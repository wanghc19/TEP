# i4 Proxy Solver Diagnostic

- Decision: `PROXY_SOLVER_DIAGNOSTIC_UNRESOLVED`
- Runtime: `10.431179` seconds
- Package backend observed: `pinv`
- Ewald backend: `Octave complex erfc compatibility shim`
- Reference eligibility: `1.112389e-16` (tolerance `5.0e-12`)
- Chosen manual tau: `3.000000e-16`

## Rebuild preflight

| Level | A size | Default rank | Relative cutoff | Coeff diff | Field diff | Max coeff repeat | Max field repeat |
|---|---:|---:|---:|---:|---:|---:|---:|
| high | 720-by-354 | 183 | 1.598721e-13 | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 |
| higher | 960-by-450 | 213 | 2.131628e-13 | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 |

## Decision diagnostics

- Package/default/backslash/manual pass: `0/0/0/1`
- Default point error: `4.518188e-08`
- Best point error: `3.261699e-12`
- Improvement factor: `1.385225e+04`
- Selected solver/error/improvement: `manual_svd`, `3.949521e-12`, `1.143984e+04`
- Same-backend default coefficient/field difference: `0.000000e+00`, `0.000000e+00`
- Same-backend selected-tau point/cross pass: `0/0`
- Same-backend selected-tau point error/cross change: `5.977870e-05`, `7.929008e-05`
- Selected-tau ranks high/higher: `225/273`
- Restored singular directions: `42`
- Adjacent-tau plateau exists: `1`
- Selected-tau lower/upper neighbor changes high: `6.207827e-12`, `3.547527e-12`
- Selected-tau lower/upper neighbor changes higher: `5.452077e-12`, `5.081702e-12`
- Near-solver field agreement high/higher: `NaN`, `NaN` (qualified counts `1/1`; NaN means vacuous)

## Claim boundary

This decision concerns three canonical point Green values only. It makes no derivative, Hessian, wall projection, layer-density, BIE, complex-root, or root-readiness claim.
