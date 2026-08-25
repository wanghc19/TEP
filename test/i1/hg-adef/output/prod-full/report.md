# M48 static half-guide to A-def report

- Status: `I1_2_M48_PASS_WITH_CONDITIONS`
- M/K: `48/97`
- Static validation time: `0.835454 s`
- First failure: ``
- I1.2 empirical ready: `1`
- Production separation: `NOT_EVALUATED_CAVEAT`
- Theorem conditioning claim: `0`
- Locator/root isolation authorized: `0/0`

## Gates

| Group | Gate | Status | Value | Tolerance |
|---|---|---|---:|---:|
| input | direct_m48_maps | PASS | 4.64166e-15 | 1e-10 |
| cell | block_coefficients | PASS | 5.74553e-14 | 1e-08 |
| cell | block_actions | PASS | 5.75745e-14 | 2e-09 |
| cell | full_pencil_change | PASS | 7.15904e-15 | 2e-09 |
| qz | direction_count_residual | PASS | 5.24692e-15 | 1e-10 |
| graph | coarse_fine_projectors | PASS | 7.05739e-15 | 1e-07 |
| chart | algebraic_dirichlet | PASS | 1 | 1 |
| dtn | coarse_fine_actions | PASS | 6.51931e-16 | 2e-09 |
| adef | graph_dtn_schur | PASS | 4.2986e-16 | 2.15383e-11 |
| adef | coarse_fine_action | PASS | 2.97955e-16 | 2e-09 |

The chart verdict is algebraic, not separation-certified. No Sylvester/Kronecker separation operator was formed or applied.

Single-point A-def singular values are metadata only and are not root evidence.
