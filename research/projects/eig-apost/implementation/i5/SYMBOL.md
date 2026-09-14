# I5 continuous residual numerator symbol ledger

This ledger is local to the I5 continuous residual numerator work.  Its
mathematical authorities are
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-wall-tail]],
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail]],
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-local-panel]],
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-kress-real]],
and [[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail]].
The earlier implemented entries describe the wall experiments.  The final
section records the later `test/i5/residual-numerator-a1` implementation and
supersedes the word “future” in its two precursor tables only for that
experiment.  Similar names in older I3 experiments are not aliases unless the
table says so.

## Authority and one-time scope

- The project-root
  [[research/projects/eig-apost/implementation/SYMBOL]] supplies only defaults
  not redefined in this file.
- This local ledger applies only to `implementation/i5/` and `test/i5/`.
- A local override changes symbols or aliases only.  It does not change the
  mathematical model, frozen artifact fields, MAT schema, public function
  interface, or any I1--I4 file.
- The Chinese draft PDF was consulted once on 2026-09-06 as a text-only
  notation snapshot.  It is not linked and is neither an authority nor a
  runtime dependency.

## Governing I5 notation

| theory symbol | meaning | code or artifact boundary |
|---|---|---|
| $\eta=(\tau,-\sigma)^{\mathsf T}$ | frozen double- and single-layer density coordinate | artifact stem `eta`; a stored `zeta` means only the second coordinate $-\sigma$ |
| $N_\eta$ | original parameter-node count of the frozen density | `source_node_count`; for `eta_unit_256`, $N_\eta=256$ |
| $M_\eta$ | largest absolute Fourier degree present in $\eta$ | derived from `density.orders`; it is not an evaluation cutoff |
| $L$ | residual Fourier cutoff, retaining $|\ell|<L$ | a zero-based code cutoff equals $L-1$ |
| $N$ | even Kress and target-DFT evaluation node count | `configuration.evaluation_node_count` in v1; legacy `configuration.boundary_node_count` only in the historical unversioned experiment |

Every governing retained-row evaluation requires
$N>2\max\{L,M_\eta\}$.  The symbols $N_{\mathrm{ser}},N_E,N_R,N_I$ denote
explicitly subscripted kernel/Ewald cutoffs and never the evaluation node count $N$.
The material coefficient alone is denoted by $\rho$; ratio-test constants use
$r$ and the dimensionless Ewald parameter is $\chi_E$.

The theoretical bare Kress factors and unchanged MATLAB outputs are mapped as
follows.  This table changes no API, function signature, structure field, or
historical code variable.

| theoretical factor | role | unchanged MATLAB source/output |
|---|---|---|
| $S_{\kappa,1},S_{\kappa,2}$ | single-layer logarithmic and regular factors | `+kernel/kress_mn_splits.m`: `M1`, `M2` |
| $D_{\kappa,1},D_{\kappa,2}$ | source-normal double-layer factors | `+kernel/kress_l_splits.m`: `L1`, `L2` |
| $D_{\kappa,1}^*,D_{\kappa,2}^*$ | target-normal adjoint factors | `+kernel/kress_l_splits.m`: `Ls1`, `Ls2` |
| $C_{\kappa,1}^{\mathrm{tan}},C_{\kappa,2}^{\mathrm{tan}}$ | Maue tangential auxiliary factors | `+kernel/kress_mn_splits.m`: `N1`, `N2` |
| $K_j^{T_e-T_i}$ | complete Maue-regularized split of $T_e-T_i$ | local code variable `Tdiff`; the normal residual applies $T_i-T_e=-(T_e-T_i)$ |
| $K_j^{\mathrm{val}},K_j^{\mathrm{nor}}$ | complete density- and Jacobian-inclusive defect integrands in $K=K_1g+K_2$ | assembled value and normal Kress rows; no API alias is introduced |

The common cotangent term is cancelled algebraically between exterior and
interior contributions while forming $K_j^{T_e-T_i}$, before either absolute
values or the normal-residual minus sign are applied.

## Runtime interface and frozen fields

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `artifact_path` | function input | path of the frozen finite-data bundle; theory-to-data map | character vector or scalar string | caller / entry | none |
| `output_path` | function input | destination of the ordinary evaluation record | character vector or scalar string | caller / entry | none |
| `loaded` | local structure | loaded MAT container, not a mathematical object | scalar structure | entry / entry | none |
| `staged` | local structure | staged frozen bundle | scalar structure | `loaded.staged` / entry | none |
| `z` | local structure | frozen certificate namespace | scalar structure | `staged.certificate` / all stages | `certificate` in I3 only |
| `raw_maps` | local structure | ordinary I3 maps used only for orientation cross-checks | scalar structure | `staged.raw_maps` / audit | none |
| `k_outer` | local scalar | $\widehat k$; theory-to-data map | positive real scalar, inverse length | `z.khat` / branch and kernels | `khat` in artifact |
| `mu_shift` | local scalar | $\mu=\widehat k^2$ in the shifted energy norm | positive real scalar, inverse length squared | artifact fields `z.gamma`, `z.mu_h` / wall weights | artifact aliases `gamma`, `mu_h`; never `gamma_m` |
| `beta_bloch` | local scalar | $\beta$ | real scalar, inverse length | `z.beta` / modal orders | `beta` in artifact |
| `period_y` | local scalar | $d$ | positive real scalar, length | `z.d` / modal orders and normalization | `d` in artifact |
| `circle_radius` | local scalar | $R$ | positive real scalar, length | `z.R` / density normalization and kernels | `R` in artifact |
| `wall_left_x` | local scalar | $X_L$ | real scalar, length | `z.X_L` / left kernel | none |
| `wall_right_x` | local scalar | $X_R$ | real scalar, length | `z.X_R` / right kernel | none |
| `cell_width` | local scalar | $d_x=X_R-X_L$ | positive real scalar, length | `z.L` / center Rayleigh derivative | artifact field `L` only at the input boundary |
| `circle_center_x` | fixed local scalar | $c_x=0$ in the frozen geometry | real scalar, length | configuration / distance and strip bound | none |
| `circle_center_y` | fixed local scalar | $c_y=0$ in the frozen geometry | real scalar, length | configuration / kernel coordinates | none |
| `eta_native` | frozen matrix | nodal map $q\mapsto\eta=(\tau,-\sigma)^{\mathsf T}$ | complex $(2N_\eta)\times194$; here $N_\eta=256$ | `z.eta_unit_256` / density FFT | none |
| `xi_left_coeff` | frozen matrix | left flat-wall single-layer density coefficients | complex $512\times194$ | `z.xi_left_unit_512` / flat-wall flux | none |
| `xi_right_coeff` | frozen matrix | right flat-wall single-layer density coefficients | complex $512\times194$ | `z.xi_right_unit_512` / flat-wall flux | none |
| `q_center` | frozen vector | center-cell Rayleigh state $q^{\rm cen}$ | complex $194\times1$ | `z.q_center` / singleton derivative | none |
| `D_plus`, `D_minus` | frozen matrices | selected subspace coordinate matrices $D_\pm$ | complex $97\times97$ | `z.Dplus`, `z.Dminus` / state audit | `Dplus`, `Dminus` in artifact |
| `G_plus`, `G_minus` | frozen matrices | density-state maps $G_\pm$ | complex $194\times97$ | `z.Gplus`, `z.Gminus` / all wall rows | `Gplus`, `Gminus` in artifact |
| `P_plus`, `P_minus` | frozen matrices | complete propagation matrices $P_\pm$ | complex $97\times97$ | `z.Pplus`, `z.Pminus` / row indexing and block certificate | `Pplus`, `Pminus` in artifact |
| `c_plus`, `c_minus` | frozen vectors | starting coordinates $c_\pm$ | complex $97\times1$ | `z.cplus`, `z.cminus` / finite and tail sums | `cplus`, `cminus` in artifact |

## Fixed evaluation configuration

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `mode_cutoff` | fixed scalar | retained wall order $M$ | integer scalar | entry config / all modal stages | `M` only in equations |
| `cell_cutoff` | fixed scalar | finite cell cutoff $J$ | integer scalar | entry config / finite sum | `J` only in equations |
| `block_length` | fixed scalar | block-power length $J_\varsigma^{\rm blk}$ | integer scalar | entry config / block certificate | none |
| `strip_width` | fixed scalar | analytic strip half-width $a$ | positive real scalar | entry config / trapezoid remainder | `a` only in equations |
| `quadrature_nodes` | fixed scalar | periodic trapezoid node count $N_q$ | positive even integer | entry config / circle coefficient rows | `N_q` only in equations |
| `roundoff_label` | fixed text | mandated claim qualifier | character vector | entry / result | exact value `NON_CERTIFIED_ROUNDOFF_EXCLUDED` |

## Density and modal coordinates

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `density_orders` | derived vector | native density orders $\ell=-128{:}127$ | integer $256\times1$ | density FFT / density evaluation | `ell` inside the FFT helper |
| `tau_coeff_map` | derived matrix | ordinary Fourier coefficient map $\widehat T_\tau$ | complex $256\times194$ | no-phase FFT / rows and constants | none |
| `single_layer_density_coeff_map` | derived matrix | ordinary Fourier map of the stored second coordinate $-\sigma$ | complex $256\times194$ | no-phase FFT / rows and constants | artifact alias `zeta` only at the input boundary |
| `tau_normalized_map` | derived matrix | $T_\tau=\sqrt{2\pi R}\widehat T_\tau$ | complex $256\times194$, square-root length | density normalization / $A$ constants | none |
| `single_layer_density_normalized_map` | derived matrix | $T_\sigma$; the sign of the stored $-\sigma$ coordinate is immaterial in its norm | complex $256\times194$, square-root length | density normalization / $A$ constants | none |
| `wall_orders` | derived vector | $m=-M{:}M$ | integer $(2M+1)\times1$ | modal setup / all row arrays | none |
| `transverse_wavenumber` | derived vector | $\beta_m=\beta+2\pi m/d$ | real $(2M+1)\times1$, inverse length | modal setup / branch, kernels, weights | artifact alias `beta_m` |
| `branch_radicand` | derived vector | $t_m=\widehat k^2-\beta_m^2$ | real $(2M+1)\times1$, inverse length squared | branch audit / `rayleigh_wavenumber` | `t_m` only in equations |
| `rayleigh_wavenumber` | derived vector | outgoing/decaying $\gamma_m$ | complex $(2M+1)\times1$, inverse length | branch helper / kernels and center derivative | artifact alias `gamma_m`; never `mu_shift` |
| `lambda_modes` | derived vector | $\lambda_m=\sqrt{\beta_m^2+\mu}$ | positive real $(2M+1)\times1$, inverse length | wall weight / `wall_weights` | none |
| `wall_weights` | derived vector | $\omega_m=2\lambda_m\tanh(h_{\rm tr}\lambda_m)$, with $h_{\rm tr}=1/2$ | positive real $(2M+1)\times1$, inverse length | wall trace lemma / $F,T$ assembly | none |
| `positive_distance` | derived scalar | $\delta=\operatorname{dist}(\Upsilon,\Gamma_-\cup\Gamma_+)$ | positive real scalar, length | geometry audit / high-mode constant | none |

## Coefficient rows and evaluation remainders

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `circle_flux_left` | derived matrix | trapezoidal approximation of the inclusion part of $Q_L$ | complex $(2M+1)\times194$ | exact Rayleigh integrand / total $Q_L$ | none |
| `circle_flux_right` | derived matrix | trapezoidal approximation of the inclusion part of $Q_R$ | complex $(2M+1)\times194$ | exact Rayleigh integrand / total $Q_R$ | none |
| `circle_row_error` | derived vector | explicit strip remainder for either circle-to-wall row | nonnegative real $(2M+1)\times1$ | strip formula / row enclosures | none |
| `flat_flux_left` | derived matrix | $\frac12(\xi_L-E\xi_R)$ | complex $(2M+1)\times194$ | finite modal algebra / total $Q_L$ | none |
| `flat_flux_right` | derived matrix | $\frac12(-E\xi_L+\xi_R)$ | complex $(2M+1)\times194$ | finite modal algebra / total $Q_R$ | none |
| `Q_left_tilde`, `Q_right_tilde` | derived matrices | finite approximations $\widetilde Q_L,\widetilde Q_R$ | complex $(2M+1)\times194$ | flat plus circle rows / internal and singleton rows | none |
| `ell_plus_tilde` | derived matrix | $\widetilde\ell_{+,m}=\widetilde Q_{R,m}G_++\widetilde Q_{L,m}G_+P_+$ | complex $(2M+1)\times97$ | row assembly / finite sum and $\overline\omega$ | none |
| `ell_minus_tilde` | derived matrix | $\widetilde\ell_{-,m}=\widetilde Q_{L,m}G_-+\widetilde Q_{R,m}G_-P_-$ | complex $(2M+1)\times97$ | row assembly / finite sum and $\overline\omega$ | none |
| `ell_plus_error`, `ell_minus_error` | derived vectors | $\epsilon_{\pm,m}$ from the two circle-row remainders | nonnegative real $(2M+1)\times1$ | operator-norm propagation / finite and tail assembly | none |
| `center_dx_left`, `center_dx_right` | derived vectors | finite center Rayleigh derivatives $\partial_xu^{\rm cen}$ | complex $(2M+1)\times1$ | frozen branch and `q_center` / singleton rows | `dxL`, `dxR` only in source formula comments |
| `singleton_plus_tilde` | derived vector | right center/first coefficient $\widetilde j^{\rm cf}_{+,m}$ | complex $(2M+1)\times1$ | center derivative plus $Q_LG_+c_+$ / finite sum | none |
| `singleton_minus_tilde` | derived vector | left center/first coefficient $\widetilde j^{\rm cf}_{-,m}$ | complex $(2M+1)\times1$ | minus center derivative plus $Q_RG_-c_-$ / finite sum | none |
| `singleton_plus_error`, `singleton_minus_error` | derived vectors | $\epsilon_{\pm,0,m}$ | nonnegative real $(2M+1)\times1$ | circle-row remainder / finite sum | none |

## Propagation and high-mode constants

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `power_norms` | block-certificate field | ordinary values $\|P_\varsigma^r\|_2$, $0\le r<J_\varsigma^{\rm blk}$ | nonnegative real $J_\varsigma^{\rm blk}\times1$ | block helper / `propagation_constant` | $\overline p_{\varsigma,r}$ only after outward verification |
| `block_norm` | block-certificate field | ordinary value $\|P_\varsigma^{J_\varsigma^{\rm blk}}\|_2$ | nonnegative real scalar | block helper / contraction gate | $\overline a_\varsigma$ only after outward verification |
| `propagation_constant` | block-certificate field | $K_\varsigma=\sum_r\overline p_{\varsigma,r}^2/(1-\overline a_\varsigma^2)$ | positive real scalar | block helper / $T$ assembly | $K_\varsigma$ only in equations |
| `A_tau_plus`, `A_tau_minus` | density-bound scalars | $A_{\tau,\varsigma}$ | nonnegative real scalars | normalized density maps / high-mode $\mathcal C_\varsigma$ | none |
| `A_single_layer_density_plus`, `A_single_layer_density_minus` | density-bound scalars | $A_{\sigma,\varsigma}$ for side $\varsigma\in\{-,+\}$; norms use the stored $-\sigma$ coordinates | nonnegative real scalars | normalized density maps / high-mode $\mathcal C_\varsigma$ | none |
| `A_tau_plus_singleton`, `A_tau_minus_singleton` | density-bound scalars | executable upper bounds for $A_{\tau,\varsigma,0}$ | nonnegative real scalars | first-cell density vectors / high-mode $\mathcal C_{\varsigma,0}$ | none |
| `A_single_layer_density_plus_singleton`, `A_single_layer_density_minus_singleton` | density-bound scalars | executable upper bounds for $A_{\sigma,\varsigma,0}$ | nonnegative real scalars | first-cell density vectors / high-mode $\mathcal C_{\varsigma,0}$ | none |
| `C_plus_squared`, `C_minus_squared` | tail scalars | $\mathcal C_\varsigma(M)^2$ | nonnegative real scalars | explicit geometric sum / $T$ assembly | none |
| `C_plus_singleton_squared`, `C_minus_singleton_squared` | tail scalars | $\mathcal C_{\varsigma,0}(M)^2$ | nonnegative real scalars | explicit geometric sum / $T$ assembly | none |
| `omega_plus`, `omega_minus` | finite Gram bounds | $\overline\omega_{\varsigma,M}$ | nonnegative real scalars | finite row norms and errors / $T$ assembly | none |

## Result and audit fields

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `finite_squared` | result scalar | $\overline F_{M,J}^2$ for $B_{\Gamma_\pm}$ | nonnegative real scalar | finite assembler / result | none |
| `tail_squared` | result scalar | $T_{M,J}^2$ | nonnegative real scalar | tail assembler / result | none |
| `quadratic_bound` | result scalar | $\sqrt{\overline F_{M,J}^2+T_{M,J}^2}$ | nonnegative real scalar | result assembly / output | none |
| `triangle_bound` | result scalar | $\overline F_{M,J}+T_{M,J}$ | nonnegative real scalar | result assembly / output | none |
| `branch_audit` | result structure | retained non-Wood, outgoing sign, and omitted-evanescent gate | scalar structure | branch helper / result | none |
| `density_audit` | result structure | no-midpoint-phase FFT, Parseval, and stored $-\sigma$ contract | scalar structure | density helper / result | none |
| `side_index_audit` | result structure | $G_\pm$, $J_\pm$, singleton sign and index checks | scalar structure | audit helper / result | none |
| `propagation_plus`, `propagation_minus` | result structures | ordinary block-power records for $P_\pm$ | scalar structures | block helper / result and tail | none |
| `coefficient_enclosures` | result structure | persisted $(\widetilde\ell,\epsilon)$ and singleton enclosures for every $|m|\le M$ | scalar structure containing $(2M+1)$-row arrays | row assembly / result | none |
| `theorem_gate` | result structure | ordinary-bundle completion and unclosed outward-rounding status | scalar structure | result assembly / output | none |
| `roundoff_excluded` | result logical | finite arithmetic has no outward rounding enclosure | logical scalar | entry / output | must remain `true` |
| `reliability_certified` | result logical | whether the reported floating-point number is a certified upper bound | logical scalar | entry / output | must remain `false` in this experiment |

Obvious loop indices, field-name iterators, temporary array-size values, and
throwaway formatting variables are intentionally omitted.  No code variable
may use bare `gamma` for both `mu_shift` and `rayleigh_wavenumber`.  The code
name `single_layer_density_sigma` always means the stored second coordinate
$-\sigma$; `wall_side_sign` is the geometric side sign and is never named
`sigma`.

## Shape-general curve-contract extension

This section is local to `test/i5/wall-curve-a1/`.  It extends, rather than
renames, the circle-special entries above.  The frozen I3 MAT schema is not
changed.

| canonical code name | kind and scope | mathematical object and source | type, shape, units | defined / consumed | permitted alias |
|---|---|---|---|---|---|
| `curve_contract_path` | function input | explicit path of the data-only parameter-curve contract | character vector or scalar string | caller / builder and general evaluator | none |
| `curve_contract` | persisted structure | finite geometry data and explicit real/complex-strip bounds required by the shape-general wall theorem | scalar structure | `build_circle_contract_a1` / `wall_tail_curve_a1` | `contract` only as a local helper argument |
| `parameter_period` | contract scalar | period $2\pi$ of the curve parameter $t$ | positive real scalar | curve contract / quadrature and density reconstruction | none |
| `source_node_count` | contract scalar | number $N_\eta$ of parameter nodes associated with the frozen density | positive even integer | curve contract / density split and alignment audit | none |
| `quadrature_node_count` | contract scalar | finite curve-row quadrature size $N_q$ | positive even integer | curve contract / general curve evaluation | `quadrature_nodes` in the circle-special evaluator |
| `source_contour` | contract matrix | source-node values of $(x,x',x'',y,y',y'')$ | real $6\times N_\eta$ | `geom.construct_cont` through the circle adapter / alignment audit | `C` only at the package boundary |
| `evaluation_contour` | contract matrix | evaluation-node values of $(x,x',x'',y,y',y'')$ | real $6\times N_q$ | `geom.construct_cont` through the circle adapter / general finite rows | `C` only at the package boundary |
| `x`, `y` | derived vectors | curve position $r(t)=(x(t),y(t))$ | real $N_q\times1$, length | `evaluation_contour` / Rayleigh phase and clearance audit | none |
| `dx_dt`, `dy_dt` | derived vectors | parameter tangent $r'(t)$ | real $N_q\times1$, length per parameter | `evaluation_contour` / double-layer measure and normal audit | none |
| `speed` | derived vector | $v(t)=|r'(t)|$ | positive real $N_q\times1$, length per parameter | tangent / single-layer measure and audit | none |
| `normal_x`, `normal_y` | derived vectors | CCW outward normal $\nu=(y',-x')/v$ | real $N_q\times1$ | tangent and speed / orientation audit only | none |
| `real_certificate` | contract structure | real-axis bounds $v_{\max}$ and $\delta_\pm$ | scalar structure of positive reals | geometry adapter / high-mode tail | none |
| `strip_certificate` | contract structure | chosen $a$, $I_x,I_y,V_x,V_y,V_s$, and $\delta_{\pm,a}$ | scalar structure of positive reals and analytic gates | geometry adapter / trapezoid remainder | none |
| `imag_x_upper`, `imag_y_upper` | strip fields | $I_x(a),I_y(a)$, bounds for $|\operatorname{Im}x(z)|,|\operatorname{Im}y(z)|$ | nonnegative real scalars, length | strip certificate / phase bound | none |
| `tangent_x_upper`, `tangent_y_upper` | strip fields | $V_x(a),V_y(a)$, bounds for $|x'(z)|,|y'(z)|$ | positive real scalars | strip certificate / source-normal derivative bound | none |
| `speed_upper` | real/strip field | $v_{\max}$ on the real axis or $V_s(a)$ in the strip, according to containing structure | positive real scalar | geometry adapter / $L^1$ or strip bound | no cross-structure alias |
| `left_clearance_lower`, `right_clearance_lower` | real/strip fields | $\delta_-,\delta_+$ or $\delta_{-,a},\delta_{+,a}$, according to containing structure | positive real scalars, length | geometry adapter / high-mode or strip phase bound | none |
| `curve_flux_left`, `curve_flux_right` | derived matrices | shape-general finite curve contributions to $Q_L,Q_R$ | complex $(2M+1)\times194$ | parameterized-curve row formula / wall rows | circle-special aliases `circle_flux_left`, `circle_flux_right` only in `wall-tail-a1` |
| `derivative_measure` | local matrix | $\mathrm i(\varsigma\gamma_m y'-\beta_mx')$, incorporating $ds\,\nu=(y',-x')dt$ | complex $N_q\times(2M+1)$ | general curve row / finite quadrature | none |
| `single_layer_measure` | local matrix | $v(t)t_{-\sigma}(t)$ | complex $N_q\times194$ | speed and stored density / finite quadrature | none |
| `l1_density_factor` | derived scalar | $2\pi v_{\max}$, the general parameter-density-to-$L^1(ds)$ factor | positive real scalar, length | real certificate / high-mode $A$ constants | $2\pi R$ only after specializing to the regression circle |
| `curve_audit` | result structure | grid alignment, regularity, CCW normal, clearance, and strip-contract checks | scalar structure | general evaluator / persisted result | none |
| `ordinary_regression_only` | audit logical | whether stored-map comparisons are used only for code-equivalence regression | logical scalar | side/index audit / result | must remain `true` |
| `ell_plus_scaled_absolute_defect`, `ell_minus_scaled_absolute_defect` | audit scalars | cancellation-safe ordinary differences $\|\widetilde\ell_\varsigma-J_\varsigma^{\rm stored}\|_F/\max(1,\|J_\varsigma^{\rm stored}\|_F)$ | nonnegative real scalars | side/index audit / regression gate | not a residual remainder |
| `singleton_left_scaled_absolute_defect`, `singleton_right_scaled_absolute_defect` | audit scalars | cancellation-safe ordinary singleton differences scaled by $\max(1,\|j^{\rm stored}\|_2)$ | nonnegative real scalars | side/index audit / regression gate | not a residual remainder |
| `ordinary_regression_pass` | audit logical | code-equivalence gate for general rows against frozen ordinary maps | logical scalar | side/index audit / declared circle regression | never a theorem gate |
| `regression_enters_remainder` | audit logical | whether regression drift is used in a mathematical remainder | logical scalar | side/index audit / result | must remain `false` |
| `regression_enters_stopping_rule` | audit logical | whether regression drift controls stopping | logical scalar | side/index audit / result | must remain `false` |

The fields `adapter_metadata.center` and `adapter_metadata.radius` are
circle-regression provenance owned by `build_circle_contract_a1`; the
shape-general evaluator does not consume them in any governing calculation.

## Unimplemented wall-to-boundary certificate fields

The following names are reserved for a future, separate $p=0,1$
wall-to-boundary evaluator for $B_{\mathrm{lift}}$ or $B_\Upsilon$.  They are
not fields of the completed `wall-curve-a1` result and must not be inferred
from sampled convergence.

| canonical code name | governing object | source for the current circle | requirement for a general curve |
|---|---|---|---|
| `speed_lower` | $\vartheta_{-,a}$ | exact $R$ | proved lower bound for the holomorphic speed branch |
| `boundary_length` | $P_\Lambda$ | exact $2\pi R$ | certified arclength integral |
| `arclength_imag_upper` | $\Sigma_a$ | exact $Ra$ | complex-strip upper bound for $|\operatorname{Im}S|$ |
| `signed_arclength_strip_lower` | $\sigma_a$ | exact $Ra$ | positive lower bound on both signed contour shifts |
| `full_support_nonwood_margin` | $\min_{m\in\mathcal I_w}|\widehat k^2\rho_e-\beta_m^2|$ | finite algebra from frozen $\widehat k,\beta,d$ and wall orders | same finite algebra with a reliable positive enclosure |
| `wall_to_boundary_branch_ledger` | per-order propagating/evanescent branch and $1/\gamma_m$ ownership | rebuilt from frozen modal inputs | mandatory finite ledger; a Boolean alone is insufficient |

For the current circle, all geometry entries are computable without changing
or resolving any frozen eigenpair, density, QZ subspace, or propagation
matrix.  A future evaluator must still use a new experiment because the
existing one evaluates the opposite curve-to-wall action.

## Future/unimplemented regular-image $K_{pq}$ evaluator

This table translates (M-R), (M-I), (M-T), and (M-L) of
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail]].
No listed field or function is implemented.  The current circle may generate
the self-tube geometry entries analytically from its frozen radius and strip
width, but the governing names remain shape-independent and may not consume a
circle formula in a general evaluator.  Finite interval widths and the
displayed analytic tails, never inter-level or sampling drift, govern every
future stopping decision.

| canonical code name | kind and future scope | mathematical object and source | type, shape, units | future definition / consumption | permitted alias |
|---|---|---|---|---|---|
| `self_tube_certificate` | future input structure | certified target-strip/source-boundary displacement and normal bounds in (M-Kpq) and (M-R)--(M-L) | scalar structure of outward real intervals | curve authority / all regular-image stages | none |
| `displacement_abs_upper` | future geometry field | $(R_X,R_Y)$ bounding $(\lvert X\rvert,\lvert Y\rvert)$ | nonnegative real $1\times2$, length | `self_tube_certificate` / M-R, M-T, M-L | none |
| `displacement_imag_upper` | future geometry field | $(I_X,I_Y)$ bounding $(\lvert\operatorname{Im}X\rvert,\lvert\operatorname{Im}Y\rvert)$ | nonnegative real $1\times2$, length | `self_tube_certificate` / M-R and M-I | none |
| `displacement_real_upper` | future geometry field | $(U_X,U_Y)$ bounding $(\lvert\operatorname{Re}X\rvert,\lvert\operatorname{Re}Y\rvert)$ | nonnegative real $1\times2$, length | `self_tube_certificate` / M-R and M-I gates | none |
| `target_normal_component_upper`, `source_normal_component_upper` | future geometry fields | $(N_{t,x},N_{t,y})$ and $(N_{s,x},N_{s,y})$ in (M-K-tail) | nonnegative real $1\times2$ vectors | `self_tube_certificate` / coordinate-to-normal assembly | none |
| `ewald_split` | future configuration scalar | Linton split $a_E>0$ | positive real scalar, dimensionless | fixed configuration / M-R--M-L | `a_E` only in equations |
| `ewald_h` | future derived scalar | $h=a_E/d$ | positive real scalar, inverse length | `ewald_split`, `period_y` / all Ewald stages | none |
| `ewald_eta` | future derived scalar | $\chi_E=(\kappa_e d/(2a_E))^2$, with $\kappa_e=k_{\rm outer}$ for the frozen exterior | nonnegative real scalar | physical inputs / M-I, M-T, M-L | code field name retained; never the density $\eta$ |
| `reciprocal_spacing` | future derived scalar | $b=2\pi/d$ | positive real scalar, inverse length | `period_y` / M-R | none |
| `reciprocal_cutoff` | future configuration scalar | $N_R$, retaining $\lvert m\rvert<N_R$ | positive integer scalar | fixed configuration / reciprocal finite part and tail | `N_R` only in equations |
| `image_cutoff` | future configuration scalar | $N_I$, retaining $0<\lvert j\rvert<N_I$ | positive integer scalar | fixed configuration / real-image finite part and tail | `N_I` only in equations |
| `taylor_cutoff` | future configuration scalar | $N_E$, retaining Ewald Taylor orders $0{:}N_E$ and local outer-series orders through $N_E$ | integer scalar at least $2$ | fixed configuration / M-T and M-L | code field name retained |
| `local_z_radius` | future geometry scalar | $R_0\ge\sup_{\mathcal D}\lvert h^2(X^2+Y^2)\rvert$ | nonnegative real scalar | `self_tube_certificate` / M-L | `R_0` only in equations |
| `local_cauchy_radius` | future configuration scalar | $B>R_0$ in (M-L8)--(M-L13) | positive real scalar | fixed configuration / local factorial and derivative bounds | `B` only in M-L equations |
| `finite_nonwood_ledger` | future gate structure | every retained $q_m=\sqrt{(\beta+2\pi m/d)^2-\kappa_e^2}$, branch choice, $1/q_m$, and a positive non-Wood separation | per-order outward interval structure | frozen modal inputs / reciprocal finite part | none |
| `reciprocal_tail_gate` | future gate structure | both inequalities in (M-R-gate) on both tail rays | scalar logicals plus interval margins | M-R geometry and cutoff / tail authorization | none |
| `reciprocal_tail_ratios` | future gate array | $r_{\sigma,s}<1$ for $\sigma\in\{-,+\}$ and $s=0,1,2$ in (M-R-tail) | nonnegative real $2\times3$ | first omitted reciprocal terms / reciprocal tail | none |
| `image_tail_gate` | future gate structure | $N_Id>U_Y$, $u_{N_I}>0$, and $r_\alpha<1$ for $\alpha=0,1,2$ in (M-I-gate)--(M-I-tail) | scalar logicals and outward margins | geometry and `image_cutoff` / omitted-image tail | none |
| `retained_image_real_lower` | future gate vector | $u_j\le\inf_{\mathcal D}\operatorname{Re}z_j$ for every $0<\lvert j\rvert<N_I$ in (M-T-gate) | positive outward-lower vector | self-tube geometry / retained-image finite and Taylor terms | none |
| `taylor_poisson_tail` | future tail scalar | $\Pi_{N_E}(\chi_E)=e^{\chi_E}-\sum_{n=0}^{N_E}\chi_E^n/n!$ | nonnegative outward-upper scalar | `ewald_eta`, `taylor_cutoff` / M-T tail | none |
| `local_series_ratios` | future gate vector | $(r_J,r_S,r_D,r_Q)$ in (M-L8) | nonnegative real $1\times4$, each strictly below one | M-L parameters / local factorial tail | none |
| `reciprocal_finite_enclosure` | future finite structure | retained reciprocal value and coordinate derivatives through total order two | outward complex interval arrays | finite complex `erfc`, exponential, branch, and denominator evaluation / coordinate finite part | none |
| `nonzero_image_finite_enclosure` | future finite structure | retained $0<\lvert j\rvert<N_I$, $0\le n\le N_E$ real-image value and derivatives | outward complex interval arrays | finite $E_{n+1}$, exponential, and polynomial evaluation / coordinate finite part | none |
| `local_canonical_finite_enclosure` | future finite structure | branch-free ${\cal C}_{\chi_E,N_E}^{\rm can}$ and derivative bounds from (M-L7), (M-L12), (M-L13) | outward real or complex interval structure | finite entire series / coordinate finite part | none |
| `finite_special_function_enclosure` | future audit structure | validation record for every finite complex `erfc`, $E_n$, exponential, logarithm, and constant enclosure | scalar structure with per-family gates | interval backend / all three finite structures | ordinary `Faddeeva_erfc` or `expint` values are not aliases |
| `reciprocal_coordinate_tail` | future tail vector | $(T_{00}^{\rm rec},T_{10}^{\rm rec},T_{01}^{\rm rec},T_{20}^{\rm rec},T_{11}^{\rm rec},T_{02}^{\rm rec})$ from (M-R-tail) | nonnegative outward-upper $1\times6$ | M-R / total coordinate tail | none |
| `omitted_image_coordinate_tail` | future tail vector | the six $T_{rs}^{\rm img}$ in (M-I-tail), already summing every Taylor order on omitted images | nonnegative outward-upper $1\times6$ | M-I / total coordinate tail | none |
| `retained_image_taylor_tail` | future tail vector | sums over the six $T_{rs,j}^{\rm tay}$ in (M-T-tail) for retained nonzero images | nonnegative outward-upper $1\times6$ | M-T / total coordinate tail | none |
| `local_factorial_coordinate_tail` | future tail vector | the six $T_{rs}^{\rm loc}$ in (M-L14) | nonnegative outward-upper $1\times6$ | M-L / total coordinate tail | none |
| `coordinate_finite_upper` | future result vector | outward upper bounds for retained coordinate derivatives $(00,10,01,20,11,02)$ | nonnegative real $1\times6$ | three disjoint finite structures / normal contraction | none |
| `coordinate_tail_upper` | future result vector | componentwise sum of M-R, M-I, M-T, and M-L coordinate tails | nonnegative outward-upper $1\times6$ | four disjoint tail vectors / (M-K-tail) | `T_rs` only in equations |
| `kernel_normal_tail_upper` | future result vector | $({\cal E}_{00},{\cal E}_{10},{\cal E}_{01},{\cal E}_{11})$ from (M-K-tail) | nonnegative outward-upper $1\times4$ | coordinate tails and normal bounds / $K_{pq}$ | none |
| `kernel_constant_upper` | future result vector | reliable upper bounds $(K_{00},K_{10},K_{01},K_{11})$ in (M-Kpq) | nonnegative outward-upper $1\times4$ | finite normal contractions plus `kernel_normal_tail_upper` / regular-image actions | none |
| `regular_image_theorem_gate` | future result structure | geometry, non-Wood, ratio, finite-special-function, tail-budget, and outward-rounding gates | scalar structure | all regular-image stages / persisted result | no sampling or refinement gate |

## Future/unimplemented shape-general local-panel evaluator

This table translates (P1)--(P29) of
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-local-panel]].
It covers only the local free-space self-action shared by $B_\Upsilon$ and
$B_{\mathrm{lift}}$.  Every entry remains unimplemented.  Retained-row
interval widths and the explicit (P12)--(P14), (P20), and (P29) remainders are
the only stopping data; sampled smoothness, observed Fourier decay, and
inter-level drift are not bounds.

| canonical code name | kind and future scope | mathematical object and source | type, shape, units | future definition / consumption | permitted alias |
|---|---|---|---|---|---|
| `boundary_length` | future geometry input | $P_\Lambda$ | positive outward interval, length | curve certificate / periodic logarithm, Fourier frequencies, and tails | existing reserved name above |
| `reach_lower` | future geometry input | $r_*>0$ | positive outward-lower scalar, length | embedded curve certificate / panel-width gate | `r_star` only in prose |
| `curvature_upper` | future geometry input | $\kappa_*$ | nonnegative outward-upper scalar, inverse length | curve certificate / panel-width gate | `kappa_star` only in prose |
| `speed_lower` | future geometry input | $v_->0$ | positive outward-lower scalar, length per parameter | holomorphic/real curve certificate / arclength derivatives and density bounds | existing reserved name above |
| `speed_upper` | future geometry input | $v_+$ in (P17), (P26) | positive outward-upper scalar, length per parameter | curve certificate / identity-density bounds | the existing field is reusable only when it certifies this same domain |
| `speed_derivative_upper` | future geometry input | $v_1\ge\sup\lvert v_t\rvert$ | nonnegative outward-upper scalar, length per parameter squared | curve-jet certificate / (P26) | `v_1` only in equations |
| `tau_state_coeff_map` | future derived matrix | finite $C_{\tau,n}(A)$ map in (P16), with the specified frozen state map $A$ applied | finite complex coefficient-map array | existing `tau_coeff_map` times $A$ / density bounds and panel rows | no second density transform |
| `sigma_state_coeff_map` | future derived matrix | finite $C_{\sigma,n}(A)$ map in (P16); the stored $-\sigma$ sign is changed exactly once | finite complex coefficient-map array | existing `single_layer_density_coeff_map` times $A$ / density bounds and panel rows | no second density transform |
| `chord_quotient_enclosure` | future geometry structure | continuous extension of $c(s,t)$ and $\log c$ in (P7)--(P10) | outward interval structure over panel boxes | divided-difference geometry / all $R_{\mathsf L}$ factors | none |
| `normal_divided_difference_enclosures` | future geometry structure | continuous extensions of $\pi_s\pi_t/q$ in (P10) and the four $p$-derivative quotients in (P24) | outward interval structure over panel boxes | curve jets and diagonal limits / hypersingular and second-derivative regular factors | no uncancelled `1/q` alias |
| `local_log_factor_upper` | future kernel structure | $(C_{\mathsf S}^\#,C_{\mathsf K}^\#,C_{\mathsf K^*}^\#,C_{\mathsf T}^\#)$ from (P8)--(P10) | nonnegative outward-upper $1\times4$ | cancellation-safe divided differences and kernel series / normal action | `C_hash` only in prose |
| `local_regular_factor_upper` | future kernel structure | $(R_{\mathsf S}^\#,R_{\mathsf K}^\#,R_{\mathsf K^*}^\#,R_{\mathsf T}^\#)$ from (P8)--(P10) | nonnegative outward-upper $1\times4$ | cancellation-safe divided differences and kernel series / normal action | `R_hash` only in prose |
| `local_second_log_factor_upper` | future kernel structure | $(C_{{\mathsf S},2}^\#,C_{{\mathsf K},2}^\#)$ in (P22), (P25) | nonnegative outward-upper $1\times2$ | differentiated cancellation-safe factors / lifting tail | none |
| `local_second_regular_factor_upper` | future kernel structure | $(R_{{\mathsf S},2}^\#,R_{{\mathsf K},2}^\#)$ in (P22)--(P24) | nonnegative outward-upper $1\times2$ | differentiated divided differences / lifting tail | none |
| `kernel_series_cutoff` | future configuration scalar | $N_{\mathrm{ser}}$ used to truncate each entire kernel series in (P14) | positive integer scalar | fixed configuration / kernel-series finite values and tails | not `taylor_cutoff` unless one shared value is explicitly frozen |
| `kernel_series_tail` | future remainder structure | $T_{J,r,N_{\mathrm{ser}}}(Q)$, $T_{Y,r,N_{\mathrm{ser}}}(Q)$, and their decreasing-ratio gates in (P14) | nonnegative outward-upper array plus logical gates | coefficient formulas and a certified $Q$ / all factor enclosures | none |
| `panel_half_width` | future configuration scalar | $\delta\le\min\{P_\Lambda/6,(2\kappa_*)^{-1},r_*/2\}$ | positive outward-upper scalar, length | geometry certificate / target-panel split | `delta` only in P11--P13 |
| `panel_taylor_order` | future configuration scalar | retained panel Taylor degree $M$ in (P11)--(P13) | nonnegative integer scalar | fixed configuration / retained singular and regular panel rules | never `mode_cutoff` |
| `periodic_log_moment_enclosure` | future finite vector | validated moments $\int_{-\delta}^{\delta}h^jg(h)\,\mathrm dh$, $0\le j\le M$ | outward real interval vector | analytic recurrence or validated one-dimensional quadrature / (P11) | none |
| `singular_panel_derivative_upper` | future finite bound | $G_{M+1}\ge\sup\lvert\partial_h^{M+1}g_s(h)\rvert$ | nonnegative outward-upper scalar or per-row vector | curve/density derivative enclosures / (P12) | none |
| `singular_panel_remainder` | future remainder | right side of (P12), including $\mathfrak m_{M+1}$ | nonnegative outward-upper scalar or row vector | panel derivative bound / retained-row enclosure | none |
| `regular_panel_remainder` | future remainder | right side of (P13) | nonnegative outward-upper scalar or row vector | regular-factor derivative bound / retained-row enclosure | none |
| `off_diagonal_chord_lower` | future geometry bound | positive chord separation for each non-target panel | positive outward-lower array, length | embedded panel partition / off-diagonal derivative rule | none |
| `retained_target_row_remainder` | future remainder | validated target integration width for each retained arclength Fourier row, including the identity coefficient | nonnegative outward-upper row vector | target-panel Taylor enclosure / module finite part | never an inter-grid difference |
| `retained_local_row_enclosure` | future finite result | all singularity-subtracted retained value/normal local Fourier rows from (P11)--(P14) | outward complex interval row arrays | panel finite rules and remainders / module finite part | none |
| `density_linf_tau`, `density_linf_sigma` | future density bounds | $A_\tau^\infty,A_\sigma^\infty$ from (P16) | nonnegative outward-upper scalars | finite coefficient-map spectral norms / (P17)--(P29) | none |
| `identity_sigma_l2_upper` | future density bound | $A_{\sigma,0}^s$ in (P17) | nonnegative outward-upper scalar | `speed_upper`, `density_linf_sigma` / normal local tail | none |
| `identity_tau_second_l2_upper` | future density bound | $A_{\tau,2}^s$ in (P26) | nonnegative outward-upper scalar | $v_-,v_+,v_1$ and weighted tau coefficients / value local tail | none |
| `local_normal_action_upper` | future action bound | $M_{\mathrm{nor}}^{\rm act}$ in (P18) | nonnegative outward-upper scalar | $C_{\mathsf T}^\#,R_{\mathsf T}^\#,C_{\mathsf K^*}^\#,R_{\mathsf K^*}^\#$ and density bounds / (P19), (P20) | none |
| `local_value_second_action_upper` | future action bound | $M_V^{(2)}$ in (P27) | nonnegative outward-upper scalar | second-factor and density bounds / (P28), (P29) | none |
| `local_normal_tail_squared` | future tail result | complete local normal omitted-mode bound in (P20) | nonnegative outward-upper scalar | trace weights and normal action / $B_\Upsilon$ tail | none |
| `local_value_tail_squared` | future tail result | complete local value omitted-mode bound in (P29) | nonnegative outward-upper scalar | tubular weights and second action / $B_{\mathrm{lift}}$ tail | none |
| `local_panel_theorem_gate` | future result structure | curve regularity, panel-width, divided-difference, series-ratio, retained-row, tail-budget, and outward-rounding gates | scalar structure | all local-panel stages / persisted result | no sampling or refinement gate |

The two future evaluators are disjoint from the completed artificial-wall
experiment.  They may read frozen finite coefficients and geometry but must
not recompute the candidate eigenpair, BIE densities, QZ subspaces, or
propagation matrices.  Until implemented, none of the names in these two
tables may appear as a passed runtime theorem gate or be inferred from
ordinary sampled convergence.

## Implemented `residual-numerator-a1` overrides

This is the governing code ledger for `test/i5/residual-numerator-a1/`.
It changes no frozen field name or schema; it only records local aliases.  The
512-node evaluation grid is not the 256-node frozen density grid.

| code field or variable | governing object | frozen/generated source | role and normalization |
|---|---|---|---|
| `k_outer` | $\widehat k$ | `z.khat` | exterior wavenumber; never the shifted norm parameter |
| `mu_shift` | $\mu=\widehat k^2$ | `z.mu_h=z.gamma` | energy shift; never a Rayleigh wavenumber |
| `beta_bloch` | $\beta$ | `z.beta` | Bloch parameter |
| `rayleigh_wavenumber` | outgoing $\gamma_m$ | algebra from frozen $\widehat k,\beta,d$ | branch and finite $1/\gamma_m$ ledger; no solve |
| `density.orders` | frozen density orders $-128{:}127$, hence $N_\eta=256$ and $M_\eta=128$ | frozen-density FFT convention | independent of evaluation grid |
| `tau_coeff_map` | coefficient map of $\tau$ | `fftshift(fft(z.eta_unit_256(1:256,:)))/256` | no midpoint phase |
| `sigma_coeff_map` | coefficient map of $\sigma$ | negative of the stored second map because `zeta=-sigma` | sign changed exactly once |
| `configuration.boundary_node_count` | evaluation size $N$ | generated input; final value 512 | proof-driven quadrature tier, not a density solve |
| `configuration.retained_mode_cutoff` | zero-based finite cutoff $L-1$ | generated input; final value 255, so $L=256$ | retained rows are exactly $|\ell|<L$; the current $N=512$ does not satisfy the strict gate $N>2\max\{L,M_\eta\}$ |
| `local_complex_strip_certificate` | proposed analytic normalized-chord contract | current generated adapter | its present booleans do not yet certify the full product strip, signed-speed branch, or absence of non-diagonal complex null chords required before (P32) |
| `local_factors` | real P3--P29 bounds | cancellation-safe certificate and series tails | P20/P29 fallback |
| `complex_strip_factor_bounds` | strip $C^\#,R^\#$ bounds | complex chord certificate and series tails | Kress alias and target rows |
| `maue_strip_factor_bounds.tau_prime_strip_upper` | $A'_{\tau,a}$ | weighted frozen density coefficients | derivative term in the actual normal center |
| `weighted_single_layer_log_upper`, `weighted_single_layer_smooth_upper` | $C_S^T,R_S^T$ in (P31M) | exterior/interior entire-series bounds | first Maue normal term |
| `tangent_derivative_log_upper`, `tangent_derivative_smooth_upper` | $C_{\partial T}^\#,R_{\partial T}^\#$ | target-tangent projection certificate | second Maue normal term after cotangent cancellation |
| `local_panel.value_rows`, `normal_rows` | local modal centers | Müller-combined Kress action | identity included once |
| `kress_log_alias_factor` | logarithmic factor in (P31) | $a,N$ | explicit remainder, not grid drift |
| `periodic_log_weight_upper` | $8\pi\log2\,V_a$ | pointwise complex signed-speed bound $V_a$ | shape-general coarse bound for the weighted periodic logarithm; not a path-length bound |
| `smooth_source_measure_upper` | $L_a\ge\sup_y\int_0^{2\pi}|v(u+\mathrm i y)|\,du$ | complex source-contour certificate | smooth-remainder source measure only |
| `retained_target_row_remainder` | conditional (P32) value-row radius | strip speed/action/phase bounds | rejected until the shape-general product-strip action enclosure passes |
| `global_action_triangle_enclosure` | shape-general $\widetilde H^\chi=H_{\rm an}^\chi$, $\chi\in\{\mathrm{val},\mathrm{nor}\}$, and strip-majorant gate | product-strip and action-bound proof | fixed `false` in the present source and included in `local_action.gate.pass` |
| `regular_image_certificate.coordinate_tail_upper` | six M-R/M-I/M-T/M-L tails | generated Ewald certificate | order $(00,10,01,20,11,02)$ |
| `kernel_finite_upper`, `kernel_tail_upper` | four $K_{pq}$ contractions | coordinate and normal bounds | source, target, and mixed normals remain distinct |
| `regular_image.value_rows`, `normal_rows` | finite $H_\beta$ centers | exact-QP Ewald finite representation | never an MFS proxy |
| `off_surface.value_rows`, `normal_rows` | wall-to-material action | frozen Rayleigh coefficients | positive-distance action |
| `rows.value`, `rows.normal` | combined defects | local, regular, off-surface centers | combined before weights |
| `rows.value_error`, `rows.normal_error` | retained row radii | sum of component radii | triangle inequality; no observed cancellation |
| `material.finite_squared` | finite part of $B_\Upsilon^2$ | retained modes/cells/states | trace weighted |
| `material.tail_squared` | omissions for $B_\Upsilon^2$ | block-power and angular tail | stopping datum |
| `lifting.material_interface` | material value-lift energy | tubular weights and value rows | factor two applied at module bound |
| `lifting.artificial_walls` | wall value-lift energy | frozen wall data | disjoint from material lift |
| `wall_normal.B_Gamma_pm` | accepted $B_{\Gamma_\pm}$ | fixed scalar with source provenance | historical output not read at runtime |
| `numerator_majorant` | ${\cal M}=B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}$ | final assembly | numerator only |
| `prediction.q_pred` | ${\cal M}/\sqrt{\widetilde N}$ | `staged.ordinary_anchor.N_tilde` | authorized diagnostic |
| `prediction.lambda_*` | predicted interval in $\mu$ | authoritative rational map | not an enclosure |
| `prediction.k_*` | predicted interval in $\widehat k$ | positive endpoint square roots | not an enclosure |

The provenance fields `mfs_proxy_used`,
`circle_bessel_diagonalization_used`, and `sampling_drift_used` must all be
false, and all four solve counts must be zero.  Every output remains labeled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` with `reliability_certified=false`.

## Implemented `residual-numerator-v1` overrides

This is the local code ledger for `test/i5/residual-numerator-v1/`.  It does
not alter the preceding historical `residual-numerator-a1` meanings or any
I1--I4 field.  The v1 builder consumes explicit `artifact_path` and
`curve_contract_path` arguments, explicit numeric `wall_finite_squared` and
`wall_tail_squared`, and an optional non-authorizing `wall_provenance_label`.
It writes only its explicit create-once `input_path`; the evaluator consumes
that MAT file and writes only its explicit create-once `output_path`.  No v1
executable reads a historical experiment output.

| canonical code field or variable | kind and scope | governing object and source | type, shape, units | definition / consumer | permitted alias |
|---|---|---|---|---|---|
| `configuration.residual_mode_cutoff` | generated scalar | $L$, retaining $|\ell|<L$, (KR-2), (KR-24)--(KR-25) | positive integer | first finite tail pass in the declared schedule, or last schedule value for a failed-tolerance display / both entry points | none |
| `configuration.evaluation_node_count` | generated scalar | $N>2\max\{L,M_\eta\}$, (KR-2) | positive even integer | $2\max\{L,M_\eta\}+2$ after $L$ is frozen / KR-16--KR-21 | never `source_node_count` |
| `local_real_derivative_certificate.val`, `.nor` | generated structures | density-inclusive $S_{j,2}$, $C_{j,q}$, $\mathcal H_q$, and $Q_2$, (KR-15), (KR-18), (KR-22) | finite nonnegative arrays with the shapes in `design-5-1b.md` | circle $q$-series adapter / local radii and Fourier tails | none |
| `delta_Ctan2_source_second_upper` | generated scalar | source-second derivative bound for $C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}}=p_TW$ | nonnegative real | diagonal-safe $J/Y$ series / KR-15 normal bound audit | none |
| `delta_Dstar2_source_second_upper` | generated scalar | source-second derivative bound for $D_{\kappa_e,2}^*-D_{\kappa_i,2}^*=p_nW$ | nonnegative real | diagonal-safe $J/Y$ series / KR-15 normal bound audit | none |
| `local_rows.*.series_delta_log_upper`, `.series_delta_smooth_upper` | generated $N\times N$ arrays | $\Delta_{1,iq},\Delta_{2,iq}$ in (KR-21), here enclosing the whole discrete integral operator about zero | nonnegative real arrays | absolute complete $J/Y$ sums including factorial tails / `LOCAL_series_radius` | not a sampled error |
| `regular_zero_center_certificate` | generated structure | exact regular-image action split into retained Ewald finite radius and M-R/M-I/M-L radii | nonnegative coordinate and `K00,K01-source,K10-target,K11` bounds | builder / retained and angular-tail assembly | no Faddeeva or `expint` center |
| `off_surface_zero_center_certificate` | generated structure | exact frozen finite Rayleigh action about zero | outgoing per-order arrays plus value/normal radii | frozen `xi_left_unit_512`, `xi_right_unit_512` / retained and angular-tail assembly | none |
| `propagation_minus`, `propagation_plus` | generated structures | block-power constants $K_-$ and $K_+$ | Frobenius-norm prefix, block contraction, nonnegative sum bound | frozen $P_-$, $P_+$ / cell and angular tails | no unqualified spectral-norm call |
| `retained_assembly.material`, `.lifting` | generated structures | $\overline F_\Upsilon^2$ and $\overline F_{\mathrm{lift}}^2$, (KR-27), (KR-30) | expanded row centers, radii, weights, and state labels | identity, zero-center kernel radii, frozen singleton/cell states / evaluator | none |
| `tail_assembly.*.low_cell` | generated structure array | retained-mode $n\ge J$ block-power remainder, (KR-28), (KR-31) | two side records with identity map, radius, weight, and state norm | builder / `LOCAL_low_cell_tail` | none |
| `wall_value_lift_certificate` | generated structure | artificial-wall value-lift finite, high-mode, and $n\ge J$ terms | nonnegative finite/tail data | frozen wall rows plus positive-distance circle-to-wall radius / lifting assembly | distinct from `wall_module` |
| `wall_finite_squared`, `wall_tail_squared` | builder input scalars | $\overline F_{\Gamma_\pm}^2$ and $T_{\Gamma_\pm}^2$, (KR-32) | finite nonnegative scalars | explicit caller values / `wall_module` and final numerator | no historical result path |
| `wall_provenance_label` | optional builder input text | descriptive origin of the explicit wall scalars | character vector or scalar string, no mathematical authority | caller / input and enclosure provenance | defaults to `UNSPECIFIED_NONAUTHORIZING_PROVENANCE` |
| `wall_module` | generated data-only structure | $\overline F_{\Gamma_\pm}^2+T_{\Gamma_\pm}^2$, (KR-32) | two nonnegative scalars, source kind, scope, and non-authorizing provenance | explicit builder arguments / final numerator | never the artificial-wall value lift |
| `retained_radius_audit` | result structure | source, target, zero-center series, regular, off-surface, and wall retained radii | nonnegative maxima and one tolerance gate | evaluator / final scientific status | tolerance failure is not a structural pre-run failure |
| `numerator_majorant` | result scalar | $\widehat B_{\Gamma_\pm}+\widehat B_\Upsilon+\widehat B_{\mathrm{lift}}$ | nonnegative real | final evaluator assembly | numerator only |

The circle identities are an input adapter only; the governing theorem remains
the shape-general real-variable Kress result.  All v1 solve-count fields are
zero, and every numeric output remains `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Implemented `residual-numerator-v2` overrides

This local ledger applies only to `test/i5/residual-numerator-v2/`.  Fields not
listed here retain their v1 mathematical meaning.  No override changes a
frozen artifact field, schema, MATLAB package API, or I1--I4 meaning.

| canonical code field or variable | governing object | source and role | non-overlap rule |
|---|---|---|---|
| `local_rows.*.finite_center` | $\widetilde d_\ell^{\mathrm{self}}=\mathcal D_N[J+Q_NK_Q]$ | signed finite Kress-series action followed by one target DFT | replaces the v1 identity-only center |
| `local_rows.*.source_radius` | $\epsilon_\ell^{\mathrm{src}}$ | exact-integrand source product-rule error | excludes identity, target, and series errors |
| `local_rows.*.target_radius` | $\epsilon_\ell^{\mathrm{tgt}}$ | minimum of the general KR-19 bound and the constant-speed alias bound (KR-19a)--(KR-19b) | two bounds for the same error are not added |
| `local_rows.*.target_radius_KR19` | KR-19 target DFT radius | complete identity-plus-action derivative bound | retained for audit even when the alias radius is smaller |
| `local_rows.*.target_radius_constant_speed_alias` | $Q_2P^{3/2}A_{\ell,N,64}/(4\pi^2)$ | exact DFT alias identity with 64 explicit two-sided aliases and monotone integral tails | requires constant speed and $|\ell|<N/2$ |
| `local_rows.*.series_radius` | $\epsilon_\ell^{\mathrm{series}}$ | tail-only difference between the signed exact kernel and signed retained series | never an unsigned enclosure of the finite center |
| `local_series_adapter` | signed $a_{\kappa,n}$, $y_{\kappa,n}$, $b_{\kappa,m}$, $r_{\kappa,m}$ coefficients | current-circle pointwise adapter for (I5.1c-5) | not a circle operator diagonalization |
| `off_surface_rows.*.finite_center` | $\widetilde d_\ell^{\mathrm{off}}$ | signed frozen finite Rayleigh action | value adds raw action; normal subtracts raw action under $A_w^\nu=-\partial_\nu u_w$ |
| `off_surface_rows.*.target_radius` | $\epsilon_\ell^{\mathrm{off}}$ | retained off-surface target quadrature error over the complete frozen finite Rayleigh support | omitted target-Fourier rows $|\ell|\ge L$ are owned only by the angular tail |
| `regular_zero_center_certificate` | $\widetilde d_\ell^{\mathrm{reg}}=0$ and a complete exact-action radius | Ewald full-action enclosure | an absorbed M-T Taylor tail is recorded once in each index scope |
| `regular_zero_center_certificate.coordinate_real_axis` | $K_{pq}(0)$ certificate | real-axis displacement, normal, and density $L^1(\mathrm ds)$ bounds | used only for retained $|\ell|<L$ radii |
| `regular_zero_center_certificate.coordinate_high_target_strip` | $K_{pq}(a)$ certificate with $a=0.2$ | complex-strip Ewald full-action bound | used only for omitted target-Fourier rows $|\ell|\ge L$ |
| `retained_high_target_index_disjoint` | $\{|\ell|<L\}\cap\{|\ell|\ge L\}=\varnothing$ | regular-image ownership gate | real-axis retained radius and strip high tail are never added to one coefficient |
| `constant_speed_alias_enclosure` | constant-speed target DFT alias gate | finite two-sided sum through 64 plus first-term-and-integral tail from 65 | fail closed; no cosecant cancellation formula |
| `combined_rows.*.center` | $C_\ell=\widetilde d_\ell^{\mathrm{self}}+\widetilde d_\ell^{\mathrm{off}}$ | signed center formed before absolute value and weighting | regular-image center is zero |
| `combined_rows.*.radius` | $\epsilon_\ell^{\mathrm{src}}+\epsilon_\ell^{\mathrm{tgt}}+\epsilon_\ell^{\mathrm{series}}+\epsilon_\ell^{\mathrm{reg}}+\epsilon_\ell^{\mathrm{off}}$ | retained-row triangle radius | every radius owner occurs once |
| `tail_assembly.*.low_cell.center_map` | $C_{\varsigma,\ell}$ in (KR-26a) | complete signed combined row map used for $n\ge J$ | replaces the v1 identity-only map |
| `tail_assembly.material.low_cell.weight` | $1/b_\ell$ | material normal trace weight | never used for lifting |
| `tail_assembly.lifting.low_cell.weight` | $e_{\ell,\mathrm{val}}$ | material value lifting energy weight | multiplies both finite and low-cell squares |
| `series_tail_ownership` | finite-series factorial remainders | Boolean and label audit | `tail_only`; a whole-action series radius is rejected |
| `off_surface_sign_audit` | physical sign of the off-surface center | Boolean audit for value plus and normal minus | failure is structural |
| `low_cell_complete_map_audit` | equality of retained and low-cell combined row definitions | Boolean audit | identity-only low-cell maps are rejected |
| `lifting_weight_direction_audit` | multiplication by $e_{\ell,\mathrm{val}}$ | Boolean audit of finite and low-cell formulas | division is rejected |

The retained set remains exactly $|\ell|<L$, $N$ remains even with
$N>2\max\{L,M_\eta\}$, and no Nyquist representative is retained.  Every v2
solve count is zero.  All v2 numerical values remain
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Implemented `residual-numerator-v3` overrides

This ledger applies only to `test/i5/residual-numerator-v3/`.  Governing
formulas are (RNC-1)--(RNC-9) in `s-kress-real.md` and the unchanged
(KR-26)--(KR-32) retained/low-cell assembly.  Unlisted fields retain their v2
meaning.  No v3 executable reads a historical output.

| canonical code field or variable | governing object | type, shape, and role | definition / consumer |
|---|---|---|---|
| `v2_input_path` | explicit I5.1c data contract | path to a self-contained MAT input, never an output | both v3 entry points / contract revalidation |
| `artifact_path` | frozen I3 certificate | explicit MAT path containing the fixed candidate, density, and state maps | builder / artifact audit |
| `same_run_v2_output_path` | fresh I5.1c baseline side effect | create-once output path; never a historical input | evaluator / `residual_numerator_v2` in the same invocation |
| `regular_taylor_cutoff` | retained Ewald order $N_E$ | nonnegative integer; Taylor orders $0{:}N_E$ are retained | v2 configuration / signed image and local sums |
| `raw_normal_rows` | $d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}$ retained center in (RNC-1) | complex $(2L-1)$-by-state row map | builder / physical-sign audit |
| `physical_normal_rows` | negative raw regular row after (RNC-9) | `-raw_normal_rows`; regular action is subtracted once | builder / material delta |
| `M_R_coordinate_tail` | reciprocal omission in (RNC-7) | nonnegative coordinate row ordered `00,10,01,20,11,02` | v2 certificate / normal contraction |
| `M_I_coordinate_tail` | omitted-image remainder in (RNC-7) | nonnegative coordinate row | v2 certificate / normal contraction |
| `M_T_coordinate_tail` | first omitted retained-image Taylor orders in (RNC-7) | nonnegative coordinate row | v3 builder / normal contraction |
| `M_L_coordinate_tail` | branch-free local factorial remainder in (RNC-7) | nonnegative coordinate row | v2 certificate / normal contraction |
| `source_quadrature_row_radius` | $\epsilon_{\ell,\mathrm{src}}^{\mathrm{nor}}$ in (RNC-4) | nonnegative scalar shared by retained rows | builder / `total_retained_row_radius` |
| `target_quadrature_row_radius` | $\epsilon_{\ell,\mathrm{tgt}}^{\mathrm{nor}}$ in (RNC-5) | nonnegative $(2L-1)$-vector | builder / `total_retained_row_radius` |
| `finite_special_function_eval_row_radius` | $\epsilon_{\ell,\mathrm{eval}}^{\mathrm{nor}}$ in (RNC-6) | zero only under `FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT` | builder / condition audit |
| `total_retained_row_radius` | $\epsilon_{\ell,\mathrm{reg}}^{\mathrm{nor}}$ in (RNC-8) | source + target + M-R + M-I + M-T + M-L + finite-evaluation radii | builder / retained and low-cell material assembly |
| `finite_physical_center` | state-scaled signed regular center | complex vector in the v2 retained-state order | builder / evaluator nonlinear recomputation |
| `finite_regular_radius` | state-scaled `total_retained_row_radius` | nonnegative vector in the v2 retained-state order | builder / evaluator nonlinear recomputation |
| `combined_center_row_map` | complete low-cell center map | local + physical regular + physical off-surface row map composed with one frozen side map | builder / $n\ge J$ block-power recomputation |
| `FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT` | conditional RNC-6 assumption | true only as a diagnostic condition; never a reliability gate | builder, evaluator, and persisted result |
| `reliable_eval_enclosure_pass` | finite-evaluation reliability gate | always false in I5.1d | builder and evaluator / claim boundary |
| `total_reliable_pass` | complete reliability gate | always false in I5.1d | evaluator / claim boundary |
| `conditional_diagnostic_pass` | finite structural diagnostic gate | true only when all non-RNC-6 structural gates and finite-value checks pass | builder and evaluator / status |

The RNC telescope gives M-R/M-I/M-T/M-L, target quadrature, source
quadrature, and finite evaluation exactly one owner.  The v3 high target-mode
groups remain disjoint and unchanged.  Every v3 solve count is zero, and its
numeric output remains `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Implemented `residual-numerator-v4` overrides

This ledger applies only to `test/i5/residual-numerator-v4/`.  It preserves
the common residual notation and does not change a frozen artifact field,
MATLAB package API, or I1--I4 meaning.

| code field or variable | governing object | role and ownership |
|---|---|---|
| `configuration.cutoff_schedule` | material cutoff candidates $L$ | selects retained $|\ell|<L$ only from explicit omission tails; the reviewed attempts selected $L=65536$ |
| `material.modewise_component_minima` | (ZF-16)--(ZF-18) | takes local, regular-image and off-surface minima separately for each mode, then adds the three radii before one trace/lift weight |
| `direct_wall_certificate.orders` | frozen wall support $-256{:}255$ | distinct from material $L$; the curve-only $m=256$ term and high $|m|\ge257$ terms are stored in analytic tails |
| `direct_wall_certificate.normal.Q_left_radius`, `.Q_right_radius` | $q_{L,m}$, $q_{R,m}$ | complete flat-half-jump plus curve-action zero-centre radii; no shared value trace enters the normal action |
| `direct_wall_certificate.normal.plus_sequence_radius` | $q_{R,m}(G_+)+q_{L,m}(G_+P_+)$ | same-wall normal actions are added before squaring |
| `direct_wall_certificate.normal.minus_sequence_radius` | $q_{L,m}(G_-)+q_{R,m}(G_-P_-)$ | same-wall normal actions are added before squaring |
| `direct_wall_certificate.value.left_defect_radius`, `.right_defect_radius` | $v_{L,m}$, $v_{R,m}$ | shared trace, flat value action and curve value action are added within one collar before squaring |
| `direct_wall_certificate.value.center_left_mismatch_radius`, `.center_right_mismatch_radius` | zero-centre bounds for (ZF-27) | rebuilt from frozen $D_\pm c_\pm$ and $q_{\rm center}$; stored mismatch rows are not read |
| `wall.analytic_tail` | curve-only $m=256$ plus $|m|\ge257$ normal tail | disjoint from retained frozen wall rows |
| `lifting.wall_value.analytic_tail` | curve-only $m=256$ plus $|m|\ge257$ value tail | direct finite wall-input support has no high contribution |
| `G_block_layout_exact_pass` | diagnostic comparison with $[D_+;D_+P_+]$ and $[D_-P_-;D_-]$ | never authorizes the bound; stored $D_\pm$ and $G_\pm$ are used directly |
| `wall_input_exact_map_pass` | exact shared-trace selector contract | literal `isequal`, not a floating tolerance |
| `rho_exterior_one` | $\rho_e=1$ and $\mu_h=\widehat k^2\rho_e$ | required-true model gate |
| `trace_half_width_pass` | $h_{\mathrm{tr}}=1/2$ | verifies the half-width against both the declared cell width and $X_R-X_L$ |
| `stored_residuals_unused` | historical wall residual exclusion | `Jplus`, `Jminus`, stored jumps and stored mismatches never enter governing totals |
| `configuration.global_lift_factor` | outer factor two in $B_{\mathrm{lift}}$ | fixed to two and applied only by the evaluator |
| `certification_label` | numerical claim boundary | always `NON_CERTIFIED_ROUNDOFF_EXCLUDED`; no outward interval backend is used |
| `local_certificate.*.Q4` | $Q_4$ in (ZF-31)--(ZF-34) | fourth-derivative local coefficient and omitted-tail alternative; minimized only against complete reliable alternatives |
| `density.*_coefficient_ball` | $(\widetilde E_m,\delta_{m,k},b_m^E)$ in (ZF-39)--(ZF-40) | finite DFT-ball enclosure for $E=\tau$ or $E=\zeta=-\sigma$; an auxiliary density centre, never a residual-action centre |
| `density.*_dft_derivative_upper` | $A_{E,q}$, $0\le q\le5$ | coefficientwise derivative upper from (ZF-41), before minimization with the uniform triangle upper |
| `density.*_uniform_derivative_upper` | uniform finite-density triangle upper | independent reliable alternative for the same derivative quantity |
| `density.*_derivative_upper` | selected density derivative upper | literal componentwise minimum of the two preceding reliable arrays |
| `density.dft_ball_certificate.selected_minimum_pass` | selected-minimum ownership gate | requires exact `isequal(selected,min(raw_dft,uniform))`; routed through builder and evaluator fail-closed conjunctions |
| `density.dft_ball_certificate.root_of_unity` | enclosure of $e^{-2\pi\mathrm i/256}$ and its powers | directed half-angle square-root rectangles and sharp-ball product recurrence; no library FFT or trigonometric call |
| `configuration.density_root_newton_iterations` | finite square-root iteration count | fixed before each attempt; the final attempt uses 64 |
| `configuration.density_root_bracket_padding` | positive dyadic analytic widening | final value $2^{-48}$; preserves noncollapse in the governing exact-arithmetic model but does not certify floating-point rounding |

The v4 input and evaluator carry zero counts for eigenpair, BIE-density, QZ
and propagation solves.  A failed `tail_tolerance_pass` is a tightness
failure, while failure of any structural or required gate blocks the
roundoff-excluded reliability claim.

## Implemented `residual-numerator-v5` conditional overrides

This section applies only to the I5.1f implementation.  It does not change
the frozen schema, package APIs, or earlier I5 contracts.  The governing
design is [design-5-1f.md](design-5-1f.md).

| code object | governing object | normalization and ownership |
|---|---|---|
| `density.orders`, `maximum_order`, `source_node_count` | frozen orders, $M_\eta$, $N_\eta$ | orders $-128{:}127$; row-2 coefficient norms, not the v4 coordinatewise dual norm |
| `configuration.residual_mode_cutoff`, `evaluation_node_count` | $L,N$ | retain $|\ell|<L$ and require even $N>2\max\{L,M_\eta\}$; tail selects $L$ before retained radius selects $N$ |
| `local.center.val/nor` | signed complete Kress self row | one identity; density and source Jacobian included; cotangent difference canceled first |
| `local.radius.*.source/target/series` | local analytic telescope | source product rule, target alias, and omitted kernel-series terms, each once |
| `regular.raw_center.val/nor`, `off_surface.raw_center.val/nor` | raw Ewald and finite Rayleigh rows | physical value uses plus raw, physical normal uses minus raw, before absolute values |
| `regular.radius.*.M_R/M_I/M_T/M_L` | four Ewald omission owners | retained $|\ell|<L$ only; high rows use the complete strip-action envelope |
| `regular.radius.*.source/target` | separate one-variable trapezoid errors | source moves with grown finite density; target moves with real-source density mass; no product-strip assumption |
| `material.finite`, `cell_tail`, `high_tail` | material retained, propagated, and omitted-mode squared bounds | normal divides by trace weight; value multiplies by lifting weight |
| `wall.normal`, `wall.lifting` | signed artificial-wall modules | retained wall $|m|\le256$, high $|m|\ge257$; value has no global lifting factor yet |
| `B_lift_ideal` | $2\sqrt{F_{\mathrm{lift},\Upsilon}^2+F_{\mathrm{lift},\Gamma}^2+T_{\mathrm{lift}}^2}$ | the global factor two is applied once, only by the final evaluator |
| `delta_sf`, `delta_fp` | $\Delta_{\mathrm{sf}}$, $\Delta_{\mathrm{fp}}$ in (I5.1f-5) | unresolved final-functional error bounds; literal strings `UNRESOLVED`, never numerical zero |
| `condition_label` | phase-1 claim | `CONDITIONAL_ON_EXACT_SPECIAL_FUNCTION_EVALUATION`; neither reliability nor certification |
| `sf_ledger` | finite primitive inventory | invocation counts and parameter regions are diagnostics, not error bounds |

The ideal majorant still includes all analytic omissions.  Every final
reliability/outward-rounding gate remains false until both unresolved
finite-evaluation obligations are closed.  The phase-2 decision uses only
the two thresholds explicitly authorized by the user.

### Restricted v5 finite-function sensitivity

These aliases belong only to `special_function_sensitivity_v5.m` and do not
change the canonical run-02 result or its unresolved claim labels.

| code object | governing object | normalization and ownership |
|---|---|---|
| `matched_state_energy` | $S_J$ in (I5.1f-35) | explicit $n<J$ states plus the same block-power $n\ge J$ envelope as the computed majorant |
| `unit_row_gain.Faddeeva.val/nor`, `.E1.val/nor` | $d_c^\chi$ in (I5.1f-34) | finite source/target contraction including actual library phase magnitudes, both Jacobians and density row norms |
| `A_F`, `A_E` | $A_c$ in (I5.1f-36) | final numerator gain per unit uniform absolute family error; lifting weight multiplication and global factor two already included |
| `required_uniform_absolute_error` | $\tau_c/A_c$ | sufficient oracle error target, not an observed or proved library error |
| `exact_function_magnitude_upper` | $U_F,U_E$ in (I5.1f-37a)--(I5.1f-37b) | ordinary evaluations of analytic magnitude bounds; reliable use still requires outward argument/gain enclosure |
| `required_uniform_exact_relative_error` | $\tau_c/(A_cU_c)$ | relative to the exact function magnitude, not to a cancelled action or a library return |
| `delta_sf_rest` | $\Delta_{\mathrm{sf,rest}}$ | all remaining primitive and argument-change paths in the mixed telescope; `UNRESOLVED`, separate from floating-point summation error |
| `status` | restricted sensitivity scope | `PARTIAL_FADDEEVA_E1_SENSITIVITY_ONLY`, not a complete special-function or residual certificate |

The separate `local_certificate_sensitivity_v5.m` further isolates only the
local positive `gammaln`-to-immediate-`exp` certificate chain:

| code object | governing object | normalization and ownership |
|---|---|---|
| `whole_state_energy` | $S_\infty$ in (I5.1f-50) | whole-state high-mode factor; distinct from matched retained/cell $S_J$ |
| `D_val`, `D_nor`, `D_local` | (I5.1f-51) | local retained-radius and high-amplitude sensitivity; `D_local=D_nor+2*D_val` |
| `prospective_error_cap.epsilon_logGamma` | $\varepsilon_\Gamma$ in (I5.1f-47) | absolute error in $\log\Gamma(n)$, $n=1{:}34$; not error in $\Gamma(n)$ |
| `prospective_error_cap.eta_exp` | $\eta_e$ in (I5.1f-47) | exact-relative error only for the immediate positive coefficient exponentials |
| `bilateral_factor` | (I5.1f-48)--(I5.1f-49) | common lower/upper factors preserve each p2/p4 alternative and its selected minimum at amplitude level |
| `delta_sf_rest2` | (I5.1f-53) | all remaining primitive paths, including regular-image gamma-log calls; `UNRESOLVED`, not silently included in floating-point error |

The final `regular_gamma_sensitivity_v5.m` isolates the additional named
regular-image composite in (I5.1f-57)--(I5.1f-68):

| code object | governing object | normalization and ownership |
|---|---|---|
| `positive_coefficient` | $P^\#,Q^\#$ in (I5.1f-60)--(I5.1f-61) | triangle before coefficient cancellation; $1/(4\pi)$ occurs once |
| `fixed_library_data_gain.E_sharp` | $E^\#$ in (I5.1f-62) | maximum over the complete finite canonical call set, not a continuum sampled maximum |
| `fixed_library_data_gain.D_tau/D_zeta`, `.target_row_scale` | $D_\tau,D_\zeta,q_\ell$ | actual library source density phases and target quadrature magnitudes, without a unit-phase shortcut |
| `Dcenter`, `Dradius` | separated sensitivity feature norms for (I5.1f-67) | the former includes the regular high-mode owner; normal and value are kept separate |
| `selected_factor.c0/cR` | $u_0-1,u_R-1$ | canonical/high and retained-radius factors, evaluated with `expm1`/`log1p` to avoid small-cap cancellation |
| `prospective_common_cap` | common dyadic $t$ for four contracts in (I5.1f-57) | absolute gamma-log/log errors and exact-relative immediate/outer-exp errors; not measured errors |
| `delta_sf_rest3` | remaining primitive-family telescope | all unnamed paths still `UNRESOLVED`; the final special-function remainder is not numerically closed |

## Implemented `residual-numerator-v6` conditional overrides

This section applies only to the I5.1g implementation under
`test/i5/residual-numerator-v6/`.  Its governing source is
[design-5-1g.md](design-5-1g.md) and (ME-1)--(ME-31) in
`phase3-analysis/residual-bound/s-lift-tail.md`.  Unlisted signed-centre,
normal-defect, Ewald, Kress, and frozen-artifact names retain their v5
meaning.  The v6 executable reads no v1--v5 output.

| canonical code object | governing object | type, shape, and ownership |
|---|---|---|
| `configuration.minimum_energy_lifting_factor` | factor one in (I5.1g-1), (ME-5) | scalar exactly equal to one; applied only by `residual_numerator_v6` |
| `geometry.material_lift_collars.plus/minus` | $(h_q,\overline\rho_q,\theta_q,\Theta_q)$ in (I5.1g-2) | separate scalar structures for the exterior and interior material collars; equality is never silently inferred |
| `geometry.wall_lift_collars.plus/minus` | $(h_q^w,\overline\rho_q^w)$ in (I5.1g-11) | separate flat-collar structures for neighbour and central sides |
| `geometry.lift_geometry_gates` | simultaneous comparison hypotheses in (ME-1)--(ME-12) | collar injectivity, mutual disjointness, zero rims, exhaustive interface labels, and $J_{\mathrm{all}}e=-a$ |
| `geometry.lift_geometry_gates.material_transverse_periodic_copies_disjoint` | transverse-copy collar condition in (ME-7) | exact Boolean check $2(R+h)\le d$, distinct from the cell-height copy check |
| `weights.minimum_energy.kappa_plus/minus` | $\kappa_{q,\ell}$ in (I5.1g-3) | positive real $(2L-1)$-vectors; one-dimensional zero-rim comparison costs |
| `weights.minimum_energy.harmonic_weight` | $\overline w_{\Lambda,\ell}$ in (I5.1g-3) | positive real $(2L-1)$-vector; multiplies the complete material value-jump ball once |
| `local.high_tail.val` | $T_{\Lambda,4}^{\mathrm{loc}\,2}$ in (I5.1g-9) | nonnegative scalar; owns only local $|\ell|\ge L$ modes under the affine harmonic-weight bound |
| `wall.minimum_energy.weight_certificate.harmonic_weight` | $\overline w_m^w$ in (I5.1g-11) | positive real 513-vector for retained $|m|\le256$ |
| `wall.minimum_energy.central_minus_center/central_plus_center` | $a_-^{\mathrm{cf}},a_+^{\mathrm{cf}}$ in (I5.1g-12) | complex 513-vectors; each physical central/first jump appears once |
| `wall.minimum_energy.paired_plus_center/paired_minus_center` | $\widetilde W_+,\widetilde W_-$ in (I5.1g-13a) | complex $513\times97$ row maps formed before weighting |
| `wall.minimum_energy.paired_plus_radius/paired_minus_radius` | $r_+,r_-$ in (I5.1g-13a) | nonnegative 513-vectors; left/right action radii are combined before one wall weight |
| `wall.minimum_energy.high_tail_ledger` | (I5.1g-15)--(I5.1g-21) | map-specific complete paired-action constants, affine wall weights, two signs, and first omitted order 257 |
| `material.cell_tail.lifting_squared` | paired material value-jump block tail | scalar using the same harmonic retained weight and one block-power certificate per side |
| `material.gates.actual_jump_owner_complete`, `wall.gates.actual_jump_owner_complete` | finite/cell/high ownership of $J_{\rm all}$ | derived Booleans combined with the three-interface label audit in `gates.simultaneous_jump_list_complete` |
| `B_lift_ideal` | $\widehat B_{\mathrm{lift}}^{\mathrm{ME}}$ in (I5.1g-22) | square root of the disjoint material/wall lifting energies; no outer factor two |

The material retained/omitted split is exactly $|\ell|<L$ versus
$|\ell|\ge L$, while the wall split is $|m|\le256$ versus $|m|\ge257$.
The strings `delta_sf=UNRESOLVED` and `delta_fp=UNRESOLVED` remain governing
claim qualifiers.  All v6 solve counts are zero.
