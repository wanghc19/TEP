# I4 three-path derivative report

- Mode: `qualification`
- Status: `OCTAVE_SANITY_PASS`
- Started: `2026-08-10 11:48:07`
- Finished: `2026-08-10 11:49:25`
- Runtime: 77.9746 s
- Backend: `Octave 10.3.0`

- Scientific authority: `0`

## Frozen semantics

Internal derivatives use $X=|x_t-x_s|$ and names `GX_abs`, `GXY_abs`. Physical rows use $G_x=\operatorname{sign}(x_t-x_s)G_{X}$ and $G_{xy}=\operatorname{sign}(x_t-x_s)G_{XY}$. The case $x_t-x_s=0$ is rejected.

Neumann coefficients are raw: the direct oracle on both walls is $(\mathrm{i}\gamma_m)D_m$. Any normalized values in the CSV are supplemental and never enforced.

## Decisions

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| published_reference | MANDATORY | EWALD_REFERENCE_CERTIFIED | 1 | Published values are checked in Linton sign convention. |
| value | MANDATORY | EWALD_VALUE_CERTIFIED | 1 | Physical signed components only; no abs-coordinate aliases. |
| gradient | MANDATORY | EWALD_GRADIENT_CERTIFIED | 1 | Physical signed components only; no abs-coordinate aliases. |
| hessian | MANDATORY | EWALD_HESSIAN_CERTIFIED | 1 | Physical signed components only; no abs-coordinate aliases. |
| projection_and_mutations | MANDATORY | ORACLE_CONTROLS_CERTIFIED | 1 | Pure Fourier projection and sign/normalization mutations. |
| runtime_authority | IMPORTANT CAVEAT | OCTAVE_SANITY_PASS | 1 | Octave is compatibility evidence only; MATLAB remains authoritative. |

## Reproduction

Run in MATLAB from the repository root:

```matlab
addpath(fullfile(pwd,'test','i4-three-path-derivatives'));
run_i4_three_path_derivatives('qualification');
```
