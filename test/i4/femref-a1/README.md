# I4.1a fitted-FEM experiment

This directory contains the bounded diagnostic-ranking implementation frozen in
[[research/projects/eig-apost/implementation/i4/design-4-1a#36. 2026-08-31 run-007 diagnostic-ranking reference revision|design §36]]
and [[research/projects/eig-apost/implementation/i4/design-4-1a#37. 2026-08-31 §AX candidate-domain and lifecycle clarification|design §37]],
with the focused design gate in
[[research/projects/eig-apost/implementation/i4/review-4-1a#AY. Focused re-review of the §37 candidate-domain clarification|review §AY]].

Status: **POST-RUN PASS WITH CONDITIONS / `run-007/execution-001` CONSUMED**
under [[research/projects/eig-apost/implementation/i4/review-4-1a#BB. `run-007/execution-001` post-run artifact/resource/claim review|review §BB]].

Historical `run-001`--`run-006` artifacts and verdicts remain immutable.
Active MATLAB code does not read, stat, hash, copy, or reuse them.

## Fixed interface

- `run_i4_1a.m` accepts exactly `run_i4_1a('run-007')`.
- `run_formal.pl` is a fixed no-argument controller.
- The first create-once leaf is
  `output/run-007/execution-001/`.
- No `execution-002`, alternate run ID, diagnostic launcher, or retry path is
  implemented.
- The completed scientific execution is consumed; no retry is authorized.

The completed command was:

```sh
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/perl ./run_formal.pl
```

## Frozen numerical method

The continuous problem, fitted conforming $P_1$ weak form, sharp geometry,
material coefficient, quasiperiodic parameters, $\lambda=k^2$, nine meshes,
phase grids, eigensolver tolerances, residual tests, and mass normalization are
unchanged.

The finite schedule is:

- 72 bulk solves: 67 40-root main spectra plus five 48-root count spectra;
- 47 base defect solves, each requesting 48 roots;
- if the 48th-root ceilings on all 17 fine twists do not exceed the upper edge
  of $W_3=[0.45,3.25]$ by $0.10$, exactly 17 additional 60-root fine solves;
- 119 base solves and at most 136 solves.

The completed run used all 119 base solves successfully. All 17 fine 48-root
spectra covered $W_3$, so the conditional 60-root expansion was not entered.

The initial cue, former guard/gap tests, root-count agreement, localization,
parity, overlap, collapse, coverage, and refinement thresholds are diagnostics
only. They cannot stop the schedule, remove a numerically valid field-bearing
$W_3$ object, or suppress publication.

## Candidate and uncertainty contract

Every valid field-bearing cluster intersecting $W_3$ is retained whole,
including edge-straddling clusters. Deterministic maximum-total-overlap
one-to-one assignments provide continuation diagnostics; births, deaths,
dimension changes, weak overlap, and unmatched singletons remain rankable.

The ascending lexicographic rank is persistence, missing/finite refinement
drift, residual, localization, parity, spectrum coverage, then the frozen
configuration/twist/root/candidate ties. Missing raw quantities remain `NaN`;
the comparison projection never uses native `NaN` ordering. The selected
publication level follows design §37.2.

A winner publishes `lambda_ref_fem`, `k_ref_fem`, its mass-normalized
field or subspace, classifications, four observed-axis components, and
`delta_ref_obs`. Partial coverage, weak localization, ambiguity, embedded
location, or pre-asymptotic behavior remains READY-capable under
`EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY`.

`NO_VALID_FIELD_BEARING_W3_EIGENOBJECT` is allowed only after the complete
finite schedule has no valid field-bearing $W_3$ object. Genuine resource,
operational, numerical-object, or canonical-publication failures remain
fail-closed; no former heuristic terminal is active.

## Completed empirical candidate

The collection contained 16 candidates. Candidate 7 ranked first, with the
`fine` / `defect-N5-s24-g48` anchor at $\theta=0$, root 11, and multiplicity
one. Its published values are

$$
\lambda_{\mathrm{ref}}^{\mathrm{FEM}}=3.3697211020626927,
\qquad
k_{\mathrm{ref}}^{\mathrm{FEM}}=1.8356800108032698,
$$

with eigenvalue envelope
$[3.3697100442273502,3.3697321598980357]$ and wavenumber envelope
$[1.8356769988827963,1.8356830227188015]$. The four observed changes are

$$
\delta_{\mathrm{FEM}}^{\mathrm{obs}}=0.0019799758723477723,
\quad
\delta_{\mathrm{supercell}}^{\mathrm{obs}}
=3.3059115711608911\times10^{-5},
$$

$$
\delta_{\mathrm{twist}}^{\mathrm{obs}}
=3.0119180025600656\times10^{-6},
\quad
\delta_{\mathrm{alg}}^{\mathrm{obs}}=0,
\quad
\Delta_{\mathrm{ref}}^{\mathrm{obs}}=0.0020160469060619413.
$$

The classifications are `cue-member`, `gap-edge-or-safe-buffer`,
`weakly-localized`, `stable-parity-assignment`,
`empirical-resolution-complete`, and `spectrum-covered-through-W3`. The bulk
gap remains unresolved and the observed resolution is not certified or shown
asymptotic. The result is only
`EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY`: it is not an error bound,
existence proof, or effectivity validation.

## Minimal artifacts and budget

Each execution leaf owns one `scientific-result.mat`, conditional
`fields.mat`, short `run.log`, `resource.tsv`, and summary-last
`run-summary.csv`; `work/` contains only current-execution caches and the
terminal draft. No audit mirror, checkpoint/history system, forecast, or
performance gate is present.

The only inclusive resource uppers are

$$
T_{\mathrm{hard}}=2700\ \mathrm{s},
\qquad
R_{\mathrm{hard}}=2147483648\ \mathrm{bytes}.
$$

The controller uses one non-resetting monotonic deadline through final
publication and PID-deduplicated aggregate MATLAB-tree RSS. It has no lower
wall/RSS threshold, reserve, grace, forecast, stall, CV, spread, or cadence
gate. No certified reference bound or effectivity result exists; `run-007` has
not been compared with the current estimator.

The execution reached `FEM_REFERENCE_CANDIDATE_READY` with 119/119 completed
solves, whole-command wall time $140.273679\,\mathrm{s}$, and authoritative
aggregate peak RSS $1353826304$ bytes. It exited naturally within both hard
limits. The execution is consumed and has no evidence-based retry basis.
