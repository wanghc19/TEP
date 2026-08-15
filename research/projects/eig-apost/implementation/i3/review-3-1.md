# I3.1 中心空列强残量实验审查

## 审查结论

- Design ID：`I3.1-CENTER-STRONG-RESIDUAL-V1`
- 正式 attempt：`center-a1`
- 执行 verdict：`PASS`
- 科学 verdict：`PASS WITH CONDITIONS / FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`
- I3.1 状态：继续活动；本次 baseline 完成，但尚未得到可用于 I3.2 的 estimator

本审查只通过 [[test/i3/s-resid/README|I3.1 experiment index]] 进入数值证据。冻结的
[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]]、MATLAB 入口和
append-only output 均不作追溯修改。

## 1. 检查的连续对象

固定 I2 保存的 candidate

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2=3.3590469326375971.
$$

实验从同一 fine $n_{\mathrm{tot}}=256$、$M=48$ evaluator 的 physical-weighted 最小右奇异
向量得到中心墙系数 $q=(q_L,q_R)$。这些系数在 homogeneous empty center column 中给出有限
Rayleigh/Fourier 场 $u_0$。固定

$$
\chi(x)=\cos^2(\pi x),\qquad |x|\le1/2,
$$

并在区间外令其为零。因为 $\chi=\chi'=0$ 于两个端点，
$u_h^{\mathrm c}=\chi u_0$ 的零延拓属于连续算子的定义域。对 stored double-precision
$\gamma_m$，逐模残量保留了全部三项

$$
-\chi''\phi_m-2\chi'\phi_m'
+\chi(\beta_m^2+\gamma_m^2-\mu_h)\phi_m.
$$

所以本次计算的不是有限矩阵 residual，而是该紧支撑连续场的 strong residual。若 norms 精确
可得，自伴谱定理给出

$$
\operatorname{dist}(\mu_h,\sigma(A))
\le
\frac{\|(A-\mu_h)u_h^{\mathrm c}\|_H}{\|u_h^{\mathrm c}\|_H}.
$$

## 2. 数值结果

| Quantity | Result |
|---|---:|
| $\|u_h^{\mathrm c}\|_H$ | $0.840017038309255$ |
| $\|(A-\mu_h)u_h^{\mathrm c}\|_H$ | $18.848991951433035$ |
| computed $\lambda$-scale ratio | $22.43882099031153$ |
| $\|{-\chi''u_0}\|_H$ | $17.144386396694575$ |
| $\|{-2\chi'\partial_xu_0}\|_H$ | $4.9283050359497285$ |
| stored-$\gamma$ dispersion component | $1.2992598309180477\times10^{-17}$ |

Composite Simpson 的 $512,1024,2048$ 子区间结果依次为

$$
22.438820995214055,\quad
22.438820990599893,\quad
22.43882099031153.
$$

最后两层相对变化为 $1.285108\times10^{-11}<10^{-10}$；对
$10^8e^{\mathrm i\pi/7}q$ 的 phase/scale test defect 为零。普通双精度 Simpson ladder 只说明
数值稳定，不提供积分误差的可靠上包络。

## 3. 为什么结果没有形成存在区间

正式 machine status 为
`I3_1_CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE`，首个严格升级失败条件为
`RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE`。当前 sharp-disk continuous projected essential
gap 也未认证，所以 gap containment、gap 内离散特征值存在、分辨率和唯一目标均为
`NOT_REACHED`。

此外，当前值本身已经显示 reconstruction 缺乏目标分辨率。若只为观察尺度而把 computed ratio
代入对称区间，会得到未经认证的

$$
[\mu_h-\eta_h,\mu_h+\eta_h]
=[-19.079774057673934,25.797867922949127].
$$

它的下端为负，不能按设计映射成正频率区间，更不可能接近预注册的
$\tau_k^{\mathrm{pre}}=10^{-6}$。因此本审查增加当前科学解释
`FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`；这不改变历史 machine field。

这个负结果的原因有数值证据区分：stored-$\gamma$ dispersion 项约为 $10^{-17}$，而两个 cutoff
导数项分别约为 $17.14$ 和 $4.93$。大 residual 来自预注册的单胞 cutoff，而不是遗漏色散项、
branch arithmetic 或有限矩阵输入失败。

## 4. 输入质量与资源

输入 point 的 physical score 为 $5.655317\times10^{-11}$，near-null ratio 为
$1.105108\times10^{-10}$；raw right/left backward errors 为
$5.206716\times10^{-13}$ 和 $5.201377\times10^{-13}$。graph Dirichlet、Neumann 和 kernel
defects 分别为 $3.642592\times10^{-17}$、$5.032372\times10^{-19}$ 和
$6.419460\times10^{-14}$。

最紧 factor 的 rcond 为 $1.0481727489\times10^{-8}$，只比 $10^{-8}$ 门高约 $4.82\%$。
它通过本次门，但不能被未来不同参数或 precision 无条件继承。

正式命令为：

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','s-resid'),fullfile(pwd,'test','i2','k-count')); check_s_resid('center-a1');"
```

实际 wall time 为 $12.783586$ s，peak active-object snapshot 为 $85.503675$ MiB；均低于
$60/180$ s 和 $256$ MiB 预算。正式 attempt 无失败、无 retry，输出目录只含 `result.mat` 与
`report.md`。

## 5. 可以保留与不能主张的结论

可以保留：

- 从 I2 wall coefficients 到一个非零 continuous-domain compact-support trial field 的确定性构造；
- 作用于 continuous self-adjoint operator 的 strong-residual 公式；
- 一个可复现且数值稳定的 computed residual baseline；
- single-cell cutoff 对当前目标缺乏分辨率的可证伪负结果。

不能主张：

- 普通 Simpson 数值是可靠 residual upper bound；
- 上述 nominal interval 含有一个 continuous discrete eigenvalue；
- candidate 附近存在 guided eigenvalue、唯一 mode 或指定 $k_*$；
- 当前值是 continuous-eigenvalue error estimator、误差上界或收敛证据。

## 6. 当前 blocker 与最小后续路线

当前 I3.1 blocker 是：尚无一个既保持 continuous conformity、又把人工 cutoff defect 压到预注册
分辨率附近的 reconstruction/residual estimator candidate。继续给同一个宽 baseline 做严格
Simpson enclosure 或优先认证 projected gap，不会改变它缺乏分辨率的事实，因而不是下一项最低
成本工作。

若继续 I3.1，应另行冻结一个能减少人工 cutoff defect 的 lead-aware reconstruction 或回到 weak
residual，并重新审查覆盖项和数值误差。只有新指标先显示足够分辨率，才值得进入 I3.2 独立
reference 验证；reliable numerical enclosure 和 projected-gap certification 则保留为更强存在性
或上界结论的后续门。
