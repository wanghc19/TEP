# I3：连续特征值误差估计与条件性证书

## 阶段定位

I2 已为连续波导问题提出一个可复现的实轴 numerical candidate，并从局部复平面计数、
Hermitian part 的端点符号计数以及两条单轴离散实验三个角度检查了它的可信度。I2 没有给出
candidate 到真实连续特征值的误差，也没有给出收敛阶或误差上界。详细交接见
[[research/projects/eig-apost/implementation/i2/report|I2 stage report]]。

I3 先研究一个不要求命名唯一 mode 的误差。记 I2 在离散层 $h$ 上实际保存的 candidate 为
$\widehat k_h$，暂记 $G_\lambda\subset(0,\infty)$ 为后续须针对当前模型认证的 continuous
projected essential gap，并定义其中的正离散特征频率集合

$$
\mathcal K_{\mathrm{disc}}(A;G_\lambda)
:=\{\sqrt{\lambda}:\lambda\in\sigma_{\mathrm{disc}}(A)\cap G_\lambda\}.
$$

约定到空集的距离为 $+\infty$。因此在当前 continuous projected gap 和其中离散谱的存在性
尚未建立时，这个定义不会预设目标集合非空。

第一层目标是

$$
e_h^{\mathrm{gap}}
=\operatorname{dist}\bigl(\widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)\bigr).
$$

这表示 candidate 到 gap 内某个真实连续离散特征值的误差；它不预先指定该特征值的名字。
只有后续确实需要跟踪特定 mode 时，才定义第二层 target-specific error

$$
e_h^*=|k_*-\widehat k_h|.
$$

本阶段不把有限维矩阵的精确零点、层间漂移、矩阵残差或某个修正公式本身当成最终成果。
这些量只有在能够帮助估计上述连续谱误差时才进入主线。I3.1 的早期路线给出四个正式负向
结果，纯 BIE 路线首次形成 finite indicator；最新全边界胞元 BIE 又关闭了旧 wall/$T$/outside-$M$
资格问题，但 circle action $256\to512$ change 仍未通过。当前因此已有可计算但
`NUMERICALLY_UNQUALIFIED` 的 indicator candidate。2026-08-24 起，I3.2 的条件性证书谱包含
定理已经建立，并承载固定同一 trial 的 empirical evaluation-cap application。正式 `ecap-a2`
完成 evaluation 后因 $664.470682>640$ MiB 资源门停止，cap、full-$P$、$q$ 和 interval 未到达；
原 I3.3 已整体迁移至未来阶段 I4.1；I4.1 只登记使用独立方法/reference 对经验 estimator 进行
effectivity validation。原 I3.4 已整体迁移至未来阶段 I4.2，仍负责可靠 enclosure/gap 与
可计算上界。I4.1 和 I4.2 当前均未启动。

长期对象门如下：每个新增主线对象和 hard gate 都必须写出它如何进入第一层集合距离或可选
target-specific error 的估计链；若它
只描述 finite root、score minimizer、层间矩阵差或实现内部一致性，就降为 `OPTIONAL` 或
quality diagnostic。Skeptic 在每次 design/revision 审查中都必须重新执行这项对象检查。

下表保留 I3.1--I3.4 的原阶段条目，便于稳定追溯。I3 当前范围只保留 I3.1 和 I3.2；原 I3.3、
I3.4 已分别迁移至 I4.1、I4.2。迁移不改变任何已完成或保留工作的科学含义。

| Milestone | 独立科学问题 | 核心输出 | 当前状态 |
|---|---|---|---|
| I3.1 | 能否从实际计算量构造并内部论证一个与 continuous gap-spectrum distance 有关的可计算指标？ | 可计算 indicator candidate、覆盖/忽略项和内部检查 | `PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE` |
| I3.2 | 对同一连续 trial，严格 residual/field caps 若存在，能否推出连续谱相交；同一 certificate 的 nested evaluation 能否形成 ordinary empirical cap？ | 条件性定理、cap 可行域、证书接口和 same-trial application | `THEOREM ESTABLISHED / EMPIRICAL CAP UNRESOLVED` |
| I3.3 | 冻结 estimator/candidate 能否在独立 reference 上跟踪真实误差量级？ | independent-reference/effectivity verdict | `已迁移到 I4` |
| I3.4 | 能否实际构造 outward enclosure、certified gap 和不含未知常数的存在/误差上界？ | reliable interval、离散存在性、$U_h$ 或 `UPPER_BOUND_UNAVAILABLE` | `已迁移到 I4` |

## 从 I2 接收的输入

I3 接收的是 candidate 及其质量证据，而不是已经成立的误差估计：

- I2 在两条预先冻结的离散轴上均保存了同一个 candidate
  $\widehat k_h=1.832770289108157$；
- 相邻离散层通过了公共 Fourier 系数、边界 trace 和固定物理采样点上的 mode identity 检查；
- 原矩阵 residual、backward error、near-null separation、factor、field、boundary、repeat 与
  selector-gauge 等诊断已经记录；
- terminal cell half-width 只描述连续 score minimizer 的搜索分辨率，不是 $\widehat k_h$ 的
  uncertainty，也不是 continuous-eigenvalue error 的上界；
- 两条轴的 observed candidate shift 都是零。这是有用的稳定性事实，但不能单独产生非零
  correction、收敛阶、effectivity 或真值误差界。

I3 还必须面对 I2 尚未解决的 continuous--discrete 问题，包括半波导近似、边界积分表示、
Rayleigh/Fourier 截断、边界离散、QZ 子空间、有限精度求解以及从离散矩阵到连续物理算子的
关系。哪些误差进入 $\eta_h$、哪些暂时忽略，必须在 I3.1 随具体公式一起说明，不能先验地把
全部误差相加成一个没有数学来源的“总误差账本”。

## I3.1 当前理论选择与实验结果

现行分析见 [[research/projects/eig-apost/phase3-analysis/README|Phase 3 analysis]]。I3.1 直接在
算法保存的 $\widehat k_h$ 处研究连续物理残量。一般主线仍是：从 I2 数据重构非零的
continuous form-space field $u_h^{\mathrm c}$，令 $\mu_h=\widehat k_h^2$，并对连续 form
$a$ 定义

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h(u_h^{\mathrm c},v)_H.
$$

首选指标来自 normalized dual norm

$$
q_h=\frac{\|R_h\|_{V'}}{\|u_h^{\mathrm c}\|_V}.
$$

对 nonnegative self-adjoint operator，谱定理把 exact $q_h$ 直接联系到 $\mu_h$ 与某个
continuous spectral point 的距离。若进一步得到可靠 residual interval，且它完全位于当前
continuous operator 的 projected essential gap 内，则区间中至少存在一个孤立、有限重的离散
特征值。正式设计还必须在看结果前冻结可接受的 $k$-分辨率及一个小于一的 gap-relative
宽度比例；区间既要小于绝对分辨率，也不能几乎占满整个 gap。区间过宽时只能保留存在性，
不能称为达到项目分辨率的结果。把该谱值识别为某个指定 $k_*$ 是独立的第二层可选升级，不是
residual 计算或第一层存在性的前置 blocker。近似 Riesz solve 也不自动给 dual norm 上界，
所以 I3.1 先交付 continuous-residual indicator candidate；I3.2 建立严格 caps 蕴含谱相交的
条件性定理并研究 same-trial empirical cap。独立 effectivity validation 与可靠
enclosure/gap 已分别迁移至未来 I4.1 和 I4.2。

首个冻结实验 [[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 利用了当前
模型中心空列的特殊结构：从 I2 的 Fourier 墙系数构造空列中的显式场 $u_0$，乘以固定
$\chi(x)=\cos^2(\pi x)$ 后在单胞外延零。这个场属于连续强算子的定义域，因而可以直接计算

$$
\eta_h^{\mathrm s}
=\frac{\|(A-\mu_h)\chi u_0\|_H}{\|\chi u_0\|_H}.
$$

正式 `center-a1` 得到 $\|\chi u_0\|_H=0.840017038309255$、残量范数
$18.848991951433035$ 和 $\eta_h^{\mathrm s}=22.43882099031153$。三个积分层稳定，但普通
双精度积分不是可靠上包络；更关键的是，残量由固定单胞 cutoff 的导数项主导，名义
$\lambda$ 区间跨过零且远宽于预注册 $10^{-6}$ 频率分辨率。因此本实验只交付一个可复现的
连续强残量负向 baseline，当前解释为
`FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`；它不支持 continuous projected gap 内离散特征值
存在，也不能实例化现行 I3.2 strict theorem 或进入未来 I4.1 independent effectivity validation。

历史 V1 路线由 frozen wall states 生成左右无限序列，并用 one-cell BIE 内外场拟合显式
Fourier--Hermite/bubble trial。正式 `lead-a3` 通过 finite input、density representation 和
frozen-$Z$ propagation，
但固定 fit 的独立 holdout error 在 $J=4$ 已约为 $4.522421$，到 $J=8$ 增至约
$5.138028$，远高于预注册 $0.20$。producer 因而在
`CONFORMING_RECONSTRUCTION_UNRESOLVED` 首败处停止；center correction、Grams、quadrature、
infinite tail 和 strong-residual ratio 均为 `NOT_REACHED`。

training/holdout targets 到材料圆的最小距离仅为 $4.22\times10^{-5}$ 与
$5.32\times10^{-5}$，约为 $N=256$ source-panel arc scale 的 $0.86\%$ 与 $1.08\%$；direct
close layer-potential evaluation 尚未单独资格化。因此现有证据不能把失败单因归咎于 bubble
basis，只能说当前 pipeline 未建立 BIE-informed shape quality。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1b|review-3-1b]]。V1 收尾时一般
continuous weak residual 仍是后备；当前 V2 已将其选为主线。exact-DtN center residual、
finite common-space transport、nearby simple
zero、matrix derivative 与 bordered conditioning 继续只属 OPTIONAL。不得自动调 basis/grid、
修改阈值或运行下一 attempt。

当前 [[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]] 已在保留 Git
历史的前提下重写为 V2：从同一 frozen QZ wall traces 出发，用真实材料的 conforming Q1
Dirichlet cell extension 形成全局 $H^1$ trial，再以 global RT0 flux 和 functional majorant
直接构造 continuous weak residual。正式 `weak-a1` 已完成：finite input、frozen-$P$
propagation、coarse/fine Q1--RT0、base Grams 与 full-$P$ tails 均通过；fine phase/scale repeat
随后因 center 的 $A,B$ Gram 及左右 first-cell 的 $A$ Gram 的 Hermitian defect 超过
$10^{-12}$ 而停止，最大 defect 为
$6.2442\times10^{-10}$。producer 状态为 `I3_1_MAJORANT_QUADRATURE_UNRESOLVED`，独立 verdict
为 `POST-RUN PASS / VALID NEGATIVE`。本 attempt 没有形成 scaled tail、refinement 或最终
estimator；独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1c|review-3-1c]]。

对历史 V2，遗留下一门是 scale-covariant Gram qualification。即使关闭该门，base coarse/fine 的
$B/\gamma$ component change 约 $0.277>0.20$，fine nominal width 约 $0.564\gg10^{-6}$；
mesh qualification 与有用分辨率仍未闭合。因此该 attempt 当时没有形成 I3.1 indicator。

现行 V3 设计
[[research/projects/eig-apost/implementation/i3/design-3-1d|design-3-1d]] 已获 Researcher
`AGREED` 与 Skeptic `DESIGN PASS`。它以真实 one-cell BIE incoming data、安全圆/墙
collar、全局 conforming Q1 companion、RT0 functional majorant 和 full-$P$ tail 重建弱残量。
历史 `bie-a1` 在进入 evaluator 前因旧接口字段缺失而停止；`bie-a2` 通过 safe-field evaluation
后因 MATLAB 转置结果索引语法而在 Q1 前停止。两个实现失败均以 append-only output 保留，且
Revision A/B 没有改变科学对象、参数、阈值或资源合同。

正式 `bie-a3` 已完成。finite input、branch/Wood、左右 propagation/scattering closure、BIE
density、one-sided surface trace 和 safe circle/wall evaluation 均通过。coarse Q1 maps 随后在
控制流中越过 form gate，但尚未写入 artifact；程序在第一个 coarse lead RT0-majorant factor
处停止，machine 状态为 `I3_1_HDIV_FLUX_UNRESOLVED`。失败矩阵已经含 true-circle polar
correction，而 integration-object gate 尚未先行检查，所以当前严格解释是 composite
RT0-majorant quadrature/assembly 未资格化，不能称为 $H(\mathrm{div})$ 理论失败。RT0 flux、
majorant 分量、full-$P$ tail、normalized indicator 和 prediction interval 均未形成。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]。I3.1 继续为
`ACTIVE / NO ESTIMATOR`；这是后来被 `fbie-a1` 更新的历史状态。

现行纯 BIE 路线
[[research/projects/eig-apost/implementation/i3/design-3-1e|design-3-1e]] 随后取消 Q1/RT0
体网格：共享 wall Dirichlet traces 驱动 finite-density exact rectangular-Green trial，数学上的
continuous radial collar 修复 circle value jump，wall/circle/collar residual 通过 full-$P$ tails
形成归一化指标。`pbie-a1` 是 warning schema 的 implementation failure；只作 typed-empty 修复的
正式 `pbie-a2` 已完成。普通双精度结果为 $q=1.1049370224693775\times10^{-10}$，名义 $k$
区间为 $[1.8327702889056474,1.8327702893106665]$，宽度
$4.0501912934587381\times10^{-10}$。但 wall $256\to512$ change 为 $0.2302$，nonzero-mode
$T$ manufactured oracle 最大误差为 $1.4439$，circle outside-$M$ share 为 $0.5147$。这三项
内部资格问题尚未闭合，所以 estimator 当时不能进入未来 I4.1 independent effectivity。512 点
continuity/H1、residual/field/tail outward bounds 与 projected gap 也均未认证；这些属于 I4.2 的 reliable
interval 与存在性问题。独立 verdict 为
`PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`，见
[[research/projects/eig-apost/implementation/i3/review-3-1e|review-3-1e]]。I3.1 因此已有
可计算 indicator candidate，但尚无经过内部资格并冻结的 empirical estimator；这是
`fbie-a1` 前的历史状态。

最新全边界路线
[[research/projects/eig-apost/implementation/i3/design-3-1f|design-3-1f]] 把 $M=48$ 限定为
共享 wall trace 输入，另用独立 $256/512$ wall response 与 circle action。正式、已消费的
`fbie-a1` 得到 wall/circle/value-lift components
$1.8732026085453917\times10^{-10}$、$2.9776880587814564\times10^{-15}$、
$4.246327820844503\times10^{-11}$，field lower $2.2269063318145634$，故
$q=1.0318643108971929\times10^{-10}$；名义 $k$ 区间为
$[1.83277028891904,1.8327702892972739]$。wall 和 actual $\Delta T$ checks 通过，所有 512 个
已计算 circle modes 都进入 $q$ 且 angular-tail 门通过；outside-$M$ share 降为描述性的
$0.036178900402764308$，未计算 Fourier tail 仍未 enclosure。唯一
nonblocking warning 是 circle action change $0.77408786032496468>0.20$，所以 estimator 仍不能
冻结后移交未来 I4.1。独立 verdict 为 `PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`，见
[[research/projects/eig-apost/implementation/i3/review-3-1f|review-3-1f]]。outward enclosure、
projected gap 和 reliable width 仍只属于 I4.2。

## I3.1：构造并内部论证可计算的误差指标

### 科学问题

能否从当前计算中实际可得的矩阵、向量、residual、相邻离散层差异或其他量，构造一个数值
$\eta_h$，并说明它为什么可能反映 $e_h^{\mathrm{gap}}$；若未来启用唯一目标升级，再说明它
怎样作用于 $e_h^*$？

### 输入

- I2 保存的 candidate、同一 mode 的公共表示和最低质量诊断；
- 连续算子、离散矩阵和两者关系中已经建立的数学结构；
- Phase 1 对真值误差、独立 reference 与内部有效性的定义；
- Phase 2 对非线性特征值扰动公式、相邻层修正和 continuous--discrete 缺口的核验结果。

Phase 2 的材料说明了若干可能的数学来源，但没有交付一个可直接沿用的 estimator。I3.1 必须
根据当前对象重新选择并推导实际公式，不能仅因某个量与目标误差同量纲就把它命名为误差估计。

### 必须完成的内部论证

I3.1 把误差来源识别并入指标构造，而不另设阶段。至少要逐项说明：

1. $\eta_h$ 的公式和所有可计算输入；
2. 公式依赖的假设；当前首选 residual 路线尤其要说明 continuous form、field conformity、
   dual norm 和 residual-to-spectrum 关系；
3. 它覆盖哪些误差，例如 field reconstruction、材料界面、边界离散、Fourier tail 或
   half-guide 近似；
4. 它忽略哪些误差，尤其是尚未建立的 continuous--discrete 误差和可能的共同偏差；
5. 单位、缩放、基底和相位改变是否会不合理地改变结果；
6. 推导恒等式、简化问题、manufactured problem、相邻层自洽性或负例等内部检查是否支持该
   公式；
7. 数值舍入、field evaluation、quadrature 和 Riesz solve error 怎样与 estimator 数值本身
   区分；
8. 若形成可靠谱区间，当前 continuous projected gap 的来源和参数映射是否匹配，区间是否
   完全落在 gap 内，以及其正频率宽度是否同时不超过看结果前冻结的绝对分辨率和 gap-relative
   宽度；
9. 是否真的需要命名一个唯一 mode；若不需要，不得把连续谱唯一性或 multiplicity-one 加成
   第一层 blocker。

这些都是内部证据：它们用于检查公式是否自洽，但不能用来证明它已经跟踪未知的连续谱误差。
I3.1 不得查看未来 I4.1 的独立 reference 后再选择公式、调常数或改变成功判据。

### 输出与结论边界

I3.1 的输出是一份冻结的 estimator specification，包括 $\eta_h$、覆盖范围、忽略项、假设、
内部检查和适用失败条件。若没有证明

$$
e_h^{\mathrm{gap}}=O(\eta_h),
$$

就只能称 $\eta_h$ 为“渐近误差指标”或“estimator candidate”。若它只预测下一层 candidate
变化，则必须称“next-level indicator/correction”，不能称 eigenvalue-error estimator。若要
把同一关系写给 $e_h^*$，还须先完成唯一目标升级。

I3.1 完成不表示 $\eta_h$ 已经有效；它只表示一个可计算、可证伪且可以在外部数据上检验的
对象已经冻结。

I3.1 同时冻结两层结论语义：第一层在可靠区间完全位于 continuous projected essential gap 且
宽度通过预注册门时，只声称区间内至少有一个连续离散特征值；第二层只有另有连续谱隔离或
计数时才命名唯一目标。gap containment 成立但区间过宽时，报告
`EXISTS_BUT_RESOLUTION_INSUFFICIENT`；唯一身份未建立不撤销第一层。

## I3.2：条件性离散证书谱包含定理

现行 [[research/projects/eig-apost/implementation/i3/design-3-2a|design-3-2a]] 与
[[research/projects/eig-apost/implementation/i3/review-3-2a|independent review]] 已建立：若有限
certificate $z_h$ 确定同一个非零连续 trial $u_h^{\mathrm c}=\mathcal T(z_h)\in V$，且严格 caps
证明

$$
\|R_h\|_{V'}\le\widetilde M_h+\epsilon_M,
\qquad
\|u_h^{\mathrm c}\|_V^2\ge\widetilde N_h-\epsilon_N>0,
$$

则

$$
\overline q_h=
\frac{\widetilde M_h+\epsilon_M}
{\sqrt{\widetilde N_h-\epsilon_N}}<1
$$

给出与 $\sigma(A)$ 相交的精确非对称区间。若该区间还完全落在同一算子的 certified projected
essential gap 内，则其中至少存在一个离散特征值；唯一身份不是前置条件。

`fbie-a1` 保存的 $\widetilde M_h=2.29786516751043\times10^{-10}$ 与
$\widetilde N_h=4.959111810675795$ 只是 ordinary-double 中心值。对预注册
$\tau_k=10^{-6}$，cap 预算要求

$$
\widetilde M_h+\epsilon_M
\le2.72811057103771594\times10^{-7}
\sqrt{\widetilde N_h-\epsilon_N}.
$$

该预算不是 strict cap。实际 outward residual/field/tail、same-operator gap 和 directed-rounded
application 仍 open，留给 I4.2。

### Same-trial empirical-cap application

[[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]] 固定同一个
certificate/trial identity，在不重新求解 candidate、QZ、propagation、density、Schur 或 proxy
的前提下比较预注册 nested evaluation levels。`ecap-a1` 是 integer/double identity-arithmetic
implementation failure。Revision E `ecap-a2` 通过 identity，并完成 7 个 image、3 个 circle、
3 个 wall 与 Riccati/Gauss levels；随后 retained active memory
$664.47068214416504$ MiB 超过 $640$ MiB hard limit，在 cap/full-$P$/$q$/interval 前停止。

已到达的 evaluation 另有三项资格失败：actual fixed-density $\Delta T$ image contraction
$2.2946515117026931>0.80$、finite-image physical Bloch
$0.071741947137921119>10^{-10}$、analytic-kernel aggregate `Inf`。因此当前正式状态是
`I3_2_RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED`，见
[[research/projects/eig-apost/implementation/i3/review-3-2b|review-3-2b]]。该 same-chain result
不是 outward bound，不能实例化上面的 strict hypotheses，也不能触发
`CONDITIONAL_SPECTRAL_INTERSECTION`。历史 circle-action $0.7741$ 只作 background；本轮没有
形成 empirical $\epsilon_M$、$\epsilon_N$、$q$ 或 nominal transform。

## 已迁移至 I4 的里程碑

原 I3.3、I3.4 的完整阶段定位、科学问题、输入、输出和结论边界现统一由
[[research/projects/eig-apost/implementation/i4/README|I4 guide]] 维护，分别映射为 I4.1、I4.2。
本页只保留上方 milestone 表中的历史条目和迁移状态，不再维护 I4 的详细规划。

## OPTIONAL

以下工作只有在当前 I3 或未来 I4 的主里程碑实际需要时才升级，不构成独立 stage：

- 额外参数、第二 mode、跨环境 parity 或泛化实验；
- exact finite Hermitian/Lagrangian 证明、第二套 root/count 方法或大范围复平面扫描；
- 与所选 $\eta_h$ 无关的完整 adjoint、transport、Gram 或 structure-preserving 理论；
- saved candidate 到 finite zero 或相邻 projected finite roots 的 one-step correction；
- 多套 reference 或 enclosure 方法的横向比较。

## 权威入口与后续设计顺序

推荐按以下顺序阅读：

1. [[research/projects/eig-apost/implementation/i2/report|I2 stage report]]：I3 的 candidate 与质量输入；
2. [[research/projects/eig-apost/phase1-scope/rq-summary|Phase 1 research question]]、
   [[research/projects/eig-apost/phase1-scope/p-method|Phase 1 method]] 和
   [[research/projects/eig-apost/phase1-scope/materials|Phase 1 error-source notes]]：目标误差与
   independent-reference 原则；
3. [[research/projects/eig-apost/phase2-sources/synthesis-dtn|Phase 2 DtN synthesis]]、
   [[research/projects/eig-apost/phase2-sources/r-nep-error|Phase 2 NEP error review]] 和
   [[research/projects/eig-apost/phase2-sources/r-da2|Phase 2 independent-reference audit]]：
   已核验的扰动公式来源、reference 独立性边界及尚未闭合的假设；
4. [[research/projects/eig-apost/implementation/open-problems#Current I3|Current I3 ledger]]：
   当前 blocker；
5. [[research/projects/eig-apost/implementation/i3/design-3-1|I3.1 frozen baseline design]]、
   [[research/projects/eig-apost/implementation/i3/review-3-1|I3.1 independent review]] 与
   [[test/i3/s-resid/README|I3.1 experiment index]]：首个连续强残量 baseline；
6. [[research/projects/eig-apost/implementation/i3/design-3-1b|I3.1 Q1--RT0 weak-residual V2 design]]：
   已完成 `weak-a1`；其
   [[research/projects/eig-apost/implementation/i3/review-3-1c|independent post-run review]] 与
   [[test/i3/w-resid/README|experiment index]] 记录 phase/scale Gram 首败。历史 BIE V1 的正式
   负结果由
   [[research/projects/eig-apost/implementation/i3/review-3-1b|independent post-run review]] 与
   [[test/i3/g-resid/README|experiment index]] 承载；
7. [[research/projects/eig-apost/implementation/i3/design-3-1e|I3.1 pure-BIE design]]、
   [[research/projects/eig-apost/implementation/i3/review-3-1e|independent post-run review]] 与
   [[test/i3/p-resid/README|experiment index]]：首个 finite pure-BIE indicator 及其历史资格问题；
8. [[research/projects/eig-apost/implementation/i3/design-3-1f|full-boundary design]]、
   [[research/projects/eig-apost/implementation/i3/review-3-1f|post-run review]] 与
   [[test/i3/fb-resid/README|experiment index]]：当前 indicator、circle-action caveat 与
   ordinary/strict 分层边界；
9. [[research/projects/eig-apost/implementation/i3/design-3-2a|I3.2 theorem design]] 与
   [[research/projects/eig-apost/implementation/i3/review-3-2a|independent review]]：条件性定理、
   cap budget 和 application obligations；
10. [[research/projects/eig-apost/implementation/i3/design-3-2b|same-trial cap design]]、
    [[research/projects/eig-apost/implementation/i3/review-3-2b|post-run review]] 与
    [[test/i3/e-cap/README|experiment index]]：固定 certificate 的 evaluation、资源首败、三项
    qualification failures 与未到达的 cap/$q$/interval；
11. [[research/projects/eig-apost/implementation/ROADMAP|implementation roadmap]]：项目级顺序。

I3.2 条件性定理已经建立；其 same-trial `ecap-a2` application 已消费并以
`RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED` 收口。identity/evaluation 到达，
cap/full-$P$/$q$/interval 未到达；actual-$\Delta T$、finite-image Bloch 与 analytic-kernel
qualification 未通过。原 I3.3、I3.4 已分别迁移至未来 I4.1、I4.2，必须另行冻结且当前均
未启动。当前结果不自动授权下一 attempt。
