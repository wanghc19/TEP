# I7：中心形状扰动下的 guided-mode 数值扫描

I7 研究在左右周期 half-guide 不变时，中心 inclusion 的形状变化如何影响 fixed-$\beta$
guided-mode candidate。当前实现以 main 参考提交
`54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb` 中的 `projgap.m` 与 `betagmode.m` 为基准；
不修改这些示例或 I1--I6。核调用修订仅在方案 1 实测资源失败后允许
[[research/projects/eig-apost/implementation/i7/design-7-1a|设计文件]]第 6 节所述的一处公共
pair-matrix evaluator hook；不修改公共核公式。

## 模型和边界

- $\beta=0.5$，周期 $d=1$，人工墙 $X_L=-0.5$、$X_R=0.5$；背景参数沿用 main 示例。
- 所有 inclusion 均取 `epsrel=17`。左右 half-guide 保持半径 $0.2$ 的圆。
- 中心列单独改为轴对齐椭圆，$x/y$ 半轴为 $0.25/0.16$。其面积
  $\pi(0.25)(0.16)=\pi(0.2)^2$，与原圆等面积；本轮不扫描材料或几何参数。
- 数值 projected gap 由 main `projgap.m` 的圆形周期介质计算。I7.1 只在该范围内作有限层、
  有预算的局部扫描；结果不称全局搜索或连续谱认证。

## 两阶段里程碑

| Milestone | 任务 | 状态 | 交付 |
|---|---|---|---|
| I7.1 | 用中心椭圆的 scattering blocks 取代空中心传播，分层扫描 `aphys_ratio` 并以冻结 final 空间离散确认候选 | `PASS WITH CONDITIONS / CURRENT SCAN BEST AT LEFT BOUNDARY` | [[research/projects/eig-apost/implementation/i7/design-7-1a|设计]]、[[test/i7/scan-v1/README|实验入口]]、[[research/projects/eig-apost/implementation/i7/review-7-1a|独立审查]] |
| I7.2 | 在 I7.1 候选附近复用 I2.2 当前的 $H_{\mathrm{sym}}$ 端点 sign count，并按 I2.3 分别检查空间离散稳定性与同模态比较 | `PLANNED; NOT STARTED` | 后续独立设计；本轮不运行、不声称结果 |

I7.2 的 sign count 只作 numerical corroboration，不解释为 raw non-Hermitian matrix 的严格
inertia。离散比较必须区分边界离散轴与 trace cutoff 轴，并报告同一 mode；零 observed
candidate drift 也不构成 root、minimizer 或连续特征值收敛证明。

## 历史 I7.1 数值结果

`attempt-1/run-01` 于 2026-09-22 在 MATLAB R2023b 完成，进程退出码为 0。17 个
`projgap` 采样点全部有效，故本轮 numerical window 是 $[1.45,2.25]$；两端都是预设扫描
界限，不是计算出的 band edges。$0.025$ 筛选网格的 33 个点全部有效，没有严格内点低谷；
筛选最低点位于左边界 $k=1.45$。final 配置共完成 6 个 unique 评价：最宽 window 中点的
pilot $k=1.85$，以及 $[1.45,1.475]$ 上的五点确认网格。所有 final 点有效，确认网格的
`aphys_ratio` 从左端开始递增，因此按冻结的边界规则停止。

保存的 `out` 为

| Field | Value |
|---|---:|
| `beta` | $0.5$ |
| `k` | $1.45$ |
| `adef_sigma` | $3.6371178757473972$ |
| `adef_ratio` | $0.0060199359811023666$ |
| `aphys_sigma` | $1.3746238403333091$ |
| `aphys_ratio` | $0.31371305311538561$ |
| `runtime` | $193.156499250$ s |

四个矩阵指标来自该同一 final 配置点；独立重算的 relative defect 为 0。受监测命令的 wall time 为 217 s，
process-tree peak RSS 为 870,367,232 bytes，低于当时的 2,000,000,000-byte 限额。该历史
`run-01` 使用的 I7-local kernel 与公共实现的 potential、gradient、Hessian 三项相对误差均为 0；
本轮核调用修订不把该 formula-copy 路径作为现行实现。完整产物见
[[test/i7/scan-v1/output/attempt-1/run-01/summary.txt|summary]]、
[[test/i7/scan-v1/output/attempt-1/run-01/history.csv|point history]] 和
[[test/i7/scan-v1/output/attempt-1/run-01/monitor-status.txt|resource status]]。

跑后 MATLAB audit 的八项门全部通过，包括七字段/标量、final tuple+$M=48$、全部有效 final
点 argmin、同点四指标、repeat、trace stop 和 kernel parity；audit 自身 wall time 为 26 s，
peak process-tree RSS 为 1,019,445,248 bytes。`checkcode` 只有 6 条已解释的 bounded append 与
cleanup-guard advisories，没有 syntax/error finding。详见
[[test/i7/scan-v1/output/attempt-1/run-01/audit/audit.txt|audit]]。
从 2026-09-22 08:49:52 UTC 首次行动到 09:28:49 UTC 交付检查，总任务耗时 2,337 s
（38 分 57 秒）；正式 run 与 audit 的受监测 MATLAB wall time 合计 243 s。计时记录见
[[test/i7/scan-v1/output/attempt-1/run-01/task-time.json|task time]]。

该结果是已覆盖数值区间的“当前扫描最佳点”。因为最小值在扫描下边界且没有观察到内点 dip，
它不是已确认特征值，也不说明更宽区间中的行为。

## 核调用修订

本轮保持模型、两类离散、扫描节点、候选规则和 `out` 不变，只修订核调用路径。
决策顺序预先固定为：

1. 先移除实验目录的 package shadow，用公共原版 `kernel.h2d_directch` 实际运行一个 final 点；
   资源门为 30 分钟和 3 GB（3,000,000,000 bytes）。若成功即采用公共原版并停止核方案修改。
2. 只有方案 1 被实际时间、RSS、MATLAB 异常退出或分配失败否决时，才允许最小 batching 适配：
   公共 pair-matrix 例程提供缺省关闭的 evaluator hook，I7 的 `LOCAL_h2d_chunked_public` 仅按 target
   列分批，每批仍调用公共 `kernel.h2d_directch`；不复制核公式，也不使用 package shadow。
3. 只有方案 2 实测越过资源门，或存在记录明确的调用链或接口障碍时，才重新考虑 I7-local 核实现。

方案 1 的实测优先于静态内存估计。历史 `attempt-1/run-01` 的命令、数据和解释保持不变；修订后的
实测另存新运行目录，不覆盖历史证据。

方案 1 已于 2026-09-22 实测否决。公共原版路径完成 17 个 gap 点后进入首个 final pilot；监测器
在第 42 s 采样到 process-tree peak RSS 3,105,751,040 bytes，越过
3,000,000,000-byte 硬门并终止进程。包括终止等待在内的 wall time 为 47 s，exit code 为 143。
公共解析路径、原命令、逐点日志和资源
时间序列保存在
[[test/i7/scan-v1/output/attempt-1/kernel-revision/scheme-1-run-01/monitor-status.txt|scheme-1 monitor]]
及同目录产物中。该失败使流程按预定顺序进入方案 2；它不改变扫描模型，且尚未触发方案 3 的条件。

方案 2 的现行正式扫描 `scheme-2-run-01` 已完成，exit code 为 0。回归中的公共整批 direct 三输出、
pair-matrix 显式公共 evaluator 六输出及 target-batched evaluator 六输出相对差异均为 0；解析到的
`kernel.h2d_directch` 是仓库公共文件，历史 `tmp/` 不在 MATLAB path。正式扫描 wall time 为 203 s，
process-tree peak RSS 为 1,071,398,912 bytes，低于 3 GB 硬门。当前保存的 `out` 为

| Field | Value |
|---|---:|
| `beta` | $0.5$ |
| `k` | $1.45$ |
| `adef_sigma` | $3.6371178757473972$ |
| `adef_ratio` | $0.0060199359811023666$ |
| `aphys_sigma` | $1.3746238403333091$ |
| `aphys_ratio` | $0.31371305311538561$ |
| `runtime` | $182.508327708$ s |

它仍是左扫描边界上的“当前扫描最佳点”，没有观察到严格内点 dip，也不是已确认特征值。现行产物见
[[test/i7/scan-v1/output/attempt-1/kernel-revision/scheme-2-run-01/summary.txt|scheme-2 summary]]、
[[test/i7/scan-v1/output/attempt-1/kernel-revision/scheme-2-run-01/history.csv|scheme-2 history]] 和
[[test/i7/scan-v1/output/attempt-1/kernel-revision/scheme-2-run-01/monitor-status.txt|scheme-2 monitor]]。
修正后的跑后产物一致性 audit `audit-run-02` 以 exit code 0 通过：旧/新 `out` 的前六个标量差为 0，
history 的科学字段（不含逐点评价耗时）、模型与离散配置、覆盖、final argmin、核回归、公共路径和 `tmp/` path 排除检查全部通过；
audit wall time 为 17 s，peak process-tree RSS 为 851,787,776 bytes。第一次只读 audit 命令因一个
括号语法错误 exit 1，其 21 s 日志仍保留且未改写正式产物。通过记录见
[[test/i7/scan-v1/output/attempt-1/kernel-revision/scheme-2-run-01/audit-run-02/audit.txt|scheme-2 audit]]。
本轮四次受监测 MATLAB 调用的 wall time 合计 288 s；全轮最高 RSS 是方案 1 触发终止的
3,105,751,040 bytes，成功的方案 2 正式扫描峰值为 1,071,398,912 bytes。方案 2 已满足资源和
数值等价门，因此方案 3 未采用。

本轮从 2026-09-22 14:47:14 UTC 开始，到 15:22:50 UTC 交付检查耗时 2137 s
（约 35 分 37 秒），低于 90 分钟；机器记录见
[[test/i7/scan-v1/output/kernel-revision/task-time.json|本轮任务计时]]。


## 阅读和复现入口

1. [[research/projects/eig-apost/implementation/i7/design-7-1a|I7.1 frozen design]]；
2. [[test/i7/scan-v1/README|scan-v1 experiment index]] 与其 `output/attempt-1/` 运行记录；
3. [[research/projects/eig-apost/implementation/i7/review-7-1a|independent review]]。

## I7 待办与问题

本表是 I7 唯一的短问题表；审查文件只链接这里，不复制问题清单。

| ID | 类别 | 当前问题 | 最小下一检查 | 状态 |
|---|---|---|---|---|
| I7-Q1 | important caveat | 本轮候选来自有限 projected-gap 窗口和有限层网格；浅 dip 或边界最小不能升级为已确认特征值 | I7.2 仅在 I7.1 结果可复现后做端点 sign count 与同模态离散比较 | open |
| I7-Q2 | blocker | 公共原版在首个 final pilot 达到 3,105,751,040 bytes，实测超过 3 GB；现行方案 2 只让 proxy-source term 使用 target-batched 公共核 evaluator | `scheme-2-run-01` 及 `audit-run-02` 已保存零差异、公共 `which` 路径、exit 0、1,071,398,912-byte formal peak 与完整一致性检查 | closed for current I7.1 implementation |
