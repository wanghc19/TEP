缩写：BIE 为边界积分方程，FEM 为有限元法，DtN 为 Dirichlet 到 Neumann 映射，RtR 为 Robin 到 Robin 映射，WGF 为加窗格林函数法，QZ 为广义 Schur 分解。

# Wood 频率处的散射、能带与线缺陷导模

**对求解器论文的判断。** 正频率处解析的闭胞 BIE 已有先例。Pérez-Arancibia–Yin 对固定 Bloch 相位明确写出全纯的体晶体能带算子；Fliss–Klindworth–Schmidt 已用 FEM 和 Robin 迹求解同类无限线缺陷导模。还值得检验的贡献是，在两侧周期引线的共同谱隙内，用纯边界离散构造经过背景掠射阶的引线衰减空间，接上缺陷胞，并在阈值上及两侧找到同一条物理导模分支。本次所读全文中未找到同时完成这些步骤并报告该项穿越试验的工作。[体晶体全纯 BIE，§4.4](https://arxiv.org/pdf/2610.28494)；[线缺陷 RtR，定理 3.1、4.1](https://doi.org/10.1007/s10543-014-0521-1)

这里固定沿导模方向的准动量 $\beta$ 和周期 $d$，扫频率 $k$。**(a)** 指开放光栅受迫散射在 $\gamma_m=0$ 仍能计算正确的辐射解，误差可通过加密检验。**(b)** 指闭合本征问题的表示算子在该正频率的一个复邻域内对 $k$ 全纯，允许它在物理本征频率有核。两种检验不同。双周期空晶格的共振还固定了第二个 Bloch 相位；其准周期格林函数有谱极点。单周期开放背景的阈值只固定切向相位，来自法向波数的平方根。两者都是检验自由空间胞元表示的例子，奇性的类型和远场条件不同。[Barnett–Greengard 2010，定义 3、§3.3](https://arxiv.org/pdf/1001.5464)；[Barnett–Greengard 2011，§2、§5](https://doi.org/10.1007/s10543-010-0297-x)

## 1. Petropoulos–Turc 的精度究竟降在哪里

本文核对的是作者公开稿，下列页码和图号依该稿。期刊版为 *Philosophical Transactions A* **383**(2303), 20240355 (2025)。问题是自由空间中相同声软障碍物阵列受给定入射场激励。式 (3.1)、(3.3) 的胞元由两条**无限长竖墙**截出，墙层势在 Fourier 域用 Sommerfeld 积分计算。式 (4.11)、(4.15) 由 Riccati 传输映射求半阵列近场，式 (5.9) 拼接两个半阵列，式 (6.6)、(6.10) 是大有限阵列的离散与合并。§7 各例均取阻抗 $Z=-\mathrm i k$；原文没有把改变阻抗作为 Wood 修复。下列实验使用不同的参照解。[作者全文，§§3–7](https://www.researchgate.net/publication/393871031_Domain_decomposition_multiple_scattering_solvers_by_semi-infinite_and_infinite_arrays_of_discrete_identical_scatterers_in_two_dimensions)

- **半无限阵列。** §7.1，式 (7.1)、图 4（稿页 25，正文页 23–24）。图的纵轴是近场误差，左图参照值取 $M=1024$，在胞内水平线段上取 256 个场点。两个传输块随 $M$ 加密通常呈高阶收敛，但在 $k_j=j\pi/d$，$j=1,\ldots,4$ 处误差呈尖点。这些是周期 $2d$ 的阵列在法向入射下的阈值；对周期 $d$ 的阵列只有 $j=2,4$ 是相应的 Wood 频率。式 (7.1) 用到 $(S^M_{LL})^{-1}$，$M=1024$ 时该块在后两处的条件数约 $10^9$。右图比较大有限阵列与半无限阵列的近场，通常相差约 $10^{-10}$，四个异常点附近约 $10^{-6}$。作者保留了两个解释：半无限问题的真共振，或计算式 (3.3) 的积分路径过于接近密度的极点。右图不能单独量出广义特征值求解的误差。[作者全文，§7.1，图 4–6](https://www.researchgate.net/publication/393871031_Domain_decomposition_multiple_scattering_solvers_by_semi-infinite_and_infinite_arrays_of_discrete_identical_scatterers_in_two_dimensions)
- **无限周期阵列。** §7.2，正文页 26–28、图 7–9（页 29–31），参照是其文献 [5]，即 Pérez-Arancibia 等 2019 的全频准周期 BIE。图 7 中，法向入射时 Riccati 拼接式 (5.9) 在 $j\pi/d$ 出现精度下降；改变为 $45^\circ$ 入射后，原有位置仍有尖点，另外在随入射角移动的真实 Wood 频率处降得更明显。原文解释为竖墙的 Fourier 密度在积分变量 $\xi$ 上生极点，指出 “the proximity of such singularities to deformed Sommerfeld contours of integration”，最终只剩几位有效数字。准周期格林函数在这一组实验中用于独立参照；文中观察到胞元矩阵条件数恶化，没有将它归因于 Robin 参数选错或 QZ 算法本身。[作者全文，§7.2，式 (2.4)、(5.9)、(6.6)，图 7](https://www.researchgate.net/publication/393871031_Domain_decomposition_multiple_scattering_solvers_by_semi-infinite_and_infinite_arrays_of_discrete_identical_scatterers_in_two_dimensions)
- **修复状态。** §7.2 稿页 27 讨论了仿照 Barnett–Greengard 平移积分路径的办法；在本篇的胞元问题 (3.1) 中会引入非辐射场，作者说 “we do not have a means to cancel them out”。直接包含缺陷的算例见 §7.3 图 10（正文页 28、图在页 31）：从周期阵列去掉一个障碍物，以式 (5.7) 接入空条带；增大有限截断长度仍在首个 Wood 频率附近收敛慢。§8（页 28）没有给出修复后的穿越实验。将这个诊断移到我们的程序应另做检查：我们的例 1 在掠射点先坏在引线胞，两个行波坐标合并；Petropoulos–Turc 测的是另一种墙势积分。[作者全文](https://www.researchgate.net/publication/393871031_Domain_decomposition_multiple_scattering_solvers_by_semi-infinite_and_infinite_arrays_of_discrete_identical_scatterers_in_two_dimensions)；[本项目 P1](../../../test/bie-bound/failure-probe-v1/README.md#p1-wood-thresholds)

## 2. 哪些积分方程可以在 Wood 点计算

表中“精度”都附有被比较的量。散射场的点值、能流平衡误差和本征频率误差不可互换。页码为链接版本的正文页，Barnett–Greengard 2011 用期刊页。

| 方法与模型 | 意义 | 构造与已证明的范围 | 在阈值做过的数值检查 |
|---|---|---|---|
| Barnett–Greengard 2010，双周期介质体晶体 | (b)，体能带 | 有限个相邻像的自由空间层势，加胞壁辅助密度及准周期匹配。增广式 (33)–(34) 在空晶格共振处仍有定义。旧准周期核的定理 4（稿页 7）有非共振前提；新表示的双向核等价列为猜想 7。 | §3.3 图 3 与 §5 图 5(c) 放大同一条物理带与空晶格带的交点；增广系统能分辨交点附近的带。见稿页 11–13、18。[作者稿](https://arxiv.org/pdf/1001.5464) |
| Barnett–Greengard 2011，单周期障碍物散射 | (a) | 自由空间近邻势加墙势；在积分路径越过极点时增加一个平面波未知量和一个辐射约束。精确掠射时投影改用常数、线性函数，开放外域只允许有界的常数项；双重 Wood 点加两个未知量。见 §5 式 (5.1)–(5.2)，期刊页 84–85。 | 在精确单 Wood 点，$N=110,M=90$ 的场点值自收敛到 14 位，双边缩放后条件数约 $3.4\times10^3$。图 6(b) 给出跨阈值的各阶能流。[期刊全文](https://doi.org/10.1007/s10543-010-0297-x) |
| Cho–Barnett 2015，多层介质光栅 | (a)，也处理内部层的人工阈值 | 每层用近邻自由空间层势和代理源，在墙上拼相位；仅最外两层施加 Rayleigh 辐射。内部层可自行选取满足墙匹配的远场修正，消元次序避免重建发散的标准准周期核。定义 1、备注 1、式 (12)、§2.1、§3 式 (57) 与备注 3，稿页 5–8、14–16。 | §4 图 4，稿页 20–21，100 个界面，顶层恰逢 Wood，能流约有 9 位精度。作者没有给出闭波导频率算子的全纯定理。[作者稿](https://arxiv.org/pdf/1410.5003) |
| Bruno–Delourme 2014，二维周期导体粗糙面 | (a) | 对自由空间源沿法向作有限差分并平滑截窗，补回缺失的平面波。标准核式 (15) 含 $1/\beta_n$（此处 $\beta_n$ 为法向波数）；定理 4.4（稿页 12）、式 (48) 给出移位阶数控制的阈值代数收敛率。离开阈值平滑截窗可超代数收敛。 | §6.3，稿页 26–28，图 7 比较采用与省去式 (64) 补波项时的条件数和能流误差；单靠加大普通格点和的截断半径不能补波。[作者稿](https://www.its.caltech.edu/~obruno/preprints/PerGreenFnct2D_bruno_delourme.pdf) |
| Bruno–Fernandez-Lado 2017，周期柱阵列散射 | (a) | 把一至两个掠射阶提出为有限秩项，采用 Woodbury 型公式。§4.3 定理 2、式 (39)、(45)，稿页 12–13，在 $A_{k_0}$ 可逆的假设下，密度有连续极限且能直接在 $k_0$ 求值。§4.4 式 (51)–(53) 重建辐射场。 | §6.1、图 4（稿页 20）检查阈值附近能流误差。典型算例为理想导体柱；定理的连续性与可逆性前提应保留。[作者稿](https://arxiv.org/pdf/1610.08567) |
| Pérez-Arancibia–Shipman–Turc–Venakides 2019，周期分层散射 | (a)，包括有限厚度中间层的 RtR | 直接以移位核构造 RtR。稿页 12–13，定理 3.5、3.6 分别处理上方无界层与中间有界厚度层；在相应光滑性与阻抗条件下，Wood 频率处可逆，位移 $h$ 须避开离散例外集。这个例外参数是源的位移。 | 数值表 2–3（稿页 27）令两种材料同时处于 Wood 频率，分别比较能流和数值解；表 7 还有多层算例。这是已发表的 Wood 处 BIE–RtR 先例。[作者稿](https://arxiv.org/pdf/1801.09094) |
| Strauszer-Caussade 等 2023，穿透障碍物的周期行列，WGF | (a) | 仅截断墙积分会漏掉辐射条件。用有限秩项选出正确的 Rayleigh 模；§8.2 式 (78)–(79) 对法向波数取极限，出现常数模和线性模的迹。§8.3 证明窗口系统 Fredholm，明确留下唯一性问题，稿页 24–26。 | 图 6、7，稿页 26–27，比较更换窗口尺度以及扫过两个阈值的误差。图 8 才是反射、透射谱。[作者稿](https://arxiv.org/pdf/2205.11574) |
| Bruno–Garza–Pérez-Arancibia 2017，均匀开口波导的弯折、终端和接头，WGF | 不属上述穿越试验 | §2–3 给定入射导模，用平移不变支臂上的场修正加窗口的层势；§3.3 的误差推导对象是简化的振荡积分。 | §4 图 3–4、表 2，稿页 10–14，给出器件散射场；没有对周期晶体引线的背景掠射阶求导模频率。[作者稿](https://arxiv.org/pdf/1610.04939) |
| Pérez-Arancibia–Yin 2026，双周期介质体晶体，预印本 | **(b)，明列全纯域** | 固定两 Bloch 相位，未知量是界面和两面胞壁的 Cauchy 迹。三胞叠合消去墙的自作用和共端点项，得到自由空间第二类方程 (42)。§4.4 命题 4.2 及其后段，稿页 12，在对比参数 $\eta\ne-1$ 下给出指标零；$E-L$ 对 $\omega\in\mathbb C\setminus(-\infty,0]$ 全纯。若一点可逆才推出逆亚纯；作者明确未证明该一点的可逆性。 | §7.1 图 4，稿页 18–19，以 30 个 Bloch 向量上的空晶格精确频率对照，找全 93 个不同频率，$\omega a/c$ 最大绝对误差 $2.1\times10^{-9}$。有对比度的杆阵列另见表 1。这个测试没有半无限缺陷引线。[预印本 v1](https://arxiv.org/pdf/2610.28494v1) |

## 3. 实际算过哪一种跨越

**体晶体能带已经算过。** Barnett–Greengard 图 3(b) 与图 5(c) 比较在两条带的交点附近换表示的效果。Pérez-Arancibia–Yin 式 (51)、图 4 还给出可独立核查的一例：在方晶格 $\Gamma$–$X$ 段，一方向的 Bloch 分量为零，选该方向为法向、法向倒格指标也为零，空晶格折叠色散就化为 $k_{\rm bg}=|\beta+2\pi m/d|$。因此他们的空晶格对照包含法向波数恰为零的模。这一点是把他们的坐标换成本文坐标得到的推论；原文列的是体能带误差。两篇都没有引入缺陷及其两侧半无限引线。[Barnett–Greengard，图 3、5](https://arxiv.org/pdf/1001.5464)；[Pérez-Arancibia–Yin，§7.1](https://arxiv.org/pdf/2610.28494v1)

| 导模或 Bloch 方法 | 原文求了什么 | 能否据此声称穿过背景阈值 |
|---|---|---|
| Botten 等 2004 | *Phys. Rev. E* **70**, 056606，§II 式 (3)–(7)，页 056606-2–3，用行波衍射阶构造转移矩阵和 Bloch 乘子；§III 式 (30) 为模态归一化。同年的 *Optics Express* **12**，§2 式 (1)、(6)–(9)，页 1594–1598，用这些基匹配晶体堆栈。 | 在以上两篇的端口构造中未找到在零法向波数处补上线性独立解的步骤，也未找到精确掠射的误差表。[PRE 作者全文](https://www.researchgate.net/publication/8128723_Bloch_mode_scattering_matrix_methods_for_modeling_extended_photonic_crystal_structures_I_Theory)；[Optics Express 机构全文](https://opus.lib.uts.edu.au/bitstream/10453/397/1/2004001968.pdf) |
| Botten 等 2006，虚源叠加 | W3 线导、无限晶体包层，§II.C–D 式 (17)–(20)，页 135–137，求 $\det Z(k,\alpha_0)=0$。§III 图 2–3，页 141，比较第二导模接近截止时与超胞 FEM 的色散。 | 有导模截止的数据。图 2(b) 的已报点是 $d/\lambda=0.32,\ \alpha_0d=1.67541$，背景为空气，故 $kd=2\pi(0.32)\simeq2.011\ne1.67541$。图 3 没有标出某阶 $\gamma_m=0$ 时如何取极限或该点误差。[期刊全文](https://www.ijmot.com/ijmot/uploaded/oTKv4AYm42.pdf) |
| Dossou–Byrne–Botten 2006 | 单胞内部用 FEM，外接衍射阶；作者稿式 (13) 页 7 有 $\chi_m^{-1/2}$ 的通量归一化，紧接着明说 “the wavelength does not coincide with a Rayleigh anomaly”。页 9 的广义本征问题用于避开传输矩阵求逆的病态。 | 假设显式排除了问题中的频点。改写广义铅笔能处理强倏逝阶的数值困难，不能据此把式 (13) 延拓到 $\chi_m=0$。[机构全文](https://opus.lib.uts.edu.au/bitstream/10453/704/1/2006005632.pdf) |
| Huang–Lu–Li 2007 | 圆柱波组成的局部解在四边上给出 $\Lambda=BA^{-1}$，稿页 7–8 式 (16)–(17)；合并成超胞，在给定频率求传播相位。§4 图 2–3、6–7（稿页 10–14）给出线导色散与场。 | 墙迹的构造不必除以背景 Rayleigh 波数。数值结果有横向截断或有限介质板，未单列无限周期包层中的背景阈值根。[作者稿](https://citeseerx.ist.psu.edu/document?doi=1eae9bb04925a1909596f726c9c82518f0420ef9&repid=rep1&type=pdf) |
| Fliss–Klindworth–Schmidt 2015，FEM + RtR | §3.1–3.2，期刊页 86–90，定理 3.1 把半条带 Robin 问题放在引线本质谱外；取非零实数 Robin 参数 $\alpha$，胞内式 (3.3) 对正频率及各实 Bloch 参数适定。§4 定理 4.1，页 100–101，把原导模问题等价化为缺陷胞上的方程。 | 同类物理问题已有不引入 $1/\gamma_m$ 的算法。§5.3 图 9–11（页 111–113）验证的是局部和半条带 Dirichlet 例外值附近的行为；作者没有把该试验称为背景 Wood 扫描。其前提仍会在真正的引线谱边改变。[期刊全文](https://doi.org/10.1007/s10543-014-0521-1) |
| Tausch 2013 | 双周期三维薄板，Galerkin 边界元。稿页 5–6 式 (6) 后将两外域的衰减系数 $\alpha_\ell^\pm$ 全部取正实数；定理 2、式 (15)–(16)，页 9，给出此范围中的导模重建。§5–6 页 15–18 固定频率求 Bloch 向量，表 1–2 作加密。 | 均匀外域的光锥是物理辐射边界。外 DtN 仍有平方根符号，所给本征计算限于光锥以下。[作者稿](https://citeseerx.ist.psu.edu/document?doi=e7b1b75cdec683effdc998ad0da764bdfce97278&repid=rep1&type=pdf) |
| Agocs–Barnett 2024 | 周期声硬阶梯的表面陷获模，§3 图 5、定理 4，文内页 10–11；齐次 BIE 式 (42) 的数值色散在光线以下。 | 作者明确指出该分支没有与光线相交。局部激励的逆 Bloch 积分可以绕过分支点，这与在固定实相位的阈值上求根是两项不同的检验。[期刊全文](https://doi.org/10.1016/j.jcp.2024.113383) |

## 4. 胞壁数据与局部例外频率

有三种值得对照的胞壁构造。它们说明“没有背景 Wood 分支点”“局部映射处处存在”和“全局零点都是导模”需要分别核查。

1. **Dirichlet 墙迹。** Yuan–Lu–Antoine 在普通或缺陷形状的介质柱周围，以整空间单柱透射解做特殊解，用自由空间 Hankel 核求界面数据。作者稿 §3 页 11–12 式 (32)–(34) 将这些解及其法向导数采在胞壁上，得到 $\Lambda=\Lambda_2\Lambda_1^{-1}$；§4 表 1（页 17–18）给出体晶体色散。这条路径没有准周期辐射核。公式仍须能从墙值唯一恢复解。在固定切向相位、端面取齐次 Dirichlet 的胞问题，Fliss 等明确指出有可数个局部 Dirichlet 特征频率（期刊页 88，式 (3.3) 后）。同理，由 Neumann 数据构造局部 NtD（Neumann 到 Dirichlet 映射）时，应检查对应的齐次 Neumann 问题；这是映射的唯一性要求，本文未把它当作 Yuan 等的定理。[Yuan–Lu–Antoine 期刊论文](https://doi.org/10.1016/j.jcp.2008.01.014)；[Fliss 等，§3.2](https://doi.org/10.1007/s10543-014-0521-1)
2. **Robin 墙迹。** Pedneault–Turc–Boubendir 的有限盒含声软障碍物，外盒墙施加非零虚阻抗。作者稿页 11，式 (2.24)、定理 2.1 的证明对齐次解取 Green 恒等式虚部，得到墙上的场为零，进而法向导数也为零，再用唯一延拓。§3 式 (3.8)、定理 3.2（页 20）给出以自由空间层势及正则化算子构成的离散前 BIE 的唯一可解性和对数据的连续依赖。这解释了为何可避开正实局部 Dirichlet 例外值；他们的模型是声软多体散射。对准周期介质胞，Fliss 等的式 (3.3) 同样采用两端 Robin 数据；定理 3.1 对**半无限**引线另要求频率在本质谱外。Pérez-Arancibia 等 2019 又给出了用 BIE 求**周期层** RtR 的定理 3.6；它对移位 $h$ 有条件。[有界盒 BIE 全文](https://arxiv.org/pdf/1608.00034)；[介质线导 FEM 全文](https://doi.org/10.1007/s10543-014-0521-1)；[周期层 BIE 全文](https://arxiv.org/pdf/1801.09094)
3. **同时保留两种 Cauchy 迹。** Pérez-Arancibia–Yin 在式 (38)、(41)–(43) 中保留值和法向导数，无需先形成局部 Dirichlet 逆。§5 引理 5.1 保证每个物理 Bloch 模产生非零核向量；定理 5.3 和推论 5.4（页 13–14）在其实正材料与单位模相位的假设下用胞外表示场的消失判别真模。原文的围线条件是整条曲线上的条件，有限采点仅是数值判据。他们确实在有对比度的算例检出伪频率（§7.2）。这解释了为何一套全纯的胞元方程仍需物理核检验。Cho–Barnett 的自由空间代理源也是已有的墙匹配构造，但其备注 1、3 讨论的是散射系统如何选取有界的辅助解，没有证明对复频率取伪逆会给出全纯导模矩阵。[Pérez-Arancibia–Yin 全文](https://arxiv.org/pdf/2610.28494v1)；[Cho–Barnett，稿页 5、15](https://arxiv.org/pdf/1410.5003)

**周期半空间的 Cauchy 投影也有先例。** Ramdani–Shipman（2008）用无限周期介质在谱隙中的格林函数构造半空间 Cauchy 投影；期刊页 554–555 定理 2.1 刻画了两侧的投影，并证明跨板耦合块随厚度指数衰减。他们还需接到均匀外域，页 547 式 (2.5) 后显式要求外域每个法向波数均非零。页 566 定理 4.1 讨论缺陷结构没有束缚态时厚板透射的衰减。已有的是连续迹空间构造；未给出只用一个离散散射胞、在人工阈值上计算导模的算法。[作者提供的期刊全文](https://karim-ramdani-site.apps.math.cnrs.fr/wp-content/uploads/2021/01/08_M3AS.pdf)

**与我们端口的距离。** 设 $s=x-x_w$ 为相对于人工墙的法向坐标。均匀部分的一阶 Fourier 分量可写为
$$
u_m(s)=q_m\cos(\gamma_m s)+p_m\frac{\sin(\gamma_m s)}{\gamma_m},
\qquad q_m=u_m(0),\quad p_m=u'_m(0).
$$
两系数函数都对 $\gamma_m^2$ 整，在阈值分别等于 $1,s$。这是由法向常系数方程直接得到的局部说明。完整 Cauchy 通量仍是 $\operatorname{Im}(\overline q_m p_m)$。在真开放半空间，线性增长项须由辐射条件剔除；在晶体两胞之间的有限条带，两项都参与匹配。把此替换带入**材料散射胞的求解和迹提取**，再证明带隙中的衰减子空间能解析选取，才涉及本项目的引线；只改最后的行列式仍会在上游遇到 $1/\gamma_m$。[本项目端口推导，第 2 节 Wood 段](../../projects/bie-enclosure/theory/port-subspace.md#单位圆wood-点和漏掉的传播阶)；[Barnett–Greengard 2011，期刊页 85](https://doi.org/10.1007/s10543-010-0297-x)

## 5. 开放散射系数的平方根从哪里来

Hessel–Oliner 在 *Applied Optics* 刊页 1283，式 (19)–(20) 后，将共振分母条件与新衍射阶擦边出现的条件分别列出，后者是 “the branch point singularities occurring at the Rayleigh wavelengths”。Wojcik 等的光子晶体板例给出更直接的系数陈述。其接受稿正文第 2 页（带封面的 PDF 第 3 页），图 1(b)–(d) 及图旁公式指出 “The S matrix is analytic as a function of β”；他们的 $\beta$ 是**新通道法向传播常数**。在该例 $\beta\sim(2\pi/c)\sqrt{2f_c(f-f_c)}$，图 1(c) 显示反射系数幅值在 $f_c$ 的转折。[Hessel–Oliner 期刊全文](https://www.researchgate.net/publication/249339215_A_New_Theory_of_Wood%27s_Anomalies_on_Optical_Gratings)；[Wojcik 等，APS 接受稿](https://link.aps.org/accepted/10.1103/PhysRevLett.127.277401)

用本项目的记号，在 $k_*>0$、
$k_*^2\rho_{\rm port}=(\beta+2\pi m/d)^2$ 时，有
$\gamma_m^2=\rho_{\rm port}(k-k_*)(k+k_*)$。若某个散射系数在局部展开中含非零的一次 $\gamma_m$ 项，它对 $k$ 就有平方根项，而在 $k_*$ 的极限可以有限。某个具体矩阵元的奇次项也可能消失。这个推论解释了为何阈值处能算出许多位场值，却仍不能在开放散射的频率插值中假设普通 Taylor 展开。[Wojcik 等，图 1 与两端口模型](https://link.aps.org/accepted/10.1103/PhysRevLett.127.277401)；[Bruno–Delourme，§2.2 式 (15)](https://www.its.caltech.edu/~obruno/preprints/PerGreenFnct2D_bruno_delourme.pdf)

## 论文能主张到哪一步

若按物理问题选比较对象，应选 Fliss 等的线导 RtR；按积分算子选，应选 Pérez-Arancibia–Yin 的全纯胞壁 BIE，并引用已发表的 Barnett–Greengard 体能带穿越算例；按 BIE 半阵列闭合选，应选 Petropoulos–Turc。可以检验的具体命题是：**固定切向相位，在背景掠射点仍构造两侧周期引线的完整衰减迹，并用它们求出共同带隙内的导模频率。** 该命题还需要在通量坐标、引线谱与单位圆分离、匹配核的物理意义上给出条件。最有区分力的数值比较是在同一组参数上报告精确 Wood 点的胞元输出和一个经过它的导模分支，以独立墙迹法或 FEM 作对照，给出两侧加密误差。已有 P1 的两级网格在精确 Wood 处均在引线阶段失效（例 1 的远场提取出现除零，W3 的两行拼接先出现非有限数）；所报 $\beta\simeq1.98154$（例 1）、$2.97503$（W3）是连续追踪的交点估计，尚无该处精确导模频率的独立对照。[P1，阈值与两侧追踪](../../../test/bie-bound/failure-probe-v1/README.md#p1-wood-thresholds)

写作中应避免三种说法：

- “首次在 Wood 点求解 BIE”或“首次得到对频率解析的光子晶体胞元 BIE”。已有开放光栅实算与闭胞全纯算子两类直接先例。
- “半无限阵列在这些点有真共振”或“Riccati、QZ、Robin 参数导致失效”。Petropoulos–Turc §7.1 保留了两种解释，§7.2 对无限光栅给出了更具体的积分路径诊断。
- “算到了带边或光线附近便验证了背景 Wood 穿越”，或“有限的点值、能流误差、行列式零点就是频率全纯性和物理导模的证明”。这几项各有不同的验证对象。

## 候选文献与检索范围

以下七篇未在本地目录和上一篇 N01–N18 清单中找到，建议作为**新增候选**。Petropoulos–Turc（N06）、两篇 WGF（N09、N10）、Botten、Dossou 和 Tausch 已有候选条目；其全文及此次核对的位置列于上文。Cho–Barnett 的作者稿已在本地待整理文献中，Pérez-Arancibia–Yin 的预印本已在库中。[既有候选表](bie-solver-novelty.md)；[本地目录](../../../ref/README.md)

1. A. Hessel、A. A. Oliner，*A New Theory of Wood’s Anomalies on Optical Gratings*，*Applied Optics* **4**(10), 1275–1297 (1965)，DOI 10.1364/AO.4.001275。[Optica 提供的期刊全文](https://www.researchgate.net/publication/249339215_A_New_Theory_of_Wood%27s_Anomalies_on_Optical_Gratings)
2. O. P. Bruno、B. Delourme，*Rapidly convergent two-dimensional quasi-periodic Green function throughout the spectrum—including Wood anomalies*，*Journal of Computational Physics* **262**, 262–290 (2014)，DOI 10.1016/j.jcp.2013.12.047。[Caltech 作者全文](https://www.its.caltech.edu/~obruno/preprints/PerGreenFnct2D_bruno_delourme.pdf)
3. O. P. Bruno、A. G. Fernandez-Lado，*Rapidly convergent quasi-periodic Green functions for scattering by arrays of cylinders—including Wood anomalies*，*Proceedings of the Royal Society A* **473**(2199), 20160802 (2017)，DOI 10.1098/rspa.2016.0802。[作者全文](https://arxiv.org/pdf/1610.08567)
4. M. Pedneault、C. Turc、Y. Boubendir，*Schur complement domain decomposition methods for the solution of multiple scattering problems*，*IMA Journal of Applied Mathematics* **82**(5), 1104–1134 (2017)，DOI 10.1093/imamat/hxx026。[作者全文](https://arxiv.org/pdf/1608.00034)
5. C. Pérez-Arancibia、S. P. Shipman、C. Turc、S. Venakides，*Domain Decomposition for Quasi-Periodic Scattering by Layered Media via Robust Boundary-Integral Equations at All Frequencies*，*Communications in Computational Physics* **26**(1), 265–310 (2019)，DOI 10.4208/cicp.OA-2018-0021。[作者全文](https://arxiv.org/pdf/1801.09094)
6. C. C. Wojcik、H. Wang、M. Orenstein、S. Fan，*Universal Behavior of the Scattering Matrix Near Thresholds in Photonics*，*Physical Review Letters* **127**(27), 277401 (2021)，DOI 10.1103/PhysRevLett.127.277401。[APS 接受稿](https://link.aps.org/accepted/10.1103/PhysRevLett.127.277401)

7. K. Ramdani、S. P. Shipman，*Transmission through a thick periodic slab*，*Mathematical Models and Methods in Applied Sciences* **18**(4), 543–572 (2008)，DOI 10.1142/S0218202508002772。[作者提供的期刊全文](https://karim-ramdani-site.apps.math.cnrs.fr/wp-content/uploads/2021/01/08_M3AS.pdf)

检索截至 2026-11-07，覆盖本地全文、期刊平台、arXiv、作者及大学公开稿，并沿上述论文引用追查。检索词包括 “Wood/Rayleigh anomaly + guided mode / line defect / grazing order / Bloch scattering matrix”、“empty lattice + photonic band + boundary integral”、“cell wall + Robin / Cauchy / impedance map” 和 “shifted / windowed Green function”。另查 White 等的同系列第二篇 *Bloch mode scattering matrix methods for modeling extended photonic crystal structures. II. Applications*（*Phys. Rev. E* **70**, 056607，2004），本次未核得可确认来源的公开全文，不据它判断掠射处理。上文关于方法的判断均取自所标版本正文；“未找到”限于这组检索及取得的全文，不构成优先权结论。[White 等期刊记录](https://doi.org/10.1103/PhysRevE.70.056607)
