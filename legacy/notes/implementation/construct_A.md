# Note on `LOCAL_construct_A`

This note records the block-matrix convention used in the construction of `LOCAL_construct_A`.

## 1. Target operator

The matrix is built to represent the operator in equation (20)[Barnett2010]:

$$
\begin{bmatrix}
u^+ - u^- \\
u_n^+ - u_n^-
\end{bmatrix}
=
\left(
\begin{bmatrix}
I & 0 \\
0 & I
\end{bmatrix}
+
\begin{bmatrix}
D_{\mathrm{QP}}^{(\omega)} - D^{(n\omega)} &
S^{(n\omega)} - S_{\mathrm{QP}}^{(\omega)} \\
T_{\mathrm{QP}}^{(\omega)} - T^{(n\omega)} &
D^{(n\omega)*} - D_{\mathrm{QP}}^{(\omega)*}
\end{bmatrix}
\right)
\begin{bmatrix}
\tau \\
-\sigma
\end{bmatrix}
=: A_{\mathrm{QP}} \eta.
$$

Thus the unknown vector is

$$
\eta =
\begin{bmatrix}
\tau \\
-\sigma
\end{bmatrix}.
$$

This sign convention is essential when matching the code blocks with the theoretical operator.

## 2. Kernel-gradient convention in code

In the code, the pairwise differences are formed as

$$
x_{\mathrm{diff}} = x_i - x_j, \qquad
y_{\mathrm{diff}} = y_i - y_j,
$$

so the computed gradient corresponds to differentiation with respect to the **target** variable:

$$
\nabla_x G(x_i,x_j).
$$

Hence

$$
\partial_{n_x} G(x,y) = \nabla_x G(x,y)\cdot n_x,
$$

while the source-normal derivative satisfies

$$
\partial_{n_y} G(x,y) = \nabla_y G(x,y)\cdot n_y
= -\,\nabla_x G(x,y)\cdot n_y.
$$

Therefore, when the code contracts a target-gradient with the **source** normal, the result corresponds to

$$
-\partial_{n_y} G(x,y),
$$

not to $$+\partial_{n_y} G(x,y).$$

## 3. Block interpretation

The four blocks in `LOCAL_construct_A` should be interpreted relative to the operator

$$
\begin{bmatrix}
D_{\mathrm{QP}}^{(\omega)} - D^{(n\omega)} &
S^{(n\omega)} - S_{\mathrm{QP}}^{(\omega)} \\
T_{\mathrm{QP}}^{(\omega)} - T^{(n\omega)} &
D^{(n\omega)*} - D_{\mathrm{QP}}^{(\omega)*}
\end{bmatrix},
$$

together with the choice of unknown vector

$$
\begin{bmatrix}
\tau \\
-\sigma
\end{bmatrix}.
$$

In particular, the apparent sign issue between the `A11` and `A22` implementations must be checked against:

1. the fact that the code uses $$\nabla_x G$$,
2. the identity $$\nabla_y G = -\nabla_x G$$,
3. the block convention in equation (20),
4. the use of $$-\sigma$$ rather than $$\sigma$$ in the unknown vector.

## 4. Practical rule

When reading or modifying `LOCAL_construct_A`, do **not** infer signs only from the formulas for $$\partial_{n_x} G$$ and $$\partial_{n_y} G$$ in isolation. Always compare the code against the full block system in equation (20).

## 5. Diagonal entries of the non-\(T\) blocks

This section records the diagonal entries for all blocks except the hypersingular block.
The hypersingular block

$$
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}
$$

is treated separately; see `note_Kress.md`.

Throughout this section, write

$$
k_{\mathrm{out}}=\omega,\qquad k_{\mathrm{in}}=n\omega,
$$

and

$$
\Phi_k(x,y)=\frac{\mathrm{i}}{4}H_0^{(1)}(k|x-y|).
$$

For the quasi-periodic Green's function, assume the local representation

$$
G_{\mathrm{QP}}^{(\omega)}(x,y)
=
\Phi_{k_{\mathrm{out}}}(x,y)+P_{\mathrm{QP}}^{(\omega)}(x,y),
$$

where \(P_{\mathrm{QP}}^{(\omega)}\) is smooth in both variables near the diagonal.
If no proxy or smooth correction is present, set

$$
P_{\mathrm{QP}}^{(\omega)}=0.
$$

Let

$$
z=z(t),\qquad s(t):=|z'(t)|,
$$

and for a counter-clockwise parametrization let the outward non-unit normal be

$$
\nu(t)=n(t)s(t)=(z_2'(t),-z_1'(t)).
$$

Define the curvature-type scalar

$$
\chi(t):=
\frac{z_1'(t)z_2''(t)-z_2'(t)z_1''(t)}{|z'(t)|^2}.
$$

For the unit circle with counter-clockwise orientation, \(\chi(t)=1\).

---

### 5.1 Bare free-space diagonal limits for \(D\) and \(D^*\)

Use the bare source-normal double-layer kernel

$$
D^{(k)}(t,\tau)
=
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_\tau}\,|z'(\tau)|
$$

and the bare adjoint double-layer kernel

$$
D^{(k)*}(t,\tau)
=
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_t}\,|z'(\tau)|.
$$

Their diagonal limits are independent of \(k\):

$$
\boxed{
D^{(k)}(t,t)=D^{(k)*}(t,t)
=
-\frac{1}{4\pi}\chi(t).
}
$$

Equivalently,

$$
D^{(k)}(t,t)=D^{(k)*}(t,t)
=
-\frac{1}{4\pi}
\frac{z_1'(t)z_2''(t)-z_2'(t)z_1''(t)}
{|z'(t)|^2}.
$$

Therefore, in the differences

$$
D_{\mathrm{QP}}^{(\omega)}-D^{(n\omega)}
$$

and

$$
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*},
$$

the singular free-space diagonal limits cancel. Only the smooth quasi-periodic correction contributes to the diagonal.

---

### 5.2 Diagonal entry of the \(A_{11}\) block

The operator-level \(A_{11}\) block is

$$
\mathcal A_{11}
=
D_{\mathrm{QP}}^{(\omega)}-D^{(n\omega)}.
$$

Using

$$
G_{\mathrm{QP}}^{(\omega)}
=
\Phi_{k_{\mathrm{out}}}+P_{\mathrm{QP}}^{(\omega)},
$$

the free-space diagonal limits of \(D^{(k_{\mathrm{out}})}\) and \(D^{(k_{\mathrm{in}})}\) cancel. Hence

$$
\boxed{
(\mathcal A_{11})_{ii}
=
\frac{\partial P_{\mathrm{QP}}^{(\omega)}(z_i,z_i)}{\partial n_y}\,s_i.
}
$$

Here

$$
z_i=z(t_i),\qquad s_i=|z'(t_i)|.
$$

If \(P_{\mathrm{QP}}^{(\omega)}=0\), then

$$
\boxed{
(\mathcal A_{11})_{ii}=0.
}
$$

The full matrix block includes the identity term from

$$
I+
\begin{bmatrix}
\mathcal A_{11} & \mathcal A_{12}\\
\mathcal A_{21} & \mathcal A_{22}
\end{bmatrix}.
$$

Therefore, if the code is assembling the full matrix directly,

$$
\boxed{
(A_{11})_{ii}=1+(\mathcal A_{11})_{ii}.
}
$$

If the code first assembles only the operator block and adds identity later, then store only \((\mathcal A_{11})_{ii}\).

---

### 5.3 Diagonal entry of the \(A_{12}\) block

The operator-level \(A_{12}\) block is

$$
\mathcal A_{12}
=
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}.
$$

Use the bare single-layer parametrized kernel

$$
S^{(k)}(t,\tau)
=
\Phi_k(z(t),z(\tau))\,|z'(\tau)|.
$$

It has the Kress split

$$
S^{(k)}(t,\tau)
=
S_1^{(k)}(t,\tau)
\log\left(4\sin^2\frac{t-\tau}{2}\right)
+
S_2^{(k)}(t,\tau),
$$

with

$$
S_1^{(k)}(t,\tau)
=
-\frac{1}{4\pi}J_0(k|z(t)-z(\tau)|)|z'(\tau)|.
$$

The diagonal values are

$$
\boxed{
S_1^{(k)}(t,t)
=
-\frac{1}{4\pi}|z'(t)|
}
$$

and

$$
\boxed{
S_2^{(k)}(t,t)
=
\frac{1}{2}
\left\{
\frac{\mathrm{i}}{2}
-\frac{C}{\pi}
-\frac{1}{2\pi}
\log\left(\frac{k^2}{4}|z'(t)|^2\right)
\right\}
|z'(t)|.
}
$$

Here \(C\) is Euler's constant.

Since the logarithmic singular coefficient has the same diagonal limit for all \(k\), the difference

$$
S^{(k_{\mathrm{in}})}-S^{(k_{\mathrm{out}})}
$$

is continuous on the diagonal, and its diagonal value is

$$
S_2^{(k_{\mathrm{in}})}(t,t)-S_2^{(k_{\mathrm{out}})}(t,t).
$$

Thus, including the smooth quasi-periodic correction,

$$
S_{\mathrm{QP}}^{(\omega)}(t,\tau)
=
S^{(k_{\mathrm{out}})}(t,\tau)
+
P_{\mathrm{QP}}^{(\omega)}(z(t),z(\tau))\,|z'(\tau)|,
$$

we obtain

$$
\boxed{
(\mathcal A_{12})_{ii}
=
S_2^{(k_{\mathrm{in}})}(t_i,t_i)
-
S_2^{(k_{\mathrm{out}})}(t_i,t_i)
-
P_{\mathrm{QP}}^{(\omega)}(z_i,z_i)\,s_i.
}
$$

Equivalently, when \(P_{\mathrm{QP}}^{(\omega)}=0\),

$$
\boxed{
(\mathcal A_{12})_{ii}
=
-\frac{s_i}{2\pi}
\log\frac{k_{\mathrm{in}}}{k_{\mathrm{out}}}.
}
$$

Since \(k_{\mathrm{in}}=n\omega\) and \(k_{\mathrm{out}}=\omega\), this becomes

$$
\boxed{
(\mathcal A_{12})_{ii}
=
-\frac{s_i}{2\pi}\log n
\qquad
(P_{\mathrm{QP}}^{(\omega)}=0).
}
$$

There is no identity contribution in the \(A_{12}\) block.

---

### 5.4 Diagonal entry of the \(A_{22}\) block

The operator-level \(A_{22}\) block is

$$
\mathcal A_{22}
=
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*}.
$$

Again, the free-space diagonal limits of

$$
D^{(k_{\mathrm{in}})*}
\quad\text{and}\quad
D^{(k_{\mathrm{out}})*}
$$

are identical and therefore cancel. The only remaining diagonal contribution comes from the smooth quasi-periodic correction:

$$
\boxed{
(\mathcal A_{22})_{ii}
=
-
\frac{\partial P_{\mathrm{QP}}^{(\omega)}(z_i,z_i)}{\partial n_x}\,s_i.
}
$$

If \(P_{\mathrm{QP}}^{(\omega)}=0\), then

$$
\boxed{
(\mathcal A_{22})_{ii}=0.
}
$$

If the code is assembling the full matrix directly, then the identity contribution gives

$$
\boxed{
(A_{22})_{ii}=1+(\mathcal A_{22})_{ii}.
}
$$

If the code first assembles only the operator block and adds identity later, then store only \((\mathcal A_{22})_{ii}\).

---

### 5.5 Relation to the target-gradient convention in code

The formulas above are written at the operator level.

However, the code forms pairwise differences as

$$
x_{\mathrm{diff}}=x_i-x_j,
\qquad
y_{\mathrm{diff}}=y_i-y_j,
$$

so the computed gradient is

$$
\nabla_x G(x_i,x_j).
$$

Therefore,

$$
\partial_{n_y}G(x,y)
=
\nabla_yG(x,y)\cdot n_y
=
-\nabla_xG(x,y)\cdot n_y.
$$

Thus, if the code evaluates a smooth correction by contracting the target gradient with the source normal,

$$
Q_y(t_i,t_j)
:=
\nabla_x P_{\mathrm{QP}}^{(\omega)}(z_i,z_j)
\cdot n_j\,s_j,
$$

then this quantity equals

$$
Q_y(t_i,t_j)
=
-\frac{\partial P_{\mathrm{QP}}^{(\omega)}(z_i,z_j)}{\partial n_y}\,s_j.
$$

Consequently, the \(A_{11}\) diagonal should be inserted as

$$
\boxed{
(\mathcal A_{11})_{ii}
=
-Q_y(t_i,t_i)
}
$$

if the code uses this target-gradient/source-normal contraction.

For the adjoint block, if the code evaluates

$$
Q_x(t_i,t_j)
:=
\nabla_x P_{\mathrm{QP}}^{(\omega)}(z_i,z_j)
\cdot n_i\,s_j,
$$

then

$$
Q_x(t_i,t_j)
=
\frac{\partial P_{\mathrm{QP}}^{(\omega)}(z_i,z_j)}{\partial n_x}\,s_j.
$$

Therefore,

$$
\boxed{
(\mathcal A_{22})_{ii}
=
-Q_x(t_i,t_i).
}
$$

This is consistent with the block convention

$$
\mathcal A_{22}
=
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*}.
$$

---

### 5.6 Summary of non-\(T\) diagonal entries

At the operator-block level,

$$
\boxed{
(\mathcal A_{11})_{ii}
=
\frac{\partial P_{\mathrm{QP}}^{(\omega)}(z_i,z_i)}{\partial n_y}\,s_i,
}
$$

$$
\boxed{
(\mathcal A_{12})_{ii}
=
S_2^{(k_{\mathrm{in}})}(t_i,t_i)
-
S_2^{(k_{\mathrm{out}})}(t_i,t_i)
-
P_{\mathrm{QP}}^{(\omega)}(z_i,z_i)\,s_i,
}
$$

$$
\boxed{
(\mathcal A_{22})_{ii}
=
-
\frac{\partial P_{\mathrm{QP}}^{(\omega)}(z_i,z_i)}{\partial n_x}\,s_i.
}
$$

The full matrix adds identity only to the diagonal blocks \(A_{11}\) and \(A_{22}\):

$$
\boxed{
(A_{11})_{ii}=1+(\mathcal A_{11})_{ii},
\qquad
(A_{22})_{ii}=1+(\mathcal A_{22})_{ii}.
}
$$

There is no identity contribution in \(A_{12}\) or \(A_{21}\).

The \(A_{21}\) block is the hypersingular difference

$$
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)},
$$

and should be implemented using the \(A+BD\) construction recorded in `note_Kress.md`.

## 6. 全 Kress 离散下的矩阵 \(A\) 四个块组装公式

本节给出当前推荐的可操作组装公式：矩阵 \(A\) 的四个积分算子块全部采用 Kress split 离散。**不要使用前面第 5 节的逐块解析对角极限替换**；所有对角项都由对应核的 Kress split 中 \(X_2(t_i,t_i)\) 或光滑修正项直接填入。

### 6.1 公共记号

令
$$
k_{\mathrm{out}}=\omega,\qquad
k_{\mathrm{in}}=n\omega,
$$
并取偶数个节点
$$
t_j=\frac{2\pi j}{N},\qquad j=0,\dots,N-1,\qquad h=\frac{2\pi}{N}.
$$
记
$$
z_j=z(t_j),\qquad s_j=|z'(t_j)|,\qquad
n_j=\frac{(z_2'(t_j),-z_1'(t_j))}{s_j}.
$$

准周期 Green 函数写成
$$
G_{\mathrm{QP}}^{(k_{\mathrm{out}})}(x,y)
=
\Phi_{k_{\mathrm{out}}}(x,y)+P(x,y),
$$
其中 \(P\) 是光滑 proxy 修正项。

若一个核有 split
$$
X^{(k)}(t,\tau)=X_1^{(k)}(t,\tau)g(t,\tau)+X_2^{(k)}(t,\tau),
\qquad
g(t,\tau)=\log\!\left(4\sin^2\frac{t-\tau}{2}\right),
$$
则定义 Kress 填充算子
$$
\boxed{
\mathcal K_N[X^{(k)}]_{ij}
=
R_{ij}^{(N)}X_1^{(k)}(t_i,t_j)
+hX_2^{(k)}(t_i,t_j).
}
$$
这里 \(R_{ij}^{(N)}\) 是已经包含 \(2\pi/N\) 缩放的 Kress 权重。

以下 \(M,L,L^*,N\) 核及其 \(X_1,X_2\) 的定义全部采用 `note_Kress.md` 中“本项目采用的 \(M,N,L\) 核记号”一节。

### 6.2 \(A_{11}\) 块

块约定为
$$
\mathcal A_{11}
=
D_{\mathrm{QP}}^{(k_{\mathrm{out}})}-D^{(k_{\mathrm{in}})}
=
\left(D^{(k_{\mathrm{out}})}-D^{(k_{\mathrm{in}})}\right)+D^P.
$$
使用 \(L\) 核组装自由空间部分：
$$
\boxed{
(A_{11}^{\mathrm{fs}})_{ij}
=
\mathcal K_N[L^{(k_{\mathrm{out}})}]_{ij}
-
\mathcal K_N[L^{(k_{\mathrm{in}})}]_{ij}.
}
$$
光滑 proxy 项用普通梯形公式：
$$
\boxed{
(A_{11}^{P})_{ij}
=
h\,\frac{\partial P(z_i,z_j)}{\partial n_y}\,s_j.
}
$$
因此
$$
\boxed{
\mathcal A_{11}=A_{11}^{\mathrm{fs}}+A_{11}^{P}.
}
$$

### 6.3 \(A_{12}\) 块

块约定为
$$
\mathcal A_{12}
=
S^{(k_{\mathrm{in}})}-S_{\mathrm{QP}}^{(k_{\mathrm{out}})}
=
\left(S^{(k_{\mathrm{in}})}-S^{(k_{\mathrm{out}})}\right)-S^P.
$$
使用 \(M\) 核组装自由空间部分：
$$
\boxed{
(A_{12}^{\mathrm{fs}})_{ij}
=
\mathcal K_N[M^{(k_{\mathrm{in}})}]_{ij}
-
\mathcal K_N[M^{(k_{\mathrm{out}})}]_{ij}.
}
$$
光滑 proxy 项为
$$
\boxed{
(A_{12}^{P})_{ij}
=
-h\,P(z_i,z_j)\,s_j.
}
$$
因此
$$
\boxed{
\mathcal A_{12}=A_{12}^{\mathrm{fs}}+A_{12}^{P}.
}
$$

### 6.4 \(A_{21}\) 块

块约定为
$$
\mathcal A_{21}
=
T_{\mathrm{QP}}^{(k_{\mathrm{out}})}-T^{(k_{\mathrm{in}})}
=
\left(T^{(k_{\mathrm{out}})}-T^{(k_{\mathrm{in}})}\right)+T^P.
$$

自由空间 \(T\)-差分用 \(A+BD\) 结构。先定义
$$
\Delta M_\ell
=
k_{\mathrm{out}}^2M_\ell^{(k_{\mathrm{out}})}
-
k_{\mathrm{in}}^2M_\ell^{(k_{\mathrm{in}})},
\qquad \ell=1,2,
$$
以及
$$
\Delta N_\ell
=
N_\ell^{(k_{\mathrm{out}})}
-
N_\ell^{(k_{\mathrm{in}})},
\qquad \ell=1,2.
$$
记
$$
G_{ij}=\frac{z'(t_i)\cdot z'(t_j)}{s_i s_j}.
$$
则
$$
\boxed{
A^{T}_{ij}
=
\left[
R_{ij}^{(N)}\Delta M_1(t_i,t_j)
+h\Delta M_2(t_i,t_j)
\right]G_{ij},
}
$$
$$
\boxed{
B^{T}_{ij}
=
\frac{1}{s_i}
\left[
R_{ij}^{(N)}\Delta N_1(t_i,t_j)
+h\Delta N_2(t_i,t_j)
\right].
}
$$
令 \(D_t\) 为 even-node trigonometric differentiation matrix，则
$$
\boxed{
A_{21}^{\mathrm{fs}}=A^T+B^T D_t.
}
$$

光滑 proxy 项直接用 mixed Hessian：
$$
\boxed{
(A_{21}^{P})_{ij}
=
h\,
\frac{\partial^2 P(z_i,z_j)}
{\partial n_x\partial n_y}
s_j.
}
$$
等价地，若已有 helper 给出 \(H_{xy}P(z_i,z_j)\)，则
$$
\frac{\partial^2 P(z_i,z_j)}
{\partial n_x\partial n_y}
=
n_i^T H_{xy}P(z_i,z_j)n_j.
$$
因此
$$
\boxed{
\mathcal A_{21}=A_{21}^{\mathrm{fs}}+A_{21}^{P}.
}
$$

### 6.5 \(A_{22}\) 块

块约定为
$$
\mathcal A_{22}
=
D^{(k_{\mathrm{in}})*}-D_{\mathrm{QP}}^{(k_{\mathrm{out}})*}
=
\left(D^{(k_{\mathrm{in}})*}-D^{(k_{\mathrm{out}})*}\right)-D^{P*}.
$$
使用 \(L^*\) 核组装自由空间部分：
$$
\boxed{
(A_{22}^{\mathrm{fs}})_{ij}
=
\mathcal K_N[L^{(k_{\mathrm{in}})*}]_{ij}
-
\mathcal K_N[L^{(k_{\mathrm{out}})*}]_{ij}.
}
$$
光滑 proxy 项为
$$
\boxed{
(A_{22}^{P})_{ij}
=
-h\,\frac{\partial P(z_i,z_j)}{\partial n_x}\,s_j.
}
$$
因此
$$
\boxed{
\mathcal A_{22}=A_{22}^{\mathrm{fs}}+A_{22}^{P}.
}
$$

### 6.6 最终矩阵

最终矩阵按块写成
$$
\boxed{
A_{\mathrm{QP}}
=
\begin{bmatrix}
I & 0\\
0 & I
\end{bmatrix}
+
\begin{bmatrix}
\mathcal A_{11} & \mathcal A_{12}\\
\mathcal A_{21} & \mathcal A_{22}
\end{bmatrix}.
}
$$
单位矩阵只加在 \(A_{11}\) 和 \(A_{22}\) 的最终 full matrix 对角块上；四个积分算子块本身都按上面的 Kress/梯形公式直接填充。
