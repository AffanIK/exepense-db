/// Binary layout (all little-endian):
/// [ crc32(4) | seq_no(8) | key_len(4) | val_len(4) | key | value ]
/// CRC32 covers seq_no..end.
/// val_len == u32::MAX signals a tombstone; no value bytes follow.
use bincode::{config, decode_from_slice, encode_to_vec};
use bincode::Encode;
use bincode::Decode;
use crc32fast::Hasher;

use crate::{Result, WalError};

pub const TOMBSTONE_SENTINEL: u32 = u32::MAX;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WalRecord {
    pub seq_no: u64,
    pub key: Vec<u8>,
    /// None = tombstone
    pub value: Option<Vec<u8>>,
}

#[derive(Encode, Decode)]
struct RecordHeader {
    seq_no: u64,
    key_len: u32,
    val_len: u32,
}

impl WalRecord {
    /// Serialize to bytes: [crc32(4) | header(16) | key | value?]
    pub fn encode(&self) -> Result<Vec<u8>> {
        let val_len = match &self.value {
            Some(v) => v.len() as u32,
            None => TOMBSTONE_SENTINEL,
        };
        let header = RecordHeader {
            seq_no: self.seq_no,
            key_len: self.key.len() as u32,
            val_len,
        };
        let cfg = config::standard();
        let header_bytes = encode_to_vec(&header, cfg)?;

        let mut payload = header_bytes;
        payload.extend_from_slice(&self.key);
        if let Some(v) = &self.value {
            payload.extend_from_slice(v);
        }

        let mut hasher = Hasher::new();
        hasher.update(&payload);
        let crc = hasher.finalize();

        let mut out = Vec::with_capacity(4 + payload.len());
        out.extend_from_slice(&crc.to_le_bytes());
        out.extend_from_slice(&payload);
        Ok(out)
    }

    /// Decode one record from a byte slice.
    /// Returns `(record, bytes_consumed)`.
    pub fn decode(buf: &[u8]) -> Result<(Self, usize)> {
        if buf.len() < 4 {
            return Err(WalError::Io(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "buffer too short for CRC",
            )));
        }
        let stored_crc = u32::from_le_bytes(buf[..4].try_into().unwrap());
        let payload_start = 4;

        let cfg = config::standard();
        let (header, header_len): (RecordHeader, usize) =
            decode_from_slice(&buf[payload_start..], cfg)?;

        let key_start = payload_start + header_len;
        let val_len_usize = if header.val_len == TOMBSTONE_SENTINEL {
            0
        } else {
            header.val_len as usize
        };
        let key_end = key_start + header.key_len as usize;
        let val_end = key_end + val_len_usize;

        if buf.len() < val_end {
            return Err(WalError::Io(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "buffer too short for key/value payload",
            )));
        }

        let mut hasher = Hasher::new();
        hasher.update(&buf[payload_start..val_end]);
        let actual_crc = hasher.finalize();

        if actual_crc != stored_crc {
            return Err(WalError::CrcMismatch {
                expected: stored_crc,
                actual: actual_crc,
            });
        }

        let key = buf[key_start..key_end].to_vec();
        let value = if header.val_len == TOMBSTONE_SENTINEL {
            None
        } else {
            Some(buf[key_end..val_end].to_vec())
        };

        Ok((WalRecord { seq_no: header.seq_no, key, value }, val_end))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip_value() {
        let rec = WalRecord { seq_no: 42, key: b"hello".to_vec(), value: Some(b"world".to_vec()) };
        let bytes = rec.encode().unwrap();
        let (decoded, consumed) = WalRecord::decode(&bytes).unwrap();
        assert_eq!(decoded, rec);
        assert_eq!(consumed, bytes.len());
    }

    #[test]
    fn roundtrip_tombstone() {
        let rec = WalRecord { seq_no: 7, key: b"bye".to_vec(), value: None };
        let bytes = rec.encode().unwrap();
        let (decoded, _) = WalRecord::decode(&bytes).unwrap();
        assert_eq!(decoded, rec);
    }

    #[test]
    fn crc_mismatch_detected() {
        let rec = WalRecord { seq_no: 1, key: b"k".to_vec(), value: Some(b"v".to_vec()) };
        let mut bytes = rec.encode().unwrap();
        bytes[0] ^= 0xFF; // corrupt CRC
        assert!(matches!(WalRecord::decode(&bytes), Err(WalError::CrcMismatch { .. })));
    }
}
