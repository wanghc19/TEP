# Eigenvalue a posteriori implementation

## 当前状态

当前阶段是 `METHOD_RECONSTRUCTION / I4_NUMERICS_PAUSED`。精确 half-guide DtN 由
半无限边值问题定义，连续中心算子 $\mathcal F(k)$ 在任何 BIE/Fourier 截断和 ordered
QZ 之前定义真实谱对象。恢复数值实现前必须先关闭
[[research/projects/eig-apost/implementation/open-problems#M0|OP-M0-1--OP-M0-4]]。

本目录当前不授权设计、组装或运行新的 $A_{\mathrm{def}}$，也不授权 locator、DtN wall、
complex disk、contour 或 root isolation。最新行动边界以
[[research/projects/eig-apost/STATUS|project STATUS]] 为准。

## 分级目录

```text
implementation/
├── README.md
├── SYMBOL.md
├── open-problems.md
├── current/
│   └── README.md
└── archive/
    ├── README.md
    ├── i0-manufactured/
    ├── i1-finite-tail/
    ├── i2-aug-bie/
    ├── i3-provenance/
    └── i4-numerical-qualification/
```

- [[research/projects/eig-apost/implementation/current/README|current/]]：只索引仍指导未来
  实现的当前材料。本轮没有创建尚未开始的离散设计文档。
- [[research/projects/eig-apost/implementation/archive/README|archive/]]：保存 I0--I4 的完整
  历史 design、result 和 review；旧 verdict 保持原文，不构成当前授权。
- [[research/projects/eig-apost/implementation/SYMBOL|SYMBOL.md]]：跨阶段缩写、数学对象、
  code variable 和稳定标签的集中说明。
- [[research/projects/eig-apost/implementation/open-problems|open-problems.md]]：本专题唯一
  open-problem ledger；问题分类、状态和 cheapest next check 只在这里维护。

## 推荐阅读顺序

1. [[research/projects/eig-apost/STATUS|project STATUS]]：确认当前阶段和禁止事项。
2. [[research/projects/eig-apost/implementation/current/README|current implementation
   guide]]：确认当前实现材料的权威边界。
3. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]：查看恢复实现前
   必须关闭的 blocker。
4. [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]：阅读
   当前数学方法；它不位于 implementation 目录。
5. [[research/projects/eig-apost/implementation/SYMBOL|symbol and code-variable ledger]]：
   查询符号、缩写和历史代码对象。
6. 只有需要追溯已完成实验时，再进入
   [[research/projects/eig-apost/implementation/archive/README|archive index]]。

## 历史阶段简介

- `archive/i0-manufactured/`：有限维 manufactured NEP root/correction 算法原型；仍可作
  数值算法单元测试，但不验证物理 BIE/DtN。
- `archive/i1-finite-tail/`：`SUPERSEDED / LEGACY` 的 finite-tail half-guide-map 代数；
  只保留为 cross-check、reference sequence 或 tail diagnostic。
- `archive/i2-aug-bie/`：历史 augmented-BIE/finite-tail coupling。中心 BIE 的 block、
  density scaling 和 failure ledger 可能复用，但旧 coupling 必须由当前 DtN/graph 路线替换。
- `archive/i3-provenance/`：`RETIRED AS CURRENT GATE / HISTORICAL PROVENANCE EVIDENCE`；
  provenance 方法可复用，历史 `GO` 不再授权后续数值阶段。
- `archive/i4-numerical-qualification/`：Fliss benchmark、Rayleigh budget、Ewald/MFS/
  extractor、SLP/DLP 和有限 $M_{\mathrm{trace}}$ 资格证据；当前只作为离散部件证据保存。
