use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use parking_lot::RwLock;

use crate::manifest::SstMeta;

/// Size budgets per level (bytes).
pub const LEVEL_SIZE_BUDGET: [u64; 3] = [
    64 * 1024 * 1024,   // L0: 64 MB total before compaction trigger
    256 * 1024 * 1024,  // L1: 256 MB
    1024 * 1024 * 1024, // L2: 1 GB
];

/// L0 SSTable count that triggers compaction.
pub const L0_COMPACTION_TRIGGER: usize = 4;
/// L0 SSTable count that causes write stalls.
pub const L0_STALL_TRIGGER: usize = 8;

#[derive(Clone)]
pub struct LevelManager {
    inner: Arc<RwLock<LevelState>>,
}

#[derive(Debug, Clone)]
pub struct LevelState {
    /// levels[0] = L0 (newest-first ordering), levels[1..] = non-overlapping
    pub levels: Vec<Vec<SstMeta>>,
    /// Loaded readers indexed by SSTable ID
    pub readers: HashMap<u64, Arc<sstable::SsTableReader>>,
}

impl LevelManager {
    pub fn new(levels: Vec<Vec<SstMeta>>, dir: &std::path::Path) -> Self {
        let mut readers = HashMap::new();
        for level in &levels {
            for meta in level {
                if let Ok(r) = sstable::SsTableReader::open(&meta.path) {
                    readers.insert(meta.id, Arc::new(r));
                }
            }
        }
        Self {
            inner: Arc::new(RwLock::new(LevelState { levels, readers })),
        }
    }

    pub fn add_l0(&self, meta: SstMeta, reader: Arc<sstable::SsTableReader>) {
        let mut state = self.inner.write();
        if state.levels.is_empty() { state.levels.push(vec![]); }
        state.levels[0].insert(0, meta.clone()); // newest-first
        state.readers.insert(meta.id, reader);
    }

    pub fn l0_count(&self) -> usize {
        let state = self.inner.read();
        state.levels.first().map(|l| l.len()).unwrap_or(0)
    }

    pub fn snapshot(&self) -> LevelState {
        self.inner.read().clone()
    }
}
