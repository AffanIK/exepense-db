use criterion::{criterion_group, criterion_main, Criterion};
use memtable::MemTable;
use std::sync::Arc;

fn bench_memtable_put(c: &mut Criterion) {
    c.bench_function("memtable_put", |b| {
        let mt = Arc::new(MemTable::new());
        let mut seq = 0u64;
        b.iter(|| {
            seq += 1;
            mt.put(format!("key_{}", seq).into_bytes(), b"value".to_vec(), seq).unwrap();
        });
    });
}

criterion_group!(benches, bench_memtable_put);
criterion_main!(benches);
