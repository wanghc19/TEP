# I7.3 fixed-point refinement experiment

This directory contains the six-configuration fixed-point experiment described
in the [I7.3 design](../../../research/projects/eig-apost/implementation/i7/design-7-3a.md)
and summarized in the [I7 status page](../../../research/projects/eig-apost/implementation/i7/README.md).
The experiment compares the frozen points `kL=1.753125`,
`k0=1.7545053299700002`, and `kR=1.75625` for these `(ntot,M)` pairs:

| ID | `ntot` | `M` |
|---|---:|---:|
| B | 256 | 48 |
| M56 | 256 | 56 |
| M64 | 256 | 64 |
| N384 | 384 | 48 |
| N512 | 512 | 48 |
| J | 512 | 64 |

All configurations use `(nside,ntop,nproxy,mpw)=(160,160,80,32)`, lead
`epsrel=17`, and center ellipse `epsrel=2` with axes `(0.25,0.16)`.

## Entry and reproduction

`check_i7_refinement(checkpoint_dir)` runs the fixed three-point experiment.
`check_i7_refinement(checkpoint_dir,'local')` runs only the common 11-point
grid `k0+(-5:5)*1e-5`. Both modes save a unique checkpoint after every
completed or classified invalid point. The entry does not read documentation,
Git metadata, or historical results.

Run from the repository root with a new output directory. The example below
is for a future fresh 2700-second budget; calls in one task must deduct every
earlier MATLAB wall time rather than reset the limit:

```bash
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
I73_WALL_LIMIT_SECONDS=2699 I73_RSS_LIMIT_BYTES=2300000000 \
test/i7/refine-v1/run_matlab_monitored.sh \
test/i7/refine-v1/output/attempt-1/run-NN \
"repo_root=pwd; experiment_dir=fullfile(repo_root,'test','i7','refine-v1'); addpath(repo_root); addpath(experiment_dir); run_dir=fullfile(experiment_dir,'output','attempt-1','run-NN'); checkpoint_dir=fullfile(run_dir,'checkpoints'); mkdir(checkpoint_dir); assert(strcmp(which('kernel.h2d_directch'),fullfile(repo_root,'+kernel','h2d_directch.m'))); [result,evidence]=check_i7_refinement(checkpoint_dir); save(fullfile(run_dir,'scientific.mat'),'result','evidence','-v7.3'); audit=audit_i7_refinement(result,evidence); save(fullfile(run_dir,'audit.mat'),'audit'); plot_i7_refinement(result,fullfile(run_dir,'refinement-summary.png'));"
```

The [archived child command](output/attempt-1/run-04/command.txt) records the
complete successful invocation, including path checks, source snapshots,
JSON, CSV, audit, and figure output. Always use a new run directory; the
monitor and checkpoints refuse overwrite.

For the local mode, use the same launcher and replace the MATLAB expression
with the following; the executed full command is archived in
[run-06/command.txt](output/attempt-1/run-06/command.txt).

```matlab
repo_root=pwd;
experiment_dir=fullfile(repo_root,'test','i7','refine-v1');
addpath(repo_root); addpath(experiment_dir);
run_dir=fullfile(experiment_dir,'output','attempt-1','run-NN');
checkpoint_dir=fullfile(run_dir,'checkpoints'); mkdir(checkpoint_dir);
[result,evidence]=check_i7_refinement(checkpoint_dir,'local');
save(fullfile(run_dir,'scientific.mat'),'result','evidence','-v7.3');
```

## Completed evidence

The successful formal run is [attempt-1/run-04](output/attempt-1/run-04/):

- 18 of 18 evaluations were valid.
- All six configurations gave the same endpoint count change, with the main
  band negative count changing from 0 at `kL` to 1 at `kR`.
- All 18 prescribed edge/object comparisons passed the frozen same-mode rule.
- The recorded outcome is `STABLE_SAME_MODE`. This is finite-dimensional
  numerical stability evidence, not a continuous eigenvalue certificate.
- The independent saved-data [audit](output/attempt-1/run-04/audit.json)
  passed all 18 points and 18 comparisons.

The main artifacts are
[scientific.mat](output/attempt-1/run-04/scientific.mat),
[result.json](output/attempt-1/run-04/result.json),
[points.csv](output/attempt-1/run-04/points.csv), and
[refinement-summary.png](output/attempt-1/run-04/refinement-summary.png).

The experiment runtime was 340.255368 seconds. The monitored wall time was
365.178545 seconds, and peak task-tree and MATLAB-union RSS were both
1,943,863,296 bytes, below the 2,300,000,000-byte early-stop threshold.
Including the 1-second failed preflight and the 12.888699-second parse-failure
run, total conservative MATLAB wall usage was 380 seconds.

The successful local scan is [attempt-1/run-06](output/attempt-1/run-06/):

- All 66 evaluations were valid and passed their finite-object diagnostics.
- Every configuration selected the fresh `k0` sample (grid index 6). Each
  winner was strictly below both neighbors; the full neighbor spacing was
  `2.0000000000131e-5` and ratio gaps were about `3.6404e-7` on each side.
- All 66 same-wavenumber edge comparisons passed the frozen same-mode rule.
- `NO_DRIFT_RESOLVED_AT_SPACING_1E-5` means only that this grid did not
  resolve configuration-dependent movement. It is not location convergence
  or an error bound.
- The saved-data [local audit](output/attempt-1/run-07/audit.json) passed six
  winners and 66 comparisons. Its largest reported discrepancy was
  `3.33066907387547e-16`.

The local numerical entry took 1236.527470 seconds; monitored wall time was
1250.057854 seconds and peak RSS was 1,606,238,208 bytes. Saved-data audit and
plotting took 13.889967 seconds with peak RSS 1,238,335,488 bytes. Including
all starts, failures, fixed and local runs, total conservative MATLAB wall
usage was 1699.729068 seconds.

## Preserved failures and static notes

- `run-01` is the unmonitored failed preflight; it performed no scientific
  evaluation.
- `run-02/monitor-selftest` preserves non-MATLAB RSS, signal cleanup, lock,
  and actual preflight rejection of existing external MATLAB processes.
  The attempted dynamic foreign-process injection did not yield a valid
  test; its evidence is retained, and that branch was inspected statically.
- `run-03` preserves the MATLAB parse failure caused by using the reserved
  word `otherwise` as a local helper argument. The corrected source renames
  that argument to `fallback` without changing behavior.
- Formal `checkcode` reported two advisories: stale suppression `MSNU` at the
  checkpoint assignment and `NASGU` for the warning guard that is explicitly
  cleared to trigger its `onCleanup` restoration. Neither affected execution.
- `run-05` preserves a 56.714003-second stopped local run after the independent
  review required stronger invalid-point and diagnostic-state wording.
- `run-06` is the complete local scan. `run-07` is its saved-data-only audit
  and [local scan figure](output/attempt-1/run-07/local-scan.png).
- Current local-source `checkcode` advisories are two stale `MSNU`
  suppressions and the intentional warning-guard `NASGU`; the audit has no
  advisories, and the plot has one stale `MSNU` suppression.
