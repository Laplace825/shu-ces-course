#import "../lib/template.typ": *

#show: base
#set_title(title: "死锁观察与避免", author: "xxx", student_id: 114514, date: "2024.11.25")

= 实验环境

#env_info

= 实验目的

#idnt2 死锁会引起计算机工作僵死，造成整个系统瘫痪。因此，死锁现象是操作系统特别是大型系统中必须设法防止的。本实验尝试独立的使用高级语言编写和调试一个系统动态分配资源的简单模拟程序，观察死锁产生的条件，并采用适当的算法，有效的防止死锁的发生。通过实习，更直观地了解死锁的起因，初步掌握防止死锁的简单方法，加深理解课堂上讲授过的知识。

+ 设计一个n个并发进程共享m个系统资源的系统。进程可动态地申请资源和释放资源。系统按各进程的申请动态地分配资源。
+ 系统应能显示各进程申请和释放资源以及系统动态分配资源的过程，便于用户观察和分析。
+ 系统应能选择是否采用防止死锁算法或选用何种防止算法(如有多种算法)。在不采用防止算法时观察死锁现象的发生过程。在使用防止死锁算法时，了解在同样申请条件下，防止死锁的过程。

= 实验内容

== 实验总体概述

#idnt2 本次实验采用银行家算法防止死锁的发生。假设有三个并发进程共享十个系统。在三个进程申请的系统资源之和不超过10时，当然不可能发生死锁，因为各个进程申请的资源都能满足。在有一个进程申请的系统资源数超过10时，必然会发生死锁。应该排除这二种情况。程序采用人工输入各进程的申请资源序列。

#idnt2 实验中采用了银行家算法，模拟系统中一共有四种资源，分别为I/O打印机、内存、缓冲区、总线。如下@table_2。

#my_table(
  caption: "模拟系统资源",
  header_l: "资源",
  header_r: "数量",
  [*IOTypst*],
  [10],
  [*Memory*],
  [5],
  [*Buffer*],
  [7],
  [*Bus*],
  [10],
)<table_2>

== 系统错误码

#idnt2 系统包括错误码如下@table_3。

#my_table(
  caption: "系统错误码",
  header_l: "错误",
  header_r: "对应编码",
  [*请求超过系统资源量*],
  [0],
  [*请求超过进程承诺最大资源量*],
  [1],
  [*没有足够资源进行分配*],
  [2],
  [*该进程不存在*],
  [3],
  [*不存在安全序列*],
  [4],
)<table_3>

== 系统资源抽象

#idnt2 系统资源通过枚举类的形式定义，对于每个资源类型，我们定义了最大资源数量、每种资源的编码。例如`IOTypst`等四种资源可以由0到3的数字表示。

#code(caption: "系统资源抽象")[```cpp
  // how many types of resources
  constexpr uint8_t SystemResourcesTypeNum = 4;

  enum class SystemResourcesType : uint8_t {
      IOTypst = 0,
      Memory,
      Buffer,
      Bus,
  };

  // Max resources for each system resources
  enum class MaxSystemResources : uint8_t {
      IOTypst = 10,
      Memory  = 5,
      Buffer  = 7,
      Bus     = 10,
  };
  ```]

== 抽象Process设计

#idnt2 实验模拟每个进程(Process)被创建后，在系统中占有以及申请资源的情况。对于每个进程，我们需要记录每个进程的进程号、最大需求资源、已占有资源、还需要多少资源。因此，每个进程都是一个`Process`类，用于记录每个进程的资源情况。

#idnt2 下列代码包括了`Process`类的设计。由于每种资源类型都有对应的数字编码，资源占有可以通过定长数组表达。

#code(caption: "Process设计")[```cpp
  class Process {
      friend class Controller;

    public:
      using resources_t = std::array< uint32_t, SystemResourcesTypeNum >;
      Process(uint32_t id = 0);
      Process(std::initializer_list< uint32_t > m);

      void set_max_require(resources_t max_require);
      Result get(const resources_t& to_consume);
      resources_t release_all();
      resources_t need() const;
      uint32_t id() const;
      void print() const noexcept;

    private:
      uint32_t m_id;
      resources_t m_max_require;
      resources_t m_need;
      resources_t m_hold;
  };
  ```]

== 资源控制器(Controller)设计

=== 资源控制器功能

#idnt2 `Process`结构只提供了基本的资源操作，只与自己承诺的最大请求量进行比较。而`Controller`类则提供了更多的资源操作，包括资源分配、资源释放、资源检查等。`Controller`类是整个银行家算法的核心模块，使用该类实现银行家算法。

#idnt2 `Controller`功能如下：

#list(indent: 2em)[
  为系统生成合理的进程并分配进程号。
][提供`is_safe`接口，用于检查是否存在安全序列，进行死锁避免。][安全地为进程分配所请求的最大资源数，超过系统资源的将返回错误，拒绝分配。][对系统资源的剩余量进行修改，不允许进程对系统资源情况进行修改。]

=== `Controller`内部函数

#idnt2 下列函数包括了`Controller`具有对各种核心功能，包括资源分配、资源释放、资源检查等。基于银行家算法的每个步骤，实现部分对应的函数。

#code[
```
  ├ generate_id
  ├ check_process_id
  ├ allocate_system_resources
  ├ release_system_resources
  ├ check_enough
  ├ in_max_require
  ├ in_require
  ├ release
  ├ is_safe
  ├ resources_hold
  ├ available
  ```
]

#idnt2 部分函数功能如下，在随报告提交的源码中可以查阅细节，应包括`process.h process.cc`。

#list(
  indent: 2em,
)[
`release`: 为某个进程释放其所有资源。
][`available`: 返回当前系统剩余可用资源。][`in_require`: 为某个进程申请资源。][`in_max_require`: 初始化某个进程的最大资源需求量。][`check_enough`: 根据传入的请求检测当前系统资源是否足够。]

== 银行家算法实现

#idnt2 每次输入某个进程号，要求为某个进程分配一定的资源(这里的所有进程已经做好了前置输入及初始化工作)。

#code(caption: "银行家算法实现 Part 1")[```cpp
  while (true) {
    uint32_t pid;
    std::cin >> pid;
    if (pid >= process_number) {
        std::println(
          RED "Error: {}" RESET, uint32_t(banker::Err::ProcessNotExist));
        continue;
    }

    banker::Process::resources_t require;
    for (auto& r : require) {
        std::cin >> r;
    }
    ......
  }
  ```]

#pagebreak()

#idnt2 此部分是银行家算法的核心部分，对于某个申请资源的进程，需要进行安全序列检查，并且尝试进行分配资源，如果分配资源失败，需要回滚到之前的状态。这里基本可以分为3步。
#list(indent: 2em)[
使用拷贝后的控制器进行资源申请，如果申请失败`!e.has_value()`，则回滚到之前的状态。
][当能够分配时，尝试进行分配，并检查是否存在安全序列，如果不存在安全序列，则回滚到之前的状态。][若上述步骤均成功，则打印信息`< Safe >`表示当前能够成功分配资源。]

#code(caption: "银行家算法 Part 2")[
```cpp
  while(true){
    ......
    auto copyed = ctrl;
    if (auto err = ctrl.in_require(pid, require); !err.has_value()) {
        std::println(RED "Error: {}" RESET, uint32_t(err.error()));
        ctrl = std::move(copyed);
        // this macro print the system available resources
        system_available(ctrl);
        continue;
    }
    if (auto err = ctrl.is_safe(); !err.has_value()) {
        std::println(RED "Error: {}" RESET, uint32_t(err.error()));
        ctrl = std::move(copyed);
        system_available(ctrl);
        continue;
    }

    std::println(GOLD "< Safe >" RESET);
    system_available(ctrl);
    ctrl.print();
  }
  ```
]

#pagebreak()

= 操作过程

== 初始化

#idnt2 向编译后的程序中输入数据,此时还没有未任何进程分配资源，运行结果见@res。

#img("../assets/banker_1.png", caption: "进程初始化输入最大需求量", width: 280pt)

== 尝试分配资源

#idnt2 为进程0分配资源，每个资源数量均为1。后续操作与此一致，结果见@res。

#img("../assets/banker_2_input.png", caption: "进程0申请资源", width: 280pt)

#pagebreak()

= 结果 <res>

== 成功分配资源

#idnt2 可以看见分配资源成功后系统资源情况和每个进程的资源占有情况。

#img("../assets/banker_sucess.png", caption: "成功分配资源", width: 280pt)

== 请求超过承诺最大需求数

#idnt2 得到错误码1，表示超过当前进程最大需求。

#img("../assets/banker_require_gt.png", caption: "请求超过承诺最大需求数", width: 280pt)

== 请求超过系统资源量

#idnt2 得到错误码2，表示系统资源量不足以分配。

#img("../assets/banker_gt_sys.png", caption: "请求超过系统资源量", width: 280pt)

#pagebreak()

== 不存在安全序列

#idnt2 我们重新进行进程初始化，让每个进程能尽可能多地获取资源，使系统更容易出现不存在安全序列的情况。如图6所示。系统最大资源量为"10, 5, 7, 10"，当已经为0号进程分配了"10, 3, 4,
5"后，如果再为1号进程分配"0, 2, 2, 4"，则系统剩余资源满足不了任何进程的需求，所有的进程依然在请求资源，发生死锁，也就是不存在安全序列，对应错误码4。

#img("../assets/banker_no_safe_seq.png", caption: "不存在安全序列", width: 280pt)

= 体会

#idnt2 本次实验基于`C++`实现了银行家算法，并对操作系统(1)中所讲授的系统资源管理和分配有了更深刻的了解。从实验中，我了解到银行家算法是个很有效的算法但是实现时有较多限制条件，虽然可用于防死锁，但花费的代价很大。

#idnt2 目前现代的大多数主流面向普通用户的操作系统面对死锁问题时往往只是忽略它，即鸵鸟策略。因为解决死锁问题的代价教高，鸵鸟策略具有更高的性能。当发生死锁时不会对用户造成多大影响，或发生死锁的概率很低，可以采用鸵鸟策略。但对于一些安全性要求较高的系统，必须采取一些措施来防止避免死锁或死锁解除。
