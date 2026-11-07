# FEM release validation

FEM: finite element method; DtN: Dirichlet-to-Neumann; RT3: Raviart–Thomas degree three; RSS: resident set size.

Run-001 forecast: h=1/48 original interval chain, 750–1000 s, 2.7 GiB, native/flux data under 40 MB plus scalar records under 5 MB. Reference run took 734.613 s, 2.304 GiB. No FMM dependency. One MATLAB process, 11 threads, 30/40 minute limits and 3 GiB.

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


Run-002: band, h=1/48. Forecast 20–60 s, 0.8 GiB; outputs <100 MB. Before launch worktree 1519.04 MB, package 75.35 MB. All stages use 11 computational threads.

Run-003: surface, h=1/48. Forecast 1850–2150 s, 2.3 GiB; the four old endpoint costs sum to 1845 s. One soft extension is reserved for the final endpoint, never beyond 2400 s; outputs <100 MB. Before launch worktree 1519.22 MB, package 75.35 MB. All stages use 11 computational threads.

Run-001 passed: energy, mass, residual upper bound, fixed s, all four-corner endpoints and printed I₁ match the original pipeline bitwise. Monitor: 753.989815 s, 1.746353 GiB. The array writes are included in that cold cost. Run-002 passed all 472 band signs: minima 1.397223838884971e-4 and 7.520504511856631e-3; 2.633369 s, 0.065155 GiB. These use ordinary finite arithmetic and analytic truncation bounds.

Run-004: dtn, h=1/48. Forecast 1450–1750 s, 2.6 GiB; outputs <100 MB. Before launch worktree 1546.11 MB, package 75.37 MB. All stages use 11 computational threads.

Run-003 passed all four endpoint counts. Common historical test fields and error norms match exactly; the current lower-endpoint code adds response diagnostics that the older records did not contain. K+ = 279.899894626, K− = 0.70782; minimum M=10 surface margin 0.004289129615391685. Monitor 1840.951939 s, 1.705978 GiB; the planned soft-limit extension was used.

Run-005: core, h=1/48. Forecast 20–60 s, 1.3 GiB; outputs <100 MB. Before launch worktree 1548.71 MB, package 75.37 MB. All stages use 11 computational threads.

Run-006: h=1/36 cold interval, 450–800 s / 2.5 GiB; same original tolerances, no sign-condition adjustment. Preflight worktree 1548.84 MB; forecast retained additional 55.0 MB.

Run-004 passed: both lower matrices and all integration/series bounds exactly reproduce the original certificates. The current source independently evaluates finite element traces; its differences are 8.2523e-16 / 8.9692e-16, whereas the old reports contained only the structural identity (zero). Monitor 1500.724024 s, 1.899323 GiB. Run-005 passed with one negative direction and safe margin 0.36537368868193165; all common numerical fields match exactly. Monitor 14.701823 s, 1.081512 GiB. Isolation total 3359.011154 s (55.9835 min); combined with the h=1/48 interval run, 68.5500 min.

Run-006 stopped at a reshape error in flux assembly after 40.145407 s (1.297989 GiB), before any numerical interval check. The h=1/36 mesh has one-element final batches; a scalar material weight expands to a row. Run-007 is a diagnostic using that run's explicit native transport, forecast 15–45 s / 1.7 GiB / <1 MB output. It records the actual weight and density shapes; no sign or tolerance is changed.

Run-007 confirmed two single-element batches (center rule 5 and right rule 6): weights 256x1, density 1x256, unintended quotient 256x256. Explicit repetition along dimension 1 produces 256x1 with identical density entries; the multi-element case is unchanged. Diagnostic cost 21.332214 s, 1.300552 GiB. The package fixes only this shape handling in assembly and the other quadrature consumers. No nodes, tolerance, remainder or sign gate changes. Fresh cold runs are run-008 (h=1/36), run-009 (h=1/24); canonical verification follows as run-010 and run-011.

Run-008: h=1/36 cold interval, 450–800 s / 2.5 GiB; same original tolerances, no sign-condition adjustment. Preflight worktree 1557.31 MB; forecast retained additional 55.0 MB.

Run-009: h=1/24 cold interval, 450–800 s / 2.5 GiB; same original tolerances, no sign-condition adjustment. Preflight worktree 1607.06 MB; forecast retained additional 55.0 MB.

Run-008 passed every original field, geometry, quadrature and certificate gate. h=1/36: free degrees of freedom (left/core/right) 17901/17586/17793; four-corner width 1.5281187530177563e-8; I₁ width 1.85551030062e-4. Cold monitor 729.728642 s, 1.932510 GiB. The repaired one-element batches use unchanged quadrature entries.

Run-010: verify interval, 700–900 s / 2.6 GiB. Preflight worktree 1782.99 MB; forecast retained additional 90.0 MB.

Run-009 passed h=1/24: free degrees of freedom 9297/9144/9234, four-corner width 8.4032215320272075e-8; 542.490169 s, 1.522797 GiB. Run-010 stopped before reintegration because the MATLAB transport had the stored integer representation rather than the original double class for mesh parameters. The earlier roundtrip test checked storage arrays; it is replaced by a class-aware bitwise test. Run-011 repairs the canonical conversion from run-001 (no field generation), forecast <30 s / 1 GiB; values and complex imaginary parts are preserved. Fresh verification will use run-012 and run-013.

Run-012: verify interval, forecast 700–900 s / 2.6 GiB / <90 MB additional. Preflight worktree 1856.99 MB, package 151.70 MB.

Run-011 repaired the export and passed original MATLAB-class, shape and value-bit checks for both native and flux arrays. Cost 7.815268 s, 0.424759 GiB. Failed run-010 retains the previous transport and logs; no numerical certificate was computed from that transport.

Run-013: verify isolation, forecast 40–90 s / 1.5 GiB / <5 MB additional. Preflight worktree 1933.79 MB, package 151.70 MB.

Run-012 and run-013 passed. Canonical verification passed: reintegration reproduces E/M/S and both decimal endpoint pairs exactly (621.359 s, 1.498 GiB including transport); isolation verification reproduces all 472 band signs, surface and DtN tests, and the core count/margin (19.669 s, 0.987 GiB). The wrong-phase and invalid-band controls are rejected. Shared flux moment mismatch is 8.94e-19, cell-interface mismatch and outer normal moments are zero. The recorded scientific reads stay inside canonical package data and these verification runs; loaded MATLAB functions stay inside the package or MATLAB installation. All 55 bundled MATLAB files appear in the loaded-function records.

The canonical structural smoke test initially rejected three pre-search NaN placeholders (k0, mu0, window); only these named configuration fields are now permitted. Actual field/flux arrays are finite. Final FEM smoke, unchanged BIE ex1 smoke, package path scan and Python syntax checks pass. Of 278 pre-existing package files, only the root README changed; no BIE code/data/reference or shared script changed.

## Commands and records

Use the explicit commands in `release/bie-enclosure-sisc/fem/README.md`. For this validation, the stage-to-run mapping is interval h48=001, band=002, surface=003, DtN=004, core=005, interval h36=008, h24=009, canonical interval verification=012 and isolation verification=013. `command.json` inside each run's monitor records the exact executable invocation. `run-012-whole/` and `run-013-whole/` include Python transport in the enclosing times. The failed runs and diagnostics are listed above.

```sh
"$PYTHON" -B "$PKG/fem/scripts/reproduce.py" --example ex1 --stage interval --mesh 48 --output "$RUN" --matlab "$MATLAB" --storage-root "$STORAGE"
"$PYTHON" -B "$PKG/fem/tests/smoke.py" --data "$PKG/fem/data/ex1" --reference "$PKG/fem/reference/ex1"
"$PYTHON" -B "$PKG/tests/smoke.py" --data "$PKG/data/ex1" --reference "$PKG/reference/ex1"
"$PYTHON" -B "$PKG/tests/paths.py" --package "$PKG" --output "$CHECK/path-check.json"
```

The cost-width and isolation tables count selected successful cold configurations. The failed h36 launch, shape probe, failed export verification, class repair and all canonical checks remain separately measured records, not included in a successful configuration's cost. No numerical sign or certificate threshold was relaxed.
