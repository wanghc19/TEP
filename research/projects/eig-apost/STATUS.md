# Eigenvalue a posteriori error status

更新日期：2026-07-30。

## 当前状态

- 工作流：Academic Research Suite / Deep Research。
- 阶段：Phase 1 Scoping、Phase 2 feasibility investigation 与 Phase 2b novelty gate
  已完成；Phase 2b verdict 为 `PASS WITH CONDITIONS`。Phase 3 已完成一轮受条件约束
  的 root-search 与 estimator 设计及 adversarial review。Phase 4 已完成方法汇总稿、
  skeptic 审查、数学修订和 PDF 交付。
- 状态：`active investigation`。
- 阶段门：Phase 4 文稿审查 verdict 为 `PASS WITH CONDITIONS`，项目研究门仍为
  `REVISE`。复根搜索方案和一阶 tail estimator 在明确假设下
  可实现且数学自洽；augmented formulation 等价性、analytic implementation、
  map convergence 与 reliable remainder 尚未闭合，不能声称已有 unconditional 或
  certified estimator。

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
  直接消元核对两段 scattering 组合公式；尚未用实际 MATLAB cell map 核对。
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
- 已完成 PDF 逐页渲染检查；没有公式裁切、页面重叠或重复参考文献标题。未运行 MATLAB
  或 Octave，未产生项目数值结果。

## 尚未进行

- 尚未把文献中的一阶 correction 假设验证到当前 BIE--DtN operator family，也没有
  可计算 remainder 或可靠性上界。
- 已写出 candidate $(n+8p)\times(n+8p)$ block system 与 equation count，但尚未逐行
  映射到实际 center BIE/extractor blocks，也未证明 kernel--finite-field equivalence
  或排除 representation nullspace 与 one-cell BIE poles 的伪根。
- 尚未实现 analytic Rayleigh branch chart、contour count、bordered complex Newton 或
  adjacent-level root matching。
- 尚未从 map-convergence theorem、stable-subspace estimate 或其他独立来源得到
  $\bar q<1$；observed doubling ratios 只能作 empirical diagnostic。
- 未冻结首版 cell port formulation，也未确认现有 `A_QP` 能否原样生成所需 cell
  DtN/RtR map。
- 尚未冻结 benchmark 参数、independent reference solver 或最终论文大纲。
- 尚未证明 structure-preserving finite-tail map convergence、doubling superlinear root
  separation 或 primary estimator 的 effectivity。
- 未审定任何连续理论命题、谱等价命题或离散正确性结论。
- 未运行 MATLAB 或 Octave，未修改任何 MATLAB 文件。
- Leclerc et al. (2026) 的 HAL manuscript 尚处于 embargo；在全文核验与投稿前
  citation update 完成以前，不冻结 priority claim。

## 当前门槛

Phase 4 文稿自身为 `PASS WITH CONDITIONS`，但项目门槛仍是 `REVISE`：先把 candidate
square augmented operator 映射到实际 BIE blocks，
静态核对并证明 kernel equivalence，再实现 analytic branch、contour isolation 和
bordered complex root solver。只有这些
通过后才验证 projected correction；只有独立建立 saturation/remainder bound 后才报告
reliable interval。仍不创建 `research/mainline/`，也不使用绝对优先权表述。
