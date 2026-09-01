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

## Completed run-008 sample-out layer

Status: **POST-RUN PASS WITH CONDITIONS / `run-008/execution-001` CONSUMED**
under review §§BF, BQ, and BT. The independent entry `run_i4_1a_refine.m`
accepted only `run-008`; the fixed no-argument controller was
`run_refine_formal.pl`, and the create-once namespace is
`output/run-008/execution-001/`. No retry is authorized.

The completed call graph built only the fitted
$(N,s,g)=(5,30,60)$ defect mesh and performed exactly five 48-root solves at

$$
\Theta_5=\left(0,\frac{\pi}{4},\frac{\pi}{2},
\frac{3\pi}{4},\pi\right).
$$

The mesh contains 11,741 nodes, 22,760 triangles, and 11,380 reduced DOFs.
The run retained every valid field-bearing whole cluster intersecting $W_3$,
tracked adjacent twists by maximum-total common-core overlap, and ranked every
component using only current-run FEM quantities. The canonical pure-FEM winner
is candidate 3, with

$$
\lambda_{30}=0.61502508946098011,
\qquad k_{30}=0.78423535336082628.
$$

The canonical schema consists of `scientific-result.mat`,
`fields.mat`, `run.log`, `resource.tsv`, and summary-last `run-summary.csv`;
`work/` contains one mesh cache, five spectrum caches, and the terminal draft.
`fields.mat` owns every retained full subspace and its common-core samples and
positive weights. The scientific command completed in $35.917169$ s with
aggregate peak RSS $1073594368$ B, inside the hard limits below.

The controller has only the inclusive hard limits

$$
T_{\mathrm{hard}}=2700\ \mathrm{s},
\qquad
R_{\mathrm{hard}}=3221225472\ \mathrm{bytes}.
$$

The exact completed command was

```sh
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/perl ./run_refine_formal.pl
```

The command completed naturally; the scientific execution is consumed.

## Completed candidate-7 identity audit

Status: **`identity-001` AND `identity-002` CONSUMED OPERATIONAL FAILURES /
`identity-003` POST-AUDIT PASS WITH CONDITIONS / CONSUMED** under design
§§46--54 and reviews §§BO--BQ. The immutable `identity-001` run stopped when
the sandbox denied process-table access; it consumed $0.001110\,\mathrm{s}$,
observed zero audit RSS before termination, and produced no identity result.
The immutable `identity-002` run stopped before substantive decoding because
the fixed dylib lacks `H5free_memory`; it consumed $2.053772\,\mathrm{s}$,
observed $966656$ bytes peak audit RSS, and also produced no identity result.
Neither is an identity-method failure, and neither may be read, copied, or
retried.

`identity_audit.py` and `run_identity_audit.pl` used the same fixed authority
`identity-003`. Its consumed create-once target is
`output/run-008/execution-001/review-audit/identity-003/`.

The audit reconstructed old candidate 7 on the five prescribed fine-grid
twists, compared complete old/new field-bearing inventories by weighted
principal subspace overlap, and applied full dummy-augmented lexicographic
assignment. All five matched pairs had overlap above $0.9999975688$, supported
`SAME_MODE_SUPPORTED`, and uniquely mapped old candidate 7 to new candidate 9.
The candidate-specific publication is

$$
\lambda_{30}^{(7)}=3.366203342658638,
\qquad k_{30}^{(7)}=1.834721598133798.
$$

Canonical pure-FEM candidate 3 remains unchanged; candidate 9 is not the
canonical winner.

The successful command was:

```sh
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/perl ./run_identity_audit.pl
```

The successful identity audit consumed $29.683016$ s and peaked at
$564379648$ B. The cumulative pre-profile account was $92.655067$ s with peak
$1073594368$ B. No identity audit may be rerun.

## Completed candidate-7 scalar profile

Status: **POST-RUN PASS WITH CONDITIONS / `profile-001` CONSUMED** under
design §56 and review §BT. The fixed create-once target is
`output/run-008/execution-001/review-audit/profile-001/`.

The postprocess used only source-frozen scalars for old candidate 7 and its
reviewed new candidate 9 identity component. Canonical pure-FEM candidate 3
remains unchanged. The signed drifts are

$$
(-0.0052814302919568235,-0.001979901415371188,-0.0009584126670008075),
$$

the contraction ratios are $(0.37487977799998845,0.4840709035106812)$, and
the out-of-sample prediction residual is
$4.794533798202494\times10^{-6}$. The seven-start QR variable-projection fit
selected start 6 with

$$
p=1.8129679837413033,
\quad k_\infty=1.8327935034213265,
\quad C=0.9181205139250015,
\quad \mathrm{SSE}=4.302174060684754\times10^{-12}.
$$

The fixed late positional comparison is
$|k_{30}^{(7)}-k_{\mathrm{BIE}}|=0.0019513090256411125<0.0029097217$, so its
strict boolean is true.

The successful command was:

```sh
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/perl ./run_profile_postprocess.pl
```

`profile-001` completed naturally in $17.400782$ s. The final cumulative wall
was $110.055849$ s and cumulative peak RSS was $1073594368$ B, below the
$2700$ s and $3221225472$ B hard uppers. The result is
`EMPIRICAL_NON_CERTIFIED`, `effectivity_performed=false`, and is not a
continuous eigenpair proof, certified reference bound, or effectivity
validation. It is consumed and must not be rerun.
