# Eigenvalue a posteriori error research

本专题用于把仓库中的周期波导特征值计算，转向偏工程实现的特征值后验误差分析与
数值认证研究。当前按 Academic Research Suite 的 Deep Research 工作流推进，已经
形成受条件约束的方法稿、完成三个离散实现 checkpoint，并在历史受控诊断之后完成
source-derived proxy provenance closure；但尚未形成可提升为统一主线的理论或真实
estimator，也不是新的 `research/mainline/`。

## 权威和边界

- 状态：`active investigation`；当前新路线为
  `I2_1_PASS_WITH_CONDITIONS / CONDITIONAL_EMPIRICAL_FINE_M48_COUNT_ONE`。I1 的 width-driven
  局部加密在 $7.6294\times10^{-7}$ 区间宽度处记录 fixed-$M=48$ dip 候选
  $k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$；I2.1 随后在同一冻结 fine
  圆盘上得到主 determinant 的 32/64 嵌套 count one，并分别得到全部 inverse factors 的
  zero winding。该结果没有给出 root 坐标，也不是 continuous eigenvalue；production
  derivative 和 estimator 仍不可用；I2.2 已完成实轴同对象两肩端点诊断并以
  `PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE` 收口。两端点态等价与 near-Hermitian
  implementation evidence 很强，但 exact Hermitian 和整段同族连续性义务未闭合，故
  inertia 为 unavailable，不能设计一维 root solve。
- 本目录只管理新专题；不续写或改写冻结的 Müller--Cauchy 主线。
- 归档理论、旧草稿中的命题和现有数值候选均不得被预设为正确。
- 生产 MATLAB/package 代码保持未修改；实验实现和生成结果只位于仓库根目录 `test/`
  的独立实验目录中。
- 本专题允许采用局部术语，但暂不建立仓库级统一记号。

## 阶段结构

当前阶段目录：

```text
eig-apost/
  README.md
  STATUS.md
  p-scope.md
  phase1-scope/
    README.md
    materials.md
    questions.md
    rq-summary.md
    r-da1.md
    p-method.md
  phase2-sources/
    README.md
    search-plan.md
    search-log.md
    r-dtn-def.md
    r-bie-dtn.md
    r-nep-error.md
    r-sources.md
    synthesis-dtn.md
    r-da2.md
  phase2b-novelty/
    README.md
    search-plan.md
    search-log.md
    claim-matrix.md
    r-sources.md
    r-gate.md
  phase3-analysis/
    README.md
    s-dtn-chain.md
    s-root.md
    s-errors.md
    s-estimator.md
    p-benchmark.md
    p-implement.md
    p-paper.md
  phase4-report/
    method.tex
  implementation/
    README.md
    ROADMAP.md
    SYMBOL.md
    open-problems.md
    i1/
      README.md
      design.md
      report.md
      review.md
    i2/
      README.md
      design.md
      design-2-2.md
      review.md
      review-2-2.md
    archive/
      legacy-route-v1/
```

研究问题和 Methodology Blueprint 已确认，Phase 2 的 DtN/BIE/NEP 可行性调查已通过
带条件 checkpoint。Phase 2b novelty gate 已完成，verdict 为 `PASS WITH CONDITIONS`：
后续 Phase 3--4 已给出 fixed-representation root search 与条件 estimator，并形成方法稿。
Octave 实验随后依次关闭 manufactured NEP、Half-guide map 与 Augmented BIE 的有限维
implementation gates。历史 Root-readiness early-stop diagnostic 的 $10^{-5}$ object
gate 通过，但独立 mirrored constructor 的三个 $10^{-11}$ output gates 失败。新的
provenance-closure 用 source-exact test-local copy 和同一 cache-derived $A,b$ 数据链重跑
原门槛，6 个 shared systems/30 个 solver rows 全部闭合，双跑数值差为 0，并由 Skeptic
给出 `PASS WITH CONDITIONS`。production 内部数组仍不可直接观测；该结论不冻结
priority claim，也不把候选公式升级为连续定理或 certified estimator。当前新路线已完成
I1.1--I1.4，并以 I2.1 Method 1B 将上述 fixed-$M=48$ dip 圆盘条件性隔离为一个按代数重数
计的 finite-dimensional zero。尚未定位该 zero、重构非零场或完成连续 kernel--field 桥；
I2.2 已按 [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 endpoint-structure design]]
完成 fail-close 结构资格，并由
[[research/projects/eig-apost/implementation/i2/review-2-2|independent review]] 限定为理论门 STOP；
不得把当前结果称为 inertia jump、实根或真实 physical eigenvalue。继续 inertia 或切换到
I2.1 小圆盘局部 complex refinement 都必须另行设计和审查。

## 当前入口

- `p-scope.md`：已完成的历史 Phase 1 范围界定计划；保留启动时的研究轴、工作包和
  Phase 2 入口门槛作为决策证据，不再作为当前计划维护。
- `phase1-scope/materials.md`：现有代码、草稿、结果和本地文献的只读材料清单。
- `phase1-scope/questions.md`：需要用户回答的第一轮 Socratic 收敛问题。
- `phase1-scope/rq-summary.md`：经用户确认的 RQ、初步 FINER 自评和范围边界。
- `STATUS.md`：当前进度、约束和下一门槛。
- `phase2-sources/`：DtN definition/construction、BIE--DtN interface 和来源核验。
- `phase2b-novelty/`：对候选贡献交叉执行 claim decomposition、近邻全文核验和
  search-bounded novelty gate；正式 verdict 见
  [[research/projects/eig-apost/phase2b-novelty/r-gate|r-gate]]。
- `phase3-analysis/`：误差分解、结构保持 finite-tail、root qualification、estimator、
  benchmark 与发表路线。
- `phase4-report/method.tex`：经 writer 整理和 skeptic 数学审查的方法稿。
- `implementation/README.md`：当前 I1--I4 实现路线的阶段概述，逐项
  解释每个阶段全称、目的、已验证内容、未验证边界和后续依赖；长时间离开项目后应先读
  这一页。
- `implementation/open-problems.md`：按阶段维护 `BLOCKER`、`IMPORTANT CAVEAT` 和
  `MINOR CAVEAT`，记录各问题的 blocking scope、最低成本检查和状态；只有未解决的
  blocker 能停止当前工程路线。见
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]。
- `implementation/i2/`：当前活动阶段；项目级状态、I2.1/I2.2 设计与独立审查分别见
  [[research/projects/eig-apost/implementation/i2/README|I2 guide]]、
  [[research/projects/eig-apost/implementation/i2/design|I2.1 design]] 和
  [[research/projects/eig-apost/implementation/i2/review|I2.1 review]]，以及
  [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]] 和
  [[research/projects/eig-apost/implementation/i2/review-2-2|I2.2 review]]。具体实验证据只从
  [[test/i2/k-count/README|I2.1 experiment index]] 与
  [[test/i2/h-inertia/README|I2.2 experiment index]] 进入。
- `test/archive/legacy-route-v1/eig-apost-nep/`、`test/archive/legacy-route-v1/hg-map/`、
  `test/archive/legacy-route-v1/aug-bie/`、`test/archive/legacy-route-v1/root-ready/`：四个互相
  独立的 Octave 实验或受控诊断及可审计输出；I3 的当前权威输出在
  `test/archive/legacy-route-v1/root-ready/provenance-closure/output/`。当前交接、claim boundary 和下一门槛以
  [[research/projects/eig-apost/STATUS|project STATUS]] 为准。
