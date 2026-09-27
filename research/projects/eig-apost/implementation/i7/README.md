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

## 三阶段里程碑

| Milestone | 任务 | 状态 | 交付 |
|---|---|---|---|
| I7.1 | 中心 `epsrel=2` 时观察到潜在内点 dip，完成固定 final 配置下的局部定位；细网格出现平台迹象 | `PASS WITH CONDITIONS / LOCAL DIP CANDIDATE` | [[research/projects/eig-apost/implementation/i7/design-7-1a|设计]]、[[test/i7/scan-v1/README|实验入口]]、[[research/projects/eig-apost/implementation/i7/review-7-1a|独立审查]] |
| I7.2 | 在固定肩点 $1.753125,1.75625$ 构造物理迹矩阵，执行 Hermitian-part 惯性型端点诊断 | `COMPLETE / JUMP; delta_negative=+1` | [[research/projects/eig-apost/implementation/i7/design-7-2a|设计]]、[[test/i7/inertia-v1/check_i7_inertia|入口]]、[[research/projects/eig-apost/implementation/i7/review-7-2a|独立审查]] |
| I7.3 | 分开加密 Rayleigh 阶数与 inclusion 边界，检查同一物理墙面迹及共同局部网格位置 | `COMPLETE / STABLE_SAME_MODE; PASS WITH CONDITIONS` | [[research/projects/eig-apost/implementation/i7/design-7-3a|设计与符号映射]]、[[test/i7/refine-v1/check_i7_refinement|入口]]、[[research/projects/eig-apost/implementation/i7/review-7-3a|独立审查]] |

I7.2 的 sign count 只作 numerical corroboration，不解释为 raw non-Hermitian matrix 的严格
inertia。跨离散阶数稳定性和同模态比较现独立列为 I7.3，不追溯改变 I7.2 的完成范围。
I7.3 区分 inclusion 边界离散轴、Rayleigh cutoff 轴和固定的 proxy 拟合配置；零 observed
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

## I7.3：离散加密与同模态检查

2026-09-26 开始，冻结 $k_L=1.753125$、$k_0=1.7545053299700002$、
$k_R=1.75625$，模型保持中心 `epsrel_center=2`、两侧 `epsrel=17`。
六个必做配置为 `(ntot,M)=(256,48),(256,56),(256,64),(384,48),(512,48),(512,64)`；
其余 tuple 固定为 `(nside,ntop,nproxy,mpw)=(160,160,80,32)`。
`M` 是 Rayleigh 端口阶数，`nside/ntop` 是 proxy 拟合采样，`nproxy` 是 proxy 节点参数，
`mpw` 是该表示的 plane-wave 阶数，不能把它们混称为同一离散轴。

同模态比较使用物理墙面 Dirichlet trace。$H_{\mathrm{sym}}$ 特征向量已处于该坐标；
$A_{\mathrm{phys}}$ 右奇异向量按 $v\mapsto D_cv\mapsto TD_cv$ 转换。
左右墙分别按真实模态编号 $m$ 对齐后零填充，报告相位/尺度不变 overlap、次近模态、
新增高模能量和近简并子空间。完整判据及符号映射见
[[research/projects/eig-apost/implementation/i7/design-7-3a|设计]]；独立审查见
[[research/projects/eig-apost/implementation/i7/review-7-3a|审查]]。

资源监控仅在新实验目录适配，保留旧 monitor。为落实本轮 3,000,000,000-byte 上限，
提前终止线设为 2,300,000,000 bytes，同时监测本任务进程树及全部 MATLAB 进程树并集，
每 0.1 s 采样；启动前拒绝已有 MATLAB，运行中遇到外部 MATLAB 则只停止本任务。
同一 attempt 的非阻塞锁防止重复启动。内存早停、信号清理、锁拒绝和真实外部任务拦截
已经实际测试，证据保存在 `refine-v1/output/attempt-1/run-02/monitor-selftest/`。
`run-01` 是约 0.9 s 的启动失败预检，未进行科学评价，RSS 未采样；按 1 s 计入预算。
用户报告的 17 GB 事件来源未知，本轮没有将它归因于某项任务。

**实际结果：`COMPLETE / STABLE_SAME_MODE; PASS WITH CONDITIONS`。**

`attempt-1/run-04` 的 18 个点全部有效；六配置都在相同两个肩点保持负计数 $0\to1$。
$c=50,100,200$ 三带计数完全一致，全部端点 unresolved 为零。下表计数顺序为
`(positive,negative,unresolved)`，余量定义为 $\min|\lambda|-\eta_{100}$，
它不是严格误差界。正计数随矩阵维数增长，不作跨 $M$ 的逐项恒等要求。

| 配置 | `(ntot,M)` | L 计数 | R 计数 | $d_H(L)/d_H(R)$ | 余量 L / R |
|---|---|---|---|---|---|
| B | (256,48) | (194,0,0) | (193,1,0) | 0.0069403631806 / 0.0069760925283 | 0.003303724159 / 0.00597864968 |
| M56 | (256,56) | (226,0,0) | (225,1,0) | 0.0069403631806 / 0.0069760925283 | 0.003303723225 / 0.005978648746 |
| M64 | (256,64) | (258,0,0) | (257,1,0) | 0.0069403631806 / 0.0069760925283 | 0.003303722148 / 0.00597864767 |
| N384 | (384,48) | (194,0,0) | (193,1,0) | 0.0069403631806 / 0.0069760925283 | 0.003303724159 / 0.00597864968 |
| N512 | (512,48) | (194,0,0) | (193,1,0) | 0.0069403631806 / 0.0069760925283 | 0.003303724159 / 0.00597864968 |
| J | (512,64) | (258,0,0) | (257,1,0) | 0.0069403631806 / 0.0069760925283 | 0.003303722148 / 0.00597864767 |

各配置最近零特征值均约为左端 $+0.010244089942$、右端 $-0.012954744811$；
同一端点跨配置变化分别不超过 $2.7\times10^{-13}$、$2.8\times10^{-13}$。
全部点的 `rcond(T)` 最小为 0.517637176836，组装/右求解误差最大分别为
$7.93923\times10^{-19}$、$5.55667\times10^{-19}$。
QZ 两方向均为 $K$ stable、$K$ unstable、0 neutral、0 indeterminate；无求解警告。
候选点 $k_0$ 的 Hsym 均有一个 band-unresolved 特征值，约 $-1.32\times10^{-6}$；
这不改变预先固定的肩点判号规则，也不构成候选点的严格判零。

固定 $k_0=1.7545053299700002$ 的四指标为：

| 配置 | adef_sigma | adef_ratio | aphys_sigma | aphys_ratio |
|---|---:|---:|---:|---:|
| B | 0.00175690973544 | 2.90794553241e-06 | 0.000869578027222 | 0.000303999932758 |
| M56 | 0.00175690973544 | 2.4931030871e-06 | 0.000869578027224 | 0.000303999932758 |
| M64 | 0.00175690973544 | 2.18184587776e-06 | 0.000869578027222 | 0.000303999932758 |
| N384 | 0.00175690973544 | 2.90794553241e-06 | 0.00086957802722 | 0.000303999932757 |
| N512 | 0.00175690973544 | 2.90794553242e-06 | 0.000869578027224 | 0.000303999932758 |
| J | 0.00175690973546 | 2.18184587778e-06 | 0.000869578027225 | 0.000303999932759 |

跨六配置的 `aphys_sigma`、`aphys_ratio` 全范围分别仅为
$5.1424\times10^{-15}$、$1.7981\times10^{-15}$；$d_H$ 也未随两轴加密下降。
这说明本次 $M$ 和 inclusion 边界加密范围内出现平台。`adef_ratio` 随 $M$ 下降约 25%，
来自 $\sigma_{\max}(A_{\mathrm{def}})$ 从约 604.176 增到 805.240，而最小奇异值基本不变；
不能把这一分母变化解释为 dip 加深。其他拟合参数固定，平台来源尚未识别。

六条配置边、三类同 $k$ 对象的 18 次比较均为 simple mode，并通过冻结规则：
最小物理迹 overlap 为 `0.9999999999999998`，最大双向 primary/competitor cross-overlap
为 $4.50\times10^{-14}$；$|m|>48$ 的最大能量占比为 $7.44\times10^{-31}$。
模态 gap 相对 machine-scale cluster band 的比至少为 $8.31\times10^7$（Hsym）和
$8.32\times10^9$（Aphys）。这提供同模态的离散证据，不由不同矩阵的谱值相近推断身份。

基线与 I7.2 的计数、构造、条件数、$d_H$ 和 $\eta$ 复算一致；最近零特征值差
不超过 $9.3\times10^{-13}$。候选点四指标与 I7.1 保存结果差不超过 $1.1\times10^{-18}$。
独立保存矩阵 audit 复核 18 点、18 次比较，最大组装/求解残差为
$7.26\times10^{-18}$，最大 overlap 差为 $2.23\times10^{-16}$，全部通过。

固定点阶段按用户当时选择在 `run-04` 交付，未执行局部位置扫描或 AUX。
随后单独授权的位置检查见下方续轮；`AUX` 仍未执行，平台来源不作归因。
两阶段的数值证据均不确认 raw $H$ 的严格惯性、实根存在/唯一性或连续算子的特征值。

入口为 `[result,evidence] = check_i7_refinement(checkpoint_dir)`；省略参数也能运行，
显式目录仅用于逐点保存，不是模型输入。目录必须预先存在且 checkpoint 不可覆盖。
固定点阶段入口保持不变；本续轮使用下方新增的 `local` 模式。
实际完整命令另见 [[test/i7/refine-v1/output/attempt-1/run-04/command.txt|command.txt]]。
[[test/i7/refine-v1/output/attempt-1/run-04/result.json|结果]]、
[[test/i7/refine-v1/output/attempt-1/run-04/scientific.mat|矩阵及模态]]、
[[test/i7/refine-v1/output/attempt-1/run-04/audit.json|独立数值 audit]]、
[[test/i7/refine-v1/output/attempt-1/run-04/resources.csv|资源时间序列]]、
[[test/i7/refine-v1/output/attempt-1/run-04/refinement-summary.png|两轴数值图]]。
图中下排纵轴自动放大了约 $10^{-15}$ 量级的差异，只能解释为所测平台中的微小变化。
run-04 入口耗时 340.255368 s，完整受监测调用 365.178545 s，exit 0，
进程树和全部 MATLAB 树并集峰值均为 **1,943,863,296 bytes**，低于 2.3 GB 提前线。
run-03 仅因 helper 形参误用保留字 `otherwise` 而解析失败，12.888699 s、886,259,712 bytes；
已改名 `fallback`，未改变数学方法。连同未采 RSS 的 run-01 预检，本轮 MATLAB 已使用
保守累计 380 s。无 MATLAB 科学点因资源超限或数值错误而失败。
本轮自 08:10:04 UTC 首次行动至 09:18:31 UTC 交付检查共 4107 s，包含用户明确暂停的 104 s；
用户在 08:57:59 UTC 恢复并另给 90 分钟后，已用 1232 s。
完整记录见 [[test/i7/refine-v1/output/attempt-1/run-04/task-time.json|task time]]。



### I7.3 续轮：共同局部网格的位置比较

用户随后单独授权的局部检查已完成。`attempt-1/run-06` 对六配置各作 11 点 fresh evaluations，
66/66 点有效且数值诊断通过。模型、辅助 tuple 以及既有 29 个 `LOCAL_` 数值 helper 的执行代码
保持不变；没有重跑旧肩点、执行 `AUX` 或改动其他辅助离散参数。

六配置共用实际区间 `[1.7544553299700001,1.7545553299700003]`，
完整宽度约 $1.00000000000211\times10^{-4}$，名义 $d_k=10^{-5}$。
均按 `aphys_ratio` 选点；`aphys_sigma` 自身的采样最小点也全为第 6 点 $k_0$。
四指标对应同一个最佳点和同一配置：

| 配置 `(ntot,M)` | 最佳 $k$ | 相对 B 的采样漂移 | adef_sigma | adef_ratio | aphys_sigma | aphys_ratio | 对 B 的同模态 overlap |
|---|---:|---:|---:|---:|---:|---:|---:|
| B (256,48) | 1.7545053299700002 | 0 | 0.0017569097354397 | 2.90794553241222e-06 | 0.00086957802722225 | 0.000303999932757942 | 1 |
| M56 (256,56) | 1.7545053299700002 | 0 | 0.00175690973544234 | 2.49310308709946e-06 | 0.000869578027223564 | 0.000303999932758402 | 1 |
| M64 (256,64) | 1.7545053299700002 | 0 | 0.00175690973543933 | 2.181845877763e-06 | 0.000869578027222249 | 0.000303999932757942 | 1 |
| N384 (384,48) | 1.7545053299700002 | 0 | 0.00175690973543591 | 2.90794553240595e-06 | 0.000869578027220243 | 0.00030399993275724 | 0.99999999999999989 |
| N512 (512,48) | 1.7545053299700002 | 0 | 0.00175690973544301 | 2.90794553241771e-06 | 0.000869578027223789 | 0.000303999932758481 | 1 |
| J (512,64) | 1.7545053299700002 | 0 | 0.00175690973545679 | 2.18184587778467e-06 | 0.000869578027225385 | 0.000303999932759038 | 1 |

全部为严格内点，左右相邻点区间统一为
`[1.7544953299700001,1.7545153299700003]`，
完整邻点间距 $2.0000000000131024\times10^{-5}$。以下差值均为邻点 score 减最佳点 score：

| 配置 | 11 点耗时 / s | 左邻点 ratio 差 | 右邻点 ratio 差 | 内点 / sigma 自身最小点 |
|---|---:|---:|---:|---|
| B | 97.047647 | 3.64044484536e-07 | 3.64025397405e-07 | 是 / $k_0$ |
| M56 | 97.053702 | 3.64044484499e-07 | 3.6402539716e-07 | 是 / $k_0$ |
| M64 | 98.443681 | 3.64044485192e-07 | 3.64025396745e-07 | 是 / $k_0$ |
| N384 | 210.485433 | 3.64044485975e-07 | 3.64025398151e-07 | 是 / $k_0$ |
| N512 | 366.440533 | 3.64044483622e-07 | 3.6402539627e-07 | 是 / $k_0$ |
| J | 366.659183 | 3.64044483238e-07 | 3.64025396136e-07 | 是 / $k_0$ |

66 次相同 $k$ 的配置边 physical-wall-trace 比较全部通过；最小 overlap 为
`0.9999999999999996`，最大双向 primary/competitor cross-overlap 为
$4.095494860270543\times10^{-14}$，$|m|>48$ 最大能量占比
$9.012495903032183\times10^{-32}$。没有近简并或强行配对。
独立保存向量中，各配置网格点对该配置 $k_0$ 的 overlap 最小为
`0.9999999999947863`；该跨 $k$ 量仅描述模态连续性，不替代相同 $k$ 的比较门。

**结论：步长 $10^{-5}$ 的共同网格上未分辨出漂移。**
状态为 `LOCAL_GRID_COMPLETED / NO_DRIFT_RESOLVED_AT_SPACING_1E-5`。
因全部最佳点已有有效邻点夹住，按冻结规则停止，没有拟合、插值或进一步加密。
采样漂移为零不是实际极小点误差为零；邻点区间不是认证包围区间。
本轮没有可靠分辨网格以下的位置差异，不宣称位置已经收敛或连续特征值存在。

`run-07` 的 MATLAB 保存数据 audit 复核六个 winner 的权重、SVD、物理迹和 QZ 分类，
及全部 66 个同 $k$ edge，均通过；四指标最大绝对复算差
$7.047314121155779\times10^{-18}$，overlap 最大复算差
$3.3306690738754696\times10^{-16}$。本轮最佳点四指标逐项等于 `run-04` 的 $k_0$ 结果。
独立审查为 `PASS WITH CONDITIONS`；限制是有限网格与固定辅助参数，
不是追加 `AUX` 或理论认证的完成要求。详见
[[research/projects/eig-apost/implementation/i7/review-7-3a|审查记录]]。

| 本续轮记录 | 用途 | 受监测 wall time / s | 进程树及 MATLAB 并集峰值 RSS / bytes | 退出状态 |
|---|---|---:|---:|---|
| run-05 | 5 点后停止，修正 invalid/platform 状态门；保留 checkpoint | 56.714003 | 1,298,055,168 | 143，显式 SIGTERM |
| run-06 | 完整 66 点局部扫描 | 1250.057854 | 1,606,238,208 | 0 |
| run-07 | 保存数据 audit、绘图、checkcode | 13.889967 | 1,238,335,488 | 0 |

`run-06` 入口耗时 1236.527470 s；本续轮 MATLAB 含停止记录和审计共 1320.661824 s。
连同先前固定点阶段与失败预检，I7.3 累计 1699.729068 s（约 28 分 20 秒），小于 2700 s 预算。
三个新运行以 0.1 s 采样，无外部 MATLAB 并发，未触及 2,300,000,000-byte 提前线或
3,000,000,000-byte 上限。先前固定点阶段已监测峰值 1,943,863,296 bytes 仍高于本续轮峰值。
本次局部续轮从 09:31:46 UTC 至 10:08:44 UTC 交付检查约 36 分 58 秒；
从用户 08:57:59 UTC 恢复并另给 90 分钟起计约 70 分 45 秒。
计时记录见 [[test/i7/refine-v1/output/attempt-1/run-07/task-time.json|续轮 task time]]。
`checkcode` 仅有已解释的 suppression/cleanup advisories，没有语法错误。

入口为 `[result,evidence] = check_i7_refinement(checkpoint_dir,'local')`。
完整受监测复现命令见 [[test/i7/refine-v1/README|实验 README]]，使用新运行目录并扣减已耗预算。
保存证据：
[[test/i7/refine-v1/output/attempt-1/run-06/command.txt|实测命令]]、
[[test/i7/refine-v1/output/attempt-1/run-06/result.json|完整结果]]、
[[test/i7/refine-v1/output/attempt-1/run-06/scientific.mat|winner 矩阵和逐点模态]]、
[[test/i7/refine-v1/output/attempt-1/run-06/resources.csv|RSS 时间序列]]、
[[test/i7/refine-v1/output/attempt-1/run-07/audit.json|独立数值复核]]、
[[test/i7/refine-v1/output/attempt-1/run-07/local-scan.png|六配置曲线]]。

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
   [[research/projects/eig-apost/implementation/i7/review-7-2a|I7.2 independent review]]；
5. [[research/projects/eig-apost/implementation/i7/design-7-3a|I7.3 discretization design]]、
   [[test/i7/refine-v1/check_i7_refinement|refinement entry]] 与
   [[research/projects/eig-apost/implementation/i7/review-7-3a|I7.3 independent review]]。

## I7 待办与问题

本表是 I7 唯一的短问题表；审查文件只链接这里，不复制问题清单。

| ID | 类别 | 当前问题 | 最小下一检查 | 状态 |
|---|---|---|---|---|
| I7-Q1 | important caveat | 本轮候选来自有限 projected-gap 窗口和有限层网格；浅 dip 或边界最小不能升级为已确认特征值 | I7.3 已完成共同局部扫描；步长 $10^{-5}$ 下未分辨出漂移，仍不据此声称候选位置收敛 | open |
| I7-Q2 | blocker | 公共原版在首个 final pilot 达到 3,105,751,040 bytes，实测超过 3 GB；现行方案 2 只让 proxy-source term 使用 target-batched 公共核 evaluator | `scheme-2-run-01` 及 `audit-run-02` 已保存零差异、公共 `which` 路径、exit 0、1,071,398,912-byte formal peak 与完整一致性检查 | closed for current I7.1 implementation |
| I7-Q3 | important caveat | I7.2 的 raw $H$ 非 Hermitian；$\eta$ 是诊断带而非离散误差界，端点符号跳跃不推出 raw 实根或连续特征值 | I7.3 两轴及联合配置均保持 jump 和同模态；非零缺陷仍需保留，不能以该稳定性替代连续误差控制 | open; I7.2 and I7.3 numerical checks complete |
| I7-Q4 | important caveat | I7.3 的 $d_H$ 与 Aphys 指标在 $M$/`ntot` 轴呈平台，但其他拟合参数未变化，来源未识别 | 如需归因平台，另行批准明确的拟合参数敏感性检查；本轮 AUX 未执行 | open; fixed axes checked |
