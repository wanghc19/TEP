# I3.1 BIE-informed 全波导连续强残量设计

## 摘要与冻结状态

- **Design ID:** `I3.1-BIE-INFORMED-GLOBAL-RESIDUAL-V1`
- **Design status:** `FROZEN RESEARCHER--ENGINEER AGREEMENT / SKEPTIC DESIGN PASS / NO IMPLEMENTATION / NO RUN`
- **Researcher--Engineer agreement:** `AGREED`（2026-08-15）
- **预留正式 attempt:** `lead-a1`
- **主要输出语义:** `BIE_INFORMED_CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE`

[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 的中心空列 cutoff
baseline 已经完成；其 computed residual ratio 为 $22.43882099031153$，且固定单胞 cutoff
导数项主导。本文不修改该冻结设计，也不修改其代码或输出。新设计取消零延拓 cutoff，改为在
整个左右周期半波导上定义一个平方可和的连续试探场。

新对象必须准确称为 **BIE-informed continuous conforming trial**：离散 BIE 场只提供胞元
内部形状的拟合数据；真正代入连续算子的是一个显式的、跨材料圆使用同一公式的有限 Fourier--
Hermite/bubble 场。它不是 exact half-guide solution，也不是“重构出的真实物理本征场”。

本设计只研究 saved candidate

$$
\widehat k_h=1.832770289108157,
\qquad \mu_h=\widehat k_h^2.
$$

不扫描或细化 $k$，不定位有限矩阵零点，不把 numerical QZ 传播当作连续半波导传播定理。
若构造通过，直接计算

$$
\eta_{\lambda,h}^{\mathrm{BIE}}
=\frac{\|(A-\mu_h I)u_h^{\mathrm c}\|_H}
{\|u_h^{\mathrm c}\|_H}.
$$

双精度势函数、最小二乘拟合和普通 Gauss 积分没有 outward enclosure，所以本轮即使所有门通过，
也只能得到 computed estimator candidate；projected-gap containment、连续离散特征值存在性、
唯一 mode 和误差上界仍为 `NOT_REACHED`。

## 1. 科学问题、输入和停止边界

本实验回答：I2 的 saved candidate、中心近核向量和左右 stable trace subspace，能否确定一个非零
$u_h^{\mathrm c}\in D(A)$，其连续强残量明显小于固定 cutoff baseline，并且无限尾、BIE shape fit
和数值积分都达到预注册分辨率？

固定物理和离散输入为

$$
\beta=0.5,\quad d=1,\quad R=0.2,\quad s=1,
\quad \rho_{\mathrm{disk}}=1+16s=17,
$$

$$
n_{\mathrm{tot}}=256,\quad M=48,\quad K=2M+1=97,
\quad [X_L,X_R]=[-1/2,1/2].
$$

沿用 I2 fine evaluator 的 geometry、proxy、branch、QZ cluster、fixed rows、chart、solver 和
物理行列权重。只允许一次 frozen seed 和一次 saved-candidate point。不得读取历史 `result.mat`，
不得修改 candidate、$M$、$n_{\mathrm{tot}}$ 或 evaluator。

当前 continuous operator 与 [[research/projects/eig-apost/phase3-analysis/s-estimator|I3.1
continuous-residual theory]] 相同：

$$
A=-\rho^{-1}\Delta,
\qquad
H=L^2(B,\rho\,\mathrm dx\,\mathrm dy),
\qquad
B=\mathbb R\times(-d/2,d/2).
$$

因此

$$
\|u\|_H^2=\int_B\rho|u|^2,
\qquad
\|(A-\mu_h)u\|_H^2
=\int_B\rho^{-1}|-\Delta u-\mu_h\rho u|^2.
$$

任何离散 residual、BIE solve residual、wall mismatch 或 QZ invariant residual 都只能作输入质量
诊断；不得把它们代替上面两个连续积分。

## 2. 当前 evaluator 数据和本设计补算的数据

`eval_i21` 的 candidate point 已返回：

- $A_{\mathrm{def}}^D$、$A_{\mathrm{def}}^G$ 与 $A_{\mathrm{QP}}$；
- scattering pencil $(A_{\mathrm{sc}},B_{\mathrm{sc}})$；
- fixed-chart bases $Z_+,Z_-\in\mathbb C^{194\times97}$；
- $D_\pm,N_\pm$、Fourier orders、$\beta_m$、冻结 branch 的 $\gamma_m$ 和 cell phase；
- branch、factor、QZ、chart 和 graph diagnostics。

它没有保存当前 point 的 proxy、incident matrices $B_L,B_R$、density response $H_L,H_R$、
far-field extractors 或 selected Schur blocks。本设计不修改历史 evaluator。新入口在同一 frame
下用 `i21_kproxy` 确定性重算当前 proxy，重建同一个圆 geometry、channels 和
$A_{\mathrm{QP}}^{\mathrm{rebuild}}$。在任何 physical sample map 之前必须检查

$$
\epsilon_A
=\frac{\|A_{\mathrm{QP}}^{\mathrm{rebuild}}
-A_{\mathrm{QP}}^{\mathrm{node}}\|_F}
{\max\{1,\|A_{\mathrm{QP}}^{\mathrm{node}}\|_F\}}
\le10^{-13}.
$$

失败说明重建 proxy 或 branch 已使对象漂移，状态为
`DENSITY_REPRESENTATION_UNRESOLVED`。通过后使用 node 与 rebuild 已核对一致的矩阵计算

$$
H=[H_L,H_R]
=-A_{\mathrm{QP}}^{-1}[B_L,B_R]
\in\mathbb C^{512\times194}.
$$

本实验不需要 $F_L,F_R$。$H$ 的 solve rcond 和 relative residual 必须分别通过 I2 的
$10^{-8}$ 与 $10^{-10}$ 门。

### 2.1 只对当前圆成立的 density scaling 门

`kbie`/`op.construct_A_QP` 形式上返回

$$
A_{\mathrm{QP}}=D_rA_{\mathrm{raw}}D_c,
$$

而 `incident_rhs` 没有显式应用同样缩放。当前圆参数化的 speed 为常数 $R$，所以

$$
D_r=\sqrt{hR}\,I,
\qquad
D_c=(\sqrt{hR})^{-1}I,
\qquad
D_rD_c=I,
$$

缩放在当前 geometry 上相消，$H$ 才能按 physical density response 使用。实现必须保存

$$
\epsilon_{\mathrm{speed}}
=\frac{\max_j|v_j-\overline v|}{\max(\overline v,\mathrm{realmin})},
\qquad
\epsilon_{\mathrm{scale}}=\|D_rD_c-I\|_2,
$$

并要求二者不超过 $10^{-13}$。失败即
`DENSITY_REPRESENTATION_UNRESOLVED`；不得把圆上的结论外推到一般 geometry，也不得在本次
attempt 临时重写 unscaled BIE。

## 3. 势函数、密度符号和制造 oracle

未知量固定为

$$
\eta=\begin{bmatrix}\tau\\ \zeta\end{bmatrix}
=\begin{bmatrix}\tau\\-\sigma\end{bmatrix}.
$$

给定一胞 incoming amplitudes $a_L,b_R\in\mathbb C^K$，有

$$
\eta=H_La_L+H_Rb_R.
$$

圆外 BIE data 定义为

$$
u_e=u_{\mathrm{inc}}+D_{\mathrm{QP}}^{(\widehat k_h)}\tau
-S_{\mathrm{QP}}^{(\widehat k_h)}\zeta,
$$

圆内 BIE data 定义为

$$
u_i=D^{(\sqrt{17}\widehat k_h)}\tau
-S^{(\sqrt{17}\widehat k_h)}\zeta.
$$

$D$ 中 source-normal derivative 必须按
$\partial_{\nu_z}G=-\nabla_xG\cdot\nu_z$ 计算。所有 wall derivative 均使用 global
$x$ derivative；左半波导的 outward normal 记号不得混入 field evaluator。

### 3.1 跑前必须通过的 sign/jump oracle

oracle 使用当前圆和相同 quadrature conventions，但不使用 candidate density。取

$$
\tau(\theta)=e^{2\mathrm i\theta},
\qquad
\zeta(\theta)=e^{-\mathrm i\theta},
$$

在 $64$ 个半 panel-shifted angles 上，从 $r=R\pm\varepsilon$ 评价，冻结

$$
\varepsilon\in\{0.04,0.02,0.01\}.
$$

oracle 不把 $D$ 与 $S$ 合成后再检查，而是分别覆盖四条实际路径：

1. interior free-space $D^{(\sqrt{17}\widehat k_h)}\tau$；
2. interior free-space $-S^{(\sqrt{17}\widehat k_h)}\zeta$；
3. exterior QP $D_{\mathrm{QP}}^{(\widehat k_h)}\tau$；
4. exterior QP $-S_{\mathrm{QP}}^{(\widehat k_h)}\zeta$。

每条路径分别检查项目约定的相应 jump：

$$
\gamma^+D\tau-\gamma^-D\tau=\tau,
\qquad
\partial_\nu^+(-S\zeta)-\partial_\nu^-(-S\zeta)=\zeta.
$$

最细 offset 的四个相对误差都必须不超过 $0.25$，并且各自不大于对应最粗 offset 误差的
$0.75$。
该宽松门用于识别符号、法向和 density ordering 错误，不把近边界普通 quadrature 当成高精度
trace scheme。

另在远离圆和 wall 的 $16$ 个固定 targets，以 centered difference、步长 $10^{-5}$，分别核对
free-space $D/-S$ 与 QP $D/-S$ 返回的 global $x$ derivative；四条 relative errors 均不得超过
$10^{-5}$。任何 oracle 失败均先于正式 field construction，状态为
`DENSITY_REPRESENTATION_UNRESOLVED`。

## 4. 从 frozen bases 恢复 whole-subspace 传播

不重新做 QZ，不对 individual multipliers 使用 `lambda.^q`，也不对角化 $P_\pm$。在 frozen
fixed-chart coordinates 中定义

$$
P_+=(B_{\mathrm{sc}}Z_+)\backslash(A_{\mathrm{sc}}Z_+),
$$

$$
P_-=(A_{\mathrm{sc}}Z_-)\backslash(B_{\mathrm{sc}}Z_-).
$$

$P_+$ 向右传播；$P_-$ 在 reversed pencil 上向左、远离中心传播。必须保存两个 coefficient
matrices 的 economy-QR rank、两个 triangular $R$ factors 的 rcond 和

$$
\epsilon_+
=\frac{\|A_{\mathrm{sc}}Z_+-B_{\mathrm{sc}}Z_+P_+\|_F}
{\max\{1,\|A_{\mathrm{sc}}Z_+\|_F
+\|B_{\mathrm{sc}}Z_+\|_F\|P_+\|_2\}},
$$

$$
\epsilon_-
=\frac{\|B_{\mathrm{sc}}Z_--A_{\mathrm{sc}}Z_-P_-\|_F}
{\max\{1,\|B_{\mathrm{sc}}Z_-\|_F
+\|A_{\mathrm{sc}}Z_-\|_F\|P_-\|_2\}}.
$$

两个 $R$ factors 的 rcond 必须至少为 $10^{-8}$，rank 必须等于 $K$，两个 invariant residual 必须
不超过 $10^{-10}$，所有数据必须 finite。selected Schur spectrum 可以保存为诊断，但不得重做
QZ 后替换 frozen $Z_\pm$ 或 $P_\pm$。失败为 `PROPAGATION_ACTION_UNRESOLVED`。

## 5. 中心向量、左右坐标和 wall traces

按 design-3-1 的物理权重构造

$$
A_{\mathrm{phys}}=D_r^{\mathrm{wall}}A_{\mathrm{def}}^DD_c^{\mathrm{wall}},
$$

取最小右奇异向量 $v_1$，并固定

$$
q=\frac{D_c^{\mathrm{wall}}v_1}
{\|D_c^{\mathrm{wall}}v_1\|_2},
\qquad \|q\|_2=1,
\qquad q=\begin{bmatrix}q_L\\q_R\end{bmatrix}.
$$

令 $E=\operatorname{diag}(e^{\mathrm i\gamma_m})$。左右 stable coordinates 为

$$
c_-=D_-^{-1}[I,E]q,
\qquad
c_+=D_+^{-1}[E,I]q.
$$

### 5.1 右半波导

写

$$
Z_+=\begin{bmatrix}A_+\\B_+\end{bmatrix},
\qquad c_n^+=P_+^nc_+.
$$

第 $n$ 胞左、右 wall state 分别为 $Z_+c_n^+$ 与 $Z_+P_+c_n^+$。对应 Fourier traces 为

$$
d_0^+=(A_++B_+)c_n^+,
\qquad g_0^+=\mathrm i\Gamma(A_+-B_+)c_n^+,
$$

$$
d_1^+=(A_++B_+)P_+c_n^+,
\qquad g_1^+=\mathrm i\Gamma(A_+-B_+)P_+c_n^+.
$$

BIE fit data 的 incoming map 为

$$
\begin{bmatrix}a_L\\b_R\end{bmatrix}
=\begin{bmatrix}A_+\\B_+P_+\end{bmatrix}c_n^+.
$$

### 5.2 左半波导

写

$$
Z_-=\begin{bmatrix}A_-\\B_-\end{bmatrix},
\qquad c_n^-=P_-^nc_-.
$$

$c_n^-$ 表示第 $n$ 个左胞的右 wall，$P_-c_n^-$ 表示其左 wall。按物理 $x$ 从左到右，

$$
d_0^-=(A_-+B_-)P_-c_n^-,
\qquad g_0^-=\mathrm i\Gamma(A_--B_-)P_-c_n^-,
$$

$$
d_1^-=(A_-+B_-)c_n^-,
\qquad g_1^-=\mathrm i\Gamma(A_--B_-)c_n^-.
$$

因为 evaluator 定义 $N_-=-\mathrm i\Gamma(A_--B_-)$，实现必须显式检查
$g_1^-=-N_-c_n^-$，不能把 $N_-$ 直接当作 global $x$ derivative。左胞 incoming map 为

$$
\begin{bmatrix}a_L\\b_R\end{bmatrix}
=\begin{bmatrix}A_-P_-\\B_-\end{bmatrix}c_n^-.
$$

## 6. 单个跨圆 Fourier--Hermite/bubble trial

在 reference cell 中令 $t=(x-X_L)/(X_R-X_L)\in[0,1]$，$L=X_R-X_L=1$，并用

$$
\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_my}.
$$

对任一 side 和任一 stable coordinate $c\in\mathbb C^K$，先以标准 cubic Hermite functions
$h_{00},h_{10},h_{01},h_{11}$ 构造

$$
p_m^{\mathrm{base}}(t;c)
=h_{00}(t)d_{0,m}(c)+Lh_{10}(t)g_{0,m}(c)
+h_{01}(t)d_{1,m}(c)+Lh_{11}(t)g_{1,m}(c).
$$

预注册 bubble basis

$$
b_j(t)=t^2(1-t)^2P_{j-1}(2t-1),
\qquad j=1,\ldots,J,
$$

其中 $P_j$ 是 Legendre polynomial。每列在固定的 combined value/derivative training norm 下先
归一化；归一化因子保存并在系数 map 中还原。因为

$$
b_j(0)=b_j(1)=b_j'(0)=b_j'(1)=0,
$$

bubble 不改变 wall value 或 global $x$ derivative。完整 trial 为

$$
u_{\mathrm{cell}}(x,y;c)
=\sum_{m=-M}^M
\left[p_m^{\mathrm{base}}(t;c)
+\sum_{j=1}^Jb_j(t)C_{jm}c\right]\psi_m(y),
$$

其中 $C_{jm}\in\mathbb C^{1\times K}$。同一个公式用于 disk 内外；$\rho$ 只在 continuous
mass 和 residual 中改变。不得在 circle 上拼接两套 trial，也不得把 piecewise BIE fit data
直接称为 $u_h^{\mathrm c}$。

冻结两个 bubble levels：

$$
J_{\mathrm{coarse}}=4,
\qquad J_{\mathrm{fine}}=8.
$$

$J=8$ 是正式 trial；$J=4$ 只作预注册内部稳定性比较。不得见结果后加阶。

## 7. 固定线性 BIE fit

### 7.1 三套互不混用的点集

训练点在 $t\in(0,1)$ 上固定为

$$
t_\ell^{\mathrm{train}}
=\frac{1-\cos((2\ell-1)\pi/48)}2,
\qquad \ell=1,\ldots,24,
$$

并配 $N_y^{\mathrm{train}}=256$ 个点

$$
y_r^{\mathrm{train}}
=-d/2+d(r+1/2)/256,
\qquad r=0,\ldots,255.
$$

holdout 点固定为

$$
t_\ell^{\mathrm{hold}}=\frac{1-\cos(\ell\pi/25)}2,
\qquad \ell=1,\ldots,24,
$$

$$
y_r^{\mathrm{hold}}
=-d/2+d(r+3/4)/256,
\qquad r=0,\ldots,255.
$$

holdout 不参与 fit、rank selection 或 coefficient scaling。任何 BIE sample 到圆的距离若不超过
$10^{-8}$，相应 grid 直接失败；不得在运行中移动单点或插值填补 near-boundary data。

连续 residual quadrature 使用第 10 节的 Gauss/polar nodes，与训练和 holdout 点都不同。代码必须
保存三套 node definitions 并核对互不重合；若实际点重复，状态为
`CONFORMING_RECONSTRUCTION_UNRESOLVED`。

### 7.2 线性 multi-RHS fit

对 $K$ 个 stable coordinate basis vectors 一次性构造 BIE value 和 global $x$ derivative maps。
每个 $(x,y)$ target 按几何位置选择第 3 节的 $u_e$ 或 $u_i$，形成 piecewise BIE data；它只作
拟合目标。对每条训练 $x$ line 作离散 Fourier projection，保留同一 $m=-48,\ldots,48$。

对每个 output Fourier order，用同一个固定 matrix 同时拟合全部 $K$ 个右端：

令 $B_J(\ell,j)=b_j(t_\ell^{\mathrm{train}})$，并明确以 global $x$ 求导

$$
B_J'(\ell,j)=L^{-1}b_j'(t_\ell^{\mathrm{train}}).
$$

先从 BIE Fourier value/global-$x$ data 减去 cubic Hermite base，所得残差矩阵分别记为
$R_m^{(u)}$ 与 $R_m^{(x)}$；fit 不得把 base 重复计入右端。于是

$$
\min_{C_m\in\mathbb C^{J\times K}}
\left\|
\begin{bmatrix}
B_J\\LB_J'
\end{bmatrix}C_m-
\begin{bmatrix}
R_m^{(u)}\\LR_m^{(x)}
\end{bmatrix}
\right\|_F.
$$

这里只允许 column-scaled QR/backslash；不得按 mode 改 rank、使用 data-dependent regularization、
`pinv` 或结果后 truncation。combined fit matrix 必须 full column rank，rcond 至少 $10^{-10}$。

在 holdout grid 上直接比较 point values 和 global $x$ derivatives，定义

$$
\epsilon_{\mathrm{fit}}
=\frac{
\left(\|u_{\mathrm{trial}}-u_{\mathrm{BIE}}\|_2^2
+L^2\|\partial_xu_{\mathrm{trial}}-\partial_xu_{\mathrm{BIE}}\|_2^2\right)^{1/2}}
{\max\left\{
\left(\|u_{\mathrm{BIE}}\|_2^2
+L^2\|\partial_xu_{\mathrm{BIE}}\|_2^2\right)^{1/2},
\mathrm{realmin}\right\}}.
$$

左右两侧的 fine error 都必须不超过 $0.20$，且不得大于对应 coarse error。另保存 actual-density
的 off-grid circle value/normal jump、raw wall value/$x$-derivative mismatch 和 $y$-seam
quasi-periodicity defect；这些量必须 finite，但只作诊断，不替代 holdout 门或 continuous residual。

任何 rank、grid-separation 或 holdout 门失败均为
`CONFORMING_RECONSTRUCTION_UNRESOLVED`。该状态表示 BIE-informed shape quality 未建立；显式
basis 的数学 conformity 本身不因 fit 失败而改变。

## 8. 中心空列与端口 correction

中心 raw Rayleigh field 仍为

$$
u_0(x,y)=\frac1{\sqrt d}\sum_m
\left(q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}
+q_{R,m}e^{-\mathrm i\gamma_m(x-X_R)}\right)e^{\mathrm i\beta_my}.
$$

分别计算它在 $X_L,X_R$ 的 value/global-$x$ derivative，与 lead traces

$$
(D_-c_-,-N_-c_-),
\qquad
(D_+c_+,N_+c_+)
$$

之差。对每个 Fourier order 加唯一 cubic Hermite correction，使 correction 在左右端的 value
和 global $x$ derivative 恰等于上述差。保存 correction/raw field 的 $H^2$ norm ratio，并要求
不超过 $0.10$；否则 `CONFORMING_RECONSTRUCTION_UNRESOLVED`。不得重新求 $q,c_-,c_+$ 以减小
correction。

中心空列的 trial 定义为

$$
u_{\mathrm{ctr}}=u_0+u_{\mathrm{corr}}.
$$

这里的 $\gamma_m$ 必须使用 frozen evaluator 实际返回并存储的双精度数值，不得用理论色散关系
把

$$
\delta_m=\beta_m^2+\gamma_m^2-\mu_h
$$

强制置零。raw Rayleigh field 对 strong residual 的贡献须按

$$
r_0(x,y)=\frac1{\sqrt d}\sum_m\delta_m
\left(q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}
+q_{R,m}e^{-\mathrm i\gamma_m(x-X_R)}\right)e^{\mathrm i\beta_my}
$$

显式保留。correction 的 Laplacian 由 cubic Hermite 多项式及 Fourier 因子解析求导；在每个积分点
先合成

$$
r_{\mathrm{ctr}}=r_0-\Delta u_{\mathrm{corr}}-\mu_hu_{\mathrm{corr}},
$$

再取平方。实现必须分别保存 $\|r_0\|_{L^2}$、correction residual norm 和 total residual norm，
但 estimator 使用的是最后一个 total norm，不能把前两个 norm 相加代替它。中心空列没有材料圆且
$\rho=1$；其 field、residual 和 $H^2$ squared norms 分别为

$$
\mathcal U_{\mathrm{ctr}}=\int_{C_0}|u_{\mathrm{ctr}}|^2,
\qquad
\mathcal R_{\mathrm{ctr}}=\int_{C_0}|r_{\mathrm{ctr}}|^2,
$$

$$
\mathcal Q_{\mathrm{ctr}}=\int_{C_0}
\left(|u_{\mathrm{ctr}}|^2+|\nabla u_{\mathrm{ctr}}|^2
+|D^2u_{\mathrm{ctr}}|^2\right).
$$

这三个量都必须用 **total corrected field** 计算，并进入第 11 节的全波导总和；不得用 raw center
field 或 correction-only norm 代替。

## 9. 定义域论证和连续 residual

### 9.1 Conformity 命题

假设：

1. 第 4 节的 $P_\pm$ 产生平方可和的 coefficient sequence；
2. 每个 reference-cell trial 属于 $H^2$，且其 $H^2$ norm 对 stable coordinate 有统一有限界；
3. 第 5--8 节的 wall value 和 global $x$ derivative 按同一 Fourier trace 精确共享。

则无限拼接场 $u_h^{\mathrm c}$ 属于 $D(A)$。

理由是：cubic Hermite base 使相邻胞元的 value 和 global normal derivative 相等；相同 finite
Fourier value trace 还给出相同 tangential derivative。bubble 的 value 和一阶法向导数在 wall
为零，所以不改变该匹配。单个 smooth formula 跨越材料圆，因而 circle 上没有 value/flux jump
或 distributional delta。finite Fourier basis 使 $y=\pm d/2$ 上的 value 和各阶导数自动满足
同一 $\beta$-准周期关系。中心 correction 又闭合两个 center/lead interfaces。最后，平方可和的
$H^2$ cell norms 给出 $u_h^{\mathrm c}\in H^1(B)$ 且 $\Delta u_h^{\mathrm c}\in L^2(B)$，所以
$u_h^{\mathrm c}\in D(A)$。

这里 $P_\pm$ 只定义 numerical trial 的 coefficient sequence；论证从未把它们等同于 continuous
exact half-guide propagation。

### 9.2 Strong residual basis

写每胞 trial 为

$$
u_{\mathrm{cell}}(x,y;c)=\Phi(x,y)c,
$$

并定义

$$
\mathcal R_\rho(x,y)
=-\Delta\Phi(x,y)-\mu_h\rho(x,y)\Phi(x,y).
$$

每侧形成三个 $K\times K$ Hermitian Gram matrices：

$$
M=\int_C\rho\,\Phi^*\Phi,
$$

$$
G=\int_C\rho^{-1}\mathcal R_\rho^*\mathcal R_\rho,
$$

$$
Q=\int_C\left(\Phi^*\Phi
+(\nabla\Phi)^*\nabla\Phi
+(D^2\Phi)^*D^2\Phi\right).
$$

$M,G,Q$ 分别用于 field、strong residual 和 $H^2$ square-summability。总 residual 必须先在每个
quadrature point 合成 $-\Delta u-\mu_h\rho u$ 再取 norm；不得把 base、bubble、material 或
Fourier components 的 norms 直接相加。

未保留的 $|m|>48$ channels 在 trial 定义中恒为零，不是一个被漏掉的 residual term。该有限
表示是否足够好，只由 BIE holdout 和 continuous residual 数值回答。

## 10. Geometry-fitted quadrature

不得在 Cartesian grid 上仅用 inside/outside mask 穿过 $\rho$ jump。field Gram 采用

$$
M=\int_C\Phi^*\Phi
+\int_{\Omega_{\mathrm{disk}}}(17-1)\Phi^*\Phi.
$$

residual Gram 采用

$$
G=\int_C \mathcal R_1^*\mathcal R_1
+\int_{\Omega_{\mathrm{disk}}}
\left(17^{-1}\mathcal R_{17}^*\mathcal R_{17}
-\mathcal R_1^*\mathcal R_1\right).
$$

full rectangle 的 $y$ integral 用 finite Fourier orthogonality 精确约去，$x$ 用 Gauss--Legendre；
disk correction 用 polar Gauss--Legendre/trapezoid。冻结两层：

| level | rectangle $N_x$ | disk $N_r$ | disk $N_\theta$ |
|---|---:|---:|---:|
| coarse | 64 | 32 | 128 |
| fine | 128 | 64 | 256 |

中心空列 $C_0=[X_L,X_R]\times[-d/2,d/2]$ 使用同一 coarse/fine rectangle
$N_x=64/128$。其有限 Fourier $y$ integral 同样用正交性精确约去；若实现改用显式 $y$ 求积，
则必须使用表中 $N_\theta=128/256$ 个等距点并接受完全相同的 refinement 门。每层都独立计算
$\mathcal U_{\mathrm{ctr}}$、$\mathcal R_{\mathrm{ctr}}$、$\mathcal Q_{\mathrm{ctr}}$，包括第 8 节的
stored-double dispersion term $\delta_m$；这些中心量与两侧 lead Gram quadratic forms 相加后，
才形成该层的 total field、residual 和 $H^2$ norms。

fine 与 coarse 的 total field norm、residual norm 和 ratio 相对变化都不得超过 $10^{-5}$。
$H^2$ norm 的相对变化也不得超过 $10^{-5}$。中心三项各自的 coarse/fine 相对变化同样不得超过
$10^{-5}$；这里以对应的全波导 fine squared norm 为分母尺度，分母下限为 `realmin`，不得以一个
可能接近零的中心分量自身作分母。stored-double dispersion contribution 必须在两层保持原值参与
计算，不能因其小而删去。
$J=8$ 与 $J=4$ 的 fine-quadrature ratio 相对变化不得超过 $0.10$。对
$10^8e^{\mathrm i\pi/7}(q,c_-,c_+)$ 重复最终 quadratic-form ratio，phase/scale defect 不得
超过 $10^{-11}$；该重复同时重算中心 field、residual 和 $H^2$ 数值积分。

Gram 以 weighted outer products 累加；保存原始 Hermitian defect。任何 Gram 的相对 Hermitian
defect不得超过 $10^{-12}$，其 Hermitian part 的最小 eigenvalue 不得小于
$-10^{-12}$ 乘相应 matrix 2-norm。Hermitian part 只用于消除 Gram 累加的 roundoff，不是手工
修改物理 operator。

这些门只说明普通双精度 quadrature 已解析当前 trial；它们不提供 rigorous integration
enclosure。

## 11. Infinite-tail doubling、误差 margin 和上下信息

对任意一侧及任一 Gram $W\in\{M,G,Q\}$，令

$$
W_N=\sum_{n=0}^{N-1}(P^n)^*WP^n.
$$

只用 whole matrices 做 doubling：

$$
W_{2N}=W_N+(P^N)^*W_NP^N,
\qquad
P^{2N}=P^NP^N.
$$

冻结 $N=2^j$、$j=0,\ldots,12$。不得以 spectral radius、逐 eigenvalue decay 或最后一胞
幅度代替 matrix-norm contraction。

每次矩阵平方同时递推保守的 floating forward-error allowance。令

$$
\gamma_K=\frac{K\epsilon_{\mathrm{mach}}}{1-K\epsilon_{\mathrm{mach}}},
$$

从 $e_1=0$ 出发，以

$$
e_{2N}=2\|P^N\|_2e_N+e_N^2
+100\gamma_K\|P^N\|_2^2
$$

更新。另以不同 association 复算已选择的 $P^N$：对 $N\ge4$，令 $A_N=P^{N/4}$，用
$((A_NA_N)A_N)A_N$ 与 primary balanced product 比较；把两者 2-norm difference 也加入
margin。
定义

$$
a_{\mathrm{hi}}
=\|P^N\|_2+e_N
+10\|P^N_{\mathrm{repeat}}-P^N\|_2.
$$

$e_N$ 只覆盖 matrix power，不覆盖 $W_N$ 累加。对每个 $W\in\{M,G,Q\}$ 另从
$\omega_1(W)=0$ 递推

$$
\begin{aligned}
\omega_{2N}(W)
={}&\left[1+(\|P^N\|_2+e_N)^2\right]\omega_N(W)\\
&+(2\|P^N\|_2e_N+e_N^2)\|W_N\|_2\\
&+100\gamma_K(1+\|P^N\|_2^2)\|W_N\|_2,
\end{aligned}
$$

并把

$$
10\|W_{2N}^{\mathrm{repeat}}-W_{2N}\|_2
$$

加到 $\omega_{2N}$；repeat 用
$W_N+(P^N)^*(W_NP^N)$ 与 $W_N+((P^N)^*W_N)P^N$ 两个 association。

精确数学量若满足 $a_N=\|P^N\|_2<1$，则 exact block-geometric theorem 是

$$
\|W_\infty-W_N\|_2
\le
\frac{a_N^2}{1-a_N^2}\|W_N\|_2.
$$

实现只有 ordinary-double $a_{\mathrm{hi}}$ 和 $\omega_N$，所以另定义 **computed conservative
diagnostic**，而不把它写成可靠不等式。对每侧、每个 $W\in\{M,G,Q\}$ 和对应初始 coordinate
$c$，保存 finite squared sum

$$
s_{W,N}^{\mathrm{diag}}(c)=\operatorname{Re}(c^*W_Nc),
$$

以及 scalar tail allowance

$$
t_{W,N}^{\mathrm{diag}}(c)
=\frac{a_{\mathrm{hi}}^2}{1-a_{\mathrm{hi}}^2}
(\|W_N\|_2+\omega_N(W))\|c\|_2^2.
$$

只有 $a_{\mathrm{hi}}<1$、所有量 finite，且第一个同时满足

$$
\frac{t_{W,N}^{\mathrm{diag}}(c)}
{\max\{s_{W,N}^{\mathrm{diag}}(c),\mathrm{realmin}\}}
\le10^{-6},
\qquad W\in\{M,G,Q\},
$$

的 doubling level 才通过 computed tail gate。左右两侧分别通过；没有达到 contraction、finite
squared sum 非正、nonfinite、near-unit margin 不可分辨或任一 tail share 超门，都固定为
`INFINITE_TAIL_UNRESOLVED`。

对实际 $c_\pm$，记 field squared norm 的 finite sum扣除 $\|c\|_2^2\omega_N(M)$、再加中心
贡献得到的 one-sided diagnostic 为 $\mathcal U_{\mathrm{diag,lower}}>0$；记 residual squared
norm 的 finite sum 加 $\|c\|_2^2\omega_N(G)$、两侧 $t_{G,N}^{\mathrm{diag}}$ 和中心贡献为
$\mathcal R_{\mathrm{diag,upper}}$。报告

$$
\eta_{\mathrm{tail,diag}}
=\sqrt{\mathcal R_{\mathrm{diag,upper}}
/\mathcal U_{\mathrm{diag,lower}}}.
$$

同样保存 nominal full sums 和 $H^2$ tail。machine fields 必须明确
`tail_diagnostic_certified=false`、`field_lower_bound_certified=false` 和
`residual_upper_bound_certified=false`。上述 `lower/upper` 只是朝保守方向组合 ordinary-double
allowances 的标签，不是可靠数学界；其作用是避免把 nonnormal transient、Jordan block 或慢衰减
隐藏在经验截断后面。

## 12. 结果解释和失败优先级

若 exact trial 和 exact integrals 可用，自伴谱定理给

$$
\operatorname{dist}(\mu_h,\sigma(A))
\le\eta_{\lambda,h}^{\mathrm{BIE}}.
$$

本实验只计算双精度近似，所以通过后的名称仍是
`BIE_INFORMED_CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE`。不允许称 empirical
eigenvalue-error estimator、reliable interval 或 upper bound。

预注册分辨率继续使用

$$
\tau_k^{\mathrm{pre}}=10^{-6},
\qquad
\rho_G^{\mathrm{pre}}=0.1.
$$

只为 computed 分辨率诊断定义非认证区间

$$
I_{k,\mathrm{nom}}
=\left[
\sqrt{\max\{0,\mu_h-\eta_{\mathrm{tail,diag}}\}},
\sqrt{\mu_h+\eta_{\mathrm{tail,diag}}}
\right].
$$

absolute 门是

$$
\operatorname{diam}(I_{k,\mathrm{nom}})\le\tau_k^{\mathrm{pre}}=10^{-6}.
$$

若 $\mu_h-\eta_{\mathrm{tail,diag}}\le0$ 或 absolute 门失败，正式科学结果为
`BIE_INFORMED_RESOLUTION_INSUFFICIENT`；这是有效负结果，不允许修改 bubble order、grid、
tail level 或 fit 门。当前 continuous projected gap 未建立，所以
$\rho_G^{\mathrm{pre}}=0.1$ 的 gap-relative 门固定为 `NOT_REACHED`；nominal interval 再窄也不能
把它改写为通过。

科学失败按下列优先级记录，不按代码碰到异常的时间重排：

1. seed/point、dependency、output collision、hard resource limit：`EXECUTION_UNAVAILABLE`；
2. frozen evaluator health：`FINITE_DISCRETE_INPUT_UNAVAILABLE`；
3. circle scaling 或 manufactured sign/jump/global-$x$ oracle：
   `DENSITY_REPRESENTATION_UNRESOLVED`；
4. frozen-$Z$ action rank/rcond/invariant residual：
   `PROPAGATION_ACTION_UNRESOLVED`；此时尚未形成可供 fit 或 tail 使用的传播 action；
5. fixed linear fit、holdout、center correction 或非零场：
   `CONFORMING_RECONSTRUCTION_UNRESOLVED`；
6. Gram、quadrature ladder、bubble-level stability 或 phase/scale：
   `CONTINUOUS_STRONG_RESIDUAL_UNRESOLVED`；
7. 第 11 节 contraction、finite squared sum 或任一 field/residual/$H^2$ tail share：
   `INFINITE_TAIL_UNRESOLVED`；只有在第 5--6 项所需的 fit、center quantities 和 Grams 已形成后，
   才允许评价这一门；
8. ratio 可计算但 nominal resolution 失败：`BIE_INFORMED_RESOLUTION_INSUFFICIENT`；
9. computed ratio 和 nominal resolution 都通过：仍把首个严格升级缺口记为
   `RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE`，并同时保存
   `PROJECTED_GAP_NOT_ESTABLISHED`。

即使 projected gap 后来建立，没有 reliable residual/field enclosure 也不得用本次 nominal interval
声称其中存在连续离散特征值。unique-target identity 始终为可选第二层升级。

## 13. 实现边界、schema、资源和命令

### 13.1 单入口与唯一允许拆分

优先新建单一 MATLAB entry：

```text
test/i3/g-resid/check_g_resid.m
```

预计完整实现约 $850$--$1100$ 行。若静态实现超过 $1000$ 行，只允许把“BIE exterior/interior
sample maps 与固定 Fourier--bubble fit”拆为一个有明确科学职责的 helper：

```text
test/i3/g-resid/i31_bie_fit.m
```

entry 仍负责 candidate/evaluator、$P_\pm$、center correction、continuous Grams、tail、验收和
report。不得为配置、schema、provenance、未来扩展或普通 utility 增加更多 MATLAB 文件；不得修改
`eval_i21`、package functions 或历史代码。

运行时只依赖 MATLAB、正常 path 上唯一 `eval_i21`/`i21_kproxy` 及必要 package functions。
不得搜索 repository root，不得读取 Git、Markdown、manifest、hash 或历史 output。

### 13.2 Append-only 输出与 compact schema

正式目录预留为

```text
test/i3/g-resid/output/lead-a1/
```

只写 `result.mat` 和简短 `report.md`。compact schema
`TEP_I3_1_BIE_INFORMED_GLOBAL_RESID_V1` 至少保存：

- candidate、fine config、density convention 和 circle scaling diagnostics；
- manufactured jump/sign/global-$x$ oracle 原始三层误差；
- $q,c_-,c_+$、frozen $Z_\pm$ action 的 rank/rcond/invariant residual；
- training/holdout/residual grid definitions、fit factor、coarse/fine holdout errors；
- actual-density circle/wall/$y$-seam diagnostics 与 center correction ratio；
- coarse/fine、$J=4/8$ 的 field/residual/$H^2$ Grams 和 quadratic norms；
- 两侧所有 doubling levels 的 $\|P^N\|_2$、error margin、$a_{\mathrm{hi}}$、tail shares；
- nominal 与 computed tail-diagnostic ratio、phase/scale defect、first failure，以及
  `tail_diagnostic_certified=false`、`field_lower_bound_certified=false`、
  `residual_upper_bound_certified=false`；
- coverage flags：global trial、material volume、cell walls、$y$ quasi-periodicity、infinite tail 为
  true；reliable numerical enclosure、projected gap、unique target 和 upper bound 为 false；
- command、elapsed time、peak active-object MiB、retry count/history。

### 13.3 资源冻结

stream QP/free-space target-source blocks，禁止同时保留全部六个 dense kernel derivative matrices。
预计总耗时 $2$--$15$ 分钟、峰值 $200$--$400$ MiB。冻结 soft/hard wall time 为
$900/1800$ 秒，active-object memory 上限 $512$ MiB。soft limit 后不再启动新的 fit 或
quadrature level；hard limit 或内存上限立即 fail close。不得因资源失败增大上限后沿用同一
attempt tag。

跑前 design、实现和 theory-to-code mapping 全部通过独立 Skeptic 后，唯一正式命令预留为

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','g-resid'), ...
  fullfile(pwd,'test','i2','k-count')); check_g_resid('lead-a1');"
```

本设计写成时没有授权 MATLAB 实现或运行；该命令只是冻结未来入口。

## 14. 验收、覆盖和剩余 blocker

一次正式 run 只有同时满足以下条件，才交付 computed estimator candidate：

1. frozen candidate/evaluator 对象无漂移；circle-only scaling 与 sign/jump oracle 通过；
2. $P_\pm$ whole-subspace action 可恢复，且 nonnormal/Jordan-aware tail fail-close 门通过；
3. single smooth Fourier--Hermite/bubble trial 的 fit、holdout、center correction 和非零门通过；
4. 直接作用于真实 $\rho$ 的 field/residual/$H^2$ Grams 通过 geometry-fitted refinement；
5. report 明确区分 BIE fit data、conforming trial、continuous residual 和有限离散诊断；
6. 所有 machine claims 保持 computed-only，不把 nominal interval 升级为存在性或上界。

本设计覆盖：中心和两侧全无限波导 trial、材料体 residual、cell interfaces、横向准周期条件、
finite-Fourier trial、BIE-informed cell shape 与 nonnormal infinite tail。它不覆盖：势函数和积分的
可靠 enclosure、当前 sharp-disk continuous projected gap、unique target、I3.2 independent
reference 或 I3.3 upper-bound conditions。

因此即使本实验成功，真正阻止第一层“gap 内至少存在一个连续离散特征值”的 blocker 仍是
`RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE` 与 `PROJECTED_GAP_NOT_ESTABLISHED`。如果本次
computed ratio 仍过宽，最先保留的科学结论是该 BIE-informed finite-basis reconstruction 在当前
预注册分辨率下不足；不得自动转向 finite-root refinement、复平面扫描或新的 adaptive field fit。

理论来源与边界见
[[research/projects/eig-apost/phase3-analysis/s-estimator|continuous residual estimator theory]]、
[[research/projects/eig-apost/phase3-analysis/s-errors|residual coverage and omissions]]；离散输入见
[[research/projects/eig-apost/implementation/i2/report|I2 report]]；中心 cutoff 负基线见
[[research/projects/eig-apost/implementation/i3/design-3-1|I3.1 center design]] 与
[[test/i3/s-resid/README|center strong-residual experiment index]]。

## Revision A：启动失败消费与 `lead-a2` 前瞻修订

2026-08-16 的首次正式命令在 MATLAB 启动阶段即以 exit code 137 终止，外层记录耗时
3.3 秒。`check_g_resid` 没有进入，evaluator 调用数为 0，且
`test/i3/g-resid/output/lead-a1/` 从未创建。因此 `lead-a1` 被保守消费为
`STARTUP_PREFLIGHT_CONSUMED / NO RUNNER ARTIFACT / SCIENTIFIC GATES NOT_REACHED`；它不是数值
失败，也不提供实验峰值内存超过 512 MiB 的证据。捕获的完整终端消息为：

```text
2026-08-16 22:14:20.956 MATLAB_maca64[1211:15409342] XType: Using static font registry.
Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error

MATLAB is exiting because of fatal error
```

随后仅在沙箱外执行 startup-only smoke：

```text
/Applications/MATLAB_R2023b.app/bin/matlab -batch "disp(version);"
```

该命令于 17.470671 秒后 exit 0，并报告 `R2023b 23.2.0.2365128`；它没有运行本实验。该对照
支持把 `lead-a1` 归入启动环境敏感的 preflight failure，但没有识别更具体的系统根因。

Revision A 只作以下机械修订：

- 唯一允许的新 attempt 改为 `lead-a2`，输出为
  `test/i3/g-resid/output/lead-a2/{result.mat,report.md}`；
- compact schema 改为 `TEP_I3_1_BIE_INFORMED_GLOBAL_RESID_V1_REV_A`；
- 新结果预存 `prior_failed_attempt_count=1` 及上述 `lead-a1` 原始启动诊断；
- `lead-a2` 自身 `retry_count=0`，不得把既往启动失败写成该 attempt 内的数值重试。

saved candidate、finite evaluator、$P_\pm$、BIE-informed conforming trial、真实 $\rho$ residual、
quadrature/bubble/tail 算法与阈值、$900/1800$ 秒和 512 MiB 资源门、失败语义及结论边界全部不变。
Revision A 唯一正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','g-resid'), ...
  fullfile(pwd,'test','i2','k-count')); check_g_resid('lead-a2');"
```

## Revision B：oracle 命名失败消费与 `lead-a3` 前瞻修订

`lead-a2` 的 shell exit code 为 0，但权威 producer 状态为
`I3_1_EXECUTION_UNAVAILABLE`。其 append-only `result.mat` 保存：

- `finite_input.pass=1`，说明 runner 已进入，frozen seed 与 saved-candidate point 两次 evaluator
  调用均已返回；`evaluator_calls=2` 是由该 machine field 与冻结控制流重建，而不是 producer
  直接保存的计数；
- first failure 为 `MATLAB:UndefinedFunction`，消息为
  `Unrecognized function or variable 'pi'.`；
- elapsed time 为 17.421279875 秒，peak active-object memory 为 61.1546688079834 MiB，
  `retry_count=0`；
- `density` 及后续字段为空。因此 density gate 没有形成判定，propagation、fit、continuous
  residual、tail 和 resolution 均为 `NOT_REACHED`。

静态定位表明，`LOCAL_oracle` 后续把 interior pair matrix 赋给局部名称 `pi`；MATLAB 因而在整个
函数内把 `pi` 解析为局部变量，使此前圆周节点公式中的圆周率 `pi` 成为赋值前引用。该失败是实现
命名错误，不是 oracle 数值失败，也不改变任何科学公式。

Revision B 只允许以下变更：

- 把该局部 pair matrix 从 `pi` 重命名为 `pair_in`，并仅同步其 `LOCAL_layers` 使用处；built-in
  圆周率 `pi`、圆周节点公式和 oracle 判据不变；
- 唯一允许的新 attempt 改为 `lead-a3`，输出为
  `test/i3/g-resid/output/lead-a3/{result.mat,report.md}`；
- schema 机械更新为 `TEP_I3_1_BIE_INFORMED_GLOBAL_RESID_V1_REV_B`；
- 统一字段保存 `lead-a1` 与 `lead-a2` 失败历史，`prior_failed_attempt_count=2`；
  `lead-a3` 自身 `retry_count=0`。

`lead-a2` 的两个 artifact 不得修改。candidate、evaluator、$P_\pm$、BIE-informed conforming
trial、真实 $\rho$ residual、quadrature/bubble/tail 算法与阈值、资源门、失败语义及结论边界全部
不变。Revision B 唯一正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','g-resid'), ...
  fullfile(pwd,'test','i2','k-count')); check_g_resid('lead-a3');"
```
