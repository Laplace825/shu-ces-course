/// show ref: refer_to
#let refer_to(content) = [
  #box(stroke: (rest: rgb(0x22, 0xff, 0xf3)))[
    #text(content, size: 12pt)
  ]
]

#let base(content) = {
  set heading(bookmarked: true, numbering: "1.")
  set text(font: ("Times New Roman", "Songti SC"), size: 12pt, lang: "zh", region: "cn")
  set page("a4", header-ascent: 2em, header: align(right)[#text(size: 8pt)[
      _DataBase Principle (1) Experiment_
    ]], numbering: "1/1")
  show ref: refer_to
  show heading.where(level: 1): set text(size: 14pt, weight: "bold")
  show heading.where(level: 2): set text(size: 12pt, weight: "bold")
  show heading.where(level: 3): set text(size: 12pt)
  show par : set par(first-line-indent: 2em, justify: true, spacing: 0.55em)
  content
}

#let idnt2 = h(2em)

#let code(raw) = align(center)[#block(fill: rgb("#dcdcdcd9"), inset: 0.5em, radius: 4pt)[#raw]]

#let code_img(raw, path: path, caption: str) = grid(
  columns: (1.6fr, 2fr),
  inset: 2pt,
  align(center)[#block(fill: rgb("#dcdcdcd9"), inset: 0.5em, radius: 4pt)[#raw]],
  align(center)[#figure(image(path, width: 247pt), caption: caption)],
)

#let set_title(title) = {
  align(center, text(16pt, font: ("Times New Roman", "Heiti SC"))[
    *#title*
  ])

  align(center)[#line(length: 60%)]

  grid(columns: (1.3fr, 1fr), align(center, text(12pt)[
    *学号:* \
    *姓名:* \
  ]), align(left, text(12pt)[
    何勇乐 \
    22121639
  ]))
  align(center)[#line(length: 60%)]
}