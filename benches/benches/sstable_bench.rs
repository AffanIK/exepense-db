use criterion::{criterion_group, criterion_main, Criterion};
// SSTable benchmarks — to be filled in after Phase 3.
fn bench_placeholder(c: &mut Criterion) {
    c.bench_function("sstable_placeholder", |b| b.iter(|| {}));
}
criterion_group!(benches, bench_placeholder);
criterion_main!(benches);
