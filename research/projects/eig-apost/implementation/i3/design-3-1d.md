# I3.1 BIE 安全带全波导弱残量设计

## 摘要与状态

- **Design ID:** `I3.1-BIE-COLLAR-Q1-RT0-V3`
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `DESIGN PASS`
- **Implementation:** `COMPLETE / AWAITING SPEC-TO-CODE REVIEW`
- **Run:** `NOT AUTHORIZED`

本设计只研究 I2 算法实际保存的 candidate

$$ \widehat k_h=1.832770289108157, \qquad \mu_h=\widehat k_h^2=3.3590469326375971. $$

目标是从真实 one-cell BIE incoming data 重建左右无限 lead 中的数值场，再构造一个明确属于
$H^1_\beta(B)$ 的全波导试验场，并计算直接面向连续算子的 weak-residual estimator
candidate。finite-matrix zero 和 score minimizer 都不是本设计对象。

历史 `lead-a3` 的 direct close evaluation 未资格化，历史 `weak-a1` 的 Q1 cell-extension
majorant 又停在 scale-covariant Gram 门。两者都是保留不改的负向基线；本文不修改它们的
design、代码或 output。新路线保留 BIE 胞内形状，但只在离材料圆有固定安全距离的位置直接
求值；近圆节点由可靠的单侧圆周 trace 和安全圆周数据填充。最后用单一 periodic-gauge Q1
函数连接所有数据，因此送入谱残量命题的是 conforming companion，不是 raw BIE 分片场。

本文普通双精度实验至多形成
`COMPUTED_CONTINUOUS_WEAK_RESIDUAL_ESTIMATOR_CANDIDATE`。在 residual、field norm、tail 和
projected gap 没有可靠外包围前，不得声称连续离散特征值存在、candidate 误差上界或特定 mode
身份。

| 路线 | 裁决及原因 |
|---|---|
| exact cell/$P$ | Fliss 的 exact 基准；finite QZ $P_\pm$ 只参数化 trial，不继承 exact 定理。 |
| raw BIE strong residual | 近边界求值未资格化，raw 分片场也不 conforming，不选。 |
| conforming weak residual + majorant | 直接作用于 continuous form 且允许保留 BIE 胞内形状，选定。 |
| finite Riesz / 同链 reference | 缺 reliable dual-norm upper bound 或与当前链共享 bias，不作主线或 I3.2 reference。 |

原文位置见 [[ref/ref_data/Fliss2013.pdf|Fliss (2013) original]] Theorem 4.12 及
(4.9)--(4.10)、(4.16)；其 exact/numerical 边界见
[[research/projects/eig-apost/phase3-analysis/s-lead-field|lead-field analysis]]。

## 1. 连续对象和计算目标

固定波导与材料

$$ B=\mathbb R\times(-1/2,1/2), \qquad \beta=0.5, $$

$$ \rho(x,y)= \begin{cases} 17,&(x,y)\text{ 位于周期 lead 的半径 }R=0.2\text{ 圆盘内},\\ 1,&\text{ 其他位置}. \end{cases} $$

中心空列没有材料圆。连续 Hilbert 空间、form domain 和算子为

$$ H=L^2(B,\rho\,\mathrm dx\,\mathrm dy), \qquad V=H^1_\beta(B), \qquad A=-\rho^{-1}\Delta. $$

对本设计构造的非零场 $u_h^{\mathrm c}\in V$，定义

$$ R_h(v)=\int_B\nabla u_h^{\mathrm c}\cdot\nabla\overline v -\mu_h\int_B\rho u_h^{\mathrm c}\overline v, \qquad v\in V. $$

固定 shift $\gamma=\mu_h$，并令

$$ \|v\|_V^2 =\int_B|\nabla v|^2+\gamma\int_B\rho|v|^2. $$

对任意满足同一准周期条件的
$\sigma_h\in H(\operatorname{div};B)$，分部积分和
Cauchy--Schwarz 不等式给出

$$ \|R_h\|_{V'}\leq \mathcal M_h, $$

$$ \mathcal M_h^2 =\|\nabla u_h^{\mathrm c}-\sigma_h\|_{L^2(B)}^2 +\gamma^{-1} \|\rho^{-1/2}(\operatorname{div}\sigma_h+ \mu_h\rho u_h^{\mathrm c})\|_{L^2(B)}^2. $$

本轮计算的 dimensionless quantity 是

$$ q_h^{\mathrm{diag}} =\frac{\mathcal M_h^{\mathrm{diag}}} {\|u_h^{\mathrm c}\|_{V,\mathrm{diag}}}. $$

上标 `diag` 表示 ordinary-double 数值诊断，不表示可靠上界或下界。

实现统一使用 periodic gauge

$$ u(x,y)=e^{\mathrm i\beta y}\widetilde u(x,y), $$

$$ \nabla_\beta=(\partial_x,\partial_y+\mathrm i\beta), \qquad \operatorname{div}_\beta\widetilde\sigma =\partial_x\widetilde\sigma_x +(\partial_y+\mathrm i\beta)\widetilde\sigma_y. $$

所有 Q1、RT0、Gram 和 tail 计算都在该 gauge 中完成；physical-field checks 通过乘回
$e^{\mathrm i\beta y}$ 独立复算。

## 2. Frozen finite input 和 whole-subspace propagation

固定 I2 fine object

$$ n_{\mathrm{tot}}=256, \qquad M=48, \qquad K=2M+1=97. $$

只在 I2 seed 和 $\widehat k_h$ 各调用一次 `eval_i21`，不扫描或调整 $k$。candidate vector
必须按 I2.3 的同一物理权重构造：若 $D_rA_{\mathrm{def}}^D D_c$ 的最小右奇异向量为 $v$，则
从 $D_cv$ 得到归一化

$$ q=\begin{bmatrix}q_L\\q_R\end{bmatrix}, \qquad \|q\|_2=1. $$

不得使用 evaluator 为其他内部检查形成的 unweighted near-null vector 代替该 $q$。中心空列的
实际 incoming coefficients 正是 $(a_L,b_R)=(q_L,q_R)$。

在构造传播算子前先资格化 frozen branch。对 retained orders $m=-M,\ldots,M$令

$$ \beta_m=\beta+\frac{2\pi m}{d}, \qquad \gamma_m^2=\widehat k_h^2-\beta_m^2, $$

其中 $\gamma_m$ 必须是 evaluator anchored branch 返回的值，并定义无量纲 Wood distance

$$ \delta_{\mathrm W} =\min_{|m|\leq M} \frac{|\gamma_m|}{\max\{1,|\widehat k_h|,|\beta_m|\}}. $$

要求 $\delta_{\mathrm W}\geq10^{-6}$、所有 port/proxy branch 值有限，且 evaluator 的
algebra 与 seed--candidate roundtrip relative defects 均不超过 $10^{-12}$。这些检查先于
$P_\pm$、BIE 和 wall derivative；失败时输出 `BRANCH_OR_WOOD_UNRESOLVED`。

还必须独立检查 outgoing sign，不得只依赖 $\gamma_m^2=\widehat k_h^2-\beta_m^2$。
对 port 与 proxy 各自的每个 native order，令

$$ t_m=\widehat k_h^2-\beta_m^2, \qquad s_m=\max\{1,|\widehat k_h|,|\beta_m|\}, \qquad \varepsilon_{\mathrm{out}}=10^{-12}. $$

由 $\delta_{\mathrm W}$ 门排除 $t_m=0$。当 $t_m>0$ 时，该 mode 为 propagating，要求
$\operatorname{Re}\gamma_m>0$、$|\operatorname{Im}\gamma_m|/s_m\leq
\varepsilon_{\mathrm{out}}$，且

$$ \frac{|\gamma_m-\sqrt{t_m}|}{s_m}\leq\varepsilon_{\mathrm{out}}. $$

当 $t_m<0$ 时，该 mode 为 evanescent，要求 $\operatorname{Im}\gamma_m>0$、
$|\operatorname{Re}\gamma_m|/s_m\leq\varepsilon_{\mathrm{out}}$，且

$$ \frac{|\gamma_m-\mathrm i\sqrt{-t_m}|}{s_m}\leq\varepsilon_{\mathrm{out}}. $$

以上正号分别固定向外传播和向无穷远衰减的 branch；任一 sign 或 relative
defect 失败与 Wood 失败使用同一首败语义。

把 frozen QZ bases 分块为

$$ Z_+=\begin{bmatrix}A_+\\B_+\end{bmatrix}, \qquad Z_-=\begin{bmatrix}A_-\\B_-\end{bmatrix}. $$

用 frozen scattering pencil $(A_{\mathrm{sc}},B_{\mathrm{sc}})$ 定义

$$ P_+=(B_{\mathrm{sc}}Z_+)\backslash(A_{\mathrm{sc}}Z_+), \qquad P_-=(A_{\mathrm{sc}}Z_-)\backslash(B_{\mathrm{sc}}Z_-). $$

每侧都要求 rank 为 $K$、thin-QR rcond 至少 $10^{-8}$、solve 和 invariant residual 至多
$10^{-10}$。不得重新 QZ、逐 multiplier 对角化、使用 $P_\pm^{-1}$ 或丢弃 Jordan/nonnormal
coupling。

令 $E=\operatorname{diag}(e^{\mathrm i\gamma_m})$，并解

$$ (A_-+B_-)c_-=[I,E]q, \qquad (A_++B_+)c_+=[E,I]q. $$

右 lead canonical cell 的 incoming map 是

$$ \begin{bmatrix}a_L\\b_R\end{bmatrix} =\begin{bmatrix}A_+\\B_+P_+\end{bmatrix}c, $$

左 lead 按物理 $x$ 从左到右的 canonical cell incoming map 是

$$ \begin{bmatrix}a_L\\b_R\end{bmatrix} =\begin{bmatrix}A_-P_-\\B_-\end{bmatrix}c. $$

第 $n$ 个外向胞元把 $c$ 换成 $P_\pm^nc_\pm$。这些公式同时冻结左右索引和 orientation。

为避免只检查 pencil invariant residual 而遗漏实际 scattering state，四个 frozen blocks 统一按

$$ \begin{bmatrix}b_L\\a_R\end{bmatrix} = \begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix} \begin{bmatrix}a_L\\b_R\end{bmatrix} $$

解释。必须直接检查以下 unit-map closure：

$$ B_+=R_LA_+ +T_{RL}B_+P_+, \qquad A_+P_+=T_{LR}A_+ +R_RB_+P_+, $$

$$ B_-P_-=R_LA_-P_-+T_{RL}B_-, \qquad A_-=T_{LR}A_-P_-+R_RB_-. $$

每个 relative Frobenius defect 均不超过 $10^{-10}$。还要把同一关系分别收缩到
$c_\pm$、$P_\pm c_\pm$ 所生成的 center-adjacent、first-lead 和 one-step-tail
actual states，逐向量 relative defect 同样不超过 $10^{-10}$。任一 closure 失败都归入
`PROPAGATION_ACTION_UNRESOLVED`。

## 3. 从 incoming coefficients 到 raw BIE field

### 3.1 BIE response 和 density coordinates

candidate node 已保存 $A_{\mathrm{QP}}$ 和 scattering blocks，但没有保存 proxy、圆几何或
$H_L,H_R$。实现只重建同一 anchored proxy、圆 $C$、channels、incident matrices
$B_L,B_R$ 和 far-field matrices $F_L,F_R$，然后直接使用 node 中的 $A_{\mathrm{QP}}$ 做一次
multi-right-hand-side solve：

$$ H_L=-A_{\mathrm{QP}}^{-1}B_L, \qquad H_R=-A_{\mathrm{QP}}^{-1}B_R. $$

不得为此再调用第二次 `kbie`。由 $F_L,F_R,H_L,H_R$ 重构的四个 scattering blocks 必须与
node 中的 blocks 相对一致到 $10^{-12}$；BIE rcond 至少 $10^{-8}$，逐 RHS relative/backward
residual 的最大值至多 $10^{-10}$。

只使用以下 density coordinate，不在实现中作第二次符号翻译：

$$ \eta=\begin{bmatrix}\tau\\\zeta\end{bmatrix}. $$

其中 $\tau$ 是 double-layer density coordinate，$\zeta$ 是当前矩阵第二 density coordinate；
二者都不是 Dirichlet trace。与历史 Müller 推导中使用的符号 $\sigma$ 相比，本坐标满足

$$ \zeta=-\sigma. $$

该式只用于对照历史推导；实现只传递 $\zeta$，不得在 kernel 调用前再用 $\sigma$
作一次符号代换，以免 double sign flip。raw fields 固定为

$$ u_{\mathrm e} =u_{\mathrm{inc}}+D_{\mathrm{QP}}^{(\widehat k_h)}\tau -S_{\mathrm{QP}}^{(\widehat k_h)}\zeta, $$

$$ u_{\mathrm i} =D^{(\sqrt{17}\widehat k_h)}\tau -S^{(\sqrt{17}\widehat k_h)}\zeta. $$

相应的 lead density maps 为

$$ H_+=H_LA_+ +H_RB_+P_+, \qquad H_-=H_LA_-P_-+H_RB_-. $$

所以第 $n$ 个胞元的 density 是 $H_\pm P_\pm^nc_\pm$。圆为常速参数化；必须检查 speed
spread 和现有 row/column scaling 的标量相消。该 circle-only identity 不通过时输出
`BIE_DENSITY_UNRESOLVED`，不得把 $H_L,H_R$ 解释为上述 field densities。

### 3.2 圆周单侧 Dirichlet traces

法向固定为从圆盘指向背景。记 Kress Nystr\"om 离散得到的 principal-value operators 为
$K_{\mathrm{QP}},S_{\mathrm{QP}},K_{\mathrm i},S_{\mathrm i}$。实现复用
`kernel.kress_l_splits`、`kernel.kress_mn_splits` 和
`quad.quad_kress_rvec`，再加入 smooth QP proxy remainder；不得把 Müller difference block
拆猜成两个单侧 operator。

在该法向和 §3.1 的 $\zeta$ coordinate 下，单侧 Dirichlet traces 定义为

$$ g_{\mathrm e} =\gamma_D^{\mathrm e}u_{\mathrm e} =u_{\mathrm{inc}}|_\Gamma +\left(\frac12I+K_{\mathrm{QP}}\right)\tau -S_{\mathrm{QP}}\zeta, $$

$$ g_{\mathrm i} =\gamma_D^{\mathrm i}u_{\mathrm i} =\left(-\frac12I+K_{\mathrm i}\right)\tau -S_{\mathrm i}\zeta. $$

固定 common trace 为

$$ g=\frac12(g_{\mathrm e}+g_{\mathrm i}). $$

它只用于构造 companion；不得称为 raw BIE 的 exact physical trace。$g_{\mathrm e}-g_{\mathrm i}$
必须与 $A_{\mathrm{QP}}\eta+B_{\mathrm{inc}}$ 的前 $n_{\mathrm{tot}}$ 行独立比较，relative
identity defect 至多 $10^{-10}$。

单侧 trace oracle 的 manufactured 部分预先固定为 circle Fourier densities
$e^{\mathrm i\ell\theta}$，$\ell\in\{0,\pm1,\pm2\}$。闭式值必须与代码的 fundamental
solution 约定完全一致：

$$ \Phi_\kappa(x,y)=\frac{\mathrm i}{4} H_0^{(1)}(\kappa|x-y|), $$

圆周半径为 $R$，source normal 指向背景。对 density $e^{\mathrm i\ell\phi}$，
Graf addition theorem 给出 single-layer potential

$$ S_{\kappa,\ell}(r,\theta) =\frac{\mathrm i\pi R}{2}e^{\mathrm i\ell\theta} \begin{cases} J_\ell(\kappa R)H_\ell^{(1)}(\kappa r),&r>R,\\ H_\ell^{(1)}(\kappa R)J_\ell(\kappa r),&r<R, \end{cases} $$

以及 double-layer potential

$$ D_{\kappa,\ell}(r,\theta) =\frac{\mathrm i\pi\kappa R}{2}e^{\mathrm i\ell\theta} \begin{cases} J_\ell'(\kappa R)H_\ell^{(1)}(\kappa r),&r>R,\\ H_\ell^{(1)\prime}(\kappa R)J_\ell(\kappa r),&r<R. \end{cases} $$

因此单层连续，

$$ S_{\kappa,\ell}^{+}(R,\theta) =S_{\kappa,\ell}^{-}(R,\theta) =\frac{\mathrm i\pi R}{2} J_\ell(\kappa R)H_\ell^{(1)}(\kappa R)e^{\mathrm i\ell\theta}, $$

而由 Wronskian identity

$$ J_\ell(z)H_\ell^{(1)\prime}(z) -J_\ell'(z)H_\ell^{(1)}(z)=\frac{2\mathrm i}{\pi z} $$

得到

$$ D_{\kappa,\ell}^{+}(R,\theta) -D_{\kappa,\ell}^{-}(R,\theta) =e^{\mathrm i\ell\theta}. $$

这与本设计的 exterior/interior traces
$(\frac12I+K_\kappa)e^{\mathrm i\ell\theta}$ 与
$(-\frac12I+K_\kappa)e^{\mathrm i\ell\theta}$ 之差一致。实现对 exterior
free-space singular part 取 $\kappa=\widehat k_h$，对 interior 取
$\kappa=\sqrt{17}\widehat k_h$；必须分别核对 $D/S$ signs、法向和 circle
normalization。每项使用预注册 relative norm

$$ \frac{\|g_{\mathrm{num}}-g_{\mathrm{ref}}\|_2} {\max\{1,\|g_{\mathrm{ref}}\|_2\}} \leq10^{-10}. $$

这个闭式 oracle 不声称资格化 quasiperiodic proxy smooth remainder；后者只通过已保存的
$A_{\mathrm{QP}}$ object identity 与下述 source-order refinement 检查。base $256$
与对同一 trigonometric density 插值后的 $512$ 点 trace 相对变化至多
$10^{-6}$。

$A_{\mathrm{QP}}\eta+B_{\mathrm{inc}}$ 的后 $n_{\mathrm{tot}}$ 行只记录为 discrete
normal-jump residual。它不能给出两个 individual normal traces。individual hypersingular/
adjoint trace oracle 是 `OPTIONAL` quality diagnostic，不是本 companion、majorant 或本轮
estimator 的前置门；未做时必须明确写 `INDIVIDUAL_NORMAL_TRACES_NOT_COMPUTED`。

### 3.3 安全圆周、墙面和 direct evaluation 资格

固定

$$ \delta_c=0.04, \qquad \delta_w=0.04. $$

$\delta_c$ 是 $n_{\mathrm{tot}}=256$ 圆周 panel arc length 的约 $8.15$ 倍。所有满足
$|r-R|<\delta_c$ 的 Q1 nodes 禁止 direct layer-potential evaluation。只在安全圆周
$r=R-\delta_c$ 与 $r=R+\delta_c$ 计算 $u_{\mathrm i}^{\mathrm safe}$、
$u_{\mathrm e}^{\mathrm safe}$。

base source order 使用原 $256$ 点 density；qualification level 只把这一已解出的
trigonometric density 插值到 $512$ 点，然后重算圆周 trace、安全圆周和
overresolved wall grids。它不重算 candidate、QZ bases、$P_\pm$、$H_L,H_R$ 或任何
finite-dimensional spectral object。两层安全圆周 field maps 的相对变化至多
$10^{-6}$。不得把 $512$ source oversampling 用于整个 Q1 grid，也不得在看到结果后
改变 $\delta_c$。

左右墙离圆最近距离为 $0.3$，因此 wall evaluation 不属于 close evaluation。仍须在同一 physical
$y$ grid 上用 $256/512$ source orders 比较 raw wall Dirichlet field，relative change 至多
$10^{-6}$。这些 direct wall evaluations 覆盖 center/first、first/next 以及 canonical
tail unit-state maps，并另外收缩到 actual $c_\pm$ 与 $P_\pm c_\pm$ states。在至少
$N_y^{\mathrm wall}=512$ 的 grid 上记录：

1. raw wall field 与 frozen shared trace $d=a+b$ 的相对 mismatch；
2. 同一几何 wall 上相邻 raw BIE cells 直接重建值之间的相对 mismatch；
3. 把 raw wall field 投影到 physical Fourier orders 后，$|m|>48$ 的能量比例；
4. top/bottom physical Bloch defect 和对应 periodic-gauge defect。

raw-to-shared mismatch、adjacent-raw direct mismatch 与 outside-$M$ tail 的大小是必须披露的
correction diagnostics，但不单独设
amplitude hard gate：最终 Q1 companion 会强制共享 wall value，全部 correction energy 进入
majorant；若 correction 过大，应由 field/majorant/refinement/width 门失败，而不是结果后删除它。

若 surface trace、安全圆周或 wall evaluator 资格失败，分别输出
`SURFACE_TRACE_UNRESOLVED` 或 `SAFE_FIELD_EVALUATION_UNRESOLVED`。不得回到 `lead-a3` 的近圆
direct evaluator。

## 4. Safe-collar Q1 conforming companion

### 4.1 两层 mesh 和固定插值函数

reference cell 为 $[-1/2,1/2]\times[-1/2,1/2]$。两层固定为

| level | $N_x$ | $N_y$ | disk polar $N_r$ | disk polar $N_\theta$ |
|---|---:|---:|---:|---:|
| coarse | 64 | 128 | 32 | 128 |
| fine | 96 | 192 | 48 | 192 |

$N_y>2M$，因此 retained $m=-48,\ldots,48$ 不在 nodal grid 上 alias。top/bottom 在 periodic
gauge 中共享同一组 DOFs。

固定 smoothstep

$$ h(t)=3t^2-2t^3, \qquad 0\leq t\leq1. $$

它满足 $h(0)=0$、$h(1)=1$ 和 $h'(0)=h'(1)=0$。所有圆周和墙面 functions 先在固定均匀
grid 上形成 trigonometric interpolant，再在 Q1 nodes 的角度或 $y$ 值求值；不得使用 nearest
neighbor 或结果依赖的 Fourier cutoff。

### 4.2 圆安全带公式

对 $R-\delta_c\leq r\leq R$，令

$$ t_- =\frac{r-(R-\delta_c)}{\delta_c}, $$

并定义 nodal shape data

$$ U_-(r,\theta) =(1-h(t_-))u_{\mathrm i}^{\mathrm safe}(\theta) +h(t_-)g(\theta). $$

对 $R\leq r\leq R+\delta_c$，令

$$ t_+=\frac{r-R}{\delta_c}, $$

并定义

$$ U_+(r,\theta) =(1-h(t_+))g(\theta) +h(t_+)u_{\mathrm e}^{\mathrm safe}(\theta). $$

$r<R-\delta_c$ 的 nodes 使用 raw interior BIE value；$r>R+\delta_c$ 且不在 wall strip 的
nodes 使用 raw exterior BIE value。圆安全带只替换未资格化的近圆点值，不声称 $U_\pm$ 满足
Helmholtz 方程。

### 4.3 墙安全带和中心空列

对任一 lead cell，令 $d_L(y),d_R(y)$ 为 §2 同一 state 给出的 shared total Dirichlet traces，
并在安全竖线 $x=-1/2+\delta_w$、$x=1/2-\delta_w$ 计算 raw exterior values
$u_L^{\mathrm safe}(y),u_R^{\mathrm safe}(y)$。左墙 strip 使用

$$ t_L=\frac{x+1/2}{\delta_w}, \qquad U_L(x,y)=(1-h(t_L))d_L(y)+h(t_L)u_L^{\mathrm safe}(y). $$

右墙 strip 使用

$$ t_R=\frac{1/2-x}{\delta_w}, \qquad U_R(x,y)=(1-h(t_R))d_R(y)+h(t_R)u_R^{\mathrm safe}(y). $$

圆安全带最外 $|x|$ 不超过 $0.24$，wall strips 的内边界为 $|x|=0.46$，二者间隔 $0.22$，
所以没有优先级重叠。

中心空列的 raw field 是由 $(q_L,q_R)$ 形成的显式有限 Rayleigh field。其左右 strip 用完全相同
公式连接到 $D_-c_-$ 和 $D_+c_+$。因此 center/lead 和 lead/lead 的 wall nodal values 是同一个
数组，不是分别求值后再比较近似相等。

把以上 physical nodal values 乘 $e^{-\mathrm i\beta y}$ 后，形成单一 periodic-gauge Q1
function $\widetilde u_h^{\mathrm c}$。这个 global Q1 function 穿过真实材料圆，不在圆上复制
DOF；故逐胞 wall arrays、periodic seam 和非零 field 检查通过且无限 $V$-norm 可和时，

$$ u_h^{\mathrm c}\in H^1_\beta(B). $$

必须独立复算 center/lead、lead/lead shared wall defects、periodic-gauge seam defect 和恢复到
physical field 后的 Bloch defect，均不超过 $10^{-12}$。所有 raw-to-common circle correction、
raw-to-shared wall correction 和 center strip correction 已先写入 Q1 nodal map，所以它们的
field、gradient 和 mass energy全部进入下节 $N/A/B$ Grams；不得另列后从 numerator 中删除。

## 5. Global RT0 flux 和 per-cell majorant

### 5.1 单值 vertical flux orientation

RT0 所有 vertical edge 使用 physical global $+x$ orientation，horizontal edge 使用 global
$+y$ orientation。vertical cell-wall DOFs 不从两个 raw BIE gradients 平均，而由 frozen QZ
Cauchy state 预先给出同一个值。

右 lead state $P_+^nc_+$ 的左右 global-$x$ derivative traces 是

$$ p_{n,L}^+=\mathrm i\Gamma(A_+-B_+)P_+^nc_+, $$

$$ p_{n,R}^+=\mathrm i\Gamma(A_+-B_+)P_+^{n+1}c_+. $$

左 lead canonical cell state $P_-^nc_-$ 的物理左右 traces 是

$$ p_{n,L}^-=\mathrm i\Gamma(A_--B_-)P_-^{n+1}c_-, $$

$$ p_{n,R}^-=\mathrm i\Gamma(A_--B_-)P_-^nc_-. $$

center/left 与 center/right 分别固定使用

$$ p_{\mathrm{center},L}=-N_-c_- =\mathrm i\Gamma(A_--B_-)c_-, $$

$$ p_{\mathrm{center},R}=N_+c_+ =\mathrm i\Gamma(A_+-B_+)c_+. $$

这些是同一 shared wall 上唯一的 global-$x$ Fourier coefficients。若其 physical
basis 表示为

$$ p(y)=\frac1{\sqrt d}\sum_{m=-M}^{M}p_m e^{\mathrm i\beta_m y}, $$

则先恢复 periodic-gauge flux

$$ \widetilde p(y)=e^{-\mathrm i\beta y}p(y) =\frac1{\sqrt d}\sum_{m=-M}^{M}p_m e^{2\pi\mathrm i m y/d}. $$

对任一 vertical RT0 edge $I_j=[y_j,y_{j+1}]$，存储的 DOF 冻结为精确 edge average

$$ \overline p_j =\frac1{|I_j|}\int_{I_j}\widetilde p(y)\,\mathrm dy =\sum_{m=-M}^{M}p_m\omega_{m,j}, $$

其中

$$ \omega_{0,j}=\frac1{\sqrt d}, \qquad \omega_{m,j}= \frac{d}{2\pi\mathrm i m|I_j|\sqrt d} \left(e^{2\pi\mathrm i m y_{j+1}/d} -e^{2\pi\mathrm i m y_j/d}\right),\quad m\ne0. $$

不得以 midpoint、nodal interpolation 或各胞元 outward-normal value 代替该积分。同一 wall 的两个
cells 必须共享完全相同的 $\overline p_j$；stored orientation 始终为 physical global $+x$，
不得把 outward normal sign 混入 stored DOF。

### 5.2 固定 boundary flux 下的 RT0 minimization

给定一个 Q1 cell map及上述两墙 RT0 normal DOFs，其余 global RT0 edge DOFs通过最小化

$$ J_h(\widetilde\sigma) =\|\nabla_\beta\widetilde u_h^{\mathrm c} -\widetilde\sigma\|_{L^2(C)}^2 +\gamma^{-1} \|\rho^{-1/2}(\operatorname{div}_\beta\widetilde\sigma +\mu_h\rho\widetilde u_h^{\mathrm c})\|_{L^2(C)}^2 $$

唯一确定。RT0 mass 使 free-flux block coercive。只允许对该固定 quadratic form 作一次 scaled
sparse factorization和 multi-RHS solve；不得按结果改为 elementwise averaging。factor rcond
至少 $10^{-10}$，逐 RHS scaled relative/backward residual 最大值至多 $10^{-10}$。

top/bottom periodic seam 使用同一个 gauge-oriented RT0 DOF。internal edge、periodic seam、
center/lead 和 lead/lead 的 normal-continuity defects 都必须不超过 $10^{-12}$。失败为
`HDIV_FLUX_UNRESOLVED`。

### 5.3 True-circle integration 和 Grams

field norm 和 majorant 第二项中的材料系数采用 background rectangle 加 true-circle polar
contrast；不得用 Cartesian inside/outside mask。两层 polar orders 已在 §4.1 冻结。`true-circle`
只表示几何对象正确，不表示 quadrature 已 outward-enclosed。

对每个 cell state map 形成 Hermitian matrices

$$ N:\ \|u_h^{\mathrm c}\|_V^2, \qquad A:\ \|\nabla_\beta\widetilde u_h^{\mathrm c} -\widetilde\sigma_h\|^2, $$

$$ B:\ \|\rho^{-1/2}(\operatorname{div}_\beta\widetilde\sigma_h +\mu_h\rho\widetilde u_h^{\mathrm c})\|^2. $$

所有 linear maps 先对 unit coordinate basis 构造，不带 $q,c_\pm$ 的全局幅值。raw Gram 的
Hermitian defect 必须不超过 $10^{-12}$；Hermitian part 的最小 eigenvalue 不低于
$-10^{-12}$ 乘 matrix scale。对称化后才用于 quadratic contraction。

旧 `weak-a1` 的 $10^8$ 重算不在本设计重复。scale/phase check 固定为：用
$\alpha=10^8e^{\mathrm i\pi/7}$ 只替换最终 coordinate vectors，比较

$$ \frac{(\alpha c)^*G(\alpha c)}{|\alpha|^2} \quad\text{与}\quad c^*Gc $$

以及相应 totals、$q_h^{\mathrm{diag}}$ 和 interval；最大 relative defect 不超过
$10^{-11}$。这直接检查本设计实际使用的 scale-covariant contraction，不用巨大幅值重新装配
本来与 coordinate scale 无关的 Gram matrices。

## 6. Full-$P$ infinite tail

center 单列。每侧 lead 把 $n=0$ first cell 的 $c^*Wc$ 也单列；该 canonical
$W$ 以 parent state $c$ 和 neighbor state $Pc$ 构造。只有 $n\geq1$ 进入 tail。对 full
$P_\pm$ 定义

$$ W_N=\sum_{j=0}^{N-1}(P^j)^*WP^j, $$

$$ W_{2N}=W_N+(P^N)^*W_NP^N, \qquad P^{2N}=(P^N)^2. $$

因此从 $n=1$ 开始的 $N$ 个 tail cells 必须收缩为

$$ T_N=(Pc)^*W_N(Pc) =\sum_{n=1}^{N}(P^nc)^*W(P^nc), $$

而不是再用 $c^*W_Nc$。连同已单列的 first cell，部分和恰为

$$ c^*Wc+T_N=\sum_{n=0}^{N}(P^nc)^*W(P^nc), $$

因此不重复计数 $n=0$。左右两侧分别用各自的 $P_\pm,c_\pm,W_\pm$。

doubling levels 固定为 $N=2^j$、$j=0,\ldots,12$。必须像历史 V2 一样用 alternate
association 复算 $P^N$ 和 $W_N$，形成 ordinary-double association allowances。只有在带
allowance 的 $\|P^N\|_2<1$ 且 field-norm、$A$、$B/\gamma$ 和 total-majorant tail shares
全部不超过 $10^{-6}$ 时 tail gate 才通过。

tail cell maps 只使用 $[I,P,P^2]$：当前 Q1 companion由 parent state 及其下一 state 构造，
shared vertical flux 同样由这两个 states 给出。不得使用 $P^{-1}$、逐 multiplier decay、只看
最后一胞幅度或显式展开大量胞元。

普通双精度 doubling allowance 仍是 diagnostic，不是可靠 tail enclosure。

## 7. 两层分辨率、谱区间和结论边界

coarse/fine 两层必须从 raw field maps、collars、Q1、RT0、Gram 到 full-$P$ tail 完整重算。
冻结内部变化门：

$$ \frac{|A_f-A_c|} {\max\{A_f+B_f/\gamma,A_c+B_c/\gamma,\mathrm{realmin}\}} \leq0.20, $$

$$ \frac{|B_f/\gamma-B_c/\gamma|} {\max\{A_f+B_f/\gamma,A_c+B_c/\gamma,\mathrm{realmin}\}} \leq0.20, $$

$$ \frac{|N_f-N_c|}{\max\{N_f,N_c,\mathrm{realmin}\}} \leq0.20. $$

任一层 $q_h^{\mathrm{diag}}\geq1$ 时，nominal interval 不定义，并直接报告
`WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT`。若 $q_h^{\mathrm{diag}}<1$，定义

$$ L_h^{\mathrm{diag}} =\max\left\{0, \frac{\mu_h-q_h^{\mathrm{diag}}\gamma} {1+q_h^{\mathrm{diag}}}\right\}, $$

$$ U_h^{\mathrm{diag}} =\frac{\mu_h+q_h^{\mathrm{diag}}\gamma} {1-q_h^{\mathrm{diag}}}, $$

$$ I_h^{k,\mathrm{diag}} =\left[\sqrt{L_h^{\mathrm{diag}}}, \sqrt{U_h^{\mathrm{diag}}}\right]. $$

预注册 absolute resolution 是

$$ \tau_k^{\mathrm{pre}}=10^{-6}. $$

两层 interval 都定义时，width change 必须不超过 fine width 的 $20\%$ 与
$0.1\tau_k^{\mathrm{pre}}$ 两者较大者；fine width 还必须不超过 $10^{-6}$。失败分别归入
`MESH_RESOLUTION_UNRESOLVED` 或 `WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT`。

即使 nominal width 通过，本轮仍只能报告
`RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE`，因为 ordinary-double numerator、denominator 和
tail 尚未 outward-enclose。以后只有得到 reliable $\overline{\mathcal M}_h$、
$\underline N_h>0$、outward-rounded interval，并证明它完全落在 certified projected gap 内，
才能说其中至少存在一个不属于本质谱的离散特征值。存在性还必须同时满足预注册 width；一个
很宽区间中的“至少存在一个特征值”不是合格结果。unique target identity 仍是独立的可选升级，
不是本轮前置门。

本 attempt 的 $256\to512$ source check、coarse/fine Q1--RT0 check、scattering closure、
full-$P$ tail 和 circle oracle 都是同一 candidate、同一 BIE/QZ model 和同一重建链内的
internal qualification。它们可以暴露实现错误或分辨率不足，但共享 model/discretization
bias；因此本 attempt 不能充当 I3.2 的 independent reference，也不能验证 estimator
在不同数值方法下是否跟踪 $|k^*-\widehat k_h|$。

functional majorant 的逻辑本身不循环：第 1 节的不等式对任意已构造的
$u_h^{\mathrm c}\in V$ 和 $\sigma_h\in H(\operatorname{div};B)$ 成立，不假设
$\widehat k_h$ 已经是 finite root 或 continuous eigenvalue。用同一数据最小化 majorant 只能改变
右端的紧致程度，不会把未知真值或预期结论写入不等式。$N/A/B$ 对象按
真实材料系数 $\rho$ 和上述 continuous form 对显式 conforming companion 组装，而不是对
finite BIE matrix residual 拟合；因此不等式的成立与 trial 的生成方式无关。但本轮的积分、
linear solves、norms 和 tail 均只是 ordinary-double approximations；在它们被 outward-enclose
之前，这个非循环的理论公式仍然只产生 estimator candidate，不产生可靠谱区间。
无论本 attempt 算得的 nominal residual 或 interval 多小，它都不能充当 I3.2 的独立
reference 或 effectivity validation。

## 8. 固定首败顺序

按科学依赖固定：

1. dependency、output collision、unknown MATLAB error 或资源失败：
   `EXECUTION_UNAVAILABLE`；
2. weighted candidate vector 或 I2 finite input health 失败：
   `FINITE_DISCRETE_INPUT_UNAVAILABLE`；
3. anchored port/proxy branch algebra/roundtrip、propagating/evanescent outgoing sign 或
   $\delta_{\mathrm W}\geq10^{-6}$ 失败：
   `BRANCH_OR_WOOD_UNRESOLVED`；
4. $P_\pm$ rank、rcond、solve、invariant residual、unit-map 或 actual-state scattering
   closure 失败：`PROPAGATION_ACTION_UNRESOLVED`；
5. proxy、BIE solve、density scaling 或 rebuilt-block identity 失败：
   `BIE_DENSITY_UNRESOLVED`；
6. 单侧 Kress Dirichlet trace、jump identity 或 $256\to512$ trace 变化失败：
   `SURFACE_TRACE_UNRESOLVED`；
7. safe-ring 或 overresolved wall evaluation 失败：
   `SAFE_FIELD_EVALUATION_UNRESOLVED`；
8. Q1 map nonfinite、shared wall、periodic seam 或非零 field 失败：
   `FORM_CONFORMITY_UNRESOLVED`；
9. constrained RT0 factor/solve 或 global normal continuity 失败：
   `HDIV_FLUX_UNRESOLVED`；
10. true-circle integration、majorant object、Gram Hermitian/PSD 或 finite-value 门失败：
    `MAJORANT_QUADRATURE_UNRESOLVED`；
11. full-$P$ contraction、association margin 或 tail share 失败：
    `INFINITE_TAIL_UNRESOLVED`；
12. 完整 totals 的 coarse/fine 或 scale/phase 门失败：
    `MESH_RESOLUTION_UNRESOLVED`；
13. $q\geq1$、interval undefined 或 width 太大：
    `WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT`；
14. nominal 诊断全部通过：仍为 `RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE`，并记录
    `PROJECTED_GAP_NOT_ESTABLISHED`。

任何失败都不得在同一 attempt 中修改 $\delta_c$、$\delta_w$、source order、mesh、common
trace、flux rule、threshold 或结果解释。individual normal trace 未计算不属于失败；它必须由
明确的 OPTIONAL flag 表达。

## 9. 最低实现、schema 和预算

### 9.1 文件边界

实现使用一个 MATLAB entry 和两个按科学对象分开的 helper：

```text
test/i3/b-resid/check_b_resid.m
test/i3/b-resid/i31_bie_cell.m
test/i3/b-resid/i31_fe_cell.m
```

entry 负责 frozen evaluator、finite input、propagation、full-$P$ tail、failure/report 和
append-only output；第一个 helper 负责 BIE response 与 Kress/safe evaluation，第二个 helper
负责 Q1 collar companion、RT0 minimization 和 per-cell Grams。合并实现超过 $1000$ 行，故按
设计预留的两个科学对象边界拆分；不得再为 config、schema、paths、未来扩展或普通 utilities
增加文件。

历史 `test/i3/g-resid/`、`test/i3/w-resid/` 及其 append-only outputs 全部保持不变。运行时只通过
MATLAB path 解析代码 dependencies，不读取 Markdown、Git、manifest 或历史 output。

### 9.2 最少 result schema

result 至少保存：

- weighted $q,c_-,c_+$、factor health、$\delta_{\mathrm W}$、port/proxy branch algebra/roundtrip、
  propagating/evanescent classifications 和 outgoing-sign relative defects、$P_\pm$ diagnostics，以及
  unit-map/actual-state scattering closure defects；
- $H_L,H_R,H_\pm$ 的尺寸和 solve/block-identity diagnostics，不保存 dense response matrices；
- density-coordinate flag `zeta_equals_minus_sigma=true`、manufactured trace oracle 逐 mode/operator
  relative errors、`source_refinement_scope=trace_safe_wall_only`、base/refined single-sided Dirichlet
  trace、value-jump、safe-ring 和 wall qualification摘要；
- raw-to-shared wall mismatch、adjacent-raw direct wall mismatch、outside-$M$ energy、raw discrete
  normal-jump residual，以及
  `individual_normal_traces_computed=false`；
- 两层 collar widths、Q1 dimensions、shared-wall/periodic/nonzero checks 和 correction-energy
  diagnostics；
- RT0 global-$x$ orientation、exact Fourier-to-edge-average map 摘要、fixed wall-flux maps、factor/solve
  和 independently reconstructed
  $H(\operatorname{div})$ defects；
- center、first cells 和 tail 的小型 $N,A,B$ Grams、doubling allowances、tail shares、totals、
  $q_h^{\mathrm{diag}}$ 和 nominal interval；
- first failure、elapsed time、peak active-object memory、retry history 和 coverage flags。

可保存 center、first-minus、first-plus 和 one-step-tail 的小型 wall/trace samples 供审计；不得
保存全网格 dense Q1/BIE maps。可靠性 flags 默认均为 false：

```text
residual_upper_bound_certified=false
field_lower_bound_certified=false
tail_diagnostic_certified=false
projected_gap_established=false
continuous_discrete_eigenvalue_existence=false
continuous_error_bound=false
shared_model_bias_present=true
i3_2_independent_reference_eligible=false
```

只有在 Q1 conformity、RT0、Gram、tail 和两层门全部通过后，才可把
`continuous_form_residual_computed=true` 和
`functional_majorant_formula_applied=true`。更早失败时不得提前置 true。

### 9.3 成本

预计 candidate/proxy/BIE response 为 $15$--$25$ 秒，surface/safe qualification 为
$30$--$120$ 秒，两层 raw-field maps、Q1、RT0 和 tail 合计约 $8$--$15$ 分钟；预计 peak
active-object memory 为 $200$--$400$ MiB。soft/hard time 固定为 $900/1800$ 秒，active-object
memory 上限为 $512$ MiB。

QP-MFS pair evaluation 是主要成本。实现必须使用 value/first-gradient-only kernel、target
batching，并在每批乘 density maps 后立即释放 pair matrices；禁止一次形成所有 target/source/
proxy arrays。$512$ source order只用于 surface/safe/wall qualification，不用于整个 Q1 grid。
达到 soft limit 后不启动新 stage；达到 hard limit 或 memory limit 时 fail close 并保存已经形成
的诊断。

attempt tag、唯一 MATLAB 命令和 append-only output directory 只在实现及 spec-to-code 审查完成
后冻结。本设计不授权写实验代码或运行 MATLAB/Octave。

## 10. 运行授权前的理论—实现审查

Skeptic 必须逐项确认：

1. saved candidate、score minimizer、finite determinant zero 和 continuous eigenvalue 没有混写；
2. branch/Wood 门先于 propagation，propagating/evanescent outgoing signs 有明确 relative
   阈值，unit-map 与 actual-state scattering closures 都直接核对；
3. actual incoming、$H_L/H_R$ density maps、左右 $P_\pm$ 索引与 global-$x$ orientation 一致；
4. $\tau,\zeta$ 只作为 densities，$\zeta=-\sigma$ 不导致二次换号，单侧 traces 含正确
   $\pm I/2$、$D/S$ signs 和 incident field；
5. manufactured oracle 的闭式对象、relative norm 与 $256\to512$ 资格范围没有越界；
6. $|r-R|<\delta_c$ 没有 direct evaluation，surface/safe/wall qualification 使用冻结的
   $256/512$ 合同；
7. circle 和 wall collar 公式完整，二者不重叠，最终 single Q1 shared DOFs 而不是 raw BIE
   jumps 建立 $H^1$ conformity；
8. raw-to-shared、adjacent-raw direct mismatch、outside-$M$ tail 和全部 collar energy 都进入
   诊断及最终 $N/A/B$ 对象；
9. RT0 vertical flux 由 global-$x$ Fourier data 的精确 edge averages 形成，在每个物理 wall
   上单值，内部 minimization 与 seam DOFs 产生真正 global
   $H(\operatorname{div})$ map；
10. full-$P$ tail 保留 nonnormal/Jordan action，且 coverage flags 只在依赖门通过后设置；
11. ordinary-double estimator candidate、reliable interval、projected-gap existence 和 unique
   identity 的结论边界严格分开；
12. 同链 internal checks 没有被写成 independent validation，本 attempt 明确不可作为
   I3.2 reference，且 majorant 的非循环原因与 ordinary-double 限制均已说明；
13. 实现规模、batching 和资源不会把本阶段变成明显昂贵的实验。

任一项未闭合时，Skeptic 应返回 bounded `REVISE`，不得授权正式运行。

理论背景见
[[research/projects/eig-apost/phase3-analysis/s-estimator|continuous residual theory]]、
[[research/projects/eig-apost/phase3-analysis/s-errors|error coverage]] 和
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|finite/continuous boundary]]；I2 输入见
[[research/projects/eig-apost/implementation/i2/report|I2 report]]；I3 阶段入口见
[[research/projects/eig-apost/implementation/i3/README|I3 README]]。

## 前瞻修订 A：evaluator 兼容字段

首次正式 attempt `bie-a1` 在进入 evaluator 和任何科学阶段前，因 `eval_i21` 仍读取旧字段
`kstar` 而结束。MATLAB shell exit code 为 0；producer outcome 为
`EXECUTION_UNAVAILABLE`，identifier 为 `MATLAB:nonExistentField`，原始消息为
`Unrecognized field name "kstar".`；耗时为 0.04598954166666667 s，peak active-object memory
为 0 MiB。append-only `bie-a1` output 已创建并保留，其中只有 `result.mat` 和 `report.md`。

Revision A 使用新 attempt `bie-a2` 和 schema
`TEP_I3_1_BIE_COLLAR_WEAK_RESIDUAL_V3_REV_A`。现行配置及 `result.config` 继续只保存语义明确的
`kseed`；仅在两次 `eval_i21` 调用前创建局部 `eval_cfg`，令
`eval_cfg.kstar=eval_cfg.kseed` 以适配未改动的旧 evaluator 接口。`bie-a2` 的 attempt-local
`retry_count=0`，另记录 `prior_failed_attempt_count=1` 及上述 `bie-a1` 历史。除该局部兼容适配、
attempt/schema/command/output guard 与失败历史外，所有科学对象、算法、参数、阈值、首败顺序和
资源预算保持不变。Revision A 仍须通过独立 spec-to-code 审查后才可运行。

## 前瞻修订 B：MATLAB 转置后索引语法

`bie-a2` 通过 finite input、branch/Wood、propagation、BIE density、surface trace 和 safe-field
evaluation 后，在首次 Q1 mesh 构造前因 `i31_fe_cell.m` 的 MATLAB 语法停止。shell exit code
为 0；producer outcome 为 `EXECUTION_UNAVAILABLE`，identifier 为
`MATLAB:m_improper_grouping`；原始消息为：

```text
File: /Users/whc/Documents/Work/epost/test/i3/b-resid/i31_fe_cell.m Line: 131 Column: 29
Invalid expression. When calling a function or indexing a variable, use parentheses. Otherwise, check for mismatched delimiters.
```

耗时为 222.9809575416667 s，peak active-object memory 为 89.65762805938721 MiB；
`scientific_stage_entered=true`，`last_completed_gate=SAFE_FIELD_EVALUATION`，Q1 及以后均为
`NOT_REACHED`。append-only `bie-a2` output 已创建并保留，其中只有 `result.mat` 和
`report.md`。

Revision B 仅把两个 mesh constructor 中四处 MATLAB 不接受的 `xx.'(:)`、`yy.'(:)` 改为
`reshape(xx.',[],1)`、`reshape(yy.',[],1)`。这保持与 `ids` 一致的节点顺序，不改变矩阵、
离散网格或任何科学计算。新 attempt 为 `bie-a3`，schema 为
`TEP_I3_1_BIE_COLLAR_WEAK_RESIDUAL_V3_REV_B`，attempt-local `retry_count=0`，并以统一 schema
记录两个 prior failed attempts。科学算法、参数、阈值、首败顺序和资源预算均不变；
Revision B 经独立 spec-to-code 审查后，还须先由 Skeptic 批准只读 `checkcode` preflight，
才能运行正式 `bie-a3`。
