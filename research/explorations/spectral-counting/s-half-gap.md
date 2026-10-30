# 半条带 Dirichlet 谱隙的单胞夹逼证书

2026-10-30；模式 `Proof from scratch`。本文件推进 [[research/explorations/spectral-counting/STATUS|G2]]，不从已证明的 bulk gap 推出表面态排除。固定模型与可靠材料矩沿用 [[research/explorations/spectral-counting/s-gap-fourier]]；以下证明针对实际切口 $x=\pm1/2$、首胞中心 $x=\pm1$，不移动切口或改变材料。

## 1. 反射捷径的精确障碍

当前源码 `test/spectral-counting/endpoint-v1/endpoint_inertia.m` 的 `LOCAL_curve` 将所有三叶形保持相同未旋转朝向，`LOCAL_space` 的切口是 $m+1/2$。对 $r_\alpha(t)=r_0(1+\alpha\cos3t)$，竖直反射令 $t\mapsto\pi-t$，从而 $\alpha\mapsto-\alpha$。以切口 $m+1/2$ 为轴，点 $(m+r_0,0)$ 位于中心 $m$ 的 inclusion 内，其反射点 $(m+1-r_0,0)$ 位于中心 $m+1$ 的 inclusion 外，因为

$$
r_0(1-\alpha)<r_0<r_0(1+\alpha),\qquad \alpha>0.
$$

严格不等式给出开集上的材料差异。因此奇延拓后的密度不是原全周期密度，不能嵌入原周期算子的奇子空间。反射只动 $x$，故 $y$ 准周期参数 $\beta$ 会保持；障碍是材料，而非准周期条件。横向反射与复共轭组合可保持固定 $\beta$ 并给 bulk 带对称性，但不固定实际墙上每一点为 Dirichlet 条件，也不修复上述材料差异。这与旧 [[research/explorations/spectral-counting/continuous_vs_discrete_gap#6. 最小 projected gap 证书|反射检查]] 一致。

## 2. 单胞边界问题与半条带定理

令 $C=(-1/2,1/2)\times(-1/2,1/2)$，$\rho=1+16\mathbf1_{D_\alpha}$，$\alpha=3/25$ 或 $1/5$，在 $y$ 方向固定 $\beta=1/2$。在 $L^2(C,\rho)$ 定义两个自伴实现：$A_C^D$ 的形式域为在 $x=\pm1/2$ 零迹的 $H^1_\beta(C)$，$A_C^N$ 的形式域为全部 $H^1_\beta(C)$；二者形式均为 $\int_C|\nabla u|^2$。Neumann 条件是普通 $\partial_x u=0$，不是带密度通量。其紧预解式本征值按重数排列为 $\lambda_j^D,\lambda_j^N$。

**命题 HD1（整胞半条带的夹逼排谱）。** 设实数 $0<a_0<b_0$ 满足

$$
\lambda_1^D<a_0<b_0<\lambda_2^N. \tag{D1}
$$

把同朝向单胞无限串接，并在一个胞元边缘截取任一侧半条带，在截口置 Dirichlet 条件。所得算子 $A_E^D$ 满足

$$
\sigma(A_E^D)\cap[a_0,b_0]=\varnothing. \tag{D2}
$$

对任意 $[a,b]\subset(a_0,b_0)$，还有

$$
\inf_{\mu\in[a,b]}\operatorname{dist}(\mu,\sigma(A_E^D))
\ge\min\{a-a_0,b_0-b\}. \tag{D3}
$$

**Proof.** 先取由 $M$ 个整胞组成的有限条带，在两端置 Dirichlet 条件，算子记为 $A_M$。允许各单胞在内部接口不连续的 Neumann 直和形式域包含其形式域；在每个接口强制零迹的 Dirichlet 直和形式域被其包含。权重与积分都相同，min–max 因此给出

$$
\lambda_M(A_M)\le\lambda_1^D<a_0,
\qquad
\lambda_{M+1}(A_M)\ge\lambda_2^N>b_0. \tag{D4}
$$

这里 Dirichlet 直和中 $M$ 个单胞第一模态构成 $M$ 维试探空间；Neumann 直和在 $\lambda_2^N$ 以下至多 $M$ 个特征值。无需内部接口反射对称，也没有相减两个无限负指数。

为严谨进入半条带，不直接把离散谱收敛当作已证。固定 $\mu\in[a_0,b_0]$，令
$d=\min\{\mu-\lambda_1^D,\lambda_2^N-\mu\}>0$。
对任意 $f\in L^2(E,\rho)$，在前 $M$ 个胞元取 $f_M$，解 $u_M=(A_M-\mu)^{-1}f_M$ 后在外部零延拓。由 (D4)，$\|u_M\|_{L^2(\rho)}\le d^{-1}\|f\|_{L^2(\rho)}$。弱方程给

$$
\|\nabla u_M\|_{L^2}^2
=\mu\|u_M\|_{L^2(\rho)}^2+
\operatorname{Re}(f_M,u_M)_{L^2(\rho)},
$$

因而零延拓序列在半条带的零墙迹 $H^1_\beta$ 空间中一致有界。取弱收敛子列；任一紧支撑测试函数最终位于有限条带内，弱极限 $u$ 满足全半条带方程。由密度性扩展到全部形式测试函数，故 $u\in D(A_E^D)$ 且 $(A_E^D-\mu)u=f$。这给出满射；自伴性使核为值域的正交补，所以核为零。逆的范数由弱下半连续性不超过 $d^{-1}$，证明 (D2)。谱闭且不进入该区间，立即得到 (D3)。左端与右端只在向外计数方向不同，整个证明保持真实单胞朝向不变。证毕。

该判据比 bulk gap 更强，未声称所有 bulk gap 都能由它捕捉；如果单胞边界谱没有足够分隔，则本路线不通过，不推断存在表面态。

## 3. 第一 Dirichlet 模态的显式试探上界

用 $v(x,y)=\sqrt2\cos(\pi x)e^{\mathrm i\beta y}$，其未加权 $L^2$ 范数为1，能量为 $\pi^2+\beta^2$。记真实 inclusion 的 Fourier 矩
$\chi(p,q)=\int_D\exp[-2\pi\mathrm i(px+qy)]$，允许 $p$ 为半整数。则

$$
\lambda_1^D\le R_D:=
\frac{\pi^2+\beta^2}
{1+16\{\pi/25+\operatorname{Re}\chi(1,0)\}}. \tag{D5}
$$

这只用一条相容试探函数，不需要求解 Dirichlet 离散本征问题。可靠验收用分子的上界、分母的正下界，检查 $R_D<a_0$。

## 4. 第二 Neumann 模态的全部补空间控制

在去掉 $e^{\mathrm i\beta y}$ 的周期 gauge 中，用正交基

$$
\psi_{nm}(x,y)=c_n\cos[n\pi(x+1/2)]e^{2\pi\mathrm i m y},
\quad n\ge0,\quad m\in\mathbb Z,\quad
c_0=1,\ c_n=\sqrt2\ (n>0).
$$

取 $0\le n\le N$、$|m|\le M$ 的投影 $P$，维数 $(N+1)(2M+1)$。遗漏动能下界为

$$
\tau_{N,M}=\min\{\pi^2(N+1)^2+\beta^2,
[2\pi(M+1)-\beta]^2\}. \tag{D6}
$$

令 $R=P\rho P$，$B=\operatorname{diag}[(n\pi)^2+(2\pi m+\beta)^2]-b_0R$，

$$
h=\tau_{N,M}-17b_0>0,
\qquad \delta=64b_0^2/h. \tag{D7}
$$

**命题 HD2（Neumann 第二模态的有限见证）。** 若 (D5) 已证明 $R_D<a_0<b_0$，且 $B-\delta I$ 有且只有一个负特征值，其余严格正，则 $\lambda_2^N>b_0$。

**Proof.** Neumann pencil 的遗漏块不小于 $hI$；$\|P\rho Q\|\le8$，所以精确 Schur 补 $S\ge B-\delta I$。min–max 使 $S$ 的第二及其后本征值严格正。Dirichlet 试探函数也属于 Neumann 形式域，且在阈值 $b_0$ 具有严格负能量；完成平方同构使 $S$ 至少有一个负方向。于是完整 pencil 恰一负、无零方向，等价于 $\lambda_1^N<b_0<\lambda_2^N$。定义域保持与 [[research/explorations/spectral-counting/s-gap-fourier|F1]] 相同：有界质量交叉块经正尾逆映入相应 Neumann 算子域。证毕。

真实质量矩可直接由半整数 Fourier 矩装配。定义
$C_k(q)=\operatorname{Re}[\mathrm i^{-k}\chi(k/2,q)]$。
由于本模型关于 $y=0$ 对称，$\chi(p,-q)=\chi(p,q)$、$\chi(-p,q)=\overline{\chi(p,q)}$，故

$$
R_{nm,\ell j}=\mathbf1_{n=\ell,m=j}
+8c_nc_\ell\{C_{n-\ell}(m-j)+C_{n+\ell}(m-j)\}. \tag{D8}
$$

它来自两余弦乘积公式，没有把材料替换为横向平均。F3 的边界积分与 F5 的面积 Taylor 公式对任意实 $p,q$ 均成立，其证明只用实平面波和周期角参数；因此可原样包围所需半整数矩。有限符号可用 F4 的可靠合同或球 LDL；不同方法交叉检查不替代各自余项证明。

## 5. 更宽 bulk gap 与已完成的实例

无需额外计算，单胞形式域 $V_D\subset V_\theta\subset V_N$ 对所有纵向 Floquet 参数均成立；故 (D1) 同时给 $\lambda_1(\theta)<a_0$、$\lambda_2(\theta)>b_0$。本轮同一证书还得到两侧共同 bulk gap $[2.30,2.60]$，不依赖带边位置或参数采样。它保留原 G1 证书，不改写其输入和历史结果。

`test/spectral-counting/half-gap-v1/attempt-1/certify-01.json` 已通过全部有限义务；实际值及复现见 [[test/spectral-counting/half-gap-v1/README]]。[[research/planning/review-3h-20261030#11. G2：反射路线、真实切口与替代夹逼证书|独立复核 §11]] 接收 HD1–HD2、源码及实际输出。两侧 $\lambda_1^D$ 的试探上界分别约2.180746、2.188159，严格小于2.30；25维 Neumann 修正块恰1负，故 $\lambda_2^N>2.60$。于是目标窗内半条带加权预解式范数不超过10，整个距目标闭窗小于 $1/10$ 的复邻域属于预解集；既有 Poisson 公式给精确 DtN 的解析性与实轴自伴性。

这是 G2 的完成，不是中心端点惯性完成。后者可接原 C1；本轮另提出 [[research/explorations/spectral-counting/s-box-count|有限箱夹逼路线]]，其实际输入和复核仍单独验收。

## 6. 执行前合同与证明报告

执行前设置：$a_0=23/10$、$b_0=13/5$，$N=4,M=2$（25维），只算两侧材料矩和两次有限符号；失败时最多 $N=6,M=3$（49维）。预计数秒、0.2 GB以内；30分钟科学硬限，09:10 UTC 更早到达时停止。实际首个可靠配置通过，未扩阶。所有实现与结果放 `test/spectral-counting/half-gap-v1/`，单 attempt、无 MATLAB、无 `.mat`；复用已安装本地 Arb 依赖，不改已验收 G1 程序。

**Completion report.** Mode: `Proof from scratch`。Target: 本文件 §§2–4 的新 Proof 块；标签 HD1、HD2，局部公式 D1–D8。Outside-proof additions: 明确模型、反射障碍、真实矩装配、执行合同及已验收结果，均属于本轮 G2 授权。Existing proofs/code: 不修改。External theorem inputs: 仅形式 min–max、自伴算子的满射／核正交关系及 Hilbert 弱紧性等标准基础；半条带极限步骤已直接证明，没有尚未核验的专门文献作为依赖。Status: 解析判据、实例可靠输入及独立复核均完成，G2 PASS；中心计数另行验收。
