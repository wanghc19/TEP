# note_Bloch_mode.md

本笔记整理线性缺陷晶体问题中右侧周期 lead 的 Bloch mode 计算子模块。目标是：在固定 $y$ 方向准周期参数 $\beta$ 和频率 $\omega$ 后，先用 BIE 计算单个 $x$ 周期 cell 的 scattering matrix，再由 scattering matrix 解广义特征值问题，得到 Bloch multiplier 与 Bloch mode 的端口表示。

本笔记暂不讨论最终 TEP 大矩阵，也暂不讨论 TE 加权法向导数。所有法向导数均指普通外法向导数。

---

## 1. 符号约定

### 1.1 几何区域

介质柱所在区域记为

$$
\Omega.
$$

介质柱边界记为

$$
\partial\Omega.
$$

不要用 $\Gamma$ 表示 $\partial\Omega$，避免和后续左右人工边界 $\Gamma_L,\Gamma_R$ 混淆。

线性缺陷问题中：

- $\Omega_0$ 表示中间缺陷区域；
- $\Omega_+$ 表示右侧半无限周期区域；
- $\Omega_-$ 表示左侧半无限周期区域。

本笔记只考虑如何为 $\Omega_+$ 计算 Bloch modes。取 $\Omega_+$ 的一个代表 cell，设其左右截面为

$$
x=X_L,
\qquad
x=X_R,
$$

并令

$$
L_+ = X_R-X_L.
$$

其中 $L_+$ 是 $\Omega_+$ 在正 $x$ 方向的周期。

$y$ 方向周期记为

$$
d.
$$

在 $y$ 方向固定准周期参数 $\beta$，即所有场满足

$$u(x,y+d)=e^{\mathrm{i}\beta d}u(x,y).
$$

### 1.2 Rayleigh/Fourier 端口基

取截断阶数 $M$，令

$$
m=-M,\ldots,M,
\qquad
K=2M+1.
$$

定义

$$
\boxed{
\beta_m=\beta+\frac{2\pi m}{d}.
}
$$

端口 Fourier/Rayleigh 基取为

$$
\boxed{
\psi_m(y)=\frac{1}{\sqrt d}e^{\mathrm{i}\beta_m y}.
}
$$

外部背景波数记为 $\omega$。若背景折射率为 $1$，定义

$$
\boxed{
\gamma_m=\sqrt{\omega^2-\beta_m^2},
\qquad
\operatorname{Im}\gamma_m\ge 0.
}
$$

若背景折射率为 $n_0$，则改为

$$
\gamma_m=\sqrt{(n_0\omega)^2-\beta_m^2}.
$$

传播阶满足 $\gamma_m\in\mathbb R$；衰减阶满足 $\operatorname{Im}\gamma_m>0$。Wood anomaly 对应 $\gamma_m=0$，这时 Rayleigh 展开与后续 scattering matrix 都会变得奇异或病态，需要单独处理。

### 1.3 Layer potential 与未知向量

外部散射场表示为

$$u_{\mathrm{sc}}(x)
=
D_{\mathrm{QP}}^{(\omega)}[\tau](x)
+
S_{\mathrm{QP}}^{(\omega)}[\sigma](x),
\qquad x\notin\overline\Omega.
$$

内部场表示为

$$u_{\mathrm{in}}(x)
=
D^{(n\omega)}[\tau](x)
+
S^{(n\omega)}[\sigma](x),
\qquad x\in\Omega.
$$

为了兼容已有 Müller 矩阵记号，未知向量取为

$$
\boxed{
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
}
$$

记

$$
\mu=-\sigma.
$$

于是外部散射场也可写为

$$
\boxed{u_{\mathrm{sc}}
=
D_{\mathrm{QP}}^{(\omega)}[\tau]
-
S_{\mathrm{QP}}^{(\omega)}[\mu].
}
$$

已有的 Müller 矩阵 $A_{\mathrm{QP}}$ 作用在 $\eta=[\tau;-\sigma]$ 上，并代表如下 operator：

$$
\begin{bmatrix}
u^+-u^-\\
u_n^+-u_n^-
\end{bmatrix}
=
A_{\mathrm{QP}}\eta.
$$

在 scattering problem 中，外部总场为

$$
u_{\mathrm{ext}}=u^{\mathrm{inc}}+u_{\mathrm{sc}}.
$$

介质柱边界上的 transmission condition 给出

$$
A_{\mathrm{QP}}\eta
=
-
\begin{bmatrix}u^{\mathrm{inc}}|_{\partial\Omega}\\
\partial_\nu u^{\mathrm{inc}}|_{\partial\Omega}
\end{bmatrix}.
$$

这里 $\nu$ 是 $\partial\Omega$ 上从介质柱内部指向外部的单位法向量。

---

## 2. 用 BIE 构造单 cell scattering matrix

### 2.1 左入射与右入射 Rayleigh channels

左入射第 $m$ 个 channel 定义为

$$
\boxed{u_m^{L,\mathrm{inc}}(x,y)
=
e^{\mathrm{i}\gamma_m(x-X_L)}\psi_m(y).
}
$$

其在 $\partial\Omega$ 上的法向导数为

$$
\boxed{
\partial_\nu u_m^{L,\mathrm{inc}}
=
\mathrm{i}(\gamma_m\nu_x+\beta_m\nu_y)u_m^{L,\mathrm{inc}}.
}
$$

右入射第 $m$ 个 channel 定义为

$$
\boxed{u_m^{R,\mathrm{inc}}(x,y)
=
e^{-\mathrm{i}\gamma_m(x-X_R)}\psi_m(y).
}
$$

其在 $\partial\Omega$ 上的法向导数为

$$
\boxed{
\partial_\nu u_m^{R,\mathrm{inc}}
=
\mathrm{i}(-\gamma_m\nu_x+\beta_m\nu_y)u_m^{R,\mathrm{inc}}.
}
$$

注意：当 $\gamma_m$ 为纯虚数时，这些 evanescent channels 不一定对应真实从无穷远入射的物理波；在这里它们是构造有限维 scattering matrix 的代数端口基。

### 2.2 多右端 BIE 系统

把所有左入射右端项组成矩阵

$$
B^L
=
\begin{bmatrix}
u_{-M}^{L,\mathrm{inc}}|_{\partial\Omega} & \cdots & u_M^{L,\mathrm{inc}}|_{\partial\Omega}\\
\partial_\nu u_{-M}^{L,\mathrm{inc}}|_{\partial\Omega} & \cdots & \partial_\nu u_M^{L,\mathrm{inc}}|_{\partial\Omega}
\end{bmatrix}.
$$

把所有右入射右端项组成矩阵

$$
B^R
=
\begin{bmatrix}
u_{-M}^{R,\mathrm{inc}}|_{\partial\Omega} & \cdots & u_M^{R,\mathrm{inc}}|_{\partial\Omega}\\
\partial_\nu u_{-M}^{R,\mathrm{inc}}|_{\partial\Omega} & \cdots & \partial_\nu u_M^{R,\mathrm{inc}}|_{\partial\Omega}
\end{bmatrix}.
$$

对应的 density 解矩阵为

$$
\boxed{
H^L=-A_{\mathrm{QP}}^{-1}B^L,
\qquad
H^R=-A_{\mathrm{QP}}^{-1}B^R.
}
$$

数值实现时，对固定 $(\omega,\beta)$，$A_{\mathrm{QP}}$ 相同，因此应当一次 factorization，然后求解所有入射 channel 的多右端问题。

---

## 3. 直接 Rayleigh 系数提取

本节推导从 BIE density $\eta=[\tau;\mu]$ 直接提取左右 outgoing Rayleigh 系数的矩阵。
为了避免和右侧半无限 lead 的 $\Omega_+$ 记号混淆，本节不再用 $+$/$-$ 上标表示右/左壁相关量，而统一使用 $R$/$L$ 上标：

- $R$ 表示右参考壁 $x=X_R$ 处的 outgoing Rayleigh 系数；
- $L$ 表示左参考壁 $x=X_L$ 处的 outgoing Rayleigh 系数。

后文仍保留 $L_+$、$E_+$、$S_{\mathrm{cell}}^+$、$\lambda_\ell^+$ 等记号，其中 $+$ 表示右侧周期 lead $\Omega_+$ 或正 $x$ 方向周期问题，而不是右参考壁。

$$
\boxed{
s^R=F^R\eta,
\qquad
s^L=F^L\eta.
}
$$

### 3.1 准周期 Green 函数的 Rayleigh 展开

$y$ 准周期 Green 函数在源点右侧有展开

$$
G_{\mathrm{QP}}^{(\omega)}(x,y;z_x,z_y)
=
\frac{\mathrm{i}}{2d}
\sum_{m\in\mathbb Z}
\frac{1}{\gamma_m}
 e^{\mathrm{i}\beta_m(y-z_y)}
 e^{\mathrm{i}\gamma_m(x-z_x)},
\qquad x>z_x.
$$

以右端口 basis

$$
e^{\mathrm{i}\gamma_m(x-X_R)}\psi_m(y)
$$

为标准，写成

$$
G_{\mathrm{QP}}^{(\omega)}(x,y;z)
=
\sum_m g_m^R(z)
e^{\mathrm{i}\gamma_m(x-X_R)}\psi_m(y).
$$

由此得到

$$
\boxed{
g_m^R(z)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
\exp\left[-\mathrm{i}\beta_m z_y-\mathrm{i}\gamma_m(z_x-X_R)\right].
}
$$

在源点左侧有展开

$$
G_{\mathrm{QP}}^{(\omega)}(x,y;z)
=
\sum_m g_m^L(z)
e^{-\mathrm{i}\gamma_m(x-X_L)}\psi_m(y),
$$

其中

$$
\boxed{
g_m^L(z)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
\exp\left[-\mathrm{i}\beta_m z_y+\mathrm{i}\gamma_m(z_x-X_L)\right].
}
$$

### 3.2 Single-layer 的系数贡献

Single-layer 为

$$
S_{\mathrm{QP}}^{(\omega)}[\sigma](x)
=
\int_{\partial\Omega}G_{\mathrm{QP}}^{(\omega)}(x;z)\sigma(z)\,ds_z.
$$

由于实际未知量使用 $\mu=-\sigma$，外部散射场中 single-layer 部分是

$$
-S_{\mathrm{QP}}^{(\omega)}[\mu].
$$

因此对右侧 outgoing 系数的贡献为

$$
\boxed{
s_{S,m}^R
=
-\int_{\partial\Omega}g_m^R(z)\mu(z)\,ds_z.
}
$$

左侧为

$$
\boxed{
s_{S,m}^L
=
-\int_{\partial\Omega}g_m^L(z)\mu(z)\,ds_z.
}
$$

### 3.3 Double-layer 的系数贡献

Double-layer 为

$$
D_{\mathrm{QP}}^{(\omega)}[\tau](x)
=
\int_{\partial\Omega}
\partial_{\nu_z}G_{\mathrm{QP}}^{(\omega)}(x;z)
\tau(z)\,ds_z.
$$

其中 $\partial_{\nu_z}$ 是对源点 $z$ 的外法向求导。

右侧 coefficient function 满足

$$
\nabla_z g_m^R(z)
=
-\mathrm{i}
\begin{bmatrix}
\gamma_m\\
\beta_m
\end{bmatrix}
g_m^R(z).
$$

因此

$$
\partial_{\nu_z}g_m^R(z)
=
-\mathrm{i}(\gamma_m\nu_x(z)+\beta_m\nu_y(z))g_m^R(z).
$$

右侧 double-layer 系数为

$$
\boxed{
s_{D,m}^R
=
\int_{\partial\Omega}
\left[-\mathrm{i}(\gamma_m\nu_x(z)+\beta_m\nu_y(z))g_m^R(z)\right]
\tau(z)\,ds_z.
}
$$

左侧 coefficient function 满足

$$
\nabla_z g_m^L(z)
=
\mathrm{i}
\begin{bmatrix}
\gamma_m\\
-\beta_m
\end{bmatrix}
g_m^L(z).
$$

因此

$$
\partial_{\nu_z}g_m^L(z)
=
\mathrm{i}(\gamma_m\nu_x(z)-\beta_m\nu_y(z))g_m^L(z).
$$

左侧 double-layer 系数为

$$
\boxed{
s_{D,m}^L
=
\int_{\partial\Omega}
\left[\mathrm{i}(\gamma_m\nu_x(z)-\beta_m\nu_y(z))g_m^L(z)\right]
\tau(z)\,ds_z.
}
$$

### 3.4 定义 $F^R$ 与 $F^L$

令

$$
\eta=
\begin{bmatrix}
\tau\\
\mu
\end{bmatrix}
=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
$$

定义

$$
\boxed{
A_m^R(z)
=
-\mathrm{i}(\gamma_m\nu_x(z)+\beta_m\nu_y(z))g_m^R(z),
}
$$

$$
\boxed{
A_m^L(z)
=
\mathrm{i}(\gamma_m\nu_x(z)-\beta_m\nu_y(z))g_m^L(z).
}
$$

则

$$
s_m^R
=
\int_{\partial\Omega}A_m^R(z)\tau(z)\,ds_z
-
\int_{\partial\Omega}g_m^R(z)\mu(z)\,ds_z,
$$

$$
s_m^L
=
\int_{\partial\Omega}A_m^L(z)\tau(z)\,ds_z
-
\int_{\partial\Omega}g_m^L(z)\mu(z)\,ds_z.
$$

因此连续层面可写为

$$
\boxed{
F_m^R=\begin{bmatrix}A_m^R & -g_m^R\end{bmatrix},
\qquad
F_m^L=\begin{bmatrix}A_m^L & -g_m^L\end{bmatrix}.
}
$$

---

## 4. 离散公式

设

$$
z=z(t),
\qquad
t_j=\frac{2\pi j}{N},
\qquad
j=0,\ldots,N-1,
\qquad
h=\frac{2\pi}{N}.
$$

记

$$
z_j=z(t_j),
\qquad
s_j=|z'(t_j)|,
\qquad
\nu_j=(\nu_{x,j},\nu_{y,j}).
$$

其中 $\nu_j$ 是单位外法向。用梯形权重

$$
hs_j
$$

离散远场系数泛函。

对 $m=-M,\ldots,M$ 与 $j=0,\ldots,N-1$，定义

$$
\boxed{
(F_\tau^R)_{mj}
=
hs_j\left[-\mathrm{i}(\gamma_m\nu_{x,j}+\beta_m\nu_{y,j})g_m^R(z_j)\right],
}
$$

$$
\boxed{
(F_\mu^R)_{mj}
=
-hs_jg_m^R(z_j).
}
$$

左侧为

$$
\boxed{
(F_\tau^L)_{mj}
=
hs_j\left[\mathrm{i}(\gamma_m\nu_{x,j}-\beta_m\nu_{y,j})g_m^L(z_j)\right],
}
$$

$$
\boxed{
(F_\mu^L)_{mj}
=
-hs_jg_m^L(z_j).
}
$$

于是

$$
\boxed{
F^R=\begin{bmatrix}F_\tau^R & F_\mu^R\end{bmatrix},
\qquad
F^L=\begin{bmatrix}F_\tau^L & F_\mu^L\end{bmatrix}.
}
$$

对任意 BIE 解 $\eta=[\tau;\mu]$，直接有

$$
\boxed{
s^R=F^R\eta,
\qquad
s^L=F^L\eta.
}
$$

---

## 5. 由 $F^L$ 和 $F^R$ 组装 scattering matrix

令

$$
\boxed{
E_+=\operatorname{diag}\left(e^{\mathrm{i}\gamma_m L_+}\right)_{m=-M}^M.
}
$$

这个矩阵表示入射 Rayleigh channel 在空背景中从 $X_L$ 传播到 $X_R$ 的相位因子。

### 5.1 左入射

左入射满足

$$
a^L=e_m,
\qquad
b^R=0.
$$

左侧 outgoing coefficient 完全来自散射场：

$$
b^L=s^L.
$$

右侧 outgoing coefficient 包括入射波自由传播和散射场右 outgoing 部分：

$$
a^R=E_+e_m+s^R.
$$

因此

$$
\boxed{
R_L^+=F^L H^L,
}
$$

$$
\boxed{
T_{L\to R}^+=E_+ + F^R H^L.
}
$$

### 5.2 右入射

右入射满足

$$
a^L=0,
\qquad
b^R=e_m.
$$

右侧 outgoing coefficient 是右侧反射：

$$
a^R=s^R.
$$

左侧 outgoing coefficient 包括入射波自由传播和散射场左 outgoing 部分：

$$
b^L=E_+e_m+s^L.
$$

因此

$$
\boxed{
R_R^+=F^R H^R,
}
$$

$$
\boxed{
T_{R\to L}^+=E_+ + F^L H^R.
}
$$

单 cell scattering matrix 定义为

$$
\boxed{
\begin{bmatrix}
b^L\\
a^R
\end{bmatrix}
=
S_{\mathrm{cell}}^+
\begin{bmatrix}
a^L\\
b^R
\end{bmatrix}
=
\begin{bmatrix}
R_L^+ & T_{R\to L}^+\\
T_{L\to R}^+ & R_R^+
\end{bmatrix}
\begin{bmatrix}
a^L\\
b^R
\end{bmatrix}.
}
$$

---

## 6. 由 scattering matrix 求 Bloch modes

Bloch condition 是

$$
u(x+L_+,y)=\lambda u(x,y),
$$

其中

$$
\lambda=e^{\mathrm{i}\alpha L_+}
$$

是未知 Floquet multiplier。

在 amplitude 变量中，Bloch condition 写为

$$
\boxed{
a^R=\lambda a^L,
\qquad
b^R=\lambda b^L.
}
$$

令

$$
a=a^L,
\qquad
b=b^L.
$$

由 scattering relation 得到广义特征值问题

$$
\boxed{
A_{\mathrm{sc}}^+
\begin{bmatrix}
a\\
b
\end{bmatrix}
=
\lambda
B_{\mathrm{sc}}^+
\begin{bmatrix}
a\\
b
\end{bmatrix},
}
$$

其中

$$
\boxed{
A_{\mathrm{sc}}^+
=
\begin{bmatrix}
-R_L^+ & I\\
T_{L\to R}^+ & 0
\end{bmatrix},
\qquad
B_{\mathrm{sc}}^+
=
\begin{bmatrix}
0 & T_{R\to L}^+\\
I & -R_R^+
\end{bmatrix}.
}
$$

解出

$$
\lambda_\ell^+,
\qquad
v_\ell^+=
\begin{bmatrix}
a_\ell\\
b_\ell
\end{bmatrix}.
$$

右侧 outgoing/decaying Bloch modes 的选择规则为：

- 若 $|\lambda_\ell^+|<1$，则该 mode 向 $x\to +\infty$ 衰减；
- 若 $|\lambda_\ell^+|=1$，需要用能流方向或 group velocity 判断是否向 $+x$ 出射；
- 若 $|\lambda_\ell^+|>1$，则向右增长，通常不属于右侧 outgoing 子空间。

---

## 7. Codex 实现总结公式

本节给出最终编程时需要直接照抄的公式。

### 7.1 输入

- `omega`: 外部背景波数 $\omega$；
- `beta`: $y$ 准周期参数 $\beta$；
- `d`: $y$ 方向周期；
- `Lplus`: 正 $x$ 方向 cell 周期 $L_+$；
- `M`: Rayleigh 截断阶数，channels 为 $m=-M,\ldots,M$；
- geometry arrays on $\partial\Omega$:
  - nodes $z_j=(x_j,y_j)$；
  - unit outward normals $\nu_j=(\nu_{x,j},\nu_{y,j})$；
  - speed $s_j=|z'(t_j)|$；
  - quadrature weight $h=2\pi/N$；
- existing BIE matrix `A_QP` corresponding to $A_{\mathrm{QP}}$ acting on $[\tau;-\sigma]$.

### 7.2 Rayleigh data

For `m = -M:M`, compute

$$
\beta_m=\beta+\frac{2\pi m}{d},
$$

$$
\gamma_m=\sqrt{\omega^2-\beta_m^2},
\qquad
\operatorname{Im}\gamma_m\ge 0.
$$

Then

$$
\psi_m(y)=d^{-1/2}e^{\mathrm{i}\beta_m y}.
$$

### 7.3 Incident trace matrices

For left incidence:

$$u_m^{L,\mathrm{inc}}(z_j)
=
d^{-1/2}
\exp\left[\mathrm{i}\gamma_m(x_j-X_L)+\mathrm{i}\beta_m y_j\right],
$$

$$
\partial_\nu u_m^{L,\mathrm{inc}}(z_j)
=
\mathrm{i}(\gamma_m\nu_{x,j}+\beta_m\nu_{y,j})u_m^{L,\mathrm{inc}}(z_j).
$$

For right incidence:

$$u_m^{R,\mathrm{inc}}(z_j)
=
d^{-1/2}
\exp\left[-\mathrm{i}\gamma_m(x_j-X_R)+\mathrm{i}\beta_m y_j\right],
$$

$$
\partial_\nu u_m^{R,\mathrm{inc}}(z_j)
=
\mathrm{i}(-\gamma_m\nu_{x,j}+\beta_m\nu_{y,j})u_m^{R,\mathrm{inc}}(z_j).
$$

Assemble

$$
H^L=-A_{\mathrm{QP}}^{-1}B^L,
\qquad
H^R=-A_{\mathrm{QP}}^{-1}B^R.
$$

In MATLAB, use factorization or backslash with multiple RHS:

```matlab
HL = -(A_QP \ BL);
HR = -(A_QP \ BR);
```

### 7.4 Far-field extraction matrices

For each channel $m$ and boundary node $j$:

$$
g_m^R(z_j)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
\exp\left[-\mathrm{i}\beta_m y_j-\mathrm{i}\gamma_m(x_j-X_R)\right],
$$

$$
g_m^L(z_j)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
\exp\left[-\mathrm{i}\beta_m y_j+\mathrm{i}\gamma_m(x_j-X_L)\right].
$$

Then

$$
(F_\tau^R)_{mj}
=
hs_j\left[-\mathrm{i}(\gamma_m\nu_{x,j}+\beta_m\nu_{y,j})g_m^R(z_j)\right],
$$

$$
(F_\mu^R)_{mj}
=
-hs_jg_m^R(z_j),
$$

$$
(F_\tau^L)_{mj}
=
hs_j\left[\mathrm{i}(\gamma_m\nu_{x,j}-\beta_m\nu_{y,j})g_m^L(z_j)\right],
$$

$$
(F_\mu^L)_{mj}
=
-hs_jg_m^L(z_j).
$$

Finally

$$
F^R=\begin{bmatrix}F_\tau^R & F_\mu^R\end{bmatrix},
\qquad
F^L=\begin{bmatrix}F_\tau^L & F_\mu^L\end{bmatrix}.
$$

### 7.5 Scattering matrix blocks

Define

$$
E_+=\operatorname{diag}(e^{\mathrm{i}\gamma_m L_+}).
$$

Then

$$
\boxed{
R_L^+=F^L H^L,
}
$$

$$
\boxed{
T_{L\to R}^+=E_+ + F^R H^L,
}
$$

$$
\boxed{
R_R^+=F^R H^R,
}
$$

$$
\boxed{
T_{R\to L}^+=E_+ + F^L H^R.
}
$$

Assemble

$$
S_{\mathrm{cell}}^+
=
\begin{bmatrix}
R_L^+ & T_{R\to L}^+\\
T_{L\to R}^+ & R_R^+
\end{bmatrix}.
$$

### 7.6 Bloch generalized eigenvalue problem

Form

$$
A_{\mathrm{sc}}^+
=
\begin{bmatrix}
-R_L^+ & I\\
T_{L\to R}^+ & 0
\end{bmatrix},
\qquad
B_{\mathrm{sc}}^+
=
\begin{bmatrix}
0 & T_{R\to L}^+\\
I & -R_R^+
\end{bmatrix}.
$$

Solve

$$
A_{\mathrm{sc}}^+v=\lambda B_{\mathrm{sc}}^+v.
$$

In MATLAB:

```matlab
[V, Lam] = eig(Asc, Bsc);
lambda = diag(Lam);
```

Each eigenvector has the amplitude form

$$
v_\ell=\begin{bmatrix}a_\ell\\ b_\ell\end{bmatrix}.
$$

### 7.7 Construct port Cauchy traces from Bloch amplitudes

At the left reference section $x=X_L$, the Dirichlet and $x$-normal derivative coefficients of a Bloch mode are

$$
d_\ell=a_\ell+b_\ell,
$$

$$
n_\ell=\mathrm{i}\operatorname{diag}(\gamma_m)(a_\ell-b_\ell).
$$

At the right reference section $x=X_R$, use

$$
a_\ell^R=\lambda_\ell a_\ell,
\qquad
b_\ell^R=\lambda_\ell b_\ell,
$$

so

$$
d_\ell^R=\lambda_\ell(a_\ell+b_\ell),
$$

$$
n_\ell^R=\lambda_\ell\mathrm{i}\operatorname{diag}(\gamma_m)(a_\ell-b_\ell).
$$

These columns form the matrices later denoted by

$$
D^+,
\qquad
N^+.
$$

---

## 8. Algorithm summary

1. Choose $M$ and form channels $m=-M,\ldots,M$.
2. Compute $\beta_m$ and $\gamma_m$.
3. Assemble $A_{\mathrm{QP}}$ for the single right-lead cell scatterer.
4. Assemble incident trace matrices $B^L$ and $B^R$ on $\partial\Omega$.
5. Solve
   $$
   H^L=-A_{\mathrm{QP}}^{-1}B^L,
   \qquad
   H^R=-A_{\mathrm{QP}}^{-1}B^R.
   $$
6. Assemble direct extraction matrices $F^R$ and $F^L$ from the Rayleigh coefficient formulas.
7. Compute
   $$
   R_L^+=F^L H^L,
   \qquad
   T_{L\to R}^+=E_+ + F^R H^L,
   $$
   $$
   R_R^+=F^R H^R,
   \qquad
   T_{R\to L}^+=E_+ + F^L H^R.
   $$
8. Assemble $S_{\mathrm{cell}}^+$.
9. Form $A_{\mathrm{sc}}^+$ and $B_{\mathrm{sc}}^+$.
10. Solve the generalized eigenvalue problem
    $$
    A_{\mathrm{sc}}^+v=\lambda B_{\mathrm{sc}}^+v.
    $$
11. Select right outgoing modes:
    - $|\lambda|<1$ for decaying modes;
    - $|\lambda|=1$ with positive $x$-directed energy flux for propagating modes.
12. Convert selected amplitude eigenvectors to port trace matrices $D^+$ and $N^+$ for later use in the linear-defect TEP matrix.

---

## 9. Implementation warnings

1. **Wood anomaly**: avoid or specially handle $\gamma_m=0$.
2. **Evanescent truncation**: include enough evanescent channels; keeping only propagating modes is usually insufficient near the scatterer.
3. **Phase origins**: the formulas assume left reference $X_L$ and right reference $X_R$. Do not silently change these origins without updating $g_m^L$, $g_m^R$, and incident fields.
4. **Normal derivative sign**: $D_{\mathrm{QP}}^{(\omega)}$ uses source-normal derivative. The formulas for $A_m^L$ and $A_m^R$ were derived by differentiating $g_m^L(z)$ and $g_m^R(z)$ with respect to the source point $z$.
5. **Multiple RHS**: for efficiency, factorize $A_{\mathrm{QP}}$ once per $(\omega,\beta)$ and solve all incident channels together.
6. **Scattering vs propagation**: the BIE calculation gives $S_{\mathrm{cell}}^+$, not the propagation operator directly. Bloch modes come from the generalized eigenvalue problem built from $S_{\mathrm{cell}}^+$.
