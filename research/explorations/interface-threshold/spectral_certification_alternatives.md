# 二维连续谱距离认证：从边界缺陷到可评价的定义域重构

日期：2026-10-28。本文的路线 A 指**二维 Helmholtz 严格后验谱认证**；与首轮候选文档的字母编号不同。固定候选 $\widehat k>0$，令 $\mu=\widehat k^2$。只做理论、已有产物的只读核查及实验设计，没有执行认证程序或数值实验。

**结论先行：可以构造连续算子定义域中的场；这一存在性桥梁项目已经有了。现在值得研究的是同一重构的边界缺陷表示，能否把大体积相消改成小缺陷的直接、严格评价。** 本文证明分布修正与现有源平滑的关系，给出单墙精确范数、多界面 Gram 的有限证书合同，以及独立的 bulk gap 有限充分判据。没有宣称当前五瓣材料 candidate 已获认证，也没有把这些基本算子恒等式称为新的谱理论。

## 1. 必须先纠正的现有成果基线

### 1.1 I6 已有一个严格全谱距离证书

本轮实时只读核查 `test/i6/resolvent-v3/output/attempt-1/run-10/certificate.json`、`scalar-audit.json`、[[research/projects/eig-apost/implementation/i6/design-6-1c]] 和 [[research/projects/eig-apost/implementation/i6/review-6-1c]]：保存的状态是 `CERTIFIED_SPECTRAL_DISTANCE_UPPER_BOUND`，有

$$
\operatorname{dist}(\mu,\sigma(A(\beta)))
\le 1.64933909531673\times10^{-7},
$$

包含区间为 $[3.359046767703687789,3.359047097571506853]$。这是空中心、圆形 inclusion、材料 $1/17$ 的冻结实例，**不是**当前 I10 的 $\mu\approx2.42872867$ 实例。保存的独立标量审查覆盖 96 个球记录和最终代数链，并明确不替代核函数证明。本轮未重跑该审查。

该证书依赖明确的 dyadic 输入定义、Arb/FLINT 包含性合同、已审查的解析余项以及有限几何门；这是通常意义的计算机辅助证书，不是全软件栈形式验证。不能因这些信任基础把它降为普通数值估计，也不能把它扩大成共同 gap、孤立性或唯一性证书。

I6 使用 raw 场的全部材料/人工墙跳跃与对偶 resolvent，原场不必属于 $H^1$。具体公式、全局 $H^2$ 正则性和统一 collar 常数已经分别证明于 [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework]]、[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace]]。重做标准谱距离不等式或这套对偶论证，不是新的研究方向。

### 1.2 I9 已有真正的强定义域重构

[[research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound#2. 常系数源重构与连续谱距离|I9 定理 1]] 从任意非零、紧支撑 $u\in L^2$ 定义

$$
w=(-\Delta+t)^{-1}[(\mu\rho+t)u]\in H^2_\beta(B)=D(A),\qquad t>0,
$$

并证明 $\rho(A-\mu)w=(\mu\rho+t)(u-w)$。因此“能不能进入原连续算子定义域”已有肯定答案。I9.6 当前缺陷在实际几何积分、带符号/复缺陷矩及评价余项未完全闭合；见 [[research/projects/eig-apost/implementation/i9/review-9-6a#9. R2：D2 run-03 实际结果审查]]。不能把评价失败解释为该定义域定理失败。

更早的 [[research/projects/eig-apost/phase3-analysis/s-lead-field]] 也已有 Fourier–Hermite/bubble 的全局 $H^2$ 场、残差 Gram 与无限传播尾；“平滑场＋有限核心＋Gram”本身不新。I5 的 collar lift 则主要修值跳跃进入 broken $H^1$，不等于同时修两类跳跃进入 $D(A)$。

## 2. 固定原二维模型和数据对象

取圆柱 $B=\mathbb R\times(0,L)$，固定实数 $\beta\in\mathbb R$，横向为 $\beta$ 准周期；

$$
0<\rho_{\min}\le\rho(x,y)\le\rho_{\max}<\infty,
\quad \mathcal H=L^2(B,\rho\,\mathrm dx\,\mathrm dy),
\quad A=-\rho^{-1}\Delta,\quad D(A)=H^2_\beta(B).
$$

$H^2_\beta$ 同时满足值与横向导数的准周期匹配。材料可以跳变、左右周期模板可以不同；因为主部是普通 Laplacian，物理传输条件是 $u$ 和同向普通法导数连续，**不是** $\rho^{-1}\partial_\nu u$ 连续。该定义域等式由准周期 Fourier 乘子直接证明，不对不连续的 $\rho$ 求导。

冻结数值系数后，先定义一个**精确的可计算 raw 场** $u$：例如用有限 Fourier 密度和精确连续层势核，逐材料片、逐胞元重建；两尾由明确的有限矩阵 $P_\pm$ 反复传播。它不必是某个未知精确 BIE 解的近似，也不必使用真实半波导 DtN。它必须定义同一个 $\mu,\beta,\rho$ 上的 $L^2$ 函数。

用从侧 1 指向侧 2 的法向，定义

$$
a_\Gamma=u^{(2)}-u^{(1)},\qquad
j_\Gamma=\partial_\nu u^{(1)}-\partial_\nu u^{(2)},\qquad
r=(-\Delta-\mu\rho)u\quad\text{逐片}.
$$

所有真实材料面、中心/尾接口和尾内人工墙各计一次。若横向相位不精确匹配，必须先把 seam 缺陷并入，而不能宣布它抵消。下文为简洁假设已精确匹配。

定义界面分布 $J$（对复测试函数使用共轭对偶）为

$$
\langle J,\phi\rangle
=\sum_\Gamma\int_\Gamma
\big(j_\Gamma\overline\phi+a_\Gamma\partial_\nu\overline\phi\big)\,\mathrm ds.
\tag{A1}
$$

分布记号为 $J=\sum_\Gamma[j_\Gamma\delta_\Gamma-\operatorname{div}(a_\Gamma\nu\delta_\Gamma)]$。逐片 Green 恒等式给

$$
(-\Delta-\mu\rho)u=r+J.
\tag{A2}
$$

对无限分区，(A2) 的含义先是紧支撑测试函数上的局部有限和。全局连续性由下面的平方可和条件给出。

## 3. 本轮证明 A1：分布修正进入原定义域

**命题 A1。** 假设 $u\in L^2_\beta(B)$、$r\in L^2(B)$，(A2) 成立，且界面具有 [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace|假设 G]] 的统一 collar 和有界覆盖重数。若

$$
\eta^2=\sum_\Gamma(\|j_\Gamma\|_{L^2(\Gamma)}^2+
\|a_\Gamma\|_{L^2(\Gamma)}^2)<\infty,
\tag{A3}
$$

则对任意 $t>0$，由转置定义的

$$
L_t=-\Delta+t,\quad e=L_t^{-1}J\in L^2_\beta(B),\quad v=u-e
\tag{A4}
$$

满足 $v\in D(A)$，并有

$$
(-\Delta-\mu\rho)v=r+(t+\mu\rho)e,
\qquad
v=L_t^{-1}[(t+\mu\rho)u+r].
\tag{A5}
$$

若 $U_->0$、$E_0\ge\|e\|_0$、$R_0\ge\|\rho^{-1/2}r\|_0$ 是严格单侧数据，且

$$
U_-\le\|u\|_{\mathcal H},\qquad
U_->\sqrt{\rho_{\max}}E_0,
$$

则

$$
\boxed{\operatorname{dist}(\mu,\sigma(A))
\le\frac{R_0+C_tE_0}{U_--\sqrt{\rho_{\max}}E_0},\qquad
C_t=\max_{s\in[\rho_{\min},\rho_{\max}]}
\frac{t+\mu s}{\sqrt s}.}
\tag{A6}
$$

这里 $\|\cdot\|_0$ 为未加权 $L^2$；$C_t^2$ 是 $t^2/s+2t\mu+\mu^2s$ 的最大值，因凸性只需两端点。若已知有限材料值集，也可直接对该集合取最大值。

**证明。** 令 $c_0=N_{\rm ov}/[(1-h\kappa_*)h]$、$c_1=N_{\rm ov}h/[2(1-h\kappa_*)]$。双侧迹不等式与 Fourier 乘子给，对 $z=L_t^{-1}f$，

$$
\sum_\Gamma(\|z\|_\Gamma^2+\|\partial_\nu z\|_\Gamma^2)
\le T_t^2\|f\|_0^2,
\quad
T_t^2=\frac{c_0}{t^2}+\frac{c_0+c_1}{4t}+c_1.
\tag{A7}
$$

这里使用 $\|z\|_0\le t^{-1}\|f\|_0$、$\|\nabla z\|_0\le(2\sqrt t)^{-1}\|f\|_0$、$\|D^2z\|_0\le\|f\|_0$。因此 $f\mapsto\langle J,L_t^{-1}f\rangle$ 是范数不超过 $T_t\eta$ 的有界泛函，Riesz 表示定义唯一 $e\in L^2$，且 $L_te=J$ 于分布意义成立。有限界面截断的 $e$ 在 $L^2$ 中收敛，因为相应 (A3) 的尾趋零；无穷和无需任意逐点换序。

由 (A2) 有 $L_t(u-e)=(t+\mu\rho)u+r\in L^2$。全条带 Fourier 乘子于是给 $v\in H^2_\beta$。材料传输条件与人工墙匹配随全局 $H^2$ 自动成立。移去正移位得到 (A5)。再用

$$
\|(A-\mu)v\|_{\mathcal H}\le R_0+C_tE_0,
\qquad \|v\|_{\mathcal H}\ge U_--\sqrt{\rho_{\max}}E_0,
$$

及自伴谱定理即得 (A6)。证毕。

**边界与已有理论的关系。** 当逐片 PDE 精确、$r=0$ 时，(A5) 就是 I9 的源平滑，推广到未硬截断的 $L^2$ raw 场。因此本命题不是“全新 lift”。贡献候选是对 $e$ 的不同表示与评价：直接输入小跳跃，避免先形成两个大量 $u$、$L_t^{-1}[(t+\mu\rho)u]$ 再相减。

**为什么不要求更强跳跃范数。** 局部逐片 $H^2$ 的 trace right inverse 常需 $a\in H^{3/2}$、$j\in H^{1/2}$。命题 A1 先只构造全局 $e\in L^2$，再由分布方程证明 $v\in H^2$；没有声称修正 $e$ 自身逐片至边界 $H^2$。故 (A3) 足够，不存在偷换迹空间。无量纲 (A3)、(A7) 与仓库一致；保留长度单位时需加入已给出的 $\ell_*$ 配对权重。

## 4. 本轮证明 A2：单墙的精确频率权重

取一条直墙 $x=0$、法向 $e_x$，$\psi_n(y)=L^{-1/2}\exp(\mathrm i q_ny)$，$q_n=\beta+2\pi n/L$。将 $a,j$ 展为 $a_n,j_n$，令 $\kappa_n=\sqrt{t+q_n^2}$。由 $J_n=j_n\delta_0-a_n\delta'_0$，

$$
e_n(x)=\frac{j_n}{2\kappa_n}\mathrm e^{-\kappa_n|x|}
+\frac{a_n}{2}\operatorname{sgn}(x)\mathrm e^{-\kappa_n|x|}.
\tag{A8}
$$

**引理 A2。** 对 $a,j\in L^2(0,L)$，(A8) 给命题 A1 的 $e$，并且

$$
\boxed{\|e\|_0^2=
\sum_{n\in\mathbb Z}\left(
\frac{|j_n|^2}{4\kappa_n^3}+
\frac{|a_n|^2}{4\kappa_n}\right).}
\tag{A9}
$$

**证明。** 一维 $L_t$ 的第 $n$ 模 Green 核为 $g_n(x)=\mathrm e^{-\kappa_n|x|}/(2\kappa_n)$，因此 $e_n=j_ng_n-a_ng'_n$，给 (A8)。偶函数与奇函数在全实轴正交，包括复系数情形；积分 $\int_{\mathbb R}\mathrm e^{-2\kappa_n|x|}\,\mathrm dx=1/\kappa_n$，再用 Parseval 即得 (A9)。有限 Fourier 和先成立；右端收敛及转置唯一性给全体 $L^2$ 数据。证毕。

这揭示直接 $L^2$ 跳跃加统一迹常数损失的结构：高频法向缺陷的平方权重是 $\kappa_n^{-3}$，值缺陷是 $\kappa_n^{-1}$。但**不同墙之间一般有交叉项**，材料曲面和墙之间也有交叉项，不能将 (A9) 的单墙范数直接相加当作全场范数。

例如同一 Fourier 模在相距 $d$ 的两墙上的单层部分，其核内积为

$$
\int_{\mathbb R}g_n(x)g_n(x-d)\,\mathrm dx
=\frac{(d+\kappa_n^{-1})\mathrm e^{-\kappa_nd}}{4\kappa_n^2}.
\tag{A10}
$$

保留完整有符号 Gram 可能利用抵消；逐面三角不等式仍可靠，但可能丢掉实际所需的分辨率。是否值得保留 cross Gram 是算法问题，不能凭形式预测一定更紧。

## 5. 边界 Gram 怎样变成有限、严格的数

### 5.1 不在奇异层势上强行作体积分

记 $G_t=L_t^{-1}$ 的准周期核，$H_t=L_t^{-2}$ 的核。第 $n$ 个横向模有

$$
H_{t,n}(x)=\frac{(1+\kappa_n|x|)\mathrm e^{-\kappa_n|x|}}{4\kappa_n^3}.
\tag{A11}
$$

对有限组足够光滑的曲线数据，$\|L_t^{-1}J\|_0^2$ 是 $H_t$ 在双边界上的二次型；每个值跳跃对应对该边界变量作一次法向微分，每个 $j$ 对应零次。准确符号由 (A1) 的两个配对确定，或用有限光滑近似定义，避免手写层势正负号造成歧义。该二次型由 $\langle J,L_t^{-2}J\rangle$ 理解，**不**先写通常发散的 $\langle J,L_t^{-1}J\rangle$ 再对 $t$ 求导。

在局部二维坐标中，$H_t$ 的最强非光滑部分为 $r^2\log r$，双法向微分至多给可积的对数奇异性。等价的自由空间核是 $rK_1(\sqrt t\,r)/(4\pi\sqrt t)$，加准周期镜像；$t>0$ 使远镜像指数收敛。这是核的表示，不等于当前库已具备所有导数与余项的可靠实现。

**拟议有限合同：** 用有限边界 Fourier/分段多项式数据定义 $J_d$，严格评价

$$
G_+\ge\|L_t^{-1}J_d\|_0^2\ge0,
\quad \eta_d\ge\|(a,j)-(a_d,j_d)\|_{\ell^2(L^2)},
\quad E_0=\sqrt{G_+}+T_t\eta_d.
\tag{A12}
$$

这里 $\eta_d$ 包含未保留边界段、模态、胞元和密度评价误差；$G_+$ 包含全部保留 cross blocks、核截断、奇异求积和舍入的单侧误差。再把 (A12) 送入 (A6)。有限矩阵近似正定不是理由；需验证所得数确实上包连续二次型。可用 $\widehat G+\varepsilon_G$，其中 $\varepsilon_G$ 来自逐块或算子范数余项。

平墙 (A9) 的高模尾可以直接用

$$
\sum_{|n|>M}\left(\frac{|j_n|^2}{4\kappa_n^3}
+\frac{|a_n|^2}{4\kappa_n}\right)
\le \frac{\|j_{>M}\|_2^2}{4\kappa_{\rm tail}^3}
+\frac{\|a_{>M}\|_2^2}{4\kappa_{\rm tail}},
\quad \kappa_{\rm tail}=\inf_{|n|>M}\kappa_n.
$$

对曲面首轮可用保守 (A7) 包尾，不必同时完成尖锐曲面伪微分估计。若所有收益都被该尾吃掉，这就是可否决该算法的直接证据。

### 5.2 本轮证明 A4：有限光滑边界 Gram 的可计算性基线

下面给一个会收敛、但未必高效的有限构造，避免把 $G_+$ 当成无法落实的 oracle。

**命题 A4。** 设 $J_d$ 支撑于有限条在圆柱商空间上嵌入、互不相交的光滑闭曲线/直墙。数据有已知有限光滑分片及断点、一致上界。给定对参数化、Jacobian、法向和 $a,j$ 的**可靠区间值域评价器**，其包围宽度随参数区间细分及工作精度增加趋于零（不是只有点值或固定粗界）；并给长度上界、不同曲线的分离证书，以及除周期识别的局部对角线外的非局部自身/镜像分离证书。局部弧长另满足

$$
|\gamma(s)-\gamma(s')|\ge c|s-s'|,\qquad
0<|s-s'|<d_0,\quad c>0.
$$

这里短弧长度按周期识别；这些资格均为显式输入，例如可由已给的曲率与分离证书导出。则对任意指定 $\epsilon>0$，存在有限区间积分过程，给出宽度不超过 $\epsilon$ 的 $\|L_t^{-1}J_d\|_0^2$ 包围。不需要离散 BIE 可逆或物理带隙。参数 $t>0,\beta\in\mathbb R$ 也须有收敛的可靠评价。

**证明。** 先看二维自由空间核

$$
H_t(r)=\frac{rK_1(\sqrt t\,r)}{4\pi\sqrt t}
=\frac1{4\pi}\int_0^\infty
\exp\big(-ts-r^2/(4s)\big)\,\mathrm ds.
$$

令 $z=\sqrt t\,r$。有 $H_t(0)=1/(4\pi t)$，且用
$r\exp(-r^2/(4s))\le\sqrt{2s/\mathrm e}$ 得
$\|\nabla H_t\|\le\sqrt{2\pi/\mathrm e}/(8\pi\sqrt t)$。径向微分给

$$
\|D^2H_t(r)\|\le\frac{K_0(z)+zK_1(z)}{4\pi}.
$$

由正积分表示 $K_0(z)=\int_0^\infty\mathrm e^{-z\cosh s}\,\mathrm ds$，以及
$\cosh s\ge\mathrm e^s/2$，对 $0<z\le1$ 有

$$
K_0(z)\le\log(2/z)+\mathrm e^{-1},\qquad zK_1(z)\le1.
$$

后一式来自 $(zK_1(z))'=-zK_0(z)$ 及零点极限。故二次边界微分至多是显式常数加 $|\log r|$。对大 $z$，$\cosh s\ge1+s^2/2$ 给
$K_0(z)\le\mathrm e^{-z}\sqrt{\pi/(2z)}$；又
$z\cosh s\,\mathrm e^{-z\cosh s}\le(2/\mathrm e)\mathrm e^{-(z/2)\cosh s}$，所以
$zK_1(z)\le(2/\mathrm e)K_0(z/2)$。这些界连同一阶导数公式给全部远镜像及其至二阶导数的指数尾界。周期相位模为一，不改变绝对上界。具体地，超过由曲线坐标跨度决定的有限指标后，镜像距离 $r_k\ge |k|L/2$；将剩余有限次幂吸收到显式常数，可用 $C\mathrm e^{-\sqrt t L|k|/4}$ 共同包围零至二阶导数，再求几何级数。先取有限镜像，余下因此可控制到任意小。

自配对的对角带 $|s-s'|<d<\min\{d_0,1,t^{-1/2}\}$，由弦距下界、密度上界和上述核界，整个有符号 Gram 被积函数的绝对值不超过
$A+B|\log|s-s'||$；$A,B$ 由这些已给数据有限计算。长度为 $p$ 的曲线，该带的绝对贡献不超过

$$
2pd\,[A+B(1-\log d)]\longrightarrow0.
\tag{A12a}
$$

跨周期参数端点的近对角部分用相同短弧坐标处理，不漏掉 seam。移去这些带后，所有保留块在有限个紧参数矩形/可分片区域上连续，且收敛的区间函数评价给收敛的积分包围；近对角区域可用矩形外包的略宽带处理。先使镜像尾与 (A12a) 小于指定预算，再细分其余区域，即给总宽度小于 $\epsilon$ 的有限包围。$H_t=L_t^{-2}$ 的转置二次型等于修正的 $L^2$ 范数平方，故包围对象正确。证毕。

这个命题只证明**存在一个有限、可验证、收敛的评价流程**；没有给达到 $10^{-10}$ 的实用复杂度。它限于给定有限 $J_d$ 的可靠表示；从 exact-kernel raw 场取得 $\eta_d$、无限尾总预算、一般交叉/角点几何以及高效奇异求积仍要分别完成。用 (A12a) 粗包整条对角带可能极昂贵，正是 A-G1 需要研究的效率问题。

### 5.3 核心有限数据及逐项资格

| 输入 | 怎样成为可证明上/下界 | 不能替代它的东西 |
|---|---|---|
| $\mu,\beta$ 与密度系数 | 明确 dyadic 或符号常数；若输入是区间，则对整个区间包围，所有核使用同一参数 | 不同程序各自舍入后默认相同 |
| 几何 | 给参数化、速度正下界、曲率/分离界、周期复制规则；必要时验证 collar | 边界点云或采样最小距离 |
| 精确 raw 场 | 固定有限密度、精确核及有限传播矩阵；先证明局部 PDE 和 $L^2$ | BIE 小奇异值、残差采样小 |
| 连续 Cauchy 缺陷 | 由同一重建算出两侧值/导数；解析条带或导数上界控制样点间误差 | 只检查离散 collocation 节点 |
| 近奇异/奇异核 | 分离解析奇异部分，给可积分余项及求积误差；或 Taylor model/区间细分 | 提高高斯阶数后两次差很小 |
| $G_+$ | 完整 Hermitian cross Gram 加核/积分/截断误差；至少对有限精确输入闭合 | 只算对角块，或把舍入后负值截成零 |
| $U_-$ | 在一个固定有限核心子域上直接给质量下界；无需证明全部尾质量 | 使用另一个场的归一化常数 |
| 无穷尾 | 证明完整 $P_\pm$ 的一个可计算范数收缩或块幂收缩，再作几何尾 | 浮点特征值模长小于一、删掉慢模态 |

一种省去大体积质量积分的方法：选定已知紧支撑 $h\in\mathcal H$，严格包围 $c=\langle u,h\rangle_\mathcal H$，令 $c_->0$ 为该复区间到零的距离、$H_+\ge\|h\|_\mathcal H$，则 $U_-=c_-/H_+$ 有效。若重叠偶然很小，换一个预先明确的有限见证函数；这不要求知道真模态。将 $h$ 支撑放在远离奇异界面的核心区域可简化评价。

### 5.4 边界算子近似误差：只控制需要的作用

设精确边界作用是 $B\xi$，数值作用为 $B_d\xi$。严格缺陷界可以用

$$
\|B\xi\|\le \|B_d\xi\|+\|(B-B_d)\xi\|.
\tag{A13}
$$

对固定输入 $\xi$，第二项只需该向量上的作用界；不必先认证整个 $B$ 的逆或全算子谱。如果坚持“真实 DtN 解”定义 raw 场，则还需认证图存在、逆界及 $\|(D-D_d)f\|_{H^{-1/2}}$，并把相应场误差传到质量/残差；这常比直接给一个任意可计算 trial 更困难。任意稳定有限传播产生的场也可使用，只要把其真实 PDE、材料和人工墙缺陷全部计入。

有限节点本身不可能给连续缺陷上界：在任意有限采样点间可放一个光滑 bump，所有样值为零而 $L^2$ 范数任意大。这不是 BIE 不能认证的结论，而是必须冻结有限函数表示或提供正则性余项的简单反例。

## 6. 无穷端：严格支付什么，哪些东西可以不证明

若第 $n$ 胞元的场/缺陷由 $T P^nc$ 给定，严格验证某个 $H>0$ 和 $0<q<1$ 满足

$$
P^*HP\le q^2H
$$

即可得到 $\|P^nc\|_H\le q^n\|c\|_H$。如果 $\|Tz\|_{\rm cell}\le C_T\|z\|_H$，则

$$
\sum_{n\ge N}\|TP^nc\|_{\rm cell}^2
\le\frac{C_T^2q^{2N}}{1-q^2}\|c\|_H^2.
\tag{A14}
$$

有限维 $H$ 与矩阵不等式均可由区间 LDL 或严格特征值界验证。此处是给定有限 trial 的尾，不是认证有限 $P$ 等于真实半波导传播算子。矩阵非正规并不破坏 (A14)，但仅有谱半径诊断不足。左右分别作证，无需有共同周期。

若直接用平滑截止 $\chi u$ 代替无限尾，体残差新增

$$
(-\Delta-\mu\rho)(\chi u)
=\chi r-2\chi'\partial_xu-\chi''u
$$

（并处理原跳跃的相应变换）。因此截止尾需要场与梯度界。硬截止则新增端墙 $a,j$，可进入 (A1)，但不能假称它已消失。靠近带边时衰减慢，任何此类尾证书都可能昂贵；这是可量化的适用边界，不是多加几层就保证成功。

## 7. 本质谱 gap：一个独立而完全有限的充分判据

谱距离上界无需先有 gap。要从它推出局域本征态存在，必须另证包含区间落在两端的共同 projected gap。下列证明说明该环节也可以从真正二维有限数据出发，而非依赖有限 $\theta$ 网格的图像。

### 7.1 本轮证明 A3：Floquet cell 的 Fourier 补空间判据

一侧周期 cell 为 $(0,a)\times(0,L)$，固定 $\beta$，沿 $x$ 的 Floquet 参数为 $\theta\in[-\pi/a,\pi/a]$。在未加权、完全周期的 $L^2$ 上写 pencil

$$
K_\theta-\lambda\rho,\qquad
K_\theta=(-\mathrm i\partial_x+\theta)^2+
(-\mathrm i\partial_y+\beta)^2.
$$

它的零点等价于加权 cell 算子的谱点。取有限矩形 Fourier 投影 $P$，$Q=I-P$，目标区间 $[b_-,b_+]\subset(0,\infty)$。若在一个 $\theta$ 小区间上已证

$$
h:=\inf_{\theta,(n,m)\notin P}
[(2\pi n/a+\theta)^2+(2\pi m/L+\beta)^2]
-b_+\rho_{\max}>0,
$$

以及 $c\ge b_+\|P\rho Q\|$，则对 $\lambda\in[b_-,b_+]$，尾块 $D=Q(K_\theta-\lambda\rho)Q\ge hI$。设有限 Hermitian 块

$$
B_\theta(\lambda)=P(K_\theta-\lambda\rho)P,\qquad \delta=c^2/h.
$$

有限 Hermitian 特征值按升序并按重数排列。若在 $\lambda=b_-,b_+$ **两端**均存在相同整数 $\ell$，使整个 $\theta$ 小区间上

$$
\lambda_\ell(B_\theta(\lambda))<0,
\qquad \lambda_{\ell+1}(B_\theta(\lambda))>\delta,
\tag{A15}
$$

（$\ell=0$ 或 $\ell=\dim P$ 时省去缺失的一侧），则该小区间的所有 cell 谱均避开 $[b_-,b_+]$。

**证明。** 精确 Schur 补 $S=B-C D^{-1}C^*$ 满足

$$
B-\delta I\le S\le B.
$$

(A15) 使 $S$ 恰有 $\ell$ 个负特征值且没有零特征值。这里 $P$ 是未加权 $L^2$ 的正交投影，与 $K_\theta$ 交换；$D$ 在 $QH^2_{\rm per}$ 上自伴且严格正。对 $x\in\operatorname{ran}P$、$y\in QH^1_{\rm per}$，完成平方给

$$
\mathfrak q_\lambda(x+y)
=\langle Sx,x\rangle+
\|D^{1/2}(y+D^{-1}C^*x)\|^2.
$$

由于 $D^{-1}C^*x\in QH^2_{\rm per}$，该三角变换保持形式域，所以完整 pencil 恰有 $\ell$ 个负方向且可逆。正密度与 cell 紧嵌入又使这个负惯性等于加权 cell 算子在 $\lambda$ 以下的本征值数；穿过任何本征值时计数按重数增加，无需假设简单根。固定每个 $\theta$，两端计数相同且端点可逆，故中间没有谱点。证毕。

**有限性。** 可保守取 $\|P\rho Q\|\le\rho_{\max}$，或通过
$P\rho Q\rho P=P\rho^2P-(P\rho P)^2$ 的有限矩阵取得更紧上界。分片材料的 Fourier 矩必须按真实几何严格积分。矩形 $P$ 外的最小动能可由坐标范围直接下界，不必遍历无限指标。

在网格中心 $\theta_0$ 认证 $B$ 后，用

$$
\|B_\theta(\lambda)-B_{\theta_0}(\lambda)\|
\le\max_{(n,m)\in P}
\big(2|2\pi n/a+\theta_0|\,d_\theta+d_\theta^2\big)
\tag{A16}
$$

覆盖 $|\theta-\theta_0|\le d_\theta$。有限覆盖 Brillouin 区，左右各做一次，即为整个共同 bulk gap 的充分证书。该粗界可能需要很大 $P$；本轮没有证明最佳复杂度，也没有实际认证目标 gap。Schur 补认证本身是已有方法，本文贡献只是对正密度 pencil 的明确、自足适配。

### 7.2 从 bulk gap 到原无限接口算子

若 $\rho$ 在有限中心之外**精确等于**两侧周期模板，则通常的紧局部扰动/截断 parametrix 论证给

$$
\sigma_{\rm ess}(A)=\sigma(A_-^{\rm per})\cup\sigma(A_+^{\rm per}).
\tag{A17}
$$

其证明义务不能靠浮点 band plot 代替：在端 resolvent 集用周期全线 resolvent、中心有界域 parametrix 和 cutoff 拼接；交换子只支撑有限条带，局部 $H^2\to H^1$ 的紧嵌入使余项紧，给 Fredholm 性。反向用两端 Bloch 波的远移长 cutoff 构造 Weyl 序列。加权空间必须通过一致的范数等价/弱 pencil 处理，不能把两个不同权重 Hilbert 空间的算子直接相减。本轮给出这一标准证明路线而不宣称重审了仓库归档附录的每一步。

因此 (A17) 的适配审核与 (A15) 的实际验证是两个独立门。若 $[\mu-R,\mu+R]$ 严格落在已认证共同 gap，谱距离证书才升级为至少一个孤立有限重本征值的存在。**唯一性**仍需连续计数或另一套隔离论证，不能从小 $R$ 推出。

若报告波数距离且 $R<\mu$，使用
$R_k=R/[\widehat k+\sqrt{\mu-R}]$；这仍不是某个已编号唯一模态的误差。

## 8. 与外部文献的精确关系

| 文献/本轮核查 | 已解决的范围 | 本文不能据此省略的部分 |
|---|---|---|
| Barnett–Hassell, *Boundary quasi-orthogonality and sharp inclusion bounds for large Dirichlet eigenvalues*, SIAM J. Numer. Anal. 49 (2011), 1046–1063；[公开全文](https://arxiv.org/pdf/1006.3592)，Thm 1.1，PDF pp. 2–4、§6 | 有界分片光滑域、Dirichlet Laplacian 的边界 tension 与谱包含；高频权重能显著影响界的锐度 | 不直接覆盖无限异质加权波导、内部材料传输和无穷尾；不能移植未评价常数 |
| Dahne–Salvy, *Computation of Tight Enclosures for Laplacian Eigenvalues*, SIAM J. Sci. Comput. 42 (2020), A3210–A3232，[DOI](https://doi.org/10.1137/20M1326520)、[全文](https://arxiv.org/pdf/2003.08095)，Thm 1，§§2.1–2.3 | MPS 的连续边界上界与内部范数下界，通过区间/Taylor 模型形成真正证书；索引另证 | 不覆盖本波导，但证明“候选生成无需认证、后验函数评价必须认证”的研究组织已成熟 |
| Herbst–Levitt–Cancès, *A posteriori error estimation for the non-self-consistent Kohn–Sham equations*, Faraday Discuss. 224 (2020), 227–246；[全文](https://arxiv.org/pdf/2004.13549)，§V，PDF pp. 5–6 | planewave 有限/无限块分解、Schur 惯性与补空间控制；还区分截断、迭代与舍入 | 本文 A3 需保留 $-\lambda\rho$ 广义 pencil、真实材料积分和全 $\theta$ 覆盖，不能照搬赝势数据 |
| [[research/explorations/interface-threshold/research_landscape|首轮文献：Cances2020、Boulton–Levitin、Engström 等]] | 保证界、二阶谱或 NEP 的各种条件框架 | $D(A)$、隔离/补空间、无限端与实际输入条件不能由有限矩阵替代 |

以上新增在线文献本轮阅读了相关正文，未下载新 PDF，也未修改 `ref/`。书目不是完整优先权检索；边界 Gram 评价路线仍需针对 Yukawa 层势/负阶边界范数的专题查重，不能宣布首次。

## 9. 可以成为论文的命题与最小下一门

**独立算法问题 A-G。** 对解析或可认证 $C^2$ inclusion、两侧不同周期模板、有限 exact-kernel 边界密度与经认证稳定的有限传播尾，构造完全有限的 (A12)，证明它收敛到同一无限 raw 场的修正范数，给出误差预算和达到给定绝对半径的条件。核心不是 (A6)，而是保留 cross Gram、曲面 log 核、无穷胞元与 Fourier 尾的共同评价定理。

可分三门，均先理论：

1. **A-G1，直墙＋有限曲线。** 固定密度系数，推导曲面/墙全部 Gram 块的局部奇异分解和有限余项；用 (A8) 作符号校准。不能把只在圆形成立的 Kress 精确性推广到五瓣曲线。
2. **A-G2，无穷周期尾。** 用 (A14) 结合 (A7) 给有界尾，并证明保留块的极限；再研究平移不变 Gram 与 Stein/几何和能否更便宜。必须计入完整 $P$，不删慢模态。
3. **A-G3，分辨率门。** 先分开同一证书的理想极限值与可下降的评价误差。只有证明同一 raw 场、同一 $t$ 和同一公式的理想极限半径超过目标，才能断言仅细化评价无法使该证书达标；一个偏宽的上界不提供这种否证，也不能排除别的证书。随后独立认证共同 gap，不以它阻断最初的全谱距离证书。

最低成本的未来实验应冻结**同一真实二维 BIE raw 场**，只比较 I6 统一迹界与 (A12) 的边界评价，记录逐项预算和资源；不换 candidate、不用 BIE 参考差作真误差。此处仅提出设计，不创建或运行实验。若只得到旧界的昂贵重写，就否决 A-G，而非继续堆积精度。

## 10. 证明与研究状态

- **本轮严格证明：** A1 的分布修正/定义域/归一化界；A2 的单墙权重及 (A10)；A3 的 cell Fourier 补空间充分判据；A4 在明确有限可计算几何/数据条件下的 Gram 收敛包围。它们是自足适配与表示结果，不预设原创优先权。
- **此前已证或已有：** I6 对偶界及特定证书；I9 源平滑；外部有界域 MPS、Schur 谱界。
- **本轮未完成：** 五瓣真实材料上完整 (A12) 的可执行评价定理、目标 raw 场上的严格半径、(A17) 的完整适配复核、实际全 $\theta$ gap 证书及连续唯一性。
- **可能失败：** raw 本身缺陷太大；曲面/尾的保守余项盖过收益；高对比材料使 $C_t$ 过大；近阈值慢衰减使尾成本失控；Gram 相消在粗区间算术中丢失。

证明工作采用 `rigorous-proof` 的 **Proof from scratch** 模式，位置为本文件命题 A1、引理 A2、命题 A3、命题 A4；用户授权的其余内容是研究分析、文献核对与设计。没有覆盖旧证明。统一开放项与独立审查结果见 [[research/explorations/interface-threshold/STATUS]]；优先级见 [[research/explorations/interface-threshold/research_priority_decision]]。
