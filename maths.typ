#import "@preview/cetz:0.4.2"

// A labelled matrix usable directly inside maths, like `mat`.
//
//   $T = labmat(P, R, ; 0.7, 0.4, P; 0.3, 0.6, R)$
//
// First row  = column labels, then a trailing comma for the empty corner.
// Each later row = the entries, then a trailing row label.
// Quoted strings ("Stay") render as upright text and rotate as column
// labels when wide; everything else renders as maths and never rotates.
//
// Call it BARE in maths (not with #): the `;` row syntax is a maths-mode
// feature, so `#labmat(...)` will not parse.
//
// Brackets and row spacing are taken from a throwaway native `mat` of the
// entries, so the result matches `mat` exactly with labels added around it.
#let labmat(..args) = context {
  let rows = args.pos()
  let numcols = rows.first().len() - 1
  let collabels = rows.first().slice(0, numcols)
  let datarows = rows.slice(1)
  let numrows = datarows.len()
  let entries = datarows.map(r => r.slice(0, numcols))

  let cell(c) = $#c$
  let render(l) = if type(l) == str { [#l] } else { $#l$ }
  // column labels: quoted words rotate when wide; maths never rotates
  let collabel(l) = {
    let c = render(l)
    pad(bottom: 0.12em, if type(l) == str and measure(c).width > 14pt {
      rotate(-90deg, reflow: true, c)
    } else { c })
  }

  // Simulate the plain matrix (entries only) and borrow real `mat` metrics:
  //   simH  = height with brackets    -> our bracket height
  //   bareH = height without brackets -> our entry rows' total height
  let simH = measure(math.equation(block: true, math.mat(delim: "[", ..entries))).height
  let bareH = measure(math.equation(block: true, math.mat(delim: none, ..entries))).height
  let bandH = bareH / numrows

  let delimcell(d) = table.cell(rowspan: numrows, box($lr(#d, size: #simH)$))

  let cols = (auto, ..(auto,) * numcols, auto, auto)
  let nrows = (auto, ..(bandH,) * numrows, auto)
  box(baseline: 50%, table(
    columns: cols,
    rows: nrows,
    stroke: none,
    align: center + horizon,
    inset: (x: 0.22em, y: 0pt),
    // column labels
    [], ..collabels.map(collabel), [], [],
    // data rows with bracket cells and row labels
    ..for (i, r) in datarows.enumerate() {
      (
        ..if i == 0 { (delimcell($\[$),) },
        ..r.slice(0, numcols).map(cell),
        ..if i == 0 { (delimcell($\]$),) },
        render(r.at(numcols)),
      )
    },
    // hidden copy of the label row, to balance it and centre the body
    [], ..collabels.map(l => hide(collabel(l))), [], [],
  ))
}


// Each colour parameter may be either a colour value or a zero-arg
// function returning a colour. Functions are resolved at render time inside
// a `context { ... }` block so themes can swap palette mid-document.
#let _resolve(x) = if type(x) == function { x() } else { x }

#let build(fg: black, ca: black, cb: black, cf: black) = {
  let mesh(cols, rows) = {
    grid(
      columns: (30pt,) * cols,
      rows: (30pt,) * rows,
      stroke: 0.5pt + gray,
      ..array.range(cols * rows).map(_ => [])
    )
  }

  let plane(
    min-x: -5,
    max-x: 5,
    min-y: -5,
    max-y: 5,
    xstep: 1,
    ystep: 1,
    blankaxes: false,
    labelstep: 1,
    xnumbers: (),
    ynumbers: (),
  ) = context {
    let fg = _resolve(fg)
    import cetz.draw: *
    cetz.canvas(length: 30pt, {
      grid(
        (min-x / xstep, min-y / ystep),
        (max-x / xstep, max-y / ystep),
        stroke: 0.2pt + gray.lighten(50%),
        step: 1,
      )
      line((min-x / xstep, 0), (max-x / xstep, 0), stroke: 0.8pt + fg, mark: (end: ">"))
      line((0, min-y / ystep), (0, max-y / ystep), stroke: 0.8pt + fg, mark: (end: ">"))
      content((max-x / xstep, 0), [$x$], anchor: "west", padding: 5pt)
      content((0, max-y / ystep), [$y$], anchor: "south", padding: 5pt)

      if not blankaxes {
        let x-to-label = if xnumbers.len() > 0 { xnumbers } else {
          range(int(min-x), int(max-x) + 1).filter(n => n != 0 and calc.rem(n, labelstep) == 0)
        }
        for x in x-to-label {
          let visual-x = x / xstep
          line((visual-x, -0.1), (visual-x, 0.1), stroke: 0.5pt + fg)
          content((visual-x, -0.2), [#x], anchor: "north")
        }
        let y-to-label = if ynumbers.len() > 0 { ynumbers } else {
          range(int(min-y), int(max-y) + 1).filter(n => n != 0 and calc.rem(n, labelstep) == 0)
        }
        for y in y-to-label {
          let visual-y = y / ystep
          line((-0.1, visual-y), (0.1, visual-y), stroke: 0.5pt + fg)
          content((-0.2, visual-y), [#y], anchor: "east")
        }
      }
    })
  }

  let numberline(
    axis-start: -5,
    axis-end: 7,
    ticks: none,
    open-dots: (),
    closed-dots: (),
    arrows: (),
    segments: (),
    width: 7cm,
    height: 0.7cm,
  ) = context {
    let fg = _resolve(fg)
    // Map data x to canvas units so the canvas has a fixed unit length.
    // Total horizontal span in canvas units = `span`; cetz `length` then
    // converts that span to `width` regardless of axis range, leaving
    // vertical sizes (tick height, ray-y, dot radius) unaffected.
    let span = 10
    let sx(x) = (x - axis-start) * span / (axis-end - axis-start)
    cetz.canvas(length: width / span, {
    import cetz.draw: *
    let y = 0
    let ray-y = 0.25

    line((sx(axis-start), y), (sx(axis-end), y), stroke: fg + 0.8pt)

    let tick-list = if ticks != none { ticks } else {
      range(axis-start, axis-end + 1)
    }
    for x in tick-list {
      line((sx(x), y - 0.12), (sx(x), y + 0.12), stroke: fg + 0.8pt)
      content((sx(x), y - 0.5), math.equation(str(x), block: false))
    }

    for seg in segments {
      line((sx(seg.at(0)), ray-y), (sx(seg.at(1)), ray-y), stroke: fg + 1.5pt)
    }

    for arr in arrows {
      let x = arr.at(0)
      let dir = arr.at(1)
      if dir == "right" {
        line((sx(x), ray-y), (sx(axis-end), ray-y), stroke: fg + 1.5pt, mark: (
          end: (symbol: ">", size: 0.25, fill: fg, stroke: fg + 0.8pt),
        ))
      } else {
        line((sx(x), ray-y), (sx(axis-start), ray-y), stroke: fg + 1.5pt, mark: (
          end: (symbol: ">", size: 0.25, fill: fg, stroke: fg + 0.8pt),
        ))
      }
    }

    for x in open-dots {
      circle((sx(x), ray-y), radius: 0.13, stroke: fg + 1pt, fill: white)
    }

    for x in closed-dots {
      circle((sx(x), ray-y), radius: 0.13, stroke: fg + 1pt, fill: fg)
    }
    })
  }

  // Inline blank for a short fill-in-the-blank answer, sized in ems.
  let gp(x) = context {
    let fg = _resolve(fg)
    box(width: x * 1em, line(length: 100%, stroke: 0.5pt + fg))
  }

  let venn(colour: true, n: false, ..args) = context {
    let fg = _resolve(fg)
    let ca = _resolve(ca)
    let cb = _resolve(cb)
    let pos = args.pos()

    let label_a = if pos.len() >= 1 { pos.at(0) } else { none }
    let label_b = if pos.len() >= 2 { pos.at(1) } else { none }
    let only_a = if pos.len() >= 3 { pos.at(2) } else { none }
    let inter = if pos.len() >= 4 { pos.at(3) } else { none }
    let only_b = if pos.len() >= 5 { pos.at(4) } else { none }
    let outside = if pos.len() >= 6 { pos.at(5) } else { none }

    let a_col = if colour { ca } else { fg }
    let b_col = if colour { cb } else { fg }
    let rect_top = if n { 2.8 } else { 2.3 }

    let fmt_label(lbl, col) = {
      if type(lbl) == str {
        text(fill: col, strong(eval("$" + lbl + "$", mode: "markup")))
      } else {
        text(fill: col, lbl)
      }
    }

    let n_val = {
      let total = 0
      for v in (only_a, inter, only_b, outside) {
        if type(v) == int or type(v) == float { total = total + v }
      }
      total
    }

    align(center, cetz.canvas({
      import cetz.draw: *
      rect((-3.5, -1.8), (3.5, rect_top), stroke: fg)
      circle((-0.8, 0.2), radius: 1.5, stroke: a_col + 1pt)
      circle((0.8, 0.2), radius: 1.5, stroke: b_col + 1pt)

      if label_a != none { content((-2.2, 1.8), fmt_label(label_a, a_col)) }
      if label_b != none { content((2.2, 1.8), fmt_label(label_b, b_col)) }

      if only_a != none { content((-1.4, 0.2), $#only_a$) }
      if inter != none { content((0, 0.2), $#inter$) }
      if only_b != none { content((1.4, 0.2), $#only_b$) }
      if outside != none { content((3, -1.3), $#outside$) }

      if n { content((-3.3, rect_top - 0.3), [$n = #n_val$], anchor: "north-west") }
    }))
  }

  // --- FRACTION DIAGRAMS ---
  // frac-circle(n, 1, 2)    → circle split into n wedges, 1st & 2nd shaded
  // frac-rectangle(n, 1, 2) → horizontal 5cm × 1cm bar split into n strips
  let frac-circle(n, ..filled) = context {
    let fg = _resolve(fg)
    let cf = _resolve(cf)
    let filled = filled.pos()
    let r = 1
    cetz.canvas({
      import cetz.draw: *
      for i in range(n) {
        let a1 = i * 360 / n
        let a2 = (i + 1) * 360 / n
        let fill-col = if filled.contains(i + 1) { cf } else { none }
        merge-path(fill: fill-col, stroke: fg + 0.8pt, {
          line(
            (0, 0),
            (r * calc.cos(a1 * 1deg), r * calc.sin(a1 * 1deg)),
          )
          arc(
            (r * calc.cos(a1 * 1deg), r * calc.sin(a1 * 1deg)),
            start: a1 * 1deg,
            stop: a2 * 1deg,
            radius: r,
          )
          line(
            (r * calc.cos(a2 * 1deg), r * calc.sin(a2 * 1deg)),
            (0, 0),
          )
        })
      }
    })
  }

  let frac-rectangle(n, ..filled) = context {
    let fg = _resolve(fg)
    let cf = _resolve(cf)
    let filled = filled.pos()
    let w = 5
    let h = 1
    let seg = w / n
    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      for i in range(n) {
        let x1 = i * seg
        let x2 = x1 + seg
        let fill-col = if filled.contains(i + 1) { cf } else { none }
        rect((x1, 0), (x2, h), fill: fill-col, stroke: fg + 0.8pt)
      }
    })
  }

  (
    mesh: mesh,
    plane: plane,
    numberline: numberline,
    venn: venn,
    frac-circle: frac-circle,
    frac-rectangle: frac-rectangle,
    gp: gp,
    A: "A",
    B: "B",
  )
}
