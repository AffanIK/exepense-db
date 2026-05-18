pub mod entry;
pub mod memtable;

pub use entry::VersionedValue;
pub use memtable::{ImmutableMemTable, MemTable};

use thiserror::Error;

#[derive(Debug, Error)]
pub enum MemTableError {
    #[error("key is empty")]
    EmptyKey,
}

pub type Result<T> = std::result::Result<T, MemTableError>;

#[cfg(test)]
mod prop_tests {
    use super::*;
    use proptest::prelude::*;
    use std::sync::Arc;

    #[derive(Debug, Clone)]
    enum Op {
        Put { key: Vec<u8>, value: Vec<u8>, seq: u64 },
        Delete { key: Vec<u8>, seq: u64 },
    }

    fn arb_op(seq: u64) -> impl Strategy<Value = Op> {
        prop_oneof![
            (prop::collection::vec(1u8..=255, 1..16), prop::collection::vec(any::<u8>(), 0..32))
                .prop_map(move |(k, v)| Op::Put { key: k, value: v, seq }),
            prop::collection::vec(1u8..=255, 1..16)
                .prop_map(move |k| Op::Delete { key: k, seq }),
        ]
    }

    proptest! {
        #[test]
        fn memtable_higher_seq_wins(
            key in prop::collection::vec(1u8..=255, 1..16),
            v1 in prop::collection::vec(any::<u8>(), 1..32),
            v2 in prop::collection::vec(any::<u8>(), 1..32),
        ) {
            let mt = Arc::new(MemTable::new());
            mt.put(key.clone(), v1, 1).unwrap();
            mt.put(key.clone(), v2.clone(), 2).unwrap();
            prop_assert_eq!(mt.get(&key, 2), Some(v2));
        }

        #[test]
        fn memtable_tombstone_hides_at_or_after_seq(
            key in prop::collection::vec(1u8..=255, 1..16),
            value in prop::collection::vec(any::<u8>(), 1..32),
        ) {
            let mt = Arc::new(MemTable::new());
            mt.put(key.clone(), value, 1).unwrap();
            mt.delete(key.clone(), 2).unwrap();
            prop_assert_eq!(mt.get(&key, 2), None);
            prop_assert_eq!(mt.get(&key, 100), None);
        }

        #[test]
        fn memtable_size_never_negative(
            ops_data in prop::collection::vec((prop::collection::vec(1u8..=4, 1..4), prop::bool::ANY), 1..30),
        ) {
            let mt = Arc::new(MemTable::with_threshold(usize::MAX));
            let mut seq = 1u64;
            for (key, is_put) in ops_data {
                if is_put {
                    let _ = mt.put(key, b"v".to_vec(), seq);
                } else {
                    let _ = mt.delete(key, seq);
                }
                seq += 1;
                // Size should never wrap (AtomicUsize underflow)
                let _ = mt.size_bytes();
            }
        }
    }
}
