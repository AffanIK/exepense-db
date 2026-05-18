// Query executor — to be implemented in Phase 7.
use std::sync::Arc;
use lsm::LsmEngine;

pub struct Executor {
    engine: Arc<LsmEngine>,
}

impl Executor {
    pub fn new(engine: Arc<LsmEngine>) -> Self {
        Self { engine }
    }
}
