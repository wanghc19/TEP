# I3.1 Q1--RT0 弱残量实验独立审查

## 审查结论

- Schema：`TEP_I3_1_Q1_RT0_WEAK_RESIDUAL_V2`
- 正式数值 attempt：`weak-a1`
- producer 状态：`I3_1_MAJORANT_QUADRATURE_UNRESOLVED`
- 独立 verdict：`POST-RUN PASS / VALID NEGATIVE`
- I3.1 状态：继续活动；尚无 estimator，I3.2 不可开始

本审查只通过 [[test/i3/w-resid/README|Q1--RT0 experiment index]] 消费正式数值证据。
[[research/projects/eig-apost/implementation/i3/design-3-1b|冻结设计]]、MATLAB 源码和
append-only output 均保持原样。producer 按预注册失败顺序在第一个未通过门停止；运行本身
完成，负结果可消费。

## 1. 检查对象与正式运行

实验固定 I2 保存的 candidate

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2=3.3590469326375971,
$$

以及 $n_{\mathrm{tot}}=256$、$M=48$ 的离散输入，不重新扫描或调整 $k$。它从 frozen QZ wall
traces 构造全波导 conforming Q1 trial，以全局 RT0 flux 形成 continuous weak residual 的
functional-majorant candidate，并预注册 ordinary-double 的两层网格、full-$P$ tail、
phase/scale 与 refinement 检查。

正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','w-resid'),fullfile(pwd,'test','i2','k-count')); check_w_resid('weak-a1');"
```

运行用时 $22.5326065$ s，peak active-object memory 为 $341.8422213$ MiB，低于
$900/1800$ s 和 $512$ MiB 资源门；`retry_count=0`。append-only 输出只含 `result.mat` 与
`report.md`。

## 2. 首败前通过的检查

finite input、左右传播、两层 Q1 cell solve、全局 $H^1$ 拼接、RT0 normal continuity、base
Gram 与 full-$P$ tail 均先于首败通过。关键原始量为：

- physical score $5.6553167\times10^{-11}$，near-null ratio
  $1.1051082\times10^{-10}$，raw residual $3.1457643\times10^{-10}$，raw backward error
  $5.2067133\times10^{-13}$；
- 最紧输入 factor rcond $1.0481727\times10^{-8}$，最大输入 factor residual
  $3.1283225\times10^{-8}$；
- 左右 propagation rank 均为 $97$，thin-QR rcond 约 $0.497733$，solve/invariant residual
  至多 $6.24\times10^{-16}$；
- coarse/fine cell factor rcond 最低分别为 $8.28\times10^{-5}$ 与
  $3.68\times10^{-5}$，逐右端 solve residual 至多 $4.34\times10^{-14}$；
- coarse/fine form defects 至多 $3.42\times10^{-16}$，RT0 defects 至多
  $3.26\times10^{-15}$，材料圆面积相对误差至多 $4.20\times10^{-15}$；
- 两层左右 full-$P$ tail 均在 $N=8$ 通过，最大 tail share 约
  $2.65\times10^{-9}<10^{-6}$。

这些通过只说明首败以前的实现对象满足各自的 ordinary-double 门，不把有限 QZ 或 Q1 场
升级为连续特征函数。

## 3. 精确首败

fine 网格的独立 phase/scale repeat 使用

$$
\alpha=10^8\exp(\mathrm{i}\pi/7).
$$

缩放后的 cell solves、form conformity、RT0 continuity 和 finite-value 检查仍通过，但 per-cell
Gram 的 Hermitian defect 超过预注册 $10^{-12}$。按 $(N,A,B)$ 顺序，失败对象为：

| Cell object | Hermitian defects | 最小特征值 |
|---|---|---|
| center | $(3.33\times10^{-15},\ 6.24\times10^{-10},\ 2.75\times10^{-11})$ | $(7.00\times10^{16},\ 1.40\times10^{12},\ 1.59\times10^{12})$ |
| first minus | $(1.70\times10^{-15},\ 8.45\times10^{-12},\ 5.79\times10^{-14})$ | $(5.25\times10^{16},\ 5.01\times10^{12},\ 6.88\times10^{15})$ |
| first plus | $(3.08\times10^{-16},\ 3.67\times10^{-11},\ 6.11\times10^{-14})$ | $(5.25\times10^{16},\ 5.01\times10^{12},\ 6.20\times10^{15})$ |

所有列出的最小特征值均为正；tail Gram 的 Hermitian defects 至多
$9.94\times10^{-15}$，其仅为舍入量级的微小负特征值也在 PSD tolerance 内。因此首败是
scaled center 的 $A,B$ Gram 及左右 first-cell 的 $A$ Gram 的 Hermitian qualification，不是
PSD 符号失败。producer 正确
返回 `MAJORANT_QUADRATURE_UNRESOLVED`。

将已经保存的对称化 Gram 除以 $|\alpha|^2$ 后与未缩放 fine 值比较，center $A$ 的相对变化
仍为 $7.43\times10^{-10}$。这是运行后补充的、未预注册的 Gram covariance 诊断；预注册
$10^{-11}$ 门针对最终 $q$ 的 phase/scale relative defect，而该门因更早的 Hermitian 首败没有
执行。因此这里只能说明不能跳过首败并假定后续 $q$ 门会通过；它本身不判定 $q$ 门失败。
下一次设计必须先建立 scale-covariant Gram qualification。

## 4. 未资格化的后续诊断

base coarse/fine totals 在首败前已计算，但没有通过完整 phase/scale 与 refinement 链，因此
只能作为定位下一门的诊断：

| Level | computed $q$ | nominal $k$ interval | width |
|---|---:|---:|---:|
| coarse | $0.1791563243$ | $[1.5291587419,\ 2.1966633290]$ | $0.6675045871$ |
| fine | $0.1520175357$ | $[1.5724321930,\ 2.1362109906]$ | $0.5637787976$ |

即使未来关闭 scale/phase 首败，base 两层的 $B/\gamma$ component change 约为 $0.277$，已高于
$0.20$ refinement 门；fine nominal width 又远大于预注册 $10^{-6}$ 绝对分辨率。因此
mesh qualification 和有用 interval width 仍是后续独立 blocker，不能把修复 Gram 当成已经
得到 estimator。

本 attempt 没有形成 scaled tail、scaled total、refinement 或最终 estimator；coverage flags、
`continuous_form_residual_computed` 和 `functional_majorant_formula_applied` 均保持 false。

## 5. 允许与禁止的结论

可以保留：

- frozen candidate、finite input、frozen-$P$ propagation 与 base Q1--RT0 reconstruction 通过
  首败前各自的 ordinary-double 检查；
- base full-$P$ tails 很小，且 coarse/fine base totals 为下一次设计提供负向分辨率诊断；
- `weak-a1` 在资源预算内、无 retry、按预注册顺序停止，是 `POST-RUN PASS / VALID NEGATIVE`；
- 当前真正的下一门是 scale-covariant Gram qualification，之后仍须面对 mesh 与 width 门。

不能主张：

- 已交付 continuous weak-residual estimator candidate；
- ordinary-double majorant 已是 residual dual-norm 的可靠上界；
- 已得到 projected gap 内谱区间、连续离散特征值存在性或指定 mode 身份；
- I3.2 可以开始，或本次负结果授权结果后修改 scale、Gram、mesh、阈值并重跑；
- 已获得 candidate 到连续谱的误差估计或上界。

Skeptic 的 post-run verdict 为 `PASS`：接受 artifact、首败优先级和 valid-negative 解释；I3.1
继续为 `ACTIVE / NO ESTIMATOR`。后续问题统一维护在
[[research/projects/eig-apost/implementation/open-problems|open-problem ledger]]。
