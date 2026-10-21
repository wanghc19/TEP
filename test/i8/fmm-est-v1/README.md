# I8.4b FMM spectral-distance estimate

This isolated experiment constructs a fresh center-512/lead-256 field at the
explicit literal $k_0=1.7562818500073423$. It uses the run-05 resolvent route:
physical material and artificial-wall jumps, 40 lead cells per side with the
same observed geometric-tail candidates, and a local disk mass. The result
remains `UNCERTIFIED_RNUM`.

## Implementation and reproduction

`fmm_est_i8(k0,output_dir)` contains the required local helpers copied from
`estimate-v1/estimate_i8.m`. The smooth-proxy callback follows
`fmm-v1/fmm_i8_point.m`, with FMM2D requested tolerance fixed at `1e-12`.
Public packages and earlier experiments are untouched. Numerical execution
uses normal MATLAB path resolution and explicit inputs; it does not load
historical results, documentation, repository metadata, or a presumed
repository directory layout.

From the package root, choose a new output run directory and execute:

```sh
bash test/i8/fmm-est-v1/launch.sh test/i8/fmm-est-v1/output/attempt-N/run-01
```

The launcher adds the package root, this experiment, and the already installed
FMM2D MATLAB directory. It sets `OMP_NUM_THREADS=11`, `OMP_DYNAMIC=FALSE`, and
uses `/Applications/MATLAB_R2023b.app/bin/matlab` unless `MATLAB_BIN` is supplied.
These launcher paths describe this machine; the numerical function has no
hard-coded dependency paths. No installation is performed. The exact actual
commands, source snapshots, dependency commit, Code Analyzer output, process
logs, and resource samples are retained under each run.

The source freezes $\beta=0.5$, $M=48$, the $(160,160,80,32)$ proxy tuple,
$H=1.1$, proxy distance $0.2$, circle radius $0.2$, lead permittivity $17$,
center permittivity $2$, and the six-row star scale $\sqrt{0.04/0.0618}$.
The [shared symbol ledger](../../../research/projects/eig-apost/implementation/i8/SYMBOLS.md)
maps the source quantities and new execution fields.

## Coverage and fixed-field comparison

One FMM construction determines the matching vector, its normalization and
phase, the physical densities, lead propagation, proxy coefficients, and
Rayleigh coefficients. FMM evaluates that same field on the 512 and 768
material/wall grids and the original two disk grids. The 768 grid is primary;
the native center 512 grid is diagnostic.

The direct check replaces only `i8_pars.h2d_evaluator` in copies of the two
cell maps. It does not re-solve any field, density, matching vector, or
propagation coordinate. The same local routines reevaluate the complete
768 material/wall jumps and the fine $32\times64$ shifted disk mass. Exact
saved equality checks cover the field and the unchanged cell maps. The
comparison includes $C_{\rm num}$, $\epsilon_{\rm num}$, $U_{\rm num}$,
$Q=C_{\rm num}\epsilon_{\rm num}$, $D=U_{\rm num}-Q$, and
$R_{\rm num}=2k_0^2Q/D$, with a positive-denominator gate.

Only smooth proxy potentials, gradients, and Hessians use FMM. Singular
free-space/Kress/jump terms and the existing treatment of close evaluation
are preserved. Wall batches remain 64 physical targets, mass batches 32,
and direct proxy batches 512. Each FMM callback makes one `hfmm2d` call;
the callback ledger records source/target counts, batches, error code,
stage, and seconds. Timing compares two FMM levels with only one direct
level, so their ratios are not controlled speedup measurements.

Raw `scientific.mat` uses MATLAB v7 format and retains matching/scattering
matrices, densities, signed material actions, wall maps, all finite and tail
terms, and mass samples, including a clearly separate single-layer
`evidence.direct`. `scalars.csv` prints 17-digit values. `result.json` stores
scalar and component differences. Relative differences use
$|a-b|/\max(\mathrm{realmin},|a|,|b|)$.

## Operational repairs and limits

`run-01` stopped before MATLAB launch because sandboxed process-list access
was unavailable. `run-02` exposed a pre-existing singleton-target shape issue
in the public pair-matrix evaluator at the disk-center diagnostic point.
Its logical indexing produces a vector with the wrong coordinate shape;
the old direct evaluator silently used only the first two rows, while FMM
correctly rejected the input.

The isolated repair duplicates a singleton physical target, invokes the same
public evaluator, and retains the first output row. Both backends share it.
It repairs the point/cone diagnostic; the multi-target disk quadrature used
for $U_{\rm num}$ is unchanged. Public code is not modified. The old point/cone
diagnostic therefore should not be compared as if this shape defect were
absent.

The original failed logs are preserved. Although the run-02 monitor recorded
zero budget charge for its operational failure, all later runs count its
actual 63.302005 seconds. `output/attempt-1/budget-correction.txt` records this
correction. The corrected monitor counts every launched process against the
same 1800-second budget and enforces 2 GiB process-tree RSS, rejects concurrent
MATLAB, and cleans only this run's process group. This run used the stricter
30-minute stop and did not request a grace interval.

The direct comparison checks evaluator sensitivity for this FMM-constructed
field. It does not exclude error in field construction, prove convergence of
the 512/768 evaluation grids, certify geometric/tail/quadrature estimates, or
provide a reliable continuous spectral-distance bound.

## Completed result: attempt-1/run-03

MATLAB R2023b completed the full fresh construction, FMM two-level evaluation,
and fixed-field direct primary-level comparison with exit code 0. Both
results have positive denominators and status `UNCERTIFIED_RNUM`.

| backend / evaluation grid | $C_{\rm num}$ | $\epsilon_{\rm num}$ | $U_{\rm num}$ | $Q$ | denominator | $R_{\rm num}$ |
|---|---:|---:|---:|---:|---:|---:|
| FMM / 512 diagnostic | 8.2735456668590359 | 9.1783478841038969e-13 | 0.11608305829685361 | 7.5937480365452596e-12 | 0.11608305828925987 | 4.0355781662571026e-10 |
| FMM / 768 primary | 8.2735456668590359 | 1.6064304963971742e-12 | 0.11608305827964503 | 1.329087607257705e-11 | 0.11608305826635415 | 7.0632274130478178e-10 |
| direct / 768 fixed field | 8.2735456668590359 | 1.6057993786883599e-12 | 0.11608305827964503 | 1.3285654491392012e-11 | 0.11608305826635938 | 7.06045248570906e-10 |

The ordinary-double product is $\mu_{\rm num}=3.0845259366652127$.
The FMM/direct absolute difference in $R_{\rm num}$ is
$2.774927338757746\times10^{-13}$, with relative difference
$0.00039286960145607874$ (about 0.0393%). The saved MATLAB mass norms are bitwise equal.
The FMM 512/768 relative differences are 0.42864954924115484 in
$R_{\rm num}$ and 0.4286495491284149 in $\epsilon_{\rm num}$; this is
substantial native/non-native sensitivity, not convergence evidence.

| fixed-field scalar | absolute difference | relative difference |
|---|---:|---:|
| `Cnum` | 0 | 0 |
| `epsilon_num` | 6.3111770881428083e-16 | 0.00039286960141115445 |
| `U_num` | 0 | 0 |
| `Q` | 5.2215811850382066e-15 | 0.00039286960141114024 |
| `denominator` | 5.2319260035460502e-15 | 4.5070538988911621e-14 |
| `Rnum` | 2.7749273387577461e-13 | 0.00039286960145607874 |

The complete primary jump ledger below gives squared value/ordinary-normal
contributions. Exact 17-digit values for every component, ratio, aggregate,
and difference are in [`parts.csv`](output/attempt-1/run-03/parts.csv).

| component | FMM value squared | direct value squared | FMM normal squared | direct normal squared |
|---|---:|---:|---:|---:|
| center material | 1.375590219e-29 | 1.417130074e-29 | 2.038581451e-24 | 2.038089167e-24 |
| 40 cells per side | 2.138167909e-30 | 2.364884751e-30 | 1.980946747e-28 | 2.644986273e-28 |
| material tail | 4.898698021e-72 | 5.419004037e-72 | 4.536955564e-70 | 6.054727942e-70 |
| two center/lead walls | 1.742670881e-27 | 1.747959465e-27 | 4.769994575e-25 | 4.754669462e-25 |
| 40 internal walls per side | 1.905941905e-27 | 1.918018540e-27 | 6.117542967e-26 | 6.108851873e-26 |
| wall tail | 4.388991071e-69 | 4.416922537e-69 | 1.402774394e-67 | 1.400791338e-67 |
| total | 3.664506857e-27 | 3.682514190e-27 | 2.576954433e-24 | 2.574909130e-24 |

The center material ordinary-normal term contributes
79.108168%
of the primary normal-squared total; artificial walls contribute
20.884144%.
The lead normal-squared term has a larger relative FMM/direct change
(about 25.1%), but its absolute difference is only
$6.640395255500175\times10^{-29}$. Small relative scalar drift therefore
must not be described as uniformly small relative error in every tiny term.
All observed geometric-tail ratios are approximately 0.091 and below one;
these remain numerical candidates rather than certified tails.

| timed stage | seconds | work covered |
|---|---:|---|
| geometry and setup | 2.284147667 | sampled geometry |
| fresh field construction | 2.576784250 | both cells, matching and propagation |
| FMM jumps | 40.814152917 | 512 and 768 |
| FMM mass | 16.228404333 | both disk grids |
| FMM scalar assembly/internal audit | 0.039101000 | both levels |
| direct jumps | 190.379638250 | 768 only |
| direct mass | 78.579055000 | fine disk only |
| comparison assembly | 0.024824417 | fixed-field checks and differences |
| initial raw save | 4.644206042 | MATLAB v7 |

Recorded entry runtime is 335.571 seconds, including the initial raw save;
final result append and text writes are included in the monitored process wall
of 353.322944 seconds. The complete attempt charge, including the failed
run-02 process, is 416.624949 seconds. Peak process-tree RSS was
1,442,856,960 bytes (about 1.344 GiB). There were no external MATLAB processes,
no resource-limit exits, and cleanup reported no survivors. All 1,479 resource samples were checked
against the saved peak and absence of external MATLAB. No grace interval
was used. These are this run's timings, not a controlled performance claim.

| smooth-proxy stage | backend calls | pair targets total | backend batches | callback seconds |
|---|---:|---:|---:|---:|
| `field` | 2 | 327680 | 2 | 1.288123208 |
| `fmm_jumps` | 84 | 5111808 | 84 | 37.376769583 |
| `fmm_mass` | 82 | 1837568 | 82 | 15.733879500 |
| `direct_jumps` | 50 | 3538944 | 6912 | 187.894323167 |
| `direct_mass` | 65 | 1574400 | 3075 | 78.064557542 |

All 168 FMM callback error codes were zero; direct evaluation used 115
callbacks and 9,987 bounded direct batches. Callback times are nested inside
the stage times and must not be added to them. The largest callback had
589,824 pair targets.

Raw evidence is [`scientific.mat`](output/attempt-1/run-03/scientific.mat),
with the precise summary in [`result.json`](output/attempt-1/run-03/result.json)
and [`scalars.csv`](output/attempt-1/run-03/scalars.csv). The original direct CSV
row had one extra format placeholder; its original bytes are retained as
`scalars-original.csv`. The current source fixes only that text-format typo,
and corrected CSV tables were generated from `result.json`. The executed
`source.m` snapshot and raw MAT are unchanged; `format-correction.txt` records
this distinction. No numerical rerun was needed.

MATLAB Code Analyzer reported only the inherited unused `q` parameter and
an unnecessary message-suppression annotation. Internal finite-matrix audit,
node-dimension checks, complete-tail gates, and exact fixed-field checks
passed. A Python standard-library check also reproduced the saved scalar
$Q$, denominator, and $R_{\rm num}$ identities exactly from JSON, verified
the frozen literal/orders, and checked the resource ledger. This scalar
check is distinct from matrix reconstruction. Independent raw-data review is recorded separately by the Skeptic;
these internal checks alone do not establish certification.

## Independent raw-data audit

The [independent review](../../../research/projects/eig-apost/implementation/i8/review-8-4b.md)
returns **PASS WITH CONDITIONS**, with no unresolved blocker. The conditions
retain the 512/768 sensitivity, cancellation sensitivity near tiny residuals,
absence of a direct field-construction comparison, and uncertified
geometry/quadrature/tail status. Matrix and scalar reconstruction is distinct
from the exact finite-array checks internal to the MATLAB entry.

[`skeptic_audit.py`](skeptic_audit.py) reads the raw v7 MAT with the Python
standard library and an existing NumPy installation. It does not require
MATLAB or new dependencies. Set `PYTHON_BIN` to an available interpreter with
NumPy and run:

```sh
"${PYTHON_BIN:-python3}" test/i8/fmm-est-v1/skeptic_audit.py \
  test/i8/fmm-est-v1/output/attempt-1/run-03/scientific.mat \
  > test/i8/fmm-est-v1/output/attempt-1/run-03/audit-reproduction.json
```

The preserved [audit output](output/attempt-1/run-03/skeptic-audit.json)
records the actual Python interpreter and NumPy versions. The initial
Skeptic reconstruction took about 2.01 seconds; the parent agent's saved
reproduction took 1.698278083 seconds, with Python peak RSS 1,908,654,080
bytes. Both are postprocessing times, separate from the 416.624949-second
MATLAB process total, and are not evaluator timing or speedup evidence.
Different BLAS reduction orders produce small differences when reconstructing
near-cancelled matrix residuals; the review discloses these rather than using
an absolute-only internal tolerance to imply relative precision.
