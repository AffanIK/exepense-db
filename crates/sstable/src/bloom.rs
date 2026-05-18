use bloomfilter::Bloom;

/// Wraps a Bloom filter for SSTable key membership testing.
pub struct BloomFilter {
    inner: Bloom<Vec<u8>>,
}

impl BloomFilter {
    pub fn new(expected_items: usize) -> Self {
        // Target ~1% false positive rate
        let inner = Bloom::new_for_fp_rate(expected_items.max(1), 0.01);
        Self { inner }
    }

    pub fn insert(&mut self, key: &[u8]) {
        self.inner.set(&key.to_vec());
    }

    pub fn contains(&self, key: &[u8]) -> bool {
        self.inner.check(&key.to_vec())
    }

    pub fn to_bytes(&self) -> Vec<u8> {
        bincode::encode_to_vec(&self.inner.bitmap(), bincode::config::standard())
            .unwrap_or_default()
    }

    pub fn from_bytes(bytes: &[u8], bitmap_bits: u64, k_num: u32) -> Self {
        let bitmap: Vec<u8> = bincode::decode_from_slice(bytes, bincode::config::standard())
            .map(|(v, _)| v)
            .unwrap_or_default();
        let inner = Bloom::from_existing(&bitmap, bitmap_bits, k_num, [(0, 0), (1, 1), (2, 2), (3, 3)]);
        Self { inner }
    }

    pub fn bitmap_bits(&self) -> u64 {
        self.inner.number_of_bits()
    }

    pub fn k_num(&self) -> u32 {
        self.inner.number_of_hash_functions()
    }
}
