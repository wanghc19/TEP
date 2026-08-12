# I1-K-SCAN-V1 TEP Missing-Column Real-k Scan Plan

## ARS Material Passport

- Experiment ID: `I1-K-SCAN-V1`
- Type: preregistered staged computation
- Status: `EXECUTED THROUGH M48 DISCRETE REAL-AXIS CONFIRMATION`
- Command: `matlab -nodesktop -batch "addpath(fullfile(pwd,'test','i1','k-scan')); tep_mc_scan('pilot'); tep_mc_scan('continuity'); tep_mc_scan('full');"`
- Outputs: stage-local CSV, MAT, Markdown, log, and source-hash artifacts
- Claim boundary: `EMPIRICAL_FD_DERIVATIVE`; no analytic production derivative, locator, root isolation, or eigenvalue

1. Run `pilot`. Verify MATLAB `lsqminnorm`, source provenance, the frozen model,
   the $M=12/24/48$ matrix dimensions, the $320/512$ BIE density sizes, the
   $2.30$ MiB largest graph matrix, and one $M=12$ coarse point. Stop on failure.
2. Run `continuity`. At the seven ascending $M=48$ nodes, preserve all I1.2
   solve, block, pencil, QZ, graph, chart, DtN, $A_{\mathrm{def}}$, Schur, wall,
   Wood-distance, branch, and infinity diagnostics. Pivot the row selector once
   at $k_0$ and keep it fixed.
3. Compare neighboring QR bases through the singular values of their overlap
   matrices. Require every smallest overlap to be at least `0.9` and never form
   dense orthogonal projectors.
4. Form centered differences at $h=0.02,0.01,0.005`. Require the last change to
   be at most `1e-6`, its ratio to the preceding change to be at most `0.35`, and
   coarse/fine derivative action disagreement to be at most `1e-6`.
5. Apply a deterministic nonsingular graph-coordinate mutation and global
   scalar mutations `1e-8`, `exp(0.37i)`, and `1e8`. Require the recorded
   invariants to change by at most `1e-12`. In the retained execution,
   pointwise invariance passed, but the finite-difference graph-basis mutation
   changed by `3.64808e-11 > 1e-12`. The continuity/candidate track therefore
   records `PASS WITH CONDITIONS`, keeps `fd_derivative_ready=false`, and
   authorizes candidate screening through the separate continuity track.
6. Once conditional screening authorization is recorded, run `screen` using
   only $M=12$ coarse nodes on `[1.55,2.15]` with step `0.05`; add the four outer
   points only if there is no strict interior dip or the best point is an
   endpoint. At most two eligible dips proceed to $M=24$ nine-point windows;
   only the best proceeds to the $M=48$ five-point window.
7. For M24/M48 advancement, require both coarse/fine minimum left/right
   singular-vector overlaps to be at least `0.9`. For every scan group, require
   raw-unbalanced and physical-score global minima to differ by at most one
   grid point; the physical weights vary with $\gamma(k)$, while only the scalar
   normalization is frozen at the stage seed. The executed M12, M24, and M48
   stages passed these gates.

Serial engineering memory is capped at `512 MiB`, and a complete future staged
run is budgeted at no more than `30 min`.

## Executed outcome

The final source-current authoritative path used `187.132 s` of MATLAB wall
time and ended at the M48 discrete real-axis candidate $k=1.83125$. Its
$k^2=3.3534765625$ value is metadata only. Including the preserved initial and
graph-basis-mutation diagnostic continuity runs, the requested five-run
accounting is `349.930 s`.
A separate approximately `110 s` compact-audit implementation attempt
hard-failed during `confirm48` before saving confirm/full results and is not
included in those totals. No locator, root isolation, Newton step, or
eigenvalue claim was made.

## Executed zoom addendum

This is an execution-after-the-fact addendum, not an independent pre-run zoom
plan. The runtime contract was frozen directly in `zoom_cfg.m` and
`tep_mc_zoom.m`; no separate pre-run zoom plan file existed, so this section
must not be represented as one.

The zoom pilot passed parent-lineage, fixed-pivot, and parent-score reproduction
checks in `9.106 s`. The single preregistered full run stopped after `38.366 s`
at its first nested level. All unchanged point/QZ/count/chart/mutation gates,
neighbor overlap, unique coarse/fine interior minima, zero minimum drift,
score ratio, minimum singular-vector overlap, raw/physical minimum index, and
`r12` passed. The prominence gate failed with
`1.05562039273045 < 1.25`; the minimum remained $k=1.83125$ with
$q=2.16407562921445\times10^{-3}>10^{-5}$.

Post-review conclusion: `STOP / DESIGN-GATE-INCONCLUSIVE`. Near-zero was not
established, no candidate was authorized, and plateau was not assessed because
the run stopped before three levels. Any future grid or gate revision requires
a new version and explicit user authorization; it must not overwrite this
run or its artifacts.
