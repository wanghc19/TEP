# Rayleigh 端口截断对简单导模根的影响

进度

- done　已证明完整条带宽度的根误差上界、显式选阶条件、切线不变性及双侧系数首阶公式。
- next　若要为单个算例公布可靠的 $M$，将目标谱窗、隔离量和几何下界代入 (15)。
- open　三个算例的锐指数、全阶导模的双侧复系数尾以及 W3 的圆心奇性解释。

对简单孤立的全阶根，精确胞元的截断根满足 $|k_M-k_*|\le C e^{-q_M^*w_{\min}}$，其中 $q_M^*$ 是全部删去阶中最小的衰减率。式 (15) 给出带显式常数的充分阶数，式 (23a) 进一步利用导模的正则性。

rayleigh-truncation 指截去端口上的高阶 Rayleigh 波。BIE 为边界积分方程，DtN 为 Dirichlet-to-Neumann 映射，W3 指缺失三排圆杆的波导。模式为 Proof from scratch。

## 1. 比较对象与编号假设

1. **连续模型。** 设 $B=\mathbb R\times I_d$，$I_d=(-d/2,d/2)$，$\beta$ 为固定实数。实介质系数满足 $0<\rho_{\min}\le\rho\le\rho_{\max}<\infty$，关于 $y$ 以 $d$ 为周期，两端在有限中心区以外分别等于其周期引线。背景系数为常数 $\rho_{\mathrm e}>0$。在 $\mathcal H=L^2(B,\rho)$ 上取 $A=-\rho^{-1}\Delta$，令 $V=H^1_\beta(B)$ 为满足 $y$ 向准周期相位 $e^{\mathrm i\beta d}$ 的能量空间。记

   $$
   a[u,v]=\int_B\nabla u\cdot\overline{\nabla v},\qquad
   b[u,v]=\int_B\rho u\bar v,\qquad
   (u,v)_V=a[u,v]+b[u,v].
   \tag{1}
   $$

   内积对第一变量线性。以上正有界系数、两端周期性和相同的横向相位正是 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]] 定理 T1.1 的假设。该定理给出自伴非负算子、闭型 (1) 及两条周期引线的谱并等于本质谱。全阶导模是该算子的平方可积特征函数。
2. **几何。** 沿 $x$ 排列含散射体的竖直块。相邻块间的开条带 $G_j=(l_j,r_j)\times I_d$ 全部由背景填充，$w_j=r_j-l_j$。所列条带与实际实施截断的间隔一一对应，每个 $G_j$ 含至少一条切线。无端口截断的内部空白并入所在块。假设 $0<w_{\min}=\inf_j w_j$，条带及含散射体块均来自有限种模板，宽度有统一上界，非空块宽度有正下界。远场的几何块和端口布局按各自引线周期重复。$\ell^2$ 求和覆盖两条半无限引线。可以取 $l_j$ 为左散射体的最大 $x$ 坐标、$r_j$ 为右散射体的最小 $x$ 坐标，只需开条带为背景。证明使用平面两侧的弱迹，容许端面接触散射体的极值点。一个无散射体的中心胞及其两侧空白可合为一个 $G_j$。若一个引线周期由两排分别求解再作端口连接，内部接合也要列入。
3. **精确端口模型。** 沿用 [[research/projects/bie-enclosure/theory/port-subspace|port-subspace]] 假设 2。对
   $\psi_m=d^{-1/2}e^{\mathrm i\beta_m y}$、$\beta_m=\beta+2\pi m/d$，$P_M$ 表示保留 $|m|\le M$ 的 Fourier 投影，$M$ 为非负整数，$K=2M+1$。令 $\gamma_m(k)^2=\rho_{\mathrm e}k^2-\beta_m^2$，实频取正实或正虚的根。给定保留阶的入射，各胞内精确求解 $-\Delta u=\lambda\rho u$，材料界面匹配值和同向法向导数，横向遵守同一准周期条件。删去阶的入射为零，出射场仍含所有阶。相邻胞元仅连接 $P_M$ 范围内的总端口状态。假设实频窗口内各模板的单胞解存在、唯一且线性，有有限的分片能量及背景端口迹。若先合并两个子胞，所用的内部消元须可逆，或直接保留内部接合条件。模式由非零场及平方可和的引线状态定义，使用 `eq:nep` 的子空间匹配。有限维入射和有限模板保证每个固定 $M$ 的重建有界。全阶的值和同向法向导数在每条切线上匹配，逐片 Green 公式即给出 (1) 的弱方程，反向由全局解取迹得到。
4. **简单根和工作窗口。** $\lambda_*=k_*^2>0$ 是 $A$ 的孤立简单特征值。令 $g>0$ 为其到 $\sigma(A)\setminus\{\lambda_*\}$ 距离的一个下界，取 $0<r<\min(g,\lambda_*)$，$U_r=\{\lambda\in\mathbb C:|\lambda-\lambda_*|\le r\}$ 及其实轴直径 $I_r$。工作窗口避开 Wood 阈值 $\beta_m^2/\rho_{\mathrm e}$。选一个固定 $M_0$，使 $b_{M_0}^2>\rho_{\mathrm e}(\lambda_*+r)$，其中

   $$
   b_M=\min_{|m|>M}|\beta_m|,\qquad
   q_M(r)=\sqrt{b_M^2-\rho_{\mathrm e}(\lambda_*+r)},\qquad
   q_M^*=\sqrt{b_M^2-\rho_{\mathrm e}\lambda_*}.
   \tag{2}
   $$

   以下 $M\ge M_0$。若 $|\beta|\le\pi/d$，则 $b_M=2\pi(M+1)/d-|\beta|$。在 $\beta>0$ 时最慢删去阶通常是 $-(M+1)$。全频率窗口统一使用 $q_M(r)$，在目标根处使用 $q_M^*=\min_{|m|>M}|\gamma_m(k_*)|$。$g$ 同时控制窗口与其他缺陷特征值、两侧引线谱的分离。

## 2. 整个背景条带上的删阶算子

**命题 1（在假设 1–4 下已证明）。** 令 $\mathcal T(\lambda)$ 为全阶弱方程在 $V$ 上的 Riesz 算子，即 $(\mathcal T(\lambda)u,v)_V=a[u,v]-\lambda b[u,v]$。精确截断模型可在同一空间表示成 $\mathcal T_M(\lambda)=\mathcal T(\lambda)+\mathcal E_M(\lambda)$。对 $\lambda\in U_r$，

$$
\|\mathcal E_M(\lambda)\|_{V\to V}
\le \varepsilon_M:=\frac{2C_{\rm tr}^2 C_\kappa}{e^{q_M(r)w_{\min}}-1},\qquad
C_{\rm tr}^2=4\max(1,w_{\min}^{-1})\max(1,\rho_{\mathrm e}^{-1}),\quad
C_\kappa=\max(1,\sqrt{\rho_{\mathrm e}(\lambda_*+r)}).
\tag{3}
$$

算子族在该闭圆盘的一个邻域全纯，且 $\mathcal T_M(\bar\lambda)=\mathcal T_M(\lambda)^*$。在实轴上，其核与假设 3 的截断模态通过下述条带内重建一一对应。

**证明一　一个删去阶。** 在 $G_j$ 中取 $t=x-l_j$，$w=w_j$。写 $\kappa=\kappa_m(\lambda)=\sqrt{\beta_m^2-\rho_{\mathrm e}\lambda}$，取实轴上为正、在 $U_r$ 上实部为正的分支。设 $\alpha,\delta$ 为该阶在 $t=0,w$ 的总值系数。全阶模型的齐次方程为 $f''=\kappa^2 f$。给定两端值时，唯一解和该条带的外法向导数为

$$
 f(t)=\frac{\sinh(\kappa(w-t))}{\sinh(\kappa w)}\alpha+
      \frac{\sinh(\kappa t)}{\sinh(\kappa w)}\delta,\qquad
 \binom{-f'(0)}{f'(w)}
 =D_m(w,\lambda)\binom{\alpha}{\delta},\quad
 D_m=\kappa
 \begin{bmatrix}\coth(\kappa w)&-\operatorname{csch}(\kappa w)\\
 -\operatorname{csch}(\kappa w)&\coth(\kappa w)\end{bmatrix}.
\tag{4}
$$

设实际切线在 $0<t_c<w$。在截断模型中，左块朝右的删去阶只能是 $\alpha e^{-\kappa t}$，右块朝左的删去阶只能是 $\delta e^{-\kappa(w-t)}$。从背景条带一侧看，$t=0,w$ 的外向导数分别为 $\kappa\alpha,\kappa\delta$。故删阶恰把 (4) 换成 $\kappa I_2$。跨空中心的条带若有两条或更多同阶数的切线，内部空胞的该阶是无入射齐次解，向左右均出射迫使其为零。两端散射体仍各自看见同一个 $\kappa$。

置 $p=e^{-\kappa w}$，$S=\left[\begin{smallmatrix}0&1\\1&0\end{smallmatrix}\right]$。截断减全阶的差为

$$
\Delta_m(w,\lambda)=\kappa I_2-D_m
=\frac{2\kappa}{1-p^2}(pS-p^2 I_2).
\tag{5}
$$

交叉项的一次传播因子是 $p$，对角项从 $p^2$ 开始。此消元只作用于严格倏逝的删去阶，保留的传播阶不需要条带 Dirichlet 坐标。

**证明二　共同空间与无穷多个端口。** 记 $t_{jm}u=(u_m(l_j),u_m(r_j))^T$，其中 $u_m(x)=\int_{I_d}u(x,y)\overline{\psi_m(y)}\,dy$。定义

$$
 (\mathcal E_M(\lambda)u,v)_V
 =\sum_j\sum_{|m|>M}(t_{jm}v)^*\Delta_m(w_j,\lambda)t_{jm}u .
\tag{6}
$$

为证明连续性，令 $h_m=(1+\beta_m^2)^{1/2}$。在长为 $w$ 的条带上，对 $f\in H^1(0,w)$ 取 $s=\min(w,h_m^{-1})$。用 $f(0)=f(x)-\int_0^x f'(t)\,dt$ 并对 $0<x<s$ 平均，得

$$
h_m|f(0)|^2\le 2h_m s^{-1}\int_0^s|f|^2
                     +2h_m s\int_0^s|f'|^2 .
$$

这里 $h_m s\le1$，$h_m/s\le\max(1,w_{\min}^{-1})h_m^2$。右端面同理。加两端、对 $m$ 用 Fourier 正交性、对互不相交的 $G_j$ 求和，得到

$$
\sum_{j,m} h_m\|t_{jm}u\|_{\mathbb C^2}^2\le C_{\rm tr}^2\|u\|_V^2.
\tag{7}
$$

在 $U_r$ 上有 $\operatorname{Re}\kappa_m\ge q_M(r)$，因为对 $\operatorname{Re}z>0$ 有 $(\operatorname{Re}\sqrt z)^2=(|z|+\operatorname{Re}z)/2\ge\operatorname{Re}z$。另有 $|\kappa_m|\le C_\kappa h_m$。由 $S$ 的两个固定正交特征方向，(5) 的特征值分别为 $2\kappa p/(1+p)$ 和 $-2\kappa p/(1-p)$，故

$$
\sup_{j,|m|>M}\frac{\|\Delta_m(w_j,\lambda)\|_2}{h_m}
\le\frac{2C_\kappa}{e^{q_M(r)w_{\min}}-1}.
\tag{8}
$$

将 (7) 用于 (6) 的两列迹即可得 (3)，没有胞元数因子。各个 $\Delta_m/h_m$ 都全纯，在略大的圆盘上仍有统一上界。围绕任一内点使用 Cauchy 系数公式，得到各对角块 Taylor 系数统一的几何级数界。因此相应块对角乘子在算子范数下全纯，前后复合固定有界迹算子后 (6) 也全纯。对实 $\lambda$ 各块为实对称矩阵，复频满足 $\Delta_m(w,\bar\lambda)=\Delta_m(w,\lambda)^*$，给出所述伴随关系。

**证明三　与原端口模型等价。** 先取实 $\lambda\in I_r$。由截断解构造 $u\in V$ 时，保留各含散射体块中的完整场和条带中的所有保留阶，将每个条带的删去阶用 (4) 的两端值插值填满。在含散射体块上应用 (7) 的一维证明，以块宽下界代替 $w_{\min}$，可知原场的两端迹满足 $\sum_{j,m}h_m\|t_{jm}u\|^2<\infty$。原场在各胞分片的总能量有限，这由平方可和端口状态、精确单胞重建和有限种模板得到。令 $v_{\rm end}=(\alpha,\delta)^T$，对 (4) 分部积分有

$$
\int_0^w(|f'|^2+\kappa^2|f|^2)\,dt
=v_{\rm end}^*D_m v_{\rm end}
\le\kappa\coth(\kappa w/2)(|\alpha|^2+|\delta|^2),
$$

对删去阶有 $\inf\kappa>0$ 且 $h_m^2/\kappa^2$ 一致有界，所以新填入的场有有限 $H^1$ 能量。它在两端与原场值迹相同，故可拼入 $V$。具体地，对含散射体块积分并加上条带的保留阶积分。低阶的端面项相消。对高阶，左、右两含散射体块在相邻端面的外向导数系数分别是 $-\kappa\alpha,-\kappa\delta$，所以剩余弱方程在块积分与保留阶积分之外恰需加上 $\sum(t_{jm}v)^*\kappa I_2\,t_{jm}u$。新填入的高阶函数在条带中贡献 $D_m$，(6) 再加 $\kappa I_2-D_m$，得到同一弱方程。可先取 $x$ 向紧支撑、$y$ 向有限 Fourier 和的测试函数，再由 (7)、总能量有限及这些测试函数在 $V$ 的稠密性取极限。因此 $\mathcal T_M(\lambda)u=0$。

反向，若 $u\in\ker\mathcal T_M(\lambda)$，在条带内部取零端值测试函数，得到各阶齐次方程。删去阶由两端值唯一决定。将其换回两段纯出射指数，多切线之间的空胞对该阶取零，保留阶维持条带上的完整齐次解。由 (6) 和 Green 公式，在两端与含散射体块精确匹配法向导数，匹配在对偶迹意义下成立。具体地，有限个端面上任意有限 Fourier 多项式值都可用纵向分段线性测试函数延拓并独立指定，因此弱方程逐阶给出上述端面外向导数关系。切线上保留阶值和同向导数相等，删去阶正好满足假设 3 的单边出射条件。向单胞外的均匀背景按这些振幅延拓时，任一删去阶均朝外衰减，入射只含有限个指定阶，故单胞唯一性识别出同一个精确散射解。纯出射段的能量也由常数乘 $h_m(|\alpha|^2+|\delta|^2)$ 控制，故重建的分片能量可和。固定 $M$ 时，各切线上的保留阶在该均匀条带中满足二阶常系数方程。在有限种条带模板上，有限维保留解空间的能量范数控制其切线值、导数和非 Wood 振幅，故这些状态平方可和。单胞唯一性排除了全体保留入射均为零的非零胞内场。两种重建互逆。证毕。

从而，“压缩”的精确含义是截掉跨条带传递的高阶入射。胞内高阶出射仍由精确散射求出，(6) 在同一能量空间上给出这一操作的差。两种重建的有界性只需对各固定 $M$ 成立。控制根误差的统一常数来自物理值迹的 (7)，从而避开了高阶振幅反向重设锚点时的指数放大。

## 3. 简单根位移与选阶规则

**定理 2（在假设 1–4 下已证明）。** 取

$$
G=1+\frac{1+\lambda_*+r}{g-r}.
$$

若 $M\ge M_0$ 满足

$$
G\varepsilon_M\le\tfrac12,\qquad 8(1+\lambda_*)\varepsilon_M<r,
\tag{9}
$$

则在 $U_r$ 中 $\mathcal T_M$ 有唯一特征根 $\lambda_M$，为简单实根，$k_M=\sqrt{\lambda_M}>0$ 是截断端口的导模根。其频率位移满足

$$
\boxed{\displaystyle
 |k_M-k_*|\le
 \frac{2(1+\lambda_*)}{k_*+\sqrt{\lambda_*-r}}\,
 \frac{2C_{\rm tr}^2 C_\kappa}{e^{q_M(r)w_{\min}}-1}.}
\tag{10}
$$

特别地，存在与 $M$、切线位置均无关的 $C$，使 $|k_M-k_*|\le C e^{-q_M^*w_{\min}}$ 对所有充分大的 $M$ 成立。

**证明一　完整问题的补空间。** 取 $A$ 在 $\lambda_*$ 的特征函数 $\phi$，归一化 $\|\phi\|_V=1$，故 $b[\phi,\phi]=1/(1+\lambda_*)$。令 $P$ 为 $V$ 中到 $\mathbb C\phi$ 的正交投影，$Q=I-P$。在 $D(A)$ 上，$\|(A+I)^{1/2}u\|_{\mathcal H}^2=\|u\|_V^2$。T1.1 给出 $D(A)=H^2_\beta(B)$，其包含的光滑准周期、$x$ 向紧支撑函数在 $V$ 稠密。因此该等距映射延拓到 $V$。其值域包含各有界谱区间的谱子空间，取闭包即得整个 $\mathcal H$。由 (1) 和谱定理，这个酉映射把 $\mathcal T(\lambda)$ 化为 $(A-\lambda)(A+I)^{-1}$。所以 $P,Q$ 对整个全阶算子族约化。$P$ 块为标量

$$s(\lambda)=\frac{\lambda_*-\lambda}{1+\lambda_*}.$$

$Q\mathcal T(\lambda)|_{QV}$ 的逆在 $U_r$ 上范数至多为 $G$。这是因为对 $t\in\sigma(A)\setminus\{\lambda_*\}$ 有 $|t-\lambda|\ge g-r$ 且 $(1+t)/|t-\lambda|\le1+|1+\lambda|/|t-\lambda|$。对其加上 $Q\mathcal E_M|_{QV}$，Neumann 级数给出

$$
H_M(\lambda)=\big(Q\mathcal T_M(\lambda)|_{QV}\big)^{-1},
\qquad \|H_M(\lambda)\|\le G/(1-G\varepsilon_M)\le2G .
\tag{11}
$$

实自伴问题的简单性在此给出一维主块，且 $s'=-1/(1+\lambda_*)$ 精确已知。

**证明二　唯一实根。** 将未知量写作 $c\phi+v$，$v\in QV$。由 $Q$ 行得 $v=-cH_MQ\mathcal E_M\phi$，其中各算子取在同一个 $\lambda$。故非平凡核等价于下列全纯标量为零，

$$
s_M=s+e_{00}-
 (\mathcal E_M H_M Q\mathcal E_M\phi,\phi)_V,\qquad
e_{00}=(\mathcal E_M\phi,\phi)_V .
\tag{12}
$$

式中 $QV$ 自然嵌回 $V$。当 $s_M\ne0$ 时，两行回代也对任意右端给出唯一有界逆。由 (3)、(11)，

$$
\sup_{U_r}|s_M-s|\le\varepsilon_M+
   \frac{G\varepsilon_M^2}{1-G\varepsilon_M}
=\frac{\varepsilon_M}{1-G\varepsilon_M}\le2\varepsilon_M .
\tag{13}
$$

圆周上 $|s|=r/(1+\lambda_*)>2\varepsilon_M$。Rouché 定理给出 $s_M$ 恰有一个零点，按重数计。其计数理由是 $s+\theta(s_M-s)$ 对 $0\le\theta\le1$ 始终在圆周上非零，绕原点的圈数恒定，由辐角原理等于圆内零点数。又因 $\mathcal T_M(\bar\lambda)=\mathcal T_M(\lambda)^*$，(12) 的两项对角块及其 Schur 补给出 $s_M(\bar\lambda)=\overline{s_M(\lambda)}$。唯一零点必为实数。代入 (13) 得 $|\lambda_M-\lambda_*|\le2(1+\lambda_*)\varepsilon_M<r/4$。由 $k_M+k_*\ge k_*+\sqrt{\lambda_*-r}$ 得 (10)。命题 1 将该实根还原为截断模式。

由 (2) 有

$$
0\le q_M^*-q_M(r)=\frac{\rho_{\mathrm e}r}{q_M^*+q_M(r)}
\le\frac{\rho_{\mathrm e}r}{q_{M_0}^*+q_{M_0}(r)}.
\tag{14}
$$

因此 (10) 的指数可以换成 $-q_M^*w_{\min}$，常数至多再含 (14) 末端乘 $w_{\min}$ 的指数及 $1/(1-e^{-q_{M_0}(r)w_{\min}})$。写成单侧 $\kappa_{M+1}(k_*)$ 也只会改变渐近上界常数，因为两个符号的 $|\beta_m|$ 至多相差 $2|\beta|$，而 $b\mapsto\sqrt{b^2-\rho_{\mathrm e}\lambda_*}$ 的导数在 $b\ge b_{M_0}$ 上有界。实际选阶应使用 (2) 中较慢的一侧。证毕。

**引线子空间的适用性（已证明）。** 若以 `eq:pencil` 实现 (10) 所说的端口根，(9) 还足以保持两端引线的带隙。由 T1.1 及其 Bloch 分解式 (T1.2)，任一实 Bloch 相位下的纯周期引线胞元谱属于 $\sigma(A)\setminus\{\lambda_*\}$。故上述 $G$ 也是每个引线纤维的完整型算子的逆范数上界。逐周期使用 (6)–(8)，跨越周期边界的条带用模为一的 Bloch 相位拼合，迹范数保持，界与相位无关。于是 $G\varepsilon_M<1$ 排除实窗口内所有截断引线纤维的核。若 `port-subspace.md` 式 (1) 的散射铅笔在单位模 $\zeta$ 处奇异，相应的非零端口状态便在一个周期构成 $\zeta$-准周期解，与此排除矛盾。故其正则且没有单位模乘子。该文件引理 A 适用，平方可和状态正是草稿 $\mathsf Z_\pm$ 的范围。若周期内有子胞，可先作同相位的逐排匹配，内部消元条件见假设 3。

**给定目标误差时选 $M$（在几何与谱输入已知时成立）。** 令 $\tau>0$ 为频率容差，取

$$
\eta_\tau=\min\!\left\{\frac1{2G},\frac{r}{8(1+\lambda_*)},
 \frac{(k_*+\sqrt{\lambda_*-r})\tau}{2(1+\lambda_*)}\right\}.
$$

从传播阶下限起，取满足

$$
b_M>\sqrt{\rho_{\mathrm e}(\lambda_*+r)+
   w_{\min}^{-2}\log^2\!\big(1+2C_{\rm tr}^2C_\kappa/\eta_\tau\big)}
\tag{15}
$$

的 $M\ge M_0$，即有 (9) 且 $|k_M-k_*|<\tau$。此规则给出的充分阶数对 $\tau^{-1}$ 按对数增长，首项比例为 $d/(2\pi w_{\min})$。若输入是可靠目标区间 $0<L\le\lambda_*\le U$ 及该区间到其余谱的下界 $g$，取 $r<\min(L,g)$，在 $G,C_\kappa$ 及 (15) 的上端用 $U$，在 $\eta_\tau$ 的最后一项用 $(\sqrt L+\sqrt{L-r})\tau/[2(1+U)]$，中间一项用 $r/[8(1+U)]$。同时在 $C_{\rm tr}$ 与 (15) 中用已证明的几何下界代替 $w_{\min}$。这些替换给出只依赖区间数据的充分规则。仅知与两条引线能带的距离，尚不能给出与其他缺陷特征值的距离。

## 4. 切线位置、线性或二次、锐率、传播阶

### 4.1 切线位置（已证明）

对每个固定的 $M$，在假设 1–3 的实频解范围内，只要物理散射体和保留阶不变，切线在各自均匀条带内的移动保持截断根集合。这个结论在 (9) 之前就成立。命题 1 的算子只含条带两端 $l_j,r_j$，其核对每个切线位置都与对应截断模式双射。

也可直接看振幅。若切线右移 $s$，保留状态 $(a,b)$ 变为 $(\mathsf E(s)a,\mathsf E(-s)b)$，其中 $\mathsf E(s)=\operatorname{diag}(e^{\mathrm i\gamma_m s})$。平移的逐阶公式与舍阶的顺序可交换，在保留空间上给出有限维可逆变换。跨越切线时，一侧的总出射就是另一侧的入射，这里总出射包含直接透射和所有多次散射。在间隔的两段分别传播距离 $\delta_1,\delta_2$，一个严格倏逝阶的一次传递因子为

$$
 e^{-\kappa_m\delta_1}e^{-\kappa_m\delta_2}=e^{-\kappa_m w_j},
 \qquad \delta_1+\delta_2=w_j .
\tag{16}
$$

删去阶的单向出射条件在平移后仍是同一条件。对固定 $M$，有限模板和有界位移还保证变换与逆变换在无限胞元的 $\ell^2$ 直和上有界。左右胞元的锚点、散射矩阵与周期接合须一致重设。单个 Dirichlet 迹块 $\mathsf D_s$ 的奇异值和极点位置可以随切线变动。[[research/projects/bie-enclosure/theory/port-subspace|port-subspace]] 定理 B 的 (16)、(19)–(20) 说明子空间匹配如何在这些位置表示同一个根。

### 4.2 线性或二次（已证明）

相对于删去的**跨间隔耦合**，简单根有一阶变分。自伴性使该变分是实二次型。它的一次传递项是两侧振幅的有符号乘积，能否抵消由模态决定。

**首阶公式。** 下式的 $\phi$ 仍按 $\|\phi\|_V=1$ 归一化。取 $\lambda=\lambda_*$、$\kappa_m=\kappa_m(\lambda_*)$，令 $p_{jm}=e^{-\kappa_m w_j}$。在第 $j$ 条带中把全阶模态的删去阶写为

$$
\phi_m(l_j+t)=A_{jm}^{\to} e^{-\kappa_m t}
                 +B_{jm}^{\leftarrow} e^{-\kappa_m(w_j-t)} .
\tag{17}
$$

$A_{jm}^{\to}$ 锚在左端，$B_{jm}^{\leftarrow}$ 锚在右端。定义两个尾量

$$
\begin{aligned}
L_M
 &=\sum_{j,\,|m|>M}\kappa_m p_{jm}
          \operatorname{Re}\!\left(\overline{A_{jm}^{\to}} B_{jm}^{\leftarrow}\right),\\
R_M
 &=\sum_{j,\,|m|>M}\kappa_m p_{jm}^2
             (|A_{jm}^{\to}|^2+|B_{jm}^{\leftarrow}|^2).
\end{aligned}
\tag{18}
$$

$L_M$ 是有符号的一次传递项，$R_M$ 是非负的两次传递项。在 (9) 下，

$$
\begin{aligned}
k_M-k_* &=
 \frac{1+\lambda_*}{2k_*}
   (\mathcal E_M(\lambda_*)\phi,\phi)_V+O(\varepsilon_M^2),\\
(\mathcal E_M(\lambda_*)\phi,\phi)_V&=4L_M+2R_M,\\
|k_M-k_*|&\le
\frac{2(1+\lambda_*)}{k_*+\sqrt{\lambda_*-r}}
   \left[4|L_M|+(2+8G C_{\rm tr}^2)R_M\right].
\end{aligned}
\tag{19}
$$

**证明。** (13) 与 Cauchy 导数估计给出 $|s'_M-s'|\le4\varepsilon_M/r$ 于 $|\lambda-\lambda_*|\le r/2$。实轴上 $s_M$ 为实值，(9) 保证这里 $-s'_M\ge1/[2(1+\lambda_*)]$。$\lambda_M$ 落在此区间内。在 $\lambda_*$ 处，令 $E=\mathcal E_M(\lambda_*)$，$H=H_M(\lambda_*)$。二者自伴，(12) 化为

$$s_M(\lambda_*)=(E\phi,\phi)_V-(H QE\phi,QE\phi)_V.$$

后一项绝对值至多 $2G\|QE\phi\|_V^2$。对 $s_M(\lambda_M)-s_M(\lambda_*)$ 用实中值定理，得

$$
\lambda_M-\lambda_*=
\frac{(E\phi,\phi)_V-(H QE\phi,QE\phi)_V}
 {\,1/(1+\lambda_*)+O(\varepsilon_M/r)\,}.
\tag{20}
$$

分母与 $1/(1+\lambda_*)$ 之差的绝对值至多 $4\varepsilon_M/r$。因 $\|E\phi\|_V\le\varepsilon_M$，再对正平方根在 $\lambda_*$ 展开即得 (19) 第一行。所有 $O$ 常数对充分大的 $M$ 统一。

写 $v_{jm}=(A_{jm}^{\to},B_{jm}^{\leftarrow})^T$，则 $t_{jm}\phi=(I+p_{jm}S)v_{jm}$。在实频，式 (5) 精确给出

$$
\Delta_m t_{jm}\phi=2\kappa_m p_{jm}S v_{jm},\qquad
(t_{jm}\phi)^*\Delta_m t_{jm}\phi=
4\kappa_m p_{jm}\operatorname{Re}(\overline{A_{jm}^{\to}}B_{jm}^{\leftarrow})
+2\kappa_m p_{jm}^2\|v_{jm}\|^2.
\tag{21}
$$

因为 $\|(I+p_{jm}S)^{-1}\|\le(1-e^{-q_{M_0}^*w_{\min}})^{-1}$，(7) 保证 $\sum_{j,|m|>M_0}h_m\|v_{jm}\|^2$ 有限，故上述求和绝对收敛。由 (6)、(7)、(21) 和 $\kappa_m\le h_m$ 得

$$
\|E\phi\|_V^2
\le 4C_{\rm tr}^2\sum_{j,|m|>M}
       \frac{\kappa_m^2}{h_m}p_{jm}^2\|v_{jm}\|^2
\le 4C_{\rm tr}^2 R_M.
\tag{22}
$$

将 (21)、(22) 代入 (20)，用分母下界，再除以 $k_M+k_*$ 即得 (19)。证毕。

在实际切线上记 (17) 的两个振幅为 $a_{jm}^{c},b_{jm}^{c}$，则 $p_{jm}\overline{A_{jm}^{\to}} B_{jm}^{\leftarrow}=\overline{a_{jm}^{c}}b_{jm}^{c}$。这解释了两侧振幅较小时的“乘积”规律。一阶指相对于 (5) 的算子改动。固定 $M$ 并把 (6) 乘实参数 $\theta$。在 $(\theta,\lambda)=(0,\lambda_*)$，(12) 的两个偏导数分别为 $(E\phi,\phi)_V,-1/(1+\lambda_*)$。标量隐函数定理给出 $\left.dk(\theta)/d\theta\right|_{\theta=0}=(1+\lambda_*)(E\phi,\phi)_V/(2k_*)$。

Hermitian 对称本身不迫使这个导数为零。取 $x=(1,1)^T/\sqrt2$ 和简单自伴铅笔 $I-xx^*-(\lambda-\lambda_*)I$。加上 (5) 形状的 Hermitian 矩阵 $2\kappa(pS-p^2I)/(1-p^2)$、$0<p<1$、固定 $\kappa>0$。$x$ 仍是特征向量，对应根位移恰为 $2\kappa p/(1+p)$。这个有限维例子检验“仅由自伴性必有二次误差”的推论。对实际导模，若 (18) 的有符号乘积消失，(19) 给出两次传递量级的上界。一般情况下，$\|E\|$ 的大小既不规定误差符号，也不规定其渐近等价式。

更具体地，令 $p_M=e^{-q_M^*w_{\min}}$。式 (14) 给出 $\varepsilon_M=O(p_M)$，且 (18) 的可和性给出 $R_M=O(p_M^2)$。所以 (19) 的前两行还给出精确的判别

$$
 k_M-k_*=O(p_M^2)\quad\Longleftrightarrow\quad L_M=O(p_M^2).
 \tag{22a}
$$

这一步用到了 $L_M$ 在根位移展开中的系数 $2(1+\lambda_*)/k_*$ 非零。

**由本模型的 $H^2$ 正则性可再得到代数因子（已证明）。** 对固定 $\phi$，

$$
 |k_M-k_*|=
 o\!\left(\frac{e^{-q_M^*w_{\min}}}{1+b_M^2}\right).
\tag{23}
$$

事实上 T1.1 给出 $\phi\in H^2_\beta(B)$。将 (7) 分别用于 $\phi,\partial_y\phi$，相加得到

$$
\sum_{j,m} h_m^3\|t_{jm}\phi\|^2
 \le C_{\rm tr}^2(1+\|\partial_y\phi\|_V^2)
 \le C_{\rm tr}^2(1+\rho_{\max}\lambda_*).
$$

最后一步用圆柱上的 Fourier 恒等式 $\|D^2\phi\|_{L^2}=\|\Delta\phi\|_{L^2}$，其两侧范数平方对频率 $(\xi,\beta_m)$ 的乘子同为 $(\xi^2+\beta_m^2)^2$。由 $\Delta\phi=-\lambda_*\rho\phi$、$a[\phi,\phi]=\lambda_*b[\phi,\phi]$，有 $\|\partial_y\phi\|_V^2\le\rho_{\max}(\lambda_*^2+\lambda_*)b[\phi,\phi]=\rho_{\max}\lambda_*$。又有 $v_{jm}=(I+p_{jm}S)^{-1}t_{jm}\phi$，故 $\sum_{j,|m|>M_0}h_m^3\|v_{jm}\|^2<\infty$。因此
$\sum_{j,|m|>M}\kappa_m\|v_{jm}\|^2=o((1+b_M^2)^{-1})$。对 (18) 的乘积用 $2|AB|\le |A|^2+|B|^2$，代入 (19) 得证。这里的小 $o$ 针对一个固定的精确导模，(3) 仍是算子范数的一次传递上界。

也可得到适于选阶的有限 $M$ 版本。由 $\|(I+p_{jm}S)^{-1}\|\le(1-p_M)^{-1}$ 及上式，

$$
 \sum_{j,|m|>M}\kappa_m\|v_{jm}\|^2
 \le \frac{C_{\rm tr}^2(1+\rho_{\max}\lambda_*)}{(1-p_M)^2(1+b_M^2)}.
$$

在 (19) 末行分别用 $p_M/2$ 与 $p_M^2$ 乘此上界控制 $|L_M|$ 与 $R_M$。只要 (9) 成立，即有

$$
 |k_M-k_*|\le
 \frac{2(1+\lambda_*)C_{\rm tr}^2(1+\rho_{\max}\lambda_*)}
 {(k_*+\sqrt{\lambda_*-r})(1-p_M)^2(1+b_M^2)}
 \left[2p_M+(2+8G C_{\rm tr}^2)p_M^2\right].
 \tag{23a}
$$

可先用 (9) 保证根唯一，再比较 (10)、(23a) 的右端与所需容差。(23a) 的输入仍只有几何、材料与谱隔离数据。

### 4.3 锐指数（条件命题已证明，三个算例的精确值开放）

若 $L_M$ 最终非零且 $R_M=o(|L_M|)$，由 (20)–(22) 可得

$$
k_M-k_*=\frac{2(1+\lambda_*)}{k_*}\,
                L_M(1+o(1)).
\tag{24}
$$

所以只要 $-\log |L_M|/q_M^*$ 有极限，该极限就是根误差的指数宽度。在符号或相位抵消时，应保留 (19) 的第二项以及补空间响应。只测一个方向的系数模长不能给出 (24) 的下界。

下列条件说明场的延拓怎样进入上界。若存在 $s_j^\to,s_j^\leftarrow\ge0$ 使

$$
\sum_{j,|m|>M_0}h_m\bigl(
 e^{2\kappa_m s_j^\to}|A_{jm}^{\to}|^2+
 e^{2\kappa_m s_j^\leftarrow}|B_{jm}^{\leftarrow}|^2\bigr)<\infty ,
\tag{25}
$$

则 $|k_M-k_*|=O(e^{-q_M^* W})$，其中

$$
 W=\min\!\left\{\inf_j(w_j+s_j^\to+s_j^\leftarrow),\
                  \inf_j(2w_j+2s_j^\to),\
                  \inf_j(2w_j+2s_j^\leftarrow)\right\}.
\tag{26}
$$

证明。在乘积项中提取 $e^{-\kappa_m(w_j+s_j^\to+s_j^\leftarrow)}$，剩余两个加权因子由 (25) 及 Cauchy–Schwarz 控制。在平方项中分别提取 $e^{-2\kappa_m(w_j+s_j^\to)}$ 和 $e^{-2\kappa_m(w_j+s_j^\leftarrow)}$。再用 (19)。证毕。按 (17)，沿 $x$ 反向延拓一个单向场 $s$ 距离，恰把各系数乘 $e^{\kappa_m s}$。(25) 正是这类延拓迹的加权平方可和条件，需对所有接口和两条无穷引线统一成立。即使 (25) 只对每个 $s<s_0$ 成立，也只能逐个取这样的 $s$，端点 $s_0$ 的常数还须另证。

**关于奇性的猜想。** 最近的延拓奇性可能限制 (25) 中的两侧余量。W3 的实际散射场若能从每侧圆边向圆心平面延拓任意小于半径 $0.2$ 的距离并满足上述求和条件，则最近行间的 $w_j=h-0.4$ 在 (26) 中给出任意接近 $h$ 的宽度，从而对根误差指数给出相应下限。等于 $h$ 的锐率还需要首阶乘积的非抵消及渐近下界。圆形边界与出射性本身不能定位全部延拓奇性。例如 $G^{(k)}(\mathbf x-\mathbf z)$ 对一个位于圆内的偏心点 $\mathbf z$ 是圆外出射解，奇点就在 $\mathbf z$。这一例子只检验由圆形边界推断奇点位置的几何步骤。实际介质圆的散射还取决于其他行产生的入射场和传输条件。W3 的 $\phi$ 是否具有所说的延拓与非抵消性质仍是开放问题。

### 4.4 传播阶下限（已证明）

对目标频率，包含全部传播阶的最小对称半宽是

$$
 M_{\rm prop}(k)=\max\big(\{0\}\cup
       \{|m|:\ |\beta+2\pi m/d|<k\sqrt{\rho_{\mathrm e}}\}\big).
\tag{27}
$$

整个窗口取其最大值，并单独排除 Wood 阈值。若遗漏传播阶，它的传播因子模为一。[[research/projects/bie-enclosure/theory/port-subspace|port-subspace]] 式 (8) 给出保留端口的右减左通量等于

$$-\sum_{\text{遗漏传播阶 }m}\gamma_m
       (|a_{\mathrm R,m}|^2+|b_{\mathrm L,m}|^2).$$

因此对一般入射保证无损截断、并让每个遗漏阶享有本文 (8) 的指数小量时，必须保留所有传播阶。若某传播阶因精确对称性对所论不变子空间完全解耦，可以另行证明其出射恒零。单靠观察到 $K$ 个衰减乘子不能作此判断，该文件还证明纯出射泄能时某些计数仍保持 $K$。本研究三组参考频率处均只有 $m=0$ 传播，故这里 (27) 给出 $M_{\rm prop}=0$。达到给定频率精度所需的 $M$ 还由 (15) 控制。

## 5. 实测比较与符号到代码的对应

**已有实验记录。** `test/bie-bound/rayleigh-order-v1/README.md` 及 `results/fits.csv`、`results/late-fits.csv` 使用同一密度节点数 $N$ 的 $M=24$ 作为参考。下表为对 $\log|\widehat k_{M,N}-\widehat k_{24,N}|$ 按 $M$ 拟合的有效宽度，三例均取 $d=1$。几何列为实验的条带宽度，W3 还可由半径与行距直接计算。

| 算例 | $w_{\min}$ | 高于数值底限的 $M$ | 拟合宽度 | 去掉 $M=1$ 后 | 每增加一阶的拟合误差比 |
|---|---:|---|---:|---:|---:|
| 算例 1，128/64/64 | 0.468476 | 1–4 | 0.737625 | 0.628557 | 0.009710 |
| 算例 2，128/64/64 | 0.428867 | 1–5 | 0.698279 | 0.597879 | 0.012433 |
| W3，圆杆交错排布 | 0.466025 | 1–4 | 0.928140 | 0.916116 | 0.002933 |

三例几何上界中指数因子的渐近逐阶比 $e^{-2\pi w_{\min}/d}$ 依次约为 $0.05268,0.06757,0.05350$。算例 1 的 192/96/96 组拟合宽度为 $0.737528$。原网格从 $M=1$ 到 $4$ 的实际误差比依次约为 $1/613,1/29.9,1/90.2$。算例 2 要把空中心与两侧空白连成一个条带，中心条带宽约 $1.517103$，最窄处在右引线。W3 最短条带在相邻两排之间，$w_{\min}=\sqrt3/2-0.4$。其拟合值接近 $2w_{\min}=0.9320508\ldots$，也高于圆心行距 $h=0.866025\ldots$。这四个阶数不能判定 (24) 中的极限，也不能区分首项的额外衰减与两次传递项主导。

算例 1 将中心右切线从 $x=0.46$ 移到 $0.66$，中心一侧净距从 $0.10$ 增到 $0.30$。原切线及三个移动位置的根差均在 $1.56\times10^{-15}$ 内。对各位置 $M=24$ 场的 $m=3,\ldots,8$，将两个符号的振幅合为 Euclidean 模后拟合。右端口的两族宽度在原切线为 $0.232217,0.481704$，和为 $0.713921$。四个位置的和为 $0.713646$、$0.713921$、$0.714337$、$0.715036$。各族宽度随切线朝相反方向移动，符合 (16)–(18)。每个参考场按中心入射向量的范数独立归一化，固定场上的共同倍数只改变对数拟合的截距。

与 (24) 比较还缺两项信息。其一，记录的 `coeff_abs` 只保留中心左右端口各振幅的模，$(\pm m)$ 的合并包络不含 $\operatorname{Re}(\bar a_m^c b_m^c)$ 的符号和相位。其二，(18) 遍及所有引线端口，W3 还包括内部排间接合。数据中的 $0.714$ 与 $0.738$ 接近，支持检验双侧乘积机制，尚未验证 (24) 的主导条件。全部参考值使用有限 BIE 密度、代理计算和浮点求根。记录中的零误差表示返回的两个浮点数相同。几何边界的 65,536 点采样和这些斜率均未用于证明 (10)。

**符号与代码。** 下表中的 `study.m`、`search_i9_physics.m`、`summarize.py` 和 `results/` 均在 `test/bie-bound/rayleigh-order-v1/`。

| 数学对象 | 代码位置或字段 | 对应关系 |
|---|---|---|
| $M,K,\beta_m,\gamma_m,\mathsf E(\ell)$ | `study.m/LOCAL_config`、`probe_config.m`、`+bloch/rayleigh_channels.m` | `M`、`K=2*M+1`、`beta_m`、`gamma_m`、`phase` 决定同一组保留 Fourier 阶与纵向相位 |
| 精确单胞入射与总出射 | `+bloch/incident_rhs.m`、`+bloch/farfield_extractors.m`、`+bloch/construct_S.m` | 数值代码以 `R_L, T_RL, T_LR, R_R` 逼近精确散射块，直接透射相位进入两个透射块 |
| 每个需要截断的间隔 $G_j$ | `study.m/LOCAL_geometry`、`search_i9_physics.m/LOCAL_pair, LOCAL_join, LOCAL_side` | 列出中心及引线条带，W3 的一周期由两个单排散射块通过有限阶端口接合 |
| 切线与锚点 | `probe_config.m` 的 `cut_positive, X_L, X_R` 及 `find_cut.m` | 移动空白区切线，重设相关胞元端口。实际的 $\mathsf D_s$ 随之变化 |
| 精确模型根 $k_M$ | 草稿 `eq:nep`，`search_i9_physics.m/LOCAL_qzsub, LOCAL_matching`，`study.m/LOCAL_root` | 实验用 QZ（广义 Schur 分解）求衰减空间，再以 DtN 行列式作局部求根。使用该除法形式还需要中心及 Dirichlet 消元有效 |
| $(a^c_{jm},b^c_{jm})$ 与 (18) | `study.m/LOCAL_root` 的 `zL, zR, coeff_abs` | 总幅包含入射和散射。现存 `coeff_abs` 对两个中心端口取模，不能从中恢复全域有符号乘积 |
| 有效宽度 | `summarize.py/fit`、`results/fits.csv`、`late-fits.csv`、`cut-tail-fits.csv` | `width=-slope/(2*pi)` 使用 $d=1$。根误差以各自的 $\widehat k_{24,N}$ 为参考，固定阶系数拟合使用 $M=24$ 的场 |
| $\Delta_m,\mathcal E_M,g,G$ | 本文 (3)、(5)–(15) | 这是对精确截断模型的型表示和证明输入。当前实验没有组装该全局型或给出到其余谱的可靠下界 |

## 6. 未决项

| 分类 | 问题 | 当前结论与所需数据 |
|---|---|---|
| blocker，仅针对算例的可靠数值选阶 | 将容差直接换成已验证的整数 $M$ | (15) 已证明。代入需要目标位置、与其余谱的隔离量及几何净距下界。给定实验记录尚缺完整的定量输入 |
| important caveat | 三例的锐宽度及 W3 圆心假说 | (19)、(24)–(26) 给出可检验的条件。需建立两侧全阶场的延拓、全部端口的尾、相位非抵消或次项主导。圆心间距和有限阶拟合各自不能确定极限 |
| important caveat | 从精确 $k_M$ 转到实际求解器的 $\widehat k_{M,N}$ | 还需控制密度离散、代理核、数值子空间和求根误差。局部 DtN 极点影响搜索表示，切线不变性适用于模型的匹配根 |
| minor caveat | 所选 $M$ 的保守程度 | (7) 对各端面统一取范数，(15) 允许最坏情况。若有已验证的全阶模态尾，可改用 (19) 减小常数 |

**完成报告。** 模式为 Proof from scratch。目标为草稿 `eq:pencil`、`eq:nep` 所定义的精确 Rayleigh 端口截断。命题 1、定理 2、(19) 及四项回答均在本文件给出，三个算例的锐指数保留为开放问题。文献核对状态为 Proof literature verification completed。复用的项目内结果为 `reliable-bound.md` 定理 T1.1 及其圆柱 Fourier 能量恒等式，以及 `port-subspace.md` 假设 2、引理 A、式 (8) 和定理 B。实验比较来自上述已有记录，本次未运行新实验，也无待批准的外部文献。
