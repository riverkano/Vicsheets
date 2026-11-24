# Vic Assessments
This template lets you easily create worksheets and assessments that look similar to VCE exams created by VCAA. Forget about messing around with tables to get the alignment right - this template creates professional learning materials without having to worry about spacing, question numbering, and counting marks.
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
`
#import "/Templates/assessment.typ": *
#show: worksheet.with(hide-marks: true)     // Change this to false to show mark allocations
#nameline()                                 // Adds a line at the top for students to write their name

= Title
`

### Assessments
Start an assessment with the following code:
``
#import "/Templates/assessment.typ": *
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
)
``

#### Sections

To start a multiple choice section, type:
`#sec-mcq`

To start a standard section, type:
`#sec`

To add additional instructions, type:
``
#sec([
    - Additional instruction
    - Additional instruction
])
``

To start a custom section, type:
``
#sec-cus(
    [Section name],
    [- Instruction
    - Instruction
    - Instruction]
)
``

## Writing questions
### Multiple choice questions
To write a multiple choice question, write:
``
#mcq(
    [Question text],
    [Option A],
    [Option B],
    [Option C],
    [Option D]
)
``
You can include up to 5 multiple choice options. Note that all VCE exams use only 4, so this is recommended.

### Single-part student-response questions
To write a single part question where students need to write their answer, write:
``
#q([Question text], X, Y)
``
Where `X` is the number of response lines (can be zero) and `Y` is the number of marks the question is worth.

### Multi-part student-response questions
If one question needs to include multiple parts (e.g. 1a, 1b, 1c...), start a new question by typing `#q()`, then start a subquestion using `#s(...)`. You can then add additional sub-parts. For example:

``
#q()

Consider a circle with a radius of $4"cm"$.

#s([Find the circle's area.],2,2)

#s([Find the circle's circumference.],2,2)
``

