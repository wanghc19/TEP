# I8.4：direct 与 FMM 独立全流程对照

## Material Passport

- Origin Skill / Mode: `academic-research-suite / experiment-agent / plan`
- Origin Date: `2026-10-21`
- Design ID: `I8.4B-INDEPENDENT-PIPELINES-V1`
- Status: `EXECUTION COMPLETE; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Verification Status: `BOTH PIPELINES COMPLETE; INDEPENDENT SEARCH/RESOURCE AND RAW AUDITS PASSED`
- Review: [[research/projects/eig-apost/implementation/i8/review-8-4c|review-8-4c]]
- Claim boundary: `INDEPENDENT FINITE-GRID PIPELINES; UNCERTIFIED_RNUM ONLY`

本合同由本轮用户授权建立，覆盖两个后端各自从宽扫到完整 768 评价的流程。它不改写
[[research/projects/eig-apost/implementation/i8/design-8-4a|旧 I8.4 两阶段合同]]、旧审查或旧结果。
旧 stage 2 的“一个 FMM 场、两个评价器”不等于本轮“两个独立搜索、两个独立场”。
本轮只写入 `test/i8/pipeline-v1/`，不建立 I9、不改公共 package、不安装 FMM。

研究问题是：在共同的模型、离散化、搜索规则与评价公式下，direct 和 FMM 各自新搜索的候选、
完整普通数值结果及实际总成本有何差异？成功标准是两条独立链均通过完整搜索与评价门，
保存可重建的点、轮、raw 分项和互斥时间账本；不要求候选或结果相等，也不预设加速比。

依赖图为：共享 MATLAB 配置 → 每后端独立宽扫/细化 → 各自累计候选 → 各自额外一次 fresh
构场 → 同一场内材料/墙/质量/trace/观察尾项 → sampled geometry 与标量组装 → 输出和独立审查。
依据是 [[research/projects/eig-apost/implementation/i8/design-8-3a|I8.3 raw-field 公式]]、
`fmm-search-v1/search_fmm_i8.m` 的搜索逻辑和 `fmm-est-v1/fmm_est_i8.m` 的局部评价公式；
这些源文件只读，不成为新 MATLAB 入口的运行依赖。

## 1. 唯一共享配置

以下数值必须集中定义在新目录的一份 MATLAB 配置源码中；两个后端读取同一配置。
字段名称可按实现确定，参数值和语义不得分叉。Markdown、manifest、Git 和历史输出不控制运行。

| 对象 | 冻结值与语义 |
|---|---|
| 基本模型 | $\beta=0.5$，$d=L=1$，$X_L=-0.5$，$X_R=0.5$，外部材料系数 $1$ |
| lead | 半径 $0.2$ 圆，材料系数 $17$ |
| center | 公共五瓣 star，材料系数 $2$，全部六行几何乘 $\sqrt{0.04/0.0618}$ |
| 构场阶数 | center $512$，lead $256$；从宽扫第一个点开始采用，禁止先以 256/256 定位 |
| Rayleigh/MFS | $M=48$，$K=97$；`nside=160, ntop=160, nproxy=80, mpw=32` |
| proxy | `H=1.1, proxy_dist=0.2` |
| 唯一后评价层 | material source/target $768$，wall source/target $768$；不计算 512 层 |
| 质量 | $B((3/8,0),1/16)$ 上 $32\times64$ 等面积径向中点、半角位移 $0.5$ 网格 |
| lead 有限段 | 左右各 $40$ 个 cell；材料与 internal wall 各自保存 observed geometric-tail candidate |
| sampled geometry | $4096,8192$ 点；collar $h=0.004$，arc band $0.01$ |
| 几何门 | area defect $\le10^{-12}$；六行缩放 defect $\le100\,\mathrm{eps}\max(1,\lVert C\rVert_F)$；其余沿用原 sampled positivity/clearance 门 |
| QZ 门 | 阈值 $\max(100\,\mathrm{eps},10\,\mathrm{res})$；stable/unstable/neutral/indeterminate 必须为 $97/97/0/0$ |
| raw 代数审计 | 阈值 $10^{-10}$；只表示数值恒等式检查 |
| 分块 | 墙/公共 pair targets $64$，质量 targets $32$，direct callback targets $512$；FMM 每 callback 一次 |
| singleton 处理 | 原公共 pair 例程前重复单目标为两列，返回时裁第一行；两后端一致 |
| FMM | 仅现有官方 FMM2D，提交 `550dae5b77b1e006c8ffae37fc832f8c2b536871`，请求 `eps=1e-12`，全部 `ier=0` |

`eps` 表中 QZ/几何处表示 MATLAB machine epsilon，`eps=1e-12` 只表示 FMM 请求精度，不能混用。
public physical-density scaling、QZ/DtN、matching、weights、SVD、材料法向符号与完整墙公式均不变。
direct 使用原 direct Helmholtz callback；FMM 只替换 smooth-proxy callback，不替换 singular/near
quadrature。不得跨点或跨后端缓存 tree、proxy、矩阵、density、传播坐标或场。

## 2. 两后端相同的搜索状态机

第零轮实际数组由 `1.45+(0:32)*0.025` 生成，共 33 点，原域端点由该数组取得。
每点均完整新评价；保存实际 binary64 `k` 和四个 singular-value 指标，选点仅用 `aphys_ratio`。
每轮必须全点成功、有限、实际节点严格递增且 exact 不重复；失败点不得删去、补大数或跳过。

宽扫先枚举 strict interior dips，取其中 ratio 最小者；exact 并列按原数组首次索引。
若没有 strict interior dip，则报告 `NO_STRICT_INTERIOR_DIP`（固定域内未完成），不得继承旧搜索的
plateau/global-min 内点 fallback。本轮用户要求严格内点 dip 优先于旧实现的较宽松选择规则。
保存全部 dip、两端点和 stable-first 全局最小；若端点低于选中的 dip，必须披露。

其后每轮恰为 11 个实际均匀请求节点：上一轮 winner 实际左右邻点为端点，请求步长为二者之差除以
10，最后节点显式保留右端点。以实际 binary64 网格为准记录 spacing 向量及
$W=k_{11}-k_1$。局部轮 winner 为全轮 stable-first 最小值；不对 exact ties 加容差。

若局部 winner 在端点，按方向平移五个当前 requested steps，保持 11 点与请求跨度，clip 到原宽域；
不重新围绕历史候选。下一网格 exact 重复、无法生成严格不同的 binary64 节点或不能域内恢复时，
保存失败原因并停止。最多 40 个后续轮只是资源保护，触发即未完成，不能当成宽度成功。

搜索完成必须同时满足：完整有效的 11 点轮、winner 严格处于数组内点、实际整轮
$W\le2\times10^{-14}$。这一明确内点门修补旧搜索代码仅判断宽度的不足，不追溯修改旧结果。
平台/小 singular value/新旧值接近均不是提前完成理由。可记录平台诊断，但不能控制停止。

**正式候选规则**：沿用旧搜索的 stable-first cumulative minimum，即本后端从第零轮起全部成功实际
采样行（含端点与 recovery）中 ratio 最小的首次执行行。它与最后一轮 bracket winner 分别保存；
若不同或候选不在最终 bracket，明确报告，不能将最终 $W$ 解释为候选的位置误差界。
失败轮中已成功的行可留作累计诊断，但未完成搜索不得进入成功的最终估计链。
不得加载旧 candidate、旧区间、旧点序或另一后端输出来初始化、选点、破并列、恢复或停止。

## 3. 独立 fresh 构场与唯一 768 评价

每后端搜索完成后，在自己的正式候选额外调用一次同后端完整 point/field 构造。
此调用计为 `final_field`，两边各一次，不能从搜索缓存取场；保存 fresh 四指标与搜索候选指标差。
phase anchor、unit norm、physical densities、Rayleigh 和 $G_\pm,P_\pm,c_\pm$ 在每个场内部一致；
两后端独立归一化，任何分项不能混用。fresh 构场后不再解 density。

唯一 768 层保存：一个中心材料界面的 768 点账目；左右各 40-cell material；两条 center--lead wall；
左右各 40 internal walls；材料与墙的 next term、观察比率和 tail candidates；同场 disk 质量样本及
梯度；trace/recurrence/physical-density/scale/raw-action identity 审计。尾比率只有有限且
$0\le r<1$ 才可形成 candidate；缺失不得补零。传播 residual 不另加一次 jump energy。

令保存的完整 value/normal jump 平方和为 $E_v,E_n$，则普通 double 组装为

$$
\mu_{\rm num}=\operatorname{fl}(k_*k_*),\qquad
\varepsilon_{\rm num}=\sqrt{E_n+E_v/d^2},\qquad
U_{\rm num}=\sqrt{\text{disk quadrature mass}},
$$

$$
Q_{\rm num}=C_{\rm num}\varepsilon_{\rm num},\qquad
D_{\rm num}=U_{\rm num}-Q_{\rm num},\qquad
R_{\rm num}=\frac{2\mu_{\rm num}Q_{\rm num}}{D_{\rm num}}.
$$

$C_{\rm num}$ 按 I8.3 第 5 节 sampled-collar 公式重新计算，只有 sampled 几何门通过才用 overlap
count 1。要求 finite、完整 tail ledger、审计通过、$D_{\rm num}>0$，方输出 `UNCERTIFIED_RNUM`。
失败则保存真实失败状态和有限前缀，不得仍称完整成功。所有结果 `certified=false`。
本轮没有第三条同场控制、额外网格、容差扫描或 evaluator refinement；旧 512/768 差不能当本轮误差条。

## 4. 公平计时、资源与运行可移植性

按 direct 全链先完成、FMM 全链后完成的顺序串行运行，不启动并行 MATLAB。
两个后端执行相同逻辑，但实际轮数/点数可以不同，分别报告 `N_direct` 与 `N_fmm`。
对比全链成本时同时报告点数、每点时间分布和搜索成本，不用共同点数虚构总时间。

互斥主账本包括：逐点 search evaluation 合计、search orchestration、额外 final field、完整 jumps、
mass、geometry 与 assembly/audit、save/export、进程 startup/shutdown 和 orchestration。
完整 pipeline wall time 包含所有必要 checkpoint、批次启动及输出；同时保留求值器纯计算时间。
callback 时间只作包含关系明确的子项，绝不再次加到所属 point/jumps/mass 时间上。
保存调用次数、source/target 数、分块和 FMM 状态，以检验实际替换覆盖面。

用户授权本任务总时钟 180 分钟、峰值 RSS 3 GiB，覆盖设计、实现、失败/修复、运行和审查；
任务起点 `2026-10-21 04:47:41 UTC`，硬截止 `07:47:41 UTC`，批次不得重置总时钟。
每个 MATLAB 批次计划不超过 30 分钟，只在客观进度表明即将完成时允许一次至多 10 分钟 grace，
40 分钟或 3 GiB 为硬限。保持一个 `pipeline-v1` attempt，失败证据保留，不清零总预算。
预估 direct 80–95 分钟、FMM 约 10 分钟、启动/输出约 10 分钟、实现/审查约 30 分钟；
这是资源规划推断，须以首批实际每点时间和剩余工作实时复核，不能当实测性能。

批次仅为授权总预算内的进程边界。新目录可保存本轮自己的 checkpoint 续算，但不读取旧实验历史。
续算必须保持完整轮和实际点顺序；不能为了重启复制已经完成的点并隐去时间，也不能遗漏必要调用。
MATLAB 运行只依赖 `pipeline-v1` MATLAB 源码、公共 package、现有 FMM MATLAB/MEX。
launcher 负责加 path、输出目录、资源监控与环境记录；数值源码不能发现 repo root 或读取人类文档。
移走新目录和必要包、重新配置 MATLAB path 后仍应可运行。禁止修改/遮蔽公共包。

团队创建参数由父代理记录为明确请求 `gpt-6-astra / high` 且创建调用被接受；没有独立运行时模型遥测，
不得把请求/接受状态升级为运行时模型身份验证。

## 5. 验收、反证与结果记录

`ESTABLISHED`：上述旧搜索候选语义、raw-field 公式和配置来源已从本地代码核对。
`CONDITIONAL`：若新实现遵守合同且两条链全部完成，才可比较本次独立全流程结果与 wall time。
`PROVISIONAL`：资源预估和后端一致性尚无本次运行证据。

需优先排查的 blocker 是：后端共享搜索数据/场、首轮阶数错误、宽度门误判、分项或尾项缺失、
warning/QZ/FMM 失败、错误归一化混用、资源越界或主账本双计。
important caveats 是：离散宽扫可能遗漏分支、roundoff 平台可使候选分离、两个候选对应不同场、
一次顺序运行含机器负载/冷暖启动影响、无 quadrature/evaluator/geometry/tail 单侧误差认证。
这些 caveats 限制结论，不自行阻止授权的数值比较。

最小验收检查：从 CSV 重建每轮点数、实际间距、dip/winner/候选与 width gate；从 raw MAT 重算
分项、$C_{\rm num},\varepsilon_{\rm num},U_{\rm num},Q_{\rm num},D_{\rm num},R_{\rm num}$；
核对点数+各自一次 fresh 构场、全部 FMM `ier`、同场数组与有限/观察尾项、互斥计时与资源记录。
最终比较同时给候选差、$k_*^2$ 差、全部标量与重要分项的绝对差/相对差；双零相对差为零。
差异不是误差界，小 ratio 或小 $R_{\rm num}$ 也不代表更准确。

研究决策为 `GO` 到实现与独立 pre-run 检查；这不是独立审查 verdict。最弱环节是观察尾项和 sampled
geometry 的非认证性，以及 total-time 预算估计。若其中数值完整性失败，最小降级为该后端有限前缀；
若仅搜索或资源未完成，保留实际点和成本，不能报告完整 pipeline 对照成功。

本合同冻结时尚未启动 MATLAB；冻结后的实际执行结果单独记录在下节。本文档作者未启动 MATLAB。

## 6. 本轮完整执行结果

当前证据为 `test/i8/pipeline-v1/output/run-02/` 下两后端各自的 `pipeline-result.json`、
`points.json`、`rounds.json`、逐批 `request.json/status.json` 和 `estimate/scientific.mat`。
关键结果保留于本文和 [[test/i8/pipeline-v1/README|pipeline-v1 复现说明]]。
生成的 `summary.json`、`summary.csv`、`rounds.csv`、`components.csv` 与 `callbacks.csv`
统一位于 `test/i8/pipeline-v1/output/run-02/`，按 output 规则忽略，不纳入 Git。
`summarize_pipeline.py` 只读取本次结果，默认将汇总写入所指定的运行目录。
`run-01/setup/` 的失败证据保留，未改变科学合同。
本节是保存结果的构造性核对；独立 Skeptic 的最终 verdict 为 `PASS WITH CONDITIONS`，见本节末尾。

### 6.1 独立搜索和 fresh 构场

两边各完成 33 点宽扫、19 个 11 点细化轮，共 242 次完整 search point 和一次额外 fresh 构场。
宽扫各自得到唯一 strict interior dip：第 13 节点 $k=1.75$，实际邻点为 1.725 和 1.775。
两条链都未调用 endpoint recovery。最终轮实际整轮宽度均为
$1.3322676295501878\times10^{-14}$，winner 均在内点；没有按平台或小 ratio 提前停止。

| 记录 | direct | FMM |
|---|---:|---:|
| 正式候选 $k_*$ | 1.7562818500073463 | 1.7562818500073423 |
| 候选首次来源：轮/全局评价序/节点 | 19 / 240 / 9 | 18 / 229 / 9 |
| 最终轮 winner：轮/全局评价序/节点 | 19 / 240 / 9 | 19 / 237 / 6 |
| 最终轮 winner 的 $k$ | 1.7562818500073463 | 1.7562818500073423 |
| `adef_sigma` | $8.8866664106406152\times10^{-14}$ | $8.0582176243806685\times10^{-14}$ |
| `adef_ratio` | $1.4708748121018025\times10^{-16}$ | $1.3337542770756416\times10^{-16}$ |
| `aphys_sigma` | $4.3898177630889989\times10^{-14}$ | $3.9888699158095294\times10^{-14}$ |
| `aphys_ratio` | $1.5371788289389097\times10^{-14}$ | $1.3967792552871384\times10^{-14}$ |

各后端 fresh 构场的四指标与自身保存的 candidate 四指标逐项相同。FMM 的最后 winner 重复了
前轮已经取得的同一实际 $k$；累计首次取点规则保留第 229 次评价，未改为第 237 次。
两候选有符号差（FMM 减 direct）为 $-3.9968028886505635\times10^{-15}$，即此处 18 个 ulp；
两者 `mu_num` 差为 $-1.4210854715202004\times10^{-14}$。这些差异与 $W$ 均不是位置误差界。

### 6.2 各自同场的完整普通数值结果

| 标量 | direct | FMM |
|---|---:|---:|
| $\mu_{\rm num}$ | 3.0845259366652269 | 3.0845259366652127 |
| $C_{\rm num}$ | 8.2735456668590057 | 8.2735456668590359 |
| $\varepsilon_{\rm num}$ | $1.6039135669302043\times10^{-12}$ | $1.6064304963971742\times10^{-12}$ |
| $U_{\rm num}$ | 0.11608305827964506 | 0.11608305827964503 |
| $Q_{\rm num}$ | $1.3270052141691763\times10^{-11}$ | $1.3290876072577050\times10^{-11}$ |
| $D_{\rm num}$ | 0.11608305826637501 | 0.11608305826635415 |
| $R_{\rm num}$ | $7.0521608619273654\times10^{-10}$ | $7.0632274130478178\times10^{-10}$ |
| 状态 | `UNCERTIFIED_RNUM` | `UNCERTIFIED_RNUM` |

两边均 `certified=false`，sampled geometry、完整材料/墙观察尾项、质量正性及代数审计通过；
保存的最大 audit defect 分别为 $2.531711452274214\times10^{-13}$ 和
$2.5547940442027093\times10^{-13}$，均小于冻结阈值 $10^{-10}$。
FMM 的 $R_{\rm num}$ 高出 $1.1066551120452309\times10^{-12}$，以 direct 为分母相对差
$0.1569242582113733\%$。质量差为 $-2.7755575615628914\times10^{-17}$，在保存的 double 中
并非完全相同；不能把历史同场控制中质量相同的表述移到这里。

主导 jump 仍是 normal 项。材料 normal 平方和由
$2.0382194856474814\times10^{-24}$ 变为 $2.0387795457227649\times10^{-24}$；
墙 normal 平方和由 $5.3068612653679875\times10^{-25}$ 变为
$5.3817488717557798\times10^{-25}$。较大的分项相对变化来自 internal-wall normal：
$5.0214192348510784\times10^{-26}$ 对 $6.1175429665961231\times10^{-26}$，相对差约
$21.829\%$、绝对差 $1.0961237317450447\times10^{-26}$。因此总体差小不能被写成每个小分项都同样稳定。
全部 signed/absolute/reference-relative 分项差见 `test/i8/pipeline-v1/output/run-02/components.csv`，尾项始终只是观察候选。

### 6.3 互斥成本与资源

以下时间单位均为秒，阶段比为 direct/FMM。两边实际 search 点数相同是本次结果，不是比较前假设。

| 互斥阶段或总量 | direct | FMM | 比值 |
|---|---:|---:|---:|
| 242 次完整 search point 合计 | 4706.354323 | 544.078151 | 8.6501 |
| 额外 fresh field | 20.738638 | 2.356218 | 8.8017 |
| 完整 jumps | 182.943271 | 28.238567 | 6.4785 |
| disk mass | 77.673579 | 13.155118 | 5.9044 |
| geometry + assembly/audit | 2.237217 | 2.140965 | 1.0450 |
| 已单列 save/export | 2.928558 | 2.769540 | 1.0574 |
| 其余 process overhead | 386.562222 | 287.518972 | 1.3445 |
| 成功 MATLAB process wall 总和 | 5379.437807 | 880.257531 | **6.1112** |
| 含 controller 的 backend elapsed | 5379.567750 | 880.366573 | **6.1106** |

“其余 process overhead”是 process 总和减上列已测互斥阶段后的余额，涵盖 startup/shutdown、
preflight、wrapper、清理及未单列的小输出；没有把这些内部环节分别测量后虚构拆分。
direct 单点 min/median/max 为 15.810057 / 19.373738 / 22.326519 秒；
FMM 为 2.043316 / 2.214642 / 2.686541 秒。callback ledger 每后端 search 484 次、estimate
117 次，时间是各自 numerical stage 的子集；FMM 全部 `ier=0`，没有二次计入总和。

本次两个后端各 26 个成功进程批次，最大单批 direct 302.409803 秒、FMM 58.264720 秒；
exit code 均为 0、无保存的 survivor。峰值 RSS 分别为 1,513,144,320 与 1,616,920,576 bytes，
均在授权 3 GiB 内。共同 setup 13.735072 秒单列；早期 `run-01/setup` 中断 10.488923 秒也单列，
不计入成功后端比，但属于任务总预算。成功 launcher wall 为 6273.674372 秒，包含共同 setup、
两个 backend 及 controller；不能将它与其内部阶段再次相加。

### 6.4 结论层级与待闭环项

`ESTABLISHED`（当前保存记录）：两条 512/256 起始的独立全链均完成，实际宽度门通过；
各自一次 fresh field、唯一 768 完整评价和有限正分母均已保存。本次固定顺序、同机配置下，
成功 process 总成本比为 6.1112，而完整 search point 时间比为 8.6501。

`CONDITIONAL`（解释）：本次 FMM 链产生邻近但不同的实际候选，其完整普通 $R_{\rm num}$ 较 direct
高约 0.156924%。该差异共同包含候选位置、构场和后评价差异；每条链内部同场，跨链是两个独立场。
本轮未做第三条同场控制，不能归因全部差异到 smooth-proxy 单项，也不能把 direct 当 exact reference。

important caveats：没有重复顺序/冷暖启动实验，故单次 wall 比不代表稳定通用加速率；
finite-grid 宽扫没有排除漏分支；无 source/evaluator 网格收敛序列；sampled geometry、disk quadrature、
FMM 请求容差和观察尾项都没有闭合单侧误差界。较小的匹配指标不保证较小 estimator，本轮 FMM 恰有
更小 `aphys_ratio` 而更大 $R_{\rm num}$。不能写成认证谱距离、特征值包围或已确定的特征值误差。

独立审查状态：`PASS WITH CONDITIONS`，无未解决 blocker。Skeptic 亲自执行两个独立脚本均 exit 0，
搜索/资源审计完成 8122 项检查，raw 重组与保存 JSON 一致；完整独立证据与限制见
[[research/projects/eig-apost/implementation/i8/review-8-4c|review-8-4c]]。
本文作者的源码/JSON 读核与 Skeptic 的 raw MAT/搜索复核是不同验证层，不混记为同一操作。

独立审查还报告了一项有界运算次序敏感性检查：接近抵消精度的 lead raw action 可有约 50% 的
相对变化，绝对尺度仅约 $2\times10^{-14}$；传播到最终 $R_{\rm num}$，direct/FMM 对各自保存主值的
相对变化分别约 $-1.00044\times10^{-5}$、$-1.15276\times10^{-5}$。该检查不启动新搜索、不产生新场、
不替换上表主结果，也不提供认证误差条。它进一步支持“分项不全相对稳定”的 important caveat。
最终研究决策为 `GO`：接受本次独立全流程数值与成本对照，并保留单次顺序计时、未排除漏分支及
全部非认证限制；不升级为谱包围或普遍精度/加速结论。
