# I7.1 独立审查：椭圆中心缺陷自适应扫描

## 核调用修订审查（2026-09-22）

### A. 审查框架

- 审查对象：在不改变 I7.1 物理模型、扫描节点、离散配置和输出语义的前提下，移除实验目录的
  package shadow，并验证公共 `kernel.h2d_directch` 的实际资源需求和必要的最小内存适配。
- 当前阶段与成功条件：工程数值复现。必须先真实执行未改公共核；只有它越过 30 分钟或
  3 GB（3,000,000,000 bytes）门才可进入方案 2。现行方案必须通过公共缺省路径、跨 batch
  数值等价、MATLAB path、完整 final 扫描、旧保存点和 process-tree 资源门。
- 排除项：不改材料、几何、QZ、DtN、中心矩阵、候选规则或 `out`；本轮不执行 I7.2，也不要求
  严格谱认证或显著 dip。
- 审查材料：公共 `+kernel/qpgreen_mfs_pairmat.m` 和 `+kernel/h2d_directch.m`；
  `scan_i7.m` 的 `LOCAL_kernel_check`、`LOCAL_h2d_chunked_public` 及两处 `pars`；
  `.gitignore`；`scheme-1-run-01`、`scheme-2-run-01`、`audit-run-02`；旧 `run-01`；
  `pre-change.json`、`history-preservation.json`、`scope-check.json`，以及当前 README/设计。
- 独立性：审查者未运行 MATLAB、未修改代码或结果，只独立读取源码、命令、日志、CSV、监测
  时间序列和串行 MATLAB audit。下面保留首轮 `run-01` 审查作为历史证据。

### B. Verdict

`PASS WITH CONDITIONS`，置信度高。

严格方案顺序、公共缺省兼容、target 分批、真实深层调用、完整扫描和资源门均有一致证据。方案 1
确实解析到根目录公共核，在进入首个 final pilot 后于第 42 s 采到
3,105,751,040-byte process-tree RSS，越过 3 GB 门；包括终止等待的 wall time 为 47 s，exit code
为 143。随后方案 2 只在公共 pair-matrix 的高内存 proxy-source 调用增加可选 evaluator；完整扫描
以 exit code 0 完成，wall time 203 s、入口 runtime 182.508327708 s、peak process-tree RSS
1,071,398,912 bytes。现行 `out` 的六个科学标量，以及 57 条 history 的阶段、配置和数值等科学
字段与旧成功结果逐项相同；逐点评价耗时按预期不同，未纳入等同性判断。
条件仍是把 $k=1.45$ 解释为左扫描边界上的“当前扫描最佳点”，不升级为 interior dip 或特征值。

### C. 最强挑战

最能推翻方案 2 的失效方式是：callback 在 flatten 后的 source-target pair 列上遗漏、重复或重排
target，或在分批时遗漏 source/charge，从而产生形状正确但物理错误的散射矩阵。源码逐列覆盖证明
和两级数值检查共同排除了当前实现中的这一机制：循环使用互不相交且并集为 `1:nt` 的连续索引，
每批原样传入全部 `sources` 与 `charge`；17-source/777-target 的 direct 三输出和
4-source/137-target 的深层 pair-matrix 六输出均跨越 512 边界且相对差为 0。history 的科学字段
与旧结果完全相同，进一步覆盖了真实 `construct_S` 调用链。

### D. Findings

1. `IMPORTANT CAVEAT` — 科学候选仍受扫描左边界限制。
   - 位置：`scheme-2-run-01/history.csv`、`summary.txt` 与 I7 README 的 `I7-Q1`。
   - 证据：17 个 gap 样本和 33 个 screening 点均有效；6 个 unique final 点中最小值仍为
     $k=1.45$，五点确认值从左端递增，停止原因为边界 minimum。
   - 当前后果：核调用修订可接受，I7.1 数值结果可复现；但不能声称 interior dip、band edge、
     离散根或连续特征值。
   - 不确定性：未评价更低 $k$，且 $[1.45,2.25]$ 两端是扫描截断而非计算出的 band edges。
   - 最便宜决定性检查：仅当后续目标需要 interior dip 时，先向低 $k$ 扩展 projected-gap 采样，
     再以同一 final 配置确认；当前 I7.1 无需追加计算。

未发现当前核调用修订的 unresolved blocker。

### E. Implementation audit

- 顺序门：方案 1 的命令先解析并断言根目录公共 `+kernel/h2d_directch.m`，完成全部 gap 点后才在
  首个 final pilot 越过硬内存门。方案 2 在该失败证据保存后才启用；方案 3 未采用。
- 公共接口：唯一公共源码改动位于 `kernel.qpgreen_mfs_pairmat` 的 proxy `potP/gradP/hessP`
  调用。`pars1.h2d_evaluator` 缺失或为空时执行原 `kernel.h2d_directch(k,Z,q,T_in)`；非空值必须
  是 scalar function handle。原点 `pot0`、regular diagonal、坐标交换、导数回映射和位置参数接口
  均未改。公共 `+kernel/h2d_directch.m` 与 HEAD/main 字节相同。
- 分批实现：`LOCAL_h2d_chunked_public` 预分配 $1\times n_t$、$2\times n_t$、$3\times n_t$
  三个输出，只按连续 target 列切分；所有 sources 和 charges 在每批保持原对象与原顺序，三个输出
  写回相同列。`LOCAL_center` 与 `LOCAL_cellsub` 使用同一个 callback，没有复制 Hankel 公式或
  上层散射调用链。
- 等价性：direct public/batched 的 potential、gradient、Hessian 三项相对差均为 0；
  pair-matrix 的 missing-field default、显式 public callback 和 batched callback 六项相对差均为 0。
  后者的 548 个 flattened pair targets 跨 batch 边界，并经过 I7 实际使用的 y-periodic 坐标和导数
  路径。
- 路径与临时文件：现行命令只 `addpath` 仓库根和 `scan-v1`，没有 `genpath`；`tmp/` 不在 MATLAB
  path，`which('kernel.h2d_directch')` 只解析到公共 package。旧 formula copy 和旧 validator 位于
  ignored `tmp/`，现行 `+kernel/` shadow 不存在。新增 `.gitignore` 规则仅为 `/test/**/tmp/`；
  immediate/nested test `tmp` 命中，`tmp-other` 和 test 外 `tmp` 不命中，且没有 tracked test/tmp
  路径。
- 结果来源：`scheme-2-run-01` 交付七个有限标量；MATLAB audit 证实字段数、标量性、final tuple、
  $M=48$、model、扫描覆盖和有效 final argmin。审查者另从 CSV 重算 6 个 unique final 点的 argmin，
  并比较两次 57 条 history 的科学字段；阶段、配置、$M$、$k$、valid 和四个指标全部相同，
  逐点评价 `seconds` 未纳入等同性判断。六个科学 `out` 标量的 MATLAB relative difference 为 0；
  runtime 按本次入口实测更新。
- 资源和失败保留：方案 2 的 654 个资源样本独立给出同一 1,071,398,912-byte tree peak。首个
  audit 命令因缺一个右括号在加载产物前退出，21 s/888,733,696 bytes 的失败记录被保留；修正后的
  `audit-run-02` 以 exit code 0、17 s 和 851,787,776 bytes 通过全部 gate。四次受监测 MATLAB wall
  time 合计 288 s。22 项旧运行文件（含移动到 `tmp/` 的旧核源码）SHA-256 全部保持不变。
- 规模控制：实现只增加一个窄公共条件分支、一个 I7-local batching helper 和一个有界回归 helper；
  没有转发 wrapper、公式副本或新的框架。`qpgreen_mfs_pairmat` 的 `checkcode` finding 为 0；
  `scan_i7.m` 的 6 条 advisory 仍是已说明的 cleanup lifetime 和有界 append，没有 error finding。

### F. What survived

- I7.1 的材料、圆形 half-guide、中心椭圆、两类空间离散、$k$ 网格、中心匹配、权重、QZ/DtN、
  候选选择和七字段 `out` 语义均未改变。
- 公共原版在 final 配置超出 3 GB 是实测结论，不是静态估计；最小公共 hook 的必要性因此成立。
- 现行计算仍实际调用公共 direct kernel；batching 只改变一次请求包含的 target 数量。
- 新旧 history 的科学字段和六个科学输出精确相同，支持“内存调度变化未改变本次数值实验”的
  有限主张；逐点评价耗时不在该等同性主张内。
- 旧 `run-01`、方案 1 失败、方案 2 成功和两次 audit 均各自保留，失败没有被覆盖。

### G. Minimal resolution

当前核调用修订无需代码修复或追加实验即可接受；`I7-Q2` 已由 `scheme-2-run-01` 和
`audit-run-02` 关闭。下一正常 gate 仍是已规划的 I7.2，且只有在 I7.2 需要解释边界候选时才扩展
扫描范围。公共 hook 将来若被 I7 以外的 caller 使用，应由该 caller 添加其自身的 callback 等价和
资源检查；这不是当前 I7.1 的阻塞条件。

### H. Open-problem handoff

唯一未解决的 goal-relevant handoff 仍是
[[research/projects/eig-apost/implementation/i7/README|I7 README]] 中的 `I7-Q1`。该问题限制
特征值解释但不阻止接受 I7.1 或进入 I7.2；最低下一检查和状态以 README 的唯一问题表为准。
`I7-Q2` 已关闭，不作为 open item 重复列出。

## 历史数值扫描审查（attempt-1/run-01）

以下 A--H 保留首次成功扫描及其旧 I7-local 核的独立证据。它们描述历史 `run-01`，不覆盖上面的
现行公共 callback 结论；其中“公共函数未修改”和“I7-local kernel 为现行路径”等陈述只适用于
该次历史运行。

### A. 审查框架

- 审查目标：判断 I7.1 是否以固定 $\beta$、固定材料和固定两侧周期半波导，正确地把空中心匹配替换为单个椭圆 inclusion 的中心散射匹配，并在预算内交付可复现的 final-config 扫描结果。
- 当前阶段：工程数值实验；不要求严格谱认证、Hermitian 定理或显著 dip。
- 验收标准：final 配置
  `ntot=256, nside=160, ntop=160, nproxy=80, mpw=32, M=48`
  至少产生一个有效评价；`out.k` 是全部已完成 final-config 有效评价中
  `aphys_ratio` 的最小点，四个指标来自该点的同一组矩阵；扫描、无效点、停止原因、运行时间和资源监测可以追溯。
- 模型边界：$\beta=0.5$、周期 $d=1$、人工墙 $X_L=-0.5$、$X_R=0.5$；所有 inclusion 均取 `epsrel=17`。两侧 half-guide 保持半径 $0.2$ 的圆，中心为横/纵半轴 $0.25,0.16$ 的椭圆。两者面积均为 $0.04\pi$。
- 权威与材料：仓库根目录和 `research/`、`test/` 的 `AGENTS.md`；main 参考提交
  `54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb` 中的
  `draft/examples/projgap.m`、`draft/examples/betagmode.m`；
  `+bloch/construct_S.m`、`+bloch/rayleigh_channels.m`、`+geom/construct_cont.m`、
  `+kernel/h2d_directch.m`；I2 当前 README、I2.2/I2.3 设计和审查材料；
  [[research/projects/eig-apost/implementation/i7/design-7-1a|I7.1 design]]、
  `test/i7/scan-v1/scan_i7.m`、I7-local `+kernel/h2d_directch.m`、
  `validate_chunked_kernel.m`，以及
  `output/attempt-1/run-01/` 中的命令、日志、MAT/CSV 结果和资源记录。
- 审查独立性：本审查只写本文件，不修改设计、实验代码或输出，也不启动 MATLAB 计算。

### B. Verdict

`PASS WITH CONDITIONS`，置信度高。

I7.1 已达到本轮工程数值目标。`run-01` 以 exit code 0 完成；17 个 projected-gap 样本、33 个筛选点、6 个 unique final 点和一次 winner repeat 全部有效。独立从 `history.csv` 重算 final 有效集合得到同一 argmin：$k=1.45$、`aphys_ratio=0.31371305311538561`；其余三个指标与 `out` 和 repeat 一致。四个指标来自 final 配置和 $M=48$ 的同一次 `LOCAL_point` 组装。总入口时间为 $193.156499250$ s，受监测 wall time 为 $217$ s，process-tree peak RSS 为 $870{,}367{,}232$ bytes，均低于冻结限额。条件是只能把结果解释为有限扫描左边界上的“当前扫描最佳点”；当前证据没有显示 interior dip，也不确认特征值。

### C. 最强挑战

最强挑战是 winner 位于扫描下限。`run-01` 的 17 个 gap 样本在 $[1.45,2.25]$ 全部通过，因此两端只是扫描截断，不是计算出的 band edges；33 个筛选分数没有严格内点低谷，final 的五个边界区间点又从 $1.45$ 起单调上升。更低的 $k$ 可能给出更小分数，本轮不能据此声称发现 dip 或特征值。该问题限制解释，但不推翻用户明确允许的边界“当前扫描最佳点”交付。

### D. Findings

1. `IMPORTANT CAVEAT` — winner 受扫描左边界限制。
   - 位置：`run-01/history.csv`、`summary.txt` 和 `scan.mat`。
   - 证据：sampled window 为 $[1.45,2.25]$，两端均等于预设扫描端点；final 有效点的最小值在 $k=1.45$，停止原因为 `current final minimum lies on scan boundary; low-order basin not confirmed`。
   - 当前后果：I7.1 可以交付数值有效的 current scan best，但不能声称 interior dip、band edge、离散根或连续特征值。
   - 不确定性：未评价 $k<1.45$；该方向是否仍在 projected gap 内也未知。
   - 最便宜决定性检查：若后续科学目标需要 interior dip，先向低 $k$ 扩展圆 lead 的 projected-gap 采样，再用同一 final 配置确认；I7.2 在当前点附近的 sign count、离散稳定性和同模态比较只能增加佐证，不能消除扫描截断。

2. `MINOR CAVEAT` — invalid 分支没有在本次自然数据上动态触发。
   - 位置：`scan_i7.m` 的 warning guard、`LOCAL_qzsub`、`LOCAL_safe_point`、cache-invalid bracket gate；`run-01/history.csv`。
   - 证据：代码把 singular/nearly-singular/rank-deficient solve warning 转为 point failure，要求 QZ stable/unstable 均为 $K$ 且无 `indet`/`neutral`，并禁止新 bracket 跨过 cache 中已知 final-invalid 点；但本次 57 条 history records 全部有效。
   - 当前后果：这些分支未参与 winner 产生，不影响 `run-01` 的 argmin；未来出现 invalid 点时仍有低影响的未实跑路径风险。
   - 不确定性：未观察到实际异常时的 CSV reason 和 bracket stop 组合。
   - 最便宜决定性检查：未来第一次自然 invalid 出现时核对一条 history reason 与 level trace；当前阶段不值得为了制造失败而重跑正式扫描。

### E. Implementation audit

- 模型与组装：`LOCAL_cellsub` 仍构造半径 $0.2$ 的圆；只有 `LOCAL_center` 使用 `flag_geom='ellipse'` 和 $[0.25,0.16]$。两者均使用 `sqrt(epsrel)*k` 且 `epsrel=17`。中心四块与第 3 节设计逐项一致，空中心代数回归 defect 为零。
- 复用：lead pencil block 顺序、QZ 主体、DtN 法向和转置线性求解均保留；`LOCAL_dtn` 没有 `pinv`。公共函数、main 示例和 I1--I6 未修改。
- 权重与指标：`Aphys=rowwt.*Adef.*colwt.'` 沿用 main 权重，没有 seed/Frobenius 整体归一化。`LOCAL_point` 一次构造两个矩阵后返回四个标量。
- 扫描：final pilot 先进入同一个 final cache；筛选和 final 分数没有混排；边界 winner 直接停止，不访问越界索引；下一 bracket 同时检查本层相邻有效性和 cache 中全部已知 final-invalid 点。`level_trace` 保存每层节点、有效性、cache hit、blocked $k$ 和停止原因。
- 真实来源：独立从 CSV 取得 6 个 unique final 有效点，按 `aphys_ratio` 排序的首项为 $k=1.45$；winner repeat 的 $k$ 和四指标逐项相同。`out` 七个字段均为标量。
- 内存适配：I7-local kernel 只把 target 分成至多 512 点的块，每个 target 仍按公共公式和原 source 顺序求和。预运行对照解析到公共和 I7-local 两个明确路径，`pot`、`grad`、`hess` 相对误差均为零。正式 run 的 105 个资源样本给出 peak process-tree RSS $870{,}367{,}232$ bytes。
- 资源与复现：命令、MATLAB transcript、history、scan/out MAT、摘要、两秒资源采样和 monitor status 均在同一 `run-01`。monitor wall time $217$ s、exit code 0、termination 为正常 process exit。

### F. What survived

- `construct_S` 的端口约定足以直接给出中心匹配。令 $G=\operatorname{diag}(\gamma)$，审查独立重建得到

  $$
  A_{\mathrm{def}}=
  \begin{bmatrix}
  (\mathrm{i}G-\Lambda_-)R_L-(\mathrm{i}G+\Lambda_-)&(\mathrm{i}G-\Lambda_-)T_{RL}\\
  (\mathrm{i}G-\Lambda_+)T_{LR}&(\mathrm{i}G-\Lambda_+)R_R-(\mathrm{i}G+\Lambda_+)
  \end{bmatrix}.
  $$

  空中心 $R_L=R_R=0$、$T_{RL}=T_{LR}=E$ 精确退化为 main `betagmode.m`；实现和回归均满足。
- 原物理行列权重仍有明确依据：列未知量仍是同一 Rayleigh 入射振幅，两组行仍是同一 Fourier 基下的墙上法向匹配残差。
- $0.25\times0.16$ 椭圆和半径 $0.2$ 圆严格等面积，且材料未改变；本轮确实只扰动中心形状。
- target 分块是必要且经对照的内存调度，没有改变 BIE、散射、QZ 或 DtN 数值算法。
- 结果即使浅且位于边界仍满足预先声明的成功条件；负结果没有被隐藏或通过改材料、改判据迎合。

### G. Minimal resolution

I7.1 不需要代码修复或追加计算即可接受。项目 README 已把 kernel/RSS 门记为 `closed for run-01`，并保留 I7-Q1 的解释限制。下一正常 gate 是按已规划的 I7.2 对当前候选作修订后的 $H_{\mathrm{sym}}$ sign count、空间离散稳定性和同模态比较；这些工作不应回写为 I7.1 已发现特征值。只有未来目标明确要求 interior dip 时，才先扩展 projected-gap 扫描范围并重做同一 final-config 确认。

### H. Open-problem handoff

唯一 goal-relevant handoff 是 [[research/projects/eig-apost/implementation/i7/README|I7 README]]
问题表中的 `I7-Q1`：stage 为 I7.1 到 I7.2，类别为 `IMPORTANT CAVEAT`，不阻止接受
I7.1 但阻止 eigenvalue claim，最低下一检查和 `open` 状态均以该唯一问题表为准。kernel
等价和资源门已经由 `run-01` 关闭，不再复制为 unresolved item。
