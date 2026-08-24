# I3：连续特征值误差估计与上界研究

## 阶段定位

I2 已为连续波导问题提出一个可复现的实轴 numerical candidate，并从局部复平面计数、
Hermitian part 的端点符号计数以及两条单轴离散实验三个角度检查了它的可信度。I2 没有给出
candidate 到真实连续特征值的误差，也没有给出收敛阶或误差上界。详细交接见
[[research/projects/eig-apost/implementation/i2/report|I2 stage report]]。

I3 先研究一个不要求命名唯一 mode 的误差。记 I2 在离散层 $h$ 上实际保存的 candidate 为
$\widehat k_h$，暂记 $G_\lambda\subset(0,\infty)$ 为后续须针对当前模型认证的 continuous
projected essential gap，并定义其中的正离散特征频率集合

$$
\mathcal K_{\mathrm{disc}}(A;G_\lambda)
:=\{\sqrt{\lambda}:\lambda\in\sigma_{\mathrm{disc}}(A)\cap G_\lambda\}.
$$

约定到空集的距离为 $+\infty$。因此在当前 continuous projected gap 和其中离散谱的存在性
尚未建立时，这个定义不会预设目标集合非空。

第一层目标是

$$
e_h^{\mathrm{gap}}
=\operatorname{dist}\bigl(\widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)\bigr).
$$

这表示 candidate 到 gap 内某个真实连续离散特征值的误差；它不预先指定该特征值的名字。
只有后续确实需要跟踪特定 mode 时，才定义第二层 target-specific error

$$
e_h^*=|k_*-\widehat k_h|.
$$

本阶段不把有限维矩阵的精确零点、层间漂移、矩阵残差或某个修正公式本身当成最终成果。
这些量只有在能够帮助估计上述连续谱误差时才进入主线。I3.1 已完成四个正式负向实验，并由
纯 BIE 边界残量路线首次形成一个可计算但 `NUMERICALLY_UNQUALIFIED` 的 indicator candidate；
qualified estimator、independent reference 与严格上界仍须分别建立和审查。

长期对象门如下：每个新增主线对象和 hard gate 都必须写出它如何进入第一层集合距离或可选
target-specific error 的估计链；若它
只描述 finite root、score minimizer、层间矩阵差或实现内部一致性，就降为 `OPTIONAL` 或
quality diagnostic。Skeptic 在每次 design/revision 审查中都必须重新执行这项对象检查。

I3 由三个正式里程碑组成。三个是科学问题决定的数量，不是为了满足阶段数而拆分；误差来源
识别、reference 搜索、术语整理和文档交接都不是独立里程碑。

| Milestone | 独立科学问题 | 核心输出 | 当前状态 |
|---|---|---|---|
| I3.1 | 能否从实际计算量构造并内部论证一个与 continuous gap-spectrum distance 有关的可计算指标？ | 冻结的 $\eta_h$、适用假设、覆盖/忽略的误差及内部检查结果 | `ACTIVE / NUMERICALLY_UNQUALIFIED INDICATOR CANDIDATE / I3.2 NOT READY` |
| I3.2 | 冻结后的 $\eta_h$ 能否在未参与其构造的独立 reference 上跟踪真实误差的量级？ | independent-reference comparison 与 empirical estimator verdict | `NOT STARTED` |
| I3.3 | 能否在没有未知常数的条件下把已经验证的估计升级为可计算上界？ | $U_h$ 或 `UPPER_BOUND_UNAVAILABLE` | `NOT STARTED` |

## 从 I2 接收的输入

I3 接收的是 candidate 及其质量证据，而不是已经成立的误差估计：

- I2 在两条预先冻结的离散轴上均保存了同一个 candidate
  $\widehat k_h=1.832770289108157$；
- 相邻离散层通过了公共 Fourier 系数、边界 trace 和固定物理采样点上的 mode identity 检查；
- 原矩阵 residual、backward error、near-null separation、factor、field、boundary、repeat 与
  selector-gauge 等诊断已经记录；
- terminal cell half-width 只描述连续 score minimizer 的搜索分辨率，不是 $\widehat k_h$ 的
  uncertainty，也不是 continuous-eigenvalue error 的上界；
- 两条轴的 observed candidate shift 都是零。这是有用的稳定性事实，但不能单独产生非零
  correction、收敛阶、effectivity 或真值误差界。

I3 还必须面对 I2 尚未解决的 continuous--discrete 问题，包括半波导近似、边界积分表示、
Rayleigh/Fourier 截断、边界离散、QZ 子空间、有限精度求解以及从离散矩阵到连续物理算子的
关系。哪些误差进入 $\eta_h$、哪些暂时忽略，必须在 I3.1 随具体公式一起说明，不能先验地把
全部误差相加成一个没有数学来源的“总误差账本”。

## I3.1 当前理论选择与实验结果

现行分析见 [[research/projects/eig-apost/phase3-analysis/README|Phase 3 analysis]]。I3.1 直接在
算法保存的 $\widehat k_h$ 处研究连续物理残量。一般主线仍是：从 I2 数据重构非零的
continuous form-space field $u_h^{\mathrm c}$，令 $\mu_h=\widehat k_h^2$，并对连续 form
$a$ 定义

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h(u_h^{\mathrm c},v)_H.
$$

首选指标来自 normalized dual norm

$$
q_h=\frac{\|R_h\|_{V'}}{\|u_h^{\mathrm c}\|_V}.
$$

对 nonnegative self-adjoint operator，谱定理把 exact $q_h$ 直接联系到 $\mu_h$ 与某个
continuous spectral point 的距离。若进一步得到可靠 residual interval，且它完全位于当前
continuous operator 的 projected essential gap 内，则区间中至少存在一个孤立、有限重的离散
特征值。正式设计还必须在看结果前冻结可接受的 $k$-分辨率及一个小于一的 gap-relative
宽度比例；区间既要小于绝对分辨率，也不能几乎占满整个 gap。区间过宽时只能保留存在性，
不能称为达到项目分辨率的结果。把该谱值识别为某个指定 $k_*$ 是独立的第二层可选升级，不是
residual 计算或第一层存在性的前置 blocker。近似 Riesz solve 也不自动给 dual norm 上界，
所以 I3.1 首先冻结 continuous-residual estimator candidate 与上述两层解释合同，I3.2 再独立
验证，I3.3 才研究可靠 enclosure。

首个冻结实验 [[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 利用了当前
模型中心空列的特殊结构：从 I2 的 Fourier 墙系数构造空列中的显式场 $u_0$，乘以固定
$\chi(x)=\cos^2(\pi x)$ 后在单胞外延零。这个场属于连续强算子的定义域，因而可以直接计算

$$
\eta_h^{\mathrm s}
=\frac{\|(A-\mu_h)\chi u_0\|_H}{\|\chi u_0\|_H}.
$$

正式 `center-a1` 得到 $\|\chi u_0\|_H=0.840017038309255$、残量范数
$18.848991951433035$ 和 $\eta_h^{\mathrm s}=22.43882099031153$。三个积分层稳定，但普通
双精度积分不是可靠上包络；更关键的是，残量由固定单胞 cutoff 的导数项主导，名义
$\lambda$ 区间跨过零且远宽于预注册 $10^{-6}$ 频率分辨率。因此本实验只交付一个可复现的
连续强残量负向 baseline，当前解释为
`FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`；它不支持 continuous projected gap 内离散特征值
存在，也尚不能进入 I3.2。

历史 V1 路线由 frozen wall states 生成左右无限序列，并用 one-cell BIE 内外场拟合显式
Fourier--Hermite/bubble trial。正式 `lead-a3` 通过 finite input、density representation 和
frozen-$Z$ propagation，
但固定 fit 的独立 holdout error 在 $J=4$ 已约为 $4.522421$，到 $J=8$ 增至约
$5.138028$，远高于预注册 $0.20$。producer 因而在
`CONFORMING_RECONSTRUCTION_UNRESOLVED` 首败处停止；center correction、Grams、quadrature、
infinite tail 和 strong-residual ratio 均为 `NOT_REACHED`。

training/holdout targets 到材料圆的最小距离仅为 $4.22\times10^{-5}$ 与
$5.32\times10^{-5}$，约为 $N=256$ source-panel arc scale 的 $0.86\%$ 与 $1.08\%$；direct
close layer-potential evaluation 尚未单独资格化。因此现有证据不能把失败单因归咎于 bubble
basis，只能说当前 pipeline 未建立 BIE-informed shape quality。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1b|review-3-1b]]。V1 收尾时一般
continuous weak residual 仍是后备；当前 V2 已将其选为主线。exact-DtN center residual、
finite common-space transport、nearby simple
zero、matrix derivative 与 bordered conditioning 继续只属 OPTIONAL。不得自动调 basis/grid、
修改阈值或运行下一 attempt。

当前 [[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]] 已在保留 Git
历史的前提下重写为 V2：从同一 frozen QZ wall traces 出发，用真实材料的 conforming Q1
Dirichlet cell extension 形成全局 $H^1$ trial，再以 global RT0 flux 和 functional majorant
直接构造 continuous weak residual。正式 `weak-a1` 已完成：finite input、frozen-$P$
propagation、coarse/fine Q1--RT0、base Grams 与 full-$P$ tails 均通过；fine phase/scale repeat
随后因 center 的 $A,B$ Gram 及左右 first-cell 的 $A$ Gram 的 Hermitian defect 超过
$10^{-12}$ 而停止，最大 defect 为
$6.2442\times10^{-10}$。producer 状态为 `I3_1_MAJORANT_QUADRATURE_UNRESOLVED`，独立 verdict
为 `POST-RUN PASS / VALID NEGATIVE`。本 attempt 没有形成 scaled tail、refinement 或最终
estimator；独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1c|review-3-1c]]。

对历史 V2，遗留下一门是 scale-covariant Gram qualification。即使关闭该门，base coarse/fine 的
$B/\gamma$ component change 约 $0.277>0.20$，fine nominal width 约 $0.564\gg10^{-6}$；
mesh qualification 与有用分辨率仍未闭合。因此 I3.1 继续活动，I3.2 不可开始。

现行 V3 设计
[[research/projects/eig-apost/implementation/i3/design-3-1d|design-3-1d]] 已获 Researcher
`AGREED` 与 Skeptic `DESIGN PASS`。它以真实 one-cell BIE incoming data、安全圆/墙
collar、全局 conforming Q1 companion、RT0 functional majorant 和 full-$P$ tail 重建弱残量。
历史 `bie-a1` 在进入 evaluator 前因旧接口字段缺失而停止；`bie-a2` 通过 safe-field evaluation
后因 MATLAB 转置结果索引语法而在 Q1 前停止。两个实现失败均以 append-only output 保留，且
Revision A/B 没有改变科学对象、参数、阈值或资源合同。

正式 `bie-a3` 已完成。finite input、branch/Wood、左右 propagation/scattering closure、BIE
density、one-sided surface trace 和 safe circle/wall evaluation 均通过。coarse Q1 maps 随后在
控制流中越过 form gate，但尚未写入 artifact；程序在第一个 coarse lead RT0-majorant factor
处停止，machine 状态为 `I3_1_HDIV_FLUX_UNRESOLVED`。失败矩阵已经含 true-circle polar
correction，而 integration-object gate 尚未先行检查，所以当前严格解释是 composite
RT0-majorant quadrature/assembly 未资格化，不能称为 $H(\mathrm{div})$ 理论失败。RT0 flux、
majorant 分量、full-$P$ tail、normalized indicator 和 prediction interval 均未形成。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]。I3.1 继续为
`ACTIVE / NO ESTIMATOR`，I3.2 不可开始。

现行纯 BIE 路线
[[research/projects/eig-apost/implementation/i3/design-3-1e|design-3-1e]] 随后取消 Q1/RT0
体网格：共享 wall Dirichlet traces 驱动 finite-density exact rectangular-Green trial，数学上的
continuous radial collar 修复 circle value jump，wall/circle/collar residual 通过 full-$P$ tails
形成归一化指标。`pbie-a1` 是 warning schema 的 implementation failure；只作 typed-empty 修复的
正式 `pbie-a2` 已完成。普通双精度结果为 $q=1.1049370224693775\times10^{-10}$，名义 $k$
区间为 $[1.8327702889056474,1.8327702893106665]$，宽度
$4.0501912934587381\times10^{-10}$。但 wall $256\to512$ change 为 $0.2302$，nonzero-mode
$T$ manufactured oracle 最大误差为 $1.4439$，circle outside-$M$ share 为 $0.5147$。这三项
内部资格问题尚未闭合，所以 estimator 还不能冻结后交给 I3.2 独立验证。512 点 continuity/H1、
residual/field/tail outward bounds 与 projected gap 也均未认证；这些属于 I3.3 的 reliable
interval 与存在性问题。独立 verdict 为
`PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`，见
[[research/projects/eig-apost/implementation/i3/review-3-1e|review-3-1e]]。I3.1 因此已有
可计算 indicator candidate，但尚无经过内部资格并冻结的 estimator，I3.2 仍不可开始。

## I3.1：构造并内部论证可计算的误差指标

### 科学问题

能否从当前计算中实际可得的矩阵、向量、residual、相邻离散层差异或其他量，构造一个数值
$\eta_h$，并说明它为什么可能反映 $e_h^{\mathrm{gap}}$；若未来启用唯一目标升级，再说明它
怎样作用于 $e_h^*$？

### 输入

- I2 保存的 candidate、同一 mode 的公共表示和最低质量诊断；
- 连续算子、离散矩阵和两者关系中已经建立的数学结构；
- Phase 1 对真值误差、独立 reference 与内部有效性的定义；
- Phase 2 对非线性特征值扰动公式、相邻层修正和 continuous--discrete 缺口的核验结果。

Phase 2 的材料说明了若干可能的数学来源，但没有交付一个可直接沿用的 estimator。I3.1 必须
根据当前对象重新选择并推导实际公式，不能仅因某个量与目标误差同量纲就把它命名为误差估计。

### 必须完成的内部论证

I3.1 把误差来源识别并入指标构造，而不另设阶段。至少要逐项说明：

1. $\eta_h$ 的公式和所有可计算输入；
2. 公式依赖的假设；当前首选 residual 路线尤其要说明 continuous form、field conformity、
   dual norm 和 residual-to-spectrum 关系；
3. 它覆盖哪些误差，例如 field reconstruction、材料界面、边界离散、Fourier tail 或
   half-guide 近似；
4. 它忽略哪些误差，尤其是尚未建立的 continuous--discrete 误差和可能的共同偏差；
5. 单位、缩放、基底和相位改变是否会不合理地改变结果；
6. 推导恒等式、简化问题、manufactured problem、相邻层自洽性或负例等内部检查是否支持该
   公式；
7. 数值舍入、field evaluation、quadrature 和 Riesz solve error 怎样与 estimator 数值本身
   区分；
8. 若形成可靠谱区间，当前 continuous projected gap 的来源和参数映射是否匹配，区间是否
   完全落在 gap 内，以及其正频率宽度是否同时不超过看结果前冻结的绝对分辨率和 gap-relative
   宽度；
9. 是否真的需要命名一个唯一 mode；若不需要，不得把连续谱唯一性或 multiplicity-one 加成
   第一层 blocker。

这些都是内部证据：它们用于检查公式是否自洽，但不能用来证明它已经跟踪未知的连续谱误差。
I3.1 不得查看 I3.2 的独立 reference 后再选择公式、调常数或改变成功判据。

### 输出与结论边界

I3.1 的输出是一份冻结的 estimator specification，包括 $\eta_h$、覆盖范围、忽略项、假设、
内部检查和适用失败条件。若没有证明

$$
e_h^{\mathrm{gap}}=O(\eta_h),
$$

就只能称 $\eta_h$ 为“渐近误差指标”或“estimator candidate”。若它只预测下一层 candidate
变化，则必须称“next-level indicator/correction”，不能称 eigenvalue-error estimator。若要
把同一关系写给 $e_h^*$，还须先完成唯一目标升级。

I3.1 完成不表示 $\eta_h$ 已经有效；它只表示一个可计算、可证伪且可以在外部数据上检验的
对象已经冻结。

I3.1 同时冻结两层结论语义：第一层在可靠区间完全位于 continuous projected essential gap 且
宽度通过预注册门时，只声称区间内至少有一个连续离散特征值；第二层只有另有连续谱隔离或
计数时才命名唯一目标。gap containment 成立但区间过宽时，报告
`EXISTS_BUT_RESOLUTION_INSUFFICIENT`；唯一身份未建立不撤销第一层。

## I3.2：用独立 reference 验证 estimator

### 科学问题

在不再改变 I3.1 公式的前提下，$\eta_h$ 是否能跟踪 candidate 到 independent reference
给出的 gap 内连续离散特征频率集合的距离，而不是只跟踪同一数值方法内部的层间变化或共同
偏差？只有 reference 还独立识别了指定 mode 时，才验证 target-specific $e_h^*$。

### 独立性的分界

I3.1 使用推导、内部恒等式、简化问题和同一计算链的自洽性；I3.2 使用 estimator 冻结后才
取得或启用的外部独立证据。若 reference 参与了公式选择、常数拟合或阈值调节，它就是校准
数据，不能再作为同一次独立验证；此时必须另有未参与校准的验证对象。

当前问题没有解析解。I3.2 应按以下优先顺序研究 reference，但本规划不预先指定具体方法：

1. 与当前 BIE/QZ 链不同的数值表述、离散方法或独立实现；
2. 两种或更多具有不同主要误差来源的方法给出的相容高精度结果；
3. 经原文核验、参数和归一化完全匹配、且给出足够复现信息的文献数据；
4. 同一方法的更高分辨率结果，仅作为后备 reference，并明确披露共享模型和离散偏差。

仅仅把同一个 one-cell map 分别交给 doubling 与 QZ/Riccati 处理，最多能交叉检查无穷端的
数值处理；由于两条链共享关键离散误差，它们不能单独充当整个连续特征值的独立 reference。

reference 自身也必须有 uncertainty 说明。若 reference uncertainty 与 candidate-reference 差异
同量级，就不能用该比较判定 effectivity；合法结果是 reference resolution 不足，而不是把
reference 当作真值。

### 输入

- I3.1 已冻结的 $\eta_h$，包括其失败条件和不允许调整的部分；
- I2 的 candidate、mode identity 与质量诊断；
- 一个或多个未参与 estimator 构造的 reference 及其 uncertainty、方法差异和参数匹配说明。

### 输出与结论边界

I3.2 比较 $\eta_h$ 与由独立 reference 近似得到的真值误差尺度，报告它是否在多个合格离散
层上保持正确量级、是否随误差共同变化，以及 reference uncertainty 是否足以解释比较。若
$\eta_h$ 只覆盖某一个误差分量，就必须先说明其他误差已经受到控制或可以忽略；否则只能验证
该分量的指标，不能把它命名为总 eigenvalue-error estimator。

只有通过这项外部检验后，$\eta_h$ 才可称为 `empirical eigenvalue-error estimator`。若失败，
I3.1 的内部一致性结果仍可保留，但名称必须退回“indicator”或“estimator candidate”；失败
原因应区分 estimator 无效、reference 不独立、reference uncertainty 过大或尚未进入适用区间。
I3.2 的通过仍不等于严格误差上界。

## I3.3：研究可计算误差上界

### 科学问题

对 I3.1 已冻结的 residual 对象，能否得到一个完全可计算的区间，先保证某个 continuous
projected-gap 离散特征频率存在，并满足

$$
\operatorname{dist}\bigl(
\widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)
\bigr)\leq U_h,
$$

且 $U_h$ 不含未知 norm constant、未计 numerical error 或凭经验选择的安全系数？

### 输入

- I3.1 冻结的 residual estimator candidate 及其覆盖/忽略项；
- 经证明的 residual dual-norm 上界、field-norm 下界和 numerical enclosure；
- 当前 sharp-disk continuous operator 的 projected essential gap、区间 containment 和在结果前
  冻结的可接受频率分辨率；
- 只有确需跟踪指定 mode 时，才额外输入 continuous spectral isolation/count；
- I3.2 的 independent-reference 结果只作经验交叉检查，不是严格上界的逻辑前提。

经验上观察到的 contraction ratio、effectivity 或同一 reference 的一致性不能替代 reliable
dual-norm/field-norm enclosure、continuous gap qualification 或预注册分辨率。

### 输出与结论边界

I3.3 的输出按强度分层：

- 给出所有量均可计算、假设逐项成立的 gap 内区间，并证明其中至少存在一个连续离散特征值；
  只有区间宽度不超过预注册尺度，才接受为分辨率级结果；
- 若另有连续谱隔离或计数，再把该特征值识别为指定 $k_*$ 并给出
  $|k_*-\widehat k_h|\le U_h$；若第一层已经成立而该附加条件缺失，则保留集合距离上界并输出
  `EXISTENCE_WITH_TARGET_UNRESOLVED`；或
- 若第一层所需的 residual-norm、field-norm、numerical enclosure 或 projected-gap 条件不能
  建立，则明确输出 `UPPER_BOUND_UNAVAILABLE`；若只缺分辨率门，则保留存在性并输出
  `EXISTS_BUT_RESOLUTION_INSUFFICIENT`。

`UPPER_BOUND_UNAVAILABLE` 是有效研究结论。它不撤销 I3.1 已完成的内部指标，也不撤销
I3.2 已通过的 empirical estimator；同样，经验 estimator 通过也不得被改写成已证明上界。
I3.2 中一般的 empirical reference uncertainty 也不能直接作为 $U_h$ 的组成项；只有当 reference
本身给出经证明覆盖 $k_*$ 的 enclosure 时，它才能进入严格上界。

## 三个里程碑之间的非循环关系

$$
\underbrace{\text{内部推导与自洽检查}}_{\mathrm{I3.1}}
\longrightarrow
\underbrace{\text{冻结后独立验证}}_{\mathrm{I3.2}}
\longrightarrow
\underbrace{\text{上界条件与可计算 enclosure}}_{\mathrm{I3.3}}.
$$

- I3.1 不能用 I3.2 的 reference 调公式后，再把同一 reference 当独立验证；
- I3.2 不能把同方法高分辨率结果默认当作无偏真值；
- I3.3 不能用 observed effectivity 代替 reliable norm enclosure、continuous projected-gap
  qualification 或预注册分辨率；若启用唯一目标升级，也不能代替 continuous spectral count；
- 后一里程碑失败不追溯撤销前一里程碑已经在其结论强度内成立的结果。

## OPTIONAL

以下工作只有在三个主里程碑实际需要时才升级，不构成独立 stage：

- 额外参数、第二 mode、跨环境 parity 或泛化实验；
- exact finite Hermitian/Lagrangian 证明、第二套 root/count 方法或大范围复平面扫描；
- 与所选 $\eta_h$ 无关的完整 adjoint、transport、Gram 或 structure-preserving 理论；
- saved candidate 到 finite zero 或相邻 projected finite roots 的 one-step correction；
- 多套 reference 或 enclosure 方法的横向比较。

## 权威入口与后续设计顺序

推荐按以下顺序阅读：

1. [[research/projects/eig-apost/implementation/i2/report|I2 stage report]]：I3 的 candidate 与质量输入；
2. [[research/projects/eig-apost/phase1-scope/rq-summary|Phase 1 research question]]、
   [[research/projects/eig-apost/phase1-scope/p-method|Phase 1 method]] 和
   [[research/projects/eig-apost/phase1-scope/materials|Phase 1 error-source notes]]：目标误差与
   independent-reference 原则；
3. [[research/projects/eig-apost/phase2-sources/synthesis-dtn|Phase 2 DtN synthesis]]、
   [[research/projects/eig-apost/phase2-sources/r-nep-error|Phase 2 NEP error review]] 和
   [[research/projects/eig-apost/phase2-sources/r-da2|Phase 2 independent-reference audit]]：
   已核验的扰动公式来源、reference 独立性边界及尚未闭合的假设；
4. [[research/projects/eig-apost/implementation/open-problems#Current I3|Current I3 ledger]]：
   当前 blocker；
5. [[research/projects/eig-apost/implementation/i3/design-3-1|I3.1 frozen baseline design]]、
   [[research/projects/eig-apost/implementation/i3/review-3-1|I3.1 independent review]] 与
   [[test/i3/s-resid/README|I3.1 experiment index]]：首个连续强残量 baseline；
6. [[research/projects/eig-apost/implementation/i3/design-3-1b|I3.1 Q1--RT0 weak-residual V2 design]]：
   已完成 `weak-a1`；其
   [[research/projects/eig-apost/implementation/i3/review-3-1c|independent post-run review]] 与
   [[test/i3/w-resid/README|experiment index]] 记录 phase/scale Gram 首败。历史 BIE V1 的正式
   负结果由
   [[research/projects/eig-apost/implementation/i3/review-3-1b|independent post-run review]] 与
   [[test/i3/g-resid/README|experiment index]] 承载；
7. [[research/projects/eig-apost/implementation/i3/design-3-1e|I3.1 pure-BIE design]]、
   [[research/projects/eig-apost/implementation/i3/review-3-1e|independent post-run review]] 与
   [[test/i3/p-resid/README|experiment index]]：当前可计算 indicator、三个资格 warnings 与
   分别属于 I3.2 handoff 和 I3.3 reliable-interval 研究的未闭合条件；
8. [[research/projects/eig-apost/implementation/ROADMAP|implementation roadmap]]：项目级顺序。

I3.2 的正式独立验证必须在一个经过内部资格的 I3.1 estimator specification 单独冻结后才能
设计和运行；I3.1 自身需要的重构、简化问题或内部一致性检查仍属于 I3.1。`center-a1`、
`lead-a3` 和 `weak-a1` 都不满足 I3.2 移交条件。任何后续算法、离散参数、reference、阈值和
运行命令都须另行冻结；`pbie-a2` 虽已形成窄名义区间，但实际 $T$ difference-block/oracle、
wall refinement 与 outside-$M$ 三项内部资格尚未闭合，因此不能移交 I3.2。reliable
enclosure、projected gap 和宽度门留给 I3.3，不是 I3.2 的前置条件。当前结果不自动授权下一
attempt。
