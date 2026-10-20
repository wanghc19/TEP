# I8.3：新星形候选冻结场数值估计独立审查

## 2026-10-16 center-512 / lead-256 续轮审查（当前）

### A. 审查框架

本次审查的精确对象是固定 $k_0=1.7562818500073463$、center 512 节点、lead 256 节点的
fresh hybrid field，以及它在 512/768 节点评价网格上的完整普通 double $R_{\rm num}$。成功标准是：
center/lead 节点必须实际分流；density scaling、194 阶 matching、传播坐标、材料/墙/40-cell 前缀与尾项、
同场质量和最终标量均须从新保存矩阵独立重组；768 节点是主结果，512 节点中心材料项只作 native
诊断。该阶段是数值案例研究，不要求可靠上界或连续离散收敛。

核查材料为当前 `estimate_i8.m`、本审查者负责的 `audit_i8.m`、run-05 的 source/audit/monitor
快照、`scientific.mat`、`result.json`、`audit2.json`、分项与资源日志。run-04 仅是 launcher 操作失败。
历史结果继续由对应运行时保存的旧 schema、源码与审计快照解释；当前独立审计只核新 schema，
不声称兼容读取旧保存结构。

### B. 判定

**PASS WITH CONDITIONS（高置信度）**。没有未解决程序 blocker。实际 center/lead BIE 阶数、密度
坐标、matching 阶数、native 标志和完整分项均通过独立新矩阵审计，768 主层得到有限正分母与
`UNCERTIFIED_RNUM`。条件是：512 层的中心 action 与原配点重合，且 512--768 的
$R_{\rm num}$ 相对差约 $0.43045$；因此本轮只交付配置特定的 768 节点数值，不能称后处理网格稳定、
空间离散收敛或可靠谱距离上界。

### C. 最强挑战

最强挑战不是坐标或漏项，而是唯一较粗层对中心材料项并不独立。512 节点中心 action 是原生配点
诊断，其普通法向平方为 $2.45816\times10^{-30}$；768 非原生主层为
$2.03804\times10^{-24}$。于是 $R_{\rm num}$ 从
$4.01655\times10^{-10}$ 变为 $7.05216\times10^{-10}$。该差异足以推翻“同场两层已经稳定”的
解释，但不使用户明确要求的 768 有限数值不可解释。

### D. 审查发现

1. **IMPORTANT CAVEAT — 本续轮没有后处理网格收敛证据。** center-512 层是 native/algebraic
   diagnostic；只有 768 层是 center 的非原生评价。两层 $R_{\rm num}$ 以较大者归一的相对差为
   $0.4304513$，中心普通法向项相差约六个数量级。最便宜的后续判别是保持同一冻结场再加一个
   $N>768$ 的非原生评价；这不是当前数值交付的完成条件。

2. **IMPORTANT CAVEAT — center-only 轴仍只有两个 fresh fields。** 相对历史 `(256,256)`，本次
   `(512,256)` 只改变 center 节点数，$R_{\rm num}$ 约缩小 $1.55\times10^5$ 倍；两次 $q$ 与密度
   各自重算、各自归一化。这是强敏感性证据，不是单调收敛。历史 `(384,384)` 同时改变 center 和
   lead，不能混入该轴。

3. **IMPORTANT CAVEAT — 结果仍未认证。** sampled geometry、MFS evaluator、边界/盘求积和观测
   几何尾项都没有单侧误差包围。正分母只支持有限普通数值公式；不支持连续全谱距离上界、特征值
   存在性或误差界。

4. **MINOR CAVEAT — run-04 是保留的启动失败。** 多行 `-batch` 实参未执行，MATLAB 在
   $16.574301$ 秒后 exit 0，但没有生成科学结果。run-05 用同一方法的单行实参完整重跑。生产入口
   唯一 Code Analyzer 提示是 `LOCAL_wall_level` 继承的未使用 `q` 形参；独立审计无提示。

### E. 实现与独立矩阵审计

- 新入口保留两参数旧行为：省略 `lead_ntot` 时令其等于 `center_ntot`；本次显式调用
  `estimate_i8(k0,512,256)`。lead 与 center 分别把 256/512 传入原构造链，不修改公共包。
- fail-fast 节点账本实测 center geometry 为 $6\times512$，$H_{L/R}$ 为 $1024\times97$，
  $A_{QP}$ 为 $1024\times1024$，$B_{L/R}$ 为 $1024\times97$，density 为 $1024\times1$；lead
  对应 $6\times256$、$512\times97$、$512\times512$、$512\times97$，传播 density maps 为
  $512\times97$。$T,N_0,L,A_{\rm def},A_{\rm phys}$ 均为 $194\times194$。
- 修正后的公共 density coordinate 链只执行一次。center/lead scaled solve residual 分别为
  $1.18431\times10^{-15}$ 与 $4.29897\times10^{-15}$。native flags 实测为 center
  `[true,false]`、lead `[false,false]`。
- 独立审计从保存的散射/QZ块重新组装 $T,N_0,L,A_{\rm def},A_{\rm phys}$ 与最小 right singular
  subspace，再重建 $P_\pm,G_\pm,c_\pm$；随后按物理 density scaling 重做两层 raw material
  actions、所有 center--lead/internal walls、左右各 40 个 cell、八个尾项、两套质量和最终标量。
  它核的是实际新矩阵和样本，不是只比较汇总表，也不是对整个 BIE 连续算法的独立实现。
- 审计 `hybrid_contract=true`，覆盖 512/256 节点、194 阶 matching、160 个按层计的 lead-cell
  贡献、160 个内部墙贡献、八个尾项和两套质量网格。最大缺陷
  $4.2989660484\times10^{-15}$；独立最终标量与保存值的最大绝对差
  $1.18061\times10^{-17}$，全部通过 $10^{-10}$ 门。

### F. 经受核查的当前结果

本轮 center-512 / lead-256 组装的 matching 矩阵给出

$$
\sigma_{\min}(A_{\rm def})=8.886666410640615\times10^{-14},\qquad
\frac{\sigma_{\min}(A_{\rm def})}{\sigma_{\max}(A_{\rm def})}
=1.4708748121018025\times10^{-16},
$$

$$
\sigma_{\min}(A_{\rm phys})=4.389817763088999\times10^{-14},\qquad
\frac{\sigma_{\min}(A_{\rm phys})}{\sigma_{\max}(A_{\rm phys})}
=1.5371788289389097\times10^{-14}.
$$

主层完整分项的普通法向平方总量为 $2.5689056121842801\times10^{-24}$；其中 center material
约占 $79.33\%$，wall 约占 $20.66\%$。尾项比率均约 $0.091<1$，完整性门通过。最终

$$
\mu_{\rm num}=3.084525936665227,\quad
C_{\rm num}=8.273545666859006,\quad
\varepsilon_{\rm num}=1.6039135669302043\times10^{-12},
$$

$$
U_{\rm num}=0.11608305827964506,\quad
D_{\rm num}=0.11608305826637501,\quad
R_{\rm num}=7.052160861927364\times10^{-10}.
$$

512 native 层的 $R_{\rm num}=4.0165490283803493\times10^{-10}$ 只作诊断。正式入口耗时
$394.471511$ 秒；run-05 wall time 为 $415.277293$ 秒，任务 ledger 连同 run-04 为
$431.851594$ 秒。峰值进程树与 MATLAB union RSS 均为 $1{,}214{,}922{,}752$ bytes，exit 0，
没有外部 MATLAB 或资源超限。日志两条 JVM 启动提示不是数值/线性求解 warning。

### G. 最小闭合

本续轮无需程序修复，可以交付 768 主值、512 native 诊断及敏感性限制。若未来需要主张同场评价
稳定，最小门是在完全相同的 run-05 冻结场上增加一个更高的非原生边界评价网格；若要主张 center
空间离散收敛，还需至少一个保持 lead-256 的独立 center 阶数。两者都不是当前完成条件。

### H. 问题移交

本审查不建立第二个问题表。请在
[[research/projects/eig-apost/implementation/i8/README|项目问题表]] 的 I8-Q9/I8-Q10 中分别记录：
center-only 两点仍显示强 field sensitivity，且 512 native / 768 non-native 层差未进入平台。它们是
important caveats，不阻断本轮有限数值交付；非认证限制继续由 I8-Q2 承载。

## 2026-10-15 原审查（历史记录）

### A. 审查框架

审查对象是 `estimate_i8(k0,ntot)`、基线 run-01、独立矩阵审计 run-02，以及经主代理授权的
`ntot=384` 单点敏感性 run-03。当前阶段是有限离散的数值案例研究：在
$k_0=1.7562818500073463$ 上冻结一个 physical-density 场，完整评价材料界面、人工墙、传播尾项和
局部质量，再形成普通 double 的 $R_{\rm num}$。成功标准是同一冻结场的两层非原生网格评价、完整分项、
正分母、独立原始矩阵重组和资源合规；不要求可靠上界、连续谱包含、位置重算或 inertia 重算。

核查材料包括 [[research/projects/eig-apost/implementation/i8/design-8-3a|设计]]、
`test/i8/estimate-v1/estimate_i8.m`、独立 `audit_i8.m`、两次 fresh field 的 `scientific.mat`、
两份 `result.json`、两份原始分项、公共函数解析路径、源码快照和资源日志。旧 I8 flow 与 I7.4
只用于核对约定，没有作为本轮数值输入。

### B. 判定

**PASS WITH CONDITIONS（高置信度）**。没有未解决程序 blocker。基线物理链、两层评价、完整分项、
正分母和独立原始矩阵审计均通过，故规定基线上的 `UNCERTIFIED_RNUM` 可以交付。条件是：一次
`ntot=384` 同点敏感性使 $R_{\rm num}$ 降低约 $434$ 倍，说明该谱距离数值估计尚未建立空间离散稳定性；
同时几何、求积、MFS evaluator 和观测尾项均无单侧包围。因此主结果只能称配置特定的数值估计，
不能称可靠谱距离上界或已收敛的连续量。

### C. 最强挑战

最可能推翻过强解释的是冻结场对 `ntot` 的敏感性。基线的主导中心材料法向平方项为
$6.1557358492\times10^{-14}$；`ntot=384` 时变为
$3.2684357107\times10^{-19}$，下降约 $1.883\times10^5$ 倍。相应
$\varepsilon_{\rm num}$ 从 $2.4810755428\times10^{-7}$ 降到
$5.7170281121\times10^{-10}$，$R_{\rm num}$ 从
$1.0909099846\times10^{-4}$ 降到 $2.5136892890\times10^{-7}$。这不是坐标或漏项错误：两次独立
矩阵审计均通过，而质量值几乎不变。它直接限制的是“空间离散稳定的物理估计”这一更强主张；
不否定本轮明确限定的 baseline 数值评价。

### D. 审查发现

1. **IMPORTANT CAVEAT — $R_{\rm num}$ 尚无空间离散稳定性。** 上述 `ntot` 敏感性发生在完整 fresh
   field，而不是仅改变后处理网格。`ntot=384` 内部的 512/768 评价仍稳定，但只有一个加密点，不能据此
   声称单调收敛或选择较小值作为最终连续估计。设计已经规定 baseline 为主结果，故这不构成本阶段
   blocker。

2. **IMPORTANT CAVEAT — 数值估计不是可靠上界。** `Cnum` 来自 sampled nonconvex-collar 检查，
   raw material/wall evaluator、disk quadrature 和 $e_{40}/(1-r)$ 尾项没有区间或单侧余项。正分母只使
   普通数值公式有限，不能升级成连续算子全谱距离证书、特征值存在性或误差界。

3. **MINOR CAVEAT — 极小分项不能用相对变化概括。** 基线两层中 lead-normal 与 wall-normal 的相对
   变化约为 $16.6\%$ 与 $36.3\%$，但绝对平方量仅约 $10^{-28}$ 与 $10^{-25}$；总
   $\varepsilon_{\rm num}$ 由约 $6.16\times10^{-14}$ 的中心法向平方项主导。结果可称总量稳定，不能称
   每个微小分项都相对收敛。

4. **MINOR CAVEAT — 静态提示无数值后果。** 生产入口唯一 Code Analyzer 提示是
   `LOCAL_wall_level` 继承的未使用形参 `q`；独立审计无提示。该形参不参与公式，也不影响复现。

### E. 实现与数值审计

- 模型与基线严格为中心 `epsrel=2` 的等面积五瓣星形、两侧半径 $0.2$ 且 `epsrel=17` 的圆，
  $(n_{\rm tot},n_{\rm side},n_{\rm top},n_{\rm proxy},m_{\rm pw},M)=(256,160,160,80,32,48)$。
  星形六行统一乘 $\sqrt{0.04/0.0618}$；中心和 lead 均解析到仓库根公共函数，未出现局部 package shadow。
- $q$ 从 fresh $A_{\rm phys}$ 右奇异向量经 column weight 恢复、统一归一化和 phase anchor；中心密度
  是 $H_La^L+H_Rb^R$。公共 scaled solve 的中心/lead 残差分别为
  $1.05\times10^{-15}$ 和 $4.30\times10^{-15}$，实验没有重复密度缩放。
- 独立审计从保存的散射块重建 $T,N_0,L,A_{\rm def},A_{\rm phys}$ 和 $q$，再按
  $W^{-1}A_sW\eta+Bq$ 重做 center/lead raw actions；普通法向取第二 block 的负号。它另行重建
  $P_\pm,G_\pm,c_\pm$、左右各 40 个材料 cell、左右各 40 个内部墙配对、两条 center--lead 墙和
  从第 41 项开始的 material/wall 尾项，没有发现漏计或重计。
- 墙项使用保存的物理墙 value/$x$-derivative maps；质量使用同一个中心冻结场在
  $16\times32$ 与 shifted $32\times64$ disk 网格的实际样本。审计覆盖两层、160 个 lead-cell
  贡献、160 个内部墙贡献、8 个尾项和两套质量网格，最后独立重组 $C_{\rm num}$、
  $\varepsilon_{\rm num}$、$U_{\rm num}$、分母、$R_{\rm num}$ 及状态。
- 基线独立审计最大差异为 $4.2989660484\times10^{-15}$；`ntot=384` 审计最大差异为
  $4.2658611064\times10^{-15}$。两者均从实际新矩阵与样本重组并通过，不只是汇总表一致性检查。

### F. 经受核查的结果

基线 fine 层得到

$$
\mu_{\rm num}=3.0845259366652269,\quad
C_{\rm num}=8.2735456668590057,
$$

$$
\varepsilon_{\rm num}=2.48107554282511\times10^{-7},\quad
U_{\rm num}=0.11608305827964591,
$$

$$
D_{\rm num}=0.11608100555046526,
\qquad R_{\rm num}=1.0909099845639975\times10^{-4}.
$$

对应的**数值参考区间**是
$[3.0844168456667704,\ 3.0846350276636834]$。基线 coarse--fine 的
$\varepsilon_{\rm num}$、$U_{\rm num}$ 和 $R_{\rm num}$ 相对变化分别约为
$2.39\times10^{-11}$、$1.48\times10^{-10}$ 和 $1.72\times10^{-10}$；所有 tail ratio 约为
$0.091<1$，完整性与正分母门均通过。

授权的 `ntot=384` 敏感性结果为
$\varepsilon_{\rm num}=5.7170281120679014\times10^{-10}$、
$U_{\rm num}=0.11608305827964505$、
$R_{\rm num}=2.5136892889947825\times10^{-7}$。其两层 $R_{\rm num}$ 相对变化约
$5.14\times10^{-6}$，但它只揭示离散敏感性，不替换 baseline 主结果。

正式 baseline 入口耗时 $404.164903375$ 秒；run-01 wall time 为 $429.975669$ 秒。
含独立审计和 `ntot=384` 敏感性的累计监控时间为 $854.913248$ 秒，最高进程树及 MATLAB union RSS
均为 $1{,}542{,}520{,}832$ bytes。三次均 exit 0，无并发或资源超限；日志中的两条 JVM 启动提示
不是数值或线性求解 warning。

### G. 最小闭合与下一步

本阶段无需程序修复；应交付 baseline 数值和 `ntot=384` 敏感性，并把两者的角色写清。若未来需要把
$R_{\rm num}$ 解释为空间离散稳定的量，最小后续门是再加一个独立 `ntot` 点并保持同一 $k_0$、同一
后处理网格和同一分项审计，观察主导中心法向项是否进入可辨平台；这不是 I8.3 当前完成条件。

### H. 问题移交

本审查不建立第二个问题表。请在
[[research/projects/eig-apost/implementation/i8/README|项目问题表]] 中把 I8-Q6 更新为“新候选 I8.3
已执行，PASS WITH CONDITIONS”，继续由 I8-Q2 承载非认证限制，并记录本轮 `ntot` 敏感性为后续
空间离散稳定性门。它不阻断 I8.3 数值交付。
