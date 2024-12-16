# Operating System 

## About the Report

There is a report template written with `typst`, you can find it in "report/lib/template.typ".
The `env_info` variable is my env, you can change the `env_intro` and `env_table` to fit your computer like
below.

```typ
#let env_intro = [
#idnt2 实验环境见@table_1。本实验使用 `Rust` 进行开发.
]

#let env_table = figure(caption: "实验环境")[

  #table(
    stroke: none,
    inset: 0.5em,
    align: center,
    columns: (20%, 40%),
    table.hline(stroke: 1.2pt),
    [*OS*],
    [_Ubuntu 24.04 LTS_],
    table.vline(x: 1),
    [*CPU*],
    [_AMR Ryzen 6800H_],
    [*Compiler*],
    [_LLVM Clang++ 19.1.4_],
    [*C++ Standard*],
    [_ISO C++23_],
    table.hline(stroke: 1.2pt),
  )
]

```

If you want to see how it looks like, you can use vscode to open `report/` folder, and use `tinymist` plugin 
to preview the `main.typ` ( Actually is my report without my name and student id).
