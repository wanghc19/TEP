# Criteria (notes for agents)

Codes are for agents. In text for people, use the names in §6.

## 0. Indicator tree

```
最终目标 [T]：精度、保证形式、适用范围、成本
贡献
├── 更快 [C]：成本怎么量、怎么比、增长阶、使用场景
├── 更准 [A]：与参考解的误差、界的紧度、稳健性、数值敏感性
├── 保证更强 [G]：结论是什么、所需的量能否算出、证明状态、舍入误差
└── 适用范围更大 [S]：新问题类、旧方法失效的条件、旧方法做不了的算例、自身限制
前提条件表 [H]：类型 | 是否覆盖典型实例 | 能否检查及目前状态 | 不成立时的后果
贯穿各项：新颖性 [N]、控制变量 [V：外部条件；M：方法自身的差异]、证据 [E]
```

## 1. Claims, comparisons, evidence

A claim gives: contribution (C/A/G/S), number with source file (G and S
may state the change in words), baseline, control variables, evidence,
novelty.

**Control variables.** Name the indicator first. What must be held fixed
depends on the question the comparison answers.

- **External conditions V1–V5**, controlled in every comparison:
  V1 problem model and instance (geometry, parameters, target
  eigenvalue); V2 target quantity and unit ($\lambda$ or $k$, full or half
  width); V3 target accuracy or guarantee; V4 cost boundary (§2); V5
  hardware and software. A difference in one of these makes the
  comparison uncontrolled for that indicator; say so.
- **The methods' own differences M**: hypotheses (H tables), guarantee
  form (G), and internal construction (trial field, mesh, order,
  discretization space, parameters).
  - Comparing whole methods: M may differ. List it, and count the cost of
    each method's construction.
  - Comparing one component (e.g. two enclosure formulas): fix the other
    components (e.g. the same trial field).
  - The instance must satisfy both methods' hypotheses; the conclusion
    holds for instances in both scopes. When the indicator is G, the
    guarantee form is what is being compared.

Example: two enclosures built on different trial fields are a fair
whole-method comparison if the cost of each trial field is counted, but
they do not isolate the effect of the enclosure formula. A BIE route and a
FEM route with different hypotheses are comparable on an instance both
cover.

**Parameters.** Each side uses its best known configuration for the
target, with parameters and the rule that chose them stated (literature
default, a priori rule, or search). A search that must be repeated for
each new instance is part of the method: count its cost. Whether the
result depends on a lucky parameter is checked under robustness (A3).

**Evidence kinds** (list all that apply): E-pred prediction only; E-case
one instance; E-multi several instances or parameter points chosen for a
stated reason, with the range they cover; E-proof proof; E-proof+num
proof and numerics.

**How much evidence.** It follows the decision and the claim. For
screening, use existing surveys, reasoned predictions, and minimal checks;
do not do the paper's work in advance. For a claim in a paper or status
record, match the evidence to the claim type:

| Claim | Evidence |
|---|---|
| A beats B on this instance at this accuracy | one controlled measurement (repeat if timing noise matters); conclusion limited to that instance |
| the advantage persists as accuracy increases | several accuracy levels covering the claimed range; three is a starting point, not a proof of the range |
| lower asymptotic complexity | theory; a fit shows only the growth observed over the fitted range |
| a bound holds under listed conditions | proof |
| the bound holds on this instance | proof, plus the instance's conditions checked (H table, Q3) |
| the method is robust | targeted hard instances, not several easy nearby ones |

The reach of the evidence is the reach of the conclusion.

**Novelty N.** For each contribution, has the literature achieved it in
the same scope? Reuse existing surveys; search further only when missing
information would change the decision or a novelty claim is made. N1
depth: screening (existing record or a few written-down queries) or full
(queries, databases, date). N2: at most 3 closest works, one-line
difference each. The same method on a new instance inside its old scope,
with nothing improved, is not a contribution (a quadrature for smooth
curves on another smooth curve is not new; extended to corners, it is).

## 2. Faster (C) and more accurate (A)

- C1 cost measure: wall time, peak memory, dominant operation counts.
- C2 comparison: cost at equal error or error at equal cost, each side at
  its best known configuration.
- C3 growth: theoretical complexity vs. observed growth; report the fitted
  range and its stability.
- C4 use case: one-off vs. repeated queries; setup and per-query cost
  separately.
- V4 cost boundary:
  - comparing routes: fix a common start and output by the actual use
    case, and report every cost inside that boundary;
  - data prepared outside the boundary is listed with its cost and how it
    is reused. It may stay outside only if both sides use it in the same
    way (e.g. one FEM solution feeding two enclosure methods: record its
    time, do not recompute it). Preparation that only one side uses is
    inside, on that side;
  - with no shared upstream (e.g. BIE vs. FEM), the boundary starts at the
    problem model;
  - deciding whether to add a step: its incremental cost; shared work is
    listed separately and cancelled only here, and the total is still
    reported;
  - if the full cost is not available, report the measured parts and the
    missing ones; never present a partial cost as total.
- Report the measured ratio. A factor 2 over a decade of accuracy is a
  guideline for a strong claim, not a threshold; a stable 30% can matter
  under repeated queries.
- A1 error against a reference: report the ratio of the reference's error
  to the measured error; it must be small enough not to change the
  conclusion.
- A2 tightness: width and effectivity (bound / true error). Effectivity
  below 1 means the bound failed. Near 1 and stable under refinement is
  tight.
- A3 robustness: parameter range, hard cases (near a band edge,
  near-degenerate, high contrast, fine mesh), failure rate and mode.
- A4 sensitivity: condition-number growth, change under perturbation or
  higher precision, ill-conditioned steps.

## 3. Stronger guarantee (G)

Four separate items, not one ladder:

- G1 statement: estimate (fit, extrapolation, tuning) / asymptotic
  relation / inequality.
- G2 computability: list every quantity that cannot be computed from data
  and the numerical solution. An inequality with an uncomputable constant
  gives no number for the instance; it may still have theoretical value
  if it shows what remains. A mesh-dependent constant is fine if
  computable. Each uncomputable quantity becomes an H row.
- G3 proof status: conjecture / proved / proved and reviewed (say whether
  post-review fixes were re-reviewed).
- G4 rounding: ignored / estimated / controlled (interval arithmetic).

Truncation errors belong to G1, G2 and H, not G4. A G contribution is a
change in G1–G4 or in Q3 of some H row.

## 4. Wider scope (S) and hypotheses (H)

Scope is the set of problems satisfying all hypotheses. S1 new problem
class; S2 which hypothesis of old methods fails there; S3 an instance old
methods cannot handle; S4 own H table. A's scope contains B's if each
hypothesis of A follows from B's; otherwise "not comparable".

H table, one row per hypothesis; never compare by row count:

- Q1 type: model condition (restricts the class: smooth boundary,
  self-adjoint, only point spectrum in the gap) / instance condition
  (true or false per instance: one eigenvalue in the window).
- Q2 coverage: do typical target instances satisfy it? Name them.
- Q3 checkability and status: no method / numerical evidence / verifiable
  in principle / verified; with cost.
- Q4 failure: error reported / silent wrong result.

Severity, highest first: a model condition excluding typical instances; an
instance condition with no checking method and silent failure; one cheap
to verify.

## 5. Root goal (T)

T1 precision, T2 guarantee form, T3 scope (which problems the deliverable
must cover), T4 cost. Source: the user's words, the record of approval, or
the current stage configuration; say which. Ask only if a missing value
would change the decision.

Necessity:

- required for the root: no known route meets T1–T4 without it. State how
  far the search for routes went; "none found" is not "unavoidable";
- required only for the chosen method: another known route meets T1–T4
  without it. Its value depends on the comparison between the method and
  that route;
- not required.

A plan meeting T1–T4 only after lowering one of them is a fallback.

## 6. Names for people

| Code | 名称 |
|---|---|
| T1–T4 | 精度要求 / 保证形式要求 / 适用范围要求 / 成本要求 |
| necessity | 必需（总目标） / 只对当前方法必需 / 不必需 |
| C / A / G / S | 更快 / 更准 / 保证更强 / 适用范围更大 |
| N1 / N2 | 查新深度 / 最接近的工作 |
| V | 控制变量 |
| V1–V5 | 外部条件：问题模型和实例 / 目标量和单位 / 目标精度或保证 / 成本边界 / 硬件软件 |
| M | 方法自身的差异：前提条件、保证形式、内部构造（试探场、网格、次数、参数） |
| E-pred … E-proof+num | 只有预测 / 单个算例 / 多个算例 / 只有证明 / 证明加数值 |
| C1–C4 | 成本怎么量 / 比较方式 / 增长阶 / 使用场景 |
| A1–A4 | 与参考解的误差 / 界的紧度 / 稳健性 / 数值敏感性 |
| G1 | 结论是什么：估计 / 渐近关系 / 不等式 |
| G2 / G3 | 所需的量能否算出 / 证明状态：猜想 / 已证明 / 已证明并审查 |
| G4 | 舍入误差：未考虑 / 估计 / 控制 |
| S1–S4 | 新覆盖的问题类 / 旧方法失效的条件 / 旧方法做不了的算例 / 自身的限制 |
| Q1–Q4 | 类型 / 是否覆盖典型实例 / 能否检查及目前状态 / 不成立时的后果 |
| Q1, Q3 values | 模型条件 / 实例条件；没有方法 / 有数值证据 / 原则上可以验证 / 已验证 |
