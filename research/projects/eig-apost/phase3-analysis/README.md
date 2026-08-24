# Phase 3：I3.1 连续物理残量路线

本目录先研究 I2 实际保存的 numerical candidate $\widehat k_h$ 到当前 continuous projected
gap 内正离散特征频率集合的距离

$$
e_h^{\mathrm{gap}}
=\operatorname{dist}\bigl(\widehat k_h,
\mathcal K_{\mathrm{disc}}(A;G_\lambda)\bigr),
$$

其中 $G_\lambda\subset(0,\infty)$ 是需要针对当前模型认证的 continuous projected essential
gap，且
$\mathcal K_{\mathrm{disc}}(A;G_\lambda)
=\{\sqrt{\lambda}:\lambda\in\sigma_{\mathrm{disc}}(A)\cap G_\lambda\}$。
只有确需跟踪特定 mode 时，才升级到 $e_h^*=|k_*-\widehat k_h|$。

I3.1 的主线必须直接服务这个误差。有限矩阵的精确零点、连续 score minimizer 和相邻有限层
零点位移都不是项目最终交付物；只有当它们确实进入上述连续谱误差的估计时，才可作为辅助量。

## 当前路线

本轮撤下 finite one-step projected-root correction 的主线地位。即使其有限维扰动公式完全
成立，它也只预测 saved candidate 到某个有限矩阵零点、或相邻 projected finite family
零点之间的位移，不能控制两个离散层共有的偏差。I2.3 已直接比较算法保存的 candidates，
所以继续把该有限根位移作为 I3.1 的前置对象会重复有限层内部问题。

当前选定的最短路线是：

1. 取 I2 已保存的 $\widehat k_h$，令 $\mu_h=\widehat k_h^2$；
2. 从 I2 的 frozen QZ/Rayleigh state 形成共享 wall Dirichlet traces，用 finite trigonometric
   density 与数学上精确的 rectangular Dirichlet Green kernel 定义分片 trial；
3. 用数学上的 continuous radial collar 修复 circle value jump，把 wall/circle normal jumps 与
   collar volume source 组成 continuous weak-residual indicator candidate；
4. 以 full-$P$ Gram/doubling 显式控制左右 infinite tail，并分别检查 phase/scale、wall/circle
   refinement 和数值 enclosure；
5. 若可靠 residual interval 完全位于当前连续算子的 projected essential gap，则先得到区间内
   至少存在一个连续离散特征值；只有区间宽度不超过看结果前冻结的频率分辨率，才接受为
   第一层分辨率级结论；
6. I3.2 已建立严格的条件性离散证书谱包含定理；I3.3 再研究 empirical error caps 与独立
   effectivity，I3.4 才实例化可靠 enclosure、projected gap 和存在性条件。若未来确需指定
   某个 mode，再另做唯一目标识别。

当前主线是纯 BIE conforming weak residual：shared wall traces、finite-density exact-kernel
trial、value-only circle collar 与 boundary dual weights 直接给出 residual indicator candidate，
无需 Q1/RT0 体网格。现行
[[research/projects/eig-apost/implementation/i3/design-3-1e|pure-BIE design]] 给出对象与实现
合同；V2 wall-trace Q1--RT0、V3 BIE-collar Q1--RT0 和此前的强残量 reconstruction 都作为
历史负向路线保留在
[[research/projects/eig-apost/phase3-analysis/s-lead-field|Global lead-aware conforming trial]]
及其 post-run review 中。

此前 homogeneous empty center column 提供了一个可立即检查的特殊情形。
首个冻结实验把该空列中的有限 Fourier 场乘以固定
$\chi(x)=\cos^2(\pi x)$ 并在单胞外延零，由于 $\chi=\chi'=0$ 于端点，得到的场属于强算子
定义域。因而 `center-a1` 可以直接计算 continuous strong residual，而无需先完成一般 lead-field
repair 或 Riesz dual-norm solve。

该 baseline 得到 computed ratio $22.43882099031153$。普通 Simpson 加密稳定，但没有给出可靠
积分 enclosure；更重要的是，固定单胞 cutoff 的导数项主导 residual，名义区间跨过零并远宽于
预注册频率分辨率。因此它是一个有效的 `FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT` 负结果，
不是可移交给按当时编号之旧 I3.2 empirical validation 的 estimator。随后 I3.1 使用全局
BIE-informed smooth trial 取消 fixed-cell
cutoff；它没有继续调节同一个过宽 baseline。

正式 `lead-a3` 通过 finite input、density representation 和 frozen-$Z$ propagation，但固定
BIE-informed fit 的独立 holdout error 在 $J=4$ 为约 $4.522421$，在 $J=8$ 增至约
$5.138028$，高于预注册 $0.20$。因此程序按冻结优先级停止于
`CONFORMING_RECONSTRUCTION_UNRESOLVED`，没有进入 center correction、Gram、quadrature、tail
或 strong-residual ratio。training/holdout targets 距材料圆仅约 source-panel arc scale 的
$0.86\%/1.08\%$，direct close layer-potential evaluation 未单独资格化；目前只能判定 pipeline
没有建立 BIE-informed shape quality，不能把原因单独归于 bubble basis 或 fit metric。

同名 [[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]] 当前已在保留
Git 历史的前提下重写为 Q1--RT0 weak-residual V2，并已完成正式 `weak-a1`。base finite
input、frozen-$P$ propagation、coarse/fine Q1--RT0、Grams 与 full-$P$ tails 通过；fine
phase/scale repeat 的 center 的 $A,B$ Gram 及左右 first-cell 的 $A$ Gram Hermitian defect 最大为
$6.2442\times10^{-10}>10^{-12}$，故 producer 停止于
`MAJORANT_QUADRATURE_UNRESOLVED`。该结果不改变 `lead-a3` 的 V1 machine verdict 与
append-only output。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1c|review-3-1c]]。

对历史 V2，遗留下一门是 scale-covariant Gram qualification。即使关闭，base diagnostics 已显示
$B/\gamma$ coarse/fine change 约 $0.277>0.20$，fine nominal width 约
$0.564\gg10^{-6}$；mesh 与 width 仍未闭合。

V3 正式 `bie-a3` 已进一步关闭 V1 的 true-incoming 与 near-circle direct-evaluation 问题。
finite input、branch/Wood、whole-subspace propagation、BIE density、one-sided surface trace 与
safe circle/wall evaluation 均通过；程序在 coarse lead 的 composite RT0-majorant factor 前
停止，machine 状态为 `HDIV_FLUX_UNRESOLVED`。因为该矩阵已经含 true-circle polar correction，
而 integration-object gate 尚未先行检查，独立审查只把它解释为 quadrature/assembly blocker，
不称 $H(\mathrm{div})$ 理论失败。RT0 flux、majorant、tail、indicator 与 interval 均未形成；
详见 [[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]。

纯 BIE 正式 `pbie-a2` 已首次形成可计算 indicator candidate。三个 residual components 的
triangle sum 为 $2.4605912515933872\times10^{-10}$，field lower candidate 为
$2.2269063318145634$，故 $q=1.1049370224693775\times10^{-10}$；名义 $k$ 区间宽度为
$4.0501912934587381\times10^{-10}$。但 wall $256\to512$ change 为 $0.2302$，nonzero-mode
$T$ oracle 最大误差为 $1.4439$，circle outside-$M$ share 为 $0.5147$。这三项内部资格问题使
ordinary estimator 尚未获得内部数值资格。512 点 continuity/$H^1$ 和全部 outward reliability
flags 也未认证；前者是未来 I3.3 empirical-cap 设计的证据问题，后者属于 I3.4 的 reliable
interval 与存在性问题。当前 verdict 是
`PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`，不是 reliable interval 或存在性结论；详见
[[research/projects/eig-apost/implementation/i3/review-3-1e|review-3-1e]]。

全边界胞元 BIE `fbie-a1` 随后把 $M=48$ 限定为 wall-trace 输入，并用独立 $256/512$ wall
response 与 circle action 检查同一 finite-density exact-kernel trial。它得到
$q=1.0318643108971929\times10^{-10}$ 和宽度 $3.7823388865376728\times10^{-10}$ 的普通双精度
名义区间。wall、actual $\Delta T$、Grams 与 full-$P$ tails 均通过；全部 512 个已计算 circle
modes 进入 $q$ 且 angular-tail 门通过，未计算 Fourier tail 仍未 enclosure；唯一
warning 是 circle action change $0.77408786032496468>0.20$。因此旧 wall/$T$/outside-$M$
问题不再是当前门，但 ordinary candidate 仍未获得内部数值资格；该 caveat 是未来 I3.3
empirical-cap/effectivity 的目标，不阻止 I3.2 条件性定理。outside-$M$ share 为 $3.6179\%$，
所有 512 个已计算 circle modes 都已进入 $q$；它不是遗漏误差。见
[[research/projects/eig-apost/implementation/i3/review-3-1f|review-3-1f]]。

## 阅读顺序

1. [[research/projects/eig-apost/phase3-analysis/s-estimator|Continuous residual estimator theory]]：
   连续弱残量、谱距离命题、gap 内存在性、预注册分辨率与可选唯一目标识别；
2. [[research/projects/eig-apost/implementation/i3/design-3-1f|Full-boundary BIE design]]
   与 [[research/projects/eig-apost/implementation/i3/review-3-1f|post-run review]]：当前从 shared
   wall traces 到 independent wall/circle response、ordinary-double indicator、circle-action
   首败与 outward-enclosure blocker；[[research/projects/eig-apost/phase3-analysis/s-lead-field|旧 lead-aware strong-residual
   theory]] 只保留历史解释；
3. [[research/projects/eig-apost/implementation/i3/design-3-2a|Conditional certificate theorem]]
   与 [[research/projects/eig-apost/implementation/i3/review-3-2a|independent theorem review]]：
   exact certificate-to-trial map、strict cap theorem、ordinary budget 和 application obligations；
4. [[research/projects/eig-apost/phase3-analysis/s-dtn-chain|Exact/numerical DtN boundary]]：
   exact half-guide theory、finite QZ/BIE 的适用边界和后备 weak-residual 路线；
5. [[research/projects/eig-apost/phase3-analysis/s-root|Existence and target identification]]：
   saved candidate、可靠谱区间、gap 内离散特征值和指定目标的区别；
6. [[research/projects/eig-apost/phase3-analysis/s-errors|Coverage and omitted errors]]：
   residual 覆盖、数值近似和遗漏项；
7. [[research/projects/eig-apost/phase3-analysis/p-implement|Design readiness]]：进入
   新实验实现前真正需要关闭的最小条件。

`p-benchmark.md` 属于 I3.3 的独立 reference/effectivity 问题，`p-paper.md` 属于结果形成后的写作问题。
它们不得参与 I3.1 公式选择和调节。

## OPTIONAL finite-matrix diagnostics

原有限维一步公式仍可用于两个局部问题：saved grid candidate 到附近有限矩阵零点的位移，
以及某一离散加密对有限矩阵零点的一阶影响。它需要共同空间、附近简单零点、左右向量、
完整 $k$ 导数和非零横截斜率。只有实际启用该诊断时，这些条件才成为其局部门槛。

该诊断不得称为 continuous-eigenvalue error estimator，不得阻止 continuous-residual 主线，也不得成为
新实验的 readiness gate。

## 当前状态

- 理论方向：`CONTINUOUS RESIDUAL MAINLINE`；
- 已闭合：残量到某个连续谱点距离的抽象自伴谱命题；中心空列 compact-support 强残量
  baseline 的连续定义域和残量公式；
- 已完成实验：[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 的
  `center-a1`，独立结论见
  [[research/projects/eig-apost/implementation/i3/review-3-1|review-3-1]]；
- 已完成历史 BIE-informed single smooth Fourier--Hermite/bubble 路线的正式负结果：
  `lead-a3` 通过 finite/density/propagation 门后在 fixed holdout fit 首败；独立结论见
  [[research/projects/eig-apost/implementation/i3/review-3-1b|review-3-1b]]；
- 已完成 Q1--RT0 V2：[[research/projects/eig-apost/implementation/i3/design-3-1b|design]] 的
  `weak-a1` 在 phase/scale Gram qualification 首败；独立结论见
  [[research/projects/eig-apost/implementation/i3/review-3-1c|review-3-1c]]；
- 已完成 BIE-collar V3：[[research/projects/eig-apost/implementation/i3/design-3-1d|design]] 的
  `bie-a3` 在 composite RT0-majorant quadrature/assembly 首败；独立结论见
  [[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]；
- I3.2：条件性离散证书谱包含定理已建立；严格 cap 的 application hypotheses 尚未闭合，
  但本轮不实例化也不运行实验；
- 当前 I3.3 target：circle action $256\to512$ ratio $0.77408786032496468>0.20$；actual
  $T$、wall refinement 与 512-mode angular-tail checks 已通过，未计算 Fourier tail 仍未 enclosure；
- 当前 I3.4 blocker：512 trace/collar、residual/field/tail 的 outward numerical enclosure，以及
  sharp-disk continuous projected gap 和预注册宽度条件尚未闭合；
- 第一层目标：可靠区间进入 projected gap，且其正频率宽度不超过预注册分辨率；
- 第二层可选升级：只有确需命名某个 mode 时才证明唯一目标身份；
- I3.1 当前状态：`PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`；
- 自 2026-08-24 起，旧 I3.2 顺延为 I3.3，旧 I3.3 顺延为 I3.4；历史设计、review、attempt
  tag 和 output 仍保留其原编号。
