# I7.2 Hermitian-part 端点符号计数独立审查

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
