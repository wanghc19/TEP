# I8.1 local locator

`locate_i8.m` evaluates one caller-specified uniform wavenumber grid for the
equal-area six-row star center.  It does not refine automatically and does not
read an earlier result.  The caller supplies

```matlab
[out, scan] = locate_i8(kmin, dk, nk)
```

with finite real `kmin`, positive finite `dk`, and a positive integer `nk`.
The actual grid is `kmin + (0:nk-1)*dk`; duplicate or nonincreasing binary64
nodes fail before any solve.  `scan` contains `k` and the four singular-value
metrics.  `out` contains exactly seven scalars: `beta`, the valid row minimizing
`aphys_ratio`, the four metrics from that same row, and the entry runtime.

## Frozen model

- `beta = 0.5`.
- Both leads retain circular inclusions of radius `0.2` and relative
  permittivity `17`.
- The center uses `geom.construct_cont(...,'star',...)`; every one of its six
  geometry rows is multiplied by $\sqrt{0.04/0.0618}$.  Its relative
  permittivity is `2`.
- The spatial configuration is
  `(ntot,nside,ntop,nproxy,mpw) = (256,160,160,80,32)` with port order `M=48`.
- The corrected public `bloch.construct_S` supplies physical densities.  The
  locator adds no density rescaling and changes no public function.

The QZ, DtN, matching matrix, row/column weights, warning handling, and
target-batched public kernel calls are the validated I7 locator computations.
Only the center geometry and I8 identifiers differ.  The implementation symbol
ledger is [SYMBOLS.md](../../../research/projects/eig-apost/implementation/i8/SYMBOLS.md).

## Numerical result

The single-point control at `k=1.7562800000000001` reproduced the earlier I8
flow values.  Four metrics were identical except for a
`3.3881317890172014e-21` (`1.2322860322362933e-15` relative) difference in
`aphys_ratio`, consistent with ordinary SVD roundoff.

Fourteen explicitly requested grids were then evaluated.  Full-precision data
are in [rounds.csv](output/attempt-1/rounds.csv), and every run retains its MAT,
JSON, CSV, command, source snapshot, log, and resource trace.

Each grid used `nk=11`.  The actual binary64 intervals, rather than nominal
decimal endpoints, were:

| Round | Run | Actual `[kfirst, klast]` | `dk` | Full span | Entry s |
|---:|:---:|:---|---:|---:|---:|
| 1 | 04 | [1.7562720000000001, 1.7562880000000001] | 1.600000e-06 | 1.600000e-05 | 98.003 |
| 2 | 05 | [1.7562800000000001, 1.7562832000000002] | 3.200000e-07 | 3.200000e-06 | 95.497 |
| 3 | 06 | [1.7562816000000001, 1.7562822400000002] | 6.400000e-08 | 6.400000e-07 | 95.721 |
| 4 | 07 | [1.7562817920000002, 1.7562819200000002] | 1.280000e-08 | 1.280000e-07 | 95.746 |
| 5 | 08 | [1.7562818432000002, 1.7562818688000001] | 2.560000e-09 | 2.560000e-08 | 92.491 |
| 6 | 09 | [1.7562818483200002, 1.7562818534400002] | 5.120000e-10 | 5.120000e-09 | 98.779 |
| 7 | 10 | [1.7562818493440002, 1.7562818503680002] | 1.024000e-10 | 1.024000e-09 | 96.872 |
| 8 | 11 | [1.7562818498560002, 1.7562818500608002] | 2.048000e-11 | 2.048000e-10 | 96.900 |
| 9 | 12 | [1.7562818499788801, 1.7562818500198403] | 4.096012e-12 | 4.096012e-11 | 98.394 |
| 10 | 13 | [1.7562818500034563, 1.7562818500116482] | 8.191892e-13 | 8.191892e-12 | 101.773 |
| 11 | 14 | [1.7562818500067330, 1.7562818500083714] | 1.638467e-13 | 1.638467e-12 | 100.779 |
| 12 | 15 | [1.7562818500072246, 1.7562818500075523] | 3.277378e-14 | 3.277378e-13 | 98.977 |
| 13 | 16 | [1.7562818500072901, 1.7562818500073556] | 6.550316e-15 | 6.550316e-14 | 97.051 |
| 14 | 17 | [1.7562818500073361, 1.7562818500073489] | 1.287859e-15 | 1.287859e-14 | 94.427 |

The four same-row metrics and relative decrease in `aphys_ratio` versus the
previous grid are listed below.  Round 1 uses the old-point control as its
reference; a zero decrease alone does not identify a platform.

| Round | Winner `k` | `Adef` sigma | `Adef` ratio | `Aphys` sigma | `Aphys` ratio | Decrease % |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1.7562816000000001 | 2.14548879e-06 | 3.55110148e-09 | 1.06108492e-06 | 3.71559136e-07 | 86.486147 |
| 2 | 1.7562819200000002 | 6.00656040e-07 | 9.94174642e-10 | 2.97063766e-07 | 1.04022578e-07 | 72.003762 |
| 3 | 1.7562818560000002 | 5.14271770e-08 | 8.51195890e-11 | 2.54341088e-08 | 8.90624075e-09 | 91.438166 |
| 4 | 1.7562818560000002 | 5.14271770e-08 | 8.51195890e-11 | 2.54341088e-08 | 8.90624075e-09 | 0.000000 |
| 5 | 1.7562818508800002 | 7.48891673e-09 | 1.23952655e-11 | 3.70376006e-09 | 1.29694258e-09 | 85.437823 |
| 6 | 1.7562818498560002 | 1.29879627e-09 | 2.14970005e-12 | 6.42339668e-10 | 2.24927547e-10 | 82.657093 |
| 7 | 1.7562818499584003 | 4.19983223e-10 | 6.95134391e-13 | 2.07709193e-10 | 7.27333551e-11 | 67.663652 |
| 8 | 1.7562818499993602 | 6.85287984e-11 | 1.13425303e-13 | 3.38918458e-11 | 1.18678794e-11 | 83.683030 |
| 9 | 1.7562818500075523 | 1.78434747e-12 | 2.95335914e-15 | 8.82528248e-13 | 3.09034181e-13 | 97.396045 |
| 10 | 1.7562818500075523 | 1.78434747e-12 | 2.95335914e-15 | 8.82528248e-13 | 3.09034181e-13 | 0.000000 |
| 11 | 1.7562818500073885 | 3.80387791e-13 | 6.29598091e-16 | 1.88202779e-13 | 6.59028104e-14 | 78.674589 |
| 12 | 1.756281850007323 | 1.69978176e-13 | 2.81339037e-16 | 8.39009660e-14 | 2.93795314e-14 | 55.419911 |
| 13 | 1.7562818500073425 | 9.66380858e-14 | 1.59950334e-16 | 4.73973794e-14 | 1.65971009e-14 | 43.507946 |
| 14 | 1.7562818500073463 | 9.04638497e-14 | 1.49731060e-16 | 4.36453313e-14 | 1.52832493e-14 | 7.916151 |

The formal final `out` is the run-17 result:

| Field | Value |
|---|---:|
| `beta` | 0.5 |
| `k` | 1.7562818500073463 |
| `adef_sigma` | 9.0463849720091667e-14 |
| `adef_ratio` | 1.4973105978156506e-16 |
| `aphys_sigma` | 4.3645331331577957e-14 |
| `aphys_ratio` | 1.5283249311405522e-14 |
| `runtime` | 94.427279625 s |

Run 17 has an actual full span of `1.2878587085651816e-14` and spacings from
`1.1102230246251565e-15` to `1.3322676295501878e-15`.  Its bottom is irregular
at the scale of neighboring scores.  The result is therefore the current
sampled best point and evidence of a numerical platform; it is not a 14-digit
location guarantee.  [dip.png](output/attempt-1/run-17/dip.png) displays the
final sampled curve.

Fresh run 18 reevaluated the exact binary64 winner in a new MATLAB process.
All five compared values (`k` and four metrics) matched run 17 exactly; its
entry runtime was `9.343255` s.  This verifies repeatability at that saved
double but does not turn the platform width into an error bound.
Relative to the old `k=1.75628` control, the final sampled `aphys_ratio` is
smaller by a factor of about `1.799e8`.

## Resources and run history

The monitor sampled the complete MATLAB process tree every `0.1` s, was
configured to stop at `2,300,000,000` bytes before the `3,000,000,000` byte hard limit, rejected
concurrent MATLAB, and shared one `2700` s ledger.  After run 18:

- cumulative monitored wall time: `1788.668541` s;
- sum of the fourteen formal grid entry runtimes: `1361.4096024166668` s;
- peak task-tree RSS: `1,341,407,232` bytes (run 08);
- all formal grids and the exact repeat exited successfully.

Run 01 evaluated its point but failed afterward because MATLAB R2023b rejected
the unsupported `writetable` `Precision` option.  Run 03 evaluated all eleven
points but failed afterward because a nested cell was passed to `fullfile` in
the JSON export loop.  Both failures remain intact; run 02 and run 04 reran the
same numerical requests with explicit `fprintf('%.17g',...)` CSV output and
simple JSON writes.  Neither failure changed the scientific attempt.

## Reproduction

Use a new run directory and the remaining authorized monitor ledger.  The
following example evaluates one uniform grid; repeat it only with explicitly
chosen parameters and a new run directory.

```bash
cd /path/to/epost
run_dir=test/i8/locate-v1/output/attempt-1/run-19
expr="repo_root=pwd; scan_dir=fullfile(repo_root,'test','i8','locate-v1'); run_dir=fullfile(scan_dir,'output','attempt-1','run-19'); addpath(repo_root); addpath(scan_dir); copyfile(fullfile(scan_dir,'locate_i8.m'),fullfile(run_dir,'source.m')); request=struct('kmin',1.7562818500073361,'dk',1.2878587085651816e-15,'nk',11); [out,scan]=locate_i8(request.kmin,request.dk,request.nk); save(fullfile(run_dir,'out.mat'),'out'); save(fullfile(run_dir,'scan.mat'),'scan'); save(fullfile(run_dir,'request.mat'),'request'); fid=fopen(fullfile(run_dir,'scan.csv'),'w'); fprintf(fid,'k,adef_sigma,adef_ratio,aphys_sigma,aphys_ratio\\n'); for j=1:height(scan), fprintf(fid,'%.17g,%.17g,%.17g,%.17g,%.17g\\n',scan.k(j),scan.adef_sigma(j),scan.adef_ratio(j),scan.aphys_sigma(j),scan.aphys_ratio(j)); end; fclose(fid); fid=fopen(fullfile(run_dir,'out.json'),'w'); fprintf(fid,'%s',jsonencode(out,'PrettyPrint',true)); fclose(fid); fid=fopen(fullfile(run_dir,'scan.json'),'w'); fprintf(fid,'%s',jsonencode(table2struct(scan),'PrettyPrint',true)); fclose(fid); fid=fopen(fullfile(run_dir,'request.json'),'w'); fprintf(fid,'%s',jsonencode(request,'PrettyPrint',true)); fclose(fid);"
I81_WALL_LIMIT_SECONDS=2700 \
I81_RSS_LIMIT_BYTES=2300000000 \
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
bash test/i8/locate-v1/monitor.sh "$run_dir" "$expr"
```

The monitor subtracts all earlier `status.txt` wall times under this experiment;
changing the run name does not reset the shared computation budget.

Final scope and artifact audit: [audit.json](output/attempt-1/audit.json).
Whole task elapsed through final review: `3062.465` s (`51.04` min);
see [task.json](output/attempt-1/task.json). This includes collaboration,
debugging, MATLAB, and documentation; it is distinct from `out.runtime`.
