# I3.1 纯 BIE 边界残量实验独立审查

## 审查结论

- Design ID：`I3.1-PURE-BIE-BOUNDARY-RESIDUAL-V1`
- 正式数值 attempt：`pbie-a2`
- producer 状态：`I3_1_COMPUTED_PURE_BIE_CONTINUOUS_RESIDUAL_INDICATOR_CANDIDATE`
- 独立 verdict：`POST-RUN PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`
- I3.1 状态：已形成可计算 indicator candidate；三项内部资格未闭合，I3.2 不可开始；
  reliable enclosure 留给 I3.3

本审查通过 [[test/i3/p-resid/README|pure-BIE experiment index]] 消费正式 artifact；冻结
[[research/projects/eig-apost/implementation/i3/design-3-1e|design-3-1e]]、MATLAB 源码与
append-only output 均保持不变。结论不是“误差已经约为 $10^{-10}$”，而是“在冻结的普通
双精度边界计算中得到一个可复算的残量指标候选，但其数值可靠性条件没有闭合”。

## 1. 数学对象与数值近似

实验固定 I2 保存的

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2,
$$

以及 $n_{\mathrm{tot}}=256$、$M=48$。左右 QZ states 通过完整 $P_\pm$ 矩阵生成共享的 wall
Dirichlet traces。每个周期胞元用有限三角密度和数学上精确的 rectangular Dirichlet Green
kernel 定义分片 trial；圆周上的 value jump 由数学上的连续 radial collar 修复，剩余 wall
normal jump、circle normal jump 和 collar volume source 进入弱残量指标。三项按三角不等式
相加，不假设正交。

必须区分两个层次：上述 exact-kernel trial、连续 collar 公式以及逐胞元、修复界面后的局部
$H^1$ 构造已经定义；代码保存的 512 点 traces、Fourier coefficients、Grams 与 tails 是普通
双精度近似。全波导上的连续 $H^1$ 归属仍依赖尚未认证的无限尾部可和性。artifact 明确记录
`mathematical_*_defined=true`，同时记录 `continuous_H1_numerically_enclosed=false` 和
`continuous_jump_enclosed=false`；因此它没有在数值上向外包住连续 jump、全局场或其范数。

## 2. Attempt 历史与运行

`pbie-a1` 是有效的 implementation failure：它已完成 finite-density exact-kernel boundary
action，但 fieldless empty struct 无法接收第一个 typed warning，因而在 boundary Grams 前以
`MATLAB:heterogeneousStrucAssignment` 停止。Revision A 只统一 warning schema，并把新 attempt
命名为 `pbie-a2`；科学公式、参数、阈值和资源预算未改。
`pbie-a1` 用时 $133.37207583333333$ s，peak $62.314550399780273$ MiB；其 `result.mat` 与
`report.md` SHA-256 分别为
`473a6809b5e8910c8e8daa82be5dd68c39da24f0edfa6c187abecba1629a7c51` 与
`925132cd91bdf6ed29e3a4a7aed7a4661014427f84a42734825b616f717c9ecb`。

正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','p-resid'),fullfile(pwd,'test','i2','k-count')); check_p_resid('pbie-a2');"
```

`pbie-a2` shell exit code 为 0，attempt-local `retry_count=0`，用时
$117.91992858333333$ s，peak active-object memory 为 $242.98618412017822$ MiB，低于
$900/1800$ s 与 $512$ MiB 资源门。正式 artifact 哈希为：

- `result.mat`：`06a319f51364a950f018e4210a9e66747d6b34b5fa68552d697f90d30a899b75`；
- `report.md`：`98e0a0e32fd79aa167804451d05f1620f4104eb813c2457a9d0d273d5a263658`。

## 3. 通过的内部检查

frozen input、branch/Wood、左右 propagation、coordinate solve 和 actual-state scattering
closure 均通过；Wood distance 为 $0.94845439884439264$，左右 $P_\pm$ 的 thin-QR rcond 约
$0.4977$，最大 actual-state closure defect 为 $1.5179587665970343\times10^{-15}$。
finite density solve 的 rcond 为 $0.01206574928219053$，最大逐右端 relative residual 为
$8.279642886309043\times10^{-15}$。

artifact 保存了完整 $P_\pm,D_\pm,G_\pm$、raw 512 点 circle jump 与 wall derivative maps。
只读独立复算得到：$G_\pm$ 与全部 wall $Q/J$ maps 的相对 defect 为 0；circle value/normal
maps 的相对 defect 为约 $1.5\times10^{-15}$--$2.0\times10^{-15}$。两侧 wall、circle、volume、
field 与 mandatory state Grams 均通过 scale-covariant Hermitian/PSD 检查；极小负 eigenvalues
只在各自 Gram scale 的舍入容差内。

circle trace weights 全部有限且为正，范围为
$[2.1489699477682942,2560.0235364578771]$；$256\to512$ Riccati change 为
$4.587964518327254\times10^{-11}$，低阶 Bessel defect 为
$1.4608152867864522\times10^{-12}$，离散 energy-identity defect 最大为
$2.9946883160822332\times10^{-6}$。collar 16--32 点变化为
$3.1282806499482901\times10^{-15}$。

左右 full-$P$ tails 都选择 $N=8$，ordinary-double tail share 最大分别为
$2.6620010359261588\times10^{-9}$ 与 $2.8726725602923426\times10^{-9}$，低于冻结
$10^{-6}$ 资格阈值；但 `tail_diagnostic_certified=false`。phase/scale repeat 最大相对 defect 为
$1.7151101537727681\times10^{-16}$，通过内部门，但同样不是 outward enclosure。

## 4. 指标候选与名义区间

三个 residual 分量、field lower candidate 与归一化指标为：

| 数值对象 | 普通双精度结果 |
|---|---:|
| wall component | $1.8732651111819612\times10^{-10}$ |
| circle component | $4.2041578545992812\times10^{-14}$ |
| collar-volume component | $5.8690572462596622\times10^{-11}$ |
| triangle sum | $2.4605912515933872\times10^{-10}$ |
| field lower candidate | $2.2269063318145634$ |
| normalized $q$ | $1.1049370224693775\times10^{-10}$ |

由冻结的代数变换得到名义 $k$ 区间

$$
[1.8327702889056474,\ 1.8327702893106665],
$$

宽度为 $4.0501912934587381\times10^{-10}<10^{-6}$。只读复算 triangle sum、$q$ 与两个端点
均与 artifact 逐位一致。该区间只能称 `NUMERICALLY_UNQUALIFIED` nominal transform；它不是
谱 enclosure，也不能与 projected gap 组合成连续离散特征值存在性结论。

## 5. 三项负向诊断

producer 按冻结顺序保存三个 nonblocking warnings：

1. `WALL_ACTION_REFINEMENT_WARNING`：wall $256\to512$ relative change 为
   $0.23020558465752644>0.20$；这是 artifact 中的 first nonblocking warning。
2. `KERNEL_IDENTITY_QUALIFICATION_WARNING`：最大 manufactured relative error 为
   $1.4438757363102721$。误差只集中在 hypersingular $T$ oracle 的非零 Fourier modes；
   $S$、$D^\pm$、$dS$ 与 $-S\zeta$ jump-sign checks 均为机器精度。当前不能判定是单个 $T$
   oracle 的解析基准、符号/归一化，还是实际 $T(k_{\mathrm{out}})-T(k_{\mathrm{in}})$ difference
   block 有误；任何后续诊断都应先检查实际 difference block，不能据此改写本 artifact。
3. `CIRCLE_OUTSIDE_RETAINED_BAND_WARNING`：circle coefficient energy 在 $|\ell|>M$ 的 share 为
   $0.51468601513057144$，说明当前 $M=48$ 没有把这项内部表示压到冻结 $0.20$ 尺度内。512 个
   circle modes 全部进入 residual factors 与 $q$；这里的 $51.5\%$ 不是被截掉的 residual，
   而是 retained-band 表示的内部资格警告。

这些 warnings 按设计不阻止有限 $q$ 的计算，所以 `first_q_unavailable_condition=NONE`。它们
却明确阻止把普通双精度结果升级为经内部资格的 estimator，更不能称 reliable bound。

## 6. 最终边界与当前 blocker

本实验支持：在冻结 candidate、finite-density exact-kernel trial 定义和普通双精度实现下，
wall/circle/collar 三类 residual、full-$P$ tails、field normalization、$q$ 与名义区间均可计算、
可审计、可复算。它不支持：512 点数据已包住 continuous trial，$q$ 是连续谱误差上界，名义
区间中存在连续离散特征值，candidate 对应唯一真值，或该结果可充当 I3.2 独立 reference。

I3.2 当前尚未就绪，是因为 estimator 自身的三项内部数值资格仍未闭合：wall refinement 为
$23.0\%$，nonzero-mode $T$ oracle 有 $O(1)$ 误差，outside-$M$ share 为 $51.5\%$。最小后续
工作应先定位实际 $T(k_{\mathrm{out}})-T(k_{\mathrm{in}})$ difference block，再冻结 wall/circle
表示的内部资格；不得先把这个尚未冻结的 estimator candidate 送入独立经验验证，也不得通过
调阈值删除 warnings。

另一个独立问题是 outward numerical enclosure：residual upper、field lower、tail、continuous
projected gap 和预注册宽度条件都未认证。这些是 I3.3 研究 reliable interval、误差上界与 gap
内存在性时的 blocker，不是 I3.2 独立经验验证的逻辑前提。

当前 post-run verdict 为 `PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`。I3.1 保持
`ACTIVE / NUMERICALLY_UNQUALIFIED INDICATOR CANDIDATE`，I3.2 仍为 `NOT READY`。
