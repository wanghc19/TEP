# I7.2 Hermitian-part 端点符号计数独立审查

## 2026-09-29 修正公共密度坐标后的独立复验审查

本节为 Skeptic 对 `inertia-v1/output/attempt-1/run-02` 的独立只读报告，由主代理原位记录。
Researcher 独立核对冻结坐标和判号规则，Engineer 运行 MATLAB；Skeptic 未修改数值代码、
未另开 MATLAB。下方 2026-09-25 的原 A--H 审查及上游修订通知保留为修正前历史。

### A. 当前审查框架

对象为原 `check_i7_inertia.m`、公共 `bloch.construct_S`、既有设计和 run-02 的
`result.json`、`endpoints.csv`、`audit.json`、`command.txt`、源码快照及资源日志。
目标是冻结 fine/$M=48$ 有限矩阵 $H_{\mathrm{sym}}=(H+H^*)/2$ 的两端符号计数；
不把 I7.3、raw-$H$ inertia、连续特征值或误差认证列为本轮完成条件。

### B. 当前 verdict

**PASS WITH CONDITIONS（高置信度）。** 新矩阵的全部坐标/求解门通过，
$c=50,100,200$ 三带均为左端 $(194,0,0)$、右端 $(193,1,0)$，无 unresolved，
$\Delta_-=+1$、$\Delta_+=-1$，结果为 `JUMP / SINGLE_JUMP`。没有未关闭 blocker。
该结论完全由修正后 run-02 建立，不依赖旧 run-01 矩阵。

### C. 最强挑战

当前证据只覆盖一个空间离散和两个固定端点。修正后的 I7.3 跨离散与同模态比较尚未复验，
因此不能从本次 jump 推断 raw $H$ 的严格实根、唯一性、连续特征值或误差界。
机器量级的非 Hermitian 缺陷也不是严格 Hermitian 证明。

### D. Findings

1. **IMPORTANT CAVEAT — 修正后的跨离散稳定性仍未验证。** 当前最小绝对特征值在两端均远离
   三个判号带；最弱的右端分离仍为 $\eta_{200}$ 的约 $3.61\times10^5$ 倍。这支持本轮有限矩阵
   分类，但不替代修正后的 I7.3；后者不阻止本阶段交付，也没有在本轮自动执行。
2. **MINOR CAVEAT — warning 表述需限定。** 两端没有数值或线性求解 warning；
   日志保留两条 `package sun.awt.X11 not in java.desktop` JVM 启动提示，不应称为“没有任何 warning”。

### E. 当前实现与证据审查

- 冻结模型仍为 $\beta=0.5$、半径 $0.2$ 的圆形 leads `epsrel=17`、单个中心椭圆
  $(0.25,0.16)$ 且 `epsrel_center=2`；tuple 为 $(256,160,160,80,32)$、$M=48$。
  两端固定为 $1.753125,1.75625$，没有扫描、定位或追加配置。
- center 与 half-guide 均直接调用公共 `bloch.construct_S`。公共函数以缩放右端求解并逆变换为
  物理密度；实验入口没有重复缩放。运行命令断言公共路径，排除旧 `scan-v1/tmp`，没有读取历史结果。
- $q=[a^L;b^R]$、trace 顺序 `[left;right]`、中心外法向 $[-\partial_x;+\partial_x]$ 不变。
  独立四块 $A_{\mathrm{def}}$ 经 $A_{\mathrm{def}}=N_0-LT$ 核验后，实际计算 $H=A_{\mathrm{def}}/T$；
  没有用 $A_{\mathrm{def}}$ 的 Hermitian part 替代，没有 `inv`、`pinv` 或修改矩阵制造 Hermitian 性。
- QZ 分类、finite、warning、imaginary leakage、partition、`rcond(T)`、组装/右解门和三带规则均未改变。
  $n=194$，残差门 $1000n\epsilon_{\mathrm{mach}}=4.3076653355456074\times10^{-11}$；
  判号带由各端点的新 $s,d_H$ 重新计算，未使用历史阈值。

| 量 | $k_L=1.753125$ | $k_R=1.75625$ |
|---|---:|---:|
| `rcond(T)` | 0.51702058265282613 | 0.5169934488000496 |
| 组装误差 | 5.4553954713536217e-19 | 5.7764643426271877e-19 |
| 右解误差 | 3.7747494080452222e-19 | 2.8012171613030743e-19 |
| $s$ | 604.17561555534041 | 604.17557925199787 |
| $d_H$ | 2.053125626861299e-13 | 2.1757952844695718e-13 |
| $\eta_{50}$ | 1.3014984904175209e-9 | 1.3015106791919563e-9 |
| $\eta_{100}$ | 2.6027916682723556e-9 | 2.6028037788554658e-9 |
| $\eta_{200}$ | 5.2053780239820255e-9 | 5.2053899781824847e-9 |
| 最近零的有符号特征值 | +0.021226887784655889 | -0.001880568371886166 |
| 最小绝对特征值 | 0.021226887784655889 | 0.001880568371886166 |
| 主带余量 | 0.021226885181864219 | 0.001880565769082387 |
| 三带各自的 $(n_+,n_-,n_{\mathrm{unresolved}})$ | (194, 0, 0) | (193, 1, 0) |
| sensitivity / diagnostic | STABLE / PASS | STABLE / PASS |

两端 imaginary leakage 均为零。同一 MATLAB 进程对 freshly returned matrices 重新计算
$H_{\mathrm{sym}}$、eigenvalues、三带 counts、partition 和恒等式，全部通过，Hermitian-part 与
eigenvalue defect 为零。Skeptic 独立核对 JSON/CSV、该审计的实际命令与资源记录，源码快照与
当前入口、`construct_S`、`qpgreen_mfs_pairmat` 逐一一致。该 audit 复核有限矩阵结果，不是独立物理解法。

入口耗时 $17.265248375$ s，完整受监测 wall time $28.184776$ s，exit 0。
282 个资源采样的进程树及全部 MATLAB 树并集峰值均为 **1,140,686,848 bytes**，
低于 2.3 GB 提前线及 3 GB 用户上限；每 0.1 s 监测，正式运行无外部 MATLAB 并发。
本轮只有这一项 MATLAB 计算，未发生科学点程序错误或资源超限。
外部 JSON/CSV 交付核对曾因 Python 浮点乘法分组的严格相等测试而停止；沿用 MATLAB 的
运算顺序后 $\eta$ 复核差为零。初次记录单独保留，没有改变科学数据或追加 MATLAB。

### F. 经受住审查的部分

旧 run-01 与新 run-02 的 count triples 一致，但新旧矩阵不能互换。$d_H$ 从约
$6.94\times10^{-3}/6.98\times10^{-3}$ 降到约 $2\times10^{-13}$；最近零谱值也从
$+0.0102440899424641/-0.0129547448103775$ 改为上表值。
当前 jump 是重新组装、重新求解与重新判号的结果，未由历史结果自动继承。

### G. 当前处置

接受 corrected-density I7.2 run-02；原入口和公共数值代码本轮无需修改。
新矩阵、完整命令、日志和资源证据保留在
[[test/i7/inertia-v1/output/attempt-1/run-02/result.json|run-02]]，复现见
[[test/i7/inertia-v1/README|实验 README]]。不追加超出本轮目标的探索。

### H. Open-problem handoff

I7.3 仍待修正后复验；本轮不为其提供新完成声明。问题状态只由
[[research/projects/eig-apost/implementation/i7/README#I7 待办与问题|I7 唯一问题表]]维护。

## 2026-09-25 修正前历史审查（保留原 A--H）

> **2026-09-27 上游修订状态。** 本文审查的端点数值使用了修正前的中心椭圆
> `bloch.construct_S` 密度坐标链。公共源现已统一缩放矩阵、右端、物理密度和场提取坐标，但本轮
> 只复验 I7.1；因此下面的 `JUMP / SINGLE_JUMP` 保留为修正前历史有限矩阵事实，尚不能作为当前
> 物理模型的端点证据。I7.2 须以修正后的公共路径独立重跑后再更新 verdict。

## A. 审查框架

- 审查对象：[[research/projects/eig-apost/implementation/i7/design-7-2a|I7.2 设计]]、
  `test/i7/inertia-v1/check_i7_inertia.m` 和
  `test/i7/inertia-v1/output/attempt-1/run-01/` 的正式结果。
- 当前问题：固定中心椭圆 `epsrel_center=2`、圆形 leads `epsrel=17`、final tuple
  $(256,160,160,80,32)$ 和 $M=48$，在 $k_L=1.753125$、$k_R=1.75625$ 上计算
  $H_{\mathrm{sym}}=(H+H^*)/2$ 的端点符号计数，判断它是否为 I7.1 dip 提供数值佐证。
- 当前阶段与输出类型：工程数值实验；交付是冻结有限维对象的两点诊断，不是 raw-$H$ inertia、
  连续特征值证明、root locator、误差认证或跨离散收敛结论。
- 成功标准：中心迹坐标、法向和 $A_{\mathrm{def}}$ 组装一致；$T$ 条件数、组装/右解残差、有限值、
  QZ、谱 leakage 和计数 partition 均按冻结规则处理；$c=50,100,200$ 三带结果和程序/科学/解释
  三层状态分开；正式运行满足 1800 s 与 3,000,000,000-byte 门。
- 权威与材料：用户本轮约束、I2.2 当前设计第 19 节、I7.1 当前实现和 I7.2 冻结设计；另读正式
  `result.json`、`endpoints.csv`、`audit.json`、`command.txt`、`run.log`、`resources.csv`、
  `monitor-status.txt` 及保存矩阵清单。Skeptic 未另开 MATLAB。

## B. Verdict

**PASS WITH CONDITIONS（高置信度）。** 正式运行 exit code 0，入口用时 $21.43027775$ s、受监测
wall time 42 s，process-tree peak RSS 为 1,107,099,648 bytes。两个端点全部对象门通过，三带计数
稳定且无 unresolved mode；结果从 $(n_+,n_-,n_?)=(194,0,0)$ 变为 $(193,1,0)$，故冻结规则下
$\Delta_-=+1$、$\Delta_+=-1$，科学状态为 `JUMP / SINGLE_JUMP`。该结论只支持“单一 final 离散的
Hermitian-part 端点符号计数提供数值佐证”。raw $H$ 的非 Hermitian 距离非零，而且尚未完成跨离散
与同模态比较，所以不能升级为 raw-$H$ inertia、实根或连续 guided mode 证明。

## C. 最强挑战

最可能推翻更强解释的是 **Hermitian-part jump 对尚未检查的离散扰动不稳健**。左、右端点的
$d_H$ 分别为 $6.940363180566178\times10^{-3}$ 与
$6.976092528270513\times10^{-3}$；虽然相对整体尺度仅约
$1.15\times10^{-5}$，却分别是端点最小绝对 $H_{\mathrm{sym}}$ 特征值的约 $67.75\%$ 和
$53.85\%$。当前 $c=50,100,200$ 只改变 roundoff allowance，不能替代边界离散轴、trace cutoff
轴和同模态检查。它不否定本轮预注册的 corroboration，但阻止任何谱存在性或精确定位表述。

## D. Findings

1. **IMPORTANT CAVEAT — 单一离散上的 jump 尚无跨离散同模态稳定性证据。**
   - 位置：正式结果两个 endpoint，以及设计第 4--5 节。
   - 证据：主带 $\eta_{100}$ 分别为 $6.940365783152534\times10^{-3}$ 与
     $6.976095130856713\times10^{-3}$；端点最小绝对特征值分别为
     $1.024408994246409\times10^{-2}$ 与 $1.295474481037747\times10^{-2}$，超过带边的余量只有
     $3.303724159311555\times10^{-3}$ 与 $5.978649679520753\times10^{-3}$。三带计数确实完全相同，
     但 $c$-sensitivity 的增量约 $10^{-9}$，远小于非 Hermitian 距离。
   - 对当前目标的后果：`JUMP` 可接受为 frozen fine/$M=48$ 数值佐证；不能证明区间内 raw $H$
     有实零点、不能给出 $k$ 误差，也不能说明该 mode 在另一空间离散下保持同一身份。
   - 不确定性：当前没有反例；缺失的是下一阶段的跨离散证据，而不是本次计数本身。
   - 最便宜决定性检查：按 I7 已规划的 I2.3 风格，分别改变边界离散和 trace cutoff，并用保存向量的
     overlap/同模态规则比较端点近零 mode；不要把两轴混成一条 refinement ladder。

未发现 unresolved `BLOCKER`。唯一未决问题及状态由
[[research/projects/eig-apost/implementation/i7/README#I7 待办与问题|I7 README 问题表]]维护，
本审查不复制问题 ledger。

## E. 实现审查

- **迹坐标与法向。** 对 $q=[a^L;b^R]$，实现使用

  $$
  T=\begin{bmatrix}I+R_L&T_{RL}\\T_{LR}&I+R_R\end{bmatrix},\qquad
  N_0=\begin{bmatrix}
  \mathrm{i}G(R_L-I)&\mathrm{i}GT_{RL}\\
  \mathrm{i}GT_{LR}&\mathrm{i}G(R_R-I)
  \end{bmatrix},
  $$

  以及 $L=\operatorname{blkdiag}(\Lambda_-,\Lambda_+)$。左墙 $-\partial_x$ 给出
  $\mathrm{i}G(b^L-a^L)$，右墙 $+\partial_x$ 给出 $\mathrm{i}G(a^R-b^R)$；block order 与
  `LOCAL_dtn` 的 $\Lambda_-,\Lambda_+$ 顺序一致。
- **独立组装。** `Adef` 仍由 I7.1 四块公式独立形成，再检查
  $A_{\mathrm{def}}=N_0-LT$；没有用恒等式反向定义 `Adef`。随后只用 `H=Adef/T`，未调用
  `inv`、`pinv` 或整体归一化。
- **对象门。** 两端 `rcond(T)` 为 $0.5176647818035973$、$0.5176371768358853$；组装残差为
  $7.755340710881157\times10^{-19}$、$5.823204150931459\times10^{-19}$；右解残差为
  $5.555193143207840\times10^{-19}$、$3.836699062833900\times10^{-19}$，均远低于
  $1000n\epsilon=4.307665335545607\times10^{-11}$。两端 solve warning 为空。
- **谱与计数。** $s$ 为 $604.1756155553412$、$604.1755792519967$，imaginary leakage 均为 0。
  左端最小特征值 $+0.01024408994246409$，右端最小特征值
  $-0.01295474481037747$。$c=50,100,200$ 三带分别都给出左端 $(194,0,0)$、右端
  $(193,1,0)$，每行和为 $n=194$。从 JSON 按冻结公式独立复算六个 $\eta_c$，与保存值逐位相同。
- **状态语义。** QZ 不合格、非有限对象、无法完成的 solve/eig、明显 leakage、partition 或资源失败
  均 fail closed；有限对象上的条件数/恒等式/右解 warning 或 band 诊断失败进入科学
  `UNRESOLVED`。本次 `execution_pass=true`、`diagnostic_pass=true`、
  `surrogate_sign_count_available=true`，同时明确
  `raw_inertia_available=false`、`raw_real_zero_claim=false` 和
  `continuous_eigenvalue_claim=false`。
- **复用和路径。** `LOCAL_center`、`LOCAL_cellsub`、`LOCAL_qzsub`、`LOCAL_dtn`、
  `LOCAL_h2d_chunked_public`、`LOCAL_solver_warning_guard` 的计算文本与 `locate_i7.m` 相同。
  H right solve 单独把四类 warning 设为 `on` 并在退出时恢复，避免依赖调用者 warning 状态。
  正式命令从 `tempdir` 启动，断言公共 `kernel.h2d_directch` 唯一路径并排除历史 `tmp/`。
- **保存与复核。** `result.mat`/JSON/CSV 保存 compact 结果，`endpoint-matrices.mat` 保存两端
  `Adef,T,N0,L,H,Hsym`、谱和 bands。正式命令中的跑后复核重新计算 $H_{\mathrm{sym}}$、eigenvalues
  和 counts，defect/差异均为 0，`audit.pass=true`。`checkcode` 只有一条对 cleanup guard 变量的
  `NASGU` 型 advisory；该变量必须存活到显式 `clear`，不影响公式或运行。
- **资源。** 139 个资源采样给出 peak tree RSS 1,107,099,648 bytes，低于 3 GB；wall 42 s，低于
  1800 s。本轮没有并发 MATLAB 或失败重试证据。

## F. 经受住审查的部分

中心散射的迹矩阵不是照搬空中心相位块，而是由实际 $R/T$ blocks 构造；法向符号、左右 DtN 顺序和
I7.1 `Adef` 完全闭合。独立组装残差、右解残差和条件数给出强实现一致性证据。三带完整 triples
一致、无 unresolved mode，且保存矩阵复核与 compact 输出一致，因此 `SINGLE_JUMP` 是当前冻结
有限维对象的真实结果，而非由阈值选择、低阶替代或事后移动端点造成。

## G. 最小处置

接受本次 I7.2 endpoint run；无需重跑、移动端点或修改 band。README 应记录上述直接数值、资源和
`JUMP` 的严格解释边界。下一正常 gate 是另行设计的跨离散与同模态比较；在该 gate 完成前，保持
“Hermitian-part numerical corroboration”表述。

## H. Open-problem handoff

本阶段没有阻止交付的未决项。后续 goal-relevant 项统一链接到
[[research/projects/eig-apost/implementation/i7/README#I7 待办与问题|I7-Q1 与 I7-Q3]]：它们属于
I7.2 之后的 `IMPORTANT CAVEAT`，不阻止接受本轮；最小下一检查是分轴离散稳定性与同模态比较，
ledger 状态保持 `open`，直到该独立实验完成。
