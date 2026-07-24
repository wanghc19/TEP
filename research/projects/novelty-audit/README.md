# Periodic line-defect waveguide literature and novelty audit

This directory contains a systematic, evidence-based audit of the current
draft `draft/draft.tex`.  The audit distinguishes established prior art,
straightforward extensions, partial overlap, unresolved questions, and topics
for which the search remains inconclusive.

## Scope

- Draft version audited: `draft/draft.tex`, modified 2026-07-20 21:04:36 +0800.
- Local reference corpus: every PDF in `ref/`.
- External search cutoff: 2026-07-20.
- Existing MATLAB code and the draft are read-only inputs to this audit.
- Evidence set: 25 distinct academic papers, plus one internal legacy report.
- Direct paper notes and comparison rows: 20 each.

## Outputs

- `progress.md`: resumable stage-by-stage status.
- `search_log.md`: queries, citation-chain routes, results, and exclusions.
- `local_reference_inventory.md`: all local PDFs and detailed relevance notes.
- `literature_matrix.csv`: structured comparison matrix.
- `r-claims.md`: claim-by-claim prior-art assessment of the draft.
- `papers/`: individual notes for directly relevant papers.
- `report/lit-review.tex`: Chinese review and novelty-audit report.
- `report/references.bib`: verified bibliography.
- `report/lit-review.pdf`: compiled and visually checked report.

The final report is a 19-page A4 PDF. It was compiled with XeLaTeX/Biber and
rendered page-by-page for visual QA. No MATLAB or Octave command was run.

## Principal conclusion

Most individual draft components have direct prior art. The strongest remaining
candidate is the particular high-order Müller interface BIE coupled to a
generalized stable Bloch Cauchy relation, provided a kernel-isomorphism/no-
spurious-root theorem and a convergence-certified contour eigensolver are added.
The report gives a conservative BIE--RtR fallback if that theory does not close.

## Evidence convention

An absence of a directly overlapping paper in this audit is not treated as
proof of priority.  Each conclusion records its evidence level and, when
necessary, uses the wording: “截至本次检索尚未发现直接重合工作，但现有证据不足以断言该方向为首次提出。”
