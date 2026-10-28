# 数学自由探索：连续谱、异质接口与阈值

检索与核验日期：2026-10-28。范围是研究问题发现，不是系统综述，也不是现有论文的补证任务。先定向核对本地理论、源码和最新审查，再检查本地文献及公开原始全文；没有遍历失败历史。

主要选择是研究**异质接口的阈值共振如何控制弱材料缺陷的出现阈值、模态数及频率尺度**。领域中已有弱缺陷、阈值共振、谱流和无污染理论；本轮不把这些主题本身称新发现。十四个问题及三项筛选见 [[research/explorations/interface-threshold/candidate_problems]]，实际证明见 [[research/explorations/interface-threshold/deep_investigation]]。

## 1. 当前问题的证据基线

### 1.1 只需要这些当前证据

| 已检查材料 | 确认的内容 | 不能据此推出 |
|---|---|---|
| `research/projects/eig-apost/phase3-analysis/fem-bound/s-enrich.md`，§§1–6 | 正材料加权自伴算子，固定准周期参数；真材料质量进入中心与两侧 lead；无限重复 FE 空间上的完整质量导数 | 一般连续 DtN 全 gap 正则、连续唯一模态、饱和性 |
| 同目录 `r-enrich.md`；`implementation/i10/review-10-1a.md`、`review-10-2a.md` | 条件估计的理论和数值资格边界 | 由普通浮点核查得到总评价误差界 |
| `test/i10/refine-v1/refine_i102.m`：1743、1953–1967、2476–2477、2548 附近 | 真实质量实际装入方程；Dirichlet 图病态时拒绝；`S_verified=false`、`E_certified=false` 始终保留 | 程序输出已认证，或已实现换图 |
| `test/i10/refine-v1/output/attempt-1/summary-01/table.csv` | 下表三组结果与审查一致 | 对 BIE 的差是实际连续误差 |

上述路径以 `/Users/whc/Documents/Work/epost/` 为根。入口：[[research/projects/eig-apost/implementation/i10/review-10-2a|I10.2 审查]]、[[research/projects/eig-apost/phase3-analysis/fem-bound/s-enrich|当前富化理论]]。本轮只读取，未重新执行源码或加载并重算 MATLAB 结果。

| 网格 | P4 candidate $k$ | 条件最大 $k$ 半径 | 对 BIE 的普通数值差 |
|---|---:|---:|---:|
| g12 | 1.5584378957007303 | $1.3287803050\times10^{-7}$ | $1.5186394364\times10^{-9}$ |
| g24 | 1.5584378942105757 | $4.4394560680\times10^{-9}$ | $2.8484770098\times10^{-11}$ |
| g48 | 1.5584378941804409 | $3.1451003534\times10^{-10}$ | $1.6500134592\times10^{-12}$ |

这些半径使用 $q=1/2$ 和 $\epsilon_3=\epsilon_4=10^{-10}$（$\mu$ 尺度）的假设。网格间重剖分不是嵌套 $h$ 族；g24/g48 的 BIE 差已经小于声明的评价预算，不能据此声称相应位数的连续精度。现有路线给出了有分辨力的条件结果，其不足并不意味着算例错误。

### 1.2 由证据提出的结构问题

1. 从“一个 candidate 有多准”转向“模态为什么出现、何时不出现、会出现几个”。这可以产生独立存在/非存在定理，不必以认证为唯一终点。
2. 公共 projected gap 控制 bulk 传播，不保证被切开的半波导没有表面态；DtN 是局部坐标，不是处处可用的对象。
3. 完整质量导数说明频率响应有结构，但不能单独替代谱正确性、目标对应或阈值展开。
4. 真材料修正使离散族针对正确模型，却不自动保证穿元场的高阶光滑性或固定饱和率。
5. 固定 $\beta$ 的 fiber eigenvalue 与完整二维算子的孤立点谱不是同一对象。离开沿缺陷周期性后，需要重新定义目标。

## 2. 领域地图

| 研究簇 | 核心对象与工具 | 已有可靠先例 | 对本项目最有价值的缺口 |
|---|---|---|---|
| 连续自伴谱与谱污染 | 加权形式、局部紧性、gap 内投影、谱投影修正 | Boulton–Levitin；Cancès–Ehrlacher–Maday | 异质闭合中的第二界面及质量逃逸；原生形式域数据能支持哪些声明 |
| 谱包含与严格计算 | 二阶谱、shifted resolvent、簇界、补空间估计 | Boulton–Levitin；Cancès 等 2020 | 选对连续定义域/簇外信息，再考虑可计算误差；不能直接平方 FEM 刚度矩阵 |
| exact DtN 与 NEP | 周期半导、Riccati、Cauchy 关系、RtR | Joly–Li–Fliss；Fliss；Fliss–Klindworth–Schmidt | 半导极点、零迹态、有限迹空间到连续计数的桥接 |
| Weyl / Herglotz 与谱流 | Poisson 导数、Schur 补、meromorphic index、Maslov | Behrndt 等；Cox–Jones–Marzuola | 无限内部 gap 不能直接相减两个全域 Morse 指数 |
| 弱缺陷与 BS | 局部 resolvent 奇异项、带边有效质量、耦合秩 | Brown 等；Duchêne 等 | 异质接口先决定是否有共振，再决定弱缺陷是否可用 |
| 阈值共振 | 有界阈值解、加权空间、Puiseux/Jordan 链 | Nazarov；Pankrashkin | 分片质量、不同周期端、内部公共 gap 的显式系数与统一条件 |
| 结构保持降阶 | 谱测度、rational Nevanlinna pencil、Gauss–Radau | Engström–Langer–Tretter；Zimmerling 等 2025 | 将内部 gap 变换到适用正定框架，控制未保留的谱测度 |
| 界面、位错与拓扑 | 半线 Weyl 匹配、位错谱流、bulk-edge | Korotyaev；Hempel 等；Drouot；Craster–Davies | 拓扑保护需具体对称/族假设；不是任意两种正材料接口的属性 |
| 超出 Bloch fiber | 无理方向、准周期提升、随机/局部缺陷的通道耦合 | Amenoagbadji–Weinstein 2026 的近期预印本 | 研究对象本身改变；近似边缘态不能冒充原算子精确本征态 |

地图的作用是区分数学机制与可发表问题。大部分单个工具已经成熟；潜在贡献需要落在明确模型、适配条件、反例或算法信息合同上。

## 重要参考文献与适用条件

核验标识：**F**＝原文相关结果及条件已检查（不表示逐页全部读完）；**M**＝仅原始出版页/摘要或引言，不能作为本文证明的外部定理；**L**＝本地原始全文。没有将二手综述当作专门定理的唯一来源。

### A. 最接近所选问题

**[R1] Brown, B. M.; Hoang, V.; Plum, M.; Wood, I. (2015). _On the spectrum of waveguides in planar photonic bandgap structures_.** Proceedings of the Royal Society A 471, 20140673. [DOI](https://doi.org/10.1098/rspa.2014.0673)，[公开预印本](https://arxiv.org/abs/1204.0998)。F+L，`TEP_ref/Brown2015.pdf`。Theorem 1、Lemma 2：正加权 Laplacian、同一双周期正有界背景、固定准周期 fiber；非负条带缺陷在正测度集合上严格正。以原文记号，gap 为 $(\mu_0,\mu_1)$，小量条件为 $\|\varepsilon_1\|_\infty<(\mu_1-\mu_0)\inf\varepsilon_0/\mu_0$，给出 gap 内本征值。**不能直接处理非局部的左右背景替换**。出版年是 2015，预印本始于 2012，不能写成 2013。

**[R2] Brown, B. M.; Hoang, V.; Plum, M.; Radosz, M.; Wood, I. (2017). _Gap localization of TE-modes by arbitrarily weak defects_.** Journal of the London Mathematical Society 95(3), 942–962. [DOI](https://doi.org/10.1112/jlms.12046)，[全文](https://arxiv.org/abs/1511.03723)。F+L，Theorem 2.1：正有界介电系数、非负且在球上严格正的缺陷和定量小扰动条件。主算子是**散度型 TE**，不是本文的质量扰动；允许不连续系数不能解释为两种算子证明自动相同。

**[R3] 同上五位作者 (2020). _Gap localization of multiple TE-Modes by arbitrarily weak defects_.** Journal of the London Mathematical Society. [DOI](https://doi.org/10.1112/jlms.12337)，[预印本](https://arxiv.org/abs/1901.05102)。F+L。已核预印本 Theorem 3；期刊编号对应 Theorem 6.4。有限带边接触、二次非退化和正缺陷条件下，给小扰动产生的模态数。**多带计数不是空白**；异质接口的共振兼容性才是这里的新增问题位置。

**[R4] Duchêne, V.; Vukićević, I.; Weinstein, M. I. (2015). _Homogenized description of defect modes in periodic structures with localized defects_.** Communications in Mathematical Sciences 13(3), 777–823. [DOI](https://doi.org/10.4310/CMS.2015.v13.n3.a9)，[作者全文](https://duchene.pages.math.cnrs.fr/publication/duchenevukicevicweinstein15/DucheneVukicevicWeinstein15.pdf)。F+L。Theorem 3.4，印刷 p.787/PDF p.11：一维连续周期势，局域有界且有一阶矩的扰动；带边曲率与 Bloch 加权扰动积分异号。得到二次 detuning、有效包络和规定邻域内的唯一性；原文余项是 $O(\varepsilon^{2+1/4})$。它不是同作者关于快速振荡局域扰动的另一篇 2015 论文。

**[R5] Hempel, R.; Kohlmann, M.; Stautz, M.; Voigt, J. (2015). _Bound states for nano-tubes with a dislocation_.** Journal of Mathematical Analysis and Applications. [DOI](https://doi.org/10.1016/j.jmaa.2015.05.040)，[全文](https://arxiv.org/abs/1412.6420)。F+L，Theorems 1.1–1.2。圆柱左右两个有界实势、给定能量位于两者 resolvent，另有半圆柱本质谱条件；存在一列位移参数使该能量成为接口本征值，并研究位移连续性。不是任意固定接口的弱中心缺陷结论；原文周期圆柱条件与任意 $\beta$ 的适配未核定。

**[R6] Korotyaev, E. (2005). _Schrödinger operator with a junction of two 1-dimensional periodic potentials_.** Asymptotic Analysis. [DOI](https://doi.org/10.3233/ASY-2005-716)，[全文](https://arxiv.org/abs/math/0507295)。F+L，Theorem 2.1 及 §2。两种一维周期势接合，连续谱为背景谱并集，离散谱位于共同 gaps，每 gap 至多两个特征值，并有位移/带边分析。“异质界面”本身不是新题；一维的至多两个不能直接搬到多通道条带。

**[R7] Pankrashkin, K. (2017). _Eigenvalue inequalities and absence of threshold resonances for waveguide junctions_.** Journal of Mathematical Analysis and Applications 449, 907–925. [全文](https://arxiv.org/pdf/1606.09620)。F，v2，Theorem 3、Lemma 5（PDF p.4）。Dirichlet 星形波导、有限柱状分支、底阈值：有 bounded threshold resonance 时，任意非空有界开集上的任意弱负势产生额外低于阈值的本征值。中心混合 D/N 谱给无共振判据。底谱 min–max 不能直接搬到内部 gap，但这是对宽泛新颖性主张的直接先例。

**[R8] Nazarov, S. A. (2020). _Threshold resonances and virtual levels in the spectrum of cylindrical and periodic waveguides_.** Izvestiya: Mathematics 84(6), 1105–1160. [DOI](https://doi.org/10.1070/IM8928)，[公开全文](https://www.mathnet.ru/php/getFT.phtml?jrnid=im&paperid=8928&what=fullteng)。F。Proposition 4.1，pp.1133–1134：几何单重、不可延长长度 $\kappa$ 的 Jordan 链对应 $|\delta|^{1/\kappa}$ 尺度，只有特定情形是平方根。§§5.1–5.2 的一个圆柱出口、底阈值、唯一 bounded 解、无低谱设定中，区分非衰减共振的二次位移与阈值 $L^2$ 态的一次位移；弱谱趋近阈值也要求有界解。作者明确将部分渐近作为已知机制的形式推导。不能把全部周期退化分类压缩成一个无条件二次律。

**[R9] Nazarov, S. A. (2017，英文版). _Almost standing waves in a periodic waveguide with a resonator, and near-threshold eigenvalues_.** St. Petersburg Mathematical Journal 28(3), 377–410. [DOI](https://doi.org/10.1090/spmj/1455)，[原始记录](https://www.mathnet.ru/php/archive.phtml?jrnid=aa&option_lang=eng&paperid=1496&wshow=paper)。M。周期 Dirichlet 几何波导的 almost-standing waves 与局部壁面扰动。**本轮未核全文定理，仍是最需要补读的近邻来源**；不能声称已排除其覆盖拟议推广。

### B. DtN、谱流、非线性谱与降阶

**[R10] Fliss, S. (2013). _A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides_.** SIAM Journal on Scientific Computing. [DOI](https://doi.org/10.1137/12086697X)。F+L，`Fliss2013.pdf`。Theorem 4.1：gap 内一般仍有半导 Dirichlet 例外；反射对称特例可排除。Theorem 4.5：正则窗口 exact reduction/重数对应；Theorem 4.9、Proposition 4.10：min–max、连续性和 fixed-point 根。Remark 4.2 已提出 RtR。原文同背景，不能静默认为异质端所有条件已经适配。

**[R11] Joly, P.; Li, J.-R.; Fliss, S. (2006). _Exact Boundary Conditions for Periodic Waveguides Containing a Local Perturbation_.** Communications in Computational Physics 1, 945–973. 本地 `Joly2006.pdf`；[作者出版入口](https://perso.ensta.fr/~fliss/publications.html)。L，本轮只作已有端口/Riccati 路线定位，不依赖未重新核对编号的外部定理。

**[R12] Fliss, S.; Klindworth, D.; Schmidt, K. (2015). _Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides_.** BIT Numerical Mathematics 55(1), 81–115（第二轮据作者出版页修正原期刊误记）。本地 `Fliss2015.pdf`；[作者出版入口](https://perso.ensta.fr/~fliss/publications.html)。L，题名与路线核验；不是本轮证明依赖。它使“换成 Robin 图”不能单独作为新贡献。

**[R13] Behrndt, J.; Gesztesy, F.; Holden, H.; Nichols, R. _Dirichlet-to-Neumann Maps, Abstract Weyl–Titchmarsh M-Functions, and a Generalized Index of Unbounded Meromorphic Operator-Valued Functions_.** 本轮核验 2016 预印本 [arXiv:1603.07089](https://arxiv.org/pdf/1603.07089)。F。Lemma 3.5(ii)–(iii)，(3.19)、(3.22)；Corollary 3.6，(3.25)–(3.26)：Poisson resolvent identity、anchor expansion 和负质量导数。Theorem 3.10 给 meromorphic index 与重数差。PDE 部分是有界 Lipschitz 域、$-\Delta+q$；不能直接视为加权无限条带适配。引言与正文的一个重数差符号需按定义校验，本文未使用该计数公式。

**[R14] Behrndt, J.; Rohleder, J. (2015). _Spectral analysis of selfadjoint elliptic differential operators, Dirichlet-to-Neumann maps, and abstract Weyl functions_.** Advances in Mathematics 285, 1301–1338. [DOI](https://doi.org/10.1016/j.aim.2015.08.016)，[全文](https://arxiv.org/pdf/1404.0922)。F，Theorems 4.1、4.7。单独的 DtN 和之逆可能漏掉切口零迹谱；增广 Cauchy/Weyl 对象给完整描述。几何与系数正则条件须重核，不能直接套分片传输介质。

**[R15] Cox, G.; Jones, C. K. R. T.; Marzuola, J. L. (2017). _Manifold decompositions and indices of Schrödinger operators_.** Indiana University Mathematics Journal. [DOI](https://doi.org/10.1512/iumj.2017.66.6129)，[全文](https://arxiv.org/pdf/1506.07431)。F，Theorems 1–3、Corollary 1。紧流形、实势、Lipschitz 分割、指定边界条件下的拼接/Morse 指数。内部 gap 的无限波导全域负指数通常无限，需 relative index 或局部谱流。

**[R16] Engström, C.; Langer, H.; Tretter, C. (2017). _Rational eigenvalue problems and applications to photonic crystals_.** Journal of Mathematical Analysis and Applications. [DOI](https://doi.org/10.1016/j.jmaa.2016.07.048)，[预印本](https://arxiv.org/pdf/1507.06381)。F，§§2–3 的 Schur 线性化与 rational Nevanlinna 设定。典型假设含半有界紧预解式主块及有界耦合；有限 poles 的模型不能免误差地替代周期 lead 的连续谱测度。

**[R17] Zimmerling, J.; Druskin, V.; Simoncini, V. (2025). _Monotonicity, Bounds and Acceleration of Block Gauss and Gauss–Radau Quadrature for Computing $B^T\phi(A)B$_.** Journal of Scientific Computing 103:5. [公开全文/DOI](https://doi.org/10.1007/s10915-025-02799-z)。F，Theorem 1、Proposition 3。$A$ 为 SPD、$s>0$，block Lanczos 无相应 breakdown 时，给 $(A+sI)^{-1}$ 压缩的单调 Loewner 上下界。内部 gap 的 $A_D-\mu$ 不正定，不能直接套；shifted resolvent 变换和连续补空间控制是候选算法课题。

**[R18] Güttel, S.; Tisseur, F. (2017). _The Nonlinear Eigenvalue Problem_.** Acta Numerica 26, 1–94. [DOI](https://doi.org/10.1017/S0962492917000034)。L，`Guettel2017.pdf`。提供有限维 NEP 的条件数、线性化和求解框架；本轮未依赖具体定理。有限矩阵 NEP 的根性质不自动等于连续波导谱。

### C. 谱污染、谱包含及更远的方向

**[R19] Boulton, L.; Levitin, M. (2007). _On Approximation of the Eigenvalues of Perturbed Periodic Schrödinger Operators_.** [公开原文](https://arxiv.org/abs/math/0702420)。F+L，`Boulton2007.pdf`。Corollary 2.5 给二阶谱点 $z$ 的包含 $\operatorname{dist}(\Re z,\sigma(A))\le|\Im z|$；试探空间须在 $D(A)$。Corollary 2.6 的强化另需隔离信息。原生 $C^0$ FEM 场不能直接作为强定义域试探，$K_h^2$ 不是该方法的自动实现。

**[R20] Cancès, E.; Ehrlacher, V.; Maday, Y. _Periodic Schrödinger operators with local defects and spectral pollution_.** 本轮核验 2011 预印本 [arXiv:1111.3892](https://arxiv.org/abs/1111.3892)，原始摘要 M。讨论 Galerkin 伪态、supercell 与近似谱投影避免污染。专门结果的精确应用优先用下一条已核全文，不把摘要提升为条件已审完。

**[R21] Cancès, E.; Ehrlacher, V.; Maday, Y. (2014). _Non-consistent Approximations of Self-adjoint Eigenproblems: Application to the Supercell Method_.** [全文](https://arxiv.org/abs/1205.0331)。F+L，`Cances2014.pdf`，Theorem 5.1。单周期势加趋零局部扰动的 supercell 谱收敛/无污染；两端异质的周期闭合会额外产生反向接口，不能未经分析沿用该结论。

**[R22] Cancès, E.; Dusson, G.; Maday, Y.; Stamm, B.; Vohralík, M. (2020). _Guaranteed A Posteriori Bounds for Eigenvalues and Eigenvectors: Multiplicities and Clusters_.** 本地 `Cances2020.pdf`；[期刊 DOI](https://doi.org/10.1090/mcom/3549)。L，相关设定核验：紧预解式、簇及簇外分离信息；不要求所有根简单，但不直接覆盖无限周期端。其角色是提示“簇估计”可以比逐个指定模态更自然，不是本文证明输入。

**[R23] Craster, R. V.; Davies, B. (2023). _Asymptotic Characterization of Localized Defect Modes: Su–Schrieffer–Heeger and Related Models_.** Multiscale Modeling & Simulation. [DOI](https://doi.org/10.1137/22M1511217)，[全文](https://arxiv.org/pdf/2202.07324)。原文摘要/设定已读 M：一维周期介质有限缺陷与两种介质接口，transfer matrix 与高频均匀化。它是拟议一维最小模型的重要先例；具体推广定理需后续逐条核验，不能仅因使用有效接口模型就宣称创新。

**[R24] Drouot, A. (2021). _The bulk-edge correspondence for continuous dislocated systems_.** Annales de l'Institut Fourier 71(3), 1185–1239. [公开全文/DOI](https://doi.org/10.5802/aif.3420)。已读引言与模型 (1.1)–(1.3)，M：一维平滑周期势的特定相位位错族、半周期对称条件、局部紧扰动；谱流与 bulk 指标对应。不能从“两侧不同”直接推导非零拓扑指标。

**[R25] Amenoagbadji, P.; Weinstein, M. I. (2026). _Continuum honeycomb Schrödinger operators with incommensurate line defects_.** [arXiv:2604.16712v2](https://arxiv.org/abs/2604.16712v2)，2026-08-17 修订。M，原始摘要已核。无理方向使通常 Bloch fiber 不适用，作者用更高维准周期提升和有效 Dirac resolvent。摘要明确区分本篇的展开/近似态与后续拟完成的精确 gap-filling 构造。本轮只据此说明 Q10 的问题仍有近期发展，未把预印本计划当成已证明定理。

## 4. 检索记录与选择偏差检查

### 4.1 本地优先

首先检查 `ref/README.md`、`ref/reference.bib` 和 `ref/ref_data/`（链接到 `/Users/whc/Documents/Work/TEP_ref`）。重点命中 Fliss2013/2015、Joly2006、Boulton2007、Cances2014/2020、Guettel2017、Engstrom2016；只对需要的结果提取原文。未借用归档主线作为新方向的理论权威。

### 4.2 在线检索簇

| 查询方向与代表字符串 | 筛选结果及作用 |
|---|---|
| `periodic interface weak perturbation threshold resonance eigenvalues gap` | 从 Brown 同背景结果转向 Hempel/Korotyaev 异质先例 |
| `threshold resonances periodic waveguides weak coupling` | 找到 Nazarov、Pankrashkin，推翻宽泛“共振机制新颖”的设想 |
| `periodic localized defect effective mass weak coupling` | Duchêne 正规形/有效模型先例，校准误差尺度与假设 |
| `Dirichlet Neumann Weyl spectral gap rational bounds` | 核验 anchor expansion 已有，区分新算法目标与旧恒等式 |
| `Morse index gluing Dirichlet to Neumann spectral flow` | 找到紧域 gluing；识别无限负指数的适配障碍 |
| `spectral pollution periodic defects supercell second order` | 建立 Galerkin、强定义域与异质闭合的边界 |
| `2024 2025 2026 periodic waveguide heterojunction threshold` | 新近物理论文多，未据摘要推出数学定理；选入 2025 block bounds 与 2026 无理线缺陷预印本作为邻近进展 |
| `bulk edge continuous dislocation honeycomb no fold` | 确认拓扑路线需专门结构，不宜作为任意异质接口的默认解释 |

检索不是穷尽检索；未命中不能作为“无人研究”的证据。作者原文、期刊、arXiv、MathNet、Numdam 优先；没有使用未授权镜像、付费墙绕过或把搜索摘要冒充全文。

### 4.3 三个研究审查点

1. **问题形成审查：** 最大风险是继续围绕 I10 半径修补而没有提出独立问题。已改为模态出生/不出生及接口机制；I10 仅作背景证据。
2. **文献综合审查：** 最大风险是把同背景弱缺陷、DtN 负导数或阈值二次律称新。R1–R17 已提供直接先例，故所有宽泛新颖性主张撤回。
3. **证明审查：** 独立 proof_skeptic 审查保存后的实际正文；补齐弱形式、端点 resolvent 和点相互作用参数范围。结果与未闭合适配统一见 [[research/explorations/interface-threshold/STATUS]]。

## 5. 合法全文取得与保留

本轮新取得以下六份公开全文，均未覆盖原文件。论文身份、版本与来源已检查；配套新增 `ref/README.md` 和 `ref/reference.bib` 条目。以下表是持久来源记录，临时文本提取不作为权威。

| 保存位置 | 取得来源 | 保存的版本 |
|---|---|---|
| `/Users/whc/Documents/Work/TEP_ref/Brown2015.pdf` | [arXiv PDF](https://arxiv.org/pdf/1204.0998) | 2012 v1；文件名用正式出版年 2015 |
| `/Users/whc/Documents/Work/TEP_ref/Brown2017.pdf` | [arXiv PDF](https://arxiv.org/pdf/1511.03723) | 公开预印本 |
| `/Users/whc/Documents/Work/TEP_ref/Brown2020.pdf` | [arXiv PDF](https://arxiv.org/pdf/1901.05102) | 2019 v1；编号与期刊版不同 |
| `/Users/whc/Documents/Work/TEP_ref/Hempel2015.pdf` | [arXiv PDF](https://arxiv.org/pdf/1412.6420) | 2015 v2 |
| `/Users/whc/Documents/Work/TEP_ref/Korotyaev2005.pdf` | [arXiv PDF](https://arxiv.org/pdf/math/0507295) | 公开预印本 |
| `/Users/whc/Documents/Work/TEP_ref/Duchene2015.pdf` | [作者 PDF](https://duchene.pages.math.cnrs.fr/publication/duchenevukicevicweinstein15/DucheneVukicevicWeinstein15.pdf) | CMS 正式排版全文 |

Nazarov2020 通过 MathNet web 正文成功核验，本地下载返回 403，未留下 PDF；不绕过访问限制。R9 的全文未核，保留为明确未完成的近邻核验。其余未落地 PDF 的来源均保留直接链接，不声称本地收藏齐备。

临时提取分别在 `research/tmp/interface-threshold/`、`research/tmp/spectral-routes/` 和 `research/tmp/boundary-routes/`；不在其中保存最终定理或唯一的来源记录。检索、推导与审查由 AI 辅助完成，没有人类已读标记，没有运行 MATLAB/Octave 或其他数值实验。
