# I2.3 跨离散阶数 candidate 漂移独立审查

## 1. 审查对象与状态

- Design ID: `I2.3-NTOT-DRIFT-V1`
- Formal attempt: `drift-a1`
- Artifact verdict: `PASS WITH CONDITIONS`
- Frozen artifact classification: `DRIFT_UNRESOLVED / STOP_DRIFT_UNRESOLVED`
- Current scientific conclusion: `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`
- I3 gate: `DESIGN MAY BEGIN / NOT STARTED`
- Review date: `2026-08-14`

本审查只接受 [[test/i2/k-drift/README|I2.3 experiment index]] 作为实验统一入口；
implementation 文档不直接链接零散 MAT、report 或源码。冻结设计见
[[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 design]]。

### 2026-08-14 解释修订

冻结设计、runner 和 append-only output 不作追溯修改。它们把两个终端 cell 半宽相加后，
将 candidate difference 分类为 `DRIFT_UNRESOLVED`。当前复审明确区分：算法保存的 terminal-grid
candidate $\widehat k_n$、未精确计算的连续-$k$ score minimizer $k_n^{\min}$，以及终端 cell
半宽 $u_n$。后者只作 minimizer-localization/search-resolution diagnostic，不是 candidate
uncertainty，也不参与 $\Delta^{\mathrm{cand}}_{ab}=\widehat k_b-\widehat k_a$ 的定义。

## 2. 问题与成功标准

I2.3 只改变圆盘边界 Nyström 点数
$n_{\mathrm{tot}}\in\{160,208,256\}$，固定 $M=48$、$K=97$、fine proxy、物理参数、
branch、QZ frame、fixed rows、solver、窗口和 candidate functional。目标是判断同一物理 mode
的算法输出 candidate 是否发生观测漂移；不是精确求解 score minimizer，也不是证明 exact
finite root、continuous eigenvalue、收敛阶或误差上界。

接受 candidate 序列需要同时满足：

1. 三层 candidate、原矩阵 residual、factor、field、boundary 与 repeat gates 通过；
2. 两项相邻比较均为 `SAME_MODE`；
3. candidate 使用相同扫描参数和 winner 规则，并直接报告保存值之差。

terminal-cell 尺度只说明 locator 对潜在 sub-grid minimizer 的分辨率。它不能否定保存 candidate
之间已经观测到的差，也不构成 I3 的停止门。

## 3. 三方职责与过程

- Researcher 冻结唯一离散轴、physical $A_{\mathrm{phys}}$ functional、五点 dyadic locator、
  公共 wall/probe mode 表示、漂移与退出语义。
- Engineer 核对 `eval_i21` 能在固定 $M=48$ 与 fine proxy 下只改变 `ntot`，实现单入口
  `check_k_drift.m`，并在跑后独立复算 residual、mode 和 drift 数值。
- Skeptic 分别完成 design-only、implementation pre-run 与 post-run 独立审查；首次正式运行前
  blocker 为零后才授权唯一命令。

正式 MATLAB 运行只有一次，没有 retry、方法切换、窗口移动或阈值修改。运行耗时
`294.984 s`，peak active-object snapshot 为 `163.769 MiB`；均低于 `900 s` target、
`1800 s` hard limit 与 `512 MiB` memory gate。输出严格为 `result.mat` 和 `report.md`。

## 4. 三层 candidate

| $n_{\mathrm{tot}}$ | saved candidate $\widehat k_n$ | terminal half-width $u_n$ | $s_1$ | $\sigma_1/\sigma_2$ |
|---:|---:|---:|---:|---:|
| 160 | 1.832770289108157 | $9.3132279666\times10^{-11}$ | $5.6552567226\times10^{-11}$ | $1.1050964837\times10^{-10}$ |
| 208 | 1.832770289108157 | $9.3132279666\times10^{-11}$ | $5.6553421682\times10^{-11}$ | $1.1051131807\times10^{-10}$ |
| 256 | 1.832770289108157 | $9.3132279666\times10^{-11}$ | $5.6553167216\times10^{-11}$ | $1.1051082081\times10^{-10}$ |

每层恰好完成 12 个 locator layers、27 个唯一节点；终端 winner--runner-up score gap 约为
$1.947\times10^{-11}>10^{-12}$。三次 fixed-candidate repeat 的矩阵差与 score 差均为零，
$q$ overlap 约为一。repeat 只证明固定终端点可复算，不证明 winner ranking 对未建模 score
扰动稳定。

## 5. 最低非伪影诊断

三个 candidate 的 raw right/left residual 约为 $1.59\times10^{-10}$ 与
$2.97\times10^{-10}$；归一化 backward errors 约为 $5.21\times10^{-13}$，SVD triplet
residual 不超过 $8.46\times10^{-16}$。Dirichlet 与 Neumann defects 分别不超过
$7.6\times10^{-17}$ 与 $8.1\times10^{-19}$，kernel defect 约为 $6.42\times10^{-14}$。
center/graph participation 约为 $0.7071/0.5000$。全部直接相关 factors、branch、QZ、chart、
field 与 boundary gates 通过。

最紧 factor 的 `rcond` 仅为门槛约 `1.048` 倍，属于 important caveat。它没有造成当前
candidate failure，但任何未来高精度或不同离散轴实验都必须重新检查，不能继承本次余量。

## 6. Mode identity

两项相邻比较的 weighted wall-trace 与九点 probe-field overlaps 在存储精度下约为一；
primary--secondary competitor overlap 分别约为 $2.56\times10^{-13}$ 与
$4.28\times10^{-13}$，远低于 $0.5$。因此两项相邻关系均为 `SAME_MODE`，没有按 candidate
数值最近原则事后连接序列。

该结论只说明三个离散计算追踪到同一数值 mode；九点 probe 不是连续物理场同一性的完备
证明，也不把 I2.1 count-one 转移到 $n_{\mathrm{tot}}=160,208$。

## 7. Candidate 漂移、minimizer 尺度与最终 verdict

对所有三对 levels，算法实际交付的 candidate drift 均为

$$
\Delta^{\mathrm{cand}}_{ab}=\widehat k_b-\widehat k_a=0.
$$

三个计算使用完全相同的初始区间、五点 dyadic 网格、$L=0,\ldots,11$、27 个实际求值点、
terminal spacing、tie band、winner 规则、functional 和 solver。因此，保存 candidate 在小数点后
15 位完全相同；结合相邻层 `SAME_MODE`，当前科学结论为
`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。

终端 locator 区间为

$$
I_n^{\mathrm{term}}
=[1.8327702890150248,1.8327702892012891],
\qquad
u_n=9.3132279666\times10^{-11}.
$$

这个半宽是潜在连续-$k$ score minimizer $k_n^{\min}$ 的搜索分辨率/定位诊断，不是
$\widehat k_n$ 的 uncertainty。当前设计没有插值、单峰性、凸性或 enclosure 证明，因此它也
不是严格 minimizer error bound。它支持“candidate 位于观测极小值附近”，但不能与两个
candidate 的差相加后否定 observed candidate drift。当前仍只能把 sub-grid minimizer drift
标为 `SUBGRID_MINIMIZER_DRIFT_UNRESOLVED`。

独立审查还发现，三层共享全部 27 个 $k$ 网格点时，node score 的最大跨层变化仅约
$1.72\times10^{-15}$，candidate $A_{\mathrm{def}}^D$ 的相对 Frobenius 变化不超过
$3.71\times10^{-17}$，$A_{\mathrm{phys}}$ 不超过 $4.48\times10^{-16}$。这说明当前 double
对象对该 `ntot` 轴已接近机器精度饱和；它与 `NO_OBSERVED_CANDIDATE_DRIFT` 一致，但不能
升级为 sub-grid minimizer、finite root 或连续真值的零漂移证明。

最终判定：

- artifact：`PASS WITH CONDITIONS`；
- execution/evidence blocker：0；
- observed candidate result：`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`；
- minimizer diagnostic：`SUBGRID_MINIMIZER_DRIFT_UNRESOLVED`；
- I3：可开始误差来源与 independent-reference 设计，但该 `ntot` 轴不能单独提供非零
  next-level correction 或收敛证据。

## 8. 保留结论、失败边界与下一门

可以保留：三个通过全部最低门的 conditional finite-dimensional candidates、强
`SAME_MODE` 证据，以及“在完全相同扫描参数下没有观察到 candidate drift”。冻结 severe
门为 $10^{-6}$，本次 observed candidate drift 为零，因而没有观察到严重 candidate 漂移。

不能声称：sub-grid minimizer 零漂移、finite-root 零漂移、收敛阶、精确有限维 root、连续
guided mode、continuous eigenvalue、误差 estimator 或上界。I2.1 count-one 仍只附着于
完全相同的 $n_{\mathrm{tot}}=256$ fine parent。

本 attempt 必须 append-only 保留且不得同 tag 重跑。I3 可以接收当前 same-mode candidate
序列并开始误差来源识别；若某个 estimator 需要非零 next-level shift、精确 minimizer 或更细
搜索分辨率，必须在 I3 中另行说明并设计，不能反向改写 I2.3 candidate 结论。

## 9. Open caveats

- 当前数据无法识别潜在 sub-grid minimizer drift；
- $n_{\mathrm{tot}}=160,208$ 没有 I2.1 count-one；
- 三个 levels 不能给 convergence order 或误差上界；
- peak active-object snapshot 不是操作系统 RSS；
- continuous projected-gap mapping、kernel--field bridge 与 continuous--discrete error control
  仍是最终物理提升和后验误差上界的独立开放问题。
