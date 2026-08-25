# I3.2 同证书经验评价 cap 数值设计

## 摘要与状态

- **Design ID:** `I3.2-SAME-CERTIFICATE-EMPIRICAL-CAP-V1`
- **生效日期：** 2026-08-24
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `DESIGN REVIEW PENDING`
- **Implementation:** `NOT STARTED`
- **Run:** `NOT AUTHORIZED`
- **Frozen future attempt:** `ecap-a1`
- **Frozen output schema:** `TEP_I3_2_SAME_TRIAL_EVALUATION_CAP_V1`

本设计是 [[research/projects/eig-apost/implementation/i3/design-3-2a|I3.2 条件性证书定理]]
的 ordinary-double、same-certificate 数值扩展。它固定已经消费的 `fbie-a1` certificate 和
普通中心值，不重新求 candidate、QZ state、propagation、coordinates、BIE densities、Schur
system、wall densities 或 lifts；只提高同一个 finite-density、continuous exact-kernel trial 的
数值评价分辨率，并按运行前冻结的经验规则形成
$\epsilon_M^{\mathrm{emp}}$ 和 $\epsilon_N^{\mathrm{emp}}$。

本设计不构造严格 cap。即使经验 cap 有限、$q_{\mathrm{emp}}<1$ 且名义宽度小于
$10^{-6}$，也只能输出 `EMPIRICAL_NOMINAL_TRANSFORM`。全部 rigorous、outward、certified-gap、
spectral-intersection、existence 和 independent-reference flags 固定为 false。I3.3 只保留真正
独立的 effectivity 验证；I3.4 才处理 outward enclosure、same-operator certified gap 和离散谱
存在性。

历史 `fbie-a1` 的 design、review、三个 MATLAB 源和两个 output 均保持 byte-identical；正式
circle action warning $0.77408786032496468$ 保留为历史背景，不能被新结果追溯删除。现行结果与
原始量见 [[research/projects/eig-apost/implementation/i3/review-3-1f|review-3-1f]]。本文件获
Skeptic `DESIGN PASS` 前不得建立 input、实现代码或运行 MATLAB。

## 1. 冻结 certificate、ordinary anchor 与 staging

### 1.1 数学 certificate 和普通中心值

本轮固定 I2 算法实际保存的

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\gamma=\widehat k_h^2,
$$

以及同一 `fbie-a1` certificate 中的

$$
q^{\mathrm{cen}},\quad
P_\pm,\quad c_\pm,\quad D_\pm,\quad G_\pm,
$$

材料圆 finite trigonometric density

$$
\eta_{256}=\begin{bmatrix}\tau_{256}\\\zeta_{256}\end{bmatrix},
\qquad \zeta_{256}=-\sigma_{256},
$$

左右 wall densities $\xi_{L,512},\xi_{R,512}$、共享 total wall traces、center traces、冻结
branch convention、几何、材料、value-lift supports、widths 和 shape rules。数学 lift amplitude
由 exact-kernel finite-density raw trace 通过该固定规则唯一确定；artifact 保存的普通双精度 lift
amplitudes 只是 anchors，不是 certificate coordinates。这里 proxy chart 只是历史
ordinary evaluator 的实现状态，不属于数学 certificate；本轮不得恢复或重建它。

数学 trial 仍是 `design-3-1f` 定义的：上述 finite densities 作用于同一个 continuous outgoing
quasiperiodic Green kernel，再施加完全相同的 wall/circle value lifts。新 levels 不改变 density、
bandwidth、phase、normal、lift rule 或 state，所以全部 level 指向同一个 $z_h$ 和同一个
$u_h^{\mathrm c}=\mathcal T(z_h)$。levels 只提高该数学 lift amplitude 的数值评价，不重新求 trial
coordinates。

$M=48$ 只冻结 QZ wall-state input 的 $K=2M+1=97$ 个 retained orders；它不是
$\xi_{L/R,512}$ 的 source bandwidth，也不截断 circle 或 wall output orders。

普通中心值保持 artifact 保存的

$$
\widetilde M_h=2.29786516751043\times10^{-10},
\qquad
\widetilde N_h=4.959111810675795.
$$

三个 numerator component anchors 是

$$
\widetilde B_W=1.8732026085453917\times10^{-10},
$$

$$
\widetilde B_\Gamma=2.9776880587814564\times10^{-15},
\qquad
\widetilde B_V=4.246327820844503\times10^{-11},
$$

并满足 $\widetilde M_h=\widetilde B_W+\widetilde B_\Gamma+\widetilde B_V$。这些量只是 ordinary
centers；不因本轮 refinement 而覆盖、替换或重命名。

### 1.2 为什么 formal MATLAB 不直接读取历史 output

`test/AGENTS.md` 禁止实际运行的 MATLAB entry 读取、解析、hash、验证或依赖 historical
output，也禁止 runtime 依赖 Git、manifest、固定 repository layout 或 provenance hash。因此
formal entry 不能直接 `load` `fbie-a1/result.mat`，即使操作声称只读。

Skeptic `DESIGN PASS` 后，还必须另获一次 input-staging 授权。受审的 host-side preflight 才可：

1. 只读核验 immutable `fbie-a1` source artifact；
2. 白名单复制本节和 §1.3 的数值字段；
3. 在新实验目录创建此前不存在的 append-only
   `input/fbie-a1-certificate.mat`；
4. 比较 source 前后 identity，证明 source 未改；
5. 把 machine-side digest 保存在 runtime 不消费的可选 provenance 中。

staging 不是科学重算：不得调用 candidate、QZ、proxy、density、Schur、coordinate 或 tail solve。
若 staging 未获授权、目标 input 已存在、白名单字段缺失或 source identity 不闭合，报告
`CERTIFICATE_INPUT_UNAVAILABLE`，不创建 formal attempt。不得以调用 `eval_i21` 或历史 helper
作为 fallback。

formal MATLAB 只接受显式 certificate path；它只检查 input schema、尺寸、类型、finiteness 和
科学不变量，不读取或 hash 历史 output。这样 experiment 目录与所需 package 一起移动并加入
MATLAB path 后，不需改 source。

### 1.3 Staged input 的白名单

input 至少分为以下互不混写的 structs：

- `certificate`: $\widehat k_h,\mu_h,\gamma,\beta,d,R,\rho$、branch、$M=48,K=97$、
  $q^{\mathrm{cen}},P_\pm,c_\pm,D_\pm,G_\pm$、$\eta_{256}$、$\xi_{L/R,512}$、shared traces、
  center actual/shared traces、lift supports/widths/shape rules 和全部 orientation/normalization
  labels；
- `ordinary_anchor`: $\widetilde B_W,\widetilde B_\Gamma,\widetilde B_V,
  \widetilde M_h,\widetilde N_h$，以及形成这些量的 frozen wall/circle/volume/field factor maps、
  artifact raw value defects、lift amplitudes/source maps、center singleton maps、ordinary Grams 和
  原始 first-level indices。白名单必须显式覆盖 artifact 中的 `delta_plus/minus`,
  `circle_jump_plus/minus`, center mismatch/lift sources, `lead_volume_factor_*`,
  `lead_wall/circle/field_factor_*` 和 `full_boundary_maps`；
- `historical_diagnostics`: circle $256\to512$ raw numerator、两侧 norms、ratio、512 action norms、
  outside-$M$ share 和历史 warning label；这些量只显示背景，绝不进入新两级差；
- `input_contract`: certificate schema version、数组形状和 exact semantic labels；provenance 字段不得
  控制 runtime。

Derived 512 actions、QL/QR、defects、Grams、tails 和旧 $q$ 不是 $z_h$ 的数学字段；它们只可作为
ordinary anchor 或历史诊断，不得伪装成新的 exact-kernel action。

## 2. 硬 `NO_RESOLVE` 调用合同

### 2.1 唯一数据流

formal attempt 的数据流只能是

$$
\text{explicit staged input}
\longrightarrow
\text{fixed-density analytic actions}
\longrightarrow
\text{same frozen lifts/factors}
\longrightarrow
\text{full-}P\text{ contractions}
\longrightarrow
\text{empirical evaluation caps and nominal transform}.
$$

禁止的数据流包括：重扫或重选 $\widehat k_h$；重算 SVD candidate；重做 QZ；重建
$P_\pm,c_\pm,D_\pm,G_\pm$；解 wall modal density、circle density 或 Schur system；重建 proxy
chart；重拟合 phase/scale；修改 $M$、geometry、branch、lift support、width 或 shape rule。提高
同一 fixed rule 所定义的 lift amplitude 评价不属于 resolve。

新的 source call graph 不得引用 `eval_i21`、`kproxy`、`kbie`、历史 `check_fb_resid`，也不得把
历史 helper 当 runtime evaluator。现有三个 MATLAB 源只提供只读公式与 schema 映射，不能由
formal entry 调用。

### 2.2 Machine counters 和 identity

result 必须保存以下计数器，且全部严格为零：

```text
candidate_solve_calls
qz_solve_calls
coordinate_solve_calls
propagation_solve_calls
wall_density_solve_calls
circle_density_solve_calls
schur_solve_calls
proxy_build_calls
```

另外保存实际 action、image、Kress oracle、Linton oracle、Riccati、Gauss 和 full-$P$ contraction
调用次数。任一禁止计数非零立即报告 `CERTIFICATE_IDENTITY_MISMATCH`，其优先级高于所有经验
结果；已经计算的 raw diagnostics 可保留，但不形成 cap。

所有 levels 必须逐项比对同一个 $\eta_{256}$、$\xi_{L/R,512}$、$P_\pm,c_\pm$、shared traces、
lift parameters、global normal、Bloch phase 和 basis normalization。array 尺寸错、非有限值或
identity label 冲突是 hard execution blocker。

## 3. 无 proxy 的同 kernel circle action

### 3.1 Project quasiperiodic Green kernel

固定 outgoing free-space fundamental solution

$$
\Phi_k(r)=\frac{\mathrm i}{4}H_0^{(1)}(k|r|).
$$

对 physical $y$-quasiperiodicity，数学 kernel 是

$$
G_{k,\beta}^{QP}(x,y)
=\Phi_k(x-y)
+\sum_{n\ne0}e^{\mathrm i\beta nd}
\Phi_k(x-y-nd e_y),
$$

其中求和按 non-Wood limiting-absorption/symmetric-image representation 理解。正相位保证 target
translation

$$
G_{k,\beta}^{QP}(x+d e_y,y)
=e^{\mathrm i\beta d}G_{k,\beta}^{QP}(x,y).
$$

本式已经使用项目的 $+\mathrm iH_0^{(1)}/4$ convention。独立 Linton oracle 中 reciprocal 和
real-space formulas 原本对应 $-\mathrm iH_0^{(1)}/4$；必须显式乘
`project_sign=-1` 后才能比较，禁止第二次变号。

冻结 source density Fourier convention：若

$$
f(\theta)=\sum_{\ell\in\mathcal I_{256}}a_\ell e^{\mathrm i\ell\theta},
\qquad
\mathcal I_N=\{-N/2,\ldots,N/2-1\},
$$

则 staged density samples 通过固定 FFT order 得到 $a_\ell$。边界输出统一改写到
$L^2(ds)$-orthonormal basis

$$
e_\ell(\theta)=\frac{e^{\mathrm i\ell\theta}}{\sqrt{2\pi R}},
\qquad
c_\ell=\sqrt{2\pi R}\,a_\ell.
$$

$-N/2$ 是保留的 Nyquist order，$+N/2$ 不属于 $\mathcal I_N$；所有 zero-padding、shell 和 nested
restriction 必须遵守这一个 convention。

### 3.2 Circle harmonic symmetric-image production

材料圆中心固定在原点。符号 `+` 表示 background exterior 的 global $+r$ trace，符号 `-` 表示
disk interior 的同向 trace。exterior 使用 $k_{\mathrm o}=\widehat k_h$ 的 $n=0$ free factor、全部
nonzero quasiperiodic images 和 wall single layers；interior 只使用
$k_{\mathrm i}=\sqrt{17}\widehat k_h$ 的 $n=0$ free factor。

对非零 image center $c_n=nd e_y$，令 target 相对于 $c_n$ 的极坐标为
$(r_n,\theta_n)$。source density $e^{\mathrm i\ell\phi}$ 的 prefactors 定义为

$$
C_\ell^S(k)=\frac{\mathrm i\pi R}{2}J_\ell(kR),
\qquad
C_\ell^D(k)=\frac{\mathrm i\pi R}{2}kJ_\ell'(kR).
$$

single- 和 double-layer image actions 是

$$
S_{\ell,n}(x)=C_\ell^S(k)
H_\ell^{(1)}(kr_n)e^{\mathrm i\ell\theta_n},
$$

$$
D_{\ell,n}(x)=C_\ell^D(k)
H_\ell^{(1)}(kr_n)e^{\mathrm i\ell\theta_n}.
$$

global target $+r$ derivative 由

$$
e_r^{\mathrm{tgt}}\!\cdot\!
\left[
e_{r_n}k(H_\ell^{(1)})'(kr_n)
+e_{\theta_n}\frac{\mathrm i\ell}{r_n}H_\ell^{(1)}(kr_n)
\right]e^{\mathrm i\ell\theta_n}
$$

分别乘 $C_\ell^S$ 或 $C_\ell^D$ 得到；不能再乘已经含 $H_\ell$ 的完整 $S_{\ell,n}$ 或
$D_{\ell,n}$。production 对 $n=\pm1,\ldots,\pm J$ 对称求和并乘
$e^{\mathrm i\beta nd}$，再按历史 convention 组合 $D\tau-S\zeta$；$\zeta=-\sigma$ 不变。

$n=0$ 的 free self action 不经过 image evaluator。令 $z=kR$，其解析 one-sided factors 包括

$$
S_\ell^0=\frac{\mathrm i\pi R}{2}J_\ell(z)H_\ell^{(1)}(z),
$$

$$
(D_\ell^0)^+
=\frac{\mathrm i\pi kR}{2}J_\ell'(z)H_\ell^{(1)}(z),
\qquad
(D_\ell^0)^-
=\frac{\mathrm i\pi kR}{2}J_\ell(z)(H_\ell^{(1)})'(z),
$$

$$
(\partial_rS_\ell^0)^+
=\frac{\mathrm i\pi kR}{2}J_\ell(z)(H_\ell^{(1)})'(z),
\qquad
(\partial_rS_\ell^0)^-
=\frac{\mathrm i\pi kR}{2}J_\ell'(z)H_\ell^{(1)}(z),
$$

$$
T_\ell^0
=\frac{\mathrm i\pi k^2R}{2}J_\ell'(z)(H_\ell^{(1)})'(z).
$$

Wronskian identities必须复算 $(D^0)^+-(D^0)^-=I$ 和
$(\partial_rS^0)^+-(\partial_rS^0)^-=-I$；因而 $-S\zeta$ 的
exterior-minus-interior global $+r$ normal jump 是 $+\zeta$。本项目 residual orientation 固定为

$$
j_\Gamma=\partial_r u_{\mathrm i}-\partial_r u_{\mathrm e},
$$

所以同一 $\zeta$ 项在 $j_\Gamma$ 中带相反号；artifact 和所有 fresh levels 都必须使用这个
orientation。
active `kernel.kress_l_splits` 和 `kernel.kress_mn_splits` 在同一 nodes 上只作独立 singular-action
oracle，不进入 production factors。

对高 $|\ell|$，不得直接相乘一个 underflow 的 $J_\ell(kR)$ 与 overflow 的
$H_\ell^{(1)}(kr_n)$。实现必须使用 scaled/log products、derivative-ratio recurrence、order
recurrence 和 Wronskian checks。任何 required product 非有限或 identity 不闭合时，该 component
报告 `CIRCLE_HARMONIC_ACTION_UNAVAILABLE`，禁止 clip、置零或删 mode。

### 3.3 Image 与 angular ladders

image-tail ladder 固定在 official target grid $N_\theta=2048$，并在一次 streamed
$|n|\le256$ traversal 中保存：

$$
J\in\{32,48,64,96,128,192,256\}.
$$

angular/action ladder固定 $J=256$，使用

$$
N_\theta\in\{512,1024,2048\}.
$$

source $\eta_{256}$ 的 Fourier coefficients 在全部 levels 完全相同；analytic source integration
使 source-quadrature refinement 是有公式证明的结构零。不得把零填充解释成重新求 density。

各 level 保存 circle raw exterior/interior value、global $+r$ normal、value difference、normal
difference、实际 $T_{\mathrm o}^{QP}-T_{\mathrm i}$ 作用及 induced factors。全部 target maps 先变换到
$\mathcal I_{N_\theta}$，再 zero-pad 到 $\mathcal I_{2048}$ 比较。为区分 circle output 和 wall
output，以下记 $\mathcal L_N:=\mathcal I_N$ 专指 circle angular coefficients；physical samples 的 nested check
使用 fine grid 每隔一点的 exact restriction，禁止 nearest node。

## 4. 两类 cross actions 与 wall maps

### 4.1 Wall densities 到 circle

冻结 wall order set $\mathcal I_{512}$、

$$
\beta_m=\beta+2\pi m/d,
\qquad
\gamma_m^2=k_{\mathrm o}^2-\beta_m^2,
$$

以及 outgoing/decaying branch。一个 wall mode 的 cell-interior single-layer field 是

$$
s_m(x,y;x_w)
=\frac{\mathrm i}{2\gamma_m}
e^{\mathrm i\gamma_m|x-x_w|}\psi_m(y),
\qquad
\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_my}.
$$

对 staged $\xi_{L/R,512}$，直接求和得到 circle targets 上的 value、$x/y$ derivatives 和 global
$+r$ normal。左 wall 在 cell 内的 global $+x$ derivative factor 为 $-1/2$，右 wall 为 $+1/2$；
$y$ derivative factor为 $\mathrm i\beta_m$。该解析 action 不解 wall system。

wall-to-circle 与 circle self action 相加后，才形成完整 raw circle value/normal maps，再施加冻结
circle value-only collar。禁止把 circle self refinement 当成完整 circle residual refinement。

### 4.2 Circle densities 到 walls

对右、左 wall，冻结 Rayleigh coefficient kernels

$$
\widehat G_{R,m}(x',y')
=\frac{\mathrm i}{2\gamma_m\sqrt d}
e^{\mathrm i\gamma_m(1/2-x')}e^{-\mathrm i\beta_my'},
$$

$$
\widehat G_{L,m}(x',y')
=\frac{\mathrm i}{2\gamma_m\sqrt d}
e^{\mathrm i\gamma_m(x'+1/2)}e^{-\mathrm i\beta_my'}.
$$

circle-to-wall coefficients由

$$
F_{R/L,m}[\eta]
=\int_\Gamma
\left[
\partial_{n'}\widehat G_{R/L,m}\,\tau
-\widehat G_{R/L,m}\,\zeta
\right]ds
$$

形成；它们只消费固定 $\eta_{256}$ 的解析 Fourier 表示。wall value 使用 $F_{R/L,m}$，cell-
outward flux 使用冻结的 $+\mathrm i\gamma_mF_{R/L,m}$ orientation。不得读取旧 proxy far-field
arrays 作为新 action。

wall common grids 冻结为

$$
N_y\in\{1024,2048,4096\}.
$$

fixed wall-source density 的 order set 始终是 $\mathcal I_{512}$；它在较大 wall output sets 上只做
zero-padding，不产生新 source coefficients。circle density 可激发完整 output sets
$\mathcal I_{1024},\mathcal I_{2048},\mathcal I_{4096}$，所以 wall refinement 测量的是 response
orders 而不是 source-density refinement。fixed $\xi_{L/R,512}$ 的 wall-self value/flux 由解析 modal
block形成，circle action与之相加后得到完整 raw wall value/normal maps。每一级通过 exact Fourier
evaluation 到 $y_j=jd/N_y$；physical Bloch basis 和 periodic gauge 分开保存。比较一律在 common
$\mathcal I_{4096}$ coefficients 或 fine-to-coarse exact restriction 上进行。

### 4.3 接口完整性

每一级必须保存并重组：

- circle exterior/interior raw values 和同一 global $+r$ derivatives；
- left/right raw wall values 和 cell-outward flux；
- center actual/shared traces 与 center-side value-lift singletons；
- lead shared $g=D_\pm c_\pm$，不得换成 incoming trace；
- repaired wall/circle value identities；
- physical Bloch value/flux 和 gauged periodic identities；
- safe rim value/derivative identities；
- $\pm1/2$ jumps、$\zeta=-\sigma$、scaled/physical roundtrip。

raw wall/circle value mismatch 是经验评价对象，不适用 $10^{-10}$ structural gate；只有显式 lift
后的 repaired identity 使用 $10^{-10}$。所有有限但较大的 raw/refinement defects 都 fail-open，
但会使相应经验 cap unresolved。

## 5. 同一个 trial 的 residual factors

### 5.1 Frozen value lifts

wall strips、circle collar、common traces、widths 和 cubic shapes 与 `fbie-a1` 完全相同。新 levels
只改变 raw boundary values 的 ordinary evaluation，因此重新计算相同 lift 公式的 source，不允许
改变 support、width 或 interpolation shape。数学上的 amplitude 始终是冻结 finite density 作用于
continuous exact kernel 得到的 exact raw trace defect；artifact 与 fresh levels 只是同一 amplitude
的不同 ordinary approximations，不是重新定义 lift 或 trial。

完整 residual 仍分为三项：

$$
B_W=\text{artificial-wall normal-jump contribution},
$$

$$
B_\Gamma=\text{material-circle normal-jump contribution},
$$

$$
B_V=\text{wall/circle value-lift volume-source contribution},
$$

并以三角和

$$
M=B_W+B_\Gamma+B_V
$$

组合。raw wall/circle **value** maps 只通过 $B_V$ 进入；raw wall **normal** 只进入 $B_W$；raw
circle **normal** 只进入 $B_\Gamma$。同一个 raw difference 不得作为单列 cap 再加一次。

所有 quadratic factors 继续用 true $\rho$、相同 trace/Riccati weights 和 lift Gauss formulas。
Riccati levels 固定为

$$
N_\gamma\in\{512,1024,2048\},
$$

radial lift Gauss levels 固定为

$$
N_G\in\{32,64,128\}.
$$

每个 Gram 由 positive factor $F^*F$ 形成；显著 non-Hermitian/indefinite、required weight 非正或
非有限使该 component unavailable，禁止 eigenvalue clipping。

### 5.2 Full-$P$ global contractions

左右 lead 保留完整 $97\times97$ $P_\pm$ 及 nonnormal/Jordan coupling。每个 component 的 global
quantity 形如

$$
\sum_{n=n_0}^{\infty}
c^*(P^*)^nWP^nc,
$$

禁止逐 multiplier、$P^{-1}$ 或只看谱半径。center、first cell、wall-side lifts、circle 和 field 的
off-by-one/index association 完全沿用冻结 artifact；每一级都保存 first four direct actions 供机器
复算。

full-$P$ evaluation ladder固定 $N=8,16,32$。对一个 $K\times K$ one-cell Gram $W$ 定义

$$
W_N=\sum_{j=0}^{N-1}(P^j)^*WP^j,
$$

并递推

$$
W_{2N}=W_N+(P^N)^*W_NP^N,
\qquad
P^{2N}=P^NP^N.
$$

对 frozen state $c$，scalar partial 是

$$
s_N(c)=c^*W_Nc.
$$

为使 $N=8,16,32$ 和 artifact/fresh 之间的 factor difference 唯一，冻结
$N_{\max}=32$。对每个 side/component，令 $H_X^*H_X=W_X$ 是它在§7.1 canonical
coordinates 上的 one-cell positive factor，并定义零填充的 direct-action vector

$$
v_{X,N}^{\pm}
=\operatorname{pad}_{32}
\begin{bmatrix}
H_X^\pm c_\pm\\
H_X^\pm P_\pm c_\pm\\
\vdots\\
H_X^\pm P_\pm^{N-1}c_\pm
\end{bmatrix}.
$$

ordinary tail candidate 使用冻结 `design-3-1f` 公式的非负 scalar

$$
t_{X,N}^{\pm}(c_\pm)
=\frac{(a_{X,N}^{\pm,\mathrm{hi}})^2}
{1-(a_{X,N}^{\pm,\mathrm{hi}})^2}
\bigl(\|W_{X,N}^{\pm,\mathrm L}\|_2+\omega_{X,N}^{\pm}\bigr)
\|c_\pm\|_2^2.
$$

它在每个 side 占一个固定 scalar coordinate
$\sqrt{t_{X,N}^{\pm}}$；$W=0$ 时该 coordinate 精确为零。center/first-cell singletons 也各占
固定槽位。因此 §7.1 的 augmented vector 必须按唯一顺序实现为

$$
F_X^{(N)}=
\begin{bmatrix}
F_{X,\mathrm{center/first}}\\
v_{X,N}^{-}\\
\sqrt{t_{X,N}^{-}}\\
v_{X,N}^{+}\\
\sqrt{t_{X,N}^{+}}
\end{bmatrix}.
$$

比较不同 $N$ 时只能对这个固定维数向量取 difference；不得相减不同长度的
direct rows，也不得把 $t_N$ 与 finite rows 混为一个可任意分配的 scalar。若
$a^{\mathrm{hi}}\ge1$、$t_N$ 非有限/负或其 association 不能重构，该 ordinary component
cap unavailable。

scale-covariant roundoff allowance 使用实际 $\|W\|$；$W=0$ 时 allowance 保持零。required
component、mandatory $W=I$ state tail 或 same-partial field factor 没有任何 finite level 时，经验
cap unavailable。finite tail share 大只记 warning；本设计不把 ordinary tail 叫 certified tail。

## 6. Independent analytic oracles

### 6.1 Free singular oracle

在 $N_\theta=512,1024,2048$ 上，用 active Kress split独立比较 §3.2 的 free-space analytic
$S,D^\pm,\partial_rS^\pm,T$ factors。至少覆盖 manufactured
$\ell=0,\pm1,\pm2$、两种 wavenumbers、$\pm1/2$ jumps、$\zeta=-\sigma$ 和 physical scaling。
production 不调用 oracle matrix作为 action。

### 6.2 Off-axis Linton oracle

只在预注册的 nonsingular off-axis displacement set

$$
(\Delta x,\Delta y)\in\{
(0.30,-0.066),(0.20,-0.066),(0.10,-0.066),
(0.263,0.173),(-0.217,0.287)
\}
$$

和 manufactured $\ell=0,\pm1,\pm2$ harmonic actions 上使用 Linton analytic
value/gradient/Hessian evaluator。最后一个负-$\Delta x$ point 必须独立消费
$s_x=\operatorname{sign}(x_t-x_s)$，不能先取绝对值后漏掉 physical derivative sign。冻结 physical displacement
和 Linton internal coordinates 为

$$
\Delta x=x_t-x_s,
\qquad
\Delta y=y_t-y_s,
\qquad
X_L=|\Delta x|,
\qquad
Y_L=\Delta y.
$$

$Y_L$ 是 period-$d$ direction，$X_L\ge0$ 是 Linton Eq. (2.65) 内部的 transverse
distance。production/oracle 只向 Linton scalar formulas 传入 $(X_L,Y_L)$，再显式恢复 physical
target derivatives：

$$
G_{x_t}=s_xG_{X_L},
\qquad
G_{y_t}=G_{Y_L},
$$

$$
G_{x_tx_t}=G_{X_LX_L},
\qquad
G_{x_ty_t}=s_xG_{X_LY_L},
\qquad
G_{y_ty_t}=G_{Y_LY_L}.
$$

source derivatives 由 displacement 关系取反号：
$\nabla_{x_s}G=-\nabla_{x_t}G$，且 source--target mixed derivatives 按该符号逐项组装。
不得把 signed $\Delta x$ 直接送入 Eq. (2.65)，也不得沿用旧 proxy 的
computational-axis swap。
Rayleigh branches 必须满足 $\operatorname{Re}\gamma_m\ge0$ 且
$\operatorname{Im}\gamma_m\ge0$，propagating/evanescent class 逐 order 保存。冻结 tuples 为

$$
E_0=(a,M_1,M_2,N_s)=(2,26,18,28),
$$

$$
E_1=(2,34,24,36),
\qquad
E_2=(2,42,30,44).
$$

它检查：project sign、target Bloch phase、source inverse phase、Helmholtz identity、source/target
derivative signs、mixed derivative 和 harmonic image action。任何 pair 都必须满足 transverse
separation $X_L\ne0$；oracle 不提供 self diagonal，也不重建 proxy。

公式 authority 是 C. M. Linton, “The Green's function for the two-dimensional Helmholtz
equation in periodic domains,” *Journal of Engineering Mathematics* 33 (1998), 377--402,
[DOI 10.1023/A:1004377501747](https://doi.org/10.1023/A:1004377501747)；
[[ref/ref_data/Linton1998.pdf|local original]] Eq. (2.65), PDF p. 13 / journal p. 389。该式给出参考
periodic Green representation；项目的 coordinate、derivative 和 single-project-sign 适配由
[[test/archive/legacy-route-v1/i4-three-path-derivatives/derivation|frozen analytic derivative derivation]]
逐式给出，现有资格化实现位置是
[[test/archive/legacy-route-v1/i4-three-path-derivatives/run_i4_three_path_derivatives.m|three-path derivative source]]
的 `LOCAL_linton_reciprocal`、`LOCAL_linton_real_space` 和 `LOCAL_project_kernel`。本设计只能在新
helper 中局部实现这些公式，不能把 archive 当 runtime dependency。

每个 tuple 保存冻结 branch classes 下的 relative Wood margin

$$
\delta_{\mathrm{Wood}}
=\min_m\frac{|k_{\mathrm o}^2-\beta_m^2|}
{k_{\mathrm o}^2+\beta_m^2},
$$

outgoing branch classes、$\gamma_m$ signs、project conversion 和 tuple truncations。`exact Wood` 精确指存在
$m$ 使 $k_{\mathrm o}^2-\beta_m^2=0$；此时或任一 branch 非有限时 oracle/action
unavailable。finite positive small margin 只记 warning，不得与 exact Wood 混同。

finite oracle defect 大于冻结 threshold 是 nonblocking warning，但使 `kernel_qualified=false`，并使
依赖它的 empirical kernel cap unresolved。oracle 不是 independent reference，不能进入 I3.3
effectivity 数据集。

## 7. 预注册 empirical evaluation cap

### 7.1 Common induced norms 和 roundoff floor

对每个 residual component

$$
X\in\{W,\Gamma,V\},
$$

raw value/normal maps 必须先进入一个唯一 canonical representation：

- circle normal 和 circle-lift amplitudes 用 $\mathcal I_{2048}$ 的 $L^2(ds)$-orthonormal
  coefficients；
- wall normal 和 wall-lift amplitudes 用 $\mathcal I_{4096}$ 的 physical Bloch coefficients；
- circle 体源在 $\mathcal I_{2048}\times N_G=128$ 的 weighted Fourier--Gauss coordinates 上评价；
- wall 体源在 $\mathcal I_{4096}\times N_G=128$ 的 weighted Fourier--Gauss coordinates 上评价。

staged input 因此必须包含 artifact raw wall defects、circle value differences/normal jumps 和
lift source maps；只保存旧 Gauss-32 factor rows 不足以形成这个比较。artifact 和 fresh lift
都由同一个 exact-trace-derived support/shape rule 重评价到上述 final coordinates；这只改进
同一 exact amplitude 的普通数值近似，不改变 $\mathcal T(z_h)$。若上述 raw maps 无法从
whitelist 重构，报告 `ARTIFACT_FACTOR_COMMON_MAP_UNAVAILABLE`，不允许直接相减不同行数的
Gauss factors。

在此 canonical Hilbert direct sum $\mathcal C_X$ 中，把 fixed state、center singletons、左右
full-$P$ partial/tail associations 都施加后的 augmented component vector 记为 $F_X$，并冻结

$$
B_X=\|F_X\|_{\mathcal C_X},
\qquad
D_X(F_1,F_0)=\|F_1-F_0\|_{\mathcal C_X}.
$$

这里的 factor 必须包含 artifact/fresh 的同一 phase、first-cell、tail allowance 和 parenthesization
association。若 artifact tail 无法嵌入同一 $\mathcal C_X$，则该 component 报告
`ARTIFACT_FACTOR_ASSOCIATION_UNAVAILABLE`，不得用 scalar 差替代。反三角不等式给出

$$
|B_X^{(1)}-B_X^{(0)}|
\le D_X(F_X^{(1)},F_X^{(0)}).
$$

因此 scalar 和 factor 变化是同一 observed shift 的两种评价，不是两个可相加的误差。
实现必须核对 $|\Delta B_X|\le D_X+\omega_X$；不成立时报告
`COMPONENT_NORM_ASSOCIATION_UNRESOLVED`。不得用未加权 Frobenius norm 替代 $D_X$。

每个 raw metric 保存 difference numerator、两侧 norms、zero-component flag、physical scale 和
scale-covariant ratio。roundoff floor 固定为

$$
\omega=100\,n_{\mathrm{op}}\epsilon_{\mathrm{mach}}s,
$$

其中 $n_{\mathrm{op}}$ 是预先记录的实际 contraction count，$s$ 是未相消的两侧 induced norms 与
相关 $B$ values 的最大值；禁止 `max(1,s)`。结构证明为零的对象才允许 exact zero。

### 7.2 Artifact 到 fresh final 的 observed shift 只计一次

令 artifact component/factor 为 $(B_X^{\mathrm{art}},F_X^{\mathrm{art}})$，全部 fresh axes 的最终
对象为 $(B_X^*,F_X^*)$。先定义 raw observed shift

$$
A_X^{\mathrm{obs}}=\max\left\{
|B_X^*-B_X^{\mathrm{art}}|,
D_X(F_X^*,F_X^{\mathrm{art}})
\right\}.
$$

另定义 comparison-specific roundoff allowance

$$
\omega_{X,\mathrm{cmp}}
=100n_{X,\mathrm{cmp}}\epsilon_{\mathrm{mach}}s_{X,\mathrm{cmp}},
$$

其中 $n_{X,\mathrm{cmp}}$ 包括 artifact/fresh 两端 augmented vectors、两个 norms 和
difference/subtraction 的全部 operations，$s_{X,\mathrm{cmp}}$ 是两端未相消 vector norms 和
$B$ values 的最大值。这个 $\omega_{X,\mathrm{cmp}}$ 是两端加 subtraction 的合并
allowance，不是单端 floor。最终取

$$
A_X=A_X^{\mathrm{obs}}+\omega_{X,\mathrm{cmp}}.
$$

$A_X$ 是 artifact 到 fresh final 的累计 observed shift 及其 comparison arithmetic，只加入
一次。§7.7 的 $R_{X,\mathrm{arith}}$ 只覆盖 true-minus-final remainder 中的 fresh-final
assembly arithmetic，
$\omega_{X,\mathrm{cmp}}$ 只覆盖 artifact-to-final 比较，两者不是同一 ledger item。artifact 到 fresh 512 的
差必须保存，但不另加，因为已经包含在 $A_X$ 内。fresh coarse levels 只估计 true-minus-final
remainder；它们的 observed shifts 不再逐 axis 重复相加。

这个定义对应经验分解

$$
\text{true}-\text{artifact}
=(\text{final}-\text{artifact})
+(\text{true}-\text{final}).
$$

### 7.3 Axis association 和无重复计数

每条 one-axis ladder 只改变表中的一个 coordinate，其余 numerical axes 都固定在 fresh-final
level。这是唯一 official association；禁止在运行时改用“其余都在 coarse”或选较好的
telescoping path。

| axis $a$ | frozen ladder | affected component coordinates | 不变 coordinates |
|---|---|---|---|
| image | $J=32,48,64,96,128,192,256$ at $N_\theta=2048$ | $F_\Gamma$ 和 $F_{V,\mathrm{circle}}$ | angular, wall, Riccati, Gauss, full-$P$ final |
| circle angular | $N_\theta=512,1024,2048$ at $J=256$ | $F_\Gamma$ 和 $F_{V,\mathrm{circle}}$ | image, wall, Riccati, Gauss, full-$P$ final |
| wall output | $N_y=1024,2048,4096$ with source $\mathcal I_{512}$ fixed | $F_W$ 和 $F_{V,\mathrm{wall}}$ | image, angular, Riccati, Gauss, full-$P$ final |
| Riccati | $N_\gamma=512,1024,2048$ | $F_\Gamma$ | all boundary actions, Gauss, full-$P$ final |
| lift Gauss | $N_G=32,64,128$ | $F_{V,\mathrm{circle}}$ 和 $F_{V,\mathrm{wall}}$ | all boundary actions, Riccati, full-$P$ final |
| full-$P$ | $N=8,16,32$ | $F_W,F_\Gamma,F_V$ | all action/weight/Gauss axes final |

$F_V$ 的 circle 和 wall 子块在 canonical direct sum 中分开形成 axis differences，最后才用同一
volume-component norm 组合。这样 raw circle/wall value 不会被 image/angular 和 wall axes 双计。

另存一个不加入 allowance 的 joint holdout：比较“所有 axes 在各自 penultimate level”与
fresh-final，并要求其 induced difference 不大于各 official one-axis final-leg differences 之和加
roundoff floor。该门只检查 mixed-axis association，不再加一次 observed shift；失败时报告
`AXIS_INTERACTION_EMPIRICALLY_UNRESOLVED`。

### 7.4 非 image axes 的 $0.5/2\times$ 规则

对 angular grid、wall common grid、Riccati、Gauss 和 full-$P$ evaluation 等预期谱或快速收敛
axis，三层得到 $(B_0,F_0),(B_1,F_1),(B_2,F_2)$。令

$$
d_1=\max\{|B_1-B_0|,D_X(F_1,F_0)\},
$$

$$
d_2=\max\{|B_2-B_1|,D_X(F_2,F_1)\}.
$$

- 若 $d_1,d_2\le\omega$，标记 `NEAR_ZERO` 并取 $R_{X,a}=2\omega$；
- 若 $d_1>\omega$ 且 $d_2\le\max\{0.5d_1,\omega\}$，取
  $R_{X,a}=2\max\{d_2,\omega\}$；
- 其他情况标记该 axis `EMPIRICAL_AXIS_UNRESOLVED`。

不得结果后更换 safety factor、跳过中间层、加入第四层或选择较好的一对 differences。

### 7.5 Symmetric image 的 $0.80/5\times$ 规则

未加速二维 Hankel symmetric-image tail 预期只有 $O(J^{-1/2})$，所以故意不用会形成已知负门的
$0.5$ contraction。以下 $X$ 分别代表 circle-normal coordinate $\Gamma$ 和
circle-volume coordinate $(V,\mathrm{circle})$；其他 axes 按 §7.3 固定在 final，并定义

$$
d_{64\to128}^{X}
=\max\{|B_{X,128}-B_{X,64}|,
D_X(F_{X,128},F_{X,64})\},
$$

$$
d_{128\to256}^{X}
=\max\{|B_{X,256}-B_{X,128}|,
D_X(F_{X,256},F_{X,128})\},
$$

$$
d_{48\to96}^{X}
=\max\{|B_{X,96}-B_{X,48}|,
D_X(F_{X,96},F_{X,48})\},
$$

$$
d_{96\to192}^{X}
=\max\{|B_{X,192}-B_{X,96}|,
D_X(F_{X,192},F_{X,96})\},
$$

以及只用于连接 staggered final 到 official final 的

$$
d_{\mathrm{cross}}^{X}
=\max\{|B_{X,256}-B_{X,192}|,
D_X(F_{X,256},F_{X,192})\}.
$$

每个 difference 保存 numerator、两侧 scales、zero flag 和 $\omega_{X,\mathrm{img}}$。dyadic
sequence 在两个 differences 都不超过 $\omega_{X,\mathrm{img}}$ 时标记 `NEAR_ZERO`；否则必须满足

$$
d_{128\to256}^{X}
\le\max\{0.80d_{64\to128}^{X},\omega_{X,\mathrm{img}}\}.
$$

staggered sequence 同理：若不是 near-zero，必须满足

$$
d_{96\to192}^{X}
\le\max\{0.80d_{48\to96}^{X},\omega_{X,\mathrm{img}}\}.
$$

$d_{\mathrm{cross}}^{X}$ 不另造一个 contraction ratio，但必须 finite 并进入 remainder。通过时定义

$$
R_{X,\mathrm{img}}
=5\max\{d_{128\to256}^{X},d_{96\to192}^{X},
d_{\mathrm{cross}}^{X},\omega_{X,\mathrm{img}}\}.
$$

系数 $5=1/(1-0.8)$ 只是预注册经验 remainder factor，不是无限 image tail 的证明。任一序列不
收缩、非有限或 scale 不可形成时报告 `IMAGE_TAIL_EMPIRICALLY_UNRESOLVED`；禁止改 $J$、改为
Ewald production 或把该分量设零。

### 7.6 未计算 Fourier tail

两个 output families 分别形成 shells，禁止把 circle $2048$ 的 shell 套到 wall $4096$
representation。circle family 用

$$
\mathcal L_{1024}\setminus\mathcal L_{512},
\qquad
\mathcal L_{2048}\setminus\mathcal L_{1024},
$$

只进入 $F_\Gamma$ 和 $F_{V,\mathrm{circle}}$。wall family 用

$$
\mathcal I_{2048}\setminus\mathcal I_{1024},
\qquad
\mathcal I_{4096}\setminus\mathcal I_{2048},
$$

只进入 $F_W$ 和 $F_{V,\mathrm{wall}}$。每个 family/component 的 induced shell norms 记为
$S_1^{X,f},S_2^{X,f}$。若二者 near-zero，取
$\Phi_{X,f}=2\omega_{X,f}$；若

$$
S_2^{X,f}\le\max\{0.5S_1^{X,f},\omega_{X,f}\},
$$

取

$$
\Phi_{X,f}=2\max\{S_2^{X,f},\omega_{X,f}\}.
$$

否则该 family/component 的未计算 Fourier tail 为 unresolved。组合规则是

$$
\Phi_W=\Phi_{W,\mathrm{wall}},
\qquad
\Phi_\Gamma=\Phi_{\Gamma,\mathrm{circle}},
$$

$$
\Phi_V=\Phi_{V,\mathrm{circle}}+\Phi_{V,\mathrm{wall}}.
$$

所有 $\mathcal L_{2048}$ circle modes 和 $\mathcal I_{4096}$ wall modes 都进入各自 $B_X^*$；
shell diagnostic 不能被解释为删除 high modes，也不是 outward tail bound。

### 7.7 Numerator cap、arithmetic allowance 和禁止 double count

对每个 final component 用三条普通双精度路径复算：(i) canonical augmented factor 的 direct
norm；(ii) 同一 factor 形成 Gram 后的 quadratic contraction；(iii) compensated/binary-tree
state-action accumulation。令三个 scalar results 的最大 pairwise spread 为 $r_{X,\mathrm{arith}}$，
未相消 scale 为 $s_{X,\mathrm{arith}}$，并冻结

$$
\omega_{X,\mathrm{arith}}
=100n_{X,\mathrm{arith}}\epsilon_{\mathrm{mach}}s_{X,\mathrm{arith}}.
$$

若任一路径非有限，或
$r_{X,\mathrm{arith}}>\omega_{X,\mathrm{arith}}$，报告
`COMPONENT_ARITHMETIC_EMPIRICALLY_UNRESOLVED`。通过时取

$$
R_{X,\mathrm{arith}}
=2\max\{r_{X,\mathrm{arith}},\omega_{X,\mathrm{arith}}\}.
$$

最终经验 component allowances 是

$$
\epsilon_X^{\mathrm{emp}}
=A_X+\sum_{a\in\mathcal A_X}R_{X,a}
+\Phi_X+R_{X,\mathrm{arith}},
$$

其中 $\mathcal A_X$ 严格由 §7.3 的 incidence table 决定。总 numerator cap 是

$$
\epsilon_M^{\mathrm{emp}}
=\epsilon_W^{\mathrm{emp}}
+\epsilon_\Gamma^{\mathrm{emp}}
+\epsilon_V^{\mathrm{emp}}.
$$

raw wall/circle value differences只进入 $F_V$；raw wall normal differences只进入 $F_W$；raw
circle normal differences只进入 $F_\Gamma$。raw maps、scalar component shift 和 factor shift
之间使用 §7.2 的 `max`，不是相加。缺少 evaluator、image、Fourier、lift、full-$P$ 或 arithmetic
中的任何 required allowance 时，总状态是 `EMPIRICAL_CAP_UNRESOLVED`。

### 7.8 Denominator 的 one-sided finite-partial cap

$\widetilde N_h$ 是 artifact 故意采用的 finite-partial field lower center，不是完整 infinite field
norm。省略的正 field tail 只能提高数学 lower quantity，不能作为 downward error 加入
$\epsilon_N^{\mathrm{emp}}$。

formal attempt 必须用同一个 frozen shared $g$、field factors、indices、first-cell convention 和
parenthesization contract，重算 artifact 使用的**同一个 finite partial**，记为 $N_{\mathrm{same}}$。
定义

$$
A_N^{\mathrm{obs}}
=\max\{0,\widetilde N_h-N_{\mathrm{same}}\}.
$$

为了覆盖 historical anchor 读取、fresh same-partial 形成和 subtraction，冻结

$$
\omega_{N,\mathrm{cmp}}
=100n_{N,\mathrm{cmp}}\epsilon_{\mathrm{mach}}
\max\{\mathrm{realmin},|\widetilde N_h|,|N_{\mathrm{same}}|\},
$$

$$
A_N=A_N^{\mathrm{obs}}+\omega_{N,\mathrm{cmp}}.
$$

$n_{N,\mathrm{cmp}}$ 覆盖两端和 subtraction 的全部 operations。保存
$|\widetilde N_h-N_{\mathrm{same}}|$ 和 $A_N^{\mathrm{obs}}$，但向上的差不形成 downward
physical allowance；$\omega_{N,\mathrm{cmp}}$ 仍要为 comparison arithmetic 提供 one-sided
roundoff。action、kernel、
Riccati 和 lift axes 对 field lower 是结构零，因为 field 只消费 staged shared $g$ 和固定 trace
weights；实现必须保存该 dependency proof，不能只写 Boolean。

同一 finite partial 另由三条预注册普通双精度路径复算：direct factor action、Gram quadratic
contraction、binary-tree/compensated accumulation。令三者的最大 pairwise 差为 $r_N$，实际量级
为 $s_N$，

$$
\omega_N=100n_N\epsilon_{\mathrm{mach}}s_N.
$$

若任一结果非有限，或 $r_N$ 超过冻结 arithmetic qualification scale，则 denominator empirical
cap unresolved；通过时取

$$
R_N=2\max\{r_N,\omega_N\},
\qquad
\epsilon_N^{\mathrm{emp}}=A_N+R_N.
$$

$N=8,16,32$ 的 positive full-$P$ growth 只作 direction/index diagnostic：显著负增量使 field
association unresolved，正增量不加入 $\epsilon_N^{\mathrm{emp}}$，也不能用
$|N_{32}-N_8|$ 作为 downward cap。必须满足

$$
\widetilde N_h-\epsilon_N^{\mathrm{emp}}>0.
$$

本式仍是 ordinary empirical denominator，不是严格 lower enclosure。

### 7.9 经验 $q$ 和名义变换

全部 required component caps 形成后定义

$$
q_{\mathrm{emp}}
=\frac{\widetilde M_h+\epsilon_M^{\mathrm{emp}}}
{\sqrt{\widetilde N_h-\epsilon_N^{\mathrm{emp}}}}.
$$

若 $q_{\mathrm{emp}}<1$，只保存与 `design-3-2a` 相同的 asymmetric algebraic transform；它的
label 是 `EMPIRICAL_NOMINAL_TRANSFORM`。不能把 `emp` 字段复制到 strict
$\epsilon_M,\epsilon_N,\overline q_h$ 字段，也不能触发条件性定理。

## 8. Internal qualification metrics

以下 threshold 全部在看新结果前冻结：

| 对象 | metric | threshold / zero semantics | 失败语义 |
|---|---|---|---|
| NO_RESOLVE | 八个禁止计数 | 必须严格为 0 | hard identity failure |
| Circle angular/action | §7.4 induced $d_2/d_1$ | $\le0.5$；near-zero 用 $\omega$ | cap unresolved |
| Symmetric image | §7.5 两个 adjacent dyadic/staggered ratios 和 $d_{\mathrm{cross}}$ | 两 ratios $\le0.80$；cross finite | image cap unresolved |
| Wall common grid | §7.4 value/flux induced ratios | $\le0.5$；zero-scale 单列 | wall cap unresolved |
| Circle/wall Fourier shells | §7.6 两个 family-specific induced shell ratios | 各自 $\le0.5$；所有 computed modes 保留 | Fourier cap unresolved |
| Riccati | weight/action induced ratio | $\le0.5$；weight 必须 positive finite | warning 或 unavailable |
| Lift Gauss | $B_V$ 与 factor ratio | $\le0.5$ | volume cap unresolved |
| Full-$P$ | component contraction ratio | $\le0.5$；share 仅 warning | cap unresolved if no level |
| Axis association | all-penultimate joint induced shift | $\le$ official final-leg shifts 之和 $+\omega$ | interaction unresolved |
| Component norm association | $|\Delta B_X|/D_X$ | $|\Delta B_X|\le D_X+\omega_X$ | association unresolved |
| Anchor comparison arithmetic | artifact/fresh operation-count floor | finite $\omega_{X,\mathrm{cmp}}$，必须加入 $A_X$ | component unavailable if nonfinite |
| Numerator arithmetic | direct-factor/Gram/compensated spread | $\le100n_X\epsilon_{\mathrm{mach}}s_X$ | component cap unresolved |
| Repaired values | shared/repaired identity | $\le10^{-10}$ | conformity unavailable |
| Bloch value/flux | paired physical/gauge norm ratio | $\le10^{-10}$ | qualification false |
| Safe rim | value/derivative ratio | $\le10^{-10}$ | qualification false |
| Jumps/signs | $\pm1/2$, Wronskian, $\zeta=-\sigma$ | $\le10^{-10}$ | qualification false/unavailable |
| Scaling | physical/scaled roundtrip | $\le10^{-10}$ | qualification false |
| Linton/Kress oracle | weighted analytic defect | $\le10^{-8}$ | kernel cap unresolved |
| Field-anchor comparison arithmetic | anchor/same-partial operation-count floor | finite $\omega_{N,\mathrm{cmp}}$，必须加入 $A_N$ | denominator unavailable if nonfinite |
| Arithmetic field | same-partial path spread | $\le100n_N\epsilon_{\mathrm{mach}}s_N$ | denominator cap unresolved |

每个 metric 保存 numerator、两侧 norms、scale、zero flag、ratio、threshold 和 pass。历史
$0.77408786032496468$ 只放 `historical_diagnostics`，不作为新 $d_1$。finite threshold failure
fail-open：继续保存后续 raw levels；只有对象非有限、required weight 非正、conformity 无法形成或
required component 无任何 finite level 才使 $q_{\mathrm{emp}}$ 不可定义。

## 9. Failure 和 claim lattice

failure precedence 固定如下：

1. `ATTEMPT_ALREADY_CONSUMED`；
2. `CERTIFICATE_INPUT_UNAVAILABLE`；
3. `CERTIFICATE_IDENTITY_MISMATCH` 或禁止 solve counter 非零；
4. `BRANCH_OR_WOOD_UNAVAILABLE`；
5. `RESOURCE_BUDGET_UNAVAILABLE` / hard time / hard memory；
6. required action、weight、factor、Gram、conformity 或 field partial numerically unavailable；
7. `EMPIRICAL_CAP_UNRESOLVED` 及其首个 component/axis reason；
8. finite $q_{\mathrm{emp}}$ 的 nominal statuses。

具体 claim lattice 是：

| 状态 | 触发条件 | 可保留内容 |
|---|---|---|
| `CERTIFICATE_INPUT_UNAVAILABLE` | staging/input/schema 不成立 | 历史 `fbie-a1` 结果不变；无新 attempt |
| `CERTIFICATE_IDENTITY_MISMATCH` | level 改变 frozen object 或隐藏 solve | 保存已算 raw diagnostics；无 cap |
| `BOUNDARY_ACTION_UNAVAILABLE` | required kernel/action 非有限或维数错 | 保存较早 levels；无总 cap |
| `ARTIFACT_FACTOR_COMMON_MAP_UNAVAILABLE` | staged raw maps 无法形成 common representation | 保存 action levels；无 component cap |
| `COMPONENT_NORM_ASSOCIATION_UNRESOLVED` | reverse-triangle/phase/tail association 不闭合 | 保存 scalar 和 factor diagnostics |
| `EMPIRICAL_AXIS_UNRESOLVED` | 非 image axis 未按 $0.5$ 收缩 | 保存三层数据；对应 component cap 不形成 |
| `AXIS_INTERACTION_EMPIRICALLY_UNRESOLVED` | joint holdout 超过 official final-leg shifts 之和 | 保存逐 axis data；不形成 cap |
| `IMAGE_TAIL_EMPIRICALLY_UNRESOLVED` | dyadic/staggered image 门失败 | 保存 image ladder；对应 component cap 不形成 |
| `FOURIER_TAIL_EMPIRICALLY_UNRESOLVED` | shell 门失败 | 所有 computed modes 仍保留；总 cap 不形成 |
| `COMPONENT_ARITHMETIC_EMPIRICALLY_UNRESOLVED` | numerator 三路径 spread 超门 | 保存 component levels；不形成 cap |
| `FIELD_PARTIAL_EMPIRICALLY_UNRESOLVED` | same-partial 或 arithmetic envelope 不成立 | 保留 numerator cap；不形成 $q_{\mathrm{emp}}$ |
| `EMPIRICAL_CAP_UNRESOLVED` | 任一 required component/denominator cap 缺失 | 保留 ordinary anchor 和全部 refined diagnostics |
| `EMPIRICALLY_SUPPORTED_EVALUATION_CAP` | 所有经验 cap 规则闭合 | 只得到 same-trial evaluation cap |
| `EMPIRICAL_NOMINAL_INTERVAL_UNAVAILABLE` | finite $q_{\mathrm{emp}}\ge1$ | 保留经验 cap；无有限 interval |
| `EMPIRICAL_RESOLUTION_INSUFFICIENT` | $q_{\mathrm{emp}}<1$ 但 width $>10^{-6}$ | 保留经验 nominal transform；不称分辨率合格 |
| `EMPIRICAL_NOMINAL_TRANSFORM` | $q_{\mathrm{emp}}<1$ 且 width $\le10^{-6}$ | 只保存 ordinary algebraic interval |

无论状态多好，以下 flags 恒为 false：

```text
rigorous_cap
outward_residual_upper
outward_field_lower
outward_tail_enclosure
reliable_interval
same_operator_gap_certified
spectral_intersection_certified
discrete_existence
unique_mode_identified
independent_reference
```

same-chain Linton/Kress oracles 和 nested data 不得进入 I3.3 independent reference，也不得在看到
结果后用于修改本设计的 levels、thresholds 或 factors。

## 10. 最低实现、schema 与资源

### 10.1 文件边界

Skeptic `DESIGN PASS` 后才允许建立：

- `test/i3/e-cap/check_e_cap.m`：runtime contract、explicit input、NO_RESOLVE counters、stage
  orchestration、schema、status 和 report；
- `test/i3/e-cap/i32_same_eval.m`：harmonic image、两类 cross actions、Kress/Linton oracles、
  boundary maps 和 fixed lifts；
- `test/i3/e-cap/README.md`：唯一命令、attempt、输入和 claim boundary。

优先只用 entry 加一个 scientific helper。只有 helper 确实超过 1000 行时，才可按“boundary
evaluation”和“cap/full-$P$ contraction”边界新增 `i32_cap_tail.m`；不得为了 utilities 或抽象接口
继续拆文件。comments 使用 English、2-space indentation 和 `LOCAL_` groups。

### 10.2 Attempt、command 和 append-only output

未来唯一 attempt 是 `ecap-a1`，`retry_count=0`，`prior_failed_attempt_count=0`。正式命令候选
冻结为显式 input 形式：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','e-cap')); check_e_cap('ecap-a1',fullfile(pwd,'test','i3','e-cap','input','fbie-a1-certificate.mat'));"
```

entry 本身不得发现 repository root 或拼历史路径。未来 output 是

```text
test/i3/e-cap/output/ecap-a1/result.mat
test/i3/e-cap/output/ecap-a1/report.md
```

正式启动前两者和 output directory 必须不存在。tag 一旦启动即消费；失败后不得同 tag 重跑，
不得覆盖或清理 output。

### 10.3 Result schema

`result.mat` 至少保存：

- `schema`, `attempt`, `command`, `retry_count`, `prior_attempts`；
- `input_contract`, `certificate_summary`, `no_resolve_call_counts`；
- `ordinary_anchor`, `historical_diagnostics`；
- artifact raw wall defects、circle value differences/normal jumps、lift source maps 与它们在
  final Fourier--Gauss coordinates 上的 canonical reconstruction records；
- `levels.circle`, `levels.image`, `levels.wall`, `levels.riccati`, `levels.gauss`,
  `levels.full_p`；
- 每一级 raw circle/wall value/normal maps 的 compact coefficients、norms 和 restriction records；
- Kress、Linton、Bloch、jump、scaling、Wronskian 和 high-order recurrence oracles；
- `axis_association` 的 component--axis incidence、all-others-final labels 和 joint holdout；
- `components.wall`, `components.circle`, `components.volume` 的
  $B,F,A^{\mathrm{obs}},\omega_{\mathrm{cmp}},A,R,\Phi,R_{\mathrm{arith}},\epsilon$ 及
  scalar--factor reverse-triangle records；
- `field.same_partial`, `field.index_direction`,
  $A_N^{\mathrm{obs}},\omega_{N,\mathrm{cmp}},A_N,R_N,\epsilon_N^{\mathrm{emp}}$；
- `caps.epsilon_M_emp`, `caps.epsilon_N_emp`, `estimator.q_emp`, nominal endpoints/width；
- `first_execution_blocker`, `first_empirical_unavailable`, `first_nonblocking_warning`；
- `coverage`, `qualification`, `reliability`, `resources`。

不保存 dense pair kernels 或所有 target--mode--image intermediates；只保存 compact coefficients、
small audit maps、factors 和 raw metric records。

report 必须列出 ordinary anchors、三个 empirical component caps、denominator cap、$q_{\mathrm{emp}}$、
nominal endpoints/width、全部 unresolved axes、历史 circle warning、资源和全部 reliability-false
边界。不能把 empirical evaluation cap 写成 theorem hypothesis 已满足。

### 10.4 成本

主要工作约为 $4.7\times10^8$ streamed target--mode--image contributions。两类 cross actions
合计约 $7.4\times10^6$ target--mode terms。实现必须逐 image/target block stream，逐 derivative
释放，不形成 dense $N^2$ kernel operators；最大暂存约为一个 $4096\times512$ complex block。

冻结资源为：

- expected wall time：13--23 min；
- preflight stop：静态估计 $>25$ min 或 peak $>520$ MiB；
- soft wall time：1500 s，达到后不启动新 stage；
- hard wall time：1800 s；
- hard peak active-object memory：640 MiB；
- 从 design 到 experiment 收尾仍服从用户给定的三小时总上限。

运行前若静态 allocation/call-count 估计超过 preflight 门，报告 `RESOURCE_BUDGET_UNAVAILABLE`；
不得自动降低 $J$、grids、modes 或删除 oracle。正式运行中不得 retry。

## 11. 阶段与结论边界

本设计成功时最多说明：对 immutable `fbie-a1` trial，若同链 fixed-density evaluation 的预注册
层差按经验规则收缩，则可形成一个 ordinary same-trial evaluation cap 和 nominal transform。它不能说明
cap 覆盖真实连续评价误差，也不能说明 candidate 到连续谱的误差被包住。

I3.2 包含已经建立的条件性定理和本 same-certificate empirical-cap extension。I3.3 只做未参与
cap calibration 的 independent effectivity validation。I3.4 才实例化严格
$\epsilon_M,\epsilon_N$、directed arithmetic、same-operator gap、区间 containment 和离散特征值
存在性。历史文档保留生成时 labels，不追溯修改。

## 12. Skeptic 22 门逐项闭合

1. **阶段分工：** 摘要和 §11 固定 I3.2 theorem+same-certificate cap、I3.3 independent
   effectivity、I3.4 strict enclosure/gap/existence。
2. **唯一 certificate 来源：** §1 只允许 immutable `fbie-a1` whitelist staging；不混入新 state。
3. **NO_RESOLVE：** §2 给出唯一调用图、禁止函数和八个零计数器。
4. **同一 exact trial：** §1、§3--§5 固定 density、kernel、branch、normal、Bloch、lifts 和 state。
5. **预注册 levels：** §3.3、§4.2、§6 和 §7 冻结全部 action/image/wall/Riccati/Gauss/full-$P$
   levels 和比较顺序。
6. **Common-grid 合同：** §3.1、§3.3、§4.2 和 §7.1 固定 $ds$ normalization、Nyquist、phase、
   restriction、artifact raw-map reconstruction 与 Fourier--Gauss induced norm。
7. **Near-zero circle：** §7.1、§8 要求绝对 difference、两侧 scales、component contribution 和
   roundoff floor；历史 $0.774$ 保留。
8. **经验外推：** §7.4 冻结 $0.5/2\times$；§7.5 冻结 image $0.80/5\times$。
9. **失败外推语义：** §7--§9 规定 noncontraction/nonfinite/zero-scale 处理，不临时换公式。
10. **唯一中心策略：** §1.1 与 §7.2 只用 immutable artifact center；fresh final 只进入 allowance。
11. **$\epsilon_M^{\mathrm{emp}}$ 单位和方向：** §5、§7.1、§7.3 和 §7.7 用 canonical
    induced $V'$ component norms、反三角关系、无重复 axis table 和三角和，不用
    cancellation/root-sum。
12. **$\epsilon_N^{\mathrm{emp}}$ squared units：** §7.8 只对同一 finite partial 给 downward
    allowance，并要求正分母。
13. **Full-$P$ nonnormal tails：** §5.2 保留 full matrices、Jordan coupling、off-by-one 和
    scale-covariant doubling。
14. **未计算 Fourier tail：** §7.6 分开 circle/wall shells、全部已计算 modes 和经验
    omitted-shell allowance；失败即 total cap unresolved。
15. **经验 $q$：** §7.9 使用
    $(\widetilde M_h+\epsilon_M^{\mathrm{emp}})/
    \sqrt{\widetilde N_h-\epsilon_N^{\mathrm{emp}}}$。
16. **Nominal-only：** §7.9、§9 固定 $q_{\mathrm{emp}}$ 的三种 nominal statuses 和全部 reliable
    flags false。
17. **禁止升级：** 摘要、§9、§11 禁止 empirical evaluation cap 触发 theorem、gap 或 existence。
18. **禁止 reference reuse：** §6、§9、§11 把全部 same-chain data 排除在 I3.3 independent
    reference 外。
19. **Failure precedence：** §9 分开 execution blocker、component unavailable、empirical
    unresolved 和 finite nominal output。
20. **资源冻结：** §10.4 给出 work、expected/soft/hard time、memory 和 preflight stop；不追加
    levels。
21. **Append-only：** §1.2、§10.2 保护全部历史 artifact，冻结新 schema/tag/output guard 和
    no-retry 语义。
22. **授权链：** 本文件当前只到 R--E `AGREED`；后续必须依次经过
    `Skeptic DESIGN PASS -> implementation freeze -> Researcher mapping review -> Skeptic spec-to-code PASS -> optional read-only checkcode -> explicit one-command run authorization`。

## 13. 运行前清单

- [ ] Skeptic 对本设计给出 `DESIGN PASS`；
- [ ] staging 另获授权，历史 source identity 核验且 append-only input 建立；
- [ ] formal source 通过 AGENTS、`$karpathy-guidelines` 和静态 NO_RESOLVE call inventory；
- [ ] Researcher 核对 same-certificate theory-to-code mapping；
- [ ] Skeptic 给出 `SPEC-TO-CODE PASS`；
- [ ] optional `checkcode` 只读 preflight 获授权并分类；
- [ ] `ecap-a1` output 不存在，资源预估未超过 stop 门；
- [ ] Skeptic 明确授权唯一正式命令。

当前所有项目均未完成；不得创建 input、实现、运行、结果或 review。
