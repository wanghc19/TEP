# I7.1 ellipse scan

This experiment keeps both periodic half-guides at the reviewed circular
inclusion of radius $0.2$ and `epsrel=17`, and changes only the center cell to
the equal-area ellipse with semi-axes $(0.25,0.16)$. It implements the frozen
design in
[`design-7-1a.md`](../../../research/projects/eig-apost/implementation/i7/design-7-1a.md)
from main reference commit
`54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb`.

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

The current monitored run performs the public/callback kernel regression and
MATLAB code check in the same process. Its exact expanded batch command is in
[`command.txt`](output/attempt-1/kernel-revision/scheme-2-run-01/command.txt).
The launcher `../run_matlab_monitored.sh` samples the launched MATLAB process
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

## Formal result

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


## Attempt 2: lower center refractive index (2026-09-25)

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


## Attempt 3: local uniform localization (2026-09-25)

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
