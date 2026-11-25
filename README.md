# vicsheets

Create VCAA-style worksheets and assessments: automatic question numbering, mark tallying, and a cover page with a table of contents, without hand-building tables.

## Features

### Worksheets and assessments

- Automatic question numbering
- Automatic mark tallying
    - Marks for subquestions are tallied and displayed next to the top-level question number
- Mark allocation
    - The number of marks can easily be displayed next to each question, or turned off for the entire worksheet
- VCAA-consistent formatting
    - Fonts and styling designed to emulate a VCE exam, to get your students accustomed to the format

### Assessments

- Cover page
    - Similar to a VCE exam, with space for your school's branding and a student declaration box
- Table of contents
    - Automatically totals the number of marks in each section
    - Lists the pages each question starts on

## Quick start

### Worksheets

Start a worksheet with the following code:

```typst
#import "@preview/vicsheets:0.1.0": *
#show: worksheet.with(hide-marks: true) // Change this to false to show mark allocations
#nameline() // Adds a line at the top for students to write their name

= Title
```

### Assessments

Start an assessment with the following code:

```typst
#import "@preview/vicsheets:0.1.0": *
#show: theme.with(
  subject: [Subject name],
  title: [Assessment name],
  reading: [Reading time],
  writing: [Writing time],
  approved: [
    - List of
    - approved materials
  ],
  supplied: [
    - This test booklet
    - Multiple-Choice Answer Sheet // If applicable
  ],
  logo: image("my-logo.png"), // Your school/organisation's logo
  declaration: [I understand my school's assessment policy and confirm that the work presented within this assessment is my own.],
)
```

`logo` and `declaration` are required — this package doesn't ship a default logo or student declaration, since every school's is different.

### Sections

To start a standard (written-response) section, printing the standard written-response instructions:

```typst
#sec([Short answer questions])
```

To start a multiple-choice section, printing the standard MC instructions:

```typst
#sec-mcq([Multiple choice questions])
```

Both letter themselves automatically (Section A, Section B, ...) based on how many sections have come before them in the document.

To add your own instruction(s) underneath the standard ones, pass `extra`:

```typst
#sec([Short answer questions], extra: [
  - Round your answer to 2 decimal places where needed.
])
```

To start a section with fully custom instructions instead of the standard ones, use `#sec-cus`:

```typst
#sec-cus(
  [Bonus round],
  [- Good luck!],
)
```

Pass `instructions: []` (an empty custom instruction list) if you want a section with no instructions block at all.

## Writing questions

### Multiple choice questions

To write a multiple choice question, write:

```typst
#mcq(
  [Question text],
  [Option A],
  [Option B],
  [Option C],
  [Option D],
)
```

You can include up to 5 multiple choice options. Note that all VCE exams use only 4, so this is recommended.

### Single-part student-response questions

To write a single part question where students need to write their answer, write:

```typst
#q([Question text], X, Y)
```

Where `X` is the number of response lines (can be zero) and `Y` is the number of marks the question is worth.

### Multi-part student-response questions

If one question needs to include multiple parts (e.g. 1a, 1b, 1c...), start a new question by typing `#q()`, then start a subquestion using `#s(...)`. You can then add additional sub-parts. For example:

```typst
#q()

Consider a circle with a radius of $4"cm"$.

#s([Find the circle's area.], 2, 2)

#s([Find the circle's circumference.], 2, 2)
```
