<!-- Phase 1 Methodology Blueprint for eigenvalue a posteriori error research -->

# Methodology Blueprint

确认日期：2026-07-26。

## Research Paradigm

- **Selected:** quantitative computational mathematics with a pragmatic verification design.
- **Justification:** RQ 要求输出与 $\lvert k_h-k_* \rvert$ 同量级的可计算 estimator；其可信度既需要
  数学结构，也需要独立 reference truth、effectivity 和受控 refinement 的数值证据。

## Method

- **Type:** computational numerical-analysis study with literature-led method identification.
- **Primary route:** 先调查并澄清 periodic half-guide DtN 的连续定义和数值构造，再判断
  DtN+BIE 是否能提供可计算 estimator；trace-subspace 保留为后续扩展对象。
- **Formulation constraint:** BIE 保留，但 RQ 不预设 DtN、trace-subspace 或其他无穷远
  条件实现。
- **Initial test geometry:** 参考 `waveguide_1d` 的光滑椭圆设置，line defect 采用两个
  不同椭圆作为首个相近但非完全相同的代表例。

## Data Strategy

- **Secondary evidence:** 本地 Joly、Fliss、Coatléven 及相关 PDF；外部同行评审论文与
  正式元数据，重点检索 DtN definition/construction、Riccati/propagation、BIE+DtN 和
  nonlinear eigenvalue error estimation。
- **Primary numerical data:** 后续 MATLAB 计算中的 $k_h$、local $\sigma_{\min}$ curves、
  DtN resolutions、BIE boundary-node counts、运行成本和 reference values。
- **Reference hierarchy:** 两个或更多独立高精度方法的一致有效数字；不可得时，使用一篇
  经原文和元数据核验的可靠文献参考数据。

## Analytical Framework

1. 区分 continuous half-guide DtN、cell/propagation operator、Riccati equation 和
   discrete DtN matrix，不允许用 trace-subspace 反向定义 DtN。
2. 建立 DtN construction taxonomy：有限胞元、propagation/Riccati、modal/trace-basis、
   boundary-integral Calderón/local-solve 等，记录每种方法的输入、输出和离散参数。
3. 在代表性 $k_h$ 附近先固定高精度 BIE，只改变 DtN resolution；再固定高精度 DtN，
   只改变 BIE boundary resolution。
4. 以 reference $k_*$ 计算 observed error，并以 $\eta_h/\lvert k_h-k_* \rvert$ 检查 effectivity；
   只要求量级预测，不预设严格上界。
5. 成本同时相对于 global discovery scan 和一次 local solve/refinement 报告。

## Validity Criteria

| Criterion | Strategy |
|---|---|
| Construct validity | 明确定义 estimator 所估计的误差层，不把 $\sigma_{\min}$ 平台直接等同于 eigenvalue error。 |
| Internal validity | 单因素改变 DtN/BIE resolution，并监测 conditioning、normalization 和 mode selection。 |
| Reference validity | 优先多方法一致；单篇文献数据只在原文、参数和可复现条件核验后使用。 |
| Reliability | 保存全部参数、失败点、local curves 和运行成本；代表例重复计算。 |
| Estimator credibility | 在预先选定的代表例上报告 effectivity、误差量级命中率和失效条件。 |

## Falsification and Revision Rules

- 若固定高精度 DtN 后改变 BIE nodes 使 $k_h$ 出现约两位有效数字浮动，重新评估 BIE
  error contribution。
- 若 BIE 加密后 observed error 非单调增大，检查 quadrature、conditioning、normalization
  和 reference truth，不得继续预设 BIE 次要。
- 若只改变 DtN resolution 不改变 $k_h$ 或 estimator，而 BIE/mode-selection 改变会显著
  移动 $k_h$，放弃 DtN-dominance 假设。
- 若 estimator 只能反映 $\sigma_{\min}$ floor 而不能预测 $\lvert k_h-k_* \rvert$ 的量级，则 RQ 未回答。

## Limitations by Design

- 第一阶段不覆盖 Wood anomaly、lead spectrum 接近单位圆、重根或 clusters。
- DtN 的具体实现尚未选择；这是 Phase 2 Investigation 的第一门槛。
- 椭圆代表例优先服务于误差隔离，不支持对复杂几何的普遍结论。
- 数值 reference truth 不是严格数学真值，必须保留方法相关性和一致有效数字的限制。

## Ethics, Reporting, and Preregistration

- 无人类受试者或敏感数据；IRB 不适用。
- EQUATOR 医学报告规范不适用；采用数值分析的可复现性与 provenance 记录。
- 当前为 exploratory method-development，暂不 preregister；进入 confirmatory benchmark
  前可在 OSF 冻结算例、指标、effectivity 判据和排除规则。
