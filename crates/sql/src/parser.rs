use nom::{
    branch::alt,
    bytes::complete::{tag, tag_no_case, take_while1},
    character::complete::{char, multispace0, multispace1},
    combinator::{map, opt},
    multi::separated_list1,
    number::complete::double,
    sequence::{delimited, preceded, tuple},
    IResult,
};

use crate::ast::*;
use crate::{Result, SqlError};

pub fn parse(input: &str) -> Result<Statement> {
    let input = input.trim();
    let result = alt((
        map(parse_insert, Statement::Insert),
        map(parse_select, Statement::Select),
    ))(input);

    match result {
        Ok((_, stmt)) => Ok(stmt),
        Err(e) => Err(SqlError::Parse(format!("{}", e))),
    }
}

// ── Helpers ────────────────────────────────────────────────────────────────

fn ws<'a, F, O>(f: F) -> impl FnMut(&'a str) -> IResult<&'a str, O>
where
    F: FnMut(&'a str) -> IResult<&'a str, O>,
{
    delimited(multispace0, f, multispace0)
}

fn ident(input: &str) -> IResult<&str, &str> {
    take_while1(|c: char| c.is_alphanumeric() || c == '_')(input)
}

fn quoted_string(input: &str) -> IResult<&str, String> {
    let (input, _) = char('\'')(input)?;
    let (input, s) = take_while1(|c: char| c != '\'')(input)?;
    let (input, _) = char('\'')(input)?;
    Ok((input, s.to_string()))
}

fn parse_value(input: &str) -> IResult<&str, Value> {
    alt((
        map(quoted_string, Value::Text),
        map(
            nom::combinator::map_opt(double, |f: f64| {
                if f.fract() == 0.0 && f.abs() < i64::MAX as f64 {
                    Some(Value::Integer(f as i64))
                } else {
                    Some(Value::Real(f))
                }
            }),
            |v| v,
        ),
        map(tag_no_case("NULL"), |_| Value::Null),
    ))(input)
}

// ── INSERT ─────────────────────────────────────────────────────────────────

fn parse_insert(input: &str) -> IResult<&str, InsertStmt> {
    let (input, _) = ws(tag_no_case("INSERT"))(input)?;
    let (input, _) = ws(tag_no_case("INTO"))(input)?;
    let (input, _) = ws(tag_no_case("expenses"))(input)?;
    let (input, columns) = delimited(
        ws(char('(')),
        separated_list1(ws(char(',')), map(ws(ident), str::to_string)),
        ws(char(')')),
    )(input)?;
    let (input, _) = ws(tag_no_case("VALUES"))(input)?;
    let (input, values) = delimited(
        ws(char('(')),
        separated_list1(ws(char(',')), ws(parse_value)),
        ws(char(')')),
    )(input)?;
    Ok((input, InsertStmt { columns, values }))
}

// ── SELECT ─────────────────────────────────────────────────────────────────

fn parse_select(input: &str) -> IResult<&str, SelectStmt> {
    let (input, _) = ws(tag_no_case("SELECT"))(input)?;
    let (input, columns) = ws(parse_select_columns)(input)?;
    let (input, _) = ws(tag_no_case("FROM"))(input)?;
    let (input, _) = ws(tag_no_case("expenses"))(input)?;
    let (input, where_clause) = opt(parse_where)(input)?;
    let (input, order_by) = opt(parse_order_by)(input)?;
    let (input, group_by) = opt(parse_group_by)(input)?;
    let (input, limit) = opt(parse_limit)(input)?;
    Ok((input, SelectStmt { columns, where_clause, order_by, group_by, limit }))
}

fn parse_select_columns(input: &str) -> IResult<&str, SelectColumns> {
    alt((
        map(ws(char('*')), |_| SelectColumns::All),
        map(
            separated_list1(ws(char(',')), map(ws(ident), str::to_string)),
            SelectColumns::Named,
        ),
    ))(input)
}

fn parse_where(input: &str) -> IResult<&str, Expr> {
    let (input, _) = ws(tag_no_case("WHERE"))(input)?;
    parse_or_expr(input)
}

fn parse_or_expr(input: &str) -> IResult<&str, Expr> {
    let (input, left) = parse_and_expr(input)?;
    let (input, rest) = nom::multi::many0(preceded(
        ws(tag_no_case("OR")),
        parse_and_expr,
    ))(input)?;
    Ok((input, rest.into_iter().fold(left, |acc, r| Expr::BinaryOp {
        op: BinOp::Or,
        left: Box::new(acc),
        right: Box::new(r),
    })))
}

fn parse_and_expr(input: &str) -> IResult<&str, Expr> {
    let (input, left) = parse_comparison(input)?;
    let (input, rest) = nom::multi::many0(preceded(
        ws(tag_no_case("AND")),
        parse_comparison,
    ))(input)?;
    Ok((input, rest.into_iter().fold(left, |acc, r| Expr::BinaryOp {
        op: BinOp::And,
        left: Box::new(acc),
        right: Box::new(r),
    })))
}

fn parse_comparison(input: &str) -> IResult<&str, Expr> {
    let (input, left) = ws(parse_atom)(input)?;
    let (input, op_str) = ws(alt((
        tag("!="), tag("<="), tag(">="), tag("="), tag("<"), tag(">"),
    )))(input)?;
    let (input, right) = ws(parse_atom)(input)?;
    let op = match op_str {
        "=" => BinOp::Eq,
        "!=" => BinOp::Ne,
        "<" => BinOp::Lt,
        "<=" => BinOp::Le,
        ">" => BinOp::Gt,
        ">=" => BinOp::Ge,
        _ => unreachable!(),
    };
    Ok((input, Expr::BinaryOp { op, left: Box::new(left), right: Box::new(right) }))
}

fn parse_atom(input: &str) -> IResult<&str, Expr> {
    alt((
        map(parse_value, Expr::Literal),
        map(ident, |s| Expr::Column(s.to_string())),
    ))(input)
}

fn parse_order_by(input: &str) -> IResult<&str, OrderBy> {
    let (input, _) = tuple((ws(tag_no_case("ORDER")), ws(tag_no_case("BY"))))(input)?;
    let (input, col) = map(ws(ident), str::to_string)(input)?;
    let (input, dir) = opt(alt((
        map(ws(tag_no_case("ASC")), |_| true),
        map(ws(tag_no_case("DESC")), |_| false),
    )))(input)?;
    Ok((input, OrderBy { column: col, ascending: dir.unwrap_or(true) }))
}

fn parse_group_by(input: &str) -> IResult<&str, Vec<String>> {
    let (input, _) = tuple((ws(tag_no_case("GROUP")), ws(tag_no_case("BY"))))(input)?;
    separated_list1(ws(char(',')), map(ws(ident), str::to_string))(input)
}

fn parse_limit(input: &str) -> IResult<&str, u64> {
    let (input, _) = ws(tag_no_case("LIMIT"))(input)?;
    map(ws(nom::character::complete::u64), |n| n)(input)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_insert_basic() {
        let sql = "INSERT INTO expenses (amount, category, description, date) VALUES (42.5, 'food', 'lunch', '2024-01-01')";
        let stmt = parse(sql).unwrap();
        match stmt {
            Statement::Insert(ins) => {
                assert_eq!(ins.columns, vec!["amount", "category", "description", "date"]);
                assert_eq!(ins.values[0], Value::Real(42.5));
            }
            _ => panic!("expected INSERT"),
        }
    }

    #[test]
    fn parse_select_star() {
        let stmt = parse("SELECT * FROM expenses").unwrap();
        assert!(matches!(stmt, Statement::Select(SelectStmt { columns: SelectColumns::All, .. })));
    }

    #[test]
    fn parse_select_where() {
        let stmt = parse("SELECT * FROM expenses WHERE category = 'food'").unwrap();
        match stmt {
            Statement::Select(sel) => assert!(sel.where_clause.is_some()),
            _ => panic!("expected SELECT"),
        }
    }

    #[test]
    fn parse_select_order_group_limit() {
        let sql = "SELECT category FROM expenses GROUP BY category ORDER BY amount DESC LIMIT 10";
        let stmt = parse(sql).unwrap();
        match stmt {
            Statement::Select(sel) => {
                assert!(sel.group_by.is_some());
                assert!(sel.order_by.is_some());
                assert_eq!(sel.limit, Some(10));
            }
            _ => panic!("expected SELECT"),
        }
    }
}
