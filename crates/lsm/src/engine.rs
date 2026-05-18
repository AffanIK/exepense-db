use std::path::{Path, PathBuf};
use std::sync::Arc;

use parking_lot::Mutex;

use memtable::{ImmutableMemTable, MemTable};
use wal::{WalReader, WalRecord, WalWriter};

use crate::levels::LevelManager;
use crate::manifest::Manifest;
use crate::mvcc::{Snapshot, SnapshotRegistry};
use crate::{LsmError, Result};

pub struct LsmEngine {
    dir: PathBuf,
    state: Mutex<EngineState>,
    registry: Arc<SnapshotRegistry>,
}

struct EngineState {
    memtable: Arc<MemTable>,
    immutable: Vec<ImmutableMemTable>,
    wal: WalWriter,
    levels: LevelManager,
    manifest: Manifest,
}

impl LsmEngine {
    pub fn open(dir: impl AsRef<Path>) -> Result<Arc<Self>> {
        let dir = dir.as_ref().to_path_buf();
        std::fs::create_dir_all(&dir)?;

        let manifest = Manifest::load(&dir)?;
        let wal_path = dir.join("wal.log");
        let memtable = Arc::new(MemTable::new());

        // Replay WAL into the fresh MemTable
        if wal_path.exists() {
            let reader = WalReader::open(&wal_path)?;
            for record in reader {
                let record = record?;
                if record.seq_no <= manifest.wal_flushed_seq {
                    continue; // already flushed to SSTable
                }
                match record.value {
                    Some(v) => memtable.put(record.key, v, record.seq_no)?,
                    None => memtable.delete(record.key, record.seq_no)?,
                }
            }
        }

        let levels = LevelManager::new(manifest.levels.clone(), &dir);
        let wal = WalWriter::open(&wal_path)?;

        Ok(Arc::new(Self {
            dir,
            state: Mutex::new(EngineState {
                memtable,
                immutable: Vec::new(),
                wal,
                levels,
                manifest,
            }),
            registry: SnapshotRegistry::new(),
        }))
    }

    pub fn put(&self, key: Vec<u8>, value: Vec<u8>) -> Result<()> {
        let seq = SnapshotRegistry::next_write_seq();
        let record = WalRecord { seq_no: seq, key: key.clone(), value: Some(value.clone()) };
        let mut state = self.state.lock();
        state.wal.append(&record)?;
        state.memtable.put(key, value, seq)?;
        self.maybe_freeze(&mut state);
        Ok(())
    }

    pub fn delete(&self, key: Vec<u8>) -> Result<()> {
        let seq = SnapshotRegistry::next_write_seq();
        let record = WalRecord { seq_no: seq, key: key.clone(), value: None };
        let mut state = self.state.lock();
        state.wal.append(&record)?;
        state.memtable.delete(key, seq)?;
        Ok(())
    }

    pub fn get(&self, key: &[u8]) -> Result<Option<Vec<u8>>> {
        let snap = SnapshotRegistry::begin_read();
        self.get_at(key, snap)
    }

    pub fn get_at(&self, key: &[u8], snapshot: Snapshot) -> Result<Option<Vec<u8>>> {
        let state = self.state.lock();

        // 1. Active MemTable
        if let Some(v) = state.memtable.get(key, snapshot.0) {
            return Ok(Some(v));
        }
        // 2. Immutable MemTables (newest-first)
        for imm in state.immutable.iter().rev() {
            if let Some(v) = imm.get(key, snapshot.0) {
                return Ok(Some(v));
            }
        }
        // 3. L0 SSTables (newest-first by ID)
        let level_snapshot = state.levels.snapshot();
        if let Some(l0) = level_snapshot.levels.first() {
            for meta in l0 {
                if let Some(reader) = level_snapshot.readers.get(&meta.id) {
                    if let Some(v) = reader.get(key, snapshot.0)? {
                        return Ok(Some(v));
                    }
                }
            }
        }
        // 4. L1+ — key-range filtered scan
        for level in level_snapshot.levels.iter().skip(1) {
            for meta in level {
                if key >= meta.min_key.as_slice() && key <= meta.max_key.as_slice() {
                    if let Some(reader) = level_snapshot.readers.get(&meta.id) {
                        if let Some(v) = reader.get(key, snapshot.0)? {
                            return Ok(Some(v));
                        }
                    }
                }
            }
        }
        Ok(None)
    }

    /// Scan all keys with the given prefix, returning (key, value) pairs visible at current snapshot.
    pub fn scan_prefix(&self, prefix: &[u8]) -> Result<Vec<(Vec<u8>, Vec<u8>)>> {
        let snap = SnapshotRegistry::begin_read();
        let state = self.state.lock();
        let mut results: std::collections::BTreeMap<Vec<u8>, Vec<u8>> = std::collections::BTreeMap::new();

        // Collect from all SSTables first (oldest to newest so newer writes win)
        let level_snapshot = state.levels.snapshot();
        for level in level_snapshot.levels.iter().rev() {
            for meta in level {
                if let Some(reader) = level_snapshot.readers.get(&meta.id) {
                    for item in reader.iter() {
                        let (key, seq, tombstone, value) = item?;
                        if key.starts_with(prefix) && seq <= snap.0 {
                            if tombstone {
                                results.remove(&key);
                            } else {
                                results.insert(key, value);
                            }
                        }
                    }
                }
            }
        }

        // Immutable MemTables (oldest to newest)
        for imm in &state.immutable {
            for (key, val) in imm.iter() {
                if key.starts_with(prefix) {
                    match val {
                        memtable::VersionedValue::Value { data, seq } if *seq <= snap.0 => {
                            results.insert(key.clone(), data.clone());
                        }
                        memtable::VersionedValue::Tombstone { seq } if *seq <= snap.0 => {
                            results.remove(key);
                        }
                        _ => {}
                    }
                }
            }
        }

        // Active MemTable
        {
            let mt_snap = state.memtable.clone();
            drop(state);
            for (key, val) in mt_snap.freeze().iter() {
                if key.starts_with(prefix) {
                    match val {
                        memtable::VersionedValue::Value { data, seq } if *seq <= snap.0 => {
                            results.insert(key.clone(), data.clone());
                        }
                        memtable::VersionedValue::Tombstone { seq } if *seq <= snap.0 => {
                            results.remove(key);
                        }
                        _ => {}
                    }
                }
            }
        }

        Ok(results.into_iter().collect())
    }

    fn maybe_freeze(&self, state: &mut EngineState) {
        if state.memtable.is_over_threshold() {
            let old = std::mem::replace(&mut state.memtable, Arc::new(MemTable::new()));
            let imm = old.freeze();
            state.immutable.push(imm);
        }
    }
}
