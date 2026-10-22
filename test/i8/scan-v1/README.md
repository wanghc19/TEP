# I8.5 two-resolution, multiple-dip FMM search

This experiment implements `design-8-5a.md`. It searches candidates only and does
not evaluate any spectral-distance quantity. Its scientific configuration is
`scan_i8_config.m`: coarse center 256 / lead 128, fine center 512 / lead 256,
FMM tolerance $10^{-12}$, initial 33 nodes in the search window $[1.45,2.25]$,
11 nodes per local round, and actual whole-width target $W\le2\times10^{-14}$.
The window is not asserted to be the exact projected-gap endpoints.

`scan_i8_point.m` extracts only the matching-field helpers from the reviewed
I8.4 `pipeline_i8_numeric.m`. Its runtime dependencies are public packages and
the existing official FMM2D MATLAB library. It does not call another experiment.
`scan_i8_search.m` separates grid construction, scheduling, dip detection,
interval management, persistence and display into local helpers. Exact binary64
keys include the entire configuration and resolution. Successful points are
shared between overlapping branches; final confirmations bypass this cache.

All coarse internal minima and exact minimum plateaus are retained. Fine
minima are grouped only when their separating saddle fails the numerical
ambiguity threshold $64\,\mathrm{eps}\max(1,\max|s|)$; no relative-depth filter is
used. Every distinguishable group receives a branch. An ambiguity group is
refined using all of its minima and outer neighbors. Endpoint recovery expands
one full current width toward the global endpoint winner, retaining the other
end and clipping to the original search window. Internal groups seen during
recovery remain pending tasks and are later dispatched. Nonwinning descending
edges remain explicitly pending rather than being declared excluded.

A normal candidate is the first minimum of a complete fine round whose actual
whole width meets the target and whose winner is strictly interior. Cumulative
best points are separate diagnostics. Noncomplete branches retain provisional
best points and explicit stop reasons. Every terminal candidate is reevaluated
in fine resolution without cache reuse; no density or matrix is reused.

## From zero

Use the existing Conda `octave` Python environment. Supply absolute paths to the
package root, installed FMM2D **matlab** directory, and MATLAB executable. The
numerical functions themselves use ordinary MATLAB path resolution and contain
no local absolute paths. The following shell variables are examples to be filled
with the local installation paths:

```sh
conda activate octave
python run_scan.py --mode selftest --output output/attempt-1/setup-01 \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python run_scan.py --mode run --output output/attempt-1/run-01 \
  --config output/attempt-1/setup-01/config.json \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
```

Run directories must be new. Operational repairs use another run number in the
same attempt, preserving prior evidence. `checkpoint.mat` is detailed output,
not an external prerequisite; restart from zero rather than overwriting logs or
resetting a partial scientific run's budget. No resume interface is provided.
The cheap artificial test is not a physical search. Setup exports management
limits from the sole configuration; the science call reads that same MATLAB
configuration directly, not Markdown, Git metadata or historical results.

The monitor permits only one MATLAB process tree and records one-second RSS,
wall time and other MATLAB processes. The scientific call shares a 30-minute
planned/soft and 40-minute hard clock and a 3,000,000,000-byte RSS hard limit.
No shallow dip is dropped to fit the budget. After coarse detection the script
estimates all queued fine work, and returns `BUDGET_REASSESSMENT_REQUIRED` if the
conservative plan cannot fit. A soft-limit extension requires objectively near
completion. Interrupts and monitor failures kill the owned process tree.

All generated CSV, JSON, MAT, plots and logs reside under `output/`. Results and
resource evidence are summarized below. No spectrum certification or
no-missed-mode claim is made.


## Executed result: attempt-1 / run-01

The formal run on 2026-10-22 used MATLAB R2023b (`23.2.0.2365128`, MACA64),
11 MATLAB threads and `OMP_NUM_THREADS=11`, `OMP_DYNAMIC=FALSE`. The installed
FMM2D commit is `550dae5b77b1e006c8ffae37fc832f8c2b536871`; no installation or
vendor changes were made.

The 33 coarse points revealed **one internal dip**, at actual coarse node
$k=1.75$, with adjacent-node interval $[1.725,1.775]$. Its fine start window was
expanded to $[1.7,1.8]$. The fine run retained this dip, with no observed
resolvable split or disappearance, and completed 21 local rounds. The change
from the coarse winning node to the fine candidate is about $0.00628185$;
this is an observed sampled-location difference, not a discretization-error
estimate. The selected fine point also equals the cumulative best point.

A separate coarse left-end descending direction was retained and actually
checked on the fine window $[1.45,1.525]$. Its minimum remained at the original
search boundary $1.45$. Expansion to the left is prohibited by the frozen
window, so this task terminated `BOUNDARY_UNRESOLVED`; it is not a located dip.
The initial `FINE_ENDPOINT_CHECK_PENDING` record is a creation event, whose
terminal outcome is interval 2's boundary status.

| Quantity | Located candidate, interval 1 | Boundary provisional point, interval 2 |
|---|---:|---:|
| Resolution | fine 512 / 256 | fine 512 / 256 |
| $k$ | 1.7562818500073423 | 1.45 |
| `adef_sigma` | 8.058217624380668e-14 | 4.099017761904005 |
| `adef_ratio` | 1.3337542770756416e-16 | 0.006784444539618595 |
| `aphys_sigma` | 3.9888699158095294e-14 | 1.3728810878019677 |
| `aphys_ratio` | 1.3967792552871384e-14 | 0.32530670466799405 |
| Actual full width $W$ | 4.218847493575595e-15 | 0.07499999999999996 |
| Last-round winner index | 2 of 11 | 1 of 11 |
| Status | `COMPLETE` | `BOUNDARY_UNRESOLVED` |

Both points received independent fine calls bypassing the cache. All four
matching metrics reproduced with **zero observed absolute difference**. The
normal candidate reached the prescribed width with a strictly interior winner;
no small-singular-value or platform early stopping was used.

Three nonwinning edge observations remain explicitly pending: interval 1,
round 20 left edge ($k=1.7562818500073252$); interval 1, round 21 right edge
($k=1.756281850007346$); and interval 2 right edge ($k=1.525$). The first two
are at the final numerical-floor scale. They are retained as unresolved
directions, not recursively promoted to numerous new candidates and not
claimed excluded. The overall status is therefore
`SEARCH_FINISHED_WITH_UNRESOLVED_INTERVALS`, while the one interior candidate
independently satisfies `COMPLETE`.

| Count | coarse | fine | Total |
|---|---:|---:|---:|
| Requested calls, including confirmations | 33 | 244 | 277 |
| Actual search calculations | 33 | 186 | 219 |
| Additional cache-bypassing confirmations | 0 | 2 | 2 |
| Actual calls | 33 | 188 | 221 |
| Distinct successful binary64 $k$ values | 33 | 186 | per-resolution keys |
| Cache hits | 0 | 56 | 56 |

| Nonoverlapping time account | Seconds |
|---|---:|
| Coarse physical evaluations | 32.92858625 |
| Fine search physical evaluations | 423.39261445833307 |
| Final confirmation physical evaluations | 4.658247291666667 |
| Remaining process work, including management, persistence, plots and startup/exit | 19.46142720893687 |
| Complete monitored formal process | 480.44087520893663 |

The MATLAB search clock was 463.8954342083333 s; it is a parent timer and must
not be added to the point-stage totals. Peak sampled process-tree RSS was
**1,225,981,952 bytes** (about 1.226 GB), below the 3,000,000,000-byte cap.
No other MATLAB was observed, and cleanup found no remaining child process.
The completed formal run stayed well below the shared 30-minute soft limit.

Setup-01 failed before launching MATLAB because the sandbox denied `ps`.
Its failure is preserved. Setup-02 and setup-03 completed cheap synthetic tests
in 16.73684108396992 s and 14.724554916960187 s, respectively. The final setup
passed 11 tests, including actual manager coarse-one-to-fine-two branching,
endpoint recovery with internal pending dips, exact floating-point cache keys,
resolution separation, plateau handling and evaluator failures. Setup/debug
costs are separate from the successful 480.44-second physical run. The resource
forecast was conservatively updated before science from 3 to 2.5 seconds per
new fine point and counted guaranteed cached endpoints; the source configuration
and resource-plan note preserve this non-scientific planning change.

Independent review passed 2,927 raw-record checks. The review reports the
boundary and pending-edge limitations rather than converting them into
successful localization claims. No $C_{\mathrm{num}}$, $\varepsilon_{\mathrm{num}}$,
$U_{\mathrm{num}}$ or $R_{\mathrm{num}}$ was computed.

### Outputs and postprocessing

The complete run is `output/attempt-1/run-01/`:

- `state.json` and `checkpoint.mat`: all points, request/cache ledger, source
  intervals, actual grids, winners, decisions, pending directions and confirmations.
- `summary.json`, `candidates.csv`, `rounds.csv`, `intervals.csv`, `points.csv`:
  precise readable output tables.
- `candidate-evidence-0209.mat` and `candidate-evidence-0221.mat`: fresh
  confirmation matching matrices, scattering data and field evidence.
- `coarse.png`, `branch-001.png`, `branch-002.png`: generated search curves.
- `command.json`, `environment.json`, `resources.csv`, `status.json`, `run.log`:
  execution and resource evidence.
- `source/`: the exact executed numerical source snapshot.
- `review/audit.json`: independent audit output.

Regenerate the small tables from this current run with:

```sh
python collect_scan.py output/attempt-1/run-01
"$AUDIT_PYTHON" audit_scan.py output/attempt-1/run-01
```

The audit uses an already installed Python with NumPy; set `AUDIT_PYTHON` to
that interpreter. The Conda `octave` interpreter used for launch/collection does
not have NumPy on this host. No package installation is required for the search,
and the independent audit is not a numerical runtime dependency.

After the successful run, three bounded non-scientific repairs were made:
exceptions preserve the last completed checkpoint; a failed final confirmation
forces an overall failure-status label; and global-endpoint event wording is
separated from nonwinning-edge wording. `postrun-repair.patch` records these
changes against the executed source. They do not change the successful search
path, and no scientific rerun was performed for them. Raw run data were retained.
