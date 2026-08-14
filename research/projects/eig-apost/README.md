# Eigenvalue a posteriori error research

本专题用于把仓库中的周期波导特征值计算，转向偏工程实现的特征值后验误差分析与
数值认证研究。当前按 Academic Research Suite 的 Deep Research 工作流推进，已经
形成受条件约束的方法稿、完成三个离散实现 checkpoint，并在历史受控诊断之后完成
source-derived proxy provenance closure；但尚未形成可提升为统一主线的理论或真实
estimator，也不是新的 `research/mainline/`。

## 权威和边界

- 状态：`active investigation`；当前新路线为
  `I2_3_PASS_WITH_CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。I1 的 width-driven
  局部加密在 $7.6294\times10^{-7}$ 区间宽度处记录 fixed-$M=48$ dip 候选
  $k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$；I2.1 随后在同一冻结 fine
  圆盘上得到主 determinant 的 32/64 嵌套 count one，并分别得到全部 inverse factors 的
  zero winding。该结果没有给出 root 坐标，也不是 continuous eigenvalue；production
  derivative 和 estimator 仍不可用；I2.2 的历史 raw-$H$ inertia 支线以
  `PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE` 收口，而后续冻结
  $H_{\mathrm{sym}}=(H+H^*)/2$ 两肩端点 sign count 得到
  `PASS WITH CONDITIONS / HERMITIAN_PART_SINGLE_JUMP`。该 jump 只作 candidate 的数值佐证；
  exact raw-$H$ inertia、实根、continuous eigenvalue 与 error estimate 均未由此建立。
  I2.3 随后分别完成两条单轴实验：边界 Nyström 阶数
  $n_{\mathrm{tot}}=160,208,256$，以及固定 $n_{\mathrm{tot}}=160$ 的
  $M=32,40,48$ trace cutoff。两条轴均通过最低 candidate、factor、field、boundary、repeat
  与 `SAME_MODE` 检查；各轴的三项 saved candidate 完全相同，因此结果为
  `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。terminal-cell 半宽只作
  潜在 sub-grid minimizer 的搜索分辨率，不是 candidate uncertainty；该结果仍不证明
  minimizer/root 零漂移或收敛。
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
      design-2-3.md
      design-2-3m.md
      review.md
      review-2-2.md
      review-2-3.md
      review-2-3m.md
    i3/
      README.md
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
I2.2 已按 [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]] 完成两条
受控路线：历史 raw-$H$ structure preflight 忠实停止于 theory gate；当前
$H_{\mathrm{sym}}$ 两端 sign count 则得到稳定 `SINGLE_JUMP`，并由
[[research/projects/eig-apost/implementation/i2/review-2-2|independent review]] 接受为
numerical corroboration。它不证明 raw finite real zero 或真实 physical eigenvalue。I2.3 已按
[[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 design]] 完成三个预注册
$n_{\mathrm{tot}}$ 层的同-mode candidate 漂移实验；独立审查见
[[research/projects/eig-apost/implementation/i2/review-2-3|I2.3 review]]。随后又按
[[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 M-axis design]] 完成固定
$n_{\mathrm{tot}}=160$ 的 $M=32,40,48$ 实验；独立审查见
[[research/projects/eig-apost/implementation/i2/review-2-3m|I2.3 M-axis review]]。两条轴的
三层 candidate 均有效、完全相同且 mode identity 通过，故当前以
`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE` 收口。I3 可以接收这一 conditional algorithmic
candidate hierarchy 并开始误差来源与 independent-reference 设计；两条轴的零 observed
shift 不能单独提供非零 correction、收敛证据或误差界。误差来源的识别和分解仍由 I3 负责。
I3.1 当前先估计 candidate 到 continuous projected gap 内离散谱集合的距离；可靠区间进入
current-model gap 且通过预注册 absolute/gap-relative resolution 时，先得至少一个连续离散
特征值的分辨率级存在结论。唯一目标识别只在必须跟踪特定 mode 时升级。

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
- `phase3-analysis/`：误差分解、candidate 诊断、consistency/discretization correction、
  benchmark 与发表路线；其中 finite-tail/doubling 和 exact-finite-root 前置方案已标记为
  历史或条件方案。
- `phase4-report/method.tex`：经 writer 整理和 skeptic 数学审查的方法稿。
- `implementation/README.md`：当前 I1--I3 实现路线的阶段概述，逐项
  解释每个阶段全称、目的、已验证内容、未验证边界和后续依赖；长时间离开项目后应先读
  这一页。
- `implementation/open-problems.md`：按阶段维护 `BLOCKER`、`IMPORTANT CAVEAT` 和
  `MINOR CAVEAT`，记录各问题的 blocking scope、最低成本检查和状态；只有未解决的
  blocker 能停止当前工程路线。见
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]。
- `implementation/i2/`：I2.1--I2.3 已完成；I3.1 theory 已启动但实验设计尚未就绪。阶段综合与项目级状态分别见
  [[research/projects/eig-apost/implementation/i2/report|I2 stage report]]、
  [[research/projects/eig-apost/implementation/i2/README|I2 guide]]，设计/审查分别见
  [[research/projects/eig-apost/implementation/i2/design|I2.1 design]] 和
  [[research/projects/eig-apost/implementation/i2/review|I2.1 review]]，以及
  [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]] 和
  [[research/projects/eig-apost/implementation/i2/review-2-2|I2.2 review]]，以及
  [[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 design]] 和
  [[research/projects/eig-apost/implementation/i2/review-2-3|I2.3 review]]，以及
  [[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 M-axis design]] 和
  [[research/projects/eig-apost/implementation/i2/review-2-3m|I2.3 M-axis review]]。具体实验证据只从
  [[test/i2/k-count/README|I2.1 experiment index]] 与
  [[test/i2/h-inertia/README|I2.2 experiment index]]、
  [[test/i2/k-drift/README|I2.3 ntot-axis experiment index]] 与
  [[test/i2/m-drift/README|I2.3 M-axis experiment index]] 进入。
- `implementation/i3/`：维护 candidate 到 gap 内连续离散谱集合的误差估计、独立 reference
  和上界可行性的目标、输入、输出与 claim ladder；唯一目标识别是可选升级，当前不冻结具体
  算法或实验。
- `test/archive/legacy-route-v1/eig-apost-nep/`、`test/archive/legacy-route-v1/hg-map/`、
  `test/archive/legacy-route-v1/aug-bie/`、`test/archive/legacy-route-v1/root-ready/`：四个互相
  独立的 Octave 实验或受控诊断及可审计输出；历史 I3 provenance 输出在
  `test/archive/legacy-route-v1/root-ready/provenance-closure/output/`。当前交接、claim boundary 和下一门槛以
  [[research/projects/eig-apost/STATUS|project STATUS]] 为准。
