# Archived implementation stages

本目录保存 I0--I4 的完整历史 implementation design、result 和 review。归档移动不改变
文件中的历史 verdict、数值结果或证据边界；它们不再作为当前实现授权。

| 阶段目录 | 当前定位 | 实验入口 |
|---|---|---|
| [[research/projects/eig-apost/implementation/archive/i0-manufactured/README|I0 manufactured]] | 有限维 root/correction 算法原型；可作单元测试 | `test/eig-apost-nep/` |
| [[research/projects/eig-apost/implementation/archive/i1-finite-tail/README|I1 finite tail]] | `SUPERSEDED / LEGACY` | `test/hg-map/` |
| [[research/projects/eig-apost/implementation/archive/i2-aug-bie/README|I2 augmented BIE]] | 历史离散代数；center BIE 部件可能复用，旧 coupling 需替换 | `test/aug-bie/` |
| [[research/projects/eig-apost/implementation/archive/i3-provenance/README|I3 provenance]] | `RETIRED AS CURRENT GATE / HISTORICAL PROVENANCE EVIDENCE` | `test/root-ready/` |
| [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README|I4 numerical qualification]] | 历史数值资格与部件证据；I4 数值暂停 | `test/root-ready/analytic-readiness/` 与 `test/i4-*/` |

当前路线和阅读入口见
[[research/projects/eig-apost/implementation/current/README|current implementation guidance]]；
未解决问题仍只在
[[research/projects/eig-apost/implementation/open-problems|top-level ledger]] 维护。

部分冻结 `test/` scripts、configs 和 outputs 仍记录移动前的 implementation source path 或
hash。本轮按约束不修改这些实验材料：既有产物保持原样，但若以后重跑 source-manifest
gate，必须在单独获准的 test-local maintenance 中更新路径并重新建立 evidence lock。
