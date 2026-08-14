# Eigenvalue a posteriori implementation

## 当前状态

当前新路线处于
`I2_3_PASS_WITH_CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。精确
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
不是 candidate uncertainty。当前形成 conditional algorithmic candidate hierarchy，I3 可以
开始误差来源与 independent-reference 设计；但该轴不能单独提供非零 next-level correction、
minimizer/root drift、收敛阶或误差上界。

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
│   └── README.md
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
  独立科学问题的内部里程碑，并向尚未启动的 I3 交付两条 conditional hierarchy。
- [[research/projects/eig-apost/implementation/i3/README|i3/]]：维护 candidate 误差估计、
  independent truth comparison 和上界可行性的目标、输入与预期输出；尚未冻结实验细节。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只维护新路线 I1--I3
  的项目级依赖和退出条件。
- [[research/projects/eig-apost/implementation/SYMBOL|SYMBOL.md]]：集中说明跨阶段缩写、
  数学对象、code variable 和稳定标签。
- [[research/projects/eig-apost/implementation/open-problems|open-problems.md]]：本专题唯一
  open-problem ledger；明确区分当前新路线与历史实验编号。
- [[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]]：
  保存旧路线 I0--I4 的完整 design、result、review 和原索引；旧编号和 verdict 不构成
  当前授权。
- [[test/README|current test index]]：记录新路线 I1.2--I2.3 实验状态；当前实验位于
  `test/i1/hg-adef/`、`test/i1/k-scan/`、`test/i1/k-ready/`、`test/i2/k-count/` 和
  `test/i2/h-inertia/`、`test/i2/k-drift/` 与 `test/i2/m-drift/`。旧实验统一
  由 [[test/archive/legacy-route-v1/README|legacy experiment index]] 保存。

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
4. [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] 与
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
   estimate、independent truth 和 upper-bound claim ladder，不提前冻结算法。
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
