# I4 package point diagnostic

- Status: `SOLVER_SENSITIVITY_UNCERTIFIED`
- Scientific authority: `1`
- Runtime: `MATLAB 23.2.0.2365128 (R2023b)`
- Gate: $2\times10^{-9}$
- Wall matrices built: `0`

- Frozen points satisfy `idx_in=true`: after manual swap their nonperiodic coordinate is $\pm0.217$ and $H=1.1$; the `C_down` branch is not used.

## Decisions

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| stage0_base | MANDATORY | DIAGNOSTIC_PREREQUISITE_REPRODUCED | 1 | B- value/gradient pass and all three Hessians reproduce known failure. |
| stage1_wrapper_parity | MANDATORY | NEGATIVE_DX_WRAPPER_CERTIFIED | 1 | Physical y wrapper against the manually swapped x-periodic call. |
| stage1_transverse_parity | IMPORTANT | UP_DOWN_APPROXIMATION_ASYMMETRY | 0 | Diagnostic only: parity failure does not implicate the wrapper or stop. |
| stage2_package_fd | MANDATORY | PAIRMAT_FORMULA_CERTIFIED | 1 | Package value/gradient FD, R9 authority, R8--R9 self, Helmholtz. |
| stage3_solver_sensitivity | MANDATORY | SOLVER_SENSITIVITY_UNCERTIFIED | 0 | One exact A,b; package closure, lsqminnorm, QR, and fixed SVD cuts. |
| stage4_proxy_ladder | MANDATORY | NOT_RUN_PREREQUISITE | 0 | Stopped after SOLVER_SENSITIVITY_UNCERTIFIED. |

## Reproduction

```matlab
addpath(fullfile(pwd,'test','i4-three-path-derivatives'));
run_i4_package_point_diagnostic();
```
