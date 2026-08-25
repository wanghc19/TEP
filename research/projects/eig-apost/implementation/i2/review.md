# I2.1 同一离散对象单根隔离审查

## 审查范围与材料

本页审查
[[research/projects/eig-apost/implementation/i2/design|I2.1 frozen design]]、其 MATLAB
实现和完整运行证据是否共同回答了一个有限问题：在冻结 fine、$M=48$、$K=97$ 的
$194\times194$ 未平衡矩阵族 $A_{\mathrm{def}}^D(k)$ 上，I1 dip 周围指定圆盘内的
determinant zero 代数计数是否为一。

实验代码、输入、输出、日志、哈希和逐表证据统一从
[[test/i2/k-count/README|I2-K-COUNT-M1B-V1 experiment index]] 进入。本页不复制原始结果，
也不直接链接零散 CSV、MAT、源码或日志。冻结设计是 `m1-a1` 实际运行所用 source
manifest 的一部分，跑后保持不动；当前状态和审查结论由本页与 I2 README 维护。

本审查明确排除 root location、几何重数、导数资格化、连续 kernel--field 等价、连续
physical eigenvalue、跨层 matching 和后验 estimator。对这些对象的未完成工作不会被
count-one 结果追溯关闭。

## 三方职责与设计收敛

- **Researcher：**澄清 argument-principle 计数对象、代数重数语义和 zero--pole 分账。
  初始只检查规范化 Dirichlet factor 的方案不能排除 QZ chart normalization 与 DtN pole
  相消，因而在首次运行前主动撤回；随后与 Engineer 收敛到以 generalized-pencil Riesz
  projector 经验资格化 fixed-row section 的 Method 1B。
- **Engineer：**把 I1.4 的 fine evaluator 复制为 test-local、只读承接的实现，暴露真实
  inverse factors，并实现共同 LU/winding/Riesz core、流式证据、append-only 输出、资源
  门和 MATLAB `lsqminnorm` provenance。静态审计发现的对象、证据和 MATLAB 运行 blocker
  均在相应 freeze 前修复。
- **Skeptic：**独立审查设计、设计--实现一致性、每次运行后的原始证据和最终 report。
  Skeptic 不参与结果辩护；它先后阻止了 Dhat-only zero--pole 误读、缺少 manufactured
  oracle、首次实现漂移和 full-parent digest 自引用，并只对具体 freeze 分别授权一次
  smoke 或 full。

Researcher 与 Engineer 在实现前对理论对象、数据结构、证据保存、资源预算、失败条件和
验收逻辑明确 `AGREED`。Method 1B 的成功阈值不以期望 count one 定义；同一 production
core 的解析 oracle 能返回 $0$、$1$、$-1$、$2$ 和 unavailable。

## 方法为何能回答根数问题

直接绕行 reduced safe-DtN determinant 可能只得到“zeros 减 poles”。Method 1B 因而将
实际会被求逆的对象逐层分账：proxy reduced factor、BIE $A_{QP}$、original/reversed
generalized-pencil resolvents、fixed-section matrices $C_{\pm,16/32}$ 和规范化
Dirichlet factors $\widehat D_\pm$。只有这些对象在 32/64 嵌套 $k$ 网格上都得到可靠的
zero winding，Riesz/fixed-row section 检查也通过，才解释主 $A_{\mathrm{def}}^D$ winding。

Riesz projector 的作用不是替换 I1 evaluator，而是检查 pointwise QZ frames 是否确实代表
同一个可延拓子空间。若 exact selected range 维数保持 $K$，且固定 seed frame 经 projector
得到的 section matrix $C$ 在区域内不奇异，则 normalized section

$$
Y=PZ_0(HPZ_0)^{-1}
$$

不依赖 QZ frame 的任意 basis gauge。这样，$\widehat D_\pm$ 的 zero winding 才能用于
排除当前 safe-DtN realization 的对应 pole，而不会把 normalization winding 混进主计数。
本实验对该解析合同做的是双轴采样、嵌套 quadrature、QZ/range parity 和 Neumann guard
组成的经验资格化，不把它写成闭盘解析定理。

## 运行历史与失败保留

I2.1 共发生四次 MATLAB 命令调用，Octave 调用为零：

1. 首次受限 sandbox 启动同一 smoke 命令时很快以 exit 137 结束；错误发生在 MATLAB
   字体/崩溃报告权限层，runner 未启动且没有创建 output。该事件没有 durable runner
   artifact，但已保守计入正式预算，也没有被后续成功覆盖。
2. `smoke-a1` 在 MATLAB R2023b 中进入 runner，12 个 manufactured oracles 通过，随后在
   seed 以 `i21:ProxyGate` fail-close，耗时 $2.8188827916666668$ s。跑后审查证明 I2 手工
   移植的 projector-repeat 公式虽在精确算术下等价，却会在相同子空间处把舍入误差放大到
   $\sqrt{\epsilon}$ 量级；这与冻结门不相容。该失败保持原样，不作 root 证据。
3. Revision 1 只用稳定、等价的 principal-angle residual 恢复 I1 gate 语义，并补齐
   Proxy 子门、非空日志和未到 memory checkpoint 的 NaN 语义。新 tag `smoke-a2` 通过；
   它只认证实现/成本 readiness，没有形成 winding 或 root count。
4. Revision 2 只拆开 accepted-smoke artifact hash、smoke producer digest 与 current-full
   freeze，修复 provenance 自引用，不改科学对象、算法、网格或阈值。经独立跑前审查后，
   `m1-a1` full 唯一运行一次，MATLAB exit code 为零，无首失败。

准确命令、耗时、资源和每个 append-only tag 的证据入口均记录在实验索引。同一 tag 不得
重跑。启动失败、`smoke-a1`、`smoke-a2` 和 `m1-a1` 的不同语义不得合并或用最终成功
追溯改写。

## 最终数值审查

最终独立 post-run 审查复算了 source/freeze/parent identity、manufactured oracles、全部
对象和 phase closure、双轴 guards、嵌套 winding、失败表、资源账及 report/log 一致性。
非主 inverse/section factors 的两个网格计数均为零，主矩阵的两个网格计数均为一；所有
正式门通过且没有首失败。运行采用 MATLAB R2023b 的 public `lsqminnorm`，未观察到
`pinv`、fallback、silent rank truncation 或 chart/branch/rank/method switch。完整数值表、
结果 artifact hash、耗时和内存只由实验索引组织，不在本页复制。

## 最终 verdict

Skeptic 最终 verdict 为 `PASS WITH CONDITIONS`，confidence high，I2.1 当前
`BLOCKER = 0`。Engineer 的独立 phase/winding、行数、哈希、资源和 report 一致性复核给出
同一 verdict；Researcher 也确认 argument-principle 的对象与有限结论边界成立。

因此，正式可接受的唯一正结论是：

> 在冻结 fine、$M=48$ evaluator 和本实验 sampled analytic/fixed-chart 经验资格成立的
> 条件下，指定圆盘内 $\det A_{\mathrm{def}}^D(k)$ 有一个按代数重数计的 zero。

这比 I1 的“观察到实轴 dip”更强，因为主 determinant 的 winding 为一，且实际 inverse
factor 的 winding 已分开检查；但它仍不是 root 坐标、derivative-qualified simple root、
非零物理场或连续 guided eigenvalue。

## 保留 caveat

### `IMPORTANT CAVEAT`

- 64 个 $k$ 节点、32 个 $\zeta$ 节点、双向 edge guards 和嵌套 winding 不能给出连续
  边界 supremum 或严格闭盘无 pole 定理；极窄未采样 excursion 仍是逻辑可能。因此只能称
  `conditional empirical finite-dimensional count`。当前 I2.2 不需要为提升定理强度追加
  I2.1 实验。
- proxy reduced factor 和 Riesz range-difference 都通过冻结门，但前者的条件数裕量很窄，
  后者的余量也有限。参数、离散层或 evaluator 改变时不得继承，I2.2 root 点也必须重新
  检查 factor health；准确数值由实验索引和 open-problem ledger 维护。
- M0 的 exact half-guide holomorphy、continuous BIE kernel--field equivalence、regular
  approximation 和 spectral-pollution 排除尚未关闭。它们阻止 continuous physical
  promotion，但不撤销当前有限维结果。

### `MINOR CAVEAT`

- 首次 sandbox 启动失败只有终端/协作记录，没有 runner artifact；预算已保守纳入。
- 独立跑后审查在不再调用 MATLAB/Octave 的约束下没有反序列化 compact result artifact；其 hash、
  发布顺序、CSV、report 和 log 机械一致性均已复核。

统一后续状态见
[[research/projects/eig-apost/implementation/open-problems#Current I2|Current I2 open-problem ledger]]。

## 下一步授权边界

I2.1 不需要第二种 count 方法、更多 contour 或 $N_k=128$ 加密。允许下一轮另行设计 I2.2，
并把当前圆盘和 `m1-a1` count-one 结果作为 immutable parent；本审查本身不授权任何 I2.2
实现或运行。

I2.2 至少仍须求出 root，并检查 root residual、左右近核 residual、backward error、root
处全部 factor health、非消失 center/port field participation、边界匹配和独立复现。若要
称实 root，还必须解释 $\operatorname{Im}k$ 是否落在数值不确定度内。失败时应记录为
I2.2 blocker，不能追溯改写 I2.1 count。
