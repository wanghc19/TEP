# I2.3 M-axis saved-candidate drift

This directory contains the frozen, independent Rayleigh/Fourier-cutoff
experiment. It holds the boundary Nyström order and fine proxy fixed while
varying only $M=32,40,48$ (hence $K=65,81,97$).

## Entry point

`check_m_drift.m` is the only MATLAB entry point. It:

1. builds an independent `eval_i21` seed and frame for each $M$;
2. checks the frozen alternate-selector gauge using the same raw seed basis;
3. runs the registered five-point dyadic locator through layer 11;
4. checks raw, factor, graph, boundary, field, and fixed-candidate repeat gates;
5. compares balanced port, weighted wall-trace, and nine-probe representations;
6. reports direct differences of the saved terminal-grid candidates.

The singular values saved by the runner are in increasing order. Thus `s1`
uses the first and last entries, while `r12` uses the two smallest entries.

## Formal command

From the repository root, after independent run approval:

```sh
matlab -batch "addpath(fullfile(pwd,'test','i2','m-drift'),fullfile(pwd,'test','i2','k-count')); check_m_drift('m-drift-a2');"
```

The runtime resolves `eval_i21`, its numerical package dependencies, and
MATLAB `lsqminnorm` from the active MATLAB path. It does not read Git metadata,
documentation, hashes, manifests, historical results, or repository-relative
source files.

## Output contract

The formal attempt is append-only and writes exactly:

```text
output/m-drift-a2/result.mat
output/m-drift-a2/report.md
```

An existing attempt directory is rejected before computation. The intended
execution model is one MATLAB process and one attempt; there is no concurrent
same-tag writer and no automatic retry. A failure before the directory is
created may leave no artifact, in which case the MATLAB error is the record.

`result.mat` retains configuration and runtime resolution, per-level seed and
selector-gauge summaries, all evaluated locator nodes and singular spectra,
terminal winner/runner-up evidence, candidate diagnostics, common mode
representations, repeats, direct candidate drift, resource measurements, and
the first failure. `report.md` is the compact human-readable view.

## Formal result

The append-only `m-drift-a2` attempt completed and passed independent post-run
artifact review. All three levels saved the same terminal-grid candidate:

| $M$ | $K$ | saved candidate $k$ | search halfwidth | $s_1$ | $r_{12}$ |
|---:|---:|---:|---:|---:|---:|
| 32 | 65 | 1.832770289108157 | 9.3132279666e-11 | 5.6553661848e-11 | 1.1051178737e-10 |
| 40 | 81 | 1.832770289108157 | 9.3132279666e-11 | 5.6553210113e-11 | 1.1051090464e-10 |
| 48 | 97 | 1.832770289108157 | 9.3132279666e-11 | 5.6552568256e-11 | 1.1050965038e-10 |

The direct saved-candidate differences for $(32,40)$, $(40,48)$, and $(32,48)$
are all exactly zero. Both adjacent pairs are `SAME_MODE`: balanced-port,
weighted-wall, and nine-probe overlaps are one to floating-point roundoff, and
the largest primary--secondary competitor overlap is $2.489\times10^{-13}$.
Thus the machine outcome is `NO_OBSERVED_CANDIDATE_DRIFT`, and the conditional
algorithmic M-axis hierarchy is qualified.

Every locator node, factor, selector gauge, candidate, common-channel,
mode-identity, and fixed-candidate repeat gate passed. The largest raw backward
error was $7.804\times10^{-13}$ against $10^{-8}$; the largest stored SVD
triplet residual was $5.575\times10^{-16}$; the largest Dirichlet and Neumann
defects were $6.197\times10^{-17}$ and $1.609\times10^{-18}$. The narrowest
factor was the fixed proxy-reduced factor, with rcond $1.04817\times10^{-8}$
against the frozen $10^{-8}$ gate.

The run used 84 evaluator calls, 171.955614542 seconds, and a peak active-object
snapshot of 148.170555115 MiB, within the 600/1200-second and 512-MiB budgets.
The a2 retry count is zero. Its search halfwidth remains only a diagnostic for a
potential sub-grid score minimizer: it is not candidate uncertainty and is not
added to or compared with direct drift.

## Revision A and the consumed a1 attempt

`m-drift-a1` failed in configuration preflight before any evaluator call. Its
wall time was 22.177848167 seconds, exit code was 1, evaluator-call count was
zero, and no output directory or artifact was created. The terminal error was:

```text
Subscripted assignment between dissimilar structures.
```

The reported stack was `LOCAL_config` line 199 / `check_m_drift` line 32; the
error identifier was not recorded. Revision A only replaces the fieldless
struct initialization with a same-field 1-by-3 struct preallocation. The a1 tag
is consumed and is not retried; `m-drift-a2` is the sole formal run tag, with
its own `retry_count=0`. No scientific field, threshold, window, or algorithm
changed.

## Frozen scope and resources

- Sole axis: `PORT_RAYLEIGH_FOURIER_CUTOFF_M_AT_FIXED_NTOT160_FINE_PROXY`.
- Fixed boundary order: `ntot=160`.
- Fixed fine proxy tuple: `(N_side,N_top,N_proxy_edge,M_pw)=(160,160,80,32)`.
- Normal work: 81 unique locator points (including 3 seeds) plus 3 repeats,
  for 84 evaluator calls.
- Estimated wall time: 150--220 seconds; soft target 600 seconds.
- Hard acceptance gates: 1200 seconds and 512 MiB active-object snapshots.

The terminal halfwidth is only a search-resolution diagnostic. It is never
added to, or compared with, direct saved-candidate drift. No I2.1 contour count
attaches to these `ntot=160` levels. The experiment does not prove a sub-grid
minimizer, finite root, continuous-mode continuation, convergence order,
estimator, error attribution, or error bound.
