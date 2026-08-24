# I3.1 BIE-collar 弱残量实验独立审查

## 审查结论

- Design ID：`I3.1-BIE-COLLAR-Q1-RT0-V3`
- 正式数值 attempt：`bie-a3`
- producer 状态：`I3_1_HDIV_FLUX_UNRESOLVED`
- 独立 verdict：`POST-RUN PASS / VALID NEGATIVE / REVISE BEFORE CONTINUATION`
- I3.1 状态：继续活动；尚无 estimator，I3.2 不可开始

本审查通过 [[test/i3/b-resid/README|BIE-collar experiment index]] 消费正式数值证据。
[[research/projects/eig-apost/implementation/i3/design-3-1d|冻结设计]]、MATLAB 源码和三个
append-only attempt output 均保持原样。`bie-a3` 正常捕获并保存了第一个数值 blocker；它是
有效负结果，但不是 estimator 本身的负结果。

## 1. 检查对象与真实入射映射

实验固定 I2 保存的 candidate

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2,
$$

以及 $n_{\mathrm{tot}}=256$、$M=48$ 的 frozen QZ/Rayleigh 数据，不重新扫描或调整 $k$。
写

$$
Z_+=\begin{bmatrix}A_+\\B_+\end{bmatrix},
\qquad
Z_-=\begin{bmatrix}A_-\\B_-\end{bmatrix}.
$$

若 $D_c v$ 是 weighted physical near-null vector，先令

$$
q=\frac{D_cv}{\|D_cv\|_2}
=\begin{bmatrix}q_L\\q_R\end{bmatrix}.
$$

中心空列 incoming 是 $(q_L,q_R)$。再令

$$
D_\pm=A_\pm+B_\pm,
\qquad
E=\operatorname{diag}(e^{\mathrm i\gamma_m}),
$$

则实际左右 lead amplitudes 由

$$
D_-c_-=[I,E]q,
\qquad
D_+c_+=[E,I]q
$$

确定；这里沿用 evaluator 已冻结的 branch $\gamma_m$，不重新开方。

右侧 canonical lead cell 对 state $c$ 使用的真实入射系数是

$$
(a_L,b_R)=(A_+c,\,B_+P_+c),
$$

对应出射系数为

$$
(b_L,a_R)=(B_+c,\,A_+P_+c).
$$

左侧按物理左右顺序使用

$$
(a_L,b_R)=(A_-P_-c,\,B_-c).
$$

对应出射系数为

$$
(b_L,a_R)=(B_-P_-c,\,A_-c).
$$

总系数 $a+b$ 只用于完整墙面 Dirichlet trace 的拼接检查，不进入 BIE incident right-hand
side。第二个 density coordinate 固定为 $\zeta=-\sigma$，内外场使用同一符号合同

$$
u_{\mathrm e}=u_{\mathrm{inc}}+D_{\mathrm{QP}}\tau-S_{\mathrm{QP}}\zeta,
\qquad
u_{\mathrm i}=D_{\mathrm i}\tau-S_{\mathrm i}\zeta.
$$

程序同时核对实际 states 的 one-cell scattering closures
$b_L=R_La_L+T_{RL}b_R$ 与 $a_R=T_{LR}a_L+R_Rb_R$；最大 defect 为
$1.52\times10^{-15}$。

程序只在圆周单侧 trace、安全圆和安全墙点评价层势；圆周与墙 collar 再写入一个全局
periodic-gauge Q1 companion。只有该场、全局 RT0 flux、材料积分与 full-$P$ tail 全部通过，
才能形成 continuous weak-residual functional majorant。

## 2. Attempt 历史与正式运行

| Attempt | 分类 | 结果 |
|---|---|---|
| `bie-a1` | legacy-interface failure | 旧 evaluator 读取缺失字段 `kstar`；未进入 evaluator 或科学阶段。producer 为 `EXECUTION_UNAVAILABLE`，用时 $0.0459895$ s。 |
| `bie-a2` | MATLAB syntax failure | finite input、branch/Wood、propagation、BIE density、surface trace 与 safe evaluation 已通过；随后因 MATLAB 不接受转置结果上的直接 `(:)` 索引而在 Q1 前停止。用时 $222.980958$ s，peak $89.657628$ MiB。 |
| `bie-a3` | 正式数值 attempt | 只作旧接口 adapter 与四处等价 `reshape` 修复，科学公式、参数、阈值和资源合同不变；在 coarse lead RT0-majorant 预因子处首败。 |

正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','b-resid'),fullfile(pwd,'test','i2','k-count')); check_b_resid('bie-a3');"
```

`bie-a3` 用时 $379.523247125$ s，peak active-object memory 为 $89.6576280594$ MiB，低于
$900/1800$ s 和 $512$ MiB 资源门；attempt-local `retry_count=0`，另行保存两个历史失败
attempt。输出目录只含 `result.mat` 与 `report.md`。

## 3. 首败前通过的正式检查

以下门在 artifact 中有明确 `pass=true`：

- finite input：physical score $5.6553167\times10^{-11}$，near-null ratio
  $1.1051082\times10^{-10}$，raw residual $3.1457643\times10^{-10}$，raw backward error
  $5.2067133\times10^{-13}$；
- branch/Wood：dimensionless Wood distance 为 $0.9484544>10^{-6}$，branch algebra
  roundtrip defect 至多 $4.37\times10^{-16}$；
- propagation：左右 rank 均为 $97$，thin-QR rcond 约 $0.497733$，solve/invariant residual
  至多 $6.24\times10^{-16}$，actual-state scattering closure defect 至多
  $1.52\times10^{-15}$；
- BIE density：$A_{\mathrm{QP}}$ rcond 为 $2.1687403\times10^{-2}$，最大 multi-RHS
  relative residual 为 $3.79\times10^{-15}$，重建 block defect 为 0；
- one-sided surface trace：Fourier--Bessel manufactured oracle 最大相对误差为
  $8.40\times10^{-15}$，$256\to512$ 同 density trace 变化至多
  $4.01\times10^{-15}$；
- safe field：安全圆与墙面的 $256\to512$ 变化均为 $10^{-15}$ 量级；完整相邻 raw wall
  trace defect 至多约 $1.24\times10^{-13}$，Bloch/gauge defect 至多约
  $2.96\times10^{-14}$。

这些都是同一 BIE/QZ 链的内部资格，不是 I3.2 独立 reference。它们支持“真实 incoming 的
BIE 场在预注册安全 targets 上通过当前 ordinary-double 检查”，但不把 BIE 场或 QZ state
升级为连续特征函数。

控制流还表明 coarse Q1 maps 已构造并越过 finite/nonzero/shared-wall/periodic form gate；否则
程序会先返回 `FORM_CONFORMITY_UNRESOLVED`。但 majorant helper 抛错前尚未把该 record 写入
`result.levels`，所以这一点只是控制流推断，不能引用未保存的 Q1 数字，也不能据此宣称整个
无限波导 trial 已有有限 $H^1$ 范数。

## 4. 精确首败与原因边界

producer 保存的首败为

```text
HDIV_FLUX_UNRESOLVED
i31b:HdivFlux
The RT0 scaling diagonal is unavailable.
```

失败发生在 coarse lead 的第一个 RT0 factor。程序要分解的 free-flux block 是

$$
L_{ff}=\left(L_A+\gamma^{-1}L_B\right)_{ff},
$$

其中 $L_B$ 已含 true-circle polar disk correction。代码在检查该积分对象之前就使用
$L_{ff}$ 的对角构造 scaling，因此 machine 标签虽与抛错位置一致，却不能单独证明
$H(\operatorname{div})$ 理论或 normal-orientation 失败。

Engineer 对冻结的同一装配与求积公式作了不调用项目函数、evaluator 或 MATLAB 的只读独立
复算。该补充诊断只是代码公式审计，不是独立物理方法、I3.2 reference 或可靠积分认证，也不是
新正式实验 artifact；它把当前代码对象定位为：

- coarse lead free block 的对角均为有限数，其中 $652$ 个非正，最小值约
  $-0.549478746$；
- 最坏项的 $L_A\approx8.1380\times10^{-5}$，background $L_{B,0}\approx4.000020345$，
  polar disk correction 约为 $-5.846018600$，故 corrected $L_B\approx-1.845998255$；
- empty-center free block 全部为正，最小值约 $0.297784872$；
- 按同一公式检查 fine 网格仍有 $1406$ 个非正 lead 对角，最小值约 $-0.559735506$。

在精确积分下，纯 flux 二次型

$$
\|p\|^2+\gamma^{-1}\|\rho^{-1/2}\operatorname{div}_\beta p\|^2
$$

应严格为正。当前最可信的解释是 Cartesian background quadrature 与带负号的 global polar
disk correction 对局部 RT0 support 不保持正性；edge indexing、support 或 assembly error 仍
不能由正式 artifact 排除。严格结论只能写成：当前 composite RT0-majorant quadrature/assembly
尚未实现其假定的正定离散对象。不得用取绝对值、clipping、正则化或放宽阈值绕过首败。

## 5. Residual、区间和结论边界

本 attempt 没有形成合格的 $\sigma_h\in H(\operatorname{div})$，因此下列 majorant 分量均未
产生：

$$
A_h^2=\|\nabla u_h^{\mathrm c}-\sigma_h\|^2,
\qquad
B_h^2=\|\rho^{-1/2}
(\operatorname{div}\sigma_h+\mu_h\rho u_h^{\mathrm c})\|^2.
$$

full-$P$ tail、phase/scale repeat、coarse/fine refinement、normalized $q_h$ 与 nominal
prediction interval 全部 `NOT_REACHED`。artifact 中 `indicator_available=false`、所有 coverage
flags 为 false，`continuous_form_residual_computed=false`，
`functional_majorant_formula_applied=false`。因此：

- 没有 estimator candidate；
- 没有 ordinary-double nominal interval，更没有 reliable prediction interval；
- 没有 projected-gap containment、连续离散特征值存在性、唯一 mode 或 candidate error bound；
- I3.2 不可开始，本 attempt 也不能充当 I3.2 independent reference。

## 6. 下一最小门

若继续，必须先作一个新的、单独审查的 append-only revision：

1. 在 majorant factor 前保存已经通过的 Q1 reconstruction record；
2. 保存 lead/center 的 $L_A$、background $L_B$、disk correction 与最终 $L_{ff}$ 对角摘要，
   包括 finite/nonpositive count、minimum、坏 edge 的方向、位置和 support；
3. 先检查 disk/integration object，再进入 factor；
4. integration 或 composite positivity 失败应归
   `MAJORANT_QUADRATURE_UNRESOLVED`；只有正定对象通过后的 conditioning、factorization 或
   solve 失败才归 `HDIV_FLUX_UNRESOLVED`；
5. 在辨明 algebraic assembly 与 quadrature positivity 之前，不修改 flux rule、阈值或科学
   解释。

本审查接受 `bie-a3` 为有效负结果，并确认当前没有预测区间。I3.1 保持
`ACTIVE / NO ESTIMATOR`。
