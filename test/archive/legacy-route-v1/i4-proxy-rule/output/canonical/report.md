# I4 proxy-rule report

- Mode: `full`
- Status: `SLP_D_N_CERTIFIED_PROXY_RATIO_0P2`
- Pass: `1`
- Runtime: `69.037429 s`
- Backend: `MATLAB 23.2.0.2365128 (R2023b)`
- Public solver: `/Applications/MATLAB_R2023b.app/toolbox/matlab/matfun/lsqminnorm.m`
- Driver SHA-256: `0e89cfc9e14d1661e90d36ef3099cc0a0199a2d6e32335671da933d89f7da708`
- Config SHA-256: `3733720afa30123b740bba2ad31e846b89191b3ed309d6ac5aec70bcfe49adf3`
- Sole proxy ratio: `0.20000000000000001`
- Singularity margin: `0.29999999999999999`
- Wood distance metadata: `1.3603695988`

## Decisions

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| runtime_package_preflight | BLOCKER | MATLAB_LSQMINNORM_PACKAGE_VERIFIED | 1 | Requires MATLAB, lsqminnorm, expected package paths, and exact hashes. |
| authority | BLOCKER | FROZEN_AUTHORITIES_VERIFIED | 1 | SHA-256 verified before reading E/R coefficients or Ewald Gx points. |
| pilot_point | BLOCKER | PILOT_PROXY_POINT_CERTIFIED | 1 | Base Gx Ewald error and every base-to-axis Gx point change are pilot wall prerequisites. |
| wall_base | BLOCKER | COMMON_PROXY_BASE_CERTIFIED | 1 | Both SLP-D and SLP-N pass frozen E/P/R coefficient and tail gates. |
| wall_Nedge | BLOCKER | SLP_D_N_NEDGE_SELF_CERTIFIED | 1 | Both densities, both walls, and every retained mode are within gate. |
| wall_Nside | BLOCKER | SLP_D_N_NSIDE_SELF_CERTIFIED | 1 | Both densities, both walls, and every retained mode are within gate. |
| wall_Ntop | BLOCKER | SLP_D_N_NTOP_SELF_CERTIFIED | 1 | Both densities, both walls, and every retained mode are within gate. |
| wall_Mpw | BLOCKER | SLP_D_N_MPW_SELF_CERTIFIED | 1 | Both densities, both walls, and every retained mode are within gate. |
| SLP-D/SLP-N | BLOCKER | SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 | 1 | One common public package proxy configuration is certified. |

## Reproduction

```matlab
addpath(fullfile(pwd,'test','i4-proxy-rule'));
run_i4_proxy_rule('full');
```
