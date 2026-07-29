# 参考文献索引

本目录保存周期波导、周期散射、边界积分方程和非线性特征值问题的参考资料索引。文献原文件和翻译工程位于上级目录的 `TEP_ref/`，并通过符号链接 `ref_data/` 从本目录访问。下表按研究主题归类；题名、作者和年份优先依据论文原文、DOI 页面或出版方页面核验。`BibTeX key` 指向同目录的 `reference.bib`。

文件名中的年份只用于本地识别，不一定等于正式出版年份。标为“暂不收录”的材料没有足够的书目信息，未写入 `reference.bib`。

下表“路径”列均相对于本目录，统一通过 `ref_data/` 访问实际资料。

## 周期波导、光子晶体与透明边界条件

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/Bonnet1995.pdf` | *Spectral Approximation of a Boundary Condition for an Eigenvalue Problem* | Anne-Sophie Bonnet-Ben Dhia; Nabil Gmati | 1995 | 光纤导模、Fourier 边界算子、谱逼近 | 证明截断 exact boundary operator 后导模特征值与特征函数的超代数先验收敛 | `BonnetBenDhiaGmati1995` |
| `ref_data/Boureghda2022.pdf` | *On Domain Error Truncation in a Problem of Guided Modes Computation in Optical Fibers* | Abdelouahab Boureghda; Abdelaziz Choutri; Hayat Rezgui | 2022 | 光纤导模、域截断、特征值误差 | 提供开放导模特征值随人工边界半径变化的指数型误差分析近邻 | `BoureghdaChoutriRezgui2022` |
| `ref_data/Choutri2008.pdf` | *Étude de l'erreur de troncature du domaine pour un problème aux valeurs propres* | Abdelaziz Choutri | 2008 | 光纤导模、Robin 边界、截断误差 | 给出光纤导模特征值与特征函数的先验域截断误差估计 | `Choutri2008` |
| `ref_data/Coatleven2012.pdf` | *Helmholtz Equation in Periodic Media with a Line Defect* | Julien Coatléven | 2012 | 线缺陷、Floquet–Bloch 变换、DtN | 研究带局部结构的周期介质与精确截断，是项目波导模型的直接背景 | `Coatleven2012` |
| `ref_data/Nittis2021.pdf` | *Spectral and Scattering Theory of One-Dimensional Coupled Photonic Crystals* | Giuseppe De Nittis; Marco Moscolari; Serge Richard; Rafael Tiedra de Aldecoa | 2021 | 一维耦合光子晶体、谱与散射理论 | 提供周期光子结构谱分解和散射算子的抽象背景 | `DeNittisEtAl2021` |
| `ref_data/Djellouli2000.pdf` | *A Local Boundary Condition Coupled to a Finite Element Method to Compute Guided Modes of Optical Fibres under the Weak Guidance Assumptions* | Rabia Djellouli; Chokri Bekkey; Abdelaziz Choutri; Hayat Rezgui | 2000 | 光纤导模、局部人工边界、FEM | 以局部 Robin 型条件近似 DtN，并用解析与文献参考值验证传播常数精度 | `DjellouliBekkeyChoutriRezgui2000` |
| `ref_data/Ehrhardt2009.pdf` | *Evaluation of Exact Boundary Mappings for One-Dimensional Semi-Infinite Periodic Arrays*（期刊版题名：*Evaluation of Scattering Operators for Semi-Infinite Periodic Arrays*） | Matthias Ehrhardt; Jiguang Sun; Chunxiong Zheng | 2009 | 半无限周期阵列、边界映射、倍增算法 | 为端口边界算子和递归倍增计算提供先例 | `EhrhardtSunZheng2009` |
| `ref_data/Engstrom2016.pdf` | *Efficient and Reliable hp-FEM Estimates for Quadratic Eigenvalue Problems and Photonic Crystal Applications* | Christian Engström; Stefano Giani; Luka Grubišić | 2016 | 二次特征值问题、hp-FEM、后验估计 | 提供光子晶体非线性特征值 residual/DWR estimator 与 effectivity 近邻 | `EngstromGianiGrubisic2016` |
| `ref_data/Fliss2013.pdf` | *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides* | Sonia Fliss | 2013 | 导模、DtN、光子晶体波导 | 项目导模与端口算子理论的核心参考 | `Fliss2013` |
| `ref_data/Fliss2015.pdf` | *Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides* | Sonia Fliss; Dirk Klindworth; Kersten Schmidt | 2015 | RtR 透明边界、导模 | 为有限计算域上的导模求解和透明边界构造提供比较框架 | `FlissKlindworthSchmidt2015` |
| `ref_data/Giani2013.pdf` | *An A Posteriori Error Estimator for hp-Adaptive Continuous Galerkin Methods for Photonic Crystal Applications* | Stefano Giani | 2013 | 光子晶体、hp-FEM、后验估计 | 阻断宽泛的光子晶体线缺陷特征值 estimator 创新声明，并提供 effectivity 基线 | `Giani2013` |
| `ref_data/Gopalakrishnan2025.pdf` | *Adaptive Resolution of Fine Scales in Modes of Microstructured Optical Fibers* | Jay Gopalakrishnan; Jacob Grosek; Gabriel Pinochet-Soto; Pieter VandenBerge | 2025 | 微结构光纤、泄漏模、自适应有限元、PML | 为复杂光纤模态的细尺度解析、损耗计算和误差控制提供数值参考 | `GopalakrishnanEtAl2025` |
| `ref_data/Hohage2013.pdf` | *Riesz Bases and Jordan Form of the Translation Operator in Semi-Infinite Periodic Waveguides* | Thorsten Hohage; Sofiane Soussi | 2013 | 平移算子、Riesz 基、Jordan 结构 | 支撑项目对端口传播算子谱结构的分析 | `HohageSoussi2013` |
| `ref_data/unsorted/huzhen6.pdf` | *Simple Boundary Condition for Terminating Photonic Crystal Waveguides* | Zhen Hu; Ya Yan Lu | 2012 | 光子晶体波导、近似边界条件 | 可与项目采用的精确端口条件比较计算成本和误差 | `HuLu2012` |
| `ref_data/Huang2007.pdf` | *Analyzing Photonic Crystal Waveguides by Dirichlet-to-Neumann Maps* | Yuexia Huang; Ya Yan Lu; Shaojie Li | 2007 | 光子晶体波导、DtN、模态分析 | 提供以超胞 DtN 将导模问题降维的数值方案 | `HuangLuLi2007` |
| `ref_data/Joly2006.pdf` | *Exact Boundary Conditions for Periodic Waveguides Containing a Local Perturbation* | Patrick Joly; Jing-Rebecca Li; Sonia Fliss | 2006 | 局部扰动、精确边界条件、Riccati 方程 | 是项目端口截断和局部缺陷波导问题的主要理论来源 | `JolyLiFliss2006` |
| `ref_data/Klindworth2015.pdf` | *On the Numerical Computation of Photonic Crystal Waveguide Band Structures* | Dirk Klindworth | 2015 | 线缺陷导模、DtN/RtR、非线性特征值 | 给出透明边界的高阶 FEM 实现与色散曲线追踪，并明确把 DtN/RtR 数值误差分析列为开放问题 | `Klindworth2015` |
| `ref_data/Li2007.pdf` | *Computing Photonic Crystal Defect Modes by Dirichlet-to-Neumann Maps* | Shaojie Li; Ya Yan Lu | 2007 | 缺陷模、DtN | 为缺陷模特征值计算和单元边界降维提供算法参考 | `LiLu2007` |
| `ref_data/Lin2025.pdf` | *An Adaptive Finite Element DtN Method for the Acoustic-Elastic Interaction Problem in Periodic Structures* | Lei Lin; Junliang Lv | 2025 | 周期散射、DtN 截断、后验误差 | 说明周期结构散射中可把 FEM residual 与可计算 DtN 截断项合并为 estimator | `LinLv2025` |
| `ref_data/Yu2022.pdf` | *PML and High-Accuracy Boundary Integral Equation Solver for Wave Scattering by a Locally Defected Periodic Surface* | Xiuchen Yu; Guanghui Hu; Wangtao Lu; Andreas Rathsfeld | 2022 | 局部缺陷周期面、PML、BIE、推进算子 | 与项目的半波导截断、Riccati 方程和衰减分析直接相关 | `YuHuLuRathsfeld2022` |
| `ref_data/Yuan2007.pdf` | *A Recursive-Doubling Dirichlet-to-Neumann-Map Method for Periodic Waveguides* | Lijun Yuan; Ya Yan Lu | 2007 | DtN、递归倍增、周期波导 | 是项目端口算子数值倍增策略的直接算法参考 | `YuanLu2007` |
| `ref_data/Yuan2008.pdf` | *Modeling Photonic Crystals by Boundary Integral Equations and Dirichlet-to-Neumann Maps* | Jianhua Yuan; Ya Yan Lu; Xavier Antoine | 2008 | 光子晶体、BIE、DtN | 说明如何用边界积分构造单胞 DtN 并计算带结构 | `YuanLuAntoine2008` |
| `ref_data/Zhang2023.pdf` | *A Spectral Decomposition Method to Approximate Dirichlet-to-Neumann Maps in Complicated Waveguides* | Ruming Zhang | 2023 | 谱分解、复杂波导、DtN 近似 | 为复杂端口上的 DtN 近似和谱截断提供现代方案 | `Zhang2023` |

## 周期散射、边界积分与高阶离散

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/unsorted/1-s2.0-S0021999124006314-main.pdf` | *Trapped Acoustic Waves and Raindrops: High-Order Accurate Integral Equation Method for Localized Excitation of a Periodic Staircase* | Fruzsina J. Agocs; Alex H. Barnett | 2024 | 周期阶梯、局域激励、高阶积分方程 | 与周期背景中的局域源、陷获波和高精度 BIE 计算相关 | `AgocsBarnett2024` |
| `ref_data/Arens2006.pdf` | *On Integral Equation and Least Squares Methods for Scattering by Diffraction Gratings* | Tilo Arens; Simon N. Chandler-Wilde; John A. DeSanto | 2006 | 光栅散射、积分方程、最小二乘 | 提供周期 Helmholtz 散射的积分方程与稳定性背景 | `ArensChandlerWildeDeSanto2006` |
| `ref_data/Barnett2010.pdf` | *A New Integral Representation for Quasiperiodic Fields and Its Application to Two-Dimensional Band Structure Calculations* | Alex H. Barnett; Leslie Greengard | 2010 | 准周期场、周期 Green 函数、能带 | 与项目准周期 Green 函数和 Bloch 参数计算直接相关 | `BarnettGreengard2010` |
| `ref_data/unsorted/1410.5003v1.pdf` | *Robust Fast Direct Integral Equation Solver for Quasi-Periodic Scattering Problems with a Large Number of Layers* | Min Hyung Cho; Alex H. Barnett | 2015 | 多层准周期散射、快速直接解法 | 为大规模周期分层结构的稳定积分方程求解提供参考 | `ChoBarnett2015` |
| `ref_data/Dominguez2016.pdf` | *Well-Posed Boundary Integral Equation Formulations and Nyström Discretizations for the Solution of Helmholtz Transmission Problems in Two-Dimensional Lipschitz Domains* | Víctor Domínguez; Mark Lyon; Catalin Turc | 2016 | Helmholtz 透射、BIE、Nyström | 为多介质界面方程的适定性和离散选择提供依据 | `DominguezLyonTurc2016` |
| `ref_data/Hao2014.pdf` | *High-Order Accurate Methods for Nyström Discretization of Integral Equations on Smooth Curves in the Plane* | Sijia Hao; Alex H. Barnett; Per-Gunnar Martinsson; Patrick Young | 2014 | Nyström、高阶求积、弱奇异核 | 是项目二维边界积分高阶离散的基础数值参考 | `HaoBarnettMartinssonYoung2014` |
| `ref_data/Hiptmair2022.pdf` | *Spurious Quasi-Resonances in Boundary Integral Equations for the Helmholtz Transmission Problem* | Ralf Hiptmair; Andrea Moiola; Euan A. Spence | 2022 | Helmholtz 透射、伪准共振、BIE | 用于辨别积分方程病态与真实物理共振 | `HiptmairMoiolaSpence2022` |
| `ref_data/Kress1991.pdf` | *Boundary Integral Equations in Time-Harmonic Acoustic Scattering* | Rainer Kress | 1991 | 声散射、边界积分方程 | 提供层势、跳跃关系与积分方程适定性的经典背景 | `Kress1991` |
| `ref_data/Linton1998.pdf` | *The Green's Function for the Two-Dimensional Helmholtz Equation in Periodic Domains* | C. M. Linton | 1998 | 周期 Helmholtz Green 函数、晶格和 | 是项目准周期/周期核函数构造的基础参考 | `Linton1998` |
| `ref_data/Lu2014.pdf` | *Efficient High Order Waveguide Mode Solvers Based on Boundary Integral Equations* | Wangtao Lu; Ya Yan Lu | 2014 | 波导模态、BIE、高阶算法 | 为项目模式求解器和边界离散提供直接算法参考 | `LuLu2014` |
| `ref_data/Lu2026.pdf` | *A Boundary Integral Equation Method for Wave Scattering in Periodic Structures via the Floquet–Bloch Transform* | Wangtao Lu; Kuanrong Shen; Ruming Zhang | 2026 | 局部扰动周期结构、Floquet–Bloch、BIE | 提供以背景 Green 函数和 Floquet–Bloch 逆变换处理非准周期散射的新方法 | `LuShenZhang2026` |
| `ref_data/Luan2019.pdf` | *A Meshless Numerical Method for Time Harmonic Quasi-Periodic Scattering Problem* | Tian Luan; Yao Sun; Zibo Zhuang | 2019 | 准周期散射、无网格方法 | 可作为项目边界积分离散之外的数值方法对照 | `LuanSunZhuang2019` |

## 非线性特征值、谱扰动与传输特征值

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/Bindel2013.pdf` | *Localization Theorems for Nonlinear Eigenvalue Problems* | David Bindel; Amanda Hood | 2013 | 非线性特征值、谱定位 | 为参数依赖算子特征值的包围和数值验证提供工具 | `BindelHood2013` |
| `ref_data/Guettel2017.pdf` | *The Nonlinear Eigenvalue Problem* | Stefan Güttel; Françoise Tisseur | 2017 | 非线性矩阵特征值、数值算法综述 | 为项目频率依赖算子和数值特征值算法提供统一框架 | `GuettelTisseur2017` |
| `ref_data/unsorted/Transmission Eigenvalues for Helmholtz Equation Perturbation Problems of Isotropic Media With Voids.pdf` | 《含空隙的各向同性介质 Helmholtz 方程扰动问题的传输特征值》 | 李诗璇；刘立汉 | 2023 | 传输特征值、折射率扰动、Neumann–Dirichlet 算子 | 与项目传输特征值的扰动理论和算子表述相关 | `LiLiu2023` |
| `ref_data/Moskow2015.pdf` | *Nonlinear Eigenvalue Approximation for Compact Operators* | Shari Moskow | 2015 | 紧算子、非线性特征值逼近、扰动 | 支撑项目对离散或参数扰动下特征值收敛的分析 | `Moskow2015` |
| `ref_data/Xi2024.pdf` | *Analysis of a Finite Element DtN Method for Scattering Resonances of Sound Hard Obstacles* | Yingxia Xi; Bo Gong; Jiguang Sun | 2024 | 散射共振、DtN 截断、非线性特征值 | 给出 DtN Fourier 截断与 FEM 离散下 holomorphic NEP 的特征值收敛估计 | `XiGongSun2024` |

## 专著与理论基础

| 路径 | 题目 | 作者 | 年份 | 主题 | 与本项目的关系 | BibTeX key |
| --- | --- | --- | ---: | --- | --- | --- |
| `ref_data/books/Colton1983 (CH3).pdf` | *Integral Equation Methods in Scattering Theory*, Chapter 3 | David Colton; Rainer Kress | 2013 重印；原版 1983 | 散射积分方程 | 本地文件是第 3 章节选；为层势与散射积分方程提供经典依据 | `ColtonKress1983` |
| `ref_data/books/Isakov2017.pdf` | *Inverse Problems for Partial Differential Equations*, 3rd ed. | Victor Isakov | 2017 | 反问题、唯一延拓、稳定性 | 为项目证明中使用的 Cauchy 唯一性与定量估计提供来源 | `Isakov2017` |
| `ref_data/books/Joannopoulos2011.pdf` | *Photonic Crystals: Molding the Flow of Light*, 2nd ed. | John D. Joannopoulos; Steven G. Johnson; Joshua N. Winn; Robert D. Meade | 2008 | 光子晶体物理与能带 | 提供周期介质、缺陷和导模的物理背景；文件名年份与版本版权页不一致 | `JoannopoulosJohnsonWinnMeade2008` |
| `ref_data/books/Kato1995.pdf` | *Perturbation Theory for Linear Operators*, 2nd ed. | Tosio Kato | 1995 | 闭算子、谱与扰动理论 | 是项目算子谱、解析族和特征值扰动的理论基础 | `Kato1995` |
| `ref_data/unsorted/Multiple scattering Interaction of time-harmonic waves with N obstacles (P. A. Martin) (Z-Library).pdf` | *Multiple Scattering: Interaction of Time-Harmonic Waves with N Obstacles* | P. A. Martin | 2006 | 多体散射、加法定理、积分方程 | 为多障碍散射和边界积分表示提供专著级参考；文件名显示来源标记，后续宜以合法来源副本替换 | `Martin2006` |
| `ref_data/books/McLean2000.pdf` | *Strongly Elliptic Systems and Boundary Integral Equations* | William McLean | 2000 | Sobolev 空间、迹、层势、BIE | 为项目函数空间、迹算子和边界积分映射性质提供基础 | `McLean2000` |
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
- 文献原文件和翻译工程通过 `ref_data/` 访问，其实际位置为仓库上级目录中的 `TEP_ref/`，不由 Git 追踪；`ref/` 下只追踪本文件、`reference.bib` 和 `AGENTS.md`。
- 对无法从原文或权威书目信息确认身份的材料，保留“无法可靠确认”标记，不补猜元数据。
