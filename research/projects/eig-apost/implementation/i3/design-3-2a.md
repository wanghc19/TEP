# I3.2 条件性离散证书谱包含定理设计

## 摘要与状态

- **Design ID:** `I3.2-CONDITIONAL-DISCRETE-CERTIFICATE-V1`
- **生效日期：** 2026-08-24
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `DESIGN PASS`
- **证明模式：** `Proof from scratch`
- **Implementation:** `NOT INCLUDED`
- **Run:** `NO NEW EXPERIMENT IN THIS DESIGN`

本设计建立一个严格的**条件性定理**。输入不是 finite determinant zero、score minimizer 或
离散矩阵的精确根，而是一个有限证书 $z_h$、由它确定性定义的连续试验场
$u_h^{mathrm c}=\mathcal T(z_h)$，以及对同一个 $u_h^{\mathrm c}$ 的连续弱残量上界和场范数
下界。若这些界由严格数值认证给出，则定理把它们变成与连续自伴算子谱相交的区间。

本设计不声称当前 [[test/i3/fb-resid/README|`fbie-a1` artifact]] 已经提供严格界。该 artifact
只给出普通双精度中心值 $\widetilde M_h$、$\widetilde N_h$；circle action
$256\to512$ ratio $0.77408786032496468>0.20$ 仍须原样保留。下面的数值预算只回答：若未来能
证明误差 cap，cap 最多可有多大；它本身不构造 cap。

本轮也不认证当前 continuous projected gap。严格 cap 的实际构造、outward arithmetic、
same-operator gap 及离散特征值存在性留给新的 I3.4。旧 I3.2 的 independent-reference
effectivity 验证改为新的 I3.3。历史 I3.1 design、review、MATLAB 和 append-only output 均保持
byte-identical。

相关现行理论背景见
[[research/projects/eig-apost/phase3-analysis/s-estimator|continuous-residual estimator theory]]；
`fbie-a1` 的正式普通双精度结果和 caveats 见
[[research/projects/eig-apost/implementation/i3/review-3-1f|review-3-1f]]。

## 1. 数学对象与量词

固定 Bloch 参数和当前 sharp-disk 系数。令 $H$ 为连续问题的质量 Hilbert 空间，
$A:D(A)\subset H\to H$ 为非负自伴算子，$a$ 为 $A$ 的闭 sesquilinear form。固定算法实际保存
的 candidate $\widehat k_h>0$，并在精确数学层面定义

$$
\mu_h=\widehat k_h^2,
\qquad
\gamma=\mu_h>0.
$$

这里 $\mu_h$ 和 $\gamma$ 是同一个精确对象；不得把两个独立舍入但数值看似相同的 binary64
量当成严格相等。定义

$$
V=D\bigl((A+\gamma I)^{1/2}\bigr),
\qquad
\|v\|_V=\|(A+\gamma I)^{1/2}v\|_H.
$$

本设计采用 Weyl essential-spectrum 约定；对当前自伴算子，
$\sigma_{\mathrm{disc}}(A)=\sigma(A)\setminus\sigma_{\mathrm{ess}}(A)$ 由孤立、有限重的谱点组成。
令 $Z_h$ 表示本轮有限证书允许取值的集合。有限证书 $z_h\in Z_h$ 必须通过一个完全规定的
确定性重构映射

$$
\mathcal T:Z_h\longrightarrow V,
\qquad
u_h^{\mathrm c}=\mathcal T(z_h)\ne0,
$$

定义**一个确切的连续试验场**。MATLAB arrays、BIE densities、QZ states 和 tail factors 只是
$z_h$ 的有限编码；它们本身不是连续试验场。这里的 $z_h\in Z_h$ 是 I3.2 的局部 certificate
记号，不是链接的历史理论中曾以 $z_h\in V$ 表示的 $V$-Riesz representative；历史文件不回写，
未来同步理论时应把后者前瞻性改名。对这个 $u_h^{\mathrm c}$ 定义连续弱残量

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h(u_h^{\mathrm c},v)_H,
\qquad v\in V.
$$

因为 $a$ 是 $A$ 的 associated closed form，$R_h\in V'$。严格证书使用的中间上界是一个映射

$$
M_{\mathrm{exact}}:Z_h\longrightarrow[0,\infty).
$$

严格证书接口需要非负数 $\epsilon_M,\epsilon_N$，使

$$
\|R_h\|_{V'}
\le M_{\mathrm{exact}}(z_h)
\le \widetilde M_h+\epsilon_M,
$$

$$
\|u_h^{\mathrm c}\|_V^2
\ge \widetilde N_h-\epsilon_N>0.
$$

$M_{\mathrm{exact}}(z_h)$ 表示一个已经证明覆盖连续残量对偶范数的中间上界；若不需要该中间
对象，可直接证明第一行的首尾不等式。$\widetilde M_h$ 和 $\widetilde N_h$ 是普通数值中心值，
不是带方向的界。定义

$$
\overline\rho_h=\widetilde M_h+\epsilon_M,
\qquad
\underline u_h=\sqrt{\widetilde N_h-\epsilon_N},
\qquad
\overline q_h=\frac{\overline\rho_h}{\underline u_h}.
$$

全部 numerator 和 denominator 必须来自同一个 certificate ID、同一个 $z_h$ 和同一个
$\mathcal T$。用一个 trial 的残量除以另一个 trial 的场范数不满足本设计假设。

## 2. 条件性谱包含定理

### 定理 2.1：严格 cap 给出的连续谱相交区间

在第 1 节假设下，若 $\overline q_h<1$，则区间

$$
J_h^\lambda=
\left[
\max\left\{0,
\frac{\mu_h-\overline q_h\gamma}{1+\overline q_h}
\right\},
\frac{\mu_h+\overline q_h\gamma}{1-\overline q_h}
\right]
$$

与 $\sigma(A)$ 相交。若另有针对**同一个算子 $A$** 的 certified projected essential gap

$$
G_\lambda=(g_-,g_+),
\qquad
G_\lambda\cap\sigma_{\mathrm{ess}}(A)=\varnothing,
$$

且 $J_h^\lambda\subset G_\lambda$，则 $J_h^\lambda$ 内至少存在一个不属于本质谱的离散特征值，
重数不作额外判断。该结论不要求先识别它是哪一个特征值，也不证明区间中只有一个特征值。

#### 证明

令 $t(\lambda)=(\lambda-\mu_h)/(\lambda+\gamma)$，并由有界 functional calculus 定义

$$
B_h=t(A).
$$

则 $B_h$ 是 $H$ 上的有界自伴算子。形式上的 sandwich
$(A+\gamma I)^{-1/2}(A-\mu_hI)(A+\gamma I)^{-1/2}$ 只按 form identity 理解；不把它误作要求
中间向量属于 $D(A)$ 的普通强算子乘积。映射

$$
U:V\longrightarrow H,
\qquad
Uv=(A+\gamma I)^{1/2}v
$$

是 onto isometry。令 $w=Uu_h^{\mathrm c}\ne0$。functional calculus 的 form identity 给出

$$
(B_hUu,Uv)_H=a(u,v)-\mu_h(u,v)_H,
\qquad u,v\in V.
$$

因此 $R_h$ 在 $V'$ 中的 Riesz 表示对应于 $B_hw$，并且

$$
\frac{\|R_h\|_{V'}}{\|u_h^{\mathrm c}\|_V}
=\frac{\|B_hw\|_H}{\|w\|_H}
\le\overline q_h.
$$

有界自伴算子的谱定理给出

$$
\operatorname{dist}(0,\sigma(B_h))
\le\frac{\|B_hw\|_H}{\|w\|_H}
\le\overline q_h.
$$

同一定理和 spectral mapping 给出

$$
\sigma(B_h)
=\overline{\left\{
\frac{\lambda-\mu_h}{\lambda+\gamma}:\lambda\in\sigma(A)
\right\}}.
$$

有界自伴算子的谱是非空紧集，所以存在 $b\in\sigma(B_h)$ 达到
$|b|=\operatorname{dist}(0,\sigma(B_h))$。由上式，$|b|\le\overline q_h<1$，故 $b\ne1$。
另一方面，当 $\lambda\to\infty$ 时 $t(\lambda)\to1$，所以闭包中可能由无穷远产生的点 $1$
不能是本次见证。更具体地，若
$t(\lambda_n)\to b\ne1$，则 $\{\lambda_n\}$ 有界；取收敛子列并使用 $\sigma(A)$ 的闭性，得到
有限的 $\lambda\in\sigma(A)$ 和 $b=t(\lambda)$。因此存在有限的 $\lambda\in\sigma(A)$ 满足

$$
\frac{|\lambda-\mu_h|}{\lambda+\gamma}
\le\overline q_h.
$$

分别解 $\lambda\le\mu_h$ 和 $\lambda\ge\mu_h$ 的不等式，并用 $A\ge0$，得到
$\lambda\in J_h^\lambda$。若 $J_h^\lambda\subset G_\lambda$，则该谱点不属于
$\sigma_{\mathrm{ess}}(A)$；按本项目采用的自伴算子 essential-spectrum 约定，它是孤立、有限重的
离散特征值。证毕。

本证明只使用自伴算子的标准谱定理和 functional calculus，没有调用未核验的项目外定理。
same-operator gap 的实际认证仍是独立证明义务。

作为模型边界核对，本地原文 Sonia Fliss, “A Dirichlet-to-Neumann Approach for the Exact
Computation of Guided Modes in Photonic Crystal Waveguides,” *SIAM Journal on Scientific
Computing* 35(2), B438--B461 (2013),
[DOI 10.1137/12086697X](https://doi.org/10.1137/12086697X)，
[[ref/ref_data/Fliss2013.pdf|local original]] 的 Proposition 3.1（PDF p. 7）证明其 fixed-$\beta$
模型中的算子非负自伴并刻画本质谱，Proposition 3.3（PDF p. 8）说明 gap 内谱点是孤立、有限重
特征值。该原文只支撑其自身 coefficient 与 fixed-$\beta$ 模型；当前 sharp-disk coefficient、
Bloch 参数、尺度、operator identity 和 certified inner gap edges 的逐项映射仍是 I3.4 义务。

### 2.2 频率区间、分辨率和唯一性边界

对 $\gamma=\mu_h$，$\overline q_h<1$ 时

$$
J_h^\lambda=
\left[
\mu_h\frac{1-\overline q_h}{1+\overline q_h},
\mu_h\frac{1+\overline q_h}{1-\overline q_h}
\right],
$$

相应正频率区间为

$$
J_h^k=
\left[
\widehat k_h\sqrt{\frac{1-\overline q_h}{1+\overline q_h}},
\widehat k_h\sqrt{\frac{1+\overline q_h}{1-\overline q_h}}
\right].
$$

其宽度是

$$
\operatorname{diam}(J_h^k)
=\frac{2\widehat k_h\overline q_h}
{\sqrt{1-\overline q_h^2}}.
$$

本设计继承并冻结此前设计的绝对分辨率和 gap-relative 非空泛尺度

$$
\tau_k^{\mathrm{pre}}=10^{-6},
\qquad
\rho_G^{\mathrm{pre}}=0.1.
$$

分辨率级离散特征值存在结论最终要求

$$
J_h^\lambda\subset G_\lambda,
\qquad
\operatorname{diam}(J_h^k)\le\tau_k^{\mathrm{pre}},
\qquad
\tau_k^{\mathrm{pre}}
\le\rho_G^{\mathrm{pre}}\operatorname{diam}(G_k),
$$

其中 $G_k=(\sqrt{g_-},\sqrt{g_+})$。本轮只冻结条件；gap 和 containment 的实际认证留给 I3.4。
若 gap containment 已成立但宽度门失败，离散特征值存在性仍保留，只是分辨率不足。

到区间内某个谱频率的最大单侧 candidate 距离为右侧距离

$$
\widehat k_h
\left(
\sqrt{\frac{1+\overline q_h}{1-\overline q_h}}-1
\right).
$$

若需要把该谱点命名为某个指定真值 $k_*$，还须独立证明唯一谱值或相应 spectral projection
条件；唯一目标识别不是本定理和第一层存在性结论的前置条件。

## 3. `fbie-a1` 给出的 cap 可行域

### 3.1 只作预算的普通双精度中心值

正式 artifact 保存

$$
\widehat k_h=1.832770289108157,
\qquad
\widetilde M_h=2.29786516751043\times10^{-10},
$$

$$
\widetilde N_h
=\texttt{estimator.field\_lower\_squared}
=4.959111810675795.
$$

最后一个数必须直接取保存的 squared field quantity；不得对 report 中已经舍入的
$2.2269063318145634$ 再平方，因为那会把末位改成 `...794`。由保存数值形成的普通比值为

$$
\widetilde q_h
=\frac{\widetilde M_h}{\sqrt{\widetilde N_h}}
\approx1.0318643108971928\times10^{-10}.
$$

上述值及 `fbie-a1` 的窄 nominal interval 仍是 ordinary-double output。它们没有 outward
enclosure，不能把 $\epsilon_M$ 或 $\epsilon_N$ 设成零，也不能触发定理 2.1。

以下高精度预算把 artifact 中显示的十进制字符串当作设计输入。未来严格实现必须改为读取
实际保存的 binary64 值并用 directed rounding 形成 input boxes；这里列出的末位不是认证值。

### 3.2 仅要求 $\overline q_h<1$ 的严格可行域

严格条件为

$$
\epsilon_M\ge0,
\qquad
0\le\epsilon_N<\widetilde N_h,
\qquad
(\widetilde M_h+\epsilon_M)^2
<\widetilde N_h-\epsilon_N.
$$

等价地，给定 $\epsilon_M$ 时

$$
\epsilon_N
<\widetilde N_h-(\widetilde M_h+\epsilon_M)^2.
$$

两条坐标轴截距分别是

$$
\epsilon_M
<2.22690633158477703
\quad(\epsilon_N=0),
$$

$$
\epsilon_N
<\widetilde N_h-\widetilde M_h^2
=4.959111810675795
-5.2801843280577365\times10^{-20}
\quad(\epsilon_M=0).
$$

边界是严格的；$\overline q_h=1$ 不产生有限上端点。第二条不能因 binary64 显示相同而写成
$\epsilon_N<\widetilde N_h$。

### 3.3 同时满足 $10^{-6}$ 宽度的可行域

令 $\tau=10^{-6}$。由第 2.2 节宽度公式，宽度门精确等价于

$$
\overline q_h\le q_{\mathrm{res}}
:=\frac{\tau}{\sqrt{4\widehat k_h^2+\tau^2}}
=2.72811057103771594\times10^{-7}.
$$

因此 cap 必须落在

$$
\epsilon_M\ge0,
\qquad
0\le\epsilon_N<\widetilde N_h,
$$

$$
\widetilde M_h+\epsilon_M
\le q_{\mathrm{res}}
\sqrt{\widetilde N_h-\epsilon_N}.
$$

等价的 frontier 写法是

$$
\epsilon_M
\le q_{\mathrm{res}}\sqrt{\widetilde N_h-\epsilon_N}
-\widetilde M_h,
$$

或

$$
\epsilon_N
\le\widetilde N_h
-\left(\frac{\widetilde M_h+\epsilon_M}{q_{\mathrm{res}}}\right)^2.
$$

坐标轴截距为

$$
\epsilon_M\le6.07294883936662387\times10^{-7}
\quad(\epsilon_N=0),
$$

$$
\epsilon_N\le4.95911110122031616
\quad(\epsilon_M=0).
$$

两个截距不能同时取到；它们只是同一弯曲 frontier 的两端。该分辨率区域自动包含在
$\overline q_h<1$ 区域内。预算说明当前 ordinary numerator 很小，因而允许的 numerator cap
约为 $6.07\times10^{-7}$；它不说明能用现有数值链证明这样一个 cap。

## 4. 严格 cap 的组成和禁止的分配方式

### 4.1 Numerator cap

若严格 residual bound 按三角不等式组合，则总 cap 必须满足

$$
\epsilon_M\ge
\epsilon_{\mathrm{wall}}
+\epsilon_{\mathrm{circle}}
+\epsilon_{\mathrm{volume}}
+\epsilon_{\mathrm{evaluator}}
+\epsilon_{\mathrm{Fourier}}
+\epsilon_{\mathrm{lift}}
+\epsilon_{\mathrm{Bloch}}
+\epsilon_{\mathrm{tail}}
+\epsilon_{\mathrm{arith}}.
$$

各项分别覆盖 wall residual、circle residual、value-lift volume source、layer evaluator、未计算
Fourier modes、重构 lift、Bloch seam、full-$P$ infinite tail 和浮点/求积误差。只有已经证明为
结构零的项才可显式取零。缺少 outward Fourier tail 或 arithmetic remainder 时，cap 是
`UNAVAILABLE`，不能静默把遗漏项设成零。除非另有正交性证明，不得用 root-sum-square 代替
三角和。

本设计只冻结上述总 cap simplex，不冻结等分、按 component 大小分配、`0.1\widetilde N_h`
工作盒或 envelope 的固定百分比。尤其 circle component 虽小，却是当前分辨率最弱的对象；按
观察到的 component 大小给它最小 cap 会形成结果后调参。

### 4.2 Denominator cap

$\epsilon_N$ 必须针对**同一个** $u_h^{\mathrm c}=\mathcal T(z_h)$ 覆盖 field lower 的求积、
有限 Fourier 表示、无限 lead tail、重构和 arithmetic omissions。若把这些来源分项相加，每项
也必须先给出方向正确的上界，最后证明

$$
\|u_h^{\mathrm c}\|_V^2
\ge\widetilde N_h-\epsilon_N>0.
$$

经验层差、same-chain phase repeat 或普通双精度 Gram positivity 不是该不等式的证明。

## 5. 机器可核验的严格证书接口

未来 I3.4 若要实例化定理 2.1，每份严格证书至少需要：

1. 唯一 certificate ID，以及 $z_h$ 的 canonical serialization 和 SHA-256；
2. $\mathcal T$ 的精确数学定义、版本、输入/输出空间及所有 reconstruction parameters；
3. 证明 numerator 和 denominator 使用同一 $z_h$、同一 $\mathcal T$ 和同一 $\widehat k_h$；
4. arithmetic backend、版本、舍入模式和可复算的 outward interval boxes；
5. $\widehat k_h$、$\mu_h=\widehat k_h^2$ 和 $\gamma=\mu_h$ 的关联 enclosure；
6. 每个 numerator/denominator omission 的 bound、组合方向和零项证明；
7. $\overline\rho_h$、$\underline u_h$、$\overline q_h$ 及 $J_h^\lambda,J_h^k$ 的 outward endpoints；
8. same-operator gap 的 operator identity、coefficient/scale/Bloch parameters、inner gap endpoints 和
   containment proof；
9. `rigorous_cap=true`、`outward_arithmetic=true`、`same_trial=true`、
   `same_operator_gap=true/false` 等机器字段；
10. 原始普通数值、empirical caps 和 rigorous caps 使用不同字段，禁止覆盖或复用标签。

若用 interval boxes 表示 $\mu_h$ 和 $\gamma$，实现必须保留二者来自同一个精确平方这一依赖；
不得分别计算两个 outward boxes 后假装它们独立。具体地，若精确平方已经 enclosure 为
$[\mu_-,\mu_+]$，且 $\overline q_h<1$ 是严格上界，则利用 $\gamma=\mu_h$ 的相关性直接计算

$$
L_h=\mu_-\frac{1-\overline q_h}{1+\overline q_h}
\quad\text{with downward rounding},
\qquad
U_h=\mu_+\frac{1+\overline q_h}{1-\overline q_h}
\quad\text{with upward rounding}.
$$

随后对 $L_h,U_h$ 的平方根继续 outward-round。机器 Boolean 只是结果索引，不能自证任何
不等式。producer 必须输出 proof objects 或可复算 witnesses；冻结的独立 checker 必须验证
canonical $z_h$、$\mathcal T$ identity、backend 与舍入模式、每条 outward inequality、每个零项
证明和 cap 组合。producer 和 checker 复用同一未经审查的计算路径不能称独立验证。

实例化定理时必须逐项关闭以下 application obligations：

- **O1:** canonical $z_h$、certificate hash 和 frozen input identity；
- **O2:** $\mathcal T:Z_h\to V$ 的精确定义、确定性和同一 trial mapping；
- **O3:** $u_h^{\mathrm c}\in V\setminus\{0\}$；
- **O4:** $\|R_h\|_{V'}\le\widetilde M_h+\epsilon_M$ 的完整 proof/witness；
- **O5:** $\|u_h^{\mathrm c}\|_V^2\ge\widetilde N_h-\epsilon_N>0$ 的完整 proof/witness；
- **O6:** 所有 omissions、结构零、组合方向和 arithmetic remainder 已覆盖；
- **O7:** $\widehat k_h$、$\mu_h=\gamma=\widehat k_h^2$ 和 $\overline q_h$ 的关联 enclosure；
- **O8:** $J_h^\lambda$、$J_h^k$ 的 outward endpoints；
- **O9:** 若声称离散存在，same-$A$ certified gap identity 和 containment；
- **O10:** 绝对与 gap-relative 分辨率门及原始 widths。

本设计中的 generic $\mathcal T$ 和 cap 不等式是带量词的定理假设，不是当前 `fbie-a1` 的已验证
事实。其实际实例化属于 I3.4。

本设计只冻结逻辑接口，不生成证书 artifact，不定义 attempt tag、MATLAB command 或 output
目录。`review-3-2a.md` 只在 Skeptic 完成独立证明审查后建立。

## 6. 严格、经验和普通数值三层分开

| 层级 | 允许输入 | 允许输出 | 禁止升级 |
|---|---|---|---|
| ordinary | $\widetilde M_h,\widetilde N_h$ 和普通双精度 tails/Grams | $\widetilde q_h$、ordinary nominal transform | 不得称严格 cap、误差界或谱存在性 |
| empirical | 固定同一 $z_h$ 后的有限层差和预注册经验外推 | `EMPIRICALLY_SUPPORTED_ERROR_CAP`、`EMPIRICAL_NOMINAL_TRANSFORM` | 不得置 `rigorous_cap`、`reliable_interval` 或 `existence` 为 true |
| rigorous | 已证明的 $\epsilon_M,\epsilon_N$、directed rounding 和同一 trial | $\overline q_h$、定理 2.1 的可靠 spectral-intersection interval | 无 certified same-operator gap 时不得称离散特征值存在 |

符号固定为：带 tilde 的量只表示普通中心值；`emp` 下标只表示经验量；overbar/underbar 只留给
严格单侧界。不能把一个 finite empirical cap 改名成 $\epsilon_M$ 或 $\epsilon_N$ 后触发定理。
定理不要求 $z_h$ 的生成方法与 BIE/QZ 链独立；它不循环，是因为结论只消费同一 trial 的**已证明
连续** residual upper 和 field lower。反之，若这些单侧界只是由同一 approximate chain 的
层差猜测出来，则输入假设没有闭合，不能借定理本身把经验层差升级为严格 cap。

## 7. 未来 I3.3 经验 cap 实验草图

本节不是本设计的 experiment contract，不冻结 grids、attempt、command 或 acceptance threshold。
它只规定未来单独 design 必须保持的科学边界。

1. 先冻结一个 certificate $z_h$，所有 refinement level 只提高同一个连续 trial 的数值评价；
   不重新求 density、QZ state 或 candidate。
2. numerator 至少分开 refinement：fixed-density wall action、fixed-density circle action、value-lift
   radial quadrature 和 full-$P$ tail/arithmetic；denominator 单独 refinement field lower 和 state tail。
3. 每个 component 至少使用三个事前冻结的 nested levels，保存两次相邻差、比例、raw norms 和
   zero-component semantics。
4. 若未来 design 选择经验几何规则，例如在
   $d_{\mathrm{last}}\le0.5d_{\mathrm{prev}}$ 时取 $2d_{\mathrm{last}}$，必须明确它只是经验 remainder
   candidate；有限层的几何趋势不能证明后续无限级数。
5. numerator component caps 仍按三角和组合；不得在看到哪项最大后重分总预算。
6. same-chain refinement 只能支持 empirical cap，不能充当 I3.3 的 independent effectivity
   reference。独立 reference 必须另用未参与 estimator 构造的方法或数据。

未来可能的 ordinary states 是：所有 empirical components 都形成时报告
`EMPIRICALLY_SUPPORTED_ERROR_CAP`；任一必要分量不形成时报告
`EMPIRICAL_CAP_UNRESOLVED`；经验 $q_{\mathrm{emp}}\ge1$ 时报告
`EMPIRICAL_NOMINAL_INTERVAL_UNAVAILABLE`；经验 $q_{\mathrm{emp}}<1$ 但宽度超过 $10^{-6}$ 时
报告 `EMPIRICAL_RESOLUTION_INSUFFICIENT`；只有经验 $q_{\mathrm{emp}}<1$ 且宽度通过时才保存
`EMPIRICAL_NOMINAL_TRANSFORM`。全部 rigorous、outward、certified-gap、existence 和
independent-reference flags 默认 false。

基于现有实现规模，未来 separate design 的初步工程预算为 3--12 分钟、512 MiB--1 GiB，circle
1024 action 可能主导。该估计不是冻结资源合同；正式 code-level allocation audit 后才能选择
hard limit。优先单入口，只有超过 1000 行时才按“fixed-trial boundary evaluation”和
“cap/tail contraction”两个科学边界拆分。未来 separate design 可以按 hash **只读**消费 immutable
`fbie-a1` certificate artifact，也可以在新 attempt 中重新构造新 certificate；两种路径必须事前
二选一并固定。历史 `fb-resid` code/output 不得修改、覆盖或同 tag 重跑。

## 8. Failure 与 claim lattice

| 状态 | 触发条件 | 可保留结论 |
|---|---|---|
| `I3_2_CONDITIONAL_THEOREM_ESTABLISHED` | 定理及 proof audit 通过 | 条件性逻辑成立；不表示当前 caps 已存在 |
| `CERTIFICATE_OBJECT_UNDEFINED` | $z_h\mapsto\mathcal T(z_h)$ 未精确定义或无法证明落在 $V$ | 只保留普通 finite diagnostics |
| `RIGOROUS_NUMERATOR_CAP_UNAVAILABLE` | 任一必要 numerator omission 无严格上界 | 保留 ordinary/empirical numerator |
| `RIGOROUS_DENOMINATOR_CAP_UNAVAILABLE` | 无同一 trial 的严格 field lower | 保留 ordinary/empirical field value |
| `RIGOROUS_Q_UNAVAILABLE` | strict cap 不完整、非有限，或 $\widetilde N_h-\epsilon_N\le0$ | 不形成 $\overline q_h$ |
| `STRICT_SPECTRAL_INTERVAL_UNAVAILABLE` | 严格 $\overline q_h\ge1$ | 保留 cap 本身；不形成有限 interval |
| `CONDITIONAL_SPECTRAL_INTERSECTION` | strict caps、$\overline q_h<1$ | $J_h^\lambda\cap\sigma(A)\ne\varnothing$ |
| `SAME_OPERATOR_GAP_UNAVAILABLE` | 已有严格谱相交区间，但无 same-$A$ certified gap | 保留连续谱相交；不声称离散存在 |
| `CERTIFIED_INTERVAL_CROSSES_GAP_EDGE` | certified gap 存在，但 $J_h^\lambda\not\subset G_\lambda$ | 保留连续谱相交；不声称交点避开本质谱 |
| `DISCRETE_EIGENVALUE_EXISTS_IN_INTERVAL` | `CONDITIONAL_SPECTRAL_INTERSECTION` 加 same-operator certified gap containment | 区间内至少一个离散特征值；不识别唯一值 |
| `EXISTS_BUT_RESOLUTION_INSUFFICIENT` | 已有 gap containment，但 absolute width 或 gap-relative 门失败 | 保留离散存在性；不称分辨率级结果 |
| `RESOLVED_DISCRETE_EIGENVALUE_EXISTS_IN_INTERVAL` | gap containment 和两个分辨率门都通过 | 至少一个离散特征值落在合格分辨率区间内 |
| `EMPIRICAL_CAP_UNRESOLVED` | 未来有限 refinement 无预注册经验趋势 | 保留原 ordinary indicator |
| `EMPIRICALLY_SUPPORTED_ERROR_CAP` | 未来经验规则闭合 | 只形成 empirical nominal output |
| `EMPIRICAL_NOMINAL_INTERVAL_UNAVAILABLE` | 经验 $q_{\mathrm{emp}}\ge1$ | 保留 empirical cap；不形成 interval |
| `EMPIRICAL_RESOLUTION_INSUFFICIENT` | 经验 $q_{\mathrm{emp}}<1$ 但 width 失败 | 保留 empirical nominal transform；不称分辨率合格 |
| `EMPIRICAL_NOMINAL_TRANSFORM` | 经验 $q_{\mathrm{emp}}<1$ 且 width 通过 | 只保留经验代数变换，所有可靠性 flags 仍 false |

failure 必须保留较弱层结果。缺少 gap 或 interval 穿过 gap edge 不撤销连续谱相交；gap containment
后 absolute 或 gap-relative 分辨率失败不撤销离散存在性；circle action 内部资格失败不撤销本设计
的条件性定理。不得用 status label 代替原始不等式、cap 分量和首个失败条件。

## 9. 里程碑映射（2026-08-24 起生效）

| 当前里程碑 | 独立科学问题 | 输出边界 |
|---|---|---|
| I3.1 | 能否构造可计算 continuous-residual indicator candidate？ | `PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`；保留 circle-action caveat |
| I3.2 | 严格 residual/field caps 若存在，能否推出连续谱相交及条件性离散存在？ | 本设计的条件性定理、cap 可行域和证书接口；不要求当前已有 caps |
| I3.3 | 经验 cap 是否成立，冻结 estimator 是否经 independent reference 跟踪真实误差？ | empirical error estimation 与 independent effectivity verdict；不能称严格界 |
| I3.4 | 能否实际构造 outward residual/field/tail enclosure、certified gap 和可靠存在/上界？ | reliable enclosure、gap containment、离散存在性或 `UPPER_BOUND_UNAVAILABLE` |

历史 design、review、code 和 output 保留它们生成时的 I3.2/I3.3 标签，不追溯改写。只有当前
planning、STATUS、README、ROADMAP 和 open-problem ledger 在 Skeptic 接受本设计后按本表最小
同步。项目级 I4 仍是 optional robustness/generalization，不与当前 I3.4 混写。

## 10. Skeptic 18 门逐项闭合表

1. **$A/H/V/\gamma/\mu$ 与 essential-spectrum 约定：** §1 定义非负自伴 $A$、质量空间、form
   domain、同一精确平方 $\gamma=\mu_h$；§2 固定自伴 essential-spectrum 约定。
2. **可靠单侧定理与非对称区间：** §2.1 从 residual upper 和 field lower 给出精确 asymmetric
   endpoints，没有用对称粗界代替。
3. **Riesz、谱映射、闭包、极限点和算术证明：** §2.1 逐步给出 $B_h$、Riesz quotient、functional
   calculus、闭包点 $1$ 的排除和两侧不等式求解。
4. **机器可核验证书：** §5 要求 certificate identity/hash、backend、舍入模式、outward boxes 和
   端点复算。
5. **精确 $\mathcal T(z_h)$ 映射：** §1 明确 arrays 只是 $z_h$ 编码，不是 trial；必须证明
   $\mathcal T(z_h)\in V\setminus\{0\}$。
6. **continuous form 与经验独立性：** §1 的 residual 直接属于连续 form；§6--§7 分开 theorem
   certificate、same-chain empirical refinement 和 independent reference。
7. **`fbie-a1` ordinary-only：** 摘要与 §3 保留 circle warning、ordinary flags 和不可触发定理的
   边界。
8. **$\epsilon_M$ 完整覆盖：** §4.1 列出 wall、circle、volume、evaluator、Fourier、lift、Bloch、
   full-$P$ tail 和 arithmetic，并规定三角组合和零项证明。
9. **同一 trial 的严格 field lower：** §1、§4.2 和 §5 禁止 numerator/denominator 混用不同
   certificate。
10. **经验/严格 schema 分层：** §5--§6 固定 tilde、`emp`、overbar/underbar 的不同语义和 flags。
11. **unavailable 与 finite-unqualified：** §8 分开对象未定义、strict cap unavailable、ordinary 和
   empirical output。
12. **$q_{\mathrm{rig}}$ 与 $q_{\mathrm{emp}}$：** §2 只让 $\overline q_h$ 触发定理；§6--§7 的经验量
   只能产生 empirical nominal diagnostic。
13. **same-$A$ gap 与 containment：** §2.1、§2.2 和 §5 要求 operator identity、gap inner bounds
   与 interval containment。
14. **预注册 $\tau_k/\rho_G$：** §2.2 冻结 $10^{-6}$ 和 $0.1$；宽度失败保留已有 existence。
15. **failure lattice：** §8 逐层保留 ordinary、empirical、spectral-intersection、gap-existence 和
   resolution 结论。
16. **shared bias 与禁止 reference reuse：** §7 固定 same-$z_h$ refinement 只作 empirical cap，
   不能在调参后复用为 independent effectivity reference。
17. **新旧 milestone 映射：** §9 给出生效日期并明确历史 artifact byte-identical。
18. **独立 Design ID、schema/attempt/cost：** 摘要给出独立 Design ID；§5、§7 明确本设计
   `NO NEW EXPERIMENT`，因此没有 attempt/schema/command/output，未来 pilot 必须另立 design、
   先冻结 code-level 资源并经 spec-to-code review，不能为凑 milestone 加实验。

## 11. 跑前审查与完成门

Researcher 必须复核定理量词、同一 trial 条件、严格/经验 cap 分类、两个 frontier 的严格性和
$\gamma=\mu_h$ 简化。Engineer 必须复核 artifact 字段、§3 的预算、未来证书数据接口和资源边界。
Skeptic 必须独立检查 §10 的 18 门、谱映射闭包步骤、区间端点、same-operator gap 和 failure
lattice。

Skeptic 给出 `DESIGN PASS` 前：

- 不建立 `review-3-2a.md`；
- 不同步当前 README/STATUS/ROADMAP/open-problem ledger；
- 不写 MATLAB/Octave code，不创建 attempt/output，不运行实验；
- 不把 `fbie-a1` 普通双精度结果改写成 rigorous cap。

本设计的完成标准是：条件性定理和 cap budget 经独立审查通过。它不以实际 cap、gap、
independent reference 或新实验成功为完成条件。
