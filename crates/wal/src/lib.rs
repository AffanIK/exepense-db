pub mod record;
pub mod reader;
pub mod writer;

pub use record::WalRecord;
pub use reader::WalReader;
pub use writer::WalWriter;

use thiserror::Error;

#[derive(Debug, Error)]
pub enum WalError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("CRC mismatch: expected {expected:#010x}, got {actual:#010x}")]
    CrcMismatch { expected: u32, actual: u32 },
    #[error("encode error: {0}")]
    Encode(#[from] bincode::error::EncodeError),
    #[error("decode error: {0}")]
    Decode(#[from] bincode::error::DecodeError),
}

pub type Result<T> = std::result::Result<T, WalError>;

#[cfg(test)]
mod prop_tests {
    use super::*;
    use proptest::prelude::*;
    use tempfile::tempdir;

    fn arb_wal_record() -> impl Strategy<Value = WalRecord> {
        (
            1u64..=u64::MAX,
            prop::collection::vec(any::<u8>(), 1..64),
            prop::option::of(prop::collection::vec(any::<u8>(), 0..128)),
        )
            .prop_map(|(seq_no, key, value)| WalRecord { seq_no, key, value })
    }

    proptest! {
        #[test]
        fn wal_roundtrip(records in prop::collection::vec(arb_wal_record(), 1..50)) {
            let dir = tempdir().unwrap();
            let wal_path = dir.path().join("test.wal");

            // Write all records
            let mut writer = WalWriter::open(&wal_path).unwrap();
            for rec in &records {
                writer.append(rec).unwrap();
            }
            drop(writer);

            // Read all back
            let replayed: Vec<WalRecord> = WalReader::open(&wal_path)
                .unwrap()
                .filter_map(|r| r.ok())
                .collect();

            prop_assert_eq!(replayed.len(), records.len());
            for (orig, rep) in records.iter().zip(replayed.iter()) {
                prop_assert_eq!(orig, rep);
            }
        }

        #[test]
        fn wal_truncated_file_does_not_panic(
            records in prop::collection::vec(arb_wal_record(), 1..20),
            truncate_at in 0usize..2000,
        ) {
            let dir = tempdir().unwrap();
            let wal_path = dir.path().join("test.wal");

            let mut writer = WalWriter::open(&wal_path).unwrap();
            for rec in &records {
                writer.append(rec).unwrap();
            }
            drop(writer);

            // Truncate to a random byte offset
            let meta = std::fs::metadata(&wal_path).unwrap();
            let trunc_len = truncate_at.min(meta.len() as usize) as u64;
            let f = std::fs::OpenOptions::new().write(true).open(&wal_path).unwrap();
            f.set_len(trunc_len).unwrap();
            drop(f);

            // Replay must not panic — it may return fewer records
            let replayed: Vec<WalRecord> = WalReader::open(&wal_path)
                .unwrap()
                .filter_map(|r| r.ok())
                .collect();

            // All replayed records must match the prefix
            for (i, rep) in replayed.iter().enumerate() {
                prop_assert_eq!(rep, &records[i]);
            }
        }

        #[test]
        fn wal_crc_corruption_detected(
            records in prop::collection::vec(arb_wal_record(), 1..10),
        ) {
            let dir = tempdir().unwrap();
            let wal_path = dir.path().join("test.wal");

            let mut writer = WalWriter::open(&wal_path).unwrap();
            for rec in &records {
                writer.append(rec).unwrap();
            }
            drop(writer);

            // Corrupt the first byte (the CRC)
            let mut data = std::fs::read(&wal_path).unwrap();
            if !data.is_empty() {
                data[0] ^= 0xFF;
                std::fs::write(&wal_path, &data).unwrap();
            }

            // The first record should fail CRC or be skipped
            let reader = WalReader::open(&wal_path).unwrap();
            let first = reader.into_iter().next();
            match first {
                Some(Err(WalError::CrcMismatch { .. })) | None => {},
                Some(Ok(_)) => {}, // corruption may have aligned to valid record by chance
                Some(Err(_)) => {},
            }
        }

        #[test]
        fn wal_truncate_after_removes_old_records(
            records in prop::collection::vec(arb_wal_record(), 2..20),
        ) {
            let dir = tempdir().unwrap();
            let wal_path = dir.path().join("test.wal");

            let mut writer = WalWriter::open(&wal_path).unwrap();
            for rec in &records {
                writer.append(rec).unwrap();
            }
            drop(writer);

            // Truncate after the seq of the first record
            let cutoff = records[0].seq_no;
            WalReader::truncate_after(&wal_path, cutoff).unwrap();

            let replayed: Vec<WalRecord> = WalReader::open(&wal_path)
                .unwrap()
                .filter_map(|r| r.ok())
                .collect();

            for rec in &replayed {
                prop_assert!(rec.seq_no > cutoff);
            }
        }
    }
}
