# 新方向独立文献与价值复核（2026-10-30）

本文件的 `review` 指独立复核。时间均为 UTC。任务模式：**Review only**（只审查候选及文献条件，不修改被审文件）。这是方向筛选记录，不是新定理证明。关联主规划：[[research/planning/p-new-directions-20261030]]。

## 1. 边界与检索独立性

- 14:55 核实目录 `/Users/whc/Documents/Work/dot-research`、分支 `codex/dot`；工作树起初干净。已读根及 `research/` 指令、相关本地技能。当前 HEAD 为 `96e93c0`。存储约 93 MB，未下载文献、未运行 MATLAB 或数值实验、未访问私有远端。
- 本轮只允许写本文件，不提交、不修改其他文件。文献在线阅读；技能通常要求归档全文，但委派明确限写单一 review，故本轮记录稳定来源与建议下载名，供主研究者决定归档。
- **14:59 独立初筛冻结**：以下第 2–4 节形成时，主规划文件尚未出现在 `research/planning/` 文件清单中，尚未阅读主研究者候选。后续交叉挑战另记，避免把事后意见伪称独立发现。
- 以当前标量模型 $-\Delta u=\mu\rho u$、沿缺陷方向的 Floquet 参数 $\beta$、横向两侧周期介质为背景。已有固定 $\beta$ 的唯一导模认证只是研究起点；本轮不继续优化该证书或旧误差半径。

## 2. 先淘汰的宽泛题目

| 宽泛题目 | 最接近的先例及已核查内容 | 独立判定与最低差异化要求 |
|---|---|---|
| 弱线缺陷在 gap 中产生导模、固定 Floquet 参数下模态总数有限 | Brown–Hoang–Plum–Wood，*On the spectrum of waveguides in planar photonic bandgap structures*（2015），arXiv:1204.0998；原文 Theorem 3 排除带边处累积，另有弱缺陷存在性。模型是加权 Helmholtz，接近本项目。 | **淘汰为独立选题**。增加一种形状或给出更精确数值不能改变已有结论。两侧不同材料不直接落在同背景假设下，但“假设不同”本身不是创新。 |
| 多带/多个极值点贡献的弱缺陷精确模态数 | Brown–Hoang–Plum–Radosz–Wood，arXiv:1901.05102，Theorem 3。原文条件依次包含有界正系数、非负且局部严格正的介电扰动、非平坦带、带边统一二次下界、小扰动；结论是 gap 内恰有 $n$ 个特征值，$n$ 为达到该边缘的 $(s,k)$ 对数。 | **明确先例，不能作为“首次精确计数”**。它是 divergence-form TE，不可直接援引为质量型模型的全部证明；但“多阈值秩/数目决定计数”的思想已不新。符号不定扰动、首阶矩阵奇异及参数一致性才可能留空间。 |
| 证明导模分支局部解析、简单分支在微小形变下持续存在 | Kato 解析扰动是基础；上述文献也使用解析带函数。 | **淘汰**。除非研究进入阈值、改变谱类型或给出新机制，否则这是隔离简单特征值的常规推论。 |
| 证明周期缺陷带不完全平坦，从而没有沿缺陷方向也平方可积的模式 | Hoang–Radosz，*Absence of bound states for waveguides in two-dimensional periodic structures*（2014），arXiv:1111.4578v4，Theorem 1：全平面加权 Helmholtz 算子无点谱。 | **同背景情形已有强先例**。这里“无 bound states”指全二维 $L^2$，不否定固定 $\beta$ 条带的离散导模。也不自动证明每点群速度非零、单调性或现有异质两端模型的同一结论。 |
| 体边对应/平移切口的谱流保证界面态 | Gontier，*Edge states for second order elliptic operators in a channel*，arXiv:2102.00275v2，Theorem 44：公共 gap 中界面族的谱流等于两端指标差。原文也讨论 Maslov 指数与一般自伴边界条件。 | **淘汰泛化表述**。这是整条参数闭路的净穿越数，并非每个参数恰有一个模式，更不保证导模分支单调或免散射。若只是把 DtN 行列式换成 Maslov 语言，价值不足。 |
| “首次处理直接拼接而非缓慢 domain wall 的两种周期介质” | Li–Lin–Qiu–Zhang，*Mathematical Theory for Photonic Hall Effect in Honeycomb Photonic Crystals*，arXiv:2512.24477v1；原文引言明确强调直接拼接、系数不连续，Theorem 6/Corollary 7 是其主结论定位，尚未完成全部条件核验。Schweizer 2026 同时研究 Helmholtz 异质两端 Dirac 点附近界面态。 | **极高重叠风险**。不能仅以“尖锐界面”“不同两端”“不是绝热连接”提出新颖性。当前正系数方晶格模型也没有已建立的蜂窝 Dirac 点/非平凡指标，不能套拓扑保护叙事。 |
| 首阶几何效应消去后出现四阶弱束缚 | Exner–Vugalter（1997），*Bound states in a locally deformed waveguide: the critical case*，原文 Theorems 1–2 已给零平均局部变宽下不存在/存在及四阶能隙界；Exner–Kondej–Lotoreichik（2024）把临界变形、唯一简单束缚态带到 soft waveguide。 | **淘汰“消去便是新机制”**。需比较周期介质、符号不定形变的高阶有效矩阵与参数联合极限。面积不变只消去 $\int V_n$，不消去边缘 Bloch 场加权的 $\int V_n|u_*|^2$。 |
| 用 tight binding 得到导模色散、几何鲁棒/近乎平带 | Ammari–Hiltunen–Liu–Miao–Zhu，arXiv:2512.05370v2（2026）已证明相应高对比亚波长电容矩阵非对角元指数衰减及带状近似误差；Delourme–Fliss（2024）有 graph-like 蜂窝边缘态、切口位置/厚度鲁棒和近乎不色散态。 | **淘汰宽泛题目**。当前有限对比度质量型模型不是其渐近模型的自动应用；但“离散模型导模”“几何鲁棒”“慢光设计”均不足以立题。必须提出连续模型中原结果无法回答的量或极限。 |

补充障碍：Borisov–Pankrashkin（2013）已经严格构造 gap 边缘在 Brillouin 区内部达到的周期连续波导。不能把一维 Floquet 参数误当一维 Sturm–Liouville 问题，从而预设极值只在 $0,\pi$ 或分支全局单调。

## 3. 独立留下的三个窄问题（均未宣称开放/首创）

### A. 两端投影阈值竞争时，导模出生边界是否产生平方根尖点？

**问题**：固定真实二维、分片常数质量系数的异质结，设左右投影带边 $E_-(\beta),E_+(\beta)$ 在 $\beta_*$ 横截相交；各边缘对应横向 Bloch 变量的简单二次极值。另用一个中心几何参数 $\tau$ 调节完整结。研究 $(\beta,\tau)$ 平面中“公共 gap 内存在导模”的局部边界，及两侧定位长度/质量分配的变化。不是问“不同介质总会产生模式”。

**关键阻碍**：仅知两端各有阈值 Bloch 波，不能推出整个结有阈值共振。必须先判定未扰动结的阈值匹配核及其维数；若匹配核为零，普通弱缺陷的奇异 Birman–Schwinger 结论未必保留。半导向 Dirichlet 的极点是坐标问题，不能凭避极点删掉物理阈值核。

**可检验的目标形式**：在一维匹配核、两端二次边缘、适当横截性下，尝试推出正规形中同时出现 $\sqrt{E_-(\beta)-\mu}$ 与 $\sqrt{E_+(\beta)-\mu}$，从而模式出生曲线相对阈值错配 $\Delta=E_+-E_-$ 可能有 $\sqrt{|\Delta|}$ 主项。**这只是未证明的工作假说；系数、符号、参数区域和适用谱面尚未建立。** 若能把它与真实二维阈值态的匹配及定位不对称联系起来，比“再算一个固定 $\beta$ 根”更有独立意义。

**价值门槛**：先读 Nazarov 2020 的阈值/虚能级分类与已有多通道散射定理；若已有一般定理直接给出该正规形，换成两侧不同周期胞元只剩常规适配，应淘汰。不要为此先扩建数值证书。

### B. 符号不定形变的有效耦合矩阵失秩，与 Floquet 参数的联合极限

**问题**：相同周期背景中，多边缘 Bloch 模式的首阶形变耦合矩阵 $C(\beta)$ 在 $\beta_*$ 有简单零特征值，形变强度 $\varepsilon\to0$。能否给出在 $\beta-\beta_*=O(\varepsilon)$ 范围一致的模态数、出生/消失及高阶能隙律，而不是对每个固定 $\beta$ 分别使用弱耦合结论？

**潜在差异**是首阶秩改变时二阶约化算子决定计数，且真实固定对比度材料界面的位移并非小 $L^\infty$ 系数变化。必须处理形状微分、阈值消奇以及联合余项；不能把已知四阶律的重新参数化当成果。Zelenko 对周期 Schrödinger 的符号不定扰动已有虚能级重数上界；软波导临界变形已有唯一性。因此本候选仅作**高重叠风险备用**，优先级低于 A。

### C. 定量“不可任意慢光”：有界对比度、固定宽度和谱隔离下的导带宽度下界

**问题**：固定能量上限、材料上下界、缺陷宽度、几何正则/最小特征尺度、以及导带到本质谱的统一距离，能否给出某个非零 Floquet 区间内孤立简单导带振幅的显式下界，或构造仍使其趋零的连续二维反例？

**区别**：无完全平带仅排除振幅等于零；微分公式仅计算局部斜率；都不提供统一定量下界。另一方面，几何参数若被人为限制为紧的有限维族，利用紧性加非平坦性的非构造性正下界可能很容易，价值有限。近乎不色散边缘态已有先例，必须说明哪些常数在其退化极限中失控。

**当前判断**：学术问题比 B 更独立，但实现难度和文献遗漏风险最大。本轮只保留为中期分析题，不建议立即投入证明。首先以允许类的紧性/非紧性检查排除“平凡紧性定理”，再检索定量唯一延拓、带宽下界与隧穿文献。未搜到同题不能证明开放。

## 4. 可复核文献记录（第一批）

“原文检视”仅表示在线检查所列章节/结果，不声称全篇证明已逐行复核。以下均未下载到本地。

1. B. M. Brown, V. Hoang, M. Plum, I. Wood. **On the spectrum of waveguides in planar photonic bandgap structures**. *Proceedings of the Royal Society A* 471 (2015), 20140673. DOI [10.1098/rspa.2014.0673](https://doi.org/10.1098/rspa.2014.0673)；[arXiv:1204.0998 原文](https://arxiv.org/html/1204.0998)。检视 §5.1、Theorem 3（不累积）及引言。建议 `Brown2015.pdf`。
2. B. M. Brown, V. Hoang, M. Plum, M. Radosz, I. Wood. **Gap localization of multiple TE-Modes by arbitrarily weak defects**. *Journal of the London Mathematical Society* 102(2) (2020), 773–795. DOI [10.1112/jlms.12337](https://doi.org/10.1112/jlms.12337)；[arXiv:1901.05102](https://arxiv.org/html/1901.05102) 的题名为 *Gap Localization of TE-Modes by arbitrarily weak defects – multiband case*。检视 preprint Assumptions 1–3、Theorem 3 及其上/下界结构；刊本元数据另以 [KIT 机构记录](https://publikationen.bibliothek.kit.edu/1000124967) 核定，刊本定理编号未独立核验。建议 `Brown2020.pdf`，归档时核对版本。
3. V. Hoang, M. Radosz. **Absence of bound states for waveguides in two-dimensional periodic structures**. *Journal of Mathematical Physics* 55 (2014), 033506. DOI [10.1063/1.4868480](https://doi.org/10.1063/1.4868480)；[arXiv:1111.4578v4](https://arxiv.org/html/1111.4578v4)。检视模型及 Theorem 1；全文名称与 arXiv 标题的 `2D` 是同文版本差异。建议 `Hoang2014.pdf`。
4. David Gontier. **Edge states for second order elliptic operators in a channel**. 2021 preprint，所检 v2 为 2024, [arXiv:2102.00275v2](https://arxiv.org/html/2102.00275v2)。检视 Theorems 1、44 和周期族/公共 gap 假设；未核定刊本元数据。建议 `Gontier2021.pdf`，记录 v2。
5. Leonid Zelenko. **Virtual bound levels in a gap of the essential spectrum of the weakly perturbed periodic Schrödinger operator**. *Integral Equations and Operator Theory* 85 (2016), 307–345；[arXiv:1505.07381](https://arxiv.org/html/1505.07381)（preprint 题名略异）。检视 §1.2、§4.3 的 Theorem 4.3 定位，尚未核完其全部技术假设；不可直接用于本项目。建议 `Zelenko2016.pdf`。
6. P. Exner, S. A. Vugalter. **Bound states in a locally deformed waveguide: the critical case**. *Letters in Mathematical Physics* 39 (1997), 59–68. DOI [10.1023/A:1007373212722](https://doi.org/10.1023/A:1007373212722)；[arXiv:funct-an/9601002](https://arxiv.org/html/funct-an/9601002)。检视 Theorems 1–2 的条件与四阶界。建议 `Exner1997.pdf`。
7. Pavel Exner, Sylwia Kondej, Vladimir Lotoreichik. **Bound states of weakly deformed soft waveguides**. *Asymptotic Analysis* 138 (2024), 151–174. DOI [10.3233/ASY-241893](https://doi.org/10.3233/ASY-241893)；[arXiv:2211.01989](https://arxiv.org/html/2211.01989)。检视 Theorems 1.1、1.3 和临界情形未决问题段落。注意某些二手书目误记为 2023，刊本记录为 2024。建议 `Exner2024.pdf`。
8. S. A. Nazarov. **Threshold resonances and virtual levels in the spectrum of cylindrical and periodic waveguides**. *Izvestiya: Mathematics* 84(6) (2020), 1105–1160. DOI [10.1070/IM8928](https://doi.org/10.1070/IM8928)；[MathNet 页](https://www.mathnet.ru/eng/im8928)、[公开 PDF](https://www.mathnet.ru/php/getFT.phtml?jrnid=im&option_lang=eng&paperid=8928&what=fullteng)。初筛只读摘要，15:10 前已进一步检视原文 §1、Proposition 4.1（印刷 pp.1133–1134，PDF pp.29–30）、§5.1–5.2 与 Lemmas 5.1–5.3：一般 Jordan 长度及多出口阈值机制已有框架；§5.2 明说其中渐近仅作形式分析并引已有证明。不能由摘要覆盖范围推断本报告 A 已被完整解决。建议 `Nazarov2020.pdf`。
9. Wei Li, Junshan Lin, Jiayu Qiu, Hai Zhang. **Mathematical Theory for Photonic Hall Effect in Honeycomb Photonic Crystals**. 2025, [arXiv:2512.24477v1](https://arxiv.org/html/2512.24477v1)。检视引言、模型及主结果定位；没有把该文拓扑结论应用到当前方晶格。建议 `Li2025.pdf`。
10. Ben Schweizer. **Edge-modes at interfaces between periodic media via reduced spatial dynamics near Dirac points**. TU Dortmund preprint 2026-01, 27 April 2026；[机构页面](https://eldorado.tu-dortmund.de/items/3cb7700a-c175-428c-9980-4c651f340e46)，[公开原文 PDF](https://eldorado.tu-dortmund.de/bitstreams/0e4fcf38-4890-4246-92f0-f3f3b6711503/download)。目前仅摘要/首页信息，尚未核定理条件。建议 `Schweizer2026.pdf`。
11. Habib Ammari, Erik Orvehed Hiltunen, Ping Liu, Borui Miao, Yi Zhu. **A Tight-binding Approach for Computing Subwavelength Guided Modes in Crystals with Line Defects**. 2025 preprint，所检 v2 为 20 January 2026，[arXiv:2512.05370v2](https://arxiv.org/html/2512.05370v2)。检视引言/主要贡献，尚未逐条核验指数衰减定理。建议 `Ammari2025.pdf`，保留版本。
12. Bérangère Delourme, Sonia Fliss. **Guided Modes in a Hexagonal Periodic Graph Like Domain**. *Multiscale Modeling & Simulation* 22(3) (2024), 1196–1245. DOI [10.1137/23M1600177](https://doi.org/10.1137/23M1600177)；[arXiv:2309.02023v3](https://arxiv.org/html/2309.02023v3)。检视引言、主结果结构；原文有薄厚参数，不能推导固定厚度下任意平坦。建议 `Delourme2024.pdf`。
13. D. I. Borisov, K. V. Pankrashkin. **Gap opening and split band edges in waveguides coupled by a periodic system of small windows**. *Mathematical Notes* 93 (2013), 660–675. DOI [10.1134/S0001434613050039](https://doi.org/10.1134/S0001434613050039)；[arXiv:1203.0201v1](https://arxiv.org/html/1203.0201v1)。目前摘要/模型已检视，不援引未查定理编号。建议 `Borisov2013.pdf`。
14. Zhongkai Tao, Mengxuan Yang. **Band edges of periodic Schrödinger operators are generically isolated and nondegenerate**. 31 August 2026, [arXiv:2608.30189v1](https://arxiv.org/html/2608.30189v1)。检视摘要及 Theorem 1.1 定位，证明未独审。该近期 preprint 的泛型结论属于 $-\Delta+V$、有界实势的拓扑类，**不是分片常数质量系数的有限维形状族**；既不能据此取消所有退化边缘题，也不能再笼统称“泛型带边非退化仍完全开放”。建议 `Tao2026.pdf`。
15. D. Borisov, R. Gadyl'shin. **On spectrum of a periodic operator with a small localized perturbation**. 2006, [arXiv:math/0609195v2](https://arxiv.org/html/math/0609195v2)。检视引言及一维周期二阶模型；已有边缘特征值存在/不存在条件及渐近，不可用一维结论冒充当前二维异质结定理。建议 `Borisov2006.pdf`。

## 5. 审查状态与待办

当前：**Preliminary review; literature verification is incomplete.** 本轮完成的是具有可追溯来源的淘汰与窄问题筛选，不是开放性或首创性证明。除本文件外无授权修改；没有新增 theorem/proof 环境、标签、编号；未改任何被审证明。所有建议下载名均为建议，不能当本地已归档事实。

下一步：在独立初筛之后阅读主规划，并用上述最近先例逐项挑战其候选；尤其检查是否只是局部继续早间证书、是否用物理标签掩盖普通 Kato/弱耦合结论、是否存在真实可达到的阈值/消去条件。

## 6. 15:06 主规划第一版的交叉挑战

15:02 后首次阅读主规划。其 §2 优先方向是“异质周期两端的非平坦导模与输运”，§3 是阈值分岔和可靠完整分支图。本轮意见针对该版本；没有修改主规划。

### 6.1 对第一优先方向的暂定判断

**有条件保留首位，但贡献核心应写成非平坦性，不能把标准输运推论当第二个独立突破。** 未找到已经直接覆盖该质量型、两侧不同真正二维周期端的定理；这不是开放性确认。主规划准确排除了 Hoang–Radosz 同背景定理的直接应用，也没有把无点谱写成全谱绝对连续。

独立重查 Black–Damanik–Kuchment–Malinovitch–Young 2026 原文 §1.1，确认 $n\ge2,m\ge1$、横向紧支撑有界势、自由外部及 Schrödinger 演化是其陈述范围；Theorems 1.2–1.3、Corollary 1.4 与主规划所述一致。**但仅靠 $n=1$ 或改为 $e^{-it\sqrt A}$ 不足以支撑新意**：其引言已说明 Fliss 在二维纤维本质谱外（包括 gap）已有 DtN/Fredholm 表述，本文困难主要是包含嵌入态；当前主候选主动避开嵌入态、仅研究统一隔离导带，解析谱投影已经是常规工具。

对于统一隔离、$\mu(\beta)>0$ 的简单分支，标准准备应明确落到下列对象，而非笼统承诺“输运”：

$$
\int_{\mathbb R\times(0,1)}\rho|\phi_\beta|^2=1,
\qquad
\mu'(\beta)=2\operatorname{Re}\int_{\mathbb R\times(0,1)}
(-\mathrm i\partial_y+\beta)\phi_\beta\,\overline{\phi_\beta},
\qquad
v(\beta)=\frac{\mu'(\beta)}{2\sqrt{\mu(\beta)}}.
$$

这里 $\phi_\beta$ 是周期 gauge 下的纤维本征函数，内积归一在加权空间，导数右端积分的动量项不额外乘 $\rho$。固定紧子区间上的光滑幅度波包，纵向位置的 Bloch 表示是 $\mathrm i\partial_\beta$ 加有界胞内项；微分相位 $e^{-it\sqrt{\mu(\beta)}}$ 给乘法速度 $v$，其他项除以 $t$ 消失。横向结论主要由该区间的一致定位/位置矩控制给出。这是待把定义域条件写清的标准推论，**并非本报告已完成的新输运证明**。

即使证明非平坦，只能推出解析分支的驻点为离散集（在紧子区间有限），不能推出 $|v|$ 的统一正下界。非零波包可有零的有符号平均速度，例如对称叠加相反速度；“强极限作为向量非零”与“期望位移非零”必须区分。主规划已经反对全区间同号，这是正确限制。

**第一项实质理论门**：对固定实能量 $\mu_0$，将“正测度 $\beta$ 上的 $L^2$ 纤维核”转为适用于异质两端的解析 Fredholm 对象，并证明它可通到一个已知可逆的复准动量区域。不能只证明每个实 gap 小邻域内的解析性。对同背景，Hoang–Radosz 的 §IV.3 Proposition 4、方程 (21) 使用紧支撑扰动把方程压到一个胞元；§V Lemma 1 / Proposition 5 继续带极点留数的预解式。对异质背景，直接写 $\rho=\rho_-+(\rho-\rho_-)$ 后，后一项在右半空间不紧支撑，**这一关键 Fredholm 压缩失效**。这精确定位了真正需新论证之处。

**反方检验**：Thomas 型大虚准动量下自由算子的逆界，即使对所有有界密度都成立，也不能单独填补实 gap 与该区域之间的 Fredholm 连通性。两个 lead 各自能解析延拓，不等于它们选定的衰减/出射分支在共同路径上仍对应所需物理核；需要管理谱面、支选择及极点，不能简单取两条可行路径的交集。

### 6.2 阈值备选须先扣除项目内部重复

现有 [[research/explorations/interface-threshold/candidate_problems]] 的 Q1–Q3 已提出异质共振必要性、多临界通道/实际共振维数和异步阈值；[[research/explorations/interface-threshold/rigorous_2d_bridge]] 已有 B1–B5、单临界端和另一端严格 gap 的条件性桥梁，以及真实二维小调制谱底模型。

因此主规划 §3 若仍只写“任意弱还是有阈值、用耦合矩阵数模态”，连**项目内部也不是新问题**。本报告 A 的两边缘随 $\beta$ 横截相交、共同阈值附近的双平方根联合尺度，比现有单临界端更窄；它仍可能只是该探索的自然扩展。应降低其“主动新方向”排序，除非明确出现可证明的相图尖点/不对称定位的新结论。不能把补完 H1–H4 或核验已有加权端条件重新命名为新方向。

### 6.3 完整分支图的可靠证明：暂不列为理论首选

净谱流看不见方向相消的模态对；有限参数网格看不见小环、未解析交叉或只在极窄参数段存在的支。因此“完整图”确实比一个净整数更强。但若范围只限已假设简单且统一隔离的紧参数区域，区间参数延拓、覆盖和导数界主要是成熟验证技术的组合，易退回本轮用户不要的认证工程。

若保留，必须事先给出一个非平凡的**可终止且可证完备**的问题类：临界点、交叉、与本质谱相碰的局部模型有明确有限结构，且算法能证明没有遗漏的分支，而不是把未知复杂处排除后再声称完整。做到这一点可能是数值分析论文；目前主规划尚无足够的新数学契约，建议放第三或暂停。

### 6.4 新增来源与访问边界

- Adam Black, David Damanik, Peter Kuchment, Tal Malinovitch, Giorgio Young. **Directional Ballistic transport in Quantum Waveguides**. 2026, [arXiv:2601.13471v1](https://arxiv.org/html/2601.13471v1)。独立检视 Theorems 1.2–1.3、Corollary 1.4、§5.2 Lemma 5.9 及证明末尾；未复核全部 DtN 估计。建议 `Black2026.pdf`。
- Sonia Fliss, Patrick Joly, Vincent Lescarret. **A Dirichlet-to-Neumann approach to the mathematical and numerical analysis in waveguides with periodic outlets at infinity**. *Pure and Applied Analysis* 3(3) (2021), 487–526. DOI [10.2140/paa.2021.3.487](https://doi.org/10.2140/paa.2021.3.487)；[出版社条目](https://msp.org/paa/2021/3-3/p03.xhtml)。元数据已核；HAL 原文请求返回 Anubis `Access Denied`，出版社 XHTML/PDF 也未获得可读正文。没有绕过保护，没有宣称其证明已核。建议 `Fliss2021.pdf`；**其是否覆盖异质端的相关无点谱/非平坦结论仍待原文核查**。
- Nikolay Filonov. **The absence of eigenvalues for certain operators with partially periodic coefficients**. *St. Petersburg Mathematical Journal* 33(5) (2022), 867–878. DOI [10.1090/spmj/1730](https://doi.org/10.1090/spmj/1730)；[AMS 原文入口](https://www.ams.org/journals/spmj/2022-33-05/S1061-0022-2022-01730-6/S1061-0022-2022-01730-6.pdf)。目前仅摘要/文献信息，横向衰减势范围不等于非衰减两种周期端；建议 `Filonov2022.pdf`。
- Rainer Hempel, Martin Kohlmann, Marko Stautz, Jürgen Voigt. **Bound states for nano-tubes with a dislocation**. *Journal of Mathematical Analysis and Applications* 431 (2015), 202–227. DOI [10.1016/j.jmaa.2015.05.040](https://doi.org/10.1016/j.jmaa.2015.05.040)；[arXiv:1412.6420v2](https://arxiv.org/pdf/1412.6420v2)。检视 Theorem 1.1：两个不同圆柱势、给定能量在各全柱算子的 resolvent，再有半柱本质谱条件，存在无界位移序列产生该能量。不是沿接口 Bloch 参数的非平坦性。建议 `Hempel2015.pdf`。

15:06 暂定排序：**异质两端的非平坦性第一；双阈值竞争相图第二（但属现有探索扩展）；完整可靠图第三；临界形变失秩与定量慢光问题仅留备忘。** 不建议把五个方向同时启动。

## 7. 15:11 最近邻补查：进一步压缩可宣称的新意

### 7.1 异质两端的 DtN 表述在 2013 已明确列为可扩展情形

Sonia Fliss，**A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides**，*SIAM Journal on Scientific Computing* 35(2) (2013), B438–B461，DOI [10.1137/12086697X](https://doi.org/10.1137/12086697X)，[arXiv:1202.4928v2 原文](https://arxiv.org/html/1202.4928v2)。本轮独立检视 Remark 1(2)、Proposition 8、Theorem 14。Remark 1(2) **明确允许左右不同周期质量密度 $\rho_p^\pm$，共用 $y$ 周期而 $x$ 周期可不同**；Theorem 14 的 DtN 等价与常规分支连续性不是新结构。原文没有在已检段落证明这种异质情形的导带非平坦性，不能把这个限定读成其已证明或未证明的全篇结论。建议 `Fliss2013.pdf`。

这是对主规划的 **important caveat**：若“新贡献”最后只有两端分别构造 DtN 后拼接，则应淘汰；若能证明全新的复准动量非平坦性排除门，仍值得预研。

### 7.2 2025 两周期半空间接合论文尚未给实频无吸收完整答案

Pierre Amenoagbadji, Sonia Fliss, Patrick Joly，**Time-harmonic wave propagation in junctions of two periodic half-spaces**，*Pure and Applied Analysis* 7 (2025), 299–357，DOI [10.2140/paa.2025.7.299](https://doi.org/10.2140/paa.2025.7.299)，[arXiv:2404.03806v2](https://arxiv.org/html/2404.03806v2)。检视 §1.1 的假设与讨论、§7.3。该文处理界面不公度情形的高维提升，但保留非零吸收；§7.3 明确指出无吸收下界面导波带来困难。因此不能援引其“有吸收问题唯一解”来排除实频平带。反过来，其未解决完整无吸收问题也**不是本候选特定非平坦性问题开放的证明**。建议 `Amenoagbadji2025.pdf`。

### 7.3 2026 高对比度论文已给统一导带计数和条件非平坦性

Habib Ammari, Bowen Li, Borui Miao, Jiayu Qiu, Lara Vrabac，**Waveguiding in systems of high-contrast resonators: Theory and fast computations**，2026，[arXiv:2608.26906v2](https://arxiv.org/html/2608.26906v2)，31 August 2026。检视摘要、§3.4.2 Corollary 3.13 及其证明：在列明的高对比度、参考内 Neumann 频率与外部 gap 等条件下，对所有沿缺陷 Floquet 参数给恰 $m_*$ 条分岔模态、统一渐近与投影 gap；若对应电容矩阵特征值非恒定，则小对比参数下实际带不平坦。建议 `Ammari2026.pdf`。

该结果使“连续 Helmholtz＋全 Floquet 参数＋精确模态数＋非平坦性”这一宽泛组合也不能称新。它仍是特定高对比度渐近/有效算子条件下的结论，未直接覆盖当前有限对比度异质两端；预研应逐一比较条件而不是仅用标题作区别。

### 7.4 不影响排序的邻近无束缚态结果

Sarah Al Humaikani, Anne-Sophie Bonnet-Ben Dhia, Sonia Fliss, Christophe Hazard，**A Rellich-type theorem for the Helmholtz equation in a junction of stratified media**，2025，[arXiv:2504.17345v1](https://arxiv.org/html/2504.17345v1)；作者网页列为 2026 年 SIAM J. Math. Anal. 已接收，本文不补猜期刊 DOI。已读 §1.1 及 Theorem 1 定位：三个有指定层状结构的半平面并、角度限制与外部常系数条件下无非零 $L^2$ 解。其几何和介质假设不同于一般二维周期异质结，只作分层极简模型的先例警告。建议 `AlHumaikani2025.pdf`。

截至本节，本轮未获得 Fliss–Joly–Lescarret 2021 正文的问题仍未解决；HAL 拒绝的是该次取文动作，未重试受保护入口，其他公开 arXiv 文献阅读正常完成。没有权限动作处于 pending 或结果不明状态。

## 8. 15:16 对主稿 A/B/C 新排序的具体批评

15:12 再读到主稿标记“15:13”的新版：B 已改为合并二次极小点的统一弱缺陷计数，C 已改为内部阈值态的受限材料实现；早先 §6 的旧版阈值备选批评不应误读成对新版 B/C 的完整判定。

### 8.1 B：至少两个参数尺度，单个 $\varepsilon^{2/3}$ 重标度不足以数尽模式

对主稿自己提出的标量检验模型，先把 $b=1$ 归一化，令 $D=-\mathrm i\partial_x$、$W\ge0$ 为非零、有界紧支撑实函数。$a=0$、能量 $-\kappa^4$ 的自由预解式核为

$$
R_\kappa(r)=\frac{1}{2\sqrt2\,\kappa^3}
 e^{-\kappa|r|/\sqrt2}
 \left(\cos\frac{\kappa|r|}{\sqrt2}+\sin\frac{\kappa|r|}{\sqrt2}\right).
$$

有限 $r$ 上其展开是

$$
R_\kappa(r)=\frac{1}{2\sqrt2\kappa^3}
-\frac{r^2}{4\sqrt2\kappa}
+\frac{|r|^3}{12}+O(\kappa |r|^4).
$$

设 $w=\sqrt W$，$Q$ 为 $L^2(\operatorname{supp}W)$ 中 $w^\perp$ 的正交投影。对满足 $\langle f,w\rangle=0$ 的 $f$，$-(x-y)^2$ 的压缩给正秩一项：其二次型等于 $2|\int xw(x)f(x)\,dx|^2$。故 Birman–Schwinger 算子除了 $\kappa^{-3}$ 主方向，还存在 $\kappa^{-1}$ 方向；只投影出第一条模态会漏掉它。

**这一小尺度核查支持的推断**：第一条能隙为 $\varepsilon^{4/3}$；若 $\|Q(xw)\|>0$，第二条应在 $\varepsilon^4$ 尺度。这里非零有界函数的正测度支撑保证该方差非零。该推断仍需用 Schur 补/余项界形成完整计数；本报告没有把这个自由四阶核的检查升级为周期连续 PDE 定理。Python 仅用标准库有理数独立核了 $e^{-z}(\cos z+\sin z)$ 的前六个 Taylor 系数 $(1,0,-1,2/3,-1/6,0)$，没有新文件或大计算。

对于 $a>0$，在零能阈值去掉发散常数方向后，$D^4+aD^2$ 的预解式核可取

$$
-\frac{|r|}{2a}-\frac{e^{-\sqrt a|r|}}{2a^{3/2}},
$$

忽略被 $Q$ 消去的常数，其 $a\downarrow0$ 主项为 $-r^2/(4\sqrt a)$，在 $Q$ 上给 $\|Q(xw)\|^2/(2\sqrt a)$ 的正方向。因此第二条模态的临界比较是 **$\varepsilon/\sqrt a$**，提示另有 **$a\asymp\varepsilon^2$** 的转变区。它与主模态的 $a\asymp\varepsilon^{2/3}$ 完全不同。

这不是一个应继续“优化误差”的局部问题，而是主稿 B 值得保留与否的**机制淘汰门**：若既有 Arazy–Zelenko 或后续联合参数定理已经给出这两个尺度的全部谱分类，则 B 可能只剩 Bloch 适配，应降级；若没有，目标应明确是保留两尺度弱模态的统一计数，而不是只写一个四阶包络。

还须修正两处容易产生假统一性的地方：

1. 对真实 $E(q;a)$，两个负 $a$ 极小点的精确边缘通常是 $E_0(a)-a^2/(4b)+O(|a|^3)$。只用四次正规形的边值，误差可能大于第二条更弱模态的能隙；必须围绕**精确背景带边**计数。
2. 真实周期模型若只有 $O(\varepsilon^2)$ 的全局能量近似，不能识别 $\varepsilon^4$ 能隙。需要对奇异通道逐层消去并控制适当重标度的余项；普通算子范数/能量误差阶不能代替这一点。

**可实现性门也不可省**：在 $\beta=0$、全周期零准动量的最底带，正有界标量质量模型满足 $E_1(q;0)=q^2/\langle\rho\rangle+O(q^4)$，二次系数严格正。因而不能在这个最容易的底带点调出四次主导。B 必须明确选较高带或非零固定 $\beta$ 的投影切片，并建立所需对称性和其他边点隔离。这里没有证明一般正密度类不能实现四次边。

### 8.2 C：“保持密度正性”本身不是强的材料限制

若 $\rho_0\ge c>0$，允许任意有界、实、横向紧支撑 $W$，则 $\rho_0+\varepsilon W>0$ 对足够小的 $\varepsilon$ 自动成立。**正性不等于扰动 $W\ge0$**，也不限制其首阶切空间。因此“只使用正密度材料”不能单独区别于一般实局部零阶势的调参理论。

C 真实还可能有价值的差别是：**固定 $\beta$；初始对象是非 $L^2$ 的完整内部阈值态；同时保留周期端的传播通道；扰动受指定几何/有限参数/符号锥约束。** 若这些都放松，单纯“辐射消去条件的余维等于可调参数数目”的方向已有大量直接先例。需要明确可调集合，才有可证伪的可实现性问题。

独立新增的直接近邻：

- Lijun Yuan, Ya Yan Lu. **Parametric dependence of bound states in the continuum on periodic structures**. *Physical Review A* 102 (2020), 033513. DOI [10.1103/PhysRevA.102.033513](https://doi.org/10.1103/PhysRevA.102.033513)；[arXiv:2007.15173](https://arxiv.org/html/2007.15173)。检视正文未编号主命题（式(7)–(8)后）及补充材料式(S27)：真实介电函数的两个独立、紧支撑扰动，单独立辐射通道、非退化 BIC 及非零耦合条件下，调一参数得到 BIC 曲线。其 $k,\beta$ 都可漂移，初态是真 BIC、外部均匀，不能当固定 $\beta$ 周期内部阈值问题的完整覆盖，但**余维/调参思想已明确存在**。建议 `Yuan2020.pdf`。
- Lijun Yuan, Ya Yan Lu. **On the robustness of bound states in the continuum in waveguides with lateral leakage channels**. *Optics Express* 29 (2021), 16695–16709. DOI [10.1364/OE.424671](https://doi.org/10.1364/OE.424671)；[arXiv:2012.15506v1](https://arxiv.org/html/2012.15506v1)。检视引言及主结果所在 §IV 的定位：一横向辐射通道、左右镜像条件下有全阶扰动鲁棒性分析。主条件尚未逐项核完，不引用为当前结论。建议 `Yuan2021.pdf`。
- Lijun Yuan, Ya Yan Lu. **Structural perturbation theory for bound states in the continuum via bifurcation of zeros and extrema of the dispersion relation**. 2026，[arXiv:2608.28321v1](https://arxiv.org/html/2608.28321v1)，28 August 2026。检视 §II 模型及单开放衍射级假设、§IV 分类结构；原文分析 BIC/共振色散的 Taylor/Puiseux 结构，不是任意周期带阈值通道的定理。它使“在结构参数下数零点、裂分、余维、标度”也不能直接认领为新意。建议 `Yuan2026.pdf`。

**C 的最小下一步**不应先证明某个大范围存在定理：固定一个完整阈值态，列出允许扰动基函数 $W_1,\ldots,W_p$，对所有独立传播通道的耦合积分取实化矩阵（须先处理互易/反射约束及通道归一化），检查其秩、所需阈值调谐方向是否独立、以及允许参数是线性空间还是只能取一侧的锥。首阶秩满也只给后续 Lyapunov–Schmidt/隐函数论证的候选条件，不是全阶消辐射完成。

### 8.3 当前最终研究价值排序建议

- **A 保留第一**：目标压缩为异质周期远场的 gap 内非平坦性，输运作后续推论。先补查 Fliss 2013 的明确异质扩展、2021 周期出口与 Filonov 类结果，再做复 Bloch 拼接的关键门；找到直接覆盖即停止。
- **B 保留第二，但不称已成立的新项目**：先证明真实正标量质量材料可实现所选孤立四次投影边；再核既有高阶虚特征值理论是否覆盖 $a\sim\varepsilon^{2/3}$ 和 $a\sim\varepsilon^2$ 两尺度。只得到 $4/3$ 律应淘汰。
- **C 继续高风险备用**：应把“正密度”收窄成真正有限的材料可调集合，保留固定 $\beta$ 与非 $L^2$ 内部阈值这一差别；不承诺短期新定理。

本报告初筛 A/B/C 的字母仅用于第 3 节独立候选；本节 A/B/C 专指主稿新版的排序，二者不可混用。建议最终简报直接用问题名称，避免字母指代冲突。

## 9. 交接验收（15:18 前）

任务模式仍为 **Review only**。输出只有本文件；被审主稿、现有理论、证书和源码均未修改，没有新 theorem/proof 环境或编号。工作树检查只见主研究者规划和本复核两个新文件，暂存区为空；本复核没有提交、push、MATLAB、依赖安装、私有远端访问或大实验。唯一计算是 §8.1 已记录的六项有理 Taylor 系数核查，无新计算文件。

最有用的交接不是“已发现三个开放问题”，而是三条可执行否证门：**异质端非平坦性是否真的缺少已有覆盖；合并边缘是否真的可在正标量材料实现且需两个尺度；固定 $\beta$ 内部阈值的材料约束是否真的比任意实零阶扰动更窄。**

文献状态：**Preliminary review; literature verification is incomplete.** 所有文献均在线阅读，未下载；§4、§6.4、§7、§8.2 分别记录原文核查深度、稳定链接、结果编号或未编号位置、建议归档名。Fliss–Joly–Lescarret 2021 的 HAL 取文遭访问防护拒绝且未绕过；这是一个来源核验缺口，不阻止本轮方向筛选交付。其余未读全文/未核技术假设已逐条标记，不据此断言开放性、首创性或完整定理覆盖。
