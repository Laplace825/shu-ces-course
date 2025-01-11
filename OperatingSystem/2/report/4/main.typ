#import "../lib/template.typ" : *

#show: base

#set_title(title: "Linux文件操作二", author: "", student_id: 114514, date: "2024.12.23")

#show ref: refer_to

= 实验环境

#env_info_rust

= 实验目的

#idnt2 随着社会信息量的极大增长，要求计算机处理的信息与日俱增，涉及到社会生活的各个方面。因此，文件管理是操作系统的一个极为重要的组成部分。学生应独立地用高级语言编写和调试一个简单的文件系统，模拟文件管理的工作过程。从而对各种文件操作命令的实质内容和执行过程有比较深入的了解，掌握它们的实施方法，加深理解课堂上讲授过的知识。

= 实验内容

== 实验内容概述

+ 限制用户在一次运行中只能打开 1 个文件。
+ 系统应能检查打入命令的正确性，出错要能显示出错原因。
+ 对文件必须设置保护措施，如只能执行，允许读、允许写等。
+ 对文件的操作至少应有下述几条命令：
  - creat 创建文件。
  - delete 删除文件。
  - open 打开文件。
  - close 关闭文件。
  - read 读文件。
  - write 覆盖写文件。
  - append 追加文件内容。

#my_table(caption: "文件权限", header_l: "文件权限", header_r: "含义", [r], [可读], [w], [可写], [x], [可执行]) <table_permissions>

== 模拟文件权限

#idnt2 文件权限按照@table_permissions 及@code_permissions
所示，分为读写可执行三类。在文件系统中，可以对每个文件以3位二进制数表示，如 $101_b$ 表示可读可执行，$110_b$ 表示可读可写。

#code(caption: "文件权限定义")[```rs
pub enum Permission {
    Read = 0b100,
    Write = 0b010,
    Execute = 0b001,
}
```] <code_permissions>

#idnt2 每个文件权限的组合通过二进制或运算得到，每个文件权限的检查通过与运算得到。例如@math_1，对于文件权限 $110_b$，可读可写，检查可读权限的方法是 $110_b$ 与 $100_b$ 进行与运算，结果为 $100_b$，表示有可读权限。当检查结果为 $000_b$，表示没有可读权限。最终代码如@code_permissions_check
中所示。

$
    & text("组合可读可写")& 0b 100 or 0b 010        &= 0b 110 \
    & text("检查可读")    & 0b 110 #math.and 0b 100 &= 0b 100
$ <math_1>

#code(caption: "文件权限检查")[```rs
if permission & u8::from(Permission::Read) == 0 {
    return Err(Error::PermissionDeniedRead);
}
```] <code_permissions_check>

== 文件操作码

#code(caption: "文件操作码定义")[```rs
pub enum Op {
    Read = 0b0000,
    Write = 0b0001,
    Execute,
    Append,
    Delete,
    ChangeMode,
}
```] <code_file_op_code>

#idnt2 为便于对文件操作进行分类，定义文件操作码如@code_file_op_code
所示。所有文件操作码通过枚举类型定义，包括读、写、执行、追加、删除、修改权限等操作，以一字节存储，从0开始编号。

== 模拟文件

=== 文件元数据(Meta)

#idnt2 文件元数据应包括文件名、文件权限、文件修改时间、文件大小等信息。在本实验中，文件元数据定义如@code_file_meta。只有文件名和文件权限可以直接被修改，*对于文件大小和文件修改时间，只能通过文件操作来修改。这符合操作系统设计标准，而不是自己手动设置。*

#code(caption: "文件元数据定义")[```rs
pub struct Meta {
    pub name: String, // file name
    pub permission: PermissionNumber,
    time_modified: DateTime<Local>, // time when file was modified
    size: u64,
}
```] <code_file_meta>

=== 文件定义

#idnt2 文件定义包括文件元数据和文件内容。文件内容由 Byte
数组存储，文件定义如@code_file。每个文件的元数据和内容都是可变的，因此使用 ```rs RefCell``` 包装。

#code(caption: "文件定义")[```rs
pub struct File {
    pub meta: RefCell<Meta>,
    pub data: RefCell<Vec<u8>>,
}
```] <code_file>

=== 文件操作

#idnt2 与文件相关的所有操作均为对 `File` 的操作，这些操作不对外暴露，只能通过文件系统调用传入操作码并根据检查情况进行函数转发。文件操作如@code_file_op。由于可执行文件的特殊性，其必须依赖系统调用执行，因此在文件操作中，目前可执行文件只输出执行信息，不做其他操作。

#code(caption: "文件操作")[```rs
pub fn op(
    &self,
    op: Op,
    src: Option<Vec<u8>>,
    mode: Option<PermissionNumber>,
) -> Result<Option<Vec<u8>>> {
    let mode = mode.unwrap_or(self.permission());
    self.check_permission(op)?;
    match op {
        Op::Read => Ok(Some(self.read())),
        Op::Write => {
            self.write(src.ok_or(Error::DataWriteIsNone)?);
            Ok(None)
        }
        Op::Execute => {
            let name = self.name();
            std::println!("{} {}", "Execute:".yellow(), name);
            Ok(None)
        }
        Op::Append => {
            self.append(src.ok_or(Error::DataWriteIsNone)?);
            Ok(None)
        }
        Op::ChangeMode => {
            self.change_mode(mode);
            Ok(None)
        }
        Op::Delete => Ok(None),
    }
}

```] <code_file_op>

== 模拟用户

#idnt2 用户包括用户名和该用户所有的文件。用户定义如@code_usr。用户的所有文件通过 B
树的形式存储，文件名为键，文件为值。每个文件本身可变，因此使用 ```rs RefCell``` 包装。

#code(caption: "用户定义")[```rs
pub struct User {
    name: String,
    files: RefCell<BTreeMap<String, file::File>>,
}
```] <code_usr>

#idnt2 每个用户针对文件实现了一系列操作，包括创建文件、删除文件、打开文件、关闭文件、读文件、写文件、追加文件内容、修改文件权限等。所有用户通过系统提供的接口进行操作，不对外暴露。具体每个操作的运行情况见@res。

#list(
  indent: 2em,
)[`add_file`: 创建文件。][`get_file`: 获取文件。][ `write_file`: 写文件。 ][ `read_file`: 读文件。 ][`delete_file`: 删除文件。][ `change_mode_file`: 修改文件权限。 ][ `append_file`: 追加文件内容。 ]

= 操作过程

== 简述

#idnt2 为便于实验展开，系统默认添加了两个用户 `root` 和 `lap`。本报告将每次以 `lap` 的身份进行登录，进行文件操作。每次操作后，将输出操作结果。

== 操作流程

#idnt2 所有操作过程如下，具体结果请参考@res。每个步骤都会进行错误情况展示。

#list(
  indent: 2em,
)[登录用户 `lap`。][创建文件 `file1`。][写文件 `file1`。][读文件 `file1`。][追加文件内容 `file1`。][修改文件权限 `file1`。][删除文件 `file1`。]

= 结果 <res>

== 登录用户

=== 成功登录用户 `lap`。

#img("../assets/usr_login.png", caption: "成功登录用户", width: 80%)

=== 登录不存在的用户

#img("../assets/usr_login_f.png", caption: "登录不存在的用户", width: 80%)

=== 密码错误

#img("../assets/usr_login_pf.png", caption: "密码错误", width: 80%)

== 创建文件file1

#idnt2 创建文件file1且权限为仅可写。可以看见空的文件file1及其创建时间。

#img("../assets/create_file1.png", caption: "创建文件file1", width: 80%)

== 向file1内写入内容

#idnt2 向file1内写入内容`hello`。可以看见文件长度变为5。

#img("../assets/write_file1_hello.png", caption: "向file1内写入内容", width: 80%)

#idnt2 无法读取file1，因为file1权限为仅可写。

#img("../assets/read_file1_hello_nop.png", caption: "尝试读取file1无权限失败", width: 80%)

== 修改file1权限

#idnt2 将file1权限改为可读可写。可以看见file1权限改变为 `rw-`。

#img("../assets/chomd_file1.png", caption: "修改file1权限", width: 80%)

#idnt2 再进行读取file1，可以看见file1内容为`hello`。

#img("../assets/read_file1_ok.png", caption: "读取file1成功", width: 80%)

== 追加file1内容

#idnt2 向file1追加内容`world`。可以看见file1内容变为`helloworld`。

#img("../assets/append_file1.png", caption: "追加file1内容", width: 80%)

== 删除file1

#idnt2 删除file1。可以看见file1被删除。

#img("../assets/delete_file1.png", caption: "删除file1", width: 80%)

== 删除不存在的文件

#idnt2 删除不存在的文件`pp`。可以看见删除失败。

#img("../assets/delete_fail.png", caption: "删除不存在的文件", width: 80%)

== 展示帮助信息

#idnt2 `help`将展示所有操作的帮助信息。

#img("../assets/show_help.png", caption: "展示帮助信息", width: 80%)

== 展示所有文件信息

#idnt2 `show`将展示所有文件信息。

#img("../assets/show_all.png", caption: "展示所有文件信息", width: 80%)

= 体会

#idnt2 通过本次实验，我使用 `Rust` 实现了一个简单文件系统的各种操作调用。在实现过程中，我对文件系统的设计有了更深入的了解，对文件权限、文件操作码、文件元数据等概念有了更深刻的认识。同时，我也学会了如何使用 `Rust` 进行文件操作，如何使用 `RefCell` 进行可变性操作，如何使用 `BTreeMap` 进行文件存储等。这些知识对我今后的学习和工作都有很大的帮助。`Rust` 从语言层面上保证了内存安全，使得我在实现文件系统时更加放心，不用担心内存泄漏等问题。这次实验让我对操作系统的文件系统有了更深入的了解，对操作系统的学习有了更多的兴趣。
