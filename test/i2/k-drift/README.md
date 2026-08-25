# I2.3 boundary-Nystrom candidate drift

This directory contains the single formal I2.3 runner `check_k_drift.m`. It
tests whether the same finite-dimensional real-axis candidate moves across
three boundary quadrature orders while the proxy, channel, frame, rows,
branches, solver, and physical scoring functional remain fixed.

## Current result

The unique formal attempt `drift-a1` completed in MATLAB on `2026-08-14`. Its
append-only artifact retains the preregistered machine status
`I2_3_DRIFT_UNRESOLVED`, while the current object-level scientific conclusion is
`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`. All three locators, candidate gates,
fixed-point repeats and adjacent mode-identity gates passed.

| `ntot` | saved candidate | terminal half-width | `s1` | `r12` |
|---:|---:|---:|---:|---:|
| 160 | 1.832770289108157 | 9.3132279666e-11 | 5.6552567226e-11 | 1.1050964837e-10 |
| 208 | 1.832770289108157 | 9.3132279666e-11 | 5.6553421682e-11 | 1.1051131807e-10 |
| 256 | 1.832770289108157 | 9.3132279666e-11 | 5.6553167216e-11 | 1.1051082081e-10 |

Both adjacent pairs are `SAME_MODE`: wall/probe overlaps are numerically one
and competitor overlaps are below `4.3e-13`. Under the same initial interval,
five-point dyadic rule, levels 0--11, 27 evaluated points, terminal spacing,
tie band, winner rule, functional and solver, all three saved candidates are
exactly equal. Hence every observed candidate drift is zero and the current
scientific classification is `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`.

The listed half-width is not candidate uncertainty. It is the terminal-cell
scale for locating an uncomputed continuous-$k$ score minimizer near the saved
candidate. Without interpolation, unimodality, convexity or an enclosure proof,
it is not a rigorous minimizer-error bound. Potential sub-grid minimizer drift
remains `SUBGRID_MINIMIZER_DRIFT_UNRESOLVED`; that caveat does not erase the
observed candidate equality or stop I3 from beginning error-source analysis.

The formal run used the command registered below, took `294.984 s`, and
recorded a peak active-object snapshot of `163.769 MiB`. There was one formal
attempt, no execution failure, and no retry. The append-only output remains under
`output/drift-a1/` and contains only `result.mat` and `report.md`; its original
machine status is preserved rather than edited to match the later interpretation.

## Frozen experiment

- Sole scientific axis:
  `BOUNDARY_NYSTROM_NTOT_AT_FIXED_FINE_PROXY_M48`.
- Levels: `ntot = 160, 208, 256`.
- Fixed channel size: `M = 48`, `K = 97`.
- Fixed fine proxy tuple:
  `(N_side, N_top, N_proxy_edge, M_pw) = (160, 160, 80, 32)`.
- Common frame: one `ntot = 256` seed at the frozen I2.1 center.
- Candidate functional: the I1.3 weighted physical matrix `Aphys`, with
  score `s1 = sigma_min(Aphys)/sigma_max(Aphys)`.
- Count context: the I2.1 conditional count-one evidence attaches only to
  `ntot = 256`; counts for `ntot = 160, 208` are not established.

Each level independently applies a five-point dyadic locator to the full I2.1
real diameter. It uses levels 0 through 11, a fixed absolute score tie band of
`1e-12`, and stops when the grid spacing is at most `1e-10`. A normal locator
uses 27 unique points. The terminal winner score, runner-up score, and gap are
stored. No fitting, window extension, interpolation, or continuous root claim
is permitted.

## Gates and interpretation

Every selected node must pass the existing `eval_i21` branch, proxy, BIE, QZ,
fixed-row, chart, graph, participation, residual, and factor gates. Terminal
candidates additionally record the raw right and left residuals, backward
errors, SVD-triplet residual, graph lift, boundary defects, weighted wall
trace, and nine fixed center-cell field probes.

Adjacent levels qualify as the same mode only when their weighted wall-trace
and probe-field overlaps are at least `0.99`, mapped second-vector
participation is available, and every primary-secondary physical cross-overlap
is at most `0.5`. The shared overlap helper is checked before evaluation using
the fixed nontrivial scales `1e8*exp(1i*pi/7)` and
`1e-8*exp(-1i*pi/7)`, as well as orthogonal and unavailable cases.

An adjacent pair is `SAME_MODE` only when the primary overlaps and competitor
gate pass. An available secondary representation with cross-overlap above
`0.5` is reported as `MODE_SWITCH`; remaining failures are
`MODE_IDENTITY_UNRESOLVED`. Neither non-`SAME_MODE` outcome forms a hierarchy.

Each terminal point is recomputed once. This repeat tests fixed-candidate
reproducibility only; it does not claim that the terminal winner/runner-up
ranking is stable. The frozen runner additionally compared candidate differences
with the sum of two terminal-cell scales and wrote `DRIFT_UNRESOLVED`,
`hierarchy_qualified=false` and `i3_may_proceed=false`. Those fields remain part
of the immutable artifact contract. They are superseded for current scientific
interpretation because the terminal-cell scale concerns the uncomputed sub-grid
minimizer, not uncertainty in the saved candidate.

The output is conditional empirical evidence about three discrete candidates.
It establishes no observed candidate drift under identical scan parameters and
strong `SAME_MODE` evidence. It does not prove equal sub-grid minimizers, a
finite root, a continuous guided mode, a convergence order, an error attribution,
an estimator, or an upper bound.

## Dependencies and command

Run from the repository root in MATLAB after independent static review:

```sh
matlab -batch "addpath(fullfile(pwd,'test','i2','k-drift'),fullfile(pwd,'test','i2','k-count')); check_k_drift('drift-a1');"
```

The required current-path dependencies are `eval_i21`, `i21_kproxy`, `kproxy`,
`kchan`, `kgreen`, `kbie`, `geom.construct_cont`, `bloch.incident_rhs`,
`bloch.farfield_extractors`, `kernel.h2d_directch`,
`kernel.kress_l_splits`, `kernel.kress_mn_splits`, `utils.triginterp`,
`quad.quad_kress_rvec`, and MATLAB `lsqminnorm`. The runner records the
resolved function paths and necessary numeric configuration, but does not read
or hash Git state, documentation, history, source digests, or old outputs.

The sole formal tag is `drift-a1`. It is append-only and refuses an existing
tag directory. Its directory contains exactly:

```text
output/drift-a1/result.mat
output/drift-a1/report.md
```

Startup failure before the output directory is created leaves no artifact; the
MATLAB command output is then the failure record.

## Resource envelope

The design requires one seed, 81 unique locator evaluations, and three fixed
candidate repeats. At most five dense locator nodes per level are retained.
The soft runtime target is 900 seconds, the hard runtime gate is 1800 seconds,
and the active-object memory gate is 512 MiB.

The implementation was prepared by static inspection and independently
reviewed before the unique MATLAB run. No Octave command was used.
