<!-- Socratic Layer 1 questions for research-question convergence -->

# Socratic scoping questions

状态：两轮 Problem Framing 已完成，RQ 已确认；Methodology Reflection 第一轮已开始。

## 第一轮：Problem Framing

1. `[Q:CLARIFY]` 如果首篇论文只能认证一个谱对象，你真正想知道的是哪一个对象的
   误差：`A_QP` 型 transmission eigenvalue、`A_def` 型 line-defect guided mode，
   还是 cell Bloch multiplier？为什么它比另外两个更值得先做？

2. `[Q:CLARIFY]` 你说“特征值后验误差”时，希望论文最终回答的核心问题是什么：
   计算值离未知连续特征值有多远，当前计算是否可信，还是如何识别伪根与漏根？
   如果三者只能保留一个，哪一个才是你的主目标？

3. `[Q:PROBE]` 什么证据会让你相信一个误差指标确实跟踪了真实误差，而不只是跟踪
   同一离散矩阵的 residual 或 $\sigma_{\min}$？你愿意采用什么相对独立的参考真值？

4. `[Q:CLARIFY]` 第一篇论文是否愿意先限定在远离 Wood anomaly、带边和多重根的
   孤立简单实特征值；还是这些困难区本身就是你认为不可放弃的工程价值？

5. `[Q:PROBE]` 对你而言，“可发表”的最低贡献是一个经过系统验证的实用 indicator，
   一个有可靠性/效率证据的 estimator，还是带明确假设的上下界或认证算法？你愿意
   为更强主张承担多少理论工作？

## 记录规则

- 回答后只提取用户自己作出的范围和方法承诺。
- 至少完成两轮 Layer 1 对话，再形成 RQ Summary。
- 未经用户确认，不生成候选 RQ、FINER 分数、文献综述或完整研究报告。

## 第一轮回答记录

### 用户作出的范围判断

- `A_QP` 按原定义主要对应单物体或完美二维周期晶体；用户当前不把它直接视为
  线缺陷晶体的主要研究对象。
- 目标是在固定 $\beta$ 后，估计由最小奇异值扫描和局部细化得到的 $k_h$ 与未知真值
  $k_*$ 之间的误差。
- 现有动机来自两类计算表现的差异：一维波导或 `A_QP` 路线可出现约 `1e-11` 的
  最小奇异值，而线缺陷 trace-subspace formulation 的最好结果约为 `1e-3`--`1e-5`；
  用户不希望继续依靠这个数值的大小直觉判断可信度。
- 第一阶段接受正则范围：非 Wood anomaly、相关 lead multipliers 远离单位圆，并只考虑
  没有重根的孤立点谱。
- 当前没有可接受的 eigenvalue reference truth，也尚未决定成果应达到 indicator、
  estimator 或 certified bound 中的哪一级。

### 已提取 INSIGHT

1. `[INSIGHT: 研究的主要目标量是固定 beta 时扫描所得 k_h 与连续谱问题真值 k_* 之间的误差，而不是离散矩阵 sigma_min 本身。]`
2. `[INSIGHT: 研究动机是用可说明的误差量替代“最小奇异值越小越可信”的经验判断，特别解释 trace-subspace 线缺陷计算中 1e-3--1e-5 量级结果是否仍可能给出准确 k。]`
3. `[INSIGHT: 首阶段愿意限制在非 Wood、lead multipliers 与单位圆分离、孤立简单点谱的正则情形。]`

### 尚待澄清

1. 主谱对象是否正式限定为当前 trace-subspace line-defect coupled problem 的连续零点，
   而把 `A_QP` 和 cell Bloch pencil 仅作为组成模块或验证对象。
2. reference truth 是否可以来自与 trace-subspace BIE 不同的独立 formulation，还是必须
   有解析或 manufactured eigenpair。
3. 希望成果提供排序诊断、数值误差预测，还是严格误差上界。

## 第二轮回答记录

### 用户作出的范围判断

- 主要对象确定为 Fliss (2013) $\beta$-formulation 中的 line-defect crystal guided-mode
  eigenvalue：固定 $\beta$，扫描并细化 $k$。
- BIE formulation 保留；外部周期半波导条件暂不预设为 trace-subspace relation 或直接
  DtN operator。`A_QP` 可能继续作为 BIE 组件，但不是目标谱对象。
- 目标成果至少是能说明 $\lvert k_h-k_* \rvert$ 量级的 estimator；不把仅排序可信度的 indicator
  作为最终目标，也暂不追求可能过宽的严格上界。
- reference truth 可以是高精度独立方法或至少两种独立方法对同一 $k_*$ 的有效数字共识，
  类似以 Ewald 与 lattice sum 共同校准 MFS quasiperiodic Green function；不要求解析解。

### 新提取 INSIGHT

4. `[INSIGHT: 主要谱对象确定为 Fliss 2013 beta-formulation 中固定 beta 的 line-defect guided-mode eigenvalue，BIE 保留但 transparent boundary realization 尚未选定。]`
5. `[INSIGHT: 目标成果是预测 |k_h-k_*| 量级的 a posteriori estimator，而不是只排序结果的 indicator，也暂不追求可能过宽的 certified bound。]`
6. `[INSIGHT: reference truth 采用与目标离散尽量独立的高精度计算，优先要求两个或更多方法对 k_* 的有效数字达成一致；解析真值不是必要条件。]`

### 候选单句 RQ（待用户确认）

在固定 $\beta$ 的二维周期线缺陷晶体 $\beta$-formulation 中，能否从 BIE 离散计算所得量
构造 a posteriori estimator $\eta_h$，使其能可靠预测孤立简单 guided-mode eigenvalue
近似 $k_h$ 的真实误差 $\lvert k_h-k_* \rvert$ 的量级？

### Layer 1 → Layer 2 待答问题

1. `[Q:CLARIFY]` 上述单句是否准确表达研究问题，特别是是否应把 estimator 限定为
   “BIE 离散计算所得量”，而不是预先限定 trace-subspace 或 DtN？
2. `[Q:PROBE]` 在进入方法设计前，你当前认为 trace-subspace relation 与直接 DtN 中
   哪一条更可能支撑这个 estimator，理由是什么？如果尚不能选择，最需要哪一种先导
   数值证据来作决定？

## RQ 确认与方法承诺

- 用户确认候选单句 RQ，并要求只限定 BIE，不预设非周期方向无穷远条件的实现方式。
- 用户认为 trace-subspace 更接近可实现状态，但理论研究应先从 DtN 路线开始，因为
  现有理论文献似乎主要采用 DtN；该判断需在 Phase 2 核验，不能作为既成文献结论。
- 若 DtN 路线得到初步可行结果，再考虑扩展到 trace-subspace。
- reference truth 的后备层级：若无法获得两个以上独立方法的一致有效数字，至少采用
  一篇经核验的可靠文献所给参考数据。

`[COMMITMENT: 理论与 estimator 的第一条调查路线选择 DtN+BIE；trace-subspace 保留为已有实现和后续扩展对象。]`

### Layer 2 第一轮待答问题

1. `[Q:PROBE]` 在 DtN+BIE 路线中，你认为 $\eta_h$ 应首先解释哪一层误差：BIE
   boundary discretization、DtN/propagation approximation，还是 $k$ 扫描与局部细化？
   如果只能先处理一层，为什么？
2. `[Q:CHALLENGE]` 如果 DtN 路线只能得到一个依赖昂贵加密计算的两层差值，而不能
   从单次生产计算中给出误差量级，你还会把它视为满足 RQ 的 estimator 吗？你能接受
   estimator 额外运行多少次或多大分辨率的辅助计算？

## Layer 2 第二轮回答记录

### 用户作出的方法判断

- 第一优先误差层是 periodic half-guide DtN approximation，即用户所称的非周期方向
  无穷远截断误差。
- BIE boundary discretization 暂列为次要项。用户依据是光滑边界 Kress scheme、多个
  点源散射 reference tests，以及一维准周期波导中约 `1e-11` 的最小奇异值；这些依据
  尚未直接验证目标 line-defect eigenproblem 的误差传播。
- $k$-scan 暂列为次要项。用户观察到把 refinement interval 从约 `1e-6` 缩到 `1e-12`
  时，最小奇异值仍停留在 `1e-3`--`1e-5` 平台，没有复现一维问题中随区间细化显著
  下降的 dip。
- estimator 可采用多次辅助计算。对已定位的代表性 $k$，几十到几百次 local
  evaluations 可接受；用户报告完整 draft experiment 曾使用 27,525 次 evaluations，
  但该数字尚未在本阶段独立核验。

### 新提取 INSIGHT

7. `[INSIGHT: 第一版 estimator 优先针对 half-guide DtN approximation error；BIE quadrature 与 k-location error 暂作为需要控制但非首要估计的误差层。]`
8. `[INSIGHT: estimator 不要求 single-shot；对少量代表性 guided eigenvalues，允许几十到几百次局部辅助 evaluations。]`
9. `[INSIGHT: 当前 sigma_min 平台在 k-interval 继续缩小时保持 1e-3--1e-5，为“误差来自 operator approximation 而非漏扫极窄 dip”提供了待验证的经验假设。]`

### Devil's Advocate Checkpoint 1

结论记录在 `r-da1.md`：`REVISE`，无 Critical issue，有两项 Major issue：必须定义
具体 DtN approximation，并用单因素 refinement 排除 BIE/conditioning/mode-selection
混淆。

### Layer 2 收尾问题

1. `[Q:CLARIFY]` 你所说的 DtN approximation 具体准备怎样计算：截断到有限个周期胞元
   并施加终端条件、迭代 propagation/Riccati operator、截断 Bloch modes/trace basis，
   还是另一种构造？哪个参数将作为第一版 estimator 的 refinement parameter？
2. `[Q:CHALLENGE]` 你是否接受这样的最低隔离要求：在代表性 $k_h$ 附近，先把 BIE
   加密到观测上稳定，再只改变 DtN resolution；随后冻结高精度 DtN、只改变 BIE
   resolution？什么观测结果会使你放弃“DtN error 主导平台”的假设？

## Layer 2 收尾回答与 Phase 2 入口

- 用户当前不知道 periodic half-guide DtN 的独立连续定义和直接数值构造；只知道
  Joly、Fliss、Coatléven 等路线中的 propagation/Riccati operator equation，并要求
  Phase 2 从原始文献澄清定义，不能先定义 trace-subspace 再反向定义 DtN。
- Phase 2 还需检索 `BIE + DtN`，辨别积分方程文献所谓“直接计算 DtN”的具体含义和
  BIE--DtN 接口。
- 用户接受单因素隔离。首个代表例采用与 `waveguide_1d` 相近的光滑椭圆设置，line
  defect 使用两个不同椭圆；参考现有 boundary-node counts，先固定 BIE 只改变 DtN。
- 若后续固定 DtN、改变 BIE nodes 导致约两位有效数字浮动，或 BIE 加密后误差反而
  增大，则重新评估 BIE error contribution。

10. `[INSIGHT: DtN definition 与 construction taxonomy 是 Phase 2 的首要证据缺口，且必须独立于 trace-subspace 定义。]`
11. `[INSIGHT: 单因素误差隔离实验采用相近的双椭圆 line-defect 代表例，并以两位有效数字浮动或非单调恶化作为重新评估 BIE error 的触发条件。]`

Layer 2 完成；Methodology Blueprint 见 `p-method.md`。用户已明确要求进入 Phase 2
检索，无需再次询问阶段切换许可。
