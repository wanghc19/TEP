# I4 DLP and trace report

- Mode: `pilot`
- Status: `DLP_D_PILOT_CERTIFIED`
- Pass: `1`
- Runtime: `1.711421 s`
- Backend: `MATLAB 23.2.0.2365128 (R2023b)`

## Decisions

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| preflight | BLOCKER | MATLAB_PACKAGE_SLP_AUTHORITIES_VERIFIED | 1 | Requires MATLAB lsqminnorm, exact package hashes, derivative authority, and certified p=0.2 SLP. |
| DLP-D pilot | BLOCKER | DLP_D_PILOT_CERTIFIED | 1 | Gx/Gy point, four-axis self, FD/sign/parity/nonmirror, rank, and q duplicate gates. |

## Reproduction

```matlab
addpath(fullfile(pwd,'test','i4-dlp-trace'));
run_i4_dlp_trace('pilot');
```
