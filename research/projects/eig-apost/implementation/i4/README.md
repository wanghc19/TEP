# I4：独立 effectivity validation 与可靠 enclosure/gap

## 当前状态

I4 是未来阶段，当前状态为 `FUTURE / NOT STARTED`。原 I3.3 已迁移为 I4.1，原 I3.4 已迁移
为 I4.2；两项工作的科学问题、输入、输出和结论边界均保持不变。本目录目前只包含阶段级
README，不含 design、review、experiment、代码或 output，也不授权启动任何 I4 研究或实验。

I4 接收 I3.1 的 estimator candidate、I3.2 已建立的条件性证书定理，以及 same-trial
`ecap-a2` 已保存的资源首败和 qualification diagnostics。I4 不追溯改写 I3 的历史设计、审查、
实验产物或 verdict。

## 阶段定位

I4 回答两个相互独立的下游问题：

1. 冻结的经验 estimator 能否在独立方法/reference 上正确反映真值误差量级；
2. 能否用经证明覆盖的 residual/field norms、numerical enclosure、continuous projected gap
   和预注册分辨率形成不含未知常数的可靠存在性或误差上界。

I4.1 的经验验证不是 I4.2 严格上界的逻辑前提；I4.2 的失败也不追溯撤销 I4.1 在其经验结论
强度内可能成立的结果。反之，observed effectivity 不能替代 I4.2 的可靠 norm enclosure、gap
qualification 或分辨率门。

## I4 内部里程碑

| Milestone | 独立科学问题 | 核心输出 | 当前状态 |
|---|---|---|---|
| I4.1 独立方法/reference 的 effectivity validation | 冻结 estimator/candidate 能否在未参与构造的独立方法/reference 上跟踪真实误差量级？ | independent-reference/effectivity verdict；失败时保留较弱 indicator | `FUTURE / NOT STARTED` |
| I4.2 可靠 enclosure、gap 与可计算误差上界 | 能否由已证明覆盖的 residual/field norms、numerical enclosure、continuous projected gap 和预注册分辨率得到不含未知常数的 existence-distance 上界；必要时再升级唯一目标？ | reliable interval、离散存在性、$U_h$、`EXISTS_BUT_RESOLUTION_INSUFFICIENT` 或 `UPPER_BOUND_UNAVAILABLE` | `FUTURE / NOT STARTED` |

## 从 I3 接收的输入

- I3 已定义的 $\widehat k_h$、$G_\lambda$、$\mathcal K_{\mathrm{disc}}(A;G_\lambda)$、
  $e_h^{\mathrm{gap}}$ 与可选 $e_h^*$；I4 不另建第二套记号；
- I3.1 冻结的 estimator candidate、candidate、覆盖/忽略项、内部资格状态和适用失败条件；
- I3.2 已建立的 strict residual/field caps 蕴含 continuous spectral intersection 的条件性定理；
- I3.2 same-trial `ecap-a2` 保存的 identity/evaluation、资源首败和三项 fail-open qualification
  diagnostics；这些 ordinary same-chain 证据不是 independent reference 或 strict cap；
- I2 的 mode identity、candidate sequence 和零 observed shift 的信息边界；
- 当前项目的 continuous operator、projected-gap 和 open-problem ledger。

## I4.1：独立方法/reference 的 effectivity validation

### 科学问题

在不再改变 I3.1 estimator/candidate 或 I3.2 same-trial evaluation contract 的前提下，能否用
真正未参与构造、调参或阈值选择的 independent method/reference，检验 $\eta_h$ 是否跟踪 gap
内连续离散特征频率集合距离？只有 reference 还独立识别指定 mode 时，才验证 target-specific
$e_h^*$。

### 独立性的分界

I3.1 使用推导与内部自洽性；I3.2 可以使用同一 certificate 的 nested evaluation；I4.1 只使用
estimator/candidate 与 same-trial diagnostics 冻结后才取得或启用的外部独立证据。若 reference
参与公式选择、常数拟合或阈值调节，它就是 calibration data，不能再作为同一次独立验证。
`ecap-a2` 与 `fbie-a1` 共享 certificate、density 和 BIE/QZ chain，明确不属于 I4.1 reference。

当前问题没有解析解。I4.1 未来可按以下优先顺序研究 reference，但本阶段 README 不预先指定
具体算法：

1. 与当前 BIE/QZ 链不同的数值表述、离散方法或独立实现；
2. 两种或更多具有不同主要误差来源的方法给出的相容高精度结果；
3. 经原文核验、参数和归一化完全匹配、且给出足够复现信息的文献数据；
4. 同一方法的更高分辨率结果仅作带共享偏差的后备，不称 independent。

reference 自身必须有 uncertainty 说明。若 uncertainty 与 candidate-reference 差异同量级，
合法结果是 reference resolution 不足，而不是把 reference 当作真值。

### 输入与输出

输入是 I3.1 冻结的 $\eta_h$/candidate、I3.2 已保存的 same-trial diagnostics、I2 mode identity，
以及未参与构造的 independent method/reference 和其 uncertainty。输出只报告
independent-effectivity verdict：是否在多个合格层上保持正确量级、是否随误差共同变化、
reference uncertainty 是否足以解释比较。

只有通过外部检验后，$\eta_h$ 才可称 `empirical eigenvalue-error estimator`；失败时保留
indicator/candidate，并区分 estimator 无效、reference 不独立、reference uncertainty 过大或
未进入适用区间。I4.1 不生成 same-trial cap，也不等于严格误差上界。

## I4.2：可靠 enclosure、gap 与可计算误差上界

### 科学问题

对 I3.1 已冻结的 residual 对象，能否得到一个完全可计算的区间，先保证某个 continuous
projected-gap 离散特征频率存在，并满足

$$
\operatorname{dist}\bigl(
\widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)
\bigr)\leq U_h,
$$

且 $U_h$ 不含未知 norm constant、未计 numerical error 或凭经验选择的安全系数？

### 输入

- I3.1 冻结的 residual estimator candidate 及其覆盖/忽略项；
- 经证明的 residual dual-norm 上界、field-norm 下界和 numerical enclosure；
- 当前 sharp-disk continuous operator 的 projected essential gap、区间 containment 和在结果前
  冻结的可接受频率分辨率；
- 只有确需跟踪指定 mode 时，才额外输入 continuous spectral isolation/count；
- I4.1 的 independent-reference 结果若形成，只作经验交叉检查，不是严格上界的逻辑前提。

经验上观察到的 contraction ratio、effectivity 或同一 reference 的一致性不能替代 reliable
dual-norm/field-norm enclosure、continuous gap qualification 或预注册分辨率。

### 输出与结论边界

I4.2 的输出按强度分层：

- 给出所有量均可计算、假设逐项成立的 gap 内区间，并证明其中至少存在一个连续离散特征值；
  只有区间宽度不超过预注册尺度，才接受为分辨率级结果；
- 若另有连续谱隔离或计数，再把该特征值识别为指定 $k_*$ 并给出
  $|k_*-\widehat k_h|\le U_h$；若第一层已经成立而该附加条件缺失，则保留集合距离上界并输出
  `EXISTENCE_WITH_TARGET_UNRESOLVED`；或
- 若第一层所需的 residual-norm、field-norm、numerical enclosure 或 projected-gap 条件不能
  建立，则明确输出 `UPPER_BOUND_UNAVAILABLE`；若只缺分辨率门，则保留存在性并输出
  `EXISTS_BUT_RESOLUTION_INSUFFICIENT`。

`UPPER_BOUND_UNAVAILABLE` 是有效研究结论。它不撤销 I3.1 已完成的内部指标，也不撤销 I4.1
可能通过的 empirical estimator；同样，经验 estimator 通过也不得被改写成已证明上界。
I4.1 中一般的 empirical reference uncertainty 不能直接作为 $U_h$ 的组成项；只有当 reference
本身给出经证明覆盖 $k_*$ 的 enclosure 时，它才能进入严格上界。

## 授权边界

- I4.1 和 I4.2 均未启动；本 README 不是 design、review 或 experiment plan；
- 不在本阶段入口中预先冻结算法、参数、阈值、reference、数值层级或实验命令；
- 任何 I4 工作都必须另行获得授权，再按顺序形成 design、独立 review 和实验入口；
- 不得把 I3 的 ordinary interval、same-trial cap diagnostics、经验 effectivity 或历史 gap 当作
  I4.2 的 strict enclosure；
- 不得追溯修改 I3 design、review、代码、output、证书或结论。

## 推荐阅读顺序

1. [[research/projects/eig-apost/implementation/i3/README|I3 guide]]：确认 I3.1/I3.2 状态和
   I4 handoff；
2. [[research/projects/eig-apost/implementation/ROADMAP|implementation roadmap]]：确认 I1--I4
   的项目级依赖；
3. [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]：确认 I4.1
   独立性 caveat 与 I4.2 enclosure/gap blockers；
4. [[research/projects/eig-apost/phase4-report/method.tex|continuous method]]：确认连续谱对象和
   claim boundary。
