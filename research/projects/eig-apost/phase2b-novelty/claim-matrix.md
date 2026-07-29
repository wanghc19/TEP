# Novelty claim matrix

状态：Phase 2b 门控矩阵已完成。`yes` 表示原文明确覆盖，`partial` 表示只覆盖可迁移
近邻，`no` 表示已核验的问题或误差对象不覆盖该项。C2--C5 均按本项目的窄定义
判断；一般 DtN、一般 eigenvalue estimator 或一般 convergence study 不自动计为
`yes`。

| 来源 | C1 | C2 | C3 | C4 | C5 | C6 | 与候选贡献的关系 | 核验状态 |
|---|---|---|---|---|---|---|---|---|
| Fliss (2013) | yes | partial | partial | no | no | partial | fixed-$\beta$ line-defect guided-mode DtN NEP 基线 | local original verified |
| Fliss--Klindworth--Schmidt (2015) | yes | partial | partial | no | no | partial | 同一对象的 DtN/RtR 透明边界与数值实现 | local original verified |
| Klindworth (2015) | yes | partial | partial | no | no | partial | 高阶 FEM DtN/RtR、Newton 与色散曲线追踪；明确把数值分析列为开放问题 | local original verified |
| Li--Lu (2007) | no | partial | partial | no | no | partial | point-defect DtN NEP、最小奇异值扫描和 rings convergence | local original verified |
| Giani (2013) | partial | no | no | partial | partial | partial | supercell line-defect photonic-crystal FEM residual estimator 与 effectivity | local original verified |
| Engström--Giani--Grubišić (2016) | partial | no | no | partial | partial | yes | photonic-crystal quadratic NEP residual/DWR estimator 与高精度 reference | local original verified |
| Yu--Hu--Lu--Rathsfeld (2022) | no | yes | yes | no | no | partial | BIE unit-cell map、semi-waveguide NtD、Riccati 与 recursive doubling | local original verified |
| Petropoulos--Turc (2025) | no | yes | yes | no | no | partial | BIE RtR 与 half-array Riccati 的最新 scattering 近邻 | publisher primary text verified |
| Bonnet-Ben Dhia--Gmati (1995) | partial | no | partial | partial | no | partial | guided eigenproblem 中 exact Fourier boundary operator 截断的超代数先验谱误差界 | local original verified |
| Djellouli et al. (2000) | partial | no | partial | partial | no | yes | guided eigenvalue 的 local Robin boundary approximation、FEM 与解析/文献 reference comparison | local original verified |
| Choutri (2008) | partial | no | partial | partial | no | partial | homogeneous-cladding optical-fiber eigenvalue domain-truncation bound | local original verified |
| Boureghda--Choutri--Rezgui (2022) | partial | no | partial | partial | no | partial | guided-mode exact DtN 与近似 Robin 边界的指数型 eigenvalue/eigenfunction bound | local original verified |
| Marletta (2004) | no | no | partial | partial | no | partial | exterior-domain DtN approximation、spectral exactness 与伪根风险 | publisher original full text verified |
| Xi--Gong--Sun (2024) | no | no | partial | partial | no | yes | DtN Fourier truncation下 holomorphic resonance NEP 的先验收敛估计 | local original verified |
| Lin--Lv (2025) | no | no | partial | partial | no | yes | periodic scattering 中 computable DtN truncation a posteriori term | local original verified |
| Leclerc et al. (2026) | partial | no | partial | partial | no | yes | 开放波导 guided eigenvalue 的线性化 ABC 与半解析精度验证 | publisher primary text verified; repository PDF embargoed |
| Gopalakrishnan et al. (2025) | partial | no | no | no | partial | yes | PML-truncated fiber eigenproblem 的 DWR eigenvalue estimator 与 effectivity | local original verified |

## 门控边界

- C1 已由 Fliss (2013)、Fliss--Klindworth--Schmidt (2015) 和 Klindworth (2015)
  实质覆盖；fixed-$\beta$ line-defect guided-mode DtN formulation 不是创新点。
- C2--C3 的计算部件也分别由透明边界文献和 BIE/Riccati/doubling scattering 文献
  覆盖；把这些部件拼接起来本身不足以构成理论创新。
- Bonnet-Ben Dhia--Gmati (1995) 已给出 exact Fourier boundary operator 截断下开放
  导模特征值的超代数先验误差界；Djellouli et al. (2000)、Choutri (2008) 与
  Boureghda et al. (2022) 又覆盖局部 artificial boundary 与域截断误差。Xi et al.
  (2024) 已把 DtN 截断连接到 holomorphic NEP 特征值收敛；Lin--Lv (2025) 已给出
  周期散射中可计算的 DtN 截断后验项。因此 C4 只能以更窄的
  “periodic half-guide numerical DtN error 到 fixed-$\beta$ guided eigenvalue shift 的
  computable estimator”表述。
- 已核验来源中仍未出现 C1--C5 的完整交叉，尤其未出现本项目意义下的 simple-root
  projected correction、two-level/doubling tail estimator 与 independent-reference
  effectivity 的组合。该结论是截至 2026-07-27 的 search-bounded 结果，不是全局
  优先权证明。

正式 verdict 与条件见 [[research/projects/eig-apost/phase2b-novelty/r-gate|novelty gate]]。
