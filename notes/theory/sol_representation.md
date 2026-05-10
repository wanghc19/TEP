# Note on solution representation for the linear-defect eigenvalue problem

本文记录线性缺陷晶体特征值问题的第一版解表示。当前版本采用**方案 A**：

1. 介质柱边界上的 Müller 表示尽量沿用已有的一维周期波导 TEP 代码；
2. density 只定义在真实介质界面上，不在左右人工边界上引入新的 layer-potential density；
3. 左右人工边界只用于把外部场的 Cauchy data 匹配到预先算出的 outgoing Bloch modes；
4. 暂不考虑 TE mode，因此所有法向导数均为普通法向导数，不引入加权系数。

---

## 1. 几何与符号

令中心 cell 中只有一个单连通介质柱

$$
\Omega_0,
\qquad
\Sigma=\partial\Omega_0.
$$

令外部中心区域为

$$
\Omega\setminus \overline{\Omega_0}.
$$

上下方向施加准周期条件，准周期参数记为 $\beta$。外部 Green 函数记为

$$
G_{\mathrm{QP}}^{(\omega)}.
$$

这里的 QP 表示沿周期方向的 quasi-periodicity；在当前线性缺陷设定中，这个周期方向可以理解为 $y$ 方向。

令

$$
k_{\mathrm{out}}=\omega,
\qquad
k_{\mathrm{in}}=n\omega.
$$

介质柱边界 $\Sigma$ 上的单位法向量 $\nu$ 规定为从介质柱内部指向外部区域。

左右人工边界记为

$$
\Gamma_+,
\qquad
\Gamma_-.
$$

其中 $\Gamma_+$ 是右端口，$\Gamma_-$ 是左端口。端口法向量取为从中心区域指向对应 lead：

$$
\nu_+=e_x
\quad\text{on }\Gamma_+,
\qquad
\nu_-=-e_x
\quad\text{on }\Gamma_-.
$$

注意本文中两个加号/减号含义不同：

- $u^+$ 与 $u^-$ 分别表示介质柱外部与内部的场；
- $\Gamma_+$ 与 $\Gamma_-$ 分别表示右、左人工边界。

---

## 2. Layer-potential 算子记号

沿用已有笔记中的算子记号。对自由空间 Helmholtz Green 函数 $\Phi_k$，定义

$$
S^{(k)}[\sigma](x)
=
\int_\Sigma \Phi_k(x,y)\sigma(y)\,ds_y,
$$

$$
D^{(k)}[\tau](x)
=
\int_\Sigma \frac{\partial \Phi_k(x,y)}{\partial n_y}\tau(y)\,ds_y.
$$

对外部准周期 Green 函数，定义

$$
S_{\mathrm{QP}}^{(\omega)}[\sigma](x)
=
\int_\Sigma G_{\mathrm{QP}}^{(\omega)}(x,y)\sigma(y)\,ds_y,
$$

$$
D_{\mathrm{QP}}^{(\omega)}[\tau](x)
=
\int_\Sigma \frac{\partial G_{\mathrm{QP}}^{(\omega)}(x,y)}{\partial n_y}\tau(y)\,ds_y.
$$

法向导数相关算子为

$$
D^{(k)*}[\sigma](x)
=
\frac{\partial}{\partial n_x}S^{(k)}[\sigma](x),
$$

$$
T^{(k)}[\tau](x)
=
\frac{\partial}{\partial n_x}D^{(k)}[\tau](x),
$$

以及相应的准周期版本

$$
D_{\mathrm{QP}}^{(\omega)*},
\qquad
T_{\mathrm{QP}}^{(\omega)}.
$$

当 target 点在 $\Gamma_\pm$ 上时，$\partial /\partial n_x$ 使用端口法向量 $\nu_\pm$。由于 $\Gamma_\pm$ 与 $\Sigma$ 不相交，端口上的这些核是光滑的，不涉及 $\Sigma$ 上的 jump term。

---

## 3. 中心区域解表示

内部场表示为

$$
u^-(x)
=
D^{(n\omega)}[\tau](x)
+
S^{(n\omega)}[\sigma](x),
\qquad
x\in D.
$$

外部场表示为

$$
u^+(x)
=
D_{\mathrm{QP}}^{(\omega)}[\tau](x)
+
S_{\mathrm{QP}}^{(\omega)}[\sigma](x),
\qquad
x\in \Omega\setminus \overline{\Omega_0}.
$$

为了和已有 `LOCAL_construct_A` 的符号兼容，未知量写成

$$
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
$$

因此上面的表示也可写成

$$
u^-(x)
=
\begin{bmatrix}
D^{(n\omega)} & -S^{(n\omega)}
\end{bmatrix}
\eta,
$$

$$
u^+(x)
=
\begin{bmatrix}
D_{\mathrm{QP}}^{(\omega)} & -S_{\mathrm{QP}}^{(\omega)}
\end{bmatrix}
\eta.
$$

这里的符号重点是：解的表示本身是 $D\tau+S\sigma$，但矩阵未知量使用 $[\tau; -\sigma]$，所以矩阵块中出现 $-S$。

---

## 4. 介质柱边界上的 Müller 方程

在 $\Sigma$ 上施加普通 transmission conditions：

$$
u^+ - u^- =0,
$$

$$
u_n^+ - u_n^- =0.
$$

按照已有笔记中的约定，这正好给出

$$
\begin{bmatrix}
u^+ - u^-\\
u_n^+ - u_n^-
\end{bmatrix}
=
\left(
\begin{bmatrix}
I&0\\
0&I
\end{bmatrix}
+
\begin{bmatrix}
D_{\mathrm{QP}}^{(\omega)}-D^{(n\omega)}
&
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}
\\
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}
&
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*}
\end{bmatrix}
\right)
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
$$

记

$$
A_{\mathrm{QP}}
=
\begin{bmatrix}
I&0\\
0&I
\end{bmatrix}
+
\begin{bmatrix}
D_{\mathrm{QP}}^{(\omega)}-D^{(n\omega)}
&
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}
\\
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}
&
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*}
\end{bmatrix}.
$$

于是介质柱边界上的 Müller 方程为

$$
A_{\mathrm{QP}}\eta=0.
$$

在当前线性缺陷问题的第一版表示中，$A_{\mathrm{QP}}$ 仍然只作用在介质柱边界 $\Sigma$ 上。左右人工边界不参与 $A_{\mathrm{QP}}$ 的 layer-potential density 定义。

---

## 5. 端口 trace evaluation 算子

由于外部场由 $\Sigma$ 上的 density 生成，因此可以在左右人工边界上直接评估它的 Dirichlet trace 和 Neumann trace。

定义右端口 Dirichlet trace 算子

$$
C_+^D
=
\begin{bmatrix}
D_{\Gamma_+\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}
&
-S_{\Gamma_+\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}
\end{bmatrix},
$$

使得

$$
C_+^D\eta
=
u^+|_{\Gamma_+}.
$$

定义右端口 Neumann trace 算子

$$
C_+^N
=
\begin{bmatrix}
T_{\Gamma_+\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}
&
-D_{\Gamma_+\leftarrow\Sigma,\mathrm{QP}}^{(\omega)*}
\end{bmatrix},
$$

使得

$$
C_+^N\eta
=
\frac{\partial u^+}{\partial \nu_+}\bigg|_{\Gamma_+}.
$$

同理定义左端口算子

$$
C_-^D
=
\begin{bmatrix}
D_{\Gamma_-\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}
&
-S_{\Gamma_-\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}
\end{bmatrix},
$$

$$
C_-^N
=
\begin{bmatrix}
T_{\Gamma_-\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}
&
-D_{\Gamma_-\leftarrow\Sigma,\mathrm{QP}}^{(\omega)*}
\end{bmatrix},
$$

使得

$$
C_-^D\eta
=
u^+|_{\Gamma_-},
$$

$$
C_-^N\eta
=
\frac{\partial u^+}{\partial \nu_-}\bigg|_{\Gamma_-}.
$$

这里 $T_{\Gamma_\pm\leftarrow\Sigma,\mathrm{QP}}^{(\omega)}$ 是 off-boundary mixed-normal evaluation：source normal 在 $\Sigma$ 上，target normal 在 $\Gamma_\pm$ 上。由于 target 与 source 不重合，它只是一个光滑矩阵，不需要 hypersingular quadrature。

---

## 6. Bloch mode trace 矩阵

假设右侧 outgoing Bloch modes 已经算出，记为

$$
\phi_1^+,
\dots,
\phi_{m_+}^+.
$$

这里的上标 $+$ 只表示右 lead 的 outgoing modes，不表示介质柱外侧 trace。定义右端口 Bloch Dirichlet trace 矩阵

$$
B_+^D
=
\begin{bmatrix}
\phi_1^+|_{\Gamma_+}
&
\phi_2^+|_{\Gamma_+}
&
\cdots
&
\phi_{m_+}^+|_{\Gamma_+}
\end{bmatrix},
$$

以及右端口 Bloch Neumann trace 矩阵

$$
B_+^N
=
\begin{bmatrix}
\partial_{\nu_+}\phi_1^+|_{\Gamma_+}
&
\partial_{\nu_+}\phi_2^+|_{\Gamma_+}
&
\cdots
&
\partial_{\nu_+}\phi_{m_+}^+|_{\Gamma_+}
\end{bmatrix}.
$$

令对应 mode 系数为

$$
a^+
=
\begin{bmatrix}
a_1^+\\
\vdots\\
a_{m_+}^+
\end{bmatrix}.
$$

则右端口 outgoing matching 条件为

$$
C_+^D\eta-B_+^D a^+=0,
$$

$$
C_+^N\eta-B_+^N a^+=0.
$$

左侧 outgoing Bloch modes 记为

$$
\phi_1^-,
\dots,
\phi_{m_-}^-.
$$

定义

$$
B_-^D
=
\begin{bmatrix}
\phi_1^-|_{\Gamma_-}
&
\phi_2^-|_{\Gamma_-}
&
\cdots
&
\phi_{m_-}^-|_{\Gamma_-}
\end{bmatrix},
$$

$$
B_-^N
=
\begin{bmatrix}
\partial_{\nu_-}\phi_1^-|_{\Gamma_-}
&
\partial_{\nu_-}\phi_2^-|_{\Gamma_-}
&
\cdots
&
\partial_{\nu_-}\phi_{m_-}^-|_{\Gamma_-}
\end{bmatrix}.
$$

令

$$
a^-
=
\begin{bmatrix}
a_1^-\\
\vdots\\
a_{m_-}^-
\end{bmatrix}.
$$

左端口 outgoing matching 条件为

$$
C_-^D\eta-B_-^D a^-=0,
$$

$$
C_-^N\eta-B_-^N a^-=0.
$$

---

## 7. 总未知量与大矩阵

总未知量取为

$$
X
=
\begin{bmatrix}
\tau\\
-\sigma\\
a^+\\
a^-
\end{bmatrix}
=
\begin{bmatrix}
\eta\\
a^+\\
a^-
\end{bmatrix}.
$$

总矩阵记为 $\mathcal A(\omega,\beta)$，定义为

$$
\boxed{
\mathcal A(\omega,\beta)
=
\begin{bmatrix}
A_{\mathrm{QP}} & 0 & 0\\
C_+^D & -B_+^D & 0\\
C_+^N & -B_+^N & 0\\
C_-^D & 0 & -B_-^D\\
C_-^N & 0 & -B_-^N
\end{bmatrix}.
}
$$

于是线性缺陷特征值问题的第一版离散方程写成

$$
\boxed{
\mathcal A(\omega,\beta)
\begin{bmatrix}
\tau\\
-\sigma\\
a^+\\
a^-
\end{bmatrix}
=0.
}
$$

其中第一行块

$$
A_{\mathrm{QP}}\eta=0
$$

是介质柱边界上的 Müller transmission equation；后四行块是左右端口上的 outgoing Bloch Cauchy-data matching。

---

## 8. 离散维度说明

设 $\Sigma$ 上有 $N_\Sigma$ 个 Nyström 节点，则

$$
\eta\in\mathbb C^{2N_\Sigma}.
$$

若 $\Gamma_+$ 上有 $M_+$ 个端口匹配点，右侧保留 $m_+$ 个 outgoing modes，则

$$
B_+^D,B_+^N\in\mathbb C^{M_+\times m_+},
$$

$$
C_+^D,C_+^N\in\mathbb C^{M_+\times 2N_\Sigma}.
$$

左侧类似：若 $\Gamma_-$ 上有 $M_-$ 个端口匹配点，左侧保留 $m_-$ 个 outgoing modes，则

$$
B_-^D,B_-^N\in\mathbb C^{M_-\times m_-},
$$

$$
C_-^D,C_-^N\in\mathbb C^{M_-\times 2N_\Sigma}.
$$

因此 $\mathcal A$ 一般可以是矩形矩阵：

$$
\mathcal A
\in
\mathbb C^{(2N_\Sigma+2M_+ +2M_-)\times (2N_\Sigma+m_+ +m_-)}.
$$

数值上可以继续用

$$
\sigma_{\min}(\mathcal A(\omega,\beta))
$$

检测非平凡解。若希望得到方阵形式，可以进一步通过消去 $a^\pm$、投影到 Bloch trace 子空间的正交补、或选择匹配点与模式数使维度配平来实现；这不是当前 note 的目标。

---

## 9. 当前方案 A 的含义与限制

当前 ansatz 的核心是

$$
u^+(x)
=
D_{\mathrm{QP}}^{(\omega)}[\tau](x)
+
S_{\mathrm{QP}}^{(\omega)}[\sigma](x),
$$

并要求它在左右端口上的 Cauchy data 落入 outgoing Bloch trace 子空间。

因此左右人工边界没有新的 layer-potential density。Bloch modes 只通过

$$
B_\pm^D,
\qquad
B_\pm^N
$$

进入大矩阵。

这与更严格的 finite-core Green representation 不同。后者会把 $\Gamma_\pm$ 也作为外部有限区域边界的一部分，并在 Green representation 中出现端口边界项。当前方案 A 暂时不采用这种写法，而是尽量保持与已有 $A_{\mathrm{QP}}$ Müller 矩阵的兼容性。

---

## 10. 最小实现目标

第一版实现可以按如下模块组织：

1. 沿用已有 `LOCAL_construct_A` 生成 $A_{\mathrm{QP}}$；
2. 新增 off-boundary evaluation，生成 $C_\pm^D$ 与 $C_\pm^N$；
3. 从 Bloch mode 计算模块读取或生成 $B_\pm^D$ 与 $B_\pm^N$；
4. 组装

$$
\mathcal A
=
\begin{bmatrix}
A_{\mathrm{QP}} & 0 & 0\\
C_+^D & -B_+^D & 0\\
C_+^N & -B_+^N & 0\\
C_-^D & 0 & -B_-^D\\
C_-^N & 0 & -B_-^N
\end{bmatrix};
$$

5. 扫描 $\omega$ 或 $(\omega,\beta)$，寻找 $\sigma_{\min}(\mathcal A)$ 的局部极小值。

