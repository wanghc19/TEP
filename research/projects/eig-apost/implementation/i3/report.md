# I3 阶段总结：用连续 residual 衡量谱距离

## 摘要

I3 的目标是回答一个比 I2 更接近连续偏微分方程的问题：给定数值 candidate
$\widehat k_h$，它离连续波导算子的谱有多远？做法是先用冻结 certificate 定义一个连续
trial $u_h^{\mathrm c}$，再计算它代入弱特征值方程后留下的 residual。Residual 越小，trial
越接近满足未离散化连续算子 $A$ 的某个谱点所对应的特征值方程。

当前接受的 I3.2 经验结果来自
`test/i3/e-cap-v4/output/ecap-v4-a1` 的最终 retry 2：

$$
q_{\mathrm{emp}}=2.8613177944\times10^{-9}.
$$

对应的 nominal $k$ 区间为

$$
[1.8327702838640185,\;1.8327702943522952],
$$

宽度为 $1.0488276692\times10^{-8}<10^{-6}$。四层计算始终评价同一个冻结 trial，并形成
finite empirical cap 和很小的 $q_{\mathrm{emp}}$。这里的“稳定”不表示全部 diagnostics
通过：wall 的四点 full fit 在 search endpoint 无效，只有四个 leave-one-out fits 有效；artifact
还保留 `BOUNDARY_RECOMBINATION_WARNING`。在这些限定下，当前 fixed-trial estimator 已有
较强的经验说服力，I3.2 数值阶段可以结束。

这一结论仍统一标记为 `EMPIRICAL / UNQUALIFIED`。它不是严格误差上界，不是 reliable 或
certified enclosure，也不证明区间内存在离散特征值。

## 1. 谱理论怎样把 residual 转成谱距离

记 $B$ 为整个 line-defect waveguide 的一个横向周期条带，并固定 Bloch 参数 $\beta$。材料
系数 $\rho$ 为正、有界且与零分离。质量空间和能量空间分别为

$$
H=L^2(B,\rho\,\mathrm dx\,\mathrm dy),
\qquad
V=H^1_\beta(B).
$$

$H^1_\beta(B)$ 表示横向满足 $\beta$-准周期条件、且具有平方可积一阶导数的函数。定义刚度型
和质量型

$$
a(u,v)=\int_B\nabla u\cdot\nabla\overline v,
\qquad
b(u,v)=\int_B\rho u\overline v.
$$

它们对应连续广义特征值问题

$$
a(u,v)=\mu b(u,v),
\qquad v\in V,
$$

其中 $\mu=k^2$。等价的连续算子 $A=-\rho^{-1}\Delta$ 是质量空间 $H$ 上的非负自伴算子。
本阶段取

$$
\mu_h=\widehat k_h^2,
\qquad
\gamma=\mu_h>0,
$$

并使用移位能量范数

$$
\|v\|_V^2=a(v,v)+\gamma b(v,v).
$$

对于非零 trial $u_h^{\mathrm c}\in V$，连续 residual 是关于测试函数 $v$ 的连续反线性泛函；
这里 $V'$ 采用复 Hilbert 空间的 anti-dual 约定：

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h b(u_h^{\mathrm c},v),
\qquad v\in V,
$$

所以 $R_h\in V'$。归一化 residual 为

$$
q_h=\frac{\|R_h\|_{V'}}{\|u_h^{\mathrm c}\|_V}.
$$

这一定义同时衡量方程缺陷和 trial 自身大小，避免仅靠缩放 $u_h^{\mathrm c}$ 改变 residual。

严格条件定理使用一个经过证明的上界 $\overline q_h\ge q_h$。若
$\overline q_h<1$，则

$$
J_h^\mu=
\left[
\max\left\{0,
\frac{\mu_h-\overline q_h\gamma}{1+\overline q_h}
\right\},
\frac{\mu_h+\overline q_h\gamma}{1-\overline q_h}
\right]
$$

与未离散化连续算子 $A$ 的谱 $\sigma(A)$ 相交。

这个公式来自有界变换

$$
t(\lambda)=\frac{\lambda-\mu_h}{\lambda+\gamma}.
$$

令 $w=(A+\gamma I)^{1/2}u_h^{\mathrm c}$。谱定理把 normalized residual 写成
$\|t(A)w\|_H/\|w\|_H$，并给出

$$
\operatorname{dist}(0,\sigma(t(A)))\le q_h.
$$

因此 $A$ 至少有一个谱点 $\lambda$ 满足

$$
\frac{|\lambda-\mu_h|}{\lambda+\gamma}\le\overline q_h.
$$

分别解 $\lambda\le\mu_h$ 和 $\lambda\ge\mu_h$ 两种情形，就得到 $J_h^\mu$。直白地说，
residual 不是直接给出普通距离 $|\lambda-\mu_h|$，而是给出按谱能量尺度
$\lambda+\gamma$ 归一化后的距离；区间公式只是把这个归一化不等式解回 $\lambda$。

只有 $\overline q_h$ 的 numerator 是严格 residual 上界、denominator 是严格正的 field-norm
下界时，这个谱包含结论才是 certified。当前 $q_{\mathrm{emp}}$ 只是同一公式的经验输入。

## 2. 连续 trial 和 residual 的完整含义

冻结 certificate 记为 $z_h$。它包含 candidate、QZ state、传播矩阵 $P_\pm$、人工 wall
trace、BIE densities 和 tail 数据，并通过一个固定重构映射定义

$$
u_h^{\mathrm c}=\mathcal T(z_h)\in V.
$$

在一个含材料圆的 cell 中，重构的基础场完全由左 wall、右 wall 和材料圆上的 layer
potentials 给出：

$$
u_h^{\mathrm{lp}}(x)=
\sum_{\Sigma\in\{L,R,\Gamma\}}
\left[D_\Sigma\tau_\Sigma(x)-S_\Sigma\zeta_\Sigma(x)\right].
$$

这里 $D_\Sigma$ 和 $S_\Sigma$ 分别是双层势和单层势，$\tau_\Sigma,\zeta_\Sigma$ 是冻结的
有限 density 所定义的三角插值函数。背景场由全部边界上的 layer potentials 重建，材料圆
内部也使用 transmission layer potentials。不同数值层只更精确地评价同一个
$u_h^{\mathrm{lp}}$，不重新求解 density。

逐 cell 的 $u_h^{\mathrm{lp}}$ 可能在 wall 或材料界面上留下很小的 value defect。用第 4 节的
boundary lifting 消除这些 defects 后，得到全局 conforming companion
$u_h^{\mathrm c}\in V$。因此 $u_h^{\mathrm c}$ 仍完全由冻结 certificate 和全边界
layer-potential trial 决定，但它不是带 value jump 的原始分片场。

$u_h^{\mathrm c}$ 也不是有限 Rayleigh 场。$M=48$ 只表示人工 wall 上 prescribed total
Dirichlet trace 的 Fourier 截断阶数；它不限制材料圆的角向 modes，不限制 cell 内场，也不
限制 residual 的 Fourier 带宽。横向 Bloch seam 已由 $H^1_\beta(B)$ 和准周期 Green kernel
处理，不另产生第四类 residual。

## 3. Residual 为什么分成三项

每个子区域中的 layer-potential 场满足相应的 Helmholtz 方程。把

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h b(u_h^{\mathrm c},v)
$$

逐 cell 分部积分后，区域内部的方程项相消，剩余量来自边界拼接缺陷。

相邻 cell 共用同一条人工 wall。若两侧法向都取各自 cell 的 outward normal，则 wall 上的
Neumann defect 是

$$
j_W=\partial_{n^-}u_h^-+\partial_{n^+}u_h^+.
$$

材料圆内外的 normal transmission defect 同样是采用一致法向约定后的两侧 normal traces
之差；等价地，用各自 outward normals 时写成两者之和。除此以外，wall 和材料圆上的 value
defects 必须由 lifting 修正，而该修正在 $a-\mu_hb$ 下又产生一项 residual。

因此 residual majorant 分为

$$
\|R_h\|_{V'}\le\mathcal M,
\qquad
\mathcal M=B_W+B_\Gamma+B_V.
$$

三项的含义分别是：

- $B_W$ 控制所有人工 wall 上的 Neumann jumps；
- $B_\Gamma$ 控制所有材料圆上的 normal transmission defects；
- $B_V$ 控制为消除 wall 和 circle value defects 而加入的 lifting contribution。

三项对应不同的边界缺陷，分别取范数后再用三角不等式相加。它们不能通过彼此的数值抵消来
制造较小的 majorant。

## 4. 用 shifted $H^{1/2}$ norm 修正 value defects

记冻结 layer-potential 场在左右 wall 上相对于 prescribed shared traces $g_L,g_R$ 的 value
defects 为

$$
a_L=u_h^{\mathrm{lp}}|_{W_L}-g_L,
\qquad
a_R=u_h^{\mathrm{lp}}|_{W_R}-g_R.
$$

在周期长度为 $d$ 的 wall 上，令

$$
a_s(y)=\sum_m a_{s,m}d^{-1/2}e^{\mathrm i\alpha_my},
\qquad
\alpha_m=\beta+\frac{2\pi m}{d},
\qquad s\in\{L,R\}.
$$

定义

$$
\lambda_m^W=\sqrt{\gamma+\alpha_m^2},
\qquad
\|a_s\|_{H^{1/2}_\gamma}^2
=\sum_m\lambda_m^W|a_{s,m}|^2.
$$

材料圆上的 value defect 是

$$
a_\Gamma=u_{\mathrm{out}}|_\Gamma-u_{\mathrm{in}}|_\Gamma.
$$

若圆半径为 $R$，其角向 coefficients 为 $a_{\Gamma,\ell}$，则

$$
\lambda_{\Gamma,\ell}
=\sqrt{\gamma+\frac{\ell^2}{R^2}},
\qquad
\|a_\Gamma\|_{H^{1/2}_\gamma}^2
=\sum_\ell\lambda_{\Gamma,\ell}|a_{\Gamma,\ell}|^2.
$$

对 wall strip 或 circle annulus，trace right inverse $E$ 满足

$$
\|Ea\|_V\le C_E\|a\|_{H^{1/2}_\gamma}.
$$

$C_E$ 的意思是：给定一个边界 value defect，用多少体能量才能把它延拓进相邻区域并消除
jump。Wall 的最小能量 strip 给出

$$
C_{E,W}^2=\coth(\lambda_{\min}^W\delta_W),
\qquad
\lambda_{\min}^W=\min_m\lambda_m^W.
$$

Circle 的 $C_{E,\Gamma}$ 由每个实际保留的角向 mode 的最小能量 annulus extension 得到。本轮
$C_{E,\Gamma}$ 只是 finite-mode empirical constant，不包含未计算的无限角向尾。

所有 value corrections 的能量由

$$
L^2=C_{E,W}^2
\left(\|a_L\|_{H^{1/2}_\gamma}^2+
\|a_R\|_{H^{1/2}_\gamma}^2\right)
+C_{E,\Gamma}^2\|a_\Gamma\|_{H^{1/2}_\gamma}^2
$$

控制。再令

$$
C_A=1+\frac{\mu_h}{\gamma},
\qquad
B_V=C_A L.
$$

旧方法先选一个 cubic profile，把边界 mismatch 延拓成体函数，再估计其二阶 strong-source
residual。结果容易受任意 profile、二阶导数和高频权重影响。新方法直接问“修好这个边界
jump 至少需要多少能量”，所以用 trace right inverse 和 shifted $H^{1/2}$ norm 代替旧 cubic
volume lifting，不再加入旧 strong-source 项。

## 5. 从一个 cell 推广到整个 half-guide

冻结状态在左右 half-guide 中分别由完整矩阵 $P_-$ 和 $P_+$ 传播。若 $c_-$、$c_+$ 是两侧
起始 state，则第 $n$ 个 cell 的 state 为

$$
P_\pm^n c_\pm.
$$

对 $X\in\{W,\Gamma,V\}$，令 $F_{X,\pm}$ 表示该类 residual 在一侧单 cell 中的 boundary
action 和相应 trace weight。该 half-guide 的平方贡献具有形式

$$
\sum_{n\ge0}
\left\|F_{X,\pm}P_\pm^n c_\pm\right\|_2^2.
$$

计算时分成有限段和无限尾：

$$
\sum_{n\ge0}\left\|F_{X,\pm}P_\pm^n c_\pm\right\|_2^2
=
\sum_{n=0}^{J-1}\left\|F_{X,\pm}P_\pm^n c_\pm\right\|_2^2
+
\sum_{n=J}^{\infty}\left\|F_{X,\pm}P_\pm^n c_\pm\right\|_2^2.
$$

前 $J$ 个 cell 使用完整 matrix powers 累加；其余部分使用冻结的 complete-matrix tail
formula。中心 cell 的有限 contribution 另行加入同一平方和。

这里必须保留完整的 $P_\pm$。若 $P_\pm$ 非正规，或者含有 Jordan coupling，不同传播方向
不是彼此正交的独立 modes；有限段可能有暂态放大，尾部也含交叉项。逐特征模套用独立几何级数
会丢掉这些耦合，所以不能替代完整 matrix powers。

## 6. 当前接受的 I3.2 经验结果

最终接受的 artifact 是
`test/i3/e-cap-v4/output/ecap-v4-a1` 的 retry ordinal 2。四层 coupled evaluation 得到

| $N_\Gamma$ | $N_W$ | $B_W$ | $B_\Gamma$ | $B_V$ | $\mathcal M$ |
|---:|---:|---:|---:|---:|---:|
| 1024 | 2048 | $1.8723932\times10^{-10}$ | $4.2948636\times10^{-13}$ | $1.5722713\times10^{-11}$ | $2.0339152\times10^{-10}$ |
| 1280 | 2560 | $1.8723234\times10^{-10}$ | $4.2773644\times10^{-13}$ | $1.8236569\times10^{-11}$ | $2.0589664\times10^{-10}$ |
| 1536 | 3072 | $1.8724084\times10^{-10}$ | $4.2718542\times10^{-13}$ | $2.0575012\times10^{-11}$ | $2.0824304\times10^{-10}$ |
| 2048 | 4096 | $1.8724053\times10^{-10}$ | $4.2895212\times10^{-13}$ | $2.5411873\times10^{-11}$ | $2.1308136\times10^{-10}$ |

同一个固定 trial 的真实 residual 不应随评价网格加密而趋于零；加密的目标是使它的数值评价
趋向一个可能非零的稳定值。主导项 $B_W$ 已基本不变，$B_\Gamma$ 保持同一尺度，$B_V$ 虽有
可见变化但仍是次要项，总 majorant 只从 $2.0339\times10^{-10}$ 变到
$2.1308\times10^{-10}$。按预注册 absolute/GQP floor 规则，circle、value-lifting 和 total
rows 均被标记为 `PLATEAU`。这里的“平台”是经验评价平台，不是严格渐近收敛阶。

Formal artifact 同时记录两项非阻塞诊断：wall 的四点 full fit 在 search endpoint 无效，但四个
leave-one-out fits 有效；另有 `BOUNDARY_RECOMBINATION_WARNING`，最细层 wall
recombination defect 约为 $6.42\times10^{-4}$。因此，下文的“稳定”只表示同一 trial 形成了
finite empirical cap 和很小的 $q_{\mathrm{emp}}$，不表示全部 diagnostics 通过。

拟合、固定 GQP 不确定度、roundoff 和 full-$P$ 数值变化组合得到

$$
\epsilon_M^{\mathrm{emp}}=6.1587987244\times10^{-9}.
$$

经验 companion field-norm candidate 为

$$
N_{\mathrm{comp,lower}}=4.9591014901456401.
$$

因此

$$
q_{\mathrm{emp}}
=\frac{\mathcal M(N_{\max})+\epsilon_M^{\mathrm{emp}}}
{\sqrt{N_{\mathrm{comp,lower}}}}
=2.8613177944\times10^{-9}.
$$

对应的 nominal $k$ 区间为

$$
[1.8327702838640185,\;1.8327702943522952],
$$

宽度为

$$
1.0488276692\times10^{-8}<10^{-6}.
$$

在上述限定下，四层 same-trial evaluation、完整 $P_\pm$ 尾和显式 empirical cap 一致表明：
对当前冻结 trial，$q_{\mathrm{emp}}$ 已经稳定在远小于 $1$ 的量级。继续为了缩小区间而调整
levels、阈值或 trial 已没有 I3.2 阶段的必要性，因此可以结束 I3.2 数值阶段。

## 7. 能说明什么，仍不能说明什么

当前可以接受的结论是：冻结 certificate 定义的全边界 layer-potential trial 具有一个数值
稳定、量级很小的经验 residual estimator，并产生一个很窄的 nominal 谱区间。

当前仍不能接受以下结论：

- $\epsilon_M^{\mathrm{emp}}$ 是严格 residual 上界；
- $N_{\mathrm{comp,lower}}$ 是经过 outward rounding 认证的 field-norm 下界；
- nominal 区间是 reliable 或 certified enclosure；
- 区间内已经证明存在离散特征值；
- 当前 QZ/BIE 链可以充当独立 reference。

后续工作已经分开：

- I3.3 使用独立方法或 reference 检查 estimator 的 effectivity；
- I3.4 构造严格 residual 和 field enclosure，认证 projected essential-spectrum gap，并在满足
  同一连续算子的 gap 条件后证明离散特征值存在。

因此，I3.2 的经验 estimator 可以接受并结束数值阶段，但 reliable enclosure 与谱存在性仍未
完成。最终状态是 `EMPIRICAL / UNQUALIFIED`。

事实来源：[[research/projects/eig-apost/implementation/i3/design-3-2e|I3.2 e-cap-v4 设计]]、
[[research/projects/eig-apost/implementation/i3/review-3-2e|I3.2 e-cap-v4 审查]] 和
[[test/i3/e-cap-v4/output/ecap-v4-a1/report|ecap-v4-a1 最终结果]]。条件性谱包含公式见
[[research/projects/eig-apost/implementation/i3/design-3-2a|I3.2 条件定理设计]]。
