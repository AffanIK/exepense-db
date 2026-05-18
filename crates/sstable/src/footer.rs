/// SSTable footer — always the last 48 bytes of the file.
///
/// Layout (all little-endian):
/// index_offset(8) | index_len(4) | bloom_offset(8) | bloom_len(4)
/// | entry_count(8) | min_seq(8) | bloom_bits(8) | bloom_k(4) | MAGIC(4)
pub const FOOTER_SIZE: usize = 56;
pub const MAGIC: u32 = 0x4C534D54; // "LSMT"

#[derive(Debug, Clone)]
pub struct Footer {
    pub index_offset: u64,
    pub index_len: u32,
    pub bloom_offset: u64,
    pub bloom_len: u32,
    pub entry_count: u64,
    pub min_seq: u64,
    pub bloom_bits: u64,
    pub bloom_k: u32,
}

impl Footer {
    pub fn encode(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(FOOTER_SIZE);
        buf.extend_from_slice(&self.index_offset.to_le_bytes());
        buf.extend_from_slice(&self.index_len.to_le_bytes());
        buf.extend_from_slice(&self.bloom_offset.to_le_bytes());
        buf.extend_from_slice(&self.bloom_len.to_le_bytes());
        buf.extend_from_slice(&self.entry_count.to_le_bytes());
        buf.extend_from_slice(&self.min_seq.to_le_bytes());
        buf.extend_from_slice(&self.bloom_bits.to_le_bytes());
        buf.extend_from_slice(&self.bloom_k.to_le_bytes());
        buf.extend_from_slice(&MAGIC.to_le_bytes());
        buf
    }

    pub fn decode(buf: &[u8]) -> Option<Self> {
        if buf.len() < FOOTER_SIZE {
            return None;
        }
        let b = &buf[buf.len() - FOOTER_SIZE..];
        let magic = u32::from_le_bytes(b[52..56].try_into().unwrap());
        if magic != MAGIC {
            return None;
        }
        Some(Footer {
            index_offset:  u64::from_le_bytes(b[0..8].try_into().unwrap()),
            index_len:     u32::from_le_bytes(b[8..12].try_into().unwrap()),
            bloom_offset:  u64::from_le_bytes(b[12..20].try_into().unwrap()),
            bloom_len:     u32::from_le_bytes(b[20..24].try_into().unwrap()),
            entry_count:   u64::from_le_bytes(b[24..32].try_into().unwrap()),
            min_seq:       u64::from_le_bytes(b[32..40].try_into().unwrap()),
            bloom_bits:    u64::from_le_bytes(b[40..48].try_into().unwrap()),
            bloom_k:       u32::from_le_bytes(b[48..52].try_into().unwrap()),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encode_decode_roundtrip() {
        let f = Footer {
            index_offset: 1024, index_len: 256,
            bloom_offset: 1280, bloom_len: 64,
            entry_count: 100, min_seq: 1,
            bloom_bits: 4096, bloom_k: 7,
        };
        let mut buf = vec![0u8; 100]; // padding before footer
        buf.extend_from_slice(&f.encode());
        let decoded = Footer::decode(&buf).unwrap();
        assert_eq!(decoded.index_offset, 1024);
        assert_eq!(decoded.entry_count, 100);
    }
}
