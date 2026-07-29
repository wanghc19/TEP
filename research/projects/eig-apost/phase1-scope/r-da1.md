<!-- Devil's Advocate Checkpoint 1 for the proposed methodology -->

# Devil's Advocate Checkpoint 1

日期：2026-07-26。

## Verdict: REVISE

没有 Critical issue；以下 Major issues 必须在形成 Methodology Blueprint 前解决。

## Critical Issues

No critical issues identified.

## Major Issues

### 1. “DtN 截断误差”尚未定义

- **Type:** Method / Scope
- **Problem:** 半波导 DtN 可以通过有限胞元截断、propagation/Riccati iteration、Bloch
  modal truncation、有限 trace basis 或其他方式近似。这些方案的可计算残差、收敛参数
  和误差机制不同；笼统称为“非周期方向截断”还不足以定义 $\eta_h$。
- **Impact:** 若近似对象和离散层级不明确，无法判断 estimator 在估计什么，也无法设计
  effectivity test。
- **Required revision:** 明确第一版 DtN approximation、refinement parameter 和可计算
  residual/difference。

### 2. BIE 误差次要性的证据尚未转移到目标问题

- **Type:** Evidence / Hasty generalization risk
- **Problem:** 光滑边界上的 Kress quadrature、散射点源 reference tests 和一维问题的深
  $\sigma_{\min}$ 支持 BIE 实现具有高精度的可能性，但它们没有直接控制当前 line-defect
  nonlinear eigenvalue problem 中 BIE block error 对 $k_h$ 的传播。
- **Impact:** 若 BIE error 与 DtN error 同阶，所谓 DtN estimator 可能只是在测量两者的
  混合扰动。
- **Required revision:** 在代表性 $k_h$ 附近分别冻结高精度 BIE 和高精度 DtN，一次只
  改变一个离散层级，检查 $k_h$ 位移和 estimator response。

## Minor Issues

- 以全区间 27,525 次 evaluation 为成本分母适合论文中的少量代表值验证，但未必代表
  estimator 在已定位特征值后的边际成本。应同时报告相对于一次 local solve/refinement
  的成本比例。
- $\sigma_{\min}$ 平台支持“继续缩小扫描区间不能降低离散残差”的观察，但尚不能单独区分
  DtN error、normalization、conditioning、mode selection 或 BIE error。

## Strongest Counter-Argument

最强反驳是：`1e-3`--`1e-5` 平台未必由无穷远 DtN approximation 主导，而可能来自
coupled matrix 的缩放/条件数、outgoing subspace selection 或 BIE--DtN 混合误差；若不做
单因素 refinement，DtN-first estimator 可能稳定地估计了错误的误差来源。

## What's Missing

- DtN approximation 的明确数学与数值定义；
- 能隔离 BIE、DtN 和 root-location error 的 refinement matrix；
- estimator 相对 local solve 而非 global discovery scan 的成本口径；
- $\eta_h/\lvert k_h-k_* \rvert$ 的 effectivity 判据和失败条件。

## Stress Test Results

| Test | Result |
|---|---|
| 移除“其他问题中 BIE 很准”的证据后，DtN 主导假设是否仍成立？ | 尚不成立 |
| 将平台解释为 conditioning 或 mode selection，是否同样符合观察？ | 是 |
| 方法是否能在不依赖完整 global scan 的情况下使用？ | 可能，但尚未定义 |
| RQ 的工程意义是否清楚？ | 是 |

## User Response Disposition

- `[DA-DECISION: Score 3/5 | ACTION: Hold | REASON: 用户明确承认 DtN 定义与数值构造未知并要求进入原始文献调查，但具体 approximation/refinement parameter 仍未解决。]`
- `[DA-DECISION: Score 5/5 | ACTION: Concede | REASON: 用户接受单因素 BIE/DtN refinement，并给出两位有效数字浮动或加密后误差增大的明确反证条件。]`

Phase-transition disposition：允许进入 Phase 2 Investigation 解决 Issue 1；在 DtN
definition/construction 明确以前，不冻结实验实现方案。
