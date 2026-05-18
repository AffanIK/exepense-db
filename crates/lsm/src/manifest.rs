use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::{LsmError, Result};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SstMeta {
    pub id: u64,
    pub min_key: Vec<u8>,
    pub max_key: Vec<u8>,
    pub size_bytes: u64,
    pub entry_count: u64,
    pub min_seq: u64,
    pub path: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Manifest {
    pub format_version: u32,
    pub next_seq: u64,
    pub wal_flushed_seq: u64,
    pub next_sst_id: u64,
    /// levels[0] = L0, levels[1] = L1, etc.
    pub levels: Vec<Vec<SstMeta>>,
}

impl Manifest {
    pub fn new() -> Self {
        Self {
            format_version: 1,
            next_seq: 1,
            wal_flushed_seq: 0,
            next_sst_id: 0,
            levels: vec![vec![], vec![], vec![]],
        }
    }

    pub fn load(dir: impl AsRef<Path>) -> Result<Self> {
        let path = manifest_path(dir.as_ref());
        if !path.exists() {
            return Ok(Self::new());
        }
        let bytes = std::fs::read(&path)?;
        let manifest: Manifest = serde_json::from_slice(&bytes)
            .map_err(|e| LsmError::Manifest(e.to_string()))?;
        Ok(manifest)
    }

    /// Write atomically via temp file + rename.
    pub fn save(&self, dir: impl AsRef<Path>) -> Result<()> {
        let dir = dir.as_ref();
        let tmp = tempfile::NamedTempFile::new_in(dir)?;
        serde_json::to_writer_pretty(tmp.as_file(), self)?;
        tmp.as_file().sync_data()?;
        tmp.persist(manifest_path(dir))
            .map_err(|e| LsmError::Manifest(e.to_string()))?;
        Ok(())
    }
}

impl Default for Manifest {
    fn default() -> Self {
        Self::new()
    }
}

fn manifest_path(dir: &Path) -> PathBuf {
    dir.join("manifest.json")
}
