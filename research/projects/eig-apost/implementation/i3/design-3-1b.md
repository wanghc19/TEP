# I3.1 全波导 conforming weak-residual 设计

## 摘要与状态

- **Design ID:** `I3.1-Q1-RT0-WEAK-RESIDUAL-V2`
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `DESIGN PASS`
- **Implementation:** `NOT STARTED`
- **Run:** `NOT AUTHORIZED`

本设计的最终目标是估计 saved candidate

$$
\widehat k_h=1.832770289108157,
\qquad
\mu_h=\widehat k_h^2,
$$

到连续算子在 projected gap 内离散谱的距离。第一步 weak residual 实际控制的是到整个连续谱
$\sigma(A)$ 的距离；只有以后再有 certified projected gap containment，才能把谱点升级为 gap 内
离散特征值。本文不定位 finite-matrix zero，不跟踪 score minimizer，也不把 QZ residual 当作
连续 residual。

历史 `center-a1` 用固定单胞 cutoff 得到过宽的强残量；`lead-a3` 又因近材料圆的 BIE 点值
无法资格化而停在 `CONFORMING_RECONSTRUCTION_UNRESOLVED`。这两个 append-only 负结果及其代码
保持不变，见 [[research/projects/eig-apost/implementation/i3/review-3-1|center review]]、
[[research/projects/eig-apost/implementation/i3/review-3-1b|lead review]]、
[[test/i3/s-resid/README|center experiment]] 和
[[test/i3/g-resid/README|lead experiment]]。本文按当前授权重写旧路线，不再保留失效的
BIE--Hermite/bubble 拟合合同。

新路线只有三步：

1. frozen QZ 数据产生左右半波导上共享的墙面 Dirichlet trace 序列；
2. 每个胞元用真实材料系数的 conforming Q1 Dirichlet problem 构造全局 $H^1$ trial；
3. 从该 trial 构造全局 RT0 通量，并用 functional majorant 估计连续 weak residual。

majorant 的数学不等式没有未知常数；但普通双精度线性代数、积分和无限尾尚无 outward
enclosure。因此首轮实验至多交付 `COMPUTED_CONTINUOUS_WEAK_RESIDUAL_ESTIMATOR_CANDIDATE`，
不能直接声称可靠谱区间或 gap 内离散特征值存在。

## 1. 路线比较与选择

| 路线 | 与目标的关系 | 当前决定 |
|---|---|---|
| exact 单胞解算子与传播算子 | exact cell extension 能从共享 trace 重建半波导场 | 作为理论原型；finite $P_h$ 不继承 exact propagation 定理 |
| BIE 直接重建与近边界高精度求值 | 可给胞内物理场，但必须闭合材料圆 trace、close evaluation 和无限拼接 | 暂停；`lead-a3` 暴露当前 direct close evaluation 未资格化，且没有区分 close-evaluation 与 fit/basis 原因 |
| conforming weak residual | 只要求 $H^1$ 场；材料与胞元界面的 flux 误差由 residual 看见 | **选定主线** |
| supercell、PML 或独立高阶 FEM | 可给独立 reference 或另一 formulation | 保留给 I3.2；不得同时参与本 estimator 的校准 |

[[ref/ref_data/Fliss2013.pdf|Fliss (2013)]] Theorem 4.1、4.5、式 (4.9)--(4.13) 和
Theorem 4.12 说明：在 exact half-guide
problem well posed、exact cell problems 可解且 exact propagation radius 小于一时，可以由单胞
Dirichlet 解算子逐胞重建半波导。[[ref/ref_data/Hohage2013.pdf|Hohage--Soussi (2013)]]
Theorem 2.2 说明 translation operator
可能含 Jordan 结构。因此本设计保留 whole-matrix $P_h$ action，但不把它称为 exact Fliss
propagation。

[[ref/ref_data/Giani2013.pdf|Giani (2013)]] Definition 3、式 (22) 以及
[[ref/ref_data/Engstrom2016.pdf|Engstrom--Giani--Grubisic (2016)]] Theorem 4.3
说明 conforming Galerkin 场的 volume residual 和 flux jump 是自然的 weak-residual 对象。
这些论文研究的离散问题和本无限波导并不相同，不能替本项目给出可靠常数或谱区间。下文的
RT0 functional majorant 是针对本项目 shifted form 的直接推导，不冒充这些论文中的定理。

BIE 路线不作为当前主线还有两个具体原因。第一，旧代码中的 $\tau$ 是 double-layer density，
不是物理 Dirichlet trace；必须先由 on-surface jump formulas 构造 exterior/interior traces，再作
conforming repair。第二，本地 [[ref/ref_data/Hao2014.pdf|Hao et al. (2014)]] 研究 Nyström
奇异求积，但其 potential tests
明确避开 close evaluation，不能资格化 `lead-a3` 中距圆远小于 panel spacing 的 targets。若以后
恢复 BIE 路线，必须先引入并原文核验真正的 close-evaluation 方法，再另行设计。

## 2. 连续对象与目标 residual

波导、材料和 Bloch parameter 固定为

$$
B=\mathbb R\times(-1/2,1/2),
\qquad
\beta=0.5,
$$

$$
\rho(x,y)=
\begin{cases}
17,&(x,y)\text{ 位于周期 lead 的半径 }0.2\text{ 圆盘内},\\
1,&\text{ 其他位置}.
\end{cases}
$$

中心空列没有材料圆。连续算子为

$$
A=-\rho^{-1}\Delta
$$

作用在

$$
H=L^2(B,\rho\,\mathrm dx\,\mathrm dy).
$$

其 form domain 是满足 $y$ 向 $\beta$-准周期条件的

$$
V=H^1_\beta(B).
$$

定义

$$
a(u,v)=\int_B\nabla u\cdot\overline{\nabla v},
\qquad
b(u,v)=\int_B\rho u\overline v.
$$

预先固定 shift

$$
\gamma=\mu_h>0,
$$

并令

$$
\|v\|_V^2=a(v,v)+\gamma b(v,v).
$$

对任何非零 $u_h^{\mathrm c}\in V$，连续 weak residual 是

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h b(u_h^{\mathrm c},v),
\qquad v\in V.
$$

本阶段要估计

$$
q_h=\frac{\|R_h\|_{V'}}{\|u_h^{\mathrm c}\|_V}.
$$

finite $A_{\mathrm{def}}^Dq$、QZ invariant residual、cell linear-solve residual 只检查输入或实现，
不能替代 $R_h$。

### 2.1 无未知常数的 functional majorant

对任意满足相同准周期条件的 $\sigma_h\in H(\operatorname{div};B)$，分部积分给出

$$
R_h(v)
=\int_B(\nabla u_h^{\mathrm c}-\sigma_h)\cdot\overline{\nabla v}
-\int_B(\operatorname{div}\sigma_h+\mu_h\rho u_h^{\mathrm c})\overline v.
$$

因此 Cauchy--Schwarz 不等式直接给出

$$
\|R_h\|_{V'}\le \mathcal M_h,
$$

其中

$$
\mathcal M_h^2
=\|\nabla u_h^{\mathrm c}-\sigma_h\|_{L^2(B)}^2
+\gamma^{-1}
\|\rho^{-1/2}(\operatorname{div}\sigma_h+
\mu_h\rho u_h^{\mathrm c})\|_{L^2(B)}^2.
$$

该不等式对任意 conforming $u_h^{\mathrm c}$ 和任意 global $H(\operatorname{div})$ flux
成立；它不要求 $u_h^{\mathrm c}$ 是离散矩阵根、score minimizer 或 exact cell solution。

正式代码使用 periodic gauge

$$
u(x,y)=e^{\mathrm i\beta y}\widetilde u(x,y),
$$

把 $y$ 向准周期条件变成普通周期条件。相应地

$$
\nabla_\beta=(\partial_x,\partial_y+\mathrm i\beta),
\qquad
\operatorname{div}_\beta\widetilde\sigma
=\partial_x\widetilde\sigma_x
+(\partial_y+\mathrm i\beta)\widetilde\sigma_y.
$$

Q1 trial、RT0 flux、cell matrices 和 majorant 全部在该 gauge 中计算；report 再说明它们对应
原物理场。

## 3. 当前数据到共享 Dirichlet skeleton

固定 I2 fine object：

$$
n_{\mathrm{tot}}=256,
\qquad M=48,
\qquad K=2M+1=97.
$$

只在 seed 和 saved candidate 各调用一次 `eval_i21`。沿用其 geometry、proxy、branch、QZ
cluster、fixed rows、chart、solver 和物理权重；不扫描或改变 $k$。

从 candidate node 读取 $Z_\pm$、冻结 channel phase 和 scattering pencil
$(A_{\mathrm{sc}},B_{\mathrm{sc}})$。按 evaluator 的 block ordering 定义

$$
Z_\pm=\begin{bmatrix}A_\pm\\B_\pm\end{bmatrix},
\qquad
D_\pm=A_\pm+B_\pm.
$$

令 $W=X_R-X_L=1$，并以 evaluator 返回的同一 branch $\gamma_m$ 定义 cell phase matrix

$$
E_{\mathrm c}
=\operatorname{diag}\!\left(e^{\mathrm i\gamma_mW}\right).
$$

这里的 channel quantities $\gamma_m$ 与 §2 中的 scalar shift $\gamma=\mu_h$ 是不同对象。
whole-subspace actions 定义为

$$
P_+=(B_{\mathrm{sc}}Z_+)\backslash(A_{\mathrm{sc}}Z_+),
$$

$$
P_-=(A_{\mathrm{sc}}Z_-)\backslash(B_{\mathrm{sc}}Z_-).
$$

不得重新 QZ、逐 multiplier 对角化或按结果换 cluster。每侧要求 rank $K$、invariant residual
不超过 $10^{-10}$。条件数门分别对 $B_{\mathrm{sc}}Z_+$ 和 $A_{\mathrm{sc}}Z_-$ 作 thin QR，
要求所得三角因子
$R$ 满足 $\operatorname{rcond}(R)\ge10^{-8}$，并保存反斜杠求解的 relative solve residual 和
上述 invariant residual。

按 I2 物理权重从 $A_{\mathrm{def}}^D$ 的最小右奇异向量得到归一化 $q=[q_L;q_R]$，再解

$$
D_-c_-=[I,E_{\mathrm c}]q,
\qquad
D_+c_+=[E_{\mathrm c},I]q.
$$

右 lead 的第 $n$ 个胞元使用共享 wall traces

$$
(d_{n,0}^+,d_{n,1}^+)
=(D_+P_+^nc_+,D_+P_+^{n+1}c_+).
$$

左 lead 按物理 $x$ 从左到右使用

$$
(d_{n,0}^-,d_{n,1}^-)
=(D_-P_-^{n+1}c_-,D_-P_-^nc_-).
$$

中心空列两墙为 $D_-c_-$ 和 $D_+c_+$。所以相邻胞元共享同一个 Fourier Dirichlet trace，
不是靠运行后平均 candidate 数值或 BIE 点值连接。未保留的 Fourier coefficients 在 trial 中定义为
零；它们的缺失只能由 continuous residual 暴露，不能事后补 mode。

physical trace coefficients 必须先按

$$
u_{\mathrm{wall}}(y)
=\sum_{m=-M}^M d_m
e^{\mathrm i(\beta+2\pi m)y}
$$

重构，再去掉 $e^{\mathrm i\beta y}$ 得到 periodic-gauge boundary data。不得把 physical
Fourier basis 直接当成 periodic Q1 nodal values。

## 4. Q1 单胞解算子与全局 $H^1$ trial

### 4.1 固定离散层

使用 reference cell $[-1/2,1/2]^2$ 上的结构化 Q1 mesh。两层预注册为：

| level | $N_x$ | $N_y$ | disk polar $N_r$ | disk polar $N_\theta$ |
|---|---:|---:|---:|---:|
| coarse | 64 | 128 | 32 | 128 |
| fine | 96 | 192 | 48 | 192 |

$N_y$ 个 periodic nodal unknowns 在 top/bottom 只保留一份。圆盘不切割 Q1 function space；
因为 principal form 是 $\int|\nabla u|^2$，单一 Q1 field 本身属于 $H^1$。材料 jump 只进入
mass 和 majorant 的第二项。$N_V^2$ 中的 weighted mass 以及
$B_h^2=\int\rho^{-1}|\operatorname{div}_\beta\widetilde\sigma_h+
\mu_h\rho\widetilde u_h^{\mathrm c}|^2$ 都用 background rectangle 加 true-circle polar contrast，
不得用 Cartesian inside/outside mask 代替。这里的 `true-circle` 只指几何区域使用真实圆，不表示
ordinary quadrature 已经 outward-enclosed。

### 4.2 Physical Dirichlet cell problem

在 reference cell $C=[-1/2,1/2]^2$ 上定义

$$
a_\beta(\widetilde u,\widetilde v)
=\int_C\nabla_\beta\widetilde u\cdot
\overline{\nabla_\beta\widetilde v},
\qquad
b_\rho(\widetilde u,\widetilde v)
=\int_C\rho\widetilde u\overline{\widetilde v}.
$$

对给定左右 gauge traces $(g_0,g_1)$，令 $E_h(g_0,g_1)$ 是 Q1 Galerkin 解：固定两墙
Dirichlet data，并对所有零墙面 trace 的 periodic-gauge Q1 test functions $v_h$ 满足

$$
a_\beta(E_h,v_h)-\mu_h b_\rho(E_h,v_h)=0.
$$

这是真实材料系数下的离散 Helmholtz Dirichlet problem，不是 coercive harmonic extension。
lead cell 一次 sparse factorization 后构造左右各 $K$ 列的 solution maps；中心空列只解当前
一组 wall data。

实际 factor 是 $C_h=K_{\beta,h}-\mu_hM_{\rho,h}$。只允许用
$K_{\beta,h}+\mu_hM_{\rho,h}$ 的 diagonal 作对称 scaling；不得加 shift、改方程或在失败后切换
Robin problem。scaled reciprocal condition estimate 必须至少 $10^{-10}$，左右共 $2K$ 个
right-hand sides 的 scaled backward/relative residual 都不得超过 $10^{-10}$。失败为
`CELL_EXTENSION_UNRESOLVED`。

所得 Q1 field 只是一个 conforming trial，不称 exact PDE solution。它在每个 cell wall 采用共享
nodal trace，在 top/bottom 使用同一 periodic DOF，并以同一个 Q1 function 穿过材料圆。因此，
只要无限 $H^1$ sum 收敛，逐胞拼接给出

$$
u_h^{\mathrm c}\in V.
$$

center/lead、lead/lead 的共同 wall nodal defect、gauged periodic seam defect和恢复到 physical
variables 后的 $\beta$-quasiperiodic defect都必须不超过 $10^{-12}$。

## 5. Global RT0 flux

在同一矩形 mesh 上构造 complex RT0 flux $\widetilde\sigma_h$。每条 mesh edge 采用唯一 global
orientation；其 normal degree of freedom 取相邻 Q1 elements 的 one-sided
$\nabla_\beta\widetilde u_h^{\mathrm c}\cdot n$ edge means 的算术平均。由此：

- 普通 element edges 上 normal component 单值；
- lead/lead 与 center/lead walls 使用两侧 cell fields 的平均；
- top/bottom seam 在 periodic gauge 中使用同一个 $+e_y$ orientation；
- 材料圆不是 principal-part mesh interface，不额外制造 flux jump；$\rho$ 由 volume term处理。

该构造先在每个有限 cell union 上给出 normal-continuous 的
$H_{\mathrm{per}}(\operatorname{div})$ flux。只有 §6 的 infinite-tail sums 闭合后才升级为
global statement：$N_V^2<\infty$ 与 $A_h^2<\infty$ 推出
$\widetilde\sigma_h\in L^2(B)^2$，而 $B_h^2<\infty$ 与
$u_h^{\mathrm c}\in L^2(B,\rho)$ 推出
$\operatorname{div}_\beta\widetilde\sigma_h\in L^2(B)$。此时才有

$$
\widetilde\sigma_h\in H_{\mathrm{per}}(\operatorname{div};B),
$$

等价于物理准周期 $\sigma_h\in H_\beta(\operatorname{div};B)$。所有 internal、cell-wall、
center/lead 和 periodic-seam normal-DOF defects 都必须不超过 $10^{-12}$；这些局部门单独不能
证明无限波导上的 global $H(\operatorname{div})$ 归属。

避免 $P^{-1}$ 的固定索引如下。每侧第一个 lead cell 及其与 center 的 flux 单列。对其后的
第 $n$ 个 cell，以 parent state $s=P^{n-1}c$ 参数化：目标 cell field 使用 $Ps$，左右邻居分别
使用 $s$ 和 $P^2s$。两墙平均 flux 以及 cell RT0 coefficients 都是 $[I,P,P^2]s$ 的固定线性
映射。因此每个 tail contribution 仍可写成 $s^*Ws$。左 lead 使用相同结构，但必须显式保留
物理左右次序。

## 6. Majorant、无限尾与数值门

每个 lead level 构造三个 Hermitian Gram matrices，分别对应

$$
N_V^2=\|u_h^{\mathrm c}\|_V^2,
$$

$$
A_h^2
=\|\nabla_\beta\widetilde u_h^{\mathrm c}-
\widetilde\sigma_h\|_{L^2}^2,
$$

$$
B_h^2
=\|\rho^{-1/2}(\operatorname{div}_\beta\widetilde\sigma_h
+\mu_h\rho\widetilde u_h^{\mathrm c})\|_{L^2}^2.
$$

因此

$$
\mathcal M_h^2=A_h^2+\gamma^{-1}B_h^2,
\qquad
q_h^{\mathrm{diag}}=\mathcal M_h^{\mathrm{diag}}/N_V^{\mathrm{diag}}.
$$

center 和每侧首胞单列；其余无限尾对 full $P_\pm$ 使用

$$
W_N=\sum_{n=0}^{N-1}(P^n)^*WP^n
$$

以及 whole-matrix doubling。不得用 spectral radius、逐 eigenvalue decay 或最后一胞幅度代替
whole-matrix action；这样保留 nonnormal transient 和 Jordan coupling。

冻结 doubling levels $N=2^j$、$j=0,\ldots,12$。primary $P_N^{(d)}$ 由 doubling 形成；
alternate $P_N^{(a)}$ 在 $j<3$ 时直接左结合相乘，在 $j\ge3$ 时把八个
$P_{N/8}^{(d)}$ 左结合相乘。预注册

$$
e_N=\|P_N^{(d)}-P_N^{(a)}\|_2
+100K\epsilon_{\mathrm{mach}}
\max\{1,\|P_N^{(d)}\|_2,\|P_N^{(a)}\|_2\},
$$

$$
a_{\mathrm{hi}}=\|P_N^{(d)}\|_2+e_N.
$$

对 Gram accumulator 同时计算

$$
W_{2N}^{(L)}=W_N^{(L)}
+((P_N^{(d)})^*W_N^{(L)})P_N^{(d)},
$$

$$
W_{2N}^{(R)}=W_N^{(R)}
+(P_N^{(d)})^*(W_N^{(R)}P_N^{(d)}),
$$

初值固定为 $W_1^{(L)}=W_1^{(R)}=W$。固定 primary $W_N=W_N^{(L)}$ 及

$$
\omega_N=\|W_N^{(L)}-W_N^{(R)}\|_2
+100K\epsilon_{\mathrm{mach}}
\max\{1,\|W_N^{(L)}\|_2,\|W_N^{(R)}\|_2\}.
$$

这些是可复算的 ordinary-double association/roundoff allowances，不是 certified error
bounds。只有在

$$
a_{\mathrm{hi}}<1
$$

且 $N_V^2$ 与 $\mathcal M_h^2$ 的 tail shares 都不超过 $10^{-6}$ 时，computed tail gate
才通过。对每个 side、每个 PSD Gram accumulator $W_N$ 和起始 coefficient $c$，
block-geometric computed tail allowance 和 tail share 固定为

$$
t_N=\frac{a_{\mathrm{hi}}^2}{1-a_{\mathrm{hi}}^2}
(\|W_N\|_2+\omega_N)\|c\|_2^2,
\qquad
s_N=\frac{t_N}
{\max\{\operatorname{Re}(c^*W_Nc),\mathrm{realmin}\}}.
$$

$N_V^2$ 和 majorant numerator 的左右 tail 均要求 $s_N\le10^{-6}$。这些量仍是
ordinary-double diagnostics，不是已证明 enclosure。

两层必须分别从 Q1 solve、RT0 flux、Gram 到 tail 完整重算。预注册经验门为

$$
\frac{|A_f^2-A_c^2|}
{\max\{\mathcal M_f^2,\mathcal M_c^2,\mathrm{realmin}\}}
\le0.20,
$$

$$
\frac{|B_f^2/\gamma-B_c^2/\gamma|}
{\max\{\mathcal M_f^2,\mathcal M_c^2,\mathrm{realmin}\}}
\le0.20,
$$

$$
\frac{|N_{V,f}^2-N_{V,c}^2|}
{\max\{N_{V,f}^2,N_{V,c}^2,\mathrm{realmin}\}}
\le0.20.
$$

对 level $\ell$，仅当 $q_\ell^{\mathrm{diag}}<1$ 时，按 §7 的同一非对称公式定义
$L_\ell^{\mathrm{diag}},U_\ell^{\mathrm{diag}}$，并令 nominal $k$-interval width 为

$$
w_\ell=\operatorname{diam}(I_\ell^k)
=\sqrt{U_\ell^{\mathrm{diag}}}-\sqrt{L_\ell^{\mathrm{diag}}}.
$$

两层 width 还必须满足

$$
|w_f-w_c|
\le\max\{0.20w_f,0.10\tau_k^{\mathrm{pre}}\}.
$$

该 width 门只在 coarse、fine 两层均有 $q_h^{\mathrm{diag}}<1$、因而两个 nominal interval 都已
定义时执行；任一层 $q_h^{\mathrm{diag}}\ge1$ 时记为 `NOT_APPLICABLE`，最终按
`WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT` 分类，不误记为 mesh failure。已定义时若该门失败，
则为 `MESH_RESOLUTION_UNRESOLVED`。Gram raw Hermitian defect 必须不超过 $10^{-12}$；
Hermitian part 的最低 eigenvalue 不得低于 $-10^{-12}$ 乘 matrix scale。对
$10^8e^{\mathrm i\pi/7}(q,c_-,c_+)$ 重算 cell、RT0 和 tail，最终 $q_h^{\mathrm{diag}}$
的 phase/scale relative defect 必须不超过 $10^{-11}$。

这些门只说明当前有限元、积分和 tail diagnostics 内部可复算。普通双精度下不得把
$\mathcal M_h^{\mathrm{diag}}$ 称为可靠 residual upper bound，也不得把 $N_V^{\mathrm{diag}}$
称为可靠 lower bound。

## 7. 谱区间与结论边界

如果将来得到 outward residual upper bound $\overline{\mathcal M}_h$ 和 field-norm lower bound
$\underline N_{V,h}>0$，则

$$
\overline q_h
=\frac{\overline{\mathcal M}_h}{\underline N_{V,h}}
$$

是 $q_h$ 的可靠上界。若 $\overline q_h<1$，由

$$
\inf_{\lambda\in\sigma(A)}
\frac{|\lambda-\mu_h|}{\lambda+\gamma}
\le\overline q_h
$$

可取

$$
L_h=
\max\left\{0,
\frac{\mu_h-\overline q_h\gamma}{1+\overline q_h}
\right\},
$$

$$
U_h=
\frac{\mu_h+\overline q_h\gamma}{1-\overline q_h}.
$$

可靠实现必须先为 stored candidate 的平方形成 outward-rounded $\mu_h$ enclosure，并对上式的
$L_h,U_h$ 和

$$
I_h^k=[\sqrt{L_h},\sqrt{U_h}]
$$

作 outward rounding；ordinary-double 点值代入不能替代这一步。

本轮只把 ordinary-double $q_h^{\mathrm{diag}}$ 代入同一公式，形成明确标注为 non-certified
的 nominal interval；若 $q_h^{\mathrm{diag}}\ge1$，则不定义有限 nominal interval。

预注册绝对分辨率继续为

$$
\tau_k^{\mathrm{pre}}=10^{-6}.
$$

若 nominal interval 不可定义或其 $k$-space 宽度超过 $10^{-6}$，结果为
`WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT`。这是有效负结果，不能授权修改 mesh、trace、flux 或
threshold 后沿用同一 attempt。

projected gap 尚未认证，所以相对分辨率参数

$$
\rho_G^{\mathrm{pre}}=0.1
$$

固定为 `NOT_REACHED`。只有可靠 $[L_h,U_h]$ 完全落入当前 sharp-disk continuous operator 的
certified projected gap $G_\lambda$，才能说区间内至少存在一个不属于本质谱的离散特征值。
即使 containment 成立，只有

$$
\operatorname{diam}(I_h^k)\le\tau_k^{\mathrm{pre}},
\qquad
\operatorname{diam}(I_h^k)
\le\rho_G^{\mathrm{pre}}\operatorname{diam}(G_k),
$$

其中 $G_k$ 是 $G_\lambda$ 在正频率下的 outward-safe image，结果才达到预注册的
resolution grade。containment 成立而任一宽度门失败时，保留存在性但报告
`EXISTS_BUT_RESOLUTION_INSUFFICIENT`。nominal interval 再窄也不能据此声称 gap containment、
连续离散特征值存在、唯一 target、continuous eigenvalue error 或 upper bound。

## 8. 失败语义

按科学依赖固定首败顺序：

1. evaluator、dependency、output collision 或资源失败：`EXECUTION_UNAVAILABLE`；
2. I2 finite input health 失败：`FINITE_DISCRETE_INPUT_UNAVAILABLE`；
3. $P_\pm$ rank、rcond 或 invariant residual 不可用：
   `PROPAGATION_ACTION_UNRESOLVED`；
4. physical Dirichlet Q1 factor 病态、RHS solve 失败或 mesh/disk integration object 不一致：
   `CELL_EXTENSION_UNRESOLVED`；
5. wall、periodic seam 或非零 $H^1$ field 失败：`FORM_CONFORMITY_UNRESOLVED`；
6. global RT0 normal continuity 或 finite flux coefficients 失败：
   `HDIV_FLUX_UNRESOLVED`；
7. majorant 或 field-norm integral nonfinite、对象装配不一致或积分失败：
   `MAJORANT_QUADRATURE_UNRESOLVED`；
8. per-cell Gram Hermitian/PSD 门失败：`MAJORANT_QUADRATURE_UNRESOLVED`；
9. full-matrix contraction 或 tail shares 失败：`INFINITE_TAIL_UNRESOLVED`；
10. 完整 tail totals 的 coarse/fine 或 phase/scale 门失败：
    `MESH_RESOLUTION_UNRESOLVED`；
11. computed ratio 不小于一、nominal interval 不可定义或 nominal width 过大：
    `WEAK_RESIDUAL_RESOLUTION_INSUFFICIENT`；
12. computed ratio 与 nominal width 通过：仍报告
    `RELIABLE_SPECTRAL_INTERVAL_UNAVAILABLE`，并同时记录
    `PROJECTED_GAP_NOT_ESTABLISHED`。

cell Dirichlet factor 失败时不得在本 attempt 中改用 Robin-to-Robin。Fliss (2013)
Remarks 4.2 与 4.11 说明 Dirichlet formulation 的例外频率及 RtR 备选；那是需要另行冻结的
后续路线，不是本次失败后的自动 fallback。

## 9. 最低成本实现、数据和预算

### 9.1 文件边界

优先使用单一 MATLAB entry：

```text
test/i3/w-resid/check_w_resid.m
```

其职责是 evaluator、trace skeleton、Q1 cell maps、RT0 flux、majorant、tail、schema 和 report。
只有当实现超过 $1000$ 行时，才允许拆出一个有明确科学边界的模块：

```text
test/i3/w-resid/i31_fe_cell.m
```

该模块只负责 periodic-gauge Q1 mesh、physical cell solve、RT0 reconstruction 和 per-cell Gram。
不得为 config、schema、路径、未来扩展或普通 utilities 增加文件。历史 `check_s_resid.m`、
`check_g_resid.m`、`i31_bie_fit.m` 及其 outputs 全部不改。

### 9.2 最少 schema

未来 append-only result 至少保存：

- saved candidate、fine evaluator config、$q,c_-,c_+$ 和 $P_\pm$ diagnostics；
- 两层 mesh、periodic gauge、disk polar correction 和 cell-factor diagnostics；
- shared wall traces、Q1 map dimensions、factor/solve diagnostics、形成的 small Gram matrices
  及 center/lead/lead conformity defects；不得把约 $19\,000\times97$ 的 dense solution maps
  写入 `result.mat`；
- global RT0 edge orientation、normal-continuity defects 和 flux maps；
- center、首胞和 tail 的 $N_V^2$、$A_h^2$、$B_h^2$、$\mathcal M_h^2$ 与 $q_h$；
- 每个 doubling level 的 full-$P$ action norm、allowance 和 tail shares；
- coarse/fine、phase/scale 和 Hermitian/PSD checks；
- nominal interval、reliability flags、first failure、elapsed time、active-object memory 和 retry history。

machine flags 必须至少包含：

```text
continuous_form_residual_computed
functional_majorant_formula_applied
residual_upper_bound_certified=false
field_lower_bound_certified=false
tail_diagnostic_certified=false
projected_gap_established=false
continuous_discrete_eigenvalue_existence=false
continuous_error_bound=false
```

### 9.3 成本

一次 seed、一次 saved-candidate point；每个 mesh level 对一个 periodic lead cell 作一次 sparse
factorization和左右各 $K$ 列 solve，center 只作一个 RHS。per-cell maps 流式形成 Gram，不同时保留
所有 dense field matrices。

预估总耗时 $2$--$12$ 分钟，峰值 $150$--$300$ MiB；soft/hard time 为 $900/1800$ 秒，
active-object memory 上限 $512$ MiB。资源门只在安全 stage boundary 检查；它不是 OS watchdog。

未来 attempt tag、命令和 append-only 目录必须在实现完成后另行冻结。当前设计不预留可运行命令，
也不授权写代码或运行 MATLAB/Octave。

## 10. 理论—实现验收

实现前的 spec-to-code 审查必须逐项确认：

1. finite QZ 只产生 trace sequence，没有被称为 exact continuous propagation；
2. Q1 Dirichlet maps 使用真实 $K_\beta-\mu_hM_\rho$；$N_V^2$ 的 weighted mass 和 majorant
   第二项均用 true-circle polar contrast；
3. wall sharing、periodic gauge 和 global RT0 normal continuity 使 $u_h^{\mathrm c}\in V$、
   $\sigma_h\in H(\operatorname{div})$；
4. majorant 两项和 field norm 使用同一个全波导对象，先合成再取 norm；
5. infinite sum 保留 full-matrix nonnormal/Jordan action；
6. ordinary-double diagnostics、reliable enclosure、projected gap 和 unique target 的语义严格分开。

若这些对象与公式没有一一落到实现，Skeptic 应停止运行授权。若全部闭合，首轮数值结果无论是
small、large、unresolved 或 resource failure 都是有效结果；不得为了达到 $10^{-6}$ 修改 mesh、
flux reconstruction、tail level 或解释。

本设计若成功只能说明：当前 saved candidate 产生了一个可复算的全波导 conforming Q1 trial，
并给出一个直接面向连续 weak residual 的 computed functional-majorant candidate。形成可靠谱区间
仍需 outward numerical enclosure；从谱区间升级为 gap 内离散特征值存在还需 certified projected
gap；唯一目标识别仍是可选的第二层问题。

理论主线见
[[research/projects/eig-apost/phase3-analysis/s-estimator|continuous residual theory]]、
[[research/projects/eig-apost/phase3-analysis/s-errors|error coverage]] 和
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|cell/propagation boundary]]；
I2 输入见 [[research/projects/eig-apost/implementation/i2/report|I2 report]]；I3 当前路线入口见
[[research/projects/eig-apost/implementation/i3/README|I3 README]]。
