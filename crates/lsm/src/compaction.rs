use std::collections::BinaryHeap;
use std::cmp::Reverse;
use std::path::PathBuf;
use std::sync::Arc;

use parking_lot::Mutex;
use tokio::sync::Semaphore;

use sstable::{SsTableBuilder, SsTableReader};

use crate::levels::{LevelManager, L0_COMPACTION_TRIGGER, LEVEL_SIZE_BUDGET};
use crate::manifest::{Manifest, SstMeta};
use crate::mvcc::SnapshotRegistry;
use crate::Result;

/// One compaction job at a time.
static COMPACTION_SEMAPHORE: std::sync::OnceLock<Arc<Semaphore>> = std::sync::OnceLock::new();

fn semaphore() -> Arc<Semaphore> {
    COMPACTION_SEMAPHORE.get_or_init(|| Arc::new(Semaphore::new(1))).clone()
}

/// Entry in the k-way merge heap.
/// Ordered by (key ASC, seq DESC) so newest version of a key wins.
#[derive(Eq, PartialEq)]
struct HeapEntry {
    key: Vec<u8>,
    seq: u64,
    tombstone: bool,
    value: Vec<u8>,
    source_idx: usize,
}

impl Ord for HeapEntry {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        // Min-heap on key ASC; for equal keys, max-heap on seq (newest first)
        self.key.cmp(&other.key)
            .then(other.seq.cmp(&self.seq))
    }
}

impl PartialOrd for HeapEntry {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

/// Check if compaction is needed and trigger it asynchronously.
pub fn maybe_trigger_compaction(
    levels: Arc<LevelManager>,
    manifest: Arc<Mutex<Manifest>>,
    dir: PathBuf,
    registry: Arc<SnapshotRegistry>,
) {
    let l0_count = levels.l0_count();
    if l0_count < L0_COMPACTION_TRIGGER {
        return;
    }

    let sem = semaphore();
    tokio::spawn(async move {
        let _permit = sem.try_acquire();
        if _permit.is_err() {
            return; // another compaction already running
        }
        let _ = tokio::task::spawn_blocking(move || {
            run_l0_compaction(&levels, &manifest, &dir, &registry)
        })
        .await;
    });
}

fn run_l0_compaction(
    levels: &LevelManager,
    manifest: &Mutex<Manifest>,
    dir: &std::path::Path,
    _registry: &SnapshotRegistry,
) -> Result<()> {
    // Take a snapshot of level metadata outside the lock
    let state = levels.snapshot();
    let l0 = match state.levels.first() {
        Some(l) if !l.is_empty() => l.clone(),
        _ => return Ok(()),
    };
    let l1 = state.levels.get(1).cloned().unwrap_or_default();

    // Find L1 SSTables that overlap with the L0 key range
    let l0_min = l0.iter().map(|m| m.min_key.clone()).min().unwrap_or_default();
    let l0_max = l0.iter().map(|m| m.max_key.clone()).max().unwrap_or_default();

    let overlapping_l1: Vec<SstMeta> = l1
        .into_iter()
        .filter(|m| m.min_key <= l0_max && m.max_key >= l0_min)
        .collect();

    // Collect all iterators
    let mut iterators: Vec<Box<dyn Iterator<Item = sstable::Result<(Vec<u8>, u64, bool, Vec<u8>)>>>> = Vec::new();

    for meta in &l0 {
        if let Some(reader) = state.readers.get(&meta.id) {
            iterators.push(Box::new(reader.iter()));
        }
    }
    for meta in &overlapping_l1 {
        if let Some(reader) = state.readers.get(&meta.id) {
            iterators.push(Box::new(reader.iter()));
        }
    }

    // K-way merge
    let mut heap: BinaryHeap<Reverse<HeapEntry>> = BinaryHeap::new();
    let mut iters: Vec<_> = iterators;

    for (idx, iter) in iters.iter_mut().enumerate() {
        if let Some(Ok((key, seq, tombstone, value))) = iter.next() {
            heap.push(Reverse(HeapEntry { key, seq, tombstone, value, source_idx: idx }));
        }
    }

    let next_sst_id = {
        let m = manifest.lock();
        m.next_sst_id + 1
    };

    let mut builder = SsTableBuilder::new(1000);
    let mut last_key: Option<Vec<u8>> = None;

    while let Some(Reverse(entry)) = heap.pop() {
        // Advance the source iterator
        let idx = entry.source_idx;
        if let Some(Ok((key, seq, tombstone, value))) = iters[idx].next() {
            heap.push(Reverse(HeapEntry { key, seq, tombstone, value, source_idx: idx }));
        }

        // Skip older versions of the same key (heap ordering ensures newest first)
        if last_key.as_deref() == Some(&entry.key) {
            continue;
        }
        last_key = Some(entry.key.clone());

        if entry.tombstone {
            builder.add(&entry.key, entry.seq, None);
        } else {
            builder.add(&entry.key, entry.seq, Some(&entry.value));
        }
    }

    let new_path = builder.finish(dir, next_sst_id)?;
    let new_meta = SstMeta {
        id: next_sst_id,
        min_key: l0_min,
        max_key: l0_max,
        size_bytes: std::fs::metadata(&new_path)?.len(),
        entry_count: 0,
        min_seq: 0,
        path: new_path.clone(),
    };

    // Atomically update manifest: remove old SSTables, add new one
    {
        let mut m = manifest.lock();
        // Remove compacted L0 entries
        let compacted_ids: std::collections::HashSet<u64> = l0.iter().map(|x| x.id).chain(overlapping_l1.iter().map(|x| x.id)).collect();
        for level in m.levels.iter_mut() {
            level.retain(|meta| !compacted_ids.contains(&meta.id));
        }
        // Ensure L1 exists
        while m.levels.len() < 2 {
            m.levels.push(vec![]);
        }
        m.levels[1].push(new_meta.clone());
        m.next_sst_id = next_sst_id;
        m.save(dir)?;
    }

    // Load the new SSTable into the level manager
    if let Ok(reader) = SsTableReader::open(&new_path) {
        levels.add_l0(new_meta, Arc::new(reader)); // temporarily in L0 — level manager will reorganize
    }

    Ok(())
}
