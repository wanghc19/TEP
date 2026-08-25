# I3.1 全局 lead-aware 连续试验场

本页冻结 I3.1 下一条理论主线，但不授权实验。目标不是证明 finite QZ graph 等于连续
half-guide propagation，而是用 I2 的 wall state 和 one-cell BIE 场数据构造一个明确属于连续
算子定义域的试验场，再让连续 PDE residual 判断该场是否接近真实本征场。

本页与
[[research/projects/eig-apost/phase3-analysis/s-estimator|continuous residual theory]]、
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|exact/numerical DtN boundary]] 和
[[research/projects/eig-apost/phase3-analysis/p-implement|design readiness]] 共同构成下一设计的
theory-to-code contract。

## 1. 连续对象和命名边界

固定 Bloch 参数 $\beta$。设 $B=\mathbb R\times(0,d)$ 是横向 $\beta$-准周期的无限条带，
$\rho$ 是正、有界、沿普通 lead 周期重复的介质参数。连续 Hilbert 空间和算子为

$$
H=L^2(B,\rho\,dx\,dy),
\qquad
A=-\rho^{-1}\Delta,
$$

其中 $A$ 由闭形式

$$
a(u,v)=\int_B\nabla u\cdot\nabla\overline v,
\qquad
V=H^1_\beta(B)
$$

定义。I2 保存的 candidate 为 $\widehat k_h>0$，本页固定
$\mu_h=\widehat k_h^2$。

下文构造的 $u_h^{\mathrm c}$ 称为 **BIE-informed continuous conforming trial**。它是由数值
wall states 和 BIE samples 决定的连续试验函数，不是 exact physical half-guide field，也不把
finite QZ propagation 称为 Fliss 的 exact propagation operator。

## 2. Frozen wall state 和两个 outward 序列

one-cell scattering pencil 使用

$$
A_{\mathrm{sc}}z_n=B_{\mathrm{sc}}z_{n+1},
\qquad
z_n=\begin{bmatrix}a_n\\ b_n\end{bmatrix},
$$

其中 $a_n,b_n\in\mathbb C^K$ 是同一竖直墙上的右行和左行 Rayleigh 系数。记 I2 同一点、
同一 fixed chart 保存的右、左稳定子空间坐标为 $Z_+,Z_-\in\mathbb C^{2K\times K}$。不重新
做 QZ 选择，而在这些 frozen coordinates 中定义

$$
P_+=(B_{\mathrm{sc}}Z_+)^\dagger A_{\mathrm{sc}}Z_+,
\qquad
P_-=(A_{\mathrm{sc}}Z_-)^\dagger B_{\mathrm{sc}}Z_-.
$$

这里 $\dagger$ 表示 full-column-rank least-squares inverse；实现中的反斜杠只有在 rank、条件数
和不变子空间残量通过预注册检查后才可使用。必须分别保存

$$
\|A_{\mathrm{sc}}Z_+-B_{\mathrm{sc}}Z_+P_+\|,
\qquad
\|B_{\mathrm{sc}}Z_--A_{\mathrm{sc}}Z_-P_-\|.
$$

这些量只检查 $P_\pm$ 是否忠实作用于 frozen finite coordinates；即使检查通过，$P_\pm$ 也
仍只参数化试验场，不能升级为连续 half-guide propagation。

取 I2 保存的系数 $c_+,c_-\in\mathbb C^K$。右 lead 的第 $j$ 面墙位于
$x=1/2+j$，左 lead 的第 $j$ 面墙位于 $x=-1/2-j$，并定义

$$
z_j^+=Z_+P_+^jc_+,
\qquad
z_j^-=Z_-P_-^jc_-,
\qquad j=0,1,\ldots.
$$

右侧第 $j$ 个胞元使用左右状态 $(z_j^+,z_{j+1}^+)$；左侧第 $j$ 个胞元的几何左右状态是
$(z_{j+1}^-,z_j^-)$。若 $z=(a,b)^{\mathsf T}$，对应 Fourier Dirichlet 和**全局** $x$ 导数为

$$
d=a+b,
\qquad
p=\partial_xu=\mathrm i\Gamma(a-b),
\qquad
\Gamma=\operatorname{diag}(\gamma_m).
$$

I2 的左 lead 变量 $N_-=-\mathrm i\Gamma(A_--B_-)$ 使用 outward 符号；因此中心左端实际
全局 $x$ 导数是 $-N_-c_-$，不能把 $N_-c_-$ 直接送入 Hermite interpolation。

## 3. One-cell BIE data 只提供内部形状

在 candidate 处重算同一个 one-cell system。记

$$
H_L=-A_{\mathrm{QP}}^{-1}B_L,
\qquad
H_R=-A_{\mathrm{QP}}^{-1}B_R.
$$

右侧胞元的 incoming data 是

$$
a_L=[I,0]z_j^+,
\qquad
b_R=[0,I]z_{j+1}^+,
$$

左侧 canonical 胞元的 incoming data 是

$$
a_L=[I,0]z_{j+1}^-,
\qquad
b_R=[0,I]z_j^-.
$$

密度向量为

$$
\eta=H_La_L+H_Rb_R
=\begin{bmatrix}\tau\\ \zeta\end{bmatrix},
\qquad \zeta=-\sigma.
$$

按当前 Müller convention，障碍外和障碍内的 raw sample fields 分别是

$$
u_{\mathrm e}
=u_{\mathrm{inc}}+D_{\mathrm{QP}}^{(k)}\tau
-S_{\mathrm{QP}}^{(k)}\zeta,
\qquad
u_{\mathrm i}
=D^{(k_{\mathrm i})}\tau-S^{(k_{\mathrm i})}\zeta.
$$

全局 $x$ 导数由同一 potentials 的 target gradients/Hessians 计算。符号和 density coordinates
必须用 value、gradient 和 trace 的独立小测试核对。

当前 sharp-disk 几何是常速圆参数化。此时 one-cell matrix 中的
$D_rA_{\mathrm{raw}}D_c$ scaling 满足

$$
D_r=\sqrt{hR}\,I,
\qquad
D_c=(\sqrt{hR})^{-1}I,
$$

所以两侧标量相消，当前 $H_L,H_R$ 可按上述 physical density convention 解释。设计必须保存
speed spread 和 $D_rD_c-I$ 检查；该 circle-only 条件失败时输出
`DENSITY_REPRESENTATION_UNRESOLVED`，不得把 $H_L,H_R$ 用于物理场采样，也不得把结论推广到
一般轮廓。

## 4. 单一 smooth Fourier--Hermite/bubble trial

raw exterior/interior BIE fields 只作为 shape data。最终 trial 在材料圆内外使用**同一个**函数；
因此不会把离散 BIE 的材料界面 jump 隐藏在 residual 之外。

在一个长度为 $L$ 的普通胞元中令 $t=(x-x_n)/L\in[0,1]$，并令

$$
\psi_m(y)=d^{-1/2}
\exp\!\left(\mathrm i\left(\beta+\frac{2\pi m}{d}\right)y\right).
$$

对每个 retained order，以两端的 $(d_{n,m},p_{n,m})$ 和
$(d_{n+1,m},p_{n+1,m})$ 构造标准 cubic Hermite polynomial
$\mathcal H_m(t)$。再加入预注册的 Legendre bubble family

$$
b_j(t)=t^2(1-t)^2P_{j-1}(2t-1),
\qquad j=1,\ldots,J,
$$

其中 $P_{j-1}$ 是 Legendre polynomial。因 $b_j=b_j'=0$ 于 $t=0,1$，胞元场

$$
u_{n,h}^{\mathrm c}(x,y)
=\sum_m\left(
\mathcal H_m(t)
+\sum_{j=1}^{J}\alpha_{jm}(c_n)b_j(t)
\right)\psi_m(y)
$$

无论 bubble coefficients 如何，都保持 frozen wall value 和 global $x$ derivative。

系数 $\alpha_{jm}(c_n)$ 由一个预先固定、full-rank 的线性 least-squares map 产生：在障碍外
拟合 $u_{\mathrm e},\partial_xu_{\mathrm e}$，在障碍内拟合
$u_{\mathrm i},\partial_xu_{\mathrm i}$。sample grid、value/derivative weight、bubble order、
circle exclusion、rank rule 和 holdout grid 都必须在看结果前冻结；不得按结果调整或做隐藏的
adaptive rank truncation。因为 BIE data 和 least-squares map 都线性依赖 $c_n$，每个胞元场仍是
$c_n$ 的固定线性像。

独立 holdout 只检查 raw BIE shape data 是否被 trial 充分表示。即使 holdout 很小，它也不是
continuous residual；即使 holdout 很大，trial 的 conformity 仍由显式 basis 保证，但结果必须
标为 `BIE_INFORMED_FIT_UNRESOLVED`，不能称其为有物理分辨率的 reconstruction。

中心空列保留 I2 的 Rayleigh field $u_0(q)$，再加唯一的 cubic Hermite correction，使中心两端
的 value/global-$x$-derivative 等于 $z_0^-,z_0^+$ 给出的共同 lead traces。设计必须保存 raw
center field、correction 以及两者的范数比；大 correction 不能被归一化掩盖。

## 5. 为什么 trial 属于 $D(A)$

以下命题是路线成立的核心，而不是对 numerical half-guide 的正确性声明。

**命题。** 假设：

1. 每个胞元使用上节同一个 finite-Fourier polynomial，材料圆内外不分片；
2. 相邻胞元共享 value 和 global $x$ derivative；
3. 中心 correction 也匹配两端的这两组 traces；
4. 两侧胞元的 $H^2$ 范数平方可和。

则拼接场 $u_h^{\mathrm c}\in H^2_\beta(B)\subset D(A)$。

**理由。** finite Fourier basis 同时保证 field 和 $y$ 导数的 Bloch 准周期关系。相邻胞元
共享同一组 finite-Fourier Dirichlet coefficients，所以切向 $y$ 导数也共享；cubic Hermite
end data 再保证一阶 $x$ 导数相同。因此分片 $H^2$ 场拼成全局 $H^2$ 场。
材料圆内外使用同一个 smooth function，故圆上不存在 value 或普通 normal-derivative jump。
这里 $\rho$ 只出现在 $A=-\rho^{-1}\Delta$ 的质量项，不是 principal-part coefficient；因此
不需要人为施加 $\rho$-weighted flux continuity。最后，$\rho$ 有正上下界，故
$-\rho^{-1}\Delta u_h^{\mathrm c}\in H$，这正给出算子定义域归属。

该命题不说明 $u_h^{\mathrm c}$ 接近真本征场。这个问题完全交给下一节的 continuous residual。

## 6. Continuous strong residual

对非零 $u_h^{\mathrm c}\in D(A)$，定义

$$
\eta_{\lambda,h}^2
=\frac{\|(A-\mu_h)u_h^{\mathrm c}\|_H^2}
{\|u_h^{\mathrm c}\|_H^2}
=\frac{\displaystyle
\int_B\rho^{-1}
\left|-\Delta u_h^{\mathrm c}-\mu_h\rho u_h^{\mathrm c}\right|^2}
{\displaystyle\int_B\rho|u_h^{\mathrm c}|^2}.
$$

自伴谱定理给出精确关系

$$
\operatorname{dist}(\mu_h,\sigma(A))\leq\eta_{\lambda,h}.
$$

trial 的 $x$ polynomial 和 $y$ Fourier basis 可直接解析微分。介质积分使用几何拟合分解：先算
$\rho=1$ 的完整 rectangle，再对 disk 加入实际 interior $\rho$ 与 background $\rho=1$ 的 polar
correction。这样不把跨 material jump 的 mask quadrature error 混入 PDE signal。

该谱距离公式对精确积分成立。普通浮点 quadrature convergence 只产生 computed
`CONTINUOUS_RESIDUAL_ESTIMATOR_CANDIDATE`；在 residual numerator 有可靠上界、field norm 有
可靠正下界前，不得称 certified enclosure 或 error upper bound。

## 7. 无限 lead 的 Gram/doubling 求和

对一个胞元的 field norm、strong-residual norm 和 $H^2$ norm，分别存在 Hermitian positive
semidefinite Gram matrix $M_U,M_R,M_2$，使对应平方范数写成 $c_n^*M c_n$。对任一
$M\succeq0$ 定义

$$
W_N(M)=\sum_{r=0}^{N-1}(P^r)^*MP^r.
$$

doubling identities 为

$$
W_{2N}=W_N+(P^N)^*W_NP^N,
\qquad
P^{2N}=(P^N)^2.
$$

若对某个 $N$ 有 $a_N=\|P^N\|_2<1$，则把无限和按每 $N$ 个胞元分块可得

$$
\left\|
\sum_{n=N}^{\infty}(P^n)^*MP^n
\right\|_2
\leq
\frac{a_N^2}{1-a_N^2}\,\|W_N(M)\|_2.
$$

该公式既保留 Jordan coupling，也保留 nonnormal transient growth；不能用逐个
$|\lambda|^n$ 代替。必须对左右两侧以及 $M_U,M_R,M_2$ 分别检查。$M_2$ 的可和性关闭上节
$D(A)$ 条件；$M_U,M_R$ 给出 denominator 和 numerator 的 tail allowances。若
$\mathcal U_{\mathrm{low}}>0$ 是 field squared norm 的下侧值，且
$\mathcal R_{\mathrm{up}}$ 是包括两侧 tail 的 residual squared norm 上侧值，则保守 ratio 使用

$$
\eta_{\lambda,h}^{\mathrm{tail,up}}
=\sqrt{\mathcal R_{\mathrm{up}}/\mathcal U_{\mathrm{low}}}.
$$

浮点实现必须预注册 $1-a_N$ 相对 matrix-power、SVD 和 repeat error 的 margin，同时给
$W_N$ 累加本身的 roundoff/repeat allowance，以及 tail allowance 相对已累加
field/residual signal 的上限。Wood/near-unit、rank failure、nonnormal
power 未达到收缩、nonfinite 或 tail margin 不足时，首个科学失败是
`INFINITE_TAIL_UNRESOLVED`。单个 double 值 $a_N<1$ 不能被写成 rigorous proof。

## 8. 为什么选择这条路线

| 路线 | 连续空间和可得结论 | 当前裁决 |
|---|---|---|
| exact half-guide/DtN extension | exact cell PDE、Cauchy continuity 和 exact propagation 成立时给真实 $H^1$/$D(A)$ tail | 理论基准；当前 exact DtN/P 不可计算，不能把 finite QZ 代入 |
| raw BIE/QZ 逐胞拼接 | retained Fourier modes 的匹配不等于 full trace matching；value jump 未修复时只是 broken field | 只能作 jump/fit 诊断 |
| 全 lead 只用 Rayleigh waves | 只在 homogeneous empty center 满足 PDE | 排除为普通 lead 主线 |
| trace-only Fourier--Hermite | 结构性属于 $D(A)$，实现最短 | 保留为 bubble-order-zero baseline；未利用 one-cell 内部场，可能仍给 $O(1)$ residual |
| raw BIE 加 circle/wall/seam 局部 Cauchy repair | 原理上可得高保真 $D(A)$ field | annulus、collar overlap、连续 trace 和 near-singular quadrature 尚使它过重 |
| 本页 BIE-informed smooth trial | BIE 提供内部形状，显式 basis 保证 conformity，continuous strong residual 独立判定质量 | 下一项 I3.1 的首选路线 |
| broken weak residual | 完整 jump functional 加 conforming companion 后可进入 $V'$ | companion 未给出前只称 partial diagnostic |

本地原文核验支持上述边界：

- [[ref/ref_data/Fliss2013.pdf|Fliss (2013) original]] Theorems 4.1、4.5、4.12 和公式
  (4.9)--(4.10)、(4.16) 使用 exact half-guide BVP、exact cell solutions、Cauchy continuity 和
  spectral radius 小于一的 exact propagation operator；它们不资格化 finite BIE/QZ graph。
- 同文 Theorem 3.5 证明的是连续真本征场的指数衰减，不是任意 numerical tail 的衰减。
- [[ref/ref_data/Hohage2013.pdf|Hohage--Soussi (2013) original]] Theorem 2.2 在其 trace problem
  条件下包含 generalized/Jordan Floquet structure；因此当前 tail 必须保留整个 matrix action，
  不能预设可逐本征向量对角化。
- [[ref/ref_data/Joly2006.pdf|Joly--Li--Fliss (2006) original]] 和
  [[ref/ref_data/Coatleven2012.pdf|Coatléven (2012) original]] 的 Riccati 收缩主结论建立在吸收
  setting；原文把无吸收极限的完整论证留作额外问题，不能直接移植到当前实频率 sharp-disk
  eigenproblem。

## 9. 覆盖、遗漏和设计门

若本页构造及数值门全部通过，strong residual 覆盖：

- 当前 trial 在 background 和 disk 中的完整体方程 defect；
- finite Fourier、finite bubble 和 BIE-fit 不足所造成的 trial error；
- center-to-lead correction；
- frozen $P_\pm$ 产生的整个 infinite-tail field；
- nonnormal transient 和 residual/field tail allowance；
- 实际 $\rho$ jump，而不引入人工 material-interface jump。

仍未自动覆盖或证明：

- raw BIE field 是 exact physical field，或 finite $P_\pm$ 是 exact continuous propagation；
- 普通 quadrature 和 floating-point tail allowance 是 rigorous enclosure；
- 当前 sharp-disk projected essential gap；
- estimator 对 $|k_*-\widehat k_h|$ 的 effectivity；
- unique target identity、convergence order 或无未知常数 upper bound。

对应 [[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]] 必须显式冻结并
在运行前通过：

1. circle-only density scaling、interior/exterior potential signs 和 global-$x$ gradient map；
2. frozen linear bubble fit、rank rule、fit/holdout grids 和 derivative weight；
3. $P_\pm$ 的 frozen-coordinate rank、condition 和 invariance residual；
4. field/residual/$H^2$ Gram、doubling、floating margin 和 two-sided tail accounting；
5. rectangle plus disk-polar geometry-fitted quadrature 和 refinement；
6. center correction、nonzero field、phase/scale invariance 和严格结果命名。

Researcher 与 Engineer 已就上述对象、符号、左右 orientation、失败顺序和资源级别达成一致；
独立 design-only 和 spec-to-code 审查已经通过，六项也已在 `design-3-1b` 逐项冻结。正式
`lead-a3` 已完成：finite input、density representation 和 propagation 通过，但 fixed
BIE-informed holdout fit 在 $J=4/8$ 得到约 $4.522421/5.138028$，高于 $0.20$，故按冻结顺序
停止于 `CONFORMING_RECONSTRUCTION_UNRESOLVED`。center、Gram、tail 与 residual ratio 均为
`NOT_REACHED`。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1b|review-3-1b]]。

初步资源合同是：一次 candidate point、预计 2--15 分钟、峰值 200--400 MiB；优先单入口，
预计 850--1100 行。若超过 1000 行，只允许把 BIE sample/fit 这一科学模块拆出，不为通用化、
provenance 或过度防御增加文件。正式 `lead-a3` 实测用时 $373.254082$ s、peak active-object
memory $62.706804$ MiB；该 snapshot 不等于进程 RSS。由于重构首败，后续 Gram/tail 的资源路径
没有执行。
