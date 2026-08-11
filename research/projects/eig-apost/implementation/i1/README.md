# I1 discrete operator readiness

## 当前状态

状态为 `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS`。本阶段已冻结当前 empty-center missing-column 模型的离散
$A_{\mathrm{def}}$ 候选、unsafe-chart graph 后备、one-cell pencil 到 half-guide Cauchy
subspace 的链条，以及下一实现阶段的接口与失败策略。两项独立 Skeptic 审查均报告
design-level `BLOCKER = 0`。尚未组装代码或运行任何数值实验。

当前 I1 仍保持：`DTN_NUMERICS=STOP`、`LOCATOR=STOP`、`ROOT_ISOLATION=STOP`。下一里程碑
允许 Engineer 在新的 `test/` 实验目录中实现纯组装和 algebraic oracle；该授权不包括
production half-guide qualification、$A_{\mathrm{def}}'$、任何 $k$ scan 或 root 工作。

## 本目录

- [[research/projects/eig-apost/implementation/i1/design|design.md]]：当前离散
  $A_{\mathrm{def}}$ 的唯一设计权威，含空间、基、符号、维数、QZ、chart、组装、导数和
  实现契约。
- [[research/projects/eig-apost/implementation/i1/review|review.md]]：记录两项独立
  Skeptic 的多轮审查、已修复 blocker、剩余 caveat 和授权边界。本阶段没有数值结果，
  因此不创建 `result.md`。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只记录新路线 I1--I4
  项目级依赖和退出条件。

## I1 内部里程碑

| Milestone | 内容 | 当前状态 | 下一门 |
|---|---|---|---|
| I1.1 discrete design | 连续 $\mathcal F$ 对应、empty-center $A_{\mathrm{def}}^{D/G}$、一般中心扩展、符号与尺寸 | `PASS WITH CONDITIONS` | 已通过两项独立 Skeptic；design-level blocker 为 0 |
| I1.2 assembly oracle | 只在新 `test/` 目录实现块组装、维数、Schur 等价、basis invariance 和 mutation negatives | `AUTHORIZED NEXT / NOT STARTED` | 不得扫描 $k$；不返回 production derivative |
| I1.3 half-guide graph/DtN qualification | one-cell pair、双向 ordered QZ、projective pair、`DIF/sep`、Dirichlet/Robin/graph 和实际 trace tail | `NOT AUTHORIZED` | 需 I1.2 通过及 M0 对应合同 |
| I1.4 derivative and balancing | 固定 analytic frame、$A_{\mathrm{def}}'$、adjoint/Gram、平衡前后等价与 CR | `NOT AUTHORIZED` | 需 I1.3 通过 |
| I1.5 locator readiness | anchored branch、小复圆盘、factor/pole ledger、negative cases 和非候选 anti-collapse | `NOT AUTHORIZED` | 需 I1.4 通过；通过后才可设计 locator |

## 权威和证据边界

连续真实谱对象仍由
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]] 定义。
I1 的当前设计只是它的有限维实现合同；OP-M0 的 kernel--field、continuous-to-cell、
analyticity 和 regular spectral approximation 证明缺口仍由
[[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 管理。

历史 numerical qualification 可作为部件证据，但不等于当前 $A_{\mathrm{def}}$ 已通过。
统一历史实验入口见
[[test/archive/legacy-route-v1/README#I4-DLP-TRACE-V1|I4-DLP-TRACE-V1]]；旧 augmented-BIE 和
finite-tail 只从
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]] 追溯。

## 推荐阅读顺序

1. [[research/projects/eig-apost/implementation/i1/design|I1 design]]。
2. [[research/projects/eig-apost/implementation/i1/review|I1 review]]。
3. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 和
   [[research/projects/eig-apost/implementation/open-problems#Current I1|current I1 ledger]]。
4. [[research/projects/eig-apost/phase4-report/method.tex|continuous method]]。
