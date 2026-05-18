pub mod compaction;
pub mod engine;
pub mod flush;
pub mod iterator;
pub mod levels;
pub mod manifest;
pub mod mvcc;

pub use engine::LsmEngine;
pub use mvcc::Snapshot;

use thiserror::Error;

#[derive(Debug, Error)]
pub enum LsmError {
    #[error("WAL error: {0}")]
    Wal(#[from] wal::WalError),
    #[error("SSTable error: {0}")]
    SsTable(#[from] sstable::SsTableError),
    #[error("memtable error: {0}")]
    MemTable(#[from] memtable::MemTableError),
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("manifest error: {0}")]
    Manifest(String),
    #[error("encode error: {0}")]
    Encode(#[from] bincode::error::EncodeError),
    #[error("decode error: {0}")]
    Decode(#[from] bincode::error::DecodeError),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
}

pub type Result<T> = std::result::Result<T, LsmError>;
