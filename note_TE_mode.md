# TE mode 的 Müller 表示与矩阵块

本文记录如何把当前 TM 型边界条件改成 TE mode 边界条件，同时保持 hypersingular block 中的超奇异主部可以相互抵消。

本文先使用边界密度 $\tau,\sigma$ 和介电常数 $\epsilon_\pm$ 推导。最后再给出代码实现时更方便的未知量 $q=-\sigma$ 以及折射率 $n$ 的写法。

## 1. TE mode 的边界条件

设介质柱外部为 $\Omega_+$，内部为 $\Omega_-$。外法向 $n$ 始终取为从 $\Omega_-$ 指向 $\Omega_+$ 的方向。设介电常数分别为

$$
\epsilon_+,
\qquad
\epsilon_-.
$$

令

$$
\alpha_+=\frac{1}{\epsilon_+},
\qquad
\alpha_-=\frac{1}{\epsilon_-}.
$$

TE mode 的标量场满足界面条件

$$
\boxed{
 u_{\mathrm{ext}}=u_{\mathrm{int}},
 \qquad
 \alpha_+\partial_n u_{\mathrm{ext}}
 =
 \alpha_-\partial_n u_{\mathrm{int}}.
}
$$

也就是

$$
\boxed{
 u_{\mathrm{ext}}-u_{\mathrm{int}}=0,
 \qquad
 \alpha_+\partial_n u_{\mathrm{ext}}
 -
 \alpha_-\partial_n u_{\mathrm{int}}=0.
}
$$

这里 $u_{\mathrm{ext}}$ 表示从外部区域取到边界的迹，$u_{\mathrm{int}}$ 表示从内部区域取到边界的迹。本文避免使用 $u^\pm$，因为该记号容易和边界极限方向混淆。

## 2. 为什么普通表示会破坏 $T$ 块抵消

在 TM 情形中，法向导数连续条件是

$$
\partial_n u_{\mathrm{ext}}=
\partial_n u_{\mathrm{int}}.
$$

此时如果内外解都使用相同系数的双层势表示，那么 Neumann 行中的 hypersingular block 自然形成

$$
T_+-T_-.
$$

由于两个 hypersingular 算子的最高阶奇异主部相同，上式的差分可以降阶，并可用已经整理好的 Kress 方法实现。

但 TE 情形中 Neumann 条件是加权的。如果仍然使用未缩放的双层势，则 $T$ 块会变成

$$
\alpha_+T_+-\alpha_-T_-.
$$

当 $\epsilon_+\ne\epsilon_-$ 时，通常有 $\alpha_+\ne\alpha_-$，于是超奇异主部不再抵消。因此不能直接把当前的 Neumann 行改成加权形式，而必须先调整 layer potential 表示。

## 3. 使 $T$ 块抵消的解表示

设 $\mathcal S_\pm$ 和 $\mathcal D_\pm$ 分别表示外部和内部波数对应的单层势与双层势。外部使用准周期 Green 函数，内部使用自由空间 Green 函数。

为了让 TE 条件下的 $T$ 块仍然以差分形式出现，应采用如下缩放双层势表示：

$$
\boxed{
 u(x)=
 \begin{cases}
 \epsilon_+\mathcal D_+[\tau](x)+\mathcal S_+[\sigma](x), & x\in\Omega_+,\\[0.4em]
 \epsilon_-\mathcal D_-[\tau](x)+\mathcal S_-[\sigma](x), & x\in\Omega_-.
 \end{cases}
}
$$

这里 $\tau$ 是双层势密度，$\sigma$ 是单层势密度。双层势前的系数不是任意选择的，而是由抵消条件决定的。

更一般地，若写成

$$
 u(x)=
 \begin{cases}
 c_+\mathcal D_+[\tau](x)+\mathcal S_+[\sigma](x), & x\in\Omega_+,\\[0.4em]
 c_-\mathcal D_-[\tau](x)+\mathcal S_-[\sigma](x), & x\in\Omega_-,
 \end{cases}
$$

则加权 Neumann 条件中的 hypersingular 部分为

$$
\alpha_+c_+T_+[\tau]-\alpha_-c_-T_-[\tau].
$$

要使超奇异主部抵消，需要

$$
\boxed{
\alpha_+c_+=\alpha_-c_-.
}
$$

最自然的选择是令公共系数为 $1$，即

$$
\boxed{
 c_+=\frac{1}{\alpha_+}=\epsilon_+,
 \qquad
 c_-=\frac{1}{\alpha_-}=\epsilon_-.
}
$$

这就得到上面的 TE Müller 表示。

## 4. 跳跃关系

下面使用外法向 $n$，方向从 $\Omega_-$ 指向 $\Omega_+$。

双层势的 Dirichlet 迹满足

$$
\mathcal D_+[\tau]_{\mathrm{ext}}
=
\left(\frac{1}{2}I+D_+\right)\tau,
\qquad
\mathcal D_-[\tau]_{\mathrm{int}}
=
\left(-\frac{1}{2}I+D_-\right)\tau.
$$

单层势的 Dirichlet 迹连续，因此边界上只出现 $S_+\sigma$ 和 $S_-\sigma$。

双层势的法向导数给出 hypersingular 算子

$$
\partial_n\mathcal D_+[\tau]_{\mathrm{ext}}=T_+\tau,
\qquad
\partial_n\mathcal D_-[\tau]_{\mathrm{int}}=T_-\tau.
$$

单层势的法向导数满足

$$
\partial_n\mathcal S_+[\sigma]_{\mathrm{ext}}
=
\left(-\frac{1}{2}I+D_+^*\right)\sigma,
\qquad
\partial_n\mathcal S_-[\sigma]_{\mathrm{int}}
=
\left(\frac{1}{2}I+D_-^*\right)\sigma.
$$

## 5. 用 $\tau,\sigma$ 得到的 TE 矩阵

将表示式代入 Dirichlet 连续条件

$$
u_{\mathrm{ext}}-u_{\mathrm{int}}=0
$$

得到第一行：

$$
\left[
\frac{\epsilon_+ + \epsilon_-}{2}I
+
\epsilon_+D_+
-
\epsilon_-D_-,
\quad
S_+-S_-
\right]
\begin{bmatrix}
\tau\\
\sigma
\end{bmatrix}
=0.
$$

将表示式代入加权 Neumann 连续条件

$$
\alpha_+\partial_n u_{\mathrm{ext}}
-
\alpha_-\partial_n u_{\mathrm{int}}=0
$$

得到第二行：

$$
\left[
T_+-T_-,
\quad
-\frac{\alpha_+ + \alpha_-}{2}I
+
\alpha_+D_+^*
-
\alpha_-D_-^*
\right]
\begin{bmatrix}
\tau\\
\sigma
\end{bmatrix}
=0.
$$

因此，以 $\begin{bmatrix}\tau&\sigma\end{bmatrix}^T$ 为未知向量时，TE Müller 矩阵为

$$
\boxed{
A_{\mathrm{TE}}^{(\tau,\sigma)}
=
\begin{bmatrix}
\dfrac{\epsilon_+ + \epsilon_-}{2}I
+
\epsilon_+D_+
-
\epsilon_-D_-
&
S_+-S_-
\\[1.0em]
T_+-T_-
&
-\dfrac{\alpha_+ + \alpha_-}{2}I
+
\alpha_+D_+^*
-
\alpha_-D_-^*
\end{bmatrix}.
}
$$

最重要的是，$T$ 块为

$$
\boxed{
T_+-T_-.
}
$$

这与 TM 情形中已经验证过的 hypersingular 差分结构相同，所以仍然可以使用 Kress 的 $A+BD$ 离散。

## 6. 外部 QP 与内部自由空间的具体含义

在当前一维周期波导单胞问题中，外部算子使用准周期 Green 函数，内部算子使用自由空间 Green 函数。记

$$
k_+=\omega,
\qquad
k_-=n\omega.
$$

则

$$
D_+=D_{\mathrm{QP}}^{(\omega)},
\qquad
S_+=S_{\mathrm{QP}}^{(\omega)},
\qquad
T_+=T_{\mathrm{QP}}^{(\omega)},
$$

以及

$$
D_-=D^{(n\omega)},
\qquad
S_-=S^{(n\omega)},
\qquad
T_-=T^{(n\omega)}.
$$

代入后，$\tau,\sigma$ 版本的矩阵为

$$
\boxed{
A_{\mathrm{TE}}^{(\tau,\sigma)}
=
\begin{bmatrix}
\dfrac{\epsilon_+ + \epsilon_-}{2}I
+
\epsilon_+D_{\mathrm{QP}}^{(\omega)}
-
\epsilon_-D^{(n\omega)}
&
S_{\mathrm{QP}}^{(\omega)}-S^{(n\omega)}
\\[1.0em]
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}
&
-\dfrac{\alpha_+ + \alpha_-}{2}I
+
\alpha_+D_{\mathrm{QP}}^{(\omega)*}
-
\alpha_-D^{(n\omega)*}
\end{bmatrix}.
}
$$

这里 $\alpha_\pm=1/\epsilon_\pm$。

## 7. 转换到代码使用的未知量 $q=-\sigma$

当前代码和旧笔记中常用的未知向量是

$$
\eta=
\begin{bmatrix}
\tau\\
q
\end{bmatrix},
\qquad
q=-\sigma.
$$

因此

$$
\sigma=-q.
$$

把 $\sigma=-q$ 代入上面的表示式，得到代码中更方便的解表示：

$$
\boxed{
 u(x)=
 \begin{cases}
 \epsilon_+\mathcal D_+[\tau](x)-\mathcal S_+[q](x), & x\in\Omega_+,\\[0.4em]
 \epsilon_-\mathcal D_-[\tau](x)-\mathcal S_-[q](x), & x\in\Omega_-.
 \end{cases}
}
$$

对应矩阵的第二列整体变号。因此，以 $\begin{bmatrix}\tau&q\end{bmatrix}^T$ 为未知向量时，TE Müller 矩阵为

$$
\boxed{
A_{\mathrm{TE}}^{(\tau,q)}
=
\begin{bmatrix}
\dfrac{\epsilon_+ + \epsilon_-}{2}I
+
\epsilon_+D_+
-
\epsilon_-D_-
&
S_--S_+
\\[1.0em]
T_+-T_-
&
\dfrac{\alpha_+ + \alpha_-}{2}I
+
\alpha_-D_-^*
-
\alpha_+D_+^*
\end{bmatrix}.
}
$$

在 QP 单胞问题中，这就是

$$
\boxed{
A_{\mathrm{TE}}^{(\tau,q)}
=
\begin{bmatrix}
\dfrac{\epsilon_+ + \epsilon_-}{2}I
+
\epsilon_+D_{\mathrm{QP}}^{(\omega)}
-
\epsilon_-D^{(n\omega)}
&
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}
\\[1.0em]
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}
&
\dfrac{\alpha_+ + \alpha_-}{2}I
+
\alpha_-D^{(n\omega)*}
-
\alpha_+D_{\mathrm{QP}}^{(\omega)*}
\end{bmatrix}.
}
$$

这就是实际代码应采用的 block convention。

## 8. 用折射率 $n$ 写成代码公式

若外部背景介电常数为

$$
\epsilon_+=1,
$$

内部介质柱折射率为 $n$，则

$$
\epsilon_-=n^2,
\qquad
\alpha_+=1,
\qquad
\alpha_-=\frac{1}{n^2}.
$$

代码中使用 $q=-\sigma$ 时，解表示为

$$
\boxed{
 u(x)=
 \begin{cases}
 \mathcal D_{\mathrm{QP}}^{(\omega)}[\tau](x)
 -
 \mathcal S_{\mathrm{QP}}^{(\omega)}[q](x), & x\in\Omega_+,\\[0.4em]
 n^2\mathcal D^{(n\omega)}[\tau](x)
 -
 \mathcal S^{(n\omega)}[q](x), & x\in\Omega_-.
 \end{cases}
}
$$

对应矩阵块为

$$
\boxed{
A_{11}^{\mathrm{TE}}
=
\frac{1+n^2}{2}I
+
D_{\mathrm{QP}}^{(\omega)}
-
n^2D^{(n\omega)}.
}
$$

$$
\boxed{
A_{12}^{\mathrm{TE}}
=
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}.
}
$$

$$
\boxed{
A_{21}^{\mathrm{TE}}
=
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}.
}
$$

$$
\boxed{
A_{22}^{\mathrm{TE}}
=
\frac{1+1/n^2}{2}I
+
\frac{1}{n^2}D^{(n\omega)*}
-
D_{\mathrm{QP}}^{(\omega)*}.
}
$$

其中 $A_{21}^{\mathrm{TE}}$ 仍然使用已经验证过的 Kress $T$-difference 离散。也就是说，TE mode 修改不会改变 $T$ 块的核心实现，只改变 $A_{11}$ 和 $A_{22}$ 中双层势及伴随双层势的系数，以及对应的 identity 系数。

## 9. 实现注意事项

1. 不要把 $T$ 块改成

$$
\alpha_+T_{\mathrm{QP}}^{(\omega)}-
\alpha_-T^{(n\omega)}.
$$

这种写法会破坏 hypersingular 主部抵消。

2. 正确的 TE 表示通过缩放双层势保证

$$
\alpha_+\epsilon_+=1,
\qquad
\alpha_-\epsilon_-=1,
$$

从而使 Neumann 行中的 $T$ 块保持为

$$
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}.
$$

3. 在代码未知量 $\eta=\begin{bmatrix}\tau&q\end{bmatrix}^T$ 下，$S$ 块仍然是

$$
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}.
$$

4. $D$ 块和 $D^*$ 块需要分别乘上 $\epsilon_\pm$ 和 $\alpha_\pm$。

5. identity 项不再是两个单位矩阵，而是

$$
\frac{\epsilon_+ + \epsilon_-}{2}I
$$

和

$$
\frac{\alpha_+ + \alpha_-}{2}I.
$$

6. 当 $\epsilon_+=\epsilon_-$ 时，TE 矩阵退化回未加权情形；当 $\epsilon_+=1$ 且 $\epsilon_-=n^2$ 时，使用第 8 节的代码公式。
