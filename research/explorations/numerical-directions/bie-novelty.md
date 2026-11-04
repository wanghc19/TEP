# BIE 保证区间的文献核查

BIE 指 boundary integral equation（边界积分方程）。

## 结论

在本次检索范围内，未找到完成拟议组合的工作：固定 $\beta$、左右不同周期半引线、真实曲界面上的分片精确 BIE 场、连续跳跃残差的可靠计算，再由公共本质谱间隙得到约 $10^{-9}$ 宽的点特征值区间，且不输入局部隔离或计数。**可以继续发展这一完整算法与实现；不能把它定位成新的无隔离谱包含原理。** 目前约 $1.2$–$1.5\times10^{-9}$ 的宽度仍来自浮点估计，保证宽度尚待实现，见 [[bie-eval-pilot]]。

最接近的工作分别是：

- Brown–Hoang–Plum–Wood（2009）已把 Weinstein 型 $H^{-1}$ 残差包围用于光子晶体线缺陷谱，基本机制最接近；其解析试探函数和宽区间例子不同于本项目的高精度固定纤维 BIE 计算。
- Betcke（2007）的区域分解特解法已用分片精确 Helmholtz 解的值跳跃和梯度跳跃控制特征值误差；“体内精确、只剩界面残差”本身已有直接先例。
- Dahne–Salvy（2020）已把边界残差包含定理、Taylor 模型和区间算术结合，给出至多 100 位的严格 Laplacian 特征值结果；新意不能只放在高精度或可靠评估微小边界残差。
- Barnett–Greengard（2010）、Agocs–Barnett（2024）已给出周期介质能带或周期陷获波的高精度 BIE；Xin（2011）还比较过光子晶体能带的 BEM 与 FEM。它们未给出这里所需的连续跳跃到无限域点谱区间的完整可计算保证。

以下“未找到”只指已说明的检索范围，不是优先权的绝对断言。

## 检索覆盖

沿用既有 phase2b-novelty、isolation-survey、l1-novelty 的已核验来源，并围绕五组词追查：photonic/line-defect waveguide + guaranteed/enclosure/Weinstein；particular solutions + boundary/interface jumps + eigenvalue inclusion；MFS/transmission + residual error；rigorous QP Green/Ewald/QBX/near-singular quadrature；periodic BIE/resonance + a posteriori/verified + FEM comparison。检索入口为 arXiv、SIAM、Springer、Oxford/IMA、Elsevier、IOP、KIT、Manchester、Oxford、Jülich 和作者主页，沿 Brown/Plum、MPS、Barnett、Steinbach/Unger 的参考文献向前后追查。只从原文已读位置作定理判断；元数据页和摘要另行标明。下文“PDF 页”指所链接公开版本的页码，含封面时会注明，不能直接当作期刊页码。

## 分量表 N1–N5

| 分量 | 判定 | 已读来源与位置 | 与拟议工作的差别 |
|---|---|---|---|
| N1：无隔离的周期导模 gap 谱包围 | partly covered | Brown 等（2009）§3，式(5)–(8)，印刷 pp.25–26；§4，pp.27–29。Brown 等（2015）Thm.1，公开 PDF p.9；2017 Thm.2.1，PDF p.3；2020 Thm.3，PDF p.16。详见下文已入库来源。 | Weinstein 谱包含与缺陷 gap 谱存在性已有。2009 是全空间散度型模型与解析缺陷内试探函数；后续为同一周期背景上的正弱缺陷存在性/计数。尚未找到左右不同半引线的高精度 BIE 后验区间。 |
| N2：精确 PDE 试探函数的边界/界面残差包含 | partly covered | Fox–Henrici–Moler（1967）pp.89–90 的定理；Betcke–Trefethen（2005）Thm.8.1，pp.484–485；Betcke（2007）Lemma 2.1、式(4.5)，公开 PDF pp.4、11；Barnett–Hassell–Tacy（2018）Thm.1.8，PDF p.7；Dahne–Salvy（2020）Thm.1，PDF p.4。 | 边界残差包含原理已经覆盖，且包括分片精确解的双跳跃；主要结果在有界域。Kleefeld–Pieronek（2018）还处理内传输特征值，但它不是本项目的自伴介电传输算子。带本质谱的波导侧由 N1 补上部分原理，尚未找到此模型的完整桥接。 |
| N3：曲边 BIE/MFS 残差及 QP 核的可靠计算 | partly covered | Dahne–Salvy（2020）§§2.1–2.4，PDF pp.6–8；Epstein–Greengard–Klöckner（2013）Thms.2.4–2.5，PDF pp.10–11，§4；Arens 等（2013）Thms.4.2–4.4、7.1–7.2，公开 PDF pp.14–17、29–31；Wala–Klöckner（2018）Thm.7，arXiv v4 pp.20–21。 | Taylor/区间残差评估、曲边层势局部展开误差、QP Ewald 及其导数尾项、带误差分析的加速 QBX 均有先例。尚未找到这些工具组成非圆材料曲线、人工壁和无限 Bloch 尾上的连续双跳跃范数上界。 |
| N4：周期 BIE 特征值/共振及可靠误差、BIE–FEM 比较 | partly covered | Barnett–Greengard（2010）Thm.4，PDF p.7；Agocs–Barnett（2024）Thm.4，印刷 p.10，§3；Pérez-Arancibia–Yin（2026）Thm.5.3、Cor.5.4、§5末，PDF pp.13–14；Xin（2011）§5.4，印刷 pp.87–91；Holzmann–Unger（2020；2019 公开稿）Prop.4.3(ii)、Thm.4.5，PDF pp.22、25；Colbrook–Townsend（2025；2023 公开稿）Thms.2.2–2.3、§4.6，PDF pp.7–8、19–21。 | 精确 BIE 等价、非线性谱问题、收敛分析、BEM–FEM 能带比较及含本质谱算子的连续残差验证均已有。尚未找到本周期双引线模型的单侧区间实现。一般 NEP 的伪谱包含不能直接当作自伴纤维算子的实轴谱距离。 |
| N5：全部组合 | not found | N1–N4 的原文和引用追查。 | 未找到在所述异质周期导波模型中，完成全部曲边/尾部/求积误差控制并得到约 $10^{-9}$ 宽、无局部隔离输入的点特征值保证区间的文献。这个有限范围的否定结论不排除未检出的论文。 |

### 已入库来源与最接近先例的具体边界

**Brown 与 Plum 组：无隔离的谱包含已经存在，紧的高阶下界另有谱分离输入。** [Brown–Hoang–Plum–Wood 2009](https://doi.org/10.1007/978-3-7643-8773-0_3) 的 §3 式(5)，p.25，由自伴移位逆算子的 Weinstein 定理直接得到“至少一个谱点”的区间，没有相邻模态计数输入。式(6)，pp.25–26，给出 $H(\operatorname{div})$ 通量型残差控制。§2 的算子是全空间 $-\operatorname{div}(\epsilon^{-1}\nabla)$，缺陷条内介电常数均匀；它并未计算本项目的固定 $\beta$ 加权 Laplacian 点特征值。§3–4 的试探函数是缺陷内的光滑分离函数 $\phi_l(x')\psi_n(x_1)e^{ikx_1}$，再取 $n\to\infty$；示例为三维导波，使用横截面方形上的显式多项式。p.27 明列区间长度并说明与此前 $2\sqrt{1295}/(\epsilon l^2)$ 的长度基本相同。这是解析存在区间，未报告一个数值导模的十位精度包围，不能把此例精度说成该定理的上限。此处复核了用户指定的既有 ref/ref_data/books/Bandle2009.pdf，印刷 pp.23–30 全章。年份按现库及作者目录记为 2009；出版社将上线和版权年份记为 2008，题名、作者、页码和 DOI 对应同一章。[Cardiff 公开记录](https://orca.cardiff.ac.uk/id/eprint/46308/)只有摘要和元数据，未找到机构公开的独立章节全文。

[Brown 等 2015](https://arxiv.org/pdf/1204.0998) Thm.1，PDF p.9，在固定准动量的条带算子上证明正的足够小介电扰动产生 gap 特征值；[2017](https://arxiv.org/pdf/1511.03723) Thm.2.1，PDF p.3，处理不连续系数的 TE 散度型情形；[2020](https://arxiv.org/pdf/1901.05102) Thm.3，PDF p.16，在多带边、二次非退化等条件下给出弱缺陷模态数。这些是同一周期远场的解析定理，不是高对比异质双引线的数值后验窄区间。它们不支持“所有 Plum 组导模结果都需要隔离”的说法。

[Hoang–Plum–Wieners 2009](https://publikationen.bibliothek.kit.edu/1000007941/246229) 的发表版 Thm.2、条件(5)，pp.1039–1040，为 Goerisch 下界要求第 $N+1$ 个特征值的分离参数；§4，pp.1042–1044，用同伦取得该输入。其 Thm.7，p.1046，证明的是周期体能带间隙。具体的非周期无限声学波导先例见 Behnke–Mertins–Plum–Wieners，*Eigenvalue Inclusions via Domain Decomposition*, Proc. R. Soc. Lond. A **456** (2000), 2717–2730，[DOI](https://doi.org/10.1098/rspa.2000.0635)：Thm.2.1、§3、§4(a) 使用有限元、混合通量及谱分离/同伦。已入库 Nakao–Plum–Watanabe（2019）Example 10.38、Table 10.2，pp.404–406，重述该波导路线，二次有限元和 RT1 通量在对称子空间上得到 $[1.7727,1.7765]$，宽 $3.8\times10^{-3}$，并用同伦控制计数。这个例子可说明实际包围规模，不能推出此类方法只能达到该宽度。

**边界残差先例比“BIE 数值找根”更接近本项目。** Betcke（候选 C4）已在有界多子域上组合特解与界面双跳跃；其 $C$ 只说明依赖子域分解，未为本波导给出可执行常数。Kleefeld–Pieronek（C8）Lemma 5、式(21)，公开 PDF p.25，已有值和法向跳跃到内传输特征值偏差的公式；Cor.6、式(23)，p.26，须有不消失的精确/极限场体积分配对。它在同一有界散射体内比较两个 Helmholtz 场，算子非自伴，与物理介电界面内外的自伴点谱问题不同。Remark 4，p.26，明确说一般并不知道所需精确特征函数性质，因此该估计通常难以直接执行。

[已入库 Barnett–Hassell–Tacy 2018](https://arxiv.org/pdf/1512.04165) 的 Thm.1.8，PDF p.7，给出光滑有界域 Neumann 谱距离与加权边界 tension 的包含关系。§8 的数值达约 14 位；**Remark 8.2，PDF p.37，明确表示该定理的常数 $C$ 未给出显式值，数值表采用由斜率估出的 $C_{\rm est}=1.6$**。这与已执行的全单侧保证计算不同。相反，Dahne–Salvy（C5）在有界平面/球面域上完成了微小边界残差的区间与 Taylor 模型计算。Dahne–Gómez-Serrano–Hou（C6）Thm.5.1，PDF p.9，给出无编号输入的谱包含；为了辨识第二特征函数和节点线，另外用 Thm.3.1、Thm.5.2 和 Lemma 5.5 控制序号与谱簇。这区分了“区间内存在谱点”和“它就是指定编号的简单模态”。

**周期 BIE、BEM–FEM 比较和无限维残差验证也都有先例。** [Barnett–Greengard 2010](https://arxiv.org/pdf/1001.5464) Thm.4，PDF p.7，在相应非共振条件下证明经典 QP 层势核与 Bloch 模态等价；其高精度能带离散没有构成本文所需的单侧特征值包围。[Agocs–Barnett 2024](https://arxiv.org/abs/2310.12486) Thm.4，印刷 p.10，将周期阶梯声学陷获波与 Fredholm BIE 的核等价，§3 数值求色散关系；这是周期刚性边界声学问题。[Pérez-Arancibia–Yin 2026](https://arxiv.org/pdf/2610.28494) Thm.5.3、Cor.5.4，PDF pp.13–14，给出胞元 BIE 核的物理解/伪解判据；§5 末明确把 §6.2.2 的有限外场采样诊断称为连续判据的数值替代。以上均按既有入库文件或公开稿复核了相关章节。

Xin（C13）§5.4，印刷 pp.87–91，Fig.5.7 与 Tables 5.3–5.4，已比较三维准周期介电胞元的 Galerkin BEM 与 FEM 能带收敛；比较量是逐级数值特征值。Holzmann–Unger（C14）的全空间 BIE 含本质谱，Thm.4.5 的误差为充分细离散后成立的渐近式，带未数值确定的常数和局部谱邻域假设。Colbrook–Townsend（C16）Thms.2.2–2.3，公开 v1 pp.7–8，给出无限维 NEP 的伪谱内包含与单侧收敛，§4.6，pp.19–21，计算具有本质谱的一维分层波导。因此也不能声称“首次对含本质谱的波导作残差验证”。一般 NEP 的伪谱残差与本项目自伴 $A(\beta)$ 的实轴谱距离区间须分别说明。

Bruno–Santana–Trefethen（C15）公开 v2 §5 的误差估计来自割线迭代历史；§6.2 与 Table 1 以数值收敛判断数字精度。它是有效的共振搜索先例，尚未提供本项目需要的连续算子到有限矩阵误差的单侧包围。Matsushima–Isakari（C12）Thm.2.8，PDF p.8，已有含 Wood 异常的频率一致 Nyström 收敛定理，但假设该频率集上的齐次散射问题只有零解；§5 式(5.11)，p.24，常数及充分大阈值由存在论给出。散射收敛定理并不直接给导模频率的数值保证区间。

## 论文定位与必要比较

可写的贡献，须以实现完成为前提：**为左右周期远场不同的二维介电线缺陷固定纤维算子，给出并执行一种可计算的边界/界面残差谱包含流程；对真实曲线、QP 核、无限 Bloch 尾和场范数实行单侧误差控制，在已确认的本质谱间隙内得到窄的点特征值区间，且不输入局部谱隔离或模态数。** F14 的作用是把这些可计算量接到自伴谱距离，主要新工作在模型适用性、显式常数及连续残差的可靠评估，而不是谱定理本身。

单纯把旧包含定理配上另一种离散方法，可能被视为算例应用。应具体展示已有方法未执行的两步：怎样在本模型上得到不依赖局部谱间距的可计算迹常数，怎样以有限成本控制曲界面和无限尾部的连续微小跳跃；若这两步只引用存在常数，拟议的贡献就没有闭合。

不宜写成首个无隔离导模包围、首个边界残差包含、首个传输 MFS 特征值误差估计、首个周期 BIE 能带计算，或首个 BIE–FEM 比较。F14 对 $\varepsilon$ 是线性的；BIE 有望得到窄区间，是因为分片精确 PDE 场能把残差压得很小，而非得到一种普遍比有限元更高阶的谱包含定理。曲线求积和截断余项的定理已有，论文仍需把其常数算到足以控制本例的微小跳跃。

对审稿人最有说服力的是以下同口径比较：

1. **存在性对存在性。** BIE 区间只保证至少一个谱点；FEM 加 (H) 还保证窗口内唯一性与简单性。主表先比较存在性区间，再单列唯一性额外成本。Brown 2009 的无隔离结果须作为理论前驱。
2. **可靠宽度对可靠宽度。** 在同一 $\mu=k^2$、同一 $\beta$、同一几何和同一舍入处理下，列出 $\overline C,\overline\varepsilon,\underline U,\overline\varepsilon_{\rm vol}$、各误差预算和总耗时。当前 pilot 的节点/后端一致性只支持继续做连续残差上界；浮点 $10^{-9}$ 尚不是保证宽度。若舍入仍只作误差估计，应称“截断可靠、附舍入误差估计”，不能称全部误差均已保证的区间。
3. **把共享和可复用成本分开。** 现稿 FEM 的 (H) 流程约 54–55 分钟，是每组引线、$\beta$、窗口的可复用成本，且取得比存在性更强的结论。BIE 仍需要同一纤维算子的本质谱间隙；若用既有带隙结果，应单列共享成本。比较一次单模态与多候选/多参数累计成本，才能判断省去计数是否实际有利。
4. **把优势做成结果。** 首先完成一个约 $10^{-9}$、至少不超过 $5\times10^{-9}$ 宽的连续问题区间，给出残差预算随求积/展开阶数的变化。若再在接近别的导模时保持宽度，能直接展示不依赖局部隔离的价值。当前 FEM 无 (H) 的约 $10^{-4}$ 宽度是现有场与一阶估计的结果，不是 FEM 理论精度下限；应保留同等投入下改进场/通量的比较空间。

项目比较数字取自 draft/fem-goerisch/paper.tex 的数值实验与成本段（lines 930–1010）：无 (H) 一阶区间约 $1.003\times10^{-4}$，Goerisch 截断可靠宽度约 $4.462\times10^{-9}$。其中的可靠性口径须沿用原文。

“带隙证书”必须足以推出**同一 $A(\beta)$ 的本质谱间隙**。对双远场，可用已经证明且适用的本质谱与两远场谱的对应结果，再加两引线带隙；这与局部模态隔离是不同输入。F14 自己只给谱相交，见项目 s-framework.md F2/F14，lines 249–307。论文应把这一步写清楚。

## 新候选参考文献

以下 17 项未见于当前 ref/README.md 与 ref/reference.bib，供用户决定是否入库。元数据用出版社、作者或机构记录核对；表中明确区分正式发表信息与实际阅读的公开版本。“否”表示只精读了所列相关章节，不能理解为通读全部证明与数值例子。

| 编号与核验后的元数据 | 合法公开全文；是否全文通读 | 已读定位与本任务关系 |
|---|---|---|
| C1. L. Fox, P. Henrici, C. Moler. *Approximations and Bounds for Eigenvalues of Elliptic Operators*. SIAM J. Numer. Anal. **4**(1) (1967), 89–102. [DOI 10.1137/0704008](https://doi.org/10.1137/0704008)。 | [Moler 作者公开本](https://blogs.mathworks.com/images/cleve/Fox_Henrici_Moler.pdf)；否，读 §§1–3。 | pp.89–90 的无编号定理及 §2，pp.91–93：有界域椭圆 Dirichlet 问题，精确 PDE 场的边界缺陷给谱包含；§3 为特解计算。不是传输无限域。 |
| C2. C. B. Moler, L. E. Payne. *Bounds for Eigenvalues and Eigenvectors of Symmetric Operators*. SIAM J. Numer. Anal. **5**(1) (1968), 64–70. [DOI 10.1137/0705004](https://doi.org/10.1137/0705004)。 | 未找到合法公开原全文；只核对出版社元数据，未读原文。 | 其边界误差定理由已读 C3 Thm.8.1 与 C5 Thm.1 明确转述核验；不声称核对了原文定理号或原文全部适用范围。 |
| C3. T. Betcke, L. N. Trefethen. *Reviving the Method of Particular Solutions*. SIAM Rev. **47**(3) (2005), 469–491. [DOI 10.1137/S0036144503437336](https://doi.org/10.1137/S0036144503437336)。 | [Oxford 作者本](https://people.maths.ox.ac.uk/~trefethen/publication/PDF/2005_112.pdf)；否，读算法及 §8。 | Thm.8.1，pp.484–485，区分无隔离的特征值包含与依赖相邻谱间距的特征函数误差；Thm.8.2，pp.486–487，控制试探空间夹角。高精度特解法的重要先例。 |
| C4. T. Betcke. *A GSVD formulation of a domain decomposition method for planar eigenvalue problems*. IMA J. Numer. Anal. **27**(3) (2007), 451–478. [出版社元数据](https://academic.oup.com/imajna/article-abstract/27/3/451/744791)，[DOI 10.1093/imanum/drl030](https://doi.org/10.1093/imanum/drl030)。 | [Manchester 作者稿](https://eprints.maths.manchester.ac.uk/595/1/betcke_revised.pdf)；否，读 §§2–4、§5 的收敛结论。其封面为 2006，页眉的 2005 和占位 DOI 不是正式发表信息。 | Lemma 2.1，PDF p.4（稿件 p.3），$\lvert u_K-u_L\rvert^2+\lvert\nabla u_K-\nabla u_L\rvert^2$；式(4.5)，PDF p.11（稿件 p.10），加入外边界后的谱误差。引理归于 Descloux–Tolley（1983），此原始来源未另读。 |
| C5. J. Dahne, B. Salvy. *Computation of Tight Enclosures for Laplacian Eigenvalues*. SIAM J. Sci. Comput. **42**(5) (2020), A3210–A3232. [出版社元数据/DOI](https://doi.org/10.1137/20M1326520)。 | [arXiv:2003.08095v2](https://arxiv.org/pdf/2003.08095v2)；否，读 Thm.1、§2、§§3.5、3.9。 | Thm.1，PDF p.4，无隔离谱包含；§§2.1–2.4，pp.6–8，组合残差的 Taylor 模型、范数下界、编号与 Arb；§3.9，pp.20–21，100 位的球面三角形结果。最接近连续小残差的可靠计算。 |
| C6. J. Dahne, J. Gómez-Serrano, K. Hou. *A counterexample to Payne’s nodal line conjecture with few holes*. Commun. Nonlinear Sci. Numer. Simul. **103** (2021), 105957. [DOI 10.1016/j.cnsns.2021.105957](https://doi.org/10.1016/j.cnsns.2021.105957)。 | [Uppsala 合法开放发表本](https://uu.diva-portal.org/smash/get/diva2%3A1609853/FULLTEXT01)；定位使用 [arXiv:2103.02276v1](https://arxiv.org/pdf/2103.02276v1)。否，读 §§3–5 相关定理和实现。 | Thm.3.1，PDF p.5，有限元粗下界；Thm.5.1、Table 2，p.9，MPS 谱包含；Thm.5.2，p.10，特征函数误差另需间距。为辨识节点线而加入计数，不表示谱包含自身要计数。 |
| C7. A. H. Barnett, A. Hassell. *Boundary Quasi-Orthogonality and Sharp Inclusion Bounds for Large Dirichlet Eigenvalues*. SIAM J. Numer. Anal. **49**(3) (2011), 1046–1063. [出版社元数据/DOI](https://doi.org/10.1137/100796637)。 | [arXiv:1006.3592](https://arxiv.org/pdf/1006.3592)；否，读 Thm.1.1 及其相关说明。 | Thm.1.1，PDF pp.3–4，边界 $L^2$ tension 到有界 Dirichlet 谱距离；是高频边界残差包含先例，模型不含材料界面和周期无限端。 |
| C8. A. Kleefeld, L. Pieronek. *The method of fundamental solutions for computing acoustic interior transmission eigenvalues*. Inverse Problems **34**(3) (2018), 035007. [Jülich 元数据](https://juser.fz-juelich.de/record/843608/)，[DOI 10.1088/1361-6420/aaa72d](https://doi.org/10.1088/1361-6420/aaa72d)。 | [Jülich 作者接受稿](https://juser.fz-juelich.de/record/843608/files/MFSInverseProblemsAKLP.pdf?version=1)；否，读问题定义与 §4 的主要结果。 | Lemma 5、式(21)，PDF p.25；Cor.6、式(22)–(23)、Remark 4，p.26。传输 MFS 双跳跃已有误差公式，执行常数依赖精确场配对；内传输谱与本项目自伴导模谱不同。 |
| C9. T. Arens, K. Sandfort, S. Schmitt, A. Lechleiter. *Analysing Ewald’s method for the evaluation of Green’s functions for periodic media*. IMA J. Appl. Math. **78**(3) (2013), 405–431. [出版社目录](https://academic.oup.com/imamat/issue/78/3)，[DOI 10.1093/imamat/hxr057](https://doi.org/10.1093/imamat/hxr057)。 | [KIT 作者稿](https://publikationen.bibliothek.kit.edu/1000019136/1396509)；否，读二维结果、误差控制与导数部分。 | Thms.4.2–4.4，PDF pp.14–17；Thms.7.1–7.2，pp.29–31，QP Ewald 截断及导数的显式误差。§6 讨论控制参数与消去影响；这不是现用 FMM 请求精度的自动保证。 |
| C10. C. L. Epstein, L. Greengard, A. Klöckner. *On the Convergence of Local Expansions of Layer Potentials*. SIAM J. Numer. Anal. **51**(5) (2013), 2660–2679. [DOI 10.1137/120902859](https://doi.org/10.1137/120902859)。 | [arXiv:1212.3868v2](https://arxiv.org/pdf/1212.3868v2)；否，读二维 Helmholtz 部分与 §4。 | Thms.2.4–2.5，PDF pp.10–11，光滑曲线层势在边界处的单侧局部展开误差；§4，pp.17–19，展开系数求积误差。仍需把依赖密度正则性和几何的常数实际算出。 |
| C11. M. Wala, A. Klöckner. *A fast algorithm with error bounds for Quadrature by Expansion*. J. Comput. Phys. **374** (2018), 135–162. [作者代码与书目信息](https://github.com/mattwala/gigaqbx-2d-paper-code)，[DOI 10.1016/j.jcp.2018.05.006](https://doi.org/10.1016/j.jcp.2018.05.006)。 | [arXiv:1801.04070v4](https://arxiv.org/pdf/1801.04070v4)；否，读导论与加速误差定理。定位为该更新稿，不混用期刊页码。 | Thm.7，PDF pp.20–21，为二维 Laplace GIGAQBX 给出加速误差不等式；不是 Helmholtz FMM2D 的同一个定理，不能将其直接当作本项目核/法向导数的保证。 |
| C12. K. Matsushima, H. Isakari. *A frequency-stable Nyström method for two-dimensional diffraction by periodic gratings at and near Wood anomalies*. 2026 预印本，arXiv:2608.08172v1。 | [arXiv 原文](https://arxiv.org/pdf/2608.08172v1)；否，读 §2 定理与 §5 证明相关段。作者、题名和版本由预印本首面核对。 | Thm.2.6，PDF p.6；Thm.2.8，p.8；式(5.11)，p.24。频率一致的离散散射误差分析；唯一性假设与非显式常数阻止直接拿来认证导模频率。 |
| C13. J. Xin. *Boundary Element Approximation for Maxwell’s Eigenvalue Problem*. KIT 博士论文，2011. [机构元数据/DOI 10.5445/IR/1000024374](https://publikationen.bibliothek.kit.edu/1000024374)。 | [KIT 开放全文](https://publikationen.bibliothek.kit.edu/1000024374/1863693)；否，读 §§3.2、5.3–5.4 相关部分。 | Thm.9，印刷 p.57，为局部孤立谱的渐近误差；§5.4，pp.87–91，三维周期介电问题的 BEM–FEM 能带比较。已覆盖“做过比较”，未覆盖“保证区间的比较”。 |
| C14. M. Holzmann, G. Unger. *Boundary integral formulations of eigenvalue problems for elliptic differential operators with singular interactions and their numerical approximation by boundary element methods*. Operators and Matrices **14**(3) (2020), 555–599. [出版社目录](https://oam.ele-math.com/volume/14)，[DOI 10.7153/oam-2020-14-39](https://doi.org/10.7153/oam-2020-14-39)。 | [arXiv:1907.04282v1](https://arxiv.org/pdf/1907.04282v1)；否，读 §§1–2、§4 的谱等价和离散收敛结果。 | Prop.4.3(ii)，PDF p.22，本质谱相同；Thm.4.5，p.25，BEM 特征值渐近误差。自伴全空间、紧界面奇异作用，不是无限周期介电界面。 |
| C15. O. P. Bruno, M. Santana, L. N. Trefethen. *Evaluation of Resonances: Adaptivity and AAA Rational Approximation of Randomly Scalarized Boundary Integral Resolvents*. SIAM J. Sci. Comput. **48**(3) (2026), A1260–A1283. [出版社元数据/DOI 10.1137/24M1690680](https://doi.org/10.1137/24M1690680)。 | [arXiv:2405.19582v2 合法全文](https://arxiv.org/html/2405.19582v2)；否，读 §§1–5、§6.2 的误差判定。正式年份为 2026，不是预印本年份 2024。 | §5 Algorithms 1–2 及割线终止段；§6.2、Table 1。BIE 共振搜索的迭代误差估计，与连续谱包含区间不同；HTML 无固定页码，以节和算法定位。 |
| C16. M. J. Colbrook, A. Townsend. *Avoiding Discretization Issues for Nonlinear Eigenvalue Problems*. SIAM J. Matrix Anal. Appl. **46**(1) (2025), 648–675. [出版社元数据/DOI 10.1137/23M1569927](https://doi.org/10.1137/23M1569927)。 | [arXiv:2305.01691v1](https://arxiv.org/pdf/2305.01691v1)；否，读 §§1–2、§4.6 及相关图。 | Thms.2.2–2.3、式(2.12)，PDF pp.7–8，连续 NEP 伪谱包含；§4.6，pp.19–21，一维分层波导与本质谱。不是本例 BIE 跳跃范数或双周期半引线的区间实现。 |
| C17. J. Tausch. *Computing Floquet–Bloch modes in biperiodic slabs with boundary elements*. J. Comput. Appl. Math. **254** (2013), 192–203. [出版社元数据和摘要](https://www.sciencedirect.com/science/article/pii/S0377042713001155)，[DOI 10.1016/j.cam.2013.03.008](https://doi.org/10.1016/j.cam.2013.03.008)。 | 本次仅读出版社摘要；其页面标有 Open archive，但全文入口未能读取，未取得可核验的公开全文。 | 摘要报告三维双周期分层板的 BEM、非线性 Hermitian 特征问题与同伦求解。这是 N4 的直接候选；本文不据摘要判定它是否具有有限单侧误差，也不虚列定理位置。 |

## 未决问题

1. 保证宽度仍是拟议结果。下一阶段最有用的输入是 C5 的“先组合抵消残差，再作 Taylor/区间控制”，以及 C9 的 QP 核及导数余项。两者能否在非圆曲线与本例参数下给出足够小且可承受的误差，文献核查本身不能回答。
2. Moler–Payne 原始全文未取得；其常用包含定理已从 C3/C5 的明确转述核验。Descloux–Tolley 的原始 Lemma 4.10 仅沿 C4 确认引用，没有另作原文核验。它们不影响已有直接先例的判断，但正式引用原定理号前应取得原文。
3. 未发现 F14 当前代数形式在上述文献中逐字出现，不能据此主张新定理。应比较的是其具体试探空间、跳跃范数和显式常数；Weinstein/预解式谱距离机制已有。
4. 本次是定向检索，不是穷尽性数据库系统综述。若论文拟用“首次”，提交前应专门补查检索期内的新稿与 C4/C8/C16 的后续引用；当前更稳妥的陈述是清楚列出该模型上完成的算法和数字。
5. C17 是尚未完成全文核查的周期 BEM 候选。它的三维分层板模型区别已由摘要确认，但其误差定理的性质仍未核验；不应以本报告排除它对 N4 的更多覆盖。
