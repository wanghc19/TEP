# eig-apost experiments

The current eig-apost implementation route starts at I1. Experiment IDs are stable even if a
directory later moves; this index and current-facing README files then follow the new path, while
frozen outputs retain their recorded paths and hashes.

## I1-HG-ADEF-V1

| Field | Value |
|---|---|
| Experiment ID | `I1-HG-ADEF-V1` |
| Stage | I1.2 |
| Purpose | Joint manufactured, low-order, and direct $M=48$ half-guide-to-$A_{\mathrm{def}}$ verification |
| Current path | `test/i1/hg-adef/` |
| Entry point | `make_prod('full')`, then `run_prod('full')` in MATLAB |
| Authoritative report | [[test/i1/hg-adef/output/prod-full/report|MATLAB M48 static report]] |
| Status | `I1_2_M48_PASS_WITH_CONDITIONS / EMPIRICAL I1.3 READY` |
| Implementation summary | [[research/projects/eig-apost/implementation/i1/README|current I1 guide]] |

## I1-K-SCAN-V1

| Field | Value |
|---|---|
| Experiment ID | `I1-K-SCAN-V1` |
| Stage | I1.3 |
| Purpose | Check real-$k$ continuity and carry one discrete candidate through $M=12\to24\to48$ |
| Current path | `test/i1/k-scan/` |
| Entry point | `tep_mc_scan('pilot')`, `tep_mc_scan('continuity')`, then `tep_mc_scan('full')` in MATLAB |
| Authoritative report | [[test/i1/k-scan/output/full/report|MATLAB staged candidate report]]; continuity qualification is [[test/i1/k-scan/output/continuity/report|reported separately]]; the v1 zoom stop is preserved as [[test/i1/k-scan/output/zoom/report|historical design-gate evidence]] |
| Status | `I1_3_PASS_WITH_CONDITIONS / M48_DISCRETE_REAL_AXIS_CANDIDATE_RECORDED`; v1 zoom is frozen historical evidence |
| Implementation summary | [[research/projects/eig-apost/implementation/i1/README|current I1 guide]] |

## I1-K-SCAN-ZOOM-V2

| Field | Value |
|---|---|
| Experiment ID | `I1-K-SCAN-ZOOM-V2` |
| Stage | I1.3 |
| Purpose | Refine the fixed-$M=48$ real-axis candidate until the evaluated interval width is below $10^{-6}$ without using prominence as a stop gate |
| Current path | `test/i1/k-scan/` |
| Entry point | `tep_mc_zoom2('pilot')`, then `tep_mc_zoom2('full')` in MATLAB |
| Authoritative report | [[test/i1/k-scan/output/zoom2/report|MATLAB width-driven zoom report]] |
| Status | `ZOOM2_M48_DISCRETE_GRID_COMPLETE / CANDIDATE ONLY` |
| Implementation summary | [[research/projects/eig-apost/implementation/i1/README|current I1 guide]] |

## I1-K-READY-V1

| Field | Value |
|---|---|
| Experiment ID | `I1-K-READY-V1` |
| Stage | I1.4 |
| Purpose | Test whether the fixed-$M=48$ I1.3 dip belongs to one sampled, anchored complex-$k$ discrete family and survives branch, factor, QZ, graph/DtN, CR, closure, and negative gates |
| Current path | `test/i1/k-ready/` |
| Entry point | `run_v4`, followed by the source-locked negative closure `run_v5`, in MATLAB; new campaigns must use new output tags |
| Authoritative report | [[test/i1/k-ready/output/v5-a1/report|V5 conditional closure]]; its frozen positive parent is [[test/i1/k-ready/output/v4-a1/report|V4 sampled-disk report]], whose sole failure remains the symmetry-inapplicable transmission-swap negative |
| Status | `I1_4_PASS_WITH_CONDITIONS / SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS`; candidate only, no locator/root/eigenvalue |
| Implementation summary | [[research/projects/eig-apost/implementation/i1/README|current I1 guide]] |

## I2-K-COUNT-M1B-V1

| Field | Value |
|---|---|
| Experiment ID | `I2-K-COUNT-M1B-V1` |
| Stage | I2.1 |
| Purpose | Determine whether the frozen fine-$M=48$ I1 dip disk contains one finite-dimensional $A_{\mathrm{def}}^D$ zero while separately screening evaluator and elimination factors |
| Current path | `test/i2/k-count/` |
| Entry point | Preserved reproduction command: `run_i21('full')` in MATLAB; append-only output tag `m1-a1` must not be reused |
| Experiment index | [[test/i2/k-count/README|I2.1 design, authorization, evidence, and reproduction index]] |
| Status | `I2_1_PASS_WITH_CONDITIONS / CONDITIONAL_EMPIRICAL_FINE_M48_COUNT_ONE`; `smoke-a1` failure and `smoke-a2` readiness parent preserved |
| Implementation summary | [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] |

## I2-H-STRUCTURE-DIAGNOSTIC-V1

| Field | Value |
|---|---|
| Experiment ID | `I2-H-STRUCTURE-DIAGNOSTIC-V1` |
| Stage | I2.2 |
| Purpose | Check the same fine-$M=48$ I2.1 object's endpoint structure, object equivalence, and fail-close theory gates at the two frozen I1.3 L14 shoulders; no inertia is computed |
| Current path | `test/i2/h-inertia/` |
| Entry point | `check_h_struct('compact-a1')`; standalone structure diagnostic, not run in this refactor; endpoint sign counts use the separate experiment below |
| Experiment index | [[test/i2/h-inertia/README|I2.2 compact implementation and preserved run-history index]] |
| Status | Historical `diag-a2`: `PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE`; compact implementation is statically reviewed only and preserves `NaN/UNAVAILABLE` inertia while both theory qualifications remain false |
| Implementation summary | [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] |

## I2-H-INERTIA-SURROGATE-V1

| Field | Value |
|---|---|
| Experiment ID | `I2-H-INERTIA-SURROGATE-V1` |
| Stage | I2.2 |
| Purpose | Count signs of the Hermitian part of the same raw endpoint $H=A/T$, with an operator-norm unresolved band, as numerical corroboration only |
| Current path | `test/i2/h-inertia/` |
| Entry point | Completed append-only attempt: `check_h_inertia('inertia-a1')` |
| Experiment index | [[test/i2/h-inertia/README|I2.2 structure history and Hermitian-part sign-count index]] |
| Status | `PASS WITH CONDITIONS / HERMITIAN_PART_SINGLE_JUMP`; raw-$H$ inertia remains unavailable |
| Implementation summary | [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] |

## I2-K-DRIFT-V1

| Field | Value |
|---|---|
| Experiment ID | `I2-K-DRIFT-V1` |
| Stage | I2.3 |
| Purpose | Compare the same candidate and physical mode across the single boundary-Nyström axis $n_{\mathrm{tot}}=160,208,256$, with fixed $M=48$, proxy, window, functional, locator, solver and identity rules |
| Current path | `test/i2/k-drift/` |
| Entry point | Completed append-only attempt: `check_k_drift('drift-a1')` |
| Experiment index | [[test/i2/k-drift/README|I2.3 design, command, result and boundary index]] |
| Status | `PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`; the immutable artifact retains its preregistered `DRIFT_UNRESOLVED` machine field, while terminal half-width is now treated only as a sub-grid minimizer-localization diagnostic |
| Implementation summary | [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] |

## I2-M-DRIFT-V1

| Field | Value |
|---|---|
| Experiment ID | `I2-M-DRIFT-V1` |
| Stage | I2.3 |
| Purpose | Compare the saved candidate and physical mode across the single Rayleigh/Fourier cutoff axis $M=32,40,48$, with fixed $n_{\mathrm{tot}}=160$, fine proxy, window, functional, locator, solver and identity rules |
| Current path | `test/i2/m-drift/` |
| Entry point | Completed append-only attempt: `check_m_drift('m-drift-a2')`; `m-drift-a1` was consumed by a preflight-only failure with zero evaluator calls and no output |
| Experiment index | [[test/i2/m-drift/README|I2.3 M-axis command, run history, result and claim-boundary index]] |
| Status | `PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / ADJACENT SAME_MODE / CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY`; all three saved candidates are 1.832770289108157 with zero direct drift, while the common $9.31323\times10^{-11}$ halfwidth remains only a sub-grid minimizer-search diagnostic |
| Implementation summary | [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] |

## I3-CENTER-STRONG-RESID-V1

| Field | Value |
|---|---|
| Experiment ID | `I3-CENTER-STRONG-RESID-V1` |
| Stage | I3.1 |
| Purpose | Apply a fixed compact cutoff to the saved candidate's explicit field in the homogeneous empty center column and compute a continuous strong-residual norm ratio |
| Current path | `test/i3/s-resid/` |
| Entry point | Completed append-only attempt `check_s_resid('center-a1')` |
| Experiment index | [[test/i3/s-resid/README|I3.1 object, command, resource and interpretation index]] |
| Status | `PASS WITH CONDITIONS / CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE / FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`; computed ratio $22.43882099031153$, but no reliable numerical enclosure or continuous projected-gap claim |
| Implementation summary | [[research/projects/eig-apost/implementation/i3/README|current I3 guide]] |

## I3-BIE-INFORMED-GLOBAL-RESID-V1

| Field | Value |
|---|---|
| Experiment ID | `I3-BIE-INFORMED-GLOBAL-RESID-V1` |
| Stage | I3.1 |
| Purpose | Build one smooth BIE-informed center-plus-infinite-leads trial at the saved candidate and compute its continuous strong-residual ratio with true material weight |
| Current path | `test/i3/g-resid/` |
| Entry point | Completed Revision B attempt `check_g_resid('lead-a3')`; `lead-a1` was consumed at MATLAB startup and `lead-a2` by the preserved density-oracle naming failure |
| Experiment index | [[test/i3/g-resid/README|I3.1-B object, frozen gates, command, resources, and interpretation boundary]] |
| Status | `PASS WITH CONDITIONS / VALID NEGATIVE / CONFORMING_RECONSTRUCTION_UNRESOLVED`; `lead-a3` passed finite input, density representation, and propagation, then failed the fixed BIE-informed holdout gate ($J=4$: $4.522421$; $J=8$: $5.138028$ versus $0.20$). Center/Gram/tail/residual estimator are `NOT_REACHED`; I3.2 remains unavailable. |
| Implementation summary | [[research/projects/eig-apost/implementation/i3/README|current I3 guide]] |

## I3-Q1-RT0-WEAK-RESIDUAL-V2

| Field | Value |
|---|---|
| Experiment ID | `I3-Q1-RT0-WEAK-RESIDUAL-V2` |
| Stage | I3.1 |
| Purpose | Reconstruct a conforming whole-waveguide Q1 trial from the saved candidate, build a global RT0 flux, and compute an ordinary-double functional-majorant candidate for the continuous weak residual |
| Current path | `test/i3/w-resid/` |
| Entry point | Completed formal attempt: `check_w_resid('weak-a1')` |
| Experiment index | [[test/i3/w-resid/README|V2 attempt, schema, grid, result, resources, and claim limits]] |
| Status | `POST-RUN PASS / VALID NEGATIVE / MAJORANT_QUADRATURE_UNRESOLVED`; base Q1--RT0 and full-$P$ tail checks passed, but the fine phase/scale repeat failed the per-cell Gram Hermitian gate (maximum defect $6.2442\times10^{-10}$ versus $10^{-12}$). No estimator was formed and I3.2 remains unavailable. |
| Implementation summary | [[research/projects/eig-apost/implementation/i3/README|current I3 guide]] |

Future current-route experiments belong under the matching `test/i*/` stage directory and receive
an index entry only after they are designed and authorized. A legacy verdict never becomes a
current stage gate.

The complete former I0--I4 experiment bundle, including its original index, scripts, configurations,
reports and frozen outputs, is preserved at
[[test/archive/legacy-route-v1/README|legacy route v1 experiment index]]. Historical paths, hashes
and manifests inside that archive remain unchanged.
