# I4 DLP and trace report

- Mode: `full`
- Status: `DLP_D_N_MTRACE48_CERTIFIED`
- Pass: `1`
- Runtime: `95.539849 s`
- Backend: `MATLAB 23.2.0.2365128 (R2023b)`

## Decisions

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| preflight | BLOCKER | MATLAB_PACKAGE_SLP_AUTHORITIES_VERIFIED | 1 | Requires MATLAB lsqminnorm, exact package hashes, derivative authority, and certified p=0.2 SLP. |
| DLP-D pilot | BLOCKER | DLP_D_PILOT_CERTIFIED | 1 | Gx/Gy point, four-axis self, FD/sign/parity/nonmirror, rank, and q duplicate gates. |
| DLP-D wall | BLOCKER | DLP_D_WALL_CERTIFIED | 1 | E/P/R coefficient triangles and all four P axes passed. |
| DLP-N point | BLOCKER | DLP_N_POINT_CERTIFIED | 1 | Gxx/Gxy point/self and mixed-Hessian controls passed. |
| DLP-N wall | BLOCKER | DLP_N_WALL_CERTIFIED | 1 | E/P/R coefficient triangles and all four P axes passed. |
| auxiliary_ntot_Ny_Ewald_ladders | IMPORTANT CAVEAT | NOT_RUN_RUNTIME_SCOPE | 0 | The decisive p=0.2 axes and independent half-grid M_trace are run; extra ntot128/Ny256/Ewald ladders are deferred to stay within 90--180 s. |
| M_trace | BLOCKER | DLP_D_N_MTRACE48_CERTIFIED | 1 | All four actions, three paths, five levels, half-grid E/P reconstruction. |

## Reproduction

```matlab
addpath(fullfile(pwd,'test','i4-dlp-trace'));
run_i4_dlp_trace('full');
```
