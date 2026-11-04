# MFS 核回卷切换线的残差项（经理提案，待审）

状态：经理 2026-11-04 写的提案；审查（[[research/projects/bie-enclosure/theory/switch-line-kress-review|switch-line-kress-review]]）判为按 S-1–S-3 修补后成立，修补已并入下文。对应 [[research/projects/bie-enclosure/open-problems|open-problems]] 的 OP-BE-6。记号沿用 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]] 的 T2.1–T2.3、T4.2–T4.5。MFS 是 method of fundamental solutions（基本解方法）。

## 1. 代码里的核是什么

`+kernel/qpgreen_mfs_pairmat.m` 在计算坐标里工作（第一坐标是物理 $y$，周期 $d$；第二坐标是物理 $x$）。对一对源 $s$、目标 $t$，令 $X=t_y-s_y$，$Y=t_x-s_x$，$m=\operatorname{round}(X/d)$，$X_0=X-md$。当 $|Y|\le H$ 时

$$
\widetilde G_\kappa(t,s)=e^{i\beta md}\,K_\kappa(X_0,Y),\qquad
K_\kappa(X,Y)=\tfrac i4H_0^{(1)}(\kappa|(X,Y)|)+\sum_{q}c_q\,\tfrac i4H_0^{(1)}(\kappa|(X,Y)-Z_q|),
$$

其中代理点 $Z_q$ 在盒子 $[-d/2-p,\,d/2+p]\times[-H-p,\,H+p]$ 的边上（$p$ 为 `proxy_dist`），系数 $c_q$ 由最小二乘拟合给出。$|Y|>H$ 时改用平面波展开。

因此：

- $K_\kappa$ 在 $|X|\le d/2$、$|Y|\le H$ 内除原点外是精确的 Helmholtz 解（代理点都在盒外）。
- 在切换线以外，$\widetilde G_\kappa(\cdot,s)$ 精确满足 $\beta$ 准周期。源恰好在高度 0（切换线落在接缝上）时例外，但这样的源只占弧长零测集，对连续密度的积分场不产生接缝残差。所以积分场的接缝跳跃 $J_{\Sigma,0},J_{\Sigma,1}$ 为零。有限求积的接缝诊断值除舍入外，还可能含落在接缝上的源节点的贡献（审查 S-3）。
- 代价是：对每个源 $s$，$\widetilde G_\kappa(\cdot,s)$ 在水平线 $\Lambda_s=\{t:\ t_y-s_y\equiv d/2 \pmod d\}$ 上不连续。跳跃等于最小二乘拟合在盒子上下壁的准周期残差：

$$
j_0(Y)=K_\kappa(-d/2,Y)-e^{-i\beta d}K_\kappa(d/2,Y),\qquad
j_1(Y)=\partial_XK_\kappa(-d/2,Y)-e^{-i\beta d}\partial_XK_\kappa(d/2,Y)
$$

（上侧减下侧，差一个模为 1 的因子）。budget-v1 的参数下实测 $|j_0|\le4.4\times10^{-12}$，$|j_1|\le5.1\times10^{-12}$（`tmp/mfs-wrap-check/wrap_jump.m`）。

- 若不回卷、直接把 $s+Z_q$ 当作固定点源（T2.1 字面上的写法），部分代理点会落在胞元内部，违反 T2.1 条件 1。所以现有核无论哪种读法都不在 T2.1 的覆盖范围内，必须补一项。

## 2. 提案：把切换线当作一族随源变化的界面

设一个均匀分片 $P$（某胞元内的背景或柱内部分）上的场为

$$
u_P(t)=\int_\Gamma\Bigl(\tau(s)\,\partial_{\nu_s}\widetilde G_\kappa(t,s)-\sigma(s)\,\widetilde G_\kappa(t,s)\Bigr)\,ds+(\text{在 }P\text{ 内精确光滑的项}),
$$

密度 $\tau,\sigma$ 是固定的三角多项式。对每个 $s\in\Gamma$，令 $\Lambda_s^P=\Lambda_s\cap P$（有限条水平线段），在其上定义被积核的跳跃

$$
\mathcal J_0(t;s)=\tau(s)[\partial_{\nu_s}\widetilde G_\kappa]-\sigma(s)[\widetilde G_\kappa],\qquad
\mathcal J_1(t;s)=\tau(s)[\partial_{t_y}\partial_{\nu_s}\widetilde G_\kappa]-\sigma(s)[\partial_{t_y}\widetilde G_\kappa],
$$

$[\cdot]$ 为跨 $\Lambda_s$ 上侧减下侧，再令

$$
e_s^2=\int_{\Lambda_s^P}\bigl(|\mathcal J_1(t;s)|^2+\ell^{-2}|\mathcal J_0(t;s)|^2\bigr)\,dt_x .
$$

**命题 S（按审查 S-1、S-2 修补）。** 边界上的法向通量**定义为**分支导数的源积分：对每个 $s$ 在所选光滑分支上求导，再对 $s$ 积分；普通自由空间层势保留通常的单侧极限。这正是代码的做法（`qpgreen_mfs_pairmat.m` 116–121 行，以及 budget_run.m 的值与法向矩阵）。它一般不等于积分场的真实法向导数，差别来自切换线在源积分中产生的分布项（审查 S-1 给了一维反例）。用这样定义的值和通量构成各界面的跳跃，相应的分组量记为 $Q_{\rm grp}^{\rm br}$；budget-v1 测的就是它。

在 T2.3 的其余假设下，把残差恒等式按源 $s$ 分解。每个固定的 $s$，$\widetilde G_\kappa(\cdot,s)$ 在 $P\setminus(\{s\}\cup\Lambda_s)$ 内满足 Helmholtz 方程，直到 $\Lambda_s$ 两侧光滑。先分出普通奇异自由空间层势；其余分支函数在紧集上一致有界，所以可以对 $s$ 积分各自的分片 Green 恒等式。固定源的角点交点不产生边项。这样得到弱 Green 恒等式

$$
(\widehat u,(A-\mu)z)_{\mathcal H}=R^{\rm br}_\partial(z)-\sum_PR_{{\rm sw},P}(z),
$$

不需要积分场逐片属于 $H^2$。其中

$$
R_{\rm sw}(z)=\int_\Gamma\int_{\Lambda_s^P}\Bigl(\mathcal J_1(t;s)\overline{z(t)}-\mathcal J_0(t;s)\overline{\partial_yz(t)}\Bigr)\,dt_x\,ds
$$

（两种跳跃都取上侧减下侧，所以它在上式中带负号，审查 S-2）。对每个 $s$，$\Lambda_s^P$ 是平直线段，取上下各 $\delta$ 的领子，它可以穿过材料曲线（$z\in H^2_\beta(B)$）。T4.2–T4.3 给出 $\kappa=0$、$N=1$ 的平直界面常数 $C_{\rm line}$（与墙同式，$\delta=0.2$ 时为 1.0356）：

$$
\Bigl|\int_{\Lambda_s^P}(\cdots)\Bigr|\le C_{\rm line}\,e_s\,\|(A+\mu)z\|_{\mathcal H}.
$$

对 $s$ 用积分形式的三角不等式（Minkowski），得

$$
|R_{\rm sw}(z)|\le C_{\rm line}\Bigl(\int_\Gamma e_s\,ds\Bigr)\|(A+\mu)z\|_{\mathcal H},
\qquad
\boxed{Q=Q_{\rm grp}^{\rm br}+C_{\rm line}\sum_P\int_\Gamma e_s\,ds .}
$$

引线胞元同理：同一源高度在各引线胞元的切换段位于同一条水平线上，覆盖重数为 1，$e_s^2$ 对胞元求和，并按 T3.8 的方式补传播尾。

**审查结论。** 下列各点都判为正确：
- Fubini 交换；
- 双层核的跳跃；
- 角点不产生额外项；
- 跨过材料曲线的平直领子；
- $C_{\rm line}=1.0356$（审查用有理数判别式验证它是上界）；
- 引线胞元的求和。

实际配置中，同一胞元的目标满足 $|t_x|\le0.5$，源满足 $|s_x|\le0.36$，所以 $|Y|\le0.86<H=1.1$，平面波分支不会启用。Minkowski 一步丢掉了不同源之间的相消，所以这个界偏保守；保守多少要由数值决定。

**对可靠评价器的限制。** 这一条在审查的逐项表之后。T3.1、T3.2、T3.3 的解析带条件和 Taylor 圆盘条件，不能跨过满足 $t_y-s_y=\pm d/2$ 的源参数。所以可靠评价时，源积分要在这些参数处分段，或者对跨过切换的部分另作包络。

## 2′. 命题 S′：沿切换线分部积分一次（经理提案，待审）

**为什么要改。** switch-v1 按命题 S 得 $Q_{\rm sw}=1.41\times10^{-9}$，是 $Q_{\rm grp}$ 的 344 倍，(B0) 不成立。最大项是双层核的 $[\partial_y^2\widetilde G]$，约 $3.5\times10^{-9}$。经理核对了 $j_0$ 是光滑函数而不是舍入噪声：沿线有限差分与 $[\partial_x\widetilde G]$ 相符，主频约 100，所以每求一次切向导数就放大约 100 倍。加密配点或加大代理距离都不能减小它：配点 160→1280 时 $[\partial_y^2\widetilde G]$ 由 $4\times10^{-9}$ 增到 $6\times10^{-8}$，代理距离 0.2→0.5 时增到 $6\times10^{-8}$（`tmp/mfs-wrap-check/`）。

**做法。** 在 $\Lambda_s$ 上，跳跃对切向 $x$ 光滑；两侧分支都满足 Helmholtz 方程，所以

$$
[\partial_x\partial_y\widetilde G]=\partial_x[\partial_y\widetilde G],\qquad
[\partial_y^2\widetilde G]=-\partial_x^2[\widetilde G]-\kappa^2[\widetilde G].
$$

把 $\mathcal J_1$ 里的切向导数沿线段分部积分一次，转到 $z$ 上（$z\in H^2_\beta(B)$，所以 $\partial_xz$ 在直线上有 $L^2$ 迹，$z$ 有点值）。记 $g_0=[\widetilde G]$、$g_x=[\partial_x\widetilde G]$、$g_y=[\partial_y\widetilde G]$，$\nu_s=(n_x,n_y)$。对固定的 $s$，线段 $\Lambda^P_s=\{(x,h(s)):\ a\le x\le b\}$ 上

$$
\int_{\Lambda_s^P}\mathcal J_1\bar z\,dx
=\int\Bigl(\tau n_y\kappa^2g_0-\sigma g_y\Bigr)\bar z\,dx
+\int\tau\bigl(n_xg_y-n_yg_x\bigr)\,\overline{\partial_xz}\,dx
+\Bigl[\tau\bigl(n_yg_x-n_xg_y\bigr)\bar z\Bigr]_{x=a}^{x=b},
$$

（符号细节待审；下面只用绝对值。）记

$$
A_0=\tau n_y\kappa^2g_0-\sigma g_y,\quad
A_1=\tau(n_xg_y-n_yg_x),\quad
\mathcal J_0=-\tau(n_xg_x+n_yg_y)-\sigma g_0,\quad
E=\tau(n_yg_x-n_xg_y).
$$

**命题 S′（已审，按 SP-1 修正了权重）。** 审查见 [[research/projects/bie-enclosure/theory/switch-line-sprime-review|switch-line-sprime-review]]：0 个 blocker，1 个 important caveat（SP-1，权重）；$A_0,A_1,E$ 的符号正确，$C_{\rm pt}$ 的数值也核对过。

$$
\boxed{Q=Q^{\rm br}_{\rm grp}+C_{\rm line}\sum_P\int_\Gamma e'_s\,ds+C_{\rm pt}\sum_P\int_\Gamma\bigl(|E(a_s;s)|+|E(b_s;s)|\bigr)\,ds,}
$$

$$
e'^2_s=\int_{\Lambda_s^P}\bigl(|A_0|^2+\ell^{-2}|A_1|^2+\ell^{-2}|\mathcal J_0|^2\bigr)\,dx .
$$

这组权重与迹范数 $\|z\|^2_\Lambda+\ell^2\|\nabla z\|^2_\Lambda$ 对偶（SP-1）；$\ell=1$ 时与原式相同，switch-v1 的数值不变。端点项要计入每条线段的两个端点，包括引线内墙两侧各自的端点。引线的端点尾按绝对值和（$L^1$）估计，不能用 T3.8 的平方和公式；这个尾界的具体形式见审查。

理由：

1. **线迹。** 对 $g=\partial_xz$ 与 $g=\partial_yz$ 重复 T4.2 的证明，即 (T4.5) 的论证，只是把 $\nu\cdot\nabla v$ 换成 $\nabla v$ 的分量：$g'$ 仍被 $|D^2v|_F$ 控制。所以 $\|z\|^2_\Lambda+\ell^2\|\nabla z\|^2_\Lambda$ 与原来的 $\|z\|^2_\Lambda+\ell^2\|\partial_yz\|^2_\Lambda$ 有同一个多项式 $p$，$C_{\rm line}$ 不变。
2. **点值常数。** 对 $\beta$ 准周期的 $z\in H^2_\beta(B)$ 和任意 $\alpha>0$，用 $y$ 向 Fourier 级数、$x$ 向 Fourier 变换以及 Cauchy–Schwarz：

$$
|z(p)|^2\le S(\alpha)\,\|(\alpha-\Delta)z\|^2_{L^2(B)},\qquad
S(\alpha)=\frac1d\sum_{m\in\mathbb Z}\frac{1}{4(\alpha+\beta_m^2)^{3/2}},
$$

其中用到 $\frac1{2\pi}\int_{\mathbb R}(c+\xi^2)^{-2}d\xi=\frac1{4c^{3/2}}$。再由 $-\Delta z=\rho Az$，得 $\|\Delta z\|_{L^2}\le\rho_{\max}^{1/2}\|Az\|_{\mathcal H}$，且 $\|z\|_{L^2}\le\rho_{\min}^{-1/2}\|z\|_{\mathcal H}$。所以

$$
C_{\rm pt}=\min_{\alpha>0}\sqrt{S(\alpha)}\Bigl(\frac{\alpha}{\sqrt{\rho_{\min}}\,(\lambda_0+\mu)}+\sqrt{\rho_{\max}}\Bigr).
$$

3. **对源求和。** 与命题 S 一样，对 $s$ 用 Minkowski。引线胞元的线段端点在每面内墙上，逐胞元相加，再补传播尾。

**粗估。** $|A_1|,|\mathcal J_0|$ 由 $g_x\approx4\times10^{-11}$ 主导，代替了原来约 $3.5\times10^{-9}$ 的 Hessian 跳跃，所以线段项约小 70–100 倍。端点项约为 $C_{\rm pt}\times4\times10^{-11}\times\int|\tau|$。这些都待 switch-v1 run-002 实算。

## 3. 另一条路（备用）

换一个以胞元为界的核：近处三个像 $m=-1,0,1$ 直接求和，代理点只负责 $|m|\ge2$。这样场在胞元内没有切换线，缺陷移到接缝上，由已审的 T2.3 接缝项处理。代价是要重拟合代理并重求密度，而且接缝跳跃会变成拟合残差量级，不再是舍入量。只有命题 S 给出的余量不够时才走这条路。
