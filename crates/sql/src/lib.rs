pub mod ast;
pub mod executor;
pub mod parser;
pub mod planner;

pub use executor::Executor;
pub use parser::parse;

use thiserror::Error;

#[derive(Debug, Error)]
pub enum SqlError {
    #[error("parse error: {0}")]
    Parse(String),
    #[error("execution error: {0}")]
    Execution(String),
    #[error("LSM error: {0}")]
    Lsm(#[from] lsm::LsmError),
    #[error("encode error: {0}")]
    Encode(#[from] bincode::error::EncodeError),
    #[error("decode error: {0}")]
    Decode(#[from] bincode::error::DecodeError),
    #[error("unknown column: {0}")]
    UnknownColumn(String),
    #[error("type error: expected {expected}, got {got}")]
    TypeError { expected: String, got: String },
}

pub type Result<T> = std::result::Result<T, SqlError>;
