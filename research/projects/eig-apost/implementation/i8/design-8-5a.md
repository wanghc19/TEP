# I8.5：两档空间离散与多 dip 搜索

## Material Passport

- Origin Skill / Mode: `academic-research-suite / experiment-agent / plan`
- Origin Date: `2026-10-22`
- Design ID: `I8.5-TWO-RESOLUTION-MULTIDIP-V1`
- Status: `RUN COMPLETE WITH EXPLICIT UNRESOLVED REGIONS; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Claim boundary: `FINITE-GRID CANDIDATE SEARCH ONLY`
- Experiment: `test/i8/scan-v1/`
- Review: [[research/projects/eig-apost/implementation/i8/review-8-5a|review-8-5a]]

本轮在当前 I8 模型上用 coarse 宽扫发现所有可见内部谷，将每个来源区间切换到 fine 后分别细化。
只搜索 candidate，不构造谱距离后评价，不计算 $C_{\rm num},\varepsilon_{\rm num},U_{\rm num},R_{\rm num}$。
它不改写 [[research/projects/eig-apost/implementation/i8/design-8-4b|I8.4 全流程合同]]，不调用 `+scan`。
本合同与独立审查分开；本文构造性研究判断不是 Skeptic verdict。

依赖图为：唯一配置 → coarse 网格 → 点调度/FMM 单点评价 → 全部 dip/待处理区间 →
fine 扩窗重采样 → 多分支细化与缓存复用 → 每终端 candidate 绕过缓存复算 → 保存/展示与独审。
可读参考为 I8.4 的 `pipeline_i8_config.m`、`pipeline_i8_numeric.m`、搜索规则和本地 FMM 包装器；
新数值入口不调用其他 I8 实验源码，不读取其结果。只提取完整单点构造所需的局部代码，保留出处和差异说明。

## 1. 冻结配置及语义

科学参数仅由 `scan_i8_config()` 定义，launcher 不维护副本，Markdown 不控制运行。

| 对象 | 本轮唯一设置 |
|---|---|
| 模型 | $\beta=0.5$，$d=L=1$，$X_L=-0.5,X_R=0.5$，背景材料系数 $1$ |
| lead | 半径 $0.2$ 圆，材料系数 $17$ |
| center | 材料系数 $2$ 的公共光滑五瓣 star；六行位置/导数数据同时乘 $\sqrt{0.04/0.0618}$ |
| coarse | `center_ntot=256, lead_ntot=128` |
| fine | `center_ntot=512, lead_ntot=256` |
| 公共辅助离散 | $M=48$，$K=97$；`nside=160, ntop=160, nproxy=80, mpw=32` |
| proxy | `H=1.1, proxy_dist=0.2`；每胞元 $320$ 个 proxy 源 |
| FMM | 已安装官方 FMM2D，提交 `550dae5b77b1e006c8ffae37fc832f8c2b536871`，请求容差 $10^{-12}$ |
| 宽扫 | `1.45+(0:32)*0.025`，coarse 档，共 $33$ 点 |
| 局部 | 每轮 $11$ 个实际节点，正常完成整轮宽度 $W\le2\times10^{-14}$ 且 winner 为内点 |
| 选点评分 | `aphys_ratio`；exact 并列取数组首次索引，不以 `aphys_sigma` 改变排序 |

公共 `construct_S` 的 physical-density scaling、periodic BIE/Kress、QZ/DtN、matching、权重和 SVD
均沿用已验证路径。只通过已有 callback 换 smooth-proxy 势、一阶与二阶导数；不替换奇异核处理。
保留 QZ 资格、维数、finite、FMM `ier`、线性求解和 warning 检查，不把失败值补成大数。
所有四指标都来自该点同一组 $194\times194$ matching 矩阵。

`design-8-1a.md` 第 135 行的请求网格、I8.4 设计第 2 节和当前 pipeline 配置都将
$[1.45,2.25]$ 用作有限宽扫描范围。本轮称其为 **搜索窗口**，没有核验其端点为 projected gap 精确端点。
不加入 $768$ 后评价配置、质量积分或任何谱距离辅助参数。

## 2. 六项职责与轻量接口

| 职责 | 接口/责任 | 不得承担的工作 |
|---|---|---|
| 构造网格 | `LOCAL_grid` 接收实际区间、规则和已有节点信息；返回节点及请求/实际尺度 | 不调用物理计算或读取矩阵 |
| 单点评价 | `scan_i8_point(k,resolution_id,config)` 返回四指标、状态、耗时及按需 raw 证据 | 不选区间、不细化、不停止搜索 |
| 点调度 | `LOCAL_schedule` 检查 cache，逐点只算缺失成功记录，保留失败和请求关系 | 不把 coarse/fine 值混合排序 |
| dip 识别 | `LOCAL_dips` 只读已评价节点/评分/有效性，返回全部谷、平台与待处理区间 | 不调用点评价或读取历史结果 |
| 扫描管理 | `scan_i8_search(output_dir,mode)` 及 `LOCAL_` 管理来源、升档、分支、恢复和停止 | 不改变模型/配置以追求更深谷 |
| 保存展示 | 保存 checkpoint、表格和曲线，记录模型与阶段 | 不由展示或导出结果决定科学参数 |

上述局部名称是职责合同；实际辅助函数名可细分，并在最终源码说明中对应。
测试 mode 可注入便宜人工评分器，但正式 mode 只走真实 FMM 点函数。

点记录至少含 `point_id,resolution_id,k,k_hex,metrics,seconds,status`；interval 记录含
`interval_id,parent_id,source_ids,resolution_id,bounds,status`；history 含 `round`、实际全网格的
point-ID 引用、winner、$W$、相邻间距、原始全部局部谷、分支/聚类/恢复理由。
空间档位 `resolution_id` 和加密轮 `round` 永远不是同一字段。

cache 在本次运行内共享，身份为**完整科学配置、档位与 `num2hex(k)` 的组合**。
当前实现只从零运行，保存的 checkpoint 是证据，不提供 resume 入口；失败点不作为成功 cache hit，
不按十进制截断/距离阈值去重。今后若获准增加续跑，必须逐项核对完整配置，不能静默读取其他 run。
复算请求有显式 bypass 标记，不覆盖第一次成功记录。分别统计 requests、new calculations、hits、
coarse/fine unique binary64 positions、复算调用和失败调用。

## 3. coarse 全部可见区间与 fine 升档

宽扫完成后按连续 exact-equal 评分 run 处理：单节点严格低于左右邻点是普通内部谷；长度大于一的
平台若两肩严格更高则作为一个谷区间。保留全部这类内部谷，不按相对全局最小值筛掉浅谷。
下降到搜索端点、接触端点的平平台、以及失败点或其邻域单独登记 pending 来源，不能据此报告“没有 dip”。
失败邻域不能构成有效 bracket；程序失败保留错误并修复，不能由缺失值插值掩盖。

每个 coarse 内部谷以其极小 run 外侧紧邻点为初始区间，再向左右各扩一个 coarse 网格单元，
clip 到搜索窗口。立即以 fine 档重新生成 $11$ 点评价；不先把 coarse 区间缩小，亦不比较混合档位评分。
所有 coarse 来源必须有终态或 descendant 列表；重叠本身不是同模态证明。允许不同来源共享相同配置的
点 cache；只有 identical 任务窗口/节点/档位才能合并重复任务，并保留所有 parent/source 关系与理由。

fine 重采样可以显示谷移动、分裂、消失或端点趋势。报告本次实际观察，不把 coarse 最小点位置当作
fine 的固定中心，也不假定每个 coarse 来源恰对应一个模态。

## 4. fine 多谷、平台歧义与边界恢复

每个完整 fine 网格先枚举全部 strict minima / exact-equal 平台。对相邻谷，设两谷评分为 $v_1,v_2$，
其间节点最大评分为 $s$。仅用于判断是否繁殖成不同任务的工程阈值为

$$
\tau=64\,\mathrm{eps}\max(1,\max_j|y_j|).
$$

若 $s-v_1>\tau$ 且 $s-v_2>\tau$，两谷在当前有限网格上记作可分辨并保留各自分支；
否则将相邻未分辨谷连成 ambiguity cluster，完整保存其中每个局部极小/平台、saddle 和判据数值。
该规则只限制 roundoff 附近任务繁殖，**不筛 coarse 谷，不认证模态相同，不作为提前平台停止**。
fine 单个 exact 平台也是一个 cluster，不要求其中某节点严格低于平台伙伴。

单谷下一轮区间为该谷实际左右邻点。多谷 cluster 的下一轮必须包住整个 cluster 最左/最右极小 run
及其外侧邻点，不能仅围住最低谷而静默删除其他极小行。若因此不能缩小且又无法分辨，保留全部歧义，
停止为 `AMBIGUITY_UNRESOLVED` 或等义真实状态，不伪报正常定位。

若全网格最小值在端点，不向该端点持续缩窄。确定恢复规则为：设当前窗为 $[a,b]$、$W=b-a$，
左端 winner 请求 $[\max(k_{\min},a-W),b]$，右端 winner 请求
$[a,\min(k_{\max},b+W)]$；保留对端，整个新窗重新取 $11$ 点，保存实际新旧窗口与方向。
实际窗口不变或达到搜索边界仍无内点支持时记录 `BOUNDARY_UNRESOLVED`。
若窗口中同时有内部谷和端点下降，内部谷保留细化，端点趋势另保留来源，不能用全局最低行抹去内部谷。
恢复采用确定规则；若同一实际窗口重复、节点无法严格递增或区间不能继续缩小，保存相应未完成状态。
扩窗期间的内部 groups 存在 interval 的 `pending_groups` 中，保存 bounds、exact anchor point IDs、
source history 和去向；恢复结束后，只有 exact anchors 已属于当前 group 才引用当前任务，否则建立
`RECOVERY_INTERNAL_DIP` 子任务。不因区间重叠而消去来源。
非 global winner 的端点下降一律保留 `NONWINNING_EDGE_PENDING`，不假称被父窗口覆盖；
最终仍有此记录时，总状态为带未解决区间的搜索交付，已经正常完成的内部 candidate 可分别交付。

## 5. 正常完成、候选与复算

任何网格先检查 finite、严格递增、无 exact binary64 重复；不能按人为近距离阈值删除不同节点。
记录实际 $W=k_{11}-k_1$、最小/最大相邻间距，以及内点 winner 邻点总宽 $w$；$W,w,\Delta k$ 分列。
一个分支正常完成必须同时满足：fine 档、整轮 $11$ 点全部成功、winner 严格内点、实际
$W\le2\times10^{-14}$。小于 $10^{-10}$ 的 `aphys_sigma` 或 `aphys_ratio` 均不触发提前完成。
没有一次评分回升/单轮停滞/宽松平台停止例外。

正式候选采用满足正常完成条件的最后完整 fine 轮中 `aphys_ratio` 的首次 argmin，具有该轮实际左右邻点支持。
另列自身支持记录中的累计 fine 最佳点；若其与正式候选不同，保存差异，不能隐去末轮回升。
分裂后不得把兄弟分支的最低点继承成本分支累计最佳；累计集合限于自身区间支持内的祖先/本分支点。
未正常完成的终端分支只交付实际 fine 最佳点及 provisional 状态，不称已定位 candidate。
即使正常完成，末轮 $W$ 仍是采样区间宽度，不是连续谱点或连续极小点的位置误差界。

所有有有效 fine 最佳点的终端分支均在该 k 上绕过 cache 重新评价，保存四指标绝对差/适当相对差、
成功状态、耗时及必要 raw matching 证据。不因不同位置candidate相近就去重模态，也不要求逐位一致。
若只有 coarse 最佳点，不将其包装成最终 fine candidate；未完成原因与已取得证据照实交付。

## 6. 验证、资源与输出

启动前用便宜人工目标验证：多个普通谷、exact 平台、端点下降/恢复、失败邻域、升档后分裂、
roundoff cluster、coarse/fine cache 隔离、exact 相邻浮点点区分、跨区间成功结果共享和 bypass。
这些是调度验证，不是额外物理研究。独审应重建每个 coarse 来源去向、全部有效轮和终态，
核对 raw 四指标同矩阵、档位、cache identity、最终复算和互斥时间账目。

资源规划依据仅为 I8.4 实测 fine FMM 约 $2.2$ 秒/点；它不是本轮性能测量。粗扫前预计 coarse 宽扫约
1 分钟，峰值 process-tree RSS 约 $1.6$ GB。coarse 后，代码用每个已登记分支
$(11+20\times9+1)\times2.5$ 秒、另加全程 $60$ 秒预留估算：首次 fine 网格 $11$ 点，随后
约 $20$ 轮每轮至多 $9$ 个新点（实际左右端点来自前轮，cache 必命中），最后一次 bypass 复算。
该式是无额外分裂/扩窗的保守规划模型，不是已运行次数；额外恢复和分裂仍计入实际剩余预算。
再据实测每点时间及全部待处理分支复核；若预计无法完成，先报告资源 blocker，不能删浅谷凑预算。

本轮没有另获两小时任务总限。一个正确配置的完整科学结果共享 $30$ 分钟 soft、最多一次有客观
“即将完成”证据的 $10$ 分钟 grace、$40$ 分钟 hard；用户内存授权为 $3\times10^9$ bytes。
分批/checkpoint 不重置同次科学运行时钟。操作性失败按 `test/AGENTS.md` 在同一 attempt 保留 run 日志、
修复后再运行；失败成本另列，不能把数值不理想当操作失败。
只有 Engineer 启动 MATLAB，始终单进程，监控 process-tree RSS、时间、其他 MATLAB 和退出残留。

分别报告 coarse 点计算、fine 点计算、候选 bypass 复算、管理/保存/绘图、MATLAB启停和完整进程时间。
proxy callback 是点时间子集，不能再加到主账本。失败调用与成功结果耗时分开披露。
所有生成 CSV/JSON/MAT/图片/log/checkpoint 仅放 `test/i8/scan-v1/output/`；源码和 README 留顶层。
关键结果保留在本文和实验 README；从空 output 开始仅需本目录代码、公共 package、已安装 FMM2D。

## 7. 研究判断与独审交接

`ESTABLISHED`：本地 I8.4 单点路径和宽扫描用途已核对；此窗口不获无遗漏或 projected-gap 端点认证。
`CONDITIONAL`：上述全部来源可追踪、独立 fine 细化及复算成立时，可交付本次有限网格候选。
`ESTABLISHED`（执行后）：本轮 coarse 谷数、升档后去向、实际计算成本和候选均已有第 8 节原始记录。
执行前这些量仅属 `PROVISIONAL`，资源预估和冻结规则仍保留于前文，未用结果追溯调整合同。

执行前实施门为 `GO` 到有界代码验证和独立 pre-run 检查，现已完成正式运行与独审。
预注册检查的可能 blocker 是配置混用、历史candidate输入、
失败伪造、遗漏粗谷来源、删除可辨分支、width gate 误判、cache错误或资源不足。
important caveats 是窄谷可能未被33点粗网格发现、fine ambiguity可能无法区分模态、有限矩阵dip非连续谱证明；
这些限制不要求本轮新增认证、谱距离或加密研究。无新增科学结论不得标记已验证。

作者只读参考旧源码、编写本设计与符号映射，未启动 MATLAB。Researcher、Engineer、Skeptic 是本轮新建
代理并继承主线程设置；工具可见的是继承创建参数，没有独立运行时模型/effort 遥测。
实际结果与接口核对如下；[[research/projects/eig-apost/implementation/i8/review-8-5a|独立审查]]
给出 `PASS WITH CONDITIONS`，2927 项检查通过，无未解决 blocker。左边界、非 winner 端点趋势及
有限网格覆盖限制仍按 important/minor caveats 披露，不因审查通过改写为已解决。

## 8. 本次执行结果

证据来自 `test/i8/scan-v1/output/attempt-1/run-01/` 的 `state.json`、`summary.json`、
`status.json`、逐点/轮 CSV、`checkpoint.mat`、候选 raw MAT 和资源日志。
本节构造性重读这些记录，不替代 Skeptic 独立重组。
全程只运行本轮 FMM 搜索，没有计算任何谱距离量。

### 8.1 coarse 来源与 fine 去向

coarse 的 33 点全部成功，发现 **1 个内部 strict dip**，位于第 13 节点 $k=1.75$，
`aphys_ratio=0.009348171276046107`，原相邻点窗 $[1.725,1.775]$。
按合同扩一粗单元后从 fine 窗 $[1.7,1.8]$ 开始，最终 interval 1 完成 21 轮，状态 `COMPLETE`。
另有 coarse 左端下降，登记 interval 2，以 fine 窗 $[1.45,1.525]$ 核查；其 winner 仍是原搜索窗口
左端 $1.45$，外扩被搜索窗口限制，明确 `BOUNDARY_UNRESOLVED`，不把该点称为已定位内部 candidate。
没有 coarse 来源丢失，没有可辨 fine 分裂或粗谷消失的实测证据。

fine 第 1 轮实际 winner 为 $1.76$，第 2 轮为 $1.756$，随后细化到下表候选。
这首先是采样网格细化造成的 winner 位置变化，**不能单独归因为空间升档的模态移动**。
本次自然重叠点 $k=1.75$ 的 fine ratio 为 $0.009348171276045458$，与 coarse 值很接近；
本轮没有完整双档曲线对照，亦没有定位 coarse 连续谷底，因此不作空间误差结论。

第 19、21 轮各观察到 3 个 raw local minima，但相邻谷 saddle prominence 小于冻结数值歧义门
$1.4210854715202004\times10^{-14}$，都记录为一个 ambiguity cluster；未把它们声称为三个模态，
也未删除其原始行。第 19 轮整 cluster 的外邻点覆盖决定第 20 轮窗口，而非只围最深谷。

### 8.2 候选与未解决记录

| 字段 | 正常完成的内部候选 | 边界 provisional 最佳点 |
|---|---:|---:|
| interval / fine round | 1 / 21 | 2 / 1 |
| $k$ | 1.7562818500073423 | 1.45 |
| `adef_sigma` | $8.058217624380668\times10^{-14}$ | 4.099017761904005 |
| `adef_ratio` | $1.3337542770756416\times10^{-16}$ | 0.006784444539618595 |
| `aphys_sigma` | $3.9888699158095294\times10^{-14}$ | 1.3728810878019677 |
| `aphys_ratio` | $1.3967792552871384\times10^{-14}$ | 0.32530670466799405 |
| 实际整轮 $W$ | $4.218847493575595\times10^{-15}$ | 0.07499999999999996 |
| winner index / 11 | 2 | 1 |
| 终态 | `COMPLETE` | `BOUNDARY_UNRESOLVED` |

内部候选末轮实际端点为 $[1.7562818500073418,1.756281850007346]$，最小/最大相邻间距为
$2.220446049250313\times10^{-16}$ 和 $4.440892098500626\times10^{-16}$。
winner 邻点为 $1.7562818500073418$ 与 $1.7562818500073427$，邻宽
$w=8.881784197001252\times10^{-16}$；它与 $W$ 分开记录。
正式 candidate 与自身累计 fine best 在本次恰为同一点。两个表列点各额外 bypass 完整复算一次，
各自四指标绝对差均为 0；相对差也为 0，没有用 cache 冒充复算。

另保留 3 条 `NONWINNING_EDGE_PENDING`，不声称已排除其外侧可能谷：

| 所属区间 / 轮 | 方向 | 实际端点 $k$ | `aphys_ratio` |
|---|---|---:|---:|
| 1 / 20 | 左 | 1.7562818500073252 | $2.582418718659016\times10^{-14}$ |
| 1 / 21 | 右 | 1.756281850007346 | $1.4447446417568652\times10^{-14}$ |
| 2 / 1 | 右 | 1.5249999999999999 | 0.3609703568806507 |

前两条在末轮量级接近数值平台，但记录仍未被擅自清除；第三条是边界核查窗另一端趋势。
因此总状态诚实保留 `SEARCH_FINISHED_WITH_UNRESOLVED_INTERVALS`，不写成整个窗口全部解决。
这不否定 interval 1 已满足本轮正常定位条件；未解决记录也不能被计入“已认证模态数”。

### 8.3 实际细化和工作量

下列整宽均由实际节点算得；完整 22 个 fine 网格、实际点引用、winner 和判据保存在 `rounds.csv/state.json`。

| interval 1 轮 | 实际 $W$ | 该轮最低 `aphys_ratio` |
|---:|---:|---:|
| 1 | $1.000000\times10^{-1}$ | $5.521848\times10^{-3}$ |
| 2 | $2.000000\times10^{-2}$ | $4.189071\times10^{-4}$ |
| 3 | $4.000000\times10^{-3}$ | $1.755895\times10^{-4}$ |
| 4 | $8.000000\times10^{-4}$ | $5.669781\times10^{-5}$ |
| 5 | $1.600000\times10^{-4}$ | $9.140064\times10^{-6}$ |
| 6 | $3.200000\times10^{-5}$ | $3.715591\times10^{-7}$ |
| 7 | $6.400000\times10^{-6}$ | $3.715591\times10^{-7}$ |
| 8 | $1.280000\times10^{-6}$ | $8.906252\times10^{-9}$ |
| 9 | $2.560000\times10^{-7}$ | $8.906252\times10^{-9}$ |
| 10 | $5.120000\times10^{-8}$ | $1.296944\times10^{-9}$ |
| 11 | $1.024000\times10^{-8}$ | $2.249249\times10^{-10}$ |
| 12 | $2.048000\times10^{-9}$ | $7.944537\times10^{-11}$ |
| 13 | $4.095999\times10^{-10}$ | $1.857157\times10^{-11}$ |
| 14 | $8.192003\times10^{-11}$ | $5.776993\times10^{-12}$ |
| 15 | $1.638401\times10^{-11}$ | $8.995263\times10^{-13}$ |
| 16 | $3.276934\times10^{-12}$ | $6.788081\times10^{-14}$ |
| 17 | $6.552536\times10^{-13}$ | $2.767702\times10^{-14}$ |
| 18 | $1.310063\times10^{-13}$ | $1.957579\times10^{-14}$ |
| 19 | $2.620126\times10^{-14}$ | $1.418412\times10^{-14}$ |
| 20 | $2.087219\times10^{-14}$ | $1.421104\times10^{-14}$ |
| 21 | $4.218847\times10^{-15}$ | $1.396779\times10^{-14}$ |

第 20 轮评分略回升，且 $W$ 仍大于目标；程序继续第 21 轮，没有平台提前停止。

| 调度项目 | coarse | fine | 合计 |
|---|---:|---:|---:|
| 请求数（含 bypass） | 33 | 244 | 277 |
| 新搜索计算 / 不同成功 $k$ | 33 | 186 | 219 |
| bypass 复算 | 0 | 2 | 2 |
| 实际完整点调用 | 33 | 188 | 221 |
| 成功 cache hits | 0 | 56 | 56 |
| 点失败 | 0 | 0 | 0 |

不同空间档位的相同 $k$ 不共用结果；按档位统计的不同点数不能误称全体互异实数点数。
cache 共避免 56 次重复搜索计算，未估算或宣称额外加速倍数。

### 8.4 时间、环境与失败记录

| 互斥阶段 | 秒 |
|---|---:|
| coarse 33 点 | 32.928586250 |
| fine 186 个新搜索点 | 423.392614458 |
| 两次 bypass 复算 | 4.658247292 |
| 其余进程成本 | 19.461427209 |
| 完整正式进程 | **480.440875209** |

数值点合计 $460.979448$ 秒。搜索入口计时至最后保存为 $463.895434$ 秒；与数值点时间差约
$2.915986$ 秒，包含调度和搜索保存。进程减该入口时间约 $16.545441$ 秒，包含 MATLAB 启停、
环境/配置准备、最终保存/作图及退出。内部细目没有单独计时，不虚构更细拆分；callback 时间不重复相加。
coarse 点 min/median/max 为 $0.875920/0.979077/1.360633$ 秒；fine 搜索点为
$2.030175/2.211875/3.025004$ 秒。它们是不同档位工作量，不是 direct/FMM 速度比较。

实测 MATLAB R2023b `23.2.0.2365128`、MACA64，MATLAB threads 11，`OMP_NUM_THREADS=11`、
`OMP_DYNAMIC=FALSE`。正式进程 exit 0，采样 process-tree 峰值 RSS **1,225,981,952 bytes**，
无退出残留，低于 $3\times10^9$ bytes；总正式运行约 8.01 分钟，无延长。

同一 `attempt-1` 的 `setup-01` 因 sandbox 不允许 `ps` 在 MATLAB 启动前失败；另一次 Python
字节码编译写全局 cache 被拒绝，改用不写字节码的语法检查。失败证据保留在 `operation-notes.json`
及对应日志。`setup-02/03` 成功耗时分别 $16.736841/14.724555$ 秒；后者包含最终 11 项便宜人工测试，
覆盖双谷、平台/端点、失败、升档分裂、精确 cache/bypass 和 endpoint 内部谷来源保留。
这些开发/验证成本不并入正式搜索时间；正式科学运行只有 `run-01`，没有为追求更深数值重跑。

`ESTABLISHED`（本次记录）：一个 coarse 内部谷升档细化完成、两个终端 fine 点复算一致，全部 coarse 来源有去向，
预算内交付全部记录。`CONDITIONAL`（解释）：得到一个正常完成的有限矩阵候选；不能由此推出整个窗口无遗漏、
模态唯一或连续谱结论。左边界和三条非 winner 端点趋势仍未解决；独立审查及问题账目保留这些边界。
