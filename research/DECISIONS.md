# Research decisions

这里只记录能由现有文件支持的研究决定。`Revisitable` 表示将来可在新证明或新证据下重新审议。

## 2026-08-11 阶段：eig-apost 恢复 continuous DtN/BIE 主层级并暂停 I4 数值

- **决定：** 精确 half-guide DtN 只由半无限边值问题定义；physical center variational
  pencil $\mathcal F(k)$ 在 BIE representation、Fourier truncation、ordered QZ、doubling
  和矩阵之前定义真实 guided eigenvalue。continuous BIE 只作待证明的等价 realization，
  ordered QZ 只作 discrete deflating-subspace 计算。
- **旧路线：** “有限多个 cells + 远端闭合 + doubling”的完整方法归档为
  `research/projects/eig-apost/phase4-report/legacy-tail.tex`。它以后只作 same-cell
  cross-check、reference sequence 或 tail diagnostic，不定义主问题或主 estimator。
- **误差路线：** 不再要求 finite-rank Fourier lift 在完整
  $H^{1/2}\to H^{-1/2}$ operator norm 下逼近一阶非紧 DtN。当前候选是 projected
  consistency + eigentrace regularity、principal-part subtraction + compact remainder，
  或 regular Galerkin/graph convergence。相邻层差默认只称 next-level correction。
- **行动边界：** I4 数值工作暂停；OP-M0-1--OP-M0-4 关闭前不得组装
  $A_{\mathrm{def}}$，不得运行 DtN wall、locator、complex disk 或 root isolation。
- **证据：** `research/projects/eig-apost/phase4-report/method.tex`；项目 `STATUS.md`、
  implementation `README.md` 和 `open-problems.md`；Researcher/Skeptic 方法审查。
- **状态：** Active method reconstruction；Phase 1--2 历史文件保持原文。

## 2026-07-13 阶段：DtN 只作为独立可行性路线

- **决定：** 直接半波导 DtN 暂不替换当前主线的出射 Cauchy 关系。若恢复原型工作，优先采用保留中心未知量 $(\eta,\xi)$、只替换端口行的 Scheme A；局部胞元 Riccati/QZ 是主要研究路线，scattering-to-DtN 只作诊断。
- **理由：** 严格无耗散情形存在单位圆传播分支，Dirichlet 投影也可能奇异或病态；关系表述更稳健。
- **证据：** `research/projects/half-guide-dtn/STATUS.md`，`research/projects/half-guide-dtn/DECISIONS.md`。
- **影响：** 该专题未整合进后来冻结的 Müller--Cauchy 主线；后续需先完成周期障碍半导和完整耦合。
- **状态：** Revisitable；当前为 paused。

## 2026-07-14 阶段：修正单胞表示命题

- **决定：** 不再把原始“齐次背景场加公共密度层势且无条件唯一”的表述当作定理。区分总是可用的直接 Green 表示与需要互补交换波数问题可解性的公共密度 Müller 表示，并显式保留表示零空间或商空间。
- **理由：** 原表述遗漏 Wood 阈值、广义阈值解和互补问题的谱条件；密度唯一性不等于物理场唯一性。
- **证据：** `research/projects/cell-representation/proof-log.md`，`research/projects/cell-representation/README.md`，`research/projects/cell-representation/open-questions.md`。
- **影响：** 修正的波数配对、表示例外集合、$N_c$ 和商空间结构已写入主线第 4 节及附录 B；其完整严格性仍为 `needs review`。
- **状态：** 当前 formulation 决定已采用；具体假设可重审。

## 2026-07-20 阶段：收窄创新性主张

- **决定：** 不把有界域约化、DtN、普通 Müller BIE、Bloch pencil、奇异值扫描或通用轮廓算法单独宣称为创新。当前候选贡献聚焦于高阶 Müller 中心表示、广义稳定 Bloch Cauchy 关系、无伪根核定理与认证离散的精确交叉。
- **理由：** 创新性审计发现多数单独组件已有直接先例；尚未检索到完全重合工作也不构成优先权证明。
- **证据：** `research/projects/novelty-audit/README.md`，`research/projects/novelty-audit/r-claims.md`，`research/projects/novelty-audit/progress.md`。
- **影响：** 主线应把已知组件标为 background/adaptation，把新颖性押在可严格证明的耦合结果上。
- **状态：** Revisitable，需随新文献更新。

## 2026-07-21 阶段：关系优先、广义模态、商空间默认

- **决定：** 半波导外部对象以闭 Cauchy 关系为主，DtN 仅是正则图坐标；模态必须包含广义 Floquet 模态与 Jordan 链；第一主定理默认采用 $\ker A/N_{\mathrm{rep}}$ 与导模空间的同构，不取商版本必须另证 $N_{\mathrm{rep}}=\{0\}$。
- **理由：** 这同时处理 DtN 图失效、普通特征向量不完备和表示密度零空间三类风险。
- **证据：** `research/planning/muller-cauchy/README.md`，`research/planning/muller-cauchy/scope.md`，`research/planning/muller-cauchy/p-theorems.md`。
- **影响：** 已整合到主线第 3--5 节。
- **状态：** 冻结主线采用的 formulation；若恢复该路线并获得更强唯一性定理，可以显式强化，但不应静默改写归档。

## 2026-07-21 阶段：Fredholm 仅作条件性强化

- **决定：** 不从“第二类结构”直接推出完整耦合算子 Fredholm 指标为零。先完成固定参数的商核--导模等价；Fredholm 只在找到自然方形实现和“可逆参考算子加紧扰动”分解后推进。
- **理由：** 关系行可能是矩形，端口块的紧性与商空间对指标的影响尚未解决。
- **证据：** `research/planning/muller-cauchy/p-proofs.md` 中 L15/T2，`research/planning/muller-cauchy/p-risks.md`，主线第 5 节 `conj:Fredholm`。
- **影响：** Fredholm 结论保持 conjectural，不是当前主定理的前提。
- **状态：** Revisitable。

## 冻结主线遗留事项：范围差异需重新确认

- **事项：** 路线图冻结的首个证明包排除了不同左右周期端，而冻结主线第 2 节和附录 A 已显式处理两种不同周期端。
- **证据：** `research/planning/muller-cauchy/scope.md`；`research/archive/muller-cauchy-2026-07/en/s-setting.tex`；`research/archive/muller-cauchy-2026-07/en/a-essspec.tex`。
- **处理：** 若恢复该路线，应审计第 3--5 节的模态与耦合假设是否也完整支持非对称端，再决定是否把路线图范围正式扩展。
- **状态：** `needs review`，不是已补写的历史决定。

## 2026-07-24 协作政策：进入草稿必须人工审核

- **决定：** `projects/` 的结论不得自动提升到 `mainline/`，`mainline/` 也不得自动提升到 `draft/`。
- **理由：** 专题完成、主线存在陈述和论文可发表性是三个不同层级。
- **影响：** 每次晋升都需明确人工审核，并同步 `research/STATUS.md`、本文件和必要的主线审计记录。
- **状态：** 当前协作规则。

## 2026-07-26 阶段：冻结 Müller--Cauchy 主线并暂不指定新方向

- **决定：** 暂停 Müller--Cauchy 统一理论路线，把原 `research/mainline/` 移至
  `research/archive/muller-cauchy-2026-07/`，并以 Git 标签
  `mainline-muller-cauchy-2026-07-26` 固定移动前的精确状态。新的研究方向尚未确定，
  因此暂不建立新分支，也不建立空的 `research/mainline/`。
- **理由：** Git 标签解决版本可恢复性，顶层归档目录解决文件结构中的权威歧义；
  在方向未明确时提前命名分支或主线会制造虚假的研究承诺。
- **证据：** 标签 `mainline-muller-cauchy-2026-07-26`；
  `research/archive/muller-cauchy-2026-07/README.md`；`research/STATUS.md`。
- **影响：** 当前 `research/` 没有统一数学主线。归档及其符号索引只在任务明确指定
  时生效；零散方向讨论进入 `planning/`，形成多轮专题后进入 `projects/`，经人工
  审核后才可重新建立 `mainline/`。
- **状态：** Revisitable；新方向形成或旧路线恢复时必须新增决定记录。

## 2026-07-26 阶段：启动特征值后验误差范围界定

- **决定：** 在 `research/projects/eig-apost/` 启动 Deep Research `socratic`
  范围界定，调查偏工程实现的特征值后验误差方向；当前只建立 Phase 1 材料清单、
  研究边界和用户问题，不建立新 `mainline/`。
- **理由：** 仓库已有 transmission eigenvalue、line-defect guided mode 和 cell Bloch
  multiplier 三类数值对象，现有 residual、$\sigma_{\min}$ 和分辨率收敛记录不能在未选定
  误差对象与参考真值前合并成一个后验误差命题。
- **证据：** 用户本次研究方向要求；`research/projects/eig-apost/p-scope.md`；
  `research/projects/eig-apost/phase1-scope/materials.md`。
- **影响：** 冻结主线、现有 MATLAB 文件和旧草稿保持不变；既有理论命题和数值候选
  均不作为新专题的已知真理。
- **状态：** Active scoping；研究问题确认后再决定是否进入 Phase 2，不代表已选定
  新统一方向。

## 2026-07-26 阶段：确认后验误差 RQ 与 DtN-first 调查顺序

- **决定：** 研究问题限定为 Fliss (2013) $\beta$-formulation 中 fixed-$\beta$
  line-defect guided-mode eigenvalue 的 BIE 后验误差估计；目标是预测
  $|k_h-k_*|$ 的量级。RQ 不预设无穷远条件采用 DtN 或 trace-subspace。
- **方法顺序：** Phase 1--2 先调查 DtN+BIE estimator 的理论与初步可行性；如果可行，
  再考虑向已有 trace-subspace 实现扩展。该顺序是可修订的调查承诺，不是理论结论。
- **参考真值：** 优先要求两个或更多独立高精度方法对 $k_*$ 的有效数字一致；若不可得，
  至少使用一篇经核验的可靠文献所报告的参考数据。
- **范围：** 首阶段只考虑非 Wood、lead multipliers 与单位圆分离、孤立简单点谱；
  不以定性 indicator 或宽泛 certified upper bound 为目标。
- **证据：** 用户的两轮 Socratic 范围确认；
  `research/projects/eig-apost/phase1-scope/rq-summary.md`。
- **状态：** Active Methodology Reflection；尚未通过文献核验或数值可行性门。

## 2026-07-26 阶段：half-guide DtN 定义与 BIE 切入点

- **决定：** 在本专题中先按 Fliss 的半波导边值问题独立定义 DtN；不从现有
  trace-subspace 反向命名 DtN。传播/Riccati、recursive doubling 和稳定模态只作为
  计算构造或交叉验证。
- **BIE 切入点：** 第一候选是由 BIE 生成 unit-cell DtN/RtR map，再用 Riccati 或
  doubling 得到半波导 map；不预设现有 `A_QP` 无需新增 port representation 即可完成。
- **依据：** Fliss (2013) PDF pp. 11, 13, 18--20；Joly--Li--Fliss (2006) PDF
  pp. 8--10, 19；Coatléven (2012) PDF pp. 8--10, 19；Yuan--Lu--Antoine (2008)；
  Petropoulos--Turc (2025)。详见 `research/projects/eig-apost/phase2-sources/`。
- **限制：** 现有证据只建立定义和构造可行性；未建立目标穿透介质 cell map、
  half-guide map 的离散误差传播或 guided eigenvalue estimator。
- **状态：** Active investigation；Phase 3 前仍需 nonlinear eigenvalue perturbation
  文献核验。

## 2026-07-26 阶段：首版 estimator 以 simple-root projected correction 为核心

- **决定：** 首版不把 $\sigma_{\min}$ 或两个 DtN 层级的直接差值单独称为 eigenvalue
  error estimator。核心候选采用左右零向量投影的 nonlinear simple-root correction，
  分母显式包含 `k` 导数；两级 correction 首先解释为相邻层级根位移。
- **强度目标：** 论文最低目标是 asymptotically quantitative estimator，并在独立
  reference truth 上报告 effectivity；不以只有排序功能的 indicator 为终点，也暂不
  强求可能很宽的 certified upper bound。
- **限制：** 只有在三层 refinement 支持 saturation/geometric-tail model 后，才能把
  相邻层级 correction 转换为到精确 DtN 的剩余误差估计。当前尚未选择具体 DtN
  hierarchy，也未验证 BIE--DtN operator hypotheses。
- **证据：** Güttel--Tisseur (2017)、Moskow (2015)、Bindel--Hood (2013)、Zhang
  (2023) 的原文核验；`research/projects/eig-apost/phase2-sources/r-nep-error.md`。
- **状态：** Revisitable research design；不是已证明定理。

## 2026-07-26 阶段：以 finite-tail doubling 隔离首个 DtN 误差源

- **决定：** 首版固定 single-cell BIE、Rayleigh port space 和其他离散，只令 finite
  periodic tail 的 cell count $N=2^j$ 增长。由 finite-segment scattering map 施加
  structure-preserving terminal closure，再经 Cayley transform 得到 $\Lambda_j$，把
  $j$ 作为唯一主 refinement parameter。
- **代码接口：** 复用 `bloch.construct_S` 和 `A_QP` 生成 single-cell scattering
  blocks；首版 infinity treatment 不调用 `bloch.solve_modes` 或 outgoing
  trace-subspace selection。
- **理由：** 这直接对应用户优先研究的非周期方向无穷远截断；Ehrhardt--Sun--Zheng
  (2009) 为 stop-band finite-tail StS/doubling limit 提供原文先例，当前范围又明确远离
  unit-circle multipliers。
- **验证限制：** doubling 与 QZ/Riccati 共享 cell map，只能交叉验证 infinity
  treatment；整个 $k_*$ 仍需独立 FEM/supercell 或明确降级的 reference status。
- **证据：** `research/projects/eig-apost/phase2-sources/r-bie-dtn.md`；
  `research/projects/eig-apost/phase3-analysis/s-dtn-chain.md`。
- **状态：** Active analysis choice；经 code-convention audit 后才可实施。

## 2026-07-26 阶段：实根层级采用结构保持闭合并增加 root qualification

- **决定：** 用于实 $k$ eigenvalue estimator 的 finite-tail sequence 首先采用远端
  homogeneous Dirichlet，另以冻结的 real Robin condition 交叉检查。远端
  zero-incoming scattering sequence 只用于 half-guide map limit；除非另行求复根，
  不把它的实轴最小奇异值极小点当作有限层特征值。
- **理由：** zero-incoming finite segment 一般仍向人工外部介质泄漏，其 nonlinear
  root 可能离开实轴；此时沿实轴扫描只得到 singular-value minimum，simple-root
  correction 的前提不成立。
- **estimator 影响：** coarse scan 仅定位候选，局部 nonlinear solve 必须确认
  $F_j(k_j)$ 的实际简单零点。对于 $N_{j+1}=2N_j$ 的层级，primary candidate 改为
  $\eta_j=|\delta_j|$；只有 next-root prediction 与 doubling separation gates 都通过，
  才解释为到精确 root 的 remaining-error estimator。
- **证据：** scattering port 代数审计；
  `research/projects/eig-apost/phase3-analysis/s-root.md`；
  `research/projects/eig-apost/phase3-analysis/s-estimator.md`。
- **状态：** Active analysis choice；尚未证明 map convergence 或 effectivity。

## 2026-07-26 阶段：Phase 2b novelty gate 有条件通过

- **决定：** fixed-$\beta$ line-defect guided-mode eigenvalue 的 BIE--DtN 后验误差
  选题以 `PASS WITH CONDITIONS` 通过 search-bounded novelty gate。允许继续低成本
  Phase 3 理论与验证设计，但不建立新 `research/mainline/`，不进入 MATLAB prototype，
  也不冻结 priority claim。
- **已知重合：** fixed-$\beta$ DtN/RtR 导模 formulation、BIE cell boundary map、
  Riccati/doubling、开放导模域截断先验界、一般 photonic/fiber eigenvalue estimator、
  DtN-truncated NEP convergence 和周期散射 DtN posterior term 均已有先例。C1--C3
  只能作为背景或适配。
- **候选核心：** 只保留 numerical half-guide DtN error 到 guided eigenvalue shift 的
  computable estimator，以及 simple-root projected correction 的量级有效性或
  effectivity，即 C4--C5 在 C1 精确对象上的交叉。
- **条件：** 补齐 Bonnet-Ben Dhia--Gmati (1995)、Djellouli et al. (2000) 与 Leclerc
  et al. (2026) 全文；投稿前更新 forward citations；先完成 root qualification、
  independent-reference ladder 与 BIE boundary saturation 检查。共享同一 BIE cell
  map 的 doubling/QZ/Riccati 一致性不视为独立真值。
- **条件更新（2026-07-27）：** Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al.
  (2000) 已完成全文核验；两者强化了“一般 boundary-truncation eigenvalue estimate
  已有先例”的判断，但未覆盖 computable posterior half-guide DtN $k$-shift estimator
  或 simple-root effectivity。当前只剩 Leclerc et al. (2026) 全文受 HAL embargo。
- **证据：** `research/projects/eig-apost/phase2b-novelty/r-gate.md`；
  `research/projects/eig-apost/phase2b-novelty/claim-matrix.md`；
  `research/projects/eig-apost/phase2b-novelty/r-sources.md`。
- **状态：** Revisitable；若补充全文覆盖 C1--C5，或候选量不能超越 convergence
  indicator，应改为 `REVISE` 或 `STOP`。

## 2026-08-07 协作政策：Skeptic 按工程目标分级并集中维护 open problems

- **决定：** `eig-apost` 当前以得到可运行、可复现、在真实案例上可检验的 empirical
  estimator 和偏工程论文为目标。Skeptic 必须把问题分为 `BLOCKER`、
  `IMPORTANT CAVEAT`、`MINOR CAVEAT`；只有未解决的 blocker 可以停止阶段。
- **审查深度：** 不因问题具有数学趣味就展开旁支。只有当问题会改变当前验收门、使
  结果不可解释或阻止下一项必要计算时才继续调查；能用廉价 numerical sanity check
  充分约束时，优先做该检查而不是开启理论研究。
- **记录方式：** 每个 stage review 末尾只保留 handoff 链接，未解决事项集中写入
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]，并记录
  category、blocking scope、cheapest next check 和 status，避免 review 之间重复清单漂移。
- **影响：** continuous proof、certification 和广泛参数稳健性仍可作为 caveat 或未来
  工作；除非当前 claim 明确依赖，它们不再自动阻止工程 estimator pipeline。
- **证据：** 用户对论文定位和 Skeptic 行为的明确修订；`research/AGENTS.md`；
  `.codex/agents/skeptic.toml`。
- **状态：** 当前协作规则；若未来目标改为 theorem-level 或 certified paper，应重新
  校准 blocker 定义。

## 2026-08-08 阶段：I4 改用相同周期端与 Fliss 缺列模型

- **决定：** I4 不再以左右 half-guide 介质柱形状不同的双椭圆配置作为主真实案例，
  改为左右完全相同的二维完美周期介质，并把中心一整列替换为背景介质。主正对照采用
  Fliss (2013) 的 period-one 光滑 Gaussian 系数和 missing-column geometry；只在
  `test/i4-fliss-2013/` 实现新的实验代码。
- **模型分层：** Fliss 光滑 profile 由独立的稀疏离散 Track A 复现。现有 BIE 只能处理
  分片常数界面，因此半径 $0.2$、折射率 $\sqrt{17}$ 的圆柱只作为单独标记的 Track B
  sharp-disk surrogate；不得把 Track B 的结果称为 Fliss 复现或用于论文值的误差门。
- **谱域：** 固定 $\beta$ 后，projected gap 由完美周期背景的离散 Floquet--Bloch bands
  计算；所有数值结果写成 $\sigma_{\mathrm{ess}}^h(\beta)$，并通过空间、Bloch 网格和
  局部带边加密给出经验 edge uncertainty。Fliss 对称胞元使 classical half-guide DtN
  的额外 Dirichlet 例外点不作为该正对照的主障碍。
- **I4 边界：** 本轮先寻找可信 projected gap 和 center-localized 特征值候选，再决定是否
  启动 complex-$k$ analytic chart 与 root isolation。实轴 $\sigma_{\min}$ dip 仍只是
  locator；未通过 contour/root qualification 前不得称为特征值或 estimator。
- **证据：** 用户明确更改当前实验模型；Fliss (2013) Sections 3--5；
  `research/projects/eig-apost/phase4-report/output/pdf/method.pdf`；
  [[research/projects/eig-apost/implementation/open-problems#I4|I4 ledger]]。
- **状态：** Active replacement benchmark；旧双椭圆 I4 结果保留为历史负例，不再决定
  新主模型是否存在候选。

## 2026-08-08 阶段：Fliss FD 候选通过，BIE 停在投影子空间门

- **决定：** 接受 exact smooth-profile Track A 的
  `TRACK_A_PROJECTED_GAP_CONFIRMED / I4_FD_CANDIDATE_READY`，但不把该候选升级为
  qualified root。sharp-disk Track B 因双向 pencil residual 与 reciprocal pairing 失败，
  冻结为 `BIE_PROJECTIVE_SUBSPACE_BLOCKED`；不运行已实现的 legacy M4/M5 实轴 scan。
- **理由：** N80/N120 targeted edge check 给出
  $\varepsilon_{80,120}=7.91\times10^{-4}<10^{-3}$、safe gap
  $(1.981350,5.386819)$ 和 candidate margin $1.479625$，与 N80 strip 的
  $\lambda_h=3.460975044$、极小 tail drift 和中心局域性共同构成可信 FD 候选。另一方面，
  BIE M5 虽恢复满秩且条件良好的两侧 traces，forward/reverse residual 仍为
  $3.15\times10^{-6}/9.43\times10^{-4}$，pairing defect 为 $1.58\times10^{-5}$，不能用
  trace normalization 或调宽阈值消除。
- **下一步：** test-local 实现带 Rayleigh 物理尺度平衡的 projective ordered-QZ 或等价
  deflating-subspace port bases，先通过单点与相邻 $k,M$ 的 subspace gates，再恢复实轴
  locator。若最终案例坚持 exact Fliss Gaussian，另需 model-consistent infinite-domain
  evaluator；不得把 sharp-disk root 迁移为 Gaussian root。
- **状态：** Track A partial success；Track B blocker open；`PHYSICAL_ROOT_READY=STOP`。
