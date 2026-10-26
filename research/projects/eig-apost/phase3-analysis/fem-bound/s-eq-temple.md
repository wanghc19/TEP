<!-- Localized equilibrated-flux estimator, Bloch-tail trial and resolvent-Temple bound for the I9 FEM spectral distance -->

# 局部化通量界与预解式 Temple 二次界：I9 FEM 谱距离的新方案

日期：2026-10-24。身份：**方法提案（Revision C 候选）**。本文给出新定理及完整证明，
但未经独立审查、未写实验代码、未运行 MATLAB；第 7 节的量级均为规划用预测，不是结果。
依据为 [[research/projects/eig-apost/phase3-analysis/fem-bound/theory|FEM-bound Revision B.1]]
（下称 B.1）与 [[research/projects/eig-apost/implementation/i9/design-9-4a|I9.4 实测]]、
[[research/projects/eig-apost/implementation/i9/review-9-4a|I9.4 独审]]。
B.1 的命题 1、定理 2–3、§7 的 RT2 空间与 §9 的真实材料积分全部保留；本文只在其上叠加。

## 0. 结论摘要

I9.4 的 $R_{\mathrm{num}}=1.7198$ 偏松，有四个**相互独立**的原因。只修通量最多消除其中两个：

| 编号 | 机制 | I9.4 中的量 | 是否可由更好通量消除 | 本文处理 |
|---|---|---|---|---|
| D1 | 体缺陷按 $s^{-1/2}\|\rho^{-1/2}\cdot\|$ 付费、无网格权重；边平均通量不平衡 | 加权体缺陷平方 $1.0683$，占 $M_s^2$ 的 $99.99\%$ | 是 | 加权最小二乘通量 + 定理 B 的 Poincaré 加权 |
| D2 | 真实/网格材料失配在无权形式下形成地板 | 失配诊断平方 $3.51\times10^{-4}$，对应 $\eta$ 地板约 $0.012$ | 否（无权形式下） | 定理 B：振荡部分乘 $C_{P,K}\approx h_K/\pi$ |
| D3 | B.1 定理 3 对残差为**线性**；无谱隙信息时该阶数不可改进 | 即使通量最优，$R_s\approx2.2\tau$ | 否 | 定理 C：单侧谱隙下的二次界 $x_T\approx3.1\tau^2$ |
| D4 | 零延拓在人工端支付 $\partial_xu$ | $\eta$ 中 $0.0073$；单独即给线性 $R\approx0.0162$ | 否（固定截断下） | Bloch 尾试探函数（命题 E） |

新方案由以下组件组成：

1. **定理 B（局部化切线通量界）。** 对任意分片 $H(\operatorname{div})$ 通量成立。单元均值部分按质量付费，均值为零的振荡部分乘曲边 Poincaré 常数。对同一通量，它从不劣于 B.1 式(9)。
2. **加权最小二乘 RT2 通量。** 沿用 B.1 §7 的 $X_h$ 与装配，只改权重，仍为 Hermitian 正定系统。
3. **命题 E（Bloch 尾）。** 在 lead 胞元墙处把 FEM 场接到离散衰减 Floquet 模态，用胞元 Gram 阵与 Stein 级数精确求和无限尾。
4. **定理 C（预解式 Temple 不等式）。** 仍只用 $u\in V$ 与 B.1 的谱测度恒等式。在"候选上方到 $\lambda_+$ 无谱"的假设 $\mathrm H^+$ 下，给出
   $$
   \lambda_\star\in[\mu_{\mathrm R}-x_T,\ \mu_{\mathrm R}],\qquad
   x_T\le\frac{(\lambda_++s)\tau^2}{\lambda_+-\mu_{\mathrm R}}.
   $$

**预测（非结果）：** 在现有 I9.3 原生场上，仅做第 1、2 项时，无条件线性界预计约 $0.03$–$0.06$。加上第 4 项、取 $\lambda_+=2.1875^2$ 时，条件二次界预计 $x_T\approx7\times10^{-4}$–$2\times10^{-3}$，可达 $0.01$ 参考尺度。$10^{-4}$ 尺度需要 $\tau\lesssim5.7\times10^{-3}$，因此至少还需第 3 项，可能还需另行授权的 FEM 加密。

## 1. 记号与沿用对象

沿用 B.1 式(1)–(6)：条带 $B=\mathbb R\times I$，$I=(-d/2,d/2)$；$\mathcal H=L^2(B,\rho)$，$V=H^1_\beta(B)$；
形式 $a$、移位形式 $a_s$、能量范数 $\|\cdot\|_s$；$A=A(\beta)$ 为 B.1 式(4) 的非负自伴算子。
对任意试探函数 $u\in V\setminus\{0\}$ 与实数 $\mu$，记

$$
\ell_\mu(v)=a(u,v)-\mu(u,v)_{\mathcal H},\qquad
\eta_s(\mu)=\sup_{0\ne v\in V}\frac{|\ell_\mu(v)|}{\|v\|_s},\qquad
U=\|u\|_{\mathcal H},\qquad
\mu_{\mathrm R}=\frac{a(u,u)}{U^2}.
\tag{1}
$$

$\mu_{\mathrm R}$ 是试探函数在**真实** $\rho$ 下的 Rayleigh 商。它与 FEM 输出 $\mu_h$ 相差 $\rho$ 与 $\rho_h$ 的失配、积分差和特征求解残差，可直接计算。
$\nu_u$ 为 $u$ 的谱测度，$C_{\mathrm{end}}=(2\sqrt{s\rho_{\min}})^{-1/2}$ 及其迹不等式沿用 B.1 式(12)；
该不等式对任意竖线 $x=t$ 成立，不只对人工端成立。新增符号见第 10 节表格。
Floquet 乘子记 $\zeta_j$；$\Lambda$ 仍保留给 DtN。

## 2. I9.4 偏松的定量诊断

### D1：无网格权重的体缺陷

B.1 式(9) 以 $s^{-1}\|\rho^{-1/2}(\operatorname{div}p+\mu_h\rho u)\|^2$ 支付全部体缺陷。I9.4 的原生场体缺陷 $\sum_Kr_K^2=0.351$ 本身就是 $P_2$ 强残差的正常量级：强残差的 $L^2$ 范数只按 $O(h)$ 下降，而能量误差按 $O(h^2)$ 下降。

在无权形式下，任何逐元接近 $\nabla u_h$ 的通量都有 $\operatorname{div}p\approx\Delta u_h$，单此一项就给 $\tau\approx(0.351/s)^{1/2}=0.380$，即 $R\approx0.9$。

边平均修正又加入散度平方 $0.891$，因为一次平均只保证法向连续，不保证单元均值平衡。

经典残差估计中，该残差应带权 $h_K/\pi$ 量级。作为示意：若均值为零、$h_K\equiv1/12$，同一 $0.351$ 只贡献 $(0.351)^{1/2}/(12\pi)=0.0157$。实际网格在界面附近更细。

### D2：材料失配地板

FEM 使用网格标签 $\rho_h$，主残差使用真实 $\rho$。差项 $f=\mu(\rho-\rho_h)u$ 支撑在曲线与 $P_2$ 插值曲线之间的薄片上。逐元 $\operatorname{div}p$ 是映射多项式，无法在薄片内抵消 $f$ 的振荡部分。

因此在无权形式下，**无论通量多好**，$\eta$ 都有约 $(3.51\times10^{-4}/s)^{1/2}=0.0120$ 的地板，线性界下对应 $R\approx0.027$。这里 $3.51\times10^{-4}$ 是 I9.4 的普通积分诊断，含未决分类片。

定理 B 中，该振荡部分乘 $C_{P,K}$。薄片单元的直径约为 $0.03$，所以 $C_{P,K}\approx10^{-2}$。$\|f\|_{L^2}\le(17\times3.51\times10^{-4})^{1/2}=0.077$ 是不加权范数的粗上界，因此该项预计至多 $10^{-3}$ 量级（启发式，待实测）。

### D3：线性界的固有阶数

B.1 定理 3 满足 $R_s\approx\sqrt{\mu_h+s}\,\tau=2.204\tau$（$s=\mu_h$）。没有谱隙信息时，线性阶在一阶近似下不可改进。

例：设 $A$ 有特征对 $(\lambda_1,e_1)$、$(\lambda_2,e_2)$，$\lambda_1<\lambda_2$，取 $u=(e_1+e_2)/\sqrt2$。则
$\mu_{\mathrm R}=(\lambda_1+\lambda_2)/2$，
$\operatorname{dist}(\mu_{\mathrm R},\sigma(A))=(\lambda_2-\lambda_1)/2$，并且由 B.1 式(17)，
$\tau^2=\frac{(\lambda_2-\lambda_1)^2}{8}\bigl(\frac1{\lambda_1+s}+\frac1{\lambda_2+s}\bigr)$。
所以当 $\lambda_2-\lambda_1\to0$ 时，距离 $=\sqrt{\mu_{\mathrm R}+s}\,\tau\,(1+o(1))$。

FEM 与 BIE 候选的平方频率差约 $7.85\times10^{-5}$。把它的平方根约 $0.009$ 当作能量误差的量级假设（不是误差证据）。在此假设下，即使通量达到 Prager–Synge 最优，线性界也约为 $0.02$，**达不到 $0.01$**。要越过该结构性障碍，必须引入谱隙信息（第 6 节）。

### D4：零延拓人工端

零延拓场在 $x_\pm$ 的法向导数跳跃是真缺陷，固定 $N=6$ 时与网格无关。I9.4 中端项为 $C_{\mathrm{end}}(g_-+g_+)=0.0073$。独审已指出，仅此一项就给线性 $R\approx0.0162$。在定理 C 下它变为约 $3.1\times0.0073^2=1.6\times10^{-4}$，仍高于 $10^{-4}$。

## 3. 方案总览

$$
\begin{aligned}
&\text{固定原生场 } u_h \xrightarrow{\text{命题 E（可选）}} \tilde u\in V
\xrightarrow{\text{加权 LS（§4.4）}} p
\xrightarrow{\text{定理 B}} \overline\eta_s(m)
\xrightarrow{\text{推论 C3}} \overline\eta_s(\mu_{\mathrm R})\\
&\Longrightarrow
\begin{cases}
\text{无条件：B.1 定理 3（线性）},\\
\text{条件 }\mathrm H^+(c,\lambda_+)\text{：推论 C1（二次）}.
\end{cases}
\end{aligned}
$$

两条输出并列报告，互不替代。条件结论的可靠性等于 $\mathrm H^+$ 的证据强度，见 §6.5。
数值积分的可靠性仍由 B.1 §9 负责，本文不改变该部分。

## 4. 局部化通量界

### 4.1 切线与分片通量

取有限条竖直切线 $t_1<\dots<t_m$。相邻切线围成片 $P_0,\dots,P_m$，首尾两片无界；$P_i=(t_i,t_{i+1})\times I$，约定 $t_0=-\infty$、$t_{m+1}=+\infty$。

设 $p|_{P_i}\in H(\operatorname{div},P_i;\mathbb C^2)$，记分片散度为 $\operatorname{div}p$。假设存在 $j_i\in L^2(I)$，使下列**分片 Green 恒等式**对所有 $v\in V$ 成立：

$$
\int_Bp\cdot\nabla\overline v+\int_B(\operatorname{div}p)\,\overline v
=\sum_{i=1}^m\int_Ij_i(y)\,\overline{v(t_i,y)}\,\mathrm dy.
\tag{G}
$$

$j_i$ 的含义是切线处"左片法向迹减右片法向迹"。(G) 同时包含上下准周期法向条件（B.1 式(8)）的弱形式。

**引理 B0（(G) 的成立条件）。** 下列构造满足 (G)：

1. B.1 §7 的 $X_h$ 通量 $p$ 在 $B_N$ 内、外部 $p=0$、切线取 $x_\pm$。此时 $j$ 等于 B.1 的 $g_\pm$。
2. 在 1 的基础上，于若干胞元墙处另加切线，两侧各用一个曲边 RT2 通量，墙上法向矩不要求相等。
3. 无界片上由命题 E 构造的 Floquet 衰减通量。

**证明。** 第一步：有界曲边单元。每个曲边单元闭包上的 RT2 函数光滑，且 $F_K$ 为双 Lipschitz 映射。对 $v\in H^1(K)$ 有 $\int_K(p\cdot\nabla\overline v+\operatorname{div}p\,\overline v)=\int_{\partial K}p\cdot n\,\overline v$。

第二步：有界片内求和。单元内部边上 RT2 法向迹由共享矩唯一决定，两侧互相抵消。上下配对边满足 $p_y^{\mathrm{top}}=e^{\mathrm i\beta d}p_y^{\mathrm{bot}}$，$\overline v^{\mathrm{top}}=e^{-\mathrm i\beta d}\overline v^{\mathrm{bot}}$，外法向相反，故也抵消。只余切线项。这一步与 B.1 定理 2 的证明相同。

第三步：无界尾片 $(t,\infty)\times I$。设其通量在第 $n$ 个胞元上是 $\sum_jc_j\zeta_j^nP_j(\cdot-n)$，$|\zeta_j|<1$。先对前 $n$ 个胞元求和：内部墙的法向迹由 Floquet 约束连续，项两两抵消，只剩 $x=t$ 与 $x=t+n$ 两项。
- 右端项不超过 $\|p\cdot e_x\|_{L^2(\{t+n\}\times I)}\|v(t+n,\cdot)\|_{L^2(I)}$。前一因子按 $\max_j|\zeta_j|^n$ 衰减。后一因子有界：$v\in H^1(\mathbb R;L^2(I))$，故 $\|v(x,\cdot)\|_{L^2(I)}$ 在 $\mathbb R$ 上有界并趋零。
- 体积分在 $n\to\infty$ 时绝对收敛到全片积分，因为 $p,\operatorname{div}p\in L^2$。

令 $n\to\infty$ 即得。证毕。

### 4.2 曲边单元 Poincaré 常数

**引理 A。** 设 $\widehat K=\{\xi_1,\xi_2\ge0,\ \xi_1+\xi_2\le1\}$，$F_K:\widehat K\to K$ 在闭参考单元上 $C^1$、双射且双 Lipschitz。设 $0<\underline d_K\le\det DF_K\le\overline d_K$，$\|DF_K\|_2\le\overline j_K$。对 $v\in H^1(K)$，令 $c_K(v)=2\int_{\widehat K}v\circ F_K\,\mathrm d\xi$。则

$$
\|v-c_K(v)\|_{L^2(K)}\le C_{P,K}\|\nabla v\|_{L^2(K)},\qquad
C_{P,K}=\frac{\overline j_K}{\pi}\Bigl(\frac{\overline d_K}{\underline d_K}\Bigr)^{1/2}.
\tag{2}
$$

**证明。** 第一步：参考三角形的 Neumann 谱间隙。

令 $Q=(0,1)^2$，$R(x,y)=(1-y,1-x)$ 为关于斜边的反射；$R$ 是保测度等距变换，逐点固定斜边。设 $\varphi\in H^1(\widehat K)$ 为非常数弱 Neumann 特征函数：对所有 $\psi\in H^1(\widehat K)$，$\int\nabla\varphi\cdot\nabla\psi=\lambda\int\varphi\psi$。

在 $\widehat K$ 上令 $\tilde\varphi=\varphi$，在 $R(\widehat K)$ 上令 $\tilde\varphi=\varphi\circ R$。两侧迹在斜边上相同，故 $\tilde\varphi\in H^1(Q)$。

对 $\psi\in H^1(Q)$，分解 $\psi_{\mathrm e}=(\psi+\psi\circ R)/2$、$\psi_{\mathrm o}=(\psi-\psi\circ R)/2$。
- 奇部分：$\nabla\tilde\varphi\cdot\nabla\psi_{\mathrm o}$ 与 $\tilde\varphi\psi_{\mathrm o}$ 在 $R$ 下变号，积分为零。
- 偶部分：$\int_Q\nabla\tilde\varphi\cdot\nabla\psi_{\mathrm e}=2\int_{\widehat K}\nabla\varphi\cdot\nabla\psi_{\mathrm e}=2\lambda\int_{\widehat K}\varphi\psi_{\mathrm e}=\lambda\int_Q\tilde\varphi\psi_{\mathrm e}$。

所以 $\tilde\varphi$ 是 $Q$ 的非常数 Neumann 特征函数。$Q$ 的 Neumann 谱为 $\pi^2(m^2+n^2)$，$m,n\ge0$（余弦可分离基完备），故 $\lambda\ge\pi^2$。

$\widehat K$ 有界 Lipschitz，Rellich 定理给出 Neumann Laplacian 的紧预解式。由谱分解，对均值为零的 $w\in H^1(\widehat K)$ 有 $\|w\|^2\le\pi^{-2}\|\nabla w\|^2$。另外 $\cos\pi x-\cos\pi y$ 是 $R$-偶函数，限制到 $\widehat K$ 即达到 $\pi^2$，但上式不需要这一等号。

第二步：拉回到参考单元。令 $\widehat v=v\circ F_K\in H^1(\widehat K)$，$\widehat c$ 为其参考均值，即 $c_K(v)$。由第一步，

$$
\|v-\widehat c\|_K^2=\int_{\widehat K}|\widehat v-\widehat c|^2\det DF_K
\le\overline d_K\pi^{-2}\int_{\widehat K}|\widehat\nabla\widehat v|^2.
$$

第三步：链式法则。$\widehat\nabla\widehat v=DF_K^{\mathsf T}(\nabla v\circ F_K)$，且 $\mathrm d\xi=\mathrm dx/\det DF_K$。所以

$$
\int_{\widehat K}|\widehat\nabla\widehat v|^2\le\overline j_K^2\,\underline d_K^{-1}\|\nabla v\|_K^2.
$$

合并即得 (2)。证毕。

仿射单元可另用凸域常数 $\operatorname{diam}K/\pi$。该常数有文献来源（见 §11 线索 L5），但本文**不依赖**它。
I9.4 记录的全参考最小 Jacobian 为 $2.09\times10^{-5}$。若个别单元的 $\overline d_K/\underline d_K$ 很大，(2) 会变松；定理 B 的逐元取小机制会在该单元自动改用质量分支。

### 4.3 定理 B

设 $u\in V\setminus\{0\}$，$\mu\in\mathbb R$，$s>0$，通量 $p$ 满足 (G)。设 $\mathcal T$ 为 $B$ 的可数分割，各单元落在某一片内且满足引理 A；离开试探场与通量支撑的区域对残差无贡献，可取任意分割。

对每个单元 $K$，令 $\mathcal R=\operatorname{div}p+\mu\rho u$，并定义

$$
\begin{aligned}
\varepsilon_K&=\|\nabla u-p\|_{L^2(K)},&
\overline{\mathcal R}_K&=|K|^{-1}\textstyle\int_K\mathcal R,\\
\omega_K&=\|\mathcal R-\overline{\mathcal R}_K\|_{L^2(K)},&
\varpi_K&=|\overline{\mathcal R}_K|\bigl(\textstyle\int_K\rho^{-1}\bigr)^{1/2},
\end{aligned}
\tag{3}
$$

$$
\eta_K^2=\min\Bigl\{(\varepsilon_K+C_{P,K}\omega_K)^2+s^{-1}\varpi_K^2,\ \
\varepsilon_K^2+s^{-1}\|\rho^{-1/2}\mathcal R\|_{L^2(K)}^2\Bigr\}.
\tag{4}
$$

**定理 B。** 若 $\sum_K\eta_K^2<\infty$，则

$$
\eta_s(\mu)\le\Bigl(\sum_{K\in\mathcal T}\eta_K^2\Bigr)^{1/2}
+C_{\mathrm{end}}\sum_{i=1}^m\|j_i\|_{L^2(I)}.
\tag{5}
$$

此外，对同一 $p$，(5) 的右端不超过 B.1 式(9)。

**证明。** 第一步：残差分解。由 (G)，

$$
\ell_\mu(v)=\int_B(\nabla u-p)\cdot\nabla\overline v-\int_B\mathcal R\,\overline v
+\sum_i\int_Ij_i\overline{v(t_i,\cdot)}.
$$

两项体积分都绝对可积，可按 $\mathcal T$ 逐元求和。

第二步：单元上的第一分支。$\mathcal R-\overline{\mathcal R}_K$ 在 $K$ 上与常数正交，取引理 A 中的常数 $c_K(v)$：

$$
\Bigl|\int_K(\mathcal R-\overline{\mathcal R}_K)\overline v\Bigr|
=\Bigl|\int_K(\mathcal R-\overline{\mathcal R}_K)\overline{(v-c_K(v))}\Bigr|
\le C_{P,K}\omega_K\|\nabla v\|_K.
$$

均值部分：

$$
\Bigl|\overline{\mathcal R}_K\int_K\overline v\Bigr|
\le\varpi_K\|\rho^{1/2}v\|_K.
$$

于是，令 $N_K(v)^2=\|\nabla v\|_K^2+s\|\rho^{1/2}v\|_K^2$，$\mathbb R^2$ 中的 Cauchy–Schwarz 给出

$$
\Bigl|\int_K(\nabla u-p)\cdot\nabla\overline v-\int_K\mathcal R\overline v\Bigr|
\le(\varepsilon_K+C_{P,K}\omega_K)\|\nabla v\|_K+\varpi_K\|\rho^{1/2}v\|_K
\le\bigl[(\varepsilon_K+C_{P,K}\omega_K)^2+s^{-1}\varpi_K^2\bigr]^{1/2}N_K(v).
$$

第三步：第二分支。同理得 $\le[\varepsilon_K^2+s^{-1}\|\rho^{-1/2}\mathcal R\|_K^2]^{1/2}N_K(v)$。两分支逐元取小即为 $\eta_KN_K(v)$。

第四步：对单元求和。由级数 Cauchy–Schwarz 与 $\sum_KN_K(v)^2=\|v\|_s^2$，体积分部分不超过 $(\sum\eta_K^2)^{1/2}\|v\|_s$。切线项对每条竖线用 B.1 式(12)。除以 $\|v\|_s$、取上确界即得 (5)。

第五步：与 B.1 式(9) 比较。第二分支对 $K$ 求和恰为 B.1 的 $M_s(p)^2$，而逐元取小只会更小；切线项与 B.1 端项相同。证毕。

**注 B1。** (4) 的两个分支对任意 $p$ 都可计算，不需要通量精确平衡，也不需要 Galerkin 正交性。若某种构造使 $\overline{\mathcal R}_K\approx0$，第一分支只为振荡部分付 $C_{P,K}\approx h_K/\pi$ 的权，D1 与 D2 同时消除。均值不为零时由第一分支的 $\varpi_K$ 如实付费。

### 4.4 加权最小二乘通量

由 $(x+y)^2\le(1+\theta)x^2+(1+\theta^{-1})y^2$（任意 $\theta>0$），第一分支有二次上界。对每个单元，**仅依几何**预先固定分支：若 $C_{P,K}\sqrt{s\rho_{\max,K}}\le1$ 用第一分支，否则用第二分支。定义

$$
J_\theta(p)=\sum_{K\in\mathcal T_1}\Bigl[(1+\theta)\varepsilon_K^2+(1+\theta^{-1})C_{P,K}^2\omega_K^2+s^{-1}\varpi_K^2\Bigr]
+\sum_{K\in\mathcal T_2}\Bigl[\varepsilon_K^2+s^{-1}\|\rho^{-1/2}\mathcal R\|_K^2\Bigr]
+\gamma\sum_i\|j_i\|^2,
\tag{6}
$$

并在 B.1 的 $X_h$ 上求最小点；若采用切线，则两侧各用一个空间。$\varepsilon_K,\omega_K,\varpi_K$ 都是 $p$ 的仿射函数的范数，所以 $J_\theta$ 是二次泛函。二次部分不小于 $\min(1,1+\theta)\|p\|^2$，故系统 Hermitian 正定，最小点唯一。

最后**不使用** $J_\theta$ 本身，而对实际最小点计算 (5)，并与 B.1 式(9) 取小。两者都是可靠界，未精确求解或装配不准都不影响有效性（与 B.1 §7.4 同理）。

实现要点如下：

- $\int_K\operatorname{div}\psi=\int_{\partial K}\psi\cdot n$ 只由各边零阶矩决定，是准确的有理组合。所以 $\varpi_K$ 的通量部分不需要求积，只有 $\mu\int_K\rho u$ 需要真实材料积分。
- $\omega_K$ 的 Gram 阵为 $\int_K(\operatorname{div}\psi_j-\overline{\operatorname{div}\psi_j})\overline{(\operatorname{div}\psi_i-\overline{\operatorname{div}\psi_i})}$，仍为单元局部量。每元六个内部矩可以静态消元。
- 与 B.1 式(28) 相比只改权重。系统规模不变：消元后 $43911$ 阶复 Hermitian 正定稀疏系统。
- 默认取 $\theta=1$、$\gamma=2C_{\mathrm{end}}^2$。$s$ 取预先声明的有限集合，例如 $\{\mu_h/2,\mu_h,2\mu_h\}$。对每个 $s$ 分别优化和评价后取最小值；每个值都是有效界，取小合法。

**注 B2（与局部平衡的关系）。** 以顶点 patch 为单位求解局部混合问题，也能得到近乎单元平衡的通量。其相容条件正是对 $P_1$ hat 函数的 Galerkin 方程：$P_1$ hat 属于等参 $P_2$ 空间。这条路线可并行、无全局求解，是加权 LS 的后备。定理 B 对两种通量同样适用，所以本文不依赖局部平衡理论。D2 的失配均值在 patch 层面因插值曲线两侧交替而部分抵消；全局加权 LS 也通过零阶边矩自动利用这一点。这两个判断都是预期，不是定理。

**注 B3（B.1 §7.3 的无权全局优化）。** 无权全局最小化以 Prager–Synge 方式逼近 $\nabla w_s$，能消除 D1。但它保留 D2 地板，约 $0.012$。另外，I9.4 没有运行该优化。定理 B 对其输出也可直接评价。

## 5. Bloch 尾试探函数

### 5.1 构造

以右侧为例。取 lead 胞元墙 $x=t$，满足 $t\in\{1/2,3/2,\dots\}$ 且 $t\le x_+-1$。令 $\mathcal T_c$ 为原 FEM 网格在 $(t,t+1)\times I$ 上的部分。

由 `fem_i9_run.m` 的 `LOCAL_mesh`：所有胞元墙由同一组 $13$ 个网格点及直边中点构成；inclusion 及其 ring 点距墙至少约 $0.086$。所以 $\mathcal T_c$ 左右墙的 $P_2$ 节点在平移 $1$ 后重合。该结论由源码推断，必须在保存网格上有限核验，属 FB-8。

以 $\mathcal T_c$ 的平移拷贝铺满 $(t,\infty)\times I$，在其上取 $y$ 准周期等参 $P_2$ 空间与 FEM 的同一离散形式。离散 Floquet 模态 $\phi$ 满足 $\phi(x+1,y)=\zeta\phi(x,y)$，并在 $x>t$ 的所有节点满足离散方程。

把单胞内部自由度消元后，得到墙迹 $w$ 的二次特征问题：

$$
\bigl(S_{RL}+\zeta(S_{RR}+S_{LL})+\zeta^2S_{LR}\bigr)w=0.
$$

墙自由度数为 $n_w=24$（$25$ 个节点按上下准周期合并）。

**有限条件 (F)。** 恰有 $n_w$ 个乘子满足 $|\zeta_j|<1$，且对应墙迹构成墙迹空间的一组基。Jordan 情形改用广义向量，下文的 Stein 求和同样适用。

(F) 在 $\mu$ 属于两侧 lead 的数值带隙时预期成立，但必须逐例核验。若内部 Dirichlet 消元在该 $\mu$ 处奇异，则另选 $t$。

设 (F) 成立。对 FEM 场在 $x=t$ 的墙迹 $g$，存在唯一系数 $c$ 使 $\sum_jc_j\phi_j|_{x=t}=g$。令

$$
\tilde u=u_h\ (x<t),\qquad \tilde u=\sum_jc_j\phi_j\ (x\ge t),
\tag{7}
$$

左侧同样处理。

**命题 E。** 在 (F) 下，(7) 属于 $V\setminus\{0\}$，且以下各量都由有限胞元数据精确表达：
- $\tilde u$ 在尾部的 $U^2$、$a(\tilde u,\tilde u)$ 贡献；
- 第 $n$ 胞元上 Floquet 通量 $p=\sum_jc_j\zeta_j^nP_j(\cdot-n)$ 的全部 (6) 型二次量。

记 $D=\operatorname{diag}(\zeta_j)$，$G$ 为相应量在单胞上的 Hermitian Gram 阵（模态 $i,j$ 的残差元组内积）。则

$$
\sum_{n\ge0}(D^nc)^*G(D^nc)=c^*Xc,\qquad
X_{ij}=\frac{G_{ij}}{1-\overline{\zeta_i}\zeta_j}.
\tag{8}
$$

**证明。** 第一步：$\tilde u\in V$。尾部第 $n$ 胞元的 $H^1$ 范数不超过 $C\max_j|\zeta_j|^n$，几何级数收敛，故尾部属于 $H^1$。$x=t$ 两侧使用同一组墙节点上的同一 $P_2$ 节点值，迹相同。尾内各墙同理。上下准周期由离散空间保持。非零性由 $x<t$ 部分保持。

第二步：线性结构。在第 $n$ 胞元上 $\nabla\tilde u-p$ 和 $\operatorname{div}p+\mu\rho\tilde u$ 都等于 $\sum_jc_j\zeta_j^n(\cdot)_j$，因为 lead 中的 $\rho$ 以 $1$ 为周期。所以各二次量为 $(D^nc)^*G(D^nc)=\sum_{ij}\overline{c_i}\,\overline{\zeta_i}^nG_{ij}\zeta_j^nc_j$。

第三步：求和。$|\overline{\zeta_i}\zeta_j|<1$，几何级数逐项求和即得 (8)。证毕。

单胞 Floquet 通量 $P_j$ 由单胞版 (6) 求出，约束为"右墙法向矩 $=\zeta_j\times$ 左墙法向矩"及上下相位。该装配映射仍为单射，系统正定。$x=t$ 处作切线，跳跃按 $C_{\mathrm{end}}\|j\|$ 付费。

### 5.2 预期作用（启发式）

离散方程只在 $x=t$ 的墙节点上被破坏。在一维指数模型中，粘接处的导数跳跃约为原人工端跳跃乘 $e^{-\kappa(x_+-t)}$。由 I9.4 端通量粗估 $\kappa\approx0.85$；若取 $x_+-t=3$，该因子约为 $0.08$。

这只是动机：实际多模态与离散效应须由 (5)、(8) 直接评价。$t$ 从预先声明的有限集合中选取，对每个 $t$ 的界都有效，取小合法。尾部模态在 $\mu_h$ 处计算，残差在任意 $m$ 处评价，再由推论 C3 转到 $\mu_{\mathrm R}$。

## 6. 预解式 Temple 二次界

### 6.1 矩恒等式

**引理 C0。** 设 $u\in V\setminus\{0\}$，$s>0$，$\mu+s>0$。则

$$
\int\mathrm d\nu_u=U^2,\quad
\int\lambda\,\mathrm d\nu_u=\mu_{\mathrm R}U^2,\quad
\int\frac{(\lambda-\mu)^2}{\lambda+s}\mathrm d\nu_u=\eta_s(\mu)^2,
$$

$$
\int\frac{\mathrm d\nu_u}{\lambda+s}
=\frac1{\mu+s}\Bigl[U^2-\frac{(\mu_{\mathrm R}-\mu)U^2-\eta_s(\mu)^2}{\mu+s}\Bigr].
\tag{9}
$$

**证明。** 前两式分别来自谱测度总质量与 $u$ 属于形式定义域：$a(u,u)=\int\lambda\,\mathrm d\nu_u$。第三式即 B.1 式(17)，其证明对任意实 $\mu$ 成立。

第四式利用两个恒等式：

$$
\frac1{\lambda+s}=\frac1{\mu+s}\Bigl[1-\frac{\lambda-\mu}{\lambda+s}\Bigr],\qquad
\frac{\lambda-\mu}{\lambda+s}=\frac{(\lambda-\mu)-(\lambda-\mu)^2/(\lambda+s)}{\mu+s}.
$$

它们都是非负谱集上的有界函数或一阶矩，逐项积分即得。证毕。

### 6.2 主定理

**定理 C。** 设 $u\in V\setminus\{0\}$，$s>0$，$\tau=\eta_s(\mu_{\mathrm R})/U$。若实数 $-s<\lambda_-<\mu_{\mathrm R}<\lambda_+$ 满足 $\sigma(A)\cap(\lambda_-,\lambda_+)=\varnothing$，则

$$
(\mu_{\mathrm R}-\lambda_-)(\lambda_+-\mu_{\mathrm R})
\le\frac{(\lambda_-+s)(\lambda_++s)}{\mu_{\mathrm R}+s}\,\tau^2.
\tag{10}
$$

**证明。** 第一步：检验函数。令 $f(\lambda)=(\lambda-\lambda_-)(\lambda-\lambda_+)/(\lambda+s)$。由假设，$\sigma(A)\subset[0,\infty)\setminus(\lambda_-,\lambda_+)$，且 $\lambda+s>0$，故 $f\ge0$ 于 $\sigma(A)$。$\nu_u$ 支撑在 $\sigma(A)$ 上，所以 $\int f\,\mathrm d\nu_u\ge0$。

第二步：部分分式。直接展开验证

$$
f(\lambda)=\lambda-(\lambda_-+\lambda_++s)+\frac{(\lambda_-+s)(\lambda_++s)}{\lambda+s}.
$$

第三步：代入矩。在引理 C0 中取 $\mu=\mu_{\mathrm R}$，(9) 化为 $\int(\lambda+s)^{-1}\mathrm d\nu_u=[U^2+\eta^2/(\mu_{\mathrm R}+s)]/(\mu_{\mathrm R}+s)$，其中 $\eta=\eta_s(\mu_{\mathrm R})$。乘以 $\mu_{\mathrm R}+s>0$，并用
$(\mu_{\mathrm R}-\lambda_--\lambda_+-s)(\mu_{\mathrm R}+s)+(\lambda_-+s)(\lambda_++s)=(\mu_{\mathrm R}-\lambda_-)(\mu_{\mathrm R}-\lambda_+)$，得

$$
0\le(\mu_{\mathrm R}-\lambda_-)(\mu_{\mathrm R}-\lambda_+)U^2
+\frac{(\lambda_-+s)(\lambda_++s)}{\mu_{\mathrm R}+s}\eta^2.
$$

移项并除以 $U^2$ 即 (10)。证毕。

**注 C1。** 令 $T=(A+sI)^{-1}$，$z=(\lambda+s)^{-1}$。(10) 等价于有界算子 $T$ 在区间 $((\lambda_++s)^{-1},(\lambda_-+s)^{-1})$ 上的 Temple 型不等式。

本文直接从 B.1 的恒等式证明，**只要求 $u\in V$**，不要求经典 Temple 不等式所需的 $u\in D(A)$ 与 $\|Au\|$，因此可直接用于 $H^1$ 相容的 FEM 场与零延拓场。

### 6.3 单侧谱隙推论

**推论 C1（上方谱隙）。** 设 $\mathrm H^+(c,\lambda_+)$ 成立：$\sigma(A)\cap(c,\lambda_+)=\varnothing$，其中 $\mu_{\mathrm R}\le c<\lambda_+$。则 $\sigma(A)\cap[0,c]\ne\varnothing$。令 $\lambda_\star=\max\sigma(A)\cap[0,c]$，则有两种情形：
- $\lambda_\star\ge\mu_{\mathrm R}$：此时 $\lambda_\star\in[\mu_{\mathrm R},c]$。
- $\lambda_\star<\mu_{\mathrm R}$：此时

$$
\mu_{\mathrm R}-\lambda_\star\le x_T
:=\frac{(\lambda_++s)\tau^2}{(\lambda_+-\mu_{\mathrm R})+(\lambda_++s)\tau^2/(\mu_{\mathrm R}+s)}
\le\frac{(\lambda_++s)\tau^2}{\lambda_+-\mu_{\mathrm R}}.
\tag{11}
$$

因而 $\sigma(A)\cap[\mu_{\mathrm R}-x_T,c]\ne\varnothing$，且 $\operatorname{dist}(\mu_{\mathrm R},\sigma(A))\le\max\{c-\mu_{\mathrm R},x_T\}$。

**证明。** 第一步：非空性。若 $\sigma(A)\cap[0,c]=\varnothing$，结合 $\mathrm H^+$ 得 $\sigma(A)\cap[0,\lambda_+)=\varnothing$。于是 $\int\lambda\,\mathrm d\nu_u\ge\lambda_+U^2>\mu_{\mathrm R}U^2$，与引理 C0 矛盾。谱为闭集，$[0,c]$ 有界，故最大值存在。

第二步：情形 $\lambda_\star<\mu_{\mathrm R}$。$(\lambda_\star,c]$ 由最大性无谱，$(c,\lambda_+)$ 由 $\mathrm H^+$ 无谱，且 $\lambda_\star\ge0>-s$。对 $(\lambda_\star,\lambda_+)$ 用 (10)，记 $x=\mu_{\mathrm R}-\lambda_\star>0$，并用 $\lambda_\star+s=\mu_{\mathrm R}+s-x$：

$$
x(\lambda_+-\mu_{\mathrm R})\le(\mu_{\mathrm R}+s-x)\frac{(\lambda_++s)\tau^2}{\mu_{\mathrm R}+s}.
$$

整理即得 (11)。证毕。

**推论 C2（下方谱隙）。** 若 $\sigma(A)\cap(\lambda_-,c')=\varnothing$，$-s<\lambda_-<c'\le\mu_{\mathrm R}$，则 $\lambda^\star=\min\sigma(A)\cap[c',\infty)$ 存在。若 $\lambda^\star>\mu_{\mathrm R}$ 且 $\delta_-:=(\mu_{\mathrm R}-\lambda_-)-(\lambda_-+s)\tau^2/(\mu_{\mathrm R}+s)>0$，则 $\lambda^\star-\mu_{\mathrm R}\le(\lambda_-+s)\tau^2/\delta_-$。

**证明。** 第一步：存在性。若 $\sigma(A)\cap[c',\infty)=\varnothing$，则 $\nu_u$ 支撑在 $[0,\lambda_-]$ 上，于是 $\int\lambda\,\mathrm d\nu_u\le\lambda_-U^2<\mu_{\mathrm R}U^2$，矛盾。谱为闭集且有下界，故最小值存在。

第二步：情形 $\lambda^\star>\mu_{\mathrm R}$。对 $(\lambda_-,\lambda^\star)$ 用 (10)，记 $y=\lambda^\star-\mu_{\mathrm R}$，并用 $\lambda^\star+s=\mu_{\mathrm R}+s+y$：

$$
(\mu_{\mathrm R}-\lambda_-)y\le\frac{(\lambda_-+s)(\mu_{\mathrm R}+s+y)}{\mu_{\mathrm R}+s}\tau^2.
$$

把含 $y$ 的项移到左边即得结论。证毕。

**推论 C3（不精确 Rayleigh 商与 FEM 候选）。** 对任意实数 $m$，

$$
\eta_s(\mu_{\mathrm R})\le\eta_s(m)+|\mu_{\mathrm R}-m|\,U s^{-1/2}.
\tag{12}
$$

若已有包围 $\mu_{\mathrm R}\in[\mu_{\mathrm R}^-,\mu_{\mathrm R}^+]$ 及 $U\ge\underline U$，则 (11) 对 $\tau$ 与 $\mu_{\mathrm R}$ 都单调不减，可取 $\overline\tau=\overline\eta_s(\mu_{\mathrm R})/\underline U$ 与 $\mu_{\mathrm R}^+$ 作最坏代入，并取 $c\ge\mu_{\mathrm R}^+$。于是 $\sigma(A)\cap[\mu_{\mathrm R}^--\overline x_T,c]\ne\varnothing$。FEM 候选的 $\operatorname{dist}(\mu_h,\sigma(A))$ 不超过 $\mu_h$ 到该区间最远端点的距离。

**证明。** 第一步：(12)。$\ell_{\mu_{\mathrm R}}-\ell_m=(m-\mu_{\mathrm R})(u,\cdot)_{\mathcal H}$，且 $|(u,v)_{\mathcal H}|\le U\|\rho^{1/2}v\|\le Us^{-1/2}\|v\|_s$。

第二步：单调性。(11) 的分子随 $\tau$ 增；分母中 $\lambda_+-\mu_{\mathrm R}$ 随 $\mu_{\mathrm R}$ 减，$(\lambda_++s)\tau^2/(\mu_{\mathrm R}+s)$ 也随 $\mu_{\mathrm R}$ 减。所以 $x_T$ 对 $\tau$ 与 $\mu_{\mathrm R}$ 都不减。

第三步：区间。由推论 C1，谱点落在 $[\mu_{\mathrm R}-x_T,c]\subset[\mu_{\mathrm R}^--\overline x_T,c]$。证毕。

**注 C2（离散特征值）。** 若另知 $[\mu_{\mathrm R}^--\overline x_T,c]\cap\sigma_{\mathrm{ess}}(A)=\varnothing$，则上述谱点不属于本质谱，即为有限重孤立特征值。这一步只需本质谱信息，不需要排除其他导模，是 FB-4 中可分离的较弱部分。

**注 C3（谱隙信息的必要性）。** §2 D3 的两模态例子表明：没有关于 $(\mu_{\mathrm R},\lambda_+)$ 的信息时，二次界不可能成立。所以 $\mathrm H^+$ 是二次精度的**必要代价**，不是技术性假设。

### 6.4 数值形式与对谱隙参数的敏感性

当 $\tau\ll1$ 时 $x_T\approx F\tau^2$，其中 $F=(\lambda_++s)/(\lambda_+-\mu_{\mathrm R})$。取 $s=\mu_{\mathrm R}\approx2.4288$：

| $\lambda_+$（$k_+=\sqrt{\lambda_+}$） | $F$ | 依据 |
|---|---:|---|
| $4.7852$（$k_+=2.1875$） | $3.06$ | 低于 I9.1 attempt-3 右侧未决来源区间 $[2.1875,2.249]$ |
| $4.0$（$k_+=2.0$） | $4.09$ | 保守 |
| $3.0$（$k_+\approx1.732$） | $9.50$ | 很保守 |
| $2.7225$（$k_+=1.65$） | $17.5$ | 极保守 |

$\lambda_+$ 缩小 $1.6$ 倍，$F$ 只增大约 $3$ 倍，所以结论对 $\lambda_+$ 不敏感。需要的只是候选**上方**一段无谱区间的下界，不是精确带边。

$s$ 的选择：$\tau^2$ 随 $s$ 增大而减小，但通量界中梯度项不随 $s$ 缩小，而 $F$ 随 $s$ 线性增大。所以 $s$ 取预先声明的有限集合，各自评价后取最小 $x_T$。

### 6.5 假设 $\mathrm H^+$ 的内容、现有证据与认证路径

$\mathrm H^+(c,\lambda_+)$ 要求 $(c,\lambda_+)$ 中**既无本质谱也无其他导模**。具体包括：

1. **本质谱。** 归档主线附录 A 论证了 $\sigma_{\mathrm{ess}}(A)=\sigma(A_{-}^{\mathrm{per}})\cup\sigma(A_{+}^{\mathrm{per}})$，并允许左右 lead 不同；其状态为 `established in archived mainline; source review pending`。在此前提下，需要两侧 lead 在 $\beta=0.5$ 的能带在 $(c,\lambda_+)$ 中为空。
   - 现有证据：I9.1 三次 attempt 中两侧在 $k\in[1.45,2.25]$ 的 33 个采样点均为数值 `GAP`，未认证、非连续覆盖。
2. **离散谱。** 需要 $(c,\lambda_+)$ 内无其他导模。
   - I9.1 attempt-3 只有一个内部 dip，右侧 $[2.1875,2.249]$ 为 `BOUNDARY_UNRESOLVED`。
   - I9.3 FEM 在窗口内只交付一个通过局域性门的模式，但声明不保证窗口内谱已穷尽。
   - 这些证据支持 $\lambda_+=4.7852$，但都是数值证据。

因此当前只能交付**条件二次界**：形如"若 $\mathrm H^+(c,4.7852)$ 成立，则 …"，并与无条件线性界并列。按 research AGENTS 的研究深度规则，这是 `important caveat`，不是 blocker：它限制"可靠二次界"的措辞，但不阻止下一项计算。

认证路径均为未来研究，可行性与成本未评估：
- 本质谱部分：对两侧 lead 的 Floquet–Bloch 单胞问题，在全部 $k_x$ 上证明 $(c,\lambda_+)$ 无带。可参考计算机辅助带隙证明（§11 线索 L6），或对 S 矩阵单位模乘子作区间排除。
- 离散谱部分：间隙中的变分特征值包围，如 Lehmann–Goerisch 型方法（§11 线索 L7）。目前没有一项已核验来源可直接套用到两侧不同的周期结构。

## 7. 预期量级（规划用预测，非结果）

$\tau$ 由假设给出，不是数据，各情景仅作规划。端项用 I9.4 实测 $0.0073$，Bloch 尾按 §5.2 的启发式。

| 情景 | 假设 $\tau$ | 无条件线性 $R_s$ | 条件 $x_T$（$\lambda_+=4.7852$） |
|---|---:|---:|---:|
| I9.4 实测（对照） | $0.6706$ | $1.72$ | $1.07$ |
| 加权 LS + 定理 B，零延拓端 | $0.015$–$0.025$ | $0.033$–$0.055$ | $6.9\times10^{-4}$–$1.9\times10^{-3}$ |
| 再加 Bloch 尾 | $0.009$–$0.018$ | $0.020$–$0.040$ | $2.5\times10^{-4}$–$9.9\times10^{-4}$ |
| 再加 $h/2$ FEM 重解（需另行授权） | $0.0025$–$0.005$ | $0.0055$–$0.011$ | $1.9\times10^{-5}$–$7.7\times10^{-5}$ |

各尺度所需的 $\tau$：
- 线性界达到 $0.01$ 需 $\tau\le0.00453$。
- 条件二次界达到 $0.01$ 只需 $\tau\le0.057$；达到 $10^{-4}$ 需 $\tau\le0.0057$。
- 零延拓端单独即给 $\tau\ge0.0073$，所以 $10^{-4}$ 必须先处理 D4。

FEM 候选还需加上 $|\mu_h-\mu_{\mathrm R}|$。它可直接计算，预期在 $10^{-4}$ 附近或更小（失配与积分差），尚未评价。

## 8. 实施路线（须另行授权；本轮不执行）

各步都使用同一冻结的 I9.3 `run-02` 原生场；在第 3 步之前不重解 FEM、不改 $k_h$。资源估计按 `test/AGENTS.md` 的预算口径。

| 步 | 内容 | 输出 | 成本估计 | 停止/判读 |
|---|---|---|---|---|
| 0 | 对 I9.4 保存的通量直接计算定理 B | 单独隔离"加权"效应 | 一次 Q10 积分，约 $1$–$2$ 分钟 | 仅诊断；预期改善有限，因为平均通量不平衡 |
| 1 | 加权 LS 通量（§4.4），零延拓端，$s\in\{\mu_h/2,\mu_h,2\mu_h\}$；计算 $\mu_{\mathrm R}$、$U$、定理 B、B.1 式(9)、推论 C1–C3 | 无条件 $R_s$；$\lambda_+\in\{4.7852,4.0,3.0\}$ 下的条件 $x_T$ | 每个 $s$：装配与 I9.4 Q10 同量级，加一次约 $4.4$ 万阶稀疏正定求解；预计合计不超过 10 分钟，内存低于 1 GiB | 若 $\tau\ge0.1$，则本文诊断不成立，停止并重新诊断；不调参重跑 |
| 2 | Bloch 尾（§5），$t$ 取预声明集合 | 端项替换后的同一组输出 | 单胞二次特征问题（24 阶）及 48 个单胞通量，耗时可忽略 | 若 (F) 失败，记录并保留第 1 步结果 |
| 3 | 若第 2 步后 $\tau$ 由体项主导，且目标为 $10^{-4}$：另行设计 FEM 加密实验 | — | 新实验 | 需新授权 |
| 4 | 认证：B.1 §9 的可靠积分；$\mathrm H^+$ 的证据整理与认证研究 | 结论身份升级 | 研究项 | 未排期 |

**实现自检（建议写入实验设计）：**
1. 同一 $p$ 下，定理 B 的值不超过 B.1 式(9) 的值。
2. Stein 和 (8) 与截断部分和的差随截断长度几何下降。
3. 用有限对角算子与已知谱，对 (10)–(11) 作单元测试。
4. 检查 $\int_K\operatorname{div}\psi$ 与边零阶矩之和的恒等式。
5. 检查左右墙节点平移重合（FB-8）。

## 9. 风险与问题移交

| ID | 分类 | 内容 | 最小后续检查 |
|---|---|---|---|
| FB-6 | important caveat | 二次界依赖 $\mathrm H^+(c,\lambda_+)$；现仅有数值证据 | 第 1 步并列报告无条件与条件结果；认证见 §6.5 |
| FB-7 | important caveat | 加权 LS 的实际 $\tau$ 未知；D1/D2 诊断可能被实测否定 | 第 0–1 步 |
| FB-8 | minor caveat | 胞元墙节点重合与 (F) 由源码推断，未在保存数据上核验 | 有限检查，耗时可忽略 |
| FB-9 | minor caveat | 强曲边单元的 $C_{P,K}$ 可能很大 | 逐元分支取小已兜底；报告使用第二分支的单元数 |
| FB-10 | important caveat | 本文未经独立审查 | 实施前做一次独立审查 |

FB-1、FB-2 不变：可靠积分与精确网格资格仍决定"数值估计"与"可靠界"的措辞。
FB-3 的"未达初步分辨率"仍是 I9.4 的事实；本文只提出新的构造。

## 10. 新增符号

| 符号 | 含义 |
|---|---|
| $\mu_{\mathrm R}$ | 试探函数在真实 $\rho$ 下的 Rayleigh 商 |
| $\ell_\mu,\ \eta_s(\mu)$ | 候选值为 $\mu$ 时的弱残差及其 $\|\cdot\|_s$ 对偶范数 |
| $t_i,\ j_i$ | 竖直切线及其左减右法向通量跳跃 |
| $\mathcal R$ | 通量体缺陷 $\operatorname{div}p+\mu\rho u$ |
| $\varepsilon_K,\omega_K,\varpi_K,\eta_K$ | 定理 B 的逐元梯度差、振荡、均值项及逐元指标 |
| $C_{P,K}$ | 引理 A 的曲边 Poincaré 常数 |
| $J_\theta$ | 加权最小二乘泛函 (6) |
| $\zeta_j,\ \phi_j,\ P_j$ | 离散 Floquet 乘子、模态及其单胞通量 |
| $\lambda_\pm,\ c,\ \mathrm H^+$ | 谱隙端点、候选上方起点及单侧谱隙假设 |
| $\lambda_\star,\ x_T,\ F$ | 最近下方谱点、Temple 半径及其放大因子 |

## 11. 证明记录与文献线索

本文定理（引理 A、B0、C0，定理 B、C，推论 C1–C3，命题 E）由主 agent 从零证明。证明只使用以下标准事实：
- 谱定理与谱测度；
- 有界 Lipschitz 域上 $H(\operatorname{div})$–$H^1$ 的 Green 公式；
- Rellich 紧嵌入；
- 正方形 Neumann 谱（可分离余弦基）；
- 双 Lipschitz 映射下 Sobolev 函数的链式法则；
- B.1 已证的式(12)、(17)。

本文**不依赖**下列任何文献结论。下列文献只作为后续检索线索；**本轮未打开原文核验**，题名、卷期与结果编号以原文为准，DOI 待核验：

- L1：Prager–Synge 超圆（1947），对偶通量能量等式的来源。
- L2：Braess–Schöberl（2008，*Math. Comp.*）；Ern–Vohralík（2015，*SIAM J. Numer. Anal.*）。patch 平衡通量。
- L3：Ainsworth–Vejchodský（2011，*Numer. Math.*）；Cheddadi–Fučík–Prieto–Vohralík（2009，*M2AN*）。反应–扩散问题中 $\min(h/\pi,(s\rho)^{-1/2})$ 型稳健权重。
- L4：Temple（1928，*Proc. R. Soc. A*）；Kato（1949，*J. Phys. Soc. Japan*）。经典二次特征值界。本地 `Kato1995.pdf` 为专著，相关章节本轮未核对。
- L5：Payne–Weinberger（1960，*Arch. Ration. Mech. Anal.*）；Bebendorf（2003，*Z. Anal. Anwend.*）。凸域 Poincaré 常数 $\operatorname{diam}/\pi$。
- L6：Hoang–Plum–Wieners（2009，*Z. Angew. Math. Phys.*）。光子晶体带隙的计算机辅助证明。
- L7：Zimmermann–Mertins（1995，*Z. Anal. Anwend.*）。任意谱结构下（含间隙）的变分特征值包围；Davies–Plum（2004，*IMA J. Numer. Anal.*）。谱污染。

已在 [[research/projects/eig-apost/implementation/i9/r-fem-lit|r-fem-lit]] 核验过的相关来源：
- [[ref/ref_data/Cances2020.pdf|Cancès 等 (2020)]]：特征值簇的可靠后验界需要簇外隔离与紧预解式。这与本文"二次界必须付出谱隙假设"的结论一致，但不能直接套用。
- [[ref/ref_data/Boulton2007.pdf|Boulton–Levitin (2007)]]：二阶谱包含不要求隔离，但仍是线性阶。
- [[ref/ref_data/Chaumont-Frelet2025.pdf|Chaumont-Frelet (2025)]]：人工端通量处理，B.1 已逐条核对。

技能模式：rigorous-proof **Proof from scratch**（新文件，用户授权交付研究文档）；notation-discipline **Writing**。
状态：**Preliminary proof; literature verification is incomplete.** 证明本身不依赖上列线索；
"不完整"指背景线索未核验，以及本文尚未独立审查（FB-10）。

## 12. 实测对照（2026-10-24 追加）

第0–2步已在 [[research/projects/eig-apost/implementation/i9/design-9-5a|I9.5]] 实施，第2步采用有限 Floquet 尾变体（外墙置零）。实测落在 §7 的预测区间内：
- 零延拓：$\tau=0.0118$–$0.0124$，线性界 $0.024$，$x_T=3.9\times10^{-4}$；
- 加 Bloch 尾：$\tau=0.0079$，线性界 $0.0152$，$x_T=1.60\times10^{-4}$。

§4.4 的 $\theta=1$ 加权通量在定理 B 下不如无权通量，所以 §4.4 的权重选择需要修订。本节只记录对照，不改动上文定理及其证明状态。
