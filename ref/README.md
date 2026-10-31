# 参考文献索引

本目录保存周期波导、周期散射、边界积分方程和非线性特征值问题的参考资料索引。文献原文件和翻译工程放在上级 `TEP_ref/`，通过符号链接 `ref_data/` 访问。下表按研究主题归类；题名、作者和年份优先依据论文原文、DOI 页面或出版方页面核验。`BibTeX key` 指向同目录的 `reference.bib`。

文件名中的年份只用于本地识别，不一定等于正式出版年份。标为“暂不收录”的材料没有足够的书目信息，未写入 `reference.bib`。

下表“路径”列均相对于本目录，统一通过 `ref_data/` 访问实际资料。

## 周期波导、光子晶体与透明边界条件

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| [机构公开稿](https://orca.cardiff.ac.uk/id/eprint/158306/)（未保存本地 PDF） | *On the Eigenvalues of Spectral Gaps of Elliptic PDEs on Waveguides* | Salma Aljawi; Marco Marletta | 2023 | 波导带隙、耗散扰动、域截断 | 给出固定耗散扰动问题的 DtN／特征值截断收敛；不是现有 FEM 场的后验谱距离公式 | `AljawiMarletta2023` |
| `ref_data/Ammari2026a.pdf` | *Band-Edge Homogenization and the Sound-Soft Limit of Finite Bubbly Crystals* | Habib Ammari; Yuxin Du; Xin Fu; Wenjia Jing; Moritz Melcher | 2026 预印本 | 带边均匀化、有限晶体终止 | 预解式误差分层参考；高对比渐近及未知常数，非当前导模证书 | `AmmariDuFuJingMelcher2026` |
| `ref_data/Ammari2026.pdf` | *Waveguiding in systems of high-contrast resonators: Theory and fast computations* | Habib Ammari; Bowen Li; Borui Miao; Jiayu Qiu; Lara Vrabac | 2026 预印本 | 高对比共振器、DtN 有效算子 | 吸收/截断/局部求解误差分账；需外部谱隙与显式常数 | `AmmariEtAl2026Waveguiding` |
| [作者公开全文](https://www.researchgate.net/publication/2484711_Eigenvalue_Inclusions_Via_Domain_Decomposition)（未保存本地 PDF） | *Eigenvalue Inclusions via Domain Decomposition* | Henning Behnke; Ulrich Mertins; Michael Plum; Christian Wieners | 2000 | 无限声学波导、谱包含、区域分解 | 对称类内用 Dirichlet／Neumann 比较和 FEM 包围处理无限域；不直接覆盖周期带隙 | `BehnkeMertinsPlumWieners2000` |
| `ref_data/Bonnet1995.pdf` | *Spectral Approximation of a Boundary Condition for an Eigenvalue Problem* | Anne-Sophie Bonnet-Ben Dhia; Nabil Gmati | 1995 | 光纤导模、Fourier 边界算子、谱逼近 | 证明截断 exact boundary operator 后导模特征值与特征函数的超代数先验收敛 | `BonnetBenDhiaGmati1995` |
| `ref_data/Boureghda2022.pdf` | *On Domain Error Truncation in a Problem of Guided Modes Computation in Optical Fibers* | Abdelouahab Boureghda; Abdelaziz Choutri; Hayat Rezgui | 2022 | 光纤导模、域截断、特征值误差 | 提供开放导模特征值随人工边界半径变化的指数型误差分析近邻 | `BoureghdaChoutriRezgui2022` |
| `ref_data/books/Bandle2009.pdf`（第 23–30 页） | *On Spectral Bounds for Photonic Crystal Waveguides* | B. M. Brown; V. Hoang; M. Plum; I. G. Wood | 2009（ISNM 157 论文集；本地为整本书） | 线缺陷、谱包围、计算机辅助证明 | 用 $H^{-1}$ 中近似特征对的残差和 Weinstein 定理包围线缺陷引入的谱点；是导模特征值可靠界的直接近邻 | `BrownHoangPlumWood2009` |
| `ref_data/Brown2015.pdf` | *On the Spectrum of Waveguides in Planar Photonic Bandgap Structures* | B. M. Brown; V. Hoang; M. Plum; I. Wood | 2015（本地为 2012 预印稿） | 加权 Laplacian、弱线缺陷、Birman–Schwinger | 给出同一周期背景中任意弱正介电缺陷的 gap 模态存在性；不直接覆盖左右异质端 | `BrownHoangPlumWood2015` |
| `ref_data/Brown2017.pdf` | *Gap Localization of TE-Modes by Arbitrarily Weak Defects* | B. M. Brown; V. Hoang; M. Plum; M. Radosz; I. Wood | 2017（本地为公开预印稿） | TE 散度型算子、不连续系数、弱缺陷 | 用负 Sobolev 空间证明正缺陷的无阈值局域化；算子与质量扰动不同，仍要求同一周期远场 | `BrownHoangPlumRadoszWood2017` |
| `ref_data/Brown2020.pdf` | *Gap Localization of Multiple TE-Modes by Arbitrarily Weak Defects*（本地预印稿题名：*Gap Localization of TE-Modes by Arbitrarily Weak Defects — Multiband Case*） | B. M. Brown; V. Hoang; M. Plum; M. Radosz; I. Wood | 2020（本地为 2019 预印稿） | 多带边、弱缺陷、模态计数 | 在二次非退化带边和正缺陷条件下计数 gap 模态；异质界面的共振耦合尚需另行分析 | `BrownHoangPlumRadoszWood2020` |
| `ref_data/Chaumont-Frelet2025.pdf` | *A Posteriori Error Estimates for the Finite Element Discretization of Second-Order PDEs Set in Unbounded Domains* | Théophile Chaumont-Frelet | 2025 预印本 | 平衡通量、人工边界、无限域源问题 | 显式控制截断端通量；可研究与 resolvent 估计的衔接，尚非特征值估计 | `ChaumontFrelet2025` |
| `ref_data/Choutri2008.pdf` | *Étude de l'erreur de troncature du domaine pour un problème aux valeurs propres* | Abdelaziz Choutri | 2008 | 光纤导模、Robin 边界、截断误差 | 给出光纤导模特征值与特征函数的先验域截断误差估计 | `Choutri2008` |
| `ref_data/Coatleven2012.pdf` | *Helmholtz Equation in Periodic Media with a Line Defect* | Julien Coatléven | 2012 | 线缺陷、Floquet–Bloch 变换、DtN | 研究带局部结构的周期介质与精确截断，是项目波导模型的直接背景 | `Coatleven2012` |
| `ref_data/Nittis2021.pdf` | *Spectral and Scattering Theory of One-Dimensional Coupled Photonic Crystals* | Giuseppe De Nittis; Marco Moscolari; Serge Richard; Rafael Tiedra de Aldecoa | 2021 | 一维耦合光子晶体、谱与散射理论 | 提供周期光子结构谱分解和散射算子的抽象背景 | `DeNittisEtAl2021` |
| `ref_data/Djellouli2000.pdf` | *A Local Boundary Condition Coupled to a Finite Element Method to Compute Guided Modes of Optical Fibres under the Weak Guidance Assumptions* | Rabia Djellouli; Chokri Bekkey; Abdelaziz Choutri; Hayat Rezgui | 2000 | 光纤导模、局部人工边界、FEM | 以局部 Robin 型条件近似 DtN，并用解析与文献参考值验证传播常数精度 | `DjellouliBekkeyChoutriRezgui2000` |
| `ref_data/Duchene2015.pdf` | *Homogenized Description of Defect Modes in Periodic Structures with Localized Defects* | Vincent Duchêne; Iva Vukićević; Michael I. Weinstein | 2015 | 弱局部缺陷、有效质量、带边分岔 | 给出一维单周期背景的近带边特征值及包络渐近；不直接给出异质周期端的界面判据 | `DucheneVukicevicWeinstein2015` |
| `ref_data/Ehrhardt2009.pdf` | *Evaluation of Exact Boundary Mappings for One-Dimensional Semi-Infinite Periodic Arrays*（期刊版题名：*Evaluation of Scattering Operators for Semi-Infinite Periodic Arrays*） | Matthias Ehrhardt; Jiguang Sun; Chunxiong Zheng | 2009 | 半无限周期阵列、边界映射、倍增算法 | 为端口边界算子和递归倍增计算提供先例 | `EhrhardtSunZheng2009` |
| `ref_data/Engstrom2016.pdf` | *Efficient and Reliable hp-FEM Estimates for Quadratic Eigenvalue Problems and Photonic Crystal Applications* | Christian Engström; Stefano Giani; Luka Grubišić | 2016 | 二次特征值问题、hp-FEM、后验估计 | 提供光子晶体非线性特征值 residual/DWR estimator 与 effectivity 近邻 | `EngstromGianiGrubisic2016` |
| `ref_data/Fliss2013.pdf` | *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides* | Sonia Fliss | 2013 | 导模、DtN、光子晶体波导 | 项目导模与端口算子理论的核心参考 | `Fliss2013` |
| `ref_data/Fliss2015.pdf` | *Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides* | Sonia Fliss; Dirk Klindworth; Kersten Schmidt | 2015 | RtR 透明边界、导模 | 为有限计算域上的导模求解和透明边界构造提供比较框架 | `FlissKlindworthSchmidt2015` |
| `ref_data/Fliss2021.pdf` | *A Dirichlet-to-Neumann Approach to the Mathematical and Numerical Analysis in Waveguides with Periodic Outlets at Infinity* | Sonia Fliss; Patrick Joly; Vincent Lescarret | 2021（本地为 HAL 投稿版，题名写作 *A DtN approach ...*） | 多周期出口结、DtN 透明边界、Fredholm 性 | 为多个周期半波导的连接构造 DtN 透明边界条件，并证明截断后的有界域问题为 Fredholm 型 | `FlissJolyLescarret2021` |
| `ref_data/Giani2013.pdf` | *An A Posteriori Error Estimator for hp-Adaptive Continuous Galerkin Methods for Photonic Crystal Applications* | Stefano Giani | 2013 | 光子晶体、hp-FEM、后验估计 | 阻断宽泛的光子晶体线缺陷特征值 estimator 创新声明，并提供 effectivity 基线 | `Giani2013` |
| `ref_data/Gopalakrishnan2025.pdf` | *Adaptive Resolution of Fine Scales in Modes of Microstructured Optical Fibers* | Jay Gopalakrishnan; Jacob Grosek; Gabriel Pinochet-Soto; Pieter VandenBerge | 2025 | 微结构光纤、泄漏模、自适应有限元、PML | 为复杂光纤模态的细尺度解析、损耗计算和误差控制提供数值参考 | `GopalakrishnanEtAl2025` |
| `ref_data/Halla2018.pdf` | *Two scale Hardy space infinite elements for scalar waveguide problems* | Martin Halla; Lothar Nannen | 2018（线上2017） | 近截止、Hardy无限元、临界模匹配 | 阈值方法强基线；§3.4与§4；[开放全文](https://link.springer.com/content/pdf/10.1007/s10444-017-9549-5.pdf)，2026-10-31下载 | `HallaNannen2018` |
| `ref_data/Hempel2015.pdf` | *Bound States for Nano-Tubes with a Dislocation* | Rainer Hempel; Martin Kohlmann; Marko Stautz; Jürgen Voigt | 2015 | 异质圆柱、界面位移、公共带隙 | 在附加谱条件下用一列界面位移实现指定 gap 能量；不保证每个固定界面或任意弱中心缺陷都有模态 | `HempelKohlmannStautzVoigt2015` |
| `ref_data/Hoang2009a.pdf` | *A Computer-Assisted Proof for Photonic Band Gaps* | Vu Hoang; Michael Plum; Christian Wieners | 2009（正式发表版；KIT 2008/5 预印本另存为 `ref_data/Hoang2009.pdf`） | 光子带隙、验证特征值界、Bloch 参数覆盖 | 用有限参数网格上的可靠界和扰动覆盖证明完整带隙；可支撑两侧公共 projected gap 的独立验证 | `HoangPlumWieners2009` |
| `ref_data/Hohage2013.pdf` | *Riesz Bases and Jordan Form of the Translation Operator in Semi-Infinite Periodic Waveguides* | Thorsten Hohage; Sofiane Soussi | 2013 | 平移算子、Riesz 基、Jordan 结构 | 支撑项目对端口传播算子谱结构的分析 | `HohageSoussi2013` |
| `ref_data/unsorted/huzhen6.pdf` | *Simple Boundary Condition for Terminating Photonic Crystal Waveguides* | Zhen Hu; Ya Yan Lu | 2012 | 光子晶体波导、近似边界条件 | 可与项目采用的精确端口条件比较计算成本和误差 | `HuLu2012` |
| `ref_data/Hu2026.pdf` | *Time-Harmonic Scattering of Plane Waves from an Infinite Periodically Inhomogeneous Medium* | Guanghui Hu; Andreas Rathsfeld; Jiayi Zhang; Ruming Zhang | 2026（Online First） | Floquet 出射模式、DtN 高频估计 | 有限/高模态分拆参照；可分离一维 lead 非二维圆柱晶体 | `HuRathsfeldZhangZhang2026` |
| `ref_data/Huang2007.pdf` | *Analyzing Photonic Crystal Waveguides by Dirichlet-to-Neumann Maps* | Yuexia Huang; Ya Yan Lu; Shaojie Li | 2007 | 光子晶体波导、DtN、模态分析 | 提供以超胞 DtN 将导模问题降维的数值方案 | `HuangLuLi2007` |
| `ref_data/Joly2006.pdf` | *Exact Boundary Conditions for Periodic Waveguides Containing a Local Perturbation* | Patrick Joly; Jing-Rebecca Li; Sonia Fliss | 2006 | 局部扰动、精确边界条件、Riccati 方程 | 是项目端口截断和局部缺陷波导问题的主要理论来源 | `JolyLiFliss2006` |
| `ref_data/Klindworth2014.pdf` | *Numerical Realization of Dirichlet-to-Neumann Transparent Boundary Conditions for Photonic Crystal Wave-Guides* | Dirk Klindworth; Kersten Schmidt; Sonia Fliss | 2014 | 光子晶体波导、DtN、透明边界、高阶 FEM | 以同方法高阶解和 supercell 对照展示 DtN 数值实现的收敛，并区分连续 exact reduction 与离散 reference | `KlindworthSchmidtFliss2014` |
| `ref_data/Klindworth2015.pdf` | *On the Numerical Computation of Photonic Crystal Waveguide Band Structures* | Dirk Klindworth | 2015 | 线缺陷导模、DtN/RtR、非线性特征值 | 给出透明边界的高阶 FEM 实现与色散曲线追踪，并明确把 DtN/RtR 数值误差分析列为开放问题 | `Klindworth2015` |
| `ref_data/Korotyaev2005.pdf` | *Schrödinger Operator with a Junction of Two 1-Dimensional Periodic Potentials* | Evgeny Korotyaev | 2005（本地为公开预印稿） | 一维异质周期接合、公共带隙、共振 | 给出 gap 内零至两个特征值及位移渐近；计数结论不能直接推广到二维多通道波导 | `Korotyaev2005` |
| `ref_data/Li2007.pdf` | *Computing Photonic Crystal Defect Modes by Dirichlet-to-Neumann Maps* | Shaojie Li; Ya Yan Lu | 2007 | 缺陷模、DtN | 为缺陷模特征值计算和单元边界降维提供算法参考 | `LiLu2007` |
| `ref_data/Lin2025.pdf` | *An Adaptive Finite Element DtN Method for the Acoustic-Elastic Interaction Problem in Periodic Structures* | Lei Lin; Junliang Lv | 2025 | 周期散射、DtN 截断、后验误差 | 说明周期结构散射中可把 FEM residual 与可计算 DtN 截断项合并为 estimator | `LinLv2025` |
| [原文入口](https://www.mathnet.ru/eng/sm8624)（无本地PDF） | *The asymptotic behaviour of the scattering matrix in a neighbourhood of the endpoints of a spectral gap* | S. A. Nazarov | 2017 | 周期端、阈值散射、共振 | 已核Theorems2–3、5、11；后续本地下载403，未重试 | `Nazarov2017` |
| `ref_data/Yu2022.pdf` | *PML and High-Accuracy Boundary Integral Equation Solver for Wave Scattering by a Locally Defected Periodic Surface* | Xiuchen Yu; Guanghui Hu; Wangtao Lu; Andreas Rathsfeld | 2022 | 局部缺陷周期面、PML、BIE、推进算子 | 与项目的半波导截断、Riccati 方程和衰减分析直接相关 | `YuHuLuRathsfeld2022` |
| `ref_data/Yuan2007.pdf` | *A Recursive-Doubling Dirichlet-to-Neumann-Map Method for Periodic Waveguides* | Lijun Yuan; Ya Yan Lu | 2007 | DtN、递归倍增、周期波导 | 是项目端口算子数值倍增策略的直接算法参考 | `YuanLu2007` |
| `ref_data/Yuan2008.pdf` | *Modeling Photonic Crystals by Boundary Integral Equations and Dirichlet-to-Neumann Maps* | Jianhua Yuan; Ya Yan Lu; Xavier Antoine | 2008 | 光子晶体、BIE、DtN | 说明如何用边界积分构造单胞 DtN 并计算带结构 | `YuanLuAntoine2008` |
| `ref_data/Zhang2021.pdf` | *Numerical methods for scattering problems in periodic waveguides* | Ruming Zhang | 2021 | 周期端、复轮廓、传播模 | Assumption1排除零群速；同乘子异号通量可处理；[开放全文](https://link.springer.com/content/pdf/10.1007/s00211-021-01229-0.pdf)，2026-10-31下载 | `Zhang2021` |
| `ref_data/Zhang2023.pdf` | *A Spectral Decomposition Method to Approximate Dirichlet-to-Neumann Maps in Complicated Waveguides* | Ruming Zhang | 2023 | 谱分解、复杂波导、DtN 近似 | 为复杂端口上的 DtN 近似和谱截断提供现代方案 | `Zhang2023` |
| `ref_data/Zou2026.pdf` | *Mixed Unfitted finite element approximation of band structures in photonic crystals* | Yuyan Zou; Luke G. Bennetts; Hailong Guo | 2026 预印本 | mixed unfitted Maxwell、谱簇 | 独立 bulk 排伪结构参考；非零准动量及渐近收敛非谱包围 | `ZouBennettsGuo2026` |

## 周期散射、边界积分与高阶离散

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/Adcock2020.pdf` | *Frames and Numerical Approximation II: Generalized Sampling* | Ben Adcock; Daan Huybrechs | 2020 | 冗余框架、广义采样、过采样最小二乘 | 说明正则化和过采样可使冗余、病态离散仍达到高精度，并界定该结论对辅助基与采样充分性的依赖 | `AdcockHuybrechs2020` |
| `ref_data/unsorted/1-s2.0-S0021999124006314-main.pdf` | *Trapped Acoustic Waves and Raindrops: High-Order Accurate Integral Equation Method for Localized Excitation of a Periodic Staircase* | Fruzsina J. Agocs; Alex H. Barnett | 2024 | 周期阶梯、局域激励、高阶积分方程 | 与周期背景中的局域源、陷获波和高精度 BIE 计算相关 | `AgocsBarnett2024` |
| `ref_data/Arens2006.pdf` | *On Integral Equation and Least Squares Methods for Scattering by Diffraction Gratings* | Tilo Arens; Simon N. Chandler-Wilde; John A. DeSanto | 2006 | 光栅散射、积分方程、最小二乘 | 提供周期 Helmholtz 散射的积分方程与稳定性背景 | `ArensChandlerWildeDeSanto2006` |
| `ref_data/Barnett2008.pdf` | *Stability and Convergence of the Method of Fundamental Solutions for Helmholtz Problems on Analytic Domains* | Alex H. Barnett; Timo Betcke | 2008 | MFS、源点布置、解析延拓、稳定性 | 将 MFS 源点位置和系数增长与最近解析延拓奇点联系起来，为代理源曲线不得越过遗漏周期像奇点的规则提供依据 | `BarnettBetcke2008` |
| `ref_data/Barnett2010.pdf` | *A New Integral Representation for Quasiperiodic Fields and Its Application to Two-Dimensional Band Structure Calculations* | Alex H. Barnett; Leslie Greengard | 2010 | 准周期场、周期 Green 函数、能带 | 与项目准周期 Green 函数和 Bloch 参数计算直接相关 | `BarnettGreengard2010` |
| `ref_data/unsorted/1410.5003v1.pdf` | *Robust Fast Direct Integral Equation Solver for Quasi-Periodic Scattering Problems with a Large Number of Layers* | Min Hyung Cho; Alex H. Barnett | 2015 | 多层准周期散射、快速直接解法 | 为大规模周期分层结构的稳定积分方程求解提供参考 | `ChoBarnett2015` |
| `ref_data/Dominguez2016.pdf` | *Well-Posed Boundary Integral Equation Formulations and Nyström Discretizations for the Solution of Helmholtz Transmission Problems in Two-Dimensional Lipschitz Domains* | Víctor Domínguez; Mark Lyon; Catalin Turc | 2016 | Helmholtz 透射、BIE、Nyström | 为多介质界面方程的适定性和离散选择提供依据 | `DominguezLyonTurc2016` |
| `ref_data/Hao2014.pdf` | *High-Order Accurate Methods for Nyström Discretization of Integral Equations on Smooth Curves in the Plane* | Sijia Hao; Alex H. Barnett; Per-Gunnar Martinsson; Patrick Young | 2014 | Nyström、高阶求积、弱奇异核 | 是项目二维边界积分高阶离散的基础数值参考 | `HaoBarnettMartinssonYoung2014` |
| `ref_data/Hiptmair2022.pdf` | *Spurious Quasi-Resonances in Boundary Integral Equations for the Helmholtz Transmission Problem* | Ralf Hiptmair; Andrea Moiola; Euan A. Spence | 2022 | Helmholtz 透射、伪准共振、BIE | 用于辨别积分方程病态与真实物理共振 | `HiptmairMoiolaSpence2022` |
| `ref_data/Huybrechs2019.pdf` | *An Oversampled Collocation Approach of the Wave Based Method for Helmholtz Problems* | Daan Huybrechs; Anda-Elena Olteanu | 2019 | Trefftz 方法、过采样配置、病态最小二乘 | 说明过采样 collocation 与小范数系数如何在高度病态的冗余波函数离散中维持数值精度 | `HuybrechsOlteanu2019` |
| `ref_data/Kress1991.pdf` | *Boundary Integral Equations in Time-Harmonic Acoustic Scattering* | Rainer Kress | 1991 | 声散射、边界积分方程 | 提供层势、跳跃关系与积分方程适定性的经典背景 | `Kress1991` |
| `ref_data/Lawrence2026.pdf` | *Stable minimum principles for scattering states* | Scott Lawrence; Yukari Yamauchi | 2026，arXiv v1 | 振幅残差界、散射稳定性 | 直接输出界先例；常数含精确测试态；[作者全文](https://arxiv.org/pdf/2605.17139v1)，2026-10-31下载 | `LawrenceYamauchi2026` |
| `ref_data/Linton1998.pdf` | *The Green's Function for the Two-Dimensional Helmholtz Equation in Periodic Domains* | C. M. Linton | 1998 | 周期 Helmholtz Green 函数、晶格和 | 是项目准周期/周期核函数构造的基础参考 | `Linton1998` |
| `ref_data/Lu2014.pdf` | *Efficient High Order Waveguide Mode Solvers Based on Boundary Integral Equations* | Wangtao Lu; Ya Yan Lu | 2014 | 波导模态、BIE、高阶算法 | 为项目模式求解器和边界离散提供直接算法参考 | `LuLu2014` |
| `ref_data/Lu2026.pdf` | *A Boundary Integral Equation Method for Wave Scattering in Periodic Structures via the Floquet–Bloch Transform* | Wangtao Lu; Kuanrong Shen; Ruming Zhang | 2026 | 局部扰动周期结构、Floquet–Bloch、BIE | 提供以背景 Green 函数和 Floquet–Bloch 逆变换处理非准周期散射的新方法 | `LuShenZhang2026` |
| `ref_data/Luan2019.pdf` | *A Meshless Numerical Method for Time Harmonic Quasi-Periodic Scattering Problem* | Tian Luan; Yao Sun; Zibo Zhuang | 2019 | 准周期散射、无网格方法 | 可作为项目边界积分离散之外的数值方法对照 | `LuanSunZhuang2019` |
| `ref_data/PerezArancibia2026.pdf` | *Photonic band structure by direct second-kind free-space boundary integral equations* | Carlos Pérez-Arancibia; Tao Yin | 2026 预印本 | 第二类胞元 BIE、Bloch 真伪核 | 直接胞元方法先例；整曲线判据不能由有限采样认证 | `PerezArancibiaYin2026` |
| `ref_data/Trefethen2014.pdf` | *The Exponentially Convergent Trapezoidal Rule* | Lloyd N. Trefethen; J. A. C. Weideman | 2014 | 周期解析积分、指数梯形余项 | Thm. 3.2、式 (3.16)，p.396；真实材料矩的显式求积误差。[作者全文](https://people.maths.ox.ac.uk/trefethen/sirev56-3_385.pdf)，2026-10-30 下载 | `TrefethenWeideman2014` |

## 非线性特征值、谱扰动与传输特征值

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/Barnett2018.pdf` | *Comparable Upper and Lower Bounds for Boundary Values of Neumann Eigenfunctions and Tight Inclusion of Eigenvalues* | Alex H. Barnett; Andrew Hassell; Melissa Tacy | 2018 | Neumann Laplacian、MPS、谱包含、加权边界 tension | 给出到最近 Neumann 谱点的边界残量型包含界；可启发周期情形的通道加权，但其定理本身不识别唯一目标特征值 | `BarnettHassellTacy2018` |
| `ref_data/Berkolaiko2026.pdf` | *The Duistermaat Index and Eigenvalue Interlacing for Self-Adjoint Extensions of a Symmetric Operator* | Gregory Berkolaiko; Graham Cox; Yuri Latushkin; Selim Sukhtaiev | 2026（EMS 正式版，49 页） | 自伴扩张、Duistermaat 指数、谱流、Cauchy 数据 | 端点计数公式的主要定理要求有限亏指数；第 4 节另研究无限维边界空间，不能据此直接套用二维迹空间计数 | `BerkolaikoCoxLatushkinSukhtaiev2026` |
| `ref_data/Bindel2013.pdf` | *Localization Theorems for Nonlinear Eigenvalue Problems* | David Bindel; Amanda Hood | 2013 | 非线性特征值、谱定位 | 为参数依赖算子特征值的包围和数值验证提供工具 | `BindelHood2013` |
| `ref_data/Boulton2007.pdf` | *On Approximation of the Eigenvalues of Perturbed Periodic Schrödinger Operators* | Lyonell Boulton; Michael Levitin | 2007 | 二阶谱、带隙、后验谱包含 | 基本包含不要求唯一模态；需算子定义域相容试探空间，不能直接平方 P2 刚度矩阵 | `BoultonLevitin2007` |
| `ref_data/Cances2014.pdf` | *Non-consistent Approximations of Self-adjoint Eigenproblems: Application to the Supercell Method* | Eric Cancès; Virginie Ehrlacher; Yvon Maday | 2014（本地为公开预印稿） | 周期背景局部缺陷、超胞、先验收敛 | 区分超胞无谱污染与可计算后验界；不直接覆盖双侧不同周期背景 | `CancesEhrlacherMaday2014` |
| `ref_data/Cances2020.pdf` | *Guaranteed A Posteriori Bounds for Eigenvalues and Eigenvectors: Multiplicities and Clusters* | Eric Cancès; Geneviève Dusson; Yvon Maday; Benjamin Stamm; Martin Vohralík | 2020 | 特征值簇、可靠后验界、通量 | 允许重根但要求簇外隔离和紧预解式，不能直接套用于无限波导 | `CancesDussonMadayStammVohralik2020` |
| `ref_data/Carstensen2014.pdf` | *Guaranteed Lower Bounds for Eigenvalues* | Carsten Carstensen; Joscha Gedicke | 2014（本地为作者稿，29 页） | 非协调 FEM、可靠特征值下界、粗网格 | 有界多边形 Dirichlet Laplacian 的全可计算上下界；用于评估惯性认证所需的下界工具，不直接覆盖无限波导 DtN 形式 | `CarstensenGedicke2014` |
| `ref_data/Carstensen2026.pdf` | *Old and New Schrödinger Eigenvalue Localization* | Carsten Carstensen; Tim Stiebert | 2026（本地为 arXiv 稿） | extra-stabilized FEM、谱上下界 | 辅助有界问题包围；准周期及真实界面条件须适配 | `CarstensenStiebert2026OldNew` |
| `ref_data/Carstensen2026a.pdf` | *Galerkin error reduction and eigenvalue localisation for conforming FEM* | Carsten Carstensen; Tim Stiebert | 2026 | Galerkin 投影常数、保证下界 | 认证辅助常数的直接模板；不直接覆盖无限 lead 或 I10 饱和性 | `CarstensenStiebert2026Galerkin` |
| `ref_data/Chouly2026.pdf` | *A posteriori error estimation for coarse or distorted meshes* | Franz Chouly; Michel Duprez; Claudio Lobos; Zuqi Tang | 2026 预印本 | 平衡通量、粗/畸变网格 | 正定辅助问题的显式界；须保留精确均值平衡和边界条件 | `ChoulyDuprezLobosTang2026` |
| `ref_data/CortesCastillo2026.pdf` | *Variationally correct loss functions for nonlinear parametric problems and their neural approximations* | Pablo Cortés Castillo; Wolfgang Dahmen; Jay Gopalakrishnan | 2026 预印本 | 残差双范数、Fortin、数据振荡 | 有限测试到完整范数的条件模板；本征频率稳定性须另证 | `CortesCastilloDahmenGopalakrishnan2026` |
| `ref_data/Cox2017.pdf` | *Manifold Decompositions and Indices of Schrödinger Operators* | Graham Cox; Christopher K. R. T. Jones; Jeremy L. Marzuola | 2017（本地为 arXiv v2，2016，19 页） | 区域分解、Maslov 指数、DtN、Morse 指数 | 给出紧流形上的拼接及 DtN 指数公式；无限波导内部带隙需额外处理相对计数与端部谱 | `CoxJonesMarzuola2017` |
| `ref_data/Dupuy2025.pdf` | *A Posteriori Error Estimates for Schrödinger Operators Discretized with Linear Combinations of Atomic Orbitals* | Mi-Song Dupuy; Geneviève Dusson; Ioanna-Maria Lygatsika | 2025（本地为 arXiv 稿） | 局部残差双范数、显式谱尾 | 全残差范数控制的近邻；trace 适配及连续 gap 尚缺 | `DupuyDussonLygatsika2025` |
| `ref_data/Guettel2017.pdf` | *The Nonlinear Eigenvalue Problem* | Stefan Güttel; Françoise Tisseur | 2017 | 非线性矩阵特征值、数值算法综述 | 为项目频率依赖算子和数值特征值算法提供统一框架 | `GuettelTisseur2017` |
| `ref_data/Herbst2020.pdf` | *A posteriori error estimation for the non-self-consistent Kohn–Sham equations* | Michael F. Herbst; Antoine Levitt; Eric Cancès | 2020，arXiv v2 | 可靠平面波谱界、Schur 补 | §V、式 (7)–(8)，PDF p.5；有限／无限块的近邻，赝势尾不能直接套用于材料跳变。[公开全文](https://arxiv.org/pdf/2004.13549v2)，2026-10-30 下载 | `HerbstLevittCances2020` |
| `ref_data/unsorted/Transmission Eigenvalues for Helmholtz Equation Perturbation Problems of Isotropic Media With Voids.pdf` | 《含空隙的各向同性介质 Helmholtz 方程扰动问题的传输特征值》 | 李诗璇；刘立汉 | 2023 | 传输特征值、折射率扰动、Neumann–Dirichlet 算子 | 与项目传输特征值的扰动理论和算子表述相关 | `LiLiu2023` |
| `ref_data/Liu2026.pdf` | *Guaranteed Lower Eigenvalue Bounds for Spectral Galerkin Methods with Application to Schrödinger Operators* | Xuefeng Liu | 2026 预印本 | 谱 Galerkin 下界、模态泄漏 | 辅助投影及补空间常数参考；周期 lead 不满足 confinement | `Liu2026Spectral` |
| `ref_data/Moskow2015.pdf` | *Nonlinear Eigenvalue Approximation for Compact Operators* | Shari Moskow | 2015 | 紧算子、非线性特征值逼近、扰动 | 支撑项目对离散或参数扰动下特征值收敛的分析 | `Moskow2015` |
| `ref_data/Pushnitski2009.pdf` | *Operator Theoretic Methods for the Eigenvalue Counting Function in Spectral Gaps* | Alexander Pushnitski | 2009（本地为 arXiv v1，2008，25 页） | 带隙计数、谱流、相对指标、广义 Birman–Schwinger 原理 | 为内部带隙中的相对计数提供算子框架；应用前需核对扰动的相对紧性及谱投影对的 Fredholm 条件 | `Pushnitski2009` |
| `ref_data/Temple1928.pdf` | *The Theory of Rayleigh's Principle as Applied to Continuous Systems* | G. Temple | 1928 | Rayleigh 商、Temple 下界 | Temple 下界的原始文献；L1 雏形 4.5 节引用 | `Temple1928` |
| `ref_data/Xi2024.pdf` | *Analysis of a Finite Element DtN Method for Scattering Resonances of Sound Hard Obstacles* | Yingxia Xi; Bo Gong; Jiguang Sun | 2024 | 散射共振、DtN 截断、非线性特征值 | 给出 DtN Fourier 截断与 FEM 离散下 holomorphic NEP 的特征值收敛估计 | `XiGongSun2024` |
| `ref_data/Zhang2026.pdf` | *Least-Squares Finite Element Methods with Weakly Imposed Boundary Conditions: Norm and Error Equivalences, Over-Penalization, and Fully Discontinuous Discretizations* | Shun Zhang | 2026 预印本 | 弱边界最小二乘、后处理 | 区分值/通量迹范数；唯一性和非显式常数限制本征问题应用 | `Zhang2026` |

## 专著与理论基础

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/books/Colton1983 (CH3).pdf` | *Integral Equation Methods in Scattering Theory*, Chapter 3 | David Colton; Rainer Kress | 2013 重印；原版 1983 | 散射积分方程 | 本地文件是第 3 章节选；为层势与散射积分方程提供经典依据 | `ColtonKress1983` |
| `ref_data/books/Folland1999.pdf` | *Real Analysis: Modern Techniques and Their Applications*, 2nd ed. | Gerald B. Folland | 1999 | 测度、Fourier 分析 | 定理 8.20（p.248）三角函数系完备、定理 8.29（p.252）Plancherel；L1 雏形 4.5 节引用 | `Folland1999` |
| `ref_data/books/Hardy1934.pdf` | *Inequalities* | G. H. Hardy; J. E. Littlewood; G. Pólya | 1934（第一版） | 经典不等式 | §7.7 定理 258（p.185）Wirtinger 不等式；L1 雏形 4.5 节引用 | `HardyLittlewoodPolya1934` |
| `ref_data/books/Isakov2017.pdf` | *Inverse Problems for Partial Differential Equations*, 3rd ed. | Victor Isakov | 2017 | 反问题、唯一延拓、稳定性 | 为项目证明中使用的 Cauchy 唯一性与定量估计提供来源 | `Isakov2017` |
| `ref_data/books/Joannopoulos2011.pdf` | *Photonic Crystals: Molding the Flow of Light*, 2nd ed. | John D. Joannopoulos; Steven G. Johnson; Joshua N. Winn; Robert D. Meade | 2008 | 光子晶体物理与能带 | 提供周期介质、缺陷和导模的物理背景；文件名年份与版本版权页不一致 | `JoannopoulosJohnsonWinnMeade2008` |
| `ref_data/books/Kato1995.pdf` | *Perturbation Theory for Linear Operators*, 2nd ed. | Tosio Kato | 1995 | 闭算子、谱与扰动理论 | 是项目算子谱、解析族和特征值扰动的理论基础 | `Kato1995` |
| `ref_data/unsorted/Multiple scattering Interaction of time-harmonic waves with N obstacles (P. A. Martin) (Z-Library).pdf` | *Multiple Scattering: Interaction of Time-Harmonic Waves with N Obstacles* | P. A. Martin | 2006 | 多体散射、加法定理、积分方程 | 为多障碍散射和边界积分表示提供专著级参考；文件名显示来源标记，后续宜以合法来源副本替换 | `Martin2006` |
| `ref_data/books/McLean2000.pdf` | *Strongly Elliptic Systems and Boundary Integral Equations* | William McLean | 2000 | Sobolev 空间、迹、层势、BIE | 为项目函数空间、迹算子和边界积分映射性质提供基础 | `McLean2000` |
| `ref_data/books/Nakao2019.pdf` | *Numerical Verification Methods and Computer-Assisted Proofs for Partial Differential Equations* | Mitsuhiro T. Nakao; Michael Plum; Yoshitaka Watanabe | 2019 | 计算机辅助证明、特征值包含 | 定理 10.8（pp.356–357）两侧 Kato–Temple 界；第 10 章 Lehmann–Goerisch 与同伦法可用于谱隙认证 | `NakaoPlumWatanabe2019` |
| `ref_data/books/Reed1978(Vol4).djvu` | *Methods of Modern Mathematical Physics IV: Analysis of Operators* | Michael Reed; Barry Simon | 1978 | 算子谱理论 | 为自伴算子、谱分解和散射理论提供一般背景；身份由卷名与既有书目记录核对 | `ReedSimon1978` |
| `ref_data/books/Wilcox1984.pdf` | *Scattering Theory for Diffraction Gratings* | Calvin H. Wilcox | 1984 | 衍射光栅、Floquet 理论、散射 | 是周期光栅散射与辐射条件的系统理论参考 | `Wilcox1984` |

## 附属材料与未核验材料

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX 状态 |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/unsorted/report_legacy.pdf` | *Transmission Eigenvalue Problems in 1D Periodic Waveguide* | **无法可靠确认** | **无法可靠确认** | 一维周期波导、Bloch 理论、传输特征值 | 早期内部推导材料；缺作者、日期和出版信息 | 暂不收录 |
| `ref_data/Fliss2013_zh/` | `Fliss2013.pdf` 的中文翻译工程 | 非独立文献 | 未单列 | 翻译、LaTeX 构建材料 | 便于阅读核心参考文献，不作为独立来源引用 | 不收录 |
| `ref_data/Joly2006_zh/` | `Joly2006.pdf` 的中文翻译工程 | 非独立文献 | 未单列 | 翻译、LaTeX 构建材料 | 便于阅读核心参考文献，不作为独立来源引用 | 不收录 |

## 维护约定

- 新增文献时，先核验题名、作者、年份和 DOI，再更新本索引及 `reference.bib`。
- 文献原文件和翻译工程通过 `ref_data/` 访问，不由 Git 追踪；`ref/` 下只追踪本文件、`reference.bib` 和 `AGENTS.md`。`ref_data/` 是指向仓库上级 `TEP_ref/` 的符号链接，所有 worktree 共用同一份文献库。
- 对无法从原文或权威书目信息确认身份的材料，保留“无法可靠确认”标记，不补猜元数据。

2026-10-31散射方法调研新增公开全文：`Halla2018.pdf`、`Lawrence2026.pdf`、`Zhang2021.pdf`，不提交PDF。Nazarov2017只保留在线阅读与书目，下载HTTP 403后停止。完整访问、版本和核读证据见 [[research/explorations/bend-scattering-methods/landscape]]。
