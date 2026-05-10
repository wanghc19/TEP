# Bloch mode selection 笔记

本文整理线性缺陷 / 空腔匹配问题中 Bloch mode selection 的符号、维数和判定规则。记号尽量与当前 `+bloch` package 保持一致，尤其是 `rayleigh_channels`、`construct_S`、`solve_modes` 和 `mode_traces` 中的符号。

本文只讨论一个方向上的周期 lead cell。`L/R` 始终表示 **一个 cell 的左壁 / 右壁**，不表示正负半轴。正负半轴只在需要讨论 left lead / right lead 时明确说明。

---

## 1. Rayleigh trace space 与 channel 数

固定 $y$ 方向周期 $d$ 和准周期参数 $\beta$。对截断阶数 $M$，定义

$$
m=-M,\ldots,M,
$$

并令

$$
K=2M+1.
$$

Rayleigh 横向波数为

$$
\beta_m=\beta+\frac{2\pi m}{d},
$$

Rayleigh 基底为

$$
\psi_m(y)=\frac{1}{\sqrt d}e^{\mathrm{i}\beta_m y}.
$$

外部背景波数记为 $k$。`+bloch/rayleigh_channels.m` 中对应的纵向波数为

$$
\gamma_m=\sqrt{k^2-\beta_m^2},
$$

并取 outgoing 分支。对实数 $k$，这通常写成

$$
\operatorname{Im}\gamma_m\ge 0,
$$

且当 $\gamma_m$ 为实数时取 $\gamma_m\ge 0$。

在 wall 上，Dirichlet trace 的离散空间由 $K$ 个 Rayleigh mode 张成。但是 Bloch mode 的完整截面状态不是只由 Dirichlet trace 决定，而是由 Cauchy data 决定，即由函数值和 $x$ 方向导数共同决定。因此离散状态空间维数通常是 $2K$。

在 Rayleigh amplitude 语言中，cell 左壁附近的场写为

$$
u(x,y)
=
\sum_m a_m^L e^{\mathrm{i}\gamma_m(x-X_L)}\psi_m(y)
+
\sum_m b_m^L e^{-\mathrm{i}\gamma_m(x-X_L)}\psi_m(y).
$$

其中：

- $a^L\in\mathbb C^K$ 是 cell 左壁上的 right-going amplitude；
- $b^L\in\mathbb C^K$ 是 cell 左壁上的 left-going amplitude。

因此一个 Bloch generalized eigenvector 写为

$$
V_j=
\begin{bmatrix}
a_j^L\\
b_j^L
\end{bmatrix}
\in\mathbb C^{2K}.
$$

所以，在未做 mode selection 前，离散 Bloch mode 的数量通常是

$$
2K.
$$

空 cell 是最简单的例子。若没有散射体，则每个 Rayleigh order 给出两个 Bloch multiplier：

$$
\lambda_m^\rightarrow=e^{\mathrm{i}\gamma_m L},
$$

$$
\lambda_m^\leftarrow=e^{-\mathrm{i}\gamma_m L}.
$$

因此总数为 $K+K=2K$。

---

## 2. Scattering matrix 与 Bloch generalized eigenproblem

`+bloch/construct_S.m` 构造一个 cell 的 scattering matrix：

$$
\begin{bmatrix}
b^L\\
a^R
\end{bmatrix}
=
S_{\mathrm{cell}}
\begin{bmatrix}
a^L\\
b^R
\end{bmatrix}
=
\begin{bmatrix}
R_L & T_{R\to L}\\
T_{L\to R} & R_R
\end{bmatrix}
\begin{bmatrix}
a^L\\
b^R
\end{bmatrix}.
$$

这里：

- $a^L$ 是左壁上的 right-going incoming amplitude；
- $b^R$ 是右壁上的 left-going incoming amplitude；
- $b^L$ 是左壁上的 left-going outgoing amplitude；
- $a^R$ 是右壁上的 right-going outgoing amplitude。

Bloch condition 是

$$
a^R=\lambda a^L,
$$

$$
b^R=\lambda b^L.
$$

令

$$
a=a^L,\qquad b=b^L,
$$

则

$$
b^R=\lambda b,\qquad a^R=\lambda a.
$$

代入 scattering relation 得到

$$
b=R_La+\lambda T_{R\to L}b,
$$

$$
\lambda a=T_{L\to R}a+\lambda R_Rb.
$$

整理得广义特征值问题：

$$
A_{\mathrm{sc}}
\begin{bmatrix}
a\\
b
\end{bmatrix}
=
\lambda
B_{\mathrm{sc}}
\begin{bmatrix}
a\\
b
\end{bmatrix},
$$

其中

$$
A_{\mathrm{sc}}
=
\begin{bmatrix}
-R_L & I\\
T_{L\to R} & 0
\end{bmatrix},
\qquad
B_{\mathrm{sc}}
=
\begin{bmatrix}
0 & T_{R\to L}\\
I & -R_R
\end{bmatrix}.
$$

`+bloch/solve_modes.m` 正是求解这个 generalized eigenproblem。输出的 `modes.lambda` 是 Floquet multipliers，`modes.V` 的列向量按

$$
V_j=
\begin{bmatrix}
a_j^L\\
b_j^L
\end{bmatrix}
$$

排列。

---

## 3. Cell wall trace 的定义

`+bloch/mode_traces.m` 从 $\lambda_j$ 和 $V_j=[a_j^L;b_j^L]$ 计算 cell 左右壁上的 trace。

对第 $j$ 个 mode，左壁 Dirichlet trace 系数定义为

$$
u_j(X_L,y)=\sum_m D_L(m,j)\psi_m(y),
$$

其中

$$
D_L(m,j)=a_L(m,j)+b_L(m,j).
$$

左壁 $x$ 方向导数 trace 系数定义为

$$
\partial_x u_j(X_L,y)=\sum_m N_L(m,j)\psi_m(y),
$$

其中

$$
N_L(m,j)=\mathrm{i}\gamma_m\left(a_L(m,j)-b_L(m,j)\right).
$$

右壁 amplitudes 由 Bloch condition 给出：

$$
a_R(m,j)=\lambda_j a_L(m,j),
$$

$$
b_R(m,j)=\lambda_j b_L(m,j).
$$

右壁 Dirichlet trace 系数为

$$
D_R(m,j)=a_R(m,j)+b_R(m,j),
$$

右壁 $x$ 方向导数 trace 系数为

$$
N_R(m,j)=\mathrm{i}\gamma_m\left(a_R(m,j)-b_R(m,j)\right).
$$

因此必有

$$
D_R(:,j)=\lambda_jD_L(:,j),
$$

$$
N_R(:,j)=\lambda_jN_L(:,j).
$$

这里的 $N_L,N_R$ 是 $\partial_x u$ 的 trace 系数，不是 positive/negative half-lead 的 outward normal derivative。真正接到正半轴或负半轴时，才需要根据端口外法向添加符号。

---

## 4. 实数 $k$ 情形下的 mode selection

先考虑无吸收的实数频率

$$
k\in\mathbb R.
$$

对实数 $k$，Rayleigh 纵向波数 $\gamma_m$ 有两类：

1. **propagating orders**

   $$
   \gamma_m\in\mathbb R,\qquad \gamma_m\ge 0.
   $$

   对应 Rayleigh wave 不在 $x$ 方向衰减。

2. **evanescent orders**

   $$
   \gamma_m=\mathrm{i}\alpha_m,\qquad \alpha_m>0.
   $$

   对应 right-going 因子

   $$
   e^{\mathrm{i}\gamma_m x}=e^{-\alpha_m x}
   $$

   在 $x\to+\infty$ 方向衰减。

在周期 lead 中，Bloch multipliers $\lambda_j$ 替代了单个 Rayleigh mode 的 $e^{\mathrm{i}\gamma_m L}$。若 $\lambda$ 表示从 cell 左壁推进到右壁的 multiplier，则：

- positive half-lead，即 $x\to+\infty$ 方向，衰减 outgoing mode 满足

  $$
  |\lambda_j|<1.
  $$

- negative half-lead，即 $x\to-\infty$ 方向，衰减 outgoing mode 满足

  $$
  |\lambda_j|>1.
  $$

这是因为向左走一个 cell 等价于乘以 $\lambda_j^{-1}$。

对于实数 $k$，若存在 propagating Bloch modes，则它们通常满足

$$
|\lambda_j|=1.
$$

这时不能用 $|\lambda|<1$ 或 $|\lambda|>1$ 区分左右 outgoing。需要计算能流或 group velocity。一个典型的能流判据是

$$
\mathcal F_x
=
\operatorname{Im}\int_0^d
\overline{u(y)}\,\partial_x u(y)\,dy.
$$

在 trace 系数中，如果

$$
D=a+b,
$$

$$
N=\mathrm{i}\gamma_m(a-b),
$$

则可以用离散内积近似

$$
\mathcal F_x
\sim
\operatorname{Im}\sum_m \overline{D_m}N_m.
$$

当 $\mathcal F_x>0$ 时，该 propagating Bloch mode 向右传输能量；当 $\mathcal F_x<0$ 时，该 mode 向左传输能量。

不过在第一阶段实现中，可以先避免实频率传播 mode 选择问题，只在 band gap 或 light cone 下方工作，或者使用复数频率 regularization。

---

## 5. 复数 $k$ 情形下的 mode selection

为了避免实频率下的传播 mode 和 possible pole，可以引入吸收：

$$
k_\epsilon=k+\mathrm{i}\epsilon,
\qquad \epsilon>0.
$$

对 outgoing convention $e^{\mathrm{i}kr}$，有

$$
e^{\mathrm{i}(k+\mathrm{i}\epsilon)r}
=
e^{\mathrm{i}kr-\epsilon r},
$$

所以 outgoing wave 会衰减。

此时

$$
\gamma_m=\sqrt{k_\epsilon^2-\beta_m^2}
$$

通常是一般复数，而不是纯实数或纯虚数。只要取 outgoing 分支，即

$$
\operatorname{Im}\gamma_m\ge 0,
$$

right-going Rayleigh wave

$$
e^{\mathrm{i}\gamma_m x}
$$

就在 $x\to+\infty$ 衰减。

对于 Bloch multipliers，也会出现类似效果：原本实频率下可能在单位圆上的 propagating multipliers 被推出单位圆。因此 mode selection 可以直接使用：

- positive half-lead outgoing / decaying modes:

  $$
  \mathcal I^+=\{j:|\lambda_j|<1-\mathrm{tol}\}.
  $$

- negative half-lead outgoing / decaying modes:

  $$
  \mathcal I^-=\{j:|\lambda_j|>1+\mathrm{tol}\}.
  $$

在数值实现中，`+bloch/solve_modes.m` 已经给出 preliminary classification：

$$
\texttt{right\_decay}:\quad |\lambda|<1-\texttt{tol},
$$

$$
\texttt{left\_decay}:\quad |\lambda|>1+\texttt{tol},
$$

$$
\texttt{neutral}:\quad \left||\lambda|-1\right|\le \texttt{tol}.
$$

需要强调：这些分类是相对于正 $x$ 方向 cell multiplier 的初步分类。真正用于 half-lead matching 时，还要根据正 / 负半轴选择对应 wall trace 和法向符号。

在 $\epsilon>0$ 且避开病态点时，通常预期有大约

$$
K
$$

个 $|\lambda|<1$ 的 modes，以及大约

$$
K
$$

个 $|\lambda|>1$ 的 modes。

---

## 6. Half-lead port trace selection

`mode_traces` 给出的 $D_L,N_L,D_R,N_R$ 是一个 cell 左右壁的 trace。它还没有决定这个 cell 接到 negative lead 还是 positive lead。

下面讨论如何把这些 cell traces 转换成 half-lead outgoing port traces。

本节采用如下符号约定：

- 下标 $L,R$ 只表示单个 lead cell 的左壁和右壁；
- 上标 $+,-$ 表示正 / 负 half-lead，也表示中心区域的右 / 左端口。

### 6.1 Positive lead

$$
\text{center positive port} \longleftrightarrow \text{positive lead cell left wall}.
$$

因此使用 cell 左壁 trace $D_L,N_L$。positive lead 向 $+x$ 延伸，outgoing / decaying mode 选择

$$
\mathcal I^+=\{j:|\lambda_j|<1\}.
$$

因此

$$
D_{\mathrm{out}}^+
=
D_L(:,\mathcal I^+),
$$

$$
N_{\mathrm{out}}^+
=
N_L(:,\mathcal I^+).
$$

这里中心区域正端口的外法向是 $+e_x$，所以 outward normal derivative 就是 $\partial_x$，没有额外负号。

### 6.2 Negative lead

$$
\text{center negative port} \longleftrightarrow \text{negative lead cell right wall}.
$$

因此使用 cell 右壁 trace $D_R,N_R$。negative lead 向 $-x$ 延伸，outgoing / decaying mode 选择

$$
\mathcal I^-=\{j:|\lambda_j|>1\}.
$$

Dirichlet trace 为

$$
D_{\mathrm{out}}^-
=
D_R(:,\mathcal I^-).
$$

但是中心区域负端口的外法向是 $-e_x$，而 `mode_traces` 中的 $N_R$ 是 $\partial_x u$，所以 outward normal derivative 需要加负号：

$$
N_{\mathrm{out}}^-
=
-N_R(:,\mathcal I^-).
$$

因此：

$$
D_{\mathrm{out}}^-=D_R(:,|\lambda|>1),
\qquad
N_{\mathrm{out}}^-=-N_R(:,|\lambda|>1).
$$

$$
D_{\mathrm{out}}^+=D_L(:,|\lambda|<1),
\qquad
N_{\mathrm{out}}^+=N_L(:,|\lambda|<1).
$$

这一层逻辑建议单独写成函数，例如

```matlab
[D_out, N_out, selected] = bloch.select_port_traces(modes, traces, portSign, opts)
```

其中 `portSign` 可以取 `'-'` 或 `'+'`。

---

## 7. Missing-column / empty-defect-cell 问题中的使用方式

在完美二维周期晶体中挖掉中间一列介质柱后，中心空腔区域没有介质柱边界，因此不需要中心 cell 的 Müller 矩阵。中心区域可以直接用 Rayleigh 展开：

$$
u_0(x,y)
=
\sum_m c_m^+ e^{\mathrm{i}\gamma_m(x-X_0^-)}\psi_m(y)
+
\sum_m c_m^- e^{-\mathrm{i}\gamma_m(x-X_0^-)}\psi_m(y).
$$

这里 $c_m^+$ 和 $c_m^-$ 仍表示中心空腔中的 right-going / left-going Rayleigh amplitude，不表示正 / 负 half-lead。中心负端口 outward normal 是 $-e_x$，中心正端口 outward normal 是 $+e_x$。令

$$
E=\operatorname{diag}(e^{\mathrm{i}\gamma_m L_0}),
\qquad
L_0=X_0^+-X_0^-.
$$

中心空腔负端口 trace 为

$$
D_0^-=c^+ + c^-,
$$

$$
N_0^-
=
-\mathrm{i}\gamma_m(c^+ - c^-),
$$

这里 $N_0^-$ 是中心区域负端口的 outward normal trace，因此有负号。

中心空腔正端口 trace 为

$$
D_0^+=E c^+ + E^{-1}c^-,
$$

$$
N_0^+
=
\mathrm{i}\gamma_m(Ec^+ - E^{-1}c^-).
$$

与正负 half-lead outgoing traces 匹配：

$$
D_0^-=D_{\mathrm{out}}^- a^-,
$$

$$
N_0^-=N_{\mathrm{out}}^- a^-,
$$

$$
D_0^+=D_{\mathrm{out}}^+ a^+,
$$

$$
N_0^+=N_{\mathrm{out}}^+ a^+.
$$

设 Rayleigh 截断阶数为 $M$，则

$$
K=2M+1.
$$

中心空腔中的两个 Rayleigh 系数向量满足

$$
c^+,c^-\in\mathbb C^K.
$$

经过 mode selection 后，负 half-lead 与正 half-lead 中被保留的 outgoing Bloch mode 个数分别记为

$$
K^-_{\mathrm{out}}=\dim a^-,
\qquad
K^+_{\mathrm{out}}=\dim a^+.
$$

因此

$$
a^-\in\mathbb C^{K^-_{\mathrm{out}}},
\qquad
a^+\in\mathbb C^{K^+_{\mathrm{out}}}.
$$

对应地，

$$
D_{\mathrm{out}}^-,N_{\mathrm{out}}^-\in\mathbb C^{K\times K^-_{\mathrm{out}}},
$$

$$
D_{\mathrm{out}}^+,N_{\mathrm{out}}^+\in\mathbb C^{K\times K^+_{\mathrm{out}}}.
$$

总未知量为

$$
\begin{bmatrix}
c^+\\
c^-\\
a^-\\
a^+
\end{bmatrix}
\in
\mathbb C^{2K+K^-_{\mathrm{out}}+K^+_{\mathrm{out}}}.
$$

四组匹配条件分别是负端口 Dirichlet、负端口 Neumann、正端口 Dirichlet、正端口 Neumann，每组都有 $K$ 个 Rayleigh 系数方程，因此总方程数为 $4K$。

于是得到维数为

$$
4K \times \left(2K+K^-_{\mathrm{out}}+K^+_{\mathrm{out}}\right)
$$

的齐次矩阵系统：

$$
\begin{bmatrix}
I & I & -D_{\mathrm{out}}^- & 0\\
-\mathrm{i}\Gamma & \mathrm{i}\Gamma & -N_{\mathrm{out}}^- & 0\\
E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
\mathrm{i}\Gamma E & -\mathrm{i}\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}
\begin{bmatrix}
c^+\\
c^-\\
a^-\\
a^+
\end{bmatrix}
=0,
$$

其中

$$
\Gamma=\operatorname{diag}(\gamma_m).
$$

这个系统的非平凡解对应 missing-column cavity mode。此问题不是原来的 TEP，而是一个空腔 / 缺陷模态问题。

在理想的吸收参数或带隙情形下，通常有

$$
K^-_{\mathrm{out}}\approx K,
\qquad
K^+_{\mathrm{out}}\approx K,
$$

此时该矩阵近似为 $4K\times4K$ 的方阵。若由于传播模态、数值阈值或截断选择导致 $K^-_{\mathrm{out}}$ 与 $K^+_{\mathrm{out}}$ 不等于 $K$，则该系统一般是矩形齐次系统，应通过最小奇异值判断是否存在非平凡解。

---

## 8. 数值注意事项

1. **未选择前 mode 数是 $2K$。**  
   Dirichlet trace 空间是 $K$ 维，但 Cauchy data / amplitude 状态空间是 $2K$ 维。

2. **selection 后每侧约为 $K$ 个 mode。**  
   对 $k+\mathrm{i}\epsilon$ 且避开病态点，通常 $|\lambda|<1$ 和 $|\lambda|>1$ 各约 $K$ 个。

3. **实数 $k$ 下单位圆 mode 需要能流判定。**  
   如果存在 $|\lambda|=1$ 的传播 mode，不能只按 $|\lambda|$ 选择。

4. **复数 $k$ 是第一阶段更稳健的选择。**  
   使用 $k+\mathrm{i}\epsilon$ 可以把传播 modes 推离单位圆，从而简化 outgoing selection。

5. **trace 中的 $N_L,N_R$ 不是 half-lead 法向导数。**  
   它们只是 cell wall 上的 $\partial_x u$ trace。接入中心负端口时需要额外负号。

6. **mode ordering 不可靠。**  
   `eig` 返回的 mode 顺序任意，选择和匹配都应基于 $\lambda$ 的数值分类，而不是 index。

7. **要保留 diagnostic 信息。**  
   对每个 mode 应检查 generalized eigenpair residual：

   $$
   \frac{
   \|A_{\mathrm{sc}}V_j-\lambda_jB_{\mathrm{sc}}V_j\|
   }{
   \max(1,\|A_{\mathrm{sc}}V_j\|,\|B_{\mathrm{sc}}V_j\|)
   }.
   $$

8. **接近 band edge 或 exceptional point 时可能病态。**  
   若存在重复 $\lambda$ 或接近不可对角化的 pencil，普通 eigenvectors 可能不稳定。第一阶段可以避开这些点，后续再考虑 invariant subspace 或 generalized Bloch chains。

---

## 9. 与当前 `+bloch` package 的对应关系

当前代码中的自然流程是：

```matlab
rayleighchan = bloch.rayleigh_channels(k, beta, d, M, L);

S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
                           rayleighchan, X_L, X_R);

modes = bloch.solve_modes(S_cell, opts);

traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);
```

其中：

- `rayleigh_channels` 定义 $m,\beta_m,\gamma_m,\mathrm{phase}$；
- `construct_S` 构造 $S_{\mathrm{cell}}$；
- `solve_modes` 解 $A_{\mathrm{sc}}V=\lambda B_{\mathrm{sc}}V$；
- `mode_traces` 构造 $D_L,N_L,D_R,N_R$；
- 后续应新增 `select_port_traces` 来完成 half-lead outgoing trace selection。
