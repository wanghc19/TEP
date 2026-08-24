# Eigenvalue a posteriori implementation roadmap

本页只维护当前项目的最短研究主线、阶段关系和长期规划规则。I1 的离散 readiness 见
[[research/projects/eig-apost/implementation/i1/README|I1 guide]]，I2 的三个里程碑见
[[research/projects/eig-apost/implementation/i2/README|I2 guide]]，I3 的目标、输入和输出见
[[research/projects/eig-apost/implementation/i3/README|I3 guide]]。具体实验只由
[[test/README|experiment index]] 索引。

## 项目唯一目标

整个项目只服务于两个最终目标：

1. 用数值方法提出连续物理谱问题的正频率特征值 candidate；
2. 估计该 candidate 与真实连续特征值之间的误差，并研究何时能够给出可计算的误差上界。

有限维矩阵、determinant zero、近核向量、inertia、transport 和 derivative 都只是实现这两个
目标的工具。项目不把“证明 numerical candidate 本身就是某个精确离散特征值”作为独立终点，
也不要求先消除所有连续—离散概念差异才允许提出 candidate。所有差异都应进入误差来源、
适用条件或 uncertainty 账本。

## 长期阶段规则

- 每个大阶段的正式内部里程碑通常以 **4 个为宜**，任何情况下不得超过 **5 个**；四个不是
  最低数量要求，三个彼此独立的问题优于为了凑数拆出的第四项。
- 只有会使当前交付不可解释、或真正阻止下一次必要计算的问题，才能成为正式里程碑或
  `BLOCKER`。
- 对主目标有帮助但不阻止后续工作的检查，统一列入 `OPTIONAL`；不得为了术语完备、
  定理级身份或额外稳健性无限扩张阶段。
- 一个实验不得同时承担发现 candidate、证明连续谱定理、认证离散结构和构造误差上界。
  每个里程碑只回答它对最终两项目标所必需的问题。
- I2 之后的规划只冻结大方向。具体算法、参数、阈值和验收流程必须根据 I2 实际结果另行设计。

## 项目主线

$$
\text{连续物理特征值问题}
\longrightarrow
\text{可信离散 evaluator}
\longrightarrow
\text{高可信 candidate}
\longrightarrow
\text{误差来源与可计算估计}
\longrightarrow
\text{真值误差验证与上界研究}.
$$

| Stage | 核心目标 | 为最终目标解决什么 | 主要交付 | 为什么下一阶段需要它 |
|---|---|---|---|---|
| I1 | 建立可重复调用、对象不漂移的离散 evaluator，并找到显著实轴 dip | 没有可信 evaluator，后续 candidate 和误差变化都可能只是 branch、chart、rank 或 solver 改变 | 冻结的 $A_{\mathrm{def}}(k)$ 计算链、已知 dip、小邻域 readiness 与失败边界 | I2 需要在同一对象上判断这个 dip 是否值得作为连续特征值 candidate |
| I2 | 汇总 count、端点 surrogate sign-count，并比较不同离散阶数下同一 mode 的 candidate 漂移 | 把“看见一个 dip”提升为“有局部计数、端点诊断和跨离散 candidate 证据支持的连续物理 candidate” | 各冻结离散阶数的 saved candidate、observed drift、terminal-cell/minimizer-localization diagnostic 及最低 residual/factor/field/boundary/mode-identity 证据 | I3 需要这些同-mode candidate 数据来识别误差来源；terminal-cell 尺度不再充当 candidate error bar |
| I3 | 构造可计算误差估计，检验它是否反映 candidate 到连续真值的误差，并研究可计算上界 | 防止把层间变化、矩阵残差或 correction 误称为真实 eigenvalue error | error indicator/correction、独立 truth comparison、effectivity 与 upper-bound verdict | 这是项目最终成果；额外参数、mode 或环境验证只在有需要时作为 OPTIONAL 扩展 |

## I1：可信离散 evaluator

### 核心目标

I1 把连续 half-guide/DtN/BIE 谱问题落实成一个可审计的有限维 evaluator，并在固定模型上找到
显著 dip。它解决的是“程序在不同参数点究竟有没有计算同一个对象”，而不是证明 candidate
等于连续特征值。

### 已完成的四个里程碑

| Milestone | 通俗目标 | 状态 |
|---|---|---|
| I1.1 | 冻结连续对象到离散矩阵的符号、尺寸和失败语义 | `PASS WITH CONDITIONS` |
| I1.2 | 验证 one-cell、QZ、graph、DtN 到 $A_{\mathrm{def}}$ 的联合计算链 | `PASS WITH CONDITIONS` |
| I1.3 | 检查实轴参数连续性并记录显著 dip | `PASS WITH CONDITIONS` |
| I1.4 | 检查 dip 小邻域内 branch、chart、factor 和 evaluator readiness | `PASS WITH CONDITIONS` |

I1 的交付是可信 evaluator 和 dip 邻域，不是 root、continuous eigenvalue 或 estimator。I2 不再
重复宽区间扫描、dip 搜索或逐层局部加密。

## I2：提出高可信连续特征值 candidate

### 核心目标

I2 不是要证明某个有限矩阵的精确特征值身份，而是汇集最低成本、互补且不循环的数值证据，判断
I1 dip 是否足够可信，可以作为连续物理问题的 eigenvalue candidate 交给误差分析。连续物理
算子的实谱支持优先使用实轴数据；离散结构缺陷则作为近似质量和 uncertainty 记录。

### 三个正式里程碑

| Milestone | 核心问题 | 当前状态 | 交付 |
|---|---|---|---|
| I2.1 单零计数诊断 | dip 小圆盘中是否存在一个孤立的有限维 zero，而不是没有 zero、多个 zero 或 factor pole 混淆 | `PASS WITH CONDITIONS` | 条件性 finite-dimensional count one；只作 candidate 可信度证据 |
| I2.2 端点 sign-count/inertia-like jump 数值诊断 | 已知 dip 邻域左右端点的符号计数是否发生稳定跳变 | `PASS WITH CONDITIONS / HERMITIAN_PART_SINGLE_JUMP` | 已观察到稳定 endpoint count difference；只作数值佐证，不证明 raw finite matrix inertia 或实根 |
| I2.3 跨离散阶数 candidate 漂移 | 预先冻结的不同离散阶数是否给出同一物理 mode，保存的 candidate 是否发生观测漂移 | `PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE` | `ntot` 与 $M$ 两条三层单轴实验均返回完全相同的 saved candidate，并分别形成 conditional algorithmic hierarchy；terminal-cell 尺度只限制 sub-grid minimizer 解释 |

I2.2 只复用 I1.3 已确定的区间端点，不重新扫描、寻找 dip、二分定位或复平面求根。旧
I2.2 structure experiment 的 `NaN/UNAVAILABLE` 与 `I2_2_STOP_THEORY_GATE` 保持历史原样；
它只说明当时不能把 raw $H$ 的计数解释成定理级 inertia。当前计划允许把明确标注对象和
结构缺陷的端点 sign-count/inertia-like jump 作为数值可信度诊断，但 exact finite Hermitian
证明不再是主线。

I2 的退出不是“candidate 已被证明为精确特征值”。`drift-a1` 的 `ntot` 轴与
`m-drift-a2` 的 $M$ 轴均给出三个可复现、同 mode 且完全相同的 saved candidates，故当前 I2 退出为
`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。I3 可以接收这一 conditional algorithmic
hierarchy；但 terminal-cell 尺度只说明 sub-grid minimizer 尚未解析，两条零-shift 轴也不能
单独提供非零 correction、收敛证据或误差界。

## I3：误差估计与上界研究

### 核心目标

I3 直接研究 candidate 与真实连续特征值之间的误差。它不以某种固定 estimator 公式为预设，
也不把 next-level shift、matrix residual 或 effectivity 单独当成最终答案。具体算法和验收流程
应根据 I2 实际交付另行冻结。当前 `drift-a1` 与 `m-drift-a2` 已提供两条经 mode-identity
检查的 candidate sequence。I3.1 已完成中心空列、lead-aware reconstruction、Q1--RT0 weak
residual 与 BIE-collar weak residual 四个正式实验，当前状态为
`ACTIVE / FOUR VALID NEGATIVE EXPERIMENTS / NO ESTIMATOR`。
零 observed shift 不能单独
验证 next-level correction、收敛或 estimator；中心空列 ratio 因固定单胞 cutoff 主导而失去
分辨率，lead-aware 实验则在形成通过资格的全波导 continuous trial/residual 之前即于固定
BIE-informed fit 首败；Q1--RT0 实验又在 fine phase/scale Gram qualification 首败。V3
`bie-a3` 虽通过真实 incoming BIE 的 branch/density/surface/safe-field 门，却在 coarse lead
RT0-majorant 的含圆盘修正预因子处停止，未形成 flux、majorant、tail 或区间。四者都不能进入
I3.2。

### 输入、三项输出和与上界的关系

- **从 I2.3 接收：**预先冻结的离散阶数、同一物理 mode 的 candidate 序列、相邻/相对漂移、
  terminal-cell/minimizer-localization diagnostic，以及最低 residual、factor、field、boundary、
  mode-identity 和复现诊断。`drift-a1` 与 `m-drift-a2` 已分别提供边界 Nyström 与
  trace-cutoff 轴的原始数值事实；两条轴的三层 saved candidate 均相同，observed shift 为零。
  这些事实可进入误差来源分析，但不能单独支持非零 correction、effectivity 或 convergence claim。
- **由 I3 另行建立：**连续模型适用边界，以及空间/trace/half-guide/BIE--QZ/结构/求解/
  continuous--discrete 误差与实际 estimator 的关系。
- **I3.1 输出：**一个冻结、可计算的 $\eta_h$，以及它覆盖和忽略的误差、适用假设和内部
  一致性证据。没有证明时只能称渐近误差指标或 estimator candidate。
- **I3.2 输出：**在 estimator 冻结后，用未参与其构造的独立 reference 检验其是否跟踪
  candidate 到 gap 内连续离散特征频率集合的距离。通过后才称
  `empirical eigenvalue-error estimator`；只有 reference 独立识别特定 mode 时才检验
  target-specific error。同方法高分辨率结果只能作有共享偏差的后备。
- **I3.3 输出：**若还能给出 certified residual dual-norm upper bound、field-norm lower
  bound、numerical enclosure、当前 continuous projected essential gap，以及结果前冻结的
  absolute/gap-relative resolution，则先产生

  $$
  \operatorname{dist}\bigl(
  \widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)
  \bigr)\le U_h.
  $$

  只有另有 continuous spectral isolation/count 时，才升级为指定
  $|k_*-\widehat k_h|\le U_h$。若这些条件不能建立，必须明确输出
  `UPPER_BOUND_UNAVAILABLE`；已经通过独立 truth validation 的 empirical estimator 仍然可以
  保留。

### 三个正式里程碑

| Milestone | 只回答什么问题 | 独立输出 |
|---|---|---|
| I3.1 构造并内部论证误差指标 | 能否构造实际可计算的 $\eta_h$，并说明其数学来源、假设、覆盖和忽略的误差 | 冻结的 estimator candidate 与内部检查结果 |
| I3.2 独立验证 estimator | 冻结后的 $\eta_h$ 是否在未参与其构造的独立 reference 上跟踪真值误差量级 | empirical estimator verdict；失败时保留较弱 indicator 结论 |
| I3.3 研究可计算上界 | 能否由已证明覆盖的 residual/field norms、numerical enclosure、continuous projected gap 和预注册分辨率得到不含未知常数的 existence-distance 上界；必要时再升级唯一目标 | $U_h$、`EXISTS_BUT_RESOLUTION_INSUFFICIENT` 或 `UPPER_BOUND_UNAVAILABLE` |

I3.1 已冻结并运行首个最低成本特殊情形：在 homogeneous empty center column 中，由 I2 的
Fourier 墙系数构造显式场，乘固定单胞 cutoff 后直接计算 continuous strong-residual norm ratio。
`center-a1` 得到 $22.43882099031153$；积分层稳定，但两个 cutoff 导数项分别约为 $17.14$ 和
$4.93$，名义区间跨过零，因而该 reconstruction 对预注册 $10^{-6}$ 频率尺度分辨率不足。
这是一项有效负结果，不是可用于 I3.2 的 estimator。

I3.1 下一步仍须直接作用于连续物理算子，不先定位 finite zero 或预测 projected finite-root shift。
历史全波导 BIE-informed Fourier--Hermite/bubble reconstruction 已正式运行；
`lead-a3` 通过 finite input、density representation 和 propagation，但 $J=4/8$ holdout error
分别约为 $4.522421/5.138028$，高于 $0.20$ 且随 bubble order 变差，故按预注册优先级停止于
`CONFORMING_RECONSTRUCTION_UNRESOLVED`。center、Gram、tail 和 residual ratio 均未到达。

由于 training/holdout targets 到圆周仅约为 source-panel arc scale 的 $0.86\%/1.08\%$，direct
close layer-potential evaluation 尚未资格化；当前不能区分近奇异评价与 basis/metric 的贡献。
当前 [[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]] 已在保留 Git
历史的前提下改写为 V2：用 frozen QZ wall traces、conforming Q1 cell extension、global RT0
flux 与 functional majorant 构造 weak residual。正式 `weak-a1` 的 base finite input、Q1--RT0
与 full-$P$ tails 通过，但 fine phase/scale repeat 中 center 的 $A,B$ Gram 及左右 first-cell 的
$A$ Gram 的最大 Hermitian
defect 为 $6.2442\times10^{-10}>10^{-12}$，故 producer 停止于
`MAJORANT_QUADRATURE_UNRESOLVED`。该 valid negative 没有形成 estimator；独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1c|review-3-1c]]。

V3 [[research/projects/eig-apost/implementation/i3/design-3-1d|design-3-1d]] 改用真实
incoming BIE、安全 collars、conforming Q1 companion 与 constrained RT0 majorant。正式
`bie-a3` 已通过 finite input、branch/Wood、propagation、density、surface trace 与 safe-field
门，但在 coarse lead 的 composite RT0-majorant pre-factor 处停止。当前最近的下一门是先保存
并检查 background、disk correction 与最终 free-block 的正性和 bad-edge 诊断，再决定是
quadrature positivity 还是 assembly/index 问题；不得绕过首败。关闭后仍须另行通过
$H(\mathrm{div})$、tail、mesh 与有用 interval width。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]。
finite one-step correction 仅为 OPTIONAL 离散分量诊断。对中心宽
baseline 优先增加可靠积分 enclosure 或 gap 认证仍不能提高分辨率。

误差来源识别并入 I3.1；reference 搜索并入 I3.2；norm enclosure、continuous projected-gap
containment 和预注册分辨率研究并入 I3.3。唯一目标识别只在下游必须跟踪特定 mode 时升级。
它们不另拆里程碑。任何后续 levels、reconstruction、reference 算法、阈值或实验命令仍须
单独冻结。I3.1 的定义、常数和样本规则必须在查看 I3.2 的 reference 结果前冻结；一般经验
reference 的 uncertainty 不能进入严格 $U_h$，除非 reference 自身给出经证明的 enclosure。

## OPTIONAL：不构成正式阶段

- 重新证明 exact finite Hermitian/Lagrangian identity，或把 endpoint diagnostic 升级为严格
  inertia theorem；
- 第二种 count 方法、额外 contour、$N_k=128$ 或大范围复平面扫描；
- 更多参数、第二 mode、跨环境 parity、额外高精度与可迁移性实验；
- 不被当前 estimator 或上界路径实际使用的 derivative、transport、Gram、adjoint 或
  structure-preserving 完备性工作。

这些项目只有在主线异常、I3 公式实际需要或准备提升 claim 时才另行设计。历史实验及其
审查结论不因本路线压缩而改变。
