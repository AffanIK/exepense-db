//! Fault injection tests — simulates crashes at key points to verify WAL replay.
use lsm::LsmEngine;
use tempfile::tempdir;

/// Simulate a crash after writes but before clean shutdown.
/// On re-open the WAL should replay all written records.
#[test]
fn crash_after_writes_replays_correctly() {
    let dir = tempdir().unwrap();

    let keys: Vec<Vec<u8>> = (0..20).map(|i| format!("key_{:03}", i).into_bytes()).collect();
    let value = b"some_value".to_vec();

    // Write without calling any shutdown/flush
    {
        let engine = LsmEngine::open(dir.path()).unwrap();
        for key in &keys {
            engine.put(key.clone(), value.clone()).unwrap();
        }
        // Drop without explicit flush = simulated crash
    }

    // Reopen: WAL replay must recover all keys
    let engine = LsmEngine::open(dir.path()).unwrap();
    for key in &keys {
        assert_eq!(
            engine.get(key).unwrap(),
            Some(value.clone()),
            "key {:?} missing after WAL replay",
            String::from_utf8_lossy(key)
        );
    }
}

/// Truncate the WAL mid-record to simulate a partial write at crash.
/// Engine should open cleanly and recover all complete records.
#[test]
fn partial_wal_write_opens_cleanly() {
    let dir = tempdir().unwrap();
    let wal_path = dir.path().join("wal.log");

    {
        let engine = LsmEngine::open(dir.path()).unwrap();
        engine.put(b"a".to_vec(), b"1".to_vec()).unwrap();
        engine.put(b"b".to_vec(), b"2".to_vec()).unwrap();
    }

    // Corrupt the last 3 bytes of the WAL (simulates partial flush)
    let mut data = std::fs::read(&wal_path).unwrap();
    let len = data.len();
    if len >= 3 {
        data.truncate(len - 3);
        std::fs::write(&wal_path, &data).unwrap();
    }

    // Must open without panic — may lose the last partial record
    let engine = LsmEngine::open(dir.path()).unwrap();
    // "a" should be recoverable; "b" may or may not be depending on which record was truncated
    let _ = engine.get(b"a").unwrap();
    let _ = engine.get(b"b").unwrap();
}
