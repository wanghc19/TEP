# Finite element comparison

FEM means finite element method; DtN means Dirichlet-to-Neumann; RT3 means Raviart–Thomas degree three; P2/P3 denote polynomial degrees. E, M and S denote energy, weighted mass and squared residual quantities. H denotes the isolation hypothesis.

Only the reference waveguide is supported; in particular its center density is 4. It is computed at h=1/48,1/36,1/24. Original integral tolerances are retained. Truncation errors are bounded; finite arithmetic rounding is excluded from those bounds and has only an earlier estimate.

## Commands and data

The commands below have explicit scientific handoffs. The canonical array and certificate formats are described in [data/README.md](data/README.md). Expected arithmetic comparisons are in [reference/tolerances.json](reference/tolerances.json). Both layers need MATLAB R2023b and Python with NumPy/SciPy; neither uses FMM2D.

## Results

All three cold interval runs passed their field, geometry, integration and four-corner sign checks. At h=1/48, E, M, S and the MATLAB four-corner endpoints reproduce the earlier computation bit for bit. The outward printed interval is [2.4287286691977, 2.4287286736602]; I₁ is [2.4286785150, 2.4287788272]. Widths below use the unrounded decimal formulas from the same binary64 inputs, not subtraction of the short printed endpoints.

| h | Free DOFs per cell, left/core/right | I₁ width (mu) | Four-corner width (mu) | Cold wall (s) | Peak RSS (GiB) |
|---|---|---:|---:|---:|---:|
| 1/24 | 9297 / 9144 / 9234 | 4.345206196e-04 | 8.403221532e-08 | 542.490 | 1.523 |
| 1/36 | 17901 / 17586 / 17793 | 1.855510301e-04 | 1.528118753e-08 | 729.729 | 1.933 |
| 1/48 | 28989 / 28629 / 28908 | 1.003120314e-04 | 4.462331793e-09 | 753.990 | 1.746 |

| Computation | Result and smallest relevant margin | Wall (s) | Peak RSS (GiB) |
|---|---|---:|---:|
| Band gap | 472 signs; lower 1.397223839e-4, upper 7.520504512e-3 | 2.633 | 0.065 |
| Half-line surface | Four zero counts; gamma 0.004289129615; K+ 279.899894626, K− 0.70782 | 1840.952 | 1.706 |
| All-trace DtN bounds | A_H 0.9997069620; K+r at most 1.090323170e-5 | 1500.724 | 1.899 |
| Core count | One negative direction; positive margin 0.365373688682 | 14.702 | 1.082 |

The isolation window is (1.7424, 5.6169). The first-order intersection lies inside it with margins 0.6862785151 and 3.1881211729. Isolation costs 55.9835 minutes once per model/window; h=1/48 plus isolation costs 68.5500 minutes. These are measured process wall times including MATLAB startup and output; Python command dispatch and decimal display bookkeeping are not separately timed. MATLAB uses 11 computational threads. The band stage is a separate SciPy process with the same thread setting.

All surface numerical fields common to the old reports, both DtN lower matrices and remainders, and the core numerical fields match exactly. The current DtN source adds an independently evaluated finite-element trace: discrepancies are 8.25e-16 and 8.97e-16; the old reports recorded the algebraic identity as zero. This diagnostic difference changes no lower matrix or bound.

Results and raw scalar stage records are in [reference/ex1/](reference/ex1/), with [cost-width.csv](reference/ex1/cost-width.csv) for plotting. Canonical verification passed: reintegration reproduces E/M/S and both decimal endpoint pairs exactly (621.359 s, 1.498 GiB including transport); isolation verification reproduces all 472 band signs, surface and DtN tests, and the core count/margin (19.669 s, 0.987 GiB). The wrong-phase and invalid-band controls are rejected. Shared flux moment mismatch is 8.94e-19, cell-interface mismatch and outer normal moments are zero. The recorded scientific reads stay inside canonical package data and these verification runs; loaded MATLAB functions stay inside the package or MATLAB installation. All 55 bundled MATLAB files appear in the loaded-function records.


The canonical field and flux are the h=1/48 result; the other two meshes have cold-start recipes and scalar reference tables. The same promotion and verification commands can be applied to their newly generated data. Canonical field data use `.npz` (ZIP collections of NumPy arrays) plus a JSON structure dictionary; no pickle is used. `arrays.py` preserves every array shape and dtype, including complex binary64 coefficients. MATLAB version-5 files are run-local transport only. Verify materializes them in its fresh output directory and recomputes geometry, normalization, E/M/S and the endpoints. It does not search for or generate a field, and it does not solve for a flux.

For isolation, verify recomputes band indicator integrals and all 472 finite signs; forms the surface error/Schur matrices from canonical integrated matrices and their recorded analytic remainders; reassembles the DtN lower matrices from canonical Q/R/Z matrices and integral/series error bounds; and rebuilds the core matrices and negative count. It reads the surface and DtN integration certificates rather than regenerating their response fields. This distinction is part of the verification boundary. All these finite computations exclude a rounding enclosure.

## Arrays not tracked in Git

`data/ex1/native.npz` (13.2 MB) and `data/ex1/flux.npz` (61.4 MB) are kept out of Git for now; their JSON structure dictionaries are tracked. Without them the FEM smoke test and `verify.py --part interval` stop at the missing file. `verify.py --part isolation` does not read them; pass `--interval "$PKG/fem/reference/ex1/interval.json"` instead of a fresh interval output. To regenerate the two arrays, run the h=1/48 interval command below (about 12.5 minutes, below 2 GiB) and convert its transport files:

```sh
"$PYTHON" -B -c 'import sys; sys.path.insert(0, sys.argv[1]); from arrays import export; export(sys.argv[2], sys.argv[3]); export(sys.argv[4], sys.argv[5])' \
  "$PKG/fem/scripts" "$RUN/science/native.mat" "$PKG/fem/data/ex1/native" \
  "$RUN/science/flux.mat" "$PKG/fem/data/ex1/flux"
```

This also rewrites `native.json` and `flux.json`. Then `verify.py --part interval` checks E/M/S and both endpoint pairs against the tracked `data/ex1/integrals.json` and `reference/ex1/`.

## Isolation handoffs

The band stage delivers its actual panel signs and endpoints. The surface stage checks the band model (both deformation parameters, density, transverse phase and period) before building the four endpoint responses. It derives K+ and K− from the resulting spectral distances, retaining the old upward display slack. The DtN stage receives those constants explicitly, including in the analytic Z envelope. The core stage checks the lead identities, orientations, ports, frequencies, endpoint window and retained Fourier indices, and consumes the separately computed first-order interval. Thus the four-corner result is not used to prove its own isolation premise.

The mathematical implications are the band certificate, the surface-count equality, the all-trace DtN inequality, and the enriched-core inertia theorem. The final count uses the independent spectral intersection supplied by I₁. Finite matrix signs are computed in ordinary arithmetic; the recorded positive margins are compared with the earlier rounding estimates. The package does not turn those estimates into ball-arithmetic certificates.

The mesh series uses 24/36/48 subdivisions per unit-cell side and 160/240/320 true-curve segments in the native quadratic geometry. P3 field degree, RT3 flux degree, the 13-cell-per-side taper box, P2 search, all quadrature orders and original certificate tolerances stay fixed. The flux mesh uses the same nodes with exact analytic interface blending. No mesh is tuned after a failed sign or integration check. The copied quadrature code is corrected for one-element batches: scalar material values are explicitly repeated as a column. This changes array shape only and avoids MATLAB implicit expansion; quadrature points and numerical rules are unchanged.

The earlier core experiment also recorded an additional mixed-field relative comparison of 1.81e-10 against a 1e-10 target. Its absolute difference, 4.61e-17, was below the retained operator remainder 1.22e-10. This package retains the operator remainder and the formal core checks; it does not claim that historical extra relative test passed.

## Reproduction commands

Set `PKG`, `PYTHON`, `MATLAB`, and `STORAGE` to explicit installation paths and a monitored storage root. `RUN`, `A`, `B`, `C`, `D`, `VI`, and `VH` are new run directories. `HAND` is a caller-owned directory for small handoff JSON files. All paths below are supplied by the caller; no repository path is discovered.

```sh
export BIE_STORAGE_ROOT="$STORAGE"
"$PYTHON" -B "$PKG/fem/scripts/reproduce.py" --example ex1 --stage interval \
  --mesh 48 --output "$RUN" --matlab "$MATLAB" --storage-root "$STORAGE"
"$PYTHON" -B "$PKG/fem/scripts/reproduce.py" --example ex1 --stage band \
  --output "$A" --matlab "$MATLAB" --python "$PYTHON" --storage-root "$STORAGE"
"$PYTHON" -B "$PKG/fem/scripts/handoff.py" --band "$A/science/band.json" --output "$HAND/surface.json"
"$PYTHON" -B "$PKG/fem/scripts/reproduce.py" --example ex1 --stage surface \
  --inputs "$HAND/surface.json" --output "$B" --matlab "$MATLAB" --storage-root "$STORAGE"
"$PYTHON" -B "$PKG/fem/scripts/handoff.py" --band "$A/science/band.json" \
  --surface "$B/science/surface.json" --output "$HAND/dtn.json"
"$PYTHON" -B "$PKG/fem/scripts/reproduce.py" --example ex1 --stage dtn \
  --inputs "$HAND/dtn.json" --output "$C" --matlab "$MATLAB" --storage-root "$STORAGE"
"$PYTHON" -B "$PKG/fem/scripts/handoff.py" --band "$A/science/band.json" \
  --surface "$B/science/surface.json" --left "$C/science/left-certificate.json" \
  --right "$C/science/right-certificate.json" --interval "$RUN/science/interval.json" \
  --output "$HAND/core.json"
"$PYTHON" -B "$PKG/fem/scripts/reproduce.py" --example ex1 --stage core \
  --inputs "$HAND/core.json" --output "$D" --matlab "$MATLAB" --storage-root "$STORAGE"
```

To create a new canonical set from these completed runs, choose empty `DATA` and `REF` directories and run:

```sh
"$PYTHON" -B "$PKG/fem/scripts/promote.py" --interval "$RUN" --band "$A" \
  --surface "$B" --dtn "$C" --core "$D" --data "$DATA" --reference "$REF"
```

Repeat only the interval command with `--mesh 36` or `--mesh 24` for the mesh series; use distinct output directories. The isolation data depend on the model and window, not the trial mesh, so their one measured cost is shown separately.

```sh
"$PYTHON" -B "$PKG/scripts/monitor.py" "<VERIFY_INTERVAL_MONITOR>" \
  "$PYTHON" -B "$PKG/fem/scripts/verify.py" --example ex1 --part interval \
  --data "$PKG/fem/data/ex1" --reference "$PKG/fem/reference/ex1" \
  --output "$VI" --matlab "$MATLAB" --storage-root "$STORAGE"
"$PYTHON" -B "$PKG/scripts/monitor.py" "<VERIFY_ISOLATION_MONITOR>" \
  "$PYTHON" -B "$PKG/fem/scripts/verify.py" --example ex1 --part isolation \
  --data "$PKG/fem/data/ex1" --reference "$PKG/fem/reference/ex1" \
  --interval "$VI/science/interval.json" --output "$VH" \
  --matlab "$MATLAB" --storage-root "$STORAGE"
```

The outer monitor includes canonical-array conversion and output in verification cost. Each isolation stage has its own 30-minute soft / 40-minute hard budget; the surface stage may finish its last endpoint during the single permitted soft-limit extension. All process trees must remain below 3 GiB. No FMM2D installation is needed by FEM reproduce or verify.
