# Goerisch enclosure experiment

Stopped after D/RT3 failed the prescribed quadrature check: 2.42% against
a 1% tolerance. R/RT1 and D/RT1–RT2 passed. R/RT2–RT3 remain TODO.
Run-001 is retained as the original startup failure record; escalated
MATLAB and monitoring worked in runs 002–006.

`goerisch-v1` means the first Lehmann–Goerisch enclosure experiment.
R denotes the reconstructed trial, D the direct tapered trial, FEM the
finite element method, DtN the Dirichlet-to-Neumann map, RT the
Raviart–Thomas element, and RSS resident set size. BIE means boundary
integral equation; JSON means JavaScript Object Notation and CSV
comma-separated values.

Purpose: measure ordinary floating-point eigenvalue intervals for R and D
with the same flux spaces. The separating edges `1.3174^2` and `2.1875^2`
are uncertified. Interval interpretation assumes exactly one spectral point
between these edges; quadrature and rounding also remain uncertified.
The reference values are `mu_BIE=2.428728670022710`,
`mu0=2.428729247773311`, and `theta_R=2.428728699465642`.

The explicit read-only input is
`/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03`.
`goerisch_trial.m` copies theta-v1's reconstruction and geometry routines,
returning the reconstructed coefficients in memory. `goerisch_prepare.m`
checks that copy and selects the box. `goerisch_enclosure.m` assembles and
minimizes the flux functional and computes the scalar enclosure.

## Method

Fix gamma equal to one and transverse phase 0.5. R uses the saved control
source with 256 columns per cell and Fourier indices -128 through 128,
including corrected source moments and analytic exponential tails. Its
normalization repeats theta-v1's column and inclusion quadrature.
Preparation selected K=13: the box is `[-13.5,13.5] x [-0.5,0.5]`, with
relative exterior mass majorant `1.8270120475e-11` using rho <= 17.
K=12 gives `1.2507828606e-10` and fails the specified tail threshold
([prepare.json](output/run-002/science/prepare.json)).

D uses the saved native FEM coefficients. Its taper is one for
`|x| <= 11.5`, then `chi=(1+cos(pi*(|x|-11.5)/2))/2`, and zero at and
beyond the cuts. This taper and its first derivative are continuous.
The taper uses the same box as R. The assembled field has matching values
across cell walls and the prescribed transverse phase.

The saved quadratic mesh has 6,410 / 6,330 / 6,392 triangles in the
left / center / right templates. Each of the 13 copies per lead uses the
same template factorization. The chosen sequence is RT1, RT2, RT3 on this
mesh: degree refinement rather than three distinct meshes. Element-interior
elimination followed by cell-interior elimination leaves the vertical wall
moments for the strip solve. This avoids factoring the matrix for all
172,756 triangles at once. The Piola-mapped flux has matching normal traces,
the transverse phase, and zero normal traces at the cuts; it is extended
by zero outside the box.

Mesh integrals use tensor Gauss rules after a triangular Duffy transform,
with orders 16 and 24. An oriented strip between each quadratic interface
and its true analytic curve corrects the material weight, with orders 10
and 16. Strip points are located in the adjacent curved triangle. The load
`integral v div(p)` is independent of rho. The quadratic flux norm uses
`integral |p|^2 + |div(p)|^2/rho` on the true materials. R is evaluated by
its finite Fourier/exponential formula; D by its native quadratic field
and taper. The higher-order check reevaluates the same computed flux.

For unnormalized trial mass B, minimize
`J_raw=B+integral |p|^2+|div(p)|^2/rho+2 Re(conj(div(p))*v)`.
B includes the exterior mass where p=0. The omitted material increment
beyond the original 33-cell source box is at most `2.2870e-13` and is
added to J_raw; its quotient uncertainty is `2.1450e-13`
([normalization](output/run-003/science/normalization/result.json)).
With `q=1+energy/B` and `J=J_raw/B`, use
`E(t)=(q-t)/(1-t*J)-1`, interval `[E(nu),E(mu)]`, and
`W=(nu-mu)*(q*J-1)/((1-mu*J)*(nu*J-1))`.
The code checks positive Gram denominators and both kappa inequalities.
These are the N=1 formulas from Nakao–Plum–Watanabe (2019), Lemma 10.25,
printed p.380; Example 10.27, pp.381–383; and Theorem 10.29, pp.386–388.

## Results

All numbers below are in mu units. Wall time includes MATLAB startup.
The RT3 D row is retained as an unaccepted diagnostic after check 4 failed.

| Flux level | R: q - gamma | R: qJ - 1 | R: interval | R: width | R: wall / peak RSS | D: q - gamma | D: qJ - 1 | D: interval | D: width | D: wall / peak RSS |
|---|---|---|---|---|---|---|---|---|---|---|
| RT1 | 2.428728699465642 | 2.43328518e-6 | [2.428708216891, 2.428761624335] | 5.34074442e-5 | 423.59 s / 1.261 GiB | 2.428729232270815 | 2.58853752e-6 | [2.428707442835, 2.428764257866] | 5.68150311e-5 | 29.16 s / 1.454 GiB |
| RT2 | TODO | TODO | TODO | TODO | not run | 2.428729232270815 | 2.33727690e-6 | [2.428709557850, 2.428760858018] | 5.13001681e-5 | 33.50 s / 1.764 GiB |
| RT3 | TODO | TODO | TODO | TODO | not run | 2.428729232270815 | 2.36695047e-6 | [2.428709308069, 2.428761259535] | 5.19514664e-5 (unaccepted) | 43.07 s / 2.272 GiB |

Sources: [R/RT1](output/run-003/science/result.json),
[D/RT1](output/run-004/science/result.json),
[D/RT2](output/run-005/science/result.json),
[D/RT3](output/run-006/science/result.json), and each run's `monitor.json`.
[comparison.csv](output/run-006/comparison.csv) collects the scalar rows;
[comparison.json](output/run-006/comparison.json) records derived comparisons.

## Checks

1. **R quotient: pass.** Run-002 and run-003 give
   2.4287286994656423 versus the stored reference 2.4287286994656418:
   relative difference `1.82848422e-16`, below `1e-12`.
   The copied norm also agrees with I9.6 to `4.44e-16` relative, and the two
   numerator formulas agree to `3.81e-15` relative
   ([normalization](output/run-003/science/normalization/result.json)).
2. **Cauchy–Schwarz: pass for all four computed rows.** The positive
   `qJ-1` values are listed above. Both scalar sign conditions pass in each
   row. Global linear-system relative residuals are at most `9.89e-16`;
   reference normal-trace errors are at most `7.55e-12` (result JSON files).
3. **Reference containment: pass for all four computed rows.** Each stored
   interval contains `2.428728670022710`, including the unaccepted RT3 row.
4. **Functional quadrature: fail at D/RT3.** The tolerance fixed before the
   first pilot is `q*abs(J_check-J)/(qJ-1) < 0.01`.

   | Run / trial / degree | J, lower order | J, higher order | J change | Scaled fraction | Outcome |
   |---|---|---|---|---|---|
   | 003 / R / RT1 | 0.2916539980083652 | 0.2916539922269458 | -5.78141934e-9 | 0.814657% | pass |
   | 004 / D / RT1 | 0.2916539979668296 | 0.2916539921808329 | -5.78599668e-9 | 0.766402% | pass |
   | 005 / D / RT2 | 0.2916539246858539 | 0.2916539191115025 | -5.57435142e-9 | 0.817744% | pass |
   | 006 / D / RT3 | 0.2916539333402464 | 0.2916539166138384 | -1.67264080e-8 | 2.422963% | fail |

5. **D taper/trial value: pass.** All D levels give
   `q-gamma=2.4287292322708147`, which is `1.55024962e-8` below mu0.
   The higher-order quotient changes by only `-4.44e-16`.
   Native cell-value jumps are zero and the transverse phase mismatch is
   `2.2342e-16` relative
   ([native_trace.json](output/run-004/science/native_trace.json)).
   The difference from mu0 includes the trial discretization and taper;
   an untapered quotient was not computed separately.

## What the measurements say

The R coarse width is 92.08 times the requested `5.8e-7` target. D's accepted
width decreases by 9.71% from RT1 to RT2. The three-level R comparison and
the expected finest-level flux accuracy remain unfinished. These data do
not establish whether the estimated R and D exact-flux floors can be reached.

The nearly equal R and D RT1 quadrature changes differ by only `4.58e-12`.
This points to the shared flux/material integration as a diagnostic priority;
the individual contributions were not isolated. The RT3 primary J increases
by `8.65e-9` over RT2, whereas the higher-order J decreases by `2.50e-9`.
The quadrature discrepancy therefore obstructs interpretation of this degree
trend. The true-curve correction strips have absolute areas
`2.52e-8 / 3.25e-7 / 4.14e-8` for left / center / right in run-006's template
JSON files. Their relation to the enclosure floor remains TODO.

The intended deliverable is an interval for the spectral point under the
stated assumptions. A bound for the old candidate would then follow by
`max(abs(mu0-lower),abs(mu0-upper))`, once its interval is guaranteed.
The current calculations supply ordinary arithmetic diagnostics.

## Reproduction and cost

Every launch used the unchanged diagnostics-v1 monitor with escalated
permission. It samples process-tree memory and enforces 30 minutes soft,
40 minutes hard, and 3 GiB RSS. Runs were serial.
Preparation:

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-002 \
  "addpath('/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1'); goerisch_prepare('/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03','/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-002/science');"
```

Flux entry, shown with the exact failed run-006 arguments:

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-006 \
  "addpath('/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1'); goerisch_enclosure('/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03','/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-006/science',3,'D');"
```

Use `(1,'R')` for run-003, `(1,'D')` for run-004, and `(2,'D')` for run-005,
changing both output paths to the corresponding run. Exact MATLAB
invocations are preserved in each run's `command.json`. To reproduce without
replacing records, use a fresh run number.

| Run | Purpose | Estimate before launch | Measured wall / solver / peak RSS |
|---|---|---|---|
| 001 | Preparation, sandbox startup failure | 1–5 min / <1.8 GiB | unavailable |
| 002 | Preparation through escalation | 1–5 min / <1.8 GiB | 27.10 s / 14.29 s / 1.087 GiB |
| 003 | R, RT1 pilot | 3–12 min / <2.2 GiB | 423.59 s / 405.60 s / 1.261 GiB |
| 004 | D, RT1 | 1–4 min / <1.6 GiB | 29.16 s / 16.85 s / 1.454 GiB |
| 005 | D, RT2 | 1–4 min / <2.2 GiB | 33.50 s / 20.42 s / 1.764 GiB |
| 006 | D, RT3 | 1–5 min / <2.6 GiB | 43.07 s / 28.22 s / 2.272 GiB |

Preparation estimates came from theta-v1 and array sizes. Run-003 measured
template elimination at about 0.2 s each; evaluating R at quadrature points
dominated its runtime. Subsequent predictions used that pilot and D/RT1's
16.85 s solver time, allowing for larger local matrices and cell factors.
The monitored runs 002–006 total 556.42 s, including preparation and the
failed check.

The exact scientific error in [run-006/run.log](output/run-006/run.log) is:

```text
Error using assert
Quadrature change is too large.

Error in goerisch_enclosure (line 134)
  assert(checks.quadrature_pass,'goerisch:Quadrature','Quadrature change is too large.');
```

The [research-worker experiment rule](../../../.agents/skills/research-worker/references/experiments.md)
says: “If one fails, stop and report rather than adjusting the method until
the check passes.” No further run was launched. TODO: isolate the functional
quadrature discrepancy, then complete R's RT2/RT3 comparison in a subsequent
task after review of the failed check.

## Startup failure and cost

Run-001 used the preparation command above with both run directory names
changed to run-001. Its exact MATLAB command is retained in [output/run-001/command.json](output/run-001/command.json).
The unchanged monitor raised the following error before recording its first
resource sample:

```text
PermissionError: [Errno 1] Operation not permitted: 'ps'
```

The full launcher traceback is retained in
[output/run-001/monitor-error.txt](output/run-001/monitor-error.txt).
MATLAB's [run.log](output/run-001/run.log) separately reports:

```text
Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error

MATLAB is exiting because of fatal error
```

The monitor's resource CSV contains only its header; it did not produce
`monitor.json`. Wall time and peak process-tree RSS are therefore unavailable.
The original attempt ended there. The authorized escalated run-002 then
completed preparation; later runs encountered no sandbox or startup failure.
