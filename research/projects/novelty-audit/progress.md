# Progress log

## 2026-07-20 — Stage 1 complete: scope and current draft

### Completed

- Read the complete task specification and inspected the repository without
  modifying existing draft, MATLAB, package, or reference files.
- Selected `draft/draft.tex` and `draft/draft.pdf` as the current version. The
  TeX file was modified at 2026-07-20 21:04:36 +0800 and the PDF at 21:04:38,
  later than the `pre/` candidates. Content also matches every construction
  named in the task.
- Read the model, guided-mode definition, bounded reduction, outgoing trace
  spaces, Theorems 1--2, DtN and absorbing remarks, Rayleigh sections,
  Conjectures 1--2, MFS, Müller block, cell scattering/Bloch pencil, all current
  numerics, and `draft/appendixA.tex`.

### Current judgment at this checkpoint

The draft contains a coherent assembly, but its first equivalence is largely a
restriction/gluing lemma, its second theorem needs close prior-art and proof
checking, modal completeness must include generalized modes, and the general
line-defect numerical subsection is empty.

### Resume point recorded at the time

Inventory all local PDFs and read Joly, Fliss, Coatléven, Barnett--Greengard,
Luan, and Linton first.

## 2026-07-20 — Stage 2 complete: all local references

### Completed

- Inventoried and text-extracted all 13 PDFs under `ref/`.
- Read every local academic paper at introduction/problem/results/numerics/
  conclusion level; inspected theorem, remark, and appendix details in the
  directly relevant papers.
- Populated `local_reference_inventory.md` with metadata, geometry, PDE,
  polarization, problem class, exterior treatment, discretization, theorem
  locations, relation to the draft, and missing content.

### Local papers read

Arens (2006); Barnett--Greengard (2010); Coatléven (2012); Domínguez--Lyon--
Turc (2016); Fliss (2013); Hao et al. (2014); Hiptmair--Moiola--Spence (2022);
Hohage--Soussi (2013); Joly--Li--Fliss (2006); Kress (1991); Linton (1998);
Luan--Sun--Zhuang (2019). `report_legacy.pdf` was read as an internal project
artifact and is not counted as external prior art.

### Current judgment at this checkpoint

- Fliss Theorem 4.5 already proves the exact global-to-bounded line-defect DtN
  equivalence.
- Barnett--Greengard supplies the closest representation/nullspace theorem and
  the exact swapped-wavenumber proof architecture used by draft Theorem 2.
- Hohage--Soussi proves a generalized Floquet/Jordan Riesz basis and directly
  resolves the completeness issue left open by Joly et al.
- The MFS and QP Green-function ingredients are method prior art rather than a
  standalone contribution.

### Resume point recorded at the time

Run the required A--G query families and backward/forward citation chains, with
special focus on RtR, unit-cell BIE--DtN, generalized-mode DtN, TE line defects,
band edges, and contour NEPs.

## 2026-07-20 — Stage 3 complete: systematic web search and citation chaining

### Completed

- Executed and logged all required A--G query families plus supplemental
  neighbor/proxy/MFS queries in `search_log.md`.
- Performed backward chaining from Joly--Li--Fliss, Fliss, Barnett--Greengard,
  Yuan--Lu--Antoine, and Brown et al.
- Performed forward chaining from Joly--Li--Fliss, Fliss, Barnett--Greengard,
  Hohage--Soussi, the RtR paper, and unit-cell BIE--DtN work.
- Verified external bibliographic metadata against SIAM, Springer, Elsevier,
  Wiley, DOI, author, or arXiv records. Search snippets were discovery aids only.

### Principal external papers added

Ammari--Santosa (2004); Soussi (2005); Yuan--Lu--Antoine (2008);
Klindworth--Schmidt--Fliss (2014); Fliss--Klindworth--Schmidt (2015);
Cho--Barnett (2015); Brown et al. (2017); Dohnal--Schweizer (2018); Zhang
(2021, 2023); Binkowski--Zschiedrich--Burger (2020); Brennan--Embree--Gugercin
(2023); Lyu--Li--Lin (2025).

### Searches and exclusions

Bulk band-structure, forced scattering, point defect, fiber/slab, and closed
waveguide papers were retained only when they supply a method component; they
were not misclassified as direct solutions of the line-defect eigenproblem.
Complex resonance and Wood-threshold intersections remain insufficiently
searched for a priority claim.

### Current judgment at this checkpoint

- RtR already removes the practical classical-DtN forbidden-frequency issue.
- Zhang (2023) already proves exponential generalized-modal DtN truncation and
  a full FEM error estimate.
- Neighbor/proxy/Rayleigh periodization and smallest-singular-value scanning
  are established.
- No verified paper was found that supplies the exact same high-order Müller
  central-cell BIE plus generalized stable Bloch Cauchy relation with a
  spurious-free kernel theorem. This is a qualified search finding, not proof
  of priority.

### Resume point recorded at the time

Complete individual notes, matrix, claim audit, innovation directions, and
formal report.

## 2026-07-20 — Stage 4 complete: evidence synthesis and novelty audit

### Completed

- Created 20 independent paper notes in `papers/` using the required template.
- Populated the 31-column `literature_matrix.csv` with 20 directly relevant
  works.
- Completed all 14 draft claims in `claim_audit.md` with closest work, exact
  overlap, differences, analytical/numerical obstacles, proved/unproved scope,
  evidence, status, and risk.
- Developed six evidence-based innovation directions and ranked them by
  novelty, feasibility, cost, theoretical/numerical risk, code compatibility,
  and suitability as the current paper's main line.

### Critical audit findings

1. `draft/appendixA.tex` line 243 uses `D_QP^(nk)[v^-]` in a pair that must use
   the (k)-wavenumber QP interior representation; the displayed cancellation
   is invalid as written.
2. Conjecture 1 omits generalized eigenfunctions/Jordan chains and is not a
   correct general completeness statement.
3. Theorem 1, absorbing DtN, Rayleigh expansion, scattering-to-Bloch pencil,
   and singular-value scanning are established or straightforward components.
4. The best remaining intersection is a certified, interface-only
   Müller--generalized-Cauchy relation, not any single component.

### Resume point recorded at the time

Compile the Chinese LaTeX report, resolve every citation, render all pages, and
inspect tables, directions, and bibliography visually.

## 2026-07-20 — Stage 5 complete: report, bibliography, and visual QA

### Completed

- Wrote the Chinese report `report/literature_review.tex` with all 16 requested
  thematic sections, readable comparison tables, six innovation directions,
  a priority table, a main route, a conservative backup, and stop/turn criteria.
- Created `report/references.bib` with 25 verified entries. Every cited item
  resolves; external entries include DOI/URL and local items are identified.
- Compiled `report/literature_review.pdf` with XeLaTeX/Biber. Final PDF is A4,
  19 pages, and has no unresolved citations or table overflow.
- Rendered all 19 pages to PNG, inspected four contact sheets and full-size key
  pages, found and fixed a missing-Chinese-glyph problem by using Songti SC and
  PingFang SC, then rerendered and rechecked the final document.

### Commands run and results

```text
latexmk -xelatex -interaction=nonstopmode -halt-on-error literature_review.tex
```

Result: success; XeLaTeX and Biber completed; 19-page PDF generated; no
unresolved citation. `pdftoppm -png -r 120` rendered every page successfully.
No MATLAB or Octave command was run because this task did not modify or validate
the numerical code.

### Final corpus counts

- Local PDFs inspected: 13 (12 external academic papers + 1 internal report).
- External papers newly added and verified: 13.
- Distinct academic-paper evidence set: 25.
- Direct paper notes: 20.
- Rows in the direct comparison matrix: 20.

### Final recommendation

Primary route: repair the representation proof, replace ordinary-mode
completeness with generalized stable invariant subspaces, prove a spurious-free
Müller--Cauchy-relation kernel result, and solve the resulting NEP by contour
projection plus physical residual certification. Conservative route: use the
already established RtR transparent condition, contribute a high-order
interface-only BIE implementation, three-way convergence study, contour mode
count, spurious-root filter, and near-band-edge benchmarks.

### Remaining questions (not incomplete deliverables)

- A truly exhaustive priority search for Wood/threshold/complex-resonance
  intersections would require a separate focused review.
- Exact theorem numbering in a few nonlocal paywalled papers should be checked
  from full texts before quoting those theorems verbatim in a future manuscript;
  the report deliberately cites only verified abstract/article-level claims.

### Task status and resume point

**Complete.** All requested outputs are under
`attempt/literature_novelty_audit/`. If research resumes, start with the
three stopping tests in report Section 18: repair Theorem 2, test physical
kernel reconstruction on a minimal circular-rod TM case, and compare the
relation condition number with RtR near a DtN pole.

## 2026-07-21 — Stage 6 complete: band-edge and resonance extension

### Preservation and scope

- Created `checkpoints/pre_extension_2026-07-21.md` before edits and
  `checkpoints/final_extension_2026-07-21.md` after validation.
- Preserved `report/literature_review.tex` and
  `report/literature_review.pdf` byte-for-byte.
- Preserved the old six innovation directions, their ranking, the main route,
  conservative backup, and stop/turn criteria.
- Appended 23 BibTeX records after the unchanged 25-entry baseline block; no
  old citation key or record was edited.

### Research outputs

- Distinguished 12 band-edge/threshold concepts and 13 resonance/QNM concepts.
- Performed the required band-edge, LAP, Bloch multiplier, numerical pathology,
  leaky resonance, BIE, periodic-lead, NEP, and BIC searches through 2026-07-21.
- Completed backward/forward chains from Fliss, periodic-waveguide LAP/DtN,
  channel-defect BIE, leaky PC waveguides, BIC perturbation, scattering poles,
  and contour NEPs.
- Created 23 theorem/section/equation-located notes under `papers_extended/`.
- Created a 20-column, 12-row band-edge matrix and a 21-column, 15-row resonance
  matrix.
- Completed module-by-module theory/code transition audit and unified-formulation
  prior-art audit.
- Added six new directions numbered 7--12, plus backup B, backup C, and a
  long-term route, without modifying the baseline ranking/routes.

### Principal judgments

1. Approaching a projected edge from inside a gap is a natural and high-reuse
   extension; an exact threshold is a separate high-risk theory problem.
2. Complex-frequency resonance retains the central BIE/geometry but requires a
   new branch-consistent periodic-lead radiation theory and analytic assembly.
3. `|lambda|<1`, `imag(gamma)>=0`, dynamic sorting, `pinv/lsqminnorm`, and SVD
   objectives cannot be used unchanged inside a holomorphic contour sampler.
4. Direct prior art exists for slab BIE bound/resonant unification, leaky
   photonic-crystal waveguides, BIE leaky fiber modes, scattering-matrix poles,
   and contour BEM NEPs. A broad “first unified method” claim is unsafe.
5. The unified guided/threshold/leaky topic should be a two-to-three-paper
   long-term program. The near-term extension should remain inside the gap;
   complex resonances are backup C after an analytic refactor.

### Report and QA

- Generated `report/literature_review_extended.tex` and the 30-page A4
  `report/literature_review_extended.pdf`.
- Ran `latexmk -xelatex -interaction=nonstopmode -halt-on-error
  literature_review_extended.tex`: success; Biber resolved all citations.
- Rendered all pages with `pdftoppm -png -r 110`, inspected three contact sheets
  and full-size key pages. No new overflow or visual defect was found.
- No MATLAB or Octave command was run; this extension made no numerical-code
  changes.

### Task status

**Complete.** The safest next action remains the original main route. If that
route stalls, activate backup B (inside-gap band-edge stability); activate
backup C only after the complex-parameter matrix path passes analyticity and
branch-continuation tests on a simple lead.
