# Eigenvalue a posteriori error research

本专题用于把仓库中的周期波导特征值计算，转向偏工程实现的特征值后验误差分析与
数值认证研究。当前按 Academic Research Suite 的 Deep Research 工作流推进，已经
形成受条件约束的方法稿并完成三个离散实现 checkpoint，但尚未形成可提升为统一主线
的理论或真实 estimator，也不是新的
`research/mainline/`。

## 权威和边界

- 状态：`active investigation`；Phase 2b novelty gate 与 Phase 3--4 方法设计已完成，
  当前离散实现达到 `STAGE2_DISCRETE_ALGEBRA_GO`，总门仍为 `ROOT_READY=STOP`。
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
    design.md
    SYMBOL.md
    experiment_plan.md
    nep-review.md
    half_guide_map.md
    half_guide_result.md
    half_guide_review.md
    aug-bie.md
    aug-bie-review.md
```

研究问题和 Methodology Blueprint 已确认，Phase 2 的 DtN/BIE/NEP 可行性调查已通过
带条件 checkpoint。Phase 2b novelty gate 已完成，verdict 为 `PASS WITH CONDITIONS`：
后续 Phase 3--4 已给出 fixed-representation root search 与条件 estimator，并形成方法稿。
Octave 实验随后依次关闭 manufactured NEP、Half-guide map 与 Augmented BIE 的有限维
implementation gates。它们不冻结 priority claim，也不把候选公式升级为连续定理或
certified estimator；真实 root search 尚未获准。

## 当前入口

- `p-scope.md`：Phase 1 的范围界定计划和进入 Phase 2 的门槛。
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
- `implementation/`：当前理论到代码的设计、符号表、实验计划和三个阶段的独立审查；
  其中 [[research/projects/eig-apost/implementation/aug-bie-review|Augmented BIE review]]
  是最新 gate，明确保持 `ROOT_READY=STOP`。
- `test/eig-apost-nep/`、`test/hg-map/`、`test/aug-bie/`：三个互相独立的 Octave 实验及
  可审计输出。当前交接、claim boundary 和下一门槛以
  [[research/projects/eig-apost/STATUS|project STATUS]] 为准。
