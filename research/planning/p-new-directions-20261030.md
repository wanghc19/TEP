<!-- p = plan（研究规划）；本文件不是定理或完成的证明。 -->
# 周期波导的新问题筛选：2026-10-30

工作窗口14:49–15:49 UTC；本地起点 `96e93c0`，分支 `codex/dot`，初始工作区干净。只新增本规划及独立审查记录，不修改上午证书、旧算法或用户规则。写入预算150KB，初测保守存储96,067,584 bytes／1GB；不启动 MATLAB，不安装依赖，不访问私有远端。

**最终排序：A主方向，B第二主方向（有前置淘汰门槛），C高风险备选。** 第一版于15:11落盘，现已吸收独立复核§7–8。三项均是值得检验的研究问题，**不是已经确认开放的问题**。本轮的实质产出是排除已有覆盖，并把可能有价值的差异收窄到可失败、可证伪的具体门槛。

| 排序 | 问题 | 独立价值 | 启动条件／最先应得到的结果 |
|---|---|---|---|
| A：优先 | 真正不同二维周期远场下，间隙内导模分支能否完全平坦？ | 从单点模态存在转向传播与局域化的结构，动力学是后续而非先行承诺 | 审计同背景无点谱证明；明确两端复 Bloch 延拓的共同 Fredholm 连通域，或找到反例／已有覆盖 |
| B：次优先、条件性 | 两个二次 projected minima 合并时，弱缺陷全部模态数怎样统一转变？ | 研究带边几何改变与多尺度计数，不依赖旧候选场 | 先在正标量质量模型中实现四次边；否则退出，不先做大规模参数扫描 |
| C：备选 | 内部阈值的几乎驻波，能否靠指定有限材料族和参数锥变成真导模？ | 区分束缚态与泄漏共振，给受限扰动的可实现性／障碍 | 一个临界通道加一个传播通道的辐射消去秩检验；需先建立可控阈值态 |

不建议三线同时投入。先给A一个短的证明桥梁审计窗口；B只做机制可实现性检查；C暂存，除非A/B被已有定理或反例淘汰。完整分支图由暂定备选降为不启动：目前没有足够证据说明它会超过现有证书的工程拼接。

## 1. 目标、证据和已有起点

目标是选出有独立学术价值的问题，不把单个候选的精度改善、给旧定理换几何或普通参数扫描当新方向。上午 [[research/explorations/spectral-counting/r-gap-fourier]] 已证明：当前模型在固定 $\beta=1/2$、$\mu=k^2\in(2.40,2.46)$ 恰一简单纤维导模；这提供真实算例和连续谱计数工具，**没有给整个色散分支的结构、阈值出生机制或动力学输运定理**。

本文件局部记号：$x$ 为横向无界坐标，$y$ 为周期方向；$A=-\rho^{-1}\Delta$ 在 $L^2(\mathbb R^2,\rho)$ 中由 $\int|\nabla u|^2$ 定义。$\rho$ 实正有界、$y$ 周期1，在 $x\to\pm\infty$ 分别等于两个真正二维周期密度 $\rho_\pm$。$A(\beta)$ 是 $\mathbb R\times\mathbb T$ 上的纤维算子；$\mu_j(\beta)$ 为孤立导模本征值。不同论文的势型、质量型、散度型、维数、同背景／异质背景及演化方程必须逐项区分。

证据层级：**T**=在线读到原文定理陈述和所需假设；**P**=另读相关证明段；**A**=仅作者摘要；**M**=仅出版／arXiv元数据。T不意味着整篇证明已独立审定。本轮使用公开原文和稳定链接，不强制下载全文；新颖性判断限已检索范围，检索未命中不等于开放问题。

## 2. 第一优先候选A：异质周期两端的导模非平坦性

**精确问法（研究目标，未证明）。** 对上述 $\rho_-$ 与 $\rho_+$ 不必相同的质量型算子，给定准动量区间 $I$ 和共同 projected gap，并假设一个有限导模簇在 $I$ 内与两端本质谱保持正距离，能否排除其中的恒定分支？进一步，对支撑在该导模簇的适当光滑波包，在正频波演化 $e^{-it\sqrt A}$ 下建立横向位置除以时间趋零、纵向位置除以时间趋于非零速度算子的强极限？先限定简单、统一隔离分支，绝不一开始声称处理所有嵌入态和带边。

**价值。** 从“存在一个纤维模态”推进到“这个模态是否真正沿波导传播”；不平坦性及实际输运比绘制若干带曲线更有独立意义。只证明已有隔离本征值的局部解析性或 Hellmann–Feynman 公式不算本方向的研究贡献。

**直接近邻。** Hoang–Radosz [L1] 已排除同一全周期背景加有限宽线缺陷的全平面点谱，允许有界跳变正密度；不能再把该结论列为新问题。Black等 [L2] 的2026论文已给横向紧支撑势的定向弹道输运和非恒定能量分支；其主定理写明 $n\ge2,m\ge1$、自由外部、Schrödinger演化，不能直接引用为本二维质量型异质晶体的结论。

**可能新增什么。** 若两种不同晶体背景确实要求新的复准动量拼接与分支控制，则目标是它们共同 gap 内的非平坦性及波动输运；不是把“密度”改称“势”制造区别。固定能量下 $(-\Delta-\mu\rho)u=0$ 本来可看作势型方程，单这一改写不构成新颖性。

**关键难点。** 两侧不同 Bloch 曲面的解析延拓、阈值及半条带极点；全局 $A(\beta)$ 在非紧柱面上并非处处 Fredholm。实轴 gap 内的解析性不自动给连接至大虚准动量的路径。还要将谱分支控制转为 $e^{-it\sqrt A}$ 的波包域与位置算子极限。

**原文审计已定位的实质门。** [L1] Proposition 3–4把扰动写成相对同一背景的横向紧支撑乘子，压到有限胞元；异质情形相对任一背景的差在另一半空间均不紧支撑，这个约化失效。分别延拓两套背景并取异常点并集，本身很可能只是有限次重复，不能当新方法。切分拼接后出现 $[-\Delta,\chi]u=-2\chi'\partial_xu-\chi''u$；原文局部预解式的 $L^2$ 小范数不自动使此一阶交换子项变小。真正需要的是**所选两端延拓支上的匹配 Fredholm 对象能通到可逆点**。原始条带算子的大虚参数可逆，不自动保证绕过分支点后的对象仍在该物理解支。若现成参数子估计即可例行补齐，A应降级。

**输运只列标准后果。** 对统一隔离的正简单分支、加权归一 $\int\rho|\phi_\beta|^2=1$，预期速度是 $v(\beta)=\mu'(\beta)/(2\sqrt{\mu(\beta)})$；Hellmann–Feynman右端动量积分不额外乘 $\rho$。紧子区间光滑波包在Bloch表示下微分相位可给速度强极限，仍须列清位置矩条件。这不是第二个独立创新。非平坦允许离散驻点；相反速度波包的有符号平均可以为零，不能宣称每个非零波包的平均位移都非零，更不能称单向／手性输运。

**第一步／反例测试。** 精确定位 [L1] 证明中“同一背景”的使用点；在两个不同可分离周期端上检验拼接是否已经由已有定理直接给出非平坦性，再决定是否推进真正二维耦合端。可先建立统一 gap 内的解析有限秩投影和质量型速度表达式，但明确这只是标准准备工作。实标量互易性给分支集合的 $\beta\leftrightarrow-\beta$ 对称，故不能猜想全区间速度同号或无驻点。

**现有切入点。** 精确 DtN／Cauchy 数据及 [[research/explorations/spectral-counting/s-gap-fourier|F6]] 的两端 parametrix；F6只处理实共同gap附近的本质谱排除，不提供本问题所需复参数连通性。上午的一点简单性只提供局部可追踪起点，不是全分支证据。

**止损。** 若原文追踪发现同类异质二维周期端已被现有无点谱／输运定理直接涵盖，降为应用而退出主方向；若只能证明局部解析性或数值速度非零，不宣称完成本目标。若两周预研仍无法明确一个可控的复准动量域，收窄到有结构的材料族或转备选，不先承诺一般定理。

## 3. 第二主方向B：合并带边的统一弱缺陷计数

**精确问法（条件性研究目标）。** 固定轴向 $\beta$，调节周期背景参数 $a$。设一个孤立 Bloch 分支在横向准动量 $q=0$ 附近有

$$
E(q;a)=E_0(a)+a q^2+bq^4+O(q^6+|a|q^4),\qquad b>0.
$$

这里偶对称需由明确的反射结构或其他假设保证，不能只凭实系数在任意固定 $\beta$ 下假定。还须保证其余 Bloch 分支及其他准动量不碰目标边。向质量系数加入沿轴向周期、横向紧支撑的 $\varepsilon W$，首轮取非负、非平凡 $W$。问在 $(a,\varepsilon)\to(0,0)$ 的联合极限中，从此边产生的**全部**导模数、重数和能隙尺度如何统一描述？$a<0$ 时实际最低边移至两个非零极小点，真实边缘一般为 $E_0(a)-a^2/(4b)+O(|a|^3)$；必须围绕**精确背景带边**计数，不能用四次正规形的近似边值吸收较弱模态的能隙。

**价值与新增门槛。** 固定 $a>0$、$a=0$、$a<0$ 分别求一个弱模态，是已有弱耦合理论的应用。值得追求的是两个极小点合并时计数与近似是否一致，尤其首层有效模型未显出的更弱模态如何转移。Brown等 [L4] 的精确多模态计数要求二次下界，在曲率消失处失效；Arazy–Zelenko [L5] 已研究高阶算子的多尺度虚特征值，所以“四次边”“多个弱模态”及 $\varepsilon^{4/3}$ 本身均不是创新。

**与仓库旧问题的区别。** [[research/explorations/interface-threshold/candidate_problems]] Q3已把曲率退化列为问题，[[research/explorations/interface-threshold/rigorous_2d_bridge]]已处理一个临界二次端的条件性桥梁。B不能把“首次想到四次边”作为进步；仅保留跨曲率变号、包含全部弱尺度的**联合参数完整计数**。若只是补完旧H1–H4，也不符合本轮策略。

**第一步／反例测试。** 先构造本项目正、有界、标量质量密度的一族真实二维周期材料，使上述退化及其它谱隔离成立，或者证明选定对称族不可能出现它。已有耦合模／多模光纤中的四次色散 [L16] 不是该连续模型的可实现性证明。随后用 $D^4+aD^2-\varepsilon W$ 检查跨尺度计数；若形式有效模型已否定拟议的统一说法，应先修改问题。

**仅作尺度推测。** 对非零首阶有效耦合，若主束缚长度为 $\ell$，平衡 $\ell^{-4}$ 与 $\varepsilon\ell^{-1}$ 提示 $\ell\asymp\varepsilon^{-1/3}$、主能隙 $\varepsilon^{4/3}$，而 $a\ell^{-2}$ 同量级时 $a\asymp\varepsilon^{2/3}$。这不是已证渐近，更不控制全部弱模态；后者可能有另外尺度。尚未验证从质量型胞问题约化至该模型的误差。

**15:18复核后的关键修正：至少要考虑第二尺度。** 已核到 [L5] 原文：一维 $D^4-\varepsilon W$ 在其非负连续、充分衰减条件下，恰有两条趋零的弱模态；第二条能隙为 $\varepsilon^4$ 阶。这是已有结果，不是本轮发现。独立复核与阈值分工分别检查自由Green核，均发现去掉常数主方向后还留一个正的奇异方向；对 $D^4+aD^2$、$a>0$，其强度约为 $\varepsilon/\sqrt a$，提示第二模态转变层是 $a\asymp\varepsilon^2$。

为把猜想变成可反驳对象，**仅在归一化玩具模型** $D=-\mathrm i\partial_x$、$b=1$、$W\in C_c$ 非负非零时，记 $\bar x=\int xW/\int W$、$M=\int(x-\bar x)^2W$。待复核的工作假说为第二模态的正曲率临界值 $a_c(\varepsilon)\sim M^2\varepsilon^2/4$。令 $Q$ 投影到 $\sqrt W$ 的正交补，$G_a$ 表示两侧乘 $\sqrt W$ 后的零能正则Green算子；其线索是 $QG_aQ\sim |(x-\bar x)\sqrt W\rangle\langle(x-\bar x)\sqrt W|/(2\sqrt a)$。本轮没有证明该阈值公式或全参数计数，也没有把它转移到周期PDE；它用于检验“一个重标度就够了”的错误预期。即使这个玩具公式成立，也可能只是短篇经典Birman–Schwinger分析，不作为论文主贡献。首层能量误差即使为 $O(\varepsilon^2)$，也不足以分辨 $\varepsilon^4$ 模态，需分层奇异约化。

**难点与切入点。** 退化边在本材料类的实现、两近邻 Bloch 态耦合退秩、联合极限中不一致的余项及遗漏的弱尺度。现有周期胞 Fourier 形式／可靠谱包含可帮助检查隔离和曲率；gap 内正则 DtN 不能直接穿过阈值。Tao–Yang 2026 [L15] 的泛型非退化说明应研究刻意调谐的例外机制，不应将四次边描述为普遍现象。

最简单的尝试已经应排除：$\beta=0$、全周期零准动量的最低质量型带满足 $E_1(q;0)=q^2/\langle\rho\rangle+O(q^4)$，曲率严格正。B需选择较高带或非零固定 $\beta$ 的投影切片，并另证隔离／对称性；不能在此最低点反复调参期待四次边。

**止损。** 若既有高阶弱耦合定理已经给出同一联合极限且只剩常规 Bloch 投影，退出；若短期无法提出可证明实现的材料族，暂缓；若只能重现已知 $4/3$ 幂律或单参数计数，不能作为成果。首轮目标是一个机制存在／不存在的清晰结论，不是完整普适理论。

## 4. 高风险备选C：内部阈值态的材料可实现性

**精确问法（经独立挑战收窄）。** 固定 $\beta$，周期端有一个临界 Bloch 通道且同时存在其它传播通道，即内部阈值 $\lambda_*$。给定完整波导的一条非 $L^2$ 阈值几乎驻波 $u_*$（必须满足整体匹配），预先指定有限个沿轴向周期、横向紧支撑的材料调节函数 $W_1,\ldots,W_p$ 及参数锥 $K$，只允许

$$
\rho_t=\rho_0+\sum_{r=1}^p t_rW_r,\qquad t\in K\subset\mathbb R^p.
$$

首个具体类可取 $W_r$ 为指定材料区域的非负密度增量、$K=\mathbb R_+^p$，而不是允许任意函数扰动。问是否有非平凡曲线 $t(\varepsilon)\to0$，使真 $L^2$ 本征态经局部归一化后趋向 $u_*$；怎样由辐射耦合与阈值调谐方向判定可实现、需增加多少独立参数，或受锥约束绝不可能？允许本征频率变化，但 $\beta$ 固定。

**价值。** 导带进入连续谱以后究竟能留下真导模还是只能形成泄漏共振，是上午间隙内唯一性完全不涉及的问题。可实现性障碍与存在性一样有价值；不能预设任意阈值态都可被材料扰动束缚。

**近邻与可能新增。** Nazarov 2020 [L7] §5.3 已明确提出一般局部算子扰动下几乎驻波成为陷获波极限的问题，且覆盖柱形、周期及可推广的多端情形；因此“推广到两个周期端”不足为创新。本项只问受限的标量正密度扰动能实现哪些辐射消去条件。该2020猜想是否已有后续全面解决，尚未穷尽核查；不能称截至2026仍开放。Nazarov 2021 [L8] 的最低阈值、边界形变与简单共振结果不直接回答内部阈值受限材料问题。

接受独立复核的反对：若允许任意有界实 $W$，小扰动后密度仍正是自动条件；固定非零能量下它等价于一般实零阶势的首阶变化。因此**“保持正密度”已从贡献理由中删除**，真正限制是预先规定的有限材料族／参数锥、固定 $\beta$ 与内部阈值初态。

一般BIC的参数余维与辐射约束计数也已有 [L17]，并非本轮新思想。2026 Yuan–Lu的结构扰动理论 [L18] 在均匀外部、严格单开放衍射级区间内作局部Taylor/Puiseux分析；其“lasing threshold”是激射阈值，不是这里的连续谱通道开启阈值。C必须处理**临界通道奇异性和受限材料可控性同时存在**，不能仅重述普通BIC的满秩条件。仓库Q12已有阈值逆设计建议；C增加内部传播通道，改变的是谱类型与辐射消去，而非只调中心参数。

**第一步、难点与已有切入点。** 先在一个临界通道加一个传播通道的可控模型中，计算“材料扰动 $\mapsto$ 出射振幅”的线性映射，核对实约束、对称性与通道归一化后判断秩；失秩反例比空泛一般存在性更有用。需要阈值加权空间、嵌入谱和高阶消辐射，原有 gap 证书不能提供这些结论。已有 DtN/Cauchy 数据表示可作组织方式，但须另建阈值坐标及辐射条件。

具体先列 $W_r$ 到所有独立辐射条件的实化矩阵，并连同阈值调谐行检查 $K$ 中是否存在允许方向；满秩只是后续隐函数／阈值约化的候选条件，不是全阶消辐射证明。普通BIC已是 $L^2$ 态，而本项初态非 $L^2$，不可直接套常规解析本征态扰动。

**止损。** 没有可控的完整阈值态则不启动；若只剩最低阈值单驻波正扰动的标准出生，淘汰；若一般算子扰动或既有有限参数BIC理论可直接选择为本材料类，降为应用。有限参数／锥约束这一收窄本身也不是已确认的新意，必须出现真实可实现性障碍或新的阈值结论才值得推进。它比A/B距离现有工具更远，不作为近期必交定理。

## 5. 淘汰与降级记录

| 路线 | 决定及理由 |
|---|---|
| 任意弱正线缺陷存在、固定纤维 gap 内有限性 | 淘汰：质量型 Brown等2015 [L6] 已覆盖；换几何不能立题。 |
| 多边点、跳变材料下弱正缺陷精确计数 | 淘汰宽泛表述：TE型 Brown等2020 [L4] 已有精确数目；模型不同不是自动创新。 |
| 符号变化／首阶消去便首次出现高阶出生律 | 淘汰：Borisov–Gadyl'shin、Arazy–Zelenko及临界波导形变已有先例 [L5,L11]。 |
| 同背景无平带、隔离模态局部解析／持续性 | 淘汰：前者 [L1]，后者标准解析扰动。A必须解决真正不同远场的实质桥梁。 |
| 异质接合的谱流差／Maslov公式 | 淘汰：[L3] 已覆盖；净谱流不等于总模态数是已知事实，不是发现。 |
| 直接拼接、Dirac小扰动界面唯一性 | 淘汰宽泛表述：[L12,L13] 已有连续模型结果；当前方晶格没有已建立的Dirac结构。 |
| “完整导模分支图”作为当前主项目 | 降级不启动。除非先提出包含无限维尾、极点坐标切换和交叉的真正完备性定理，否则只是既有证书加扫描。 |
| 一般阈值分类、带宽呼吸、四次边慢光 | 淘汰宽泛表述：[L7,L9,L16]已有明确先例。B/C只保留更窄的联合极限／受限可实现性。 |
| 高对比tight-binding、局部电容矩阵计算 | 不立为主方向：2026新作 [L14] 已有系统工作；与当前有限对比度模型不同不能单独构成创新。 |
| 所有分支单调、处处非零速度或单向输运 | 不采用此猜想。实系数互易性允许反向伙伴与驻点；[L10]已有内部带边构造。 |

## 6. 已核查的文献证据

### L1：同背景无束缚态，已覆盖的结果

Vu Hoang and Maria Radosz, *Absence of bound states for waveguides in 2D periodic structures*, Journal of Mathematical Physics **55**, 033506 (2014). DOI [10.1063/1.4868480](https://doi.org/10.1063/1.4868480)；[arXiv:1111.4578v4](https://arxiv.org/html/1111.4578v4)，访问2026-10-30。证据 T/P：§II假设、§III Theorem 1；接口分工另读§III–VII，重点Propositions 3–5、Theorem 4，定位紧支撑压缩和选定延拓支的小范数。

条件按原文：$\varepsilon_0,\varepsilon_1\in L^\infty$ 实值；$\varepsilon_0$ 全周期；$\varepsilon_1$ 沿波导周期且横向紧支撑；$\varepsilon_0$ 与总密度正下界；存在开集 $M$ 使 $\operatorname{ess\,inf}_M|\varepsilon_1|>0$。结论是无全空间点谱。v4特别撤回由旧引文推出无奇异连续谱的附加推断，因此不能把本定理写成纯绝对连续或强输运。当前两个不同周期端不满足同一 $\varepsilon_0$ 加紧支撑扰动的形式。

### L2：2026定向弹道输运，最新直接近邻

Adam Black, David Damanik, Peter Kuchment, Tal Malinovitch, Giorgio Young, *Directional Ballistic Transport in Quantum Waveguides* (2026), [arXiv:2601.13471v1](https://arxiv.org/html/2601.13471v1)，2026-01-19；[稳定元数据](https://arxiv.org/abs/2601.13471)，访问2026-10-30。未在所读记录中确认期刊DOI。证据 T/P：§1.1 Theorems 1.2–1.3、Corollary 1.4，及§1.3证明结构。

原文主设置 $\mathbb R^{n+m}$、$n\ge2,m\ge1$，实 $V\in L^\infty$ 在横向单位球内支撑、其余方向周期。Theorem 1.3给纤维点谱的解析分支／投影（零测集之外）及梯度零集测度零；Theorem 1.2对列明定义域中的非零表面态给 Schrödinger演化的定向弹道输运。它显著压缩“DtN证明解析分支和输运”的新意空间，但自由外部及维数条件未匹配本问题。

### L3：异质接合谱流差，不能重新包装

David Gontier, *Edge states for second order elliptic operators in a channel*, Journal of Spectral Theory **12** (2022), 1155–1202（在线出版2023），DOI [10.4171/JST/430](https://doi.org/10.4171/JST/430)；[arXiv:2102.00275v2](https://arxiv.org/html/2102.00275v2)，2024-03-02修订，访问2026-10-30。证据 T：§4.2.4与Theorem 44；卷年、在线年、作者稿版本年分开记录。

对参数环上 $C^1(\mathbb T;L^\infty)$ 的左右实势族，并在整个参数环具有共同gap，接合谱流等于左右指标差，也等于相应Maslov指标；不依赖接合切换函数。空间跳变势允许；移动尖锐界面一般不满足 $L^\infty$ 参数连续，但仅弥补该拓扑条件未必有足够独立价值。净谱流不是固定参数的总模态数。

### L4–L19：其余核心来源及对选题的影响

以下访问日期均为2026-10-30。T/P项来自本轮主研究或只读分工实际阅读的指定正文；A/M项不用于断言未读的定理细节。

- **L4. B. M. Brown, V. Hoang, M. Plum, M. Radosz, I. Wood**, *Gap localization of multiple TE-Modes by arbitrarily weak defects*. Journal of the London Mathematical Society **102** (2020), 773–795. DOI [10.1112/jlms.12337](https://doi.org/10.1112/jlms.12337)；[arXiv:1901.05102v1](https://arxiv.org/html/1901.05102v1)，作者稿题名为 *Gap Localization of TE-Modes by arbitrarily weak defects – multiband case*。**T：Theorem 3及假设**。单一周期背景、固定轴向准动量、横向局部非负介电增量且在球上正、有界正系数、非恒定带、边点二次下界、小扰动；gap内恰有由达到该边的band/quasimomentum对数给出的特征值数。B的曲率消失点不满足该二次下界。
- **L5. Jonathan Arazy, Leonid Zelenko**, *Virtual Eigenvalues of the High Order Schrödinger Operator I*, IEOT **55** (2006), 189–231，DOI [10.1007/s00020-005-1389-x](https://doi.org/10.1007/s00020-005-1389-x)；*II*, 305–345，DOI [10.1007/s00020-005-1390-4](https://doi.org/10.1007/s00020-005-1390-4)。**T/P（已升级）**：ESI官方公开作者稿 [I:1705](https://www.esi.ac.at/preprints/esi1705.pdf)、[II:1706](https://www.esi.ac.at/preprints/esi1706.pdf)，阈值分工读II Theorem 3.4、式(3.3)，印刷pp.12–13（PDF第13–14页），并核I的Fourier规范。对一维 $D^4-\varepsilon W$，$W$连续、非负、非零、趋零且 $\int |x|^6W<\infty$，有两条虚特征值；第二条为 $-M^4\varepsilon^4/64\,(1+O(\varepsilon))$，$M=\int(x-\bar x)^2W$。一般高阶多尺度及Puiseux–Newton分析早已存在；B不能认领这些结论，联合$a$参数的覆盖仍需专查。另 **Orif O. Ibrogimov, David Krejčiřík, Ari Laptev**, *Sharp bounds for eigenvalues of biharmonic operators with complex potentials in low dimensions*, Math. Nachr. **294** (2021), 1333–1349，DOI [10.1002/mana.202000196](https://doi.org/10.1002/mana.202000196)，[arXiv:1903.01810v1](https://arxiv.org/html/1903.01810v1)。**T**：Theorem 1及弱耦合说明；$d=1,2,3$、$L^1$势的尺度界及尖锐性，排除把一维$4/3$指数认作新意。
- **L6. B. M. Brown, V. Hoang, M. Plum, I. Wood**, *On the spectrum of waveguides in planar photonic bandgap structures*, Proc. R. Soc. A **471** (2015), 20140673. DOI [10.1098/rspa.2014.0673](https://doi.org/10.1098/rspa.2014.0673)；[arXiv:1204.0998v1](https://arxiv.org/html/1204.0998v1)。**T/P**：弱正缺陷存在性论证及Theorem 3不累积／固定纤维gap有限性。质量型模型，同一周期背景；存在性论证已允许高偶次带边展开，故“首次处理非二次边存在性”也应淘汰。
- **L7. Sergei A. Nazarov**, *Threshold resonances and virtual levels in the spectrum of cylindrical and periodic waveguides*, Izvestiya: Mathematics **84** (2020), 1105–1160. DOI [10.1070/IM8928](https://doi.org/10.1070/IM8928)；[MathNet原文入口](https://www.mathnet.ru/eng/im8928)。**T/P（阈值分工）**：算子设定、分类、§5.3式(5.33)–(5.37)后问题和§5.4。一般形式自伴二阶椭圆系统，柱形／周期无穷端，Dirichlet/Neumann；讨论多端推广及内部阈值的精细调参。这是C的直接问题来源，不是本轮新提出的一般猜想。
- **L8. Sergei A. Nazarov**, *The preservation of threshold resonances and the splitting off of eigenvalues from the threshold of the continuous spectrum of quantum waveguides*, Sbornik: Mathematics **212** (2021), 965–1000. DOI [10.1070/SM9426](https://doi.org/10.1070/SM9426)；[MathNet](https://www.mathnet.ru/eng/sm9426)。**T：Theorems 2–5**。最低阈值Dirichlet波导、局部边界扰动、简单共振；保留共振及符号条件下分出特征值、二阶至任意阶渐近。不能把它偷换为一般内部阈值受限密度问题已解或未解。
- **L9. Lucas Chesnel, Sergei A. Nazarov**, *On the breathing of spectral bands in periodic quantum waveguides with inflating resonators*, ESAIM:M2AN **59** (2025), 2171–2206. DOI [10.1051/m2an/2025049](https://doi.org/10.1051/m2an/2025049)；[arXiv:2401.00439v1](https://arxiv.org/html/2401.00439v1)。**T：Theorem 6.1、Proposition 6.2**。薄Dirichlet周期波导、简单几乎驻波、几何调谐及紧参数区间一致带边余项；带宽呼吸机制已有。另 S. A. Nazarov, K. M. Ruotsalainen, P. J. Uusitalo, *Scattering Coefficients and Threshold Resonances in a Waveguide with Uniform Inflation of the Resonator*, J. Math. Sci. **283** (2024), 617–640，DOI [10.1007/s10958-024-07296-6](https://doi.org/10.1007/s10958-024-07296-6)，**A/M**：半无限柱加星形腔的散射相位与阈值共振。
- **L10. D. I. Borisov, K. V. Pankrashkin**, *Gap opening and split band edges in waveguides coupled by a periodic system of small windows*, Mathematical Notes **93** (2013), 660–675. DOI [10.1134/S0001434613050039](https://doi.org/10.1134/S0001434613050039)；[arXiv:1203.0201v1](https://arxiv.org/html/1203.0201v1)。**T**：模型和主定理；连续周期波导可有Brillouin区内部边缘。排除未经论证的全局单调性。
- **L11. D. Borisov, R. Gadyl'shin**, *On spectrum of a periodic operator with a small localized perturbation* (2008刊本；2006作者稿)，[arXiv:math/0609195v1](https://arxiv.org/html/math/0609195v1)。**T：Theorems 2.7–2.9**：一维周期二阶算子广义局部小扰动、每边至多一个、存在充要条件及首／次阶系数。稳定作者稿足以定位，刊本DOI本轮未核定。另 **D. I. Borisov**, *On the spectrum of a two-dimensional periodic operator with a small localized perturbation*, Izv. Math. **75** (2011), 471–505，DOI [10.1070/IM2011v075n03ABEH002541](https://doi.org/10.1070/IM2011v075n03ABEH002541)，[MathNet](https://www.mathnet.ru/eng/im4113)。**T：A1–A3、Theorems 1.5–1.9**：平面局部扰动、简单非退化二次边及本质唯一Bloch边点。不是线缺陷纤维的自动定理，但阻止笼统认领弱耦合充要条件。
- **L12. Wei Li, Junshan Lin, Jiayu Qiu, Hai Zhang**, *Mathematical Theory for Photonic Hall Effect in Honeycomb Photonic Crystals* (2025-12-30)，[arXiv:2512.24477v1](https://arxiv.org/html/2512.24477v1)。**T：Assumptions 1–5、9、12，Theorem 6、Corollary 7**。Hermitian一致椭圆蜂窝散度型算子、Dirac非退化、no-fold及小扰动；固定Dirac投影准动量下zigzag一个、armchair视类型一或两个界面模态。不是任意正密度异质晶体的全分支定理。
- **L13. Ben Schweizer**, *Edge-modes at interfaces between periodic media via reduced spatial dynamics near Dirac points* (2026-04-27)，TU Dortmund preprint 2026-01；[机构记录](https://eldorado.tu-dortmund.de/items/3cb7700a-c175-428c-9980-4c651f340e46)，repository DOI [10.17877/DE290R-26621](https://doi.org/10.17877/DE290R-26621)。**A/M**：Helmholtz周期波导、两半轴不同扰动从Dirac点开gap、得到界面模；未核全部定理假设。另 **Jiayu Qiu, Junshan Lin, Peng Xie, Hai Zhang**, *Mathematical theory for the interface mode in an acoustic waveguide bifurcated from a Dirac point*, Commun. Math. Sci. **24** (2026), 749–796，DOI [10.4310/CMS.260210003613](https://doi.org/10.4310/CMS.260210003613)，[作者全文](https://webhome.auburn.edu/~jzl0097/publications/Edge_modes_waveguide_QLXZ.pdf)。**T：Assumptions 1.1–1.3、Theorem 1.1**：有壁、周期障碍、反射/no-fold、小位移；唯一界面模。其关于障碍域无点谱的问题不能移植为本质量型模型已知开放性的证据。
- **L14. Habib Ammari, Bowen Li, Borui Miao, Jiayu Qiu, Lara Vrabac**, *Waveguiding in systems of high-contrast resonators: Theory and fast computations* (2026)，[arXiv:2608.26906v2](https://arxiv.org/html/2608.26906v2)，2026-08-31版。**T：§3.2、Corollary 3.13；独立复核另读其证明**。高对比、内部Neumann共振条件(3.2),(3.4)及外部gap(3.5)下，恰有$m_\star$条分岔导带、全轴向Floquet参数一致渐近及projected gap；对应电容本征值非恒定可推出小参数下实际带非平坦。它排除了“全参数计数＋非平坦”宽泛组合的新意，但不是任意固定对比度异质两端定理。另 **Habib Ammari, Erik Orvehed Hiltunen, Ping Liu, Borui Miao, Yi Zhu**, *A Tight-binding Approach for Computing Subwavelength Guided Modes in Crystals with Line Defects*，[arXiv:2512.05370v2](https://arxiv.org/html/2512.05370v2)，2026-01-20版；**A／独立复核引言**，亚波长高对比tight-binding已有系统近邻。
- **L15. Zhongkai Tao, Mengxuan Yang**, *Band edges of periodic Schrödinger operators are generically isolated and nondegenerate* (2026-08-31)，[arXiv:2608.30189v1](https://arxiv.org/html/2608.30189v1)。**A及Theorem 1.1定位**：$-\Delta+V$、实有界周期势、$d\ge2$，作者主张泛型势的gap端点由单带在有限准动量达到且Hessian非退化。本轮未独审证明；不将该拓扑类推广为有限维分片常数质量形状族，也不据此排除刻意调谐的B机制。
- **L16. Andrey A. Sukhorukov, C. J. Handmer, C. Martijn de Sterke, M. J. Steel**, *Slow light with flat or offset band edges in multi-mode fiber with two gratings*, Optics Express **15** (2007), 17954–17959，DOI [10.1364/OE.15.017954](https://doi.org/10.1364/OE.15.017954)；[arXiv:0711.1403v1](https://arxiv.org/html/0711.1403v1)。**P：式(3)–(8)、图2–3及色散推导**：四个包络的耦合模模型，调栅强／失谐控制四次或分裂带边。它是重要物理先例，不是正标量连续胞算子退化边的严格实现定理。
- **L17. Amgad Abdrabou, Lijun Yuan, Wangtao Lu, Ya Yan Lu**, *Parametric dependence of bound states in the continuum: a general theory*, Physical Review A **107** (2023), 033511，DOI [10.1103/PhysRevA.107.033511](https://doi.org/10.1103/PhysRevA.107.033511)；[arXiv:2205.09951v1](https://arxiv.org/html/2205.09951v1)（2022稿）。**P：§II式(6)–(14)**：按独立散射解、实约束和可调波矢自由度提出一般BIC余维公式，再作扰动展开；一般式的作者措辞为建议／论证框架，不在此升级为无条件普适定理。它直接压缩C的“辐射约束数决定调参量”新意空间。
- L17的更直接先例：**Lijun Yuan, Ya Yan Lu**, *Parametric dependence of bound states in the continuum on periodic structures*, Physical Review A **102** (2020), 033513，DOI [10.1103/PhysRevA.102.033513](https://doi.org/10.1103/PhysRevA.102.033513)；[arXiv:2007.15173](https://arxiv.org/html/2007.15173)。**T（独立复核）：式(7)–(8)后主命题、补充式(S27)**：两个实紧支撑介电扰动、单独立辐射通道、非退化BIC及非零耦合，调一参数得到BIC曲线；频率和准动量均可漂移，初态为真BIC，均匀外部。普通有限参数调谐已有明确理论。
- **L18. Lijun Yuan, Ya Yan Lu**, *Structural perturbation theory for bound states in the continuum via bifurcation of zeros and extrema of the dispersion relation* (2026-08-28)，[arXiv:2608.28321v1](https://arxiv.org/html/2608.28321v1)。**P：§II模型、式(1)，摘要及§III定位**。实介电层外部为真空，反射对称，$|\beta_*|<k_*<2\pi/L-|\beta_*|$，仅零阶开放；对复色散虚部零点／极值作Taylor/Puiseux扰动。该严格不等式避开衍射通道开启点，故不能直接用作C的内部阈值结论。
- **L19. Christian Hainzl, Robert Seiringer**, *Asymptotic behavior of eigenvalues of Schrödinger type operators with degenerate kinetic energy*, Math. Nachr. **283** (2010), 489–499，DOI [10.1002/mana.200810195](https://doi.org/10.1002/mana.200810195)；[arXiv:0808.3737v1](https://arxiv.org/html/0808.3737v1)。**T：设定及Theorems 1–2**，$n\ge2$、固定动能 $T=|P|^r$、光滑余维一零集，附近 $\nabla P\ne0$；不能直接把常数当作两个零点合并时一致。**Jean-Claude Cuenin, Konstantin Merz**, *Weak coupling limit for Schrödinger-type operators with degenerate kinetic energy for a large class of potentials*, Lett. Math. Phys. **111** (2021),46，DOI [10.1007/s11005-021-01385-2](https://doi.org/10.1007/s11005-021-01385-2)，[arXiv:2006.07110v2](https://arxiv.org/html/2006.07110v2)；以及 *On the number and sums of eigenvalues of Schrödinger-type operators with degenerate kinetic energy* (2023)，DOI [10.1007/978-3-031-31139-0_13](https://doi.org/10.1007/978-3-031-31139-0_13)，[arXiv:2202.05212v3](https://arxiv.org/html/2202.05212v3)。**T（设定核查，非全篇证明审计）**：固定正则零集，后文要求 $|\nabla P|\ge c_P>0$。这些是B必须对照的弱动能理论，已读假设不直接给合并极限的一致完整计数。

### A的额外覆盖风险及访问限制

**N. Filonov**, *Absolute continuity of the spectrum of two-dimensional Schrödinger operator with partially periodic coefficients*, St. Petersburg Math. J. **29** (2018), 383–398，DOI [10.1090/spmj/1498](https://doi.org/10.1090/spmj/1498)。**A/M**：[作者机构记录](https://pureportal.spbu.ru/en/publications/absolute-continuity-of-the-spectrum-of-twodimensional-schroedinger-operator-with-partially-periodic-coefficients%285c99e8cc-8902-4c75-a7ae-7006e201a27c%29.html)说明主系数与势为同一全周期项加横向超指数衰减项；完整系数正则性未核。**N. D. Filonov**, *The absence of eigenvalues for certain operators with partially periodic coefficients*, 同刊 **33** (2022), 867–878，DOI [10.1090/spmj/1730](https://doi.org/10.1090/spmj/1730)，**A/M**：势沿非周期方向快于一次幂衰减。AMS读取返回403，停止读取，没有绕过。二文未见直接包含不同非零周期远场，但这只是已读摘要的范围，不是开放性证明。

**Sonia Fliss, Patrick Joly, Vincent Lescarret**, *A Dirichlet-to-Neumann approach to the mathematical and numerical analysis in waveguides with periodic outlets at infinity*, Pure and Applied Analysis **3** (2021), 487–526，DOI [10.2140/paa.2021.3.487](https://doi.org/10.2140/paa.2021.3.487)；[出版商记录](https://msp.org/paa/2021/3-3/p03.xhtml)，[HAL:02444754](https://inria.hal.science/hal-02444754)。**A/M**：接口分工经正常浏览器读到完整出版商摘要：多个不同周期半波导接合、精确DtN、有界域Fredholm约化、可数频率共振例外。因此匹配框架本身已有。刊本题名依出版商修正，作者CV另用 *Mathematical analysis and numerical computation in waveguide domains with periodic outlets at infinity*。HAL全文返回Anubis Access Denied；出版商公开摘要可读，但PDF明确要求订阅／购买并显示Access Denied。未购买、未绕过、未读到正文，具体定理条件与是否覆盖A仍待核；工具不支持XHTML的技术错误不等于全文访问授权。

另两篇已读到明确范围：**Sonia Fliss**, *A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides*, SIAM J. Sci. Comput. **35** (2013), B438–B461，DOI [10.1137/12086697X](https://doi.org/10.1137/12086697X)，[arXiv:1202.4928v2](https://arxiv.org/html/1202.4928v2)，**T（独立复核）：Remark 1(2)、Proposition 8、Theorem 14**，早已明确允许左右不同周期密度、共同轴向周期；因此两端分别构造DtN拼接不是A的新增。**Pierre Amenoagbadji, Sonia Fliss, Patrick Joly**, *Time-harmonic wave propagation in junctions of two periodic half-spaces*, Pure and Applied Analysis **7** (2025), 299–357，DOI [10.2140/paa.2025.7.299](https://doi.org/10.2140/paa.2025.7.299)，[arXiv:2404.03806v2](https://arxiv.org/html/2404.03806v2)，**T/P：§1.1、§7.3**，不公度界面高维提升，保留非零吸收；不能用吸收问题唯一解排除实频平带，也不能把其无吸收困难当作A开放性的证明。

## 7. 检索范围、独立挑战与本轮边界

当前各候选均为**研究问题／猜想**，没有新定理、数值实验或候选间优劣的实验数据。现有证书只作为切入点，不修改其范围。检索包含2026新作，仍不是穷尽系统综述；未命中项不称已知开放问题。

实际检索族包括 periodic waveguide / absence of bound states / partially periodic / heterojunction / directional ballistic transport / weak defect multiband / threshold resonance / quartic band edge / band edge genericity，以及各命中文献的原文和后向参考。覆盖作者稿arXiv、作者主页、出版商和机构仓储；最新直接命中包括2026年1月、4月、8月文献。不是数据库穷尽综述，也未声称查完所有2026后续工作。

已读独立复核全部§1–9，采纳三项实质修正：A剥离标准输运推论，定位延拓支可逆点；B加入第二尺度、精确边缘和底带不可调退化的限制；C删除“正密度本身是强约束”的理由，限定有限材料族／参数锥。相同背景无点谱、完整阈值匹配核、近乎平带与完全平带、净谱流与总模态数等边界也已保留。复核者提出的“定量不可任意慢光”有独立价值，但目前既缺紧性／反例审计也缺专门文献覆盖，暂不挤入本轮三个入选项。

`Review only`用于文献定理及假设核验；没有改动被核查证明。本轮未下载新PDF，在线全文的稳定链接已记录；候选新颖性与若干原文假设尚未闭合，状态为 *Preliminary review; literature verification is incomplete.* 独立复核见 [[research/planning/review-new-directions-20261030]]，其文件由复核者独占编辑。

## 8. 下一步决策与交付检查

本轮不再启动新证明或实验。建议下一研究窗口只执行A的证明桥梁审计，同时给B一个很小的可实现性调查预算；C不启动。A的审计交付应是一份逐条对应已有定理的条件表和一个明确缺失引理，或一份已有覆盖／例行适配的淘汰结论，而不是先搭新程序。

| 尚存事项 | 对当前规划的影响 | 对下一阶段的门槛 |
|---|---|---|
| Filonov和FJL2021部分正文未核 | important caveat：不能确认A开放或首创；不阻止有条件排序 | 宣称新颖性前的blocker；只从合法可访问原文核查，不绕过限制 |
| B的真实正标量退化胞族未构造；联合参数先例未穷尽 | important caveat：B仅条件性主候选 | 进入PDE统一计数证明前的blocker；实现失败即暂缓 |
| C的完整内部阈值态和规定材料控制矩阵尚未建立 | important caveat：不承诺近期定理 | 存在性／不可实现性主张前的blocker；不以普通BIC秩条件代替 |
| 玩具模型临界系数尚未正式证明 | minor caveat：仅供反例测试的工作猜想 | 不纳入任何已证明结论；即使证出也不自动构成主贡献 |

本轮检查：路径与分支重新核验；起点工作区干净，最终只应提交本规划和独立复核两个新Markdown；已有理论、证书、用户规则及其它工作树均未改。文内仓库链接检查无缺失。未启动MATLAB、未安装依赖、未新增MAT／PDF／实验数据；独立复核仅作了六项Taylor系数的标准库有理运算，无输出文件。15:23保守存储核查为 **96,149,568 bytes**（包含隐藏／忽略文件，不跟随外部符号链接，并给Git指针预留1MiB；不遍历共享Git元数据），远低于1GB。两个新文档当时共75,746 bytes，后续仅少量文字整理，仍在150KB写入预算内。提交后哈希与工作区状态由对话交付，不在文件内自引用提交哈希。

进程核对限制：最后尝试只读 `ps` 的PID/父PID/RSS/程序名并筛选MATLAB/Python，系统返回 `operation not permitted: ps`，结果为**拒绝、未取得快照**，未重试或绕过。本轮没有启动MATLAB或后台实验，所有本轮命令均已返回、只读分工已结束；据此没有已知遗留的本轮计算任务，但不能宣称已用全系统进程表独立确认。
