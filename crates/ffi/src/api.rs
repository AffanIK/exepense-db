/// flutter_rust_bridge v2 public API surface.
///
/// Call open_db once on app start; pass the returned handle to all subsequent
/// calls. Call close_db on app shutdown.
use std::collections::HashMap;
use std::sync::Arc;

use parking_lot::Mutex;

use lsm::LsmEngine;
use sql::{
    executor::{Executor, ExpenseRow, QueryResult},
    parse,
};

use crate::{FfiError, Result};

// Global registry: handle -> engine.
// Using a static Mutex<HashMap> avoids raw pointer FFI risks.
static ENGINES: std::sync::OnceLock<Mutex<HashMap<u64, Arc<LsmEngine>>>> =
    std::sync::OnceLock::new();
static NEXT_HANDLE: std::sync::atomic::AtomicU64 =
    std::sync::atomic::AtomicU64::new(1);

fn registry() -> &'static Mutex<HashMap<u64, Arc<LsmEngine>>> {
    ENGINES.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_engine(handle: u64) -> Result<Arc<LsmEngine>> {
    registry()
        .lock()
        .get(&handle)
        .cloned()
        .ok_or(FfiError::InvalidHandle)
}

// ── Public API (annotated for flutter_rust_bridge v2) ─────────────────────

/// Open (or create) a database at `path`.
/// Returns an opaque handle used by all subsequent calls.
pub fn open_db(path: String) -> Result<u64> {
    let engine = LsmEngine::open(path)?;
    let handle = NEXT_HANDLE.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
    registry().lock().insert(handle, engine);
    Ok(handle)
}

/// Close the database handle and release its resources.
pub fn close_db(handle: u64) {
    registry().lock().remove(&handle);
}

/// Insert an expense record.
/// Returns the generated UUID string for the new row.
pub fn insert_expense(
    handle: u64,
    amount: f64,
    category: String,
    description: String,
    date: String,
) -> Result<String> {
    let engine = get_engine(handle)?;
    let executor = Executor::new(engine);
    let sql = format!(
        "INSERT INTO expenses (amount, category, description, date) VALUES ({}, '{}', '{}', '{}')",
        amount,
        category.replace('\'', "''"),
        description.replace('\'', "''"),
        date.replace('\'', "''"),
    );
    let stmt = parse(&sql).map_err(|e| FfiError::Sql(e))?;
    match executor.execute(stmt)? {
        QueryResult::Inserted { id } => Ok(id),
        _ => Err(FfiError::Sql(sql::SqlError::Execution("expected Inserted result".into()))),
    }
}

/// Execute a SELECT SQL query and return matching expense rows.
pub fn query_expenses(handle: u64, sql_text: String) -> Result<Vec<FfiExpenseRow>> {
    let engine = get_engine(handle)?;
    let executor = Executor::new(engine);
    let stmt = parse(&sql_text).map_err(|e| FfiError::Sql(e))?;
    match executor.execute(stmt)? {
        QueryResult::Rows(rows) => Ok(rows.into_iter().map(FfiExpenseRow::from).collect()),
        _ => Err(FfiError::Sql(sql::SqlError::Execution("expected Rows result".into()))),
    }
}

/// Delete an expense by ID.
pub fn delete_expense(handle: u64, id: String) -> Result<()> {
    let engine = get_engine(handle)?;
    let key = format!("expense:{}", id).into_bytes();
    engine.delete(key)?;
    Ok(())
}

// ── Dart-friendly row type ─────────────────────────────────────────────────

/// A row type with primitive fields that flutter_rust_bridge can auto-generate
/// a Dart class for.
#[derive(Debug, Clone)]
pub struct FfiExpenseRow {
    pub id: String,
    pub amount: f64,
    pub category: String,
    pub description: String,
    pub date: String,
    pub created_at: i64,
}

impl From<ExpenseRow> for FfiExpenseRow {
    fn from(r: ExpenseRow) -> Self {
        Self {
            id: r.id,
            amount: r.amount,
            category: r.category,
            description: r.description,
            date: r.date,
            created_at: r.created_at,
        }
    }
}
