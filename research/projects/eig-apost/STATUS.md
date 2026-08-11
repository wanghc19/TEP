# Eigenvalue a posteriori error status

更新日期：2026-08-11。

## 当前状态

- **2026-08-11 新路线 I1 discrete-design update：** I1 数值工作仍暂停。本轮没有组装
  $A_{\mathrm{def}}$，也没有运行 locator、DtN wall experiment、complex disk 或 root
  isolation。当前 empty-center 的离散设计已由两项独立 Skeptic 审查到
  design-level `BLOCKER = 0`，verdict 为 `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS`。下一里程碑
  只授权在新 `test/` 目录实现 static algebraic assembly oracle；production DtN、
  $A_{\mathrm{def}}'$、任何 $k$ scan 和 root 工作仍不获授权。
- 当前连续主路线为
  `exact half-guide PDE -> continuous DtN -> continuous center BIE--DtN operator
  \(\mathcal F(k)\) -> BIE/Fourier one-cell pencil -> ordered-QZ stable graph ->
  discrete DtN/augmented graph -> matrix representation`。真实 guided eigenvalue 由
  $\ker\mathcal F(k)\ne\{0\}$ 定义；QZ 只计算离散 stable deflating subspace。
- 旧的“有限多个 cells + 远端闭合 + doubling”方法完整归档为
  [[research/projects/eig-apost/phase4-report/legacy-tail.tex|superseded finite-tail formulation]]，
  以后只作 cross-check、reference sequence 或 tail diagnostic，不定义主问题或主 estimator。
- 现行理论稿为
  [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]；
  该稿现已加入 original/reversed 双 QZ pass、projective infinite-pair policy、双向
  Sylvester separation、absolute chart-margin gates，以及当前 empty-center 的
  $2K\times2K$ safe-DtN 和 $4K\times4K$ full-graph 公式。设计与审查见
  [[research/projects/eig-apost/implementation/i1/design|I1 discrete design]] 和
  [[research/projects/eig-apost/implementation/i1/review|I1 design review]]。
  two-level projected difference 在没有独立 saturation/remainder 前只称
  next-level correction，不称 remaining-error estimator。
- 本次权威变化记录于
  [[research/projects/eig-apost/DECISIONS|2026-08-11 decision record]]；Phase 1--2 历史
  文件保持原文。
- 工作流：Academic Research Suite / Deep Research，现处于受审查的理论方法重构阶段。
- 论文定位：以可运行、可复现、具有代表性真实案例的 empirical estimator 为当前目标；
  theorem-level certification 是更强的未来方向，不作为默认阶段门。
- 阶段：Phase 1--3 已完成范围、来源、novelty 和历史理论方案；旧 Phase 4 finite-tail
  方法稿已 supersede，当前 Phase 4 为连续 DtN/BIE 方法重构。此前已完成三个
  Octave implementation checkpoints：manufactured NEP、Half-guide map 和
  Augmented BIE / center coupling。Root-readiness 的第一轮 early-stop diagnostic
  保留为历史负结果，后续 source-derived proxy provenance-closure 已完成并通过独立审查。
  I4 首轮双椭圆 full analytic complex-$k$ baseline/repeat 在 locator 处得到可复现的
  `NO_SCREENED_DIP`，现保留为历史负例。当前主模型已改为相同周期端与 Fliss
  missing-column geometry；新的 exact-profile FD track 找到可信 projected-gap 候选，
  sharp-disk BIE track 已完成 21 点 Rayleigh-budget screening：旧 transmission-rank/
  affine blocker 被 projective ordered-QZ/doubling core 取代。最新三路径诊断先用真 Ewald
  real/reciprocal decomposition 复现 Linton Tables 2--5 的五个函数值，再对同一冻结圆周
  密度比较 Ewald full kernel、package MFS 和 Rayleigh extractor。Ewald--Rayleigh 的
  single-layer Dirichlet 系数在当前正间距、实数非 Wood 参数上闭合到
  $6.10\times10^{-16}$。新的 MATLAB derivative qualification 继续使用根目录
  `Faddeeva_erfc.mexmaca64`，Linton 五点最大误差为 $5.07\times10^{-11}$；解析 Ewald
  gradient/Hessian 通过 value-only Richardson、Rayleigh derivative、Helmholtz、mixed
  derivative、source/target sign 及 Ewald 单轴加密。package `lsqminnorm` 的五个项目函数值
  最大误差降到 $5.14\times10^{-10}$，但负横向分离 hold-out 的三个 Hessian 分量仍为
  $1.46\times10^{-8}$--$1.60\times10^{-8}$。将过强的全六分量门修正为
  action-specific dependencies 后，历史 $p/d=0.7$ run 的 full SLP--D 通过，而 SLP--N
  出现 $10^{-8}$ 级 proxy self failure。Researcher 随后识别出该 source curve 越过最近
  周期镜像奇点；新 `test/i4-proxy-rule/` 只预注册 $p/d=0.2$，固定 MATLAB
  `lsqminnorm`、原科学门与四个单轴 refinement。最终 canonical 中 SLP--N 的
  E--P/P--R 最大误差为 $3.42\times10^{-14}$/$3.47\times10^{-14}$，四轴 self 最大为
  $1.61\times10^{-13}$；共同配置下 SLP--D 也通过。因此 OP-I4-1f 已关闭。随后新的
  `test/i4-dlp-trace/` 严格按 DLP--D、DLP--N、$M_{\mathrm{trace}}$ 顺序运行：DLP--D 与
  DLP--N 的三路径最大 coefficient 误差分别为 $1.39\times10^{-14}$ 与
  $1.19\times10^{-13}$，四轴 wall self 最坏为 $1.40\times10^{-13}$；独立半网格重构
  将 $M_{\mathrm{trace}}=48$ 的最坏误差和 omitted energy 分别压到
  $7.08\times10^{-12}$ 与 $5.00\times10^{-13}$。OP-I4-1h 与 OP-I4-6 因而在当前制造
  密度、实数非 Wood 参数和有限 $M_{\mathrm{ref}}=96$ 意义下关闭。
- 状态：`active investigation -- I1 discrete design passed; numerical work remains paused`。
- 历史阶段门（均不构成当前实现授权）：manufactured root/correction pipeline 曾为窄范围
  `GO`，finite-tail Half-guide map 曾为 Stage 1 `GO`，Augmented BIE 曾为
  `STAGE2_DISCRETE_ALGEBRA_GO`；provenance-closure 曾为
  `PASS WITH CONDITIONS`，其 operational label 为
  `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`。历史 I4 numerical verdict 为
  `PARTIAL SUCCESS -- I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / EWALD_DERIVATIVE_REFERENCE_CERTIFIED /
  SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 / DLP_D_N_MTRACE48_CERTIFIED`；这些标签现只作为
  已完成的离散数值证据保留，不构成继续实现的授权。OP-I4-1e 中旧矩阵的授权已被方法重构
  决定撤销并由新路线 I1 设计取代；$A_{\mathrm{def}}$、scanner、real-axis locator 与 I2 root isolation 均不获授权，
  `PHYSICAL_ROOT_READY=STOP`。新的 $A_{\mathrm{def}}^{D/G}$ 只完成理论设计，尚无实际
  assembly matrix、qualified production half-guide graph 或 derivative。现有证据支持一个可信的
  exact-profile finite-strip eigenvalue candidate，但不支持 qualified BIE root、
  连续 kernel--field equivalence、unconditional effectivity 或 certified interval。

## 实现 checkpoint

| Checkpoint | 结果 | 已验证 | 明确未验证 |
|---|---|---|---|
| Manufactured NEP | `GO`; `conditional/empirical` | 固定维数 contour count、bordered Newton、root qualification、projected correction 和四个负例；末级 tail effectivity 为 `0.999987793` | BIE/DtN、branch cut、pole、representation kernel、common discretization error |
| Legacy finite-tail Half-guide map | Stage 1 historical `GO` | 非交换 Redheffer/terminal/Cayley 次序、exact analytic cell、固定 $k=0.10$ 的中心圆形介质夹杂单胞（旧报告称 `EDC cell`）same-cell QZ/doubling smoke 和负例传播；Case B 最终误差 $1.93\times10^{-15}$ | 只作 discrete infinity-treatment cross-check；不定义连续 DtN，缺独立 PDE truth、operator convergence 与 $C^1$ error control |
| Augmented BIE | `STAGE2_DISCRETE_ALGEBRA_GO`; `ROOT_READY=STOP` | 固定九块 $(n+8p)$ assembly、scaled density coordinate、raw/reduced Schur agreement、七级 availability 与 failure ledger；unchanged-source 复现差为 $0$ | 连续表示单射性、kernel--field equivalence、pole-free analytic neighborhood、root/eigenvalue/estimator |
| Root-readiness proxy diagnostic and provenance closure | `PASS WITH CONDITIONS`; historical `GO` to full analytic complex-$k$ Root-readiness, revoked 2026-08-11; `PHYSICAL_ROOT_READY=STOP` | 历史受控诊断的 $10^{-5}$ object gate 通过；新 source-exact copy 在 6 个 shared systems/30 个 solver rows 上使三个原 $10^{-11}$ output gates 以 0 误差通过；双跑数值差为 0，manifest/shared/projector fingerprints 一致 | production 内部 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍不可直接观测；off-collocation 与 historical projectors 非门控；未运行 complex disk、CR、root、Newton、eigenvalue 或 estimator |
| Historical double-ellipse full analytic complex-$k$ Root-readiness | evidence `PASS WITH CONDITIONS`; scientific `REPRODUCIBLE STOP / NO_SCREENED_DIP` | 29/29 locator 点 available；$s(k)$ 从 $0.2083091449$ 严格降至 $s(0.18)=0.03539366850$；baseline/repeat 全表数值差为 0 | 已被新主模型取代；没有 interior dip 或 seed，chart/disk/factor/full-$F$ CR 未运行 |
| Revised I4 Fliss missing-column benchmark, Rayleigh budget and three-path kernel audit | `PARTIAL SUCCESS`; `I4_FD_CANDIDATE_READY`; `BIE_RAYLEIGH_BUDGET_SCREENED`; `EWALD_VALUE_REFERENCE_CERTIFIED`; `EWALD_DERIVATIVE_REFERENCE_CERTIFIED`; `SLP_D_N_CERTIFIED_PROXY_RATIO_0P2`; `DLP_D_N_MTRACE48_CERTIFIED`; `PHYSICAL_ROOT_READY=STOP` | exact smooth profile 的 N80 strip 候选 $\lambda_h=3.460975044$；sharp-disk candidate windows 为 $[5,20]$、$[19,20]$；MATLAB 真 Ewald value/gradient/Hessian reference 通过；共同 $p/d=0.2$ 的四个 SLP/DLP wall actions 在 Ewald/MFS/Rayleigh 三路径上通过。DLP--D/DLP--N 最大 coefficient 误差为 $1.39\times10^{-14}$/$1.19\times10^{-13}$，DLP 四轴 self 最坏为 $1.40\times10^{-13}$，半网格有限带测试认证当前 $M_{\mathrm{trace}}=48$ | 认证只覆盖当前几何、实数非 Wood 点、两制造密度与有限 $M_{\mathrm{ref}}=96$；没有完成额外 $n_{\mathrm{tot}}/N_y$/Ewald wall ladder。package proxy 列表有一个重复角点，rank/edge-tail 仅为诊断。balanced $A_{\mathrm{def}}$/scanner、locator、root 与 estimator 未认证 |
| Current I1 discrete $A_{\mathrm{def}}$ design | `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS`; `DESIGN_BLOCKER_COUNT=0`; `NUMERICS_PAUSED` | current empty center 的 $2K$ safe-DtN 和 $4K$ full-graph 公式；original/reversed QZ reference planes；regular infinite-pair policy；seed-cluster continuation；双向 Sylvester separation；absolute Dirichlet/Robin chart margins；common-$M$ dual transport；legacy block mapping；两项独立 Skeptic 复审 | 尚无 assembly matrix、production `DIF`、analytic graph tangent 或 $A_{\mathrm{def}}'$。只授权下一里程碑的新 test-local static assembly oracle；DtN wall、locator、complex disk、root 仍停止 |

实现权威入口为
[[research/projects/eig-apost/implementation/archive/i0-manufactured/design|manufactured NEP design]]、
[[research/projects/eig-apost/implementation/archive/i1-finite-tail/half_guide_map|Half-guide map design]] 和
[[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie|Augmented BIE design]]；相应独立审查为
[[research/projects/eig-apost/implementation/archive/i0-manufactured/nep-review|manufactured NEP review]]、
[[research/projects/eig-apost/implementation/archive/i1-finite-tail/half_guide_review|Half-guide review]]、
[[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie-review|Augmented BIE review]] 和
[[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness_review|Root-readiness review]]；
本轮数值解释见
[[research/projects/eig-apost/implementation/archive/i3-provenance/root_result|I3 Root-readiness result]]、
[[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-result|I4 result]] 和
[[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-review|I4 review]]；当前替换 benchmark 见
[[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-fliss|I4 Fliss benchmark]]，最新 BIE port
预算见 [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-rayleigh|I4 Rayleigh budget]]，谱提取与
proxy-solver 收敛诊断见
[[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-extract|I4 spectral extraction closure]]。

## 已完成

- 读取仓库与 `research/` 的协作、权威和命名规则。
- 确认当前没有活动中的 `research/mainline/`，冻结主线不支配本专题。
- 对与特征值、Bloch 模态、奇异值扫描、收敛测试和 Green 函数基准有关的代码、
  草稿、结果文件和本地文献索引完成入口级盘点。
- 建立 Phase 1 专题目录、材料清单和首轮收敛问题。
- 用户已确认单句 RQ、首阶段范围、estimator 目标和 reference-truth 层级；已生成
  `phase1-scope/rq-summary.md`。
- Methodology Reflection、Checkpoint 1 和用户修订已完成；`phase1-scope/p-method.md`
  允许 Phase 2 调查，但在 DtN definition/construction 明确前不冻结实验实现。
- 已从 Fliss 原文独立澄清 half-guide DtN：先解半波导 Dirichlet problem，再取有符号
  Neumann trace；Riccati 是构造而非定义。
- 已核验 Joly、Fliss、Coatléven 的数值链均由 FEM/mixed FEM 生成 cell DtN blocks。
- 已核验三类 BIE--DtN 机制：Calderón operator quotient、special-solution trace
  quotient，以及 BIE unit-cell RtR + half-array Riccati。
- 已找到 line-defect PCW DtN 文献数据和 Petropoulos--Turc (2025) 的 BIE/Riccati
  近邻验证架构。
- 已核验 Güttel--Tisseur 的 matrix-level simple-root sensitivity、Moskow 的
  operator-level nonlinear eigenvalue correction，以及 two-level difference 必须另加
  saturation/tail assumption 才能代表剩余误差。
- 已把当前需要的公开全文统一保存并核验于 `ref/ref_data/`；临时渲染仍留在
  `research/tmp/`。
- 历史 Phase 3 曾选定首版 finite-tail hierarchy：固定 BIE/cell scattering 离散，只令
  cell count $N=2^j$ 增长。2026-08-11 起该选择已被 supersede，只保留为 cross-check、
  reference sequence 或 tail diagnostic，不再称精确 DtN hierarchy。
- 已建立 Phase 3 目录并写入 DtN 数据链、分层误差预算、projected correction、
  effectivity criteria、双椭圆 benchmark 和未来实现路线。
- 已按当前 port convention 推导左右 finite-tail DtN 的法向符号，并用独立随机复矩阵
  直接消元核对两段 scattering 组合公式；随后已在 Half-guide Stage 1 用现有 one-cell
  BIE/scattering 接口完成固定参数的 Octave smoke 核对。
- 已明确区分实轴 $\sigma_{\min}$ 极小点、离散 NEP 实际零点和精确 guided eigenvalue；
  root qualification 失败时不得报告 eigenvalue estimator。
- 已把 $\eta_j=\lvert \delta_j^{\mathrm{map}} \rvert$ 设为 doubling hierarchy 的 primary
  candidate，并把
  “effectivity 趋近 1”列为需要证明/反驳的核心发表命题，而非当前结论。
- 已建立 `phase2b-novelty/`，冻结 C1--C6 claim decomposition、检索边界、证据等级和
  `PASS / PASS WITH CONDITIONS / REVISE / STOP` 判据。
- 首轮检索已核验 Li--Lu (2007)、Yu--Hu--Lu--Rathsfeld (2022) 和
  Gopalakrishnan et al. (2025) 的公开全文，并把所需 PDF 保存到 `ref/ref_data/`。
- 首轮结果已经排除宽泛的“首个 photonic-crystal/line-defect eigenvalue estimator”
  表述，并形成待全文闭合的近邻清单；后续闭合结果列于下两项。
- 已补齐并全文核验 Giani (2013)、Engström--Giani--Grubišić (2016)、
  Boureghda--Choutri--Rezgui (2022)、Choutri (2008)、Xi--Gong--Sun (2024)、Lin--Lv
  (2025) 和 Klindworth (2015)，并按 `ref/ref_data/` 规则同步更新索引与 BibTeX。
- 已完成 backward/forward citation chasing、2024--2026 更新检索、C1--C6 claim matrix
  和 devil's-advocate checkpoint；正式 novelty verdict 为 `PASS WITH CONDITIONS`。
- 已确认 C1、C2 和 C3 的问题设置与计算部件已有直接先例；候选核心只能是 C4--C5：
  numerical half-guide DtN error 到 fixed-$\beta$ guided eigenvalue shift 的 computable
  estimator 及 simple-root effectivity。
- 已全文核验 Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al. (2000)，按规则登记为
  `ref/ref_data/Bonnet1995.pdf` 和 `ref/ref_data/Djellouli2000.pdf`。前者直接证明 exact Fourier boundary
  operator 截断下的 guided eigenvalue 先验收敛，后者给出 local boundary + FEM 和
  independent-reference comparison；两者进一步阻断宽泛 C4，但不覆盖 computable
  posterior half-guide DtN $k$-shift estimator 或 simple-root effectivity。
- 已在 `phase2b-novelty/r-gate.md` 中补充 C1--C6 的操作性定义，区分连续真根 $k_*$、
  固定 BIE/port 离散的极限根 $k_{\infty,h}$ 与 finite-tail 根 $k_{j,h}$，并解释
  projected correction、effectivity index 与 asymptotically exact estimator。
- 已按 ARS deep-research Phase 3 continuation 完成一轮 researcher/skeptic 并行调查与
  交叉复核；skeptic 充当 falsification-oriented human challenger。
- 已核验 Güttel--Tisseur 的 simple-root perturbation、bordered implicit determinant、
  Beyn contour method 与 argument-principle root count；Fliss 的 half-guide DtN/Riccati
  定义与 convergence statements 已定位到原文。Ehrhardt 的 finite scattering/doubling
  只作为数值先例，不作为当前二维 BIE convergence theorem。
- 已把 root 搜索具体化为固定公共表示的 augmented finite-tail NEP：实轴 scan 只定位，
  anchored analytic Rayleigh chart 保证局部解析性，小型 pole-free contour 隔离一个
  complex root，bordered implicit determinant Newton 完成 refinement。
- 已识别当前 `bloch.rayleigh_channels` 的 pointwise principal-square-root convention
  不适合 complex analytic root search；实现时必须改用从 physical seed 延拓的局部分支。
- 已修正 estimator 的层级含义与符号：
  $\delta_j^{\mathrm{map}}$ 一阶预测 $k_{j+1,h}-k_{j,h}$，在
  $e_{j+1}=o(e_j)$ 时估计 coarse tail
  $|k_{j,h}-k_{\infty,h}|$，不估计 fine-level tail。
- 已把未收敛 root defect、map correction 与 total next-level predictor 分开，并给出
  simple-root $C^1$ expansion 下 effectivity 趋于 $1$ 的条件化推导。
- 已给出依赖独立 saturation bound 与 correction remainder 的严格区间；同时以精确
  oscillatory scalar counterexample 证明有限个 observed ratios 不能生成 certificate。
- 已用一个非正规 `2 x 2` manufactured NEP 检查 correction 的符号和渐近 effectivity，
  并用 oscillatory scalar hierarchy 检查 false-asymptotic gate；这些是 Python
  algebraic sanity checks，不是项目 MATLAB validation。
- 历史 writer 曾把 Phase 2--3 的 finite-tail 理论和实现协议整理为旧
  `phase4-report/method.tex`；该 13 页版本现完整归档为
  `phase4-report/legacy-tail.tex`，不删除推导和审查记录。
- 历史独立 skeptic 曾逐式核对 augmented equations、analytic chart、bordered Newton、
  projected correction、coarse/fine 解释、条件 effectivity 证明和 reliable interval；
  writer 未改变 researcher 的核心数学逻辑。
- 历史稿曾按 skeptic 初轮 `REVISE` 意见补入同维 $F_{\infty,h}$ scattering-block lift、
  far-block 一致可逆性与 kernel bridge 条件、完整 doubling Schur pole gate、Fliss DtN
  的谱适用域，以及紧圆盘上的 $C^1$ 范数；delta-audit verdict 为
  `PASS WITH CONDITIONS`。
- 历史稿曾清理 notation conflicts：center extractors 改记为 $\mathcal E_L,\mathcal E_R$，
  三个标量反例与主 NEP 符号分离，并内联双侧 DtN map-difference 诊断。
- 历史 finite-tail PDF 曾完成逐页渲染检查；当前连续 DtN/BIE `method.pdf` 已重新生成并
  另行检查。
- 已在唯一活动目录 `implementation/i1/` 冻结离散 $A_{\mathrm{def}}$ 设计。两位
  独立 Skeptic 先后发现并促成修复 left reversed-pair reference、双向 `DIF/sep`、
  seed-cluster continuation 和 ratio-only chart gate；最终均报告 design-level blocker 为
  0。稳定定义已同步写入 `method.tex`，16 页 `method.pdf` 已重新构建并逐页渲染检查。
- 本轮未调用 Engineer、未修改或运行 `test/`、未修改 package 源码，也未组装任何实际
  $A_{\mathrm{def}}$。下一阶段只允许新 test-local static assembly oracle。
- 已在 `test/eig-apost-nep/` 完成 manufactured `2 x 2` analytic NEP 的 Octave 实现、
  两次确定性复现和 skeptic 审查；该实验只关闭有限维算法门。
- 已在 `test/hg-map/` 完成 Half-guide map Stage 1：非交换代数、exact analytic cell、
  固定物理 smoke、Wood/Robin/order 负例和数值向量复现均通过；完整 artifact-byte
  reproducibility 尚未建立。
- 已在 `test/aug-bie/` 完成 Augmented BIE Stage 2：A1/A2 manufactured oracles、实际
  ellipse/circle interface smoke、七个 finite-tail levels、availability/failure negatives
  与 source-aware unchanged-source rerun 均通过。最大 actual raw Schur error 为
  $3.16\times10^{-17}$，wrong-coordinate mutation mismatch 为 $7.22\times10^{-2}$。
- 已在 `test/root-ready/` 完成历史 Root-readiness early-stop proxy diagnostic 及两次
  unchanged-source Octave 运行。修正后的 $10^{-5}$ object-compatibility gate 中 78/78
  downstream rows 和 3/3 resolution rows 通过，aggregate max 为
  $1.898508\times10^{-9}$；rank 126/144 的 projector fingerprints、直接调用源码清单和
  数值向量完全复现。
- 历史受控诊断确认当前 `kernel.precomp_proxy` 接口不暴露其内部实际消费的
  $A_{\mathrm{pr}},b_{\mathrm{pr}}$；测试只能镜像构造并比较输出。coefficient、proxy
  field 与 residual 的三个 $10^{-11}$ gates 分别以 $2.798540\times10^{-7}$、
  $5.531552\times10^{-10}$ 和 $1.250388\times10^{-9}$ 失败，因而没有启动 root-stage
  计算。
- 已在 `test/root-ready/provenance-closure/` 完成 source-exact test-local copy、
  共享 $A,b$ cache、原阈值 gate、synthetic mutation negative 和 transactional
  baseline/repeat。6 个 shared systems 对应 30 个 solver rows；复制体与 package public
  output bitwise 一致，三个原 $10^{-11}$ output gates 的差异均为 0。
- provenance-closure 双跑均由 Conda `octave` 环境完成，baseline/repeat 用时分别为
  $6.4742$ s 和 $6.6299$ s；repeat 数值相对差为 0，11 项 direct-call manifest、
  shared-system 和 projector fingerprints 全部一致，原子发布与 marker hashes 经
  Engineer 独立复算通过。
- 已在 `test/root-ready/analytic-readiness/` 完成 I4 source-derived branch-injected
  evaluator、29 点 locator、fixed-chart/disk/CR/factor/negative 的 fail-closed 管线和
  transactional baseline/repeat。两次权威 Octave 运行 exit code 均为 0，所有科学表
  完全复现，aggregate numeric difference 为 0，19 项 direct-source manifest 与双 marker
  验证通过。
- I4 在 locator 处得到 `NO_SCREENED_DIP`：29/29 点 available，$s(k)$ 在
  $[0.04,0.18]$ 上严格下降，从 $0.2083091449$ 到右端点的 $0.03539366850$。没有 strict
  interior minimum，最小值仍约为 $10^{-3}$ 门限的 $35.4$ 倍，因此 chart、complex disk、
  factor ledger、full-$F$ CR 和七个依赖 seed 的 negatives 均按协议未运行。
- I4 Researcher 分析和 Skeptic post-run review 均认定 STOP 有效且可解释：证据为
  `PASS WITH CONDITIONS`，科学结论为 `REPRODUCIBLE STOP / NO_SCREENED_DIP`，I5 不获
  授权。该结论现只作为历史双椭圆 negative 保存。
- 已在 `test/i4-fliss-2013/` 完成 Fliss missing-column 双轨 benchmark。exact smooth FD
  baseline 给出主候选 $\lambda_h=3.460975044$，中心质量比例 $0.4959$、端部比例
  $6.97\times10^{-10}$、八/十二周期尾长相对位移 $2.32\times10^{-7}$；相对论文值差
  $0.116\%$。
- targeted N80/N120 edge confirmation 得到 $\varepsilon_{80,120}=7.91\times10^{-4}$、
  safe gap $(1.981350,5.386819)$ 和 candidate margin $1.479625$，四个冻结门全部通过，
  因而状态为 `TRACK_A_PROJECTED_GAP_CONFIRMED / I4_FD_CANDIDATE_READY`。
- sharp-disk 旧 affine/逐模态 pencil diagnostics 保留为历史失败路径。新的 projective
  ordered-QZ/doubling core 完成 15 个 $(\delta,k)$ low cases、三个尺度控制和三个 high
  pairs；canonical $\delta=0.30$ 与 small-clearance $\delta=0.10$ 分别观察到
  $[5,20]$、$[19,20]$ right-censored candidate windows。$\delta=0.20$ 在目标 $k$ 有两个
  neutral pairs，属于 parameter-specific projected-band 情形，不记作算法失败。
- 三个 high extractor errors 为 $1.499\times10^{-7}$、$4.282\times10^{-8}$ 和
  $1.438\times10^{-7}$，均未过 $10^{-8}$。因此全局
  `M_trace=NA / M_stable=NA / interval=NOT_CERTIFIED`，状态为
  `BIE_RAYLEIGH_BUDGET_SCREENED / TRACE_EXTRACTOR_BLOCKED`。
- canonical extractor-only 实验中的 Bessel closed form 与 package extractor 都直接使用
  Rayleigh modal kernel；它们的一致性只验证同一个 modal integral 的闭式公式、梯形求积
  和代码实现，不再作为 qpgreen 谱表示或 sum--integral interchange 的独立闭环。
- 新 `test/i4-three-path/` 实验以 Linton 式 (2.65) 的真 Ewald split 建立独立 value
  reference：Tables 2--5 五点最大误差 $5.07\times10^{-11}$，项目点
  Ewald--Rayleigh 最大误差 $1.11\times10^{-16}$。同一冻结密度先经完整 Ewald kernel
  积分再做 wall Fourier projection，与 Rayleigh extractor 的 SLP--D 系数最大差为
  $6.10\times10^{-16}$。这只在当前实数非 Wood、clearance $0.3$ 和冻结密度/模态范围内
  通过，不自动推广到导数、复杂 $k$ 或一般曲线。
- package MFS 在五个 canonical/hold-out point 上最大误差为 $4.89\times10^{-8}$，在
  Linton 五个原始点上最大误差为 $6.01\times10^{-8}$；SLP--D
  中 Ewald--MFS 和 MFS--Rayleigh 最大误差为 $4.69\times10^{-8}$。分别只加密
  $N_{\mathrm{side}},N_{\mathrm{top}},N_{\mathrm{proxy,edge}},M_{\mathrm{pw}}$ 时，系数变化为
  $7.52,5.99,3.72,4.45\times10^{-8}$，而 $n_{\mathrm{tot}}$ 与 $N_y$ 变化仅约
  $2.8\times10^{-11}$。当前 blocker 因而定位为 Octave augmented-MFS/proxy/solver path。
- cheap solver diagnostic 证明默认 `pinv` path 复现上述 point error；economy-SVD 在
  relative $\tau=3\times10^{-16}$ 时把三个冻结点降到 $3.95\times10^{-12}$，但同阈值
  `pinv(A,tol)` 产生 $5.98\times10^{-5}$，因此不能把问题简化为 cutoff-only，也未授权
  derivative/Hessian/wall 验证。
- 新 `test/i4-three-path-derivatives/` 已完成 MATLAB Ewald 解析导数资格化。Linton
  Tables 2--5 五点最大误差仍为 $5.07\times10^{-11}$；value-only Richardson、独立
  Rayleigh derivative、Helmholtz residual、mixed-derivative symmetry、source/target sign
  以及 $a,M_1,M_2,N$ 单变量加密均通过。此结论认证 point-level Ewald gradient/Hessian，
  不自动认证 wall layer actions。
- MATLAB pilot 锁定根目录 MEX、package `lsqminnorm` 和三个 package 精确路径。项目函数值
  最大误差为 $5.14\times10^{-10}$；全部一阶导数通过，但 `holdout_B` 的
  $G_{xx},G_{xy},G_{yy}$ 分别为 $1.46\times10^{-8}$、$1.60\times10^{-8}$、
  $1.59\times10^{-8}$，因此在 wall 前以 `P_POINT_KERNEL_UNCERTIFIED` 早停。
- 独立 fixed-$A,b$ 点诊断中 physical-y wrapper 与手工交换后的 computational-x 调用
  逐分量误差为 0；package Hessian 与同一 P 场的 Richardson gradient-FD 最坏误差为
  $2.12\times10^{-11}$。默认 `lsqminnorm` residual 为 $7.79\times10^{-8}$，不同 solver
  的六元组 spread 为 $3.04\times10^{-8}$。relative-$10^{-14}$ economy-SVD 的最坏
  Ewald 点误差为 $2.90\times10^{-11}$，但它只证明 rank/tolerance 是决定变量，不能
  静默替代 public package 路径。该问题是 DLP--N 的下游 Hessian blocker，不覆盖较早
  action 的 component-specific 资格。
- action-specific full run 中 SLP--D 全部通过：E--P/P--R 最大系数误差为
  $4.33\times10^{-10}$，P proxy self 最大为 $3.97\times10^{-10}$，因此旧 full SLP--D
  P-path blocker 已关闭。SLP--N 的系数三角、$n_{\mathrm{tot}}$、$N_y$、Ewald、tail 和
  $M_{\mathrm{pw}}$ 加密均通过，但 P 的 Nside/Ntop/Nedge self changes 分别为
  $6.56\times10^{-9}$、$2.58\times10^{-9}$、$1.09\times10^{-8}$。该历史 run 的 blocker 是
  `SLP_N_UNCERTIFIED_P_GX_PROXY_SELF_CONVERGENCE`；DLP--D/DLP--N 按用户冻结顺序未运行。
- 新 `test/i4-proxy-rule/` 没有继续加密历史 $p/d=0.7$，而是按最近周期镜像奇点先验
  唯一冻结 $p/d=0.2$。MATLAB pilot 的两个 $G_x$ 点 Ewald 误差最坏为
  $2.18\times10^{-14}$，training/错位 hold-out residual 为 $10^{-12}$--$10^{-11}$。
  canonical 的 SLP--D/SLP--N E--P 最大误差为 $1.64\times10^{-14}$、
  $3.42\times10^{-14}$；SLP--N Nedge/Nside/Ntop/$M_{\mathrm{pw}}$ self 为
  $4.14\times10^{-14}$、$2.12\times10^{-14}$、$3.03\times10^{-14}$、
  $1.61\times10^{-13}$。最终源码哈希写入 report 后复跑用时 $69.037429$ s，故
  `SLP_D_N_CERTIFIED_PROXY_RATIO_0P2` 与 OP-I4-1f 正式关闭。
- 新 `test/i4-dlp-trace/` 在任何 wall matrix 前完成 1.71 s MATLAB pilot。三个冻结点的
  $G_x,G_y$ 对 Ewald 最大误差为 $7.88\times10^{-14}$，四轴 point self 最坏为
  $7.64\times10^{-14}$；五个 level 的 rank 精确复现 $(302,328,302,302,330)$，且 public
  `lsqminnorm` residual 与 duplicate-column minimum-norm sanity 全部通过。95.539849 s
  canonical 随后按顺序认证 DLP--D、DLP--N 与 $M_{\mathrm{trace}}=48$。DLP--D/DLP--N
  E--P 最大误差为 $1.39\times10^{-14}$/$1.19\times10^{-13}$，DLP--N 最坏四轴 wall self
  为 $1.40\times10^{-13}$；四个 SLP/DLP actions 在 $|m|\le96$ 的逐模态三角全部通过。
  半网格直接 E/P 墙场的 $M=48$ 最坏重构误差为 $7.08\times10^{-12}$，omitted energy
  为 $5.00\times10^{-13}$。完整产物含 9,264 个 coefficient rows 与 49,152 个 wall
  samples；OP-I4-1h 和 OP-I4-6 在冻结范围内关闭。
- Researcher 与 Skeptic 均只认可 screening 结果，不授权 real-axis locator 或 complex
  root isolation。
  `production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` 作为 claim boundary 保持不变。
- 已识别并在 Stage 2 局部规避 variable-speed geometry 的 density-scaling mismatch；
  production `bloch.construct_S` 与 `scat_ld_lead_in` 尚未全局修改或验证。
- MATLAB R2023b 已运行 derivative qualification、point-only solver diagnostic、
  历史 action-specific early-stop wall run、singularity-aware proxy-rule pilot/full，以及
  新 DLP/trace pilot/full。所有新增实验代码和产物只位于 `test/` 下。

## 尚未进行

- 尚未证明 exact half-guide solution operator 与 $\Lambda_\pm(k)$ 在所选复邻域上的
  holomorphy，也未把 projected gap、half-guide Dirichlet spectrum、Wood threshold、cell
  poles 和 BIE representation poles 分成一个完整 analytic-domain ledger。
- 尚未证明 physical variational pencil $\mathcal F(k)$ 与 continuous BIE schema 的
  representation completeness、injectivity、kernel--field equivalence、Fredholm index 和
  adjoint consistency；因此 BIE matrix kernel 还不能等同于真实 guided mode。
- 尚未证明 continuous one-cell relation 到 BIE/Fourier generalized pencil 的 primal/adjoint
  $C^1$ consistency，也未得到 stable/unstable cluster 的 uniform `DIF/sep`、safe chart 或
  带固定 impedance/Riesz map 的 Cauchy-relation/Robin 合同。
- 原先要求的
  $\|\Lambda-E_M\Lambda_{h,M}Q_M\|_{H^{1/2}\to H^{-1/2}}\to0$ 对一阶非紧 DtN 和有限秩
  lift 通常不可能。尚需在 projected consistency + eigentrace regularity、principal-symbol
  subtraction + compact remainder、或 regular Galerkin convergence 三条路线中证明一条。
- 新的 $A_{\mathrm{def}}^{D/G}$ 理论设计已完成并通过两项审查，但尚未组装。locator、
  selected complex disk、anchored analytic Rayleigh chart、factor/pole ledger、full-$F$ CR、
  contour isolation、bordered root refinement 或 adjacent-level root matching 仍未执行且
  未获授权。
- 尚未得到独立 saturation 常数和 computable correction remainder；相邻层差只能称
  next-level correction，不能称 remaining-error estimator。
- 尚未修复并回归验证 production variable-speed density scaling；当前 ellipse 的修正
  只存在于 `test/aug-bie/` 的实验路径。
- 尚未直接捕获 production 调用内部实际消费的
  $A_{\mathrm{pr}},b_{\mathrm{pr}}$；本轮关闭的是冻结源码与 Octave 环境中的
  source-derived operational provenance，而不是更强的 runtime internal-array identity。
- 尚未建立独立 $k_{\mathrm{ref}}$、BIE/port refinement、MATLAB parity 或真实缺陷晶体
  waveguide benchmark。
- Leclerc et al. (2026) 的 HAL manuscript 尚处于 embargo；在全文核验与投稿前
  citation update 完成以前，不冻结 priority claim。

## 当前门槛

当前门是 `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS / I1_NUMERICS_PAUSED`。现行方法已经具备正确层级：
physical half-guide PDE 定义 exact $\Lambda_\pm$，physical center variational pencil
$\mathcal F(k)$ 在截断前定义真实根，continuous BIE 只作待证明的等价 realization，
ordered QZ 只计算 finite pencil 的 deflating subspace。旧 finite-tail 方法已降为 legacy。

恢复新路线 I1 的 production 数值与 locator 前仍必须关闭
[[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 中的
OP-M0-1--OP-M0-4。one-cell pencil、左右 Cauchy blocks 和 design-level
`DIF/sep`/chart gates 已完成；最便宜的下一步仅是 test-local static assembly oracle。其后
仍需完成 concrete analytic-domain exceptions、physical/BIE kernel bridge、production
separation/graph-tangent qualification，并选定 projected DtN 到 continuous spectral
approximation 的可证明路线。OP-M0-5 的
saturation/remainder 是 `IMPORTANT CAVEAT`，不阻止先寻找 qualified discrete root，但会
阻止 remaining-error/certification claim。

因此不得把当前状态描述为“只差 balanced $A_{\mathrm{def}}$”。static assembly oracle
通过后仍需关闭四个 M0 blocker，并依次完成：M1 production $A_{\mathrm{def}}$ 与
no-pollution consistency、M2 locator/analytic
readiness、M3 root isolation、M4 two-level correction、M5 independent reference/effectivity。
既有 Fliss FD candidate 和 SLP/DLP/$M_{\mathrm{trace}}$ 数值证据继续保留，但不缩短上述
理论—离散桥接链。仍不创建 `research/mainline/`，也不使用绝对优先权表述。

## 新 session handoff

- 唯一允许写入的 worktree 是 `/Users/whc/Documents/Work/epost`，当前分支为
  `codex/epost`，本阶段基准提交为 `d699ae9`。不得修改主分支所在目录，也不得删除该
  worktree。
- 新 session 应先读取仓库根目录与 `research/` 下的 `AGENTS.md`，再读取本文件、
  [[research/projects/eig-apost/implementation/README|implementation stage overview]]、
  [[research/projects/eig-apost/phase1-scope/questions|Phase 1 commitments]]、
  [[research/projects/eig-apost/phase1-scope/p-method|Phase 1 analytical framework]]、
  [[research/projects/eig-apost/phase2-sources/synthesis-dtn|DtN source synthesis]]、
  [[research/projects/eig-apost/phase2-sources/r-nep-error|NEP error sources]]、
  [[research/projects/eig-apost/implementation/i1/design|current I1 discrete design]]、
  [[research/projects/eig-apost/implementation/i1/review|current I1 review]]、
  [[research/projects/eig-apost/phase4-report/method.tex|current continuous method]]、
  [[research/projects/eig-apost/phase4-report/legacy-tail.tex|legacy finite-tail formulation]] 和
  [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]。Phase 1--2 文件
  保持历史原文，不因本次重构回写。
- 新路线 I1 当前 verdict 是
  `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS`，并保留历史 I4 数值标签
  `PARTIAL SUCCESS -- I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / EWALD_DERIVATIVE_REFERENCE_CERTIFIED /
  SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 / DLP_D_N_MTRACE48_CERTIFIED`；
  `REPRODUCIBLE STOP / NO_SCREENED_DIP` 只描述历史双椭圆实验。I3 的
  `root_readiness_review.md` Section L 与 `root_result.md` Section I 继续作为 provenance
  历史边界；不得把历史 I3 的下一阶段授权覆盖当前 BIE blocker。
- 保持 Researcher + Engineer + Skeptic 多 subagent 协作：方法重构期以 Researcher 为主；
  Engineer 只在 TeX 构建或必要一致性检查时介入，Skeptic 独立只读审查。Skeptic
  必须按当前工程目标区分 `BLOCKER`、`IMPORTANT CAVEAT`、`MINOR CAVEAT`，只有
  blocker 能停止阶段，并优先建议廉价 numerical sanity check；主 agent 负责综合、更新
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]] 和
  handoff。
- 当前权威 operational provenance 状态仍保留
  `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`，但更新的阶段 gate 是
  `I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / EWALD_DERIVATIVE_REFERENCE_CERTIFIED /
  SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 / DLP_D_N_MTRACE48_CERTIFIED`；
  `production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` 和
  `PHYSICAL_ROOT_READY=STOP` 保持不变。不得解释成 qualified root 或 estimator。
- 新路线 I1 下一里程碑授权 OP-CI1-1 的最窄实现：只在新的 `test/` 目录组装 static algebraic oracle，
  使用 manufactured graph inputs 与小型 exact Sylvester separation，验证维数、Schur、
  basis、符号和 chart negatives。不得运行 production DtN wall、bounded locator、
  complex disk、contour 或 root，也不得返回 production $A_{\mathrm{def}}'$。
- 当前新增内容位于 `test/i4-rayleigh-budget/`、`test/i4-extract/`、
  `test/i4-three-path/`、`test/i4-three-path-derivatives/`、`test/i4-proxy-rule/`、
  `test/i4-dlp-trace/` 与本专题
  STATUS/README/ledger/report 文档；package 源码未修改。MATLAB R2023b qualification、
  action-specific pilot、历史 early-stop full wall run、point-only fixed-system diagnostic、
  proxy-rule pilot/full 与 DLP/trace pilot/full 已运行；最终 DLP/trace full 用时
  $95.539849$ s 并通过顺序门。
  历史 Octave canonical 用时 $531.181285$ s。

新 session 若调用 Engineer，应只实现上述 static assembly oracle；理论侧继续处理
OP-M0-1 的 concrete exact-DtN/analytic-domain contract 和 OP-M0-2 的 physical/BIE
kernel bridge。不得以 balanced matrix 或固定点数值 sanity check 跳过连续—离散证明义务，
也不得把当前有限 $M_{\mathrm{ref}}=96$ 制造密度认证外推为完整
$H^{1/2}\to H^{-1/2}$ operator-norm convergence。
