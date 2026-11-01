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

## Step 3: RT3 plateau and reconstruction cost

R stays near width `1.89e-7` after stabilizing RT3 and refining the RT2
mesh. The optional RT4 result is `1.88602522e-07`. The large RT3 discrepancy
comes from div-div cancellation in the moment basis. Correcting it greatly
improves functional agreement while leaving the pointwise enclosure
unchanged within quadrature uncertainty. Field evaluation dominates R's cost.

### Localization and correction

Run-016 reproduces run-015's pointwise J and width exactly. Separately
evaluating the flux-mass, div-div and twice-load terms localizes the error
as follows. Entries are Gram minus pointwise values before division by
the trial mass `2.5896785236423288`.

| Elements | Term | Order 16 difference | Order 24 difference |
|---|---|---|---|
| Unchanged | Flux mass | 3.99680e-15 | 5.40124e-14 |
| Curved | Flux mass | 8.15320e-17 | 1.83881e-16 |
| Unchanged | Div-div | 2.34903e-8 | -5.06036e-9 |
| Curved | Div-div | 3.73385e-11 | -1.73938e-10 |
| Unchanged | Twice load | -9.10383e-15 | 3.55271e-15 |
| Curved | Twice load | -6.31439e-16 | 5.34295e-16 |

The constant is the independently integrated trial mass in both formulas,
so its difference is zero. More than 99% of the primary div-div discrepancy
is on unchanged elements. The combined matrix evaluation has numerator
difference `2.29379e-8`; separately contracting its components adds another
roundoff difference, visible in the table. The normalized difference is
`J_gram-J=8.85743e-9`.

Between orders 16/24, relative Frobenius differences range from
`1.57e-15` to `3.86e-15` for the matrix, and `1.75e-8` to `9.22e-7` for the
load, across templates and the two element groups. The pointwise J changes
by `5.26929e-12`. The condensed global residual is `1.06702e-15`; unreduced
interior-equation residuals range from `2.71e-8` to `3.35e-8` in the old
coordinates. The discrepancy between the two functional evaluations occurs
for the same coefficient vector, independently of how it was obtained.
Sources: [component records](output/run-016/science/result.json) and
[arithmetic summary](output/run-022/study-summary.json).

The fix preserves the RT space, edge moments and Piola map. A weighted QR
factorization orthonormalizes the raw reference vector polynomials. A
singular value decomposition of their edge-moment matrix supplies
minimum-norm edge lifts and an orthonormal interior kernel. At RT3, the
coefficient-matrix norm drops from `251521.82` to `3413.63`; the edge-moment
error is `1.15e-13` ([basis data](output/run-018/science/result.json)).
This addresses the observed cancellation without increasing quadrature.

Re-solving R/RT3 gives `J=0.29165329083928765`, against the previous
`0.29165329083925257`: a change of `3.51e-14`, compared with a
`5.28e-12` quadrature change. The scaled Gram discrepancy drops from
`353.377%` to `0.0871530%`. Thus the inaccurate matrix functional does not
explain the observed width plateau.

### Mesh control and fixed-solve results

The refined mesh has 691,024 triangles, four children per original fitted
triangle. Every child map is the parent map composed with an affine
reference map. It preserves the exact interfaces, material labels, box,
normal traces and transverse phase. RT2 is nested under this refinement.
Flux quadrature orders 8/12 on children use the same point count as 16/24
on parents. Area checks remain at 16/24. D's normalization remains on its
native mesh with the original quadrature orders.

Refined RT2 and coarse RT4 use blocked Schur-complement construction and
refactor one template during recovery. This avoids dense extension
matrices and retaining three sparse factors. The older enclosure entry
point remains available unchanged; the new entry is `goerisch_flux_study`.

| Mesh | Degree | R: qJ-1 | R: interval | R: width | R: wall | R: RSS | D: qJ-1 | D: interval | D: width | D: wall | D: RSS |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Original fitted | RT3 | 8.59426552e-09 | [2.428728627121582, 2.428728815753848] | 1.88632266e-07 | 431.99 s | 2.562 GiB | 1.63968723e-07 | [2.428727852029159, 2.428731450916315] | 3.59888715e-06 | 75.40 s | 2.379 GiB |
| Four children | RT2 | 8.59389204e-09 | [2.428728627124726, 2.428728815748794] | 1.88624068e-07 | 479.52 s | 2.327 GiB | 1.63970918e-07 | [2.428727852010681, 2.428731450946018] | 3.59893533e-06 | 82.85 s | 2.178 GiB |
| Original fitted | RT4 | 8.59291038e-09 | [2.428728627132988, 2.428728815735512] | 1.88602522e-07 | 465.01 s | 2.204 GiB | 1.63967420e-07 | [2.428727852040129, 2.428731450898682] | 3.59885855e-06 | 93.94 s | 2.238 GiB |

Sources are R runs 018/020/022 and D runs 017/019/021, each with
`science/result.json` and `monitor.json`. The [scalar table](output/run-022/study-results.csv)
and [comparison record](output/run-022/study-summary.json) collect them.

### Checks

1. All inclusion areas pass relative `1e-12`; the maximum error is `1.05790e-14`.
   The maximum cell-area error is `9.22595e-14`. All R quotients equal
   `2.4287286994656423`, with relative difference `1.82848e-16` from theta-v1.
2. Every fixed row has positive qJ-1, both sign conditions, and an interval
   containing `mu_BIE=2.428728670022710`. Every R width exceeds `7.67705e-8`.
3. All nested comparisons pass. The refinement comparison uses RT2 on
   both meshes; the degree comparison uses the original fitted mesh.
   Each allowance is the sum of the two measured absolute quadrature changes.
4. Pointwise quadrature passes `q*abs(J_check-J)/(qJ-1)<0.01` for all six
   fixed rows. Its maximum scaled change is `0.285514%`.
5. Assembled-versus-pointwise agreement passes
   `q*abs(J_gram-J)/(qJ-1)<0.01` for all six fixed rows. Its maximum is `0.353387%`.
   The old-basis run-016 audit deliberately measures the discrepancy being fixed.

| Trial / runs compared | J decrease | Summed quadrature change | Check |
|---|---|---|---|
| D / 012 to 017 | 5.70229419e-11 | 2.77555756e-16 | pass |
| R / 014 to 018 | 5.89363003e-11 | 1.05653264e-11 | pass |
| D / 012 to 019 | 5.63827318e-11 | 6.66133815e-16 | pass |
| R / 014 to 020 | 5.90452132e-11 | 1.24391608e-11 | pass |
| D / 017 to 021 | 3.80084852e-13 | 1.66533454e-16 | pass |
| R / 018 to 022 | 3.95183886e-13 | 1.05649378e-11 | pass |

The last column in the following table is the new functional-agreement
check. Refinement 0 denotes the original fitted mesh, and 1 its four-child
refinement. Both percentages must be below 1%.

| Run / trial / degree / refinement | J | J check | J Gram | Quadrature | Gram agreement |
|---|---|---|---|---|---|
| 018 / R / RT3 / 0 | 0.2916532908392876 | 0.2916532908445700 | 0.2916532908414722 | 0.210744% | 0.087153% |
| 017 / D / RT3 / 0 | 0.2916532908334767 | 0.2916532908334767 | 0.2916532908357237 | 0% | 0.00469863% |
| 020 / R / RT2 / 1 | 0.2916532908391787 | 0.2916532908463350 | 0.2916532908345222 | 0.285514% | 0.185784% |
| 019 / D / RT2 / 1 | 0.2916532908341170 | 0.2916532908341166 | 0.2916532908294547 | 8.1254e-07% | 0.00974897% |
| 022 / R / RT4 / 0 | 0.2916532908388925 | 0.2916532908441750 | 0.2916532908300360 | 0.210784% | 0.353387% |
| 021 / D / RT4 / 0 | 0.2916532908330967 | 0.2916532908330968 | 0.2916532908242579 | 3.48239e-07% | 0.0184828% |

### What R costs

Each flux quadrature point set evaluates R once. Primary-order values are
cached for the subsequent functional check, then released template by
template. Each run contains one degree; no field cache is retained between
runs. J needs trial values only. Its quotient reuses the Fourier energy
identity from theta-v1, so pointwise trial gradients are unnecessary here.

The timing categories below are disjoint. The primary check reuses cached
values. The higher-order check column excludes field evaluation, already
counted in the first timing column. Solve time includes condensation,
the global solve and recovery. Other time includes geometry, input loading,
bookkeeping and MATLAB startup.

| R run / degree / refinement | Field values | Assembly | Solve | Primary check | Higher-order check | Normalization | Other/startup | Total wall |
|---|---|---|---|---|---|---|---|---|
| 018 / RT3 / 0 | 374.04 | 2.26 | 3.43 | 6.18 | 14.02 | 15.41 | 16.64 | 431.99 |
| 020 / RT2 / 1 | 403.91 | 2.73 | 13.95 | 6.28 | 12.23 | 17.58 | 22.82 | 479.52 |
| 022 / RT4 / 0 | 392.36 | 3.97 | 6.36 | 8.86 | 20.77 | 16.37 | 16.31 | 465.01 |

All times are seconds, taken from the result's `timing` and
`field_evaluation_detail` plus its monitor. For run-018, field evaluation
splits into `114.23 s` at the primary order and `259.80 s` at the check
order; all 408 primary batches are reused. Run-020 reuses 1,601 batches.
The cache avoids repeating the measured primary-order field work. The
main field-evaluation cost remains, so a cache across separate degree runs
has not been included in these timings.

At RT3, R's interval is 19.08 times narrower than D's,
while its wall time is 5.73 times larger. Field evaluation
accounts for 86.59% of R's wall time
([cost ratios](output/run-022/study-summary.json)).

### Meaning for the target

The observed R plateau is near `qJ-1=8.6e-9`. Width `1e-7` requires
`qJ-1=4.55610e-9` with these edges. Stabilization, one mesh refinement and
RT4 leave the width near `1.89e-7`; the original `5.8e-7` target is met.
The numerical results support a trial-dependent floor, while the exact
minimum over all fluxes remains uncomputed.

For the exact source functional
$G=\langle v,(A+1)^{-1}v\rangle_\rho/\|v\|_\rho^2$,
$$qJ-1=(qG-1)+q(J-G).$$
The containment argument gives `qG-1 >= 3.49774e-9` and width at least
`7.67705e-8`. Therefore `5.09641e-9` is an upper bound on the remaining
flux contribution for the old RT3 row. The difference from the containment
lower limit combines flux error and excess trial variance. An independently
converged source solve would
separate the two contributions, including the fixed-box flux restriction.
These arithmetic constraints are recorded in
[study-summary.json](output/run-022/study-summary.json).

### Reproduction and run budgets

The read-only input and MATLAB version are unchanged. All runs use two
MATLAB computational threads and the unchanged monitor, with escalated
permission, serial execution, 30 minutes soft, 40 minutes hard and 3 GiB
RSS limits. The following estimates were written before each launch.

| Run | Degree / trial / study / refinement | Estimated time / RSS |
|---|---|---|
| 016 | 3 / R / audit / 0 | 8–16 min / <2.9 GiB |
| 017 | 3 / D / stable / 0 | 1–3 min / <2.7 GiB |
| 018 | 3 / R / stable / 0 | 6–10 min / <2.9 GiB |
| 019 | 2 / D / stable / 1 | 2–6 min / <2.6 GiB |
| 020 | 2 / R / stable / 1 | 7–12 min / <2.9 GiB |
| 021 | 4 / D / stable / 0 | 2–5 min / <2.6 GiB |
| 022 | 4 / R / stable / 0 | 7–12 min / <2.9 GiB |

Run-016 took `405.13 s` at `2.600 GiB`. The fixed runs' measured costs are
in the results table. The refined D pilot used `2.178 GiB`, and the RT4 D
pilot used `2.238 GiB`; adding the approximately `0.66 GiB` primary R cache
supported their R forecasts. All seven runs completed within the limits.

For example, run-018 is reproduced by:

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-018 \
  "addpath('/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1'); goerisch_flux_study('/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03','/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-018/science',3,'R','stable',0);"
```

Use a fresh output number, and substitute the arguments from the table.
Every run retains its exact command in `command.json`. The postprocessor is:

```sh
python3 test/numerical-directions/goerisch-v1/summarize_flux_study.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1 \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v1/output/run-022
```
