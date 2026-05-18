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
