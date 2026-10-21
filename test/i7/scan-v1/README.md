# I7.1 ellipse scan

This experiment keeps both periodic half-guides at the reviewed circular
inclusion of radius $0.2$ and `epsrel=17`, and changes only the center cell to
the equal-area ellipse with semi-axes $(0.25,0.16)$. It implements the frozen
design in
[`design-7-1a.md`](../../../research/projects/eig-apost/implementation/i7/design-7-1a.md)
from main reference commit
`54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb`.

**Current authority:** see [Density-coordinate correction (2026-09-27)](#density-coordinate-correction-2026-09-27).
All 2026-09-22--25 numerical results below that predate the correction are retained as historical
evidence and are not authoritative physical I7.1 results.

## Density-coordinate correction (2026-09-27)

The corrected rerun keeps $\beta=0.5$, radius-$0.2$ circular leads with
`epsrel=17`, and the center ellipse with semiaxes $[0.25,0.16]$ and
`epsrel_center=2`. Its final spatial tuple is
`(ntot,nside,ntop,nproxy,mpw)=(256,160,160,80,32)` with $M=48$.

The 2026-09-27 review found that `op.construct_A_QP` returns a square-root
quadrature density coordinate, while the earlier `bloch.construct_S` passed it
an unscaled incident right-hand side and treated its solution as a physical
density. Let the physical density samples be
$\eta=[\tau;-\sigma]$, let $w_j=h|z'(t_j)|$, and define

$$
D=\mathop{\rm diag}\bigl(\sqrt{w_1},\ldots,\sqrt{w_N},
\sqrt{w_1},\ldots,\sqrt{w_N}\bigr).
$$

The matrix returned by `op.construct_A_QP` is
$A_s=D A_{\rm raw}D^{-1}$, where $A_{\rm raw}$ is the unscaled boundary
integral matrix. The consistent solve and scattered-coefficient extraction are

$$
B_s=DB_{\rm raw},\qquad
\xi=-A_s^{-1}B_s=D\eta,\qquad
F_{\rm raw}\eta=F_{\rm raw}D^{-1}\xi.
$$

The factors $h|z'|$ already occur in the Nyström and far-field quadratures;
$D$ is a density-coordinate change, not an extra quadrature weight. The fixed
`bloch.construct_S` solves for $\xi$, maps back to physical $\eta$, and keeps
the public `H_L,H_R` fields in physical-density coordinates for field
reconstruction. Products such as `F_L*H_L` are scattered outgoing Rayleigh
coefficients. The full scattering matrix additionally includes the direct
phase matrix $E$ in its two transmission blocks. This density-coordinate
matrix $D$ is also distinct from the row and column weights used later to form
the port matching matrix `Aphys`.

### Coordinate controls and three-point impact

The pre-fix [run-13](output/attempt-3/run-13/) built the legacy and corrected
chains from the same assembled matrices. For the radius-$0.2$, `epsrel=17`
circle, $D$ is scalar and the two scale factors cancel: the largest recorded
legacy/corrected defect was $2.5957821470365854\times10^{-15}$. For the
ellipse, `max(D)/min(D)=1.25`; the legacy/corrected full-$S$ relative defect
was $0.0039102$--$0.0039145$. The corrected scaled solve agreed with an
independent physical-coordinate solve to at most
$2.618072583161322\times10^{-15}$, and scaled-system/round-trip residuals
also passed their frozen coordinate gate.

| $k$ | old `aphys_ratio` | corrected `aphys_ratio` | old $d_H$ | corrected $d_H$ |
|---:|---:|---:|---:|---:|
| 1.753125 | $2.0771266823595485\times10^{-3}$ | $4.271375588141114\times10^{-3}$ | $6.940363180566178\times10^{-3}$ | $2.053125626861299\times10^{-13}$ |
| 1.7545053299700002 | $3.039999327579424\times10^{-4}$ | $2.2169529646617566\times10^{-3}$ | $6.956102600520672\times10^{-3}$ | $1.9118873147967958\times10^{-13}$ |
| 1.75625 | $2.6131828919534845\times10^{-3}$ | $3.7807116306705205\times10^{-4}$ | $6.976092528270513\times10^{-3}$ | $2.1757952844695718\times10^{-13}$ |

At the old $k_0$, the corrected four metrics are
`[0.012812588944603935, 2.120673021984856e-5,
0.006341485916479236, 0.0022169529646617566]`. These changes establish that
the coordinate mismatch materially affected the old candidate. They do not
show that it was the unique cause of the old fine-grid platform, and the three
fixed points are an impact diagnostic rather than an I7.2/I7.3 rerun.

The post-fix [run-14](output/attempt-3/run-14/) independently recomputed the
same local corrected and physical-coordinate chains and obtained zero
public/corrected metric and $d_H$ difference. Its command subsequently loaded
run-13 for a redundant cross-run equality check, so that cross-run portion is
non-portable supplemental evidence rather than the formal reproducibility
gate. The clean formal gate is run-25 below. The corrected wide scan has no
historical-output dependency.

### Corrected wide scan and localization

The corrected [run-15](output/attempt-3/run-15/) reran the existing
`scan_i7` method unchanged: 17 lead-gap samples, 33 screening samples, and 20
unique final-configuration evaluations were all valid. The bounded scan
stopped at its maximum refinement level with the current corrected best

| Field | Value |
|---|---:|
| `beta` | $0.5$ |
| `k` | $1.75595703125$ |
| `adef_sigma` | $3.324302999723711\times10^{-4}$ |
| `adef_ratio` | $5.50221342130019\times10^{-7}$ |
| `aphys_sigma` | $1.6443203700766671\times10^{-4}$ |
| `aphys_ratio` | $5.756273282435942\times10^{-5}$ |
| `runtime` | $340.5530312916667$ s |

The final neighboring samples are $k=1.755859375$ with
`aphys_ratio=2.02785446752283e-4` and $k=1.7560546875$ with
`aphys_ratio=8.76542677758356e-5`. Runs 16--23 each evaluated 11 uniformly
spaced points on the preceding winner's closed neighbor interval. Run-24 used
five points for the last budget-bounded call. Each linked `command.txt` is the
exact monitored invocation; the table gives the actual binary64 endpoints
saved in `scan.json` and the requested input spacing.

| Run command | Actual sampled span | Input `dk` | `nk` | Sampled best $k$ | Bracketing neighbors | Full neighbor width |
|---|---:|---:|---:|---:|---:|---:|
| [run-16](output/attempt-3/run-16/command.txt) | $[1.755859375,1.7560546875]$ | $1.953125\times10^{-5}$ | 11 | $1.75599609375$ | $[1.7559765625,1.756015625]$ | $3.906250000018652\times10^{-5}$ |
| [run-17](output/attempt-3/run-17/command.txt) | $[1.7559765625,1.7560156249999999]$ | $3.90625\times10^{-6}$ | 11 | $1.7559960937499999$ | $[1.7559921875,1.7559999999999998]$ | $7.812499999815259\times10^{-6}$ |
| [run-18](output/attempt-3/run-18/command.txt) | $[1.7559921875,1.756]$ | $7.8125\times10^{-7}$ | 11 | $1.7559960937499999$ | $[1.7559953125,1.755996875]$ | $1.562499999829825\times10^{-6}$ |
| [run-19](output/attempt-3/run-19/command.txt) | $[1.7559953125,1.7559968750000001]$ | $1.5625\times10^{-7}$ | 11 | $1.75599578125$ | $[1.7559956250000002,1.7559959375]$ | $3.124999998771472\times10^{-7}$ |
| [run-20](output/attempt-3/run-20/command.txt) | $[1.755995625,1.7559959375]$ | $3.125\times10^{-8}$ | 11 | $1.7559957499999999$ | $[1.75599571875,1.75599578125]$ | $6.250000006424727\times10^{-8}$ |
| [run-21](output/attempt-3/run-21/command.txt) | $[1.75599571875,1.75599578125]$ | $6.25\times10^{-9}$ | 11 | $1.75599574375$ | $[1.7559957375,1.7559957499999999]$ | $1.249999992403161\times10^{-8}$ |
| [run-22](output/attempt-3/run-22/command.txt) | $[1.7559957375,1.7559957499999999]$ | $1.25\times10^{-9}$ | 11 | $1.75599574125$ | $[1.75599574,1.7559957425]$ | $2.499999984806323\times10^{-9}$ |
| [run-23](output/attempt-3/run-23/command.txt) | $[1.75599574,1.7559957425]$ | $2.5\times10^{-10}$ | 11 | $1.75599574075$ | $[1.7559957405,1.755995741]$ | $5.000000413701855\times10^{-10}$ |
| [run-24](output/attempt-3/run-24/command.txt) | $[1.7559957405,1.755995741]$ | $1.25\times10^{-10}$ | 5 | $1.755995740875$ | $[1.75599574075,1.755995741]$ | $2.500000206850928\times10^{-10}$ |

All four metrics attain their sampled minimum at the same listed $k$ in every
local run.

| Run | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| run-16 | $3.0304358642403154\times10^{-6}$ | $5.0158198270528515\times10^{-9}$ | $1.4989381530701917\times10^{-6}$ | $5.2475252970237359\times10^{-7}$ |
| run-17 | $3.0304358739361745\times10^{-6}$ | $5.0158198431009395\times10^{-9}$ | $1.4989381577292833\times10^{-6}$ | $5.2475253133344406\times10^{-7}$ |
| run-18 | $3.0304358739361745\times10^{-6}$ | $5.0158198431009395\times10^{-9}$ | $1.4989381577292833\times10^{-6}$ | $5.2475253133344406\times10^{-7}$ |
| run-19 | $3.4682389517202421\times10^{-7}$ | $5.7404487269199313\times10^{-10}$ | $1.7154880081172648\times10^{-7}$ | $6.00562743098901\times10^{-8}$ |
| run-20 | $7.8462621856749428\times10^{-8}$ | $1.2986725079155882\times10^{-10}$ | $3.8809808212207329\times10^{-8}$ | $1.358664361852558\times10^{-8}$ |
| run-21 | $2.4790367432166884\times10^{-8}$ | $4.1031726806243373\times10^{-11}$ | $1.226200939192306\times10^{-8}$ | $4.2927177009147767\times10^{-9}$ |
| run-22 | $3.3214728788149961\times10^{-9}$ | $5.4975291564673825\times10^{-12}$ | $1.6428931882997553\times10^{-9}$ | $5.7514852812699673\times10^{-10}$ |
| run-23 | $9.7231435924909631\times10^{-10}$ | $1.6093241565563574\times10^{-12}$ | $4.8093380654024887\times10^{-10}$ | $1.683666185962501\times10^{-10}$ |
| run-24 | $1.0113801620671042\times10^{-10}$ | $1.6739838415360645\times10^{-13}$ | $5.0025687287374247\times10^{-11}$ | $1.7513129037661019\times10^{-11}$ |

Thus the current corrected result is the seven-scalar run-24 `out` with
`beta=0.5`, the run-24 row above, and `runtime=49.494959041666668` seconds.
The run-16 and run-17 winners differ by one binary64 unit, so their small
metric difference is not an exact-$k$ repeat. Run-18 repeats the exact run-17
binary64 point and all four metrics exactly. This supports deterministic
reevaluation but does not establish position convergence.

Localization stopped after run-24 to reserve the remaining shared budget for
the clean formal verification. No numerical floor or plateau is claimed. The
last full neighbor width records the sampling scale only; it is not a position
error. The sampled best remains a finite-grid result, not a continuous root,
eigenvalue certificate, or position-error bound.

The standalone [run-25 command](output/attempt-3/run-25/command.txt) evaluated
the three frozen diagnostic points and the run-24 winner without loading any
historical output. At all four points, public `bloch.construct_S` and the local
corrected coordinate chain agreed exactly in the full scattering matrix, the
scattered coefficients, physical density, four metrics, and $d_H$. The largest
independent physical-coordinate defect was
$2.621685745180568\times10^{-15}$ and the largest coordinate residual was
$4.288123065331613\times10^{-15}$. At the winner,
$d_H=1.871889938530571\times10^{-13}$ and all four metrics exactly repeated
run-24. This verifies the corrected implementation and saved candidate; it is
not an I7.2 or I7.3 rerun.

Runs 13--25 used $1691.861073$ monitored MATLAB wall seconds in total. Their
largest sampled process-tree RSS was $1,177,403,392$ bytes, below the
$2,300,000,000$-byte early-stop line.

| Run | Monitored wall (s) | Peak task-tree RSS (bytes) |
|---|---:|---:|
| run-13 | $50.790181$ | $1,077,936,128$ |
| run-14 | $46.583506$ | $1,103,429,632$ |
| run-15 | $352.589910$ | $996,442,112$ |
| run-16 | $153.718432$ | $930,070,528$ |
| run-17 | $139.123559$ | $1,022,263,296$ |
| run-18 | $147.405167$ | $1,065,811,968$ |
| run-19 | $142.841261$ | $1,003,749,376$ |
| run-20 | $146.915487$ | $848,723,968$ |
| run-21 | $138.270870$ | $980,959,232$ |
| run-22 | $130.090251$ | $1,059,651,584$ |
| run-23 | $121.126675$ | $1,177,403,392$ |
| run-24 | $63.613199$ | $1,146,683,392$ |
| run-25 | $58.792575$ | $1,109,770,240$ |

Current reruns use `test/i7/refine-v1/run_matlab_monitored.sh` with explicit
remaining-wall and RSS environment caps. It samples the task tree and the
all-MATLAB union every 0.1 seconds, rejects concurrent MATLAB, and uses the
current 1,800-second shared compute budget and 2,300,000,000-byte early-stop
line. The older 0.25-second launcher statements below describe only their
dated runs.

### Monitored reproduction

From the repository root, the following commands reproduce the corrected wide
scan, the final five-point localization, and the standalone coordinate gate.
The three wall caps sum to 825 seconds, within the 1,800-second shared compute
budget. Each output path below was unused when this record was written. The
monitor creates it and refuses to overwrite any existing monitor output, so
choose another new directory name for a later repetition.

```bash
MONITOR=test/i7/refine-v1/run_matlab_monitored.sh

WIDE=test/i7/scan-v1/output/attempt-3/run-26
I73_WALL_LIMIT_SECONDS=600 I73_RSS_LIMIT_BYTES=2300000000 \
  "$MONITOR" "$WIDE" \
  "repo=pwd; scan_dir=fullfile(repo,'test','i7','scan-v1'); run_dir=fullfile(scan_dir,'output','attempt-3','run-26'); addpath(repo); addpath(scan_dir); scan_i7(run_dir);"

LOCAL=test/i7/scan-v1/output/attempt-3/run-27
I73_WALL_LIMIT_SECONDS=105 I73_RSS_LIMIT_BYTES=2300000000 \
  "$MONITOR" "$LOCAL" \
  "repo=pwd; scan_dir=fullfile(repo,'test','i7','scan-v1'); run_dir=fullfile(scan_dir,'output','attempt-3','run-27'); addpath(repo); addpath(scan_dir); [out,scan]=locate_i7(1.7559957405,1.25e-10,5); save(fullfile(run_dir,'out.mat'),'out','-v7'); save(fullfile(run_dir,'scan.mat'),'scan','-v7'); writetable(scan,fullfile(run_dir,'scan.csv'));"

CONTROL=test/i7/scan-v1/output/attempt-3/run-28
I73_WALL_LIMIT_SECONDS=120 I73_RSS_LIMIT_BYTES=2300000000 \
  "$MONITOR" "$CONTROL" \
  "repo=pwd; scan_dir=fullfile(repo,'test','i7','scan-v1'); run_dir=fullfile(scan_dir,'output','attempt-3','run-28'); addpath(repo); addpath(scan_dir); result=check_density_scaling(run_dir,'final',[1.753125,1.7545053299700002,1.75625,1.755995740875]); assert(result.circle_control_pass && result.independent_physical_pass && result.coordinate_residual_pass && result.public_matches_correct); assert(result.max_metric_difference==0 && result.max_dH_difference==0); save(fullfile(run_dir,'result.mat'),'result','-v7');"
```

These commands contain no load from an earlier run. For a partial rerun under
an already active task budget, reduce each wall cap to the remaining allowance;
do not run concurrent MATLAB jobs.

## Entry point and output

`scan_i7.m` is the MATLAB entry point. It accepts one explicit output directory
and returns only the seven scalar fields

```text
beta, k, adef_sigma, adef_ratio, aphys_sigma, aphys_ratio, runtime.
```

The output directory must already exist. A portable numerical invocation is:

```matlab
cd(tempdir);
addpath('/path/to/repository');
addpath('/path/to/scan-v1');
out = scan_i7('/path/to/new/run-directory');
```

The historical Scheme 2 monitored run performed the public/callback kernel regression and
MATLAB code check in the same process. Its exact expanded batch command is in
[`command.txt`](output/attempt-1/kernel-revision/scheme-2-run-01/command.txt).
Its launcher `../run_matlab_monitored.sh` sampled the launched MATLAB process
tree every 0.25 seconds and enforces 1800 seconds and 3,000,000,000 bytes.

## Frozen scan

The layers distinguish the $k$ grid from the spatial discretization:

1. lead-gap classification uses $k=1.45:0.05:2.25$, the coarse spatial tuple
   `(160,120,120,64,24)`, and $M=12$;
2. ellipse screening uses a $0.025$ grid, the same coarse tuple, and $M=24$;
3. one deterministic pilot and all candidate confirmation points use only the
   final tuple `(256,160,160,80,32)` and $M=48$;
4. a final bracket is refined only around an interior valid minimum with two
   valid neighbors, for at most seven additional levels.

All final evaluations share the same cache. Invalid evaluations retain their
reason and never enter the argmin. `LOCAL_qzsub` rejects a point before
subspace extraction unless both directions have exactly $K$ stable/unstable
pairs and no neutral or indeterminate pair. Singular, nearly singular,
ill-conditioned, and rank-deficient solve warnings are promoted to point
failures. `LOCAL_dtn` retains the reviewed transposed linear solves and never
uses `pinv`.

The public `kernel.qpgreen_mfs_pairmat` accepts an optional
`pars1.h2d_evaluator` for its high-memory proxy-source term. Missing or empty
preserves the original public `kernel.h2d_directch` call. I7 supplies
`LOCAL_h2d_chunked_public`, which passes all sources and charges unchanged to
the public kernel while evaluating contiguous groups of at most 512 targets.
No Hankel formula is copied. The primary-source term and regular diagonal
evaluation remain on their original public calls.

`LOCAL_kernel_check` compares the public kernel and the actual I7 callback for
potential, gradient, and Hessian outputs with 17 sources and 777 targets. It
also compares all six outputs of a small `qpgreen_mfs_pairmat` problem through
the missing-field default, an explicit public callback, and the actual I7
callback; its 548 source-target pairs cross the 512-target boundary. The
deterministic inputs are saved in
[`kernel-validation-inputs.mat`](output/attempt-1/kernel-revision/scheme-2-run-01/audit-run-02/kernel-validation-inputs.mat).

## Kernel resource revision

Scheme 1 ran the unchanged public direct kernel through the production
fine/$M=48$ call chain. All 17 lead-gap points completed, but the first final
pilot was stopped by the 3,000,000,000-byte hard limit. The sampled process-tree
peak was 3,105,751,040 bytes at elapsed 42 seconds; total wall time was 47
seconds including the termination wait. The exact command and failure are
preserved in
[`scheme-1-run-01`](output/attempt-1/kernel-revision/scheme-1-run-01/).

Scheme 2 uses the single optional proxy-term callback described above. The
complete frozen scan exited successfully in 203 seconds wall time with a
1,071,398,912-byte sampled process-tree peak. Direct-kernel and pair-matrix
relative differences were all zero. The artifact audit then found zero
difference from the initial successful run in `beta`, `k`, all four matrix
metrics, all history scientific/status fields excluding per-point timing,
model, spatial configurations, scan coverage, and the valid-final argmin. The
corrected audit used 17 seconds and 851,787,776 bytes. Its first launch had a
MATLAB-expression parenthesis error and is retained as `audit`; it exited
before loading the artifacts after 21 seconds and 888,733,696 bytes. The
corrected evidence is in
[`audit-run-02`](output/attempt-1/kernel-revision/scheme-2-run-01/audit-run-02/).
The kernel-revision MATLAB runs used 288 seconds of monitored wall time in
total, including Scheme 1 and the failed audit launch.

The former I7-local kernel source and its path-based validator are retained
only as ignored history under `tmp/`. That directory is absent from the MATLAB
path and neither file is a current entry point.

## Historical pre-density-fix formal result

`attempt-1/kernel-revision/scheme-2-run-01` completed in MATLAB R2023b with exit
code 0. All 17 gap samples were valid, giving the sampled window
$[1.45,2.25]$; both endpoints are scan limits rather than computed band edges.
All 33 screening points were valid. The screening minimum was the left
endpoint, and the five final points on $[1.45,1.475]$ increased away from that
endpoint. The bounded rule therefore stopped without an interior refinement.

The current scan best is:

| Field | Value |
|---|---:|
| `beta` | $0.5$ |
| `k` | $1.45$ |
| `adef_sigma` | $3.6371178757473972$ |
| `adef_ratio` | $0.0060199359811023666$ |
| `aphys_sigma` | $1.3746238403333091$ |
| `aphys_ratio` | $0.31371305311538561$ |
| `runtime` | $182.508327708$ s |

The winner repeated with zero recorded four-metric difference. The public and
chunked kernel potential, gradient, and Hessian relative differences were all
zero. The Scheme 2 formal command used 203 seconds wall time and a sampled
process-tree peak RSS of 1,071,398,912 bytes. The corrected post-run artifact
audit passed all gates in 17 seconds with an 851,787,776-byte peak.

The result is a current best over the completed numerical scan. The minimum is
at the left scan boundary, and no strict interior dip was observed, so it is
not a confirmed eigenvalue.

Current artifacts are
[`out.mat`](output/attempt-1/kernel-revision/scheme-2-run-01/out.mat),
[`history.csv`](output/attempt-1/kernel-revision/scheme-2-run-01/history.csv),
[`scan.mat`](output/attempt-1/kernel-revision/scheme-2-run-01/scan.mat),
[`kernel-checkpoint.mat`](output/attempt-1/kernel-revision/scheme-2-run-01/kernel-checkpoint.mat),
[`monitor-status.txt`](output/attempt-1/kernel-revision/scheme-2-run-01/monitor-status.txt),
and
[`audit.txt`](output/attempt-1/kernel-revision/scheme-2-run-01/audit-run-02/audit.txt).
The initial successful `attempt-1/run-01` outputs, command, audit, and plot are
retained unchanged as historical evidence.

## Traceability to the main examples

- `LOCAL_cellsub` retains the circular geometry, public cell scattering
  construction, pencil blocks, and five-output interface from `betagmode.m`.
- `LOCAL_qzsub` retains the normalized projective QZ classification and adds
  the required fail-closed count gate before `ordqz`.
- `LOCAL_dtn` retains the original normal signs and transposed solves.
- `LOCAL_point` retains the four scalar outputs and physical row/column
  weights, replacing only the empty-center blocks by the reviewed center-cell
  scattering formula.
- `LOCAL_center` is the only new mathematical constructor. The remaining local
  helpers implement the bounded scan, cache, diagnostics, and output records.
- `LOCAL_h2d_chunked_public` changes only the size of each public direct-kernel
  target request; `LOCAL_kernel_check` verifies the direct and deep package
  outputs across a batch boundary before scanning.

The code-name ledger is in [`SYMBOLS.md`](SYMBOLS.md). Six MATLAB `checkcode`
advisories remain in `scan_i7.m`: two intentional lifetime-only `onCleanup`
assignments and four bounded append operations for history/cache/trace. The
modified public package file has no advisory. The corrected audit found no
code-check error and all numerical gates passed.


## Historical attempt 2: lower center refractive index (2026-09-25, pre-density-fix)

This run follows `design-7-1a.md` for the numerical method but overrides only
the ellipse material to `model.epsrel_center=2` (index $\sqrt{2}$). Circular
leads retain `model.epsrel=17`; all geometry, grids, discretizations, algorithms,
and stopping rules are unchanged. See [`SYMBOLS.md`](SYMBOLS.md). Preceding
results retain their original center material.

The [actual command](output/attempt-2/run-02/command.txt) includes post-run
checks. To repeat the scan, choose an unused directory (for example `run-03`):

```sh
cd /Users/whc/Documents/Work/epost
run_dir="$PWD/test/i7/scan-v1/output/attempt-2/run-03"
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab bash test/i7/run_matlab_monitored.sh "$run_dir" "cd(tempdir); addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i7/scan-v1'); out=scan_i7('$run_dir'); disp(out);"
```

| Field | Original center `epsrel=17` | Attempt 2 center `epsrel=2` |
|---|---:|---:|
| `beta` | 0.5 | 0.5 |
| `k` | 1.45 | 1.7544921875000001 |
| `adef_sigma` | 3.6371178757473972 | 0.0017605539256743739 |
| `adef_ratio` | 0.0060199359811023666 | 2.9139772056421109e-06 |
| `aphys_sigma` | 1.3746238403333091 | 0.00087138658623769319 |
| `aphys_ratio` | 0.31371305311538561 | 0.00030462845109826403 |
| `runtime` | 182.50832770833333 | 307.36577391666668 |

The original column is from `attempt-1/kernel-revision/scheme-2-run-01`.
Its best was the left boundary $k=1.45$. The new best is an interior dip:
final-config `aphys_ratio` is $0.04421804$ at $k=1.725$, $0.03038474$ at
$k=1.775$, and $0.0003046284511$ at $k=1.7544921875$. It is not a confirmed
eigenvalue; no I7.2 work was performed.

All 17 gap and 33 screening points on $[1.45,2.25]$ were valid. One candidate
was refined over levels 0--7 on $[1.725,1.775]$: 20 distinct final points,
including the $k=1.85$ pilot, 21 cache hits, and one winner repeat. The last
interval was $[1.754296875,1.7546875]$; the original maximum-level rule stopped
refinement. There were zero invalid points and zero repeat difference. Checks
passed for the center-only change, unchanged settings/gap classification, the
seven finite scalar fields, public kernel, and valid-final argmin; new/old
scores were not required to agree.

MATLAB R2023b exited 0 in 320 s monitored wall time, with process-tree peak RSS
1,123,532,800 bytes (0.25 s sampling; limits 1800 s and 3,000,000,000 bytes).
`run-01` failed before scanning because of a leading-newline batch expression
(12 s, exit 1, peak 808,435,712 bytes); its evidence remains intact. `run-02`
used a single-line command. Total monitored time was 332 s. No unresolved
numerical failure was observed; interpretation remains limited by the finite
grid and fixed spatial configuration.

Outputs: [out.mat](output/attempt-2/run-02/out.mat),
[history.csv](output/attempt-2/run-02/history.csv),
[scan.mat](output/attempt-2/run-02/scan.mat),
[comparison.json](output/attempt-2/run-02/comparison.json), and
[resource status](output/attempt-2/run-02/monitor-status.txt).


## Historical attempt 3: local uniform localization (2026-09-25, pre-density-fix)

[`locate_i7.m`](locate_i7.m) provides `[out,scan] = locate_i7(kmin,dk,nk)`.
One call evaluates exactly `kmin+(0:nk-1)*dk`; `scan` is a five-column table
of `k` and the four metrics. Selection uses `aphys_ratio`, and all four `out`
metrics come from that row. `out.runtime` measures this call, not the combined
sequence. There is no cache, automatic refinement, or historical-file input.

The model follows attempt 2: $\beta=0.5$, circular leads of radius $0.2$ with
`epsrel=17`, and the center ellipse $(0.25,0.16)$ with `epsrel_center=2`.
Only the final spatial tuple `(ntot,nside,ntop,nproxy,mpw)=(256,160,160,80,32)`
and `M=48` are used. The six numerical helpers are copied unchanged from the
current `scan_i7`; the warning guard, QZ gates, finite checks, and public
512-target batching are retained. `scan_i7.m` and prior results were untouched
by this localization task.

To repeat a local grid, choose an unused output directory. For example:

```sh
cd /Users/whc/Documents/Work/epost
run_dir="$PWD/test/i7/scan-v1/output/attempt-3/run-13"
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab bash test/i7/run_matlab_monitored.sh "$run_dir" "cd(tempdir); addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i7/scan-v1'); [out,scan]=locate_i7(1.7545053299500002,1e-11,11); save(fullfile('$run_dir','result.mat'),'out','scan'); disp(out);"
```

The actual [final command](output/attempt-3/run-12/command.txt) additionally
checks the public kernel path, absence of `tmp` from the path, the exact-point
repeat, and code diagnostics, and produces the plots. No `genpath` is used.

Run 01 reevaluated the requested old point $k=1.7544921875$. Absolute changes
from the saved attempt-2 metrics were respectively
$3.17\times10^{-15}$, $5.24\times10^{-18}$, $2.14\times10^{-15}$, and
$7.47\times10^{-16}$; the saved and requested `k` differ by one ULP.
Each next grid below was chosen explicitly after inspecting the previous
result. Every grid argmin was interior, so no endpoint expansion was needed.

| Run | First sampled k | Last sampled k | dk | Ratio-best k | Full neighbor width | Entry seconds |
|---|---:|---:|---:|---:|---:|---:|
| run-02 | 1.75439453125 | 1.75458984375 | 1.953125e-05 | 1.7545117187499999 | 3.90625e-05 | 101.891 |
| run-03 | 1.7544921874999999 | 1.7545312499999999 | 3.90625e-06 | 1.7545039062499999 | 7.8125e-06 | 97.977 |
| run-04 | 1.7544999999999999 | 1.7545078125 | 7.8125e-07 | 1.7545054687499999 | 1.5625e-06 | 97.908 |
| run-05 | 1.7545046875000001 | 1.7545062500000002 | 1.5625e-07 | 1.7545053125000001 | 3.125e-07 | 99.437 |
| run-06 | 1.75450515625 | 1.7545054687500001 | 3.125e-08 | 1.75450534375 | 6.24999998e-08 | 109.055 |
| run-07 | 1.7545053125000001 | 1.7545053750000001 | 6.25e-09 | 1.7545053312500001 | 1.25000001e-08 | 107.123 |
| run-08 | 1.754505325 | 1.7545053374999999 | 1.25e-09 | 1.75450533 | 2.49999998e-09 | 103.252 |
| run-09 | 1.7545053287500001 | 1.7545053312500001 | 2.5e-10 | 1.7545053300000002 | 4.99999819e-10 | 98.217 |
| run-10 | 1.7545053297500002 | 1.7545053302500002 | 5e-11 | 1.7545053300000002 | 1.00000008e-10 | 100.578 |
| run-11 | 1.7545053299500002 | 1.7545053300500002 | 1e-11 | 1.7545053299700002 | 2.00000017e-11 | 101.645 |

The [complete summary](output/attempt-3/summary.csv) records each interval's
actual width, all four metrics at its best point, relative improvements,
neighbor score differences, entry/wall times, and peak RSS. Full-precision
[JSON](output/attempt-3/summary.json), per-run MAT files, and full-precision
scan JSON preserve the last digits; CSV display rounding is not used to
identify exact repeated `k` values.

Run 06 first reached full neighbor width $6.249999984220267\times10^{-8}$
with `dk=3.125e-8` (whole scan width $3.125000000991918\times10^{-7}$).
Run 11 first reached $2.000000165480742\times10^{-11}$ with `dk=1e-11`
(whole scan width $1.000000082740371\times10^{-10}$). Run 10's neighbor width
was slightly greater than $10^{-10}$ in stored double precision, so it was
not counted as satisfying that threshold. These are sampling scales, not
position-error bounds.

Value flattening appeared by run 08; the first irregular near-platform
samples appeared in run 09 (`dk=2.5e-10`, full neighbor width approximately
$5\times10^{-10}$), supported by runs 10--11. Their successive best-ratio
improvements were $9.94\times10^{-17}$, zero, and $7.32\times10^{-16}$.
Run 11 has competing low samples at $1.7545053299700002$ and
$1.7545053300200002$, only $1.12\times10^{-16}$ apart in ratio. Thus its
mechanical argmin does not establish ten-digit position accuracy. The
sampled near-platform range in run 10 was
$[1.7545053297500002,1.7545053302500002]$ (width about $5\times10^{-10}$),
with ratio spread $3.43\times10^{-15}$. This observed range is not a
certified enclosure of a continuous minimum. The coarser run-08 neighbor
range $[1.75450532875,1.75450533125]$ still showed a resolved sampled dip;
no finer *reliable* position enclosure is established here.

At the selected ratio minima, `aphys_sigma` settles near
$8.69578027\times10^{-4}$. Within the finest windows it still decreases with
`k`; its separate minimizer is not the ratio minimizer. No metrics from
separate minima are mixed. Platform causes remain unassigned.

The final [out.json](output/attempt-3/run-12/out.json) and
[out.mat](output/attempt-3/run-12/out.mat) come from the one-point call at
$k=1.7545053299700002$; all four metrics exactly repeat run 11.
Across the 21 exact-double repeated-point comparisons, all four differences
were zero. This establishes reproducibility of these evaluations, not their
accuracy relative to an undiscretized operator. Refinement stopped after both
sampling-scale targets and persistent platform evidence, followed by that
repeat. No continuous-operator eigenvalue is confirmed.

The 12 monitored MATLAB calls evaluated 112 points in 1189 s wall time
(including startup, checks, and plotting); summed entry time was
1036.234010917 s. Peak process-tree RSS was 1,268,891,648 bytes, sampled every
0.25 s, within the combined 1800 s and 3,000,000,000-byte limits. All calls
exited 0; there were no failed numerical evaluations in this attempt.
See [resource records](output/attempt-3/run-12/resources.csv), per-run
`resources.csv`/`monitor-status.txt`, and the summary for the complete record.
The sampling curves are available as
[PNG](output/attempt-3/run-12/localization.png) and
[PDF](output/attempt-3/run-12/localization.pdf); display offsets do not change
saved metrics or matrix normalization.

Independent Skeptic review: **PASS WITH CONDITIONS**. Frozen model/config,
core-helper reuse, public-kernel resolution, scalar-output provenance,
actual interval widths, exact-point repeat, and resource bounds passed.
The remaining limitation is unresolved fine-grid position accuracy and
platform origin. MATLAB `checkcode` reported only one intentional `NASGU`
advisory for the lifetime-only `onCleanup` warning guard; no blocker was found.
