# Provenance-closure diagnostic: baseline

- Status: `PROVENANCE_CLOSURE_DIAGNOSTIC_COMPLETE`
- Operational label: `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_BLOCKED`
- Finalization state: `FINAL_COMPLETE_BLOCKED`
- Artifact bundle complete: `1`
- Root readiness: `BLOCKED_UPSTREAM_PROVENANCE`
- Sampled discrete GO: `0`
- Physical root ready: `STOP`

## Claim boundary

The package-internal collocation arrays remain `NOT_DIRECTLY_OBSERVED` with reason `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. A positive operational label establishes only source-derived shared-system provenance.

## Source audit

- Package source lock: `1`
- Source-exact copied body: `1`
- Context independence: `1`
- Execution manifest complete: `1`
- Minimum-norm branch: `pinv`
- Synthetic mutation rejected without execution: `1`

## Numerical evidence

- Shared-system rows: `6`
- Selected ranks (base/refined): `126/144`
- Maximum coefficient-output error: `0.000000e+00`
- Maximum proxy-field-output error: `0.000000e+00`
- Maximum residual-output error: `0.000000e+00`
- Maximum base/refined Green difference: `1.898507e-09`
- Maximum downstream object difference: `1.670931e-09`

## Historical projector diagnostic (non-gating)

- `base`: available `1`, state `DIFFERENT`, ranks `126/126`, left/right relative differences `3.481091e-10/1.299474e-10`, left/right bitwise equal `0/0`, note `NON_GATING_HISTORICAL_DIAGNOSTIC`.
- `refined`: available `1`, state `DIFFERENT`, ranks `144/144`, left/right relative differences `1.830556e-10/4.626516e-10`, left/right bitwise equal `0/0`, note `NON_GATING_HISTORICAL_DIAGNOSTIC`.

## Reproducibility

- Status: `PENDING_REPEAT`
- Numeric relative difference: `NaN`
- Manifest equal: `0`
- Execution manifest complete in both runs: `0`
- Baseline artifact bundle complete: `0`
- Shared fingerprints equal: `0`
- Projector fingerprints equal: `0`

No scan, complex disk, Cauchy--Riemann test, contour count, Newton solve, eigenvalue, adjacent-level correction, or estimator was run.
