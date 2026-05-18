pub mod api;

use thiserror::Error;

#[derive(Debug, Error)]
pub enum FfiError {
    #[error("SQL error: {0}")]
    Sql(#[from] sql::SqlError),
    #[error("LSM error: {0}")]
    Lsm(#[from] lsm::LsmError),
    #[error("invalid handle")]
    InvalidHandle,
}

pub type Result<T> = std::result::Result<T, FfiError>;
