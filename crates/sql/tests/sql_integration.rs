use lsm::LsmEngine;
use sql::{
    executor::{Executor, QueryResult},
    parse,
};
use tempfile::tempdir;

fn make_engine() -> std::sync::Arc<LsmEngine> {
    let dir = tempdir().unwrap();
    // Leak the TempDir so it lives long enough
    let path = dir.into_path();
    LsmEngine::open(path).unwrap()
}

#[test]
fn insert_then_select_star() {
    let engine = make_engine();
    let exec = Executor::new(engine);

    let insert_sql = "INSERT INTO expenses (amount, category, description, date) VALUES (12.50, 'food', 'coffee', '2024-01-15')";
    let result = exec.execute(parse(insert_sql).unwrap()).unwrap();
    let id = match result {
        QueryResult::Inserted { id } => id,
        _ => panic!("expected Inserted"),
    };

    let select_sql = "SELECT * FROM expenses";
    let result = exec.execute(parse(select_sql).unwrap()).unwrap();
    match result {
        QueryResult::Rows(rows) => {
            assert_eq!(rows.len(), 1);
            assert_eq!(rows[0].id, id);
            assert!((rows[0].amount - 12.50).abs() < f64::EPSILON);
            assert_eq!(rows[0].category, "food");
        }
        _ => panic!("expected Rows"),
    }
}

#[test]
fn select_where_category() {
    let engine = make_engine();
    let exec = Executor::new(engine);

    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (10.0, 'food', 'lunch', '2024-01-01')").unwrap()).unwrap();
    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (50.0, 'transport', 'taxi', '2024-01-01')").unwrap()).unwrap();

    let result = exec.execute(parse("SELECT * FROM expenses WHERE category = 'food'").unwrap()).unwrap();
    match result {
        QueryResult::Rows(rows) => {
            assert_eq!(rows.len(), 1);
            assert_eq!(rows[0].category, "food");
        }
        _ => panic!("expected Rows"),
    }
}

#[test]
fn select_order_by_amount_desc() {
    let engine = make_engine();
    let exec = Executor::new(engine);

    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (5.0, 'food', 'a', '2024-01-01')").unwrap()).unwrap();
    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (100.0, 'food', 'b', '2024-01-01')").unwrap()).unwrap();
    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (30.0, 'food', 'c', '2024-01-01')").unwrap()).unwrap();

    let result = exec.execute(parse("SELECT * FROM expenses ORDER BY amount DESC").unwrap()).unwrap();
    match result {
        QueryResult::Rows(rows) => {
            assert_eq!(rows.len(), 3);
            assert!(rows[0].amount >= rows[1].amount);
            assert!(rows[1].amount >= rows[2].amount);
        }
        _ => panic!("expected Rows"),
    }
}

#[test]
fn select_group_by_category() {
    let engine = make_engine();
    let exec = Executor::new(engine);

    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (10.0, 'food', 'a', '2024-01-01')").unwrap()).unwrap();
    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (20.0, 'food', 'b', '2024-01-01')").unwrap()).unwrap();
    exec.execute(parse("INSERT INTO expenses (amount, category, description, date) VALUES (50.0, 'transport', 'c', '2024-01-01')").unwrap()).unwrap();

    let result = exec.execute(parse("SELECT category FROM expenses GROUP BY category").unwrap()).unwrap();
    match result {
        QueryResult::Rows(rows) => {
            assert_eq!(rows.len(), 2);
            let food = rows.iter().find(|r| r.category == "food").unwrap();
            assert!((food.amount - 30.0).abs() < 0.001);
        }
        _ => panic!("expected Rows"),
    }
}
