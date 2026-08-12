# Eigenvalue a posteriori error research

本专题用于把仓库中的周期波导特征值计算，转向偏工程实现的特征值后验误差分析与
数值认证研究。当前按 Academic Research Suite 的 Deep Research 工作流推进，已经
形成受条件约束的方法稿、完成三个离散实现 checkpoint，并在历史受控诊断之后完成
source-derived proxy provenance closure；但尚未形成可提升为统一主线的理论或真实
estimator，也不是新的 `research/mainline/`。

## 权威和边界

- 状态：`active investigation`；当前新路线 I1.4 为
  `I1_4_PASS_WITH_CONDITIONS / SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS`。width-driven 局部
  加密在 $7.6294\times10^{-7}$ 区间宽度处记录 fixed-$M=48$ 离散候选
  $k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$。这不是 locator root 或
  eigenvalue；sampled complex-$k$ readiness 已条件通过，允许另行预注册 empirical I2
  isolation，但 locator/root 尚未运行，production derivative 和 estimator 仍不可用。
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
    design.md
    SYMBOL.md
    experiment_plan.md
    nep-review.md
    half_guide_map.md
    half_guide_result.md
    half_guide_review.md
    aug-bie.md
    aug-bie-review.md
    open-problems.md
    root_readiness.md
    root_result.md
    root_readiness_review.md
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
priority claim，也不把候选公式升级为连续定理或 certified estimator。当前新路线又完成
I1.1--I1.4，并记录上述 fixed-$M=48$ 离散候选和 sampled complex-disk readiness；下一步
只能另行预注册 derivative-free I2 contour/root isolation，当前仍没有真实 root。

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
- `implementation/README.md`：从 Phase 1 范围界定到 I3 Root-readiness 的阶段概述，逐项
  解释每个阶段全称、目的、已验证内容、未验证边界和后续依赖；长时间离开项目后应先读
  这一页。
- `implementation/open-problems.md`：按阶段维护 `BLOCKER`、`IMPORTANT CAVEAT` 和
  `MINOR CAVEAT`，记录各问题的 blocking scope、最低成本检查和状态；只有未解决的
  blocker 能停止当前工程路线。见
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]。
- `implementation/`：当前理论到代码的设计、符号表、实验计划和分阶段独立审查；
  最新证据与最终 delta verdict 分别见
  [[research/projects/eig-apost/implementation/archive/legacy-route-v1/i3-provenance/root_result|Root-readiness result]] 和
  [[research/projects/eig-apost/implementation/archive/legacy-route-v1/i3-provenance/root_readiness_review|Root-readiness review]]。
- `test/archive/legacy-route-v1/eig-apost-nep/`、`test/archive/legacy-route-v1/hg-map/`、
  `test/archive/legacy-route-v1/aug-bie/`、`test/archive/legacy-route-v1/root-ready/`：四个互相
  独立的 Octave 实验或受控诊断及可审计输出；I3 的当前权威输出在
  `test/archive/legacy-route-v1/root-ready/provenance-closure/output/`。当前交接、claim boundary 和下一门槛以
  [[research/projects/eig-apost/STATUS|project STATUS]] 为准。
