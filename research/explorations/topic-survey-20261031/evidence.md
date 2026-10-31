# 文献证据与方向淘汰记录

本文件只服务本轮 [[research/explorations/topic-survey-20261031/README|选题调研]]，不是新定理证明。

证据层级：T=读到原文定理及所列假设；P=另核相关证明段；A=作者摘要；M=元数据。T/P不代表整篇证明独立复核。每项保留完整书目、稳定链接、核读位置、已覆盖范围和剩余问题；只读摘要不能用来断言原文没有某个结论。

## 执行记录

- 2026-10-31 01:50起重新核验工作区和现有探索；没有沿用旧A/B/C作为三个推荐名额。
- 所有结论以本轮实际原文查证及明确旧来源记录为依据；分工的核读范围与主汇总者核读分开记载。未完成全篇证明独审。
- 实际检索日期为2026-10-31，范围包含经典谱理论与明确的2025、2026检索；深入核读的新近原文包括Drouot的2026-09-15版本、Hislop等2026-09-27的定理范围，以及Ammari–Qiu的2026-10-07定理设定；Han等2026-08-11正文也已核。2026-10-16的modified-Haldane论文仅出版商接受记录/摘要，不能说已审核其定理或最新全年文献。未采用聚合站自动概述作为定理证据。

## 价值筛选准则

1. 结果是否改变对存在、传输、泄漏、容量或设计限制的认识？
2. 是否超出单点后验误差、常规参数延拓或旧定理换算例？
3. 最近邻强定理已经回答什么；剩余部分是否实质而非形式换模型？
4. 先做哪个便宜的引理或反例就能决定继续或退出？
5. 若缺条件、找不到可实现机制或已有覆盖，直接降级，不为三个名额强行维持。

## E1：尖角传播模的存在与高透射不是同一结论

Habib Ammari, Jiayu Qiu, **Robustness of Valley-Hall Interface Modes Against Sharp Bending**, arXiv:2605.29485v2, 2026-07-11（v1为2026-05-28）。[原文](https://arxiv.org/html/2605.29485v2)。访问2026-10-31。证据T/P：§2 Assumptions 2.1–2.4、2.7；Theorem 2.8；§3.3；§1.3。

光滑实正系数的二维散度型算子、三角晶格、旋转/反射/反演对称及Dirac点、no-fold条件；小反演破缺产生完整bulk gap。另假设直界面导模带在整个Brillouin区均与其余谱隔离，研究频段群速度非零。弯角为 $2\pi/3$。定理在有限例外集外给两个广义传播模及远场振幅；例外处角点束缚模至多有限重。

**定理的振幅条件本身不保证高透射。** 原文已经在式(2.16)明确给出散射矩阵；将式(2.14–2.15)的奇偶解各取一半也可消去右侧入射。记该文单位复数 $\beta$ 为 $b$（避免与本项目准动量混淆），其余两个单位相位为 $b_o,b_e$；在该文相同通量规范下

$$r=(b_o+b_e)/2,\qquad t=b(b_e-b_o)/2,$$

$$R=\cos^2\!\big((\arg b_e-\arg b_o)/2\big),\quad T=\sin^2\!\big((\arg b_e-\arg b_o)/2\big).$$

散射振幅是**原文已有公式**，功率是其模方，不是本轮新定理。单位模长只给 $R+T=1$；高透射还需要奇偶相位差接近 $\pi$。也未证明任意相位组合都由该PDE实现，不能称为已有低透射反例。选题应问控制这个相位差的实质条件，而非再证明弯后有模。

## E2–E4：尖角高透射已有物理机制与反例线索

- **E2** Wei Dai, Taiki Yoda, Yuto Moritake, Masaaki Ono, Eiichi Kuramochi, Masaya Notomi, **High transmission in 120-degree sharp bends of inversion-symmetric and inversion-asymmetric photonic crystal waveguides**, *Nature Communications* **16**, 796 (2025)。DOI [10.1038/s41467-025-56020-8](https://doi.org/10.1038/s41467-025-56020-8)；[作者全文v2](https://arxiv.org/html/2310.17487v2)。已读Discussion、Table 1说明、补充§§2、5–6：数值/实验比较支持domain-wall配置的重要性；polarization singularity解释明确是推测。不得把“拓扑标签不保证高透射”当首次发现，也不将仿真归纳提升为PDE定理。
- **E3** Theo Torres, Cédric Bellis, Régis Cottereau, Antonin Coutant, **Canonical scattering problem in topological metamaterials: Valley-Hall modes through a bend**, *Proceedings of the Royal Society A* **480**, 20230905 (2024)。DOI [10.1098/rspa.2023.0905](https://doi.org/10.1098/rspa.2023.0905)；[全文v2](https://arxiv.org/html/2312.04396v2)（初稿2023）。已读§§II.1、IV.2–IV.4及结论：graphene-ribbon tight-binding、transfer matrix反透射，有限宽和定位长度竞争；反射随质量参数并不简单单调。零反射点为数值精度内结果，不是连续PDE严格零反射定理。
- **E4** Tirth Shah, Florian Marquardt, Vittorio Peano, **Tunneling-induced fractal transmission in valley Hall waveguides**, *Physical Review B* **107**, 054304 (2023)。DOI [10.1103/PhysRevB.107.054304](https://doi.org/10.1103/PhysRevB.107.054304)；[作者全文](https://arxiv.org/html/2209.06188v2)（初稿2022）。已读§§I、VI、Appendix C：包络近似抑制大动量转移，硬界面/较大gap的反射可依赖方向和corner相对晶格位置；紧束缚数值及Dirac解释。没有完成全文渐近余项审查，不能据此宣布相邻问题开放。

## E5：没有完整gap时分叉共振/BIC已有定理

Jiayu Qiu, Hai Zhang, **On the bifurcation of a Dirac point in a photonic waveguide without band gap opening**, *Journal of Functional Analysis* **291**(1), 111472 (2026)。DOI [10.1016/j.jfa.2026.111472](https://doi.org/10.1016/j.jfa.2026.111472)；[作者全文v2](https://arxiv.org/html/2310.17964v2)（2025-05-26；初稿2023）。访问2026-10-31。证据T/P：§1.1 Assumptions 1.1–1.3、1.6，Theorem 1.8，Remark 1.9，§1.2证明路线。

模型为有界横截面的周期Neumann条带，正折射率、反射对称；相关带在Dirac点及远处准动量同能；正负小扰动在接合处相拼，非零耦合打开局部gap。定理给近Dirac的实嵌入模或下半平面共振，按与远处传播Bloch通道的耦合区分。

**淘汰**“局部gap而非完整gap可能泄漏或成为BIC”作为新选题。本文不是整个二维平面线缺陷的局部纵向散射定理；模型不同也不自动意味着有创新。出版社页面open返回403，未重试；核读来源是公开作者arXiv HTML。

## E6–E8：慢变、粗糙辐射与阈值展开已有基线

- **E6** Steven G. Johnson, Peter Bienstman, M. A. Skorobogatiy, Mihai Ibanescu, Elefterios Lidorikis, J. D. Joannopoulos, **Adiabatic theorem and continuous coupled-mode theory for efficient taper transitions in photonic crystals**, *Physical Review E* **66**, 066608 (2002)。DOI [10.1103/PhysRevE.66.066608](https://doi.org/10.1103/PhysRevE.66.066608)；[作者稿](https://math.mit.edu/~stevenj/papers/JohnsonBi02.pdf)。主汇总者A/M；分工研究者读作者稿。要求整个taper相应模持续传播且被导引。淘汰不带新阈值机制的一般慢taper选题。
- **E7** Steven G. Johnson, Michelle L. Povinelli, Marin Soljačić, Aristeidis Karalis, Steven Jacobs, J. D. Joannopoulos, **Roughness losses and volume-current methods in photonic-crystal waveguides**, *Applied Physics B* **81**, 283–293 (2005)。DOI [10.1007/s00340-005-1823-4](https://doi.org/10.1007/s00340-005-1823-4)；[作者稿](https://math.mit.edu/~stevenj/papers/JohnsonPo05.pdf)。分工核§§1–2、4及群速/Van Hove讨论：已有不完整gap、Born辐射、局部态密度、隐藏共振。淘汰把单点谱证书接到常规Born公式当主创新。
- **E8** Serge Richard, Rafael Tiedra de Aldecoa, **Resolvent expansions and continuity of the scattering matrix at embedded thresholds: the case of quantum waveguides**, *Bulletin de la Société Mathématique de France* **144** (2016), 251–277。DOI [10.24033/bsmf.2713](https://doi.org/10.24033/bsmf.2713)；[作者稿v2](https://arxiv.org/html/1402.0373v2)。分工T：Props.3.2、3.8，硬壁直管、紧支撑实有界势。阈值预解式展开和散射连续性已有结果，不能直接迁移开放二维周期介质。

## E9：2026年9月单谷Dirac无反射定理与明确的连续模型延伸问题

Alexis Drouot, **Reflectionless edge states in Dirac models of topological insulators**, arXiv:2609.16949v1 (2026-09-15)。[全文](https://arxiv.org/html/2609.16949v1)。主汇总者与接口分工均核读§§1.1–1.4、Theorem 1.1。

单谷 $2\times2$ Dirac算子，实有界质量墙，两条远场直臂，角度在 $(-\pi,\pi)$，允许有界区域任意墙变形；在横向首个正谱阈值内、局部有限例外集外，得到唯一畸变平面波且 $|t|=1$。§1.4直接讨论能否把此完全透射结论延续到Ammari–Qiu模型；§1.2也已有相位导数与延迟、共振的联系。故这些不能认领为本轮新成果。

该论文提供**作者明确提出的延伸研究问题**，比“没搜到”强；但不是对本报告具体双谷散射渐近之新颖性的穷尽认证。目标须放在连续PDE到有效模型的实频散射桥梁和首个反射项，不能再证明单谷定理。

Alexis Drouot, Michael I. Weinstein, **Edge states and the valley Hall effect**, *Advances in Mathematics* **368**, 107142 (2020)，DOI [10.1016/j.aim.2020.107142](https://doi.org/10.1016/j.aim.2020.107142)；[作者稿](https://arxiv.org/abs/1910.03509)。接口分工T：Theorem 5.1为直线有理边、固定平行准动量纤维、避开有效Dirac谱的预解式展开；并非弯角全空间的出射实频散射逼近。把它接到2026定理还需控制弱破缺与极限吸收的联合极限。

## E10–E15：延迟—带宽的最强先例与模型门

- **E10** Owen D. Miller, Francesco Monticone, **Fundamental limits in photonics and electromagnetics: a tutorial**, arXiv:2605.24738v1 (2026-05-23)。[全文§5.9](https://arxiv.org/html/2605.24738v1#S5.SS9)，DOI [10.48550/arXiv.2605.24738](https://doi.org/10.48550/arXiv.2605.24738)。主汇总及容量分工已读式(224–225)及节末。作者明确提出一般二维/三维延迟—带宽界的研究问题；不等于确认本报告子类未被旧定理覆盖。
- **E11** David A. B. Miller, **Fundamental limit for optical components**, *Journal of the Optical Society of America B* **24**, A1–A18 (2007)。DOI [10.1364/JOSAB.24.0000A1](https://doi.org/10.1364/JOSAB.24.0000A1)；[作者全文](https://ee.stanford.edu/~dabm/331.pdf)。容量分工T/P：§2D–E、式(31)、pp.A5–A6，§§3–4。一般线性多重散射、材料响应有界、指定源子空间上的Green紧性/可迹条件下，给可控制正交输出数上界。理论不限1D；1D是显式估计例子。它是延迟候选最强的覆盖威胁：必须先检查周期lead迹估计是否直接给线性长度界。
- **E12** David A. B. Miller, **Fundamental Limit to Linear One-Dimensional Slow Light Structures**, *Physical Review Letters* **99**, 203903 (2007)。DOI [10.1103/PhysRevLett.99.203903](https://doi.org/10.1103/PhysRevLett.99.203903)；[作者全文](https://ee.stanford.edu/~dabm/337.pdf)。容量分工及独立review读式(3)、(6–7)：一维、相对窄带、长度足够大，延迟比特数受长度和介电反差约束；包含单模模式重叠推广的说明。延迟—带宽转写还使用脉宽关系，不能跳过定义差异。
- **E13** Jussi Behrndt, Fritz Gesztesy, Shu Nakamura, **Spectral shift functions and Dirichlet-to-Neumann maps**, *Mathematische Annalen* **371**, 1255–1300 (2018；线上2017)。DOI [10.1007/s00208-017-1593-4](https://doi.org/10.1007/s00208-017-1593-4)；[作者稿](https://arxiv.org/abs/1609.08292)。容量分工T/P：§1式(1.1)、§4、Hypothesis5.1、Theorem6.1。预解式幂差可迹条件下，抽象Weyl函数/DtN的谱移表示已有；应用于光滑紧边界椭圆问题和紧支撑Schrödinger势。“首次用DtN表示谱移”淘汰。
- **E14** Adrian Dietlein, Martin Gebert, Peter D. Hislop, Abel Klein, Peter Müller, **A Bound on the Averaged Spectral Shift Function and a Lower Bound on the Density of States for Random Schrödinger Operators on $\mathbb R^d$**, *International Mathematics Research Notices* **2018**(21), 6673–6697。DOI [10.1093/imrn/rnx092](https://doi.org/10.1093/imrn/rnx092)；[出版原文](https://academic.oup.com/imrn/article/2018/21/6673/3792081)。容量分工T：条件(K)、(V1–2)、Theorems2.6–2.7、Remark2.9。随机alloy模型局域化区给**期望**DN谱移界。引言说明多维切界不是有限秩且一般大盒谱移可失控；不能直接将有限盒Weyl计数视为散射相位界，也不能将该反例当本候选固定gap lead的反例。
- **E15** Jean-Claude Cuenin, **Effective upper bounds on the number of resonances in potential scattering**, *Mathematika* **71**, e70000 (2025；线上2024-11-19)。DOI [10.1112/mtk.70000](https://doi.org/10.1112/mtk.70000)；[作者全文v2](https://arxiv.org/html/2209.06079v2)。容量分工T：Theorems1.1、7.1、§1.5。奇数维 $d\ge3$、复势散射，给势范数显式共振计数；不是二维周期密度模型，但行列式/Jensen计数本身早已成熟。

**必须先做的否证门。** 若E11在固定lead的Green核上作常规迹估计，就能直接推出目标指标的 $O(L)$ 界，则应降级为已有理论应用，不能因为E10提出宽泛问题就继续强推。单个窄全通峰的延迟积分为常数量级，不是固定资源乘积界反例；真正要数的是可用相位周转及其资源成本。

**两端口与谱移的适用边界。** 固定互易通量规范后，$\det S=-t/t^*$，于是相对透射相位导数等于相对散射行列式相位导数的一半；这只是代数事实。建立Birman–Krein公式后，也不能忽略与通道解耦的BIC所造成的整数跳跃；指数形式的公式看不见这个整数。高透射并不排除BIC。相对散射通道识别、谱移归一化和可能奇异部分需另核。

对质量型问题，$U_\rho u=\sqrt\rho\,u$ 将算子转成固定空间上的 $H_\rho=\rho^{-1/2}(-\Delta)\rho^{-1/2}$，形式域随密度变化。二维一阶预解式差不自动可迹；应先核高次预解式幂差及不变性原理。将 $-\omega^2(\rho-\rho_0)$ 当固定势套用通常Schrödinger谱移定理不正确。本轮未证明这些适用性条件。

## E16–E20：双谷合并、真实模数与截止

- **E16** Sahand Mahmoodian, Christopher G. Poulton, Kokou B. Dossou, Ross C. McPhedran, Lindsay C. Botten, C. Martijn de Sterke, **Modes of shallow photonic crystal waveguides: semi-analytic treatment**, *Optics Express* **17**(22), 19629–19643 (2009)。DOI [10.1364/OE.17.019629](https://doi.org/10.1364/OE.17.019629)；[作者上传/出版商提供的公开全文](https://www.researchgate.net/publication/40483998_Modes_of_Shallow_Photonic_Crystal_Waveguides_Semi-Analytic_Treatment)；[作者机构记录](https://web-tools.uts.edu.au/publications/search.cfm?unitId=53&year=2009)。阈值分工核§§4–5、pp.19638–19642；主汇总核§5公开原文段。六角TE例子 $n_b=3,n_c=1,r=0.3d$，近 $k_xd=1.956$ 的双谷合并。作者明确二次展开/分离包络失效，数值截止随缺陷移动。它给具体科学疑问，不提供本报告所求联合连续计数定理。
- **E17** J. Scott Brownless, Sahand Mahmoodian, Kokou B. Dossou, Felix J. Lawrence, Lindsay C. Botten, C. Martijn de Sterke, **Coupled waveguide modes in hexagonal photonic crystals**, *Optics Express* **18**, 25346–25360 (2010)。DOI及[出版原文入口](https://doi.org/10.1364/OE.18.025346)。阈值分工读出版商检索返回的§§2–4及附录；§2假设单波导模已算出，§4改变双波导间距。复带分叉、耦合尾场和多次交叉已有；并非对E16单波导近合并过渡层的修复。直接open工具读取失败，未重试该动作；读取深度限于返回内容。
- **E18** B. M. Brown, V. Hoang, M. Plum, M. Radosz, I. Wood, **Gap localization of multiple TE-Modes by arbitrarily weak defects**, *Journal of the London Mathematical Society* **102**, 773–795 (2020)。DOI [10.1112/jlms.12337](https://doi.org/10.1112/jlms.12337)；[全文作者稿](https://arxiv.org/html/1901.05102v1)（作者稿题名为 *Gap Localization of TE-Modes by arbitrarily weak defects – multiband case*）。本轮阈值分工及独审重新核Assumptions1–3、Theorems1–3。正有界TE系数、横向局部正介电增加、固定轴向准动量、所有边点二次下界，给小缺陷精确纤维gap模数。四次合并违反关键二次下界；这仅说明不能直接套定理，不单独证明新颖性。
- **E19** Jonathan Arazy, Leonid Zelenko, **Virtual Eigenvalues of the High Order Schrödinger Operator II**, *Integral Equations and Operator Theory* **55**, 305–345 (2006)。DOI [10.1007/s00020-005-1390-4](https://doi.org/10.1007/s00020-005-1390-4)；[官方作者稿](https://www.esi.ac.at/preprints/esi1706.pdf)。沿用上轮T/P核查：Theorem3.4、稿内pp.12–13；一维 $D^4-\varepsilon V$、非负衰减及有限矩势，两个弱态和不同阶渐近已有。$\varepsilon^{4/3}$、$\varepsilon^4$ 不是新发现；本轮没有重证或把玩具系数搬进二维材料。
- **E20** Sahand Mahmoodian, Andrey A. Sukhorukov, Sangwoo Ha, Andrei V. Lavrinenko, Christopher G. Poulton, Kokou B. Dossou, Lindsay C. Botten, Ross C. McPhedran, C. Martijn de Sterke, **Paired modes of heterostructure cavities in photonic crystal waveguides with split band edges**, *Optics Express* **18**, 25693–25701 (2010)。DOI [10.1364/OE.18.025693](https://doi.org/10.1364/OE.18.025693)；[作者机构记录](https://digitalcollections.anu.edu.au/items/3c52b421-dd49-4e17-a830-cae611250276)。A/M及部分原文：在既有导波分支双带边上造腔；不是二维bulk projected edge合并。未做全文复核，不据此断言全部覆盖范围。

TE候选的精确对象为 $L_{\varepsilon,\beta}=-(\nabla+i\beta e_x)\cdot(a_0-\varepsilon v)(\nabla+i\beta e_x)$，$a_0>0$ 双周期，$v\ge0$ 轴向周期且横向紧支撑，保持一致椭圆性。这是新模型选择，不是原质量型算子的记号改写。截止移动 $O(\varepsilon^2)$ 仅为玩具启发；计数对象是固定 $\beta$ 的离散导模，不能直接代替固定频率的传播通道数。

## 其他2026检索命中：仅摘要层级，不支持开放性判断

- Habib Ammari, Jiayu Qiu, **Symmetry-protected Interface Modes Bifurcated from Double Dirac Cones**, arXiv:2603.19442 (2026-03-19)，[记录](https://arxiv.org/abs/2603.19442)。A/M；摘要的离散layer-potential框架、sharp interface及确切模数不自动成为当前质量型算子结果。
- Anne-Sophie Bonnet-Ben Dhia, Lucas Chesnel, Sonia Fliss, **Trapped Modes in Electromagnetic Waveguides**, *Integral Equations and Operator Theory* **98**, 27 (2026-07-02)，DOI [10.1007/s00020-026-02848-8](https://doi.org/10.1007/s00020-026-02848-8)。A/M；三维Maxwell PEC谐振腔接波导，部分机制并非标量理论。
- Chengxi Yang, Jialin Liu, Jianfei Li, Yuanhang Jiang, Zheyu Zhang, Jingfeng Yao, Zhongxiang Zhou, Chengxun Yuan, **Topological defect states via local symmetry breaking in modified Haldane models**, *Physical Review A*，2026-10-16接受，DOI [10.1103/h3ls-f3pb](https://doi.org/10.1103/h3ls-f3pb)。[接受记录](https://journals.aps.org/pra/accepted/10.1103/h3ls-f3pb)。A/M；非互易modified Haldane背景，不作为当前实正标量模型的创新证据。说明检索触及2026年10月，不代表已穷尽当月文献。

## E21–E25：深核后必须吸收的覆盖威胁

- **E21** Ning Han, Rui Zhao, Shuxing Yang, Mingzhu Li, Hongsheng Chen, Yihao Yang, **Causality Sum Rules in Conventional Scattering Matrices**, arXiv:2608.10427v1 (2026-08-11)。[元数据](https://arxiv.org/abs/2608.10427)，[公开PDF](https://arxiv.org/pdf/2608.10427)，DOI [10.48550/arXiv.2608.10427](https://doi.org/10.48550/arXiv.2608.10427)。主汇总及容量分工读正文pp.14–15、式(6)：无损相位延迟推广额外要求modal-count假设及无singular-inner部分，额外相位绕转须修正。公开21页PDF未含所引Supplementary Notes8–9，故只核到条件/结论声明，未核完整证明。不能以此断言资源上界已解决，也不能忽略这个近邻。HTML不存在，使用条目所列PDF，非绕过限制。
- **E22** Gaëtan Lévêque, Yan Pennec, Pascal Szriftgiser, Alberto Amo, Alejandro Martínez, **Scattering-matrix approach for a quantitative evaluation of the topological protection in valley photonic crystals**, *Physical Review A* **108**, 043505 (2023)。DOI [10.1103/PhysRevA.108.043505](https://doi.org/10.1103/PhysRevA.108.043505)，[公开作者稿v2](https://arxiv.org/html/2301.10565v2)。主汇总读§1及引言/模型，独审读§§1–3：二维TE FEM与角点/分流器的现象散射模型，已有反向转换、共振分裂、传输低谷及定量参数拟合。它不是弱破缺连续PDE的一致余项定理；“首次定量散射/角点反射”仍应淘汰。
- **E23** Tirth Shah, Florian Marquardt, Vittorio Peano, **Tunneling in the Brillouin zone: Theory of backscattering in valley Hall edge channels**, *Physical Review B* **104**, 235431 (2021)。DOI及[开放出版全文](https://doi.org/10.1103/PhysRevB.104.235431)。主汇总及独审读§§III、VI–VIII：tight-binding平滑墙的WKB谷间隧穿、反射随平滑度指数抑制及局部散射中心已有。不能仅将双谷或微观几何依赖作为新机制。
- **E24** Romain Pierrat, Philipp Ambichl, Sylvain Gigan, Alexander Haber, Rémi Carminati, Stefan Rotter, **Invariance property of wave scattering through disordered media**, *Proceedings of the National Academy of Sciences* **111**(50), 17765–17770 (2014)。DOI [10.1073/pnas.1417725111](https://doi.org/10.1073/pnas.1417725111)，[开放原文](https://pmc.ncbi.nlm.nih.gov/articles/PMC4273329/)。容量分工及独审读式(6–8)、DOS/Weyl段：已有二维Helmholtz的延迟迹—态密度联系。平均或高频Weyl估计不直接给固定低频窗、所有构型的统一界；这一区别也不能自动担保新颖性。
- **E25** Rytis Juršėnas, Julius Ruseckas, **Bound states of the spin-orbit coupled ultracold atom in a one-dimensional short-range potential**, *Journal of Mathematical Physics* **54**(5) (2013)。DOI [10.1063/1.4807419](https://doi.org/10.1063/1.4807419)，[公开作者稿](https://arxiv.org/html/1305.2316v1)。主汇总、阈值分工与独审核式(IV.4)、TheoremV.1、RemarkV.3；普通连续本征函数的点缺陷分支中，两极小在 $\Omega=\eta^2$ 合并，第二态在 $\Omega=\eta^2+\gamma^2/4$ 截止。**已有移动截止、平方尺度及内部态耦合机制**。不同点相互作用实现的额外不连续态不用于本项目类比。只把其有效矩阵换成Bloch系数不足支持主线；这是第二候选降级的重要证据。

## E26–E29：首步与替代方向的边界

- **E26** Giovanni Alessandrini, **Strong unique continuation for general elliptic equations in 2D**, *Journal of Mathematical Analysis and Applications* **386**, 669–676 (2012；作者稿2010)。DOI [10.1016/j.jmaa.2011.08.029](https://doi.org/10.1016/j.jmaa.2011.08.029)，[作者稿](https://arxiv.org/pdf/1004.4527)。阈值分工T：Theorem1.1、p.1，实有界一致椭圆主系数及所列低阶可积条件的二维UCP；主汇总核书目/摘要。用于检验Bloch波及其参数导数的缺陷梯度耦合是否独立，不是新的UCP定理。
- **E27** Amgad Abdrabou, Ya Yan Lu, **Indirect link between resonant and guided modes on uniform and periodic slabs**, *Physical Review A* **99**, 063818 (2019)。DOI [10.1103/PhysRevA.99.063818](https://doi.org/10.1103/PhysRevA.99.063818)，[作者稿](https://arxiv.org/abs/1901.08789)。主汇总A/M；阈值分工读原文模型与分支讨论。已有经improper modes与exceptional points间接连接导模和共振的结构，否定“跨连续谱立即成为复共振”的笼统选题。
- **E28** J. R. Anglin, A. Schulz, **Analytical solutions of the two-dimensional Dirac equation for a topological channel intersection**, *Physical Review B* **95**, 045430 (2017)。DOI [10.1103/PhysRevB.95.045430](https://doi.org/10.1103/PhysRevB.95.045430)，[作者全文](https://arxiv.org/html/1612.05126v1)。接口分工T/P：§§II–III、VI、VII.1，棋盘质量墙的全隙精确散射态、等分及无反射已有。不能因2026文献列其为后续兴趣就认为基础问题开放。
- **E29** Zhenhua Qiao, Jeil Jung, Chungwei Lin, Yafei Ren, Allan H. MacDonald, Qian Niu, **Current Partition at Topological Channel Intersections**, *Physical Review Letters* **112**, 206601 (2014)。DOI [10.1103/PhysRevLett.112.206601](https://doi.org/10.1103/PhysRevLett.112.206601)，[作者稿](https://arxiv.org/html/1302.6307)。接口分工读角度分流公式与适用性：近隙中心数值规律，非一般解析定理。仅变交角/质量的分流方案不足以成为比当前候选更强的独立方向。

**阶段筛选记录，最终替换见E30–E35。** 已额外比较多臂分流与随机纵向缺陷。前者基础模型已有精确解，连续晶体推广又依赖推荐一尚未建立的桥梁，暂不替换。后者物理价值明确，但旧随机表面/管状模型已有无绝对连续谱和边缘局域化定理；不能拿旧论文的“开放”句子证明2026仍开放。其完整比较以独立review及后续本文件记录为准。本轮没有因为三个名额而把它们称为新问题。

## E30–E33：临界链候选替换及2026年10月后续

- **E30** Habib Ammari, Silvio Barandun, Jiayu Qiu, Alexander Uhlmann, **Long-range interactions and Anderson localisation for one-dimensional high-contrast resonator chain**, arXiv:2607.04971v1 (2026-07-06)，[原文](https://arxiv.org/html/2607.04971v1)，[ETH报告2026-27](https://math.ethz.ch/sam/research/reports.leftnav.html?id=1182)。主汇总及两分工读§§2–3、Theorems3.2、3.8、§5。三维自由外部的一维同形 $C^{2,\eta}$ 共振器链，高对比极限；Bloch符号有非零逆对数主项，电容核有临界长程衰减，有限链强收敛/谱收敛已有。§5材料随机是 $v_n=1+\varepsilon\xi_n$ 的乘性形式；纯点/局域化只是有限链数值，不是定理。其引言与正文引用旧衰减门槛的表述不同，且“可和即能直接套强无序定理”需另核，不照抄成已验事实。
- **E31** Habib Ammari, Jiayu Qiu, **Absence of Absolutely Continuous Spectrum for One-Dimensional Capacitance Operators with Critical Long-Range Interactions**, arXiv:2610.09582v1 (2026-10-07)，SAM Report2026-35。[作者全文](https://arxiv.org/html/2610.09582v1)，[官方报告记录](https://math.ethz.ch/sam/research/reports.leftnav.html?id=1190)。主汇总读Assumptions2.1–2.3、Theorem2.4、Prop.3.6、Cor.4.9及§5，容量分工另读§3.5。核临界衰减及一二阶有限差分、实偶符号在正半区严格单调、乘性iid紧支撑有界密度等条件下，小非零无序几乎必然无绝对连续谱。一般几何给局部声学窗，反射对称单胞给全谱。§5明确未区分纯点和奇异连续。**因此7月的“无序局域化待证”必须被此更新；无绝对连续谱不再是候选目标。** 未独立审全篇证明。
- **E32** Peter D. Hislop, Rodrigo Matos, Constanza Rojas-Molina, **Poisson eigenvalue statistics and dynamical delocalization for fractional and long-range Anderson models**, arXiv:2609.33084v1 (2026-09-27)。[作者原文](https://arxiv.org/html/2609.33084v1)。主汇总核元数据/摘要；接口分工T/P：Theorems1.6、5.1及§4.1、Thm4.4。加性iid有界密度、强无序、跳跃 $|n-m|^{-d-2\beta}$；所核动力学结论还要求 $\beta>d/2$。高阶位置矩的时间指数平均可对每个平均时间均为无穷，低阶矩仍可有限，不能简写成“波以某速度扩散”。证明的分数矩参数需要核属某个 $\ell^s$，临界对数核不满足；不能令 $\beta\downarrow0$ 直接得到本候选。纯点与动力学局域化的区别本身已是旧/新近已知现象，不认领为创新。
- **E33** Margherita Disertori, Roberto Maturana Escobar, Constanza Rojas-Molina, **Decay of the Green’s Function of the Fractional Anderson Model and Connection to Long-Range SAW**, *Journal of Statistical Physics* **191**,33 (2024)。DOI [10.1007/s10955-024-03253-4](https://doi.org/10.1007/s10955-024-03253-4)，[作者稿v2](https://arxiv.org/html/2306.02860v2)。容量分工T：Theorems1–2；加性强无序、分数阶 $\alpha>0$，所需 $s>d/(d+2\alpha)$ 不能延伸到临界 $\alpha=0$。主汇总核出版元数据/摘要。这是具体方法边界，不以“未搜到”代替覆盖审查。

- **E34** Michael Aizenman, Stanislav Molchanov, **Localization at large disorder and at extreme energies: An elementary derivation**, *Communications in Mathematical Physics* **157**,245–278 (1993)。DOI及[原刊入口](https://doi.org/10.1007/BF02099760)。容量分工读出版商摘要所列某个 $s<1$ 的跳跃分数次可和条件，未重新审全篇证明；不能只因临界核在 $\ell^1$ 就声称直接满足该条件。
- **E35** Xianzhe Li, Zhenfu Wang, Jiangong You, Qi Zhou, **Transfer Operators, Canonical Center Dynamics, and Spectral Applications for Long-Range Operators**, arXiv:2606.29154v1 (2026)。[作者全文](https://arxiv.org/html/2606.29154v1)。容量分工读模型与Theorem1.1，独审核摘要/版本；解析跳跃符号及相应小势/准周期条件排除当前对数奇点，不能凭“long-range”题名认作直接覆盖。

**替换决策。** 临界链入前三，取代创新风险上升的双谷截止。理由不是更换了一个核，而是E31明确未控制奇异谱、E32/E33的分数矩门在临界核失效，且乘性弱无序与加性强无序不同。目标仍极难；首先限定内部能窗，接受新三维高对比模型，不宣称当前二维波导证书已提供起点定理。首步无指数尾推导仅校正目标，不能作为论文主贡献。

## 访问与覆盖限制

公开作者稿、出版商全文/元数据及机构稿为主要证据；本轮不下载全文到本地，不新增ref文件。E5出版社403、E17直接open失败、部分出版商订阅限制、分工中的429均未重试绕过。上一轮FJL2021 HAL Access Denied未再访问。检索命中与全文可读是两回事；未读证明、只见摘要及沿用上轮核读已分别标明。核心检索族包括 sharp bend/valley Hall scattering、projected band-edge merger/weak defect counting、delay-bandwidth/spectral shift、embedded thresholds、topological intersections、random surface/line disorder，配合具体作者题名及2025/2026限定。它是定向筛查，不是数据库穷尽综述，也未证明任何候选“文献中无人研究”。

E31的ETH Research Collection条目读取返回403，官方 `www.sam.math.ethz.ch/.../2026-35.pdf` 返回工具不可访问，均未取得全文，受阻路径未重试。分工在收到停止通知前已有一次该PDF读取在途，同样失败；之后停止。普通文献检索独立发现公开arXiv:2610.09582，正常读取其作者HTML成功，未改变权限、网络设置或访问受限资源。故E31最终证据级别为上述T，ETH地址仍记录失败。检索深度现已到**2026-10-07具体定理设定**；不是仅以“最新”笼统形容。


## E36：把随机谱型首关写成具体条件

- Barry Simon, Tom Wolff, **Singular continuous spectrum under rank one perturbations and localization for random hamiltonians**, *Communications on Pure and Applied Mathematics* **39**(1),75–90 (1986)。DOI [10.1002/cpa.3160390105](https://doi.org/10.1002/cpa.3160390105)。本轮核出版商摘要和作者书目，A/M，未读全证明；来源明确为自伴算子的循环秩一扰动谱测度判据。
- Michael Aizenman, Simone Warzel, **Boosted Simon-Wolff Spectral Criterion and Resonant Delocalization**, *Communications on Pure and Applied Mathematics* **69**,2195–2218 (2016)。DOI [10.1002/cpa.21625](https://doi.org/10.1002/cpa.21625)，[作者稿v2](https://arxiv.org/html/1412.3681v2)（2015-12-08；初稿2014）。主汇总实际读§§2.1–2.4，Propositions2.1–2.2、Theorem2.4及Green平方积分定义；独审核v1，编号不同。T/P，不是全证明审计。加性随机、条件单点连续/绝对连续分布的条件要保留，不能直接套乘性链。它让首关成为真实预解式列的实轴平方可和问题，而非方法名清单；10月无AC没有给该量的有限性。适配仍未完成。

检索Simon–Wolff原稿时，Caltech机构记录URL `https://authors.library.caltech.edu/records/p2tz5-xg339` 返回工具不可访问，未作重试、未用其内容；书目仅依上面的出版商和作者目录。没有本地下载。
