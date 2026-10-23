# I9 FEM 原生场谱距离与人工边界：文献检索

日期：2026-10-23。范围：定向文献检索、原文关键段落核验和适用性分析；不是穷尽式系统综述，也不是新定理或实验设计的通过记录。本轮由主 agent 完成，没有调用子代理、运行数值实验或改变模型。

## 结论

**有直接研究线缺陷光子晶体 FEM 后验误差的论文，也有研究无限波导特征值截断误差和带隙谱包含的论文。因此不能把这一大类问题称为全新研究命题。** 但本次没有核实到能够不加改造地接入当前 I9.3、同时覆盖原生曲边 P2 场、双侧不同周期介质、有限域人工边界，并直接给出原无限波导谱距离数值估计的完整方案。

最相关的四个入口是 Giani (2013)、Aljawi–Marletta (2023)、Chaumont-Frelet (2025) 和 Boulton–Levitin (2007)：分别解决有限模型的 FEM 后验估计、波导截断的收敛、包含人工边界的源问题后验估计，以及带隙内的谱包含。不能把这四种结论互换，也不能因为需要适配就否定已有 FEM candidate 的交付价值。

本记录续接 [[research/projects/eig-apost/implementation/i4/r-validation|I4 文献审计]]，但以本轮重新核对的原文为依据。当前实验事实以 [[research/projects/eig-apost/implementation/i9/design-9-3a|I9.3 设计与结果]]、[[test/i9/compare-v1/README|I9.3 运行说明]] 为准。

## 当前问题究竟差在哪里

I9.3 的 FEM 场定义在中心加左右各 6 个胞元的有限域，远端是齐次 Dirichlet 条件，上下是固定 $\beta=0.5$ 的准周期条件。这里需要分清：

1. 代数残差小，说明矩阵特征对求解充分；它不评价连续 PDE 残差。
2. 有限域连续问题的 FEM 后验误差，仍以这个人工边界模型为目标。
3. 到原无限波导谱的距离，还要把人工边界纳入分析。端部质量占比小可以支持局域性解释，不能直接换算成谱距离。

在精确几何层面，齐次 Dirichlet FEM 场零延拓后属于原域的相应 $H^1$ 空间，但通常不属于强算子的定义域：单元边及截断端的法向导数会跳跃。这解释了为什么体残差、内部边通量跳跃和人工端边界项都可能参与估计。当前曲边几何近似还需另作对应处理。本段是对本项目的适用性分析，不是某篇论文已经证明的 I9 定理。

固定 FEM candidate 的 BIE 重构给出的是另一场的 $R_{\rm num}=0.11866142633964537$；它不等于 FEM 原生场的误差，也不证明 FEM candidate 本身误差有这么大。比较仍用 $\mu=k^2$ 的谱参数，不能直接把 $k$ 差当作 $\mu$ 的谱距离。

## 原文证据与适用范围

以下页码为所核对 PDF 的页序或论文印刷页，明确区分。每条只核验支撑本问题的部分，不声称逐行审查全文证明。

### 1. Giani (2013)：直接包含线缺陷，但估计针对有限超胞

Stefano Giani, *An a posteriori error estimator for hp-adaptive continuous Galerkin methods for photonic crystal applications*, Computing 95, 395–414. [DOI](https://doi.org/10.1007/s00607-012-0244-6)，[机构公开稿](https://durham-repository.worktribe.com/OutputFile/1466692)，[[ref/ref_data/Giani2013.pdf|已有 PDF]]。

- 原文定位：§2 的式 (9)–(10)，§4 Definition 3／式 (22)、Theorems 1–2（印刷 pp.403–405）；§5.2 线缺陷算例（pp.409–410）。
- 方法：体残差与单元边通量跳跃驱动 $hp$ 自适应，并给出特征函数与特征值的可靠性估计。
- 限制：线缺陷算例使用有限超胞。Theorem 1 假设离散特征值收敛到模型的某个特征值；Theorem 2 含隐常数及高阶余项。它不是一个覆盖无限波导截断的、常数已全部可计算的最终区间。
- 对 I9：这是“FEM 不分片 Helmholtz 也能做后验估计”的直接先例；可以借鉴原生场残差构成，不能把它的估计直接标成无限波导谱距离。

### 2. Aljawi–Marletta (2023)：直接处理波导截断，却是另一求解路线的先验收敛

Salma Aljawi and Marco Marletta, *On the Eigenvalues of Spectral Gaps of Elliptic PDEs on Waveguides*, Integral Equations and Operator Theory 95, article 7. [出版方](https://doi.org/10.1007/s00020-023-02727-6)，[机构页面](https://orca.cardiff.ac.uk/id/eprint/158306/)，[公开作者稿](https://orca.cardiff.ac.uk/id/eprint/158306/1/SAljawifinal.pdf)。

- 原文定位：§2 的模型与 Proposition 2.1；Theorem 3.3（作者稿 p.15）；Theorem 4.12（p.24）；§5 数值实现。机构 PDF 比正文多一页封面。
- 方法：给原自伴问题加入有限支撑的耗散扰动，再作域截断；借助 DtN 分析证明截断映射和相应孤立特征值的指数收敛。数值使用 MATLAB PDETool 的线性有限元。
- 限制：Theorem 4.12 控制的是固定耗散扰动后的无限域与截断域特征值之间的误差，常数不是由一次现有 FEM 输出直接计算的误差条。恢复原自伴谱还涉及扰动的影响；全文未给出当前曲边 P2 场的后验残差公式。
- 对 I9：这篇说明“有限多胞元截断如何分析”有实质先例；其半无限波导、边界和算子设定仍需与双侧加权准周期问题对照。不是现有 I9.3 的即用后处理。

### 3. Chaumont-Frelet (2025)：最值得优先借鉴的人工边界处理

Théophile Chaumont-Frelet, *A posteriori error estimates for the finite element discretization of second-order PDEs set in unbounded domains*, arXiv:2503.22297v1，**预印本**；本轮未核实到正式期刊版。[公开来源](https://arxiv.org/abs/2503.22297)，[[ref/ref_data/Chaumont-Frelet2025.pdf|新增 PDF]]。

- 原文定位：Theorem 3.1、Corollary 3.2、Theorem 3.5（PDF pp.7–9）；§4.1.7、Theorem 4.9（pp.14、18）。
- 方法：把有限域场视作无限域上的零延拓函数；平衡通量估计显式保留人工边界的法向通量，并处理域外源项。反应扩散部分给出可计算可靠界，而不先把截断误差假设为零。
- 限制：这是源问题。Helmholtz 部分假设适定性，并涉及稳定性／逼近因子；其圆柱端 PML 模型不是当前周期材料半波导。
- 对 I9：优先考察其**正定反应扩散部分**能否服务于现有 resolvent 路线的辅助问题。还需核对加权质量、准周期接缝、曲边几何及源问题误差向谱距离的转换；本文没有完成这个转换。

### 4. Boulton–Levitin (2007)：真正的带隙谱距离方法，不要求先识别唯一模态

Lyonell Boulton and Michael Levitin, *On approximation of the eigenvalues of perturbed periodic Schrödinger operators*, Journal of Physics A: Mathematical and Theoretical 40, 9319–9329. [DOI](https://doi.org/10.1088/1751-8113/40/31/010)，[公开稿](https://arxiv.org/abs/math/0702420)，[[ref/ref_data/Boulton2007.pdf|新增 PDF]]。

- 原文定位：§2.2 的式 (2.3)–(2.4)、Corollary 2.5（PDF pp.5–6）；§3.1（pp.8–9）。
- 方法：二阶谱／二次投影的复根，其虚部大小控制实部到原自伴算子谱的距离。基本包含结论不要求预先知道附近只有一个特征值；更尖锐的 Corollary 2.6 才使用隔离信息。
- 截断处理：选取满足算子定义域要求的紧支撑试探函数，直接针对无限域算子形成矩阵；§3.1 使用零函数值与零法向导数条件保证延拓正则性。
- 对 I9：不是对普通刚度／质量矩阵直接取平方。当前连续 P2 场只有 $H^1$ 相容性，需额外构造定义域相容的场或另一适当实现；这将比增加普通残差指标更大幅度地改变后处理。

### 5. 透明边界、超胞及一般谱包含的补充证据

| 文献与来源 | 核验位置与所得结论 | 对当前问题的限制 |
|---|---|---|
| Fliss (2013), *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides*；[DOI](https://doi.org/10.1137/12086697X)，[[ref/ref_data/Fliss2013.pdf|PDF]] | Theorem 4.5，§§5–6（PDF pp.13、20–23）：连续 DtN 约化与原导模问题等价；数值可用 FEM | 连续精确约化不等于离散 DtN 或最终特征值的后验界 |
| Klindworth–Schmidt–Fliss (2014), *Numerical Realization of Dirichlet-to-Neumann Transparent Boundary Conditions for Photonic Crystal Wave-Guides*；[DOI](https://doi.org/10.1016/j.camwa.2013.03.005)，[[ref/ref_data/Klindworth2014.pdf|PDF]] | 公开稿 §§7.1–7.2，Figs.7–8（PDF pp.22–24）：高阶 FEM／DtN 与超胞比较；固定超胞尺寸存在模型误差平台，弱局域模态更明显 | 高阶同方法参考与加密曲线，不是后验谱距离上界；这里采用当前公开稿节号，不能照搬旧审计的节号 |
| Cancès–Ehrlacher–Maday (2014), *Non-consistent approximations of self-adjoint eigenproblems: application to the supercell method*；[DOI](https://doi.org/10.1007/s00211-014-0626-0)，[[ref/ref_data/Cances2014.pdf|新增公开预印稿]] | 预印稿 Theorems 3.1、5.1–5.2：扰动周期 Schrödinger 算子的超胞无谱污染及先验收敛，含离散／积分影响 | 不是一次有限域 FEM 结果的可计算后验误差；I9 两侧背景不同，也不能直接当作一个周期背景的紧支撑扰动 |
| Cancès–Dusson–Maday–Stamm–Vohralík (2020), *Guaranteed a posteriori bounds for eigenvalues and eigenvectors: multiplicities and clusters*；[DOI](https://doi.org/10.1090/mcom/3549)，[[ref/ref_data/Cances2020.pdf|新增 PDF]] | 摘要、§2、§5：紧预解式情形的特征值簇可靠后验估计与通量构造 | 允许簇内重根，却要求簇与外部谱分离；无限波导有本质谱，不能直接套用紧预解式设定 |
| Behnke–Mertins–Plum–Wieners (2000), *Eigenvalue inclusions via domain decomposition*；[DOI](https://doi.org/10.1098/rspa.2000.0635)，[作者公开全文页面](https://www.researchgate.net/publication/2484711_Eigenvalue_Inclusions_Via_Domain_Decomposition)，[机构书目](https://publikationen.bibliothek.kit.edu/13522000) | §4.1、Lemma 4.1：无限声学条带障碍物算例，通过对称性约化、Dirichlet／Neumann 比较及有限元包含计算处理无限域 | 是真正的无限波导包围先例，但依赖所选对称类及阈值以下的谱结构；不能直接移植为当前不对称周期带隙模式的上下界。此次网页可读正文，公式转录不完整，未作公式级核验 |

既有 [[ref/ref_data/Engstrom2016.pdf|Engström 等 (2016)]]、[[ref/ref_data/Gopalakrishnan2025.pdf|Gopalakrishnan 等 (2025)]] 分别提供二次光子晶体特征值及固定 PML 光纤模态的后验估计近邻；[[ref/ref_data/Lin2025.pdf|Lin–Lv (2025)]] 给出散射问题 FEM 残差与 DtN 截断项的结合。其目标问题不同，本轮没有据此声称解决无限波导实特征值的谱距离。相关原文已在本地复核身份与有关段落。

Soussi (2005), *Convergence of the Supercell Method for Defect Modes Calculations in Photonic Crystals*, [DOI](https://doi.org/10.1137/040616875)：本轮仍未取得公开全文，仅核实书目信息及摘要层面的超胞收敛结论，不用于支持当前双侧线缺陷模型的具体假设。

## 对下一步的判断

**先做一项范围有限的适用性推导，比立即再跑一次 FEM 或另起完整估计理论更合适。** 本次不授权执行以下工作。

优先方向：保持 FEM candidate 和原生场身份，考察 Chaumont-Frelet 的反应扩散／通量估计能否接到当前 resolvent 谱距离框架。需要回答的具体问题只有：原生场如何延拓；人工端法向通量如何计入；所得范数和常数如何对应当前谱距离公式；准周期及曲边几何还剩哪些差异。没有证明这些对应关系之前，不把原 $C_{\rm num}\epsilon_{\rm num}$ 机械加上一个体残差。

如果这一步代价过高，Giani 式有限模型残差指标仍是有效的较小交付，但必须明确它估计的是有限模型离散误差。若目标改为不依赖模态身份的原无限算子谱包含，可进一步评估 Boulton–Levitin；不应把它伪装成现有 P2 输出上的免费附加计算。

Aljawi–Marletta 的耗散扰动和透明 DtN FEM 都可作为另一个求解器路线，当前没有理由只为给既有 FEM 场附加估计而立即重写求解器。文献中的先验收敛和数值验证足以指导实验，但不会自动给出本次单个 candidate 的误差数值。

本次发现支持“有可复用理论，适配具有实质工作量”，**不支持尚未完成的创新性声明，也不要求先解决全体真实模态计数**。谱距离包含与唯一特征值识别是不同目标。

## 检索与文件记录

- 检索日期：2026-10-23；渠道为通用学术网页检索、arXiv、出版社页面、作者及机构仓储；从 Giani、Fliss、Boulton 和 Aljawi 的引文继续追踪。没有使用付费数据库穷尽检索。
- 代表检索式：`"line defect" "a posteriori" eigenvalue`；`"photonic crystal waveguides" "error estimates" eigenvalues`；`"periodic waveguides" "a posteriori" eigenvalues`；`"waveguides" "a posteriori" "truncation" eigenvalue`；`"defect" "spectral enclosure" periodic operator finite element`；`"Eigenvalues in spectral gaps of differential operators"`。另核对 2024–2026 相关结果及上述论文引用线索。
- 纳入依据：至少涉及线缺陷 FEM 后验估计、无限域截断误差、带隙谱包含三项之一。仅有色散图、代数矩阵残差、散射源问题或固定 PML 指标的论文，不列为现成的无限波导特征值估计。
- 下载只使用公开作者稿／arXiv，不覆盖已有文件。Aljawi (2023) 的公开 PDF 可由网页工具读取，但直接文件下载返回 HTTP 403；未保存 PDF，保留机构链接。Behnke (2000) 的作者公开网页可读，PDF 下载未成功；未把网页内容伪装成 PDF。
- 四份新 PDF 已检查文件头、可解析页数、首页题名及作者，保存到 `TEP_ref`；通过 `ref/ref_data/` 访问。版本年份以正式出版信息为准，预印稿页码与期刊页码可能不同。Cancès (2014) 保存的是 arXiv:1205.0331v1 公开文件，其正文日期印作 2018-09-06；该文件日期不用于改写期刊年份。

| 本地文件 | 公开下载 URL | PDF 页数 | SHA-256 |
|---|---|---:|---|
| `Chaumont-Frelet2025.pdf` | https://arxiv.org/pdf/2503.22297v1 | 41 | `2d826c8858e563771549334e58b512e5162d1cb4a61b0d68a18afd22f45374c9` |
| `Boulton2007.pdf` | https://arxiv.org/pdf/math/0702420v1 | 17 | `cd61bf46f267b5d5cd393557938a7ac1de79b15f2b3ea06cf1172be045a97064` |
| `Cances2014.pdf` | https://arxiv.org/pdf/1205.0331v1 | 29 | `7288a235cecb1bbf2fb04265681f29b9c22e618aca83582a4b8019a37f36ec21` |
| `Cances2020.pdf` | https://arxiv.org/pdf/2008.04140 | 39 | `c3b0e37f85eea420b7d2167957f2841ffb6908dd5f1c61b1f321407023f0c45c` |

书目已同步 [[ref/README|参考文献索引]] 和 `ref/reference.bib`。提取文本等临时材料留在忽略的 `tmp/fem-lit-20261023/`，不是运行依赖。问题状态统一登记于 [[research/projects/eig-apost/implementation/i9/README#I9 当前问题账目|I9 问题账目]]。
