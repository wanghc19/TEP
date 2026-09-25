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
