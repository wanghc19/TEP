# Eigenvalue a posteriori open-problem ledger

本文件集中维护 `eig-apost` 各实现阶段仍与当前目标有关的问题。当前目标是一篇偏工程的
论文：先得到可运行、可复现、在代表性真实案例上有数值效果的 eigenvalue estimator，
并诚实说明适用范围；除非当前 claim 明确要求，不把 theorem-level certification 作为
默认验收条件。

各 review 保留其历史原文，只在末尾链接本 ledger。这里的分类按当前工程目标重新评估，
不回写或伪造旧 verdict。最新阶段状态仍以
[[research/projects/eig-apost/STATUS|project STATUS]] 为准。

## 分类与维护规则

- `BLOCKER`：会使当前阶段主要产物无效、不可解释，或直接阻止下一项必要计算。只有未
  解决的 blocker 才能触发 `STOP` 或 `BLOCKED`。
- `IMPORTANT CAVEAT`：显著限制范围、稳健性、复现性或解释，论文必须披露或安排检查，
  但不阻止当前阶段或下一阶段。
- `MINOR CAVEAT`：低影响限制、文档问题或可选稳健性扩展，可以延后。
- 每项必须给出 blocking scope 和 cheapest next check。若一个问题不能改变当前验收门或
  下一项计算，不再继续深挖。
- 每次 stage review 后由主 agent 合并 Skeptic handoff；Skeptic 保持只读。状态只使用
  `OPEN`、`SCHEDULED`、`RESOLVED` 或 `WONT-FIX FOR CURRENT CLAIM`。

## I0

**Manufactured Nonlinear Eigenvalue Problem Root-and-Correction Prototype。**
历史审查见
[[research/projects/eig-apost/implementation/nep-review|I0 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I0-1 | `IMPORTANT CAVEAT` | 三角形 manufactured NEP 弱化了通用非正规问题中左特征向量敏感性的测试。 | 只限制把 I0 推广成一般 NEP correction 验证；不阻止实际 BIE pipeline。 | 仅当真实 estimator 的 correction quotient 出现异常时，再加一个左右向量非共线的 $2\times2$ 或 $3\times3$ oracle。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I0-2 | `MINOR CAVEAT` | contour 位置利用了解析根知识。 | 不影响 I0 算法单元测试；限制其作为自动 locator benchmark。 | 在真实 root stage 使用只由实轴 locator 产生的预注册 disk。 | `SCHEDULED` |

## I1

**Finite-tail Half-guide Dirichlet-to-Neumann Map。**历史审查见
[[research/projects/eig-apost/implementation/half_guide_review|I1 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I1-1 | `IMPORTANT CAVEAT` | doubling 与 QZ 共享同一 one-cell map，不是独立 physical DtN truth。 | 限制 half-guide accuracy 的独立性陈述；不阻止使用该 map 搜索候选 root。 | 在两个附近的非 Wood 实频率，把高-$j$ finite-tail map 与 QZ limit 及一个更高分辨率 cell map 比较。 | `OPEN` |
| OP-I1-2 | `IMPORTANT CAVEAT` | 尚无严格 saturation 常数或 half-guide map remainder bound。 | 不阻止 empirical estimator；阻止 certified interval 或无条件 reliability claim。 | 在至少三个连续 $j$ levels 记录 map/root shift ratios，并用下一层实际 shift 检查预测。 | `SCHEDULED` |

## I2

**Augmented Boundary Integral Equation and Center Coupling。**历史审查见
[[research/projects/eig-apost/implementation/aug-bie-review|I2 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I2-1 | `IMPORTANT CAVEAT` | variable-speed ellipse 的 density scaling 目前只在 test-local path 验证，production helper 未统一。 | 限制 production-path 复用；不阻止冻结 test-local real-case experiment。 | 在两个空间分辨率上比较 scaled test-local assembly、field traces 和 scattering blocks；只有最终迁回 package 时才改 production。 | `OPEN` |
| OP-I2-2 | `IMPORTANT CAVEAT` | continuous kernel--field equivalence 与 representation injectivity 尚无证明。 | 对工程论文是 spurious-root 风险说明；只有出现近零 algebraic vector 但物理场消失时才升级为 blocker。 | 对候选最小奇异向量记录 center/port field energy、边界 residual 和一层空间 refinement overlap。 | `SCHEDULED` |

## I3

**Root-readiness Proxy Diagnostic and Source-derived Provenance Closure。**当前审查见
[[research/projects/eig-apost/implementation/root_readiness_review#L. Provenance-closure post-run review|I3 review Section L]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I3-1 | `IMPORTANT CAVEAT` | production 调用内部 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍未直接观测。 | 不阻止已通过的 source-derived path；只阻止更强的 runtime internal-array identity claim。 | 若论文需要该强 claim，再增加可选 diagnostic output；否则保持当前措辞。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I3-2 | `IMPORTANT CAVEAT` | provenance-closure 尚未做 MATLAB parity。 | 不阻止下一 Octave 实验；最终工程论文的跨环境复现需补。 | 在冻结源码上用命令行 MATLAB 各跑一次 baseline/repeat，并比较公开 CSV 指标。 | `SCHEDULED` |
| OP-I3-3 | `MINOR CAVEAT` | off-collocation residual 尚无独立冻结阈值，historical projectors 与当前 projectors 有约 $10^{-10}$ 的差异。 | 不影响 provenance verdict；只影响更强的 chart robustness 描述。 | 在 complex-$k$ stage 同时记录 densified off-collocation residual 和 rank/projector spread，不单开理论任务。 | `SCHEDULED` |

## I4

**Full Analytic Complex-Wavenumber Root-readiness。**首轮双椭圆实验的
`REPRODUCIBLE STOP / NO_SCREENED_DIP` 保留为历史负例。当前主模型已按用户决定改为
Fliss 相同周期端与 missing-column geometry；最新 Track A/Track B 结果见
[[research/projects/eig-apost/implementation/i4-fliss|I4 Fliss benchmark]]。最新 sharp-disk
Rayleigh-budget 诊断见
[[research/projects/eig-apost/implementation/i4-rayleigh|I4 Rayleigh budget]]；最新谱提取与
proxy-solver 诊断见
[[research/projects/eig-apost/implementation/i4-extract|I4 spectral extraction closure]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I4-1a | `MINOR CAVEAT` | 历史双椭圆的 29 点 locator 在 $[0.04,0.18]$ 上严格单调下降，没有 screened interior dip。 | 不再阻止当前 Fliss missing-column 主模型；只限制对旧双椭圆 family 的结论。 | 保留原 baseline/repeat，不再为当前项目连续追扫旧区间。 | `WONT-FIX FOR CURRENT MODEL` |
| OP-I4-1b | `MINOR CAVEAT` | 旧 affine/逐模态路径把高阶 transmission 数值降秩解释成模态丢失。新 projective ordered-QZ/doubling 诊断在 canonical $\delta=0.30$ 和 small-clearance $\delta=0.10$ 上通过所有 same-$M$ 门到测试上界 $M=20$；即使 $41\times41$ transmission block 在相对阈值 $10^{-10}$ 下秩仅为 7，deflating subspaces 仍完整可用。 | 旧路径不再阻止当前 projective 路线；$M=20$ 只是 right-censored pass-through，不能称为已知 $M_{\mathrm{stable}}$ 上界。 | 保留 transmission tolerance sweep 为 ledger，不再以 raw rank 或逐模态 pairing 停止 projective path。只有扩展到 $M>20$ 或新参数时才复查 same-$M$ gates。 | `RESOLVED` |
| OP-I4-1c | `IMPORTANT CAVEAT` | Track A 是精确 Fliss smooth Gaussian profile，Track B 是 radius-$0.2$ sharp disk；两者没有同一离散算子或 root identity。用户已选择 sharp-disk missing-column 作为独立 BIE benchmark，Fliss track 只提供尺度和参数参考。 | 不阻止寻找 sharp-disk 自身的 root；阻止把 Track A 的 $\lambda_h=3.460975044$ 当成 sharp-disk root 或 estimator reference。 | sharp-disk 路线必须生成 own locator、root hierarchy 和 reference；只有论文要声称复现 exact Fliss profile 时才实现 model-consistent smooth-profile infinite-domain evaluator。 | `OPEN` |
| OP-I4-1d | `BLOCKER` | 新模型尚无 selected complex-$k$ disk 上的 anchored Rayleigh branch、fixed chart/rank、factor/pole ledger、full-$F$ CR 和完整实际-object negatives。 | 直接阻止 contour count 和 bordered Newton root isolation。 | 只有 OP-I4-1f 与 OP-I4-1e 关闭并得到可解释的 sharp-disk 实轴 locator 后，才冻结一个小 disk 运行完整 analytic readiness。 | `SCHEDULED` |
| OP-I4-1e | `BLOCKER` | 当前双向 M5 的 $44\times44$ $A_{\mathrm{def}}$ 在相对阈值下数值秩仅为 8，normalized singular value 为 $1.18\times10^{-17}$；已实现的 M4/M5 scan 仍调用 legacy affine `solve_modes`，没有接入双向/deflating-subspace bases。 | 即使先修复 port subspace residual，现有 locator matrix 与 scanner 仍可能因 $E,E^{-1}$ 和变量块尺度失衡产生结构性假 dip。 | 对 $A_{\mathrm{def}}$ 做物理块级 row/column equilibration，在预注册非候选点排除秩坍缩；随后把 scanner 实际接到通过门的双向/deflating bases，再运行 bounded scan。 | `OPEN` |
| OP-I4-1f | `BLOCKER` | 旧 Bessel closed form 与 `farfield_extractors` 共用 Rayleigh modal kernel，不能独立认证 qpgreen 谱表示或 sum--integral interchange。新三路径实验已用真 Ewald split 复现 Linton Tables 2--5，且完整 Ewald kernel--boundary integral--wall Fourier 路径与 Rayleigh extractor 的 SLP--D 系数闭合到 $6.10\times10^{-16}$；因此当前参数的 spectral/extractor value path 通过。相反，package MFS 在项目 point、相同 Linton 五点和 SLP--D 上的最大误差分别为 $4.89\times10^{-8}$、$6.01\times10^{-8}$、$4.69\times10^{-8}$；分别只加密 $N_{\mathrm{side}},N_{\mathrm{top}},N_{\mathrm{proxy,edge}},M_{\mathrm{pw}}$ 时变化为 $7.52,5.99,3.72,4.45\times10^{-8}$。默认 `pinv` 路径仍失败；relative $\tau=3\times10^{-16}$ economy-SVD 只在三个 in-sample 点达到 $10^{-12}$，同阈值 `pinv(A,tol)` 反而产生 $5.98\times10^{-5}$。 | 直接阻止 eligible MFS wall reference、certified $M_{\mathrm{trace}}$、完整 upstream-qualified $M_{\mathrm{stable}}$、可解释的 DtN locator 和 root isolation。 | 完全冻结既有 economy-SVD backend/reconstruction，不用 hold-out 调参；先计算本轮两个 off-axis hold-out point values，再只运行一次 $n_{\mathrm{tot}}=128,N_y=256$ authority SLP--D。若 point $2\times10^{-9}$ 和 coefficient $10^{-8}$ 门通过，再做 roundoff-equivalent assembly 与四个 proxy 单轴加密；否则区分 solver path 与 basis/collocation limitation。 | `OPEN` |
| OP-I4-1h | `BLOCKER` | Linton Tables 2--5 只认证 Ewald 函数值；test-local Ewald analytic gradient/Hessian 尚未实现和独立加密。SLP--D 因上游 MFS blocker 未通过，故 SLP--N、DLP--D、DLP--N 按预注册顺序未运行。 | 当前不改变 OP-I4-1f 的首要诊断，但在其关闭后直接阻止完整 wall Cauchy data、$M_{\mathrm{trace}}$ 和 locator。 | 仅在 SLP--D 通过后，从 Ewald real/reciprocal 公式解析求导；分别加密 $a,M_1,M_2,N$，在 separated hold-out pairs 上对 centered finite differences、Helmholtz residual 和 source/target sign/axis mutations。不得用 MFS derivatives 认证 Ewald。 | `SCHEDULED AFTER OP-I4-1f` |
| OP-I4-1g | `IMPORTANT CAVEAT` | $\delta=0.20$、$k=1.8603695988$ 的 low/high pencil 在所有测试 $M$ 上都有两个 neutral pairs；$M=20$ 的 unit-circle gap 约 $3.05\times10^{-9}$，因此 decaying/growing ordered maps 不可用。 | 阻止在该参数点使用 half-guide decaying DtN，也阻止跨 $\delta$ 的统一窗口；不阻止 canonical $\delta=0.30$ 路线，因为其 stable/unstable split 清晰。 | 只有选择 $\delta=0.20$ 作为 root 模型时，才做 projected-band scan 与 $k+\mathrm{i}\eta$ limiting-absorption continuation；当前先避开该 point。 | `SCHEDULED` |
| OP-I4-2 | `IMPORTANT CAVEAT` | Track A 候选仅在 N80 finite strip 上计算；N80/N120 加密的是相邻 band edges，不是 defect eigenpair。 | 不阻止 `I4_FD_CANDIDATE_READY`，但阻止声称 defect eigenvalue 已完成空间收敛。 | 需要增强证据时，只算 strong case 的 N120 八周期尾条带并与 N80 八周期结果比较。 | `SCHEDULED` |
| OP-I4-3 | `IMPORTANT CAVEAT` | smooth-profile contrast continuation 未运行；新 Fliss 证据尚无 baseline/repeat 字节级复现和 MATLAB parity。 | 不阻止当前单点候选身份；限制参数稳健性与跨环境复现主张。 | root path 恢复后再对最小必要配置做一次 unchanged-source repeat 和命令行 MATLAB parity；continuation 只在论文需要时运行。 | `SCHEDULED` |
| OP-I4-4 | `MINOR CAVEAT` | targeted edge check 的四个 $\eta_\theta$ 为零，因为 coarse/fine 子集都包含已知对称 extremizer $\theta=-\pi$。 | 不影响 baseline 全 Brillouin-zone 扫描加 targeted N80/N120 的组合结论；不能把零值单独称为角向误差证明。 | 报告中保持组合证据措辞；不单独追加理论分支。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I4-5 | `IMPORTANT CAVEAT` | bidirectional scaling test 在任意缩放后立即采用同一 port-local 归一化，且 sigma 绝对容差 $10^{-10}$ 远大于被比较的 $10^{-17}$。 | 只验证列归一化代码不依赖 eigenvector scale；不验证 pencil eigenvectors 准确，也不验证 center propagation blocks 的 equilibration。 | 修复 OP-I4-1b 与 OP-I4-1e 时新增 block-balanced matrix 与未平衡矩阵的条件数、秩和 dip 对照。 | `SCHEDULED` |
| OP-I4-6 | `IMPORTANT CAVEAT` | 三路径实验的 Rayleigh retained-row change 为 0，因为 extractor 对每个 $m$ 独立构造；扩大输出 $M$ 不改变已存在的 row。 | 不影响 Ewald--Rayleigh 对当前 SLP--D 系数的条件通过，但阻止把 retained-row equality 解释成 Rayleigh tail convergence 或 $M_{\mathrm{trace}}$ 认证。 | MFS SLP--D 闭合后，用 Ewald full wall field 分别测 $M=12,24,48$ 的重构误差和 omitted coefficient energy；不要再用 retained-row identity 代替 tail test。 | `SCHEDULED` |

## I5

**Actual Root Isolation and Simple-root Qualification。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I5-1 | `BLOCKER` | 尚无 count-one contour、converged bordered Newton root、simple-root derivative 和跨层匹配。 | 阻止把实轴小奇异值位置称为 eigenvalue，也阻止计算有意义的后验 correction。 | I4 通过后，只对一个预注册 disk 做 contour count、Newton 和相邻两个 $j$ levels 的 root matching。 | `OPEN` |

## I6

**Empirical A Posteriori Correction and Effectivity。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I6-1 | `BLOCKER` | 尚无 matched root hierarchy、resolved reference root 和 estimator effectivity。 | 阻止工程论文声称 estimator 能预测真实 eigenvalue error。 | 对同一 mode 计算至少三个 matched levels，以最高分辨率 reference 比较 predicted shift、actual next-level shift 和 effectivity。 | `OPEN` |
| OP-I6-2 | `IMPORTANT CAVEAT` | 尚无严格 saturation 与 correction-remainder bound。 | 不阻止 empirical estimator；只限制其被称为 certified 或 guaranteed。 | 报告 observed ratios、reference uncertainty 和失败案例，并把结论明确标为 empirical。 | `OPEN` |

## I7

**Independent Real-case Validation。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I7-1 | `IMPORTANT CAVEAT` | 单一参数/单一 mode 可能不足以说明工程稳健性，独立 reference 与 MATLAB parity 仍缺。 | 限制论文的可推广范围，但不必阻止第一份真实案例。 | 在第一案例跑通后增加一个附近参数或第二 mode，并执行一组 MATLAB parity 与独立高分辨率 reference。 | `OPEN` |
