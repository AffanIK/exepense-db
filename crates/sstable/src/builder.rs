use std::io::Write;
use std::path::Path;

use crate::block::{BlockBuilder, BlockEntry};
use crate::bloom::BloomFilter;
use crate::footer::{Footer, FOOTER_SIZE};
use crate::{Result, SsTableError};

/// Index entry: last key of a data block + its offset and length.
#[derive(Debug, Clone)]
pub struct IndexEntry {
    pub last_key: Vec<u8>,
    pub offset: u64,
    pub len: u32,
}

pub struct SsTableBuilder {
    blocks: Vec<(Vec<u8>, u64, u32)>, // (last_key, offset, len)
    current_block: BlockBuilder,
    data_buf: Vec<u8>,
    bloom: BloomFilter,
    entry_count: u64,
    min_seq: u64,
}

impl SsTableBuilder {
    pub fn new(expected_entries: usize) -> Self {
        Self {
            blocks: Vec::new(),
            current_block: BlockBuilder::new(),
            data_buf: Vec::new(),
            bloom: BloomFilter::new(expected_entries),
            entry_count: 0,
            min_seq: u64::MAX,
        }
    }

    /// Add a sorted entry. Callers must provide entries in ascending key order.
    pub fn add(&mut self, key: &[u8], seq: u64, value: Option<&[u8]>) {
        self.bloom.insert(key);
        self.entry_count += 1;
        if seq < self.min_seq { self.min_seq = seq; }

        let entry = BlockEntry {
            seq,
            tombstone: value.is_none(),
            key: key.to_vec(),
            value: value.unwrap_or_default().to_vec(),
        };
        if !self.current_block.add(&entry) {
            self.seal_block();
            self.current_block.add(&entry);
        }
    }

    fn seal_block(&mut self) {
        let builder = std::mem::replace(&mut self.current_block, BlockBuilder::new());
        if builder.is_empty() { return; }
        let (data, last_key) = builder.finish();
        let offset = self.data_buf.len() as u64;
        let len = data.len() as u32;
        self.data_buf.extend_from_slice(&data);
        self.blocks.push((last_key, offset, len));
    }

    /// Finish building and write to a file atomically (temp + rename).
    pub fn finish(mut self, dir: impl AsRef<Path>, sst_id: u64) -> Result<std::path::PathBuf> {
        self.seal_block();

        // Build index block: for each data block, write [last_key_len(2) | last_key | offset(8) | len(4)]
        let mut index_buf = Vec::new();
        for (last_key, offset, len) in &self.blocks {
            index_buf.extend_from_slice(&(last_key.len() as u16).to_le_bytes());
            index_buf.extend_from_slice(last_key);
            index_buf.extend_from_slice(&offset.to_le_bytes());
            index_buf.extend_from_slice(&len.to_le_bytes());
        }

        let bloom_bytes = self.bloom.to_bytes();
        let bloom_bits = self.bloom.bitmap_bits();
        let bloom_k = self.bloom.k_num();

        let index_offset = self.data_buf.len() as u64;
        let index_len = index_buf.len() as u32;
        let bloom_offset = index_offset + index_len as u64;
        let bloom_len = bloom_bytes.len() as u32;

        let footer = Footer {
            index_offset,
            index_len,
            bloom_offset,
            bloom_len,
            entry_count: self.entry_count,
            min_seq: if self.min_seq == u64::MAX { 0 } else { self.min_seq },
            bloom_bits,
            bloom_k,
        };

        // Write to temp file in same directory, then rename
        let dir = dir.as_ref();
        let tmp = tempfile::NamedTempFile::new_in(dir)?;
        {
            let mut f = std::io::BufWriter::new(tmp.as_file());
            f.write_all(&self.data_buf)?;
            f.write_all(&index_buf)?;
            f.write_all(&bloom_bytes)?;
            f.write_all(&footer.encode())?;
            f.flush()?;
            tmp.as_file().sync_data()?;
        }

        let target = dir.join(format!("sst_{:08}.sst", sst_id));
        tmp.persist(&target).map_err(SsTableError::Persist)?;
        Ok(target)
    }
}
