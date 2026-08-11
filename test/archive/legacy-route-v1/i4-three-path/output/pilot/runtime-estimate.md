# I4 full SLP-D runtime estimate

This estimate is measured from the pilot with `ntot=32`, `Ny=64`, `M=12`, the base Ewald truncation, and the base package proxy. It is required before any full wall ladder is launched.

| Quantity | Value |
|---|---:|
| Pilot Ewald two-wall time (s) | 0.995510 |
| Pilot MFS two-wall time (s) | 1.538551 |
| Pilot proxy precomputation (s) | 0.553460 |
| Pilot source-target interactions | 4096 |
| Full Ewald source-target interactions | 786432 |
| Full proxy-weighted interactions | 210501632 |
| Ewald ladder estimate (s) | 211.168 |
| MFS wall matrices estimate (s) | 307.662 |
| Proxy precomputations estimate (s) | 5.574 |
| Central full-ladder estimate (s) | 524.405 |
| Scaling range (s) | 419.524--786.607 |

Ewald matrix time is scaled by source-target count and the explicit Eq. (2.65) work proxy `(2*M1+1)+(2*M2+1)*(N+1)`. MFS matrix time is scaled by source-target count and `1+4*Nedge`; proxy setup is scaled by `equations*unknowns^2`. The range is a workload estimate, not a deadline or scientific result.
