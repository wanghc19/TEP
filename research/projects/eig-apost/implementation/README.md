# Eigenvalue a posteriori implementation

## 当前状态

当前新路线处于 `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS / NUMERICS_PAUSED`。精确
half-guide DtN 由半无限边值问题定义，连续中心算子 $\mathcal F(k)$ 在任何
BIE/Fourier 截断和 ordered QZ 之前定义真实谱对象。现行数学权威是
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]，离散
$A_{\mathrm{def}}$ 的设计与审查统一位于
[[research/projects/eig-apost/implementation/i1/README|i1/]]。

本阶段没有组装或运行新的 $A_{\mathrm{def}}$，因此 `i1/` 没有 `result.md`。两项独立
review 均无 design-level blocker；下一里程碑只授权新的 test-local static assembly
oracle。production DtN、$A_{\mathrm{def}}'$、locator、complex disk、contour 和 root
isolation 仍不获授权。OP-M0-1--OP-M0-4 继续限制 physical/root 解释，最新行动边界以
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
└── archive/
    ├── README.md
    ├── i0-manufactured/
    ├── i1-finite-tail/
    ├── i2-aug-bie/
    ├── i3-provenance/
    └── i4-numerical-qualification/
```

- [[research/projects/eig-apost/implementation/i1/README|i1/]]：当前新路线的唯一活动阶段，
  汇总离散设计、内部里程碑、审查和授权边界。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只维护新路线 I1--I4
  的项目级依赖和退出条件。
- [[research/projects/eig-apost/implementation/SYMBOL|SYMBOL.md]]：集中说明跨阶段缩写、
  数学对象、code variable 和稳定标签。
- [[research/projects/eig-apost/implementation/open-problems|open-problems.md]]：本专题唯一
  open-problem ledger；明确区分当前新路线与历史实验编号。
- [[research/projects/eig-apost/implementation/archive/README|archive/]]：保存历史 I0--I4
  的完整 design、result 和 review；旧编号和 verdict 不构成当前授权。
- [[test/README|test experiment index]]：以稳定 Experiment ID 映射所有 eig-apost
  实验的物理路径、入口和权威报告。

## 阶段文档规则

当前新路线的阶段目录直接位于 `implementation/iN/`，不再增加 `current/` 中间层，也不为
内部里程碑或小实验创建并列阶段目录。阶段目录按实际内容使用：`README.md` 维护状态、
阅读顺序和入口；`design.md` 冻结共享设计；只有产生实际数值结果后才创建 `result.md`；
`review.md` 记录阶段级审查与授权边界。

具体实验的代码、配置、报告和产物仍保存在 `test/`，implementation 只负责索引与综合。
历史阶段继续保存在 `archive/`；不得把新路线 I1--I4 的编号机械写回历史 I1--I4 文档、
实验 ID 或冻结 verdict。

## 推荐阅读顺序

1. [[research/projects/eig-apost/STATUS|project STATUS]]：确认当前阶段和禁止事项。
2. [[research/projects/eig-apost/implementation/ROADMAP|project roadmap]]：确认新路线
   I1--I4 的依赖。
3. [[research/projects/eig-apost/implementation/i1/README|current I1 guide]]：确认内部
   里程碑和授权边界。
4. [[research/projects/eig-apost/implementation/i1/design|discrete A-def design]]：阅读当前
   离散空间、QZ/graph/DtN 链和组装合同。
5. [[research/projects/eig-apost/implementation/i1/review|current I1 review]]：核对审查结论
   和 caveat。
6. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]：查看仍限制
   physical/root 解释的 blocker。
7. [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]：阅读
   当前数学方法。
8. [[research/projects/eig-apost/implementation/SYMBOL|symbol and code-variable ledger]] 和
   [[test/README|unified experiment index]]：查询符号与实验权威报告。
9. 只有需要追溯历史设计、结果和审查时，再进入
   [[research/projects/eig-apost/implementation/archive/README|archive index]]。

## 历史阶段简介

- `archive/i0-manufactured/`：有限维 manufactured NEP root/correction 原型；实验入口
  [[test/README#I0-NEP-V1|I0-NEP-V1]]。
- `archive/i1-finite-tail/`：`SUPERSEDED / LEGACY` 的 finite-tail half-guide map；实验入口
  [[test/README#I1-HG-MAP-V1|I1-HG-MAP-V1]]。
- `archive/i2-aug-bie/`：历史 augmented-BIE coupling；center BIE 部件可能复用，旧
  coupling 必须替换。实验入口 [[test/README#I2-AUG-BIE-V1|I2-AUG-BIE-V1]]。
- `archive/i3-provenance/`：`RETIRED AS CURRENT GATE / HISTORICAL PROVENANCE EVIDENCE`；
  实验入口 [[test/README#I3-PROVENANCE-V1|I3-PROVENANCE-V1]]。
- `archive/i4-numerical-qualification/`：历史 Fliss、Rayleigh、Ewald/MFS/extractor、
  SLP/DLP 和 $M_{\mathrm{trace}}$ 部件证据；最后顺序资格实验为
  [[test/README#I4-DLP-TRACE-V1|I4-DLP-TRACE-V1]]。
