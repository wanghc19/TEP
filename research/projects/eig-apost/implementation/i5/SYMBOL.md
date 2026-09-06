# I5 continuous residual numerator symbol ledger

This ledger is local to the I5 continuous residual numerator work.  Its
mathematical authorities are
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-wall-tail]],
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail]],
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-local-panel]],
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
| `cell_width` | local scalar | $L=X_R-X_L$ | positive real scalar, length | `z.L` / center Rayleigh derivative | `L` in artifact |
| `circle_center_x` | fixed local scalar | $c_x=0$ in the frozen geometry | real scalar, length | configuration / distance and strip bound | none |
| `circle_center_y` | fixed local scalar | $c_y=0$ in the frozen geometry | real scalar, length | configuration / kernel coordinates | none |
| `eta_native` | frozen matrix | nodal map $q\mapsto(\tau,-\sigma)^T$ | complex $512\times194$ | `z.eta_unit_256` / density FFT | none |
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
| `ewald_eta` | future derived scalar | $\eta=(\kappa_e d/(2a_E))^2$, with $\kappa_e=k_{\rm outer}$ for the frozen exterior | nonnegative real scalar | physical inputs / M-I, M-T, M-L | none |
| `reciprocal_spacing` | future derived scalar | $b=2\pi/d$ | positive real scalar, inverse length | `period_y` / M-R | none |
| `reciprocal_cutoff` | future configuration scalar | $N_R$, retaining $\lvert m\rvert<N_R$ | positive integer scalar | fixed configuration / reciprocal finite part and tail | `N_R` only in equations |
| `image_cutoff` | future configuration scalar | $N_I$, retaining $0<\lvert j\rvert<N_I$ | positive integer scalar | fixed configuration / real-image finite part and tail | `N_I` only in equations |
| `taylor_cutoff` | future configuration scalar | $N$, retaining Ewald Taylor orders $0{:}N$ and local outer-series orders through $N$ | integer scalar at least $2$ | fixed configuration / M-T and M-L | `N` only in those equations |
| `local_z_radius` | future geometry scalar | $R_0\ge\sup_{\mathcal D}\lvert h^2(X^2+Y^2)\rvert$ | nonnegative real scalar | `self_tube_certificate` / M-L | `R_0` only in equations |
| `local_cauchy_radius` | future configuration scalar | $B>R_0$ in (M-L8)--(M-L13) | positive real scalar | fixed configuration / local factorial and derivative bounds | `B` only in M-L equations |
| `finite_nonwood_ledger` | future gate structure | every retained $q_m=\sqrt{(\beta+2\pi m/d)^2-\kappa_e^2}$, branch choice, $1/q_m$, and a positive non-Wood separation | per-order outward interval structure | frozen modal inputs / reciprocal finite part | none |
| `reciprocal_tail_gate` | future gate structure | both inequalities in (M-R-gate) on both tail rays | scalar logicals plus interval margins | M-R geometry and cutoff / tail authorization | none |
| `reciprocal_tail_ratios` | future gate array | $\rho_{\sigma,s}<1$ for $\sigma\in\{-,+\}$ and $s=0,1,2$ in (M-R-tail) | nonnegative real $2\times3$ | first omitted reciprocal terms / reciprocal tail | none |
| `image_tail_gate` | future gate structure | $N_Id>U_Y$, $u_{N_I}>0$, and $\rho_\alpha<1$ for $\alpha=0,1,2$ in (M-I-gate)--(M-I-tail) | scalar logicals and outward margins | geometry and `image_cutoff` / omitted-image tail | none |
| `retained_image_real_lower` | future gate vector | $u_j\le\inf_{\mathcal D}\operatorname{Re}z_j$ for every $0<\lvert j\rvert<N_I$ in (M-T-gate) | positive outward-lower vector | self-tube geometry / retained-image finite and Taylor terms | none |
| `taylor_poisson_tail` | future tail scalar | $\Pi_N(\eta)=e^\eta-\sum_{n=0}^N\eta^n/n!$ | nonnegative outward-upper scalar | `ewald_eta`, `taylor_cutoff` / M-T tail | none |
| `local_series_ratios` | future gate vector | $(\rho_J,\rho_S,\rho_D,\rho_Q)$ in (M-L8) | nonnegative real $1\times4$, each strictly below one | M-L parameters / local factorial tail | none |
| `reciprocal_finite_enclosure` | future finite structure | retained reciprocal value and coordinate derivatives through total order two | outward complex interval arrays | finite complex `erfc`, exponential, branch, and denominator evaluation / coordinate finite part | none |
| `nonzero_image_finite_enclosure` | future finite structure | retained $0<\lvert j\rvert<N_I$, $0\le n\le N$ real-image value and derivatives | outward complex interval arrays | finite $E_{n+1}$, exponential, and polynomial evaluation / coordinate finite part | none |
| `local_canonical_finite_enclosure` | future finite structure | branch-free ${\cal C}_{\eta,N}^{\rm can}$ and derivative bounds from (M-L7), (M-L12), (M-L13) | outward real or complex interval structure | finite entire series / coordinate finite part | none |
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
| `kernel_series_cutoff` | future configuration scalar | $N_E$ used to truncate each entire kernel series in (P14) | positive integer scalar | fixed configuration / kernel-series finite values and tails | not `taylor_cutoff` unless one shared value is explicitly frozen |
| `kernel_series_tail` | future remainder structure | $T_{E,r,N_E}(Q)$ and decreasing-ratio gates in (P14) for every required series and derivative | nonnegative outward-upper array plus logical gates | coefficient formulas and a certified $Q$ / all factor enclosures | none |
| `panel_half_width` | future configuration scalar | $\delta\le\min\{P_\Lambda/6,(2\kappa_*)^{-1},r_*/2\}$ | positive outward-upper scalar, length | geometry certificate / target-panel split | `delta` only in P11--P13 |
| `panel_taylor_order` | future configuration scalar | retained panel Taylor degree $M$ in (P11)--(P13) | nonnegative integer scalar | fixed configuration / retained singular and regular panel rules | never `mode_cutoff` |
| `periodic_log_moment_enclosure` | future finite vector | validated moments $\int_{-\delta}^{\delta}h^j\lambda(h)\,\mathrm dh$, $0\le j\le M$ | outward real interval vector | analytic recurrence or validated one-dimensional quadrature / (P11) | none |
| `singular_panel_derivative_upper` | future finite bound | $G_{M+1}\ge\sup\lvert\partial_h^{M+1}g_s(h)\rvert$ | nonnegative outward-upper scalar or per-row vector | curve/density derivative enclosures / (P12) | none |
| `singular_panel_remainder` | future remainder | right side of (P12), including $\mathfrak m_{M+1}$ | nonnegative outward-upper scalar or row vector | panel derivative bound / retained-row enclosure | none |
| `regular_panel_remainder` | future remainder | right side of (P13) | nonnegative outward-upper scalar or row vector | regular-factor derivative bound / retained-row enclosure | none |
| `off_diagonal_chord_lower` | future geometry bound | positive chord separation for each non-target panel | positive outward-lower array, length | embedded panel partition / off-diagonal derivative rule | none |
| `retained_target_row_remainder` | future remainder | validated target integration width for each retained arclength Fourier row, including the identity coefficient | nonnegative outward-upper row vector | target-panel Taylor enclosure / module finite part | never an inter-grid difference |
| `retained_local_row_enclosure` | future finite result | all singularity-subtracted retained value/normal local Fourier rows from (P11)--(P14) | outward complex interval row arrays | panel finite rules and remainders / module finite part | none |
| `density_linf_tau`, `density_linf_sigma` | future density bounds | $A_\tau^\infty,A_\sigma^\infty$ from (P16) | nonnegative outward-upper scalars | finite coefficient-map spectral norms / (P17)--(P29) | none |
| `identity_sigma_l2_upper` | future density bound | $A_{\sigma,0}^s$ in (P17) | nonnegative outward-upper scalar | `speed_upper`, `density_linf_sigma` / normal local tail | none |
| `identity_tau_second_l2_upper` | future density bound | $A_{\tau,2}^s$ in (P26) | nonnegative outward-upper scalar | $v_-,v_+,v_1$ and weighted tau coefficients / value local tail | none |
| `local_normal_action_upper` | future action bound | $M_N^{\rm act}$ in (P18) | nonnegative outward-upper scalar | $C_{\mathsf T}^\#,R_{\mathsf T}^\#,C_{\mathsf K^*}^\#,R_{\mathsf K^*}^\#$ and density bounds / (P19), (P20) | none |
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
| `density.orders` | frozen density orders $-128{:}127$ | 256-node FFT convention | independent of evaluation grid |
| `tau_coeff_map` | coefficient map of $\tau$ | `fftshift(fft(z.eta_unit_256(1:256,:)))/256` | no midpoint phase |
| `sigma_coeff_map` | coefficient map of $\sigma$ | negative of the stored second map because `zeta=-sigma` | sign changed exactly once |
| `configuration.boundary_node_count` | evaluation size $N$ | generated input; final value 512 | proof-driven quadrature tier, not a density solve |
| `configuration.retained_mode_cutoff` | finite cutoff $m-1$ | generated input; final value 255 | both $\ell=\pm256$ begin the tail |
| `local_complex_strip_certificate` | analytic normalized-chord contract | current circle adapter | shape-general fields, not a Bessel diagonalization |
| `local_factors` | real P3--P29 bounds | cancellation-safe certificate and series tails | P20/P29 fallback |
| `complex_strip_factor_bounds` | strip $C^\#,R^\#$ bounds | complex chord certificate and series tails | Kress alias and target rows |
| `maue_strip_factor_bounds.tau_prime_strip_upper` | $A'_{\tau,a}$ | weighted frozen density coefficients | derivative term in the actual normal center |
| `weighted_single_layer_log_upper`, `weighted_single_layer_smooth_upper` | $C_M,R_M$ in (P31M) | exterior/interior entire-series bounds | first Maue normal term |
| `tangent_derivative_log_upper`, `tangent_derivative_smooth_upper` | $C_{\partial F}^\#,R_{\partial F}^\#$ | target-tangent projection certificate | second Maue normal term after cotangent cancellation |
| `local_panel.value_rows`, `normal_rows` | local modal centers | Müller-combined Kress action | identity included once |
| `kress_log_alias_factor` | logarithmic factor in (P31) | $a,N$ | explicit remainder, not grid drift |
| `retained_target_row_remainder` | (P32) value-row radius | strip speed/action/phase bounds | independent target integration remainder |
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
