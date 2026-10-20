# I8 FMM experiment symbol and variable ledger

This ledger maps the nontrivial names owned by `test/i8/fmm-v1`.  Mathematical
objects follow the frozen I8 design in
`research/projects/eig-apost/implementation/i8/p-fmm.md`.  Obvious loop
indices (`j`, `p`, `e`, `m`, `c`, `s`, `first`, `index`, `position`, and
`key_index`) and short-lived formatting/file-handle temporaries are omitted.

## Numerical point entry

| Code name | Kind and scope | Source or data requirement | Meaning; type and shape | Defined / consumed |
|---|---|---|---|---|
| `k` | input scalar | p-fmm sec. 2 | Exterior wavenumber; finite positive binary64 scalar | `fmm_i8_point`; all cell, channel, and kernel calls |
| `method` | input text | p-fmm sec. 4 | Smooth evaluator role, exactly `direct` or `fmm` | `fmm_i8_point`; evaluator selection and output |
| `fmm_eps`, `requested_eps` | input / record scalar | p-fmm secs. 3, 6 | Requested FMM2D tolerance; positive scalar for FMM, `NaN` for direct | point entry, FMM adapter, result rows |
| `capture_fields` | input logical | p-fmm secs. 4, 5, 7 | Whether one point retains actual callback inputs and raw fields | point entry and both callbacks |
| `beta` | frozen scalar | p-fmm sec. 2, $\beta=0.5$ | Bloch parameter | point entry; `model`, public channel/proxy calls |
| `model` | frozen struct | p-fmm sec. 2 | Physical model: period, lead/center contrast, walls, proxy box, and equal-area star scale | point entry; lead and center helpers |
| `cfg` | frozen struct | p-fmm sec. 2 | Spatial sizes `ntot=256`, `nside=ntop=160`, `nproxy=80`, `mpw=32` | point entry; lead and center helpers |
| `M` | frozen integer | p-fmm sec. 2 | Rayleigh truncation order 48, hence 97 channels | point entry; lead and center helpers |
| `evaluator` | function handle | p-fmm sec. 4 | Direct-batched or one-call FMM smooth-proxy evaluator | point entry; `pars.h2d_evaluator` |
| `pars` | local struct | public evaluator-hook interface, p-fmm sec. 4 | Physical/kernel parameters including `periodic_axis='y'` and `evaluator` | `LOCAL_cellsub`, `LOCAL_center`; proxy and BIE assembly |
| `chans` | local struct | p-fmm secs. 2, 4 | Public Rayleigh channel data for one point | cell helpers; `bloch.construct_S` and lead QZ |
| `C` | local array | p-fmm sec. 2 | Inclusion contour array, circle in lead or scaled star in center | cell helpers; `bloch.construct_S` |
| `curvelen` | local scalar | public geometry interface | Parameter-interval length returned with `C`; it is $2\pi$ for the frozen circle and star contours | cell helpers; `bloch.construct_S` |
| `mfscfg` | local struct | p-fmm sec. 2 | Proxy precomputation sizes and box geometry | cell helpers; `kernel.precomp_proxy` |
| `proxy` | local struct | public proxy interface, p-fmm sec. 4 | Proxy charges/sources and top/bottom plane-wave coefficients | cell helpers; `bloch.construct_S` |
| `kint` | local scalar | frozen dielectric model, p-fmm sec. 2 | Interior wavenumber, `sqrt(epsrel)*k` | cell helpers; `bloch.construct_S` |
| `cellmap` | local struct | public scattering interface | Lead or center cell scattering blocks | cell helpers; matching and lead pencil |
| `Zp`, `Zm` | local complex matrices | unchanged locate_i8 QZ convention, p-fmm secs. 1, 4 | Qualified stable generalized-Schur subspaces, each 194-by-97 | `LOCAL_cellsub`; `LOCAL_dtn` |
| `bm` | local real vector | Rayleigh channels | Channel tangential wavenumbers, 97-by-1 | lead helper; physical column weights |
| `gamma` | local complex vector | Rayleigh channels | Outgoing/decaying normal wavenumbers, 97-by-1 | lead helper; DtN and matching |
| `Lp`, `Lm` | local complex matrices | unchanged locate_i8 DtN convention | Right/left half-guide DtN maps, each 97-by-97 | `LOCAL_dtn`; `Adef` construction |
| `G` | local diagonal matrix | unchanged locate_i8 matching formula | `diag(gamma)`, 97-by-97 | point entry; `Adef` |
| `Adef` | output complex matrix | p-fmm secs. 2, 5 | Unweighted defect matching matrix, 194-by-194 | point entry; raw MAT and comparisons |
| `b` | local positive vector | unchanged locate_i8 physical weights | `sqrt(1+abs(bm).^2)`, 97-by-1 | point entry; row/amplitude weights |
| `rowwt`, `ampwt`, `colwt` | local vectors | unchanged locate_i8 physical weighting | Two-block row weights, channel amplitude weights, and two-block column weights | point entry; `Aphys` |
| `Aphys` | output complex matrix | p-fmm secs. 2, 5 | Physically weighted matching matrix, 194-by-194 | point entry; raw MAT and comparisons |
| `adef_sval`, `aphys_sval` | local vectors | p-fmm sec. 5 | Ascending singular values of `Adef` and `Aphys` | point entry; `metrics` |
| `metrics` | output struct | p-fmm secs. 2, 5 | Minimum/maximum singular values and their ratios for both matrices | point entry; validation/performance records |
| `point_timer`, `point_seconds` | timer / scalar | p-fmm sec. 7 | Inner numerical-chain time; auxiliary, not main performance denominator | point entry; output rows |
| `warning_guard` | cleanup object | frozen locate_i8 warning policy | Restores warning state and turns solver warnings into errors | point entry |
| `proxy_calls` | output struct array | p-fmm secs. 4, 5 | Exactly two callback records, ordered lead then center | callbacks/capture; raw evidence and timing |

## QZ and DtN helpers

| Code name | Kind and scope | Source | Meaning; type and shape | Defined / consumed |
|---|---|---|---|---|
| `K` | local integer | p-fmm sec. 2 | Channel count 97 | lead/QZ/DtN helpers |
| `A`, `B` | local complex matrices | frozen locate_i8 pencil | Generalized lead pencil matrices, 194-by-194 | `LOCAL_cellsub`; `LOCAL_qzsub` |
| `rho` | local scalar | frozen locate_i8 QZ scaling | Joint Frobenius scale of the pencil | `LOCAL_qzsub` |
| `S`, `T`, `Q`, `Z` | local complex matrices | MATLAB complex QZ | Generalized Schur factors before ordering | `LOCAL_qzsub` |
| `res`, `tol` | local scalars | frozen locate_i8 qualification | QZ residual and classification tolerance | `LOCAL_qzsub` |
| `alpha`, `theta`, `scale`, `an`, `tn` | local vectors | generalized eigenvalue classification | Diagonals, joint scale, and normalized magnitudes | `LOCAL_qzsub` |
| `indet`, `infinite`, `neutral`, `stable`, `unstable` | local logical vectors | frozen locate_i8 classification | Disjoint generalized-eigenvalue classes | `LOCAL_qzsub`; `ordqz` |
| `Zo`, `Zs` | local/output matrices | ordered QZ | Ordered Schur vectors and returned stable subspace | `LOCAL_qzsub`; lead helper |
| `Ap`, `Bp`, `Am`, `Bm` | local complex matrices | frozen half-guide split | Upper/lower blocks of the two stable subspaces | `LOCAL_dtn` |
| `Dp`, `Np`, `Dm`, `Nm` | local complex matrices | frozen DtN formula | Dirichlet and normal-trace block combinations | `LOCAL_dtn`; solves for `Lp`,`Lm` |

## Smooth field adapters and capture

| Code name | Kind and scope | Source | Meaning; type and shape | Defined / consumed |
|---|---|---|---|---|
| `wavek` | callback scalar | public `h2d_evaluator` contract | Helmholtz wavenumber for the current actual callback | both adapters; public direct/FMM calls |
| `sources` | callback array | p-fmm sec. 3 | Smooth proxy locations, 2-by-320 | adapters; raw evidence |
| `charge` | callback vector | p-fmm sec. 3 | Complex proxy charges, 1-by-320 after reshape | adapters; raw evidence |
| `targ`, `target` | callback array / record alias | p-fmm secs. 3, 4 | Full actual point-difference target set, 2-by-65536 | adapters; raw evidence |
| `pot`, `grad`, `hess` | callback outputs | p-fmm sec. 3 | Potential 1-by-nt, target gradient 2-by-nt, and target Hessian 3-by-nt in `(xx,xy,yy)` order | adapters; public pair-matrix assembly and raw evidence |
| `target_batch` | direct-only integer | frozen locate_i8 callback | Direct batch size 512 | `LOCAL_h2d_chunked_public` |
| `eval_timer`, `evaluator_seconds` | timer / scalar | p-fmm sec. 7 | Complete callback time including FMM setup/reshape/reorder or direct batching | adapters; call records |
| `ns`, `nt` | local/record integers | p-fmm secs. 3, 5 | Actual source and target counts; required as 320 and 65536 | adapters; interface checks and CSV |
| `srcinfo` | FMM local struct | official `hfmm2d` interface | FMM source coordinates and complex charge row | `LOCAL_h2d_fmm`; `hfmm2d` |
| `U` | FMM local struct | official `hfmm2d` interface | Raw FMM target potential, gradient, and Hessian fields | `LOCAL_h2d_fmm`; reshaped callback outputs |
| `ier` | FMM status scalar | official `hfmm2d` interface | FMM error code, required to be zero | adapter; raw and CSV evidence |
| `timeinfo` | FMM timing vector | official `hfmm2d` interface | Six internal FMM phase times; diagnostic only | adapter; raw call record |
| `record` | local struct | p-fmm secs. 4, 5 | One callback method/status/timing record, optionally with raw arrays | adapters; `LOCAL_capture` |
| `records`, `current_label` | persistent array/text | required lead/center evidence order | Per-point callback buffer and current cell label | `LOCAL_capture` |

## Run, comparison, and export

| Code name | Kind and scope | Source | Meaning; type and shape | Defined / consumed |
|---|---|---|---|---|
| `output_dir`, `raw_dir` | input / local paths | p-fmm secs. 5, 8 | Requested artifact directory and its raw MAT subdirectory | `run_fmm_i8`; all writers |
| `k_values`, `point_ids` | frozen vector / cell array | p-fmm sec. 2 | Five literal wavenumbers and stable row identifiers | runner; every validation/performance stage |
| `base_eps_values`, `fmm_eps_values` | vectors | p-fmm secs. 3, 6 | Base tolerances and final set after the fixed third-tier decision | runner; validation and performance |
| `repeat_point_indices` | frozen vector | p-fmm sec. 7 | Indices of candidate `k0` and neighbor `k1` | performance stage |
| `environment` | output struct | p-fmm sec. 8 | MATLAB/platform/thread/path/config record | runner; JSON/result |
| `original_out`, `original_scan`, `original_metrics`, `originals` | locator outputs / records | p-fmm secs. 4, 5 | Untouched `locate_i8(k,1,1)` output, four metrics, and per-point summary | original stage; direct equality and raw MAT |
| `direct_point`, `direct_outer_seconds`, `directs` | point output / timing / cache | p-fmm secs. 4, 5 | Timed diagnostic-direct result, main wall time, and field-stripped matrix references | direct stage; raw MAT and FMM comparisons |
| `fmm_point`, `fmm_outer_seconds` | point output / timing | p-fmm secs. 4, 5 | Timed FMM result and complete-entry wall time | FMM validation; raw MAT/rows |
| `outer_timer`, `outer_seconds` | timer / scalar | p-fmm sec. 7 | Main complete-entry performance timing | all method calls; reports |
| `validation_rows` | output struct array | p-fmm secs. 5, 6 | One row per original/direct/FMM point and tolerance | runner; MAT/JSON/CSV and trigger |
| `field_rows` | output struct array | p-fmm secs. 5, 6 | Six component rows per cell, point, and FMM tolerance | comparison; MAT/JSON/CSV |
| `performance_rows`, `performance_summary` | output struct arrays | p-fmm sec. 7 | Raw warmup/repeat calls and three-repeat min/median/max | performance stage; result exports |
| `direct_raw` | loaded struct | p-fmm sec. 5 | One point's raw direct callback evidence loaded for an FMM comparison | `LOCAL_validation_tier` |
| `field_evidence` | raw struct array | p-fmm sec. 5 | Two-cell actual inputs plus complete direct/FMM fields and summaries | comparison; per-FMM raw MAT |
| `comparison_seconds` | scalar | p-fmm secs. 5, 7 | Post-timer field-summary/minimum-distance comparison cost | validation row; explicitly excluded from point time |
| `minimum_distance` | scalar | p-fmm secs. 3, 5 | Smallest source-target separation for one actual callback | field evidence and interface audit |
| `summary` | struct array | p-fmm sec. 5 | Six component norms and scale-safe field errors for one cell | field comparison; raw/CSV |
| `difference` | local array | p-fmm sec. 5 | FMM minus direct field or matrix | component/matrix comparison helpers |
| `matrix_comparison` | struct | p-fmm secs. 5, 6 | `Adef`/`Aphys` max, Frobenius, and spectral differences | validation; trigger and raw MAT |
| `metric_comparison` | struct | p-fmm sec. 5 | Four metric differences and two Weyl checks | validation; raw MAT/CSV |
| `reference_fro`, `reference_spectral` | local scalars | p-fmm sec. 5 | Direct matrix Frobenius and spectral norms | matrix comparison helper |
| `trigger` | output struct | p-fmm sec. 6 | Three preregistered predicates, contraction statistics, and decision | runner; JSON/result/performance method set |
| `fmm10`, `fmm12`, `direct` | trigger row subsets | p-fmm sec. 6 | Five validation rows for each base tolerance and direct | trigger helper |
| `errors10`, `errors12`, `contraction` | trigger vectors | p-fmm sec. 6 | Ten relative Frobenius errors at each tolerance and their contraction factors | trigger helper |
| `criterion_1`, `criterion_2a`, `criterion_2b` | trigger logicals | p-fmm sec. 6 | Candidate floor, median contraction, and degradation predicates | trigger decision |
| `specs`, `method_specs` | struct array | p-fmm sec. 7 | Direct plus active FMM methods/tolerances | fixed performance protocol |
| `orders` | integer matrix | p-fmm sec. 7 | Three fixed cyclic repeat orders for three or four methods | performance loop |
| `phase`, `round_index` | row text / integer | p-fmm sec. 7 | Warmup/repeat label and repeat round number | performance records |
| `fmm_evaluator_seconds`, `fmm_call_count` | record fields | p-fmm secs. 4, 7 | Sum of two FMM callback times and observed callback count | validation/performance rows |
| `result` | function output struct | p-fmm secs. 5-8 | Complete small aggregate; large fields remain in per-point raw MAT files | runner; `result.mat` and JSON |

## Monitor names

`MAX_WALL_SECONDS=1800`, `MAX_RSS_BYTES=2*1024^3`, and
`SAMPLE_SECONDS=0.2` are the fixed monitor limits from p-fmm sec. 8.
`task_tree_rss_bytes` is the sum over the launched process and descendants;
`matlab_union_rss_bytes` also includes any detected MATLAB tree.  The monitor
terminates on a foreign MATLAB root, either RSS measure reaching the cap, or
the wall limit.  `OMP_NUM_THREADS` is launch metadata and was fixed at 11 for
run 01.

