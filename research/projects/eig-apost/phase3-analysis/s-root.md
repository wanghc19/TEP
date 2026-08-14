# Saved candidate、gap 内存在性与唯一目标

## 1. 必须分开的对象

I3.1 同时涉及四个不同对象：

1. $\widehat k_h$：I2 的固定算法实际保存的实数 candidate；
2. $I_h^\lambda$：由可靠 continuous weak-residual bounds 构造的连续谱区间；
3. $\lambda\in\sigma(A)$：residual 命题保证落在该区间中的某个连续谱点；
4. $\lambda_*=k_*^2$：只有完成额外身份识别后才能命名的特定连续特征值真值。

score minimizer 和 finite determinant zero 不在这条主链中。I3.1 直接把
$\mu_h=\widehat k_h^2$ 代入连续弱方程。

## 2. 第一层：projected gap 内至少存在一个离散特征值

设 $A=A^*\ge0$ 是固定 Bloch 参数后的连续物理算子，并已针对当前 sharp-disk 模型证明

$$
G_\lambda=(g_-,g_+),
\qquad 0<g_-<g_+,
\qquad
G_\lambda\cap\sigma_{\mathrm{ess}}(A)=\varnothing.
$$

这里的 projected gap 必须属于该连续算子的本质谱，而且 $g_-$ 与 $g_+$ 必须是已证明位于
真实间隙内的 inner bounds；有限矩阵的 QZ separation、I2.1 的小圆盘 count 或其他材料
profile 的 band gap 都不能代替。若可靠 residual interval 满足

$$
I_h^\lambda\subset G_\lambda,
$$

则其中至少存在一个不属于本质谱的连续谱点，因而是孤立、有限重的离散特征值。这里采用
Weyl/Fredholm essential-spectrum 约定。Fliss (2013), Proposition 3.3（本地原文 PDF p. 8）
对 fixed-$\beta$ 波导给出同一 gap 内离散谱结论；当前项目仍须逐项核对 sharp-disk coefficient、
Bloch 参数和尺度映射，见 [[ref/ref_data/Fliss2013.pdf|Fliss2013 original]]。projected gap 只排除
本质谱，不排除同一区间内有多个离散特征值。

若 $I_h^\lambda=[L_h,U_h]\subset(0,\infty)$，定义

$$
I_h^k=[\sqrt{L_h},\sqrt{U_h}],
\qquad
G_k=(\sqrt{g_-},\sqrt{g_+}).
$$

若记 gap 内正离散特征频率集合为
$\mathcal K_{\mathrm{disc}}(A;G_\lambda)$，则可靠区间同时给出

$$
\operatorname{dist}\bigl(
\widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)
\bigr)
\le
\max\{\widehat k_h-\sqrt{L_h},
       \sqrt{U_h}-\widehat k_h\}.
$$

这仍是到集合中某个谱点的上界，不是到指定 $k_*$ 的上界。

在正式计算前必须独立预注册可接受频率分辨率 $\tau_k^{\mathrm{pre}}$。第一层可信结果还要求

$$
\operatorname{diam}(I_h^k)\le\tau_k^{\mathrm{pre}}.
$$

该阈值必须由下游所需有效数字、物理分辨率或比较任务决定。还要在结果前冻结
$0<\rho_G^{\mathrm{pre}}<1$，并要求

$$
\tau_k^{\mathrm{pre}}
\le\rho_G^{\mathrm{pre}}\operatorname{diam}(G_k),
$$

从而不能用一个几乎占满整个 gap 的区间通过绝对宽度门。两个阈值都不能由已观察到的
estimator 区间、I2 的零 observed shift 或后见的谱间距反推；$\rho_G^{\mathrm{pre}}$ 也须有
非空泛性理由，不能只机械取成略小于一。区间落在 gap 内但过宽时，仍可保留
“至少存在一个离散特征值”，但必须标为 `EXISTS_BUT_RESOLUTION_INSUFFICIENT`，不能作为达到
预注册分辨率的 candidate 认证。

## 3. 第二层：唯一目标识别

只有后续确实需要跟踪某个指定 mode 或特征值时，才进一步要求例如

$$
I_h^\lambda\cap\sigma(A)=\{\lambda_*\}.
$$

这会把第一层存在的谱值识别为 $\lambda_*$；若还要声称一重特征值，则另需 multiplicity-one
或连续谱投影秩一。唯一身份和重数不是 residual 计算、gap 内存在性或分辨率门的前置条件。

I3.2 可以用独立 reference 和公共物理场表示经验检查身份；这支持 empirical estimator，不能
替代连续谱隔离或计数。I2.1 的有限矩阵 count one 也不能替代连续谱计数。

## 4. I2 证据能提供什么

- I2.1 只说明某个冻结 finite matrix determinant 在小复圆盘内有条件性 count one；它不能
  充当 continuous projected gap 或连续谱计数。
- I2.2 的 Hermitian-part endpoint sign-count 只提高 candidate 的数值可信度；它不是连续
  spectral enclosure。
- I2.3 的 `SAME_MODE` 与零 observed candidate shift 支持算法输出稳定；它不能证明 continuous
  minimizer、finite root 或连续特征值收敛。

这些证据适合帮助选择重构场和检查 mode identity，但不能参与 gap containment 或事后调整
$\tau_k^{\mathrm{pre}}$。

## 5. 不再是主线门的有限根条件

nearby finite simple zero、左右 finite null vectors、非零 transverse slope、完整 matrix
derivative 和 bordered conditioning 只服务可选 simple-root correction。它们失败时，该
finite diagnostic unavailable；continuous weak residual 仍可继续。

## 6. 分层失败语义

- 不能构造非零 conforming field：`CONFORMING_FIELD_UNAVAILABLE`；
- residual norm 只覆盖部分项：`PARTIAL_RESIDUAL_ONLY`；
- residual/Riesz 数值误差淹没信号：`CONTINUOUS_RESIDUAL_UNRESOLVED`；
- 当前模型的 continuous projected gap 未建立：`PROJECTED_GAP_NOT_ESTABLISHED`；
- 可靠区间越过 gap 边缘：`CERTIFIED_INTERVAL_CROSSES_GAP_EDGE`；
- gap 内存在性成立但区间过宽：`EXISTS_BUT_RESOLUTION_INSUFFICIENT`；
- 第一层通过但唯一身份未建立：`EXISTENCE_WITH_TARGET_UNRESOLVED`；
- finite optional correction 失败：只停止该可选诊断，不改变以上主线状态。

后面一层失败不得撤销前面已经成立的较弱结论。
