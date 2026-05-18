use std::path::Path;
use std::sync::Arc;

use memmap2::Mmap;

use crate::block::BlockIterator;
use crate::bloom::BloomFilter;
use crate::footer::{Footer, FOOTER_SIZE};
use crate::{Result, SsTableError};

pub struct SsTableReader {
    mmap: Arc<Mmap>,
    footer: Footer,
    bloom: BloomFilter,
    pub path: std::path::PathBuf,
}

impl SsTableReader {
    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref().to_path_buf();
        let file = std::fs::File::open(&path)?;
        let mmap = unsafe { Mmap::map(&file)? };

        if mmap.len() < FOOTER_SIZE {
            return Err(SsTableError::FileTooSmall);
        }

        let footer = Footer::decode(&mmap).ok_or(SsTableError::InvalidMagic)?;

        let bloom_start = footer.bloom_offset as usize;
        let bloom_end = bloom_start + footer.bloom_len as usize;
        let bloom = BloomFilter::from_bytes(
            &mmap[bloom_start..bloom_end],
            footer.bloom_bits,
            footer.bloom_k,
        );

        Ok(Self { mmap: Arc::new(mmap), footer, bloom, path })
    }

    /// Point lookup for a key visible at `read_seq`.
    pub fn get(&self, key: &[u8], read_seq: u64) -> Result<Option<Vec<u8>>> {
        if !self.bloom.contains(key) {
            return Ok(None);
        }

        // Binary search index to find candidate block
        let block_data = self.find_block(key)?;
        if block_data.is_none() {
            return Ok(None);
        }
        let (block_offset, block_len) = block_data.unwrap();
        let block_bytes = &self.mmap[block_offset..block_offset + block_len];

        let mut result = None;
        for entry in BlockIterator::new(block_bytes) {
            let entry = entry?;
            if entry.key == key && entry.seq <= read_seq {
                if entry.tombstone {
                    return Ok(None);
                }
                result = Some(entry.value);
            }
        }
        Ok(result)
    }

    /// Iterate all entries in this SSTable.
    pub fn iter(&self) -> SsTableIter {
        let data_end = self.footer.index_offset as usize;
        SsTableIter {
            mmap: Arc::clone(&self.mmap),
            pos: 0,
            data_end,
        }
    }

    pub fn footer(&self) -> &Footer {
        &self.footer
    }

    fn find_block(&self, key: &[u8]) -> Result<Option<(usize, usize)>> {
        let index_start = self.footer.index_offset as usize;
        let index_end = index_start + self.footer.index_len as usize;
        let index_buf = &self.mmap[index_start..index_end];

        let mut pos = 0;
        let mut best: Option<(usize, usize)> = None;

        while pos < index_buf.len() {
            if index_buf.len() - pos < 2 { break; }
            let last_key_len = u16::from_le_bytes(index_buf[pos..pos+2].try_into().unwrap()) as usize;
            pos += 2;
            if index_buf.len() - pos < last_key_len + 8 + 4 { break; }
            let last_key = &index_buf[pos..pos + last_key_len];
            pos += last_key_len;
            let offset = u64::from_le_bytes(index_buf[pos..pos+8].try_into().unwrap()) as usize;
            pos += 8;
            let len = u32::from_le_bytes(index_buf[pos..pos+4].try_into().unwrap()) as usize;
            pos += 4;

            if last_key >= key {
                best = Some((offset, len));
                break;
            }
        }
        Ok(best)
    }
}

pub struct SsTableIter {
    mmap: Arc<Mmap>,
    pos: usize,
    data_end: usize,
}

impl Iterator for SsTableIter {
    type Item = Result<(Vec<u8>, u64, bool, Vec<u8>)>; // (key, seq, tombstone, value)

    fn next(&mut self) -> Option<Self::Item> {
        if self.pos >= self.data_end {
            return None;
        }
        let buf = &self.mmap[self.pos..self.data_end];
        let mut iter = BlockIterator::new(buf);
        match iter.next() {
            Some(Ok(e)) => {
                self.pos += 8 + 1 + 2 + 4 + e.key.len() + e.value.len();
                Some(Ok((e.key, e.seq, e.tombstone, e.value)))
            }
            Some(Err(e)) => Some(Err(e)),
            None => None,
        }
    }
}
