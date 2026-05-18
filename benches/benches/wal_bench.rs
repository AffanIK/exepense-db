use criterion::{criterion_group, criterion_main, BenchmarkId, Criterion};
use tempfile::tempdir;
use wal::{WalRecord, WalWriter};

fn bench_wal_append(c: &mut Criterion) {
    let mut group = c.benchmark_group("wal_append");
    for size in [64usize, 1024, 4096] {
        group.bench_with_input(BenchmarkId::from_parameter(size), &size, |b, &sz| {
            let dir = tempdir().unwrap();
            let mut writer = WalWriter::open(dir.path().join("bench.wal")).unwrap();
            let record = WalRecord {
                seq_no: 1,
                key: b"bench_key".to_vec(),
                value: Some(vec![0u8; sz]),
            };
            b.iter(|| writer.append(&record).unwrap());
        });
    }
    group.finish();
}

criterion_group!(benches, bench_wal_append);
criterion_main!(benches);
