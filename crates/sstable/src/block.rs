/// Data block entry layout (little-endian):
/// [ seq_no(8) | tombstone(1) | key_len(2) | val_len(4) | key | value ]
use crate::{Result, SsTableError};

pub const BLOCK_SIZE: usize = 4096;

#[derive(Debug, Clone)]
pub struct BlockEntry {
    pub seq: u64,
    pub tombstone: bool,
    pub key: Vec<u8>,
    pub value: Vec<u8>,
}

pub struct BlockBuilder {
    data: Vec<u8>,
    last_key: Vec<u8>,
}

impl BlockBuilder {
    pub fn new() -> Self {
        Self { data: Vec::new(), last_key: Vec::new() }
    }

    /// Returns true if the entry was added, false if block is full.
    pub fn add(&mut self, entry: &BlockEntry) -> bool {
        let needed = 8 + 1 + 2 + 4 + entry.key.len() + entry.value.len();
        if !self.data.is_empty() && self.data.len() + needed > BLOCK_SIZE {
            return false;
        }
        self.data.extend_from_slice(&entry.seq.to_le_bytes());
        self.data.push(entry.tombstone as u8);
        self.data.extend_from_slice(&(entry.key.len() as u16).to_le_bytes());
        self.data.extend_from_slice(&(entry.value.len() as u32).to_le_bytes());
        self.data.extend_from_slice(&entry.key);
        self.data.extend_from_slice(&entry.value);
        self.last_key = entry.key.clone();
        true
    }

    pub fn finish(self) -> (Vec<u8>, Vec<u8>) {
        (self.data, self.last_key)
    }

    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}

impl Default for BlockBuilder {
    fn default() -> Self {
        Self::new()
    }
}

pub struct BlockIterator<'a> {
    data: &'a [u8],
    pos: usize,
}

impl<'a> BlockIterator<'a> {
    pub fn new(data: &'a [u8]) -> Self {
        Self { data, pos: 0 }
    }
}

impl<'a> Iterator for BlockIterator<'a> {
    type Item = Result<BlockEntry>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.pos >= self.data.len() {
            return None;
        }
        let buf = &self.data[self.pos..];
        if buf.len() < 8 + 1 + 2 + 4 {
            return Some(Err(SsTableError::Io(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "block entry header truncated",
            ))));
        }
        let seq = u64::from_le_bytes(buf[..8].try_into().unwrap());
        let tombstone = buf[8] != 0;
        let key_len = u16::from_le_bytes(buf[9..11].try_into().unwrap()) as usize;
        let val_len = u32::from_le_bytes(buf[11..15].try_into().unwrap()) as usize;
        let header_end = 15;
        let key_end = header_end + key_len;
        let val_end = key_end + val_len;
        if buf.len() < val_end {
            return Some(Err(SsTableError::Io(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "block entry payload truncated",
            ))));
        }
        let key = buf[header_end..key_end].to_vec();
        let value = buf[key_end..val_end].to_vec();
        self.pos += val_end;
        Some(Ok(BlockEntry { seq, tombstone, key, value }))
    }
}
