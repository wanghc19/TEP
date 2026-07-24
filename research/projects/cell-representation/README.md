# Conjecture 1: single-cell representation

This directory contains an isolated theoretical investigation of Conjecture 1
in `draft/draft.tex`: whether every quasiperiodic Helmholtz transmission field
in one cell can be written as a homogeneous-background Rayleigh field plus
interface layer potentials, and in what sense such a representation is unique.

## Files

- `problem.md`: exact source statement, context, and a precise list
  of ambiguities that must be resolved.
- `notation.md`: unified geometry, PDE, trace-space, and sign
  conventions (to be completed after source comparison).
- `r-literature.md`: verified bibliographic and theorem-level source log.
- `proof-log.md`: dated proof attempts, failure mechanisms, and decisions.
- `open-questions.md`: issues not settled by the final investigation.
- `report.tex`: self-contained final report.
- `report.pdf`: compiled and visually checked final report.
- `report-zh.tex`: complete Chinese translation of the final report, including
  local-source verification notes for Hiptmair--Moiola--Spence (2022) and
  Colton--Kress Theorem 3.41.
- `report-zh.pdf`: compiled and visually checked Chinese report.

## Current status

Complete as of 2026-07-14.  The exact conjecture was recovered from
`draft/draft.tex`, lines 583--622.  The investigation classifies the original
wording as incomplete, proves an unconditional direct Green representation,
and proves a corrected common-density theorem under explicit regularity and
non-Wood assumptions.  The mixed QP/free ansatz produces a standard full-plane
complementary transmission problem, not a periodic-cylinder spectral condition.

`report.pdf` was compiled with

```text
latexmk -xelatex -interaction=nonstopmode -halt-on-error report.tex
```

The final 15-page PDF was rendered page by page with Poppler and visually
checked for clipping, overlap, broken equations, table layout, references, and
page numbering.  No MATLAB, Octave, numerical benchmark, or source-code change
was made.  No file outside this directory was modified by this investigation.

The Chinese copy was compiled with

```text
latexmk -xelatex -interaction=nonstopmode -halt-on-error report-zh.tex
```

Its 15 pages were rendered with Ghostscript and visually checked.  The local
file `../../pdf/Hiptmair2022.pdf` was inspected to verify the distinction
between the physical solution operator and the swapped-parameter unphysical
solution operator.  The reports were subsequently corrected to use the radial
Sommerfeld condition for the full-plane complementary exterior field and to
state complementary well-posedness directly as unique solvability for every
jump pair `(F,G)`.  The local file `../../pdf/books/Colton1983 (CH3).pdf` was
then checked against Theorem 3.41, and Sections 7--8 were expanded to include
the complementary layer-potential formula, the four Green extinction
identities, the explicit density formulas, and the full existence/uniqueness
construction.
