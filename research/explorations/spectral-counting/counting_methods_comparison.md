# 二维周期 Helmholtz 波导的三条计数路线

日期：2026-10-28。目标是固定 $\beta$ 后的 $N_A(I)=\operatorname{rank}\mathbf1_I(A(\beta))$，$I=(a,b)$，**不预设计数为一**。研究主体始终是二维、左右可异质的周期端和有界中心缺陷。当前已有全谱距离估计、BIE／FEM 候选吻合和 FEM 的速度优势，均作为背景接受，不在本轮重做。

**推荐 A：完整中心 DtN 二次型的端点 Morse 指标差。** 用严格 FEM 包围或补空间估计做其认证后端；A 与 B 因而可以组合。C 保留为有易认证参考算子的特殊模型方案。连续计数结构已有成熟基础，主要研究机会在可验证的有限计算。

## 1. 共同模型与评价口径

$A=-\rho^{-1}\Delta$ 作用于 $L^2(\rho)$，闭形式为 $\int|\nabla u|^2$，形式域 $H^1_\beta(\mathbb R\times(0,L))$。$0<\rho_{\min}\le\rho\le\rho_{\max}$；材料在中心之外分别为 $\rho_\pm$。这是质量加权 Helmholtz，不是 $-\operatorname{div}(\rho^{-1}\nabla)$。精确定义及法向约定见 [[research/explorations/spectral-counting/minimal_counting_theorem]]。

所有路线都需要：共同 projected gap 的连续证明；端点不在目标谱中；重数完整计入；有限维结果与连续空间之间的可靠连接。内部 gap 下全无限波导通常在区间下方已有无限维谱子空间，不能把两个无穷总数相减。有限 box 结果也不自动获得正确编号。

## 2. A：DtN Morse index／spectral flow

对两侧平方可积 Poisson 延拓 $P_\pm(\mu)$ 及从 lead 指向中心的 DtN $D_\pm(\mu)$，在完整中心空间 $V=H^1_\beta(C)$ 定义

$$
t_\mu[u,v]=\int_C\nabla u\cdot\overline{\nabla v}
-\mu\int_C\rho u\bar v+
\sum_{\sigma=\pm}\langle D_\sigma(\mu)\gamma_\sigma u,\gamma_\sigma v\rangle.
$$

只要区间内两端半波导 Dirichlet 算子无谱，DtN 解析；其导数给出

$$
t'_\mu[u,u]=-\|u\|_{L^2(C,\rho)}^2-
\sum_\sigma\|P_\sigma(\mu)\gamma_\sigma u\|_{L^2(E_\sigma,\rho_\sigma)}^2<0.
$$

每个 $t_\mu$ 有有限负指数，精确核与全域本征空间同构，故

$$
N_A((a,b))=n_-(t_b)-n_-(t_a).
$$

**已有理论。** Fliss 2013 的本质谱、精确 DtN 约化、Gårding 和 min–max 结构已具备核心输入；2014 数值论文明确处理不同周期端，并给出负尾部质量导数。主文件给出直接 crossing 证明，避免把某个有限 deficiency 抽象结论未经验证套到无限迹空间。并不把显示公式尚未定位到原文视作创新证据。

**极点与隐藏模态。** bulk gap 不排除半条带 Dirichlet 表面态；DtN 可在其处有极点，端点负指数差不能无修正跨过。中心 Dirichlet poles 不影响完整中心形式，只影响额外的中心消元图。两端正则时精确核双射已经包括所有模态；不能再凭空添加“可能隐藏”的例外，也不能漏记内部块后声称已经保持重数。所有负 crossing 按核维数计，重根原则上不构成障碍。

**从有限到连续。** 两端都要认证完整中心负指数，至少证明未解析空间为正并控制它与有限空间的耦合。另需真实 DtN 误差、材料积分误差和有限矩阵符号证书。详见 [[research/explorations/spectral-counting/continuous_vs_discrete_gap]] 的 C1，而非单纯对矩阵做区间 LDL。

**难度和成本。** 连续无极点定理难度低到中；可靠 DtN 与补空间正性难度中到高。数值探索只需两个端点，各做两侧响应及中心惯性分解，无需密集扫频或精确 root。完整中心 LDL 的填充成本高于墙面特征值计算，但不必恢复场或求 Stein 尾部质量。认证难度由端点到零的谱余量决定，而不是候选波数的第十二位小数。

## 3. B：严格 FEM 上下界及谱排除

最直接适配当前问题的 B，并非对无限 $A$ 生搬“前 $j$ 个本征值”，而是在每个端点 $e\in\{a,b\}$ 上定义有界中心的自伴算子 $L_e$：

$$
t_e[u,v]=\lambda\int_C\rho u\bar v,\qquad u,v\in V.
$$

精确 DtN 下，此形式有 Gårding 不等式，$L_e$ 下半有界且紧预解式。若按重数编号的严格包围满足

$$
\lambda_r(L_e)\le U_r<0<L_{r+1}\le\lambda_{r+1}(L_e),
$$

则 $n_-(t_e)=r$。$r=0$ 时只需第一特征值的正下界。这实际上成为 A 的严格后端。

相容 Rayleigh–Ritz 给上界，足以证明“至少这些负方向”；邻接连续特征值的下界才给穷尽性。Lehmann–Goerisch、非相容 FEM 的修正下界及平衡通量方法有成熟先例，但必须核对权重、准周期边界、非局部 DtN、可靠源问题常数和索引起点。不能把用于多边形 Dirichlet Laplacian 的显式常数直接搬到本问题。

另一种 B 是在有限截断域上包围特征值。此时必须另证 artificial boundary／超胞不会引入端部或第二界面模态，并量化到真实无限算子的连接。内部 gap 的有限截断谱污染与编号遗漏是真问题；“有限 FEM 所有特征值都经过严格矩阵包围”仍不解决它们。二阶谱等 anti-pollution 方法可保证靠近某个真实谱点，但不单独给出区域内所有模态已找齐；其试探空间要求也不能忽略。

**成本。** 若把 B 用在 A 的两个中心端点上，物理输入高度复用。额外代价是辅助通量／源问题、下一本征值下界及 Gram 常数。若从有限 box 独立开展 B，则需要更多域扩大和边界控制，且可能重复 A 已处理的无限尾部问题。严格包围可处理簇与重根，但簇外隔离条件不能由同一组未经认证的 Ritz 值自证。

## 4. C：Birman–Schwinger 紧算子计数

先选择参考密度 $\rho_0$，要求 $0<\rho_{0,\min}\le\rho_0\le\rho_{0,\max}<\infty$，**共享两侧全部无限尾部**，且中心质量差 $w=\rho-\rho_0\in L^\infty$ 非负、紧支撑。在 $\mathcal H_0=L^2(\rho_0)$ 上令

$$
A_0=-\rho_0^{-1}\Delta,\qquad W=w/\rho_0,
\qquad K(\mu)=\mu\sqrt W(A_0-\mu)^{-1}\sqrt W.
$$

假设 $[a,b]\subset\operatorname{res}(A_0)$。局部椭圆正则性和紧支撑给出 $K(\mu)$ 紧、自伴、解析。加权方程等价于 $(A_0-\mu)u=\mu Wu$，所以 $\mu$ 是目标本征值当且仅当 $1$ 是 $K(\mu)$ 的本征值，并保持重数。这里不需要 $K\ge0$；在内部 gap 中它一般不是正算子。

**条件计数推导。**

$$
K'(\mu)=\sqrt W A_0(A_0-\mu)^{-2}\sqrt W\ge0.
$$

在 $1$ 的本征子空间上 $\sqrt W f\ne0$；而 $\ker A_0=0$，因为无限条带上的零能量平方可积函数不能有非零常数值。因此导数在该子空间严格正。紧算子阈值 $1$ 的有限维 crossing 论证给出

$$
N_A((a,b))=n_>(1,K(b))-n_>(1,K(a)).
$$

这是明确假设下的标准 BS 机制推论，不声称首创。若 $K_N$ 为有限秩自伴近似，且两个端点都有

$$
\|K-K_N\|\le\delta<\operatorname{dist}(1,\sigma(K_N\oplus0)),
$$

则两个整数由有限计算认证；此处补零是允许的，因为 $K$ 本身紧，而不是一阶 DtN。需要控制整个算子及未解析补空间，不能只包围矩阵条目。

**额外条件和危险。** 若参考取单一左侧晶体，右半无限区域一般不是紧支撑扰动，不能继续使用上述紧性。共享异质尾部的参考接口自身可能有 gap 模态，使 $K$ 有极点；必须认证参考无谱或加入参考谱的相对计数。若 $w$ 变号，简单的 $n_>(1,K)$ 不适用；可考虑 $J-\mu\sqrt{|W|}(A_0-\mu)^{-1}\sqrt{|W|}$ 的相对惯性，其中 $J=\operatorname{sign}W$，但需另证带参数质量问题的连接。

**已有理论与成本。** Brown–Hoang–Plum–Wood 2015 已有同型加权周期缺陷 BS 算子；Pushnitski 2009 提供 gap 中相对指数和一般 BS 计数。前者背景是同一周期晶体；后者的固定加性扰动定理不能不经处理套给含 $\mu$ 的质量扰动。对同背景参考，Bloch 预解式可能可复用；对异质参考，先认证参考预解式可能接近原任务难度。C 不因“只需两个端点”就必然比 A 便宜。

## 5. 三条路线的选择表

| 项目 | A：DtN 端点指数 | B：严格 FEM 包围 | C：紧 BS |
| --- | --- | --- | --- |
| 连续计数对象 | 完整中心形式的有限负指数 | 明确连续紧预解式问题的逐索引谱包围 | 共享尾部参考的紧算子阈值计数／相对指数 |
| 已有理论成熟度 | 高；当前无极点情形是标准推论 | 高；边界与索引条件需适配 | 高；正质量同背景尤成熟 |
| 当前主要缺口 | 精确端点惯性的有限认证 | 下一连续特征值下界、DtN 与无限尾部连接 | 参考谱排除和全算子范数误差 |
| pole 来源 | 半条带 Dirichlet；中心消元图另计 | 继承所用约化的 pole | 参考 $A_0$ 的本征值 |
| 谱污染／漏根 | 完整连续形式无遗漏；离散仍须补空间证书 | 有限 box 可污染；Ritz 单向不能穷尽 | 精确紧 BS 无额外根；截断需全算子误差 |
| 重数 | 核维数直接计入 | 严格簇包围可处理 | 阈值重数直接计入 |
| 初步数值成本 | 两端四次 lead 响应＋中心稀疏惯性 | 端点模式可与 A 复用，辅助认证较多 | 参考 Green 应用、紧矩阵及范数界 |
| 本项目优先级 | **首选** | **作为 A 的认证后端** | 特殊参考易验证时备选 |

## 6. 指定文献与邻近文献的全文核对记录

以下页码指本地版本，不混用期刊页码；完整出版元数据和公开来源已入 `ref/README.md`、`ref/reference.bib`。本轮不是系统穷尽检索，不能据此宣称某种算法“首次”。

### Fliss 2013 与 FEM＋DtN 2014

Sonia Fliss, *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides*, [DOI](https://doi.org/10.1137/12086697X)，[本地全文](/Users/whc/Documents/Work/TEP_ref/Fliss2013.pdf)。核对 Prop.3.1、Thm.4.1、Thm.4.5、Lemma4.7、Prop.4.8、Thm.4.9、Prop.4.10：本质谱、半条带例外、精确核及重数、Gårding／min–max 均已提供。所需输入是正权重、周期端、gap 与半条带正则性，不是有限矩阵恰好可逆。

Dirk Klindworth, Kersten Schmidt, Sonia Fliss, *Numerical Realization of Dirichlet-to-Neumann Transparent Boundary Conditions for Photonic Crystal Wave-Guides*, [DOI](https://doi.org/10.1016/j.camwa.2013.03.005)，[本地全文](/Users/whc/Documents/Work/TEP_ref/Klindworth2014.pdf)。本地为 2013-02-08 作者稿。§2.1/PDF p.2 明确不同周期端；Prop.2.1/p.4 给本质谱并集；Thm.3.4、Eq.(8)–(10)/p.6 给完整中心形式；Thm.3.11、Cor.3.12、Remark3.13/p.9 处理正则频率微分；Eq.(36)/p.13 给负尾部质量；§7.4/p.26 有异质算例。不能再把“二维异质端 exact DtN 是否可行”作为新问题。

### Hoang–Plum–Wieners 2009

Vu Hoang, Michael Plum, Christian Wieners, *A Computer-Assisted Proof for Photonic Band Gaps*, [DOI](https://doi.org/10.1007/s00033-008-8021-2)，[KIT 全文](https://publikationen.bibliothek.kit.edu/1000007941/246229)。本地 `Hoang2009.pdf` 是 KIT 2008/5 预印本，PDF 页比正文页多 2。

Theorem1/正文 p.4 为相容 Ritz 上界。Theorem2/pp.4–5 的 Goerisch 下界需要 $H(\operatorname{div}_k)$ 通量、下一连续本征值的先验下界及辅助矩阵正定／符号条件。§4/pp.6–8 从常密度 Fourier 谱及密度同伦建立索引起点。Lemma6、Theorem7/pp.9–10 给参数扰动覆盖。其正有界周期权重模型与本项目 bulk 匹配；固定 $\beta$ 后逐侧覆盖一维横向参数即可。**它认证 bulk gap，不直接计数无限缺陷波导。**

### Berkolaiko–Cox–Latushkin–Sukhtaiev 2026

Gregory Berkolaiko, Graham Cox, Yuri Latushkin, Selim Sukhtaiev, *The Duistermaat Index and Eigenvalue Interlacing for Self-Adjoint Extensions of a Symmetric Operator*, JST 16(1), 1–49, [DOI](https://doi.org/10.4171/JST/590)，[正式全文](https://ems.press/content/serial-article-files/52264?nt=1)。

Thm.1.2/p.5 的区间计数继承有限且相等 deficiency 的假设；§5/p.24 明确恢复有限维辅助空间。不能把无限 $H^{1/2}\oplus H^{-1/2}$ 端口直接当成这个定理的实例。另一方面，§4 **确实允许无限维**：Thm.4.1/p.19、Cor.4.3/p.22、Prop.4.5/pp.22–23 分别给 Cauchy 数据解析性、质量 crossing form、Lagrangian／单调性。Lemma5.1/p.24 明确保留隐藏内解项，其在相对计数中抵消。正确评价是：有相关的无限维结构，但指定计数定理不能未经条件核对整体移植。

### 无限维边界指数的较早先例

Graham Cox, Christopher K. R. T. Jones, Jeremy L. Marzuola, *Manifold Decompositions and Indices of Schrödinger Operators*, [DOI](https://doi.org/10.1512/iumj.2017.66.6129)，[arXiv v2](https://arxiv.org/pdf/1506.07431)。本地 `Cox2017.pdf` 19 页。Thms.1–3、Cor.1/PDF pp.4–5 在紧流形／有界分解、适当椭圆边界条件下将 Morse、Maslov 和 DtN 联系，使用真正的无限维 Sobolev 迹空间。这里核对到的是理论先例；它的有限全局 Morse 数不能直接用于内部 gap 的无限波导。SC1 通过完整有界中心形式避开该问题。

### 严格包围与谱污染

Carsten Carstensen, Joscha Gedicke, *Guaranteed Lower Bounds for Eigenvalues*, [DOI](https://doi.org/10.1090/S0025-5718-2014-02833-0)，[作者全文](https://ins.uni-bonn.de/media/public/publication-media/CG_2014.pdf?pk=1442)。本地为 29 页作者稿。Thms.3.1–3.2/p.6 通过 CR 修正取得下界，而非原始非相容值自动为下界；Thm.5.1/pp.16–17 的高阶索引需网格及谱分离条件。模型为有界多边形 Dirichlet Laplacian；本项目必须重核权重和边界。

Eric Cancès, Geneviève Dusson, Yvon Maday, Benjamin Stamm, Martin Vohralík, *Guaranteed A Posteriori Bounds for Eigenvalues and Eigenvectors: Multiplicities and Clusters*, [DOI](https://doi.org/10.1090/mcom/3549)，本地 `Cances2020.pdf`。Assumptions4.2、4.4/p.14 需要簇外隔离，包含下一连续本征值的可靠下界；Thm.5.3/p.24 允许簇内重根；§6.1/p.29 说明下界来源。不能用未知谱分离循环证明自己的计数完整性。

Lyonell Boulton, Michael Levitin, *On Approximation of the Eigenvalues of Perturbed Periodic Schrödinger Operators*, [arXiv 全文入口](https://arxiv.org/abs/math/0702420)，本地 `Boulton2007.pdf`。Cor.2.5/p.6 是二阶谱到真实谱的包含结论，不能单独证明区间内唯一或全部模态已找到；其算子定义域试探空间也不等于普通 $H^1$ FEM 空间。

### Birman–Schwinger 和 gap 内相对计数

B. M. Brown, V. Hoang, M. Plum, I. Wood, *On the Spectrum of Waveguides in Planar Photonic Bandgap Structures*, [DOI](https://doi.org/10.1098/rspa.2014.0673)，本地 `Brown2015.pdf` 为 2012 预印本。§4 Eq.(16)、Lemmas2–3/pp.7–8 已有相同质量型 BS 紧算子与单调性；Theorem3/p.18 的固定 Bloch 不积聚结果使用同一周期背景。它不是任意异质端的 validated 整数计数。

Alexander Pushnitski, *Operator Theoretic Methods for the Eigenvalue Counting Function in Spectral Gaps*, [DOI](https://doi.org/10.1007/s00023-009-0422-z)，[全文](https://arxiv.org/pdf/0809.4365)。本地 v1 的 Thm.3.1/p.10 对下半有界自伴算子和相对形式紧的 $G^*JG$ 扰动建立广义 BS 指数；$J$ 需有界自伴且可逆。Cor.3.2/p.11 给目标与参考的区间计数差；Lemma3.4/p.12 保持核维数；Thm.2.3/p.6 的范数预解式稳定性没有提供本项目可计算截断阈值。§4 中的质量型参数推导不能用“固定加性扰动”一句话略去。

## 7. 本轮结论的边界

连续无极点计数不缺一个全新的抽象理论。仍未由这些来源替当前算例完成的是：两侧完整参数 gap 证书、half-guide pole 排除、精确端点惯性的有限验证。后两者的实现不能用最新 Cauchy 数据理论的名称替代。最值得先推进的证明缺口与本轮已完成的可行性实验见 [[research/explorations/spectral-counting/novelty_and_feasibility]] 和 [[research/explorations/spectral-counting/claude_experiment_spec]]。
