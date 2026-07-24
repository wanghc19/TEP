下面我先写 **1D periodic waveguide prototype** 的新 formulation。这里的“1D periodic”指：介质柱阵列沿 (x) 方向准周期，(y) 方向开口；先不进入后面 line-defect 的左右 half-lead Bloch trace 矩阵。你的原始 (A_{\mathrm{QP}}) 路线是用显式 (G_{\mathrm{QP}}) 组装 Müller matrix；现在改成 **free-space Müller near field + interior proxy sources + Rayleigh matching**，最后再把 auxiliary unknowns 消元掉。

Barnett 2010 的后半部分正是把显式 (G_{\mathrm{QP}}) formulation 看成 Schur complement；他写出 (A_{\mathrm{QP}}=A-BQ^{-1}C)，并指出 (Q) 奇异时 (G_{\mathrm{QP}}) 路线会 blow up，而完整系统仍然良态。 下面这个方案就是把同样思想改成你当前的 1D-open waveguide setting。

---

# 1. 几何和未知量

取一个截断周期 cell：

[
U_H=(-d/2,d/2)\times(-H,H),
]

中心介质柱为

[
\Omega\subset U_H,
\qquad
\Sigma=\partial\Omega.
]

背景区域为

[
D_H=U_H\setminus\overline{\Omega}.
]

外部波数为

[
k_e=k,
]

介质柱内部波数为

[
k_i=nk.
]

沿 (x) 方向的 Bloch phase 为

[
\alpha=e^{\mathrm{i}\beta d}.
]

Müller density 仍取

[
\eta=
\begin{bmatrix}
\tau\
-\sigma
\end{bmatrix}
=============

\begin{bmatrix}
\tau\
\mu
\end{bmatrix},
\qquad
\mu=-\sigma.
]

这样写的好处是，你原来 Barnett-style (A_{\mathrm{QP}}) 的 block 符号基本保留下来；你 report 里正是用 (\eta=[\tau;-\sigma]) 和 mismatch (m=[u^+-u^-;u_\nu^+-u_\nu^-]) 得到 (A_{\mathrm{QP}}\eta)，并且依靠同一对 density 使 hypersingular difference 的最强奇异性抵消。

---

# 2. 解的表示

## 2.1 内部场

内部场仍然用普通 free-space Müller layer potential：

[
u_i(x)
======

D_i[\tau](x)-S_i[\mu](x),
\qquad
x\in\Omega.
]

这里

[
S_i=S^{(k_i)},
\qquad
D_i=D^{(k_i)}.
]

也就是说，

[
S_i[\mu](x)
===========

\int_\Sigma G^{(k_i)}(x,y)\mu(y),ds_y,
]

[
D_i[\tau](x)
============

\int_\Sigma
\partial_{\nu_y}G^{(k_i)}(x,y)\tau(y),ds_y.
]

注意：这里不建议用介质柱内部点源来近似内部场。内部场本身的奇异结构、jump relation、Kress quadrature 都已经由 Müller layer potential 处理得很好。

---

## 2.2 外部 near-field 表示

外部场不再用 (S_{\mathrm{QP}},D_{\mathrm{QP}})。改写成：

[
u_e^{\mathrm{near}}(x)
======================

## \widetilde D_e[\tau](x)

\widetilde S_e[\mu](x)
+
\Phi[q](x),
\qquad
x\in D_H.
]

其中 (\widetilde S_e,\widetilde D_e) 是有限 image 的 free-space layer potential。建议第一版取 (J=1)，即 central copy 加左右邻居：

[
\widetilde S_e[\mu](x)
======================

\sum_{\ell=-J}^{J}
\alpha^\ell
\int_\Sigma
G^{(k_e)}(x,y+\ell d e_x)\mu(y),ds_y,
]

[
\widetilde D_e[\tau](x)
=======================

\sum_{\ell=-J}^{J}
\alpha^\ell
\int_\Sigma
\partial_{\nu_y}
G^{(k_e)}(x,y+\ell d e_x)\tau(y),ds_y.
]

这里 (\ell=0) 是真实中心介质柱贡献，(\ell=\pm1) 是 nearest neighbor images。加 nearest neighbors 的目的不是为了构造完整 (G_{\mathrm{QP}})，而是把最强的邻近影响直接纳入 near field，让剩下的 auxiliary correction 更光滑；Barnett 后半部分也采用“近邻直接加入 + auxiliary unknowns 处理 periodizing part”的结构。

---

## 2.3 auxiliary / proxy field

在介质柱内部放一圈 proxy points：

[
z_p\in\Omega,
\qquad
p=1,\dots,P.
]

例如圆形介质柱可以取

[
z_p=q_0+\rho(\cos t_p,\sin t_p),
\qquad
0<\rho<r.
]

定义

[
\Phi[q](x)
==========

\sum_{p=1}^{P} q_p G^{(k_e)}(x,z_p).
]

这些 (z_p) 是外部场的 proxy sources。它们的奇点在 (\Omega) 内部，所以对外部区域 (D_H) 来说是光滑的。它们不是物理点源，也不进入内部场表示。

如果第一版 proxy 不够稳定，可以升级成带有限 phase images 的 proxy field：

[
\Phi[q](x)
==========

\sum_{\ell=-J_p}^{J_p}
\alpha^\ell
\sum_{p=1}^{P}q_p
G^{(k_e)}(x,z_p+\ell d e_x).
]

但我建议第一版先取 (J_p=0)，避免多一层符号。

---

## 2.4 上下 Rayleigh far field

在上方 (y\ge H)，写 outgoing Rayleigh expansion：

[
u^+(x,y)
========

\sum_{m=-M}^{M}
a_m^+
e^{\mathrm{i}\beta_m x}
e^{\mathrm{i}\gamma_m(y-H)}.
]

在下方 (y\le -H)，写

[
u^-(x,y)
========

\sum_{m=-M}^{M}
a_m^-
e^{\mathrm{i}\beta_m x}
e^{-\mathrm{i}\gamma_m(y+H)}.
]

其中

[
\beta_m=\beta+\frac{2\pi m}{d},
]

[
\gamma_m=\sqrt{k_e^2-\beta_m^2},
\qquad
\operatorname{Im}\gamma_m\ge 0.
]

below light cone 时所有 (\gamma_m) 都是正虚部，对应指数衰减；这正是你 report 里 guided-mode 条件的作用。

未知量合并为：

[
\eta\in\mathbb C^{2N},
\qquad
q\in\mathbb C^P,
\qquad
a^+,a^-\in\mathbb C^K,
\qquad
K=2M+1.
]

---

# 3. 方程条件

总共施加四类条件。

## 3.1 介质柱边界 (\Sigma) 上的 transmission condition

在 (\Sigma) 上要求

[
u_e^{\mathrm{near},+}=u_i^-,
]

[
\partial_\nu u_e^{\mathrm{near},+}
==================================

\partial_\nu u_i^-.
]

写成 mismatch：

[
m_\Sigma
========

\begin{bmatrix}
u_e^{+}-u_i^-\
\partial_\nu u_e^{+}-\partial_\nu u_i^-
\end{bmatrix}
=0.
]

代入表示式后得到：

[
A_0\eta+B_\Sigma q=0.
]

这里

[
A_0
===

\begin{bmatrix}
I&0\
0&I
\end{bmatrix}
+
\begin{bmatrix}
\widetilde D_e-D_i
&
S_i-\widetilde S_e
\
\widetilde T_e-T_i
&
D_i^*-\widetilde D_e^*
\end{bmatrix}.
]

这就是原来 (A_{\mathrm{QP}}) 的 free-space-near-image 版本。区别只是把 (D_{\mathrm{QP}},S_{\mathrm{QP}},T_{\mathrm{QP}}) 换成 (\widetilde D_e,\widetilde S_e,\widetilde T_e)。原来的 (A_{\mathrm{QP}}) 公式正是 (I) 加四个 operator differences，并且依靠 (T_{\mathrm{QP}}-T_i) 的 singular cancellation 成为 second-kind operator。

辅助源在 (\Sigma) 上的矩阵是

[
B_\Sigma
========

\begin{bmatrix}
\Phi_\Sigma\
\partial_\nu\Phi_\Sigma
\end{bmatrix},
]

其中

[
(\Phi_\Sigma)_{jp}
==================

G^{(k_e)}(x_j^\Sigma,z_p),
]

[
(\partial_\nu\Phi_\Sigma)_{jp}
==============================

\nu_j\cdot\nabla_xG^{(k_e)}(x_j^\Sigma,z_p).
]

因为 (z_p) 距离 (\Sigma) 有正距离，所以这一块是光滑矩阵，不需要 Kress。

---

## 3.2 左右边界的 quasi-periodicity

令

[
\Gamma_L={-d/2}\times[-H,H],
\qquad
\Gamma_R={d/2}\times[-H,H].
]

在左右边界上施加

[
u_e^{\mathrm{near}}(d/2,y)
--------------------------

\alpha u_e^{\mathrm{near}}(-d/2,y)
=0,
]

[
\partial_xu_e^{\mathrm{near}}(d/2,y)
------------------------------------

\alpha\partial_xu_e^{\mathrm{near}}(-d/2,y)
=0.
]

离散后写成

[
C_{\mathrm{side}}\eta
+
Q_{\mathrm{side}}q
=0.
]

其中 Dirichlet side row 是

[
C_{\mathrm{side},D}
===================

\begin{bmatrix}
\widetilde D_R-\alpha\widetilde D_L
&
-\widetilde S_R+\alpha\widetilde S_L
\end{bmatrix},
]

[
Q_{\mathrm{side},D}
===================

\Phi_R-\alpha\Phi_L.
]

Neumann side row 是

[
C_{\mathrm{side},N}
===================

\begin{bmatrix}
\partial_x\widetilde D_R-\alpha\partial_x\widetilde D_L
&
-\partial_x\widetilde S_R+\alpha\partial_x\widetilde S_L
\end{bmatrix},
]

[
Q_{\mathrm{side},N}
===================

\partial_x\Phi_R-\alpha\partial_x\Phi_L.
]

然后

[
C_{\mathrm{side}}
=================

\begin{bmatrix}
C_{\mathrm{side},D}\
C_{\mathrm{side},N}
\end{bmatrix},
\qquad
Q_{\mathrm{side}}
=================

\begin{bmatrix}
Q_{\mathrm{side},D}\
Q_{\mathrm{side},N}
\end{bmatrix}.
]

这里用 (\partial_x)，不是 outward normal derivative，因为准周期条件比较的是同一坐标导数。

---

## 3.3 上边界 Rayleigh matching

令

[
\Gamma_T=[-d/2,d/2]\times{H}.
]

在上边界施加

[
u_e^{\mathrm{near}}(x,H)-u^+(x,H)=0,
]

[
\partial_yu_e^{\mathrm{near}}(x,H)-\partial_yu^+(x,H)=0.
]

定义 Rayleigh trace matrix

[
(P_T)_{\ell m}
==============

e^{\mathrm{i}\beta_m x_\ell^T}.
]

则

[
u^+(x_\ell^T,H)
===============

(P_Ta^+)_\ell,
]

[
\partial_yu^+(x_\ell^T,H)
=========================

(P_T,\mathrm{i}\Gamma_\gamma a^+)_\ell,
]

其中

[
\Gamma_\gamma=\operatorname{diag}(\gamma_m).
]

写成矩阵：

[
C_T\eta+Q_Tq-R_Ta^+=0,
]

其中

[
C_T=
\begin{bmatrix}
\widetilde D_T&-\widetilde S_T\
\partial_y\widetilde D_T&-\partial_y\widetilde S_T
\end{bmatrix},
]

[
Q_T=
\begin{bmatrix}
\Phi_T\
\partial_y\Phi_T
\end{bmatrix},
]

[
R_T=
\begin{bmatrix}
P_T\
P_T,\mathrm{i}\Gamma_\gamma
\end{bmatrix}.
]

---

## 3.4 下边界 Rayleigh matching

令

[
\Gamma_B=[-d/2,d/2]\times{-H}.
]

在下边界施加

[
u_e^{\mathrm{near}}(x,-H)-u^-(x,-H)=0,
]

[
\partial_yu_e^{\mathrm{near}}(x,-H)-\partial_yu^-(x,-H)=0.
]

定义

[
(P_B)_{\ell m}
==============

e^{\mathrm{i}\beta_m x_\ell^B}.
]

因为

[
u^-(x,-H)
=========

\sum_m a_m^-e^{\mathrm{i}\beta_mx},
]

[
\partial_yu^-(x,-H)
===================

-\sum_m \mathrm{i}\gamma_m a_m^-e^{\mathrm{i}\beta_mx},
]

所以

[
C_B\eta+Q_Bq-R_Ba^-=0,
]

其中

[
C_B=
\begin{bmatrix}
\widetilde D_B&-\widetilde S_B\
\partial_y\widetilde D_B&-\partial_y\widetilde S_B
\end{bmatrix},
]

[
Q_B=
\begin{bmatrix}
\Phi_B\
\partial_y\Phi_B
\end{bmatrix},
]

[
R_B=
\begin{bmatrix}
P_B\
-P_B,\mathrm{i}\Gamma_\gamma
\end{bmatrix}.
]

---

# 4. 完整扩展矩阵

把所有未知量写成

[
x_{\mathrm{ext}}
================

\begin{bmatrix}
\eta\
q\
a^+\
a^-
\end{bmatrix}.
]

完整扩展系统为

[
\mathcal E
\begin{bmatrix}
\eta\
q\
a^+\
a^-
\end{bmatrix}
=0,
]

其中

[
\mathcal E
==========

\begin{bmatrix}
A_0 & B_\Sigma & 0 & 0\
C_{\mathrm{side}} & Q_{\mathrm{side}} & 0 & 0\
C_T & Q_T & -R_T & 0\
C_B & Q_B & 0 & -R_B
\end{bmatrix}.
]

这就是“不显式构造 (G_{\mathrm{QP}})”的版本。第一行是物理介质界面条件，后面三组是 auxiliary periodization/radiation matching 条件。

这和 Barnett 后半部分的结构对应：

[
\begin{bmatrix}
A&B\
C&Q
\end{bmatrix}
\begin{bmatrix}
\eta\
\xi
\end{bmatrix}
=0.
]

区别是：Barnett 的 (\xi) 是 unit-cell wall auxiliary layer densities；这里的 auxiliary unknowns 是

[
y=
\begin{bmatrix}
q\
a^+\
a^-
\end{bmatrix},
]

也就是介质柱内部 proxy sources 加上下 Rayleigh coefficients。Barnett 的文献中也明确把 (B) 看成 auxiliary densities 对介质边界 mismatch 的作用，(C,Q) 则来自 periodization discrepancy rows。

---

# 5. 消元得到 (2N\times 2N) effective Müller matrix

为了避免扩展矩阵过大，把 auxiliary unknowns 局部消元。

设

[
y=
\begin{bmatrix}
q\
a^+\
a^-
\end{bmatrix}.
]

将完整系统写成两块：

[
A_0\eta+\overline B y=0,
]

[
C\eta+My=0.
]

其中

[
\overline B=
\begin{bmatrix}
B_\Sigma&0&0
\end{bmatrix},
]

[
C=
\begin{bmatrix}
C_{\mathrm{side}}\
C_T\
C_B
\end{bmatrix},
]

[
M=
\begin{bmatrix}
Q_{\mathrm{side}}&0&0\
Q_T&-R_T&0\
Q_B&0&-R_B
\end{bmatrix}.
]

如果 (M) 是方阵且可逆，则

[
y=-M^{-1}C\eta.
]

代回第一行：

[
\left(A_0-\overline B M^{-1}C\right)\eta=0.
]

定义

[
A_{\mathrm{eff}}
================

A_0-\overline B M^{-1}C.
]

这样最终用于 eigenvalue scan 的矩阵仍然是

[
2N\times 2N.
]

如果 (M) 是 rectangular，例如人工边界 collocation rows 多于 auxiliary unknowns，则用 least-squares 消元：

[
X=M\backslash C,
]

[
A_{\mathrm{eff}}=A_0-\overline B X.
]

在 MATLAB 中就是：

```matlab
X = M \ C;
A_eff = A0 - Bbar * X;
```

这一步就是你想要的“不要把一堆 MFS 预计算未知量永久加入后续大矩阵”。它们只在 periodization/radiation 子问题里出现，最后被 Schur complement 消掉。Barnett 2010 对 (G_{\mathrm{QP}}) formulation 的解释也是这个方向：显式 (A_{\mathrm{QP}}) 是扩展系统的 Schur complement。

---

# 6. 离散实现时各块怎么填

设 (\Sigma) 上有 (N=\texttt{ntot}) 个 Kress 节点：

[
x_j^\Sigma,\quad \nu_j,\quad w_j.
]

proxy points 有 (P) 个：

[
z_p,\quad p=1,\dots,P.
]

Rayleigh 截断为 (|m|\le M_R)，所以

[
K=2M_R+1.
]

人工边界 collocation 点数：

[
N_s \quad \text{for side walls},
]

[
N_t \quad \text{for top and bottom}.
]

建议第一版取

[
N_s\approx P/2,
\qquad
N_t\approx K,
]

然后再逐步 overcollocation，例如乘以 (1.5) 或 (2)。

---

## 6.1 组装 (A_0)

(\ell=0) 的 self-interaction 使用你已有的 Kress/Müller assembly。

(\ell\ne0) 的 neighbor images 都是光滑项，用普通 trapezoid/Nyström 直接加进 operator block：

[
\widetilde S_e=S_e^{(0)}+\sum_{\ell\ne0,|\ell|\le J}\alpha^\ell S_e^{(\ell)}.
]

[
\widetilde D_e=D_e^{(0)}+\sum_{\ell\ne0,|\ell|\le J}\alpha^\ell D_e^{(\ell)}.
]

[
\widetilde T_e=T_e^{(0)}+\sum_{\ell\ne0,|\ell|\le J}\alpha^\ell T_e^{(\ell)}.
]

然后填：

[
A_0
===

I_2+
\begin{bmatrix}
\widetilde D_e-D_i
&
S_i-\widetilde S_e
\
\widetilde T_e-T_i
&
D_i^*-\widetilde D_e^*
\end{bmatrix}.
]

这里 (I_2) 表示上下两个 (N\times N) identity blocks。

---

## 6.2 组装 (B_\Sigma)

[
B_\Sigma=
\begin{bmatrix}
B_{\Sigma,D}\
B_{\Sigma,N}
\end{bmatrix}.
]

其中

[
(B_{\Sigma,D})_{jp}
===================

G^{(k_e)}(x_j^\Sigma,z_p),
]

[
(B_{\Sigma,N})_{jp}
===================

\nu_j\cdot\nabla_xG^{(k_e)}(x_j^\Sigma,z_p).
]

如果 proxy 使用 finite phase images，则把上式替换为

[
\sum_{\ell=-J_p}^{J_p}
\alpha^\ell G^{(k_e)}(x_j^\Sigma,z_p+\ell d e_x),
]

以及对应 target normal derivative。

---

## 6.3 组装 side rows

对 side collocation points

[
x_\ell^L=(-d/2,y_\ell),
\qquad
x_\ell^R=(d/2,y_\ell),
]

计算 layer-potential trace matrices：

[
\widetilde S_L,\widetilde D_L,\partial_x\widetilde S_L,\partial_x\widetilde D_L,
]

[
\widetilde S_R,\widetilde D_R,\partial_x\widetilde S_R,\partial_x\widetilde D_R.
]

再填：

[
C_{\mathrm{side},D}
===================

\begin{bmatrix}
\widetilde D_R-\alpha\widetilde D_L
&
-\widetilde S_R+\alpha\widetilde S_L
\end{bmatrix},
]

[
C_{\mathrm{side},N}
===================

\begin{bmatrix}
\partial_x\widetilde D_R-\alpha\partial_x\widetilde D_L
&
-\partial_x\widetilde S_R+\alpha\partial_x\widetilde S_L
\end{bmatrix}.
]

proxy rows：

[
Q_{\mathrm{side},D}
===================

\Phi_R-\alpha\Phi_L,
]

[
Q_{\mathrm{side},N}
===================

\partial_x\Phi_R-\alpha\partial_x\Phi_L.
]

---

## 6.4 组装 top rows

对 top nodes

[
x_\ell^T=(x_\ell,H),
]

计算

[
\widetilde S_T,\widetilde D_T,\partial_y\widetilde S_T,\partial_y\widetilde D_T,
]

以及

[
\Phi_T,\partial_y\Phi_T.
]

然后

[
C_T=
\begin{bmatrix}
\widetilde D_T&-\widetilde S_T\
\partial_y\widetilde D_T&-\partial_y\widetilde S_T
\end{bmatrix},
]

[
Q_T=
\begin{bmatrix}
\Phi_T\
\partial_y\Phi_T
\end{bmatrix}.
]

Rayleigh matrix：

[
(P_T)*{\ell m}=e^{\mathrm{i}\beta_m x*\ell}.
]

[
R_T=
\begin{bmatrix}
P_T\
P_T,\mathrm{i}\Gamma_\gamma
\end{bmatrix}.
]

---

## 6.5 组装 bottom rows

对 bottom nodes

[
x_\ell^B=(x_\ell,-H),
]

同理计算

[
C_B=
\begin{bmatrix}
\widetilde D_B&-\widetilde S_B\
\partial_y\widetilde D_B&-\partial_y\widetilde S_B
\end{bmatrix},
]

[
Q_B=
\begin{bmatrix}
\Phi_B\
\partial_y\Phi_B
\end{bmatrix}.
]

Rayleigh matrix：

[
(P_B)*{\ell m}=e^{\mathrm{i}\beta_m x*\ell}.
]

[
R_B=
\begin{bmatrix}
P_B\
-P_B,\mathrm{i}\Gamma_\gamma
\end{bmatrix}.
]

---

# 7. 数值目标

最终有两个可比较对象。

旧路线：

[
A_{\mathrm{QP}}\eta=0.
]

新路线：

[
A_{\mathrm{eff}}\eta=0,
\qquad
A_{\mathrm{eff}}=A_0-\overline B(M\backslash C).
]

然后扫描

[
\sigma_{\min}(A_{\mathrm{eff}}(k,\beta)).
]

如果新旧 dips 一致，说明显式 (G_{\mathrm{QP}}) 只是把 auxiliary matching 子问题预先消元进 kernel 里；如果新方法在某些参数处更平滑，则说明你的怀疑是对的：显式 (G_{\mathrm{QP}}) 填 (A_{\mathrm{QP}}) 是一个 reduced formulation，不一定是最稳健的基本 formulation。
