#import "../lib/template.typ": *

#show: base
#set_title(title: "动态分区分配", author: "", student_id: 114514, date: "2024.12.09")

= 实验环境

#env_info

= 实验目的

+ 深入理解操作系统中动态内存分配算法的工作原理和性能差异
+ 比较不同算法在内存利用率、分配成功率和内存碎片率等方面的表现
+ 观察和分析内存碎片的形成及其对系统性能的影响，理解如何选择合适的算法以最小化碎片

= 实验内容

== 实验总体概述

+ 分别实现首次适应算法 (FirstFit)、循环首次适应算法 (RecursiveFirstFit)、最佳适应算法 (BestFit) 和最坏适应算法 (WorstFit)。
  - 首次适应算法 (FirstFit)：从空闲分区链表的头部开始查找第一个满足要求的空闲分区。所有空闲分区按照地址递增的顺序排列。
  - 循环首次适应算法 (RecursiveFirstFit)：从上次分配的空闲分区开始查找第一个满足要求的空闲分区。如果找到了，则从该空闲分区的下一个空闲分区开始查找；否则，从空闲分区链表的头部开始查找。
  - 最佳适应算法 (BestFit)：从所有满足要求的空闲分区中选择最小的空闲分区。
  - 最坏适应算法 (WorstFit)：从所有满足要求的空闲分区中选择最大的空闲分区。

+ 假设初始状态下，可用的内存空间为 640KB，编写程序在这 640KB 的空间上模拟上述动态分区分配算法的过程，其中，空闲分区通过空闲分区表来管理。作业请求序列如下：
  - 作业 1 申请 130 KB
  - 作业 2 申请 60 KB
  - 作业 3 申请 100 KB
  - 作业 2 释放 60 KB
  - 作业 4 申请 200 KB
  - 作业 3 释放 100 KB
  - 作业 1 释放 130 KB
  - 作业 5 申请 140 KB
  - 作业 6 申请 60 KB
  - 作业 7 申请 50 KB
  - 作业 8 释放 60 KB

#my_table(
  caption: "空闲分区表项",
  header_l: "Attributes",
  header_r: "属性",
  [*idle_begin*],
  [空闲分区开始],
  [*idle_size*],
  [空闲分区大小],
  [*state*],
  [空闲分区使用状态],
) <table_2>

== 空闲分区表设计

#idnt2 空闲分区表表项如下@table_2。一个表项会保存空闲分区的起始地址、大小、分区的使用状态。

#code(```cpp
struct MemIdleTableItem {
    uint32_t idle_begin;
    uint32_t idle_size;
    MemState state;
};

using MemIdleTable = std::map< patritial_num_t, MemIdleTableItem >;
```, caption: "空闲分区表定义")

#idnt2 如@table_3，这里 `state` 一共包括了三种状态：`Idle`, `Used`, `Full`。后面两种状态分别表示分区已被使用和分区已被占满。一般而言，只有 `Idle`
表明当前的分区是空闲的，而其他两种状态则表示分区已被占用。

#my_table(caption: "空闲分区状态", header_l: "State", header_r: "状态", [*Idle*], [空闲], [*Used*], [已使用], [*Full*], [已满]) <table_3>

== 内存分区链设计(不同于空闲分区链)

#idnt2 在一般的设计中，只使用空闲分区链存储所有空闲分区节点，然而在实际的使用中，如果只通过空闲分区链记录数据，在释放作业合并空闲分区时会难以辨别某个正在使用的分区前后是否存在空闲分区。

#idnt2 这里我使用双向链表将所有分区节点连接起来，这样在释放作业时，可以通过前后节点的状态来判断是否需要合并空闲分区。例如释放时，我们可以对 `job`
节点的前后节点进行判断，如果前后节点都是空闲的，那么我们可以将这三个节点合并为一个节点。

#code(```cpp
    uint8_t condition  = 0b0000;
    if (job_node_prev && job_node_prev->state == MemState::Idle) {
        condition = 0b1100;
    }
    else if (!job_node_prev) {
        condition = 0b0000;
    }

    if (job_node_next && job_node_next->state == MemState::Idle) {
        condition |= 0b0011;
    }

```, caption: "释放作业时的合并空闲分区判断")

#idnt2 针对节点前后是否存在节点以及节点是否为 `Idle`，可以将这四种情况分别用二进制表示，这样我们可以通过一个 `uint8_t` 类型的变量来表示这四种情况。针对这四种不同情况，分别进行合并即可。

#list(
  indent: 2em,
)[ `0b0000`：前后节点都不存在。 ][ `0b1100`: 前节点存在且为 `Idle`，后节点不存在。 ][ `0b1111`: 前后节点均存在且为 `Idle`。 ][ `0b0011`: 后节点存在且为 `Idle`，前节点不存在。 ]

== FirstFit

#idnt2 首次适应算法 (FirstFit) 是最简单的动态分区分配算法之一，它从内存分区链表的头部开始查找第一个满足要求的空闲分区。所有空闲分区按照地址递增的顺序排列。

#code(caption: "FirstFit 算法实现 Part 1")[```cpp
Result MemControl::alloc_first_fit(job_id_t id, uint32_t size) noexcept {
    if (size > m_max_size) {
        return Error(Err::OutOfMem);
    }
    auto [mem_node, e] = m_mem_list.find_enough_idle_mem(size);
    if (!e.has_value()) {
        return e;
    }

    if (mem_node->size == size) {
        mem_node->state = MemState::Full;
        m_idle_table.erase(mem_node->id.par_num);
        mem_node->id.id = id;
        return true;
    }
    ...
```]

#idnt2 对于每个节点，当恰好能分配时，我们将节点的状态设置为
`Full`，并将其从空闲分区表中移除。如果节点的大小大于请求的大小，我们将节点分割为两个节点，一个节点的大小为请求的大小，另一个节点的大小为原节点大小减去请求的大小。下面的@code_4 是关于FirstFit算法的实现的第二部分伪代码。

#code(caption: "FirstFit 算法实现 Part 2")[```cpp
    ...
    auto job_node   = new MemNode();

    // update job node to used
    update(job_node)

    // update mem_node to split
    update(mem_node)

    // update idle table
    auto& item      = m_idle_table.at(mem_node->id.par_num);
    update_item(item)

    auto mem_node_prev = mem_node->prev;

    // insert the job_node
    insert(job_node, mem_node, mem_node_prev);
    m_mem_list.update_head_from(mem_node);
    return true;
}
```
] <code_4>

== RecursiveFirstFit

#idnt2 循环首次适应在 FirstFit 的基础上添加一个 `static node cur` 用于记录当前的查找位置。当分配成功时，我们将 `static node cur`
设置为当前分配的节点，这样下次分配时，我们就可以从这个节点开始查找。每次调用了 `RecursiveFirstFit` 函数进行内存分配时，`cur` 都会继续找到下一个空闲分区。

#code(caption: "RecursiveFirstFit")[
```cpp
    ...
    static MemNode* cur = m_mem_list.m_head;

    while (cur->state != MemState::Idle) {
        cur = cur->next;
    }

    auto tmp = cur;
    while (cur && !(cur->size >= size && cur->state == MemState::Idle)) {
        cur = cur->next;
    }
    ...
    if (!cur) { // update if cur is tail
      cur = m_mem_list.m_head;
      while (cur->state != MemState::Idle) {
          cur = cur->next;
      }
    }

  ```
]

== BestFit & WorstFit

#idnt2 为保证查找可用分区进行排序时，不改变原来内存分区链的顺序，会先对内存分区链进行复制，然后对复制的链表进行排序，再对排序后的链表进行查找。

#idnt2 对于 BestFit or WorstFit, 仅存在排序时是升序或降序的区别，故此处合并在一起进行叙述。在函数传参时，通过 `asc` 参数来控制排序的方式。

#code(caption: "BestFit & WorstFit")[
```cpp
Result MemControl::alloc_bw_fit_impl(
  job_id_t id, uint32_t size, bool asc) noexcept {
    auto copyted = m_mem_list.copy();
    copyted.sort(asc);
    if (size > m_max_size) {
        return Error(Err::OutOfMem);
    }
    auto [tmp, e] = copyted.find_enough_idle_mem(size);
    ...
    // like FirstFit
}
```
]

== 运行脚本

#idnt2 由于实验任务给定了每次运行具体任务，我们可以将任务写入脚本，并通过重定向输出将运行结果导入到文件中。

#idnt2 整个程序将读取环境变量 `MEM_ALLOC_TYPE` 来判断当前的分配算法，然后根据不同的算法进行分配。当该环境变量未被设置时，程序会报错。如@code_5。

#code(caption: "读取环境变量")[```cpp
    // get from envetiment variable
    std::string alloc_type = "";
    alloc_type             = getenv("MEM_ALLOC_TYPE");

    os::DynamicMemAllocType type;

    if (alloc_type == "FirstFit") {
        type = os::DynamicMemAllocType::FirstFit;
    }
    else if (alloc_type == "RecursiveFirstFit") {
        type = os::DynamicMemAllocType::RecursiveFirstFit;
    }
    else if (alloc_type == "BestFit") {
        type = os::DynamicMemAllocType::BestFit;
    }
    else if (alloc_type == "WorstFit") {
        type = os::DynamicMemAllocType::WorstFit;
    }
    else {
        std::println("Error: {}", int(os::Err::NoThatAllocMethod));
        return 1;
    }
```] <code_5>

#pagebreak()

#idnt2 由于有了环境变量进行选择，我们可以通过脚本很方便地来进行不同算法的运行，如@code_6。

#code(caption: "运行脚本")[```bash
#!/bin/bash

# FirstFit;
# RecursiveFirstFit;
# BestFit;
# WorstFit;

ALLOCATORS=(FirstFit RecursiveFirstFit BestFit WorstFit)

for allocator in "${ALLOCATORS[@]}"; do
  echo "Running $allocator"
  MEM_ALLOC_TYPE="${allocator}" ./bin/release/dyn_allo_mem > "result_${allocator}.txt"
done
```] <code_6>

= 操作过程

#idnt2 通过上述的实验内容，我们可以直接运行脚本。如@pic_1，我们可以看到正在运行的情况，同时运行后的结果将存放在 ```bash result_${allocator}.txt``` 文件中。

#img("../assets/run_dyn_mem_alloc.png", caption: "运行脚本", width: 400pt) <pic_1>

= 结果

== 文件之前

#idnt2 在所有输出文件之前将记录当前的所有工作。

#align(center)[
#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[
```
"
  ## Total Idle Mem 640KB
  Task:
  - Job 1: alloc 130
  - Job 2: alloc 60
  - Job 3: alloc 100
  - Job 2: free
  - Job 4: alloc 200
  - Job 3: free
  - Job 1: free
  - Job 5: alloc 140
  - Job 6: alloc 60
  - Job 7: alloc 50
  - Job 6: free
"
```
]
]

== FirstFit

#idnt2 如下所示，为防止输出过长，共两列排版，输出顺序从左列开始，一直到后列最后的 `< Done >` 结束。
#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[
#grid(columns: (1fr, 1fr), align(center)[
```
Init
-> Partial 0
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 640 	 | 
	 | <State>: Idle	 |

Alloc Job 1: 130KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 130 	 |
	 | <idle_size>: 510 	 | 
	 | <State>: Idle	 |

Alloc Job 2: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |

Alloc Job 3: 100KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Free Job 2
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Alloc Job 4: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Free Job 3
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |
```
],align(center)[
  ```
Free Job 1
-> Partial 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |

Alloc Job 5: 140KB
-> Partial 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

Alloc Job 6: 60KB
-> JobId 6
	 | <idle_begin>:  0  	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>:  60 	 |
	 | <idle_size>:  70 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

Alloc Job 7: 50KB
-> JobId 6
	 | <idle_begin>:  0  	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 7
	 | <idle_begin>:  60 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 110 	 |
	 | <idle_size>:  20 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

Free Job 6
-> Partial 2
	 | <idle_begin>:  0  	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 7
	 | <idle_begin>:  60 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 110 	 |
	 | <idle_size>:  20 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

< Done >
  ```
])
]

== RecursiveFirstFit

#idnt2 如 FirstFit 类似。

#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[
#grid(columns: (1fr, 1fr), align(center)[
  ```
  Init
-> Partial 0
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 640 	 | 
	 | <State>: Idle	 |

Alloc Job 1: 130KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 130 	 |
	 | <idle_size>: 510 	 | 
	 | <State>: Idle	 |

Alloc Job 2: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |

Alloc Job 3: 100KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Free Job 2
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Alloc Job 4: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

Free Job 3
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>: 160 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |
  ```
],align(center)[
  ```
Free Job 1
-> Partial 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

Alloc Job 5: 140KB
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 140 	 |
	 | <idle_size>: 150 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

Alloc Job 6: 60KB
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 140 	 |
	 | <idle_size>: 150 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 6
	 | <idle_begin>: 350 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 410 	 |
	 | <idle_size>: 230 	 | 
	 | <State>: Idle	 |

Alloc Job 7: 50KB
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> JobId 7
	 | <idle_begin>: 140 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 6
	 | <idle_begin>: 350 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 410 	 |
	 | <idle_size>: 230 	 | 
	 | <State>: Idle	 |

Free Job 6
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> JobId 7
	 | <idle_begin>: 140 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

< Done >
  ```
])]

== BestFit

#idnt2 如 FirstFit 类似。

#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[
#grid(columns: (1fr, 1fr), align(center)[
```
Init
-> Partial 0
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 640 	 | 
	 | <State>: Idle	 |

Alloc Job 1: 130KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 130 	 |
	 | <idle_size>: 510 	 | 
	 | <State>: Idle	 |

Alloc Job 2: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |

Alloc Job 3: 100KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Free Job 2
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Alloc Job 4: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Free Job 3
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |
```
] ,align(center)[
  ```
Free Job 1
-> Partial 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |

Alloc Job 5: 140KB
-> Partial 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

Alloc Job 6: 60KB
-> JobId 6
	 | <idle_begin>:  0  	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>:  60 	 |
	 | <idle_size>:  70 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

Alloc Job 7: 50KB
-> JobId 6
	 | <idle_begin>:  0  	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 7
	 | <idle_begin>:  60 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 110 	 |
	 | <idle_size>:  20 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

Free Job 6
-> Partial 2
	 | <idle_begin>:  0  	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 7
	 | <idle_begin>:  60 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 110 	 |
	 | <idle_size>:  20 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Full	 |
-> JobId 5
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 330 	 |
	 | <idle_size>: 310 	 | 
	 | <State>: Idle	 |

< Done >
  ```
])]

== WorstFit

#idnt2 如 FirstFit 类似。

#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[
#grid(columns: (1fr, 1fr), align(center)[

  ```
Init
-> Partial 0
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 640 	 | 
	 | <State>: Idle	 |

Alloc Job 1: 130KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 130 	 |
	 | <idle_size>: 510 	 | 
	 | <State>: Idle	 |

Alloc Job 2: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 450 	 | 
	 | <State>: Idle	 |

Alloc Job 3: 100KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> JobId 2
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Free Job 2
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 290 	 |
	 | <idle_size>: 350 	 | 
	 | <State>: Idle	 |

Alloc Job 4: 60KB
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 3
	 | <idle_begin>: 190 	 |
	 | <idle_size>: 100 	 | 
	 | <State>: Used	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

Free Job 3
-> JobId 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 130 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 130 	 |
	 | <idle_size>: 160 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |
  ```
],align(center)[
  ```
Free Job 1
-> Partial 1
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

Alloc Job 5: 140KB
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 140 	 |
	 | <idle_size>: 150 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 350 	 |
	 | <idle_size>: 290 	 | 
	 | <State>: Idle	 |

Alloc Job 6: 60KB
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 140 	 |
	 | <idle_size>: 150 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 6
	 | <idle_begin>: 350 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 410 	 |
	 | <idle_size>: 230 	 | 
	 | <State>: Idle	 |

Alloc Job 7: 50KB
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 140 	 |
	 | <idle_size>: 150 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 6
	 | <idle_begin>: 350 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> JobId 7
	 | <idle_begin>: 410 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 460 	 |
	 | <idle_size>: 180 	 | 
	 | <State>: Idle	 |

Free Job 6
-> JobId 5
	 | <idle_begin>:  0  	 |
	 | <idle_size>: 140 	 | 
	 | <State>: Used	 |
-> Partial 1
	 | <idle_begin>: 140 	 |
	 | <idle_size>: 150 	 | 
	 | <State>: Idle	 |
-> JobId 4
	 | <idle_begin>: 290 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Used	 |
-> Partial 2
	 | <idle_begin>: 350 	 |
	 | <idle_size>:  60 	 | 
	 | <State>: Idle	 |
-> JobId 7
	 | <idle_begin>: 410 	 |
	 | <idle_size>:  50 	 | 
	 | <State>: Used	 |
-> Partial 0
	 | <idle_begin>: 460 	 |
	 | <idle_size>: 180 	 | 
	 | <State>: Idle	 |

< Done >
  ```
])]

= 体会

#idnt2 本次实验实现了⼏种内存分配算法，通过模拟内存分配和释放的过程，对⽐了它们的性能。同时，我也意识到理论与实践之间的差异，在理论上我们合并空闲分区块是很简单的事情，但是当真正用代码表达时，对双向链表的改查增添则变的很复杂，这也是我在实验中遇到的困难，虽然我采用了 “内存分区链” 这样的结构进行存储表达，但是链表的正确操作依然是一个难点，这也让我的代码结构变的很糟糕。

#idnt2 在以后的学习中，我会更加注重代码的结构，提高代码的可读性，同时，还要加强对理论知识的理解，以指导实践。

= 思考题

#idnt2 #text(size: 14pt)[*这些分配算法主要适用于何种情况？*]

#idnt2 *答*：

#list(indent: 3em)[
*FirstFit*: 空闲分区按地址递增的次序排列。每次分配内存时，顺序查找到第⼀个能满⾜⼤⼩的空闲分区，分配给作业。⾸次适应算法保留了内存⾼地址部分的⼤空闲分区，有利于后续⼤作业的装⼊。但它会使内存低地址部分出现许多⼩碎⽚，⽽每次分配查找时都要经过这些分区，因此增加了开销。
][*RecursiveFirstFit*: 也称邻近适应算法，由⾸次适应算法演变⽽成。不同之处是，分配内存时从上次查找结束的位置开始继续查找。邻近适应算法试图解决该问题。它让内存低、⾼地址部分的空闲分区以同等概率被分配，划分为⼩分区，导致内存⾼地址部分没有⼤空闲分区可⽤。通常⽐⾸次适应算法更差。][
*BestFit*: 空闲分区按容量递增的次序排列。每次分配内存时，顺序查找到第⼀个能满⾜⼤⼩的空闲分区，即最⼩的空闲分区，分配给作业。最佳适应算法虽然称为最佳，能更多地留下⼤空闲分区，但性能通常很差，因为每次分配会留下越来越多很⼩的难以利⽤的内存块，进⽽产⽣最多的外部碎⽚。
][
  *WorstFit*: 空闲分区按容量递减的次序排列。每次分配内存时，顺序查找到第⼀个能满⾜要求的之空闲分区，即最⼤的空闲分区，从中分割⼀部分空间给作业。与最佳适应算法相反，最坏适应算法选择最⼤的空闲分区，这看起来最不容易产⽣碎⽚，但是把最⼤的空闲分区划分开，会很快导致没有⼤空闲分区可⽤，因此性能也很差。
]
