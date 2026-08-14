# I3：连续特征值误差估计与上界研究

## 阶段定位

I2 已为连续波导问题提出一个可复现的实轴 numerical candidate，并从局部复平面计数、
Hermitian part 的端点符号计数以及两条单轴离散实验三个角度检查了它的可信度。I2 没有给出
candidate 到真实连续特征值的误差，也没有给出收敛阶或误差上界。详细交接见
[[research/projects/eig-apost/implementation/i2/report|I2 stage report]]。

I3 只研究下面这个最终问题。记 I2 在离散层 $h$ 上实际保存的 candidate 为
$\widehat k_h$，记目标连续物理问题的真实特征值为 $k_*$，则目标误差是

$$
e_h=|k_*-\widehat k_h|.
$$

本阶段不把有限维矩阵的精确零点、层间漂移、矩阵残差或某个修正公式本身当成最终成果。
这些量只有在能够帮助估计 $e_h$ 时才进入主线。I3 当前只重构研究问题、输入、输出与结论
边界；具体算法、离散参数、reference 实现、阈值和实验命令均尚未冻结。

I3 由三个正式里程碑组成。三个是科学问题决定的数量，不是为了满足阶段数而拆分；误差来源
识别、reference 搜索、术语整理和文档交接都不是独立里程碑。

| Milestone | 独立科学问题 | 核心输出 | 当前状态 |
|---|---|---|---|
| I3.1 | 能否从实际计算量构造并内部论证一个与 $e_h$ 有关的可计算指标？ | 冻结的 $\eta_h$、适用假设、覆盖/忽略的误差及内部检查结果 | `NOT STARTED` |
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
  uncertainty，也不是 $e_h$ 的上界；
- 两条轴的 observed candidate shift 都是零。这是有用的稳定性事实，但不能单独产生非零
  correction、收敛阶、effectivity 或真值误差界。

I3 还必须面对 I2 尚未解决的 continuous--discrete 问题，包括半波导近似、边界积分表示、
Rayleigh/Fourier 截断、边界离散、QZ 子空间、有限精度求解以及从离散矩阵到连续物理算子的
关系。哪些误差进入 $\eta_h$、哪些暂时忽略，必须在 I3.1 随具体公式一起说明，不能先验地把
全部误差相加成一个没有数学来源的“总误差账本”。

## I3.1：构造并内部论证可计算的误差指标

### 科学问题

能否从当前计算中实际可得的矩阵、向量、residual、相邻离散层差异或其他量，构造一个数值
$\eta_h$，并说明它为什么可能反映 $e_h$ 的一部分或主要部分？

### 输入

- I2 保存的 candidate、同一 mode 的公共表示和最低质量诊断；
- 连续算子、离散矩阵和两者关系中已经建立的数学结构；
- Phase 1 对真值误差、独立 reference 与内部有效性的定义；
- Phase 2 对非线性特征值扰动公式、相邻层修正和 continuous--discrete 缺口的核验结果。

Phase 2 的材料说明了若干可能的数学来源，但没有交付一个可直接沿用的 estimator。I3.1 必须
根据当前对象重新选择并推导实际公式，不能仅因某个量与 $e_h$ 同量纲就把它命名为误差估计。

### 必须完成的内部论证

I3.1 把误差来源识别并入指标构造，而不另设阶段。至少要逐项说明：

1. $\eta_h$ 的公式和所有可计算输入；
2. 公式依赖的假设，例如单根、稳定性、非零分母、公共表示或渐近区间；
3. 它覆盖哪些误差，例如 candidate 求解、边界离散、Fourier 截断或 half-guide 近似；
4. 它忽略哪些误差，尤其是尚未建立的 continuous--discrete 误差和可能的共同偏差；
5. 单位、缩放、基底和相位改变是否会不合理地改变结果；
6. 推导恒等式、简化问题、manufactured problem、相邻层自洽性或负例等内部检查是否支持该
   公式；
7. 数值舍入、线性求解和 candidate 定位误差怎样与 estimator 数值本身区分。

这些都是内部证据：它们用于检查公式是否自洽，但不能用来证明它已经跟踪未知的 $e_h$。
I3.1 不得查看 I3.2 的独立 reference 后再选择公式、调常数或改变成功判据。

### 输出与结论边界

I3.1 的输出是一份冻结的 estimator specification，包括 $\eta_h$、覆盖范围、忽略项、假设、
内部检查和适用失败条件。若没有证明

$$
e_h=O(\eta_h),
$$

就只能称 $\eta_h$ 为“渐近误差指标”或“estimator candidate”。若它只预测下一层 candidate
变化，则必须称“next-level indicator/correction”，不能称 eigenvalue-error estimator。

I3.1 完成不表示 $\eta_h$ 已经有效；它只表示一个可计算、可证伪且可以在外部数据上检验的
对象已经冻结。

## I3.2：用独立 reference 验证 estimator

### 科学问题

在不再改变 I3.1 公式的前提下，$\eta_h$ 是否能跟踪
$|k_*-\widehat k_h|$ 的量级，而不是只跟踪同一数值方法内部的层间变化或共同偏差？

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

在 I3.2 已经建立 empirical estimator 的基础上，能否得到一个完全可计算的 $U_h$，使

$$
|k_*-\widehat k_h|\leq U_h,
$$

且 $U_h$ 不含未知稳定性常数、未知 remainder 或凭经验选择的安全系数？

### 输入

- I3.1 冻结的 estimator 及其覆盖/忽略项；
- I3.2 的 independent-reference 验证结果；
- 另行建立的 continuous--discrete 关系、稳定性、谱隔离/no-pollution、remainder 控制，或
  足以给出 enclosure 的其他条件。

经验上观察到的 contraction ratio、effectivity 或同一 reference 的一致性不能自动替代这些
条件。若使用 saturation，也必须有独立论证，而不能从要证明的上界反推 saturation 常数。

### 输出与结论边界

I3.3 只有两类合法输出：

- 给出所有量均可计算、假设逐项成立的 $U_h$；或
- 明确输出 `UPPER_BOUND_UNAVAILABLE`，并列出缺失的稳定性、连续--离散、remainder、
  enclosure 或 reference 条件。

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
- I3.3 不能用 observed effectivity 代替未知 remainder 或稳定性常数；
- 后一里程碑失败不追溯撤销前一里程碑已经在其结论强度内成立的结果。

## OPTIONAL

以下工作只有在三个主里程碑实际需要时才升级，不构成独立 stage：

- 额外参数、第二 mode、跨环境 parity 或泛化实验；
- exact finite Hermitian/Lagrangian 证明、第二套 root/count 方法或大范围复平面扫描；
- 与所选 $\eta_h$ 无关的完整 adjoint、transport、Gram 或 structure-preserving 理论；
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
5. [[research/projects/eig-apost/implementation/ROADMAP|implementation roadmap]]：项目级顺序。

I3.2 的正式独立验证必须在 I3.1 estimator specification 单独冻结后才能设计和运行；I3.1
自身需要的简化问题或内部一致性检查仍属于 I3.1。本 README 不授权实验，也不预注册具体
算法、离散阶数、reference、阈值或运行命令。
