# I2：连续特征值 candidate 的可信度与跨离散阶数漂移

## 当前状态与权威边界

I2 当前状态为 `I2.1 PASS WITH CONDITIONS / I2.2 HERMITIAN-PART SINGLE_JUMP /`
`I2.3 PASS WITH CONDITIONS -- NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。
三里程碑的综合科学解释、失败历史、证据层级与 I3 交接见
[[research/projects/eig-apost/implementation/i2/report|I2 stage report]]。
I2.1 已在冻结 fine、$M=48$、$K=97$ 的有限维矩阵族上得到 factor-aware count one；统一入口为
[[test/i2/k-count/README|I2.1 experiment index]]，结论边界见
[[research/projects/eig-apost/implementation/i2/review|I2.1 review]]。它提高了 I1 dip 是谱候选
的可信度，但没有给出 continuous physical eigenvalue，也不是误差估计。

I2.2 的第一条 exact-structure 路线和双端点 preflight 已冻结在
[[research/projects/eig-apost/implementation/i2/design-2-2|historical I2.2 design]] 与
[[research/projects/eig-apost/implementation/i2/review-2-2|historical I2.2 review]]；实验入口为
[[test/i2/h-inertia/README|endpoint-structure experiment index]]。其历史 verdict
`I2_2_STOP_THEORY_GATE` 和 `inertia=NaN/UNAVAILABLE` 不作追溯修改。它只说明当时不能把
raw finite $H$ 的 endpoint count 当成定理级 inertia，不表示端点 sign-count/inertia-like jump
失去数值诊断价值，也不阻止继续完成用户要求的最低成本可信度检查。
当前 `inertia-a1` 已在同一 fine-$M=48$ evaluator 的两个冻结端点上得到稳定的
$H_{\mathrm{sym}}$ sign-count difference：左端 $(194,0,0)$、右端 $(193,1,0)$，即
$\Delta_-=+1$；这只是一项 numerical corroboration，不是 raw-$H$ inertia 或实根证明。

I2.3 的冻结设计和独立审查见
[[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 design]] 与
[[research/projects/eig-apost/implementation/i2/review-2-3|I2.3 review]]，统一实验入口为
[[test/i2/k-drift/README|I2.3 experiment index]]。唯一 `drift-a1` 在只改变
$n_{\mathrm{tot}}=160,208,256$ 时得到三个同一终端网格点的 `SAME_MODE`
candidate。算法保存的三项 $\widehat k_n$ 完全相同，因此当前结论是
`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。终端 cell 半宽只作潜在 sub-grid score minimizer
的定位尺度，不是 candidate uncertainty，也不否定 observed candidate drift。冻结 output 中
原 `DRIFT_UNRESOLVED / I3 STOP` 字段保持不变，但不再支配当前科学解释或 I3 入口。

I2.3 随后追加一条独立的 trace-cutoff 轴：冻结 $n_{\mathrm{tot}}=160$，只改变
$M=32,40,48$ 及其派生维数。设计、跑后审查和实验索引分别为
[[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 M-axis design]]、
[[research/projects/eig-apost/implementation/i2/review-2-3m|I2.3 M-axis review]] 与
[[test/i2/m-drift/README|I2.3 M-axis experiment index]]。正式 `m-drift-a2` 的三项 saved
candidate 同样均为 $1.832770289108157$，相邻 mode identity 均为 `SAME_MODE`，全部直接
candidate drift 为零。它形成第二条 `CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY`，但不
证明 sub-grid minimizer 相等、Fourier 截断收敛、continuous mode 或误差界。

本页是当前 I2 的项目级规划。它不修改 I2.1 或 I2.2 的冻结设计、审查和 append-only 输出；
后续实验仍须单独设计和审查。

## 阶段定位

I2 的任务是提出一个有充分数值依据的 continuous physical eigenvalue candidate，并直接向 I3
交付不同离散阶数下同一 mode 的 candidate 漂移数据。I2 不负责识别和分解全部误差来源，也不
以证明 candidate 等于某个精确有限维 determinant zero 或
离散矩阵 eigenvalue 为阶段终点。有限维 count、inertia、residual、near-kernel、factor 和 field
都只是判断 candidate 是否可信、以及误差可能来自哪里的证据。

I2 遵循三个成本边界：

1. 不重复 I1.3 已完成的宽区间实轴扫描、dip 搜索或发现式局部网格加密；I2.3 只允许在各
   冻结离散阶数的预注册窗口内，用同一定位规则取得可比较 candidate 与 minimizer-localization
   diagnostic；
2. 不为 exact finite Hermitian、严格离散实根或额外 contour 完备性扩张主线；
3. I2.3 已完成两条分别预注册的单轴实验：边界 Nyström 轴
   $n_{\mathrm{tot}}=160,208,256$，以及固定 $n_{\mathrm{tot}}=160$ 的 trace-cutoff 轴
   $M=32,40,48$。两条轴的 saved candidate drift 均为零且相邻 mode identity 均为
   `SAME_MODE`。这允许 I3 开始误差来源识别，但不授权把零 observed shift 当成收敛证据、
   非零 next-level correction 或误差界。

## 目标、输入和退出

### 目标

- 利用 I1 dip、I2.1 count one 和 I2.2 endpoint surrogate sign-count 诊断，提出高可信 candidate；
- 在预先冻结的不同离散阶数上跟踪同一物理 mode，观察 candidate 是否漂移；
- 报告 candidate 漂移量、minimizer-localization/search-resolution 尺度及最低必要的
  residual、factor、field、boundary 和
  mode-identity 检查；
- 把上述数值序列直接交给 I3，由 I3 识别空间、trace、half-guide、BIE/QZ、结构、求解和
  continuous--discrete 等误差来源并构造估计。

### 已有输入

- I1.1--I1.2 冻结的 continuous-to-discrete 对象层级、one-cell/QZ/graph/DtN/
  $A_{\mathrm{def}}$ evaluator、排序和失败语义；
- I1.3 已发现并加密的显著实轴 dip 及其已知窄区间；
- I1.4 sampled branch、chart、rank、factor 与小复圆盘 readiness；
- I2.1 在同一冻结圆盘内得到的条件性有限维 count one；
- I2.2 历史 preflight 提供的端点同对象关系、$T$ 可逆性和结构缺陷诊断。

### 退出条件

I2 完成时必须交付：

1. 一个明确数值和区间、可重复得到的 candidate；
2. I2.1 count 与 I2.2 endpoint jump/no-jump 的忠实诊断及其有限解释；
3. 冻结物理对象、完整 level tuples、唯一主 refinement axis、candidate functional、定位窗口/
   规则、solver policy、precision 与 provenance；
4. 公共 mode 表示、跨层映射、normalization/phase-alignment 规则，以及各离散阶数下同一
   physical mode 的 candidate、相邻/相对漂移和 terminal-cell/minimizer-localization 尺度；
5. 每个阶数的最低 residual、factor、field、boundary、mode-identity 与复现诊断。

退出不要求证明 candidate 是精确离散 eigenvalue，也不要求先得到 posterior estimator 或真值
误差上界。只有 candidate 无法与明显数值伪影区分，或 level 配置、candidate 定义、
mode identity 与必要原始诊断无法记录，才阻止把 I2.3 输出作为 estimator-ready I3 输入。

## I2 内部里程碑

| Milestone | 内容 | 当前状态 | 后续作用 |
|---|---|---|---|
| I2.1 单零计数诊断 | 检查 dip 小圆盘内是否有一个有限维 zero，并与 evaluator poles/factors 分账 | `PASS WITH CONDITIONS` | 为 candidate 提供独立的局部谱计数证据 |
| I2.2 端点 sign-count/inertia-like jump 数值诊断 | 只在 I1.3 已知区间左右端点检查 sign count/inertia-like quantity 是否出现可信 jump | `PASS WITH CONDITIONS / HERMITIAN_PART_SINGLE_JUMP` | 稳定 jump corroboration；不证明 raw-$H$ inertia 或严格实根 |
| I2.3 跨离散阶数 candidate 漂移实验 | 在预先冻结的不同离散阶数下比较同一物理 mode 的 candidate | `PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE` | `ntot` 与 $M$ 两条三层单轴实验均返回完全相同的 saved candidate，并形成两条 conditional algorithmic hierarchy；terminal-cell 尺度只限制 sub-grid minimizer 解释 |

正式里程碑共 **3 个**。四个里程碑只是常见压缩目标，不是最低数量要求；本项目不再为纯
交接或误差账本凑出 I2.4。exact discrete root、额外 contour、完整 finite Hermitian、local
complex solve 和其他非阻断检查列入 `OPTIONAL`。

## 逐项解释

### I2.1 单零计数诊断

- **具体要解决什么问题：**I1 dip 附近是否没有 zero、混有多个 zero，或只是某个 inverse
  factor 的 pole。
- **为什么必须做：**只看 singular-value dip 可能把浅谷、pole 或 evaluator failure 当成谱候选。
- **计划检查什么：**这一里程碑已经完成；它冻结同一 finite family，并对主 determinant 与
  实际 inverse factors 分别计数。
- **什么结果可以接受：**主对象 count one，必要 factors count zero，branch/chart/factor 门稳定。
- **什么失败会阻止继续：**count 为零、多于一、不可解释，或 zeros/poles 无法分账。
- **完成后能支持什么结论：**只支持该有限维圆盘内条件性 count one；作为 candidate 的一条
  独立证据，不证明 continuous eigenvalue。

### I2.2 端点 sign-count/inertia-like jump 数值诊断

- **具体要解决什么问题：**I1.3 已发现 dip 的已知邻域两端，是否观察到一个稳定的
  endpoint surrogate sign-count/inertia-like jump，作为同一 evaluator 的结构一致性佐证。
- **为什么必须做：**count one 说明小复圆盘内存在有限维 zero，但不直接说明实轴 dip 对连续
  物理特征值的可信程度。端点 jump 是低成本、与重新扫描不同的佐证。
- **计划检查什么：**只检查已经冻结的左右端点和同一 evaluator；报告所用矩阵对象、结构缺陷、
  unresolved eigenvalues、端点分离与 sign counts。不得移动端点、重扫区间、二分、Newton、
  Brent 或启动复平面搜索。
- **什么结果可以接受：**端点 count 在预先固定的数值容差和对象下可解释、可重复，并明确报告
  jump 或 no jump。若使用 Hermitian part 或其他 surrogate，必须直接标为
  `inertia-like/sign-count diagnostic`，不能冒充 raw non-Hermitian matrix 的数学 inertia。
- **什么失败会阻止继续：**对象漂移、端点谱与数值 uncertainty 无法分离、unresolved 值被强行
  计正负，或结果对合理数值精度/容差极不稳定。no jump 本身是有效诊断，不得为得到 jump 改区间。
- **完成后能支持什么结论：**只能作为 same-evaluator corroboration，提高、降低或不改变已有
  dip 的数值可信度；它与 raw zero existence 没有逻辑蕴含关系，不能证明 crossing、严格实根、
  candidate 等于离散 eigenvalue，或给出真值误差。

### I2.3 跨离散阶数 candidate 漂移实验

- **具体要解决什么问题：**在预先冻结的不同离散阶数下，I1/I2 所识别的同一物理 mode 的
  算法输出 candidate 是否发生观测漂移，并记录 locator 对潜在 sub-grid minimizer 的分辨尺度。
- **为什么必须做：**单一离散阶数上的 dip、count 和 endpoint diagnostic 只能说明该离散对象
  值得关注；只有比较同一 mode 随离散变化的 candidate，I3 才有真实数据研究离散误差，而不是
  对一个孤立数字构造 estimator。
- **计划检查什么：**预先冻结物理对象、至少两个离散阶数、唯一主 refinement axis、各 level
  tuple、candidate functional、定位窗口/规则、solver policy 和 precision；每个阶数都记录
  candidate 与 terminal interval。不同维数的场/trace 必须映到预先定义的公共表示，完成
  phase alignment、mode overlap、邻近竞争 mode 检查，并只做解释漂移所必需的原矩阵
  residual、关键 factor health、非零 field participation、boundary matching 和复现检查。
  若同时改变多个离散轴，只能标为 composite hierarchy，I2 不作误差归因。本阶段已分别
  完成 `ntot` 轴和固定 $n_{\mathrm{tot}}=160$ 的 $M$ 轴；具体数值、阈值与证据边界见两套
  I2.3 design/review 与实验索引。
- **对象定义：**算法保存的 candidate 记为 $\widehat k_n$，candidate drift 直接定义为
  $\Delta^{\mathrm{cand}}_{ab}=\widehat k_b-\widehat k_a$。概念上的连续-$k$ score minimizer
  $k_n^{\min}$ 不是算法交付物，也未被精确计算。terminal interval 半宽 $u_n$ 只作
  minimizer-localization/search-resolution diagnostic；它不是 $\widehat k_n$ 的 uncertainty，
  不进入 $\Delta^{\mathrm{cand}}_{ab}$。
- **什么结果可以接受：**各阶数的 candidate 都可复现且属于同一物理 mode；直接报告 saved
  candidate 的 signed 与 absolute drift，并另列 terminal interval 与半宽。observed drift 大、
  小、为零或暂不单调都可以是有效科学结果，不以“必须收敛”定义成功。
- **什么失败会阻止继续：**离散阶数未预先冻结、不同阶数发生 mode swap 或 mode identity
  unresolved、candidate 定义变化，或 residual/factor/
  field/boundary 任一最低门说明 candidate 是明显伪影。
- **实际结果：**相同初始区间、五点 dyadic 规则、$L=0,\ldots,11$、27 个求值点、terminal
  spacing、tie band、winner rule、functional 与 solver 给出
  $\widehat k_{160}=\widehat k_{208}=\widehat k_{256}=1.832770289108157$；三项
  $\Delta^{\mathrm{cand}}=0$，相邻比较均为 `SAME_MODE`。每层 terminal interval 半宽
  $u_n=9.3132\times10^{-11}$，只说明潜在 sub-grid minimizer 的搜索分辨尺度。
- **追加 $M$ 轴结果：**固定 $n_{\mathrm{tot}}=160$ 后，$M=32,40,48$ 的三项 saved
  candidate 也均为 $1.832770289108157$；三项直接 drift 为零，两个相邻比较均为
  `SAME_MODE`。selector-gauge、repeat、raw residual、factor、field 和 boundary 门全部通过。
  最紧 `proxy_reduced` rcond 仅为门槛的约 $1.048$ 倍，必须作为后续数值 caveat 保留。
- **完成后能支持什么结论：**`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`；I3 可接收该
  candidate 序列并开始误差来源识别。不能声称 sub-grid minimizer 或 finite root 零漂移、
  收敛、saturation、已接近连续真值，或已有误差上界。

## OPTIONAL：不计入三个正式里程碑

| Optional item | 为什么不构成当前 blocker | 何时才升级 |
|---|---|---|
| exact finite Hermitian/Lagrangian proof 或 strict inertia theorem | I2.2 只需要候选可信度诊断，不以离散实根定理为目标 | 未来确需 rigorous signed-crossing/enclosure 时 |
| 第二种 count 方法、更多 contour、$N_k=128$ | I2.1 已完成成本适当的条件性 count one | count 稳定性、factor 或 branch 出现新异常时 |
| local complex refinement 或大范围复扫描 | 连续实谱支持实轴 candidate，I2 当前不需要证明 finite zero 精确位置 | 实轴证据出现无法解释的 residual/phase 异常且 I3 确实需要时；大范围扫描仍不推荐 |
| 完整 transport、adjoint、Gram、denominator 理论 | I2.3 只需足以判定同一 mode 的最低 identity 检查；完整理论由 I3 选定 estimator 后决定 | I3 具体公式把它列为输入时 |
| 第二参数、第二 mode、跨环境 parity、额外高精度 | 属于稳健性与可推广性，不阻止第一 candidate 进入误差研究 | 首个 estimator 路线跑通或准备提升论文 claim 时 |

## 与 I1 和 I3 的衔接

| 已完成输入 | I2 如何使用 | 不可自动推出 |
|---|---|---|
| I1.3 显著 dip 与窄区间 | 固定 I2.2 端点和 candidate 初始位置；I2.3 不再做宽区间发现式扫描，但可在各层预注册窗口内按同一规则定位 candidate | dip 是 exact root 或 continuous eigenvalue |
| I1.4 sampled readiness | 维持同一 branch/chart/factor/evaluator 语义 | 未采样处绝无异常 |
| I2.1 count one | 作为 candidate 的局部谱证据 | zero 位于实轴、等于 candidate 或对应非零 physical field |
| I2.2 endpoint jump/no-jump | 作为 same-evaluator corroborative diagnostic，不作独立证据计数 | strict inertia theorem、crossing 或实根存在定理 |
| I2.3 saved candidate 序列、observed drift 与 minimizer-localization diagnostic | 直接供 [[research/projects/eig-apost/implementation/i3/README|I3]] 识别误差源；当前 `ntot` 与 $M$ 两条轴均给出零 observed shift，不能单独提供非零 correction 或收敛证据 | 某类误差已经被分解、estimator 或 upper bound 已经得到 |

## 失败与停止规则

- I2.2 no jump、unresolved 或不稳定时，忠实保留结果；不移动端点、不自动转 complex search。
- I2.3 出现 mode swap、不可比较 candidate 或明显伪影时，不把漂移解释成交给 I3 的同一-mode
  refinement 数据；I1 dip 和 I2.1 count 仍保留。
- 历史 I2.2 的 `NaN/UNAVAILABLE`、`I2_2_STOP_THEORY_GATE`、失败 attempt 和 append-only
  output 均保持不变。
- 所有对主线有帮助但不回答独立科学问题的增强检查进入 `OPTIONAL`；不得为了达到四个而
  恢复 I2.4。任何阶段最多五个 milestone，但本 I2 当前只保留三个。

## 推荐阅读顺序

1. [[research/projects/eig-apost/implementation/ROADMAP|project roadmap]]；
2. [[research/projects/eig-apost/implementation/i1/README|I1 guide]]；
3. [[research/projects/eig-apost/implementation/i2/report|I2 stage report]]；
4. [[research/projects/eig-apost/implementation/i2/design|I2.1 frozen design]] 与
   [[research/projects/eig-apost/implementation/i2/review|I2.1 review]]；
5. [[research/projects/eig-apost/implementation/i2/design-2-2|historical I2.2 design]] 与
   [[research/projects/eig-apost/implementation/i2/review-2-2|historical I2.2 review]]；
6. [[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 frozen design]]、
   [[research/projects/eig-apost/implementation/i2/review-2-3|I2.3 independent review]] 与
   [[test/i2/k-drift/README|I2.3 ntot-axis experiment index]]；随后读
   [[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 M-axis frozen design]]、
   [[research/projects/eig-apost/implementation/i2/review-2-3m|I2.3 M-axis independent review]] 与
   [[test/i2/m-drift/README|I2.3 M-axis experiment index]]；
7. [[research/projects/eig-apost/implementation/open-problems#Current I2|Current I2 ledger]]；
8. [[research/projects/eig-apost/implementation/i3/README|I3 guide]]。
