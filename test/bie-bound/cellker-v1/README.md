# Cell-bounded kernel version 1

`cellker` means cell-bounded kernel; MFS means method of fundamental solutions; FMM means fast multipole method; QP means quasi-periodic. This experiment keeps the existing boundary-integral densities and compares the wrapped and three-image cell kernels. No density re-solve.

## Plan and forecast

Kernel pilot: fit value and periodic-coordinate derivative differences on a two-dimensional grid, with top/bottom outgoing plane-wave matching. Forecast 30–120 s, below 1.5 GiB for the compact parameter sweep. Full fixed-field residual comparison: forecast 8–18 min, below 2.5 GiB, including the old split-source wall calculation. All output is small JSON/CSV; rounding is excluded.

Measured results and reproduction commands follow below.

## Pilot and selected setting

run-001 retained an output-array initialization error (17.804 s, 1.012 GiB). run-002 completed the six-setting sweep (22.644 s, 1.566 GiB). Choose 120 sources per proxy edge, margin 0.35, scaled singular-value cutoff 1e-14, 13 by 81 periodic-difference collocation points, 240 top/bottom points and 65 outgoing modes. Independent-grid value/periodic-derivative mismatch: 2.352e-15 / 5.078e-15. Larger proxy count did not improve those residuals.

run-003 forecast: 8–18 min, 2.5 GiB. One rebuild of the old densities, split-source direct old walls (768 source/target), old material (1536) and seams (1536 source/768 target), then new material (1536) and new walls/seams at 768 and 1536 sources. The old grouped budget must agree with 4.0088154357e-12 within 1%; the native mass check must agree within 1e-10. The new source-refinement result is reported, not assumed.

## Fitting equations and field convention

Computational X is physical y, and computational Y is physical x. With q=exp(i beta d), the explicit-image quasi-periodic difference simplifies before evaluation to

`q^(-1) G0(X+d,Y) - q^2 G0(X-2d,Y)`.

The proxy matrix rows are `G0((X,Y)-Z)-q G0((X-d,Y)-Z)` and their X derivatives. This avoids subtracting the singular near-image terms on the fitting grid. At Y=+/-H, value and Y derivative are matched to the outgoing modes exp(i beta_m X), with derivative +/-i gamma_m. Columns are normalized by their Euclidean norms before truncated singular-value decomposition. Only the exterior wave number k0 is used by the active wrapped layer; material interiors retain the free-space kernel.

All evaluated pairs have |X|<=0.76 and |Y|<=0.86 at the walls/seams, and no larger values on a material curve. The analytic source bounds |physical x|<=0.36, |physical y|<=0.26 include all three templates. For the selected proxy rectangle, every translated source has distance at least 0.59 in one coordinate from the closed cell box; the two adjacent explicit-image curves have at least 0.24 clearance. Thus the new representation has no artificial point source or wrap line inside the evaluated cell. Each translated lead cell uses the same local construction.

The copied Muller assembly retains its Kress free-space singular blocks. Only its smooth remainder and regular diagonal are replaced by the two adjacent images plus the new proxy sum. `cell_operator` is the local copy of `op.construct_A_QP`; field generation still calls the original operator. `cell_budget` copies the existing fixed-field and source-split routines, with a local dispatch for residual evaluation after the old budget check.

## Reproduction

Run serially, each command through the escalated-permission channel; choose a new output number for every execution.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellker-v1/launch.py --mode pilot --output test/bie-bound/cellker-v1/output/run-NNN --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellker-v1/launch.py --mode budget --output test/bie-bound/cellker-v1/output/run-MMM --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellker-v1/summarize.py --pilot test/bie-bound/cellker-v1/output/run-NNN --budget test/bie-bound/cellker-v1/output/run-MMM
```

The launcher sets eleven MATLAB/OpenMP threads and disables dynamic OpenMP. The copied monitor enforces 30/40 minutes and 3 GiB for each result. `cell_settings.m` contains all new quadratures, grouped constants and fit parameters; `pilot_config.m` contains the copied physical model and original solve parameters. No old output is loaded by MATLAB. The postprocessor reads only the explicitly supplied outputs of this experiment.

The eight comparison disks are inside the inclusions (`matrel-v1/disks.py`, rho in {4,17}, free-space evaluation). Changing only the exterior kernel leaves their fields unchanged when the densities and states are held fixed. The requested width prediction uses the supplied rounded-down U=1.23587. Lead tails and C_g retain the earlier floating treatment.

Filename notes: `pairmat` means pair matrix; `cell_pairmat.m` returns physical-coordinate pair matrices, and `cell_regular.m` returns their smooth remainder in computational coordinates. `cell_operator.m` is the copied quasi-periodic Muller operator; `cell_budget.m` assembles the grouped residual budget. The copied `pilot_*` files reproduce the original evaluation-pilot model. `monitor.py` records resident set size (RSS); CSV means comma-separated values and JSON means JavaScript Object Notation.

## Results and checks

The old grouped Q is 4.008833205473486e-12 (relative difference 4.43267438243744e-6 from the reference; acceptance 1%). The native mass baseline agrees exactly. The new Q is 3.5283532835345356e-12 and the requested width is 2.7735644615416048e-11. Center material contributes 89.0159%. This is a floating comparison, with the original observed-ratio lead tail and C_g. No new density solve was performed.

| Group | Old epsilon | New epsilon | Old C epsilon | New C epsilon |
|---|---:|---:|---:|---:|
| center | 1.2611637249e-12 | 1.2613654945e-12 | 3.1402932451e-12 | 3.1407956508e-12 |
| negative | 1.5804512699e-14 | 6.2570965888e-14 | 1.8669875467e-14 | 7.3915100280e-14 |
| positive | 1.6381833182e-14 | 6.6042299984e-14 | 2.0209281305e-14 | 8.1472409319e-14 |
| walls | 7.6336310141e-13 | 2.1459433331e-13 | 7.9050228281e-13 | 2.2222361815e-13 |
| seams | 3.7814147413e-14 | 9.6050259271e-15 | 3.9158520758e-14 | 9.9465050220e-15 |

Source refinement 768 to 1536 changes Q by 1.1173547286635888e-5 relative. All material terms use 1536 nodes, both wall/seam target grids use 768. The center epsilon and old split-wall epsilon reproduce 1.2611637248633255e-12 and 7.633631014111668e-13. Density and propagation objects are unchanged. Geometry/Fourier interpolation and breakpoint checks remain those of the copied source-split evaluator, recorded in result.json.

| Stage | Seconds |
|---|---:|
| build_seconds | 3.464307 |
| breakpoint_seconds | 1.179227 |
| old_wall_seconds | 211.242332 |
| old_material_seconds | 65.932075 |
| old_seam_seconds | 43.780087 |
| fit_seconds | 0.947754 |
| new_material_seconds | 58.469915 |
| new walls and seams, 768 sources | 78.723118 |
| new walls and seams, 1536 sources | 154.148630 |
| mass check and output remainder | 0.207340 |
| MATLAB enclosing timer | 618.094784 |
| startup, exit and monitor remainder | 17.529905 |
| monitored total | 635.624689 |

Budget-run peak 1.425156 GiB; all runs including the failed initialization total 676.072276 s, maximum peak 1.565613 GiB. Retained data are below 1 MB. `summary.json` and `groups.csv` are recomputed from the explicit result files by `summarize.py`. The pilot and budget outputs preserve their raw scalar inputs.

The active entry points now accept the settings explicitly; the earlier one-argument invocations in monitor command records use the identical default structure. The copied native builder remains unchanged and scientific runtime never loads earlier results. Coincident free-space pair entries are placeholders used only within the Muller self assembly; its Kress/regular-diagonal formulas replace them.

The observed gain supports replacing the exterior kernel without first re-solving densities. Left/right material errors grow by factors 3.959/4.031, but their total weighted contribution is only 1.554e-13. A consistent future re-solve needs a local copy of `bloch.construct_S`, the local operator, and verification or replacement of the ideal-Rayleigh far-field extractors by K3 wall projections; frequency re-search cost is not measured here.
