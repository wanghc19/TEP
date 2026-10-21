# I8 single-point evaluation timing diagnostic

`profile_i8.m` measures the unchanged I8.1 locator entry
`locate_i8(k,1,1)`.  It does not copy the point evaluator or alter the frozen
model, discretization, QZ/DtN construction, matching matrices, or singular
values.  The caller must put the repository package root, `locate-v1`, and
`profile-v1` on the MATLAB path.

The two points are the candidate
`k0 = 1.7562818500073463` and the earlier local-grid point
`k1 = 1.7562818560000002`.  The latter is separated from the candidate by
`5.992653706155648e-9`; it is a normal point in the same local valley rather
than a final-round ulp neighbor.  Both use the frozen
`(ntot,nside,ntop,nproxy,mpw,M) = (256,160,160,80,32,48)` configuration.

## Protocol and artifacts

One fresh MATLAB process performs, in order:

1. one first call at `k0`;
2. one explicit warmup and three unprofiled repeats at `k0`;
3. one explicit warmup and three unprofiled repeats at `k1`;
4. one separately profiled call at each point.

The profiled calls are not baseline timing samples.  Each profiler session
saves raw `profile('info')` data in `profile-k*.mat`, including the original
`Children`, `Parents`, and `ExecutedLines` fields.  The function, call-edge,
and executed-line CSV files expose the same data for inspection.  In the
function tables, `inclusive_seconds` is MATLAB's `TotalTime`,
`child_edge_seconds` is the sum of the recorded child-edge times, and
`derived_self_seconds` is their unclamped difference.  Built-in work not
listed as a child is therefore retained in derived self time.  The active
MATLAB profiler reported timer `performance`, detail level `mmex`, and history
tracking `timestamp`.

Run from the worktree root with a new run directory in the same attempt:

```bash
I8PROFILE_WALL_LIMIT_SECONDS=1800 \
I8PROFILE_RSS_LIMIT_BYTES=2147483648 \
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
bash test/i8/profile-v1/monitor.sh \
  test/i8/profile-v1/output/attempt-1/run-NN \
  "addpath(pwd); addpath(fullfile(pwd,'test','i8','locate-v1')); addpath(fullfile(pwd,'test','i8','profile-v1')); profile_i8(fullfile(pwd,'test','i8','profile-v1','output','attempt-1','run-NN'));"
```

The monitor refuses an existing MATLAB process, stops if another MATLAB
appears, and samples process-tree RSS, CPU, and system load every 0.2 seconds.
It enforces the 30-minute and 2 GiB hard limits.

## Unprofiled timing and numerical consistency

The successful formal run is `output/attempt-1/run-02`.  The first call took
8.521968 s by `out.runtime` and 8.533504 s around the complete entry.  Warmed
repeat results are:

| Point | Entry min / median / max (s) | Outer min / median / max (s) |
|---|---:|---:|
| `k0` | 8.008139 / 8.066617 / 8.410510 | 8.008212 / 8.066692 / 8.410590 |
| `k1` | 7.939344 / 8.034608 / 8.061616 | 7.939421 / 8.034689 / 8.061693 |

All 11 calls, including first, warmup, repeat, and profiler calls, reproduced
their point's four metrics with zero binary64 difference relative to the first
unprofiled repeat.  The two reference rows are:

| Point | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| `k0` | 9.0463849720091667e-14 | 1.4973105978156506e-16 | 4.3645331331577957e-14 | 1.5283249311405522e-14 |
| `k1` | 5.1427176954783761e-8 | 8.5119588994282451e-11 | 2.5434108843217626e-8 | 8.9062407543503152e-9 |

The profiled outer times were 8.138300 s at `k0` and 8.248252 s at `k1`.
Their observed differences from the corresponding unprofiled medians are
about 0.9% and 2.7%, respectively.  This combines profiler overhead with
ordinary load and run-order variation; it is not an isolated overhead
measurement and is not used as the normal evaluation baseline.

## Profiler-domain timing attribution

The following ledger is non-overlapping within MATLAB profiler
`LOCAL_point` time.  `lead construct` is `LOCAL_cellsub` inclusive time minus
its two `LOCAL_qzsub` edges; `QZ and DtN` restores those QZ edges and adds
`LOCAL_dtn`; `matching and SVD` is the remaining `LOCAL_point` self time.

| Component | `k0` s / share | `k1` s / share |
|---|---:|---:|
| lead construct | 4.095395 / 50.36% | 4.116130 / 49.96% |
| QZ and DtN | 0.098308 / 1.21% | 0.094437 / 1.15% |
| center construct | 3.916038 / 48.16% | 4.007553 / 48.64% |
| matching, weights, two SVDs | 0.022178 / 0.27% | 0.020660 / 0.25% |
| profiler `LOCAL_point` total | 8.131919 / 100% | 8.238779 / 100% |

Lead construction was 0.179 s and 0.109 s slower than center construction in
the two profiles.  The difference is only 1.3--2.2% of the full point time;
there is no large lead/center imbalance.

The deeper non-overlapping ledger below closes to the same `LOCAL_point`
denominator.  The BIE solve is the line-140 time for the single concatenated
multi-right-hand-side backslash in `construct_S`; no per-right-hand-side
factorization is present.

| Component | `k0` s / share | `k1` s / share |
|---|---:|---:|
| smooth proxy correction, `LOCAL_h2d_chunked_public` | 7.513075 / 92.39% | 7.540684 / 91.53% |
| remaining quasi-periodic pair evaluation | 0.025296 / 0.31% | 0.024305 / 0.30% |
| two `precomp_proxy` calls, including least squares | 0.216391 / 2.66% | 0.245493 / 2.98% |
| remaining `construct_A_QP` assembly | 0.203478 / 2.50% | 0.251262 / 3.05% |
| concatenated multi-RHS BIE solve | 0.030260 / 0.37% | 0.031686 / 0.38% |
| remaining `construct_S` work | 0.018929 / 0.23% | 0.025798 / 0.31% |
| cell wrappers, geometry, and channel setup | 0.004005 / 0.05% | 0.004455 / 0.05% |
| QZ and DtN | 0.098308 / 1.21% | 0.094437 / 1.15% |
| matching, weights, and SVD | 0.022178 / 0.27% | 0.020660 / 0.25% |

Within the smooth correction, the 256 batched calls to the public direct
kernel account for 7.501728 s at `k0` and 7.529578 s at `k1`.  The two direct
free-space pair-kernel edges outside that helper take only 0.012194 s and
0.011821 s.  Thus the expensive item is specifically the smooth field of 320
proxy sources at the boundary-pair differences, rather than the center-image
free-space call or temporary pair-array setup.  The profile does not separate
the smooth correction into individual lead and center calls because both use
the same helper; their enclosing construction times are reported above.  It
also cannot form a fully disjoint potential/gradient/Hessian split because
those outputs share Bessel values and intermediate arrays.  Across all 260
`h2d_directch` calls, the two Bessel lines alone take 6.443742 s at `k0` and
6.484841 s at `k1`, or 79.24% and 78.71% of `LOCAL_point`.  The final potential,
two gradient, and three Hessian accumulation lines take respectively
0.021562 / 0.120527 / 0.175384 s at `k0` and
0.021882 / 0.119340 / 0.173351 s at `k1`.  Shared coefficient construction,
temporary arrays, and return/copy work remain unseparated.

The two cell constructors call `precomp_proxy` and `rayleigh_channels` with
the same arguments.  Their aggregate profiler times are 0.216--0.245 s and
0.0010--0.0011 s.  Within the two proxy precomputations, the two
`lsqminnorm` calls take 0.089899 s at `k0` and 0.118963 s at `k1`; the remaining
proxy matrix and field formation takes 0.126492 s and 0.126531 s.  These are
subparts of the aggregate proxy-precomputation time and must not be added to it.
Removing the second proxy precomputation can therefore save only approximately
one call, about 1--1.5% of a point on these profiles.
Repeated free-space extraction and Kress helper work is also visible but much
smaller: at `k0`, the free-gradient, free-potential extraction, and
free-Hessian helpers total about 0.023 s, while `kress_l_splits`,
`kress_mn_splits`, and `LOCAL_kress_matrix` total about 0.148 s.

Based only on the measured profiler shares, eliminating all smooth-proxy time
would cap the overall speedup at about 13.1x for `k0` and 11.8x for `k1`.
A 2x acceleration of that helper would imply about 1.86x and 1.84x overall;
these are Amdahl-law estimates, not achieved speedups.  The observed share at
both points is strong evidence that local expansion research should target
this helper before small repeated setup or solve costs.

## Environment and run accounting

Run 02 used MATLAB R2023b 23.2 on arm64 macOS 14.8.7.  MATLAB reported 11
detected cores and 11 maximum computational threads; the standard thread-limit
environment variables were unset.  Preflight found no MATLAB process and no
external MATLAB appeared during the run.  The sampled process-tree peak RSS
was 1,366,786,048 bytes.  The monitor wall time was 100.823534 s.  The 11
outer call timers sum to 89.818421 s; the remaining 11.005113 s combines
MATLAB startup/exit, environment capture, profiler setup, exports, and monitor
preflight, so startup and exit are not separately isolated.

The preflight load average was 1.59 / 2.37 / 2.44.  The one-minute load reached
10.02 while MATLAB itself used roughly ten cores.  Across the sampled run, the
1-, 5-, and 15-minute load ranges were 1.59--10.02, 2.37--4.97, and 2.44--3.44;
the corresponding medians were 7.53, 3.88, and 3.00.  Several desktop
processes were active before launch, but no second MATLAB was present;
non-MATLAB load was not isolated further.

Run 01 is a retained operational failure: the sandbox denied the monitor's
read-only `ps` preflight before MATLAB started.  Its status records
`root_pid=none`, its log is empty, and it produced no locator output; this is
evidence that the launcher did not start MATLAB, although the failed preflight
could not create a process snapshot.  Run 02 used the same method in the same
attempt with process inspection authorized.  The exact implementation checks
preceding the formal run, including their unmonitored-RSS limitation, are
recorded in `output/attempt-1/implementation-checks.txt`.  Neither check called
`locate_i8` or performed a scientific evaluation.


