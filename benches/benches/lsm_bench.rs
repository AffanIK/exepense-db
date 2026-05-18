use criterion::{criterion_group, criterion_main, Criterion};
// LSM engine benchmarks — to be filled in after Phase 4.
fn bench_placeholder(c: &mut Criterion) {
    c.bench_function("lsm_placeholder", |b| b.iter(|| {}));
}
criterion_group!(benches, bench_placeholder);
criterion_main!(benches);
