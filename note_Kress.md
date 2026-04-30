## The Kress quadrature

Fix the period $T=2\pi$ and take $N$ to be even. The nodes are
$$
x_j=\frac{2\pi j}{N},\qquad j=1,\ldots,N.
$$

To derive the scheme of Kress, originally due to Martensen--Kussmaul, note the Fourier series
$$
g(s)=\log\left(4\sin^2\frac{s}{2}\right)
\quad\Longleftrightarrow\quad
g_n=
\begin{cases}
0, & n=0,\\
-1/|n|, & n\ne 0.
\end{cases}
$$

Translating $g$ by a displacement $t\in\mathbb{R}$ corresponds to multiplication of $g_n$ by $e^{-int}$. Substituting this displaced series into the product-quadrature weights and simplifying gives
$$
\int_0^{2\pi}
\log\left(4\sin^2\frac{t-s}{2}\right)\phi(s)\,ds
\approx
\sum_{j=1}^N R_j^{(N/2)}(t)\phi(x_j),
$$
where the weights, which depend on the target location $t$, are
$$
R_j^{(N/2)}(t)
=
-\frac{4\pi}{N}
\left[
\sum_{n=1}^{N/2-1}\frac{1}{n}\cos n(x_j-t)
+\frac{1}{N}\cos\frac{N}{2}(x_j-t)
\right],
\qquad j=1,\ldots,N.
$$

When a smooth function is also present, use the periodic trapezoid rule for it, to get
$$
\int_0^{2\pi}
\left[
\log\left(4\sin^2\frac{t-s}{2}\right)\phi(s)+\psi(s)
\right]\,ds
\approx
\sum_{j=1}^N R_j^{(N/2)}(t)\phi(x_j)
+\frac{2\pi}{N}\sum_{j=1}^N \psi(x_j).
$$

Assuming the separation into $\phi$ and $\psi$ is known, this gives a high-order accurate quadrature; in fact, for $\phi$ and $\psi$ analytic, it is exponentially convergent.

## A Nystrom scheme

Use the above Kress quadrature to approximate the integral where the kernel has the form
$$
k(x,x')=
\phi(x,x')\log\left(4\sin^2\frac{x-x'}{2}\right)+\psi(x,x'),
$$
with $T=2\pi$, and where the functions $\phi(x,x')$ and $\psi(x,x')$ are separately known. Applying the Kress quadrature, with $h=2\pi/N$, gives
$$
\int_0^{2\pi} k(x_i,x')\sigma(x')\,dx'
\approx
\sum_{j=1}^N
R_j^{(N/2)}(x_i)\phi(x_i,x_j)\sigma(x_j)
+h\sum_{j=1}^N \psi(x_i,x_j)\sigma(x_j).
$$

Using the symbol
$$
R_j^{(N/2)}:=R_j^{(N/2)}(0),
$$
and noticing that $R_j^{(N/2)}(x_i)$ depends only on $|i-j|$, the entries of the coefficient matrix $A$ are
$$
a_{i,j}
=
R_{|i-j|}^{(N/2)}\phi(x_i,x_j)
+h\psi(x_i,x_j).
$$

Note that $R_{|i-j|}^{(N/2)}$ is a dense circulant matrix, and all $N^2$ elements differ from the standard Nystrom matrix. Since $\phi$ and $\psi$ do not usually have fast potential-theory based algorithms to apply them, the Kress scheme is not FMM-compatible.

## 算子T的等价形式

定义
$$
\boxed{
(T_k\mu)(x)=\frac{\partial}{\partial n_x}\int_\Gamma
\frac{\partial \Phi_k(x,y)}{\partial n_y}\mu(y),ds_y
}
$$

则有公式
$$
\boxed{
T_k\mu =

k^2\int_\Gamma \Phi_k(x,y)\,(n_x\!\cdot n_y)\,\mu(y)\,ds_y
+
\frac{d}{ds_x}\int_\Gamma \Phi_k(x,y)\,\frac{d\mu}{ds_y}(y)\,ds_y
}
$$

因此两个波数相减时，

$$
\boxed{
(T_{k_1}-T_{k_2})\mu
=

\int_\Gamma \Big(k_1^2\Phi_{k_1}(x,y)-k_2^2\Phi_{k_2}(x,y)\Big)
(n_x\!\cdot n_y)\mu(y)\,ds_y
+
\frac{d}{ds_x}\int_\Gamma
\Big(\Phi_{k_1}(x,y)-\Phi_{k_2}(x,y)\Big)\frac{d\mu}{ds_y}(y)\,ds_y
}
$$
曲线参数化拉回后
$$
\varphi(\tau)=\mu(z(\tau)),\qquad r(t,\tau)=|z(t)-z(\tau)|.
$$
又因为
$$
\frac{d\mu}{ds_y}(y)=\frac{\varphi'(\tau)}{|z'(\tau)|},\qquad
\frac{d}{ds_x}=\frac{1}{|z'(t)|}\frac{d}{dt},
$$
参数化后变成

$$
\boxed{
\big((T_{k_1}-T_{k_2})\varphi\big)(t)
=

\frac{1}{|z'(t)|}
\int_0^{2\pi} A_{k_1,k_2}(t,\tau)\,\varphi(\tau)\,d\tau
+
\frac{1}{|z'(t)|}
\int_0^{2\pi} \big(N_{k_1}(t,\tau)-N_{k_2}(t,\tau)\big)\,\varphi'(\tau)\,d\tau
}
$$
其中
$$
A_{k_1,k_2}(t,\tau) = \frac{\mathrm{i}}{4} \Big(k_1^2 H_0^{(1)}(k_1 r(t,\tau)) - k_2^2 H_0^{(1)}(k_2 r(t,\tau))\Big)\big(z'(t)\!\cdot z'(\tau)\big).
$$

这里用到了
$$
n(t)\cdot n(\tau)=\frac{z'(t)\cdot z'(\tau)}{|z'(t)|\,|z'(\tau)|},
$$
再和$ds_y=|z'(\tau)|,d\tau$合并后，外面只剩一个$1/|z'(t)|$。而
$$
N_k(t,\tau) = -\frac{\mathrm{i}k}{4}\,\frac{z'(t)\cdot (z(t) - z(\tau))}{r(t,\tau)}H_1(kr(t,\tau)).$$
分裂kernel后得到
$$
N_k(t,\tau) = \frac{1}{4\pi}\cot \frac{t - \tau}{2} + N_{1k}(t,\tau)\log\left(4\sin^2\frac{t - \tau}{2}\right) + N_{2k}(t,\tau)
$$
其中
$$
N_{1k}(t,\tau) = \frac{k}{4\pi}\,\frac{z'(t)\cdot (z(t) - z(\tau))}{r(t,\tau)}J_1(kr(t,\tau)),\\
N_{2k}(t,\tau) = N_k(t,\tau) - \frac{1}{4\pi}\cot \frac{t - \tau}{2} - N_{1k}(t,\tau)\log\left(4\sin^2\frac{t - \tau}{2}\right)
$$
且有极限
$$
N_{1k}(t,t) = 0,\quad N_{2k}(t,t) = \frac{1}{4\pi}\,
\frac{z_1'(t)z_1''(t) + z_2'(t)z_2''(t)}{|z'(t)|^2}.
$$

记$(T_{k1} - T_{k2})\mu = I_a + I_b$, 

### 积分$I_a$
对于kernel
$$
M(t, \tau) = \frac{\mathrm{i}}{4}H_0^{(1)}(kr(t,\tau))|z'(\tau)|
$$
有
$$
M(t,\tau) = M_1(t,\tau)\log\left( 4\sin^2\frac{t - \tau}{2} \right) + M_2(t,\tau)
$$
其中
$$
M_1(t,\tau) = -\frac{1}{4\pi}J_0(kr(t,\tau))|z'(t)|,\\
M_2(t,\tau) = M(t, \tau) - M_1(t,\tau) \log\left( 4\sin^2\frac{t - \tau}{2} \right).
$$
且有极限
$$
M_1(t,t) = -\frac{1}{4\pi}|z'(t)|,\\
M_2(t,t)= \frac{1}{2}
\left\{\frac{\mathrm{i}}{2} -\frac{C}{\pi} -\frac{1}{2\pi}\log\!\left(\frac{k^2}{4}|z'(t)|^2\right)
\right\}|z'(t)|
$$
其中C是Euler常数C = 0.57721566490153286060. 于是有
$$
I_a(t) = \int_0^{2\pi} \left\{ [k_1^2M_1^{(k_1)}(t,\tau) - k_2^2M_1^{(k_2)}(t,\tau)]\log(4\sin^2\frac{t - \tau}{2}) + [k_1^2M_2^{(k_1)}(t,\tau) - k_2^2M_2^{(k_2)}(t,\tau)]\right\}\frac{z'(t)\cdot z'(\tau)}{|z'(t)||z'(\tau)|}\varphi(\tau)d\tau
$$

### 积分$I_b$
直接将kernel split代入得
$$
I_b(t) = \frac{1}{|z'(t)|}\int_0^{2\pi} \left\{ [N_1^{(k_1)}(t,\tau) - N_1^{(k_2)}(t,\tau)]\log(4\sin^2\frac{t - \tau}{2}) + [N_2^{(k_1)}(t,\tau) - N_2^{(k_2)}(t,\tau)] \right\}\varphi'(\tau)d\tau
$$

### 化为Kress型积分
最终可将积分化为
$$
(T^{(k_1)} - T^{(k_2)})\mu = \int_0^{2\pi} \{K_1(t,\tau)\log(4\sin^2\frac{t - \tau}{2}) + K_2(t,\tau)\}\,d\tau
$$
其中
$$
K_1(t,\tau) = [k_1^2M_1^{(k_1)}(t,\tau) - k_2^2M_1^{(k_2)}(t,\tau)]\frac{z'(t)\cdot z'(\tau)}{|z'(t)||z'(\tau)|}\varphi(\tau)
+ [N_1^{(k_1)}(t,\tau) - N_1^{(k_2)}(t,\tau)]\frac{\varphi'(\tau)}{|z'(t)|},\\
K_2(t,\tau) = [k_1^2M_2^{(k_1)}(t,\tau) - k_2^2M_2^{(k_2)}(t,\tau)]\frac{z'(t)\cdot z'(\tau)}{|z'(t)||z'(\tau)|}\varphi(\tau)
+ [N_2^{(k_1)}(t,\tau) - N_2^{(k_2)}(t,\tau)]\frac{\varphi'(\tau)}{|z'(t)|}
$$

## Equidistant trigonometric interpolation of the boundary density

为处理
$$
I_b(t) = \frac{1}{|z'(t)|}\int_0^{2\pi}
\left\{ [N_1^{(k_1)}(t,\tau) - N_1^{(k_2)}(t,\tau)]\log\!\left(4\sin^2\frac{t-\tau}{2}\right)
+ [N_2^{(k_1)}(t,\tau) - N_2^{(k_2)}(t,\tau)]\right\}\varphi'(\tau)\,d\tau,
$$
不再尝试将连续算子改写成单纯的 ``kernel $\times$ density'' 形式，而是直接在等距节点上对 density 作三角插值，然后对插值函数求导。

### 1. 等距节点与离散未知量

取
$$
t_j = \frac{\pi j}{n},\qquad j=0,1,\dots,2n-1.
$$
定义离散未知量
$$
\varphi_j := \varphi(t_j)=\mu(z(t_j)).
$$

于是未知量仍然只是节点值向量
$$
\boldsymbol{\varphi}
=
(\varphi_0,\varphi_1,\dots,\varphi_{2n-1})^T.
$$

### 2. 三角插值表示

记 $\mathcal T_n$ 为次数不超过 $n$ 的 $2\pi$-周期三角多项式空间。定义三角插值函数 $\varphi_n\in \mathcal T_n$ 满足
$$
\varphi_n(t_j)=\varphi_j,\qquad j=0,\dots,2n-1.
$$

引入等距三角插值基函数 $L_j(t)$，定义为
$$
L_j(t_i)=\delta_{ij},\qquad i,j=0,\dots,2n-1.
$$
则
$$
\boxed{
\varphi_n(t)=\sum_{j=0}^{2n-1}\varphi_j\,L_j(t).
}
$$

对于 $t\neq t_j$，有显式公式
$$
\boxed{
L_j(t)=\frac{1}{2n}\sin\big(n(t-t_j)\big)\cot\frac{t-t_j}{2}.
}
$$
并取连续延拓 $L_j(t_j)=1$。

### 3. density 导数的离散表示

由插值函数直接定义导数近似
$$
\varphi'(\tau)\approx \varphi_n'(\tau).
$$
于是
$$
\varphi_n'(t_m)=\sum_{j=0}^{2n-1} D_{mj}\,\varphi_j,
\qquad m=0,\dots,2n-1,
$$
其中 $D=(D_{mj})$ 为等距三角微分矩阵，满足
$$
\boxed{
D_{mj}=
\begin{cases}
\dfrac12\,(-1)^{m+j}\cot\dfrac{t_m-t_j}{2}, & m\neq j,\\[1.2ex]
0, & m=j.
\end{cases}
}
$$

记
$$
\mathbf{g}:=D\boldsymbol{\varphi},
\qquad
g_m=\varphi_n'(t_m).
$$
则 $\mathbf{g}$ 就是 density 导数在节点处的近似值向量。

### 4. 记号简化

定义
$$
\Delta N_1(t,\tau):=N_1^{(k_1)}(t,\tau)-N_1^{(k_2)}(t,\tau),
\qquad
\Delta N_2(t,\tau):=N_2^{(k_1)}(t,\tau)-N_2^{(k_2)}(t,\tau).
$$

同理，对 $I_a$ 中的 $M$-项定义
$$
\Delta M_1(t,\tau):=k_1^2M_1^{(k_1)}(t,\tau)-k_2^2M_1^{(k_2)}(t,\tau),
$$
$$
\Delta M_2(t,\tau):=k_1^2M_2^{(k_1)}(t,\tau)-k_2^2M_2^{(k_2)}(t,\tau).
$$

再定义几何因子
$$
G(t,\tau):=\frac{z'(t)\cdot z'(\tau)}{|z'(t)|\,|z'(\tau)|}.
$$

### 5. Kress 型权重记号

对于 target $t=t_i$ 和 source 节点 $t_m$，记
$$
R_{im}^{(n)}:=R_m^{(n)}(t_i),
$$
其中 $R_m^{(n)}(t)$ 是你现有 `LOCAL_quad_kress_rvec` 所返回的对数核 product quadrature 权重。由于节点等距且问题周期，$R_{im}^{(n)}$ 实际上只依赖于 $i-m \pmod{2n}$，但实现时直接使用
$$
R_{im}^{(n)}=R_m^{(n)}(t_i)
$$
即可。

### 6. 积分 $I_b$ 的离散化

将 $\varphi'(\tau)$ 近似为三角插值导数 $\varphi_n'(\tau)$，再对 fixed target $t=t_i$ 应用 Kress product quadrature，得到
$$
I_b(t_i)\approx
\frac{1}{|z'(t_i)|}
\sum_{m=0}^{2n-1}
\left[
R_{im}^{(n)}\,\Delta N_1(t_i,t_m)
+\frac{\pi}{n}\,\Delta N_2(t_i,t_m)
\right] g_m.
$$

定义矩阵 $B=(B_{im})$ 为
$$
\boxed{
B_{im}
=
\frac{1}{|z'(t_i)|}
\left[
R_{im}^{(n)}\,\Delta N_1(t_i,t_m)
+\frac{\pi}{n}\,\Delta N_2(t_i,t_m)
\right].
}
$$
则
$$
\boxed{
\mathbf{I}_b \approx B\,\mathbf{g}=B\,D\,\boldsymbol{\varphi}.
}
$$

也就是说，$I_b$ 这一块的离散矩阵不是单独一个 Kress 矩阵，而是
$$
\boxed{
T_b^{(n)}=B D.
}
$$

### 7. 积分 $I_a$ 的离散化

对于
$$
I_a(t)=\int_0^{2\pi}
\left\{
\Delta M_1(t,\tau)\log\!\left(4\sin^2\frac{t-\tau}{2}\right)
+\Delta M_2(t,\tau)
\right\}
G(t,\tau)\,\varphi(\tau)\,d\tau,
$$
直接应用 Kress product quadrature 得
$$
I_a(t_i)\approx
\sum_{m=0}^{2n-1}
\left[
R_{im}^{(n)}\,\Delta M_1(t_i,t_m)
+\frac{\pi}{n}\,\Delta M_2(t_i,t_m)
\right]
G(t_i,t_m)\,\varphi_m.
$$

定义矩阵 $A=(A_{im})$ 为
$$
\boxed{
A_{im}
=
\left[
R_{im}^{(n)}\,\Delta M_1(t_i,t_m)
+\frac{\pi}{n}\,\Delta M_2(t_i,t_m)
\right]
G(t_i,t_m).
}
$$
则
$$
\boxed{
\mathbf{I}_a \approx A\,\boldsymbol{\varphi}.
}
$$

### 8. 最终离散形式

因此，
$$
(T^{(k_1)}-T^{(k_2)})\mu = I_a + I_b
$$
在等距三角插值下的离散矩阵形式为
$$
\boxed{
\mathbf{T}^{(n)}\boldsymbol{\varphi}
=
(A + B D)\boldsymbol{\varphi}.
}
$$

其中：

- $A$ 来自 $I_a$ 的标准 Kress 型离散；
- $D$ 是等距三角微分矩阵；
- $B$ 是对 $I_b$ 中 $\Delta N_1,\Delta N_2$ 作 Kress product quadrature 后得到的矩阵。

### 9. 实现层面的最小改动

如果现有代码已经能装配标准的 Kress 型矩阵，那么这里仅需额外加入三部分：

1. 生成等距节点
$$
t_j=\frac{\pi j}{n},\qquad j=0,\dots,2n-1.
$$

2. 生成三角微分矩阵
$$
D_{mj}=
\begin{cases}
\dfrac12\,(-1)^{m+j}\cot\dfrac{t_m-t_j}{2}, & m\neq j,\\[1.2ex]
0, & m=j.
\end{cases}
$$

3. 装配矩阵 $B$，然后令
$$
T_b^{(n)}=B D,
\qquad
T^{(n)}=A+B D.
$$

因此，这一路线并不要求求出 $\partial_\tau N_2$，也不要求在连续层面把 $I_b$ 再改写成单纯的 ``kernel $\times$ density'' 形式；只需要把 density 在等距节点上用三角插值表示，并通过微分矩阵获得节点导数即可。
