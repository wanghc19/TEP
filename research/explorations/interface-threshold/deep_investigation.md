# 异质接口的阈值共振与弱缺陷分岔

日期：2026-10-28。任务模式：**Proof from scratch**。这是独立理论探索，不是 I10 的新版本，也不改变现有实验的模型、假设或结论。文献地图见 [[research/explorations/interface-threshold/research_landscape]]；候选比较见 [[research/explorations/interface-threshold/candidate_problems]]。

## 1. 本轮究竟建立了什么

最值得继续的问题是：**在左右不同的周期介质之间，弱材料缺陷产生局域态的机制，是否由未扰动接口的阈值共振决定，而不能只由两侧 bulk 带隙决定？**

本轮结果分四层：

| 层级 | 本文内容 | 资格 |
|---|---|---|
| 本轮完整证明 | 命题 1：加权 Helmholtz 的局部 Birman–Schwinger 等价、单调性与有界判据 | 连续算子结论；须满足正文明确假设 |
| 本轮完整证明 | 定理 2：有限秩奇异项决定弱缺陷分岔数及二次尺度 | 条件式连续算子定理；关键局部预解式展开是输入，尚未对一般异质周期端证明 |
| 本轮完整证明 | 定理 3：无限维边界算子经有限核约化后的多通道分岔 | 抽象定理；不把其假设偷换为当前波导的已知事实 |
| 本轮完整证明 | 命题 4：阶跃介质加点相互作用的精确阈值、唯一性与带边规律；§7 三个边界反例 | 最小模型，不是原二维材料问题 |
| 本轮完整证明 | 推论 5：正密度二维分层 Helmholtz 的显式阈值共振、弱增重模态及系数 | 同型连续 PDE 的可分离最小模型，位于谱底边缘；不是一般二维内部 gap |
| 文献已有 | 弱周期缺陷产生谱、有效质量、阈值共振分类、Schur/BS 方法 | 不主张这些机制的原创性 |
| 尚未证明 | 对一般左右异质、分片正材料、固定准周期参数，建立本文需要的有限秩平方根展开并识别其核 | 本方向真正的后续理论任务 |

“本轮证明”指这里给出完整论证，不等于“文献中首次发现”。新颖性只作有检索边界的研究判断。

## 2. 连续对象、扰动与问题边界

取 $L>0$，条带 $B=\mathbb R\times(0,L)$，固定实数 $\beta$，横向准周期条件为

$$
u(x,L)=\mathrm e^{\mathrm i\beta L}u(x,0).
$$

这里 $x$ 是无限延伸并穿过异质接口的方向；固定 $\beta$ 的方向是 $y$。这只是坐标命名，不改变线缺陷问题。令

$$
0<\rho_{\min}\le \rho_0(x,y)\le\rho_{\max}<\infty,
\qquad H=L^2(B,\rho_0\,\mathrm dx\mathrm dy),
\qquad V=H^1_\beta(B).
$$

内积对第一变量线性。非负自伴算子 $A_0$ 由闭形式

$$
a(u,v)=\int_B\nabla u\cdot\overline{\nabla v},\qquad u,v\in V
$$

定义；其作用为 $-\rho_0^{-1}\Delta$，定义域由形式给出，不能把任意 FEM 场视为强定义域元素。在 $|x|>R$，$\rho_0$ 分别等于左右周期材料 $\rho_-$ 和 $\rho_+$，它们可以不同；中心本身也可以已有固定接口结构。

我们**另行研究一个参数族**，不重解释现有 I10 网格：

$$
\rho_\varepsilon=\rho_0+\varepsilon w,
\qquad 0\le w\in L^\infty(B),\qquad
\operatorname{supp}w\subset[-R_1,R_1]\times[0,L],\qquad\varepsilon\ge0.
$$

扰动只改变中心材料质量，不改两侧 bulk。其谱方程是

$$
-\Delta u=\mu(\rho_0+\varepsilon w)u,
\qquad u\in V\cap L^2(B).
\tag{2.1}
$$

式 (2.1) **按弱意义**解释：对所有 $v\in V$，

$$
a(u,v)=\mu\int_B(\rho_0+\varepsilon w)u\overline v.
$$

因此准周期法向导数匹配和材料传输条件已包含在方程中；仅有函数值的准周期约束加内部微分方程不够。由右端属于 $L^2$，该弱等式还保证用于后续 BS 变换的 $u\in D(A_0)$。

取正数 $\mu_*>0$ 与 $\delta>0$，满足

$$
I=(\mu_*-\delta,\mu_*)\subset(0,\infty)\cap\rho(A_0).
\tag{2.2}
$$

注意 (2.2) 比“两侧公共 projected gap”强：未扰动接口在该窗口也不能已有离散本征值。研究的是从上端 $\mu_*$ 向下进入 gap 的新模态。另一边缘、符号改变的扰动、已有接口态移动应另行处理。本文不证明本质谱并集公式，而直接将 (2.2) 作为局部假设；两侧 bulk 谱与接口点谱不可混淆。

设

$$
W u=\frac{w}{\rho_0}u,
\qquad \tau=\sqrt{\mu_*-\mu}>0.
$$

$W:H\to H$ 是有界非负乘法算子。$\varepsilon$ 是扰动强度，$\tau$ 是带边距离的平方根；不使用项目里的 $k$ 表示这两个量。

“阈值共振”在本研究中拟指：$\mu=\mu_*$ 时存在非零的 $H^1_{\mathrm{loc}}$ 准周期解，具有有界带边 Bloch 尾而不是指数增长尾，但不属于 $L^2(B)$。若解本身属于 $L^2$，则是**阈值本征态**，属于另一种奇异结构。最终需用选定的辐射/加权空间精确定义允许的阈值尾；本文不把所有形式上的边界核都自动称为阈值共振。

## 3. 命题 1：正材料质量扰动的 BS 算子

对 $\mu\in I$ 定义

$$
K(\mu)=\mu W^{1/2}(A_0-\mu)^{-1}W^{1/2}:H\longrightarrow H.
\tag{3.1}
$$

**命题 1。** 在 §2 的假设下：

1. $K(\mu)$ 是紧自伴算子，关于 $\mu$ 算子范数解析。
2. 对 $\varepsilon>0$，(2.1) 在 $\mu\in I$ 有非零局域本征函数，当且仅当 $1/\varepsilon$ 是 $K(\mu)$ 的本征值；两者本征空间同构。
3. 在同一 resolvent 窗口 $I$ 内，$K(\mu)$ 按二次型单调增加，并且

$$
K'(\mu)=W^{1/2}A_0(A_0-\mu)^{-2}W^{1/2}\succeq0.
\tag{3.2}
$$

对任何 $W^{1/2}f\ne0$，导数二次型严格为正。
4. 如果 $C_I=\sup_{\mu\in I}\|K(\mu)\|<\infty$，则 $0<\varepsilon<C_I^{-1}$ 时，$I$ 内没有扰动产生的本征值。$C_I=0$ 时所有 $\varepsilon$ 都满足这一无根结论。

### Proof：命题 1

**等价性。** (2.1) 等价于

$$
(A_0-\mu)u=\varepsilon\mu W u.
$$

若 $v=W^{1/2}u=0$，右边为零，(2.2) 给出 $u=0$，矛盾。所以 $v\ne0$ 且 $v=\varepsilon K(\mu)v$。

反之，对 $v=\varepsilon K(\mu)v\ne0$，令

$$
u=\varepsilon\mu(A_0-\mu)^{-1}W^{1/2}v.
$$

则 $u\in D(A_0)$，$W^{1/2}u=v$，并满足原方程。这两个线性构造互逆，保留几何重数；自伴连续算子的本征值没有 Jordan 链。权重 $\rho_\varepsilon$ 与 $\rho_0$ 等价，局域性和 $L^2$ 资格不因采用固定空间 $H$ 改变。

**紧性。** 对有界输入，$u=(A_0-\mu)^{-1}f$ 在 $H$ 与形式范数中有界，且 $-\Delta u=\rho_0(f+\mu u)\in L^2$。由局部 Laplace 正则性，$u$ 在包含 $\operatorname{supp}w$ 的有限条带上有界于 $H^2_{\mathrm{loc}}$（跨 $y=0,L$ 用准周期延拓）。局部 Rellich 紧嵌入给出 $W^{1/2}(A_0-\mu)^{-1}:H\to H$ 紧。这里材料在零阶权重中；若改成 TE 的不连续主系数，不能原样复用此 $H^2$ 论证。乘上有界的另一个 $W^{1/2}$ 仍紧。自伴性与解析性由 resolvent 和实数 $\mu$ 直接得到。

**导数与严格性。** 令 $R=(A_0-\mu)^{-1}$。由 $R'=R^2$，

$$
R+\mu R^2=A_0R^2.
$$

因此 (3.2) 成立。谱定理给

$$
\langle K'(\mu)f,f\rangle
=\int_{[0,\infty)}\frac{\lambda}{(\lambda-\mu)^2}
\,\mathrm d\|E_{A_0}(\lambda)W^{1/2}f\|^2.
$$

$\ker A_0=\{0\}$：零能量使梯度为零，常数不属于无限条带的 $L^2$。于是 $W^{1/2}f\ne0$ 时上述积分严格正。沿实参数积分即可得到单调性；无需错误地假定内部 gap 中的 $R$ 正定。

**无根判据。** 若 $\varepsilon C_I<1$，则 $\|\varepsilon K(\mu)\|<1$，所以 $I-\varepsilon K(\mu)$ 可逆，等价性排除本征值。证毕。

### 这个命题解决与未解决的事

这是标准 BS 思想在当前加权质量扰动上的直接证明。因子 $\mu$ 不能省略；它还使 (3.2) 的单调性由 $A_0\ge0$ 自然出现。它没有证明 $C_I$ 有限。虽然 $\|(A_0-\mu)^{-1}\|$ 通常在带边发散，局部压缩 $W^{1/2}(A_0-\mu)^{-1}W^{1/2}$ 可能保持有界；这正是需要研究接口匹配的地方。

## 4. 定理 2：局部预解式奇异秩与新生模态数

**定理 2。** 在命题 1 的设定下，另假设存在有限秩非负自伴算子 $G:H\to H$、常数 $M<\infty$ 和 $\tau_0>0$，使

$$
K(\mu_*-\tau^2)=\frac{G}{\tau}+E(\tau),
\qquad \|E(\tau)\|\le M,
\quad 0<\tau\le\tau_0,
\quad [\mu_*-\tau_0^2,\mu_*)\subset I.
\tag{4.1}
$$

$E(\tau)$ 在 $\tau>0$ 连续；不要求它本身单调。设 $G$ 的正本征值按非增次序为 $g_1\ge\cdots\ge g_r>0$，计重数。

- 若 $r=0$，充分小的正 $\varepsilon$ 不在该窗口产生本征值。
- 若 $r>0$，对充分小的正 $\varepsilon$，该窗口中恰有 $r$ 个扰动本征值（按本征空间维数累计），其参数可配对使

$$
\tau_j(\varepsilon)=\varepsilon g_j+O(\varepsilon^2),
\qquad
\mu_j(\varepsilon)=\mu_*-\varepsilon^2g_j^2+O(\varepsilon^3).
\tag{4.2}
$$

这里“恰有”是对这个固定小窗口而言，不能外推到整个公共 gap。若多个 $g_j$ 相同，允许本征值重合或更高阶分裂。

### Proof：定理 2

对紧自伴算子采用从上端的 min–max 值 $\lambda_j^+$，正谱不足时补零。由范数扰动界及 $\operatorname{rank}G=r$，

$$
\left|\lambda_j^+(K(\mu_*-\tau^2))-\frac{g_j}{\tau}\right|\le M
\quad(1\le j\le r),
\qquad
\lambda_{r+1}^+(K(\mu_*-\tau^2))\le M.
\tag{4.3}
$$

选 $1/\varepsilon>M$ 且 $1/\varepsilon>\|K(\mu_*-\tau_0^2)\|$。当 $\tau=\tau_0$，全部本征值低于 $1/\varepsilon$；当 $\tau\downarrow0$，恰有前 $r$ 个正 min–max 值趋于正无穷。连续性给每个至少一次穿越，(4.3) 排除其余谱穿越。

还须证明不会多次穿越。若 $\mu_1<\mu_2$，命题 1 给 $K(\mu_2)-K(\mu_1)\succeq0$。在 $K(\mu_1)$ 的任意有限维正谱子空间上，$W^{1/2}$ 没有核：否则该向量对 $K(\mu_1)$ 的二次型为零，与正性矛盾。该子空间单位球紧，导数积分在其中有严格正的最小值。min–max 因此使每个仍为正的上端谱值严格增加。故各序号恰穿越一次；同点多个序号对应核维数，不重数错误地当作多个不同频率。

在穿越点，(4.3) 给

$$
\frac{g_j}{\varepsilon^{-1}+M}\le \tau_j
\le\frac{g_j}{\varepsilon^{-1}-M}.
\tag{4.4}
$$

所以 $\tau_j=\varepsilon g_j+O(\varepsilon^2)$；平方得到 (4.2)。由命题 1 的空间同构，这些都是原连续算子的局域本征值，重数一致。$r=0$ 时直接应用无根判据。证毕。

**非循环性说明。** 这里没有输入未知本征值或 FEM 饱和率；输入是未扰动连续算子的**局部** resolvent 展开。难度并未消失，而是被准确集中到 (4.1)。如果用有限矩阵观测到 $1/\tau$ 趋势，只得到展开的数值线索，不满足该定理的算子范数假设。

## 5. 定理 3：边界阈值正规形

为研究怎样得到 (4.1)，考虑一个边界形式的正规化。物理端口迹空间可取 $X=H^{1/2}_\beta(\Gamma_-\cup\Gamma_+)$；$X^*$ 指共轭对偶，DtN 的和原本映到 $X^*$。先用固定的 $X$ 内积定义与 $\tau,\varepsilon$ 无关的正 Riesz 同构 $J:X\to X^*$，将形式变为 $J^{-1}D:X\to X$。不能随参数改变度量后仍不加项地使用下面导数。

以下定理直接在 Hilbert 空间 $X$ 上陈述，不以已构造出物理 DtN 为前提。

**定理 3。** 设 $F(\tau,\varepsilon):X\to X$ 是原点邻域内算子范数 $C^2$ 的有界自伴族，

$$
F(\tau,\varepsilon)=F_0+\tau C-\varepsilon B_1+R(\tau,\varepsilon),
\quad \|R\|\le c(|\tau|+|\varepsilon|)^2,
\quad \|\partial_\tau R\|\le c(|\tau|+|\varepsilon|).
\tag{5.1}
$$

其中 $F_0$ 为自伴 Fredholm 算子。记 $N=\ker F_0$、$r=\dim N$，$P$ 为到 $N$ 的正交投影，$Q=I-P$。若 $r>0$，要求

$$
C_N=PCP|_N\succ0,\qquad B_N=PB_1P|_N\succ0.
\tag{5.2}
$$

则存在固定 $\tau_1,\varepsilon_1>0$，使每个 $0<\varepsilon<\varepsilon_1$ 在 $0<\tau<\tau_1$ 中恰有 $r$ 个方程 $\ker F(\tau,\varepsilon)\ne\{0\}$ 的根，计核维数，且

$$
\tau_j=\varepsilon\gamma_j+O(\varepsilon^2),
\qquad
\gamma_j\in\sigma(C_N^{-1/2}B_NC_N^{-1/2}),
\tag{5.3}
$$

按重数配对。于是若 $\mu=\mu_*-\tau^2$，相应距离为

$$
\mu_*-\mu_j=\varepsilon^2\gamma_j^2+O(\varepsilon^3).
\tag{5.4}
$$

若 $r=0$，则原点某固定邻域内 $F(\tau,\varepsilon)$ 一直可逆，因而不存在这样的弱扰动分岔。

### Proof：定理 3

**第一步：补空间确实可消元。** 自伴 Fredholm 性使 $\operatorname{ran}F_0=N^\perp$ 闭，故

$$
QF_0Q:QX\to QX
$$

有有界逆。缩小邻域后，$D=QF(\tau,\varepsilon)Q$ 由 Neumann 级数仍有一致有界逆，且逆是 $C^2$。令

$$
S=PFP-PFQ\,D^{-1}QFP:N\to N.
\tag{5.5}
$$

给定 $v\in\ker S$，$v-D^{-1}QFPv$ 属于 $\ker F$；反向取 $P$ 投影。这两个映射互逆，因此核维数相等。没有把无限维问题仅凭截断替换为有限矩阵。

**第二步：余项及导数。** 因 $PF_0Q=QF_0P=0$，两个非对角块都是 $O(|\tau|+|\varepsilon|)$。它们的 Schur 乘积是二阶，其 $\tau$ 导数是一阶。故

$$
S(\tau,\varepsilon)=\tau C_N-\varepsilon B_N+O((|\tau|+|\varepsilon|)^2),
\quad
\partial_\tau S=C_N+O(|\tau|+|\varepsilon|).
\tag{5.6}
$$

记 $c_0=\lambda_{\min}(C_N)>0$，再缩小固定邻域，使 $\partial_\tau S\succeq(c_0/2)I_N$。这一步正是只写函数值 $O((\tau+\varepsilon)^2)$ 而不控制导数时会缺失的论证。

**第三步：存在和精确计数。** 对充分小的 $\varepsilon>0$，

$$
S(0,\varepsilon)=-\varepsilon B_N+O(\varepsilon^2)\prec0.
$$

先取足够小的固定 $\tau_1>0$，使 $S(\tau_1,0)\succ0$；再取足够小的 $\varepsilon_1$，使 $S(\tau_1,\varepsilon)\succ0$。$S$ 的 $r$ 个有序本征值连续，且由 min–max 和 $\partial_\tau S\succeq(c_0/2)I_N$ 严格增加。所以每个恰穿越零一次，共 $r$ 次，计重数。区间中没有其他根，因为 $D$ 可逆且 $S$ 是完整 Schur 补。

**第四步：先定位尺度，再求系数。** 对足够大的固定 $T$，$TC_N-B_N\succ0$。由 (5.6)，$S(T\varepsilon,\varepsilon)\succ0$，故全部根满足 $\tau_j=O(\varepsilon)$。定义固定同余后的矩阵

$$
\widehat S=C_N^{-1/2}SC_N^{-1/2}
=\tau I_N-\varepsilon C_N^{-1/2}B_NC_N^{-1/2}+O(\varepsilon^2)
$$

于包含所有根的 $0\le\tau\le T\varepsilon$ 上一致成立。其与显式 Hermitian 矩阵的有序本征值误差不超过 $c_1\varepsilon^2$。结合严格单调性，每个零点被相应 $\varepsilon\gamma_j\pm c_1\varepsilon^2$ 括住（对重特征值作簇配对）。这就给出 (5.3)；平方得到 (5.4)。

若 $r=0$，$F_0$ 有有界逆，直接由 Neumann 级数证明邻域内可逆。证毕。

### 5.1 对物理波导的条件对应，不能略过

| 定理输入 | 在本问题中的拟议含义 | 本轮状态 |
|---|---|---|
| $\ker F(\tau,\varepsilon)$ 与 $L^2$ 模态同构，$\tau>0$ | 中心和两侧衰减解的 Cauchy 拼接 | 无 Dirichlet 极点时的标准路线；本轮未替所有异质材料证明完整适配 |
| $F(\tau,\varepsilon)$ 在 $\tau=0$ 为 $C^2$ | 简单二次带边的平方根正则化 | **未证明**；不能由离散 QZ 曲线平滑推出 |
| $F_0$ Fredholm、有限核 | 阈值匹配的有限自由度 | **未证明**一般适配；阈值加权空间及边界图必须选对 |
| $N$ 等于共振空间 | 非衰减但有界的阈值尾可见，且排除阈值 $L^2$ 态 | **未证明**；零 Dirichlet 迹或边界极点可破坏单图解释 |
| $C_N\succ0$ | 共振态耦合到简单开放阈值通道 | **未证明**一般式；对称性可使部分通道不可见 |
| $B_N\succ0$ | 局部增重确实作用于每个共振方向 | 对给定中心 Poisson 问题可由下述变分式检验；正定性仍需检查 |

若中心 Dirichlet 问题在 $\mu_*$ 可解，对固定边界迹 $f,g$ 的中心解 $u_f,u_g$，其弱 DtN 形式满足

$$
\left.\partial_\varepsilon\langle D_c(\mu,\varepsilon)f,g\rangle\right|_{\varepsilon=0}
=-\mu\int_{B_c}w u_f\overline{u_g}.
\tag{5.7}
$$

**证明 (5.7)。** 对中心 stationary form $a(u_f,u_g)-\mu\int(\rho_0+\varepsilon w)u_f\bar u_g$ 求导；场的导数有零边界迹，分别与未扰动方程配对为零，只剩显式材料项。此论证也要求解对参数可微，由可逆的中心 Dirichlet 问题保证。

因此当 $\mu_*>0,w\ge0$ 时，$B_N$ 的候选矩阵是 $\mu_*\int w u_i\bar u_j$。它非负，但不能仅凭 $w\not\equiv0$ 无条件声称正定；须排除共振线性组合在扰动支集上消失。$B_1$ 是边界导数，不是 §2 的乘法算子 $W$。

## 6. 命题 4：可完全解出的异质阈值

考虑 $L^2(\mathbb R)$ 上的模型

$$
H_\alpha=-\frac{\mathrm d^2}{\mathrm dx^2}
+V_-\mathbf1_{x<0}+V_+\mathbf1_{x>0}-\alpha\delta_0,
\qquad V_\pm\in\mathbb R,\quad\alpha\in\mathbb R.
\tag{6.1}
$$

定义域由两半轴 $H^2$、$u(0-)=u(0+)$ 和

$$
u'(0+)-u'(0-)=-\alpha u(0)
\tag{6.2}
$$

给出。这是解释阈值机制的自伴最小模型，不属于当前正密度 Helmholtz 方程的已完成极限推导。

**命题 4。** 令 $V_0=\min(V_-,V_+)$，$\Delta=|V_+-V_-|$。在 $(-\infty,V_0)$：

- 若 $\alpha>\sqrt\Delta$，恰有一个简单本征值；
- 若 $\alpha\le\sqrt\Delta$，没有本征值；
- $\alpha=\sqrt\Delta$ 时有有界但非 $L^2$ 的阈值解；
- 当 $\alpha>\sqrt\Delta$，本征值恰为

$$
E(\alpha)=V_0-\frac{(\alpha^2-\Delta)^2}{4\alpha^2}.
\tag{6.3}
$$

### Proof：命题 4

设 $E<V_0$，$\kappa_\pm=\sqrt{V_\pm-E}>0$。两端 $L^2$ 解分别是 $c_-\mathrm e^{\kappa_-x}$ 和 $c_+\mathrm e^{-\kappa_+x}$。连续性使 $c_-=c_+=c$；若 $c=0$ 则解为零，所以 (6.2) 等价于

$$
\kappa_-+\kappa_+=\alpha.
\tag{6.4}
$$

左边随 $E$ 严格下降，其值域为 $(\sqrt\Delta,\infty)$，故得到存在性、唯一性；特别是 $\alpha\le0$ 也没有根。解只剩一维振幅，所以简单。

不妨 $V_-=V_0$。由 $\kappa_+^2-\kappa_-^2=\Delta$ 和 (6.4)，

$$
\kappa_-=\frac{\alpha^2-\Delta}{2\alpha}.
$$

它必须为正；不能只平方方程后保留 $\alpha<\sqrt\Delta$ 的伪解。代入 $E=V_0-\kappa_-^2$ 得 (6.3)。等号时左端解为非零常数、右端在 $\Delta>0$ 时衰减；$\Delta=0$ 时两端均为常数。均非 $L^2$，却满足阈值方程。证毕。

### 6.1 三个直接后果

1. **异质性可以产生正临界强度。** $\Delta>0$ 时，任意弱吸引不足以产生束缚态。因而“同周期背景的任意弱缺陷定理自动适用于不同两端”在这个最小类中已经错误。
2. **相同带边也不充分。** 取 $V_-=V_+=V_0$，但预先加入排斥接口 $+\gamma\delta_0$，再施加吸引 $-\varepsilon\delta_0$。有效强度 $\alpha=\varepsilon-\gamma$；仅当 $\varepsilon>\gamma$ 才有本征态。两侧 bulk 完全相同也不能替代接口阈值匹配条件。
3. **临界共振附近恢复二次律。** 对 $\Delta>0$，写 $\alpha=\sqrt\Delta+h$，$h\downarrow0$，则 $V_0-E=h^2+O(h^3)$；对 $\Delta=0$，恰有 $V_0-E=\alpha^2/4$。这里控制变量是到临界接口的距离，而不一定是到零缺陷的距离。

另有一个可用于识别矩阵系数的解析量：固定 $u(0)=1$ 时，

$$
\|u\|_{L^2(\mathbb R)}^2=\frac1{2\kappa_-}+\frac1{2\kappa_+}
=-\frac{\mathrm d}{\mathrm dE}(\kappa_-+\kappa_+-\alpha).
\tag{6.5}
$$

质量在带边发散，而改用 $\tau=\sqrt{V_0-E}$ 后边界函数可变得光滑。这解释为什么应研究参数化，不宜把大质量导数单独解释为求解失败。本文只证明这个模型的恒等式，不据此外推当前算例的具体病态程度。

### 6.2 两侧带边失配的过渡尺度

将同一精确模型取成 $V_-=0$、$V_+=\varepsilon^2d$，接口已有排斥 $+\varepsilon g\delta_0$，新吸引为 $-\varepsilon b\delta_0$，其中 $d\ge0$、$g\ge0$、$b>0$ 固定。令 $a=b-g$。当 $a\le0$，(6.4) 的正左边不能等于非正右边；当 $a>0$，命题 4 直接给

$$
\text{存在束缚态}\quad\Longleftrightarrow\quad a>\sqrt d,
\qquad
E=-\varepsilon^2\left(\frac{a^2-d}{2a}\right)^2.
\tag{6.6}
$$

这是完整代数后果，不是新的数值结果。它给出一个比“相同/不同两端”更精确的后续问题：**当 bulk 边缘失配与弱缺陷能量位移同为 $O(\varepsilon^2)$ 时，是否存在可统一描述两者的接口有效模型？** 对真实周期介质，此统一极限尚未证明；不能先取固定失配极限再任意令失配归零。

### 6.3 推论 5：不用点相互作用的正密度 Helmholtz 例子

前面的点相互作用用于拆解机制。现在直接在 §2 的同型 PDE 中构造一个可解析检查的例子。取 $L=1$、$\beta=1$、

$$
\ell=\frac{\pi}{2\sqrt3},\qquad
\rho_\varepsilon(x)=
\begin{cases}
1,&x<0,\\
7+\varepsilon,&0<x<\ell,\\
4,&x>\ell.
\end{cases}
\tag{6.7}
$$

两端常系数也是周期介质；所有系数均为正，界面满足 $u$ 与 $\partial_xu$ 连续。考虑 $u(x,y)=v(x)\mathrm e^{\mathrm iy}$，其方程为

$$
-v''+v=\mu\rho_\varepsilon v.
\tag{6.8}
$$

**推论 5。** 当 $\varepsilon=0$ 时，$\mu_*=1/4$ 是该 fixed-$\beta$ 连续算子的谱底，有显式非 $L^2$ 阈值共振而无低于它的谱。充分小 $\varepsilon>0$ 时，恰有一个低于 $1/4$ 的简单局域本征值，并且

$$
\mu(\varepsilon)
=\frac14-\left(\frac{\pi+2}{32\sqrt3}\right)^2\varepsilon^2
+O(\varepsilon^3).
\tag{6.9}
$$

若先把中心密度降为 $7-\eta$，其中固定 $0<\eta<1$，再增重 $\varepsilon$，则 $0\le\varepsilon\le\eta$ 时没有低于 $1/4$ 的局域态；$\varepsilon=\eta$ 恰为阈值共振；充分小的 $\varepsilon-\eta>0$ 时 (6.9) 以 $\varepsilon-\eta$ 代替 $\varepsilon$ 成立。

### Proof：推论 5

**显式共振及无低谱。** 令 $\nu_0=\sqrt3/2$，故 $\nu_0\ell=\pi/4$。函数

$$
h(x)=
\begin{cases}
\mathrm e^{\nu_0x},&x<0,\\
\cos(\nu_0x)+\sin(\nu_0x),&0\le x\le\ell,\\
\sqrt2,&x>\ell
\end{cases}
\tag{6.10}
$$

处处正、$C^1$，满足 $-h''+h=\rho_0h/4$，且右端不衰减，故不是 $L^2$。对紧支撑光滑 $v$ 分部积分（两界面项因 $h,h'$ 连续而抵消）得 ground-state 恒等式

$$
\int_{\mathbb R}\left(|v'|^2+|v|^2-\frac14\rho_0|v|^2\right)
=\int_{\mathbb R}h^2\left|\left(\frac vh\right)'\right|^2\ge0.
\tag{6.11}
$$

右端也等于 $\int|v'-(h'/h)v|^2$，且 $h'/h$ 有界，故 $H^1$ 闭包和下述等号条件均合法，不受 $h$ 在左无穷远趋零的影响。

由形式闭包，$n=0$ 通道的算子不低于 $1/4$。把宽支撑、缓变的常数型 cutoff 平移到右端，可构造在 $1/4$ 的 Weyl 序列；故它确为谱底。零等号若为 $L^2$ 本征函数，则 $v/h$ 常数，矛盾，所以这是真共振而非阈值本征态。

横向 Fourier 通道为 $q_n=1+2\pi n$。当 $n\ne0$ 时，$|q_n|\ge2\pi-1$，且 $0\le\varepsilon<1$ 时 $\rho_\varepsilon\le8$，故相应 Rayleigh 商至少为 $(2\pi-1)^2/8>1/4$。因此阈值附近不会遗漏别的横向通道；这一步把标量计算提升为这个二维分层模型的完整 fiber 结论。

**精确匹配方程。** 写 $\mu=1/4-\tau^2$，其中 $\tau>0$。左右衰减率为

$$
\kappa_-=\sqrt{1-\mu},\qquad \kappa_+=\sqrt{1-4\mu}=2\tau,
\qquad \nu=\sqrt{(7+\varepsilon)\mu-1}.
$$

在原点附近 $\nu>0$。固定左端 $v(0)=1$、$v'(0)=\kappa_-$ 后，中心精确解为

$$
v(x)=\cos(\nu x)+\frac{\kappa_-}{\nu}\sin(\nu x).
$$

右端衰减条件等价于标量方程

$$
f(\tau,\varepsilon)=
-\nu\sin(\nu\ell)+\kappa_-\cos(\nu\ell)
+2\tau\left(\cos(\nu\ell)+\frac{\kappa_-}{\nu}\sin(\nu\ell)\right)=0.
\tag{6.12}
$$

任一非零 $L^2$ 解的 $v(0)$ 不能为零，否则左端衰减解及其导数均为零；所以该归一化不漏模态。(6.12) 在 $(0,0)$ 附近解析，可为求导把 $2\tau$ 延拓到负 $\tau$，但物理衰减只取正支。

在原点 $\kappa_-=\nu=\nu_0$，$\sin(\nu_0\ell)=\cos(\nu_0\ell)=1/\sqrt2$。因 $\partial_\tau\mu(0)=0$，

$$
f(0,0)=0,\qquad f_\tau(0,0)=2\sqrt2,
\qquad
f_\varepsilon(0,0)=-\frac{\pi+2}{16\nu_0\sqrt2}.
\tag{6.13}
$$

最后一个式子可直接用 $\partial_\varepsilon\nu=1/(8\nu_0)$ 微分 (6.12)，没有使用数值差分。定理 3 的标量版本（或隐函数定理）给唯一正根

$$
\tau=\frac{\pi+2}{64\nu_0}\varepsilon+O(\varepsilon^2)
=\frac{\pi+2}{32\sqrt3}\varepsilon+O(\varepsilon^2).
$$

平方得到 (6.9)。标量匹配核一维，因而连续自伴本征值简单。

**排除更远的低谱及证明正阈值。** 由 $\rho_\varepsilon\le(1+\varepsilon/7)\rho_0$ 与 (6.11)，整个 $n=0$ 通道的 Rayleigh 商至少为 $1/[4(1+\varepsilon/7)]$。所以 $\varepsilon\downarrow0$ 时任何低于 $1/4$ 的谱都必须进入刚才已经完整计数的固定阈值邻域；其他通道已排除，故只有上述一个本征值。对于中心密度 $7-\eta+\varepsilon\le7$，(6.11) 反而直接使 Rayleigh 商不低于 $1/4$，所以无低谱。若 $t=\varepsilon-\eta<0$，由于 $0<\eta<1$，在阈值仍有 $0<\nu<\nu_0$ 且 $\nu\ell<\pi/4$，于是 $f(0,t)=-\nu\sin(\nu\ell)+\nu_0\cos(\nu\ell)>0$，也没有阈值共振。超过临界时用 $\varepsilon-\eta$ 代入。证毕。

**适用边界。** 这是本轮真正闭合到连续正材料 PDE 的最小结果，说明“一侧临界、另一侧仍衰减”也能有共振和二次分岔。但它是可分离分层介质的**谱底**；有限内部 gap、非平凡周期单胞和多通道适配仍未解决。本轮不主张这个可解例子的优先权。

## 7. 主动尝试推翻：哪里会失败

### 7.1 有共振但没有非退化平方根项

标量族 $F(\tau,\varepsilon)=\tau^2-\varepsilon$ 有 $F_0=0$，也有正材料方向的形式 $-\varepsilon$，但 $C_N=0$。它的正根为 $\tau=\sqrt\varepsilon$，因而 $\mu_*-\mu=\varepsilon$，不是二次律。故不能删除定理 3 的 $C_N\succ0$。它是正规形反例，不声称此具体族已经由周期波导实现。

### 7.2 共振存在而扰动不耦合

取 $F(\tau,\varepsilon)=\operatorname{diag}(\tau,1-\varepsilon)$。$F_0$ 有一维核、$C_N=1$，但 $B_N=0$。小 $\varepsilon$ 下没有正 $\tau$ 根。共振本身不是充分条件，必须检查扰动在共振空间的投影。

### 7.3 只给函数值余项而不给导数，会失去精确根数

在标量情形，以 $\varepsilon>0$ 定义

$$
F(\tau,\varepsilon)=\tau-\varepsilon+
\varepsilon^2\sin\!\left(\frac{\tau-\varepsilon}{\varepsilon^4}\right).
\tag{7.1}
$$

它满足函数值的二阶余项界，但在 $|\tau-\varepsilon|<\varepsilon^2$ 内发生多次符号变化（取正弦连续交替极值且 $|\tau-\varepsilon|<\varepsilon^2/2$ 即可）。因此不能由 $O((\tau+\varepsilon)^2)$ 一句推出唯一分支；(7.1) 不满足定理 3 的 $C^2$/导数条件。定理 2 没有这一缺陷，因为它使用从原连续 resolvent 直接证明的单调性。

### 7.4 与已知理论比较后必须放弃的宽泛主张

- “阈值共振决定弱扰动分岔”并非新主题：Nazarov 已研究圆柱及周期波导，Pankrashkin 给出无阈值共振判据。
- “二次带边距离与有效质量”已有 Duchêne–Vukićević–Weinstein 等精确结果。
- “多通道计数”也不能笼统称新：Brown 等对同背景弱线缺陷已给出产生模态数。
- “两侧带边不同就一定有正阈值”没有被本文证明，也未成为最终猜想。通过中心结构调到阈值共振，即使只有一侧到达带边，也可能无阈值分岔。

保留下来的狭义研究目标是：**建立适用于加权传输型二维异质周期条带的、可识别接口共振空间及缺陷耦合矩阵的阈值展开，并证明它在有边界图极点、通道退化时何时失效。** 该句仍是研究目标，不是优先权声明。

## 8. 文献条件核对与未闭合桥接

文献完整书目、核验深度和 URL 集中在 [[research/explorations/interface-threshold/research_landscape#重要参考文献与适用条件]]。这里仅登记与证明关系：

| 来源 | 实际核对结果 | 对本文可用的范围 | 不允许的跳跃 |
|---|---|---|---|
| Brown–Hoang–Plum–Wood 2015，Theorem 1（2012 预印本） | 同一周期背景、正的弱线缺陷、固定准周期纤维的存在性 | 说明原问题附近已有无阈值先例 | 把异质接口当作同一周期背景的局部扰动 |
| Duchêne–Vukićević–Weinstein 2015，Theorem 3.4 | 一维连续周期实势，局域有界扰动及一阶矩可积；带边曲率与 Bloch 加权扰动积分异号；给二次主项及局部唯一性 | 比较有效质量机制与余项假设 | 将其 $O(\varepsilon^{2+1/4})$ 任意升级到本文抽象假设下的 $O(\varepsilon^3)$；两套假设不同 |
| Fliss 2013，Theorems 4.1、4.5；Remark 4.2 | gap 内半导 Dirichlet 仍可有例外，正则窗口有精确消元 | 解释为什么边界图和核/场等价必须单列 | 公共 bulk gap 自动保证全窗口 DtN 正则 |
| Behrndt–Rohleder 2015，Theorems 4.1、4.7 | 单一 DtN 逆的谱可见性有局限，增广 Weyl 对象可恢复完整描述 | 警告切口零迹态与图的局限 | 把所有边界核/极点直接等同阈值共振 |
| Nazarov 2020；Pankrashkin 2017 | 已有阈值共振分类、缺失判据及弱扰动机制，具体模型和条件见地图 | 否定宽泛新颖性主张，指向加权空间/散射工具 | 宣称本文已适配它们到所有分片材料、内部带边和左右异质端 |

命题 1、定理 2、定理 3、命题 4 的证明没有将上表中的专门定理作为未展开的逻辑黑箱；只用谱定理、闭形式、局部椭圆正则性、Rellich、Neumann 级数和有限维 min–max 等基础结果。原波导阈值展开则仍未完成，不能以抽象证明闭合来掩盖。

### 8.1 合理但尚未证明的具体猜想

**猜想 A1（局部阈值二分）。** 进一步限制 §2 的材料：每个周期胞元仅有有限条光滑材料界面；公共 gap 的上端 $\mu_*$ 在临界一侧/两侧只由有限个孤立、二次非退化的 Bloch 带极小值达到；非临界另一侧仍严格位于 gap；原接口在 $\mu_*$ 没有 $L^2$ 本征态，且 (2.2) 成立。则对每个固定的非负紧支撑 $w$，有

$$
K(\mu_*-\tau^2)=\tau^{-1}G+O(1)
\quad\text{于 }\mathcal B(H)\text{ 中},
\qquad G\succeq0,
$$

其中 $\operatorname{rank}G$ 等于阈值共振空间经 $u\mapsto W^{1/2}u$ 映射后的维数。特别地，无阈值共振时局部 BS 算子有界，充分弱增重不产生趋近该边缘的本征值；有可见共振时定理 2 给相应模态数与二次尺度。

这是**待证明且需要继续查重**的候选陈述，不是已核文献定理。局部映射对非 $L^2$ 共振有意义，因为 $w$ 紧支撑；但共振空间的严格辐射定义、有限维性和范数余项均须建立。本轮推论 5 验证了一个同型的谱底特例，不能证明上述一般猜想。

**尚不清楚：** 上述正则性/带边条件是否已经充分，是否还需要额外的阈值可解性或边界可见性假设，以及它与 Nazarov 的最强周期波导结果究竟重合多少。若只能得到比 $O(1)$ 更弱的余项，定理 2 的精确误差阶须相应重新推导，不可保留原来的 $O(\varepsilon^3)$。

## 9. 证明交付与记号审计

- 源文件：用户给出研究任务，没有指定需修补的既有定理。
- 输出文件：本文件；证明位置为各 `Proof` 小节，公式 (5.7) 另有显式证明。
- 新编号：命题 1、定理 2、定理 3、命题 4、推论 5；这是手工编号，未依赖 LaTeX 自动编号。
- 用户授权的证明外内容：问题设定、文献比较、反例、后续适配表；均在独立主题目录内。
- 新记号：$W$ 是固定 Hilbert 空间中的局部质量乘法；$K$ 是 BS 算子；$G$ 是其有限秩奇异系数；$F$ 是已正规化的边界族；$B_1$ 是边界扰动导数；$N,P,Q$ 只用于有限核约化；$S$ 是精确 Schur 补；$\tau$ 统一表示带边距离平方根。没有与旧主线宏或矩阵名静默合并。
- 下载：本轮新增六份合法公开 PDF，身份、版本和来源见领域地图 §5；其余引用可由在线全文核验，R9 仍只核元数据/摘要。没有声称人类已读过这些文献。
- 已证明部分状态：**Proof literature verification completed**，限定为上述自足命题及抽象定理；不表示二维异质阈值展开已完成。
- 未解决的全部后续任务、严重性与最小检查统一登记在 [[research/explorations/interface-threshold/STATUS]]，不在此重复增长问题清单。
- 本文由 AI 辅助检索、推导与独立审查形成；文献先例与本轮证明分开标记，未运行任何数值实验。

独立审查：proof_skeptic 对保存后的命题 1、定理 2、定理 3、命题 4 和三个反例给出 **VERIFIED（仅在正文假设内）**，并另行审查新增推论 5，结论同为 **VERIFIED（分层谱底模型）**。首轮指出的弱形式和定理 2 左端资格已补齐；点相互作用的实参数范围、共轭对偶、ground-state 闭包、失谐阈值与下载记录已同步修复。审查未认证一般二维阈值展开，也未声称文献穷尽性。
