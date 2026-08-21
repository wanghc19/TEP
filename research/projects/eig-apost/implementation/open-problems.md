# Eigenvalue a posteriori open-problem ledger

本文件集中维护 `eig-apost` 各实现阶段仍与当前目标有关的问题。项目只有两个最终目标：
提出 continuous physical eigenvalue candidate；估计该 candidate 到真实连续特征值的误差，
并研究可计算上界。首个工程目标是带 independent-truth validation 的 empirical estimator；
严格上界是后续明确研究方向。第一层存在性需要 residual/field norm enclosure、numerical
enclosure、当前 continuous projected essential gap 与预注册分辨率；只有指定 mode 的升级才
另需 target isolation。条件未建立前不得把相应结论伪装成已完成的 certification。

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

## M0

**Continuous DtN/BIE Method Reconstruction。**2026-08-11 起新路线 I1 受门控推进。离散
$A_{\mathrm{def}}$ 设计已通过两项独立审查，I1.2 manufactured、$M=5,8$ low-order 和
direct $M=48$ static QZ/graph/DtN/$A_{\mathrm{def}}$ 链也已通过。经验型 I1.3 已完成
real-$k$ 连续性、$M=12\to24\to48$ candidate reconnaissance 和独立 width-driven 局部
加密，记录 fixed-$M=48$ 离散候选 $k=1.8327703475952146$、
$q=8.3200886232193094\times10^{-8}$。新版 15 层实验的 167 个 hard gates 全部通过，
最终三个 $q$ 值仍明显变化，不是 $10^{-3}$ 平台。旧 immediate-neighbor prominence
实验的停止 verdict 保留为历史设计负例；OP-CI1-7 已由 v2 关闭。有限差分的
graph-basis mutation 门仍未过，production derivative 仍不可用。I1.4 已在冻结
fixed-$M=48$ 小复圆盘上达到 sampled discrete readiness；I2.1 又在同一圆盘完成条件性
factor-aware count one。它们不关闭 continuous blockers，也不允许 root 坐标或真实
eigenvalue 声明。现行方法见
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]；旧路线见
[[research/projects/eig-apost/phase4-report/legacy-tail.tex|superseded finite-tail formulation]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-M0-1 | `BLOCKER` | 当前 sharp-disk continuous operator 的 projected essential gap 尚未形成认证合同：需核对 fixed-$\beta$ coefficient、尺度、本质谱定义与 gap 的可靠内边缘。 | 只阻止把 reliable residual interval 升级为“gap 内至少存在一个连续离散特征值”；不阻止 I3.1 计算 residual 或 I3.2 经验验证。finite QZ gap、smooth-profile gap 和 I2.1 count 均不能替代。 | 针对当前模型建立 $G_\lambda\cap\sigma_{\mathrm{ess}}(A)=\varnothing$ 及认证 gap 边缘，并在 design 中预注册绝对和 gap-relative 分辨率。 | `OPEN` |
| OP-M0-1a | `IMPORTANT CAVEAT` | gap 内可能有多个连续离散特征值；尚无 unique-target count/isolation。 | 只阻止把第一层存在区间命名为指定 $k_*$，或声称 multiplicity one；不阻止存在性、分辨率或不指定 mode 的集合距离上界。 | 仅当后续必须跟踪特定 mode 时，再证明 $I_h^\lambda\cap\sigma(A)=\{\lambda_*\}$；若还需一重性，再核验谱投影秩。 | `OPEN` |
| OP-M0-2 | `IMPORTANT CAVEAT` | physical variational pencil $\mathcal F(k)$ 已先于截断定义；但 continuous BIE schema 的 representation completeness、injectivity、kernel--field equivalence、Fredholm index 和 adjoint pairing 尚未证明。 | 阻止把任意有限维近核无条件等同于真实 guided mode，也限制整个 BIE 方法的完备性；不阻止对一个实际重构、非零且 conforming 的物理场计算 continuous residual。若 residual 直接作用于该场，density injectivity 不是其前置门。 | I3.1 先冻结 deterministic field reconstruction、nonzero/form-conformity 和 residual components；完整 BIE kernel--field 双向对应只在方法完备性或矩阵-kernel claim 需要时另证。 | `OPEN` |
| OP-M0-3 | `IMPORTANT CAVEAT` | continuous one-cell relation 到 BIE/Fourier generalized pencil 的 primal/adjoint consistency 仍未证明，production `DIF/sep` backend 和 analytic graph tangent 也未资格化。有限维设计已冻结 original/reversed 两次 QZ、regular infinite pair、seed-cluster continuation、absolute chart margin、fallback 和 $A_{\mathrm{def}}^{D/G}$；既有 sampled checks 已通过，但 FD graph-basis mutation 仍失败。 | 不阻止 candidate，也不阻止直接作用于 continuous field 的 residual indicator；后者不消费 matrix derivative。它只阻止 derivative-based finite correction、完整离散谱收敛和依赖该 tangent 的 theorem-level claim。 | production derivative、adjoint transport 和 `DIF/sep` 仅在 OPTIONAL finite correction 或未来具体公式实际需要时资格化。 | `OPEN` |
| OP-M0-4 | `IMPORTANT CAVEAT` | 原目标 $\|\Lambda-E_M\Lambda_{h,M}Q_M\|_{H^{1/2}\to H^{-1/2}}\to0$ 对一阶非紧 DtN 和有限秩 lift 通常不可能。projected consistency、principal-symbol subtraction 或 regular Galerkin/graph convergence 尚未选定并证明。 | 阻止把两层矩阵差解释为 continuous operator error，也阻止完整离散谱收敛定理；不阻止对一个 conforming reconstructed field 直接评价 continuous residual。若使用 OPTIONAL exact-DtN center residual，则相应 DtN difference 与 outgoing lifting 必须显式控制。 | 中心空列 strong-residual baseline 已完成但受固定单胞 cutoff 分辨率限制；下一步优先 lead-aware conforming reconstruction 或 weak residual。只有具体路线实际使用 center DtN、跨层 operator comparison 或离散谱收敛 claim 时，才关闭相应 projected consistency/transport。 | `OPEN` |
| OP-M0-5 | `MINOR CAVEAT` | 相邻层 projected difference 只有 next-level correction 含义；独立 saturation 常数和 correction remainder 尚无来源或证明。 | 只限制 OPTIONAL finite correction 的 remaining-error/effectivity 解释；不阻止 continuous-residual estimator 或其 residual-based upper-bound route。 | 仅在再次启用 finite correction 时寻找 saturation/remainder；observed ratios 不能单独升级为证明。 | `OPEN` |
| OP-M0-6 | `MINOR CAVEAT` | 旧“有限多个 cells + 远端闭合 + doubling”曾被放在主方法位置。 | 双重方法权威会使真实谱对象和 estimator 含义漂移。 | 已完整归档为 legacy，并在当前 method/STATUS/README 中降为 cross-check、reference sequence 或 tail diagnostic。 | `RESOLVED` |

## Current route

当前新路线的正式项目级编号为 I1--I3；I4 只保留 OPTIONAL 泛化验证方向。为避免与历史
I1--I4 ledger ID 冲突，当前问题使用
`OP-CI*` 前缀；旧 ID 只作历史引用。机械映射为：`OP-I4-1e -> OP-CI1-1`、
`OP-I4-1d -> OP-CI1-2`、`OP-I5-1 -> OP-CI2-1`、`OP-I6-1/2 -> OP-CI3-1/2`、
`OP-I7-1 -> OP-CI4-1`。当前阶段语义以本节和
[[research/projects/eig-apost/implementation/ROADMAP|ROADMAP]] 为准，不把新编号写回历史实验。

### Current I1

**Discrete Operator Readiness。**当前设计与审查见
[[research/projects/eig-apost/implementation/i1/design|I1 design]] 和
[[research/projects/eig-apost/implementation/i1/review|I1 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-CI1-1 | `BLOCKER` | `test/i1/hg-adef/` 已在 MATLAB `lsqminnorm` 下直接生成 $M=48$、$K=97$ coarse/fine maps；block/action、original/reversed QZ、stable/Cauchy projectors、代数 Dirichlet chart、DtN action 和 $A_{\mathrm{def}}^{D/G}$ Schur 门全部通过。四个 pass 均为 97 stable / 97 unstable、0 neutral / 0 indeterminate，最大 QZ residual 为 $5.25\times10^{-15}$。 | 原共同 production trace 缺口已按当前经验型目标关闭；不再阻止 I1.2 static exit 或经验型 I1.3。该结果本身仍不授权 locator/root。 | 在 I1.3 的最小 real-$k$ stencil 上复用同一计数、projector 和 algebraic-chart availability 门，不从单点外推连续性。 | `RESOLVED` |
| OP-CI1-2 | `BLOCKER` | 围绕 $k=1.8327703475952146$、$r_0=3.8146972647368216\times10^{-7}$ 的 I1.4 sampled disk 已完成 anchored Rayleigh branch、seed-cluster continuation、fixed chart/rank、factor ledger、loop closure 和 full-$F$ CR。V4 的 82 node、820 factor、164 branch、164 QZ、8 closure、36 CR 与 6 CR-negative rows 全通过；V5 保留 V4 failure 并以可辨识非对称 assembly oracle 闭合唯一因当前物理对称而不适用的 transmission swap。 | 原 complex-disk readiness blocker 已关闭；不再阻止另行预注册的经验型 I2 isolation。它仍不证明无 unsampled pole、连续谱逼近、root 或 eigenvalue。 | I2 在同一冻结模型、frame、chart 和 factor gates 下先做 derivative-free contour/count，再比较 coarse/fine isolated candidates。 | `RESOLVED` |
| OP-CI1-3 | `IMPORTANT CAVEAT` | direct $M=48$ input 与 v2 full 已记录 MATLAB `lsqminnorm`、Git、runner/config/plan/package hashes 和 zero-fallback/rank fields；当前全部 provenance hashes 一致，源码也未发现 `pinv` 或 solver switch。但 zero fields 仍主要是 generator self-attestation，v2 pilot token 也未绑定全部下层 dependency hashes。 | 不阻止当前 I1.3；限制对 solver path 和未来 stale-pilot invalidation 的更强审计声明。 | 任一记录依赖改变后必须重跑 pilot；若候选对 solver 细节敏感，再加 runtime call ledger 或受控 shadow negative。 | `SCHEDULED` |
| OP-CI1-4 | `MINOR CAVEAT` | $M=48$ regular-infinite count 在 real-axis coarse/fine pass 间为 87--88，但始终位于 97 维 unstable complement。I1.4 sampled disk 的全部 QZ rows 均为 97 stable / 97 unstable、0 neutral / 0 indeterminate，最小 anchored overlap 为 $0.9999999999999398$，未见 selected subspace 不连续。 | 不阻止当前 candidate 或 I2 empirical isolation；只限制对 complementary infinite classification 的定量描述。 | I2 继续逐点记录 infinity/count/overlap；只有 selected cluster 不连续时再升级。 | `RESOLVED` |
| OP-CI1-5 | `IMPORTANT CAVEAT` | I1.4 未形成或施加 production generalized-Sylvester separation operator；chart 只认证 sampled algebraic margin/condition/solve，不是 perturbation-certified。 | 不阻止 sampled fixed-$M=48$ readiness 或下一项 empirical isolation；阻止 theorem-level graph/DtN conditioning bound、certified root 和无条件 estimator。 | I2 继续使用 count/overlap/chart continuity 门；只有出现 branch ambiguity 或论文 claim 升级时，才实现 structured `xTGSEN/xTGSYL` condition estimate。 | `OPEN` |
| OP-CI1-6 | `IMPORTANT CAVEAT` | I1.3 的中心差分在 $h=0.000625$ 达到 $9.75\times10^{-7}$ 且二阶比为 $0.250$，coarse/fine $A_{\mathrm{def}}$/DtN derivative action 约为 $3.26\times10^{-11}$/$6.87\times10^{-11}$；但 graph-basis mutation 后变化为 $3.65\times10^{-11}>10^{-12}$，故 `FD_DERIVATIVE_READY=false`。 | 本项本身不阻止逐点 candidate 或 readiness 设计；阻止把该差分作为 production $A_{\mathrm{def}}'$，并阻止 Newton、simple-root pairing、correction 和 estimator 使用。 | 不再盲目减小 $h$；在 analytic/anchored frame 就绪后预注册 roundoff-aware mutation oracle，或以独立 complex-step/analytic tangent 作决定性比较。 | `OPEN` |
| OP-CI1-7 | `BLOCKER` | 历史 v1 bounded zoom 因 shrinking-neighbor prominence $1.055620<1.25$ 停止。独立预注册 v2 明确把 prominence 降为非停机诊断，以当前区间宽度作唯一正常终点；15 层、33 个唯一 $k$ 点和 167 个 hard gates 全部通过，在 $7.6294\times10^{-7}$ 宽度处得到 $k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$。 | 原 zoom 实验设计 blocker 已关闭；v1 verdict 保持历史有效。该结果不单独授权 root/eigenvalue 声明。 | 若参数、模型或选区规则改变，重新预注册；当前候选的 complex-$k$ readiness 由已关闭的 OP-CI1-2 管理。 | `RESOLVED` |
| OP-CI1-8 | `IMPORTANT CAVEAT` | homogeneous 左右对称模型使 physical $T_{RL}$ 与 $T_{LR}$ 的相对差仅为 $1.25\times10^{-14}$，无法用 live physical swap 动态识别标签。V5 的非对称 $K=3$ oracle 认证 assembly contract，但不是非对称物理提取测试。 | 不影响当前对称候选，因为交换不可分辨 blocks 不能制造 dip；若将来改变为非对称 geometry，则限制 transmission-label 解释。 | 第一次使用非对称物理模型时，在 live extraction-to-assembly 路径重跑 transmission-swap negative。 | `OPEN` |
| OP-CI1-9 | `MINOR CAVEAT` | V5 校验了 V4 的 31 个 sources 与 7 个 artifacts，但冻结输出未自带 `plan-v5.md`、`run_v5.m` 的 self-manifest。当前 SHA-256 已记录于实验 README，V5 不称 fully self-source-closed。 | 不改变代数结果或 I1.4 conditional verdict；限制 V5 自身 provenance 强度。 | 下一次无需重跑 V4，只做 append-only provenance-only closure，并让 runner/plan hash 进入自身 manifest。 | `OPEN` |

### Current I2

**Candidate Credibility and Cross-discretization Drift。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-CI2-1 | `IMPORTANT CAVEAT` | I2.3 的 `drift-a1` 已在 $n_{\mathrm{tot}}=160,208,256$ 得到三层有效 saved candidate；`m-drift-a2` 又在固定 $n_{\mathrm{tot}}=160$ 的 $M=32,40,48$ 上得到第二条三层序列。两条轴的最低 residual/factor/field/boundary/repeat 门通过，相邻层均为 `SAME_MODE`，且 $\Delta^{\mathrm{cand}}=0$。潜在连续-$k$ score minimizer 未精确计算；terminal half-width 只作 search-resolution diagnostic。 | I2 已按 `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE` 收口，该 caveat 不阻止 I3 开始设计；它仅阻止把 observed candidate equality 升级为 minimizer/root 零漂移、收敛阶或误差界。 | I3 使用两条 saved candidate sequence 并识别各轴零 observed shift 的信息边界；只有 estimator 实际需要 sub-grid minimizer 或非零 level shift 时，才另行设计定位或其他独立 refinement。不得重跑同 tag 或追溯改写 artifact。 | `OPEN` |
| OP-CI2-2 | `IMPORTANT CAVEAT` | I2.1 依赖 64 点 $k$、32 点 $\zeta$、双向 sampled Neumann guards 和嵌套 winding，而非连续边界 supremum 或严格闭盘无 pole 定理；未采样极窄 excursion 仍不能逻辑排除。 | 不阻止当前 conditional empirical finite-dimensional count one 或 I2.2；阻止把 I2.1 称为 certified pole-free theorem。 | I2.2 继续 fail-close 监测同一 branch/QZ/chart/factors；只有出现 nested inconsistency、弱 separation、近阈 guard 或 claim 升级时，才另行审查 $N_k=128$ 或严格界。 | `OPEN` |
| OP-CI2-3 | `IMPORTANT CAVEAT` | I2.1 proxy reduced `rcond` 与 Riesz range-difference 虽通过但余量有限；M-axis 中最紧 `proxy_reduced` rcond 为 $1.0481727489\times10^{-8}$，只比 $10^{-8}$ 门高约 $4.8\%$。 | 不撤销 I2.1 或两条 I2.3 hierarchy；意味着后续离散轴不能继承 factor readiness。只有直接相关 factor failure 才阻止相应 candidate 的漂移解释。 | 在每个新冻结阶数复查最低必要的 factor/conditioning；不追加完整 contour 或 projector 理论。 | `OPEN` |
| OP-CI2-4 | `IMPORTANT CAVEAT` | 历史 I2.2 preflight 的 exact finite Lagrangian/Hermitian 和 whole-interval proof 未闭合，故 raw $H$ 的 mathematical inertia 为 `NaN/UNAVAILABLE`。 | 继续阻止 strict inertia theorem、finite-real-zero claim 和手工对称化后的 root 解释；不阻止把明确标注的 endpoint sign-count/inertia-like jump 当作 candidate 可信度诊断。 | 停止扩张 exact finite-structure 证明。I2.2 只报告对象、structure defect、unresolved band 和 jump/no-jump；严格 inertia 证明列为 OPTIONAL。 | `WONT-FIX FOR CURRENT CLAIM` |

### Current I3

**Continuous Eigenvalue Error Estimation and Upper-bound Feasibility。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-CI3-1 | `BLOCKER` | I3.1 已得到两个有效负结果：`center-a1` 的 ratio $22.43882099031153$ 由固定单胞 cutoff 主导；`lead-a3` 虽通过 finite input、density representation 和 propagation，但固定 fit 的 $J=4/8$ holdout error 为约 $4.522421/5.138028$，远高于 $0.20$，故在 `CONFORMING_RECONSTRUCTION_UNRESOLVED` 停止。training/holdout targets 到圆周只有约 source-panel arc scale 的 $0.86\%/1.08\%$，而 direct close layer-potential evaluation 未资格化，所以当前不能区分近奇异评价与 basis/metric 的贡献。 | 阻止形成 qualified whole-waveguide trial、continuous residual estimator candidate 和 I3.2 输入；不撤销 finite input、density/sign/scaling、frozen-$Z$ propagation 的通过，也不撤销两个负结果。center/Gram/quadrature/tail/residual ratio 在 `lead-a3` 中均为 `NOT_REACHED`。finite zero、common matrix transport 和 production derivative 仍不是主线 blocker。 | 在设计新 attempt 前，先以独立、低成本、可证伪的检查区分 close-evaluation quality 与 fixed reconstruction space/metric；据结果另行冻结修订或替代 reconstruction。不得结果后调 basis/grid/阈值，不自动启动 `lead-a4`。 | `OPEN` |
| OP-CI3-2 | `BLOCKER` | 尚无 I3.3 第一层可计算存在区间所需的 certified residual dual-norm upper bound、field-norm lower bound、numerical enclosure、continuous projected-gap containment 和预注册 absolute/gap-relative resolution。 | 这是 gap 内存在性与分辨率级 upper-bound claim 的 blocker，不阻止 I3.1 形成 estimator candidate，也不阻止 I3.2 形成 independently validated empirical estimator。unique-target isolation 只阻止可选指定-mode升级。 | I3.3 只使用可计算且经证明覆盖的 norm/enclosure/gap contract 研究 $U_h$，并在看结果前冻结分辨率；一般 empirical reference uncertainty 不能直接充当上界项。若条件不成立，正式输出 `UPPER_BOUND_UNAVAILABLE` 或 `EXISTS_BUT_RESOLUTION_INSUFFICIENT`。 | `OPEN` |

### Current I4

**OPTIONAL Independent Validation。**

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-CI4-1 | `IMPORTANT CAVEAT` | 单一参数/单一 mode 可能不足以说明可推广性。I3 所需的 independent truth reference 已并入主线；这里仅保留第二参数、第二 mode、MATLAB parity 和跨模型稳健性。 | 限制推广范围，但不阻止第一 candidate 的 error estimator 或上界可行性 verdict。 | 第一案例和 I3 跑通后，按论文 claim 选择最小扩展；不得提前形成正式 I4 blocker。 | `SCHEDULED` |

## Historical implementation stages

以下 I0--I4 标题、问题 ID 和实验语义均沿用旧路线编号，供归档材料稳定引用；它们不覆盖
上面的 current-route I1--I4。

## I0

**Manufactured Nonlinear Eigenvalue Problem Root-and-Correction Prototype。**
历史审查见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i0-manufactured/nep-review|I0 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I0-1 | `IMPORTANT CAVEAT` | 三角形 manufactured NEP 弱化了通用非正规问题中左特征向量敏感性的测试。 | 只限制把 I0 推广成一般 NEP correction 验证；不阻止实际 BIE pipeline。 | 仅当真实 estimator 的 correction quotient 出现异常时，再加一个左右向量非共线的 $2\times2$ 或 $3\times3$ oracle。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I0-2 | `MINOR CAVEAT` | contour 位置利用了解析根知识。 | 不影响 I0 算法单元测试；限制其作为自动 locator benchmark。 | 在真实 root stage 使用只由实轴 locator 产生的预注册 disk。 | `SCHEDULED` |

## I1

**Legacy Finite-tail Half-guide-map Algebra。**历史审查见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i1-finite-tail/half_guide_review|I1 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I1-1 | `IMPORTANT CAVEAT` | doubling 与 QZ 共享同一 one-cell map，不是独立 physical DtN truth。 | 限制 legacy infinity-treatment cross-check 的独立性；该 map 不再授权搜索当前 root。 | 只有把 finite-tail 作为可选 tail diagnostic 时，才在两个非 Wood 实频率与 QZ limit 及更高分辨率 cell map 比较。 | `SCHEDULED` |
| OP-I1-2 | `IMPORTANT CAVEAT` | 尚无严格 finite-tail saturation 常数或 remainder bound。 | 不阻止 continuous DtN 主路线；阻止把 legacy level difference 称为 remaining-error estimator。 | 只有论文保留 tail diagnostic 时才记录至少三个 $j$ levels；否则由 OP-M0-5 统一管理 estimator 限制。 | `SCHEDULED` |

## I2

**Augmented Boundary Integral Equation and Center Coupling。**历史审查见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i2-aug-bie/aug-bie-review|I2 review]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I2-1 | `IMPORTANT CAVEAT` | variable-speed ellipse 的 density scaling 目前只在 test-local path 验证，production helper 未统一。 | 限制 production-path 复用；不阻止冻结 test-local real-case experiment。 | 在两个空间分辨率上比较 scaled test-local assembly、field traces 和 scattering blocks；只有最终迁回 package 时才改 production。 | `OPEN` |
| OP-I2-2 | `IMPORTANT CAVEAT` | continuous kernel--field equivalence 与 representation injectivity 尚无证明。 | 对工程论文是 spurious-root 风险说明；只有出现近零 algebraic vector 但物理场消失时才升级为 blocker。 | 对候选最小奇异向量记录 center/port field energy、边界 residual 和一层空间 refinement overlap。 | `SCHEDULED` |

## I3

**Root-readiness Proxy Diagnostic and Source-derived Provenance Closure。**当前审查见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i3-provenance/root_readiness_review#L. Provenance-closure post-run review|I3 review Section L]]。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I3-1 | `IMPORTANT CAVEAT` | production 调用内部 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍未直接观测。 | 不阻止已通过的 source-derived path；只阻止更强的 runtime internal-array identity claim。 | 若论文需要该强 claim，再增加可选 diagnostic output；否则保持当前措辞。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I3-2 | `IMPORTANT CAVEAT` | provenance-closure 尚未做 MATLAB parity。 | 不阻止下一 Octave 实验；最终工程论文的跨环境复现需补。 | 在冻结源码上用命令行 MATLAB 各跑一次 baseline/repeat，并比较公开 CSV 指标。 | `SCHEDULED` |
| OP-I3-3 | `MINOR CAVEAT` | off-collocation residual 尚无独立冻结阈值，historical projectors 与当前 projectors 有约 $10^{-10}$ 的差异。 | 不影响 provenance verdict；只影响更强的 chart robustness 描述。 | 在 complex-$k$ stage 同时记录 densified off-collocation residual 和 rank/projector spread，不单开理论任务。 | `SCHEDULED` |

## I4

**Full Analytic Complex-Wavenumber Root-readiness。**首轮双椭圆实验的
`REPRODUCIBLE STOP / NO_SCREENED_DIP` 保留为历史负例。当前主模型已按用户决定改为
Fliss 相同周期端与 missing-column geometry；最新 Track A/Track B 结果见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-fliss|I4 Fliss benchmark]]。最新 sharp-disk
Rayleigh-budget 诊断见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-rayleigh|I4 Rayleigh budget]]；最新谱提取与
proxy-solver 诊断见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-extract|I4 spectral extraction closure]]。
该历史 I4 数值路线因 M0 方法重构暂停；下表保留既有数值证据和历史编号，不构成继续
当前 I1 的 $A_{\mathrm{def}}$/locator 授权。

| ID | Category | Open problem | Blocking scope | Cheapest next check | Status |
|---|---|---|---|---|---|
| OP-I4-1a | `MINOR CAVEAT` | 历史双椭圆的 29 点 locator 在 $[0.04,0.18]$ 上严格单调下降，没有 screened interior dip。 | 不再阻止当前 Fliss missing-column 主模型；只限制对旧双椭圆 family 的结论。 | 保留原 baseline/repeat，不再为当前项目连续追扫旧区间。 | `WONT-FIX FOR CURRENT MODEL` |
| OP-I4-1b | `MINOR CAVEAT` | 旧 affine/逐模态路径把高阶 transmission 数值降秩解释成模态丢失。新 projective ordered-QZ/doubling 诊断在 canonical $\delta=0.30$ 和 small-clearance $\delta=0.10$ 上通过所有 same-$M$ 门到测试上界 $M=20$；即使 $41\times41$ transmission block 在相对阈值 $10^{-10}$ 下秩仅为 7，deflating subspaces 仍完整可用。 | 旧路径不再阻止当前 projective 路线；$M=20$ 只是 right-censored pass-through，不能称为已知 $M_{\mathrm{stable}}$ 上界。 | 保留 transmission tolerance sweep 为 ledger，不再以 raw rank 或逐模态 pairing 停止 projective path。只有扩展到 $M>20$ 或新参数时才复查 same-$M$ gates。 | `RESOLVED` |
| OP-I4-1c | `IMPORTANT CAVEAT` | Track A 是精确 Fliss smooth Gaussian profile，Track B 是 radius-$0.2$ sharp disk；两者没有同一离散算子或 root identity。用户已选择 sharp-disk missing-column 作为独立 BIE benchmark，Fliss track 只提供尺度和参数参考。 | 不阻止寻找 sharp-disk 自身的 root；阻止把 Track A 的 $\lambda_h=3.460975044$ 当成 sharp-disk root 或 estimator reference。 | sharp-disk 路线必须生成 own locator、root hierarchy 和 reference；只有论文要声称复现 exact Fliss profile 时才实现 model-consistent smooth-profile infinite-domain evaluator。 | `OPEN` |
| OP-I4-1f | `BLOCKER` | 历史 $p/d=0.7$ 把 proxy 竖边放到 $|x|=1.2d$，越过 $G_{\mathrm{QP}}-G_0$ 最近镜像奇点 $|x|=d$，并产生 SLP--N 的 $10^{-8}$ 级单轴变化。归档实验 `test/archive/legacy-route-v1/i4-proxy-rule/` 在不修改 package、固定 MATLAB `lsqminnorm` 和唯一预注册 $p/d=0.2$ 后重跑：SLP--N 的 E--P/P--R 最大误差为 $3.42\times10^{-14}$/$3.47\times10^{-14}$，Nedge/Nside/Ntop/$M_{\mathrm{pw}}$ self 分别为 $4.14\times10^{-14}$、$2.12\times10^{-14}$、$3.03\times10^{-14}$、$1.61\times10^{-13}$；同一配置的 SLP--D 也通过。 | 原 SLP--N sequential blocker 已关闭；这只认证当前几何、频率、两密度与 SLP--D/N，不认证 DLP、$M_{\mathrm{trace}}$、DtN 或 root。 | 保留奇点感知规则 $0<p<d/2$ 和当前 $p/d=0.2$ 的条件性范围；下一步只运行 DLP--D 专项。package proxy 列表重复左下角并缺失右上角，故 rank/edge-DFT tail 仅作非门诊断，最终若修改 package 再单独回归。 | `RESOLVED` |
| OP-I4-1h | `BLOCKER` | 归档实验 `test/archive/legacy-route-v1/i4-dlp-trace/` 在共同 $p/d=0.2$、public MATLAB `lsqminnorm` 下按 DLP--D、DLP--N 顺序通过。DLP--D/DLP--N 三路径最大 coefficient 误差为 $1.39\times10^{-14}$/$1.19\times10^{-13}$；DLP--N 四轴 wall self 最坏为 $1.40\times10^{-13}$。三点 Hessian Ewald 误差最坏为 $5.41\times10^{-14}$，mixed/source-target FD 最坏为 $5.58\times10^{-10}$，五个预期 rank 全部复现。 | 历史 $p/d=0.7$ Hessian/solver spread 不再阻止当前 $p/d=0.2$ DLP Cauchy-data；这只认证当前参数、两制造密度和 public solver，不是任意参数的 rank theorem。 | 保持当前 solver/proxy 哈希与顺序门；参数、geometry 或 solver 变化时重跑 point/self 和 DLP wall，禁止把本结果外推。 | `RESOLVED` |
| OP-I4-1g | `IMPORTANT CAVEAT` | $\delta=0.20$、$k=1.8603695988$ 的 low/high pencil 在所有测试 $M$ 上都有两个 neutral pairs；$M=20$ 的 unit-circle gap 约 $3.05\times10^{-9}$，因此 decaying/growing ordered maps 不可用。 | 阻止在该参数点使用 half-guide decaying DtN，也阻止跨 $\delta$ 的统一窗口；不阻止 canonical $\delta=0.30$ 路线，因为其 stable/unstable split 清晰。 | 只有选择 $\delta=0.20$ 作为 root 模型时，才做 projected-band scan 与 $k+\mathrm{i}\eta$ limiting-absorption continuation；当前先避开该 point。 | `SCHEDULED` |
| OP-I4-2 | `IMPORTANT CAVEAT` | Track A 候选仅在 N80 finite strip 上计算；N80/N120 加密的是相邻 band edges，不是 defect eigenpair。 | 不阻止 `I4_FD_CANDIDATE_READY`，但阻止声称 defect eigenvalue 已完成空间收敛。 | 需要增强证据时，只算 strong case 的 N120 八周期尾条带并与 N80 八周期结果比较。 | `SCHEDULED` |
| OP-I4-3 | `IMPORTANT CAVEAT` | smooth-profile contrast continuation 未运行；新 Fliss 证据尚无 baseline/repeat 字节级复现和 MATLAB parity。 | 不阻止当前单点候选身份；限制参数稳健性与跨环境复现主张。 | root path 恢复后再对最小必要配置做一次 unchanged-source repeat 和命令行 MATLAB parity；continuation 只在论文需要时运行。 | `SCHEDULED` |
| OP-I4-4 | `MINOR CAVEAT` | targeted edge check 的四个 $\eta_\theta$ 为零，因为 coarse/fine 子集都包含已知对称 extremizer $\theta=-\pi$。 | 不影响 baseline 全 Brillouin-zone 扫描加 targeted N80/N120 的组合结论；不能把零值单独称为角向误差证明。 | 报告中保持组合证据措辞；不单独追加理论分支。 | `WONT-FIX FOR CURRENT CLAIM` |
| OP-I4-5 | `IMPORTANT CAVEAT` | bidirectional scaling test 在任意缩放后立即采用同一 port-local 归一化，且 sigma 绝对容差 $10^{-10}$ 远大于被比较的 $10^{-17}$。 | 只验证列归一化代码不依赖 eigenvector scale；不验证 pencil eigenvectors 准确，也不验证 center propagation blocks 的 equilibration。 | 修复 OP-I4-1b 与 OP-I4-1e 时新增 block-balanced matrix 与未平衡矩阵的条件数、秩和 dip 对照。 | `SCHEDULED` |
| OP-I4-6 | `IMPORTANT CAVEAT` | 新 DLP/trace canonical 保存四个 SLP/DLP actions 的完整墙场，预冻结 $M\in\{12,24,48,64,96\}$，并用半网格直接 E/P 墙场而不是 retained-row invariance 认证 $M_{\mathrm{trace}}=48$。最坏半网格重构误差、omitted maximum 和 omitted energy 为 $7.08\times10^{-12}$、$1.11\times10^{-13}$、$5.00\times10^{-13}$；$48\to64\to96$ 变化也通过。 | 原 retained-row 假认证风险已关闭；当前结论仍只是 $M_{\mathrm{ref}}=96$、$N_y=512$、两制造密度的有限数值 screen，不能外推为无限尾定理或所有 BIE 解密度的统一 $M_{\mathrm{trace}}$。 | 在实际 solved density 与相邻 BIE/port levels 上复用同一重构/omitted-energy ledger；若参数或 wall clearance 改变则重新认证。 | `RESOLVED` |
| OP-I4-7 | `IMPORTANT CAVEAT` | 本次决定性设计按用户冻结只重跑 Nedge/Nside/Ntop/$M_{\mathrm{pw}}$ 四个 package 单轴与半网格 trace；没有再次运行额外 $n_{\mathrm{tot}}=128\to256$、$N_y=256\to512$ 和 Ewald wall truncation ladders。 | 不阻止当前 manufactured DLP/trace closure：解析 Ewald point derivative ladder 已独立通过，三路径误差与半网格重构比门低三到五个数量级；但限制对 boundary/wall quadrature 与 Ewald wall truncation 的新 artifact-level 完备性表述。 | 在真实 solved density 首次进入 DtN 前，把 $n_{\mathrm{tot}}/N_y$ 相邻 level 变化写入同一 action ledger；只有观察到接近 $2\times10^{-9}$ 时才重跑 Ewald wall axes。 | `SCHEDULED` |
| OP-I4-8 | `MINOR CAVEAT` | pilot 的首次 source-sign 控制发现 `qpgreen_mfs_pairmat` 在“一 target、多 source 且全部 `idx_in`”的行形 logical-indexing edge case 中返回错误的 source sweep；逐 source 标量调用恢复到 $3.66\times10^{-11}$ 并通过。wall 路径使用 512 targets、256 sources，不触发该形状。 | 不影响当前 wall/DLP/trace 结论，但限制 public pairmat 对任意 `nt=1,ns>1` 输入形状的接口主张。package 按本阶段约束未修改。 | 获准修改 package 时新增 `nt=1,ns>1` 与 `nt>1,ns=1` 回归并修正 `T_in` 形状；此前 test source sweep 必须逐 source 调用。 | `SCHEDULED` |
