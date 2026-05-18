use std::collections::BTreeMap;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use parking_lot::RwLock;

use crate::entry::VersionedValue;
use crate::{MemTableError, Result};

/// Size threshold (4 MB) before the MemTable should be frozen.
pub const DEFAULT_SIZE_THRESHOLD: usize = 4 * 1024 * 1024;

pub struct MemTable {
    inner: RwLock<BTreeMap<Vec<u8>, VersionedValue>>,
    size_bytes: AtomicUsize,
    threshold: usize,
}

impl MemTable {
    pub fn new() -> Self {
        Self::with_threshold(DEFAULT_SIZE_THRESHOLD)
    }

    pub fn with_threshold(threshold: usize) -> Self {
        Self {
            inner: RwLock::new(BTreeMap::new()),
            size_bytes: AtomicUsize::new(0),
            threshold,
        }
    }

    pub fn put(&self, key: Vec<u8>, value: Vec<u8>, seq: u64) -> Result<()> {
        if key.is_empty() {
            return Err(MemTableError::EmptyKey);
        }
        let added = key.len() + value.len() + 16; // 16 = overhead estimate
        let mut map = self.inner.write();
        let removed = map
            .get(&key)
            .map(|v| key.len() + match v { VersionedValue::Value { data, .. } => data.len(), VersionedValue::Tombstone { .. } => 0 } + 16)
            .unwrap_or(0);
        map.insert(key, VersionedValue::Value { data: value, seq });
        self.size_bytes.fetch_add(added, Ordering::Relaxed);
        self.size_bytes.fetch_sub(removed, Ordering::Relaxed);
        Ok(())
    }

    pub fn delete(&self, key: Vec<u8>, seq: u64) -> Result<()> {
        if key.is_empty() {
            return Err(MemTableError::EmptyKey);
        }
        let mut map = self.inner.write();
        let removed = map
            .get(&key)
            .map(|v| key.len() + match v { VersionedValue::Value { data, .. } => data.len(), VersionedValue::Tombstone { .. } => 0 } + 16)
            .unwrap_or(0);
        map.insert(key.clone(), VersionedValue::Tombstone { seq });
        let added = key.len() + 16;
        self.size_bytes.fetch_add(added, Ordering::Relaxed);
        self.size_bytes.fetch_sub(removed, Ordering::Relaxed);
        Ok(())
    }

    /// Returns the value if the key exists and is visible at `read_seq`.
    /// Returns `None` if the key is a tombstone or doesn't exist.
    pub fn get(&self, key: &[u8], read_seq: u64) -> Option<Vec<u8>> {
        let map = self.inner.read();
        map.get(key).and_then(|v| v.read_at(read_seq)).map(|b| b.to_vec())
    }

    pub fn size_bytes(&self) -> usize {
        self.size_bytes.load(Ordering::Relaxed)
    }

    pub fn is_over_threshold(&self) -> bool {
        self.size_bytes() >= self.threshold
    }

    /// Freeze into an immutable snapshot, returning the entries sorted by key.
    pub fn freeze(self: Arc<Self>) -> ImmutableMemTable {
        let map = self.inner.read();
        ImmutableMemTable {
            entries: map.clone(),
        }
    }
}

impl Default for MemTable {
    fn default() -> Self {
        Self::new()
    }
}

/// A read-only snapshot of a frozen MemTable, waiting to be flushed to an SSTable.
#[derive(Clone)]
pub struct ImmutableMemTable {
    pub entries: BTreeMap<Vec<u8>, VersionedValue>,
}

impl ImmutableMemTable {
    pub fn get(&self, key: &[u8], read_seq: u64) -> Option<Vec<u8>> {
        self.entries.get(key).and_then(|v| v.read_at(read_seq)).map(|b| b.to_vec())
    }

    pub fn iter(&self) -> impl Iterator<Item = (&Vec<u8>, &VersionedValue)> {
        self.entries.iter()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_put_get() {
        let mt = Arc::new(MemTable::new());
        mt.put(b"key".to_vec(), b"val".to_vec(), 1).unwrap();
        assert_eq!(mt.get(b"key", 1), Some(b"val".to_vec()));
        assert_eq!(mt.get(b"key", 0), None); // seq 0 < write seq 1
    }

    #[test]
    fn tombstone_hides_value() {
        let mt = Arc::new(MemTable::new());
        mt.put(b"k".to_vec(), b"v".to_vec(), 1).unwrap();
        mt.delete(b"k".to_vec(), 2).unwrap();
        assert_eq!(mt.get(b"k", 2), None);
        assert_eq!(mt.get(b"k", 1), None); // tombstone at seq=2 is not visible at seq=1, but value at seq=1 was overwritten
    }

    #[test]
    fn overwrite_at_higher_seq() {
        let mt = Arc::new(MemTable::new());
        mt.put(b"k".to_vec(), b"v1".to_vec(), 1).unwrap();
        mt.put(b"k".to_vec(), b"v2".to_vec(), 2).unwrap();
        assert_eq!(mt.get(b"k", 2), Some(b"v2".to_vec()));
    }
}
