# Legacy route v1 implementation archive

## Archive record

- Pre-archive commit: `c05149a1a674d414b60a5d7d9429ca2dae51260c`.
- Archived on: `2026-08-11`.
- Scope: the former implementation I0--I4 route, including its original stage index.
- Preservation rule: historical verdicts, formulas, links, paths and experiment references below
  retain their pre-archive text. Broken legacy-internal paths are historical metadata and are not
  silently repaired.

## Formulation and reusable evidence

The following formulation is superseded by the new continuous DtN/BIE route: finite cell tails
with remote closure as the main half-guide definition, the old augmented-BIE/finite-tail coupling,
and the old $A_{\mathrm{def}}$/locator authorization chain. None of those objects defines the
current spectral problem or estimator.

The archive is not wholly deprecated. The following evidence may still inform the new route,
subject to a new theory-to-code map and the frozen parameter scope of each report:

- the manufactured NEP root/correction machinery as a finite-dimensional algorithm oracle;
- center-BIE block layout, density scaling diagnostics and failure/provenance ledgers;
- Fliss finite-difference and band-edge results as geometry and search-window guidance only;
- Rayleigh-budget and failure diagnostics as trace-order and negative-test guidance;
- the Linton-qualified Ewald function values and independently checked gradient/Hessian formulas;
- the MATLAB `lsqminnorm`, singularity-aware `proxy_dist/d=0.2`, and Ewald/MFS/Rayleigh
  comparisons for SLP-D, SLP-N, DLP-D and DLP-N;
- the finite $M_{\mathrm{trace}}=48$ screen for the frozen manufactured densities and
  $M_{\mathrm{ref}}=96$, which is not an infinite-tail theorem or a uniform solved-density claim.

The archived experiment bundle is indexed at
[[test/archive/legacy-route-v1/README|legacy-route-v1 experiment index]]. Current implementation
authority remains in [[research/projects/eig-apost/implementation/README|implementation README]].

## Preserved pre-archive index

本目录保存 I0--I4 的完整历史 implementation design、result 和 review。归档移动不改变
文件中的历史 verdict、数值结果或证据边界；它们不再作为当前实现授权。

| 阶段目录 | 当前定位 | 实验入口 |
|---|---|---|
| [[research/projects/eig-apost/implementation/archive/i0-manufactured/README\|I0 manufactured]] | 有限维 root/correction 算法原型；可作单元测试 | [[test/README#I0-NEP-V1\|I0-NEP-V1]] |
| [[research/projects/eig-apost/implementation/archive/i1-finite-tail/README\|I1 finite tail]] | `SUPERSEDED / LEGACY` | [[test/README#I1-HG-MAP-V1\|I1-HG-MAP-V1]] |
| [[research/projects/eig-apost/implementation/archive/i2-aug-bie/README\|I2 augmented BIE]] | 历史离散代数；center BIE 部件可能复用，旧 coupling 需替换 | [[test/README#I2-AUG-BIE-V1\|I2-AUG-BIE-V1]] |
| [[research/projects/eig-apost/implementation/archive/i3-provenance/README\|I3 provenance]] | `RETIRED AS CURRENT GATE / HISTORICAL PROVENANCE EVIDENCE` | [[test/README#I3-PROXY-DIAG-V1\|I3 proxy diagnostic]]；[[test/README#I3-PROVENANCE-V1\|I3 provenance closure]] |
| [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 numerical qualification]] | 历史数值资格与部件证据；I4 数值暂停 | [[test/README#I4-ANALYTIC-READINESS-V1\|I4 analytic readiness]] 至 [[test/README#I4-DLP-TRACE-V1\|I4 DLP/trace]] 的统一索引 |

当前路线和阅读入口见
[[research/projects/eig-apost/implementation/README|current implementation guidance]]；
未解决问题仍只在
[[research/projects/eig-apost/implementation/open-problems|top-level ledger]] 维护。

所有实验的当前路径和报告由 [[test/README|unified experiment index]] 维护。部分冻结
scripts、configs 和 outputs 仍记录移动前的 implementation source path 或 hash；这些内容
保持原样。若以后重跑 source-manifest gate，必须在单独获准的 test-local maintenance 中
更新路径并重新建立 evidence lock。
