# I9.5b fem-dtn-v1：三胞元模板＋离散 DtN 的 FEM candidate

本实验实施 `research/projects/eig-apost/implementation/i9/design-9-5b.md`。最初按 D1 实现（run-01 停在网格阶段），现按 D2 原位修订并完成正式运行 run-02（见下文“D2 修订与正式结果 run-02”）。

- **构造**：中心单胞元经左右无限周期 lead 的完整离散稳定子空间 DtN 闭合。中心墙 Schur 的有符号特征分支在 E.2 局部窗内求根。
- **配置链**：coarse（24/160，Q10）→ fine-q10（48/320）→ fine-q12，条件触发 fine-q16。
- **范围**：不计算新谱距离。BIE 参考值只在求解结束后的 Python 汇总层出现，MATLAB 求解入口不接触它。

## 文件

| 文件 | 作用 |
|---|---|
| `fem_dtn_i95b_config.m` | 冻结参数。模型、$k_0=1.558439927483915$（E.2，显式标量）、总窗 $k_0\pm0.01$、四个配置、网格修补规则（含 D2 翻边限额）、细层独立入口规则、逐频资格门、求根合同和资源限。模式为 `formal`、`smoke`（s=6/12，n=40/80）、`meshcheck`、`smoke-entry`（D2 入口代码路径探针） |
| `fem_dtn_i95b.m` | MATLAB 入口，详见下节 |
| `run_dtn.py` | 启动器，详见下节 |
| `summarize_dtn.py` | 求解后汇总。BIE 差、E.2 并列比较（E.2 计时为常数引用）、改善/未分辨标签和完整时间账，写 `summary.json` |

`fem_dtn_i95b.m` 的内容：

- **网格**：联合三胞元网格，按设计 §5 做确定性修补。
- **装配**：提取三模板，只消去上下准周期从属节点（`Qqp`）。
- **lead DtN**：内部 LU 加 32 列分块多右端求解；复 QZ 排序稳定子空间，给出 `Pout`、$D$。
- **中心**：Cholesky 凝聚得 $F$，再求 $H=R^{-*}FR^{-1}$ 的实分支。
- **求根**：分支选择与追踪、固定半宽夹逼、Brent。
- **交付**：恢复与交付检查、展示胞元和图表；`iterations.csv` 逐频即时写入。

`run_dtn.py` 的内容：

- 进程树 RSS 每秒采样，2.7 GB 预警，3e9 字节硬停。
- 30 分钟软限处读取 MATLAB 的 `progress.json`，按设计 §7.2 的客观证据决定是否给一次至多 10 分钟宽限；否则以 `RESOURCE_STOP` 停止。40 分钟硬停。
- 外部 MATLAB 检查与 killpg 清理。
- 汇总在同一墙钟内运行。

MATLAB 只接收输出路径与模式，不读文档、Git 或历史输出。

## 运行

从工作树根目录：

```sh
python3 test/i9/fem-dtn-v1/run_dtn.py --mode formal \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --output test/i9/fem-dtn-v1/output/attempt-1/run-02
```

`--mode smoke` 为操作性探针；`--mode meshcheck` 只生成冻结的 formal 网格层并列出坏元，不做任何求解。`--mode smoke-entry` 仅用于检查 D2 细层独立入口的代码路径：coarse 用正式 s24/n160 网格并把翻边检查次数设为 0，人为得到 `LOCAL_REPAIR_LIMIT`；fine 用 smoke 尺寸。它不产生科学结果。

## 运行记录（attempt-1）

均为 MATLAB R2023b（MACA64），11 线程，串行，启动前无其他 MATLAB 进程。

| 目录 | 模式 | 结果 | 墙钟 s | 采样峰值 RSS bytes |
|---|---|---|---:|---:|
| `smoke-01` | smoke | 操作性失败：`fprintf` 不接受稀疏右端范数（`-AIW(:,J)` 未转 full）。已修复，见 `run.log` | 17.70 | 899,792,896 |
| `smoke-02` | smoke | 全链跑通，状态 `CANDIDATE_DELIVERED`（仅探针） | 17.86 | 1,212,989,440 |
| `smoke-03` | smoke | 改动后复跑：init 行补记所选分支、相关图改 log 尺度 | 20.86 | 1,223,147,520 |
| **`run-01`** | **formal** | **`GEOMETRY_FAILED`（coarse）**，后续链按依赖未运行 | **15.64** | **1,113,456,640** |
| `diag-01-meshcheck` | meshcheck | 网格诊断：coarse 失败，fine 通过 | 15.70 | 1,007,321,088 |

全部 attempt-1 进程合计墙钟 87.8 s。各次均无软限/宽限触发、无 RSS 预警、无残留子进程。

`meshcheck` 模式是在 run-01 之后加入的：只在入口加了一个提前返回分支，配置中加了模式名，`formal` 路径未改动。因此 run-01 的 `provenance.json` 记录的是加入前的源码身份。

### smoke 检查（仅证明实现可执行，不是结果）

在 s=6/12 的探针网格上，逐频资格量均远优于门：

| 资格量 | 观测值 |
|---|---|
| 胞元后向残差 | ~3e-17 |
| condest | ~1e4 |
| 单位圆距离 | ≥0.45 |
| `rcond(Z0)` | ~0.04–0.09 |
| Riccati | ~4e-16 |
| $D$ 的 Hermitian 缺陷 | ~6e-17 |
| 平移自洽 | ~2e-17 |
| $H$ 的 Hermitian 缺陷 | ~1e-16 |

目标分支与邻近特征值的间距约 4.77。根的结果：

- 夹逼宽度 1.25e-11，$|\lambda|\le10^{-12}$。
- 未凝聚中心残差 2e-14 至 1.4e-13。
- 交付门全部通过：恢复约 1e-14、载荷平衡 ≤1.7e-13、值连续 ≤6e-17。
- 同模相关 ≥0.99999999。
- 稳定乘子谱半径约 0.377/0.384。

探针频率不作科学比较。

## 正式结果 run-01：`GEOMETRY_FAILED`

coarse 层（s=24，interface_segments=160）在修补第 0 轮即失败。全网格唯一的坏元：

- **位置**：中心胞元，背景材料 $\rho=1$。
- **Jacobian**：$\det J_{\min}=3.76\times10^{-8}>0$，$\det J_{\max}/\det J_{\min}=569.47>20$。这与 E.2 网格记录的比值 569.5 薄片元一致，说明本实验复制的网格规则重现了 E.2 网格。
- **顶点**：三个顶点**全部是界面曲线节点**。它们是中心星形 $\theta=\pi-\delta,\ \pi,\ \pi+\delta$（$\delta=2\pi/160$）处的相邻三点，坐标 $(-0.24097,\mp0.00554)$ 与 $(-0.24,0)$，位于五瓣星 $\cos5\theta=-1$ 的内凹谷底。两条边是弯曲的共享界面边。
- **无可删点**：设计 §5 第 3 步只允许删除自由背景点，而该元没有，按合同直接标 `GEOMETRY_FAILED`。
- **按更宽读法也会失败**：若把“坏元相邻”理解为相邻元的背景点，同样会失败。删除点不能消去外接圆已空的 Delaunay 三角形，三轮后结果相同。

按设计 §4.2，fine-q10 以 coarse 合格根为初值。coarse 无合格根，fine-q10、fine-q12、fine-q16 均为 `NOT_RUN`。因此：

- **没有交付 candidate**，没有 $\delta_h,\delta_Q$，也没有 BIE 差。`summary.json` 只记录 E.2 自身的 BIE 差 2.03e-6。
- 未作任何 DtN/QZ 评价，`iterations.csv` 只有表头。
- 未放宽 det 比门，未移动或删除曲线/ring 点，未改网格，也未改用 $k_0$ 直接启动细层。

run-01 内部互斥计时：

| 项 | 秒 |
|---|---:|
| 网格/修补 | 0.306 |
| 最终状态 | 0.005 |
| 保存 | 0.088 |
| 图表 | 3.213 |
| MATLAB 函数合计 | 3.669 |
| 启动/退出 | 11.95 |
| 汇总 | 0.001 |
| 全墙钟 | 15.64 |

`figures/` 只有空的漂移/相关图和成本图；没有场图，因为没有 candidate。

### 网格诊断 diag-01-meshcheck（非正式运行，无求解）

| 层 | 状态 | 坏元 | 最大 det 比 | 三角形数 | P2 节点数 |
|---|---|---:|---:|---:|---:|
| s24-n160（coarse） | `GEOMETRY_FAILED` | 1（三顶点均为界面点） | 569.47 | 6102 | 12397 |
| s48-n320（fine，Q10/Q12/Q16 共用） | PASS | 0 | 1.163 | 见 `mesh-check.json` | 见 `mesh-check.json` |

fine 网格本身满足修补门，但按冻结的初值依赖它不会单独运行。

## 交回研究助手决定的事项（未自行处理）

1. （D1 时记录；D2 已按设计处理，见下节。）coarse 层失败元由三个相邻界面节点构成，设计的背景点修补对此无效。是否允许或如何修改 coarse 层规则或依赖链，属于实质设计调整。可能的方向包括：曲线节点相位、谷底处理、coarse 失败时 fine 链的初值来源等。本实验未做任何此类尝试。
2. `DISCRETIZATION_SENSITIVITY_UNRESOLVED` 在设计中没有给出 $\delta_h$ 的冻结判据，本实现不自动赋该状态。若需要，请在设计中给出触发条件。
3. 实现中的几处解释，均写在源码注释与配置中：
   - **QZ 退化门**：$|\alpha|+|\gamma|\le 100\cdot 2n\cdot\varepsilon\cdot(\|\mathcal A\|_F+\|\mathcal B\|_F)$。
   - **根门**：$|\lambda(H)|\le10^{-10}$ 取 $H$ 特征值的绝对值，另记 $|\lambda|/\max(1,\|H\|_2)$。
   - **夹逼顺序**：每个半宽先左后右，取首个异号区间。
   - **交付检查失败的状态映射**：恢复、连续、QP、载荷门失败映射为 `CELL_OR_DTN_EXCEPTION`；未凝聚残差失败映射为 `ROOT_NOT_CONVERGED`。

## D2 修订与正式结果 run-02

### 实现改动（仅本目录）

D2 改动位于网格修补和依赖/汇总层。DtN/QZ、中心凝聚、分支选择、求根及交付检查的数学路径未改，门限、物理几何、材料、积分阶和求根窗也未改。

- **网格（`LOCAL_mesh`）**：原 `LOCAL_triangulate` 拆为两步。
  - 约束 Delaunay 加质心材料/胞元标签。
  - 无 Delaunay 的重建 `LOCAL_mesh_build`：边表、共享 P2 编号、全部结构检查、全元行列式极值。
- **D2 局部翻边**：旧删除规则（最多 3 轮）之后若仍有坏元，进入第 4 步，即 `LOCAL_flip_repair`、`LOCAL_flip_trial`、`LOCAL_segment_curve_clear`。
  - **候选**：只处理含界面边的坏元，候选为其非约束内边，并要求：
    - 两元同材料、同胞元，patch 四顶点不在墙或上下边界；
    - 四边形严格凸（转角 $>10^{-12}\ell^2$）；
    - 新边 $bd$ 不是已有边；
    - 实际 P2 外边与 $bd$ 的交点用二次方程 $f(t)=t(c_1+c_2t)$ 解出，切触、共线或落在容差 $10^{-9}$ 内都按“不可判”拒绝；
    - 两新曲边元满足 $\det J_{\min}>0$ 且比值 $\le 20$。
  - **提交**：接受后整网用 `LOCAL_mesh_build` 重建（不再调用 Delaunay），要求结构检查通过、无新坏元，否则回退。
  - **限额**：32 次候选检查、16 次成功翻边、30 秒。计时从首次发现坏元开始，涵盖之后的删除重剖分、翻边和重建复查；每次操作前做预测检查。
  - **记录**：每次试验的元/边编号、顶点、新旧 P2 节点、前后行列式、各门布尔量、拒绝原因和耗时，均存入 `evidence.mat` 的 `meshes(:).geometry.flip`。
- **结构化失败**：
  - `geometry.failure_kind` 取 `NONE`、`JACOBIAN_QUALITY_UNRESOLVED`、`LOCAL_REPAIR_LIMIT` 或 `STRUCTURAL_CHECK_FAILED`。另有 `mesh_structural_checks_pass` 和 `structural_checks_completed`。结构检查失败优先记为 `STRUCTURAL_CHECK_FAILED`，不能用于例外入口。
  - 为满足设计要求的“覆盖检查”，在 D1 检查之外新增三项：`edge_incidence`（每边 1–2 个邻元，单邻元边只在外框上）、`positive_orientation`、`cell_coverage`（各胞元仿射面积和与 1 的差 $<10^{-10}$）。
- **细层独立入口（`LOCAL_should_run` 和 `LOCAL_fine_entry`）**：只看结构化记录，条件为：
  - coarse 状态为 `GEOMETRY_FAILED`，`failure_kind` 在白名单内，`mesh_structural_checks_pass=true`；
  - 已进入翻边阶段，装配和频点评价都未开始；
  - 已用时间加剩余预估 620 s（设计 §7.2 中 fine-q10/q12/q16 与收尾各行上限之和）不超过软限。

  满足时 fine-q10 从 $k_0$ 独立启动，记 `initialization_source=E2_AFTER_COARSE_GEOMETRY_FAILURE`。fine-q12 和 fine-q16 仍依赖前链。
- **有效必要链（`LOCAL_final`）**：
  - 正常情况为 `[coarse, fine-q10, fine-q12]`；例外入口时为 `[fine-q10, fine-q12]`；触发 Q16 时追加 `fine-q16`。
  - `result.json` 记录 `effective_required_chains`、`coarse_control_unavailable`、`coarse_fine_comparison_status`、`delta_h_status`、`coarse_failure`、`fine_entry` 和 `two_level_sensitivity_available`。
  - 缺粗层时 $\delta_h$ 和粗细相关都写 `null`，并标 `UNAVAILABLE_COARSE_GEOMETRY`。`progress.json` 同时写剩余必要链、有效必要链和缺粗标志。
- **图表与汇总**：
  - 图中不合格链或不可用的相关对不画点或柱，只在刻度标签上注明状态。
  - `candidates.csv` 增加 `initialization_source` 和 `geometry_failure_kind` 两列。
  - `summarize_dtn.py` 在缺粗时于首要位置写 `headline_disclosure`。

### D2 运行记录（attempt-1，接续上表）

均为 MATLAB R2023b（MACA64），11 线程，串行，启动前无其他 MATLAB 进程，无软限/宽限触发，无 RSS 预警，无残留子进程。

| 目录 | 模式 | 结果 | 墙钟 s | 采样峰值 RSS bytes |
|---|---|---|---:|---:|
| `smoke-04-entry` | smoke-entry | 入口路径跑通。发现图表缺陷：`max(1-NaN,eps)` 把不可用相关画成 eps 柱，已修复 | 21.90 | 1,211,105,280 |
| `smoke-05-entry` | smoke-entry | 修复后复跑。coarse 记 `LOCAL_REPAIR_LIMIT`，入口放行，`UNAVAILABLE_COARSE_GEOMETRY` 正确记录，无 0 值图元 | 18.85 | 1,135,132,672 |
| `smoke-06` | smoke | 正常粗→细路径回归 | 17.75 | 1,169,620,992 |
| **`run-02`** | **formal** | **`CANDIDATE_DELIVERED`** | **30.32** | **1,582,481,408** |

另有一次实现调试用的 meshcheck，直接用 MATLAB 运行（约 16 s），输出在本目录之外的临时目录，未保留，也不是正式记录。它的网格修补结论与 run-02 现场记录一致。本节四次运行合计墙钟 88.8 s；attempt-1 全部保留运行累计 176.6 s（不含该调试运行）。

### run-02 网格

| 层 | 状态 | 修补 | 最大 det 比 | 三角形 | P2 节点 |
|---|---|---|---:|---:|---:|
| s24-n160（coarse） | PASS，`failure_kind=NONE` | 删除：1 个坏元，无可删背景点，进入翻边。翻边：检查 1 次，接受 1 次 | 1.345 | 6102 | 12397 |
| s48-n320（fine） | PASS，原始门直接通过，未修补 | — | 1.163 | 19132 | 38649 |

被翻的是 coarse 坏元 3792（三个中心星形谷底界面节点），邻元 938 的另一顶点为外 ring 点 $(-0.276,0)$。

- 旧弦被新边取代：旧坏元 $\det J_{\min}=3.757\times10^{-8}$，比值 569.47。两新元比值都是 1.0508，$\det J_{\min}=1.971\times10^{-4}$。
- 四条外边的曲线交点检查：两条界面边的第二根 $t=-83.3$，在 $[0,1]$ 外；两条直边无第二根。
- 修补（删除轮加翻边加重建复查）共 0.334 s。翻边后结构检查全部通过。节点、单元和 P2 自由度总数不变。

因 coarse 合格，**本次正式运行未使用细层独立入口**。该入口只经 smoke-entry 探针验证过代码路径。

### run-02 结果

| 配置 | 状态 | $k$ | 夹逼宽度 | $\lvert\lambda\rvert$ | 未凝聚中心残差 | 频点数 | 初值来源 | BIE 差 $k-k_{\mathrm{BIE}}$ |
|---|---|---:|---:|---:|---:|---:|---|---:|
| coarse（s24/n160，Q10） | ROOT_QUALIFIED | 1.5584398513990294 | 1.25e-11 | 8.6e-11 | 9.7e-12 | 4 | E2_K0 | +1.957e-6 |
| fine-q10（s48/n320） | ROOT_QUALIFIED | 1.558438079544167 | 1.25e-11 | 3.3e-12 | 7.9e-13 | 5 | coarse 根 | +1.854e-7 |
| **fine-q12** | **ROOT_QUALIFIED，最终 candidate** | **1.558438079544167** | 1.25e-11 | 6.7e-12 | 1.0e-12 | 3 | fine-q10 根 | **+1.854e-7** |
| fine-q16 | NOT_RUN（未触发） | — | — | — | — | 0 | — | — |

- **candidate**：$k=1.558438079544167$，$\mu=k^2$。
- **最终 BIE 绝对差**：$1.854\times10^{-7}$，由汇总层在全部求解结束后计算。E.2 的同一差为 $2.033\times10^{-6}$，下降 $1.848\times10^{-6}$，远大于分辨尺度 $\max(\delta_Q,\text{夹逼宽度})=1.25\times10^{-11}$。按设计 §7.1 口径，标“数值参考差改善”。这只是数值参考比较，不是认证误差，也不等于真实精度。
- **离散敏感性**：
  - $\delta_h=\lvert k_{\mathrm{fine},10}-k_{\mathrm{coarse},10}\rvert=1.772\times10^{-6}$，只是两点离散敏感性，不据此估收敛阶或真误差。
  - 机器输出 $\delta_Q=0$。原因是 Q12 链在 Q10 根处初值 $\lambda=-6.7\times10^{-12}$，已满足门，Brent 保留了该点。因此 Q10 与 Q12 根之差只能分辨到夹逼宽度 $1.25\times10^{-11}$ 的量级，不是精确相等。$\delta_Q<10^{-8}$，Q16 未触发。此现象是 D1 求根合同的既有行为，smoke 中同样出现，D2 未改。
- **同模证据**：两墙 201 点合并迹的归一复相关为 coarse/fine-q10 $1-2.4\times10^{-13}$，fine-q10/fine-q12 $1-9\times10^{-16}$，均 $\ge0.99$。`coarse_fine_comparison_status=PASS`。初链分支间距 4.772，后续链转移相关唯一达到 0.90。
- **逐频与交付资格**：
  - 单位圆距离 $\ge0.445$，`rcond(Z0)` $\ge0.0114$，Riccati $\le7\times10^{-16}$。
  - 三个合格配置的 11 项交付门（中心残差/恢复/QP，左右恢复/连续/QP/载荷平衡）全部通过。
- 本轮不声称与 E.2 已证明连续同模或唯一，不计算谱距离。

### run-02 成本（完整一次科学运行，共用一个预算）

| 项 | 秒 |
|---|---:|
| 网格/修补（两层，含翻边和复查） | 0.792 |
| 装配：K/M、约束、墙质量（coarse、fine-q10、fine-q12 重装配） | 1.483 |
| lead 消元 | 5.247 |
| QZ/DtN | 2.011 |
| 中心消元/小特征问题 | 2.411 |
| 求根控制其余 | 0.270 |
| 恢复/交付检查/最终状态 | 0.172 |
| 保存 | 1.172 |
| 图表 | 4.369 |
| MATLAB 未归属 | 0.063 |
| **MATLAB 函数合计** | **17.99** |
| MATLAB 启动/退出 | 12.30 |
| 汇总（含 BIE 差） | 0.002 |
| **完整墙钟（启动器测得）** | **30.32** |

- 各配置自身耗时（预计算/求根/恢复，秒）：coarse 0.730/1.076/0.334，fine-q10 0.945/4.242/0.856，fine-q12 0.600/2.596/1.001。网格前置成本在总账中只计一次。
- 冷启动到最终 candidate 为 24.76 s：启动/退出上界加上 MATLAB 内到 fine-q12 交付检查完成的时间，不含图表和保存。
- 采样峰值 RSS 为 1,582,481,408 bytes（每秒采样 29 次）。这是采样峰值，不证明瞬时峰值。
- 事前估计为 2–14 分钟、1.3–2.4 GB，实测远低于此。
- E.2 candidate 算法 2.65 s（含保存 4.86 s）对应另一合同：17 胞元有限 Dirichlet 条带，h=1/24，Q8，一次 eigs，无 DtN，无夹逼求根。两者只能并列，不构成同精度加速比。515 s 属于另一任务（谱距离）。

### 实现解释（供审查，未改设计）

1. 30 秒修补计时从首次发现坏元开始，不含初始网格生成。初始网格生成时间另计入网格账。
2. 细层入口所需的“剩余预算足够”判据取设计 §7.2 各行上限之和 620 s。
3. 新增的三项结构检查只会收紧几何门，不放宽任何门。
