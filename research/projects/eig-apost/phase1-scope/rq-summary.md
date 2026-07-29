<!-- Confirmed Socratic RQ Summary for eigenvalue a posteriori error research -->

# RQ Summary

确认日期：2026-07-26。

## Research Question Direction

在固定 $\beta$ 的二维周期线缺陷晶体 $\beta$-formulation 中，能否从 BIE 离散计算所得量
构造 a posteriori estimator $\eta_h$，使其能可靠预测孤立简单 guided-mode eigenvalue
近似 $k_h$ 的真实误差 $\lvert k_h-k_* \rvert$ 的量级？

## Preliminary FINER Self-Assessment

- Feasible：已有 BIE、Bloch 和 trace-subspace 计算组件；DtN 路线尚需调查和原型验证。
- Interesting：现有 $\sigma_{\min}$ 大小不能直接说明 $k_h$ 的可信位数，在线缺陷计算中尤其
  明显。
- Novel：尚未判断；必须通过 Phase 2 文献检索和来源核验决定。
- Ethical：待用户在 Phase 1 总确认时自评；当前描述的是计算研究，尚未提出人类受试者
  或敏感数据，但研究完整性仍要求来源、代码、参数和失败结果可追溯。
- Relevant：目标直接服务于 fixed-$\beta$ guided-mode eigenvalue 计算的误差解释和
  数值可信度。

## Preliminary Scope Definition

- Focus：固定实 $\beta$；Fliss (2013) $\beta$-formulation；BIE 离散；孤立简单点谱；
  非 Wood；相关 lead multipliers 与单位圆分离。
- Formulation boundary：保留 BIE，但不在 RQ 中预设非周期方向无穷远条件采用 DtN
  operator 或 trace-subspace relation。
- Initial methodology commitment：理论调查和初步可行性先从 DtN 路线开始；如果得到
  可行结果，再研究向已有 trace-subspace 实现的扩展。
- Reference truth：优先采用两个或更多独立高精度方法对 $k_*$ 的有效数字共识；若无法
  获得，则至少使用一篇经核验的可靠文献所报告的参考数据。
- Excluded for the first study：Wood anomaly、lead spectrum 接近单位圆、重根或
  eigenvalue cluster、严格但可能过宽的 certified upper bound。
- To be confirmed：DtN estimator 的可计算核心量、误差分解、独立 reference solver、
  estimator 校准与转移到 trace-subspace 的条件。

## Sub-question Direction

正式 sub-questions 尚未生成。它们必须在 Methodology Reflection 完成后分别覆盖：

1. estimator 所依赖的可计算量及其与 $\lvert k_h-k_* \rvert$ 量级的关系；
2. BIE、transparent boundary approximation 和 $k$-search 误差的分离；
3. reference truth 与 effectivity 验证设计。

以上方向继承同一 $\beta$、正则参数区和孤立简单点谱范围；不得在后续阶段静默扩展。
