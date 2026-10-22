# I8 independent DIRECT and FMM pipelines

This experiment implements the frozen [design-8-4b](../../../research/projects/eig-apost/implementation/i8/design-8-4b.md). The shared [symbol ledger](../../../research/projects/eig-apost/implementation/i8/SYMBOLS.md) maps the local implementation to the governing formulas. It compares two complete independent pipelines: DIRECT first, then FMM. Each starts from the same wide grid and constructs a fresh field at its own cumulative candidate.

`pipeline_i8_config.m` is the sole scientific configuration. `pipeline_i8_numeric.m` shares the copied local field, jump, mass and resolvent formulas between backends; only the smooth proxy callback changes. The installed third-party FMM2D is a dependency. No runtime path invokes another I8 experiment or reads a historical candidate or MAT file. Public numerical packages and the vendor are unchanged.

The common construction uses center 512 / lead 256 from the first search point. Every final field is constructed again, frozen, and evaluated only on the 768-node material/wall grid with the shifted 32 by 64 disk grid and 40-cell finite prefixes plus tails. The result remains `UNCERTIFIED_RNUM`.

## Run from zero

From the package root, activate the existing environment and run:

```sh
conda activate octave
python test/i8/pipeline-v1/run_pipeline.py \
  --output test/i8/pipeline-v1/output/run-02 \
  --package-root . \
  --fmm-root test/i8/fmm-v1/vendor/fmm2d/matlab \
  --deadline 2026-10-21T07:47:41Z
```

The output directory must not already exist unless `--resume` is used. For a future separately authorized run, use a new output directory and its explicit resource deadline. The package root, local experiment directory, and third-party FMM2D MATLAB directory are launcher inputs. The numerical functions resolve dependencies through the normal MATLAB path.

The current logical attempt is `attempt-1`, described in `output/attempt.json`. `run-01` is an interrupted 10.49-second configuration bootstrap with no scientific point; `run-02` is its corrected execution under the same original three-hour task clock. These are not separate scientific attempts. No deadline reset is used.

The controller monitors each MATLAB process tree and records wall time, RSS, CPU load, external MATLAB processes, exit status, and cleanup. Both backends use 11 MATLAB/OpenMP threads with dynamic OpenMP disabled. The task has a 3 GiB RSS hard limit, 30-minute batch soft limit, and 40-minute batch hard limit. A soft-limit extension requires objective imminent-completion evidence. All failures still consume the original task clock.

## Search and recovery

The wide scan selects the lowest strict interior dip. If none exists, the search fails closed. Each refinement evaluates all 11 actual MATLAB `linspace` nodes between the selected point's actual neighbors. An endpoint winner triggers the deterministic in-domain overlapping shift with the prior requested step retained. Actual nodes must be finite, distinct and increasing; repeated actual grids are rejected. Exact score ties use the first index. Every repeated wavenumber requested by the algorithm is reevaluated.

Success requires a complete local round with an interior winner and actual width at most $2\times10^{-14}$. The formal candidate is the first cumulative minimum across all newly computed successful rows; the final-round winner is retained separately. Neither a metric plateau nor a historical candidate stops the search.

For operational recovery, rerun the same command with `--resume`. It validates current-attempt request equality, reuses only already completed batches, preserves failed batch directories with a `-failed-N` suffix, and executes incomplete batches. It never imports another experiment's state. Resume elapsed time is explicitly labeled as the current controller invocation; successful batch process walls remain separately accumulated. No resume has been used unless the run records say otherwise.

## Evidence and timing

Each point retains the four matching metrics, its full construction time, actual node, backend and callback ledger. Rounds retain actual endpoints/width, selected point and neighbors, strict dips and cumulative winner. `estimate/scientific.mat` retains matrices, physical densities, normalized port vector, propagation coordinates, signed jumps, finite cells/tails and mass samples. Scalar CSVs use 17 significant digits.

Search construction, final-field construction, jumps, mass, geometry/assembly and export/save are disjoint timers. Callback timers are subsets and must never be added to totals. The successful monitored process-batch wall sum includes MATLAB startup/shutdown, process preflight/cleanup and wrapper overhead. Pipeline elapsed time additionally includes controller work. Common configuration setup and failed execution costs are reported separately. `point.seconds` times `LOCAL_full_point`; outer configuration and wrapper work belong to the unclassified process overhead.

Initial source snapshots are under `output/run-02/source`. `source-metadata-update` records the later metadata exporter and the exactly equivalent geometry closure from literal neighbor shifts to the configured $L=1$ before either estimator. Search does not call that geometry helper. The first three wide batches lack the added environment JSON; their command records identify the same MATLAB executable and OpenMP settings. Later batches record actual MATLAB version, thread counts and resolved dependency paths. The active controller retains its original launch implementation. Later source-only additions for explicit resume and failure-status retention after an unavailable cleanup query were not used by this execution; the initial controller snapshot preserves the exact executed version. Controller and scientific sources are now frozen except for an actual blocking run failure.

After both pipelines complete:

```sh
python test/i8/pipeline-v1/summarize_pipeline.py \
  test/i8/pipeline-v1/output/run-02
```

This writes `summary.json`, `summary.csv`, `callbacks.csv`, `components.csv` and `rounds.csv` into the supplied run directory by default (`output/run-02/` above); `--summary-dir` remains an explicit override. These generated summaries stay under ignored output alongside the raw data. Key numerical results and timings remain in this README and the design document. Independent review scripts in this directory inspect the completed evidence without rerunning the scientific pipelines. The summaries distinguish finite sampled numerical evidence from continuous certification.

The independent review is [review-8-4c](../../../research/projects/eig-apost/implementation/i8/review-8-4c.md): **PASS WITH CONDITIONS**, no unresolved blocker. With an already installed Python interpreter containing NumPy, the saved evidence can be audited as follows; these are post-run matrix/data checks, not additional MATLAB pipelines:

```sh
env OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 "$AUDIT_PYTHON" test/i8/pipeline-v1/skeptic_search_audit.py test/i8/pipeline-v1/output/run-02
env OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 "$AUDIT_PYTHON" test/i8/pipeline-v1/skeptic_audit.py test/i8/pipeline-v1/output/run-02
env OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 "$AUDIT_PYTHON" test/i8/pipeline-v1/skeptic_matrix_order.py test/i8/pipeline-v1/output/run-02
```

Set `AUDIT_PYTHON` to the existing interpreter before these commands. This run used the bundled Python 3.12.14 with NumPy 2.3.5, without installing packages. Exact commands, exits and audit timings are saved in `output/run-02/review/commands.json`; raw outputs and operational logs are alongside it. The matrix-order check retains each field's saved C and U and diagnoses cancellation; it does not replace the reported R value or provide an error bound. Run these audits after MATLAB has exited so their CPU use does not enter the pipeline timing comparison.

The task clock started at 04:47:41 UTC. At the final scope check at 06:50:01 UTC, elapsed task time was 7340.73 seconds (122.35 minutes), including design, implementation, all scientific runs and independent review, within the three-hour authorization. `output/run-02/review/closeout.json` retains this checkpoint and the accepted subagent creation parameters (`gpt-6-astra`, `high`); runtime model telemetry was unavailable. No MATLAB process remained at the final read-only process check. No further scientific run is planned in this task.

## FMM callback coverage

The completed FMM ledger records two smooth proxy callbacks per search point: one with $256\times256=65536$ pair-difference targets and one with $512\times512=262144$. Across 242 search points this gives 484 callbacks. The fresh final estimator adds 117 callbacks, split as follows:

| Estimator stage | Callback count | Pair-difference targets per callback |
|---|---:|---:|
| Fresh field construction | 2 | 65536 once; 262144 once |
| Material jumps | 2 | $768\times768=589824$ |
| Wall jumps | 48 | $64\times768=49152$ |
| Disk mass integration | 64 | $32\times768=24576$ |
| Existing disk-center diagnostic | 1 | $2\times768=1536$ |

Thus the estimator stage totals are field 2, jumps 50, and mass 65; the complete FMM pipeline has 601 callbacks. In `kernel.qpgreen_mfs_pairmat`, each physical target is paired with each boundary source, and the flattened differences become the proxy evaluator's targets. The callback ledger's `nt` therefore counts these pair-difference targets, not physical quadrature samples; its `ns` counts proxy sources.

The main mass quadrature has exactly $32\times64=2048$ physical disk samples. `LOCAL_center_field` evaluates them in 64 batches of 32 against 768 boundary sources. `LOCAL_mass_diagnostic` also evaluates the existing disk-center diagnostic. For that singleton, `LOCAL_center_field` duplicates the physical target into two identical columns before pair assembly, then retains only the first output row. This produces the ledger count $2\times768=1536$ and applies equally to DIRECT and FMM. The singleton contributes to the existing cone diagnostic; it does not add an integration sample or another evaluation grid.

Only the smooth proxy callback uses FMM. Free-space kernels, singular Kress terms, and near-singular evaluation remain unchanged. The callback counts describe this specific acceleration coverage, not replacement of the entire field evaluator by FMM.

## Completed run-02 results

Both pipelines completed 242 search calls (one wide round plus 19 local rounds), followed by one additional fresh field each. Both final valid interior rounds have actual width $1.3322676295501878\times10^{-14}$; neither used recovery or an early metric stop. The DIRECT cumulative candidate is first attained in round 19; the FMM cumulative candidate is first attained in round 18 and is also the final-round winner. Independent raw-evidence review is recorded separately.

| Quantity | DIRECT | FMM |
|---|---:|---:|
| Candidate $k_*$ | 1.7562818500073463 | 1.7562818500073423 |
| Monitored process-batch wall, seconds | 5379.437807375798 | 880.2575305858627 |
| Backend controller elapsed, seconds | 5379.567750209011 | 880.3665725419996 |
| Search construction sum, seconds | 4706.354323 | 544.0781507916666 |
| Final estimator process-batch wall, seconds | 302.4098034169292 | 58.264720167033374 |
| $R_{\rm num}$ | 7.052160861927365e-10 | 7.063227413047818e-10 |
| $D_{\rm num}$ | 0.11608305826637501 | 0.11608305826635415 |
| Peak process-tree RSS, bytes | 1513144320 | 1616920576 |

The successful monitored process-batch speed ratio is 6.11120907286697. The candidate difference (FMM minus DIRECT) is $-3.9968028886505635\times10^{-15}$. The ordinary estimator difference is $1.1066551120452309\times10^{-12}$, or 0.1569242582113733% relative to DIRECT. These are differences between independently constructed candidate fields, not a kernel-error estimate, eigenvalue error, or certification. Both results remain `UNCERTIFIED_RNUM` and have `certified=false`.

Common setup cost is 13.735071541974321 seconds. The separately retained interrupted bootstrap costs 10.488923000055365 seconds. Neither is hidden inside the reported backend speed ratio; both remain inside the original overall task budget. This is one ordered DIRECT-then-FMM comparison on this machine, without repeated timing trials.
