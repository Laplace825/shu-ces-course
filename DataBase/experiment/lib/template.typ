#let base(content) = {
  set heading(bookmarked: true, numbering: "1.")
  set text(font: ("Times New Roman", "Songti SC"), size: 12pt, lang: "zh", region: "cn")
  set page("a4", header-ascent: 2em, header: align(right)[#text(size: 8pt)[
      _DataBase Principle (1) Experiment_
    ]], numbering: "1/1")
  show heading.where(level: 1): set text(size: 14pt, weight: "bold")
  show heading.where(level: 2): set text(size: 12pt, weight: "bold")
  show heading.where(level: 3): set text(size: 12pt)
  show par : set par(first-line-indent: 2em, justify: true, spacing: 0.55em)
  content
}

#let idnt2 = h(2em)

#let code_img(raw, path: path, caption: none) = grid(
  columns: (1.5fr, 2fr),
  inset: 2pt,
  align(center)[#block(fill: rgb(0xf2, 0xf2, 0xf2), inset: 0.5em, radius: 4pt)[#raw]],
  align(center)[#figure(image(path, width: 17em), caption: caption)],
)

#let set_title(title: str, name : str, student_id: str) = {
  align(center, text(16pt, font: ("Times New Roman", "Heiti SC"))[
    *#title*
  ])

  align(center)[#line(length: 60%)]

  grid(columns: (1.3fr, 1fr), align(center, text(12pt)[
    *学号:* \
    *姓名:* \
  ]), align(left, text(12pt)[
     #name \
     #student_id
  ]))
  align(center)[#line(length: 60%)]
}
