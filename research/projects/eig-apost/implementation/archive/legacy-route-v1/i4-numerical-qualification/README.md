# I4 numerical qualification archive

## 阶段定位和状态

I4 保存 full analytic root-readiness 的历史负例，以及 Fliss benchmark、Rayleigh budget、
Ewald/MFS/extractor 和 SLP/DLP/trace 资格证据。当前状态是
`ARCHIVED NUMERICAL QUALIFICATION / I4 NUMERICS PAUSED`；这些结果不授权 $A_{\mathrm{def}}$、
DtN wall、locator、complex disk 或 root isolation。

## 文件

- [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-readiness|i4-readiness.md]]：
  冻结旧双椭圆 analytic root-readiness 的 branch/chart/disk/CR/negative 设计。
- [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-result|i4-result.md]]：
  保存旧双椭圆 locator early-stop 结果和复现边界。
- [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-review|i4-review.md]]：
  保存该 early-stop 的独立审查与最小后续动作。
- [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-fliss|i4-fliss.md]]：
  记录 Fliss smooth-profile finite-strip benchmark 与 sharp-disk 独立 BIE benchmark 的边界。
- [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-rayleigh|i4-rayleigh.md]]：
  记录不同 wall clearance、mode order 和 QZ/doubling 的 Rayleigh budget screening。
- [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-extract|i4-extract.md]]：
  汇总 spectral extraction、Ewald 三路径、derivative、proxy placement 和 DLP/trace closure。

## 实验产物入口

- 历史 analytic readiness：
  [[test/README#I4-ANALYTIC-READINESS-V1|I4-ANALYTIC-READINESS-V1]]。
- Fliss finite-difference 与 sharp-disk diagnostics：
  [[test/README#I4-FLISS-BASE-V1|I4-FLISS-BASE-V1]]、
  [[test/README#I4-FLISS-EDGE-V1|I4-FLISS-EDGE-V1]]、
  [[test/README#I4-SHARP-PENCIL-V1|I4-SHARP-PENCIL-V1]]、
  [[test/README#I4-BIDIR-PENCIL-V1|I4-BIDIR-PENCIL-V1]]。
- Rayleigh budget：[[test/README#I4-RAYLEIGH-BUDGET-V1|I4-RAYLEIGH-BUDGET-V1]]。
- extraction 与 solver diagnostics：[[test/README#I4-EXTRACT-V1|I4-EXTRACT-V1]]、
  [[test/README#I4-PROXY-SOLVER-V1|I4-PROXY-SOLVER-V1]]。
- Ewald/MFS/Rayleigh value、derivative 与 action audits：
  [[test/README#I4-THREE-PATH-V1|I4-THREE-PATH-V1]]、
  [[test/README#I4-DERIVATIVE-ACTIONS-V1|I4-DERIVATIVE-ACTIONS-V1]]、
  [[test/README#I4-PACKAGE-POINT-V1|I4-PACKAGE-POINT-V1]]。
- singularity-aware proxy rule：
  [[test/README#I4-PROXY-RULE-V1|I4-PROXY-RULE-V1]]。
- DLP and trace qualification：
  [[test/README#I4-DLP-TRACE-V1|I4-DLP-TRACE-V1]]。

当前物理路径、入口函数和权威报告只在统一实验索引维护。

## 复用和替代关系

Ewald reference、four-layer wall actions、有限 trace screen、FD candidate 和失败案例仍可作为
离散部件证据复用，但只覆盖各自冻结参数。旧 root-readiness/finite-tail coupling 已由 M0
continuous DtN/BIE 路线取代；恢复 I4 必须先关闭当前 ledger 的 OP-M0-1--OP-M0-4。
