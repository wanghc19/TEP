# Symbol and code-variable ledger

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
