# I6 resolvent-v1 symbol and variable ledger

This ledger maps the nontrivial numerical names used by
`resolvent_bound_v1.m`, `signed_wall_l2_v1.m`, and `run_with_limits.py`.
The mathematical sources are the frozen resolvent-bound theory T9--T10,
F14, and N1--N9, together with the I5 paired signed-row formulas.

| Canonical code name | Kind and scope | Source object and meaning | Type, shape, units | Defined / consumed | Alias |
|---|---|---|---|---|---|
| `z` | frozen input structure | Legacy I3 certificate containing the exact-kernel raw field, candidate, geometry, and full $P_\pm,G_\pm,c_\pm$; it is not the auxiliary resolvent field $z=(A-\mu I)^{-1}u$ in F14, which this experiment never solves | scalar structure | candidate MAT / evaluator and wall helper | `certificate` only in explanatory text |
| `i5v7` | frozen input structure | I5 signed physical material rows, radii, geometry, and density contract | scalar structure | v7 MAT / evaluator | `v7` in local helpers |
| `configuration` | run configuration | fixed $J=16$, material cutoff 1024, wall cutoff 256, block length 32, and $\ell_*=d$ | scalar structure | evaluator / all assemblies | `cfg` locally |
| `mu` | physical scalar | $\mu=\widehat k^2$ in T9 and F14 | positive real, inverse length squared | frozen candidate / trace and F14 | none |
| `rho_min`, `rho_max` | material bounds | $\rho_-,\rho_+$ in T9 | positive reals | frozen exterior/inclusion densities / trace constant | none |
| `h` | geometry scalar | common two-sided collar half-width in T7--T9 | positive real, length | frozen `delta_c`, `delta_w` / trace constant | none |
| `kappa_max` | geometry scalar | $\kappa_*=1/R$ | positive real, inverse length | inclusion radius / `theta` | none |
| `theta` | geometry scalar | $1-h\kappa_*$ in T7 | positive real | geometry / trace constant | none |
| `overlap` | geometry integer | $N_{\mathrm{ov}}=1$ from disjoint collar gates | positive integer | geometry audit / `c0`, `c1` | none |
| `ell_ref` | paired-norm scalar | reference length $\ell_*=d$ in T9--T10 | positive real, length | configuration / value-jump weight | none |
| `c0`, `c1` | derived geometry scalars | T7 coefficients | inverse length; length | geometry / T9 | none |
| `trace_constant` | output scalar | $\overline C=C_{\mathrm{tr},\ell_*}$ in T9 | nonnegative real, length$^{3/2}$ for dimensionless $\rho$ | T9 formula / `Q_bar` | `C_bar` in reports |
| `Cv`, `Cn` | material row maps | signed physical value and ordinary-normal Fourier rows | complex $2047\times194$ | v7 physical centers / material finite and cell tail | none |
| `rv`, `rn` | material row radii | per-mode evaluation radii paired with `Cv`, `Cn` | nonnegative real $2047\times1$ | v7 analytic radii / material bounds | none |
| `G`, `P`, `state` | per-side propagation data | $G_\varsigma$, full $P_\varsigma$, and $P_\varsigma^n c_\varsigma$ in N6--N8 | complex matrices/vectors, dimension 97 or 194 | frozen candidate / lead sums | side-qualified outside helper |
| `propagation` | block certificate | N7 block norm, prefix power norms, and $K_\varsigma$ | scalar structure per side | full matrices / every infinite cell tail | none |
| `material_value`, `material_normal` | defect ledgers | squared $L^2$ contributions of actual lead material interfaces | scalar structures | signed rows / T10 | none |
| `wall_value`, `wall_normal` | defect ledgers | squared $L^2$ contributions of actual paired walls | scalar structures | wall helper / T10 | none |
| `epsilon_boundary` | defect scalar | $\overline\varepsilon_{\partial,\ell_*}$ in T10 | nonnegative real, field / square-root length | all interface ledgers / F14 | none |
| `mass` | mass ledger | analytic empty-center Rayleigh mass and quadrature diagnostic | scalar structure plus 97-vector | frozen `q_center` / denominator | none |
| `U_lower` | mass scalar | finite safe-region raw $\mathcal H$ mass evaluation, N9 | nonnegative real, field times length | center mass / F14 | none |
| `Q_bar` | combined defect | $\overline Q=\overline C\,\overline\varepsilon_\partial$ in F14 | nonnegative real, field times length | trace/defect / denominator | none |
| `denominator` | F14 scalar | $\underline U-\overline Q$ | real | mass and defect / finite-bound gate | none |
| `epsilon_volume` | defect scalar | $\overline\varepsilon_{\mathrm{vol}}=0$ for the ideal exact-kernel raw field | zero real | exact PDE/QP contract / F14 | none |
| `spectral_distance_bound` | result scalar | F14 upper-estimate value $R_{\mathrm{spec}}$ | nonnegative real or `Inf`, inverse length squared | F14 / result | `R_spec` in reports |
| `spectral_interval` | result vector | $[\mu-R_{\mathrm{spec}},\mu+R_{\mathrm{spec}}]$ | real $1\times2$ | result / report | none |
| `WALL_LIMIT_SECONDS` | launcher budget | user hard limit for one complete run | integer seconds | launcher / watchdog | none |
| `RSS_LIMIT_BYTES` | launcher budget | user process-tree sampled RSS limit | integer bytes | launcher / watchdog | none |
| `SAMPLE_SECONDS` | launcher budget | process-tree RSS polling interval | positive seconds | launcher / resource record | none |

Obvious loop indices, file handles, path strings, temporary field-name cells,
and one-use JSON/printing temporaries are omitted. Internal variable `lifting`
inside the wall helper is a retained implementation name from its I5 source;
the helper exports it only as `out.value`, and no lift norm enters the result.
