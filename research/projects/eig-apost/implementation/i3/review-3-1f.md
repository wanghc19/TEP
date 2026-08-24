# I3.1 全边界胞元 BIE 弱残量实验独立审查

## 审查结论

- Design ID：`I3.1-FULL-BOUNDARY-CELL-BIE-V1`
- 正式 attempt：`fbie-a1`，已消费，禁止同 tag 重跑
- producer 状态：`I3_1_COMPUTED_NUMERICALLY_UNQUALIFIED_FULL_BOUNDARY_BIE_INDICATOR`
- 独立 verdict：`POST-RUN PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`
- I3.1 状态：已有可计算 indicator candidate；circle action 内部资格未闭合，I3.2 尚不可开始

本审查通过 [[test/i3/fb-resid/README|full-boundary experiment index]] 消费 append-only artifact。
冻结 [[research/projects/eig-apost/implementation/i3/design-3-1f|design-3-1f]]、MATLAB 源码和
正式 output 均不再修改。该结果说明冻结边界对象可计算、可复算；它不说明数值区间已经包住
连续谱误差。

链接的 design 保持正式运行时的 byte-identical 预注册快照，SHA-256 为
`9077311ff06b6f2b7a48897cc4519a65341c1f3f4bf9ea2401e29923a40219bb`。其中 `NOT AUTHORIZED`、
output 不存在等语句记录的是**跑前合同**；本审查与当前状态入口记录已消费的跑后状态，二者不得
混作同一时态。

## 1. 数学对象与本轮变化

实验固定 I2 保存的

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2=3.3590469326375971.
$$

$M=48$ **只**定义 center/lead 共享 total Dirichlet wall trace 的输入 Fourier modes；wall response
使用独立的 $256/512$ 阶表示，材料圆 density/action 也独立使用 $256/512$ 点。左右 wall
single-layer densities 与材料圆 Müller densities 共同定义 finite-density、continuous exact-kernel
trial；显式 wall strips 和 circle collar 修复 value traces。wall normal jump、circle normal jump 与
全部 value-lift volume sources 形成三个 residual 分量，再通过完整 $P_\pm$ 矩阵的 ordinary-double
tails 归一化。

这仍与先前 rectangular Dirichlet-wall Green 路线共享连续 Schur 对象，不是 I3.2 独立方法。
本轮的价值是把 $M=48$ 输入与完整 wall/circle response 解耦，并用实际
$T(k_{\mathrm{out}})-T(k_{\mathrm{in}})$ difference block、公共 wall grid 和全部 512 个已计算
circle modes 做内部资格检查。

## 2. 正式运行与 artifact

唯一命令已经消费：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','fb-resid'),fullfile(pwd,'test','i2','k-count')); check_fb_resid('fbie-a1');"
```

shell exit code 为 0，`retry_count=0`，`prior_failed_attempt_count=0`。用时
$80.671210875$ s，peak active-object memory 为 $373.645583152771$ MiB；未触发 $900$ s soft
limit，也未触发 $1800$ s 或 $640$ MiB hard limit。正式目录只含两个 artifact：

- `result.mat`：`276d1c52ed4ca6f522c47359e22771a63d23a8d9b5b5ca0443d32f66417b1592`；
- `report.md`：`f4983741c39f44be3edf3e1d75c239cbbb5a182c9c2690f85350549679e11f63`。

消费时的源码与设计 SHA-256 为：entry
`225927c0d6a057c5a22c311cc0b2c35d64b6435ca5fd3bca65f3be10e0b4103c`，full-boundary helper
`2ba7a060bffe61a857d0f98d2f78159d2afaded42028f8f3c2311bf073a1597b`，boundary/tail helper
`954c3068c4d89770ffd02312591acbaa682aabe2aaa73cc3bcb0ac04e55d6007`，设计
`9077311ff06b6f2b7a48897cc4519a65341c1f3f4bf9ea2401e29923a40219bb`。

## 3. 指标候选和独立复算

| 数值对象 | 普通双精度结果 |
|---|---:|
| wall residual component | $1.8732026085453917\times10^{-10}$ |
| circle residual component | $2.9776880587814564\times10^{-15}$ |
| value-lift volume component | $4.246327820844503\times10^{-11}$ |
| triangle sum | $2.29786516751043\times10^{-10}$ |
| field lower candidate | $2.2269063318145634$ |
| normalized $q$ | $1.0318643108971929\times10^{-10}$ |

冻结代数变换给出名义 $k$ 区间

$$
[1.83277028891904, 1.8327702892972739],
$$

宽度为 $3.7823388865376728\times10^{-10}<10^{-6}$。独立只读复算直接从保存的 factors、
$P_\pm$、states 和 center singleton maps 重建两侧 $N=8$ 有限和；与 artifact tail sums 的最大
相对差为 $3.8629845030380475\times10^{-16}$。重算三个分量、field、$q$ 和两个区间端点与
artifact 一致。

左右 tail 都选择 $N=8$，最大 share 分别约为 $2.6445\times10^{-9}$；全部低于冻结
$10^{-6}$ 门，且没有 roundoff-negative contraction。phase/scale repeat defect 为 0。producer
保存了前四层 state/action，但没有把显式 off-by-one 复算作为 machine gate；独立 post-run
复算的相应最大相对差不超过 $2.72\times10^{-16}$。这是 minor implementation caveat，不改变
本 attempt 的首个资格失败。

## 4. 唯一内部资格失败

唯一 nonblocking warning 是

```text
CIRCLE_ACTION_WARNING = 0.77408786032496468
```

它来自同一 official wall state 和同一 finite density 的 circle residual action：把 256 点 action
按冻结三角插值映射到 512 点后，与独立 512 点 action 比较。保存的原始量为：

- 差的 Frobenius numerator：$3.8218614403582282\times10^{-13}$；
- 512 点 action norm：$4.9372450289477451\times10^{-13}$；
- 插值后的 256 点 action norm：$4.0739337915931895\times10^{-13}$；
- scale-covariant ratio：$0.77408786032496468>0.20$。

official 512 点 action 的 value/normal norms 分别为
$5.8666324155782418\times10^{-14}$ 和 $4.9022662837584686\times10^{-13}$，所以其尺度主要由
normal-jump 行贡献；artifact 没有保存 256--512 **差**的 value/normal 分项 numerator，因此
不能进一步宣称 warning 本身由哪一行主导。该门按预注册语义 fail-open：有限 $q$ 和名义代数
变换仍保存，但 estimator 不能冻结并交给 I3.2。

没有第二项内部资格失败。circle angular-tail ratio 为 $0.17504911539587287<0.20$；actual
$\Delta T$ defect/reference change 分别为 $0.022863669166056137$ 与
$0.0064954552541407629$；proxy、coarse/official Schur solves、manufactured signs、wall modal、
Bloch、value repairs、Grams、tails、phase/scale 和预注册宽度检查均通过。

circle normal-jump weighted energy 在 $|\ell|>M$ 的 share 为
$0.036178900402764308$，即 $3.6179\%$。这是描述性诊断，不是资格门；所有 512 个已计算
circle modes 均进入 residual factors 和 $q$，没有把这 $3.6179\%$ 截掉。circle angular-tail
gate 已通过；未计算的 Fourier tail 仍未 enclosure，留给 I3.3。

## 5. 结论边界与下一门

本 attempt 支持：full-boundary finite-density trial、显式 value repairs、三个 residual 分量、
full-$P$ tails、field normalization、$q$ 和名义区间在普通双精度中可计算并可复算。它不支持：
512 点 action 已向外包住 continuous trace、$q$ 是 empirical eigenvalue-error estimator、名义区间
是可靠谱 enclosure、区间内存在连续离散特征值，或 candidate 已对应唯一真值。

`continuous_H1_numerically_enclosed=false`、`continuous_jump_enclosed=false`，全部 reliability、
independent-reference 和 existence flags 都是 false。I3.2 当前唯一直接 blocker 是 circle action
$256\to512$ 内部资格失败；先诊断并重新冻结该 action 的分辨率合同，才能冻结 estimator 后做
独立经验验证。residual/field/tail outward enclosure、certified projected gap 与可靠区间宽度
属于 I3.3 的存在性和误差上界条件，不是 I3.2 前置条件。

最终 verdict 为 `POST-RUN PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`。`fbie-a1` 是
有效、已消费的正式结果，不得同 tag 重跑，也不得通过改阈值或追溯修改 output 删除 warning。
