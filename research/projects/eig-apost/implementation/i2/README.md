# I2：从实轴 dip 到后验估计可用离散根的总体规划

## Material Passport

- Origin Skill: `academic-research-suite / experiment-agent`
- Origin Mode: `plan`
- Origin Date: `2026-08-12`
- Verification Status: `I2.1 PASS WITH CONDITIONS / I2.2 NOT STARTED`
- Version Label: `i2-project-plan-v2-compact`
- Scope: 本页维护 I2 的四里程碑最小充分证据链和实际状态；具体实验仍须另行设计与审查。

## 当前状态与权威边界

I2 当前状态为 `I2.1 PASS WITH CONDITIONS / I2.2 DESIGN NOT STARTED`。I2.1 已在冻结
fine、$M=48$、$K=97$ 的未平衡 $194\times194$ 矩阵族上完成 factor-aware contour count：
指定 I1 dip 圆盘内的 determinant zero 代数计数为一。统一实验入口是
[[test/i2/k-count/README|I2-K-COUNT-M1B-V1]]，独立结论与运行历史见
[[research/projects/eig-apost/implementation/i2/review|I2.1 review]]。

该结论没有给出 root 坐标、几何/导数单根、非零物理场、跨层 matching 或 estimator；
也不是连续 physical eigenvalue。I2.2 尚未设计或授权。

现行连续物理对象由
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]] 定义：
真实 guided eigenvalue 是连续 physical pencil $\mathcal F(k)$ 的非平凡核点。I2 直接处理的
对象是 I1 冻结的有限维矩阵族 $A_{\mathrm{def},h,M}(k)$。这里 $M$ 表示人工墙上保留的
Fourier 模态阶数，$h$ 统称 one-cell 或 center 的空间离散；一个离散 level 是这些选择和
linear-algebra policy 的冻结组合。

本页始终区分四类对象：

1. 实轴最小奇异值的 deep dip；
2. 一个固定离散层上的 finite-dimensional root；
3. 相邻离散层上匹配的 finite-dimensional simple root；
4. 连续 physical $\mathcal F(k)$ 的真实 eigenvalue。

前一项不能自动升级为后一项。I2 即使完整通过，也只交付可供 I3 使用的、跨层匹配的有限维
simple root；只要 M0 的连续理论缺口仍开，就不能把它直接称为真实 guided eigenvalue。
当前行动边界见 [[research/projects/eig-apost/STATUS|project STATUS]]，阶段依赖见
[[research/projects/eig-apost/implementation/ROADMAP|current-route ROADMAP]]，未解决问题由
[[research/projects/eig-apost/implementation/open-problems|open-problem ledger]] 管理。

## 阶段定位与成本原则

I2 位于 I1 的“离散算子与 dip readiness”和 I3 的“后验 correction 与 effectivity”之间。
它的实验总体目标不是把所有连续理论和数值细节一次证明完，而是用可控成本回答：

> I1 找到的 dip，是否对应一个能被可靠求出、能在相邻离散层上保持同一身份，并且具有
> 可用一阶分母的离散根？

最小主线为：

$$
\mathrm{I1\ sampled\ dip\ readiness}
\longrightarrow
\mathrm{single\ root\ isolation}
\longrightarrow
\mathrm{qualified\ fixed\ level\ root}
\longrightarrow
\mathrm{one\ matched\ level\ pair}
\longrightarrow
\mathrm{qualified\ correction\ denominator}
\longrightarrow
\mathrm{I3}.
$$

本规划采用以下成本原则：

- 一项检查只有在失败时会改变“能否把 dip 当根”或“能否计算和解释后验 correction”，
  才进入四个主里程碑。
- 能增加完备性、鲁棒性或理论强度，但不直接改变 I3 可行性的工作，列为 `OPTIONAL`。
- `OPTIONAL` 不预先消耗实验预算；只有观察到对应异常，或准备提升论文主张时才升级。
- I2 不承担三个以上 levels、reference truth、effectivity、saturation、remainder 或
  theorem-level continuous certification；这些分别属于 I3、I4 或 M0。

## 阶段目标

I2 只追求四个直接服务于后验特征值误差估计的目标：

1. 确认 dip 邻域内有一个可解释的离散根，而不是零根、多根、换支或 evaluator pole；
2. 求出该根，并用最低成本排除 solver 停滞、factor pole 和重构零场等明显伪根；
3. 在一个相邻离散层对上确认同一个 root 与同一个 mode，得到可解释的实际 root shift；
4. 资格化 I3 公式所需的总导数作用和非零左右配对，形成最小 I3 交接包。

## 输入条件

### 已由 I1 提供的输入

I2 承接以下 I1 正式收尾结果；数值证据以
[[research/projects/eig-apost/implementation/i1/report|I1 stage report]] 为准。I1 的
[[research/projects/eig-apost/implementation/i1/review|design review]] 只审查 I1.1 设计，
不能代替 I1.2--I1.4 的数值报告。

- 冻结模型为 identical sharp-disk periodic leads 与 homogeneous missing center column；
  当前中心 density dimension 为 $n=0$。
- fixed-$M=48$ trace space、Fourier 顺序、法向、unknown ordering、physical coefficient
  weights、双向 ordered-QZ 及 safe-chart/fallback 语义已经冻结。
- I1 给出的实轴候选为 $k_c=1.8327703475952146$；它仍只是 dip 的定位输入，不是 root。
- I1.4 在小复圆盘的有限采样点上完成 anchored branch、seed-cluster continuation、固定
  frame/chart/rank、factor ledger、closure、Cauchy--Riemann 和负例 readiness。
- I1.2 的 one-cell $\to$ QZ $\to$ Cauchy graph $\to$ DtN
  $\to A_{\mathrm{def}}$ 静态链及 I1.3 的 coarse/fine candidate consistency 已有证据。
- `DERIVATIVE_AVAILABLE=false`；I1 暴露的 graph-basis mutation 问题尚未解决，现有
  finite difference 不能直接用于 I3 correction。

这些输入用于避免重复 I1 已通过的 readiness 工作。它们没有证明 contour 内有根、未采样处
绝无 pole，也没有证明离散矩阵核等价于连续物理场。

### 后续实施前必须补齐的输入

I2.1 已由冻结设计和独立审查完成。任何 I2.2--I2.4 实验开始前，仍需要一份另行审查的
详细设计与预注册，并获得用户明确授权。后续设计至少要冻结：

1. 权威矩阵 evaluator、搜索域、root count 语义和 fail-closed 规则；
2. 一个相邻离散层对及其公共表示、transport、normalization 和 scaling；
3. root、mode identity、导数分母及其 uncertainty 的最小验收规则；
4. 基本 source/config/solver provenance 和失败后停止规则。

本页不选择具体算法、阈值、轮廓参数、离散层数值或 solver。

## 退出条件

完整 I2 只有在以下四道门全部通过时才结束：

1. 在同一冻结离散对象上得到可解释且稳定的 count one；branch、selected subspace、chart、
   rank、solver policy 与必要 factors 没有在搜索中悄悄改变。若 evaluator 是 meromorphic
   或含消元 factors，内部 poles 必须被排除或显式计入，不能把“零点数减极点数”误读成
   “一个零点”。
2. 在隔离区域内得到可重复、低 residual 的根；其近核方向不消失，最低限度 center/port
   场证据和边界匹配成立，且 singularity 不与 factor pole 同步。
3. 在一个预先冻结的相邻离散层对上分别得到合格根，并在公共表示下确认是同一 mode；
   root shift 必须能与两层的求根不确定度区分。
4. I3 实际使用的总导数作用通过独立一致性检查，左右配对
   $y^*A_{\mathrm{def}}'(k)x$ 明显非零且大于相关不确定度；交接数据不混层、不混坐标。

通过前两门后，只能报告“固定离散层上的 qualified finite-dimensional root”，不能开始
I3。四门全过后，I2 才能交付“跨层匹配、分母可用的 finite-dimensional simple root”。
该出口不表示 continuous eigenvalue、remaining-error estimator、effectivity 或 certified
bound 已经建立。

## I2 内部里程碑规划

| Milestone | 内容 | 当前状态 | 下一门 |
|---|---|---|---|
| I2.1 同一离散对象上的单根隔离 | 合并对象合同、搜索域/evaluator 完整性和 count-one isolation | `PASS WITH CONDITIONS` | 条件性 finite-dimensional count one 已完成；允许另行设计 I2.2 |
| I2.2 根求解与最低限度伪根排除 | 求出 fixed-level root，并检查 residual、复现、factor health 与非零场证据 | `NOT STARTED / NOT AUTHORIZED` | 只有根不是明显数值或表示伪影，才允许跨层比较 |
| I2.3 一个相邻层对上的 root/mode matching | 确认两层是同一谱对象，并分离实际 root shift 与求根噪声 | `PLANNED / NOT STARTED` | matching 通过后，才资格化 correction 分母 |
| I2.4 correction 分母资格化与 I3 交接 | 资格化总导数作用、非零左右配对、共同 scaling 和最小交接包 | `PLANNED / NOT STARTED` | 四门全过后才允许另行规划 I3 |

## 逐项解释

### I2.1 同一离散对象上的单根隔离

- **具体要解决什么问题：**判断 I1 dip 周围究竟没有根、恰有一个根，还是混有多个根、
  evaluator pole 或不同数值分支，并把后续求解限制在一个单根区域内。
- **为什么必须做：**实轴上的小奇异值只说明边界匹配“几乎”有非零解；它可能只是一个
  没有 zero 的浅谷。若平方根 branch、衰减模态集合或 chart 在搜索中改变，程序甚至会把
  不同矩阵拼在一起；若内部 factor 有 pole，绕行计数看到的还可能是零点数减极点数。
- **计划检查什么：**把对象合同并入本里程碑，冻结同一 $A_{\mathrm{def},h,M}(k)$、排序和
  solver policy；继承 I1.4 的 branch、QZ subspace、frame/chart/rank 与 factor gates；检查
  count 的闭域解析或显式 pole-aware 语义、边界分离，以及一次预注册的最小稳定性核对。
- **什么结果可以接受：**整个搜索边界都来自同一可用 evaluator；没有未解释的内部 pole；
  count 可稳定解释为 one，且边界不贴近 root 或 evaluator failure。
- **什么失败会阻止继续：**count 为零、大于一或不稳定；无法区分 zeros 与 poles；发生
  branch/subspace/rank 切换、关键 factor 失效、chart 无合法处理或 solver 静默换路。
- **完成后能支持什么结论：**只支持“冻结有限维矩阵族的该区域内有一个按代数重数计的
  determinant zero”。它还没有给出根的位置、向量或物理身份。

I2.1 实际以 `PASS WITH CONDITIONS` 完成。嵌套主 winding 稳定为 count one，全部非主
inverse/section factors 均为 zero winding，预注册门全部通过。运行耗时、资源、失败保留、
哈希与数值裕量统一见
[[test/i2/k-count/README|experiment index]]，阶段审查见
[[research/projects/eig-apost/implementation/i2/review|review]]。该结果按项目术语称
“一个按代数重数计的 zero”，不提前称 derivative-qualified simple root。

### I2.2 根求解与最低限度伪根排除

- **具体要解决什么问题：**在 count-one 区域内求出根，并确认结果不是 solver 停在 dip、
  消元 factor 的 pole、多个近核方向或只产生零物理场的代数奇异性。
- **为什么必须做：**count one 只说明“区域内有一个”，不告诉根在哪里。小 residual 若与
  evaluator error 同量级，可能只是计算噪声；非零矩阵向量若不能产生非消失的 center/port
  场，也不能作为后续“特征值误差”的对象。
- **计划检查什么：**检查根位于隔离区域内部、非线性 residual、linear-algebra backward
  error、evaluator uncertainty 和一次独立复现；检查一维近核方向、左右 residual、root
  处 factor health、最低限度 center/port field participation 与边界匹配；若目标是实
  guided root，还要判断 $\operatorname{Im}k$ 是否能由数值不确定度解释。
- **什么结果可以接受：**同一区域内得到可重复的低 residual root；近核方向与其他方向可
  区分；场证据不消失且边界匹配合格；root 不贴近 contour 或 factor pole。无需在本阶段
  建立完整 kernel--field 定理。
- **什么失败会阻止继续：**根不复现、跑出区域或 residual 停滞；近核维数不清；重构场
  消失；singularity 与 factor pole 同步；或者对预期实根出现超过误差解释范围的虚部。
- **完成后能支持什么结论：**支持“在一个冻结离散层上得到具有最低非伪根证据的
  finite-dimensional root”。它仍不是连续 physical eigenvalue，也不能单独支持 I3。

### I2.3 一个相邻层对上的 root/mode matching

- **具体要解决什么问题：**确认相邻两个离散层上的根代表同一个 mode，并得到 I3 将要
  解释的实际 root shift，而不是把两个数值接近但场形态不同的根配在一起。
- **为什么必须做：**离散层改变时，mode 可能靠近、交换顺序，伪根也可能消失。只按
  $|k_{\ell+1}-k_\ell|$ 最近配对，会制造虚假的收敛序列，使后续 correction 的 numerator
  比较两个不同谱对象。
- **计划检查什么：**只选择一个预先冻结的相邻层对；要求两层分别通过 I2.1--I2.2；通过
  明确 transport 放入公共表示，比较 root 邻近、近核方向和最低限度 field signature；
  检查 root shift 是否明显大于两层 root-solve uncertainty。
- **什么结果可以接受：**两层各有一个合格 root，公共表示下的 mode/field identity 一致，
  没有明显 mode swap，且层间 shift 不被求根噪声淹没。
- **什么失败会阻止继续：**任一层失去隔离根；公共 transport 未定义；field 或近核方向
  表明换支；finer root 消失；或 root shift 与求根不确定度无法区分。
- **完成后能支持什么结论：**支持“一个相邻层对上匹配到同一 finite-dimensional root
  family，并得到可解释的 next-level root shift”。三个以上 levels、收敛率和 effectivity
  留给 I3。

### I2.4 correction 分母资格化与 I3 交接

- **具体要解决什么问题：**确认后验 correction 公式的分母可计算且不接近零，并把 I3
  真正需要的 roots、vectors、transport 和 uncertainties 交接出去。
- **为什么必须做：**I3 的一阶结构包含

  $$
  -\frac{y^*\Delta A(k)x}{y^*A_{\mathrm{def}}'(k)x}.
  $$

  分母表示改变 $k$ 时匹配条件穿过零的速度。若导数漏掉某项 $k$ 依赖、受 basis mutation
  污染或配对接近零，微小矩阵误差就会被放大成巨大而虚假的 correction。若两层使用不同
  scaling，商值也可能只因坐标单位改变，而非物理误差改变。
- **计划检查什么：**检查 correction 实际使用的总 derivative action 覆盖 phase、cell/BIE、
  continued subspace、graph/chart 与 DtN 的相关 $k$ 依赖；用独立数值一致性和 I1 已暴露的
  basis-mutation 风险检查其 uncertainty；检查左右向量、非零导数配对及共同
  normalization/scaling；最后核对交接 provenance 与 claim boundary。
- **什么结果可以接受：**derivative action 在当前窄合同下可用；
  $|y^*A_{\mathrm{def}}'(k)x|$ 明显大于 derivative、root 和 evaluator uncertainty；合理的
  固定坐标变换不改变可用性结论；交接包不混层、不混表示。这里不要求先证明 continuous
  physical adjoint 或完整 Riesz/Gram 理论。
- **什么失败会阻止继续：**导数遗漏主要依赖、独立核对不一致或仍受 basis mutation 污染；
  左右配对接近零或对 scaling 敏感；不同层数据混用；root uncertainty 足以淹没待解释量。
- **完成后能支持什么结论：**支持“已得到 I3 可消费的、跨层匹配且分母可用的有限维
  simple root”，并允许另行规划 I3 correction/effectivity。它不表示 estimator 已运行或
  theorem-level error claim 已成立。

## OPTIONAL：不计入四个主里程碑的增强工作

下列工作不因单独未完成而阻断 I2，也不预先安排为额外 stage。只有括号中的触发条件出现
时，相关项目才升级为解决当前 blocker 所必需的检查。

| OPTIONAL 工作 | 为什么不在 I2 主线 | 何时升级 |
|---|---|---|
| 第二种独立 count 算法、多组轮廓族或大范围复域扫描 | 一个可审计且稳定的 count-one 路径已足以回答当前单根问题 | count 随合法加密变化、疑似漏根或准备作全域完备性主张 |
| raw/Schur/graph/DtN 全面互证、大型 spurious-density 负例或独立物理求解器 | I2.2 只需最低成本排除明显零场和 factor-pole 伪根 | 场趋零、表示敏感、factor 异常，或准备提升 kernel--field 主张 |
| production structured `DIF/sep`、全闭域 pole-free 定理和穷举 chart/path/gauge 检查 | I1 的经验连续性证据足够支持当前窄范围 isolation，不支持认证级条件数结论 | cluster/branch ambiguity、chart 敏感或 claim 升级 |
| 三个以上离散 levels、多个 mode、参数扫描、收敛率和独立 reference | 它们用于 effectivity、渐近区或可迁移性，不是确认首个 matched pair 的最低需要 | 进入 I3/I4 后按其设计启动 |
| 某一种特定的 production analytic subspace-tangent backend、完整 continuous adjoint、Riesz/Gram 理论和 balancing sweep | I2 不预先指定导数 backend；但无论采用何种 provider，总导数都不得漏掉 continued-subspace 的实际贡献 | 廉价 derivative oracle 不一致、配对对 scaling 敏感或准备作定理级主张 |
| saturation、remainder、certified interval 和 remaining-error bound | 它们不决定 dip 是否为根，属于 estimator 强度问题 | I3 要把 next-level correction 升级为 remaining-error estimator 时 |
| MATLAB parity、任意精度复算、全量 self-contained manifest 与跨版本重跑 | 基本 provenance 和一次独立复现已足以支持当前阶段结论 | 出现 runtime 敏感、准备发布可移植结果或依赖发生实质变化 |

M0 中 continuous holomorphy、BIE kernel--field equivalence、regular approximation 和
spectral-pollution 排除仍是 physical promotion blockers。它们不进入 I2 的四个实验
里程碑，但未关闭时必须限制结论为 empirical/conditional finite-dimensional result；
不得因列在主线之外而把这些理论义务写成已经解决。

## I2 与 I1 已完成结果的衔接

| I1 已完成结果 | I2 如何承接 | 不能由此推出什么 |
|---|---|---|
| I1.1 冻结 continuous-to-discrete 层级、法向、空间、QZ/graph/chart 与 $A_{\mathrm{def}}$ 合同 | I2.1 直接沿用，不再单设“合同实验” | 离散矩阵核等价于 continuous physical kernel |
| I1.2 actual $M=48$ static one-cell/QZ/graph/DtN/$A_{\mathrm{def}}$ chain 通过 | I2.1--I2.2 复用 evaluator、排序、factor 和失败语义，不重复静态装配 | contour 内有 root，或 production derivative 已完成 |
| I1.3 得到 coarse/fine 一致的 real-axis dip 与 fixed-$M=48$ candidate | I2.1 用它定位搜索域，I2.2 尝试把它推进为 root | 已存在 real root、root 已收敛或出现 plateau |
| I1.4 sampled anchored complex-disk readiness 条件通过 | I2.1 继承 branch/frame/chart/rank/factor/closure/CR 证据，只补 count 所需的最小检查 | 未采样处绝无 pole，或 contour count/root 已经运行 |
| I1 暴露 `DERIVATIVE_AVAILABLE=false` | I2.1--I2.3 保持 derivative-free；I2.4 只资格化 I3 实际需要的总 derivative action | Newton、simple-root correction 或 estimator 已可用 |
| 当前对称模型中 physical transmission swap 不可辨识 | 保留 I1 的条件性边界，不在 I2 重做无辨识力的测试 | 一般非对称 lead 的 transmission labels 已动态验证 |

I1 的历史失败 verdict 不作追溯改写。I2 应引用 I1.3 width-driven v2、I1.4 V4 positive
parent 与 V5 conditional closure，不能把它们合并成无条件 PASS。旧 finite-tail/doubling
只保留为 `OPTIONAL` cross-check，不重新成为 exact DtN 或主 root definition。

## 失败、降级与停止规则

| 失败位置 | 可保留的结论 | 必须停止什么 |
|---|---|---|
| I2.1 未得到可解释 count one | 只保留 I1 dip 与 count diagnostic | root claim、root solve 和后续全部主线 |
| I2.2 求根或最低非伪根门失败 | count-one 区域，或最多 algebraic matrix root | guided-mode discrete candidate、matching 与 I3 |
| I2.3 无法确认同一 mode | 两个各自合格但身份未匹配的离散 roots | root convergence、next-level shift 与 correction |
| I2.4 derivative/pairing 失败 | matched discrete roots 与实际 shift | simple-root claim 和 I3 correction |
| 四门通过但 M0 blockers 仍开 | qualified matched finite-dimensional simple root | continuous eigenvalue 与 theorem-level estimator claim |
| I3 尚无 saturation/remainder | empirical next-level correction | remaining-error、certified bound 或无条件 effectivity claim |

失败后不得通过临时改变轮廓、solver、normalization、mode identity 指标或阈值来追溯制造
PASS。若必须改变合同，应形成新的详细设计并重新审查。

## 当前尚不确定、需要后续决定的事项

以下事项在项目级规划中保持开放；它们是在四个里程碑内部需要冻结的选择，不构成新的
stage：

1. **root solve 与复现。** 采用何种 derivative-free 求根方式、如何定义 evaluator/root
   uncertainty，以及哪一种独立复现足够而不扩张成 solver benchmark。
2. **最低非伪根门。** 当前 $n=0$ 模型下，哪一个 center/port field participation、边界
   residual 与 factor-health 组合足以排除明显伪根；出现异常时再启用 OPTIONAL 互证。
3. **相邻层对与 transport。** 第二个 level 改变 $h$、$M$ 还是其中一项，以及 trial/test
   vectors 和 field traces 如何搬到公共表示；I2 只冻结一对，三层以上交给 I3。
4. **mode identity。** 哪个最低成本的 eigendirection/field overlap 规则足以排除 mode swap，
   以及 root shift 相对 solve uncertainty 的解释规则。
5. **derivative 与 pairing。** 哪种总 derivative provider 能关闭 I1 的 basis-mutation 失败，
   如何评估其 uncertainty，并在固定坐标/scaling 下形成稳定的左右配对。
6. **经验解析 caveat 的触发条件。** I2.1 的 64 点 $k$ screen、32 点 $\zeta$ screen、
   proxy reduced 的窄 `rcond` 裕量和 Riesz range-difference 裕量何时需要升级；除非 I2.2
   出现异常或 claim 升级，否则不追加 I2.1 完备性实验。
7. **交接标签。** fixed-level root、matched root、simple root 和 physical eigenvalue 的稳定
   标签，以及 I3 最小输入文件和 provenance 格式。

## 推荐阅读顺序

1. [[research/projects/eig-apost/STATUS|project STATUS]]：当前状态、禁止事项与 handoff。
2. [[research/projects/eig-apost/implementation/i1/report|I1 stage report]]：I1 正式收尾结果与
   数值证据边界。
3. [[research/projects/eig-apost/implementation/i1/design|I1 discrete design]]：I2 继承的
   空间、QZ/graph/chart、导数与 balancing 合同。
4. [[research/projects/eig-apost/implementation/i2/design|I2.1 frozen design]] 与
   [[research/projects/eig-apost/implementation/i2/review|I2.1 review]]：已运行方法、独立
   verdict 和进入 I2.2 的边界。
5. [[test/i2/k-count/README|I2.1 experiment index]]：唯一实验材料入口。
6. [[research/projects/eig-apost/implementation/ROADMAP|current-route ROADMAP]]：I1--I4
   依赖和正式 I2 退出条件。
7. [[research/projects/eig-apost/implementation/open-problems#Current I2|Current I2 ledger]]
   与 [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]：当前 blocker
   与 caveat。
8. [[research/projects/eig-apost/phase3-analysis/s-root|root qualification]]：dip、离散 root 与
   continuous eigenvalue 的区分。
9. [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]：I3
   correction 的对象、分母和现行数学边界。

本页不把历史 Phase 3 finite-tail plan 或归档旧 I2 当作当前授权；只有明确追溯历史时才进入
archive。
