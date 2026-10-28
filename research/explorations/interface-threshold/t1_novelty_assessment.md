# T1 的文献重合、研究价值与二维桥梁

日期：2026-10-28。第二轮定向重评；只新增本文件，不修改现有定理、计划、参考目录或实验。关联：[[research/explorations/interface-threshold/deep_investigation]]、[[research/explorations/interface-threshold/next_steps]]、[[research/explorations/interface-threshold/research_landscape]]。开放问题的项目级账目仍由 [[research/explorations/interface-threshold/STATUS]] 管理。

**主要判断：T1 可以保留为有明确输出的技术校验，但目前没有充分理由把它作为独立研究主线，或作为真正二维研究启动的总前置条件。** 一维的稳定 Bloch 支、Cauchy 匹配、阈值平方根坐标、共振条件、弱扰动二次能量律及节点坐标修补，都有强先例。没有核实到某篇文献恰好同时覆盖“任意左右异质正密度、有限中心材料、弱质量扰动”的全部细节；这只表示直接可引用的完整定理尚未落实，不能据此宣布新颖。

本文件不是新定理或独立证明审查的裁决。证据状态：`ESTABLISHED` 表示已核原文或项目正文；`CONDITIONAL` 表示依赖明确尚未建立的条件；`PROVISIONAL` 表示研究判断；`BLOCKED` 仅用于当前不能给出的结论。本轮没有运行数值实验。

## 1. 评估对象与依赖关系

当前 T1 是固定横向通道的连续加权问题

$$
-v''+q^2v=\mu\rho_\varepsilon(x)v,
\qquad \rho_\varepsilon=\rho_0+\varepsilon w,
\qquad w\geq0,
$$

其中左右端为正的分段周期密度，中心长度有限，$w$ 支撑在中心，研究一个非退化有限带隙边缘附近的局域谱。它在物理上属于二维分层 Helmholtz fiber，但数学上是单个标量 ODE。完整二维分层算子的结论还需排除其他 Fourier 通道；现有推论 5 已为其特定谱底例子做了这一步。**这仍不能检验横向通道耦合。** 此判断是 `ESTABLISHED`，来自现有模型的变量分离结构。

依赖图应写成

$$
\text{非退化周期端}
\longrightarrow \text{阈值支展开}
\longrightarrow \text{全接口共振与耦合系数}
\longrightarrow \text{分岔与计数}.
$$

在一维，中间步骤是有限维基本解和匹配行列式。在一般二维，必须增加“固定函数空间中的算子展开、无限维补空间估计、真实模态与边界核对应”。T1 并不自动提供这三个步骤。当前抽象定理 2、3 把最关键的阈值展开列为假设；证明它们的标量实例，不等于证明一般二维实例。

成功标准因此有两种，必须分开：一是补齐一个同型可核验例子；二是解决原二维问题中的一个尚未闭合环节。前者可以有教学和方法校准价值，但不能代替后者的研究价值。

## 2. 原始文献核验与覆盖边界

页号使用所链接 PDF 的页序；有正式排版页码时同时给出。下面“全文核验”指已检查所列命题及其前置设定，并非逐行审计整篇论文的全部证明。

### 2.1 Fassari–Klaus（1998）：比二次律更强的直接先例

Silvestro Fassari and Martin Klaus, *Coupling constant thresholds of perturbed periodic Hamiltonians*, Journal of Mathematical Physics 39(9), 4369–4416. [DOI](https://doi.org/10.1063/1.532516)，[机构公开全文](https://vtechworks.lib.vt.edu/bitstream/handle/10919/47036/1.532516.pdf?isAllowed=y&sequence=1)。`ESTABLISHED`，本轮全文核验。

§II 研究实周期势 $V\in L^1_{\mathrm{loc}}$ 与短程势扰动 $H_\lambda=-\partial_x^2+V+\lambda W$，包括非零临界耦合 $\lambda_0$。H1、H2、H3 分别要求 $W$ 的一阶矩、二阶矩、某个指数矩可积（正式 p.4372，PDF p.5）。**Theorem 2.12**（pp.4382–4383，PDF pp.15–16）在非空内部 gap 的阈值匹配条件下，按首个非零耦合系数区分局部分支和高阶退化；非零一阶项给二次能量位移。**Theorem 2.13**（p.4383）在 H3 下给相应平方根能量参数的收敛幂级数。**Theorem 2.14**（p.4387）处理原坐标在阈值有零点的情形；(2.78)–(2.81)（p.4386）已经把领先系数与阈值态重叠、尾部幅度、有效质量联系起来。

不直接覆盖：左右不同周期背景及谱参数乘密度的扰动；其临界中心缺陷和变化方向同属 $\lambda W$ 族，也不能直接替代任意固定中心加独立扰动方向。不能把它的二维章节直接用于本项目：该文高维背景可分离，且全空间局部扰动与固定 $\beta$ 的条带问题具有不同阈值维度。研究含义：**共振、二次律、较高阶幂次、节点修补或有效质量系数本身，均不足以形成 T1 的新颖性。**

### 2.2 Korotyaev（2005）：异质端及阈值分支已有明确理论

Evgeny Korotyaev, *Schrödinger Operator with a Junction of Two 1-Dimensional Periodic Potentials*, Asymptotic Analysis 45(1–2), 73–97. [DOI](https://doi.org/10.3233/ASY-2005-716)，[公开全文](https://arxiv.org/pdf/math/0507295)；本地 `TEP_ref/Korotyaev2005.pdf`。`ESTABLISHED`，全文核验。

**Theorem 2.1**（PDF pp.4–5）处理两周期势拼接的谱及续拓结构。**Theorem 2.4**（pp.6–7）研究 $p\in L^2$ 的位错族：带边附近用平方根变量描述本征值或非物理 sheet 的共振，给渐近；实解析 $p$ 时该变量解析。一般低正则条件下的余项不能擅自升级为任意阶 Taylor 展开。**Theorem 2.7(i)**（p.8）还研究常势端与周期端组成的 half-solid：周期带边严格低于常势阈值时，由显式匹配条件产生局部分支。这已包含“仅一侧临界，另一侧仍衰减”的先例。

不直接覆盖：任意有限中心增重、两独立周期密度及其统一参数估计。该文是势的位错扰动，不能直接当作质量扰动定理。研究含义：**左右异质、单侧临界和本征值/共振的符号区分也不是新的概念。** 本轮没有依赖 Theorem 2.7(ii) 的能量公式；其公开预印本中的符号需另核，不能转抄到本项目。

### 2.3 Dohnal–Plum–Reichel（2009）：接口谱匹配与唯一性的近邻结果

Tomáš Dohnal, Michael Plum and Wolfgang Reichel, *Localized Modes of the Linear Periodic Schrödinger Operator with a Nonlocal Perturbation*, SIAM Journal on Mathematical Analysis 41(5), 1967–1993. [DOI](https://doi.org/10.1137/080743366)，[作者机构全文](https://iana.math.kit.edu/downloads/iana2/Plum_Paper_PDF/localizedmodesreicheldohnalplum.pdf)。`ESTABLISHED`，全文核验所列结果。

§3.1 的左右势连续、偶、各自周期，周期不必相同。**Lemma 3.1**（PDF p.8）给 gap 内左右对数导数的单调性；**Lemma 3.2**（p.9）区分带边 Dirichlet/Neumann 型的极限；**Theorem 3.4**（p.10）在相应 gap 类型条件下给接口本征值存在与唯一性。位错部分 **Lemma 3.8**（p.15）显式处理对数导数的极点。

不直接覆盖：任意非对称中心、谱权重扰动的阈值渐近。偶对称性保证某些 ratio 在开 gap 内无极点，不能删掉后仍照搬连续单调论证。研究含义：重新证明“稳定 Bloch 波拼接 + 对数导数单调 + 节点换图”通常只是适配工作。

### 2.4 Duchêne–Vukićević–Weinstein（2015）：弱周期缺陷的定量有效模型

Vincent Duchêne, Iva Vukićević and Michael I. Weinstein, *Homogenized Description of Defect Modes in Periodic Structures with Localized Defects*, Communications in Mathematical Sciences 13(3), 777–823. [DOI](https://doi.org/10.4310/CMS.2015.v13.n3.a9)，[作者全文](https://duchene.pages.math.cnrs.fr/publication/duchenevukicevicweinstein15/DucheneVukicevicWeinstein15.pdf)；本地 `TEP_ref/Duchene2015.pdf`。`ESTABLISHED`。

**Theorem 3.4**（正式 p.787，PDF p.11）：同一连续周期势 $Q$、有界且具有可积一阶矩的局部势 $V$，选取非零曲率带边并要求曲率与 Bloch 加权扰动积分异号，得到 gap 分岔、二次能量主项、包络及所述邻域内唯一性；能量余项为 $O(\lambda^{2+1/4})$。**Corollary 3.6**（p.788）在更强矩条件下给更高阶展开。不能把该唯一性改写为整个 gap 只有一个本征值。

不直接覆盖：预先存在的异质接口共振和质量型非线性谱依赖。研究含义：只写出标量有效 $\delta$ 模型或二次系数，不能超越此类已有定量结果。

### 2.5 Craster–Davies（2023）：正密度 Helmholtz 不是空白模型

Richard V. Craster and Bryn Davies, *Asymptotic Characterization of Localized Defect Modes: Su–Schrieffer–Heeger and Related Models*, Multiscale Modeling & Simulation. [DOI](https://doi.org/10.1137/22M1511217)，[全文 arXiv:2202.07324v2](https://arxiv.org/pdf/2202.07324)。`ESTABLISHED`，本轮从摘要核验推进到相关全文核验。

§2.1 的正波速 Helmholtz 方程正是 $q=0$、$\rho=c^{-2}$ 的正权重形式。**Theorem 2.4**（PDF p.5）给有限材料缺陷的传递矩阵匹配条件；**Corollary 2.5**（p.6）给衰减率。§3.1（p.16）要求两端周期、单胞反射对称且等谱；**Theorem 3.1**（p.17）给接口匹配。**Theorems 2.7、3.5**（pp.8、18–19）是所述均匀化 ansatz 下的包络描述；后者还依赖特定 SSH 结构。不能把它们当作任意异质端的算子范数余项定理。

不直接覆盖：不等谱且无对称性的两端、独立中心弱增重、完整根计数的一致阈值定理。研究含义：增加 $q^2$、改写为 $\rho$ 或使用精确分层传递矩阵，均不足以单独支撑新颖性。

### 2.6 Nazarov（2017、2020）：波导先例必须留在评估中心

Sergei A. Nazarov, *Threshold Resonances and Virtual Levels in the Spectrum of Cylindrical and Periodic Waveguides*, Izvestiya: Mathematics 84(6) (2020), 1105–1160. [DOI](https://doi.org/10.1070/IM8928)，[MathNet 全文](https://www.mathnet.ru/php/getFT.phtml?jrnid=im&paperid=8928&what=fullteng)。`ESTABLISHED`，相关全文已核。

**Proposition 4.1**（正式 p.1134，PDF p.30）在周期端 pencil 的几何单重根、唯一不可延长 Jordan 链条件下给分裂及余项；平方根是链长为二的情形。§5.1–5.2、**Lemma 5.1**（pp.1140–1143）采用一个圆柱端的 Dirichlet Laplacian、唯一有界阈值态、无阈下离散谱的简化设定，施加光滑局部吸引势且阈值态加权积分为正，区分非 $L^2$ 共振的二次位移和阈值 $L^2$ 态的线性位移。该节将渐近证明来源指向既有文献；(5.6) 是二次公式，Lemma 5.1(1) 指向 (5.7) 的编号与后续推导不一致，引用时不能照搬。

边界：一般理论包含周期波导，但不能把上述圆柱端例子的每个结论直接宣布为“两个异质材料端、准周期横向条件、分片正密度”的现成定理。它已经足以排除“把阈值共振机制搬到波导就是新贡献”的说法。

另一篇 *Almost Standing Waves in a Periodic Waveguide with a Resonator and Near-Threshold Eigenvalues*, St. Petersburg Mathematical Journal 28(3) (2017), 377–410，[DOI](https://doi.org/10.1090/spmj/1455)，[原始书目与摘要](https://www.mathnet.ru/php/archive.phtml?jrnid=aa&option_lang=eng&paperid=1496&wshow=paper)，仅完成元数据和摘要核验，**没有核得全文定理**。俄文原刊为 2016，英文出版为 2017。其周期 Dirichlet 几何与近阈值特征值内容构成重要待核近邻，不能把获取失败当作差异证据。

## 3. 已覆盖、不直接覆盖、仍未知

| 拟议内容 | 当前证据判断 | 对研究安排的含义 |
|---|---|---|
| 单胞 monodromy、稳定支与匹配条件 | 已覆盖；参见 2.2、2.3、2.5 | 用作基础工具，不单独立题 |
| 非退化带边的平方根变量 | 已覆盖；参见 2.1、2.2、2.6 | 要核条件，不能宣传坐标本身 |
| 共振加非零重叠产生二次位移 | 已覆盖其核心机制；参见 2.1、2.4、2.6 | T1 的二次律只是适配成果，除非新增实质条件或统一性 |
| 对数导数极点、切口零迹的标量修补 | 已覆盖；参见 2.1、2.3 | 仍应做正确，但不是独立创新 |
| 左右不同周期、仅一侧临界 | 已有直接势模型先例；参见 2.2、2.3 | 不能据“异质”二字立新颖性 |
| 任意异质正密度 + 有限中心 + 弱增重的完整 T1 | 上述定理不直接共同覆盖；本轮未完成对一般 Sturm–Liouville 文献的穷尽核查 | `PROVISIONAL`：可有完整适配定理，但独立价值尚不足 |
| 非可分离二维、内部 projected gap、材料传输的范数展开与系数识别 | 本项目未证明；本轮不能确认已有完整覆盖定理 | `CONDITIONAL`：是真正研究目标，须查 Nazarov 及相关椭圆 pencil 理论的可迁移部分 |
| 带边失配与弱缺陷同时趋零的一致临界律 | 单参数结果不直接给一致性；尚未完成专项查重 | `PROVISIONAL`：可能有价值，不是已确认新颖 |

正密度形式与普通势问题之间也不能任意划等号。对足够光滑、严格正的密度，可以作 Liouville 变换；分片常数则留下相应传输条件，密度随参数变化还改变变换和相位。因此本轮没有把势模型定理直接当作 T1 的证明。但“需要适配”与“适配值得形成独立研究”是不同判断：目前证据支持前者，尚未支持后者。

## 4. T1 应保留的有限任务，以及不应继续重复的工作

建议把 T1 限制为以下三个输出，状态 `PROVISIONAL`：

1. 在一个已有非退化有限 gap 的正密度例子上，明确全接口共振条件；写出与共振态归一化、切口位置无关的领先系数，并与普通势模型系数逐项对照。
2. 将“带边匹配”与“全接口共振”分开，指出哪一个中心调节参数能横截地改变共振条件；若仅能数值调参，则不把该构造称为已证存在。
3. 输出供二维证明直接使用的符号、通量及质量耦合恒等式，明确每一步在无限维迹空间中所需的估计。凡只能依赖 $2\times2$ 矩阵行列式的步骤，标出其二维替代物。

若三个输出没有改变二维的一个明确证明缺口，T1 就应到此结束。以下任务不值得为“新方向”另开长周期：重复 Floquet band/gap 分类；再证一个普通二次律；反复换分层参数增加例子；把节点换图包装成新方法；只因模型可解析，就先做完整一维工程，再决定是否碰二维。

这不是否定已有推论 5：它验证连续 PDE、正密度与非 $L^2$ 共振机制兼容。其正确定位是完整可分离例子，不是一般二维进展的替代品。

## 5. 更可能有独立价值的两个出口

### 5.1 直接针对非可分离二维的一个有限目标

建议保留固定 $\beta$ 的真实二维条带，左右端周期密度至少有非平凡横向依赖；只研究一个简单临界 Bloch 分支，另一端位于 gap 内部，排除阈值 $L^2$ 态。研究目标不是重证二次律，而是建立以下任一具体桥梁：

- 在同一个局部 Hilbert 空间中证明截断 resolvent 的有限秩奇异项和一致有界余项，并证明其秩、像恰好由全接口非 $L^2$ 共振空间决定；或
- 在固定迹空间中构造无切口坐标伪极点的边界对象，证明阈值参数下的范数展开、补空间一致可逆性及质量耦合矩阵公式。

只有这些条件建立后，现有抽象定理才真正转化为二维连续模态陈述。单胞 Bloch 根的平方根展开不是全接口 resolvent 展开的替代：中心可能改变共振，其他通道和阈值本征态可能改变奇异结构。**最小理论入口应直接包含横向依赖或通道耦合；“二维几何中恰好可分离”不满足这个验收条件。**

此目标为 `CONDITIONAL`。在投入长证明前，应先将 Nazarov 的固定加权空间、Floquet pencil 和辐射解理论逐项映射到正密度传输型 fiber；若既有定理经短适配即可给出全部目标，则调整为应用或算法问题，不能继续宣称新定理机制。

### 5.2 双参数失配：关键是一致性和额外接口失谐

设两侧相关带边之差为 $\Delta$，弱缺陷强度为 $\varepsilon$。已知单侧固定失配与精确等边的结果，通常不能直接给出 $\Delta=O(\varepsilon^2)$ 的一致过渡。可能值得研究的是：在实际周期介质中，统一证明临界缺陷强度、模态消失边界、局域长度及余项，且允许两个端的曲率不同。

必须加入反证检查：**$\Delta$ 并不决定接口共振失谐。** 即使两端边缘相同，中心连接也可产生非零零阶匹配项。概念上，归一化后的局部标量匹配可能包含

$$
s+ a_-\sqrt{\mu_--\mu}
  +a_+\sqrt{\mu_+-\mu}
  -\varepsilon b+\text{余项}=0,
$$

这里仅表示两个上方谱边缘下侧共同 gap 的一种候选结构；$s$ 是接口匹配失谐，不能从 $\Delta=\mu_+-\mu_-$ 推出。此式为 **未经证明的候选正规形**，不是所有异质接口的统一公式。要使平方根项与弱缺陷同阶，除 $\Delta=O(\varepsilon^2)$ 外，还须控制 $s=O(\varepsilon)$；否则预期的弱缺陷分岔可以完全消失。

独立价值应来自在根碰到阈值时仍有效的一致误差与分岔分类，不能只在远离碰撞的参数点应用隐函数定理，也不能只解已有的阶跃 $\delta$ 模型。最小理论检查可先在周期 ODE 中完成，但若最终目标仍是原问题，应预先规定其二维迁移所需的范数估计。这一方向的存在价值为 `PROVISIONAL`，优先权为 `BLOCKED`：尚无充分文献证据支持“首次”。

## 6. 决策、反证门与审查不足

建设性建议是 **REVISE T1 的范围，GO 二维桥梁的定向可行性核查**。修订理由是任务与目标错位：原计划把完整一维推进放在决定一般二维投入之前，而目前已知先例使这种前置安排缺少足够回报依据。这是有限范围的研究组织建议，不是对现有证明正确性的否定，也不是禁止小模型。

| 待检验主张 | 最小否证门 | 失败后的最小降级 | 严重性 |
|---|---|---|---|
| C1：T1 可形成独立新定理方向 | 找到一般加权 Sturm–Liouville 或经明确变换覆盖其全部假设的现成定理 | 保留为技术适配附录/校验 | important caveat |
| C2：T1 对二维有实际帮助 | 每个 T1 输出须对应一个二维缺口；若只有有限矩阵代数则不成立 | 截止 T1，直接研究二维算子步骤 | important caveat |
| C3：二维新目标仍有实质空间 | 核 Nazarov2017 全文及2020一般框架，检查是否只需常规换权重 | 改为应用、算法或更窄的传输适配问题 | important caveat |
| C4：失配双参数给统一弱缺陷律 | 检查 $s$ 未受控时是否仍有分支；核参数碰撞点余项 | 增加接口调谐参数/条件，或仅保留局部非一致结果 | important caveat |

本轮不足如下，均不妨碍给出上述保守建议，但阻止确认研究优先权：Nazarov2017 全文未获取；未穷尽经典 Sturm–Liouville、加权 Weyl 函数及多参数阈值散射文献；没有证明分片密度到已有势模型的完整等价；未审计列举论文全部证明；没有做数值实验或构造新的非可分离二维例子。**Preliminary review; literature verification is incomplete.**

本轮新增的 Dohnal–Plum–Reichel2009 与 Fassari–Klaus1998 通过机构公开全文只读核验，没有下载文件或改参考索引。本文件只记录其核验入口；如后续正式引用，应在获授权的书目维护中加入规范条目。
