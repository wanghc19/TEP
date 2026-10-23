# I9.3 FEM candidate delivery and historical timing comparison

This experiment runs FEM only. It does not call FMM, search a projected gap,
compute spectral distance, or compare numerical errors. Historical FMM data
are used only after independent FEM candidate delivery.

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

