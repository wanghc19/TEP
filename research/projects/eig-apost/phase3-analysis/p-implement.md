# I3.1 实验设计门与当前完成情况

本页不是实验设计，也不授权 MATLAB 运行。它记录设计需要关闭的门，以及
[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 和 `center-a1` 实际关闭到
哪一层；新路线的冻结参数见
[[research/projects/eig-apost/implementation/i3/design-3-1b|design-3-1b]]。

## 必须先关闭

1. **Continuous form contract。** 明确 $H$、$V$、$a(\cdot,\cdot)$、质量内积、
   $\lambda=k^2$、$\gamma$、norm 和 field normalization。
2. **Selected strong-residual object。** 首个设计使用
   [[research/projects/eig-apost/phase3-analysis/s-lead-field|BIE-informed global conforming trial]]
   和 continuous strong residual；不把 exact-DtN center residual 或 broken BIE jump samples
   混成 total residual。只有退回一般 weak residual 时，才需要 Riesz dual-norm solve。
3. **Density 和 field signs。** 核对 circle-only $D_rA_{\mathrm{raw}}D_c$ scaling、
   $\eta=(\tau,-\sigma)^{\mathsf T}$、interior/exterior potentials 及其 global-$x$ gradients。
   scaling gate 失败时输出 `DENSITY_REPRESENTATION_UNRESOLVED`。
4. **Fixed linear reconstruction。** 冻结 wall Hermite data、bubble basis、BIE sample/holdout
   grids、value/derivative weights、full-rank fit 和 center correction。最终 field 必须在 disk
   内外使用同一个 smooth function；raw BIE 分片场只作 shape data。
5. **Frozen propagation 和 infinite tail。** 只用同一点 frozen $Z_\pm,A_{\mathrm{sc}},
   B_{\mathrm{sc}}$ 恢复 $P_\pm$，保存 rank/condition/invariance residual。对 field、residual 和
   $H^2$ Gram 分别冻结 doubling、$1-\|P^N\|_2$ 的 floating/repeat margin 及 two-sided tail
   allowance；失败时输出 `INFINITE_TAIL_UNRESOLVED`。
6. **Residual decomposition 和 integration。** 用 rectangle background integral 加 disk-polar
   contrast correction 计算实际 $\rho$ 下的 field/residual norm；列出 BIE fit、center
   correction、finite basis、left/right tail、quadrature 和 floating allowances。固定 fit
   未解析时输出 `CONFORMING_RECONSTRUCTION_UNRESOLVED`。
7. **Numerical separation。** 给出 field evaluation、geometry-fitted quadrature、linear fit、
   matrix power、Gram accumulation、repeat 和 floating-point allowance；信号被淹没时 fail
   close。普通 quadrature 只给 estimator candidate，不自动给 reliable enclosure。
8. **两层解释合同。** 预先写明当前连续算子在 $\lambda=k^2$ 尺度上的 projected essential
   gap 候选、其证明状态、可靠 residual interval 的 outward enclosure，以及在看结果前由下游
   科学需求确定的 $\tau_k^{\mathrm{pre}}$ 和 $0<\rho_G^{\mathrm{pre}}<1$，并要求
   $\tau_k^{\mathrm{pre}}\le
   \rho_G^{\mathrm{pre}}\operatorname{diam}(G_k)$，其中
   $G_k=(\sqrt{g_-},\sqrt{g_+})$。两项尺度都必须由下游精度和非空泛性理由预注册，而不只是
   机械选择一个略小于一的比例。gap 尚未证明不阻止 residual 计算，但必须使
   continuous discrete-eigenvalue existence claim unavailable；唯一目标识别不属于第一层门。
## 首个设计应保存的最小量

- saved candidate $\widehat k_h$ 与 $\mu_h=\widehat k_h^2$；
- continuous form/norm contract、frozen wall orientation 和 reconstruction parameters；
- density scaling/sign checks、$P_\pm$ rank/condition/invariance residual 和 center-correction
  ratio；
- reconstructed field norm 与 nonzero check；
- BIE fit/holdout diagnostics，以及 field/residual/$H^2$ Grams；
- 每个 residual component、left/right doubling history、tail bounds 及其合成值；
- geometry-fitted quadrature、solve/repeat/floating allowance；
- covered/ignored terms；
- continuous projected-gap contract、gap-edge margin、可靠 $\lambda$/$k$ 区间、预注册
  $\tau_k^{\mathrm{pre}}$、$\rho_G^{\mathrm{pre}}$ 与 absolute/gap-relative 区间宽度；
- `CONTINUOUS_RESIDUAL_ESTIMATOR_CANDIDATE`、`PARTIAL_RESIDUAL_ONLY`、
  `CONTINUOUS_RESIDUAL_UNRESOLVED`、`PROJECTED_GAP_NOT_ESTABLISHED`、
  `CERTIFIED_INTERVAL_CROSSES_GAP_EDGE`、`EXISTS_BUT_RESOLUTION_INSUFFICIENT`、
  `EXISTENCE_WITH_TARGET_UNRESOLVED` 或明确的 implementation failure。

设计还必须预注册 non-circular checks：exact/manufactured polynomial、bubble-order-zero
baseline、故意错误的 left derivative sign、故意 tail omission、错误 candidate 和
phase/scale transform。它们是设计内容，不是创建设计前必须先得到结果的理论门。

这些字段只服务公式复算和失败解释。不得同时实现 finite-root locator、production matrix
derivative、通用跨维 transport、复杂 provenance framework 或与 residual 无关的结构证明。

## 不再是 readiness gate

- nearby finite determinant zero 的存在、实性或简单性；
- finite left/right null vectors 与 bordered conditioning；
- production matrix $k$ derivative 与 transverse slope；
- common finite-matrix prolongation/restriction 或 exact Schur zero equivalence；
- exact finite Hermitian/Lagrangian identity；
- continuous eigenvalue 的唯一身份、multiplicity-one、certified dual-norm upper bound 和
  无未知常数 target-specific enclosure。

唯一目标识别和 target-specific enclosure 属于可选第二层/I3.3；其失败不撤销 gap 内存在性。
certified dual-norm upper bound 只在生成 reliable interval 时成为相应结论的门。其余
finite-matrix 条件只在启用 OPTIONAL correction 时恢复为局部门槛。

## 当前裁决

历史 baseline 仍是 `CENTER STRONG-RESIDUAL BASELINE COMPLETE / RESOLUTION INSUFFICIENT`。
`design-3-1` 对中心
空列特殊情形明确了 continuous operator/domain、紧支撑场、完整强残量三项、普通 Simpson
数值检查和解释边界；正式 ratio 为 $22.43882099031153$。它关闭了“是否能从 I2 数据构造一个
真正 continuous-domain trial field 并计算 residual”这一最低门，但没有关闭：

- 通过 BIE-informed reconstruction 门后的全波导 continuous residual 与实测分辨率；
- residual numerator 的可靠上界与 field norm 的可靠下界；
- 当前 sharp-disk projected gap；
- I3.2 所需的可验证 estimator。

全局 trial 的路线级数学对象、$D(A)$ 归属、strong residual 和 tail formula 已完成独立审查；
`design-3-1b` 已按本页冻结参数和 fail-close margin，完成实现、spec-to-code 审查和正式
`lead-a3`。finite input、density representation 与 propagation 通过；固定 fit 的 $J=4/8$
holdout error 约为 $4.522421/5.138028$，因而在
`CONFORMING_RECONSTRUCTION_UNRESOLVED` 停止。center correction、Grams、quadrature、tail 与
residual ratio 均为 `NOT_REACHED`。

本次 targets 到材料圆仅约为 source-panel arc scale 的 $0.86\%/1.08\%$，direct close
layer-potential evaluation 尚未资格化。因此当前 blocker 是“BIE-informed shape quality 未建立，
且近奇异评价与 basis/metric 原因未区分”，不是已经证明 bubble basis 失败。不得自动调节
basis/grid/阈值或启动新 attempt。独立结论见
[[research/projects/eig-apost/implementation/i3/review-3-1b|review-3-1b]]。原 common-space、
finite-root、matrix-derivative blockers 继续不属于主线。
