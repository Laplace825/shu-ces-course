#let base(content) = {
  set text(font: ("Times New Roman", "Songti SC"), size: 12pt, lang: "zh", region: "cn")
  set heading(bookmarked: true, numbering: "1.")
  set par(justify: true, leading: 0.7em)
  set page("a4", header-ascent: 2em, header: align(right)[
    _Operating System (2) Experiment_
  ], numbering: "1/1")

  show raw: set text(ligatures: true)
  show heading.where(level: 1): set text(size: 16pt, weight: "bold", font: ("Times New Roman", "Heiti SC"))
  show heading.where(level: 2): set text(size: 14pt, weight: "bold", font: ("Times New Roman", "Heiti SC"))
  show heading.where(level: 3): set text(size: 12pt, font: ("Times New Roman", "Heiti SC"))

  content
}

#let idnt2 = h(2em, weak: false)

#let code(content, caption: none) = align(center, figure(
  caption: caption,
  supplement: [code],
  numbering: "1",
)[ #block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 1em, radius: 5pt)[#content] ])

#let img(path, caption: none, width: 60%, height: none) = figure(caption: caption)[
  #if height != none {
    image(path, width: width, height: height)
  } else {
    image(path, width: width)
  }
]

#let set_title(title: str, author: str, student_id: int, date: str) = {
  align(center, text(22pt, font: ("Times New Roman", "Heiti SC"))[
    *《计算机操作系统》实验报告*
  ])

  align(center)[
    #par(spacing: 0.2em)[
      #line(length: 86%)
      #line(length: 86%)
    ]
  ]

  grid(align: center, columns: (1.4fr, 2.8fr))[
    #align(left, text(16pt, font: ("Times New Roman", "Heiti SC"))[
      #h(3em)*实验题目:* \
      #h(3em)*姓名:* #author \
    ])
  ][
    #align(left, text(16pt, font: ("Times New Roman", "Heiti SC"))[
      #title \
      *学号:* #student_id#h(1em)*实验日期:* #date \
    ])
  ]

  align(center)[
    #line(length: 86%)
  ]
}

#let my_table(caption: str, header_l: str, header_r: str, ..rows) = figure(caption: caption, table(
  stroke: none,
  inset: 0.5em,
  align: center,
  columns: (40%, 40%,),
  table.hline(stroke: 1.2pt),
  [*#header_l*],
  [*#header_r*],
  table.hline(stroke: 1.2pt),
  ..rows,
  table.hline(stroke: 1.2pt),
))

= 实验环境

#let env_intro = [
#idnt2 实验环境见@table_1。本项目舍弃`try catch`异常处理，使用`std::expected`进行异常处理。引入格式化字符串打印 `<print> header file`。
*已提供构建脚本，但本实验必须使用支持ISO C++ 23编译套件，对于GNU/GCC，应使用gcc 14.x 版本及以上。*
]

#let env_table = figure(caption: "实验环境")[

  #table(
    stroke: none,
    inset: 0.5em,
    align: center,
    columns: (20%, 40%),
    table.hline(stroke: 1.2pt),
    [*OS*],
    [_Darwin 24.1.0_],
    table.vline(x: 1),
    [*CPU*],
    [_Apple M3 Arm64_],
    [*Compiler*],
    [_LLVM Clang++ 19.1.4_],
    [*C++ Standard*],
    [_ISO C++23_],
    table.hline(stroke: 1.2pt),
  )
]

#let env_info = [
  #env_intro

  #env_table <table_1>
]

= 实验目的

= 实验内容

= 操作过程

= 结果

见 @app

= 体会

// NOTE: APPENDIX

#let appendix(body) = {
  set heading(numbering: "A.", supplement: [Appendix])
  counter(heading).update(0)
  body
}

#let AppendixHeading = heading(numbering: none)[#text("Appendix", size: 16pt, weight: "bold")]

#let appendix-show(content) = {
  show: appendix
  content
}

#show: appendix-show

= xxxxx <app>
