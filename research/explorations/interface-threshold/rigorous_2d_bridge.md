# 真二维阈值桥梁：全部通道、加权端问题与局部预解式

日期：2026-10-28。主模式：**Proof from scratch**；记号模式：Writing。
本文只负责从真正耦合的二维连续 PDE 到阈值约化的桥梁，不修改既有主线。
背景命题和定理编号属于 [[research/explorations/interface-threshold/deep_investigation|第一轮推导]]；本文使用 B1–B5，避免编号混淆。
一般内部带隙适配仍有待证条件；但 §8 给出一个可以用解析扰动推进的真正二维、单临界端的具体中间族。
所有证明均是连续算子论证，没有把 Fourier 截断当作原方程，没有运行数值实验。

## 1. 本文交付的层次

| 层次 | 内容 | 资格 |
|---|---|---|
| B1 | 简单二次 cell 带边产生关于 $\tau$ 解析的慢 Bloch 分支 | 本文证明；cell 光谱隔离是假设 |
| B2 | 固定加权空间中的增广半波导问题可逆，推出 Poisson/DtN 正则性 | 本文证明的充分条件；不把其可逆性视为任意介质的事实 |
| B3 | 临界尾振幅决定 $\partial_\tau F(0)$；无阈值 $L^2$ 态时压缩正定 | 本文证明；全部有界解的渐近完备性须核验 |
| B4 | 精确拼接及 Schur 补给加权/局部预解式 $\tau^{-1}$ 展开与奇异秩 | 本文证明；条件比“bulk 有共同 gap”更强 |
| B5 | 两端及中心均加入横向耦合调制，调谐中心后保持真实二维共振与弱缺陷分岔 | 本轮模型级证明通过独立审查；真正二维的小调制谱底族，不是一般内部 gap 定理 |

逻辑链为：**cell 谱 → 慢 Bloch 波 → 全部快通道的加权解算子 → 精确端口拼接 → 共振核 → 局部预解式 → 弱缺陷分岔**。
抽象 Schur 补并不建立前三个箭头。本文将它们写成固定空间上的 PDE 条件，而不是由有限 QZ 曲线或有限矩阵惯性替代。

## 2. 连续对象与“真二维”的含义

取 $B=\mathbb R\times(0,L)$，沿 $y$ 固定实准周期参数 $\beta\in\mathbb R$，$u(x,L)=\mathrm e^{\mathrm i\beta L}u(x,0)$。
令 $0<\rho_{\min}\le\rho(x,y)\le\rho_{\max}<\infty$，允许中心及每个模板胞元内有有限条分片光滑材料界面，整个条带上的周期复制局部有限。
在 $x<-R$ 和 $x>R$ 分别等于 $\rho_-(x,y)$、$\rho_+(x,y)$，后两者沿 $x$ 的周期为 $d_-,d_+>0$；不要求相同。
在 $H=L^2(B,\rho\,\mathrm dx\mathrm dy)$ 上，$A$ 由 $H^1_\beta(B)$ 上的形式 $\int_B|\nabla u|^2$ 定义。
内积对第一变量线性；$A=-\rho^{-1}\Delta$，所有方程及界面传输均按弱意义解释。
由于跳跃只在零阶质量项，局部解满足 $-\Delta u\in L^2_{\mathrm{loc}}$ 时仍有 $H^2_{\mathrm{loc}}$ 正则性；这不适用于不加修改地改成 TE 主系数跳跃问题。

写 $q_n=\beta+2\pi n/L$ 及 $u(x,y)=\sum_{n\in\mathbb Z}u_n(x)\mathrm e^{\mathrm iq_ny}$。
若 $\rho(x,y)=\sum_j\rho_j(x)\mathrm e^{2\pi\mathrm ijy/L}$，则原方程给出

$$
-u_n''+q_n^2u_n=\mu\sum_{m\in\mathbb Z}\rho_{n-m}(x)u_m,
\qquad n\in\mathbb Z.
\tag{B.1}
$$

当 $\rho_{\pm1}\ne0$ 时，单个横向通道立即耦合到相邻通道；反复耦合到任意远的 Fourier 编号。
例如 $\rho=\rho^{\mathrm{lay}}(x)+\eta\cos(2\pi x/d)\cos(2\pi y/L)$、$\eta\ne0$ 时，没有由有限个横向 Fourier 模张成的非零不变空间。
事实上，有限支持的最高编号 $N$ 会在第 $N+1$ 个方程产生 $\rho_1u_N$，迫使 $u_N=0$ 于 $\cos(2\pi x/d)\ne0$ 的开区间，再由连续性及方程延续消去；逐级递推给零解。
这说明标量 $2\times2$ transfer matrix 只属于可分离模型。把 (B.1) 截成 $2(2N+1)$ 维后，得到的是近似系统，不能据此直接证明原连续算子的阈值重数。
本文的有限秩仅来自**隔离临界 Bloch 谱**；其余无限维通道始终保留在有界逆中。

还存在比矩阵变大更根本的障碍：即使材料为常数，沿 $x$ 的双向 Cauchy 演化也不是自然迹空间 $H^{1/2}\oplus H^{-1/2}$ 上的有界传递算子。第 $n$ 个高横向模的方程具有 $\cosh(\kappa_n d)$、$\kappa_n\sim|q_n|$ 的增长；将初始值按 $H^{1/2}$ 范数归一化、初始导数取零，传播后范数仍随 $|n|$ 指数增长。这是椭圆 Cauchy 问题的高模不适定性。因此二维适配应使用稳定解子空间、Cauchy 关系或 Poisson 算子，而非把完整 transfer 当作一个有界大矩阵的极限。

## 3. Cell 条件与慢分支

### B1：一个临界端的精确 cell 假设

先选右端临界、左端严格处于 gap。右端单胞 $C_+=(0,d_+)\times(0,L)$ 上定义

$$
\mathcal L_+(\theta,\mu)
=-(\partial_x+\mathrm i\theta)^2-\partial_y^2-\mu\rho_+,
\quad H^2_{\mathrm{per},\beta}(C_+)\longrightarrow L^2(C_+).
\tag{B.2}
$$

这里 $x$ 周期、$y$ 准周期；其弱版本从 $H^1_{\mathrm{per},\beta}$ 映到共轭对偶。
等价的 cell 算子 $\rho_+^{-1}[-(\partial_x+\mathrm i\theta)^2-\partial_y^2]$ 在 $L^2(C_+,\rho_+)$ 中有紧预解式，实 $\theta$ 时自伴。
假设某个孤立简单带函数满足

$$
\lambda(\theta_*)=\mu_*>0,\qquad
\lambda'(\theta_*)=0,\qquad
a=\tfrac12\lambda''(\theta_*)>0.
\tag{B.3}
$$

并要求存在 $\gamma>0$，使一个 $x$ 准动量基本区间内、$|\operatorname{Im}\theta|\le2\gamma$ 中，在 $\mu=\mu_*$ 时只有这个二重特征根 $\theta_*$；两条边界线没有根。
这里“二重”是 $\theta$-pencil 的代数重数，而 cell 本征空间仍是一维。
左端在相应复带内完全没有特征根。该复谱隔离条件强于只画出一条实 band curve，须单独证明或核验。
允许多临界点的推广需同时保留所有点，本文不把其余点默认为不存在。

**命题 B1。** 在 (B.3) 的局部隔离条件下，令 $\mu=\mu_*-\tau^2$。存在关于复 $\tau$ 解析的右衰减 Bloch 分支

$$
\Phi_\tau(x,y)=\mathrm e^{\mathrm i\theta(\tau)(x-R)}p_\tau(x,y),
\qquad
\theta(\tau)=\theta_*+\frac{\mathrm i\tau}{\sqrt a}+O(\tau^2),
\tag{B.4}
$$

其中 $p_\tau$ 在 cell 的 $H^2$ 范数中解析，沿 $x$ 周期。对小的实 $\tau>0$，它向右衰减。
选定归一化

$$
\frac1{d_+}\int_{C_+}\rho_+|p_0|^2=1.
\tag{B.5}
$$

**Proof。** (B.2) 是固定定义域上的解析族；围住简单 cell 本征值的 Riesz 积分给秩一解析投影，因而给解析的 $\lambda(\theta)$ 和 $p(\theta)$。
其在 $H^2$ 中的有界性和解析性可由 $-\Delta p$ 的方程及 cell 椭圆估计得到；没有对横向 Fourier 作截断。
写 $z=\theta-\theta_*$，则 $\lambda(\theta)-\mu_*=z^2a(z)$，其中 $a(z)$ 解析且 $a(0)=a>0$。
局部选解析平方根后，$z\mapsto z\sqrt{a(z)}$ 在零点导数非零，所以有解析逆。
令该表达式等于 $\mathrm i\tau$ 即得 (B.4)；另一支对应 $-\mathrm i\tau$。证毕。

**需要排除什么。** $a=0$、cell 几何重数大于一、多个实准动量同频、或者复特征根没有与其余谱隔开时，都不能用命题 B1 的单支版本。
Nazarov 2020 Proposition 4.1 明确允许一般 Jordan 长度对应的其他分数次尺度，不能把平方根当成所有周期阈值的默认定律。

## 4. 用固定加权 PDE 替代“假设 DtN 光滑”

### 4.1 空间、增广算子与精确假设

在右端用 $s=x-R\ge0$，左端用 $s=-x-R\ge0$。定义

$$
H^1_\gamma(B_\pm)=\{v:\mathrm e^{\gamma s}v\in H^1_\beta(B_\pm)\},
\qquad
H^{-1}_\gamma(B_\pm)=(H^1_{-\gamma,0}(B_\pm))^*.
\tag{B.6}
$$

下标 $0$ 只指人工端口的零 Dirichlet 迹；星号为共轭对偶。后一空间保证 $L_\tau=-\Delta-(\mu_*-\tau^2)\rho$ 从 $H^1_\gamma$ 连续映入 $H^{-1}_\gamma$。
选固定光滑 $\chi_+(s)$，近端口为零、充分远处为一。定义

$$
\mathcal T_+(\tau)(v,c)
=\bigl(L_\tau v+cL_\tau(\chi_+\Phi_\tau),\;v|_{\Gamma_+}\bigr),
\tag{B.7}
$$

其定义域是 $H^1_\gamma(B_+)\oplus\mathbb C$，值域是 $H^{-1}_\gamma(B_+)\oplus H^{1/2}_\beta(\Gamma_+)$。
虽然 $\Phi_\tau$ 本身不在固定衰减空间内，$L_\tau(\chi_+\Phi_\tau)=[-\Delta,\chi_+]\Phi_\tau$ 支撑紧，因此 (B.7) 是固定空间间的解析有界算子族。
左端没有临界分支，定义 $\mathcal T_-(\tau)v=(L_\tau v,v|_{\Gamma_-})$，使用同型加权空间。

以下是**可证明足够、但不能由实 bulk gap 自动推出**的 PDE 假设：

- **H1，阈值端问题正则：** $\mathcal T_+(0)$ 与 $\mathcal T_-(0)$ 是上述 Banach 空间间的有界同构。
- **H2，中心 Dirichlet 正则：** $-\Delta-\mu_*\rho$ 在有界中心、两端零 Dirichlet 迹的弱问题可逆。
- **H3，完整渐近类：** 每个阈值齐次解若各远端 cell 的 $H^1$ 范数一致有界，则右端为 $c\Phi_0+H^1_\gamma$、左端为 $H^1_\gamma$；小正 $\tau$ 的 $L^2$ 齐次尾也属于对应衰减类。
- **H4，无阈值真本征态：** 全局 $A$ 在 $\mu_*$ 没有 $L^2$ 本征函数。

H1 是关于**整个半波导**的带一个临界幅度的边值问题，不是某个有限矩阵条件数。
H1 排除了该切口下的 Dirichlet 表面本征态及阈值 Dirichlet 共振；H2 排除了中心 pole。
H3 才保证我们构造的尾类包含全部物理有界解；没有 H3 时只能讨论所定义的渐近类，不能说已数尽全部阈值态。

### B2：从端问题同构推出端口正则性

**命题 B2。** 在 B1、H1–H2 下，存在小的 $\tau$ 邻域，使中心及两端的精确 Poisson 算子在每个固定局部 $H^1$ 范数中解析，且在全域 $H^1_{-\gamma}$ 范数中解析。
其 outward DtN 之和

$$
D(\tau):X\longrightarrow X^*,\qquad
X=H^{1/2}_\beta(\Gamma_-\cup\Gamma_+),
\tag{B.8}
$$

在算子范数中解析。固定 $X$ 内积和 Riesz 映射 $J:X\to X^*$，令 $F(\tau)=J^{-1}D(\tau)$。
则对实 $\tau\ge0$，$F(\tau)$ 自伴，$F(0)$ Fredholm，且指数为零。

**Proof。** 由 (B.7) 的解析性与 H1，Neumann 级数给 $\mathcal T_\pm(\tau)^{-1}$ 的局部解析性。
对边界数据 $g$ 和零源，记右端逆像为 $(v_\tau(g),c_\tau(g))$，于是

$$
P_+(\tau)g=v_\tau(g)+c_\tau(g)\chi_+\Phi_\tau,
\quad
v_\tau\in\mathcal B(H^{1/2},H^1_\gamma),\quad
c_\tau\in\mathcal B(H^{1/2},\mathbb C).
\tag{B.9}
$$

慢波在 $H^1_{-\gamma}$ 中解析，只需进一步缩小 $|\tau|$ 使其指数增长率小于 $\gamma/2$。因此全 Poisson 算子也解析。
中心结论由 H2 和有界域的解析逆得到。非零源的精确 Dirichlet 解算子同样存在，且在局部/负权范数中有界解析。
在端口邻域取固定 lifting，以弱 Green 公式定义法向导数，即得 $H^{-1/2}$ 中的解析性。
对实 $\tau>0$，所有齐次解都指数衰减，所以 Green 公式给 DtN 的 Hermitian 性；令 $\tau\downarrow0$ 得 $F(0)$ 自伴。

Fredholm 性还须说明。将 $D(0)$ 与参考参数 $\mu=-1$ 的拼接 DtN $D_{\mathrm{ref}}$ 比较。
参考形式 $\int(|\nabla u|^2+\rho|u|^2)$ 和迹定理使 $J^{-1}D_{\mathrm{ref}}$ 为正的有界同构。
对相同边界数据，阈值解与参考解之差在端口取零迹；在有限 collar 中，它满足右端属于 $L^2$ 的常主部椭圆方程。
局部边界 $H^2$ 估计使其法向迹属于 $H^{1/2}$，且对 $\|g\|_X$ 一致有界。
紧嵌入 $H^{1/2}(\Gamma)\hookrightarrow H^{-1/2}(\Gamma)$ 因而使 $D(0)-D_{\mathrm{ref}}:X\to X^*$ 紧。
这里需要的局部 $H^1$ 界已由 (B.9) 给出；无限长的慢尾不参加这个 collar 紧性论证。
故 $F(0)$ 为同构的紧扰动，Fredholm 指数零。证毕。

**这一步没有证明的事。** 对任意二维周期端，H1 尚须通过加权 Fredholm 理论、核/余核排除或 Robin 换图来核验；不是写下 (B.7) 就自动可逆。
若只知核为零而未证明指数零/满射，仍不能使用命题 B2。

## 5. 阈值尾幅度与正定压缩

### B3：质量发散给出精确的一阶系数

令 $N=\ker F(0)$，$P_N$ 为 $X$ 上到 $N$ 的正交投影。
将中心及两个尾部 Poisson 解拼接，记其全局重构为 $P(\tau)g$；$P$ 不是投影，与 $P_N$ 明确区分。
右临界幅度 $c_0(g)$ 指 (B.9) 对 $\Gamma_+$ 数据的系数，并延拓为 $X\to\mathbb C$。

**命题 B3。** 在 B1、H1–H2 下，

$$
(F'(0)g,g)_X=\sqrt a\,|c_0(g)|^2.
\tag{B.10}
$$

若再有 H3–H4，则 $N$ 与全部有界非 $L^2$ 阈值解空间同构，$\dim N\le1$。
若 $N\ne0$，则 $C_N=P_NF'(0)P_N|_N$ 严格正定。

**Proof：导数。** 对实 $\tau>0$，固定端口迹，精确 Green 恒等式给每个子域

$$
\langle D'(\tau)g,g\rangle
=2\tau\int\rho|P(\tau)g|^2.
\tag{B.11}
$$

中心和严格 gap 左端的质量一致有界，所以其极限贡献为零。
右端由 (B.9) 和 $v_\tau\in H^1_\gamma$，得到慢波、快余项的交叉积分一致有界。
令 $\kappa(\tau)=\operatorname{Im}\theta(\tau)=\tau/\sqrt a+O(\tau^2)$。
逐 cell 求几何级数，并用 (B.5) 及 $p_\tau=p_0+O(\tau)$，给

$$
\int_{B_+}\rho_+|P_+(\tau)g|^2
=\frac{|c_\tau(g)|^2}{2\kappa(\tau)}+O(\|g\|_X^2).
\tag{B.12}
$$

余项对 $g$ 的单位球一致：快余项用加权 Cauchy–Schwarz，周期单胞误差为 $O(\tau)$，乘几何级数后为 $O(1)$。
将 (B.12) 代入 (B.11)，再用 B2 的算子范数连续性，得到 (B.10)，而不只是逐个向量的形式极限。
若改变 (B.5) 的归一化，右端常数须同步改变；它不是与 Bloch 归一化无关的裸 $\sqrt a$。

**Proof：共振核。** $F(0)g=0$ 正是两人工界面的法向通量和为零；函数值已共享，所以重构满足全局弱方程。
其右端为 $c_0(g)\Phi_0+H^1_\gamma$、左端指数衰减。反向由 H3 及各块的唯一性，任意有界阈值解均是这样的重构。
若其共同端口迹为零，H1–H2 使每块都为零，所以此对应为同构。
若 $c_0(g)=0$，两端都指数衰减，因而重构属于 $L^2$；H4 迫使 $g=0$。
所以 $c_0:N\to\mathbb C$ 单射，给 $\dim N\le1$；结合 (B.10) 得正定性。证毕。

这里“一临界通道”限制的是端部的临界 Bloch 空间，不是整个二维函数空间。
多个临界通道时，若可分别建立正权尾质量式，则 $C_N$ 是临界幅度向量的正 Gram 形式；无阈值 $L^2$ 态给幅度映射单射。
重根、不同准动量的交叉平均及多个端的归一化均须重新核验，本文不宣布一般多通道扩展已完成。

## 6. 真正需要的 $\tau^{-1}$ 预解式展开

### B4：精确拼接、奇异秩与局部可见性

再设 $I=(\mu_*-\delta,\mu_*)\subset\rho(A)$。
这一条件排除未扰动接口在该固定小窗已有本征值；它不由公共 projected gap 单独推出。
令 $M$ 是实乘法算子，取紧支撑光滑 cutoff $\chi$，或 $M u=\mathrm e^{-\gamma\langle x\rangle}u$。
前者研究局部预解式，后者等价于 $L^2_\gamma\to L^2_{-\gamma}$ 的加权预解式。
记 $E_\tau=MP(\tau):X\to H$，以固定的 $X,H$ 内积取伴随。

**定理 B4。** 在 B1、H1–H4 及上述 resolvent 小窗假设下，若 $N\ne0$，则

$$
M(A-\mu_*+\tau^2)^{-1}M
=\frac1\tau E_0P_NC_N^{-1}P_NE_0^*+O(1)
\quad\text{于 }\mathcal B(H),
\qquad \tau\downarrow0.
\tag{B.13}
$$

若 $N=0$，左边一致有界。奇异系数非负，且其秩为 $\operatorname{rank}(E_0|_N)$，即被 $M$ 看见的阈值共振维数。

**Proof：精确拼接。** 对源 $Mf$，先在中心与两端解零端口迹问题，记分块解为 $R_D(\tau)Mf$。
B2 给 $MR_D(\tau)M=O(1)$；对指数 multiplier，源属于正权空间，B2 的非零源版本仍适用。
各块 outward 法向源迹之和由 Green 公式等于 $-JP(\tau)^*Mf$。
因此待补充的公共边界迹满足 $F(\tau)g=E_\tau^*f$，全局解为分块源解加 $P(\tau)g$，从而

$$
M(A-\mu_*+\tau^2)^{-1}M
=MR_D(\tau)M+E_\tau F(\tau)^{-1}E_\tau^*.
\tag{B.14}
$$

此处 $P(\tau)^*$ 仅在实 $\tau>0$ 的 $L^2$ Poisson 映射上使用；在阈值实际使用的是有界的 $E_0^*$。
对任意 $f$ 先在紧支撑稠密类证明 Green 恒等式，再用加权估计延拓。
正号来自 $R_Df$ 的零 Dirichlet 迹；不能随法向约定擅自换号。

**Proof：极点阶数。** 由 B2 和 Fredholm 性，在 $N^\perp$ 上 $F(0)$ 有有界逆。
精确 Schur 补满足 $S(\tau)=\tau C_N+O(\tau^2)$，因而

$$
F(\tau)^{-1}=\tau^{-1}P_NC_N^{-1}P_N+O(1).
\tag{B.15}
$$

这正是 [[research/explorations/interface-threshold/deep_investigation#5. 定理 3：边界阈值正规形|既有抽象约化]] 的无扰动逆版本：非对角块是 $O(\tau)$，所以其与 $S^{-1}$ 的乘积只有 $O(1)$。
由 $E_\tau=E_0+O(\tau)$，将 (B.15) 代入 (B.14) 得 (B.13)。若 $N=0$，普通 Neumann 逆即可。
正定 $C_N$ 使主项为 $VV^*$ 型，秩恰等于 $E_0|_N$ 的秩。证毕。

### 6.1 从 cutoff 秩到材料 Birman–Schwinger 秩

对 $W=w/\rho$，其中 $w\ge0$ 有界且紧支撑，可直接将上面的 $M$ 换成 $W^{1/2}$；局部解算子估计不要求 multiplier 光滑。
于是

$$
\mu W^{1/2}(A-\mu)^{-1}W^{1/2}
=\frac{G_w}{\tau}+O(1),
\qquad
G_w=\mu_* E_wP_NC_N^{-1}P_NE_w^*,
\quad E_w=W^{1/2}P(0).
\tag{B.16}
$$

这是 [[research/explorations/interface-threshold/deep_investigation#4. 定理 2：局部预解式奇异秩与新生模态数|定理 2]] 所需的**算子范数**展开。
若 $w\ge w_0>0$ 于某非空开集，则 $E_w|_N$ 单射：其核中的共振解在该开集为零，由唯一延拓在整个连通条带为零。
这里适用 Aronszajn 1957 的无编号定理（印刷 pp.235–236，公开扫描 PDF pp.1–2）：主部为常系数 Laplacian，低阶势 $\mu_*\rho$ 有界，解为 $H^2_{\mathrm{loc}}$；复解分别对实部、虚部应用。
因此材料跃迁不破坏该步骤。若只给一个任意可测支集而无开集条件，本文保留“局部幅度映射单射”为独立可见性条件，不调用更强但未核对的唯一延拓版本。

### 6.2 为什么阈值 $L^2$ 态和隐藏模态不能混过去

若存在阈值本征态，谱投影项为 $(\mu_* -\mu)^{-1}\Pi=\tau^{-2}\Pi$；局部压缩看得见它时，(B.13) 的 $O(1)$ 余项不可能成立。
在边界约化中，它对应 $c_0(g)=0$ 但 $g\ne0$，因而 $C_N$ 退化。这不是数值条件数问题，而是不同的奇异阶。
若某个子域有零 Dirichlet 迹态，H1 或 H2 已失败；此时一个普通 DtN 图可能漏掉它，不能继续用 (B.14) 数完整谱。
改用 Robin 图或增广 Cauchy relation 是候选修复，但须重建图可逆性、核/场同构和 residue，不能仅宣布“换图即可”。

## 7. 一般二维内部 gap 的剩余 PDE 门

这里列的是对 H1–H4 的具体核验路线，不另建重复问题账目；总体状态交由 [[research/explorations/interface-threshold/STATUS]] 维护。

| 门 | 精确需要的命题 | 可用路线 | 当前一般模型状态 |
|---|---|---|---|
| G1 | 除有限临界根外，复 cell pencil 在两条权线一致可逆 | 周期 Floquet transform、解析 Fredholm、cell 椭圆估计 | 需证明指定材料/频窗的谱隔离 |
| G2 | 有界尾等于临界常幅波加指数余项；无漏失通道 | 将加 cutoff 的尾作 Floquet–Laplace 变换，移动积分线并取所有 residues | Nazarov Theorem 3.1 给结构先例；本模型的准周期/零阶跳跃适配需完成 |
| G3 | $\mathcal T_\pm(0)$ 同构，而不只是单射 | 权线 Fredholm 指数＋端口核/余核分析；必要时重选图 | 真实表面 pole 可使其失败，不能由 bulk 条件替代 |
| G4 | 阈值无 $L^2$ 态，或者将其分离并保留 $\tau^{-2}$ 项 | 增广 Cauchy 关系、局部谱投影、精确能量/对称分析 | 不能由简单 bulk edge 推出 |
| G5 | 有限秩 coefficient 对指定局部缺陷可见 | 开集正缺陷＋唯一延拓，或直接核验有限维 overlap | 上述开集正缺陷情形已明确闭合 |

**G2 的具体证明骨架。** 对右端齐次解 $u$，将 $\zeta u$ 延拓到整个周期柱，其中 $\zeta$ 只在远端等于一。
其源 $[-\Delta,\zeta]u$ 支撑于有限 collar。先在 $\operatorname{Im}\theta=-\gamma$ 上对 $\zeta u$ 作 Floquet–Laplace 变换；该权线使右端至多有界/慢增长的函数可积。
fiber 方程由 $\mathcal L_+(\theta,\mu)^{-1}$ 精确求解，再将逆变换线移到 $\operatorname{Im}\theta=+\gamma$。
权线上的有界逆给 $H^1_\gamma$ 余项；移动过程中所有特征根的 residues 给完整慢模空间。
在简单二次阈值，双根的 residue 产生一个 Bloch 波和一个线性增长的广义 Bloch 波；各 cell 范数有界排除后者。
在 $\tau>0$，两个简单根中向右增长的分支被 $L^2$ 条件排除。
这需要对 fiber 逆证明一致 $H^{-1}\to H^1$ 界，以及源变换/积分线移动的合法性；不能只计算两个形式上的根就算完成。

Nazarov 的 Theorem 3.1（pp.1127–1129）在其光滑 periodic-outlet 系统设定中给加权 Fredholm 与带估计的完整渐近分解；Proposition 4.1（pp.1133–1134）给 Jordan 分裂。
本文未将其“Dirichlet/Neumann 几何边界、指定算子系统”的全部条件直接等同于本题 fixed-$\beta$、分片质量条带。
因此 B2–B4 是可审核的充分条件定理，而不是声称 G1–G4 已对所有目标材料成立。

## 8. 真正耦合、但比一般内部 gap 简单的中间族

### 8.1 定义与可证明目标

固定 $L=1$、$\beta=1$、$d_-=d_+=1$ 及 $\ell=\pi/(2\sqrt3)$。取

$$
\rho_{\eta,t}(x,y)=
\begin{cases}
1,&x<0,\\
7+t,&0<x<\ell,\\
4,&x>\ell
\end{cases}
+\eta\cos(2\pi x)\cos(2\pi y).
\tag{B.17}
$$

仅考虑 $|\eta|<1/2$、$|t|<1$，故密度一致正。
$\eta$ 改变整条波导的二维耦合；$t$ 只调谐中心。调谐完成后另用 $\varepsilon>0$ 增加中心密度，即 $t\mapsto t+\varepsilon$。
这是用户授权的中间研究模型，不是将现有 I10 材料替换后继续旧实验。
对任意 $\eta\ne0$，两端及中心均横向耦合；§2 证明其不具有有限横向 Fourier 闭子空间。

**命题 B5（模型级定理，修补后通过独立审查）。** 存在 $\eta_0>0$ 及实解析函数 $\mu_*(\eta)$、$t_*(\eta)$，满足 $\mu_*(0)=1/4$、$t_*(0)=0$。
对 $|\eta|<\eta_0$，右周期端有唯一的简单二次谱底边缘 $\mu_*(\eta)$，左端在其邻域处于严格 gap。
当 $t=t_*(\eta)$ 时，全局有一维有界非 $L^2$ 阈值解空间，且一个固定小的下邻域没有未扰动本征值。
充分小 $\varepsilon>0$ 的中心增重恰在该邻域产生一个简单本征值，并且

$$
\mu(\eta,\varepsilon)
=\mu_*(\eta)-b(\eta)^2\varepsilon^2+O(\varepsilon^3),
\qquad b(\eta)>0,
\qquad b(0)=\frac{\pi+2}{32\sqrt3}.
\tag{B.18}
$$

这里结论只针对明确的小邻域，不宣称更远处没有其他谱；它是**真正二维耦合的谱底族**，不证明有限内部 gap 的一般适配。

### Proof：B5 的连续链条

**第一步：cell 谱及复权线。** $\eta=0$ 时，右 cell 的所有精确本征值为

$$
\lambda_{m,n}(\theta)=\frac{(2\pi m+\theta)^2+(1+2\pi n)^2}{4},
\quad m,n\in\mathbb Z,
\tag{B.19}
$$

其最低点是 $(\theta,m,n)=(0,0,0)$、$\mu_*=1/4$，简单，曲率系数 $a=1/4$。
左端对应分母为一，谱底为 1，与右端有正分离。
在复权线 $\operatorname{Im}\theta=\pm\gamma$ 上取充分小固定 $\gamma>0$，(B.19) 的 Fourier 逆给一致 $H^{-1}\to H^1$ 估计；高 $|m|+|n|$ 项由二次增长控制，有限低模与零分离。
下面的闭带去盘估计先在 $|\operatorname{Im}\theta|\le2\gamma$ 上成立（必要时缩小 $\gamma$），从而满足 B1 的隔离约定；实际轮廓移动使用内侧权线 $\pm\gamma$。
质量调制是有界 $H^1\to H^{-1}$ 扰动，故权线可逆性由 Neumann 级数对所有模式同时保留，不是只对有限子块保留。
还须排除权线**内部**的其他根。取包含零点的小圆盘 $U$，使其闭包位于复带内部。基准时，在准动量闭基本区间与 $|\operatorname{Im}\theta|\le2\gamma$ 中去掉 $U$ 的紧集上，所有低模分母均非零，高模分母与 $1+m^2+n^2$ 一致可比；故完整 Fourier 逆的 $H^{-1}\to H^1$ 范数一致有界。Neumann 级数在这一整个紧集上排除小 $\eta$ 的所有特征根。盘内将简单 cell 空间和其精确补空间分离；解析带函数给
$\lambda(\theta,\eta)-\lambda(0,\eta)=\theta^2 a(\theta,\eta)$，其中 $a$ 在缩小的盘内非零。下面的反射对称性使一次项为零，因而在 $\mu=\mu_*(\eta)$ 恰保留一个二重根，而非仅知道两条权线上没有根。
简单 cell Riesz 投影和 B1 给 $(\theta,\eta)$ 的解析临界带及 Bloch 函数。
$x$ 反射对称使该带对 $\theta$ 偶；正曲率和远离 $\theta=0$ 的谱分离随小 $\eta$ 保留，所以真实右谱底仍在 $\theta=0$，记为 $\mu_*(\eta)$。
实谱的同样形式比较使左端继续高于它。

**第二步：基准端问题同构，含全部 Fourier 通道。** 右端 $n=0$ 在阈值是 $-v''=f$；允许尾部常数并给定 $v(0)=g$ 后，对光滑指数衰减源可写

$$
v(s)=g+\int_0^s\int_r^\infty f(z)\,\mathrm dz\,\mathrm dr,
\qquad
v(\infty)=g+\int_0^\infty zf(z)\,\mathrm dz.
\tag{B.20}
$$

对一般 $H^{-1}_\gamma$ 的临界模源，由加权 $H^1$ 空间的 Riesz 表示可写 $f=f_0-\partial_s f_1$，其中 $f_i\in L^2_\gamma$，且二者范数之和受 $C_\gamma\|f\|_{H^{-1}_\gamma}$ 控制；$C_\gamma$ 只来自对 $\mathrm e^{-\gamma s}\phi$ 求一次导数及固定横向模的范数等价。令 $Tg(s)=\int_s^\infty g(z)\,\mathrm dz$。将指数权移入积分并用 Young 不等式得

$$
\|Tg\|_{L^2_\gamma}\le\gamma^{-1}\|g\|_{L^2_\gamma},\qquad
v'=Tf_0+f_1,\qquad
c=g+\int_0^\infty sf_0(s)\,\mathrm ds+\int_0^\infty f_1(s)\,\mathrm ds.
$$

于是 $v-c=-T(v')$，且
$|c-g|\le(2\gamma^{3/2})^{-1}\|f_0\|_{L^2_\gamma}+(2\gamma)^{-1/2}\|f_1\|_{L^2_\gamma}$。这给 $v-\chi_+c\in H^1_\gamma$ 及全部所需范数界；其弱方程为 $-v''=f$、迹为 $g$。齐次方程中有界尾只能为常数，零迹又迫使常数为零，所以该逆唯一。公式先对光滑源成立，再由上述有界估计延拓，不要求一般 $H^{-1}$ 源有点值。
右端所有 $n\ne0$ 为 $-v_n''+[(1+2\pi n)^2-1]v_n=f_n$，左端所有 $n$ 为 $-v_n''+[(1+2\pi n)^2-1/4]v_n=f_n$。
取 $\gamma$ 小于这些正衰减率的统一下界。对一个快通道记其率为 $\kappa_n$，置 $V_n=\mathrm e^{\gamma s}v_n$，共轭算子为 $-\partial_s^2+2\gamma\partial_s+\kappa_n^2-\gamma^2$。零 Dirichlet 迹时，漂移项的二次型实部为零，因此

$$
\operatorname{Re}\mathfrak a_{n,\gamma}(V_n,V_n)
=\|V_n'\|_2^2+(\kappa_n^2-\gamma^2)\|V_n\|_2^2
\ge c_\gamma\big(\|V_n'\|_2^2+(1+q_n^2)\|V_n\|_2^2\big),
$$

其中 $c_\gamma=\min\{1,\inf_n(\kappa_n^2-\gamma^2)/(1+q_n^2)\}>0$，下确界取相应快通道。连续性亦对该能量范数一致；Lax–Milgram 因而给整个无限直和的有界逆。
边界 lifting $g_n\mathrm e^{-\kappa_ns}$ 的能量与 $(1+n^2)^{1/2}|g_n|^2$ 可比，正好对应 $H^{1/2}$ 迹范数；求和因此合法。
这证明基准 H1。中心 Dirichlet 在最低通道的特征值为 $12j^2-3/4>0$、$j\ge1$，其他通道更高，所以 H2 也成立。
将慢 Bloch 波显式加进 (B.7) 后，其整个算子随 $(\eta,\tau)$ 解析；基准有界逆由 Neumann 级数延续到小 $\eta$。

**第三步：全部物理尾的完备性。** 第一步已给两条复权线的一致逆和其中只有一个临界双根。
具体将带 cutoff 的尾 $U$ 延拓到全周期柱；其源 $f=[-\Delta,\zeta]u$ 在 $L^2$ 中且支撑有限个 cell。对 $s\in(0,d)$ 定义

$$
\widehat U(\theta;s,y)=\sum_{k\in\mathbb Z}
\mathrm e^{-\mathrm i\theta(s+kd)}U(s+kd,y).
$$

源的变换是 $L^2$-cell 值的有限和整函数；有界尾在 $\operatorname{Im}\theta=-\gamma$ 上属于相应负权 $H^1$ 空间。该线上的精确 fiber 方程由逆解出。对每个固定 cell 编号 $k$，
$\mathrm e^{\mathrm i\theta(s+kd)}\mathcal L(\theta,\mu)^{-1}\widehat f(\theta)$ 是 $H^1$-cell 值亚纯函数，可在有限矩形内用 Cauchy 公式。在两竖边，$\theta\mapsto\theta+2\pi/d$ 使变换和 fiber 解乘 $\mathrm e^{-2\pi\mathrm i s/d}$，外因子恰好抵消，故竖边积分相消。上权线逆的一致 $H^{-1}\to H^1$ 界与 Floquet Plancherel 给余项的全 cell $H^1_\gamma$ 范数控制。第一步的闭带根排除保证轮廓移动只遇到所列临界根，不漏掉别的 residues。
简单 cell 投影把局部逆写成秩一极点项加解析有界余项；在 $\tau=0$ 其分母有二阶零，因此 residue 只有 Bloch 波和线性增长的广义波。
有界条件消去线性项，$L^2$ 条件又消去常幅项；$\tau>0$ 时消去增长支。于是 H3 成立，且阈值 $L^2$ 解必为正权衰减类。

**第四步：中心调谐而不是预设共振。** 在 $(\eta,t)=(0,0)$，[[research/explorations/interface-threshold/deep_investigation#6.3 推论 5：不用点相互作用的正密度 Helmholtz 例子|已证显式正共振]] 给一维全局阈值核，且无阈值 $L^2$ 态。
B2 给无限维 $F(\tau,\eta,t)$；在基准一维核的固定正交补上作**精确** Schur 消元，得到实解析标量 $s(\tau,\eta,t)$。
它满足 $s(0,0,0)=0$，由 B3 有 $s_\tau(0,0,0)>0$。
中心质量微分式给

$$
s_t(0,0,0)=-\mu_*(0)\int_{(0,\ell)\times(0,1)}|h|^2<0,
\tag{B.21}
$$

其中 $h$ 是与选定单位边界核向量对应的基准共振；归一化影响数值但不影响严格负号。
隐函数定理给唯一实解析调谐曲线 $t=t_*(\eta)$，使 $s(0,\eta,t_*(\eta))=0$。
其附近补空间仍可逆，故阈值核维数恰为一；该核的右临界幅度由连续性保持非零，所以它不是 $L^2$ 态。
若另有阈值 $L^2$ 态，第三步和 H1–H2 会将它映到同一核，但其幅度必须为零，矛盾；因此这里 H4 得到实际核验。

**第五步：真正的连续分岔。** 缩小统一邻域，$s_\tau>0$、$s_t<0$ 持续成立。
未扰动调谐点满足 $s(0)=0$，所以小正 $\tau$ 无根；中心加 $\varepsilon>0$ 后，$s(0)<0$，固定小正端点处 $s>0$，严格单调性给唯一简单根。
精确核/场同构和第三步排除遗漏的 $L^2$ 解，故这是原连续 fiber 的本征值，而不只是标量近似的根。
其展开为 $\tau=b(\eta)\varepsilon+O(\varepsilon^2)$，其中 $b(\eta)=-s_t/s_\tau>0$ 取于调谐阈值；平方得 (B.18)。
基准系数由上述已证推论 5 给出，故 $b(0)$ 如式所列。
最后需要的是不带指数权的 $H=L^2(B,\rho)$ 上的 resolvent，不能只使用 B2 的加权源解。此模型是谱底：半波导零 Dirichlet 函数可零延拓为全周期柱的 $H^1$ 函数，所以各半波导 Dirichlet Rayleigh 商不低于对应 bulk 谱底。对每个 $\mu<\mu_*(\eta)$，两端零迹实现严格正定，因而有整个 $L^2$ 上的有界逆；该逆允许随 $\tau\downarrow0$ 发散。中心由 H2 保持可逆。小正 $\tau$ 的 Poisson 解属于 $L^2$，源法向迹连续；因此对任意 $H$ 源，零迹分块逆加 $P(\tau)F(\tau)^{-1}$ 的精确拼接给整个 $H$ 上的有界逆。未扰动调谐点的小正 $\tau$ 没有核，就确实得到 resolvent 小窗；扰动后只有上述简单根。故 B4 也适用。证毕。

### 8.2 该中间结果值在哪里，限制又在哪里

该族不再可分离，临界 Bloch 波包含无限横向 Fourier 分量；半波导余项与中心补空间都是无限维。
真正有限维的只有隔离阈值共振核，有限约化前已经证明全部其他通道的有界可逆性。
调谐曲线是存在性结果，不是已经给出的闭式材料参数，也没有通过计算拟合它。
该族位于谱底，常系数基准的全通道估计使小调制可处理；一般有限内部 gap 没有这里直接可用的基准加权逆。
因此它是向一般问题前进的一座桥，不是将“近分层”改名为所有二维异质周期介质。

## 9. 来源、审查门与证明交接

### 9.1 已核原始来源及实际依赖

1. N. Aronszajn, *A unique continuation theorem for solutions of elliptic partial differential equations or inequalities of second order*, J. Math. Pures Appl. 36 (1957), 235–249。已读 [原文扫描](https://sites.math.washington.edu/~blwilson/Nodal/Aronszajn.pdf) 的无编号主定理及条件，印刷 pp.235–236/PDF pp.1–2；用于 §6.1 的唯一延拓，条件对应已逐项写明。
2. S. A. Nazarov, *Threshold resonances and virtual levels in the spectrum of cylindrical and periodic waveguides*, Izv. Math. 84(6) (2020), 1105–1160，[DOI](https://doi.org/10.1070/IM8928)、[原文](https://www.mathnet.ru/php/getFT.phtml?jrnid=im&paperid=8928&what=fullteng)。本轮核 Theorem 3.1、Proposition 4.1 和 Remark 4.1；用于确认加权渐近及非平方根先例，不把未核适配当作 B2–B5 的黑箱。
3. Fliss 2013 Theorems 4.1、4.5 与 Behrndt–Rohleder 2015 Theorems 4.1、4.7 的既有核验见 [[research/explorations/interface-threshold/research_landscape|文献地图]]；它们提醒 Dirichlet 图例外及零迹可见性。本轮拼接恒等式已在 §6 自行说明。
4. Fliss–Joly–Lescarret 2021 *A DtN approach to the mathematical and numerical analysis in waveguides with periodic outlets at infinity*，[DOI](https://doi.org/10.2140/paa.2021.3.487)。作者页指向 HAL；本轮公开入口返回访问防护页，未绕过，也未将其未知定理当作证明输入。

本轮不下载新 PDF、不修改参考目录；Aronszajn1957 与上述 Nazarov 全文在线核验。若日后允许归档，建议分别用 `Aronszajn1957.pdf`、`Nazarov2020.pdf` 并同步书目；此处不是已下载声明。

### 9.2 独立审查的重点与修补

1. B2 的 $H^{1/2}\to H^{-1/2}$ 正则性及 compact-perturbation Fredholm 论证，尤其零阶跳跃下的 collar 估计。
2. B3 中归一化 (B.5)、几何级数常数和算子范数余项，防止漏掉 cell 长度或尾部幅度。
3. B4 的源迹正负号、固定 Riesz 度量、加权伴随及 $\tau^{-1}$ residue 的秩。
4. B5 第二、三步的全通道加权逆与 Floquet contour 完备性；这是最不能以“标准”二字跳过的模型级环节。

**审查结果。** B1–B4 在明确条件下通过。B5 初稿被要求补充闭复带去盘根排除、一般 $H^{-1}_\gamma$ 源的 Hardy 界、全部快通道强制性、具体 Floquet 轮廓/Plancherel 链，以及不带指数权的 $H$ 上真正的 resolvent。上述补证现已落入 §8，并经独立 `proof_skeptic` 复核为 **VERIFIED**；无需降为仅在预设渐近类内成立。唯一延拓来源亦独立核对。

这个通过只覆盖所定义的小调制谱底模型和条件桥梁，不包含可认证的 $\eta_0$ 数值、调谐曲线数值或原创优先权。对一般内部 gap，G1–G4 仍是限制完整适配的 important caveat；它们不推翻已证明的条件桥梁。

### 9.3 证明交付记录

- Source file：当前任务给出新桥梁问题；既有依据为 `deep_investigation.md` 的命题 1、定理 2–3、推论 5。
- Output file：仅本文件；新命题 B1、B2、B3、B5，定理 B4，Proof 段为各命题后明确位置；公式 B.1–B.21 为手工编号。
- 授权范围：本文件内新定义、证明、条件与中间模型；没有覆盖旧证明或修改其他文件。
- 状态：**B1–B5 证明通过独立审查，范围限各自陈述。** 证明实际依赖的来源核验已完成；研究优先权的文献排查仍未完成。B5 是真正二维的小调制谱底族，不代表一般二维内部 gap 问题完成。
- 未验证事项：一般内部 gap 的加权端同构与完备性没有实例化；未核 Fliss–Joly–Lescarret 2021 的全文定理；未给可认证参数范围、实际材料实例或复杂度。
- 检查：仅文档、记号、来源条件与解析论证；没有 MATLAB/Octave、Fourier 数值截断、数值求根或实验结果。
