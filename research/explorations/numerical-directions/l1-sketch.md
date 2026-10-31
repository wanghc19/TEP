# 第 1 条线论文雏形：导模特征值的二阶保证界

`l1` 指本目录 README 中的"第 1 条线"（FEM + DtN 导模候选的保证误差界）。本文由 Claude 撰写，状态为 **draft**：推导未经独立审查，所有"预计"数字都是用已有记录做的估算，不是计算结果。

## 进度

- 已完成：问题定位（[[stage2-bound-decomposition]]）、$\theta$ 的普通计算（`test/numerical-directions/theta-v1/`）、本雏形初稿。
- 下一步：用户审阅本稿；之后做第 8 节的最小实验。
- 未决：谱隙认证（第 6 节第 3 点，最难）；文献查新（第 7 节，TODO）；命题 3 中 $Q_1$ 投影项的界偏保守，可能需要更紧的估计。
- 2026-10-31 修订：补全命题的假设；证明了原 TODO 的 $Q_1$ 投影项，纳入后预计区间从 $7.5\times10^{-8}$ 变为 $5.1\times10^{-7}$（第 5 节）。

## 1. 一句话

对 $y$ 周期介质中线缺陷导模的 FEM + DtN 候选，把 FEM 场经正定源问题重构成全条带上的光滑试探场，取它的 Rayleigh 商作为新的中心值，再用两侧 Kato–Temple 不等式给出**二阶**保证区间。在现有数据上，预计区间宽度从 I9.6 的约 $2.4\times10^{-4}$（$\mu$）降到约 $5.1\times10^{-7}$，约窄 470 倍。区间宽度随加密按二次律下降是预期，不是已证定理（见第 5 节）。

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

本节供证明审查使用。每条结论标明状态：**本稿证明**、**经典结论（本稿附证明）**、**待证（TODO）**、**假设**。第 1–3、5 节中的"二阶""有效性有界"是预期，不是定理；能作为定理引用的只有本节标为"本稿证明"或"经典结论"的内容。

### 4.0 设定、输入与假设

**设定**（同 `s-dtn-bound.md` §1–2）：
- $\mathcal H=L^2(B,\rho)$，$1\le\rho\le17$；$V=H^1_\beta(B)$。
- $A\ge0$ 是闭形式 $a(v,z)=\int_B\nabla v\cdot\overline{\nabla z}$ 在 $\mathcal H$ 中确定的自伴算子。对 $v\in D(A)$、$z\in V$，有 $a(v,z)=(Av,z)_{\mathcal H}$。
- $L_s=-\Delta+s$ 是未加权 $L^2(B)$ 上的正定准周期实现，$s>0$。其定义域为 $H^2_\beta(B)$，且 $H^2_\beta(B)\subset D(A)$（`s-dtn-bound.md` §2）。$L_s\ge s+\beta^2$，因为 $\min_m q_m^2=\beta^2$。
- $q_m=\beta+2\pi m$，$a_m^2=s+q_m^2$。

**场**：
- $w=L_s^{-1}f$，$w_d=L_s^{-1}f_d$，其中 $f$ 和 $f_d$ 都属于 $L^2(B)$。所以 $w,w_d\in H^2_\beta\subset D(A)$。
- $e=w-w_d=L_s^{-1}g$，$g=f-f_d$。
- 假设 $w\ne0$、$w_d\ne0$。
- $\theta=a(w,w)/\|w\|_{\mathcal H}^2$，$\theta_d=a(w_d,w_d)/\|w_d\|_{\mathcal H}^2$。
- $\eta=\|(A-\theta)w\|_{\mathcal H}/\|w\|_{\mathcal H}$，$r_\mu=\|(A-\mu_0)w\|_{\mathcal H}/\|w\|_{\mathcal H}$。

**来自 I9.6 的输入**（审查只核对引用是否正确，不重审 I9.6 本身）：
- (I1) $r_\mu\le R_\mu$。依据：`s-dtn-bound.md` 式 (7) 给出 $\|(A-\mu_0)w\|_{\mathcal H}=\|\rho^{-1/2}(\mu_0\rho+s)(u-w)\|_0$，这正是式 (8) 第一个不等式的分子；定理 2 的 $R_\mu$ 是式 (8) 右端的上界。
- (I2) $\|w-w_d\|_0\le\varepsilon_0$，并且这里的 $w_d$ 与 theta-v1 计算 $\theta_d$ 所用的是同一个有限场：相同的已存源系数加修正项。theta-v1 重算 $\|w_d\|_0^2$ 时，与 I9.6 的记录一致到 $10^{-15}$。
- (I3) 记号同 `s-dtn-bound.md` §4：$f_R=\Pi_Rf$ 是精确矩的逐矩形 $Q_1$ 投影，$\widetilde f_R$ 是用计算所得矩构造的 $Q_1$ 源，$P_M$ 保留 $|m|\le M$ 的 Fourier 模式，$f_d=P_M\widetilde f_R$。I9.6 给出 $E_y\ge\|(I-P_M)\widetilde f_R\|_0$（式 17）、$\delta_c\ge\|f_R-\widetilde f_R\|_0$（式 15）、$E_R\ge\|f-\widetilde f_R\|_0$，以及 $b_M=\min_{|m|>M}a_m^2$（式 16）。

**假设**：
- (A1) 选定的 $\alpha<\beta$ 使 $\sigma(A)\cap(\alpha,\beta)$ 至多含一个点。本稿不证明它（第 6 节第 3 点）。

### 4.1 命题 1（两侧 Kato–Temple；经典结论，本稿附证明）

设 $w\in D(A)\setminus\{0\}$。

(a) 若 $\lambda\in\sigma(A)$，$\theta<\beta$，且 $\sigma(A)\cap(\lambda,\beta)=\varnothing$，则 $\lambda\ge\theta-\eta^2/(\beta-\theta)$。

(b) 若 $\lambda\in\sigma(A)$，$\theta>\alpha$，且 $\sigma(A)\cap(\alpha,\lambda)=\varnothing$，则 $\lambda\le\theta+\eta^2/(\theta-\alpha)$。

(c) 若 $\alpha<\theta<\beta$ 且 $\eta^2<(\beta-\theta)(\theta-\alpha)$，则 $\sigma(A)\cap(\alpha,\beta)\ne\varnothing$。在 (A1) 下，该交集恰为一点 $\lambda$，它是孤立谱点，因此是特征值，并且 (a)(b) 两个界同时成立。

*证明。* 设 $\|w\|_{\mathcal H}=1$，$\nu(\cdot)=\|E(\cdot)w\|_{\mathcal H}^2$，$E$ 为 $A$ 的谱测度。由 $w\in D(A)$，有 $\int t\,d\nu=\theta$ 和 $\int(t-\theta)^2d\nu=\eta^2$。因此对任意实数 $c,c'$：

$$\int(t-c)(t-c')\,d\nu=\eta^2+(\theta-c)(\theta-c').$$

- (a) 取 $c=\lambda$，$c'=\beta$。在 $\sigma(A)$ 上，要么 $t\le\lambda$，要么 $t\ge\beta$，所以被积函数非负。于是 $(\theta-\lambda)(\beta-\theta)\le\eta^2$。若 $\theta\ge\lambda$，由此得到 (a)；若 $\theta<\lambda$，(a) 显然成立。
- (b) 取 $c=\alpha$，$c'=\lambda$，论证对称。
- (c) 若 $\sigma(A)\cap(\alpha,\beta)=\varnothing$，取 $c=\alpha$，$c'=\beta$，得 $\eta^2\ge(\beta-\theta)(\theta-\alpha)$，与条件矛盾。自伴算子的孤立谱点是特征值。

**推论 1′（用包含区间和上界代入）。** 设 $\theta\in[\theta_-,\theta_+]$，$\eta\le\bar\eta$，且 $\bar\eta<\beta-\theta_+$，$\bar\eta<\theta_--\alpha$。则在 (A1) 和 (c) 的条件下，

$$\theta_--\frac{\bar\eta^2}{\beta-\theta_-}\le\lambda\le\theta_++\frac{\bar\eta^2}{\theta_+-\alpha}.$$

*证明。* $g(t)=t-\bar\eta^2/(\beta-t)$ 在 $\{t<\beta-\bar\eta\}$ 上递增，所以 $\lambda\ge\theta-\eta^2/(\beta-\theta)\ge g(\theta)\ge g(\theta_-)$。上界同理，用 $h(t)=t+\bar\eta^2/(t-\alpha)$ 在 $\{t>\alpha+\bar\eta\}$ 上递增。(c) 的条件可以用 $\bar\eta^2<(\beta-\theta_+)(\theta_--\alpha)$ 来保证。

**引理 1″（残差平移；本稿证明）。** $\eta^2=r_\mu^2-(\theta-\mu_0)^2$，因此在 (I1) 下可取 $\bar\eta^2=R_\mu^2-\min_{t\in[\theta_-,\theta_+]}(t-\mu_0)^2$，最简单的取法是 $\bar\eta=R_\mu$。

*证明。* $(A-\mu_0)w=(A-\theta)w+(\theta-\mu_0)w$，且 $((A-\theta)w,w)_{\mathcal H}=0$，两项正交。

### 4.2 命题 2（Rayleigh 商转移；本稿证明）

在 4.0 的设定下，

$$(\theta_d-\theta)\|w_d\|_{\mathcal H}^2=a(e,e)-\theta\|e\|_{\mathcal H}^2-2\operatorname{Re}\,((A-\theta)w,e)_{\mathcal H}.$$

因而

$$-\frac{a(e,e)+2\eta\|w\|_{\mathcal H}\|e\|_{\mathcal H}}{\|w_d\|_{\mathcal H}^2}\le\theta-\theta_d\le\frac{\theta\|e\|_{\mathcal H}^2+2\eta\|w\|_{\mathcal H}\|e\|_{\mathcal H}}{\|w_d\|_{\mathcal H}^2}.$$

其中：
- $\|e\|_{\mathcal H}\le\sqrt{17}\,\|e\|_0\le\sqrt{17}\,\varepsilon_0$，依据 (I2) 和 $\rho\le17$；
- $\|w\|_{\mathcal H}\le\|w_d\|_{\mathcal H}+\|e\|_{\mathcal H}$；
- $\eta\le\bar\eta$，依据引理 1″；
- 右端的 $\theta$ 用 $\theta\le\mu_0+R_\mu$ 上界。这由引理 1″ 得到：$|\theta-\mu_0|\le r_\mu\le R_\mu$。

*证明。* 记 $\|\cdot\|=\|\cdot\|_{\mathcal H}$，$(\cdot,\cdot)=(\cdot,\cdot)_{\mathcal H}$。

$$a(w_d,w_d)-\theta\|w_d\|^2=\bigl[a(w,w)-\theta\|w\|^2\bigr]-2\operatorname{Re}\bigl[a(w,e)-\theta(w,e)\bigr]+a(e,e)-\theta\|e\|^2 .$$

第一个方括号为零（$\theta$ 的定义）。因为 $w\in D(A)$、$e\in V$，有 $a(w,e)=(Aw,e)$。左端等于 $(\theta_d-\theta)\|w_d\|^2$，恒等式得证。

不等式：由 Cauchy–Schwarz，$|2\operatorname{Re}((A-\theta)w,e)|\le2\eta\|w\|\|e\|$；又 $a(e,e)\ge0$，$\theta\ge0$。分别舍去符号确定的项即可。

### 4.3 命题 3（能量范数转移界；本稿证明）

把 $g$ 写成

$$g=f-P_M\widetilde f_R=\underbrace{(I-P_M)\widetilde f_R}_{g_1}+\underbrace{(f-f_R)}_{g_2}+\underbrace{(f_R-\widetilde f_R)}_{g_3}.$$

记号见 (I3)。记 $\|v\|_{-}:=(v,L_s^{-1}v)_0^{1/2}=\|L_s^{-1/2}v\|_0$（未加权 $L^2$）。则：

- (i) $a(e,e)\le\|g\|_-^2\le\bigl(\|g_1\|_-+\|g_2\|_-+\|g_3\|_-\bigr)^2$。**本稿证明。** 第一步来自 $a(e,e)+s\|e\|_0^2=(L_se,e)_0=(g,L_s^{-1}g)_0$，第二步是 $\|\cdot\|_-$ 的三角不等式。
- (ii) $\|g_1\|_-\le E_y/\sqrt{b_M}$。**本稿证明。** $L_s^{-1}$ 对每个 Fourier 模式对角，第 $m$ 个模式上算子范数 $\le a_m^{-2}$；$g_1$ 只含 $|m|>M$ 的模式。再用 (I3)。
- (iii) $\|g_3\|_-\le\delta_c/\sqrt{s+\beta^2}$。**本稿证明**：由 $L_s\ge s+\beta^2$ 和 (I3) 中的 $\|g_3\|_0\le\delta_c$。
- (iv) $\|g_2\|_-\le c_R'\,E_R$，其中 $c_R'=\sqrt{h_x^2+h_y^2}/\pi$，$E_R\ge\|f-\widetilde f_R\|_0$ 取自 I9.6（`s-dtn-bound.md` §4.2）。**本稿证明**，仿照该文引理 3，只是把对偶空间换成能量空间。

  *证明。* 由对偶，$\|g_2\|_-=\sup_{v}|(g_2,v)_0|/\|L_s^{1/2}v\|_0$，上确界取遍 $v\in H^1_\beta(B)\setminus\{0\}$。$g_2=f-f_R=f-\Pi_Rf$ 支撑于 $D$，并且在每个矩形上与 broken $Q_1$ 正交，所以 $(g_2,v)_0=(g_2,v-\Pi_Rv)_{0,D}$。

  由 $I-\Pi_R=(I-\Pi_x)+\Pi_x(I-\Pi_y)$、$\|\Pi_x\|\le1$，以及区间上的均值零 Poincaré 不等式（分片一次投影的误差不超过分片常数投影的误差，后者 $\le h\|v'\|/\pi$），

  $$\|v-\Pi_Rv\|_{0,D}\le\frac{h_x\|v_x\|_0+h_y\|v_y\|_0}{\pi}\le c_R'\|\nabla v\|_0\le c_R'\|L_s^{1/2}v\|_0 .$$

  最后一步用了 $\|L_s^{1/2}v\|_0^2=\|\nabla v\|_0^2+s\|v\|_0^2$。再用 $\|g_2\|_0=\|f-f_R\|_0\le\|f-\widetilde f_R\|_0\le E_R$：$f_R$ 是 $f$ 在 broken $Q_1$ 中的最佳 $L^2$ 逼近，而 $\widetilde f_R$ 也属于该空间。

  阶数：$E_R=O(h^{1/2})$，因为源在材料界面处间断。所以 $\|g_2\|_-^2=O(h^3)$，与 Fourier 尾的 $O(M^{-3})$ 同阶。

合并：$a(e,e)\le\bigl(E_y/\sqrt{b_M}+c_R'E_R+\delta_c/\sqrt{s+\beta^2}\bigr)^2$，右端全部是 I9.6 已有的量。

### 4.4 谱隙（假设 A1）

见第 6 节第 3 点。本稿把它作为假设，不作为命题。

## 5. 预期阶数与用现有数字的估算

本节都是**预期和估算**，不是定理。

**阶数（预期）。** 设 FEM 场误差为 $\epsilon_h$，则 $R_\mu=O(\epsilon_h)$，候选与 $\theta$ 的实际误差都是 $O(\epsilon_h^2)$。新区间的宽度为

$$O\!\left(\frac{R_\mu^2}{\text{间隙}}\right)+O\bigl(E_y^2/b_M\bigr)+O\bigl(h^2E_R^2\bigr)+O(\delta_c^2)+O(R_\mu\varepsilon_0)+\text{交叉项}.$$

- 第一项与实际误差同阶。
- 第二、三项分别按 $M^{-3}$ 和 $h^3$ 下降：$E_y\sim M^{-1/2}$，$E_R\sim h^{1/2}$。
- 只要 $M^{-3}$、$h^3$ 和积分认证误差都不慢于 $\epsilon_h^2$，有效性指数（区间半宽 / 实际误差）在加密下就有界。这是之前定下的"足够紧"标准；一阶界做不到。

**旁证。** $\theta_d-\mu_{\rm BIE}$ 从 control 到 main 缩小 7.8 倍，与 $M$、$N$ 同时加倍时三次律的 8 倍一致。$\theta_d$ 都在参考值上方，与命题 2 中 $a(e,e)$ 主导、偏移单侧也一致。

**估算（control 层，单位为 $\mu$）。** 用推论 1′ 和命题 2、3 的全部项，$\bar\eta=R_\mu$。间隙边：下边 $\alpha=1.3174^2$，取自 17 点轴向扫描，**未认证**；上边 $\beta=2.1875^2$，是**历史假设值**，因为 I9.1 在 $k\in[2.1875,2.249]$ 有未解决的疑似谱点。

| 项 | 数值 |
|---|---:|
| $\theta_d-\mu_{\rm BIE}$ | $+2.94\times10^{-8}$ |
| $\|g_1\|_-$（Fourier 尾）/ $\|g_2\|_-$（$Q_1$ 投影）/ $\|g_3\|_-$（矩误差） | $3.1\times10^{-4}$ / $7.3\times10^{-4}$ / $6.9\times10^{-5}$ |
| 转移下侧 $a(e,e)/\|w_d\|_{\mathcal H}^2$ | $4.7\times10^{-7}$ |
| 转移一阶项 / 转移上侧 | $5.0\times10^{-9}$ / $6.1\times10^{-9}$ |
| Kato–Temple 下侧 / 上侧 | $6.2\times10^{-9}$ / $2.1\times10^{-8}$ |
| **预计区间** | $[\mu_{\rm BIE}-4.5\times10^{-7},\ \mu_{\rm BIE}+5.7\times10^{-8}]$ |
| 宽度 | $5.1\times10^{-7}$（$k$ 中约 $1.6\times10^{-7}$） |
| I9.6 区间宽度 $2R_\mu$ | $2.42\times10^{-4}$ |

几点说明：

- 预计区间包含参考值，比 I9.6 窄约 470 倍。但宽度与原候选的实际误差（$5.8\times10^{-7}$）相当，相对 $\theta_d$ 自身误差的有效性指数约为 9。
- 主导项是 $Q_1$ 投影项 $\|g_2\|_-$。它的界来自最坏情形的 Poincaré 不等式，实测的 $\theta_d$ 偏移（约 $2.9\times10^{-8}$）比转移下侧界小约 16 倍，所以这个界偏保守。更紧的估计是独立的改进方向，不影响命题的正确性。
- main 层预计宽度为 $9.1\times10^{-7}$，因为它的 $R_\mu$ 和 $\delta_c$ 都被矩包含的片数上限拉大了。如果矩包含修好（$\delta_c\to0$，$R_\mu\approx3.6\times10^{-5}$），main 层转移项降到约 $5.3\times10^{-8}$，Kato–Temple 项降到约 $2\times10^{-9}$。这时区间宽度约 $6\times10^{-8}$，按 $h^3$ 规律下降。

## 6. 三个未决问题的处理方案

1. **main 层 $\theta_d$ 未收敛**：不需要单独处理。$\theta_d$ 与 $\theta(w)$ 的差正是命题 2、3 要包住的量，只需把转移界算出来。若要更窄，就同时提高 $M$ 和 $N$；当前主导的是 $Q_1$ 投影项，也可以先找更紧的估计。$\theta_d$ 的计算只需要源系数（control 约 70 MB，main 约 280 MB），比 I9.6 写盘的方式省得多。
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
  1. 用记录中的 $E_R,E_y,\delta_c$ 按命题 3 给出转移界的数值（无需新计算）；
  2. 用区间算术重算 $\theta_d$；
  3. 在"本质谱边与单谱点为假设"的前提下，输出 control 层的完整区间。

**Main risk:** $Q_1$ 投影项的界保守约一个数量级，当前层级上它让区间宽度和原候选误差相当；要明显优于候选误差，需要更紧的投影项估计或更细的 $h$。
