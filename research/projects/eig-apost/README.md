# Eigenvalue a posteriori error research

2026-10-28，**I10.1 D2已完成首轮条件估计，R2为PASS WITH CONDITIONS**：[[research/projects/eig-apost/implementation/i10/review-10-1a#6. R2：D2 run-02 完整结果审查|实际结果审查]]、[[research/projects/eig-apost/implementation/i10/README|入口/账目]]。最终P4 $k=1.5584378941804409$，条件 $B_4=9.8028871425\times10^{-10}$（$\mu$）；完整墙钟127.844845秒、全树采样峰2.509GB。已获得有分辨力的独立数值对照，仍未证明S/E或无条件连续误差界；BIE末位差不是精度保证。无需本轮补跑，以下保留各历史阶段。

2026-10-28，**I10.1首轮因定位合同缺陷提前终止，D2待执行**：[[research/projects/eig-apost/implementation/i10/review-10-1a|实际失败审查R1]]、[[research/projects/eig-apost/implementation/i10/design-10-1a|唯一设计D2]]。修复近边容差双解的owner选择，保持实际积分点及有向权重；质量/预测诊断不再阻断独立根。尚无新candidate或估计，保留原条件边界和预算；下一步直接争取完整条件半径，非新增认证/定位专题。账目见[[research/projects/eig-apost/implementation/i10/README|I10入口]]。以下为历史阶段记录。

2026-10-27，**I10.1正式进入方法与设计阶段**：[[research/projects/eig-apost/implementation/i10/README|I10入口及账目]]、[[research/projects/eig-apost/phase3-analysis/fem-bound/s-enrich|三模板真实材料扩充理论]]、[[research/projects/eig-apost/implementation/i10/design-10-1a|实验合同]]。固定fine二次网格，$P_2/P_3/P_4$共同扩充；完整无限质量归一化预测、独立求根验证及明示饱和性/评价假设下的三类误差半径。新建本阶段Researcher/skeptic，未运行数值或修改实验代码；不将条件估计改称无条件上界。当前阶段关系以 [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP]] 为准。

2026-10-27，**研究路线复评**见 [[research/projects/eig-apost/phase3-analysis/fem-bound/p-next#11. 研究路线复评：从维护估计器转向评价特征值|p-next §11]]：保留FEM＋DtN求解器，优先研究中心与两侧lead共同富化的有符号特征值修正；不再把继续完善I9.6包围工程当作默认进展。新方向尚非连续误差上界，首门预测层间根漂移，随后才研究余项/饱和性。旧R2结论不变；下文bulk/F/P修复是旧路线的局部下一步，当前研究优先级以上述报告为准。未新建设计、执行实验或恢复goal。

2026-10-27，[[research/projects/eig-apost/implementation/i9/review-9-6a#9. R2：D2 run-03 实际结果审查|I9.6a D2实际审查R2]]：**REVISE，上界资格尚未闭合**。D1空成功出口已补；bulk近整矩形替代的复缺陷矩误差未受控，机器上界标签须收窄。主层报告 $R_k=1.42815\times10^{-4}$，源矩包围占半径91.76%，实用目标未达且不能归因为candidate变差。正式墙钟302.5766秒、MATLAB子树采样峰值2.713GB；目标流程总成本下降未建立。最小后续为冻结场的bulk资格及F/P评价收紧，未授权执行。本轮仅更新审查/入口，未修改理论、设计、实验或运行数值计算。问题见 [[research/projects/eig-apost/implementation/i9/README#I9.6 后验估计问题账目|I9.6账目]]；以下D2“未运行”等表述保留当时历史范围。

2026-10-27续，选定 [[research/projects/eig-apost/implementation/i9/design-9-6a|I9.6a D2修复方案]]：在固定场上用参考元仿射剪裁与几何误差细带，直接评价缺陷及源缺陷矩；有限模采用显式Taylor余项，所有系数分块留存且不重复投影。完整有效上界出口与状态机已设计，实际精度和30/40分钟、3GB内的成本仍待验证。[[research/projects/eig-apost/phase3-analysis/fem-bound/r-dtn-bound|D2独审]]与 [[research/projects/eig-apost/implementation/i9/README#I9.6 后验估计问题账目|问题账目]]分别维护；旧review不改写。

2026-10-27，[[research/projects/eig-apost/implementation/i9/review-9-6a|I9.6a实际结果审查R1]]：**REVISE，上界交付未完成**。保留两层普通诊断，主层 $R_\mu=3.63384\times10^{-5}$、$R_k=1.16586\times10^{-5}$。可靠成功路径未实现；源矩、范数误差及真实材料薄带的矩形归属仍须处理，不能把平台认定为纯原生FEM缺陷。203.65秒是普通路径成本；可靠方法成本仍未知。复用两位代理并完成正文独审，本轮没有改设计/理论/实验文件或运行实验。以下是理论交接历史。

2026-10-26，I9.6已形成 [[research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound|FEM＋DtN正定源重构谱距离理论]]、[[research/projects/eig-apost/phase3-analysis/fem-bound/r-dtn-bound|独立审查]]及 [[research/projects/eig-apost/implementation/i9/design-9-6a|待执行设计]]。目标为原无限连续算子，不使用BIE或谱隔离；常系数重构把原生场转成强定义域试探场，并以有限Q1/Fourier/Yukawa/Q2评价其已抵消缺陷。小量机制与有限常数已给出，当前candidate的实际分辨能力和可靠积分总成本仍未建立；两层计算须同时交付 $R_\mu,R_k$ 与成本，不能用过宽上界宣布精度目标完成。本轮仅理论与设计，没有实验或代码修改。问题集中于 [[research/projects/eig-apost/implementation/i9/README#I9.6 后验估计问题账目|I9.6账目]]。

以下为I9.5b及更早阶段记录。

2026-10-26，[[research/projects/eig-apost/implementation/i9/review-9-5b|I9.5b FEM＋DtN实际结果审查]]：**PASS WITH CONDITIONS**。D2 run-02交付 $k=1.558438079544167$，BIE参考差 $1.85362\times10^{-7}$，较E.2缩小约10.97倍；完整墙钟30.318秒、采样峰值1.582GB。粗网一次局部翻边成功，正式粗细及Q10/Q12链通过；Q零差只表示求根停止尺度内一致。无主结果blocker，但曲线偏差/QZ原始块未交齐，另有未保留探针；不宣称真误差、完整研发成本或同精度提速。设计保持D2，本轮只审查、不重跑或改代码。问题见[[research/projects/eig-apost/implementation/i9/README#FEM＋DtN 问题账目|I9 FEM＋DtN账目]]。

以下为E.2及更早阶段记录。

2026-10-26，[[research/projects/eig-apost/implementation/i9/review-9-5a|E.2 实际结果审查]]：**PASS WITH CONDITIONS，仅限普通算术完整数值链**。
新candidate $k_h=1.558439927483915$；新场主 $R$ 为Q10 $0.004627470466476482$、Q8 $0.004625864372333271$，对旧最佳同阶下降约69.47%。
受监控完整科学链515.14695675秒、采样峰值1,759,723,520字节；同合同成本下降未建立。真材料积分、薄片元、H+及BIE参考条件仍须披露。
用户已清除goal，本轮没有建立或恢复goal；只读审查源码/已有结果并维护研究文档，未重跑实验，不自动进入下一轮。
完整设计仍见 [[research/projects/eig-apost/implementation/i9/design-9-5a#6. 当前设计 E.2：联合细化后的完整谱距离交付|design §6]]；问题统一维护于 [[research/projects/eig-apost/implementation/i9/README#FEM 原生场理论问题账目|I9账目]]。旧审查保持各自范围。

2026-10-23 理论专题 v2：[[research/projects/eig-apost/phase3-analysis/fem-bound/p-scope|FEM 原生场范围与新版验收]]、
[[research/projects/eig-apost/phase3-analysis/fem-bound/theory|无限域谱距离、非零通量与精度评价]]、
[[research/projects/eig-apost/phase3-analysis/fem-bound/r-theory|独立审查]]。
对象为 I9.3 有限多胞元曲边 $P_2$ 原生场的零延拓，目标是原连续算子的全谱距离；
不需要预知模态数。旧零通量后备的必然大量级已排除其作为精度方案；v2 要求具体有限维
通量及小量机制，旧 PASS 不覆盖新版。本轮只做理论，没有新数值结果，也不提升到 `mainline/`。
当前问题集中于 [[research/projects/eig-apost/implementation/i9/README#FEM 原生场理论问题账目|I9 FEM 理论账目]]。
以下原阶段简介和各历史结论保持其原有范围，当前状态见 `STATUS.md`。

本专题用于把仓库中的周期波导特征值计算，转向偏工程实现的特征值后验误差分析与
数值认证研究。当前按 Academic Research Suite 的 Deep Research 工作流推进，已经
形成受条件约束的方法稿、完成三个离散实现 checkpoint，并在历史受控诊断之后完成
source-derived proxy provenance closure。I3.1 已形成 ordinary-double continuous-residual
estimator candidate；I3.2 的条件性离散证书谱包含定理已建立，但 same-trial `ecap-a2` 在完成
evaluation 后因资源硬门停止，未形成 empirical cap、$q$ 或 interval。严格 cap 的实例化假设
仍未闭合。本专题尚未形成 certified estimator，也不是新的 `research/mainline/`。

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
  minimizer/root 零漂移或收敛。2026-08-24 起，I3.1 状态为
  `PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`；新 I3.2 包含已经建立的
  条件性证书定理和 same-trial empirical-cap application，后者当前为
  `RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED`；原 I3.3 已迁移至未来 I4.1，
  只登记使用独立方法/reference 对经验 estimator 进行 effectivity validation；原 I3.4 已迁移
  至未来 I4.2，继续负责 reliable enclosure/gap/existence。I4.1、I4.2 当前均未启动。
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
    fem-bound/
      p-scope.md
      theory.md
      r-theory.md
      s-dtn-bound.md
      r-dtn-bound.md
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

- `phase3-analysis/fem-bound/`：当前有限截断 FEM 原生场到原无限算子谱距离的理论专题；
  包含弱残差、曲边 RT2 通量、人工端贡献、真实材料积分与有限可核验的小量机制。
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
- `implementation/i2/`：I2.1--I2.3 已完成；I3.1 当前已有全边界 BIE
  `NUMERICALLY_UNQUALIFIED` indicator candidate，阶段为
  `PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`；reliable enclosure 未闭合。
  阶段综合与项目级状态分别见
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
- `implementation/i3/`：维护 candidate 到连续谱的 residual indicator、条件性证书定理与
  same-trial empirical cap。I3.1 当前证据由
  [[research/projects/eig-apost/implementation/i3/review-3-1f|full-boundary BIE review]] 进入；
  I3.2 定理与独立审查分别见
  [[research/projects/eig-apost/implementation/i3/design-3-2a|design-3-2a]] 和
  [[research/projects/eig-apost/implementation/i3/review-3-2a|review-3-2a]]；same-trial cap 设计与
  资源负结果见 [[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]] 和
  [[research/projects/eig-apost/implementation/i3/review-3-2b|review-3-2b]]。I3 milestone 表保留
  原 I3.3、I3.4 条目，并标记已分别迁移至 I4.1、I4.2。
- `implementation/i4/`：未来阶段入口；I4.1 只做独立 method/reference effectivity，I4.2 只做
  reliable enclosure/gap/upper-bound research。两项当前均未启动；不得把 ordinary evaluation
  或名义区间称为可靠 enclosure。
- `test/archive/legacy-route-v1/eig-apost-nep/`、`test/archive/legacy-route-v1/hg-map/`、
  `test/archive/legacy-route-v1/aug-bie/`、`test/archive/legacy-route-v1/root-ready/`：四个互相
  独立的 Octave 实验或受控诊断及可审计输出；历史 I3 provenance 输出在
  `test/archive/legacy-route-v1/root-ready/provenance-closure/output/`。当前交接、claim boundary 和下一门槛以
  [[research/projects/eig-apost/STATUS|project STATUS]] 为准。
