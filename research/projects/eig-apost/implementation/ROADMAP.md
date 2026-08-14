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
| I2 | 汇总 count、端点 surrogate sign-count，并比较不同离散阶数下同一 mode 的 candidate 漂移 | 把“看见一个 dip”提升为“有局部计数、端点诊断和离散漂移证据支持的连续物理 candidate” | 各冻结离散阶数的 candidate、漂移量、定位不确定度及最低 residual/factor/field/boundary/mode-identity 证据 | I3 需要先看到 candidate 随离散变化的实际数据，才能识别误差来源和构造估计 |
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
| I2.3 跨离散阶数 candidate 漂移 | 预先冻结的不同离散阶数是否给出同一物理 mode，candidate 漂移多大且是否超过定位不确定度 | `PLANNED / NOT STARTED` | 每个阶数的 candidate、相邻/相对漂移、定位不确定度，以及最低 residual、factor、field、boundary 和 mode-identity 结果 |

I2.2 只复用 I1.3 已确定的区间端点，不重新扫描、寻找 dip、二分定位或复平面求根。旧
I2.2 structure experiment 的 `NaN/UNAVAILABLE` 与 `I2_2_STOP_THEORY_GATE` 保持历史原样；
它只说明当时不能把 raw $H$ 的计数解释成定理级 inertia。当前计划允许把明确标注对象和
结构缺陷的端点 sign-count/inertia-like jump 作为数值可信度诊断，但 exact finite Hermitian
证明不再是主线。

I2 的退出不是“candidate 已被证明为精确特征值”，而是：candidate 已有足够、可复现且
互相不循环的数值证据；不同离散阶数下同一 mode 的 candidate、漂移与定位不确定度均已报告；
I3 能据此识别误差来源并研究 candidate 到连续真值的误差。误差分解本身属于 I3，不再为了
“交接”单设 I2.4。精确 finite zero、额外 contour、全局复扫描、完整离散自伴证明和多参数
稳健性均不自动成为 I2 blocker。

## I3：误差估计与上界研究

### 核心目标

I3 直接研究 candidate 与真实连续特征值之间的误差。它不以某种固定 estimator 公式为预设，
也不把 next-level shift、matrix residual 或 effectivity 单独当成最终答案。具体算法和验收流程
必须等 I2 交付后再冻结。

### 输入、预期输出和与上界的关系

- **从 I2.3 接收：**预先冻结的离散阶数、同一物理 mode 的 candidate 序列、相邻/相对漂移、
  各层定位不确定度，以及最低 residual、factor、field、boundary、mode-identity 和复现诊断。
  这些是尚未归因的原始数值事实，不预先指定属于哪种误差。
- **由 I3 另行建立：**连续模型适用边界、空间/trace/half-guide/BIE--QZ/结构/求解/
  continuous--discrete 误差分类，以及带自身 uncertainty 的独立 truth reference。
- **第一层输出：**一个可计算 error indicator 或 correction，以及它试图估计的误差分量。
- **第二层输出：**与实际 refinement shift 和带 uncertainty 的独立连续问题 reference 比较后的
  effectivity。若只预测下一层变化，必须称 `next-level correction/indicator`，不能称真值误差
  estimator。
- **最终输出：**若还能给出充分的 continuous--discrete bridge、稳定性、remainder 和
  saturation/enclosure 条件，则产生可计算上界 $U_h$，满足

  $$
  |k_*-\widetilde k_h|\le U_h.
  $$

  若这些条件不能建立，必须明确输出 `UPPER_BOUND_UNAVAILABLE`；已经通过独立 truth
  validation 的 empirical estimator 仍然可以保留。

### 四个预计方向（非冻结实验设计）

| Direction | 只回答什么问题 |
|---|---|
| I3.1 误差来源识别与分解 | candidate 的变化来自哪些误差，哪些量能在公共表示下比较 |
| I3.2 可计算误差估计 | 能否从已有离散数据构造一个与目标误差同量纲的 indicator/correction |
| I3.3 真值关联与 effectivity | 该估计是否真的跟踪到连续真值的误差，而不只是预测共享偏差下的层间变化 |
| I3.4 上界可行性 | 能否把估计、remainder、稳定性与 continuous bridge 组合成可计算上界；否则准确记录缺口 |

这些方向保持在项目级，不在本轮冻结 levels、transport、denominator、reference 算法、阈值或
实验命令。

## OPTIONAL：不构成正式阶段

- 重新证明 exact finite Hermitian/Lagrangian identity，或把 endpoint diagnostic 升级为严格
  inertia theorem；
- 第二种 count 方法、额外 contour、$N_k=128$ 或大范围复平面扫描；
- 更多参数、第二 mode、跨环境 parity、额外高精度与可迁移性实验；
- 不被当前 estimator 或上界路径实际使用的 derivative、transport、Gram、adjoint 或
  structure-preserving 完备性工作。

这些项目只有在主线异常、I3 公式实际需要或准备提升 claim 时才另行设计。历史实验及其
审查结论不因本路线压缩而改变。
