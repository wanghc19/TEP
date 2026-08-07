# Root-readiness early-stop proxy diagnostic

- Diagnostic status: `PROXY_DIAGNOSTIC_COMPLETE`
- Root readiness: `BLOCKED_UPSTREAM_PROVENANCE`
- Sampled discrete GO: `0`
- Physical root ready: `STOP`
- Primary state: `BLOCKED_MIRRORED_CONSTRUCTOR_OUTPUT_REPRODUCTION`

## Scope

This experiment reconstructs and compares proxy solvers only. Candidate scans, complex disks, Cauchy--Riemann checks, root counts, Newton solves, eigenvalues, and estimators were not run.

The earlier interactive pilot numbers are labeled `DISCARDED_CORRUPTED_INTERACTIVE_PREFLIGHT` and are excluded from every gate.

## Production observations

- Base k=0.095 production full residual: `2.624417e-08`; coefficient norm: `1.477085e+00`.
- Base k=0.100 production full residual: `2.732265e-08`; coefficient norm: `1.501689e+00`.
- Base k=0.105 production full residual: `2.849913e-08`; coefficient norm: `1.530088e+00`.

The production interface does not expose its internal collocation matrix or right-hand side. Their entrywise or bytewise identity with the mirrored constructor is therefore `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`; no such identity is claimed.

## Seed-frozen ratio-rank diagnostic

- Selected ranks (base/refined): `126/144`.
- Maximum selected full residual: `3.261485e-08`.
- Maximum selected off-collocation residual: `5.911454e-08`.
- Maximum downstream relative difference: `1.670932e-09`.
- `base` projector rank `126`; left SHA-256 `10e9b38c1b3a79569d3ad46154a5a41fc0b5f9d8ed7eefe73dad7773dfa97df1`; right SHA-256 `6d97a4959cbfa5b6838e12294795bf0dda345bbb1ed862013614e7508149b3d2`.
- `refined` projector rank `144`; left SHA-256 `fa88c4455257e4be257c0bab7ebfba2dd63a8c026a2a710b690d41341184167d`; right SHA-256 `59358366a38d26ec16305e9d6d3bb030b28ffc5449ab53b2f356a81bec573f94`.

## Mirrored-constructor output verdict

These are output comparisons, not proof of internal constructor identity. The three frozen `1e-11` checks are:

- Coefficient-output relative error: `2.798540e-07` (threshold `1.0e-11`; pass `0`; label `MIRRORED_CONSTRUCTOR_COEFFICIENT_OUTPUT_REPRODUCTION_FAILURE`).
- Proxy-field-output relative error: `5.531552e-10` (threshold `1.0e-11`; pass `0`).
- Residual-output difference: `1.250388e-09` (threshold `1.0e-11`; pass `0`).

## Frozen object-compatibility gate

Every computed Green potential/gradient/Hessian, defect and bulk `A_QP`, and scattering object has an individual `PASS` or `FAIL` row against the frozen `1e-5` threshold.

- Base/refined Green maximum: `1.898508e-09`; pass `1`.
- Production/selected downstream maximum: `1.670932e-09`; pass `1`.
- Aggregate object compatibility: pass `1`.

## Provenance boundary

The source manifest hashes the diagnostic, wrapper, design, and every directly called project helper, including `+geom/construct_cont.m`. It is intentionally labeled `DIRECT_PROJECT_CALLS_ONLY`: transitive dependencies cannot be reliably enumerated here without runtime instrumentation. The diagnostic source SHA-256 is `e2f9ffdb52d27da5ba6957062cd00e132df7eee944f0c1c10aed0f3cfbe86048`.

## Decision boundary

The frozen object-compatibility gate is enforced and may pass independently. It cannot override the three failed observable output-reproduction checks or the unavailable internal `A,b` identity check.

Therefore this experiment emits `PROXY_DIAGNOSTIC_COMPLETE`, `ROOT_READINESS_SAMPLED_DISCRETE_GO=0`, and `PHYSICAL_ROOT_READY=STOP`. No scan, disk, Cauchy--Riemann, root, Newton, eigenvalue, or estimator stage was run.

## Reproducibility

- Status: `REPRODUCED`
- Relative numeric difference: `0.000000e+00`
- Source manifest equal: `1`
- Projector fingerprints equal: `1`
