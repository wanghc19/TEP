# Frozen design: proxy placement and parameter rule

## Error decomposition

The experiment separates three effects.

1. **Approximation error.** Proxy sources and the internal top/bottom
   Rayleigh basis must span the analytic continuation of the correction.
   Source curves must remain before the nearest continuation singularities.
   Proxy-edge coefficient tails and internal plane-wave tails diagnose this
   part.
2. **Collocation error.** The six matched boundary conditions may look small
   only at their training nodes. Therefore every level is also evaluated on
   midpoint-shifted side and top/bottom grids. `Nside` and `Ntop` control this
   part; the equation-to-unknown ratio is recorded rather than treated as a
   theorem.
3. **Solver/rank error.** The public MATLAB path remains `lsqminnorm`. The
   singular spectrum, numerical rank, coefficient norm, and raw residual are
   recorded, but no alternate solver or post-selected cutoff is allowed to
   replace package output.

## Theory-to-code map

- `proxy_dist` is the distance from the fundamental-cell boundary to the
  proxy rectangle. For period $d=1$, nearest excluded copies of the primary
  source produce continuation singularities at computational $x=\pm 1$.
  The sole candidate `proxy_dist=0.2` leaves the proxy edge at
  $|x|=0.7<1$.
- `H` is the half-height of the computational non-periodic near region. The
  largest wall/source separation needed here is $0.7$, while `H=1.1`; hence
  every wall pair stays in the primary-plus-proxy branch with margin $0.4$.
- `Nedge` resolves the proxy density, `Nside/Ntop` resolve the six
  collocation conditions, and `Mpw` resolves only the internal outgoing
  representation above and below the box.
- `M_trace` resolves the physical wall Fourier action. The separate band
  $24<|m|\leq48$ screens the current value and is never inferred from `Mpw`.
  This experiment does not by itself certify `M_trace`, because it does not
  bound the omitted infinite tail or repeat a wall-field reconstruction at a
  larger output bandwidth.

## Parameter-selection algorithm

1. Locate the nearest physical or periodic-image continuation singularities.
   Reject any proxy curve crossing them. Choose one conservative interior
   source distance before inspecting target errors.
2. Choose `H` above the largest source-to-target non-periodic separation.
   Check its margin and Wood distance as metadata; near-Wood cases require a
   separate experiment.
3. Start near an equation-to-unknown ratio of two, then require both training
   and shifted hold-out residuals. The ratio alone is not an accuracy claim.
4. Increase `Nedge` until proxy coefficient tails and physical wall actions
   stabilize. Increase `Nside` and `Ntop` separately only after the `Nedge`
   gate. Increase `Mpw` only from its own coefficient tail and action change.
5. Record the singular spectrum, numerical rank, and coefficient norm at each
   level. If coefficients grow while residuals fall, classify the source
   placement or rank policy as unresolved; do not tune a cutoff against Ewald.
6. Certify `M_trace` later from a dedicated physical output-tail and wall-field
   reconstruction study. This experiment only screens its current frozen
   value.

The package rectangular proxy list repeats the lower-left corner as its first
and last source and omits the upper-right corner. Thus the copied collocation
matrix has an exact duplicate proxy column. The diagnostic records
$|q_1-q_N|$, $|q_1+q_N|$, and the zero first-to-last source distance. Edgewise
Fourier tails remain non-gating diagnostics because the endpoint defect makes
their literal interpretation basis-dependent. No source is removed and the
public package solve is left unchanged.

## Primary literature boundary

- Barnett and Betcke (2008), DOI
  [10.1016/j.jcp.2008.04.008](https://doi.org/10.1016/j.jcp.2008.04.008),
  relate MFS convergence and coefficient growth to the nearest analytic-
  continuation singularity. Their rigorous placement result is for analytic
  disks, so its use for this rectangular quasi-periodic proxy system is a
  source-placement heuristic, not a theorem for the package.
- Cho and Barnett (2015), DOI
  [10.1364/OE.23.001775](https://doi.org/10.1364/OE.23.001775), choose periodic
  proxy sources relative to omitted-copy singularities and warn against source
  curves that force large coefficients. Their circular combined-field proxy
  differs from the package rectangular monopole construction.
- Barnett and Greengard (2010), DOI
  [10.1016/j.jcp.2010.05.029](https://doi.org/10.1016/j.jcp.2010.05.029), use
  an overdetermined extended system for periodic auxiliary-source matching.
- Adcock and Huybrechs (2020), DOI
  [10.1007/s00041-020-09796-w](https://doi.org/10.1007/s00041-020-09796-w), and
  Huybrechs and Olteanu (2019), DOI
  [10.1016/j.wavemoti.2018.06.001](https://doi.org/10.1016/j.wavemoti.2018.06.001),
  support oversampled collocation and regularized small-norm solves only when
  the auxiliary basis and sampling are resolved. They do not supply a
  universal oversampling ratio or project-specific rank cutoff.

## Preregistered gates and stopping

- Gx point error against the frozen Ewald value: `2e-9`.
- Base Ewald/package/Rayleigh wall coefficient error: `1e-8`.
- Base-to-each-axis package wall coefficient change: `2e-9`.
- Physical output tail $24<|m|\leq48$: `2e-9`.

The pilot must pass before a wall matrix is built. Full mode checks base,
then `Nedge`, `Nside`, `Ntop`, and `Mpw`. The first failure stops all later
levels; no joint refinement or alternate `proxy_dist` is permitted.

## Predicted sensitivity

SLP-D uses $G$ itself, whose high-frequency evanescent content is strongly
damped. SLP-N uses the wall-normal derivative $G_x$; differentiation amplifies
high spatial frequencies and cancellation in a nearly dependent proxy basis.
Thus an overextended proxy curve can leave SLP-D apparently stable while
SLP-N responds first to `Nedge`, `Nside`, and `Ntop`. The earlier passing
`Mpw` refinement makes internal far-field truncation a less likely primary
cause for the observed failure.
