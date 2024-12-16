#set text(
  font: ("Times New Roman", "Songti SC"),
  size: 12pt,
  lang: "zh",
  region: "cn",
)
#set heading(bookmarked: true, numbering: "1.")
#set par(justify: true, leading: 0.7em)
#set page(
  "a4",
  header-ascent: 2em,
  header: align(right)[
    _Operating System (2) Experiment_
  ],
  numbering: "1/1",
)

#show raw: set text(font: "FiraCode Nerd Font Mono", ligatures: true)
#show heading.where(level: 1): set text(size: 16pt, weight: "bold", font: ("Times New Roman", "Heiti SC"))
#show heading.where(level: 2): set text(size: 14pt, weight: "bold", font: ("Times New Roman", "Heiti SC"))
#show heading.where(level: 3): set text(size: 12pt, font: ("Times New Roman", "Heiti SC"))

#let idnt2 = h(2em)

#let code(content, caption: none) = align(
  center,
  figure(caption: caption, supplement: [code], numbering: "1")[ #block(
      fill: rgb(0xf2, 0xf2, 0xf2),
      inset: 1em,
      radius: 5pt,
    )[#content]],
)

#align(
  center,
  text(22pt, font: ("Times New Roman", "Heiti SC"))[
    *《计算机操作系统》实验报告*
  ],
)

#align(center)[
  #par(spacing: 0.2em)[
    #line(length: 86%)
    #line(length: 86%)
  ]
]

#grid(align: center, columns: (1.4fr, 2.8fr))[
  #align(
    left,
    text(16pt, font: ("Times New Roman", "Heiti SC"))[
      #h(3em)*实验题目:* \
      #h(3em)*姓名:* xxx \
    ],
  )
][
  #align(
    left,
    text(16pt, font: ("Times New Roman", "Heiti SC"))[
      操作系统的进程调度 \
      *学号:* 114514#h(1em)*实验日期:* 2024.11.18 \
    ],
  )
]

#align(center)[
  #line(length: 86%)
]

= 实验环境

#idnt2 实验环境见下表1。本项目舍弃`try catch`异常处理，使用`std::expected`进行异常处理。引入格式化字符串打印 `<print> header file`。*已提供构建脚本，但本实验必须使用支持ISO C++ 23编译套件，对于GNU/GCC，应使用gcc 14.x 版本。*

#figure(caption: "实验环境")[
  #table(
    stroke: none, inset: 0.5em, align: center, columns: (
      20%,
      40%,
    ), table.hline(stroke: 1.2pt), [*OS*], [_Darwin 24.1.0_], table.vline(x: 1), [*CPU*], [_Apple M3 Arm64_], [*Compiler*], [_LLVM Clang++ 19.1.4_], [*C++ Standard*], [_ISO C++23_], [*Build System*], [_CMake_ $ >=$ _3.20_ & _Ninja Build_],table.hline(stroke: 1.2pt),
  )
]

= 实验目的

+ 独立地用高级语言编写和调试一个简单的进程调度程序。
+ 调度算法任意选择或自行设计。简单轮转法和优先数法等。
+ 加深对于进程调度和各种调度算法的理解。

= 实验内容

== 实验总体内容概述

+ 设计一个有 n 个进程工行的进程调度程序。每个进程由一个进程控制块`PCB`表示。`PCB`包含下述信息：进程名、进程优先数、进程需要运行的时间、占用CPU的时间以及进程的状态等。可按调度算法的不同而增删。
+ 调度程序包含2种不同的调度算法，分别为时间片轮转法(Round Robin)、动态优先级调度法(Priority First)，运行时可任选一种，以利于各种算法的分析比较。
+ 系统能显示或打印各进程状态和参数的变化情况，便于观察诸进程的调度过程。

== `PCB`设计

#idnt2 `PCB`保留的信息包括进程优先数、进程需要运行的时间、占用CPU的时间以及进程的状态等。优先数从0开始，以0为最高优先级，数值越大优先级越低。`PCB`的
具体定义如下表2。

#figure(caption: "PCB结构")[
  #table(
    stroke: none, inset: 0.5em, align: center, columns: (
      40%,
      40%,
    ), table.hline(stroke: 1.2pt), [*字段*], [*描述*], table.hline(stroke: 1.2pt), [*进程优先数*], [_pid_], [*进程需要运行的时间*], [_cpu_require_time_], [*占用CPU的时间*], [_cpu_hold_time_], [*进程状态*], [_State_], table.hline(stroke: 1.2pt),
  )
]

#idnt2 下列代码包括`PCB`的定义，将`PCB`以双向链表进行连接，实现调度算法。每个进程只有三种状态：`Finish`、`Running`、`Waiting`。

#code(caption: "PCB设计")[```cpp
  struct PCB {
      enum class State : uint16_t {
          Finish = 0,
          Running,
          Waiting,
      };
      uint32_t pid;
      uint32_t priority;
      int32_t cpu_max_require_time;
      int32_t cpu_require_time;
      int32_t cpu_hold_time;
      State state;

      PCB* next;
      PCB* prev;
  };
  ```
]

== `PCB`控制器设计

=== `PCB`控制器功能

#idnt2 `PCB`结构只提供基本的字段设计，`PCB`控制器(`PcbController`)负责对`PCB`的创建、删除、插入、查找、调度等操作。

#idnt2 `PCB`控制器功能如下：

#list(indent: 2em)[
  维护了整个进程调度链，链首作为当前正在运行的进程，其余进程则为`Waiting`状态，等待调度。
][提供`set_schedule_type`接口，用于设置调度算法。][自动进行进程计数。][可自行指定CPU时间片长度。
][`schedule`接口，每次根据当前调度算法类型进行单步调度。]

=== `PCB`控制器内部函数

#idnt2 下列函数针对内部实现，不对外提供接口。主要用于管理`PCB`进程链、实现不同调度类型算法。具体可以参考附件内容。

#code(caption: "PcbController核心功能函数")[```cpp
  ├  insert_pcb_pf
  ├  insert_pcb_rr
  ├  schedule_running_pf
  ├  schedule_running_rr
  ├  ret_true_type
  ├  ret_false_type
  ├  finish_one
  ├  pop_front
  ├  front
  ├  push_back
  ├  insert_pcb
  ```]

#idnt2 核心函数功能如下，在随报告提交的源码中查阅具体细节，应包括文件`pcb.h pcb.cc`：

#list(indent: 2em)[
  `insert_pcb_pf`：按照优先级次序插入链表，优先级相同时，插入到该节点之前。
][`insert_pcb_rr`: 按照时间片轮转插入链表，未完成的节点进行尾插(`push_back`)。][`schedule_running_pf`: 执行单步动态优先级优先算法。][`schedule_running_rr`: 执行单步时间片轮转算法。
][`pop_front`: 类似双向队列的形式将链表首节点弹出。][`push_back`: 类似双向队列的形式将节点插入表尾巴。][`finish_one`: 将链首节点弹出后修改其状态。]

== Priority First 实现

#idnt2 由`PcbController`实现调度算法。`PCB`链首进程为当前运行进程，其余进程为`Waiting`状态。

#idnt2 当进程数只有一个时，直接将该进程运行至结束。

#code(caption: "Priority First Part-1")[
  ```cpp
  PcbController::ResTuple PcbController::schedule_running_pf() noexcept {
    if (empty()) {
        return ret_false_type(Err::NoEnoughProcess);
    }
    else if (m_process_count == 1) {
        return finish_one();
    }
    ......
  }
  ```
]

#idnt2 当进程数至少有2个，而链首进程可以在时间片内运行完成时，让该进程运行至结束并移出链表，并使下一个进程进入`Running`状态。

#code(caption: "Priority First Part-2")[
  ```cpp
  PcbController::ResTuple PcbController::schedule_running_pf() noexcept {
      ......
      // at least 2 processes
      PCB* next_tmp = m_now_running->next;
      m_now_running->cpu_hold_time += m_time_slice;
      m_now_running->priority += 3;
      if (m_now_running->cpu_require_time - m_time_slice <= 0) {
          m_now_running->next->state = PCB::State::Running;
          return finish_one();
      }
      ......
   }
  ```
]

#idnt2 当进程数至少有2个时，每次调度需要修改优先数和进程占用时间片数。大致分为下面两种情况：

#list(indent: 2em, marker: none)[
  1. 当前运行进程优先数增加(优先级降低)后，依然比第二个进程优先级高或相等。
][
  2. 当前运行进程优先数增加(优先级降低)后，比第二个进程优先级低。
]

#idnt2 对于第一种情况，仍使当前运行进程继续运行。

#code(caption: "Priority First Part-3")[
  ```cpp
  PcbController::ResTuple PcbController::schedule_running_pf() noexcept {
    ......
    else {
        // at least 2 process, and will not finish
        if (m_now_running->priority <= next_tmp->priority) {
            m_now_running->cpu_require_time -= m_time_slice;
            next_tmp->state      = PCB::State::Waiting;
            m_now_running->state = PCB::State::Running;
            return ret_true_type(m_now_running);
        }
    ......
    }
  }
  ```
]

#idnt2 对于第二种情况，此时需要将链首进程重新按照优先级插入链表，此时又分为两种情况：

#list(indent: 2em, marker: none)[
  1. 存在比当前运行进程优先数高(优先级更低)的进程。
][
  2. 不存在比当前运行进程优先数高(优先级更低)的进程。
]

#idnt2 对于不存在比当前运行进程优先数高的进程，直接将当前运行进程插入链表尾部，下一个进程进入`Running`状态。而对于存在比当前运行进程优先数高的进程，
将当前运行进程插入到该进程之前。

#code(caption: "Priority First Part-4")[
  ```cpp
  ......
   PCB* tmp = next_tmp->next;
   while (tmp != nullptr) {
       if (tmp->priority >= m_now_running->priority) {
           break;
       }
       tmp = tmp->next;
   }
   if (!tmp) {
       tmp = m_now_running;
       m_now_running->cpu_require_time -= m_time_slice;
       m_process_count -= 1;
       push_back(m_now_running);
       m_tail->state        = PCB::State::Waiting;
       m_now_running->state = PCB::State::Running;
       return ret_true_type(tmp);
   }
   else {
       m_now_running->cpu_require_time -= m_time_slice;
       m_now_running->state = PCB::State::Waiting;
       m_head               = m_now_running->next;
       m_head->prev         = nullptr;
       m_head->state        = PCB::State::Running;
       PCB* tmp_prev        = tmp->prev;
       tmp->prev            = m_now_running;
       PCB* tmp_ret         = m_now_running;
       m_now_running->next  = tmp;
       m_now_running->prev  = tmp_prev;
       tmp_prev->next       = m_now_running;
       m_now_running        = m_head;
       return ret_true_type(tmp_ret);
   }
  ```
]


== Round Robin 实现

#idnt2 由`PcbController`实现调度算法。`PCB`链首进程为当前运行进程，其余进程为`Waiting`状态。

#idnt2 对于当前只有一个进程的情况，直接让该进程执行完全程，返回给外界。

#code(caption: "Round Robin Part-1")[
  ```cpp
   PcbController::ResTuple PcbController::schedule_running_rr() noexcept {
      if (m_process_count < 1) {
          return ret_false_type(Err::NoEnoughProcess);
      }
      else if (m_process_count == 1) {
          return finish_one();
      }
      ......
  }
  ```
]

#idnt2 每次调度时，将链首进程放到链尾，链首进程更新，当前运行进程更新。对于被调度的进程，根据设定时间片数进行调整，当进程当前所需时间片为0时，将进程状态置为`Finish`并从链表中返回给外界，进行回收。

#code(caption: "Round Robin Part-2")[
  ```cpp
   PcbController::ResTuple PcbController::schedule_running_rr() noexcept {
     ......
      m_now_running->cpu_hold_time += m_time_slice;
      if (m_now_running->cpu_require_time - m_time_slice <= 0) {
          m_now_running->next->state = PCB::State::Running;
          return finish_one();
      }
      else {
          m_now_running->cpu_require_time -= m_time_slice;
          m_now_running->state = PCB::State::Waiting;

          // this must be true; because we have at least 2 process
          auto [front, ] = pop_front();
          push_back(front);
          m_now_running->state = PCB::State::Running;
          return ret_true_type(front);
      }
  }
  ```
]

= 操作过程

== Priority First 操作过程

#idnt2 向编译好的程序中按下面的格式输入数据。运行结果见 @pf_res.

#figure(caption: "Priority First输入数据")[
  #image("../assets/pf_input.png", width: 350pt)
]

== Round Robin 操作过程

#idnt2 在第一步输入时输入`rr`即可，其他输入情况与`Priority First`一致。运行结果见 @rr_res。

= 结果

== Priority First 运行结果 <pf_res>

#idnt2 每轮输出调度前的链所有进程情况，并输出一次当前运行结果。

#figure(caption: "Priority First运行结果 轮次 1")[
  #image("../assets/pf_turn_1.png", width: 350pt)
]

#figure(caption: "Priority First运行结果 轮次 2")[
  #image("../assets/pf_turn_2.png", width: 350pt)
]

#idnt2 省去过多轮次的输出，最终调度结果按照进程号看为 "1 0 2 0 2 3 2 3"，结果如下图4。

#figure(caption: "Priority First运行结果 最终")[
  #image("../assets/pf_turn_final.png", width: 350pt)
]

#idnt2 按照流程可根据输入分析输出情况。可以发现程序输出情况完全正确。

#figure(caption: "Priority First运行分析 1")[
  #image("../assets/pf_1.png", width: 350pt)
]

#figure(caption: "Priority First运行分析 2")[
  #image("../assets/pf_2.png", width: 350pt)
]

#figure(caption: "Priority First运行分析 3")[
  #image("../assets/pf_3.png", width: 350pt)
]



== Round Robin 运行结果 <rr_res>

#idnt2 每轮输出调度前的链所有进程情况，并输出一次当前运行结果。由于时间片轮转算法分析较为简单，此处只给出最终结果。可以看见是"0 1 2 3 0 2 3 2"，*注意，当只剩下一个进程时会直接执行完成，而不会按步继续*。

#figure(caption: "Round Robin运行结果 最终")[
  #image("../assets/rr_turn_final.png", width: 350pt)
]

= 体会

#idnt2 本次实验中，我通过代码模拟了两个进程调度算法。但是仅通过模拟算法不足以真正理解操作系统在 `NO STD`时必须手动实现内存池、线程池、锁等基础设施。对于实际的处理机调度，还须考虑竞态条件。本次实验仅是针对算法进行简单模拟，对于实际操作系统的调度算法还有很多细节需要考虑。

#idnt2 虽说本次实验只是简单模拟，但是我对于进程调度算法的理解有了更深一步的认识。在实际操作系统中，进程调度算法是非常重要的一部分，不同的调度算法会对系统的性能产生很大的影响。因此，对于进程调度算法的理解非常重要。
