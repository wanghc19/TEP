# Numerical-directions diagnostics, version 1

`numerical-directions` means the search for numerical-analysis research directions. DtN means Dirichlet-to-Neumann; FEM means finite element method; QZ means generalized Schur decomposition; RSS means resident set size. CSV files contain comma-separated values, JSON files contain JavaScript Object Notation, and MAT files store MATLAB arrays. MB below is decimal disk use; GiB is binary memory use.

The two revised diagnostics use existing I9.6 and I10.2 routines. L1's g12/g24 rerun was dropped: its diagnostic is the retained enrichment/cross-grid/BIE comparison in `test/i10/refine-v1/README.md`. The I9/I10 source files and shared packages were read only. All commands below are from the repository root, using MATLAB R2023b on MACA64 with 11 threads.

## Files and monitoring

- `integration_rate.m`: calls the unchanged I9.6 entry, then extracts per-template moment bounds before block cleanup.
- `integration_sweep.py`: runs the adjusted five-cap sweep serially and removes each completed case's disposable `blocks/**/*.mat` after extraction.
- `lead_dtn_probe.m`: g24 P4 lead assembly, archived-matrix equivalence, Chebyshev interpolation, and a discrete Bloch-band scan. Its header names the source and source commit; 47 local support functions are copied verbatim from `test/i10/refine-v1/refine_i102.m`.
- `monitor.py`: samples the MATLAB process tree every second, records wall/RSS/disk, and enforces 3 GiB RSS, 30 min soft / 40 min hard time ceilings, and an experiment-directory disk guard below 300 MB. The L2 cases share a remaining sweep budget; no extension was needed. The process monitor requires an execution context where `ps` is available.
- `analyze.py`: regenerates `rate-data.csv`, `rate-fits.json/csv`, `level-summary.csv`, and the interpolation analysis from retained numerical records.

For L3, `output/run-003/source/` preserves its launched entry and config. The top-level entry additionally accepts the retained `reference-D.mat` as a portable numerical input; that path was validated by run-004, whose sources are also retained. `output/run-002/source/` retains the integration entry, launcher, and original I9.6 sources. The underlying I9.6/I10.2 repository sources correspond to checkout `b06db99382d10915a4991490c71c608c77803445`.

## run-001 — original startup failure, retained

Purpose: startup feasibility. Estimate: 20 s and below 2 GiB; startup timeout 60 s.

```sh
/Applications/MATLAB_R2023b.app/bin/matlab -batch "disp('NUMERICAL_DIRECTIONS_STARTUP_OK')"
```

It exited −9 after 1.61245 s before the marker, reporting:

```text
Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error
MATLAB is exiting because of fatal error
```

Peak memory was unavailable because `ps` was denied. The original command, status, and log remain under `output/run-001/startup/`. Later successful runs used the approved execution context with process monitoring.

## run-002 — moment-enclosure rate

Purpose: measure the shrinkage of the moment enclosure against actual terminal pieces. Base: `dtn_bound_i96_config('smoke')`, `native=[]`, with `continue_on_mismatch=true`. Mesh s12/n80, four cells per lead, control N32/M16, main N64/M32, start level 3. **Only `engine.piece_limit` changes.** `NATIVE_FIELD_MISMATCH` is expected for this fixed smoke field and does not invalidate the integration-rate study.

The prelaunch smoke estimate was 1–2 min per case and below 2 GiB. The largest case exceeded that estimate at 134.7 s and 2.24 GiB, while staying within the enforced limits. The two smallest caps stopped the pilot before it could measure contraction, so the five-point scientific sweep was shifted to 100,000–1,600,000. This spans a factor 16 in cap and factors 11.0–12.6 in actual terminal pieces.

Exact initial commands:

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py test/numerical-directions/diagnostics-v1/output/run-002/cap-25000 "addpath('test/i9/dtn-bound-v1','test/numerical-directions/diagnostics-v1'); integration_rate('test/numerical-directions/diagnostics-v1/output/run-002/cap-25000',25000)"
python3 test/numerical-directions/diagnostics-v1/monitor.py test/numerical-directions/diagnostics-v1/output/run-002/cap-50000 "addpath('test/i9/dtn-bound-v1','test/numerical-directions/diagnostics-v1'); integration_rate('test/numerical-directions/diagnostics-v1/output/run-002/cap-50000',50000)"
python3 test/numerical-directions/diagnostics-v1/integration_sweep.py
```

The sweep launches, for each cap $P$ in `[100000,200000,400000,800000,1600000]`, the exact batch expression

```matlab
addpath('test/i9/dtn-bound-v1','test/numerical-directions/diagnostics-v1');
integration_rate('test/numerical-directions/diagnostics-v1/output/run-002/cap-P',P)
```

Here `cap-P` is replaced by its integer value, for example `cap-100000`; each case's `command.json` retains its complete command.

| Piece cap | Wall (s) | Peak tree RSS (GiB) | Case disk before / after cleanup (MB) | Outcome |
|---|---|---|---|---|
| 25,000 | 27.96 | 1.485 | 5.06 / 5.06 | pilot: no measured tightening; levels skipped |
| 50,000 | 25.74 | 1.424 | 5.06 / 5.06 | pilot: no measured tightening; levels skipped |
| 100,000 | 39.01 | 1.434 | 33.33 / 5.30 | six template-levels, PIECE_LIMIT |
| 200,000 | 45.37 | 1.325 | 33.57 / 5.32 | six template-levels, PIECE_LIMIT |
| 400,000 | 62.59 | 1.434 | 33.71 / 5.34 | six template-levels, PIECE_LIMIT |
| 800,000 | 87.13 | 1.500 | 33.73 / 5.36 | six template-levels, PIECE_LIMIT |
| 1,600,000 | 134.67 | 2.239 | 33.73 / 5.36 | six template-levels, PIECE_LIMIT |

The first case's disk use was measured as 5.06 MB before launching the rest; the first complete six-template-level case occupied 33.33 MB before cleanup and 5.30 MB afterwards. The monitored experiment-directory peak during the sweep was 65.25 MB. The removed block files are reproducible with the commands above. Original config/result/integration JSON, per-case CSV, native field, figures, monitor records, and extracted moment summaries are retained; `block-cleanup.json` records each deletion.

For each template, `moment_uncertainty_upper` uses the centered complex-box radii in the estimator's minimum of coefficient $\ell^2$ and weighted $\ell^1$ moment bounds. `moment_upper` includes the nonspecial moments. The two differ only at rounding scale here. Regressing the log of that uncertainty against the log of actual terminal pieces gives:

| Level | Left $r$ | Center $r$ | Right $r$ | Whole-level $r$ |
|---|---|---|---|---|
| control | 2.391 | 2.273 | 2.388 | 2.398 |
| main | 2.357 | 2.229 | 2.331 | 2.298 |

All adjusted cases stopped at PIECE_LIMIT on all six template-levels. All six reached final subdivision level 8 at the largest cap; actual terminal counts were 604,302–813,507. Per-template fit $R^2$ is 0.9952–0.9996. Main's whole moment upper bound fell from 5.53483e−3 to 1.82362e−5, its share of $R_\mu$ from 29.13% to 0.135%, $R_\mu$ from 0.202586 to 0.142978, and $R_k$ from 0.0664115 to 0.0465680. The coarse field's $E_v\approx0.0134193$ dominates once integration tightens.

`rate-data.csv` gives all 30 rows, including final subdivision level, stop reason, template/global moment bounds and shares, radii, times and peak memory. `rate-fits.json` and `level-summary.csv` give the regression and level summaries. Template shares use the common radius scaling; they sum to the recorded global moment contribution for these cases.

**Formal extrapolation:** `formal-reference.json` retains the small numerical inputs read from I9.6 run-03. With $r=2.298$, reducing its main moment from 3.85205e−5 to $E_v=3.14505$e−6 needs a factor 2.975 in actual pieces: 2.276/2.622/2.384 million for left/center/right, or a predictive cap about 5.95 million. Linear work scaling gives about 155 s for the three main engines. Time looks feasible, but an unchanged formal rerun is **infeasible under the current full resource contract**: the documented baseline already wrote about 3.5 GB, above the 1 GB worktree limit, and reached about 2.53 GiB RSS; output streaming/earlier disposal and a memory preflight would be needed before raising its cap. The smoke exponent's transfer to the formal grids is an assumption, not a proven rate.

## run-003 — lead-DtN frequency interpolation

Purpose: test smoothness across a root-search window, with direct archived-result verification before interpolation. Estimate: 3–5 min and below 2.5 GiB. Configuration: `refine_i102_config('g24')`, restricted to P4, check volume order 16, four thin-band subsegments and 12-point rules, $\beta=0.5$, wall dimension 96. Root $k_*=1.5584378942105757$. Half-widths are $10^{-4},10^{-3},10^{-2}$; nested Chebyshev–Lobatto degrees 2/4/8/16 use 17 full nodes and nine off-grid tests per interval.

Exact command used:

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py test/numerical-directions/diagnostics-v1/output/run-003 "addpath('test/i10/refine-v1','test/numerical-directions/diagnostics-v1'); lead_dtn_probe('test/numerical-directions/diagnostics-v1/output/run-003','/Users/whc/Documents/Work/epost/test/i10/refine-v1/output/attempt-1/run-g24-01')"
```

The external directory was read only, solely for its P4 root matrices and original search ledger. Their compact D/S/k arrays are retained in `output/run-003/reference-D.mat`; `iterations-reference.csv` and `root-search-reference.json` retain the search comparison. Run-004 validates a portable rerun using that compact reference file, without the external directory.

Results: both absolute and relative Frobenius differences against the original left/right DtN matrices were 0. At $h=10^{-2}$ the worst relative spectral-norm interpolation errors over both leads were 4.149e−8 / 1.650e−11 / 2.827e−15 / 2.648e−15 for degrees 2/4/8/16. At $h=10^{-3}$ degree 4 reached 1.725e−15; at $h=10^{-4}$ degree 2 gave 3.921e−14. All 24 lead/width/degree combinations are in `interpolation.csv`.

Wall 85.66 s; sampled peak process-tree RSS 1.392 GiB; run disk 23.44 MB and monitored whole-experiment peak 60.33 MB. There were 76 fresh paired DtN evaluations. The 78-row sampling table includes three reused midpoint rows and omits the initial midpoint evaluation; `analyze.py` accounts for that reuse. Paired evaluation median is 0.6723 s; both interpolants together cost roughly 0.12–0.24 ms. Training takes $n+1$ samples.

The original g24 ledger has 26 paired root-search evaluations, 5/4/4/4/4/5 over its six chains, and 33 including identity/prediction/derivatives/recoveries. P4's two chains used nine. This limits amortization in one root chain despite cheap online interpolation.

A 17-point axial Bloch scan on $[-\pi,\pi]$ found adjacent discrete edge candidates at $q=\pm\pi$: left 1.312557304887/2.395219092458, right 1.317414080243/2.380844148165. The nearest sampled edge is 0.241023813967 from the root. If it is the nearest analytic obstruction, it gives a Bernstein-ellipse parameter about 48.2 for $h=10^{-2}$; the observed degree-2/4 ratios correspond to 50–51, then the error reaches rounding scale. The scan supplies discrete edge candidates, with no global or continuous enclosure and no exclusion of closer complex singularities.

## run-004 — portable reproduction of L3

Purpose: verify the compact reference-file input and regenerate the complete L3 diagnostic. Estimate before launch: 2 min and below 1.8 GiB. Configuration and all numerical routines match run-003; only the reference-input location and output directory change.

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py test/numerical-directions/diagnostics-v1/output/run-004 "addpath('test/i10/refine-v1','test/numerical-directions/diagnostics-v1'); lead_dtn_probe('test/numerical-directions/diagnostics-v1/output/run-004','test/numerical-directions/diagnostics-v1/output/run-003/reference-D.mat')"
```

Wall 88.11 s; peak process-tree RSS 1.431 GiB; case disk 23.52 MB before duplicate-sample cleanup. Both root-matrix differences remain 0, and all 24 relative-error table entries reproduce exactly; `reproduction.json` records the comparison. The regenerated duplicate `matrices.mat` was removed after comparison; the full samples remain in run-003 and the command above regenerates them. The monitored whole-experiment peak was 84.19 MB; retained data occupy about 62.2 MB, below 300 MB.

## Regenerate the summaries

```sh
python3 -B test/numerical-directions/diagnostics-v1/analyze.py
```

This uses the retained compact numerical records and `formal-reference.json`, without the discarded blocks or external historical directories. The interpretation and revised ranking are in `research/explorations/numerical-directions/stage1-findings.md`.
