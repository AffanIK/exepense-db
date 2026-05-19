use lsm::LsmEngine;
use tempfile::tempdir;

#[test]
fn basic_put_get_delete() {
    let dir = tempdir().unwrap();
    let engine = LsmEngine::open(dir.path()).unwrap();

    engine.put(b"hello".to_vec(), b"world".to_vec()).unwrap();
    assert_eq!(engine.get(b"hello").unwrap(), Some(b"world".to_vec()));

    engine.delete(b"hello".to_vec()).unwrap();
    assert_eq!(engine.get(b"hello").unwrap(), None);
}

#[test]
fn overwrite_returns_latest_value() {
    let dir = tempdir().unwrap();
    let engine = LsmEngine::open(dir.path()).unwrap();

    engine.put(b"k".to_vec(), b"v1".to_vec()).unwrap();
    engine.put(b"k".to_vec(), b"v2".to_vec()).unwrap();
    assert_eq!(engine.get(b"k").unwrap(), Some(b"v2".to_vec()));
}

#[test]
fn missing_key_returns_none() {
    let dir = tempdir().unwrap();
    let engine = LsmEngine::open(dir.path()).unwrap();
    assert_eq!(engine.get(b"nonexistent").unwrap(), None);
}

#[test]
fn scan_prefix_returns_matching_keys() {
    let dir = tempdir().unwrap();
    let engine = LsmEngine::open(dir.path()).unwrap();

    engine.put(b"expense:1".to_vec(), b"100".to_vec()).unwrap();
    engine.put(b"expense:2".to_vec(), b"200".to_vec()).unwrap();
    engine.put(b"other:1".to_vec(), b"999".to_vec()).unwrap();

    let results = engine.scan_prefix(b"expense:").unwrap();
    assert_eq!(results.len(), 2);
    assert!(results.iter().all(|(k, _)| k.starts_with(b"expense:")));
}

#[test]
fn wal_replayed_on_reopen() {
    let dir = tempdir().unwrap();

    {
        let engine = LsmEngine::open(dir.path()).unwrap();
        engine.put(b"persist_me".to_vec(), b"still here".to_vec()).unwrap();
    }

    // Reopen — WAL should replay the write
    let engine2 = LsmEngine::open(dir.path()).unwrap();
    assert_eq!(engine2.get(b"persist_me").unwrap(), Some(b"still here".to_vec()));
}

/// Regression: before the fix, NEXT_SEQ stayed at 1 across reopens, so the
/// MVCC snapshot returned by begin_read() was 1, hiding every replayed row
/// whose original seq_no was > 1. The app symptom was "all my expenses
/// disappeared except the first one" after an app restart.
#[test]
fn all_writes_visible_after_reopen() {
    let dir = tempdir().unwrap();

    {
        let engine = LsmEngine::open(dir.path()).unwrap();
        for i in 0..20 {
            engine
                .put(format!("k{i:02}").into_bytes(), format!("v{i:02}").into_bytes())
                .unwrap();
        }
    }

    let engine2 = LsmEngine::open(dir.path()).unwrap();
    for i in 0..20 {
        assert_eq!(
            engine2.get(format!("k{i:02}").as_bytes()).unwrap(),
            Some(format!("v{i:02}").into_bytes()),
            "row k{i:02} should be visible after reopen",
        );
    }

    let scanned = engine2.scan_prefix(b"k").unwrap();
    assert_eq!(scanned.len(), 20, "scan_prefix should return all 20 rows after reopen");
}

/// New writes made after a reopen must coexist with replayed rows — none
/// should be hidden by an out-of-date seq counter.
#[test]
fn writes_after_reopen_keep_replayed_rows_visible() {
    let dir = tempdir().unwrap();

    {
        let engine = LsmEngine::open(dir.path()).unwrap();
        for i in 0..5 {
            engine
                .put(format!("old{i}").into_bytes(), format!("v{i}").into_bytes())
                .unwrap();
        }
    }

    let engine2 = LsmEngine::open(dir.path()).unwrap();
    // Add new rows after reopen
    for i in 0..5 {
        engine2
            .put(format!("new{i}").into_bytes(), format!("v{i}").into_bytes())
            .unwrap();
    }

    // Old rows must still be visible
    for i in 0..5 {
        assert_eq!(
            engine2.get(format!("old{i}").as_bytes()).unwrap(),
            Some(format!("v{i}").into_bytes()),
        );
    }
    // New rows must be visible
    for i in 0..5 {
        assert_eq!(
            engine2.get(format!("new{i}").as_bytes()).unwrap(),
            Some(format!("v{i}").into_bytes()),
        );
    }
}
