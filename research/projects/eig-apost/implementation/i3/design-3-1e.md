# I3.1 纯 BIE 边界残量设计

## 摘要与状态

- **Design ID:** `I3.1-PURE-BIE-BOUNDARY-RESIDUAL-V1`
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `DESIGN PASS`
- **Implementation:** `REVISION A FROZEN / SPEC-TO-CODE REVIEW PENDING`
- **Run:** `NOT AUTHORIZED`
- **Frozen attempt:** `pbie-a2`

本设计只研究 I2 算法实际保存的 candidate

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2=3.3590469326375971.
$$

目标是在不引入 Q1、RT0 或二维体网格的条件下，从共享的人工墙 Dirichlet trace 构造一个
明确属于连续 form space 的全波导试验场，并用纯边界积分数据计算其连续弱残量指标。设计
直接面向 $\widehat k_h$ 到连续谱的距离；finite-matrix zero、score minimizer 和精确离散根都
不是目标。

核心选择是：每个材料胞元使用有限三角密度和数学上精确的矩形 Dirichlet Green kernel；该
kernel 使胞元左右墙上的总 Dirichlet trace 结构性等于预先给定的共享 trace。有限 BIE 解在材料
圆上可能留下 value jump 和 normal jump。只用显式两侧 radial collar 修复 value jump，使最终
场属于 $H^1$；normal jump 保留为圆周边界残量，collar 引入的体残量也显式计算。三类残量按
三角不等式相加，不假设正交。

本轮普通双精度结果至多是
`COMPUTED_PURE_BIE_CONTINUOUS_RESIDUAL_INDICATOR_CANDIDATE`。即使数值很小，也不是 I3.2 的
独立 reference，不是可靠误差上界，也不能单独证明 projected gap 中存在连续离散特征值。

## 1. 连续对象和指标

波导、材料和 form space 为

$$
B=\mathbb R\times(-1/2,1/2),
\qquad
\rho=17\ \text{in each lead disk},
\qquad
\rho=1\ \text{elsewhere},
$$

$$
H=L^2(B,\rho\,\mathrm dx\,\mathrm dy),
\qquad
V=H^1_\beta(B),
\qquad
\beta=0.5.
$$

固定 shift $\gamma=\mu_h$，定义

$$
\|v\|_V^2
=\int_B |\nabla v|^2+\gamma\int_B\rho|v|^2.
$$

对本设计构造的非零 $u_h^{\mathrm c}\in V$，弱残量是

$$
R_h(v)=\int_B\nabla u_h^{\mathrm c}\cdot\nabla\overline v
-\mu_h\int_B\rho u_h^{\mathrm c}\overline v.
$$

实验计算一个 residual upper candidate $\mathcal M_h^{\mathrm{num}}$ 和一个 field-norm lower
candidate $N_h^{\mathrm{num}}$，再形成

$$
q_h^{\mathrm{num}}
=\frac{\mathcal M_h^{\mathrm{num}}}{\sqrt{N_h^{\mathrm{num}}}}.
$$

上标 `num` 始终表示 ordinary-double 近似；没有 outward-rounded quadrature、BIE truncation
enclosure 和 tail enclosure 时，不得删除该限定。

## 2. Frozen finite input 和共享墙迹

固定 I2 fine object

$$
n_{\mathrm{tot}}=256,
\qquad
M=48,
\qquad
K=2M+1=97.
$$

只在 I2 seed 和 $\widehat k_h$ 各调用一次 `eval_i21`。若 $v_h$ 是物理加权矩阵
$D_rA_{\mathrm{def}}^DD_c$ 的最小右奇异向量，则中心系数固定为

$$
q=\frac{D_cv_h}{\|D_cv_h\|_2}
=\begin{bmatrix}q_L\\q_R\end{bmatrix}.
$$

不重新扫描 $k$，不重新选择 candidate，也不使用 evaluator 的另一条 unweighted near-null
vector 代替该 $q$。

把 frozen QZ bases 写成

$$
Z_+=\begin{bmatrix}A_+\\B_+\end{bmatrix},
\qquad
Z_-=\begin{bmatrix}A_-\\B_-\end{bmatrix},
$$

并按现有 whole-subspace solve 得到完整 $K\times K$ 传播矩阵 $P_+$ 和 $P_-$。不得逐
multiplier 对角化、使用 $P_\pm^{-1}$ 或删除 nonnormal/Jordan coupling。令

$$
D_+=A_++B_+,
\qquad
D_-=A_-+B_-.
$$

令 $E_c=\operatorname{diag}(e^{\mathrm i\gamma_mL})$。沿用 evaluator 的 phase convention，
$c_+$ 和 $c_-$ 由

$$
D_-c_-=[I,E_c]q,
\qquad
D_+c_+=[E_c,I]q
$$

唯一一次线性求解得到。相应 solve residual 必须保存；若解或 residual 非有限，传播对象不可用。
右 lead 中 state $c$ 对应一胞元的共享墙迹

$$
G_+c=
\begin{bmatrix}D_+\\D_+P_+\end{bmatrix}c,
$$

左 lead 按物理 $x$ 从左到右排列时为

$$
G_-c=
\begin{bmatrix}D_-P_-\\D_-\end{bmatrix}c.
$$

第 $n$ 个外向胞元把 $c$ 换成 $P_\pm^nc_\pm$。这些 total traces 是新 BIE 的边界数据；旧
Rayleigh incoming coefficients 不进入新 BIE right-hand side，只用于 nonblocking Cauchy
decomposition check。

Branch、Wood、propagation rank、solve residual 和 actual-state scattering closure 仍按
[[research/projects/eig-apost/implementation/i3/design-3-1d|V3 design]] 的对象、方向和数值尺度
复算。它们不得被解释成连续谱证据。

## 3. 矩形 Dirichlet Green BIE

### 3.1 精确数学 kernel

一个标准 lead cell 为

$$
C=(X_L,X_R)\times(-d/2,d/2),
\qquad
X_L=-1/2,
\quad X_R=1/2,
\quad d=1,
\quad L=X_R-X_L=1.
$$

用 $L^2(-d/2,d/2)$ 正交归一的准周期 Fourier basis

$$
\psi_m(y)=d^{-1/2}\exp(\mathrm i\beta_my),
\qquad
\beta_m=\beta+\frac{2\pi m}{d},
$$

以及 anchored outgoing branch

$$
\gamma_m^2=\widehat k_h^2-\beta_m^2,
$$

定义满足左右齐次 Dirichlet 条件的背景 Green kernel

$$
G_D(x,y;x',y')
=\sum_{m\in\mathbb Z}\psi_m(y)\overline{\psi_m(y')}g_m(x,x'),
$$

$$
g_m(x,x')
=\frac{\sin\!\bigl(\gamma_m(x_<-X_L)\bigr)
\sin\!\bigl(\gamma_m(X_R-x_>)\bigr)}
{\gamma_m\sin(\gamma_mL)},
$$

其中 $x_<=\min(x,x')$、$x_>=\max(x,x')$，$\gamma_m=0$ 使用连续极限。该公式满足
$(\Delta+\widehat k_h^2)G_D=-\delta$、$y$ 向 $\beta$-准周期和
$G_D|_{x=X_L,X_R}=0$。

本节的试验场由数学上精确的 $G_D$ 和有限三角 density 定义。代码中的 Fourier/Kress 求值
只是该 exact-kernel trial 的 ordinary-double approximation；same-density 512 点检查不得称为
可靠 enclosure 或“精确 jump”。

对 retained background wall data $d_L,d_R$，无圆时的显式场为

$$
u_0(x,y)=\sum_{|m|\leq M}\psi_m(y)
\left[
d_{L,m}\frac{\sin(\gamma_m(X_R-x))}{\sin(\gamma_mL)}
+d_{R,m}\frac{\sin(\gamma_m(x-X_L))}{\sin(\gamma_mL)}
\right].
$$

定义 background Dirichlet-pole clearance

$$
\delta_D^{\mathrm{pole}}
=\min_{|m|\leq M_G}
\left|\frac{\sin(\gamma_mL)}{\gamma_mL}\right|,
$$

其中零点使用极限 $1$。本 candidate 满足

$$
\mu_h<\pi^2+\min_m\beta_m^2
=\pi^2+0.25\approx10.1196,
$$

所以解析上没有 background rectangular Dirichlet pole。数值 clearance 小于 $10^{-8}$ 但仍为
有限正数时只记 nonblocking warning；只有 denominator 精确为零、非有限、overflow，或 background
lift 无法返回有限值时才阻断 kernel evaluation。该检查不得升级为 full transmission cell
problem 的唯一性结论。

### 3.2 Müller density 和 signs

圆的法向 $n$ 固定从材料圆指向背景。新矩形 BIE 仍使用 Müller coordinate

$$
\eta=\begin{bmatrix}\tau\\\zeta\end{bmatrix},
\qquad
\zeta=-\sigma,
$$

其中 $\tau$ 是 double-layer density coordinate，$\zeta$ 是第二 density coordinate；二者都
不是物理 trace。raw fields 定义为

$$
u_{\mathrm e}=u_0+D_D^{(\widehat k_h)}\tau-S_D^{(\widehat k_h)}\zeta,
$$

$$
u_{\mathrm i}=D^{(\sqrt{17}\widehat k_h)}\tau
-S^{(\sqrt{17}\widehat k_h)}\zeta.
$$

为使 singular/regular split 可机械审查，写

$$
G_{\mathrm{QP}}(x,y;x',y')
=\sum_{m\in\mathbb Z}\psi_m(y)\overline{\psi_m(y')}
\frac{\mathrm i}{2\gamma_m}e^{\mathrm i\gamma_m|x-x'|},
$$

$$
G_D-G_{\mathrm{QP}}
=\sum_{m\in\mathbb Z}\psi_m(y)\overline{\psi_m(y')}r_m(x,x'),
\qquad
r_m=g_m-\frac{\mathrm i}{2\gamma_m}e^{\mathrm i\gamma_m|x-x'|}.
$$

两个 Green kernels 的 source singularity 相同，所以 $r_m$ 的总和在圆周 source/target 上平滑，
并因圆到墙的正距离而指数收敛。矩形 Müller matrix 复用现有 free-singular Kress differences，
只把 exterior smooth remainder 换成上述 wall correction 加 anchored quasi-periodic remainder；不得
直接用有限 Fourier sum 替代 logarithmic singularity。

令 $K_D,S_D,T_D,K_D^*$ 分别为 $G_D$ 的 double-layer、single-layer、hypersingular 和 adjoint
double-layer operators，$K_i,S_i,T_i,K_i^*$ 为材料圆内部 free-space operators。两侧 traces 是

$$
g_{\mathrm e}=u_0|_\Gamma+
\left(\frac12I+K_D\right)\tau-S_D\zeta,
\qquad
g_{\mathrm i}=\left(-\frac12I+K_i\right)\tau-S_i\zeta,
$$

$$
h_{\mathrm e}=\partial_r u_0|_\Gamma+T_D\tau+
\left(\frac12I-K_D^*\right)\zeta,
\qquad
h_{\mathrm i}=T_i\tau+\left(-\frac12I-K_i^*\right)\zeta.
$$

这里所有 $\partial_r$ 都沿从圆盘指向背景的同一 global $+r$ orientation。因此

$$
\mathcal A_D=
\begin{bmatrix}
I+K_D-K_i&S_i-S_D\\
T_D-T_i&I+K_i^*-K_D^*
\end{bmatrix},
\qquad
\mathcal B_D=\begin{bmatrix}u_0|_\Gamma\\\partial_r u_0|_\Gamma\end{bmatrix}.
$$

这里 $\mathcal A_D$ 是 continuous trace-difference operator，不对它作形式上的 exact inverse。
实际计算只在 $N_\eta=256$ 个 Nystr\"om nodes 上形成 finite matrix $A_{D,256}$ 和 unit-wall
right-hand sides $B_{D,256}^{\mathrm{unit}}$，并解

$$
H_{D,256}=-A_{D,256}^{-1}B_{D,256}^{\mathrm{unit}}.
$$

再形成 finite density maps

$$
H_{+,256}=H_{D,256}G_+,
\qquad
H_{-,256}=H_{D,256}G_-.
$$

把 $H_{\pm,256}$ 的 nodal coefficients 作固定 trigonometric interpolation，并与数学上精确的
$G_D$ layer potentials 组合，才定义 raw continuous trial。一般

$$
\mathcal A_D\eta_{256}+\mathcal B_D\ne0.
$$

该 continuous residual 的两行正是 $\delta_D^{\mathrm{ex}}$ 和
$j_\Gamma^{\mathrm{ex}}$；512-point action 只近似它们。这样 unit-wall data、finite density maps
和 full-$P$ cell states 之间没有隐藏的 incoming translation，也没有把 finite collocation solve
偷换成 continuous inverse。

先为左右单位 wall data 一次组装 background Cauchy right-hand sides，再作一个 multi-RHS
solve，最后与 $G_\pm$ 复合。scaled matrix 的 row/column factors 必须显式记录；在 512 点
overresolved trace action 前，必须把 $\eta$ 恢复为上述物理 $[\tau;\zeta]$ coordinate。

wall value 不通过大数相消求值，而直接使用 $G_D=0$；wall global-$x$ derivative 使用

$$
\partial_xg_m(X_L,x')
=\frac{\sin(\gamma_m(X_R-x'))}{\sin(\gamma_mL)},
$$

$$
\partial_xg_m(X_R,x')
=-\frac{\sin(\gamma_m(x'-X_L))}{\sin(\gamma_mL)},
$$

及其 source-normal derivative。圆到墙的距离为 $0.3$，所以这些 wall series 是平滑、指数
收敛的，不需要 near-boundary quadrature。

## 4. 材料圆的 value-only collar 修复

圆半径固定 $R=0.2$，collar 宽度固定

$$
\delta_c=0.04.
$$

对数学上精确的 $G_D$ 和固定有限三角 density，先定义连续 traces

$$
\delta_D^{\mathrm{ex}}(\theta)
=u_{\mathrm e}(R,\theta)-u_{\mathrm i}(R,\theta),
$$

$$
j_\Gamma^{\mathrm{ex}}(\theta)
=\partial_r u_{\mathrm e}(R,\theta)-\partial_r u_{\mathrm i}(R,\theta),
$$

其中两个 radial derivatives 都使用同一 global $+r$ orientation，而不是两个子域各自的
outward normal。数学 companion、下述 collar 以及分部积分恒等式都使用
$\delta_D^{\mathrm{ex}}$ 和 $j_\Gamma^{\mathrm{ex}}$。

代码对同一个 $N_\eta=256$ 点 density，在 $N_\Gamma=512$ 个圆周点上应用 overresolved
one-sided trace-difference operators，得到 $\delta_{D,512}^{\mathrm{num}}$ 和
$j_{\Gamma,512}^{\mathrm{num}}$，再近似 continuous Fourier coefficients 和 Grams。这些 512 点
量只是 exact continuous traces 的 ordinary-double approximations；BIE solve-grid algebra
residual 不能代替 overresolved action，512 点三角插值也不能被描述为结构性消除了所有
continuous jump。

冻结

$$
\chi(t)=1-3t^2+2t^3,
\qquad
\chi(0)=1,
\quad \chi'(0)=0,
\quad \chi(1)=\chi'(1)=0.
$$

在外、内 collar 分别加入

$$
w_{\mathrm e}(r,\theta)
=-\frac12\delta_D^{\mathrm{ex}}(\theta)
\chi\!\left(\frac{r-R}{\delta_c}\right),
\qquad R\leq r\leq R+\delta_c,
$$

$$
w_{\mathrm i}(r,\theta)
=+\frac12\delta_D^{\mathrm{ex}}(\theta)
\chi\!\left(\frac{R-r}{\delta_c}\right),
\qquad R-\delta_c\leq r\leq R.
$$

在 safe rims 上 correction 的 value 和 radial derivative 都为零；在 $r=R$ 两侧 corrected
values 相等，而 correction radial derivative 为零。因此数学上用 exact continuous traces 定义的
corrected field $u_h^{\mathrm c}$ 属于 $H^1_\beta(B)$，并且 raw normal jump
$j_\Gamma^{\mathrm{ex}}$ 没有被改变。若 $\delta_D^{\mathrm{ex}}=0$，correction 恒为零。数值
实现只近似该 companion；outside-band、staggered-grid 和 256--512 changes 必须保存为
nonblocking diagnostics。

collar 内的 volume source 是

$$
f_{\mathrm e}=(-\Delta-\mu_h)w_{\mathrm e},
\qquad
f_{\mathrm i}=(-\Delta-17\mu_h)w_{\mathrm i}.
$$

它们通过 angular Fourier 正交和一维 radial Gauss quadrature 组装，不建立二维体网格。

## 5. 三项 residual bound 和 field lower bound

### 5.1 人工墙 jump

令 $Q_L$ 和 $Q_R$ 是一个胞元在左、右墙的 outward normal derivative maps。对 plus 和 minus
lead 的内部墙，jump maps 分别为

$$
J_+=Q_R^+ +Q_L^+P_+,
\qquad
J_-=Q_L^- +Q_R^-P_-.
$$

中心空列与第一材料胞元之间的两个 jumps 使用中心显式 Rayleigh derivative 和第一胞元 BIE
wall derivative 单独计算，不能并入一般 tail 后重复计数。

对所有 wall Fourier orders，令

$$
\kappa_m=\sqrt{\beta_m^2+\gamma},
\qquad
b_m^{\mathrm w}=2\kappa_m\tanh(\kappa_m/2).
$$

wall basis $\psi_m$ 对 $\mathrm dy$ 正交归一。每个人工墙两侧长度 $1/2$ 的 intervals 恰好分割
整个波导；又因 $\rho\geq1$，一维最小能量 trace inequality 给出 wall residual bound

$$
(B_h^{\mathrm w})^2
=\sum_{\text{walls}}\sum_m
\frac{|j_{m}|^2}{b_m^{\mathrm w}}.
$$

wall derivative 先在 256 和 512 个 $y$ 点上求值，再在 physical quasi-periodic basis 中作
FFT。正式 512 点 Gram 包括所有 Nyquist orders；不得把 BIE 生成的 $|m|>48$ 成分删掉。

### 5.2 圆周 normal jump

圆周使用 $L^2(\mathrm ds)$ 正交归一 basis

$$
e_\ell(\theta)=\frac{e^{\mathrm i\ell\theta}}{\sqrt{2\pi R}},
\qquad
j_\Gamma^{\mathrm{ex}}=\sum_\ell j_\ell^{\mathrm{ex}} e_\ell.
$$

在内外 annuli 上求 shifted radial minimum-energy extension。令 $t=\log r$，并对每个
$\ell$ 定义 logarithmic derivative $p=v_t/v$。它满足与 modified-Bessel DtN 完全等价的
Riccati equation

$$
p_t=\ell^2+\gamma\rho e^{2t}-p^2.
$$

内环从 $r=R-\delta_c$ 的 natural condition $p=0$ 积分到 $R$，得到
$p_\ell^{\mathrm{in}}(R)>0$；外环从 $r=R+\delta_c$ 的 $p=0$ 反向积分到 $R$，得到
$p_\ell^{\mathrm{out}}(R)<0$。在上述 $L^2(\mathrm ds)$ normalization 下，唯一使用的 weight 是

$$
b_\ell^\Gamma
=\frac{p_\ell^{\mathrm{in}}(R)-p_\ell^{\mathrm{out}}(R)}{R}>0,
$$

因此

$$
(B_h^\Gamma)^2
=\sum_{\text{lead circles}}\sum_\ell
\frac{|j_\ell^{\mathrm{ex}}|^2}{b_\ell^\Gamma}.
$$

每个材料圆的 annulus 外半径为 $0.24$，小于到人工墙的距离 $0.5$，且相邻圆心相距 $1$；所以
不同圆的 annuli 互不相交，也不接触人工墙。各圆最小能量可以相加，circle trace bound 的全局
常数仍为 $1$。

实现用确定性的 classical fourth-order Runge--Kutta stepper 在 $t$ 上直接积分 Riccati equation：
inner interval 按递增 $t$，outer interval 按递减 $t$，分别使用 256 和 512 个等长 steps，512 为
official。不得直接形成会在大 $|\ell|$ 下 underflow/overflow 的 $I_\ell/K_\ell$ 比值。低阶
orders 另与 exponentially scaled modified-Bessel quotient 比较，并保存 energy identity、
positivity 和 256--512 relative change。

weight 非有限、非正或 stepper 无法返回结果时，本项记为
`CIRCLE_TRACE_WEIGHT_NUMERICALLY_UNAVAILABLE`，使 $q_h^{\mathrm{num}}$ unavailable。有限正
weight 即使 256--512 relative change 超过 $10^{-8}$ 也继续使用 official 512-step value；只记
nonblocking warning，并使最终 $q$ 标为 `NUMERICALLY_UNQUALIFIED`，不得结果后换公式。

### 5.3 Collar volume source 和总 bound

定义

$$
B_h^{\mathrm{vol}}
=\gamma^{-1/2}
\left(
\int_{\text{outer collars}}|f_{\mathrm e}|^2
+\int_{\text{inner collars}}17^{-1}|f_{\mathrm i}|^2
\right)^{1/2}.
$$

三个分量使用同一个 $V$ norm，但其支撑和最小 lift 没有证明为正交，所以总量固定为

$$
\mathcal M_h^{\mathrm{num}}
=B_h^{\mathrm w}+B_h^\Gamma+B_h^{\mathrm{vol}}.
$$

禁止把三项改成 root-sum-square 以得到更小结果。

### 5.4 Field-norm lower candidate

同一个 wall-strip inequality 还给出

$$
N_h^{\mathrm{num}}
=\sum_{\text{all artificial walls}}\sum_m
b_m^{\mathrm w}|d_m|^2.
$$

这里每个共享 total Dirichlet trace 只计一次；center-adjacent walls 对应 $D_\pm c_\pm$，随后
walls 对应 $D_\pm P_\pm^nc_\pm$。$N_h^{\mathrm{num}}\leq\|u_h^{\mathrm c}\|_V^2$ 的数学
来源不需要 BIE field identity；DtN--$\mu$ derivative 或高阶边界能量 identity 只属
`OPTIONAL` tightening，不是本 attempt 的 blocker。

### 5.5 Positive-factor Gram contract

每个 wall、circle、collar-volume 和 field-lower quadratic object 都先写成加权 linear factor
$F$，official Gram 只按

$$
W=F^*F
$$

形成。实现保存 factor dimensions、Gram Hermitian defect、最小 eigenvalue 和 matrix scale。
Hermitian defect 及允许的 rounding-level negative eigenvalue 均以 $10^{-12}$ 乘相应 scale 为
尺度；超过该尺度的 indefinite Gram 使 $q_h^{\mathrm{num}}$ unavailable。不得把负 eigenvalues
clip 为零。乘以 $10^8e^{\mathrm i\pi/7}$ 的 coordinate-only repeat 必须满足 quadratic
contraction 除以幅值平方后不变；有限但超过 $10^{-10}$ 的 scale defect 记 nonblocking warning，
不改变 frozen Gram。

## 6. Full-$P$ infinite sums

除 residual/lower Grams 外，每侧还必须用 $W=I_K$ 计算 state tail

$$
\sum_{n=0}^{\infty}\|P^nc\|_2^2.
$$

该 mandatory tail 与有限 cell maps 一起建立数学 trial 的 global $H^1$ summability；只有
semidefinite residual Grams 的有限和不足以替代它。

对任一 required Gram $W$ 和传播矩阵 $P$，定义

$$
W_N=\sum_{n=0}^{N-1}(P^n)^*WP^n,
\qquad
S_N(c)=c^*W_Nc.
$$

doubling 使用

$$
W_{2N}=W_N+(P^N)^*W_NP^N,
\qquad
P^{2N}=(P^N)^2.
$$

每个 $N=2^j$ 同时用两条确定的浮点路径重算 $P^N$ 和 $W_N$。$P_N^{\mathrm L}$ 使用 repeated
squaring；$P_N^{\mathrm R}$ 在 $N\leq4$ 时从 $P$ 作 $N$ 次顺序乘法，在 $N\geq8$ 时取已保存的
$Q=P^{N/8}$ 并作八次顺序乘法。对 Gram recurrence，left path 使用

$$
W_{2N}^{\mathrm L}=W_N^{\mathrm L}+(P_N^*W_N^{\mathrm L})P_N,
$$

right path 使用

$$
W_{2N}^{\mathrm R}=W_N^{\mathrm R}+P_N^*(W_N^{\mathrm R}P_N).
$$

两条路径数学等价但实际 parenthesization 不同，不能把同一次矩阵结果复制两份冒充
association check。令

$$
e_N=\|P_N^{\mathrm L}-P_N^{\mathrm R}\|_2,
$$

$$
a_N^{\mathrm{hi}}
=\|P_N^{\mathrm L}\|_2+e_N
+100K\epsilon_{\mathrm{mach}}
\max\{1,\|P_N^{\mathrm L}\|_2,\|P_N^{\mathrm R}\|_2\},
$$

$$
\omega_N
=\|W_N^{\mathrm L}-W_N^{\mathrm R}\|_2
+100K\epsilon_{\mathrm{mach}}
\max\{\|W_N^{\mathrm L}\|_2,\|W_N^{\mathrm R}\|_2\}.
$$

Gram roundoff scale 必须随 $W$ 同次缩放；$W=0$ 时该 roundoff term 精确取零，禁止以
`max(1,norm(W))` 人为给零 residual 注入非零 allowance。只有除法分母可用 `realmin` 防止
浮点除零，不得把它加进物理 quadratic quantity。Hermitian/PSD tolerance 同样使用实际
$\|W\|_2$ 的相对尺度；零 Gram 单独按精确零对象处理。

若 $a_N^{\mathrm{hi}}<1$，冻结 ordinary-double remainder allowance 和 share 为

$$
t_N(c)=\frac{(a_N^{\mathrm{hi}})^2}{1-(a_N^{\mathrm{hi}})^2}
\bigl(\|W_N^{\mathrm L}\|_2+\omega_N\bigr)\|c\|_2^2,
\qquad
s_N(c)=\frac{t_N(c)}{\max\{\operatorname{Re}S_N(c),\mathrm{realmin}\}}.
$$

固定 $j=0,\ldots,12$ 和 `tail_share_max=1e-6`。只要一个 level 的所有 required sums 和
allowances 有限、$a_N^{\mathrm{hi}}<1$ 且 squared sums 非负，它就能形成 ordinary-double tail
candidate；精确为零的 residual component 是合法结果，不得因 $S_N=0$ 自动拒绝。优先选择第一个
所有 required shares 都不超过 $10^{-6}$ 的 level。若没有这样的 level，但存在可用 level，则选择
maximum required share 最小者；tie 时取最小 $N$，继续计算并记录
`TAIL_SHARE_QUALIFICATION_WARNING`。state tail 同样以 $a_N^{\mathrm{hi}}<1$ 建立 finite
summability candidate，share 只控制数值资格，不把 finite share failure 升级为 $q$ unavailable。
所有 $e_N,a_N^{\mathrm{hi}},\omega_N,t_N,s_N$ 都写入 artifact。不得用逐 multiplier scalar
tail、$P^{-1}$ 或 eigendecomposition。

residual 的 wall/circle/collar squared sums 使用 $\operatorname{Re}S_N+t_N$ 作为 ordinary-double
upper candidate。field lower 只能使用有限部分和 $\operatorname{Re}S_N$；$t_N$ 是上侧 allowance，
不得加到 denominator。state tail 只用于判定 global summability。所有 $t_N$ 仍是普通双精度
allowance，不是 outward enclosure。

circle/collar 的 lead-cell sum 从 $n=0$ 开始。内部 wall-jump sum 也从第一与第二材料胞元之间的
wall 开始，即 $J_\pm P_\pm^nc_\pm$ 的 $n=0$ term；两个 center/first jumps 单列。field lower
明确由 center-adjacent wall $D_\pm c_\pm$ 加上 farther walls
$D_\pm P_\pm^nc_\pm$、$n\geq1$ 组成，每个物理 wall 只计一次。state-tail 和 circle/collar
cell sums 均从 $n=0$ 开始。任一 required Gram 的 infinite sum 无法在冻结 power 内闭合时，
仍保存所有 finite rows，但不给 $q_h^{\mathrm{num}}$。

## 7. Frozen numerical contract

### 7.1 Levels 和阈值

| 对象 | Frozen values | 用途 |
|---|---|---|
| finite density | $N_\eta=256$ | 定义 official finite-layer-potential trial |
| overresolved circle action | $N_\Gamma=512$ | 近似 $\delta_D^{\mathrm{ex}}$ 和 $j_\Gamma^{\mathrm{ex}}$ |
| smooth wall correction orders | $M_G=48,64$ | 64 为 official，48--64 为 kernel diagnostic |
| wall FFT samples | 256, 512 | 512 为 official，256--512 为 diagnostic |
| radial collar Gauss | 16, 32 | 32 为 official，16--32 为 diagnostic |
| circle quotient integration | 256, 512 steps | 512 为 official，256--512 的 $10^{-8}$ 只作 warning scale |
| scale repeat | $10^8e^{\mathrm i\pi/7}$ | phase/scale invariance diagnostic |
| BIE factor/solve scales | rcond $10^{-8}$、residual $10^{-10}$ | nonblocking qualification |
| ordinary refinements | relative change $0.20$ | nonblocking qualification |

同一 $N_\eta=256$ density 在 512 点上的 trace action 只是对同一 finite trial 的更细求值，不是
independent discretization、continuous error estimate 或 I3.2 reference。所有 refinement 和
old-scattering comparisons 都是同链内部检查。

### 7.2 Exact-kernel evaluator checks

实现必须保存：$G_D$ reciprocity、左右 wall zero identity、background wall-lift identity、
circle manufactured Fourier mode、regular-diagonal finite check、48--64 smooth-correction change、
scaled/unscaled density roundtrip 和 $\zeta=-\sigma$ sign oracle。evanescent sine/hyperbolic ratios使用
scaled formulas；不得形成中间 overflow 后再相除。

kernel formula、wall identity 或 density coordinate 出现 nonfinite/size mismatch 时属于真正数值
错误。有限但未达到建议精度的 identity、factor rcond、solve residual 或 refinement 只降低
qualification，不提前丢弃后续 residual 数据。

## 8. Failure semantics 和结论边界

### 8.1 真正 hard errors

只有下列情况停止后续数值 stage，并保存已形成的 diagnostics：

1. attempt/output guard、MATLAB availability 或 frozen input size 失败；
2. branch 或 $P_\pm,c_\pm$ action 非有限，或 background denominator 精确为零、非有限、overflow；
3. exact-kernel evaluator、density、wall/circle action 出现 nonfinite 或维数错误；
4. BIE factor/solve 无法返回有限 density；
5. hard wall time 或 memory limit 超过预算。

这些情况归入 `EXECUTION_UNAVAILABLE` 或更具体的 numerical-unavailable code。BIE rcond 小、finite
solve residual 大、circle jump 大、source/kernel refinement 大、outside-$M$ 能量大、旧 scattering
comparison 差、phase/scale 差都不是停止理由；它们必须随最终数值一起报告。
有限正的 Dirichlet-pole clearance 即使小于 $10^{-8}$ 也属于同一 nonblocking warning。

### 8.2 阻断 $q$、但不抹去前序数据的条件

下列结果不是 implementation crash，但使 $q_h^{\mathrm{num}}$ unavailable：

- circle trace weights 非有限、非正或 stepper unavailable；
- required residual/lower/state full-$P$ tail 在冻结 power 内没有任何有限且
  $a_N^{\mathrm{hi}}<1$ 的可用 level；
- $N_h^{\mathrm{num}}$ 非有限或不为正；
- residual component 非有限，或 squared-norm Gram 显著 indefinite。

producer 仍应保存有限 circle/wall/collar maps、Grams 和 tail rows，并指出第一个 unavailable
condition。

若 $q_h^{\mathrm{num}}$ 有限但 $q_h^{\mathrm{num}}\geq1$，正式结论是
`PURE_BIE_RESOLUTION_INSUFFICIENT`。若 $q_h^{\mathrm{num}}<1$，可按

$$
I_\lambda^{\mathrm{num}}
=\left[
\max\left\{0,\frac{\mu_h-q_h^{\mathrm{num}}\gamma}{1+q_h^{\mathrm{num}}}\right\},
\frac{\mu_h+q_h^{\mathrm{num}}\gamma}{1-q_h^{\mathrm{num}}}
\right]
$$

以及 $I_k^{\mathrm{num}}=\sqrt{I_\lambda^{\mathrm{num}}}$ 报告 nominal interval。只要没有 outward
numerics，该区间一律带 `UNQUALIFIED`；nonblocking diagnostics 失败时状态进一步标为
`NUMERICALLY_UNQUALIFIED`，但不得隐藏数值。

无论哪种结果，本 attempt 都不能声称：finite BIE density 是 exact cell solution、candidate 是
finite determinant zero、连续特征值已存在、特定 mode 已唯一识别、形成了 convergence order、
I3.2 independent validation 或可计算误差上界。

## 9. 实现、artifact 和资源

### 9.1 文件边界

首选入口为

- `test/i3/p-resid/check_p_resid.m`：frozen input、propagation、residual Grams、full-$P$ tail、
  estimator、schema、report 和资源合同；
- `test/i3/p-resid/i31_cell_bie.m`：rectangular Green、Kress Müller solve、overresolved circle action
  和 wall normal maps。

若 `check_p_resid.m` 超过约 1000 行，才允许按单一科学边界增加
`i31_bdry_est.m`，只承接 wall/circle trace weights、collar Grams 和 tail；不得为通用 utilities 或
抽象接口继续拆文件。所有 stem 不超过 15 个字符，文件头解释缩写全称。不得修改或运行历史
`s-resid`、`g-resid`、`w-resid`、`b-resid` 代码和 output。

### 9.2 Frozen attempt 和 schema

- Attempt: `pbie-a1`。
- Schema: `TEP_I3_1_PURE_BIE_BOUNDARY_RESIDUAL_V1`。
- Output: `test/i3/p-resid/output/pbie-a1/`，运行前必须不存在，运行后 append-only。
- 唯一 MATLAB 命令：

```text
matlab -batch "addpath(fullfile(pwd,'test','i3','p-resid'),fullfile(pwd,'test','i2','k-count')); check_p_resid('pbie-a1');"
```

- `retry_count=0`，`prior_failed_attempt_count=0`。

`result.mat` 至少保存：config、candidate/weighted state、branch/Wood、$P_\pm$ 和 $c_\pm$、kernel
checks、density solve、wall/circle trace maps、$\delta_{D,512}^{\mathrm{num}}$、
$j_{\Gamma,512}^{\mathrm{num}}$、collar/trace Grams、每个
full-$P$ tail row、三项 residual、field lower、$q$、nominal interval、nonblocking warnings、
coverage/reliability flags、`first_nonblocking_failure`、`first_q_unavailable_condition`、
`first_execution_blocker`、elapsed time 和 peak active-object memory。
不保存 pair-kernel 大矩阵或二维场样本。

所有可靠性 flags 初始并保持 `false`：`outward_residual_upper`、`outward_field_lower`、
`certified_tail`、`certified_projected_gap`、`independent_reference`、`reliable_spectral_interval`。
普通双精度下即使所有内部 checks 通过也不得改为 `true`。

### 9.3 资源

- 预计 wall time：5--10 分钟；预计 peak active-object memory：150--300 MiB。
- Soft/hard wall time：900/1800 秒；hard active-object limit：512 MiB。
- 每个大 stage 前检查 soft limit；超过 soft limit 后不启动新 stage，直接保存已有数据。
- 只统计当前 active MATLAB objects；不运行明显昂贵的参数搜索，不因结果调整网格、$M_G$、
  collar、threshold 或 tail depth。

## 10. Theory--implementation checklist

正式实现前，Researcher 和 Engineer 必须逐项确认：

1. saved $\widehat k_h$、weighted $q$、$D_\pm$、$P_\pm$ 和共享 wall sequence 没有重定义；
2. 数学 trial 使用 finite density 加 exact $G_D$，没有偷换成 exact cell solution；
3. $u_0$ 是 BIE right-hand side 的唯一 wall driver，incoming 只作 diagnostic；
4. $[\tau;\zeta]$、$\zeta=-\sigma$、row/column unscaling 和 global normal orientations 一致；
5. 数学 collar 使用 exact continuous $\delta_D^{\mathrm{ex}}$，512 点量只近似其 coefficients；
6. collar 只修 value jump，safe seams 的 value/derivative correction 都为零；
7. raw circle normal jump、collar volume source 和所有 artificial-wall jumps 均进入 numerator；
8. wall、circle、volume 使用 triangle sum，field lower 每个 wall 只计一次；
9. circle basis normalization、deterministic Riccati stepper 与
   $b_\ell^\Gamma=(p_{\mathrm{in}}-p_{\mathrm{out}})/R$ 完全一致；
10. all lead Grams 和 mandatory $W=I_K$ state tail 使用 full-$P$ doubling，center/first 和
    $n=0$ indexing 无重复或遗漏；
11. same-chain checks 不被称为 I3.2 reference，所有 interval 和 existence flags 保持不可靠。

Skeptic 必须在实现前独立审查 exact-kernel/truncation distinction、circle basis normalization、
collar 分部积分、left/right orientation、tail indexing、failure precedence 和 ordinary-double claim
boundary。Skeptic 未给 `DESIGN PASS` 前，不得编写实验代码或运行 `pbie-a1`。

## 前瞻修订 A：typed warning schema

首次正式 attempt `pbie-a1` 完成 frozen input、branch/Wood、propagation、coordinates、actual-state
closure 以及 finite-density exact-kernel boundary action 后，在记录第一个 nonblocking warning 时因
MATLAB struct schema 不一致而停止。shell exit code 为 0；producer outcome 为
`EXECUTION_UNAVAILABLE`；identifier 为 `MATLAB:heterogeneousStrucAssignment`；原始消息为
`Subscripted assignment between dissimilar structures.`；耗时为
`133.37207583333333` s，peak active-object memory 为 `62.314550399780273` MiB。触发记录的数值是
wall $256\to512$ relative change `0.23020558465752644`，它仍只是 nonblocking warning。boundary
Grams、full-$P$ tails、$q$ 和 nominal interval 均未进入。

append-only `pbie-a1` 中只含 `result.mat` 和 `report.md`；其 SHA-256 分别为
`473a6809b5e8910c8e8daa82be5dd68c39da24f0edfa6c187abecba1629a7c51` 和
`925132cd91bdf6ed29e3a4a7aed7a4661014427f84a42734825b616f717c9ecb`。Revision A 统一把 top-level、
finite、cell 和 boundary 的 warning 容器初始化为含 `code/value/blocking` 字段的 typed empty
struct。新 attempt 为 `pbie-a2`，schema 为
`TEP_I3_1_PURE_BIE_BOUNDARY_RESIDUAL_V1_REV_A`，attempt-local `retry_count=0`，并记录一个 prior
failed attempt。科学公式、参数、阈值、失败语义和资源预算均不变；特别是 wall refinement
warning 与 finite manufactured-kernel warning 不得被压掉。Revision A 须经独立 spec-to-code
审查后才可运行。
