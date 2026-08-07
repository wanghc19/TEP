# Eigenvalue a posteriori error status

更新日期：2026-08-07。

## 当前状态

- 工作流：Academic Research Suite / Deep Research，现处于受审查的数值实现阶段。
- 阶段：Phase 1--4 已完成范围、来源、novelty、理论方案和方法稿；随后完成三个
  Octave implementation checkpoints：manufactured NEP、Half-guide map 和
  Augmented BIE / center coupling。
- 状态：`active investigation`。
- 阶段门：manufactured root/correction pipeline 为窄范围 `GO`，Half-guide map 为
  Stage 1 `GO`，Augmented BIE 为 `STAGE2_DISCRETE_ALGEBRA_GO`；但总门仍为
  `ROOT_READY=STOP`。现有证据只支持固定离散代数、单点 interface smoke 和条件经验
  estimator，不支持真实 guided eigenvalue、连续 kernel--field equivalence、
  unconditional effectivity 或 certified interval。

## 实现 checkpoint

| Checkpoint | 结果 | 已验证 | 明确未验证 |
|---|---|---|---|
| Manufactured NEP | `GO`; `conditional/empirical` | 固定维数 contour count、bordered Newton、root qualification、projected correction 和四个负例；末级 tail effectivity 为 `0.999987793` | BIE/DtN、branch cut、pole、representation kernel、common discretization error |
| Half-guide map | Stage 1 `GO` | 非交换 Redheffer/terminal/Cayley 次序、exact analytic cell、固定 $k=0.10$ 的 EDC same-cell QZ/doubling smoke 和负例传播；Case B 最终误差 $1.93\times10^{-15}$ | 独立 PDE truth、频率区间、asymmetric/defective cases、map convergence theorem；artifact-level 仅 `PARTIALLY_REPRODUCIBLE` |
| Augmented BIE | `STAGE2_DISCRETE_ALGEBRA_GO`; `ROOT_READY=STOP` | 固定九块 $(n+8p)$ assembly、scaled density coordinate、raw/reduced Schur agreement、七级 availability 与 failure ledger；unchanged-source 复现差为 $0$ | 连续表示单射性、kernel--field equivalence、pole-free analytic neighborhood、root/eigenvalue/estimator |

实现权威入口为
[[research/projects/eig-apost/implementation/design|manufactured NEP design]]、
[[research/projects/eig-apost/implementation/half_guide_map|Half-guide map design]] 和
[[research/projects/eig-apost/implementation/aug-bie|Augmented BIE design]]；相应独立审查为
[[research/projects/eig-apost/implementation/nep-review|manufactured NEP review]]、
[[research/projects/eig-apost/implementation/half_guide_review|Half-guide review]] 和
[[research/projects/eig-apost/implementation/aug-bie-review|Augmented BIE review]]。

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
- 已识别并在 Stage 2 局部规避 variable-speed geometry 的 density-scaling mismatch；
  production `bloch.construct_S` 与 `scat_ld_lead_in` 尚未全局修改或验证。
- MATLAB 尚未运行；上述数值证据均由 Conda `octave` 环境产生，实验代码只位于
  `test/` 下。

## 尚未进行

- 尚未证明实际 center BIE 表示的连续 kernel--field equivalence、排除 zero-field
  representation nullspace，或给出 root-search domain 上的一致 injectivity/pole-free
  条件；fixed-$k$ raw/reduced Schur agreement 不能替代这些命题。
- 尚未实现 anchored analytic Rayleigh branch chart、完整 contour pole ledger、complex
  contour isolation、bordered root refinement 和 adjacent-level root matching。当前
  pointwise principal-square-root convention 不得直接用于 complex analytic search。
- 尚未证明 finite-tail half-guide map convergence、得到独立 saturation 常数
  $\bar q<1$，也没有 computable correction remainder；observed doubling ratios 仍只能
  作为 empirical diagnostic。
- 尚未把一阶 correction 假设验证到当前 BIE--DtN operator family，因而不能报告
  reliable eigenvalue interval 或真实二维缺陷波导的 estimator effectivity。
- 尚未修复并回归验证 production variable-speed density scaling；当前 ellipse 的修正
  只存在于 `test/aug-bie/` 的实验路径。
- 尚未建立独立 $k_{\mathrm{ref}}$、BIE/port refinement、MATLAB parity 或真实缺陷晶体
  waveguide benchmark。
- Leclerc et al. (2026) 的 HAL manuscript 尚处于 embargo；在全文核验与投稿前
  citation update 完成以前，不冻结 priority claim。

## 当前门槛

本轮离散实现 checkpoint 已关闭并可提交；下一阶段尚未开始。进入真实 root search 前，
必须先关闭 continuous center-BIE kernel--field/representation gate，并冻结一个避开 Wood、
BIE、terminal 和 raw-Schur poles 的 analytic search neighborhood。随后才可实现 anchored
Rayleigh chart、contour isolation、bordered Newton 与 adjacent-level matching；这些通过后
才测试真实 projected correction。只有再独立建立 saturation/remainder bound 后，才可把
结果称为 reliable interval。仍不创建 `research/mainline/`，也不使用绝对优先权表述。
