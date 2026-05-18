pub mod block;
pub mod bloom;
pub mod builder;
pub mod footer;
pub mod iterator;
pub mod reader;

pub use builder::SsTableBuilder;
pub use reader::SsTableReader;

use thiserror::Error;

#[derive(Debug, Error)]
pub enum SsTableError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("invalid magic bytes in footer")]
    InvalidMagic,
    #[error("file too small to contain a valid footer")]
    FileTooSmall,
    #[error("CRC mismatch in data block")]
    BlockCrcMismatch,
    #[error("encode error: {0}")]
    Encode(#[from] bincode::error::EncodeError),
    #[error("decode error: {0}")]
    Decode(#[from] bincode::error::DecodeError),
    #[error("key not found")]
    NotFound,
    #[error("persist error: {0}")]
    Persist(#[from] tempfile::PersistError),
}

pub type Result<T> = std::result::Result<T, SsTableError>;

#[cfg(test)]
mod prop_tests {
    use super::*;
    use proptest::prelude::*;
    use tempfile::tempdir;

    fn build_sstable(entries: &[(Vec<u8>, u64, Option<Vec<u8>>)], dir: &std::path::Path) -> std::path::PathBuf {
        let mut builder = SsTableBuilder::new(entries.len());
        for (k, seq, v) in entries {
            builder.add(k, *seq, v.as_deref());
        }
        builder.finish(dir, 1).unwrap()
    }

    proptest! {
        #[test]
        fn sstable_all_written_keys_readable(
            // Generate 1-100 unique sorted key-value pairs
            mut entries in prop::collection::vec(
                (prop::collection::vec(1u8..=200, 1..16), 1u64..=100, prop::collection::vec(any::<u8>(), 0..32)),
                1..100,
            )
        ) {
            // Sort by key and deduplicate (keep last value per key)
            entries.sort_by(|a, b| a.0.cmp(&b.0));
            entries.dedup_by(|a, b| a.0 == b.0);

            let dir = tempdir().unwrap();
            let entries_ref: Vec<(Vec<u8>, u64, Option<Vec<u8>>)> = entries
                .iter()
                .map(|(k, s, v)| (k.clone(), *s, Some(v.clone())))
                .collect();

            let path = build_sstable(&entries_ref, dir.path());
            let reader = SsTableReader::open(&path).unwrap();

            for (key, seq, value) in &entries_ref {
                let result = reader.get(key, *seq).unwrap();
                prop_assert_eq!(&result, value);
            }
        }

        #[test]
        fn sstable_bloom_no_false_negatives(
            mut entries in prop::collection::vec(
                (prop::collection::vec(1u8..=200, 1..16), 1u64..=100),
                1..50,
            )
        ) {
            entries.sort_by(|a, b| a.0.cmp(&b.0));
            entries.dedup_by(|a, b| a.0 == b.0);

            let dir = tempdir().unwrap();
            let entries_ref: Vec<(Vec<u8>, u64, Option<Vec<u8>>)> = entries
                .iter()
                .map(|(k, s)| (k.clone(), *s, Some(b"val".to_vec())))
                .collect();

            let path = build_sstable(&entries_ref, dir.path());
            let reader = SsTableReader::open(&path).unwrap();

            // Every inserted key must be found (no false negatives in bloom)
            for (key, seq, _) in &entries_ref {
                let result = reader.get(key, *seq).unwrap();
                prop_assert!(result.is_some(), "key {:?} not found", key);
            }
        }

        #[test]
        fn sstable_tombstones_return_none(
            key in prop::collection::vec(1u8..=200, 1..16),
        ) {
            let dir = tempdir().unwrap();
            let mut builder = SsTableBuilder::new(1);
            builder.add(&key, 1, None); // tombstone
            let path = builder.finish(dir.path(), 1).unwrap();
            let reader = SsTableReader::open(&path).unwrap();
            let result = reader.get(&key, 1).unwrap();
            prop_assert_eq!(result, None);
        }

        #[test]
        fn sstable_truncated_file_returns_error(
            entries in prop::collection::vec(
                (prop::collection::vec(1u8..=200, 1..16), 1u64..=100, prop::collection::vec(any::<u8>(), 1..32)),
                1..20,
            ),
            truncate_pct in 0.0f64..0.9,
        ) {
            let dir = tempdir().unwrap();
            let mut sorted = entries.clone();
            sorted.sort_by(|a, b| a.0.cmp(&b.0));
            sorted.dedup_by(|a, b| a.0 == b.0);

            let entries_ref: Vec<(Vec<u8>, u64, Option<Vec<u8>>)> = sorted
                .iter()
                .map(|(k, s, v)| (k.clone(), *s, Some(v.clone())))
                .collect();

            let path = build_sstable(&entries_ref, dir.path());

            let original_len = std::fs::metadata(&path).unwrap().len();
            let trunc_len = (original_len as f64 * truncate_pct) as u64;
            let f = std::fs::OpenOptions::new().write(true).open(&path).unwrap();
            f.set_len(trunc_len).unwrap();
            drop(f);

            // Opening a truncated file should return an error (invalid magic / too small)
            let result = SsTableReader::open(&path);
            prop_assert!(result.is_err(), "expected error opening truncated SSTable");
        }
    }
}
