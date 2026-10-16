# I8.3：新星形候选冻结场数值估计独立审查

## A. 审查框架

审查对象是 `estimate_i8(k0,ntot)`、基线 run-01、独立矩阵审计 run-02，以及经主代理授权的
`ntot=384` 单点敏感性 run-03。当前阶段是有限离散的数值案例研究：在
$k_0=1.7562818500073463$ 上冻结一个 physical-density 场，完整评价材料界面、人工墙、传播尾项和
局部质量，再形成普通 double 的 $R_{\rm num}$。成功标准是同一冻结场的两层非原生网格评价、完整分项、
正分母、独立原始矩阵重组和资源合规；不要求可靠上界、连续谱包含、位置重算或 inertia 重算。

核查材料包括 [[research/projects/eig-apost/implementation/i8/design-8-3a|设计]]、
`test/i8/estimate-v1/estimate_i8.m`、独立 `audit_i8.m`、两次 fresh field 的 `scientific.mat`、
两份 `result.json`、两份原始分项、公共函数解析路径、源码快照和资源日志。旧 I8 flow 与 I7.4
只用于核对约定，没有作为本轮数值输入。

## B. 判定

**PASS WITH CONDITIONS（高置信度）**。没有未解决程序 blocker。基线物理链、两层评价、完整分项、
正分母和独立原始矩阵审计均通过，故规定基线上的 `UNCERTIFIED_RNUM` 可以交付。条件是：一次
`ntot=384` 同点敏感性使 $R_{\rm num}$ 降低约 $434$ 倍，说明该谱距离数值估计尚未建立空间离散稳定性；
同时几何、求积、MFS evaluator 和观测尾项均无单侧包围。因此主结果只能称配置特定的数值估计，
不能称可靠谱距离上界或已收敛的连续量。

## C. 最强挑战

最可能推翻过强解释的是冻结场对 `ntot` 的敏感性。基线的主导中心材料法向平方项为
$6.1557358492\times10^{-14}$；`ntot=384` 时变为
$3.2684357107\times10^{-19}$，下降约 $1.883\times10^5$ 倍。相应
$\varepsilon_{\rm num}$ 从 $2.4810755428\times10^{-7}$ 降到
$5.7170281121\times10^{-10}$，$R_{\rm num}$ 从
$1.0909099846\times10^{-4}$ 降到 $2.5136892890\times10^{-7}$。这不是坐标或漏项错误：两次独立
矩阵审计均通过，而质量值几乎不变。它直接限制的是“空间离散稳定的物理估计”这一更强主张；
不否定本轮明确限定的 baseline 数值评价。

## D. 审查发现

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

## E. 实现与数值审计

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

## F. 经受核查的结果

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

## G. 最小闭合与下一步

本阶段无需程序修复；应交付 baseline 数值和 `ntot=384` 敏感性，并把两者的角色写清。若未来需要把
$R_{\rm num}$ 解释为空间离散稳定的量，最小后续门是再加一个独立 `ntot` 点并保持同一 $k_0$、同一
后处理网格和同一分项审计，观察主导中心法向项是否进入可辨平台；这不是 I8.3 当前完成条件。

## H. 问题移交

本审查不建立第二个问题表。请在
[[research/projects/eig-apost/implementation/i8/README|项目问题表]] 中把 I8-Q6 更新为“新候选 I8.3
已执行，PASS WITH CONDITIONS”，继续由 I8-Q2 承载非认证限制，并记录本轮 `ntot` 敏感性为后续
空间离散稳定性门。它不阻断 I8.3 数值交付。
