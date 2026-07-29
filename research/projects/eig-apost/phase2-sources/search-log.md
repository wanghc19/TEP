# Phase 2 search log

## 2026-07-26 — Search initialization

- RQ source: `phase1-scope/rq-summary.md`。
- Method source: `phase1-scope/p-method.md`。
- Local seed PDFs: Joly (2006), Fliss (2013), Coatléven (2012)。
- External search not yet executed at file creation time.
- Screening counts: identified `0`; screened `0`; included `0`; excluded `0`。

## 2026-07-26 — DtN definition and Riccati chain

- **Local originals:** `Fliss2013.pdf`, `Joly2006.pdf`, `Coatleven2012.pdf`。
- **Action:** text extraction followed by visual inspection of the exact pages containing the
  definition, Riccati equation, DtN recovery formula and numerical discretization.
- **Included:** Fliss (2013), Joly--Li--Fliss (2006), Coatléven (2012).
- **Finding recorded, not synthesized here:** all three define the half-guide map through a
  half-guide boundary-value problem; propagation/Riccati is the construction. All three reported
  implementations use FEM variants.

## 2026-07-26 — BIE and DtN search

- Queries included `"Dirichlet-to-Neumann" "boundary integral" Helmholtz`,
  `"Steklov-Poincare" boundary element Helmholtz`, `periodic waveguide boundary integral
  Dirichlet-to-Neumann`, and `unit cells DtN map boundary integral periodic waveguide`.
- **Included after primary-source check:** Yuan--Lu--Antoine (2008), Huang--Lu--Li (2007),
  Yuan--Lu (2007), Lu--Lu (2014), Petropoulos--Turc (2025).
- **Background only:** symmetric Calderón transmission formulations; BIE-NtD grating papers;
  generic exterior circular DtN truncation papers.
- **Excluded from the core chain:** inverse-problem DtN papers, neural-operator DtN papers,
  time-domain DtN, unrelated homogeneous exterior-circle DtN, and sources without enough
  primary text to determine the construction.

## 2026-07-26 — Recent alternatives

- Located Lu--Shen--Zhang (2026), DOI `10.1016/j.jcp.2026.114850`, which builds a BIE transparent
  boundary condition from the background periodic Green function via Floquet--Bloch transform.
- Retained as an alternative infinity treatment, not treated as a half-guide DtN source.
- Located Petropoulos--Turc (2025), DOI `10.1098/rsta.2024.0355`, as the closest BIE unit-cell map
  plus half-infinite Riccati implementation.

## Screening count after first pass

- Identified records: `31`.
- Title/abstract screened: `31`.
- Primary/full-text checked: `11`.
- Included in core or near-neighbor evidence cards: `8`.
- Retained as alternative/background: `3`.
- Excluded from current scope: `20`.

## 2026-07-26 — Nonlinear eigenvalue perturbation and DtN truncation

- Queries covered nonlinear-eigenvalue condition numbers, backward error, simple-root operator
  perturbation, holomorphic Fredholm approximation, two-level/hierarchical estimators and
  periodic-waveguide DtN truncation.
- **Included after primary-source check:** Güttel--Tisseur (2017), Moskow (2015),
  Bindel--Hood (2013), Zhang (2023).
- Güttel--Tisseur gives the finite-dimensional left/right-vector first-order formula and the
  backward-error/forward-sensitivity distinction.
- Moskow gives an operator-level nonlinear eigenvalue correction with a product-order remainder,
  but its compactness hypotheses are not yet verified for the target formulation.
- Bindel--Hood is retained for root localization/counting rather than as the sharp estimator.
- Zhang proves exponential convergence for a spectral-decomposition DtN truncation in a forced
  waveguide problem; it is a tail-model precedent, not the target eigenvalue theorem.
- Generic two-level estimator literature was retained only as a warning that a difference of
  consecutive levels estimates the remaining error only under a saturation/tail assumption.

## 2026-07-26 — Full-text storage audit after AGENTS.md update

- Re-read repository-root `AGENTS.md` and `research/AGENTS.md`.
- Moved the previously downloaded Yuan--Lu--Antoine full text from `research/tmp/pdfs/` to the
  required durable location `ref/ref_data/Yuan2008.pdf`; identity rechecked from the title page.
- Downloaded and identity-checked the currently needed lawful public full texts at
  `ref/ref_data/Guettel2017.pdf`, `ref/ref_data/Moskow2015.pdf`, `ref/ref_data/Zhang2023.pdf`, `ref/ref_data/Bindel2013.pdf`,
  `ref/ref_data/Huang2007.pdf`, `ref/ref_data/Yuan2007.pdf`, `ref/ref_data/Lu2014.pdf` and `ref/ref_data/Lu2026.pdf`.
- Rendered page images remain disposable inspection artifacts under `research/tmp/`.

## 2026-07-26 — Finite-tail boundary-map hierarchy

- Citation chasing from recursive doubling located Ehrhardt--Sun--Zheng (2009), DOI
  `10.4310/CMS.2009.v7.n2.a4`.
- The needed lawful author full text was saved as `ref/ref_data/Ehrhardt2009.pdf`; title, page count and
  the finite-tail/doubling pages were visually checked.
- Included because it gives the cleanest hierarchy for the user's priority error source:
  hold the cell discretization fixed, use $N=2^j$ cells with zero incoming data at the remote
  port, and let the finite-tail StS/RtR map converge to the half-guide map in a stop band.

## Cumulative screening count after second pass

- Deduplicated records identified and screened: `40`.
- Primary/full-text checked: `16`.
- Included in core or near-neighbor evidence cards: `13`.
- Retained as alternative/background: `4`.
- Excluded from current scope: `23`.

## 2026-07-26 — Structure-preserving truncation follow-up

- Phase 3 root audit separated a real-axis singular-value minimum from an actual NEP zero and
  questioned zero-incoming finite tails as the primary real-eigenvalue hierarchy.
- Located Soussi (2005/2006), DOI `10.1137/040616875`. The official SIAM abstract reports
  exponential supercell convergence of photonic-crystal defect frequencies, so it is retained
  as an adjacent precedent only. No lawful public full text was found; no local PDF was created
  and no theorem details were inferred from the abstract.
- Rechecked Petropoulos--Turc (2025). The Royal Society PDF endpoint returned an HTML access
  page rather than a PDF; the invalid placeholder was deleted. OpenAlex and the NJIT record show
  no open repository full text. The official abstract still supports the BIE unit-cell RtR plus
  Riccati architecture, but detailed numerical claims are secondary until a lawful full text is
  obtained.
- This follow-up obeys `research/AGENTS.md`: only verified full texts are stored under `ref/ref_data/`, and
  failed/closed-access responses are not retained with a `.pdf` suffix.
