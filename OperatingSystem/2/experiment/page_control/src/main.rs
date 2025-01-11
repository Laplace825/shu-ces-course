#![allow(clippy::upper_case_acronyms)]

use addr::{PAGE_OFFSET_BITS, PAGE_SIZE};
use colored::Colorize;
use page::PhysAddr;

use std::{
    cell::Cell,
    collections::{HashMap, VecDeque},
};

fn main() {
    let mut algo_type = Algo::FIFO;

    std::env::args().skip(1).for_each(|x| match x.as_str() {
        "FIFO" => algo_type = Algo::FIFO,
        "LRU" => algo_type = Algo::LRU,
        "OPT" => algo_type = Algo::OPT,
        _ => {}
    });

    // generate 150 random page id
    let mut page_ids = Vec::with_capacity(1024);
    for _ in 0..1024 {
        page_ids.push(rand::random::<u32>() % 32);
    }

    // page_ids.extend_from_slice(&[0, 4, 4, 5, 1, 4, 2, 5, 4, 2, 3, 1, 0, 45, 24, 0, 2]);
    // dbg!(&page_ids);

    for i in (2..34).step_by(2) {
        println!("{} {}", "Mem: ".blue(), i);
        let mut ctrl = Controller::new(i, 1u32, algo_type);
        ctrl.in_pages(&page_ids);
        ctrl.summary();
    }

    let mut ctrl = Controller::new(32u32, 1u32, Algo::FIFO);
    let mut page_ids = Vec::with_capacity(32);
    for _ in 0..32 {
        page_ids.push(rand::random::<u32>() % 32);
    }

    let mut addrs = Vec::with_capacity(32);

    for p in page_ids.iter().take(32) {
        addrs.push(rand::random::<u32>() % PAGE_SIZE + (p << PAGE_OFFSET_BITS));
    }

    for addr in addrs {
        if let Some(page_id) = ctrl.addr_trans2page_id(addr) {
            println!(
                "{} {:#x}\t->\t{} {:#x} ",
                "Addr :".green(),
                addr,
                "Page Id: ".green(),
                page_id
            );
        }
    }

    // ctrl.clear();
    // ctrl.set_algo_type(Algo::LRU);
    // ctrl.in_pages(&page_ids);
    // ctrl.summary();
    //
    // ctrl.clear();
    // ctrl.set_algo_type(Algo::OPT);
    // ctrl.in_pages(&page_ids);
    // ctrl.summary();
}

#[derive(Debug, Default, Clone, Copy)]
#[repr(u8)]
enum Algo {
    LRU,
    #[default]
    FIFO,
    OPT,
}

// #[derive(Debug)]
#[repr(C)]
struct Controller {
    alog_type: Algo,
    mem_block_size: u32, // KB
    mem_block_num: u32,  // how many
    page_table: Cell<page::Table>,
    page_in_use: Cell<HashMap<page::PageId, bool>>,
    page_table_len: u32,
    machine: Cell<Box<dyn Schedule>>,
}

impl Controller {
    /// if mem_block_size == 0, set to 32KB
    /// if mem_block_num == 0, set to 2
    fn new<Number>(mem_block_size: Number, mem_block_num: Number, algo_type: Algo) -> Self
    where
        Number: Into<u32> + Copy,
    {
        let mut mbs = mem_block_size.into();
        if mbs == 0 {
            mbs = 32;
        }
        let mbn = mem_block_num.into();
        if mbn == 0 {
            mbs = 2;
        }
        let table_len = mbs * mbn * 1024 / addr::PAGE_SIZE;
        let mut machine: Box<dyn Schedule> = Box::new(FIFOMachine::new(table_len));
        match algo_type {
            Algo::FIFO => {
                machine = Box::new(FIFOMachine::new(table_len));
            }
            Algo::LRU => {
                machine = Box::new(LRUMachine::new(table_len));
            }
            Algo::OPT => {
                machine = Box::new(OPTMachine::new(table_len));
            }
        }

        Controller {
            mem_block_size: mbs,
            mem_block_num: mbn,
            page_table: Cell::new(page::Table::new(table_len)), // page_size is 1024( 1KB )
            alog_type: algo_type,
            page_in_use: Cell::new(HashMap::with_capacity(table_len as usize)),
            page_table_len: table_len,
            machine: Cell::new(machine),
        }
    }

    fn addr_trans(&mut self, address: impl addr::Addr + Copy) -> Option<PhysAddr> {
        self.page_table.get_mut().page_addr_of(address)
    }

    fn addr_trans2page_id(&mut self, address: impl addr::Addr + Copy) -> Option<page::PageId> {
        self.page_table.get_mut().page_id_of(address)
    }

    fn clear(&mut self) {
        self.page_in_use.get_mut().clear();
        self.machine.get_mut().clear();
    }

    fn set_algo_type(&mut self, algo_type: Algo) {
        self.alog_type = algo_type;
        match algo_type {
            Algo::FIFO => {
                self.machine
                    .set(Box::new(FIFOMachine::new(self.page_table_len)));
            }
            Algo::LRU => {
                self.machine
                    .set(Box::new(LRUMachine::new(self.page_table_len)));
            }
            Algo::OPT => {
                self.machine
                    .set(Box::new(OPTMachine::new(self.page_table_len)));
            }
        }
    }

    fn sche(&mut self, page_id: page::PageId, page_act: PageAction) {
        self.machine
            .get_mut()
            .sche(page_id, page_act, self.page_in_use.get_mut());
        // self.machine.get_mut().show();
    }

    fn in_pages(&mut self, page_ids: &[page::PageId]) {
        match self.alog_type {
            Algo::OPT => {
                self.machine
                    .get_mut()
                    .in_pages(page_ids, self.page_in_use.get_mut());
            }
            _ => {
                for page_id in page_ids {
                    self.sche(*page_id, PageAction::In);
                }
            }
        }
    }

    fn summary(&mut self) {
        let (page_loss_times, page_in_times) = self.machine.get_mut().summary();
        let page_loss_ratio = page_loss_times as f32 / page_in_times as f32;
        println!("\t {}", format!("{:?}", self.alog_type).yellow());

        println!(
            "{} {}",
            "\t-> | The page loss times: ".yellow(),
            page_loss_times
        );
        // println!(
        //     "{} {}",
        //     "\t-> | The page in times: ".yellow(),
        //     page_in_times
        // );
        println!(
            "{} {:#.2}",
            "\t-> | The page loss ratio: ".yellow(),
            page_loss_ratio
        );
    }
}

impl Default for Controller {
    fn default() -> Self {
        Controller::new(32u32, 2u32, Algo::FIFO)
    }
}

#[derive(Clone, Copy)]
enum PageAction {
    In,
    Out,
}

trait Schedule {
    fn sche(
        &mut self,
        page_id: page::PageId,
        page_act: PageAction,
        page_in_use: &mut HashMap<page::PageId, bool>,
    ) {
        match page_act {
            PageAction::In => {
                self.in_page(page_id);
                page_in_use.insert(page_id, true);
            }
            PageAction::Out => {
                if let Some(page_id) = self.out_page(page_id) {
                    if let Some(x) = page_in_use.get_mut(&page_id) {
                        *x = false;
                    }
                }
            }
        }
    }

    /// returns true if is empty
    fn is_empty(&self) -> bool;

    /// returns true if is full
    fn is_full(&self) -> bool;

    /// page in action
    fn in_page(&mut self, page_id: page::PageId);

    fn in_pages(
        &mut self,
        page_ids: &[page::PageId],
        page_in_use: &mut HashMap<page::PageId, bool>,
    ) {
        for page_id in page_ids {
            self.in_page(*page_id);
            page_in_use.insert(*page_id, true);
        }
    }

    /// page out action
    fn out_page(&mut self, page_id: page::PageId) -> Option<page::PageId>;

    /// show the page in the schedule
    fn show(&self);

    fn summary(&self) -> (u32, u32);

    fn clear(&mut self);
}

struct FIFOMachine {
    queue: VecDeque<page::PageId>,
    page_loss_times: u32,
    page_in_times: u32,
}
struct LRUMachine {
    queue: VecDeque<page::PageId>,
    hit_counter: HashMap<page::PageId, u32>,
    page_loss_times: u32,
    page_in_times: u32,
}
struct OPTMachine {
    queue: VecDeque<page::PageId>,
    page_loss_times: u32,
    page_in_times: u32,
    future_pages: VecDeque<page::PageId>, // the future page id
}

impl FIFOMachine {
    fn new(capacity: impl Into<u32> + Copy) -> Self {
        FIFOMachine {
            queue: VecDeque::with_capacity(capacity.into() as usize),
            page_loss_times: 0,
            page_in_times: 0,
        }
    }

    fn is_exist(&self, page_id: page::PageId) -> bool {
        self.queue.contains(&page_id)
    }
}

impl Schedule for FIFOMachine {
    fn is_empty(&self) -> bool {
        self.queue.is_empty()
    }

    fn is_full(&self) -> bool {
        self.queue.len() == self.queue.capacity()
    }

    fn in_page(&mut self, page_id: page::PageId) {
        // println!("{} {}", "in page:".green(), page_id);
        self.page_in_times += 1;
        if self.is_exist(page_id) {
            // println!("{} {}", "Hit :".yellow(), page_id);
            return;
        }
        if self.is_full() {
            if let Some(o) = self.out_page(page_id) {
                //     println!("{} {}", "out page:".blue(), o);
            }

            self.queue.push_back(page_id);
            return;
        }

        self.page_loss_times += 1;
        self.queue.push_back(page_id);
    }

    /// FIFO just pop the first page
    fn out_page(&mut self, _: page::PageId) -> Option<page::PageId> {
        if let Some(p) = self.queue.pop_front() {
            self.page_loss_times += 1;
            return Some(p);
        }
        None
    }

    fn show(&self) {
        for i in 0..self.queue.capacity() {
            match self.queue.get(i) {
                Some(p) => print!(" {:_^5} ", p),
                None => {
                    let s = "_".repeat(4);
                    print!(" {s} ")
                }
            }
        }
        println!()
    }

    fn summary(&self) -> (u32, u32) {
        (self.page_loss_times, self.page_in_times)
    }

    fn clear(&mut self) {
        self.queue.clear();
        self.page_loss_times = 0;
        self.page_in_times = 0;
    }
}

impl LRUMachine {
    fn new(capacity: impl Into<u32> + Copy) -> Self {
        LRUMachine {
            queue: VecDeque::with_capacity(capacity.into() as usize),
            hit_counter: HashMap::new(),
            page_loss_times: 0,
            page_in_times: 0,
        }
    }

    fn is_exist(&mut self, page_id: page::PageId) -> bool {
        if let Some(x) = self.hit_counter.get_mut(&page_id) {
            *x += 1;
            return true;
        }
        false
    }
}

impl Schedule for LRUMachine {
    fn is_empty(&self) -> bool {
        self.queue.is_empty()
    }

    fn is_full(&self) -> bool {
        self.queue.len() == self.queue.capacity()
    }

    fn in_page(&mut self, page_id: page::PageId) {
        // println!("{} {}", "in page:".green(), page_id);
        // is already in the queue
        self.page_in_times += 1;
        if self.is_exist(page_id) {
            // println!("{} {}", "Hit :".yellow(), page_id);
            return;
        }

        self.page_loss_times += 1;
        if self.is_full() {
            let most_unuse = *self.hit_counter.iter().min_by_key(|x| x.1).unwrap().0;
            // println!("{} {}", "least used page:".blue(), most_unuse);
            // println!(
            //     "{} {} with {}",
            //     "exchange page:".blue(),
            //     most_unuse,
            //     page_id
            // );
            self.out_page(most_unuse);
            self.hit_counter.insert(page_id, 1);
            let pos = self.queue.iter().position(|x| *x == most_unuse).unwrap();
            if let Some(x) = self.queue.get_mut(pos) {
                *x = page_id;
            }

            return;
        }
        self.queue.push_back(page_id);
        self.hit_counter.insert(page_id, 0);
    }

    fn out_page(&mut self, page_id: page::PageId) -> Option<page::PageId> {
        self.hit_counter.iter_mut().for_each(|x| *x.1 = 0);
        self.hit_counter.remove(&page_id)?;
        None
    }

    fn show(&self) {
        for i in 0..self.queue.capacity() {
            match self.queue.get(i) {
                Some(p) => print!(" {:_^5} ", p),
                None => {
                    let s = "_".repeat(4);
                    print!(" {s} ")
                }
            }
        }
        println!()
    }

    fn summary(&self) -> (u32, u32) {
        (self.page_loss_times, self.page_in_times)
    }

    fn clear(&mut self) {
        self.page_in_times = 0;
        self.page_loss_times = 0;
        self.queue.clear();
        self.hit_counter.clear();
    }
}

impl OPTMachine {
    fn new(capacity: impl Into<u32> + Copy) -> Self {
        OPTMachine {
            queue: VecDeque::with_capacity(capacity.into() as usize),
            future_pages: VecDeque::new(),
            page_loss_times: 0,
            page_in_times: 0,
        }
    }
}

impl Schedule for OPTMachine {
    fn is_full(&self) -> bool {
        self.queue.len() == self.queue.capacity()
    }

    fn is_empty(&self) -> bool {
        self.queue.is_empty()
    }

    fn in_pages(
        &mut self,
        page_ids: &[page::PageId],
        page_in_use: &mut HashMap<page::PageId, bool>,
    ) {
        // for i in 0..self.queue.capacity() {
        //     let page_id = page_ids[i];
        //     self.in_page(page_id);
        //     page_in_use.insert(page_id, true);
        // }
        self.future_pages.extend(page_ids);

        // dbg!(&self.future_pages);
        // self.show();

        let futures_iter_clone = self.future_pages.clone();
        for page_id in futures_iter_clone {
            if self.is_empty() {
                self.in_page(page_id);
                self.future_pages.pop_front();
                continue;
            }
            let mut is_ok_in_future =
                HashMap::<page::PageId, bool>::with_capacity(self.queue.len());
            self.queue.iter().for_each(|p| {
                is_ok_in_future.insert(*p, false);
            });

            self.page_in_times += 1;
            // println!("{} {}", "in page:".green(), page_id);

            if self.queue.contains(&page_id) {
                // println!("{} {}", "Hit :".yellow(), page_id);
                self.future_pages.pop_front();
                continue;
            }

            if self.is_full() {
                self.page_loss_times += 1;
                for id in self.future_pages.iter() {
                    if self.queue.contains(id) {
                        *is_ok_in_future.get_mut(id).unwrap() = true;
                    }
                    // count how many true in the is_ok_in_future
                    // if the count is equal to the queue.len() - 1, then break
                    if is_ok_in_future.values().filter(|x| **x).count() == self.queue.len() - 1 {
                        break;
                    }
                }

                if let Some(which_to_exchange) = is_ok_in_future.iter().find(|x| !*x.1) {
                    // println!(
                    //     "{} {} with {}",
                    //     "exchange page:".blue(),
                    //     which_to_exchange.0,
                    //     page_id,
                    // );
                    let pos = self
                        .queue
                        .iter()
                        .position(|x| *x == *which_to_exchange.0)
                        .unwrap();
                    *self.queue.get_mut(pos).unwrap() = page_id;
                }
            } else {
                self.in_page(page_id);
            }

            self.future_pages.pop_front();
            // dbg!(&self.future_pages);
            // self.show();
        }
    }

    fn in_page(&mut self, page_id: page::PageId) {
        self.page_in_times += 1;
        self.page_loss_times += 1;
        self.queue.push_back(page_id);
    }

    fn out_page(&mut self, page_id: page::PageId) -> Option<page::PageId> {
        None
    }

    fn show(&self) {
        for i in 0..self.queue.capacity() {
            match self.queue.get(i) {
                Some(p) => print!(" {:_^5} ", p),
                None => {
                    let s = "_".repeat(4);
                    print!(" {s} ")
                }
            }
        }
        println!()
    }

    fn summary(&self) -> (u32, u32) {
        (self.page_loss_times, self.page_in_times)
    }

    fn clear(&mut self) {
        self.page_in_times = 0;
        self.page_loss_times = 0;
        self.queue.clear();
        self.future_pages.clear();
    }
}
