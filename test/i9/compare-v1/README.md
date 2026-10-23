# I9.3 FEM candidate timing and fixed-frequency BIE reconstruction

The original I9.3 timing experiment below runs FEM only; its contract and
results remain unchanged. The separately authorized continuation at the end
reconstructs one BIE/FMM field at the fixed delivered FEM frequency and evaluates
the existing spectral-distance formula. It does not rerun FEM or optimize k.
This continuation is a main-agent self-check, not a new independent review.

## Frozen configuration

`fem_i9_config.m` is the sole scientific configuration. The current model is
$\beta=0.5$, $d=L=1$, background coefficient 1, center relative permittivity 4,
and lead relative permittivity 17. The center is the native unscaled star,
including its internal 0.2 factor. Negative and positive leads use the
same global orientation with three-lobe amplitudes 0.12 and 0.20.

The known frequency window is
`[1.4509999999999998, 2.2490000000000001]`. There are six complete lead cells
on either side of the center, giving the domain $[-6.5,6.5]\times[-0.5,0.5]$.
The background grid scale is $h=1/12$; each inclusion has 80 parameter
segments. Material interface vertices and P2 midpoints lie on the analytic
curve. The intervening P2 trace is a quadratic approximation. All interfaces
are shared by adjacent material regions. Each cell wall is constrained.

Assembly uses curved isoparametric P2 elements and an $8\times8$ tensor-Duffy
quadrature rule. The equation is $-\Delta u=\mu\rho u$, $k=\sqrt\mu$.
Far x ends have homogeneous Dirichlet conditions; top values equal
$\exp(i\beta d)$ times bottom values, including edge-midpoint DOFs.

Three shifts are the centers of equal subintervals of the squared window:
`2.597501`, `3.5817010000000002`, `4.565901`. Each requests 12 roots,
with tolerance `1e-10`, maximum 1000 iterations, subspace dimension 40,
and deterministic random seed 193. This is a finite inventory, not a
proof that all window eigenpairs have been obtained.

All Ritz pairs are retained. Candidate acceptance requires solver flag zero,
positive nearly-real eigenvalue, relative algebraic residual at most `1e-8`,
window membership, center-cell weighted mass at least 0.15, three-cell core
mass at least 0.60, and combined outermost-two-cell mass on both sides at
most 0.02. Pairs are deduplicated only when both $|\Delta k|\le10^{-6}$ and
mass overlap at least 0.90 hold; the lowest-residual representative is kept.
The preflight uses three cells, $h=1/6$, 40 interface segments and three
roots only to check implementation and resources; it delivers no candidates.

## From-zero commands

No historical output is needed. Use the installed MATLAB and Python; the
launcher adds this directory to the MATLAB path. From the repository root:

```sh
conda run -n octave python test/i9/compare-v1/run_fem.py \
  --mode preflight --output test/i9/compare-v1/output/attempt-1/preflight-01 \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab
conda run -n octave python test/i9/compare-v1/run_fem.py \
  --mode formal --output test/i9/compare-v1/output/attempt-1/run-01 \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab
```

The MATLAB executable path is a launcher argument; numerical code has no
absolute-path or old-experiment dependency. Each output directory must be
new. All operational fixes stay within the attempt, using a new run name.
The automatic monitor enforces 2400 seconds and 3,000,000,000 process-tree
RSS bytes, refuses concurrent MATLAB, samples once per second, and kills
its process group on interruption. Necessary continued batches must pass
`--prior-status` so the budget start is retained. No such continuation is
required by the one-process formal implementation.

`evidence.mat` retains full/reduced forms, mesh, constraints, all eigenvectors,
regional mass forms and diagnostics. `modes.csv` and `summary.json` retain
all roots and the filters. Timings are exclusive mesh, assembly/constraint,
eigensolve and delivery checks; save/export and process overhead are separate.
The inherited I4 element formulas are identified in MATLAB headers. No I4
geometry, horizontal Bloch condition, historical target or controller is used.

## Current results

Formal authority is `output/attempt-1/run-02`. The run delivered one candidate:

| Quantity | FEM result |
|---|---:|
| $k$ | 1.5584630910866906 |
| $\mu$ | 2.4288072062794823 |
| relative algebraic residual | 1.1205551316481714e-13 |
| center-cell mass fraction | 0.5587263771753322 |
| three-cell core fraction | 0.9365097037405425 |
| all negative / positive lead fraction | 0.21922472746539007 / 0.22204889535927771 |
| negative / positive outer-two-cell fraction | 0.0001004556893433309 / 0.00011790687954624385 |
| combined end fraction | 0.00021836256888957476 |
| triangles / full P2 DOFs / reduced DOFs | 9750 / 19837 / 19476 |

All three eigensolver calls returned flag zero. The 36 requested Ritz records
contain three window entries (IDs 1, 13 and 30), which form one duplicate
group by the frozen frequency-and-mass-overlap rule. ID 1 has the lowest
residual and is the delivered representative. Across the whole returned
inventory there are 16 duplicate records and 20 representatives; the other
19 representatives lie outside the known window. No nonconverged or
window-internal end-localized mode was observed in this finite inventory.
This does not guarantee completeness of the window spectrum.

The minimum curved Jacobian over every full reference triangle is
`2.087949976980942e-05`; the domain area is `13.000000000000158`.
All material constraints are shared P2 edges. Top/bottom and Dirichlet
constraint defects are zero. Reduced Hermitian defects are
`2.4010379291536367e-18` (stiffness) and
`4.208779785994885e-17` (mass); the mass Cholesky flag is zero.
Curved represented inclusion areas are `0.1941489084976929` for the center,
`0.7539819662439897` for all six negative leads and `0.7539815987336402`
for all six positive leads. These are geometry-discretization records, not
exact analytic areas or a spatial-error study.

| Mutually exclusive formal stage | Seconds |
|---|---:|
| mesh generation | 0.14169579166666665 |
| assembly, constraints and SPD checks | 0.3538094583333333 |
| three eigensolver calls and loop overhead | 0.8385349166666667 |
| deduplication, filtering and delivery checks | 0.11690079166666667 |
| **candidate-delivery algorithm sum** | **1.4509409583333333** |
| raw evidence save and export | 0.7802710833333333 |
| MATLAB entry function, including remaining setup | 2.249100416666667 |
| complete monitored process, including startup/exit | 16.722826417069882 |

The single-batch UTC start-to-finish span is `16.723256` seconds. The sampled
formal process-tree peak is **1,281,654,784 bytes**, exit code zero, with no
surviving child process. MATLAB is R2023b on `MACA64`, using 11 MATLAB/OpenMP
threads. The launcher explicitly sets `OMP_DYNAMIC=FALSE`. Sampling is once per second and is not an instantaneous-memory
certificate. Assembly and delivery timing include the corresponding checks;
inner eigensolver timing is a subset, not an additional cost.

### Historical FMM comparison after FEM delivery

The I9.1 material-4 baseline remains untouched. Its tracked search README and
available `output/attempt-3/run-02` records report
$k=1.5584378941820909$, 266 matching requests, 213 actual matching calls,
53 point-cache hits, and two fresh confirmations. Its candidate-delivery
stages are coarse search `39.87983062500001` seconds, fine refinement
`508.24273658333317` seconds and fresh confirmations `5.739799666666666`
seconds, totaling **553.8623668749999 seconds**. Gap exploration
`28.40966425` seconds and standalone representative/degeneracy validation
`12.955570791666666` seconds are excluded from this core-stage comparison.
The residual historical process overhead cannot be reliably assigned solely
to candidate delivery and is not apportioned by guesswork.

| Fixed-configuration observation | Current FEM | Historical FMM |
|---|---:|---:|
| candidate $k$ | 1.5584630910866906 | 1.5584378941820909 |
| isolated candidate-delivery stages, seconds | 1.4509409583333333 | 553.8623668749999 |
| complete historical/current science process, seconds | 16.722826417069882 | 642.9869550421136 |
| sampled peak RSS, bytes | 1,281,654,784 | 1,422,639,104 |

The ratio of the isolated stage sums is **381.7263** (historical FMM / current
FEM). It is a non-simultaneous, fixed-configuration delivery-cost observation,
**not a same-accuracy speedup**. FEM uses finite truncation and finite Ritz
requests, while FMM searches and refines a matching dip to a tiny interval.
The complete FMM process also includes gap and validation work and is shown
for context only; it is not divided by FEM eigensolver time. No difference
between candidate values is called an actual error, and no error comparison
or convergence experiment was performed.

### Preflight and failure accounting

All records remain in `output/attempt-1/operational-history.json` and their
individual run directories. None enters the successful algorithm ratio.

| Run | Outcome | Process seconds | Sampled peak bytes |
|---|---|---:|---:|
| preflight-01 | sandbox denied `ps`; no MATLAB started | 0.003449333 | 0 |
| preflight-02 | small solve finished; output-struct initialization failed | 16.801836083 | 924,368,896 |
| preflight-03 | implementation/resource checks passed; no candidates selected | 14.713278375 | 956,203,008 |
| run-01 | automatic RSS stop during assembly/constraint stage | 6.664054000 | **3,190,554,624** |
| run-02 | formal delivery succeeded | 16.722826417 | 1,281,654,784 |

The first formal implementation attempted a natural-order sparse Cholesky
check, which is a plausible source of excessive fill. The successful
equivalent repair is consistent with this explanation, but no independent
allocation profile established the exact allocation site. The operational
repair applies the same
AMD permutation to both reduced forms, requests a sparse reordered Cholesky,
and undoes the permutation on eigenvectors before all residuals and mass
checks. The model, mesh, shifts, tolerances and filters were unchanged.
The actual failed sampled peak exceeded the hard threshold; the monitor
terminated the process and verified cleanup. It is not claimed that every
attempt remained below 3 GB.

### Independent audit and limitations

Independent source/raw-result audit passed **30,569 checks**, with no blocker.
The Skeptic reconstructed all 9750 curved elements, the original-coordinate
constraints, all 36 Ritz residuals, regional masses, and dedup/filter decisions.
Independent stiffness/mass assembly relative defects were
`1.5120201666028022e-14` / `2.9776229869247803e-15`. The audit command and
stdout are preserved under `run-02/review/`; audit time is excluded from FEM
algorithm and process timings. The full review is recorded in
`research/projects/eig-apost/implementation/i9/review-9-3a.md`.
The audit is reproducible with `audit_fem.py` using an already installed
Python with NumPy. It does not call MATLAB or rerun the eigensolver. On the
execution host the existing bundled Python supplies NumPy; the project
Conda `octave` environment supplies the standard-library monitor. No package
was installed. An explicit audit command (choose a new audit output name) is:

```sh
mkdir -p test/i9/compare-v1/output/attempt-1/run-02/review
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 \
  /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  test/i9/compare-v1/audit_fem.py test/i9/compare-v1/output/attempt-1/run-02 \
  > test/i9/compare-v1/output/attempt-1/run-02/review/audit.json
```

The saved raw matrix export uses separate real/imaginary columns and
little-endian float64 column-major arrays described by `raw-audit.json`;
it requires no SciPy to inspect. The evidence MAT retains the same objects.

Finite truncation, quadratic geometry and finite shifts/requests are scope
and coverage limitations. No mesh/truncation convergence or same-accuracy
comparison was attempted. There is no spectral-distance computation.


## Continuation: fixed FEM candidate, BIE reconstructed spectral-distance estimate

This is **固定FEM candidate的BIE重构谱距离数值估计**. Only the FEM frequency
`1.5584630910866906` is used. No FEM vector or historical density is loaded.
It is not an error estimate for the native FEM field. This continuation does
not change the earlier FEM timing experiment or claim an independent review.

`reconstruct_i93_config.m` is the unique configuration for this continuation.
It preserves the actual I9.2 inputs, with only k and metadata labels changed:
center/negative/positive nodes512/256/256, M48/K97, nside/ntop160,
nproxy80, mpw32, H1.1, proxy_dist0.2, beta0.5, center star_scale1/rho4,
negative/positive trilobes0.12/0.20/rho17, background1, FMM tolerance1e-12.
Material/wall evaluation uses768 points, each lead40 cells and separate numerical
tails; wall_batch64, mass_batch32. Mass is the local background disk at
$(0,3/8)$, radius1/16, 32×64 half-angle-shifted nodes. Geometry uses4096/8192
samples, collar0.004, arc_band0.01 and the same I9.2 trace formula.

`reconstruct_i93.m` migrates only the required numerical evaluator and local
geometry/classification helpers from I9.2. It independently builds three cells,
uses the physical column-scaled minimum right singular vector, normalizes its
Euclidean norm and positive-real maximum component, and freezes the density
and propagation state once. Evaluation at768 points only interpolates the
frozen density. Smooth proxy fields use FMM; free-space/Kress/singular terms
and the existing directly evaluated regular diagonal remain unchanged.
There is no small-singular-value acceptance gate or frequency correction.

Top/bottom periodic seams remain theoretical zero for the exact-QP mathematical
field; their numerical consistency diagnostics are saved separately and excluded
from the original epsilon formula. All required material and longitudinal-wall
finite terms and tails are included. Only a positive denominator permits a finite
`UNCERTIFIED_RNUM`.

### From-zero reconstruction and self-check

From the repository root, using installed tools and a fresh output identity:

```sh
conda run -n octave python test/i9/compare-v1/run_fem.py --entry reconstruct \
  --output test/i9/compare-v1/output/attempt-1/reconstruct-01 \
  --package-root /Users/whc/Documents/Work/epost \
  --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab
mkdir -p test/i9/compare-v1/output/attempt-1/reconstruct-01/selfcheck
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 \
  /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  test/i9/compare-v1/check_reconstruct.py \
  test/i9/compare-v1/output/attempt-1/reconstruct-01 \
  > test/i9/compare-v1/output/attempt-1/reconstruct-01/selfcheck/check-01.json
```

Paths are explicit launcher examples; numerical MATLAB functions use ordinary
path resolution and no directory inference, history, Markdown, Git or hashes.
Only installed FMM2D is resolved from its vendor path, not an old experiment entry.
`--entry reconstruct` calls `run_reconstruct_i93`, never `fem_i9_run`.
The same local monitor enforces40min/3,000,000,000 bytes, rejects concurrent
MATLAB, samples RSS and cleans the process tree. Output directories must be new;
operational retries use reconstruct-02 etc within the same attempt. Original
FEM run directories are preserved. No preflight or second scientific batch was
needed in this continuation.

### Actual continuation result: attempt-1/reconstruct-01

| Quantity | Value |
|---|---:|
| Fixed k | **1.5584630910866906** |
| Actual binary64 k*k | 2.4288072062794823 |
| adef_sigma / adef_ratio | 0.0003072570853809984 / 5.085541227475573e-7 |
| aphys_sigma / aphys_ratio | 0.00016586532312818552 / 4.632113870520935e-5 |
| C_num | 9.5778611959313427 |
| epsilon_num | 0.00030727040364047489 |
| U_num | 0.1234196046988323 |
| Q_num | 0.0029429932756862651 |
| U_num-Q_num | **0.12047661142314603** |
| R_num | **0.11866142633964537** |
| Status | **UNCERTIFIED_RNUM** |

Both leads have97 stable/97 unstable modes, with no near-unit, uncertain or
indeterminate classifications. The inverse negative pencil also passes.
The new q norm is0.9999999999999998; component146 is the positive-real phase
anchor. The maximum internal fixed-field check defect is2.0603073386301774e-13,
below the unchanged1e-10 gate. All215 FMM calls return ier0.

| Jump source | Value squared, finite/single | Normal squared, finite/single |
|---|---:|---:|
| Center material | 1.549253881393317e-29 | 1.5895918423517847e-24 |
| Negative material40 | 1.0070806828922435e-30 | 8.99857773595241e-29 |
| Positive material40 | 1.0514975847982383e-30 | 9.947002755160048e-29 |
| Left junction | 1.5271318111743475e-27 | 4.7908394950857145e-8 |
| Right junction | 1.5476447470688144e-27 | 4.650670600252322e-8 |
| Negative walls40 | 1.1523333006223523e-27 | 6.662205467029817e-26 |
| Positive walls40 | 1.414627920208404e-27 | 1.2224051435405234e-25 |

| Numerical tail | Value squared | Normal squared |
|---|---:|---:|
| Negative material | 1.3040916967543603e-64 | 1.1644610115212147e-62 |
| Positive material | 5.724422290259699e-64 | 5.418590042297253e-62 |
| Negative walls | 1.4946548875230524e-61 | 8.622360748240968e-60 |
| Positive walls | 7.709544943772479e-61 | 6.658821515233862e-59 |

All four tails are available; negative ratios are approximately0.14219692054,
positive0.14739497040. Totals are value_squared5.659288896155542e-27 and
normal_squared9.441510095338036e-8. Left/right junction normal jumps contribute
approximately50.7423%/49.2577% of the total. No required term was zeroed.
Separate periodic diagnostic value/normal squares are center
4.457631143790577e-28/3.510885776796606e-27, negative
4.9138556499535117e-29/3.2058434070146733e-28, positive
7.7626853852775e-29/5.819393169110105e-28.

The unchanged actual-geometry checks pass; theta0.7428571428571429 and
curvature_max64.28571428571426. The disk's sampled curve clearance is
0.08315076090331691 and wall/periodic clearance0.0625, exceeding twice the collar.
U remains a local disk mass norm, not a full-waveguide integral.

| Exclusive timing | Seconds |
|---|---:|
| Field construction/freeze | 3.2540724583333334 |
| Material jumps | 9.442822541666667 |
| Longitudinal walls | 29.185655916666665 |
| Periodic consistency diagnostic | 19.208633416666668 |
| Local mass | 8.420549791666666 |
| Geometry/scalar assembly | 6.109614916666667 |
| Stage sum / numerical function | 75.62134904166668 / 75.62383166666666 |
| Serialization and MAT export | 4.080915875 |
| MATLAB driver | 79.72312741666667 |
| Complete monitored process | **98.16553341597319** |

Final JSON/log writing is covered by process time; inner FMM62.18798158333336s
is nested and not added again. UTC span98.166423s; one process, exit0,
no concurrent MATLAB or survivors; peak sampled RSS **1,423,163,392 bytes**.
EnvironmentR2023b/MACA64, MATLAB/OpenMP11, OMP_DYNAMIC=FALSE. No failed run or retry
occurred in this continuation; prior FEM failures remain separate historical costs.

`evidence.mat` preserves the fresh field, matrices, interpolated densities,
propagation, every finite/tail term and mass samples. `result.json`, `config.json`,
`components.csv`, `timing.json`, commands, resources and logs retain scalar ledgers.
`selfcheck/check-01.json` records **91 main-agent checks, PASS**; reassembled scalars
have maximum relative difference1.7642476457870755e-16. This is **not an independent
review**. The self-check reuses only the MAT reader from I9.2; it does not copy its
old audit flow or launch MATLAB.

For historical context only, I9.2 used k1.5584378941820909 and a different BIE field,
with R_num7.745852555568109e-10. The two values do not rank actual errors or prove
mode identity. Sampled geometry, numerical tails and FMM/quadrature are uncertified;
no new method, direct comparison, sensitivity or frequency correction was attempted.
