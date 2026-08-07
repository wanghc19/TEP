# Eigenvalue a posteriori open-problem ledger

本文件集中维护 `eig-apost` 各实现阶段仍与当前目标有关的问题。当前目标是一篇偏工程的
论文：先得到可运行、可复现、在代表性真实案例上有数值效果的 eigenvalue estimator，
并诚实说明适用范围；除非当前 claim 明确要求，不把 theorem-level certification 作为
默认验收条件。

各 review 保留其历史原文，只在末尾链接本 ledger。这里的分类按当前工程目标重新评估，
不回写或伪造旧 verdict。最新阶段状态仍以
[[research/projects/eig-apost/STATUS|project STATUS]] 为准。

## 分类与维护规则

- `BLOCKER`：会使当前阶段主要产物无效、不可解释，或直接阻止下一项必要计算。只有未
  解决的 blocker 才能触发 `STOP` 或 `BLOCKED`。
- `IMPORTANT CAVEAT`：显著限制范围、稳健性、复现性或解释，论文必须披露或安排检查，
  但不阻止当前阶段或下一阶段。
- `MINOR CAVEAT`：低影响限制、文档问题或可选稳健性扩展，可以延后。
- 每项必须给出 blocking scope 和 cheapest next check。若一个问题不能改变当前验收门或
  下一项计算，不再继续深挖。
- 每次 stage review 后由主 agent 合并 Skeptic handoff；Skeptic 保持只读。状态只使用
  `OPEN`、`SCHEDULED`、`RESOLVED` 或 `WONT-FIX FOR CURRENT CLAIM`。

## I0

**Manufactured Nonlinear Eigenvalue Problem Root-and-Correction Prototype。**
历史审查见
[[research/projects/eig-apost/implementation/nep-review|I0 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I0-1 | `IMPORTANT CAVEAT` | 三角形 manufactured NEP 弱化了通用非正规问题中左特征向量敏感性的测试。 | 只限制把 I0 推广成一般 NEP correction 验证；不阻止实际 BIE pipeline。 | 仅当真实 estimator 的 correction quotient 出现异常时，再加一个左右向量非共线的 $2\times2$ 或 $3\times3$ oracle。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I0-2 | `MINOR CAVEAT` | contour 位置利用了解析根知识。 | 不影响 I0 算法单元测试；限制其作为自动 locator benchmark。 | 在真实 root stage 使用只由实轴 locator 产生的预注册 disk。 | `SCHEDULED` |

## I1

**Finite-tail Half-guide Dirichlet-to-Neumann Map。**历史审查见
[[research/projects/eig-apost/implementation/half_guide_review|I1 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I1-1 | `IMPORTANT CAVEAT` | doubling 与 QZ 共享同一 one-cell map，不是独立 physical DtN truth。 | 限制 half-guide accuracy 的独立性陈述；不阻止使用该 map 搜索候选 root。 | 在两个附近的非 Wood 实频率，把高-$j$ finite-tail map 与 QZ limit 及一个更高分辨率 cell map 比较。 | `OPEN` |
| OP-I1-2 | `IMPORTANT CAVEAT` | 尚无严格 saturation 常数或 half-guide map remainder bound。 | 不阻止 empirical estimator；阻止 certified interval 或无条件 reliability claim。 | 在至少三个连续 $j$ levels 记录 map/root shift ratios，并用下一层实际 shift 检查预测。 | `SCHEDULED` |

## I2

**Augmented Boundary Integral Equation and Center Coupling。**历史审查见
[[research/projects/eig-apost/implementation/aug-bie-review|I2 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I2-1 | `IMPORTANT CAVEAT` | variable-speed ellipse 的 density scaling 目前只在 test-local path 验证，production helper 未统一。 | 限制 production-path 复用；不阻止冻结 test-local real-case experiment。 | 在两个空间分辨率上比较 scaled test-local assembly、field traces 和 scattering blocks；只有最终迁回 package 时才改 production。 | `OPEN` |
| OP-I2-2 | `IMPORTANT CAVEAT` | continuous kernel--field equivalence 与 representation injectivity 尚无证明。 | 对工程论文是 spurious-root 风险说明；只有出现近零 algebraic vector 但物理场消失时才升级为 blocker。 | 对候选最小奇异向量记录 center/port field energy、边界 residual 和一层空间 refinement overlap。 | `SCHEDULED` |

## I3

**Root-readiness Proxy Diagnostic and Source-derived Provenance Closure。**当前审查见
[[research/projects/eig-apost/implementation/root_readiness_review#L. Provenance-closure post-run review|I3 review Section L]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I3-1 | `IMPORTANT CAVEAT` | production 调用内部 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍未直接观测。 | 不阻止已通过的 source-derived path；只阻止更强的 runtime internal-array identity claim。 | 若论文需要该强 claim，再增加可选 diagnostic output；否则保持当前措辞。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I3-2 | `IMPORTANT CAVEAT` | provenance-closure 尚未做 MATLAB parity。 | 不阻止下一 Octave 实验；最终工程论文的跨环境复现需补。 | 在冻结源码上用命令行 MATLAB 各跑一次 baseline/repeat，并比较公开 CSV 指标。 | `SCHEDULED` |
| OP-I3-3 | `MINOR CAVEAT` | off-collocation residual 尚无独立冻结阈值，historical projectors 与当前 projectors 有约 $10^{-10}$ 的差异。 | 不影响 provenance verdict；只影响更强的 chart robustness 描述。 | 在 complex-$k$ stage 同时记录 densified off-collocation residual 和 rank/projector spread，不单开理论任务。 | `SCHEDULED` |

## I4

**Full Analytic Complex-Wavenumber Root-readiness。**这是下一实现阶段，尚无完成后的
review。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I4-1 | `BLOCKER` | 当前 evaluator 尚未在一个冻结 complex-$k$ disk 上数值验证 branch consistency、fixed chart、factor availability 与近似解析性。 | 直接阻止 contour root isolation，因为非解析或跨极点的矩阵族会使 root count 无意义。 | 冻结一个小 disk；运行 anchored branch algebra、fixed-rank/projector spread、factor minimum-rcond、full-matrix Cauchy--Riemann stencil 及 antiholomorphic/branch-breaking negatives。 | `SCHEDULED` |

## I5

**Actual Root Isolation and Simple-root Qualification。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I5-1 | `BLOCKER` | 尚无 count-one contour、converged bordered Newton root、simple-root derivative 和跨层匹配。 | 阻止把实轴小奇异值位置称为 eigenvalue，也阻止计算有意义的后验 correction。 | I4 通过后，只对一个预注册 disk 做 contour count、Newton 和相邻两个 $j$ levels 的 root matching。 | `OPEN` |

## I6

**Empirical A Posteriori Correction and Effectivity。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I6-1 | `BLOCKER` | 尚无 matched root hierarchy、resolved reference root 和 estimator effectivity。 | 阻止工程论文声称 estimator 能预测真实 eigenvalue error。 | 对同一 mode 计算至少三个 matched levels，以最高分辨率 reference 比较 predicted shift、actual next-level shift 和 effectivity。 | `OPEN` |
| OP-I6-2 | `IMPORTANT CAVEAT` | 尚无严格 saturation 与 correction-remainder bound。 | 不阻止 empirical estimator；只限制其被称为 certified 或 guaranteed。 | 报告 observed ratios、reference uncertainty 和失败案例，并把结论明确标为 empirical。 | `OPEN` |

## I7

**Independent Real-case Validation。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I7-1 | `IMPORTANT CAVEAT` | 单一参数/单一 mode 可能不足以说明工程稳健性，独立 reference 与 MATLAB parity 仍缺。 | 限制论文的可推广范围，但不必阻止第一份真实案例。 | 在第一案例跑通后增加一个附近参数或第二 mode，并执行一组 MATLAB parity 与独立高分辨率 reference。 | `OPEN` |
