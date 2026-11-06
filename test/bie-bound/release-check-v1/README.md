# Release checking version 1

Validation logs for the self-contained BIE (boundary integral equation) example-1 package. Cold reproduction forecast: 14–16 minutes, 2.2 GiB; Python verification: 10–13 minutes, 2.2 GiB. Both use 30/40 minute limits and 3 GiB.

run-001: numerical certificates passed, but the final dependency audit found MATLAB current-folder package precedence. Preserved as an operational packaging failure; the corrected driver uses `-sd` and asserts dependency paths. A new cold reproduction is forecast at 14–16 minutes and 2.5 GiB.
run-002: I1 trace pilot, 17.19 seconds, 0.180 GiB.
run-003: clean-copy verification passed, 613.60 seconds, 2.306 GiB.
run-004: corrected self-contained cold reproduction passed, 850.85 seconds, 1.739 GiB. Candidate, field data and scientific results match the prior numerical run exactly.
run-005 forecast: final canonical data and package in a fresh external copy, verify plus smoke. 10–13 minutes, 2.5 GiB; 30/40 minute and 3 GiB limits. Python bytecode writes are disabled in the final entry points, so the release sources remain clean.

Final standalone control forecast: at most 30 seconds and 0.5 GiB after the full verification. It calls the packaged deliberately failing band test; no new scientific configuration is tested. Smoke uses exact integer/rational checks only.

run-005 completed: final clean-copy verify 652.121 s; maximum sampled RSS across monitors 1.995 GiB (outer monitor 1.979 GiB). All printed scientific values match exactly, all 472 signs and four independent LDL* checks pass, the invalid threshold fails, and I1 passes. The file ledger has 469 reads and no repository reads. Seventy-five final source/data files equal the clean copy. Standalone failure-control entry: 2.103 s / 0.199 GiB; smoke: 0.208 s. All outputs are under output/run-005; the temporary clean copy remains available at its path recorded in clean-copy.json.

Reproduction uses the explicit command in the package README. The accepted canonical input comes from run-004/02-field, promoted by scripts/promote.py. Scientific results and references are in release/bie-enclosure-sisc/reference. run-001 and every later record are retained.

## Release R2

Run-006 forecast: ex2-L1, one complete cold driver, 18–22 minutes (search 450 s, field 20 s, reliable groups 450–600 s, other certificates 155 s), 2.6 GiB; outputs below25 MB and canonical data below14 MB. Eight residual workers, 80/80 states, tail-square target1e-6. The explicit example file supplies the model. Whole-run30/40 min and3 GiB limits apply.

R2 run-007: ex2-L1 verify; complete forecast 900 s, 2.7 GiB, retained output below 40 MB. Before launch: worktree 1268.78 MB, package 30.81 MB, validation 158.53 MB.

R2 run-008: ex2-L2 cold; complete forecast 1650 s, 2.4 GiB, retained output below 40 MB plus canonical data below 14 MB. Before launch: worktree 1275.47 MB, package 30.83 MB, validation 165.19 MB.

R2 run-009: ex2-L2 verify; complete forecast 1250 s, 2.4 GiB, retained output below 40 MB. Before launch: worktree 1308.81 MB, package 45.54 MB, validation 184.07 MB.

R2 run-010: ex2-L1.6 cold; complete forecast 1400 s, 2.3 GiB, retained output below 40 MB plus canonical data below 14 MB. Before launch: worktree 1321.75 MB, package 45.56 MB, validation 196.70 MB.

R2 run-011: ex2-L1.6 verify; complete forecast 1000 s, 2.3 GiB, retained output below 40 MB. Before launch: worktree 1350.86 MB, package 60.16 MB, validation 211.19 MB.

R2 run-012: ex2-L1.9 cold; complete forecast 1500 s, 2.1 GiB, retained output below 40 MB plus canonical data below 14 MB. Before launch: worktree 1359.07 MB, package 60.18 MB, validation 219.37 MB.

R2 run-013: ex2-L1.9 verify; complete forecast 1100 s, 2.1 GiB, retained output below 40 MB. Before launch: worktree 1390.09 MB, package 74.83 MB, validation 235.72 MB.

R2 run-014: ex1 verify; complete forecast 900 s, 2.5 GiB, retained output below 40 MB. Before launch: worktree 1400.20 MB, package 74.85 MB, validation 245.79 MB.

## R2 completed validation

All four fresh cold runs and their canonical verifies passed; ex1 also passed a new verify. New MATLAB source and Python stages are inside the release package. Each public run performed its own heavy-process preflight and shared stage budget.

| Example | Cold / verify runs | Cold / verify seconds | Cold / verify peak GiB | Width |
|---|---|---:|---:|---:|
| ex2-L1 | 006 / 007 | 1076.195 / 574.507 | 1.786 / 2.114 | 0.0000000000030865909669693 |
| ex2-L1.6 | 010 / 011 | 1194.219 / 718.551 | 1.689 / 1.959 | 0.0000000000063518489429721 |
| ex2-L1.9 | 012 / 013 | 1352.766 / 854.347 | 1.749 / 1.945 | 0.0000000000052160427687771 |
| ex2-L2 | 008 / 009 | 1531.664 / 1063.376 | 2.492 / 2.184 | 0.0000000000081552944188614 |

Ex1 run-014 verify: 679.385 s, 1.917 GiB. R1 canonical data and reference scientific values remain unchanged. L1 has only a 9.21e-9 relative wall-bound change from the later per-field envelope coordinate correction; all other new-point scientific values equal the earlier records. The isolated-Python promotion import and zero-row smoke encoding needed maintenance repairs; both are recorded in run-006/promotion-repair.json, and no scientific run was repeated.

Package references contain the comparisons, per-point verify results, general-p tails, resource inventory and final absolute-path scan. The public numerical runs read no earlier experiment outputs; earlier-result comparisons were performed only afterward.
