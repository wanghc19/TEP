# 以有限箱夹逼连续缺陷导模计数

2026-10-30；模式 `Proof from scratch`。本文件将 [[research/explorations/spectral-counting/s-half-gap|HD1–HD2]] 的更强单胞信息转为精确半条带 DtN 的序关系，再对接 [[research/explorations/spectral-counting/minimal_counting_theorem|SC1]]。它不近似旧 FEM/DtN，也不假定小残差已经给出导模。

## 1. 输入、空间与计数对象

固定 $\beta=1/2$，两侧真实周期密度及实际切口沿用 HD1。假设两侧在 $[a,b]$ 的一个开邻域中满足
$\lambda_1^D<a_0<a<b<b_0<\lambda_2^N$。由域包含，$\lambda_1^N\le\lambda_1^D$、$\lambda_2^D\ge\lambda_2^N$，故单胞两种边界问题在该邻域均可逆，且负惯性均为1。

每个单胞的左右墙迹属于 $Y=X\oplus X$，$X=H^{1/2}_\beta(-1/2,1/2)$。$P_C(\mu):Y\to H^1_\beta(C)$ 为给定两墙迹的单胞解；其存在唯一性来自单胞 Dirichlet 正则性。双墙 DtN 二次型为

$$
s_\mu[g]=\int_C\bigl(|\nabla P_C(\mu)g|^2-\mu\rho|P_C(\mu)g|^2\bigr).
\tag{B1}
$$

中心保留完整 $V=H^1_\beta(C_0)$；其精确形式 $t_\mu$、负指数及与全无限算子核的对应同 SC1。不对中心求 Dirichlet 逆。

## 2. 正单胞墙面形式与半条带比较

**引理 BC1。** 对实 $\mu\in[a,b]$，两侧的 $s_\mu$ 都在 $Y$ 上强制，即有 $c_\mu>0$ 满足 $s_\mu[g]\ge c_\mu\|g\|_Y^2$。

**Proof.** 将单胞形式域分解为零墙迹空间及 $P_C(\mu)Y$；弱方程使二者关于能量减质量形式正交，分解是有界同构。零墙迹块和完整 Neumann 形式均恰一负，故墙面形式无负方向。若墙面形式有核，其 Poisson 解满足齐次 Neumann 墙条件，从而给 Neumann 算子零向量；该算子可逆，故墙面核为零。

还需排除趋于零的高频正方向。取 $c>0$，以常系数 $-\Delta+c$ 的单胞 Poisson 映射 $P_c$ 定义 $s_c^0[g]=\int_C(|\nabla P_cg|^2+c|P_cg|^2)$；迹定理与最小延拓使其等价于 $Y$ 范数平方。单胞 Green 恒等式给
$s_\mu(g,h)-s_c^0(g,h)=-\int_C(\mu\rho+c)P_C(\mu)g\,\overline{P_ch}$。
两延拓有界 $Y\to H^1$，且到 $L^2$ 紧，所以经 $s_c^0$ 的 Riesz 同构归一化后为 $I+$ 紧自伴算子。非负且无核即有严格正下界。证毕。

记 $D_\infty(\mu)$ 为该侧精确半条带 DtN，法向从 lead 指向中心。令 $D_L^D(\mu)$、$D_L^N(\mu)$ 为包含 $L$ 个真实单胞的有限 lead 段响应，在远端分别施加 Dirichlet 或 Neumann 条件，近端仍给定迹。它们不是拟合或数值 DtN。

**引理 BC2。** 对所有整数 $L\ge1$，有形式序

$$
0\le D_L^N(\mu)\le D_\infty(\mu)\le D_L^D(\mu).
\tag{B2}
$$

**Proof.** 对连续墙迹序列 $(g_j)_{j\ge0}$，在每个胞元作精确 Poisson 延拓。周期性、迹定理与有界延拓给出
$\sum_j\|g_j\|_X^2<\infty$ 与拼接场的 $H^1$ 控制；固定 $g_0=g$ 时，正二次型
$\sum_{j\ge0}s_\mu(g_j,g_{j+1})$
在其余 $\ell^2(X)$ 变量上强制，故有唯一最小元。Euler 方程正是内部墙通量匹配；拼接解属于 $H^1\cap L^2$，并由 HD1 唯一性等于半条带 Poisson 解。因此该最小值为 $\langle D_\infty g,g\rangle$。

有限 $L$ 项之和的自由末迹最小值为 $D_L^N$，固定 $g_L=0$ 的最小值为 $D_L^D$；内部单胞 Dirichlet 模态已精确消去，并不对原不定体形式取不合法的全域最小值。无限最小元的前 $L$ 项不大于其非负总和，给左侧比较；有限 Dirichlet 最小元在末迹零处接全零序列，给右侧比较。每项非负，故第一不等式成立。证毕。

同一论证允许左 lead 沿相反方向编号；只把单胞双迹的顺序交换，不改变真实材料朝向。固定 $\beta$ 的准周期空间在所有拼接处保持。

## 3. 有限箱的严格计数合同

令 $C_L=(-L-1/2,L+1/2)\times(-1/2,1/2)$，包含原中心及左右各 $L$ 个真实胞元。$F_L^D(\mu)$、$F_L^N(\mu)$ 分别是该有限箱在两外墙为 Dirichlet／Neumann 的完整形式 $\int(|\nabla u|^2-\mu\rho|u|^2)$。令 $n_L^D(\mu),n_L^N(\mu)$ 为其完整连续负惯性，不能用尚未认证的 Galerkin 数代替。

**定理 BC3（有限箱端点夹逼）。** 若在 $e=a,b$ 两端已认证有限箱的两种边界问题可逆，且

$$
n_L^D(e)=n_L^N(e)=r_e, \tag{B3}
$$

则无限中心形式 $t_e$ 可逆，

$$
n_-(t_e)=r_e-2L,\qquad
\operatorname{rank}\mathbf1_{(a,b)}(A)=r_b-r_a. \tag{B4}
$$

**Proof.** 对有限箱，先消去每个 lead 单胞的零墙迹内部空间：每个贡献一个负方向，共 $2L$。其余内部墙变量的形式由 BC1 为正；再消去这些变量只留下完整中心形式
$t_\mu^D=q_{C_0,\mu}+D_{L,-}^D+D_{L,+}^D$
或 $t_\mu^N=q_{C_0,\mu}+D_{L,-}^N+D_{L,+}^N$。这些有界同构均保持形式域，故
$n_L^{D/N}(\mu)=2L+n_-(t_\mu^{D/N})$，可逆性也等价。

BC2 给 $t_e^N\le t_e\le t_e^D$。在 SC1 的共同强制参考内积下，三者均为 $I+$ 紧自伴算子。对有限段，常系数正参考 DtN 的 Fourier 乘子分别为 $\kappa_n\tanh(\kappa_nL)$ 和 $\kappa_n\coth(\kappa_nL)$，与半条带 $\kappa_n$ 的差在归一化后趋零，故紧；真实材料修正再由有界 Poisson 映射和紧 $L^2$ 嵌入给出紧性。(B3) 使两端界算子的负惯性相同，均为 $r_e-2L$，且均可逆。min–max 使中间算子的这些负特征值严格负，其余谱严格正，故 $t_e$ 可逆且负惯性相同。L3 的核同构加 F6 的端点本质谱排除给出 $e\notin\sigma(A)$，即 H4；HD1 已提供 H3，G1 提供 H2。于是 SC1 得到 (B4)。证毕。

BC3 不是直接相减两个无限负指数。所有消去的无限维单胞内部块只有一个负方向；最终相减的是完整中心的有限负指数。它也没有假定中心 Dirichlet 正则。

## 4. 有限箱 Fourier 证书的完整尾界

箱长 $W=2L+1$，沿用 HD1 去掉 $e^{\mathrm i\beta y}$ 的周期 gauge；动能中的横向导数相应为 $\partial_y+\mathrm i\beta$，质量矩不变。Neumann 基为 $c_nW^{-1/2}\cos[n\pi(x+W/2)/W]e^{2\pi\mathrm i m y}$，$n\ge0$；Dirichlet 基为 $(2/W)^{1/2}\sin[n\pi(x+W/2)/W]e^{2\pi\mathrm i m y}$，$n\ge1$。两者取 $n\le N,|m|\le M$，遗漏动能下界

$$
\tau=\min\{[\pi(N+1)/W]^2+\beta^2,
[2\pi(M+1)-\beta]^2\}.
$$

对端点 $e>0$，设 $R=P\rho P$、$R_2=P\rho^2P$、$B=P(-\Delta-e\rho)P$。因为 $\rho\in\{1,4,17\}$，必须分别装配 $R_2$，不能误用两值材料的 $18R-17I$。若 $h=\tau-17e>0$，则精确 Schur 补满足

$$
B-\frac{e^2}{h}(R_2-R^2)\le S\le B. \tag{B5}
$$

这是 $D^{-1}\le h^{-1}I$ 和恒等式 $P\rho Q\rho P=R_2-R^2$ 的直接结果；协方差矩阵真实半正定，不依赖各区间条目看起来为正。若两个有限界矩阵可靠惯性相同且可逆，则完整有限箱可逆且惯性等于该整数，正如 F1 的 min–max 论证。该矩阵值修正保留了低模态的实际耦合，避免把全部方向都减去 $64e^2/h$。

## 5. 真实中心几何与可靠积分

中心不缩放，按当前源码保持五瓣曲线

$$
x(t)=\tfrac3{10}\cos t+\tfrac3{100}(\cos4t+\cos6t),\qquad
y(t)=\tfrac15\sin t+\tfrac3{100}(\sin6t-\sin4t).
\tag{B6}
$$

它等于原参数式 $x=0.2(1.5+0.3\cos5t)\cos t$、$y=0.2(1+0.3\cos5t)\sin t$。令 $f=0.3\cos5t$，则 $xy'-yx'=0.04[(1.5+f)(1+f)+0.5f'\sin t\cos t]\ge0.04(0.84-0.375)>0$；因此曲线绕原点严格正向、无自交。面积由 Green 公式与 Fourier 正交性为 $309\pi/5000$。实际密度中心4，两端17，背景1。

对条带 $|\operatorname{Im}t|\le s$，可取
$H_x=0.3\sinh s+0.03(\sinh4s+\sinh6s)$、
$H_y=0.2\sinh s+0.03(\sinh4s+\sinh6s)$，
$J_x=0.3\cosh s+0.12\cosh4s+0.18\cosh6s$、
$J_y=0.2\cosh s+0.12\cosh4s+0.18\cosh6s$。
Green 积分选择非零 $p$ 分量时，条带模界为
$J_y(2\pi|p|)^{-1}\exp[2\pi(|p|H_x+|q|H_y)]$；选择 $q$ 时相应用 $J_x/(2\pi|q|)$。F3 的梯形余项因而逐矩有效，适用于箱基的有理频率 $p=k/(2W)$。各 lead 矩乘平移相位 $\exp(-2\pi\mathrm i p j)$ 后相加；$R$ 的 inclusion 系数为3或16，$R_2$ 为15或288。Neumann 质量装配用两余弦的和，Dirichlet 用余弦差，均保留 $W^{-1}$ 归一化。

## 6. 不使用梯形积分的材料矩复算

三种曲线都写成有限 Fourier 多项式 $x(t)=\sum a_k\cos kt$、$y(t)=\sum b_k\sin kt$。令 $X(z),Y(z)$ 为相应 Laurent 多项式，$z=e^{\mathrm it}$，$T_y(z)$ 对应 $y'(t)$。在 Green 公式选择 $p\ne0$ 时，有限代数式为

$$
\chi(p,q)=\frac{\mathrm i}{p}
\sum_{j=0}^J\frac{(-2\pi\mathrm i)^j}{j!}
\operatorname{CT}\{T_y(pX+qY)^j\}+E_J,
\quad
|E_J|\le\frac{\sum k|b_k|}{|p|}
\frac{Z^{J+1}}{(J+1)!},
\tag{B7}
$$

其中 $Z=2\pi(|p|\sum|a_k|+|q|\sum|b_k|)$。选择 $q$ 时，前因子换成 $-\mathrm i/q$、$T_y$ 换成 $T_x$、余项前因子换成 $\sum k|a_k|/|q|$。零矩独立由面积 $\pi\sum k a_kb_k$ 计算。

**Proof.** 将实角参数上的指数展开至 $J$ 次，真实相位 Taylor 余项模不超过 $Z^{J+1}/(J+1)!$。对边界导数绝对值用 $\sum k|b_k|$，积分长度为 $2\pi$，再乘 Green 因子 $1/(2\pi|p|)$，得到余项。有限多项式的积分为 $2\pi$ 倍常数项，给出 (B7)。零矩由 $\frac12\int(xy'-yx')$ 和三角正交性得到。证毕。

复算器使用192 bit、$J=96$ 的球多项式计算；它不使用边界节点、条带宽度或梯形余项。重建矩后再做全部区间 LDL。几何积分路径独立，物理模型、矩阵装配和 Arb 后端共享，其独立性范围必须如实陈述。

## 7. 已完成的有限输入

[[test/spectral-counting/box-count-v1/README|实际可靠计算]] 在 $L=3,N=32,M=3$ 时得到
$n_L^D(2.40)=n_L^N(2.40)=6$、
$n_L^D(2.46)=n_L^N(2.46)=7$；上下界矩阵、可靠合同和区间 LDL 全部通过。B7 的独立几何积分重建全部1365个矩后，再次通过全部8个矩阵。独立人工复核§12已接收 BC1–BC3、B5–B6、主程序及实际输出，故精确解析模型的连续导模计数为1。B7复算的后续审查范围以同一复核报告为准。

**Completion report.** Task mode: `Proof from scratch`。Target: 本文新 BC1–BC3 Proof 块及必要定义、矩阵界、真实几何求积、B7复算。Source authority: 当前 SC1、F1–F6、HD1–HD2；无修改既有证明。External references: 仅标准变分、紧嵌入及自伴 Fredholm 基础；所有专门比较步骤在此直接证明。Status: BC1–BC3及实际主证书经独立人工验收§12 PASS，连续计数为1；B7及补充复算经反向终审§13 PASS。模型桥接见 [[research/explorations/spectral-counting/s-model-bridge]]；旧候选误差不由该状态自动解决。
