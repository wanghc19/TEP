# I3.1 实验设计门与当前完成情况

本页不是实验设计，也不授权 MATLAB 运行。它记录首个设计需要关闭的门，以及
[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 和 `center-a1` 实际关闭到
哪一层。

## 必须先关闭

1. **Continuous form contract。** 明确 $H$、$V$、$a(\cdot,\cdot)$、质量内积、
   $\lambda=k^2$、$\gamma$、norm 和 field normalization。
2. **Residual object。** 首个设计固定 global-field residual，不把 exact-DtN center
   residual 的未控项混入；后者若另行启用，必须先给出到 global form residual 的稳定
   extension/lifting 关系。
3. **Field reconstruction。** 给出从 I2 数据到非零 conforming $u_h^{\mathrm c}\in V$ 的
   确定性算法；若先得到 broken field，给出 jump 与 repair。
4. **Residual decomposition。** 列出 volume、material interface、cell/port、quasi-periodic、
   tail/cutoff 和 reconstruction terms，并明确未覆盖项。
5. **Computable dual norm。** 给出 Riesz problem、离散空间、quadrature、refinement 和
   stopping rule；说明其结果是 approximation、lower estimate 还是 reliable upper estimate。
6. **Numerical separation。** 给出 field evaluation、quadrature、Riesz solve、linear solve、
   repeat 和 floating-point allowance；信号被淹没时 fail close。
7. **两层解释合同。** 预先写明当前连续算子在 $\lambda=k^2$ 尺度上的 projected essential
   gap 候选、其证明状态、可靠 residual interval 的 outward enclosure，以及在看结果前由下游
   科学需求确定的 $\tau_k^{\mathrm{pre}}$ 和 $0<\rho_G^{\mathrm{pre}}<1$，并要求
   $\tau_k^{\mathrm{pre}}\le
   \rho_G^{\mathrm{pre}}\operatorname{diam}(G_k)$，其中
   $G_k=(\sqrt{g_-},\sqrt{g_+})$。两项尺度都必须由下游精度和非空泛性理由预注册，而不只是
   机械选择一个略小于一的比例。gap 尚未证明不阻止 residual 计算，但必须使
   continuous discrete-eigenvalue existence claim unavailable；唯一目标识别不属于第一层门。
## 首个设计应保存的最小量

- saved candidate $\widehat k_h$ 与 $\mu_h=\widehat k_h^2$；
- continuous form/norm contract 和 reconstruction parameters；
- reconstructed field norm 与 nonzero check；
- 每个 residual component 及其合成值；
- Riesz representative、dual-norm approximation 和 refinement history；
- quadrature/solve/repeat allowance；
- covered/ignored terms；
- continuous projected-gap contract、gap-edge margin、可靠 $\lambda$/$k$ 区间、预注册
  $\tau_k^{\mathrm{pre}}$、$\rho_G^{\mathrm{pre}}$ 与 absolute/gap-relative 区间宽度；
- `CONTINUOUS_RESIDUAL_ESTIMATOR_CANDIDATE`、`PARTIAL_RESIDUAL_ONLY`、
  `CONTINUOUS_RESIDUAL_UNRESOLVED`、`PROJECTED_GAP_NOT_ESTABLISHED`、
  `CERTIFIED_INTERVAL_CROSSES_GAP_EDGE`、`EXISTS_BUT_RESOLUTION_INSUFFICIENT`、
  `EXISTENCE_WITH_TARGET_UNRESOLVED` 或明确的 implementation failure。

设计还必须预注册 non-circular checks：exact/manufactured field、故意 interface jump、故意
tail omission、错误 candidate 和过小 Riesz space。它们是设计内容，不是创建设计前必须先
得到结果的理论门。

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

`CENTER STRONG-RESIDUAL BASELINE COMPLETE / RESOLUTION INSUFFICIENT`。`design-3-1` 对中心
空列特殊情形明确了 continuous operator/domain、紧支撑场、完整强残量三项、普通 Simpson
数值检查和解释边界；正式 ratio 为 $22.43882099031153$。它关闭了“是否能从 I2 数据构造一个
真正 continuous-domain trial field 并计算 residual”这一最低门，但没有关闭：

- cutoff defect 更小且具有项目分辨率的 reconstruction/residual；
- residual numerator 的可靠上界与 field norm 的可靠下界；
- 当前 sharp-disk projected gap；
- I3.2 所需的可验证 estimator。

因此后续 design 仍须单独冻结。原 common-space、finite-root、matrix-derivative blockers 继续
不属于主线。
