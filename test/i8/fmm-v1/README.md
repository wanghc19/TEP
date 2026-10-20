# I8 smooth-proxy FMM2D comparison

This directory contains the bounded I8 experiment that replaces only the
smooth proxy-source callback used by `kernel.qpgreen_mfs_pairmat`.  The
center-image direct kernel, diagonal treatment, BIE construction and solve,
QZ/DtN calculation, matching matrices, weights, and singular-value definitions
remain unchanged.  This is a numerical comparison at five fixed points; it is
not a scan, a new candidate location, or a spectral certificate.

## Source and build record

The dependency is the official
[`flatironinstitute/fmm2d`](https://github.com/flatironinstitute/fmm2d) source
at commit `550dae5b77b1e006c8ffae37fc832f8c2b536871`; no release label is used.
The local checkout is `vendor/fmm2d`; its Apache-2.0
`LICENSE` is preserved.  That checkout is ignored by Git, while this README and
the experiment source are not ignored and are eligible for version control.

The existing arm64 toolchain was sufficient: GNU make 3.81, Homebrew gfortran
14.2, Apple clang 15, MATLAB R2023b, and the already installed `libgfortran`
and `libgomp`.  No package, compiler, toolbox, or OpenMP runtime was installed
or upgraded.  The official build route was:

```sh
git clone --no-tags --filter=blob:none \
  https://github.com/flatironinstitute/fmm2d.git vendor/fmm2d
git -C vendor/fmm2d checkout --detach \
  550dae5b77b1e006c8ffae37fc832f8c2b536871
cp vendor/fmm2d/make.inc.macos_arm64.gnu vendor/fmm2d/make.inc
make -C vendor/fmm2d -j4 matlab
```

During this run, GNU make completed the Fortran/OpenMP static library, but the
MATLAB MEX front end aborted twice inside the restricted sandbox with
`fl:filesystem:SystemError` and exit 134.  The same MEX link, using the same
local library and existing dependencies, succeeded outside that restriction:

```sh
/Applications/MATLAB_R2023b.app/bin/mex -v \
  matlab/fmm2d.c lib-static/libfmm2d.a \
  -compatibleArrayDims -DMWF77_UNDERSCORE1 \
  -L/opt/homebrew/Cellar/gcc/14.2.0_1/lib/gcc/current -D_OPENMP \
  -output matlab/fmm2d -lm -lstdc++ -ldl -lgfortran -lgomp
```

The failed logs are `output/attempt-1/build-01.log` and
`build-02-mex-verbose.log`; the complete successful output is
`build-03-success.log`.  The resulting `fmm2d.mexmaca64` is arm64.  The
linker warned that Fortran objects targeted macOS 14.0 while the MEX link
declared a minimum of 11.0.  It loaded and ran on the measured macOS 14.8.7
host, but that warning is a portability caveat for older macOS systems.

Official `hfmm2d.m` defines the kernel as

$$
G_k(x,y)=\frac{\mathrm{i}}4H_0^{(1)}(k\lVert x-y\rVert),
$$

so `proxy.q` is passed without another factor.  Sources and targets are
`2-by-n`, charges are complex `1-by-n`, gradient rows are `(x,y)`, and Hessian
rows are `(xx,xy,yy)`.  The bottom-level Fortran source and the five-point
actual-field comparisons both support this mapping.

## Entry points and timing boundary

- `fmm_i8_point.m` is the traceable copy of the frozen `locate_i8` point
  calculation.  It selects either the original 512-target direct callback or
  one complete FMM call per cell and returns the full `Adef` and `Aphys`.
- `run_fmm_i8.m` runs the five fixed points, accuracy comparisons, fixed
  third-tier trigger, and warmed performance protocol.
- `monitor.sh` enforces a single MATLAB process, a 30-minute wall limit, and a
  2 GiB process-tree RSS limit while recording load and other MATLAB processes.

The performance sample `outer_seconds` surrounds the complete
`fmm_i8_point(...)` call.  It includes input checks, model construction, FMM
input/output reshaping, FMM tree and reorder work, both cell constructions,
QZ/DtN, matching, weights, and both SVDs.  Raw-field comparison, matrix
differences, summary formation, file export, and MATLAB startup/exit are
outside that sample.  `point_seconds` is an auxiliary inner timer and is not
the reported performance denominator.  Each FMM point made exactly two FMM
calls: one lead and one center call, each with 320 sources and all 65,536
targets at once.  No tree, proxy result, or field was cached across cells or
points.

From the repository root, a fresh monitored run uses a new output directory:

```sh
OMP_NUM_THREADS=11 OMP_DYNAMIC=FALSE \
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
test/i8/fmm-v1/monitor.sh test/i8/fmm-v1/output/attempt-N/run-01 \
"repo=pwd; addpath(repo); addpath(fullfile(repo,'test','i8','locate-v1')); addpath(fullfile(repo,'test','i8','fmm-v1')); addpath(fullfile(repo,'test','i8','fmm-v1','vendor','fmm2d','matlab')); run_fmm_i8(fullfile(repo,'test','i8','fmm-v1','output','attempt-N','run-01'));"
```

The MATLAB entry itself accepts only the output directory and does not read
Markdown, Git metadata, historical results, or a machine-specific path.

The five literal points and their provenance are:

| Point | $k$ | Existing I8.1 record |
|---|---:|---|
| `far_left` | `1.7562800000000001` | locate-v1 run-04, row 7 |
| `near_left` | `1.7562818432000002` | locate-v1 run-07, row 6 |
| `k0` | `1.7562818500073463` | locate-v1 run-17, row 10; run-18, row 2 |
| `k1` | `1.7562818560000002` | locate-v1 run-07, row 7 |
| `far_right` | `1.7562832000000002` | locate-v1 run-04, row 9 |

## Run 01 results

The formal run is `output/attempt-1/run-01`.  It completed with exit 0 in
199.294 seconds.  Peak sampled process-tree RSS was 1,155,547,136 bytes; no
other MATLAB process was present before or during the run.  MATLAB reported
R2023b on `MACA64`, 11 computation threads, `OMP_NUM_THREADS=11`, and
`OMP_DYNAMIC=FALSE`.  The sampled 1-minute load ranged from 2.716 to 13.416,
so the fixed cyclic method order remains relevant when reading small timing
differences.

All five original calls reproduce the stated historical four-metric rows
exactly in binary64, and the diagnostic direct copy is bitwise equal to its
same-process original call at every point.  The CSV writer displays about 15
digits; `result.json`, the raw MAT files, and the 17-digit source literals are
the authority for exact values.

Every one of the 20 validation FMM cell calls returned `ier=0`; every shape
and finite check passed.  The performance protocol added 32 FMM cell calls,
for 52 FMM calls in the formal run, all successful.  The minimum source-target
distance in the captured validation calls was 0.299066, far from the
coincidence threshold.  All 120 component rows passed the preregistered
engineering threshold.  The direct and FMM callback source, charge, and target
arrays were bitwise identical for every captured lead/center pair.  The
largest scale-safe field errors were:

| Requested FMM tolerance | max scaled infinity error | max scaled Frobenius error |
|---:|---:|---:|
| `1e-10` | `2.440e-11` | `1.498e-11` |
| `1e-12` | `7.200e-13` | `3.354e-13` |

The lead and center direct smooth evaluations had median times 3.772 and
3.605 seconds.  Their FMM medians were about 0.281 and 0.282 seconds at
`1e-10`, and 0.292 and 0.291 seconds at `1e-12`.  There is no material
lead/center asymmetry in the FMM call itself for these five points.

The downstream matrix comparison also passed every engineering threshold and
every recorded Weyl check:

| Requested tolerance | max `Adef` relative Frobenius | max `Adef` spectral difference | max `Aphys` relative Frobenius | max `Aphys` spectral difference |
|---:|---:|---:|---:|---:|
| `1e-10` | `3.294e-16` | `6.039e-13` | `1.419e-14` | `2.691e-13` |
| `1e-12` | `2.941e-16` | `4.354e-13` | `7.986e-16` | `1.207e-14` |

`Aphys` improves clearly when the request is tightened.  `Adef` is already at
a relative Frobenius plateau near binary64 roundoff; its absolute spectral
difference decreases only modestly.  The preregistered ten-matrix median
contraction was 9.345, but that aggregate must not be read as uniform
convergence of every matrix measure.

The complete four-metric comparison is split below for readability.  Absolute
differences use the same-point diagnostic direct result.

| Point | FMM tolerance | direct `adef_sigma` | FMM `adef_sigma` | absolute difference | direct `adef_ratio` | FMM `adef_ratio` | absolute difference |
|---|---:|---:|---:|---:|---:|---:|---:|
| `far_left` | `1e-10` | `1.5876231719907793e-05` | `1.5876231838851944e-05` | `1.189442e-13` | `2.6277513150613766e-08` | `2.6277513347483937e-08` | `1.968702e-16` |
| `near_left` | `1e-10` | `5.841854800507074e-08` | `5.8418671809303598e-08` | `1.238042e-13` | `9.6691342793425702e-11` | `9.6691547707753826e-11` | `2.049143e-16` |
| `k0` | `1e-10` | `9.0463849720091667e-14` | `4.3466458183172583e-13` | `3.442007e-13` | `1.4973105978156506e-16` | `7.1943421254512991e-16` | `5.697032e-16` |
| `k1` | `1e-10` | `5.1427176954783761e-08` | `5.1427047045350792e-08` | `1.299094e-13` | `8.5119588994282451e-11` | `8.5119373974944557e-11` | `2.150193e-16` |
| `far_right` | `1e-10` | `1.1585222925247052e-05` | `1.1585222799794212e-05` | `1.254528e-13` | `1.9175258534932009e-08` | `1.9175258327288989e-08` | `2.076430e-16` |
| `far_left` | `1e-12` | `1.5876231719907793e-05` | `1.5876231704970208e-05` | `1.493759e-14` | `2.6277513150613766e-08` | `2.6277513125889874e-08` | `2.472389e-17` |
| `near_left` | `1e-12` | `5.841854800507074e-08` | `5.8418534706038634e-08` | `1.329903e-14` | `9.6691342793425702e-11` | `9.6691320781559292e-11` | `2.201187e-17` |
| `k0` | `1e-12` | `9.0463849720091667e-14` | `8.2563260342289218e-14` | `7.900589e-15` | `1.4973105978156506e-16` | `1.3665441508760589e-16` | `1.307664e-17` |
| `k1` | `1e-12` | `5.1427176954783761e-08` | `5.1427184594920566e-08` | `7.640137e-15` | `8.5119588994282451e-11` | `8.511960163983967e-11` | `1.264556e-17` |
| `far_right` | `1e-12` | `1.1585222925247052e-05` | `1.1585222941940843e-05` | `1.669379e-14` | `1.9175258534932009e-08` | `1.917525856256272e-08` | `2.763071e-17` |

| Point | FMM tolerance | direct `aphys_sigma` | FMM `aphys_sigma` | absolute difference | direct `aphys_ratio` | FMM `aphys_ratio` | absolute difference |
|---|---:|---:|---:|---:|---:|---:|---:|
| `far_left` | `1e-10` | `7.8518431836730985e-06` | `7.8518432420310801e-06` | `5.835798e-14` | `2.7494686301593299e-06` | `2.7494686505943961e-06` | `2.043507e-14` |
| `near_left` | `1e-10` | `2.8891800391280084e-08` | `2.8891861780655644e-08` | `6.138938e-14` | `1.0117017608828445e-08` | `1.0117039105494554e-08` | `2.149667e-14` |
| `k0` | `1e-10` | `4.3645331331577957e-14` | `2.152085411469092e-13` | `1.715632e-13` | `1.5283249311405522e-14` | `7.5359395562940907e-14` | `6.007615e-14` |
| `k1` | `1e-10` | `2.5434108843217626e-08` | `2.5434044701005134e-08` | `6.414221e-14` | `8.9062407543503152e-09` | `8.9062182937248629e-09` | `2.246063e-14` |
| `far_right` | `1e-10` | `5.7296486607576744e-06` | `5.7296485986712944e-06` | `6.208638e-14` | `2.0063488307499211e-06` | `2.0063488090091087e-06` | `2.174081e-14` |
| `far_left` | `1e-12` | `7.8518431836730985e-06` | `7.8518431759975181e-06` | `7.675580e-15` | `2.7494686301593299e-06` | `2.7494686274715863e-06` | `2.687744e-15` |
| `near_left` | `1e-12` | `2.8891800391280084e-08` | `2.8891793730464212e-08` | `6.660816e-15` | `1.0117017608828445e-08` | `1.0117015276416112e-08` | `2.332412e-15` |
| `k0` | `1e-12` | `4.3645331331577957e-14` | `4.0734437675046815e-14` | `2.910894e-15` | `1.5283249311405522e-14` | `1.4263944104766683e-14` | `1.019305e-15` |
| `k1` | `1e-12` | `2.5434108843217626e-08` | `2.5434112793630254e-08` | `3.950413e-15` | `8.9062407543503152e-09` | `8.9062421376630271e-09` | `1.383313e-15` |
| `far_right` | `1e-12` | `5.7296486607576744e-06` | `5.7296486690255817e-06` | `8.267907e-15` | `2.0063488307499211e-06` | `2.0063488336450928e-06` | `2.895172e-15` |

The corresponding `Aphys` matrix differences are:

| Point | FMM tolerance | spectral absolute | spectral relative | Frobenius relative |
|---|---:|---:|---:|---:|
| `far_left` | `1e-10` | `2.602557e-13` | `9.113336e-14` | `1.365205e-14` |
| `near_left` | `1e-10` | `2.646153e-13` | `9.266013e-14` | `1.393707e-14` |
| `k0` | `1e-10` | `2.652140e-13` | `9.286978e-14` | `1.401840e-14` |
| `k1` | `1e-10` | `2.657525e-13` | `9.305835e-14` | `1.405976e-14` |
| `far_right` | `1e-10` | `2.690838e-13` | `9.422496e-14` | `1.418857e-14` |
| `far_left` | `1e-12` | `8.671261e-15` | `3.036403e-15` | `5.723457e-16` |
| `near_left` | `1e-12` | `1.044829e-14` | `3.658670e-15` | `7.316838e-16` |
| `k0` | `1e-12` | `1.178677e-14` | `4.127362e-15` | `7.985801e-16` |
| `k1` | `1e-12` | `1.087478e-14` | `3.808013e-15` | `7.532307e-16` |
| `far_right` | `1e-12` | `1.207216e-14` | `4.227305e-15` | `7.794369e-16` |

At the candidate, direct gives
`aphys_sigma=4.3645331331577957e-14` and
`aphys_ratio=1.5283249311405522e-14`.  FMM gives respectively
`2.15208541146909e-13`, `7.53593955629409e-14` at `1e-10`, and
`4.07344376750468e-14`, `1.42639441047667e-14` at `1e-12`.  The tighter FMM
result lying slightly below the direct singular value is not evidence of
greater accuracy; the matrix perturbation scale is the correct comparison.
Both tolerances preserve the ordering: the candidate remains the smallest of
the five ratios, the near points remain below the far points, and no claim is
made about an unmeasured scan.

The `1e-14` tier was not run.  All three fixed trigger predicates were false:
the candidate-floor predicate, median-contraction predicate, and individual
degradation predicate.  The two requested tolerances remain in the evidence
regardless of this decision.

The warmed complete-point timings use three repeats and report the median of
`outer_seconds`:

| Point | Method | min (s) | median (s) | max (s) | direct/FMM median |
|---|---|---:|---:|---:|---:|
| `k0` | direct | 7.869 | 8.022 | 8.075 | 1.00 |
| `k0` | FMM `1e-10` | 1.269 | 1.287 | 1.395 | 6.23 |
| `k0` | FMM `1e-12` | 1.203 | 1.253 | 1.281 | 6.40 |
| `k1` | direct | 7.803 | 7.982 | 8.080 | 1.00 |
| `k1` | FMM `1e-10` | 1.176 | 1.222 | 1.397 | 6.53 |
| `k1` | FMM `1e-12` | 1.189 | 1.223 | 1.242 | 6.52 |

Thus both tolerances are acceptable under the preregistered engineering
checks for this frozen five-point experiment, and both reduce warmed complete
point time at both performance points.  `1e-12` has substantially smaller
field and `Aphys` perturbations with no measured median-time penalty.  This is
a conditional numerical replacement for the frozen configuration, not a
strict FMM error bound, a new candidate location, a full-scan result, or a
continuous-spectrum certification.

There is no blocker for this bounded experiment.  The important caveat is that
the candidate metrics lie at the same scale as the remaining matrix
perturbation, so the five-point result cannot establish binary64 platform
agreement or certify the candidate.  Minor caveats are the macOS deployment
warning, the variable host load during timing, and the reduced display
precision of the convenience CSV exports.

## Evidence map

- `output/attempt-1/run-01/result.mat` and `result.json`: aggregate validation,
  trigger, and timing records.
- `raw/direct-*.mat`: complete diagnostic-direct matrices and actual lead and
  center callback inputs/fields.
- `raw/fmm-*.mat`: complete FMM matrices, both raw direct/FMM field sets,
  component summaries, FMM `ier/timeinfo`, and matrix/metric comparisons.
- `validation.csv`, `field-errors.csv`, `performance-calls.csv`, and
  `performance-summary.csv`: review tables.
- `resources.csv`, `system-preflight.json`, `status.txt`, and `command.txt`:
  environment, resource, and exact-launch evidence.
- `output/attempt-1/check-01`: monitored MATLAB Code Analyzer check; exit 0,
  17.093 seconds, peak RSS 812,613,632 bytes.  Its five notices are performance
  suggestions or an intentional cleanup-guard lifetime, not syntax errors.

