# Eigenvalue a posteriori implementation stage overview

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: handoff
- Origin Date: 2026-08-07
- Verification Status: METHOD RECONSTRUCTION REVIEWED; I4 NUMERICS PAUSED
- Version Label: eig-apost-stage-overview-v1.4
- Repro Lock: null

本文件是 `eig-apost` 专题从研究问题到当前数值实现状态的导航页。它回答“每一阶段为何
存在、具体做了什么、得到了什么、还不能说明什么”。详细数学定义、门槛和数值结果仍以
各阶段的 design、result、review 和实验输出为准；最新行动边界以
[[research/projects/eig-apost/STATUS|project STATUS]] 为准。

研究 Phase 编号和 implementation checkpoint 编号是两套不同序列：Phase 1--4 表示从
问题界定到方法稿的研究流程；I0--I4 表示把方法逐步转成代码实验的实现流程。

## 维护规则

以后每增加或重做一个阶段，都必须同步更新本文件。阶段条目至少写明：阶段编号和中英文
全称、它要解决的具体问题、实际完成的计算或推导、通过的门、失败或未验证的边界、当前
状态以及 design/result/review/test 入口。不得只留下缩写、目录名或 `GO`/`STOP` 标签而不
解释其含义；状态变化应保留审计历史，并在本页明确哪个 verdict 最新。

所有尚未解决但与当前工程目标有关的问题统一维护在
[[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]。每次
stage review 后只追加指向对应 stage 小节的 handoff 链接，不在各 review 重复复制一份会
逐渐漂移的清单。只有 ledger 中未解决的 `BLOCKER` 能停止当前阶段；`IMPORTANT CAVEAT`
和 `MINOR CAVEAT` 用于论文披露、廉价 sanity check 或后续稳健性工作。

## 从起点到当前位置

```text
研究问题与范围
  -> 来源和可行性核验
  -> search-bounded 新颖性门
  -> root / estimator 数学方案
  -> I0: manufactured root-and-correction algorithm
  -> I1: legacy finite-tail half-guide-map algebra
  -> I2: legacy augmented finite-tail center coupling
  -> I3a: Root-readiness proxy diagnostic
       [historical result: REVISE / BLOCKED_UPSTREAM_PROVENANCE]
  -> I3b: Source-derived proxy provenance closure
       [passed prerequisite: PASS WITH CONDITIONS]
  -> I4: Full analytic complex-k root-readiness
       [historical double ellipse: REPRODUCIBLE STOP / NO_SCREENED_DIP]
       [current Fliss benchmark: FD CANDIDATE READY]
       [sharp disk: SLP/DLP and finite M_trace screens passed]
  -> M0: continuous DtN/BIE method reconstruction
       [current: exact PDE-defined DtN -> continuous F(k) -> discrete QZ/DtN]
       [I4 NUMERICS PAUSED; finite-tail formulation is legacy/cross-check]
  -> future after M0 blockers: redesign A_def -> locator -> analytic readiness
             -> root isolation -> empirical correction -> independent reference
```

## 研究准备阶段：Phase 1--4

| 阶段全称 | 这一阶段解决的问题 | 已完成的工作与结论 | 权威入口 |
|---|---|---|---|
| **Phase 1 — Research Question and Methodology Framing（研究问题与方法范围界定）** | 明确到底估计哪个特征值误差、无限远误差来自哪里、何种 reference truth 才足够。 | 将目标收窄为 fixed-$\beta$ 二维周期线缺陷波导的 guided-mode wavenumber error；选择先研究 BIE 生成的 half-guide DtN 层级和 simple-root correction，并冻结非 Wood、孤立简单根等首版范围。此阶段没有数值结论。 | [[research/projects/eig-apost/phase1-scope/README|Phase 1 overview]]；[[research/projects/eig-apost/phase1-scope/rq-summary|RQ summary]] |
| **Phase 2 — Source Investigation for Dirichlet-to-Neumann Maps, Boundary Integral Equations, and Nonlinear Eigenvalue Error（DtN、BIE 与非线性特征值误差的来源调查）** | 核验 half-guide DtN 的定义与构造、BIE 到 Robin-to-Robin map（RtR，Robin 数据到 Robin 数据的边界映射）的接口，以及 simple nonlinear eigenvalue correction 的理论来源。 | 区分 DtN 的边值问题定义与 Riccati/doubling 构造；核验 BIE cell map、半波导传播和 simple-root perturbation 依据；明确相邻层级差必须在 saturation/remainder 条件下才能解释为剩余误差。 | [[research/projects/eig-apost/phase2-sources/README|Phase 2 overview]]；[[research/projects/eig-apost/phase2-sources/synthesis-dtn|source synthesis]] |
| **Phase 2b — Search-bounded Novelty Gate（有检索边界的新颖性门）** | 判断候选贡献是否只是已有 BIE、DtN、doubling 或通用 estimator 的重新组合。 | 结论为 `PASS WITH CONDITIONS`。不能宣称一般导模 estimator、BIE cell map 或 doubling 本身新颖；可继续研究的窄缺口是 numerical half-guide DtN error 到 fixed-$\beta$ guided eigenvalue shift 的 computable correction/effectivity。 | [[research/projects/eig-apost/phase2b-novelty/README|novelty overview]]；[[research/projects/eig-apost/phase2b-novelty/r-gate|novelty verdict]] |
| **Phase 3 — Mathematical Error Decomposition, Root Qualification, and Experiment Design（误差分解、根资格判定和实验设计）** | 把文献结论转成可实现、可反驳的算法：怎样区分实轴奇异值低谷和真实根，怎样定义 estimator，怎样分离误差来源。 | 设计 fixed-representation augmented nonlinear eigenvalue problem、anchored analytic branch、contour count、bordered Newton、adjacent-level projected correction、error budget、双椭圆 benchmark 和 independent-reference ladder。所有 estimator/effectivity 结论保持条件化。 | [[research/projects/eig-apost/phase3-analysis/README|Phase 3 overview]]；[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]]；[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]] |
| **Phase 4 — Continuous DtN/BIE Method Reconstruction（连续 DtN/BIE 方法重构）** | 恢复 Phase 1--2 的方法承诺：连续 DtN 和连续耦合算子必须先于有限 trace、QZ、doubling 和矩阵。 | 现行 `method.tex` 先定义精确 half-guide DtN、连续 $\mathcal F(k)$、outgoing Cauchy graph 和离散 QZ--DtN 链；旧的 finite-tail/doubling 稿完整归档为 superseded legacy。当前是受审查的理论设计，不是 root 或 estimator 结果。 | [[research/projects/eig-apost/phase4-report/method.tex|current continuous method]]；[[research/projects/eig-apost/phase4-report/legacy-tail.tex|legacy finite-tail formulation]] |

## 数值实现阶段：I0--I4

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
  [[research/projects/eig-apost/implementation/open-problems#I0|I0 open problems]]；
  `test/eig-apost-nep/output/report.md`。

### I1 — Legacy Finite-tail Half-guide-map Algebra

全称含义：**有限周期尾段的 half-guide-map 离散代数实验**。旧称 `hg-map` 或
`Half-guide map`；这里的 `HG` 只是 half-guide。2026-08-11 supersession 后，本实验只作
same-cell infinity-treatment cross-check，不定义精确 DtN，也不再承担主 estimator 层级。

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
- 状态：历史 Stage 1 `GO`；只保留为 legacy/cross-check，artifact-level reproducibility
  仍为部分完成。
- 入口：[[research/projects/eig-apost/implementation/half_guide_map|I1 design]]；
  [[research/projects/eig-apost/implementation/half_guide_result|I1 result]]；
  [[research/projects/eig-apost/implementation/half_guide_review|I1 review]]；
  [[research/projects/eig-apost/implementation/open-problems#I1|I1 open problems]]；
  `test/hg-map/output/report.md`。

### I2 — Augmented Boundary Integral Equation and Center Coupling

全称含义：**增广边界积分方程（Augmented Boundary Integral Equation, Augmented BIE）与
缺陷中心胞元—左右有限周期尾段耦合**。旧称 `aug-bie` 或 `Center coupling`；其历史目标不是
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
- 状态：历史离散代数 `GO`，但该 finite-tail matrix 不再定义当前主问题，
  `ROOT_READY=STOP`。
- 入口：[[research/projects/eig-apost/implementation/aug-bie|I2 design]]；
  [[research/projects/eig-apost/implementation/aug-bie-review|I2 review]]；
  [[research/projects/eig-apost/implementation/open-problems#I2|I2 open problems]]；
  `test/aug-bie/output/report.md`。

### I3 — Root-readiness Gate and Quasiperiodic Proxy Provenance Diagnostics

全称含义：**进入真实根搜索前的准备门，以及准周期 Green proxy system 的来源与固定表示
诊断**。它检查当前 BIE/proxy 计算能否形成一个在 complex $k$ 上可追踪、固定坐标、来源
一致的 matrix evaluator；它本身不搜索根。

- 做了什么：第一轮受控诊断在 $k=0.095,0.100,0.105$ 比较 production output、独立
  mirrored constructor、显式 SVD 和 seed-frozen reduced chart，并记录 base/refined
  proxy、Green、$A_{\mathrm{QP}}$、scattering 和 projector/source fingerprints。随后在
  `test/` 内建立 source-exact instrumented copy：锁定 package 与 executable-body 字节，
  让复制体返回其已有的 $A,b$，并使每个样本的五类 solver rows 使用同一 cache-derived
  $A,b$；保留旧门槛、加入 synthetic source mutation negative、completion marker 与
  baseline/repeat 原子发布。
- 通过了什么：provenance-closure 覆盖 base/refined 与三个实频率的 6 个 shared systems
  和 30 个 solver rows；package/copy public output、复制体系数、proxy field 和 residual
  差异均为 0。冻结的 $10^{-5}$ object gate 中 78/78 downstream rows 与 3/3 resolution
  rows 通过，aggregate maximum 为 $1.898507\times10^{-9}$；两次运行数值差为 0，
  direct-call manifest、shared-system 和 projector fingerprints 一致。
- 仍未通过或未验证什么：production 调用内部实际消费的
  $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍为 `NOT_DIRECTLY_OBSERVED`，所以通过标签只能是
  source-derived operational provenance。off-collocation readiness 没有冻结阈值，
  historical projectors 也只作非门控诊断；MATLAB parity 尚未运行。
- 没有运行什么：没有 candidate scan、complex disk、Cauchy--Riemann consistency test、
  pole ledger、contour root count、Newton、eigenvalue 或 estimator。
- 状态：第一轮独立 mirrored-constructor 诊断的历史 verdict 保持
  `REVISE / BLOCKED_UPSTREAM_PROVENANCE`；新的 provenance-closure 经 Researcher、
  Engineer 和 Skeptic 审查为 `PASS WITH CONDITIONS`；当时的历史 gate decision 为
  `GO -- FULL_ANALYTIC_COMPLEX_K_ROOT_READINESS ONLY`，已于 2026-08-11 被方法重构决定
  撤销。这一旧标签不再授权进入数值设计门；`PHYSICAL_ROOT_READY=STOP`，仍没有 root
  或 estimator。
- 入口：[[research/projects/eig-apost/implementation/root_readiness|I3 design]]；
  [[research/projects/eig-apost/implementation/root_result|I3 result]]；
  [[research/projects/eig-apost/implementation/root_readiness_review|I3 review，Section L
  是当前 verdict]]；
  [[research/projects/eig-apost/implementation/open-problems#I3|I3 open problems]]；
  `test/root-ready/provenance-closure/output/repeat/report.md`。

较早的 `test/root-ready/output/` 受控诊断在运行后发生过 design status-note 漂移，因此
其完整 worktree manifest 保持 `STALE`。新的 provenance-closure v1.1 把冻结 design 纳入
11 项 direct-call manifest；本轮收尾只更新 result/review/status/handoff，不改冻结 design，
所以新运行锁保持有效。两次复现仍只说明冻结离散实现一致，不能替代数学正确性证明。

### I4 — Full Analytic Complex-Wavenumber Root-readiness

全称含义：**完整复波数解析根准备门**。它试图先由实轴 locator 选择一个候选，再冻结
anchored Rayleigh branch、proxy chart/rank 和小复圆盘，检查 factor availability、完整
$240\times240$ 增广矩阵的 Cauchy--Riemann consistency 以及 N1--N11 负例；它仍不做
contour count 或 root solve。

- 做了什么：在 `test/root-ready/analytic-readiness/` 建立 source-derived、
  branch-injected test evaluator，冻结双椭圆几何、29 点实轴 locator、两套 proxy、四个
  chart、三种半径、三层 finite-tail、full-$F$ CR、factor/pole ledger、实际-object
  negatives 和事务化 baseline/repeat。package 源码未修改。
- 得到了什么：两次 Octave 运行均成功发布，所有复现 equality flag 为 1，数值相对差为
  0。29 个 locator 点全部 available，但 $s(k)$ 从 $0.2083091449$ 严格下降到右端点的
  $0.03539366850$；没有 strict interior minimum，且最小值约为冻结 $10^{-3}$ 门限的
  $35.4$ 倍。结果是 `REPRODUCIBLE STOP / NO_SCREENED_DIP`。
- 没有验证什么：没有 seed，因此 chart、disk、factor 和 CR ledger 均未运行；只有
  N1、N2、N5、N10 四个上游独立负例执行，其余七个为 `NOT_RUN_UPSTREAM_STOP`。没有
  contour、root、eigenvalue 或 estimator。
- 状态：证据为 `PASS WITH CONDITIONS`，科学阶段为 `STOP`；
  `PHYSICAL_ROOT_READY=STOP`，I5 不获授权。
- 入口：[[research/projects/eig-apost/implementation/i4-readiness|I4 design]]；
  [[research/projects/eig-apost/implementation/i4-result|I4 result]]；
  [[research/projects/eig-apost/implementation/i4-review|I4 review]]；
  [[research/projects/eig-apost/implementation/open-problems#I4|I4 open problems]]；
  `test/root-ready/analytic-readiness/output/repeat/report.md`。

用户随后把当前主模型改为相同左右周期端与 Fliss missing-column geometry；上述双椭圆
结论降为历史负例。替换 benchmark 在 `test/i4-fliss-2013/` 保持两个模型严格分离：

- Track A 使用 Fliss period-one smooth Gaussian coefficient。N80 finite strip 得到
  $\lambda_h=3.460975044$，相对论文值差 $0.116\%$；八/十二周期尾长相对位移
  $2.32\times10^{-7}$，mass overlap 为 $0.99999991$。N80/N120 targeted edge check 得到
  uncertainty $7.91\times10^{-4}$、safe gap $(1.981350,5.386819)$、candidate margin
  $1.479625$，四个门全部通过。状态为
  `TRACK_A_PROJECTED_GAP_CONFIRMED / I4_FD_CANDIDATE_READY`。
- Track B 使用 $n=\sqrt{17}$ 的 sharp disk 作为独立 BIE benchmark。新的 21 点
  Rayleigh-budget screening 把旧 transmission-rank/affine 失败降为历史路径：canonical
  $\delta=0.30$ 与 small-clearance $\delta=0.10$ 的 projective QZ/doubling core 在
  $M=5{:}20$ 的 same-$M$ gates 未观察失败，并分别给出 $[5,20]$、$[19,20]$
  right-censored candidate windows。$\delta=0.20$ 的目标 $k$ 有两个 neutral pairs，属于
  projected-band parameter point。
- 三个 high direct-wall/extractor errors 仍为 $4.28\times10^{-8}$--$1.50\times10^{-7}$，
  未过 $10^{-8}$，所以严格 $M_{\mathrm{trace}}$、$M_{\mathrm{stable}}$ 与 global interval
  均为 `NA / NA / NOT_CERTIFIED`。当前 operational label 为
  `BIE_RAYLEIGH_BUDGET_SCREENED / TRACE_EXTRACTOR_BLOCKED`。
- canonical extractor-only closure 见
  [[research/projects/eig-apost/implementation/i4-extract|I4 spectral extraction closure]]。
  其中 Bessel closed form 与 package extractor 共用 Rayleigh modal kernel；二者一致性只
  验证 modal integral 公式与实现，不再视为 qpgreen 谱表示的独立认证。
- 新 `test/i4-three-path/` 使用 Linton 式 (2.65) 的真 Ewald real/reciprocal split。Tables
  2--5 五个值最大误差为 $5.07\times10^{-11}$，项目点 Ewald--Rayleigh 最大误差为
  $1.11\times10^{-16}$。对同一冻结密度，完整 Ewald kernel 先做圆周积分再做 wall
  Fourier projection，与 Rayleigh extractor 的 SLP--D 系数最大差为
  $6.10\times10^{-16}$。因此当前参数的 value-level label 更新为
  `EWALD_VALUE_REFERENCE_CERTIFIED / SLP_D_EWALD_RAYLEIGH_PASS`。
- 历史 Octave package MFS 在项目 point 上最大误差为 $4.89\times10^{-8}$，在相同 Linton 五点上与
  合格 Ewald 的最大差为 $6.01\times10^{-8}$；SLP--D 中所有含 MFS 的比较
  最大误差为 $4.69\times10^{-8}$。四个 proxy 参数的单轴变化均超过
  $2\times10^{-9}$，而 boundary/wall quadrature 变化约为 $2.8\times10^{-11}$。
  当时的 blocker 标签为 `OCTAVE_AUGMENTED_MFS_PROXY_SOLVER_PATH_BLOCKED`；该三角关系只隔离
  Octave P path，未区分 solver backend、proxy basis 或 collocation。后续 MATLAB 结果见下两项。
- economy-SVD 在三个冻结点达到约 $10^{-12}$，但同 nominal cutoff 的 Octave `pinv(A,tol)`
  产生约 $10^{-5}$ 误差；所以尚不能把修复写成“调小 cutoff”，也不授权 wall $D/N$ 或
  $M_{\mathrm{trace}}$ claim。
- 新 `test/i4-three-path-derivatives/` 在 MATLAB R2023b 中认证了 Ewald analytic
  gradient/Hessian：Linton 五点最大误差仍为 $5.07\times10^{-11}$，独立 Richardson、
  Rayleigh derivative、Helmholtz、mixed/source-target 与 Ewald 单轴加密门全部通过。
- MATLAB package `lsqminnorm` 的函数值最大误差降到 $5.14\times10^{-10}$，但一个负分离
  hold-out 的三个 Hessian 分量仍为 $1.46\times10^{-8}$--$1.60\times10^{-8}$，因此在
  wall 前早停。fixed-$A,b$ 诊断排除了 wrapper 与 Hessian 公式，测得 solver spread
  $3.04\times10^{-8}$；这保留为 DLP--N 的下游 solver-rank blocker。test-local
  relative-$10^{-14}$ SVD 的 $2.90\times10^{-11}$ Ewald 误差仍未授权替换 package。
- action-specific full run 已认证 SLP--D：E--P/P--R 最大系数误差
  $4.33\times10^{-10}$，P proxy self 最大 $3.97\times10^{-10}$。SLP--N coefficient triangle
  通过到 $5.58\times10^{-9}$，但 P 的 Nside/Ntop/Nedge self changes 为
  $6.56\times10^{-9}$、$2.58\times10^{-9}$、$1.09\times10^{-8}$，故该历史 run 的 blocker 是
  `SLP_N_UNCERTIFIED_P_GX_PROXY_SELF_CONVERGENCE`；DLP--D/DLP--N 按顺序未运行。
- Researcher 没有继续加密上述历史 $p/d=0.7$ 路径，而是根据
  $G_{\mathrm{QP}}-G_0$ 最近周期镜像奇点冻结唯一 $p/d=0.2$。新
  `test/i4-proxy-rule/` 强制 MATLAB `lsqminnorm`、锁定 package/authority 哈希并保持原
  $2\times10^{-9}$ self、$10^{-8}$ coefficient 门。最终 SLP--D/SLP--N E--P 最大误差为
  $1.64\times10^{-14}$、$3.42\times10^{-14}$；SLP--N 四轴 self 最坏为
  $1.61\times10^{-13}$。因此 `SLP_D_N_CERTIFIED_PROXY_RATIO_0P2` 关闭 OP-I4-1f。
  此结论不认证 DLP、$M_{\mathrm{trace}}$、DtN 或 locator；package proxy 源列表的重复
  左下角使 rank 与 edge-DFT tail 只能作为非门诊断。
- 新 `test/i4-dlp-trace/` 延续相同 $p/d=0.2$、public MATLAB `lsqminnorm`、两制造密度
  与 $10^{-8}/2\times10^{-9}$ 原门，严格按 DLP--D、DLP--N、$M_{\mathrm{trace}}$
  顺序执行。DLP--D/DLP--N 三路径最大 coefficient 误差为
  $1.39\times10^{-14}$/$1.19\times10^{-13}$，DLP--N 四轴 wall self 最坏为
  $1.40\times10^{-13}$。保存的完整墙场在半网格 hold-out 上以 $M=48$ 重构时最坏误差
  为 $7.08\times10^{-12}$，$48<|m|\le96$ omitted energy 最坏为
  $5.00\times10^{-13}$。因此 `DLP_D_N_MTRACE48_CERTIFIED` 在当前几何、实数非 Wood
  参数、两密度和有限 $M_{\mathrm{ref}}=96$ 范围内关闭 OP-I4-1h/OP-I4-6；这不是任意
  BIE 解密度的无限尾定理。额外 $n_{\mathrm{tot}}/N_y$/Ewald wall ladders 未运行，列为
  `IMPORTANT CAVEAT`，不覆盖此前 point derivative qualification。
- 当前综合状态是 `PARTIAL SUCCESS`：已观察到第一个可信 real-case FD eigenvalue
  candidate，但 `PHYSICAL_ROOT_READY=STOP`，I5 仍不获授权。权威当前入口为
  [[research/projects/eig-apost/implementation/i4-fliss|I4 Fliss benchmark]]、
  [[research/projects/eig-apost/implementation/i4-rayleigh|I4 Rayleigh budget]] 和
  [[research/projects/eig-apost/implementation/open-problems#I4|I4 ledger]]。

2026-08-11 起 I4 数值工作暂停，进入 M0 理论方法重构。上述 Ewald/MFS/Rayleigh 与
$M_{\mathrm{trace}}$ 结果继续作为离散部件证据，但不再授权组装 $A_{\mathrm{def}}$、运行
locator、DtN wall experiment 或 root isolation。现行主链见
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]；旧的
finite-tail/doubling 主链见
[[research/projects/eig-apost/phase4-report/legacy-tail.tex|superseded legacy formulation]]。

## 后续阶段：距离真实特征值和 estimator 还有什么

| 顺序 | 阶段全称 | 具体要完成的工作 | 完成后才允许声称什么 |
|---:|---|---|---|
| M0 | **Continuous DtN/BIE Method Reconstruction（连续 DtN/BIE 方法重构）** | 冻结精确 DtN、连续 $\mathcal F(k)$、one-cell pencil 到 discrete graph/DtN 的桥接、公共 trace space 和误差分解；关闭 ledger 中 OP-M0-1--OP-M0-4。 | 只建立重新设计离散 $A_{\mathrm{def}}$ 的理论合同；仍没有 root。 |
| M1 | **Discrete $A_{\mathrm{def}}$ Redesign and Operator-level Consistency（离散矩阵重设计与算子层一致性）** | 让 $A_{\mathrm{def}}$ 成为 $\mathcal F_{h,M}(k)$ 的矩阵表示；验证 primal/adjoint、QZ separation、safe chart 或 augmented graph，以及相邻 $(h,M)$ level 的一致性。 | 通过后才可授权 bounded real-axis locator。 |
| M2 | **Locator and Analytic Root-readiness（定位与解析根准备门）** | 先做可解释的实轴定位，再冻结 anchored branches、fixed chart/rank、complex disk、CR 与 factor/pole ledger。 | 只在全部门通过后授权 contour root isolation。 |
| M3 | **Actual Root Isolation and Simple-root Qualification（真实离散根隔离与简单根资格判定）** | 隔离一个根、bordered Newton refinement，并检查左右 null vectors、$y^*\mathcal F'(k)x$ 和相邻层匹配。 | 首个 qualified discrete root；还不是连续 reference truth。 |
| M4 | **Two-level Eigenvalue Correction（两层特征值校正）** | 在公共 trace space/prolongation 上计算 $\mathcal F_{h_1,M_1}-\mathcal F_{h_0,M_0}$ 的左右向量投影并核对 actual next-level shift。 | 首先只得到 next-level correction；附加 saturation/remainder 后才可解释 remaining error。 |
| M5 | **Independent Reference and Effectivity（独立参考值与有效性）** | 建立可复现的高分辨率独立 reference、量化 reference uncertainty，并报告多层 correction、失败例和全误差预算。 | 可信真实二维 eigenvalue 与 empirical correction/effectivity case study。 |

既有 trace/extractor 子门已完成，Track A 的可信 FD 候选也已观察到；原双椭圆路径只保留
为历史负例。当前处于 M0，不能再用“只差一个 balanced $A_{\mathrm{def}}$”描述剩余距离。
关闭 M0 的四个理论 blocker 后才进入 M1；随后至少还需 locator/readiness、qualified root、
two-level correction 和 independent reference 四层工作。Fliss Gaussian 仍是不同模型，只
提供尺度参考。若目标升级为 certified interval，还需证明 saturation/remainder 和经过验证的
total error budget。

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
| QZ | Generalized Schur decomposition，广义 Schur 分解 | 当前主离散链中从 one-cell generalized pencil 计算 stable/unstable deflating subspaces；finite-tail/doubling 才只作 cross-check。 |
| SVD | Singular Value Decomposition，奇异值分解 | 用于提取最小奇异方向、数值秩和 seed-frozen proxy subspaces。 |
| CR | Cauchy--Riemann consistency，Cauchy--Riemann 一致性 | 诊断 complex-$k$ evaluator 是否表现为解析函数；有限差分通过不等于严格解析证明。 |
| $A_{\mathrm{QP}}$ | Quasiperiodic BIE matrix，准周期边界积分矩阵 | 由 proxy Green construction 生成的 center/cell BIE 离散矩阵。 |
| $\mathcal F(k)$ | Physical center--DtN operator function，物理中心域--DtN 算子函数 | 在 BIE representation、截断和 QZ 前定义；真实 guided eigenvalue 由 $\ker\mathcal F(k)\ne\{0\}$ 定义。 |
| $D_{s,M},N_{s,M}$ | Decaying Cauchy-data blocks，衰减 Cauchy 数据的 Dirichlet/Neumann blocks | 由右 stable、左 unstable ordered-QZ deflating subspaces 转换得到；只有 $D_{s,M}$ chart 安全时才形成 $N_{s,M}D_{s,M}^{-1}$。 |
| $F_{j,h}^{\mathrm{aug}}$ | Legacy augmented finite-tail matrix | 历史上把 center 和有限 tails 放在同一 block order；2026-08-11 后只作 cross-check/reference sequence。 |
| `GO` | 该阶段冻结的窄范围验收门通过 | 只对该阶段明确列出的离散对象有效，不能自动向后续阶段传播。 |
| `STOP` / `BLOCKED` | 上游条件未满足，后续量不可解释或不可计算 | 必须修复并重新审查；不得用调阈值或跳过检查绕过。 |

## 阅读顺序

1. 想快速恢复当前工作：先读本文件，再读
   [[research/projects/eig-apost/STATUS|project STATUS]]。
2. 想理解当前主方法：读
   [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]，再对照
   [[research/projects/eig-apost/phase4-report/legacy-tail.tex|superseded finite-tail formulation]]。
3. 想继续理论工作：读
   [[research/projects/eig-apost/implementation/open-problems#M0|M0 open problems]]、
   [[research/projects/eig-apost/phase2-sources/synthesis-dtn|DtN source synthesis]] 和
   [[research/projects/eig-apost/phase2-sources/r-nep-error|NEP error sources]]。在 OP-M0-1--4
   关闭前，不得组装 $A_{\mathrm{def}}$ 或运行 locator、DtN wall、contour、root。
4. 想追溯已完成的数值部件证据：读
   [[research/projects/eig-apost/implementation/i4-fliss|I4 Fliss benchmark]]、
   [[research/projects/eig-apost/implementation/i4-rayleigh|I4 Rayleigh budget]] 和
   [[research/projects/eig-apost/implementation/i4-extract|I4 spectral extraction closure]]。
