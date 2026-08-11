# eig-apost 实验统一索引

本文件是 `codex/epost` 分支上 eig-apost 实验的人工维护目录。它只负责把稳定实验标识、
当前物理路径、运行入口和权威报告对应起来；实验的数学结论仍以所链接的冻结报告为准。

## 索引维护约定

- `Experiment ID` 是稳定标识；实验目录的物理路径以后可以变化，ID 不随路径改变。
- 本人工索引始终跟随实验的当前位置更新。implementation 的读者入口只链接这里的稳定
  heading，不直接依赖具体 `test/...` 路径。
- 冻结 output 中记录的旧绝对路径、source hash 和 manifest 是历史运行事实，不得为配合
  后续目录移动而改写。
- 未来若移动实验目录，只更新本索引和其他人工 README；不得静默改写冻结报告、CSV、MAT、
  log、配置或 source manifest。
- `Authoritative report` 指该实验当前用于解释结论的具体报告。baseline/repeat 并存时，本
  索引明确指定最终权威版本；单独的辅助诊断不会自动取代其上游或下游实验的 verdict。

## 实验编号总表

| Experiment ID | Stage | 简称 | Status |
|---|---|---|---|
| `I0-NEP-V1` | I0 | manufactured NEP | frozen |
| `I1-HG-MAP-V1` | I1 | finite-tail half-guide map | superseded |
| `I2-AUG-BIE-V1` | I2 | augmented BIE | frozen / legacy coupling |
| `I3-PROXY-DIAG-V1` | I3 | controlled root-readiness proxy | negative evidence |
| `I3-PROVENANCE-V1` | I3 | source-derived provenance closure | frozen |
| `I4-ANALYTIC-READINESS-V1` | I4 | analytic readiness repeat | negative evidence |
| `I4-FLISS-BASE-V1` | I4 | Fliss dual-track baseline | frozen / mixed verdict |
| `I4-FLISS-EDGE-V1` | I4 | Fliss targeted edge confirmation | frozen |
| `I4-SHARP-PENCIL-V1` | I4 | sharp-disk pencil diagnostic | negative evidence |
| `I4-BIDIR-PENCIL-V1` | I4 | bidirectional pencil diagnostic | negative evidence |
| `I4-RAYLEIGH-BUDGET-V1` | I4 | Rayleigh budget batch | frozen / reference-uncertified |
| `I4-EXTRACT-V1` | I4 | extraction oracles | negative evidence |
| `I4-PROXY-SOLVER-V1` | I4 | Octave proxy solver diagnostic | negative evidence |
| `I4-THREE-PATH-V1` | I4 | Ewald/MFS/Rayleigh SLP-D | negative evidence |
| `I4-DERIVATIVE-ACTIONS-V1` | I4 | derivative and layer-action audit | frozen / sequential stop |
| `I4-PACKAGE-POINT-V1` | I4 | package point diagnostic | negative evidence |
| `I4-PROXY-RULE-V1` | I4 | singularity-aware proxy rule | frozen |
| `I4-DLP-TRACE-V1` | I4 | DLP and trace certification | frozen |

## I0 manufactured NEP

### I0-NEP-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I0-NEP-V1` |
| Stage | I0 manufactured NEP |
| Purpose | 在解析可解的有限维非线性特征值问题上验证 root search 和条件型 projected correction。 |
| Current path | `test/eig-apost-nep/` |
| Entry point | [`run_manufactured_nep.m`](eig-apost-nep/run_manufactured_nep.m) |
| Authoritative report | [`output/report.md`](eig-apost-nep/output/report.md) |
| Status | `frozen`；历史窄范围 `GO / conditional-empirical`，不验证物理 BIE 或 DtN。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i0-manufactured/README\|I0 archive summary]] |

## I1 finite-tail half-guide

### I1-HG-MAP-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I1-HG-MAP-V1` |
| Stage | I1 finite-tail half-guide |
| Purpose | 验证有限周期尾段、远端 closure、doubling 和历史 half-guide map 的离散代数。 |
| Current path | `test/hg-map/` |
| Entry point | [`run_hg_map_experiment.m`](hg-map/run_hg_map_experiment.m) |
| Authoritative report | [`output/report.md`](hg-map/output/report.md) |
| Status | `superseded`；`SUPERSEDED / LEGACY`，只保留为 cross-check、reference sequence 或 tail diagnostic。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i1-finite-tail/README\|I1 archive summary]] |

## I2 augmented BIE

### I2-AUG-BIE-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I2-AUG-BIE-V1` |
| Stage | I2 augmented BIE |
| Purpose | 验证历史中心 augmented-BIE/finite-tail coupling 的矩阵结构、缩放和离散代数。 |
| Current path | `test/aug-bie/` |
| Entry point | [`run_aug_bie_experiment.m`](aug-bie/run_aug_bie_experiment.m) |
| Authoritative report | [`output/report.md`](aug-bie/output/report.md) |
| Status | `frozen / legacy coupling`；历史 `STAGE2_DISCRETE_ALGEBRA_GO` 与 `ROOT_READY=STOP` 保持不变。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i2-aug-bie/README\|I2 archive summary]] |

## I3 provenance

### I3-PROXY-DIAG-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I3-PROXY-DIAG-V1` |
| Stage | I3 provenance |
| Purpose | 对早期 root-readiness proxy、chart 和 controlled-array 路径作受控诊断。 |
| Current path | `test/root-ready/` |
| Entry point | [`run_root_ready_diagnostic.m`](root-ready/run_root_ready_diagnostic.m) |
| Authoritative report | [`output/report.md`](root-ready/output/report.md) |
| Status | `negative evidence`；结论为 `BLOCKED_UPSTREAM_PROVENANCE`。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i3-provenance/README\|I3 archive summary]] |

### I3-PROVENANCE-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I3-PROVENANCE-V1` |
| Stage | I3 provenance |
| Purpose | 用 source-derived shared arrays、manifest 和重复运行关闭历史 provenance gate。 |
| Current path | `test/root-ready/provenance-closure/` |
| Entry point | [`run_provenance_closure.m`](root-ready/provenance-closure/run_provenance_closure.m) |
| Authoritative report | 最终权威是 [`output/repeat/report.md`](root-ready/provenance-closure/output/repeat/report.md)；它取代 baseline 作为最终 repeat verdict。 |
| Status | `frozen`；`SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`，但 I3 已退出 current gate。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i3-provenance/README\|I3 archive summary]] |

## I4 numerical qualification

### I4-ANALYTIC-READINESS-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-ANALYTIC-READINESS-V1` |
| Stage | I4 numerical qualification |
| Purpose | 在旧双椭圆几何上检查 analytic branch、chart、small disk、CR 和必要负例。 |
| Current path | `test/root-ready/analytic-readiness/` |
| Entry point | [`run_analytic_readiness.m`](root-ready/analytic-readiness/run_analytic_readiness.m) |
| Authoritative report | 最终权威是 [`output/repeat/report.md`](root-ready/analytic-readiness/output/repeat/report.md)，而非 baseline。 |
| Status | `negative evidence`；可复现 early stop，旧几何与 coupling 已被当前路线取代。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-FLISS-BASE-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-FLISS-BASE-V1` |
| Stage | I4 numerical qualification |
| Purpose | 用有限差分复现 Fliss smooth-profile 缺陷候选，并以 sharp-disk BIE 作分离的诊断 Track B。 |
| Current path | `test/i4-fliss-2013/` |
| Entry point | [`run_i4_fliss_experiment.m`](i4-fliss-2013/run_i4_fliss_experiment.m)，profile `baseline` |
| Authoritative report | [`output/baseline/report.md`](i4-fliss-2013/output/baseline/report.md) |
| Status | `frozen / mixed verdict`；Track A candidate ready，Track B mode completeness blocked。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-FLISS-EDGE-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-FLISS-EDGE-V1` |
| Stage | I4 numerical qualification |
| Purpose | 对 Fliss Track A 的最近 band edges 作共享节点的定向加密确认。 |
| Current path | `test/i4-fliss-2013/` |
| Entry point | [`run_targeted_edge_confirm.m`](i4-fliss-2013/run_targeted_edge_confirm.m) |
| Authoritative report | [`output/targeted-edge-confirm/report.md`](i4-fliss-2013/output/targeted-edge-confirm/report.md) |
| Status | `frozen`；这是 Track A edge confirmation 的最终权威报告。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-SHARP-PENCIL-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-SHARP-PENCIL-V1` |
| Stage | I4 numerical qualification |
| Purpose | 在冻结 sharp-disk 单点上诊断 transmission rank 和 projective QZ multiplier 缺失机制。 |
| Current path | `test/i4-fliss-2013/` |
| Entry point | [`run_bie_pencil_diagnostic.m`](i4-fliss-2013/run_bie_pencil_diagnostic.m) |
| Authoritative report | [`output/bie-pencil-diagnostic/report.md`](i4-fliss-2013/output/bie-pencil-diagnostic/report.md) |
| Status | `negative evidence`；diagnostic-only，不作 defect-root 声称。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-BIDIR-PENCIL-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-BIDIR-PENCIL-V1` |
| Stage | I4 numerical qualification |
| Purpose | 在同一 sharp-disk 单点上独立构造双向 pencil basis 并检查残差、配对、trace rank 和缩放。 |
| Current path | `test/i4-fliss-2013/` |
| Entry point | [`run_bie_bidirectional_pencil_diagnostic.m`](i4-fliss-2013/run_bie_bidirectional_pencil_diagnostic.m) |
| Authoritative report | [`output/bie-bidirectional-pencil/report.md`](i4-fliss-2013/output/bie-bidirectional-pencil/report.md) |
| Status | `negative evidence`；`BIE_PROJECTIVE_SUBSPACE_BLOCKED`。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-RAYLEIGH-BUDGET-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-RAYLEIGH-BUDGET-V1` |
| Stage | I4 numerical qualification |
| Purpose | 分离检查 Rayleigh trace budget、QZ/doubling action onset、wall clearance 和离散敏感性。 |
| Current path | `test/i4-rayleigh-budget/` |
| Entry point | [`run_i4_rayleigh_budget_batch.m`](i4-rayleigh-budget/run_i4_rayleigh_budget_batch.m)，profile `all` |
| Authoritative report | 批次权威是 [`global-summary.txt`](i4-rayleigh-budget/output/batch-all/global-summary.txt)、[`gate-summary.txt`](i4-rayleigh-budget/output/batch-all/gate-summary.txt) 和 [`case-summary.csv`](i4-rayleigh-budget/output/batch-all/case-summary.csv)；代表性 central-high case 的具体报告是 [`report.md`](i4-rayleigh-budget/output/batch-case-central-hi-d0p30-k1p860369599-high/report.md)。当前没有 aggregate `report.md`。 |
| Status | `frozen / reference-uncertified`；批次 action ledger 是 paired sensitivity 的权威，不能据此宣称全局已认证预算。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-EXTRACT-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-EXTRACT-V1` |
| Stage | I4 numerical qualification |
| Purpose | 用 Fourier/Bessel oracle 检查逐模态 extractor 实现，并记录它不能独立认证谱表示的边界。 |
| Current path | `test/i4-extract/` |
| Entry point | [`run_i4_extract_oracles.m`](i4-extract/run_i4_extract_oracles.m)，profile `canonical` |
| Authoritative report | [`output/canonical/report.md`](i4-extract/output/canonical/report.md) |
| Status | `negative evidence`；mandatory pass 为 0，不能当作独立 spectral-extraction closure。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-PROXY-SOLVER-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-PROXY-SOLVER-V1` |
| Stage | I4 numerical qualification |
| Purpose | 固定 proxy systems，仅比较 Octave least-squares solver path、rank cutoff 和 point-value 误差。 |
| Current path | `test/i4-extract/proxy-solver/` |
| Entry point | [`run_i4_proxy_solver.m`](i4-extract/proxy-solver/run_i4_proxy_solver.m) |
| Authoritative report | [`../output/proxy-solver/report.md`](i4-extract/output/proxy-solver/report.md) |
| Status | `negative evidence`；`PROXY_SOLVER_DIAGNOSTIC_UNRESOLVED`，不认证 wall action。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-THREE-PATH-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-THREE-PATH-V1` |
| Stage | I4 numerical qualification |
| Purpose | 首次比较 Ewald、package MFS/proxy 与 Rayleigh 的 point values 和完整 SLP-D wall action。 |
| Current path | `test/i4-three-path/` |
| Entry point | [`run_i4_three_path.m`](i4-three-path/run_i4_three_path.m)，profile `slp` |
| Authoritative report | [`output/canonical/report.md`](i4-three-path/output/canonical/report.md) |
| Status | `negative evidence`；Octave authority run 为 `SLP_D_UNCERTIFIED`，隔离出当时的 package/MFS path discrepancy。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-DERIVATIVE-ACTIONS-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-DERIVATIVE-ACTIONS-V1` |
| Stage | I4 numerical qualification |
| Purpose | 在 MATLAB 中认证 Ewald gradient/Hessian，并顺序比较四种 SLP/DLP、D/N wall actions。 |
| Current path | `test/i4-three-path-derivatives/` |
| Entry point | [`run_i4_three_path_derivatives.m`](i4-three-path-derivatives/run_i4_three_path_derivatives.m)，profile `full` |
| Authoritative report | [`output/canonical/report.md`](i4-three-path-derivatives/output/canonical/report.md) |
| Status | `frozen / sequential stop`；Ewald derivatives 与 SLP-D 通过，SLP-N 之后的层按当时 first-failure policy 停止。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-PACKAGE-POINT-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-PACKAGE-POINT-V1` |
| Stage | I4 numerical qualification |
| Purpose | 不构造 wall matrix，隔离 package point gradient/Hessian、axis wrapper、rank 和 proxy-level 敏感性。 |
| Current path | `test/i4-three-path-derivatives/` |
| Entry point | [`run_i4_package_point_diagnostic.m`](i4-three-path-derivatives/run_i4_package_point_diagnostic.m) |
| Authoritative report | [`output/package-point-diagnostic/report.md`](i4-three-path-derivatives/output/package-point-diagnostic/report.md) |
| Status | `negative evidence`；solver/proxy sensitivity diagnostic，不替代完整 wall-action gate。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-PROXY-RULE-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-PROXY-RULE-V1` |
| Stage | I4 numerical qualification |
| Purpose | 预注册并验证 `proxy_dist/d=0.2` 的 singularity-aware source-placement 修复。 |
| Current path | `test/i4-proxy-rule/` |
| Entry point | [`run_i4_proxy_rule.m`](i4-proxy-rule/run_i4_proxy_rule.m)，profile `full` |
| Authoritative report | [`output/canonical/report.md`](i4-proxy-rule/output/canonical/report.md) |
| Status | `frozen`；`SLP_D_N_CERTIFIED_PROXY_RATIO_0P2`。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### I4-DLP-TRACE-V1

| 字段 | 内容 |
|---|---|
| Experiment ID | `I4-DLP-TRACE-V1` |
| Stage | I4 numerical qualification |
| Purpose | 顺序认证 DLP-D、DLP-N 三路径 wall actions，并以完整 wall samples 认证有限 trace bandwidth。 |
| Current path | `test/i4-dlp-trace/` |
| Entry point | [`run_i4_dlp_trace.m`](i4-dlp-trace/run_i4_dlp_trace.m)，profile `full` |
| Authoritative report | [`output/canonical/report.md`](i4-dlp-trace/output/canonical/report.md)；[`audit-summary.md`](i4-dlp-trace/output/canonical/audit-summary.md) 是补充审计摘要。 |
| Status | `frozen`；`DLP_D_N_MTRACE48_CERTIFIED`，只覆盖冻结参数和离散部件，不授权 DtN 或 root locator。 |
| Implementation summary | [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/README\|I4 archive summary]] |

### 未纳入编号的 I4 脚手架

`test/i4-fliss-2013/run_bie_m4_m5_scan.m` 已实现但按上游 port-basis gate 的结论明确没有
运行，因而没有 output 或权威报告。本索引不为未执行实验分配稳定 Experiment ID，也不把
脚本说明当作数值结果。

## I5 root isolation

尚无已授权或已执行的 I5 实验，因此不分配 Experiment ID。

## I6 estimator and effectivity

尚无已授权或已执行的 I6 实验，因此不分配 Experiment ID。

## I7 independent validation

尚无已授权或已执行的 I7 实验，因此不分配 Experiment ID。
