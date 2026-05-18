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
