# I4.1a 独立 FEM supercell reference 审查

状态：`POST-RUN REVIEW COMPLETE / PASS (VALID SCIENTIFIC NEGATIVE) / M1 FAILED / ATTEMPT CONSUMED / NO FURTHER RUN AUTHORIZED`

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
