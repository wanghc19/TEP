# Scattering problem 的 trace 表述与 forcing 方式

本文整理线性缺陷 / missing-column 模型中 scattering problem 的基本表述。重点是区分三类对象：

- 与入射波有关的量使用下标 `in`；
- 与中心 cell 内点源 particular solution 有关的量使用下标 `p`；
- 与散射波有关的量使用下标 `s` 或 `scat`。

这些下标可用于场、trace、以及 trace 子空间，例如 $u_{\mathrm{in}}$、$D_{\mathrm{in}}$、$N_{\mathrm{in}}$、$\mathcal E_{\mathrm{in}}$，以及 $u_p$、$D_p^\pm$、$N_p^\pm$、$u_s$、$D_s^\pm$、$N_s^\pm$、$\mathcal E_{\mathrm{s}}^\pm$。

本文仍遵守以下符号约定：

- $L,R$ 只表示**单个 lead cell 的左 / 右壁**，不表示正 / 负 half-lead；
- 与正 / 负 half-lead 以及中心 cell 正 / 负端口有关的量使用上标 $+$ 和 $-$；
- 中心空腔展开中的 $c_m^+$、$c_m^-$ 是例外，它们只表示中心空腔中的 right-going / left-going Rayleigh amplitude，不表示正 / 负 half-lead。

---

## 1. Rayleigh trace space：为什么所有 trace 都能放在同一个大空间中

固定 $y$ 方向准周期参数 $\beta$ 和周期 $d$。定义

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\psi_m(y)=\frac{1}{\sqrt d}e^{\mathrm{i}\beta_m y}.
$$

由于整个问题在 $y$ 方向满足准周期条件

$$
u(x,y+d)=e^{\mathrm{i}\beta d}u(x,y),
$$

所以在任意竖直截面 $x=X$ 上，函数 $u(X,y)$ 仍然是 $y$-quasiperiodic 函数。因此可以展开为

$$
u(X,y)=\sum_{m\in\mathbb Z}D_m\psi_m(y).
$$

同理，$x$ 方向导数也满足同样的 $y$-quasiperiodicity：

$$
\partial_x u(X,y)=\sum_{m\in\mathbb Z}N_m\psi_m(y).
$$

因此，端口 Cauchy trace 可以写成

$$
\operatorname{Tr}(u)
=
\begin{bmatrix}
D\\
N
\end{bmatrix},
$$

其中 $D$ 是 Dirichlet trace coefficient，$N$ 是 $x$-derivative 或端口 outward-normal derivative 的 trace coefficient，具体取决于上下文。

截断到

$$
|m|\le M,
\qquad
K=2M+1,
$$

后，所有端口 Cauchy trace 都被表示在有限维空间

$$
\mathbb C^K\times\mathbb C^K=\mathbb C^{2K}
$$

中。

这里要强调：Rayleigh basis $\{\psi_m\}$ 是**端口截面上的通用坐标基底**，不是说 lead 中的 Bloch mode 本身就是单个 Rayleigh wave。真实 Bloch mode 在一个 lead cell 内可能很复杂，但它在 cell wall 上的 trace 仍然可以用同一组 $\psi_m$ 表示。

因此 incoming、outgoing/scattered、particular source trace 都属于同一个更大的 Rayleigh Cauchy trace space：

$$
\begin{bmatrix}D_{\mathrm{in}}\\N_{\mathrm{in}}\end{bmatrix},
\quad
\begin{bmatrix}D_s\\N_s\end{bmatrix},
\quad
\begin{bmatrix}D_p\\N_p\end{bmatrix}
\in
\mathbb C^{2K}.
$$

但是它们通常属于这个大空间中的不同子空间。

---

## 2. Incoming 与 outgoing trace 子空间

在截断模型中，一个 lead cell 的 Bloch generalized eigenproblem 给出约 $2K$ 个 Bloch mode。通过 mode selection，可以分出 incoming 和 outgoing 子空间。

在某个端口处，incoming trace 子空间写作

$$
\mathcal E_{\mathrm{in}}
=
\left\{
\begin{bmatrix}
D_{\mathrm{in}}p\\
N_{\mathrm{in}}p
\end{bmatrix}
:
 p\in\mathbb C^{K_{\mathrm{in}}}
\right\}
\subset \mathbb C^{2K}.
$$

outgoing/scattered trace 子空间写作

$$
\mathcal E_{\mathrm{s}}
=
\left\{
\begin{bmatrix}
D_{\mathrm{out}}q\\
N_{\mathrm{out}}q
\end{bmatrix}
:
q\in\mathbb C^{K_{\mathrm{out}}}
\right\}
\subset \mathbb C^{2K}.
$$

一般来说，$\mathcal E_{\mathrm{in}}$ 和 $\mathcal E_s$ 不是同一个子空间。散射问题并不是因为入射 trace 属于一个 $K$ 维子空间，所以散射 trace 也属于同一个子空间；真正的理由是：散射波在 half-lead 中满足齐次方程，并被要求满足 outgoing/radiation condition，因此其 trace 属于 outgoing 子空间。

在精确连续问题中，这些空间是无限维的。有限维 $K$ 是 Rayleigh/Bloch 截断近似。

---

## 3. Scattering problem 的总体思路

scattering problem 的基本分解是

$$
u=u_{\mathrm{forcing}}+u_s.
$$

这里 $u_{\mathrm{forcing}}$ 可以有两种典型来源：

1. 从无穷远 lead 给定的 incoming wave：

$$
u_{\mathrm{forcing}}=u_{\mathrm{in}}.
$$

2. 中心 cell 中给定的点源 particular solution：

$$
u_{\mathrm{forcing}}=u_p.
$$

未知的 $u_s$ 总是 scattered field，并且在左右 half-lead 中应满足 outgoing condition。换句话说，未知散射 trace 用 outgoing trace basis 表示。

对端口 $\pm$，通常写成

$$
\begin{bmatrix}
D^\pm\\
N^\pm
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{forcing}}^\pm\\
N_{\mathrm{forcing}}^\pm
\end{bmatrix}
+
\begin{bmatrix}
D_s^\pm\\
N_s^\pm
\end{bmatrix}.
$$

其中

$$
\begin{bmatrix}
D_s^\pm\\
N_s^\pm
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{out}}^\pm\\
N_{\mathrm{out}}^\pm
\end{bmatrix}a^\pm.
$$

---

## 4. 情形一：从无穷远 lead 给定 incoming wave

### 4.1 入射 trace

假设从负 half-lead 或正 half-lead 给定一个 incoming wave。它不是任意一组独立的 $D$ 和 $N$，而是 incoming Bloch trace 子空间中的一个元素。

例如负端口入射可以写成

$$
\begin{bmatrix}
D_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-
\end{bmatrix}_{\mathrm{basis}}p^-.
$$

为避免符号过重，也可将 basis matrix 仍记作

$$
D_{\mathrm{in}}^-,\quad N_{\mathrm{in}}^-,
$$

并将入射系数记作 $p^-$，于是

$$
D_{\mathrm{in,tot}}^-=D_{\mathrm{in}}^-p^-,
\qquad
N_{\mathrm{in,tot}}^-=N_{\mathrm{in}}^-p^-.
$$

类似地，正端口入射为

$$
D_{\mathrm{in,tot}}^+=D_{\mathrm{in}}^+p^+,
\qquad
N_{\mathrm{in,tot}}^+=N_{\mathrm{in}}^+p^+.
$$

在 scattering problem 中，$p^\pm$ 是给定的，而 outgoing 系数 $a^\pm$ 是未知的。

### 4.2 以 empty-defect cell 为例的方程

中心 empty-defect cell 中的齐次场写为

$$
u_0(x,y)
=
\sum_m c_m^+e^{\mathrm{i}\gamma_m(x-X_0^-)}\psi_m(y)
+
\sum_m c_m^-e^{-\mathrm{i}\gamma_m(x-X_0^-)}\psi_m(y).
$$

这里 $c_m^+$、$c_m^-$ 只表示中心空腔 Rayleigh 展开中的 right-going / left-going amplitude。

令

$$
E=\operatorname{diag}(e^{\mathrm{i}\gamma_mL_0}),
\qquad
L_0=X_0^+-X_0^-,
\qquad
\Gamma=\operatorname{diag}(\gamma_m).
$$

中心空腔负端口 outward trace 为

$$
D_0^-=c^+ + c^-,
$$

$$
N_0^-=-\mathrm{i}\Gamma(c^+-c^-).
$$

中心空腔正端口 outward trace 为

$$
D_0^+=Ec^+ + E^{-1}c^-,
$$

$$
N_0^+=\mathrm{i}\Gamma(Ec^+-E^{-1}c^-).
$$

设左右 outgoing trace 为

$$
D_s^- = D_{\mathrm{out}}^-a^-,
\qquad
N_s^- = N_{\mathrm{out}}^-a^-,
$$

$$
D_s^+ = D_{\mathrm{out}}^+a^+,
\qquad
N_s^+ = N_{\mathrm{out}}^+a^+.
$$

若两端都允许给定入射，则匹配条件为

$$
D_0^- = D_{\mathrm{in,tot}}^- + D_{\mathrm{out}}^-a^-,
$$

$$
N_0^- = N_{\mathrm{in,tot}}^- + N_{\mathrm{out}}^-a^-,
$$

$$
D_0^+ = D_{\mathrm{in,tot}}^+ + D_{\mathrm{out}}^+a^+,
$$

$$
N_0^+ = N_{\mathrm{in,tot}}^+ + N_{\mathrm{out}}^+a^+.
$$

将未知量取为

$$
\begin{bmatrix}
c^+\\c^-\\a^-\\a^+
\end{bmatrix},
$$

则左端矩阵与 homogeneous cavity problem 相同，右端项由 incoming trace 给出：

$$
\begin{bmatrix}
I & I & -D_{\mathrm{out}}^- & 0\\
-\mathrm{i}\Gamma & \mathrm{i}\Gamma & -N_{\mathrm{out}}^- & 0\\
E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
\mathrm{i}\Gamma E & -\mathrm{i}\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}
\begin{bmatrix}
c^+\\c^-\\a^-\\a^+
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{in,tot}}^-\\
N_{\mathrm{in,tot}}^-\\
D_{\mathrm{in,tot}}^+\\
N_{\mathrm{in,tot}}^+
\end{bmatrix}.
$$

如果只从负端口入射，则取

$$
D_{\mathrm{in,tot}}^+=0,
\qquad
N_{\mathrm{in,tot}}^+=0.
$$

如果只从正端口入射，则负端口入射 trace 置零。

---

## 5. 情形二：中心 cell 中有沿 $y$ 方向准周期分布的点源

### 5.1 点源 particular solution

考虑中心 empty-defect cell 中存在一个点源

$$
(x_s,y_s).
$$

沿 $y$ 方向作准周期复制后，可以用 $y$-quasiperiodic Green function 作为 particular solution：

$$
u_p(x,y)=G_{\mathrm{QP}}^{(k)}((x,y),(x_s,y_s)).
$$

Rayleigh 展开为

$$
G_{\mathrm{QP}}^{(k)}((x,y),(x_s,y_s))
=
\frac{\mathrm{i}}{2d}
\sum_m
\frac{1}{\gamma_m}
 e^{\mathrm{i}\beta_m(y-y_s)}
 e^{\mathrm{i}\gamma_m|x-x_s|}.
$$

因此，$u_p$ 在正负端口上的 trace 可以直接写成 Rayleigh 系数。

### 5.2 点源在端口上的 trace

正端口 $x=X_0^+$ 的 particular Dirichlet trace 系数为

$$
D_p^+(m)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
 e^{-\mathrm{i}\beta_m y_s}
 e^{\mathrm{i}\gamma_m(X_0^+-x_s)}.
$$

负端口 $x=X_0^-$ 的 particular Dirichlet trace 系数为

$$
D_p^-(m)
=
\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
 e^{-\mathrm{i}\beta_m y_s}
 e^{\mathrm{i}\gamma_m(x_s-X_0^-)}.
$$

若 $x_s=0$ 且

$$
X_0^-=-L/2,
\qquad
X_0^+=L/2,
$$

则两个端口到点源的距离相同，衰减尺度由

$$
\delta=L/2
$$

控制。

对 Neumann trace，本文采用中心区域端口 outward normal。正端口 outward normal 是 $+e_x$，负端口 outward normal 是 $-e_x$。因此有

$$
N_p^+(m)=\mathrm{i}\gamma_mD_p^+(m),
$$

$$
N_p^-(m)=\mathrm{i}\gamma_mD_p^-(m).
$$

后一式中的正号来自负端口 outward normal $-e_x$ 与 left-going derivative 的负号相互抵消。

### 5.3 Forced matching system

中心区域总场写作

$$
u_0=u_p+u_h,
$$

其中 $u_h$ 是中心空腔中的齐次 Rayleigh 展开：

$$
u_h(x,y)
=
\sum_m c_m^+e^{\mathrm{i}\gamma_m(x-X_0^-)}\psi_m(y)
+
\sum_m c_m^-e^{-\mathrm{i}\gamma_m(x-X_0^-)}\psi_m(y).
$$

匹配条件为

$$
D_h^-+D_p^- = D_{\mathrm{out}}^-a^-,
$$

$$
N_h^-+N_p^- = N_{\mathrm{out}}^-a^-,
$$

$$
D_h^++D_p^+ = D_{\mathrm{out}}^+a^+,
$$

$$
N_h^++N_p^+ = N_{\mathrm{out}}^+a^+.
$$

因此矩阵左边仍与 homogeneous empty-defect problem 相同：

$$
\begin{bmatrix}
I & I & -D_{\mathrm{out}}^- & 0\\
-\mathrm{i}\Gamma & \mathrm{i}\Gamma & -N_{\mathrm{out}}^- & 0\\
E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
\mathrm{i}\Gamma E & -\mathrm{i}\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}
\begin{bmatrix}
c^+\\c^-\\a^-\\a^+
\end{bmatrix}
=
-
\begin{bmatrix}
D_p^-\\
N_p^-\\
D_p^+\\
N_p^+
\end{bmatrix}.
$$

这个问题是一个有源 forced scattering problem。它不是 cavity eigenvalue problem，因为右端项非零；也不是从无穷远 lead 入射的问题，因为 forcing term 位于中心 cell 内。

---

## 6. 用点源估计 Rayleigh 截断阶数

点源 formulation 的一个优点是可以较自然地估计 Rayleigh 截断阶数 $M$。当 $|m|$ 大时，若 $k$ 为实数，则

$$
\gamma_m\approx \mathrm{i}|\beta_m|,
\qquad
|\beta_m|\sim \frac{2\pi |m|}{d}.
$$

点源到端口的距离为 $\delta$ 时，高阶 trace 系数大致带有衰减因子

$$
e^{-\operatorname{Im}\gamma_m\delta}.
$$

因此可以要求第一个被截断的 mode 满足

$$
e^{-\operatorname{Im}\gamma_{M+1}\delta}\lesssim \mathrm{tol}.
$$

粗略估计为

$$
M\gtrsim \frac{d}{2\pi\delta}\log\frac{1}{\mathrm{tol}}.
$$

如果点源位于中心 $x_s=0$，且端口为 $X_0^\pm=\pm L/2$，则

$$
\delta=\frac{L}{2}.
$$

这比任意指定一个 wall trace 更有物理意义，因为 forcing term 的空间位置明确决定了高阶 evanescent tail 的大小。

---

## 7. 小结

Scattering problem 的共同结构是：

$$
\text{known forcing trace} + \text{unknown outgoing scattered trace}
= \text{center-region trace}.
$$

从 lead 入射时，known forcing trace 是 $\mathcal E_{\mathrm{in}}$ 中的 incoming trace；中心点源 forcing 时，known forcing trace 是 particular solution $u_p$ 在端口上的 trace。

无论哪种 forcing，未知散射波都应满足 outgoing condition，因此其 trace 使用

$$
D_{\mathrm{out}}^\pm,
\qquad
N_{\mathrm{out}}^\pm
$$

表示。

Rayleigh basis $\psi_m$ 的作用只是为所有端口 trace 提供统一坐标系。incoming、particular、scattered/outgoing trace 都可以写成这个大 Rayleigh Cauchy trace space 中的向量，但它们对应不同的物理子空间或不同的 forcing 来源。

## 8. 杂项 / Q&A

### 8.1 为什么不能任意指定 wall trace 作为入射波？

在端口方法中，wall trace 不能任意指定。合法的入射数据必须来自相应 half-lead 的 incoming trace 子空间。

也就是说，若负 half-lead 有 incoming trace basis

$$
D_{\mathrm{in}}^-,
\qquad
N_{\mathrm{in}}^-,
$$

则合法入射 Cauchy trace 应写成

$$
\begin{bmatrix}
D_{\mathrm{in}}\\
N_{\mathrm{in}}
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{in}}^-\\
N_{\mathrm{in}}^-
\end{bmatrix}p,
$$

其中 $p$ 是人为选择的入射系数向量。

如果直接任意给出

$$
(D,N)\in\mathbb C^K\times\mathbb C^K,
$$

它一般不属于 incoming 子空间，也不一定对应某个能在 half-lead 中传播或衰减的合法入射场。这样的数据只能解释为人工端口强迫，而不是物理意义上的 lead 入射波。

---

### 8.2 为什么 incoming 子空间和 outgoing 子空间都能用同一组 Rayleigh basis 表示？

Rayleigh basis

$$
\psi_m(y)=\frac{1}{\sqrt d}e^{\mathrm{i}\beta_m y},
\qquad
\beta_m=\beta+\frac{2\pi m}{d},
$$

不是说 lead 中的真实 Bloch mode 都是简单 Rayleigh 波，而是作为 wall 上 $y$-准周期函数的通用坐标基底。

对任意固定竖直 wall，例如 $x=X$，若场满足

$$
u(x,y+d)=e^{\mathrm{i}\beta d}u(x,y),
$$

则

$$
u(X,y)
$$

和

$$
\partial_x u(X,y)
$$

都是 $y$-准周期函数，因此都可以展开为

$$
u(X,y)=\sum_m D_m\psi_m(y),
$$

$$
\partial_x u(X,y)=\sum_m N_m\psi_m(y).
$$

所以 incoming trace、outgoing trace、散射 trace、点源 particular trace 都位于同一个大的 Rayleigh Cauchy trace space 中：

$$
(D,N)\in\ell^2\times\ell^2.
$$

截断到 $|m|\leq M$ 后，则写成

$$
(D,N)\in\mathbb C^K\times\mathbb C^K,
\qquad K=2M+1.
$$

incoming / outgoing 子空间是这个大 Cauchy trace space 中的不同子空间，而不是不同的坐标系统。

---

### 8.3 为什么散射波的 trace 属于 outgoing 子空间？

这不是由入射波属于 incoming 子空间推出的，而是由散射问题的 radiation / outgoing condition 定义的。

散射问题写成

$$
u=u_{\mathrm{in}}+u_{\mathrm{s}},
$$

其中 $u_{\mathrm{in}}$ 是已知入射部分，$u_{\mathrm{s}}$ 是未知散射部分。要求是：

$$
u_{\mathrm{s}}
\quad\text{在每个 half-lead 中满足 outgoing condition}.
$$

因此在端口上有

$$
\begin{bmatrix}
D_{\mathrm{s}}\\
N_{\mathrm{s}}
\end{bmatrix}
\in
\mathcal E_{\mathrm{out}},
$$

即

$$
\begin{bmatrix}
D_{\mathrm{s}}\\
N_{\mathrm{s}}
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{out}}\\
N_{\mathrm{out}}
\end{bmatrix}q
$$

for some coefficient vector $q$。

精确问题中 $\mathcal E_{\mathrm{out}}$ 是无限维的；数值计算中用有限 $M$ 截断它。因此更准确的说法是：

$$
\operatorname{Tr}(u_{\mathrm{s}})
\approx
\begin{bmatrix}
D_{\mathrm{out}}\\
N_{\mathrm{out}}
\end{bmatrix}q.
$$

---

### 8.4 入射波可以是多个 Bloch modes 的线性组合吗？

可以。这里需要谨慎使用 “Bloch mode” 一词。

本文中 Bloch mode 特指通过 lead cell 的传播 / scattering 矩阵求出的、沿 $x$ 方向推进一个 cell 后乘以 Floquet multiplier 的本征解。入射波不必是单个 Bloch mode；它可以是 incoming Bloch trace 子空间中的任意线性组合：

$$
u_{\mathrm{in}}
=
\sum_j p_j\,\phi_j^{\mathrm{in}}.
$$

对应端口 Cauchy trace 为

$$
\begin{bmatrix}
D_{\mathrm{in}}\\
N_{\mathrm{in}}
\end{bmatrix}
=
\sum_j p_j
\begin{bmatrix}
D_j^{\mathrm{in}}\\
N_j^{\mathrm{in}}
\end{bmatrix}.
$$

因此，不能把任意入射波都称为“一个 Bloch mode”。只有单个满足 Floquet multiplier 条件的本征解才称为 Bloch mode。

---

### 8.5 为什么从负无穷入射时只给负端口 trace，而不给正端口 trace？

自由空间单体散射中，入射平面波

$$
u_{\mathrm{in}}(x)=e^{\mathrm{i}k d\cdot x}
$$

是整个背景空间中的已知解。因此可以把它限制到整个物体边界上，作为边界积分方程的右端项。

但在 lead scattering 中，从负 half-lead 入射的 incoming wave 只是负半无限周期结构中的合法 incoming 解。它不是整个缺陷结构中的已知解，也不是正 half-lead 中的已知解。

因此从负无穷入射时，已知的是负端口 incoming trace：

$$
D_{\mathrm{in}}^-,
\qquad
N_{\mathrm{in}}^-.
$$

正端口没有从正无穷来的入射波，正端口 trace 是未知透射响应，应由方程求出并匹配到正 half-lead outgoing 子空间：

$$
\begin{bmatrix}
D_{\mathrm{s}}^+\\
N_{\mathrm{s}}^+
\end{bmatrix}
=
\begin{bmatrix}
D_{\mathrm{out}}^+\\
N_{\mathrm{out}}^+
\end{bmatrix}a^+.
$$

如果同时在正端口也给 incoming trace，则描述的是双边入射问题，而不是单侧入射。

---

### 8.6 中心 cell 内有介质柱时，是否还要把入射波限制到介质柱边界？

如果直接解中心 cell 的边界积分方程，则需要。

设中心 cell 内有介质柱 $\Omega_0$。若某个进入中心 cell 的入射场为 $u_{\mathrm{in}}$，则在构造中心 cell scattering matrix 时，需要在介质柱边界上形成右端项：

$$
A_{\mathrm{QP}}\eta
=
-
\begin{bmatrix}
u_{\mathrm{in}}|_{\partial\Omega_0}\\
\partial_\nu u_{\mathrm{in}}|_{\partial\Omega_0}
\end{bmatrix}.
$$

这里 $u_{\mathrm{in}}$ 通常不是自由空间平面波，而是从端口进入中心 cell 的 Rayleigh 组合。

但如果已经预先构造了中心 cell scattering matrix $S_0$，那么后续端口匹配时不需要再显式把入射波限制到 $\partial\Omega_0$。因为 $S_0$ 的构造过程已经对每个 Rayleigh incoming basis 做过这一步，并把中心介质柱的边界条件编码进了 $S_0$。

因此：

$$
\text{直接 BIE 视角：需要 restrict 到 }\partial\Omega_0.
$$

$$
\text{端口散射矩阵视角：这一步已被 }S_0\text{ 吸收。}
$$

---

### 8.7 如果已知 missing-column 背景解，能否像自由空间散射一样处理中心介质柱？

可以。

假设先求出挖掉中心介质柱后的背景解

$$
u_{\mathrm{bg}},
$$

它满足：
1. 左右 half-lead 的合法 incoming/outgoing 条件；
2. 中心空腔中的背景 Helmholtz 方程；
3. 端口匹配条件；
4. 但中心介质柱尚未放回去。

若之后将中心介质柱放回，可以写成

$$
u=u_{\mathrm{bg}}+u_{\mathrm{s}},
$$

其中 $u_{\mathrm{s}}$ 是由新增中心介质柱产生的 correction。此时可以像自由空间单体散射一样，把背景解限制到中心介质柱边界上：

$$
u_{\mathrm{bg}}|_{\partial\Omega_0},
\qquad
\partial_\nu u_{\mathrm{bg}}|_{\partial\Omega_0}.
$$

这些量可作为放回中心介质柱后的 BIE 右端项。

但严格地说，$u_{\mathrm{s}}$ 应满足的是 missing-column 背景结构中的 outgoing 条件。若有该背景结构的 Green function，则可以直接用它构造散射表示；若没有，则仍需要通过端口 matching 来强制左右 half-lead outgoing 条件。

---

### 8.8 用中心 cell 内的周期点源作为 forcing 是否合理？

合理，而且比随机指定 wall trace 更有物理意义。

若在中心空腔中放置一个沿 $y$ 方向准周期复制的点源，记 particular solution 为

$$
u_{\mathrm{p}}(x,y)
=
G_{\mathrm{QP}}^{(k)}((x,y),(x_s,y_s)),
$$

则总场可写为

$$
u_0=u_{\mathrm{p}}+u_{\mathrm{h}},
$$

其中 $u_{\mathrm{h}}$ 是中心空腔中的齐次 Rayleigh 展开。

点源在端口上的 trace 记为

$$
D_{\mathrm{p}}^\pm,
\qquad
N_{\mathrm{p}}^\pm.
$$

然后 matching 方程写成：

$$
D_{\mathrm{h}}^-+D_{\mathrm{p}}^-
=
D_{\mathrm{out}}^-a^-,
$$

$$
N_{\mathrm{h}}^-+N_{\mathrm{p}}^-
=
N_{\mathrm{out}}^-a^-,
$$

$$
D_{\mathrm{h}}^++D_{\mathrm{p}}^+
=
D_{\mathrm{out}}^+a^+,
$$

$$
N_{\mathrm{h}}^++N_{\mathrm{p}}^+
=
N_{\mathrm{out}}^+a^+.
$$

这给出一个非齐次 forced scattering problem，而不是齐次 cavity-mode problem。

如果点源位于中心 $x_s=0$，中心端口为

$$
X_0^-=-L/2,
\qquad
X_0^+=L/2,
$$

则点源到左右端口距离为

$$
\delta=L/2.
$$

高阶 Rayleigh 项大致含有衰减因子

$$
e^{-\operatorname{Im}\gamma_m\delta}.
$$

因此可以用

$$
e^{-\operatorname{Im}\gamma_{M+1}\delta}
\lesssim \mathrm{tol}
$$

来估计 Rayleigh 截断阶数 $M$。

粗略地，当 $|m|$ 较大时，

$$
\operatorname{Im}\gamma_m\sim \frac{2\pi |m|}{d},
$$

所以

$$
M
\gtrsim
\frac{d}{2\pi\delta}
\log\frac{1}{\mathrm{tol}}.
$$

---

### 8.9 有限维 trace 子空间只是截断近似

精确问题中的 Rayleigh / Bloch 展开一般是无限维的。有限 $M$ 截断后，端口 trace space 为

$$
\mathbb C^K\times\mathbb C^K,
\qquad K=2M+1.
$$

incoming 和 outgoing 子空间在该截断空间中通常各有约 $K$ 个维度。但这只是数值近似，不表示真实散射波严格属于某个固定有限维子空间。

截断合理性的来源是高阶 evanescent modes 在端口与散射区域之间快速衰减。若端口到源或散射区域的距离为 $\delta$，则 omitted modes 的影响可由

$$
e^{-\operatorname{Im}\gamma_m\delta}
$$

估计。

因此，小 $M$ 可以用于 toy model 或代码验证；若要获得物理精度，则必须做 $M$ 收敛测试。