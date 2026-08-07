<!-- Phase 1 scoping plan for eigenvalue a posteriori error research -->

# Phase 1 scoping plan

> **Status: COMPLETED / HISTORICAL PHASE 1 PLAN.** 本文件保留项目启动时的范围选择、
> Phase 1 工作包和进入 Phase 2 的原始门槛，作为
> [[research/DECISIONS|research decisions]] 中启动 `eig-apost` 专题的决策证据。下文的
> “当前”“仍需”等措辞应按 Phase 1 当时的时间点阅读，不代表现行任务状态。已确认的
> Research Question 见
> [[research/projects/eig-apost/phase1-scope/rq-summary|RQ summary]]，Phase 1 方法输出见
> [[research/projects/eig-apost/phase1-scope/p-method|Methodology Blueprint]]；当前阶段、
> 阻塞项和下一步以 [[research/projects/eig-apost/STATUS|project STATUS]] 及
> [[research/projects/eig-apost/implementation/README|implementation stage overview]] 为准。

## 目标

把“偏工程实现和特征值后验误差”收敛成一个可由现有代码支撑、可构造数值证据、
并能明确说明误差对象的 research question。当前计划不选择答案，只明确需要作出的
研究决定和进入下一阶段的门槛。

## 不变约束

1. 不重写或扩展冻结主线，也不建立新的 `research/mainline/`。
2. 不把旧草稿、归档命题、小奇异值、分辨率收敛或低线性残差当作谱正确性的证明。
3. 不改变数学模型或 MATLAB 接口；Phase 1 只读盘点。
4. 区分证据、推断和建议；本地文献索引中的结论将在 Phase 2 独立核验。

## 需要收敛的研究轴

| 研究轴 | Phase 1 必须确定的内容 |
|---|---|
| 谱对象 | 首篇论文究竟研究 transmission eigenvalue、line-defect guided mode，还是 cell Bloch multiplier。 |
| 误差目标 | 估计连续特征值误差、离散后向误差、残差到误差的关系，还是伪根/漏根风险。 |
| 参考真值 | 哪类独立参考可用于判断指标是否跟踪真实误差，而不只是跟踪本方法自身残差。 |
| 参数范围 | 是否先限制为实参数、孤立简单特征值、远离 Wood/带边/多重根的正则区间。 |
| 贡献强度 | 目标是可复现实用 indicator、经验可靠的 estimator，还是带假设的上下界/认证。 |

## Phase 1 工作包

1. 材料定位：记录可复用的计算模块、现有诊断量、历史结果和候选本地来源。
2. 问题界定：通过两轮以上 Layer 1 对话确定一个单句 research question 方向。
3. 初步 FINER 自评：只记录用户对可行性、兴趣、新颖性、伦理和相关性的判断，
   不在 Socratic 阶段替用户评分。
4. 范围门：写出 in-scope、out-of-scope、待核假设和可证伪的成功判据，并由用户确认。

## 进入 Phase 2 的必要条件

- 有一个单句、非复合的候选 RQ；
- 明确主要谱对象和主要误差目标；
- 至少指出一种与待测算法非同源的参考真值或交叉验证路径；
- 明确第一篇论文暂不覆盖的困难参数区；
- 用户显式确认 Phase 1 输出。

门槛通过后，Phase 2 才开始系统检索和来源核验；后续才依序开展误差分解、候选指标
比较、数值验证设计、试验实现和论文材料组织。

## Layer 1 已收敛的范围

- 谱对象：Fliss (2013) $\beta$-formulation 中固定 $\beta$ 的 line-defect guided-mode
  eigenvalue。
- 主要目标：构造能预测 $\lvert k_h-k_* \rvert$ 量级的 a posteriori estimator。
- formulation 边界：保留 BIE；trace-subspace relation 与直接 DtN 暂不选边。
- reference truth：采用尽量独立的高精度 formulation，优先要求两个或更多方法对
  $k_*$ 的有效数字达成一致。
- 首阶段范围：非 Wood、lead multipliers 与单位圆分离、孤立简单点谱。
- 不追求：只给定性排序的 indicator；当前也不以严格但宽泛的 certified bound 为目标。

RQ 已由用户确认并记录在 `phase1-scope/rq-summary.md`。Layer 2 的初始方法承诺是先调查
DtN+BIE estimator，再考虑向已有 trace-subspace 实现扩展；该顺序仍需方法反思和
Phase 2 文献证据检验。

## 阶段关闭说明

Phase 1 的五个主要范围决定均已关闭：谱对象选为 fixed-$\beta$ line-defect guided-mode
eigenvalue；误差目标选为预测 $\lvert k_h-k_*\rvert$ 量级的 a posteriori estimator；
首版参数范围限制在非 Wood、单位圆分离和孤立简单点谱；reference truth 要求尽量独立的
高精度 formulation；贡献强度目标为可检验的 quantitative estimator，而不是只有排序
作用的 indicator。

对应的 Phase 1 产物为：

- [[research/projects/eig-apost/phase1-scope/materials|materials]]：启动时的代码、结果和
  本地来源入口清单；
- [[research/projects/eig-apost/phase1-scope/rq-summary|RQ summary]]：用户确认的研究问题、
  FINER 自评和范围边界；
- [[research/projects/eig-apost/phase1-scope/p-method|Methodology Blueprint]]：进入来源调查
  前的方法承诺和停止规则；
- [[research/projects/eig-apost/phase1-scope/r-da1|Devil's Advocate Checkpoint 1]]：对范围
  与方法选择的第一轮反方审查。

此后已完成 Phase 2 来源核验、Phase 2b novelty gate、Phase 3 数学与实验设计、Phase 4
方法稿，以及 I0--I3 数值实现 checkpoint。它们不回写到本历史计划；完整演进路线统一在
[[research/projects/eig-apost/implementation/README|implementation stage overview]] 维护。
