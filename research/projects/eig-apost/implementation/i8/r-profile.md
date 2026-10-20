# I8 单点评价耗时独立审查

## A. 审查框架

审查对象是 I8 内部诊断 `I8-POINT-PROFILE-V1`：在不改变模型、空间参数、公式和原定位含义的前提下，判断原入口 `locate_i8(k,1,1)` 的单点评价时间主要花在哪里，以及现有证据是否足以把下一步优化研究优先放在 smooth proxy correction field 的局部展开。当前阶段是 baseline 配置下的数值工程诊断，预期输出为可复现计时、profiler 归属、数值一致性和有边界的优化建议，不是加速实现、离散收敛或谱认证。

冻结对象为实验工作树分支 `codex/epost` 的起始 HEAD `f3f8d2acbdb89db1e9c6ad9efef26286ce7bea15`、$k_0=1.7562818500073463$、邻点 $k_1=1.7562818560000002$ 和 `(ntot,nside,ntop,nproxy,mpw,M)=(256,160,160,80,32,48)`。成功标准是：两个点有预热后三次正常计时；四指标与原入口和历史记录一致；一级账目互斥；热点细分不重复父子累计；环境与资源可解释。

我独立检查了 [[research/projects/eig-apost/implementation/i8/p-profile|诊断设计]]、[[test/i8/profile-v1/profile_i8|诊断入口]]、原 [[test/i8/locate-v1/locate_i8|定位入口]]、`qpgreen_mfs_pairmat`、`precomp_proxy`、`construct_A_QP`、`construct_S`，以及 run-02 的 `calls.csv`、`comparisons.csv`、`resources.csv`、两组原始 `profile-k*.mat` 和从同一 `FunctionTable` 导出的 function/edge/line CSV。我用只读 MATLAB-v5 解析直接读取两份 MAT 的 `FunctionTable`、`Children` 和 `ExecutedLines`，抽查的 call count 与 time 和 CSV 逐项一致。还核对了 run-01 失败记录、工作树范围和 [[test/i8/profile-v1/README|实验说明]]。本审查没有运行 MATLAB，也没有修改实验代码或公共包。

## B. Verdict

**PASS WITH CONDITIONS（高置信度）**。两个代表点的 warmed outer 中位数为 8.066692 s 与 8.034689 s，全部 11 次调用的四指标逐位一致。两次 profiler 都把 91.53%--92.39% 的 `LOCAL_point` 时间归到只负责 smooth proxy 场分批直接求值的 `LOCAL_h2d_chunked_public`；它到 `h2d_directch` 的 child edge 记录了 256 次调用，又解释了几乎全部该时间。一级账目和更深的互斥重建都闭合，资源在限额内。因此，在冻结 baseline 上把下一步优化研究优先放在局部展开是有充分数值证据的，方向门为 **GO**。条件是把占比视为 profiler 域的两次快照，把 Amdahl 数字明确标成理想上限，并在任何加速实现后用无 profiler 的完整原入口复测实际收益。

## C. 最强挑战

最可能推翻“优先局部展开”的失败机制，是 profiler 把别的昂贵工作错误归入了 proxy helper，或单次 profiled 调用不能代表正常运行。代码和 raw edge data 不支持前一种解释：helper 只把 `proxy.Z, proxy.q` 在 pair-difference targets 上分成 512 点批次交给公共 `h2d_directch`；两胞元共 256 个 child calls，耗时 7.501728/7.529578 s，而 pairmat 直接自由空间单源 edges 只有 0.012194/0.011821 s。后一风险仍存在，但两个 profiled outer time 与正常中位数只差约 0.9%/2.7%，且两点得到同一热点排序，足以支持本轮方向判断。

## D. Findings

1. **IMPORTANT CAVEAT — 子阶段份额是 profiler 域证据。** 位置：run-02 `profile-k0/k1` 的 FunctionTable/edges/lines 及 I8-P1。证据：每点只有一次 profiled 调用；无 profiler 的重复只测了完整入口。后果：91.53%--92.39% 可以确定热点和优先级，不能直接当作优化后的正常运行收益。未确定性来自 profiler 开销、运行顺序和系统负载。最便宜的决定性检查是在未来实现任何优化后，用相同两点、相同三次 warmed 完整调用与本基线对比；当前交付不需追加运行。

2. **MINOR CAVEAT — 未把 smooth proxy 时间按 lead/center、势/梯度/Hessian 再分开。** 位置：两个 proxy helper calls 汇总到同一 profiler function row，对应 I8-P2。后果：不能声称某一胞元或某一导数阶单独主导，但不影响“同一 helper 是整体热点”。最便宜的下一检查是仅在实际设计局部展开时加入调用上下文或算子阶计时；它不改变当前 acceptance criterion。

3. **MINOR CAVEAT — 运行外部开销和两个短实现检查的资源未完全分离。** 位置：run-02 monitor 总时间与 outer timer 差额、正式运行前的 implementation checks、run-01 preflight failure。run-02 已完整监控且没有其他 MATLAB；run-01 在 `ps` preflight 被拒，`root_pid=none`，没有数值启动。后果：不能把总进程时间拆成精确启动/导出/退出份额，也不能给两个非科学短检查的 RSS；不影响正式单点评价或热点结论。最便宜的下一检查是在以后确有需要时增加边界时间戳；本轮无需重跑。

没有 blocker。

## E. 实现与计时审计

`profile_i8` 只调用原 `locate_i8(k,1,1)`，没有复制 point helper、遮蔽公共包或改变求解顺序。`construct_S` 把 `[B_L,B_R]` 合成一个 `rhs_all`，每胞元只有一次多右端反斜杠；profiler 的 line 140 两胞元合计仅 0.030260/0.031686 s，不能描述成逐右端重复分解。

profiler 的一级互斥账目为：

| 阶段 | $k_0$ s / 占比 | $k_1$ s / 占比 |
|---|---:|---:|
| lead 构造，扣除 QZ | 4.095395 / 50.36% | 4.116130 / 49.96% |
| 中心构造 | 3.916038 / 48.16% | 4.007553 / 48.64% |
| QZ/DtN | 0.098308 / 1.21% | 0.094437 / 1.15% |
| 匹配、权重与两个 SVD | 0.022178 / 0.27% | 0.020660 / 0.25% |
| `LOCAL_point` | 8.131919 / 100% | 8.238779 / 100% |

我用 raw function totals、parent-specific child edges 和 executed-line time 另行重建了更深的互斥账目：

| 互斥分项 | $k_0$ s / 占比 | $k_1$ s / 占比 |
|---|---:|---:|
| smooth proxy correction | 7.513075 / 92.39% | 7.540684 / 91.53% |
| pairmat 自由空间单源 | 0.012194 / 0.15% | 0.011821 / 0.14% |
| pairmat 其余工作 | 0.013102 / 0.16% | 0.012484 / 0.15% |
| `construct_A_QP` 其余装配 | 0.203478 / 2.50% | 0.251262 / 3.05% |
| BIE 多右端求解 | 0.030260 / 0.37% | 0.031686 / 0.38% |
| `construct_S` 其余工作 | 0.018929 / 0.23% | 0.025798 / 0.31% |
| 两次 proxy 预计算 | 0.216391 / 2.66% | 0.245493 / 2.98% |
| 几何、channels 与胞元 wrapper | 0.004005 / 0.05% | 0.004455 / 0.05% |
| QZ/DtN | 0.098308 / 1.21% | 0.094437 / 1.15% |
| 匹配、权重与 SVD | 0.022178 / 0.27% | 0.020660 / 0.25% |

两列分别闭合到 8.131919 和 8.238779 s；没有将父函数累计与子函数累计相加。导出的 92 个 function rows 中，`TotalTime-child edge time` 均非负，未截断的 `derived_self_seconds` 与该差逐项一致。

静态与 call-count 审计还确认了单点评价内部的重复：两胞元以完全相同参数各算一次 `precomp_proxy` 和 `rayleigh_channels`；S/T 装配重复同参 `kress_mn_splits`，`LOCAL_kress_matrix(256)` 重复六次；pairmat 先算自由空间项，随后装配 helper 又在相同 off-diagonal 点差上重算自由空间量以提取 proxy correction。这些重复存在，但量级较小。按两次 `precomp_proxy` 总时间的一半估算，复用一次只覆盖整点约 1.33%/1.49%，理想整体上限约 1.013/1.015 倍。

数值方面，candidate 的近零四指标和 ordinary neighbor 的四指标在 first/warmup/repeats/profile 中绝对差全为零；邻点也逐位复现 I8.1 run-06/run-07 的记录。正式环境为 MATLAB R2023b、MACA64，报告 11 个最大计算线程；preflight 与全过程没有其他 MATLAB。100.823534 s 的受监控进程峰值 RSS 为 1,366,786,048 bytes，低于 2 GiB；一分 load 上升伴随 MATLAB 约十核 CPU 使用，没有证据显示明显外部负载打断正式计时。

## F. 经受审查的结论

- smooth proxy 场求值是冻结 baseline 单点的主导热点，且在两个代表点上稳定占约 92%。
- 直接自由空间单源、BIE 多右端求解、QZ/DtN、匹配和 SVD 都不是当前瓶颈。
- lead 与中心分别约占一半；lead 只慢 0.109--0.179 s，没有明显量级差异。
- 同参重复计算确实存在，但先复用 proxy 预计算或小型 Kress 数据只能给小幅收益。
- 若把 smooth proxy 时间理想化为完全消失，按占比得到的整体上限是 11.8--13.1 倍；这是理想 Amdahl 上限，不是已实现速度，真实局部展开仍有构造与求值成本。

## G. 最小推进动作

本诊断无需修复或补跑即可接受。下一门只需把局部展开研究限定在 `LOCAL_h2d_chunked_public` 所代表的 320-source smooth correction，并在实现后沿用本轮两个点做三次 warmed、无 profiler 的原入口 before/after；同时检查四指标绝对差。可以顺手评估同参 proxy 缓存，但不应让约 1.5% 的 setup 复用取代主热点工作。本轮到此停止，不进入实现。

## H. Open-problem handoff

| Stage | Category | Blocking scope | Cheapest next check | Suggested ledger status |
|---|---|---|---|---|
| I8 单点评价耗时诊断 / I8-P1 | important caveat | 不阻断当前诊断；限制对正常运行收益的外推 | 未来优化后，以相同两点的 warmed unprofiled 完整入口验证 | `OPEN` |
| I8 单点评价耗时诊断 / I8-P2 | minor caveat | 不阻断热点方向；限制胞元/算子阶细分和短检查资源陈述 | 仅在实现决策需要时增加上下文计时；本轮不补跑 | `WONT-FIX FOR CURRENT CLAIM` |
