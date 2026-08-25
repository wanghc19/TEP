# I4 DLP and trace canonical audit

- Status: `DLP_D_N_MTRACE48_CERTIFIED`
- Runtime: `95.539849 s`
- MATLAB: `R2023b`
- Driver SHA-256: `2fc2cfaadd56bb7c2c66786765a2a4c0f8aeaf0ac76ad171f1db207d33ecdf8e`
- Config SHA-256: `d059e4d9f55988e09ed660314191aef62c3cdacf7b5a937fc392ec5fb80f4fec`
- Results MAT SHA-256: `4e72ad589841cfe037b81be423d6e9cecf12c1c0112a752b5002e6f86a650c38`

## Sequential decisions

| Stage | Result |
|---|---|
| MATLAB/package/upstream preflight | pass |
| DLP-D point and sign pilot | pass |
| DLP-D Ewald/MFS/Rayleigh wall action | pass |
| DLP-N Hessian, rank, and sign gate | pass |
| DLP-N Ewald/MFS/Rayleigh wall action | pass |
| Four-action $M_{\mathrm{trace}}=48$ finite screen | pass |

No scientific gate failed.  An initial pilot invocation exposed a public
pair-matrix layout edge case when one target and several displaced sources
were supplied in one call.  The experiment's source finite differences were
corrected to use one scalar source per call; package source was not modified,
and the 512-target wall path does not trigger this shape.  The corrected
source/target sign errors are at most $3.66\times10^{-11}$.

## Three-path coefficient maxima

| Action | E--P | E--R | P--R |
|---|---:|---:|---:|
| SLP--D | $1.64\times10^{-14}$ | $5.40\times10^{-16}$ | $1.66\times10^{-14}$ |
| SLP--N | $3.42\times10^{-14}$ | $1.03\times10^{-15}$ | $3.47\times10^{-14}$ |
| DLP--D | $1.39\times10^{-14}$ | $3.69\times10^{-16}$ | $1.36\times10^{-14}$ |
| DLP--N | $1.19\times10^{-13}$ | $5.57\times10^{-16}$ | $1.19\times10^{-13}$ |

The coefficient CSV contains 9,264 unique action/density/side/mode/path-pair
rows: 2,316 rows for each action.  Every absolute error is below the frozen
$10^{-8}$ gate.  Floored relative errors remain in the CSV and are not used to
reject very small coefficients.

## Point, self, and rank maxima

- DLP-D base point error: $2.18\times10^{-14}$.
- DLP-N base Hessian point error: $5.41\times10^{-14}$.
- Mixed-Hessian/source-target finite-difference error: $5.58\times10^{-10}$.
- DLP-D package wall self: $6.37\times10^{-14}$.
- DLP-N package wall self: $1.40\times10^{-13}$.
- Numerical ranks `(302,328,302,302,330)` reproduce the preregistered base,
  Nedge, Nside, Ntop, and $M_{\mathrm{pw}}$ values.
- Public-solution relative residuals range from $8.40\times10^{-13}$ to
  $2.34\times10^{-12}$; duplicated proxy coefficients agree exactly.

## Physical trace screen

The wall-sample CSV contains 49,152 rows: four actions, two densities, two
walls, three paths, two grids, and 512 samples per group.  Fourier bandwidths
were frozen as $M\in\{12,24,48,64,96\}$ before the run.  At the candidate
$M=48$:

- worst half-grid reconstruction error: $7.08\times10^{-12}$;
- worst omitted maximum on $48<|m|\le96$: $1.11\times10^{-13}$;
- worst omitted coefficient energy: $5.00\times10^{-13}$;
- worst $48\to64$ reconstruction change: $8.67\times10^{-13}$;
- worst $64\to96$ reconstruction change: $2.28\times10^{-12}$.

All are below the unchanged $2\times10^{-9}$ gate.  This certifies
$M_{\mathrm{trace}}=48$ only for the frozen manufactured actions and finite
$M_{\mathrm{ref}}=96$ screen.  It is not an infinite-tail theorem or a
uniform statement for every solved BIE density.

## Classification

- `BLOCKER`: none in DLP/trace closure.
- `IMPORTANT CAVEAT`: additional $n_{\mathrm{tot}}$, $N_y$, and Ewald wall
  ladders were not rerun; the current finite screen must be repeated for an
  actual solved density or changed geometry.
- `MINOR CAVEAT`: the package proxy list retains its known duplicated corner;
  rank and proxy-edge tail diagnostics are not promoted to scientific gates.
  The one-target/many-source pair-matrix edge case also remains for a future
  package regression because package edits were outside this experiment.

The next permitted task is the block-balanced $A_{\mathrm{def}}$/scanner
integration.  A bounded real-axis locator remains blocked until that matrix
and actual scanner path pass their own noncandidate rank and scaling gates.
