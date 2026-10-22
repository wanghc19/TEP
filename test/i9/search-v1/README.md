# I9.1 common projected-gap and candidate search

This standalone experiment implements `design-9-1a`. It uses two independently
constructed, globally oriented asymmetric trilobe leads. It only classifies
Bloch data and searches matching-matrix dips; it computes no spectral-distance
quantity and does not use historical candidates or results.

## Frozen computation

`search_i9_config.m` is the only scientific parameter source. It freezes
$\beta=0.5$, negative/positive radial deformation $a=0.12/0.20$, lead material
17, the native public five-star center with relative permittivity 4 and extra scale 1, FMM request
$10^{-12}$, and coarse center/negative/positive nodes 256/128/128 versus fine
512/256/256. The current center has area $0.0618\pi$; both leads retain
area $0.04\pi$. The public star formula retains its internal 0.2 multiplier.
The previous controlled comparison removed only the additional
`sqrt(0.04/0.0618)` normalization. The current material comparison changes
only center relative permittivity from 2 to 4, so the interior wavenumber is
`sqrt(4)*k = 2*k`. The completed scaled and native-material-2 baselines remain below.

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
python run_search.py --mode selftest --output output/attempt-3/setup-01 \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python run_search.py --mode run --output output/attempt-3/run-01 \
  --config output/attempt-3/setup-01/config.json \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python collect_search.py output/attempt-3/run-01
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

### Historical scaled baseline: attempt-1 (2026-10-22)

The preserved scaled-baseline raw run is `output/attempt-1/run-01/`; it used
`star_scale=sqrt(0.04/0.0618)` and center area $0.04\pi$. MATLAB R2023b on
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
python run_search.py --mode plot --output output/attempt-2/plot-01 \
  --config output/attempt-2/setup-01/config.json \
  --data-dir output/attempt-2/run-01 \
  --prior-status output/attempt-2/run-01/status.json \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python collect_search.py output/attempt-2/run-01 \
  --presentation-status output/attempt-2/plot-01/status.json
```

## Historical native-center controlled comparison: attempt-2

The attempt-2 configuration changed only `model.star_scale` to 1. Geometry
validation now uses the center's analytic area
$0.0618\pi\,\mathrm{star\_scale}^2$ and retains the separate strict lead-area
checks. The analytic position envelopes are $|x|\le0.36\,\mathrm{star\_scale}$
and $|y|\le0.26\,\mathrm{star\_scale}$; these are upper bounds, not claims
that the sampled extrema attain both bounds. All six center geometry rows
receive the same factor. The common-gap classification, grids, score, cache
identities, multiple-dip rules, fine-width target and fresh confirmations are
unchanged. This attempt begins from empty output and does not read attempt-1.

The audit now independently reconstructs all six center rows, verifies the
public internal 0.2 factor, checks center/lead areas separately, and accepts
`--expected-star-scale` (default 1). At that time the audit was invoked explicitly as follows (a historical command,
not a claim that the current stricter material-metadata audit accepts old MAT files):

```bash
python audit_i9.py output/attempt-2/run-01 --expected-star-scale 1
```

The historical audit output and its then-current code remain preserved.
The current material-comparison audit additionally requires raw `rho`, `kext`
and `kint` fields, absent from historical MAT files; it does not silently
skip this evidence requirement or rerun the old physics.

### Attempt-2 observed results and comparison

The complete fresh run is `output/attempt-2/run-01/`; its six figures are saved
there. The center area measured on 2048 analytic geometry nodes was
0.19415042599184917 versus analytic $0.0618\pi=0.19415042599184923$.
The minimum sampled speed and horizontal wall clearance were both 0.14;
vertical clearance was 0.2508140559911424. Both lead areas remained
$0.04\pi$. The 54.5% increase in center area is intentional; the two leads,
materials, discretizations and auxiliary settings are unchanged.

A post-run recursive configuration comparison found exactly one changed
field: `model.star_scale`, from 0.8045179867091297 to 1. Both newly computed
33-point lead classifications remained GAP throughout the exploration window;
the observed segments are still **double-truncated**, with common search
interval `[1.4509999999999998,2.249]`. All three coarse/fine lead representative
checks passed. The same-lead Adef/Aphys regression again gave zero differences.
These results are freshly computed; the baseline was read only by the optional
post-run reporting command.

The 44-point coarse matching search found one internal dip, now at sampled
`k=1.725`, and the left-boundary trend. Fine refinement completed 19 rounds
without a resolved multi-dip split. The formal candidate follows the unchanged
first-minimum rule on the final full valid round:

| Quantity | Scaled baseline, attempt-1 | Native center, attempt-2 |
|---|---:|---:|
| center extra scale | 0.8045179867091297 | 1 |
| center analytic area | $0.04\pi$ | $0.0618\pi$ |
| formal `k` | 1.7585257790608451 | **1.7245767064712256** |
| `adef_sigma` | 9.078700854412531e-14 | 9.968314121327948e-14 |
| `adef_ratio` | 1.5026594195573455e-16 | 1.6499025187720787e-16 |
| `aphys_sigma` | 4.5313501077829634e-14 | 4.99358987318351e-14 |
| `aphys_ratio` | 1.583142462304327e-14 | 1.6870752240995276e-14 |
| actual final whole `W` | 1.9761969838327786e-14 | 1.9761969838327786e-14 |
| normal status | `COMPLETE` | `COMPLETE` |
| fresh four-metric absolute differences | all zero | all zero |

The signed candidate difference is **-0.03394907258961943**, absolute difference
0.03394907258961943, and absolute relative difference 0.019305416499353346
(about 1.93054%). This compares the sole observed candidate in each model;
it is neither a certified mode-identity statement nor an eigenvalue error.
The four absolute metric changes are 8.896132669154173e-15,
1.4724309921473318e-17, 4.6223976540054625e-15 and
1.0393276179520058e-15 respectively. Near-zero metric changes do not establish
an improvement or degradation in spectral accuracy.

The cumulative best point differs from the formal final-round point:
point 189 at `k=1.7245767064712216` had four metrics
`9.847315888199273e-14`, `1.6298755325459087e-16`,
`4.9099535976094885e-14`, `1.6588188610540434e-14`.
The final-round `aphys_ratio` increased by 2.8256363045484195e-16,
or **1.7034025660601415%**, relative to that accumulated best. Both records
remain saved; the formal candidate was not substituted after observing this
increase.

At the formal candidate both leads independently retain 97 stable and 97
unstable multipliers, with zero near-unit/uncertain/indeterminate counts.
Their minimum homogeneous circle distances are 0.6566213916707055 and
0.6496274149681597, and QZ residuals are 4.9172886169144614e-15 and
4.80992613267099e-15. The fresh full point recomputation bypassed both caches.

Two unresolved observations are retained:

- The coarse-window left trend remains `BOUNDARY_UNRESOLVED` after its fine
  check, at `k=1.4509999999999998`, with four metrics
  `3.8378435237052413`, `0.006352164948920149`, `1.3722988238019735`,
  `0.31982334389900036`, and `W=0.049000000000000155`. Its fresh four-metric
  differences are all zero, but it is not a located candidate.
- Fine branch 1, round 19, has a nonwinning left-end trend at point 188,
  `k=1.7245767064712119`, `aphys_ratio=2.282455008701525e-14`, recorded as
  `NONWINNING_EDGE_PENDING`. This numerical edge ambiguity is not silently
  discarded and is not claimed to be another mode. The final-round interior
  candidate still satisfies the frozen normal completion conditions.

Counts matched the baseline: 266 matching requests, 215 actual calls and
51 point-cache hits; coarse 44 matching points, fine 169 different matching
points and two extra confirmations. There were 46 coarse and 174 fine
lead-pair constructions, and 35 lead-cache hits. Including the separate
same-lead regression, there were 442 lead-cell and 216 center-cell
constructions. No additional physical evaluation was performed for reporting.

| Timing or resource | Scaled baseline | Native center |
|---|---:|---:|
| gap exploration, s | 25.25935825 | 24.300710916666667 |
| representative/regression checks, s | 7.608173916666667 | 6.725618041666666 |
| coarse search, s | 33.542282916666665 | 32.983866875000004 |
| fine search, s | 486.57384383333334 | 475.9859458333333 |
| confirmations, s | 5.5038272500000005 | 5.358331041666666 |
| remaining science process, s | 44.39048237537827 | 45.42556500059641 |
| complete science process, s | 602.877968542045 | 590.7800377089297 |
| presentation process, s | 20.87797229201533 | 18.9000017499784 |
| sum of science and presentation process durations, s | 623.7559408340603 | 609.6800394589081 |
| elapsed wall clock from science launch to plot finish, s | 769.175876 | 666.045271 |
| peak science tree RSS, bytes | 1341112320 | 1458012160 |

The attempt-2 plotting monitor explicitly inherited the accumulated science
process timer; its final accumulated process clock was 609.6800405828981
seconds. Separately, the actual cross-batch wall-clock span from science
launch at 13:02:42.464902 UTC to plot completion at 13:13:48.510173 UTC
was **666.045271 seconds**, including the interval between processes. Both
are below the 2400-second hard budget; the process-duration sum is not the
full elapsed wall clock. The matching baseline elapsed span was 769.175876 seconds. No other MATLAB
was observed and neither process left survivors. Setup, science and plot all
succeeded on their first attempt-2 invocation. These are single-run observed
timings, not a performance claim for changing center scale.

`summary.json` contains formal-versus-cumulative records and unresolved edges.
`comparison.json`/`comparison.csv` preserve both models' candidates, configuration
difference, geometry, classifications, intervals, counts, timings and memory;
`comparison-command.json` records the explicit reporting command. Reproduce
only that optional post-run comparison using:

```bash
python collect_search.py output/attempt-2/run-01 \
  --presentation-status output/attempt-2/plot-01/status.json \
  --baseline-run output/attempt-1/run-01
```

The fresh science commands do not require this comparison or any baseline
file. Continuous-spectrum certification, complete gap-edge localization,
finite-grid coverage and spectral-distance estimation remain outside this
controlled comparison. No $C_{\mathrm{num}}$, $\varepsilon_{\mathrm{num}}$,
$U_{\mathrm{num}}$ or $R_{\mathrm{num}}$ was computed.

## Center-material controlled comparison: attempt-3

The current configuration changes only `model.rho_center` from 2 to 4. This
parameter is relative permittivity; `kint=sqrt(rho_center)*kext=2*k` in the
center, while the unchanged lead relation is `sqrt(17)*k`. The native star,
its six analytic geometry rows and extra scale 1, all lead geometry/materials,
FMM tolerance, discretizations, common-gap and multi-dip search rules remain
unchanged. No anticipated frequency is used as a seed, target or stopping rule.

The compact raw cell evidence now includes `rho`, `kext` and `kint`, using
the same local values actually passed to `bloch.construct_S`. The independent
audit requires this evidence and checks the center and each lead separately:

```bash
python audit_i9.py output/attempt-3/run-02 \
  --expected-star-scale 1 --expected-rho-center 4
```

The monitor records `budget_started_utc` and carries the original science
start into the presentation batch. Its shared hard clock now includes time
between processes, rather than summing process runtimes alone. This changes
resource accounting only, not scientific parameters or computation.

After the full new science run, the optional comparison uses attempt-2 as the
explicit primary baseline. Its labels are neutral `baseline` / `current`,
with `rho_center` and `star_scale` stored alongside every candidate:

```bash
python run_search.py --mode plot --output output/attempt-3/plot-02 \
  --config output/attempt-3/setup-01/config.json \
  --data-dir output/attempt-3/run-02 \
  --prior-status output/attempt-3/run-02/status.json \
  --package-root "$PACKAGE_ROOT" --fmm-root "$FMM_MATLAB" --matlab "$MATLAB_BIN"
python collect_search.py output/attempt-3/run-02 \
  --presentation-status output/attempt-3/plot-02/status.json \
  --baseline-run output/attempt-2/run-01
```

### Preserved operational diagnosis

The first material run (`attempt-3/run-01`) reached the first fine round but
reported `MATLAB:error:missingMessageArgument` at $k=1.5875$. It therefore did
not complete the internal dip. The original assertion trigger was obscured
by identifier-only `assert` calls; it is **not established** that the BIE
qualification threshold was exceeded. All original raw records are retained.

A same-configuration, exact-point diagnostic (`diagnose-01`) succeeded. Its
center BIE relative residual was $1.2926313512724865\times10^{-15}$; the two
lead residuals were $3.4251193729025305\times10^{-15}$ and
$3.299794023355351\times10^{-15}$. The evidence records center relative
permittivity 4 and interior wavenumber 3.175 at exterior wavenumber 1.5875.
This did not reproduce the earlier failure and does not identify its cause.

The temporary `search_i9_diagnose.m` source is archived inside
`output/attempt-3/diagnose-01/`, alongside its evidence. It is not part of the
permanent search entry points. The historical `command.json` is unchanged and
records its original pre-archive MATLAB path. To inspect or manually reproduce
that diagnostic, explicitly add the archived source directory and this
experiment's current source directory to the MATLAB path, together with the
public packages and installed FMM2D; use a new output directory and call
`search_i9_diagnose(new_output,1.5875,'fine')`. The normal fresh search requires
none of this archived source or evidence. This archival edit did not rerun MATLAB.

The corrected full `run-02` starts from the unchanged wide grid. The repair
only supplies missing assertion messages and saves point/lead exception
stacks and extended reports; no assertion condition, tolerance or algorithm
was changed. The failed first run (184.531165708 s) and diagnostic process
(20.955598208 s) remain separate from corrected-run performance. Their
combined process cost was 205.486763916 s and counts toward total task time.
An unreproduced original operational failure remains an important caveat.

### Completed material comparison

The corrected `attempt-3/run-02` completed with no failed evaluation. Only
`model.rho_center` differs from the completed attempt-2 baseline. The two
geometry reports are identical. Both leads classify all initial 33 exploration
nodes as numerical `GAP`; the safe common search interval remains
$[1.4509999999999998,2.249]$. Both exploration ends remain truncated, so these
are not measured full band edges. The three representative coarse/fine lead
checks and all actual fine candidate-neighborhood classifications are `GAP`.
No frequency extension was used.

The coarse search found one interior dip. Its neighbor bracket
$[1.5375,1.575]$ was expanded to $[1.525,1.5875]$ before fine sampling. After
19 fine rounds, the formal candidate is the fifth node of the final grid
$[1.5584378941820844,1.5584378941821007]$. Its final-round winner and cumulative
best are the same point 196. The only other task follows the coarse right
endpoint trend; it remains `BOUNDARY_UNRESOLVED` at 2.249. No fine dip split or
nonwinning unresolved fine edge was recorded. A boundary trend is not counted
as a formal candidate.

| Quantity | Baseline: center material 2 | Current: center material 4 |
|---|---:|---:|
| candidate $k$ | 1.7245767064712256 | 1.5584378941820909 |
| `adef_sigma` | 9.968314121327948e-14 | 1.9492443044385317e-13 |
| `adef_ratio` | 1.6499025187720787e-16 | 3.226276216246245e-16 |
| `aphys_sigma` | 4.99358987318351e-14 | 1.0508097636631883e-13 |
| `aphys_ratio` | 1.6870752240995276e-14 | 2.9344919212372774e-14 |
| final full width $W$ | 1.9761969838327786e-14 | 1.6209256159527285e-14 |
| formal status | COMPLETE | COMPLETE |

The signed candidate change is $-0.16613881228913474$, with absolute change
0.16613881228913474 and relative change 0.09633599460419637. This compares the
sole observed candidate of each model; it does not establish mode identity or
an actual eigenvalue error. In the current run, the entire final round is
valid, both side classifications are `GAP`, and the four indicators agree
exactly with the full fresh bypass confirmation (point 201). The provisional
right boundary point also has a fresh confirmation (point 213); its indicators
are 3.5308048971248907, 0.005844067848480552, 1.3259522653041997 and
0.7335793554846374, with $W=0.06150000000000011$. Its status remains unresolved.

Matching requests total 266: 213 actual evaluations and 53 exact-cache hits.
The coarse tier uses 44 distinct matching points; the fine tier uses 167
distinct points plus 2 fresh confirmations, hence 169 actual fine calls.
Lead-pair construction counts are 46 coarse and 172 fine, with 35 coarse
lead-cache hits. The bounded lead cache peaks at 95,991,099 bytes and has 168
LRU evictions. Including the separately timed equal-lead regression adds two
lead cells and one center cell: 438 lead-cell and 214 center-cell constructions
in total. These counts do not include the failed first run or diagnostic.

| Corrected-run stage or resource | Observed value |
|---|---:|
| gap exploration, s | 28.40966425 |
| representative and equal-lead checks, s | 12.955570791666666 |
| coarse search, s | 39.87983062500001 |
| fine search, s | 508.24273658333317 |
| fresh confirmations, s | 5.739799666666666 |
| remaining science process, s | 47.75935312544709 |
| science process, s | 642.9869550421136 |
| plotting process, s | 18.86539620894473 |
| science plus plotting process durations, s | 661.8523512510583 |
| science-launch to plot-finish elapsed wall clock, s | 713.261805 |
| science peak process-tree RSS, bytes | 1422639104 |
| plot peak process-tree RSS, bytes | 1036795904 |

The monitored shared clock, including cleanup, ended at 713.2710374169983 s,
under 2400 s; no process tree exceeded 3,000,000,000 bytes and no MATLAB
survivors were left. The corrected process duration is distinct from elapsed
wall clock and from the 205.486763916 s failed-run/diagnostic cost. Including
setup, all five material-attempt processes total 887.3295123751741 s.
These are single-run observations, not a speedup claim for changing material.

Raw `candidate-evidence-0201.mat` and `candidate-evidence-0213.mat` contain
fresh two-lead, center and matching evidence. `state.json`, `checkpoint.mat`,
`points.csv`, `rounds.csv`, `lead-points.csv`, `summary.json` and the generated
figures preserve the actual search. `comparison.json`/`comparison.csv` compare
to attempt-2 only after computation. `comparison-command.json` and
`operational-history.json` preserve command and resource/failure provenance.
Every generated artifact remains under ignored `output/`; no old result is
needed for a fresh run. The final independent review is recorded in
`research/projects/eig-apost/implementation/i9/review-9-1a.md`.

The unreproduced original assertion trigger, truncated band edges and unresolved
right boundary trend remain explicit caveats. Finite-grid coverage and
continuous-spectrum certification are not claimed. No spectral-distance
quantity or $R_{\mathrm{num}}$ was computed.
