# I2.3 单轴离散 candidate 漂移实验设计

## 1. 状态、问题与结论边界

- Origin Skill: `academic-research-suite / experiment-agent`
- Design ID: `I2.3-NTOT-DRIFT-V1`
- Design Status: `FROZEN RESEARCHER--ENGINEER AGREEMENT / SKEPTIC DESIGN PASS`
- Freeze Date: `2026-08-14`
- Claim Boundary: `CONDITIONAL EMPIRICAL THREE-LEVEL DISCRETE-CANDIDATE DRIFT`

本实验只回答一个问题：在物理模型、trace cutoff、proxy、solver、branch、QZ frame、
fixed rows 和 candidate functional 全部不变时，只增加圆盘边界 Nyström 点数，I1--I2
识别的同一离散 mode candidate 是否发生可分辨漂移。输出是三个离散 candidate、各自的
算法定位区间，以及相邻层和首末层的 signed drift。

本实验不证明 candidate 是有限维精确实根，不证明 continuous guided mode、连续本征值、
收敛阶、误差来源、saturation、上界或后验 estimator。定位 uncertainty 只是下述冻结
dyadic locator 的终端网格不确定度，不是严格 root enclosure。很小的 resolved drift 和
nonmonotone trend 可以是有效科学结果；`DRIFT_UNRESOLVED` 必须停止 hierarchy exit、
报告 blocker，并令 I3 不可继续。不得为得到可分辨漂移移动窗口、改 functional 或增补
wide scan。

## 2. Authority、parents 与运行输入

项目级成功条件和 claim boundary 由
[[research/projects/eig-apost/implementation/i2/README|I2 project index]] 支配。I2.1 的
count-one 设计与审查由
[[research/projects/eig-apost/implementation/i2/design|I2.1 design]]、
[[research/projects/eig-apost/implementation/i2/review|I2.1 review]] 和
[[test/i2/k-count/README|I2.1 experiment index]] 组织；I2.2 仅作为 endpoint corroboration，
由 [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]]、
[[research/projects/eig-apost/implementation/i2/review-2-2|I2.2 review]] 和
[[test/i2/h-inertia/README|I2.2 experiment index]] 组织。

冻结科学谱系包括 I1.3 `zoom2` candidate/fixed rows、I1.4 sampled readiness、I2.1
conditional count one 和 I2.2 `inertia-a1` endpoint corroboration。parent artifact 与
current source identity 只由跑前静态审查核对，不进入 MATLAB runtime 合同。
I2.1 count-one 只附着于与其完全同配置的 $n_{\mathrm{tot}}=256$ fine parent；它不转移给
$n_{\mathrm{tot}}=160,208$ 两层，本阶段也不为这两层重跑 contour count。

正式 runner 不读取历史 MAT、Git、Markdown、review、freeze 或其他 human-facing metadata。
实现把本设计中的模型、selectors、levels 和阈值写成 test-local 常量，运行时只调用当前
MATLAB path 上的 evaluator 及真实数值依赖。I2.2 `inertia-a1` 不向 locator 提供数值输入；
它的 nearest-shoulder
interval 和 `SINGLE_JUMP` 只说明更窄区间内已有 same-evaluator corroboration；本实验使用
I2.1 圆盘的完整实直径，以避免用 I2.2 的更窄区间预选三层漂移。

compact result 只记录 MATLAB/version、实际解析的必要函数名和完整必要 config，不记录
human-facing hash、source digest 或历史 artifact identity。不得调用 `run_i21`，不得改
I1/I2.1/I2.2 source 或 output。MATLAB `lsqminnorm`、double precision、零 `pinv`、零
fallback、零 silent rank truncation 和零 method switch 是硬合同。

## 3. 唯一离散轴和三个 levels

唯一科学 refinement axis 是

```text
BOUNDARY_NYSTROM_NTOT_AT_FIXED_FINE_PROXY_M48
```

三个 levels 为 $n_{\mathrm{tot}}\in\{160,208,256\}$。完整逐字段合同如下：

| Field | level 160 | level 208 | level 256 | Semantics |
|---|---:|---:|---:|---|
| `level.name` | `fine` | `fine` | `fine` | fixed |
| `level.ntot` | 160 | 208 | 256 | sole scientific change |
| `level.N_side` | 160 | 160 | 160 | fixed fine proxy |
| `level.N_top` | 160 | 160 | 160 | fixed fine proxy |
| `level.N_proxy_edge` | 80 | 80 | 80 | fixed fine proxy |
| `level.M_pw` | 32 | 32 | 32 | fixed fine proxy |
| `M`, `K` | 48, 97 | 48, 97 | 48, 97 | fixed trace space |
| proxy shape/rank | $960\times450$, 260 | same | same | fixed seed chart |
| `A_QP` order | 320 | 416 | 512 | derived as $2n_{\mathrm{tot}}$ |
| pencil / $A_{\mathrm{def}}^D$ order | 194 | 194 | 194 | common coordinates |
| $A_{\mathrm{def}}^G$ order | 388 | 388 | 388 | common graph coordinates |

Physical parameters remain $\beta=0.5$, $d=1$, $R=0.2$, $s=1$,
$X_L=-0.5$, $X_R=0.5$, proxy height $1.1$ and proxy distance $0.2$. Fourier order,
unknown/row order, wall labels, normals, phase origins, square-root anchors, original/reversed QZ
semantics and fixed selectors remain identical.

The configuration passed to `eval_i21` may differ scientifically only in `level.ntot`.
`expected_bie_order=2*ntot` is runner-derived dimension metadata, not a second refinement axis.
Changing the Nyström quadrature weights and density dimension with `ntot` is part of this one axis.
No result may be attributed separately to quadrature weight, density order, proxy error or trace error.

Create the proxy/branch/QZ frame exactly once with the $n_{\mathrm{tot}}=256$ configuration at
$k_\star$. The proxy chart is independent of `ntot`, and every resulting scattering pencil remains
$194\times194$. Reuse this frame for all three levels and all point evaluations. A lower level that
does not continue safely from the common frame fails closed; it must not select a new QZ cluster,
rows, rank or branch.

## 4. Common candidate functional and raw transport

At every evaluated real $k$, let $A=A_{\mathrm{def}}^D(k)$. For the common Fourier orders define

$$
b_m=\sqrt{1+|\beta_m|^2},
\qquad
w_{r,m}=b_m^{-1/2},
\qquad
w_{c,m}=\left(b_m+\frac{|\gamma_m|^2}{b_m}\right)^{-1/2}.
$$

Repeat each weight vector for the two port blocks and set

$$
D_r=\operatorname{diag}(w_r,w_r),
\qquad
D_c=\operatorname{diag}(w_c,w_c),
\qquad
B=A_{\mathrm{phys}}=D_r A D_c.
$$

This is exactly the I1.3 physical weighting. Order singular values increasingly,
$\sigma_1\leq\sigma_2\leq\cdots\leq\sigma_{\max}$, and use the sole locator score

$$
s_1(k)=\frac{\sigma_1(B(k))}{\sigma_{\max}(B(k))}.
$$

Also record $r_{12}=\sigma_1/\sigma_2$ and all raw singular values. No seed scale changes either
ratio. If $Bv_1=\sigma_1u_1$, the raw port vector and raw left algebraic covector are

$$
q=D_cv_1,
\qquad
\ell^*=u_1^*D_r.
$$

The direction is important: the raw right vector is $D_cv_1$, not $D_c^{-1}v_1$. The left vector
is an algebraic residual covector and is not called a physical adjoint.

## 5. Fixed window and bounded dyadic locator

The common initial interval is the real diameter of the reviewed I2.1 disk:

$$
I_0=[k_\star-r_0,k_\star+r_0],
$$

$$
k_\star=1.8327703475952146,
\qquad
r_0=3.8146972647368216\times10^{-7}.
$$

Thus the initial five-point spacing is $h_0=r_0/2$. Each level runs its own locator but uses the
same deterministic rule:

1. On the current interval $I_j=[a_j,b_j]$, evaluate exactly the five points
   $a_j+(0{:}4)h_j$, where $h_j=(b_j-a_j)/4$. Cache exact $k$ values.
2. Every node must pass the structural gates in Section 7 before its score is selectable.
3. Let $s_{(1)}\leq s_{(2)}$ be the two smallest scores. Require
   $s_{(2)}-s_{(1)}>10^{-12}$ and require the unique minimizer to be one of the three interior
   nodes. This absolute $10^{-12}$ band is the sole score-tie rule.
4. The next interval is exactly the two-neighbor interval around that minimizer.
5. Do not extend the interval, fit a curve, interpolate, run golden-section/Newton, or import a
   minimum from another level.

Run levels $j=0,\ldots,11$ and stop normally at the first terminal layer with
$h_j\leq10^{-10}$. Here $h_{11}\simeq9.313\times10^{-11}$. A passing level evaluates 27 unique
points. The candidate is the terminal grid minimizer, its reported localization interval is its
two-neighbor interval, and

$$
u_{\mathrm{loc}}=h_{\mathrm{terminal}}.
$$

Store the terminal winner score, runner-up score and their absolute gap. The candidate repeat in
Section 8 checks deterministic recomputation of the selected point; it does not certify that the
winner--runner-up ordering would survive an unmodelled score perturbation.

An endpoint minimum, score tie, missing node, failed node gate or failure to reach the terminal
spacing gives `CANDIDATE_UNRESOLVED`. No alternate locator is allowed in the same attempt.

## 6. Phase/scale-invariant mode identity

### 6.1 Common physical representations

Split $q=(q_L,q_R)$ and let $E=\operatorname{diag}(e^{\mathrm i\gamma_m(X_R-X_L)})$. The common
left/right wall Dirichlet traces and their weighted concatenation are

$$
d_L=q_L+Eq_R,
\qquad
d_R=Eq_L+q_R,
\qquad
t=\begin{bmatrix}\sqrt b\,d_L\\ \sqrt b\,d_R\end{bmatrix}.
$$

The homogeneous missing-center column has no center density. Freeze the nine physical probes

$$
\mathcal P=\{(x,y):x,y\in\{-1/4,0,1/4\}\}.
$$

At each probe use the common Fourier reconstruction

$$
f(x,y)=\frac{1}{\sqrt d}\sum_m
\left[
q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}+
q_{R,m}e^{-\mathrm i\gamma_m(x-X_R)}
\right]e^{\mathrm i\beta_my}.
$$

Store the nine entries as $f_{\mathcal P}$. Primary participation requires

$$
\frac{\|t\|_2}{\|q\|_2}\geq10^{-3},
\qquad
\frac{\|f_{\mathcal P}\|_2}{\|q\|_2}\geq10^{-3}.
$$

For nonzero finite vectors define

$$
\rho(x,y)=\frac{|x^*y|}{\|x\|_2\|y\|_2}.
$$

Phase-align the higher level using the wall-trace inner product and apply the same unit-modulus
factor to $q$, $t$ and $f_{\mathcal P}$. The absolute overlap is already phase- and scale-invariant;
the aligned vectors are retained only as an audit.

### 6.2 Adjacent identity and competitor rule

For each adjacent pair $(160,208)$ and $(208,256)$ require

$$
\rho(t_a,t_b)\geq0.99,
\qquad
\rho(f_{\mathcal P,a},f_{\mathcal P,b})\geq0.99.
$$

The raw $q$ overlap and the direct $(160,256)$ trace/probe overlaps are reported but are not
additional hard gates. They cannot replace the adjacent physical checks.

Map the second right singular vector by the same rules,
$q_2=D_cv_2$, and construct $t_2$ and $f_{\mathcal P,2}$. Before normalization require both

$$
\frac{\|t_2\|_2}{\|q_2\|_2}\geq10^{-3},
\qquad
\frac{\|f_{\mathcal P,2}\|_2}{\|q_2\|_2}\geq10^{-3}.
$$

Nonfinite or smaller values produce `MODE_IDENTITY_UNRESOLVED`; the implementation must not
divide by zero or silently omit that representation. Equivalently it may conservatively set the
competitor overlap to one. For each adjacent pair define the switch diagnostic as the maximum of
the four bidirectional primary--secondary cross-overlaps in wall-trace and probe space. Require

$$
\rho_{\mathrm{switch}}\leq0.5.
$$

Together with $r_{12}\leq0.1$ at each candidate, this is the complete nearby-mode competition
gate. Classify an adjacent pair as `SAME_MODE` only when both primary overlaps and the competitor
gate pass. If the secondary representations are available and
$\rho_{\mathrm{switch}}>0.5$, classify the pair as `MODE_SWITCH`; this is a numerical diagnostic,
not a theorem that the continuous physical branch switched. All other failures, including an
unavailable secondary representation or failed primary overlap without a competitor crossing, are
`MODE_IDENTITY_UNRESOLVED`. Both non-`SAME_MODE` outcomes stop hierarchy qualification and I3
handoff. No larger mode-transport framework is added in I2.3.

### 6.3 Identity core oracle

The production normalization/overlap helper must first pass a deterministic dimension-two oracle:

- $e_1$ versus $10^8e^{\mathrm i\pi/7}e_1$ and versus
  $10^{-8}e^{-\mathrm i\pi/7}e_1$ has overlap within
  $10^{-14}$ of one;
- $e_1$ versus $e_2$ has overlap at most $10^{-14}$;
- zero, nonfinite and under-threshold vectors return unavailable rather than a number.

An oracle failure is `IDENTITY_ORACLE_FAIL` and stops before physical evaluation.

## 7. Node, near-null, factor, field and boundary gates

Every unique locator node must satisfy the unchanged `eval_i21` branch, proxy, BIE, QZ,
fixed-row, Dirichlet-chart, Schur, participation, solve-residual and factor gates. Every factor row
must be available and pass. The runner additionally checks the derived $A_{\mathrm{QP}}$ order $2n_{\mathrm{tot}}$,
proxy shape/rank, pencil order, graph order, row labels and frozen-frame fingerprints.

At each terminal candidate require

$$
s_1\leq10^{-3},
\qquad
r_{12}\leq0.1.
$$

The normalized SVD triplet residual is

$$
r_{\mathrm{svd}}=
\frac{\max\{\|Bv_1-\sigma_1u_1\|_2,
\|B^*u_1-\sigma_1v_1\|_2\}}
{\max(\operatorname{realmin},\sigma_{\max})},
$$

and must satisfy

$$
r_{\mathrm{svd}}\leq10^3(2K)\epsilon_{\mathrm{mach}}.
$$

Report the absolute raw residuals and require both raw backward errors

$$
r_R=\frac{\|Aq\|_2}{\|A\|_2\|q\|_2},
\qquad
r_L=\frac{\|\ell^*A\|_2}{\|A\|_2\|\ell\|_2}
$$

to be finite and at most $10^{-8}$. Denominators use `realmin` only to fail safely; a zero or
nonfinite vector is unavailable.

Using this same physical $q$, not the evaluator's separate raw-minimum vector, reconstruct

$$
c_-=D_-^{-1}[I,E]q,
\qquad
c_+=D_+^{-1}[E,I]q,
\qquad
z=(q,c_-,c_+).
$$

Require center and graph participation

$$
\frac{\min(\|q_L\|_2,\|q_R\|_2)}{\|q\|_2}\geq10^{-3},
\qquad
\frac{\min(\|c_-\|_2,\|c_+\|_2)}{\|z\|_2}\geq10^{-3}.
$$

With the existing fixed Dirichlet and Neumann row blocks $G_D,G_N$, require

$$
e_D=\frac{\|G_Dz\|_2}{\max(1,\|G_D\|_2\|z\|_2)}\leq10^{-10},
$$

$$
e_N=\frac{\|G_Nz-Aq\|_2}
{\max(1,\|G_N\|_2\|z\|_2+\|A\|_2\|q\|_2)}\leq10^{-10}.
$$

Record the full $A_{\mathrm{def}}^G$ kernel defect, but do not add a redundant kernel-defect hard
gate. Raw $Aq$, the two boundary defects and the existing graph-factor gates are authoritative.

## 8. Candidate repeat

After all three locators finish, recompute each terminal candidate once at the same $k$ and with
the same frozen frame. Require

$$
\frac{\|A_{\mathrm{repeat}}-A\|_F}{\max(1,\|A\|_F)}\leq10^{-12},
$$

$$
|s_{1,\mathrm{repeat}}-s_1|\leq10^{-12},
\qquad
\rho(q_{\mathrm{repeat}},q)\geq1-10^{-10}.
$$

The factor availability/pass pattern, dimensions, labels and fingerprints must match. A repeat
failure gives `CANDIDATE_UNRESOLVED`; it does not authorize a second locator or a looser tolerance.

## 9. Drift, severity, trend and hierarchy exit

For any qualified pair $a<b$, define

$$
\Delta_{ab}=k_b-k_a,
\qquad
D_{ab}=|\Delta_{ab}|,
\qquad
U_{ab}=u_a+u_b.
$$

Report $[\Delta_{ab}-U_{ab},\Delta_{ab}+U_{ab}]$ and $D_{ab}/U_{ab}$. Classification is

| Condition | Classification |
|---|---|
| $D_{ab}\leq U_{ab}$ | `DRIFT_UNRESOLVED` |
| $U_{ab}<D_{ab}\leq10^{-6}$ | `DRIFT_RESOLVED_SUBTARGET` plus sign |
| $D_{ab}>10^{-6}$ | `DRIFT_RESOLVED_SEVERE` plus sign |

The $10^{-6}$ severity scale is inherited from the I1 width goal. Because both candidates must
remain inside the same I2.1 real diameter, whose width is below $10^{-6}$, a two-candidate
`SEVERE` result is not expected to be reachable. A mode whose minimum reaches a window endpoint is
instead honestly `CANDIDATE_UNRESOLVED`; it is not relabelled non-severe.

Classify the two adjacent signed drifts as `MONOTONE` only when both are resolved and have the same
sign, `NONMONOTONE` only when both are resolved and have opposite signs, and `TREND_UNRESOLVED`
otherwise. Nonmonotonicity is not a failed experiment and does not establish asymptotic behavior.
Also report the direct $(160,256)$ drift with its combined uncertainty.

Failure precedence is:

1. runtime/configuration, oracle, resource or node failure;
2. `CANDIDATE_UNRESOLVED` at any level;
3. `MODE_SWITCH` or `MODE_IDENTITY_UNRESOLVED` if candidates exist but an adjacent identity gate
   does not establish `SAME_MODE`;
4. drift classifications only after all three candidates and both adjacent identities qualify.

Set `hierarchy_qualified=true` and `i3_may_proceed=true` only when both adjacent drifts are resolved,
both adjacent mode identities are `SAME_MODE`, and every candidate, factor, field, boundary and
repeat gate passes. `DRIFT_UNRESOLVED` is a valid experiment outcome, but it sets both flags false
because the observed shift cannot be separated from localization uncertainty. Resolved
`NONMONOTONE` drift may still form a qualified hierarchy without supporting a convergence trend.
Resolved `SEVERE` drift may also form a qualified hierarchy, but must set
`i3_status=MAY_PROCEED_WITH_SEVERE_DRIFT_LIMITATION` and cannot be described as stable or convergent.
Cases 1--3 set both flags false.

## 10. Cost, artifacts and formal command

There is one $n_{\mathrm{tot}}=256$ seed. Each level evaluates 27 unique points, for 81 unique
level-points total, followed by three candidate repeats. Cache exact $k$ values and keep at most
five dense nodes active per level. Stream scalar node/factor ledgers and retain dense matrices only
for the three candidates and their repeats.

- Soft target: `900 s`.
- Runner hard stop: `1800 s`.
- Active-memory hard gate: `512 MiB`.
- Whole I2.3 design--implementation--review--formal-run--post-review boundary: `3 h`.

If the remaining three-hour task budget cannot accommodate a reviewed formal run, stop with
`THREE_HOUR_BOUNDARY` rather than deleting gates, reducing levels, changing the window or retrying.
The runner hard stop is independent of this workflow boundary.

The implementation is test-local under `test/i2/k-drift/`, with the single entry point
`check_k_drift.m`. The sole formal tag is `drift-a1`; after an independent Skeptic authorizes the
frozen implementation, the intended MATLAB command is

```matlab
check_k_drift('drift-a1');
```

The runner must refuse an existing `output/drift-a1/` and must not retry the same tag. The compact
append-only output contains exactly `result.mat` and `report.md`. `result.mat` contains compact
configuration and runtime information, scalar node/factor ledgers, candidate matrices/vectors/fields,
identity diagnostics, repeats, drift classifications and first-failure data. Dense state from all
locator nodes must not be saved. Startup failure before the runner creates an artifact is recorded
from command output and counts against the time budget.

## 11. Failure taxonomy

| Code | Meaning | Scientific handling |
|---|---|---|
| `RUNTIME_OR_CONFIG_FAIL` | MATLAB, solver, function resolution or frozen configuration failed | stop before evaluation |
| `IDENTITY_ORACLE_FAIL` | common normalization/overlap helper failed | stop before evaluation |
| `SCIENTIFIC_NODE_GATE` | branch/proxy/BIE/QZ/chart/factor/node gate failed | no candidate at that level |
| `CANDIDATE_ENDPOINT` | minimum reached a frozen interval endpoint | `CANDIDATE_UNRESOLVED` |
| `CANDIDATE_TIE` | score separation was at most $10^{-12}$ | `CANDIDATE_UNRESOLVED` |
| `CANDIDATE_NEAR_NULL` | score, gap, SVD or raw backward gate failed | `CANDIDATE_UNRESOLVED` |
| `CANDIDATE_FIELD_BOUNDARY` | physical participation or boundary gate failed | `CANDIDATE_UNRESOLVED` |
| `CANDIDATE_REPEAT` | repeat gate failed | `CANDIDATE_UNRESOLVED` |
| `MODE_SWITCH` | an available secondary representation has cross-overlap above $0.5$ | no same-mode drift claim or I3 handoff |
| `MODE_IDENTITY_UNRESOLVED` | primary overlap, competitor or secondary participation failed | no same-mode drift claim |
| `DRIFT_UNRESOLVED` | drift does not exceed combined localization uncertainty | valid result; no qualified hierarchy and no I3 handoff |
| `HARD_TIME`, `MEMORY`, `THREE_HOUR_BOUNDARY` | resource contract stopped the workflow | preserve partial evidence; no retry or scope change |

An unlisted stop code is an implementation defect and cannot be converted into a scientific
outcome. Formal failure artifacts remain immutable.

## 12. Researcher--Engineer agreement and pending review

Researcher and Engineer explicitly agreed on `2026-08-14` to the following complete contract:

- the sole axis and levels are `ntot={160,208,256}` at fixed fine proxy and $M=48$;
- one $n_{\mathrm{tot}}=256$ seed frame is reused everywhere;
- I1.3 $A_{\mathrm{phys}}$ and the full I2.1 real diameter define the common locator;
- the five-point dyadic rule, $10^{-12}$ tie band, levels 0--11 and
  $u_{\mathrm{loc}}\leq10^{-10}$ are immutable;
- raw transport, $10^{-8}$ left/right backward gates, factor/field/boundary/repeat gates and exact
  SVD residual formula are frozen;
- adjacent wall/probe overlap $0.99$, competitor overlap $0.5$, secondary fail-close and the
  identity oracle are frozen;
- drift uncertainty, $10^{-6}$ severity scale, trend rules, 81+3 evaluation budget,
  `900/1800 s` and `512 MiB` are frozen;
- the result remains a conditional empirical discrete-candidate hierarchy only.

Agreement record:

```text
Researcher: AGREED — 2026-08-14
Engineer:   AGREED — 2026-08-14
```

Independent Skeptic design review returned `PASS WITH CONDITIONS` on `2026-08-14` and authorized
implementation only. This document does not authorize MATLAB execution by itself. The frozen
implementation still requires a separate pre-run Skeptic review. Any scientific or numerical
change requires an explicit appended revision, renewed Researcher--Engineer agreement, a new
implementation freeze and a new Skeptic review before the first formal run.
