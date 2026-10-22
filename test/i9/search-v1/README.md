# I9.1 common projected-gap and candidate search

This standalone experiment implements `design-9-1a`. It uses two independently
constructed, globally oriented asymmetric trilobe leads. It only classifies
Bloch data and searches matching-matrix dips; it computes no spectral-distance
quantity and does not use historical candidates or results.

## Frozen computation

`search_i9_config.m` is the only scientific parameter source. It freezes
$\beta=0.5$, negative/positive radial deformation $a=0.12/0.20$, lead material
17, the unchanged area-scaled five-star center with material 2, FMM request
$10^{-12}$, and coarse center/negative/positive nodes 256/128/128 versus fine
512/256/256. All three inclusions have area $0.04\pi$.

The initial 33-point frequency exploration window is $[1.45,2.25]$. Each lead
uses its own scattering pencil and homogeneous QZ diagnostics. A two-ring
classification distinguishes numerical near-unit multipliers, uncertainty,
qualified balanced decay, and invalid pencils. Only qualified common-gap
points may construct a center matching matrix. Numerical transition brackets
have requested width $10^{-4}$, with inward search buffer 0.001; window-ended
segments are explicitly truncated. The source documents specify the one
permitted extension and all qualifications.

The common-gap coarse grid reuses current-run classified nodes, inserts safe
endpoints, subdivides gaps larger than 0.025, and provides at least 11 nodes.
All internal dips and endpoint trends have explicit lineage. Fine rounds use
11 actual nodes, independent left/right lead reclassification, and the unchanged
`aphys_ratio` score. Normal completion requires an interior winner and actual
whole-round width $W\le2\times10^{-14}$. Fresh confirmations bypass both point
and lead caches.

## Files and source relationships

- `search_i9_geometry.m`: analytic six-row radial geometry in the public
  `[x;x';x'';y;y';y'']` convention; no mirroring or finite differences.
- `search_i9_classify.m`: standalone homogeneous Bloch classifier.
- `search_i9_physics.m`: the scattering, matching weights, DtN signs and FMM
  mapping extracted from I8.5 `scan_i8_point`; independent left/right shapes
  and explicit `leads`/`match` actions replace the single shared circular lead.
- `search_i9_run.m`: local grid, cache, gap, scheduling, dip, branch and export
  helpers based on I8.5 `scan_i8_search`, with a common-gap stage before search.
- `run_search.py`: serial MATLAB launcher and process-tree monitor, adapted
  from I8.5; one 2400-second hard limit, 3,000,000,000-byte RSS cap, no grace.
- `collect_search.py`: current-run standard-library tables and summaries only.
- `search_i9_plot.m`: current-run figures only, with no physical evaluations.
- `audit_i9.py`: independent saved-result audit, maintained by the audit owner.

No runtime code calls another I8 experiment. The installed official FMM2D
MATLAB interface is the only dependency located inside an older experiment's
vendor directory. Public package interfaces and the installed vendor remain
unchanged. The reviewed FMM commit is
`550dae5b77b1e006c8ffae37fc832f8c2b536871`.

## Run from empty output

Use the existing Conda `octave` environment for Python. Set explicit launcher
paths to the package root, installed FMM2D MATLAB directory and MATLAB binary.
The numerical functions resolve dependencies on ordinary MATLAB path and do
not discover the repository, read Markdown/Git, or load historical data.

```bash
conda activate octave
python run_search.py --mode selftest --output output/attempt-1/setup-01 \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python run_search.py --mode run --output output/attempt-1/run-01 \
  --config output/attempt-1/setup-01/config.json \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python collect_search.py output/attempt-1/run-01
```

The setup export only supplies monitor limits from the unique configuration;
MATLAB loads its configuration from `search_i9_config`. The science entry also
runs the cheap synthetic checks before physical evaluations. The full gap,
representative checks, matching searches and confirmations share the same
monitored process clock. Checkpoints are outputs of this run; the from-zero
entry needs none. Reuse the attempt with a new run suffix after an operational
failure and preserve its evidence.

The launcher refuses pre-existing MATLAB, samples process-tree RSS once per
second, enforces the hard limits, and kills its process group on interruption
or monitor failure. It records environment, commands, timestamps and survivors.
All generated CSV/JSON/MAT/images/logs stay under this experiment's ignored
`output/` directory. Normal successful point timing includes new lead work
needed by that request and center/matching work; cached lead lookup is included.
Lead-level times are nested diagnostics and must not be added again.

## Results

The completed current run and independent review are summarized below.

### Completed run (2026-10-22)

The authoritative raw run is `output/attempt-1/run-01/`. MATLAB R2023b on
MACA64 used 11 MATLAB threads and `OMP_NUM_THREADS=11`, `OMP_DYNAMIC=FALSE`.
The initial 33 exploration points on **each** side all classified `GAP`.
Consequently the observed numerical gap segment is $[1.45,2.25]$ **truncated at
both exploration-window boundaries**; no physical band edge was located or
claimed. The buffered common search interval was
`[1.4509999999999998, 2.249]`. No extension was needed under the frozen rule.
Three representative points (both buffered ends and midpoint 1.85) were GAP
for both leads at both resolutions; relative scattering-matrix differences
were between approximately $2.7\times10^{-16}$ and $1.94\times10^{-15}$.
This small check is numerical consistency evidence, not a global convergence
or band-coverage proof.

The coarse common-interval grid contained 44 actual points, because the rule
retained current-run classified nodes and supplemented actual gaps exceeding
0.025. It found one internal dip and one left-boundary downward trend. The
internal branch completed 19 fine rounds; the boundary branch completed its
one fine check and remained unresolved. There was no observed separable fine
dip split and no unreported nonwinning endpoint trend.

| Field | Formal candidate | Left boundary provisional point |
|---|---:|---:|
| `k` | **1.7585257790608451** | 1.4509999999999998 |
| `adef_sigma` | 9.078700854412531e-14 | 4.2041574606846313 |
| `adef_ratio` | 1.5026594195573455e-16 | 0.0069584654758720445 |
| `aphys_sigma` | 4.5313501077829634e-14 | 1.3730572816349851 |
| `aphys_ratio` | 1.583142462304327e-14 | 0.32084496179980937 |
| actual whole `W` | 1.9761969838327786e-14 | 0.049000000000000155 |
| status | `COMPLETE`, fine interior winner | `BOUNDARY_UNRESOLVED` |

Both points were freshly reconstructed with both lead and matching caches
bypassed. All four metric differences were exactly zero. At the formal
candidate both independently constructed forward pencils had 97 stable and
97 unstable multipliers, zero near-unit/uncertain/indeterminate counts, and
minimum homogeneous circle distances 0.6649474848367948 (negative) and
0.6579082975883048 (positive). QZ residuals were about $4.6\times10^{-15}$.
The negative decay subspace was independently obtained from its reciprocal
pencil. The boundary provisional point is **not** an additional located candidate.

The same-lead regression used independent constructions with the same
negative-lead geometry and gave zero Frobenius differences in both full
`Adef` and `Aphys` compared with the one-lead shared assembly. At the same
representative point the different-side full scattering matrices differed by
0.018984949413932816 in Frobenius norm. The actual analytic geometry checks
confirmed CCW orientation, positive radius/speed, area, endpoint closure,
positive boundary clearances and unchanged global orientation.

| Work count | coarse | fine |
|---|---:|---:|
| actual matching calls | 44 | 171 |
| different matching `k` values | 44 | 169 |
| included fresh confirmations | 0 | 2 |
| actual lead-pair builds | 46 | 174 |
| different lead-pair `k` values | 46 | 171 |
| lead-cache hits | 35 | 0 |

There were 266 matching requests, 215 actual calls and 51 exact point-cache
hits. Each lead-pair build comprises two independent lead cells. The lead
cache separately avoided 35 pair builds (70 lead-cell constructions), reached
95,974,095 bytes and evicted 169 entries under its 96,000,000-byte cap. The
same-lead regression additionally built two lead cells and one center, outside
the cache ledger. Thus actual physical construction totals, including that
regression, were 442 lead cells and 216 center cells. Point-cache hits bypassed
the entire point request before querying the lead cache; these are separate
savings, not duplicated hit counts.

| Exclusive timing category | seconds |
|---|---:|
| numerical gap exploration | 25.25935825 |
| representative and same-lead validation | 7.608173916666667 |
| coarse matching search | 33.542282916666665 |
| fine matching search | 486.57384383333334 |
| fresh confirmations | 5.5038272500000005 |
| remaining science-process startup, geometry, save and plots | 44.39048237537827 |
| complete science process | **602.877968542045** |
| separate current-result plot process | 20.87797229201533 |
| complete monitored science plus presentation | **623.7559408340603** |

The science process peak sampled tree RSS was **1,341,112,320 bytes**; the
presentation process peak was 1,059,094,528 bytes. Neither observed concurrent
MATLAB, and both recorded no surviving descendants. The plotting monitor
explicitly inherited 602.8779689579969 elapsed seconds from science; its final
shared-budget clock was 623.7559416670119 seconds (small sampling/timer
roundoff explains the difference from summing process walls). Inner lead
and FMM callback times must not be added to the table again. The nested
same-lead regression callback ledger lists its final two lead calls; its
outer validation timer includes the center too.

### Evidence, review and operational history

`run-01/state.json` and `checkpoint.mat` retain every lead classification,
exact point key, request, gap source, grid, lineage and outcome. Small tables
are `lead-points.csv`, `points.csv`, `rounds.csv`, `intervals.csv` and
`candidates.csv`; `summary.json` includes the presentation clock. Full raw
matching evidence is in `candidate-evidence-0203.mat` and
`candidate-evidence-0215.mat`; the regression matrices are in
`equal-lead-validation.mat`. The six PNG figures cover geometry, two-sided
classification, common intervals, coarse search and both branches.

The independent saved-data audit reconstructed 12,649 checks and passed.
The research review is `implementation/i9/review-9-1a.md`. The valid finite
matrix candidate has no identified blocker. Important caveats are finite
frequency-grid coverage, unresolved/truncated band edges and the unresolved
left search-boundary trend, numerical unit-circle guards, and lack of
continuous-spectrum certification. The small resolution check does not prove
all frequencies converged. Single-run timing and sampled rather than
continuous RSS are minor limitations. No spectral-distance quantity was computed.

`setup-01` failed before MATLAB launch because sandbox restrictions denied
`ps`; `setup-02` succeeded with authorized monitoring. The completed science
run had no operational or numerical failure. The first collector failed
because the existing Python environment lacked matplotlib; its log is
`output/attempt-1/export-01.log`. No dependency was installed: the collector
now uses only Python's standard library and plots are rendered by existing
MATLAB. `plot-01/` retains that serial monitor's command and resource logs.
After science exited, an unexercised status-reporting guard was added for
future all-fine-representatives-unusable/coarse-failure outcomes and the
source help text was corrected; neither changes this run's numerical path.

To regenerate the additional figures and combined timing summary after the
from-zero science command, use the same package/FMM/MATLAB path variables:

```bash
python run_search.py --mode plot --output output/attempt-1/plot-01 \
  --config output/attempt-1/setup-01/config.json \
  --data-dir output/attempt-1/run-01 \
  --prior-status output/attempt-1/run-01/status.json \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python collect_search.py output/attempt-1/run-01 \
  --presentation-status output/attempt-1/plot-01/status.json
```
