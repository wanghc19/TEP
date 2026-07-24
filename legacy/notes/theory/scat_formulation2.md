# `scat_formulation2.md`

# 中心 cell 含介质柱时的 scattering formulation

本文是 `scat_formulation.md` 的后续笔记。旧笔记前三节中关于 Rayleigh trace space、incoming/outgoing trace 子空间、以及 forcing/scattered decomposition 的内容不再重复。本文只保留进入中心介质柱问题所需的最小前置符号，并从中心 cell 含介质柱的 lead incoming scattering problem 开始推导。

如果本文符号与旧笔记冲突，以本文为准。

---

## 1. 必要符号约定与前置基础

### 1.1 Reference cells、介质柱和人工边界

三个最中间的 reference cells 记为

$$
\mathcal C^-,
\qquad
\mathcal C^0,
\qquad
\mathcal C^+ .
$$

其中 $\mathcal C^0$ 是中心 reference cell，$\mathcal C^-$ 与 $\mathcal C^+$ 分别代表负、正 half-lead 的 reference cell。

三类介质柱形状记为

$$
\Omega_-,
\qquad
\Omega_0,
\qquad
\Omega_+ .
$$

它们分别约定为 centered in

$$
\mathcal C^-,
\qquad
\mathcal C^0,
\qquad
\mathcal C^+ .
$$

中心 cell 中真正需要解 BIE 的介质柱是 $\Omega_0$。其边界暂记为

$$
\Sigma_0=\partial\Omega_0.
$$

由于本文主要使用中心介质柱边界，后面简写为

$$
\Sigma:=\Sigma_0.
$$

左右 lead reference obstacles 的边界可暂记为

$$
\Sigma_-=\partial\Omega_-,
\qquad
\Sigma_+=\partial\Omega_+.
$$

这个边界符号只是暂定的，将来如果有更合适的记号可以替换。

中心 cell 的左右人工边界，也就是左右 wall，记为

$$
\Gamma_-,
\qquad
\Gamma_+ .
$$

设

$$
\Gamma_-=\{x=X_-\},
\qquad
\Gamma_+=\{x=X_+\},
\qquad
L_0=X_+-X_- .
$$

这里 $\Gamma_-$ 是中心 cell 的左 wall，$\Gamma_+$ 是中心 cell 的右 wall。端口 outward normal 约定为

$$
\nu_{\Gamma_-}=-e_x,
\qquad
\nu_{\Gamma_+}=+e_x .
$$

---

### 1.2 Rayleigh basis 与 trace convention

沿 $y$ 方向满足 quasiperiodic condition

$$
u(x,y+d)=e^{\mathrm{i}\beta d}u(x,y).
$$

定义

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\psi_m(y)=\frac{1}{\sqrt d}e^{\mathrm{i}\beta_m y}.
$$

截断到

$$
|m|\le M,
\qquad
K=2M+1.
$$

定义

$$
\gamma_m=\sqrt{k^2-\beta_m^2},
\qquad
\operatorname{Im}\gamma_m\ge 0,
$$

并令

$$
\Gamma=\operatorname{diag}(\gamma_m),
\qquad
E=\operatorname{diag}(e^{\mathrm{i}\gamma_mL_0}).
$$

注意这里的 $\Gamma$ 是 diagonal matrix，不是边界。边界使用 $\Gamma_\pm$，Rayleigh diagonal matrix 使用无下标的 $\Gamma$。如后续觉得冲突严重，可将 diagonal matrix 改写为 $\Gamma_{\mathrm{R}}$ 或 $G_\gamma$。

端口 trace 使用 Rayleigh coefficient 表示。对任意端口 $\Gamma_\pm$，

$$
D^\pm\in\mathbb C^K
$$

表示 Dirichlet trace coefficients，

$$
N^\pm\in\mathbb C^K
$$

表示端口 outward-normal derivative trace coefficients。

因此在中心左端口 $\Gamma_-$ 上，$N^-$ 对应 $-\partial_x u$；在中心右端口 $\Gamma_+$ 上，$N^+$ 对应 $+\partial_x u$。

---

### 1.3 Incoming/outgoing basis matrix 与 trace vector

入射和出射 trace basis matrices 仍记为

$$
D_{\mathrm{in}}^\pm,
\quad
N_{\mathrm{in}}^\pm,
\quad
D_{\mathrm{out}}^\pm,
\quad
N_{\mathrm{out}}^\pm .
$$

这些是矩阵，例如

$$
D_{\mathrm{out}}^\pm,N_{\mathrm{out}}^\pm
\in
\mathbb C^{K\times K_{\mathrm{out}}^\pm}.
$$

而下面这些量是 trace vectors，不是矩阵：

$$
D_h^\pm,
\quad
N_h^\pm,
\quad
D_s^\pm,
\quad
N_s^\pm.
$$

例如

$$
D_h^\pm,N_h^\pm\in\mathbb C^K.
$$

所以应区分：

$$
D_{\mathrm{out}}^\pm r^\pm
\quad\text{is a trace vector},
$$

but

$$
D_{\mathrm{out}}^\pm
\quad\text{is a trace basis matrix}.
$$

---

### 1.4 Potential theory operator convention

Potential theory 算子不使用 calligraphic letters。单层、双层算子写成

$$
S^{(\omega)}[\sigma](x),
\qquad
D^{(\omega)}[\tau](x).
$$

如果使用 quasiperiodic Green function，则加下标 QP：

$$
S_{\mathrm{QP}}^{(\omega)}[\sigma](x),
\qquad
D_{\mathrm{QP}}^{(\omega)}[\tau](x).
$$

例如 exterior wavenumber 为 $\omega_e$，interior wavenumber 为 $\omega_i$ 时，可以写成

$$
u_s^e(x)
=
D_{\mathrm{QP}}^{(\omega_e)}[\tau](x)
+
S_{\mathrm{QP}}^{(\omega_e)}[\sigma](x),
\qquad
x\in \mathcal C^0\setminus\overline{\Omega_0},
$$

$$
u_s^i(x)
=
D^{(\omega_i)}[\tau](x)
+
S^{(\omega_i)}[\sigma](x),
\qquad
x\in\Omega_0.
$$

如果代码中 interior block 也使用 quasiperiodic kernel，则第二式可相应改写为

$$
u_s^i
=
D_{\mathrm{QP}}^{(\omega_i)}[\tau]
+
S_{\mathrm{QP}}^{(\omega_i)}[\sigma].
$$

本文推导只依赖已经 assembled 的 Müller matrix

$$
A_{\mathrm{QP}}.
$$

因此具体 interior kernel 是否加 QP 下标，应以当前 `op.construct_A_QP` 的实现为准。

BIE density 按现有代码约定写为

$$
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}
=
\begin{bmatrix}
\tau\\
\mu
\end{bmatrix},
\qquad
\mu=-\sigma.
$$

---

### 1.5 矩阵命名

Müller matrix 记为

$$
A_{\mathrm{QP}}.
$$

它只对应中心介质柱边界 $\Sigma$ 上的 BIE / transmission condition。

总的大耦合矩阵，也就是代码中可以命名为 `A_trmatch` 的矩阵，笔记中记为

$$
\mathcal A.
$$

它包含：

1. $\Sigma$ 上的 Müller BIE；
2. $\Gamma_-$ 与 $\Gamma_+$ 上的 port trace matching；
3. half-lead outgoing condition encoded by $D_{\mathrm{out}}^\pm,N_{\mathrm{out}}^\pm$。

---

## 2. 中心 cell 含介质柱的 lead incoming scattering problem

### 2.1 问题目标

现在考虑中心 cell $\mathcal C^0$ 内存在介质柱 $\Omega_0$ 的散射问题。给定来自负 half-lead 或正 half-lead 的合法 incoming trace，求解：

1. 中心 cell 外部场；
2. 中心介质柱内部场；
3. 左右 half-lead 中的 outgoing scattered coefficients。

本文优先处理 direct BIE formulation，而不是先构造中心 cell scattering matrix $S_0$。

设入射系数为

$$
p_{\mathrm{in}}^-,
\qquad
p_{\mathrm{in}}^+.
$$

相应 incoming trace vectors 为

$$
D_{\mathrm{in,tot}}^-
=
D_{\mathrm{in}}^-p_{\mathrm{in}}^-,
\qquad
N_{\mathrm{in,tot}}^-
=
N_{\mathrm{in}}^-p_{\mathrm{in}}^-,
$$

$$
D_{\mathrm{in,tot}}^+
=
D_{\mathrm{in}}^+p_{\mathrm{in}}^+,
\qquad
N_{\mathrm{in,tot}}^+
=
N_{\mathrm{in}}^+p_{\mathrm{in}}^+.
$$

单侧负端口入射时取

$$
p_{\mathrm{in}}^+=0.
$$

单侧正端口入射时取

$$
p_{\mathrm{in}}^-=0.
$$

---

### 2.2 中心 cell 中的 homogeneous Rayleigh field

中心 cell 外部背景中的 homogeneous Rayleigh field 写为

$$
u_h(x,y)
=
\sum_{m=-M}^M
a_m
e^{\mathrm{i}\gamma_m(x-X_-)}
\psi_m(y)
+
\sum_{m=-M}^M
b_m
e^{-\mathrm{i}\gamma_m(x-X_-)}
\psi_m(y).
$$

这里 $a_m$ 和 $b_m$ 只是中心区域中的 right-going / left-going Rayleigh amplitudes，不表示正负 half-lead。

令

$$
a=(a_m)_{|m|\le M},
\qquad
b=(b_m)_{|m|\le M}.
$$

注意 $a$ 和 $b$ 不带正负上标，因为它们是中心 cell 的方向系数，不是正 / 负 half-lead 量。

则 $u_h$ 在两个端口上的 trace vectors 为

$$
D_h^- = a + b,
$$

$$
N_h^- = -\mathrm{i}\Gamma(a-b),
$$

$$
D_h^+ = Ea + E^{-1}b,
$$

$$
N_h^+ = \mathrm{i}\Gamma(Ea-E^{-1}b).
$$

这些式子只描述中心 cell 内的 homogeneous Rayleigh component。它们不是 outgoing lead basis，也不是 Bloch mode trace。

---

### 2.3 中心介质柱的 BIE 方程

中心 cell 外部总场写成

$$
u_e=u_h+u_s^e,
\qquad
x\in\mathcal C^0\setminus\overline{\Omega_0}.
$$

介质柱内部场写成

$$
u_i=u_s^i,
\qquad
x\in\Omega_0.
$$

其中 $u_s^e,u_s^i$ 由 boundary density $\eta=[\tau;-\sigma]$ 通过 layer potentials 给出。

在 $\Sigma=\partial\Omega_0$ 上施加 transmission condition。以普通 TM-like continuity 为例：

$$
u_e=u_i,
\qquad
\partial_\nu u_e=\partial_\nu u_i,
\qquad
x\in\Sigma.
$$

其中 $\nu$ 是 $\Omega_0$ 的 outward unit normal。

由于 $u_e=u_h+u_s^e$，$u_i=u_s^i$，得到

$$
u_s^e-u_s^i=-u_h,
$$

$$
\partial_\nu u_s^e-\partial_\nu u_s^i=-\partial_\nu u_h.
$$

这正是 Müller equation 的 forced form。抽象写为

$$
A_{\mathrm{QP}}\eta
+
H_\Sigma^a a
+
H_\Sigma^b b
=
0.
$$

其中

$$
H_\Sigma^a
=
\begin{bmatrix}
H_{D,\Sigma}^{a}\\
H_{N,\Sigma}^{a}
\end{bmatrix},
\qquad
H_\Sigma^b
=
\begin{bmatrix}
H_{D,\Sigma}^{b}\\
H_{N,\Sigma}^{b}
\end{bmatrix}
$$

把中心 Rayleigh basis field restricted to $\Sigma$ 后得到的 Cauchy data 矩阵。

设边界节点为

$$
z_j=(x_j,y_j)\in\Sigma,
\qquad
\nu_j=(\nu_{x,j},\nu_{y,j}).
$$

则

$$
H_{D,\Sigma}^{a}(j,m)
=
e^{\mathrm{i}\gamma_m(x_j-X_-)}
\psi_m(y_j),
$$

$$
H_{D,\Sigma}^{b}(j,m)
=
e^{-\mathrm{i}\gamma_m(x_j-X_-)}
\psi_m(y_j).
$$

法向导数 block 为

$$
H_{N,\Sigma}^{a}(j,m)
=
\left(
\mathrm{i}\gamma_m\nu_{x,j}
+
\mathrm{i}\beta_m\nu_{y,j}
\right)
e^{\mathrm{i}\gamma_m(x_j-X_-)}
\psi_m(y_j),
$$

$$
H_{N,\Sigma}^{b}(j,m)
=
\left(
-\mathrm{i}\gamma_m\nu_{x,j}
+
\mathrm{i}\beta_m\nu_{y,j}
\right)
e^{-\mathrm{i}\gamma_m(x_j-X_-)}
\psi_m(y_j).
$$

如果之后改成 TE boundary condition，只需要替换 $A_{\mathrm{QP}}$ 中的 Neumann row 和 $H_{N,\Sigma}^{a}$、$H_{N,\Sigma}^{b}$ 的权重。例如加权法向导数条件可写成

$$
\alpha_e\partial_\nu u_e=\alpha_i\partial_\nu u_i.
$$

---

### 2.4 中心介质柱散射场在端口上的 outgoing coefficients

中心介质柱 density $\eta$ 产生的 scattered field 在左右端口上可以展开为 outgoing Rayleigh waves。记其 outgoing Rayleigh coefficients 为

$$
s^-,
\qquad
s^+.
$$

其中

$$
s^-\in\mathbb C^K
$$

表示从中心介质柱向左离开的 Rayleigh coefficients，

$$
s^+\in\mathbb C^K
$$

表示从中心介质柱向右离开的 Rayleigh coefficients。

现有函数

```matlab
function [F_L, F_R, aux] = farfield_extractors(geom, rayleighchan, X_L, X_R, curvelen)
```

实现了映射

$$
s_L=F_L\eta,
\qquad
s_R=F_R\eta.
$$

在本文符号中取

$$
X_L=X_-,
\qquad
X_R=X_+,
$$

并定义

$$
F_-:=F_L,
\qquad
F_+:=F_R.
$$

于是

$$
s^- = F_-\eta,
\qquad
s^+ = F_+\eta.
$$

由于 $s^\pm$ 是端口处的 outgoing Rayleigh Dirichlet coefficients，所以中心介质柱散射场在端口上的 trace vectors 为

$$
D_s^- = F_-\eta,
\qquad
N_s^- = \mathrm{i}\Gamma F_-\eta,
$$

$$
D_s^+ = F_+\eta,
\qquad
N_s^+ = \mathrm{i}\Gamma F_+\eta.
$$

这里两个 Neumann 公式都是 $+\mathrm{i}\Gamma$，原因是：

- 在右端口 $\Gamma_+$，right-going outgoing wave 的 outward normal derivative 是 $+\partial_x$，因此给出 $+\mathrm{i}\gamma_m$；
- 在左端口 $\Gamma_-$，left-going outgoing wave 的 $\partial_x$ derivative 是 $-\mathrm{i}\gamma_m$，而 outward normal 是 $-\partial_x$，所以也给出 $+\mathrm{i}\gamma_m$。

这一步是使用 `bloch.farfield_extractors` 后端口方程可以简化的关键。

---

### 2.5 端口匹配方程

中心 cell 外部总场在端口上的 trace 是

$$
D_0^\pm=D_h^\pm+D_s^\pm,
\qquad
N_0^\pm=N_h^\pm+N_s^\pm.
$$

另一方面，half-lead 侧的端口 trace 等于 given incoming trace 加 unknown outgoing scattered trace：

$$
D_{\mathrm{lead}}^\pm
=
D_{\mathrm{in}}^\pm p_{\mathrm{in}}^\pm
+
D_{\mathrm{out}}^\pm r^\pm,
$$

$$
N_{\mathrm{lead}}^\pm
=
N_{\mathrm{in}}^\pm p_{\mathrm{in}}^\pm
+
N_{\mathrm{out}}^\pm r^\pm.
$$

因此 port matching conditions 是

$$
D_h^-+D_s^-
=
D_{\mathrm{in}}^-p_{\mathrm{in}}^-
+
D_{\mathrm{out}}^-r^-,
$$

$$
N_h^-+N_s^-
=
N_{\mathrm{in}}^-p_{\mathrm{in}}^-
+
N_{\mathrm{out}}^-r^-,
$$

$$
D_h^++D_s^+
=
D_{\mathrm{in}}^+p_{\mathrm{in}}^+
+
D_{\mathrm{out}}^+r^+,
$$

$$
N_h^++N_s^+
=
N_{\mathrm{in}}^+p_{\mathrm{in}}^+
+
N_{\mathrm{out}}^+r^+.
$$

代入 $D_h^\pm,N_h^\pm$ 和 $D_s^\pm,N_s^\pm$，得到

$$
F_-\eta+a + b -D_{\mathrm{out}}^-r^-
=
D_{\mathrm{in}}^-p_{\mathrm{in}}^-,
$$

$$
\mathrm{i}\Gamma F_-\eta-\mathrm{i}\Gamma a + \mathrm{i}\Gamma b -N_{\mathrm{out}}^-r^-
=
N_{\mathrm{in}}^-p_{\mathrm{in}}^-,
$$

$$
F_+\eta+Ea + E^{-1}b -D_{\mathrm{out}}^+r^+
=
D_{\mathrm{in}}^+p_{\mathrm{in}}^+,
$$

$$
\mathrm{i}\Gamma F_+\eta+\mathrm{i}\Gamma Ea - \mathrm{i}\Gamma E^{-1}b -N_{\mathrm{out}}^+r^+
=
N_{\mathrm{in}}^+p_{\mathrm{in}}^+.
$$

---

### 2.6 总线性系统

未知量取为

$$
x=
\begin{bmatrix}
\eta\\
a\\
b\\
r^-\\
r^+
\end{bmatrix}.
$$

其中

$$
\eta\in\mathbb C^{2N},
\qquad
a,b\in\mathbb C^K,
$$

$$
r^-\in\mathbb C^{K_{\mathrm{out}}^-},
\qquad
r^+\in\mathbb C^{K_{\mathrm{out}}^+}.
$$

总系统写为

$$
\mathcal A x=b_{\mathrm{in}}.
$$

其中

$$
\mathcal A
=
\begin{bmatrix}
A_{\mathrm{QP}} & H_\Sigma^a & H_\Sigma^b & 0 & 0\\
F_- & I & I & -D_{\mathrm{out}}^- & 0\\
\mathrm{i}\Gamma F_- & -\mathrm{i}\Gamma & \mathrm{i}\Gamma & -N_{\mathrm{out}}^- & 0\\
F_+ & E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
\mathrm{i}\Gamma F_+ & \mathrm{i}\Gamma E & -\mathrm{i}\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}.
$$

右端项为

$$
b_{\mathrm{in}}
=
\begin{bmatrix}
0\\
D_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
D_{\mathrm{in}}^+p_{\mathrm{in}}^+\\
N_{\mathrm{in}}^+p_{\mathrm{in}}^+
\end{bmatrix}.
$$

这里第一块 $0$ 的长度等于 $A_{\mathrm{QP}}$ 的行数，通常是 $2N$。下面四块每块长度为 $K$。

单侧负端口入射时，

$$
p_{\mathrm{in}}^+=0,
$$

因此

$$
b_{\mathrm{in}}^-
=
\begin{bmatrix}
0\\
D_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
0\\
0
\end{bmatrix}.
$$

单侧正端口入射时，

$$
p_{\mathrm{in}}^-=0,
$$

因此

$$
b_{\mathrm{in}}^+
=
\begin{bmatrix}
0\\
0\\
0\\
D_{\mathrm{in}}^+p_{\mathrm{in}}^+\\
N_{\mathrm{in}}^+p_{\mathrm{in}}^+
\end{bmatrix}.
$$

这说明在 lead incoming formulation 中，forcing term 不是任意 wall trace，也不是点源，而是合法 incoming Bloch trace：

$$
\left(
D_{\mathrm{in}}^\pm p_{\mathrm{in}}^\pm,
\quad
N_{\mathrm{in}}^\pm p_{\mathrm{in}}^\pm
\right).
$$

---

## 3. `bloch.farfield_extractors` 的数学逻辑

本节把现有函数 `bloch.farfield_extractors` 的数学内容写入公式，方便后续实现 `scat_*` 脚本时直接引用。

### 3.1 输出含义

函数输出

$$
F_L,
\qquad
F_R
$$

满足

$$
s_L=F_L\eta,
\qquad
s_R=F_R\eta.
$$

其中

$$
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
$$

在本文中心 cell 符号中，

$$
F_-:=F_L,
\qquad
F_+:=F_R.
$$

因此

$$
s^- = F_-\eta,
\qquad
s^+ = F_+\eta.
$$

这里 $s^\pm$ 是 scattered field 的 outgoing Rayleigh coefficients，不包含中心 homogeneous field 的 direct phase contribution

$$
E=\operatorname{diag}(e^{\mathrm{i}\gamma_mL_0}).
$$

这个 direct phase contribution 只属于 $u_h$ 中 $a,b$ 的传播，不属于介质柱 density $\eta$ 产生的 scattered coefficient extraction。

---

### 3.2 Green coefficient

设边界节点为

$$
z_j=(x_j,y_j)\in\Sigma,
$$

边界以 counter-clockwise 方向参数化，outward unit normal 为

$$
\nu_j=(\nu_{x,j},\nu_{y,j}).
$$

对左 outgoing coefficient，函数内部使用

$$
g_L(m,j)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
\exp\left(
-\mathrm{i}\beta_m y_j
+
\mathrm{i}\gamma_m(x_j-X_L)
\right).
$$

对右 outgoing coefficient，使用

$$
g_R(m,j)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
\exp\left(
-\mathrm{i}\beta_m y_j
-
\mathrm{i}\gamma_m(x_j-X_R)
\right).
$$

在中心 cell 中取

$$
X_L=X_-,
\qquad
X_R=X_+.
$$

---

### 3.3 Double-layer source-normal derivative coefficient

代码变量 `dgdn_L` 和 `dgdn_R` 不是 adjoint double-layer operator $D^*$。它们是 double-layer source-normal derivative coefficients。

具体为

$$
\mathrm{dgdn}_L(m,j)
=
\mathrm{i}
\left(
\gamma_m\nu_{x,j}
-
\beta_m\nu_{y,j}
\right)
g_L(m,j),
$$

$$
\mathrm{dgdn}_R(m,j)
=
-\mathrm{i}
\left(
\gamma_m\nu_{x,j}
+
\beta_m\nu_{y,j}
\right)
g_R(m,j).
$$

这些量可记为

$$
A_m^L(z_j),
\qquad
A_m^R(z_j),
$$

但不要把它们误解为 boundary integral operator $D^*$。

---

### 3.4 Trapezoid weights 与矩阵公式

设边界参数区间长度为 `curvelen`，节点数为 $N$，则

$$
h=\frac{\mathrm{curvelen}}{N}.
$$

若边界速度为

$$
\mathrm{speed}_j=|z'(t_j)|,
$$

则 trapezoid weight 为

$$
w_j=h\,\mathrm{speed}_j.
$$

函数构造

$$
F_L
=
\begin{bmatrix}
w_j\mathrm{dgdn}_L(m,j)
&
-w_j g_L(m,j)
\end{bmatrix}_{m,j},
$$

$$
F_R
=
\begin{bmatrix}
w_j\mathrm{dgdn}_R(m,j)
&
-w_j g_R(m,j)
\end{bmatrix}_{m,j}.
$$

更明确地说，对

$$
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix},
$$

有

$$
F_L\eta
=
\sum_j
w_j\mathrm{dgdn}_L(m,j)\tau_j
+
\sum_j
w_j g_L(m,j)\sigma_j,
$$

$$
F_R\eta
=
\sum_j
w_j\mathrm{dgdn}_R(m,j)\tau_j
+
\sum_j
w_j g_R(m,j)\sigma_j.
$$

这与 field representation

$$
u_s
=
D^{(\omega)}[\tau]
+
S^{(\omega)}[\sigma]
$$

的 far-field coefficient extraction 一致。

---

### 3.5 从 outgoing coefficient 到端口 Cauchy trace

一旦得到

$$
s^- = F_-\eta,
\qquad
s^+ = F_+\eta,
$$

则端口 trace vectors 为

$$
D_s^- = s^-,
\qquad
N_s^- = \mathrm{i}\Gamma s^-,
$$

$$
D_s^+ = s^+,
\qquad
N_s^+ = \mathrm{i}\Gamma s^+.
$$

因此在总矩阵 $\mathcal A$ 中可以直接使用

$$
F_-,
\qquad
\mathrm{i}\Gamma F_-,
\qquad
F_+,
\qquad
\mathrm{i}\Gamma F_+.
$$

---

## 4. 与 empty defect cell 情形的对比

### 4.1 Empty cell 中没有 BIE unknown

在 empty defect cell 情形中，中心 cell 没有介质柱 $\Omega_0$，因此没有

$$
\Sigma,
\qquad
\eta,
\qquad
A_{\mathrm{QP}},
\qquad
H_\Sigma^\pm,
\qquad
F_\pm.
$$

未知量只有

$$
x_{\mathrm{empty}}
=
\begin{bmatrix}
a\\
b\\
r^-\\
r^+
\end{bmatrix}.
$$

总矩阵退化为纯端口 trace matching：

$$
\mathcal A_{\mathrm{empty}}
=
\begin{bmatrix}
I & I & -D_{\mathrm{out}}^- & 0\\
-\mathrm{i}\Gamma & \mathrm{i}\Gamma & -N_{\mathrm{out}}^- & 0\\
E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
\mathrm{i}\Gamma E & -\mathrm{i}\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}.
$$

对应方程为

$$
\mathcal A_{\mathrm{empty}}
\begin{bmatrix}
a\\
b\\
r^-\\
r^+
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
D_{\mathrm{in}}^+p_{\mathrm{in}}^+\\
N_{\mathrm{in}}^+p_{\mathrm{in}}^+
\end{bmatrix}.
$$

---

### 4.2 含中心介质柱时增加的内容

中心 cell 含介质柱后，新增三类对象：

1. 介质柱 boundary density

$$
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
$$

2. $\Sigma$ 上的 Müller equation

$$
A_{\mathrm{QP}}\eta
+
H_\Sigma^a a
+
H_\Sigma^b b
=
0.
$$

3. 介质柱 density 对端口 outgoing Rayleigh coefficients 的贡献

$$
s^- = F_-\eta,
\qquad
s^+ = F_+\eta.
$$

因此 empty cell 的端口 matching

$$
D_h^\pm
=
D_{\mathrm{in}}^\pm p_{\mathrm{in}}^\pm
+
D_{\mathrm{out}}^\pm r^\pm
$$

变成

$$
D_h^\pm+D_s^\pm
=
D_{\mathrm{in}}^\pm p_{\mathrm{in}}^\pm
+
D_{\mathrm{out}}^\pm r^\pm,
$$

Neumann trace 同理。

也就是说：

$$
\text{empty cell: only port matching on }\Gamma_\pm,
$$

而

$$
\text{rod cell: BIE on }\Sigma
+
\text{port matching on }\Gamma_\pm.
$$

---

## 5. Forcing term 与 RHS 的分类

### 5.1 Lead incoming forcing

本文主问题的 forcing term 是合法 incoming Bloch trace。也就是说，给定的是

$$
p_{\mathrm{in}}^-,
\qquad
p_{\mathrm{in}}^+
$$

以及由它们生成的 trace vectors

$$
D_{\mathrm{in}}^-p_{\mathrm{in}}^-,
\qquad
N_{\mathrm{in}}^-p_{\mathrm{in}}^-,
$$

$$
D_{\mathrm{in}}^+p_{\mathrm{in}}^+,
\qquad
N_{\mathrm{in}}^+p_{\mathrm{in}}^+.
$$

这些项只进入 port matching rows 的 RHS，而不直接进入 $\Sigma$ 上的 BIE row。原因是中心 cell 中的 field $u_h$ 是未知 Rayleigh expansion，它通过端口 matching 与 incoming trace 自洽确定，然后通过

$$
H_\Sigma^a a + H_\Sigma^b b
$$

作用到介质柱边界方程上。

因此 lead incoming formulation 的 RHS 是

$$
b_{\mathrm{in}}
=
\begin{bmatrix}
0\\
D_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
D_{\mathrm{in}}^+p_{\mathrm{in}}^+\\
N_{\mathrm{in}}^+p_{\mathrm{in}}^+
\end{bmatrix}.
$$

---

### 5.2 中心点源 forcing，且中心 cell 含介质柱

如果中心 cell 外部背景中还有点源 particular solution

$$
u_p(x,y)
=
G_{\mathrm{QP}}^{(k)}((x,y),(x_s,y_s)),
$$

则中心外部总场应写成

$$
u_e=u_p+u_h+u_s^e.
$$

此时 $\Sigma$ 上的 BIE equation 变成

$$
A_{\mathrm{QP}}\eta
+
H_\Sigma^a a
+
H_\Sigma^b b
=
-
\begin{bmatrix}
u_p|_\Sigma\\
\partial_\nu u_p|_\Sigma
\end{bmatrix}.
$$

点源在端口上的 trace vectors 记为

$$
D_p^\pm,
\qquad
N_p^\pm.
$$

如果没有 lead incoming，只考虑中心点源 forcing，则 port matching rows 为

$$
D_h^-+D_s^-+D_p^-
=
D_{\mathrm{out}}^-r^-,
$$

$$
N_h^-+N_s^-+N_p^-
=
N_{\mathrm{out}}^-r^-,
$$

$$
D_h^++D_s^++D_p^+
=
D_{\mathrm{out}}^+r^+,
$$

$$
N_h^++N_s^++N_p^+
=
N_{\mathrm{out}}^+r^+.
$$

因此总 RHS 变为

$$
b_p
=
-
\begin{bmatrix}
u_p|_\Sigma\\
\partial_\nu u_p|_\Sigma\\
D_p^-\\
N_p^-\\
D_p^+\\
N_p^+
\end{bmatrix}.
$$

这里第一大块长度为 $2N$，后面四块每块长度为 $K$。

如果同时存在 lead incoming 和中心点源，则 RHS 叠加为

$$
b
=
\begin{bmatrix}
-
\begin{bmatrix}
u_p|_\Sigma\\
\partial_\nu u_p|_\Sigma
\end{bmatrix}\\
D_{\mathrm{in}}^-p_{\mathrm{in}}^- - D_p^-\\
N_{\mathrm{in}}^-p_{\mathrm{in}}^- - N_p^-\\
D_{\mathrm{in}}^+p_{\mathrm{in}}^+ - D_p^+\\
N_{\mathrm{in}}^+p_{\mathrm{in}}^+ - N_p^+
\end{bmatrix}.
$$

---

## 6. Suggested implementation flow

### 6.1 Build lead trace bases

For the left and right periodic leads:

1. construct lead cell scattering matrices;
2. solve Bloch generalized eigenproblems;
3. build mode traces;
4. select incoming and outgoing port traces.

The selected matrices are

$$
D_{\mathrm{in}}^\pm,
\quad
N_{\mathrm{in}}^\pm,
\quad
D_{\mathrm{out}}^\pm,
\quad
N_{\mathrm{out}}^\pm .
$$

The incoming coefficients

$$
p_{\mathrm{in}}^\pm
$$

are user-specified forcing data.

---

### 6.2 Build center obstacle BIE data

Construct the geometry for $\Omega_0$ and its boundary $\Sigma$.

Assemble

$$
A_{\mathrm{QP}}
$$

using the existing Müller matrix construction.

Then assemble the Rayleigh-to-boundary matrices

$$
H_\Sigma^a,
\qquad
H_\Sigma^b.
$$

These matrices represent the Cauchy data of the two center Rayleigh basis families restricted to $\Sigma$.

---

### 6.3 Build center obstacle far-field extractors

Use

```matlab
[F_L, F_R, aux] = bloch.farfield_extractors(geom0, rayleighchan, X_minus, X_plus, curvelen);
```

Then set

```matlab
F_minus = F_L;
F_plus  = F_R;
```

Mathematically,

$$
F_-:=F_L,
\qquad
F_+:=F_R.
$$

Use the port trace blocks

$$
F_-,
\qquad
\mathrm{i}\Gamma F_-,
\qquad
F_+,
\qquad
\mathrm{i}\Gamma F_+.
$$

---

### 6.4 Assemble and solve the global matrix

Assemble

$$
\mathcal A
=
\begin{bmatrix}
A_{\mathrm{QP}} & H_\Sigma^a & H_\Sigma^b & 0 & 0\\
F_- & I & I & -D_{\mathrm{out}}^- & 0\\
\mathrm{i}\Gamma F_- & -\mathrm{i}\Gamma & \mathrm{i}\Gamma & -N_{\mathrm{out}}^- & 0\\
F_+ & E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
\mathrm{i}\Gamma F_+ & \mathrm{i}\Gamma E & -\mathrm{i}\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}.
$$

For negative lead incidence, use

$$
b_{\mathrm{in}}^-
=
\begin{bmatrix}
0\\
D_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-p_{\mathrm{in}}^-\\
0\\
0
\end{bmatrix}.
$$

Then solve

$$
\mathcal A x=b_{\mathrm{in}}^-.
$$

Extract

$$
x=
\begin{bmatrix}
\eta\\
a\\
b\\
r^-\\
r^+
\end{bmatrix}.
$$

---

### 6.5 Reconstruct fields for plotting

In the center exterior region,

$$
u_e(x,y)
=
u_h(x,y)
+
D_{\mathrm{QP}}^{(\omega_e)}[\tau](x,y)
+
S_{\mathrm{QP}}^{(\omega_e)}[\sigma](x,y).
$$

In the center obstacle,

$$
u_i(x,y)
=
D^{(\omega_i)}[\tau](x,y)
+
S^{(\omega_i)}[\sigma](x,y),
$$

or the QP version if that is what the assembly uses.

In the negative half-lead, the field is

$$
u^-
=
u_{\mathrm{in}}^-
+
u_{\mathrm{out}}^-.
$$

In the positive half-lead,

$$
u^+
=
u_{\mathrm{in}}^+
+
u_{\mathrm{out}}^+.
$$

For one-sided incidence from the negative half-lead,

$$
u_{\mathrm{in}}^+=0.
$$

The outgoing parts are represented by the solved coefficients

$$
r^-,
\qquad
r^+.
$$

---

## 7. Checks and diagnostics

### 7.1 Empty obstacle limit

If $\Omega_0$ is removed, then

$$
\eta,\quad A_{\mathrm{QP}},\quad H_\Sigma^\pm,\quad F_\pm
$$

should disappear, and $\mathcal A$ should reduce to $\mathcal A_{\mathrm{empty}}$.

This is the first structural check.

---

### 7.2 BIE residual on $\Sigma$

After solving, check

$$
r_\Sigma
=
A_{\mathrm{QP}}\eta
+
H_\Sigma^a a
+
H_\Sigma^b b.
$$

For lead incoming forcing without point source, this should be small.

For point-source forcing, check instead

$$
r_\Sigma
=
A_{\mathrm{QP}}\eta
+
H_\Sigma^a a
+
H_\Sigma^b b
+
\begin{bmatrix}
u_p|_\Sigma\\
\partial_\nu u_p|_\Sigma
\end{bmatrix}.
$$

---

### 7.3 Port matching residuals

Check the four port residuals:

$$
r_D^-
=
F_-\eta+a + b -D_{\mathrm{out}}^-r^-
-
D_{\mathrm{in}}^-p_{\mathrm{in}}^-,
$$

$$
r_N^-
=
\mathrm{i}\Gamma F_-\eta-\mathrm{i}\Gamma a + \mathrm{i}\Gamma b
-N_{\mathrm{out}}^-r^-
-
N_{\mathrm{in}}^-p_{\mathrm{in}}^-,
$$

$$
r_D^+
=
F_+\eta+Ea + E^{-1}b -D_{\mathrm{out}}^+r^+
-
D_{\mathrm{in}}^+p_{\mathrm{in}}^+,
$$

$$
r_N^+
=
\mathrm{i}\Gamma F_+\eta+\mathrm{i}\Gamma Ea - \mathrm{i}\Gamma E^{-1}b
-N_{\mathrm{out}}^+r^+
-
N_{\mathrm{in}}^+p_{\mathrm{in}}^+.
$$

All four should be small relative to the corresponding data scale.

---

### 7.4 Far-field extractor sign check

A useful check is to compare two ways of getting the scattered port trace from $\eta$:

1. Use `bloch.farfield_extractors`:

$$
D_s^- = F_-\eta,
\qquad
N_s^- = \mathrm{i}\Gamma F_-\eta,
$$

$$
D_s^+ = F_+\eta,
\qquad
N_s^+ = \mathrm{i}\Gamma F_+\eta.
$$

2. Directly evaluate the layer potential on $\Gamma_\pm$ and project to Rayleigh basis.

The two should agree up to quadrature / truncation error.

This is the analogue of the previously verified `bloch_test_F.m` check, but now used inside the center-cell rod scattering formulation.
