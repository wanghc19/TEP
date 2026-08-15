# I3.1 continuous-residual estimator theory

## 1. 目标误差

I2 在离散层 $h$ 上保存了确定性的实数 candidate $\widehat k_h>0$。暂记
$G_\lambda\subset(0,\infty)$ 为后文需要针对当前模型认证的 continuous projected essential
gap，并定义其中的正离散特征频率集合

$$
\mathcal K_{\mathrm{disc}}(A;G_\lambda)
:=\{\sqrt{\lambda}:\lambda\in\sigma_{\mathrm{disc}}(A)\cap G_\lambda\}.
$$

约定到空集的距离为 $+\infty$。因此在尚未证明该集合非空时，下面的第一层误差不会暗含
一个尚未建立的特征值存在性；命题 3.2 的 gap containment 正是使该集合非空的步骤。

I3 第一层先研究

$$
e_h^{\mathrm{gap}}
=\operatorname{dist}\bigl(\widehat k_h,
\mathcal K_{\mathrm{disc}}(A;G_\lambda)\bigr),
$$

其中 $G_\lambda$ 是 $\lambda=k^2$ 尺度的 continuous projected essential gap。只在后续确实需要跟踪一个
预先命名的特征值 $k_*$ 时，才升级到 target-specific error

$$
e_h^*=|k_*-\widehat k_h|.
$$

I3.1 不先把 $\widehat k_h$ 替换成 score minimizer 或有限矩阵零点；所有 residual 都直接在
$\widehat k_h$ 处计算。第一层可以证明 candidate 附近存在某个连续离散特征值而不命名它，
第二层才处理唯一目标身份。

固定 Bloch 参数后，记连续物理算子为 $A=A^*$，其谱参数为

$$
\lambda=k^2,
\qquad
\mu_h=\widehat k_h^2.
$$

本命题明确假设连续自伴算子 $A\ge0$。固定 $\gamma>0$，于是
$A+\gamma I\ge c_\gamma I$，其中 $c_\gamma>0$，并定义 form domain

$$
V=D\bigl((A+\gamma I)^{1/2}\bigr),
\qquad
\|v\|_V=\|(A+\gamma I)^{1/2}v\|_H.
$$

这里 $H$ 是连续问题的质量内积空间，$V'$ 是 $V$ 的对偶空间。

## 2. 直接作用于 saved candidate 的弱残量

从 I2 的离散数据确定性地重构一个非零场 $u_h^{\mathrm c}\in V$。上标 $\mathrm c$ 表示该场
已经修复到连续 form space；它不表示已证明是特征函数。若 $a(\cdot,\cdot)$ 是 $A$ 的闭
sesquilinear form，定义

$$
R_h(v)
=a(u_h^{\mathrm c},v)
-\mu_h(u_h^{\mathrm c},v)_H,
\qquad v\in V,
$$

以及相位和整体缩放不敏感的无量纲量

$$
q_h=
\frac{\|R_h\|_{V'}}{\|u_h^{\mathrm c}\|_V}.
$$

这个对象直接检查：把算法保存的 $\widehat k_h$ 代入连续物理问题后，重构场离满足连续弱
特征方程还有多远。它不需要 finite determinant zero、左右有限矩阵零向量、矩阵 $k$ 导数
或相邻层零点位移。

## 3. 弱残量给出的连续谱结论

### 命题 3.1：到某个连续谱点的相对距离

对任意非零 $u_h^{\mathrm c}\in V$，有

$$
\inf_{\lambda\in\sigma(A)}
\frac{|\lambda-\mu_h|}{\lambda+\gamma}
\le q_h.
$$

证明如下。令

$$
w=(A+\gamma I)^{1/2}u_h^{\mathrm c},
$$

并在 $H$ 上定义有界自伴算子

$$
T_{\mu_h}
=(A+\gamma I)^{-1/2}(A-\mu_h I)(A+\gamma I)^{-1/2}.
$$

$R_h$ 的 $V'$ Riesz representative 对应 $T_{\mu_h}w$，因此

$$
q_h=\frac{\|T_{\mu_h}w\|_H}{\|w\|_H}.
$$

对有界自伴算子的 spectral measure 应用残量到谱距离的不等式，得到

$$
\operatorname{dist}(0,\sigma(T_{\mu_h}))\le q_h.
$$

谱映射给出

$$
\sigma(T_{\mu_h})
=\overline{\left\{\frac{\lambda-\mu_h}{\lambda+\gamma}:\lambda\in\sigma(A)\right\}},
$$

命题成立。

若 $q_h<1$，则存在某个 $\lambda\in\sigma(A)$ 满足

$$
|\lambda-\mu_h|
\le E_{\lambda,h}
:=\frac{q_h(\mu_h+\gamma)}{1-q_h}.
$$

这是到**某个连续谱点**的结论，还不是到指定 $\lambda_*=k_*^2$ 的结论。

### 命题 3.2：projected gap 内的存在性与分辨率

第一层不要求先识别某个指定的 $\lambda_*$。设已经针对当前 sharp-disk 连续算子、固定
Bloch 参数和同一单位约定证明一个 projected essential gap

$$
G_\lambda=(g_-,g_+),
\qquad 0<g_-<g_+,
\qquad
G_\lambda\cap\sigma_{\mathrm{ess}}(A)=\varnothing.
$$

这里 $G_\lambda$ 必须是连续算子的本质谱间隙；有限 QZ pencil 的 unit-circle gap 或其他材料
模型的数值 band gap 不能替代它。再假设 residual、field norm 和数值误差已经给出可靠的单侧界

$$
\|R_h\|_{V'}\le \overline\rho_h,
\qquad
0<\underline u_h\le \|u_h^{\mathrm c}\|_V,
\qquad
\overline q_h:=\frac{\overline\rho_h}{\underline u_h}<1.
$$

定义

$$
\overline E_{\lambda,h}
=\frac{\overline q_h(\mu_h+\gamma)}{1-\overline q_h},
\qquad
I_h^\lambda
=[\mu_h-\overline E_{\lambda,h},\mu_h+\overline E_{\lambda,h}].
$$

正式浮点实现还必须用 outward-rounded 端点覆盖 $\mu_h$ 的算术误差；$g_-$ 与 $g_+$ 也必须
采用已经证明位于真实本质谱间隙内的 certified inner bounds。若

$$
I_h^\lambda\subset G_\lambda,
$$

则命题 3.1 保证 $I_h^\lambda$ 与 $\sigma(A)$ 相交。该交点位于本质谱间隙内，所以其中至少
存在一个连续算子的孤立、有限重离散特征值。这里采用 Weyl/Fredholm essential-spectrum
约定。Fliss (2013), Proposition 3.3（本地原文 PDF p. 8）对 fixed-$\beta$ 波导给出同一
gap 内离散谱结论，见 [[ref/ref_data/Fliss2013.pdf|Fliss2013 original]]；当前 sharp-disk
coefficient、Bloch 参数和尺度仍须单独完成假设映射。这个结论不要求区间内只有一个特征值。

若 $I_h^\lambda=[L_h,U_h]\subset(0,\infty)$，相应正频率区间为

$$
I_h^k=[\sqrt{L_h},\sqrt{U_h}].
$$

由于 $\widehat k_h=\sqrt{\mu_h}$ 也在这个可靠区间中，命题 3.2 还直接给出第一层集合距离
上界

$$
e_h^{\mathrm{gap}}
\le U_h^{\mathrm{gap}}
:=\max\{\widehat k_h-\sqrt{L_h},
         \sqrt{U_h}-\widehat k_h\}.
$$

该式只界定 candidate 到 gap 内某个离散特征频率的距离，不识别具体是哪一个特征值。

正式设计必须在查看 estimator 结果前，根据项目需要的有效数字、物理分辨率或下游比较目的
预注册一个频率分辨率 $\tau_k^{\mathrm{pre}}>0$，并要求

$$
\operatorname{diam}(I_h^k)
=\sqrt{U_h}-\sqrt{L_h}
\le \tau_k^{\mathrm{pre}}.
$$

$\tau_k^{\mathrm{pre}}$ 还必须相对于 gap 宽度非空泛：设计需在结果前冻结
$0<\rho_G^{\mathrm{pre}}<1$，并满足

$$
\tau_k^{\mathrm{pre}}
\le \rho_G^{\mathrm{pre}}\operatorname{diam}(G_k),
\qquad
G_k=(\sqrt{g_-},\sqrt{g_+}).
$$

$\tau_k^{\mathrm{pre}}$ 和 $\rho_G^{\mathrm{pre}}$ 都必须给出下游精度与非空泛性理由，不能
仅把 $\rho_G^{\mathrm{pre}}$ 机械取成略小于一，也不能从已经观察到的区间宽度、I2 candidate
drift 或后见的谱间距反推。
若 gap containment 成立但宽度门失败，数学上的存在性仍保留，但只能报告
`EXISTS_BUT_RESOLUTION_INSUFFICIENT`，不能把一个过宽区间称为可信的分辨率级结果。

### 命题 3.3：唯一目标识别是独立升级

若后续必须把区间中的谱点识别为某个指定真值 $\lambda_*=k_*^2$，还需独立证明例如

$$
I_h^\lambda\cap\sigma(A)=\{\lambda_*\}.
$$

此条件只给出唯一谱值；若还要声称一重特征值或唯一 mode，则需进一步证明相应连续谱投影的
秩或重数。I2.1 对有限矩阵的 count one 不能替代这项连续谱论证。

一旦唯一目标条件成立，$k_*$ 落在 $I_h^k$ 中，并可直接报告

$$
|k_*-\widehat k_h|
\le
\max\{\widehat k_h-\sqrt{L_h},\sqrt{U_h}-\widehat k_h\}.
$$

唯一目标识别属于第二层可选升级；只要研究目标仍是以预注册分辨率证明 candidate 附近存在
某个连续离散特征值，它就不是 I3.1 residual 计算或第一层存在性结论的前置 blocker。

## 4. 一般 weak residual 与中心空列 strong-residual baseline

若 $u_h^{\mathrm c}\in D(A)$，可计算强残量

$$
\rho_h^{\mathrm s}
=\frac{\|(A-\mu_h I)u_h^{\mathrm c}\|_H}
{\|u_h^{\mathrm c}\|_H},
$$

并直接得到

$$
\operatorname{dist}(\mu_h,\sigma(A))\le\rho_h^{\mathrm s}.
$$

但当前 BIE/QZ 场可能在材料界面、胞元接口和人工截面带有 trace 或 flux defect；未经修复时，
强残量可能含分布项而不属于 $H$。弱残量只要求 form conformity，并允许通量 jump 作为
$V'$ 泛函出现。因此对一般 lead-aware reconstruction，weak residual 仍是更自然的主线。

当前 homogeneous empty center column 是一个可直接计算的特殊情形。取空列显式 Fourier 场
$u_0$，令

$$
\chi(x)=\cos^2(\pi x),\quad |x|\le1/2,
$$

并在单胞外延零。因为 $\chi=\chi'=0$ 于端点，$u_h^{\mathrm c}=\chi u_0$ 属于 $D(A)$。
[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 因而能够计算上式强残量。
正式 `center-a1` 给出

$$
\|u_h^{\mathrm c}\|_H=0.840017038309255,
\qquad
\|(A-\mu_h)u_h^{\mathrm c}\|_H=18.848991951433035,
$$

所以 computed ratio 为 $22.43882099031153$。普通 Simpson 三层结果稳定，但未形成可靠数值
上包络；两个 cutoff 导数分量的范数约为 $17.14$ 与 $4.93$，说明该 ratio 由固定单胞 cutoff
主导。名义区间跨过零，远不能达到预注册 $10^{-6}$ 频率分辨率。故这个特殊强残量是一个
有效的 `FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT` baseline，不是可移交 I3.2 的 estimator。
一般 weak residual 或 cutoff defect 更小的 conforming reconstruction 仍需另行研究。

## 5. 可计算 dual norm 与当前名称

抽象 dual norm 可由 Riesz 问题定义：求 $z_h\in V$ 使

$$
a(z_h,v)+\gamma(z_h,v)_H=R_h(v)
\qquad\text{对所有 }v\in V,
$$

于是 $\|R_h\|_{V'}=\|z_h\|_V$。实际计算必须再选择独立的 conforming Riesz
discretization、quadrature 和 stopping rule。

普通 Galerkin Riesz solve 通常只给 exact dual norm 的下近似；内部加密稳定并不自动给可靠
上界。因此 I3.1 可以冻结

$$
\widehat q_h
=\frac{\widehat{\|R_h\|}_{V'}}{\widehat{\|u_h^{\mathrm c}\|}_V}
$$

作为 estimator candidate，并报告 Riesz discretization 与数值误差。只有另有可靠 enclosure
后，才能把 $\widehat q_h$ 用于命题 3.2 的存在区间；只有再满足命题 3.3 的条件，才能把该
区间升级为指定 $k_*$ 的严格 bound。

## 6. residual 必须包含什么

首个主线对象固定为 global-field residual：

1. **global-field residual**：在中心区域和有限个左右胞元重构场，用固定 cutoff 接到零；
   residual 包含体方程、材料界面、胞元接口、准周期边界、cutoff 和尾部缺陷；
2. **OPTIONAL exact-DtN center residual**：只在中心域工作，但端口项必须使用连续 exact DtN；还要
   给出中心场到全局 outgoing field 的定量 extension/lifting，例如具有已知常数的
   $\|R_h^{\mathrm{global}}\|_{V'}\le C_{\mathrm{lift}}
   \|R_h^{\mathrm{center}}\|_{V_0'}+\eta_h^{\mathrm{tail}}$。若缺少这条不等式，center residual
   只能是 partial indicator。

首个 `design-3-1.md` 不需要同时实现第 2 项。若 residual 只把当前离散 DtN 重新代回同一
离散方程，它只能检查离散内部一致性，不能称
continuous residual。若重构场只分片属于 $V$，则必须显式加入 Dirichlet jump、flux jump
和修复项；不得把 sampled boundary mismatch 当成完整 dual norm。

## 7. 覆盖、忽略和反例

若 $u_h^{\mathrm c}$、$R_h$ 和 dual norm 按上述连续对象定义，则 residual 原则上同时看见
当前 candidate 下重构场的体方程、接口、边界和尾部缺陷。它仍可能忽略：

- 未纳入 residual 的 Rayleigh/Fourier tail 或 half-guide 近似；
- 从离散密度到 conforming field 的 reconstruction error；
- residual quadrature、Riesz solve 和 floating-point error；
- projected essential gap 是否已针对当前连续模型建立；
- 区间中离散特征值的唯一身份与重数；
- 其他谱点或本质谱对 residual 的影响。

以下反例必须保留：

- 两个离散层可以具有完全相同的 candidate 和矩阵差，但共同偏离连续真值；
- 把同一离散 DtN 代回同一离散方程可以得到极小 residual，却没有测到 DtN 的共同误差；
- 仅在有限测试点上残量为零，不表示完整 $V'$ residual 为零；
- 极小 residual 只能保证靠近某个连续谱点；只有可靠区间完全位于 continuous projected gap
  内时，才能先升级为离散特征值存在性，唯一目标身份仍需额外论证；
- 即使可靠区间位于 gap 内，若其宽度超过事前规定的 $\tau_k^{\mathrm{pre}}$，存在性结论也不
  具有项目要求的分辨率；
- 一个很小的 Galerkin Riesz norm 可能只是 Riesz space 太小，而不是 true dual norm 很小。

## 8. OPTIONAL finite-matrix component diagnostics

原先的

$$
\delta_h^{\mathrm{loc}}
=-\frac{y_h^*B_h(\widehat k_h)x_h}
{y_h^*B_h'(\widehat k_h)x_h},
$$

以及

$$
\delta_h^{\mathrm{disc}}
=-\frac{y_h^*[B_{h^+\downarrow h}(\widehat k_h)-B_h(\widehat k_h)]x_h}
{y_h^*B_h'(\widehat k_h)x_h}
$$

仍可分别诊断 saved candidate 到附近 finite zero 的局部位移，以及某一 enrichment 对
projected finite zero 的一阶影响。其 finite simple-root 扰动推导没有被否定。

但它们不覆盖共同偏差，不直接进入命题 3.1，也不构成 continuous-eigenvalue error
estimator。共同 trial/test
transport、exact Schur/kernel equivalence、nearby simple zero、左右向量、production
derivative 和 bordered conditioning 全部只在启用这项 `OPTIONAL` 诊断时成为局部门槛。

## 9. 当前裁决

- 主对象：direct continuous residual at the saved candidate；
- 已完成：中心空列 compact-support strong-residual baseline；
- 当前结果：computed ratio $22.43882099031153$，数值稳定但分辨率不足；
- 允许名称：continuous strong-residual baseline / estimator candidate；
- 不允许名称：continuous-eigenvalue error estimator、可靠存在区间或误差上界；
- 下一候选：减少 cutoff defect 的 lead-aware conforming reconstruction，或一般 continuous
  weak residual；
- 已闭合：抽象 residual-to-continuous-spectrum 命题，以及中心空列 baseline 的 operator-domain
  与 strong-residual 公式；
- 尚未闭合：具有项目分辨率的一般 conforming reconstruction/residual、可靠 numerical
  enclosure、当前 sharp-disk continuous projected gap；
- 第一层升级：可靠区间进入 continuous projected gap 且宽度不超过预注册尺度时，报告其中
  至少存在一个连续离散特征值；
- 第二层升级：只有独立连续谱隔离或计数成立时，才识别指定 $k_*$；
- 不允许：把近似 dual norm 称为已证明区间，把 gap 内存在性改写成唯一 mode，或用结果后
  选择的分辨率接受一个过宽区间；
- `design-3-1.md` 与 `center-a1`：已完成并保留为负向 baseline；下一设计须另行冻结。
