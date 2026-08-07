# Eigenvalue a posteriori implementation stage overview

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: handoff
- Origin Date: 2026-08-07
- Verification Status: UNVERIFIED
- Version Label: eig-apost-stage-overview-v1.0
- Repro Lock: null

本文件是 `eig-apost` 专题从研究问题到当前数值实现状态的导航页。它回答“每一阶段为何
存在、具体做了什么、得到了什么、还不能说明什么”。详细数学定义、门槛和数值结果仍以
各阶段的 design、result、review 和实验输出为准；最新行动边界以
[[research/projects/eig-apost/STATUS|project STATUS]] 为准。

研究 Phase 编号和 implementation checkpoint 编号是两套不同序列：Phase 1--4 表示从
问题界定到方法稿的研究流程；I0--I3 表示把方法逐步转成代码实验的实现流程。

## 维护规则

以后每增加或重做一个阶段，都必须同步更新本文件。阶段条目至少写明：阶段编号和中英文
全称、它要解决的具体问题、实际完成的计算或推导、通过的门、失败或未验证的边界、当前
状态以及 design/result/review/test 入口。不得只留下缩写、目录名或 `GO`/`STOP` 标签而不
解释其含义；状态变化应保留审计历史，并在本页明确哪个 verdict 最新。

## 从起点到当前位置

```text
研究问题与范围
  -> 来源和可行性核验
  -> search-bounded 新颖性门
  -> root / estimator 数学方案
  -> I0: manufactured root-and-correction algorithm
  -> I1: finite-tail half-guide DtN map
  -> I2: augmented BIE center coupling
  -> I3: Root-readiness proxy/provenance gate
       [current: REVISE / BLOCKED_UPSTREAM_PROVENANCE]
  -> future: analytic root isolation -> empirical estimator -> real-case validation
```

## 研究准备阶段：Phase 1--4

| 阶段全称 | 这一阶段解决的问题 | 已完成的工作与结论 | 权威入口 |
|---|---|---|---|
| **Phase 1 — Research Question and Methodology Framing（研究问题与方法范围界定）** | 明确到底估计哪个特征值误差、无限远误差来自哪里、何种 reference truth 才足够。 | 将目标收窄为 fixed-$\beta$ 二维周期线缺陷波导的 guided-mode wavenumber error；选择先研究 BIE 生成的 half-guide DtN 层级和 simple-root correction，并冻结非 Wood、孤立简单根等首版范围。此阶段没有数值结论。 | [[research/projects/eig-apost/phase1-scope/README|Phase 1 overview]]；[[research/projects/eig-apost/phase1-scope/rq-summary|RQ summary]] |
| **Phase 2 — Source Investigation for Dirichlet-to-Neumann Maps, Boundary Integral Equations, and Nonlinear Eigenvalue Error（DtN、BIE 与非线性特征值误差的来源调查）** | 核验 half-guide DtN 的定义与构造、BIE 到 Robin-to-Robin map（RtR，Robin 数据到 Robin 数据的边界映射）的接口，以及 simple nonlinear eigenvalue correction 的理论来源。 | 区分 DtN 的边值问题定义与 Riccati/doubling 构造；核验 BIE cell map、半波导传播和 simple-root perturbation 依据；明确相邻层级差必须在 saturation/remainder 条件下才能解释为剩余误差。 | [[research/projects/eig-apost/phase2-sources/README|Phase 2 overview]]；[[research/projects/eig-apost/phase2-sources/synthesis-dtn|source synthesis]] |
| **Phase 2b — Search-bounded Novelty Gate（有检索边界的新颖性门）** | 判断候选贡献是否只是已有 BIE、DtN、doubling 或通用 estimator 的重新组合。 | 结论为 `PASS WITH CONDITIONS`。不能宣称一般导模 estimator、BIE cell map 或 doubling 本身新颖；可继续研究的窄缺口是 numerical half-guide DtN error 到 fixed-$\beta$ guided eigenvalue shift 的 computable correction/effectivity。 | [[research/projects/eig-apost/phase2b-novelty/README|novelty overview]]；[[research/projects/eig-apost/phase2b-novelty/r-gate|novelty verdict]] |
| **Phase 3 — Mathematical Error Decomposition, Root Qualification, and Experiment Design（误差分解、根资格判定和实验设计）** | 把文献结论转成可实现、可反驳的算法：怎样区分实轴奇异值低谷和真实根，怎样定义 estimator，怎样分离误差来源。 | 设计 fixed-representation augmented nonlinear eigenvalue problem、anchored analytic branch、contour count、bordered Newton、adjacent-level projected correction、error budget、双椭圆 benchmark 和 independent-reference ladder。所有 estimator/effectivity 结论保持条件化。 | [[research/projects/eig-apost/phase3-analysis/README|Phase 3 overview]]；[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]]；[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]] |
| **Phase 4 — Integrated Method Draft and Mathematical Review（综合方法稿与数学审查）** | 将 Phase 2--3 的定义、算法、条件和停止规则整理成一次性可读的方法文稿，并检查 writer 是否改变数学逻辑。 | 形成 `method.tex`；独立 Skeptic 检查 root search、augmented equations、projected correction、coarse/fine error 含义和 reliable-interval 条件，最终为 `PASS WITH CONDITIONS`。它是方法设计，不是已验证的真实案例。 | [[research/projects/eig-apost/phase4-report/method.tex|integrated method draft]] |

## 数值实现阶段：I0--I3

### I0 — Manufactured Nonlinear Eigenvalue Problem Root-and-Correction Prototype

全称含义：**人为构造的非线性特征值问题（Nonlinear Eigenvalue Problem, NEP）根搜索与
校正原型**。它先把物理 BIE、半波导和分支问题全部拿掉，只验证通用数值算法本身。

- 做了什么：在一个解析可解的 $2\times2$ 非正规矩阵层级上实现实轴 locator、argument-
  principle contour count、bordered Newton、左右零向量和 simple-root qualification；实现
  root correction、map correction、total correction、matched next-level root 和 effectivity；
  另设 real-axis false dip、level scaling、wrong contour、polluted root 四个负例。
- 得到了什么：全部预注册数值门和负例通过，末级 manufactured tail effectivity 为
  `0.999987793`。结论只支持有限维 root/correction pipeline 的实现正确性。
- 没有验证什么：没有 BIE、DtN、Rayleigh branch、pole ledger、物理 guided mode 或
  certified interval。
- 状态：`GO`，但仅为 `conditional/empirical` manufactured-algorithm evidence。
- 入口：[[research/projects/eig-apost/implementation/design|I0 design]]；
  [[research/projects/eig-apost/implementation/nep-review|I0 review]]；
  `test/eig-apost-nep/output/report.md`。

### I1 — Finite-tail Half-guide Dirichlet-to-Neumann Map

全称含义：**由有限周期尾段逼近半无限波导的 Dirichlet-to-Neumann map（Dirichlet 数据到
外法向导数的映射）**。旧称 `hg-map` 或 `Half-guide map`；这里的 `HG` 只是
half-guide，不是另一个数学对象。

- 做了什么：从 one-cell scattering blocks 出发，实现非交换 Redheffer composition、
  recursive doubling、zero-incoming/Dirichlet/Robin terminal closure 和 Cayley transform；
  用解析 gap cell 给出独立代数真值，并用 generalized QZ（广义 Schur 分解）稳定/不稳定
  invariant graph 与一个含中心圆形介质夹杂的实际单胞（旧代码和报告称 `EDC cell`）的
  doubling 极限交叉比较；加入 Wood、BIE pole、
  terminal resonance、reversed Cayley order 等失败门。
- 得到了什么：非交换代数、解析 cell、实际单点 smoke 和负例均通过，Case B 最大误差约
  $1.93\times10^{-15}$。
- 没有验证什么：上述圆形介质夹杂单胞只是在同一 cell map 上做 QZ/doubling 交叉检查，
  不是独立 physical DtN truth；没有 center defect coupling、频率区间证明、map
  convergence theorem、eigenvalue 或 estimator。仓库历史材料没有给出 `EDC` 的可靠全称，
  因此本概述不猜测其展开，而用实际 fixture 的几何和材料含义描述它。
- 状态：Stage 1 `GO`；artifact-level reproducibility 仍为部分完成。
- 入口：[[research/projects/eig-apost/implementation/half_guide_map|I1 design]]；
  [[research/projects/eig-apost/implementation/half_guide_result|I1 result]]；
  [[research/projects/eig-apost/implementation/half_guide_review|I1 review]]；
  `test/hg-map/output/report.md`。

### I2 — Augmented Boundary Integral Equation and Center Coupling

全称含义：**增广边界积分方程（Augmented Boundary Integral Equation, Augmented BIE）与
缺陷中心胞元—左右有限周期尾段耦合**。旧称 `aug-bie` 或 `Center coupling`；其目标不是
再造一个 BIE，而是把 center BIE、Rayleigh port amplitudes 和 finite-tail scattering
equations 组装成同一固定维数矩阵。

- 做了什么：冻结九组 unknown/row block order，组装
  $F_{j,h}^{\mathrm{aug}}$；修正 variable-speed ellipse 的 Nyström density coordinate
  $\xi=D_h\eta$；分别验证 raw augmented matrix、center-scattering elimination、far-amplitude
  elimination 和独立 reduced Schur path；建立 Wood/BIE/doubling/terminal/raw-Schur/
  zero-field/scaling failure 的 availability ledger。
- 得到了什么：manufactured block oracles、density-scaling oracle、实际 ellipse/circle
  interface smoke、七个 finite-tail levels 和失败传播通过；结果为
  `STAGE2_DISCRETE_ALGEBRA_GO`，unchanged-source 数值复现差为 0。
- 没有验证什么：没有证明 continuous BIE kernel--field equivalence 或 representation
  injectivity；实际 ellipse 是 unscreened interface smoke；没有 analytic neighborhood、
  complex root、eigenvalue 或 estimator。
- 状态：离散代数 `GO`，但 `ROOT_READY=STOP`。
- 入口：[[research/projects/eig-apost/implementation/aug-bie|I2 design]]；
  [[research/projects/eig-apost/implementation/aug-bie-review|I2 review]]；
  `test/aug-bie/output/report.md`。

### I3 — Root-readiness Gate and Quasiperiodic Proxy Provenance Diagnostic

全称含义：**进入真实根搜索前的准备门，以及准周期 Green proxy system 的来源与固定表示
诊断**。它检查当前 BIE/proxy 计算能否形成一个在 complex $k$ 上可追踪、固定坐标、来源
一致的 matrix evaluator；它本身不搜索根。

- 做了什么：在 $k=0.095,0.100,0.105$ 比较 production output、mirrored pointwise
  pseudoinverse、显式奇异值分解（Singular Value Decomposition, SVD）和 seed-frozen
  reduced chart；记录 collocation 与 shifted
  off-collocation residual、base/refined proxy resolution、Green potential/gradient/Hessian、
  defect/bulk $A_{\mathrm{QP}}$ 和 scattering blocks；保存 rank 126/144 projectors 的数值
  fingerprint 与 source manifest，并完成 unchanged-source 双跑。
- 通过了什么：冻结的 $10^{-5}$ object-compatibility gate 中 78/78 downstream rows 和
  3/3 resolution rows 通过，aggregate maximum 为 $1.898508\times10^{-9}$；两次权威运行
  的数值向量、当时的 direct-call source manifest 和 projector fingerprints 一致。
- 失败或未通过什么：production 内部实际消费的 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 在当前
  接口下不可观测；coefficient、proxy field、residual 三个 $10^{-11}$ mirrored-output gates
  分别以 $2.798540\times10^{-7}$、$5.531552\times10^{-10}$、
  $1.250388\times10^{-9}$ 失败。off-collocation readiness 没有冻结阈值，仍为
  `PENDING_REVIEW`。
- 没有运行什么：没有 candidate scan、complex disk、Cauchy--Riemann consistency test、
  pole ledger、contour root count、Newton、eigenvalue 或 estimator。
- 状态：诊断执行完成，但科学 verdict 为 `REVISE / BLOCKED_UPSTREAM_PROVENANCE`；
  `ROOT_READINESS_SAMPLED_DISCRETE_GO=0`，`PHYSICAL_ROOT_READY=STOP`。
- 入口：[[research/projects/eig-apost/implementation/root_readiness|I3 design]]；
  [[research/projects/eig-apost/implementation/root_result|I3 result]]；
  [[research/projects/eig-apost/implementation/root_readiness_review|I3 review，Section K
  是当前 verdict]]；`test/root-ready/output/report.md`。

运行后只给 I3 design 增加了 post-experiment status note，因此当前 design hash 与运行时
manifest 不同。数值证据没有被改写，但当前完整 worktree manifest 应视为 `STALE`；不能
把“两次权威运行彼此复现”扩大成“当前所有文件仍与运行 manifest 相同”。

## 后续阶段：距离真实特征值和 estimator 还有什么

| 顺序 | 阶段全称 | 具体要完成的工作 | 完成后才允许声称什么 |
|---:|---|---|---|
| P1 | **Production Proxy-System Provenance Closure（production proxy system 来源闭合）** | 经用户明确授权后，让 `kernel.precomp_proxy` 可选返回其实际消费的 $A_{\mathrm{pr}},b_{\mathrm{pr}}$，或让 production 与诊断结构性共享同一 constructor；保持单输出行为不变，在不放宽阈值下重跑并审查。 | 获得可审计的共同 proxy system 和候选固定 chart；仍没有 root。 |
| P2 | **Full Analytic Root-readiness on a Complex Wavenumber Domain（复波数域上的完整解析根准备门）** | 冻结 anchored Rayleigh square-root branches、固定维数 $F_{j,h}(k)$、complex candidate disk、Cauchy--Riemann consistency、所有 BIE/terminal/Schur/proxy factors 的 pole/conditioning ledger 和反解析负例。 | 只在所有门通过后授权 contour root isolation；仍不是 physical truth。 |
| P3 | **Actual Double-Ellipse Root Isolation and Simple-root Qualification（真实双椭圆离散根隔离与简单根资格判定）** | 实轴扫描只作 locator；用 complex contour count 隔离一个根，用 bordered Newton refinement，并在相邻 tail levels 匹配同一 root，检查左右 null vectors、transverse derivative 和 conditioning。 | 首个 qualified discrete eigenvalue candidate；还不是独立验证的真实 guided eigenvalue。 |
| P4 | **Empirical A Posteriori Eigenvalue Correction and Effectivity（经验型特征值后验校正与有效性）** | 计算 matched $k_{j,h}$ hierarchy、projected map correction、root-solve correction、next-level shift consistency；用高分辨率 $k_{\infty,h}^{\mathrm{ref}}$ 比较 effectivity。 | 条件化、经验型 finite-tail estimator；没有 saturation/remainder 证明时不能称 certified interval。 |
| P5 | **Independent Real-case Validation（真实案例的独立验证）** | 做 proxy/BIE/port refinement、独立 half-guide/reference calculation、可行的外部 benchmark、代表性 eigenmode 检查和 MATLAB parity；分别量化 root、spatial、port、proxy 与 reference uncertainty。 | 若结果一致，可形成可信的真实二维 eigenvalue + empirical estimator case study。 |

预计 P3 完成后才可能出现首个 qualified discrete root；P1--P5 全部完成后才可能形成可信
的真实二维特征值与 empirical estimator 案例。若目标升级为 certified error interval，
还需要另外闭合 continuous center-BIE kernel--field equivalence / injectivity、half-guide
map saturation bound 与 correction remainder，以及 validated total error budget。

## 缩写和对象速查

| 缩写或代码名 | 全称 | 在本项目中的含义 |
|---|---|---|
| RQ | Research Question，研究问题 | 本专题要回答的单句问题；当前指 fixed-$\beta$ 线缺陷导模波数的后验误差估计。 |
| NEP | Nonlinear Eigenvalue Problem，非线性特征值问题 | 矩阵或算子 $F(k)$ 对谱参数 $k$ 非线性依赖，目标是寻找 $F(k)$ 的非平凡核。 |
| DtN | Dirichlet-to-Neumann map，Dirichlet 到 Neumann 映射 | 给定半波导边界 Dirichlet trace，返回面向中心区约定下的有符号 Neumann trace。 |
| RtR | Robin-to-Robin map，Robin 到 Robin 映射 | 将一组 Robin 边界数据映到另一组 Robin 数据；在 BIE/scattering 接口文献中作为 DtN 的替代坐标。 |
| BIE | Boundary Integral Equation，边界积分方程 | 用边界密度表示 center cell 或 one-cell scattering field。 |
| HG / hg-map | Half-guide / half-guide map，半波导映射 | 左或右半无限周期波导在中心截面上的反射或 DtN 对象；不是新的独立方程。 |
| EDC cell | 仓库旧代码和报告中的历史 fixture 标签；可靠英文展开未记录 | 本项目中具体指 $k=0.10$、折射率比 3、中心圆形介质夹杂的 one-cell BIE/scattering smoke fixture；不得仅凭缩写推断其他含义。 |
| QZ | Generalized Schur decomposition，广义 Schur 分解 | 从 scattering pencil 的稳定/不稳定 invariant subspace 构造 half-guide map 的 same-cell cross-check。 |
| SVD | Singular Value Decomposition，奇异值分解 | 用于提取最小奇异方向、数值秩和 seed-frozen proxy subspaces。 |
| CR | Cauchy--Riemann consistency，Cauchy--Riemann 一致性 | 诊断 complex-$k$ evaluator 是否表现为解析函数；有限差分通过不等于严格解析证明。 |
| $A_{\mathrm{QP}}$ | Quasiperiodic BIE matrix，准周期边界积分矩阵 | 由 proxy Green construction 生成的 center/cell BIE 离散矩阵。 |
| $F_{j,h}^{\mathrm{aug}}$ | Augmented finite-tail nonlinear eigenvalue matrix | 把 center density、center/far port amplitudes 和左右 finite-tail equations 放在同一固定 block order 中。 |
| `GO` | 该阶段冻结的窄范围验收门通过 | 只对该阶段明确列出的离散对象有效，不能自动向后续阶段传播。 |
| `STOP` / `BLOCKED` | 上游条件未满足，后续量不可解释或不可计算 | 必须修复并重新审查；不得用调阈值或跳过检查绕过。 |

## 阅读顺序

1. 想快速恢复当前工作：先读本文件，再读
   [[research/projects/eig-apost/STATUS|project STATUS]]。
2. 想理解为什么当前停在 Root-readiness：读
   [[research/projects/eig-apost/implementation/root_result|I3 result]] 和
   [[research/projects/eig-apost/implementation/root_readiness_review|I3 review Section K]]。
3. 想继续下一次实现：读
   [[research/projects/eig-apost/implementation/root_readiness|I3 frozen design]]、
   [[research/projects/eig-apost/implementation/SYMBOL|symbol/code ledger]] 和
   `test/root-ready/output/gate.csv`；未经用户明确授权，不得修改 `test/` 外 package helper。
4. 想追溯 estimator 的数学来源：读
   [[research/projects/eig-apost/phase3-analysis/s-root|root qualification]]、
   [[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]] 和
   [[research/projects/eig-apost/phase4-report/method.tex|integrated method draft]]。
