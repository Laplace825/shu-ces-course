#import "../lib/template.typ": *

#show : base
#set_title(title: "请求页式存储管理", author: "", student_id: 114514 date: "2024.12.19")

= 实验环境

#env_info_rust

= 实验目的

#idnt2 虚拟存储技术是用来扩大内存容量的一种重要方法。学生应独立地用高级语言编写几个常用的存储分配算法，并设计一个存储管理的模拟程序，对各种算法进行分析比较，评测其性能优劣，从而加深对这些算法的了解。

= 实验内容

== 实现指令地址流转换

#idnt2 根据页表，将逻辑地址转换为物理地址。每个页大小为 1KB，页表大小为 1KB，以字节编址，一个页共1024个逻辑地址。

=== 常量定义

#idnt2 本实验中，定义了页大小为1KB，页表大小为1KB，一个页共1024个逻辑地址，如@code_0 所示。@table_1 显示了常量定义。

#my_table(
  caption: "常量定义",
  header_l: "常量",
  header_r: "值",
  [*PAGE_SIZE*],
  [1KB],
  [*PAGE_OFFSET_MASK*],
  [1023 (0b1111111111)],
  [*PAGE_OFFSET_BITS*],
  [10],
  [*PAGE_NUM*],
  [1 << 22 (4MB)],
  [*PAGE_ID_BITS*],
  [22],
) <table_1>

#code(caption: "常量定义")[
```rs
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
```
] <code_0>

=== Page Table设计

#idnt2 页表 `PageTable` 包括本页表长度以及页表的内容。页表的内容是一个哈希表，保证动态插入删除以及 $O(1)$ 时间复杂度查询。每个元素是一个页表项 `Item`。每个页表项存储的仅为某页的内存块号。如@code_1
所示。

#code(caption: "PageTable")[
```rs
// in mod page
pub struct Item {
    mem_block_id: u32,
}

pub struct Table {
    items: HashMap<PageId, Item>,
    len: u32,
}
```
] <code_1>

#idnt2 `PageTable` 结构提供地址转化方法，将逻辑地址转化为物理地址，完成地址转换机构任务。如@code_2 所示，提供 `page_addr_of` 和 `page_id_of`
方法，分别用于逻辑地址到物理地址和逻辑地址到页号的转换。

#code(caption: "PageTable Method")[
```rs
  @ impl Table
  fn new(...)
  fn is_empty(...)
  fn len(...)
  fn page_addr_of( logical_addr ) -> PhysAddr
  fn page_id_of( logical_addr ) -> PageId
  fn delete( ... )
  fn insert( ... )
  ```
] <code_2>

=== 逻辑地址转换

#idnt2 逻辑地址转换的过程是将逻辑地址分为页号和页内偏移两部分，通过页号在页表中查找对应的内存块号，再将内存块号和页内偏移合并为物理地址。如@code_3 所示。

#code(caption: "地址转换")[
```rs
  pub fn page_addr_of(&mut self, address: impl addr::Addr + Copy) -> Option<PhysAddr> {
    let add = address.addr();
    let offset = add & addr::PAGE_OFFSET_MASK;
    let page_id = add >> addr::PAGE_OFFSET_BITS;
    if page_id >= self.len {
        return None;
    }
    self.items
        .get(&page_id)
        .map(|item| item.mem_block_id * PAGE_SIZE + offset)
  }
  ```
] <code_3>

== FIFO算法实现

#idnt2 FIFO算法是最简单的页面置换算法，将所有调入的页号以双端队列的形式存储，每次缺页时移除队列头，并将新页入队尾。@code_4 展示了FIFO算法的实现细节。

#code(caption: "FIFO算法")[```rs
fn in_page(&mut self, page_id: page::PageId) {
    self.page_in_times += 1;
    if self.is_exist(page_id) {
        return;
    }
    if self.is_full() {
        self.queue.push_back(page_id);
        return;
    }

    // not full and not exist
    self.page_loss_times += 1;
    self.queue.push_back(page_id);
}
```] <code_4>

== LRU算法实现

#idnt2 LRU需要表明某个页上次被访问的时间，每次访问时更新该时间。当缺页时，选择最久未被访问的页进行替换。

#idnt2 为记录某个页被访问过的时间，可以对每个已换入页面进行计数，*缺页*基本可以分为以下步骤。

#list(indent: 2em)[查找当前以换入页面中计数最小的页面id。]
#code(caption: "LRU算法 Part 1")[
```rs
  let most_unuse = *self.hit_counter
      .iter()
      .min_by_key(|x| x.1)
      .unwrap().0;
```
]
#list(indent: 2em)[更新所有已换入页面的计数为0，刚换入的新页面计数为1。]
#code(caption: "LRU算法 Part 2")[
```rs
  self.out_page(most_unuse);
  self.hit_counter.insert(page_id, 1);

  @ fn out_page
  self.hit_counter
    .iter_mut()
    .for_each(|x| *x.1 = 0);
  self.hit_counter.remove(&page_id);
```
]
#list(indent: 2em)[将计数最小的页面与需要换入的页面进行置换。]
#code(caption: "LRU算法 Part 3")[```rs
  let pos = self.queue.iter()
      .position(|x| *x == most_unuse)
      .unwrap();
  if let Some(x) = self.queue.get_mut(pos) {
      *x = page_id;
  }
```]

== OPT算法实现

#idnt2 OPT算法每次换出的是未来最久不使用的页面，与FIFO和LRU不同，必须知道未来的页面才能对换出的页面进行选择。因此，OPT算法是一种理论上的算法，无法在实际中实现。

#idnt2 在我们的模拟算法中，由于可以显式地知道未来的页面访问情况，因此可以实现OPT算法。OPT算法在缺页时的实现可以分为以下步骤。

#list(indent: 2em)[
根据已换入的所有页面设立访问数组 `is_ok_in_future`，初始全为 `false` 表示全未访问。
]
#code(caption: "OPT算法 Part 1")[```rs
    let mut is_ok_in_future =
      HashMap::<page::PageId, bool>::with_capacity(self.queue.len());
    self.queue.iter().for_each(|p| {
        is_ok_in_future.insert(*p, false);
    });
  ```]

#list(indent: 2em)[遍历未来将访问的页面，每遍历到一个已经存在的页面，则将该页面记为 `true`，表示已访问。 ]
#code(caption: "OPT算法 Part 2")[```rs
    for id in self.future_pages.iter() {
        if self.queue.contains(id) {
            *is_ok_in_future.get_mut(id).unwrap() = true;
        }
      ...
    }

  ```]
#list(indent: 2em)[当 `is_ok_in_futrue` 数组中为 `true` 的个数为已换入页面个数$- 1$时，查找 `is_ok_in_future` 中第一个为 `false` 的页面，将其换出。 ]
#code(caption: "OPT算法 Part 3")[```rs
  ...
      if is_ok_in_future
        .values()
        .filter(|x| **x)
        .count() == self.queue.len() - 1 {
          break;
      }
  }

  if let Some(which_to_exchange) = is_ok_in_future
    .iter()
    .find(|x| !*x.1) {
      let pos = self
          .queue
          .iter()
          .position(|x| *x == *which_to_exchange.0)
          .unwrap();
      *self.queue.get_mut(pos).unwrap() = page_id;
  }

  ```]

= 操作过程

== 指令地址流转换

=== 单元测试

#idnt2 由于 $1 K B$ 页表大小的特殊性，当页面从地址$0$开始连续分配时， 页表的内存块号也是连续的。此时物理地址和逻辑地址相同。如下所示。

#table(stroke: none, inset: 0.5em, align: center, columns: (50%, 50%,), [$
    l o g i c \_ a d d r e s s eq & 0 b 10000000011 (0 d 1027) \
    p a g e \_ i d eq             & 0d 1 \
    o f f s e t eq                & 0d 3 \
  $
], table.vline(), [$ #h(2em)
  p h y s i c \_ a d d r e s s
  eq & 1 times 1024 plus 3 \
  eq & 0b 10000000011 (0 d 1027) \
  eq & l o g i c \_ a d d r e s s $])

#idnt2 所以特意为页表设立单元测试，插入不从地址 $0$ 开始连续分配的页面，例如页面 $1$ 的起始地址为 $2048$。可以发现逻辑地址 $1022$ 位于页面 $0$，而逻辑地址 $1024 + 1022$ 位于页面 $1$，起始地址为 $2048 + 1022$。

#code(caption: "PageTable Test")[
```rs
#[test]
fn test_page_table() {
    let mut page_table = Table::default();
    // page 0 is mem block 0 ( addr begin is 0)
    assert_eq!(page_table.insert(0u32, 0u32), None);

    let mut addr = 1022 + (0 << addr::PAGE_OFFSET_BITS);
    assert_eq!(page_table.page_addr_of(addr), Some(1022));

    // duplicate insert will return Some(K), `K` is the mem
    // block id that already exist
    assert_eq!(page_table.insert(0u32, 1u32), Some(0u32));

    // page 1 is mem block 2 ( addr begin is 2048)
    assert_eq!(page_table.insert(1u32, 2u32), None);

    // page 1 , page offset 1022
    addr = 1022 + (1 << addr::PAGE_OFFSET_BITS);
    assert_eq!(page_table.page_addr_of(addr), Some(2048 + 1022));

    // page 2, page offset 1022 will not be found. Result
    // will be None assert_eq!(
        page_table.page_addr_of(addr + (1 << addr::PAGE_OFFSET_BITS)),
        None
    );
}
```
]

=== 逻辑地址转换页号

#idnt2 这里我们随机生成了32个逻辑地址(只分配32个页框)，并且每个页号都被覆盖，页内偏移则随机生成 $[0,1023]$ 之间的数。如@pic_1 所示。

#img("../assets/addr2page_id.png", caption: "逻辑地址转换页号", height: 400pt, width: auto) <pic_1>

== 页面置换算法

#idnt2 实验采取随机生成 $1024$ 个 $[0,31]$ 之间的页号，模拟页面访问情况。每次访问时，模拟缺页情况。最后统计缺页次数，计算缺页率。

#idnt2 *值得注意的是，由于访问页号是随机生成的，某次生成结果可能并不符合局部性原理，例如生成了连续的 `0, 31, 10, 5, 20, 17`
这样的访问情况，可能对实验结果正确性存存一定影响，但为了模拟更大规模页面的调换，依然采用了随机生成的方式。*

#idnt2 已提供运行脚本 `run-all.sh`。脚本中包含了对 FIFO、LRU、OPT 算法的测试。测试结果将写入 ```bash result_$algo.txt```
文件中。程序将模拟从2开始一直到32的偶数个物理块时的缺页情况。具体请参考@chapter-5。

#code(caption: "run-all.sh")[```bash
#!/bin/bash

Algo_type=(FIFO LRU OPT)

for algo in "${Algo_type[@]}"
do
    echo "Running $algo"
    cargo run --release -- "$algo" >> result_"$algo".txt
done
```]

= 结果 <chapter-5>

== FIFO

#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[
#grid(columns: (1fr, 1fr), align(center)[
```
Mem:  2
   FIFO
  -> | The page loss times:  946
  -> | The page loss ratio:  0.92
Mem:  4
   FIFO
  -> | The page loss times:  886
  -> | The page loss ratio:  0.87
Mem:  6
   FIFO
  -> | The page loss times:  815
  -> | The page loss ratio:  0.80
Mem:  8
   FIFO
  -> | The page loss times:  745
  -> | The page loss ratio:  0.73
Mem:  10
   FIFO
  -> | The page loss times:  674
  -> | The page loss ratio:  0.66
Mem:  12
   FIFO
  -> | The page loss times:  624
  -> | The page loss ratio:  0.61
Mem:  14
   FIFO
  -> | The page loss times:  564
  -> | The page loss ratio:  0.55
Mem:  16
   FIFO
  -> | The page loss times:  501
  -> | The page loss ratio:  0.49
```
], align(center)[
```
Mem:  18
   FIFO
  -> | The page loss times:  434
  -> | The page loss ratio:  0.42
Mem:  20
   FIFO
  -> | The page loss times:  370
  -> | The page loss ratio:  0.36
Mem:  22
   FIFO
  -> | The page loss times:  307
  -> | The page loss ratio:  0.30
Mem:  24
   FIFO
  -> | The page loss times:  250
  -> | The page loss ratio:  0.24
Mem:  26
   FIFO
  -> | The page loss times:  186
  -> | The page loss ratio:  0.18
Mem:  28
   FIFO
  -> | The page loss times:  159
  -> | The page loss ratio:  0.16
Mem:  30
   FIFO
  -> | The page loss times:  89
  -> | The page loss ratio:  0.09
Mem:  32
   FIFO
  -> | The page loss times:  32
  -> | The page loss ratio:  0.03
```
])
]

== LRU

#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[#grid(columns: (1fr, 1fr), align(center)[
```
Mem:  2
   LRU
  -> | The page loss times:  968
  -> | The page loss ratio:  0.95
Mem:  4
   LRU
  -> | The page loss times:  916
  -> | The page loss ratio:  0.89
Mem:  6
   LRU
  -> | The page loss times:  844
  -> | The page loss ratio:  0.82
Mem:  8
   LRU
  -> | The page loss times:  788
  -> | The page loss ratio:  0.77
Mem:  10
   LRU
  -> | The page loss times:  701
  -> | The page loss ratio:  0.68
Mem:  12
   LRU
  -> | The page loss times:  644
  -> | The page loss ratio:  0.63
Mem:  14
   LRU
  -> | The page loss times:  594
  -> | The page loss ratio:  0.58
Mem:  16
   LRU
  -> | The page loss times:  515
  -> | The page loss ratio:  0.50
```
], align(center)[
```
Mem:  18
   LRU
  -> | The page loss times:  474
  -> | The page loss ratio:  0.46
Mem:  20
   LRU
  -> | The page loss times:  397
  -> | The page loss ratio:  0.39
Mem:  22
   LRU
  -> | The page loss times:  334
  -> | The page loss ratio:  0.33
Mem:  24
   LRU
  -> | The page loss times:  252
  -> | The page loss ratio:  0.25
Mem:  26
   LRU
  -> | The page loss times:  222
  -> | The page loss ratio:  0.22
Mem:  28
   LRU
  -> | The page loss times:  154
  -> | The page loss ratio:  0.15
Mem:  30
   LRU
  -> | The page loss times:  74
  -> | The page loss ratio:  0.07
Mem:  32
   LRU
  -> | The page loss times:  32
  -> | The page loss ratio:  0.03
```
])]

== OPT

#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[#grid(columns: (1fr, 1fr), align(center)[
```
Mem:  2
   OPT
  -> | The page loss times:  853
  -> | The page loss ratio:  0.83
Mem:  4
   OPT
  -> | The page loss times:  686
  -> | The page loss ratio:  0.67
Mem:  6
   OPT
  -> | The page loss times:  571
  -> | The page loss ratio:  0.55
Mem:  8
   OPT
  -> | The page loss times:  483
  -> | The page loss ratio:  0.47
Mem:  10
   OPT
  -> | The page loss times:  411
  -> | The page loss ratio:  0.40
Mem:  12
   OPT
  -> | The page loss times:  351
  -> | The page loss ratio:  0.34
Mem:  14
   OPT
  -> | The page loss times:  300
  -> | The page loss ratio:  0.29
Mem:  16
   OPT
  -> | The page loss times:  253
  -> | The page loss ratio:  0.24
```
], align(center)[
```
Mem:  18
   OPT
  -> | The page loss times:  211
  -> | The page loss ratio:  0.20
Mem:  20
   OPT
  -> | The page loss times:  173
  -> | The page loss ratio:  0.17
Mem:  22
   OPT
  -> | The page loss times:  139
  -> | The page loss ratio:  0.13
Mem:  24
   OPT
  -> | The page loss times:  111
  -> | The page loss ratio:  0.11
Mem:  26
   OPT
  -> | The page loss times:  86
  -> | The page loss ratio:  0.08
Mem:  28
   OPT
  -> | The page loss times:  65
  -> | The page loss ratio:  0.06
Mem:  30
   OPT
  -> | The page loss times:  46
  -> | The page loss ratio:  0.04
Mem:  32
   OPT
  -> | The page loss times:  32
  -> | The page loss ratio:  0.03
```
])]

== 结论

#idnt2 由于随机生成可能并不符合程序局部性原理，结果可能存在一定影响。

#idnt2 例如LRU算法和FIFO算法的表现相对一致，但原理上LRU算法核心是利用程序局部性原理，同一页面被访问时，很可能是最近被访问的页面，因此理论上LRU算法的缺页率应该会更低，而实际由于随机生成页号，导致LRU算法的表现与FIFO算法基本一致。

#idnt2 但是即使是这样的情况，OPT算法的缺页率依然保持最低，这是因为OPT算法是一种理论上最优，并且"能预测"未来换入页面的算法。即使在随机生成的情况下，OPT算法依然知道未来哪些页面是最久不会使用的，从而决策出应该换出哪些页面。然而，实际运行时，该算法对性能也有一定的消耗，特别是在各种查找和判定上，也许可以进一步优化。

= 体会

#idnt2 本次实验，通过代码模拟实现了三种页面置换算法，我对操作系统内部的页面置换有了更进一步的了解，同时我也体会到很多理论最优的算法如 OPT，实际上可能根本无法落地，重要的是如何在实际中找到一个性能和效果的平衡点。
