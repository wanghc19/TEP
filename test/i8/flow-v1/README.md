# I8 star-center flow

`run_i8.m` runs the complete ordinary-double I8 experiment with one equal-area
star inclusion in the center cell.  The lead circles remain radius $0.2$ and
relative permittivity $17$; the star has relative permittivity $2$ and uses

$$
s=\sqrt{0.04/0.0618}=0.8045179867091297
$$

on all six rows returned by `geom.construct_cont(...,'star',...)`.  The baseline
configuration is `(ntot,nside,ntop,nproxy,mpw,M)=(256,160,160,80,32,48)`.
The code uses the corrected public physical-density coordinates and the
target-batched public kernel callback.  It does not read old outputs, Git state,
or Markdown at runtime.

## Workflow

1. Check the star geometry on 4096 and 8192 samples and compare the public
   density solve with an independent raw-coordinate solve for a circle and the
   star.
2. Evaluate 33 uniformly spaced points on $[1.45,2.25]$.  Refine an interior
   valid basin on at most five 11-point grids.  Select the smallest valid
   `aphys_ratio` over every evaluated baseline point.
3. Use distinct neighboring samples outside a $64\epsilon$ equivalence window
   as shoulders.  Evaluate the three inertia bands with $c=50,100,200$.
4. Compare the selected B trace with the single-axis N (`ntot=384`) and M
   (`M=64`) traces.  A near-degenerate singular target is reported unresolved
   instead of forcing a single-vector match.
5. Freeze the selected baseline port vector and physical 256-node density.
   Evaluate signed material and wall defects on the non-native 512 and 768
   grids, 40 lead cells on each side plus observed geometric tails, and the
   same-field disk mass on $16\times32$ and shifted $32\times64$ quadratures.
6. `audit_i8.m` independently rebuilds the matching matrices, SVD metrics,
   inertia counts, trace maps, component ledger, and numerical scalar formula
   from the fresh in-memory result.

The collar, quadrature changes, observed tails, and scalar result are numerical
diagnostics.  They are not continuous error bounds or a spectral certificate.

## Formal result

The successful evidence is in `output/attempt-1/run-03/`.  All 33 screen points
and all 55 local points were valid.  The scan stopped after the fixed five
local levels; the final distinct-neighbor width was about $1.6\times10^{-5}$.

| quantity | value |
|---|---:|
| selected $k$ | 1.7562800000000001 |
| `adef_sigma` | 1.5876231719907793e-5 |
| `adef_ratio` | 2.6277513150613766e-8 |
| `aphys_sigma` | 7.8518431836730985e-6 |
| `aphys_ratio` | 2.7494686301593333e-6 |
| left/right shoulder | 1.756272 / 1.7562879999999998 |
| shoulder offsets | -8.000000000008e-6 / 7.999999999786e-6 |

The negative counts are `[0 0 0]` on the left and `[1 1 1]` on the right;
both endpoint diagnostics pass.  The B--N and B--M primary overlaps round to
one, their maximum primary--competitor cross overlap is about `2.32512e-5`,
and both simple-mode checks pass.

| configuration | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| B: 256, M48 | 1.5876231719e-5 | 2.6277513149e-8 | 7.8518431831e-6 | 2.7494686300e-6 |
| N: 384, M48 | 1.5876231724e-5 | 2.6277513157e-8 | 7.8518431854e-6 | 2.7494686308e-6 |
| M: 256, M64 | 1.5876231713e-5 | 1.9716147441e-8 | 7.8518431839e-6 | 2.7494686302e-6 |

The sampled star geometry passes both numerical grids.  Its area defect is at
most `5.56e-17`, sampled maximum absolute curvature is `79.90587575136033`,
and the nominal collar factor is `theta=0.6803764969945587`.  The independent
physical-density control has maximum normalized defect `4.30e-15`.

The fine 768-node component ledger gives:

| component | value squared | normal squared |
|---|---:|---:|
| center material | 8.0061232205e-29 | 6.1557317783e-14 |
| lead material, finite cells | 2.0890373423e-30 | 1.8560338234e-28 |
| lead material, observed tail | 4.7840808552e-72 | 4.2529693246e-70 |
| center--lead walls | 1.3765452793e-27 | 2.5248370659e-10 |
| internal walls | 1.9043499598e-27 | 4.9832942249e-26 |
| observed wall tail | 4.3662774256e-69 | 1.1406066747e-67 |

The fine disk norm is `U_num=0.11608313379588661`.  With
`epsilon_num=1.5891672785007143e-5`, `Cnum=8.273559292601668`, and positive
denominator `0.11595165309884123`, the ordinary diagnostic is
`Rnum=0.0069952390495916393`.  Its status is `UNCERTIFIED_RNUM`.
The 512-to-768 relative changes are recorded in `result.json`; the largest
listed change is the tiny lead-normal term (`0.3292` relative to a value near
roundoff), while the dominant wall-normal term changes by `1.97e-10` relative
and the disk norm by `1.48e-10` relative.

The independent audit passes with maximum recomposition defect
`7.343837628306003e-14` against tolerance `1e-9`.  See `audit2.json` for the
five point summaries and both raw-field evaluation levels.  `scan.png` shows
the saved wide and local scans.

## Reproduction

The following command is for a new work copy with this source revision, an
empty I8 `output/` tree, and a separately authorized task budget.  Do not use it
in the current worktree to clear or bypass the existing cumulative ledger; the
saved `run-03/command.txt` is the exact command record for this delivery.

```bash
run_dir=test/i8/flow-v1/output/attempt-1/run-01
matlab_expr="repo_root=pwd; scan_dir=fullfile(repo_root,'test','i8','flow-v1'); run_dir=fullfile(scan_dir,'output','attempt-1','run-01'); addpath(repo_root); addpath(scan_dir); copyfile(fullfile(scan_dir,'run_i8.m'),fullfile(run_dir,'source.m')); copyfile(fullfile(scan_dir,'audit_i8.m'),fullfile(run_dir,'audit_src.m')); copyfile(fullfile(scan_dir,'monitor.sh'),fullfile(run_dir,'monitor.sh')); issues_run=checkcode(fullfile(scan_dir,'run_i8.m'),'-id'); issues_audit=checkcode(fullfile(scan_dir,'audit_i8.m'),'-id'); save(fullfile(run_dir,'codechk.mat'),'issues_run','issues_audit'); [result,evidence]=run_i8(run_dir); audit=audit_i8(result,evidence); save(fullfile(run_dir,'audit.mat'),'audit','-v7.3'); fid=fopen(fullfile(run_dir,'audit2.json'),'w'); fprintf(fid,'%s\\n',jsonencode(audit,'PrettyPrint',true)); fclose(fid); assert(audit.pass);"
MATLAB_BIN="${MATLAB_BIN:-matlab}" \
I8_WALL_LIMIT_SECONDS=2400 I8_RSS_LIMIT_BYTES=2300000000 \
bash test/i8/flow-v1/monitor.sh "$run_dir" "$matlab_expr"
conda run -n octave python test/i8/flow-v1/plot_i8.py "$run_dir"
```

`monitor.sh` rejects concurrent MATLAB, samples the full task tree every 0.1 s,
and enforces a cumulative 2700-second budget across run directories.

## Resource and failure record

| run | outcome | wall seconds | peak tree RSS |
|---|---|---:|---:|
| run-01 | program failure before scientific evaluation: dissimilar empty-struct assignment | 31.869832 | 667,615,232 B |
| run-02 | actively interrupted after scan when a 1-ulp duplicate could be chosen as a shoulder | 922.439173 | 1,000,292,352 B |
| run-03 | complete result and passing independent audit | 1228.056123 | 1,182,564,352 B |

The cumulative monitored wall time is `2182.365128` seconds, leaving about
`517.634872` seconds in this task's 2700-second computation budget.  run-02 reports a
monitor `SIGINT`/process-monitoring failure because the owned run was deliberately
interrupted; it was not a memory or MATLAB crash.  No run exceeded the 2.3 GB
early-stop threshold or overlapped another MATLAB process.

## Files

- `run_i8.m`: numerical flow and frozen I8 helpers.
- `audit_i8.m`: independent fresh-result arithmetic audit.
- `monitor.sh`: cumulative time, concurrency, and RSS monitor.
- `plot_i8.py`: saved-data scan plotter.
- `output/attempt-1/run-03/`: formal matrices, compact JSON/CSV, command,
  source snapshots, resource samples, audit, and figure.
