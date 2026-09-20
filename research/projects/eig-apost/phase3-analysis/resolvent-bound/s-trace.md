# 正移位预解式的全界面迹估计

本文证明用户式 (4) 的一个可评价基线。算子及界面记账见
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework]]。
所有范数未注明权重时均使用欧氏面积或弧长测度。材料满足
$0<\rho_-\le\rho\le\rho_+<\infty$，$\beta$ 为固定实数，
$I=[\mu_-,\mu_+]\subset(0,\infty)$。本结果不要求该窗口是谱隙。

## 1. 明确的几何输入

将上下边按准周期相位识别，几何上得到圆柱
$\mathbb R\times(\mathbb R/d\mathbb Z)$；场是带该相位的函数。
这只是描述同一条带的局部坐标，并未更换物理算子。

**假设 G（统一 collar）。** 实际材料和人工拼接界面组成局部有限的可数集合
$\mathscr E$，每条物理界面只计一次。材料界面是简单闭合 $C^2$ 曲线；
人工竖直界面在圆柱上是闭合直线。若需控制 raw 准周期缺陷，还允许加入一条完整的
嵌入水平直线作为接缝，弧长参数在 $\mathbb R$ 上，取其 collar 宽度 $h<d/2$。
每条界面有弧长参数
$\boldsymbol r_\Gamma(s)$、单位法向 $\nu_\Gamma(s)$，存在共同的
$h>0$、$\kappa_*\ge0$ 和整数 $N_{\mathrm{ov}}\ge1$，使

$$
F_\Gamma(s,t)=\boldsymbol r_\Gamma(s)+t\nu_\Gamma(s),
\qquad -h<t<h,
\qquad |\kappa_\Gamma(s)|\le\kappa_*,
$$

在圆柱上单射，且

$$
\theta:=1-h\kappa_*>0,
\qquad
\sum_{\Gamma\in\mathscr E}\mathbf1_{U_\Gamma}(x,y)
\le N_{\mathrm{ov}}\quad\text{几乎处处},
\qquad U_\Gamma=F_\Gamma(\Gamma\times(-h,h)).
\tag{G1}
$$

曲线上的同一点按参数周期识别；单射性不要求首尾参数不同。
法向坐标的 Jacobian 是 $1-t\kappa_\Gamma$，故至少为 $\theta$。
collar 可以穿过另一材料界面：被估计的测试场是全局 $H^2$ 场，不是独立的局部
transmission 解。重叠由 $N_{\mathrm{ov}}$ 控制。对最简单的分离几何，取互不相交
collar，即可令 $N_{\mathrm{ov}}=1$。

此假设是本专题新增的充分条件，不能由“$\Omega_0$ 单连通”推出；不要求圆形、凸性
或星形。$C^{1,1}$ 可进一步放宽，但本轮使用 $C^2$ 基线，不为此增加证明分支。

## 2. 算子定义域确实给出全局二阶控制

**引理 T1（准周期全局正则性）。** 对 draft 的定义域有

$$
D(A(\beta))=
\{v\in H^2(B):v_+=e^{\mathrm i\beta d}v_-,\quad
v_{y,+}=e^{\mathrm i\beta d}v_{y,-}\}.
\tag{T1}
$$

这里下标 $+$、$-$ 只在本式表示上、下边的迹。原定义域中的导数匹配先按
$H^{-1/2}$ 广义法向迹理解，不预设其为 $L^2$ 迹；升阶后才取得通常的导数迹。并且

$$
\|D^2v\|_{L^2(B)}^2
:=\|v_{xx}\|_2^2+2\|v_{xy}\|_2^2+\|v_{yy}\|_2^2
=\|\Delta v\|_2^2.
\tag{T2}
$$

**证明。** 从 draft 的 $H^1(\Delta,B)$ 定义出发，把 $v$ 以相位
$e^{\mathrm i\beta d}$ 延拓。值的匹配排除接缝处的一阶分布源；弱法向导数的匹配
排除 Laplacian 的接缝面源。这也可用逐条带 Green 公式与紧支撑测试函数直接验证。
故圆柱上分布 Laplacian 仍是给定的 $L^2$ 函数。

使用 $y$ 方向的正交基
$\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_my}$，
$\beta_m=\beta+2\pi m/d$，以及 $x$ 方向的单位 Fourier 变换。
分布恒等式给出

$$
\widehat{\Delta v}_m(\xi)
=-(\xi^2+\beta_m^2)\widehat v_m(\xi).
$$

Parseval 表明
$\sum_m\int(\xi^2+\beta_m^2)^2|\widehat v_m|^2\,\mathrm d\xi<\infty$。
各二阶乘子 $\xi^2,\xi\beta_m,\beta_m^2$ 均受其控制，因而 $v\in H^2(B)$。
展开 $(\xi^2+\beta_m^2)^2$ 就得到 (T2)。反方向直接成立。
该论证既没有跨材料界面对 $\rho$ 求导，也没有在有角胞元上调用 $H^2$ 正则性定理。
材料处 $\Delta v\in L^2$ 是全局分布条件，已经排除了跳跃源。证毕。

**引理 T2（正移位控制）。** 令 $f=(A(\beta)+\mu I)v$，则

$$
\|v\|_{\mathcal H}\le\mu^{-1}\|f\|_{\mathcal H},\qquad
\|Av\|_{\mathcal H}\le\|f\|_{\mathcal H},\qquad
\|\nabla v\|_2^2\le\frac{1}{4\mu}\|f\|_{\mathcal H}^2,
\tag{T3}
$$

$$
\|v\|_2^2\le\frac{\|f\|_{\mathcal H}^2}{\rho_-\mu^2},
\qquad
\|D^2v\|_2^2\le\rho_+\|f\|_{\mathcal H}^2.
\tag{T4}
$$

**证明。** 全条带积分分部或 Fourier 截断给出
$(Av,v)_{\mathcal H}=\|\nabla v\|_2^2\ge0$。因此

$$
\|f\|_{\mathcal H}^2
=\|Av\|_{\mathcal H}^2+2\mu\|\nabla v\|_2^2
+\mu^2\|v\|_{\mathcal H}^2.
$$

前两个范数界直接得到；再用

$$
\|Av-\mu v\|_{\mathcal H}^2\ge0
\quad\Longrightarrow\quad
\|f\|_{\mathcal H}^2\ge4\mu\|\nabla v\|_2^2
$$

得到梯度界。最后 $\Delta v=-\rho Av$，从而
$\|\Delta v\|_2^2\le\rho_+\|Av\|_{\mathcal H}^2$；结合 (T2) 和
加权、非加权质量范数的比较即得 (T4)。没有使用负移位预解式或谱距离。证毕。

## 3. 展开的局部迹不等式

**引理 T3（双侧一维迹）。** 对 $g\in H^1(-h,h)$，

$$
|g(0)|^2\le\frac1h\int_{-h}^h|g(t)|^2\,\mathrm dt
+\frac h2\int_{-h}^h|g'(t)|^2\,\mathrm dt.
\tag{T5}
$$

**证明。** $t>0$ 时，微积分基本定理与 Cauchy--Schwarz 给出
$|g(0)|^2\le2|g(t)|^2+2t\int_0^t|g'(r)|^2\,\mathrm dr$。
在 $(0,h)$ 平均，导数项的系数为 $(h^2-r^2)/h\le h$，得到
$|g(0)|^2\le(2/h)\int_0^h|g|^2+h\int_0^h|g'|^2$。
对 $(-h,0)$ 同样操作，再将两条不等式相加除以二，即为 (T5)。证毕。

对 $w\in H^1(U_\Gamma)$ 沿法线用 (T5)、再换元，得到

$$
\|w|_\Gamma\|_{L^2(\Gamma)}^2
\le\frac1{\theta h}\|w\|_{L^2(U_\Gamma)}^2
+\frac h{2\theta}\|\nabla w\|_{L^2(U_\Gamma)}^2.
\tag{T6}
$$

先对光滑函数使用基本定理，再用 $H^1$ 稠密逼近即可定义并延拓迹。
准周期接缝附近在相位坐标内使用同一论证；$|e^{\mathrm i\beta d}|=1$，不增加常数。
取 $w=v$ 得到值迹；分别取 $w=v_x,v_y$ 并求和，利用
$|\partial_{\nu_\Gamma}v|\le|\nabla v|$ 得到普通法向导数迹。
这里没有对 $\nu_\Gamma$ 作切向微分，因此没有额外的曲率导数常数。

## 4. 主定理及式 (4)

定义两个有几何意义的系数

$$
c_0=\frac{N_{\mathrm{ov}}}{\theta h},\qquad
c_1=\frac{N_{\mathrm{ov}}h}{2\theta}.
\tag{T7}
$$

**定理 T4（全界面正移位迹估计）。** 在上述材料、定义域和假设 G 下，对任意
$\mu\in I$、$v\in D(A(\beta))$，用户式 (4) 在固定无量纲坐标中成立，可取

$$
\boxed{
C_{\mathrm{tr}}^2
=\frac{c_0}{\rho_-\mu_-^2}
+\frac{c_0+c_1}{4\mu_-}
+c_1\rho_+ .}
\tag{T8}
$$

即

$$
\left[\sum_{\Gamma\in\mathscr E}
\left(\|v|_\Gamma\|_2^2+
\|\partial_{\nu_\Gamma}v|_\Gamma\|_2^2\right)\right]^{1/2}
\le C_{\mathrm{tr}}\|(A(\beta)+\mu I)v\|_{\mathcal H}.
\tag{4}
$$

若保留物理长度单位，应同时采用下述配对加权版本。固定一个明确的长度
$\ell_*>0$（例如 $d$），令

$$
T_{\ell_*}(v)^2
=\sum_{\Gamma\in\mathscr E}
\left(\|v|_\Gamma\|_2^2+
\ell_*^2\|\partial_{\nu_\Gamma}v|_\Gamma\|_2^2\right),
$$

$$
\boxed{
C_{\mathrm{tr},\ell_*}^2
=\frac{c_0}{\rho_-\mu_-^2}
+\frac{c_1+\ell_*^2c_0}{4\mu_-}
+\ell_*^2c_1\rho_+,
\qquad
T_{\ell_*}(v)\le C_{\mathrm{tr},\ell_*}\|(A+\mu I)v\|_{\mathcal H}.}
\tag{T9}
$$

与之配对的缺陷必须是

$$
\varepsilon_{\partial,\ell_*}^2
=\sum_{\Gamma\in\mathscr E}
\left(\|j_\Gamma\|_2^2+
\ell_*^{-2}\|a_\Gamma\|_2^2\right).
\tag{T10}
$$

**证明。** 对任意有限子集求和 (T6)，利用重叠重数后，右边分别不超过

$$
\sum_\Gamma\|v|_\Gamma\|_2^2
\le c_0\|v\|_2^2+c_1\|\nabla v\|_2^2,
$$

$$
\sum_\Gamma\|\partial_{\nu_\Gamma}v|_\Gamma\|_2^2
\le c_0\|\nabla v\|_2^2+c_1\|D^2v\|_2^2.
\tag{T11}
$$

由非负项的单调收敛，这两式对全可数集合成立。代入 (T3)--(T4)，再以
$\mu\ge\mu_-$ 放大常数，就得到 (T8)--(T9)。所有求和中只使用重叠重数，
从未使用胞元总数。证毕。

取无量纲 $\ell_*=1$ 时 (T10) 就是用户的 $\varepsilon_\partial$。
若 $\rho$ 无量纲，$[\mu]=\mathrm{length}^{-2}$，则
$[c_0]=\mathrm{length}^{-1}$、$[c_1]=\mathrm{length}$，(T9) 的每一项均具有
$\mathrm{length}^3$ 的单位。于是 $C_{\mathrm{tr},\ell_*}
\varepsilon_{\partial,\ell_*}$ 与 $\|u_{h,M}\|_{\mathcal H}$ 同单位。
尺度变换 $x'=x/s$ 同时改变 $h,d,\ell_*$ 和 $\mu$；不能只改变一侧权重。

## 5. 从有限几何参数得到 G1

本节给出充分的有限证书，不把未知 reach 当作未展开的答案。

**引理 T5（单曲线 collar 单射证书）。** 对弧长周期为 $p_\Gamma$ 的简单闭合
$C^2$ 曲线，给出曲率上界 $K_\Gamma$，选
$0<b_\Gamma<p_\Gamma/2$，并证明：当两点的短弧长距离至少为 $b_\Gamma$ 时，
弦距至少为 $s_\Gamma>0$。若

$$
K_\Gamma(b_\Gamma/2+h)<1,
\qquad 2h<s_\Gamma,
\tag{T12}
$$

则其平面法向 collar 单射。

**证明。** 若 $F(s,t)=F(s',t')$，记短弧长距离为 $q$。当 $q\ge b_\Gamma$ 时，
弦距至少 $s_\Gamma>2h$，但两法向偏移之差至多为 $2h$，矛盾。
当 $0<q<b_\Gamma$ 时，沿短弧的起点切向量投影，由
$|\tau(s+r)-\tau(s)|\le K_\Gamma r$ 得到

$$
\left|(\boldsymbol r(s')-\boldsymbol r(s))\cdot\tau(s)\right|
\ge q(1-K_\Gamma q/2).
$$

而 $\nu(s)\cdot\tau(s)=0$、
$|\nu(s')-\nu(s)|\le K_\Gamma q$，碰撞等式迫使
$1-K_\Gamma q/2\le hK_\Gamma$，与 (T12) 矛盾。
$q=0$ 时同一法线参数的单射性显然。证毕。

这些输入可由给定参数曲线的有限区间包围产生：速度下界保证正则；速度及二阶导数
界给出曲率上界；利用弧长或其单侧积分界隔开参数对角带，在剩余紧参数对上有限划分，
以包围盒间距离给出 $s_\Gamma$。严格正间距允许逐步细分终止；单纯采样最小值不算
该证书。对具体曲线必须给出可评价的参数函数及导数包围，不能仅输入“任意 $C^2$”。

再给出不同材料曲线及其周期镜像之间、材料与人工竖线之间的距离下界
$s_{\mathrm{sep}}>0$。竖线间距至少是 $\min\{L,2a\}$，其中 $2a$ 为中心宽度，
$L$ 为背景胞元周期。选择共同的 $h$ 同时满足 (T12)、

$$
2h<s_{\mathrm{sep}},\qquad
2h<\min\{L,2a\},\qquad h\kappa_*<1.
\tag{T13}
$$

材料界面只需有限种中心、左、右模板；将曲线坐标包围盒扩张 $2h$，只检查与这些盒
可能相交的有限个 $L$、$d$ 平移。其余镜像由坐标距离直接排除。圆柱上的自碰撞也要
检查非零 $d$ 平移，不能只检查曲线在平面上的自身。这给出互不相交 collar，
$N_{\mathrm{ov}}=1$。对 inclusion 跨越上下接缝的情形，要用同一条圆柱曲线或相容图
作这一检查；把被切开的两段重复当作两条材料界面是不正确的。

允许重叠时，可用更宽的 collar：对各模板的扩张包围盒建立有限相交表，在一个周期窗
和中心过渡窗中计数，未确定是否相交的盒一律计入。若每个 collar 最多与 $D$ 个其他
collar 相交，则在任意点 $N_{\mathrm{ov}}\le D+1$。远平移仍由包围盒距离排除。
可选的水平准周期接缝 collar 覆盖全部 $x$，自身重数为一，加入时将旧重数加一即可；
取其宽度 $h<d/2$ 防止自身绕圆柱重复。

因此 (T8) 显式依赖于 $\rho_\pm,\mu_-,h,\kappa_*,N_{\mathrm{ov}}$；
$L,d,2a$、材料间距和人工界面间距通过 (T12)--(T13) 与重数进入。
没有 $\mu_+$ 或 $|\beta|$ 的额外损失：实准周期相位不改变 Parseval 与局部绝对值。
若只使用单个 $\mu$，可在 (T8)--(T9) 中直接用该 $\mu$ 得到更小常数。

## 6. 原始假设不足之处及保守性

“单连通”本身连可积弧长都不保证。例如取一个紧含于胞元的 Koch 雪花内部作为
单个 inclusion，周期复制；其边界长度无限。取 $\beta=0$ 且在该胞元邻域恒为一、
在 $x$ 方向紧支撑的光滑场 $v$。则 $v\in D(A(0))$、右侧有限，但按弧长测度的
值迹积分无限。这是对未附加边界正则性的 (4) 的直接反例；法向迹也未必可定义。
本例仅说明缺少假设，绝不把当前光滑实现改为分形模型。

无限族还必须有一致的局部密度：若在有限宽条带中人工插入无限多条累积竖线，
同一个非零光滑场的值迹平方和即可发散。本专题的周期有限模板与 (G1) 排除了该情况。

常数的主要损失可逐项定位：共同最窄 $h$、曲率因子 $\theta^{-1}$、重数上界、
$\rho_-/\rho_+$ 的全局比较，以及分别最大化三个体范数而不是联合优化。
细颈或界面相互靠近使可用 $h$ 变小；$\mu_-\downarrow0$ 时质量项放大。
这些是已证明基线的局限，并不意味着具体 candidate 错误。
后续可以分材料/直墙分别使用不同 collar 参数再汇总，或在正标量 $h$ 的显式可行区间
内优化 (T9)，均不需要求全波导预解式。本轮不追求高频 sharpness。
