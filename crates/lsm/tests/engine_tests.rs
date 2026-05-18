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
