use std::collections::HashMap;

use addr::PAGE_SIZE;

pub type PhysAddr = u32;
pub type PageId = u32;

/// Page Item struct
///
///
/// `mem_block_id` is the base address of each page
#[derive(Debug, Clone, Copy)]
pub struct Item {
    mem_block_id: u32,
}

impl From<u32> for Item {
    fn from(mem_block_id: u32) -> Self {
        Item { mem_block_id }
    }
}

impl From<Item> for u32 {
    fn from(item: Item) -> u32 {
        item.mem_block_id
    }
}

#[derive(Debug)]
pub struct Table {
    items: HashMap<PageId, Item>,
    len: u32,
}

impl Table {
    pub fn new(length: impl Into<u32>) -> Self {
        let len = length.into();
        let mut items = HashMap::with_capacity(len as usize);
        for i in 0..len {
            items.insert(i, Item::from(i));
        }
        Table { items, len }
    }

    /// return true if the page is empty
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    pub fn len(&self) -> u32 {
        self.len
    }

    pub fn page_addr_of(&mut self, address: impl addr::Addr + Copy) -> Option<PhysAddr> {
        let add = address.addr();
        let offset = add & addr::PAGE_OFFSET_MASK;
        let page_id = add >> addr::PAGE_OFFSET_BITS;
        if page_id >= self.len {
            return None;
        }
        dbg!(page_id);
        dbg!(offset);
        self.items
            .get(&page_id)
            .map(|item| item.mem_block_id * PAGE_SIZE + offset)
    }

    pub fn page_id_of(&self, address: impl addr::Addr + Copy) -> Option<PageId> {
        let add = address.addr();
        let page_id = add >> addr::PAGE_OFFSET_BITS;
        if page_id >= self.len {
            return None;
        }
        Some(page_id)
    }

    /// return none if not exist
    ///
    /// return Some(PhysAddr) if exist
    pub fn delete(&mut self, page_id: impl Into<u32> + Copy) -> Option<PhysAddr> {
        if page_id.into() >= self.len {
            return None;
        }
        match self.items.remove(&page_id.into()) {
            None => None,
            Some(item) => {
                self.len -= 1;
                Some(item.mem_block_id)
            }
        }
    }

    /// if not exist, return None and insert it
    ///
    /// if already exist, return `Some(PhysAddr)`
    pub fn insert(
        &mut self,
        page_id: impl Into<PageId> + Copy,
        item: impl Into<Item>,
    ) -> Option<u32> {
        match self.items.insert(page_id.into(), item.into()) {
            Some(p) => Some(p.mem_block_id),
            None => {
                self.len += 1;
                None
            }
        }
    }
}

impl Default for Table {
    fn default() -> Self {
        Table::new(0u32)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_page_table() {
        let mut page_table = Table::default();

        // page 0 is mem block 0 ( addr begin is 0)
        assert_eq!(page_table.insert(0u32, 0u32), None);

        let mut addr = 1022 + (0 << addr::PAGE_OFFSET_BITS);
        assert_eq!(page_table.page_addr_of(addr), Some(1022));

        // duplicate insert will return Some(K),
        // `K` is the mem block id that already exist
        assert_eq!(page_table.insert(0u32, 1u32), Some(0u32));

        // page 1 is mem block 2 ( addr begin is 2048)
        assert_eq!(page_table.insert(1u32, 2u32), None);

        // page 1 , page offset 1022
        addr = 1022 + (1 << addr::PAGE_OFFSET_BITS);
        assert_eq!(page_table.page_addr_of(addr), Some(2048 + 1022));

        // page 2, page offset 1022 will not be found.
        // Result will be None
        assert_eq!(
            page_table.page_addr_of(addr + (1 << addr::PAGE_OFFSET_BITS)),
            None
        );
    }
}
