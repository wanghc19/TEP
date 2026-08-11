# Initial Proxy Solver Run — Preserved Summary

This is an explicit summary of the first `INVALID_REFERENCE_OR_REBUILD` run.
The full initial CSV/MAT artifacts had already been overwritten by the first
exact-order rerun when the preservation request arrived; they are not claimed
to be preserved.

- Runtime: `4.3996489048` seconds
- Reference eligibility: `1.1123893155e-16`
- High package/local-pinv coefficient difference: `6.2832465583e-04`
- High package/local-pinv point-field difference: `6.5722870644e-08`
- Higher coefficient difference: `5.206317e-04`
- Higher point-field difference: `2.168344e-08`
- Decision: `INVALID_REFERENCE_OR_REBUILD`

The locally factored Green expressions changed the mirrored matrix by only
roundoff relative to a source-identical instrumented copy:

| Level | Relative matrix difference | Max matrix entry difference | Relative RHS difference | Max RHS entry difference |
|---|---:|---:|---:|---:|
| high | `5.700016e-19` | `1.241267e-16` | `1.022030e-16` | `2.482534e-16` |
| higher | `4.117854e-19` | `1.241267e-16` | `1.001591e-16` | `2.482534e-16` |

The strict preflight correctly rejected these tiny assembly differences
because the nearly rank-deficient pseudoinverse amplified them. The active
runner now mirrors the package anonymous Green expressions in their literal
operation order and separately records repeated package and local-pinv calls.
