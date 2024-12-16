#![allow(dead_code)]

use core::fmt;
use std::{cell::RefCell, collections::HashMap, fmt::Debug, marker::PhantomData};

fn generate_pid() -> u32 {
    // make this thread safe
    static mut PID: u32 = 0;
    unsafe {
        PID += 1;
        PID
    }
}

#[derive(Debug, Default, Clone, Copy, PartialEq)]
#[repr(u32)]
pub enum State {
    #[default]
    Waiting,
    Running,
    Finished,
}

impl fmt::Display for State {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            State::Waiting => write!(f, "Waiting"),
            State::Running => write!(f, "Running"),
            State::Finished => write!(f, "Finished"),
        }
    }
}

#[derive(Debug, Default, Clone, Copy)]
#[repr(u32)]
pub enum Algo {
    #[default]
    PriorityAlgo,

    RoundRobinAlgo,
}

/**
  Process Control Block

  + pid: Process ID
  + priority: Process Priority
  + cpu_hold_time: The Process has already consumed how much CPU time
  + cpu_require_time: The Process still wants how much CPU time
  + state:  Process State
  + alog: Process Scheduling Algorithm

*/
#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub struct PCB {
    pub pid: u32,
    pub priority: u32,
    pub cpu_hold_time: i32,
    pub cpu_require_time: i32,
    pub state: State,
    algo: Algo,
}

impl Default for PCB {
    fn default() -> Self {
        PCB {
            pid: generate_pid(),
            state: State::default(),
            algo: Algo::default(),
            priority: u32::MAX,
            cpu_hold_time: 0,
            cpu_require_time: 0,
        }
    }
}

impl PCB {
    pub fn new(priority: u32, cpu_require_time: i32) -> PCB {
        PCB {
            pid: generate_pid(),
            priority,
            cpu_hold_time: 0,
            cpu_require_time,
            state: State::Waiting,
            algo: Algo::PriorityAlgo,
        }
    }

    pub fn get_state(&self) -> String {
        self.state.to_string()
    }
}

impl PCB {
    pub fn set_priority(&mut self, priority: u32) {
        self.priority = priority;
    }

    pub fn consume_cpu_time_pri(&mut self) {
        self.priority += 3;
        self.cpu_hold_time += 1;
        self.cpu_require_time -= 1;
    }

    pub fn set_cpu_require_time(&mut self, cpu_require_time: i32) {
        self.cpu_require_time = cpu_require_time;
    }

    pub fn consume_cpu_time_rr(&mut self, time: i32) {
        self.cpu_hold_time += time;
        self.cpu_require_time -= time;
    }

    pub fn to_run(self) -> PCB {
        PCB {
            pid: self.pid,
            priority: self.priority,
            cpu_hold_time: self.cpu_hold_time,
            cpu_require_time: self.cpu_require_time,
            state: State::Running,
            algo: self.algo,
        }
    }

    pub fn to_finished(self) -> PCB {
        PCB {
            pid: self.pid,
            priority: self.priority,
            cpu_hold_time: self.cpu_hold_time,
            cpu_require_time: self.cpu_require_time,
            state: State::Finished,
            algo: self.algo,
        }
    }

    pub fn to_wait(self) -> PCB {
        PCB {
            pid: self.pid,
            priority: self.priority,
            cpu_hold_time: self.cpu_hold_time,
            cpu_require_time: self.cpu_require_time,
            state: State::Waiting,
            algo: self.algo,
        }
    }
}

#[derive(Debug, Clone, Default, Copy)]
pub struct PriorityAlgo;

#[derive(Debug, Clone, Default, Copy)]
pub struct RoundRobinAlgo;

#[derive(Debug, Clone, Default)]
pub struct Control<A> {
    pub pcbs: Vec<PCB>,
    next_schedule: RefCell<HashMap<usize, usize>>,
    run_orders: Vec<u32>,
    time_slice: i32,
    algo: PhantomData<A>,
}

impl<A> Control<A> {
    pub fn new(size: usize) -> Self {
        Control::<A> {
            pcbs: Vec::with_capacity(size),
            next_schedule: RefCell::new(HashMap::new()),
            run_orders: Vec::with_capacity(size),
            time_slice: 0,
            algo: PhantomData,
        }
    }

    pub fn emplace_back(&mut self, pcb: &[PCB]) {
        for p in pcb {
            self.pcbs.push(*p);
        }
    }

    pub fn get_pid(&self, idx: usize) -> u32 {
        self.pcbs[idx].pid
    }
}

pub trait Scheduling: Default {
    fn build(&mut self, time_slice: i32) -> &[u32];
    fn step(&mut self) -> (usize, usize);
    fn is_empty(&self) -> bool;
    fn push(&mut self, pcb: PCB);
    fn get_pcbs(&self) -> &[PCB];
}

impl Scheduling for Control<PriorityAlgo> {
    fn get_pcbs(&self) -> &[PCB] {
        &self.pcbs
    }

    fn push(&mut self, pcb: PCB) {
        self.pcbs.push(pcb);
    }
    fn is_empty(&self) -> bool {
        self.run_orders.is_empty()
    }

    /// must call `build` before `step`
    ///
    /// This will build the run order
    fn build(&mut self, _: i32) -> &[u32] {
        let (order, next_schedule) = Self::get_run_order(&self.pcbs);
        self.next_schedule.replace(next_schedule);
        self.run_orders = order;
        self.run_orders.as_slice()
    }

    /// `step` function will return the next process to run
    ///
    /// `return` (idx, pid)
    ///
    /// the `idx` is the index of the process in the `run_order`
    fn step(&mut self) -> (usize, usize) {
        let len = self.run_orders.len();

        if len >= 2 {
            let idx = self.run_orders.pop().unwrap() as usize - 1;
            let pid = self.pcbs[idx].pid as usize;
            // let second_run = self.run_orders[self.run_orders.len() - 1] as usize - 1;
            self.pcbs[idx].consume_cpu_time_pri();
            self.pcbs[idx] = self.pcbs[idx].to_run();
            if self.pcbs[idx].cpu_require_time <= 0 {
                self.pcbs[idx] = self.pcbs[idx].to_finished();
                return (idx, pid);
            } else {
                let mut pcbs = self
                    .pcbs
                    .clone()
                    .into_iter()
                    .filter(|p| p.state != State::Finished)
                    .collect::<Vec<_>>();
                pcbs.sort_by(|a, b| {
                    b.priority
                        .cmp(&a.priority)
                        .then_with(|| b.cpu_require_time.cmp(&a.cpu_require_time))
                });
                self.pcbs[idx] = self.pcbs[idx].to_wait();
                self.run_orders = pcbs.iter().map(|f| f.pid).collect();
            }
            // if self.pcbs[idx].priority <= self.pcbs[second_run].priority {
            //     self.run_orders.push(idx as u32 + 1);
            // } else {
            //     // insert the idx according to the priority
            //     // the lower the priority, the higher the position
            //     let mut insert_idx = 0;
            //
            //     for i in 0..self.run_orders.len() {
            //         if self.pcbs[self.run_orders[i] as usize - 1].priority > self.pcbs[idx].priority
            //         {
            //             insert_idx = i + 1;
            //             break;
            //         }
            //     }
            //
            //     self.run_orders.insert(insert_idx, idx as u32 + 1);
            //     self.pcbs[idx] = self.pcbs[idx].to_wait();
            // }
            (idx, pid)
        } else {
            let idx = *self.run_orders.last().unwrap() as usize - 1;
            let pid = self.pcbs[idx].pid as usize;
            // self.run_orders.pop();
            if self.pcbs[idx].cpu_require_time <= 0 {
                self.pcbs[idx] = self.pcbs[idx].to_finished();
            } else {
                self.pcbs[idx].consume_cpu_time_pri();
                self.pcbs[idx] = self.pcbs[idx].to_run();
            }
            (idx, pid)
        }
    }
}

impl Control<PriorityAlgo> {
    fn get_run_order(pcbs: &[PCB]) -> (Vec<u32>, HashMap<usize, usize>) {
        let mut order = pcbs.iter().enumerate().collect::<Vec<_>>();
        order.sort_by(|a, b| {
            b.1.priority
                .cmp(&a.1.priority)
                .then_with(|| b.1.cpu_require_time.cmp(&a.1.cpu_require_time))
        });
        let mut next_schedule = HashMap::new();
        (
            order
                .iter()
                .map(|f| {
                    let next_pid = pcbs[f.0].pid;
                    next_schedule.insert(f.0, next_pid as usize);
                    next_pid
                })
                .collect(),
            next_schedule,
        )
    }
}

impl Scheduling for Control<RoundRobinAlgo> {
    fn get_pcbs(&self) -> &[PCB] {
        &self.pcbs
    }

    fn push(&mut self, pcb: PCB) {
        self.pcbs.push(pcb);
    }
    fn build(&mut self, time_slice: i32) -> &[u32] {
        self.set_time_slice(time_slice);
        (self.run_orders, *self.next_schedule.borrow_mut()) =
            Self::get_run_order(&self.pcbs, self.time_slice);
        self.run_orders.as_slice()
    }

    fn step(&mut self) -> (usize, usize) {
        let idx = self.run_orders.pop().unwrap() as usize;
        let pid = self.pcbs[idx].pid as usize;
        self.pcbs[idx] = self.pcbs[idx].to_run();
        self.pcbs[idx].consume_cpu_time_rr(self.time_slice);
        if self.pcbs[idx].cpu_require_time <= 0 {
            self.pcbs[idx] = self.pcbs[idx].to_finished();
        } else {
            self.pcbs[idx] = self.pcbs[idx].to_run();
        }

        self.pcbs.iter_mut().enumerate().for_each(|(i, pcb)| {
            if pcb.state == State::Running && i != idx {
                pcb.state = State::Waiting;
            }
        });

        (idx, pid)
    }

    fn is_empty(&self) -> bool {
        self.run_orders.is_empty()
    }
}

impl Control<RoundRobinAlgo> {
    pub fn set_time_slice(&mut self, time_slice: i32) {
        self.time_slice = time_slice;
    }

    fn get_run_order(pcbs: &[PCB], time_slice: i32) -> (Vec<u32>, HashMap<usize, usize>) {
        let mut order = pcbs
            .iter()
            .enumerate()
            .map(|(i, pcb)| (i, *pcb))
            .collect::<Vec<_>>();
        let mut finished = [false].repeat(order.len());
        let mut run_order: Vec<u32> = vec![];
        let mut last_idx = -1;
        while finished.iter().any(|&x| !x) {
            last_idx = (last_idx + 1 + order.len() as i32) % (order.len() as i32);
            let ulast_idx = last_idx as usize;
            if finished[ulast_idx] {
                continue;
            }
            let mut last = order[ulast_idx];
            run_order.push(ulast_idx as u32);
            last.1.consume_cpu_time_rr(time_slice);
            order[ulast_idx].1 = last.1.to_wait();
            if order[ulast_idx].1.cpu_require_time <= 0 {
                finished[ulast_idx] = true;
            }
        }
        run_order.reverse();

        let mut next_schedule = HashMap::new();
        for uindex in run_order.iter() {
            let index = *uindex as usize;
            let next_pid = pcbs[index].pid;
            next_schedule.insert(index, next_pid as usize);
        }

        dbg!(&run_order);

        (run_order, next_schedule)
    }
}
