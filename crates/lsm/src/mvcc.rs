use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use parking_lot::Mutex;
use std::collections::BTreeSet;

/// Seq 0 is reserved; real writes start at 1.
static NEXT_SEQ: AtomicU64 = AtomicU64::new(1);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Snapshot(pub u64);

pub struct SnapshotRegistry {
    active: Mutex<BTreeSet<u64>>,
}

impl SnapshotRegistry {
    pub fn new() -> Arc<Self> {
        Arc::new(Self { active: Mutex::new(BTreeSet::new()) })
    }

    pub fn begin_read() -> Snapshot {
        Snapshot(NEXT_SEQ.load(Ordering::SeqCst).saturating_sub(1).max(1))
    }

    pub fn next_write_seq() -> u64 {
        NEXT_SEQ.fetch_add(1, Ordering::SeqCst)
    }

    pub fn oldest_active_snapshot(registry: &Arc<Self>) -> u64 {
        registry.active.lock().iter().copied().next().unwrap_or(u64::MAX)
    }
}

impl Default for SnapshotRegistry {
    fn default() -> Self {
        Self { active: Mutex::new(BTreeSet::new()) }
    }
}
