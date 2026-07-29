<!-- Read-only material map for Phase 1 scoping -->

# Phase 1 material map

本清单用于定位可用材料，不认定材料中的理论、数值候选或文献解释正确。`Observed`
表示可由文件结构或代码静态检查直接确认；`Existing record` 表示来自仓库已有研究记录，
需要在后续阶段独立复核。

## 代码入口

| 入口                                                    | 可直接观察到的作用                                                                                  | 对后验误差研究的待查问题                                                                 | 状态                              |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- | ------------------------------- |
| `+bloch/solve_modes.m`                                | 求解 cell scattering matrix 导出的 generalized eigenproblem，并输出有限 Floquet multipliers 与 traces。 | 当前输出是否足以构造 pencil residual、scaled backward error、条件数或 eigenvalue cluster 诊断。 | Observed                        |
| `+bloch/construct_S.m`                                | 组装 cell scattering matrix，并保存 BIE solve residual。                                          | 线性系统残差如何传播到 multiplier 和后续 port subspace；低残差是否掩盖病态性。                         | Observed                        |
| `tep_edc_scan_local.m`                                | 扫描缺陷匹配矩阵的 $\sigma_{\min}$ 并细化局部 dip；工作树中有用户未提交修改。                                              | $\sigma_{\min}$ 与连续特征值误差、伪根和 mode-selection 跳变之间的关系。                             | Observed; preserve user changes |
| `tep_edc_projected_gap_scan.m`                        | 以 near-unit Bloch multiplier 计数寻找 projected-gap 候选区；当前为未跟踪文件。                              | `unit_tol`、截断和非正规性对 gap classification 的敏感性。                                 | Observed; untracked user file   |
| `draft/examples/run_tep_fixed_beta_k_scan.m`          | 对 `A_QP(k,beta)` 的 $\sigma_{\min}$ 做 coarse/mid/final 分辨率扫描。                                   | 多分辨率 dip 稳定性是否能成为误差 indicator，如何避免同源外推造成的虚假信心。                               | Observed                        |
| `waveguide_1d/tep_conv_local2.m`                      | 记录 `k_best(N)`、`sigma_best(N)`、固定 $k$ 值和外推残差。                                              | 外推误差、离散误差和扫描误差是否可分离；该旧脚本的经验逻辑能否迁移。                                           | Observed; legacy implementation |
| `crystal_2d/bloch_pc_barnett_scan.m`                  | 比较 unit-circle phase scan 与 transfer/Bloch multipliers，并记录 proxy 和 solve residual。         | 两种 formulation 的差异能否提供相对独立的交叉验证信号。                                           | Observed                        |
| `benchmark/qpgreen/` 与 `draft/examples/run_qpgreen_*` | 以 Ewald 值比较 MFS quasiperiodic Green function，并已有参数 sweep。                                  | kernel approximation error 如何进入 operator、singular value 和 eigenvalue 误差预算。   | Observed                        |

## 草稿与结果入口

| 入口 | 当前用途 | 使用限制 |
|---|---|---|
| `pre/report/report.tex` | 记录 boundary-integral trace-subspace 数值流程。 | 第一版技术说明，不是当前理论权威。 |
| `pre/report/sections/numerical_workflow.tex` | 已列出 boundary、Rayleigh、proxy、mode selection 和 residual 检查。 | 只提供误差源分类入口，不提供后验估计结论。 |
| `pre/report/sections/05_numerical_experiments.tex` | 数值实验占位，明确尚未报告结果。 | 不得据此声称完成验证。 |
| `draft/examples/output/tep_fixed_beta_timing.md` | 保存 `ntot=40,60,80,100` 的 timing 和 $\sigma_{\min}$ 记录。 | 未在本阶段重跑；$\sigma_{\min}$ 衰减不等于特征值误差界。 |
| `draft/examples/output/qpgreen_linton_tables_20260710_202620.md` | 保存三个 Linton 参数点的 MFS/Ewald 差异。 | 只验证特定 kernel evaluations，不能自动外推到完整 eigenproblem。 |
| `draft/examples/output/*.mat` 与 `draft/figs/` | 已有 band scan、fixed-beta scan、timing 和图形输出。 | 需建立数据 provenance、参数记录和独立复算后才可进入论文证据。 |

## 本轮静态核对的实现事实

- `tep_edc_scan_local.m` 中的 `A_def` 是一个具体的空缺陷 matching matrix：它把中心
  空胞元的两组 Rayleigh coefficients 与左右 lead 的 outgoing Dirichlet/Neumann
  trace bases 拼接。它不是 half-guide DtN 的定义，也不是 `A_QP` 的另一个名字。
- 该文件当前默认 `ntot=60`，使用相同的左右 bulk inclusion；其 infinity treatment
  是 outgoing trace-subspace，不是 DtN。
- `waveguide_1d/tep_scan_local4_2.m` 记录了 all-Kress ellipse case 在 `ntot=120` 时
  $\sigma_{\min}$ 达到约 `8.6e-13`。旧文件中也有 `ntot=150` 的记录，但 assembly 版本不同；
  因此首个 line-defect benchmark 若参考该结果，应先把 `ntot=120` 作为 provisional
  fixed value，而不是把多个版本的数字混成收敛证据。
- `draft/draft.pdf` 第 18 页 Table 4 的 `27525` 是整个 band scan 的 $(k,\beta)$ evaluation
  总数；它支持“只对少数候选根做几十到几百次 estimator evaluation 的额外成本可接受”，
  但不提供 line-defect reference truth。
- 初始“双椭圆”几何仍需在 Phase 3 先选出一个具有 isolated guided mode 的 bulk/defect
  轴长组合，再冻结几何、$\beta$ 和 `ntot`。几何筛选与正式 effectivity 实验必须分开，
  避免用结果反向挑选 benchmark。

## 本地文献入口

以下仅是 Phase 2 的候选来源，不是本阶段的文献综合结果。书目信息和相关性描述来自
`research/projects/novelty-audit/local_reference_inventory.md`，届时需回到原 PDF 和
正式元数据核验。

| 本地文件 | 后续核验主题 | 当前依据 |
|---|---|---|
| `ref/ref_data/Coatleven2012.pdf` | periodic line defect reduction、convergence/error estimates、吸收与无耗散范围差异。 | Existing record |
| `ref/ref_data/Luan2019.pdf` | interface residual 与 field error 的关系、MFS/Rayleigh truncation。 | Existing record |
| `ref/ref_data/Hiptmair2022.pdf` | BIE spurious quasi-resonance，以及小奇异值并非物理解的充分证据。 | Existing record |
| `ref/ref_data/Hao2014.pdf`、`ref/ref_data/Kress1991.pdf` | Nyström/Kress 离散误差与稳定性基线。 | Existing record |
| `ref/ref_data/Fliss2013.pdf` | line-defect guided-mode DtN reduction、multiplicity 与数值 eigenproblem。 | Existing record |
| `ref/ref_data/Barnett2010.pdf` | quasiperiodic BIE、band-structure nullspace test 与独立 formulation 比较。 | Existing record |
| `ref/ref_data/Hohage2013.pdf` | generalized Floquet/Jordan structure 对 multiplier/subspace 误差指标的影响。 | Existing record |
| `ref/ref_data/Linton1998.pdf` | quasiperiodic Green function 参考计算和阈值敏感性。 | Existing record |

## 当前可见的误差层级

这只是待核查分类，不是误差传播结论：

1. kernel periodization 与 proxy/MFS 近似；
2. boundary Nyström/Kress 离散；
3. Rayleigh channel truncation；
4. cell scattering linear solve；
5. generalized eigenpair 与 invariant-subspace 计算；
6. outgoing/mode selection tolerance；
7. center/lead matching matrix assembly；
8. scalar scan、dip detection 和 local refinement；
9. continuum interpretation、multiplicity、threshold 与 spurious-root 风险。

各层是否可分离、如何组合、哪些量真正是 a posteriori estimator，留待 RQ 确认后的
Phase 2--3 研究。
