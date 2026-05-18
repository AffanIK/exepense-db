#[derive(Debug, Clone, PartialEq)]
pub enum Statement {
    Insert(InsertStmt),
    Select(SelectStmt),
}

#[derive(Debug, Clone, PartialEq)]
pub struct InsertStmt {
    pub columns: Vec<String>,
    pub values: Vec<Value>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SelectStmt {
    pub columns: SelectColumns,
    pub where_clause: Option<Expr>,
    pub order_by: Option<OrderBy>,
    pub group_by: Option<Vec<String>>,
    pub limit: Option<u64>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum SelectColumns {
    All,
    Named(Vec<String>),
}

#[derive(Debug, Clone, PartialEq)]
pub struct OrderBy {
    pub column: String,
    pub ascending: bool,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
    Column(String),
    Literal(Value),
    BinaryOp {
        op: BinOp,
        left: Box<Expr>,
        right: Box<Expr>,
    },
}

#[derive(Debug, Clone, PartialEq)]
pub enum BinOp {
    Eq,
    Ne,
    Lt,
    Le,
    Gt,
    Ge,
    And,
    Or,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Text(String),
    Real(f64),
    Integer(i64),
    Null,
}
