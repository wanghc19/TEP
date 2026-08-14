# I3：连续特征值误差估计与上界研究

## 阶段定位

I3 的唯一研究对象是 I2 提出的 numerical candidate 与真实连续物理特征值之间的误差。
本阶段不把某个有限维 matrix root、特定 correction 公式、transport、denominator 或 effectivity
本身当成最终成果；这些量只有在能够帮助估计真值误差时才进入主线。

项目目标按以下顺序推进：

$$
\text{提出 candidate}
\longrightarrow
\text{识别误差来源}
\longrightarrow
\text{构造可计算误差估计}
\longrightarrow
\text{研究真值误差上界}.
$$

I3 当前只冻结目标、输入、预期输出和 claim ladder，不冻结具体算法、levels、阈值、reference
构造或实验流程。I2.3 的 `ntot` 与 $M$ 两条三层单轴实验均得到 `SAME_MODE`，且各自三个
saved candidate 完全相同，当前结论为 `NO_OBSERVED_CANDIDATE_DRIFT`。因此 I3 当前
`DESIGN MAY BEGIN / NOT STARTED`；具体算法仍须另行设计和审查。

## 目标

1. 明确 candidate 与连续真值之间有哪些可分辨的误差来源；
2. 构造一个从实际数值计算中可得到的 error indicator 或 correction；
3. 检查该估计是否跟踪真实连续特征值误差，而非只跟踪下一层变化或共享离散偏差；
4. 研究在什么额外条件下能够把估计升级为可计算上界。

I3 同时接管误差来源的识别与分解：空间离散、trace 截断、half-guide 近似、BIE/QZ 表示、
finite structure defect、candidate 求解/定位以及 continuous--discrete bridge 均在本阶段归类、
隔离并与可计算估计建立关系，不再由 I2 单设误差账本。

I3 不要求先证明 candidate 本身是精确有限维特征值。若某种误差公式确实要求 simple-root、
adjoint、transport 或非零 denominator，这些条件只作为该公式的适用条件审查；也可以选择不依赖
这些中间对象的其他 estimator 路线。

## 输入

I3 预期从 I2.3 直接接收：

- 一个冻结、可复现的实轴 candidate 及其搜索区间；
- 原始 evaluator、factor、field 和 residual 的可信度诊断；
- 冻结物理对象、完整 level tuples、唯一主 refinement axis、candidate functional、定位窗口/
  规则、solver policy、precision 与 provenance；
- 预先冻结的不同离散阶数及每个阶数的 saved candidate；
- terminal search-cell half-width；它只作潜在 sub-grid minimizer 的 localization/resolution
  metadata，不是 candidate uncertainty；
- 公共 mode 表示、跨层映射和 normalization/phase-alignment 规则；
- 同一物理 mode 的相邻/相对 candidate 漂移；
- 每个阶数最低必要的原矩阵 residual、factor、field、boundary、mode-identity 与复现结果；

`drift-a1` 与 `m-drift-a2` 已分别提供 `ntot` 轴和 $M$ 轴的三层候选及上述健康诊断，且每条轴
的三项 saved candidate 均共享同一终端网格点。因此它们形成两条 conditional same-mode
algorithmic candidate hierarchy，observed candidate shift 均为零。
I3 可以据此开始误差来源与 independent-reference 设计，但不能把 terminal half-width 解释为
candidate error bar，也不能从零 observed shift 推出相等 minimizers、收敛、effectivity 或误差界。

I3 另行建立而不反推给 I2 的输入是：

- 连续物理模型、projected gap、half-guide 和 BIE kernel--field 等 claim boundary；
- 独立 truth reference 的候选来源及其自身 uncertainty 说明；
- 空间、trace、half-guide、BIE/QZ、结构、求解和 continuous--discrete 误差的分类与分解规则。

这些输入不预先声称任何漂移属于哪种误差。I3 首先识别并分解空间、trace、half-guide、
BIE/QZ、结构、求解和 continuous--discrete 误差，再判断哪些分量能够估计。若某项输入缺失，
I3 应先判断它是否真正阻止误差估计，而不是自动扩张成新的 candidate 资格阶段。

## 预期输出

I3 的输出按强度分四级：

| Level | 允许的名称 | 必须回答什么 |
|---|---|---|
| 1 | `error indicator` | 给出一个可计算量，并说明它对应哪一类误差 |
| 2 | `next-level correction` | 能预测同一 candidate/mode 在下一 refinement level 的实际变化 |
| 3 | `empirical eigenvalue-error estimator` | 与带 uncertainty 的独立连续问题 reference 比较后，能稳定跟踪 $|k_*-\widetilde k_h|$ |
| 4 | `computable upper bound` | 在独立成立的稳定性、remainder、saturation/enclosure 与 continuous--discrete bridge 下给出 $U_h$，使 $|k_*-\widetilde k_h|\le U_h$ |

不得跨级命名：能预测层间 shift 不等于能估计真值误差；effectivity 接近一也不自动给出上界；
observed contraction ratio 不能冒充已证明 saturation。

## 与误差上界的直接关系

I3 必须把以下问题分开：

1. **estimate：**可计算量是否与真实误差同量纲并在 refinement 中跟踪它；
2. **validation：**独立 reference 的 uncertainty 是否足够小，使 effectivity 可解释；
3. **upper bound：**是否有独立理由控制尚未计算的尾项和 remainder，并排除共同偏差或谱污染。

当前 sufficient route 可以写成

$$
|k_*-\widetilde k_h|
\le
U_h,
$$

其中 $U_h$ 必须由可计算估计、reference/solve uncertainty、remainder 及经过审查的稳定性或
saturation/enclosure 条件组成。该形式不是唯一可能路线；若未来得到不同的可靠 enclosure
理论，可以另行替换。没有这些条件时，正确结论是 `UPPER_BOUND_UNAVAILABLE`，而不是给经验
估计乘一个没有来源的安全系数。

## 预计四个方向

| Direction | 核心问题 | 本轮是否冻结细节 |
|---|---|---|
| I3.1 误差来源识别与分解 | I2.3 的 candidate 漂移中哪些部分来自定位/求解、空间/trace、half-guide、BIE/QZ、结构或连续模型近似 | 否 |
| I3.2 可计算估计 | 哪种 indicator/correction 能从实际数据得到，并对应目标误差的哪一部分 | 否 |
| I3.3 独立 truth 与 effectivity | 估计是否跟踪真实连续特征值误差，reference uncertainty 是否足够小 | 否 |
| I3.4 上界可行性 | 是否具备把估计升级为真值误差上界的独立条件；若没有，缺口是什么 | 否 |

四个方向是规划框架，不是预注册实验。I2 完成后可以合并或重排内部工作；四个只是规划经验，
不是最低数量要求，正式里程碑任何情况下不得超过五个，也不得为了凑数拆分没有独立问题的
交接工作。

## OPTIONAL

以下工作只有在主 estimator、truth validation 或上界路径确实需要时才升级：

- 额外 parameter/mode、跨环境 parity 和泛化实验；
- exact finite Hermitian、第二套 root/count 方法和大范围 complex scan；
- 与已选 estimator 无关的完整 adjoint/Gram/transport 理论；
- theorem-level certified bound 之外的多套 enclosure 比较。

统一项目依赖见 [[research/projects/eig-apost/implementation/ROADMAP|implementation roadmap]]，
当前 blockers 见
[[research/projects/eig-apost/implementation/open-problems#Current I3|Current I3 ledger]]。
