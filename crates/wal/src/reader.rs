use std::fs::File;
use std::io::Read;
use std::path::Path;

use crate::{Result, WalError, WalRecord};

pub struct WalReader {
    data: Vec<u8>,
    pos: usize,
}

impl WalReader {
    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        let mut file = File::open(path)?;
        let mut data = Vec::new();
        file.read_to_end(&mut data)?;
        Ok(Self { data, pos: 0 })
    }

    /// Truncate the WAL file, keeping only records with seq_no > flushed_seq.
    /// Reads all records, rewrites those above the threshold.
    pub fn truncate_after(path: impl AsRef<Path>, flushed_seq: u64) -> Result<()> {
        let reader = Self::open(&path)?;
        let records: Vec<WalRecord> = reader
            .filter_map(|r| r.ok())
            .filter(|r| r.seq_no > flushed_seq)
            .collect();

        // Rewrite the file atomically via temp file + rename
        let dir = path.as_ref().parent().unwrap_or(Path::new("."));
        let tmp = tempfile::NamedTempFile::new_in(dir)?;
        {
            use std::io::Write;
            let mut f = std::io::BufWriter::new(tmp.as_file());
            for rec in &records {
                let bytes = rec.encode()?;
                f.write_all(&bytes)?;
            }
            f.flush()?;
            tmp.as_file().sync_data()?;
        }
        tmp.persist(&path).map_err(WalError::from)?;
        Ok(())
    }
}

impl Iterator for WalReader {
    type Item = Result<WalRecord>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.pos >= self.data.len() {
            return None;
        }
        match WalRecord::decode(&self.data[self.pos..]) {
            Ok((record, consumed)) => {
                self.pos += consumed;
                Some(Ok(record))
            }
            Err(WalError::Io(_)) => None, // partial write at end of file — stop cleanly
            Err(e) => Some(Err(e)),
        }
    }
}
