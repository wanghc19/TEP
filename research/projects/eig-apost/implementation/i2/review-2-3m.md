# I2.3 M-axis saved-candidate drift 跑后审查

## 1. 审查对象与结论

- Design ID: `I2.3-M-DRIFT-V1`
- Scientific axis: `PORT_RAYLEIGH_FOURIER_CUTOFF_M_AT_FIXED_NTOT160_FINE_PROXY`
- Consumed failed attempt: `m-drift-a1`
- Formal successful attempt: `m-drift-a2`
- Artifact verdict: `PASS WITH CONDITIONS`
- Scientific outcome: `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`
- Hierarchy: `CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY`
- I3 gate: `MAY PROCEED WITH CONDITIONS`
- Review date: `2026-08-14`

本审查以 [[research/projects/eig-apost/implementation/i2/design-2-3m|M-axis frozen design]]
为预注册合同，只接受 [[test/i2/m-drift/README|M-axis experiment index]] 作为实验统一入口。
append-only 数值 artifact、runner 和冻结设计均不作追溯修改。本文件独立解释保存的数值证据，
但不据此推定未记录的 Skeptic 身份或签字。

最终 verdict 为 `PASS WITH CONDITIONS`。三个 $M$ levels 均得到通过最低门的 saved candidate，
两项相邻 mode identity 均为 `SAME_MODE`，所有直接 candidate drift 均为零，且 gauge、repeat、
resource 与最低健康门通过。因此形成 conditional algorithmic M-axis hierarchy，I3 可以接收该
hierarchy 并开始误差来源与 independent-reference 设计。

该 verdict 不证明 sub-grid minimizer、finite-dimensional exact root、continuous guided mode、
收敛阶、estimator 或误差上界。

## 2. 唯一轴与验收问题

本实验固定边界 Nyström 阶数 $n_{\mathrm{tot}}=160$，只改变人工边界
Rayleigh/Fourier cutoff：

$$
M\in\{32,40,48\},
\qquad
K=2M+1\in\{65,81,97\}.
$$

固定 fine proxy tuple 为

$$
(N_{\mathrm{side}},N_{\mathrm{top}},N_{\mathrm{proxy\ edge}},M_{\mathrm{pw}})
=(160,160,80,32).
$$

物理、几何、precision、solver、branch convention、窗口、五点 dyadic locator、candidate
functional、winner rule 和所有非 $K$-派生阈值保持不变。$M$ 改变引起的 Fourier basis、
port anchor、QZ frame、weights 和矩阵维数变化，都是该单一 cutoff axis 的派生结果；本审查
不把 observed drift 单独归因于其中某一内部部件。

跑后验收回答以下问题：

1. 三个 levels 是否各自得到可用 saved candidate；
2. gauge、raw residual、factor、field、boundary 与 repeat 门是否通过；
3. 三种公共表示是否把相邻 candidates 识别为同一数值 mode；
4. 保存的 candidate 是否出现直接漂移，是否超过预注册 $10^{-6}$ severe scale；
5. 是否形成 conditional hierarchy，以及 I3 可以接收什么、不能接收什么。

## 3. Attempt 历史与执行完整性

### 3.1 消耗的 `m-drift-a1`

`m-drift-a1` 在 configuration preflight 失败。wall time 为 `22.177848167 s`，exit code 为
`1`，evaluator-call count 为零，且未创建 output directory 或 artifact。终端错误为：

```text
Subscripted assignment between dissimilar structures.
```

stack 指向 `LOCAL_config` line 199 / `check_m_drift` line 32；error identifier 未记录。根因是
fieldless `struct([])` 接收 whole-element fielded struct。Revision A 只将其替换为同字段
$1\times3$ struct preallocation；未改变任何科学字段、阈值、窗口或算法。`m-drift-a1` 已消费，
没有以同 tag 重试，也没有补造历史 artifact。

### 3.2 正式 `m-drift-a2`

`m-drift-a2` 正常 exit 0，正式 attempt 自身 `retry_count=0`，first failure 为 `NONE / NONE`。
三层各完成 27 个唯一 locator nodes，包括各自的 seed，随后各做一次 terminal repeat，总计
84 次 evaluator calls。没有换 $M$、移动窗口、改阈值、改 selector 或改 locator。

实际 wall time 为 `171.956 s`，低于 `600 s` soft target 和 `1200 s` hard gate；peak
active-object snapshot 为 `148.171 MiB`，低于 `512 MiB` gate。该 peak 不是操作系统 RSS。

## 4. 三层 saved candidates

| $M$ | $K$ | locator | saved candidate $\widehat k_M$ | minimizer-search half-width | $s_1$ | $r_{12}$ | runner-up gap | repeat |
|---:|---:|---|---:|---:|---:|---:|---:|---|
| 32 | 65 | `PASS` | 1.832770289108157 | $9.31323\times10^{-11}$ | $5.65537\times10^{-11}$ | $1.10512\times10^{-10}$ | $1.94683\times10^{-11}$ | `PASS` |
| 40 | 81 | `PASS` | 1.832770289108157 | $9.31323\times10^{-11}$ | $5.65532\times10^{-11}$ | $1.10511\times10^{-10}$ | $1.94692\times10^{-11}$ | `PASS` |
| 48 | 97 | `PASS` | 1.832770289108157 | $9.31323\times10^{-11}$ | $5.65526\times10^{-11}$ | $1.10510\times10^{-10}$ | $1.94703\times10^{-11}$ | `PASS` |

每层完成固定 $L=0,\ldots,11$ locator，terminal winner 严格位于内部，runner-up gap 均大于
$10^{-12}$ tie band。$s_1\ll10^{-3}$ 且 $r_{12}\ll0.1$。三次 fixed-candidate repeat 均通过
matrix、score、balanced-port overlap 和 factor/signature 门。

保存对象是 terminal-grid winner $\widehat k_M$。表中的 half-width 只描述未计算的连续-$k$
score minimizer 的 search-resolution scale；它不是 $\widehat k_M$ 的 uncertainty，不参与
candidate drift，也不证明 winner ranking 对未建模 score 扰动稳定。

## 5. Selector gauge 与共同表示

production 使用 natural top/bottom halves。每个 $M$ 又在同一 raw seed QZ basis 上，以
filtered/remapped frozen-$M=48$ selector order 重做一次 alternate gauge，不增加 evaluator call。

| $M$ | gauge | $A_{\mathrm{def}}^D$ relative Frobenius difference | $s_1$ difference | raw $q$ overlap | wall overlap | probe overlap |
|---:|---|---:|---:|---:|---:|---:|
| 32 | `PASS` | $4.77728\times10^{-17}$ | $2.02283\times10^{-16}$ | 1 | 1 | 1 |
| 40 | `PASS` | $4.32494\times10^{-17}$ | $1.70403\times10^{-16}$ | 1 | 1 | 1 |
| 48 | `PASS` | $2.13762\times10^{-17}$ | $1.03071\times10^{-16}$ | 1 | 1 | 1 |

三层 alternate fixed-row 与 Dirichlet factors 均通过。结果远低于冻结的 $10^{-12}$ matrix/score
门，三个 phase/scale-invariant overlaps 也超过 $1-10^{-10}$。没有观察到 row ordering 制造的
伪 $M$ drift。

共同 proxy shape、rank 和 fingerprint gate 通过。对共享 Fourier labels，所有实际公共 nodes
上的 $\beta_m$ 一致，最大 $\gamma_m$ difference 和 phase difference 均为零。因此跨 $M$ 的
balanced-port、weighted-wall 和 probe comparison 在预注册公共表示中可用。

## 6. Candidate health

| $M$ | raw right / left residual | raw right / left backward | SVD triplet | factors | center / graph | Dirichlet / Neumann defect | kernel defect |
|---:|---:|---:|---:|---|---:|---:|---:|
| 32 | $1.59\times10^{-10}$ / $2.97\times10^{-10}$ | $7.8\times10^{-13}$ / $7.8\times10^{-13}$ | $3.35\times10^{-16}$ | `PASS` | $0.707$ / $0.5$ | $5.15\times10^{-17}$ / $1.61\times10^{-18}$ | $1.17\times10^{-13}$ |
| 40 | $1.59\times10^{-10}$ / $2.97\times10^{-10}$ | $6.25\times10^{-13}$ / $6.24\times10^{-13}$ | $2.97\times10^{-16}$ | `PASS` | $0.707$ / $0.5$ | $6.20\times10^{-17}$ / $3.73\times10^{-19}$ | $8.41\times10^{-14}$ |
| 48 | $1.59\times10^{-10}$ / $2.97\times10^{-10}$ | $5.21\times10^{-13}$ / $5.20\times10^{-13}$ | $5.57\times10^{-16}$ | `PASS` | $0.707$ / $0.5$ | $5.28\times10^{-17}$ / $7.32\times10^{-19}$ | $6.42\times10^{-14}$ |

raw backward errors 远低于 $10^{-8}$，SVD triplet residual 远低于各层 $10^3(2K)\epsilon_{\mathrm{mach}}$，
center/graph participation 远高于 $10^{-3}$，Dirichlet/Neumann defects 远低于 $10^{-10}$。
kernel defect 按预注册合同只记录，不追加结果导向门。

每个 candidate 的十项直接 factor rows 全部 available 且 pass。最紧 factor 是固定 proxy 的
`proxy_reduced`：

$$
\operatorname{rcond}=1.0481727488892215\times10^{-8},
\qquad
\operatorname{rcond}_{\min}=10^{-8}.
$$

其门槛比例约为 $1.04817$。它没有触发本次 failure，但余量有限，是必须保留的
`IMPORTANT CAVEAT`；未来参数、precision 或离散轴不能继承该 pass。

## 7. Mode identity

mode identity 使用共同空间中的 balanced physical coefficient $p=v_1$、weighted wall trace 和
九点 probe field，并以第二右奇异向量的双向 primary--secondary overlap 排除邻近 mode mixing。

| $M$ pair | status | balanced port | weighted wall | probe field | competitor maximum | hard gate |
|---|---|---:|---:|---:|---:|---:|
| 32--40 | `SAME_MODE` | 1 | 1 | 1 | $2.48842\times10^{-13}$ | yes |
| 40--48 | `SAME_MODE` | 1 | 1 | 1 | $2.48847\times10^{-13}$ | yes |
| 32--48 | `SAME_MODE` | 1 | 1 | 1 | $8.23004\times10^{-14}$ | diagnostic only |

两项相邻 primary overlaps 均超过 $0.99$，competitor maximum 远低于 $0.5$，secondary
representations 均可用。因此两项相邻关系按预注册规则为 `SAME_MODE`，没有按 candidate 数值
最近或跨维 raw vector 事后连接序列。$32$--$48$ comparison 与相邻结果一致，但不增加第三个
hard gate。

该结论是同一离散数值 mode 的强证据；有限 Fourier representation 与九点 probe 不是连续物理场
同一性的完备证明。

## 8. Direct candidate drift 与 hierarchy

对两项相邻 pairs 和完整 $32$--$48$ pair，直接保存值之差均为

$$
\Delta^{\mathrm{cand}}_{ab}=\widehat k_{M_b}-\widehat k_{M_a}=0.
$$

| $M$ pair | signed drift | absolute drift | classification |
|---|---:|---:|---|
| 32--40 | 0 | 0 | `NO_OBSERVED_CANDIDATE_DRIFT` |
| 40--48 | 0 | 0 | `NO_OBSERVED_CANDIDATE_DRIFT` |
| 32--48 | 0 | 0 | `NO_OBSERVED_CANDIDATE_DRIFT` |

没有观察到超过预注册 $10^{-6}$ scale 的 severe drift。trend `FLAT` 只描述保存的三个 grid
winners，不描述未计算的 sub-grid minimizers。

三个 candidates、两项相邻 `SAME_MODE`、最低健康门、gauge 与 repeats 全部通过。因此按冻结
合同形成 `CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY`，并设置 `hierarchy_qualified=true`、
`i3_may_proceed=true`。零 observed shift 不撤销 hierarchy，也不自动提供可用于 estimator 的
非零 next-level correction。

## 9. 旧 `drift-a1` 与新 M48 的 context comparison

旧 ntot-axis `drift-a1` 的 $n_{\mathrm{tot}}=160,M=48$ point 使用由
$n_{\mathrm{tot}}=256,M=48$ seed 产生的 common frame；本实验的 M48 level 在
$n_{\mathrm{tot}}=160$ 独立 seed。二者不是彼此的 algorithmic parent，以下对照按预注册合同
只作 context，不进入 M-axis pass/fail。

| Quantity | old ntot-axis $n_{\mathrm{tot}}=160,M=48$ | new M-axis $M=48$ | comparison |
|---|---:|---:|---:|
| saved candidate | 1.832770289108157 | 1.832770289108157 | difference $0$ |
| $s_1$ | $5.65525672256\times10^{-11}$ | $5.65525682561\times10^{-11}$ | difference $1.03\times10^{-18}$ |
| raw right residual | $1.59276282291\times10^{-10}$ | $1.59276343645\times10^{-10}$ | roundoff-scale change |
| raw left residual | $2.97099970872\times10^{-10}$ | $2.97099672317\times10^{-10}$ | roundoff-scale change |
| raw right backward | $5.20664864548\times10^{-13}$ | $5.20665065111\times10^{-13}$ | both pass |
| raw left backward | $5.20131492754\times10^{-13}$ | $5.20130970074\times10^{-13}$ | both pass |
| SVD triplet residual | $8.45372\times10^{-16}$ | $5.57430\times10^{-16}$ | both pass |

phase/scale-invariant overlaps for balanced $v_1$, weighted wall trace, probe field and raw $q$ are
all one to stored precision.旧新 $A_{\mathrm{def}}^D$ 与 $A_{\mathrm{phys}}$ 的 relative
Frobenius differences 分别约为 $2.85\times10^{-17}$ 与 $4.21\times10^{-17}$。两边均有相同
十个 factor labels，availability/pass pattern 完全一致；最紧 `proxy_reduced` rcond 和
$1.04817$ 门槛比例也完全相同。

该对照支持 M48 candidate 对两种合法 seed/frame context 的数值一致性，但不能把旧 ntot-axis
和新 M-axis 合并为二维 convergence hierarchy，也不把旧 I2.1 count 转移到本实验。

## 10. Claim boundary 与 I3 handoff

本次可以保留：

- 三个通过最低健康门的 conditional finite-dimensional saved candidates；
- 两项相邻 `SAME_MODE` 与一致的 $32$--$48$ diagnostic；
- 三对 direct candidate drift 均为零，即 `NO_OBSERVED_CANDIDATE_DRIFT`；
- selector-order gauge、fixed-candidate repeat 和 resource contract 通过；
- 一条可供 I3 使用的 conditional algorithmic M-axis hierarchy。

本次不能声称：

- 三个 sub-grid score minimizers 相同或已经解析；
- finite-dimensional exact root 或 continuous guided-mode eigenvalue 已建立；
- $M$-convergence order、Richardson-type correction 或 nonzero next-level error signal；
- continuous--discrete error attribution、estimator、effectivity 或误差上界；
- I2.1 count one 附着于任何固定 $n_{\mathrm{tot}}=160$ level，包括 $M=48$。

I3 可以接收 saved candidate sequence、same-mode identity、零 observed shift、terminal minimizer
search scale 和最低健康 ledger，开始区分定位、trace cutoff、half-guide、BIE/QZ、structure 与
continuous--discrete error sources。若 I3 所选 estimator 需要非零 next-level correction、精确
minimizer 或 independent continuous truth，必须另行冻结相应 indicator/reference；不得反向改写
本次 flat candidate 结论。

## 11. Caveats 与最终 verdict

### Blockers

当前 execution/evidence blocker 为零。

### Important caveats

1. `proxy_reduced` rcond 仅为门槛的约 $1.04817$ 倍；本次 pass 余量有限。
2. terminal-grid winner 相同不能识别潜在 sub-grid minimizer drift。
3. 固定 $n_{\mathrm{tot}}=160$ 的三个 levels 均没有 I2.1 count-one evidence。
4. 三个有限 cutoff levels 不能给出 convergence order 或 error bound。
5. 九点 probes 和有限 Fourier common representations 不是 continuous-mode identity 的完备证明。

这些 caveats 与 [[research/projects/eig-apost/implementation/open-problems|project open-problem ledger]]
中的 candidate/minimizer、factor margin 和 I3 independent-reference 问题一致；本审查不另开重复
理论路线。

### Minor caveat

peak active-object snapshot 不是操作系统 RSS，只能按冻结 resource contract 解释。

最终决定为：

```text
PASS WITH CONDITIONS
NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE
CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY
I3 MAY PROCEED WITH CONDITIONS
```

正式 `m-drift-a2` 必须 append-only 保留，不得以同 tag 重跑。最小下一门是 I3 冻结误差来源、
独立 reference 与 estimator 所需的非零或替代 indicator；不是继续扩张 I2.3 扫描。
