#[derive(Debug, Clone, PartialEq, Eq)]
pub enum VersionedValue {
    Value { data: Vec<u8>, seq: u64 },
    Tombstone { seq: u64 },
}

impl VersionedValue {
    pub fn seq(&self) -> u64 {
        match self {
            Self::Value { seq, .. } | Self::Tombstone { seq } => *seq,
        }
    }

    pub fn is_tombstone(&self) -> bool {
        matches!(self, Self::Tombstone { .. })
    }

    /// Returns the data if this is a live value and seq <= read_seq.
    pub fn read_at(&self, read_seq: u64) -> Option<&[u8]> {
        match self {
            Self::Value { data, seq } if *seq <= read_seq => Some(data),
            _ => None,
        }
    }
}
