# 模型与已有方法覆盖

2026-10-31散射数值方法调查。本文的审查是 `Review only`；不修改所引原文，不把未检索到当成开放性证据。文献核读的T表示读到定理/算法及假设，P表示另核相关证明，A/M只表示摘要/元数据。T/P均不代表整篇证明复核。分工阅读的证据明确注明；独立review另有自己的证据，不自动升级主汇总阅读层级。

## 1. 固定模型，先避免三种误换

原项目接近质量型方程

$$-\Delta u-k^2\rho(x)u=f,\qquad 0<\rho_-\le\rho\le\rho_+<\infty.$$

在分片常系数介质界面上连续的是 $u$ 与普通法向导数；它不同于 $-\nabla\cdot(a\nabla u)-k^2u=f$ 的散度型模型及其加权通量条件。下面用 $\lambda=k^2$。局部坐标 $s_j$ 沿第 $j$ 条臂向外、$t_j$ 横向，不沿用旧直纤维的全局轴向约定。

**物理目标M0：** 全平面质量型介质，一个有限弯折/连接区，外部有两条渐近周期直线缺陷臂。两臂方向应与给定晶格相容；不预设蜂窝、120度、拓扑保护或小对比。输入为实频率和一个通量归一化入射导模，输出为导波散射矩阵及反/透射功率。固定频率时，应求各臂的传播相位根，而不是继续固定旧 $\beta$ 求 $k$。

若频率位于周围二维晶体的**完整bulk gap**，没有传播体Bloch通道，但存在倏逝bulk场；仅有某个轴向相位下的projected gap不够。若离开完整gap，弯角破坏全局平移对称，可能向体Bloch波辐射；仅取有限个导波通道的矩阵是总散射算子的子块，不能用 $R+T=1$ 作正确性证明。旧固定 $\beta=1/2$ 证书不证明上述全二维条件。

**解析/算法首个原型M1：** 有界横截面的二维波导，两条不相交半无限直条带出口通过有界中心区连接；物理侧壁明确取齐次Neumann或Dirichlet之一。各臂质量 $\rho_j(s_j,t_j)$ 沿 $s_j$ 周期、一般不可分离。它保留周期端口的临界簇困难，避免同时建立开放bulk辐射理论。M1是另一个清楚定义的模型，**不是给M0随意加墙后的等价问题**。

对于M0，在有界中心之外还存在连通的bulk区域，不能只给两个有限截面端口加独立DtN就称为精确截断。必须额外构造整个外部的出射算子，或对横向截断与bulk近似给可靠误差。该桥梁不列为本候选第一阶段成果。

## 2. 可复用与不能复用

| 现有资产 | 可复用 | 尚需新增/不能默认 |
|---|---|---|
| 胞Floquet、谱投影、Fourier补空间经验 | 周期臂的带边与临界谱簇分析 | 频率扫描时的准动量根及通量；零群速度不能靠旧符号选择 |
| BIE与单胞边界映射 | 分片常系数质量型胞问题；M1端口接口 | 全平面弯角没有全局准周期；不是重复旧一个 $\beta$ 的BIE |
| FEM与DtN/RtR | 中心区装配、胞解、模态/迹残差 | DtN（Dirichlet-to-Neumann，值到通量）自身极点、离散端口误差与物理共振需分开 |
| 连续谱排除及计数经验 | 带边隔离、补空间稳定门的技术起点 | 非自伴出射问题的逆常数/区间误差不是自伴惯性结论的直接应用 |
| 两路线数值一致 | 日后诊断算例的交叉检查 | 不构成连续散射误差上界，也不证明频窗无漏峰 |

## 3. 覆盖矩阵（最终筛选）

| 具体计算障碍 | 已有补救 | 本轮处理 |
|---|---|---|
| 倍增/传递矩阵的增长与衰减混合 | Riccati、DtN/RtR、散射矩阵与稳定子空间 | 不重命名为创新 |
| 周期端的同乘子正/负通量简并 | Zhang2021特殊频率插值/轮廓方案 | 它仍排除零群速度；不能称算法处理了全部截止 |
| 常系数圆柱出口的通道截止 | 增广波空间与固定维解析散射矩阵；两尺度Hardy元素/critical pole提取 | 强覆盖；候选必须超过常系数方案换算例 |
| 纵向不可分离周期端的驻波临界簇 | Hohage–Soussi结构；Nazarov2017周期阈值散射及2018/2019人工边界；Zhang2023非驻波DtN | 整簇和周期化不是创新；仅保留“连续截止位置误差→指定散射输出”的条件诊断 |
| 近共振全场误差界过松 | goal-oriented伴随、natural-norm、deflation与第二奇异值 | 单独作为新方向淘汰，见后续诊断 |
| 宽频实轴扫描漏窄峰 | 有理代理、自适应采样、轮廓/NEP、认证降阶与稳定下界 | 缺少独立新机制，暂不推荐；有限采样不可能性只作诊断 |
| 极小反射与 $1-T$ 消减误差 | 直接提取反射振幅、伴随输出估计、通量检查 | 单独更紧误差/改提取式价值不足 |

## 4. 首批已核原文

### L1 — 周期闭条带的轮廓与传播模方法

Ruming Zhang, **Numerical methods for scattering problems in periodic waveguides**, *Numerische Mathematik* **148**,959–996 (2021), DOI [10.1007/s00211-021-01229-0](https://doi.org/10.1007/s00211-021-01229-0)。[开放原文](https://link.springer.com/article/10.1007/s00211-021-01229-0)；本地 `ref/ref_data/Zhang2021.pdf`，2026-10-31合法下载，首页题名/作者/年份已核。

主汇总读§§2、6–8，阈值分工读Assumptions1–2及§8。质量型闭Neumann条带，正有界周期系数，紧支源；复轮廓积分与传播模分拆，FEM胞问题及半导源反演。§8允许同乘子同时有正负通量，但仍保持没有零群速度驻波。插值常数随特殊点附近参数可能退化，不提供无条件的阈值一致可计算误差。定理缺条件不等于程序在该点一定失效；这里只划定已证明保证。

### L2 — 已有直接散射振幅残差界

Scott Lawrence, Yukari Yamauchi, **Stable minimum principles for scattering states**, arXiv:2605.17139v1，提交2026-05-16，PDF题头2026-05-19。[作者原文](https://arxiv.org/html/2605.17139v1)；本地 `ref/ref_data/Lawrence2026.pdf`，2026-10-31下载并核首页。主汇总及输出分工T/P：Lemma2.4、Theorems2.6、2.8、2.11与§3。

短程自伴Schrödinger散射的 $L^1$ 残差直接控制振幅/截面，常数含精确测试散射态的 $L^\infty$ 范数；一般三维情形并未给统一显式控制，弱势及一维有较具体界。这不是周期端口定理，但已否定“第一次绕开全场误差给振幅界”的新颖性。近共振输入输出敏感性不会因写成残差最小化消失。

### L3 — 近核消去的严格输出界已于2006年出现

S. Sen, K. Veroy, D. B. P. Huynh, S. Deparis, N. C. Nguyen, A. T. Patera, **“Natural norm” a posteriori error estimators for reduced basis approximations**, *Journal of Computational Physics* **217**,37–62 (2006), DOI [10.1016/j.jcp.2006.02.012](https://doi.org/10.1016/j.jcp.2006.02.012)。[作者公开全文](https://www.mit.edu/~cuongng/publication/pub18/pub18.pdf)。主汇总核首页及Eq27–29；输出分工T/P：§2.1、§6.1 Lemmas6.1–6.2、Proposition6.3，印刷pp.54–55。

仿射参数非强制问题、固定有限维truth空间、参数域内正inf-sup下界。式(27)通过对偶残差在锚点危险模上的消去改善输出界，不要求原残差也正交；式(87)分母为锚点第二奇异值乘自然范数稳定下界，不应直接称为当前参数的第二奇异值下界。论文含近共振Helmholtz。把此deflation接到BIE/DtN不自动形成创新；连续BIC核及truth空间之外误差不在该结论中，但仅补这些假设也不自动值得立题。

### L4 — 2026开放波导网络已有高阶BIE算法

Tristan Goodwill, Charles L. Epstein, **A Numerical Method for Scattering Problems from Unbounded Interfaces**, *Journal of Scientific Computing* **107**,70 (2026-04-10), DOI [10.1007/s10915-026-03282-z](https://doi.org/10.1007/s10915-026-03282-z)。[开放全文](https://link.springer.com/article/10.1007/s10915-026-03282-z)。主汇总T（算法/模型）：§1式1.1、方法构造及数值例；尚未审其引用的全证明。

用分区出射Green函数、无界接口BIE及复坐标缩放处理decomposable网络；典型臂沿轴向平移不变、横向势紧支，另有半无限光栅后续。不同方向开放臂的计算并非未被研究。严格复缩放论证引用2025平行臂连接工作，不能把数值展示直接扩成所有周期晶体弯角的误差定理。

## 5. 阈值候选的关键竞争原文

访问日期均为2026-10-31；未下载者只给稳定原文/元数据链接。表中“未覆盖”只指读到的保证范围，不断言对应程序失效。

| 完整书目与原始链接 | 实际证据、假设与对候选的影响 |
| --- | --- |
| B. A. Plamenevskii, A. S. Poretskii, O. V. Sarafanov, **Method for computing waveguide scattering matrices in the vicinity of thresholds**, *St. Petersburg Mathematical Journal* 26(1),91–116 (2015；俄文2014), DOI [10.1090/S1061-0022-2014-01332-5](https://doi.org/10.1090/S1061-0022-2014-01332-5), [原平台条目](https://www.mathnet.ru/rus/aa1371) | 阈值分工A及少量原文公式；俄文PDF编码损坏，英文入口403。柱形Dirichlet端，固定维增广S、有限截断二次最小化、阈值邻域一致指数截断已有。不能据摘要扩成全离散可计算常数。 |
| Thorsten Hohage, Sofiane Soussi, **Riesz bases and Jordan form of the translation operator in semi-infinite periodic waveguides**, *J. Math. Pures Appl.* 100(1),113–135 (2013), DOI [10.1016/j.matpur.2012.10.013](https://doi.org/10.1016/j.matpur.2012.10.013), [作者稿v2](https://arxiv.org/html/1010.1738v2) | 主汇总核模型；阈值分工T：Theorem2.2 pp.4–5、AppendixA p.26。正质量周期半条带，广义Floquet/Jordan与Riesz结构已有。出射选择及迹空间适定假设不能省，整簇投影不自动等于LAP出射子空间。 |
| Martin Halla, Lothar Nannen, **Two scale Hardy space infinite elements for scalar waveguide problems**, *Advances in Computational Mathematics* 44,611–643 (2018；线上2017), DOI [10.1007/s10444-017-9549-5](https://doi.org/10.1007/s10444-017-9549-5), [开放PDF](https://link.springer.com/content/pdf/10.1007/s10444-017-9549-5.pdf) | 阈值分工T：§3.4 pp.627–628，Eq3.17；独立review另核§4。轴向齐次圆柱端，两尺度及临界极点提取已有。不预知横向模也可加临界极点；已指出近线性相关。p.624的arbitrarily small threshold指截断误差floor，不能误读为频率跨截止一致。 |
| S. A. Nazarov, **The asymptotic behaviour of the scattering matrix in a neighbourhood of the endpoints of a spectral gap**, *Sbornik: Mathematics* 208(1),103–156 (2017), DOI [10.1070/SM8624](https://doi.org/10.1070/SM8624), [英文原文](https://www.mathnet.ru/php/getFT.phtml?jrnid=sm&option_lang=eng&paperid=8624&what=fullteng) | 主汇总与阈值分工T/P：Theorems2–3 pp.123–125、Theorem5 p.131、Theorem11 p.150、§5.7 p.153。周期几何端接柱形端的Dirichlet问题，增广阈值S、临界共振判据及有权渐近已有；多周期臂并非新的基本机制。主汇总后续本地下载403，无PDF留存。 |
| S. A. Nazarov, **Finite-Dimensional Approximations of the Steklov–Poincaré Operator for the Helmholtz Equation in Periodic Waveguides**, *Journal of Mathematical Sciences* 232,461–502 (2018), DOI [10.1007/s10958-018-3890-1](https://link.springer.com/article/10.1007/s10958-018-3890-1) | 阈值分工A：周期Floquet波有限维人工边界、解与散射系数误差已在原摘要声明。全文订阅未核，不能断言排除截止；这是直接覆盖风险。 |
| S. A. Nazarov, **Finite-dimensional approximations to the Poincaré–Steklov operator for general elliptic boundary value problems in domains with cylindrical and periodic exits to infinity**, *Transactions of the Moscow Mathematical Society* 80,1–51 (2019；电子2020-04-01), DOI [10.1090/mosc/290](https://doi.org/10.1090/mosc/290), [公开俄文原稿条目](https://www.mathnet.ru/rus/mmo622) | 主汇总A；阈值分工英文全文403。**随后独立review T**：俄文p.3正质量、§2.4长度2 Jordan波、Theorems6.1/6.4、式4.29、§7.1。固定实频率、精确Floquet数据、极化矩阵条件下已有散射截断误差；常数依赖频率，不是全离散可计算联合界。主汇总未请求被拒入口。 |
| Christian Engström, **Spectral approximation of quadratic operator polynomials arising in photonic band structure calculations**, *Numerische Mathematik* 126(3),413–440 (2014), DOI [10.1007/s00211-013-0568-y](https://doi.org/10.1007/s00211-013-0568-y), [作者上传全文](https://www.researchgate.net/publication/257368235_Spectral_approximation_of_quadratic_operator_polynomials_arising_in_photonic_band_structure_calculations) | 独立review T：§§2.5、3–4、Theorem2、式91–99。适当线性化、广义Bloch特征空间Galerkin逼近及缺陷根降阶已有；可计算常数和物理S误差未据此自动闭合。 |
| Ruming Zhang, **A spectral decomposition method to approximate Dirichlet-to-Neumann maps in complicated waveguides**, *SIAM Journal on Numerical Analysis* 61(3),1195–1217 (2023), DOI [10.1137/22M1485425](https://doi.org/10.1137/22M1485425), [2022作者稿](https://arxiv.org/pdf/2207.12690) | 主汇总读引言，阈值分工T：Assumptions2、8、11、15，Theorem14 p.12、Eq38 p.16。两周期质量端、广义模DtN、指数尾与FEM误差已有。排除standing waves及相应半导/全域本征态；全离散率另需解析系数。 |

同乘子正/负非零通量交叉与零群速截止必须区分。出射定义可对照 Andreas Kirsch, Ben Schweizer, **Periodic waveguides revisited: Radiation conditions, limiting absorption principles, and the space of bounded solutions**, *Mathematical Methods in the Applied Sciences* 48(2),2267–2293 (2025；线上2024), DOI [10.1002/mma.10435](https://onlinelibrary.wiley.com/doi/full/10.1002/mma.10435)。独立review T：Assumption3.5、Theorem4.4、§5；不同吸收权重可能在交叉处选择不同出射子空间。最终候选因此固定谱参数正虚部，不把任意“加小损耗”当同一模型。

## 6. 近共振输出和频窗路线的淘汰证据

L2、L3之外，下表记录改变筛选决定的原文。更广但只读摘要的先例留在review，不能把摘要升级为已审定理。

| 完整书目与原始链接 | 实际证据及边界 |
| --- | --- |
| B. A. Plamenevskii, O. V. Sarafanov, **On a Method for Computing Waveguide Scattering Matrices in the Presence of Point Spectrum**, *Functional Analysis and Its Applications* 48(1),49–58 (2014), DOI [10.1007/s10688-014-0045-0](https://doi.org/10.1007/s10688-014-0045-0), [2011作者稿](https://arxiv.org/html/1106.5975v1) | 独立review T：§2、Theorem2.3。圆柱端、远离阈值、允许俘获模；Robin辅助问题最小化直接逼近S。因此场不唯一而S可算不是新切口。未声明周期端/全离散常数已有。 |
| Sridhar Chellappa, Lihong Feng, Valentin de la Rubia, Peter Benner, **Inf-Sup-Constant-Free State Error Estimator for Model Order Reduction of Parametric Systems in Electromagnetics**, *IEEE Transactions on Microwave Theory and Techniques* 71(11),4762–4777 (2023), DOI [10.1109/TMTT.2023.3288642](https://doi.org/10.1109/TMTT.2023.3288642), [作者稿](https://arxiv.org/pdf/2104.12802) | 输出分工T：v3 §3 Theorem1；界中余项仍是未知误差。MPG条目403，未重试；作者公开稿已读。标题不能代替可计算性核查。 |
| Lihong Feng, Sridhar Chellappa, Peter Benner, **A posteriori error estimation for model order reduction of parametric systems**, *Advanced Modeling and Simulation in Engineering Sciences* 11,5 (2024), DOI [10.1186/s40323-024-00260-8](https://link.springer.com/article/10.1186/s40323-024-00260-8) | 输出分工T：Remark1排除PDE离散误差，Theorem7用逆范数控制二次残差。因此不含inf-sup的实践估计不自动形成全连续保证。 |
| Ya Yan Lu, Jiaxin Zhou, **Local Robustness of Bound States in the Continuum through Scattering-Matrix Eigenvector Continuation** (2026), [arXiv:2603.08489v1](https://arxiv.org/html/2603.08489v1) | 输出分工T：Lemma3.2、Lemma4.1/Theorem4.1、§7。周期Helmholtz，BIC处S与局部增广可逆性已有；绕数数值步骤未给完整误差半径。不能认领首次BIC增广。 |
| Stephen P. Shipman, Hairui Tu, **Total Resonant Transmission and Reflection by Periodic Structures**, *SIAM Journal on Applied Mathematics* 72(1),216–239 (2012), DOI [10.1137/110834196](https://doi.org/10.1137/110834196), [作者稿v2](https://arxiv.org/html/1105.2906v2) | 输出分工T：§3.2 Theorem12。正介质板、镜像、单传播谐波及泛性条件；BIC附近全反/全透曲线说明S有界不等于联合参数稳定。不是任意双臂模型的定理。 |
| Lei Lin, Junliang Lv, **An Adaptive Finite Element DtN Method for the Acoustic-Elastic Interaction Problem in Periodic Structures** (2025), DOI [10.1007/s10444-025-10253-9](https://doi.org/10.1007/s10444-025-10253-9), [作者稿v1](https://arxiv.org/html/2504.17233v1) | 输出分工T：Eq26与§4 Theorem1。残差+指数DtN尾已存在；inf-sup由唯一性得到，常数和足够大截断阶不全部显式。模型为声弹耦合，不能直接代入质量型阈值问题。 |
| Ralf Hiptmair, Andrea Moiola, Euan A. Spence, **Spurious Quasi-Resonances in Boundary Integral Equations for the Helmholtz Transmission Problem**, *SIAM Journal on Applied Mathematics* 82(4),1446–1469 (2022), DOI [10.1137/21M1447052](https://doi.org/10.1137/21M1447052), [作者稿v4](https://arxiv.org/html/2109.08530v4) | 独立review T：Theorems1.10–1.12、1.15。BIE逆混入交换材料问题；已有Calderón约束增广。因此矩阵逆峰不能自动等于物理反射峰。 |
| Davide Pradovera, Ralf Hiptmair, Ilaria Perugia, **Surrogate Modeling of Resonant Behavior in Scattering Problems Through Adaptive Rational Approximation and Sketching**, *Journal of Scientific Computing* 104,104 (2025), DOI [10.1007/s10915-025-03020-x](https://doi.org/10.1007/s10915-025-03020-x), [作者稿v2](https://arxiv.org/html/2503.10194v2) | 主汇总核摘要，频窗分工与独立review T：原稿§§2–5，Theorem3.1、Proposition3.4、Algorithms2–4。BIE逆的有理代理/sketch已有；停止和采样含启发式，不是连续S全频不漏峰保证。PMC正文曾正常读取，后出现reCAPTCHA，不重开该路径。 |
| Davide Pradovera, **Toward a certified greedy Loewner framework with minimal sampling**, *Advances in Computational Mathematics* 49,92 (2023), DOI [10.1007/s10444-023-10091-7](https://doi.org/10.1007/s10444-023-10091-7), [作者稿](https://arxiv.org/pdf/2303.01015) | 频窗分工T：Propositions1–2及§4。状态残差形状与输出余因子分开；输出因子不可由黑盒样本直接算，且状态/输出极点相消影响假设。不能把certified标题读成无遗漏停止保证。 |
| Matthew J. Colbrook, Alex Townsend, **Avoiding Discretization Issues for Nonlinear Eigenvalue Problems**, *SIAM Journal on Matrix Analysis and Applications* 46(1),648–675 (2025), DOI [10.1137/23M1569927](https://doi.org/10.1137/23M1569927), [作者稿](https://arxiv.org/pdf/2305.01691) | 频窗分工T：23页v1 §2.2、Theorem2.3；未审期刊28页版。无限维轮廓方法及伪谱内包含不自动证明所有连续极点无遗漏，相关步骤仍需总数/秩信息。 |
| Goele Pipeleers, Lieven Vandenberghe, **Generalized KYP Lemma With Real Data**, *IEEE Transactions on Automatic Control* 56(12),2942–2946 (2011), DOI [10.1109/TAC.2011.2161945](https://doi.org/10.1109/TAC.2011.2161945), [作者全文](https://www.seas.ucla.edu/~vandenbe/publications/gkyp.pdf) | 频窗分工T：§II Theorem1、§IV Theorem2。有限状态有理系统的频带二次不等式可化LMI；须核无极点等条件。不能用黑盒采样反例否定这些intrusive方法；连续非有理DtN仍需桥接。 |

## 7. 2025–2026检索确实读到了什么

本轮实际检索日期为2026-10-31，围绕数值散射关键词和上述原文参考链，覆盖经典方法及2025–2026出版/预印本；不是系统综述或穷尽全部数据库。下列近年材料有具体核读，不能泛称“最新文献均未解决”：

- Andreas Kirsch, Ruming Zhang, **The PML-method for a scattering problem for a local perturbation of an open periodic waveguide**, *Numerische Mathematik* 157,717–748 (2025), DOI [10.1007/s00211-025-01456-9](https://link.springer.com/article/10.1007/s00211-025-01456-9)。阈值分工/独立review T：Assumptions3、7、10、Theorem19等。开放周期层，上方均匀，排除相关导模/截止碰撞及零通量，不能删条件套到本候选。
- Tilo Arens, N. Shafieeabyaneh, Ruming Zhang, **Scattering problems in periodic or locally perturbed periodic domains: Convergence of the perfectly matched layer approximation and efficient numerical solution**, KIT Report2026/21，DOI [10.5445/IR/1000194519](https://publikationen.bibliothek.kit.edu/1000194519)。阈值分工T：§2、Condition3及算法；声软周期图形表面，Rayleigh分支与Schur计算已有，不是一般质量型周期臂的驻波端点。
- Wangtao Lu, Kuanrong Shen, Ruming Zhang, **A boundary integral equation method for wave scattering in periodic structures via the Floquet-Bloch transform**, *Journal of Computational Physics* 558,114850 (2026), DOI [10.1016/j.jcp.2026.114850](https://doi.org/10.1016/j.jcp.2026.114850)，[2025作者稿](https://arxiv.org/abs/2512.12414)。主汇总核出版预览，阈值分工T：§3.2及§7；横向均匀背景夹周期层，当前算法排除导模极点，不能把结论读成任意周期波导弯角。
- Lawrence–Yamauchi 2026、Lu–Zhou 2026、Goodwill–Epstein 2026分别见L2、§6、L4，均读到正文；它们改变了“直接输出界”“BIC增广”“开放臂BIE未研究”的宽泛创新判断。
- Michael S. Ackermann, Linus Balicki, Serkan Gugercin, Steffen W. R. Werner, **A refined nonlinear least-squares method for the rational approximation problem**, *Research in the Mathematical Sciences* 13,82，**2026-10-26**，DOI [10.1007/s40687-026-00668-1](https://doi.org/10.1007/s40687-026-00668-1)。频窗分工T：§2.3、§4.3 Eq57；离散样本误差改进不是连续频窗认证。此为本轮实际核读的最新出版日期之一，不能据此声称2026年文献覆盖完整。

## 8. 证据缺口、访问限制与决定

| 项目 | 对交付的影响 | 下一步/状态 |
| --- | --- | --- |
| Nazarov2018全文未核；2019已由独立review核俄文关键条件 | 2019覆盖显著增强；仍不能宣称联合可计算保证已有或开放 | 基于已读条件作逐步算法比较；2018保留A，英文403不重试/绕过 |
| PPS2015俄文编码损坏、英文入口403 | 关键算法摘要已足以否决宽泛新颖性；不能编造定理编号 | 保留A/部分原文等级 |
| Nazarov2017网页可读、随后本地curl下载403 | 理论引用仍有此前T/P证据；没有本地副本 | 不重试或换路径绕过，记录准确结果 |
| MPG条目403、PMC后续reCAPTCHA、个别DOI跳转失败/超时 | 仅影响各自访问路径；可用已正常读到的公开作者稿，不宣称下载成功 | 分工及review记录具体来源，不重试拒绝路径 |
| 真实M0开放bulk未在本轮形成完整误差证书 | **适用范围限制**，不能将M1称原模型已解决；也不能称M0尚无算法 | 已完成直接模型核验，见open-crystal及review §§18–20 |
| 旧方法未被证明在目标例失效 | 限制价值判断；定理范围差异不是算法失败证据 | 先作理论诊断，未启动实验 |

最终建议见 [[research/explorations/bend-scattering-methods/recommendation]]。本轮没有证明新散射主定理，也没有确认一个可直接正式立项的方法空白。

## 9. 原开放晶体几何的直接方法

为避免用硬壁条带先例代替原模型，后半轮单独核了Hu–Lu2008、Pissoort等2005/2007、Mingaleev–Kivshar2002等原始算法，以及Fliss/Coatléven的连续归约。完整书目和覆盖矩阵集中在 [[research/explorations/bend-scattering-methods/open-crystal]]；独立审查为 [[research/explorations/bend-scattering-methods/review]] §§16–21。不重复把这些条目复制成第二份长目录。

核验发现：无限二维背景、局部弯角、半无限导波臂的实际方法已有直接覆盖。连续误差保证、人工表面谱、核尾及倏逝尾的限制应准确保留，但“原模型更复杂”本身没有恢复候选新颖性。最终仍是零项正式推荐。
