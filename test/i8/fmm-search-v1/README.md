# I8.4 FMM wide-search experiment

Status: `COMPLETE; WIDTH TARGET MET; FRESH FMM REPEAT EXACT`.

This experiment independently searches the frozen I8.1 model with
`fmm_i8_point(k,'fmm',1e-12,false)`. It starts from the fixed 33-point grid
`1.45:0.025:2.25`; no runtime decision reads the historical candidate, a prior
local interval, or an earlier result. The wide scan selects the best eligible
strict interior dip. Each later 11-point grid uses the stable first global
minimum and its actual neighbors. The implemented endpoint recovery is the
frozen five-spacing overlapping shift inside the original domain, although no
recovery round was needed in this run.

## Entry points

- `search_fmm_i8.m` performs the wide scan and nested refinement, writes a
  checkpoint after every complete grid, and records the platform diagnostic
  without using it for early stopping.
- `confirm_fmm_i8.m` accepts one explicit 17-digit literal and makes exactly
  one fresh FMM evaluation. It contains no `load` call and no historical
  candidate literal.
- `monitor.sh` rejects another MATLAB, samples process-tree RSS and system
  load, enforces the shared 30-minute/2-GiB limits, and audits process-group
  cleanup after exit.
- `plot_search.py` renders dependency-free SVG summaries from completed CSV
  records. It does not evaluate the model.

The launcher may add the repository packages, this directory,
`test/i8/fmm-v1`, and the vendored FMM2D MATLAB directory to the MATLAB path.
The numerical functions themselves resolve dependencies only through that
path. The exact formal commands are in
[`run-01/command.txt`](output/attempt-1/run-01/command.txt) and
[`run-02/command.txt`](output/attempt-1/run-02/command.txt). The second command
contains the literal `1.7562818500073423` directly and does not load the search
output.

To reproduce from the repository root with the existing MATLAB/FMM2D build,
choose an unused attempt/run directory and set `MATLAB_BIN` to the installed
MATLAB executable (or leave it unset when `matlab` is on the shell path):

```sh
OMP_NUM_THREADS=11 bash test/i8/fmm-search-v1/monitor.sh \
  test/i8/fmm-search-v1/output/attempt-N/run-01 \
  "addpath(pwd); addpath('test/i8/fmm-search-v1'); addpath('test/i8/fmm-v1'); addpath('test/i8/fmm-v1/vendor/fmm2d/matlab'); search_fmm_i8('test/i8/fmm-search-v1/output/attempt-N/run-01');"
```

After that process exits, use the printed `FINAL_K_LITERAL` explicitly in a
second monitored process calling `confirm_fmm_i8(k_literal,output_dir)` with
`run-02` under the same attempt. Do not load the first run to obtain this input.
The monitor shares the scientific time budget across those run directories.
Do not rerun into an existing output directory or run concurrent MATLAB.

## Search result

All 242 calls were valid: 33 wide points plus 19 complete 11-point grids.
They contain 188 distinct exact binary64 values of `k`; the 54 repeated calls
are retained as real computations. All four metrics at every row come from
one `fmm_i8_point` call. The wide grid had one eligible strict dip, at
`k=1.75`. Every local winner was interior, so no endpoint recovery was used.

The first complete grid meeting the target was round 19:

| quantity | value |
|---|---:|
| actual first node | `1.7562818500073356` |
| actual last node | `1.7562818500073489` |
| actual full width | `1.3322676295501878e-14` |
| actual min/max spacing | `1.3322676295501878e-15` / `1.3322676295501878e-15` |
| final-round winner index | `6 / 11` |
| cumulative winner first evaluation | `229` (round 18, node 9) |
| candidate `k` | `1.7562818500073423` |
| `adef_sigma` | `8.2879554543588172e-14` |
| `adef_ratio` | `1.3717792880175595e-16` |
| `aphys_sigma` | `4.0360727231757905e-14` |
| `aphys_ratio` | `1.4133082230178709e-14` |

Round 19 reevaluated the same candidate and reproduced all four metrics
bitwise. Across all 19 rounds containing exact repeated nodes, every repeated
four-metric vector was bitwise equal; the maximum recorded absolute difference
was zero. Exact repeats were never cached or removed.

The platform state is `not_confirmed`. Rounds 5, 9, 15, and 19 individually
had cumulative improvement below 5%, but each streak reached only one before a
later larger improvement or the width stop. No three-transition candidate or
confirmation was observed. The search therefore stopped only because the
actual-width target was met.

The table reports `(prior - current) / prior` for the round-best and cumulative
change columns. A negative round-best value means that complete grid's own
minimum was slightly higher; the cumulative minimum remains monotone.

| round | kind | actual W | winner k | winner aphys sigma | winner aphys ratio | round-best change | cumulative change | outer sum (s) | platform |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---|
| 0 | wide | 8.0000000000e-01 | 1.75 | 2.6853565645e-02 | 9.3481712760e-03 | — | — | 43.093192 | none |
| 1 | refinement | 5.0000000000e-02 | 1.7549999999999999 | 5.4483796739e-03 | 1.9055688489e-03 | 0.796156 | 0.796156 | 14.963329 | none |
| 2 | refinement | 1.0000000000e-02 | 1.756 | 1.1966146772e-03 | 4.1890714750e-04 | 0.780167 | 0.780167 | 14.021687 | none |
| 3 | refinement | 2.0000000000e-03 | 1.7562 | 3.4742121874e-04 | 1.2164688833e-04 | 0.709609 | 0.709609 | 14.215916 | none |
| 4 | refinement | 4.0000000000e-04 | 1.7562800000000001 | 7.8518431760e-06 | 2.7494686275e-06 | 0.977398 | 0.977398 | 13.617752 | none |
| 5 | refinement | 8.0000000000e-05 | 1.7562799999999998 | 7.8518431793e-06 | 2.7494686286e-06 | -4.24639e-10 | 0 | 14.248560 | streak 1 |
| 6 | refinement | 1.6000000000e-05 | 1.7562815999999999 | 1.0610849136e-06 | 3.7155913335e-07 | 0.864861 | 0.864861 | 14.036771 | none |
| 7 | refinement | 3.2000000001e-06 | 1.7562819199999999 | 2.9706380114e-07 | 1.0402259057e-07 | 0.720038 | 0.720038 | 14.484806 | none |
| 8 | refinement | 6.4000000011e-07 | 1.756281856 | 2.5434140854e-08 | 8.9062519634e-09 | 0.914382 | 0.914382 | 13.533957 | none |
| 9 | refinement | 1.2799999993e-07 | 1.756281856 | 2.5434140854e-08 | 8.9062519634e-09 | 0 | 0 | 15.445521 | streak 1 |
| 10 | refinement | 2.5599999898e-08 | 1.75628185088 | 3.7037639540e-09 | 1.2969439392e-09 | 0.854378 | 0.854378 | 13.917431 | none |
| 11 | refinement | 5.1199999795e-09 | 1.756281849856 | 6.4233298320e-10 | 2.2492520557e-10 | 0.826573 | 0.826573 | 13.681429 | none |
| 12 | refinement | 1.0239999959e-09 | 1.7562818499584001 | 2.0770118457e-10 | 7.2730550762e-11 | 0.676646 | 0.676646 | 13.768114 | none |
| 13 | refinement | 2.0479995477e-10 | 1.75628184999936 | 3.3885738727e-11 | 1.1865740900e-11 | 0.836853 | 0.836853 | 13.378257 | none |
| 14 | refinement | 4.0960124181e-11 | 1.7562818500075521 | 8.8423323344e-13 | 3.0963121470e-13 | 0.973905 | 0.973905 | 13.277011 | none |
| 15 | refinement | 8.1918916095e-12 | 1.7562818500075519 | 8.8663441113e-13 | 3.1047203309e-13 | -0.00271555 | 0 | 13.579477 | streak 1 |
| 16 | refinement | 1.6384671397e-12 | 1.7562818500073882 | 1.9331434385e-13 | 6.7692722736e-14 | 0.781968 | 0.781376 | 14.425873 | none |
| 17 | refinement | 3.2751579226e-13 | 1.7562818500073227 | 7.8862672912e-14 | 2.7615276473e-14 | 0.59205 | 0.59205 | 14.078109 | none |
| 18 | refinement | 6.5503158453e-14 | 1.7562818500073423 | 4.0360727232e-14 | 1.4133082230e-14 | 0.488215 | 0.488215 | 13.886367 | none |
| 19 | refinement | 1.3322676296e-14 | 1.7562818500073423 | 4.0360727232e-14 | 1.4133082230e-14 | 0 | 0 | 15.270390 | streak 1 |

The authoritative complete ledgers are
[`evaluations.csv`](output/attempt-1/run-01/evaluations.csv),
[`rounds.csv`](output/attempt-1/run-01/rounds.csv), and
[`result.mat`](output/attempt-1/run-01/result.mat). The CSV uses `%.17g`; MAT
files retain the original doubles.

## Fresh-process repeat and historical comparison

The fresh process received only the explicit candidate literal and reproduced
`k` plus all four metrics bitwise; every absolute difference is zero. Its
complete-call time was `1.545477` s and internal point time was
`1.4873975833333333` s. Raw evidence is in
[`confirmation.csv`](output/attempt-1/run-02/confirmation.csv) and
[`confirmation.mat`](output/attempt-1/run-02/confirmation.mat).

Only after the search and fresh repeat were complete was the result compared
with the historical direct candidate `1.7562818500073463`. The new FMM search
candidate differs by `-3.9968028886505635e-15`, exactly `-18` binary64 ulps at
that scale. This proximity did not control the search and does not certify a
continuous minimizer. The historical direct result also uses a different
evaluator, so its metric values are not substituted for the FMM result.

## Timing, environment, and resource record

| record | search | fresh repeat | combined |
|---|---:|---:|---:|
| monitored process wall (s) | 340.982072 | 13.618543 | 354.600615 |
| complete-call outer sum (s) | 310.923948 | 1.545477 | 312.469425 |
| internal point sum (s) | 310.326052 | 1.487398 | 311.813450 |
| sampled peak process-tree RSS (bytes) | 1,103,577,088 | 1,031,847,936 | 1,103,577,088 |

Search complete-call times had min/median/max
`1.134419 / 1.257380 / 2.051487` s. The `42.131190` s difference between
combined monitored wall and complete-call sums contains MATLAB startup/exit,
the one in-process `checkcode` gate, checkpoint/CSV/JSON/MAT/PNG exports, and
monitor management; these components were not separated and are not point
evaluation time.

The run used MATLAB `23.2.0.2365128 (R2023b)` on `MACA64`, with MATLAB's
reported thread limit `11` and `OMP_NUM_THREADS=11`. `OMP_DYNAMIC` and
`OMP_PROC_BIND` were unset. This differs from the earlier fixed-point timing
environment where `OMP_DYNAMIC=FALSE`, so the present times are not a strict
historical speedup comparison. Both preflights and all runtime samples found
no other MATLAB. One-minute load average ranged from `1.823730` to
`14.875977`, including load generated by this 11-thread computation. Both
monitors exited with code zero and reported `post_cleanup_survivors=none`.
The combined charged wall used `354.600615 / 1800` seconds of the shared
scientific budget.

`checkcode` returned six advisory search-source messages (`AGROW`, `NASGU`,
three stale `MSNU` suppressions, and `FNDSB`) and no confirmation-source
message. It reported no syntax or correctness diagnostic. The source files
loaded by the search are copied into `run-01` for audit. A postprocessing
bytecode check initially hit the restricted system Python cache, then passed
with a `/tmp` cache; it launched no MATLAB and is recorded in
[`implementation-checks.log`](output/attempt-1/implementation-checks.log).

## Curves and audit artifacts

Each complete round has its own raw MAT/JSON/CSV and MATLAB-generated
semilog-y PNG, from
[`curve-00.png`](output/attempt-1/run-01/curve-00.png) through
[`curve-19.png`](output/attempt-1/run-01/curve-19.png). The dependency-free
postprocessor also writes an
[all-round panel](output/attempt-1/run-01/curves-all.svg) and
[width/score trends](output/attempt-1/run-01/trends.svg), with the SVG vertical
coordinates explicitly labeled as base-10 logarithms. These figures are views
of the CSV; the numerical ledgers remain authoritative.

## Independent review and claim boundary

The independent review verdict is **PASS WITH CONDITIONS**, with high
confidence and no blocker. It allows the candidate to proceed to a separately
designed stage-2 $R_{\rm num}$ evaluation only as a finite FMM-grid candidate.
The audit is recorded in
[`review-8-4a.md`](../../../research/projects/eig-apost/implementation/i8/review-8-4a.md).

Two important caveats limit the location claim. Round 19 contains two strict
dips: the winning score and the score at the historical-candidate node differ
by only `1.308618745879736e-16`, about `0.926%` of the winner. This is smaller
than the already observed fixed-point direct/FMM perturbation scale, so the
ordering is not evidence of a unique direct or continuous minimum. Also, the
33-point grid with spacing `0.025` cannot exclude narrower valleys between its
nodes. The varying system load is a minor timing caveat. The negative platform
result is correctly recorded evidence and is neither a blocker nor an
additional caveat.

The actual full-grid width is only a sampling scale. The requested FMM
tolerance is not a bound on matrix or singular-value error. This experiment
does not certify a continuous minimum, run direct-neighborhood relocation,
prove convergence, or evaluate the I8.4 spectral-distance quantity. Those
limits do not invalidate the completed finite FMM grid search.
