对，这个 ODE 原型确实不复杂，而且它正好把你之后需要的几个概念全部暴露出来：

$$
\text{periodic coefficient}
\Longrightarrow
\text{one-cell transfer matrix}
\Longrightarrow
\text{Floquet multiplier}
\Longrightarrow
\text{Bloch mode}
\Longrightarrow
\text{band / gap / decaying mode}.
$$

下面用最标准的一维周期 ODE 来推导。

---

# 1. 一维周期 ODE 模型

考虑

$$
-u''(x)+q(x)u(x)=k^2 u(x),
$$

其中

$$
q(x+d)=q(x).
$$

等价地，也可以写成

$$
u''(x)+a(x;k)u(x)=0,
$$

其中

$$
a(x+d;k)=a(x;k).
$$

这里 $d$ 是周期，$k$ 是谱参数。为了方便，令

$$
U(x)=
\begin{pmatrix}
u(x)\
u'(x)
\end{pmatrix}.
$$

那么二阶方程变成一阶系统

$$
U'(x)=A(x;k)U(x),
$$

其中

$$
A(x;k)
======

\begin{pmatrix}
0 & 1\
-a(x;k) & 0
\end{pmatrix}.
$$

由于 $a(x;k)$ 是周期的，所以

$$
A(x+d;k)=A(x;k).
$$

---

# 2. 一个周期上的 transfer matrix

取基本矩阵解 $\Phi(x;k)$，满足

$$
\Phi'(x;k)=A(x;k)\Phi(x;k),
$$

并归一化为

$$
\Phi(0;k)=I.
$$

那么任意初值 $U(0)$ 对应的解是

$$
U(x)=\Phi(x;k)U(0).
$$

过一个周期之后，

$$
U(d)=\Phi(d;k)U(0).
$$

定义

$$
M(k):=\Phi(d;k).
$$

这个 $2\times 2$ 矩阵就是一个周期的 transfer matrix，也叫 monodromy matrix。

它的含义非常直接：

$$
\boxed{
U(d)=M(k)U(0).
}
$$

也就是说，$M(k)$ 把一个 cell 左边界的 Cauchy data 传到右边界。

---

# 3. Bloch multiplier 的定义

Bloch 解要求过一个周期后只差一个倍数：

$$
u(x+d)=\lambda u(x),
$$

$$
u'(x+d)=\lambda u'(x).
$$

用 $U$ 写就是

$$
U(x+d)=\lambda U(x).
$$

特别地，在 $x=0$ 处，

$$
U(d)=\lambda U(0).
$$

但又有

$$
U(d)=M(k)U(0).
$$

所以非零 Bloch 解存在，当且仅当

$$
M(k)U(0)=\lambda U(0).
$$

也就是说：

$$
\boxed{
\lambda \text{ 是 } M(k) \text{ 的特征值。}
}
$$

这就是 Floquet multiplier。

因此一维周期 ODE 的 Bloch mode 计算，本质上就是求

$$
\boxed{
M(k)v=\lambda v.
}
$$

这里 $v$ 是一个 cell 左边界上的 Cauchy data：

$$
v=
\begin{pmatrix}
u(0)\
u'(0)
\end{pmatrix}.
$$

一旦知道 $v$，整个 cell 内的 mode 就由 ODE 解出来：

$$
U(x)=\Phi(x;k)v.
$$

---

# 4. Bloch 解的具体形式

如果

$$
M(k)v=\lambda v,
$$

令

$$
U_\lambda(x)=\Phi(x;k)v.
$$

那么

$$
U_\lambda(x+d)=\lambda U_\lambda(x).
$$

因此

$$
u_\lambda(x+d)=\lambda u_\lambda(x).
$$

如果写

$$
\lambda=e^{i\alpha d},
$$

那么

$$
u_\lambda(x+d)=e^{i\alpha d}u_\lambda(x).
$$

于是可以把解写成

$$
u_\lambda(x)=e^{i\alpha x}p_\lambda(x),
$$

其中

$$
p_\lambda(x+d)=p_\lambda(x).
$$

这就是最基本的 Bloch 形式：

$$
\boxed{
u(x)=e^{i\alpha x}p(x),
\qquad
p(x+d)=p(x).
}
$$

注意这里的 $p(x)$ 一般不是常数。只有当介质均匀时，$p$ 才退化成常数，Bloch mode 才退化成普通平面波。

---

# 5. 为什么 $\det M(k)=1$

因为

$$
\det \Phi(x;k)
$$

满足 Liouville 公式：

$$
\frac{d}{dx}\det \Phi(x;k)
=

\operatorname{tr} A(x;k)\det\Phi(x;k).
$$

而这里

$$
\operatorname{tr} A(x;k)=0.
$$

所以

$$
\det \Phi(x;k)=\det \Phi(0;k)=1.
$$

因此

$$
\boxed{
\det M(k)=1.
}
$$

所以 $M(k)$ 的两个特征值 $\lambda_+$ 和 $\lambda_-$ 满足

$$
\lambda_+\lambda_-=1.
$$

这非常重要。它说明两个 Floquet multiplier 总是一对互逆的数：

$$
\lambda_-= \lambda_+^{-1}.
$$

---

# 6. 判别式与 band / gap

$M(k)$ 是 $2\times 2$ 矩阵，而且

$$
\det M(k)=1.
$$

因此它的特征方程是

$$
\lambda^2-\operatorname{tr}M(k)\lambda+1=0.
$$

令

$$
\Delta(k):=\operatorname{tr}M(k).
$$

那么

$$
\lambda^2-\Delta(k)\lambda+1=0.
$$

所以

$$
\lambda_{\pm}(k)
================

\frac{\Delta(k)\pm\sqrt{\Delta(k)^2-4}}{2}.
$$

这个 $\Delta(k)$ 通常叫 Floquet discriminant。

现在分情况看。

---

## 情形 A：$|\Delta(k)|<2$

此时

$$
\Delta(k)^2-4<0.
$$

两个 multiplier 是复共轭单位模数：

$$
\lambda_\pm=e^{\pm i\alpha d}.
$$

所以

$$
|\lambda_\pm|=1.
$$

这对应传播 Bloch wave。

物理上说，$k$ 落在 allowed band 中。

---

## 情形 B：$|\Delta(k)|>2$

此时两个 multiplier 是实数，而且互为倒数：

$$
\lambda_+\lambda_-=1.
$$

所以一个满足

$$
|\lambda|<1,
$$

另一个满足

$$
|\lambda|>1.
$$

这时没有传播 Bloch wave，而是一边指数衰减、一边指数增长的 evanescent Bloch mode。

物理上说，$k$ 落在 band gap 中。

---

## 情形 C：$|\Delta(k)|=2$

此时

$$
\lambda=\pm 1.
$$

这是 band edge。这个地方通常比较微妙，因为两个 multiplier 重合，矩阵 $M(k)$ 可能不可对角化。可能出现普通周期/反周期解，也可能出现形如

$$
u(x)=p_1(x)+x p_2(x)
$$

的广义 Floquet 解。

数值上，band edge 通常也是需要小心的地方。

---

# 7. 半无限问题中的出射/衰减条件

现在考虑右半无限周期结构：

$$
x>0.
$$

如果一个 Bloch mode 满足

$$
u(x+d)=\lambda u(x),
$$

那么向右走 $m$ 个周期后，

$$
u(x+md)=\lambda^m u(x).
$$

因此：

* 如果 $|\lambda|<1$，它向 $x\to+\infty$ 衰减；
* 如果 $|\lambda|>1$，它向 $x\to+\infty$ 增长；
* 如果 $|\lambda|=1$，它是传播模式，需要用群速度或能流方向判断是 outgoing 还是 incoming。

所以在右半无限 lead 中，gap 内的自然条件是：

$$
\boxed{
\text{只允许 } |\lambda|<1 \text{ 的 mode。}
}
$$

左半无限结构则相反。若向左走一个周期，相当于乘 $\lambda^{-1}$。所以在左半无限 lead 中，向 $x\to-\infty$ 衰减的 mode 对应

$$
\boxed{
|\lambda|>1.
}
$$

因此：

$$
\begin{cases}
x\to+\infty: & |\lambda|<1,\
x\to-\infty: & |\lambda|>1.
\end{cases}
$$

这个结论以后在二维周期 lead 中仍然成立，只是 $\lambda$ 不再来自 $2\times2$ transfer matrix，而是来自更大的 cell eigenproblem。

---

# 8. 用这个语言写半无限解

假设右侧 lead 的可接受 Bloch multipliers 是

$$
\lambda_1^R,\dots,\lambda_N^R,
$$

对应 Bloch modes 是

$$
\phi_1^R,\dots,\phi_N^R.
$$

那么右侧解写成

$$
u_R(x)=\sum_{\ell=1}^N a_\ell^R \phi_\ell^R(x).
$$

在一维 ODE 的 gap 里，实际上只有一个向右衰减 mode，所以大概就是

$$
u_R(x)=a^R\phi^R(x),
\qquad |\lambda^R|<1.
$$

左侧类似：

$$
u_L(x)=a^L\phi^L(x),
\qquad |\lambda^L|>1.
$$

如果在 band 中，$|\lambda|=1$，则不能靠模长判断，要引入传播方向。对 ODE 来说，如果

$$
\lambda=e^{i\alpha d},
$$

那么 band relation 给出

$$
k=k(\alpha).
$$

群速度大致由

$$
v_g=\frac{dk}{d\alpha}
$$

判断。右侧 outgoing 取 $v_g>0$，左侧 outgoing 取 $v_g<0$。

---

# 9. 为什么这就是二维 periodic lead 的原型

在二维线性缺陷晶体里，固定 $y$ 方向准周期参数 $\beta$ 后，右侧 periodic lead 的 Bloch mode 会满足类似条件：

$$
\phi(x+d,y)=\lambda \phi(x,y),
$$

$$
\partial_x\phi(x+d,y)=\lambda \partial_x\phi(x,y),
$$

再加上

$$
\phi(x,y+L)=e^{i\beta L}\phi(x,y).
$$

这和一维 ODE 完全平行。

一维 ODE 中，cell 边界 data 是二维向量：

$$
\begin{pmatrix}
u(0)\
u'(0)
\end{pmatrix}.
$$

二维问题中，cell 边界 data 变成函数：

$$
\begin{pmatrix}
u|*{\Gamma}\
\partial*\nu u|_{\Gamma}
\end{pmatrix}.
$$

一维中有

$$
M(k)v=\lambda v.
$$

二维中会有一个离散化后的矩阵问题：

$$
M(k,\beta)v=\lambda v.
$$

或者更一般地，是一个 generalized eigenvalue problem：

$$
A(k,\beta)v=\lambda B(k,\beta)v.
$$

但概念完全一致：

$$
\boxed{
\lambda \text{ 控制跨 cell 的增长/衰减/传播，}
}
$$

$$
\boxed{
v \text{ 给出一个周期 cell 边界上的 Cauchy data。}
}
$$

---

# 10. 对你现在最有用的总结

这个 ODE 模型告诉你：

1. **Bloch mode 不需要先手写出来。**
   它是 one-cell transfer matrix 的特征向量生成的解。

2. **Floquet multiplier $\lambda$ 是核心对象。**
   它告诉你跨一个周期后解乘了多少。

3. **$|\lambda|<1$ 和 $|\lambda|>1$ 控制衰减方向。**
   右半无限 lead 取 $|\lambda|<1$，左半无限 lead 取 $|\lambda|>1$。

4. **$|\lambda|=1$ 是传播 mode。**
   这时需要用 group velocity / energy flux 判断 outgoing 方向。

5. **二维线性缺陷晶体只是把 $2\times2$ transfer matrix 换成了一个 cell 上的离散 Bloch eigenproblem。**
   但逻辑结构完全相同。

所以第一步的核心公式可以浓缩为：

$$
\boxed{
M(k)v=\lambda v,
}
$$

$$
\boxed{
u_\lambda(x+d)=\lambda u_\lambda(x),
}
$$

$$
\boxed{
u_\lambda(x)=e^{i\alpha x}p_\lambda(x),\qquad p_\lambda(x+d)=p_\lambda(x).
}
$$

这就是你后面理解 periodic lead mode 的最小模型。
