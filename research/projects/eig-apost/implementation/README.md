# Eigenvalue a posteriori implementation

## 当前状态

当前新路线处于 `I2_1_PASS_WITH_CONDITIONS / CONDITIONAL_EMPIRICAL_FINE_M48_COUNT_ONE`。精确
half-guide DtN 由半无限边值问题定义，连续中心算子 $\mathcal F(k)$ 在任何
BIE/Fourier 截断和 ordered QZ 之前定义真实谱对象。现行数学权威是
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]，离散
$A_{\mathrm{def}}$ 的离散来源位于
[[research/projects/eig-apost/implementation/i1/README|i1/]]，当前 root-isolation 状态位于
[[research/projects/eig-apost/implementation/i2/README|i2/]]。

I1.2 的 manufactured、MATLAB $M=5,8$ mechanism 与 direct $M=48$ static arms 已通过；
I1.3 又完成 real-$k$ 连续性、分层筛查和 width-driven 局部加密，记录 fixed-$M=48$
离散候选 $k=1.8327703475952146$ 与 $q=8.3200886232193094\times10^{-8}$。I1.4 随后在
冻结小复圆盘上完成 sampled anchored branch、QZ/graph/DtN、factor、closure、CR 和负例门；
V5 条件闭合只解决对称模型无法识别的 transmission-order assembly negative。I2.1 随后在
同一 fine、$M=48$ 圆盘上运行 factor-aware determinant winding：全部实际 inverse factors
得到嵌套 zero winding，主 $A_{\mathrm{def}}^D$ 在 32/64 点网格上均得到 count one。该结果只
是条件性 finite-dimensional algebraic zero count；尚未定位 root，production derivative 仍未
资格化。下一阶段只允许另行设计 I2.2 root solve 和最低伪根排除，不能声称 continuous
physical eigenvalue 或 estimator。
OP-M0-1--OP-M0-4 继续限制 physical/root 解释，最新行动边界以
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
│   └── review.md
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
- [[research/projects/eig-apost/implementation/i2/README|i2/]]：当前活动阶段；I2.1 已条件
  通过，并维护 I2.1--I2.4 四个内部里程碑。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只维护新路线 I1--I4
  的项目级依赖和退出条件。
- [[research/projects/eig-apost/implementation/SYMBOL|SYMBOL.md]]：集中说明跨阶段缩写、
  数学对象、code variable 和稳定标签。
- [[research/projects/eig-apost/implementation/open-problems|open-problems.md]]：本专题唯一
  open-problem ledger；明确区分当前新路线与历史实验编号。
- [[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]]：
  保存旧路线 I0--I4 的完整 design、result、review 和原索引；旧编号和 verdict 不构成
  当前授权。
- [[test/README|current test index]]：记录新路线 I1.2--I2.1 实验状态；当前实验位于
  `test/i1/hg-adef/`、`test/i1/k-scan/`、`test/i1/k-ready/` 和 `test/i2/k-count/`。旧实验统一
  由 [[test/archive/legacy-route-v1/README|legacy experiment index]] 保存。

## 阶段文档规则

当前新路线的阶段目录直接位于 `implementation/iN/`，不再增加 `current/` 中间层，也不为
内部里程碑或小实验创建并列阶段目录。阶段目录按实际内容使用：`README.md` 维护状态、
阅读顺序和入口；`design.md` 冻结共享设计；只有产生实际数值结果后才创建 `result.md`；
`review.md` 记录阶段级审查与授权边界。

具体实验的代码、配置、报告和产物仍保存在 `test/`，implementation 只负责索引与综合。
历史阶段统一保存在 `archive/legacy-route-v1/`；不得把新路线 I1--I4 的编号机械写回旧
I1--I4 文档、实验 ID 或冻结 verdict。

## 推荐阅读顺序

1. [[research/projects/eig-apost/STATUS|project STATUS]]：确认当前阶段和禁止事项。
2. [[research/projects/eig-apost/implementation/ROADMAP|project roadmap]]：确认新路线
   I1--I4 的依赖。
3. [[research/projects/eig-apost/implementation/i1/README|current I1 guide]]：确认内部
   里程碑和授权边界。
4. [[research/projects/eig-apost/implementation/i2/README|current I2 guide]] 与
   [[research/projects/eig-apost/implementation/i2/review|I2.1 review]]：确认 count-one 结果与
   I2.2 入口。
5. [[research/projects/eig-apost/implementation/i1/design|discrete A-def design]]：阅读当前
   离散空间、QZ/graph/DtN 链和组装合同。
6. [[research/projects/eig-apost/implementation/i1/review|current I1 review]]：核对审查结论
   和 caveat。
7. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]：查看仍限制
   physical/root 解释的 blocker。
8. [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]：阅读
   当前数学方法。
9. [[research/projects/eig-apost/implementation/SYMBOL|symbol and code-variable ledger]] 和
   [[test/README|current experiment index]]：查询符号与新路线实验状态。
10. 只有需要追溯历史设计、结果和审查时，再进入
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
