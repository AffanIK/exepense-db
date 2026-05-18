use std::path::Path;
use memtable::ImmutableMemTable;

use crate::manifest::SstMeta;
use crate::Result;

/// Flush an immutable MemTable to an SSTable file.
/// Returns the SSTableMeta for the new file.
pub fn flush_to_sstable(
    imm: &ImmutableMemTable,
    dir: impl AsRef<Path>,
    sst_id: u64,
) -> Result<SstMeta> {
    let dir = dir.as_ref();
    let entry_count = imm.entries.len();
    let mut builder = sstable::SsTableBuilder::new(entry_count);

    let mut min_key = None;
    let mut max_key = None;

    for (key, val) in imm.iter() {
        let value_bytes = match val {
            memtable::VersionedValue::Value { data, seq } => {
                builder.add(key, *seq, Some(data));
                Some(data.as_slice())
            }
            memtable::VersionedValue::Tombstone { seq } => {
                builder.add(key, *seq, None);
                None
            }
        };
        if min_key.is_none() {
            min_key = Some(key.clone());
        }
        max_key = Some(key.clone());
        let _ = value_bytes;
    }

    let path = builder.finish(dir, sst_id)?;

    Ok(SstMeta {
        id: sst_id,
        min_key: min_key.unwrap_or_default(),
        max_key: max_key.unwrap_or_default(),
        size_bytes: std::fs::metadata(&path)?.len(),
        entry_count: entry_count as u64,
        min_seq: 0,
        path,
    })
}
