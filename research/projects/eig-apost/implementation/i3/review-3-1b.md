# I3.1 全波导强残量实验独立审查

## 审查结论

- Design ID：`I3.1-BIE-INFORMED-GLOBAL-RESIDUAL-V1`
- 正式数值 attempt：`lead-a3`
- producer 状态：`I3_1_CONFORMING_RECONSTRUCTION_UNRESOLVED`
- 独立 verdict：`PASS WITH CONDITIONS / VALID NEGATIVE`
- I3.1 状态：继续活动；尚无 estimator，I3.2 不可开始

本审查只通过 [[test/i3/g-resid/README|I3.1 lead-aware experiment index]] 进入正式数值证据。
冻结的 [[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]]、MATLAB 源码和
append-only output 均不作追溯修改。Skeptic 确认 producer 使用了预注册阈值和失败优先级；
`lead-a3` 是可消费的负结果，不是需要改写为成功的异常 run。

## 1. 检查的对象

实验固定 I2 保存的 candidate

$$
\widehat k_h=1.832770289108157
$$

以及 fine $n_{\mathrm{tot}}=256$、$M=48$ 离散输入，不扫描或调整 $k$。它先从 frozen QZ bases
恢复左右 whole-subspace propagation actions，再用 one-cell BIE 内外场作为训练数据，拟合一个
在每个胞元内由单一 Fourier--Hermite/bubble 公式定义的光滑 trial。只有该拟合、中心修正和
非零门通过后，程序才会形成全波导 field/residual/$H^2$ Grams、无限尾诊断和 continuous strong
residual ratio。

因此本次首败发生在 field reconstruction 阶段时，continuous residual 尚未被计算；原有限矩阵
residual、BIE solve residual 或 QZ invariant residual 都不能代替它。

## 2. Attempt 历史与正式命令

| Attempt | 分类 | 结果与消费方式 |
|---|---|---|
| `lead-a1` | startup/preflight failure | MATLAB 启动阶段于约 $3.3$ s 以 exit code 137 结束；runner 未进入、evaluator 调用为 0、无 output。所有科学门均为 `NOT_REACHED`，不能解释为实验内存失败。 |
| `lead-a2` | implementation/naming failure | shell exit 0，但 producer 为 `I3_1_EXECUTION_UNAVAILABLE`。finite input 已通过；随后局部变量名遮蔽 MATLAB 常数 `pi`，density gate 未形成判定。用时 $17.421280$ s，peak active-object memory $61.154669$ MiB，`retry_count=0`。其两个 artifact 保持原样。 |
| `lead-a3` | formal numerical attempt | 只修复上述局部命名并机械更新 attempt metadata；科学对象、公式、参数、阈值和资源门均未改变。producer 在固定 BIE-informed fit 首败处停止，形成当前有效负结果。 |

正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','g-resid'),fullfile(pwd,'test','i2','k-count')); check_g_resid('lead-a3');"
```

`lead-a3` 实际用时 $373.254082$ s，peak active-object memory 为 $62.706804$ MiB，低于
$900/1800$ s 和 $512$ MiB 资源门；自身 `retry_count=0`，并保留两个先前失败 attempt。输出目录
只含 `result.mat` 和 `report.md` 两个文件，二者的 attempt、status、candidate、首败、耗时和内存
摘要一致。

## 3. 首败前已通过的数值门

### 3.1 Finite input

saved-candidate point 的 physical score 为 $5.6553167\times10^{-11}$，near-null ratio 为
$1.1051082\times10^{-10}$，raw residual 为 $3.1457643\times10^{-10}$，raw backward error 为
$5.2067133\times10^{-13}$。最紧 factor rcond 为 $1.0481727\times10^{-8}$，仍只比
$10^{-8}$ 门略高；最大 factor solve residual 为 $3.1283225\times10^{-8}$。本门通过，但最紧
factor margin 仍是重要 caveat。

### 3.2 Density 表示

实验使用 $\eta=(\tau,\zeta)^{\mathsf T}$、$\zeta=-\sigma$。重组的 $A_{\mathrm{QP}}$ 与 evaluator
对象的相对差为 0，$A_{\mathrm{QP}}$ rcond 为 $2.1687403\times10^{-2}$，solve residual 为
$4.4979262\times10^{-15}$；circle speed 和 scaling-product defects 分别为
$1.2490009\times10^{-15}$ 与 $1.1102230\times10^{-16}$。

四个 manufactured D/minus-S oracle 的 finest errors 为

$$
0.07419,\quad 0.08160,\quad 0.09318,\quad 0.04165,
$$

都低于 $0.25$，相对 coarsest 的比例为 $0.2528$--$0.3079<0.75$；global-$x$ derivative error
最大为 $2.47\times10^{-9}<10^{-5}$。因此 density/sign/scaling 门通过。

### 3.3 Propagation action

左右 frozen-$Z$ actions 的 rank 均为 97，rcond 分别为 $0.4977327$ 与 $0.4977327$，invariant
residual 分别为 $6.24\times10^{-16}$ 与 $6.21\times10^{-16}$；left global-$x$ orientation
defect 为 0。故 whole-subspace propagation 门通过，未见 rank、orientation 或不变子空间公式
造成首败的证据。

## 4. 固定重构的首个失败

左右两侧结果在普通舍入范围内对称：

| Bubble order | Rank | factor rcond | 左侧 holdout error | 右侧 holdout error |
|---:|---:|---:|---:|---:|
| $J=4$ | 4 | $0.2681649$ | $4.5224212$ | $4.5224212$ |
| $J=8$ | 8 | $0.0681810$ | $5.1380284$ | $5.1380284$ |

rank 和 factor rcond 门通过；但 $J=8$ 的 holdout error 约为预注册上限 $0.20$ 的 $25.69$ 倍，
且比 $J=4$ 更差。producer 因而正确给出首败
`CONFORMING_RECONSTRUCTION_UNRESOLVED`，消息为 `The fixed BIE-informed fit failed.`。

作为区分性诊断，actual BIE data 的 circle value jumps 为 $0.11925$，circle normal jumps 为
$0.04311$；wall value/global-$x$ defects 为 $10^{-15}$--$10^{-13}$，横向 quasi-periodic seam
defects 为 $10^{-15}$--$10^{-13}$。这些数据没有显示显然的 wall、seam、左右符号、reshape 或
索引错误，但也不能证明 close layer-potential evaluation 已可靠。

## 5. 近圆评价 caveat

training 和 holdout targets 到材料圆的最小距离分别只有
$4.2207\times10^{-5}$ 与 $5.3152\times10^{-5}$。$N=256$ 圆周源点的典型弧长约为
$4.91\times10^{-3}$，所以两种距离仅约为该尺度的 $0.86\%$ 与 $1.08\%$。当前 direct
layer-potential close evaluation 没有独立资格化。

因此大 holdout error 不能单独归咎于 bubble basis、fit metric 或 BIE close evaluation 中的任何
一项。严格可保留的结论只是：当前冻结 pipeline 没有建立 BIE-informed shape quality。这个未决
原因是 I3.1 reconstruction 的 blocker；它不授权结果后修改 basis、grid、阈值或自动运行
`lead-a4`。

## 6. 能保留与不能主张的结论

可以保留：

- frozen finite input、density representation 和 propagation action 已通过各自预注册门；
- 当前固定 BIE-informed fit 在独立 holdout 上明确失败，且 $J=8$ 没有改善；
- `lead-a3` 是资源预算内、无 retry、按冻结失败优先级停止的有效负结果；
- I3.1 仍活动，下一步必须先解释或替代当前 reconstruction 首败。

不能主张：

- 已构造通过资格的全波导 continuous trial；
- 已计算 continuous strong-residual estimator candidate；
- 已得到 reliable numerical enclosure、projected-gap 内存在区间或指定 eigenvalue；
- 当前失败已经证明 bubble basis 本身不足，或已经证明 close BIE evaluation 是唯一原因；
- I3.2 可以开始，或应自动设计、调参并运行下一 attempt。

center correction、field/residual/$H^2$ Grams、quadrature、infinite-tail diagnostics、nominal interval
和所有 gap/upper-bound claims 均为 `NOT_REACHED`。Skeptic 最终 verdict 为
`PASS WITH CONDITIONS`：接受 producer 首败和负结果解释，同时要求保留上述近圆评价 caveat。
