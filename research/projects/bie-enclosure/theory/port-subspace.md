# 引线衰减子空间的维数与无 Dirichlet 极点的端口匹配

进度

- done　引理 A 与定理 B 的有限维结论均已证明，P2 与 P4 的代码和已有数值记录已核对。
- next　审查式 (10) 的全离散判据及式 (19)–(24) 的消元条件。实算可在原有 P4 频点验证 (10)。
- open　当前算例尚缺通量缺陷与圆周分离量的可靠数值、组装的全纯延拓证明及连续模式重数对应。

port-subspace 指端口上的引线状态子空间。BIE 为边界积分方程，DtN 为 Dirichlet-to-Neumann 映射，QZ 为广义 Schur 分解。模式为 Proof from scratch。

## 1. 设置与编号假设

使用 `draft/bie-solver/sec-method.tex` 的 `eq:pencil`、`eq:nep` 和 `eq:port-matrix`。引理 A 对**每一条引线自己的一个完整周期**分别应用。左引线朝负 $x$ 方向延拓，右引线朝正 $x$ 方向延拓。下面 $*$ 表示共轭转置，矩阵范数为诱导的 Euclidean 二范数。用 $\mathsf J_f$ 表示通量矩阵，草稿的 $J(k)=\mathsf A_0(k)$ 专指中心传输方程。

1. **实频和界面。** $k>0$、$\beta\in\mathbb R$、周期 $d>0$，背景 $\rho_{\mathrm e}>0$，各材料分片内 $\rho$ 为实常数。胞元为一个纵向周期乘 $I_d=(-d/2,d/2)$，材料界面为与胞元边界正分离的 $C^2$ 曲线。精确场 $u$ 属于胞元上的 $H^1$，在每个分片直到边界属于 $H^2$，并满足 $-\Delta u=k^2\rho u$。材料界面两侧的值和同向法向导数连续，上下端的值和 $y$ 导数具有同一相位 $e^{\mathrm i\beta d}$。端口位于均匀开带内，值和导数迹属于 $L^2(I_d)$，其内积等于 Fourier 系数内积。
2. **截断和单胞问题。** $m\in\mathbb Z$，$M$ 为非负整数，$K=2M+1$。保留 $|m|\le M$，$\beta_m=\beta+2\pi m/d$，$\gamma_m^2=k^2\rho_{\mathrm e}-\beta_m^2$。实频取正实或正虚的根。假设所有传播阶都已保留，所有删去阶均严格倏逝。下文正常情形还要求每个保留阶 $\gamma_m\ne0$。给定保留的入射向量 $h=(a_{\mathrm L},b_{\mathrm R})\in\mathbb C^{2K}$，删去阶的入射振幅置零。假设此精确散射问题可解，保留的出射振幅是 $h$ 的单值线性函数。需要从系数重建唯一胞元场时，还要求选定的内部求解有唯一重建。实 $k$ 和实 $\rho$ 本身不足以保证单胞问题的可解性。
3. **铅笔。** 以各墙为振幅锚点，$z_{\mathrm L}=(a_{\mathrm L},b_{\mathrm L})$、$z_{\mathrm R}=(a_{\mathrm R},b_{\mathrm R})$ 都按正 $x$ 方向定义上下两块。一个胞元的散射矩阵和相容条件为

   $$
   \binom{b_{\mathrm L}}{a_{\mathrm R}}=
   \begin{bmatrix}R_{\mathrm L}&T_{\mathrm{RL}}\\T_{\mathrm{LR}}&R_{\mathrm R}\end{bmatrix}h,\qquad
   \mathsf E_{\mathrm L}z_{\mathrm L}=\mathsf E_{\mathrm R}z_{\mathrm R},\qquad
   \mathsf E_{\mathrm L}=\begin{bmatrix}-R_{\mathrm L}&I\\T_{\mathrm{LR}}&0\end{bmatrix},\quad
   \mathsf E_{\mathrm R}=\begin{bmatrix}0&T_{\mathrm{RL}}\\I&-R_{\mathrm R}\end{bmatrix}.
   \tag{1}
   $$

   正则指 $\det(\mathsf E_{\mathrm L}-\zeta\mathsf E_{\mathrm R})$ 不恒为零。带隙维数结论要求这个 $2K$ 阶有限铅笔正则，并在 $\lvert\zeta\rvert=1$ 上处处可逆。按铅笔的阶数计入 $\zeta=\infty$ 的代数重数。连续引线的带隙与这一有限铅笔的条件是分别需要建立的事实。此模型只在相邻胞元间传递保留阶。
4. **中心和半引线。** 中心未知量 $\xi=(\eta,a^-_0,b^+_0)\in\mathbb C^{n+2K}$，其中 $\eta$ 为草稿的双层密度与负单层密度的离散列，空中心取 $n=0$。矩阵 $\mathsf A_0\in\mathbb C^{n\times(n+2K)}$ 给出全部中心传输行。令 $L_0=x_+-x_-$、$\mathsf E(\ell)=\operatorname{diag}(e^{\mathrm i\gamma_m\ell})$。$\mathsf F^\leftarrow_{x_-}$、$\mathsf F^\rightarrow_{x_+}$ 把密度映到两墙的散射出射振幅。中心两端的**总**状态为

   $$
   \mathsf Y_-\xi=\binom{a^-_0}{\mathsf F^\leftarrow_{x_-}\eta+\mathsf E(L_0)b^+_0},\qquad
   \mathsf Y_+\xi=\binom{\mathsf F^\rightarrow_{x_+}\eta+\mathsf E(L_0)a^-_0}{b^+_0}.
   \tag{2}
   $$

   两侧 $\mathsf Z_s\in\mathbb C^{2K\times K}$ 满列秩，分别张成朝该侧无穷远衰减的全部右偏转子空间（right deflating subspace）。对理想截断铅笔，这一列数由引理 A 给出。对给定全离散矩阵，可独立检验该列数。定理 B 的“离散导模”指中心系数解及其平方可和的两侧端口状态列，与 `eq:nep` 的定义一致。
5. **局部解析性。** 仅在讨论复频行列式时，要求 $k_0$ 有一个复开邻域，固定几何、阶数、矩阵大小，选定 $\gamma_m$ 的局部全纯分支。两侧铅笔及 $\mathsf A_0,\mathsf Y_s$ 的条目在该邻域全纯，分离所选簇的固定围道上铅笔可逆。计算 $\mathsf N_s\mathsf D_s^{-1}$ 的亚纯延拓时，还要求 $\det\mathsf D_s$ 在所论连通邻域不恒为零。中心密度块的可逆性只在使用消元后的中心矩阵时加入。

## 2. 引理 A　实频通量与衰减空间维数

**引理 A（在假设 1–3 下已证明）。** 保留阶的通量矩阵 $\mathsf J_f$ 非退化，正、负惯性指数各为 $K$。对同一铅笔，向右衰减和向左衰减的右偏转子空间均为 $\mathsf J_f$-中性，维数均为 $K$。中性指 $v^*\mathsf J_f w=0$ 对子空间中任意 $v,w$ 成立。允许零、无穷以及具有非平凡 Jordan 链的乘子。

**证明一　墙上的通量。** 取 $\psi_m=d^{-1/2}e^{\mathrm i\beta_m y}$。在长度为 $d$ 的周期区间上 $\int\bar\psi_m\psi_n\,dy=\delta_{mn}$。第 $m$ 阶在参考墙 $x=x_w$ 上的值、正 $x$ 导数系数为 $a_m+b_m$、$\mathrm i\gamma_m(a_m-b_m)$。因此

$$
\operatorname{Im}\big[(\bar a_m+\bar b_m)\,\mathrm i\gamma_m(a_m-b_m)\big]
=\begin{cases}
\gamma_m(|a_m|^2-|b_m|^2),&\gamma_m>0,\\
2\kappa_m\operatorname{Im}(\bar a_m b_m),&\gamma_m=\mathrm i\kappa_m,\ \kappa_m>0 .
\end{cases}
\tag{3}
$$

第一式取 $(\bar a+\bar b)(a-b)$ 的实部。第二式取 $\kappa(\bar a+\bar b)(b-a)$ 的虚部。两阶间交叉项由正交性消失。记 $\boldsymbol\gamma=\operatorname{diag}(\gamma_m)$，$u_M$ 为保留阶的场。其正 $x$ 通量及相应 Hermitian 形式分别为 $\Phi_f(z)$ 和 $(z,w)\mapsto z^*\mathsf J_f w$，其中

$$
\Phi_f(z)=\operatorname{Im}\int_{I_d}\overline{u_M(x_w,y)}\,\partial_xu_M(x_w,y)\,dy
=z^*\mathsf J_f z,\qquad
\mathsf J_f=\begin{bmatrix}
 \operatorname{Re}\boldsymbol\gamma&-\mathrm i\operatorname{Im}\boldsymbol\gamma\\
 \mathrm i\operatorname{Im}\boldsymbol\gamma&-\operatorname{Re}\boldsymbol\gamma
\end{bmatrix}.
\tag{4}
$$

每个 $2\times2$ 块的特征值为 $\pm|\gamma_m|$。墙的外法向为 $-e_x$ 时，外向通量等于 $-\Phi_f$。把**同一个场**的锚点从 $x_w$ 移到 $x_w+\ell$ 时，$(a,b)$ 变为 $(\mathsf E(\ell)a,\mathsf E(-\ell)b)$。传播阶的两个模长不变，倏逝阶的乘积 $\bar a_m b_m$ 不变。入射的两束分别从左右墙向内传播距离 $L$ 时，直接透射项则各含一次 $\mathsf E(L)$。这两种相位关系说明式 (3) 适用于代码在各自墙上保存的状态，且没有额外因子 $d$。

**证明二　从无限阶散射到有限端口关系。** 对一个精确场逐片作 Green 积分。体积分 $\int(|\nabla u|^2-k^2\rho|u|^2)$ 为实数。材料界面项因两侧迹匹配而相消，上下边界项因准周期相位的模为一而相消。因此两竖墙上 $\operatorname{Im}\int\bar u\,\partial_xu\,dy$ 相等。即使保留入射含向胞元外增长的倏逝解，这一证明也只在有限胞元内积分。对完整 Fourier 迹取内积可逐阶求和，收敛由两迹的 $L^2$ 范数与 Cauchy–Schwarz 保证。

在左墙，每个删去阶只有 $b_{\mathrm L,m}$，在右墙只有 $a_{\mathrm R,m}$。由 (3) 两者各自通量为零。保留的低阶倏逝波仍可能同时有两种振幅，必须保留其交叉项。这一步使用了单柱散射问题的零高阶入射条件。若直接截取一个无限阶 Bloch 场的端口数据，其高阶也可能有两个振幅，通量仍应按 (3) 计算。引入两个从同一个入射向量到总状态的矩阵

$$
G_{\mathrm L}=\begin{bmatrix}I&0\\ R_{\mathrm L}&T_{\mathrm{RL}}\end{bmatrix},\qquad
G_{\mathrm R}=\begin{bmatrix}T_{\mathrm{LR}}&R_{\mathrm R}\\0&I\end{bmatrix}.
\tag{5}
$$

式 (1) 的全部相容对恰是 $(G_{\mathrm L}h,G_{\mathrm R}h)$。事实上从任一相容对取左墙上块与右墙下块就还原 $h$，(1) 的两行给出余下两块。因此对所有 $h$ 均有两端保留通量相等。极化这个 Hermitian 二次型恒等式得到

$$
G_{\mathrm R}^*\mathsf J_f G_{\mathrm R}
=G_{\mathrm L}^*\mathsf J_f G_{\mathrm L}.
\tag{6}
$$

它直接适用于散射铅笔的相容状态，尤其容许传输块奇异。

**证明三　广义衰减方向也中性。** 以下对同一引线写 $A=\mathsf E_{\mathrm L}, B=\mathsf E_{\mathrm R}$。选单位圆上一个正则值 $\omega$，置 $T=(A-\omega B)^{-1}B$。正则铅笔仅有有限多个有限特征值，故有这样的 $\omega$。分解式

$$
A-\zeta B=(A-\omega B)[I-(\zeta-\omega)T]
\tag{7}
$$

把右偏转空间化成普通矩阵 $T$ 的广义特征空间直和。$T$ 的非零特征值 $t$ 对应 $\zeta=\omega+1/t$，零特征值的整个广义空间对应 $\infty$。对非零 $t$，在该块上右乘可逆常矩阵 $T^{-1}$ 即得到普通矩阵 $\omega I+T^{-1}$ 的铅笔。零特征值块为幂零块，对所有有限 $\zeta$ 的行列式为一，缺少的次数就是无穷乘子的代数重数。由普通矩阵的 Jordan 分解，各块总维数为 $2K$。

取 $T$ 的这些不变空间各自的基 $Z$，写 $TZ=ZT_Z$。对 $|\zeta|<1$ 块，$T_Z$ 可逆，$P=\omega I+T_Z^{-1}$ 满足 $AZ=BZP$。对 $|\zeta|>1$ 或 $\zeta=\infty$ 块，$I+\omega T_Z$ 可逆，$P_{\rm rev}=(I+\omega T_Z)^{-1}T_Z$ 满足 $BZ=AZP_{\rm rev}$。后者的特征值为 $1/\zeta$，其中 $1/\infty=0$。两种朝外传播矩阵的谱半径都小于一。对任取介于谱半径与一之间的 $r$，Jordan 块的二项展开给出 $\|P^j\|\le C_r r^j$，反向矩阵同理。非零特征值的多项式因子被 $r^j$ 吸收，零特征值的块在有限步后为零。

正向块上的两列 $z_j=ZP^j c$、$w_j=ZP^j e$ 构成相容序列。(6) 给出 $z_j^*\mathsf J_f w_j=z_{j+1}^*\mathsf J_f w_{j+1}$。令 $j\to\infty$ 得 $z_0^*\mathsf J_f w_0=0$。反向块用 $P_{\rm rev}$ 从右墙向左墙逐次应用同一等式。这样得到两整个偏转空间的中性，包含所有广义特征向量。

这两个空间也恰好给出相应半线的所有平方可和状态。例如在右半线，将递推 $(I+\omega T)z_j=Tz_{j+1}$ 投影到外部乘子块。其分量满足 $w_j=P_{\rm rev}^\ell w_{j+\ell}$。平方可和序列有界，右端趋于零，故每个 $w_j=0$。剩余正向块由 $z_0$ 唯一确定，且指数衰减。左半线交换铅笔次序即可。这里的不稳定空间须取反向铅笔的稳定**右**空间，正向 QZ 已选列的 Euclidean 正交补一般是另一空间。

**证明四　维数。** 在 $\mathsf J_f$ 的正负谱空间中分别乘上 $|\mathsf J_f|^{1/2}$ 后，通量成为 $\|p\|^2-\|q\|^2$，$p,q\in\mathbb C^K$。在任一中性子空间，取正坐标 $p$ 的映射单射，因为 $p=0$ 蕴含 $q=0$。因此每个中性子空间维数至多为 $K$。假设 3 排除了单位圆上的第三类块，正、反向两个空间直和的维数为 $2K$，故二者各为 $K$。证明完毕。

### 单位圆、Wood 点和漏掉的传播阶

**带内结论（在单位模乘子半单时已证明）。** 保留 (6)、非退化通量和正则铅笔，允许单位模乘子。设单位圆上的每个乘子均半单，即其广义空间由普通特征向量张成。则向右衰减方向加上每个单位模特征空间中选取的最大正通量子空间，共 $K$ 维。向左使用衰减方向和负通量子空间，维数也为 $K$。所选正、负通量特征向量生成的单位模序列范数恒定，分别向两侧的无穷远传能。

证明。若 $\zeta$、$\nu$ 为两个不同的单位模乘子，(6) 给出 $(1-\bar\zeta\nu)v^*\mathsf J_f w=0$，故它们的特征空间互相通量正交。各单位模序列在两个方向均有界。将其与正向、反向衰减序列分别配对并取极限，得到与两衰减空间均通量正交。故单位模各特征空间及正反向衰减空间之和构成通量正交直和，后一项在此作为一个整体。全形式非退化，故这些直和项上的限制都非退化。正反向两空间各自中性，其和上的 Gram 矩阵形如 $\left[\begin{smallmatrix}0&H\\H^*&0\end{smallmatrix}\right]$。非退化迫使 $H$ 方且可逆，所以两者维数同为某个 $h$，合并后的惯性为 $(h,h)$。剩余单位模特征空间上的正负惯性合计各为 $K-h$。逐特征值对限制的 Hermitian 形式取正、负基，组合即得结论。取正方向是在每个特征空间选一个正定子空间，混合符号重特征值时这一选择可有多个。将所选空间进一步与特定连续问题的极限吸收辐射条件等同，需要另证。证毕。

半单条件确实有作用。取单个传播通道，归一化 $\mathsf J_f=\operatorname{diag}(1,-1)$。传递矩阵

$$
T_b=\begin{bmatrix}1+\mathrm i&1\\1&1-\mathrm i\end{bmatrix}
$$

满足 $T_b^*\mathsf J_f T_b=\mathsf J_f$，行列式一，迹二。其唯一特征线由 $(1,-\mathrm i)^T$ 张成，通量为零。它没有衰减或正通量特征线。由于 $(T_b)_{22}\ne0$，从 $z_{\mathrm R}=T_bz_{\mathrm L}$ 解出 $b_{\mathrm L},a_{\mathrm R}$ 即得到 (1) 形式的正则散射铅笔。这一代数例子说明，在允许单位圆 Jordan 块的带边，单凭签名得不出所述出射计数。

在保留的 Wood 阶 $\gamma_m=0$，两指数波重合，(4) 的该块为零，$\mathsf C_\pm$ 也丢秩。阈值 ODE 的完整解为 $q+p(x-x_w)$，其通量为 $\operatorname{Im}(\bar q p)$。重新取此基可以表示完整 Cauchy 数据，但阈值散射条件和含 $1/\gamma_m$ 的提取公式需要相应修改。若阈值阶被删去，也需要单独规定阈值解和辐射条件，假设 2 已排除此情形。

若删去严格传播阶，取其入射仍为零。由 (3) 及完整通量守恒，

$$
\Phi_f(z_{\mathrm R})-\Phi_f(z_{\mathrm L})
=-\sum_{\text{删去的传播阶 }m}\gamma_m
  \big(|a_{\mathrm R,m}|^2+|b_{\mathrm L,m}|^2\big).
\tag{8}
$$

只有这些出射分量对每个保留入射都为零时，式 (6) 的无损恒等式才仍成立。这里还能证明一个较强的计数结论。若保持这种**纯出射**删减、保留通量非退化、铅笔正则且无单位模乘子，则计数仍为 $K$。事实上式 (8) 表明通量沿正 $x$ 单调不增，在向右衰减列上其极限为零，故初始通量非负。在反向衰减列上初始通量非正。正坐标投影在非负子空间上单射，负坐标投影在非正子空间上单射，所以两维数分别至多为 $K$，再用直和即得各为 $K$。此时中性一般丢失，模型通过被删传播阶泄能。仅凭计数无法识别这种遗漏，也不能据此把有损截断的带隙判定转给物理引线。若删去阶还允许独立入射分量，则 (8) 的符号也需重新检查。

### 全离散通量缺陷的充分判据

**引理 A 的扰动结论（已证明）。** 现在把实际组装的四个散射块视为给定有限矩阵。按 (1)、(5) 组成 $A,B,G_{\mathrm L},G_{\mathrm R}$，取非退化的物理通量矩阵 (4)。定义通量缺陷与单位圆分离量

$$
F=G_{\mathrm R}^*\mathsf J_fG_{\mathrm R}
  -G_{\mathrm L}^*\mathsf J_fG_{\mathrm L},\qquad
g=\min_{|\zeta|=1}\sigma_{\min}(A-\zeta B),\qquad
j_f=\sigma_{\min}(\mathsf J_f)=\min_{|m|\le M}|\gamma_m|.
\tag{9}
$$

取 $W=G_{\mathrm R}-G_{\mathrm L}$。若有可验证的下界 $\underline g>0$ 及

$$
\boxed{\ \|F\|<j_f\,\sigma_{\min}(W)\,\underline g\ },\qquad
0<\underline g\le g,
\tag{10}
$$

则这个全离散铅笔在单位圆内部和外部（含 $\infty$）各有 $K$ 个乘子，按代数重数计。也可用更简便的充分条件 $\|F\|<j_f\,\underline g^2$。两条判据都不预设任一簇的列数。

**证明。** 令 $V_\zeta=\operatorname{diag}(I,\zeta I)$，$\Pi$ 交换两个 $K$ 行块。散射块直接相乘给出

$$
(G_{\mathrm R}-\zeta G_{\mathrm L})V_\zeta
=V_\zeta\Pi(A-\zeta B).
\tag{11}
$$

对 $\zeta\ne0$ 取行列式再消去 $\det V_\zeta$，由多项式恒等得到两铅笔的行列式只差常符号，包括零和无穷乘子的重数。在单位圆上 $V_\zeta,\Pi$ 都酉，故式 (11) 两边给出的原铅笔与入射坐标铅笔有相同的奇异值。特别地 $\sigma_{\min}(W)\ge g$，$W$ 可逆。

定义 $H=(G_{\mathrm R}+G_{\mathrm L})W^{-1}$。展开两次乘法得到

$$
H^*\mathsf J_f+\mathsf J_fH=2W^{-*}F W^{-1},\qquad
\Delta=\mathsf J_f^{-1}W^{-*}F W^{-1},\qquad
(H-\Delta)^*\mathsf J_f+\mathsf J_f(H-\Delta)=0 .
\tag{12}
$$

其中 $W^{-*}=(W^{-1})^*$。令 $H_t=H-t\Delta$、$R_t=(H_t+I)W/2$、$L_t=(H_t-I)W/2$，$0\le t\le1$。在 $t=0$ 即为原 $G_{\mathrm R},G_{\mathrm L}$。对所有 $|\zeta|=1$，

$$
\big\|(R_t-\zeta L_t)-(G_{\mathrm R}-\zeta G_{\mathrm L})\big\|
\le \frac{|1-\zeta|}{2}\|\Delta W\|
\le\frac{\|F\|}{j_f\,\sigma_{\min}(W)}<\underline g .
\tag{13}
$$

故整条同伦在单位圆上可逆。对 $f_t(\zeta)=\det(R_t-\zeta L_t)$，单位圆内部零点数为 $\frac1{2\pi\mathrm i}\oint f_t'/f_t\,d\zeta$。将多项式分解为线性因子即可得到该公式。该积分随 $t$ 连续且取整数，因而计数不变。这一论证也容许有限乘子经无穷变化。

在 $t=1$，式 (12) 给出 $H_1$ 与 $-H_1^*$ 相似，其特征值按 $h\leftrightarrow-\bar h$ 成对，含代数重数。又有

$$
R_1-\zeta L_1=\tfrac12\big[(1-\zeta)H_1+(1+\zeta)I\big]W.
$$

虚轴特征值将给出单位模乘子，与 (13) 矛盾。故 $H_1$ 的开左、右半平面各有 $K$ 个特征值。变换 $\zeta=(h+1)/(h-1)$ 将左半平面送入单位圆内，右半平面送到外部，$h=1$ 对应 $\infty$。由上述行列式分解，重数保留。再用同伦及 (11)，结论成立。取 $F=0$ 时，$H=H_1$，上述变换还将 $h\leftrightarrow-\bar h$ 直接变为固定 $\beta$ 的 $\zeta\leftrightarrow1/\bar\zeta$ 配对。证毕。

**怎样有限计算 (10)。** 取圆上的 $N$ 个等距节点 $\zeta_j$，在每点取得 $\ell_j\le\sigma_{\min}(A-\zeta_j B)$。由最小奇异值的变分公式及最近节点弦长，可以用

$$
\underline g=\min_j\ell_j-2\sin\!\left(\frac{\pi}{2N}\right)\|B\|.
\tag{14}
$$

例如，若近似逆 $X_j$ 满足已包围的 $e_j=\|I-X_j(A-\zeta_jB)\|<1$，则 Neumann 级数给出 $\ell_j=(1-e_j)/\|X_j\|$。将范数取可靠上端、最小奇异值取可靠下端，再检查 (10) 的严格比较即可。若沿用代码对 $(A,B)$ 的共同 Frobenius 缩放，必须把圆周下界换回 (1) 的尺度才能与 (5) 的通量缺陷比较。

式 (9) 衡量的是单位圆离**矩阵奇异**还有多远。如果已有可靠的通常乘子距离 $d_{\rm rad}=\min_j\bigl|\,|\zeta_j|-1\,\bigr|$，且 $B$ 可逆、$B^{-1}A=X\operatorname{diag}(\zeta_j)X^{-1}$，则分解 $A-\zeta B=BX(\operatorname{diag}(\zeta_j)-\zeta I)X^{-1}$ 给出

$$
g\ge\frac{\sigma_{\min}(B)}{\|X\|\|X^{-1}\|}\,d_{\rm rad}.
\tag{15}
$$

非正规性会影响这个换算。取 $K=1$、$s>0$，在 (1) 中令 $R_{\mathrm L}=0,T_{\mathrm{RL}}=3/2,T_{\mathrm{LR}}=1/2,R_{\mathrm R}=3s/2$。传递矩阵为 $\left[\begin{smallmatrix}1/2&s\\0&2/3\end{smallmatrix}\right]$，两个单乘子的径向距离最小值恒为 $1/3$。但 $(A-B)(1,1/(3s))^T=(-1/(6s),0)^T$，故 $g\le1/(6s)$ 可任意小。这说明即使所有乘子为单根，普通特征值距离也不能直接充当 (13) 中的矩阵误差容限。式 (14) 同样适用于 Jordan 块及无穷乘子。

若还要把**浮点 QZ 输出的分类**与上述有限矩阵的精确计数相连，可执行以下附加检查。由求得的三角矩阵 $S,T_q$ 和可逆 $Q,Z$ 组成 $A_q=Q^*SZ^*$、$B_q=Q^*T_qZ^*$，在同一尺度验证 $\|A_q-A\|+\|B_q-B\|<\underline g$。再对每个齐次对 $(S_{jj},(T_q)_{jj})$ 可靠地区分模长大小。前一条件使连接两对铅笔的线段在整个单位圆上可逆，后一条件直接给出三角铅笔的计数，包括分母为零的项。由同一零点数论证，两计数一致。实际程序另有近单位圆拒绝带，输出 `GAP` 还须通过其容差判据。这些是可执行的充分条件，本次没有计算 P4 各频点的 (10)。

## 3. 定理 B　增广端口匹配

**定理 B（分项在下列条件下已证明）。** 在假设 3–4 的衰减空间上令

$$
\mathcal B(k)=
\begin{bmatrix}
\mathsf A_0(k)&0&0\\
\mathsf Y_-(k)&-\mathsf Z_-(k)&0\\
\mathsf Y_+(k)&0&-\mathsf Z_+(k)
\end{bmatrix}
\ \in\mathbb C^{(n+4K)\times(n+4K)} .
\tag{16}
$$

投影 $(\xi,c_-,c_+)\mapsto\xi$ 给出 $\ker\mathcal B$ 与离散导模系数空间的线性同构。用可逆 Cauchy 坐标 $\mathsf C_\pm$ 且两个 Dirichlet 块可逆时，式 (19) 给出与 DtN 行列式的精确关系。若还采用假设 5，则 (16) 在固定的局部解析标架中全纯，包括 Dirichlet 块的孤立奇点。实频时，中心消元有效并采用标准正交列基的 P2 投影矩阵有零最小奇异值，当且仅当 (16) 有非平凡核。

**证明一　离散模式的线性同构。** 由 (16) 的三行，中心系数解必须且只需满足

$$
\mathsf A_0\xi=0,\qquad
\mathsf Y_s\xi\in\operatorname{ran}\mathsf Z_s,\qquad s=-,+ .
\tag{17}
$$

给定这样的 $\xi$，每侧存在唯一 $c_s$ 使 $\mathsf Y_s\xi=\mathsf Z_s c_s$，因为 $\mathsf Z_s$ 满列秩。反之，若增广核向量的 $\xi=0$，两侧的 $c_s$ 都为零。两个方向均为线性。引理 A 的递推证明给出唯一的平方可和半线状态 $\mathsf Z_s\mathsf P_s^j c_s$，包括从 $j=0$ 起的接合状态。故同构保留几何重数，若只按比例识别模态，亦诱导对应的射影空间双射。此项允许任一个 $\mathsf D_s$ 奇异，也允许中心密度消元失效。

若每个参考胞的基场均有有限的分片 $H^1$ 能量，则有限维线性重建 $\mathcal U_s\colon h\mapsto u_h$ 到该分片 $H^1$ 空间有界。第 $j$ 胞的输入 $h_j$ 取自相邻的两个状态，故 $\sum_{j\ge0}\|\mathcal U_s h_j\|^2\le2\|\mathcal U_s\|^2\sum_{j\ge0}\|z_j\|^2<\infty$。若“模态”还要按不同的重建场识别，则需重建映射在 (17) 上单射。一个充分条件是中心密度可唯一消去，且重建场的保留 Cauchy 迹与所用端口数据一致。这时非零 $\xi$ 必有非零中心入射，由 (2) 至少一个总状态非零，非 Wood 时对应 Cauchy 迹也非零。连续波导特征函数及其重数还涉及无限阶传输条件。

**证明二　行列式与 Dirichlet 极点。** 两侧都取**从中心指向该引线**的法向，因此 $\mathsf C_-=[I,I;-\mathrm i\boldsymbol\gamma,\mathrm i\boldsymbol\gamma]$，$\mathsf C_+=[I,I;\mathrm i\boldsymbol\gamma,-\mathrm i\boldsymbol\gamma]$。这里方括号内的分号表示分块换行。在每个端口定义

$$
\mathsf C_s\mathsf Z_s=\binom{\mathsf D_s}{\mathsf N_s},\qquad
\mathsf C_s\mathsf Y_s=\binom{T_s^{c}}{N_s^{c}},\qquad
D=\operatorname{diag}(\mathsf D_-,\mathsf D_+),\qquad
N=\operatorname{diag}(\mathsf N_-,\mathsf N_+).
$$

将两侧中心值行竖排为 $T^c$，两侧中心导数行竖排为 $N^c$。两矩阵的大小均为 $2K\times(n+2K)$。先将 (16) 的两组端口行分别左乘 $\mathsf C_-,\mathsf C_+$，再将负侧导数的 $K$ 行与正侧值的 $K$ 行互换。结果为

$$
\begin{bmatrix}\mathsf A_0&0\\ T^c&-D\\ N^c&-N\end{bmatrix},\qquad
\varepsilon=(-1)^{K^2}.
\tag{18}
$$

这里 $\varepsilon$ 是上述换行的符号。对 $\det D\ne0$ 记 $\Lambda=ND^{-1}$。从最后的行块减去 $\Lambda$ 乘值行块，再交换两个 $2K$ 行块。后一次交换的符号为正，且 $\det(-D)=\det D$。分块三角行列式给出

$$
\boxed{\quad
\varepsilon\det\mathsf C_-\det\mathsf C_+\det\mathcal B
=\det\mathsf D_-\det\mathsf D_+
 \det\begin{bmatrix}\mathsf A_0\\N^c-\Lambda T^c\end{bmatrix}.
\quad}
\tag{19}
$$

$\det\mathsf C_-=\det(2\mathrm i\boldsymbol\gamma)$、$\det\mathsf C_+=\det(-2\mathrm i\boldsymbol\gamma)$ 均在保留阶非 Wood 时非零。等式 (19) 的右端使用**保留中心密度未知量**的 DtN 系统。

为与 `eq:port-matrix` 的 $2K$ 阶端口系统比较，将 $\mathsf A_0=[A_\eta,B_0]$ 按 $\xi=(\eta,\mathsf a)$ 分块，$\mathsf a=(a_0^-,b_0^+)$。仅在 $A_\eta$ 可逆时取

$$
H_c=\binom{-A_\eta^{-1}B_0}{I_{2K}},\qquad
\mathsf T_0=T^c H_c,\qquad \mathsf N_0=N^c H_c,\qquad
\mathsf A=\mathsf N_0-\Lambda\mathsf T_0.
$$

这时 $\xi=H_c\mathsf a$ 参数化 $\ker\mathsf A_0$。对 (19) 最右边的矩阵作中心密度 Schur 消元，得到

$$
\varepsilon\det\mathsf C_-\det\mathsf C_+\det\mathcal B
=\det A_\eta\,\det\mathsf D_-\,\det\mathsf D_+\,\det\mathsf A .
\tag{20}
$$

例如，消元可由右乘 $\left[\begin{smallmatrix}I&-A_\eta^{-1}B_0\\0&I\end{smallmatrix}\right]$ 实现，变换后右下块是 $\mathsf A$，右上块为零。若从一开始就对输入 $\mathsf a$ 写增广矩阵，使用 $\mathsf Y_s H_c$ 且略去中心传输行，则 (20) 相应地少一个 $\det A_\eta$。$n=0$ 时规定该空行列式为一。与原始增广矩阵比较时，$\det A_\eta$ 的零点必须单独处理。

在假设 5 的局部解析标架中，$\mathsf N_s\mathsf D_s^{-1}$ 亚纯。设 $k_*$ 是 $\det\mathsf D_s$ 的一个孤立零点，且 $\mathsf C_s\mathsf Z_s$ 在 $k_*$ 仍为满列秩。若该 DtN 矩阵的所有条目均可去奇，则其延拓满足 $\mathsf N_s(k_*)=\Lambda_s(k_*)\mathsf D_s(k_*)$。对 $0\ne v\in\ker\mathsf D_s(k_*)$ 作用，便得到 $\mathsf D_s v=\mathsf N_s v=0$，与满列秩矛盾。故至少一个条目在此有真极点。反过来，$\det\mathsf D_s\ne0$ 处逆矩阵全纯。由此恰好刻画的是**引线 DtN 矩阵本身**的极点。若 $\det\mathsf D_s$ 在整个邻域恒为零，该 Dirichlet 坐标在此没有定义域。

匹配行列式 $\det\mathsf A$ 的零与极可抵消。单端口标量例子取 $t=k-k_*$，引线 Cauchy 列为 $(t,1)^T$，中心列为 $(0,1)^T$。此时 $\Lambda=1/t$、消元匹配矩阵等于 $1$，而保留两列的行列式为 $t$，在 $t=0$ 两条状态线相交。这解释了为何 (19) 应视为等式及其亚纯延拓，不能在极点直接相乘数值。增广矩阵在这个点直接实施 (17)。单胞组装自身的奇性仍受假设 5 约束。

**证明三　解析标架与重数。** 实频通量确定基点的簇维数，复延拓使用假设 5 的矩阵条目。两侧分别处理，右侧用 $(A,B)=(\mathsf E_{\mathrm L},\mathsf E_{\mathrm R})$，左侧交换次序。取包围所选有限衰减簇且与其余谱分开的正向固定围道 $\Gamma$，在带隙可取单位圆。右偏转空间的投影为

$$
\mathscr P(k)=\frac1{2\pi\mathrm i}\int_\Gamma
   (\zeta B(k)-A(k))^{-1} B(k)\,d\zeta .
\tag{21}
$$

说明它的作用。固定一个 $k$，在 (7) 的坐标中，被积矩阵为 $[(\zeta-\omega)T-I]^{-1}T$。在 $T$ 的可逆块上它等于 $[\zeta I-(\omega I+T^{-1})]^{-1}$，在零特征值的幂零块上则是关于 $\zeta$ 的矩阵多项式。对有限 Jordan 块展开预解式，$\int_\Gamma(\zeta-\lambda)^{-1}d\zeta/(2\pi\mathrm i)$ 在围道内等于一，围道外等于零，高阶极点项的该积分为零。故 (21) 在所选广义空间上为恒等，在其余各块上为零，亦排除了无穷块。按假设 5，被积矩阵由全纯矩阵求逆得到，在紧围道上局部一致全纯，因而 $\mathscr P(k)$ 全纯。其秩局部恒定，例如 $\operatorname{tr}\mathscr P$ 连续且等于整数秩。

在一个基点 $k_0$ 取 $\operatorname{ran}\mathscr P(k_0)$ 的固定基 $V$。$F_s(k)=\mathscr P(k)V$ 在 $k_0$ 有一个非零的 $K$ 阶子式，故在邻域内构成全纯标架。另取固定参考矩阵 $\mathsf Z_0\in\mathbb C^{2K\times K}$，每侧可各取一个。若 $\mathsf Z_0^*$ 限制到当前衰减空间上可逆，则任意逐点选取的 QZ 基 $\mathsf Z_s(k)$ 给出的

$$
\widehat{\mathsf Z}_s(k)
=\mathsf Z_s(k)\big(\mathsf Z_0^*\mathsf Z_s(k)\big)^{-1}
=F_s(k)\big(\mathsf Z_0^*F_s(k)\big)^{-1}
\tag{22}
$$

全纯。第二等式源于两基仅差一个逐点可逆的右乘因子，该因子及其逆在乘积中消去。左乘的 $\mathsf Z_0^*$ 为常矩阵。不同基点的右式在同一参考坐标的重合域取相同值，故 (22) 在该坐标可用的整个开集全纯。取 $\mathsf Z_0=V$ 即可保证基点附近可用。将 (22) 代入 (16) 得到局部全纯的增广行列式。

若 $\widetilde Z_s=\widehat{\mathsf Z}_s W_s$ 是另一组全纯标架，则 $W_s=\mathsf Z_0^*\widetilde Z_s$ 全纯可逆。新标架的增广矩阵等于原矩阵右乘 $\operatorname{diag}(I_{n+2K},W_-,W_+)$。因此行列式乘以 $\det W_-\det W_+$，其零点及孤立零点的阶数保持不变。同一个乘法公式适用于逐点换基。若原始 QZ 列按频率任意换相位，这个逐点行列式因子可以不连续。空间有解析坐标所需的假设涉及铅笔条目，而单有乘子分离还不够。例如以 $(1,\bar k)^T$ 与 $(0,1)^T$ 为特征基，配固定特征值 $1/2,2$，取 $B=I$。参考矩阵 $(1,0)^T$ 归一化后的稳定列仍为 $(1,\bar k)^T$。

更明确地，若 (20) 两侧的函数在穿孔邻域有定义且行列式不恒为零，记 $\operatorname{ord}_{k_*}$ 为亚纯函数的阶，极点取负阶。Cauchy 坐标可逆时

$$
\operatorname{ord}\det\mathcal B
=\operatorname{ord}\det A_\eta
+\operatorname{ord}\det\mathsf D_-+\operatorname{ord}\det\mathsf D_+
+\operatorname{ord}\det\mathsf A .
\tag{23}
$$

这是 (20) 的局部因子分解。中心与 Dirichlet 块均可逆时，两个特征行列式的孤立零阶相同。式 (17) 给出的几何重数等价在 Dirichlet 块奇异时仍成立。一般解析矩阵的零阶与单点核维数是两个量，例如标量 $(k-k_*)^2$ 在该点核维数为一，零阶为二。连续算子的特征值重数未纳入 (23)。

**证明四　P2 的实频检验。** 令 $Z_s$ 为标准正交列基，即 $Z_s^*Z_s=I_K$。于是 $\Pi_s^\perp=I-Z_sZ_s^*$ 正交投影到其列空间的 Euclidean 正交补。对任一状态 $y$，$\Pi_s^\perp y=0$ 与 $y\in\operatorname{ran}Z_s$ 等价。原变量上的完全等价矩阵为

$$
\begin{bmatrix}\mathsf A_0\\\Pi_-^\perp\mathsf Y_-\\\Pi_+^\perp\mathsf Y_+\end{bmatrix}.
$$

在 P2 使用的中心消元条件下，$\ker\mathsf A_0=\operatorname{ran}H_c$，而 $H_c$ 的下块为恒等。于是

$$
F_{\rm P2}=\binom{\Pi_-^\perp\mathsf Y_-H_c}
                  {\Pi_+^\perp\mathsf Y_+H_c}
\in\mathbb C^{4K\times2K},\qquad
\sigma_{\min}(F_{\rm P2})=0
\quad\Longleftrightarrow\quad
\ker\mathcal B\ne\{0\}.
\tag{24}
$$

证明为 $\sigma_{\min}(F_{\rm P2})=\min_{\|\mathsf a\|=1}\|F_{\rm P2}\mathsf a\|$。单位球面紧，最小值为零恰好给出非零 $\mathsf a$ 满足两个端口条件，再取 $\xi=H_c\mathsf a$。反向由 (17) 与中心参数化即得。若用一般满秩标架，例如 (22)，则投影应写作 $I-Z_s(Z_s^*Z_s)^{-1}Z_s^*$。若中心密度块奇异，保留 $\mathsf A_0$ 的第一种矩阵仍然有效。直接在原 $\xi$ 上堆叠端口投影而漏掉中心行会扩大待检验的空间。

代码还输出 $\sigma_{\min}/\sigma_{\max}$。当 $\sigma_{\max}>0$，这个比值的**精确零点**与 (24) 相同。有限阈值的接受频率取决于矩阵尺度和条件数。投影与奇异值适用于逐点实频检验，复频标量行列式的解析性由 (21)–(22) 提供。证明完毕。

## 4. 符号与代码

下面以 `test/bie-bound/failure-probe-v1/` 为 P2/P4 代码的相对目录。对应关系已从源文件逐项核对。

| 数学对象 | 代码入口 | 对应内容 |
|---|---|---|
| $\beta_m,\gamma_m,\mathsf E(L)$ | `+bloch/rayleigh_channels.m` | `beta_m`、`gamma_m`、`phase`，实际算例背景 $\rho_{\mathrm e}=1$ |
| $\psi_m,r_m^{x_{\mathrm L}},l_m^{x_{\mathrm R}}$ | `+bloch/incident_rhs.m`，`psi, U_L, U_R` | 除以 $\sqrt d$，两端分别使用正、负指数和各自锚点 |
| $\mathsf F^\leftarrow_{x_{\mathrm L}},\mathsf F^\rightarrow_{x_{\mathrm R}}$ | `+bloch/farfield_extractors.m`，`F_L, F_R` | 提取散射出射幅，`g_scale` 含 $\mathrm i/(2\sqrt d\,\gamma_m)$ |
| $A_\eta,B_0,H_c$ | `+bloch/construct_S.m`，`A_QP, B_L, B_R, density_scale, H_L, H_R` | 取物理密度坐标与未缩放的右端，$S_w=\operatorname{diag}(\texttt{density_scale})$，则 $A_\eta=S_w^{-1}\texttt{A_QP}\,S_w$，$B_0=[\texttt{B_L},\texttt{B_R}]$。$H_c$ 的上块为 $[\texttt{H_L},\texttt{H_R}]$ |
| 单胞散射块与 $G_{\mathrm L},G_{\mathrm R}$ | `+bloch/construct_S.m`，`R_L, T_RL, T_LR, R_R` | 直达相位各加一次到两个透射块。由四块按 (5) 可构造通量缺陷 |
| 两排组成的 W3 周期 | `search_i9_physics.m` 的 `LOCAL_join` | 在公共端口消去内部状态。若内部系统可逆且两排各满足 (6)，将二式相加后公共状态的通量相消，整个周期仍满足 (6) |
| $\mathsf E_{\mathrm L},\mathsf E_{\mathrm R},\mathsf Z_\pm$ | `search_i9_physics.m`，`LOCAL_lead_classify, LOCAL_qzsub` | 正向取 `(A,B)`，负侧向左衰减另取 `(B,A)`。`ordqz` 的首列块为 `Zo(:,1:K)`。比较特征向量的分支另外使用 `qr(V,0)` |
| $\mathsf P_\pm$ | 草稿 `eq:propagation`，代码有序 QZ 的两个首对角块 | 若 $QAZ=U_A,QBZ=U_B$，有限稳定对的 $U_{B,11}$ 可逆，故 $AZ_s=BZ_s U_{B,11}^{-1}U_{A,11}$。前 $r$ 列给出 $r$ 个独立的衰减初值，由第 2 节的直和刻画正好张成所选空间。负侧交换 $A,B$ |
| $\mathsf C_s,\mathsf D_s,\mathsf N_s,\Lambda_s$ | `search_i9_physics.m`，`LOCAL_dtn` | `Dp=Ap+Bp`、`Dm=Am+Bm`，右导数为 $+\mathrm i\boldsymbol\gamma(A_p-B_p)$，左导数为 $-\mathrm i\boldsymbol\gamma(A_m-B_m)$。右除通过转置后的线性求解完成 |
| $\mathsf T_0,\mathsf N_0,\mathsf A$ | `search_i9_physics.m`，`LOCAL_matching` 的 `T, N0, Adef` | `Adef` 与 `N0-blkdiag(Lm,Lp)*T` 交叉核对。`Aphys` 再加可逆实频行列权重，精确核维数相同，奇异值尺度会改变 |
| $\mathsf Y_-H_c,\mathsf Y_+H_c,F_{\rm P2}$ | `search_i9_physics.m` 的 `amplitude_check` | `yl=[I,0;R_L,T_RL]`、`yr=[T_LR,R_R;0,I]`。`F=[yl-zl*(zl'*yl);yr-zr*(zr'*yr)]`，`sv(end)` 为 (24) 的最小奇异值 |
| 乘子计数与距离 | `search_i9_classify.m`，`diagnose.m` 的 `sub` | 前者比较齐次 QZ 对的模并使用两个容差环。后者的 `unit_distance` 是有限乘子的径向距离，`eigen_condition` 只测所选稳定特征向量列。式 (9) 的 $g$ 需要整个单位圆的奇异值下界 |

**P2 的已有记录。** `failure-probe-v1/README.md` 的 P2 表在右切口位移 $+0.2761873742$ 时，列出被后备路线接受的频率 $1.55625025815/1.55625025840$。两种分辨率下，加权 DtN 匹配的绝对最小奇异值约 $0.01961/0.01956$，相对值却约 $4.47\times10^{-16}/4.66\times10^{-16}$，最大奇异值超过 $2.2\times10^{13}$。在该极点附近，`amplitude_check` 的相对值约为 $0.00402225$。四个移动切口的投影扫描所报候选均约为 $1.558437894182089$。这些是既有实频浮点结果。生产搜索副本 `test/bie-bound/pipeline-v1/search/detsearch.m` 对 `Adef` 求行列式，其后备确认使用 `aphys_ratio`。式 (24) 对应另一个已实现的 `amplitude_check` 分支。

**P4 的已有记录。** `results/edge-subspaces.csv` 的 96 行包含 $M=6$ 的 48 个计数 $13=K$ 和 $M=12$ 的 48 个计数 $25=K$，相应的 `rank` 列均等于 $K$。P4 报告的最小单位圆距离为 $2.83\times10^{-6}$。它及 `eig` 与 QZ 的空间夹角是实测诊断量。`search_i9_classify.m` 在计数与容差条件均通过后才给 `GAP` 状态。式 (10) 给出独立于预期列数的检验，本文件只作证明与只读源码核对。

**组装的解析性。** `+kernel/precomp_proxy.m` 使用 `lsqminnorm` 或 `pinv` 求代理系数，`+bloch/rayleigh_channels.m` 逐点选平方根分支。对复 $k$，一般的最小二乘解含共轭。例如以列 $(1,k)^T$ 拟合 $(1,0)^T$，解为 $1/(1+|k|^2)$。它在实轴上可另取局部全纯延拓 $1/(1+k^2)$。因此，从实频代码构造假设 5 的矩阵族，需说明根的延拓分支、拟合的秩及所用解析表达式。QZ 的共同非零缩放保留右子空间，(22) 消去基的选择，组装本身的频率依赖仍需逐项核对。

## 5. 未决项与适用范围

| 分类 | 受影响的主张 | 条件、现状及所需检查 |
|---|---|---|
| blocker，仅针对无条件带内推广 | 任意单位模乘子均可由“衰减加正通量传播”给出 $K$ 个方向 | 第 2 节的 Jordan 例子否定这一表述。已证的有限维版本要求单位模乘子半单。若要选定带边或混合符号交叉处的物理辐射解，需另给阈值或极限吸收条件 |
| important caveat | 将精确散射引理直接用于当前离散胞元 | 当前组装使用有限 Nyström 求积、基本解代理和数值线性求解，精确单胞求解假设不成立。实算 $\lVert F\rVert$ 与 (14)，再检查 (10)，可给这些离散矩阵自己的计数保证。已有记录未给出该比较，$F$ 是否恰为零也未经验证 |
| important caveat | 复频插值所用矩阵的全纯性 | (21)–(22) 已解决标架问题。代码的秩选择、最小二乘延拓、单胞矩阵可逆性和整个所用围道的分离尚需核对。实频的 P2 等价式可以直接使用 |
| important caveat | 离散系数模态与连续物理场的重数对应 | (17) 证明离散几何重数相同，(23) 证明解析行列式的局部阶数关系。连续场重建的单射性、完备性及谱收敛未由这两式建立 |
| minor caveat | 在整段频率上使用一个固定参考标架 | 基点可取 $\mathsf Z_0=\mathsf Z_s(k_0)$。单个坐标可延伸到哪里取决于 $\mathsf Z_0^*\mathsf Z_s(k)$ 的可逆性，需在该频段验证或覆盖以多个局部坐标 |

Wood 点与 Dirichlet 例外值的作用不同。前者破坏当前 Rayleigh 状态的非退化性，需更换阈值基与散射定义。后者仅使 Dirichlet 消元失效，在第 3 节的其余假设下，(16)、(17) 和 (24) 在该点仍成立。

**完成报告。** 模式为 Proof from scratch。新增证明位于本文件的引理 A、其全离散扰动结论和定理 B。假设 1–4 给出实频有限维结论，各分项使用的额外条件已在原处列出。解析结论另用假设 5。文献核对状态为 Proof literature verification completed。本文使用原稿的 `eq:pencil`、`eq:propagation`、`eq:nep`、`eq:port-matrix` 及上表的源代码和既有 P2/P4 记录。带内只用本文证明的有限维签名计数，无需新增文献。
