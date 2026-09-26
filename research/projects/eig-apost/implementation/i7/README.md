# I7：中心 inclusion 扰动的 guided-mode 数值实验

I7 研究在左右周期 half-guide 不变时，中心 inclusion 的形状和材料变化如何影响 fixed-$\beta$
guided-mode candidate。当前实现以 main 参考提交
`54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb` 中的 `projgap.m` 与 `betagmode.m` 为基准；
不修改这些示例或 I1--I6。核调用修订仅在方案 1 实测资源失败后允许
[[research/projects/eig-apost/implementation/i7/design-7-1a|设计文件]]第 6 节所述的一处公共
pair-matrix evaluator hook；不修改公共核公式。

## 模型和边界

- $\beta=0.5$，周期 $d=1$，人工墙 $X_L=-0.5$、$X_R=0.5$；背景参数沿用 main 示例。
- 当前左右 half-guide 保持半径 $0.2$ 的圆、`epsrel=17`；中心椭圆为 `epsrel_center=2`。
  初始全 inclusion `epsrel=17` 的结果保留为历史，不能与当前模型混用。
- 中心列单独改为轴对齐椭圆，$x/y$ 半轴为 $0.25/0.16$。其面积
  $\pi(0.25)(0.16)=\pi(0.2)^2$，与原圆等面积；本轮不扫描材料或几何参数。
- 数值 projected gap 由 main `projgap.m` 的圆形周期介质计算。I7.1 只在该范围内作有限层、
  有预算的局部扫描；结果不称全局搜索或连续谱认证。

## 两阶段里程碑

| Milestone | 任务 | 状态 | 交付 |
|---|---|---|---|
| I7.1 | 中心 `epsrel=2` 时观察到潜在内点 dip，完成固定 final 配置下的局部定位；细网格出现平台迹象 | `PASS WITH CONDITIONS / LOCAL DIP CANDIDATE` | [[research/projects/eig-apost/implementation/i7/design-7-1a|设计]]、[[test/i7/scan-v1/README|实验入口]]、[[research/projects/eig-apost/implementation/i7/review-7-1a|独立审查]] |
| I7.2 | 在固定肩点 $1.753125,1.75625$ 构造物理迹矩阵，执行 Hermitian-part 惯性型端点诊断 | `COMPLETE / JUMP; delta_negative=+1` | [[research/projects/eig-apost/implementation/i7/design-7-2a|设计]]、[[test/i7/inertia-v1/check_i7_inertia|入口]]、[[research/projects/eig-apost/implementation/i7/review-7-2a|独立审查]] |

I7.2 的 sign count 只作 numerical corroboration，不解释为 raw non-Hermitian matrix 的严格
inertia。原计划的跨离散阶数稳定性和同模态比较保留为**后续未执行事项**，不计入本轮 I7.2
完成状态。后续比较须区分边界离散轴与 trace cutoff 轴，并报告同一 mode；零 observed
candidate drift 也不构成 root、minimizer 或连续特征值收敛证明。

## 当前 I7.1：中心 `epsrel=2`

沿用原数值方法，仅降低中心材料后，宽扫描和局部均匀定位均观察到潜在内点 dip。
固定 final tuple $(256,160,160,80,32)$、$M=48$ 下的当前局部采样最佳点为
$k=1.7545053299700002$，`aphys_ratio` 为 $3.0399993275794239\times10^{-4}$，
`aphys_sigma` 为 $8.6957802722225058\times10^{-4}$；最终同点四指标复算差均为零。
最细邻点完整宽度约 $2.00\times10^{-11}$，但采样值已出现非平滑平台，不能将其解释为
十位准确定位或已确认的连续特征值。详见 [[test/i7/scan-v1/README#Attempt 3 local uniform localization 2026-09-25|局部定位记录]]
和 [[test/i7/scan-v1/output/attempt-3/run-12/out.json|保存的 out]]。

全 `epsrel=17` 的初始模型在已覆盖范围内未观察到显著内点 dip，最佳点位于左边界；该历史
结论保持有效，但不描述当前中心 `epsrel=2` 的实验。

## I7.2：固定端点 Hermitian-part 诊断

2026-09-25 的 `inertia-v1/output/attempt-1/run-01` 已完成。中心 `epsrel=2`、两侧
`epsrel=17`，空间配置保持 $(256,160,160,80,32)$、$M=48$。从当前中心 scattering blocks
构造 $T,N_0,L$，独立核验 $A_{\mathrm{def}}=N_0-LT$ 后以右线性求解计算
$H=A_{\mathrm{def}}/T$，只对 $H_{\mathrm{sym}}=(H+H^*)/2$ 判号。

程序执行成功；科学结果为 **JUMP**，负计数差
$\Delta_-=n_-(k_R)-n_-(k_L)=+1$，正计数差为 $-1$。下表两项误差为
[[research/projects/eig-apost/implementation/i7/design-7-2a|设计第 3 节]]定义的
normalized Frobenius 组装/求解残差；门为 $1000n\epsilon_{\mathrm{mach}}=4.30766533555\times10^{-11}$，
$n=194$，`rcond(T)` 门为 $10^{-8}$。

| 端点 | k | rcond(T) | 组装误差 | 求解误差 | s | dH | eta (100) | min abs eigenvalue | (+, -, unresolved) | 敏感性 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| L | 1.753125 | 0.517664781804 | 7.75534071e-19 | 5.55519314e-19 | 604.175615555 | 0.00694036318057 | 0.00694036578315 | 0.0102440899425 | (194, 0, 0) | STABLE |
| R | 1.75625 | 0.517637176836 | 5.82320415e-19 | 3.83669906e-19 | 604.175579252 | 0.00697609252827 | 0.00697609513086 | 0.0129547448104 | (193, 1, 0) | STABLE |

$c=50,100,200$ 三个系数的完整计数均为左端 $(194,0,0)$、右端 $(193,1,0)$；
$\eta_{50}$ 分别为 $0.0069403644818593563$、$0.0069760938295636123$，
$\eta_{200}$ 分别为 $0.0069403683857388893$、$0.006976097733442912$。
两端全部坐标/求解门通过，imaginary leakage 为零，无数值求解警告。

$d_H$ 明显非零且主导判号带，不能忽略。最小绝对特征值分别约为主带宽的 $1.476$ 和
$1.857$ 倍；这是本次冻结判据下的数值分离，不是严格误差上界。结论仅为既有局部 dip
增加一项 Hermitian-part sign-count 数值佐证；不推断 raw $H$ 的严格惯性、实根存在或
唯一性，也不确认连续算子的特征值。

MATLAB R2023b 正式命令包含端点计算及原矩阵的 eig/count 复核，exit code 为 0。
入口耗时 $21.43027775$ s，完整受监测 wall time 为 $42$ s，进程树峰值 RSS 为
1,107,099,648 bytes（每 $0.25$ s 采样），低于本轮累计 1800 s / 3,000,000,000-byte 限额。
没有失败运行；没有宽扫描、继续定位、绕数、跨离散阶数或同模态实验。

复现入口为 `[result,evidence] = check_i7_inertia()`；例如选择未使用的 `run-02`：

```sh
cd /Users/whc/Documents/Work/epost
run_dir="$PWD/test/i7/inertia-v1/output/attempt-1/run-02"
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab bash test/i7/run_matlab_monitored.sh "$run_dir" "cd(tempdir); addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i7/inertia-v1'); [result,evidence]=check_i7_inertia(); save(fullfile('$run_dir','result.mat'),'result','evidence'); disp(result);"
```

[[test/i7/inertia-v1/output/attempt-1/run-01/command.txt|实际完整命令]]、
[[test/i7/inertia-v1/output/attempt-1/run-01/result.json|端点原始结果]]、
[[test/i7/inertia-v1/output/attempt-1/run-01/endpoint-matrices.mat|原始矩阵]]、
[[test/i7/inertia-v1/output/attempt-1/run-01/resources.csv|RSS 记录]]、
[[research/projects/eig-apost/implementation/i7/review-7-2a|独立审查]]。
关键数值已在本节和设计/审查文档中保存，不依赖被忽略的 output 目录才能了解结论。

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
3. [[research/projects/eig-apost/implementation/i7/review-7-1a|I7.1 initial independent review]]；
4. [[research/projects/eig-apost/implementation/i7/design-7-2a|I7.2 endpoint design]] 与
   [[research/projects/eig-apost/implementation/i7/review-7-2a|I7.2 independent review]]。

## I7 待办与问题

本表是 I7 唯一的短问题表；审查文件只链接这里，不复制问题清单。

| ID | 类别 | 当前问题 | 最小下一检查 | 状态 |
|---|---|---|---|---|
| I7-Q1 | important caveat | 本轮候选来自有限 projected-gap 窗口和有限层网格；浅 dip 或边界最小不能升级为已确认特征值 | I7.2 仅完成本轮端点诊断；跨离散阶数与同模态比较另行设计，尚未执行 | open |
| I7-Q2 | blocker | 公共原版在首个 final pilot 达到 3,105,751,040 bytes，实测超过 3 GB；现行方案 2 只让 proxy-source term 使用 target-batched 公共核 evaluator | `scheme-2-run-01` 及 `audit-run-02` 已保存零差异、公共 `which` 路径、exit 0、1,071,398,912-byte formal peak 与完整一致性检查 | closed for current I7.1 implementation |
| I7-Q3 | important caveat | I7.2 的 raw $H$ 非 Hermitian；$\eta$ 是诊断带而非离散误差界，端点符号跳跃不推出 raw 实根或连续特征值 | 后续独立设计跨离散阶数和同模态检查；本轮不追加计算 | open; endpoint diagnostic complete |
