# I6 symbol and variable ledger

## Version scope

The original ledger below applies to `test/i6/resolvent-v2/`
(formerly `test/i6/resolvent-nonfourier-v1/`) and design/review-6-1b.
It was moved here on 2026-09-20 without changing the historical MATLAB code.
Certification-specific names for `resolvent-v3` and design/review-6-1c are
listed separately below; v2 floating-point outputs do not become certified by migration.

This ledger maps the nontrivial names used by `resolvent_nonfourier_v1.m`,
the four signed-action helpers, and `run_with_limits.py`. The mathematical
sources are resolvent-bound T9--T10, F14 and N1--N9, and the locally recorded
direct-integration formulas NF1--NF6. The signed local, regular-image,
off-surface, and wall actions retain their I5.1g source conventions.

| Canonical code name | Kind and scope | Source object and meaning | Type, shape, units | Defined / consumed | Permitted alias |
|---|---|---|---|---|---|
| `z` | frozen input structure | Legacy I3 certificate for the exact-kernel raw field and full $G_\pm,P_\pm,c_\pm$ state; it is not the F14 auxiliary resolvent field $z=(A-\mu I)^{-1}u$, which is never solved | scalar structure | candidate MAT / all MATLAB sources | `certificate` in prose only |
| `curve_contract` | frozen input structure | I5 circle parameterization, density-coordinate, orientation, and wall-location contract | scalar structure | circle MAT / main validation | `contract` locally |
| `configuration`, `cfg` | run configuration | fixed $N=1026$, $a=0.2$, $Q=32$, $J=16$, wall cutoff 256, block length 32, and $\ell_*=d$ | scalar structure | main / helpers | `cfg` only as local argument |
| `density` | source-density structure | finite Fourier coefficients of $(\tau,\zeta)$ with $\zeta=-\sigma$; source expansion only, not a material jump expansion | orders $256\times1$, coefficients $256\times194$ | `LOCAL_density` / material helpers | none |
| `geometry_direct` | curve certificate | physical circle nodes, normals, arclength data, complex strip, clearances, and collar gates | scalar structure | `LOCAL_circle_geometry` / helpers | `geometry`, `g` locally |
| `mu` | physical scalar | $\mu=\widehat k^2$ in T9 and F14 | positive real, inverse length squared | frozen candidate / trace and F14 | none |
| `rho_min`, `rho_max` | material bounds | $\rho_-,\rho_+$ in T9 | positive real | frozen material / trace constant | none |
| `h`, `kappa_max`, `theta`, `overlap` | geometry scalars | common collar width, $\kappa_*=1/R$, $1-h\kappa_*$, and $N_{\rm ov}=1$ in T7--T9 | length; inverse length; real; integer | main / trace formula | none |
| `ell_ref` | paired-norm scalar | $\ell_*=d$ in T9--T10 | positive real, length | configuration / value-jump weight | none |
| `c0`, `c1` | trace coefficients | T7 coefficients | inverse length; length | main / T9 | none |
| `trace_constant` | output scalar | $\overline C=C_{\mathrm{tr},\ell_*}$ in T9 | nonnegative real, length$^{3/2}$ for dimensionless $\rho$ | T9 / `Q_bar` | `C_bar` in reports |
| `local`, `regular`, `off_surface` | material component certificates | I5.1g signed identity/local, exact-QP regular-image, and finite-Rayleigh actions evaluated at physical curve nodes | scalar structures | component helpers / `LOCAL_material` | none |
| `Cv`, `Cn` | signed physical rows | NF2 value row $C_a=C_L+C_R+C_O$ and ordinary-normal row $C_j=C_L-C_R-C_O$, combined before any norm | complex $1026\times194$ | `LOCAL_material` / NF4--NF6 | none |
| `continuous_node_radius` | local error certificate | NF1 continuous omitted entire-series action radius; governing local node radius | two nonnegative scalars | local helper / `rv`,`rn` | none |
| `radius` in local helper | inactive diagnostic | superseded p4-source plus discrete-series bridge radius | node vectors | local helper output only | none |
| `rv`, `rn` | complete node radii | NF3 local continuous radius plus regular-image source/Ewald radii and zero off-surface radius | nonnegative $1026\times1$ | `LOCAL_material` / NF4--NF6 | none |
| `Mv`, `Mn` | complex-strip action bounds | NF3 complete value and normal row upper bounds on $|\Im t|=a$ | nonnegative scalars | three material components / NF4--NF6 | `Mstrip` within one action |
| `ds` | arclength weight | $p_\Gamma/N$ in NF4 | positive real, length | geometry / direct quadrature | none |
| `target_remainder_factor` | analytic remainder coefficient | $e_N=2p_\Gamma/(\exp(aN)-1)$ in NF4 | positive real, length | main / finite and tail bounds | `remainder_factor` locally |
| `material_value`, `material_normal` | defect ledgers | direct continuous $L^2$ upper bounds for actual material value and ordinary-normal jumps | scalar structures | NF4--NF6 / T10 | none |
| `state_entries` | finite-interface ledger | per-side, per-cell signed-center, node-radius increment, and target-contour contributions | $2J$ structure array | `LOCAL_direct_sequence` / result MAT | none |
| `propagation` | block certificate | N7 full-matrix block norm, prefix norms, and infinite power-sum bound | structure per side | full $P_\pm$ / NF6 and walls | none |
| `G_upper` | state-map upper | $\|G_\pm\|_F$ used in NF5 | nonnegative real | tail operator / NF6 | none |
| `wall_value`, `wall_normal` | defect ledgers | actual paired artificial-wall value and ordinary-normal $L^2$ contributions | scalar structures | wall helper / T10 | none |
| `epsilon_boundary` | boundary defect | $\overline\varepsilon_{\partial,\ell_*}$ in T10 | field / square-root length | all interfaces / F14 | none |
| `mass`, `U_lower` | mass ledger and scalar | exact empty-center Rayleigh finite-region mass evaluation, N9 | structure; field times length | frozen `q_center` / F14 | none |
| `Q_bar`, `denominator` | F14 scalars | $\overline Q=\overline C\overline\varepsilon_\partial$ and $\underline U-\overline Q$ | field times length | main / finite-bound gate | none |
| `epsilon_volume` | volume defect | zero for the ideal exact-kernel raw construction | zero real | analytic raw-field contract / F14 | none |
| `spectral_distance_bound`, `spectral_interval` | final outputs | F14 $R_{\rm spec}$ and $[\mu-R_{\rm spec},\mu+R_{\rm spec}]$ | real scalar and $1\times2$ | main / MAT and JSON | `R_spec` in reports |
| `WALL_LIMIT_SECONDS`, `RSS_LIMIT_BYTES`, `SAMPLE_SECONDS` | launcher budgets | user hard run limits and process-tree RSS polling interval | seconds; bytes; seconds | launcher / resource record | none |

Obvious loop indices, file handles, paths, field-name lists, and single-use
printing temporaries are omitted. `lifting` remains an inherited internal name
inside the wall helper; that helper exports it as the actual value jump and no
old lift norm enters F14.


## V3 / I6.1c certification mapping

This section applies only to `test/i6/resolvent-v3/`, `design-6-1c.md`, and
`review-6-1c.md`. The original v2 ledger above retains its historical scope.
All real and complex scientific operations below use 192-bit Arb balls;
`upper` / `lower` mean directed, exact dyadic endpoints, not midpoint rounding.

| Code name | Mathematical object and exact meaning | Shape / role |
|---|---|---|
| `fields` | Explicit MATLAB binary64 payloads; real/imaginary components are exact dyadics | Named scalar/matrix input records |
| `khat`, `mu` | Exact stored $\widehat k$ and exact real product $\mu=\widehat k^2$ | Real singleton; shared by all kernels, constants and F14 |
| `mu_h` | Legacy rounded square; identity/offset diagnostic only | Never a physical-kernel or F14 input |
| `rho_exterior` | Explicit exact model constant $\rho_e=1$ | Input contract gate |
| `tau_coeff`, `zeta_coeff` | Mathematical DFT (C2) of exact frozen density samples, $\zeta=-\sigma$ | $256\times194$ complex balls, modes $-128{:}127$ |
| `NODE_COUNT`, `KERNEL_SERIES_CUTOFF` | Material curve nodes $N$ and retained local entire-series order $Q$ | Attempt scientific configuration |
| `PARAMETER_STRIP_WIDTH` | Exact algorithm strip width $a=1/5$ | Distinct from stored dyadic geometry $R$ |
| `material_value_center`, `material_normal_center` | Signed local/regular/off sums before the norm | $N\times194$ complex ball rows |
| `material_value_radius`, `material_normal_radius` | Continuous exact-minus-retained node radii | Include local series and regular source/Ewald tails |
| `material_value_strip`, `material_normal_strip` | Full exact-row analytic strip bounds $M_A$ | Before $G_\pm$; C6 uses $G$ and propagated state once each |
| `propagation[side]` | $r_\pm\ge\|P_\pm\|_F<1$, $K_\pm=1/(1-r_\pm^2)$ | Full $97\times97$ matrices; zero power has exact norm 1 |
| `cutoff` | First permitted $J$ satisfying the propagated-state energy target | Target is not the final action-tail bound |
| `plus_factor`, `minus_factor` | $K_\pm\|P_\pm^Jc_\pm\|_2^2$ | Retained-mode infinite-cell wall tail |
| `plus_full_factor`, `minus_full_factor` | $K_\pm\|c_\pm\|_2^2$ | Omitted wall modes for all cells starting at zero |
| `hc_left`, `hc_right` | Exact paired central-wall value mismatch, using stored $D_\pm c_\pm$ | Ordinary jump, never an old lift |
| `trace_upper`, `epsilon_upper`, `mass_lower` | Certified $\overline C$, $\overline\varepsilon_\partial$, $\underline U$ | C3, C6, C4 respectively |
| `Q_upper`, `denominator_lower` | $\operatorname{up}(\overline C\overline\varepsilon_\partial)$, $\operatorname{down}(\underline U-\overline Q)$ | Same exact raw field |
| `spectral_upper`, `interval_lower`, `interval_upper` | Directed F14 spectral-distance upper and outward spectral-parameter interval | Not a residual norm or discrete-eigenvalue label |
| `lower_dyadic`, `upper_dyadic` | Exact endpoints as integer mantissa times $2^{\text{exponent}}$ | Canonical machine-readable proof data |
| `*_decimal_exact` | Full finite decimal expansion of that exact dyadic | No fixed-precision truncation |

The density symbol $\eta$ is not reused for a defect. $\Lambda$ remains the DtN
operator; interface sums retain $\mathscr E$. The only inclusion is the single
simply connected $\Omega_0$; side labels on $G_\pm,P_\pm,c_\pm$ are propagation
sides, not disconnected inclusion components.


### V3 explicit inputs and signed wall aliases

| Canonical code name | Kind, shape, units | Mathematical meaning and source | Defined / consumed |
|---|---|---|---|
| `q_center` | exact acb column, $2K\times1$ | Empty-center left/right Rayleigh coefficients; C4 | exporter / mass and wall singleton |
| `Gplus`, `Gminus` | exact acb matrices, $2K\times K$ | Full lead state maps $G_\pm$ | exporter / all interface actions |
| `Pplus`, `Pminus` | exact acb matrices, $K\times K$ | Full propagation matrices $P_\pm$; C5 | exporter / finite states and tail |
| `cplus`, `cminus` | exact acb columns, $K\times1$ | Frozen stable lead coefficients $c_\pm$ | exporter / finite states and tail |
| `Dplus`, `Dminus` | exact acb matrices, $K\times K$ | Frozen near-center blocks used by wall singletons | exporter / wall certificate |
| `eta_unit_256` | exact acb matrix, $512\times2K$ | Samples of $(\tau,\zeta)$ with $\zeta=-\sigma$ | exporter / interval DFT |
| `xi_left_unit_512`, `xi_right_unit_512` | exact acb matrices, $512\times2K$ | Frozen finite Rayleigh maps | exporter / off-surface and walls |
| `wall_input_unit_512` | exact acb matrix, $1024\times2K$ | Shared wall Dirichlet selector | exporter / wall certificate |
| `inv_i_gamma` | acb vector, 513 retained wall modes | $1/(\mathrm{i}\gamma_m)$; wall value trace formula in C6 | wall certificate |
| `flat_value_multiplier` | acb vector, 513 retained wall modes | $\mathrm{i}/(2\gamma_m)=-\bigl(1/(\mathrm{i}\gamma_m)\bigr)/2$; flat wall value trace in C6 | wall certificate |
| `curve_value_multiplier` | acb vector, 513 retained wall modes | $1/(\mathrm{i}\gamma_m)$; curved-layer wall value trace in C6 | wall certificate |
| `VL`, `VR` | acb matrices, $513\times2K$ | Left/right signed value-jump row maps after flat and curve trace subtraction; C6 | wall singleton, finite sequence, and tail |
