# Eigenvalue a posteriori implementation

## 当前状态

当前新路线处于 `I3_1_PRELIMINARY_OBJECTIVE_ACHIEVED / COMPUTED_ESTIMATOR_CANDIDATE`；I3.2
条件性证书谱包含定理已经建立，same-trial empirical-cap application 则由 `ecap-a2` 给出
`RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED`。该 run 完成 evaluation 后在 cap、
full-$P$、$q$ 和 interval 前超过 $640$ MiB hard limit。I3.3 只负责 independent
reference/effectivity，可靠 enclosure/gap 属于 I3.4。其输入阶段 I2 已以
`I2_3_PASS_WITH_CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE` 收口。精确
half-guide DtN 由半无限边值问题定义，连续中心算子 $\mathcal F(k)$ 在任何
BIE/Fourier 截断和 ordered QZ 之前定义真实谱对象。现行数学权威是
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]，离散
$A_{\mathrm{def}}$ 的离散来源位于
[[research/projects/eig-apost/implementation/i1/README|i1/]]，当前 candidate 资格与跨离散阶数漂移规划位于
[[research/projects/eig-apost/implementation/i2/README|i2/]]。

I1.2 的 manufactured、MATLAB $M=5,8$ mechanism 与 direct $M=48$ static arms 已通过；
I1.3 又完成 real-$k$ 连续性、分层筛查和 width-driven 局部加密，记录 fixed-$M=48$
离散候选 $k=1.8327703475952146$ 与 $q=8.3200886232193094\times10^{-8}$。I1.4 随后在
冻结小复圆盘上完成 sampled anchored branch、QZ/graph/DtN、factor、closure、CR 和负例门；
V5 条件闭合只解决对称模型无法识别的 transmission-order assembly negative。I2.1 随后在
同一 fine、$M=48$ 圆盘上运行 factor-aware determinant winding：全部实际 inverse factors
得到嵌套 zero winding，主 $A_{\mathrm{def}}^D$ 在 32/64 点网格上均得到 count one。该结果只
是条件性 finite-dimensional algebraic zero count；尚未定位 root，production derivative 仍未
资格化。I2.2 曾优先审查实直径上奇异等价的有限维 Dirichlet-coordinate mismatch 与 endpoint
inertia；其第一轮 diagnostic-only 两肩 preflight 已完成并以
`PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE` 收口：点态对象关系与 near-Hermitian
diagnostics 通过实现检查，但 exact finite half-guide Hermitian 和 whole-interval same-family
证明未闭合，故 inertia 返回 unavailable。不能声称
continuous physical eigenvalue 或 estimator。

2026-08-13 路线复审把项目压缩回两个最终目标：提出 continuous physical eigenvalue candidate，
并估计该 candidate 到真实连续特征值的误差，进一步研究可计算上界。上述 STOP 只否定 raw
finite $H$ 的定理级 inertia 解释；I2.2 仍可在同一已知端点完成明确标注的
sign-count/inertia-like 数值诊断；该诊断现已得到稳定 `SINGLE_JUMP`，用于提高 candidate
可信度。它不重复 I1.3 scan，
不证明 exact discrete real root，也不扩张 finite Hermitian 理论。I2.3 在预先冻结的不同离散
阶数上比较同一物理 mode 的 candidate，报告 candidate 漂移、terminal-cell/minimizer-
localization diagnostic 及最低必要的 residual、factor、field、boundary 和 mode-identity
诊断。`drift-a1` 的 $n_{\mathrm{tot}}=160,208,256$ 轴与 `m-drift-a2` 的
固定 $n_{\mathrm{tot}}=160$、$M=32,40,48$ 轴均确认 `SAME_MODE`，且各轴保存的 candidate
完全相同，故 observed candidate drift 为零。终端半宽只描述潜在 sub-grid score minimizer 的搜索分辨率，
不是 candidate uncertainty。当前形成 conditional algorithmic candidate hierarchy。I3.1 已
完成首个中心空列 continuous strong-residual baseline：固定单胞 cutoff 场给出的 computed ratio
为 $22.43882099031153$，数值积分稳定，但 cutoff 导数项主导且名义区间跨过零，故结论为
`FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`。这一负结果没有形成可靠存在区间，也不能实例化
现行 I3.2 theorem。历史 V1 的全波导 BIE-informed Fourier--Hermite/bubble trial
随后完成实现与正式 `lead-a3`。finite input、density representation 和 propagation
通过，但固定 fit 的 $J=4/8$ holdout error 分别约为 $4.522421/5.138028$，故在
`CONFORMING_RECONSTRUCTION_UNRESOLVED` 首败处停止，尚未形成通过资格的全波导 continuous
trial/residual 或 estimator。近圆 targets 相对 source-panel arc scale 过近且 direct close evaluation 未资格化，
所以失败原因仍不能在近奇异评价与 basis/metric 之间区分；不自动启动下一 attempt。当前
[[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]] 已在保留 Git 历史的
前提下改写为 QZ wall-trace、conforming Q1 cell extension、global RT0 flux 和 weak-residual
majorant 的 V2 设计。正式 `weak-a1` 的 base finite input、Q1--RT0 和 full-$P$ tails 通过，
但 fine phase/scale repeat 的 center 的 $A,B$ Gram 及左右 first-cell 的 $A$ Gram Hermitian
qualification 失败，最大 defect
为 $6.2442\times10^{-10}>10^{-12}$；状态为 `POST-RUN PASS / VALID NEGATIVE /`
`MAJORANT_QUADRATURE_UNRESOLVED`。没有形成 estimator；这是当前 I3.1 结论前的历史负结果。该 V2 路线的下一门是
scale-covariant Gram qualification；即使关闭，mesh change 与过宽 nominal interval 仍须处理。
`lead-a3` 的 V1 历史结论继续由独立 review 与 append-only output 承载。
V3 [[research/projects/eig-apost/implementation/i3/design-3-1d|design-3-1d]] 随后改用真实
$(a_L,b_R)$ incoming、one-sided BIE traces、安全 collars、conforming Q1 companion 与 RT0
majorant。正式 `bie-a3` 通过 finite input、branch/Wood、propagation、density、surface trace
和 safe-field 门，但在 coarse lead 的 composite RT0-majorant 预因子处停止。machine 状态为
`HDIV_FLUX_UNRESOLVED`；独立复核将其限定为含 polar disk correction 的 quadrature/assembly
对象未资格化，而非 $H(\mathrm{div})$ 理论失败。没有形成 majorant、tail、indicator 或区间；
详见 [[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]。
纯 BIE [[research/projects/eig-apost/implementation/i3/design-3-1e|design-3-1e]] 随后避开 Q1/RT0，
以 shared wall traces、finite-density exact rectangular-Green trial、value-only circle collar 和
full-$P$ boundary Grams 直接计算 weak-residual indicator。`pbie-a1` 是 typed-warning schema 的
implementation failure；正式 `pbie-a2` 得到 $q=1.1049370224693775\times10^{-10}$ 及宽度
$4.0501912934587381\times10^{-10}$ 的普通双精度名义区间。wall refinement $0.2302$、nonzero-mode
$T$ oracle 最大误差 $1.4439$ 和 outside-$M$ share $0.5147$ 使 verdict 只能为
`PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`。该 attempt 当时的 wall/T/outside-$M$
三项 warnings 解释其历史 verdict；outward enclosure 与 continuous projected gap 现属 I3.4。
详见
[[research/projects/eig-apost/implementation/i3/review-3-1e|review-3-1e]]。
最新全边界胞元 BIE
[[research/projects/eig-apost/implementation/i3/design-3-1f|design-3-1f]] 将 $M=48$ 只用于
wall trace 输入，并独立计算 full wall/circle response。正式 `fbie-a1` 已消费，得到
$q=1.0318643108971929\times10^{-10}$ 和宽度 $3.7823388865376728\times10^{-10}$ 的普通双精度
名义区间。wall、actual $\Delta T$、Grams、tails 与 phase/scale checks 通过；所有 512 个已计算
circle modes 进入 $q$ 且 angular-tail 门通过，未计算 Fourier tail 仍未 enclosure；
唯一 warning 是 circle action change $0.77408786032496468>0.20$。因此 I3.1 已有
`COMPUTED ESTIMATOR CANDIDATE`，但普通数值仍 `NUMERICALLY_UNQUALIFIED`。该 warning 不阻止
I3.2 theorem。same-trial cap 的正式 `ecap-a2` 通过 identity 并完成 evaluation，但以
$664.470682>640$ MiB 资源门停止，因此 cap 未计算。actual-$\Delta T$、finite-image Bloch 和
analytic-kernel 资格也未通过；按冻结 component gates，这些 fail-open warnings 会保存 raw
diagnostics，但也使相应 empirical cap unresolved。I3.4 的
outward/gap 条件仍独立未闭合。I3.2 见
[[research/projects/eig-apost/implementation/i3/design-3-2a|design-3-2a]]、
[[research/projects/eig-apost/implementation/i3/review-3-2a|review-3-2a]]、
[[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]] 与
[[research/projects/eig-apost/implementation/i3/review-3-2b|review-3-2b]]。
finite one-step root correction 仍为
OPTIONAL。第一层只要求可靠区间进入
current continuous projected gap，并通过
结果前冻结的 absolute/gap-relative resolution，从而证明其中至少存在一个连续离散特征值；
唯一目标识别只在指定-mode升级时需要。两条 I2 轴不能单独提供非零 correction、minimizer/root drift、
收敛阶或误差上界。

OP-M0-1--OP-M0-4 继续限制 continuous physical theorem 与上界解释，但不阻止提出带诚实
claim boundary 的 candidate。最新行动边界以
[[research/projects/eig-apost/STATUS|project STATUS]] 为准。

## 分级目录

```text
implementation/
├── README.md
├── ROADMAP.md
├── SYMBOL.md
├── open-problems.md
├── i1/
│   ├── README.md
│   ├── design.md
│   └── review.md
├── i2/
│   ├── README.md
│   ├── design.md
│   ├── design-2-2.md
│   ├── design-2-3.md
│   ├── design-2-3m.md
│   ├── review.md
│   ├── review-2-2.md
│   ├── review-2-3.md
│   └── review-2-3m.md
├── i3/
│   ├── README.md
│   ├── design-3-1.md
│   ├── review-3-1.md
│   ├── design-3-1b.md
│   ├── review-3-1b.md
│   ├── review-3-1c.md
│   ├── design-3-1d.md
│   ├── review-3-1d.md
│   ├── design-3-1e.md
│   ├── review-3-1e.md
│   ├── design-3-1f.md
│   ├── review-3-1f.md
│   ├── design-3-2a.md
│   └── review-3-2a.md
└── archive/
    └── legacy-route-v1/
        ├── README.md
        ├── i0-manufactured/
        ├── i1-finite-tail/
        ├── i2-aug-bie/
        ├── i3-provenance/
        └── i4-numerical-qualification/
```

- [[research/projects/eig-apost/implementation/i1/README|i1/]]：已完成的离散算子与 sampled
  root-readiness 阶段。
- [[research/projects/eig-apost/implementation/i2/README|i2/]]：I2.1--I2.3 已完成；维护三个有
  独立科学问题的内部里程碑，并由
  [[research/projects/eig-apost/implementation/i2/report|I2 stage report]] 综合向尚未启动的 I3
  交付两条 conditional hierarchy。
- [[research/projects/eig-apost/implementation/i3/README|i3/]]：维护 candidate 误差估计、
  independent truth comparison 和上界可行性的目标、输入与预期输出；中心空列强残量
  baseline 分辨率不足，lead-aware reconstruction 在 BIE-informed fit 首败，Q1--RT0 V2 又在
  phase/scale Gram qualification 首败；BIE-collar V3 随后在含材料圆修正的 RT0-majorant
  pre-factor 首败；纯 BIE `pbie-a2` 随后形成首个 finite indicator。最新全边界 `fbie-a1`
  关闭旧 wall/$T$/outside-$M$ 问题，但 circle-action refinement 未通过。I3.1 已完成 preliminary
  objective；I3.2 conditional theorem 已建立。same-trial `ecap-a2` 已在 I3.2 内尝试 empirical
  cap，但资源硬门使本次 cap 未计算；三项 fail-open qualification failures 也会使相应 cap
  unresolved。I3.3 只做
  independent reference/effectivity，可靠 enclosure 留给 I3.4。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只维护新路线 I1--I3
  的项目级依赖和退出条件。
- [[research/projects/eig-apost/implementation/SYMBOL|SYMBOL.md]]：集中说明跨阶段缩写、
  数学对象、code variable 和稳定标签。
- [[research/projects/eig-apost/implementation/open-problems|open-problems.md]]：本专题唯一
  open-problem ledger；明确区分当前新路线与历史实验编号。
- [[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]]：
  保存旧路线 I0--I4 的完整 design、result、review 和原索引；旧编号和 verdict 不构成
  当前授权。
- [[test/README|current test index]]：记录新路线 I1.2--I3.1 实验状态；当前实验位于
  `test/i1/hg-adef/`、`test/i1/k-scan/`、`test/i1/k-ready/`、`test/i2/k-count/` 和
  `test/i2/h-inertia/`、`test/i2/k-drift/`、`test/i2/m-drift/`、`test/i3/s-resid/` 与
  `test/i3/g-resid/`、`test/i3/w-resid/`、`test/i3/b-resid/` 与 `test/i3/p-resid/`。旧实验统一由
  [[test/archive/legacy-route-v1/README|legacy experiment index]] 保存。

## 阶段文档规则

当前新路线的阶段目录直接位于 `implementation/iN/`，不再增加 `current/` 中间层，也不为
内部里程碑或小实验创建并列阶段目录。阶段目录按实际内容使用：`README.md` 维护状态、
阅读顺序和入口；`design.md` 冻结共享设计；只有产生实际数值结果后才创建 `result.md`；
`review.md` 记录阶段级审查与授权边界。

具体实验的代码、配置、报告和产物仍保存在 `test/`，implementation 只负责索引与综合。
历史阶段统一保存在 `archive/legacy-route-v1/`；不得把新路线 I1--I3 的编号机械写回旧
I1--I4 文档、实验 ID 或冻结 verdict。

### 长期压缩规则

- 每个大阶段的正式内部里程碑通常以 4 个为宜，任何情况下不得超过 5 个；“4 个为宜”是
  压缩经验，不是最低数量要求。
- 每个 milestone 必须回答一个独立科学问题；若两个项目没有独立问题或后一项只是前一项的
  文档交接，不得为了凑数拆成两个 milestone。
- 只有真实阻止当前交付或下一次必要计算的问题才能形成正式 milestone；其他有价值检查统一
  放入 `OPTIONAL`。
- 当前只较具体维护 I2。I2 之后只写目标、输入、预期输出和 claim ladder，具体算法、参数与
  验收流程等待 I2 实际结果后再冻结。
- 阶段文档必须说明每个大阶段为“提出 candidate—估计真值误差—研究上界”解决什么；不得只用
  transport、denominator、effectivity 或 consistency 等术语代替问题说明。

## 推荐阅读顺序

1. [[research/projects/eig-apost/STATUS|project STATUS]]：确认当前阶段和禁止事项。
2. [[research/projects/eig-apost/implementation/ROADMAP|project roadmap]]：确认新路线
   I1--I3 的依赖。
3. [[research/projects/eig-apost/implementation/i1/README|current I1 guide]]：确认内部
   里程碑和授权边界。
4. [[research/projects/eig-apost/implementation/i2/README|current I2 guide]]、
   [[research/projects/eig-apost/implementation/i2/report|I2 stage report]] 与
   [[research/projects/eig-apost/implementation/i2/review|I2.1 review]]：确认 count-one 结果；
   再读 [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]] 与
   [[research/projects/eig-apost/implementation/i2/review-2-2|I2.2 review]]，最后读
   [[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 design]]、
   [[research/projects/eig-apost/implementation/i2/review-2-3|I2.3 review]] 与
   [[test/i2/k-drift/README|I2.3 ntot-axis experiment index]]；再读
   [[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 M-axis design]]、
   [[research/projects/eig-apost/implementation/i2/review-2-3m|I2.3 M-axis review]] 与
   [[test/i2/m-drift/README|I2.3 M-axis experiment index]]。
5. [[research/projects/eig-apost/implementation/i3/README|I3 guide]]：确认 candidate、error
   estimate、independent truth 和 upper-bound claim ladder；再读
   [[research/projects/eig-apost/implementation/i3/review-3-1f|full-boundary BIE post-run review]]，
   再读 [[research/projects/eig-apost/implementation/i3/design-3-2a|I3.2 theorem design]] 与
   [[research/projects/eig-apost/implementation/i3/review-3-2a|independent theorem review]]，确认
   ordinary indicator、strict cap theorem 与 reliable-application boundary。
6. [[research/projects/eig-apost/implementation/i1/design|discrete A-def design]]：阅读当前
   离散空间、QZ/graph/DtN 链和组装合同。
7. [[research/projects/eig-apost/implementation/i1/review|current I1 review]]：核对审查结论
   和 caveat。
8. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]：查看仍限制
   physical/root 解释的 blocker。
9. [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]：阅读
   continuous self-adjoint real-spectrum 依据、离散误差分层与 correction 方法。
10. [[research/projects/eig-apost/implementation/SYMBOL|symbol and code-variable ledger]] 和
   [[test/README|current experiment index]]：查询符号与新路线实验状态。
11. 只有需要追溯历史设计、结果和审查时，再进入
   [[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]]。

## Legacy route v1 证据边界

被新路线取代的是 finite-tail/远端闭合对 half-guide 的主定义、旧 augmented-BIE/
finite-tail coupling，以及旧 $A_{\mathrm{def}}$/locator 授权链。它们不再定义当前谱问题
或 estimator。

仍可参考的 legacy 证据包括 manufactured NEP 算法 oracle、center-BIE block/scaling 和
provenance 机制、Fliss 参数窗口、Rayleigh budget 与失败负例，以及冻结参数下的 Linton
Ewald value/gradient/Hessian、MATLAB `lsqminnorm`、`proxy_dist/d=0.2`、四种 SLP/DLP
action 的 Ewald/MFS/Rayleigh 三路径比较和有限 $M_{\mathrm{trace}}=48$ screen。后两类只
认证冻结几何、制造密度、solver 和有限 $M_{\mathrm{ref}}=96$，不是当前 DtN、任意 solved
density、无限尾或 root 的认证。

具体报告与原始产物统一从
[[test/archive/legacy-route-v1/README|legacy experiment index]] 进入；implementation 侧的
阶段索引见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]]。
