use std::fs::{File, OpenOptions};
use std::io::{BufWriter, Write};
use std::path::Path;

use crate::{Result, WalRecord};

pub struct WalWriter {
    inner: BufWriter<File>,
    path: std::path::PathBuf,
}

impl WalWriter {
    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref().to_path_buf();
        let file = OpenOptions::new().create(true).append(true).open(&path)?;
        Ok(Self { inner: BufWriter::new(file), path })
    }

    pub fn append(&mut self, record: &WalRecord) -> Result<()> {
        let bytes = record.encode()?;
        self.inner.write_all(&bytes)?;
        self.inner.flush()?;
        self.inner.get_ref().sync_data()?;
        Ok(())
    }

    pub fn path(&self) -> &Path {
        &self.path
    }
}
