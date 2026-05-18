// SQL parser using nom 7 — to be implemented in Phase 7.
// Stub so the workspace compiles.
use crate::ast::Statement;
use crate::{Result, SqlError};

pub fn parse(_input: &str) -> Result<Statement> {
    Err(SqlError::Parse("parser not yet implemented".to_string()))
}
