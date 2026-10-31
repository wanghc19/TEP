# 第 1 条线论文雏形：导模特征值的二阶保证界

`l1` 指本目录 README 中的"第 1 条线"（FEM + DtN 导模候选的保证误差界）。本文由 Claude 撰写，状态为 **draft**：推导未经独立审查，所有"预计"数字都是用已有记录做的估算，不是计算结果。

## 进度

- 已完成：问题定位（[[stage2-bound-decomposition]]）、$\theta$ 的普通计算（`test/numerical-directions/theta-v1/`）、本雏形初稿。
- 下一步：用户审阅本稿；之后做第 8 节的最小实验。
- 未决：命题 3 的 $Q_1$ 投影部分（TODO）；谱隙认证（第 6 节第 3 点，最难）；文献查新（第 7 节，TODO）。

## 1. 一句话

对 $y$ 周期介质中线缺陷导模的 FEM + DtN 候选，把 FEM 场经正定源问题重构成全条带上的光滑试探场，取它的 Rayleigh 商作为新的中心值，再用两侧 Kato–Temple 不等式给出**二阶**保证区间。在现有数据上，预计区间宽度从 I9.6 的约 $2.4\times10^{-4}$（$\mu$）降到约 $7.5\times10^{-8}$，约窄 3000 倍，并且宽度和实际误差同阶。

## 2. 问题与现状

- **模型**：条带 $B=\mathbb R\times(-1/2,1/2)$，横向 Bloch 相位 $\beta$ 固定；左右为不同的 $x$ 周期 lead，中心为缺陷。算子 $A=-\rho^{-1}\Delta$ 作用在 $\mathcal H=L^2(B,\rho)$ 上，自伴非负。导模特征值 $\lambda$ 位于两侧 lead 本质谱的公共间隙中，下方和上方都有本质谱。记号同 `s-dtn-bound.md`。
- **I9.6 已有的界**（一阶，Weinstein 型）：$\operatorname{dist}(\mu_0,\sigma(A))\le R_\mu$。control 层 $R_\mu=1.21\times10^{-4}$，约为候选实际误差的 210 倍。拆解表明，主因是一阶界线性地支付场的缺陷，而不是某个常数特别差。
- **新发现**：重构场 $w_d$ 的 Rayleigh 商 $\theta$ 离参考值很近，main 层为 $3.8\times10^{-9}$，control 层为 $2.9\times10^{-8}$。原候选 $\mu_0$ 的偏差是 $5.8\times10^{-7}$。

## 3. 算法

输入：FEM + DtN 候选 $(\mu_0,u_h)$，$u_h$ 为有限个胞元上的 FEM 场。

1. **截断与重构**（沿用 I9.6）：$u$ 为 $u_h$ 截断到有限盒子后的 $L^2$ 函数，取 $s>0$，令 $f=(\mu_0\rho+s)u$，$w=L_s^{-1}f$，$L_s=-\Delta+s$。$w$ 属于 $H^2_\beta(B)\subset D(A)$。
2. **有限表示**：$f_d$ 为 $f$ 的分片 $Q_1$ 投影再截断到 $|m|\le M$ 个 Fourier 模式；$w_d=L_s^{-1}f_d$ 在每个模式、每个 $x$ 区间上有闭式（指数加线性），盒外是解析的指数尾。
3. **残差上界**（沿用 I9.6 定理 1、2）：$r_\mu:=\|(A-\mu_0)w\|_{\mathcal H}/\|w\|_{\mathcal H}\le R_\mu$。
4. **Rayleigh 商**：计算 $\theta_d=a(w_d,w_d)/\|w_d\|_{\mathcal H}^2$。分子用能量恒等式，只涉及 Fourier 系数；分母需要在曲边夹杂上积分，theta-v1 已实现。
5. **转移**：由 $\theta_d$ 得到包含精确 Rayleigh 商 $\theta=\theta(w)$ 的区间（命题 2、3）。
6. **两侧 Kato–Temple**：给定认证的 $\alpha<\theta<\beta$，使 $(\alpha,\beta)$ 中至多一个谱点，输出包含区间（命题 1）。

第 1–3 步是 I9.6 已有的；第 4 步已有普通版本；第 5、6 步是新的。

## 4. 需要证明的命题

记 $\eta^2=\|(A-\theta)w\|_{\mathcal H}^2/\|w\|_{\mathcal H}^2$。

**命题 1（两侧 Kato–Temple）。** 设 $w\in D(A)\setminus\{0\}$，$\alpha<\theta<\beta$，$\lambda\in\sigma(A)$，且 $\sigma(A)\cap(\alpha,\beta)=\{\lambda\}$。则

$$\theta-\frac{\eta^2}{\beta-\theta}\le\lambda\le\theta+\frac{\eta^2}{\theta-\alpha}.$$

此外，若 $\eta^2<(\beta-\theta)(\theta-\alpha)$，则 $\sigma(A)\cap(\alpha,\beta)\ne\varnothing$，即谱点的存在性不需要另证。

*证明思路（经典结论，draft）。* 设 $\|w\|_{\mathcal H}=1$，$E$ 为谱测度。对任意 $c$，$\int(t-c)(t-\beta)\,d\|E_tw\|^2=\eta^2+(\theta-c)(\theta-\beta)$，因为 $\int(t-\theta)\,d\|E_tw\|^2=0$。取 $c=\lambda$：由于 $\sigma(A)\cap(\lambda,\beta)=\varnothing$，被积函数在谱上非负，所以 $(\theta-\lambda)(\beta-\theta)\le\eta^2$，得到下界。用 $\alpha$ 同理得到上界。取 $c=\alpha$ 且区间内无谱时，得到 $\eta^2\ge(\beta-\theta)(\theta-\alpha)$，这就是存在性部分。

两个界关于 $\theta$ 单调（只要 $\eta<\beta-\theta$ 且 $\eta<\theta-\alpha$），所以把 $\theta$ 换成其包含区间的端点仍然成立。并且 $\eta^2=r_\mu^2-(\theta-\mu_0)^2\le R_\mu^2-(\theta-\mu_0)^2$，即 I9.6 已有的残差界可以直接使用。

**命题 2（Rayleigh 商转移恒等式）。** 令 $e=w-w_d$，则

$$\bigl(\theta_d-\theta\bigr)\|w_d\|_{\mathcal H}^2
= a(e,e)-\theta\|e\|_{\mathcal H}^2-2\operatorname{Re}\,((A-\theta)w,e)_{\mathcal H}.$$

*证明。* 把 $w_d=w-e$ 代入 $a(w_d,w_d)-\theta\|w_d\|_{\mathcal H}^2$，并用 $a(w,w)=\theta\|w\|_{\mathcal H}^2$ 和 $a(w,e)=(Aw,e)_{\mathcal H}$。

由此

$$-\frac{a(e,e)+2\eta\|w\|_{\mathcal H}\|e\|_{\mathcal H}}{\|w_d\|_{\mathcal H}^2}\le\theta-\theta_d\le\frac{\theta\|e\|_{\mathcal H}^2+2\eta\|w\|_{\mathcal H}\|e\|_{\mathcal H}}{\|w_d\|_{\mathcal H}^2}.$$

一阶项是 $\eta\cdot\|e\|$，两个小量相乘；主要的单侧项是 $a(e,e)$，它是 $e$ 的二次量。

**命题 3（能量范数转移界，TODO）。** 需要可计算的 $a(e,e)$ 上界。由于 $e=L_s^{-1}g$，$g=f-f_d$，有

$$a(e,e)\le(g,L_s^{-1}g)=\sum_m\int\frac{|\hat g_m(\xi)|^2}{\xi^2+a_m^2}\,d\xi .$$

$g$ 分三部分：

- **Fourier 尾**（$|m|>M$）：直接得到 $\le E_y^2/a_{M+1}^2$，其中 $E_y$ 是 I9.6 已算的尾部 $L^2$ 量，$a_{M+1}^2$ 对应记录中的 $b_M$。
- **$Q_1$ 矩形投影误差** $f-\Pi f$：需要一个 $H^{-1}$ 型估计。投影在每个矩形上与常数正交，对偶论证预计给出 $O(h^2)\|f-\Pi f\|_0^2$ 量级。**这是本稿唯一需要新证明的估计。**
- **矩的数值误差**：$\le\|g_{\rm mom}\|_0^2/s$，按记录可以忽略。

$\|e\|_{\mathcal H}\le\sqrt{17}\,\|e\|_0\le\sqrt{17}\,\varepsilon_0$ 已由 I9.6 给出。

**命题 4（谱隙认证）。** 见第 6 节第 3 点，这是开放问题。

## 5. 预期阶数与用现有数字的估算

**阶数。** 设 FEM 场误差为 $\epsilon_h$，则 $R_\mu=O(\epsilon_h)$，候选与 $\theta$ 的实际误差都是 $O(\epsilon_h^2)$。新区间的宽度为

$$O\!\left(\frac{R_\mu^2}{\text{间隙}}\right)+O\bigl(E_y^2/a_{M+1}^2\bigr)+O(R_\mu\varepsilon_0)+(\text{命题 3 的 }Q_1\text{ 投影项}).$$

第一项与实际误差同阶。第二项随 Fourier 截断按 $M^{-3}$ 下降（$E_y\sim M^{-1/2}$，$a_{M+1}\sim M$）。只要 $M$ 按 $\epsilon_h^{-2/3}$ 增长，有效性指数（区间半宽 / 实际误差）就在加密下有界。这正是之前定下的"足够紧"标准；一阶界做不到这一点。

**旁证。** $\theta_d-\mu_{\rm BIE}$ 从 control 到 main 缩小 7.8 倍，与 $M$ 加倍时 $M^{-3}$ 律的 8 倍一致。$\theta_d$ 都在参考值上方，与命题 2 中 $a(e,e)$ 主导、符号单侧也一致。

**估算（control 层，单位为 $\mu$）。** 用的间隙边是：下边 $\alpha=1.3174^2$，取自 17 点轴向扫描，**未认证**；上边 $\beta=2.1875^2$，是**历史假设值**，因为 I9.1 在 $k\in[2.1875,2.249]$ 有未解决的疑似谱点。表中暂不计命题 3 的 $Q_1$ 投影项。

| 项 | 数值 |
|---|---:|
| $\theta_d-\mu_{\rm BIE}$ | $+2.94\times10^{-8}$ |
| 转移：Fourier 尾 $E_y^2/(b_M\|w_d\|_{\mathcal H}^2)$ | $3.68\times10^{-8}$ |
| 转移：一阶项 $2\eta\sqrt{17}\varepsilon_0/\|w_d\|_{\mathcal H}$ | $5.0\times10^{-9}$ |
| Kato–Temple 下侧 $\eta^2/(\beta-\theta)$ | $6.2\times10^{-9}$ |
| Kato–Temple 上侧 $\eta^2/(\theta-\alpha)$ | $2.11\times10^{-8}$ |
| **预计区间** | $[\mu_{\rm BIE}-1.9\times10^{-8},\ \mu_{\rm BIE}+5.7\times10^{-8}]$ |
| 宽度 | $7.5\times10^{-8}$（$k$ 中约 $2.4\times10^{-8}$） |
| I9.6 区间宽度 $2R_\mu$ | $2.42\times10^{-4}$ |

几点说明：

- 预计区间包含参考值，宽度约为原候选实际误差的 1/8。
- 转移的 Fourier 尾项（$3.7\times10^{-8}$）与实测的 $\theta_d$ 偏移（约 $2.9\times10^{-8}$）几乎相等，说明这个上界并不松。
- main 层预计反而更宽（$5.8\times10^{-7}$），因为它的 $R_\mu$ 被矩包含失败拉大了。所以眼下的主瓶颈是 $R_\mu$ 的积分认证，而不是 $M$。

## 6. 三个未决问题的处理方案

1. **main 层 $\theta_d$ 未收敛**：不需要单独处理。$\theta_d$ 与 $\theta(w)$ 的差正是命题 2、3 要包住的量，只需把转移界算出来。若要更窄，就提高 $M$。$\theta_d$ 的计算只需要源系数（control 约 70 MB，main 约 280 MB），比 I9.6 写盘的方式省得多。
2. **$w$ 与 $w_d$ 不是同一个场**：用命题 2、3 解决。我核查过一条看似更省事的捷径：直接对 $w_d$ 求残差，绕开 $u$。这条路不可行。$w_d$ 的强残差含有 $f-f_d$，而间断源 $f$ 的投影误差在 $L^2$ 中只有 $O(M^{-1/2})$，也就是记录里 $E_y\approx0.25$ 那个量级。所以必须保留 I9.6 的"$u-w$ 抵消"结构，再做转移。
3. **谱隙认证**（最难）：
   - 本质谱的边：两侧 lead 在固定 $\beta$ 下的能带边，需要对所有 $x$ 方向准动量取能带的认证上下界，可用 Hoang–Plum–Wieners 的单胞方法（Rayleigh–Ritz 上界加 Goerisch 下界，再加参数覆盖）。
   - 间隙内其他导模的排除：这是真正开放的部分。候选方案有两个：
     - (a) 在一个复频率围道上，对 DtN 约化后的中心问题做认证的零点计数（L3 已显示 DtN 对频率很光滑）。难点是把离散误差也认证进去。
     - (b) 在 $(\alpha,\lambda)$、$(\lambda,\beta)$ 内的若干点上，认证预解式 $(A-z)^{-1}$ 的范数上界（Plum 型）。
   - 第一篇论文可以把"间隙内只有一个谱点"列为**明确的假设**，只认证本质谱的边。这样的界是"在所列条件下成立的上界"。

## 7. 与文献的关系（查新 TODO）

- Brown–Hoang–Plum–Wood 2009：解析宽条模型，用 Weinstein 一阶界，区间与 $\tilde\lambda$ 本身同宽，没有数值场。本稿在同一框架下换用数值试探场和二阶界。
- Hoang–Plum–Wieners 2009、Liu 2015：单胞特征值认证，用于第 6 节第 3 点。
- Cancès 等 2020：有界区域上的保证界，有效性趋于 1；本问题是无界条带加谱隙。
- Kato 1949 的原始 Kato–Temple 不等式未入库。正式引用前要按 `ref/AGENTS.md` 核实；目前可以引用 Kato1995。
- **TODO**：需要查 Plum 组及其他组近年关于"光子晶体波导导模的计算机辅助证明 / 二阶包含"的工作，确认二阶 + FEM 场 + 无界 lead 的组合是否已被做过。

## 8. 演示计划与代价

- **主算例**：本仓库模型。中心星形 $\rho=4$，两侧三叶形 $\rho=17$，$\beta=0.5$。
- **有效性随加密的变化**：至少三个 FEM 层级，例如 refine_i102 的 g12/g24/g48 场，各自走 I9.6 重构，然后算 $\theta_d$、转移、Kato–Temple。主要代价在 I9.6 的源矩认证：每层约 5 分钟、峰值 2.7 GB 内存。存储需要改成流式（本 worktree 限 1 GB），这需要改写重构的存储方式，不改数学。
- **最小下一步实验**（约半小时计算，不含开发）：
  1. 推出命题 3 的 $Q_1$ 投影项并给出数值；
  2. 用区间算术重算 $\theta_d$；
  3. 在"本质谱边与单谱点为假设"的前提下，输出 control 层的完整区间。

**Main risk:** 命题 3 的 $Q_1$ 投影项若比 Fourier 尾大一个量级，区间会相应变宽；不过阶数仍是二次的，结论方向不变。
