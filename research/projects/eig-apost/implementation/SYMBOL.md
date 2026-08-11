# Symbol and code-variable ledger

## Cross-stage abbreviations and objects

本节由原 implementation overview 的速查表迁入；只集中已有定义，不改变各阶段原有数学
含义或 verdict。

| 缩写或代码名 | 全称 | 在本项目中的含义 |
|---|---|---|
| RQ | Research Question，研究问题 | 本专题要回答的单句问题；当前指 fixed-$\beta$ 线缺陷导模波数的后验误差估计。 |
| NEP | Nonlinear Eigenvalue Problem，非线性特征值问题 | 矩阵或算子 $F(k)$ 对谱参数 $k$ 非线性依赖，目标是寻找 $F(k)$ 的非平凡核。 |
| DtN | Dirichlet-to-Neumann map，Dirichlet 到 Neumann 映射 | 给定半波导边界 Dirichlet trace，返回面向中心区约定下的有符号 Neumann trace。 |
| RtR | Robin-to-Robin map，Robin 到 Robin 映射 | 将一组 Robin 边界数据映到另一组 Robin 数据；在 BIE/scattering 接口文献中作为 DtN 的替代坐标。 |
| BIE | Boundary Integral Equation，边界积分方程 | 用边界密度表示 center cell 或 one-cell scattering field。 |
| HG / hg-map | Half-guide / half-guide map，半波导映射 | 左或右半无限周期波导在中心截面上的反射或 DtN 对象；不是新的独立方程。 |
| EDC cell | 仓库旧代码和报告中的历史 fixture 标签；可靠英文展开未记录 | 本项目中具体指 $k=0.10$、折射率比 3、中心圆形介质夹杂的 one-cell BIE/scattering smoke fixture；不得仅凭缩写推断其他含义。 |
| QZ | Generalized Schur decomposition，广义 Schur 分解 | 当前主离散链中从 one-cell generalized pencil 计算 stable/unstable deflating subspaces；finite-tail/doubling 才只作 cross-check。 |
| SVD | Singular Value Decomposition，奇异值分解 | 用于提取最小奇异方向、数值秩和 seed-frozen proxy subspaces。 |
| CR | Cauchy--Riemann consistency，Cauchy--Riemann 一致性 | 诊断 complex-$k$ evaluator 是否表现为解析函数；有限差分通过不等于严格解析证明。 |
| $A_{\mathrm{QP}}$ | Quasiperiodic BIE matrix，准周期边界积分矩阵 | 由 proxy Green construction 生成的 center/cell BIE 离散矩阵。 |
| $\mathcal F(k)$ | Physical center--DtN operator function，物理中心域--DtN 算子函数 | 在 BIE representation、截断和 QZ 前定义；真实 guided eigenvalue 由 $\ker\mathcal F(k)\ne\{0\}$ 定义。 |
| $D_{s,M},N_{s,M}$ | Decaying Cauchy-data blocks，衰减 Cauchy 数据的 Dirichlet/Neumann blocks | 由右 stable、左 unstable ordered-QZ deflating subspaces 转换得到；只有 $D_{s,M}$ chart 安全时才形成 $N_{s,M}D_{s,M}^{-1}$。 |
| $F_{j,h}^{\mathrm{aug}}$ | Legacy augmented finite-tail matrix | 历史上把 center 和有限 tails 放在同一 block order；2026-08-11 后只作 cross-check/reference sequence。 |
| `GO` | 该阶段冻结的窄范围验收门通过 | 只对该阶段明确列出的离散对象有效，不能自动向后续阶段传播。 |
| `STOP` / `BLOCKED` | 上游条件未满足，后续量不可解释或不可计算 | 必须修复并重新审查；不得用调阈值或跳过检查绕过。 |

## Notation policy

This ledger is frozen before implementation. Each mathematical object has one primary code
name. The implementation may introduce local loop indices and file handles, but it may not
introduce a new mathematical object without first adding its meaning and reason here.

The representation tag is `manufactured-nep-v1`. Across levels, the matrix size, row and
column order, scaling, and the parameters $k_\star$, $\alpha$, $c$, and $q$ are invariant.
Only $j$, $N_j$, and $\varepsilon_j$ vary.

## Mathematical objects

| Mathematical object | Code variable | Type and scope | Meaning |
|---|---|---|---|
| $k$ | `k` | complex scalar, local | Spectral parameter supplied to the matrix callback. |
| $k_\star=k_\infty$ | `cfg.k_star` | real scalar, global config | Exact limit root of the manufactured hierarchy. |
| $s=k-k_\star$ | `s` | complex scalar, local | Shifted spectral parameter; introduced to keep the matrix formula readable. |
| $\alpha$ | `cfg.alpha` | complex scalar, global config | Fixed upper-right coupling that makes the matrix nonnormal. |
| $c$ | `cfg.curvature_c` | real scalar, global config | Fixed quadratic curvature in the target scalar factor. |
| $q$ | `cfg.second_diag_slope_q` | real scalar, global config | Fixed slope in the second diagonal factor. |
| $\theta$ | `cfg.theta` | real scalar, global config | Base of the manufactured doubling hierarchy. |
| $j$ | `level_j` | nonnegative integer | Hierarchy index. |
| $N_j=2^j$ | `n_cells` | positive integer, diagnostic | Doubling-depth label only; no physical cells are assembled. |
| $\varepsilon_j=\theta^{2^j}$ | `epsilon_j` | real scalar | Level-dependent map perturbation. |
| $F_j(k)$ | `F_level` | complex $2\times2$ matrix | Level matrix in the common representation. |
| $F_{j+1}(k)$ | `F_next` | complex $2\times2$ matrix | Fine-level evaluation at the coarse computed root. |
| $F_\infty(k)$ | `F_limit` | complex $2\times2$ matrix | Matrix with $\varepsilon=0$. |
| $F_j'(k)$ | `dFdk` | complex $2\times2$ matrix | Exact derivative with respect to $k$. |
| $\mathcal C$ | `contour_k` | complex vector | Counter-clockwise contour nodes. |
| $m_0$ | `root_count` | complex scalar | Argument-principle root count before integer qualification. |
| $m_1$ | `root_moment` | complex scalar | First argument-principle moment. |
| $m_1/m_0$ | `moment_seed` | complex scalar | Newton seed used only after the count-one gate. |
| $v_{\mathrm{bdr}}$ | `border_column` | complex vector | Fixed upper-right border from the scan-candidate left singular vector. |
| $w_{\mathrm{bdr}}$ | `border_row` | complex vector | Fixed lower-left border from the scan-candidate right singular vector. |
| $k_j$ | `k_root` | complex scalar | Computed qualified target root at level $j$. |
| $k_j^{\mathrm{ref}}$ | `k_exact_j` | complex scalar | Analytic target-branch oracle at level $j$. |
| $x_j$ | `x_right` | unit complex vector | Computed right singular direction. |
| $y_j$ | `y_left` | unit complex vector | Computed left singular direction. |
| $x_j^{\mathrm{ref}}$ | `x_exact` | unit complex vector | Analytic right null direction. |
| $y_j^{\mathrm{ref}}$ | `y_exact` | unit complex vector | Analytic left null direction. |
| $d_j=y_j^*F_j'(k_j)x_j$ | `root_slope` | complex scalar | Projected transverse derivative. |
| $\rho_j$ | `relative_root_residual` | nonnegative scalar | Smallest singular value divided by `max(1,norm(F_level,2))`. |
| $\delta_j^{\mathrm{root}}$ | `delta_root` | complex scalar | First-order correction for incomplete coarse root solve. |
| $\delta_j^{\mathrm{map}}$ | `delta_map` | complex scalar | Common-representation adjacent-level map correction. |
| $\delta_j^{\mathrm{tot}}$ | `delta_total` | complex scalar | Sum of root and map corrections. |
| exact $\delta_j^{\mathrm{map}}$ | `delta_map_oracle` | complex scalar | Analytic manufactured reference for the map correction. |
| $\eta_j$ | `eta_map` | nonnegative scalar | Magnitude of the empirical map correction. |
| $a_j=k_{j+1}-k_j$ | `root_increment` | complex scalar | Matched next-level root shift. |
| $c_j$ | `linearization_consistency` | nonnegative scalar | Relative mismatch between `delta_map` and `root_increment`. |
| $\mathcal I_j^{\mathrm{tail}}$ | `tail_effectivity` | nonnegative scalar | Estimator divided by exact manufactured coarse-tail error. |
| $\tau$ | `dip_tau` | positive scalar, negative case | Imaginary displacement in the real-axis-dip test. |

## Diagnostic variables

| Code variable | Meaning |
|---|---|
| `representation_id` | Must equal `manufactured-nep-v1` at every level. |
| `level_scale` | Scalar representation scale; frozen to 1 in the positive hierarchy. |
| `row_scale_fingerprint` | Two-entry row-scaling metadata; identical at every accepted level. |
| `column_scale_fingerprint` | Two-entry column-scaling metadata; identical at every accepted level. |
| `root_levels` | Frozen vector `0:4`. |
| `estimator_levels` | Frozen vector `0:3`. |
| `scan_candidate` | Real-axis minimum used only as a seed. |
| `scan_sigma_min` | Smallest singular value observed by the coarse real scan. |
| `contour_min_relative_sigma` | Minimum boundary separation over the contour nodes. |
| `newton_iterations` | Number of bordered Newton updates. |
| `newton_exit_reason` | Deterministic convergence or failure label. |
| `border_rcond` | Minimum reciprocal condition estimate of the bordered systems. |
| `left_residual` | `norm(y_left' * F_level,2) / max(1,norm(F_level,2))`. |
| `right_residual` | `norm(F_level * x_right,2) / max(1,norm(F_level,2))`. |
| `left_angle_error` | Phase-invariant sine of the principal angle to `y_exact`. |
| `right_angle_error` | Phase-invariant sine of the principal angle to `x_exact`. |
| `singular_values` | Singular values in MATLAB/Octave descending order. |
| `singular_gap` | Second-smallest singular value `singular_values(end-1)` divided by `max(1,norm(F_level,2))`; for this $2\times2$ matrix it is the largest singular value. |
| `derivative_spread` | Maximum relative spread of projected centered differences. |
| `derivative_exact_error` | Relative matrix error of a centered-difference derivative against `dFdk`. |
| `delta_map_oracle_error` | Complex map-correction error against `delta_map_oracle`. |
| `delta_total_sum_error` | Error in `delta_total = delta_root + delta_map`. |
| `delta_total_direct_error` | Error against a direct projection of `F_next`. |
| `gate_pass` | Boolean conjunction of all upstream gates for the current row. |
| `available` | Boolean indicating whether upstream gates permit the current quantity. |
| `failure_reason` | Stable failure label; empty only when the row passes. |
| `total_effectivity_collapses_to_tail` | Always true for this manufactured hierarchy. |

## Symbols deliberately not introduced

- No discretization index $h$ is used because the experiment has no BIE or port
  discretization.
- No saturation constant $\bar q$ or remainder bound $r_j$ is used because the experiment
  does not produce a reliable interval.
- No DtN, scattering, Rayleigh-channel, or BIE block symbol is used because those objects
  are outside the implementation boundary.

## Half-guide map Stage 1 ledger

This section applies only to `half_guide_map.md` and the corresponding Stage 1 experiment.
It does not alter the manufactured NEP meanings above.

### Representation invariant

At every doubling level, the channel count, Rayleigh ordering, amplitude meanings, phase
origins, basis normalization, and row and column scaling are identical. The scattering
block order is always `[R_L,T_RL;T_LR,R_R]`, mapping `[a_L;b_R]` to `[b_L;a_R]`. Only the
level and segment length change.

### Mathematical objects

| Mathematical object | Code variable | Scope and meaning | Reason retained |
|---|---|---|---|
| $m$ | `channels.m` | Rayleigh integer index | Standard channel label. |
| $\beta_m$ | `channels.beta_m` | Transverse quasiperiodic wavenumber | Required for the Wood gate. |
| $\gamma_m$ | `channels.gamma_m` | Longitudinal wavenumber with nonnegative imaginary part | Required for phases, Robin closure, and DtN. |
| $\Gamma$ | `Gamma` | Port derivative matrix; `diag(channels.gamma_m)` in Case B and `diag([1,2])` in Case A | Recurrent Cayley operator. |
| $E$ | `phase_matrix` | `diag(exp(1i*gamma_m*L))`, optional empty-cell sanity only | Non-governing block-order check. |
| $K$ | `channel_count` | Number of Rayleigh channels | Fixes every block dimension. |
| $\rho$ | `case_a.rho` | Two positive analytic reflection parameters | Defines the nondegenerate unitary gap oracle. |
| $r=\mathrm{i}\rho$ | `case_a.r` | Analytic diagonal reflection entries | Exact Case A one-cell reflection. |
| $t=\sqrt{1-\rho^2}$ | `case_a.t` | Positive analytic diagonal transmission entries | Exact Case A one-cell transmission. |
| $\vartheta$ | `case_a.theta_stable` | Stable multipliers `[1/2,1/3]` | Exact finite-QZ oracle. |
| $S$ | `segment` | Struct holding the four scattering blocks and metadata | Stable independent segment concept. |
| $R_L$ | `segment.R_L` | Left-wall reflection block | Fixed by the code convention. |
| $T_{LR}$ | `segment.T_LR` | Transmission from left input to right output | Fixed by the code convention. |
| $T_{RL}$ | `segment.T_RL` | Transmission from right input to left output | Fixed by the code convention. |
| $R_R$ | `segment.R_R` | Right-wall reflection block | Fixed by the code convention. |
| $A,B$ | `segment_a`, `segment_b` | Adjacent left and right segments during composition | Local composition roles only. |
| $G_A$ | `schur_a` | $I-R_R^A R_L^B$ | Noncommuting Schur factor with its own ledger row. |
| $G_B$ | `schur_b` | $I-R_L^B R_R^A$ | Noncommuting Schur factor with its own ledger row. |
| $j$ | `level_j` | Doubling level | Standard hierarchy index. |
| $N_j=2^j$ | `cell_count` | Number of cells represented by a doubled segment | Physical length label. |
| $C$ | `terminal_C` | Returned-to-outgoing terminal amplitude map | Unifies zero, Dirichlet, and Robin closures. |
| $\zeta$ | `cfg.robin_zeta` | Production real Robin parameter, frozen to `0.7` | Nonresonant third closure after the preserved smoke failure. |
| $\zeta_{\mathrm{res}}$ | `negative.robin_zeta` | Resonant value `1` used only by the negative case | Reproduces `TERMINAL_RESONANCE` without overloading the production parameter. |
| $\widehat R_{+,N}$ | `map_plus` | Right center-facing reflection map | Primary right half-guide map quantity. |
| $\widehat R_{-,N}$ | `map_minus` | Left center-facing reflection map | Primary left half-guide map quantity. |
| $\Lambda_{+,N}$ | `dtn_plus` | Right center-outward DtN matrix | Required Cayley output. |
| $\Lambda_{-,N}$ | `dtn_minus` | Left center-outward DtN matrix | Required Cayley output. |
| $A_{\mathrm{sc}}$ | `A_sc` | Left matrix of the generalized scattering pencil | Matches `bloch.solve_modes`. |
| $B_{\mathrm{sc}}$ | `B_sc` | Right matrix of the generalized scattering pencil | Matches `bloch.solve_modes`. |
| $\lambda$ | `lambda_qz` | Finite generalized Floquet multiplier | Stable/unstable classification variable. |
| $Z_s$ | `Z_stable` | Right stable generalized-Schur subspace | Defines the right invariant graph. |
| $A_s$ | `A_stable` | Top $K$ rows of `Z_stable` | Graph denominator for the right lead. |
| $B_s$ | `B_stable` | Bottom $K$ rows of `Z_stable` | Graph numerator for the right lead. |
| $Z_u$ | `Z_unstable` | Positive-$x$ unstable Schur subspace | Defines decay toward the left. |
| $A_u$ | `A_unstable` | Top $K$ rows of `Z_unstable` | Graph numerator for the left lead. |
| $B_u$ | `B_unstable` | Bottom $K$ rows of `Z_unstable` | Graph denominator for the left lead. |
| $R_+^{\mathrm{QZ}}$ | `qz_map_plus` | $B_s A_s^{-1}$, evaluated by a right solve | Same-cell right infinity reference. |
| $R_-^{\mathrm{QZ}}$ | `qz_map_minus` | $A_u B_u^{-1}$, evaluated by a right solve | Same-cell left infinity reference. |
| $r_{A,s},r_{B,s}$ | `qz.stable_deflating_residual` | Ordered stable deflating-subspace residuals | Fixes the QZ residual definition. |
| $r_{A,u},r_{B,u}$ | `qz.unstable_deflating_residual` | Ordered unstable deflating-subspace residuals | Fixes the QZ residual definition. |
| $\mathcal R_+$ | `qz.fixed_point_residual_plus` | Right reflection fixed-point residual | Cross-checks the invariant graph. |
| $\mathcal R_-$ | `qz.fixed_point_residual_minus` | Left reflection fixed-point residual | Cross-checks the invariant graph. |

### Naming protections

- Boundary geometry may retain the existing code name `C`; the terminal map must always
  be `terminal_C`, never `C`, in new code.
- The NEP parameter `cfg.second_diag_slope_q` above is unrelated to the half-guide Robin
  closure. No symbol $q$ is introduced in the Stage 1 design.
- MATLAB's `i` or a loop index must not represent the imaginary unit. New formulas and
  code use $\mathrm{i}$ and `1i`.
- A matrix quotient in the theory tables always means the stated left or right linear
  solve. It never authorizes `inv` or a change in multiplication order.

## Augmented BIE Stage 2 ledger

This section applies only to
[[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie|the Stage 2 augmented BIE design]].
It does not change the manufactured NEP or Stage 1 meanings above.

### Representation invariant

The representation identifier is eig-apost-aug-bie-v1.0. At every lead level, $n$, $p$,
the nine row and column blocks, channel order, phase origins, basis normalization, density
coordinate, center blocks, and terminal equations are identical. Only finite-lead
scattering blocks and the level label vary.

The column order is

$$
  (\xi,a_c^-,b_c^+,b_c^-,a_c^+,a_f^-,b_f^-,b_f^+,a_f^+).
$$

The row order is center BIE, center-left output, center-right output, left far output,
left center return, left Dirichlet, right center return, right far output, and right
Dirichlet.

### Center and augmented objects

| Mathematical object | Code variable | Meaning |
|---|---|---|
| $n$ | n_density | Center BIE block length. |
| $p$ | p_channels | Length of every Rayleigh amplitude block. |
| $\eta=(\tau,-\sigma)^{\mathsf T}$ | eta_physical | Physical Nyström density. |
| $D_h$ | density_scale | Positive diagonal density-coordinate matrix. |
| $\xi=D_h\eta$ | xi | Scaled center BIE unknown and first augmented block. |
| $A_c$ | A_c | Scaled center BIE matrix from op.construct_A_QP. |
| $B_L^{\mathrm{phys}},B_R^{\mathrm{phys}}$ | B_L_physical, B_R_physical | Raw incident_rhs outputs. |
| $B_L,B_R$ | B_L, B_R | Incident columns left-scaled by $D_h$. |
| $\mathcal E_L^{\mathrm{phys}},\mathcal E_R^{\mathrm{phys}}$ | E_L_physical, E_R_physical | Raw farfield_extractors outputs. |
| $\mathcal E_L,\mathcal E_R$ | E_L, E_R | Extractors right-scaled by $D_h^{-1}$. |
| $E_c$ | phase_center | Direct wall-to-wall Rayleigh phase. |
| $J_{LL},J_{LR},J_{RL},J_{RR}$ | J_LL, J_LR, J_RL, J_RR | Direct blocks with diagonal zero and cross blocks $E_c$. |
| $J_c$ | J_center | $\begin{bmatrix}0&E_c\\E_c&0\end{bmatrix}$. |
| $x_c$ | center_incoming | $(a_c^-,b_c^+)^{\mathsf T}$. |
| $y_c$ | center_outgoing | $(b_c^-,a_c^+)^{\mathsf T}$. |
| $S_c$ | S_center | Center scattering matrix in order $[R_L^c,T_{RL}^c;T_{LR}^c,R_R^c]$. |
| $F_{j,h}^{\mathrm{aug}}$ | F_aug | Primary square $(n+8p)$-dimensional matrix. |

### Termination and reduced objects

| Mathematical object | Code variable | Meaning |
|---|---|---|
| $\widehat R_{-,j}^{\mathrm D}$ | Rhat_minus_D | Dirichlet reflection seen from the left center port. |
| $\widehat R_{+,j}^{\mathrm D}$ | Rhat_plus_D | Dirichlet reflection seen from the right center port. |
| $R_j^{\mathrm D}$ | Rhat_block_D | Block diagonal of the two terminated maps. |
| $F_{j,h}^{\mathrm{red}}$ | F_reduced | $I_{2p}-R_j^{\mathrm D}S_c$. |
| $K_{ee},K_{er},K_{re},K_{rr}$ | K_ee, K_er, K_re, K_rr | Raw blocks for the independent Schur path. |
| $\mathcal B_{f,-,j}$ | far_block_minus | Left far block on $(a_f^-,b_f^-)$. |
| $\mathcal B_{f,+,j}$ | far_block_plus | Right far block on $(b_f^+,a_f^+)$. |
| $V_c$ | representation_stack | Tall stack $[A_c;\mathcal E_L;\mathcal E_R]$. |
| $\pi_\xi,\pi_c,\pi_f$ | participation_density, participation_center, participation_far | Density, center-port, and far-port fractions. |

### Diagnostics and availability

| Code variable | Meaning |
|---|---|
| representation_id | Must equal eig-apost-aug-bie-v1.0 at every level. |
| density_fingerprint | Frozen $D_h$ data and physical density convention. |
| phase_fingerprint | Channel order, $\gamma_m$, wall origins, and $E_c$. |
| relative_matrix_error | Frobenius relative matrix metric in aug-bie.md. |
| relative_solve_residual | Backward-style solve residual in aug-bie.md. |
| relative_homogeneous_residual | Normalized known-vector residual. |
| rank_tolerance | $10^{-10}\max(1,\lVert M\rVert_2)$. |
| primary_failure_reason | First failed stable gate in deterministic order. |
| all_failure_reasons | All failed stable labels in deterministic semicolon order. |
| raw_available | Primitive blocks permit storage of the raw augmented matrix. |
| elimination_available | Required center, terminal, and raw-Schur factors pass. |
| root_ready | Frozen to STOP in Stage 2. |

### Stable Stage 2 labels

- WOOD_POINT
- LEAD_BIE_POLE
- CENTER_BIE_POLE
- DOUBLING_POLE
- TERMINAL_RESONANCE
- RAW_SCHUR_POLE
- ZERO_FIELD_REPRESENTATION
- SCALING_COORDINATE_MISMATCH
- DIMENSION_OR_FINGERPRINT_MISMATCH
- BLOCK_ORDER_OR_SIGN_MISMATCH
- REDUCED_CROSSCHECK_UNAVAILABLE
- UNQUALIFIED_SINGULAR_CANDIDATE
- UNSCREENED_CENTER_BIE_INTERFACE_SMOKE
- STAGE2_DISCRETE_ALGEBRA_GO

### Stage 2 naming protections

- Code variables E_L and E_R represent $\mathcal E_L$ and $\mathcal E_R$; new Stage 2
  code must not reuse F_L or F_R because $F_{j,h}$ is the augmented matrix function.
- $E_c$ is only the direct phase and never an extractor.
- $R_j^{\mathrm D}S_c$ is the frozen order. The reversed product is only a negative case.
- Preserve the raw augmented matrix whenever finite primitive blocks exist, even if a
  conditional elimination fails. NaN is restricted to undefined derived quantities.
- Inverse notation in formulas never authorizes an explicit matrix inverse; use the
  stated linear solve.

## Root-readiness diagnostic ledger

This section applies only to
[[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness|the root-readiness design]]
and `test/root-ready/root_ready_diagnostic.m`. It records the corrected diagnostic
implementation and does not change the manufactured NEP, Stage 1, or Stage 2 meanings
above. The solver labels are `production_actual`, `pinv_default`, and
`ratio_rank_rseed` for the production output, mirrored pointwise solve, and selected
seed-frozen reduced chart, respectively.

### Production-interface boundary

The test constructs a mirrored $A_{\mathrm{pr}}(k),b_{\mathrm{pr}}(k)$ and compares
observable coefficients, proxy fields, residuals, and downstream objects with production
outputs. `kernel.precomp_proxy` does not expose its internal matrix or right-hand side.
Accordingly, gate `production_internal_A_b_identity` has `availability = false`, and its
stable reason is `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. No entrywise or bytewise
identity of the production-internal $A_{\mathrm{pr}},b_{\mathrm{pr}}$ is claimed.

### Stable objects and actual variables

| Mathematical or numerical object | Actual test variable | Scope and meaning |
|---|---|---|
| Mirrored $A_{\mathrm{pr}}(k)$ | `proxy_A`; local `A` | Matrix returned by `LOCAL_build_proxy_system`; it is not the unexposed production-internal matrix. |
| Mirrored $b_{\mathrm{pr}}(k)$ | `proxy_b`; local `b` | Right-hand side returned by `LOCAL_build_proxy_system`; it is not the unexposed production-internal right-hand side. |
| Production proxy and coefficients | `production_proxy`, `production_coefficients`; local `production_c` | Observable output of `kernel.precomp_proxy` and its flattened coefficient vector. |
| Mirrored pointwise coefficients | `c_pinv` | `pinv(A) * b` for the mirrored system; compared with `production_coefficients`. |
| Explicit full-SVD coefficients | `c_svd` | Minimum-norm coefficient vector formed from the current thin SVD. |
| $U_0,\Sigma_0,V_0$ | `U_seed`, `s_seed`, `V_seed`; `seed_data(ic).U`, `.s`, `.V` | Thin SVD at the fixed real seed `cfg.k_seed`. |
| $r,U_r,V_r$ | `ratio_rank`, `U_r`, `V_r` | Rank selected once by `cfg.ratio_rank_threshold` and the corresponding frozen seed columns. |
| $U_r^*A_{\mathrm{pr}}V_r$, $U_r^*b_{\mathrm{pr}}$ | `reduced_A`, `reduced_b` | Reduced Petrov--Galerkin system at the current $k$. |
| $a_r(k),c_r(k)=V_ra_r(k)$ | `a_r`, `c_r` | Reduced and lifted coefficients for `ratio_rank_rseed`. |
| $U_rU_r^*,V_rV_r^*$ | `P_left`, `P_right`; `results.projectors(idx).left`, `.right` | Phase-invariant frozen projectors for the base or refined proxy configuration. |
| Projector representation fingerprint | `projector_fingerprints`; `results.projector_fingerprints` | Rank, dimensions, traces, Frobenius norms, idempotence errors, weighted checksums, and left/right SHA-256 values written to `projector-fingerprint.csv`. |
| Sampled proxy field | `production_field`, `ev.field` | Stacked Green potential, gradient, and Hessian samples returned by `LOCAL_field_vector`. |
| Defect/bulk $A_{\mathrm{QP}}$ | `A_QP`; `data.A_QP` | Correctly scaled center BIE matrix used only for the downstream object comparison. |
| Defect/bulk $R_L,T_{LR},T_{RL},R_R$ | `data.R_L`, `.T_LR`, `.T_RL`, `.R_R` | Corrected scattering blocks compared between production and selected proxy paths. |

### Residual and compatibility diagnostics

| Diagnostic | Actual test variable or field | Definition or role |
|---|---|---|
| $r_{\mathrm{pr}}=A_{\mathrm{pr}}c-b_{\mathrm{pr}}$ | `residual` | Mirrored-system residual for the coefficient vector under evaluation. |
| Projected residual | `projected_residual`; `ev.projected_residual` | Normalized residual of `reduced_A * a_r = reduced_b`; unavailable for the production-output row. |
| $r_{\mathrm{full}}$ | `full_residual`; `ev.full_residual` | `norm(residual,2) / max(1,norm(b,2))`. |
| $r_{\mathrm{fullsys}}$ | `ev.full_system_backward` | `norm(residual,2) / max(1,norm(A,2)*norm(coefficients,2)+norm(b,2))`. |
| Shifted off-collocation residuals | `off_rows`; fields `qp_value_residual`, `qp_derivative_residual`, `top_value_residual`, `top_derivative_residual`, `bottom_value_residual`, `bottom_derivative_residual`, `combined_residual` | Independent half-grid-shifted diagnostics with no post-hoc pass threshold. |
| Coefficient-output mismatch | `production_coefficient_error`; aggregate `constructor_observed` | Mirrored `pinv_default` coefficients versus `production_actual` coefficients. |
| Proxy-field-output mismatch | `production_proxy_field_error`; aggregate `constructor_field_observed` | Mirrored and production Green potential/gradient/Hessian output vectors. |
| Residual-output mismatch | `residual_identity`; aggregate `residual_observed` | Absolute difference of production and mirrored normalized full residuals. |
| Base/refined Green compatibility | `resolution_rows`; fields `green_pot_diff`, `green_grad_diff`, `green_hess_diff`, `status` | Per-node selected-chart comparison; every row is `PASS` or `FAIL`. |
| Production/selected object compatibility | `downstream_rows`; fields `geometry`, `quantity`, `relative_difference`, `status` | Per-object comparison for Green potential/gradient/Hessian, defect/bulk $A_{\mathrm{QP}}$, and all four scattering blocks. |
| Aggregate object gates | `resolution_observed`, `downstream_observed`, `all_object_observed`; corresponding `*_pass` variables | Maxima and Boolean conjunctions used by the three object-compatibility gates. |
| Unchanged-source reproducibility | `results.repro_vector`, `results.reproducibility` | Numeric-vector, direct-source-manifest, and projector-fingerprint repeat checks. |

All relative matrix and field differences use `LOCAL_relmat(actual, expected)`, namely
the Frobenius norm of `actual - expected` divided by
`max(1,norm(expected,'fro'))`.

### Fixed thresholds

| Purpose | Actual variable | Frozen value |
|---|---|---|
| Ratio-rank selection | `cfg.ratio_rank_threshold` | `1e-8` |
| Three observable mirrored-output gates | `cfg.constructor_tol` | `1e-11` |
| Every Green, $A_{\mathrm{QP}}$, and scattering compatibility row | `cfg.object_compatibility_tol` | `1e-5` |
| Unchanged-source numeric repeat | `results.reproducibility.tolerance` | `1e-13` |

There is no threshold for `off_collocation_readiness`; it remains unavailable with
`PENDING_REVIEW`. Projector repeatability requires equal non-placeholder SHA-256 values
through `projector_fingerprints_equal` and also includes its numeric fingerprint fields
in `results.repro_vector`.

### Stable gates and status labels

| Gate | Stable failure or unavailability label |
|---|---|
| `production_internal_A_b_identity` | `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE` |
| `mirrored_constructor_coefficient_output_reproduction` | `MIRRORED_CONSTRUCTOR_COEFFICIENT_OUTPUT_REPRODUCTION_FAILURE` |
| `mirrored_constructor_proxy_field_output_reproduction` | `MIRRORED_CONSTRUCTOR_PROXY_FIELD_OUTPUT_REPRODUCTION_FAILURE` |
| `mirrored_constructor_residual_output_reproduction` | `MIRRORED_CONSTRUCTOR_RESIDUAL_OUTPUT_REPRODUCTION_FAILURE` |
| `off_collocation_readiness` | `PENDING_REVIEW` |
| `object_compatibility_resolution` | `OBJECT_COMPATIBILITY_RESOLUTION_FAILURE` |
| `object_compatibility_downstream` | `OBJECT_COMPATIBILITY_DOWNSTREAM_FAILURE` |
| `object_compatibility_all` | `OBJECT_COMPATIBILITY_FAILURE` |
| `source_provenance` | `SOURCE_PROVENANCE_FAILURE` |

Individual computed-object rows use only `PASS` or `FAIL`; solver rows use `COMPUTED` or
`UNAVAILABLE`. The diagnostic-level labels are `PROXY_DIAGNOSTIC_COMPLETE`,
`BLOCKED_UPSTREAM_PROVENANCE`,
`BLOCKED_MIRRORED_CONSTRUCTOR_OUTPUT_REPRODUCTION`, and `STOP`. Dormant scan, disk,
Cauchy--Riemann, root, Newton, adjacent-level, and estimator stages are
`NOT_RUN_UPSTREAM_STOP`. Reproducibility uses `BASELINE_CREATED`,
`REPRODUCIBILITY_FAILURE`, or `REPRODUCED`.

## Provenance-closure addendum ledger

This section applies only to the pre-execution addendum in
[[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness|the Root-readiness design]]
and the future `test/root-ready/provenance-closure/` experiment. It does not alter the
manufactured NEP, Half-guide Stage 1, Augmented BIE Stage 2, or completed controlled-
diagnostic meanings above.

### Necessary notation distinction

The source-exact test-local copy returns
$A_{\mathrm{pr}}^{\mathrm{copy}}(k)$ and
$b_{\mathrm{pr}}^{\mathrm{copy}}(k)$. The `copy` superscript is introduced only to keep
these returned arrays distinct from the unmodified package's internal arrays, which are
not directly observable. No symbol is introduced for those unobserved arrays.

Gate `production_internal_A_b_identity` therefore retains
`availability = false` and status `NOT_DIRECTLY_OBSERVED`, with stable reason
`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. The new operational gate has a different name
and must never overwrite or alias this field.

### Source-copy and shared-system variables

| Mathematical or numerical object | Frozen code variable or artifact | Scope and meaning |
|---|---|---|
| Source-exact copied helper | `LOCAL_precomp_proxy_instrumented` | Test-local function copied from the frozen package; it may differ executably only in its declaration. |
| Package public output | `proxy_package` | Observable `kernel.precomp_proxy` result used only as a same-process anchor. |
| Copied public output | `proxy_copy` | Public proxy struct returned by the source-exact copy. |
| $A_{\mathrm{pr}}^{\mathrm{copy}}(k)$ | `A_shared` | Collocation matrix returned from the copied function and passed unchanged to every comparison solver. |
| $b_{\mathrm{pr}}^{\mathrm{copy}}(k)$ | `b_shared` | Right-hand side returned from the copied function and passed unchanged to every comparison solver. |
| Copied production-path coefficients | `coeffs_copy` | Existing local `coeffs` returned by the copied function. |
| Flattened copied proxy coefficients | `coeffs_from_proxy_copy` | `[proxy_copy.q(:); proxy_copy.C_up(:); proxy_copy.C_down(:)]`; bitwise cross-check for `coeffs_copy`. |
| Shared matrix raw-byte fingerprint | `A_shared_sha256` | SHA-256 of the frozen raw-byte payload for `A_shared`. |
| Shared right-hand-side raw-byte fingerprint | `b_shared_sha256` | SHA-256 of the frozen raw-byte payload for `b_shared`. |
| Package full-source fingerprint | `package_source_sha256` | Must equal `3a16825064e5762f3486373fee702e94c34fa3cfdfb3b774f78f3b27eb2f9a60`. |
| Package executable-body fingerprint | `package_body_sha256` | Must equal `eb116bc9a359b9a50d6804891939cdfeb2b6a17eacb8a6a2a3a8e7d29bebd82c`. |
| Copied executable-body fingerprint | `copy_body_sha256` | Must equal `package_body_sha256` before any numerical gate runs. |
| Raw package body bytes | `package_body_bytes` | Binary-mode `uint8` span from the frozen configuration marker through the newline after `proxy.C_down`; no EOL normalization or text recoding. |
| Raw copied body bytes | `copy_body_bytes` | Binary-mode `uint8` span with the same markers; compared and hashed directly against `package_body_bytes`. |
| Environment solver branch | `minimum_norm_solver_branch` | Same-process result of `exist('lsqminnorm','file')`; identical for package and copied calls. |
| Source-copy transform record | `source_transform` | Exact declaration change plus non-executable help-text allowance; no arithmetic-body change. |
| Synthetic mutation result | `synthetic_source_mutation` | In-memory `1i/4` to `1i/5` mutation that must be rejected without execution. |
| Cached frequency record | `system_cache(ic,ik)` | Sole package/copy call record at one proxy configuration and frequency; contains public outputs and the copied `A_shared`, `b_shared`, and `coeffs_copy`. |
| Cached seed index | `seed_index` | Unique index satisfying `cfg.k_nodes(seed_index) == cfg.k_seed`; its cached `A_shared` supplies the seed SVD without a second constructor call. |
| Frozen solver labels | `cfg.expected_solver_labels` | Exact ordered set `package_public_anchor`, `copy_production`, `pinv_default`, `explicit_svd_pinv_tol`, `ratio_rank_rseed`. |
| Expected row counts | `cfg.expected_shared_rows`, `cfg.expected_solver_rows_per_system`, `cfg.expected_solver_rows` | Respectively `6`, `5`, and `30`; used for bidirectional exact coverage. |
| Primary Green source | `cfg.primary_source` | Frozen value `[0,0]`, serialized in `config.txt` as a cross-check of the unchanged hardcoded `src` in the source-exact body; it is not a new function input. |
| Green probe arrays | `cfg.green_sources`, `cfg.green_targets` | Frozen $2\times3$ source and $2\times4$ target matrices used by the value/gradient/Hessian comparison. |
| Channel-order identifier | `cfg.channel_order` | Stable label `RAYLEIGH_NATIVE_ORDER`; no channel permutation is allowed between objects or runs. |
| Density-scaling identifier | `cfg.density_scaling` | Stable text containing the exact `h`, `speed`, and `density_scale` formulas frozen in the design. |
| Shifted residual identifier | `cfg.off_collocation_rule` | Stable label `SHIFTED_DENSIFIED_MIDPOINT_2X`; diagnostic-only and never a solver collocation system. |
| Historical projector comparison | `historical_projector_comparison` | Non-gating row-matched report against read-only `test/root-ready/output/results.mat`, including availability, rank/dimensions, relative differences, and recomputed raw-byte equality. |
| In-progress evidence root | `cfg.staging_output_root` | `test/root-ready/provenance-closure/output.inprogress/`; the only writable output tree before final publication. |
| Final evidence root | `cfg.output_root` | `test/root-ready/provenance-closure/output/`; created only by the final atomic rename. |
| Required artifact set | `cfg.required_artifacts` | Exact per-run list frozen in the design, including `historical-projector.csv` and `completion.marker`. |
| Completion marker | `completion.marker` | Last file written in a validated run bundle; records version, run, artifact-bundle pass, final label, and non-marker artifact SHA-256 values. |

The raw-byte payload used for `A_shared_sha256` and `b_shared_sha256` starts with class,
dimensions, and machine-endianness metadata. It then appends the raw IEEE-754 bytes of
the column-major real part followed by the raw bytes of the column-major imaginary part.
It never hashes MAT-file serialization.

### Source-copy gate variables

| Gate | Boolean or observed field | Frozen meaning |
|---|---|---|
| `package_source_lock` | `package_source_lock_pass` | Full package source has the pre-registered SHA-256. |
| `source_exact_copy_body` | `source_exact_copy_body_pass` | Copied executable block is byte-identical and has the frozen body hash. |
| `source_copy_context_independence` | `source_copy_context_independence_pass` | Forbidden name/output-count/stack/random/global/dynamic-evaluation constructs are absent and the solver branch is shared. |
| `execution_manifest_complete` | `execution_manifest_complete_pass` | Every direct-call manifest path is a distinct existing regular file with a valid lowercase SHA-256 and no sentinel digest. |
| `package_copy_public_output_bitwise` | `package_copy_public_output_bitwise_pass` | Fields `q`, `Z`, `H`, `C_up`, and `C_down` are bitwise equal. |
| `copy_coefficients_bitwise` | `copy_coefficients_bitwise_pass` | `coeffs_copy` and `coeffs_from_proxy_copy` are bitwise equal. |
| `shared_A_b_raw_fingerprints` | `shared_A_b_raw_fingerprints_pass` | Exact bidirectional row coverage holds and every one of the five solver rows stores its unique constructor's `A_shared_sha256` and `b_shared_sha256`. |
| `synthetic_source_mutation_rejected` | `synthetic_source_mutation_rejected_pass` | The deterministic arithmetic-token mutation triggers the body-mismatch gate before execution. |
| `two_run_reproducibility` | `two_run_reproducibility_pass` | Numeric, source/body, manifest, shared-array, and projector evidence agrees between the preserved baseline and repeat. |
| `artifact_bundle_complete` | `artifact_bundle_complete_pass` | The closed log and all frozen artifacts pass staging-tree validation before the completion marker and atomic publication. |
| Source-derived aggregate | `source_derived_shared_A_b_provenance_pass` | Conjunction of every required provenance, manifest, unchanged numerical, object, negative, reproduction, and artifact-bundle gate. |

The three existing `mirrored_constructor_*_output_reproduction` gate names retain
threshold `cfg.constructor_tol = 1e-11`. The resolution and per-object compatibility
gates retain `cfg.object_compatibility_tol = 1e-5`. The ratio-rank rule remains
`cfg.ratio_rank_threshold = 1e-8`, and two-run numeric reproduction remains `1e-13`.
No new threshold is assigned to off-collocation readiness.

### Stable provenance-closure labels

| Gate or state | Stable label |
|---|---|
| Unobserved production-internal arrays | `NOT_DIRECTLY_OBSERVED` with reason `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE` |
| Package full-source mismatch | `PACKAGE_SOURCE_DRIFT` |
| Copied executable-body mismatch | `SOURCE_COPY_BODY_MISMATCH` |
| Forbidden context dependence | `SOURCE_COPY_CONTEXT_DEPENDENCE` |
| Missing, failed, duplicate, or invalid direct-call manifest record | `EXECUTION_MANIFEST_INCOMPLETE` |
| Public package/copy output mismatch | `PACKAGE_COPY_PUBLIC_OUTPUT_MISMATCH` |
| Copied coefficient extraction mismatch | `COPY_COEFFICIENT_EXTRACTION_MISMATCH` |
| Shared-array fingerprint mismatch | `SHARED_A_B_FINGERPRINT_MISMATCH` |
| Synthetic mutation not rejected | `SOURCE_MUTATION_NOT_REJECTED` |
| Two-run mismatch | `PROVENANCE_REPRODUCIBILITY_FAILURE` |
| Missing, partial, inconsistent, unmarked, or unpublished artifact bundle | `ARTIFACT_BUNDLE_INCOMPLETE` |
| Operational aggregate pass | `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS` |

`SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS` means only that the frozen copied arithmetic
is source-exact, its public output is a same-process bitwise match to the package, and all
test-local comparison solvers consume one fingerprinted returned pair. It never means
`production_internal_A_b_identity = true` and never authorizes a complex disk, root,
eigenvalue, correction, estimator, effectivity, or certification claim.

## I4 analytic root-readiness ledger

This section applies only to
[[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-readiness|the I4 full analytic complex-wavenumber Root-readiness design]]
and the corresponding test-local experiment.
It does not change the I0--I3 meanings above.

### Representation invariant

The representation identifier is `eig-apost-i4-readiness-v1.0`. Within one frozen
chart, the two ellipse geometries, density coordinate, port/proxy orders, branch seed and
mode ordering, proxy rank and projectors, nine augmented row/column groups, terminal
closure, and matrix dimensions are fixed. Only the sampled $k$ and finite-tail level
$j\in\{0,3,4\}$ vary.

The implementation label is `SOURCE_DERIVED_BRANCH_INJECTED_TEST_EVALUATOR`. It is not
a source-exact copy of package arithmetic and does not alter the I3 status
`production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED`.

### Mathematical objects and code variables

| Mathematical or numerical object | Required code variable | Meaning |
|---|---|---|
| real locator center $k_c$ | `candidate_center` | Final strict-interior real locator after two frozen refinements. |
| port/proxy orders $m$ | `branch_orders` | Frozen integer ordering for one branch provider. |
| $\beta_m$ | `branch_beta_m` | Frozen transverse wavenumbers in the same order. |
| seed $\gamma_{m,c}$ | `branch_gamma_seed` | Physical outgoing/decaying values selected once at $k_c$. |
| continued $\gamma_m(k)$ | `branch_gamma` | Anchored logarithmic continuation supplied to every consumer. |
| branch descriptor | `branch_fingerprint` | Seed, order, formula, provider source, and raw-value fingerprint. |
| $A_{\mathrm{pr}}(k),b_{\mathrm{pr}}(k)$ | `proxy_A`, `proxy_b` | Test-local branch-injected proxy collocation system. |
| $U_r,V_r,r$ | `proxy_U`, `proxy_V`, `proxy_rank` | One seed-frozen Petrov--Galerkin chart. |
| $a_r,c_r$ | `proxy_reduced_coefficients`, `proxy_coefficients` | Reduced and lifted fixed-chart coefficients. |
| $r_P,r_{P,\mathrm{back}},r_{\mathrm{full}}$ | `proxy_projected_residual`, `proxy_projected_backward`, `proxy_full_residual` | Frozen collocation residual definitions. |
| shifted residuals $r_q,r_{\mathrm{off}}$ | `off_block_residuals`, `off_combined_residual` | `SHIFTED_DENSIFIED_MIDPOINT_2X` branch-injected diagnostics. |
| candidate disk $\mathcal D(k_c,r)$ | `candidate_disk` | One attempt among $r_0,r_0/2,r_0/4$. |
| disk attempt state | `disk_attempt` | Radius index, node coverage, first failure, and acceptance state. |
| $F_{j,h}^{\mathrm{aug}}(k)$ | `F_aug` | Fixed $240\times240$ test-local augmented matrix. |
| $s(k)$ | `relative_sigma_min` | Real locator or boundary separation diagnostic only. |
| maximum $e_{ab}$ | `relative_full_F_chart_spread` | Maximum pairwise full-matrix spread over the declared chart/node/level scope. |
| $D_x,D_y,e_{\mathrm{CR}}$ | `derivative_real`, `derivative_imag`, `cr_defect` | Full-$F$ centered-difference analytic-consistency diagnostics. |
| factor/pole record | `factor_ledger` | Role, raw-inversion flag, rcond, residual, availability, and failure. |
| mandatory negative record | `negative_cases` | Exact N1--N11 outcome and whether the common checker rejected it. |

### Stable I4 labels

- `SOURCE_DERIVED_BRANCH_INJECTED_TEST_EVALUATOR`
- `NO_SCREENED_DIP`
- `REPRESENTATION_DRIFT`
- `SCALING_COORDINATE_MISMATCH`
- `PROXY_COMPRESSION_POLE`
- `FULL_F_CR_DEFECT`
- `HIDDEN_INTERIOR_POLE_UNEXCLUDED`
- `ZERO_FIELD_REPRESENTATION`
- `CIRCLE_LEAD_INTERFACE_SMOKE`
- `SAMPLED_DOMAIN_AVAILABLE`
- `ROOT_READINESS_SAMPLED_DISCRETE_STOP`
- `ROOT_READINESS_SAMPLED_DISCRETE_GO`

`ROOT_READINESS_SAMPLED_DISCRETE_GO` authorizes only a separately frozen I5 design.
Every I4 outcome retains `PHYSICAL_ROOT_READY=STOP`; no I4 variable represents a root,
eigenvalue, correction, estimator, effectivity, or certified interval.
