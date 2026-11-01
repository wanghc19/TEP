# Goerisch enclosure experiment

`goerisch-v1` means the first Lehmann–Goerisch enclosure experiment.
R is the reconstructed trial, D the direct tapered trial, FEM the finite
element method, DtN the Dirichlet-to-Neumann map, RT the Raviart–Thomas
element, RSS resident set size, and BIE the boundary integral equation.
JSON means JavaScript Object Notation; CSV means comma-separated values.

The diagnostic supports fitting the interfaces: straddling triangles carry
90.09% of R/RT1's excess and 93.37% of D/RT2's excess. Fitted R/RT3 reaches
width `1.8863e-7`, below the `5.8e-7` target; D/RT3 reaches `3.5989e-6`.
All calculations use ordinary floating point. The gap edges `1.3174^2`
and `2.1875^2` are uncertified; interval interpretation assumes exactly one
spectral point between them. All reported widths and endpoints are in mu units.

The read-only input is
`/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03`.
Its generation is described in the [I9.6 README](../../../test/i9/dtn-bound-v1/README.md).
Reference values: `mu_BIE=2.428728670022710`, `mu0=2.428729247773311`,
and `theta_R=2.428728699465642`.

## Diagnostic split

The true-interface strips account for almost the same excess in both trials:
`2.15470e-6` for R/RT1 and `2.15280e-6` for D/RT2, in qJ-1 units.
Each diagnostic recomputes the original primary-order flux and evaluates
its split at the higher quadrature order. On the infinite strip
$B=\mathbb R\times(-1/2,1/2)$, the exact local identity is
$$
qJ-1=\frac{q}{\|v\|_\rho^2}\int_B\left[
\left|p-\frac{\nabla v}{q}\right|^2+
\frac{|\operatorname{div}p+\rho(1-1/q)v|^2}{\rho}\right].
$$
Expansion and integration by parts give the identity. The reported shares
are of $qJ-1=q(J-G)+(qG-1)$; isolating $J-G$ itself would require the exact
source solution. This computable split supplies the requested decision rule.
A triangle is counted as straddling when it contains true-interface strip
quadrature points. There are 640 such triangles per template cell.

Raw functional numerator, before division by the trial mass:

| Trial / degree | Straddling triangles | Remaining triangles | Strips, a subset | Exterior |
|---|---|---|---|---|
| R / RT1 | 3.19762822e-2 | 7.23313798e-1 | 1.79036914e-6 | 1.45789502e-11 |
| D / RT2 | 3.19743194e-2 | 7.23315251e-1 | 1.78902912e-6 | 0 |

Contributions to qJ-1 from the nonnegative identity:

| Trial / degree | Straddling triangles | Remaining triangles | Exterior | Strips, a subset | Straddling share | Strip share |
|---|---|---|---|---|---|---|
| R / RT1 | 2.17424981e-6 | 2.39219769e-7 | 1.61090770e-11 | 2.15470364e-6 | 90.0875% | 89.2777% |
| D / RT2 | 2.16437787e-6 | 1.53580449e-7 | 0 | 2.15279962e-6 | 93.3743% | 92.8748% |

The sum agrees with the scalar higher-order qJ-1 to relative `9.7071e-6`
for R and `8.8709e-5` for D. Both exceed the 50% localization threshold.
The original scalar quotients and J values are reproduced.
Sources: [D diagnostic](output/run-007/science/diagnostic.json),
[R diagnostic](output/run-008/science/diagnostic.json), and
[normalized comparison](output/run-008/diagnostic_comparison.json).
Per-template and per-cell contributions are retained in those records.

## Trial fields and fitted flux method

Fix gamma equal to one, cell period one and transverse phase 0.5. The
material is rho=4 in the center star, rho=17 in the lead trilobes, and
rho=1 outside. The radius parameter is 0.2 and the left/right trilobe
amplitudes are 0.12/0.20, using the I9.6 parametrizations. R is the control-level
finite reconstruction with 256 source columns per cell and Fourier indices
-128 through 128, including moment corrections and analytic exterior tails.
`goerisch_trial.m` copies the theta-v1 routines and returns the coefficients
in memory. The common flux box is `[-13.5,13.5] x [-0.5,0.5]`.
Its R exterior mass majorant relative to the whole trial mass is
`1.82701205e-11`; K=12 would give `1.25078286e-10`
([preparation](output/run-002/science/prepare.json)).

D uses the same native field as the quadratic-mesh baseline. Its taper is
one for `|x|<=11.5`, then `(1+cos(pi*(|x|-11.5)/2))/2`, and zero beyond
`|x|=13.5`. Values and first derivatives of the taper match at its joins.
D's mass and energy are integrated on its native mesh, retaining the true-
material correction for its mass. This preserves its quotient and resolves
its native gradient jumps. D's values on the fitted flux mesh are obtained
by inversion in the native element or its interface neighbor.

The native templates have 6,410 / 6,330 / 6,392 triangles for left / center /
right. Only the 640 interface-adjacent triangles per template are changed.
For barycentric coordinates at the two interface vertices, set
$r=\lambda_a+\lambda_b$ and $t=\lambda_b/r$. The fitted map is
$$F_h+r^3[c(\theta_0+t\Delta\theta)-c_h(t)],$$
where $c$ is the analytic curve and $c_h$ its quadratic edge interpolant.
It equals the analytic edge at $r=1$ and leaves the other edges fixed.
Curved-element quadrature uses $(r,t)$ coordinates. The Piola map, transverse
phase and zero outer normal traces retain their previous definitions.
The fitted flux integrals have constant rho per element; flux strip
corrections are omitted only after the area test passes.

| Template | Analytic inclusion area | Fitted area, order 24 | Maximum relative error, orders 16/24 |
|---|---|---|---|
| Left | 0.12566370614359174 | 0.12566370614359171 | 2.4296e-15 |
| Center | 0.19415042599184923 | 0.19415042599184906 | 1.0007e-15 |
| Right | 0.12566370614359174 | 0.12566370614359171 | 2.6505e-15 |

The analytic areas are $\pi(0.2)^2$ for either lead inclusion and
$\pi(0.2)^2(1.5+0.3^2/2)$ for the star. All sampled Jacobians are positive. The maximum cell-area error is
`1.5543e-14`. [Run-009](output/run-009/science/result.json) checks the mapping
before flux runs; every fitted run repeats both area orders.

RT1, RT2 and RT3 are degree refinements on the same fitted geometry.
Element-interior elimination and cell-interior elimination reduce the
172,756-triangle strip to wall moments. Reusing each periodic template's
factorization keeps the runs within the memory limit.

With $q=1+\int|\nabla v|^2/\|v\|_\rho^2$, minimize
$$J=\frac{\int |p|^2+|\operatorname{div}p+\rho v|^2/\rho}{\|v\|_\rho^2}.$$
The exterior flux is zero; R's whole-strip mass includes its exterior
contribution. The material increment beyond the original 33-cell source
box is at most `2.2870e-13`, with quotient uncertainty `2.1450e-13`
([normalization](output/run-010/science/normalization/result.json)).
The code adds that increment to the functional's numerator.

The fitted runs evaluate the quadratic part of J from physical p and div(p)
at quadrature points, then add the independently computed trial mass.
`J_gram` retains evaluation through the assembled matrices for comparison.
This uses the same functional and avoids cancellation among large matrix
terms. Triangle orders are 16/24; both evaluations use the same computed flux.

Set $\mu=\alpha_-+1$, $\nu=\alpha_++1$ and
$E(t)=(q-t)/(1-tJ)-1$. The interval is $[E(\nu),E(\mu)]$, with
$$W_G=\frac{(\nu-\mu)(qJ-1)}{(1-\mu J)(\nu J-1)}.$$
Positive Gram denominators and both kappa sign conditions are checked.
These are the N=1 formulas in Nakao–Plum–Watanabe (2019), Lemma 10.25,
printed p.380; Example 10.27, pp.381–383; and Theorem 10.29, pp.386–388.

## Fitted-mesh results

| RT degree | R: q - gamma | R: qJ - 1 | R: interval | R: width | R: wall | R: RSS | D: q - gamma | D: qJ - 1 | D: interval | D: width | D: wall | D: RSS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2.428728699465642 | 2.59247529e-07 | [2.428726517196, 2.428732207323] | 5.69012757e-06 | 552.42 s | 1.438 GiB | 2.428729232270815 | 4.14481840e-07 | [2.428725743284, 2.428734840591] | 9.09730768e-06 | 56.17 s | 1.385 GiB |
| 2 | 2.428728699465642 | 8.79634210e-09 | [2.428728625421, 2.428728818488] | 1.93067568e-07 | 564.70 s | 1.530 GiB | 2.428729232270815 | 1.64164240e-07 | [2.428727850383, 2.428731453562] | 3.60317847e-06 | 61.59 s | 1.812 GiB |
| 3 | 2.428728699465642 | 8.59414517e-09 | [2.428728627123, 2.428728815752] | 1.88629624e-07 | 555.09 s | 1.885 GiB | 2.428729232270815 | 1.63968600e-07 | [2.428727852030, 2.428731450915] | 3.59888445e-06 | 64.60 s | 2.245 GiB |

R rows use runs 010, 014 and 015; D rows use runs 011–013. Each row comes
from `science/result.json` and `monitor.json` in its run directory.
The [six-row comparison](output/run-015/comparison.json) also records the
monotonicity checks; [comparison.csv](output/run-015/comparison.csv) contains
the scalar table.

## Fitted-mesh checks

1. Areas: pass at relative 1e-12. Both orders and all three templates pass;
   the largest observed inclusion-area error is `2.6505e-15`.
2. R quotient: all three R runs give `2.4287286994656423`, relative
   difference `1.8285e-16` from theta-v1, below 1e-12.
3. All six fitted rows have positive qJ-1, satisfy both scalar sign
   conditions, and contain `mu_BIE=2.428728670022710`.
4. Nested-space monotonicity passes for both trials at RT1–RT3. Compare
   each J decrease against the sum of the two absolute quadrature changes.
   R/RT2 to RT3 decreases J by `5.89714e-11`, against `1.05522e-11`
   summed quadrature change; D's decrease is `5.70589e-11`, against
   `1.23790e-14`. Both decreases exceed that measured uncertainty.
5. Quadrature uses the preset criterion
   `q*abs(J_check-J)/(qJ-1)<0.01`. All six fitted rows pass; the maximum
   scaled change is `0.210224%`, for R/RT3.

| Trial / degree | J | J check | Scaled change | J_gram minus J |
|---|---|---|---|---|
| R / RT1 | 0.2916533639431363 | 0.2916533639484193 | 0.00698713% | -5.14926990e-12 |
| D / RT1 | 0.2916533638964395 | 0.2916533638964398 | 1.83683e-07% | -5.13133980e-12 |
| R / RT2 | 0.2916532908982239 | 0.2916532909035069 | 0.205924% | -1.50582824e-10 |
| D / RT2 | 0.2916532908904997 | 0.2916532908905000 | 5.79702e-07% | -1.50815638e-10 |
| R / RT3 | 0.2916532908392526 | 0.2916532908445219 | 0.210224% | 8.85743179e-09 |
| D / RT3 | 0.2916532908334408 | 0.2916532908334287 | 2.53052e-05% | 8.83233547e-09 |

D's quotient is `2.4287292322708147` at every degree, `1.55024962e-8` below
mu0. Native cell-value jumps are zero and the phase mismatch is `2.2342e-16`
relative ([native traces](output/run-011/science/native_trace.json)).

## Interpretation

Fitting removes the common spatial floor: the strip contributions are about
`2.15e-6` in qJ-1 for both trials. D's fitted RT2 and RT3 widths are near the
estimated `4e-6` exact-flux floor. R's width decreases by a factor of 29.47
from RT1 to RT2, then by 2.30% to RT3's `1.8863e-7`. Both RT2 and RT3
meet the `5.8e-7` target; RT3 is within a factor of two of `1e-7`.
D's width changes by only 0.119% from RT2 to RT3. The separation between
the two trials becomes visible once the interface floor is removed.

There is a separate arithmetic loss in the assembled quadratic form.
For fitted D/RT3, `J_gram-J=8.83233547e-9` at the same quadrature order;
the pointwise two-order change is only `1.21014e-14`. The matrix formula
therefore retains a cancellation problem even after fitting. The accepted
J values use physical pointwise evaluation, whose refinement is monotone.

The `3e-8` estimated R floor is too small for the stored quotient and these
gap edges. Set $\delta=q-1-\mu_{\rm BIE}>0$. The smallest J for which the
lower endpoint reaches the reference is
$$J_{\min}=\frac{\nu-\delta}{\nu(q-\delta)}.$$
Substitution gives width `7.67704614e-8` before any remaining flux error
([arithmetic record](output/run-013/comparison.json)). This is an algebraic
constraint using the stored values, not a measurement of the exact flux.

The deliverable is an interval for the spectral point under the stated
conditions. An error bound for the old candidate would follow as
`max(abs(mu0-lower),abs(mu0-upper))` once the interval entries are guaranteed.

## Reproduction and cost

All MATLAB runs use the unchanged diagnostics-v1 monitor and escalated
permission. Runs are serial, with 30 minutes soft, 40 minutes hard and
3 GiB RSS limits. Times below include MATLAB startup and all checks.
The experiment starts from the saved source blocks and native field.

The flux command, shown for the final run, is:

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-015 \
  "addpath('/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1'); goerisch_enclosure('/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03','/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-015/science',3,'R','fitted');"
```

Substitute the run number, degree, trial and mode from the table. Use a
fresh run number to preserve existing records. Each `command.json` contains
its exact MATLAB invocation.

| Run | Entry / degree / trial / mode | Estimate before launch | Wall / peak RSS |
|---|---|---|---|
| 007 | enclosure / 2 / D / diagnose | 1–4 min, <2.3 GiB | 41.90 s / 1.932 GiB |
| 008 | enclosure / 1 / R / diagnose | 8–18 min, <2.5 GiB | 738.22 s / 1.500 GiB |
| 009 | fit_check | 15–60 s, <1.5 GiB | 17.11 s / 1.073 GiB |
| 010 | enclosure / 1 / R / fitted | 8–16 min, <2.5 GiB | 552.42 s / 1.438 GiB |
| 011 | enclosure / 1 / D / fitted | 1–4 min, <2.2 GiB | 56.17 s / 1.385 GiB |
| 012 | enclosure / 2 / D / fitted | 1–5 min, <2.5 GiB | 61.59 s / 1.812 GiB |
| 013 | enclosure / 3 / D / fitted | 2–6 min, <2.9 GiB | 64.60 s / 2.245 GiB |
| 014 | enclosure / 2 / R / fitted | 9–16 min, <2.5 GiB | 564.70 s / 1.530 GiB |
| 015 | enclosure / 3 / R / fitted | 10–16 min, <2.8 GiB | 555.09 s / 1.885 GiB |

The fitted R pilot measured 537 s in the solver; field evaluation dominates.
The R/RT3 forecast was updated before launch using the 552 s R pilot and
D/RT3's measured 64.60 s / 2.245 GiB. R/RT2's 564.70 s result confirmed it.
The six fitted runs total 1,854.56 s; all nine new monitored runs total
2,651.79 s. The largest measured RSS is 2.245 GiB, for D/RT3.

For run-009, replace the MATLAB call with
`goerisch_fit_check(input_dir,output_dir)`; it has no degree/trial arguments.
Run-002 used `goerisch_prepare(input_dir,output_dir)`. The explicit input and
output paths are the same pattern as the command above. The scalar
postprocessor is reproduced by:

```sh
python3 test/numerical-directions/goerisch-v1/summarize_goerisch.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1 \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-015
```

## Quadratic-mesh results

All numbers below are in mu units. Wall time includes MATLAB startup.
The RT3 D row is retained as an unaccepted diagnostic after its quadrature check failed.

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


The quadratic-mesh quadrature test used the same 1% scaled tolerance:

| Run / trial / degree | J change | Scaled change | Outcome |
|---|---|---|---|
| 003 / R / RT1 | -5.78141934e-9 | 0.814657% | pass |
| 004 / D / RT1 | -5.78599668e-9 | 0.766402% | pass |
| 005 / D / RT2 | -5.57435142e-9 | 0.817744% | pass |
| 006 / D / RT3 | -1.67264080e-8 | 2.422963% | fail |

That phase stopped at the failed check, leaving the quadratic-mesh R/RT2
and R/RT3 rows unrun. Run-006's exact error was:

```text
Error using assert
Quadrature change is too large.

Error in goerisch_enclosure (line 134)
  assert(checks.quadrature_pass,'goerisch:Quadrature','Quadrature change is too large.');
```

Runs 003–006 used the enclosure entry with degrees/trials shown above and
the default `quadratic` mode. Their exact commands remain in `command.json`.
Their estimates were respectively 3–12 / 1–4 / 1–4 / 1–5 minutes, with peak
estimates below 2.2 / 1.6 / 2.2 / 2.6 GiB. Run-002 preparation took 27.10 s
at 1.087 GiB, against a 1–5 minute / below-1.8 GiB estimate. Completed
monitored runs 002–006 total 556.42 s
([original comparison](output/run-006/comparison.json)).

## Startup failure and cost

Run-001 used the preparation entry with its output paths set to run-001. Its exact MATLAB command is retained in [output/run-001/command.json](output/run-001/command.json).
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
The original attempt ended there. Authorized escalated run-002 completed
preparation; all subsequent launches used that channel.
