# I3.1 conforming weak residual

This directory implements the reviewed
[[research/projects/eig-apost/implementation/i3/design-3-1b|I3.1 Q1--RT0 design]].
It evaluates only the saved candidate

$$
\widehat k_h=1.832770289108157
$$

at the fine I2 object $n_{\mathrm{tot}}=256$, $M=48$. It does not scan or
refine $k$, locate a finite-dimensional root, or read any historical output.

## Frozen contract and formal run

- Attempt tag: `weak-a1`.
- Schema: `TEP_I3_1_Q1_RT0_WEAK_RESIDUAL_V2`.
- Entry point: `check_w_resid.m`.
- Scientific module: `i31_fe_cell.m`, which owns only the periodic-gauge Q1
  cell extension, true-circle material integration, RT0 flux reconstruction,
  and per-cell Gram matrices.
- Append-only output: `output/weak-a1/`, containing only `result.mat` and
  `report.md` from the completed formal run.
- Runtime dependencies: MATLAB, `eval_i21` and its numerical package
  dependencies on the normal MATLAB path. The code does not inspect Git,
  Markdown, manifests, hashes, repository layout, or old output.

The single frozen MATLAB command is:

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','w-resid'),fullfile(pwd,'test','i2','k-count')); check_w_resid('weak-a1');"
```

This command is documented for a repository-root launch; the numerical entry
itself resolves `eval_i21` by normal MATLAB function resolution and does not
search for a repository root.

The formal MATLAB run completed in 22.5326065 seconds with a peak active-object
estimate of 341.8422213 MiB and no retry. Its producer status is
`I3_1_MAJORANT_QUADRATURE_UNRESOLVED`; independent review accepts it as
`POST-RUN PASS / VALID NEGATIVE`. See
[[research/projects/eig-apost/implementation/i3/review-3-1c|post-run review]].

## Frozen numerical levels and gates

| Object | Coarse | Fine |
|---|---:|---:|
| Q1 mesh $(N_x,N_y)$ | $(64,128)$ | $(96,192)$ |
| Disk polar quadrature $(N_r,N_\theta)$ | $(32,128)$ | $(48,192)$ |

The shift is $\gamma=\mu_h=\widehat k_h^2$. The scaled physical Helmholtz
cell factor requires rcond at least $10^{-10}$ and solve residual at most
$10^{-10}$. Frozen-$P$ thin-QR rcond is at least $10^{-8}$ and its invariant
residual is at most $10^{-10}$. Field conformity and global RT0 normal
continuity defects are at most $10^{-12}$. Gram Hermitian and PSD tolerances
are $10^{-12}$, each full-matrix tail share is at most $10^{-6}$, and the
phase/scale defect under $10^8e^{\mathrm i\pi/7}$ is at most $10^{-11}$.

Coarse/fine changes in the two majorant components and field norm are at most
$0.20$. If both computed ratios are below one, the nominal interval-width
change must not exceed

$$
\max\{0.20w_f,0.10\tau_k^{\mathrm{pre}}\},
\qquad \tau_k^{\mathrm{pre}}=10^{-6}.
$$

The soft/hard times are $900/1800$ seconds, the active-object memory limit is
$512$ MiB, and the estimated run is 2--12 minutes with a 150--300 MiB peak.

## Result and conclusion boundary

The schema can record the finite input; $P_\pm$ diagnostics; shared wall
traces; Q1 factor and conformity diagnostics; RT0 normal-continuity defects;
small center/lead Gram matrices; full-$P$ doubling levels and tail shares;
coarse/fine and phase/scale checks; the computed majorant ratio; nominal
interval; resource data; and first-failure semantics. `weak-a1` retains only
the subset reached before its first failure. Dense Q1 solution maps and an
unfolded infinite-waveguide field are not written to `result.mat`.
For auditability it retains only center, first-cell, and one-step-tail wall
traces together with their boundary-flux values and the small tail boundary
flux maps.

The base coarse/fine finite-element and tail objects passed, but the fine
phase/scale repeat failed the per-cell Gram Hermitian gate. The largest recorded
Hermitian defect was $6.2442\times10^{-10}$ against the frozen $10^{-12}$
limit. The run therefore stopped before scaled tails, refinement, or a final
estimator were formed. The base $q$ values $0.1791563$ and $0.1520175$ and their
nominal interval widths $0.6675046$ and $0.5637788$ remain unqualified
diagnostics, not an estimator result.

Even after all internal gates pass, ordinary-double integration, linear
algebra and tail values can produce only a computed continuous weak-residual
estimator candidate, not a reliable enclosure. The following certification
states remain false or unestablished in this V2 experiment:

```text
residual_upper_bound_certified=false
field_lower_bound_certified=false
tail_diagnostic_certified=false
projected_gap_established=false
continuous_discrete_eigenvalue_existence=false
continuous_error_bound=false
```

No estimator, projected-gap existence interval, continuous eigenvalue, or
error upper bound is delivered. I3.1 remains active and I3.2 cannot start.
