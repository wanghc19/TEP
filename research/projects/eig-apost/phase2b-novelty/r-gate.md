<!-- Search-bounded novelty gate for the eig-apost candidate contribution -->

# Phase 2b novelty gate

日期：2026-07-27。

## Verdict

**`PASS WITH CONDITIONS`**。

截至本次检索边界，没有发现单篇论文或同一研究系列同时覆盖以下完整链条：

> fixed-$\beta$ periodic line-defect guided-mode eigenvalue
> $\rightarrow$ BIE cell boundary map
> $\rightarrow$ numerical half-guide DtN truncation
> $\rightarrow$ computable eigenvalue-shift estimator
> $\rightarrow$ simple-root effectivity on independent reference truth。

这个结论只说明目前存在一个值得低成本继续验证的窄缺口，不证明方法正确，也不构成
“首次”或“没有已有工作”的优先权证明。详细逐项证据见
[[research/projects/eig-apost/phase2b-novelty/claim-matrix|claim matrix]] 和
[[research/projects/eig-apost/phase2b-novelty/r-sources|source verification]]。

## 1. 链条与 C1--C6 的具体含义

### 1.1 先区分三个“特征值”

为避免把 DtN 截断误差、BIE 离散误差和物理真误差混在一起，本项目需要区分：

1. $k_*$：连续无限线缺陷晶体的真实 guided-mode eigenvalue；
2. $k_{\infty,h}$：固定 BIE boundary discretization、port space 和线性代数设置后，
   使用该离散层面的极限 half-guide DtN 得到的根；
3. $k_{j,h}$：同样固定其他离散，但 half-guide 只用第 $j$ 个 finite-tail/doubling
   层级时得到的根。

这里 $h$ 统称暂时冻结的 BIE 与 port discretization，$j$ 只表示 half-guide tail
refinement。这个 $h$ 只在 gate 中用于暴露误差层级；Phase 3 文件因默认固定其他离散而
省略它，所以其中的 $k_j$、$F_j$、$\delta_j$ 分别是这里 $k_{j,h}$、$F_{j,h}$、
$\delta_{j,h}$ 的简写。总误差可以形式上分解为

$$
  k_{j,h}-k_*
  =\bigl(k_{j,h}-k_{\infty,h}\bigr)
   +\bigl(k_{\infty,h}-k_*\bigr).
$$

第一项是本阶段优先估计的 **DtN/infinity-treatment error**；第二项包含 BIE quadrature、
port truncation 和其他冻结误差。只有后者经独立 refinement 证明确实更小，第一项的
estimator 才能近似解释为总的 $k$ 误差。否则论文必须明确说它只估计 DtN contribution。

### 1.2 C1：固定 $\beta$ 的线缺陷导模特征值

固定传播方向的准周期参数 $\beta$，把波数 $k$ 当作待求谱参数。对无限线缺陷晶体，
真实导模是在横向无限方向衰减、满足 $\beta$-准周期条件的非零场。消去左右无限周期
半波导后，可以示意写成

$$
  F\bigl(k;\Lambda_-(k),\Lambda_+(k)\bigr)u=0,
  \qquad u\neq 0,
$$

其中 $\Lambda_-$、$\Lambda_+$ 是精确左右 half-guide DtN，$F(k)$ 是频率依赖的
nonlinear eigenvalue operator。C1 问的是“我们的物理对象和固定-$\beta$ 扫描 $k$
设置是否已有先例”，不是误差估计。Fliss 系列已经覆盖这一层，所以 C1 是背景。

还必须区分 $F(k)$ 的根与实轴扫描得到的 $\sigma_{\min}(F(k))$ 极小点。后者只说明某个
矩阵在当前 scaling 下接近奇异，不能单独给出根的位置误差，也不保证附近存在实根。

### 1.3 C2：由 BIE cell map 连接到 half-guide boundary map

对一个无缺陷 bulk cell，在固定 $k$ 和 $\beta$ 下用 BIE 解多个 port right-hand sides，
得到 cell scattering/trace map $S_h(k)$。现有 `A_QP` 在这一步只充当 one-cell BIE
component：它处理 inclusion-boundary transmission，但不是整个 line-defect
eigenoperator，也不是 DtN 的定义。

C2 要求说明如何从 $S_h(k)$ 形成半无限周期端在中心截面上看到的 DtN/RtR/NtD map，
并保持左右端口、法向号和 trace space 一致。BIE cell map 与 half-array Riccati 的相近
构造已有文献先例，因此 C2 最多是针对当前介质与代码接口的适配。

### 1.4 C3：structure-preserving finite-tail / doubling hierarchy

精确 half-guide 包含无穷多个周期 cell，不能直接存成有限矩阵。第 $j$ 层把
$N_j=2^j$ 个 bulk cells 的 scattering maps 递归组合，在远端施加冻结的 Dirichlet 或
real Robin closure，再得到

$$
  \Lambda_{-,j,h}(k),\qquad \Lambda_{+,j,h}(k).
$$

期望它们在 lead multipliers 远离单位圆时趋向离散极限 maps
$\Lambda_{\pm,\infty,h}(k)$。`doubling` 的含义是每次把 tail cell 数从 $N_j$ 变成
$2N_j$，不是把扫描点数加倍。

`structure-preserving` 在这里表示：对实材料和实 $k$，有限层 closure 应尽量保持原
eigenproblem 的实谱/自伴对称结构，使 $k_{j,h}$ 可以作为实根追踪。若直接采用会造成
人工泄漏的 zero-incoming closure，有限层真根可能进入复平面；此时实轴
$\sigma_{\min}$ 极小点不能冒充 eigenvalue sequence。finite-tail、Riccati 和 doubling
本身也已有先例，所以 C3 不是单独创新点。

### 1.5 C4：从 numerical DtN error 得到可计算的 $k$-shift estimator

把第 $j$ 层左右 DtN 接到 defect-cell BIE 后得到近似 NEP

$$
  F_{j,h}(k)u=0,
$$

并经 root qualification 得到实际根 $k_{j,h}$。C4 的目标不是再观察
$\|\Lambda_{\pm,j+1,h}-\Lambda_{\pm,j,h}\|$ 变小，而是从当前计算已经产生的矩阵、
根、左右零向量和导数，给出一个数 $\eta_{j,h}$，预测

$$
  \bigl|k_{j,h}-k_{\infty,h}\bigr|
$$

的量级。这就是 `computable a posteriori estimator` 在本项目中的含义：它应由已算
数据求出，不包含未知的真实根、精确特征函数或无法定量的常数。

Bonnet-Ben Dhia--Gmati (1995) 已对光纤 exact Fourier boundary operator 的截断证明
$C/N^{2s}$ 型特征值先验界。这说明“boundary/DtN truncation 会导致可控的 eigenvalue
error”不是新问题；但未知常数 $C$ 不能从本次数值结果直接得到，因此仍不同于本项目
希望构造的 posterior estimator。C4 的可辩护范围必须明确限定为 periodic half-guide
numerical DtN error 的可计算 $k$-shift 估计。

### 1.6 C5：simple-root projected correction 与 effectivity

#### 什么是 simple root

设 $k_{j,h}$ 已被确认是 $F_{j,h}$ 的根，并取单位范数的右、左零向量
$x_{j,h}$、$y_{j,h}$：

$$
  F_{j,h}(k_{j,h})x_{j,h}=0,
  \qquad
  y_{j,h}^*F_{j,h}(k_{j,h})=0.
$$

在 $F_{j,h}$ 关于 $k$ 局部解析且为 regular matrix function（即行列式不恒为零）的
有限维 NEP 中，本项目采用下面的可检查判据：零空间和左零空间均为一维，并且根沿
$k$ 方向横截零：

$$
  y_{j,h}^*F_{j,h}'(k_{j,h})x_{j,h}\neq 0.
$$

最后这个非零量是局部 spectral slope。若它很小，哪怕 DtN map 只改变一点，根也可能
移动很多；若它为零或存在重根，一阶标量 correction 一般不再有效，需要多重特征值或
invariant-subspace 理论。

#### 什么是 projected correction

相邻层级只改变 half-guide DtN。把 operator change 投影到当前左右零向量，并除以
spectral slope，得到一阶预测

$$
  \delta_{j,h}
  =-
  \frac{
    y_{j,h}^*\bigl(F_{j+1,h}(k_{j,h})-F_{j,h}(k_{j,h})\bigr)x_{j,h}
  }{
    y_{j,h}^*F_{j,h}'(k_{j,h})x_{j,h}
  }.
$$

分子测量“DtN refinement 在目标 eigendirection 上造成多大 operator perturbation”，
分母把这个纵向 residual 换算成横向的 $k$ 位移。因此 $|\delta_{j,h}|$ 比单独观察
$\sigma_{\min}$ 更接近用户真正关心的“$k$ 差多少”。在没有额外 tail 证据时，
$\delta_{j,h}$ 首先只预测相邻根位移

$$
  k_{j+1,h}-k_{j,h},
$$

不能直接宣称它等于到 $k_{\infty,h}$ 的剩余误差。

#### 什么是 effectivity

令候选 estimator 为 $\eta_{j,h}=|\delta_{j,h}|$，并用足够可信的 reference root
$k_{\mathrm{ref}}$ 定义实际误差。effectivity index 是

$$
  \mathcal I_{j,h}
  :=\frac{\eta_{j,h}}{|k_{j,h}-k_{\mathrm{ref}}|}.
$$

$k_{\mathrm{ref}}$ 的目标层级必须在表格中明示：若评价纯 DtN contribution，它应高精度
逼近 $k_{\infty,h}$；若评价相对连续物理真值的总误差，它应逼近 $k_*$，且必须另证
$|k_{\infty,h}-k_*|$ 不会主导分母。前一种 reference 可以检查 estimator 的内部逻辑，
后一种才足以支撑“计算出的 $k$ 有多少位可信”的完整外部结论。

- $\mathcal I_{j,h}\approx 1$：estimator 与真实误差同量级且常数接近正确；
- $\mathcal I_{j,h}\ll 1$：严重低估误差，结果会显得比实际更可信；
- $\mathcal I_{j,h}\gg 1$：明显高估，可能仍保守但数值信息较弱；
- $\mathcal I_{j,h}$ 随 refinement 无规律漂移：尚未进入渐近区，或 estimator 模型错误。

`simple-root effectivity` 是本项目为了描述候选贡献使用的缩写，不应冒充文献中已经
统一定义的专门术语。它不是“找到了一个简单根”，而是两个条件的合称：

1. 根确实简单，使 projected first-order correction 有数学意义；
2. 随 DtN refinement，$\eta_{j,h}$ 与实际 root error 的比值保持在有用的 $O(1)$
   范围，理想情况下趋于 $1$。

若能证明

$$
  \frac{|\delta_{j,h}|}{|k_{j,h}-k_{\infty,h}|}\longrightarrow 1,
$$

就称 estimator 对 DtN error **asymptotically exact**。若只能证明比值夹在两个与 $j$
无关的适中常数之间，则仍是 quantitative estimator，但不是严格渐近精确。effectivity
是对 estimator 质量的评价，不等同于 certified upper bound；本项目目前也不把严格
上界作为首要目标。

### 1.7 C6：独立 reference truth 为什么仍在链条中

C6 不单独构成理论创新，但决定 C5 能否被可信验证。$k_{\mathrm{ref}}$ 优先来自两个实质
独立方法给出的相同有效数字，或一篇可靠文献对完全相同 benchmark 报告的数据。由同一
BIE cell map 得到的 doubling、Riccati 和 QZ 结果只能交叉检查 infinity-treatment
algebra，不能发现共同的 BIE/port error，因此不算完整独立真值。

整个链条可以压缩为：C1 规定“求哪个 $k$”，C2 产生一个 cell 的 boundary response，
C3 用有限数据逼近无限周期尾，C4 把 DtN change 换成可计算的 $k$ 误差数值，C5 说明
这个数是否真的与 root error 同量级，C6 提供检验 C5 所需的可信真值。

## 2. 已被已有工作覆盖的部分

- **C1 是背景。** Fliss (2013)、Fliss--Klindworth--Schmidt (2015) 和 Klindworth
  (2015) 已建立 fixed-$\beta$ 线缺陷导模的 DtN/RtR 非线性特征值 formulation 和
  数值求解框架。
- **C2--C3 的部件不是独立创新。** Yuan--Lu--Antoine (2008)、Yu et al. (2022) 与
  Petropoulos--Turc (2025) 已覆盖 BIE cell map、半无限周期阵列 boundary map、
  Riccati 或 recursive doubling 的相近组合；透明边界文献也已给出有限元版本。
- **开放导模特征值的截断误差不是空白。** Bonnet-Ben Dhia--Gmati (1995) 已给出
  exact Fourier boundary operator 截断下的超代数特征值误差界；Djellouli et al.
  (2000)、Choutri (2008) 和 Boureghda et al. (2022) 又覆盖局部边界条件、数值比较和
  指数型先验界。
- **一般特征值 estimator 与 DtN 截断分析均有先例。** Giani (2013)、Engström et al.
  (2016) 和 Gopalakrishnan et al. (2025) 已覆盖 photonic/fiber eigenvalue estimator、
  DWR 或 effectivity；Xi et al. (2024) 已连接 DtN Fourier 截断与 holomorphic NEP
  特征值误差；Lin--Lv (2025) 已在周期散射中给出可计算的 DtN truncation 后验项。

因此，BIE、DtN、RtR、doubling、最小奇异值扫描、simple-root perturbation、一般
photonic-crystal eigenvalue estimator 或“截断误差随层数下降”都不能单独作为论文
创新点。

## 3. 当前最小可辩护贡献

候选贡献必须收窄为：

> 对远离 Wood anomaly、lead spectrum 与单位圆分离且根为孤立简单点谱的
> fixed-$\beta$ periodic line-defect guided-mode BIE NEP，构造一个**可计算的**
> numerical half-guide DtN truncation eigenvalue-shift estimator；说明其与
> simple-root projected correction 的关系，并用独立 formulation 或可信参考数据验证
> 误差量级和 effectivity。

在这个表述中：

| 环节 | 门控后的地位 |
|---|---|
| C1：fixed-$\beta$ line-defect guided mode | 已知问题设置 |
| C2：BIE cell map / half-guide boundary map | 已知部件的适配与实现 |
| C3：finite-tail / doubling hierarchy | 已知部件的结构保持适配 |
| C4：numerical DtN error 到 $k$-shift 的 computable estimator | 候选核心贡献 |
| C5：simple-root correction 的量级有效性或 effectivity | 候选核心贡献 |
| C6：独立 reference truth | 发表证据门槛，不是理论创新 |

只有 C4 与 C5 在 C1 的精确问题上被真正关闭，才足以形成当前预想的论文主张。把已知
组件集成成求解器、只画 convergence curve，或只说明哪个结果更可信，都不够。

## 4. 允许与禁止的 novelty wording

允许使用的暂定表述：

- “We investigate a computable estimator for the eigenvalue shift induced specifically by
  numerical half-guide DtN approximation in a fixed-$\beta$ line-defect BIE formulation.”
- “Our search found no verified source covering this complete intersection as of
  2026-07-27.”

在剩余条件闭合前禁止使用：

- “the first a posteriori estimator for photonic-crystal guided modes”；
- “the first BIE--DtN method for line-defect eigenvalues”；
- “no previous work estimates truncation errors in guided-mode eigenvalues”；
- 任何没有 search boundary 的“首次”“从未研究”或 “novel”绝对表述。

## 5. Devil's-advocate checkpoint

### Critical risks

1. **核心量可能最终只是同一离散层级的差值。** 若 $\eta_{j,h}$ 只复述
   $|k_{j+1,h}-k_{j,h}|$，却不能在可检验假设下预测
   $|k_{j,h}-k_{\infty,h}|$ 的量级，则它仍是 convergence indicator，不是目标
   DtN estimator。
2. **reference truth 可能不独立。** doubling、Riccati 和 QZ 若共享同一个 BIE cell
   map，只能验证半波导代数，不足以验证绝对 $k$ 误差。

### Major risks

1. 未知常数很大的可靠性上界可能形式严格但数值无用；论文价值依赖可计算性与实际
   effectivity，而不是只存在一个宽界。
2. projected correction 只有在确认为离散 NEP 的 simple root、分母不退化且 root
   residual 足够小时才有意义；$\sigma_{\min}$ 平台本身不能代替 root qualification。
3. BIE boundary error 当前被有理由地延后，但不能永久忽略。固定饱和 DtN 后若改变
   boundary nodes 导致两位有效数字漂移或非单调恶化，必须重新打开 BIE 误差预算。

### Minor risks

- 非 Wood、远离单位圆和简单根的限制使首篇论文范围较窄，但这是可接受且必要的
  第一阶段边界，不构成 gate failure。

这些反方风险不触发 `REVISE` 或 `STOP`，因为尚未发现覆盖 C1--C5 的直接先例；它们
解释了为何 verdict 只能是 `PASS WITH CONDITIONS`。

## 6. 继续研究的条件

1. Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al. (2000) 已完成全文核验；继续等待
   Leclerc et al. (2026) 的 HAL accepted manuscript 在 2026-12-15 解禁。在此之前不
   对该文作全文级否定，也不冻结 priority claim。
2. 在投稿前至少再做一次以 Fliss (2013)、Klindworth (2015)、Choutri (2008)、
   Boureghda et al. (2022)、Xi et al. (2024) 和 Gopalakrishnan et al. (2025) 为种子的
   forward citation update。
3. Phase 3 首先调查 C4--C5 的最小离散命题：map perturbation、simple-root transfer、
   computable remainder 或可验证的 saturation/tail condition；不能预设现有理论命题
   正确。
4. reference truth 必须满足至少一项：两种实质独立方法给出相同有效数字，或可靠文献
   对同一 benchmark 报告经核验的高精度数据。共享同一 cell map 的交叉检查只能算
   partial evidence。
5. 在任何 estimator effectivity 实验前，必须先通过 root qualification，并单独检查
   BIE boundary refinement 是否已经饱和。

## 7. 阶段决定

Phase 2b 到此完成。允许进入**受条件约束的 Phase 3 低成本理论与验证设计**，优先
回答 C4--C5 是否可能成立、独立参考值如何获得以及哪些失败条件会使 estimator 降级。
当前不创建或续写 `research/mainline/`，不修改 MATLAB，不把 provisional formula
写成定理，也不开始批量生产论文数值结果。

若后续全文发现已有工作实质覆盖 C1--C5，或候选量无法超越 convergence indicator，
应立即把 gate 改为 `REVISE` 或 `STOP`，而不是通过扩展措辞维持原选题。

## 8. 检索边界

- 最后检索日期：2026-07-27。
- 记录范围：本地 corpus、出版社/DOI/机构仓储、arXiv 与公开学术索引，以及核心来源
  的 backward/forward citation chasing。
- 累计 gate-relevant unique records：19。
- 原文级本地全文核验：14；出版社全文或 primary text 核验：3；仅摘要/元数据级：2。
- 保留在 claim matrix 的核心或近邻来源：17。

详细计数和查询族见
[[research/projects/eig-apost/phase2b-novelty/search-log|search log]]。
