# Progress log

## 2026-07-21 — Stage 0 complete: initialization

- Read the full 1,446-line task specification.
- Confirmed the roadmap directory did not previously exist.
- Created the requested directory skeleton and a pre-work checkpoint.
- Recorded source hashes and unrelated dirty-worktree entries.
- Selected a quotient-safe continuous kernel--field equivalence as the first
  hard theoretical milestone; Fredholm index zero remains a conditional
  strengthening, and full discrete spectral exactness is future work.

Resume point: freeze scope, notation, assumptions, and the exact statement of
the target spaces before writing any proof dependency.

## 2026-07-21 — Stage 1 complete: scope, notation, assumptions

- Froze the first-paper regime to real fixed-`beta`, strict-gap, non-Wood,
  smooth scalar TM problems with identical leads and separated multiplier
  clusters.
- Defined the global guided space in ordinary `H^1_beta`; exponential decay is
  a consequence to prove/cite, not part of the definition.
- Replaced unexplained continuous density spaces by
  `H^{1/2}(Gamma) x H^{-1/2}(Gamma)` and introduced weighted Rayleigh sequence
  spaces whose final weights remain an explicit proof obligation.
- Made the outgoing object a closed Cauchy relation; DtN is only its graph when
  the Dirichlet projection is invertible.
- Separated quotient-safe kernel equivalence, unquotiented injectivity,
  Fredholm index zero, and future spectral approximation into four theorem
  levels.
- Recorded auxiliary uniqueness, representation poles, Jordan-coordinate
  injectivity, and the Appendix A `k/nk` correction as named assumptions rather
  than hidden proof steps.

Resume point: build the theorem/reference correspondence and classify each
draft claim as retain, repair, downgrade, or remove.

## 2026-07-21 — Stage 2 complete: theorem/prior-art correspondence

- Added `draft_theorem_correspondence.md` and `reference_guide.md`.
- Demoted current draft Theorem 1 to a relation-valued restriction--gluing
  lemma because Fliss Theorem 4.5 already covers exact global/bounded
  equivalence and multiplicity.
- Split current draft Theorem 2 into field surjectivity, reconstruction-kernel
  characterization, and quotient-space isomorphism.
- Recorded the exterior `D^(k)`, not `D^(nk)`, correction without modifying
  the protected draft.
- Replaced ordinary-mode completeness by the Hohage--Soussi generalized
  Floquet/Jordan trace-basis route.

Resume point: number the complete proof chain and give every formal conclusion
an auditable proof obligation.

## 2026-07-21 — Stage 3 complete: proof chain and dependency graph

- Added `theorem_roadmap.md`, `proof_obligations.md`, and
  `theorem_dependency_graph.md`.
- Fixed the recommended Main Theorem K1 as
  `ker(A_rel)/N_rep ~= G(k,beta)`, with an unquotiented strengthening only on
  an injective regular subset.
- Specified 28 formal proof obligations: 15 continuous lemmas, 2 continuous
  propositions, 3 continuous theorems, 1 continuous corollary, 4 future
  lemmas, and 3 future theorems.
- Supplied ASCII, Mermaid, and LaTeX/TikZ dependency graphs and explained every
  arrow group.

Resume point: build the prerequisite path and focused theory notes.

## 2026-07-21 — Stage 4 complete: prerequisite learning route

- Added `prerequisite_map.md` with Modules A--H, reading depth, skip guidance,
  theorem links, references, gate questions, and priorities.
- Added seven requested notes covering spaces, gluing, layers, outgoing
  relations, translation/Jordan structure, Fredholm structure, and future
  spectral approximation.
- Recommended A (Sobolev/trace), B (weak transmission/gluing), and E
  (Floquet--Bloch/Riesz traces) as the first three modules.

Resume point: make failure routes explicit before drafting the report.

## 2026-07-21 — Stage 5 complete: risks, fallback packages, open questions

- Added `risk_register.md`, `fallback_results.md`, and `open_questions.md`.
- Registered all ten required risks plus model-corruption, edge, and analytic
  branch risks, each with trigger, detection, impact, downgrade, stop, and
  pivot fields.
- Recommended Package B as the committed result, Package A as a stretch, and
  Package C as the conservative publishable exit.
- Identified L10, L13, and L15/T2 as the three principal bottlenecks; T2 is the
  theorem most likely to fail.

Resume point: write planning-only numerical interfaces and the final report.

## 2026-07-21 — Stage 6 complete: numerical placeholders

- Added `numerical_todo_placeholder.md` with six experiment groups and their
  exact theorem/risk links.
- Specified a six-component physical certificate and separated boundary,
  Rayleigh, stable-subspace, and nonlinear-root error budgets.
- No numerical experiment, MATLAB command, Octave command, or solver
  implementation was run.

Resume point: compile and visually inspect the Chinese report.

## 2026-07-21 — Stage 7 complete: report and final validation

- Added `report/theory_roadmap.tex`, `report/references.bib`, and the compiled
  `report/theory_roadmap.pdf`.
- Report contains 18 main sections, a formal K1 statement, 16 resolved
  bibliography entries, and a TikZ dependency diagram.
- Built with `latexmk -xelatex -interaction=nonstopmode -halt-on-error
  theory_roadmap.tex`; Biber and repeated XeLaTeX passes completed.
- Verified no unresolved citation, empty bibliography, or LaTeX error.
- Rendered all 10 A4 pages at 150 dpi and visually inspected every page twice;
  a first-pass page-break orphan was corrected and the latest rendering has no
  visible clipping, overlap, missing glyph, or broken diagram/table.
- Remaining log notices are nonmaterial: Songti SC supplies no italic shape,
  and one overfull box is 0.11633 pt.
- Rechecked protected hashes: current draft, appendix, and prior literature
  report are byte-identical to the pre-roadmap checkpoint.

Final status: complete. Future work starts with L1, L3, and L6, then the
Hohage--Soussi hypothesis audit, L9 field surjectivity, and L10/L13.
