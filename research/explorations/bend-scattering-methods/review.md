# 弯折散射数值方法的独立价值审查

`bend-scattering-methods` 表示弯折散射数值方法专题，`review` 是独立审查记录。本轮为2026-10-31 03:08:10–04:38:10 UTC；复核者只写本文件，由lead统一提交。首轮先形成独立判断，再读主稿，避免沿主稿排序反推新颖性。

Task mode: **Review only**。Proof status: **Reviewed literature and conditional analytic diagnostics; no new scattering theorem.** 本文件不证明新散射主定理，不运行数值实验；后续短推导仅用于否证不可能的保证、辨认算法贡献及确定第一门。部分全文核查仍有明确访问/证据边界。

**实质结论：本轮零项通过独立立项门槛。** 截止误差传递有计算用途，但目前未识别超出既有增广波、广义谱逼近及标准扰动的新数值机制，宜降为可靠性验收要求。以下早期倾向是过程记录，最新判断见§§10–20。§§18–20另核横向无限晶体M0的直接算法：不能用硬壁文献宣布M0整体解决，也不能以开放晶体弯角尚无数值框架为由重新立项。

## 1. 执行边界与审查标准

03:09核实实际目录 `/Users/whc/Documents/Work/dot-research`，分支 `codex/dot`，HEAD `9cb8d8a23f6eae8090da95aa92fa85c7b9df16ae`，初始Git工作区干净。已重新读根AGENTS.md、AGENTS.override.md、research/AGENTS.md、README/STATUS/NOTATION及rigorous-proof Review-only相关规则。现有数值成果是固定轴向准动量的导模谱结果，不能直接当作弯角开放散射的解、端口完备性或全频段保证。worktree约93MB；本文件文字预算100KB，不写其它文件、不提交/push、不运行MATLAB或其它实验，不读取私有远端。公开文献下载优先由lead执行，复核者仅提供来源，不在ref另建同名副本。

本轮要求**一个主候选、至多一个备选，也允许零项合格**。一项合格的数值方法课题至少要回答：

1. 输出究竟是一个固定实频率的复散射振幅、功率、频带上的函数，还是复共振位置/个数？不能混成“解决散射”。
2. 哪个现有计算步骤确有困难，困难是坐标/基选择、实际物理解的敏感性，还是尚未证明的误差估计？已有定理没覆盖不能自动证明算法失效。
3. 新环节是否超出FEM/BIE＋DtN/PML＋模态展开的常规拼接？用更高精度或换一个蜂窝几何不够。
4. 保证是否包含端口误差、空间离散、截断和稳定性常数？只对有限矩阵成立时必须如此命名。
5. 首个廉价理论诊断能否使其失败或降级，且失败结论有明确含义？本轮只设计诊断，不执行实验。

模型先选质量型 $-\Delta u=\omega^2\rho u$ 或散度型 $-\nabla\cdot(a\nabla u)=\omega^2u$ 之一。固定完整bulk gap内的有限导波通道是一种可行首期限定；若无完整gap，必须包含体辐射，不能把有限端口的酉性当完整守恒。蜂窝、$120^\circ$ 与拓扑不预设为算法必要条件。

## 2. 独立先验否证：三个切口各自不能许诺什么

### A. 近截止端口：先分清三种不同现象

同向传播分支的半单简并、相反通量分支恰有同一Floquet乘子、群速度为零的带边不是同一问题。半单简并内部可以用块基/通量形式避免任意特征向量旋转；若通量正负子空间仍有分离，就不能仅以本征向量变化大宣布物理散射病态。相反，在真正截止处，入/出通道合并及通量归一化确有内在退化。

**独立解析诊断，不是新算法。** 一个均匀标量通道满足 $u''+q^2u=0$，两方向Cauchy向量为 $(1,\pm iq)^\top$；合并基的行列式为 $-2iq$。$q\to0$ 时单模方向分解病态，而出射DtN系数 $iq$ 本身有界并趋零。单位通量场的幅度为 $O(q^{-1/2})$，出射Green核有 $1/(2iq)$ 因子。这说明**部分病态来自表示，部分来自真实阈值**。仅改基不能使所有物理量及材料扰动敏感性对 $q$ 一致有界。

可保留的数值目标应说明：对哪个簇的Cauchy数据/端口算子，在何种加权范数及带边局部变量中给误差；到真实截止时是否改输出或返回不可分辨。不能承诺保持固定维数、单位通量普通S矩阵在通道开闭点无条件解析且具有统一条件数。Riesz投影若把入/出都包进同一簇，可以稳定表示整个簇，却还没有稳定分出出射部分。

### B. 窄共振：固定频率输出和不漏检频扫必须分开

有限端口无损散射矩阵在实轴可有界，但场的范数或对结构/频率的导数可以很大。不能据 $\|S\|=1$ 推出容易算准S，更不能用总场小残差除以一个未算出的稳定常数冒充可计算误差界。

**独立解析诊断。** 单通道全通因子

$$s_{\gamma,a}(\omega)=\frac{\omega-a-i\gamma}{\omega-a+i\gamma},\qquad\gamma>0$$

在实轴模恒1。对任意固定的有限采样点集，取 $a$ 在采样点之间、令 $\gamma$ 足够小，所有样本都可任意接近常数1，但 $s_{\gamma,a}(a)=-1$。因此在没有可核的线宽/解析邻域/导数或极点信息时，有限点拟合、守恒及留出点测试不能给频窗内“不漏共振”的最坏情形保证。并且 $\partial_a s_{\gamma,a}(a)=2i/\gamma$，故固定实频率输出若要绝对精度 $\epsilon$，一般仍须把有效共振中心误差控制到 $O(\epsilon\gamma)$。这不是所有正材料PDE均实现该族的证明，而是任何声称只用有限样本与酉性就可靠的抽象方法必须排除的反例类。

有价值的算法可以在缺信息时诚实返回未分辨；不能先假设所有目标共振已被定位，再把“不漏检”当贡献。极点个数、极点位置、残量及一个指定散射输出的误差也不同：暗模可在所选输出中抵消，极点计数本身不等于输出认证。

### C. 微小反射：守恒不是精度证书

对任意实 $\theta$，

$$S_\theta=\begin{pmatrix}\cos\theta&i\sin\theta\\i\sin\theta&\cos\theta\end{pmatrix}$$

都是互易酉矩阵，而反射功率从0到1皆可取。因此能量平衡误差、互易性误差同时为0也不能给反射误差上界。一般全端口下应使用相应通量/Gram矩阵；有倏逝或非正交通道时直接检查 $S^*S=I$ 还可能检查错对象。

“相对误差很小”在反射振幅穿零时本就无法统一定义。可用的任务是复振幅绝对误差、功率区间或对 $R\le R_0$ 的判定；若只把旧双对偶误差表示、散射场消去入射场或任意精度运算搬到新几何，按本轮标准淘汰。若有新意，应在端口与无限域误差的完整闭合或相对全场界显著更好的可证明目标量控制中寻找，而非笼统称“算出很小反射”。

## 3. 已定位的强近邻及当前核读深度

下列是第一轮证据，不因没有直接覆盖目标就认定目标开放。T表示读到具体公式/定理条件，A表示仅摘要/元数据；完整证明另核。

### R1 周期端口的 contour/模态法早已存在

**Ruming Zhang (2021), *Numerical methods for scattering problems in periodic waveguides***，Numerische Mathematik **148**,959–996，DOI [10.1007/s00211-021-01229-0](https://doi.org/10.1007/s00211-021-01229-0)，[出版商开放正文](https://link.springer.com/article/10.1007/s00211-021-01229-0)。目前T：模型§2、Assumptions1–2、§§6–8算法及§9.4。质量型正有界周期系数、硬壁条带、紧支撑源；已有复轮廓积分法、传播模方法和半波导方法。§8“更一般波数”主要处理左右传播集合重合，并非自动覆盖零群速截止；需继续逐条核其Assumption1。非周期弯角也不能只靠全局Bloch积分代替局部匹配。

### R2 常系数/圆柱端近截止的多尺度处理已有专门方法

**Martin Halla, Lothar Nannen (2018；线上2017), *Two scale Hardy space infinite elements for scalar waveguide problems***，Advances in Computational Mathematics **44**,611–643，DOI [10.1007/s10444-017-9549-5](https://doi.org/10.1007/s10444-017-9549-5)，[出版商入口](https://link.springer.com/article/10.1007/s10444-017-9549-5)。当前A：圆柱标量端、近cutoff慢/快两尺度，作者已提出两尺度Hardy无限元并给相应指数收敛结果。仅说PML近截止需要长层或提出慢模显式分离并不新；必须读其具体阈值与误差常数后再判别周期端差异。公开PDF待核，不将摘要中的收敛表述扩展到精确cutoff。

### R3 阈值S矩阵的平方根结构不是本轮发现

**Charles C. Wojcik, Haiwen Wang, Meir Orenstein, Shanhui Fan (2021), *Universal Behavior of the Scattering Matrix Near Thresholds in Photonics***，Physical Review Letters **127**,277401，DOI [10.1103/PhysRevLett.127.277401](https://doi.org/10.1103/PhysRevLett.127.277401)，[作者稿](https://arxiv.org/html/2107.02321v1)。T：通道、阻抗及式(1)附近推导，继续核其阻抗有限的泛性条件。已有由互易、守恒、时间反演得到的阈值模型及光子晶体slab/界面/金属波导例子；“用平方根局部变量”“阈值开通道S有普适形”均不能单独认领。它也不是自动适用于所有零能共振的均匀数值误差定理。

### R4 简并/倏逝模的广义互易关系已有

**Guro K. Svendsen, Magnus W. Haakestad, Johannes Skaar (2013), *Reciprocity and the scattering matrix of waveguide modes***，Physical Review A **87**,013838，DOI [10.1103/PhysRevA.87.013838](https://doi.org/10.1103/PhysRevA.87.013838)，[作者稿](https://arxiv.org/html/1301.2458v1)。T：§II式(4)、(8)–(11)，非正交简并、倏逝和复模需用广义正交矩阵，得到 $CS=(CS)^T$。其端口沿轴均匀，非平行开放辐射端口存在模场重叠问题，原文§I明确讨论。不能把它直接作为周期弯角全部模态完备性的定理；也不能把广义互易公式包装为新算法。

### R5 散射S参数的目标量自适应不是新方向

**Pär Ingelström, Anders Bondeson (2003), *Goal-oriented error estimation and h-adaptivity for Maxwell’s equations***，Computer Methods in Applied Mechanics and Engineering **192**,2597–2616，DOI [10.1016/S0045-7825(03)00295-0](https://doi.org/10.1016/S0045-7825(03)00295-0)，[出版商摘要](https://www.sciencedirect.com/science/article/pii/S0045782503002950)。目前A：波导腔S参数、对偶解、层次基及自适应已有；摘要是数值effectivity而非无条件可计算可靠上界。不能因它是Maxwell就认定标量Helmholtz的相同目标量策略有创新。另有2004短文 *Goal-Oriented Error-Estimation for S-Parameter Computations*，IEEE Transactions on Magnetics **40**(2),1432–1435，DOI [10.1109/TMAG.2004.824606](https://doi.org/10.1109/TMAG.2004.824606)。后者目前仅核索引，不采用其全文细节。

### R6 规避直接计算inf-sup的输出误差估计也有先例

**Lihong Feng, Peter Benner (2020作者稿), *On Error Estimation for Reduced-order Modeling of Linear Non-parametric and Parametric Systems***，[arXiv:2003.14319v2](https://arxiv.org/html/2003.14319v2)。T：§§1–3、Proposition3.1；线性传递函数的真实误差为精确对偶解与原残差配对；已有避免直接算最小奇异值的估计变体。下一步需核其中“估计器”与“可靠上界”需要什么不可省的误差项，不能据标题宣告B已解决，也不能声称“首次输出估计不除inf-sup”。这是有限线性系统/降阶误差，不自动包含连续PDE、端口和截断误差。

### R7 共振识别与自适应有理代理的近年强覆盖

**Davide Pradovera (2020), *Interpolatory Rational Model Order Reduction of Parametric Problems Lacking Uniform Inf-Sup Stability***，SIAM Journal on Numerical Analysis **58**(4),2265–2293，DOI [10.1137/19M1269695](https://doi.org/10.1137/19M1269695)。目前A：meromorphic解映射、有理插值、共振识别、后验指标和自适应采样已有。

**Davide Pradovera, Ralf Hiptmair, Ilaria Perugia (2025), *Surrogate modeling of resonant behavior in scattering problems through adaptive rational approximation and sketching***，Journal of Scientific Computing **104**，DOI [10.1007/s10915-025-03020-x](https://doi.org/10.1007/s10915-025-03020-x)。目前仅核[作者出版物页](https://pradovera.github.io/publications/)的书目与摘要：BIE解算子范数、adaptive rational approximation及随机sketch已有；具体保证待原文。出版商DOI入口工具不可达，未重试；将通过作者页明确给出的公开稿核正文，不能把聚合站概述当证据。

**新近还须查的一篇**：*Scattering Matrix Interpolation for Modeling Resonant Photonic Crystal Structures Using the Fourier Modal Method*，JETP Letters (2025/2026具体卷年待核)，DOI [10.1134/S0021364025609340](https://doi.org/10.1134/S0021364025609340)。检索返回原出版内容：分成非共振子层后插值子层S，再组合恢复窄共振，避免直接粗网插值总S；需核完整作者、年份及保证。DOI重定向工具500不可重试，停止该路径，不重复读取。尚不据此断言已给“不漏检”的可靠保证。

## 4. 当前倾向与下一查证

尚不选定主候选。A与B均有强既有方法，C作为一般“微小反射更准确”应先淘汰。接下来优先核R2的cutoff收敛条件、R1到底排除什么、R6上界中的剩余误差，以及R7近年方法是否只作代理指标还是已有完整误差/漏检保证。主稿出现后应给出明确的新算法步骤与先验信息预算，再决定保留哪一项；不能以“周期端更难”或“没有严格证明”作为唯一创新理由。

References downloaded in this pass: **none**；当前对应全文未在本地作者名文件检索中发现，下载/完整catalog核验由lead协调。Source proof files modified: **none**。截至本段不存在新proof环境、定理标签或实验结果。

## 5. 03:19的原文核读更新：已经足以否决的创新表述

以下更新取代§3相应条目的较浅阅读标签，原条目保留作为查证过程记录。

**R1更新（T）。** Zhang的Assumption1明确要求 $P_0=\varnothing$，即排除零群速Bloch分支；§5.3和§8移除的是Assumption2（同一Floquet点有正负非零斜率分支），仍保留Assumption1。因此它覆盖一类相反通量简并，却不覆盖真正截止。不能把“既有算法只处理简单模”作为A的动机，也不能反过来宣称该文已经解决零群速阈值。

**R2更新（T）。** 已读[开放PDF](https://link.springer.com/content/pdf/10.1007/s10444-017-9549-5.pdf)的§§2、3.4、4.2–4.3及5：式(2.9)的Hardy条件排除精确cutoff处的零Laplace极点；附近慢模已有双尺度和mode-matched基。后者只需慢模波数，且原文已警告大阶数下近线性相关。式(4.14)、(4.16)及(4.20)还分析内部解误差、对偶改进及端口尾项。故“显式保留慢模”“双尺度处理”“用对偶改善内部量”均已有。其固定频率存在的稳定常数不应读成可计算或跨cutoff一致的常数。

**R6更新（T）。** Feng–Benner的Theorems3.1–3.3不能据标题理解为所有估计量都是可计算上界：精确界含完整对偶残差解；换为降阶近似后，剩余项如 $\epsilon_2=|(x_{rdu}-\widehat x_{rdu})^T r_{pr}|$ 仍含未知误差。实践估计量有效不等于该项自动已受控。B若主张规避不可计算inf-sup，必须给出这个剩余项的可计算闭合，而不能仅复写双对偶残差表示。

**R7更新（T）。** 已读Pradovera–Hiptmair–Perugia的[2025原文v2](https://arxiv.org/html/2503.10194v2)，含§§2–5、Theorem3.1、Proposition3.4及Algorithms2–4。目标是有限BIE矩阵逆的范数及其场放大代理；局部Laurent分析说明极点位置之外还需残量。自适应有理近似、随机sketch及“找极点后拟合峰形”均已有。采样预算与邻近极点数的关系含启发式，不能把它当连续频窗不漏检定理；作者也明确区分理论依据和经验验证。本轮若只再提有理代理，创新不足。

### R8 全BIE逆的峰可并非物理散射峰：已有排除方法

**Ralf Hiptmair, Andrea Moiola, Euan A. Spence (2022), *Spurious Quasi-Resonances in Boundary Integral Equations for the Helmholtz Transmission Problem***，SIAM Journal on Applied Mathematics **82**(4),1446–1469，DOI [10.1137/21M1447052](https://doi.org/10.1137/21M1447052)，[原文v4](https://arxiv.org/html/2109.08530v4)。T：Theorems1.10–1.12、增广算子和Theorem1.15。

质量型常系数内外透射问题中，第一类和第二类BIE逆同时混入原物理问题与交换材料问题的解算子；限制到物理Calderón数据范围后才恢复相应物理解。原文已有附加Calderón约束的增广BIE和稳定性估计。因此不能把全BIE逆范数峰自动称为物理S参数的窄共振，也不能把“投影物理Cauchy范围过滤假准共振”作为本轮首创。该结论不直接覆盖周期端，但改变了B的基准：拟比较的必须是指定物理输入—输出，而非任意矩阵逆峰值。

### R9 增广S矩阵跨阈值的算法并非空白

**B. A. Plamenevskii, A. S. Poretskii, O. V. Sarafanov (2014俄文／2015英文), *Method for computing waveguide scattering matrices in vicinity of thresholds***，Algebra i Analiz **26**(1),128–164；St. Petersburg Mathematical Journal **26**(1),91–116，DOI [10.1090/S1061-0022-2014-01332-5](https://doi.org/10.1090/S1061-0022-2014-01332-5)，[MathNet原始条目及开放俄文PDF](https://www.mathnet.ru/php/archive.phtml?jrnid=aa&option_lang=rus&paperid=1371&wshow=paper)。

目前A＋部分原文公式：原始摘要明确给出圆柱出口Dirichlet Helmholtz、固定维数且参数解析的增广S、截断域二次泛函最小化，并称在阈值邻域（可含俘获本征值）一致指数趋近增广S，再恢复普通S。这已经否决“首次用增广矩阵使S跨阈值平滑”这一宽泛表述。俄文PDF已打开，但文字编码严重损坏，尚未完成定理假设逐项核读；不能据摘要断言其有限元误差或恢复普通S的条件数一致。英文DOI入口返回403，停止该路径，未绕过。

### R10 存在点谱时直接计算S也已有定理

**B. A. Plamenevskii, O. V. Sarafanov (2014), *On a Method for Computing Waveguide Scattering Matrices in the Presence of Point Spectrum***，Functional Analysis and Its Applications **48**(1),49–58，DOI [10.1007/s10688-014-0045-0](https://doi.org/10.1007/s10688-014-0045-0)。已核2011作者预印本 *A method for computing waveguide scattering matrices in the presence of discrete spectrum*，[arXiv:1106.5975v1原文](https://arxiv.org/html/1106.5975v1)。T：§§2.1–2.3、Theorem2.3。

其光滑圆柱端的系数指数趋近轴向不变系数，频窗不含阈值，却允许俘获模。用有限截断域Robin问题建立边界二次泛函；其唯一极小点对S行向量有频窗一致指数截断误差。全场只模俘获模唯一，S仍唯一。故“全场病态而只算S可稳定”“不必先排除全部俘获模”已有明确算法先例。这不是周期端定理，也没有给出随着复共振线宽趋零的材料族一致常数或全部有限元误差；这些差别才值得进一步核查。

### R11 可靠Helmholtz输出界至少须对照1999工作

**Josep Sarrate, Jaime Peraire, Anthony T. Patera (1999), *A posteriori finite element error bounds for non-linear outputs of the Helmholtz equation***，International Journal for Numerical Methods in Fluids **31**(1),17–36，DOI [10.1002/(SICI)1097-0363(19990915)31:1<17::AID-FLD953>3.0.CO;2-X](https://onlinelibrary.wiley.com/doi/abs/10.1002/%28SICI%291097-0363%2819990915%2931%3A1%3C17%3A%3AAID-FLD953%3E3.0.CO%3B2-X)。A：原出版摘要及作者LaCàN摘要索引，尚未核全文假设；首作者全名据UPC作者资料核为Josep。

摘要已声称用局部Neumann子问题构造非线性输出的常数无关上下界，并以二维外散射强度为例。因此“首次给散射功率可靠上界”不能成立为未经细分的选题口号。作者摘要入口请求超时；未重复读取或绕过，全文覆盖范围仍待核。另有Chen–Hesthaven–Maday–Rodríguez (2010), *Certified Reduced Basis Methods and Output Bounds for the Harmonic Maxwell’s Equations*, SIAM J. Sci. Comput.32(2),970–996，DOI [10.1137/09075250X](https://doi.org/10.1137/09075250X)，目前A，需核其truth模型与稳定常数条件。

**阶段判断。** 泛化A、B、C均不足立项；这不等于否定所有周期端散射数值研究。若保留A，须同时对照R1、R2、R9而非只对照普通PML；若保留B，须同时对照R5–R8、R10–R11，明确区分物理输出、人工表示峰和频窗完整性，不能只强调“近共振”。

## 6. 进一步收窄：采样、阻抗与辐射定义的三条硬边界

### R12 “certified Loewner”标题不意味着已有无条件停止保证

**Davide Pradovera (2023), *Toward a certified greedy Loewner framework with minimal sampling***，Advances in Computational Mathematics **49**，DOI [10.1007/s10444-023-10091-7](https://doi.org/10.1007/s10444-023-10091-7)，[原文v3](https://arxiv.org/html/2303.01015v3)。T：Propositions1–2及§§3–4。

对有限描述系统，重心分母倒数精确给状态残差的频率形状，故廉价贪心选点已有。输出误差另含不可由黑盒样本计算的因子 $\Delta$；其有界结论还要求状态极点在输出中不发生相消。§4的一点look-ahead、memory和batch规则是实用停止策略，原文明说可能低估最大误差；随机测试的概率保证也需要足够样本。故“自适应选点”“多次留出测试再停止”皆不新，且不等于全频窗最坏情形控制。

补充§2B的独立诊断：若采样在长 $L$ 的频窗均匀独立，宽 $2\gamma$ 的中心区被 $N$ 点全部漏掉的概率是 $(1-2\gamma/L)^N$。没有线宽或其它结构信息时，随机化也没有与 $\gamma$ 无关的有限样本保证。相反，若允许读取完整有限状态矩阵，则不能继续使用“黑盒有限采样不可能”否定所有算法；例如 **Stephen Boyd, Venkataramanan Balakrishnan, Pierre Kabamba (1989), *A Bisection Method for Computing the $H_\infty$-Norm of a Transfer Matrix and Related Problems***，Mathematics of Control, Signals, and Systems **2**(3),207–219，[作者入口](https://stanford.edu/~boyd/papers/bisection_hinfty.html)，已有Hamiltonian特征值与全频范数判定联系。当前A（作者摘要）；PDF请求超时，未重试。这类有限系统工具仍需另算PDE与端口近似误差，不能凭“不扫频”就认领创新。

### R13 用阻抗坐标避免DtN极点已有；合并后稳定仍须证明

**Thomas Beck, Yaiza Canzani, Jeremy L. Marzuola (2022), *Quantitative bounds on impedance-to-impedance operators with applications to fast direct solvers for PDEs***，Pure and Applied Analysis **4**(2),225–256，DOI [10.2140/paa.2022.4.225](https://doi.org/10.2140/paa.2022.4.225)，[2021作者稿v1](https://arxiv.org/html/2103.14700v1)。T：Assumption1、Theorems1.1–1.2及§5。

已有ItI（impedance-to-impedance，阻抗到阻抗）和合并逆 $(I-R_1R_2)^{-1}$ 的定量分析；模型为光滑正势、矩形及明确的非俘获条件。函数空间并非任取同一 $L^2$：Theorem1.1将 $I-R_1R_2$ 视为 $L^2\to\mathcal H_k^1$，§5展示 $I-R$ 在同一 $L^2$ 中一般不下有界。由此不应把矩阵范数良好误当连续端口尾项已经控制。

独立标量诊断：即使 $R_1,R_2$ 都酉，若 $R_1R_2=e^{i\theta}$，合并逆仍有 $|1-e^{i\theta}|^{-1}$。局部坐标稳定与全局共振敏感性不同。A若改用RtR/ItI，必须把“坐标极点被消去”与“全局匹配有可核稳定下界”分成两步；前者本身已有。

### R14 周期端口的出射定义必须先固定

**Thorsten Hohage, Sofiane Soussi (2013), *Riesz bases and Jordan form of the translation operator in semi-infinite periodic waveguides***，Journal de Mathématiques Pures et Appliquées **100**(1),113–135，[原文2012版v2](https://arxiv.org/html/1010.1738v2)。T：§2、Theorem2.2、AppendixA及B。其Riesz基/Jordan结构并非自动等于所有阈值处的物理LAP基：Theorem2.2相关空间须满足平移不变，迹基结论还需半导问题适定；AppendixA明确指出异号斜率交叉中正通量线性组合可能不是LAP模，并未确定零群速模的物理选择。不能以该结构定理直接跳过截止出射条件。

**Andreas Kirsch, Ben Schweizer (2025卷年；线上2024-08-28), *Periodic waveguides revisited: Radiation conditions, limiting absorption principles, and the space of bounded solutions***，Mathematical Methods in the Applied Sciences **48**(2),2267–2293，DOI [10.1002/mma.10435](https://doi.org/10.1002/mma.10435)，[开放正文](https://onlinelibrary.wiley.com/doi/full/10.1002/mma.10435)。T：Assumption3.5、Theorem4.4及§5。闭Dirichlet周期条带中，非退化通量形式仍可有异号；用不同正吸收权重选取的出射子空间在交叉处可不同。故算法须固定 $k+i\eta$ 或具体材料吸收，而非仅说“取任意小损耗”。这限制A的建模，不否定远离阈值的常规通量分类。

**Andreas Kirsch, Ruming Zhang (2025), *The PML-method for a scattering problem for a local perturbation of an open periodic waveguide***，Numerische Mathematik **157**,717–748，DOI [10.1007/s00211-025-01456-9](https://doi.org/10.1007/s00211-025-01456-9)，[开放正文](https://link.springer.com/article/10.1007/s00211-025-01456-9)。T：Assumptions3、7、10、Theorems12、14、16及DtN式(31)–(32)。开放半平面周期层、上方常介质；已给相应PML指数收敛。但其零通量排除、导模不与Rayleigh cutoff重合及同点通量同号等条件不能删去，也不是任意二维晶体弯角的完整外部解算子。

另须知道**Wood异常已有专门稳定表示**：Alex Barnett, Leslie Greengard (2011；线上2010), *A new integral representation for quasi-periodic scattering problems in two dimensions*, BIT Numerical Mathematics51,67–90，DOI [10.1007/s10543-010-0297-x](https://link.springer.com/article/10.1007/s10543-010-0297-x)（A）；Oscar P. Bruno, Bérangère Delourme (2014), *Rapidly convergent two-dimensional quasi-periodic Green function throughout the spectrum—including Wood anomalies*, J. Comput. Phys.262,262–290，DOI [10.1016/j.jcp.2013.12.047](https://www.sciencedirect.com/science/article/pii/S0021999113008553)（读算法摘要、引言及分节概述，非完整定理审查）。因此“平方根临界通道导致Green函数发散，故加有限秩修正”在更广散射文献中也不是新想法；真实周期Bloch带边是否不同须具体说明。

## 7. 对03:22可见主稿的第一轮判断

已读README与landscape（recommendation与候选细稿尚未出现）。M0全平面晶体弯角与M1有界横截面端口被正确区分；完整bulk gap、projected gap与无限外部连通区域的差异也写得准确。保留这三项边界非常重要，不能在最终摘要把M1算法称为原M0已完成的散射方法。

当前条件主候选是纵向不可分离周期端的驻波临界簇；它比泛化B/C有更清楚的计算对象，但尚未通过价值门。**须证明的差异不是“系数从常数改为周期”本身，而是既有增广S/慢模基无法直接提供的稳定构造、误差率或可计算常数。** 首个解析诊断至少包括：孤立普通二次带边、临界簇与其余Bloch谱的可核分离、固定吸收机制、端口图坐标及真正物理奇异的区分。若有限秩约化后与圆柱阈值公式完全相同，而剩余部分仅用既有Fredholm扰动，则应降为推广或淘汰，除非得到具体新的数值保证。

尚不推荐备选。B的场误差投影/deflation已有natural-norm强先例，主稿已经明确，因此不宜为保留第二项再把“连续误差闭合”本身当学术价值；C仅作输出层要求及诊断。此时没有新数值实验，也没有某既有算法在周期临界例上失败的证据。

访问状态补录：HAL `hal-02202233/file/paper_helmholtz.pdf` 返回Anubis Access Denied（code 9e4edb5b6b850c41），停止该路径；FJL2021出版商检索入口明确subscription/PDF Access Denied，未绕过，另独立公开的作者上传稿已定位，可用于后续核读。以上限制只影响相应全文证据，不阻断其余调研。

## 8. 主候选的新颖性重大更新：周期带边本身已有直接近邻

**需要主稿立即吸收。** 不应再以“增广散射只在常系数圆柱端存在，纵向不可分离周期端尚无临界簇构造”作为立项理由。已取得以下可读的原始英文全文，其模型本来就是一个圆柱臂连接一个真正周期臂，周期臂的横截面形状不要求可分离。

**Sergei A. Nazarov (2017), *The asymptotic behaviour of the scattering matrix in a neighbourhood of the endpoints of a spectral gap***，Sbornik: Mathematics **208**(1),103–156，DOI [10.1070/SM8624](https://doi.org/10.1070/SM8624)，[MathNet原始条目](https://www.mathnet.ru/eng/sm8624)，[公开英文PDF](https://www.mathnet.ru/php/getFT.phtml?jrnid=sm&option_lang=eng&paperid=8624&what=fullteng)。T：§§1–3模型/临界波，Theorems5–6及§§5.2–5.6；没有完整复核全篇证明。

最直接的覆盖是§5.3式(5.3)–(5.6)：对孤立普通二次Bloch带边，已有**跨带边连续的人工入/出波基**，再由代数运算恢复物理辐射条件。§5.4 Lemmas6–7给分离渐近项的加权空间框架。Theorem5式(4.26)–(4.27)已有通常情形下跨新旧通道的 $|\epsilon|^{1/4}$ 项，以及有almost-standing波时不同的 $|\epsilon|^{3/4}$ 行为；这里 $\epsilon=\lambda-\lambda_\dagger$，不是数值误差。§5.5式(5.15)把潜在奇异因子写为小块分母，式(5.19)/Theorem11分别控制非临界与临界系数。证明段§5为清楚起见假设阈值无trapped wave，不能删除此条件。

**对候选的具体影响。** “保留两波簇，人工条件平滑，再恢复真实S”以及“普通二次周期带边出现四分之一次幅度尺度”已经有非常接近的原型，甚至不需我们先做常系数到周期的概念推广。质量型分片材料与变截面Dirichlet几何有差别，但仅替换模型不能自动形成新的数值方法；也不能把现成渐近式中的 $\epsilon$ 换名为有限元cutoff误差后就宣布得到可计算误差界。

另外两条查证线索已确认，但目前仅A/M，不能代替已读定理：

- **Pekka Neittaanmäki, Boris A. Plamenevskii, Oleg V. Sarafanov (2012), *Radiation and scattering in domains with periodic waveguides under slow stabilization of characteristics of a medium***，Journal of Mathematical Sciences **184**(3),331起，DOI [10.1007/s10958-012-0871-7](https://doi.org/10.1007/s10958-012-0871-7)。摘要已包括一般自伴椭圆系统、轴向周期极限、S矩阵及计算方法；其完整有限域辅助问题适定性在2025后续引言中被说明并非当时全部证明。未核原文，不称完整阈值数值保证。
- **Sergei A. Nazarov (2020), *Threshold resonances and virtual levels in the spectrum of cylindrical and periodic waveguides***，Izvestiya: Mathematics **84**(6),1105–1160，DOI [10.1070/IM8928](https://doi.org/10.1070/IM8928)，[原始条目](https://www.mathnet.ru/eng/im8928)。一般二阶自伴系统、Dirichlet/Neumann及周期端阈值分类。英文PDF链接实际返回俄文条目，未拿到可读英文正文；不能声称核过其中定理。2017已读全文足以构成当前最强的新颖性挑战。

### 8.1 连续cutoff误差的第一反例：不要许诺错误的阶

以下是本次独立解析诊断，不是新研究结果，也没有执行数值实验。一个两通道界面模型中，入射侧纵向波数 $p>0$ 固定，临界侧 $q\ge0$，解的连续性给

$$r(q)=\frac{p-q}{p+q},\qquad t_F(q)=\frac{2\sqrt{pq}}{p+q},\qquad T(q)=|t_F(q)|^2=\frac{4pq}{(p+q)^2}.$$

$t_F$ 为通量归一化幅度。$q=0$ 时取阈值极限 $r=1,T=t_F=0$。若数值cutoff偏移 $\eta>0$ 使算法在同一频率使用 $\widehat q=\sqrt\eta$，则

$$|\widehat r-r|=\frac{2}{p}\eta^{1/2}+O(\eta),\qquad \widehat T=\frac4p\eta^{1/2}+O(\eta),\qquad |\widehat t_F-t_F|=\frac2{\sqrt p}\eta^{1/4}+O(\eta^{3/4}).$$

这个界面也可由均匀Dirichlet条带同一横向模、两侧不同正质量系数实现。它不是不可分离周期端的全部定理，却已经排除对一般阈值输出无条件承诺 $O(\eta)$；**功率与通量归一化幅度不能混同阶数。** 远离阈值，根误差还会含 $1/|q|$。若频率落在cutoff区间包络内，甚至不能只凭近似cutoff判断新通道是否打开。可靠算法应返回含阈值的输出包络/未分辨标签，并说明物理意义；这仍可能只是必要的误差传播，而非足够的学术贡献。

### 8.2 哪一项才可能使A超出常规适配

Halla–Nannen的常系数Hardy基不能逐字把 $e^{iqs}$ 替成 $e^{i\theta s}p(s,t)$：周期因子的Laplace变换有整列移位极点，原文可分离的横向正交展开及显式误差因子也不再相同。但采用胞边界/Floquet约化后，已有Jordan链与Nazarov连续人工波正好针对这个困难。因此“不能直接用Hardy公式”只证明需要另一套表示，不能证明它尚无人做。

若最终仍保留A，最低应提出一个超出这些连续构造的**具体数值差异**，例如在不预知精确带边/特征函数的情况下，同时从离散胞问题得到临界二维空间、cutoff位置和非临界尾项的可计算误差，证明由它们到指定物理S输出的闭合界，并展示较逐模/现有增广方法确实减少了随 $|q|\to0$ 的无效自由度或精度消耗。必须明确哪一个步骤用了新结构；只给未知常数的连续稳定性或既有表示加网格加密，应降级。此处仅列通过条件，尚未证明该组合足够新，也没有认定它可行。

## 9. 已取得2019俄文原文：不再只是摘要覆盖风险

针对新候选中“Nazarov2019全文403、尚未排除”的项目，独立找到了**MathNet公开俄文原文**：[原始条目](https://www.mathnet.ru/rus/mmo622)，[62页PDF](https://www.mathnet.ru/php/getFT.phtml?jrnid=mmo&option_lang=rus&paperid=622&what=fullt)。这不是对先前AMS拒绝的重试；未请求该受限入口，也未改变访问条件。俄文正文文本可读，已核§§1.1、2.4、3.2、4.5、6.3–6.4及7.1的公式/条件，未完整复核俄文证明。

**Sergei A. Nazarov (2019卷年／2020-04-01英文上线), *Finite-dimensional approximations to the Poincaré–Steklov operator for general elliptic boundary value problems in domains with cylindrical and periodic exits to infinity***，Transactions of the Moscow Mathematical Society **80**,1–51，DOI [10.1090/mosc/290](https://doi.org/10.1090/mosc/290)；俄文题名 *Конечномерные версии оператора Стеклова–Пуанкаре для общих эллиптических краевых задач в областях с цилиндрическими и периодическими выходами на бесконечность*，Труды ММО80(1),1–62。

**最强的可复核覆盖点：**

- 俄文p.3式(1.5)是 $Lu-\lambda R(x)u=f$，$R$ 可为正定光滑周期质量；取 $D=\nabla,A=I$ 即包含光滑正质量型标量模型。因而“几何Dirichlet而非质量型”已不能单独区分本候选。
- pp.21–22的§2.4第四种情形明确取**实Floquet根、几何单重、代数重数2**，式(2.33)用长度2 Jordan链构造正负通量组合；并非全文排除了驻波。
- 俄文Theorem6.1在 $C_\Xi,C_{\Pi^+},C_{\Pi^=}$ 下给截断域适定性；Theorem6.4对散射系数给 $c_\beta R^{3(c-1)}e^{-2\beta R}\|f\|$ 型误差。式(4.29)另要求极化矩阵可逆及其逆的多项式增长控制，不能略去。§7.1明确多周期臂可作相同构造。

**仍未覆盖的差别也必须保留。** 俄文p.3明确将实 $\lambda$ 固定，p.24说明常数依赖 $\lambda$；以上是已知精确Floquet波下的有限域截断结论，不是同时对网格 $h$ 和到带边距离 $\delta\to0$ 的可计算一致界。阈值波组合采用能量辐射条件，不能直接当作恰好阈值的有界物理LAP解。光滑系数假设也不能默许覆盖跳跃材料。它**显著压缩创新范围，但不证明“未知连续截止误差→指定常开输出”的全部数值问题已解决**。

对主稿当前版本的具体小修：示例 $\rho=1+\eta\cos(2\pi s/a)(1+\nu\cos(\pi t/W))$ 若要保证非可分离，还须 $\eta\nu\ne0$；仅写 $\nu\ne0$ 仍允许 $\eta=0$ 的常系数情形。候选中对简单带边、其它通道分离、非共振及未分辨输出的限制是恰当的，应保留。

## 10. 03:38前的第二条强先例：广义Bloch空间的有限元逼近亦已有

**Christian Engström (2014), *Spectral approximation of quadratic operator polynomials arising in photonic band structure calculations***，Numerische Mathematik **126**(3),413–440，DOI [10.1007/s00211-013-0568-y](https://doi.org/10.1007/s00211-013-0568-y)，[作者公开全文](https://www.researchgate.net/publication/257368235_Spectral_approximation_of_quadratic_operator_polynomials_arising_in_photonic_band_structure_calculations)。T：§§2.5、3及4的线性化、Theorem2和式(91)–(99)，未完整复核全部证明。

该文对周期质量型/散度型二次Bloch铅笔作适当线性化后，证明修正Galerkin算子范数收敛；式(91)–(94)处理整个广义特征空间，式(95)的根误差含上升阶 $\alpha$ 的 $1/\alpha$ 次幂。§3明确说实介电系数下只要特征值孤立也适用，不应仅凭其主要应用为损耗材料而排除。它的常数并非已经可计算，也不直接给周期条带物理S输出或未知截止区间的联合界。但“用轮廓谱空间而非分别追踪两根”“Jordan缺陷导致根精度降阶”“先线性化再用谱逼近理论”都不能再单列创新。

已读候选新增§5.1的自伴两通道点耦合诊断：在明确给定矩阵及其奇异值下界后，$O(\sqrt e)$ 反射误差由标准逆扰动立即成立。这个诊断方向正确，且应作为**淘汰门**保留；它并未证明真实二维周期端已解决。结合Nazarov2017连续人工基、Nazarov2019固定频率截断和本条广义空间逼近，当前剩余工作很可能是成熟构件的误差闭合。闭合本身可能技术很难，却尚未显示一个足以构成独立数值方法论文的新机制。

**给主汇总的建议：** 可以只推荐一次有明确上限的证伪预研，不能把它写成已经筛得一个新颖主方向。先列既有增广法在哪一步必须知道精确端口数据，再检查标准谱空间扰动加小块逆扰动是否足以补上。若足以补上，应退出独立选题；若不足，需指出一个可复核的失败原因和能改变误差率、计算复杂度或可计算性的具体新步骤。不要因本轮目标允许一个候选而抬高其推荐等级。

## 11. 对现有解析诊断的补核：常开反射的平方根损失可以是真实的

候选§5.1的两通道点耦合方程和逆扰动界经独立代数核对成立；这不是二维材料模型的验证。还可在同一模型取 $p=1$、$V_{11}=V_{22}=0$、$V_{12}=V_{21}=1$，得到

$$r_{11}(\kappa)=-\frac1{1+4\kappa},\qquad
M_0=\begin{pmatrix}2i&-1\\-1&0\end{pmatrix},\qquad
\sigma_{\min}(M_0)=\sqrt2-1>0.$$

所以即使临界匹配在阈值处有严格正的稳定下界，真实 $\kappa=0$ 与错移截止得到的 $\widehat\kappa=\sqrt e$ 仍有

$$|r_{11}(0)-r_{11}(\sqrt e)|=\frac{4\sqrt e}{1+4\sqrt e}.$$

这是常开通道输出的明确例子：平方根敏感性未必只是把不稳定模基用错，也未必源于临界共振。它支持“应控制截止误差”这一实际计算动机，却同时说明其最小误差传递可完全由旧式小块解析运算给出，**不支持据此宣称新方法**。若后续定理只有这一级传播，独立选题应止步。

另一个边界是：整体匹配逆下界是充分条件，不是每个输出的必要条件。例如令临界通道完全解耦且其零能常数模保留，整体临界块可能奇异，而第一通道反射仍独立且可准确计算。候选可选择在这种情形返回未分辨，但不应将这种失败描述成物理反射本身不存在或无法稳定定义。当前主稿未作这种错误推论；此处只是约束未来误差定理的解释。

## 12. 针对当前最小模型的更便宜证伪关：带边数据可从自伴胞问题开始

第一阶段已限定实正质量、直条带以及已知对称点 $q_*=0$ 或 $\pi/a$。此时不应默认先解一个高度病态的非自伴双根问题才能获得临界簇。令胞上

$$A(q)=\rho^{-1}\bigl[-(\partial_s+iq)^2-\partial_t^2\bigr]
\quad\text{作用于 }L^2_\rho,\qquad
\langle u,v\rangle_\rho=\int\rho\overline u v.$$

横向Neumann和轴向周期形式域固定。对实 $q$，它自伴；在光滑正质量的矩形胞内，算子域亦可固定。若 $A(q_*)\phi=\lambda_*\phi$ 是简单特征值，与其余胞谱距离至少 $g>0$，取 $\|\phi\|_\rho=1$ 及规范 $\langle\phi,\phi'\rangle_\rho=0$，普通解析扰动直接给

$$\begin{aligned}
A'(q_*)&=-2i\rho^{-1}(\partial_s+iq_*),\qquad A''(q_*)=2\rho^{-1},\\
(A(q_*)-\lambda_*)\phi'&=-A'(q_*)\phi,\qquad\phi'\perp_\rho\phi,\\
\mu''(q_*)&=\langle\phi,A''(q_*)\phi\rangle_\rho
+2\operatorname{Re}\langle\phi,A'(q_*)\phi'\rangle_\rho.
\end{aligned}$$

这里用了 $\mu'(q_*)=0$；对实系数简单胞分支，在这两个对称点可由时间反演与倒格矢周期性得到。约化逆在 $L^2_\rho$ 的范数不超过 $1/g$，故还有粗界

$$\|\phi'\|_\rho\le\frac{2}{g}\sqrt{\frac{\lambda_*}{\rho_-}}.$$

这只是核对过的胞内条件推导，无数值实验，亦非新的散射定理。它说明临界Jordan数据本可由自伴特征问题和一个正交补线性问题得到；与Nazarov2017 Lemma2的链构造相容。**上述 $L^2$ 界不能直接当端口Cauchy迹误差**：迹还需相应Sobolev残差/正则性控制，曲率非零与其余复杂Floquet根分离也须另证。

给后续预研的具体筛选次序是：先尝试这条已知自伴扰动路线，再接已有连续人工波基和标准小块扰动。若这已经提供所需端口数据，所谓“临界簇新求解器”应删除；若真正障碍只剩可计算迹常数和常规误差闭合，仍须说明为何值得独立论文。不能先选择最一般的非自伴铅笔表示，再把它的人为困难当作新方法价值。

## 13. 必须比较强基线，才能判断“避免选错通道数”的价值

当前recommendation的“不确定时仍给反射范围”有明确的使用意义，但还不能据此评为独立研究价值中高。应当把**计算用途的价值**与**足以立项的学术增量**拆开：后者目前未确立。特别是，错误通道数是某类逐模实现的危险，并非增广S方法不可避免的前置步骤；固定维辅助响应本来就不要求先把新旧物理S矩阵当成同一维数。

一个可证伪的成本比较可先写清楚。若已有增广表示与非共振条件给常开反射对临界根的局部Lipschitz界，而截止误差为 $\eta$，则平方根换元只需把它传成 $C\sqrt\eta$。为使这一项小于输出容差 $\varepsilon$，约需 $\eta\lesssim(\varepsilon/C)^2$；为了先确定新通道开闭，却需 $\eta<\delta=|\lambda-\lambda_*|$。在 $\delta\ll\varepsilon^2$ 时，强制分类可能浪费精度。但**成熟固定维增广基线也可能避免这笔开销**，因此不能只胜过“先选通道再求解”的弱基线来证明新方法有效。

这里是条件性的成本诊断，不是已证明的连续PDE复杂度结论；它没有给出可计算 $C$，亦没有证明所有几何都有所需非共振界。后续若要升级，应准确展示在同一信息预算下，新方法相对Nazarov型周期增广基线减少了什么成本或取得了什么原先没有的保证。若只补上已知构件的保守区间传播，按用户偏好应作为内部可靠性工作处理，而非把“未知截止”四字当作新方向的充分理由。

## 14. 一项淘汰证据的独立抽核与措辞校正

已独立读到 **S. Sen, K. Veroy, D. B. P. Huynh, S. Deparis, N. C. Nguyen, A. T. Patera (2006), *“Natural norm” a posteriori error estimators for reduced basis approximations***，Journal of Computational Physics **217**(1),37–62，DOI [10.1016/j.jcp.2006.02.012](https://doi.org/10.1016/j.jcp.2006.02.012)，[MIT作者公开PDF](https://www.mit.edu/~cuongng/publication/pub18/pub18.pdf)。T/P仅针对§2.1–2.2、Lemma6.2与Proposition6.3及其证明，未全面审整篇算法。

主稿L3的淘汰方向有实据，但“令原/对偶残差对最不稳定奇异向量正交”应改精确：式(27)与证明用的是**对偶残差**在锚点最危险模上的消去，不要求原残差也满足该条件。式(87)分母是锚点第二奇异值乘自然范数稳定下界；p.42明说这一乘积不应直接称为当前参数第二奇异值的严格下界。固定有限维truth空间、参数域正inf-sup假设及连续PDE误差未闭合的边界，主稿写得正确。以上细节不改变“不把近核伴随/deflation重新命名为新方法”的淘汰结论。

## 15. Zhang算法不是只给抽象DtN：已显式接入广义谱逼近

独立补读 **Ruming Zhang (2023), *A spectral decomposition method to approximate Dirichlet-to-Neumann maps in complicated waveguides***，SIAM Journal on Numerical Analysis **61**(3),1195–1217，DOI [10.1137/22M1485425](https://doi.org/10.1137/22M1485425)。实际核读的是题名缩为 *DtN maps* 的[2022作者稿v1](https://arxiv.org/pdf/2207.12690v1)，20页；T：Assumptions2、8、11、15、Theorem14及§5.3，不将期刊版本自动视为逐页核过。

其§5.3已直接引用Engström的式(94)–(96)，将上升阶引起的广义谱逼近误差纳入周期端DtN与中心有限元算法；式(38)同时列 $h$、胞谱离散及模态尾的误差。因此“把整簇谱逼近、端口尾、中心FEM首次放在一个误差分析中”也不是准确差别。Assumption2仍排除standing wave，Assumption8/11排除相应半导/全域本征态，全离散率另用实解析质量与光滑边界。这些是已证范围的边界，**没有证明该算法在近带边实际失效**。当前候选只能继续问联合临界极限和可计算性，不能把已整合的组成部分拆开后重新组合称新。

## 16. 横向域的逐项核对：这些覆盖不能越过M1/M0边界

本段回应父线程追加的模型审查。已重新查对应原文模型，而非根据标题中的“periodic waveguide”作判断。

| 已核先例 | 实际横向域和边界 | 对原全平面晶体线缺陷M0能说什么 |
| --- | --- | --- |
| Halla–Nannen2018，§2.1、§5 | $\mathbb R_+\times\Upsilon$，$\Upsilon$ 有界；齐次Neumann侧壁，轴向可分离的常系数模型 | 是近截止表示和误差分析的强机制基线；不是横向无限晶体线缺陷的散射定理 |
| Nazarov2017，§1、§2 | 周期quasicylinder的胞在横向有界，物理Dirichlet边界；与柱形出口连接 | 已有真正纵向不可分离周期端的临界波，但不是由无限晶体带隙横向约束的导模 |
| Nazarov2019，式1.1、§1.1、§7.1 | 有界周期胞的quasicylinder；一般局部自伴侧壁条件，多出口扩展仍属这一类 | 正质量模型覆盖是M1内部的直接覆盖；不提供M0的整个外部bulk出射算子 |
| Engström2014，§§2.1、2.4、3 | $H^1(\mathbb T^2)$ 上的双周期胞铅笔。§2.4固定界面平行的实Bloch分量、求垂直复分量，仍在周期胞上 | 这是bulk/界面Bloch谱及广义空间的数值先例，不是横向 $L^2(\mathbb R)$ 局域线缺陷导模，也不是其散射误差定理 |
| Zhang2023作者稿，§2及3 | 两条有限宽条带，Dirichlet侧壁为例；质量轴向周期、有限中心 | 最接近M1的全算法基线；没有把整个二维晶体外部处理掉 |

**对本轮结论的限制。** 不能因上述先例已覆盖临界簇机制，就宣称用户的原M0目标已被这些定理整体覆盖或只剩工程实现。相反，M0沿一条臂作轴向Floquet后，横向仍是无界问题；离散导模需与横向bulk本质谱隔离，复准动量延拓、迹与尾项不能直接沿用紧胞的紧预解式论证。完整bulk gap可消除传播体通道，却不使倏逝bulk场消失，也不使弯角外部自动分成两个独立有限端口。反过来，这些额外工作本身也不等于新数值机制，不能以“加一次横向截断”自动重新立项。

因此主稿把首模型退到有物理墙的M1，是**实质模型退让**：可用来检查阈值模块，不能自动服务原M0的反/透射计算。目前连这个较小模型中的新算法增量也未识别，所以不建议先开发M1再把未来可能移植到M0当成其价值背书。主稿最新开头“暂不独立立项、降为可靠性要求”与此相容；仍应将“问题价值中等偏高”改为“计算用途明确，独立学术价值尚未确立”。

## 17. 开线缺陷也有直接先例：不要反过来把横向无界本身当创新

为核清上段的边界，另读 **Sonia Fliss (2013), *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides***，SIAM Journal on Scientific Computing **35**(2),B438–B461，DOI [10.1137/12086697X](https://doi.org/10.1137/12086697X)，[作者稿v2](https://arxiv.org/pdf/1202.4928v2)。T：§2模型、Propositions3.1/3.3、Theorems4.1/4.5及4.12；未完整审其数值实现。

这里确实是横向无限的二维晶体线缺陷，正有界质量，沿缺陷取一个准周期胞。纤维算子在加权 $L^2$ 中自伴，本质谱由bulk决定；Theorem4.5把导模特征问题精确化为横向有限区域上的非线性DtN问题，半带Dirichlet谱例外见Theorem4.1。它研究直线导模，不是完整弯角散射，也未在本次阅读中给本候选要求的全部可计算临界误差。

相应的数学修正是：**没有紧预解式，不意味着孤立导模的局部谱投影理论失效。** 若目标导模在整个无界纤维谱中是有限重孤立谱点，且与其余离散谱及bulk本质谱有正距，标准局部解析扰动仍可使用。§12的思想因此并非必然只适于硬壁；真正要核的是隔离与相应范数/迹误差是否连续可计算。另一方面，导模靠近bulk谱边时该正距会消失，此时不能无条件声称横向截断仍一致。当前主候选限定的“轴向二次驻点”不应与这个横向失去约束的临界过程混同。

这没有新增推荐路线。它只是排除两种过头结论：既不能用硬壁文献直接宣布M0已解决，也不能用M0横向无限就宣布原有增广/谱投影思路不足且有新意。主稿当前没有足够证据跨过这两者之间的方法价值门。

## 18. 原开放弯角模型补核：实际数值框架早已有直接覆盖

父线程追加的M0核验已完成；下列是原始算法全文证据，不再用硬壁文献代替。它们已足以否决“尚无二维无限晶体中弯角/多臂散射框架”的宽泛动机；未读到端到端可靠误差定理不等于程序失效。

### O1 Hu–Lu2008：无限bulk与弯角为目标，但横向用零墙近似

**Zhen Hu, Ya Yan Lu (2008), *Efficient analysis of photonic crystal devices by Dirichlet-to-Neumann maps***，Optics Express **16**(22),17383–17399，DOI [10.1364/OE.16.017383](https://doi.org/10.1364/OE.16.017383)，[出版商提供的公开原文](https://www.researchgate.net/publication/23425710_Efficient_analysis_of_photonic_crystal_devices_by_Dirichlet-to-Neumann_maps)。T：§§1–4、§5弯角例；未复核全部数值例。

模型确实是无限二维周期晶体中有限器件连接半无限缺陷臂；E偏振对应本项目的正质量方程，不能把文中另一个 $\rho$ 符号直接当本项目质量。已有单胞DtN合并、Bloch模端口条件式(15)–(18)，并算90度和三角晶格弯角。§3式(6)–(11)的端口本身先横向截成supercell，两侧取零Dirichlet；远离缺陷的bulk边界也取零值。§5明确目标bulk/臂无限。因此这是**针对M0的实际数值方法，以有限横向近似实现**，不是物理硬壁目标，也不是完整M0精确消元的已证误差定理。不能把其“rigorous/nonlocal”用词扩成所有连续截断误差均已受控。

### O2 Pissoort等2005：直接用无限晶体Green函数消去bulk

**Davy Pissoort, Eric Michielssen, F. Olyslager, Daniël De Zutter (2005), *Fast Analysis of 2-D Electromagnetic Crystal Devices Using a Periodic Green Function Approach***，Journal of Lightwave Technology **23**(7),2294–2308，DOI [10.1109/JLT.2005.850029](https://doi.org/10.1109/JLT.2005.850029)，[作者公开全文](https://www.researchgate.net/publication/3243013_Fast_analysis_of_2-D_electromagnetic_crystal_devices_using_a_periodic_Green_function_approach)。T：§III的背景Green、端口及式(30)–(33)，§IV弯角/器件例；未全面核全部推导。

未知电流只放在被移除/改变的圆柱处，耦合核包含无限双周期背景；体隙内核衰减促成近稀疏系统。§III-C已计算无限缺陷臂Bloch模并构造多方向入/出端口；但其端口放置处假设仅单传播模足够，倏逝成分已可忽略，Green预计算也截成有限背景。因此“用bulk Green函数避免显式离散整个外部、只保留缺陷网络”已经是原M0的直接方法先例；不能据此称所有近截止、核尾项及模式误差的连续界均已证明。

### O3 2007推广已经不局限于移除圆柱

**Davy Pissoort, Eric Michielssen, Anthony Grbic (2007), *An Electromagnetic Crystal Green Function Multiple Scattering Technique for Arbitrary Polarizations, Lattices, and Defects***，Journal of Lightwave Technology **25**(2),571–583，DOI [10.1109/JLT.2006.889364](https://doi.org/10.1109/JLT.2006.889364)，[作者公开全文](https://www.researchgate.net/publication/3243893_An_Electromagnetic_Crystal_Green_Function_Multiple_Scattering_Technique_for_Arbitrary_Polarizations_Lattices_and_Defects)。T：§§I、III–IV及V-E弯角，非完整证明审查。

它允许方/三角晶格、两种偏振、非圆及改变材料的缺陷，以场等效电流和晶体Green核构造系统；有弯角、分支与长网络例。因此把“不同晶格/任意缺陷/只算局部散射块再拼接”当作新方法也不充分。原文的bulk Green预计算、远耦合截断和端口近似仍是算法信息预算的一部分；其数值成功不是所有这些近似的可靠上界证明。

### O4 去嵌入和补偿有限臂反射也非新方法

**Wojciech Śmigaj (2007), *Application of the multiple-scattering method to analysis of systems with semi-infinite photonic waveguides***，Journal of the Optical Society of America A **24**(10),3309–3316，DOI [10.1364/JOSAA.24.003309](https://doi.org/10.1364/JOSAA.24.003309)，[作者稿v1](https://arxiv.org/pdf/physics/0703165v1)。T：§§2–3及附录；卷页已据出版商索引及PubMed校正。

该文从有限晶体多重散射结果后处理中消去端部反射，包含两臂弯角；假定单模、适当镜像性质，以及拟合区倏逝项可忽略。它不等于完整出射算子的连续构造，但足以说明“换臂长、拟合Bloch比值、消除有限端反射”已有可操作基线，不能凭新近实现重命名。

### O5 Moreno–Erni–Hafner2002：实际横向泄漏与端口距离已有直接诊断

**Esteban Moreno, Daniel Erni, Christian Hafner (2002), *Modeling of discontinuities in photonic crystal waveguides with the multiple multipole method***，Physical Review E **66**,036618，DOI [10.1103/PhysRevE.66.036618](https://doi.org/10.1103/PhysRevE.66.036618)，[作者公开全文](https://www.researchgate.net/publication/11093070_Modeling_of_discontinuities_in_photonic_crystal_waveguides_with_the_multiple_multipole_method)。T：§§II–IV模型、模态匹配及§IV-B的横向/端口诊断；未核全部算例。

这不是只有FDTD端面伪反射的泛泛警告。该文先求无限直线缺陷的supercell模，再匹配中心MMP场；§IV-B具体展示低频例中导模进入晶体更深，增加两行晶体可降低横向泄漏，并说明端口要离结点足够远以减小倏逝项。因而端面匹配“无伪反射”不等于横向有限晶体误差也消失。这是原文特定算例的数值诊断，不是所有算法必然失效的定理；横向宽度、臂长与离散阶数必须分开看。

### O6 Oskooi等2008：周期材料中的伪PML确有已知连续反射机制

**Ardavan F. Oskooi, Lei Zhang, Yehuda Avniel, Steven G. Johnson (2008), *The failure of perfectly matched layers, and towards their redemption by adiabatic absorbers***，Optics Express **16**(15),11376–11392，DOI [10.1364/OE.16.011376](https://doi.org/10.1364/OE.16.011376)。T：出版商检索可见的原始全文§1、§6及其列出的模型/机制；未完整审CMT推导。直接全文跳转随后返回不可访问，停止该入口，不下载或重试。

其否定对象是把通常各向异性吸收层直接覆盖在未相应延拓的周期介质上：固定层厚下，即使网格趋细也仍可能反射，近带边低群速度使效果更差。原文同时给渐变吸收的已有补救，并指出模态边界条件的替代。因此“晶体中PML有问题”不是新发现，“改用渐变吸收/模态端口”也不能单独立项。此处不推论所有周期PML构造都不可能，更不把不同几何中的PML收敛定理判为错误。

## 19. 外部消元的另一条连续先例及其真实保证边界

**Julien Coatléven (2012), *Helmholtz equation in periodic media with a line defect***，Journal of Computational Physics **231**(4),1675–1704，DOI [10.1016/j.jcp.2011.10.022](https://doi.org/10.1016/j.jcp.2011.10.022)，[作者公开稿](https://www.researchgate.net/publication/220207190_Helmholtz_equation_in_periodic_media_with_a_line_defect)，题头2011-06-20。T：§2、§3 Theorem3.1、§5.3 Theorems5.5–5.6及无吸收讨论；未完整审证明。

模型横向无限，两侧可以是不同二维周期介质，但沿同一条直线缺陷共享轴向周期；在这一参考结构上作紧支扰动。已有**广义Lippmann–Schwinger＋轴向Floquet反演＋横向DtN**的有界计算归约。Theorem5.6给Floquet求积误差的指数率，依赖正吸收及解的指数衰减；全文明确假设吸收，不能当作无损实频率导波散射的统一界。它不直接包含两条非共线半无限臂，所以不能据此说弯角全覆盖；但“开放线缺陷首用LS和DtN消去外部”亦不是创新。

补核 **Christophe Besse, Julien Coatléven, Sonia Fliss, Ingrid Lacroix-Violet, Karim Ramdani (2013), *Transparent boundary conditions for locally perturbed infinite hexagonal periodic media***，Communications in Mathematical Sciences **11**(4),907–938，DOI [10.4310/CMS.2013.v11.n4.a2](https://doi.org/10.4310/CMS.2013.v11.n4.a2)，[作者稿v1](https://arxiv.org/pdf/1205.5345v1)。T：§1的(A1)–(A3)、§3.3、Theorem4.1和末节算法。无限六角周期介质、紧支局部缺陷、正耗散以及数据/几何的 $2\pi/3$ 对称；半空间DtN、DtD及Riccati因子化已有。**紧支缺陷不包含延伸至无穷的两条缺陷臂，旋转不变子空间也不是任意入射导模**；无耗散LAP明确未处理。这是整个bulk边界映射的机制先例，不能包装为本M0弯角定理。

最近邻检索另见 **Pierre Amenoagbadji, Sonia Fliss, Patrick Joly (2025), *Time-harmonic wave propagation in junctions of two periodic half-spaces***，Pure and Applied Analysis **7**(2),299–357，DOI [10.2140/paa.2025.7.299](https://doi.org/10.2140/paa.2025.7.299)，[作者机构元数据与摘要](https://researchportal.ip-paris.fr/en/publications/time-harmonic-wave-propagation-in-junctions-of-two-periodic-half-/)。此项仅A/M：不共周期的直界面可作高维周期提升，增广PDE退化椭圆。未核原文定理，不能据此判任意异质弯角已解决，也不能因摘要未列该词就宣布尚无人做。近期检索不是系统综述，零搜索结果不作开放性证据。

## 20. 原模型子阶段的结论与最有价值的边界

**原M0并未因先前模型退让而漏掉直接方法先例。** O1–O3已经实际针对无限二维晶体及有限弯角/网络；O4–O5已有端部去嵌入和横向泄漏处理，§19已有更一般连续外部归约。它们足以淘汰“先做开放晶体弯角FEM/BIE＋DtN/模态端口”“只保留缺陷未知量”“重用bulk核”“拆散射块后拼接”等宽泛方法陈述。反面也要明确：本轮没有核出一个对原几何、无损实频率、近所有截止、全部离散及截断参数同时给可计算常数的现成定理；这项未核出的保证本身仍不足以构成新数值机制。

真正的计算困难可精确落到以下已有机制之间的接口，但**本轮不将其拼装为新课题**：

- **消去bulk不等于选择导波出射。** gap内背景预解式的局部核衰减，而缺陷网络沿臂无界；有效无限线系统仍可支持不衰减的导模。不能因为Green核在单对胞之间衰减，就把整条臂删成有限矩阵，或在全局 $L^2$ 上使用预解式后声称已容纳入射导波。O2的模态端口正是另一个必要步骤。
- **两个不同临界距离。** 到bulk谱的距离控制横向约束/核衰减，到臂轴向带边的距离控制入/出根分离及群速度。两者可以独立退化；靠近轴向截止不自动意味着横向失去局域。统一误差必须说明保持哪个谱距，但这不是把两个旧估计相加就能认领新方法的理由。
- **信息预算不止网格。** 单胞离散阶、背景Green预计算区域、远耦合截断、横向supercell宽度、结点到端口的臂长、保留的倏逝模都可能改变输出。只提高一个离散阶的收敛并不排除其它固定误差；O5已有这种具体诊断。未给完整误差界不等于O1–O3算法不能正常计算。
- **参考介质要匹配。** O2–O3的单一背景晶体并不自动包含任意两个异质bulk构成的域墙网络；Coatléven允许两侧不同背景，但参考仍是同轴直缺陷。若原几何确属多背景扇区，需另核相应全外部匹配，不能把“任意缺陷”读成任意全局参考介质。这个边界也尚未显示独立新算法环节。

给主汇总的可用结论是：**仍是零项正式推荐；退回可靠性要求的决定有M0直接算法支撑，不只依赖硬壁近邻。** 不是宣布开放晶体散射已完全解决。若未来重开，应先给同一连续模型中的具体旧法瓶颈及超出上述强基线的操作，而非仅提出“全误差闭合”目标。

本子阶段访问状态：Hu2008出版商全文跳转不可用、Pissoort2005 DOI入口不可用、Śmigaj出版商robots拒绝以及O6直接全文跳转不可用均停止相应路径；分别利用已公开作者稿或可见的原始检索文本核查，不改变权限/网络、不绕过访问限制。未下载、未运行实验、未提交；此前文件与ref变化均未由本复核者修改。

**03:54 UTC子阶段交付检查。** `git diff --check`通过，HEAD仍为9cb8d8a，分支codex/dot；worktree为97,800KiB，低于1GB。本复核文件约64KB。此时主稿尚未冻结、未有本轮提交；不能当作最终提交验收。主汇总仍宜吸收§§18–20的M0直接先例，并修正§14所指Sen2006的“原/对偶残差都正交”表述及§16所指“问题价值中等偏高”含混评级；后两项不改变零项正式推荐的结论。后续04:25–04:33仅作只读验收，不再扩展选题。

## 21. 终稿验收准备：本review冻结，主稿尚有文字待同步

**03:55 UTC核读快照。** recommendation开头明确零项正式推荐、不设备选，末段明确只限制本轮三个入口，不否定整个散射方向；这一决定及其范围通过。候选已保留明确输出、M1/M0边界、重新开启所需的新机制、强基线比较及退出条件，没有承诺新的连续PDE定理，这部分通过。

但当时可见文件尚未真正落实两处已提修正：`landscape.md` L3仍写“原/对偶残差”正交且将第二奇异值表述得过直，须依§14限定为对偶残差锚点消去及对应分母；`recommendation.md`及候选末段仍写“问题价值中等偏高”，须区分明确的计算用途与尚未确立的独立学术增量。另有一个状态冲突：候选§5.1末句仍称“推荐仍停留在低成本证伪阶段”，应与总推荐同步为“仅保留验收标准；有新证据才重开”，避免暗示默认继续投入。README也仍标“尚未完成筛选”，应在主稿冻结时更新。

这些是明确可修的终稿一致性问题，不要求另开研究或推翻淘汰结果。§§18–20给出的M0直接算法应在主稿增加简要入口或链接，让最终负面判断不只列硬壁近邻。此后复核者不再修改本文件；待lead提交SHA，只读检查修正、提交范围、暂存区和资源状态。03:55检查暂存区为空，尚无本轮提交，不能预先宣称验收通过。
