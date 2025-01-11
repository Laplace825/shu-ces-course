/// How many addresses in a page. if address is encoded by Byte
pub const PAGE_SIZE: u32 = 1 << 10;

/// The mask to get the offset in a page.
pub const PAGE_OFFSET_MASK: u32 = PAGE_SIZE - 1;

/// How many bits to get the page offset.
pub const PAGE_OFFSET_BITS: u32 = 10;

/// How many pages in the memory.
pub const PAGE_NUM: u32 = 1 << 22;

/// How many bits to get the page id.
pub const PAGE_ID_BITS: u32 = 22;

pub trait Addr: Into<u32> {
    fn addr(&self) -> u32;
}

impl Addr for u32 {
    fn addr(&self) -> u32 {
        *self
    }
}

/** The LogicAddr is 32 bits, and the page size is 1KB.

    ## only 1024 addresses in a page

*/
#[derive(Debug, Clone, Copy)]
pub struct LogicAddr {
    addr: u32,
}

impl LogicAddr {
    pub fn new(addr: impl Into<u32>) -> LogicAddr {
        LogicAddr { addr: addr.into() }
    }
}

impl Addr for LogicAddr {
    fn addr(&self) -> u32 {
        self.addr
    }
}

impl From<u32> for LogicAddr {
    fn from(addr: u32) -> Self {
        LogicAddr::new(addr)
    }
}

impl From<LogicAddr> for u32 {
    fn from(value: LogicAddr) -> Self {
        value.addr()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_addr() {
        let raw_addr = 0x12345678u32;
        let l = LogicAddr::new(raw_addr);
        let x = l.addr();

        assert_eq!(x, raw_addr);
    }
}
