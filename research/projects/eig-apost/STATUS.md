# Eigenvalue a posteriori error status

更新日期：2026-08-09。

## 当前状态

- 工作流：Academic Research Suite / Deep Research，现处于受审查的数值实现阶段。
- 论文定位：以可运行、可复现、具有代表性真实案例的 empirical estimator 为当前目标；
  theorem-level certification 是更强的未来方向，不作为默认阶段门。
- 阶段：Phase 1--4 已完成范围、来源、novelty、理论方案和方法稿；随后完成三个
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
  $6.10\times10^{-16}$，而所有含 MFS 的比较在低阶模态达到
  $4.69\times10^{-8}$；在 Linton 五个原始点上，MFS 与合格 Ewald 的最大差也达到
  $6.01\times10^{-8}$。MFS 四个 proxy 参数的单变量变化为
  $3.72\times10^{-8}$--$7.52\times10^{-8}$。因此当前 value-level blocker 已独立定位到
  augmented-MFS/proxy/solver path；导数 Ewald 与其余 wall Cauchy data 尚未启动。
- 状态：`active investigation`。
- 阶段门：manufactured root/correction pipeline 为窄范围 `GO`，Half-guide map 为
  Stage 1 `GO`，Augmented BIE 为 `STAGE2_DISCRETE_ALGEBRA_GO`；provenance-closure 为
  `PASS WITH CONDITIONS`，其 operational label 为
  `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`。当前 I4 verdict 为
  `PARTIAL SUCCESS -- I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / SLP_D_EWALD_RAYLEIGH_PASS /
  OCTAVE_AUGMENTED_MFS_PROXY_SOLVER_PATH_BLOCKED`；
  I5 root isolation 不获授权，`PHYSICAL_ROOT_READY=STOP`。现有证据支持一个可信的
  exact-profile finite-strip eigenvalue candidate，但不支持 qualified BIE root、
  连续 kernel--field equivalence、unconditional effectivity 或 certified interval。

## 实现 checkpoint

| Checkpoint | 结果 | 已验证 | 明确未验证 |
|---|---|---|---|
| Manufactured NEP | `GO`; `conditional/empirical` | 固定维数 contour count、bordered Newton、root qualification、projected correction 和四个负例；末级 tail effectivity 为 `0.999987793` | BIE/DtN、branch cut、pole、representation kernel、common discretization error |
| Half-guide map | Stage 1 `GO` | 非交换 Redheffer/terminal/Cayley 次序、exact analytic cell、固定 $k=0.10$ 的中心圆形介质夹杂单胞（旧报告称 `EDC cell`）same-cell QZ/doubling smoke 和负例传播；Case B 最终误差 $1.93\times10^{-15}$ | 独立 PDE truth、频率区间、asymmetric/defective cases、map convergence theorem；artifact-level 仅 `PARTIALLY_REPRODUCIBLE` |
| Augmented BIE | `STAGE2_DISCRETE_ALGEBRA_GO`; `ROOT_READY=STOP` | 固定九块 $(n+8p)$ assembly、scaled density coordinate、raw/reduced Schur agreement、七级 availability 与 failure ledger；unchanged-source 复现差为 $0$ | 连续表示单射性、kernel--field equivalence、pole-free analytic neighborhood、root/eigenvalue/estimator |
| Root-readiness proxy diagnostic and provenance closure | `PASS WITH CONDITIONS`; `GO` only to full analytic complex-$k$ Root-readiness; `PHYSICAL_ROOT_READY=STOP` | 历史受控诊断的 $10^{-5}$ object gate 通过；新 source-exact copy 在 6 个 shared systems/30 个 solver rows 上使三个原 $10^{-11}$ output gates 以 0 误差通过；双跑数值差为 0，manifest/shared/projector fingerprints 一致 | production 内部 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍不可直接观测；off-collocation 与 historical projectors 非门控；未运行 complex disk、CR、root、Newton、eigenvalue 或 estimator |
| Historical double-ellipse full analytic complex-$k$ Root-readiness | evidence `PASS WITH CONDITIONS`; scientific `REPRODUCIBLE STOP / NO_SCREENED_DIP` | 29/29 locator 点 available；$s(k)$ 从 $0.2083091449$ 严格降至 $s(0.18)=0.03539366850$；baseline/repeat 全表数值差为 0 | 已被新主模型取代；没有 interior dip 或 seed，chart/disk/factor/full-$F$ CR 未运行 |
| Revised I4 Fliss missing-column benchmark, Rayleigh budget and three-path kernel audit | `PARTIAL SUCCESS`; `I4_FD_CANDIDATE_READY`; `BIE_RAYLEIGH_BUDGET_SCREENED`; `EWALD_VALUE_REFERENCE_CERTIFIED`; `SLP_D_EWALD_RAYLEIGH_PASS`; `OCTAVE_AUGMENTED_MFS_PROXY_SOLVER_PATH_BLOCKED`; `PHYSICAL_ROOT_READY=STOP` | exact smooth profile 的 N80 strip 候选 $\lambda_h=3.460975044$；sharp-disk candidate windows 为 $[5,20]$、$[19,20]$；真 Ewald 复现 Linton 五个表值的最大误差为 $5.07\times10^{-11}$，项目点 Ewald--Rayleigh 误差为 $1.11\times10^{-16}$；同一冻结密度的 Ewald--Rayleigh SLP--D 系数最大差为 $6.10\times10^{-16}$；$n_{\mathrm{tot}}$、$N_y$ 与 Ewald 各轴加密均通过 | Bessel closed form 与 extractor 共用 modal kernel，旧一致性不再当作独立谱闭环；Octave fallback `pinv(A)` 下 P-path 在 Linton 同点最大误差为 $6.01\times10^{-8}$，SLP--D pairwise 最大误差为 $4.69\times10^{-8}$，四个 proxy 单轴变化均失败；内部原因仍可能是 solver backend、proxy basis 或 collocation；Ewald derivative、其余 D/N、$M_{\mathrm{trace}}$、locator、root 与 estimator 未运行或未认证 |

实现权威入口为
[[research/projects/eig-apost/implementation/design|manufactured NEP design]]、
[[research/projects/eig-apost/implementation/half_guide_map|Half-guide map design]] 和
[[research/projects/eig-apost/implementation/aug-bie|Augmented BIE design]]；相应独立审查为
[[research/projects/eig-apost/implementation/nep-review|manufactured NEP review]]、
[[research/projects/eig-apost/implementation/half_guide_review|Half-guide review]]、
[[research/projects/eig-apost/implementation/aug-bie-review|Augmented BIE review]] 和
[[research/projects/eig-apost/implementation/root_readiness_review|Root-readiness review]]；
本轮数值解释见
[[research/projects/eig-apost/implementation/root_result|I3 Root-readiness result]]、
[[research/projects/eig-apost/implementation/i4-result|I4 result]] 和
[[research/projects/eig-apost/implementation/i4-review|I4 review]]；当前替换 benchmark 见
[[research/projects/eig-apost/implementation/i4-fliss|I4 Fliss benchmark]]，最新 BIE port
预算见 [[research/projects/eig-apost/implementation/i4-rayleigh|I4 Rayleigh budget]]，谱提取与
proxy-solver 收敛诊断见
[[research/projects/eig-apost/implementation/i4-extract|I4 spectral extraction closure]]。

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
- 已选定首版单参数 DtN hierarchy：固定 BIE/cell scattering 离散，只令 finite-tail
  cell count $N=2^j$ 增长；实根 sequence 采用远端 Dirichlet/real-Robin 结构保持闭合，
  zero-incoming sequence 只作 half-guide map 交叉核验。
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
- 已由 writer 把 Phase 2--3 的理论和实现协议整理为
  `phase4-report/method.tex`，并用 XeLaTeX 生成 13 页 `output/pdf/method.pdf`。
- 已由独立 skeptic 逐式核对 augmented equations、analytic chart、bordered Newton、
  projected correction、coarse/fine 解释、条件 effectivity 证明和 reliable interval；
  writer 未改变 researcher 的核心数学逻辑。
- 已按 skeptic 初轮 `REVISE` 意见补入同维 $F_{\infty,h}$ scattering-block lift、
  far-block 一致可逆性与 kernel bridge 条件、完整 doubling Schur pole gate、Fliss DtN
  的谱适用域，以及紧圆盘上的 $C^1$ 范数；delta-audit verdict 为
  `PASS WITH CONDITIONS`。
- 已清理 active notation conflicts：center extractors 改记为 $\mathcal E_L,\mathcal E_R$，
  三个标量反例与主 NEP 符号分离，并内联双侧 DtN map-difference 诊断。
- 已完成 PDF 逐页渲染检查；没有公式裁切、页面重叠或重复参考文献标题。
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
- Researcher 与 Skeptic 均只认可 screening 结果，不授权 real-axis locator 或 complex
  root isolation。
  `production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` 作为 claim boundary 保持不变。
- 已识别并在 Stage 2 局部规避 variable-speed geometry 的 density-scaling mismatch；
  production `bloch.construct_S` 与 `scat_ld_lead_in` 尚未全局修改或验证。
- MATLAB 尚未运行；上述数值证据均由 Conda `octave` 环境产生，实验代码只位于
  `test/` 下。

## 尚未进行

- 尚未证明实际 center BIE 表示的连续 kernel--field equivalence、排除 zero-field
  representation nullspace，或给出 root-search domain 上的一致 injectivity/pole-free
  条件；fixed-$k$ raw/reduced Schur agreement 不能替代这些命题。
- 尚未在当前 Fliss/sharp-disk 替换 benchmark 的 selected disk 上执行 anchored analytic
  Rayleigh chart、fixed-rank factor ledger、full-$F$ CR 和完整 negatives；当前因
  trace/extractor reference 与 balanced $A_{\mathrm{def}}$/scanner blockers 没有可解释的
  BIE locator。尚未进行 complex
  contour isolation、bordered root refinement 和 adjacent-level root matching。package
  pointwise principal-square-root convention 不得直接用于 complex analytic search。
- 尚未证明 finite-tail half-guide map convergence、得到独立 saturation 常数
  $\bar q<1$，也没有 computable correction remainder；observed doubling ratios 仍只能
  作为 empirical diagnostic。
- 尚未把一阶 correction 假设验证到当前 BIE--DtN operator family，因而不能报告
  reliable eigenvalue interval 或真实二维缺陷波导的 estimator effectivity。
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

当前不再延伸历史双椭圆 locator。Fliss exact-profile Track A 已关闭经验 projected-gap
blocker，并给出 $\lambda_h=3.460975044$ 的可信 FD 候选；这已经反驳“该 missing-column
模型普遍无解”的怀疑，但不是 qualified root。

当前最小下一步仍是 OP-I4-1f，但不再依赖 Bessel--extractor 共享-kernel 证据。不得再盲加
boundary $n$ 或 wall $N_y$。最便宜的决定性检查是把既有 relative
$\tau=3\times10^{-16}$ economy-SVD backend/reconstruction 完全冻结在 test-local copy 中，
不使用 hold-out 调参，先计算本轮两个 off-axis hold-out point values，再只重放一次
$n_{\mathrm{tot}}=128,N_y=256$ 的 SLP--D authority wall。若 point 的
$2\times10^{-9}$ 门和 coefficient 的 $10^{-8}$ 门都通过，再对同一 solver policy 做
roundoff-equivalent assembly 与四个 proxy 单轴加密；否则直接区分 solver path 与 proxy
basis/collocation limitation。只有 SLP--D 闭合后才实现并认证解析 Ewald gradient/Hessian，
依次运行 SLP--N、DLP--D、DLP--N。随后才处理 OP-I4-1e 的 block-balanced
$A_{\mathrm{def}}$/scanner integration。Fliss smooth Gaussian 只提供尺度参考，不得当作
sharp-disk root 或 reference。

从当前 sharp-disk 路径计，约三个阶段可观察到可解释的实轴 candidate：MFS SLP--D
solver closure、Ewald derivative/full wall Cauchy data 与 $M_{\mathrm{trace}}$ closure、
block-balanced $A_{\mathrm{def}}$ 加 bounded locator。再加 full analytic complex-$k$
readiness 与 contour/Newton qualification，约五个阶段才可能得到 qualified root；第六
阶段才产生 empirical estimator，第七阶段才得到 independent high-resolution reference
effectivity。
continuous kernel--field/representation、saturation/remainder 和 validated total error budget
仍是更强 certification 的另外问题。仍不创建 `research/mainline/`，也不使用绝对优先权
表述。

## 新 session handoff

- 唯一允许写入的 worktree 是 `/Users/whc/Documents/Work/epost`，当前分支为
  `codex/epost`，本阶段基准提交为 `d699ae9`。不得修改主分支所在目录，也不得删除该
  worktree。
- 新 session 应先读取仓库根目录与 `research/` 下的 `AGENTS.md`，再读取本文件、
  [[research/projects/eig-apost/implementation/README|implementation stage overview]]、
  [[research/projects/eig-apost/implementation/i4-fliss|current I4 Fliss benchmark]]、
  [[research/projects/eig-apost/implementation/i4-rayleigh|current I4 Rayleigh budget]]、
  [[research/projects/eig-apost/implementation/i4-readiness|I4 design]]、
  [[research/projects/eig-apost/implementation/i4-result|I4 result]]、
  [[research/projects/eig-apost/implementation/i4-review|I4 review]]、
  `implementation/SYMBOL.md`、
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]] 和
  `test/i4-rayleigh-budget/README.md`、
  `test/i4-rayleigh-budget/output/batch-all/global-summary.txt`、
  `case-summary.csv`、`ntot-action-ledger.csv` 与 `gate-summary.txt`，再读
  `test/i4-fliss-2013/output/baseline/report.md`、
  `output/targeted-edge-confirm/report.md` 与
  `output/bie-bidirectional-pencil/report.md`。历史证据入口仍为
  `test/root-ready/analytic-readiness/output/repeat/report.md` 与 `locator.csv`。
- I4 当前 verdict 是
  `PARTIAL SUCCESS -- I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / SLP_D_EWALD_RAYLEIGH_PASS /
  OCTAVE_AUGMENTED_MFS_PROXY_SOLVER_PATH_BLOCKED`；
  `REPRODUCIBLE STOP / NO_SCREENED_DIP` 只描述历史双椭圆实验。I3 的
  `root_readiness_review.md` Section L 与 `root_result.md` Section I 继续作为 provenance
  历史边界；不得把 I3 的下一阶段授权覆盖当前 BIE blocker。
- 保持 Researcher + Engineer + Skeptic 多 subagent 协作：Researcher 冻结数学和实验
  设计，Engineer 只在获准路径实现并复现，Skeptic 在实现前后独立只读审查。Skeptic
  必须按当前工程目标区分 `BLOCKER`、`IMPORTANT CAVEAT`、`MINOR CAVEAT`，只有
  blocker 能停止阶段，并优先建议廉价 numerical sanity check；主 agent 负责综合、更新
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]] 和
  handoff。
- 当前权威 operational provenance 状态仍保留
  `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`，但更新的阶段 gate 是
  `I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / SLP_D_EWALD_RAYLEIGH_PASS /
  OCTAVE_AUGMENTED_MFS_PROXY_SOLVER_PATH_BLOCKED`；
  `production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` 和
  `PHYSICAL_ROOT_READY=STOP` 保持不变。不得解释成 qualified root 或 estimator。
- 下一步仅允许由 Researcher 冻结 economy-SVD solver policy，Engineer 在新的 test-only
  follow-up 中先运行本轮两个 hold-out point values 和一次 authority SLP--D wall，Skeptic
  在运行前后审查。不得用 hold-out 重选 solver，不得调宽 $10^{-8}$ coefficient 或
  $2\times10^{-9}$ reference-change 门。只有 SLP--D 闭合后才实现 Ewald analytic
  gradient/Hessian 与其余 wall $D/N$ actions；不得重新运行 legacy affine scan绕过 blocker。
- 当前新增内容位于 `test/i4-rayleigh-budget/`、`test/i4-extract/`、
  `test/i4-three-path/` 与本专题 STATUS/README/ledger/report 文档；package 源码未修改。
  MATLAB 尚未运行。三路径 qualification、pilot 和 canonical SLP--D 的 Octave exit code
  均为 0；canonical 用时 $531.181285$ s。

新 session 应从冻结 economy-SVD solver path 的 hold-out point value 与 authority
SLP--D closure 开始，不得直接启动 derivative wall actions、实轴 scan、complex disk、
contour、root 或 estimator，也不得把三个 in-sample point values 升级为 certified wall
trace，或把 source-derived provenance 升级为 production 内部数组已观测。
