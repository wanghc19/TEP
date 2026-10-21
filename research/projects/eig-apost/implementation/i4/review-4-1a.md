# I4.1a 独立 FEM supercell reference 审查

状态：`§15 DESIGN REVIEW COMPLETE / PASS WITH CONDITIONS / §Q HISTORY PRESERVED / ENGINEER BOUNDED REPAIR AUTHORIZED / DIAGNOSTIC AND RUN-005 NOT AUTHORIZED`

审查对象：[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]]。
本文件由同一 Skeptic 持续维护；依次保留 design 初审、design 复审和当前 spec-to-code review。
formal run、artifact review 和 post-run verdict 均为 `NOT STARTED`。

## A. Audit frame

| 项目 | 审查框架 |
|---|---|
| 精确问题 | 冻结的自包含 polygon-fitted conforming $P_1$ FEM supercell 实验，能否在 30 min / 2 GiB 内独立形成覆盖整个 observed target gap 的 branch/cluster collection 和诚实的四轴 empirical resolution，或 fail closed？ |
| claimed contribution | 在揭盲前生成 fixed-$\beta$ bulk gap、全部 observed defect branches、fields、coverage ledger 和 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$；不计算 effectivity。 |
| 当前阶段 | experiment design；尚未实现、运行或产生 numerical result。 |
| intended output | 工程数值研究的 blinded empirical reference artifact，不是 certified enclosure、continuous spectrum count 或 I4.2 result。 |
| 成功标准 | exact continuous problem 不漂移；reference 与 BIE/QZ 真正隔离；whole-gap empirical coverage 和 cluster handling 可执行；四轴变化按预注册规则 fail closed；完整运行静态估计不超过预算。 |
| 主要假设 | polygonal interface 随 level 收敛到 exact circle；固定 40-root low-spectrum solve 可由 convergence/sentinel gates 形成 empirical inventory；有限 twist sampling 只支持 observed coverage。 |
| 明确排除 | estimator reveal、nearest-current-root selection、MATLAB/Python/Octave 试算、package/main code 修改、I1--I3 历史产物修改。 |

审查材料包括仓库根 `AGENTS.md`、`research/AGENTS.md`、`test/AGENTS.md`、
[[research/projects/eig-apost/implementation/i4/README|I4 guide]]、
[[research/projects/eig-apost/implementation/i4/methods|candidate comparison]]、
[[research/projects/eig-apost/implementation/i4/method-4-1|method manuscript]]、
[[research/projects/eig-apost/implementation/i4/method-review|method review]]、
[[research/projects/eig-apost/STATUS|project STATUS]]、current continuous-method authority 中的
missing-column/first-layer set target，以及 I3 的 gap-set/target-specific distinction。

## B. Design verdict

**Verdict：`REVISE`。Confidence：high。**

continuous model、polygonal variational-crime disclosure、information isolation、attempt lifecycle、
wide-cue non-selection rule 和总体预算框架均可辩护；67 次 distinct bulk solves 与 42 次 distinct
defect solves 的 union 算术也正确。然而当前 coverage gate 允许把 raw observed gap 的 edge-buffer
eigenobjects 排除后仍令 `coverage_pass=true`，这与第一层 whole-gap set target 直接冲突。另一个
blocker 是 cluster qualification/branch output 没有 basis-invariant 定义，且 localization/tail gate
对 twist 的量词未冻结。两处都可能使同一计算输出因实现选择而改变 qualified set，因此在有界文本
修订前不能交 Engineer。

## C. Strongest challenge

最强反例是一条 localized defect band 完全落在
$G_{\mathrm{safe}}^{\mathrm{obs}}$ 与 B4 raw observed gap edge 之间。设计第 5.1 节的 solver
sentinel 会看到它，但第 6.3 节允许将其作为 edge-buffer object 登记、排除，并仍通过 coverage。
此时导出的 $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 不是 whole observed gap 的完整 empirical
collection；该遗漏 branch 还可能是 future candidate 的最近 observed branch，从而改变
set-distance denominator。仅声明 safe interior 不是 certified gap 不能修复这一点：第一层 target
没有被授权从整个 gap 缩成 safe interior。

## D. Findings

### 1. `BLOCKER`：edge-buffer 排除规则破坏 whole-gap coverage

- **Location：** design Sections 1.2、4.2、5.1、6.3；尤其是
  `edge-buffer object 没有进入 qualified set，并被显式登记` 仍可令 `coverage_pass=true`。
- **Evidence：** method contract 要求 broad search 覆盖 independently computed target gap 的完整
  正频率像；gap edge/branch coverage 未解析时必须 fail closed。设计却只让
  $G_{\mathrm{safe}}^{\mathrm{obs}}$ 内对象进入 ledger/qualification，同时把 raw-gap edge buffer
  当作可无害排除区域。
- **Failure mechanism：** 一个真实或 observed localized branch 可位于 edge buffer。排除它会改变
  finite observed set，且可能改变 future set-distance 的最近元素；collection 因而不可解释为当前
  第一层 target 的 empirical reference。
- **Uncertainty：** 目前不知道此类 branch 是否实际存在；但 gate 在它存在时仍可能误报 success，
  这是设计合同缺陷，不是“缺少证据”本身。
- **Cheapest decisive repair：** 保持现有 widened sentinel solves；明确 raw observed gap 与
  $G_{\mathrm{safe}}^{\mathrm{obs}}$ 的 inventory 关系，并冻结：任何 raw-gap edge-buffer 中的
  localized、未解析或无法稳定判定的 eigenobject 都触发
  `BULK_GAP_UNRESOLVED` 或 `REFERENCE_SET_COVERAGE_UNRESOLVED`。只有明确证明 inventory 中没有
  这类对象时才允许 whole-gap `coverage_pass=true`。不得仅把 target 改名为 safe-interior set。

### 2. `BLOCKER`：cluster 与 across-twist qualification 没有唯一、basis-invariant 语义

- **Location：** design Sections 5.1、5.3、6.1--6.3、7。
- **Evidence：** 设计允许 frequency cluster 作为 subspace continuation，并允许 finest anchor
  保存整个 subspace；但 $L_0$、$L_{\mathrm{core}}$、$T_N$、parity、band center、four-axis change
  和 $k_{\mathrm{ref},j}$ 仍按单一 eigenvector/branch 定义。cluster 内旋转 basis 会改变单向量的
  localization/tail。与此同时，“finest slice 必须满足”没有说明是全部
  $\Theta_{17}$ slices、anchor slice、最坏值还是平均值；$N$-tail ratios 在共同
  $\Theta_5$ 上的聚合规则也未写明。
- **Failure mechanism：** 两个合法实现可对同一 eigenspace 选不同 basis 或不同 twist slice，得到
  不同 include/exclude verdict、multiplicity、central value 和
  $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$。这使 complete collection 和失败状态不可复现。
- **Uncertainty：** 若所有 roots 始终 simple 且远隔，问题可能不触发；设计却明确把 unresolved
  multiplicity/cluster 作为 coverage gate，因此不能假定它不会出现。
- **Cheapest decisive repair：** 冻结 across-twist 量词（例如对所有 finest slices 使用
  $\min L_0$、$\min L_{\mathrm{core}}$、$\max T_N$，并在共同 $\Theta_5$ 上逐 slice 检查 tail
  ratios），同时为 cluster 选择一种唯一合同：使用 restricted-mass Gram 的 basis-invariant
  extremal values和 cluster spectral envelope，或只要 finest cluster 无法稳定拆分就直接输出
  `REFERENCE_SET_COVERAGE_UNRESOLVED`。还需明确 cluster 如何贡献
  $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 与逐支 resolution。

### 3. `IMPORTANT CAVEAT`：supercell axis 在 medium geometry 上测量，缺少 final-geometry cross-axis corner

- **Location：** design Sections 5.2、7。
- **Evidence：** $\delta_{N,j}^{\mathrm{obs}}$ 来自 $(s,n_\Gamma)=(18,36)$ 的 $N=4\to5$，
  而 final reference 使用 $(24,48)$、$N=5$。当前 directed ladder 没有 $N=4$、fine geometry、
  $\Theta_5$ corner，因此看不到 FEM/geometry 与 supercell interaction。
- **Consequence：** 若 medium geometry 恰好压低 twist/width sensitivity，最终
  $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 会遗漏一个可见的 cross-axis effect。它限制 empirical
  resolution 的说服力，但在明确保持非上界措辞时不单独否定路线。
- **Cheapest decisive check：** 增加五次 $N=4$、$(24,48)$、$\Theta_5$ solves，并在 final geometry
  重算 $\delta_N$；这会把 defect union 从 42 增至 47，需同步更新预算。若不增加，必须明确把
  cross-axis interaction 记为未测 important caveat，且不得声称 method manuscript 所要求的
  cross-axis check 已通过。

### 4. `IMPORTANT CAVEAT`：low-spectrum solver completion gate 仍缺机械定义

- **Location：** design Sections 4.2、5.1。
- **Evidence：** 40th-root sentinels 在正 definite generalized spectrum 上是合理的 empirical
  upper/lower bracketing，但设计没有显式要求 `eigs` 的 convergence flag、恰好 40 个 finite roots、
  排序/去重规则和 cluster multiplicity preservation 全部通过。逐根 residual 小并不单独证明一次
  iterative solve 没有丢失 requested root。
- **Consequence：** 实现可能把部分收敛的 `eigs` 返回值误当 complete slice，直接污染 coverage。
- **Cheapest decisive repair：** 冻结 `flag==0`、returned count、finite/ordered spectrum、all-root
  residual 和 multiplicity ledger 为 hard gates；可在预注册的少数 worst slices 用较大 `nev`
  重复作 count sentinel。失败必须是 `SPECTRUM_INVENTORY_TRUNCATED`，不能继续 branch stage。

### 5. `MINOR CAVEAT`：`NO_LOCALIZED_BRANCH` 只是否定冻结 screen

- **Location：** design Sections 1.2、6.1、11。
- **Evidence：** $L_0\ge0.15$、$L_{\mathrm{core}}\ge0.60$、$T_5\le0.02$ 是预注册的 empirical
  screen，不是 continuous existence test。
- **Consequence：** 即使 full numerical inventory 通过，`NO_LOCALIZED_BRANCH` 也只能解释为
  `no branch qualified under the frozen observed screen`，不能否定 continuous guided mode。
- **Cheapest repair：** 在 terminal claim boundary 中采用这一限定措辞；不需新理论或额外实验。

## E. Implementation and reproducibility audit

尚无 implementation 或 output，不能进行 spec-to-code 判断。跑前审查必须特别检查：

1. constrained Delaunay 的每条 polygon constraint 都成为 mesh edge，且 triangle material label
   不跨 interface；
2. phase reduction 的 corner factor、seam pairing 和 Hermitian checks 是 hard gates；
3. `eigs` completion/count/sentinel 与 cluster rules 按修订设计实现；
4. code 不读 Markdown、Git、历史 output 或 current-chain data，不发现 repository root，也不依赖
   absolute repository path；
5. stage-first progress、first-failure semantics、atomic export、run-ID collision 和 30 min / 2 GiB
   monitor 均可执行。

本次 design review 没有运行 MATLAB、Octave、Python numerical experiment 或任何 guided-mode
computation。

## F. What survived

1. exact continuous problem 与 method authority 一致：exact radius-$0.2$ disks、missing center
   column、$q=17/1$、$\beta=0.5$、$A=I$、$B=q$、$\lambda=k^2$。
2. polygon-fitted $P_1$ finite problems 与 exact-circle target 被诚实区分；finest
   $n_\Gamma=48$ 的 circle-to-chord sagitta 约为 $4.28\times10^{-4}$，确实通过冻结的
   $5\times10^{-4}$ geometry diagnostic，但该量没有被冒充 eigenvalue bound。
3. volume FEM + constrained mesh + direct generalized eigensolve 与 current BIE/QZ chain 具有实质
   independence；blinding order 和 prohibited-input list 足以阻止 obvious estimator leakage。
4. $I_{\mathrm{cue}}=[1.65,2.05]$ 只用来唯一标识“完整包含该宽区间”的 bulk gap，不按未知 current
   root 排序或选 branch。这个 gate 是保守、可失败且不依赖精确 current root；它可能产生合法的
   `BULK_GAP_UNRESOLVED`，但不会产生 nearest-root leakage。
5. fixed 40-root sentinels、nested twist grids、tail/twist collapse、all-object ledger 和 fail-closed
   states 构成了可修复的 empirical coverage 框架。
6. attempt reuse、运行输入白名单、atomic output、formal-command boundary 和“不进入 effectivity”均
   与用户约束一致。

### Solve-count 与预算复算

- Bulk：B1 的 17、B2 的 17 与 B4 的 33 个 phases；B3 的 17 个 phases 是 B4 的 nested subset，
  同 mesh/tolerance 可复用，所以 distinct count 为 $17+17+33=67$。另有五个 loose/tight repeats，
  完整 bulk count 为 72。
- Defect：FEM axis 15；supercell axis 只新增 N3/N4 的 10；fine twist union 从
  $\Theta_5$ 扩到 $\Theta_{17}$ 只新增 12；loose algebraic repeat 新增 5，故
  $15+10+12+5=42$。
- 总计划为 114 eigensolves。按设计自己的上界，22 个 fine solves 取 35 s、其余 20 个 defect
  solves 取 15 s、72 个 bulk solves 取 1.5 s，solve subtotal 约 19.6 min；27 min 上界给 startup、
  meshing、tracking 和 export 约 7.4 min。该预算算术可执行但余量不大，actual DOF/fill estimate
  必须在 spec-to-code gate 重算。当前 $1.2$ GiB peak estimate 低于 2 GiB，不构成 design blocker。

## G. Minimal resolution before implementation

Researcher 只需对同一 `design-4-1a.md` 做有界修订：

1. 令任何 raw-gap edge-buffer localized/unresolved object 触发 coverage/gap failure，关闭 whole-gap
   omission；
2. 冻结 all-twist localization/tail aggregation与 basis-invariant cluster qualification、cluster
   output/resolution semantics；
3. 明确 `eigs` complete-return hard gates；
4. 对 final-geometry $N$ corner 作“增加五次 solve”或“明确降级为未测 cross-axis caveat”的预先
   决定，并同步 solve count/预算。

完成后交回同一 Skeptic 复审。不得在修订前创建 `test/i4/femref-a1/` 或运行 scientific solve。

## H. Open-problem handoff

本表只供主 agent 合并到既有 project ledger；Skeptic 不修改 ledger。

| Stage | Category | Item | Blocking scope | Cheapest next check | Suggested status |
|---|---|---|---|---|---|
| I4.1a design | `BLOCKER` | raw-gap edge-buffer 可被排除但 coverage 仍通过 | 阻止 design pass 和 Engineer handoff | 纯文本修订 fail-closed edge rule | `OPEN` |
| I4.1a design | `BLOCKER` | cluster/basis 与 across-twist qualification 未冻结 | 阻止可复现 qualified set | 纯文本冻结 invariant/quantifier rules | `OPEN` |
| I4.1a resolution | `IMPORTANT CAVEAT` | final geometry 未测 $N=4\to5$ cross-axis interaction | 限制 empirical uncertainty；不单独否定方法 | 五次 fixed corner solves 或显式降级 | `SCHEDULED` |
| I4.1a solver | `IMPORTANT CAVEAT` | iterative low-spectrum complete-return gate 不完整 | 可能污染 slice coverage | 冻结 `flag/count/order/residual` gates | `SCHEDULED` |

当前结论：`REVISE`；两个 unresolved blockers 都可由有界 design 修订解决。没有进入 implementation
或 numerical run。

## I. Design re-review

复审对象：同一
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]] 的 bounded revision。
初审文字和 findings 原样保留作为审查历史；本节给出当前权威 verdict。

### I.1 Re-review verdict

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。**

两个初审 blocker 均已关闭，没有 unresolved blocker。修订稿把 raw observed gap edge buffer 改为
all-level/all-slice 空集硬门，任何 object 均使 whole-gap coverage fail closed；它不再允许“登记后
排除”。cluster 现在以 dimension-stable subspace、restricted-mass Gram spectra、principal-angle
overlap、compressed-parity spectrum 和 spectral envelope 表述；所有 qualification 均有明确的
every-slice 量词，且 unresolved dimension/continuation 不再产生 basis-dependent scalar result。
40/48-root complete-return/count sentinels和 final-geometry $N=4\to5$ corner 也已冻结。

因此设计可以交 Engineer 实现。该授权不包括 formal run：29.8 min conservative estimate 只低于
30 min 约 12 s，必须在 implementation 完成后的 theory-to-code 与 spec-to-code gate 根据 actual
DOF、sparse fill、solver configuration、119-solve ledger 和 export cost 重新估算；跑前估算一旦超过
30 min 或 1.5 GiB design-preflight threshold，必须输出 `RESOURCE_BUDGET_UNAVAILABLE` 并停止，不能
靠删减 coverage/refinement 或拆 command 启动。

### I.2 Initial blockers resolution

#### 1. `BLOCKER — RESOLVED`：whole raw-gap edge-buffer omission

- **Revised locations：** design Sections 1.2、4.2、5.1、6.3、11。
- **Resolution evidence：** defect inventory 先覆盖
  $G_{\mathrm{raw}}^{\mathrm{obs}}$；只有
  $G_{\mathrm{raw}}^{\mathrm{obs}}\setminus G_{\mathrm{safe}}^{\mathrm{obs}}$ 在每个冻结
  FEM/$N$/twist/algebraic slice 都为空，才进入 branch qualification。任一 object，无论看似
  localized、delocalized、clustered 或 unresolved，都立即触发 `BULK_GAP_UNRESOLVED` 和
  `coverage_pass=false`。
- **Decision：** 初审反例不再能误报 success；first-layer target 没有被缩为 safe-interior target。

#### 2. `BLOCKER — RESOLVED`：cluster basis dependence 与 slice quantifier

- **Revised locations：** design Sections 5.3、6.1--6.3、7、9.2、10.2。
- **Resolution evidence：** multiplicity-$m$ cluster 以 $M$-orthonormal subspace $U$ 表示；
  $G_D(U)=U^*M_DU$ 的 extremal eigenvalues、$U^*M\mathcal R_xU$ 的 spectrum、cross-subspace
  singular values 和 spectral envelope 在 $U\mapsto UQ$ 下均不变。dimension 必须在所有 twists、
  FEM/$N$ levels 和 algebraic repeats 中稳定；merge/split 或不唯一 continuation 直接 fail coverage。
  localization 在全部 $\Theta_{17}$ slices 检查，tail/collapse 在共同 $\Theta_5$ 上逐 slice 检查；
  verdict 不再使用平均值。stable cluster 输出一个 envelope center、multiplicity、完整 subspace 和
  envelope-based $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$；unresolved cluster 不输出 scalar reference。
- **Decision：** qualification、mode identification、output 和 resolution 已 basis-invariant 且足以
  进入 implementation。common-core interpolation/orthonormalization 的具体线性代数仍须在
  spec-to-code review 核对，但不再是 design ambiguity。

### I.3 Additional gates rechecked

#### 40/48-root coverage sentinels

- 所有 main solves 均要求 `flag==0`、完整 requested count、finite/positive ordered roots、保留
  multiplicity、$M$-orthonormality、all-root residual、Hermitian/mass 和上下 spectral sentinels。
- B4 的五个固定 phases 另求 48 roots；其 first 40 必须与 tight 40-root solve 的
  cluster-preserving ordered list 在 $10^{-8}$ frequency tolerance 内一致，41--48 不得回到 raw gap。
- finest defect 的五个 loose algebraic solves 固定为 48 roots；first 40 与 tight solve 的 tolerance
  为 $10^{-7}$，并执行相同 count/sentinel hard gates。
- 任一失败均是 `SPECTRUM_INVENTORY_TRUNCATED`，不能在结果后扩大 `nev`。这足以支持当前强度的
  empirical inventory；它仍不是 certified spectral count。

#### Final-geometry supercell corner

新增 $N=4$、$(s,n_\Gamma)=(24,48)$、$\Theta_5$ 的五次 solves。修订的
$\delta_{N,j}^{\mathrm{obs}}$ 同时包含 final-geometry $N=4\to5$ envelope change 及它与 medium-
geometry change 的 observed interaction；final-geometry twist/tail collapse 也逐 slice fail closed。
初审的 cross-axis caveat 已按最小数值 corner 关闭。

#### Solve-count and static budget

- Bulk main union 仍为 $17+17+33=67$；五个 fixed 48-root count sentinels使 bulk total 为 72。
- Defect 原 union 为 42；新增五个 fine-geometry $N=4$ corners 后为 47。五个 loose algebraic
  48-root solves 已在原 42 中，不重复计数。
- 总数为 $72+47=119$，与修订稿一致。
- 以修订稿各类 solve 上界复算：27 个 fine/corner solves 取 35 s、其余 20 个 defect solves 取
  15 s、72 个 bulk solves 取 1.5 s，solve subtotal 约 22.55 min；29.8 min estimate 留给 startup、
  meshing、tracking、CSV/MAT export 约 7.25 min。算术没有漏项，但只有 0.2 min 的计划余量。
- 预计 7000--9000 reduced DOF、hard cap 12000、`nnz(K)+nnz(M)` cap 2000000、单 solve live objects
  和最多 48 vectors 支持 1.2 GiB 静态估计；actual sparse factor fill 尚须 Engineer 静态 audit。

### I.4 Remaining conditions and caveats

1. `IMPORTANT CONDITION`：29.8 min 不是可依赖的运行余量。Engineer handoff 后必须在不运行正式
   science 的前提下完成 actual implementation resource preflight；若 updated estimate 大于 30 min，
   当前设计成为 `RESOURCE_BUDGET_UNAVAILABLE`，返回 Skeptic，不得 launch。该不确定性不阻止写代码，
   因为目前 best available estimate 尚未超限且 implementation facts 可给更强判断。
2. `IMPORTANT CAVEAT`：$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 仍是 observed envelope，不是 true-error
   bound；P1 polygonal refinements仍可能共享 pre-asymptotic bias。修订没有越界提升 claim。
3. `MINOR CAVEAT`：40/48 agreement、finite twist grids 和 empty observed edge buffer 只支持 empirical
   coverage；不构成 continuous completeness theorem。

### I.5 Updated handoff

| Stage | Category | Item | Blocking scope | Next gate | Status |
|---|---|---|---|---|---|
| I4.1a design | `BLOCKER — RESOLVED` | raw-gap edge-buffer omission | 不再阻止 Engineer | spec-to-code 检查实现确为 all-level/all-slice hard gate | `RESOLVED` |
| I4.1a design | `BLOCKER — RESOLVED` | cluster/basis 与 twist quantifier | 不再阻止 Engineer | spec-to-code 检查 Gram/subspace/envelope formulas | `RESOLVED` |
| I4.1a resolution | `IMPORTANT CAVEAT — RESOLVED AT DESIGN` | final-geometry $N$ interaction 未测 | 五次 corner 已冻结 | 检查五次 solves 与 interaction term 均实现 | `RESOLVED` |
| I4.1a resource | `IMPORTANT CONDITION` | 29.8 min estimate 仅余 12 s | 不阻止实现；阻止未经复算的 formal run | actual implementation preflight | `OPEN` |

最终 design re-review：`PASS WITH CONDITIONS`；**Engineer handoff authorized**。formal run 仍为
`NOT AUTHORIZED`，必须等待 Researcher theory-to-code check、同一 Skeptic spec-to-code review 和跑前
resource preflight。

## J. Spec-to-code and resource review

审查对象：`test/i4/femref-a1/run_i4_1a.m`、同目录 `README.md` 与 `SYMBOLS.md`，以及 current
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]]。Researcher handoff 报告
`THEORY-TO-CODE PASS`；本 Skeptic 将其视为待核查 claim，并独立逐对象复核。

### J.1 Verdict

**Verdict：`REVISE`。Confidence：high。First formal command：`NOT AUTHORIZED`。**

数值公式和大部分 fail-closed gates 与 design 一致；没有 current-chain import、prohibited read、
repository absolute path 或额外 attempt directory。72+47 schedule、B3 alias、40/48 sentinels、raw-gap
empty-buffer、basis-invariant cluster continuation、four-axis envelope formulas 和 pre-eigensolve resource
ledger 均已静态实现。

但是 expected branch/coverage scientific failures 在 helper 内直接抛出，caller 尚未收到更新后的
artifacts；因此合法的 `REFERENCE_SET_COVERAGE_UNRESOLVED` 或
`SUPERCELL_RESOLUTION_UNAVAILABLE` 可只留下 raw spectra 和一句 exception，而缺失 design 要求的
partial branch edges、branch inventory、coverage ledger 及 reached-branch fields。I4.1a 的 primary
deliverable 明确包括“完整 ledger 的合法失败状态”，所以这不是可留给 post-run 的文档瑕疵，而是
formal run 前的静态 blocker。

### J.2 Finding 1 — `BLOCKER`：expected scientific-failure artifacts 未在异常前发布

- **Location：** `run_i4_1a.m` main stage 5；`LOCAL_branch_and_coverage`、
  `LOCAL_track_twists`、`LOCAL_match_configurations`、`LOCAL_tail_collapse`、
  `LOCAL_twist_collapse`；另见 `LOCAL_export_success` 和 bulk 48-root sentinel loop。
- **Evidence：** main 只有在 `LOCAL_branch_and_coverage(...)` 正常 return 后才调用
  `LOCAL_write_branch_artifacts`。然而 changing cluster count、nonunique continuation、dimension change、
  cross-configuration mismatch 以及 tail/twist failure 都在深层 helper 中 `LOCAL_raise(...)`。MATLAB
  value semantics 下，callee 内累积的 `artifacts.branch_edge_rows` 等不会返回 caller；catch 只写
  `failures.csv`、empty `reference-collection.mat` 和 summary。`coverage_result.pass=false` 路径实际上
  接不到这些 expected failures。类似地，bulk 48-root mismatch 在保存 sentinel spectrum 之前抛出；
  resolution failure 虽保存 scalar ledger，但已到达的 anchor subspaces 只在 success 的
  `fields.mat` 中导出。
- **Failure mechanism：** 一次 correctly implemented full run 若在 cluster continuation 或 collapse
  gate 合法失败，将无法重建哪个 edge、subspace、slice 或 branch 触发 first failure；post-run
  Skeptic 不能区分真实 scientific negative、matching bug 或 ledger omission，也不能审计 retry
  eligibility。该 artifact 不满足 frozen failure schema。
- **Cheapest decisive repair：** expected scientific gates 不得跨 stage publication boundary 直接丢弃
  artifacts。可选择：
  1. 让 branch stage 返回 `coverage_result.pass=false`、first code/reason 和所有已形成 rows，由 main
     原子写出 `branch-edges.csv`、`branch-inventory.csv`、`coverage-ledger.csv`、reached anchor
     `fields.mat` 后再 `LOCAL_raise`；或
  2. 在 stage-local `try/catch` 中保存同等 partial artifacts 后 rethrow，同时保持 single first-failure
     semantics。
  bulk 48-root sentinel 也须在 mismatch gate 前保存其 machine spectrum/ledger。resolution failure
  时若 branches 已形成，须按 design 的 “fields if branches reached” 发布 subspaces，并明确标记
  `UNQUALIFIED / FAILURE_ARTIFACT`。不得通过删掉 required outputs 或把 scientific failure 改称
  operational failure 修复。

### J.3 Static implementation audit

#### Scope, isolation, and portability — survived

- 唯一 active directory 是 `test/i4/femref-a1/`，只有 entry、README 和 symbol ledger；没有第二 attempt。
- executable code 的路径只由 `mfilename('fullpath')` 得到 entry-local `output/<run_id>/`；没有发现
  `/Users/...`、repository-root discovery、`pwd`/`cd`、shell/system/Git 或 sibling-path dependency。
- runtime `load` 只读取本次 `output/<run_id>/work/` 中由同一 command 刚写出的 mesh/spectrum payload；
  `dir` 只读取 current-run cache size。没有 Markdown、README、design/review、STATUS、historical
  output、candidate、estimator、BIE density 或 QZ field read。
- physical model digest 只 hash source-owned scalar configuration，不 hash human-facing artifact，且不
  消费 current-chain information。

#### MATLAB API and syntax — statically plausible

- entry/subfunction layout、`LOCAL_` groups、2-space indentation 和 substantial-file header 符合 root
  instructions。
- R2023b 所需 APIs（`delaunayTriangulation`、`triangulation`、`pointLocation`、
  `cartesianToBarycentric`、`symbfact`、generalized `eigs(...,'smallestabs')`、`save -v7.3`）的调用
  形式静态合理；environment gate 在任何 eigensolve 前检查 availability。
- 本审查依约没有运行 `checkcode`、MATLAB、Octave 或 Python，因此 actual API availability、mesh
  topology 和 solver behavior 仍是 formal-command 内 pre-eigs/runtime risks，不伪装为已验证结果。

#### Mesh, material, reflection, and quasiperiodic forms — survived

- bulk 含中心 disk；defect mesh 删除 $j=0$ disk，并保留 $j=-N,\ldots,-1,1,\ldots,N$。
- constrained polygon edges、outer rectangle、half-integer vertical boundaries、inner/outer rings、
  constraint-preservation、minimum-angle、inversion、cross-interface 和 exact-circle geometry diagnostics
  均有 hard gates。half-integer constraints使 $C_0$、$|x|<3/2$ 和 $|x|>N-3/2$ 成为 triangle unions。
- triangle stiffness 是 $\int\nabla u\cdot\nabla\bar v$；mass coefficient 是 polygon disk 内 17、外
  1。restricted masses复用同一 weighted local mass，符合 design 的 discrete functionals。
- node reflection permutation和 assembled full-$K/M$ reflection defects 在 eigensolve 前 fail closed。
  正则 Cartesian/Delaunay tie-breaking 可能使该 oracle 实际失败，但当前无法静态证明；若发生，它在
  pre-eigs 以 `MESH_QUALITY_UNRESOLVED` 停止，属于可审查运行风险而非已展示的 formula defect。
- master/slave reduction 使用
  $P^*KP$、$P^*MP$；right/top phases 分别为 $e^{\mathrm i\phi}$、$e^{\mathrm i\beta}$，top-right
  自动为 $e^{\mathrm i(\phi+\beta)}$。coordinate、seam 和 Hermitian checks 是 hard gates。

#### Solve union and inventory — survived

- bulk main schedule 为 B1 17 + B2 17 + B4 33 = 67；B3 是 B4 odd-index phases 的 explicit
  `alias-reuse-no-solve` ledger，不增加 counter。五个 fixed B4 48-root sentinels使 bulk total 72。
- defect schedule 是 5 coarse + 5 medium + 17 finest + 5 N3-medium + 5 N4-medium + 5 N4-fine +
  5 loose-count = 47，总 counter hard gate 为 119。
- each solve 检查 `flag`、requested count、finite/positive objects、ordered multiplicity、
  $M$-orthogonality、all-root residual、mass Cholesky、Hermitian defect 和上下 sentinels。40/48 comparisons
  保存 cluster IDs 和 frequency tolerances；41--48 不得落回 raw gap。
- every defect solve 在 branch processing 前检查 raw-gap edge buffer；任一 object 立即
  `BULK_GAP_UNRESOLVED`，所以 all-level/all-slice empty-buffer contract 已实现。

#### Cluster, mode, and resolution formulas — survived

- gap cluster subspaces重新 $M$-orthonormalize；regional labels使用 restricted-mass Gram extremal
  eigenvalues，anchor parity使用 compressed reflection spectrum，same-mesh/common-core matching 使用
  subspace singular values。common-core samples在离散 circle points 上删除，并按 exact $q$ 加权后
  分别 orthonormalize，避免 basis/scale leakage。
- twist tracking要求 cluster count、dimension、mutual best match 和 overlap threshold 全部稳定；跨
  FEM/$N$/algebraic configurations 在五个 common phases 上一一匹配，否则 fail coverage。
- localization 对全部 $\Theta_{17}$ slices 取 every-slice gate；medium/fine tail collapse 与
  final-geometry twist collapse 均按冻结 phase grid检查。
- $\delta_{\mathrm{FEM}}$、fine/medium interaction-aware $\delta_N$、twist sampling + half-width、
  algebraic envelope maximum 和 total $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 与 revised design 一致，
  且输出继续声明不是 upper bound。

### J.4 Resource review — `IMPORTANT CONDITION`, not a demonstrated blocker

内部 preflight 在 first eigensolve 前完成九个 mesh、actual reduced DOF/nnz、`symbfact` fill、40/48
workspace、current-run mesh/spectrum cache、export buffer 和 67/5/20/27 solve-category ledger。B3 alias
不计 solve；五个 defect loose-count 已含在 27；119 total、12000 DOF、2000000 nnz、1.5 GiB preflight
cap 和 29.8 min design floor 均被机械检查。

memory estimate 使用 actual symbolic fill、复杂 sparse/vector workspace、runtime baseline、current-run
cache/export 和 1.25 safety factor，并以 1.2 GiB 为 floor。runtime estimate使用 actual DOF scaling、
same-command preflight elapsed、全部 solve categories、300 s postprocess allowance 和 29.8 min floor；若
forecast 超过 30 min 或 memory 超过 1.5 GiB，在任何 eigensolve 前 fail closed。故未知 actual mesh
规模不是当前静态 blocker。

剩余限制是 runtime nominal rates 未由本 implementation 上的实测校准，`symbfact` fill 只直接进入
memory estimate，频繁 CSV/MAT publication 也只能由 300 s allowance近似。29.8 min 只余 12 s，
因此它不是性能保证。修复 blocker 后若授权 formal command，Code Runner 必须：

1. 把 preflight、MATLAB startup、119 solves、postprocess 和 subprocess 计入同一 clock；
2. 30 s 轮询 process/RSS/progress，RSS 达 2 GiB 或 wall 达 40 min hard stop；
3. 30 min 时仅在至少 90% solves complete、最近五次 rate 有限且 ETA 不超过 10 min 时允许一次 grace；
4. 不因 preflight pass 而忽略 external RSS，也不拆命令重置预算。

这仍是 `IMPORTANT CONDITION`，不是额外 design blocker；当前 formal command 未授权是因为 J.2 的
artifact blocker，而不是把未知 runtime 当作已证明超限。

### J.5 Additional caveats

1. `IMPORTANT CAVEAT`：top-level catch 消化 scientific 和 operational exceptions，除 output collision
   外 shell process 可能以 code 0 退出。formal monitor/post-run review 必须以
   `run-summary.mat`/console `Terminal status` 为 authority，不能以 shell exit 0 认定 success。若将
   `EXECUTION_UNAVAILABLE` 改为 nonzero exit，必须先保存 failure artifacts。
2. `MINOR CAVEAT`：`MODE_ID_AMBIGUOUS` 目前以 parity fields、coverage boolean 和 collection flag
   表示，不作为 terminal failure；这与“first layer may survive”一致，但 post-run summary 必须显式
   报告该 flag。
3. `MINOR CAVEAT`：40/48 sentinels、finite phases 和 observed empty buffer 只形成 empirical
   inventory，不是 continuous spectral-count theorem；代码 claim boundary 保持了该降级。

### J.6 Minimal repair and next gate

同一 Engineer 只需修复 failure-path publication，不改变任何 mesh、solver、threshold、schedule 或
科学公式：

- expected branch/coverage/collapse failures return or checkpoint partial rows before throw；
- bulk count-sentinel mismatch先保存 sentinel evidence；
- reached branch subspaces在后续 resolution failure时仍导出为明确 unqualified failure artifact；
- 保持 output collision、atomic `.partial` publication、single first failure 和 current-run-only cache。

修复后交回同一 Skeptic 做 bounded spec-to-code re-review。当前不得执行

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-001')"
```

artifact/post-run review section 继续保留，待 formal run 真正获授权并完成后追加。

## K. Spec-to-code bounded re-review

复审对象是同一 Engineer 对 J.2/J.6 的 bounded failure-path repair。本节是当前
spec-to-code 权威结论；J 节保留为初审历史。本次仍只做静态审查，没有运行
MATLAB、Octave、Python 或任何 numerical experiment。

### K.1 Verdict

**Verdict：`REVISE`。Confidence：high。First formal command：`NOT AUTHORIZED`。**

J.2/J.6 指定的 failure-publication 修复本身已关闭：branch/coverage、cross-configuration
matching、tail/twist collapse、`NO_LOCALIZED_BRANCH` 和 resolution failure 均在重抛原
scientific code 前先发布可达 ledger；已形成 branch 的 anchor 按 configuration/mesh identity
输出为明确 unqualified field，未完成 continuation 的 cluster 只作
`REACHED_UNTRACKED` row，不冒充 branch。bulk 48-root sentinel 也在 mismatch gate 前保存
machine spectrum 并刷新 bulk/seam evidence。

然而当前 code 有一个独立、确定的 MATLAB scope blocker：
`LOCAL_gap_clusters` 没有接收 `spec`，却在函数体中读取 `spec.parity_threshold`。MATLAB
subfunction 不捕获 caller workspace；因此首个非空 raw-gap cluster 必将以 undefined
`spec` 失败。该异常被解码为 `EXECUTION_UNAVAILABLE` 并直接 rethrow，不会进入新的
scientific failure handoff。由于 branch stage 在 119 次 frozen eigensolves 之后，它会消耗整个
scientific budget 却不可能形成 primary deliverable。

### K.2 `BLOCKER`：`LOCAL_gap_clusters` 的 `spec` 作用域错误

- **Location：** `test/i4/femref-a1/run_i4_1a.m:2031`、`:2047`、`:2080`。
- **Evidence：** call 为 `LOCAL_gap_clusters(spectrum, target_gap, mesh)`，definition 也只有三个
  arguments，但 `parity_ambiguous` 读取 `spec.parity_threshold`；该 subfunction 内没有定义
  `spec`。
- **Failure mechanism：** 任一非空 gap cluster 进入 parity 计算后必然触发 undefined-variable
  operational exception。`LOCAL_build_configuration` 和 `LOCAL_branch_and_coverage` 都对
  `EXECUTION_UNAVAILABLE` rethrow，所以当前正式命令无法到达 coverage/resolution 或新的
  complete failure-ledger path。
- **Consequence：** 确定阻止 I4.1a reference artifact 和可解释的 scientific negative result；
  不能把它留给 formal run 后调试。
- **Cheapest decisive repair：** 只把同一 frozen `spec` 显式传入
  `LOCAL_gap_clusters`（或只传入 frozen parity threshold），同步唯一 call signature；不改任何
  科学参数、公式、schedule 或 artifact schema。修复后由同一 Skeptic 做一次有界的
  static re-review。

### K.3 Failure-path and schema checks that survived

1. `LOCAL_branch_failure_handoff` 保留已完成 configuration 的 branch rows，保留已读取但
   尚未 continuation 的 cluster rows，并把同一 first code/reason 写入三个 ledger 后才由
   main rethrow。cross-config 异常和 collapse failure 都会走该 handoff。
2. `NO_LOCALIZED_BRANCH` 先 mark/write ledgers 并输出 reached fields；resolution failure 先写
   19-column resolution ledger，再 mark/write branch ledgers 和 unqualified fields，然后抛出原
   `REFERENCE_RESOLUTION_UNRESOLVED`。
3. `reached_anchor_fields` 只遍历已有 complete `branches` 的 configurations；每个 entry 包含
   `configuration`、`mesh_id`、`branch_id`、multiplicity 和 qualification。`fields.mat` 嵌入的
   meshes 通过 current-run registry/work cache 加载，并标记
   `UNQUALIFIED / FAILURE_ARTIFACT`；未形成 branch 的 cluster 不输出为 field branch。
4. bulk count mismatch 在 raise 前已原子保存 current-run sentinel MAT，追加 bulk/seam rows 并
   发布相应 CSV。在无更早 resource failure 时，terminal code 仍为原
   `SPECTRUM_INVENTORY_TRUNCATED`。
5. CSV schema 与所有相关 row constructors 同宽：`branch-edges.csv` 为 14 columns、
   `branch-inventory.csv` 为 24 columns、`coverage-ledger.csv` 为 12 columns；普通行、
   reached-untracked 行和 failure marker 均匹配。CSV/MAT 仍通过 sibling `.partial` 后
   `movefile` 发布，output collision 及 current-run-only cache 规则未改变。

### K.4 Resource condition and bounded next gate

J.4 的 resource 判断未改变：actual DOF/nnz、`symbfact` fill、40/48 workspace、cache/export、
67/5/20/27 categories 和 119 total 均仍进入 pre-eigensolve audit；29.8 min 和 1.2 GiB
floors、30 min/1.5 GiB launch gates 仍在。29.8 min 的 12 s 余量仍是
`IMPORTANT CONDITION`，但它不是本轮新 blocker。

当前不授权执行预注册的 first formal command。完成 K.2 的单点 signature repair 并通过
static re-review 之前，不得运行：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-001')"
```

artifact/post-run section 仍为 `NOT STARTED`，本节不给出任何 numerical 或 effectivity verdict。

## L. Final bounded spec-to-code re-review

复审对象仅为 Engineer 对 K.2 的单点 signature repair 及对应 symbol locator。
K 节保留为审查历史；本节是当前 spec-to-code 权威结论。本次没有运行
MATLAB、Octave、Python 或任何 numerical experiment。

### L.1 Verdict

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。First formal command：`AUTHORIZED`。**

K.2 的 undefined-`spec` blocker 已关闭。`LOCAL_build_configuration` 中唯一 call 现为
`LOCAL_gap_clusters(spec, spectrum, target_gap, mesh)`，helper definition 以相同顺序接收
四个 arguments，并在同一 scope 中读取 frozen `spec.parity_threshold = 0.80`。全文
只有这一个 call 和这一个 definition，没有旧三参数签名或另一条调用漂移；
`SYMBOLS.md` 也已把 `spec.parity_threshold` 的 consumer 指向
`LOCAL_gap_clusters`。修复没有改变 threshold、cluster formula、schedule、schema 或
failure-publication path。

结合 J.3--J.5 和 K.3 已通过的完整静态审查，当前没有 unresolved
spec-to-code blocker。该结论只授权首个 blinded formal command，不等于 numerical
success、reference acceptance 或 effectivity verdict。

### L.2 Exact authorized command and launch boundary

从 `test/i4/femref-a1/` 作为 working directory，且仅在
`output/run-001/` 仍不存在时，授权执行：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-001')"
```

这一 command 包含 MATLAB startup、internal pre-eigensolve resource audit、119 eigensolves、
postprocess 和 export，共享同一 wall/memory budget。不得拆分或使用第二 command 重置计时。
internal preflight 若给出 forecast $>30$ min、peak estimate $>1.5$ GiB、DOF $>12000$ 或
`nnz(K)+nnz(M)>2000000`，必须在 first eigensolve 前以
`RESOURCE_BUDGET_UNAVAILABLE` fail closed；这是合法 formal outcome，不得通过减少
inventory/refinement 规避。

### L.3 Frozen external monitor

Code Runner 必须从 process 启动起每 30 s 记录 process alive、elapsed wall、RSS、
`progress.csv` 的 stage 与 completed/planned solves。单次 sparse solve 可能较长，因此 90 s
无 progress 只标记 `OUTPUT_STALL` advisory，不自动中断。以下规则为必须执行的
hard/grace boundary：

1. observed RSS 达 $2$ GiB 立即 hard stop；不以 internal 1.5 GiB estimate 代替 external RSS。
2. elapsed wall 达 30 min 时，只有在 completed solves 至少为 $0.90\times119$，最近
   五个 solve rates 全部 finite，且 current ETA $\le 10$ min 时，才允许唯一 grace
   period；任一条不满足即停止。
3. elapsed wall 达 40 min 无条件 hard stop，没有第二次 extension。所有 subprocess 和
   export 时间均计入同一 elapsed wall。
4. 外部中断必须保留当时已原子发布的 current-attempt artifacts 供 post-run 审查；
   不新建 attempt 或立即重跑。

### L.4 Frozen terminal-status interpretation

MATLAB top-level catch 会消化 scientific/operational exceptions，因此 **shell exit code 0 不是
success evidence**。外部判定冻结为：

- 只有 console 明确输出 `Terminal status: REFERENCE_COLLECTION_READY`，且 post-run 审查核对
  `run-summary.mat` 的 `success=true`、`terminal_status=REFERENCE_COLLECTION_READY`、
  `completed_solves=119`，`reference-collection.mat` 状态一致且 `failures.csv` 为空，才可判为
  command-level success candidate；它仍需同一 Skeptic 的 artifact/post-run verdict。
- console 的任何其他 `Terminal status` 都是已完成的 fail-closed outcome，必须以该
  scientific/operational code 与已发布 ledgers 审查，不得因 shell exit 0 冒充 success。
- shell nonzero、process disappearance、2 GiB/40 min external kill 或无可读 terminal artifacts 是 execution
  failure/externally interrupted outcome，不是 scientific-method verdict；保留同一 attempt 进入
  artifact/retry-ledger 判定。

### L.5 Remaining condition and next authority

29.8 min conservative floor 仍只低于 30 min 约 12 s；runtime nominal rates 尚未由该实现
实测校准。这是 `IMPORTANT CONDITION`，由 internal preflight 和 L.3 external monitor 约束，
但不再阻止 first formal command。artifact/post-run review 仍为 `NOT STARTED`；在同一 Skeptic
完成该审查前，不得同步 numerical claim 到项目研究文档，也不得进入 effectivity
comparison。

## M. Bounded operational re-review after `run-001`

本节只审查 `run-001` 的 operational stop、Engineer 对 environment capability probe 和 CSV
cleanup 的 bounded repair，以及同 attempt 的 retry eligibility。L 节的科学
spec-to-code verdict 与 resource/terminal contract 保持有效。本次没有运行 MATLAB、Octave、
Python 或任何 numerical experiment。

### M.1 Verdict

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。Corrected formal rerun：`run-002 AUTHORIZED`。**

`run-001` 在 `SPEC_AND_ENVIRONMENT`、`completed_solves=0/119` 停止；`work/` 中没有
mesh/spectrum cache，且 `matlab.log`、`progress.csv`、`failures.csv`、
`reference-collection.mat` 和 `run-summary.mat` 均保留。旧失败码为
`DEPENDENCY_UNAVAILABLE`，消息是把 `pointLocation` 当作普通 file/builtin 查找后误判
缺失；R2023b log 显示 MATLAB 23.2。该运行既没有 eigensolve，也没有证明 frozen
scientific method 失败，因此是可修复的 environment/code operational failure，不消耗
`femref-a1` attempt。

修复后没有 unresolved operational blocker。`run-001` 必须保留为失败证据；新
`run_id=run-002` 只创建同一 `test/i4/femref-a1/` 下的新 artifact namespace，不改任何
science，不是新 attempt，且当前 `output/run-002/` 不存在。这与 design Sections
8.3、9.3 及 `test/AGENTS.md` 的 operational retry rule 一致。

### M.2 Capability-check audit

1. 普通 numerical functions 只检查 `sparse`、`eigs`、`symbfact`，并分别接受
   `file` 或 `builtin`；这与 R2023b 的 function resolution 一致。
2. `delaunayTriangulation` 和 `triangulation` 通过 `exist(name,'class')` 检查，不再把
   class constructor 伪装成普通 function dependency。
3. code 实际调用的 `pointLocation(physical_triangulation, query)` 通过
   `methods('triangulation')` 的 public method inventory 检查。该调用返回 triangle index 和
   barycentric coordinates，当前 code 没有 `cartesianToBarycentric` 调用，因而没有为
   unused symbol 制造伪 dependency。`SYMBOLS.md` 已同步 `triangulation_methods` 的职责。
4. capability probe 仍在 `SPEC_AND_ENVIRONMENT` 内、任何 mesh/eigensolve 之前 fail closed；
   没有读取 Markdown、Git、historical output 或 repository path。

以上判断是 R2023b 的静态 API 审查，不声称已通过运行验证；但不存在需要在
formal rerun 前再修复的确定 mismatch。

### M.3 CSV close/atomic-publication audit

`LOCAL_write_csv` 现在用 `onCleanup(@() LOCAL_safe_fclose(file_id))` 安装 exception-path
cleanup。`LOCAL_safe_fclose` 只在 `file_id` 仍出现于 `fopen('all')` 时调用
`fclose`：

- 正常路径先显式 safe-close，紧接着 `delete(cleanup_file)` 触发的第二次
  safe-close 因 file ID 已不在 open set 而成为 no-op，不会 double-close 或复用旧 ID。
- `fprintf`、encoding 或其他中途 exception 使 function unwinds 时，cleanup 看到仍打开的
  ID 并只关闭一次。
- 只有正常 close 并删除 cleanup object 后才执行 `.partial` to final `movefile`；异常
  路径保留 fail-closed partial semantics。

因此 `run-001` log 中的 invalid-file-identifier cleanup warnings 的确定机制已关闭，没有用
`try/catch` 吞掉无关 I/O failure。

### M.4 Authorized corrected command and frozen monitor

从 `test/i4/femref-a1/` 作为 working directory，授权且只授权以下同一科学命令，
只将 artifact label 从 `run-001` 改为 `run-002`：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-002')"
```

`run-001` 已消耗的 operational/debug time 不计入 corrected rerun；`run-002` 从 process
start 获得同一 attempt 的 fresh 30 min soft budget 和唯一最多 10 min grace。L.3 的
external monitor 规则不变：每 30 s 检查 process/RSS/progress；90 s 无 progress 只是
advisory；RSS 达 2 GiB 或 wall 达 40 min hard stop；30 min 只有在至少
$0.90\times119$ solves complete、最近五个 rates finite 且 ETA $\le 10$ min 时允许唯一
grace。不得拆分 command 或忽略 internal preflight 的 30 min/1.5 GiB launch gate。

L.4 的 terminal 解释也不变：shell exit code 0 不是 success evidence；只有 console
`REFERENCE_COLLECTION_READY` 与 `run-summary.mat`、`reference-collection.mat`、空
`failures.csv`、`completed_solves=119` 一致才是 command-level success candidate。任何其他
terminal code、external kill 或无可读 terminal artifacts 均必须在同一 attempt 内保留证据并
交同一 Skeptic 做 artifact/retry verdict，不得自动重跑。

artifact/post-run review 仍为 `NOT STARTED`；本节的授权不是 numerical success、method PASS
或 effectivity comparison 授权。

## N. Bounded operational re-review after `run-002`

本节只审查 `run-002` 的 operational stop、两处 `triangulation` constructor 参数顺序
修复及 retry eligibility。L--M 节已冻结的科学实现、resource monitor 和 terminal
判定保持不变。本次没有运行 MATLAB、Octave、Python 或任何 numerical
experiment。

### N.1 Verdict and retry classification

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。Corrected formal rerun：`run-003 AUTHORIZED`。**

`run-002` 的 preserved evidence 显示 terminal code 为 `EXECUTION_UNAVAILABLE`，stage 为
`MESH_ORACLES`，`completed_solves=0/119`，elapsed 约 $0.15$ s。log 的唯一原因是旧调用
`triangulation(points, triangles)` 把 point array 误作 connectivity，从而触发
`numtriangles-by-3` 格式错误。`work/` 没有 mesh/spectrum cache；`model.csv`、
`config.csv`、progress/failure/log 和 terminal MAT artifacts 均保留。该失败发生在任何
eigensolve 前，只证明 constructor API 的 implementation defect，没有证明 frozen mesh method
或 scientific contract 失败。

因此 `run-002` 与 `run-001` 一样不消耗 `femref-a1` attempt。保留
`output/run-001/` 和 `output/run-002/` 后，以新 explicit artifact label `run-003` 在同一
attempt directory 重跑符合 design Section 8.3 和 `test/AGENTS.md`；它不是新 attempt，也不改
science。当前 `output/run-003/` 不存在。

### N.2 Constructor audit

MATLAB `triangulation` 对二维 mesh 的调用顺序是 connectivity-first、points-second。当前
source 全文只有两处 constructor，且均与该 schema 一致：

1. mesh oracle 使用 `triangulation(triangles, points)`；`triangles` 源自
   `delaunayTriangulation(...).ConnectivityList`、为 triangle connectivity，`points` 源自
   `.Points`。构造后只调用 `edges(...)` 检查 constrained edges。
2. common-core interpolation 使用 `triangulation(mesh.triangles, mesh.points)`，与上述同一
   current-run mesh schema 一致；后续 `pointLocation` 可得 triangle indices 和 barycentric
   coordinates。

`rg` 检查没有第三处 constructor，也没有残留的
`triangulation(points, triangles)` 或 `triangulation(mesh.points, ...)` 调用。此单点修复
不改 points/connectivity 数据、mesh generation、material labels、scientific gates、solve schedule 或
artifact schema。当前没有 unresolved constructor blocker。

### N.3 Authorized command and unchanged monitor

从 `test/i4/femref-a1/` 作为 working directory，授权且只授权以下同一科学命令，
仅将 artifact label 改为 `run-003`：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-003')"
```

`run-003` 从 process start 获得 corrected rerun 的 fresh 30 min soft budget。L.3/M.4 的监控
合同完全不变：每 30 s 记录 process/RSS/progress；90 s 无 progress 只是 advisory；
RSS 达 2 GiB 或 wall 达 40 min hard stop；30 min 仅在至少 $0.90\times119$ solves
complete、最近五个 rates finite 且 ETA $\le 10$ min 时允许唯一 grace。不得拆分
command，也不得忽略 internal preflight 的 30 min/1.5 GiB launch gate。

terminal 合同仍以 artifacts 为准：shell exit code 0 不是 success evidence；只有 console
`REFERENCE_COLLECTION_READY`、`completed_solves=119`、成功 `run-summary.mat`/
`reference-collection.mat` 和空 `failures.csv` 一致，才是 command-level success candidate。任何
其他 terminal code 或 external interruption 均必须保留在同一 attempt 并交同一 Skeptic
审查；不授权自动再跑。

artifact/post-run review 仍为 `NOT STARTED`；本节不产生 numerical、method 或 effectivity
verdict。

## O. Post-run audit of `run-001`--`run-003`

本节是同一 Skeptic 的首个 post-run artifact/budget/retry audit。审查对象是三个已停止
runs 的 preserved output、Code Runner 提供的 external wall/RSS ledger，以及 current source 中
`MESH_ORACLES` 的 publication boundary。本次没有运行 MATLAB、Octave、Python 或
任何 numerical experiment，也不修改 design/code。

### O.1 Post-run verdict

**Verdict：`REVISE`。Confidence：high。`run-003` 不是可验收的完整 scientific
failure；`run-004` 当前 `NOT AUTHORIZED`。**

`run-003` 确实 fail closed：它以 terminal code `MESH_QUALITY_UNRESOLVED` 在首个 bulk mesh
上停止，没有 eigensolve、没有空缺后继科学 stage，也没有产生伪 reference
collection。然而 design Section 9.1 要求每个 reached stage 先发布 stage artifact，Section
10.2 明确要求 mesh stage reached 时存在 `mesh-ledger.csv` 和 `seam-checks.csv`。
`run-003` 两者都缺失。

当前 `LOCAL_build_mesh` 在计算 reflection stiffness/mass defects 后直接抛出；
`LOCAL_mesh_oracles` 因此没有收到 mesh，也没有 append 该 row；main 只在整个
`LOCAL_preflight_audit` 正常 return 后才写 mesh/seam artifacts。故 preserved evidence 只能说
“oracle 报错”，却不能审查实际 reflection defects、threshold exceedance、mesh counts 或已到达的
quality diagnostics。这使 post-run review 无法区分 genuine frozen-mesh limitation、assembly asymmetry 与
diagnostic/publication bug。

因此本轮分类为 **scientific gate 上的 artifact-schema/implementation failure**，而不是已执行
完整且可审查的 scientific negative。它不消耗 `femref-a1` attempt，但也不允许在当前
source 上直接启动 `run-004`。

### O.2 Artifact and stage audit

| Run | Terminal / stage | Reached solves | Preserved evidence | Current classification |
|---|---|---:|---|---|
| `run-001` | `DEPENDENCY_UNAVAILABLE` / `SPEC_AND_ENVIRONMENT` | 0/119 | log, progress, failure, terminal MATs | capability-probe operational failure；M 节已审查，不消耗 attempt |
| `run-002` | `EXECUTION_UNAVAILABLE` / `MESH_ORACLES` | 0/119 | model/config, log, progress, failure, terminal MATs | constructor operational failure；N 节已审查，不消耗 attempt |
| `run-003` | `MESH_QUALITY_UNRESOLVED` / `MESH_ORACLES` | 0/119 | model/config, log, progress, failure, terminal MATs；`work/` 空 | gate fail closed，但 reached mesh ledgers 缺失；schema/implementation failure，未构成完整 scientific negative |

`run-003` 缺失 `bulk-*`、`spectrum-*`、branch、resolution 和 `fields.mat` 是正常的，因为
相应 stages 从未 reached。`resource-preflight.csv/.mat` 缺失也不是独立 schema defect：
preflight 只在全部 mesh oracles 完成后才能基于九个 meshes 形成，本次在第一 mesh 已
停止。真正的 blocker 是 mesh stage 已 reached，但它自身的失败 diagnostics 没有发布。

shell exit code 0 没有被当作 success；console、`failures.csv` 和 progress 一致指向
`MESH_QUALITY_UNRESOLVED`。L.4 的 terminal-artifact authority 在本次得到正确应用。

### O.3 Budget ledger

Code Runner 提供的 external `/usr/bin/time` ledger 为：

| Run | External real time | Maximum RSS | Solves | Budget verdict |
|---|---:|---:|---:|---|
| `run-001` | 13.22 s | 689,618,944 bytes | 0/119 | well below 30 min / 2 GiB；operational time 不计入 corrected rerun |
| `run-002` | 13.57 s | 709,017,600 bytes | 0/119 | well below 30 min / 2 GiB；operational time 不计入 corrected rerun |
| `run-003` | 13.16 s | 735,887,360 bytes | 0/119 | well below hard limits；没有完成 internal resource preflight |

三次都没有触发 grace、2 GiB RSS 或 40 min hard stop。这些数字只说明早期 operational/
schema stops 本身没有超资源，**不能**用来验证 119-solve complete run 的 29.8 min /
1.2 GiB forecast。该 resource condition 仍未被 formal preflight 实际触达。

### O.4 Finding 1 — `BLOCKER`：reached mesh failure diagnostics 未发布

- **Location：** `run_i4_1a.m` main lines 80--84，`LOCAL_mesh_oracles` lines 726--746，
  `LOCAL_build_mesh` reflection gate lines 879--888；design Sections 9.1 and 10.2。
- **Evidence：** `run-003` 已进入 `MESH_ORACLES` 并命中第一 mesh 的 reflection gate，但
  目录中没有 `mesh-ledger.csv` 或 `seam-checks.csv`。helper 在 return/row append 前 throw，
  main 的写出 boundary 不可达。
- **Consequence：** 失败的主要数值证据丢失；无法判定 oracle exceedance 的大小、是
  $K$、$M$ 或两者失败，也无法审查前置 constraint/quality counts。这阻止将
  `MESH_QUALITY_UNRESOLVED` 解释为 frozen method 的可复现 scientific negative。
- **Uncertainty：** reflection failure 可能是真实的 deterministic mesh limitation；当前证据不足以
  接受或否定它。缺证据本身不证明 oracle 是假的，但它违反当前 failure-artifact
  acceptance contract。
- **Cheapest decisive repair：** 使 mesh stage 在 expected quality/oracle failure 时返回或 checkpoint
  reached diagnostic row、first code/reason，由 main 原子发布 `mesh-ledger.csv` 及
  `seam-checks.csv`（未到达 phase/seam check 时可为带 header 的空 ledger），然后重抛同一
  `MESH_QUALITY_UNRESOLVED`。必须保留 actual reflection stiffness/mass defects 与 mesh identity；
  不得改 triangulation、tolerance、oracle、mesh schedule 或将失败降级为 warning。

### O.5 What survived and claim boundary

1. source 没有在 mesh failure 后继续 bulk/defect solves，也没有非空 reference collection 或
   fields；first-failure/fail-closed direction 仍然正确。
2. `run-001` 和 `run-002` 的 operational classification 保持不变；其修复后证据没有显示
   新的 dependency/constructor blocker。
3. `run-003` 唯一支持的数值观察是：当前实现在 `bulk-s12-g24` 的冻结
   reflection gate 处停止。由于 defects 未发布，不得声称 polygon-fitted FEM 科学上
   不可行，也不得声称 mesh symmetry 已通过或已定量失败。
4. 三次均没有生成 bulk gap、guided-mode eigenvalue/field、branch inventory、
   $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 或 effectivity evidence。不存在可同步到项目 STATUS/report 的
   numerical claim。

### O.6 Minimal next action and retry authority

同一 Engineer 只可做 O.4 的 bounded failure-publication repair，不得改科学 mesh/oracle 或实验
schedule。修复后必须交同一 Skeptic 做静态 schema/failure-path re-review。当前 **不授权
`run-004` 或任何新命令**。

若 bounded repair 通过，同 attempt 的 future `run-004` 才可获得 fresh corrected-run budget。若它在
未改科学 oracle 的条件下再现同一 reflection failure，且原子发布完整 reached-mesh
diagnostics，届时应把它审查为可能的完整 scientific negative；不得再以 operational retry
自动跑下一 ID。

Open-problem handoff：`I4.1a / implementation / BLOCKER / reached MESH_ORACLES failure lacks
required mesh and seam ledgers / blocking run-004 / cheapest check: bounded publication repair then
same-Skeptic static review / suggested status OPEN`。本 Skeptic 不修改 project ledger 或 STATUS。

## P. Bounded mesh-failure publication re-review

本节只审查 Engineer 对 O.4 的 bounded repair：21-column mesh ledger、逐 mesh checkpoint、
expected failure 的 actual diagnostic publication、seam/resource reached semantics，以及 `run-003`
preservation 和 `run-004` eligibility。O 节保留为 post-run 审查历史。本次没有运行
MATLAB、Octave、Python 或任何 numerical experiment，也不修改 design/code。

### P.1 Verdict

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。Corrected formal rerun：
`run-004 AUTHORIZED`。**

O.4 的 artifact-schema blocker 已关闭。expected mesh/oracle failure 现在先形成包含 mesh
identity、last reached boundary、actual reached diagnostics 和 immutable first code/reason 的 row，再原子
发布 `mesh-ledger.csv` 与 header-complete `seam-checks.csv`，最后重抛原 scientific code。
该修复没有改 triangulation、mesh points/connectivity、material assembly、reflection tolerance/oracle、
schedule 或 failure interpretation。

当前没有 unresolved publication blocker。本 verdict 只授权同 attempt 的 corrected
`run-004`；不预判 reflection gate 会通过，也不把 future 同码失败预先当作
operational failure。

### P.2 Header, rows, and first-failure semantics

1. `artifacts.mesh_rows` 和 `LOCAL_mesh_oracles` 均初始化为 `cell(0,21)`。
2. `mesh-ledger.csv` header 共 21 columns：原 18 个 mesh/geometry/reflection fields，加
   `reached_boundary`、`first_failure_code`、`first_failure_reason`。
3. `LOCAL_mesh_diagnostic_row` 以相同顺序构造 21 个 values；成功-pending、成功-complete
   与 partial-failure rows 共用该唯一 constructor，没有另一个异宽 row path。尚未到达的
   diagnostics 保持 `NaN`，不猜测数值。
4. `LOCAL_checkpoint_mesh_failure` 先将同一 first code/reason 附到以前已达 mesh rows 的
   columns 20--21，再 append 当前 partial row，然后写两个 reached-stage CSV。这保留
   single first-failure semantics，不会把之前成功 mesh 冒充为当前失败 mesh。

### P.3 Checkpoint-before-raise audit

所有 source-owned expected mesh gates（signed area、constraint edges、angle/interface、reflection node、
reflection matrices、finest geometry）都按以下顺序执行：设置 exact reason，调用
`LOCAL_checkpoint_mesh_failure(...)`，然后 `LOCAL_raise(...)`。periodic/seam helper 的
`QUASIPERIODIC_SEAM_UNRESOLVED` 也在 rethrow 前 checkpoint。

对 `run-003` 命中的 reflection-matrix path：

- `reflection_stiffness_defect` 和 `reflection_mass_defect` 先由 assembled $K/M$ 计算；
- 两个 actual values 在 gate 判断前写入 `mesh_diagnostic`；
- failure row 的 boundary 冻结为 `REFLECTION_MATRIX_ORACLE`，code 保持
  `MESH_QUALITY_UNRESOLVED`；
- `LOCAL_checkpoint_mesh_artifacts` 通过现有 `.partial` then `movefile` writers 发布
  21-column mesh ledger 和 12-column seam ledger；在首个 mesh 尚未到达 phase reduction 时，
  seam file 为 header-only，诚实表示 not reached。完成 seam 的 earlier meshes 则保留已有 rows。

完整 `resource-preflight.csv/.mat` 仍只在全部九个 mesh oracles 正常 return 后形成；
partial mesh failure 不伪造 incomplete resource forecast。这与 O.2 的 reached-stage 判断一致。

### P.4 Preservation and retry eligibility

`output/run-003/` 仍只包含当时保留的 model/config/progress/failure/log/terminal MAT
artifacts，没有事后补造 `mesh-ledger.csv`、`seam-checks.csv` 或 resource artifacts；文件集、
sizes 和 modification times 与 post-run audit 时一致。因此 run evidence 没有被 source repair
覆盖。`output/run-004/` 当前不存在。

`run-003` 依照 O 节的 classification 不消耗 `femref-a1` attempt；当前 repair 仅修复
failure publication。因此以新 explicit `run_id=run-004` 在同一 attempt directory 做一次
corrected rerun 符合 `test/AGENTS.md`。

### P.5 Exact command and unchanged monitor

从 `test/i4/femref-a1/` 作为 working directory，授权且只授权：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-004')"
```

L.3/M.4/N.3 的 external monitor 不变：从 process start 起每 30 s 记录 process/RSS/
progress；90 s 无 progress 只是 advisory；RSS 达 2 GiB 或 wall 达 40 min hard stop；
30 min 仅在至少 $0.90\times119$ solves complete、最近五个 rates finite 且 ETA
$\le 10$ min 时允许唯一 grace。internal preflight 的 30 min/1.5 GiB launch gate 仍然必须
fail closed。

shell exit code 0 仍不是 success evidence。若 `run-004` 再现
`MESH_QUALITY_UNRESOLVED`，必须停止并交同一 Skeptic 审查新 mesh/seam ledgers；不得自动
启动 `run-005`。只有 console `REFERENCE_COLLECTION_READY`、`completed_solves=119`、
成功 terminal MATs 和空 `failures.csv` 一致，才是 command-level success candidate，且仍需
post-run artifact verdict。

artifact/post-run numerical review 在 `run-004` 停止前不继续；本节不生成新的 numerical、
method 或 effectivity claim。

## Q. Final post-run audit of `run-004`

本节是 I4.1a M1/femref-a1 的最终 post-run artifact、budget、retry、numerical 与
claim-boundary audit。审查对象是 authorized `run-004` 的 preserved artifacts、Code Runner
external command/resource record，以及 P 节冻结的 terminal 合同。本次没有运行 MATLAB、
Octave、Python 或任何新 numerical experiment，也没有修改 method/design/code/output。

### Q.1 Final verdict

**Artifact/review verdict：`PASS`。Scientific outcome：
`MESH_QUALITY_UNRESOLVED / VALID SCIENTIFIC NEGATIVE / FROZEN M1 METHOD FAILED`。
Confidence：high。Attempt：`CONSUMED`。Further retry：`NOT AUTHORIZED`。**

`PASS` 表示 `run-004` 完整执行了冻结的 fail-closed 合同并产生足以审查的
negative artifact；它不表示 FEM reference 成功。实际科学结果是：第一个冻结
`bulk-s12-g24` mesh 的 assembled mass matrix 失败 reflection hard oracle，因而 M1 不能
形成合法 discrete eigenproblem，在任何 eigensolve 之前终止。

这不再是 operational/schema failure。P 节要求的 partial diagnostics、first code/reason、
mesh/seam ledgers 和 terminal artifacts 全部存在并相互一致。对 deterministic frozen mesh
重复不变运行不会增加当前验收标准所需证据；任何改 connectivity generator、
triangulation rule、mass assembly、reflection tolerance 或 oracle 都超出 operational retry，需要新的
scientific design/review authority。

### Q.2 Command, terminal, and artifact completeness

Code Runner 记录的 exact command 为：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-004')"
```

shell exit code 为 0，但本审查按 L.4/P.5 不将其当作 success。`matlab.log`、
`progress.csv` 和 `failures.csv` 一致给出：

- terminal code：`MESH_QUALITY_UNRESOLVED`；
- reached stage：`MESH_ORACLES`；
- message：`bulk-s12-g24 constrained triangulation breaks the reflection oracle.`；
- completed/planned solves：`0/119`。

Reached-stage artifact matrix 完整：

| Artifact | Audit result |
|---|---|
| `model.csv`, `config.csv` | present；frozen model ID/digest 与 reflection tolerance $5\times10^{-11}$ 可审查 |
| `progress.csv`, `failures.csv`, `matlab.log` | present；stage/count/code/reason 一致 |
| `mesh-ledger.csv` | present；header 和唯一 data row 均为 21 columns |
| `seam-checks.csv` | present；12-column header only，诚实表示 failure 发生在 phase/seam oracle 前 |
| `run-summary.mat`, `reference-collection.mat` | present；terminal failure artifacts；没有伪 qualified collection |
| `work/` | empty；失败 mesh 未被 cache 成可用 scientific object |

`resource-preflight.csv/.mat` 不存在是合法 reached semantics：完整 resource audit 需要九个
mesh oracles 全部通过，而 run 在第一 mesh 停止。bulk bands/gaps、defect spectrum、
branch/coverage/resolution ledgers 和 `fields.mat` 均属未 reached stages，其缺失不是 schema
defect。

### Q.3 Mesh-oracle numerical audit

`mesh-ledger.csv` 的唯一 row 完整记录：

| Quantity | Value | Frozen-gate interpretation |
|---|---:|---|
| mesh | `bulk-s12-g24` | first frozen bulk mesh |
| nodes / triangles / constraints | 233 / 416 / 72 | reached and recorded |
| minimum angle | $5.4213544486562171^\circ$ | passes $3^\circ$ minimum |
| area deficit | $0.011384070534630863$ | diagnostic only at this coarse polygon level |
| Hausdorff defect | $0.0017110277252379237$ | diagnostic only; finest-only cap not invoked here |
| missing constraints / cross-interface triangles | 0 / 0 | both gates pass |
| $\operatorname{nnz}(K)$ / $\operatorname{nnz}(M)$ | 1309 / 1529 | assembled matrices reached |
| reflection defect of $K$ | $2.410043158511017\times10^{-15}$ | passes $5\times10^{-11}$ |
| reflection defect of $M$ | $0.014666412555809508$ | fails $5\times10^{-11}$ by about $2.9\times10^8$ |
| reached boundary / code | `REFLECTION_MATRIX_ORACLE` / `MESH_QUALITY_UNRESOLVED` | exact frozen first failure |

这不是 tolerance-scale ambiguity：stiffness reflection 通过，mass reflection 大幅失败。一个便宜的
重复运行无法修复 deterministic mesh/mass object，也不改变冻结 hard gate。根因可能与
constrained-Delaunay connectivity 的 reflection pairing 或 weighted mass assembly 在该 connectivity 上的
非对称性有关，但当前目标不需要先区分两者：无论哪种原因，冻结 M1 产生的
discrete pair 都不符合必须的 reflection oracle。

### Q.4 Budget and retry ledger

`run-004` 的 external resource record 为：

| Metric | Value | Verdict |
|---|---:|---|
| real wall time | 15.90 s | below 30 min soft limit; no grace |
| maximum RSS | 664,223,744 bytes | below 2 GiB hard limit |
| peak memory footprint | 496,915,520 bytes | below 2 GiB hard limit |
| eigensolves | 0/119 | stopped correctly before invalid mesh could enter solver |

该数据不验证 119-solve 的 29.8 min / 1.2 GiB forecast，但资源不是本次失败
原因。没有触发 30 min grace、40 min wall 或 2 GiB RSS hard stop。

最终 retry ledger：

| Run | Classification | Attempt effect | Next authority |
|---|---|---|---|
| `run-001` | false dependency probe; operational | not consumed | bounded fix led to `run-002` |
| `run-002` | constructor API error; operational | not consumed | bounded fix led to `run-003` |
| `run-003` | scientific gate reached but required failure ledgers absent; schema/implementation | not consumed | bounded publication fix led to `run-004` |
| `run-004` | complete, reviewable `MESH_QUALITY_UNRESOLVED` under unchanged frozen oracle | **attempt consumed** | no same-method retry; no `run-005` authorized |

`femref-a1` 到此关闭。不得通过新 run ID 、重复相同命令、放松 reflection tolerance、
删除 oracle 或修改 mesh connectivity 继续该 attempt。若项目未来选择 symmetric-mesh variant、
alternative FEM/RtR/DtN 或其他 reference route，必须先由 Researcher 做新 design，经独立
Skeptic review，并按 `test/AGENTS.md` 使用新 attempt authority。本 review 不自动授权该
扩展。

### Q.5 Final claim boundary

Allowed claims：

1. 冻结的 polygon-fitted constrained-Delaunay M1 在第一 `bulk-s12-g24` mesh 的
   mass-reflection oracle 处合法 fail closed；完整 diagnostics 如 Q.3。
2. `run-004` 是可复现、可审查的 early scientific negative，它证明当前 frozen M1
   未能产生合法 reference eigensolver input。
3. 本 run chain 在 wall/RSS hard limits 内停止，且没有使 invalid mesh 进入 eigensolve。

Prohibited claims：

- 不得声称 FEM 方法族普遍不可行，不得否定 continuous guided mode 存在；
- 不得声称已得到 bulk gap、guided-mode eigenvalue/field、branch collection 或
  $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$；
- 不得做 estimator/reference 位置比较、effectivity validation 或任何 I4.2 结论；
- 不得把 early-run RSS/time 当作 complete 119-solve resource validation。

### Q.6 Project-document synchronization and next action

post-run review 现已完成，因此允许对 project research documents 做**最小、经验证的失败
状态同步**：

- I4.1a M1/femref-a1 以 valid `MESH_QUALITY_UNRESOLVED` 终止，attempt consumed；
- 失败位于 first mesh mass-reflection oracle，0/119 eigensolves，没有 reference collection；
- I4.1 reference/effectivity 仍未验证，future route 需新 design/review authority。

建议只同步到 I4 `README.md` 和 project `STATUS.md`，并链接本 review 作详细证据；若
existing project-level `open-problems.md` 没有同类项，可由主 agent 记录“需新 independent
reference route”。不应修改 method manuscript 的理论公式，不应创建 effectivity/report
claim，也不应在尚未选定 future route 时提前写入 `DECISIONS.md`。

最终 next action：**停止实验链，不授权 `run-005` 或任何 same-method retry；由主 agent
仅做上述 project status sync。**

## R. Independent review of prospective design §15

本节审查
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a §15]] 在后续 user
direction 下建立的 prospective same-method mesh-implementation repair contract。审查对象仅为
§15 的前瞻授权、freeze、allowed/prohibited scope、diagnostic 和 preformal gates。Q 节的
`VALID SCIENTIFIC NEGATIVE / FROZEN M1 METHOD FAILED / ATTEMPT CONSUMED` 及 run-001--004
artifacts 全部保留为历史权威。本次没有运行 MATLAB、Octave、Python，没有审查
或修改 implementation，也没有创建文件或目录。

### R.1 Verdict and present authority

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。Unresolved `BLOCKER`：none。**

本轮 user authority 明确允许将 future mesh-connectivity/material-pair repair 前瞻性重分类为
same-method implementation repair。§15 忠实实现该授权：它只改 future action authority，不否定
run-004 当时的 complete negative artifact，不把 Q 节 `PASS` 改写为 reference success，也不
追溯将 consumed attempt 记为 unconsumed。Git diff 显示 design 只在旧文末追加 §15，没有删除
或改写原 sections。

§15 给出的 prospective exception 只允许 Engineer 实现原 design 已要求的
reflection-closed fitted mesh；不允许 diagnostic 或 formal MATLAB run。因此本 Skeptic **明确
授权同一 Engineer 开展第 15.3 节的 bounded implementation repair 和 diagnostic plumbing**，
但 **不授权运行第 15.5 节 diagnostic，不授权 `run-005`，也不授权任何
MATLAB/Octave/Python numerical command**。

### R.2 Historical boundary and reclassification audit

1. §15.1 明确链接 Q 节，逐字保留 run-001--004 artifact/retry ledger 和当时
   `M1 FAILED / ATTEMPT CONSUMED` verdict；该修订没有赋予 run-004 新数值含义。
2. Established evidence 仍只是 run-004 的 $K/M$ reflection defects、$5\times10^{-11}$
   threshold 和 $0/119$ eigensolves。Delaunay tie-breaking 或 material pairing 作为根因仍标为
   `PROVISIONAL`，没有把推测提升为事实。
3. 当前 user-authorized prospective repair 是对 future work 的窄例外：历史上“attempt consumed”仍是
   当时正确 verdict；future 工作则在不新建 attempt 的条件下按 §15 gates 进行。后续
   文档必须同时保留这两个时态，不得用 prospective authority 覆盖历史。

### R.3 Frozen scientific contract audit

§15.2 对本 repair 不可改变的科学对象枚举完整：

- exact-circle continuous problem、$R=0.2$、$q_{\mathrm{in}}=17$、$q_{\mathrm{out}}=1$、missing
  index $0$、$\beta=0.5$ 和 frequency normalization；
- volume conforming $P_1$ FEM weak form、local stiffness 和 consistent weighted-mass formulas；
- 全部 $(s,n_\Gamma)$、$N$、$\alpha$、$\vartheta$、solver/root/tolerance/threshold gates 与
  $72+47=119$ solve union；
- raw/safe-gap、all-slice edge buffer、cluster/subspace、localization/tail、coverage、four-axis
  refinement 和 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ uncertainty rules；
- wide cue 的唯一 bulk-gap-identification 角色、information isolation、blind export/reveal gate 和
  empirical/non-certified claim boundary；
- 同一 `femref-a1` directory 与原 30 min / 2 GiB / single-grace / 40 min 合同。

因此 prospective repair 不能改 continuous eigenproblem、trial space family、branch selector、coverage target、
resolution formula 或结论强度。该 freeze 足以阻止借“mesh fix”引入 effectivity/reveal 或
nearest-root leakage。

### R.4 Property-based repair and method identity

§15.3 将 acceptance 写成 pre-assembly property contract，而不猜测特定 root cause。允许改动的只是
ordering 或 deterministic tie resolution；point coordinates、point-removal rule、disk polygon/rings、
constraint segment multiset、mesh levels 和 material rule 不变。每个 unordered triangle 必须有唯一
reflected partner，material flag 必须 pairwise 一致，且原 quality/seam/Hermitian 合同仍然 fail
closed。

更换 Delaunay tie resolution 会改变有限维 connectivity，因此后续 source diff 必须受严格审查；
但在本轮 user 明确的 prospective reclassification 下，它不是新 method，原因是：

1. old design 本就要求 reflection-invariant deterministic fitted mesh，而未冻结唯一 tie algorithm；
2. node/constraint/material/weak-form 数据与所有 refinement axes 不变；
3. repair 在 assembly 之前用 combinatorial closure 验收，而不在 assembly 之后修饰 matrices；
4. formal run 仍从 source 重建 meshes 并重跑全部原 oracles。

这一 property-based boundary 允许 Engineer 选择最小实现，但不允许将一种新外部 mesher 或
新 variational problem 悄然引入 M1。

### R.5 Prohibition audit

§15.4 对最容易伪造“symmetry pass”的路径给出了足够强的排除：

1. 明禁 $K$、$M$ matrix averaging/post-symmetrization；
2. 明禁改 `LOCAL_assemble_p1` coefficients/formulas、material labeling rule、points/removal/rings/
   polygons/constraints 或 mesh levels；
3. 明禁放松 $5\times10^{-11}$ tolerance、删除/降级 reflection oracle 或只检查 $K$；
4. 明禁 external mesher/toolbox、BIE/QZ/current estimator、historical output 和信息泄漏；
5. 明禁改 cue/window/root/solver/branch/refinement/uncertainty/claim/reveal objects；
6. 明禁覆写 run-001--004、新建 second attempt 或把 diagnostic 伪装为 reference
   collection。

这些禁令关闭了容忍度放宽、后验 matrix repair、point/constraint 漂移和科学参数更改四类
最大风险。

### R.6 Diagnostic-path and lifecycle audit

Optional `test/i4/femref-a1/diagnostics/mesh-repair-001/` 是 existing `femref-a1` 内部的
debug-evidence namespace，不是 second attempt directory。它不要求新 `design-*.md`、
`review-*.md`、attempt README 或新 scientific output tree；只保存原子发布的 diagnostic
ledgers。因此它与 user 对新 design/review/attempt files/directories 的禁止兼容。

§15.5 的 diagnostic boundary 足够明确：

- 保留 one-argument formal scientific entry 的语义，diagnostic 只使用显式 debug mode；
- 只构造九个 frozen meshes、组装 matrices、运行原 quality/seam/reflection oracles 和
  resource preflight；
- 必须记录 unpaired-triangle/material-pair counts、所有原 diagnostics、$K/M$ defects、
  seam checks、$0$ eigensolves 和 wall/memory forecast；
- 禁止 `eigs`、bulk/defect/branch/coverage/resolution/reference export、current-chain 或历史
  inputs；
- 任一九-mesh property/oracle/resource gate 失败即 fail closed，不产生 `output/run-005/`；
- future formal run 不读/复用 diagnostic mesh、cache 或 artifact，而是在独立同命令 clock 中
  从 source 重建。

因为 diagnostic 显式包含 numerical mesh/matrix oracles，§15 没有把它误称为“无数值运算”；
它只是 non-eigensolve/non-scientific debugging gate。这一分类诚实。

### R.7 Findings and conditions

#### 1. `IMPORTANT CAVEAT`：future connectivity diff 必须证明零科学漂移

- **Consequence：** connectivity 本身会改变有限维 matrices；若 points/constraints/material rule/local
  formulas 也改变，repair 将越界成新 method 或科学调参。
- **Decisive later evidence：** Engineer diff 必须只落在 §15.3 allowed scope，Researcher
  theory-to-code check 必须核对 source-owned spec、point/constraint multiset、material rule、weak-form
  formulas 和 schedules 零漂移。该证据属 implementation 后 gate，不阻止当前 design pass。

#### 2. `IMPORTANT CAVEAT`：diagnostic pass 不可代替 formal-run independence

- **Consequence：** 若 formal run 读取 diagnostic cache/mesh，就会把 debug command 嵌入 scientific result、
  破坏 single-command budget 与当次重建证据。
- **Decisive later evidence：** diagnostic artifact 必须显示九 meshes、$0$ eigensolves、全 oracles
  pass 和 forecast within 30 min/1.5 GiB；后续 spec-to-code review 必须证明 `run-005`
  不读 diagnostic path 或复用 cache。该证据在本轮尚不存在，因此当前不授权
  diagnostic 或 formal run，但不阻止 Engineer 实现 plumbing。

#### 3. `MINOR CAVEAT`：diagnostic namespace 必须 create-once 且不冒充 attempt

- **Consequence：** fixed `mesh-repair-001` 若被静默覆写，会破坏 debug evidence 的可追溯性；若在其中
  新建 design/review/reference files，会混淆文件权威。
- **Cheapest later check：** diagnostic writer 对已存在路径 fail collision，只写第 15.5 节的
  ledgers；README/SYMBOLS 若需机械同步，只更新现有文件。该项不影响当前 method identity。

No `BLOCKER` is unresolved。Root-cause diagnosis 仍为 provisional，但 property-based acceptance
不依赖在当前阶段确定唯一 root cause，因而不构成 blocker。

### R.8 Preformal gates and bounded handoff

§15.6--15.7 的 gates 足以防止提前运行或用 diagnostic 替代 formal evidence：

1. Engineer 只能修改 `run_i4_1a.m` 中 mesh connectivity/tie-resolution、直接相关
   `LOCAL_` helpers、pre-assembly closure diagnostics 和最小 diagnostic dispatch/writers；现有
   `SYMBOLS.md`/attempt `README.md` 只能机械同步。
2. Engineer 完成后，同一 Researcher 必须先做 theory-to-code zero-drift check。
3. 后续 diagnostic 必须独立证明九 meshes、connectivity/material pairing、原 oracles、
   $0$ eigensolves 和 resource forecast。
4. 同一 Skeptic 必须在 diagnostic 后完成 implementation/artifact/spec-to-code review，并另行
   明确授权 formal `run-005`。
5. formal run 必须保持 run-001--004 不变、`output/run-005/` 预先不存在，以
   单条 exact command 从 source 重建九 meshes，共享原 30/40 min 和 2 GiB 合同。
6. 任一 mesh/oracle/preflight gate 失败即在 eigensolve 前返回 Skeptic，不自动授权
   `run-006`。

当前 handoff 仅为：**Engineer implementation repair and diagnostic plumbing authorized**。不允许创建
新 design/review/attempt files or directories，不允许覆写历史 artifacts，不允许运行 diagnostic，
不允许创建 `output/run-005/`，不允许执行或授权 formal command。

## S. Pre-diagnostic independent spec/code review after design §17

### S.1 Audit frame and verdict

本节审查 [[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a
§§15--17]]、`test/i4/femref-a1/run_i4_1a.m`、`README.md` 和 `SYMBOLS.md`
的完整 working-tree diff，以及 diagnostic/formal 共享 helper 的静态调用链。当前 gate 的成功标准是：
bounded repair 恢复冻结的 reflection-closed fitted mesh，diagnostic 可在不调用 `eigs`、不读取历史或
current-chain 信息且不复用 cache 的条件下，独立产生九网格 pre-eigensolve evidence。审查时确认 cwd
为 `/Users/whc/Documents/Work/epost`、branch 为 `codex/epost`；没有运行 MATLAB、Octave、Python，
没有创建 diagnostic/output，也没有修改 design、implementation、documentation 或历史 artifact。

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。Unresolved `BLOCKER`：none。**

本 verdict 只授权一次 create-once mesh diagnostic；它不是 scientific/reference run 的授权。
Q 节及 run-001--004 的历史 verdict、artifact 和 attempt-consumption 结论保持不变，`run-005`
继续 `NOT AUTHORIZED`。

### S.2 Scope, method identity and zero-drift audit

完整 diff 的实质 source hunks仅包括：two-input diagnostic dispatch、diagnostic publication、
21-to-36-column mesh ledger migration、`LOCAL_build_mesh` 中 assembly 前的 reflection tie repair 与
planar/material closure gates，以及直接服务这些对象的 `LOCAL_` helpers。`README.md` 和
`SYMBOLS.md` 只作 interface/ledger 机械同步。未发现下列冻结对象发生 diff：

1. exact-circle continuous problem、physical parameters、frequency normalization、volume $P_1$
   weak form、local stiffness 和 consistent weighted-mass formulas；
2. point coordinates/removal、disk polygon/rings、constraint generation/deduplication 和
   polygon-centroid material rule；
3. 40/48 complete-return gates、$72+47=119$ solve union、bulk/defect schedule、wide cue、
   all-slice edge buffer、cluster/subspace、coverage、branch identification、four-axis refinement、
   empirical uncertainty、information isolation 和 claim/reveal boundary；
4. `coordinate_tolerance=10^{-13}`、`constraint_tolerance=2\times10^{-12}`、
   `reflection_tolerance=5\times10^{-11}`、resource caps 及其他 scientific gates。

没有 matrix averaging/post-symmetrization、tolerance relaxation、point/constraint/formula/parameter
改动，亦没有 external mesher、BIE/QZ、current estimator 或 reference input。修复只在原
constrained-Delaunay connectivity 上保留已闭合 triangle orbits，并以 negative-$x$ centroid
代表生成缺失 reflection partner；centered 或左右 inventory 不平衡、duplicate、coverage-area defect
均 fail closed。最终 connectivity 还必须通过独立 planar-complex、unique partner、material-pair 和
assembled $K/M$ reflection oracles。因此这仍是 §15 已授权的 same-method implementation repair，
不是新连续模型或 M2。

### S.3 Implementation and schema audit

1. **Reflection and planar-complex gates.** `reflection_index` 在 repair 前由冻结 point set 构造；
   constraints 必须在 reflection 下闭合。repair 后依次检查 strictly positive signed area、unordered
   triangle uniqueness、edge incidence、outer-boundary 双向集合相等、frozen constraint retention、
   nonincident-edge intersections 和 single triangle component。material classification 之后又检查
   unique reflected triangle partner 和 pairwise material equality；assembly 后原 $K/M$ reflection
   defects 仍以 $5\times10^{-11}$ fail closed。intersection sweep 的 lower-$x$ stop 和 $y$-box
   pruning 不会跳过 bounding boxes 可能相交的 pair；absolute orientation tolerance 对本冻结坐标尺度是
   保守的 near-touch failure rule。
2. **36-column contract.** Header、initial row、success row 和 failure checkpoint 均为 36 columns。
   Columns 19--23 是 repair/reflection/material fields，24--33 是 planar fields，34 是
   `reached_boundary`，35--36 是 first code/reason。seam completion 只写 column 34，failure
   propagation 只回填 35--36。diagnostic `closure_pass` 对九 rows、九 seam rows以及 columns 19--33
   作一致映射；constraint、quality、matrix 和 seam failures 则由 shared builder 在返回九 rows 前直接
   fail closed。
3. **Create-once and atomic publication.** Entry 先确认 final diagnostic ID 不存在，再成功创建
   system-temporary work area，之后才 claim `diagnostics/mesh-repair-001/`。每个 CSV/MAT 通过
   `.partial` 后 move 发布；catchable failure 进入 terminal summary。temporary cache 由 cleanup
   删除，formal one-input path 不含 `diagnostics` read。
4. **Zero-eigensolve control flow.** Exact two-input dispatch 调用 `LOCAL_run_mesh_diagnostic` 后立即
   return。其静态 call chain止于 `LOCAL_preflight_audit`、mesh/seam oracles、`symbfact` 和 resource
   forecast；唯一 `eigs` call 位于未被该路径调用的 `LOCAL_low_spectrum`。summary 固定
   `completed_eigensolves=0`、`reference_exported=false` 和 non-reference claim boundary。
5. **Isolation.** Diagnostic 只加载其 system-temporary current-command mesh caches；source 中没有
   Markdown、Git、历史 output、BIE/QZ/current-estimator/reference read。formal path 只使用
   `output/<run-id>/work/` 的 current-run caches，从 source 重建九 meshes，不读取或复用 diagnostic
   artifacts。
6. **Resource fail-closed behavior.** Shared preflight仍审计九 meshes、40/48 workspaces、symbolic
   fill、current-run cache/export buffers 和 $72+47=119$ solves。diagnostic 只在 forecast
   $\le30$ min、$\le1.5$ GiB 且全部 closure/oracle gates pass 时给出 `PASS`；其自身仍受
   30 min / 2 GiB external limits。当前 `diagnostics/mesh-repair-001/`、`output/run-005/` 和
   untracked files 均不存在；source diff 没有历史 artifact 写入路径，run-001--004 当前文件集与
   Q 节 reached-stage inventory 一致。

### S.4 Strongest challenge and classified findings

**Strongest challenge.** 最可能推翻本 gate 的 failure mode 是一个 reflection-closed 但非合法
planar complex 的 triangle soup 被当成 valid mesh。§16 已准确识别这一问题；新增 incidence、boundary、
intersection、component 和 constraint oracles 加上原 positive-area/total-area checks，在本冻结
Delaunay-plus-reflection provenance 下关闭了该 blocker。下一项决定性证据不是再扩展理论，而是运行九网格
diagnostic 并审查逐网格 ledgers。

1. **`IMPORTANT CAVEAT` — aggregate `closure_pass` 不可单独替代完整 artifact audit。**
   `closure_pass` 显式重查新增 columns 19--33，但不再次数值比较原 columns 13--18 或 seam-row
   tolerances；这些对象依靠 shared builder/phase helper 的 throw-before-return control flow 保障。
   这在静态上足以授权 diagnostic，却意味着后续 formal authorization 必须逐列复核原
   constraint/interface/$K/M$ 和 seam/Hermitian values，不能只读取 summary 的一个 boolean。
2. **`IMPORTANT CAVEAT` — 资源余量仍须由当次 evidence 证明。** Design floor 为 29.8 min，
   距 30 min gate 仅 0.2 min；新 planar sweep 的真实耗时未知。preflight 把当次九网格 elapsed 纳入
   forecast，故会 fail closed，但 diagnostic 必须由外部 process-tree/RSS monitor独立验证实际
   wall/RSS，并且不得因接近上限自动重试。
3. **`MINOR CAVEAT` — intersection orientation tolerance 是冻结尺度专用。** 当前
   $[-5.5,5.5]\times[-0.5,0.5]$ 尺度下，$2\times10^{-12}$ 的 absolute tolerance 是保守 gate；
   未来若 rescale geometry，不能未经新 freeze 直接沿用。它不影响本轮 diagnostic。

No unresolved `BLOCKER` was found。上述 caveats 只限制后续证据解释，不阻止执行最便宜的
decisive check。

### S.5 Exact diagnostic authorization and monitor contract

在 `test/i4/femref-a1` 工作目录中，**仅授权一次**以下 exact command：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('mesh-repair-001','mesh-diagnostic')"
```

Code Runner 必须每 30 s 监控 MATLAB process tree、elapsed wall 和 aggregate RSS，并保存完整 terminal
及 `/usr/bin/time -lp` record。Diagnostic 必须在 30 min 内结束，2 GiB 是 hard RSS limit；达到任一
limit 即停止并保留当前 artifact。不得 auto-retry、不得改 command/ID、不得将 shell exit code 单独当作
成功权威。`diagnostic-summary.csv/.mat`、ledgers 和 terminal record 共同决定状态；本授权不包含
`run-005`、`mesh-repair-002` 或任何 formal/scientific command。

### S.6 Required post-diagnostic artifact gate

在考虑 formal authorization 前，同一 Skeptic 至少必须确认：

1. `diagnostic-summary.csv/.mat` 一致记录 `PASS`、九 meshes、$0$ eigensolves、
   `closure_pass=true`、resource forecast complete/pass、`reference_exported=false` 及冻结
   non-reference claim boundary；无 `.partial` 或冒充 reference collection 的 artifact；
2. `mesh-ledger.csv` 有 36-column header 和九个冻结 mesh IDs 各一 row；新增 repair/material/planar
   fields 全部过 gate，同时原 minimum-angle、constraint、cross-interface、Hausdorff（适用 level）和
   $K/M$ reflection fields 逐列过原 tolerance；
3. `seam-checks.csv` 有 12-column header 和九 rows，periodic pairing、corner、coordinate、seam 与
   Hermitian diagnostics 全部过原 gates；
4. `resource-preflight.csv/.mat` 的 schedule ledger 为 72 bulk + 47 defect = 119，wall forecast
   $\le30$ min、peak forecast $\le1.5$ GiB，且 external actual wall $<30$ min、peak RSS
   $<2$ GiB；
5. diagnostic 未产生 bulk/defect spectra、branch/coverage/resolution、fields 或
   `reference-collection`，未留下可供 formal 复用的 mesh cache；run-001--004 的 artifact sets/content
   未变，`output/run-005/` 仍不存在；
6. 若任一项失败，保留 create-once diagnostic evidence并返回本 review，不自动修复、重跑或创建新
   ID。只有全部通过且同一 Skeptic 完成 artifact/spec re-review 后，才可另行判断是否授权
   `run-005`。

### S.7 Minimal resolution and open-problem handoff

当前最小下一门仅是上述 authorized diagnostic 及其 artifact audit；不需要新理论、设计、attempt 或
source modification。Goal-relevant handoff 为：stage `I4.1a preformal`，category
`IMPORTANT CAVEAT`，blocking scope `formal run only`，cheapest check `nine-mesh diagnostic plus
full-column artifact audit`，建议 ledger status `PENDING DIAGNOSTIC EVIDENCE`。项目 ledger 由主 agent
维护；本 Skeptic 不在此阶段同步 project status。

## T. Post-diagnostic artifact and final preformal review

### T.1 Audit frame and verdict

本节直接审查 authorized create-once
`test/i4/femref-a1/diagnostics/mesh-repair-001/` 的全部六个 artifacts，并将其逐列对照
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a §§15--17]]、S 节的
post-diagnostic gate 和当前 `run_i4_1a.m`。审查目标是判断 same-method repair 是否已经产生足以放行
第一次 prospective formal run 的 pre-eigensolve evidence；它不审查 guided mode、reference
collection 或 effectivity，因为 diagnostic 按合同不计算这些对象。本次只使用 read-only
filesystem/Git inspection；没有运行 MATLAB、Octave、Python 或任何 experiment
command，没有修改 design/code/docs/output，也没有创建 artifact。

**Verdict：`PASS WITH CONDITIONS`。Confidence：high。Unresolved `BLOCKER`：none。Formal
`run-005`：`AUTHORIZED`。**

Diagnostic 充分证明九个冻结 mesh implementations 满足 preassembly planar/reflection/material
contract、assembled $K/M$ 与 seam/Hermitian oracles，并给出合格的 formal resource forecast。
该结论不推翻 Q 节的历史 negative；它只关闭 §§15--17 前瞻修复的 preformal gate。

### T.2 Command, external budget and artifact inventory

Code Runner 的 external record 给出 exact command：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('mesh-repair-001','mesh-diagnostic')"
```

terminal 为 `PASS`；external real wall 为 19.40 s，maximum RSS 为 775,766,016 bytes，peak memory
footprint 为 487,543,808 bytes。三者均远低于 30 min / 2 GiB diagnostic limits，没有 grace、kill 或
retry。内部 summary 的 6.365840875 s 只计 entry 内 diagnostic clock；它与包含 MATLAB startup/exit
的 external wall 含义不同，不构成冲突。

Diagnostic final directory 直接枚举为且仅为：

- `diagnostic-summary.csv` / `diagnostic-summary.mat`；
- `mesh-ledger.csv`；
- `seam-checks.csv`；
- `resource-preflight.csv` / `resource-preflight.mat`。

没有 `.partial`、subdirectory、mesh cache、bulk/defect spectrum、branch/coverage/resolution、fields、
`reference-collection` 或其他 scientific output。`output/run-005/` 仍不存在。当前 source 中 formal
one-input path 不读取 `diagnostics/`，diagnostic temporary work 由 system-temp cleanup 管理；artifact
集合与调用链共同支持“没有 diagnostic cache 被 formal 复用”。

### T.3 Summary-independent mesh and seam audit

`mesh-ledger.csv` 的 header 和九个 data rows 均为 36 columns，mesh ID 集合与冻结 schedule 完全一致。
逐列直接核验结果为：

1. columns 13--14 的 constraint-missing/cross-interface 均为 0；
2. columns 19、21--26、29--31 的 repair-unresolved、unpaired constraint/triangle、material mismatch、
   duplicate、invalid incidence、nonmanifold、interior-free boundary、missing outer boundary 和
   nonincident intersection 均为 0；
3. connectivity-area defect 最大为 $3.5850110758805058\times10^{-14}$，低于
   $2\times10^{-12}$；每个 mesh 的 triangle component 为 1、`planar_complex_pass=1`；
4. actual/expected outer-boundary counts逐 mesh 相等，依次为
   48、72、96、288、288、360、432、480、576；
5. minimum angle 均大于冻结的 $3^\circ$；三个 $s=24,n_\Gamma=48$ meshes 的 Hausdorff defect
   均为 $4.2821535227930422\times10^{-4}<5\times10^{-4}$；
6. stiffness-reflection defect 最大为 $5.5742785813988442\times10^{-14}$，mass-reflection defect
   最大为 $3.0644974405302783\times10^{-16}$，均远低于 $5\times10^{-11}$；
7. 九 rows 的 reached boundary 均为 `MESH_AND_SEAM_COMPLETE`，first failure code/reason 均为空，
   CSV 中没有 `NaN`、`Inf` 或 failure token。

`seam-checks.csv` 有 12-column header 和九 rows。所有 coordinate mismatch 和 seam residual 均为 0；
Hermitian stiffness defect 最大为 $2.9312934718285006\times10^{-18}$，mass defect 最大为
$2.7105054312137611\times10^{-19}$，均远低于 $5\times10^{-13}$。每 row 记录四个 corner pairs、
冻结 phase $0$ 和与 $\beta=0.5$ 一致的 corner factor。因而 S.4 所要求的原 mesh/seam/$K/M$ fields
并非只由 aggregate `closure_pass` 间接推断，而是已经逐列通过。

### T.4 Resource, zero-eigensolve and isolation audit

`resource-preflight.csv` 直接记录九个 symbolic mesh rows、elapsed preflight、67 bulk-main、5
bulk-count、20 defect-medium、27 defect-fine/corner/count 和 postprocess categories。`TOTAL` row 为：

- solve count $119=72+47$；
- estimated wall $1788$ s $=29.8$ min；
- estimated peak $1,288,490,188.8$ bytes $=1.2$ GiB；
- current-run cache/export estimate $255,984,094$ bytes。

这些值分别通过 30 min 和 1.5 GiB internal preflight caps；summary 独立记录
`resource_forecast_complete=1`、`resource_pass=1`。九 mesh reduced DOF 最大 7496、reduced nonzeros
最大 94,032，均低于冻结 caps。Forecast 仍是 implementation estimate，不是正式 119-solve runtime
measurement；这一降级在 claim boundary 中保留。

`diagnostic-summary.csv` 有 14-column header 和唯一 row，直接记录 `PASS`、mesh count 9、completed
eigensolves 0、`closure_pass=1`、`reference_exported=0`、空 failure fields 及
`NON_EIGENSOLVE_IMPLEMENTATION_DIAGNOSTIC;NOT_A_REFERENCE_COLLECTION;NO_GUIDED_MODE_OR_EFFECTIVITY_CLAIM`。
目录中没有 progress/solve/spectrum/reference artifacts；静态 call graph 在
`LOCAL_preflight_audit` 后 return，唯一 `eigs` call 仍只由 formal bulk/defect path 到达。没有发现
Markdown、Git、historical output、BIE/QZ/current estimator 或 reference input，也没有 absolute
repository dependency。

### T.5 Historical immutability and scientific zero drift

Direct filesystem subset audit枚举 run-001--004 下 28 个 regular artifact files；其 SHA-256、size、
mtime 与本 Skeptic 在 diagnostic 前记录的 snapshot 一致，四个 `work/` directories 仍为空。
提供的更广 35-entry baseline 也报告 unchanged；二者计数口径不同，但没有任何相同 path 的 digest
冲突。Q 节的 run-001--004 artifact、retry ledger、valid negative 和 historical attempt-consumed
verdict 均未被 diagnostic 改写。

Current code/doc numstat 与 S 节 pre-diagnostic snapshot 相同，diagnostic 之后没有 source change。
formal path 仍使用相同 continuous problem、physical parameters、$P_1$ weak form、local element
formulas、point/constraint/material rules、40/48 gates、119-solve schedule、branch/coverage/refinement/
uncertainty/information-isolation/claim boundaries。Diagnostic evidence 证明 repair 实现了原冻结
reflection property；它没有引入 matrix post-symmetrization、tolerance relaxation 或新 method。

### T.6 Strongest challenge and classified findings

**Strongest challenge.** 当前最可能使 formal result 不可用的风险已从 mesh validity 转为 resource
forecast error：29.8 min 距 30 min soft gate 只有 12 s，diagnostic 的 19.40 s 不能验证 119 个
eigensolves 的真实吞吐。这个风险不会使现有 preflight artifact 不可解释；冻结的 30 min objective-progress
gate、一次 10 min grace、40 min/2 GiB hard stops 能以最小代价在 formal command 内决定它。

1. **`IMPORTANT CAVEAT` — 29.8 min forecast 余量极窄。** Formal run 必须每 30 s 监控 process
   tree、aggregate RSS、`progress.csv` completed/planned count 和 ETA。30 min 后只有 artifact 给出
   objective imminent-completion evidence 时才允许唯一 10 min grace；否则停止。40 min 或 2 GiB
   无条件 hard stop。该 caveat 限制运行管理，不构成启动 blocker，因为 frozen preflight 已通过。
2. **`IMPORTANT CAVEAT` — diagnostic pass 只关闭 pre-eigensolve gate。** 它没有计算 bulk gap、
   defect eigenpair、branch coverage 或 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$。任何 reference/effectivity
   claim 仍须等待 run-005 完整 artifacts 和本 Skeptic post-run review；不得把当前 mesh pass 同步为
   reference success。
3. **`MINOR CAVEAT` — external resource record 不在 diagnostic final directory。** Exact command、
   19.40 s 和 external RSS/footprint 由 Code Runner record提供，而 machine directory只保存内部 clock
   和 forecast。当前 review 已把两条 authority 分开记录；formal post-run review 也必须保留 external
   record，不能用 internal MATLAB elapsed 代替 process wall/RSS。

No unresolved `BLOCKER` was found。

### T.7 Exact formal authorization and monitoring contract

在 `test/i4/femref-a1` 工作目录中，**仅授权一次**以下 exact first formal command：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-005')"
```

Code Runner 必须沿用每 30 s external monitor，记录 MATLAB process tree、aggregate RSS、elapsed wall、
`progress.csv`、terminal output 和 `/usr/bin/time -lp`。30 min 是 soft gate：只有 current-run artifacts
显示至少 90% solve completion且 ETA 不超过 10 min，或同等客观证据证明即将完成时，才允许一次且仅一次
最多 10 min grace。40 min 和 2 GiB 是 hard limits；达到即停止并保留 artifacts。不得拆分 command、
不得 auto-retry、不得预授权 `run-006`，也不得把 shell exit code 单独当作 success。正式 command 必须
从 source 重建九 meshes并重跑全部 oracles/preflight；任一 gate failure 都按 reached-stage artifact
返回本 Skeptic。

### T.8 Mandatory post-run artifact/review obligations

无论 run-005 success 或 fail closed，下一步只能是同一 `review-4-1a.md` 的 post-run audit，至少包括：

1. exact command、start/end、30 s monitor ledger、soft/grace/hard decision、external real/RSS/footprint、
   shell exit 与 terminal-artifact authority；
2. output collision、current-run-only work/cache、atomic publication、first failure、completed/planned solves、
   attempt/retry ledger 及 run-001--004/diagnostic immutability；
3. formal `model.csv`/`config.csv` 和九-row 36-column mesh ledger、seam ledger、resource preflight，确认
   当次独立重建而非 diagnostic cache reuse；
4. reached-stage bulk 72-solve inventory、40/48 sentinels、raw/safe gap 与 all-level/all-slice edge gates；
5. reached-stage defect 47-solve union、cluster/subspace continuation、localization/tail、coverage、mode
   identification、four-axis resolution 和 empirical $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$；
6. reference collection/fields 的 qualified 或 fail-closed status，及
   `EMPIRICAL / NOT CERTIFIED / NO EFFECTIVITY BEFORE REVEAL` claim boundary；
7. post-run verdict、unresolved blocker/caveat 和是否允许最小 project-doc sync。Post-run review 前不得
   宣称 reference success、不得 effectivity reveal、不得同步数值结论，也不得启动 `run-006`。

### T.9 Minimal resolution and open-problem handoff

当前最小下一门就是 authorized run-005 及其 mandatory post-run review，不需要代码、设计或方法修订。
Goal-relevant handoff：stage `I4.1a formal run`，category `IMPORTANT CAVEAT`，blocking scope
`reference/effectivity claims only`，cheapest next check `one monitored 119-solve formal command`，建议
ledger status `RUN-005 AUTHORIZED / POST-RUN REVIEW PENDING`。项目 ledger 仍由主 agent维护；本节不作
project-document synchronization。

## U. `run-005` post-run audit：reduced-mass definiteness stop

### U.1 Audit frame and authority

本节审查唯一 authorized formal command：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-005')"
```

审查目标是判断 first bulk entry 的 reduced-mass `chol` stop 能否作为冻结方法的合法科学阴性结果，
以及它是否消费 R--T 节 prospectively reopened work。权威链为：design §5.1 的 positive-mass gate、
§10.2 reached-stage artifact contract、§11 failure semantics；current source 中
`LOCAL_phase_reduce`/`LOCAL_low_spectrum`；`run-005` 的 machine artifacts；以及 Code Runner 的 external
`/usr/bin/time -lp` record。shell exit code 不是 terminal authority。本 Skeptic 未运行 MATLAB、Octave、
Python 或任何数值程序，也未改动 source、design 或 output。

### U.2 Direct artifact, budget and retry audit

`failures.csv` 的唯一 terminal row 是
`SPECTRUM_INVENTORY_TRUNCATED, bulk-s12-g24 reduced mass is not positive definite., BULK_INVENTORY`
（internal elapsed 6.503098333333333 s）；`progress.csv` 记录已经进入 `BULK_INVENTORY`，但 completed
solves 仍为 $0/119$。Code Runner 的 external record 是 shell exit 0、real 20.71 s、maximum RSS
790,233,088 bytes、peak memory footprint 497,751,040 bytes。它们远低于 30 min/2 GiB gates；shell 0
仅说明 MATLAB batch wrapper正常结束，不能覆盖 machine terminal failure。

Formal directory含完整 `config.csv`、`model.csv`、九-row 36-column `mesh-ledger.csv`、九-row
`seam-checks.csv`、`resource-preflight.csv/.mat`、failure-only `run-summary.mat` 和
`reference-collection.mat`，并在 `work/` 保存九个 current-run mesh caches。九个 mesh 的 topology、
material、reflection、seam 和 resource values 与 T 节 diagnostic相符；`TOTAL` 仍为 119 solves、
1788 s（29.8 min）和 1.2 GiB。没有任何 bulk eigenvalue、guided mode 或 reference result。

另一方面，directory 中没有 `bulk-bands.csv` 或 `bulk-gaps.csv`。design §10.2 明确要求二者在
bulk reached时存在；source 只有在 first `LOCAL_low_spectrum` 成功返回后才调用 bulk writer。因此
当前 failure path在进入 `BULK_INVENTORY` 后、first `chol` raise 前没有原子发布哪怕 header-only 的
reached-stage bulk ledgers。该缺失是可重复的 artifact-contract failure，不是科学阴性证据。

`run-005` 保持 append-only；本次审查没有发现 run-001--004 或 `mesh-repair-001` 被改写。由于 stop发生
在 first eigensolve前且 reached-stage schema不完整，本 run 不消费 prospectively reopened scientific
work/attempt。它仍永久占用 label `run-005`；未来若另获授权只能使用新的 run ID。

### U.3 Verdict

**Verdict: `REVISE`（high confidence）。** 当前 primary classification 是 **(b) bounded
implementation/artifact failure**；mass-definiteness stop 的具体根因仍是 **(c) unresolved**，但明确
不是 **(a) valid frozen scientific negative**。理由有两层：其一，冻结的正系数 consistent $P_1$
mass 与 full-column-rank periodic prolongation在数学上应给出 positive-definite reduced mass，而当前
generic `chol_flag` message没有发布足以解释违反该 invariant 的证据；其二，已经达到 bulk stage 却
缺少 required bulk ledgers。两项均须在接受任何 scientific failure classification前有界修订。

本 verdict 不授权 `run-006`，不授权 auto-retry，也不授权把 `run-005` 解释为没有 bulk band、没有
guided mode 或 FEM reference方法失败。

### U.4 Strongest challenge and classified findings

**Strongest challenge.** 若把一次与冻结 finite-element invariant矛盾、又缺诊断的 `chol` flag直接称为
`SPECTRUM_INVENTORY_TRUNCATED` 科学阴性，implementation defect（unused DOF、约化 support错误、assembly
defect 或 floating-point Hermitian handling）会被错误包装成 coverage failure。这样会使方法成败和
后续 attempt ledger都不可解释。

1. **`BLOCKER` — positive-definite invariant 与 terminal classification 未闭合。** Source在
   `LOCAL_low_spectrum` 中只执行 `[~, chol_flag] = chol(reduced.mass)`，随后发布 generic message；没有
   保存 `chol_flag`/failing pivot、zero row/column、nonfinite、diagonal range、active-node incidence、master
   group support 或 absolute/relative Hermitian defect。与此同时，current source的 local consistent
   mass使用正系数 $q\in\{1,17\}$；periodic map通过 `unique(canonical_node)` 产生 contiguous groups，
   prolongation每 row恰有一个 unit-modulus entry，故只要 full nodal space无 orphan DOF，$P$ 就满列秩且
   $P^*MP$ 应正定。first mesh ledger还给出 233 nodes、416 triangles、48 outer-boundary edges、valid
   edge incidences、单 component、无 interior-free edge；由
   $E=(3F+B)/2=648$ 和 $V=E-F+1=233$，这些已记录的 planar-complex invariants 与“存在未被 triangle
   使用的额外 point”不相容。现有证据因此强烈指向未诊断的 implementation/numerical representation
   failure，而非 frozen method negative。最便宜的决定性检查见 U.7；在它完成前不得升级 scientific
   claim。
2. **`BLOCKER` — reached bulk artifact contract 未满足。** `progress.csv` 已记录
   `BULK_INVENTORY stage-start`，但 design §10.2 要求的 `bulk-bands.csv` 和 `bulk-gaps.csv` 均缺失。
   Source writer位于 first low-spectrum return之后，使 `chol` failure不能发布 header/empty reached
   ledgers或 mass-gate evidence。最小 repair必须在任何 future raise前原子发布 schema-complete reached
   ledgers及有明确字段的 mass-definiteness evidence；否则 post-run audit无法区分“没有求根”与“求根后
   inventory为空”。
3. **`IMPORTANT CAVEAT` — tiny Hermitian defect 不能自行解释或修复 `chol` failure。** Mesh/seam
   artifacts证明 phase-zero reduced mass normalized Hermitian defect极小，但这既不是 positive-definiteness
   certificate，也不授权 matrix post-symmetrization、tolerance relaxation、point/constraint/formula/
   parameter更改。若 bounded diagnostic显示 failure仅来自 floating-point exact-Hermitian handling，任何
   formal-path canonicalization仍须经 Researcher specification和独立 review，不能作为“普通 bug fix”
   静默加入。
4. **`MINOR CAVEAT` — external resource evidence 与 machine terminal evidence分属两条 authority。**
   External real/RSS/footprint没有写入 final directory；machine artifact又正确记录 failure。这不妨碍
   当前 stop判定，但未来 review必须继续同时保存两者，且不得用 shell exit 0称为成功。

### U.5 Implementation audit and what survived

Defensible components仍包括：formal command从 source重建并通过九 mesh topology/material/reflection/seam
gates；current-run-only work caches和119-solve resource preflight完整；没有 evidence表明 diagnostic cache、
Markdown、Git、historical output、BIE/QZ/current estimator 或 existing reference被读取；budget没有接近
soft/hard stop；run-001--005 的 historical artifacts保持可追溯。故本次 failure不推翻同一 continuous
problem、weak form、independence或 mesh repair本身。

不能存活的 claim是 bulk spectrum、gap、guided-mode branch、four-axis resolution、
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$、reference collection 或 effectivity中的任何一个。当前唯一允许的
数值陈述是：`run-005` 在 first bulk entry、任何 eigensolve前触发 as-built reduced-mass `chol` gate；原因
尚未分类。

### U.6 Claim boundary, synchronization and attempt decision

- `run-005` 是 preserved operational/implementation artifact，不是 qualified scientific negative；
- completed/planned仍为 $0/119$，本次 wall/RSS只计入 retry history，不消费 prospectively reopened
  scientific work；
- 不得把 generic terminal code解释为 continuous FEM operator没有 spectrum、wide cue没有 gap或没有
  localized guided mode；
- 不得 reveal estimator、做 effectivity comparison，亦不得把 numerical conclusion同步到项目
  `STATUS.md`、I4 `README.md`、method/report或其他 project docs；
- 允许的 project-level状态至多是“formal run遇到未解决 implementation gate，post-run verdict
  `REVISE`”，但本 Skeptic不执行该同步。

### U.7 Minimal resolution and authorization boundary

在任何 source repair或 rerun前，先冻结一个 **zero-eigensolve、read-only/as-built mass diagnostic
obligation**。它必须针对 preserved `run-005/work/bulk-s12-g24.mat` 或从相同 frozen source重建的同一
mesh，逐项发布：

1. full point count、triangle-used point count/unused IDs、每点 triangle incidence；
2. `master_index` 的 minimum/maximum/unique count、每个 master group size，以及 prolongation的
   zero-support columns；
3. full/reduced mass 的 dimensions、`nnz`、nonfinite count、zero rows/columns、real diagonal min/max、
   absolute和normalized Hermitian defects；
4. 对 **as-built matrix** 的 two-output `chol` flag/failing pivot，以及该 pivot对应的 row/column/support
   identity；
5. terminal evidence在 raise前原子发布，并同时发布 design-required header-only `bulk-bands.csv`、
   `bulk-gaps.csv`，不运行 `eigs`、不构造 reference、也不改写 `run-005`。

本节只授权同一 Engineer作 **read-only source/artifact investigation并提出上述最小 diagnostic/repair
patch**；不授权执行新的 MATLAB diagnostic，不授权 source mutation直接落地，不授权
post-symmetrization或其他 scientific change。若 future diagnostic证明 unused/support/assembly defect，
Researcher须把最小 representation repair与 artifact schema闭合交给同一 Skeptic静态复审；若只剩
exact-Hermitian handling，则须先作显式 specification amendment。任一路径都必须在另获授权后才能运行。

**`run-006` 未授权。** 没有 automatic retry；在 diagnosis、bounded repair、theory-to-code mapping和
同一 Skeptic pre-run review全部通过前，formal chain保持停止。

### U.8 Open-problem handoff

唯一 goal-relevant handoff为：stage `I4.1a first bulk mass gate`；category `BLOCKER`；blocking scope
`scientific-negative classification, further formal run, all reference/effectivity claims`；cheapest next check
`zero-eigensolve as-built mass diagnostic plus reached-bulk schema publication`；建议 ledger status
`RUN-005 PRESERVED / IMPLEMENTATION CAUSE UNRESOLVED / RUN-006 NOT AUTHORIZED`。项目 ledger由主 agent
维护；本节不创建或修改其他文件。

## V. Design review of §18 bounded source-rebuild mass diagnostic

### V.1 Audit frame

本节只审查 design §18 是否足以把 U.7 的最小 diagnosis交给 Engineer实现。当前问题不是求 guided
mode，而是定位 `run-005` 在 first bulk entry 的 raw reduced-mass `chol` failure为何与正系数
consistent $P_1$ mass invariant冲突。成功标准是：从 frozen source重建 exact object，零 eigensolve、
零 reference/effectivity input，完整发布 node/master/$P$/full-reduced-mass/pivot证据，再 fail closed；
不得借诊断设计改变 formal representation或授权 `run-006`。审查材料包括 design §18、review §U、
current `run_i4_1a.m` 的 entry/build/assembly/periodic reduction/`chol` path、现有 CSV atomic writer合同和
R2023b `chol` API identity。未运行任何数值程序。

### V.2 Verdict

**Verdict: `PASS WITH CONDITIONS`（high confidence）。** §18 已把 U 节两个 blockers转化为一个有界、
可证伪、zero-eigensolve diagnostic specification；没有 unresolved `BLOCKER`。本 verdict 只允许实现
diagnostic/evidence plumbing。条件是 Engineer diff仍须由 Researcher作 zero-drift mapping，并由同一
Skeptic作 pre-execution spec-to-code/resource review；在该门之前 diagnostic command仍未授权。

### V.3 Strongest challenge

最强挑战是 source rebuild与 preserved `run-005` cache并非同一 byte-level input：若重建后的
`chol_flag=0`，它只能证明 current source未复现 failure，不能反推 `run-005` 的矩阵或环境发生了哪种
变化。§18.7 第 5 分支正确把该结果冻结为 reproducibility/cache/environment discrepancy，并禁止自动
formal repair/retry；因此该限制不阻止当前 diagnostic，但必须保留为 postdiagnostic claim boundary。

### V.4 Classified findings

1. **`IMPORTANT CAVEAT` — source-rebuild pass 不能关闭 historical root cause。** Diagnostic刻意不读
   `run-005/work/bulk-s12-g24.mat`，提高了 current-source独立重现性，也牺牲了对 historical cache的
   byte-level attribution。若 flag变为 0，最便宜的后续动作只能是报告 discrepancy并停在 Skeptic gate，
   不能据此称 `run-005` 已修复或 formal path可重跑。§18.7 已给出这一处理，故无 design blocker。
2. **`IMPORTANT CAVEAT` — 2 min/1.0 GiB 是 prospective estimate。** `run-005` 九-mesh preflight到
   stop的 external record为20.71 s、约0.736 GiB；本 diagnostic只构造一张 coarse mesh并保存小型 sparse
   matrices，2 min/1.0 GiB估计有直接依据。尽管如此，1.0 GiB不是实际 measurement；pre-execution
   review仍须确认新增 MAT/CSV temporary copies、partial Cholesky factor和writer peak，不得仅以低于
   2 GiB hard cap替代所冻结的1.0 GiB forecast。
3. **`MINOR CAVEAT` — `chol_flag`/partial-factor mapping需防止实现期 off-by-one。** Design冻结唯一
   `[R_partial, chol_flag] = chol(M_red)`，没有 third-output permutation、reordering或 alternate triangle；
   只有 $1\leq\texttt{chol_flag}\leq n$ 才映射为 1-based reduced/master ID，flag 0时 pivot-only fields
   空置，越界或 call未返回则 evidence incomplete。该语义足以设计，但 implementation review须逐项核对
   `R_partial` dimensions和 pivot-support row，不能把 partial-factor order或任意内部 ordering误记为
   different physical node。

### V.5 Specification and artifact audit

以下要点经审查成立：

- source identity由 `LOCAL_spec`、`LOCAL_mesh_schedule` 的唯一 ID、`kind='bulk'`、$N=0$、$s=12$、
  $n_\Gamma=24$、`LOCAL_phase_reduce(...,0,'mass-diagnostic')` 共同冻结；因此
  $\alpha=0$、$\beta=0.5$ 与 `run-005` first object一致；
- $M_{\mathrm{full}}$、$P$ 和 $M_{\mathrm{red}}$ 均来自同一次 source build，`chol`直接消费返回的同一
  sparse `reduced.mass`；禁止 copy-and-average、drop、threshold、symmetrize、regularize、shift、
  reorder或第二个 repaired verdict；
- per-node incidence/usage、master group/member、$P$ row/column support、entry modulus、full/reduced
  dimensions/`nnz`/nonfinite/zero-support/diagonal/Hermitian defect，以及 failed pivot的 master/full-node/
  triangle/$P$/mass-support trace，足以区分 U.7列出的 active-node、master/prolongation、assembly/storage
  和 raw-`chol` representation branches；exact matrices、$P$、partial factor和IDs同时保存在唯一
  `payload` 中，CSV只承担审查级 scalar/list ledger；
- header-only `bulk-bands.csv` 和 `bulk-gaps.csv` 在 mesh/mass work前创建，且 hard gates要求零 data
  rows；这补齐 diagnostic namespace的 reached-bulk evidence，但没有提前修改 one-input formal writer；
- `evidence_complete` 只在 required rows/fields、single `chol` return、pivot mapping、zero-eigensolve/
  no-reference gates及 atomic publication全部完成后成立。`MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL` 必须在
  populated evidence和 terminal summary成功发布后才 raise；pre-evidence异常保持
  `MASS_DIAGNOSTIC_INCOMPLETE`，不会伪装成 mass verdict；
- create-once `diagnostics/mass-gate-001/` 与 `output/` 分离；collision在 evidence read/write前停止，
  namespace不覆盖、不追加、不复用。Diagnostic只从 source构建内存对象，不读 run-005、旧 diagnostic、
  Markdown、design/review、Git、BIE/QZ、estimator或 reference，不输出 fields/eigenvalues/branches/
  $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$，也不留下可供 formal path复用的 cache；
- setup、build、evidence和cleanup共享一只 budget clock；30 min soft、single grace、40 min/2 GiB hard
  semantics保持。该 diagnostic不创建或消费 scientific attempt，不恢复或重写 `run-005`。

### V.6 Prohibited drift and authorization boundary

§18.5--18.7 明确把 active-DOF removal、node/master reindex、$P$ support或storage repair、matrix
post-symmetrization/averaging/thresholding/shift、pivot-rule substitution、tolerance relaxation，以及
continuous problem、weak form、geometry/material/phase、119-solve、coverage/refinement/uncertainty/
isolation/claim gates全部排除在本轮之外。即使 diagnostic找到明确 implementation cause，也只能进入新的
bounded revision/review；§18本身没有 silently authorize representation repair、formal bulk schema
patch或任何 formal run。

因此，**明确授权同一 Engineer** 仅执行以下实现工作：

1. 在 existing `test/i4/femref-a1/run_i4_1a.m` 中加入 exact
   `('mass-gate-001','mass-diagnostic')` dispatch、`LOCAL_run_mass_diagnostic`、pure evidence/pivot-support
   helpers、atomic diagnostic writers和 header-only bulk publication；
2. 对同目录 `README.md`、`SYMBOLS.md` 作 dispatch/schema/helper locator的机械同步；
3. 保持 one-input formal path、`LOCAL_low_spectrum`、formal mass computation/raise/writer placement、
   `mesh-repair-001` semantics及所有 historical artifacts不变；先提交完整 diff给 Researcher和本
   Skeptic复审。

**不授权运行** `run_i4_1a('mass-gate-001','mass-diagnostic')`；**不授权** MATLAB/Octave/Python
diagnostic、formal mass或representation repair、formal header patch、`run-006`、auto-retry、reference/
effectivity reveal或 project-doc result synchronization。

### V.7 Minimal next gate and open-problem handoff

下一门只有 implementation diff：Researcher先给 `THEORY-TO-CODE PASS` 或有界修订，同一 Skeptic随后
核对 exact dispatch、raw object identity、single-`chol` call graph、schema row/column counts、
atomic-before-raise、zero-eigs/isolation、create-once lifecycle和 static peak estimate。只有该门无
unresolved blocker，才可另行考虑授权一次 diagnostic command。

Goal-relevant handoff：stage `I4.1a mass-gate diagnostic implementation`；category
`IMPORTANT CAVEAT`；blocking scope `diagnostic execution and all later formal/reference claims`；cheapest
next check `bounded Engineer diff plus Researcher/Skeptic static review`；建议 ledger status
`DESIGN PASS WITH CONDITIONS / IMPLEMENTATION AUTHORIZED / DIAGNOSTIC RUN AND RUN-006 NOT AUTHORIZED`。
项目 ledger仍由主 agent维护。

## W. §18 mass-diagnostic pre-execution spec/code/resource review

### W.1 Audit frame

本节审查 Researcher §19 `THEORY-TO-CODE PASS` 后的 exact implementation，成功标准是 diagnostic
可以一次性重建 `run-005` first bulk mass object并发布足够的 as-built证据，而不进入任何 eigensolve、
reference或 formal repair。权威是 design §18、review §U--§V、current source及 machine-side preserved
artifact inventory；§19 conclusions只作为待核 claim。审查覆盖 complete entry dispatch、mass diagnostic
call graph、all writers/schema/gates、unchanged formal/build/assembly/periodic/phase code、README/SYMBOLS和
create-once namespace。未运行 MATLAB、Octave、Python或 diagnostic。

### W.2 Verdict

**Verdict: `PASS WITH CONDITIONS`（high confidence）。** 没有 unresolved `BLOCKER`。Implementation
满足 §18 的 zero-eigensolve、raw-object、evidence-before-raise和 isolation contract，且 prospective
resource plan低于本轮 hard budget。条件只包括 W.6 的 external monitor、create-once/no-retry合同和 W.7
postdiagnostic review；它们不授权任何 source/formal repair。

### W.3 Strongest challenge

最可能使 diagnostic失去解释力的实现 failure是 terminal order错误：若 intentional `chol` error先于
完整 evidence或 summary commit，create-once namespace会被占用却仍不能诊断 `run-005`。Current code已
关闭该路径：detail/header artifacts先原子发布，`mass-summary.csv/.mat` 随后发布，
`diagnostic-summary.mat` 再发布，`diagnostic-summary.csv` 作为最后 commit marker，最后才依据 status
raise。若 final CSV缺失，namespace按合同只能解释为 incomplete，不得使用 MAT或 shell exit补成 verdict。

### W.4 Static implementation audit and what survived

以下 spec-to-code claims经直接审查成立：

1. **Exact dispatch/source identity.** Two-input entry只接受
   `mesh-repair-001`/`mesh-diagnostic` 和 `mass-gate-001`/`mass-diagnostic`；mass branch立即 return，其他
   pair fail closed。它唯一选择 `LOCAL_mesh_schedule` 中的 `bulk-s12-g24`，assert `kind='bulk'`、
   $N=0$、$s=12$、$n_\Gamma=24$、$\beta=0.5$，再以
   `LOCAL_phase_reduce(spec,mesh,0,'mass-diagnostic')` 固定 $\alpha=0$。One-input formal semantics未变。
2. **Scientific zero drift.** Mass additions位于独立 dispatch/helper block；current
   `LOCAL_build_mesh`、`LOCAL_assemble_p1`、`LOCAL_periodic_maps`、`LOCAL_phase_reduce`和 formal
   `LOCAL_low_spectrum` 仍保留已审查的 geometry/material/$P_1$/phase/$P^*MP$行为。没有 DOF/master/
   storage repair、symmetrization、averaging、threshold、shift、alternate pivot rule或 tolerance change；
   formal bulk writer仍位于 first spectrum return后，本 diagnostic没有偷偷修 formal schema。
3. **Single raw Cholesky semantics.** Diagnostic call graph中唯一 factorization是
   `[partial_factor,chol_flag]=chol(reduced.mass)`；它直接消费本次 `LOCAL_phase_reduce` 返回的同一 sparse
   object，没有 third-output permutation、copy、reordering或 second matrix。R2023b two-output contract把
   nonzero flag定义为 natural pivot position；code只接受 finite real integer $0\le p\le n$，positive
   $p$ 直接映射 1-based reduced/master ID，0时 pivot-only fields为空/`NaN`，call error或越界使
   evidence incomplete。Partial-factor实际 dimensions/`nnz`/nonfinite另行记录，避免 off-by-one推断。
4. **Evidence sufficiency and schemas.** Node/master/matrix/pivot rows固定为9/7/14/23 columns；rows分别
   是 every full point、every unique master、exact two matrices、exact one pivot record。Summary固定26
   columns，terminal summary固定16 columns；mesh/seam和empty bulk沿用36/12/10/14-column schemas。
   Integer IDs经升序去重，pivot member incidences按升序 member-node sequence保持对应。Exact points/
   triangles/incidence/master groups/$P$/full-reduced mass/partial factor/pivot support均在唯一 MAT
   `payload`，不是只靠 CSV narrative。
5. **Header/reached/atomic semantics.** Namespace claim后首先发布 zero-row bulk bands/gaps及四个
   header-only mass ledgers。Mesh或phase failure仍可借 existing checkpoint留下 reached mesh/seam rows；
   catch把 exact `reached_boundary`和 first cause写入 terminal incomplete summary。Complete path先替换
   populated mass ledgers，再检查 required files及无 `.partial` peers，发布 mass summary，最后以
   `diagnostic-summary.csv` commit。`chol_flag>0` 的 intentional error只发生在 commit之后；writer/call/
   schema failure保持 `MASS_DIAGNOSTIC_INCOMPLETE`。
6. **Isolation and zero eigensolves.** Mass call graph不到达唯一 `eigs`、`LOCAL_low_spectrum`、formal
   cache `load`、work directory、field/branch/reference exports或 `output/` writer。它不读 run-005、旧
   diagnostic、Markdown、design/review、Git、BIE/QZ、estimator或 reference；只在内存 source-build一张
   mesh，不留下 formal可复用 cache。Hard fields保持 `completed_eigensolves=0`、
   `reference_exported=false`和zero bulk rows。
7. **Lifecycle/history.** `diagnostics/mass-gate-001/` 当前不存在；collision会在任何 evidence read/write
   前停止。Preserved `diagnostics/mesh-repair-001/`、`output/run-001`--`run-005` 均早于 current source
   mtime且未出现在 source diff；本 review没有发现历史改写。Exact run-005和§U verdict保持 immutable。
8. **Resource.** Source只新增一张 coarse mesh、$233/208$ scale sparse evidence和一个 partial factor；
   对照 run-005九-mesh到 first gate的20.71 s/约0.736 GiB external record，2 min/1 GiB plan保守且低于
   30 min/2 GiB hard limits。MAT/CSV temporary peers很小；仍须由 external process-tree/RSS monitor给出
   actual authority。

### W.5 Classified findings

1. **`IMPORTANT CAVEAT` — source rebuild仍不是 historical-cache attribution。** 若 diagnostic raw
   `chol` pass，结论只是不复现 `run-005` failure；不得自动把它解释为 current source修复或授权 formal
   retry。该 caveat由 §18.7 decision tree处理，故不阻止 diagnostic。
2. **`IMPORTANT CAVEAT` — prospective resource不是 measurement。** 2 min/1 GiB有充分静态依据，但
   external monitor仍是 wall/RSS authority；超过 W.6 caps必须停止并保留 incomplete artifacts。
3. **`MINOR CAVEAT` — existing README有两处 stale run-history wording.** Mesh diagnostic paragraph仍写
   “has not been run”，但 preserved summary明确是 `PASS`；后文“This implementation stage has not run
   MATLAB”也与 run-001--005及 mesh diagnostic的 preserved MATLAB artifacts冲突。它们不控制 execution，
   不改变 code mapping或 artifact truth，因此不是 pre-execution blocker。明确授权只在 existing
   `test/i4/femref-a1/README.md` 作机械事实修正：记录 mesh diagnostic已运行一次并 PASS、不是 reference；
   记录 historical MATLAB runs存在但截至 `run-005` completed eigensolves仍为 0，mass diagnostic尚未
   运行。不得借此改 status、science、code或其他 docs；无需重开 theory-to-code review。

No `BLOCKER` was found。

### W.6 Exact one-command authorization and monitor contract

只在 `/Users/whc/Documents/Work/epost/test/i4/femref-a1` 中授权 **一次** exact command：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('mass-gate-001','mass-diagnostic')"
```

Code Runner必须原样执行，不得加入前置 MATLAB command、改 ID/mode或拆分 budget。每30 s记录 process
tree、aggregate RSS、elapsed和 diagnostic namespace/terminal output；即使 command在 first interval内结束，
也须记录 start/final process及 `/usr/bin/time -lp`。Planned gate为2 min/1 GiB；本 diagnostic采用更保守
的 **30 min/2 GiB hard stop**，不使用 grace。达到任一 hard cap即停止并保留 artifacts。不得 auto-retry；
create-once namespace一旦出现，无论 PASS、FAIL或 INCOMPLETE都返回本 Skeptic，不得删除、覆盖、追加或
换 ID重跑。shell exit只作 launcher evidence，`diagnostic-summary.csv` terminal commit才是 status
authority。

本 authorization **不包含** source、matrix、representation、formal bulk-header或 formal mass repair；
不授权 `run-006`、任何 guided-mode eigensolve、reference/effectivity reveal或 project-result sync。

### W.7 Mandatory postdiagnostic artifact obligations

Command结束后，必须在同一 review追加 postdiagnostic audit，至少直接核对：

1. exact command、working directory、start/end、30 s monitor、external real/max RSS/footprint、shell exit、
   terminal CSV status及 hard-cap decision；
2. create-once final inventory和无 `.partial` peers；`diagnostic-summary.csv` 是否为 terminal commit，
   MAT/CSV status、identity、elapsed、failure/reached语义是否一致；
3. `mesh-ledger.csv` header+1 row/36 columns、`seam-checks.csv` header+1/12，冻结 ID、
   $\alpha=0$、$\beta=0.5$、mesh/oracle values；
4. `bulk-bands.csv` 10-column header only、`bulk-gaps.csv` 14-column header only；
5. node ledger header+full-point rows/9 columns、master ledger header+unique-master rows/7、matrix ledger
   header+2/14、pivot ledger header+1/23、mass summary header+1/26；
6. MAT top-level payload identity和 exact arrays；unused/incidence、master contiguity/groups、$P$ row/column
   support/moduli、full/reduced zero/nonfinite/diagonal/Hermitian evidence、raw flag、partial-factor dimensions及
   positive-pivot support mapping；
7. hard gates `completed_eigensolves=0`、`reference_exported=0`、zero bulk rows、`evidence_complete`，并按
   §18.7选择唯一 decision branch；
8. run-001--005和 mesh diagnostic immutability、无 output/reference/cache reuse，以及允许的 exact claim
   boundary。Postdiagnostic verdict前不得 repair或启动任何 formal run。

### W.8 Minimal handoff

下一步唯一获授权动作是 W.6 command及其 W.7 artifact review。Goal-relative ledger建议：stage
`I4.1a mass-gate diagnostic execution`；category `IMPORTANT CAVEAT`；blocking scope
`all source/formal repair, run-006 and reference/effectivity claims`；cheapest next check
`one monitored create-once zero-eigensolve diagnostic`；status
`SPEC-TO-CODE PASS WITH CONDITIONS / MASS-GATE-001 AUTHORIZED ONCE / NO REPAIR OR RUN-006`。项目 ledger
仍由主 agent维护。

## X. `mass-gate-001` postdiagnostic operational-publication audit

### X.1 Audit frame and evidence authority

本节只审查 W.6 唯一授权的 source-rebuild mass diagnostic 是否形成了可解释的持久证据。当前成功标准不是
证明 reduced mass 正定或否定 `run-005`，而是完整发布 §18 冻结的 raw $P^*MP$、single two-output
`chol` flag、node/master/support/pivot ledgers和最后 commit summary；在此之前不得进入 representation repair
或 formal retry。直接核查了 preserved `diagnostics/mass-gate-001/` inventory、terminal CSV、mesh/seam/bulk/
mass CSV 行数及 current writer/evidence call graph。Exact command、shell exit 1、external real 14.45 s、max RSS
743800832 B、peak footprint 487904192 B 来自 Code Runner 的 external record；本节没有运行 MATLAB、Octave、
Python或任何数值程序。

Terminal `diagnostic-summary.csv` 是本次 status authority：
`MASS_DIAGNOSTIC_INCOMPLETE / EXECUTION_UNAVAILABLE`，
`reached_boundary=MASS_EVIDENCE_COMPUTED`，message 为
`Function is not defined for sparse inputs`，internal elapsed 0.51799820833333332 s，completed eigensolves为0，
reference exported为false，bulk band/gap rows均为0，`evidence_complete=0`。因此 shell exit 1 与 terminal
artifact一致；不能从 `MASS_EVIDENCE_COMPUTED` 反推未持久化的 Cholesky结果。

### X.2 Verdict

**Verdict: `REVISE`（high confidence）。** 这是一个有明确 source-level mechanism 的
**operational diagnostic/artifact failure**，不是 frozen mass gate 的科学正结果或负结果，也不消费
scientific attempt。唯一 `BLOCKER` 是 required raw-mass/`chol` evidence没有被原子发布，因而 §18 decision
tree无法选择任何 scientific branch。修复是有界的，但 `mass-gate-001` create-once namespace已经被消费且
必须保持 immutable；任何 corrected diagnostic只能在新的 prospective design/review gate之后使用
append-only ID `mass-gate-002`。当前不授权 mutation、new ID、new run或 formal retry。

### X.3 Strongest challenge

最危险的错误解释是把 `reached_boundary=MASS_EVIDENCE_COMPUTED` 当成 mass verdict。它只证明
`LOCAL_mass_gate_diagnostics` 返回到 caller，随后 caller把 reached marker推进到了该值；它不证明任一
required evidence artifact已经 durable。目录中四个 final mass CSV均只有 header，另有一个 header-only
`mass-node-incidence.csv.partial`，且没有 `mass-summary.csv/.mat`。特别是没有持久化 `chol_flag`、partial
factor、matrix diagnostics或 pivot support，故当前既不能称 raw `chol` failed，也不能称 raw `chol`
passed或 `run-005` discrepancy成立。

### X.4 Classified findings

1. **`BLOCKER` — first populated node-ledger row在 scalar serialization处失败，完整 mass evidence不可达。**
   Source先以 `p_row_support = sum(spones(phase_prolongation),2)` 构造 sparse column，随后把
   `p_row_nnz = p_row_support(node_id)` 直接放入 node row第5列。该 1-by-1 value仍为 sparse numeric；
   `LOCAL_csv_value` 的 scalar branch调用 `sprintf('%.17g',double(value))`，而 MATLAB对 sparse input报出
   terminal中完全一致的 `Function is not defined for sparse inputs`。Writer先编码整行、后 `fprintf`，
   因而 failed `.partial` 只有 header，正与 first data row第5列 failure一致。Consequence是 matrix/Cholesky/
   pivot evidence与 mass summary都没有 durable publication，当前 diagnostic不可用于 §18 scientific
   classification。最便宜的 decisive repair是仅在 diagnostic evidence builder把该 count转成 full scalar，
   并静态枚举四张 mass ledger的所有 numeric cells以排除其他 sparse scalar；不得借机更改 shared generic
   CSV serializer或 formal mass path。修复后的 populated-ledger schema和 raw `chol` evidence仍需同一
   Researcher/Skeptic pre-execution gate。
2. **`IMPORTANT CAVEAT` — `mass-gate-001` 已永久占用，不能原地清理或重试。** Final terminal summary、
   header-only final files和 failed `.partial` 共同记录了 create-once incomplete run；删除 `.partial`、覆盖/
   追加 final files、复用 ID或把它补写成 complete都会破坏 append-only provenance。若后续 design明确授权
   bounded publication repair，corrected execution必须是同一 `femref-a1` scientific attempt内的新
   `mass-gate-002` namespace，而不是新 scientific method/attempt；但 §18/current dispatch只冻结001，故
   002尚未获授权。
3. **`MINOR CAVEAT` — external process record不在 diagnostic namespace内。** 14.45 s、743800832 B
   （约0.693 GiB RSS）和487904192 B（约0.454 GiB footprint）均低于2 min/1 GiB diagnostic plan，也远低于
   30 min/2 GiB hard caps；内部0.518 s与 MATLAB startup差异合理。该记录足以作本轮 budget ledger，但
   corrected diagnostic仍须重新独立监控，不能继承该 measurement。

### X.5 Artifact, retry, and implementation audit

以下内容经审查成立并保留：

- `bulk-bands.csv`、`bulk-gaps.csv` 均为 header-only；`mesh-ledger.csv` 与 `seam-checks.csv` 均为
  header+1 row，identity是 `bulk-s12-g24`、mass-diagnostic、$\alpha=0$、$\beta=0.5$；mesh/seam gates到达
  `MESH_AND_SEAM_COMPLETE`；
- 四个 final mass CSV均只有 header；唯一 `.partial` 是同样只有 header的
  `mass-node-incidence.csv.partial`；没有 `mass-summary.csv` 或 `mass-summary.mat`。这一 inventory与
  first populated node-ledger write failure一致，没有 completed evidence的歧义；
- terminal CSV/MAT仍被 catch path原子发布，且 status、zero eigensolves、zero bulk rows、no reference和
  `evidence_complete=0` fail closed；这说明 terminal lifecycle存活，但不能提升 upstream partial evidence；
- mesh/source/phase build和 in-memory diagnostic helper已到达，未进入任何 eigensolve，也没有产生
  reference、field、branch或 effectivity artifact。不存在可供 formal run合法复用的 complete mass cache；
- 这次失败源于 diagnostic-only row representation/CSV boundary，而不是 frozen continuous model、weak
  form、$P^*MP$ formula或 `chol` predicate的已证 failure。它不消耗重新开放后的 scientific attempt，
  但 create-once diagnostic ID确已消费。

### X.6 Authorization boundary and minimal resolution

当前只允许以下**只读/源级调查**，且本节已完成足以定位 blocker的最小部分：追踪第一个 populated writer、
核对 sparse/full类型传播、枚举所有 mass-ledger cell的潜在 sparse scalar，并由 Researcher把 diagnostic-local
conversion、schema invariants、new create-once ID和失败语义写成 bounded prospective design amendment。

本节**不授权**任何 code/doc/artifact mutation，不授权修改 shared `LOCAL_csv_value`，不授权删除或补写
`mass-gate-001`，不授权创建/运行 `mass-gate-002`，不授权 MATLAB diagnostic、auto-retry、formal mass/
representation repair、`run-006`、reference/effectivity reveal或 project-document synchronization。最小
推进序列是：同一 Researcher作 bounded design amendment；同一 Skeptic design review；同一 Engineer仅在
获准后实施 diagnostic-local repair和 exact 002 dispatch；Researcher theory-to-code mapping；同一 Skeptic
pre-execution spec/code/resource review。只有最后一门无 unresolved blocker时，才可另行考虑一次 exact
002 command。

### X.7 What survived and open-problem handoff

Defensible claim仅为：一次冻结 identity的 zero-eigensolve source rebuild完成 mesh/phase并在内存中计算了
mass evidence，随后在第一张 populated mass CSV的 first-row sparse scalar serialization处 operationally
failed；terminal和 partial artifacts按 fail-closed方式保留。它不是 reduced-mass definiteness verdict，
不是 `run-005` root-cause resolution，也不是 independent reference或 effectivity evidence。

Goal-relevant handoff：stage `I4.1a mass diagnostic publication repair`；category `BLOCKER`；blocking scope
`§18 mass decision branch, all representation/formal repair, run-006 and reference/effectivity claims`；cheapest
next check `bounded diagnostic-local scalar densification plus all-ledger type audit under new prospective
mass-gate-002 design`；建议 ledger status
`MASS-GATE-001 OPERATIONAL INCOMPLETE / SCIENTIFIC ATTEMPT NOT CONSUMED / NO RETRY AUTHORIZED`。项目 ledger
由主 agent维护。

## Y. Design review of §20 prospective `mass-gate-002` publication repair

### Y.1 Audit frame

本节独立审查 design §20 能否以最小 operational repair关闭 §X 的 CSV publication blocker，同时保持
`mass-gate-001`、raw mass objects、single `chol` predicate和全部 formal/scientific contract不变。成功标准
是：001及其 `.partial` 保持 immutable；002是唯一 append-only corrected namespace；所有可能从 sparse
object派生的 CSV numeric scalar在 diagnostic boundary做 value-preserving `full` normalization；写盘前有
nonmutating、schema-safe type gate；不改变 shared serializer、矩阵、求解或信息隔离。本节直接对照了
§18--§20、review §U--§X、current mass-diagnostic source call graph和 preserved 001 inventory；没有编辑
design/code/docs/artifacts，也没有运行 MATLAB、Octave、Python或任何数值程序。

### Y.2 Verdict

**Verdict: `PASS WITH CONDITIONS`（high confidence）。** 没有 unresolved `BLOCKER`。§20把已证 failure
收缩为 diagnostic-only scalar representation/publication repair，没有把它伪装成 mass/scientific repair，
也没有授权 corrected diagnostic或 formal run。Y.4的两个 `IMPORTANT CAVEAT` 是 implementation/pre-run
review必须逐项关闭的静态条件，不妨碍现在把 bounded implementation交给同一 Engineer。

### Y.3 Strongest challenge

最可能使这个修复越界或再次失效的机制不是漏掉已知 `p_row_nnz`，而是把“修复 sparse scalar”实现成
shared serializer宽松转换：那会改变 formal和所有其他 CSV的全局语义，并可能把 unintended nonscalar或
unsupported cell静默压平。§20明确禁止修改 `LOCAL_csv_value`/`LOCAL_write_csv`，把 conversion限制在五个
diagnostic evidence scalars，并要求 prepublication gate不改 value。只要 implementation严格执行这个
边界，修复不会改变 $P$、$M_{\mathrm{full}}$、$M_{\mathrm{red}}$ 或 `chol` 结论。

### Y.4 Classified findings

1. **`IMPORTANT CAVEAT` — type gate必须 schema-safe，而不能只“跳过非 numeric cell”。** §20正确要求
   numeric/logical cell只能是 empty或 nonsparse scalar，并保留 integer-list character strings；但
   implementation helper还必须显式接受 existing legitimate character cells（IDs、status、failure reason、
   claim boundary以及 semicolon lists），若选择支持 MATLAB `string`，只能接受 scalar string且不得改写
   content。其他 object/cell/struct类型应 fail closed，而不能让 generic serializer把 `class(value)` 当作数据
   发布。最便宜的 decisive check是在 static review对四张 evidence rows、mass-summary row和 terminal row
   各做 allowed-type truth table及故意 sparse/nonscalar numeric反例；不需要运行 guided-mode computation。
   这是 §20现有 nonmutating/schema gate的实现精化，不需要扩展 design或改 shared writer。
2. **`IMPORTANT CAVEAT` — 001 immutability与002 no-read必须由 call order而非意图证明。** Parameterized
   runner只能在 exact allowlist和002 create-once claim后构建 source-owned evidence；不得为了比较、迁移或
   fallback而调用 `exist/load/dir/copyfile/movefile` 访问001。001 exact invocation必须在 source build前由
   preserved collision停机。Pre-execution diff review须核对001完整 inventory（包括
   `mass-node-incidence.csv.partial`）未变，并追踪002 call graph无任何001 path read。该条件有便宜、决定性
   的 static path/call audit，故不是 design blocker。
3. **`MINOR CAVEAT` — 2 min/1.0 GiB仍是 prospective estimate。** 001实际14.45 s、约0.693 GiB RSS，002
   只增加常数级 scalar conversions/type predicates，budget有直接依据且低于30 min/2 GiB hard limits；但
   measurement不能继承。若后续获准执行，仍须独立记录完整 process tree、wall和RSS，不得 auto-retry。

No `BLOCKER` was found.

### Y.5 Representation inventory and value-preservation audit

§20冻结的五类 conversion与 current source逐项匹配：

1. `sum(spones(P),2)` 保留 sparse vector，只有 selected `p_row_support(node_id)` 转为 full scalar；既不
   densify $P$，也不改变 support count；
2. `diag(M)` 可保留 sparse vector，只有 `min(real(diagonal_values))`、
   `max(real(diagonal_values))`、`max(abs(imag(diagonal_values)))` 三个 reduction result转为 full scalar；
   empty branch仍是原 `NaN`，matrix本体和完整 diagonal均不 densify；
3. 只有 selected `M_{\mathrm{red}}(p,p)` 转为 full scalar后提取 real/imag；raw matrix、partial factor和
   natural 1-based `chol_flag`不变；
4. `size`、`nnz`、`numel`、norm、`find`/`nonzeros`后的 counts/extrema，以及 pivot row/column nonfinite counts
   是 ordinary full scalar/vector-to-scalar results；ID/support vectors在入 CSV前继续经过现有
   `LOCAL_integer_list`/`LOCAL_integer_sequence` 成为 character fields，不应被 numeric-scalar gate误拒；
5. mass-summary和terminal-summary只复用上述 full scalar、identity/status strings和boolean gates；它们仍须
   在各自 MAT/CSV commit前通过同一 nonmutating type invariant。

因此，当前 source inventory没有遗漏另一个已知 sparse scalar origin。All-row gate必须只验证类型、shape和
sparsity，不得 normalize value、flatten numeric vector、改变 list order/encoding、计算 tolerance或读取 matrix
scientific property。若任何 evidence row不安全，`MASS_EVIDENCE_REPRESENTATION_UNSAFE` 在 populated writer
前回到既有 catch并保持 `MASS_DIAGNOSTIC_INCOMPLETE`；terminal row自身不安全时不发布 MAT或CSV，缺 final
commit marker即是权威 incomplete状态。该 fail-closed semantics与001教训一致。

### Y.6 Scientific, lifecycle, isolation, and resource audit

以下 design choices经审查成立：

- `diagnostics/mass-gate-001/` 的 final/header/terminal文件和 header-only `.partial` 全部保留，不删除、
  补写、覆盖、追加、重命名、移动或重跑；002不得读、探测后复用、链接、复制或缓存001；
- corrected dispatch唯一是 exact `('mass-gate-002','mass-diagnostic')`，只允许 create-once 002 namespace；
  arbitrary suffix/prefix/fallback被排除。002 incomplete也永久占用自己的ID并返回 review；
- source identity仍是 `bulk-s12-g24`、$N=0$、$s=12$、$n_\Gamma=24$、$\alpha=0$、$\beta=0.5$；mesh、
  assembly、periodic/phase helpers与 raw sparse $P$、$M_{\mathrm{full}}$、$P^*M_{\mathrm{full}}P$ 完全复用；
- 唯一 `[R_{\mathrm{partial}},p]=\operatorname{chol}(M_{\mathrm{red}})` call、natural pivot semantics、四张
  evidence schema、MAT payload、atomic per-file publication、terminal CSV last commit和§18.7 decision tree
  保持；full-scalar normalization只改变 MATLAB storage class，不改变要序列化的数值；
- shared serializer/writer、one-input formal path、mesh diagnostic、formal headers、eigensolve schedule、
  branch/coverage/refinement/uncertainty gates和 claim boundary均明确禁止修改；002保持0 eigensolves、no
  reference/output/cache reuse，也不读 Markdown、review/design、Git、BIE/QZ、estimator或 historical output；
- 2 min/1.0 GiB plan在现有 evidence下可执行；setup、source rebuild、factorization、publication、catch和
  cleanup共享一个 budget，不能用子阶段重置。§20只登记 proposed command，未授权创建 namespace或执行。

### Y.7 Bounded implementation authorization

在没有 unresolved blocker的前提下，**明确授权同一 Engineer** 只做以下 bounded implementation：

1. 在 existing `test/i4/femref-a1/run_i4_1a.m` 中加入 exact allowlisted 002 dispatch/identity plumbing；
2. 只加入 §20.2冻结的 selected `p_row_nnz`、三个 diagonal reduction和 selected pivot diagonal
   full-scalar conversions，以及 diagnostic-only、nonmutating、schema-safe prepublication row audit；
3. 可把 existing mass diagnostic runner参数化为 exact 001/002 ID，但必须保持001 collision-before-evidence、
   no-read/no-reuse和 one-input formal path不变；不得修改 shared generic serializer/writer；
4. 只对 existing `test/i4/femref-a1/README.md`、`SYMBOLS.md` 作 exact 002 dispatch、helper locator、gate和
   nonauthorization的机械同步，不写结果或新 scientific claim。

本 authorization **不包含**创建002 diagnostic directory/artifact、运行 MATLAB/Octave/Python、运行002、
修改或清理001、修改 matrix/$P$/`chol`/formal path、`run-006`、auto-retry、reference/effectivity reveal或
project-document synchronization。Engineer完成 diff后，必须先由同一 Researcher给 theory-to-code
zero-drift结论，再由同一 Skeptic核对 Y.4 conditions、all-row schemas/call order、001 immutability和 static
resource；在该 pre-execution gate通过前，§20 proposed command仍**未获授权**。

### Y.8 Minimal handoff

Goal-relative handoff：stage `I4.1a mass-gate-002 bounded implementation`；category
`IMPORTANT CAVEAT`；blocking scope `002 execution, all mass/formal repair, run-006 and reference/effectivity
claims`；cheapest next check `bounded Engineer diff + Researcher theory-to-code + same-Skeptic static review`；
建议 ledger status
`§20 DESIGN PASS WITH CONDITIONS / BOUNDED IMPLEMENTATION AUTHORIZED / MASS-GATE-002 RUN NOT AUTHORIZED`。
项目 ledger由主 agent维护。

## Z. `mass-gate-002` pre-execution spec/code/artifact review

### Z.1 Audit frame

本节在 Researcher §21 `THEORY-TO-CODE PASS` 后审查 exact implementation是否足以执行一次 create-once、
zero-eigensolve corrected diagnostic。成功标准是：002 exact dispatch/path与001完全隔离；§20五个 conversions
只改变 CSV scalar storage class；9/7/14/23/26/16-column rows在各自 writer前 fail closed；raw $P$、mass、
single `chol`、source identity、formal path、shared serializer、atomic order和 resource contract不漂移。本节
直接核查 current source/docs、001 inventory/hash/mtime、002 absence及 historical output inventory；没有编辑
code/design/docs/artifacts，没有创建 namespace，也没有运行 MATLAB、Octave、Python或任何数值程序。

### Z.2 Verdict

**Verdict: `PASS WITH CONDITIONS`（high confidence）。** 没有 unresolved `BLOCKER`。§Y的两个 important
conditions均由 exact call order和 schema-aware predicate静态关闭。剩余条件是一次受监控 execution及本
Skeptic的 postdiagnostic artifact gate；它们限制 runtime/result claim，但不阻止授权本次唯一 command。
本 verdict只授权 Z.7，不授权任何 repair、second diagnostic、formal run或 effectivity claim。

### Z.3 Strongest challenge

最有可能推翻 static PASS的 residual risk是实际 row cell仍携带一个未枚举的 sparse/nonscalar value。Current
code已把该风险变为可解释的 fail-closed outcome：四张 evidence rows全部先 audit、后写第一张 populated
ledger；mass summary先 audit、后写 CSV/MAT；terminal row先 audit、后写 MAT和最终 commit CSV。因而未知
runtime type不会被 generic serializer静默压平。但只有002 artifact能证明 real rows实际通过，该点必须留给
postdiagnostic gate，不能从 source提升为 runtime success。

### Z.4 Classified findings

1. **`IMPORTANT CAVEAT` — runtime row values与 atomic lifecycle尚未被执行证据验证。** Static predicate
   正确，但002尚不存在；CSV/MAT row counts、无 `.partial` peers、terminal commit order和 raw `chol` branch
   仍须由一次获准 execution验证。Cheapest decisive test正是 Z.7的 single zero-eigensolve diagnostic，不需要
   guided-mode solve。
2. **`IMPORTANT CAVEAT` — 001 immutability的历史证据有明确上限。** 本次直接计算的11个 SHA-256与§21
   table逐项一致，所有 current mtimes仍为 `2026-08-28T23:29:07+0800`，inventory仍含四个 header-only final
   mass CSV、同 hash的 header-only node `.partial`、terminal summary且无 mass-summary。可是 pre-§20没有
   digest table，故可证明的是“自§21 snapshot至本 gate unchanged”以及 content/mtime/no-diff与§X一致，不能
   倒推 cryptographic pre/post equality。该 bounded statement足以保护当前 gate；postdiagnostic必须再与§21
   hash table比较。
3. **`MINOR CAVEAT` — resource仍是 forecast。** 2 min/1.0 GiB由001的14.45 s/约0.693 GiB和常数级新 gate
   支持，但不是002 measurement。若 crossing planned values但未触及 hard caps，必须记录为 resource anomaly
   并返回 review；不得据此自行重试或扩张 computation。

No `BLOCKER` was found.

### Z.5 Spec-to-code and artifact audit

以下 claims经直接审查成立：

1. **Exact dispatch/path and no-read.** Two-input entry只接受 exact mesh001/mass001/mass002 pairs；mass
   runner再次将 ID限制为 exact two-element allowlist。002只由 selected ID构造
   `diagnostics/mass-gate-002/`，在 `LOCAL_spec`、mesh build、evidence或 writer之前检查自己的 collision。
   002 call graph没有001 artifact path的 `exist/load/dir/copy/move/link/cache`；allowlist里的001仅是 identity
   string。001 invocation会在 preserved namespace collision处、任何 evidence前停止，无法触及修复后的
   helper或重写001。
2. **Five value-preserving conversions.** Selected `p_row_support(node_id)`、三个 sparse-diagonal reduction
   results和 selected positive-pivot diagonal分别转为 ordinary full scalar；$P$、support vector、完整
   diagonal、$M_{\mathrm{full}}$、$M_{\mathrm{red}}$、partial factor均不 densify。`size`/`nnz`/`numel`、norm、
   nonfinite/support counts和 `find`/`nonzeros` derived extrema没有另一个已知 sparse scalar hazard。唯一
   diagnostic raw call仍是 `[partial_factor,chol_flag]=chol(reduced.mass)`，没有 alternate matrix、third
   output、symmetrization、threshold、shift、reorder或第二个 verdict。
3. **Schema-safe gates.** `LOCAL_assert_mass_csv_rows`要求 cell matrix和 exact width；numeric/logical仅允许
   nonsparse empty或scalar，character仅允许 empty/row vector，MATLAB string仅允许 scalar，其余 class和
   nonempty nonscalar/sparse numeric全部 fail closed为 `MASS_EVIDENCE_REPRESENTATION_UNSAFE`。因此 existing
   IDs/status/reason/claim及 semicolon list strings、empty character/numeric cells不会被误拒，也不会 flatten
   vector或转换 value。Node/master/matrix/pivot的9/7/14/23 gates全部发生在任何 populated mass writer前；
   mass-summary 26 gate在其 CSV/MAT前；terminal 16 gate在 terminal MAT和最终 CSV二者之前。Header-only
   `cell(0,width)`也满足同一 width gate。
4. **Source/science/isolation.** 002仍唯一选择 `bulk-s12-g24`并硬检查 `kind='bulk'`、$N=0$、$s=12$、
   $n_\Gamma=24$、$\beta=0.5$，以$\alpha=0$调用 unchanged mesh/assembly/periodic/phase helpers。Entry在 mass
   runner后 return，不能到达 `LOCAL_low_spectrum`/`eigs`。Zero eigensolves、no reference、zero bulk rows和
   non-reference claim保持；没有 Markdown/Git/BIE/QZ/estimator/historical/reference read，也没有 formal可
   复用 cache。
5. **Formal/shared writer unchanged.** One-input formal control flow、formal raw mass predicate、119-solve
   schedule、coverage/refinement/uncertainty gates及 generic `LOCAL_write_csv`/`LOCAL_csv_value`保持 prior
   reviewed语义；type gate只由 mass diagnostic writers调用。当前 formal `chol`仍是其原 one-output gate，
   不受 diagnostic evidence/helper改变。
6. **Commit/failure order.** Empty bulk/mass headers先发布；source evidence后四张 ledgers逐文件 atomic
   replace；mass-summary row audit后发布 CSV/MAT；required-artifact/no-partial gate随后形成
   `evidence_complete`；terminal row audit后写 terminal MAT，最后 CSV commit marker。Positive raw flag只在
   complete terminal publication后 intentional raise；earlier schema/type/writer exception回 existing catch
   成为 incomplete。Terminal row自身不安全时两种 terminal artifact均不写，缺 commit即 authority。
7. **Current artifacts/history.** `diagnostics/mass-gate-002/`不存在。001的11个 current SHA-256逐项等于
   §21 table，且 current inventory/mtime与§X narrative一致。`run-005`仍为20个 preserved files，包含九张
   work mesh caches和 original terminal artifacts；run-001--005及 mesh diagnostic files均早于 current
   design/source edits，未出现在 Git diff或002 source call graph。因缺更早 hash manifest，这里只作
   bounded no-observed-mutation结论。
8. **Resource and docs.** 新增工作是约233-row scalar type iteration和五个 scalar conversions；不改变
   factorization/payload规模，2 min/1 GiB plan可信且低于30 min/2 GiB hard caps。README/SYMBOLS只登记 exact
   002、not-run、type/storage gate和 nonauthorization；README遗留的九-mesh旧时态是 minor documentation
   issue，不影响 command或 artifact authority。

### Z.6 What survived and claim boundary

Independent source rebuild、frozen continuous/FEM problem、raw as-built mass object、natural two-output `chol`
diagnostic及 create-once provenance均可进入一次 zero-eigensolve runtime check。Static PASS不说明 raw mass
positive definite，不解析 `run-005`，不产生 reference collection，也不授权 formal/effectivity comparison。

### Z.7 Exact one-command authorization and monitor contract

只在 `/Users/whc/Documents/Work/epost/test/i4/femref-a1` 作为 working directory，授权**一次** exact command：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('mass-gate-002','mass-diagnostic')"
```

Code Runner须每30 s记录 process tree、aggregate RSS、elapsed、namespace/terminal state，并保留 start/final
snapshot及 `/usr/bin/time -lp`。Plan为2 min/1 GiB；30 min wall或2 GiB aggregate RSS是本 diagnostic hard
stop，不使用 grace。Planned value crossing须记录并交回 review；hard cap到达必须停止。不得改 command、
ID/mode、拆分 budget、预运行 MATLAB snippet或 auto-retry。002 namespace一旦出现，无论 complete、scientific
fail或 incomplete都永久消费 ID，不得删除、覆盖、追加、补写、清理或改用003。Shell exit只作 launcher
evidence，存在时以 final `diagnostic-summary.csv` 为 terminal status authority；若 final CSV缺失，则 outcome
只能是 operational incomplete。

本 authorization不包含任何 code/doc/artifact repair、001 mutation、formal mass/header/representation
repair、`run-006`、second diagnostic、reference/effectivity reveal或 project-document synchronization。

### Z.8 Mandatory postdiagnostic obligations and decision tree

Command结束后必须回到同一 Skeptic并在本文件追加直接 artifact audit：

1. exact command/cwd、start/end、30 s monitor、shell exit、external real/max RSS/footprint及 cap decision；
2. 002 create-once inventory、file mtimes、terminal CSV/MAT一致性、最终 commit存在性和所有 `.partial` peers；
3. mesh ledger header+1 row/36、seam header+1/12、frozen identity/$\alpha$/$\beta$/oracle values；bulk bands
   10-column header-only、bulk gaps 14-column header-only；
4. node header+233 rows/9、master header+208 rows/7、matrix header+2 rows/14、pivot header+1 row/23、mass
   summary header+1 row/26、terminal header+1 row/16；actual counts若由 artifact identity不同则 fail closed，
   不得凭 expected count补齐；
5. MAT payload的 exact points/triangles/incidence/master groups/$P$/full-reduced masses/partial factor、matrix
   diagnostics、raw `chol_flag`和 pivot mapping；CSV/MAT identity/value一致，所有 required artifacts无 partial；
6. `completed_eigensolves=0`、`reference_exported=0`、zero bulk rows、no output/work/reference cache，001 hashes
   仍逐项等于§21 table，run-005/history无 observed mutation；
7. external resource与2 min/1 GiB plan、30 min/2 GiB hard contract比较，并复核 exact allowed claim。

Postdiagnostic只允许以下分类：

- `MASS_DIAGNOSTIC_COMPLETE_CHOL_PASS`：durable raw flag为0，只证明 current source rebuild未复现 positive
  flag；按§18.7报告与run-005 discrepancy并停在新的 bounded review，**不自动授权** formal repair/retry；
- `MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL`：durable positive natural flag及完整 pivot/matrix evidence构成 frozen
  diagnostic scientific negative/root-cause evidence；intentional nonzero shell exit不推翻 terminal artifact，
  但仍只允许另行设计最小 representation investigation，**不自动授权** repair或run-006；
- `MASS_DIAGNOSTIC_INCOMPLETE`、缺 terminal commit、schema/type/atomic矛盾或 cap stop：002是 operational
  incomplete，ID已消费；不得 auto-retry、补写或创建新 ID，须先由同一 Skeptic界定最小后续 authority。

只有 postdiagnostic review完成且另有明确 authorization，才可修改 source或同步任何 project result。

### Z.9 Minimal handoff

Goal-relative handoff：stage `I4.1a mass-gate-002 one-command diagnostic`；category
`IMPORTANT CAVEAT`；blocking scope `all repair, run-006 and reference/effectivity claims`；cheapest next check
`one monitored create-once zero-eigensolve command plus direct artifact audit`；建议 ledger status
`SPEC-TO-CODE PASS WITH CONDITIONS / MASS-GATE-002 AUTHORIZED ONCE / NO REPAIR OR RUN-006`。项目 ledger由主
agent维护。

## AA. `mass-gate-002` postdiagnostic artifact and representation audit

### AA.1 Audit frame and evidence authority

本节审查 Z.7 唯一授权的 corrected source-rebuild mass diagnostic，目标是判断002是否完成§18 evidence
contract、`chol_flag=1`能否被可靠分类，以及哪些§U blockers关闭。直接核查了002全部 CSV、MAT file identity/
field-name inventory、row/column counts、absence of partial/cache/output、001 hashes和 preserved run history；
exact command、shell exit 1、external real 13.62 s、maximum RSS 721502208 B、peak footprint 494556160 B来自
Code Runner record。本 Skeptic没有运行 MATLAB、Octave、Python或任何数值程序，也没有修改
design/code/docs/artifacts。

Terminal `diagnostic-summary.csv` 是 status authority：
`MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL`、`evidence_complete=1`、internal elapsed
0.6171102083333333 s、completed eigensolves为0、reference exported为false、bulk rows为0；failure reason明确
为 raw reduced mass natural 1-based `chol_flag 1`。因此 shell exit 1是 complete terminal publication后的
intentional raise，不是 operational failure。

### AA.2 Verdict

**Diagnostic artifact verdict: `PASS WITH CONDITIONS`（high confidence）。** 002完整、可复现且没有
unresolved artifact/schema/resource blocker；它成功关闭§X publication blocker和§U.4 item 1的
“mass failure cause unresolved”部分。允许的结论是：current source的 mathematically Hermitian reduced
mass以 raw floating storage进入 MATLAB `chol` 时，在 first pivot因 exact-Hermitian representation defect
失败；这**不是** positive-definiteness failure的证据。

**Formal-chain disposition: `REVISE / NOT AUTHORIZED`。** §U.4 item 2 的 reached-bulk formal artifact
blocker未关闭，且 branch-4 representation amendment尚未存在。`run-006`、任何 code repair和 formal/
effectivity synchronization继续停止。

### AA.3 Strongest challenge

最危险的解释错误是把 complete `CHOL_FAIL` 等同于 $M_{\mathrm{red}}$ 不正定。Artifact给出 failing pivot
$p=1$，partial factor为$0\times208$，但同一 first diagonal为
$0.0034722222222222255-1.0842021724855044\times10^{-19}\mathrm{i}$：real part严格正，唯一 first-pivot
异常是理论 Hermitian matrix不应有的 tiny imaginary diagonal。与此同时 full/reduced matrices无
zero/nonfinite rows/columns，$P$满 support，所有 nodes被 triangles使用。故 raw `chol` failure是 exact
storage predicate failure；它不能反证 consistent $P_1$ mass在数学上的正定性，也不能被当作 FEM method
negative。

### AA.4 Direct artifact, budget, and retry audit

002 final namespace恰有12个 required artifacts且没有 `.partial`：bulk bands/gaps CSV、mesh/seam CSV、四张
mass evidence CSV、mass-summary CSV/MAT和terminal-summary CSV/MAT。MAT files均为 MATLAB v7.3、唯一
top-level `payload`；直接 field-name inventory包含 identity、`phase_prolongation`、`mass_full`、
`mass_reduced`、`partial_factor`、`chol_flag`、matrix diagnostics、pivot support、zero-eigensolve和
no-reference fields。没有 `output/mass-gate-002`、diagnostic work/cache或 reference artifact。

CSV schema/rows全部闭合且每行列宽一致：

- bulk bands为10-column header only，bulk gaps为14-column header only；
- mesh为header+1 row/36，seam为header+1/12，identity是 `bulk-s12-g24`、$N=0$、$s=12$、
  $n_\Gamma=24$、$\alpha=0$、$\beta=0.5$，reached boundary为 `MESH_AND_SEAM_COMPLETE`；
- node为header+233 rows/9：233/233 nodes均 used，unused为0，每行$P$ support和entry modulus均为1；
- master为header+208 rows/7：IDs $1{:}208$，group sizes合计233，$P$ column supports合计233，entry modulus
  range为$[1,1]$；
- matrix为header+2 rows/14，pivot为header+1/23，mass summary为header+1/26，terminal为header+1/16。

External 13.62 s、721502208 B（约0.672 GiB RSS）和494556160 B（约0.461 GiB footprint）均低于2 min/
1 GiB plan以及30 min/2 GiB hard caps；没有 grace、kill或 retry。002 create-once ID已由这个 complete result
永久消费。001的11个 current SHA-256仍逐项等于§21 snapshot，包括 immutable node `.partial`；run-001--005
和 mesh diagnostic files没有晚于 current source的写入，`run-005`仍保留原20 files/九 mesh caches。

### AA.5 Numerical classification and §U blocker closure

Direct ledgers形成以下 dependency chain：

1. full space有233 points、416 triangles，全部 points used；full mass为$233\times233$、`nnz=1529`，无
   zero/nonfinite row/column，real diagonal range
   $[0.00052123279916479895,0.076555047333841247]$，imaginary diagonal和Hermitian defects均为0；
2. periodic prolongation为$233\times208$、`nnz=233`，每row恰一 unit-modulus entry、208 columns全部有
   support、master IDs contiguous；因此 source evidence与 full-column-rank $P$一致；
3. raw reduced mass为$208\times208$、`nnz=1456`，无 zero/nonfinite row/column，real diagonal仍在同一
   strictly-positive range；maximum diagonal imaginary part为$1.0842021724855044\times10^{-19}$，absolute
   和normalized Hermitian defect均为$2.7105054312137611\times10^{-19}$；
4. raw two-output `chol`正常返回 natural flag 1，partial factor $0\times208$。Pivot 1对应 master group
   nodes `1;13;221;233`、四个 unit $P$ supports，reduced row/column各7 nonzeros，pivot row/column无
   nonfinite，且其 positive real diagonal只带上述 tiny negative imaginary part。

所以§18.7 branch 1--3的 unused/assembly/master/$P$/zero/nonfinite/support failure mechanisms均由 direct
evidence排除；branch 5 source discrepancy不成立；branch 6 incomplete不成立。**唯一支持的分类是branch 4：
全部 structural evidence正常，positive raw flag只剩 tiny non-Hermitian representation。**

对§U两个 blockers的处理必须分开：

- §U.4 item 1的 diagnostic/classification blocker **关闭**：cause不再 unresolved，generic
  “not positive definite”不得保留为 scientific interpretation；
- 该 item对应的 formal execution blocker **没有关闭**：raw representation仍会在 first pivot停止，直到
  prospective representation contract通过 review；
- §U.4 item 2 **没有关闭**：002只在 diagnostic namespace发布 header-only bulk ledgers，没有修改
  `run-005`，也没有冻结/实现 future one-input formal path在 mass gate前的 reached-bulk/mass evidence
  publication。

### AA.6 Classified findings

1. **`BLOCKER`（blocking formal repair/run, not diagnostic acceptance）— canonical operator representation
   尚未规格化。** Existing design明确禁止 matrix post-symmetrization；即使 data强烈支持 roundoff-only
   representation，Engineer也无权选择 triangle、清理 diagonal或绕过 raw `chol`。最便宜的 resolution是
   AA.7的单一 Researcher prospective amendment，随后同一 Skeptic design review；不能直接改 code。
2. **`BLOCKER`（blocking future formal run）— reached-bulk/mass failure publication尚未闭合。** Future
   one-input path仍必须在 first mass gate前发布 schema-complete header-only bulk ledgers及明确的 mass
   representation evidence。002 artifacts不能作为 formal cache或替代 future current-run artifact。
3. **`IMPORTANT CAVEAT` — complete raw `CHOL_FAIL`不是 SPD certificate的反面。** Positive diagonals、
   support和tiny defect本身也不是一个 standalone numerical SPD certificate；允许的 SPD claim来自 frozen
   finite-element congruence structure的proof obligation，加上 canonical representation上的 actual
   factorization gate。两者缺一不可。
4. **`MINOR CAVEAT` — external resource authority仍在 namespace之外。** 这不影响 complete terminal
   classification，但 future review仍须同时保留 machine commit和external monitor，不能只看 shell exit。

### AA.7 Minimum explicit Researcher specification amendment

在任何 representation code change前，同一 Researcher须在 existing `design-4-1a.md` 作一个 bounded、
prospective amendment，至少冻结以下内容；不得只写“容忍 tiny imaginary part”或删除 `chol` gate：

1. **Proof obligation.** 明确证明 frozen consistent full mass对当前 conforming active nodal space正定，且
   frozen periodic $P$满列秩，所以数学对象$P^*M_{\mathrm{full}}P$为 Hermitian positive definite；把002的
   node/master/support evidence作为 implementation hypotheses check，而不是把 raw `chol` flag当作数学反例。
2. **One-triangle canonical Hermitian view.** 对每个理论 Hermitian reduced operator$A_{\mathrm{raw}}$
   冻结一个 deterministic stored triangle（建议 upper triangle，与 MATLAB Cholesky convention一致），令
   $U=\operatorname{triu}(A_{\mathrm{raw}},1)$，并定义

   $$
   A_{\mathrm H}=U+U^*+\operatorname{diag}(\operatorname{Re}\operatorname{diag}A_{\mathrm{raw}}).
   $$

   这不是 averaging；不得使用$(A+A^*)/2$，不得 threshold、shift、regularize、reorder或 tolerance-based
   entry selection。Amendment必须显式、狭窄地替换现有“任何 post-symmetrization均禁止”的条款，而不能让
   Engineer自行解释例外。
3. **Consistent solver object.** 不能只让 canonical mass通过 `chol`、随后把 raw mass交给 `eigs`。必须冻结
   $M_{\mathrm H}$作为 factorization、generalized `eigs`、mass normalization、orthogonality和 residual/
   downstream mass algebra的一致对象；保留$M_{\mathrm{raw}}$只作 audit。因为 solver设置
   `options.issym=true`，amendment还必须选择：同样 canonicalize理论 Hermitian reduced stiffness
   $K_{\mathrm{raw}}$，或以 all-formal-phase evidence证明 raw $K$ exact Hermitian。只有phase-zero stiffness
   defect 0不足以默许后者；最小稳健路线是对$K$与$M$使用同一个 one-triangle rule。
4. **No hidden drift gates.** 对每个 formal solve发布 raw Hermitian defect、
   $\|A_{\mathrm H}-A_{\mathrm{raw}}\|_1/\max(1,\|A_{\mathrm{raw}}\|_1)$、exact-Hermitian check、
   raw/canonical diagonal evidence和 canonical mass `chol_flag`；raw defect超过既有 frozen Hermitian
   tolerance、canonical diagonal非正/nonfinite或 canonical `chol` nonzero必须 fail closed。不得放宽 tolerance
   或把 representation delta计为0而不记录。
5. **Formal artifact order.** 在 future one-input run的 `BULK_INVENTORY stage-start` 后、任何 raw/canonical
   mass gate或 `eigs`前，原子发布 current-run header-only bulk ledgers和 mass-representation ledger；任一
   raise前保留 reached evidence。002 MAT不得被读取或复用。
6. **Preformal cheapest check.** Design应冻结一个 zero-eigensolve、create-once current-source diagnostic，
   至少验证 raw diagnostics、canonical exact Hermitian、canonical mass `chol_flag=0`及同一 $K/M$ view将被
   formal solver消费。其 ID、schema、budget和retry semantics必须另经 Researcher/Skeptic gate；本节不预先
   授权或命名该 execution。

**Option comparison.** “Proof-based SPD gate only”不足：proof说明离散数学对象正定，却不能让 MATLAB
`chol`或 generalized `eigs(...,options.issym=true)`接受 raw non-exact-Hermitian storage，也不能保证 solver、
normalization和residual使用同一 operator。单三角+real-diagonal view是最小可执行 representation，但若没有
上述 proof与perturbation ledger，它仍会成为未经解释的 matrix repair。故最低可接受方案是
**proof-backed one-triangle canonical view**，两者不是互斥替代项。

### AA.8 Authorization and claim boundary

当前只授权同一 Researcher起草 AA.7的 bounded specification amendment并交回同一 Skeptic design review。
**不授权** Engineer改 code/docs、不授权 canonicalization、proof-only bypass、tolerance relaxation、修改
shared serializer或 raw artifacts、不授权新 diagnostic execution、`run-006`、auto-retry、formal
header/mass repair、reference/effectivity reveal或 project-document synchronization。

`mass-gate-001`、`mass-gate-002`及其 artifacts和 `run-005`必须保持 immutable。002不消费 scientific
attempt；它消费且完成自己的 create-once diagnostic ID。任何未来 formal ID和 retry/attempt status只能在
representation + reached-artifact specifications、implementation mapping和 independent pre-run review全部
通过后另行决定。

### AA.9 What survived and open-problem handoff

Surviving claims：同一 continuous/FEM problem、mesh/assembly/periodic identity、full mass结构、$P$ support、
zero-eigensolve information isolation、artifact atomicity和resource plan均通过本 diagnostic；root cause已从
“可能的 SPD failure”收缩为 raw exact-Hermitian storage mismatch。不能存活的 claims仍包括任何 bulk
spectrum、gap、guided mode、reference resolution、$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$或 effectivity。

Goal-relative handoff：stage `I4.1a exact-Hermitian representation specification`；category `BLOCKER`；
blocking scope `all code repair, preformal diagnostic, run-006 and reference/effectivity claims`；cheapest next
check `Researcher proof-backed one-triangle canonical-view amendment plus formal reached-artifact contract`；
建议 ledger status
`MASS-GATE-002 COMPLETE / ROOT CAUSE CLASSIFIED AS REPRESENTATION / FORMAL CHAIN REVISE / RUN-006 NOT AUTHORIZED`。
项目 ledger由主 agent维护。

## AB. Independent proof/spec/budget review of design §22

### AB.1 Audit frame and proof-review mode

**Rigorous-proof mode: `Review only`.** Target是 existing `design-4-1a.md` §22，尤其§22.2--§22.4的
discrete SPD/representation proof及§22.5--§22.9的 executable contract。成功标准是：证明在明确假设下
成立；canonical operator identity/bound正确；同一 canonical $K/M$ metric在所有消费者中无歧义；derived
Hermitian self-Grams与rectangular cross-Grams不混淆；raw mesh matrices/oracles不被canonicalization掩盖；
artifact/first-failure/resource合同足以交 Engineer。本节只追加 review，没有修改 proof/design/code/docs/
artifacts，也没有运行 MATLAB、Octave、Python或任何数值程序。

§22没有引用外部 theorem、论文或数值规范；全部主张可由有限维线性代数和 frozen $P_1$ 定义直接审查。
因此不存在 unavailable-source dependency，source/citation status为 self-contained / no external reference。

### AB.2 Verdict

**Verdict: `REVISE`（high confidence）。** Exact-mathematics SPD proof和 canonical inequality通过；但有两个
unresolved `BLOCKER` 使 theory-to-code map不唯一：global cluster normalization同时受到相互冲突的 metric
规则约束，且 frozen 33-column evidence schema不能记录§22.5自己要求的 `operator_contract_id`。此外30.0 min
forecast没有可审计的正余量，必须把既已要求的 zero-eigensolve diagnostic扩展成 additive resource benchmark
gate。当前**不授权 Engineer**、implementation diagnostic或 `run-006`；最小 Researcher修订见AB.8。

### AB.3 Strongest challenge

最可能使整个 representation方向失去科学可解释性的 failure不是 $\mathcal H$ 公式，而是 metric split：
solver/eigenvectors按$M_{\phi,\mathrm H}$归一化，cluster helper若仍以
$U^*M_hU$（raw full mass）做第二次 Cholesky normalization，就会把同一 subspace换到另一个 rounded metric；
若直接删除这一步而不冻结替代 Gram，又会改变 basis-invariant localization pipeline。§22.5一方面把
“dense global mass Gram”列入 canonical/`chol` allowlist，另一方面明确禁止 raw full mass二次
re-normalization，却没有定义该 global Gram究竟由 reduced canonical object还是 raw full object形成。这不是
注释问题；它决定 cluster basis、restricted Gram spectra和continuation overlap，必须在 design层唯一化。

### AB.4 Rigorous proof audit: what is valid

1. **Full $P_1$ mass SPD — valid.** 对任意$c\ne0$，nodal coefficient中至少一个非零。对应 active node属于
   positive-area triangle；该 triangle上的 affine $u_h$在该 vertex非零，故由连续性/affine polynomial性质，
   $u_h$在一个正测度子集非零。因此$\int|u_h|^2>0$，再由$q_h\ge1$得$c^*M_hc>0$。Conforming connectedness
   不是正定性的必要条件；every-node positive-area support足够。Conjugate symmetry也可直接由 integral
   definition得出，故 complex coefficient case闭合。
2. **Nodal independence — valid under stated mesh hypotheses.** Nondegenerate conforming triangulation和
   distinct active nodal DOFs给出standard nodal interpolation property；duplicate/overlap/hole gates不是线性
   无关性的全部必要条件，但作为更强 implementation hypotheses无害。Proof没有把 numerical mesh oracle
   tolerance误当作数学 SPD certificate。
3. **Periodic prolongation full rank — valid.** Every row恰一 unit-modulus entry使不同 columns的 row support
   不相交；every column supported给$s_j\ge1$。因此$P_\phi^*P_\phi=\operatorname{diag}(s_j)$且kernel为0。
   Congruence argument随即给$z^*P_\phi^*M_hP_\phi z>0$和rank $r$。这里 phase/corner factors只需 modulus
   one；proof不依赖它们的具体角度。
4. **Canonical Hermitian identity — valid.** Strict upper entries保持，strict lower entries成为 upper的exact
   conjugate，diagonal取real part，所以$\mathcal H(A)^*=\mathcal H(A)$；exact Hermitian input上它为identity。
   这确实是one-stored-triangle rule而不是$(A+A^*)/2$ averaging。
5. **Raw-to-canonical 1-norm inequality — valid.** 对每个column$j$，change只含$i>j$的lower entries，且
   $D_{ij}=-(A-A^*)_{ij}$；diagonal change的magnitude是$|(A-A^*)_{jj}|/2$；upper change为0。因此每column
   change sum不超过相同column的anti-Hermitian defect sum，取maximum column sum即得
   $\|\mathcal H(A)-A\|_1\le\|A-A^*\|_1$。该 bound不蕴含 canonical SPD，§22保留 actual Cholesky gate是
   必要且正确的。

Proof-level结论没有 unresolved logical gap。一个纯排版错误是§22.2的
`s_j\in\mathbb N,quad s_j\ge1`，应为 `s_j\in\mathbb N,\quad s_j\ge1`；它不改变证明，但应在bounded
revision中机械修正。

### AB.5 Canonical consumers, localization, and raw-oracle audit

以下 design choices可保留：

- primary canonical pair由同一 in-memory $K_{\phi,\mathrm H},M_{\phi,\mathrm H}$供 `chol`、generalized
  `eigs`、normalization、orthogonality和algebraic residual，避免“gate canonical / solve raw”；
- theoretical-Hermitian restricted center/core/tail compressions是square self-Grams，可先过raw defect gate再用
  one-triangle view取extremal eigenvalues；common-core的两个self-Grams同理；
- adjacent-twist、different-mesh和common-core cross-Grams一般是rectangular/non-Hermitian，只用于singular
  values，不得canonicalize；这一边界数学上正确；
- full assembled $K_h,M_h,M_D$、$P_\phi$、fields、mesh/reflection/seam oracles继续消费raw objects。Raw
  defect必须先过既有$5\times10^{-13}$ gate，故 canonicalization不会掩盖 full-mesh/connectivity/material
  failure；full matrices仍禁止 averaging；
- parity compression只有在物理 parity label有意义的$\vartheta=0,\pi$才消费。其 Hermitian性需要在修订中
  补一句直接证明：reflection permutation $R=R^*=R^{-1}$且 raw reflection oracle给$R^*M_hR=M_h$，所以
  $M_hR=RM_h$并且$(M_hR)^*=M_hR$，从而$U^*M_hRU$ Hermitian。Interior-twist parity不得继续构造后丢弃，
  应明确标记为not applicable。

但 global cluster normalization存在**确定冲突**：§22.5 allowlist item 2和§22.6 item 5仍允许一个global
mass self-Gram经canonical `chol`；紧邻 paragraph又禁止用 raw full mass二次re-normalize。Current code的
`gram_full=U^*M_hU`及其 Cholesky正是被禁止的路径。Design没有冻结以下二者之一：

1. 取消第二次 normalization，直接依靠 spectrum-level $M_{\phi,\mathrm H}$ orthogonality gate；或
2. 用 reduced vectors明确构造$G_C=V_C^*M_{\phi,\mathrm H}V_C$，canonicalize/factorize $G_C$，再以同一
   change同时更新$V_C$和$U_C=P_\phi V_C$。

只有第二种路线保留 current “cluster re-orthonormalization” robustness且不切换 metric；若选择它，spectrum
cache/struct、memory estimate和`operator_contract_id`必须携带所需 reduced basis/contract linkage。未经该
选择，Engineer无法判断 global mass Gram、normalizer和localized subspace的权威对象。

### AB.6 Artifact and first-failure contract audit

Header-first bulk publication、per-phase MAT then CSV commit、failure前checkpoint、terminal after reached
evidence、002/no-history read prohibition及create-once `run-006`边界总体正确。33 columns逐项计数也确为33，
K/M primary rows、derived object IDs、factorization kind/flag和consumer strings足以描述大部分scalar evidence。

但存在两个 executable schema gaps：

1. §22.5强制 `spectrum.operator_contract_id`证明 solver、norm、orthogonality和residual引用同一 pair；33-column
   CSV与fixed MAT mirror fields均没有该ID。`consumer_contract='chol|eigs|...'`只是声明，不是 pair linkage；
   K row、M row、spectrum cache和derived rows无法在artifact中machine-join。这个 mismatch是 `BLOCKER`。
2. 若 stiffness raw gate先失败，§22.6要求mass row只保存“可安全取得的 raw evidence”，但没有冻结该row的
   `gate_pass`、canonical/factorization blanks和 first-failure fields语义。若复制 stiffness code会误称mass
   failed；若全部留空又无法区分not-evaluated与writer omission。修订必须指定一个明确
   `evaluation_status`（或等价 frozen encoding），并保持phase first failure只归于实际 first object。

`operator-representation.mat`不保存 raw/canonical matrices、也不作为solver cache是正确的信息隔离选择；
但加入contract linkage和evaluation status后，CSV header、MAT mirror、schema version及row-width必须同步
重冻结，不能继续称原33-column schema完整。

### AB.7 Budget audit

Peak estimate 1.3 GiB低于1.5 GiB preflight和2 GiB hard cap；one-triangle canonical pair可能取raw/canonical
pattern union，但§22已要求以actual canonical pattern重算fill，memory design目前没有 blocker。

Wall forecast恰为30.0 min则没有任何可审计余量。`test/AGENTS.md`只允许launch一个**预计不超过**30 min的
完整结果；decimal 30.0本身不是自动超限，但当前新增成本同时包含119次 sparse canonical construction、
至少238 primary rows、derived Gram rows以及per-phase growing MAT/CSV atomic rewrites，§22只给“约0.2 min”
而没有计数/benchmark依据。故不能把equal-to-limit estimate直接当成 prelaunch evidence。

这不是永久 resource failure，也不需要扩大理论研究；§22.8已要求的 two-object zero-eigensolve diagnostic是
最便宜的 decisive check，但其现有合同只验证representation correctness，没有冻结计时外推。修订应要求它：

- 分别记录coarse bulk和finest defect的raw diagnostics、canonical construction、factorization、row/MAT/CSV
  checkpoint wall及peak RSS；
- 由exact 119 primary pair count和derived-row upper count外推 additive overhead，并计入MAT/CSV growing rewrite；
- 与原29.8 min floor合成一个**未四舍五入且严格小于30 min**的 preformal forecast，同时peak严格不超过
  1.5 GiB；否则 `RESOURCE_BUDGET_UNAVAILABLE`，不得授权formal run；
- diagnostic仍受2 min/1 GiB自身 envelope且不调用 `eigs`。它只能测additive representation/I/O成本，不能
  宣称重新验证119 eigensolve基线。

因此 zero wall margin是 **`IMPORTANT CAVEAT` at Engineer-design stage and a `BLOCKER` for any formal launch**。
它可由已规划的 cheap diagnostic解决，不需要在本轮把方法判为资源失败；但在补齐上述合同前，§22 resource
gate尚不完整。

### AB.8 Classified findings and minimum bounded revision

1. **`BLOCKER` — cluster global normalization metric contract自相矛盾。** Location §22.5 items 2及后续
   localization paragraph。Effect：可能让 solver和localization使用不同 rounded mass metric。Minimum
   repair：选择并写出AB.5的canonical reduced-Gram路线或明确删除第二次normalization；同步理论对象、cache/
   memory和derived row consumer。
2. **`BLOCKER` — `operator_contract_id`不在33-column/MAT mirror。** Location §22.5 versus §22.7。
   Effect：artifact不能证明same-pair consumer identity。Minimum repair：为每个phase生成一个K/M共享、
   spectrum继承的 deterministic contract ID；加入重编号schema/MAT mirror及derived parent linkage，更新
   schema version/width。
3. **`IMPORTANT CAVEAT` — prior-object failure后的row state未冻结。** Location §22.6--§22.7。Effect：mass
   raw-only row可能冒充mass failure或missing row。Minimum repair：冻结 evaluation status、blank fields、
   gate/failure ownership和MAT/CSV mirror semantics。
4. **`IMPORTANT CAVEAT` — 30.0 min无正余量。** Location §22.9。Effect：当前无法诚实证明launch forecast
   不超过默认上限。Minimum repair：把AB.7 timing/extrapolation作为zero-eigs diagnostic的hard preformal gate；
   forecast不严格小于30 min即resource blocker。
5. **`IMPORTANT CAVEAT` — parity Hermitian/endpoint消费缺显式 bridge。** Location §22.5。Effect：实现可能
   对interior twists继续输出无物理意义的parity labels。Minimum repair：加入$M_hR$ Hermitian的一行证明，
   endpoints only，interior status not applicable。
6. **`MINOR CAVEAT` — `\quad`排版缺反斜杠。** Location §22.2。Effect：不影响逻辑；机械修正即可。

### AB.9 Authorization boundary

由于存在 unresolved blockers，**不授权 Engineer** 修改 `run_i4_1a.m`/README/SYMBOLS；不授权任何
canonical helper、schema writer、preformal diagnostic、`run-006`、auto-retry、history/001/002 mutation、
reference/effectivity reveal或 project-document synchronization。

只授权同一 Researcher对§22作一次有界修订：关闭AB.8 items 1--5，机械修正item 6，保留已通过的SPD proof、
canonical formula/inequality、raw full matrices/oracles、no-averaging rule、119 schedule和claim boundary。
修订后回同一 Skeptic re-review；不得让 implementation output反向选择规格。

### AB.10 Proof-review completion record

- **Task mode:** `Review only`；
- **Proof status:** exact SPD与canonical-bound proofs valid under stated hypotheses；executable specification
  has two blockers；
- **Source file:** `research/projects/eig-apost/implementation/i4/design-4-1a.md`；
- **Theorem/claim:** §22.3 discrete mass positivity claim及§22.4 representation identity/bound；
- **Target environment/location:** Markdown §22.2--§22.4及其§22.5--§22.9 consumers；
- **Output file:** 本 `review-4-1a.md` append-only §AB；
- **Original-text integrity:** proof/design file未修改；review以外无写入；
- **Verified references:** none required；proof self-contained；
- **References downloaded/missing locally:** none；
- **Steps awaiting literature verification:** none；
- **Remaining proof gaps:** none in SPD/inequality claims；parity Hermitian bridge需补写但可由stated raw reflection
  identity直接完成；
- **Review-only findings:** AB.8给出location、effect和minimum repair；
- **Literature status:** `Review literature verification completed.`

Goal-relative handoff：stage `I4.1a §22 bounded design revision`；category `BLOCKER`；blocking scope
`Engineer handoff, representation diagnostic, run-006 and all reference/effectivity claims`；cheapest next check
`Researcher resolves canonical cluster metric + contract-linked schema, then adds diagnostic resource extrapolation`；
建议 ledger status `§22 REVISE / PROOFS VALID / EXECUTABLE CONTRACT BLOCKED / NO ENGINEER OR RUN-006`。项目
ledger由主 agent维护。

## AC. Independent re-review of design §22.12

### AC.1 Audit frame

**Rigorous-proof mode: `Review only`.** Target是 existing `design-4-1a.md` §22.12 对 review §AB.8 的 bounded
revision。当前 gate的成功标准不是产生 eigenvalue，而是让 proof-backed canonical representation、artifact
linkage和 zero-eigensolve resource gate足够唯一且可实现，之后才可考虑 Engineer handoff。本节只审查
design；没有修改 design/code/docs/artifacts，没有运行 MATLAB、Octave、Python或任何数值程序。

审查权威包括 root/research/test `AGENTS.md`、本 design 的 frozen branch/output/budget sections、§22及
§22.12，以及 current source中既有 `branch-inventory.csv` row semantics。§22.12没有使用外部文献；线性代数
主张仍为 self-contained，因此没有 citation blocker。

### AC.2 Verdict

**Verdict: `REVISE`（high confidence）。** §AB的 cluster-metric与33-column linkage blockers在数学对象层面
基本关闭：canonical reduced Gram、同步的 $V_C/U_C$、OP2/DRV2以及36-column mirror均可唯一解释；行数和
checkpoint算术也成立。但是当前 preformal diagnostic有两个新的 executable `BLOCKER`：MATLAB读取
external-monitor sidecar与 repository `test/AGENTS.md` 的 MATLAB-only runtime contract冲突，而且 MATLAB
在退出前不可能核验退出后才产生的 `/usr/bin/time` whole-command record；同时 resource proxy没有覆盖新增
cluster synchronization的实际 full-height操作，并用最粗 bulk pair外推全部72个 bulk pairs。在原 baseline
只剩12 s余量时，这不能支撑严格 $T_{\mathrm{forecast}}<1800$ s。当前不授权 Engineer、
`representation-gate-001` execution或 `run-006`。

### AC.3 Strongest challenge

最强 failure mode是 resource terminal claim的因果顺序不可能成立。§22.12.5把 `/usr/bin/time`
whole-command record列为 complete evidence，§22.12.8却要求 MATLAB在退出前读取 sidecar并先提交
`diagnostic-summary.mat/.csv`。`/usr/bin/time -lp` 的 final `real`/maximum RSS只能在 MATLAB process退出后
产生；因此 MATLAB summary不能同时成为 last terminal commit marker并诚实断言 whole-command evidence
complete。即使忽略这一时序，MATLAB entry依赖 monitor token/sidecar才运行也违反本 experiment适用的
MATLAB runtime portability rule。这个问题不能留给“运行后再解释”；必须先改成 observational external
monitor + post-run Skeptic resource gate，或另一个不让 MATLAB消费非-code artifact的同等明确合同。

### AC.4 What survived the proof and specification audit

1. **Canonical cluster route通过。** 对
   $G_{C,\mathrm{raw}}=(V_C^{(0)})^*M_{\phi,\mathrm H}V_C^{(0)}$ 取
   $G_{C,\mathrm H}=R_C^*R_C$ 后，`V_C = V_C_0 / R_C`给
   $V_C^*M_{\phi,\mathrm H}V_C=I$；随后唯一重建 $U_C=P_\phi V_C$ 是同一 basis change。任意另一个
   $M_{\phi,\mathrm H}$-orthonormal basis只与其相差 unitary transform，故 restricted self-Gram spectra、
   principal angles和continuation singular values保持 basis-invariant。禁止 full raw mass二次 normalization
   已写清，existing localization/coverage thresholds不变。
2. **OP2/DRV2核心 linkage通过。** OP2只依赖 model/mesh/phase kind/exact `num2hex` phase，同一 tight/count
   operator pair可稳定复用；primary K/M共享OP2，derived self-object以DRV2指回唯一 parent OP2，避免以
   result/ranking生成identity。36-column header独立计数确为36，新增 contract/evaluation fields与MAT cell
   mirror足以记录 primary/derived representation evidence。
3. **Stiffness-first semantics通过。** stiffness first failure独占 owner；mass的 raw-only row用
   `RAW_ONLY_BLOCKED_BY_PRIOR_OBJECT`，canonical/gate/failure cells为空而非伪造0/`NaN`，且先提交两行再
   raise。这既保存 reached evidence，也不把未评估mass冒充第二个 verdict。
4. **Parity proof通过。** 从 $R=R^*=R^{-1}$ 和 $R^*M_hR=M_h$ 可得 $M_hR=RM_h$，再得
   $(M_hR)^*=M_hR$；endpoint compression理论 Hermitian。只在 $\vartheta=0,\pi$ 形成 parity object、
   interior不形成该matrix，是原§5.3物理定义的正确边界。
5. **Raw/canonical边界通过。** full assembled $K_h/M_h/M_D$、mesh/reflection/seam oracles、$P_\phi$与
   rectangular cross-Grams保持raw；只有allowlist中的reduced/theoretically-Hermitian objects使用
   one-upper-triangle/real-diagonal view。没有 averaging、tolerance relaxation或将 representation delta冒充
   eigenvalue/reference uncertainty。

### AC.5 Independent count audit

- Defect schedule的42个`nev=40`和5个`nev=48`给
  $42\cdot40+5\cdot48=1920$ cluster slots。
- Global、three restricted、endpoint parity和cached common-core上界分别为
  $1920$、$5760$、$6\cdot2\cdot40+1\cdot2\cdot48=576$、$1920$；合计
  $10176$ derived rows。加119 pairs的238 primary rows得到 $10414$。其中 common-core与parity计数是安全
  上界；它们可高估但未低估 frozen union。
- `1 + 119 + 47 + 47 + 47 = 261` checkpoint算术成立。其科学含义只能是 batch upper bound；empty batch
  可跳过且 common-core self-Gram必须缓存复用，design已明确这一点。

因此 row/checkpoint算术本身不是 blocker；问题在这些上界如何被 resource timing proxy使用。

### AC.6 Classified findings

1. **`BLOCKER` — external RSS handshake违反runtime authority且terminal evidence存在因果矛盾。**
   Location：§22.12.5、§22.12.8；authority：`test/AGENTS.md` MATLAB runtime portability。Evidence：MATLAB
   等待并读取 monitor token/sidecar才继续，而适用规则要求实际 entry point只依赖 MATLAB与真正需要的
   source；另外 whole-command `/usr/bin/time` record在 MATLAB退出后才完成，不能被退出前的
   summary-last marker验证。Consequence：`resource_evidence_complete=1`和`peak_rss_bytes`没有唯一可实现的
   authority，create-once diagnostic可能因monitor plumbing而 operationally fail，或提前声称完整。
   Cheapest repair：外部monitor保持纯 observational，MATLAB不读token/RSS artifact、不以其输入决定状态；
   MATLAB只提交 internal correctness/timing/array evidence并明确等待post-run resource audit。同一 Skeptic在
   command结束后把 frozen monitor ledger与 `/usr/bin/time` final record结合，才判 peak/wall gate。若仍要
   machine sidecar，必须冻结被监控PID/command identity、atomic close和post-exit authority，但不得让MATLAB
   science/diagnostic消费它。
2. **`BLOCKER` — additive resource forecast没有覆盖实际新增路径，且bulk sample不是保守代表。**
   Location：§22.12.1、§22.12.5。Evidence：$72t_{\mathrm{bulk}}$只从最粗
   `bulk-s12-g24`取得，未按largest bulk pair或actual size schedule分层；48-by-48 principal-block probe只测
   已形成dense object后的diagnostics/$\mathcal H$/`chol|eig`，没有测 global route新增的
   `V_C_0/R_C`、full-height `P_\phi V_C`、$V_C^*M_{\phi,\mathrm H}V_C-I$和
   $U_C-P_\phi V_C$ checks。它也把最多rows与max-width dense cost混为一个
   `10176t_{\mathrm{derived}}`项，既不对应actual operation partition，也不能解释为可信 tight forecast。
   Consequence：在 $1788$ s baseline后仅有12 s时，strict `<1800` pass可能低估真实新增成本，或因互不同时
   达到的worst cases而产生无意义false failure；两者都不能作为launch authority。Cheapest repair：至少以
   largest bulk mesh（或逐level size-weighted schedule）测 primary overhead；把derived row serialization、
   dense canonical/factorization和global $V/U$ synchronization分项计时；用一个 deterministic、
   zero-eigenobject、full-height width-at-most-48 probe实际走 `/R`、`P*V`和两个recheck，再按 cluster-dimension
   partition的安全上界外推。Growing writer的10414/261实测继续单列，不得重复计入per-row writer cost。
3. **`IMPORTANT CAVEAT` — `branch-inventory.csv`的interior parity cell语义与现有schema冲突。**
   Location：§22.12.6 versus frozen/current branch writer。Existing file一行对应一个branch slice，但
   `parity_signature`/`parity_ambiguous`当前是branch-level endpoint aggregate并在所有slice rows重复；
   §22.12.6又要求interior row写`NOT_APPLICABLE_INTERIOR_TWIST/false`。Consequence：Engineer虽可任选一种写法，
   但后一写法会把同一列从branch-level变成slice-level，并可能让审查者误以为该branch没有endpoint ambiguity。
   Cheapest repair：保留existing branch-level aggregate在每一slice row，只让interior cluster cache的
   parity spectrum为空；或显式版本化schema并增加separate parity scope/status field。无论哪种，
   `MODE_ID_AMBIGUOUS`仍只由两个endpoints aggregate决定。
4. **`IMPORTANT CAVEAT` — spectrum/eigenobject的OP2 artifact继承语句不闭合。**
   Location：§22.12.2 versus frozen `bulk-bands.csv`/`spectrum-inventory.csv` headers。Design声称每个
   eigenobject row继承OP2，但这两个scientific ledgers没有该column；目前只能通过`solve_id`间接join到primary
   operator row。Consequence：不是operator v2-36本身的宽度错误，但direct inheritance claim不可机械验证。
   Cheapest repair：明确规定`solve_id -> OP2`是唯一权威join并把“row继承”改为“cache继承/row经solve_id
   join”，或对两个ledger作显式、versioned schema扩展；不得让Engineer临场决定。
5. **`MINOR CAVEAT` — benchmark temp hash没有schema位置。** Location：§22.12.5。Text要求timing/hash/byte
   counts后删除temporary files，但11-column rewrite ledger只有timing和byte fields。Hash对本 gate并非必要；
   删除该要求或给出单独machine-only field即可，不能把未记录hash声称为已保存证据。

### AC.7 Implementation audit and authorization boundary

§22.12尚未实现，因此本轮不能给 spec-to-code PASS。两个 blockers均发生在 Engineer可执行合同之前；不能以
future runtime fail-closed替代 design修订。尤其不应让同一 Engineer同时发明external monitor protocol、
resource estimator和canonical scientific plumbing。

**当前不授权 Engineer。** 也不授权创建/执行 `representation-gate-001`、`run-006`、auto-retry、修改
historical run/diagnostic、读取 BIE/QZ/current reference、同步 project/effectivity结论。

最小下一步是同一 Researcher仅修订AC.6 items 1--4并机械处理item 5。修订通过后，建议权限仍分 gate：

1. 先授权 Engineer实现 canonical helper、formal consumer linkage/v2 evidence writers，以及不会读取external
   artifacts的 zero-eigensolve diagnostic plumbing；
2. Researcher做 theory-to-code mapping、同一 Skeptic做 pre-execution spec/code/resource review；
3. 另行授权至多一次 diagnostic command；postdiagnostic review通过 strict wall/peak gates后，才讨论
   `run-006`。

### AC.8 Open-problem handoff

Goal-relative handoff：stage `I4.1a §22.12 executable representation/resource contract`；category `BLOCKER`；
blocking scope `Engineer handoff, representation diagnostic, run-006 and all reference/effectivity claims`；
cheapest next check `Researcher replaces MATLAB-consuming RSS handshake with post-exit observational audit and
freezes a size-aware/full-path additive benchmark`；suggested ledger status
`§22.12 REVISE / PROOFS AND COUNTS VALID / RESOURCE TERMINAL CONTRACT BLOCKED / NO ENGINEER OR EXECUTION`。
项目 ledger由主 agent维护。

**Review literature verification completed.**

## AK. Design review of §23 user-authorized 2 GiB representation continuation

### AK.1 Audit frame

本节独立审查 [[research/projects/eig-apost/implementation/i4/design-4-1a|design §23]] 的 prospective amendment，而不复审或改写 [[research/projects/eig-apost/implementation/i4/review-4-1a|review §AJ]] 的历史 postdiagnostic verdict。当前问题是：能否在 continuous model、FEM weak form、scientific/evidence workload、120 s wall envelope、information isolation 和 claim boundary 均不变时，以新的 exact create-once ID 在用户明确授权的 $2147483648$-byte actual-RSS 上限内继续 zero-scientific-eigensolve representation diagnostic。当前阶段是 pre-implementation design gate；目标 artifact 是用于判断 future formal preflight 是否可解释的 representation correctness/resource diagnostic，不是 guided-mode numerical result。

Authority 为用户本轮明确授权、仓库根目录及 `research/AGENTS.md`、`test/AGENTS.md`、design §23、历史 review §AJ、current `run_i4_1a.m`/`README.md`/`SYMBOLS.md` 和 preserved 001 artifacts。成功标准是：001 immutable/consumed；002 identity、namespace、collision 和 consumption 语义唯一；002 的唯一 current-diagnostic memory stop 是 external aggregate observed RSS 达到 $2147483648$ bytes；120 s wall 与不粗于30 s的 process-tree/RSS monitoring保持；旧1.5 GiB字段只作 future-formal observation；all probes/counts/schemas/DP/writer与zero-eigensolve claim不变；`run-006`继续冻结。本节没有执行 MATLAB、Octave、Python或其他 numerical computation。

### AK.2 Verdict

**Design verdict: `PASS WITH CONDITIONS`（high confidence）。** 没有 unresolved `BLOCKER`。§23以最小 prospective amendment明确关闭了§AJ中“没有新ID authority”的 blocker，同时保留001的资源失败与create-once历史。002的 actual-RSS authority、wall/monitor、consumption、no-reuse、artifact及postreview gates足够明确，可交同一 Engineer作 bounded source/README/SYMBOLS implementation。条件只约束实现不得重新引入较低 memory gate及不得制造schema语义混淆；本 verdict不授权执行002，更不授权`run-006`。

### AK.3 Strongest challenge

最能推翻本次授权的 failure mode 是旧1.5 GiB array forecast仍在 implementation中进入 `internal_gate_pass`，从而在 observed RSS尚未达到2 GiB时把002标成internal resource failure。Current source确实仍是pre-amendment状态：representation runner硬编码001，且 `internal_pass = wall_pass && peak_pass && timing_pass`，failure reason还包含`array-peak`。这不是§23 design defect，而是 Engineer必须消除且后续双重静态review必须验证的唯一关键implementation risk；若它在002 path残留，即构成阻止执行的 spec-to-code `BLOCKER`。

### AK.4 Classified findings

1. **`IMPORTANT CAVEAT` — 002 policy必须dispatch-local，不能全局改写formal或历史001语义。** Location：design §§23.2、23.5；current source entry dispatch、representation runner、forecast/status block和summary expected-dispatch。Evidence：current source只allowlist并硬编码`representation-gate-001`，且old `internal_pass`含`peak_pass`。Consequence：若只机械换ID或全局删除peak gate，前者违反用户2 GiB authority，后者会误改尚未获准的formal 1.5 GiB preflight。Uncertainty：bounded且可由静态映射完全消除。Cheapest decisive check：implementation后逐行确认002 exact allowlist、validated ID传入runner、002-only gate expression及formal `spec.preflight_peak_cap_gib=1.5`未变。
2. **`MINOR CAVEAT` — 27-column forecast schema复用时必须显式记录列语义的dispatch-local supersession。** Location：design §§23.3、23.5--23.6；`representation-forecast.csv` header及`SYMBOLS.md` representation objects。Evidence：`forecast_at_most_1p5_gib`仍准确表示1.5 GiB comparison，但002的`internal_gate_pass`改为只含wall/timing；forecast row自身没有diagnostic-ID列。Consequence：脱离namespace读取单个CSV可能误用旧§22语义，但不会使本设计不可执行。Cheapest decisive repair：保持冻结27列不变，在README/SYMBOLS明确002的两列关系，并确保summary中的exact `diagnostic_id`/`expected_dispatch`与002 namespace一致。无需新增schema版本或列；namespace加summary identity已足以消歧，擅自版本化/扩列反而违反§23.3。

### AK.5 Implementation audit and exact conditions

Same Engineer只获准作以下 bounded changes：

1. 在two-argument entry中加入且只加入 exact `representation-gate-002` / `representation-diagnostic` pair；不得接受任意ID、alias或path。
2. 令representation runner使用已经exact-validated的`diagnostic_id`形成current namespace和summary；002不得读取、stat、hash、复制或复用001。001 dispatch、namespace和7个preserved files保持不写不补，现有001 collision语义保持。
3. `expected_dispatch`必须对002精确写为 `run_i4_1a('representation-gate-002','representation-diagnostic')`；不得继续硬编码001，也不得由未验证runtime string形成路径或authority。
4. 继续如实计算并写出`peak_pass = forecast_peak_bytes <= 1.5 * 1024^3`对应的`forecast_at_most_1p5_gib` observation；对002仅令 `internal_gate_pass = wall_pass && timing_pass`。该observation不得触发early return、删减benchmark、terminal internal-resource failure或failure reason。
5. 002的non-memory internal failure reason只能指向strict wall、CV或propagated-spread/margin gate；不得保留`array-peak`措辞。若correctness与这些non-memory gates通过，terminal必须pending external review，即使1.5 GiB observation为false。
6. 不修改2 mesh、3 seam、6 primary、294 probe、8 partition、$10414\times36$ padding、261 rewrite、one 27-column forecast、36/17/16/7/11/27/19 schemas、warm-up/repeat、DP、timing、canonicalization、tolerances或zero-eigensolve/no-reference gates。
7. README和SYMBOLS只追加002 identity、001 consumed history、2 GiB unique external stop以及002 dispatch-local `internal_gate_pass`语义；不得把pending status写成resource PASS。
8. External runner而非MATLAB拥有actual process-tree RSS authority。Prospective execution monitor必须从process start起以不粗于30 s记录process-alive与aggregate RSS；first observed RSS $\ge2147483648$ bytes时立即停止。不得设置或沿用1 GiB、1.5 GiB或其他较低actual-RSS stop。`/usr/bin/time -lp`只作post-exit authority；120 s wall达到即stop，无grace。

### AK.6 What survived scrutiny

1. 001 historical boundary完整保留：direct artifact inspection仍见恰7个reached files；001 consumed且不得重跑、补齐或有利重解释。
2. Freeze时002 namespace与`output/run-006/`均不存在；new ID不构成same-ID retry，也不消费scientific method attempt。
3. §23.2的source rebuild/no-history/no-reference isolation足以阻断001 evidence leakage；001不是002 prerequisite或completion input。
4. 2 GiB rule使用exact bytes和aggregate observed process-tree RSS，且明确排除了旧1 GiB stop与1.5 GiB internal forecast作为current diagnostic memory control。
5. 120 s shared wall、30 s-or-finer monitoring、complete/incomplete皆消费002、无auto-retry、post-exit same-Skeptic authority及`run-006`冻结均清楚且可执行。
6. Scientific model、FEM forms、representation objects、counts、schemas、timing/DP/writer workload、information isolation和claim boundary均未被扩大或改变。

### AK.7 Minimal resolution and authorization

**仅授权同一 Engineer按AK.5实现bounded source/README/SYMBOLS change。** 不授权创建002 namespace，不授权MATLAB/Octave/Python execution，不授权`run-006`、auto-retry、003、reference/effectivity reveal或project result sync。Implementation完成后必须先由同一 Researcher作theory-to-code audit，再由同一 Skeptic作spec-to-code/resource pre-execution review；任一review发现002仍有低于2 GiB的memory stop即`REVISE`。只有两道review均无blocker，才可讨论恰一次§23.7 exact 002 command。002无论complete、incomplete、external stop、MATLAB或environment failure都消费该ID，且必须先完成same-Skeptic postdiagnostic review；在此之前`run-006`绝对不授权。

### AK.8 Open-problem handoff

- Stage：`I4.1a representation-gate-002 pre-implementation`；category：`IMPORTANT CAVEAT`；blocking scope：`002 execution`；cheapest next check：`bounded implementation followed by Researcher theory-to-code and same-Skeptic spec-to-code review`；suggested ledger status：`DESIGN PASS WITH CONDITIONS / IMPLEMENTATION ONLY AUTHORIZED / EXECUTION AND RUN-006 BLOCKED`。
- Stage：`I4.1a representation-gate-002 postdiagnostic resource feasibility`；category：`IMPORTANT CAVEAT`；blocking scope：`run-006 and formal reference computation`；cheapest next check：`one exact create-once 002 execution only after all pre-execution gates, then audit complete artifacts, actual peak RSS, wall and 1.5 GiB observation`；suggested ledger status：`CONDITIONAL / NOT YET EXECUTED`。

这些是阶段内handoff，不需要在Engineer implementation前扩写project-level open-problem ledger。项目ledger仍由主agent维护。

**Review literature verification completed; no external literature claim was required for this bounded design audit.**

## AH. Pre-execution spec-to-code/resource re-review after §22.16

### AH.1 Audit frame

Target是 current `test/i4/femref-a1/run_i4_1a.m`、`README.md`、`SYMBOLS.md` against design §§22--22.16与
review §AF.7。成功标准是：AF的三个static blockers确实关闭，create-once representation diagnostic可以作为
zero-scientific-eigensolve correctness/resource gate执行一次；不是 canonical numerical result或formal-run
authorization。本节只读核查source/doc diff、function/call graph、schemas、artifact gates与namespace；没有改
code/design/docs/artifacts，也没有执行 MATLAB、Octave、Python或任何 diagnostic。

### AH.2 Verdict

**Verdict: `PASS WITH CONDITIONS`（high confidence for static readiness）。** 没有 unresolved blocker。三阶段
derived checkpoint、formal/benchmark shared writer以及formal/diagnostic shared endpoint-parity helper均在当前
source中成立；119-solve scientific contract、B3 alias、branch/refinement/uncertainty与information isolation未漂移。
Conditions只涉及本来就必须由一次运行与post-exit review决定的MATLAB runtime、actual 261-write cost及external
wall/RSS；它们不阻止执行该 diagnostic。下文仅授权一次 exact `representation-gate-001` command，绝不授权
`run-006`。

### AH.3 Strongest remaining challenge

当前最可能推翻“可进入formal preflight”的不是未关闭的source mismatch，而是actual shared writer/resource
evidence：261次从0增长到10414 rows的v2 MAT/CSV atomic rewrite可能使 diagnostic越过2 min/1 GiB，或使
$29.8\,\mathrm{min}+T_{\mathrm{add}}$没有strict positive margin。该风险已被测量而非假定：同一 formal writer被
完整benchmark，internal gate要求$T_{\mathrm{forecast}}<1800\,\mathrm{s}$且margin大于spread/floor，external
runner另在120 s/1 GiB停止。任一失败都给resource/operational negative，不得靠删rows/checkpoints或自动retry
规避。

### AH.4 Findings

1. **`IMPORTANT CAVEAT` — runtime/resource feasibility仍未观测。** Location：diagnostic lines 981--1349，
   `LOCAL_benchmark_growing_writer` lines 1819--1879及forecast lines 1233--1300。Static evidence已经足以执行，
   但MATLAB parser/API、filesystem atomic-write cost、timing CV、strict wall margin与whole-process RSS只能由一次
   authorized command判定。Consequence只阻止后续`run-006`，不阻止本 diagnostic。Cheapest decisive test就是
   AH.8授权的单次command与same-Skeptic post-exit audit。
2. **`MINOR CAVEAT` — B3继续是machine-join的显式non-solve exception。** Location：formal lines
   4506--4519。B3 synthetic IDs只把odd B4 spectra登记为`alias-reuse-no-solve`，不拥有primary OP2。它保持冻结
   science、旧CSV schema与72-solve count；不得为了字面`solve_id -> OP2`而伪造OP2或增加solve。该例外不影响
   representation diagnostic或formal actual-solve OP2 mapping。

### AH.5 Implementation audit

1. **Pre-consumer evidence顺序通过。** `LOCAL_normalize_defect_clusters`先prepare全部global raw/canonical Gram、
   `chol` factor和DRV2 row，lines 4395--4396 checkpoint后才在4400执行`/ normalizer`、重建$U=P_\phi V$与
   rechecks。`LOCAL_gap_clusters`先prepare center/core/tail及endpoint parity rows，5107--5108 checkpoint后才在
   5113/5122调用restricted/parity `eig` consumer；再prepare common-core self-Gram/factor，5159--5160
   checkpoint后才在5164执行`/ common_factor`。Prepare/evaluation failure先发布reached batch再raise；
   post-checkpoint consumer failure不修改或重复已提交row，而由existing terminal path fail closed。
2. **Shared writer/resource path通过。** Formal checkpoints和benchmark都进入
   `LOCAL_write_operator_representation`，outer timer在`LOCAL_prepare_operator_payload`前启动，后者执行同一
   36-column gate、stable OP2/DRV2-parent inventories、first-failure/model/planned/checkpoint payload；MAT与CSV均
   走same atomic temporary-to-final writers，total timer在两次move后停止。Padding每次从未分配container构造
   exact $10414\times36$，含238 parent-empty alternating `reduced-stiffness`/`reduced-mass` primary shapes及
   10176 nonempty-parent DRV2 shapes。Schedule为$1+119+47+47+47=261$ checkpoints，additions总和10414；
   rewrite gate核对before/add/after identities、finite/nonnegative timings/bytes、monotone cumulative time及
   MAT+CSV-to-total consistency。Row-preparation的2 warmups/5 repeats每次均含dimension/type/parent-shape gate；
   timing values有finite/nonnegative/CV/$10^{-4}$ s conservative-floor gate。
3. **Shared endpoint parity通过。** Formal与diagnostic都调用唯一
   `LOCAL_prepare_parity_object`和`LOCAL_consume_parity_object`。Diagnostic只在source-rebuilt finest defect
   $artheta=0$ pair形成global-normalized full basis后测该helper；interior$artheta=\pi/4$不构造parity。
   `eigs`唯一静态调用仍在formal `LOCAL_low_spectrum`；diagnostic只调用allowlisted small dense `eig` consumers，
   不产生scientific eigenpair。
4. **Schema/MAT/terminal path通过。** Code冻结operator 36、resource 17、probe 16、partition 7、rewrite 11、
   forecast 27、summary 19 columns，并保留mesh 36/seam 12与header-only bulk 10/14 schemas。Completion gate要求
   exact 2 mesh、3 seam、6 primary、294 probe、8 partition、261 rewrite、one forecast row、$10414\times36$
   padding；operator MAT mirror必须有6 rows、3 primary OP2、0 derived rows、4 completed checkpoints、empty first
   failure。Required current-namespace files、zero bulk data rows、0 scientific eigensolves、no reference/field/
   spectrum和no `.partial`在pending status前fail closed。Summary按MAT后CSV提交，external review status只能是
   `PENDING_SAME_SKEPTIC_POST_EXIT_REVIEW`。
5. **Formal science/no-leak通过。** Primary K-first/M-second evidence在`eigs`前checkpoint；同一in-memory
   canonical K/M进入`chol|eigs|normalization|orthogonality|residual`，raw full matrices/oracles、restricted full
   masses及rectangular cross-Grams不canonicalize。72 bulk +47 defect$=119$、40/48 sentinels、branch/coverage/
   refinement/$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ empirical-only boundary未改变。Executable source没有absolute
   repository path，也不读取Markdown/Git/history/prior output/external monitor/BIE/QZ/estimator/reference。
   `diagnostics/representation-gate-001/`与`output/run-006/`当前均不存在。
6. **Static MATLAB/API/signature audit通过但不冒充runtime。** 163个`LOCAL_` definitions无duplicate或undefined
   reference；shared parity output arities、writer calls及primary/derived signatures静态相容。使用的R2023b APIs
   (`onCleanup`, `tempname`, `unique(...,'stable')`, sparse `chol`, `movefile(...,'f')`, `all(...,'all')`)没有obvious
   syntax/API blocker；`git diff --check`通过。本项没有运行parser或`checkcode`，其剩余风险由create-once
   diagnostic fail-closed覆盖。

### AH.6 What survived

- Canonical rule仍是strict upper triangle + adjoint copy + real raw diagonal；没有averaging、shift、drop、reorder或
  tolerance relaxation。
- Derived basis synchronization、basis-invariant restricted spectra、endpoint-only parity、common-core normalized
  samples与rectangular cross-Gram的职责分离保持可审计。
- Diagnostic final namespace create-once、temporary benchmark cleanup、atomic publication、summary-last与
  no-history/no-reference isolation保持成立；任何complete或incomplete run都消费`representation-gate-001`，不得
  自动改名或重试。

### AH.7 Post-execution evidence obligations

同一 Skeptic必须在process完全退出后审查：exact command与cwd、shell exit、`/usr/bin/time -lp`的unrounded
`real`、maximum resident set size及peak memory footprint；terminal summary而非shell exit单独决定MATLAB status。
还必须直接核对14个required artifacts、所有上述exact counts/schemas、operator CSV/MAT equality与inventories、
header-only bulk ledgers、zero `eigs`/reference、no forbidden/no `.partial`、probe repetitions/CV/quantization、DP
partitions、261 rewrite identities/timings、strict forecast margin与internal array peak。Internal或external resource
gate失败都不得授权formal run；artifact/schema/API failure也不得自动retry，先回同一 review分类。

### AH.8 One-command authorization and hard boundary

**授权 Code Runner仅在** `test/i4/femref-a1` **执行一次：**

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('representation-gate-001','representation-diagnostic')"
```

External monitor至少每30 s记录MATLAB process tree alive与aggregate observed RSS；`/usr/bin/time -lp` stderr/terminal
record必须完整保留，不能写回diagnostic science namespace。Diagnostic envelope为2 min/1 GiB：wall达到120 s或
observed RSS达到$1{,}073{,}741{,}824$ bytes立即停止，无grace、无auto-retry。若提前结束，也必须保留namespace与
全部partial/final evidence并交同一 Skeptic。只有process退出后的same-Skeptic artifact/resource verdict才可决定
下一步；**本节绝不授权`run-006`、formal command、reference/effectivity reveal或project-result sync。**

Handoff：stage `I4.1a representation-gate-001 pre-execution`；category `IMPORTANT CAVEAT`；blocking scope
`run-006 and every reference/effectivity claim, not the one diagnostic command`；cheapest next check
`execute the exact command once under the 120 s/1 GiB monitor, then same-Skeptic post-exit audit`；suggested ledger
status `SPEC-TO-CODE PASS WITH CONDITIONS / REPRESENTATION-GATE-001 AUTHORIZED ONCE / RUN-006 NOT AUTHORIZED`。
项目ledger由主agent维护。

**Review literature verification completed.**

## AF. Independent spec-to-code/resource review after design §22.15

### AF.1 Audit frame

Target是 current `test/i4/femref-a1/run_i4_1a.m`、`README.md`、`SYMBOLS.md` against design §§22--22.14及
Researcher §22.15 findings。当前成功标准是 static implementation足以进入一次 representation diagnostic
pre-execution gate；不是数值PASS。审查覆盖 canonical formulas/consumers、evidence-before-consumer、formal/
benchmark writer parity、resource timing、identities/counts、B3 alias、dispatch/call graph/create-once/no-leak/
zero-eigs边界。本节只追加review；没有改 code/design/docs/artifacts，也没有执行 MATLAB、Octave、Python或
diagnostic。

### AF.2 Verdict

**Verdict: `REVISE`（high confidence）。** Researcher §22.15的三个 blockers均由source直接证实：derived
objects在evidence checkpoint前已被normalization/`eig`消费；261-checkpoint benchmark没有执行formal v2
payload/inventory/type/publication path；endpoint diagnostic复制而非复用formal parity path。Resource和terminal
evidence另有有界缺口。Canonical mathematics、continuous model、119-solve schedule与zero-eigs isolation仍然
成立。只授权同一 Engineer做AF.7列出的局部修复；不授权 diagnostic或`run-006`。

### AF.3 Strongest challenge

最强 failure mode是“artifact显示representation已在consumer前冻结”这一核心 claim为假。
`LOCAL_normalize_defect_clusters`在global row仍位于`pending_rows`时已执行`initial_reduced / normalizer`、
$P_\phi V$和rechecks；`LOCAL_gap_clusters`在restricted/parity rows仍pending时调用`eig`，并在common-core row
pending时执行`common_samples/common_factor`。成功路径到每solve末尾才写batch。若consumer或recheck失败，
ledger只能事后发布，无法证明失败前使用的是已冻结对象。这正是§22.12.4的pre-consumer gate要排除的情形，
必须先用prepare/checkpoint/consume passes修复。

### AF.4 Findings

1. **`BLOCKER` — derived checkpoint发生在first scientific consumer之后。** Locations：
   `LOCAL_normalize_defect_clusters` current lines 4155--4205；`LOCAL_gap_clusters` current lines 4828--4937。
   Evidence：global `/R`和$U=PV$在checkpoint前；restricted/parity `eig`在checkpoint前；common-core `/factor`
   与orthogonality recheck在checkpoint前。Current success schedule只有47 global +47 combined
   restricted/parity/common checkpoints，而非formal contract的47+47+47。Consequence：reached evidence与
   first-use ordering不可审计，formal checkpoint schedule也不匹配resource benchmark。Repair：每defect solve
   分三阶段：(a) prepare全部reached global rows/canonical factors，atomic checkpoint，再normalize/synchronize；
   (b) prepare全部restricted/parity rows/canonical matrices，atomic checkpoint，再`eig`；(c) prepare全部
   common-core self rows/factors，atomic checkpoint，再normalize/publish samples。Evaluation failure先checkpoint
   reached rows再raise。Post-checkpoint normalization/eig/recheck failure不得retroactively改已提交的
   representation row或追加duplicate row；它应由existing terminal failure ledger承载，从而保持immutable
   first cause和10414/261 bounds。
2. **`BLOCKER` — 261 rewrite benchmark不是formal v2 writer。** Location：
   `LOCAL_benchmark_growing_writer` current lines 1664--1725 versus
   `LOCAL_write_operator_representation` lines 3799--3835。Evidence：benchmark payload仅五个fields，MAT timer在
   payload construction后才开始；未调用`LOCAL_assert_operator_rows`，未构造primary/derived inventories、
   first-failure/model/planned/checkpoint metadata；padding rows全部parent为空，因而formal growing derived-parent
   inventory的去重/循环成本完全未测。Consequence：`rewrite_seconds`可能严重低估formal writer，strict
   $<1800$ s forecast无效。Repair：抽取formal与benchmark共同使用的pure payload-preparation与publication
   functions；benchmark prefixes必须包含238个parent-empty primary-shaped rows及至多10176个nonempty-parent
   DRV2-shaped rows，执行同一assert/inventories/metadata/MAT/CSV atomic path。每checkpoint timer在shared
   preparation前开始并在两次atomic move后结束；任何inventory优化必须两边共享。
3. **`BLOCKER` — endpoint parity diagnostic不是same-helper验证。** Location：formal block in
   `LOCAL_gap_clusters` versus `LOCAL_probe_parity_path` current lines 1496--1513。Evidence：两处独立重复
   reflection/compression/canonical/`eig`。Consequence：diagnostic即使PASS也不能证明formal parity plumbing相同，
   且future drift不会被gate捕获。Repair：抽取pure parity prepare helper（形成reflection compression、
   canonical evaluation/evidence）和consume helper（`eig`/finite result）；formal在prepare后先checkpoint再
   consume，diagnostic endpoint $\vartheta=0$计时同一prepare+consume，无formal-ledger混入。
4. **`IMPORTANT CAVEAT` — row-preparation与rewrite timing gates未完整实现。** Location：
   `LOCAL_measure_row_preparation` lines 1615--1649及writer lines 1696--1722。Evidence：10414-by-36 dimensions与
   `LOCAL_assert_operator_rows`只在五次timed actions全部结束后执行，故timing排除了required gate；warmups也
   不过gate；row repetitions没有explicit nonfinite/negative rejection。Single rewrite的MAT/CSV/checkpoint/
   cumulative fields也未在forecast前逐项finite/nonnegative gate。Consequence：resource row可能把不完整或
   非法timing提升为internal benchmark complete。Repair：把build+exact dimensions+same type/width assert放入
   每次warmup/timed action，保留最终container；复用`LOCAL_measure_repeated`等价的finite/nonnegative/CV/floor
   semantics；rewrite完成后逐行验证timings与monotone row/checkpoint identities，再允许forecast。
5. **`IMPORTANT CAVEAT` — exact evidence identities尚有漂移。** Location：
   `LOCAL_prepare_primary_pair`及`LOCAL_gap_clusters`/diagnostic width rows。Primary literals当前为
   `stiffness-reduced`/`mass-reduced`而frozen names是`reduced-stiffness`/`reduced-mass`；restricted IDs多出
   `restricted-`前缀；global width probe把parent OP2同时写进contract与parent columns，而不是DRV2 global-probe
   ID。Consequence：v2 rows不能按冻结object vocabulary和parent graph machine-audit。Repair只改evidence
   literals/IDs：使用latest non-superseded names；global probe生成deterministic
   `DRV2|<OP2>|global-probe|width-<m>`，OP2只留parent field。不得改数学对象或solver。
6. **`IMPORTANT CAVEAT` — pending terminal correctness gate不足。** Location：summary block current
   lines 1300--1304。Evidence：只检查2 mesh/3 seam/6 operator/294 probe rows；没有硬核对8 partition rows、261
   rewrite rows、one 27-column forecast row、10414-by-36 prepared container、operator checkpoint/inventory mirror、
   header-only zero-row bulk ledgers、zero eigensolve/reference artifacts或`.partial` absence。Consequence：缺失
   resource/artifact evidence仍可能获得`...PENDING_EXTERNAL_RESOURCE_REVIEW`。Repair：在pending status前逐项
   hard gate上述exact counts/schema/current-namespace artifacts；失败只能`REPRESENTATION_GATE_INCOMPLETE`。
7. **`MINOR CAVEAT` — B3是solve-ID join的明确non-solve exception。** Location：
   `LOCAL_bulk_inventory` current lines 4298--4311。B3 rows以`role='alias-reuse-no-solve'`和
   `B3-reuse-B4-pXX` synthetic ID复用odd B4 cache，不拥有primary OP2。Scientific semantics保持原frozen B3
   alias且未增加solve；但这些rows不能按字面`solve_id -> OP2`直接join。Engineer不得为“修复”它而增加solve、
   修改旧bulk schema或伪造primary row。后续design/ledger可把§22.13.5限定为actual formal solves，或另行增加
   machine-readable alias relation；本bounded code repair保持B3不动。

### AF.5 Implementation and call-graph audit: what survived

- `LOCAL_canonical_hermitian`严格使用upper triangle、adjoint copy和real diagonal；没有 averaging、shift、drop、
  reorder或full-matrix repair。Raw gates先于canonical construction；canonical mass/self-Gram使用two-output
  `chol`和positive real diagonal gate。
- Formal primary pair在K-first/M-second两行checkpoint后才进入`eigs`；同一 in-memory canonical K/M用于
  `chol|eigs|normalization|orthogonality|residual`，没有raw fallback。Stiffness failure后的mass raw-only empty
  fields语义正确。
- Cluster $G_C$使用canonical reduced mass，basis change是`V/R`后重建$U=PV$；restricted full masses、raw full
  matrices/oracles及rectangular cross-Grams不canonicalize。Interior parity为空且branch aggregate仍由endpoints
  决定。
- Formal 72+47=119、40/48 gates、branch/coverage/refinement/$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$与blindness
  未被representation改写。Old scientific CSV headers保持。
- Diagnostic dispatch只接受exact
  `representation-gate-001/representation-diagnostic`，final namespace create-once且当前不存在；它source-
  rebuilds 2 meshes/3 phases、没有`LOCAL_low_spectrum`/`eigs` call、没有history/Markdown/Git/external resource
  read，也不写field/spectrum/reference。`run-006` output当前不存在。
- Static helper-name inventory未显示undefined helper或obvious call-signature mismatch；这不是MATLAB parser/runtime
  结果。README/SYMBOLS保持“implemented/not run”边界，但必须在局部修复后机械同步locators/schema/status。

### AF.6 Resource and atomicity consequence

External `/usr/bin/time` authority与MATLAB pending summary仍正确解耦；2 min/1 GiB diagnostic envelope、29.8 min
baseline、strict formal `<1800` s/1.5 GiB internal gates和post-exit review规则可保留。当前不能执行的原因不是
预计结果已超限，而是 benchmark尚未测formal writer、timing completeness可被漏过。修复后如果shared full
writer或conservative DP给出无正余量，唯一合法结果仍是`RESOURCE_BUDGET_UNAVAILABLE`；不得删rows/checkpoints
或调整科学规格。

### AF.7 Bounded repair authorization

**只授权同一 Engineer在 existing attempt做以下局部修复：**

1. 将global、restricted/parity、common-core改为prepare/checkpoint/consume passes，并保持每solve至多
   1+1+1 derived checkpoints、immutable rows和existing terminal failure path；
2. 抽取formal/benchmark共享的v2 payload preparation与atomic publication；构造238 primary-shaped +10176
   derived-parent-shaped padding schedule并完整计时261 checkpoints；
3. 抽取formal/diagnostic共享parity prepare/consume helpers；
4. 把10414-by-36 type/width gate纳入每次row-prep timing，并补齐row/rewrite finite/nonnegative/monotone gates；
5. 机械修正primary/restricted object literals及global-probe DRV2 parentage；
6. 补齐pending summary前的exact count/schema/artifact/zero-eigs/no-reference/current-namespace checks；
7. 对existing `README.md`/`SYMBOLS.md`仅作上述function locators、schemas和“仍未运行”机械同步。

不得修改design/review/method/project docs、physical parameters、mesh/phase/formula/tolerances、119 schedule、
B3 alias或旧scientific schemas、branch/refinement/uncertainty、package/main code、historical artifacts；不得创建或
执行`representation-gate-001`、`run-006`、auto-retry、reference/effectivity reveal或project result sync。

### AF.8 Required next gates

修复后先由同一 Researcher重复§22.15 THEORY-TO-CODE audit并给明确PASS/REVISE；只有PASS后，回同一 Skeptic
做完整spec-to-code/resource re-review，重点逐行验证三个checkpoint boundaries、shared writer实际call graph、
261 schedule/inventories、shared endpoint parity helper、all timing/terminal gates和历史/namespace immutability。
只有该re-review无blocker，才可另行授权一次 exact diagnostic command；本节不授权execution。

Handoff：stage `I4.1a representation implementation repair`；category `BLOCKER`；blocking scope
`representation-gate-001 execution, run-006 and all reference/effectivity claims`；cheapest next action
`same Engineer performs exactly AF.7, then Researcher T2C and same-Skeptic re-review`；suggested ledger status
`SPEC-TO-CODE REVISE / BOUNDED ENGINEER REPAIR AUTHORIZED / NO DIAGNOSTIC OR RUN-006`。项目ledger由主agent维护。

## AD. Independent re-review of design §22.13

### AD.1 Audit frame

**Rigorous-proof mode: `Review only`.** Target是 existing `design-4-1a.md` §22.13 对 review §AC.6 的第二次
bounded revision。成功标准是：MATLAB entry不依赖external artifacts；post-exit resource authority不提前
宣称complete；size-aware/cluster-partition benchmark对正式新增成本给出可审查的保守估计；parity和OP2
artifact semantics保持冻结；create-once/retry/claim boundary足以交 Engineer implementation。本节只追加
review；没有修改 design/code/docs/artifacts，也没有运行任何数值程序。

### AD.2 Verdict

**Verdict: `REVISE`（high confidence）。** §AC的 external-resource blocker已关闭，cluster-partition DP及
artifact/summary authority也基本闭合。但仍有一个 bounded executable `BLOCKER`：diagnostic唯一 finest
defect phase冻结为 interior $\vartheta=\pi/4$，同时要求“实际形成 endpoint parity”路径；这与仍有效的
endpoint-only rule冲突。Engineer无法既复用formal helper又不在interior构造被禁止的parity operator。最小
修订只需在同一 finest mesh上额外形成 source-owned $\vartheta=0$ 或 $\pi$ 的 zero-eigensolve phase reduction
供 parity probe，保留 $\pi/4$ primary complex-phase sample。当前不授权 Engineer、diagnostic execution或
`run-006`。

### AD.3 Strongest challenge

§22.13.2把 full-height probes全部建立在 `defect-N5-s24-g48 at $\vartheta=\pi/4$`，随后又要求 endpoint
parity实际执行 $U_m^*M_hRU_m$。§22.12.6及§22.13.5却继续要求所有
$0<\vartheta<\pi$ slice不得构造 parity operator，formal cache也必须为空/N/A。若 Engineer让formal
endpoint helper在 $\pi/4$ 运行，便改变冻结的物理消费边界；若另写 diagnostic-only bypass，则 benchmark
不再验证同一 formal path。这个矛盾会直接阻止 theory-to-code/spec-to-code PASS，但不要求新方法或新
实验：同一已建mesh上无 eigensolve地形成 endpoint $P_0$ 即可关闭。

### AD.4 What survived

1. **MATLAB/external authority解耦通过。** MATLAB不等待、读取或搜索monitor/token/RSS/`time` output，
   terminal只能写 `PENDING_SAME_SKEPTIC_POST_EXIT_REVIEW`；外部monitor纯observational且不写science
   namespace。`/usr/bin/time`的final `real`/maximum RSS在process退出后才由同一 Skeptic审查，因此不再有
   summary-before-exit的虚假complete，也符合 `test/AGENTS.md` runtime portability。
2. **Post-exit gate通过。** Internal unrounded forecast/array evidence与external command identity、exit、
   whole-command wall/RSS分属明确authority。MATLAB pending status不自行授权下一阶段；external record缺失
   只得到 `RESOURCE_EVIDENCE_INCOMPLETE`，不能重跑补证。
3. **Primary sample保守方向通过。** Largest bulk `bulk-s24-g48`用于全部72 pairs，finest defect用于全部47
   pairs，消除了coarsest-bulk外推。Primary timings、derived algebra、row preparation和growing writer明确要求
   不重叠；writer的10414/261 cumulative cost只出现一次。
4. **Cluster-partition DP数学上成立。** 对任意positive partition $n=m_1+\cdots+m_k$，递推
   $C_a(n)=\max_m(a_m+C_a(n-m))$枚举全部ordered partitions，故在measured width-cost table上不低估任一
   partition。$42/5$ global/restricted/common-core counts和$12/2$ parity endpoint counts与冻结schedule一致；
   common-core按全部47 solves计算是允许的保守上界。
5. **Probe覆盖方向通过。** $m=1,\ldots,48$ 的full-height、full-rank $V_m^{(0)}$实际走 reduced Gram、
   canonical `chol`、`/R`、$P_\phi V$及两个recheck，关闭了§AC指出的只测48-by-48 tail问题。Restricted和
   common-core probes也形成actual full-height contractions，而非只测已形成dense matrix。
6. **Artifacts/summary通过。** 15/7/7/11/27-column ledgers及19-column summary独立计数一致；summary-last
   CSV只承诺MATLAB-owned internal completion，external review不回写。Hash要求已删除，header-only bulk
   ledgers、zero eigensolves/no reference、create-once namespace和any complete/incomplete ID consumption继续
   由§22.12继承。
7. **Parity aggregate与OP2 join通过。** Existing branch rows继续重复branch-level two-endpoint aggregate，
   interior cache为空但不清除ambiguity。Scientific rows以unique `solve_id` join到同一solve的K/M共享OP2；
   tight/count不同solve IDs可映射同一OP2，cache直接携带OP2，DRV2再指回parent。
8. **Claim boundary通过。** No averaging、raw full matrices/oracles、119 solves、branch/refinement/
   uncertainty rules和effectivity隔离均未改变。

### AD.5 Classified findings

1. **`BLOCKER` — parity resource probe的phase违反endpoint-only contract。** Location：§22.13.2 versus
   §22.12.6/§22.13.5。Evidence：唯一 defect probe phase是 $\vartheta=\pi/4$，却要求实际执行endpoint parity
   path。Consequence：formal helper要么越界在interior生成parity object，要么diagnostic另写不可代表formal
   path的bypass。Cheapest repair：primary/canonical sample仍用 $\vartheta=\pi/4$；在同一 rebuilt finest mesh
   上另调用 unchanged phase reduction形成 $P_0$（或$P_\pi$），由同一 deterministic $V_m^{(0)}$经该 endpoint
   pair形成 $U_m$并计时 formal parity helper。不得新增 eigensolve、scientific row、mode claim或另一mesh。
2. **`IMPORTANT CAVEAT` — aggregate row-preparation cost缺显式row count。** Location：§22.13.2--§22.13.4。
   Evidence：formula只加一次 $T_{\mathrm{row\ preparation}}$，文本“形成 schema-safe operator rows”未明确
   是全部10414 rows；15-column resource schema也没有row-count field。Consequence：若 Engineer只计一个row，
   会漏计；若 growing writer又包含padding construction，可能重复。Cheapest repair：冻结
   `row-preparation`为在timer内一次形成恰10414个36-cell padding rows、记录count=10414；growing-rewrite
   timer从prebuilt rows开始，只计261次conversion/write/rename。可在`notes`记录count，或新增明确field并
   version schema。
3. **`IMPORTANT CAVEAT` — point timing需要post-review保守性判据。** Location：§22.13.3。Evidence：DP对
   measured table是exact upper，但单次elapsed不是runtime upper，且formal余量最多12 s。Consequence：
   `1799.999...`的形式PASS未必支持“预计不超过30 min”。Cheapest resolution：pre-execution implementation
   必须拒绝nonfinite/negative timing，并用每个component的重复max或明确timer-resolution/safety floor；若
   diagnostic结果接近threshold到不足以覆盖measurement variability，同一 Skeptic post-exit review应判
   `RESOURCE_BUDGET_UNAVAILABLE`，不能仅凭一条rounded-below-threshold row授权formal run。该问题不阻止
   bounded implementation，但限制未来resource PASS。

### AD.6 Implementation audit and minimum revision

External authority、DP公式、strict internal
$T_{\mathrm{forecast}}<1800$ s、internal $\le1.5$ GiB与diagnostic external
$\le120$ s/$\le1$ GiB gates均可实现；诊断失败会产生resource/operational evidence而不是scientific mode
negative。Create-once、no auto-retry、history immutability和post-exit review顺序也足够明确。

但AD.5 item 1必须先在design层修正，item 2应同次机械闭合；item 3可作为implementation/post-run condition
冻结。**当前不授权 Engineer** 修改 canonical formal path、diagnostic或README/SYMBOLS，也不授权执行
`representation-gate-001`、创建`run-006`、运行formal command、同步project/effectivity文档。

若 bounded revision关闭上述phase与row-count问题，下一 gate可授权同一 Engineer只做：

- `run_i4_1a.m` 内 proof-backed canonical helper、formal K/M/cluster/derived consumer linkage、v2-36
  reached-evidence writer与 `representation-gate-001` source plumbing；
- existing attempt `README.md`、`SYMBOLS.md` 的机械schema/locator/dispatch同步。

该 implementation后仍必须先由同一 Researcher给 `THEORY-TO-CODE PASS`，再由同一 Skeptic完成完整
spec-to-code/resource review；只有后者通过才可另行授权 exact diagnostic command。Diagnostic post-exit review
通过 internal/external gates后才可讨论 `run-006`。本 review不授权任何 execution。

### AD.7 Open-problem handoff

Stage `I4.1a §22.13 representation diagnostic contract`；category `BLOCKER`；blocking scope
`Engineer handoff, representation-gate-001 execution, run-006, project/effectivity sync`；cheapest next check
`Researcher binds parity timing probe to an endpoint phase on the same finest mesh and freezes aggregate row-prep
count/timing boundary`；suggested ledger status
`§22.13 REVISE / EXTERNAL AUTHORITY AND DP VALID / ENDPOINT PROBE CONTRACT BLOCKED / NO IMPLEMENTATION OR RUN`。
项目 ledger由主 agent维护。

**Review literature verification completed.**

## AE. Independent re-review of design §22.14

### AE.1 Audit frame and verdict

**Rigorous-proof mode: `Review only`.** Target是 existing `design-4-1a.md` §22.14 对 review §AD.5 的 minimal
revision。审查目标是 endpoint parity sample不改变formal union；row preparation与writer不漏计/重复；timing
guard足以使近阈值结果 fail closed；授权范围停在 implementation而非execution。本节只追加review，没有修改
design/code/docs/artifacts，也没有运行 MATLAB、Octave、Python或任何数值程序。

**Verdict: `PASS WITH CONDITIONS`（high confidence）。** §AD唯一 blocker已关闭。Endpoint $\vartheta=0$
reduction、10414-by-36 all-row preparation和warmup/repeat/floor/near-threshold contracts均足以交同一 Engineer
作 bounded implementation。Conditions只约束后续 static mapping与resource computation的保守实现，不阻止
implementation；diagnostic和`run-006`仍未授权。

### AE.2 Endpoint probe, identities and count audit

1. Primary correctness samples仍是 largest bulk $\alpha=\pi/4$ 与 finest defect
   $\vartheta=\pi/4$，因此 complex-phase canonical path不被endpoint sample替代。额外 $\vartheta=0$ reduction
   复用同一 rebuilt finest mesh，不增加mesh，也不调用 `eigs`。
2. Endpoint path调用同一 periodic reduction、raw/canonical gates、mass `chol`、global normalization和formal
   parity helper。Interior $\vartheta=\pi/4$不再形成parity operator，故 endpoint-only物理边界和branch rules
   均保持。
3. Zero phase的`num2hex`部分为`0000000000000000`，endpoint OP2唯一；48个parity-probe DRV2按width指回该
   parent。Implementation仍须给这个diagnostic phase一个source-owned unique `solve_id`，但这只是后续静态
   locator/schema检查，不是design gap。
4. Diagnostic counts闭合：2 mesh rows、3 seam rows、3 phase reductions的6 K/M primary rows；六类
   width-indexed paths乘48得288 rows，再加用于formal forecast的largest-bulk/finest-defect三类primary
   timings各3 rows，共294 probe-cost rows。Endpoint phase/global setup只进入diagnostic own-budget的resource
   row，不混入formal additive forecast。
5. Formal union仍是119 pairs/238 primary rows。$t_D$已保守代表包括formal endpoints在内的47 defect primary
   pairs；$C_g$包含formal endpoint global normalization；$p_m$从同一 endpoint-normalized $U_m$就绪后开始，
   因而$12C_p(40)+2C_p(48)$不重复primary或global cost。Diagnostic的额外OP2/6 rows/294 timing rows不得进入
   formal 10414-row ledger，design已明确。

### AE.3 Row preparation, writer and resource gates

`row-preparation`现在从unallocated container开始，恰形成10414-by-36 schema-valid cells并运行type/width gate；
17-column resource row机器记录两个dimensions。Timer在任何serialization之前停止。`growing-rewrite`只消费
已经验证的prebuilt rows，按至多261 cumulative checkpoints计conversion/temp write/atomic rename，不重建
padding rows。故
$T_{\mathrm{row\ preparation}}+T_{\mathrm{growing\ rewrite}}$各出现一次，边界可静态审查。

Primary及width-indexed costs统一用2次discarded warm-ups、5次timed repetitions，并以

$$
t_{\mathrm{cons}}
=\max\left\{10^{-4},10^{-4}
\left\lceil\frac{\max_jt_j}{10^{-4}}\right\rceil\right\}
$$

进入DP/forecast；zero-looking interval不会变成0。任一nonfinite/negative repetition、CV大于0.25，或
$1800-T_{\mathrm{forecast}}$不超过1 s与propagated timing spread中的较大者，都 fail closed为
`RESOURCE_BUDGET_UNAVAILABLE`。Growing writer使用一次完整schedule而非乐观per-write mean，也符合目标。

Strict internal $T_{\mathrm{forecast}}<1800$ s、array forecast不超过1.5 GiB，以及post-exit whole diagnostic
不超过120 s/1 GiB均保持。MATLAB仍只给pending-external-review status；同一 Skeptic在退出后结合 exact
command、external wall/RSS和timing stability才可给resource verdict。不存在自动继承PASS。

### AE.4 Classified conditions and caveats

没有 unresolved `BLOCKER`。

1. **`IMPORTANT CAVEAT` — near-threshold spread必须按DP partition保守传播。** Location：§22.14.3。
   `sum_forecast_multipliers`在实现时不得只取一个global max-minus-min或只沿nominal fastest partition。
   Spec-to-code gate应要求：primary贡献使用$72\Delta t_B+47\Delta t_D$；每个$g/d/p/c$ family对
   $\Delta a_m=t_{m,\max}-t_{m,\min}$再作同一partition DP，并乘42/5或12/2 schedule counts；row-preparation
   spread乘1。Writer虽只有一次full trial，post-exit Skeptic仍可因external variability拒绝近阈值PASS。
2. **`IMPORTANT CAVEAT` — timing statistics必须machine-complete。** Implementation应固定finite/nonnegative
   raw repeat rows、sample CV的同一公式及mean-zero处理；任何undefined CV不得被序列化成一个通过值。两次
   warm-up虽不进入formal multiplier，diagnostic own elapsed/array budget仍必须包含它们。若first-call/JIT或
   timer resolution使external evidence与internal forecast不相容，post-exit verdict应降级resource unavailable。
3. **`MINOR CAVEAT` — diagnostic endpoint setup不是formal cost sample。** 其aggregate resource row必须明确
   `partition_role='diagnostic-own-budget-only'`，避免未来审查把它遗漏于diagnostic 2 min/1 GiB或误加到formal
   $T_{\mathrm{add}}$。这一点已由§22.14.1科学语义确定，可在code/doc机械映射时落实。

### AE.5 Authorization boundary

**授权同一 Engineer仅实现以下 bounded scope：**

- `test/i4/femref-a1/run_i4_1a.m` 中§22--§22.14的 one-triangle canonical helper；formal primary
  K/M、cluster $V/U$ synchronization、restricted/parity/common-core consumers；OP2/DRV2 linkage；v2-36
  reached-evidence/first-failure writers；以及 create-once `representation-gate-001` dispatch、probes、DP、
  row-preparation/rewrite、internal summary plumbing；
- existing `test/i4/femref-a1/README.md` 与 `SYMBOLS.md` 的必要机械同步，仅限dispatch、schema、artifact、
  function/symbol locator和未执行状态。不得把docs同步写成 diagnostic PASS或formal result。

不授权修改design/method/project docs、historical artifacts、physical/configuration parameters、119-solve
schedule、branch/refinement/uncertainty rules或package/main code；不授权执行
`representation-gate-001`、创建/执行`run-006`、auto-retry、reference/effectivity reveal或project-document
result synchronization。

### AE.6 Mandatory gates after implementation

1. **Researcher THEORY-TO-CODE gate：**逐项核对$\mathcal H$ identity/no averaging、raw-first gates、同一
   canonical K/M供`chol|eigs|normalization|orthogonality|residual`、cluster `V/R`与$U=PV$同步、endpoint-only
   parity、rectangular cross-Gram不canonicalize、OP2/DRV2 parentage、formal 119/238/10414/261与diagnostic
   6/294隔离、zero-eigs/no-reference/no-history boundary，并明确给 PASS/REVISE。
2. **同一 Skeptic pre-execution spec-to-code/resource gate：**只读审查完整source/doc diff，验证MATLAB API/
   syntax、all 36/17/16/7/11/27/19-column widths及MAT mirrors、first-failure/atomic/create-once semantics、exact
   $\vartheta=0$ parity dispatch、10414-by-36 preparation、261 writer、DP与spread propagation、summary pending
   semantics、formal path/no-leak/history immutability、absence of diagnostic namespace/`run-006`。只有该gate无
   blocker，才可另行授权 exact diagnostic command。
3. **Postdiagnostic gate：**只有一次authorized command结束后，必须审查全部internal artifacts、external exact
   command/exit/`real`/maximum RSS、2 min/1 GiB envelope、strict formal forecast/array gates和timing stability。
   只有该review PASS才可另行考虑`run-006`；本节不预授权。

### AE.7 Handoff

Stage `I4.1a §22--§22.14 canonical representation implementation`；category `IMPORTANT CAVEAT`；blocking scope
`diagnostic execution and run-006, not bounded implementation`；cheapest next check
`same Engineer implements exactly the authorized code/docs, then Researcher T2C and same-Skeptic spec-to-code`；
suggested ledger status
`§22.14 PASS WITH CONDITIONS / ENGINEER IMPLEMENTATION AUTHORIZED / REPRESENTATION-GATE-001 EXECUTION AND RUN-006 NOT AUTHORIZED`。
项目 ledger由主 agent维护。

**Review literature verification completed.**

## AG. Current control note for the §22.15 spec-to-code/resource review

The full independent audit is recorded in §AF. Sections §AD--§AE were appended concurrently from earlier bounded
design-review turns, so this control note fixes the current authority without deleting or reordering append-only history.

**Current verdict: `REVISE`（high confidence）。** The three unresolved blockers are exactly: (1) global,
restricted/parity and common-core DRV2 evidence is not atomically checkpointed before its first normalization/`eig`/
factor consumer; (2) the 261-checkpoint benchmark does not exercise the formal v2 payload, inventories, assertions and
atomic CSV/MAT publication path; and (3) the endpoint parity diagnostic duplicates rather than shares the formal parity
helper. The row-preparation/rewrite gates, exact object identities and terminal exact-count checks are the bounded
important corrections listed in §AF.4. B3 remains a scientifically valid zero-solve alias exception and must not be
turned into a new solve, a fabricated OP2 row or an old-schema change.

Only the same Engineer is authorized to perform the bounded repairs in §AF.7, including mechanical existing
`README.md`/`SYMBOLS.md` synchronization. This does **not** authorize creation or execution of
`representation-gate-001`, any MATLAB/Octave/Python execution, `run-006`, auto-retry, artifact mutation, reference/
effectivity reveal or project-result synchronization. After repair, the required gates remain same-Researcher
THEORY-TO-CODE review followed by same-Skeptic full spec-to-code/resource re-review.

**Review literature verification completed.**

## AI. Current control note after the §22.16 re-review

The complete current pre-execution audit is §AH. It supersedes §AF/§AG only as to the status of the now-completed
AF.7 repair; all historical findings and prior run verdicts remain unchanged.

**Current verdict: `PASS WITH CONDITIONS`（high confidence for static readiness）。** No unresolved blocker remains.
The exact one-command `representation-gate-001` diagnostic is authorized once under the §AH.8 120 s/1 GiB external
stop boundary and 30 s process/RSS monitoring. The full `/usr/bin/time -lp` terminal record and all diagnostic artifacts
must return to the same Skeptic for post-exit review. This does not authorize `run-006`, automatic retry, reference/
effectivity reveal or project-result synchronization.

**Review literature verification completed.**

## AJ. Postdiagnostic audit of `representation-gate-001`

### AJ.1 Audit frame and evidence authority

Target是唯一authorized command在 `test/i4/femref-a1` 形成的 preserved
`diagnostics/representation-gate-001/` namespace。成功标准原为：完整zero-scientific-eigensolve representation
correctness/resource artifact、external wall$<120$ s且maximum RSS$<1$ GiB，再由同一 Skeptic决定是否可讨论
formal run。Repo artifacts由本节直接检查；exact command、process samples、exit和`/usr/bin/time -lp`数字来自
Code Runner external record，未写回science namespace。本节没有改code/design/docs/artifacts，也没有执行任何
程序或数值计算。

### AJ.2 Verdict

**Postdiagnostic verdict: `BLOCKED`（high confidence）。** `representation-gate-001`是
**`INCOMPLETE / EXTERNAL_RESOURCE_BUDGET_UNAVAILABLE`**，不是complete representation PASS，也不是FEM/
guided-mode scientific negative。约73 s时observed RSS已越过冻结1 GiB stop gate，runner按授权立即中断；因而
缺失probe/resource/rewrite/forecast/summary是预算截停后的expected incomplete boundary，而不是已证明的source/
schema bug。该资源failure是阻止`run-006`的unresolved `BLOCKER`。Diagnostic ID永久消费；不授权rerun、换ID、
code repair或formal run。

### AJ.3 Strongest challenge

最强且决定性的failure mode已经发生：在尚未发布任何width-probe/resource ledger、尚未进入10414-row preparation
和261-writer benchmark前，MATLAB RSS已经超过1 GiB。即使reached primary objects全部PASS，也不能外推未执行的
294 probes、DP、writer成本或strict $29.8\,\mathrm{min}+T_{\mathrm{add}}<30\,\mathrm{min}$。因此没有证据支持
formal run的representation completeness或resource feasibility；`run-006`必须保持冻结。

### AJ.4 Direct artifact audit

1. Final namespace只有7个files：`bulk-bands.csv`、`bulk-gaps.csv`、`mesh-ledger.csv`、
   `seam-checks.csv`、`operator-representation.csv/.mat`、`progress.csv`。没有任何`.partial`，
   `output/run-006/`不存在。MAT文件被识别为valid MATLAB v7.3 container；在禁止MATLAB/Python执行的本节没有
   解码其payload，且这不改变下述decisive resource verdict。
2. `bulk-bands.csv`与`bulk-gaps.csv`各只有header，宽度分别10/14。`mesh-ledger.csv`为header+2 rows且每行
   36 columns；largest bulk与finest defect均到
   `REPRESENTATION_DIAGNOSTIC_MESH_COMPLETE`，planar/reflection/material gates pass。
   `seam-checks.csv`为header+3 rows、每行12 columns，覆盖bulk $\alpha=\pi/4$、defect
   $\vartheta=\pi/4$与$\vartheta=0$。
3. `operator-representation.csv`为header+6 rows且每行36 columns。三个K/M pairs各共享一个deterministic OP2；
   object IDs恰为`reduced-stiffness`/`reduced-mass`，parent均empty。六行均`EVALUATED_PASS`、raw/canonical
   nonfinite count 0、canonical exact-Hermitian true、canonical Hermitian defect 0、gate true；三个mass rows均
   `chol` flag 0。该证据只建立largest-bulk/finest-defect两phase加endpoint的primary representation。
4. `progress.csv`只有`HEADER_FIRST`、`SOURCE_MESH_REBUILD`、`THREE_PRIMARY_PAIRS`三个complete data rows，最后
   elapsed约2.779 s；没有`INTERNAL_BENCHMARK` checkpoint。缺失的7个required terminal artifacts恰是
   `representation-resource.csv`、`representation-probe-costs.csv`、
   `representation-partition-bounds.csv`、`representation-rewrite-benchmark.csv`、
   `representation-forecast.csv`、`diagnostic-summary.csv/.mat`。所以没有294-probe、8-partition、261-rewrite、
   one-forecast、internal gate或summary commit evidence。

### AJ.5 Budget and termination audit

Exact external command与AH.8 authorization相同。Runner记录约48 s MATLAB RSS为996384 KiB，仍低于
$1{,}048{,}576$ KiB；约73 s为1266400 KiB，已经越界并立即`Ctrl-C`。Process在`real 80.74` s结束，exit 1；
`user 404.94` s、`sys 171.73` s反映parallel work而不改变wall gate。`/usr/bin/time -lp` maximum resident set
size为1355071488 bytes，明确大于$1{,}073{,}741{,}824$ bytes；peak memory footprint 777329920 bytes虽较低，
但冻结判据是RSS，不能用footprint替代。Wall未到120 s，memory gate已先失败。Monitor/termination符合授权，
没有预算违规或grace。

### AJ.6 Classified findings and retry ledger

1. **`BLOCKER` — representation diagnostic超过external RSS envelope且未完成。** Evidence：monitor crossing、
   maximum RSS及missing terminal ledgers。Consequence：representation/resource gate未通过，formal preflight/
   `run-006`不可解释也不可启动。Cheapest next action不是rerun；保持blocked。若未来要研究更低内存但等价的
   evidence acquisition，必须由Researcher提出新bounded specification并取得用户明确授权，再经同一设计/
   code gates；本节不预授权。
2. **`IMPORTANT CAVEAT` — reached primary PASS不可提升为all-representation PASS。** 六行只覆盖primary K/M。
   Width-indexed global/restricted/parity/common-core paths可能已在memory中部分执行，但没有atomic ledger，故其
   completion、timing与result均unknown。不得从process duration或absence of `.partial`作有利推断。
3. **`MINOR CAVEAT` — operator MAT payload未在本只读/no-runtime gate解码。** CSV、file identity和atomic final
   presence足以审计reached primary boundary；即使MAT mirror另有问题，resource blocker与no-run conclusion不变。

`representation-gate-001`无论PASS或incomplete均create-once，现已永久消费。该run是preformal diagnostic，
不消费新的scientific method attempt；但它也不给任何same-ID retry entitlement。不存在`run-006`，不授权
`representation-gate-002`、改ID、auto-retry、implementation repair或另一command。

### AJ.7 Numerical and claim boundary

Defensible claim仅为：两张source-rebuilt mesh与三条phase seam到达；三个primary canonical K/M pairs通过raw/
exact-Hermitian/canonical-mass-Cholesky gates；未调用formal scientific `eigs`，未生成band/gap data row、field、
branch或reference。不能声称shared parity全width、all derived objects、10414/261 writer、internal forecast、
guided-mode eigenpair、reference resolution或effectivity得到验证。这个结果不是对fitted-FEM method的scientific
反例，也不改变任何历史公式、证书或结论。

### AJ.8 Final action and project synchronization

- **`run-006`：不授权。** 不授权任何formal command、retry、new diagnostic ID、code/design change或artifact
  mutation。
- Same Researcher若无新的用户授权，应在此停止；不得为通过budget而删probe、rows/checkpoints、放宽1 GiB或
  改变scientific contract。
- Post-run review现已完成，因此project-level `STATUS.md`可以由主agent作最小状态同步，仅记录
  `representation-gate-001 INCOMPLETE / EXTERNAL_RESOURCE_BUDGET_UNAVAILABLE`、primary reached evidence与
  `run-006 NOT AUTHORIZED`。不得同步guided-mode numerical result、reference collection、effectivity result或
  I4.1完成结论，也不得更新method claim为PASS。

Handoff：stage `I4.1a representation diagnostic post-run`；category `BLOCKER`；blocking scope
`run-006, formal reference computation and every reference/effectivity claim`；cheapest next action
`stop and preserve artifacts; any redesigned diagnostic requires new explicit user authority and full gates`；suggested
ledger status `REPRESENTATION-GATE-001 RESOURCE-BLOCKED AND CONSUMED / PRIMARY-ONLY REACHED / RUN-006 NOT AUTHORIZED`。
项目ledger由主agent维护。

**Review literature verification completed.**

## AL. Spec-to-code/resource pre-execution review for `representation-gate-002`

### AL.1 Audit frame

Target是 [[research/projects/eig-apost/implementation/i4/design-4-1a|design §§23--24]]、current `test/i4/femref-a1/run_i4_1a.m`、`README.md`、`SYMBOLS.md`、preserved `diagnostics/representation-gate-001/` 与 prospective 002/run-006 path。问题是：bounded implementation是否忠实实现用户授权的create-once zero-scientific-eigensolve representation diagnostic，并能否在不改变science/evidence workload的前提下，以external actual aggregate process-tree RSS达到$2147483648$ bytes作为002唯一memory stop进入一次正式diagnostic execution。

当前阶段是spec-to-code/resource pre-execution gate；目标artifact是representation correctness/resource evidence，不是guided-mode eigenpair、reference collection或effectivity result。Authority顺序为用户本轮明确授权、`test/AGENTS.md`、design §23、review §AK、Researcher §24、current source/docs。成功标准是exact ID/namespace、no-001 reuse、no lower memory stop、unchanged schemas/counts/zero-eigs boundary、可执行external monitor和continued `run-006` freeze。本审查只读；没有运行MATLAB、Octave、Python、parser、diagnostic或formal command。

### AL.2 Verdict

**Pre-execution verdict: `PASS WITH CONDITIONS`（high confidence for static readiness）。** 没有 unresolved `BLOCKER`。Current source已把002 identity和memory-policy exception限定在exact validated dispatch；002的internal terminal path不再消费1.5 GiB observation，也没有1 GiB/1.5 GiB actual-RSS stop或memory early return。Scientific workload、artifact contract和formal 1.5 GiB preflight均保持。下述conditions是一次execution及postreview的外部控制条件，不要求新设计或实现修订。

**仅授权在AL.8所列external monitor下执行恰一次§23.7 exact `representation-gate-002` command。** 不授权`run-006`、auto-retry、003、reference/effectivity reveal或project-result synchronization。

### AL.3 Strongest challenge

最强failure mode是旧1.5 GiB forecast通过另一个consumer、early return或failure reason暗中使002在actual RSS低于2 GiB时停止或被标成memory failure。Static call/data-flow audit refutes该路径：source仍计算`peak_pass`并把它写入`forecast_at_most_1p5_gib`，但exact 002 branch只令`internal_pass = wall_pass && timing_pass`；002 failure reason只列strict wall、CV/timing与propagated spread；terminal block只消费这个dispatch-local `internal_pass`。Completion gate不另读`peak_pass`，source也没有actual-RSS query或1 GiB literal。若runtime artifact与该静态结论矛盾，postdiagnostic review必须判implementation/operational failure，不得运行`run-006`。

### AL.4 Exact implementation audit

1. **Dispatch与signature通过。** Entry只接受exact `representation-gate-001`/`representation-diagnostic`与`representation-gate-002`/`representation-diagnostic` pairs，二者将已经验证的ID传给唯一`LOCAL_run_representation_diagnostic(diagnostic_id)` definition；其他ID/mode/alias/path fail closed。Targeted helper definitions和call arities静态一致，没有duplicate representation runner。
2. **Create-once与isolation通过。** Runner只由selected validated ID形成`diagnostics/<diagnostic_id>`，在任何current-run evidence access前检查该selected path collision。002不检查、读取、加载、stat、hash、copy或复用001；representation runner不调用source中formal current-run cache的`load` helpers。若002 namespace已存在即collision，不得覆盖、补齐、换ID或retry。
3. **Summary identity通过。** 002 summary的`diagnostic_id`与`expected_dispatch`分别是exact 002 ID和 `run_i4_1a('representation-gate-002','representation-diagnostic')`；terminal stub使用同一helper。19-field summary保持pending same-Skeptic external review，不预填resource PASS。
4. **Memory separation通过。** 002仍如实计算1.2 GiB baseline加array increment、`forecast_peak_bytes`及1.5 GiB observation，但该logical不进入002 `internal_pass`、early return、terminal memory failure或failure reason。001历史else branch仍是wall/peak/timing conjunction；formal `spec.preflight_peak_cap_gib=1.5`及formal preflight consumer保持不变。002 exception未扩散至formal path。
5. **Workload与schemas通过。** Source rebuild仍形成2 meshes、3 phases/seams和6 primary K/M rows；2 primary samples乘3 components给6 rows，六条width paths乘48给288 rows，总计294 probes；四families乘40/48给8 partition rows；padding硬核对238 primary加10176 derived等于$10414\times36$；writer schedule是header、119 primary、47 global、47 restricted/parity、47 common-core共261 checkpoints且row sum 10414。17/16/7/11/27/19及36-column schemas、MAT mirrors、header-only 10/14 bulk ledgers、summary-last、first-failure、atomic/no-partial gates未改变。
6. **Zero-eigensolve/claim boundary通过。** Whole source唯一scientific `eigs` call在formal low-spectrum helper；representation runner不调用该helper。Diagnostic only dense `eig` probes不产生scientific spectrum、field、branch、reference或effectivity export；completion gate要求0 completed scientific eigensolves、no reference export并禁止spectrum/field/reference files。
7. **Docs mapping通过。** README准确区分001 executed/consumed resource-incomplete history、002 prospective/not-run、2 GiB unique external stop、1.5 GiB observation和formal gate；SYMBOLS准确记录exact IDs、27-column observation及dispatch-local `internal_pass`语义。没有把pending status或002 implementation写成numerical/resource PASS。

### AL.5 Artifact and immutability audit

Direct read-only inspection仍见001 namespace恰有7个files：header-only 10/14-column bulk ledgers；header加2行的36-column mesh ledger；header加3行的12-column seam ledger；header加6行的36-column operator CSV及MAT mirror；header加3行的4-column progress ledger。该reached boundary与§AJ一致，未见补齐后的probe/resource/forecast/summary files。

Pre-execution freeze时 `diagnostics/representation-gate-002/` 与 `output/run-006/` 均不存在。001已消费且不是002 prerequisite；002 launch一旦开始，无论complete、incomplete、external stop、MATLAB/environment failure都消费002。不存在same-ID retry entitlement。

### AL.6 Classified findings

没有 `BLOCKER`。

1. **`IMPORTANT CAVEAT` — complete runtime与resource feasibility仍未知。** Location：尚未执行的294 probes、$10414\times36$ preparation及261 rewrites。Evidence：001在这些artifacts前被旧1 GiB gate停止，static source不能证明allocation、atomic filesystem cost、wall或peak RSS。Consequence：只限制postdiagnostic interpretation和`run-006`，不阻止一次获准diagnostic。Cheapest decisive test：AL.8 exact create-once command under the exact external envelope，随后same-Skeptic完整postreview。
2. **`MINOR CAVEAT` — 未进行MATLAB parser/runtime检查。** Current改动只使用既有MATLAB constructs和简单`strcmp`/one-argument signature change；targeted definitions/calls静态一致，未发现obvious API mismatch。Runtime syntax、allocation或filesystem failure必须原样保存为002 incomplete；不得自动修复重跑。
3. **`MINOR CAVEAT` — 两处研究Markdown含literal control character而不是LaTeX `\vartheta`。** Direct byte scan定位于design §24.5和review §AK.5附近。它不进入MATLAB、artifact schema、phase value或execution control，故不阻止002；但违反Markdown可读性/公式规范。因本阶段要求append-only历史，不应原位静默改写；在未来获准的机械文档维护中纠正，当前§AL使用正确`\vartheta`记法即可。
4. **`MINOR CAVEAT` — source header的Based-on范围停在§22.15。** README/SYMBOLS与actual code已明确§23 mapping，同一authoritative design文件未变，因此不影响spec authority或execution。可延期机械维护。

### AL.7 What survived scrutiny

- Continuous model、geometry/material/quasiperiodic phases、consistent $P_1$ weak form、canonical Hermitian construction、mass factorization、all tolerances和claim boundary均未改变。
- 001历史resource failure及primary-only evidence保持；002没有读取或利用其results。
- 1.5 GiB forecast作为future formal observation被完整保留，formal preflight仍fail closed；它不再是002 current-diagnostic memory control。
- 120 s whole-command wall、30 s-or-finer monitor、2 GiB exact actual-RSS threshold、no grace、no retry及same-Skeptic post-exit authority相互一致。
- `run-006`继续完全冻结；即使MATLAB返回pending，也不自动成为resource PASS或formal authorization。

### AL.8 One-command execution authorization and monitor contract

在working directory
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`，且launch前再次确认002 namespace不存在后，只授权恰一次：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('representation-gate-002','representation-diagnostic')"
```

External Code Runner必须满足：

1. 从MATLAB process出现起建立以该MATLAB PID为root的递归descendant集合；每个sample按unique live PID恰计一次RSS。Aggregate observed RSS定义为这些PID的`rss`之和乘1024 bytes；不得把launch shell或`/usr/bin/time`自身内存混入MATLAB tree，也不得用footprint、virtual size、internal array forecast或单一child代替aggregate RSS。
2. 在MATLAB root取得后立即采一次，随后采样间隔不得大于30 s；每行至少保存elapsed wall、process-alive、PID set/per-PID RSS及aggregate RSS。Monitor记录不得写入science namespace，也不得被MATLAB读取。
3. 第一次观测到aggregate RSS大于或等于2147483648 bytes时，立即停止同一MATLAB process tree；无grace、无下一sample等待、无retry。只要观测值低于该数，任何1 GiB、1.5 GiB、forecast或旧review文字都不得触发memory stop。
4. Whole command elapsed达到120 s时立即停止，无grace。Wall与2 GiB memory谁先到达谁控制stop。Monitor无法附着、无法取得可信aggregate RSS或丢失process identity时，按monitor/environment failure停止并保留证据；这不是较低memory gate，也不授权retry。
5. 完整保存start/final snapshots、all samples、stop/kill decision、shell exit及`/usr/bin/time -lp`的`real`、maximum resident set size、peak footprint、user/sys record。Post-exit peak authority取preserved aggregate samples与`time` maximum RSS中的较大者；若后者才显示达到2 GiB，仍判external resource failure。
6. 不拆分stage/subprocess重置120 s budget，不从001恢复，不删probe/row/checkpoint，不改command，不预创建002 namespace。Command一旦launch，002即消费。

### AL.9 Mandatory postdiagnostic handoff

执行结束后必须回到同一 Skeptic，在existing `review-4-1a.md`追加postdiagnostic audit，至少核对：

1. exact command/cwd/start/end、MATLAB root identity、30 s-or-finer完整process-tree/RSS trace、stop reason、shell exit及full `time -lp` record；
2. external wall与peak相对120 s和2147483648 bytes的判定，且1.5 GiB只作为separate internal observation；
3. 002 create-once namespace的全部final/partial files、atomic publication order、first failure和consumption status；
4. required/forbidden artifact集合，2/3/6/294/8/261/one-forecast exact counts，36/17/16/7/11/27/19 schemas与MAT mirrors；
5. all probe repetitions、CV、quantization floor、DP partitions、timing spread、$10414\times36$ preparation、261 rewrite identities与unrounded strict wall forecast；
6. `forecast_at_most_1p5_gib`、002 dispatch-local `internal_gate_pass`、terminal status/failure reason及pending external-review claim；
7. zero scientific eigensolves、header-only band/gap、no field/spectrum/reference/effectivity exports、001 unchanged及`run-006`absence。

只有该postreview完成且无blocker，才可另行讨论`run-006`。本节不预授权formal execution、retry、artifact repair、new ID或result synchronization。

Handoff：stage `I4.1a representation-gate-002 pre-execution`；category `IMPORTANT CAVEAT`；blocking scope `run-006 and every formal reference/effectivity claim, not the one authorized diagnostic`；cheapest next check `execute the exact 002 command once under AL.8 and return all internal/external evidence to the same Skeptic`；suggested ledger status `SPEC-TO-CODE PASS WITH CONDITIONS / EXACT 002 ONCE AUTHORIZED / RUN-006 BLOCKED`。项目ledger由主agent维护。

**Review literature verification completed; no external literature claim was required for this bounded implementation/resource audit.**

## AM. Postdiagnostic audit of `representation-gate-002`

### AM.1 Audit frame and evidence authority

Target是§AL唯一授权的exact create-once command在
`test/i4/femref-a1/diagnostics/representation-gate-002/`形成的reached artifacts，以及Code Runner提供的external process-tree/RSS、wall、interrupt、shell-exit和`/usr/bin/time -lp` record。Success criterion原为：在120 s whole-command wall和$2147483648$-byte aggregate observed RSS envelope内，完成全部zero-scientific-eigensolve representation correctness/resource artifacts，再由同一 Skeptic决定是否可以讨论`run-006`。

Repository artifacts由本节直接只读检查。Exact command/cwd、PID samples、interrupt timing和`time -lp`数字来自Code Runner external record；它们没有写回science namespace。本节没有修改design/code/docs/artifacts，没有执行MATLAB、Octave、Python或任何数值程序。External record和artifact一致表明该command只launch一次。

### AM.2 Verdict

**Postdiagnostic verdict: `BLOCKED`（high confidence）。** `representation-gate-002`应记录为
**`INCOMPLETE / EXTERNAL_MONITOR_PROTOCOL_FAILURE / WALL HARD LIMIT EXCEEDED`**；它不是memory failure，也不是FEM/guided-mode scientific negative。Preserved RSS samples与`time -lp` maximum均未达到$2147483648$ bytes，所以不得使用`EXTERNAL_MEMORY_BUDGET_UNAVAILABLE`或任何2 GiB exceeded表述。决定性失败是external samples约40 s才取得一次，违反不粗于30 s的freeze；whole-command `real 139.74` s又超过120 s hard wall，且interrupt/termination没有在hard limit前完成。Diagnostic required ledgers未完成，故representation/resource gate没有通过，`run-006`继续被unresolved `BLOCKER`阻止。

002 create-once ID已永久消费，不授权same-ID retry、新ID、code repair或formal run。该preformal zero-eigensolve diagnostic不消费新的scientific-method attempt；existing `femref-a1` attempt identity保持，不得创建下一attempt目录。

### AM.3 Strongest challenge

最强且已经发生的failure mechanism不是内存，而是external control未实现冻结的采样和wall-stop contract。相邻preserved samples约相隔40 s，monitor无法满足“30 s-or-finer”；尽管计划在约119 s发出`Ctrl-C`，tool/escalation scheduling及termination delay使whole command直到`real 139.74` s才退出。120 s没有grace，故不能把这19.74 s overrun视为允许的shutdown、soft limit或near-complete extension。即使reached primary rows全部通过，也不能把一个monitor-noncompliant、wall-overrun且没有terminal ledgers的process解释为complete diagnostic或resource feasibility evidence。

### AM.4 External budget and monitor audit

Exact authorized command在
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`启动一次。MATLAB root PID为75375；preserved process-tree samples为：

| Root elapsed | Main RSS | Descendant RSS | Aggregate RSS |
|---:|---:|---:|---:|
| 17 s | 738800 KiB | 121952 KiB | 881410048 bytes |
| 57 s | 834528 KiB | 122112 KiB | 979599360 bytes |
| 97 s | 1076208 KiB | 122128 KiB | 1227096064 bytes |

每个aggregate均按unique MATLAB-root tree RSS之和乘1024得到，均严格低于2147483648 bytes。`/usr/bin/time -lp`记录shell exit 1、`real 139.74` s、maximum resident set size 1154154496 bytes、peak memory footprint 846175360 bytes、`user 461.30` s和`sys 159.15` s。Post-exit peak authority取preserved aggregate samples与`time` maximum RSS的较大者，即1227096064 bytes，仍低于2 GiB；footprint不是RSS gate。

因此：

1. **Memory stop未触发。** 没有任何获保存actual-RSS authority达到2 GiB；不能把001的1 GiB或internal 1.5 GiB文字带入本次verdict。
2. **Monitor cadence失败。** 17--57--97 s gaps约40 s，超过30 s上限。
3. **Wall hard limit失败。** Whole-command authority是`real 139.74` s，大于120 s；无grace。Late interrupt不改变该判定。
4. **No retry。** Monitor/escalation/tool scheduling属于operational failure，但002已launch并消费；失败不得通过换ID、拆command或自动rerun抹去。

### AM.5 Direct artifact and primary-row audit

002 final namespace恰有7个files：`bulk-bands.csv`、`bulk-gaps.csv`、`mesh-ledger.csv`、`seam-checks.csv`、`operator-representation.csv/.mat`和`progress.csv`；没有`.partial`。MAT file被识别为MATLAB v7.3 container；本只读/no-runtime审查未解码其payload，但CSV和决定性external failure足以限定reached boundary。

1. `bulk-bands.csv`与`bulk-gaps.csv`各只有header，分别10/14 columns。没有band/gap data row。
2. `mesh-ledger.csv`是header加2行、每行36 columns。`bulk-s24-g48`与`defect-N5-s24-g48`均到`REPRESENTATION_DIAGNOSTIC_MESH_COMPLETE`；planar complex、reflection、material、boundary及intersection gates通过。
3. `seam-checks.csv`是header加3行、每行12 columns，覆盖bulk $\alpha=\pi/4$、defect $\vartheta=\pi/4$与同一defect mesh的$\vartheta=0$；coordinate mismatch为0，reached Hermitian/seam defects通过既有gate。
4. `operator-representation.csv`是header加6行、每行36 columns。三个phase pairs各有同一OP2下parent-empty的`reduced-stiffness`/`reduced-mass`两行；object dimensions分别是bulk 692和两组defect 7496。六行均`EVALUATED_PASS`、raw/canonical nonfinite count 0、canonical exact-Hermitian true、canonical Hermitian defects 0、gate true、first failure empty；三个mass rows均natural canonical `chol` flag 0。该证据只建立three-primary-pair representation boundary。
5. `progress.csv`是header加3行、每行4 columns，依次为`HEADER_FIRST`、`SOURCE_MESH_REBUILD`、`THREE_PRIMARY_PAIRS`，最后internal elapsed为2.6204025833333335 s。它不是whole-command wall，不能与139.74 s external authority替换。
6. 缺失的required terminal artifacts是`representation-resource.csv`、`representation-probe-costs.csv`、`representation-partition-bounds.csv`、`representation-rewrite-benchmark.csv`、`representation-forecast.csv`和`diagnostic-summary.csv/.mat`。因此没有atomic evidence证明294 probes、8 partitions、$10414\times36$ row preparation、261 rewrites、one forecast、1.5 GiB observation、002 `internal_gate_pass`或summary commit完成。

Code Runner报告001全部7个prelaunch digests在002退出后仍匹配；本review不展示human-facing hash values。Direct file identity/count inspection也与§AJ一致。`output/run-006/`不存在。

### AM.6 Classified findings and retry ledger

1. **`BLOCKER` — external monitor/wall contract失效且diagnostic未完成。** Location：external 40 s sample gaps、`real 139.74` s、missing terminal ledgers。Consequence：002不满足授权execution protocol，也没有complete correctness/resource artifact；`run-006`、formal reference computation和任何reference/effectivity claim均不可启动。Cheapest decisive action在当前authority下是stop and preserve；用户已明确no retry，故不提出same-ID rerun或replacement ID。
2. **`IMPORTANT CAVEAT` — primary PASS不能外推到all-width/DP/writer PASS。** 六个primary rows证明source-rebuilt meshes与three phase primary canonical pairs在reached boundary通过，但width probes可能只存在于interrupted process memory，没有atomic ledger。不得由长wall、低于2 GiB的RSS或absence of `.partial`推断294/8/10414/261完成。
3. **`IMPORTANT CAVEAT` — formal 1.5 GiB observation与strict time forecast均unknown。** `representation-forecast.csv`未形成，所以不能声称`forecast_at_most_1p5_gib` true/false、002 `internal_gate_pass`、$T_{\mathrm{forecast}}<1800$ s或timing stability。Observed external RSS below2 GiB不能替代这些future-formal preflight inputs。
4. **`MINOR CAVEAT` — MAT mirror未在本只读gate解码。** CSV rows、file presence/type及external blocker已足以给出no-run verdict；MAT payload的不确定性不会改变002 consumed/incomplete或`run-006` prohibition。

Retry ledger：002是一次authorized launch，现已consumed；status为primary-only reached、external protocol/wall incomplete。它不消费新的scientific attempt，因为0 scientific eigensolves且没有formal/reference output。不存在002 retry、003、new design、new review file或new attempt authority。

### AM.7 Numerical and claim boundary

Defensible statements仅为：两张source-rebuilt meshes与三条phase seam到达；三个primary canonical K/M pairs通过reached raw/canonical/factorization gates；全部保存RSS evidence低于2 GiB；0 scientific eigensolves，0 band/gap rows，no field/spectrum/reference/effectivity export。不能声称representation diagnostic complete、all derived paths通过、internal forecast成立、formal resource feasibility、guided-mode eigenpair、reference resolution或effectivity得到验证。

本次failure是external monitor/120 s wall operational-resource failure，不是2 GiB memory failure，不是FEM weak form、continuous model或guided-mode method的科学反例，也不改变任何公式、证书或历史结论。

### AM.8 Final action and synchronization authority

- **`representation-gate-002`：consumed / no retry。** 不授权补齐、覆盖、删除、rename、换ID或重跑。
- **`run-006`：不授权。** 不授权formal command、new attempt、reference/effectivity comparison或result promotion。
- §AM追加完成后，主agent可作最小status-only同步：project `STATUS.md`可记录002 consumed、primary-only reached、external monitor protocol failure、whole wall 139.74 s超过120 s、observed RSS未达到2 GiB和`run-006 NOT AUTHORIZED`。不得写成memory failure、scientific method failure、reference result或I4.1完成。
- Existing test `README.md`/`SYMBOLS.md`中prospective/not-run wording已变陈旧；可由主agent或same Engineer作机械status-only同步为002 consumed/incomplete、no retry、no run-006，不改变code、schema、science或历史001。Design/review旧段保持append-only，不原位改写。
- 不授权其他project/method/result文档同步；不更新guided-mode、reference collection或effectivity结论。

Handoff：stage `I4.1a representation-gate-002 postdiagnostic`；category `BLOCKER`；blocking scope `run-006, formal reference computation and all reference/effectivity claims`；cheapest next action `stop, preserve 001/002 artifacts, append this postreview and make only minimal status synchronization`；suggested ledger status `REPRESENTATION-GATE-002 CONSUMED / PRIMARY-ONLY REACHED / MONITOR NONCOMPLIANT / WALL HARD LIMIT EXCEEDED / 2 GIB NOT REACHED / RUN-006 NOT AUTHORIZED`。项目ledger由主agent维护。

**Review literature verification completed; no external literature claim was required for this postdiagnostic artifact/resource audit.**

## AN. Independent design review of §25 `representation-gate-003`

### AN.1 Audit frame

Target是 [[research/projects/eig-apost/implementation/i4/design-4-1a|design §25]] 的prospective `representation-gate-003` resource-policy amendment。当前问题是：能否在scientific/evidence workload完全不变时，以elapsed wall 1800 s和aggregate MATLAB process-tree RSS 2147483648 bytes作为唯一resource upper limits，通过fixed no-argument Perl watchdog取得一次create-once zero-scientific-eigensolve diagnostic，而不复用001/002或提前进入`run-006`。

当前阶段是pre-implementation design gate；目标output是representation correctness/resource-observation artifact和外部控制ledger，不是guided-mode eigenpair、reference collection或effectivity result。Authority为用户本轮明确授权、`test/AGENTS.md`、immutable reviews §§AJ/AM和design §25。成功标准是：只有两个resource hard stops；correctness/integrity failure不伪装成resource upper；watchdog能够安全、可复现地监控、kill、reap并发布external evidence；003 exact/create-once/no-history；advisory fields不阻止execution；`run-006`保持冻结。

本审查没有修改design/code/docs/artifacts，没有创建003/watchdog namespace，没有运行watchdog、MATLAB、Octave、Python或numerical computation。作了一次不启动project code的read-only system-Perl module availability probe：`POSIX::setpgid`与`Time::HiRes::clock_gettime`可用，`POSIX::fsync`未导出；这不是syntax/runtime validation。

### AN.2 Verdict

**Design verdict: `REVISE`（high confidence）。** 有两个unresolved `BLOCKER`，所以不授权Engineer、watchdog implementation、`perl -c`、003 execution或`run-006`。Scientific workload、identity/isolation与advisory schema方向可以保留；修订只需解决external controller的两组相互矛盾要求，不得扩展为新方法研究。

第一，§25同时要求persistent `ps` failure不得停止target，并声称2 GiB是hard upper。若RSS authority长期不可用而MATLAB继续增长，watchdog没有任何机制在aggregate RSS首次达到2 GiB时kill，hard cap即不可执行。第二，§25把outer Perl command的launch、monitor、kill、reap、atomic rename和summary全部计入strict 1800 s whole-command wall，却只在watchdog monotonic elapsed达到1800 s时才发`SIGKILL`，且要求kill后继续reap/finalize、无grace；outer `real`必然晚于该decision。Design必须先选择可实现且不冒充用户authority的wall/RSS failure semantics，再进入实现。

### AN.3 Strongest challenge

最小反例是：MATLAB在某个valid sample后继续分配内存，随后`/bin/ps`持续失败。按照§25.4，watchdog只能不断写`SAMPLE_UNAVAILABLE`并继续；即使actual MATLAB-tree RSS随后超过2147483648 bytes，也无法形成RSS predicate或kill decision。这不是“evidence稍弱”，而是hard upper失去执行机制。事后把run降为evidence insufficient不能撤销已经发生的超限风险。若不允许因monitor authority loss停止target，唯一可替代的是独立kernel-enforced aggregate process-tree cap；§25没有提供该机制，macOS per-process interfaces也不能由本稿自动视为aggregate-tree enforcement。

### AN.4 Classified findings

1. **`BLOCKER` — `ps` unavailable-and-continue规则与2 GiB hard cap不相容。** Location：§§25.3--25.4、25.9。Failure mechanism：一个或连续多个unavailable samples覆盖RSS crossing；watchdog没有aggregate value，按spec又不得停止，故不能保证hard limit。Consequence：本阶段的resource controller primary deliverable不可解释，也无法安全授权003。Uncertainty：不是推测性的数值风险，而是control-logic gap。Cheapest decisive repair：Researcher必须取得/记录一种明确authority——要么把loss of RSS measurement authority定义为non-resource operational-integrity kill（不声称2 GiB触发），要么冻结一个真正独立且可审查的kernel-enforced aggregate cap。若用户坚持“任何ps failure均不得停止”且不允许第二机制，则该目标在现有平台合同下应标为`BLOCKED`，不能靠postreview补救。
2. **`BLOCKER` — strict whole-command 1800 s与threshold-after-finalization顺序不可同时满足。** Location：§§25.3--25.6。Failure mechanism：watchdog从Perl runtime first statement设$t_0$，排除了interpreter startup；到$t-t_0\ge1800$才kill后，还必须reap、flush、rename、写summary并退出。即使每步极快，outer `/usr/bin/time` `real`仍严格大于1800 s；nonblocking reap又不能证明target/process group已消失。Consequence：无论实现如何，hard-stop run都会违反design自己的whole-command authority或留下unreaped target/incomplete terminal evidence。Cheapest decisive repair：Researcher必须明确选择：(a) 1800 s只约束MATLAB target active lifetime，post-kill bounded administrative finalization由outer `real`记录但不冒充grace；或(b) whole-command仍strict 1800 s，则需用户明确授权一个早于1800 s的control deadline/reserve并冻结其值；或(c)接受hard-stop时只有partial external ledger且watchdog在kill decision后立即退出，同时另证MATLAB tree必被OS清除。当前文本不能静默选择其中之一。
3. **`IMPORTANT CAVEAT` — hard-kill lifecycle缺少可证明的exec/PGID/reap state machine。** Location：§§25.2、25.4--25.6。Design要求“MATLAB child成功launch”才消费diagnostic ID，但没有冻结close-on-exec handshake来区分fork success与exec failure；parent `setpgid`/confirm failure后的安全路径未定义；hard stop只要求nonblocking reap，可能在child仍live时写final status并退出。Cheapest repair：冻结一个minimal lifecycle：CLOEXEC status pipe确认exec，child+parent双侧`setpgid`并验证`pgid==child_pid`且不同于watchdog group；所有negative-group kills前重验positive dedicated PGID；summary区分exec failure、kill-issued与child-reaped。若要求confirmed reap，则必须与Finding 2的wall authority一起修订。
4. **`IMPORTANT CAVEAT` — recursive descendants与PGID union尚不能声称覆盖全部reparent race。** Location：§25.4。Current wording每次只重建“current root descendants + current PGID members”。已观察过、随后reparent且离开PGID的worker可能从两个current sets同时消失。Cheapest bounded repair：维护本次run曾确认的descendant PID inventory，并在每个sample检查其live identity；为避免PID reuse，ledger/process identity至少需由PGID或可用start identity约束。若Engineer能证明MATLAB全部children始终继承并保持dedicated PGID，可在pre-execution review用static/runtime-free OS contract将此降级，否则不要声称union完全覆盖reparent。
5. **`MINOR CAVEAT` — external parent directory与flush primitive需机械澄清。** Freeze时`test/i4/femref-a1/watchdog/`不存在。Implementation需要区分可创建的container directory与create-once atomic leaf claim，不能把parent creation当成003 completion evidence。Local system Perl未导出`POSIX::fsync`；`IO::Handle::flush`等core flush可以满足当前“fsync/flush”二选一措辞，但不得声称durable fsync已完成。该点不影响两个核心blocker。

### AN.5 Resource limits versus correctness gates

这一部分通过审查，可在修订中原样保留：

- 1800 s/2147483648 bytes是resource controller唯一upper predicates；历史120 s、1 GiB/1.5 GiB、sample cadence、stall、RSS slope、footprint、single-process RSS、forecast、CV/spread及near-completion不得成为003 resource stop。
- Collision、canonical algebra、wrong schema/count、nonfinite scientific/evidence object、atomic write/move failure、information leakage或MATLAB exception是correctness/evidence-integrity failure；它们可以使MATLAB自然incomplete，但必须按first cause分类，不能伪装成resource threshold。
- 一个operational control invariant failure只有在修订明确赋予authority时才能kill；若获准，它必须记录为`WATCHDOG_OPERATIONAL_INCOMPLETE`，绝不能写成wall/RSS exceeded。这个分类不能解决未获授权继续运行时的2 GiB enforceability，故仍需Finding 1的选择。

### AN.6 Identity, schemas and scientific invariants that survived

1. 003 exact identity、two-argument allowlist、selected namespace collision、source rebuild与no arbitrary ID/path均清楚。MATLAB/watchdog均禁止读取、load、stat、hash、copy、compare或复用001/002；003/watchdog namespaces与`output/run-006/`当前均不存在。
2. 001/002 consumed histories不被改写；003 complete/incomplete都消费ID，不授权004/new attempt。只有MATLAB child confirmed exec后才消费diagnostic ID，external leaf claim则独立消费watchdog evidence identity。
3. 2 mesh、3 seam、6 primary、294 probe、8 partition、$10414\times36$ preparation、261 writer、one 27-column forecast、19-field summary及36/17/16/7/11/27/19 schemas保持；zero scientific `eigs`、no field/spectrum/reference/effectivity与claim boundary保持。
4. 27-column schema无需版本化。003 namespace、summary exact ID/dispatch以及`ADVISORY_RESOURCE_SCREEN_FALSE`/`OBSERVATION_ONLY_NOT_EXECUTION_FAILURE`前缀足以把`internal_gate_pass`降为dispatch-local historical observation。Probe CV false同样可用advisory code保存。关键implementation condition是003 terminal selection绝不能消费这些advisories；001/002/formal分支必须保持原语义。
5. Fixed no-argument, list-form MATLAB `exec`、`FindBin`-local path、dedicated PGID、recursive/PGID de-duplicated RSS、monotonic clock、1 s observational samples、external-only create-once logs及outer exact command方向合理。Outer `/usr/bin/time` maximum RSS不得当作MATLAB-tree RSS；postreview memory authority只能来自valid watchdog aggregate samples。若samples unavailable，outer maxRSS不能填补缺口。

### AN.7 Minimal resolution and authorization boundary

**当前不授权same Engineer。** Researcher只需对existing design §25作bounded append-only revision，并把以下选择冻结后交同一 Skeptic复审：

1. RSS measurement authority loss时的exact state machine：prelaunch baseline、single/transient failure、persistent failure、是否/何时operational kill，以及如何不把它写成第三resource upper；若禁止kill，必须给出另一可执行2 GiB enforcement mechanism。
2. 1800 s authority究竟约束MATLAB active lifetime还是outer whole command；kill/reap/log finalization与`time real`如何判定，不能同时声称“threshold at 1800”“whole command <=1800”“post-kill complete summary”“zero grace”。
3. exec-success handshake、safe dedicated-PGID confirmation、kill guards、known-descendant handling、wait/reap和summary fields在每个terminal branch的最小状态机。
4. Logging failure与samples unavailable的terminal classification及create-once consumption，不得用postreview retroactively发明resource stop。

Revision不得改scientific workload、schemas、continuous model、formal 1.5 GiB gate、001/002 history或`run-006` boundary。完成后由同一 Skeptic re-review；只有无blocker时才可授权same Engineer修改现有`run_i4_1a.m`/README/SYMBOLS并新增唯一watchdog source。`perl -c`、003 command及`run-006`当前均不授权。

### AN.8 Open-problem handoff

- Stage：`I4.1a representation-gate-003 external controller design`；category：`BLOCKER`；blocking scope：`watchdog implementation and 003 execution`；cheapest next check：`Researcher resolves RSS-monitor-loss authority and strict whole-command wall/finalization contradiction in one bounded append-only revision`；suggested ledger status：`§25 REVISE / TWO-LIMIT INTENT VALID / CONTROLLER ENFORCEABILITY BLOCKED / NO ENGINEER OR RUN`。
- Stage：`I4.1a representation-gate-003 process lifecycle`；category：`IMPORTANT CAVEAT`；blocking scope：`safe pre-execution approval after design repair`；cheapest next check：`freeze exec handshake, PGID guards, descendant inventory and terminal reap semantics, then static source audit`；suggested ledger status：`PENDING BOUNDED DESIGN REPAIR`。

项目ledger由主agent维护；本阶段不需要扩展到新方法、实验attempt或文献工作。

**Review literature verification completed; no external literature claim was required for this bounded controller-design audit.**

## AO. Independent Skeptic re-review of the section 26 controller repair

### AO.1 Audit frame

- **Audit target:** the controller-only repair frozen in [[design-4-1a#26. Controller repair after the section 25 `REVISE` verdict]].
- **Question:** whether section 26 resolves the two controller blockers recorded in section AN while preserving exactly two resource upper predicates: MATLAB target-active lifetime reaching $1800\,\mathrm{s}$ and authoritative aggregate MATLAB process-tree RSS reaching $2{,}147{,}483{,}648$ bytes.
- **Success criterion:** before implementation is authorized, the controller design must enforce both hard upper limits without a lower reserve or soft stop, must fail closed on loss of RSS authority without misreporting that event as a memory-limit crossing, and must consume and finalize the create-once namespaces without reading or reusing representation-gate-001 or representation-gate-002.
- **Authority and scope:** this is a read-only design re-review. It does not authorize implementation or execution. The continuous model, scientific zero-eigenvalue probes, 27-column scientific schema, row counts, dynamic-programming partition, writer, uncertainty interpretation, attempt identity, and claim boundary are outside the reopened issue and remain frozen.
- **Materials examined:** design sections 25--26; review section AN; `test/AGENTS.md`; the current representation driver/README/SYMBOLS contract; the preserved representation-gate-001 and representation-gate-002 namespace constraints; and the stated absence of representation-gate-003 and `run-006` before implementation.

### AO.2 Verdict

**`REVISE` (high confidence).** Section 26 successfully removes the two defects identified in section AN: RSS-authority loss is now an operational-integrity kill rather than a third resource upper predicate, and the $1800\,\mathrm{s}$ limit is explicitly scoped to MATLAB target-active lifetime rather than outer wrapper administration. Its CLOEXEC exec handshake, two-sided dedicated-PGID verification, guarded group kill, reap/dead confirmation, create-once separation, and rejection of outer `/usr/bin/time` maximum RSS as aggregate authority are materially sound. One hard-limit defect nevertheless remains: the frozen clock starts only after successful exec has already been observed, so MATLAB can execute before $t_0$ and before the one-shot alarm is armed; moreover, the alarm handler's frozen kill set covers only the dedicated process group even though section 26 permits known target descendants that have left that group. Those two paths can allow target work beyond the declared $1800\,\mathrm{s}$ target-active lifetime. A bounded controller-only revision is required before implementation.

### AO.3 Strongest challenge

The controller does not yet use one absolute deadline that begins at the earliest instant MATLAB is permitted to execute and covers every process classified as part of the MATLAB target. The parent sends `EXEC_GO`, the child successfully `exec`s MATLAB, and only after the parent observes CLOEXEC EOF plus PGID confirmation does section 26 define $t_0$ and arm `alarm(1800)`. The interval between release/exec and that later parent observation is target-active but uncharged. At the deadline, the signal handler directly kills only the dedicated PGID, while the design separately preserves live known descendants even after reparenting or PGID departure. Such a descendant can therefore survive the alarm until the main loop next regains control. Both are concrete mechanisms for exceeding the sole wall-time upper predicate.

### AO.4 Findings

1. **`BLOCKER` -- target-active time begins before the frozen clock and alarm.**
   - **Location:** design sections 26.3.3--26.3.4 and 26.7.2--26.7.3.
   - **Evidence:** after `EXEC_GO`, the child opens its external logs and performs the fixed MATLAB `exec`; successful exec closes the CLOEXEC status pipe. The parent defines the target-active zero point only after observing clean EOF, confirming that the child is not reaped, and re-verifying the PGID. The design then installs `alarm(1800)` at that later zero point.
   - **Consequence:** MATLAB can execute during the release-to-confirmation interval, and a fresh 1800-second alarm armed afterward permits more than 1800 seconds of actual target-active lifetime. This violates the exact resource contract even if the overrun is normally small.
   - **Uncertainty:** the size of the interval is runtime-dependent, but its existence follows from the prescribed ordering and does not require a numerical experiment to establish.
   - **Cheapest decisive repair:** record one monotonic $t_0$ when the parent sends `EXEC_GO`, because MATLAB cannot execute before that release; define the immutable absolute deadline as $t_0+1800\,\mathrm{s}$; do not reset $t_0$ after exec confirmation; after clean CLOEXEC EOF arm the one-shot alarm only for the positive remaining interval to that same deadline, and kill immediately if the deadline has already been reached. If exec fails, discard this provisional clock and retain the existing no-science-consumption classification. This is accounting from the earliest possible target activity, not an early reserve or lower stop.

2. **`BLOCKER` -- the one-shot deadline kill does not cover the complete frozen target set.**
   - **Location:** design sections 26.5, 26.6.2, and 26.7.3.
   - **Evidence:** section 26.5 intentionally retains identity-verified known descendants after reparenting or PGID departure, but the SIGALRM handler is constrained to immutable `child_pid`, `pgid`, and supervisor identities and directly performs the guarded negative-PGID kill. A known target descendant outside that PGID is not reached by the handler. Waiting for the main loop to process the alarm flag is not equivalent to the promised immediate hard-limit action, especially if the main loop is blocked in process-table acquisition or logging.
   - **Consequence:** a process still counted as part of the MATLAB target can remain active past the declared wall-time limit even though the dedicated process group has been killed.
   - **Uncertainty:** whether MATLAB will create or leave such a descendant in this run is unknown, but the controller explicitly admits that state and claims to enforce the hard limit over the aggregate target tree; the failure mechanism is therefore within the frozen controller's own state space.
   - **Cheapest decisive repair:** maintain the dedicated-PGID invariant as an enforceability condition: if any live identity-verified known target descendant is observed outside the verified dedicated PGID, classify that observation as controller/RSS-authority loss and issue the existing operational-integrity kill immediately, while retaining the known-PID inventory for positive cleanup and dead confirmation. Then every nominally running target member is guaranteed to be reached by the one-shot negative-PGID deadline kill. This is an operational-integrity rule, not a third resource upper predicate. An alternative must provide an equally safe alarm-time kill set without risking a reused PID; a stale mutable PID list in a Perl signal handler is not sufficient.

3. **`IMPORTANT CAVEAT` -- alarm and monotonic-loop decisions must share one immutable absolute deadline.**
   - **Location:** design section 26.7.3.
   - **Evidence:** section 26 states that one-shot alarm and loop checks enforce the same rule, but the implementation contract should forbid independently accumulating elapsed durations or rearming a fresh 1800-second alarm after exec confirmation.
   - **Consequence:** independent relative timers can drift or disagree at the boundary even after finding 1 is repaired.
   - **Cheapest decisive check:** pre-execution spec-to-code review must identify one stored monotonic `deadline`, show that both the remaining alarm interval and every loop comparison derive from it, and verify that `now >= deadline` has the same inclusive boundary as `aggregate_rss >= 2147483648`.

4. **`MINOR CAVEAT` -- outer wrapper resource numbers remain contextual only.**
   - **Location:** design section 26.9.
   - **Evidence:** `/usr/bin/time -lp` measures the wrapper process according to platform semantics and cannot replace the recursive-plus-PGID union used by the watchdog.
   - **Consequence:** none for controller acceptance if the post-run review keeps outer `real`/maximum-RSS fields separate and does not use them to declare either scientific resource gate.
   - **Cheapest decisive check:** inspect the post-diagnostic ledger labels; no extra experiment is needed.

### AO.5 Implementation audit boundary

No implementation exists to audit at this gate, and no execution is authorized. A later static review must verify all of the following against exact source:

1. fixed no-argument invocation and exact representation-gate-003 allowlist;
2. atomic external leaf claim and science-namespace consumption only after clean CLOEXEC-confirmed exec;
3. two-sided `pgid == child_pid`, `pgid > 1`, and `pgid != supervisor_pgid` checks before any negative-PGID signal;
4. one absolute monotonic deadline beginning at `EXEC_GO`, with one-shot alarm armed only for the remaining time and the loop using the identical inclusive predicate;
5. no live target member outside the dedicated PGID during nominal RSS-authority-valid operation, or another demonstrably safe complete deadline kill mechanism;
6. recursive-descendant plus PGID-union RSS de-duplication, stable PID/start-identity handling, and immediate operational-integrity kill on authority loss;
7. blocking reap plus valid dead/group confirmation before external finalization;
8. no lower memory or wall stop, no advance reserve, no grace, and no use of outer `/usr/bin/time` maximum RSS as aggregate authority;
9. unchanged scientific probe calls, schemas, counts, DP, row preparation, writer, and terminal scientific semantics except the already declared local operational enum/summary extension;
10. no read or reuse of representation-gate-001 or representation-gate-002 and no creation or launch of `run-006`.

### AO.6 What survived scrutiny

- The only scientific resource upper predicates remain $1800\,\mathrm{s}$ target-active lifetime and $2{,}147{,}483{,}648$ bytes authoritative aggregate RSS; section 26 introduces no lower reserve or soft threshold.
- Treating loss of RSS authority as `WATCHDOG_OPERATIONAL_INCOMPLETE / RSS_AUTHORITY_LOST / OPERATIONAL_INTEGRITY_KILL` is defensible and does not falsely report a 2 GiB crossing.
- Full-table process inspection, recursive-descendant plus PGID union de-duplication, stable PID/start identities, and preservation of known descendants are appropriate ingredients for aggregate-RSS authority.
- CLOEXEC exec confirmation cleanly separates external-controller consumption from scientific diagnostic consumption.
- Two-sided dedicated-PGID verification, guarded group signalling, direct-child reap, and target-dead confirmation resolve the unsafe-PGID and unbounded-finalization ambiguity raised in section AN.
- Bounded post-target ledger finalization outside the target-active interval is defensible provided it performs no scientific work and outer wrapper time is reported separately.
- The 27-column scientific schema, advisory historical forecast field, zero-eigenvalue probe contract, partition logic, row preparation, writer, and claim boundary remain unchanged; representation-gate-001 and representation-gate-002 remain immutable and consumed; `run-006` remains forbidden.

### AO.7 Minimal resolution and authorization

Add one controller-only design amendment that:

1. moves $t_0$ to the parent's monotonic `EXEC_GO` release instant and derives one immutable absolute deadline from it;
2. arms the one-shot alarm for the remaining time after exec confirmation and uses the same deadline in the monotonic loop; and
3. makes departure of a live known target from the dedicated PGID an immediate operational-integrity failure, or freezes another complete and PID-reuse-safe deadline kill mechanism.

Return that bounded amendment to the same Skeptic. **Until then, the same Engineer is not authorized to modify `run_i4_1a.m`, README, SYMBOLS, or add the watchdog source, and even static `perl -c` is premature.** No representation-gate-003 command, MATLAB process, retry, or `run-006` is authorized.

### AO.8 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Release-to-confirmation interval is excluded from target-active time | I4.1a representation controller design | `BLOCKER` | Controller implementation and representation-gate-003 execution | Bounded design amendment using one `EXEC_GO`-anchored absolute deadline | Open in `review-4-1a.md`; do not duplicate project ledger |
| Alarm kill omits known target descendants outside the dedicated PGID | I4.1a representation controller design | `BLOCKER` | Controller implementation and representation-gate-003 execution | Enforce PGID membership as an operational-integrity invariant or specify an equally safe complete kill set | Open in `review-4-1a.md`; do not duplicate project ledger |
| Perl alarm delivery and source-level state transitions | I4.1a pre-execution controller audit | `IMPORTANT CAVEAT` | Static authorization only after the two blockers are repaired | Same-Skeptic exact source review plus permitted `perl -c`; no MATLAB execution | Pending |

## AP. Independent Skeptic final controller-design re-review of section 27

### AP.1 Audit frame

- **Audit target:** the bounded controller amendment in [[design-4-1a#27. 2026-08-29 minimal controller amendment after review §AO]], read together with design section 26 and review sections AN--AO.
- **Question:** whether section 27 closes the two remaining controller blockers by using one `EXEC_GO`-anchored absolute deadline and by making dedicated-PGID membership an operational enforceability invariant, while retaining exactly two resource upper predicates.
- **Success criterion:** the design must count from the earliest instant at which MATLAB can be released, must never reset or replace that deadline, must kill immediately when the remaining interval is nonpositive, and must ensure that nominally active target members remain covered by the guarded dedicated-PGID kill. It must introduce no lower reserve or third resource threshold and must leave all scientific contracts and historical namespaces unchanged.
- **Authority and scope:** read-only final controller-design review. This section may authorize bounded implementation and static source checks, but it cannot authorize representation-gate-003 execution or `run-006`.
- **Materials examined:** design sections 26--27; review sections AN--AO; the frozen controller/resource contract in `test/AGENTS.md`; and the unchanged scientific/history boundaries stated in section 27.

### AP.2 Verdict

**`PASS WITH CONDITIONS` (high confidence).** Section 27 closes both blockers in section AO at design level. The single monotonic clock is now captured immediately before `EXEC_GO`, the immutable deadline is $t_0+1800\,\mathrm{s}$, neither clean exec confirmation nor any later event may reset it, and a nonpositive remaining interval requires immediate wall-limit kill instead of a fresh timer. The dedicated-PGID rule now makes any observed live known target outside the verified group an operational-integrity failure, so nominal deadline enforcement and known-descendant cleanup no longer rely on an acknowledged out-of-group target. The only resource upper predicates remain target-active time reaching 1800 seconds and authoritative aggregate RSS reaching 2,147,483,648 bytes. The conditions below concern faithful implementation and mandatory pre-execution review; there is no unresolved design blocker.

### AP.3 Strongest remaining challenge

The strongest remaining risk is implementation drift between three representations of one wall rule: the `EXEC_GO` release timestamp, the remaining interval passed to the one-shot alarm after exec confirmation, and the main-loop monotonic comparison. A fresh `alarm(1800)`, a reset of $t_0$, a strict `>` comparison, or a PID/group cleanup path that bypasses the dedicated-PGID invariant would silently recreate the rejected controller. This is now a source-review risk rather than a design defect and is decidable by exact static inspection before any execution.

### AP.4 Findings

1. **`IMPORTANT CAVEAT` -- the absolute deadline must remain a single source of truth in code.**
   - **Location:** design section 27.1.
   - **Evidence:** section 27 freezes $t_0$ immediately before the release write and defines exactly one immutable $t_{\mathrm{deadline}}=t_0+1800\,\mathrm{s}$. The alarm is armed only for the positive remaining interval after clean exec confirmation, while the loop uses `now >= deadline`.
   - **Consequence:** a source-level reset, a fresh relative 1800-second alarm, or inconsistent inclusive boundaries would violate the hard wall contract.
   - **Uncertainty:** no controller source yet exists to inspect.
   - **Cheapest decisive check:** the Researcher theory-to-code map and same-Skeptic spec-to-code review must trace one stored monotonic deadline into both alarm arming and loop comparison and must verify immediate guarded kill when `remaining <= 0`.

2. **`IMPORTANT CAVEAT` -- dedicated-PGID membership must be checked as part of every valid authority snapshot and preserved through cleanup.**
   - **Location:** design section 27.2, with sections 26.4--26.6.
   - **Evidence:** an identity-verified live known target with `pgid != dedicated_pgid` now requires `WATCHDOG_OPERATIONAL_INCOMPLETE / TARGET_LEFT_DEDICATED_PGID / OPERATIONAL_INTEGRITY_KILL`; it may not remain a nominal running state. Known identities remain available for positive cleanup and dead confirmation.
   - **Consequence:** omitting the membership test, treating it as a warning, or dropping the known inventory would reopen the incomplete deadline kill set.
   - **Uncertainty:** implementation is pending.
   - **Cheapest decisive check:** exact static review of the full-table parsing, membership branch, guarded negative-group kill, identity-verified positive cleanup, and post-kill dead confirmation.

3. **`MINOR CAVEAT` -- the release timestamp conservatively includes only the unavoidable dispatch interval.**
   - **Location:** design section 27.1.
   - **Evidence:** $t_0$ is captured immediately before writing `EXEC_GO`, the earliest causal point at which the child may proceed toward MATLAB exec. It is not an arbitrary earlier setup timestamp and cannot be reset later.
   - **Consequence:** a very small release/exec dispatch interval is charged to the target budget, but this is conservative enforcement of the authorized hard cap, not a lower reserve, soft stop, or third resource predicate.
   - **Cheapest decisive check:** verify the timestamp and release write are adjacent in source and that no unrelated setup is inserted between them.

No `BLOCKER` remains.

### AP.5 Controller and resource conclusions

1. The wall resource upper predicate is exactly the immutable absolute deadline $t_0+1800\,\mathrm{s}$, with $t_0$ captured immediately before `EXEC_GO`.
2. Exec confirmation consumes the science ID but does not reset the clock. `remaining <= 0` causes immediate guarded wall-limit kill; otherwise the one-shot alarm receives only that remaining interval.
3. The redundant monotonic loop and alarm implement the same inclusive deadline; they are not separate timers, reserves, retries, or grace periods.
4. The memory resource upper predicate remains exactly authoritative aggregate process-tree RSS `>= 2147483648` bytes.
5. Loss of RSS authority, loss of the dedicated-PGID invariant, kill-guard failure, or controller failure is an operational-integrity kill. None is a resource upper predicate or evidence that either numerical threshold was reached.
6. Nominal target operation requires every identity-verified live known descendant to remain in the verified dedicated PGID. The known inventory is still retained for PID-reuse exclusion, positive cleanup, and target-dead confirmation.
7. Outer `/usr/bin/time -lp` maximum RSS remains contextual wrapper evidence only and is not aggregate MATLAB RSS authority.
8. The continuous problem, FEM weak form, all frozen scientific counts and schemas, zero-scientific-eigensolve boundary, advisory historical forecast semantics, 001/002 immutable consumed histories, and the prohibition on `run-006` remain unchanged.

### AP.6 What survived scrutiny

- The CLOEXEC exec-status handshake still distinguishes a successful fixed MATLAB exec from a pre-exec controller failure and preserves the science-ID consumption boundary.
- Two-sided PGID verification and the release barrier prevent MATLAB from starting before the dedicated group is established.
- The repaired `EXEC_GO` clock removes the uncharged exec-confirmation interval identified in section AO without adding an early reserve.
- The new membership invariant removes the admitted nominal state in which an active known target could evade the alarm's group kill.
- Recursive-descendant plus PGID union RSS accounting, stable start identities, PID-reuse exclusion, guarded signalling, direct-child reap, and target-dead confirmation remain coherent with the repaired controller.
- Scientific schemas and interpretations do not require versioning merely because the existing textual operational enums gain `TARGET_LEFT_DEDICATED_PGID`; no scientific column meaning changes.

### AP.7 Bounded implementation authorization and required next gates

**Authorization granted only to the same Engineer** for the following bounded implementation:

- modify the existing `test/i4/femref-a1/run_i4_1a.m` only where required by the frozen representation-gate-003 dispatch/terminal contract;
- modify the existing `test/i4/femref-a1/README.md` and `test/i4/femref-a1/SYMBOLS.md` only to document the frozen controller contract;
- add exactly one controller source: `test/i4/femref-a1/run_representation_gate_003_watchdog.pl`;
- perform source inspection and the non-executing syntax check `perl -c` on that Perl source.

This authorization does **not** permit creation or claiming of the representation-gate-003 evidence leaf, execution of the watchdog, MATLAB, Octave, Python numerical work, any diagnostic command, any retry, or `run-006`. It does not permit changes to design/review history, scientific formulas, probe inventory, schemas, I1--I3 artifacts, package/main code, representation-gate-001, or representation-gate-002.

After implementation and before any representation-gate-003 execution:

1. the same Researcher must append a theory-to-code mapping that traces the section 27 deadline, PGID invariant, RSS authority, consumption boundary, terminal enums, scientific no-change contract, and exact external command to named source locations;
2. the same Skeptic must perform an independent spec-to-code/resource pre-execution review of the exact diff and `perl -c` result;
3. that review must explicitly verify the single absolute deadline, no reset/rearm to 1800 seconds, `remaining <= 0` immediate kill, inclusive `>=` thresholds, complete PGID/member enforcement, guarded kill/reap/dead confirmation, exact create-once namespace, no 001/002 reads, no lower stops, unchanged scientific calls/schemas/counts, and absence of `run-006`;
4. only a later explicit no-blocker pre-execution verdict may authorize one exact representation-gate-003 command under the already frozen external wrapper.

### AP.8 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Exact implementation of one `EXEC_GO`-anchored deadline | I4.1a controller implementation | `IMPORTANT CAVEAT` | Execution authorization, not bounded coding | Researcher theory-to-code map plus same-Skeptic exact source review | Pending implementation review |
| Exact implementation of dedicated-PGID membership and cleanup | I4.1a controller implementation | `IMPORTANT CAVEAT` | Execution authorization, not bounded coding | Same-Skeptic inspection of membership, kill, reap, and identity paths | Pending implementation review |
| Perl syntax/API availability | I4.1a static implementation validation | `MINOR CAVEAT` | Execution authorization only if syntax/API defect appears | Authorized `perl -c` plus source-level API audit | Pending static check |

## AQ. Mandatory independent spec-to-code/resource pre-execution review

### AQ.1 Audit frame

- **Audit target:** current `test/i4/femref-a1/run_representation_gate_003_watchdog.pl`, the dispatch-local representation-gate-003 changes in `run_i4_1a.m`, and the corresponding README/SYMBOLS mappings, against design §§25--29 and review §§AN--AP.
- **Question:** whether the exact create-once zero-scientific-eigensolve diagnostic can now be executed once under the sole $1800\,\mathrm{s}$ target-active wall upper and $2{,}147{,}483{,}648$-byte authoritative aggregate RSS upper, with no lower stop, history reuse, cleanup hang, schema drift, or premature `run-006` authority.
- **Success criterion:** every threshold or authority-loss branch must stop the target before any operation that can block indefinitely; the watchdog must preserve the exact ID/command/deadline/process-tree/accounting/publication contract; MATLAB must retain the frozen workload and advisory-only 003 semantics; 001/002 and `run-006` must remain outside the execution path.
- **Authority and scope:** read-only mandatory pre-execution review. The only executed checks were `/usr/bin/perl -c`, a nonlaunching Perl core-API identity check, namespace/file inspection, and `git diff --check`. No watchdog, MATLAB, Octave, Python numerical work, diagnostic, or formal run was executed.
- **Materials examined:** design §§25--29; review §§AN--AP; the complete current watchdog source; targeted 003 MATLAB dispatch, representation runner, completion/advisory/schema code; README/SYMBOLS; current filesystem namespace state; and the current diff.

### AQ.2 Verdict

**`REVISE` (high confidence).** The section 28 cleanup/reap blocker is closed: released-unconfirmed targets receive guarded group cleanup, alarm guard/signal failure no longer enters unsafe blocking reap, blocking wait is guarded by an accepted/absent direct-child kill, and dead confirmation remains fail closed. The fixed ID, single `EXEC_GO` deadline, exact inclusive thresholds, full-table aggregate accounting, dedicated-PGID invariant, MATLAB advisory semantics, and scientific no-change boundary also pass static inspection. One unresolved controller blocker remains, however: the RSS-limit and RSS-authority-loss branches perform required sidecar/stdout write-and-flush operations before sending `SIGKILL`. A blocked log sink can therefore leave MATLAB running after the 2 GiB predicate is already observed or after RSS authority has already been lost. This contradicts the immediate hard-stop/fail-closed contract, so representation-gate-003 execution is not authorized yet.

### AQ.3 Strongest challenge

The controller correctly computes the resource decision but does not always act on it first. At an authoritative RSS crossing, line 314 calls `LOCAL_record_sample` before line 315 calls `LOCAL_issue_group_kill`; on process-table or authority failure, lines 265/289 call `LOCAL_record_unavailable_sample` before lines 269/293 issue the kill. Both record helpers synchronously write and flush `samples.tsv.partial` and watchdog stdout. A write or flush can block without throwing, so neither the exception cleanup nor the one-second loop can guarantee prompt termination. The wall alarm would eventually kill at 1800 seconds, but that does not enforce the independent 2 GiB hard cap and does not make RSS-authority loss fail closed.

### AQ.4 Classified findings

1. **`BLOCKER` -- RSS threshold and authority-loss branches log before killing the live target.**
   - **Location:** `run_representation_gate_003_watchdog.pl:264-270`, `:288-294`, `:312-318`; blocking publication operations in `:750-789`.
   - **Evidence:**
     - process-table failure calls `LOCAL_record_unavailable_sample('OPERATIONAL_INTEGRITY_KILL')` before `LOCAL_issue_group_kill`;
     - authoritative-sample/PGID-membership failure does the same;
     - aggregate RSS `>= 2147483648` calls `LOCAL_record_sample(..., 'RSS_HARD_LIMIT_KILL')` before group/positive cleanup;
     - both record helpers synchronously write and flush the sidecar and unbuffered stdout before returning.
   - **Consequence:** if either sink blocks, the target remains live after a measured hard-limit crossing or after the controller can no longer prove the hard cap. This directly invalidates the current pre-execution resource-enforcement deliverable.
   - **Uncertainty:** no runtime assumption is needed; blocking is permitted by the source ordering. Ordinary fast writes would hide rather than eliminate the defect.
   - **Cheapest decisive repair:** freeze the computed sample/error and terminal classification in memory, issue the existing guarded group plus identity-safe positive cleanup first, and only then attempt the required row publication. If post-kill publication fails, retain `WATCHDOG_OPERATIONAL_INCOMPLETE` with the truthful logging/RSS-authority cause; if the frozen threshold row publishes to both required sinks, retain `RSS_HARD_LIMIT_KILLED`. The repair must not add a threshold, retry, grace, sample, or schema field.

2. **`IMPORTANT CAVEAT` -- an early nonblocking wait can reap the child without recording the reap result.**
   - **Location:** `run_representation_gate_003_watchdog.pl:179-188` and later reap logic at `:495-511`.
   - **Evidence:** `waitpid($child_pid, WNOHANG)` is called during exec confirmation; when it returns the child PID, source raises `PRELAUNCH_FAILURE` without first setting `child_reaped` or `child_wait_status`. The later helper then calls `waitpid` again and can only return unconfirmed.
   - **Consequence:** a very fast post-exec exit cannot cause an unsafe blocking wait after the §28 fix, but exact child status and target-dead evidence can be lost and the external ledger is unnecessarily degraded. The external create-once leaf still prevents retry, so this does not independently invalidate normal-run authorization once the blocker above is repaired.
   - **Uncertainty:** MATLAB normally cannot complete during this short interval, but executable/environment failure can take this path.
   - **Cheapest decisive repair/check:** when the early wait returns the exact child PID, record `child_reaped=1` and `$?` before raising the existing fail-closed classification. Do not widen the clean-confirmation or retry rule.

3. **`MINOR CAVEAT` -- static syntax/API success is not runtime process-control evidence.**
   - **Location:** system Perl and the not-yet-executed watchdog.
   - **Evidence:** `/usr/bin/perl -c test/i4/femref-a1/run_representation_gate_003_watchdog.pl` returned `syntax OK`; a nonlaunching symbol check found `POSIX::setpgid`, `Time::HiRes::clock_gettime`, and `Time::HiRes::alarm`. Both commands emitted only the host `C.UTF-8` to `C` locale fallback warning.
   - **Consequence:** source availability is established, but PGID, signal, `ps`, and dead-confirmation runtime behavior remains evidence for the later postdiagnostic review.
   - **Cheapest decisive test:** after the blocker is repaired and the static gate is repeated, the single exact diagnostic command is the decisive runtime check; no auxiliary watchdog run or retry is authorized.

### AQ.5 Implementation audit

#### AQ.5.1 Controller items that pass

1. **Exact identity and no arguments:** watchdog constants fix `representation-gate-003`, the exact MATLAB path, and the exact batch string; `@ARGV == 0` is enforced before leaf creation.
2. **Create-once separation:** science and external collisions are checked; only `watchdog/representation-gate-003/` is atomically claimed by Perl; MATLAB alone owns `diagnostics/representation-gate-003/`. Current science and external 003 leaves are absent.
3. **CLOEXEC/release/PGID:** the two-pipe handshake, child and parent `setpgid`, exact `PGID_READY`/`EXEC_GO`, post-exec PGID check, and list-form exec match the frozen contract.
4. **One wall deadline:** `target_start` is captured immediately before the complete `EXEC_GO` write; `deadline=target_start+1800` is assigned once; clean confirmation does not reset it; positive remaining time alone is passed to the one-shot alarm; `remaining <= 0` immediately enters guarded kill; every loop test uses inclusive `now >= deadline`.
5. **No lower resource gate:** watchdog source contains no 120-second, 1 GiB, 1.5 GiB, forecast, cadence, stall, grace, or early-reserve stop. The nominal one-second sleep is observational only.
6. **Exact memory predicate:** arbitrary-precision aggregate bytes are compared inclusively with `2147483648`.
7. **RSS coverage:** exact full-table `/bin/ps` fields include PID, PPID, PGID, RSS, start identity, state, and command; current descendants and dedicated-PGID members are unioned and PID-deduplicated; stable known identities and PID-reuse exclusions are retained.
8. **Dedicated-PGID invariant:** an identity-verified live known target outside the dedicated group yields `TARGET_LEFT_DEDICATED_PGID` and operational-integrity cleanup, not a resource crossing.
9. **Section 28/29 cleanup:** alarm guard/signal failure returns to main-loop guarded cleanup before reap; released-unconfirmed targets use guarded group cleanup; blocking reap is used only after already-reaped or exact accepted/absent direct-child kill; later process-table/group/known-identity checks control target-dead confirmation.
10. **External artifacts:** exclusive child logs, partial samples, atomic samples rename, and exclusive temporary-summary-to-final rename implement the frozen 11- and 18-column external schemas. Outer `/usr/bin/time` maximum RSS is not consumed by the controller.

#### AQ.5.2 MATLAB/scientific items that pass

1. Entry dispatch accepts the exact 003 pair and no arbitrary ID/path; its selected ID alone forms the diagnostic namespace.
2. The 003 path rebuilds two meshes and three phase reductions and prepares six primary rows; it does not call `LOCAL_low_spectrum` or the sole `eigs` site.
3. Frozen completion counts remain 2 mesh rows, 3 seam rows, 6 primary rows, 294 probe rows, 8 partition rows, a $10414\times36$ prepared container, 261 rewrite rows, one 27-column forecast row, and a 19-field summary.
4. The 17/16/7/11/27 representation ledger widths, 36-column operator representation, header-only bulk/gap ledgers, zero completed eigensolves, no reference export, forbidden-output checks, and no-partial completion gate remain hard correctness conditions.
5. For 003, false CV uses `ADVISORY_TIMING_VARIABILITY`; false forecast/CV/spread/1.5-GiB observation uses `ADVISORY_RESOURCE_SCREEN_FALSE` with `OBSERVATION_ONLY_NOT_EXECUTION_FAILURE`; `internal_pass` is recorded but is not consumed by 003 terminal selection.
6. Correctness-complete 003 ends only at `REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`; it cannot select `REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`.
7. Formal 1.5-GiB preflight and formal solve-wall logic remain in the one-input scientific path; they are not reached by the two-input 003 path.
8. The watchdog contains no 001/002 path or artifact reference. Existing 001/002 namespaces remain present and were not written by this audit. `output/run-006/` is absent.

### AQ.6 What survived scrutiny

- The §27 single-deadline repair and dedicated-PGID membership repair are faithfully represented in source.
- The §28/29 alarm-failure, released-unconfirmed, no-hang reap, identity cleanup, and dead-confirmation fixes materially resolve the earlier controller blocker.
- Exactly two resource upper predicates remain; correctness and operational-integrity failures are not mislabeled as threshold crossings.
- The external wrapper identity, fixed child command, schemas, create-once paths, and summary claim boundary are reproducible and appropriately separate from MATLAB science artifacts.
- The MATLAB 003 branches preserve the scientific representation workload, schemas, zero-eigensolve boundary, historical advisory fields, and pending-review claim strength.
- Static checks passed: Perl syntax and required core API symbols are available; `git diff --check` passed; 003 science/external leaves and `run-006` are absent.

### AQ.7 Minimal resolution and authorization boundary

Return only the ordering defect in AQ.4 finding 1 to the same Engineer; the adjacent early-wait bookkeeping caveat may be repaired in the same bounded controller edit. The permitted change remains confined to `run_representation_gate_003_watchdog.pl` and any strictly mechanical README/SYMBOLS locator update. It must not change MATLAB science, thresholds, timer origin, sample schemas, terminal claim boundary, IDs, or artifact paths.

After the bounded fix:

1. the same Researcher must append a delta theory-to-code mapping showing kill-before-log ordering for RSS crossing, process-table failure, authoritative-sample failure, and target-left-PGID failure;
2. rerun only `/usr/bin/perl -c` and `git diff --check` plus namespace-absence checks;
3. return the exact source to the same Skeptic for a focused re-review.

**The command `/usr/bin/time -lp /usr/bin/perl ./run_representation_gate_003_watchdog.pl` is not authorized by this verdict.** No watchdog/MATLAB execution, representation-gate-003 leaf creation, retry, new diagnostic ID, or `run-006` is authorized.

### AQ.8 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| RSS threshold/authority-loss branches publish before kill | I4.1a representation-gate-003 controller implementation | `BLOCKER` | Exact 003 execution | Bounded kill-before-log source repair, Researcher delta map, same-Skeptic static re-review | Open in `review-4-1a.md`; execution blocked |
| Early `waitpid(WNOHANG)` reap bookkeeping | I4.1a controller implementation | `IMPORTANT CAVEAT` | Failure-ledger completeness, not normal target execution | Record exact reap flag/status before existing fail-closed return | Pending bounded cleanup |
| PGID/signal/process-table runtime behavior | I4.1a postdiagnostic evidence | `MINOR CAVEAT` | Postrun interpretation only after static pass | One exact authorized command followed by same-Skeptic postreview | Not yet executable |

## AR. Focused exact-source re-review after section 30

### AR.1 Audit frame

- **Audit target:** the section 30 source delta in `test/i4/femref-a1/run_representation_gate_003_watchdog.pl`, limited to kill-before-log ordering, post-kill publication downgrade, RSS hard-limit status retention, early reap bookkeeping, and preservation of the two-upper-limit contract.
- **Question:** whether review §AQ's execution blocker is closed without adding a lower stop, retry path, schema change, or new scientific authority.
- **Success criterion:** process-table failure, authoritative-sample/PGID failure, and authoritative RSS crossing must all terminate the live target before any potentially blocking log write/flush; failed post-kill publication or dead confirmation must prevent retention of a complete hard-limit terminal; an early exact reap must preserve its wait status; the only resource uppers must remain 1800 target-active seconds and 2,147,483,648 aggregate RSS bytes.
- **Authority and scope:** read-only focused pre-execution review. Checks were limited to exact source inspection, `/usr/bin/perl -c`, `git diff --check`, lower-threshold string inspection, and namespace absence. No watchdog, MATLAB, Octave, Python numerical work, diagnostic, or formal run was executed.
- **Materials examined:** design §30 together with §§25--29; review §AQ together with §§AN--AP; current watchdog source; and the current 003/run-006 filesystem state.

### AR.2 Verdict

**`PASS WITH CONDITIONS` (high confidence).** The §AQ blocker is closed. All three reopened branches now freeze their truthful in-memory classification, issue guarded group and identity-safe positive cleanup, and only then attempt the sidecar/stdout write-and-flush. A post-kill row-publication exception enters the existing operational-incomplete exception path; samples close/rename failure also downgrades before summary construction; reap/dead-confirmation failure downgrades before summary; and summary-publication failure leaves no completed summary authority and reports operational incomplete on stderr. Therefore `RSS_HARD_LIMIT_KILLED` survives only when the authoritative threshold row is published to both required live sinks and the later target-death/samples/summary finalization succeeds. The early exact `waitpid` result is now retained. No unresolved blocker remains; the conditions are runtime evidence and postdiagnostic-review requirements, not source repairs.

### AR.3 Strongest remaining challenge

The strongest remaining uncertainty is runtime rather than static: macOS process-group signalling, safe-signal delivery, full-table `ps` identity/accounting, post-kill descendant disappearance, and external atomic publication have not yet been exercised together. Static source now fails closed if any of those mechanisms loses authority, so this uncertainty is exactly what the one authorized create-once diagnostic and subsequent postdiagnostic review must test; it is not a reason for another design or implementation cycle.

### AR.4 Classified findings

1. **`IMPORTANT CAVEAT` -- a post-kill logging failure deliberately destroys complete hard-limit evidence.**
   - **Location:** watchdog threshold/failure branches at current lines 269--323; exception downgrade at 359--407; samples finalization at 414--423; summary publication at 447--454.
   - **Evidence:** kill precedes the row writer in every reopened branch. If the row writer throws, the outer exception branch forces `WATCHDOG_OPERATIONAL_INCOMPLETE` and repeats guarded cleanup before safe reap/dead confirmation. If samples close/rename fails, status is downgraded before the summary row is formed. If summary publication fails, no summary commit marker is established and stderr reports operational incomplete.
   - **Consequence:** the target is safely stopped, but postreview must not reconstruct a complete RSS hard-limit verdict from a partial sidecar or one sink alone.
   - **Uncertainty:** only runtime can show whether both sinks and the summary complete.
   - **Cheapest decisive test:** the exact once-only command below, followed by same-Skeptic cross-check of sidecar, mirrored stdout, final samples file, summary, child logs, target-dead evidence, and outer `time`.

2. **`MINOR CAVEAT` -- syntax success does not establish signal/process runtime behavior.**
   - **Location:** host system Perl and controller runtime APIs.
   - **Evidence:** `/usr/bin/perl -c test/i4/femref-a1/run_representation_gate_003_watchdog.pl` returned `syntax OK`; only the known unsupported `C.UTF-8` to `C` locale fallback warning was emitted.
   - **Consequence:** none for launch authorization; runtime PGID/RSS/dead-confirmation evidence remains conditional on the diagnostic.
   - **Cheapest decisive test:** no auxiliary dry run or new ID; use only the authorized exact command.

No `BLOCKER` remains.

### AR.5 Focused implementation findings

1. **Process-table failure passes.** Source freezes `WATCHDOG_OPERATIONAL_INCOMPLETE / RSS_AUTHORITY_LOST` and the stop timestamp, calls `LOCAL_issue_group_kill`, then writes the unavailable operational-integrity row.
2. **Authoritative-sample/PGID failure passes.** The exact authority cause, including `TARGET_LEFT_DEDICATED_PGID`, is frozen before guarded group/positive cleanup; only the stopped-target branch attempts the unavailable row.
3. **RSS crossing passes.** The arbitrary-precision aggregate is compared inclusively with `2147483648`; source freezes `RSS_HARD_LIMIT_KILLED / RSS_HARD_LIMIT_REACHED`, kills first, then writes the frozen `SAMPLE_OK / RSS_HARD_LIMIT_KILL` row.
4. **Post-kill downgrade passes.** A required row write/flush exception cannot leave a live target waiting for logging and cannot retain the hard-limit status. Reap/dead-confirmation, samples close/rename, and summary publication remain necessary for complete terminal authority.
5. **Early reap bookkeeping passes.** When the confirmation-stage `waitpid(..., WNOHANG)` returns the exact child PID, source records `child_reaped=1` and exact `$?` before entering the existing fail-closed pre-confirmation branch; later code does not lose or double-reap that status.
6. **Wall enforcement is unchanged.** One monotonic timestamp immediately precedes `EXEC_GO`; one immutable deadline equals that timestamp plus 1800 seconds; `remaining <= 0` kills immediately; alarm and loop use the same inclusive deadline; no reset or early reserve appears.
7. **Memory enforcement is unchanged.** The only memory upper is authoritative aggregate RSS `>= 2147483648` bytes. Recursive descendants, dedicated-PGID members, and stable known identities remain PID-deduplicated; leaving the dedicated group remains operational-integrity failure.
8. **No hidden lower resource stop was introduced.** Source contains no 120-second, 1 GiB, 1.5 GiB, forecast, cadence, stall, grace, or reserve stop. The one-second interval remains observation only.
9. **Schemas and science remain unchanged.** The fixed 11/18-column external schemas, fixed no-argument command, MATLAB 003 dispatch, advisory-only internal forecast/CV fields, zero-scientific-eigensolve workload, 001/002 isolation, and no-reference/no-effectivity claim boundary are unchanged by this delta.
10. **Prelaunch state passes.** `diagnostics/representation-gate-003/`, `watchdog/representation-gate-003/`, and `output/run-006/` are absent. `git diff --check` passed.

### AR.6 What survived scrutiny

- The single `EXEC_GO`-anchored wall deadline and exact 2 GiB aggregate threshold remain the only resource uppers.
- Operational-integrity and correctness failures remain distinct from resource crossings and may fail closed without inventing a lower resource limit.
- The CLOEXEC handshake, verified dedicated PGID, full-table RSS authority, stable known identities, guarded kill, nonhanging reap policy, and dead confirmation remain internally coherent after the ordering repair.
- External create-once ownership and atomic publication remain separate from MATLAB's science namespace.
- MATLAB's 003-specific advisory and pending-review terminal semantics remain intact; no scientific eigensolve, reference export, effectivity comparison, or formal-run authority is introduced.

### AR.7 Exact one-time execution authorization

With no unresolved blocker, **one and only one** representation-gate-003 execution is authorized. It must be launched from
`/Users/whc/Documents/Work/epost/test/i4/femref-a1` with exactly:

```text
/usr/bin/time -lp /usr/bin/perl ./run_representation_gate_003_watchdog.pl
```

No arguments, wrapper loop, alternate cwd, alternate MATLAB command, precreated 003 leaf, manual polling controller, retry, or replacement ID is authorized. The successfully claimed external leaf is create-once. After confirmed MATLAB exec, the science ID is consumed regardless of natural completion, hard stop, operational failure, correctness failure, environment failure, or incomplete artifacts.

During the run, the only **resource** stop predicates are:

$$
t-t_0\ge1800\ \mathrm{s},
$$

and

$$
B_{\mathrm{RSS}}^{\mathrm{agg}}\ge2147483648\ \mathrm{bytes}.
$$

The diagnostic may also stop fail closed for an actual operational-integrity, correctness, schema, atomic-publication, isolation, MATLAB, or environment failure. Such a stop must retain its truthful classification and must not be relabeled as a lower resource limit. Historical 120-second, 1 GiB, 1.5 GiB, cadence, forecast, CV, spread, or progress observations cannot stop 003 as resource gates.

Completion or failure must return to the same Skeptic for full postdiagnostic review before any further action. **This authorization does not authorize `run-006`, a retry, representation-gate-004, another attempt, guided-mode eigensolves, reference/effectivity comparison, artifact repair, or project-result promotion.**

### AR.8 Mandatory postdiagnostic evidence

The postdiagnostic review must receive and audit:

1. exact cwd, outer command, shell exit, and complete `/usr/bin/time -lp` record;
2. external samples partial/final state, mirrored watchdog stdout, MATLAB stdout/stderr, and summary-last state;
3. every valid sample's PID list, de-duplicated KiB sum, byte conversion, peak, decision, elapsed, and gap;
4. any unavailable/operational row and the preceding kill timestamp/order;
5. wall alarm/loop decision, target-stop, child wait status, target-dead confirmation, ledger-finalized timestamp, and outer real time;
6. exact MATLAB terminal or reached partial artifacts, all required counts/schemas if complete, advisory forecast/CV semantics, and zero scientific eigensolves/no-reference boundary;
7. immutable 001/002 evidence and continued absence of `run-006`.

### AR.9 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Combined PGID/RSS/dead-confirmation runtime behavior | I4.1a representation-gate-003 execution | `IMPORTANT CAVEAT` | Postdiagnostic interpretation and any later formal-run discussion | One exact authorized command plus same-Skeptic postdiagnostic audit | Authorized once / not yet executed |
| Host locale fallback warning | I4.1a controller runtime | `MINOR CAVEAT` | None unless it changes fixed parser output | Record stderr and verify exact `ps` parsing in reached evidence | Monitor only |

## AS. Independent postdiagnostic audit of `representation-gate-003`

### AS.1 Audit frame

- **Audit target:** the one create-once execution of `representation-gate-003`, including its external watchdog ledger, MATLAB zero-scientific-eigensolve representation artifacts, resource record, retry/ID boundary, and claim boundary.
- **Exact execution evidence:** cwd `/Users/whc/Documents/Work/epost/test/i4/femref-a1`; command `/usr/bin/time -lp /usr/bin/perl ./run_representation_gate_003_watchdog.pl`; shell exit 0. The supplied outer record reports `real 761.52`, `user 992.77`, `sys 274.34`, maximum resident set size 1,175,863,296 bytes, and peak memory footprint 15,680,512 bytes. The outer memory fields are contextual wrapper evidence, not aggregate MATLAB-tree authority.
- **Question:** whether the exact frozen representation workload completed correctly and atomically before either authorized resource upper was reached, without history reuse, scientific eigensolve, reference/effectivity output, retry, or `run-006`.
- **Success criterion:** complete frozen internal counts/schemas and pending-review terminal; externally authoritative PID-deduplicated aggregate RSS always below 2,147,483,648 bytes; target-active elapsed below 1800 seconds; natural child/group/known-target death before final ledger commit; no unavailable or operational row; no partial artifact; and an honest zero-eigensolve/no-reference claim.
- **Authority and scope:** read-only postdiagnostic review under design §§25--30 and review §§AN--AR. No artifact, source, design, review, status, or documentation file was modified. No MATLAB, Octave, Python numerical work, watchdog rerun, diagnostic retry, or formal computation was executed.
- **Checks used:** read-only filesystem/file-identity inspection; CSV/TSV parsing and integer arithmetic with system Perl; line/schema/count checks; source-to-artifact consistency checks; `file`, `stat`, `find`, `wc`, `du`, `rg`, `git status`, branch, and HEAD inspection.

### AS.2 Verdict

**Postdiagnostic verdict: `PASS WITH CONDITIONS` (high confidence).** The exact 003 command completed naturally and produced a complete, internally and externally consistent zero-scientific-eigensolve representation artifact. The watchdog observed 737 valid samples, no unavailable or operational sample, and a PID-deduplicated aggregate peak of 1,296,187,392 bytes ($1.207168579102$ GiB), strictly below 2,147,483,648 bytes. Target-active elapsed was 761.486755 seconds (12.69145 minutes), strictly below 1800 seconds. MATLAB exited with status 0 and no signal; the final zero-live-PID sample recorded `NATURAL_EXIT_OBSERVED`; target death preceded ledger finalization. Every frozen internal count/schema gate passed, no partial or forbidden scientific artifact exists, and MATLAB reported `REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`. The condition is prospective: the internal formal forecast remains 2671.67 seconds (44.53 minutes) with substantial timing variability, so this successful diagnostic does not authorize `run-006`, a formal reference run, or any effectivity claim.

### AS.3 Strongest challenge

The result most capable of being overclaimed is the contrast between a successful 12.69-minute diagnostic and the diagnostic's own 44.53-minute future-formal forecast. The executed workload contained zero scientific eigensolves and measured representation preparation/writer paths; it did not execute the 119-solve guided-mode reference workload. Therefore the actual diagnostic wall/RSS pass establishes representation correctness and current diagnostic resource feasibility only. It does not refute the failed formal wall forecast, establish formal-run feasibility, produce a guided-mode eigenpair, or validate effectivity.

### AS.4 Classified findings

1. **`IMPORTANT CAVEAT` -- the future-formal wall forecast remains above the default plan budget and timing stability is poor.**
   - **Location:** `diagnostics/representation-gate-003/representation-forecast.csv` and `representation-probe-costs.csv`.
   - **Evidence:** `forecast_seconds=2671.6706757083334`, `forecast_minutes_unrounded=44.527844595138887`, `forecast_strictly_below_30=0`, `timing_pass=false`, and `internal_gate_pass=0`. The row truthfully uses `ADVISORY_RESOURCE_SCREEN_FALSE` and `OBSERVATION_ONLY_NOT_EXECUTION_FAILURE;wall_pass=false;forecast_at_most_1p5_gib=true;timing_pass=false`. Exactly 114 of 294 probe rows carry `ADVISORY_TIMING_VARIABILITY`, with no `RESOURCE_BUDGET_UNAVAILABLE` row; the largest observed CV is about 1.36565.
   - **Consequence:** this does not invalidate 003, because those fields were prospectively frozen as observation-only for this diagnostic. It does prevent using 003 as automatic authority for a 30-minute formal `run-006`; any later formal proposal requires a new explicit Researcher/design/resource review flow.
   - **Uncertainty:** the forecast is empirical and timing-variable, not a certified runtime bound; nevertheless, current evidence does not support silently ignoring it.
   - **Cheapest decisive next action:** stop at the current postdiagnostic result. If the user later requests formal continuation, return the 44.53-minute/timing evidence to a new bounded design and budget gate before any command.

2. **`MINOR CAVEAT` -- MAT mirrors were identity-checked but not independently decoded in this no-MATLAB/no-Python audit.**
   - **Location:** `diagnostic-summary.mat` and `operator-representation.mat`.
   - **Evidence:** both are valid MATLAB v7.3 containers with nonzero sizes; their CSV peers are schema-valid and the runtime completion gate reports the in-memory mirror/count checks passed. No permitted local HDF5 inspection utility was available, and this audit intentionally did not run MATLAB or Python.
   - **Consequence:** no effect on the postdiagnostic verdict because the CSV ledger, source-owned runtime mirror gate, summary-last state, and external resource result independently establish the current claim. It limits only an optional extra binary-mirror robustness assertion.
   - **Cheapest decisive check:** defer; decode only if a later authorized artifact-integrity audit specifically requires it.

3. **`MINOR CAVEAT` -- 001/002 immutability is supported by isolation and timestamps, but no fresh pre/post-003 digest pair was supplied to this Skeptic.**
   - **Location:** existing `diagnostics/representation-gate-001/` and `representation-gate-002/`.
   - **Evidence:** each still contains exactly seven files; all recorded mtimes predate the 003 launch; the 003 controller/source contains no 001/002 artifact path; and no audit action wrote them. Earlier reviews preserve the available digest history.
   - **Consequence:** there is no evidence of mutation and no history dependency in 003. The present check is metadata/source-isolation confirmation rather than a newly established cryptographic before/after proof.
   - **Cheapest decisive check:** none needed for the current verdict; retain the existing immutable histories and do not rewrite them.

No `BLOCKER` remains for the representation-gate-003 diagnostic deliverable.

### AS.5 External watchdog and resource audit

1. **Create-once artifacts:** the external leaf contains exactly the four terminal files `samples.tsv`, `watchdog-summary.tsv`, `matlab.stdout.log`, and `matlab.stderr.log`; the live `samples.tsv.partial` was atomically renamed and no `.partial` remains.
2. **External schemas:** `samples.tsv` has exactly 11 columns and 737 data rows; `watchdog-summary.tsv` has exactly 18 columns and one data row.
3. **Sequence and identity:** sample sequences are exactly 1--737. Every row records root PID 81968 and dedicated PGID 81968. The only observed target PIDs are 81968 and 82034; every per-row PID list is strictly sorted and duplicate-free.
4. **Arithmetic:** every row's `live_pid_count` equals its parsed PID-pair count, and every `aggregate_rss_bytes` equals $1024$ times the sum of the recorded RSS KiB values. No arithmetic, sequence, schema, monotonic-time, or stored-gap mismatch was found.
5. **Peak:** the authoritative peak is 1,296,187,392 bytes at sequence 81. Its exact row contains `81968:1145984;82034:119824`; the KiB sum is 1,265,808 and $1{,}265{,}808\times1024=1{,}296{,}187{,}392$. This is 851,296,256 bytes below the 2 GiB hard upper.
6. **Sampling:** all 737 rows are `SAMPLE_OK`; `unavailable_sample_count=0`; no operational-integrity decision appears. The observed post-first-sample gaps range from about 1.024682 to 1.099532 seconds, with mean about 1.034596 seconds. Cadence remains observational, but the evidence is continuous and well resolved.
7. **Natural terminal:** the sole nonempty decision is sequence 737 `NATURAL_EXIT_OBSERVED`, with elapsed 761.48668099986389, live count 0, empty PID pairs, and aggregate 0. Summary status is `TARGET_EXITED / NATURAL_EXIT`, child wait status 0, exit code 0, signal 0, and diagnostic namespace present.
8. **Ordering:** supplied controller evidence gives `target_dead=2849620.6282569999` and `ledger_finalized=2849620.6288549998`; ledger commit follows confirmed target death by about 0.000598 seconds. The last sample precedes target-dead elapsed by about 0.000074 seconds. No scientific process remained live during finalization.
9. **Wall:** summary target-active elapsed 761.4867549999617 seconds is below 1800 seconds; outer `real 761.52` transparently includes controller setup/finalization and is consistent with the target record.
10. **Outer/aggregate distinction:** outer maximum RSS is 1,175,863,296 bytes ($1.095108032227$ GiB), lower than the watchdog's aggregate MATLAB-tree peak. It was correctly not used as aggregate authority. The reported 15,680,512-byte outer peak footprint is also contextual only.
11. **Child logs:** MATLAB stdout contains only the expected pending-review terminal line. MATLAB stderr contains two Java package warnings and no scientific or controller failure.

### AS.6 MATLAB science-artifact audit

1. **Terminal summary:** the 19-field CSV summary records exact ID/dispatch, `completed_eigensolves=0`, `reference_exported=0`, six primary rows, correctness pass, internal benchmark complete, empty terminal failure fields, claim boundary `ZERO_EIGENSOLVE_REPRESENTATION_AND_RESOURCE_EVIDENCE_ONLY`, and external review pending.
2. **Exact row counts and widths:** independent CSV parsing found:
   - mesh ledger: 2 rows, 36 columns;
   - seam ledger: 3 rows, 12 columns;
   - operator representation: 6 rows, 36 columns;
   - representation resource: 293 rows, 17 columns;
   - probe costs: 294 rows, 16 columns;
   - partition bounds: 8 rows, 7 columns;
   - rewrite benchmark: 261 rows, 11 columns;
   - forecast: 1 row, 27 columns;
   - diagnostic summary: 1 row, 19 columns;
   - bulk bands/gaps: header-only 10/14 columns;
   - progress: 4 reached rows ending at `INTERNAL_BENCHMARK / COMPLETE`.
   Every data row has its header's exact width.
3. **Primary representation:** the six operator rows form exactly three stiffness/mass pairs. All have `EVALUATED_PASS`, `gate_pass=1`, zero raw/canonical nonfinite counts, exact canonical Hermitian status, and empty first-failure fields.
4. **Mesh/seam correctness:** both meshes have complete planar-complex pass, zero unpaired triangles, zero material mismatches, zero invalid/nonmanifold/interior-free/missing-boundary/intersection counts, one connected triangle component, and empty failure fields. All three seam rows have zero coordinate mismatch and tiny seam/Hermitian defects below the frozen tolerance.
5. **Probe inventory:** path counts are six primary component rows plus 48 rows for each of global, restricted-center, restricted-core, restricted-tail, endpoint-parity, and common-core, totaling 294. All false timing gates are correctly advisory; none becomes a diagnostic terminal failure.
6. **Partition and writer:** all eight maximizing partitions sum to their declared 40/48 target and match their cluster counts. The 261 rewrite rows have exact sequential checkpoints, chained before/after counts, finite nonnegative timing/byte fields, monotone cumulative time, and final `rows_after=10414`. Checkpoint kinds are exactly 1 header, 119 primary-pair, 47 global-normalization, 47 restricted-parity, and 47 common-core.
7. **$10414\times36$ evidence:** the runtime completion gate reports the in-memory prepared container passed the exact $10414\times36$ check; the independent rewrite ledger reaches exactly 10414 rows under the 36-column operator contract.
8. **Atomic publication:** all required final artifacts are present; no `.partial` remains in either science or watchdog leaf. Summary MAT/CSV and external summary-last files are present after their dependent ledgers.
9. **No scientific result leakage:** bulk band/gap files are header-only; no field, spectrum, eigenvalue, reference collection, or effectivity artifact exists. Strings such as `eigs` in operator consumer-contract fields describe future consumers and do not represent an executed solve; the runtime summary confirms zero completed eigensolves.

### AS.7 Budget, retry, history, and claim boundary

- **Budget:** target-active time was 12.69 minutes and authoritative aggregate peak RSS was 1.2072 GiB, both below the user-authorized 1800-second/2-GiB uppers. The science leaf occupies about 400 KiB and the external leaf about 144 KiB.
- **Attempt/ID:** representation-gate-003 has now been launched exactly once and is permanently consumed. Existing representation IDs are exactly 001, 002, and 003; there is one external 003 leaf and no representation-gate-004.
- **Retry:** no retry occurred and none is authorized. A successful result does not create a right to repeat the ID for robustness or overwrite artifacts.
- **History:** 001 and 002 remain preserved as their earlier consumed incomplete histories. The current result does not reinterpret either failure.
- **Formal boundary:** `output/run-006/` is absent. Existing output directories stop at `run-005`.
- **Git:** branch is `codex/epost`; HEAD remains the pre-existing 2026-08-28 commit and the task files/artifacts remain uncommitted in the working tree. This Skeptic made no commit.
- **Claim:** the defensible claim is only: *the frozen zero-scientific-eigensolve representation correctness/resource diagnostic completed naturally once, with complete internal schemas/counts, external target-active elapsed about 761.49 seconds, and observed aggregate peak RSS 1,296,187,392 bytes below 2 GiB.* It is not a guided-mode eigenpair, independent reference result, reference-error bound, effectivity validation, or formal-run feasibility proof.

### AS.8 Allowed minimal synchronization and prohibited next actions

After appending this review, the main Researcher/agent may make only minimal status/documentation synchronization needed to replace prospective wording with the verified facts above. Appropriate scope is:

1. project `STATUS.md`: record 003 consumed, complete zero-eigensolve representation diagnostic, natural exit, exact target wall/aggregate peak, advisory 44.53-minute formal forecast, and `run-006 NOT AUTHORIZED`;
2. `test/i4/femref-a1/README.md` and `SYMBOLS.md`: mechanically update 003 from prospective/not-run to consumed/complete and preserve the exact claim boundary;
3. the existing review file: append this postdiagnostic audit.

No formula, scientific design, I1--I3 artifact, 001/002 history, MATLAB code, watchdog code, experiment output, method claim, reference/effectivity result, or formal result may be changed or promoted in that synchronization.

**This verdict does not authorize `run-006`, another representation diagnostic, a retry, a new ID, a formal guided-mode computation, effectivity comparison, reference/result promotion, or a commit.** Any such continuation requires a new explicit user-authorized Researcher--Engineer--Skeptic flow beginning from the unresolved formal forecast/timing evidence.

### AS.9 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Formal forecast 44.53 minutes and timing instability | Any future I4.1a formal-run proposal | `IMPORTANT CAVEAT` | `run-006` and any formal reference/effectivity claim; not the completed 003 diagnostic | New explicit bounded design/resource review if the user requests continuation | Open / formal execution not authorized |
| Independent MAT-payload decode | Optional artifact-integrity extension | `MINOR CAVEAT` | No current claim | Defer unless specifically authorized and needed | Deferred |
| Fresh cryptographic pre/post proof for 001/002 | Historical immutability robustness | `MINOR CAVEAT` | No current claim | Preserve existing files; do not reopen history | Closed by scope / retain immutable |

## AT. Independent design review of §31 `run-006` core formal path

### AT.1 Audit frame

- **Audit target:** `design-4-1a.md` §31 的 prospective `run-006` core-path revision，尤其是 A/B/C 边界、最小 FEM 合法性、科学输出、资源依据和最小 external controller。
- **Current stage:** 同一 M1 geometry-fitted conforming $P_1$ FEM 方法的 formal-runtime 精简设计；尚未实现、未创建 `run-006`、未运行 MATLAB，也未形成 reference/effectivity 结果。
- **Question:** 删除 representation/resource/provenance 审计负担后，是否仍完整求解同一 continuous guided-mode problem，并留下足以独立审查 eigenvalues、fields、branch/mode identity、coverage 和 empirical resolution 的最小工件；同时，是否有充分的 planning evidence 在单一 $2700$ s/$2147483648$ byte hard budget 下进入 bounded implementation。
- **Success criterion:** 科学合同和所有决定 reference 资格的数学 gate 不变；B 类路径确属非数学审计且在 formal call graph 中不可达；最小 mesh/assembly/spectral checks 能拒绝错误 FEM 离散；canonical outputs 可区分 ready、scientific negative、operational failure 和 resource failure；external controller 只执行两个 user-authorized resource upper 和 enforcement-integrity stop。
- **Authority and materials:** repository/test/research rules，`method-4-1.md`、`method-review.md`、`design-4-1a.md` §§1--31，以及 `review-4-1a.md` 既有 postdiagnostic evidence，尤其 §AS 对 003 的资源和 claim-boundary 审计。历史 diagnostic 结果只作为 planning evidence，不作为 formal science authority。
- **Scope:** 本审查只读；未修改 design、review、source、artifact 或 status，未运行 MATLAB、Octave、Python、Perl 或任何 numerical/diagnostic command。

### AT.2 Verdict

**Design verdict: `PASS WITH CONDITIONS` (high confidence).** §31 完整保留了 continuous model、fitted-$P_1$ weak form、geometry/material/quasiperiodic identification、$72+47=119$ solve union、full branch/cluster inventory、coverage/collapse/mode-identity rules、四轴 resolution、$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 的 empirical/non-certified 语义、information isolation 和 claim boundary。拟删除的 OP2/DRV2 mirrors、representation dispatch/probes、$10414\times36$ writer contract、$261$ rewrites、forecast/CV/stall gates、低于 $2$ GiB 的 internal screens、hash/provenance 和不影响离散判定的 exhaustive mesh ledgers 均不是该 FEM 方法的数学定义。最小输出集合足以在 post-run review 中重建科学 terminal。$1788$ s core planning point 和现有约 $1.20$--$1.4073$ GiB evidence 不是上界，但在明确删除已分解的 $883.67$ s audit additive 后，为 $2700$ s/$2$ GiB 启动提供了合理而非保证性的依据。下列 conditions 只约束实现解释和下一审查门；它们不是要求恢复旧审计系统，也不阻止 bounded implementation。

### AT.3 Strongest challenge

最强挑战是资源推断仍未由一次完整 $119$-solve run 实测：003 的 $761.49$ s/$1.2072$ GiB 结果包含零次 scientific eigensolve，而 $1788$ s 是原 formal scientific baseline planning point，不是 certified runtime bound。若 Engineer 仅删除文件名而让 representation rows、rewrite/checkpoint、forecast 或 mirror construction 仍可达，则减去 $883.67$ s 的推断立即失效，$2700$ s 设计余量也不再可信。最便宜且足够的决定性检查不是新增 benchmark，而是 implementation 后的 exact call-graph/source audit，证明全部 B 类工作在 formal entry 下不可达，同时 controller/log publication 保持常数级最小负担。

### AT.4 Classified findings

1. **`IMPORTANT CAVEAT` -- resource feasibility is evidence-based but conditional, not measured or bounded.**
   - **Location:** §31.4 and prior §AS resource evidence.
   - **Evidence:** current decomposition is $1788$ s scientific baseline plus $883.67067570833342$ s representation/audit additive, including $674.58177570833345$ s writer rewrite; 003 measured aggregate peak $1296187392$ bytes but executed zero scientific eigensolves. Removing the identified additive leaves about $912$ s planning margin under $2700$ s; available memory estimates remain below $2147483648$ bytes.
   - **Consequence:** enough to accept the design and implement under the explicit hard budget, but not enough to promise completion or support a later reference claim before execution. Any reachable large rewrite/probe path would invalidate the planning premise and become a pre-execution blocker.
   - **Uncertainty:** eigensolver timing and peak workspace remain unmeasured for the full union.
   - **Cheapest decisive check:** at spec-to-code review, trace the single formal entry and verify every B call edge is absent/unreachable; do not add a probe, benchmark, forecast gate, reserve, or lower memory/time threshold.

2. **`IMPORTANT CAVEAT` -- the A/B mesh boundary must retain cheap connectivity validity, not its old evidence ledger.**
   - **Location:** §31.2 fitted-mesh row and the following deletion paragraph.
   - **Evidence:** §31 already makes mathematical consequence the governing rule and fail-closes on missing interface constraints, interface-crossing elements, degeneracy, periodic mismatch, and invalid reflection action. Under that rule, exact duplicate triangle connectivity cannot be treated as a removable audit: duplicate elements would count the same cell twice in stiffness/mass assembly and change the discrete bilinear forms. By contrast, a 36-column mesh ledger, Euler/incidence/component reports, exhaustive nonincident-intersection inventory, and duplicate payload mirrors are not required when the constrained triangulation and the direct mathematical checks pass.
   - **Consequence:** no design revision is needed, because §31's own “affects the mathematical object” criterion classifies a cheap unordered-triangle uniqueness rejection as A. If the implementation omits it, or merely logs duplicates without failing, the later spec-to-code review must return `REVISE` before execution.
   - **Uncertainty:** only the future source mapping is unavailable at this design stage.
   - **Cheapest decisive check:** one direct uniqueness check on active triangle connectivity, together with finite coordinates, strictly positive areas, unique material classification, required interface/constraint edges, periodic pairing, and required reflection compatibility; do not recreate the historical global mesh-audit schema.

3. **`IMPORTANT CAVEAT` -- minimal canonical publication needs an exact, non-mirrored completion contract at the next gate.**
   - **Location:** §§31.3, 31.5 and 31.6.
   - **Evidence:** the proposed five-file responsibility split contains the spec, mesh descriptors, all reached spectra/branches/coverage/resolution, fields/subspaces, terminal summary, stage log, and authoritative resource ledger. This is sufficient in substance, and §31 forbids fabricating a complete scientific container after interruption, but exact MAT field names, terminal enum values, and final-publication ownership are intentionally not yet frozen.
   - **Consequence:** post-run interpretability is preserved only if `scientific-result.mat` is unambiguously complete or absent/incomplete and `run-summary.csv` is terminal-summary-last. This requires a minimal atomic finalization/completion convention, not the deleted atomic-publication stress suite or mirror schemas.
   - **Uncertainty:** bounded to the not-yet-written source/schema.
   - **Cheapest decisive check:** Researcher freezes one concise field/terminal map in theory-to-code; same Skeptic verifies a single canonical publication path and no second scientific mirror before execution.

4. **`MINOR CAVEAT` -- same-root operational correction needs one simple append-only execution label.**
   - **Location:** §31.5.
   - **Evidence:** create-once `run-006` and non-overwrite correction semantics are both stated, but the concrete leaf naming is deferred.
   - **Consequence:** none for the mathematical design. A future genuine operational repair must not overwrite a failed log or masquerade as a new scientific attempt.
   - **Cheapest decisive check:** freeze one monotone execution-label convention only if an operational failure actually occurs; do not build a retry ledger in advance.

There is **no unresolved `BLOCKER`** at the design stage.

### AT.5 Scientific-contract and implementation audit

The following objects survive intact and are sufficient for the intended finite empirical reference claim:

1. **Continuous/discrete matching:** $A=I$, $B=q$, $\beta=0.5$, radius-$0.2$ sharp circular material target, missing $x=0$ cylinder, $\lambda=k^2$, and the same fitted polygonal-interface conforming $P_1$ variational discretization, mesh/supercell/twist/tolerance schedules and quasiperiodic phase reduction.
2. **Complete inventory:** all 72 bulk and 47 defect solves, root counts, sentinels, finite positive spectra, residual/orthogonality checks, cluster multiplicity, gap construction and full defect branch inventory remain scientific A work. A legal prerequisite failure may stop early, but `REFERENCE_COLLECTION_READY` still requires the complete 119-solve union.
3. **Mode identity:** safe-gap filtering, basis-invariant subspaces, continuation edges, all-object coverage, localization, core/tail, parity, common-core matching and twist/tail collapse are unchanged. No nearest-$k_h$ selection is introduced.
4. **Resolution:** FEM, supercell, twist and algebraic axes and the existing total/collapse gates remain unchanged; $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ remains empirical and explicitly not a certified upper bound.
5. **Information and claims:** no Markdown/Git/history/BIE-QZ/estimator read, no reveal before freeze, and no certified truth/existence/effectivity claim.
6. **Minimum FEM integrity:** finite coordinates; nonduplicate, strictly positive-area active triangles; one material label per element with correct fitted-interface classification; all required interface/constraint edges; periodic node pairing and required reflection action; finite assembled entries; raw/as-assembled Hermitian defect within its frozen tolerance before any roundoff-only canonicalization; positive-definite mass factorization; seam residual; eigensolver completion/residual/orthogonality. These are A checks. Their old wide ledgers and mirrors are not.

The proposed canonical MAT/fields/one-row summary/log/resource outputs are sufficient to audit eigenvalues, reached fields/subspaces, branch inventory, coverage, resolution, direct failure and resource terminal. They need not preserve OP2/DRV2, row-writer, forecast, provenance, hash or exhaustive graph payloads.

### AT.6 Resource-controller audit

The acceptable controller is deliberately small:

- one exact no-argument formal launcher and one MATLAB target tree;
- one non-resetting whole-command wall clock with hard stop at elapsed $\geq2700$ s;
- authoritative deduplicated aggregate target-tree RSS with hard stop at $\geq2147483648$ bytes;
- process-alive/death observation sufficient to stop safely and reap the target;
- immediate operational stop if aggregate-RSS enforcement authority is lost;
- a short append-only resource/terminal record, including observed peak and exit reason.

Sampling cadence may be chosen only to enforce/record RSS; it is not a correctness threshold. There must be no 30/40-minute, 120/1800-second, 1/1.5-GiB, reserve, forecast, stall, CV, spread, timer-resolution, writer-throughput or cadence pass/fail predicate. Controller setup, MATLAB, descendants, mesh/solve/postprocess and necessary publication share the same 2700-second budget; no grace or clock reset is permitted. These requirements do not justify reconstructing the 003 handshake/audit schemas, PID proof ledgers, performance forecasts or stress paths.

### AT.7 What survived scrutiny

- The revision is a runtime reduction of the same independent FEM method, not a new method or a weakened reference gate.
- The A/B/C criterion is scientifically coherent: checks that determine the finite element space, bilinear forms, spectral inventory, mode identity or reference qualification remain; evidence-mirroring and performance-audit machinery does not.
- The minimal outputs retain every object needed for a finite empirical reference or an honest scientific negative while avoiding multiple authorities for the same object.
- The $2700$ s/$2$ GiB launch plan is proportionate to the evidence. It is explicitly conditional and fail-closed at the only authorized resource uppers; uncertainty about completion is not itself a blocker.
- Valid early scientific-negative semantics do not weaken the full-inventory requirement: early stop is allowed only after a prerequisite A gate fails, while a ready collection still requires all 119 solves and all qualification gates.

### AT.8 Minimal resolution and implementation authorization

**Authorized now:** the same Engineer may perform one bounded implementation pass only inside `test/i4/femref-a1/`:

1. simplify the existing `run_i4_1a.m` to the §31 A+C core path;
2. update the existing `README.md` and `SYMBOLS.md` only for the new prospective source/output contract;
3. add or replace exactly one minimal formal runner implementing the $2700$ s/$2147483648$ byte controller;
4. remove the already historical diagnostic-controller source only if it is no longer an active entry and no immutable diagnostic artifact, design/review ledger or historical result is altered.

Static source/call-graph inspection and non-executing syntax checks, including `perl -c`, are allowed. This verdict does **not** authorize creating `output/run-006/`, launching MATLAB/Octave, running the formal runner, performing a benchmark/probe, reading historical output, changing package/main code, adding a new attempt, or starting effectivity comparison.

After implementation and before any formal command, the mandatory gates are:

1. **Researcher theory-to-code mapping:** enumerate every retained A object/formula/gate and its source owner; classify each old formal call edge as A, minimal C, or unreachable/deleted B; freeze exact canonical MAT/summary fields, valid terminal states, output filenames, one core entry and one exact no-argument shell command.
2. **Same-Skeptic spec-to-code/resource review:** verify the continuous problem and 119-solve schedules are unchanged; minimum mesh/assembly/eigs checks above are executable; B paths and historical reads are unreachable; raw Hermitian failure cannot be hidden by canonicalization; output publication is single-authority and fail-closed; `run-006` is still absent; the controller contains only the exact 2700-second and 2147483648-byte uppers plus enforcement-integrity stop; no lower/forecast/cadence/stall/CV gate exists.

Only a separate no-blocker pre-execution verdict may authorize the one exact formal command.

### AT.9 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Conditional full-run wall/RSS feasibility | I4.1a pre-execution | `IMPORTANT CAVEAT` | Does not block implementation; blocks execution only if B paths remain active or hard limits cannot be enforced | Static call-graph and minimal-controller review; then let the hard budget decide in the authorized formal run | Open / verify at spec-to-code gate |
| Cheap triangle-connectivity uniqueness and raw Hermitian ordering | I4.1a theory-to-code/spec-to-code | `IMPORTANT CAVEAT` | Future FEM interpretability if omitted | Direct source check; no ledger or numerical probe | Must satisfy before execution |
| Canonical publication/terminal field map | I4.1a theory-to-code/spec-to-code | `IMPORTANT CAVEAT` | Future post-run interpretability if ambiguous | Freeze one minimal schema and summary-last rule | Must satisfy before execution |
| Append-only operational correction label | Only after a genuine operational failure | `MINOR CAVEAT` | No current implementation/run claim | Define only if needed | Deferred |

**Final gate statement:** `PASS WITH CONDITIONS / BOUNDED CORE IMPLEMENTATION AUTHORIZED / RUN-006 EXECUTION NOT AUTHORIZED`.

## AU. Independent exact spec-to-code/resource pre-execution review

### AU.1 Audit frame

- **Audit target:** current exact implementation diff for the prospective `run-006` core path: `test/i4/femref-a1/run_i4_1a.m`, `run_formal.pl`, `README.md`, and `SYMBOLS.md`, checked against design §§31--34 and review §AT.
- **Current stage:** same M1 geometry-fitted conforming $P_1$ FEM method, implemented but not run; `output/run-006/` remains absent.
- **Question:** whether the source preserves the frozen continuous/discrete problem and complete $72+47=119$ scientific chain, removes all B-class diagnostic/audit work, publishes a reviewable single-authority result for every legal terminal, and enforces the exact whole-command $2700$ s/$2147483648$ byte contract.
- **Success criterion:** no direct mathematical drift; all required cheap FEM validity and spectral/coverage/resolution gates executable; no diagnostic/history path; READY possible only after the full union; scientific negatives retain the reached evidence needed to audit the direct failure; and the runner cannot return or publish success after either hard upper is reached.
- **Materials and checks:** root/research/test rules; `method-4-1.md`, `method-review.md`; `design-4-1a.md` §§1--34; `review-4-1a.md` §AT; current tracked/untracked source and documentation. Read-only checks used `rg`, line-numbered source inspection, `git status`, `git diff --check`, `find`, and `/usr/bin/perl -c`. No runner, MATLAB, Octave, Python, benchmark, diagnostic, or numerical computation was run; no artifact or source was modified.

### AU.2 Verdict

**Pre-execution verdict: `REVISE` (high confidence).** The active MATLAB source preserves the frozen continuous model, nine mesh schedules, $72+47$ solve union, weak-form assembly, raw-Hermitian-before-canonicalization rule, mass SPD, seam/eigensolver gates, complete branch/coverage/mode machinery, and four-axis empirical resolution. Static inspection also confirms that the old representation/OP2--DRV2/probe/padding/rewrite/forecast/preflight/history paths are not active. However, two concrete source-ordering defects remain. First, scientific exceptions raised inside bulk/defect stage functions do not return their partial inventories to the top-level catch, so `scientific-result.mat` can omit all already completed spectra while claiming a valid scientific negative. Second, the runner freezes the final deadline decision before its two required publications; a boundary-near natural exit can therefore write a success summary and return zero after the whole command has exceeded $2700$ s. These defects directly violate canonical-output interpretability and the only authorized wall upper. They are bounded implementation defects, not failures of the FEM method.

### AU.3 Strongest challenge

The strongest challenge is the canonical negative path. `run_i4_1a.m` initializes the stage inventories as empty, invokes `LOCAL_bulk_inventory`/`LOCAL_defect_inventory` through output assignment, and only receives those outputs if the function returns normally. A scientific exception after many valid solves therefore transfers control to the top-level catch with the old empty variable. The catch then atomically publishes that empty variable as the single scientific authority. The non-authoritative `work/` cache may contain some reached spectra, but §31 explicitly makes `scientific-result.mat` the canonical interpretive object. A post-run reviewer could see a direct failure string and a solve count without the eigenvalues/residuals/cluster objects that caused or preceded the failure. That is not a merely optional ledger omission; it makes an authorized scientific-negative terminal insufficiently auditable.

### AU.4 Classified findings

1. **`BLOCKER` -- scientific-negative exceptions discard reached bulk/defect inventories from the canonical result.**
   - **Location:** `run_i4_1a.m:49-54,61-76,96-113,1031-1131,1133-1196,1998-2020`.
   - **Evidence:** top-level `bulk_inventory` and `defect_inventory` start empty. MATLAB output assignment occurs only when the called stage returns normally. `LOCAL_bulk_inventory` can complete and cache all 72 spectra, then raise `BULK_GAP_UNRESOLVED` at the target-gap/refinement gates (`:1069-1124`) before returning its inventory. The top-level catch consequently passes the still-empty `bulk_inventory` into `LOCAL_save_scientific`. Likewise, `LOCAL_defect_inventory` can compute a valid spectrum and detect a raw-gap edge-buffer object at `:1150-1158` before saving that spectrum, incrementing the solve count, appending the entry, or returning any prior partial entries. Other later in-stage scientific failures have the same output-loss mechanism.
   - **Consequence:** `scientific-result.mat` can label a valid scientific negative while omitting the reached spectra, residuals, gap data, cluster inventory, and exact triggering eigenobject needed to verify the conclusion. The `work/` cache is explicitly non-authoritative and cannot substitute for the canonical artifact. This violates §§31.3 and 31.6 and prevents post-run acceptance of those legal terminals.
   - **Uncertainty:** none about the control flow; the defect is statically demonstrated. Which scientific gate would be reached at runtime is unknown and irrelevant.
   - **Smallest repair:** keep a current-run partial scientific state that survives every preregistered scientific gate. In particular, a valid spectrum must be cached/registered and its solve count advanced before an edge-buffer decision; bulk/defect stage functions must return partial inventories plus a failure object, or the top level must reconstruct only current-run reached objects before the single canonical save. Do not add a mirror ledger, history read, checkpoint/rewrite benchmark, or second scientific authority. After repair, one static negative-path trace must show that every scientific terminal publishes all successfully reached objects and the exact direct failure.

2. **`BLOCKER` -- the whole-command deadline is no longer live during required final publication.**
   - **Location:** `run_formal.pl:16-17,107-122,125-130,186-259`; design §§31.4, 33.2 and 34.
   - **Evidence:** the runner correctly creates one immutable `deadline = start + 2700` and performs fresh checks after `ps`, reap, and draft read. But at `:116-118` it freezes `final_terminal` and `final_elapsed`, then executes `write_resource` and `write_summary` at `:119-122` with no deadline enforcement or fresh post-publication classification. Both helpers perform open/write/close/rename I/O. Therefore a natural exit checked at, for example, $2699.999$ s can cross $2700$ s while publishing these required leaves, retain `NATURAL_EXIT`, record a prepublication elapsed below the hard limit, and return zero after the outer command has exceeded the authorized wall.
   - **Consequence:** the exact $2700$ s whole-command upper is not enforceable for setup + MATLAB + postprocess + necessary publication, and success can be misclassified at the boundary. This is the same contract-level failure mechanism identified in §32, not a request for optional controller robustness.
   - **Uncertainty:** the normal publication cost is small, but the forbidden path exists for any positive I/O duration and is most relevant precisely near the hard boundary.
   - **Smallest repair:** retain the single start/deadline and single resource/summary-last publication, but keep one fail-closed deadline mechanism active through the final summary rename and process exit. A deadline firing during finalization must prevent a success terminal/zero exit and leave an honest wall-resource failure indication; it must not use a reserve, lower threshold, grace, repeated publication, correction rewrite, cadence gate, or 003-style audit system. The same Researcher and Skeptic must review the exact bounded delta before launch.

3. **`IMPORTANT CAVEAT` -- full-run resource feasibility remains conditional rather than measured.**
   - **Location:** design §31.4 and review §AT.
   - **Evidence:** the $1788$ s core planning point and roughly $1.20$--$1.4073$ GiB evidence do not include a completed 119-solve execution; 003 completed zero scientific eigensolves.
   - **Consequence:** this does not block execution after the two source defects are repaired, because the user explicitly authorized $2700$ s/$2$ GiB and the runner is supposed to let those exact hard uppers decide. It only limits any pre-run promise of completion.
   - **Cheapest decisive check:** no benchmark or lower gate; preserve this condition and audit the actual formal resource artifact after the one authorized run.

No additional optional robustness issue is promoted to a blocker.

### AU.5 Scientific implementation audit

The following current mappings survive independent static review:

1. **Exact entry and continuous model:** `run_i4_1a` requires exactly one input and accepts only literal `run-006`. `LOCAL_spec` retains $A=I$, $B=q$, $q_{\mathrm{in}}=17$, $q_{\mathrm{out}}=1$, radius $0.2$, missing column $0$, $\beta=0.5$, $\lambda=k^2$, the cue/guard intervals, solver controls, and the empirical-only claim boundary. No current BIE/QZ or estimator input exists.
2. **Nine meshes and schedules:** the three bulk and six defect mesh identities remain $(s,n_\Gamma)=(12,24),(18,36),(24,48)$ with $N=3,4,5$ as frozen. The defect groups contain $5+5+17+5+5+5+5=47$ solves; bulk contains $17+17+33+5=72$ solves. Tolerances remain bulk $10^{-9},10^{-10},10^{-11}$ and defect $10^{-11}$ plus the $10^{-8}$ 48-root algebraic sentinel.
3. **Minimum mesh legality:** active source rejects nonfinite/out-of-range connectivity, nonpositive or duplicate triangles, missing required constraints, fitted-interface crossing/material mismatch, invalid reflection pairing/action, periodic coordinate/master mismatch, nonfinite assembly, and finest geometry failure. These are cheap A checks; the removed wide graph/row ledgers are not required.
4. **Operators and spectra:** stiffness and weighted/full/restricted mass use the frozen $P_1$ forms. Raw normalized Hermitian defect is checked before one upper-triangle canonicalization. Reduced mass requires positive diagonal and successful `chol`; seam residual, complete finite positive roots, solver flag/count, residual, mass orthogonality, ordering, sentinel, and cluster multiplicity gates remain fail closed.
5. **Branches and coverage:** all raw-gap clusters enter basis-invariant restricted Grams, endpoint parity, common-core normalization, mutual twist continuation, cross-configuration matching, all-object coverage, every-slice localization, tail/twist collapse, and ambiguity flags. No nearest-$k_h$ selector exists. Parity ambiguity is retained as an explicit empirical-set limitation, consistent with the frozen first-layer rule.
6. **Four-axis resolution:** FEM, supercell, twist and algebraic envelope changes and their collapse/total gates are present; collection entries retain `EMPIRICAL_SENSITIVITY_ENVELOPE_NOT_AN_UPPER_BOUND`.
7. **READY guard:** the main path requires `completed_solves == 119`, passing coverage, a nonempty qualified set, and passing four-axis resolution before `REFERENCE_COLLECTION_READY`.
8. **B-path isolation:** executable source contains no representation/mesh-repair/mass-gate dispatch, OP2/DRV2 mirror, 10414-row/261-writer path, padding, checkpoint/rewrite forecast, preflight, 1/1.5-GiB screen, CV/spread/stall gate, Git/hash/provenance/history input, or effectivity path. Uses of the word “diagnostic” that remain are the direct reflection/seam/common-core mathematical quantities, not the deleted resource/representation system.
9. **Local call graph:** source contains 67 unique `LOCAL_*` symbols and 67 local function definitions when the three continuation-line signatures are included; no unresolved local call was found. The earlier 67/67 Researcher mapping is consistent with direct inspection.

### AU.6 Canonical-output audit

The intended output split is otherwise coherent:

- `scientific-result.mat` is atomically create-once and, on a normal READY path, contains spec, mesh descriptors, compact bulk/defect spectra, branch inventory/edges, coverage, resolution, collection and terminal boundary.
- `fields.mat` contains reached anchor subspaces, simple representatives and the used meshes/material labels, with a noncanonical/no-effectivity label.
- MATLAB writes only current-run `work/`, `run.log`, the canonical science/fields leaves, and one transient terminal draft.
- The runner makes one draft read, one `resource.tsv` publication, and one `run-summary.csv` publication last; non-natural controller terminals cannot remain READY.

The sole canonical-output blocker is the exception-boundary loss in AU.4(1). A repair must preserve the current single-authority architecture rather than restore old ledgers.

### AU.7 Resource-controller audit

The runner correctly has:

- no arguments; literal `run-006`; exact batch call `run_i4_1a('run-006')`;
- create-once output claim and no historical-output read;
- one monotonic start and one absolute deadline;
- recursive-descendant plus dedicated-PGID union with PID-key deduplication;
- the only RSS predicate `aggregate >= 2147483648` bytes;
- operational stop on process-table/RSS authority loss;
- no lower wall/RSS threshold, reserve, grace, stall, CV, spread, forecast, or cadence pass/fail gate;
- a one-second sleep used only for observation/enforcement, not as a scientific gate;
- kill/reap and non-natural READY downgrade.

`/usr/bin/perl -c test/i4/femref-a1/run_formal.pl` returned `syntax OK` with only the known host locale fallback warning. The unresolved whole-command publication gap is exactly AU.4(2); no broader controller expansion is requested.

### AU.8 Repository and documentation checks

- Branch is `codex/epost`.
- `output/run-006/` is absent; existing history remains outside the current diff/status.
- The former 003 watchdog source is deleted from the active source set, while historical 001--003 outputs are untouched.
- `README.md` and `SYMBOLS.md` consistently state `IMPLEMENTED / NOT RUN / run-006 NOT AUTHORIZED`, the same 119-solve core, canonical leaves, no-effectivity boundary, and the exact prospective command.
- `git diff --check` passed for the tracked diff. The untracked `run_formal.pl` passed Perl syntax checking.
- No commit was made by this Skeptic.

### AU.9 Minimal resolution and gate decision

Return only the two bounded defects in AU.4 to the same Engineer:

1. preserve reached scientific inventories across valid-negative stage exits without adding mirrors or old checkpoint machinery;
2. keep the single absolute deadline fail-closed through the one resource publication and summary-last completion, without reserve, lower gate, repeated publication, or controller audit expansion.

Then the same Researcher must append a bounded delta theory-to-code map, and the same Skeptic must perform a focused exact source re-review. Static syntax/call-graph checks remain allowed; no workload, benchmark, runner or MATLAB invocation is authorized during repair.

**The exact command `/usr/bin/perl ./run_formal.pl` is NOT AUTHORIZED by this verdict.** `run-006` must remain absent. No retry identity, new attempt, effectivity comparison, result promotion or commit is authorized.

### AU.10 Mandatory evidence for any later post-run review

Only after a subsequent no-blocker pre-execution verdict may the single exact command be launched. Its post-run review must receive:

1. exact cwd, exact command, launch count, shell exit, branch and no-commit evidence;
2. create-once `run-006` tree, file inventory, no `.partial`, one draft read, one resource leaf and summary-last publication ordering;
3. whole-command elapsed, controller terminal, MATLAB exit/signal, complete resource samples or minimal enforcement ledger, authoritative PID-deduplicated aggregate peak RSS, and proof that neither $2700$ s nor $2147483648$ bytes was silently exceeded;
4. canonical MAT/fields schemas and identities, planned/completed solve counts, exact $72+47$ role inventory, mesh descriptors, bulk gap/sentinels, defect spectra, branch/coverage objects and claim boundary;
5. if READY: all 119 solves, complete all-object coverage, mode/parity/common-core identity, localization/tail/twist collapse, four-axis values/gates, nonempty qualified collection and empirical-only uncertainty label;
6. if scientific negative: the exact first preregistered failure plus every successfully reached spectrum/inventory object in the canonical artifact, sufficient to recompute or verify that failure;
7. if operational/resource failure: exact first direct cause, preserved append-only evidence, attempt-consumption/retry classification and no scientific/reference promotion;
8. unchanged historical 001--003 and `run-001`--`run-005`, no history/BIE-QZ/estimator read, no reference reveal/effectivity comparison, no new attempt and no hidden rerun.

### AU.11 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Partial scientific state lost on stage exception | I4.1a pre-execution | `BLOCKER` | All valid scientific-negative terminals reached inside bulk/defect stages | Bounded return/state repair plus static negative-path trace | Open / execution blocked |
| Deadline inactive during final publication | I4.1a pre-execution | `BLOCKER` | Exact $2700$ s whole-command enforcement and terminal truth | Bounded runner delta plus focused same-Skeptic source review | Open / execution blocked |
| Full 119-solve time/RSS not measured | I4.1a post-run interpretation | `IMPORTANT CAVEAT` | No pre-run completion guarantee; does not block after source repair | Let the exact hard uppers decide in the single authorized run | Retain as conditional |

**Final gate statement:** `REVISE / TWO BOUNDED IMPLEMENTATION BLOCKERS / RUN-006 EXECUTION NOT AUTHORIZED`.

## AV. Focused source re-review of the §AU bounded repairs

### AV.1 Audit frame

- **Audit target:** only the two implementation blockers returned by §AU: preservation of reached scientific state across
  bulk/defect scientific-negative exits, and enforcement of the unique $2700$ s whole-command deadline through final
  publication and process exit.
- **Current stage:** same M1 geometry-fitted conforming $P_1$ FEM method, implemented but not run. The continuous problem,
  $72+47=119$ solve union, branch/coverage/mode rules, four-axis resolution and empirical claim boundary are not reopened.
- **Success criterion:** a preregistered scientific failure must reach the top-level catch only after all successfully completed
  spectra, entries and counts have been returned into the canonical state; READY must still require the complete union. The
  runner must use the same single absolute deadline before, during and after MATLAB, keep its one-shot enforcement armed
  through `resource.tsv`, summary-last and exit, and retain $2147483648$ bytes as the only RSS upper.
- **Materials:** design §35, current `run_i4_1a.m`, `run_formal.pl`, `README.md`, `SYMBOLS.md`, and the prior §AU findings.
  This review used static source/diff/path inspection only. It did not execute the runner, MATLAB, Octave, Python, a
  benchmark, a diagnostic, or numerical work; it did not create `run-006` or modify any artifact/source/design file.

### AV.2 Verdict

**Pre-execution verdict: `PASS WITH CONDITIONS` (high confidence).** Both §AU blockers are closed by bounded source
changes. Bulk and defect stages now return their current inventory, run state and a failure object before the top level raises
the scientific terminal, so the single canonical negative save sees the reached state rather than the pre-call empty value.
The formal runner now arms one high-resolution alarm from the same immutable `start + 2700` deadline before setup and never
cancels, resets or rearms it; the handler remains active through both final publications and exit, kills the target, emits only
the wall terminal to stderr and exits nonzero. It neither publishes nor rewrites an artifact. The only RSS crossing remains
aggregate RSS $\ge2147483648$ bytes. No diagnostic/audit/mirror/checkpoint/history/forecast path has returned. The conditions
below govern post-run interpretation and do not block the one formal launch.

### AV.3 Strongest challenge

The strongest remaining risk is no longer source correctness but empirical completion: the $1788$ s core planning point and
prior RSS evidence do not contain a completed 119-solve run. This uncertainty cannot be resolved by another preflight without
violating the frozen flow. It is adequately bounded for the current goal by the exact $2700$ s/$2$ GiB controller and the
mandatory post-run review; it is not evidence that the implementation or method will fail.

### AV.4 Classified findings

1. **`IMPORTANT CAVEAT` -- full-run time and peak RSS remain unmeasured.**
   - **Location:** design §31.4 and review §§AT/AU.
   - **Evidence:** representation-gate-003 contained zero scientific eigensolves; the current $1788$ s core estimate remains
     a planning point rather than an upper bound.
   - **Consequence:** no completion promise may be made before execution. It does not prevent the launch because the user
     explicitly authorized the exact hard uppers and the repaired controller enforces them.
   - **Cheapest decisive check:** the one formal command followed by the required post-run artifact/resource audit; no new
     benchmark, forecast gate or lower threshold.

2. **`MINOR CAVEAT` -- an alarm during final publication intentionally favors fail-closed exit over a corrected summary.**
   - **Location:** `run_formal.pl:19-25,123-131`.
   - **Evidence:** the handler performs only group/root kill, a fixed stderr wall record and `_exit(2)`; it does not rewrite
     `resource.tsv` or `run-summary.csv`. If the absolute deadline fires during a final open/write/rename boundary, a partial
     leaf or a leaf completed immediately before the signal may remain.
   - **Consequence:** no success is authorized in that case because the exact command exits nonzero with
     `WALL_HARD_LIMIT_REACHED`; post-run review must treat that external terminal as controlling and must not promote any
     orphaned or pre-signal READY-looking leaf. This is the deliberate single-publication/fail-closed tradeoff, not a hidden
     grace or a reason to restore correction rewrites.
   - **Cheapest decisive check:** inspect shell exit, stderr, `.partial` leaves and publication ordering in the mandatory
     post-run review.

There is **no unresolved `BLOCKER`** at the pre-execution gate.

### AV.5 Scientific-negative repair audit

1. `run_i4_1a.m:72-81` receives `bulk_inventory`/`defect_inventory`, updated `run_state` and `stage_failure` before the
   top-level `LOCAL_raise`; `:112-124` therefore publishes the returned state for a recognized scientific terminal.
2. Bulk main solves save the current-run spectrum before updating frequencies, residuals, path, `completed_phases` and the
   solve count. A later scientific gate returns that state rather than throwing across the function boundary.
3. Bulk count sentinels are saved, appended to `count_sentinels` and counted before the 48-versus-40 mismatch/extra-gap gate.
   The four target gaps are computed under a bounded catch, and the triggering `target_gap` plus its refinement/safe flags are
   installed before a refinement failure is returned.
4. Each defect spectrum is saved and its summary/entry/count installed in `defect_inventory` before the raw-edge-buffer and
   loose-count sentinel gates. Thus the exact edge-buffer or count-sentinel trigger survives in the returned current-run
   state.
5. Operational I/O, dependency and unknown-code failures remain operational: the stage may return their code, but the
   top-level terminal classifier does not convert them into a scientific negative or publish a scientific conclusion.
6. READY logic is unchanged: bulk still contains $17+17+33+5=72$ solves, defect still contains
   $5+5+17+5+5+5+5=47$, and `REFERENCE_COLLECTION_READY` remains downstream of `completed_solves == 119`, passing
   coverage, a nonempty qualified collection and passing resolution.

This closes §AU.4(1) without adding a second scientific authority, a mirror ledger, a history read or a checkpoint/rewrite
path.

### AV.6 Deadline/RSS repair audit

1. `run_formal.pl:16-17` forms the only absolute wall deadline as `start + 2700`; `:25` arms exactly once from the remaining
   interval to that same deadline. There is no cancellation, rearm, reserve, grace or second wall threshold.
2. The alarm is installed before directory claim/fork and remains armed through supervision, target reap, the one terminal-
   draft read, the one `resource.tsv` publication, summary-last and the immediately following exit.
3. The handler at `:19-24` only kills the dedicated target group/root, writes `WALL_HARD_LIMIT_REACHED` to stderr, and exits
   nonzero via `_exit(2)`. It does not call a publication helper, mutate a terminal draft, or overwrite a completed leaf.
4. The loop's ordinary fresh checks still compare the same absolute deadline. The alarm closes blocking/final-I/O windows;
   it is enforcement of the same upper, not a new gate.
5. The unique memory predicate remains `aggregate_rss_bytes >= 2147483648`. Process-table/RSS authority loss remains an
   operational-integrity stop. The one-second sleep is observation/enforcement cadence only.
6. Source-wide static inspection found no lower wall/RSS gate, stall/CV/spread/forecast predicate, representation dispatch,
   OP2/DRV2 mirror, padding, probe, 10414-row/261-writer rewrite, checkpoint, preflight, provenance/hash, Git/history,
   BIE/QZ or estimator input.

This closes §AU.4(2) without restoring the 003 controller/audit system.

### AV.7 What survived

- The exact one-input scientific entry remains `run_i4_1a('run-006')`; the launcher accepts no arguments and contains no
  alternate scientific parameter.
- The continuous specification, nine meshes/tolerances, fitted-interface $P_1$ assembly, raw Hermitian-before-canonical gate,
  mass SPD, seam/eigs residual/orthogonality gates, full branch/coverage/collapse/mode identity and all four resolution axes
  remain as accepted in §AU.
- Canonical READY and scientific-negative outputs remain empirical only, with no certified upper-bound, continuous existence
  or effectivity claim.
- `output/run-006/` was absent during this review, and no historical output was modified or read by active source.

### AV.8 Execution authorization and post-run gate

**Exactly one formal command is now authorized:** from
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`, execute

```text
/usr/bin/perl ./run_formal.pl
```

The runner internally fixes the identity to `run-006`. This authorization does not permit an alternate launcher, arguments,
a reduced workload, benchmark, diagnostic, manual multistage command, new attempt, estimator reveal, effectivity comparison,
or commit.

A retry is not authorized merely because the method, a scientific gate, or either resource upper fails. Only a demonstrated
dependency/path/source/controller/environment operational failure may enter the existing `test/AGENTS.md` same-attempt,
append-only correction flow; it requires preserving the failed evidence and a new bounded review before any corrected
execution.

The post-run Skeptic review must audit the complete evidence list in §AU.10 and additionally treat
`WALL_HARD_LIMIT_REACHED` plus nonzero handler exit as authoritative if the alarm interrupts final publication. No reference,
status promotion or future effectivity step is allowed before that post-run verdict.

### AV.9 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Full 119-solve wall/RSS behavior | I4.1a formal execution | `IMPORTANT CAVEAT` | No pre-run guarantee; does not block the authorized command | One exact command and post-run resource audit | Open / execution authorized once |
| Alarm during final publication | I4.1a post-run terminal interpretation | `MINOR CAVEAT` | No success promotion if stderr/exit reports wall crossing | Inspect exit, stderr, partials and summary ordering | Monitor in post-run review |

**Final gate statement:** `PRE-EXECUTION PASS WITH CONDITIONS / ONE EXACT RUN-006 COMMAND AUTHORIZED / POST-RUN REVIEW REQUIRED`.

## AW. Independent post-run review of formal `run-006`

### AW.1 Audit frame

- **Audit target:** the create-once formal `run-006` artifact, including canonical/partial scientific state, resource budget,
  attempt/retry classification, claim boundary and downstream authority.
- **Exact execution:** from `test/i4/femref-a1`, `/usr/bin/perl ./run_formal.pl`; supplied outer shell exit was `0`.
- **Question:** whether the observed `SCIENTIFIC_NEGATIVE / BULK_GAP_UNRESOLVED` terminal is an internally consistent,
  preregistered scientific gate result rather than an implementation, environment or resource failure, and whether the
  preserved 67-solve state is sufficient to audit that result without promoting a reference or effectivity conclusion.
- **Success criterion:** create-once internally consistent leaves; all successfully completed spectra preserved; direct B1
  gate reproducible from canonical arrays; no false READY/collection/field output; actual wall/RSS below the sole hard uppers;
  and an honest consumed-attempt/no-retry decision.
- **Checks:** read-only file/tree/schema/log inspection and read-only MATLAB loading of existing v7.3 MAT payloads. The MATLAB
  checks only compared stored arrays and recomputed the frozen gap predicate; they did not build a mesh, call `eigs`, solve a
  guided-mode problem, change an artifact or start a new experiment.

### AW.2 Verdict

**Post-run verdict: `PASS WITH CONDITIONS` (high confidence).** `run-006` completed naturally and truthfully stopped at the
first frozen bulk prerequisite. The canonical result, transient terminal, runner summary, resource record and log agree on
`SCIENTIFIC_NEGATIVE / BULK_GAP_UNRESOLVED`, 67 of 119 completed solves, zero collection, MATLAB elapsed
4.391348458 s, whole-command elapsed 21.435584 s and aggregate peak RSS 812744704 bytes. The preserved B1/B2/B4 main
inventories are complete, finite and exactly mirrored by 67 current-run caches. Re-evaluation of the registered B1 gap rule
finds zero candidate satisfying both the full cue and guard predicates. This is a valid scientific method failure, not an
operational/resource failure and not a reference result. The conditions are interpretive: no retry, no branch/location
claim, no effectivity comparison, and no promotion beyond the empirical negative stated here.

### AW.3 Strongest challenge

The strongest risk is to treat the later B2/B3/B4 behavior or the short runtime as permission to ignore the failed B1 gate
and continue to defect solves. The frozen method requires every bulk level to identify the target gap under the same cue and
guard rule before count sentinels or the defect stage. B1 has a cue-spanning open gap, but its upper edge is about
$2.45685255229$, outside the frozen guard upper $2.45$; therefore B1 has zero admissible candidates. Later levels cannot
retroactively waive that prerequisite. Continuing, widening the guard or rerunning after any such change would be a different
design/attempt, not a correction of this completed run.

### AW.4 Classified findings

1. **`IMPORTANT CAVEAT` -- the accepted result contains no independent reference eigenpair or branch collection.**
   - **Location:** `scientific-result.mat`, `run-summary.csv`, and absent `fields.mat`.
   - **Evidence:** terminal is `BULK_GAP_UNRESOLVED`; `collection_size=0`; defect, branch, coverage and resolution payloads
     are empty; no fields artifact exists; only 67 bulk-main solves were reached.
   - **Consequence:** no guided-mode location, field, refinement uncertainty, reference error or effectivity statement follows.
     The result blocks downstream comparison under the current frozen path while remaining a valid post-run deliverable.
   - **Cheapest decisive action:** stop. Any future reference-producing route requires new explicit authority and a new
     Researcher--Engineer--Skeptic design/attempt flow; do not rerun `run-006`.

2. **`MINOR CAVEAT` -- the direct failure string abbreviates the combined cue-and-guard predicate.**
   - **Location:** canonical `first_failure` and `LOCAL_target_gap`.
   - **Evidence:** the message says `B1 has 0 observed gaps containing the full cue interval.` Stored B1 arrays actually give
     one open gap spanning the cue, approximately $[1.32174859199,2.45685255229]$, but its upper edge exceeds the guard upper
     $2.45$, so the combined frozen candidate count is zero.
   - **Consequence:** the string alone omits the guard-specific cause, but the canonical arrays make the gate fully
     reproducible and the terminal remains correct. This does not justify source repair or rerun after consumption.
   - **Cheapest decisive check:** retain the recomputed interval in this review/status note; do not alter the artifact.

3. **`MINOR CAVEAT` -- MATLAB logged the same nonfatal `eigs` option warning for each solve.**
   - **Location:** `run.log`.
   - **Evidence:** 67 occurrences state that the `issym` option is ignored for a matrix input. All 67 solver flags are zero;
     every cache has 40 frequencies/residuals/cluster IDs with multiplicities summing to 40; the largest stored residual is
     approximately $1.13\times10^{-12}$, below the frozen $10^{-9}$ gate.
   - **Consequence:** log noise only. Explicit raw Hermitian checks and the observed solver/residual gates remain decisive.
   - **Cheapest decisive check:** none; preserve the log and disclose the warning.

There is **no unresolved artifact or execution `BLOCKER`**. The scientific negative itself prevents downstream
reference/effectivity work under this path, but it does not invalidate the run artifact.

### AW.5 Artifact and internal-consistency audit

1. The create-once root contains 81 files: four terminal/root leaves and 77 current-run work files. The work leaf consists of
   67 bulk-main spectrum caches, nine mesh caches and one MATLAB terminal draft. No `.partial` remains.
2. Root leaves are exactly `scientific-result.mat` (160096 bytes), `run.log`, `resource.tsv` and `run-summary.csv`.
   `fields.mat` is correctly absent because no defect branch/anchor field was reached.
3. External records agree exactly:
   - `controller_terminal=NATURAL_EXIT`, MATLAB exit code/signal `0/0`;
   - `SCIENTIFIC_NEGATIVE / BULK_GAP_UNRESOLVED`;
   - completed/planned `67/119`, collection size `0`;
   - first failure `B1 has 0 observed gaps containing the full cue interval.`;
   - claim boundary `EMPIRICAL_REFERENCE_ONLY_NO_CERTIFIED_UPPER_BOUND_NO_EFFECTIVITY`.
4. `run.log` contains exactly 67 ordered solve records: B1 phases 1--17, B2 phases 1--17 and B4 phases 1--33, followed
   immediately by the same terminal/failure. It contains no defect-stage record, resource stop, exception or authority-loss
   terminal.
5. The canonical MAT is schema `i4a-core-v1`, run ID `run-006`, contains nine mesh descriptors, nonempty bulk inventory and
   empty defect/branch/coverage/resolution objects. It has no target-gap object because the first B1 candidate gate failed.
6. Canonical levels contain B1 $40\times17$, B2 $40\times17$, B4 $40\times33$, plus B3 as the registered 17-phase
   nested view of B4 rather than an additional solve. All stored frequencies/residuals are finite; all frequencies are
   positive. The 67 authoritative completed solves therefore agree with $17+17+33$, not with the B3 alias view.
7. Every one of the 67 cache payloads has solver flag zero, 40 frequencies, 40 residuals, 40 cluster IDs and multiplicities
   summing to 40. Mesh IDs/phases match the canonical level arrays, and cache-to-canonical frequency/residual differences are
   exactly zero.
8. Mesh descriptors match the frozen nine meshes; every stored cross-interface count is zero. Finest geometry has
   Hausdorff defect about $4.28215\times10^{-4}<5\times10^{-4}$, and stored reflection defects remain below the frozen
   tolerance.

### AW.6 Frozen bulk-gate numerical result

Read-only recomputation from the canonical frequency matrices gives:

| Level | Admissible full-cue + inside-guard candidates | Cue-overlapping open gap near the target |
|---|---:|---|
| B1 | 0 | band-1 gap $[1.32174859199,2.45685255229]$; upper edge exceeds $2.45$ |
| B2 | 1 | band-1 gap $[1.31543949403,2.42566749789]$ |
| B3 | 1 | band-1 gap $[1.31311200754,2.41655432366]$ |
| B4 | 1 | band-1 gap $[1.31311200754,2.41655432366]$ |

The B1 result is evaluated first by the frozen gate. Its zero admissible-candidate count therefore legitimately returns
`BULK_GAP_UNRESOLVED` before the five 48-root count sentinels and all 47 defect solves. Section 31.6 explicitly permits a
valid scientific negative to stop at the first failed A-class prerequisite; the missing downstream solves are not a truncated
execution or resource failure.

### AW.7 Budget audit

- Whole-command elapsed: 21.435584 s, about $0.794\%$ of the $2700$ s hard budget; headroom 2678.564416 s.
- MATLAB elapsed: 4.391348458 s.
- Aggregate peak RSS: 812744704 bytes, about 0.75693 GiB and $37.846\%$ of the 2 GiB upper; headroom
  1334738944 bytes.
- Neither resource predicate fired. No lower wall/RSS, forecast, stall, CV or cadence terminal appears.

The short usage reflects early scientific termination and must not be extrapolated as the cost of a 119-solve READY path.

### AW.8 Attempt and retry ledger

- `run-006` was launched once under the exact authorized command and now has a complete create-once root.
- The controller and MATLAB exited naturally; source, dependency, path, schema, environment and resource control did not
  fail. All completed eigensolves passed their solver/residual/count-shape gates.
- The first failure is a preregistered scientific bulk-gap gate. Under `test/AGENTS.md` and design §31.5, this consumes
  `run-006` and the current `femref-a1` scientific method execution.
- **No retry is permitted or needed.** Re-executing identical source would duplicate a consumed scientific result. Changing
  B1, the guard/cue, mesh schedule, gate order or selection rule would be a substantive new design/attempt and requires new
  explicit user authority; none is granted by this review.

### AW.9 Claim boundary and allowed synchronization

The only defensible scientific claim is:

> Under the frozen I4.1a fitted-FEM protocol, the formal run reached all 67 preregistered bulk-main solves and then failed the
> B1 combined cue/guard target-gap prerequisite; consequently no defect reference branch, field, empirical reference
> collection or effectivity comparison was produced.

Minimal synchronization is allowed only after this review is appended:

1. project `STATUS.md`: record `run-006` consumed, valid `BULK_GAP_UNRESOLVED` scientific negative, `67/119`, actual
   wall/RSS, no reference and no retry/effectivity authority;
2. `implementation/i4/README.md`: change the I4.1a experiment state from prospective/running to accepted scientific negative,
   without altering the method manuscript or claiming I4.1 completion;
3. `test/i4/femref-a1/README.md` and `SYMBOLS.md`: replace not-run wording with the exact terminal/resource facts and consumed
   attempt status.

Do not modify source, design, artifacts, historical I1--I3/001--003 outputs, formulas, method/review conclusions or
`DECISIONS.md`. Do not create another design/review/attempt, reveal the estimator, run effectivity comparison or commit.

### AW.10 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next action | Suggested ledger status |
|---|---|---|---|---|---|
| No admissible B1 target gap under the frozen cue/guard rule | Any future I4.1 reference attempt | `IMPORTANT CAVEAT` | Blocks reference collection/effectivity under current `femref-a1`; not acceptance of this negative artifact | Stop; await explicit authority for a genuinely new design/attempt | Open / current attempt consumed |
| Failure string omits the guard-specific cause | Historical run interpretation | `MINOR CAVEAT` | None after this review records the recomputed interval | Preserve artifact; cite §AW.6 | Documented / no repair |
| Repeated ignored-`issym` warning | Historical log readability | `MINOR CAVEAT` | None | Preserve log; no rerun | Documented |

**Final gate statement:** `POST-RUN PASS WITH CONDITIONS / RUN-006 CONSUMED AS A VALID SCIENTIFIC NEGATIVE / NO REFERENCE / NO RETRY / NO EFFECTIVITY`.

## AX. Independent design review of the §36 diagnostic-ranking revision

### AX.1 Audit frame

- **Target:** `design-4-1a.md` §36 only, as a prospective revision for create-once `run-007`; historical §§1--35, `run-001`--`run-006` and their verdicts/artifacts are not reopened.
- **Question:** whether the revised same-method fitted-$P_1$ FEM path must publish a deterministic top empirical FEM candidate whenever the user-authorized numerical allowlist permits one, while treating gap, coverage, localization, parity, collapse and refinement thresholds only as diagnostics.
- **Current stage and output type:** pre-implementation design for a numerical independent-reference candidate, not a continuous existence theorem, certified reference, experiment result or effectivity comparison.
- **Authority and success criterion:** the new user authorization, repository `AGENTS.md`, `research/AGENTS.md`, `test/AGENTS.md`, the passed I4.1 method gate and the immutable continuous model. Only a genuine numerical, implementation, resource or canonical-publication failure may prevent the top-candidate output; caveats cannot stop it.
- **Materials examined:** §36 in full; the directly inherited branch/refinement definitions in §§5--7 and the core resource/output contract in §31; method claim boundary; current status; and the existing review through §AW. Review was static only. `output/run-007/` was absent. No runner, MATLAB, Octave, Python or numerical computation was executed.

### AX.2 Verdict

**Design verdict: `REVISE` (high confidence).** The continuous problem, fitted-$P_1$ weak form, physical parameters, $\beta=0.5$, $\lambda=k^2$, information isolation, finite four-window search, actual 48-to-conditional-60 spectrum expansion, threshold-free diagnostic treatment, empirical-only uncertainty and $2700$ s/$2147483648$ B resource contract all survive review. One bounded selection-domain defect remains: §§36.4 and 36.8(3) can still return no reference when a numerically valid field-bearing current-run eigenobject exists but lacks a cross-configuration continuation record. That is precisely a tracking/coverage diagnostic cancelling the only valid object, and it exceeds the stated no-reference allowlist. The defect is local and does not require changing the FEM method, schedules, physical model, budgets or claim boundary, but it must be corrected before implementation. No implementation or execution is authorized by this verdict.

### AX.3 Strongest counterexample

Consider a completed base/conditional schedule in which one legal configuration contains a finite positive, residual-valid, mass-normalized field-bearing eigenobject intersecting $W_3$, while every other configuration has no valid $W_3$ object. No mesh, matrix, eigensolver, field, resource or publication failure has occurred, and it is false that all refinements failed to form an eigenpair/field. Nevertheless §36.4 labels the surviving object `UNTRACKED_AUXILIARY_EIGENOBJECT` and excludes it from ranking, while §36.8(3) returns `NO_TRACKABLE_EIGENPAIR_FIELD_ACROSS_REFINEMENTS`. Thus absence of a continuation record becomes a global candidate-cancelling gate even though §36.2 says mode-ID/coverage/refinement diagnostics cannot stop ranking. This counterexample directly changes the primary deliverable and is therefore a blocker, not a robustness preference.

### AX.4 Classified findings

1. **`BLOCKER` -- the rankable domain and §36.8(3) exceed the user-authorized no-reference boundary.**
   - **Location:** §§36.4, 36.8(3), 36.9 and theory-to-code item 5.
   - **Evidence:** a valid singleton is retained in the inventory but barred from the lexicographic ordering; lack of cross-configuration continuation is then an explicit global no-reference terminal. Low overlap, births/deaths, changing multiplicity and mode-ID ambiguity have been downgraded elsewhere to diagnostics, so using the absence of their resulting edge to suppress publication reintroduces the old gate under a new name.
   - **Consequence:** an implementation conforming to §36 could suppress a valid field-bearing FEM candidate even though none of the allowed numerical, resource, operational or publication failures occurred. That violates the current stage's primary success criterion.
   - **Cheapest decisive repair:** make every numerically valid field-bearing $W_3$ eigenobject/component rankable. A singleton receives zero persistence counts, missing refinement components as `NaN`, `delta_ref_obs=NaN`, and explicit `UNTRACKED_SINGLE_CONFIGURATION / EMPIRICAL_RESOLUTION_PARTIAL` caveats. The existing first key then makes genuinely cross-refinement-persistent candidates outrank singletons without a cancellation threshold. Remove §36.8(3) as a separate no-reference state, or narrow it to the case where the completed finite schedule contains no numerically valid field-bearing $W_3$ object at any legal configuration. If the user instead intended cross-refinement continuation itself to remain mandatory, that requires new explicit authority; it cannot be inferred from §36.

2. **`IMPORTANT CAVEAT` -- top-candidate scalar/field extraction needs one deterministic level rule.**
   - **Location:** §36.5, phrase `richest available branch level` and `declared anchor-twist`.
   - **Evidence:** the ranking key uniquely orders candidate IDs, but no exact ordering selects among two available branch levels with different twist coverage/configuration roles when neither is unambiguously “richest.” Their envelopes, multiplicities and anchor fields can differ.
   - **Consequence:** two otherwise conforming implementations could publish different $\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$, $k_{\mathrm{ref}}^{\mathrm{FEM}}$ or field for the same winning candidate. This must be frozen before source execution, but it does not require a new method or new numerical gate.
   - **Cheapest decisive repair:** in the same bounded §36 clarification, define a total priority for the publication level/twist, for example by a stated tuple of valid twist count, configuration priority and fixed twist index, and define the finite-part sum/`NaN` handling of the ranking key. Preserve the existing no-nearest-current-root rule.

3. **`IMPORTANT CAVEAT` -- the max-136 budget estimate is feasible evidence, not a completion bound.**
   - **Location:** §36.10.
   - **Evidence:** $2518$ s and about $1.7591$ GiB are extrapolated from the $1788$ s planning point/root-work ratio and prior memory evidence; no complete 119- or 136-solve path has been measured, and sparse eigensolve/field-tracking cost need not scale exactly with requested-root count.
   - **Consequence:** completion cannot be promised. There is nevertheless no evidence that the declared schedule is expected to exceed $2700$ s or $2147483648$ B, and the sole hard controller limits remain enforceable. This caveat must not create a lower stop, pre-run benchmark or new forecast gate.
   - **Cheapest decisive check:** after the bounded design repair and both code reviews, one exact formal execution under the existing hard controller, followed by post-run resource review.

4. **`MINOR CAVEAT` -- `run-007` consumption wording should defer to same-attempt operational repair semantics.**
   - **Location:** §§36.1 and 36.8.
   - **Evidence:** §36.1 says every complete/incomplete confirmed launch consumes `run-007`, whereas §36.8 and `test/AGENTS.md` permit dependency/path/controller/environment failures to be repaired in the same attempt with preserved evidence.
   - **Consequence:** an implementation could either forbid an authorized operational correction or overwrite a create-once leaf. This is a lifecycle wording ambiguity, not a scientific blocker.
   - **Cheapest decisive clarification:** scientific/resource/canonical outcomes consume the scientific execution; a demonstrated operational failure preserves immutable failed evidence and reuses the same `femref-a1`/`run-007` identity only through an append-only execution label after bounded re-review. No new run ID and no overwrite.

### AX.5 Implementation and resource audit

No implementation exists for §36 and none was audited. At design level:

- the continuous model, geometry/material data, quasiperiodic phase, $A=I$, $B=q$, fitted conforming $P_1$ weak form and mass normalization are unchanged;
- $I_{\mathrm{cue}}$ is only a hint; $W_0$--$W_3$ are finite, pre-reveal and BIE-independent;
- all 47 base defect spectra genuinely request 48 roots, and the only conditional rung requests 60 roots on all 17 fine twists, giving base 119 and maximum 136 solves;
- failure of finite-spectrum coverage records `SPECTRUM_COVERAGE_PARTIAL` and does not remove already returned valid fields;
- the lexicographic key has no nearest-$1.85$, nearest-$\widehat k_h$, BIE/QZ field or estimator input;
- $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ is correctly degraded to `NaN / EMPIRICAL_RESOLUTION_PARTIAL` when an axis is missing and is never called a bound or confidence interval;
- gap-edge, embedded, weak-localization, parity ambiguity and pre-asymptotic labels remain READY-capable with an empirical-candidate claim only;
- the sole resource uppers remain inclusive $2700$ s and $2147483648$ B, with no lower gate.

The canonical MAT/conditional fields/summary-last contract is sufficient to audit spectra, fields, tracks, rank keys, selected scalars, empirical resolution and a no-effectivity claim once finding 1 is repaired. `git diff --check` passed with no output; `output/run-007/` was absent during review.

### AX.6 What survived

1. The four-window search and all-slice 48-to-60 expansion are systematic, finite and independent of the current BIE/QZ chain.
2. Threshold-free maximum-overlap assignment, explicit birth/death retention and the lexicographic persistence-first ordering are defensible; after singleton inclusion they naturally prefer cross-refinement evidence without turning it into a pass/fail threshold.
3. Multiplicity-one fields and higher-multiplicity subspaces are distinguished correctly; no unique basis vector is fabricated for a cluster.
4. Missing refinement axes truthfully yield partial empirical resolution rather than a false finite uncertainty.
5. The claim boundary remains `EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY`; neither guided-mode existence, certification nor effectivity is asserted.
6. The declared resource plan has enough evidence to remain prospective; only the exact hard limits may stop the future command.

### AX.7 Minimal resolution and next gate

Researcher should append one bounded design clarification that:

1. includes valid field-bearing singleton/untracked components in the same ranking with zero persistence and partial-resolution caveats;
2. restricts no-reference to absence of every numerically valid field-bearing $W_3$ object after the complete finite schedule, plus the already authorized mesh/matrix/eigensolver, resource, publication and operational failures;
3. freezes a total publication-level/anchor priority and explicit missing-value comparison semantics;
4. clarifies append-only same-attempt handling of a genuine operational failure.

The same Skeptic should then re-review only that delta. Until it passes, the Engineer is **not authorized** to implement §36 and `run-007` is **not authorized** to run. The continuous model, schedules, resource limits, windows, formulas, diagnostic labels, information isolation and no-effectivity boundary need not be reopened.

### AX.8 Open-problem handoff

| Item | Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|---|
| Valid singleton is excluded and continuation absence causes global no-reference | I4.1a §36 design | `BLOCKER` | Blocks implementation and top-candidate contract | One bounded §36 clarification plus same-Skeptic delta review | Open / design revision required |
| Publication level/anchor is not totally ordered | I4.1a implementation mapping | `IMPORTANT CAVEAT` | Reproducibility of selected scalar/field | Freeze one deterministic tuple in the same clarification | Open / resolve before code review |
| Max-136 wall/RSS extrapolation is not an upper bound | I4.1a formal run | `IMPORTANT CAVEAT` | No completion guarantee; does not block design | Exact future run under hard controller | Open / monitor only |
| `run-007` consumption wording versus operational correction | I4.1a attempt lifecycle | `MINOR CAVEAT` | Append-only repair semantics | One implementation-level sentence and source audit | Open / clarify before launch |

**Final gate statement:** `DESIGN REVISE / ONE CANDIDATE-DOMAIN BLOCKER / NO IMPLEMENTATION AUTHORIZATION / NO RUN-007`.

## AY. Focused re-review of the §37 candidate-domain clarification

### AY.1 Scope and verdict

本复审只核对 §37 对 §AX 唯一 blocker及其直接实现语义的闭合；§36其余 continuous model、search schedule、resource budget和claim boundary不重开。

**Verdict: `PASS` (high confidence).** 没有 unresolved blocker。

### AY.2 Closure audit

1. **Singleton ranking closed.** §37.1 明确把每个来自 legal configuration、数值有效、field-bearing 且与 $W_3$ 相交的 eigenobject/component 纳入同一 lexicographic ranking。无 continuation 的 singleton 获得永久 `candidate_id`、零 persistence counts、missing deltas与 `delta_ref_obs=NaN`；已有 persistence-first key自然优先跨 refinement evidence，但不再删除 singleton。
2. **No-reference allowlist closed.** 旧 §36.8(3) 已被完全替换；只有完整有限 schedule 后所有 legal configurations 合计不存在任何数值有效、field-bearing、与 $W_3$ 相交的 object/component，才可给出 `NO_VALID_FIELD_BEARING_W3_EIGENOBJECT`。Tracking、overlap、parity、localization、coverage或resolution不足均不能产生 no-reference terminal，故 §AX 反例不再成立。
3. **Publication and `NaN` semantics closed.** §37.2 用 $(-n_{\vartheta}^{\mathrm{valid}},p_{\mathrm{config}},i_{\vartheta}^{\min},i_{\mathrm{root}}^{\min},\mathrm{candidate\_id})$ 给出唯一 publication level/anchor；published envelopes、$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$、$k_{\mathrm{ref}}^{\mathrm{FEM}}$、field和multiplicity的来源确定。Raw missing values保留 `NaN`，rank projection与finite-part sum均显式定义，最终 `candidate_id` 保证 total order，不依赖 native `NaN` comparison。
4. **Same-run operational lifecycle closed.** §37.3 固定唯一 scientific identity `run-007` 及 create-once `execution-001` leaf namespace。Scientific/resource/publication terminal消费该run；仅经审查确认的真实 operational failure可在保留旧 evidence、完成bounded修订和pre-run复审后，以同一 `run-007` 和下一个显式 execution label继续。不得auto-retry、覆盖、另建run ID或让MATLAB读取旧execution content。

### AY.3 Gate

§§36--37 现已足以进入 bounded implementation。**授权同一 Engineer 仅按 §36.11 在现有 `test/i4/femref-a1/` 范围内实现 §§36--37**，随后必须完成 Researcher theory-to-code audit 和 same-Skeptic exact spec-to-code/resource review。

本 verdict **不授权执行 runner、MATLAB、Octave或 `run-007`**，也不授权 estimator reveal、effectivity comparison、修改历史 output或创建新 attempt。

`git diff --check`通过；审查时 `output/run-007/` 不存在。未运行任何程序或数值计算。

**Final gate statement:** `DESIGN PASS / SAME ENGINEER BOUNDED IMPLEMENTATION AUTHORIZED / RUN-007 EXECUTION NOT AUTHORIZED`.

## AZ. Independent exact spec-to-code/resource pre-execution review

### AZ.1 Audit frame and verdict

本审查对照 design §§36--40 与 review §AY，静态核对当前 `run_i4_1a.m`、`run_formal.pl`、`README.md` 和 `SYMBOLS.md`。只允许 genuine numerical、implementation、resource 或 canonical-publication failure 阻止结果；diagnostic/caveat不得成为stop。

**Verdict: `REVISE` (high confidence).** 119/136 solve graph、48-to-conditional-60 expansion、singleton ranking、threshold-free tracking、total rank/`NaN` projection、publication tuple、four-axis deltas、normal READY/no-reference schemas、information isolation及$2700$ s/$2147483648$ B controller均静态通过。唯一 unresolved blocker 是三处同一性质的异常分类泄漏：真实I/O或source/runtime failure可被吞成invalid numerical inventory，或canonical publication failure可被误标为可修复operational failure。当前不授权运行。

### AZ.2 What passed

1. Bulk为$17+17+33+5=72$，base defect为$5+5+17+5+5+5+5=47$且全部请求48 roots；若17个fine第48根未全部覆盖$W_3$上端加$0.10$，则全部17 slices追加60 roots，actual总数严格为119或136。
2. 每个numerically valid、field-bearing、与$W_3$相交的cluster可形成object；derived localization/parity/common-core failure保留object。无edge singleton形成独立component并以零persistence、missing deltas及`NaN`进入同一total ordering。旧gap/count/coverage/localization/parity/collapse/refinement thresholds均未出现在reachable top-level early terminal/filter中。
3. Maximum-overlap assignment、component construction、rank projection、finite-part sum、publication configuration/twist/root tuple、$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$、$k_{\mathrm{ref}}^{\mathrm{FEM}}$、multiplicity-one phase fixing及higher-multiplicity subspace路径均可静态执行；normal success leaves与runner draft/summary字段一致。
4. Runner固定no-argument、`run-007/execution-001`、one absolute 2700 s deadline和PID-deduplicated aggregate RSS `>=2147483648` B stop；deadline贯穿target、resource与summary-last publication。没有lower wall/RSS、reserve、grace、forecast、stall、CV、spread、旧diagnostic/audit或history path。
5. Active MATLAB source只读取source constants和current-execution mesh/spectrum caches；未发现Markdown、Git、historical run、BIE/QZ、estimator或effectivity input。

### AZ.3 Classified finding

**`BLOCKER` -- operational/source/publication exceptions do not obey the frozen terminal and retry allowlist.**

- `LOCAL_mesh_registry` 的outer `catch`无条件把异常登记为mesh failure并继续。因此mesh build中的generic struct/dimension/runtime exception解码出的`EXECUTION_UNAVAILABLE`可被吞掉；后续all-spectrum mesh lookup失败最终可误报`NO_VALID_FIELD_BEARING_W3_EIGENOBJECT`。
- `LOCAL_attempt_spectrum`只重抛`OUTPUT_*`，没有重抛`EXECUTION_UNAVAILABLE`。因此`LOCAL_low_spectrum`或其consumer中的真实MATLAB source/runtime/shape bug可被记为invalid solve；若影响全部可用objects，同样产生假的scientific no-reference terminal。
- `LOCAL_publish_fields`正确把fields publication failure改为`CANONICAL_PUBLICATION_FAILURE`，但`LOCAL_publish_scientific`直接调用`LOCAL_atomic_save`。`scientific-result.mat` publication失败因而成为`OUTPUT_* / OPERATIONAL_FAILURE`，与§37.3“canonical publication failure consumes `run-007`”矛盾，并可能错误进入same-run operational retry流程。

该故障会把implementation/I/O failure解释成科学负结果，或把消费性的publication failure解释成可重试operational failure；它直接破坏post-run claim和attempt ledger，故为真正blocker。

### AZ.4 Minimal repair and next gate

同一Engineer只需做异常路由修复，不改任何数学对象、schedule、rank、schema字段或controller：

1. `LOCAL_mesh_registry`在记录合法mesh numerical-invalid原因前，必须重抛`EXECUTION_UNAVAILABLE`及`OUTPUT_*`；
2. `LOCAL_attempt_spectrum`同样重抛`EXECUTION_UNAVAILABLE`及`OUTPUT_*`，只把明确的mesh/phase/eigensolver/numerical-object failure留作local invalid inventory；
3. `scientific-result.mat`的create-once save failure必须冻结为`CANONICAL_PUBLICATION_FAILURE`，且top-level不得为记录该失败而再次尝试发布同一个canonical leaf；terminal draft/runner summary须保留该exact publication terminal，使`run-007`按§37.3消费而非进入operational retry。

修复后由Researcher只做上述catch/terminal delta的theory-to-code audit，再交同一Skeptic focused re-review。其余已通过路径不重开。

`/usr/bin/perl -c ./run_formal.pl`返回`syntax OK`（仅locale fallback warning）；`git diff --check`通过；`output/run-007/`不存在。未运行runner、MATLAB、Octave、Python或任何数值计算。

**Final gate statement:** `PRE-EXECUTION REVISE / ONE EXCEPTION-CLASSIFICATION BLOCKER / RUN-007 NOT AUTHORIZED`.

## BA. Focused re-review of the §AZ exception-routing repair

### BA.1 Verdict

**`PRE-EXECUTION PASS` (high confidence).** §AZ 的唯一 blocker 已关闭；没有 unresolved numerical、implementation、resource 或 publication blocker。§AZ 已通过的科学 call graph、ranking、schema、information-isolation及resource路径不重开。

### BA.2 Exact closure

1. `LOCAL_mesh_registry`现在只把显式`MESH_QUALITY_UNRESOLVED`/`QUASIPERIODIC_SEAM_UNRESOLVED`记录为单mesh numerical failure；generic `EXECUTION_UNAVAILABLE`、全部`OUTPUT_*`及未列明I4A code均重抛，故source/I/O failure不能再伪装成mesh invalid。
2. `LOCAL_attempt_spectrum`的recordable allowlist精确为`MESH_QUALITY_UNRESOLVED`、`QUASIPERIODIC_SEAM_UNRESOLVED`、`SPECTRUM_INVENTORY_TRUNCATED`和`NUMERICAL_OBJECT_INVALID`。缺失的已知invalid mesh只使对应solve local-invalid并继续其他legal configurations；generic/source/output和任何未列明code均fail closed。
3. `LOCAL_publish_scientific`把`scientific-result.mat` save failure映为`CANONICAL_PUBLICATION_FAILURE`。Top-level识别该消费性terminal并跳过第二次canonical publication；随后terminal draft正常记录exact code，runner在natural MATLAB return下以summary-last保留该terminal。`fields.mat`使用相同canonical code。因此publication failure消费`run-007`，不会误入operational retry。
4. Catch delta没有改变119/136 schedule、candidate membership、ranking、`NaN`语义、continuous model或controller。Runner仍只有inclusive $2700$ s与$2147483648$ B两个hard uppers并贯穿publication；既有预算估计仍支持一次受控formal run。

审查时`output/run-007/`不存在。未执行runner、MATLAB、Octave、Python、Perl检查或任何数值计算。

### BA.3 Exact authorization

现精确授权**一次且仅一次**formal command：在cwd
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`执行

```text
/usr/bin/perl ./run_formal.pl
```

该命令内部固定`run-007/execution-001`。不授权alternate command、参数、benchmark、retry、新run/execution ID、estimator reveal或effectivity comparison。完成后必须由同一Skeptic作post-run artifact/resource/claim review，review前不得同步reference结论。

**Final gate statement:** `PRE-EXECUTION PASS / ONE EXACT RUN-007 COMMAND AUTHORIZED / POST-RUN REVIEW REQUIRED`.

## BB. `run-007/execution-001` post-run artifact/resource/claim review

### BB.1 Audit frame

Audit target: the completed create-once formal FEM run `test/i4/femref-a1/output/run-007/execution-001/`.

Success criterion: verify that the frozen independent FEM method produced an internally consistent, field-bearing empirical reference candidate within the $2700\,\mathrm{s}$/2 GiB budget, without promoting it to a certified bound, continuous-existence result, or effectivity comparison.

This audit was read-only. It inspected the canonical artifacts, all 119 spectrum caches, nine mesh caches, log/resource/terminal records, candidate inventory, and the stored winning field. No mesh, eigensolve, guided-mode computation, or effectivity calculation was run.

### BB.2 Artifact and execution integrity

- The create-once namespace contains exactly 134 files: 119 spectrum caches, nine mesh caches, one MATLAB terminal record, and five root-level artifacts. No `.partial`, `.tmp`, second execution, retry, or fine-60 expansion artifact exists.
- Root artifacts are:
  - `scientific-result.mat`: 24,833,378 bytes;
  - `fields.mat`: 351,709 bytes;
  - `run.log`: 51,133 bytes;
  - `run-summary.csv`: 496 bytes;
  - `resource.tsv`: 148 bytes.
- `run-summary.csv`, `resource.tsv`, and `matlab-terminal.tsv` agree on `run-007/execution-001`, `SCIENTIFIC_READY`, `FEM_REFERENCE_CANDIDATE_READY`, 119 attempted/completed/planned solves, collection size 16, and natural exit.
- The solve topology is exactly 72 bulk solves plus 47 defect solves:
  - 67 `bulk-main` and five `bulk-count`;
  - 42 `tight` and five `loose-count`;
  - 67 solves requested 40 roots and 52 requested 48 roots.
- All 119 caches have zero solver flags, finite positive spectra and finite fields. The maximum stored residual is $2.9596950828977078\times10^{-11}$ and maximum orthogonality defect is $6.646890494085932\times10^{-15}$.
- The 48-root fine spectra covered W3 on all 17 slices, with minimum W3 ceiling margin $1.1744558698561991$; therefore the conditional 60-root expansion was correctly not entered.
- Bulk count sentinels are valid, with mismatches from $1.0658\times10^{-14}$ to $2.3093\times10^{-14}$ and matching cluster counts. All five defect count comparisons pass; their largest mismatch is $3.5527\times10^{-15}$.

### BB.3 Candidate publication and field audit

The ordered candidate IDs are

`7, 6, 8, 15, 16, 9, 13, 4, 2, 10, 14, 5, 1, 11, 12, 3`.

Candidate 7 is the deterministic first-ranked candidate:

- 47 realizations, four represented refinement axes, six configurations, and 16 distinct twist values;
- status `TRACKED_WITH_DIAGNOSTIC_EDGES`;
- publication anchor: `fine`, mesh `defect-N5-s24-g48`, $\theta=0$, root 11, multiplicity one;
- eigenvalue envelope: $[3.3697100442273502,\,3.3697321598980357]$;
- wavenumber envelope: $[1.8356769988827963,\,1.8356830227188015]$;
- scalar definition: $\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$ is the midpoint of the eigenvalue envelope and $k_{\mathrm{ref}}^{\mathrm{FEM}}=\sqrt{\lambda_{\mathrm{ref}}^{\mathrm{FEM}}}$, giving

$$
\lambda_{\mathrm{ref}}^{\mathrm{FEM}}
=3.3697211020626927,
\qquad
k_{\mathrm{ref}}^{\mathrm{FEM}}
=1.8356800108032698.
$$

The four empirical changes are

$$
\delta_{\mathrm{FEM}}^{\mathrm{obs}}
=0.0019799758723477723,
$$

$$
\delta_{\mathrm{supercell}}^{\mathrm{obs}}
=3.3059115711608911\times10^{-5},
$$

$$
\delta_{\mathrm{twist}}^{\mathrm{obs}}
=3.0119180025600656\times10^{-6},
\qquad
\delta_{\mathrm{alg}}^{\mathrm{obs}}=0,
$$

and hence

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}
=0.0020160469060619413.
$$

All four components are present, so the stored status `EMPIRICAL_RESOLUTION_COMPLETE` is internally correct.

`fields.mat` is linked exactly to candidate 7 and contains a $7785\times1$ subspace/vector on a 7,785-node, 14,992-triangle mesh. Its mass-Gram defect is $2.2217488424916266\times10^{-16}$; the phase-fixed vector has mass-normalization defect $1.1323410689992802\times10^{-15}$ and a positive-real maximum pivot. The run/execution/candidate, eigenvalue, wavenumber, multiplicity, mesh, twist, basis-status, and claim-boundary fields agree with the canonical scientific result.

### BB.4 Mode classification and claim boundary

The winner is classified as:

- `cue-member`;
- `gap-edge-or-safe-buffer`;
- `weakly-localized`;
- `stable-parity-assignment`;
- `empirical-resolution-complete`;
- `spectrum-covered-through-W3`.

Across its track, the conservative localization summaries are

$$
L_0=0.56822282309369454,
\qquad
L_{\mathrm{core}}=0.96349629586559093,
\qquad
T_{\mathrm{tail}}=0.036503704134409468.
$$

The anchor field is even, with anchor tail metric $2.547962370900575\times10^{-4}$. The bulk diagnostic nevertheless reports `BULK_GAP_UNRESOLVED_DIAGNOSTIC`: no refinement-qualified target bulk gap is available. Thus the artifact does not distinguish a continuous gap-guided mode from an edge, embedded, or near-continuum interpretation at stronger claim level.

The active artifact and prior spec-to-code audit show no historical output, BIE/QZ vector, estimator, or effectivity input in the selection path. Candidate 7 was selected by the frozen lexicographic FEM ranking, not proximity to the current BIE root. The correct boundary remains:

`EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY`.

This result is not a certified upper bound, confidence interval, proof of continuous eigenvalue existence, or effectivity validation.

### BB.5 Resource and retry ledger

- MATLAB elapsed: $120.186555458\,\mathrm{s}$.
- Whole-command elapsed: $140.273679\,\mathrm{s}<2700\,\mathrm{s}$.
- Authoritative aggregate peak RSS: $1{,}353{,}826{,}304$ bytes $<2{,}147{,}483{,}648$ bytes.
- Controller terminal: `NATURAL_EXIT`; MATLAB exit code and signal are zero.

This is a complete frozen-method run, not an operational, path, schema, or environment failure. `run-007/execution-001` is therefore consumed. There is no evidence-based basis for a retry under the same authorization.

### BB.6 Findings

1. **IMPORTANT CAVEAT -- unresolved bulk-gap interpretation.**
   The candidate is field-bearing and reproducible, but the target bulk gap is not refinement-qualified. The strongest counterexample is that the observed localized FEM branch may remain an edge/embedded or near-continuum discrete branch rather than a continuous gap-guided mode. This limits interpretation but does not invalidate the frozen ranking or empirical reference artifact.
2. **IMPORTANT CAVEAT -- empirical resolution is not certified or demonstrably asymptotic.**
   `EMPIRICAL_RESOLUTION_COMPLETE` means all four prescribed sensitivity components were available. It does not establish asymptotic convergence, and $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ is not an upper bound for the unknown continuous error. The absence of an explicit pre-asymptotic label must not be interpreted as evidence that the ladder is asymptotic.
3. **MINOR CAVEAT -- repeated MATLAB option warning.**
   MATLAB reports that `issym` is ignored for matrix-form `eigs` calls. Zero flags, finite spectra, residuals, orthogonality, and the previously reviewed raw Hermitian checks show no current numerical consequence.

No artifact, implementation, resource, or publication blocker was found.

### BB.7 Verdict and allowed synchronization

**POST-RUN VERDICT: PASS WITH CONDITIONS.**

Confidence: high for artifact integrity and the empirical FEM candidate; deliberately limited for continuous guided-mode interpretation.

A minimal synchronization may record in project `STATUS.md`, the I4 README, and existing test documentation that:

- `run-007/execution-001` completed naturally within budget;
- it produced the above empirical field-bearing FEM candidate;
- the bulk-gap classification remains unresolved;
- $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ is non-certified;
- the attempt is consumed and no retry is authorized.

This review does not authorize effectivity comparison, a new run/attempt, new method work, or any certified/existence claim. `git diff --check` passes.

## BC. Independent design review of the §43 out-of-sample $s=30$ layer

### BC.1 Audit frame

审查对象为 design §43 的 prospective `run-008/execution-001`。当前阶段只判断该设计能否进入有界实现；成功标准是：活动科学运行只产生一个与旧结果隔离的纯 FEM $s=30$ 候选，post-run 身份审查不反向影响候选选择，并且完整流程可在 $2700$ s 和 $3{,}221{,}225{,}472$ B 两个 hard upper 内执行。

审查依据包括根目录、`research/` 与 `test/` 的 `AGENTS.md`、design §43、既有 post-run review §BB，以及当前 create-once/attempt contract。未运行 MATLAB、Octave、Python 或任何数值程序，未创建 output。

### BC.2 Verdict

**Verdict: `REVISE` (high confidence).**

科学设计、纯 FEM 选择、样本外身份规则、sealed comparison 和资源上限本身可辩护；但 §43.5 的 create-once 与 operational-repair 语义存在一个真实 implementation blocker。当前不授权 Engineer 实现，修复只需一处有界生命周期澄清。

### BC.3 Strongest challenge

若 `execution-001` 在写出首个 mesh/spectrum/cache leaf 后发生真实 source/path/dependency failure，§43 同时要求：

1. 已有 leaf 永久 immutable、任何既有 leaf 均 fail closed；
2. partial evidence 必须保留；
3. 修复后仍只能使用同一个 `run-008/execution-001`，不得换 ID；
4. MATLAB entry 不得读取 historical output。

因此纠正运行既不能覆盖旧 leaf，也不能使用新的 create-once execution namespace，还不能把旧 cache 当作运行输入；冻结合同没有合法恢复路径。

### BC.4 Classified findings

1. **BLOCKER — operational correction lifecycle is internally impossible.**
   Location: §43.5 create-once、partial preservation 与 operational failure 段。
   Consequence: 一个非科学故障可永久阻止同一方法完成，并与 `test/AGENTS.md` 的 same-attempt bounded repair 规则冲突。
   Minimal repair: 保持 attempt/scientific identity 为 `run-008`；`execution-001` 永久保留且不得覆盖。只有经审查确认的真实 operational failure 才可在有界修复和重新 pre-execution review 后使用下一个显式 create-once execution label，例如 `execution-002`。不得 auto-retry、复用旧 leaf 或更换 `run-008`。

2. **IMPORTANT CAVEAT — reviewer-side historical-field path still requires an exact audited implementation.**
   §43.3 的 identity rule 本身足够保守：五个 twist 上采用 common-core principal overlap、唯一 mutual-best、continuation、localization 与 endpoint parity，且不使用 BIE 解歧；失败只封锁 convergence/BIE comparison，不抹除合法的 $k_{30}$。
   但 §BB 表明 `run-007/fields.mat` 只保存 candidate 7 的 publication anchor field，而不是五个 twist 的完整 subspaces。后续审查必须明确从 immutable `run-007` spectrum/mesh caches 重构所需五个 subspaces及 fixed common-core samples，或诚实登记 `IDENTITY_AUDIT_UNAVAILABLE`。该路径必须单独通过 theory-to-code/spec-to-code review，不能调用读取 historical output 的 MATLAB/Octave experiment entry，也不能读取 BIE/estimator。由于 unavailable 已有 fail-safe 语义，这不是 `run-008` 科学运行的 blocker。

3. **MINOR CAVEAT — §43 存在 Markdown/LaTeX 拼写缺陷。**
   应作机械修订：`$lambda=k^2$` 改为 `$\lambda=k^2$`；`$lambda$ envelope 改为 `$\lambda$ envelope；`$Theta_5$` 改为 `$\Theta_5$`；含控制字符的错误 `vartheta` 拼写改为 `$\vartheta=0,\pi$`。上下文语义仍清楚，故不构成 blocker。

### BC.5 What survived

- 活动 call graph 恰为一个 $(N,s,g)=(5,30,60)$ mesh、$\Theta_5$ 上五次 48-root solve；没有旧 72+47 schedule 或 60-root expansion。
- 连续模型、拟合界面 $P_1$ 弱式、材料、几何、准周期相位及 $\lambda=k^2$ 均保持 run-007 的已审查定义。
- 活动 selection 只使用新运行的 FEM objects；旧 FEM scalars、candidate 7、BIE/QZ、density 与 estimator 均不进入 mesh、spectrum、tracking 或 ranking。
- Singleton、birth/death 与 partial continuation 均可排名；$k_{30}$ 在任何历史揭示前永久冻结，身份失败不撤销该结果。
- Drift、ratio、预注册 $k_{30}^{\mathrm{pred}}$ residual、七起点 variable-projection fit 和严格 BIE boolean test 均确定；fit failure 只产生 caveat。所有结果保持 empirical、non-certified、no-effectivity 边界。
- Reviewer audit 与 scientific command 共享 wall-time 总和和两阶段 RSS 最大值；设计只含 $2700$ s 与 $3{,}221{,}225{,}472$ B 两个 hard resource predicates，没有较低 gate。实现审查仍须确认 audit 使用剩余 wall budget且不重置计时。
- 约 $1402.74$ s、$2{,}538{,}424{,}320$ B 的 prospective estimate 低于授权上限；它只是 GO 估计，不是运行停止门。

### BC.6 Minimal resolution and gate

Researcher只需修改 §43.5 的 operational lifecycle：允许在同一 `run-008` attempt 下，经审查后使用下一个 create-once execution label，同时永久保留失败 execution。其余模型、五次 solve、ranking、身份规则、profile、预算和 claim boundary 不重开。公式拼写可在同一 bounded delta 中机械修正。

修订后由同一 Skeptic 只复审该生命周期 delta。通过前：

**`RUN-008 IMPLEMENTATION NOT AUTHORIZED / RUN NOT AUTHORIZED`.**

`git diff --check -- research/projects/eig-apost/implementation/i4/review-4-1a.md` 通过；分支为 `codex/epost`；`output/run-008/` 不存在。

## BD. Focused re-review of the §44 operational-recovery closure

### BD.1 Scope and verdict

本复审只核对 §44 是否关闭 review §BC 的唯一 blocker；§43 的连续模型、五次求解、ranking、identity audit、profile 和资源设计均不重开。

**Verdict: `PASS` (high confidence).** §BC blocker已关闭，没有 unresolved numerical、implementation、resource 或 publication blocker。

### BD.2 Closure audit

1. **Same-attempt semantics明确。** Scientific identity 与 attempt 保持 `run-008`；首次 execution 固定为 create-once `execution-001`，恢复不会更换 run ID。
2. **失败 execution永久 immutable。** 已启动 execution 及其所有 leaf 不得覆盖、复用或作为恢复运行输入；只允许 post-failure review 追溯。
3. **Operational recovery严格受控。** 只有同一 Skeptic 明确分类为 genuine source/path/dependency/controller/environment operational failure 后，经 Researcher bounded revision、Engineer最小修复和完整 pre-run re-review，才可使用最小未用的 create-once execution label。不存在 runner 自行分类、auto-retry或跳过 gate。
4. **消费性终态完整。** Scientific/numerical、resource以及 canonical-publication terminal均消费 `run-008`；不能重命名为 operational failure以取得恢复资格。
5. **Information isolation保持。** 后续 execution 的 active science不得读取、统计、复制、hash或比较任何旧 execution artifact，必须从冻结输入独立完成相同五次48-root solves。
6. **公式规范已给出无歧义 authoritative override。** §44 明确将相关记号解释为 `$\lambda=k^2$`、`$\lambda$ envelope`、`$\Theta_5$`及`$\vartheta=0,\pi$`，不改变数学对象。§43 原位置仍可日后机械清理，但不影响本设计闭合。

### BD.3 Gate

授权同一 Engineer 仅在 `test/i4/femref-a1/` 内按 §43、并以 §44 为 lifecycle authority，实施独立 `run-008` scientific entry、fixed no-argument controller及必要 README/SYMBOLS 同步。

实现后仍必须依次完成：

1. Researcher theory-to-code mapping；
2. 同一 Skeptic exact spec-to-code/resource review。

二者通过前不得执行 `run-008`、MATLAB或任何身份审查。

**Final gate statement: `DESIGN PASS / SAME ENGINEER BOUNDED IMPLEMENTATION AUTHORIZED / RUN-008 EXECUTION NOT AUTHORIZED`.**

审查期间未运行数值程序；`output/run-008/`不存在。

## BE. Exact spec-to-code/resource pre-execution review for `run-008`

### BE.1 Audit frame and verdict

本审查静态核对 `run_i4_1a_refine.m`、`run_refine_formal.pl`、README及SYMBOLS相对 design §§43–45、§44 lifecycle authority与review §BD的映射。未运行 MATLAB、Octave、Python、runner或任何数值程序，未创建 output。

**Verdict: `PRE-EXECUTION PASS` (high confidence).** 未发现 unresolved numerical、implementation、resource 或 publication blocker。

### BE.2 Exact scientific mapping

1. **Call graph恰为五次。** 顶层只构造 `defect-N5-s30-g60`，`spec.theta_5`固定为
   $$
   \left(0,\frac{\pi}{4},\frac{\pi}{2},\frac{3\pi}{4},\pi\right),
   $$
   唯一 spectrum loop迭代五次，并且唯一 `LOCAL_low_spectrum`调用固定请求48 roots。没有bulk、旧72+47 schedule、第二mesh或60-root expansion路径。
2. **模型与弱式未漂移。** Period、radius、$q_{\mathrm{in}}=17$、$q_{\mathrm{out}}=1$、missing column、$\beta=0.5$、拟合界面 $P_1$ stiffness/weighted-mass assembly、quasiperiodic phase reduction、raw-Hermitian gate、mass SPD、residual和orthogonality定义与已运行的 run-007 helper一致。
3. **Whole-cluster fields完整。** 每个与 $W_3$ 相交的observed cluster整体形成object；保存raw/full-mass-normalized subspace、eigenvalue/$k$ envelopes、localization、endpoint parity和common-core representation。派生诊断失败只写 unavailable/`NaN`，不会删除已通过field-validity checks的object。
4. **Tracking与ranking可执行。** 四对相邻twist使用maximum-total common-core-overlap assignment；birth、death和singleton均保留。Rank依次使用 $-n_{\mathrm{twist}}$、$-n_{\mathrm{edge}}$、四个共同missing refinement slots、finite drift sum、residual、localization、parity、coverage及确定anchor/object ties。所有可能的missing scalar均在 `sortrows` 前投影，native `NaN`不参与比较。
5. **Publication scalar正确。** 胜出component全部realizations的eigenvalue envelope定义
   $$
   \lambda_{30}=\frac{\min\Lambda_{30}+\max\Lambda_{30}}{2},
   \qquad
   k_{30}=\sqrt{\lambda_{30}}.
   $$
   Multiplicity-one anchor作确定phase fixing；higher-multiplicity路径保留mass-normalized subspace。
6. **Diagnostics不成为取消门。** Coverage、guard、localization、parity、edge straddle、weak overlap和partial continuation只改变classification/rank；只要存在一个numerically valid、field-bearing $W_3$ object，代码即排名并发布第一名。

### BE.3 Exception, artifact and isolation audit

- Single-twist mesh/seam/spectrum/object numerical failure进入ledger并继续；全部五个twist均无valid field-bearing $W_3$ object时才产生合法 `NO_VALID_FIELD_BEARING_W3_EIGENOBJECT`。
- Generic source/runtime、dependency、path和output failure保持 operational fail-closed；`scientific-result.mat`或`fields.mat`发布失败被映射为 `CANONICAL_PUBLICATION_FAILURE`，不会伪装为READY或自动重试。
- Success schema包含冻结spec、五项ledger、compact scientific inventory、tracking、total ranks、winner及 $\lambda_{30},k_{30}$；`fields.mat`保存全部retained objects的full subspaces和common-core data。
- Runner先发布 `resource.tsv`，最后发布 `run-summary.csv`；每个MAT/root artifact使用create-once partial-to-final路径。
- MATLAB唯一 `load` 是当前 `execution-001/work/s30-pXX.mat`。活动source没有旧 execution、run-007 FEM scalar/candidate、BIE/QZ、density、estimator、Markdown或Git读取。设计路径只存在于注释。
- `run-008/execution-001` 当前不存在；旧output没有覆盖路径。

### BE.4 Runner and resource audit

`run_refine_formal.pl`为fixed no-argument controller，内部命令固定为 `run_i4_1a_refine('run-008')`。静态控制流只含两个inclusive resource predicates：

$$
T\ge2700\ \mathrm{s},
\qquad
R_{\mathrm{aggregate}}\ge3{,}221{,}225{,}472\ \mathrm{bytes}.
$$

Wall deadline自controller启动后不重置，并贯穿MATLAB、resource publication和summary-last；RSS对MATLAB root、递归descendants及dedicated PGID union去重求和。不存在较低wall/RSS门、reserve、forecast、stall、CV或grace predicate。

约 $1402.74$ s和 $2{,}538{,}424{,}320$ B 的prospective estimate低于两个hard uppers；实际 $s=30$ mesh构造和峰值仍须由正式运行验证，但这不是pre-execution blocker。Perl文件已逐行静态检查，未执行 `perl -c` 或runner。

### BE.5 Strongest counterexample and claim boundary

最强反例是 $(5,30,60)$ fitted mesh不能合法构造，或五个twist全部不能形成valid field-bearing $W_3$ object。当前实现对此给出消费性的scientific negative及partial evidence，而不会发布伪READY；因此该反例检验方法，而不揭示implementation-routing缺陷。

Reviewer-side candidate-7 identity audit、四点profile及sealed BIE comparison尚未实现也未获授权。它们不影响本次纯FEM运行冻结合法 $k_{30}$；当前claim严格限于：

`EMPIRICAL_OUT_OF_SAMPLE_FEM_CANDIDATE_NO_EFFECTIVITY`.

### BE.6 Exact authorization and post-run gate

现授权一次且仅一次执行以下命令，cwd固定为
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`：

```text
/usr/bin/perl ./run_refine_formal.pl
```

该命令内部固定 `run-008/execution-001`。不授权alternate command、参数、retry、新execution、identity audit、profile、BIE reveal/comparison或effectivity。

运行后必须由同一 Skeptic完成post-run artifact/resource/claim review，至少核验：

- create-once文件树、无partial、五个solve/cache及summary-last；
- mesh、solver flags、finite spectra、residual、orthogonality和全部field objects；
- ordered candidate IDs、rank keys、winner、$\lambda_{30}$与$k_{30}$；
- continuation、coverage、localization、parity及所有caveat；
- whole-command wall与aggregate RSS；
- attempt consumption、claim boundary及是否允许后续独立identity audit。

**Final gate statement: `PRE-EXECUTION PASS / ONE EXACT RUN-008 COMMAND AUTHORIZED / POST-RUN REVIEW REQUIRED / IDENTITY-PROFILE-BIE-EFFECTIVITY NOT AUTHORIZED`.**

## BF. `run-008/execution-001` first-stage post-run artifact/resource/claim review

### Audit frame

Target: the create-once artifacts under `test/i4/femref-a1/output/run-008/execution-001/`, reviewed against design §§43–45 and pre-execution review §BE. This is a first-stage pure-FEM artifact review, not the candidate-7 identity audit, BIE comparison, estimator comparison, or effectivity analysis.

The review used only read-only shell inspection and direct HDF5 reads of the current `run-008` MAT files. It did not run MATLAB/Octave, create output, read BIE/estimator data, or execute the reviewer-side identity audit.

### Verdict

**PASS WITH CONDITIONS** — high confidence in artifact integrity and execution correctness; target-mode identity remains intentionally unresolved.

No artifact, implementation, resource, or publication blocker was found. The run produced a complete, internally consistent pure-FEM candidate and the field-bearing artifacts needed to implement and statically review the separately gated §43.3 identity audit. The present result must not yet be treated as the same mode as the earlier candidate, as a converged reference, or as effectivity evidence.

### Decisive evidence

- Exact tree: 12 files, comprising five canonical root artifacts, one mesh cache, five spectrum caches, and `matlab-terminal.tsv`; no `.partial` or temporary file was present.
- `run-summary.csv`, `resource.tsv`, `matlab-terminal.tsv`, `scientific-result.mat`, and the final log record agree on:
  - `run-008` / `execution-001`;
  - `OUT_OF_SAMPLE_FEM_CANDIDATE_READY`;
  - `SCIENTIFIC_READY`;
  - attempted/completed/planned solves `5/5/5`;
  - collection size 29;
  - controller `NATURAL_EXIT`;
  - MATLAB elapsed `17.504931125` s;
  - whole-command elapsed `35.917169000` s;
  - aggregate peak RSS `1,073,594,368` bytes;
  - claim boundary `EMPIRICAL_OUT_OF_SAMPLE_FEM_CANDIDATE_NO_EFFECTIVITY`.
- The mesh cache is `defect-N5-s30-g60`: 11,741 nodes, 22,760 triangles, and 11,380 reduced DOFs. Coordinates are finite; connectivity is in range and nonduplicate; all triangle signed areas are positive, with minimum doubled area $5.607201769085146\times10^{-5}$; material labels cover all triangles; interface crossings are zero; periodic coordinate mismatch is zero.
- Exactly five 48-root caches exist, at
  $$
  \theta\in\left\{0,\frac{\pi}{4},\frac{\pi}{2},\frac{3\pi}{4},\pi\right\}.
  $$
  Every solver flag is zero, every spectrum/vector entry is finite, and no 60-root expansion cache exists because all five 48-root spectra cover W3. The minimum coverage margin is `1.241736828331625`. Across the five solves, the largest stored residual is $3.252486857677656\times10^{-16}$, the largest orthogonality defect is $6.099699291667107\times10^{-15}$, and the largest seam residual is $1.2412670766236366\times10^{-16}$.
- The candidate inventory contains 145 field-bearing objects: roots 3–31 on each of five twists, hence 29 objects per slice. Object IDs are contiguous. All 145 raw and normalized subspaces are nonempty finite arrays of shape `1 x 11741`; all common-core sample and weight arrays are nonempty finite arrays of shape `1 x 10465`, and all stored weights are positive.
- Ordered candidate IDs are:
  `3, 1, 7, 2, 5, 4, 9, 10, 12, 6, 11, 14, 13, 8, 16, 15, 26, 28, 17, 18, 25, 23, 20, 24, 22, 21, 19, 27, 29`.
  The selected candidate is therefore candidate 3, with
  $$
  \lambda_{30}=0.61502508946098011,\qquad
  k_{30}=0.78423535336082628.
  $$
  Its stored rank key is
  `[-5,-4,4,0,8.531044331372605e-17,-0.0059703014666022,-0.26579510641258347,0.33967990013018884,1,-5,-1.241736828331625,1,5,3,3]`.
- Candidate 3 uses realization IDs `3,32,61,90,119`, all root 5 and multiplicity one, across all five twists. Its frequency values are
  `0.737788543799568, 0.7556543442844904, 0.7846972850313371, 0.8126651802711921, 0.8280810609838104`;
  its stored envelope is
  $$
  k\in[0.737788543799568,\ 0.8280810609838104].
  $$
- The selected five normalized fields have mass-Gram errors between $1.7\times10^{-15}$ and $7.9\times10^{-15}$. Applying the frozen pivot phase convention leaves a positive real pivot with imaginary magnitude at most $1.2\times10^{-17}$. Thus the full subspaces and deterministic phase reconstruction required by the future identity audit are available.
- Classification is exactly:
  `expansion-shell-3`, `BULK_GAP_NOT_COMPUTED`,
  `FULL_FIVE_TWIST_CONTINUATION`, `weakly-localized`,
  `mixed/ambiguous`, `empirical-resolution-partial`,
  `spectrum-covered-through-W3`.
  The localization summaries are `localization_center=0.0059703014666022`, `localization_core=0.26579510641258347`, and `tail_max=0.33967990013018884`. Endpoint parity is even at $\theta=0$ and odd at $\theta=\pi$; intermediate-twist parity is correctly unavailable.

### Findings

1. **BLOCKER:** none.

2. **IMPORTANT CAVEAT — identity is not yet established.**
   The pure-FEM ranking validly selects candidate 3, but this stage has not tested its common-core field overlap or continuation against the earlier candidate-7 fields. Its numerical location must neither validate nor invalidate identity. Until the separately reviewed identity audit is completed, no cross-run convergence comparison or same-mode statement is admissible.

3. **IMPORTANT CAVEAT — no empirical resolution number is available.**
   `delta_fem`, `delta_supercell`, `delta_twist`, `delta_algebraic`, and `delta_ref_obs` are all `NaN`; `missing_refinement_count=4` and the status is `EMPIRICAL_RESOLUTION_PARTIAL`. The result is a field-bearing FEM candidate, not a resolved reference and not a certified upper bound.

4. **IMPORTANT CAVEAT — physical classification remains weak.**
   Bulk-gap status is not computed, localization is weak, and parity is mixed/ambiguous. These facts limit interpretation but do not invalidate the frozen threshold-free FEM ranking or its canonical publication.

### Resource and lifecycle audit

The scientific command used `35.917169` s and `1,073,594,368` bytes, well below the authorized `2700` s and `3,221,225,472` bytes. Reviewer-side HDF5 inspection peaked at `171,982,848` bytes; conservatively charging all setup and inspection commands adds less than 25 s. The shared total therefore remains below 61 s, and the shared peak remains `1,073,594,368` bytes.

`run-008/execution-001` completed scientifically and is consumed. There is no operational failure supporting a retry or a new execution label.

### Claim boundary and next gate

What survives is the claim that `run-008` produced a reproducible, independently ranked, field-bearing pure-FEM candidate with complete five-twist W3 coverage. It does not establish continuous eigenpair existence, certified error, same-mode identity, reference convergence, BIE agreement, estimator validity, or effectivity.

The artifacts are sufficient to authorize **only implementation and static review of the reviewer-side §43.3 identity-audit tool**. Execution of that audit remains unauthorized until its own review gate passes. No further FEM run, BIE comparison, estimator read, effectivity comparison, or retry is authorized by this verdict.

## BG. Independent design review of §46 reviewer-side candidate-7 identity audit

### BG.1 Audit frame

Target: design §46, reviewed against §§43–45, review §BF, `test/AGENTS.md`, and the immutable `run-007`/`run-008` artifact schemas. This review did not implement or execute the audit, run MATLAB/Octave/Python numerical work, or read BIE/estimator data.

Success criterion: determine whether the proposed reviewer-side audit can independently identify the continuation of old FEM candidate 7 without changing the canonical `run-008` winner, leaking frequency/BIE information into selection, exceeding the shared resource budget, or publishing an ambiguous derived scalar.

### BG.2 Verdict

**REVISE** — high confidence.

The target-consistency revision is scientifically justified, the field-overlap method is implementable, and no selection leakage was found. One genuine resource blocker remains: §46.6 omits the already consumed §BF reviewer-inspection wall time from the controller’s hard-limit predicate. Consequently the proposed controller does not enforce the declared shared 2700 s budget. A small prospective amendment can close this without changing any scientific rule.

### BG.3 Strongest challenge and blocker

1. **BLOCKER — the executable wall predicate omits an already consumed required stage.**

   Section 46.6 defines the stop condition as
   $$
   35.917169+T_{\mathrm{audit}}\ge2700,
   $$
   leaving `2664.082831` s for the audit. But §BF was a required post-run gate and explicitly charged its read-only inspection to the same scientific-result budget: its reviewer work consumed less than 25 s and peaked at 171,982,848 bytes. Section 46.6 acknowledges that work but excludes its elapsed time from the controller formula. Thus an audit allowed to use the stated remaining time could make cumulative required-stage wall time exceed 2700 s before termination.

   **Smallest repair:** freeze a documented conservative §BF wall charge, for example exactly `25.000000` s, and define
   $$
   35.917169+25.000000+T_{\mathrm{audit}}\ge2700.
   $$
   The resulting executable remaining time is at most `2639.082831` s. Record scientific, §BF-review, audit, and cumulative wall values separately in `resource.tsv`. This is not a new lower gate; it is correct accounting for the sole 2700 s hard limit. Peak-memory accounting remains a maximum, so the existing 3,221,225,472-byte predicate is correct because the §BF peak is below the scientific peak.

### BG.4 Caveats

1. **IMPORTANT CAVEAT — assignment optimization direction should be stated explicitly.**

   Section 46.4 calls the procedure “maximum-total lexicographic assignment” but defines real-pair costs beginning with `(-O_ij,0,...)`. The reviewed MATLAB source resolves this by **lexicographically minimizing the total cost tuple**, so the negative first component maximizes total overlap. The Python contract should state that minimization direction explicitly; maximizing the written tuple would choose smaller overlaps. Because the existing source is an unambiguous referenced implementation, this is a bounded specification clarification rather than a second blocker.

2. **MINOR CAVEAT — two control-character LaTeX corruptions remain in §46.**

   - §46.3 contains a literal tab in the theta expression; the intended set notation should be `$\Theta_{17}$`.
   - §46.5 contains a vertical-tab corruption in the endpoint expression; it should be `$\vartheta=0,\pi$`.

   These are mechanical Markdown repairs and do not alter the design. `git diff --check` nevertheless passes because it does not detect these control characters.

### BG.5 What survived scrutiny

- The target revision is valid: canonical pure-FEM winner candidate 3 and its stored $\lambda_{30},k_{30}$ remain immutable, while a field-unique alternate component may supply the separately named `lambda30_candidate7` and `k30_candidate7`. This answers continuation of the old FEM mode rather than silently changing the pure-FEM ranking question.
- The alternate-component route preserves `SELECTED_BRANCH_MISMATCH / ALTERNATE_MATCH_IDENTIFIED`; it does not rewrite the canonical science artifact.
- Candidate selection uses complete FEM field inventories, common-core overlaps, deterministic assignment, mutual-best uniqueness, continuation, localization, and endpoint parity. Frequency-envelope distance is only a deterministic tie-break after overlap, and no BIE value, previous scalar proximity, estimator, or effectivity input is permitted.
- The old candidate-7 reconstruction is feasible from the allowlisted artifacts: the required five `fine-pXX.mat` caches and `mesh-defect-N5-s24-g48.mat` exist, and the old scientific schema contains the required configuration, realization, object, tracking, mesh, root, and solve identities.
- The common-grid interpolation, weighted Gram normalization, principal-overlap calculation, full assignment evidence, ambiguity states, and multiplicity caveat provide a reproducible identity test. Failure of auxiliary localization or parity evidence correctly yields `IDENTITY_AMBIGUOUS`, not a frequency-based replacement.
- The exact bundled HDF5 library path in §46.2 exists and exposes the required HDF5 1.8 APIs. A stdlib-only `/usr/bin/python3 -I -S` implementation using `ctypes`, streamed twist processing, RFC 8259 JSON, and explicit unknown-class failure is feasible within the prospective resource estimate.
- The create-once review leaf, two-file terminal contract, `null` rather than nonstandard `NaN`, post-audit review gate, and prohibition on direct profile/BIE execution preserve artifact authority and claim boundaries.
- The proposed status vocabulary does not call a location disagreement `DIFFERENT_MODE`, and derived candidate-7 scalars remain empirical and non-certified.

### BG.6 Minimal resolution and authorization

Researcher should append one bounded amendment that:

1. includes a frozen §BF reviewer-wall charge in the sole 2700 s cumulative predicate and resource schema;
2. states that assignment lexicographically minimizes the summed cost tuples;
3. repairs the two §46 control-character spellings.

Then return only that delta to the same Skeptic. Until it passes, **Engineer implementation is not authorized**. No audit execution, profile, BIE reveal, estimator read, effectivity comparison, new FEM solve, or new output leaf is authorized by this verdict.

## BH. Focused re-review of §47 closure

### BH.1 Scope

This review reopens only the §BG blocker and its two bounded clarifications. It does not reconsider §46’s scientific identity method, implement or execute the audit, or read BIE/estimator data.

### BH.2 Closure findings

1. **Resource blocker closed.** Section 47 freezes the prior reviewer charge at exactly `25.000000` s and defines the sole cumulative wall predicate as
   $$
   35.917169+25.000000+T_{\mathrm{audit}}\ge2700.
   $$
   The controller’s non-resettable remaining deadline is therefore exactly `2639.082831` s. Separate scientific/review/audit fields and their cumulative sum make post-run accounting auditable. Peak memory is correctly combined by maximum rather than addition, with the sole limit remaining 3,221,225,472 bytes.

2. **Assignment direction clarified.** Section 47 now explicitly requires componentwise summation of all matched/dummy cost tuples followed by lexicographic **minimization**. Because the real-pair first component is $-O_{ij}$, the first objective is unambiguously maximum total overlap. Pairwise greedy matching is explicitly excluded.

3. **Notation ambiguity closed.** Section 47 authoritatively fixes the intended spellings as `$\Theta_{17}$` and `$\vartheta=0,\pi$`. The earlier control bytes remain historical text, but they no longer create a mathematical or implementation ambiguity; mechanical documentation synchronization must use the corrected forms.

`git diff --check` passes.

### BH.3 Verdict and authorization

**PASS.** No unresolved blocker remains.

The same Engineer is authorized to implement only:

- `test/i4/femref-a1/identity_audit.py`;
- `test/i4/femref-a1/run_identity_audit.pl`;
- the necessary mechanical `README.md` and `SYMBOLS.md` synchronization.

Implementation must follow §§46–47 exactly. Audit execution, creation of `identity-001`, profile fitting, BIE reveal/comparison, estimator access, effectivity work, new FEM solves, and canonical-artifact mutation remain unauthorized. After implementation, Researcher theory-to-code review and the same Skeptic’s exact spec-to-code/resource pre-execution review are still mandatory.
## BI. Independent spec-to-code/resource pre-execution review of the candidate-7 identity audit

### BI.1 Audit frame

Target: current `identity_audit.py`, `run_identity_audit.pl`, `README.md`, and `SYMBOLS.md`, reviewed against design §§46–49 and review §§BG–BH.

This was a static, read-only review. No audit, MATLAB, Octave, FEM solve, profile, BIE read, estimator read, or output publication was performed. Artifact access was limited to metadata needed to verify frozen schema compatibility. `identity-001` remains absent.

### BI.2 Verdict

**REVISE** — high confidence.

Three concrete blockers would respectively prevent input decoding, force a false `IDENTITY_AUDIT_UNAVAILABLE`, or lose the mandatory resource terminal on the hard-wall path. Because launching now would permanently consume the create-once identity, the exact command is not authorized.

### BI.3 Blockers

1. **BLOCKER — the frozen HDF5 library does not export the bound reference API.**

   `identity_audit.py:302–303,447` binds and calls `H5Rdereference2`, but the exact frozen library
   `/Applications/MATLAB_R2023b.app/bin/maca64/libhdf5-1.8.8.dylib`
   exports `H5Rdereference` and does not export `H5Rdereference2`. Static symbol inspection confirms only `_H5Rdereference`.

   The first `Hdf5MatFile.__enter__()` therefore raises `AttributeError` during `_bind()`. That exception is not an `AuditUnavailable`, so Python exits nonzero without `identity-audit.json`; the runner would already have consumed `identity-001`.

   **Minimal repair:** bind the HDF5 1.8 signature
   `H5Rdereference(hid_t, H5R_type_t, const void *)` and use it for object references. Keep the frozen library path unchanged. Binding failure should be converted to `AuditUnavailable` or otherwise deterministically routed without an uncaught Python traceback.

2. **BLOCKER — the new scientific-object allowlist requires a nonexistent `configuration` field.**

   `NEW_SCIENCE_SPEC` at `identity_audit.py:164–186` assigns `OLD_OBJECT_SPEC` to the `run-008` compact object inventory. `OLD_OBJECT_SPEC` includes `configuration`, but metadata inspection confirms that `run-008/execution-001/scientific-result.mat` objects do not contain that field.

   After the reference-API repair, `_decode_object()` would therefore raise `HDF5_REQUIRED_FIELD_MISSING`. The exception would be caught and published as `IDENTITY_AUDIT_UNAVAILABLE`, incorrectly turning an implementation/schema mismatch into an identity result and permanently consuming the audit ID.

   **Minimal repair:** define a compact new-science object specification equal to `OLD_OBJECT_SPEC` minus `configuration`, without the full-field sample arrays, and use it only in `NEW_SCIENCE_SPEC`. Retain the existing `NEW_OBJECT_SPEC` with common-core fields for `fields.mat`.

3. **BLOCKER — the SIGALRM hard-wall path exits before publishing `resource.tsv`.**

   `run_identity_audit.pl:27–32` kills the target and immediately calls `POSIX::_exit(2)`. Consequently an alarm-triggered 2700 s hard stop bypasses child reap, elapsed/peak calculation, and `write_resource()` at lines 140–148. It cannot preserve the required resource terminal or distinguish the hard-wall outcome from an unexplained incomplete leaf.

   **Minimal repair:** the signal handler must immediately kill the target and set a wall-limit flag, but must not `_exit` before cleanup. The main path must prioritize that flag over interrupted `ps`/wait results, reap or confirm the target dead, classify `WALL_HARD_LIMIT_REACHED`, and exclusively publish `resource.tsv` before returning nonzero. This must not add a second deadline, grace period, reserve, or lower stop.

### BI.4 What survived scrutiny

- File and run identities, five old target twists, exact cache names, candidate selection by `candidate_id == 7`, and old 17-slice continuation reconstruction match the frozen contract.
- Apart from the new compact-schema error, the decoder’s reversed HDF5 dimensions, MATLAB column-major reconstruction, numeric/logical/char/compound handling, reference recursion, and allowlisted-field policy are structurally consistent.
- The common-grid loop order matches MATLAB `meshgrid(...); (: )` ordering. The $P_1$ barycentric interpolation, positive $q$-weighted trapezoid weights, deterministic triangle choice, and weight cross-check match §§46–47.
- Weighted Gram construction, right normalization through the lower Cholesky factor, complex Hermitian Jacobi iteration, and principal-overlap calculation implement the intended field comparison.
- The assignment now uses the corrected endpoint-max frequency distance and a complete dummy-augmented lexicographic minimization; no greedy or BIE/frequency-gate selector is present.
- Strict mutual-best checks, overlap thresholds, old/new continuation, localization, endpoint parity, multiplicity status, conditional candidate-7 scalar, and publication cross-check follow the frozen claim boundary.
- Unsupported identity correctly publishes no identity component, no derived scalar, and `profile_gate=NOT_ELIGIBLE`.
- Outside the alarm path, the runner has the correct no-argument command, create-once leaf, cumulative `35.917169 + 25.000000 + T_{\mathrm{audit}}` wall accounting, sole 3,221,225,472-byte RSS hard limit, process-tree aggregation, and no lower forecast/stall/reserve gate.
- No active BIE, estimator, effectivity, Markdown, Git, or historical scalar input was found.
- `git diff --check` passes.

### BI.5 Minimal resolution and authorization

Return only the three bounded repairs above to the same Engineer, update README/SYMBOLS so they do not claim a passed static implementation prematurely, then obtain a Researcher delta mapping and the same Skeptic’s focused pre-execution re-review.

**Execution remains unauthorized.** In particular, do not run:

```sh
/usr/bin/perl ./run_identity_audit.pl
```

and do not create `identity-001`. After a future pre-execution PASS, that exact command may be authorized once from `test/i4/femref-a1`; its result will still require independent post-audit artifact/resource/claim review before any profile or late BIE comparison.
## BJ. Focused pre-execution re-review of the §BI repairs

### BJ.1 Scope

This review reopens only the three §BI blockers and Researcher §50. The previously accepted identity mathematics, assignment hierarchy, claim boundary, and input allowlist were not re-audited. No audit, Python entry, Perl runner, MATLAB, Octave, BIE read, estimator read, profile, or output publication was performed.

### BJ.2 Repair verification

1. **HDF5 reference binding — closed.**

   `identity_audit.py` now binds the three-argument HDF5 1.8 function
   `H5Rdereference(hid_t, H5R_type_t, const void *)`; static library-symbol inspection confirms that the frozen `libhdf5-1.8.8.dylib` exports this exact symbol. The active source contains no `H5Rdereference2`. Library and binding failures are converted to `AuditUnavailable`, while negative dereferences remain `HDF5_DANGLING_REFERENCE`.

2. **Run-008 compact schema — closed.**

   `NEW_COMPACT_OBJECT_SPEC` is now the old object schema minus the run-007-only `configuration` field. `NEW_SCIENCE_SPEC` uses this compact schema, while `NEW_FIELDS_SPEC` uses the separate extended schema containing common-core samples, weights, and validity. This matches the frozen run-008 metadata and removes the false `HDF5_REQUIRED_FIELD_MISSING` route.

3. **Hard-wall terminal publication — closed.**

   The SIGALRM handler now sets one wall-limit flag and immediately kills the target without calling `_exit`. The controller checks the same flag/deadline before and after process-table, RSS, and reap operations; it then reaps the child, confirms the dedicated target group is dead, freezes `WALL_HARD_LIMIT_REACHED`, and reaches the unique create-once `resource.tsv` writer before returning nonzero.

   The only resource uppers remain:

   $$
   35.917169+25.000000+T_{\mathrm{audit}}\ge2700
   $$

   and aggregate audit process-tree RSS at or above `3221225472` bytes. No lower wall/RSS gate, forecast, stall, reserve, grace period, or retry was introduced.

### BJ.3 Residual checks

- `identity-001` is absent.
- The runner remains fixed, no-argument, and bound to `run-008/execution-001/review-audit/identity-001`.
- Unsupported identity still publishes no matched identity component, no derived candidate-7 scalar, and `profile_gate=NOT_ELIGIBLE`.
- The repaired source contains no BIE, estimator, effectivity, historical scalar, Markdown, or Git runtime input.
- README/SYMBOLS remain prospective and do not claim that the audit has run.
- `git diff --check` passes.

No blocker, important caveat, or new claim-boundary defect was found in the bounded repair.

### BJ.4 Verdict and exact authorization

**PRE-EXECUTION PASS.**

One and only one execution is authorized from:

```text
/Users/whc/Documents/Work/epost/test/i4/femref-a1
```

using exactly:

```sh
/usr/bin/perl ./run_identity_audit.pl
```

This authorization creates only `identity-001`; it does not authorize retry, `identity-002`, FEM recomputation, profile fitting, BIE reveal/comparison, estimator access, effectivity analysis, or canonical-artifact modification.

After the command finishes, the same Skeptic must review `identity-audit.json`, `resource.tsv`, create-once integrity, overlap/assignment evidence, identity and selection statuses, conditional scalar publication, cumulative wall/RSS, and the claim boundary. Profile or late BIE comparison remains prohibited until that post-audit review explicitly accepts a `SAME_MODE_SUPPORTED*` result.
## BK. Independent review of §51 operational recovery

### BK.1 Scope and evidence

This review is limited to the `identity-001` operational classification, the proposed `identity-002` recovery identity, non-reset resource accounting, and the required execution context. It does not reopen the identity method and did not read BIE/estimator data or execute any audit.

The immutable `identity-001` leaf contains only `resource.tsv`. It records:

- `audit_wall_seconds=0.001110000`;
- `cumulative_wall_seconds=60.918279000`;
- `audit_peak_rss_bytes=0`;
- `cumulative_peak_rss_bytes=1073594368`;
- `controller_terminal=RSS_ENFORCEMENT_UNAVAILABLE`;
- `python_signal=9`.

No `identity-audit.json` exists.

### BK.2 Findings

1. **Operational classification — accepted.**

   The process-table authority failed before any review result was published, and the controller killed the Python target fail-closed. The artifact contains no field comparison or identity verdict. Classification as
   `HOST_SANDBOX_OPERATIONAL_FAILURE / PROCESS_TABLE_PERMISSION_DENIED`
   is consistent with the terminal evidence and observed `/bin/ps` permission denial. It is not a numerical, FEM-method, identity-method, or memory-capacity failure. `identity-001` is permanently consumed and must remain immutable.

2. **BLOCKER — the recovery identity change is internally contradictory and incomplete.**

   Section 51.2 permits changing only the controller’s fixed ID to `identity-002`, while also stating that `identity_audit.py` must not change. Current `identity_audit.py` still fixes

   ```text
   AUDIT_ID = "identity-001"
   ```

   and uses it both in JSON identity fields and in the publication path. If only the controller is changed, it will claim `identity-002`, but Python will try to publish into the already consumed `identity-001` leaf and fail its exclusive create. The new leaf would be consumed without an identity JSON.

   **Smallest repair:** explicitly authorize only the mechanical identity change in both files:

   - Python `AUDIT_ID`, JSON `audit_id`, and its fixed review-audit publication path become `identity-002`;
   - Perl `$AUDIT_ID`, collision/error strings, and fixed leaf become `identity-002`;
   - README/SYMBOLS are updated mechanically;
   - Python inputs, decoder, schemas other than the audit ID value, numerical algorithm, statuses, and output-field contract remain unchanged;
   - neither path may read or copy `identity-001`.

3. **Non-reset wall accounting — accepted.**

   The arithmetic is exact:

   $$
   2700-(35.917169+25.000000+0.001110)=2639.081721\ \mathrm{s}.
   $$

   The recovered controller must record the scientific, reviewer, immutable `identity-001` operational, and current `identity-002` wall charges separately and use their sum. The previous charge may not be reset or omitted.

4. **Memory contract — accepted.**

   Peak memory remains a maximum rather than a sum. The previous zero-byte observation is not evidence of memory resolution, but it does not increase the existing combined peak of `1073594368` bytes. The only inclusive hard upper remains `3221225472` bytes, with no lower proxy or gate.

5. **Execution context — accepted.**

   Requiring an explicitly escalated/unsandboxed launch is necessary and sufficient for the controller’s `/bin/ps -axo ...` process-tree authority. Continued inability to obtain that authority must again fail closed; it cannot justify bypass, automatic retry, or another ID.

### BK.3 Verdict and handoff

**REVISE.**

The operational classification, cumulative resource rules, and escalated-context requirement are accepted. Only the cross-file `identity-002` identity authorization must be clarified before implementation.

Engineer implementation and execution are not authorized by this verdict. After the bounded design clarification, return it to the same Skeptic. A subsequent PASS may authorize only the mechanical ID/resource/docs changes; Researcher theory-to-code and Skeptic spec-to-code review must still pass before any escalated execution.
## BL. Focused delta review of §52 cross-file identity authority

### BL.1 Scope

This review reopens only the §BK cross-file `identity-002` blocker. The operational classification, identity method, decoder, numerical thresholds, assignment, claim boundary, and resource limits are not reconsidered. No implementation or execution was performed.

### BL.2 Closure

Section 52 closes the blocker unambiguously:

- Python’s fixed `AUDIT_ID`, JSON `audit_id`, and publication path must all become `identity-002`.
- Perl’s fixed ID, collision check, create-once directory, diagnostic strings, and `resource.tsv` path must use the same namespace.
- Neither file may dynamically select an ID or read/reuse `identity-001`.
- `identity-001` remains an immutable consumed operational-failure leaf.
- The resource schema separately records scientific, reviewer, `identity-001`, and current `identity-002` wall/RSS fields.
- The sole remaining wall allowance is exactly `2639.081721` s, and the sole memory upper remains `3221225472` bytes.
- README/SYMBOLS must distinguish the consumed operational failure from the prospective `identity-002` audit and must not claim an identity result or execution.

`git diff --check` passes. No unresolved blocker or caveat remains in this bounded design delta.

### BL.3 Verdict and authorization

**PASS.**

The same Engineer is authorized to implement only:

1. the mechanical cross-file switch from `identity-001` to `identity-002`;
2. the four-part non-reset wall/RSS accounting and exact remaining deadline;
3. the corresponding README/SYMBOLS status synchronization.

The HDF5 decoder, field-identity algorithm, thresholds, assignment, JSON fields other than the audit ID, conditional scalar rules, and claim boundary must remain unchanged.

This PASS does **not** authorize execution or creation of `identity-002`. After implementation, Researcher cross-file theory-to-code review and the same Skeptic’s focused pre-execution review remain mandatory. Any eventual execution must still use the explicitly escalated context required by §51.
## BM. Final focused pre-execution review for `identity-002`

### BM.1 Scope

This review is limited to the §52 mechanical implementation and Researcher §53. The identity algorithm, HDF5 decoder, numerical thresholds, assignment, and claim boundary were not reopened. No audit, BIE/estimator access, or output creation was performed.

### BM.2 Static verification

- Python fixes `AUDIT_ID="identity-002"` and derives both JSON `audit_id` and the unique publication path from it.
- Perl independently fixes `$AUDIT_ID='identity-002'`; collision check, create-once directory, error messages, and `resource.tsv` all target the same namespace.
- No active `identity-001` publication or input path remains. Its values appear only as immutable resource charges.
- The remaining absolute deadline is exactly `2639.081721` s.
- Cumulative wall is the sum of `35.917169`, `25.000000`, `0.001110`, and current `identity-002` elapsed.
- Scientific, reviewer, `identity-001`, and `identity-002` RSS peaks are recorded separately and combined by maximum.
- The only inclusive memory upper is `3221225472` bytes; no lower resource gate was introduced.
- README/SYMBOLS correctly distinguish the consumed `identity-001` sandbox failure from prospective, unexecuted `identity-002`.
- `identity-002` is absent, and `git diff --check` passes.

No unresolved blocker or caveat was found in this bounded implementation.

### BM.3 Verdict and one-time authorization

**PRE-EXECUTION PASS.**

Exactly one execution is authorized from:

```text
/Users/whc/Documents/Work/epost/test/i4/femref-a1
```

using exactly:

```sh
/usr/bin/perl ./run_identity_audit.pl
```

The command **must** be launched through a `require_escalated`/unsandboxed execution context so `/bin/ps -axo ...` can provide authoritative aggregate process-tree RSS monitoring. Running it in the ordinary sandbox is not authorized.

This authorization is one-time and applies only to `identity-002`. It does not authorize retry, another identity ID, profile fitting, BIE reveal/comparison, estimator access, effectivity analysis, FEM recomputation, or canonical-artifact modification.

After completion, the same Skeptic must perform a post-audit review of the JSON, resource record, create-once integrity, identity/selection status, conditional scalar publication, cumulative wall/RSS, and claim boundary. Profile or late BIE comparison remains prohibited until that review explicitly accepts the result.
## BN. `identity-002` post-audit artifact/resource/claim review

### BN.1 Audit frame

Target: the completed create-once leaf
`output/run-008/execution-001/review-audit/identity-002/`.

This review inspected only its two artifacts and performed a read-only symbol comparison against the exact bundled HDF5 dylib. It did not read BIE/estimator data, run a field comparison, create another audit ID, or perform profile/effectivity work.

### BN.2 Artifact and resource integrity

The leaf contains exactly:

- `identity-audit.json` — 778 bytes;
- `resource.tsv` — 409 bytes.

No partial or temporary file is present. The JSON consistently records:

- `audit_id=identity-002`;
- `audit_terminal=IDENTITY_AUDIT_UNAVAILABLE`;
- `candidate7_identity_status=IDENTITY_AUDIT_UNAVAILABLE`;
- caveat `HDF5_BINDING_UNAVAILABLE`;
- `matched_component_id=null`;
- `lambda30_candidate7=null`;
- `k30_candidate7=null`;
- `selection_relation=NO_UNIQUE_IDENTITY_COMPONENT`;
- `profile_gate=NOT_ELIGIBLE`.

The resource artifact records:

- `identity002_wall_seconds=2.053772000`;
- `cumulative_wall_seconds=62.972051000`;
- `identity002_peak_rss_bytes=966656`;
- `cumulative_peak_rss_bytes=1073594368`;
- controller `NATURAL_EXIT`;
- Python exit `0`, signal `0`.

The arithmetic is internally exact:

$$
35.917169+25.000000+0.001110+2.053772
=62.972051\ \mathrm{s}.
$$

Both wall and peak RSS are below 2700 s and 3,221,225,472 bytes. The tiny current-audit RSS is only evidence that the program stopped before substantive decoding; it is not a memory-resolution result.

### BN.3 Failure classification

**This is an operational HDF5 binding failure, not an identity, FEM, same-mode, or resource-capacity failure.**

`NATURAL_EXIT` means the Python program correctly caught the binding exception, published the fail-closed JSON, and returned normally. It does not mean the identity audit succeeded.

The failure occurs during `_bind()` before `H5open`, input-file opening, field reconstruction, Gram/SVD computation, assignment, or identity classification. Therefore:

- no FEM field comparison was performed;
- no overlap or continuation evidence was produced;
- no candidate was accepted or rejected;
- no conclusion about whether candidate 7 persists at $s=30$ is supported.

The claim downgrade is correct and prevents any profile or BIE continuation.

### BN.4 Decisive static diagnosis

The active decoder references 32 HDF5 symbols. Static comparison with the exact dylib finds 31 present and exactly one missing:

```text
H5free_memory
```

The dylib exports `H5Rdereference`, confirming the prior repair, but does not export `H5free_memory`. Its embedded version string identifies HDF5 1.8.12 despite the filename `libhdf5-1.8.8.dylib`. This precisely explains `HDF5_BINDING_UNAVAILABLE`.

### BN.5 Findings and verdict

1. **BLOCKER — exact-library deallocation API is unresolved.**

   The current decoder cannot bind the exact library because it assumes `H5free_memory`. Until the ownership/deallocation contract for the pointer returned by `H5Tget_member_name` is verified for this bundled HDF5 1.8.12 library, the audit cannot safely decode compound complex fields.

2. No other artifact, resource, claim-boundary, or lifecycle defect is demonstrated by this run.

**Post-audit verdict: `BLOCKED — OPERATIONAL HDF5 BINDING FAILURE`.**

`identity-002` is permanently consumed. This verdict is not `IDENTITY_AMBIGUOUS` and is not evidence against the FEM method or same-mode hypothesis.

### BN.6 Minimal next diagnostic scope

The next action should remain read-only and static:

1. preserve the exact 32-symbol binding inventory and the finding that only `H5free_memory` is absent;
2. inspect the exact bundled HDF5 1.8.12 API or authoritative headers/documentation for the allocation ownership of `H5Tget_member_name`;
3. determine the correct available deallocator or a safe API-compatible way to avoid that allocation;
4. statically verify the proposed function signature and library symbol before any source repair or execution request.

A future source correction would still require bounded Researcher design, Engineer implementation, Researcher theory-to-code review, and Skeptic pre-execution review.

No new audit ID, retry, profile, BIE reveal/comparison, estimator access, effectivity work, or FEM computation is authorized.
## BO. Independent design review of §54 allocation-free recovery

### BO.1 Scope

This review is limited to the allocation-free HDF5 member lookup, the prospective `identity-003` lifecycle, and non-reset resource accounting. The FEM identity method, field values, thresholds, assignment, statuses, and claim boundary were not reopened. No audit or BIE/estimator access was performed.

### BO.2 Exact-library review

The fixed dylib identifies itself internally as HDF5 1.8.12 and exports:

- `H5Tget_member_index`;
- `H5Tget_member_name`;
- `H5Tget_member_offset`;
- `H5Tget_member_type`;
- `H5Tget_nmembers`.

It does not export `H5free_memory`.

Local disassembly of `H5Tget_member_index` confirms the two incoming arguments are the datatype identifier and member-name pointer, that names are compared using `strcmp`, and that the function returns the existing member index without allocating a caller-owned name buffer. This supports the frozen signature:

```c
int H5Tget_member_index(hid_t type_id, const char *name);
```

The proposed repair is therefore allocation-free and avoids both unsafe alternatives: binding the unavailable cross-version `H5free_memory` or relying on an internal allocator/deallocator.

Retaining the exact two-member check, querying both `"real"` and `"imag"`, requiring distinct in-range indices, and then applying the existing type/offset/size checks preserves name validation without assuming member order.

### BO.3 Lifecycle and resource review

The prospective identity is consistently frozen as `identity-003`; `identity-001` and `identity-002` remain immutable consumed operational failures and may not be active inputs.

The prior wall calculation is exact:

$$
35.917169+25.000000+0.001110+2.053772
=62.972051\ \mathrm{s},
$$

so the remaining allowance is exactly:

$$
2700-62.972051=2637.027949\ \mathrm{s}.
$$

The future resource record must preserve all five stage entries and combine RSS by maximum. Prior peak remains `1073594368` bytes, and the only inclusive memory upper remains `3221225472` bytes. No lower wall/RSS gate, reset, forecast, reserve, stall, guard, or grace period is introduced.

`identity-003` is absent, and `git diff --check` passes.

### BO.4 Verdict and implementation authorization

**PASS.**

The same Engineer is authorized only to:

1. replace `H5Tget_member_name`/`H5free_memory` bindings and use with the public allocation-free `H5Tget_member_index` path specified in §54;
2. mechanically synchronize Python, JSON, runner, collision messages, and publication paths to `identity-003`;
3. add the immutable `identity-002` wall/RSS entries and exact `2637.027949` s remaining deadline;
4. update README/SYMBOLS mechanically.

No other decoder, numerical, identity, assignment, status, input, or claim behavior may change.

This PASS does **not** authorize execution or creation of `identity-003`. After implementation, Researcher theory-to-code review and the same Skeptic’s focused pre-execution review remain mandatory. Any later execution must still use the explicitly escalated/unsandboxed context.
## BP. identity-003 最终 focused pre-execution review

### 审查范围

仅复审 Researcher §55 对 §54/§BO 已通过设计的有界实现；未执行 audit，未读取 BIE、estimator 或历史数值以选根，也未创建任何新 artifact。

### 静态核验

- `identity_audit.py` 与 `run_identity_audit.pl` 均唯一固定为 `identity-003`；complete、unavailable、publication 和 resource 路径一致，现有 `identity-003` namespace 不存在。
- HDF5 compound decoder 已移除 `H5Tget_member_name`、`H5free_memory` 及其他分配/释放路径。当前实现使用已由精确 MATLAB dylib 导出并核验签名的 `H5Tget_member_index(type_id, "real"/"imag")`。
- 原有 member count、索引互异、member type、offset、float class 和 4/8-byte size 检查均保留；修复没有改变 candidate7 映射、插值、Gram/SVD、assignment、continuation、localization、parity 或 claim boundary。
- runner 的固定命令仍为 `/usr/bin/python3 -I -S ./identity_audit.py`。剩余 wall budget 为 `2637.027949` s，唯一 RSS hard limit 为 `3221225472` bytes；identity-001/002 的 wall/RSS charge 均计入累计字段，没有预算重置或较低停止门。
- create-once、partial publication、absolute deadline、target-tree RSS enforcement 和 resource summary 路径保持一致。README/SYMBOLS 已同步 identity-003 的 prospective 状态及五阶段资源 schema。
- 静态检查未发现旧 ID、旧 deallocator binding、BIE/estimator 输入或 identity-001/002 读取回流；`git diff --check` 通过。

### Findings

- `BLOCKER`: 无。
- `IMPORTANT CAVEAT`: 无新增。
- `MINOR CAVEAT`: 无需在执行前处理。

### Verdict

**PRE-EXECUTION PASS**

授权仅一次执行：

- cwd：`/Users/whc/Documents/Work/epost/test/i4/femref-a1`
- command：`/usr/bin/perl ./run_identity_audit.pl`

该命令必须以 `require_escalated`／unsandboxed context 启动，以保证 runner 能读取完整进程表并执行既定 RSS 监管。除此之外不授权 retry、新 identity ID、profile、BIE、estimator 或 effectivity 操作。执行完成后，必须由同一 Skeptic 完成 post-audit artifact/resource/claim review，之后才能决定是否进入 profile/BIE。
## BQ. `identity-003` post-audit artifact/resource/claim review

### Audit frame

本节只读核验：

- `output/run-008/execution-001/review-audit/identity-003/identity-audit.json`
- `output/run-008/execution-001/review-audit/identity-003/resource.tsv`

未读取旧 profile、BIE 或 estimator，未执行新的 eigensolve、mesh、MATLAB、Octave 或数值实验。目标仅是判断冻结的 reviewer-side FEM field identity audit 是否完整、内部一致，并决定是否可进入另经审查的 postprocess。

### Artifact 与输入完整性

- leaf 中恰有两个 terminal files：`identity-audit.json`（767073 B）和 `resource.tsv`（481 B）；无 partial、temporary 或额外文件。
- JSON 可按标准 JSON 完整解析，且给出：
  - `schema_version=i4a-candidate7-identity-v1`
  - `audit_id=identity-003`
  - `audit_terminal=IDENTITY_AUDIT_COMPLETE`
- 输入身份与冻结合同一致：
  - old：`run-007/execution-001`，`i4a-diagnostic-ranking-v2`
  - new：`run-008/execution-001`，science `i4a-s30-refinement-v1`，fields `i4a-s30-fields-v1`
- old candidate 7 按字段身份恢复出 47 个互异 realizations；五个目标行分别是 old theta indices $1,5,9,13,17$、`fine-p01/p05/p09/p13/p17`、root 11、dimension 1。
- common grid 保留 10465 点，weight sum 为 13.03125；未发现 unavailable 或非有限状态。

### 五 twist identity evidence

每个 twist 的 old/new field-bearing inventory 均为 29 个对象；overlap、frequency-distance 和 principal-singular-value 矩阵均为 $29\times29$。每个 global assignment 含 29 个互异 real pairs，完整 dummy-augmented ledger 含 58 项。

冻结目标映射为：

| phase | old object | new object | overlap |
|---|---:|---:|---:|
| $0$ | 9 | 9 | 0.9999975690137297 |
| $\pi/4$ | 125 | 38 | 0.9999975689864963 |
| $\pi/2$ | 241 | 67 | 0.9999975689207237 |
| $3\pi/4$ | 357 | 96 | 0.9999975688549545 |
| $\pi$ | 473 | 125 | 0.9999975688277154 |

五对均：

- 出现在完整 global assignment 中；
- 为 strict mutual best；
- 通过 simple–simple threshold $0.90$；
- row strict gap 至少 0.9171526270，column strict gap 至少 0.9162254250；
- dimension 均为 1，故无 multiplicity caveat。

old 完整 $\Theta_{17}$ chain 的 16 条边全部存在；new 五 twist matched chain 的四条边全部存在。五个 localization rows 均 available，old/new 均分类为 `localized`；endpoint parity 在 $0,\pi$ 均为 available、even/even match。JSON `caveats=[]`。

因此冻结判据下的

`candidate7_identity_status=SAME_MODE_SUPPORTED`

可接受。

### Selection relation 与 conditional publication

匹配的新 component 为 candidate 9，而 canonical pure-FEM winner 仍是 candidate 3：

- canonical：$\lambda_{30}=0.6150250894609801$，$k_{30}=0.7842353533608263$；
- identity component：`matched_component_id=9`；
- `selection_relation=PURE_FEM_WINNER_DIFFERS_IDENTITY_COMPONENT`；
- `selection_fact=SELECTED_BRANCH_MISMATCH / ALTERNATE_MATCH_IDENTIFIED`。

identity component 的五个新 eigenvalues 给出

$$
\Lambda_{30}^{(7)}
\subset
[3.3661924255424971,\ 3.3662142597747793],
$$

并按冻结 midpoint 规则得到

$$
\lambda_{30}^{(7)}=3.366203342658638,\qquad
k_{30}^{(7)}=1.834721598133798.
$$

重新计算所得 midpoint 与平方根分别和新 scientific artifact 中 candidate 9 的 stored publication scalars 一致，`lambda_matches=true`、`k_matches=true`。`profile_gate=ELIGIBLE_AFTER_POST_AUDIT_REVIEW` 与上述状态一致。

### Resource 与 lifecycle audit

五阶段账本为：

| stage | wall (s) | peak RSS (B) |
|---|---:|---:|
| scientific | 35.917169 | 1,073,594,368 |
| reviewer inspection | 25.000000 | 171,982,848 |
| identity-001 | 0.001110 | 0 |
| identity-002 | 2.053772 | 966,656 |
| identity-003 | 29.683016 | 564,379,648 |

累计 wall 为 92.655067 s，逐项求和与 ledger 完全一致；累计 peak 为五阶段最大值 1,073,594,368 B。二者分别低于 2700 s 和 3,221,225,472 B。controller 为 `NATURAL_EXIT`，Python exit 0、signal 0；无硬预算触发或 operational failure。

### Findings

1. **IMPORTANT CAVEAT — canonical selection 与 identity component 不同。**
   最强反例是 threshold-free pure-FEM ranking 选择 candidate 3，而 field identity 唯一支持 candidate 9 作为旧 candidate 7 的延续。该差异已被 artifact 明确记录，不能在后续文档中把 $k_{30}^{(7)}$ 称为 canonical pure-FEM winner。它不推翻 field identity，也不阻止 candidate-specific convergence postprocess。

2. **MINOR CAVEAT — claim strength。**
   `SAME_MODE_SUPPORTED` 是基于冻结 FEM field overlap、continuation、localization 和 parity 的数值身份支持，不是 certified identity theorem、连续谱存在性证明或 reference upper bound。

3. **BLOCKER：无。**

### Verdict

**PASS WITH CONDITIONS**

接受冻结意义下的 `SAME_MODE_SUPPORTED`，并接受 $k_{30}^{(7)}=1.834721598133798$ 作为旧 candidate 7 的经审查、candidate-specific $s=30$ scalar；canonical candidate 3 的事实不得被覆盖。

授权进入下一道独立设计与预执行审查后的 postprocess：

- 使用预注册的 $k_{12},k_{18},k_{24}$ 与这里接受的 $k_{30}^{(7)}$ 完成冻结的四点 profile；
- 对预注册 $k_{30}^{\mathrm{pred}}$ 报告样本外残差；
- 仅在上述 FEM quantities 冻结后揭示并使用 late BIE scalar 作冻结的位置比较。

该授权不允许用 BIE 重选 candidate，不授权 estimator、effectivity comparison、certified bound、连续特征值存在性结论或新的 FEM run。
## BR. Independent design review of §56 `profile-001`

### Audit frame

审查目标是 prospective candidate-specific scalar postprocess，不是新 FEM run。成功标准是：只对 §BQ 已接受的 candidate 7 $\to$ new candidate 9 identity scalar作冻结四点 profile、样本外预测残差和 late-BIE 位置比较，同时保持 canonical candidate 3、资源账本及 non-certified claim boundary 不变。

### Design audit

1. **Frozen mathematical inputs are consistent.**
   §56 使用预注册 $k_{12},k_{18},k_{24},k_{30}^{\mathrm{pred}}$、§BQ 接受的
   $k_{30}^{(7)}=1.834721598133798$，并把 late-BIE scalar 限定为 identity 和 $k_{30}^{(7)}$ 冻结后的只读常数。signed drifts、absolute drifts、ratios、prediction residual 和 strict BIE boolean 均与 §43.4 一致；零分母只降级为 JSON `null`，不会取消有效 scalar。

2. **Variable-projection fit is mathematically and operationally determinate.**
   模型 $k(s)=k_\infty+C s^{-p}$、$p=\exp(x)>0$ 保持不变。每个 $x$ 的 economy-QR solve、SSE objective、七个固定 starts、`fminsearch` options 及 `(SSE,p,start_index)` lexicographic winner 均已逐字冻结。非有限、rank-deficient 或非正 exitflag 只产生 `FIT_NUMERICALLY_UNRESOLVED`，不会伪造 fit success，也不会撤销 $k_{30}$ 或其他直接量。

3. **Sealed ordering and information isolation are adequate.**
   MATLAB entry 无输入，不读取 identity JSON、history、既有 output、Markdown、Git、field、eigenpair 或 estimator。BIE scalar 作为 post-identity literal 只参与最终 absolute-distance/strict-boolean 计算，不进入 candidate selection、四点 fit 或任何调参。最强潜在反例——用 BIE proximity 改选 branch——已被 source contract 明确排除。

4. **Publication and create-once contract are sufficient.**
   fresh `profile-001` leaf 只允许 `profile.json` 和 summary-last `resource.tsv`。JSON schema、candidate context、七-start ledger、winner/status、empirical certification 和 `effectivity_performed=false` 均明确；非有限值不得以 `NaN`/`Infinity` 发布。成功、数值未决和 operational failure 的边界可区分，leaf 一经创建即消费且不得覆盖或自动换 ID。

5. **Resource contract remains non-reset.**
   prior charge 固定为 92.655067 s 和 1,073,594,368 B，故唯一 wall predicate 为
   $92.655067+T_{\mathrm{profile-001}}\ge2700$，remaining 为 2607.344933 s；唯一 memory upper 为 3,221,225,472 B，cumulative RSS 按 maximum 而非求和。300 s/1.5 GiB 仅是 prospective estimate，不是较低停止门。fixed no-argument runner、dedicated process group、authority-loss handling 和 summary-last resource publication足以执行该硬预算。

### Findings

- `BLOCKER`: 无。
- `IMPORTANT CAVEAT`: canonical pure-FEM winner 仍是 candidate 3；所有 profile/BIE 输出必须明确标为 candidate-7 identity component，即 new candidate 9，不能把 $k_{30}^{(7)}$ 改称 canonical winner。§56 已正确保留此边界。
- `MINOR CAVEAT`: 四点拟合及外推即使 `FIT_RESOLVED` 也只是 empirical model fit，不证明渐近区间、连续谱存在性或 certified error。§56 已正确降级。
- Mechanical check：`git diff --check` 当前仅报告既有 §BQ 两行 Markdown hard-break trailing spaces；不是 §56 设计缺陷，也不阻止实现。

### Verdict

**DESIGN PASS**

授权同一 Engineer 仅：

1. 新增 `test/i4/femref-a1/profile_postprocess.m`；
2. 新增 `test/i4/femref-a1/run_profile_postprocess.pl`；
3. 如需同步 README/SYMBOLS，只可机械登记 `profile-001` 为 implemented but not run，不得写入结果。

本 PASS 不授权执行、不授权创建 `profile-001` leaf，也不授权 estimator、effectivity、新 FEM solve 或 certified-reference claim。实现后仍须先完成 Researcher theory-to-code mapping，再由同一 Skeptic 完成 exact spec-to-code/resource pre-execution review。
## BS. Exact spec-to-code/resource pre-execution review of `profile-001`

### Audit frame

本节只静态核对 `profile_postprocess.m`、`run_profile_postprocess.pl` 与 §§56–58/§BR；未运行 MATLAB、Octave、Perl 或 postprocess，未创建或读取 `profile-001` artifact。当前 `profile-001` leaf 不存在。

### MATLAB specification-to-code audit

1. **Frozen inputs and direct quantities match exactly.**
   - `s_values=[12,18,24,30]`；
   - 四个 candidate-7 identity-component scalars、$k_{30}^{\mathrm{pred}}$、late $k_{\mathrm{BIE}}$ 与 $D_{\mathrm{old}}$ 均逐字匹配 §56；
   - `diff(k_values)` 正确实现 finer-minus-coarser signed drifts；
   - absolute drifts、两个 ratios、prediction residual、late-BIE absolute distance 和严格 `<` boolean 均无额外 threshold 或 branch-selection 路径；
   - zero denominator 只发布 `null`-eligible `NaN` 和 `UNDEFINED_ZERO_DENOMINATOR`。

2. **QR variable projection and seven-start search are exact.**
   - 模型为 $k(s)=k_\infty+C s^{-p}$、$p=\exp(x)>0$；
   - 每次调用使用 `qr(A,0)` 与 `R \ (Q' * k(:))`；
   - objective 唯一为 residual SSE；
   - 非有限 $x,p,A,R$、zero diagonal $R$ 或非有限 coefficients/SSE 均返回 `Inf` objective，不引入 condition-number gate；
   - 七个 starts、`TolX`、`TolFun`、`MaxIter`、`MaxFunEvals` 与设计一致；
   - winner 只在 finite/full-rank endpoints 中按 `(SSE,p,start_index)` ascending `sortrows` 选择，exitflag 不参与排名，只决定 resolved/unresolved status；
   - 无 finite winner 与非正 winner exitflag 的 publication downgrade 均符合冻结语义。

3. **JSON and claim boundary are consistent.**
   - candidate context 明确区分 old candidate 7、new identity component candidate 9 与 canonical candidate 3；
   - 七-start ledger、winner、fit status、direct quantities和 late comparison 均进入单一 payload；
   - `jsonencode(...,'ConvertInfAndNaN',true)` 后再次拒绝 `NaN`/`Infinity` token；
   - `certification_status=EMPIRICAL_NON_CERTIFIED` 且 `effectivity_performed=false`；
   - source 无 argument、`load`、`read*`、`fileread`、identity/scientific artifact、Markdown、Git 或 estimator 读取。Late-BIE literal 不进入 fit、winner 或 candidate selection。

4. **Publication repair closes §57 blocker.**
   `fopen(...,'w','n','UTF-8')` 是 §58 限定修复。它只能由 exact runner 在原子声明的 fresh `profile-001` leaf 中调用；runner 在 fork 前拒绝 existing leaf，因此该 write mode 不会覆盖历史 artifact。byte-count 和 close checks 保留，未引入第二 publication path。

### Runner/resource audit

- runner 固定无参数，唯一 MATLAB command 为
  `/Applications/MATLAB_R2023b.app/bin/matlab -batch "profile_postprocess"`；
- exact create-once namespace 为 `run-008/execution-001/review-audit/profile-001`；
- absolute deadline 从 runner 启动时建立，remaining 为 2607.344933 s；prior wall 92.655067 s 未重置；
- aggregate target RSS 由 root descendants 与 dedicated-PGID union 去重求和；`/bin/ps` 不可用、PGID 不成立或 reap authority 丢失均 fail closed；
- 唯一 resource upper predicates 为累计 wall 达到 2700 s 或 target-tree/cumulative peak 达到 3,221,225,472 B；未发现较低 RSS/wall、forecast、stall、reserve、grace 或 fit-quality stop；
- 只有 MATLAB natural zero exit、dedicated group 已验证且 `profile.json` 存在时才发布 `NATURAL_EXIT`；`resource.tsv` 使用 `O_EXCL` 最后发布。

最强实现反例是绕过 runner 直接调用 MATLAB，此时 `'w'` 不再拥有 runner 的 create-once 保护。因此唯一授权入口必须保持为 exact Perl runner；当前 source/runner 合同已经满足这一条件。

### Findings

- `BLOCKER`: 无。
- `IMPORTANT CAVEAT`: canonical candidate 3 与 candidate-7 identity component candidate 9 的区别必须在 post-run interpretation 中继续保留；当前 schema 已保留。
- `MINOR CAVEAT`: `FIT_RESOLVED` 只表示冻结数值优化成功，不验证幂律模型的渐近正确性；当前 claim boundary 已正确降级。
- `git diff --check` 对本轮 source/design 范围通过。

### Verdict

**PRE-EXECUTION PASS**

授权仅一次执行：

- cwd：`/Users/whc/Documents/Work/epost/test/i4/femref-a1`
- command：`/usr/bin/perl ./run_profile_postprocess.pl`

该命令必须使用 `require_escalated`／unsandboxed context，以保证完整 `/bin/ps` process-table authority。不得直接运行 `profile_postprocess`，不得 retry、换 profile ID、新增 FEM solve 或执行 estimator/effectivity。

运行后必须由同一 Skeptic 审查 `profile.json`、`resource.tsv`、七-start fit ledger、direct quantities、late-BIE boolean、预算和 claim boundary，审查通过前不得同步研究结论。
## BT. `profile-001` post-run artifact/resource/claim review

### Artifact integrity

`profile-001` leaf 恰含两个 create-once terminal files：

- `profile.json`：3070 B
- `resource.tsv`：277 B

无 partial、temporary 或附加工件。JSON 可完整解析并给出：

- `schema_version=i4a-candidate7-profile-v1`
- `profile_id=profile-001`
- `terminal=PROFILE_POSTPROCESS_COMPLETE`

Candidate labels 保持正确：

- old identity target：candidate 7
- new identity component：candidate 9
- canonical pure-FEM winner：candidate 3

因此本结果是 candidate-7-specific profile，未改写 canonical selection。

### Direct quantities

独立按冻结 literals 重算后与 artifact 完全一致：

$$
\begin{aligned}
d_{12\to18}&=-0.0052814302919568235,\\
d_{18\to24}&=-0.001979901415371188,\\
d_{24\to30}&=-0.0009584126670008075,
\end{aligned}
$$

$$
\rho_1=0.37487977799998845,\qquad
\rho_2=0.4840709035106812.
$$

预注册样本外预测残差为

$$
r_{\mathrm{pred}}
=k_{30}^{(7)}-k_{30}^{\mathrm{pred}}
=4.794533798202494\times10^{-6},
$$

其绝对值相同。上述量只能解释为 observed drift/prediction diagnostics，不能单独证明渐近收敛或形成 certified error bound。

### Seven-start fit audit

七个 endpoints 均为 finite/full-rank。Exit flags 为

`[1, 1, 1, 0, 1, 1, 1]`。

Start 4 的 warning/`exitflag=0` 已透明保留，但它不是 lexicographic winner。按冻结 `(SSE,p,start_index)` 顺序独立核验，winner 确为 start 6，且 `exitflag=1`：

$$
p=1.8129679837413033,
$$

$$
k_\infty=1.8327935034213265,\qquad
C=0.9181205139250015,
$$

$$
\mathrm{SSE}=4.302174060684754\times10^{-12}.
$$

由每个 endpoint 的 $(p,k_\infty,C)$ 重新计算 SSE 均与 ledger 一致。七个 starts 的 parameter spread 很小：

- $p\in[1.8129679692436007,1.8129680080939325]$；
- $k_\infty\in[1.8327935033833178,1.832793503485172]$；
- $C\in[0.9181204840353469,0.9181205641324178]$。

因此 `fit_status=FIT_RESOLVED` 符合冻结规则。Start 4 的非正 exitflag 是已记录的非 winner caveat，不构成 retry 或 fit failure。

### Late-BIE comparison and claim boundary

冻结 positional comparison 给出

$$
|k_{30}^{(7)}-k_{\mathrm{BIE}}|
=0.0019513090256411125
<0.0029097217,
$$

故 `strictly_less_than_old_distance=true` 正确。

Artifact 同时明确：

- `certification_status=EMPIRICAL_NON_CERTIFIED`
- `effectivity_performed=false`

该 boolean 只表示冻结位置差严格小于预注册旧距离；不能解释为 BIE mode selection、reference error upper bound、continuous eigenvalue existence 或 effectivity validation。

### Resource audit

$$
92.655067+17.400782=110.055849\ \mathrm{s},
$$

与 cumulative ledger 完全一致。Profile peak RSS 为 825,491,456 B，故累计 peak 为

$$
\max(1,073,594,368,\ 825,491,456)
=1,073,594,368\ \mathrm{B}.
$$

累计 wall 和 peak 分别低于 2700 s 与 3,221,225,472 B。Controller 为 `NATURAL_EXIT`，MATLAB exit 0、signal 0；无 operational 或 resource failure。

### Findings

1. **IMPORTANT CAVEAT — candidate-specific interpretation.**
   Profile 属于由 field identity 支持的 new candidate 9，而 canonical pure-FEM winner 仍为 candidate 3。同步时必须保留这一差别。

2. **MINOR CAVEAT — one non-winning optimizer warning.**
   Start 4 的 `exitflag=0` 不影响 start 6 的有效 lexicographic winner，但七-start ledger和该 warning 应保留，不得概括为“所有 starts 均正常收敛”。

3. **MINOR CAVEAT — empirical fit only.**
   很小的 SSE 和跨 start 稳定性支持数值拟合可复现，但不验证幂律模型在连续极限中的正确性。

4. **BLOCKER：无。**

### Verdict

**POST-RUN PASS WITH CONDITIONS**

`profile-001` 已成功完成并消费，不应重跑或创建新 profile ID。

允许最小同步至 I4 README、项目 STATUS 和现有 test 文档：

- `profile-001` natural completion 与实际 wall/RSS；
- 三段 drifts、两个 ratios 和 prediction residual；
- `FIT_RESOLVED` 及 winner 的 $p,k_\infty,C,\mathrm{SSE}$；
- late-BIE strict positional boolean 为 true；
- candidate 7 $\to$ candidate 9 identity context及 canonical candidate 3 caveat；
- `EMPIRICAL_NON_CERTIFIED`、`effectivity_performed=false`。

不得同步为 certified reference、$\varepsilon_{\mathrm{ref}}$、连续特征值存在性证明或 effectivity validation；本审查也不授权新的数值运行。
