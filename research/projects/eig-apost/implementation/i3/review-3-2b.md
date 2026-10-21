# I3.2 同一试验场经验评价 cap 实验独立审查

## 审查结论

- Design ID：`I3.2-SAME-CERTIFICATE-EVALUATION-CAP-V1`
- 设计：[[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]]
- 条件性定理：[[research/projects/eig-apost/implementation/i3/review-3-2a|review-3-2a]]
- 正式 attempts：`ecap-a1`、`ecap-a2`，均已消费，禁止同 tag 重跑
- `ecap-a1`：`I3_2_EXECUTION_UNAVAILABLE`，有效 implementation failure
- `ecap-a2`：`I3_2_RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED`
- Engineer artifact verdict：`VALID RESOURCE-LIMITED NEGATIVE RESULT`
- Researcher post-run verdict：`PASS`
- Skeptic post-run verdict：`PASS`（高置信度）

`ecap-a2` 通过 immutable certificate identity，并完成冻结的 same-trial evaluation 阶段；它在
进入 cap、full-$P$ contraction、经验 $q$ 和名义区间之前，由实际 active-object memory
$664.47068214416504$ MiB 超过 $640$ MiB hard limit 而停止。因此本次结果不是经验 cap，不能
产生 `EMPIRICALLY_SUPPORTED_EVALUATION_CAP` 或 `EMPIRICAL_NOMINAL_TRANSFORM`。它保存的
actual-$\Delta T$、finite-image Bloch 和 analytic-kernel diagnostics 仍是有效负向证据。

本审查采用描述性、可复算的实验验证边界：只解释保存的 artifact，不把未到达的 cap、$q$、
interval 或严格定理实例化补写为结果。[[test/i3/e-cap/README|e-cap experiment index]]、冻结设计、
MATLAB 源码、staged input 和两个 append-only output 均不在本次文档收尾中修改。

## 1. 冻结对象与 NO_RESOLVE 边界

实验只读消费由 `fbie-a1` 冻结的 finite certificate：saved candidate、geometry/material/branch、
$P_\pm,c_\pm,D_\pm,G_\pm$、circle density、wall density、shared traces 和 lift contract。它没有
重新求解 candidate、QZ、coordinate、propagation、wall density、circle density、Schur system
或 proxy chart。`M=48` 仍只定义 $K=97$ 个 QZ wall-input modes；wall density 固定为 512 个
coefficients，fresh wall outputs 使用 1024/2048/4096 modes。

`ecap-a2` 的 certificate identity record 为 pass，且
`mathematical_trial_redefined=false`。实际 `call_counters` 中八类 forbidden solves/builds 全为零：

- candidate、QZ、coordinate、propagation solves：各 0；
- wall-density、circle-density、Schur solves 与 proxy builds：各 0。

这说明已到达的 evaluation 是同一个 certificate/trial 的固定-density 重评价，不是重新拟合或
重新选候选。它仍是 same-chain ordinary-double diagnostic，不是独立 reference。

## 2. `ecap-a1`：实现失败

`ecap-a1` 在任何科学评价前停止。保存的 machine 状态为
`I3_2_EXECUTION_UNAVAILABLE / UNAVAILABLE`，首个 execution blocker 为
`MATLAB:mixedClasses`：

```text
Integers can only be combined with integers of the same class, or scalar doubles.
```

位置是冻结 a1 `check_e_cap.m` 的 `LOCAL_identity:378`。保存 result 时 elapsed 为
$0.038080041666666668$ s，peak active memory 为 $44.56219482421875$ MiB；所有 call counters
为零。该 result 保存之后，report publication 又因冻结 `LOCAL_report:872` 使用 MATLAB 不支持的
`fopen(path,'x')` 而得到 `Invalid permission.`，shell exit code 为 1，所以 a1 report 不存在。

这是同一 attempt 内按顺序发生的两个 implementation events，不是两次运行。`ecap-a1` 没有
same-trial evaluation、cap、$q$ 或 interval；不得重跑或用 `ecap-a2` 的科学诊断追溯改写它。

## 3. `ecap-a2`：运行与资源首败

Revision E 只把 staged integer storage 显式验证并转换为 double arithmetic，修复 a1 的
implementation blocker；它没有改变科学 levels、阈值、kernel、certificate 或 cap 公式。正式
命令已消费：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','e-cap')); check_e_cap('ecap-a2',fullfile(pwd,'test','i3','e-cap','input','fbie-a1-certificate.mat'));"
```

shell exit code 为 0，`retry_count=0`，`prior_failed_attempt_count=1`。preflight 估计为
$1320$ s、$407.26230335235596$ MiB，并通过冻结的 $1500$ s、$520$ MiB preflight stop。实际：

| 资源对象 | 保存值 |
|---|---:|
| elapsed | $373.24243479166665$ s |
| evaluation helper-local peak | $312.38566112518311$ MiB |
| retained before evaluation | $47.26230335235596$ MiB |
| retained after evaluation / active peak | $664.47068214416504$ MiB |
| hard memory limit | $640$ MiB |
| soft/hard time limits | $1500/1800$ s |

elapsed 没有触发 time limit，`soft_time_exceeded=false`；唯一 execution blocker 是
`RESOURCE_LIMIT_EXCEEDED`。memory gate 位于 completed evaluation 与 cap stage 之间，所以
`retained_before_cap`、`retained_after_cap` 为 unavailable，cap helper peak 为 0。

## 4. 实际到达的计算覆盖

尽管 top-level status 因资源门为 unavailable，保存的 `evaluation.record` 证明以下对象已经到达：

- `core_maps_available=true`、`same_trial_evaluation_available=true`；
- 7 个 symmetric-image checkpoints：$32,48,64,96,128,192,256$；
- 3 个 circle angular levels：$512,1024,2048$；
- 3 个 wall output levels：$1024,2048,4096$；
- Riccati levels $512,1024,2048$ 与 radial Gauss levels $32,64,128$；
- 所有已计算 circle/wall modes 均保留；未计算 tail 没有 enclosure；
- conformity qualification 通过。

相应 authoritative `call_counters` 为：harmonic actions 4、image-pair updates 512、Kress oracle 1、
actual-$\Delta T$ actions 10、finite-image Bloch updates 1024、Riccati calls 6、Gauss-factor calls 6；
full-$P$ contraction calls 为 0。最后一项与 cap 未开始一致。

### 4.1 早停后的 schema caveat

producer 只在 cap 成功路径把部分 top-level summary 从 evaluation 回填。因此本 artifact 中：

- `coverage` 全为 false；
- `no_resolve_call_counts` 保留初始化的全零；
- `first_empirical_unavailable` 和 `first_nonblocking_warning` 都保留 `NOT_REACHED`；
- `unresolved_axes={'NOT_REACHED'}`；
- 但 `evaluation.record.core_maps_available=true`，且 `nonblocking_warnings` 有 3 项。

这些默认 summary 不得被解释为 evaluation 未执行。到达范围以 `evaluation.record` 和
`call_counters` 为权威；禁止求解的计数也从 `call_counters` 的八个 solve/build fields 判定。
另一方面，`components`、`caps`、`estimator`、`tails`、`axis_metrics` 和 `arithmetic` 均为空，
准确说明 cap/full-$P$/$q$/interval 未到达。

## 5. 三项资格失败

资源首败先决定本 attempt 的正式 status。以下三项 nonblocking warnings 是已完成 evaluation
留下的额外诊断；即使没有资源首败，冻结 design 第 4.3、6、9 节和 consumed code 也会令相应
empirical cap unresolved。这里的 fail-open 只表示继续保存 raw evaluation levels 和 warnings，
不是继续形成 cap、$q$ 或 nominal transform。

设计第 8 节另有一句把 fail-open 概括成继续计算 $q$，与上述 component rules、failure lattice
和实际 `numerator_available` gate 不一致。本审查按更具体条款与 consumed code 解释，并把该
措辞冲突记为 design caveat；由于资源门先发生，这个 counterfactual cap gate 本次没有实际到达。

### 5.1 Actual fixed-density $\Delta T$ action

实际对象是

$$
\Delta T\tau
=\partial_r(D_{mathrm o}^{QP}\tau)
-\partial_r(D_{mathrm i}\tau),
$$

采用 global $+r$ 和 exterior-minus-interior 方向，并与完整 circle residual 分解分开保存。
dyadic image contraction 通过，但 staggered image contraction 未通过：最大 ratio 为
$2.2946515117026931>0.80$。angular $512/1024/2048$ comparison 通过；失败来自 image ladder，
不是 circle source density 被重新求解。

### 5.2 Finite-image physical Bloch action

同一 fixed $\eta/\xi$ 的 finite-image production action 在 paired top/bottom safe targets 上检查
physical Bloch value 和 global-$y$ derivative。最终 $J=256$ 最大 ratio 为
$0.071741947137921119>10^{-10}$；其中 value ratio 为同一最大值，flux ratio 为
$0.049201004541568526$。这不否定 exact continuous QP kernel 的结构 Bloch identity；它说明
有限 symmetric-image action 没有达到冻结资格门。

### 5.3 Analytic kernel oracle

aggregate warning 为 `ANALYTIC_KERNEL_ORACLE_WARNING=Inf`。其三个保存的子诊断均未通过
$10^{-8}$ 门：

- free singular/Kress oracle 最大 relative defect：$0.60886670048489133$；
- Linton off-axis oracle：unavailable，message 为 `Input must be real and full.`；
- high-order recurrence 最大 defect：$6.4223017627510662\times10^{-8}$。

该 aggregate 是一项 qualification failure，不应把三个子诊断误写成三个额外正式 warnings。
历史 `fbie-a1` circle-action ratio $0.77408786032496468$ 只保留为 background；outside-$M$ share
$0.036178900402764308$ 仍是描述性量，所有 512 个已计算 circle modes 已进入历史 $q$。

## 6. 未到达的 cap、$q$ 与区间

本 run 没有形成 wall/circle/volume component cap，没有形成 empirical $\epsilon_M$ 或
$\epsilon_N$，也没有运行 full-$P$ $8/16/32$ contraction。因而下式没有 numerical instance：

$$
q_{\mathrm{emp}}
=\frac{\widetilde M_h+\epsilon_M^{\mathrm{emp}}}
{\sqrt{\widetilde N_h-\epsilon_N^{\mathrm{emp}}}}.
$$

保存的 ordinary anchor
$\widetilde M_h=2.29786516751043\times10^{-10}$、
$\widetilde N_h=4.959111810675795$ 仍只是 `fbie-a1` 中心值；不得把它们单独代入后称为本轮 cap
或 interval。全部 rigorous/reliable flags 为 false：没有 strict cap、residual upper enclosure、
field lower enclosure、image/Fourier tail enclosure、directed arithmetic、same-operator certified
gap、certified spectral interval、eigenvalue existence、independent reference 或 effectivity
validation。

## 7. 当前里程碑解释

本结果不撤销 [[research/projects/eig-apost/implementation/i3/review-3-2a|I3.2 conditional
theorem]]。当前 I3.2 同时包含：已经建立的条件性定理，以及固定同一 trial 的 empirical
evaluation-cap application；后者现为 `EMPIRICAL_CAP_UNRESOLVED`。资源硬门是实际到达的首个
execution blocker；已保存的三项资格失败则表明，即使资源门关闭，按 consumed cap gates 仍不会
形成 empirical cap。

I3.3 只保留 independent reference 和 effectivity validation；same-trial nested evaluation 不是
independent reference，不能因为它已运行就说 I3.3 开始或通过。I3.4 仍专门负责 strict outward
residual/field/tail enclosure、same-operator certified gap、resolution 和离散特征值存在性。
`ecap-a2` 的任何 ordinary diagnostic 都不能触发 I3.2 strict theorem、I3.3 effectivity 或 I3.4
existence claim。

2026-08-24 以前以及本轮 remap 前形成的 historical design、review、attempt tag 和 append-only
artifact 保留其原编号与时态；本审查只同步 current planning authority。

## 8. Artifact 与冻结快照

正式 artifact：

- `ecap-a1/result.mat`：
  `8dc98c1d830d92e2d5885a1e38dda6205cf5673ad7919034c951685a2f88490f`，115936 bytes；
  `ecap-a1/report.md` absent；
- `ecap-a2/result.mat`：
  `711ca45666f452f091912f51e832c5a45a2ea70cd380a4a23db4c2128bd6d97b`，193695534 bytes；
- `ecap-a2/report.md`：
  `dec38ef250ac47294d573c5f58ea76871f5dfdd1dc69451723874da0664c9d6d`，1797 bytes。

运行所消费的冻结 scientific snapshot：

- design：`f2c6306eae7ff7de219818cc7f7f8a302d51eccbc56903c351d85521ba938837`；
- entry：`0a36d26afe4993f315002fd666ea30ddc784b264afdc3d8261887b0550099100`；
- evaluator helper：`7b299c424f663dab7ac6eb857d11bd6db404993421483f9dd8810f6b7567df40`；
- cap/tail helper：`2f7ea8b211a67c86453645bfac653e6054298cfb3e05b7d443cc5cf0c7572b26`；
- staged input：`bb502ed97bfda5d60bd653fcb9e75f67fe15e86e053e160750ed5a735280e1b3`。

两个 attempts 都是 append-only consumed history。下一步若要解决资源或 evaluator diagnostics，
必须另行设计新 attempt；不得改变 `ecap-a1`、`ecap-a2`、staged input、冻结源码、设计或 amendment。

## ecap-a3 design amendment: 2 GiB resource variant

本小节记录用户对尚未消费的 `ecap-a3` 预注册语义的明确覆盖。`ecap-a3` 直接采用旧版
Revision E 的 `check_e_cap.m`、`i32_same_eval.m`、`i32_cap_tail.m` 与冻结的
`fbie-a1-certificate.mat`；不采用未完成的 modular REV_F 路线。

相对于已运行的 `ecap-a2`，唯一资源变化是 hard active-object memory gate 从 640 MiB 提高到
2048 MiB。attempt、command 和 output tag 同步为 `ecap-a3`，provenance 标记为
`REVISION_E_2GIB_RESOURCE_VARIANT`，prior-attempt ledger 同时保留已消费的 `ecap-a1` 与
`ecap-a2`。certificate、trial、levels、阈值、ordinary-double 公式、actual-$\Delta T$、Bloch、
kernel-oracle 与 cap gates、1500/1800 s 时间门以及全部 reliability flags 均保持不变。

授权的唯一命令是：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','e-cap')); check_e_cap('ecap-a3',fullfile(pwd,'test','i3','e-cap','input','fbie-a1-certificate.mat'));"
```

创建 `output/ecap-a3` 即消费 tag；无论成功或失败都不得 retry、覆盖或补写。结果统一标记为
`REVISION E 2 GiB RESOURCE VARIANT / EMPIRICAL / UNQUALIFIED`。该变体只放宽执行资源门，不改变
科学方法，也不产生 strict upper bound、reliable/certified interval、gap certificate 或谱存在性结论。

## ecap-a3 review: 2 GiB resource-variant result

统一结果标记：`REVISION E 2 GiB RESOURCE VARIANT / EMPIRICAL / UNQUALIFIED`。

唯一授权命令于 2026-08-25 执行一次。MATLAB 在进入实验入口并创建 append-only output 之前发生
fatal exit，shell exit code 为 137；launcher 观测 wall time 约为 0.6 s。终端只给出 MATLAB fatal
error，并报告无法写入 on-disk crash report：`Operation not permitted`。未重试、未覆盖、未补写。

运行后只读检查结果如下：

| 项目 | 保存结果 |
|---|---|
| status | `MATLAB_FATAL_EXIT_137 / NO_ARTIFACT` |
| elapsed | launcher wall time 约 0.6 s；MATLAB scientific elapsed unavailable |
| active-object memory peak | `NOT_REACHED / UNAVAILABLE` |
| $\epsilon_{\mathrm w}^{\rm emp}$ | `NOT_REACHED` |
| $\epsilon_{\Gamma}^{\rm emp}$ | `NOT_REACHED` |
| $\epsilon_{\mathrm{vol}}^{\rm emp}$ | `NOT_REACHED` |
| $\epsilon_P^{\rm emp}$ | `NOT_REACHED` |
| $\epsilon_M^{\rm emp}$ | `NOT_REACHED` |
| field lower 与 $\epsilon_N^{\rm emp}$ | `NOT_REACHED` |
| $q_{\rm emp}$ | `NOT_REACHED` |
| nominal interval / width | `NOT_REACHED / NOT_REACHED` |
| scientific gates | `NOT_REACHED` |
| `result.mat` / `report.md` | absent / absent |
| `output/ecap-a3` | absent |

首个 blocker 是 MATLAB process fatal exit 137，早于 certificate identity、evaluation、cap、full-$P$
contraction、field lower、$q_{\rm emp}$ 与 interval。无法写 crash report 是同一启动失败之后的次级
host diagnostic，不替代首个 blocker。全部 empirical cap、field 与 gate 状态 unresolved；没有可从
`result.mat` 或 `report.md` 提取的数值 warning。

由于 output 目录未创建，目录层面的 tag-consumption event 没有发生；但本 amendment 同时规定
success 或 failure 均不得 retry。因此本次唯一 invocation 已终结，`ecap-a3` 必须视为 retired，
不得因目录缺失而再次运行或复用。

本次没有实例化任何 reliability flag。严格/可靠解释全部保持 false：没有 residual upper enclosure、
field lower enclosure、tail enclosure、directed arithmetic、certified gap、reliable/certified interval、
离散特征值存在性、independent reference 或 effectivity validation。该结果只是一项未到达科学入口的
Revision E 2 GiB host-execution failure。

## ecap-a3 final override and artifact: Revision E 2 GiB resource variant

本小节由后续用户指令授权，明确覆盖上节的 no-retry、retired 与目录消费解释。`ecap-a3` 在本轮
允许清理精确 output 目录、覆写和重复运行，完成条件改为生成可读取的 `result.mat` 与
`report.md`。先前两次通过 PATH launcher 的 invocation 均在进入 MATLAB entry 前 fatal exit 137；
随后只读诊断确认同一 MATLAB 二进制及 staged certificate 可正常启动和载入。改用
`command -v matlab` 解析出的同一二进制绝对路径后，完全相同的 batch expression 成功完成并发布
两个 artifact。没有使用或修改 modular REV_F 实现。

统一结果标记：`REVISION E 2 GiB RESOURCE VARIANT / EMPIRICAL / UNQUALIFIED`。

### 最终状态与资源

| 项目 | 最终保存值 |
|---|---:|
| status | `I3_2_EMPIRICAL_CAP_UNRESOLVED` |
| scientific outcome / cap status | `EMPIRICAL_CAP_UNRESOLVED` / `EMPIRICAL_CAP_UNRESOLVED` |
| MATLAB elapsed | $445.57999270833335$ s |
| active-object peak | $1024.470682144165$ MiB |
| evaluation / cap helper-local peak | $312.39013195037842$ / $360$ MiB |
| retained before / after cap | $664.47068214416504$ / $678.50803852081299$ MiB |
| hard memory / soft-hard time gates | $2048$ MiB / $1500$--$1800$ s |
| hard limits respected | true |

preflight 仍使用冻结的 520 MiB preflight gate；估计为 1320 s 与
$407.26230335235596$ MiB，并通过。2 GiB 变化只作用于运行时 hard active-object memory gate。

### Empirical caps、field lower 与 nominal transform

| 对象 | 最终保存值 |
|---|---:|
| $\widetilde M_h$ | $2.29786516751043\times10^{-10}$ |
| $\widetilde N_h$ | $4.959111810675795$ |
| finite wall component candidate | $1.58959164244813\times10^{-15}$ |
| official $\epsilon_{\mathrm w}^{\rm emp}$ | `NaN` |
| $\epsilon_{\Gamma}^{\rm emp}$ | `NaN` |
| $\epsilon_{\mathrm{vol}}^{\rm emp}$ | `NaN` |
| $\epsilon_M^{\rm emp}$ | `NaN` |
| $\epsilon_N^{\rm emp}$ | $2.4886735830058964\times10^{-8}$ |
| squared field-lower candidate $\widetilde N_h-\epsilon_N^{\rm emp}$ | $4.9591117857890588$ |
| norm field-lower candidate | $2.226906326226826$ |
| $q_{\rm emp}$ | `NaN` |
| nominal $k$ interval / width | `[NaN, NaN]` / `NaN` |

wall component 自身 available，但冻结 Revision E 只有在完整 numerator qualification 成立时才发布
official component caps；因此 official $\epsilon_{\mathrm w}^{\rm emp}$ 仍与其余 numerator caps 一起
保存为 `NaN`。denominator cap 已完成，numerator cap 与 nominal transform 未完成。

### Gates、warnings 与 unresolved 项

- certificate identity、same-trial evaluation、conformity：pass；
- kernel oracle、actual-$\Delta T$ action、finite-image Bloch、empirical-cap support：fail；
- actual-$\Delta T$ 最大 contraction ratio：$2.2946515117026931$；
- finite-image physical Bloch final ratio：$0.071741947137921119$；
- full-$P$ contraction sequences：292；actual-$\Delta T$ actions：10；finite-Bloch image updates：1024；
- 八类 forbidden solve/build counters：全部为零；所有 fresh computed modes 已纳入。

nonblocking warnings 为：

- `ACTUAL_DELTA_T_ACTION_WARNING = 2.2946515117026931`；
- `FINITE_IMAGE_BLOCH_ACTION_WARNING = 0.071741947137921119`；
- `ANALYTIC_KERNEL_ORACLE_WARNING = Inf`；
- `IMAGE_TAIL_EMPIRICALLY_UNRESOLVED = 2.5456623549227015`。

unresolved axes 为 `image_circle`、`shell_circle_circle`、`shell_circle_volume`、
`actual_DeltaT_action` 与 `finite_image_Bloch`。execution blocker 为 `NONE`；首个真正阻止完整
empirical cap 的 scientific condition 是 `KERNEL_ORACLE_UNAVAILABLE`：required analytic kernel
oracle numerically unavailable。

两个最终 artifact 均已由 MATLAB 只读载入或文本读取验证。该结果是 same-chain ordinary-double
empirical diagnostic；所有 rigorous/reliable/certified、outward enclosure、field enclosure、tail
enclosure、gap、spectral existence、independent-reference 与 effectivity flags 均为 false。即使存在
finite field-lower candidate，也不得解释为可靠下界；本轮没有 nominal interval 或谱存在性结论。
