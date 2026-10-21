# I8.4：FMM 定位与固定场谱距离数值评价设计

本文保留第一阶段定位合同与已完成结果（第 1–9 节），并在第二阶段另行授权后追加
固定场谱距离数值评价合同（第 10 节起）。第一阶段的禁止后续计算、停止与资源时钟只约束第一阶段；
其选点、停止和验收规则不作追溯修改。第二阶段不重新定位，也不把两阶段的配置视为同一个场。

## 1. 第一阶段：状态、问题与边界

- Design ID: `I8.4A-FMM-WIDE-LOCATE-V1`
- Status: `EXECUTED; FRESH FMM CONFIRMED; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Numerical object: I8.1 baseline 模型下，以 FMM2D `eps=1e-12` 完成一次独立宽扫和嵌套 11 点细化
- Selection score: `aphys_ratio`
- Primary completion target: 至少一个完整有效细化轮的实际整轮宽度 $W\leq2\times10^{-14}$
- Claim boundary: `FINITE FMM GRID LOCATION; FRESH FMM SINGLE-POINT REPEAT ONLY`

研究问题是：不使用既有 candidate 或局部区间作任何搜索决策时，固定宽区间
$[1.45,2.25]$ 的 33 点 FMM 扫描会选择哪个离散谷底；随后按实际相邻节点嵌套的
11 点网格能否在资源限额内达到目标宽度，并给出可在新进程复算的 FMM 候选。

第 1–9 节任务是 I8 内部的第一阶段定位，不建立 I9，不运行 I8.2 惯性、离散加密或 I8.3 谱距离估计。
它不证明宽扫步长足以发现全部连续极小值，不把最终 $W$ 或邻点宽度当作位置误差界，也不把
FMM 请求容差当作矩阵或谱指标的严格误差界。权威依据为
[[research/projects/eig-apost/implementation/i8/design-8-1b|I8.1 定位合同]]、
[[research/projects/eig-apost/implementation/i8/p-fmm|FMM 对照设计]]、
[[research/projects/eig-apost/implementation/i8/r-fmm|FMM 独立审查]]、
[[test/i8/locate-v1/README|I8.1 机器记录]]和
[[test/i8/fmm-v1/README|FMM 固定点机器记录]]。

既有 candidate `1.7562818500073463`、旧局部区间、旧 winner 顺序和旧平台轮次只可在本轮完全
结束后作人工历史比较。它们不得初始化、居中、扩缩、平移、打破并列、停止本轮搜索，也不得写入
可执行入口作为期望值或 fallback。本轮 candidate 只能来自本轮新评价的节点。

## 2. 冻结模型、评价器与代码边界

保持

$$
\beta=0.5,\qquad
(N,n_{\rm side},n_{\rm top},n_{\rm proxy},m_{\rm pw},M)
=(256,160,160,80,32,48).
$$

左右 lead 仍为半径 $0.2$、`epsrel=17` 的圆；中心仍为 `epsrel=2` 的公共五瓣星形，且六行几何
数组同时乘 $\sqrt{0.04/0.0618}$。公共 `bloch.construct_S` 的 physical-density coordinate
scaling、QZ/DtN、matching、weights、$A_{\rm def}$、$A_{\rm phys}$ 和 SVD 公式保持不变。
每点调用已经对照通过的 `fmm_i8_point(k,'fmm',1e-12,false)`，smooth proxy callback 每胞元一次
FMM；不得改成 `1e-10`，不得缓存或跨胞元、跨点复用 tree、proxy 或场，也不得修改或遮蔽公共包。

宽扫和细化入口只依赖 MATLAB path 上的实验函数、公共 package 与现有官方 FMM2D MATLAB/MEX。
可执行 MATLAB 不读取 Markdown、Git、历史 CSV/MAT/JSON、旧 candidate 或硬编码本机路径。
launcher 可添加所需目录到 path、传入 output directory并保存环境和资源记录，但不能向数值入口
注入历史搜索结果。

## 3. 固定 33 点宽扫

第 0 轮固定为

$$
k_i=1.45+i\,0.025,\qquad i=0,\ldots,32.
$$

生成后以实际 binary64 数组为准，要求 33 个节点全部有限、严格递增且 exact 不重复；实际首末节点、
间距和整轮宽度必须从保存的 `k` 数组重建，不能只抄十进制请求。33 点逐点串行评价，每点只调用
一次 FMM `eps=1e-12` 完整 point evaluator。沿用未修改的 `fmm_i8_point` 既有 warning 处理：该入口
把捕获到的 warning 抛为 `PointWarning`，搜索层保留错误并停止当轮以排查。任一点发生 MEX/FMM、
QZ、线性求解、SVD 异常、非有限值或输出结构错误同样使整轮失败；不得给失败点赋大数、删行或从
剩余 32 点选 winner。

先枚举全部 interior strict local dips，即索引为 2 至 32 且 `aphys_ratio` 严格小于左右实际邻点
的行。宽扫保存这些 dip、stable first 全局最小行和两个端点；若至少有一个 strict dip，winner 是
其中 `aphys_ratio` 最小者，exact 并列按实际数组中的首次索引确定并披露。即使端点的全局值更低，
仍按这个预先冻结的“最优有效内点 dip”规则追踪 interior 分支，同时明确记录端点更低这一事实。

若没有 strict dip，但 exact 全局最小集合包含 interior 行，则按首次 interior 索引选择它，标记
`strict_dip=false` 和 plateau/tie 证据，仍用其左右邻点继续细化。exact 并列不是歧义 blocker，
也不允许用旧 candidate 打破并列。只有全局最小位置全在当前网格端点且没有可用 interior 行时，
才进入第 4 节冻结的域内重叠平移；宽扫已经覆盖整个原宽域，重复窗口检测会把这种情形记为
`RANGE_LIMIT`。该状态表示固定宽域内没有形成可追踪内点，不是否定模型的证据。

## 4. 11 点嵌套细化

设上一完整有效轮 winner 的实际左右相邻节点为 $k_L,k_R$。下一轮固定请求

$$
k_i^{\rm req}=k_L+i\,\Delta k_{\rm req},\qquad
\Delta k_{\rm req}=\frac{k_R-k_L}{10},\qquad i=0,\ldots,10.
$$

不得用旧 candidate、拟合、插值、抛物线顶点或根求解改变这 11 个请求点。生成后再次检查 actual
binary64 节点有限、严格递增、无单轮内 exact 重复，且上一 winner 严格位于实际首末节点之间。
每轮完整评价 11 行后，对该轮全部成功行取 `aphys_ratio` stable first-min 作为 local winner；exact
并列严格按实际数组的首次索引，不再使用宽扫的“优先 interior strict dip”分支。若 local winner
是 interior，就以它的实际左右邻点构造下一轮；`strict_dip` 只记录它是否严格低于两邻点，非严格
或 exact tie 不另外阻止细化。这个规则保留原局部定位的最小值路径，不能为了避免端点而改选更高
的 interior dip。

若按首次索引选出的 local winner 为端点，先进行确定性的域内 recovery，而不是直接停止。保持
当前 requested step 和 11 个节点的完整窗宽，向该端点方向平移 5 个间隔，因而正常情况下与旧窗
保留 6/11 个节点；
新窗必须夹在原宽域 $[1.45,2.25]$ 内。若靠近原宽域边界，则整体夹回域内而不改变 requested step
或节点数。recovery 网格也完整评价，并按全部成功行 stable first-min 选择 local winner；每个实际
窗口保留在 ledger 中。若夹回后得到与已经评价窗口 exact 相同的 11 节点数组，或无法形成 11 个
严格递增节点，停止并记
`RANGE_LIMIT` 或 `BINARY64_GRID_FAILURE`，避免盲目循环。不得插入旧 candidate、跳过节点或换用
另一个 score。

跨轮 exact 重复节点允许再次评价。所有重复行都保留，并报告同一 exact $k$ 四指标的 bitwise
比较与 absolute differences；普通浮点差异不自动成为 blocker，也不能只挑重复值中较小者掩盖
差异。`round_best` 和累计 winner 始终对各自保存范围内的全部成功行执行 `aphys_ratio` stable
first-min；相同位置的重复相等行不构成两个位置。若不同 distinct $k$ exact 并列，仍按首次评价
行确定位置并披露并列位置数。只有固定宽扫的 bracket winner 服从第 3 节 interior-dip 优先级，
因此宽扫端点全局最小值低于它时二者必须分别记录；11 点局部轮的 bracket winner 就是该轮
stable first-min local winner。

`round_best` 是当前轮所有成功评价行的 stable first-min `aphys_ratio`。宽扫另存的 interior-dip
bracket winner 驱动首个细化轮；此后只要局部轮完整，其 stable first-min local winner 在 interior
时驱动下一轮，在端点时驱动域内 recovery。
`cumulative_best` 是从本轮第 0 轮开始至当前时刻、**全部成功实际采样行**的 stable first-min，
包括 recovery 网格和后来未能完成的轮中已成功的点；最终搜索候选取该规则给出的实际位置。
失败或不完整轮不能形成下一细化网格，也不抹去其中已成功点。旧 I8.1 数据完全不进入 cumulative
集合。若最后一轮 `round_best` 未改善，仍保留该轮并由 `cumulative_best` 保存先前更小的新值。

## 5. 实际网格量与完整性账目

对每一轮的实际数组 $k_0<\cdots<k_{n-1}$ 定义

$$
W=k_{n-1}-k_0,\qquad
h_i=k_{i+1}-k_i\quad(i=0,\ldots,n-2).
$$

ledger 保存 `requested_step`、`actual_first_k`、`actual_last_k`、`actual_W`、完整 spacing vector，
并至少汇总 `min_spacing` 与 `max_spacing`。不存在一个由 nominal `dk` 替代所有 $h_i$ 的
“actual step”。对 interior winner $j$ 再定义

$$
h_L=k_j-k_{j-1},\qquad h_R=k_{j+1}-k_j,\qquad
w=k_{j+1}-k_{j-1}=h_L+h_R.
$$

这里 $W$ 是完整轮宽度，$w$ 是 winner 的实际邻点 bracket 宽度，二者都只是采样尺度。
所有停止和下一轮构造使用保存的 actual double；不能从 `10*requested_step` 或理想十进制推断。

点 ledger 至少保存 `round_index,round_kind,node_index,evaluation_index,k,valid,outer_seconds,
point_seconds` 和四指标。round ledger 至少保存 requested/actual 网格量、winner 及左右节点、
`round_best,prior_cumulative_best,cumulative_best,relative_improvement,below_5pct,
below_5pct_streak,platform_candidate,platform_confirmation,strict_dip,stop_reason`。
每轮须能由点表独立重建 winner、$W$、spacing 与 $w$；摘要不能代替完整曲线。

## 6. 宽度完成门与平台记录

主完成门是第 $r\geq1$ 个完整有效细化轮满足

$$
W_r\leq2\times10^{-14}.
$$

达到后停止新增搜索网格。该宽度是目标采样尺度，不是连续极小点误差。按理想 spacing，宽扫
winner 的两个邻点先给出首个细化宽度约 $0.05$；安全的左右邻点嵌套每轮约缩小到前一轮的
$0.2$。因此第 18 个细化网格仍约为 $6.55\times10^{-14}$，第 19 个约为
$1.31\times10^{-14}$；无 endpoint recovery 时预估总点数是 $33+19\times11=242$。19 只是预估，
不是硬停止轮数。

为防实现错误或异常不收缩，设置最多 40 个 **完整细化轮** 的资源保护 guard。若 40 轮后仍未
达到目标，状态为 `RESOURCE_GUARD`；若科学 run 先达到 wall/RSS 限额，则为 `RESOURCE_LIMIT`。
二者都不能写成已观察到平台，也不能通过重开 attempt 重置同一方法的预算。

平台记录只用本轮累计最优值。令 $c_r$ 为第 $r$ 轮 `cumulative_best`，对 $r\geq1$ 定义

$$
I_r=\frac{c_{r-1}-c_r}{c_{r-1}}.
$$

$c_r$ 单调不增，故正常情况下 $I_r\geq0$；无新改善时 $I_r=0$。若 $c_{r-1}=0$，显式记录
`exact_zero` 并令本轮平台计数按零改善处理，不执行除零。`below_5pct` 当且仅当 $I_r<0.05$；
exact 5% 不计。连续三个完整有效细化 transition 满足该条件时，记录 `platform_candidate`；下一个
完整有效细化轮作为 confirmation，若仍低于 5% 则记录 `platform_confirmed`，否则记录 rejected 并
重置 streak。历史旧轮不进入 streak。

candidate 或 confirmed platform 都只是累计 score 改善变小的数值迹象，不自动提前停止；默认仍
继续到 $W$ 完成门。若 $W$ 先达标，不为完成平台标签而额外生成可能重复的更细网格，标签保持
pending/unconfirmed。只有 binary64 节点已无法形成完整严格递增网格、资源限额或另一次独立核查
明确要求提前停止时才在 $W$ 目标前结束，并按真实原因分类。

## 7. 最终新进程确认

完成搜索后，从本轮 `cumulative_best` 的 stable first-min 取 $k_*$，以 `%.17g` 打印成 literal。
全新 MATLAB 进程显式使用该 literal；它不加载搜索 MAT/CSV/JSON，也不读取旧 candidate：

1. 调用一次 `fmm_i8_point(k_*,'fmm',1e-12,false)`，保存 FMM runtime 和四个定位指标；
2. 进程退出后比较 fresh FMM 与搜索保存值的 bitwise 状态、absolute differences 及适当的 relative
   differences；接近零的指标不只用相对误差。

fresh FMM 同点非逐位一致时保留差值并结合 magnitude、运行环境和跨轮重复证据解释；这本身不
机械判为 blocker，也不能挑较小值替换搜索分数。本阶段不新增 direct 调用。历史 direct 结果只在
搜索完全结束后作事后背景比较，不参与候选、停止或一致性判据。

若未达到主宽度门或因网格/资源原因停止，则不伪造完成态。仍可保存当前 stable first-min 及已成功
点作不完整搜索的 diagnostic，但它不是本节的正式 confirmation。exact tie 只需按冻结规则披露，
不额外阻止 fresh FMM 复算。

## 8. 资源、attempt 与交付

FMM 固定点正式中位数约 $1.22$--$1.25$ 秒；242 点纯评价约 5 分钟。加上 MATLAB 启动、完整
曲线保存和同点 FMM 新进程确认，预计科学计算低于 10 分钟。内存规划沿用固定点 run 的
约 $1.1$ GiB 观测，以 2 GiB process-tree RSS 为硬上限。一个完整正确配置的 run 服从 30 分钟
soft wall limit、至多一次即将完成的 10 分钟 grace 与 40 分钟 hard stop；MATLAB 必须串行，
运行前和运行中不得有第二个 MATLAB。

第一阶段总时限从 2026-10-21 01:20:16 UTC 起 120 分钟，至少保留最后 20 分钟给独立审查和文档。
操作性错误在同一个 `attempt-1` 内保留日志、修复和重跑；正确方法达到资源 guard 或科学限额时
不得另开 attempt 规避。历史 direct locate 的十四个 11 点网格共154点评价、entry runtime 合计
1361.4096024166668秒，只可在结果讨论中作不同 evaluator 的历史背景；旧 flow 的88点与混合后续
总时长口径不同，均不得当作本轮对等 speedup 分母。本轮性能只报告自身逐点、各轮和总 wall。

交付至少包括：

- 可重复 MATLAB 入口和 launcher；33 点宽扫及每轮 11 点完整 point/round ledgers；
- 每点四指标与时间，actual $W$、完整 spacings、$w$、winner、round/cumulative best；
- 低于5% streak、platform candidate/confirmation 状态和真实 stop reason；
- fresh-process FMM 单点输出及与搜索保存值的差异；
- MATLAB/FMM2D 路径与版本、线程、其他 MATLAB、process-tree peak RSS、wall 和系统负载记录；
- 失败日志，不遗漏、不选最快结果、不把 $W$、FMM 容差或平台迹象写成认证。

完成门是：宽扫和所有用于决策的细化轮完整有效，至少一轮 actual $W\leq2\times10^{-14}$，
候选仅由本轮 `aphys_ratio` 决定，fresh-process 输出齐全，资源不越界，独立 Skeptic 能从原始文件
重建选择与停止。未证明连续极小点、未运行 direct 邻域复核、未认证谱距离是 important caveat，
不构成本阶段 blocker。第一阶段完成后停止；第二阶段 $R_{\rm num}$ 评价需要另行授权，其现行合同见第 10 节。

## 9. 实际结果：attempt-1

正式搜索 `run-01` 于 2026-10-21 完成，原始证据为
[[test/i8/fmm-search-v1/output/attempt-1/run-01/result.json|result.json]]、
[[test/i8/fmm-search-v1/output/attempt-1/run-01/evaluations.csv|evaluations.csv]] 和
[[test/i8/fmm-search-v1/output/attempt-1/run-01/rounds.csv|rounds.csv]]。固定宽扫只发现一个 strict
interior dip，位于 $k=1.75$；后续没有触发 endpoint recovery。20 个完整网格共作 242 次 FMM
point 调用，对应 188 个 distinct binary64 $k$。第 19 个细化网格首次满足

$$
W=1.3322676295501878\times10^{-14}\leq2\times10^{-14}.
$$

该轮 10 个 actual spacing 全为 $1.3322676295501878\times10^{-15}$，winner 的实际邻点宽度为
$w=2.6645352591003757\times10^{-15}$。因此 **ESTABLISHED**：主宽度门已按 actual grid 满足，
`ACTUAL_WIDTH_TARGET_MET` 与点表可独立重建。

累计 stable first-min 首次出现于第 18 轮 evaluation 229：

$$
k_*=1.7562818500073423,
$$

四指标为

$$
\begin{aligned}
\sigma_{\min}(A_{\rm def})&=8.2879554543588172\times10^{-14},\\
\frac{\sigma_{\min}}{\sigma_{\max}}(A_{\rm def})&=1.3717792880175595\times10^{-16},\\
\sigma_{\min}(A_{\rm phys})&=4.0360727231757905\times10^{-14},\\
\frac{\sigma_{\min}}{\sigma_{\max}}(A_{\rm phys})&=1.4133082230178709\times10^{-14}.
\end{aligned}
$$

第 19 轮 evaluation 237 在同一 exact $k$ 逐位复现这四项；累计 stable-first 规则因此保留第 18 轮
的首次来源，而不是产生第二个位置或更换 candidate。全部跨轮重复比较均为 bitwise equal，最大
absolute difference 为零。

平台账目没有达到 3+1 条件。`below_5pct` 只在第 5、9、15、19 轮出现，每次前后的非低改善轮都
把 streak 重置，最大 streak 为 1；第 19 轮改善为零，但第 18 轮累计改善仍为约 $48.82\%$。
因此 `platform_status=not_confirmed` 是 **ESTABLISHED**，不能改写为已观察到平台。按第 6 节冻结
口径，平台只是诊断而非完成门；用户允许达到 $W$ 目标后正常完成，因此这一状态既不是 blocker，
也不单独构成 important caveat。

fresh-process `run-02` 的
[[test/i8/fmm-search-v1/output/attempt-1/run-02/confirmation.json|confirmation.json]] 在显式 literal
$k_*$ 上逐位复现全部四指标。fresh 完整 point wall 为 $1.545477$ 秒，进程 wall 为
$13.618543$ 秒。搜索进程 wall 为 $340.982072$ 秒；243 次完整 point 的外层计时合计
$312.4694249166667$ 秒，两个进程合计科学 wall 为 $354.600615$ 秒。最大 process-tree RSS 为
$1103577088$ bytes，低于 2 GiB；两次 preflight 均无其他 MATLAB，进程退出后无残留。

结论是 **GO FOR SEPARATELY AUTHORIZED $R_{\rm num}$ EXECUTION**：该 literal 已满足本阶段预注册
的独立宽扫、actual-$W$ 和 fresh-repeat 工程门，可以作为另行授权第二阶段的输入。本轮到此停止，
不自动执行后续计算。真正的 important caveat 是该判断仍只针对 FMM 与浮点有限采样，不认证连续
极小位置、不排除漏过其他候选，也不认证连续算子谱距离。后续第二阶段不得继承旧 frozen field 或
旧 $R_{\rm num}$ 结果；其具体执行合同由后续授权决定。

独立 Skeptic 已从原始 CSV/JSON 重建 242 次评价、188 个 distinct $k$、第 19 轮 $W$/$w$/spacing、
四个孤立的 `below_5pct` 轮和 fresh exact match，结论为 `PASS WITH CONDITIONS`。其 GO 范围与上段
相同：只接受这是 finite FMM grid candidate，并把连续位置、漏候选和谱距离留给后续独立阶段。
以上阶段 1 历史结果与审查保持冻结。


## 10. 第二阶段：新候选的同场数值评价合同

### 10.1 状态、权威与依赖

- Design ID: `I8.4B-FMM-FROZEN-FIELD-V1`
- Status: `COMPLETE; PASS WITH CONDITIONS; UNCERTIFIED_RNUM`
- Material Passport: 本节为已授权实验的实施合同；参数、旧资源与既有算法为本地已核证据，
  新结果在运行前为空；无新理论定理、无外部文献或新数据来源。
- Numerical object: 新 literal $k_0=1.7562818500073423$ 上 fresh center-512/lead-256 场的
  ordinary-double 完整材料/人工墙跳跃、同场局部质量与 $R_{\rm num}$。
- Claim boundary: `UNCERTIFIED_RNUM; FIXED-FIELD EVALUATOR COMPARISON ONLY`。

权威链为第一阶段实际 candidate 与
[[research/projects/eig-apost/implementation/i8/review-8-4a|第一阶段独审]]，加上
[[research/projects/eig-apost/implementation/i8/design-8-3a|I8.3 同场合同]]、
[[research/projects/eig-apost/implementation/i8/review-8-3a|center-512/lead-256 独审]]，及
[[test/i8/estimate-v1/README|estimate-v1]] 的正式 `output/attempt-1/run-05/`。
理论来源继续是 I6 到 I7 再到 I8 的 shifted-resolvent/raw-field 完整跳跃路线，具体继承
[[research/projects/eig-apost/implementation/i7/design-7-4a|I7.4]] 与 I8.3 第 2–5、9 节；
不恢复旧 lift/Fourier-tail 路线。历史 run-05 只提供配置、运算定义与资源基线，不能输入其密度、
归一化、跳跃或最终标量。FMM 映射沿用
[[research/projects/eig-apost/implementation/i8/p-fmm|p-fmm]] 与
[[research/projects/eig-apost/implementation/i8/r-fmm|r-fmm]] 中的官方实现约定。

依赖顺序固定为：literal 与模型 → fresh FMM scattering/QZ/DtN/matching → 一次归一化的
$q$、密度与传播 → 512/768 完整跳跃及质量 → 768 主标量 → 保持该场的 768 direct-proxy
重评价 → 保存原始证据与独立审查。未认证、未建立收敛或新值不优于旧值均不是本阶段 blocker。

### 10.2 冻结参数与新场身份

使用显式 literal，禁止重搜索、修改 $k_0$、容差扫描、空间加密或追踪多个 dip：

$$
k_0=1.7562818500073423,\qquad
(n_c,n_\ell,M,n_{\rm side},n_{\rm top},n_{\rm proxy},m_{\rm pw})
=(512,256,48,160,160,80,32).
$$

模型是 $\beta=0.5$、$d=L=1$、$X_L=-0.5$、$X_R=0.5$、外部材料系数 1；
lead 为半径 $R=0.2$、材料系数 17 的圆，中心为材料系数 2 的五瓣星，六行几何统一乘
$\sqrt{0.04/0.0618}$。MFS 保持 `H=1.1`、`proxy_dist=0.2`。几何评价保持
4096/8192 节点、`collar_h=0.004`、`arc_band=0.01`；禁止复制旧 `Cnum` 数值代替本轮重算。
FMM 固定 `eps=1e-12`，只使用已安装官方 FMM2D commit
`550dae5b77b1e006c8ffae37fc832f8c2b536871`，不安装依赖。

每次正确配置科学运行只构造一次新场。由新 $A_{\rm phys}$ 最小右奇异向量经 column-weight
recovery 得到 $q=[a^L;b^R]$，按 run-05 的单位范数与 phase anchor 归一化一次。
随后固定 $q$、$\eta_c=H_La^L+H_Rb^R$、lead 的 physical density maps、
$G_\pm,P_\pm,c_\pm$、Rayleigh coefficients 与全部归一化。$\zeta=-\sigma$、physical-density
scaling、QZ/DtN、matching、weights 和质量定义均保持原路线。

节点账本应确认 center `H_L/H_R` 为 $1024\times97$、`A_QP` 为 $1024\times1024$；
lead 对应为 $512\times97$、$512\times512$；matching 为 $194\times194$。
此处新场与第一阶段定位用的 `(256,256)` 场不同；阶段 1 的四指标也不能直接代替本阶段四指标。

### 10.3 允许的 FMM 替换及分块

唯一替换点是 `pars.h2d_evaluator` 对 smooth proxy charges 的 Helmholtz 势、梯度和 Hessian。
`kernel.qpgreen_mfs_pairmat` 的自由空间原点项仍调用公共 direct kernel；公共 Kress、自作用、
跳跃、近奇异处理和外侧 Rayleigh 分支保持原样。不能把全部 BIE 或全部场称为 FMM。

| 阶段 | smooth proxy | 其他运算 | 分块合同 |
|---|---|---|---|
| 新 lead/center 场构造 | FMM `1e-12` | 公共 singular/Kress、QZ/DtN/matching direct/dense | 每个公共 callback 一次 FMM，无跨胞元缓存 |
| 512/768 材料跳跃 | FMM `1e-12` | 同一插值密度、scaled raw action、jump identity 原样 | 材料 pair grid 每个 callback 一次 FMM |
| 512/768 物理墙 | FMM `1e-12` | 原自由空间核、物理法向与 Rayleigh incident | wall target 外层每批 64 |
| 两层 safe-disk 质量 | FMM `1e-12` | 原直接自由空间核与 incident 场 | disk target 外层每批 32 |
| 固定场 768 对照 | direct proxy | 与主层同一 field、grid、权重和分项定义 | callback 内 target 每批 512；wall/disk 外层批量同上 |

FMM wrapper 继续调用
`hfmm2d(1e-12,wavek,srcinfo,0,targ,3)`，其中 `srcinfo` 仅含 `sources` 和 `charges`；
输出依次 reshape 为 `1 x nt`、`2 x nt`、`3 x nt`，Hessian 顺序 `(xx,xy,yy)`。
它沿用 $\mathrm{i}H_0^{(1)}/4$ 与 target-minus-source 约定，不另乘常数，不重复 y-periodic
坐标交换，不引入 dipole 输入。每次记录 role、source/target counts、批量、`ier`、时间与 finite
状态。`ier` 非零、shape 错误或非有限量须显式失败，不能填零继续。
若内存分析需要更小固定 FMM 批量，只能在运行前记录新批量及原因；不得借此改变物理网格。

### 10.4 完整分项与最终标量

继续使用同一个 frozen density 的 `interpft` 插值。材料和墙均评价 $N=512,768$ 两层；768 是
主层，512 的中心材料 action 是 native/collocated 诊断，不能用来声称独立网格验证或收敛。
两层 disk 分别为 $16\times32$（无角位移）与 $32\times64$（半角步位移），区域保持
$B((3/8,0),1/16)$。

每层完整保留 center material、左右各 40 个 lead material cells、两条 center--lead walls、
左右各 40 条内部墙、材料和墙从第 41 项开始的 observed geometric-tail candidates。
材料 raw action、普通 normal 的第二 block 负号与墙两侧法向保持 I8.3 合同。传播/trace residual
只作坐标审计，不重复加入 jump energy；physical-wall evaluation 已包括 retained channels
以外的 frozen-field 内容，不另加旧 Fourier-tail 项。

尾项仍使用下一项与观察比率形成 $e_{40}/(1-r)$，条件为有限且 $0\le r<1$；任一缺失
或不合格时保留 finite prefix 并 fail closed，不能用零填补。对于每个完整 evaluator 结果：

$$
\varepsilon_{\rm num}=\sqrt{E_n+E_v/d^2},\qquad
Q_{\rm num}=C_{\rm num}\varepsilon_{\rm num},\qquad
D_{\rm num}=U_{\rm num}-Q_{\rm num},
$$

$$
R_{\rm num}=\frac{2\mu_{\rm num}Q_{\rm num}}{D_{\rm num}},\qquad D_{\rm num}>0.
$$

数学参数 $\mu=\widehat k_0^2$ 是输入 double 的 exact-real square；代码仍保存
`mu_num=k0*k0`，不可把 rounded product 称为 exact square。$C_{\rm num}$ 保持 I8.3
第 5 节的 sampled-collar T9 公式并从本轮参数重算，$U_{\rm num}$ 是同场 fine-disk quadrature
norm。全部分项、几何和内部审计齐全、分母有限为正且 $R_{\rm num}$ 有限时，状态才为
`UNCERTIFIED_RNUM`，并保存 `certified=false`；其他情况报告实际失败状态。

### 10.5 固定场 direct-proxy 对照

主层保存后固定全部场构造数组；只把 `center.i8_pars.h2d_evaluator` 与
`lead.i8_pars.h2d_evaluator` 换成直接 proxy callback。复用同一 proxy coefficients、原密度、
$q$、传播、Rayleigh 系数、归一化与几何。不能再调用 fresh field construction、QZ、SVD 或
重新解密度来产生“对照场”。独立审计可以从保存矩阵重组代数对象，但不改变对照输入。

在同一 768 material/wall grid 上重新评价全部上述跳跃分项、40-cell 前缀和尾项；在同一
$32\times64$ shifted disk 上重新评价质量样本。由 direct 分项分别重算
$\varepsilon_{\rm num},U_{\rm num},Q_{\rm num},D_{\rm num},R_{\rm num}$，不能沿用 FMM
的 $U_{\rm num}$ 或只对照单个材料界面。主层仍是预定 FMM 结果，不择小者替换。

对每个 scalar component、tail ratio、总量及最终标量保存两值、绝对差
$|x_{\rm fmm}-x_{\rm direct}|$ 和相对差
$|x_{\rm fmm}-x_{\rm direct}|/\max(|x_{\rm fmm}|,|x_{\rm direct}|)$；双方为零时记零。
原始 signed material/wall jumps、质量 samples、相关 maps/matrices 同时保留，微小分项必须连同
绝对尺度解释。若原始场输出只作抽样核验，则需明确抽样范围，不能代替完整跳跃对照。

该实验只检验同一 FMM 构造场上 smooth-proxy 后处理的敏感性。即使两者非常接近，也不能排除
共同场构造的 FMM 误差、直接核误差、几何/求积/tail 误差或离散误差；direct 不被授予 exact
reference 地位。相对差明显或 FMM 数值比旧结果大应如实保留，不能据此扫描容差或换候选。

### 10.6 资源、实现边界与完成门

运行前本地证据是 run-05 entry $394.471511292$ 秒、完整进程 wall $415.277293$ 秒、峰值 RSS
$1{,}214{,}922{,}752$ bytes。以两倍旧完整 run 约 831 秒覆盖本轮主计算与 direct 主层对照，再为
审计、写出和波动预留余量，启动前估计完整科学计算约 18–22 分钟；这不是测得的新耗时或加速比。
不把固定点 FMM 的历史约六倍加速外推为本轮收益。

768 材料 pair grid 至多约 589824 个 callback targets；六个 complex-double 输出约 54 MiB，
还需计入 FMM workspace 与公共 dense assembly。基于 run-05 峰值，计划内存应控制在约
1.6–1.8 GiB；这是待监测估算。不得把两套全部 evidence 深复制后仍假定旧峰值适用，宜顺序评价、
及时保存并释放不再需要的临时矩阵，且完整保留可独立审查的原始数组。若实际实现的预估已超过
2 GiB 或 30 分钟，不启动科学计算，先报告资源 blocker。

本阶段完整科学计算（主计算、固定场 direct 对照及必要数值审计）共享 30 分钟 soft budget；
仅在客观进度证据表明即将完成时允许一次至多 10 分钟 grace，40 分钟及 2 GiB RSS 是 hard stop。
不得拆子进程重置预算。不得并发 MATLAB；运行前检查其他 MATLAB，运行中保留 process-tree RSS
与时间。总任务时钟为 2026-10-21 02:01:22 UTC 起 120 分钟，预留独审和文档时间。操作性失败在
同一 attempt 内修复并以新 run 日志保留，不能靠新 attempt 规避正确方法的资源失败。

实现只在 `test/i8/fmm-est-v1/`，入口为 `fmm_est_i8(k0,output_dir)`，沿用 `estimate_i8.m` 的必要 local helpers；不修改公共 package、
`estimate-v1`、`fmm-v1` 或 `fmm-search-v1`。MATLAB 运行只依赖实际所需源码和 path resolution，
不读取 Markdown、Git、历史结果或机器 provenance 来决定参数或授权。新输出至少保存 fresh 场身份、
node ledger、两层完整分项、direct 对照原始证据、absolute/relative differences、$\mu_{\rm num},C_{\rm num},Q_{\rm num},D_{\rm num},R_{\rm num}$、FMM role/batch/ier、
阶段 wall time、资源峰值、失败日志和源代码快照。

完成门是新 literal/new field 与 512/256 配置确实生效；768 完整主值及同场 direct 对照均可重建；
无缺失分项和不合法分母冒充成功；资源合规；独立 Skeptic 完成限定于数值交付的审查。
不能以“未认证”“没有收敛证明”“不比旧值小”阻止可解释的有限数值交付。
潜在 blocker 只包括新旧场混用、配置/符号/normalization 错误、漏项、未完成必要对照、失败值
冒充成功、资源越界或不可运行。其余限制交由
[[research/projects/eig-apost/implementation/i8/README#历史基线与遗留问题|I8 统一问题表]]；
本节不建立第二套问题清单。


### 10.7 协作角色与可核模型证据

本轮新建 `researcher_i84b`、`engineer_i84b`、`skeptic_i84b`；主代理报告三次 spawn 均显式传入
`model=gpt-6-astra`、`reasoning_effort=high`、`fork_turns=none` 且工具接受。工具返回任务名，
没有提供运行时模型遥测，因此只能确认分派参数，不能独立证明实际后端模型。用户指定主代理也用
同模型/high，但可用工具没有主模型自查接口。未向旧 agent 分配本轮工作，也未修改模型配置文件。
Researcher 负责本设计与 `SYMBOLS.md`，Engineer 负责隔离实验实现/运行证据，Skeptic 负责
`review-8-4b.md` 独立审查；主代理负责 README 和总任务资源协调。


### 10.8 保留的操作修复

`test/i8/fmm-est-v1/output/attempt-1/run-01/` 因 sandbox 不允许 `ps` 而在 preflight 退出，
没有启动 MATLAB。run-02 于 2026-10-21 02:06:56 UTC 启动，63.302005 秒后因 singleton target
形状错误退出，峰值 process-tree RSS 为 $1{,}434{,}419{,}200$ bytes，无完整科学输出。

问题位于 safe-disk 的独立 center-point cone diagnostic：公共 pair-matrix 在只有一个物理 target
时把 logical-indexed 行向量转置后纵向连接，产生 `2N x 1` 的 callback target；官方 `hfmm2d`
严格要求首维为 2，因而拒绝。旧 direct kernel 不检查首维，但本轮不能把其静默处理当作正确
singleton 结果。这个中心点值不进入 `U_num` 的 disk quadrature。

最小修复只在新实验的 `LOCAL_center_field`：需要一个物理 target 时复制同一 target 成两列，
由原公共 pair routine 正常评价后裁回第一列。FMM 和 direct 两路共用此修复，不改公共包、核、
几何或数学定义。主质量的 512/2048 个 disk samples 均按 32 targets 成批，未触发 singleton 分支；
边界、墙和主 $U_{\rm num}$ 路径保持原分块。其效果由后续实际运行及独立审查核验。

失败记录留在同一 attempt；本轮主动将 run-02 的 63.302005 秒计入后续共享科学预算，尽管它是
操作性失败，避免利用重跑隐藏成本。后续不得以 run-02 无科学输出冒充已完成主值或对照。

run-03 完成后的 scalar CSV direct 行发现多余格式占位符；Engineer 只修新实验的导出格式，并从
已保存 `result.json` 按 17 位重导 `scalars.csv` 与完整分项 `parts.csv`。原错版 CSV、运行时源码
快照与 raw 数值证据保留；没有为此重跑数值，也没有修改 `scientific.mat` 或其结果。


### 10.9 实际数值结果与研究解释

正式 `attempt-1/run-03` 已完成；原始标量、分项、callback 与 timing 记录见
[[test/i8/fmm-est-v1/output/attempt-1/run-03/result.json|result.json]]，完整数组见同目录
`scientific.mat`。本节只摘录核心结果，完整对照表由
[[test/i8/fmm-est-v1/README|实验 README]] 维护。

**ESTABLISHED（普通数值账目）**：新 literal 与 center-512/lead-256 配置生效，匹配维数为 194，
保存的 fixed-field flags 全真。主 768 FMM 结果为

$$
\begin{aligned}
\mu_{\rm num}&=3.0845259366652127,\\
C_{\rm num}&=8.273545666859036,\\
\varepsilon_{\rm num}&=1.6064304963971742\times10^{-12},\\
U_{\rm num}&=0.11608305827964503,\\
Q_{\rm num}&=1.329087607257705\times10^{-11},\\
D_{\rm num}&=0.11608305826635415>0,\\
R_{\rm num}&=7.063227413047818\times10^{-10}.
\end{aligned}
$$

同一新场的 direct-proxy 768 对照得到
$\varepsilon_{\rm num}=1.60579937868836\times10^{-12}$、
$R_{\rm num}=7.06045248570906\times10^{-10}$；$U_{\rm num}$ 与主层逐位相同。
$R_{\rm num}$ 绝对差为 $2.774927338757746\times10^{-13}$，以较大值归一的相对差为
$0.00039286960145607874$（约 $0.03929\%$）。**CONDITIONAL**：该差异只支持本场、本网格下
smooth-proxy 后处理的总量敏感性较小，不能排除共同场构造的 FMM 误差。个别微小分项仍有较大
相对差，例如 lead finite normal square 约 $25.1\%$、绝对差仅
$6.640395255500175\times10^{-29}$；不能声称全部分项都逐位一致或相对稳定。

512 native-center 诊断给出 $R_{\rm num}=4.0355781662571026\times10^{-10}$，与主层的相对差为
$0.42864954924115484$。因此本次仍没有独立的评价网格收敛证据。新主值相对旧 run-05 的
$7.052160861927364\times10^{-10}$ 大约 $0.1569\%$；这只是历史对照，同时涉及新候选与新构造场，
不能归因于单个 evaluator，也不能称为定位或谱距离改善。以上均不阻止本轮完整数值交付。

主计算的 168 次 FMM callbacks 全部返回 `ier=0`：field 2 次、material/wall 84 次、mass 82 次。
固定场 direct-proxy callbacks 共 115 次（jumps 50、mass 65）；这些不是新的场构造。
主计算与对照保留 `UNCERTIFIED_RNUM`、`certified=false`。Researcher 用独立 Python 标量重组
512/768 FMM 和 768 direct 的 $\varepsilon_{\rm num},Q_{\rm num},D_{\rm num},R_{\rm num}$，与保存值
差为零；此检查仅核 scalar ledger，不替代 Skeptic 对完整原始数组的独立审查。

正式 entry 总时长 $335.5712032083333$ 秒、监控 wall $353.322944$ 秒；加上保留的 run-02，
共享科学预算累计 $416.624949$ 秒。正式峰值 RSS 为 $1{,}442{,}856{,}960$ bytes，无其他 MATLAB
与退出后残留，未用 grace。FMM jump/mass 两层耗时分别为 $40.814153/16.228404$ 秒，direct
仅 768 jump/mass 为 $190.379638/78.579055$ 秒；工作量不同，不能相除作为完整同工作量 speedup。
资源实际值低于启动前估算与硬门。后续独立审查已完成，结论为 **PASS WITH CONDITIONS**，
详见 [[research/projects/eig-apost/implementation/i8/review-8-4b|review-8-4b]] 及原始矩阵重组记录。
普通双精度数值交付成立，认证状态不变；第二阶段至此完成并停止。
