# I4 three-path derivative report

- Mode: `full`
- Status: `SLP_N_UNCERTIFIED`
- Started: `2026-08-10 17:02:48`
- Finished: `2026-08-10 17:04:57`
- Runtime: 129.258 s
- Backend: `MATLAB 23.2.0.2365128 (R2023b)`

- Scientific authority: `1`

## Frozen semantics

Internal derivatives use $X=|x_t-x_s|$ and names `GX_abs`, `GXY_abs`. Physical rows use $G_x=\operatorname{sign}(x_t-x_s)G_{X}$ and $G_{xy}=\operatorname{sign}(x_t-x_s)G_{XY}$. The case $x_t-x_s=0$ is rejected.

Neumann coefficients are raw: the direct oracle on both walls is $(\mathrm{i}\gamma_m)D_m$. Any normalized values in the CSV are supplemental and never enforced.

Package point prerequisites are action-specific: SLP-D uses $G$; SLP-N uses $G_x$; DLP-D uses $(G_x,G_y)$; and DLP-N uses $(G_{xx},G_{xy})$. $G_{yy}$ is diagnostic only.

## Decisions

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| published_reference | MANDATORY | EWALD_REFERENCE_CERTIFIED | 1 | Published values are checked in Linton sign convention. |
| value | MANDATORY | EWALD_VALUE_CERTIFIED | 1 | Physical signed components only; no abs-coordinate aliases. |
| gradient | MANDATORY | EWALD_GRADIENT_CERTIFIED | 1 | Physical signed components only; no abs-coordinate aliases. |
| hessian | MANDATORY | EWALD_HESSIAN_CERTIFIED | 1 | Physical signed components only; no abs-coordinate aliases. |
| projection_and_mutations | MANDATORY | ORACLE_CONTROLS_CERTIFIED | 1 | Pure Fourier projection and sign/normalization mutations. |
| runtime_authority | MANDATORY | DERIVATIVE_REFERENCE_CERTIFIED | 1 | MATLAB is the scientific authority. |
| P_point_kernel | DIAGNOSTIC | P_POINT_COMPONENTS_RECORDED | 1 | No global gate; each wall action consumes only its required components. |
| P_Gyy | IMPORTANT | P_Gyy_DIAGNOSTIC_OUTSIDE_GATE | 0 | Gyy is retained for diagnosis and is not a wall-action prerequisite. |
| SLP-D_P_point | MANDATORY | SLP_D_P_POINT_CERTIFIED | 1 | G max_error=5.138e-10 pass=1 |
| SLP-D | MANDATORY | SLP_D_CERTIFIED | 1 | Raw D/N coefficient pairs plus all enabled self-refinements. |
| SLP-N_P_point | MANDATORY | SLP_N_P_POINT_CERTIFIED | 1 | Gx max_error=1.224e-09 pass=1 |
| SLP-N | MANDATORY | SLP_N_UNCERTIFIED | 0 | Raw D/N coefficient pairs plus all enabled self-refinements. |
| DLP-D | MANDATORY | NOT_RUN_PREREQUISITE | 0 | Stopped after SLP-N failure; no coefficient rows emitted. |
| DLP-N | MANDATORY | NOT_RUN_PREREQUISITE | 0 | Stopped after SLP-N failure; no coefficient rows emitted. |

## Reproduction

Run in MATLAB from the repository root:

```matlab
addpath(fullfile(pwd,'test','i4-three-path-derivatives'));
run_i4_three_path_derivatives('full');
```
