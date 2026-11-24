#import "@preview/shadowed:0.2.0": shadowed
#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.3"
#import "@preview/zero:0.7.0": num, set-group
#set-group(separator: sym.space.thin)
#let cetz = cetz
#let canvas = cetz.canvas
#let draw = cetz.draw
#let cetz-angle = cetz.angle
#let plot = cetz-plot

// Internal functionality

// Question and mark counter
//// These set up the internal counters. The questions counter counts what question you are up to. The marks counter totals up the marks in a given section so it can be printed in the contents.
#let q-counter = counter("question")
#let s-counter = counter("section")
#let marks-state = state("marks", ())

//// This turns off and on whether marks are printed beside the questions.
#let hide-marks-state = state("hide-marks", false)
#let hide-marks(..args) = hide-marks-state.update(args.pos().at(0, default: true))
#let _marks-label(m) = if m == 1 { "mark" } else { "marks" }

//// VCAA exams use Arial for all text, except for mathematics exams which use Times New Roman for the text within questions. When this is set to true, the font for question text is set to Times New Roman. The font for maths equations is always set to STIX Two Math, regardless. If set to false, the font size is adjusted so that it matches the appearance of Arial.
#let maths-state = state("maths", false)
#let maths(..args) = maths-state.update(args.pos().at(0, default: true))
#let _qtext-size = 14.17pt
#let _qtext(body) = context {
  if maths-state.final() { text(font: "Times New Roman", size: _qtext-size, body) } else { body }
}

// Styling
//// Main settings for the theme
#let _base(body) = {
  //// Font and spacing
  set text(font: "Arial", size: 12pt)
  set par(leading: 1em, spacing: 2em)
  set list(tight: false)
  set enum(tight: false)
  show list: set par(leading: 0.8em, spacing: 0.8em)
  show enum: set par(leading: 0.8em, spacing: 0.8em)

  // Subheadings
  show heading.where(level: 2): set text(16pt)
  show heading.where(level: 3): set text(12pt)
  show heading: set block(above: 2em)

  // Math Styling
  set math.mat(delim: "[")
  show math.equation: set text(font: "STIX Two Math", size: 13.4pt)
  // Clamp inline math's line-height contribution to Arial's cap-height
  // (8.26pt = 12pt × 0.688) so inline math doesn't push baselines apart.
  show math.equation.where(block: false): set text(top-edge: 8.26pt, bottom-edge: 0pt)
  // Group digits of plain numbers typed in equations, e.g. 23948.2390483
  // renders as 23 948.239 048 3 (thin-space separated, via `zero`).
  show math.equation: it => {
    show regex("^[0-9]+(\.[0-9]+)?$"): m => num(m.text)
    it
  }

  body
}

// Table of contents
//// The table of contents is displayed on the front page of assessments. It can be called manually by typing `#contents()`, or `#contents(title: [Table of contents])`.
#let contents(title: [Contents]) = {
  text(size: 15pt, [*#title* #h(1fr)])
  text(size: 12pt, [pages])

  context {
    let headings = query(heading.where(level: 1))
    let total_pages = counter(page).final().at(0)
    let all_marks = marks-state.final()
    let q_markers = query(<question_marker>)
    set par(spacing: 0.65em)
    for i in range(headings.len()) {
      let it = headings.at(i)
      let start_loc = it.location()
      let next_h = if i + 1 < headings.len() { headings.at(i + 1) } else { none }

      let section_questions = q_markers.filter(m => {
        let m_loc = m.location()
        let is_after = (m_loc.page() > start_loc.page()) or (m_loc.page() == start_loc.page() and m_loc.position().y > start_loc.position().y)
        let is_before = if next_h == none { true } else {
          let n_loc = next_h.location()
          (m_loc.page() < n_loc.page()) or (m_loc.page() == n_loc.page() and m_loc.position().y < n_loc.position().y)
        }
        is_after and is_before
      })
      let sq_keys = section_questions.map(m => {
        let sec = s-counter.at(m.location()).at(0)
        let qn = q-counter.at(m.location()).at(0)
        (sec, qn)
      })
      let q_count = sq_keys.len()
      let m_total = all_marks.filter(m => sq_keys.contains((m.at(0), m.at(1)))).map(m => m.at(2)).sum(default: 0)

      let q_label = if q_count == 1 { "question" } else { "questions" }
      let m_label = _marks-label(m_total)
      let stats = if q_count == 0 { [] } else if hide-marks-state.final() {
        [ (#q_count #q_label)]
      } else {
        [ (#q_count #q_label, #m_total #m_label)]
      }

      let start_page = start_loc.page()
      let end_page = if next_h != none { next_h.location().page() - 1 } else { total_pages }
      let final_end = calc.max(start_page, end_page)
      let page_range = if start_page == final_end { [#start_page] } else { [#start_page–#final_end] }

      let full_text = ""
      if it.body.has("children") {
        full_text = it.body.children.map(c => if c.has("text") { c.text } else if type(c) == str { c } else { "" }).join()
      } else if it.body.has("text") {
        full_text = it.body.text
      }
      let display_title = full_text.split("-").at(0).trim()

      grid(
        columns: (auto, 1fr, auto),
        column-gutter: 4pt,
        align: bottom,
        [#strong(display_title)#text(weight: "regular", stats)],
        box(width: 100%, stroke: (bottom: 0.4pt), inset: (bottom: 3pt)),
        page_range
      )
      v(4pt)
    }
  }
}

// Cover page
//// These variables can be set at the start of a document to be printed on the Cover page. In worksheet mode, where no cover page is present, they can be called manually too.
#let _subject-state = state("cover-subject", [Subject Name])
#let _title-state = state("cover-title", [Assessment Title])
#let _reading-state = state("cover-reading", [5 minutes])
#let _writing-state = state("cover-writing", [55 minutes])
#let _approved-state = state("cover-approved", [- Approved Materials])
#let _supplied-state = state("cover-supplied", [- Formula sheet])
#let _declaration-state = state("cover-declaration", [I understand Albert Park College's Assessment Policy and #underline[confirm that the work presented within this assessment is my own]. I understand that any breach of these rules is a serious offence and may result in a loss of marks or a Not Assessed being awarded for this topic.])

//// Settings for the cover page elements

////// Logo, name line, teacher name line
#let header(logo: "/assets/image-42.png") = {
  grid(
    columns: (auto, 1fr),
    column-gutter: 2em,
    align: horizon,
    image(logo, width: 40mm),
    [
      Full name:
      #v(-0.8em)
      #line(length: 100%, stroke: 0.5pt)
      #v(1.2em)
      Teacher:
      #v(-0.8em)
      #line(length: 100%, stroke: 0.5pt)
    ]
  )
}

//// Subject, title
#let title-block(subject: none, title: none) = context {
  let subject = if subject != none { subject } else { _subject-state.get() }
  let title = if title != none { title } else { _title-state.get() }
  text(size: 30pt, [#subject \ #title])
  linebreak()
  line(length: 100%, stroke: 1.5pt)
}

//// Reading and writing time specifications
#let exam-times(reading: none, writing: none) = context {
  let reading = if reading != none { reading } else { _reading-state.get() }
  let writing = if writing != none { writing } else { _writing-state.get() }
  text([- Reading time is *#reading* \
  - Writing time is *#writing*])
}

//// Approved materials list.
#let approved-materials(materials: none) = context {
  let materials = if materials != none { materials } else { _approved-state.get() }
  text(size: 15pt, [*Approved materials*])
  text([\ #materials])
}

//// Materials supplied list.
#let materials-supplied(materials: none) = context {
  let materials = if materials != none { materials } else { _supplied-state.get() }
  text(size: 15pt, [*Materials supplied*])
  text([\ #materials])
}

//// Student declaration box, with a signature/date line.
#let declaration-box(body: none) = context {
  let body = if body != none { body } else { _declaration-state.get() }
  rect(width: 100%, stroke: 0.75pt, inset: 10pt)[
    *Student Declaration:* \
    #body
    #v(0.8em)
    #grid(
      columns: (auto, 2fr, auto, 1fr),
      column-gutter: 8pt,
      align: bottom,
      [Student Signature:], box(width: 100%, line(length: 100%, stroke: 0.5pt)),
      [Date:], box(width: 100%, line(length: 100%, stroke: 0.5pt)),
    )
  ]
}

// Worksheet template
//// When `#show: worksheet` is written at the top, the document displays in worksheet mode. This hides the cover page, although the individual elements of the cover page can be called with their own functions.
//// If `#show: worksheet.with(hide-marks: true)` is written at the top, worksheet mode is activated, and marks are hidden next to each question. You can still specify the marks for each question in case you want to change back to assessment mode later, or if you want to copy and paste a question from a worksheet into an assessment.

#let worksheet(
  subject: none,
  title: none,
  reading: none,
  writing: none,
  approved: none,
  supplied: none,
  declaration: none,
  hide-marks: false,
  maths: false,
  body,
) = {
  set page(margin: 1.5cm)
  if hide-marks { hide-marks-state.update(true) }
  if maths { maths-state.update(true) }
  if subject != none { _subject-state.update(subject) }
  if title != none { _title-state.update(title) }
  if reading != none { _reading-state.update(reading) }
  if writing != none { _writing-state.update(writing) }
  if approved != none { _approved-state.update(approved) }
  if supplied != none { _supplied-state.update(supplied) }
  if declaration != none { _declaration-state.update(declaration) }
  // Reset question counter on level 1 headings (so L1 can be used as a title)
  show heading.where(level: 1): it => {
    q-counter.update(0)
    s-counter.step()
    it
  }
  // Reset question counter on level 2 headings (section breaks)
  show heading.where(level: 2): it => {
    q-counter.update(0)
    s-counter.step()
    it
  }
  _base(body)
}

// Assessment template
//// When `#show: theme.with(subject: ..., title: ..., ...)` is written at the top, the document renders as an assessment with a cover page. The cover page is designed to be similar to a VCE exam cover page.
#let theme(
  subject: [Subject Name],
  title: [Assessment Title],
  reading: [5 minutes],
  writing: [55 minutes],
  approved: [- Approved Materials],
  supplied: [- Formula sheet],
  declaration: [I understand Albert Park College's Assessment Policy and #underline[confirm that the work presented within this assessment is my own]. I understand that any breach of these rules is a serious offence and may result in a loss of marks or a Not Assessed being awarded for this topic.],
  hide-marks: false,
  maths: false,
  cover-margin: (x:auto,y:2cm),
  margin: auto,
  body
) = {
  if hide-marks { hide-marks-state.update(true) }
  if maths { maths-state.update(true) }
  _subject-state.update(subject)
  _title-state.update(title)
  _reading-state.update(reading)
  _writing-state.update(writing)
  _approved-state.update(approved)
  _supplied-state.update(supplied)
  _declaration-state.update(declaration)

  // Header
  set page(
    header: context {
      let current-page = here().page()
      if current-page > 1 {
        set text(12pt)
        grid(
          columns: (auto, auto),
          column-gutter: 1fr,
          align(left)[#title],
          align(right)[Page #counter(page).display() of #counter(page).final().at(0)]
        )
        v(-0.5em)
        line(length: 100%, stroke: 0.5pt)
      }
    }
  )

  // Sections
  show heading.where(level: 1): it => {
    q-counter.update(0)
    s-counter.step()
    let full-text = ""
    if it.body.has("children") {
      for child in it.body.children {
        if child.has("text") {
          full-text += child.text
        } else if type(child) == str {
          full-text += child
        } else {
          full-text += " "
        }
      }
    } else if it.body.has("text") {
      full-text = it.body.text
    }
    if full-text.contains("-") {
      let parts = full-text.split("-")
      let first = parts.at(0)
      let rest = parts.slice(1).join("-")

      block(width: 100%)[
        #set text(weight: "regular")
        #strong(first)-#rest
      ]
    } else {
      it
    }
  }

  _base[
    // Front cover
    #set page(margin: cover-margin)
    #block(width: 100%)[
      #header()
      #v(0em)

      #title-block()

      #exam-times()

      #approved-materials()

      #materials-supplied()

      #text([Students are *not* permitted to bring blank sheets of paper, whiteout, mobile phones and/or any unauthorised electronic devices into the examination room.])
      #line(length: 100%)

      #v(1em)
      #contents()

      #v(1fr)
      #declaration-box()
    ]
    #set page(margin: margin)
    #pagebreak()
    #body
  ]
}



// Page elements
//// Response lines
#let ln(count) = {
  for i in range(count) {
    v(0.8cm)
    line(length: 100%, stroke: 0.5pt)
  }
}

//// Name line (for use in worksheets where there is no cover page)
#let nameline() = {
  [Name:]
  v(-1em)
  line(length: 100%, stroke: 0.5pt)
  v(-2em)
}

//// Questions
////// `#q()` starts a new question. You can then type the question stem and add subquestions. If it is a one-part question, text can be embedded in the function itself, like `#q([Question text], X, Y) where X = number of lines, Y = number of marks.
#let q(..args) = {
  let pos = args.pos()

  if pos.len() == 0 {
    q-counter.step()
    counter("subquestion").update(1)
    [#metadata("question-marker") <question_marker>]
    context {
      let sec-num = s-counter.get().at(0)
      let q-num = q-counter.get().at(0)
      let total = marks-state.final().filter(m => m.at(0) == sec-num and m.at(1) == q-num).map(m => m.at(2)).sum(default: 0)
      text(weight: "bold")[Question #q-num]
      if total > 0 and not hide-marks-state.final() [ (#total #_marks-label(total))]
    }
  } else {
    let body-text = pos.at(0)
    let lines = pos.at(1)
    let marks = pos.at(2)

    q-counter.step()
    counter("subquestion").update(1)
    [#metadata("question-marker") <question_marker>]

    context {
      let sec-num = s-counter.get().at(0)
      let q-num = q-counter.get().at(0)
      marks-state.update(curr => {
        curr.push((sec-num, q-num, marks))
        curr
      })
    }

    block(breakable: false)[
      #context {
        let sec-num = s-counter.get().at(0)
        let q-num = q-counter.get().at(0)
        let total = marks-state.final().filter(m => m.at(0) == sec-num and m.at(1) == q-num).map(m => m.at(2)).sum(default: 0)

        if total > 0 and not hide-marks-state.final() {
          grid(
            columns: (1fr, auto),
            column-gutter: 10pt,
            [#text(weight: "bold")[Question #q-num] (#total #_marks-label(total)) \ #_qtext(body-text)],
            []
          )
        } else {
          [#text(weight: "bold")[Question #q-num] \ #_qtext(body-text)]
        }
      }
      #ln(lines)
    ]
  }
}

//// Multiple-choice questions
////// Enter MCQs in the format: #mcq([Question text], [Answer A], [Answer B]...)
////// MCQs are always worth 1 mark. Up to 5 options are supported (but note that all VCE exams use 4 options).
#let mcq(body-text, ..options) = {
  q-counter.step()
  [#metadata("question-marker") <question_marker>]

  context {
    let sec_num = s-counter.get().at(0)
    let q_num = q-counter.get().at(0)
    marks-state.update(curr => {
      curr.push((sec_num, q_num, 1))
      curr
    })
  }

  block(breakable: false)[
    #context {
      let q_num = q-counter.get().at(0)
      text(weight: "bold")[Question #q_num]
    }
    #linebreak()
    #_qtext(body-text)
    #v(-0.4em)
    #let labels = ("A.", "B.", "C.", "D.", "E.")
    #let tall-funcs = (math.frac, math.root, math.mat, math.vec, math.cases, math.binom)
    #let has-tall(c) = {
      if type(c) != content { return false }
      if tall-funcs.contains(c.func()) { return true }
      for (_, v) in c.fields() {
        if type(v) == content and has-tall(v) { return true }
        if type(v) == array {
          for item in v {
            if type(item) == content and has-tall(item) { return true }
            if type(item) == array {
              for sub in item {
                if type(sub) == content and has-tall(sub) { return true }
              }
            }
          }
        }
      }
      return false
    }
    #let tall = options.pos().any(opt => has-tall(opt))
    #let gutter = if tall { 0.6em } else { 0.15em }
    #let inset-y = if tall { 0.8em } else { 0.35em }
    #let grid-mode = options.named().at("grid", default: false)
    #if grid-mode {
      std.grid(
        columns: (auto, 1fr, auto, 1fr),
        column-gutter: (10pt, 24pt, 10pt),
        row-gutter: gutter,
        inset: (y: inset-y),
        align: top + left,
        ..for (i, opt) in options.pos().enumerate() {
          if i < 4 {
            ([*#labels.at(i)*], _qtext(opt))
          }
        }
      )
    } else {
      std.grid(
        columns: (auto, 1fr),
        column-gutter: 10pt,
        row-gutter: gutter,
        inset: (y: inset-y),
        align: top + left,
        ..for (i, opt) in options.pos().enumerate() {
          if i < 5 {
            ([*#labels.at(i)*], _qtext(opt))
          }
        }
      )
    }
  ]
}

//// Subquestions
////// For a question with multiple parts. Usage, where X = number of lines and Y = number of marks
////// #q()
////// Question stem text
////// #s([Subquestion A text], X, Y)
#let s(body-text, lines, marks) = {
  context {
    let sec-num = s-counter.get().at(0)
    let q-num = q-counter.get().at(0)
    marks-state.update(curr => {
      curr.push((sec-num, q-num, marks))
      curr
    })
  }

  block(breakable: false)[
    #context {
      if marks > 0 and not hide-marks-state.final() {
        std.grid(
          columns: (auto, 1fr, auto),
          column-gutter: 10pt,
          [*#counter("subquestion").display("a.")*],
          [#_qtext(body-text)],
          [#marks #_marks-label(marks)],
          [], [#v(1em) #ln(lines)], []
        )
      } else {
        std.grid(
          columns: (auto, 1fr),
          column-gutter: 10pt,
          [*#counter("subquestion").display("a.")*],
          [#_qtext(body-text)],
          [], [#v(1em) #ln(lines)]
        )
      }
    }
  ]
  counter("subquestion").step()
}

// Coloured text
//// The following functions can be called to type coloured text. This is typically not used in VCE exams, but may be useful for diagrams, or text in questions where following the VCAA style is not important.
#let nc(x) = text(fill: black, [#x])
#let bl(x) = text(fill: rgb("#176799"), [#x])
#let rd(x) = text(fill: rgb("#d20f39"), [#x])
#let rs(x) = text(fill: rgb("#fe640b"), [#x])
#let yl(x) = text(fill: rgb("#df8e1d"), [#x])
#let gr(x) = text(fill: rgb("#40a02b"), [#x])
#let pp(x) = text(fill: rgb("#8839ef"), [#x])

// Maths diagrams
//// These functions 
#import "/Templates/maths.typ": build as _build-diagrams, labmat
#let _d = _build-diagrams()
#let mesh = _d.mesh
#let plane = _d.plane
#let numberline = _d.numberline
#let venn = _d.venn
#let frac-circle = _d.frac-circle
#let frac-rectangle = _d.frac-rectangle
#let gp = _d.gp
#let A = _d.A
#let B = _d.B