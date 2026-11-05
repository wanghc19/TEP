# detsearch-v1: determinant root search version 1

BIE = boundary integral equation; FMM = fast multipole method; DtN = Dirichlet-to-Neumann; SVD = singular value decomposition; LU = lower-upper factorization; QZ = generalized Schur factorization; RSS = resident set size; I9 is the inherited experiment identifier; JSON = JavaScript Object Notation; CSV = comma-separated values; MAT is the MATLAB binary data format. Binary64 hex uses MATLAB num2hex (16 hexadecimal digits, most significant byte first); the exported hexadecimal float is also supplied.

Purpose: a standalone, empty-start candidate pipeline: unchanged I9 gap classification and representative checks, determinant localization, real-axis polish, fresh sigma-minimum confirmation. All scientific parameters are in search_config.m and the explicitly supplied I9 scientific configuration. Runtime reads source code and supplied paths only. The test-only known root is absent from production settings.

Prelaunch production estimate: gap 28–35 s, representative checks 10–15 s, 33 Chebyshev nodes and 2 off-grid evaluations about 100 s, polish and confirmation about 10 s; total 150–190 s including startup, peak 1.6 GiB, 11 threads after an idle-machine check. Forced-fallback test: original I9 fine manager on a known-root bracket of half-width 2e-10, about 40–80 evaluations, 2–5 minutes, peak 1.6 GiB. Both results together are expected below 10 minutes. Each run is monitored at 30 minutes soft / 40 minutes hard and 3 GiB RSS. Production writes no MAT files; the copied fallback retains its original fresh-confirmation MAT evidence.

Method: last three relative Chebyshev coefficients < 1e-10, two off-grid relative errors < 1e-9, cap degree 64, split at cap or log range > 18. Bernstein ellipse rho < 1.1; near-real threshold 1e-6. Polish uses the interpolant derivative until the complex step is < 2e-14 or the real update stalls. rcond < 1e-3, near-real root separation < 1e-7, or confirmation ratio > 1e-11 triggers the I9 fine-manager fallback. Duplicate confirmed roots use the separate tolerance 2e-13. The unchanged original matching entry point still computes its SVDs.

prepare_support.py copies numerical source inputs only into each run's inputs/ directory. The gap and sigma-minimum manager bodies retain their numerical logic. Its dispatcher is new; only large MAT writes and a diagnostic wording differ. The original gap stage includes representative/equal-lead checks. Each run retains compact JSON states. Output decimal strings are checked against binary64 hex and normalized to Python's shortest round-trip representation.

Production result (run-001, eleven threads): common interval [1.4509999999999998, 2.249], one candidate 1.558437894182088, binary64 hex 3ff8ef5c92c5bf30, hexadecimal float 0x1.8ef5c92c5bf30p+0. Difference from I9 is -2.88658e-15. Fresh aphys_ratio is 2.80361e-14. The 32-degree last-three coefficient ratio is 6.48e-11. Production uses 35 determinant evaluations (33 nodes, 2 off-grid), 2 polish evaluations, and 1 fresh confirmation; no fallback fires. The gap stage retains its original representative/equal-lead validation separately.

| Stage | evaluations | seconds |
|---|---:|---:|
| Gap exploration | original 33 coarse nodes | 28.2315 |
| Representative/equal-lead validation | original checks | 8.2481 |
| Determinant localization | 35 | 111.5490 |
| Polish | 2 | 6.4857 |
| Fresh confirmation | 1 | 3.1341 |
| Science total | 38 search match calls, plus original validation | 158.2758 |
| Monitored process | includes MATLAB startup/exit | 176.2683 |

Peak RSS is 0.94334 GiB. Idle-machine checks before and after the run are saved. Historical I9 science is 642.99 seconds (28.41 gap, 12.96 validation, 39.88 coarse, 508.24 fine, 5.74 confirmations, 47.76 remaining overhead); its 169 fine calls include the two confirmation calls. The prototype still calls the unchanged SVD-bearing physics function. Source bodies for the classifier, grids, dip detector, fine manager, and lead cache were compared with I9 and agree.

Forced-fallback control (run-002, eleven threads): 68 evaluations, 236.0587 seconds science, 249.3739 seconds monitored process, peak 0.98175 GiB. Eight original I9 rounds return a COMPLETE candidate 1.5584378941820887, hex 3ff8ef5c92c5bf33, final width 5.32907e-15, fresh ratio 2.87270e-14. Its difference from I9 is -2.22045e-15 and from the production candidate 6.66134e-16. The original manager also retains one nonwinning right-edge marker from round seven and therefore reports SEARCH_FINISHED_WITH_UNRESOLVED_INTERVALS. The candidate check passes; the unresolved search status is retained, not cleared by the adapter. Current reporting propagates it to the top-level status as well. Production has no such unresolved item.

The executed MATLAB sources are in each run's inputs directory. The current source additionally checks off-grid rcond and labels confirmation separately in the resource ledger; every recorded node is above that threshold. The reporter explicitly propagates an unresolved fallback state. These changes preserve the measured production numerical path. A fresh reproduction need only match the root within 2e-14, candidate count, and branch decisions; timings and bit-level root choices can vary at the plateau.

Reproduction from empty directories (the launcher refuses a nonempty directory):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/detsearch-v1/launch.py \
 --output /Users/whc/Documents/Work/dot-research/test/bie-bound/detsearch-v1/output/run-003 \
 --package-root /Users/whc/Documents/Work/dot-research \
 --search-path /Users/whc/Documents/Work/dot-research/test/i9/search-v1 \
 --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab \
 --mode production --threads 11
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/detsearch-v1/launch.py \
 --output /Users/whc/Documents/Work/dot-research/test/bie-bound/detsearch-v1/output/run-004 \
 --package-root /Users/whc/Documents/Work/dot-research \
 --search-path /Users/whc/Documents/Work/dot-research/test/i9/search-v1 \
 --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab \
 --mode forced-fallback --threads 11
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/detsearch-v1/check_result.py \
 test/bie-bound/detsearch-v1/output/run-003 test/bie-bound/detsearch-v1/output/run-004
```

The eleven-thread launcher refuses to start while another numerical Python/MATLAB job is active. Use five threads for development during competing work. The launch-summary file records the post-run check. Input preparation copies only source files into the fresh run; neither production nor the control reads prior numerical output. Candidate-list JSON and candidate-k text contain the shortest round-trip decimal and binary64 hex; coefficient and node CSV tables support the root localization audit. The control's original I9 confirmation MAT evidence is retained (5.41 MB); no field MAT is a runtime input.

Acceptance checks (set before candidate output): one near-real candidate within 2e-14 of 1.5584378941820909; the forced I9 fallback must return a complete candidate within the same tolerance; decimal/hex conversion must be bit-exact and use the shortest round-trip decimal. Production must report no unresolved interval; any exceptional path is retained with its reason.
