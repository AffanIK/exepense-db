use std::collections::HashMap;
use std::sync::Arc;

use bincode::config;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use lsm::LsmEngine;

use crate::ast::*;
use crate::{Result, SqlError};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ExpenseRow {
    pub id: String,
    pub amount: f64,
    pub category: String,
    pub description: String,
    pub date: String,
    pub created_at: i64,
}

pub struct Executor {
    engine: Arc<LsmEngine>,
}

impl Executor {
    pub fn new(engine: Arc<LsmEngine>) -> Self {
        Self { engine }
    }

    pub fn execute(&self, stmt: Statement) -> Result<QueryResult> {
        match stmt {
            Statement::Insert(ins) => self.execute_insert(ins),
            Statement::Select(sel) => self.execute_select(sel),
        }
    }

    fn execute_insert(&self, stmt: InsertStmt) -> Result<QueryResult> {
        let id = Uuid::new_v4().to_string();
        let mut row = ExpenseRow {
            id: id.clone(),
            amount: 0.0,
            category: String::new(),
            description: String::new(),
            date: String::new(),
            created_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs() as i64,
        };

        for (col, val) in stmt.columns.iter().zip(stmt.values.iter()) {
            match col.as_str() {
                "amount" => row.amount = value_to_f64(val)?,
                "category" => row.category = value_to_string(val)?,
                "description" => row.description = value_to_string(val)?,
                "date" => row.date = value_to_string(val)?,
                "created_at" => row.created_at = value_to_i64(val)?,
                other => return Err(SqlError::UnknownColumn(other.to_string())),
            }
        }

        let key = format!("expense:{}", id).into_bytes();
        let value = bincode::serde::encode_to_vec(&row, config::standard())?;
        self.engine.put(key, value)?;

        Ok(QueryResult::Inserted { id })
    }

    fn execute_select(&self, stmt: SelectStmt) -> Result<QueryResult> {
        // Optimized path: WHERE id = 'xxx'
        if let Some(id) = extract_id_eq(&stmt.where_clause) {
            let key = format!("expense:{}", id).into_bytes();
            let rows = match self.engine.get(&key)? {
                Some(bytes) => {
                    let (row, _): (ExpenseRow, _) = bincode::serde::decode_from_slice(&bytes, config::standard())?;
                    vec![row]
                }
                None => vec![],
            };
            return Ok(QueryResult::Rows(rows));
        }

        // Full scan path
        let pairs = self.engine.scan_prefix(b"expense:")?;
        let mut rows: Vec<ExpenseRow> = pairs
            .into_iter()
            .filter_map(|(_, bytes)| {
                bincode::serde::decode_from_slice::<ExpenseRow, _>(&bytes, config::standard())
                    .ok()
                    .map(|(r, _)| r)
            })
            .collect();

        // Apply WHERE filter
        if let Some(expr) = &stmt.where_clause {
            rows.retain(|row| eval_expr(expr, row).unwrap_or(false));
        }

        // GROUP BY
        if let Some(group_cols) = &stmt.group_by {
            rows = group_by(rows, group_cols);
        }

        // ORDER BY
        if let Some(order) = &stmt.order_by {
            let asc = order.ascending;
            let col = order.column.clone();
            rows.sort_by(|a, b| {
                let va = row_field(a, &col);
                let vb = row_field(b, &col);
                let ord = va.partial_cmp(&vb).unwrap_or(std::cmp::Ordering::Equal);
                if asc { ord } else { ord.reverse() }
            });
        }

        // LIMIT
        if let Some(limit) = stmt.limit {
            rows.truncate(limit as usize);
        }

        Ok(QueryResult::Rows(rows))
    }
}

#[derive(Debug)]
pub enum QueryResult {
    Inserted { id: String },
    Rows(Vec<ExpenseRow>),
}

// ── Expression evaluation ──────────────────────────────────────────────────

fn eval_expr(expr: &Expr, row: &ExpenseRow) -> Result<bool> {
    match expr {
        Expr::BinaryOp { op, left, right } => {
            match op {
                BinOp::And => Ok(eval_expr(left, row)? && eval_expr(right, row)?),
                BinOp::Or => Ok(eval_expr(left, row)? || eval_expr(right, row)?),
                _ => {
                    let lv = eval_value_expr(left, row)?;
                    let rv = eval_value_expr(right, row)?;
                    Ok(compare_values(&lv, op, &rv))
                }
            }
        }
        _ => Ok(false),
    }
}

fn eval_value_expr(expr: &Expr, row: &ExpenseRow) -> Result<Value> {
    match expr {
        Expr::Literal(v) => Ok(v.clone()),
        Expr::Column(col) => Ok(match col.as_str() {
            "id" => Value::Text(row.id.clone()),
            "amount" => Value::Real(row.amount),
            "category" => Value::Text(row.category.clone()),
            "description" => Value::Text(row.description.clone()),
            "date" => Value::Text(row.date.clone()),
            "created_at" => Value::Integer(row.created_at),
            other => return Err(SqlError::UnknownColumn(other.to_string())),
        }),
        Expr::BinaryOp { .. } => Err(SqlError::Execution("nested ops not supported in value context".to_string())),
    }
}

fn compare_values(left: &Value, op: &BinOp, right: &Value) -> bool {
    match (left, right) {
        (Value::Text(a), Value::Text(b)) => apply_op(a.as_str(), op, b.as_str()),
        (Value::Real(a), Value::Real(b)) => apply_op(a, op, b),
        (Value::Integer(a), Value::Integer(b)) => apply_op(a, op, b),
        (Value::Real(a), Value::Integer(b)) => apply_op(a, op, &(*b as f64)),
        (Value::Integer(a), Value::Real(b)) => apply_op(&(*a as f64), op, b),
        _ => false,
    }
}

fn apply_op<T: PartialOrd + ?Sized>(a: &T, op: &BinOp, b: &T) -> bool {
    match op {
        BinOp::Eq => a == b,
        BinOp::Ne => a != b,
        BinOp::Lt => a < b,
        BinOp::Le => a <= b,
        BinOp::Gt => a > b,
        BinOp::Ge => a >= b,
        _ => false,
    }
}

// ── Helpers ────────────────────────────────────────────────────────────────

fn extract_id_eq(expr: &Option<Expr>) -> Option<String> {
    if let Some(Expr::BinaryOp { op: BinOp::Eq, left, right }) = expr {
        match (left.as_ref(), right.as_ref()) {
            (Expr::Column(col), Expr::Literal(Value::Text(id))) if col == "id" => {
                return Some(id.clone());
            }
            (Expr::Literal(Value::Text(id)), Expr::Column(col)) if col == "id" => {
                return Some(id.clone());
            }
            _ => {}
        }
    }
    None
}

fn group_by(rows: Vec<ExpenseRow>, cols: &[String]) -> Vec<ExpenseRow> {
    let mut groups: HashMap<String, (ExpenseRow, f64, usize)> = HashMap::new();
    for row in rows {
        let key = cols.iter().map(|c| row_field_str(&row, c)).collect::<Vec<_>>().join("|");
        let entry = groups.entry(key).or_insert_with(|| (row.clone(), 0.0, 0));
        entry.1 += row.amount;
        entry.2 += 1;
    }
    groups.into_values().map(|(mut row, total_amount, _count)| {
        row.amount = total_amount;
        row
    }).collect()
}

fn row_field(row: &ExpenseRow, col: &str) -> f64 {
    match col {
        "amount" => row.amount,
        "created_at" => row.created_at as f64,
        _ => 0.0,
    }
}

fn row_field_str(row: &ExpenseRow, col: &str) -> String {
    match col {
        "id" => row.id.clone(),
        "category" => row.category.clone(),
        "description" => row.description.clone(),
        "date" => row.date.clone(),
        _ => String::new(),
    }
}

fn value_to_f64(v: &Value) -> Result<f64> {
    match v {
        Value::Real(f) => Ok(*f),
        Value::Integer(i) => Ok(*i as f64),
        other => Err(SqlError::TypeError { expected: "REAL".into(), got: format!("{:?}", other) }),
    }
}

fn value_to_string(v: &Value) -> Result<String> {
    match v {
        Value::Text(s) => Ok(s.clone()),
        other => Err(SqlError::TypeError { expected: "TEXT".into(), got: format!("{:?}", other) }),
    }
}

fn value_to_i64(v: &Value) -> Result<i64> {
    match v {
        Value::Integer(i) => Ok(*i),
        Value::Real(f) => Ok(*f as i64),
        other => Err(SqlError::TypeError { expected: "INTEGER".into(), got: format!("{:?}", other) }),
    }
}
