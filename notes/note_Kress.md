## Kress 对数核求积

本文统一采用以下符号：边界总节点数记为大写 $N$，并总是假设 $N$ 为偶数；Kress 对数核求积权重记为 $R_j^{(N)}$；带波数的 hypersingular 算子统一写作 $T^{(k)}$，两个波数相减写作 $T^{(k_1)}-T^{(k_2)}$。

固定周期 $T=2\pi$。取 $N$ 个等距节点
$$
x_j=\frac{2\pi j}{N},\qquad j=1,\ldots,N.
$$

Kress 求积本质上是 Martensen--Kussmaul 型乘积求积。先记对数核的 Fourier 级数
$$
g(s)=\log\left(4\sin^2\frac{s}{2}\right)
\quad\Longleftrightarrow\quad
g_n=
\begin{cases}
0, & n=0,\\
-1/|n|, & n\ne 0.
\end{cases}
$$

将 $g$ 平移 $t\in\mathbb{R}$ 相当于把 Fourier 系数乘以 $e^{-int}$。代入乘积求积权重并化简，得到
$$
\int_0^{2\pi}
\log\left(4\sin^2\frac{t-s}{2}\right)\phi(s)\,ds
\approx
\sum_{j=1}^N R_j^{(N)}(t)\phi(x_j),
$$
其中依赖目标点位置 $t$ 的权重为
$$
R_j^{(N)}(t)
=
-\frac{4\pi}{N}
\left[
\sum_{\ell=1}^{N/2-1}\frac{1}{\ell}\cos \ell(x_j-t)
+\frac{1}{N}\cos\frac{N}{2}(x_j-t)
\right],
\qquad j=1,\ldots,N.
$$

如果还含有光滑项，则对光滑项使用周期梯形公式：
$$
\int_0^{2\pi}
\left[
\log\left(4\sin^2\frac{t-s}{2}\right)\phi(s)+\psi(s)
\right]\,ds
\approx
\sum_{j=1}^N R_j^{(N)}(t)\phi(x_j)
+\frac{2\pi}{N}\sum_{j=1}^N \psi(x_j).
$$

只要奇异对数部分和光滑部分已经分离，这个求积公式就是高阶精度的；当 $\phi$ 和 $\psi$ 都解析时，误差呈指数收敛。

## Kress Nyström 离散

对形如
$$
k(x,x')=
\phi(x,x')\log\left(4\sin^2\frac{x-x'}{2}\right)+\psi(x,x'),
$$
的周期核，如果 $\phi(x,x')$ 和 $\psi(x,x')$ 已经分别给出，则令 $h=2\pi/N$，应用 Kress 求积得到
$$
\int_0^{2\pi} k(x_i,x')\sigma(x')\,dx'
\approx
\sum_{j=1}^N
R_j^{(N)}(x_i)\phi(x_i,x_j)\sigma(x_j)
+h\sum_{j=1}^N \psi(x_i,x_j)\sigma(x_j).
$$

记
$$
R_j^{(N)}:=R_j^{(N)}(0),
$$
并注意到等距周期节点下 $R_j^{(N)}(x_i)$ 只依赖于 $|i-j|$ 的循环差。于是系数矩阵 $A$ 的元素可写为
$$
a_{i,j}
=
R_{|i-j|}^{(N)}\phi(x_i,x_j)
+h\psi(x_i,x_j).
$$

这里 $R_{|i-j|}^{(N)}$ 形成稠密循环矩阵，所有 $N^2$ 个元素都不同于标准 Nyström 矩阵。由于一般的 $\phi$ 和 $\psi$ 不一定有可直接调用的快速势算法，这个 Kress 型离散本身通常不与 FMM 直接兼容。

## 本项目采用的 \(M,N,L\) 核记号

下面统一采用和 Kress 论文类似的三个核记号，但所有系数、符号都按本项目的裸归一化约定来写。设
$$
z=z(t),\qquad s(t)=|z'(t)|,\qquad
\nu(t)=n(t)s(t)=(z_2'(t),-z_1'(t)),
$$
并令
$$
r(t,\tau)=|z(t)-z(\tau)|,\qquad
g(t,\tau)=\log\!\left(4\sin^2\frac{t-\tau}{2}\right).
$$

对任意满足
$$
X^{(k)}(t,\tau)=X_1^{(k)}(t,\tau)g(t,\tau)+X_2^{(k)}(t,\tau)
$$
的核，Kress 矩阵填充统一写成
$$
\boxed{
\mathcal K_N[X^{(k)}]_{ij}
=
R_{ij}^{(N)}X_1^{(k)}(t_i,t_j)
+hX_2^{(k)}(t_i,t_j),
\qquad h=\frac{2\pi}{N}.
}
$$
这里 \(R_{ij}^{(N)}\) 是已经包含 \(2\pi/N\) 缩放的 Kress 对数权重。

### \(M\) 核：对应单层核 \(\Phi_k\)

定义
$$
M^{(k)}(t,\tau)
=
\Phi_k(z(t),z(\tau))s(\tau)
=
\frac{i}{4}H_0^{(1)}(k r(t,\tau))s(\tau).
$$
其 split 为
$$
M^{(k)}=M_1^{(k)}g+M_2^{(k)},
$$
其中 \(t\ne\tau\) 时
$$
M_1^{(k)}(t,\tau)
=
-\frac{1}{4\pi}J_0(k r(t,\tau))s(\tau),
\qquad
M_2^{(k)}=M^{(k)}-M_1^{(k)}g.
$$
对角上使用
$$
M_1^{(k)}(t,t)=-\frac{1}{4\pi}s(t),
$$
$$
M_2^{(k)}(t,t)
=
\frac12
\left\{
\frac{i}{2}
-\frac{C}{\pi}
-\frac{1}{2\pi}\log\!\left(\frac{k^2}{4}s(t)^2\right)
\right\}s(t).
$$

### \(L\) 核：对应裸 \(D\) 算子

本文的 \(L\) 核定义为 source-normal double-layer kernel：
$$
L^{(k)}(t,\tau)
=
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_\tau}s(\tau).
$$
这和 Kress 论文式 (2.2) 中直接出现的 \(L_{\mathrm K}\) 不同；论文中的 \(K,S\) 带整体因子 \(2\)，并且式 (2.2) 中 \(L_{\mathrm K}\) 前还有一个负号。因此
$$
\boxed{
L^{(k)}=-\frac12 L_{\mathrm K}^{(k)}.
}
$$
后续凡是写
$$
(D^{(k)}\varphi)(t)=\int_0^{2\pi}L^{(k)}(t,\tau)\varphi(\tau)\,d\tau
$$
时，\(L^{(k)}\) 都指这个裸核，而不是 Kress 论文原始的 \(L_{\mathrm K}\)。

写成 Kress split：
$$
L^{(k)}=L_1^{(k)}g+L_2^{(k)}.
$$
其中 \(t\ne\tau\) 时可取
$$
L_1^{(k)}(t,\tau)
=
-\frac{k}{4\pi}
\frac{\nu(\tau)\cdot(z(t)-z(\tau))}{r(t,\tau)}
J_1(k r(t,\tau)),
\qquad
L_2^{(k)}=L^{(k)}-L_1^{(k)}g.
$$
对角上使用
$$
L_1^{(k)}(t,t)=0,
\qquad
L_2^{(k)}(t,t)
=
-\frac{1}{4\pi}
\frac{z_1'(t)z_2''(t)-z_2'(t)z_1''(t)}{s(t)^2}.
$$

对于 adjoint double-layer，记
$$
L^{(k)*}(t,\tau)
=
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_t}s(\tau),
$$
并同样写成
$$
L^{(k)*}=L_1^{(k)*}g+L_2^{(k)*}.
$$
使用 Kress 论文的 split 时同样先做换算
$$
L^{(k)*}=-\frac12 L_{\mathrm K}^{(k)*}.
$$

### \(N\) 核：对应 \(T\) 算子的切向导数部分

本项目将裸 hypersingular 算子写成
$$
T^{(k)}\mu
=
k^2\int_\Gamma \Phi_k(x,y)(n_x\cdot n_y)\mu(y)\,ds_y
+
\frac{d}{ds_x}\int_\Gamma \Phi_k(x,y)\frac{d\mu}{ds_y}(y)\,ds_y.
$$
参数化后，第二项使用
$$
N^{(k)}(t,\tau)
=
-\frac{ik}{4}
\frac{z'(t)\cdot(z(t)-z(\tau))}{r(t,\tau)}
H_1^{(1)}(k r(t,\tau)).
$$
其 split 为
$$
N^{(k)}
=
\frac{1}{4\pi}\cot\frac{t-\tau}{2}
+N_1^{(k)}g+N_2^{(k)}.
$$
其中 \(t\ne\tau\) 时
$$
N_1^{(k)}(t,\tau)
=
\frac{k}{4\pi}
\frac{z'(t)\cdot(z(t)-z(\tau))}{r(t,\tau)}
J_1(k r(t,\tau)),
\qquad
N_2^{(k)}
=
N^{(k)}
-\frac{1}{4\pi}\cot\frac{t-\tau}{2}
-N_1^{(k)}g.
$$
对角上使用
$$
N_1^{(k)}(t,t)=0,\qquad
N_2^{(k)}(t,t)
=
\frac{1}{4\pi}
\frac{z_1'(t)z_1''(t)+z_2'(t)z_2''(t)}{s(t)^2}.
$$

## 算子 $T^{(k)}$ 的等价形式

定义
$$
\boxed{
(T^{(k)}\mu)(x)=\frac{\partial}{\partial n_x}\int_\Gamma
\frac{\partial \Phi_k(x,y)}{\partial n_y}\mu(y)\,ds_y
}
$$

则有公式
$$
\boxed{
T^{(k)}\mu =

k^2\int_\Gamma \Phi_k(x,y)\,(n_x\!\cdot n_y)\,\mu(y)\,ds_y
+
\frac{d}{ds_x}\int_\Gamma \Phi_k(x,y)\,\frac{d\mu}{ds_y}(y)\,ds_y
}
$$

因此两个波数相减时，

$$
\boxed{
(T^{(k_1)}-T^{(k_2)})\mu
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
\big((T^{(k_1)}-T^{(k_2)})\varphi\big)(t)
=

\frac{1}{|z'(t)|}
\int_0^{2\pi} A^{(k_1,k_2)}(t,\tau)\,\varphi(\tau)\,d\tau
+
\frac{1}{|z'(t)|}
\int_0^{2\pi} \big(N^{(k_1)}(t,\tau)-N^{(k_2)}(t,\tau)\big)\,\varphi'(\tau)\,d\tau
}
$$
其中
$$
A^{(k_1,k_2)}(t,\tau) = \frac{\mathrm{i}}{4} \Big(k_1^2 H_0^{(1)}(k_1 r(t,\tau)) - k_2^2 H_0^{(1)}(k_2 r(t,\tau))\Big)\big(z'(t)\!\cdot z'(\tau)\big).
$$

这里用到了
$$
n(t)\cdot n(\tau)=\frac{z'(t)\cdot z'(\tau)}{|z'(t)|\,|z'(\tau)|},
$$
再和 $ds_y=|z'(\tau)|\,d\tau$ 合并后，外面只剩一个 $1/|z'(t)|$。而
$$
N^{(k)}(t,\tau) = -\frac{\mathrm{i}k}{4}\,\frac{z'(t)\cdot (z(t) - z(\tau))}{r(t,\tau)}H_1(kr(t,\tau)).
$$
分裂核函数后得到
$$
N^{(k)}(t,\tau) = \frac{1}{4\pi}\cot \frac{t - \tau}{2} + N_1^{(k)}(t,\tau)\log\left(4\sin^2\frac{t - \tau}{2}\right) + N_2^{(k)}(t,\tau)
$$
其中
$$
N_1^{(k)}(t,\tau) = \frac{k}{4\pi}\,\frac{z'(t)\cdot (z(t) - z(\tau))}{r(t,\tau)}J_1(kr(t,\tau)),\\
N_2^{(k)}(t,\tau) = N^{(k)}(t,\tau) - \frac{1}{4\pi}\cot \frac{t - \tau}{2} - N_1^{(k)}(t,\tau)\log\left(4\sin^2\frac{t - \tau}{2}\right)
$$
且有极限
$$
N_1^{(k)}(t,t) = 0,\quad N_2^{(k)}(t,t) = \frac{1}{4\pi}\,
\frac{z_1'(t)z_1''(t) + z_2'(t)z_2''(t)}{|z'(t)|^2}.
$$

记 $(T^{(k_1)} - T^{(k_2)})\mu = I_a + I_b$。

### 积分 $I_a$
对于核函数
$$
M(t, \tau) = \frac{\mathrm{i}}{4}H_0^{(1)}(kr(t,\tau))|z'(\tau)|
$$
有
$$
M(t,\tau) = M_1(t,\tau)\log\left( 4\sin^2\frac{t - \tau}{2} \right) + M_2(t,\tau)
$$
其中
$$
M_1(t,\tau) = -\frac{1}{4\pi}J_0(kr(t,\tau))|z'(\tau)|,\\
M_2(t,\tau) = M(t, \tau) - M_1(t,\tau) \log\left( 4\sin^2\frac{t - \tau}{2} \right).
$$
且有极限
$$
M_1(t,t) = -\frac{1}{4\pi}|z'(t)|,\\
M_2(t,t)= \frac{1}{2}
\left\{\frac{\mathrm{i}}{2} -\frac{C}{\pi} -\frac{1}{2\pi}\log\!\left(\frac{k^2}{4}|z'(t)|^2\right)
\right\}|z'(t)|
$$
其中 $C$ 是 Euler 常数，$C = 0.57721566490153286060$。于是有
$$
I_a(t) = \int_0^{2\pi} \left\{ [k_1^2M_1^{(k_1)}(t,\tau) - k_2^2M_1^{(k_2)}(t,\tau)]\log(4\sin^2\frac{t - \tau}{2}) + [k_1^2M_2^{(k_1)}(t,\tau) - k_2^2M_2^{(k_2)}(t,\tau)]\right\}\frac{z'(t)\cdot z'(\tau)}{|z'(t)||z'(\tau)|}\varphi(\tau)d\tau
$$

### 积分 $I_b$
直接将核函数分裂代入得
$$
I_b(t) = \frac{1}{|z'(t)|}\int_0^{2\pi} \left\{ [N_1^{(k_1)}(t,\tau) - N_1^{(k_2)}(t,\tau)]\log(4\sin^2\frac{t - \tau}{2}) + [N_2^{(k_1)}(t,\tau) - N_2^{(k_2)}(t,\tau)] \right\}\varphi'(\tau)d\tau
$$

### 化为 Kress 型积分
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

## 边界密度的等距三角插值

为处理
$$
I_b(t) = \frac{1}{|z'(t)|}\int_0^{2\pi}
\left\{ [N_1^{(k_1)}(t,\tau) - N_1^{(k_2)}(t,\tau)]\log\!\left(4\sin^2\frac{t-\tau}{2}\right)
+ [N_2^{(k_1)}(t,\tau) - N_2^{(k_2)}(t,\tau)]\right\}\varphi'(\tau)\,d\tau,
$$
不再尝试将连续算子改写成单纯的 “核函数 $\times$ 密度” 形式，而是直接在等距节点上对密度作三角插值，然后对插值函数求导。

### 1. 等距节点与离散未知量

取总节点数 $N$ 为偶数，并令 $n=N/2$ 仅表示最高余弦模态的阶数。节点为
$$
t_j = \frac{2\pi j}{N},\qquad j=0,1,\dots,N-1.
$$
定义离散未知量
$$
\varphi_j := \varphi(t_j)=\mu(z(t_j)).
$$

于是未知量仍然只是节点值向量
$$
\boldsymbol{\varphi}
=
(\varphi_0,\varphi_1,\dots,\varphi_{N-1})^T.
$$

### 2. 三角插值表示

记偶数节点对应的三角插值空间为
$$
\mathcal T_N=
\operatorname{span}\{1,\cos t,\sin t,\dots,\cos((n-1)t),\sin((n-1)t),\cos(nt)\}.
$$
这里包含 Nyquist cosine mode $\cos(nt)$，但没有独立的 Nyquist sine mode，因为 $\sin(nt_j)=0$。定义三角插值函数 $\varphi_N\in \mathcal T_N$ 满足
$$
\varphi_N(t_j)=\varphi_j,\qquad j=0,\dots,N-1.
$$

引入等距三角插值基函数 $L_j(t)$，定义为
$$
L_j(t_i)=\delta_{ij},\qquad i,j=0,\dots,N-1.
$$
则
$$
\boxed{
\varphi_N(t)=\sum_{j=0}^{N-1}\varphi_j\,L_j(t).
}
$$

对于 $t\neq t_j$，有显式公式
$$
\boxed{
L_j(t)=\frac{1}{N}\sin\!\left(\frac{N}{2}(t-t_j)\right)\cot\frac{t-t_j}{2}.
}
$$
并取连续延拓 $L_j(t_j)=1$。

### 3. 密度导数的离散表示

由插值函数直接定义导数近似
$$
\varphi'(\tau)\approx \varphi_N'(\tau).
$$
于是
$$
\varphi_N'(t_m)=\sum_{j=0}^{N-1} D_{mj}\,\varphi_j,
\qquad m=0,\dots,N-1,
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
g_m=\varphi_N'(t_m).
$$
则 $\mathbf{g}$ 就是密度导数在节点处的近似值向量。

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

对于目标点 $t=t_i$ 和源节点 $t_m$，记
$$
R_{im}^{(N)}:=R_m^{(N)}(t_i),
$$
其中 $R_m^{(N)}(t)$ 是对数核乘积求积权重。由于节点等距且问题周期，$R_{im}^{(N)}$ 实际上只依赖于 $i-m \pmod{N}$，但实现时直接使用
$$
R_{im}^{(N)}=R_m^{(N)}(t_i)
$$
即可。

### 6. 积分 $I_b$ 的离散化

将 $\varphi'(\tau)$ 近似为三角插值导数 $\varphi_N'(\tau)$，再对固定目标点 $t=t_i$ 应用 Kress 乘积求积，得到
$$
I_b(t_i)\approx
\frac{1}{|z'(t_i)|}
\sum_{m=0}^{N-1}
\left[
R_{im}^{(N)}\,\Delta N_1(t_i,t_m)
+\frac{2\pi}{N}\,\Delta N_2(t_i,t_m)
\right] g_m.
$$

定义矩阵 $B=(B_{im})$ 为
$$
\boxed{
B_{im}
=
\frac{1}{|z'(t_i)|}
\left[
R_{im}^{(N)}\,\Delta N_1(t_i,t_m)
+\frac{2\pi}{N}\,\Delta N_2(t_i,t_m)
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
\mathbf T_{b,N}=B D.
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
直接应用 Kress 乘积求积得
$$
I_a(t_i)\approx
\sum_{m=0}^{N-1}
\left[
R_{im}^{(N)}\,\Delta M_1(t_i,t_m)
+\frac{2\pi}{N}\,\Delta M_2(t_i,t_m)
\right]
G(t_i,t_m)\,\varphi_m.
$$

定义矩阵 $A=(A_{im})$ 为
$$
\boxed{
A_{im}
=
\left[
R_{im}^{(N)}\,\Delta M_1(t_i,t_m)
+\frac{2\pi}{N}\,\Delta M_2(t_i,t_m)
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
\mathbf T_N^\Delta\boldsymbol{\varphi}
=
(A + B D)\boldsymbol{\varphi}.
}
$$

其中：

- $A$ 来自 $I_a$ 的标准 Kress 型离散；
- $D$ 是等距三角微分矩阵；
- $B$ 是对 $I_b$ 中 $\Delta N_1,\Delta N_2$ 作 Kress 乘积求积后得到的矩阵。

### 9. 实现层面的最小改动

如果现有代码已经能装配标准的 Kress 型矩阵，那么这里仅需额外加入三部分：

1. 生成等距节点
$$
t_j=\frac{2\pi j}{N},\qquad j=0,\dots,N-1.
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
\mathbf T_{b,N}=B D,
\qquad
\mathbf T_N^\Delta=A+B D.
$$

因此，这一路线并不要求求出 $\partial_\tau N_2$，也不要求在连续层面把 $I_b$ 再改写成单纯的 “核函数 $\times$ 密度” 形式；只需要把密度在等距节点上用三角插值表示，并通过微分矩阵获得节点导数即可。

## 圆边界上的 $T^{(k_1)} - T^{(k_2)}$ 验证

下面把圆上验证实验重新整理一遍。核心是：**圆具有旋转对称性，所以所有边界积分算子都是 convolution 型算子，Fourier 模态 $e^{imt}$ 会自动成为特征函数。** 因此可以避开直接计算 hypersingular 积分，只检查实现的差分算子
$$
T^{(k_1)}-T^{(k_2)}
$$
是否在 Fourier 模态上给出正确特征值。

### 1. 要验证的算子

这里使用当前的“裸归一化”：
$$
(T^{(k)}\mu)(x)
=
\frac{\partial}{\partial n_x}
\int_\Gamma
\frac{\partial \Phi_k(x,y)}{\partial n_y}\mu(y)\,ds_y,
\qquad
\Phi_k(x,y)=\frac{i}{4}H_0^{(1)}(k|x-y|).
$$

Kress 论文中 $T$ 被定义为双层势的法向导数，但他的算子定义里有整体因子 $2$；这里采用裸归一化，并用 Kress 的恒等式把 $T^{(k)}$ 拆成 $\kappa^2\Phi$ 项和切向导数项。

要验证的离散块是
$$
\mathbf T_N^\Delta=\mathbf T_N^{(k_1)}-\mathbf T_N^{(k_2)}.
$$

按现在的实现路线，它应当由两部分组成：
$$
\boxed{
\mathbf T_N^\Delta=A+B D.
}
$$

其中：

* $A$ 来自 $\kappa^2\Phi$ 对应的 $I_a$ 项；
* $B$ 来自 $N^{(k_1)}-N^{(k_2)}$ 作用在 $\varphi'$ 上的 $I_b$ 项；
* $D$ 是等距三角插值微分矩阵。

### 2. 圆边界和测试密度

取圆
$$
\Gamma=\{a(\cos t,\sin t):0\le t<2\pi\},
$$
即
$$
z(t)=a(\cos t,\sin t),
\qquad
|z'(t)|=a,
\qquad
n(t)=(\cos t,\sin t).
$$

取 Fourier 密度
$$
\mu_m(z(t))=\varphi_m(t)=e^{imt},
\qquad m\in\mathbb Z.
$$

实际代码里可以用复数版本 $e^{imt}$，也可以用实数版本 $\cos(mt)$、$\sin(mt)$。由于圆对称，$\cos(mt)$ 和 $\sin(mt)$ 也都是同一特征值对应的实特征函数。

### 3. 为什么 $e^{imt}$ 是特征函数

圆上的核只依赖两个点的角度差 $t-\tau$。因此算子具有旋转不变性：
$$
T^{(k)}(\mu(\cdot+\alpha))(t)
=
(T^{(k)}\mu)(t+\alpha).
$$

任何旋转不变的周期积分算子在 Fourier 基底下都是对角的，所以
$$
T^{(k)}[e^{imt}]
=
\lambda_m^T(k)e^{imt}.
$$

这只是“圆上 convolution 被 Fourier 变换对角化”的说法。剩下的任务是算出 $\lambda_m^T(k)$。

### 4. 特征值的推导

使用 Graf 加法公式。对 $x=(r,\theta)$、$y=(a,\tau)$，当 $r>a$ 时，
$$
\Phi_k(x,y)
=
\frac{i}{4}
\sum_{\ell=-\infty}^{\infty}
H_\ell^{(1)}(kr)
J_\ell(ka)
e^{i\ell(\theta-\tau)}.
$$

双层势是
$$
(\mathcal D^{(k)}\mu)(x)
=
\int_\Gamma
\frac{\partial \Phi_k(x,y)}{\partial n_y}\mu(y)\,ds_y.
$$

圆上 $n_y$ 是径向外法向，因此
$$
\frac{\partial}{\partial n_y}
=
\frac{\partial}{\partial a}.
$$

并且
$$
ds_y=a\,d\tau.
$$

所以对密度 $\mu(y)=e^{im\tau}$，外部区域 $r>a$ 中有
$$
\mathcal D^{(k)}[e^{im\tau}](r,\theta)
=
\int_0^{2\pi}
\frac{\partial}{\partial a}
\left[
\frac{i}{4}
\sum_{\ell=-\infty}^{\infty}
H_\ell^{(1)}(kr)J_\ell(ka)e^{i\ell(\theta-\tau)}
\right]
e^{im\tau}a\,d\tau.
$$

对 $a$ 求导：
$$
\frac{\partial}{\partial a}J_\ell(ka)
=
kJ_\ell'(ka).
$$

于是
$$
\mathcal D^{(k)}[e^{im\tau}](r,\theta)
=
\frac{i}{4}a
\sum_{\ell=-\infty}^{\infty}
H_\ell^{(1)}(kr)kJ_\ell'(ka)
e^{i\ell\theta}
\int_0^{2\pi}e^{-i\ell\tau}e^{im\tau}\,d\tau.
$$

利用 Fourier 正交性：
$$
\int_0^{2\pi}e^{-i\ell\tau}e^{im\tau}\,d\tau
=
2\pi\delta_{\ell m}.
$$

只剩下 $\ell=m$ 项：
$$
\mathcal D^{(k)}[e^{im\tau}](r,\theta)
=
\frac{i\pi a k}{2}
J_m'(ka)H_m^{(1)}(kr)e^{im\theta},
\qquad r>a.
$$

现在 $T^{(k)}$ 是对这个双层势在 $x$ 处再取外法向导数。圆上外法向就是 $\partial_r$，所以令 $r\to a$：
$$
T^{(k)}[e^{imt}]
=
\left.
\frac{\partial}{\partial r}
\left[
\frac{i\pi a k}{2}
J_m'(ka)H_m^{(1)}(kr)e^{im\theta}
\right]
\right|_{r=a}.
$$

对 $r$ 求导：
$$
\frac{\partial}{\partial r}H_m^{(1)}(kr)
=
k\big(H_m^{(1)}\big)'(kr).
$$

因此
$$
T^{(k)}[e^{imt}]
=
\frac{i\pi a k^2}{2}
J_m'(ka)\big(H_m^{(1)}\big)'(ka)e^{imt}.
$$

所以裸归一化下的特征值是
$$
\boxed{
\lambda_m^T(k)
=
\frac{i\pi a k^2}{2}
J_m'(ka)\big(H_m^{(1)}\big)'(ka).
}
$$

这里 $J_m'$ 和 $\big(H_m^{(1)}\big)'$ 都是对完整 argument 求导，而不是对 $a$ 或 $k$ 求导。

### 5. 两个波数相减的解析答案

因此
$$
(T^{(k_1)}-T^{(k_2)})[e^{imt}]
=
\left(\lambda_m^T(k_1)-\lambda_m^T(k_2)\right)e^{imt},
$$
其中
$$
\boxed{
\lambda_m^T(k_1)-\lambda_m^T(k_2)
=
\frac{i\pi a}{2}
\left[
k_1^2J_m'(k_1a)\big(H_m^{(1)}\big)'(k_1a)
-
k_2^2J_m'(k_2a)\big(H_m^{(1)}\big)'(k_2a)
\right].
}
$$

这就是验证实验的精确参考值。

### 6. 数值验证怎么做

取等距节点
$$
t_j=\frac{2\pi j}{N},\qquad j=0,\dots,N-1.
$$

令
$$
\boldsymbol\varphi_m
=
(e^{imt_0},e^{imt_1},\dots,e^{imt_{N-1}})^T.
$$

组装实现中的离散矩阵
$$
\mathbf T_N^\Delta=A+B D.
$$

然后比较
$$
\mathbf T_N^\Delta\boldsymbol\varphi_m
$$
和
$$
\lambda_m^\Delta\boldsymbol\varphi_m,
\qquad
\lambda_m^\Delta:=\lambda_m^T(k_1)-\lambda_m^T(k_2).
$$

误差可以定义为
$$
\boxed{
E_T(N,m)
=
\frac{
\|\mathbf T_N^\Delta\boldsymbol\varphi_m-\lambda_m^\Delta\boldsymbol\varphi_m\|_\infty
}{
|\lambda_m^\Delta|\,\|\boldsymbol\varphi_m\|_\infty
}.
}
$$

因为 $\|\boldsymbol\varphi_m\|_\infty=1$，所以就是
$$
E_T(N,m)
=
\frac{
\|\mathbf T_N^\Delta\boldsymbol\varphi_m-\lambda_m^\Delta\boldsymbol\varphi_m\|_\infty
}{
|\lambda_m^\Delta|
}.
$$

### 7. 参数建议

先取
$$
a=1,\qquad k_1=2.3,\qquad k_2=4.7.
$$

测试模态：
$$
m=0,1,2,3,5.
$$

注意必须保证
$$
m<N/2,
$$
避免碰到 Nyquist 模态。比如 $N=32$ 时，$m=5$ 没问题。

取
$$
N=32,48,64,96,128,192,256.
$$

预期：

* 对固定小 $m$，误差应快速下降；
* 最后达到 $10^{-12}\sim 10^{-13}$ 附近的平台；
* 若误差卡在 $O(1)$ 或 $10^{-2}$，优先检查整体因子 $2$、法向方向、$I_a$ 是否漏项、以及 $BD$ 的顺序。

### 8. 一个很重要的因子检查

上面的特征值对应的是裸算子：
$$
T^{(k)}
=
\partial_{n_x}\int_\Gamma \partial_{n_y}\Phi_k\,\mu\,ds_y.
$$

如果代码里不小心使用了 Kress 论文中带整体因子 $2$ 的 $T$，那么数值结果会接近
$$
2\lambda_m^T(k).
$$

所以这个实验对因子 $2$ 非常敏感，是目前最适合验证 $T$-block 归一化的测试。


## 将 QP 光滑项加入最终 TEP 矩阵

前面各节主要整理的是自由空间核
$$
\Phi_k(x,y)=\frac{\mathrm{i}}{4}H_0^{(1)}(k|x-y|)
$$
所产生的奇异部分，尤其是
$$
T^{(k_1)}-T^{(k_2)}
$$
的 Kress 型离散。实际 TEP 矩阵中，外部波数对应的是准周期 Green 函数，因此还需要把 QP Green 函数相对自由空间 Green 函数的光滑修正项加入矩阵。

记
$$
k_{\mathrm{out}}=\omega,\qquad k_{\mathrm{in}}=n\omega.
$$
假设准周期 Green 函数在边界附近已经写成
$$
G_{\mathrm{QP}}^{(\omega)}(x,y)
=
\Phi_{k_{\mathrm{out}}}(x,y)
+
P_{\mathrm{QP}}^{(\omega)}(x,y),
$$
其中
$$
P_{\mathrm{QP}}^{(\omega)}(x,y)
$$
关于 $x,y$ 都是光滑函数。实际代码中，$P_{\mathrm{QP}}^{(\omega)}$ 可以来自 proxy correction、lattice correction，或其它光滑修正项。下面统一简称
$$
P(x,y):=P_{\mathrm{QP}}^{(\omega)}(x,y).
$$

最终 TEP 矩阵对应的算子块为
$$
\begin{bmatrix}
D_{\mathrm{QP}}^{(\omega)} - D^{(n\omega)} &
S^{(n\omega)} - S_{\mathrm{QP}}^{(\omega)} \\
T_{\mathrm{QP}}^{(\omega)} - T^{(n\omega)} &
D^{(n\omega)*} - D_{\mathrm{QP}}^{(\omega)*}
\end{bmatrix}.
$$

因此可以先装配自由空间差分部分
$$
\begin{bmatrix}
D^{(k_{\mathrm{out}})} - D^{(k_{\mathrm{in}})} &
S^{(k_{\mathrm{in}})} - S^{(k_{\mathrm{out}})} \\
T^{(k_{\mathrm{out}})} - T^{(k_{\mathrm{in}})} &
D^{(k_{\mathrm{in}})*} - D^{(k_{\mathrm{out}})*}
\end{bmatrix},
$$
然后再加入由 $P$ 产生的光滑 QP 修正项。

取等距节点
$$
t_j=\frac{2\pi j}{N},\qquad j=0,\dots,N-1,
$$
并记
$$
z_i=z(t_i),\qquad z'_i=z'(t_i),\qquad s_i=|z'_i|,\qquad h=\frac{2\pi}{N}.
$$
令单位外法向为
$$
n_i=n(t_i).
$$
如果使用逆时针参数化，则可取非单位外法向
$$
\nu_i=n_i s_i=(z_2'(t_i),-z_1'(t_i)).
$$

---

### 1. QP 项对 $A_{11}$ 块的贡献

$A_{11}$ 的算子块为
$$
D_{\mathrm{QP}}^{(\omega)}-D^{(n\omega)}.
$$
由于
$$
D_{\mathrm{QP}}^{(\omega)}
=
D^{(k_{\mathrm{out}})}+D^P,
$$
所以
$$
D_{\mathrm{QP}}^{(\omega)}-D^{(n\omega)}
=
\left(D^{(k_{\mathrm{out}})}-D^{(k_{\mathrm{in}})}\right)
+
D^P.
$$

这里
$$
D^P(t,\tau)
=
\frac{\partial P(z(t),z(\tau))}{\partial n_\tau}|z'(\tau)|.
$$

因此离散矩阵中，QP 光滑项给 $A_{11}$ 增加
$$
\boxed{
(A_{11}^{P})_{ij}
=
h\,\frac{\partial P(z_i,z_j)}{\partial n_y}\,s_j.
}
$$

也就是说
$$
\boxed{
A_{11}
=
A_{11}^{\mathrm{fs}}
+
A_{11}^{P}.
}
$$

这里 $A_{11}^{\mathrm{fs}}$ 表示自由空间部分
$$
D^{(k_{\mathrm{out}})}-D^{(k_{\mathrm{in}})}
$$
的离散矩阵。由于 $P$ 是光滑函数，$A_{11}^P$ 不需要任何 Kress 对数修正，直接用周期梯形公式即可。

如果代码中只能得到目标变量梯度
$$
\nabla_x P(z_i,z_j),
$$
则需要注意
$$
\nabla_y P(x,y)=-\nabla_x P(x,y)
$$
只对平移不变核成立。一般的 proxy 光滑项未必满足这个关系。因此：

- 如果 $P$ 由显式平移不变核给出，可以通过 $\nabla_x P$ 推出 $\nabla_y P$；
- 如果 $P$ 是一般 proxy 表示，应优先直接实现或返回 $\nabla_y P$；
- 不要在一般情形下默认 $\nabla_y P=-\nabla_x P$。

---

### 2. QP 项对 $A_{12}$ 块的贡献

$A_{12}$ 的算子块为
$$
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}.
$$
由于
$$
S_{\mathrm{QP}}^{(\omega)}
=
S^{(k_{\mathrm{out}})}+S^P,
$$
所以
$$
S^{(n\omega)}-S_{\mathrm{QP}}^{(\omega)}
=
\left(S^{(k_{\mathrm{in}})}-S^{(k_{\mathrm{out}})}\right)
-
S^P.
$$

其中
$$
S^P(t,\tau)
=
P(z(t),z(\tau))|z'(\tau)|.
$$

因此 QP 光滑项给 $A_{12}$ 增加
$$
\boxed{
(A_{12}^{P})_{ij}
=
-h\,P(z_i,z_j)s_j.
}
$$

也就是说
$$
\boxed{
A_{12}
=
A_{12}^{\mathrm{fs}}
+
A_{12}^{P}.
}
$$

这里 $A_{12}^{\mathrm{fs}}$ 表示自由空间差分
$$
S^{(k_{\mathrm{in}})}-S^{(k_{\mathrm{out}})}
$$
的 Kress 离散。由于 $P$ 光滑，$A_{12}^P$ 直接用周期梯形公式。

---

### 3. QP 项对 $A_{22}$ 块的贡献

$A_{22}$ 的算子块为
$$
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*}.
$$
由于
$$
D_{\mathrm{QP}}^{(\omega)*}
=
D^{(k_{\mathrm{out}})*}+D^{P*},
$$
所以
$$
D^{(n\omega)*}-D_{\mathrm{QP}}^{(\omega)*}
=
\left(D^{(k_{\mathrm{in}})*}-D^{(k_{\mathrm{out}})*}\right)
-
D^{P*}.
$$

其中
$$
D^{P*}(t,\tau)
=
\frac{\partial P(z(t),z(\tau))}{\partial n_t}|z'(\tau)|.
$$

因此 QP 光滑项给 $A_{22}$ 增加
$$
\boxed{
(A_{22}^{P})_{ij}
=
-h\,\frac{\partial P(z_i,z_j)}{\partial n_x}\,s_j.
}
$$

也就是说
$$
\boxed{
A_{22}
=
A_{22}^{\mathrm{fs}}
+
A_{22}^{P}.
}
$$

其中 $A_{22}^{\mathrm{fs}}$ 表示自由空间部分
$$
D^{(k_{\mathrm{in}})*}-D^{(k_{\mathrm{out}})*}
$$
的离散矩阵。这里同样不需要 Kress 对数修正。

---

### 4. QP 项对 $A_{21}$ 即 $T$ 块的贡献

$A_{21}$ 的算子块为
$$
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}.
$$
由
$$
G_{\mathrm{QP}}^{(\omega)}
=
\Phi_{k_{\mathrm{out}}}+P
$$
得到
$$
T_{\mathrm{QP}}^{(\omega)}-T^{(n\omega)}
=
\left(T^{(k_{\mathrm{out}})}-T^{(k_{\mathrm{in}})}\right)
+
T^P.
$$

其中自由空间差分部分
$$
T^{(k_{\mathrm{out}})}-T^{(k_{\mathrm{in}})}
$$
已经在前面整理为
$$
\mathbf T_N^\Delta=A+BD.
$$

现在只需加入光滑 QP 修正 $T^P$。

若 $P$ 在边界附近满足外部 Helmholtz 方程
$$
(\Delta_x+k_{\mathrm{out}}^2)P(x,y)=0,
$$
则可使用与 $T^{(k)}$ 相同的等价形式：
$$
T^P\mu
=
k_{\mathrm{out}}^2
\int_\Gamma P(x,y)(n_x\cdot n_y)\mu(y)\,ds_y
+
\frac{d}{ds_x}
\int_\Gamma P(x,y)\frac{d\mu}{ds_y}(y)\,ds_y.
$$

参数化后，第一项为
$$
k_{\mathrm{out}}^2
\int_0^{2\pi}
P(z(t),z(\tau))
\frac{z'(t)\cdot z'(\tau)}{|z'(t)||z'(\tau)|}
\varphi(\tau)|z'(\tau)|\,d\tau.
$$
即
$$
\frac{1}{|z'(t)|}
\int_0^{2\pi}
k_{\mathrm{out}}^2P(z(t),z(\tau))
\big(z'(t)\cdot z'(\tau)\big)
\varphi(\tau)\,d\tau.
$$

第二项为
$$
\frac{1}{|z'(t)|}
\int_0^{2\pi}
\partial_t P(z(t),z(\tau))\,\varphi'(\tau)\,d\tau,
$$
其中
$$
\partial_t P(z(t),z(\tau))
=
\nabla_x P(z(t),z(\tau))\cdot z'(t).
$$

因此定义两个光滑矩阵：
$$
\boxed{
(A_{21}^{P,a})_{ij}
=
h\,\frac{1}{s_i}
k_{\mathrm{out}}^2
P(z_i,z_j)
\big(z'_i\cdot z'_j\big),
}
$$
以及
$$
\boxed{
(B_{21}^{P})_{ij}
=
h\,\frac{1}{s_i}
\left[\nabla_x P(z_i,z_j)\cdot z'_i\right].
}
$$

则
$$
\boxed{
A_{21}^{P}
=
A_{21}^{P,a}
+
B_{21}^{P}D.
}
$$

最终
$$
\boxed{
A_{21}
=
A_{21}^{\mathrm{fs}}
+
A_{21}^{P}
=
(A+BD)
+
A_{21}^{P,a}
+
B_{21}^{P}D.
}
$$

也可以合并写成
$$
\boxed{
A_{21}
=
(A+A_{21}^{P,a})
+
(B+B_{21}^{P})D.
}
$$

其中：

- $A+BD$ 是自由空间差分
  $$
  T^{(k_{\mathrm{out}})}-T^{(k_{\mathrm{in}})}
  $$
  的 Kress 离散；
- $A_{21}^{P,a}$ 是 QP 光滑项中 $k_{\mathrm{out}}^2P$ 对应的积分；
- $B_{21}^{P}D$ 是 QP 光滑项中切向导数对应的积分。

由于 $P$ 是光滑函数，这两个 QP 修正矩阵都只需要普通周期梯形公式，不需要 Kress 对数权重。

如果 $P$ 不满足外部 Helmholtz 方程，或者无法确认上述等价形式成立，则应直接使用原始定义
$$
(T^P\mu)(x)
=
\frac{\partial}{\partial n_x}
\int_\Gamma
\frac{\partial P(x,y)}{\partial n_y}\mu(y)\,ds_y,
$$
并离散为
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
但对于由准周期 Green 函数减去自由空间 Green 函数得到的常见光滑修正项，通常更方便采用上面的
$$
A_{21}^{P,a}+B_{21}^{P}D
$$
形式。

---

### 5. 最终 TEP 矩阵的实现形式

记自由空间部分的离散块为
$$
A_{11}^{\mathrm{fs}},\quad
A_{12}^{\mathrm{fs}},\quad
A_{21}^{\mathrm{fs}},\quad
A_{22}^{\mathrm{fs}}.
$$

其中
$$
A_{21}^{\mathrm{fs}}=A+BD
$$
由前面 $T^{(k_{\mathrm{out}})}-T^{(k_{\mathrm{in}})}$ 的 Kress 离散给出。

QP 光滑修正项为
$$
A_{11}^{P},\quad A_{12}^{P},\quad A_{21}^{P},\quad A_{22}^{P}.
$$

于是算子块为
$$
\boxed{
\mathcal A_{11}
=
A_{11}^{\mathrm{fs}}+A_{11}^{P},
}
$$

$$
\boxed{
\mathcal A_{12}
=
A_{12}^{\mathrm{fs}}+A_{12}^{P},
}
$$

$$
\boxed{
\mathcal A_{21}
=
A_{21}^{\mathrm{fs}}+A_{21}^{P},
}
$$

$$
\boxed{
\mathcal A_{22}
=
A_{22}^{\mathrm{fs}}+A_{22}^{P}.
}
$$

最终 TEP 矩阵为
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

未知向量仍然采用
$$
\boxed{
\eta=
\begin{bmatrix}
\tau\\
-\sigma
\end{bmatrix}.
}
$$

因此在代码中应注意：

1. $A_{11}$ 和 $A_{22}$ 的单位矩阵项只加在最终 full matrix 的对角块中；
2. $A_{12}$ 和 $A_{21}$ 没有单位矩阵项；
3. $A_{21}$ 的自由空间部分应使用
   $$
   A+BD
   $$
   而不是单独的 Kress 矩阵；
4. QP 光滑项不改变任何对数奇异系数，也不改变 Kress 权重；
5. QP 光滑项全部通过普通周期梯形公式加入。

## D, D' 算子的 Kress 离散

Kress 1991 的式 (2.2) 把双层势方程写成
$$
\psi(t)-\int_0^{2\pi}
\{L_{\mathrm K}(t,\tau)+i\eta M(t,\tau)\}\psi(\tau)\,d\tau
=2g(t).
$$
这里特别注意：论文中的 \(K\) 和 \(S\) 算子本身带整体因子 \(2\)，并且式 (2.2) 中双层核以负号放在积分号前。因此 Kress 论文的 \(L_{\mathrm K}\) 不是本文的裸 source-normal double-layer kernel，而是
$$
L_{\mathrm K}^{(k)}(t,\tau)
=
-2\,
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_\tau}
|z'(\tau)|.
$$

本文采用裸归一化，所以定义
$$
D^{(k)}(t,\tau)
:=
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_\tau}
|z'(\tau)|
=
-\frac12 L_{\mathrm K}^{(k)}(t,\tau).
$$
这就是把 Kress 论文中的系数 \(2\) 和前置负号整理回本文 \(D\) 算子时必须保留的换算。

Kress 式 (2.5) 对 \(L_{\mathrm K}\) 作分裂：
$$
L_{\mathrm K}^{(k)}(t,\tau)
=
L_{\mathrm K,1}^{(k)}(t,\tau)
\,\log\!\left(4\sin^2\frac{t-\tau}{2}\right)
+L_{\mathrm K,2}^{(k)}(t,\tau).
$$
其中对 \(t\ne\tau\)，令 \(r(t,\tau)=|z(t)-z(\tau)|\)，有
$$
L_{\mathrm K,1}^{(k)}(t,\tau)
=
\frac{k}{2\pi}
\left\{
z_2'(\tau)\,[z_1(t)-z_1(\tau)]
-z_1'(\tau)\,[z_2(t)-z_2(\tau)]
\right\}
\frac{J_1(k r(t,\tau))}{r(t,\tau)},
$$
$$
L_{\mathrm K,2}^{(k)}(t,\tau)
=
L_{\mathrm K}^{(k)}(t,\tau)
-L_{\mathrm K,1}^{(k)}(t,\tau)
\,\log\!\left(4\sin^2\frac{t-\tau}{2}\right).
$$
因此本文的裸 \(D\) 核应使用
$$
D_1^{(k)}(t,\tau)=-\frac12 L_{\mathrm K,1}^{(k)}(t,\tau),
\qquad
D_2^{(k)}(t,\tau)=-\frac12 L_{\mathrm K,2}^{(k)}(t,\tau),
$$
再按标准 Kress 公式离散：
$$
(D_h^{(k)})_{ij}
=
R_{ij}^{(N)}D_1^{(k)}(t_i,t_j)
+hD_2^{(k)}(t_i,t_j),
\qquad h=\frac{2\pi}{N}.
$$

对角线上，Kress 给出
$$
L_{\mathrm K,2}^{(k)}(t,t)=L_{\mathrm K}^{(k)}(t,t)
=
\frac{1}{2\pi}
\frac{z_1'(t)z_2''(t)-z_2'(t)z_1''(t)}
{|z'(t)|^2}.
$$
因此本文裸归一化下
$$
D^{(k)}(t,t)
=
-\frac{1}{4\pi}
\frac{z_1'(t)z_2''(t)-z_2'(t)z_1''(t)}
{|z'(t)|^2},
$$
这也解释了为什么不同波数的自由空间 \(D\) 对角极限在差分中相互抵消。

对于 adjoint double-layer kernel，
$$
D^{(k)*}(t,\tau)
:=
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_t}
|z'(\tau)|,
$$
同样可以定义一个 Kress 归一化核
$$
L_{\mathrm K}^{(k)*}(t,\tau)=-2D^{(k)*}(t,\tau),
$$
然后完全同样地分裂和离散。也就是说，本文的 \(D'\) 或 \(D^*\) block 若借用 Kress 的 \(L\)-split，必须先做同一个换算：
$$
D^{(k)*}=-\frac12 L_{\mathrm K}^{(k)*}.
$$

换句话说，本文后续若写成
$$
(D_x^{(k)}\varphi)(t)
=
\int_0^{2\pi}
\frac{\partial \Phi_k(z(t),z(\tau))}{\partial n_t}
\varphi(\tau)\,|z'(\tau)|\,d\tau
=
\int_0^{2\pi}L_x^{(k)}(t,\tau)\varphi(\tau)\,d\tau,
$$
则这里的 \(L_x^{(k)}\) 是裸核
$$
L_x^{(k)}=D^{(k)*}=-\frac12 L_{\mathrm K}^{(k)*},
$$
而不是 Kress 论文式 (2.2) 中直接出现的 \(L_{\mathrm K}\)。source-normal 的 \(D^{(k)}\) 块同理。
