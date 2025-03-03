#let _refer_to_helper(c, number, ..nums) = {
  link(
    c.location(),
    box(
      clip: true,
      outset: 0.11em,
      stroke: (rest: rgb("#ff0000")),
      text(fill: black)[#numbering(
          number,
          ..nums,
        )],
    ),
  )
}

#let _generate_caption(caption: [], supplement, count) = {
  count.step()
  [#supplement #context count.display() #h(0.65em) #caption]
  v(-0.5em)
}

#let _code-counter = counter("code")

#let code(content, caption: none) = {
  let supplement = "代码"
  figure(kind: "code", supplement: supplement)[
    #_generate_caption(caption: caption, supplement, _code-counter)
    #content
  ]
}

#let _fake-code-counter = counter("fake-code")

#let fake-code(caption: none, input: content, output: content, ..steps) = {
  let supplement = "伪代码"
  figure(kind: "fake-code", supplement: supplement)[
    #_generate_caption(caption: caption, supplement, _fake-code-counter)
    #table(
      align: left,
      stroke: none,
      columns: (0.2fr, 1.2fr),
      table.hline(stroke: 1pt),
      [*Algorithm*], [#caption],
      table.hline(stroke: 0.5pt),
      table.cell(rowspan: 2)[*Input:* \ *Output:* ], [#input \ #output],
    )
    #move(dx: 1em, dy: -2em)[
      #{
        let n = 0
        for step in steps.pos() {
          n += 1
          let n-str = str(n) + "."
          box(
            grid(column-gutter: 0.5em, align: left, columns: (0.05fr, 1.5fr))[#text(
                style: "italic",
                size: 10pt,
              )[#n-str]][#step],
          )
        }
      }
    ]
    #move(dy: -2.5em)[
      #line(length: 100%, stroke: 0.5pt)
    ]
    #v(-1.5em)
  ]
}

#let _graph-counter = counter("graph")

#let graph(path: "", caption: none, alt: "", width: 80%, height: none) = {
  let supplement = "图"
  figure(kind: "graph", supplement: supplement)[
    #if height == none {
      image(path, width: width, alt: alt)
    } else {
      image(path, width: width, height: height, alt: alt)
    }
    #v(-1em)
    #_generate_caption(caption: caption, supplement, _graph-counter)
    #v(1.5em)
  ]
}

#let _table-counter = counter("table-maker")

#let table-maker(
  ..children,
  caption: [],
  align: auto,
  column-gutter: auto,
  columns: auto,
  fill: none,
  gutter: auto,
  inset: 0% + 5pt,
  row-gutter: auto,
  rows: auto,
  stroke: 1pt + black,
) = {
  let supplement = "表"
  figure(supplement: "表", kind: table)[
    #_generate_caption(caption: caption, supplement, _table-counter)
    #table(align: align, column-gutter: column-gutter, columns: columns, fill: fill, gutter: gutter, inset: inset, rows: rows, stroke: stroke, ..children)
  ]
}

#let lib-style(content) = {
  set text(font: ("Times New Roman", "Songti SC"), size: 10pt, lang: "zh", region: "cn")
  set page(
    paper: "a4",
    margin: (left: 3.18cm, right: 3.18cm, top: 2.54cm, bottom: 2.54cm),
    numbering: "1/1",
  )

  set heading(numbering: "1.")
  set outline(depth: 3, indent: 2em)

  show heading.where(level: 1): set text(size: 14pt)
  show heading.where(level: 2): set text(size: 12pt)
  show heading.where(level: 3): set text(size: 10pt)

  set math.equation(numbering: "(1)", number-align: right)

  set figure.caption(position: top)
  show figure.caption: set text(size: 10pt)

  show link: it => {
    text(fill: blue)[#underline(it)]
  }

  show ref: it => {
    let eq = math.equation
    let head = heading
    let el = it.element
    if el.has("supplement") {
      el.supplement + h(0.2em)
      if el.func() == head {
        _refer_to_helper(el, "1.1", ..counter(head).at(el.location()))
      } else if el.func() == eq {
        _refer_to_helper(el, "1", ..counter(eq).at(el.location()))
      } else if el.has("counter") {
        _refer_to_helper(el, "1", ..el.counter.at(el.location()))
      }
      h(0.05em)
    } else {
      it
    }
  }

  show cite: it => box(
    it,
    clip: true,
    // outset: 1em,
    inset: 0.01em,
    // baseline: -1em,
    stroke: (rest: rgb("#00bbbf")),
  )


  show raw.where(block: true): set text(size: 8pt, lang: "en")
  show raw.where(block: true): set par(spacing: 70% * 10pt)
  set raw(tab-size: 4)
  show raw.where(block: true): it => box(stroke: (right: 0.5pt))[
    #let counter = 0
    #for codes in it.lines {
      if counter == 0 {
        line(start: (5%, 0pt), end: (100%, 0pt), stroke: 0.5pt)
      }
      counter += 1
      let num = str(codes.number) + "."
      grid(align: left, columns: (0.05fr, 1fr))[#text(size: 6pt, style: "italic")[#num]][#codes.body]
    }
    #line(start: (5%, 0pt), end: (100%, 0pt), stroke: 0.5pt)
  ]

  show raw.where(block: false): it => {
    h(0.5em)
    box(fill: rgb("#d8d8d8"), outset: 2.5pt, radius: 2pt, clip: true)[
      #it
    ]
  }

  content
}

#let make-cover(title: [], name: [], id: 114514) = {
  set text(font: "Heiti SC")

  let year = datetime.today().year()

  align(center)[#text(size: 16pt, stroke: 0.5pt)[*上海大学 #{year - 1} \u{301C} #year 学年冬季学期* ]]

  v(-1em)

  grid(columns: 2)[#move(dy: 1em)[#text(
        size: 16pt,
        stroke: 0.5pt,
      )[#underline(stroke: 1pt)[*研究方法与前沿(计算机)*]*课程成绩评价表* ]]][#move(
      dx: 4em,
    )[#table(columns: 2, table.cell(inset: 2.5em)[成绩], table.cell(inset: 2.5em)[])]]

  linebreak()

  v(-2em)


  set text(size: 13.2pt)
  grid(column-gutter: 0.1em, columns: (0.4fr, 0.9fr, 0.5fr, 0.5fr))[课程名称:][#underline(
      "研究方法与前沿(计算机)",
      stroke: 0.5pt,
      extent: 0.3em,
    )][课程编号:][#underline(stroke: 0.5pt, extent: 1em)[*0830SY02*]]

  show line: it => {
    move(dy: 0.4em)[#it]
  }

  grid(column-gutter: 0.1em, columns: (0.8fr, 3.9fr))[研究题目：][#underline(
      stroke: 0.5pt,
      extent: 0.6em,
      offset: 2.5pt,
    )[#box[#h(0.3em)#title]]]

  grid(columns: (0.35fr, 0.4fr, 0.4fr, 0.6fr, 0.5fr, 1.1fr))[姓名:][#underline(
      stroke: 0.5pt,
      extent: 0.5em,
      offset: 2.5pt,
    )[#name]][学号:][#underline(stroke: 0.5pt, extent: 0.5em)[#id]][所在院系:][#underline(
      stroke: 0.5pt,
      extent: 0.3em,
    )[ 计算机工程与科学学院]]

  v(4em)


  set text(size: 12pt)
  table(
    align: center,
    inset: 1.7em,
    stroke: 0.5pt,
    columns: (1fr, 1fr, 1fr, 1fr),
    table.cell(rowspan: 2, align: center)[#move(dy: 3em)[指标]],
    [一],
    [二],
    [三],
    [研究方法(60%)],
    [国内外技术(20%)],
    [实验与验证(20%)],
    [得分], [], [], []
  )

  set text(size: 14pt)

  [研究报告评语:]

  v(12em)

  align(right)[任课教师：#h(4em)]
  pagebreak()
}


#let make-title(content, name: content, id: 114514) = {
  align(center)[#text(size: 20pt, stroke: 0.2pt)[#content]]

  align(center)[#name (#id)]
  linebreak()
}

#let make-abstract(content, ..keywords) = {
  set text(size: 10pt)

  [#text(stroke: 0.4pt)[摘要：]#content]
  v(1pt)
  {
    [#text(stroke: 0.4pt)[关键词#h(1em)]]
    for word in keywords.pos() {
      text[#word#h(0.5em)]
    }
  }
}

#let make-bibliography(source: "", style: "ieee") = {
  set text(font: "Times New Roman", size: 10pt, lang: "en")
  bibliography(
    source,
    style: style,
    title: text(font: ("Times New Roman", "Heiti SC"), size: 14pt, lang: "zh", region: "cn")[参考文献],
  )
}

#let appendix(body) = {
  set heading(numbering: "1.", supplement: [Appendix], depth: 1)
  counter(heading).update(0)
  body
}

#let AppendixHeading = heading(numbering: "A")[#text("附录", size: 14pt, weight: "bold")]

#let appendix-show(content) = {
  show: appendix
  show raw: set text(size: 8pt)
  // pagebreak()
  content
}
