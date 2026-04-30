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