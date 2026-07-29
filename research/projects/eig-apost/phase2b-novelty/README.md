# Phase 2b novelty gate

本目录对 [[research/projects/eig-apost/phase3-analysis/p-paper|候选论文路线]] 的创新性
进行独立、可复查的检索核验。它属于 Phase 2 Investigation 的扩展，不证明候选方法
正确，也不把 Phase 3 的理论设计提升为活动主线。

## 当前问题

检索对象不是 BIE、DtN、doubling、guided-mode computation 或一般 nonlinear
eigenvalue perturbation 中的任一单项，而是下面的完整交叉：

> fixed-$\beta$ periodic line-defect guided-mode eigenvalue
> $\rightarrow$ BIE cell map
> $\rightarrow$ structure-preserving finite-tail half-guide DtN
> $\rightarrow$ computable infinity-truncation eigenvalue estimator
> $\rightarrow$ simple-root effectivity
> $\rightarrow$ independent-reference validation。

## 文件

- `search-plan.md`：预先冻结的检索边界、query families 和 gate 判据。
- `search-log.md`：按日期记录查询、筛选数量和 citation chasing。
- `claim-matrix.md`：逐项比较近邻工作覆盖了候选创新链的哪些环节。
- `r-sources.md`：只记录经过元数据和原文核验的核心来源。
- `r-gate.md`：search-bounded novelty verdict、反方审查和继续研究的条件。

## 状态

状态：`completed / PASS WITH CONDITIONS`。本阶段允许受条件约束的低成本 Phase 3
理论与验证设计，但不允许冻结 priority claim；不得使用“first”“no prior work”或
“首次”等绝对表述。

检索和全文核验确认：

- 一般 photonic-crystal/optical guided-mode eigenvalue estimator 已有 FEM residual 和
  DWR 先例，不能作为宽泛创新点；
- BIE unit-cell boundary map、semi-waveguide NtD、Riccati/doubling 的组合也已有
  scattering 先例；
- 开放导模特征值的域截断误差、一般 photonic/fiber eigenvalue estimator、DtN
  truncation 的谱误差分析和周期散射后验项都已有先例；
- 尚未发现一篇已核验来源覆盖本目录定义的 C1--C5 完整交叉。可辩护缺口仅是
  numerical half-guide DtN error 到 fixed-$\beta$ guided eigenvalue shift 的 computable
  estimator 及其 simple-root effectivity，不是求解器组件本身。

Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al. (2000) 的本地全文已于
2026-07-27 完成核验并登记；当前只剩 Leclerc et al. (2026) 的 accepted manuscript
受 HAL embargo，尚不能作全文级排除。

正式结论与剩余全文条件见
[[research/projects/eig-apost/phase2b-novelty/r-gate|novelty gate]]；来源访问情况见
[[research/projects/eig-apost/phase2b-novelty/r-sources|source verification]]。
