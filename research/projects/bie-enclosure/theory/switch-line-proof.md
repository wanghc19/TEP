# 回卷切换线的残差界及端点合并

进度：
- done：定理 SW 的条件、弱 Green 恒等式、线迹与点值估计、引线尾和谱距离推论。
- done：Part B 的端点集体估计、较小的点常数、有限 Fourier 尾和已有 CSV 的重算。
- next：交由独立线程审查；实验线程按末节计算带符号的复 Fourier 矩。
- open：所需解析证明已写全；实际输入的可靠求积与传播收缩证书尚缺，现有 CSV 不保存复端点系数。

SW 指 switch-line（切换线）。BIE 指 boundary integral equation（边界积分方程），MFS 指 method of fundamental solutions（基本解方法）。本文采用 **Proof from scratch** 模式，只研究固定的连续源积分场。主张的状态分别列在定理、推论和命题处；已有浮点结果不作为证明前提。

## Part A：定理 SW

### 1. 对象、条件与结论

**状态：在以下列出条件下已证明。** 本定理扩展 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]] 的 T2.3：以逐源的弱 Green 恒等式代替对积分场本身的逐片 Helmholtz 与 $H^2$ 假设。分支通量的含义采用 [[research/projects/bie-enclosure/theory/switch-line-kress-review|switch-line-kress-review]] 的 S-1，符号采用 S-2，接缝的零测例外采用 S-3。

**算子。** 设 $d>0$、$\beta\in\mathbb R$、$\mu>0$，
$$
B=\mathbb R\times(-d/2,d/2),\qquad
0<\rho_{\min}\le\rho(x,y)\le\rho_{\max}<\infty.
$$
$\rho$ 为实值、$y$ 向 $d$ 周期，在各材料分片内为常数。令
$$
\mathcal H=L^2(B,\rho),\qquad
(u,v)_{\mathcal H}=\int_B\rho u\overline v\,\mathrm{d}x\,\mathrm{d}y.
$$
由型 $\int_B\nabla u\cdot\overline{\nabla v}$、型域 $H^1_\beta(B)$ 定义自伴非负算子
$$
A:D(A)=H^2_\beta(B)\longrightarrow\mathcal H,
\qquad Az=-\rho^{-1}\Delta z.
$$
$H^k_\beta(B)$ 表示准周期 Sobolev 空间；$H^2_\beta(B)$ 的值与 $y$ 导数在上下边界相差 $q=\exp(\mathrm{i}\beta d)$。这一算子及其域采用 T2.3 所用的 T1.1。记
$$
\beta_m=\beta+\frac{2\pi m}{d},\qquad
\lambda_0=\frac{\min_{m\in\mathbb Z}|\beta_m|^2}{\rho_{\max}}.
$$
T4.3 中的 Fourier--Poincaré 估计给出 $A\ge\lambda_0$。

**几何与核。** 胞元是有界的竖向矩形；胞元墙局部有限。每胞元内只有有限条正则、嵌入的解析闭材料曲线，彼此及与胞元墙、上下接缝有正距离。每个均匀分片 $P$ 中的波数为 $\kappa_P=\sqrt{\mu\rho_P}$。在该片使用的每条源曲线 $\Gamma_P$ 上，源高度 $s_y$ 不是常数。允许 $\Gamma_P$ 是有限条曲线的不交并。

对物理坐标 $t=(x,y)$、$s=(s_x,s_y)$，令
$$
X=y-s_y,\quad Y=x-s_x,\quad
m=\operatorname{round}(X/d),\quad X_0=X-md,
$$
$$
\widetilde G_{\kappa_P}(t,s)=q^mK_{\kappa_P}(X_0,Y),\qquad
K_\kappa(X,Y)=G_\kappa(X,Y)+\sum_r c_rG_\kappa((X,Y)-Z_r),
$$
其中 $G_\kappa(r)=\mathrm{i}H_0^{(1)}(\kappa|r|)/4$。所有 $c_r,Z_r$ 固定；代理点与闭盒 $[-d/2,d/2]\times[-H,H]$ 有正距离。要求实际使用的源、目标对满足 $|Y|<H$，因此不启用代码的平面波切换分支。若启用该分支，必须另外计入 $Y=\pm H$ 的缺陷，本文的公式不涵盖漏计的竖向切换。

这正是 `+kernel/qpgreen_mfs_pairmat.m` 的内盒分支：物理 $y$ 是计算第一坐标，物理 $x$ 是计算第二坐标；第 87--89 行逐对回卷，第 116--121 行返回选定分支的导数。代理系数是差坐标核的固定系数，不对源位置再求系数的导数。

**固定场和通量。** 在每个 $P$ 上定义
$$
\widehat u_P(t)=\int_{\Gamma_P}
\left(\tau_P(s)\partial^{\mathrm{br}}_{\nu_s}\widetilde G_{\kappa_P}(t,s)
-\sigma_P(s)\widetilde G_{\kappa_P}(t,s)\right)\,\mathrm{d}s+u_{\mathrm{fs},P}(t)+u_{b,P}(t).
\tag{SW1}
$$
密度是固定的有限三角多项式；$\mathrm{d}s$ 是源弧长。$u_{b,P}$ 是直到闭片附近光滑的精确 Helmholtz 解。可选项 $u_{\mathrm{fs},P}$ 是同一波数的普通连续自由空间单、双层势之和（fs 指 free space），其源曲线与密度满足上述光滑性条件；它没有回卷切换项。没有回卷层势的柱内片可取 (SW1) 的积分项为零。所有平面波均使用精确色散关系。源奇性只允许位于相应材料边界，片内没有点源奇性。

上标 $\mathrm{br}$ 表示在选定光滑分支上求导。设 $\nu_s=(n_x,n_y)$，则
$$
\partial^{\mathrm{br}}_{\nu_s}\widetilde G
=-n_x\partial_x^{\mathrm{br}}\widetilde G-n_y\partial_y^{\mathrm{br}}\widetilde G.
\tag{SW2}
$$
边界通量 $\Phi_{P,\nu}$ **定义为** (SW1) 的被积函数在分支上作目标法向导数后再对源积分，加上 $u_{\mathrm{fs},P}$ 的普通单侧法向迹与 $\partial_\nu u_{b,P}$。普通奇异自由空间层势保留通常的单侧值、法向迹。$\Phi_{P,\nu}$ 不是对整个积分场的弱导数所作的另一个记号。

**引线。** 中心只有有限个胞元。左右引线分别由参考胞元平移得到，可以有不同的周期、材料和传播矩阵。对引线 $\varsigma\in\{-,+\}$，参考密度及光滑项线性依赖有限维状态 $v\in\mathbb C^{K_\varsigma}$，第 $j\ge0$ 胞元的状态为
$$
v_{\varsigma,j}=\mathsf P_\varsigma^jc_\varsigma.
$$
要求存在整数 $p_\varsigma\ge1$ 和 $0\le r_\varsigma<1$，使
$$
\|\mathsf P_\varsigma^{p_\varsigma}\|_2\le r_\varsigma.
\tag{SW3}
$$
这是对固定传播矩阵的条件，不要求它等于连续精确传播算子。

**物理边界残差。** 在材料边界或胞元墙上，选法向 $\nu$ 从片 $P^-$ 指向片 $P^+$，置
$$
J^{\mathrm{br}}_0=\widehat u_{P^+}-\widehat u_{P^-},\qquad
J^{\mathrm{br}}_1=\Phi_{P^-,\nu}-\Phi_{P^+,\nu}.
$$
接缝以顶边为代表，置
$$
J^{\mathrm{br}}_{\Sigma,0}=q\widehat u(x,-d/2)-\widehat u(x,d/2),\qquad
J^{\mathrm{br}}_{\Sigma,1}=\Phi_{e_y}(x,d/2)-q\Phi_{e_y}(x,-d/2).
\tag{SW4}
$$
每面共享墙计一次，每对上下边界配成一条接缝。将这些界面分为有限种组 $g$，组内允许无穷多个引线平移副本。假设按 T4.2--T4.3 验证了该组的领子单射性、曲率界和实际覆盖重数，得到对所有 $z\in D(A)$ 的迹界
$$
\sum_{\Gamma\in g}
\left(\|z\|_\Gamma^2+\ell_g^2\|\partial_{\nu_\Gamma}z\|_\Gamma^2\right)
\le C_g^2\|(A+\mu)z\|_{\mathcal H}^2.
$$
定义
$$
\varepsilon_{g,\mathrm{br}}^2=
\sum_{\Gamma\in g}\int_\Gamma
\left(|J^{\mathrm{br}}_1|^2+\ell_g^{-2}|J^{\mathrm{br}}_0|^2\right),
\qquad Q_{\mathrm{grp}}^{\mathrm{br}}=\sum_gC_g\varepsilon_{g,\mathrm{br}}.
\tag{SW5}
$$
下文的传播估计保证这些无穷和收敛；数值使用时仍须给各积分与常数可靠上界。

**切换段。** 对几乎每个源 $s$，令 $h(s)\in(-d/2,d/2)$ 为唯一满足
$h(s)-s_y\equiv d/2\pmod d$ 的高度。以增加 $x$ 的方向定向 $P$ 内每条非退化连通段
$$
\Lambda_s^P=\bigcup_{[a,b]}\{(x,h(s)):a<x<b\}.
$$
交点或切点的例外源集合为弧长零测集。所有跳跃均取切换线上侧减下侧，定义
$$
g_0=[\widetilde G],\qquad g_x=[\partial_x^{\mathrm{br}}\widetilde G],\qquad
g_y=[\partial_y^{\mathrm{br}}\widetilde G],
$$
$$
\mathcal J_0=-\tau(n_xg_x+n_yg_y)-\sigma g_0,
\qquad
\mathcal J_1=[\partial_y^{\mathrm{br}}(\tau\partial^{\mathrm{br}}_{\nu_s}\widetilde G-\sigma\widetilde G)].
\tag{SW6}
$$
在各段上置
$$
A_0=\tau n_y\kappa_P^2g_0-\sigma g_y,\quad
A_1=\tau(n_xg_y-n_yg_x),\quad
E=\tau(n_yg_x-n_xg_y)=-A_1.
\tag{SW7}
$$
密度、法向和源在段内的 $x$ 微分中保持不变。为减少引线线项的三角不等式损失，可把同一参考分片的所有引线胞元并为一组 $P$：$s$ 此时取参考源，逐胞元使用相应状态和纵向平移，$\Lambda_s^P$ 是这些互不重叠的共线段的并。以下 $\sum_P$ 按选定的这些组求和。也可逐胞元使用公式，但会得到较大的线项。

固定 $\ell>0$，定义
$$
(e'_s)^2=\sum_{[a,b]\subset\Lambda_s^P}\int_a^b
\left(|A_0|^2+\ell^{-2}|A_1|^2+\ell^{-2}|\mathcal J_0|^2\right)\,\mathrm{d}x,
\tag{SW8}
$$
$$
M_{\mathrm{end}}=
\sum_P\int_{\Gamma_P}\sum_{[a,b]\subset\Lambda_s^P}
\left(|E(a;s)|+|E(b;s)|\right)\,\mathrm{d}s.
\tag{SW9}
$$
每段的两个端点均计入，包括内引线墙上来自左右两个胞元的端点，以及切换线与材料界面的交点。

**常数。** 取 $0<2\delta<d$、$\eta>0$，令
$$
D_0=\frac{1+\eta}{2\delta},\qquad
D_1=(1+\eta^{-1})\frac\delta6,
$$
$$
p(\lambda)=\frac{D_0}{\rho_{\min}}
+(D_1+\ell^2D_0)\lambda+\ell^2D_1\rho_{\max}\lambda^2,
\qquad
C_{\mathrm{line}}^2=\sup_{\lambda\ge\lambda_0}
\frac{p(\lambda)}{(\lambda+\mu)^2}.
\tag{SW10}
$$
对任一 $\alpha>0$ 置
$$
S(\alpha)=\frac1d\sum_{m\in\mathbb Z}
\frac1{4(\alpha+\beta_m^2)^{3/2}},\qquad
C_{\mathrm{pt}}(\alpha)=\sqrt{S(\alpha)}
\left(\frac{\alpha}{\sqrt{\rho_{\min}}(\lambda_0+\mu)}+\sqrt{\rho_{\max}}\right).
\tag{SW11}
$$
可取任一这样的 $C_{\mathrm{pt}}$，也可取 $\inf_{\alpha>0}C_{\mathrm{pt}}(\alpha)$。这里写 $\inf$，不预设一般参数下最小值在 $\alpha>0$ 内达到。有限参数的可靠上界足够用于定理。

**结论。** 场 (SW1) 属于 $\mathcal H$。定义反线性残差泛函
$$
R:D(A)\longrightarrow\mathbb C,\qquad
R(z)=(\widehat u,(A-\mu)z)_{\mathcal H}.
$$
则对所有 $z\in D(A)$，
$$
|R(z)|\le Q\|(A+\mu)z\|_{\mathcal H},\qquad
Q=Q_{\mathrm{grp}}^{\mathrm{br}}
+C_{\mathrm{line}}\sum_P\int_{\Gamma_P}e'_s\,\mathrm{d}s
+C_{\mathrm{pt}}M_{\mathrm{end}}.
\tag{SW12}
$$
这里的和可取完整引线。若只计算有限个胞元，则用第 6 步的可靠尾上界替代余项；同一尾项不重复添加。

### 2. 证明：先确定跳跃和 Green 恒等式

**证明。** 以下直到第 7 步为定理 SW 的完整证明。

**第 1 步：固定源的符号。** 设跨过某条切换线时回卷整数从 $m$ 变为 $m+1$。下侧趋于 $X_0=d/2$，上侧趋于 $X_0=-d/2$，因而
$$
g_0=q^{m+1}\left(K_\kappa(-d/2,Y)-q^{-1}K_\kappa(d/2,Y)\right),
$$
$$
g_y=q^{m+1}\left(\partial_XK_\kappa(-d/2,Y)-q^{-1}\partial_XK_\kappa(d/2,Y)\right),
\qquad g_x=\partial_xg_0.
\tag{SW13}
$$
相位 $q^{m+1}$ 的模为一，但在合并不同源前必须保留它。分支上 $m$ 局部不变，源导数满足 (SW2)，故 (SW6) 中的 $\mathcal J_0$ 正确。两分支都满足同一个 Helmholtz 方程，因此
$$
[\partial_x\partial_y\widetilde G]=\partial_xg_y,
\qquad
[\partial_y^2\widetilde G]=-\partial_xg_x-\kappa_P^2g_0.
$$
代入双层与单层的 $y$ 导数，逐项得
$$
\mathcal J_1=-\tau n_x\partial_xg_y
+\tau n_y\partial_xg_x+\tau n_y\kappa_P^2g_0-\sigma g_y
=A_0+\partial_xE.
\tag{SW14}
$$

**第 2 步：逐源 Green 公式及 Fubini。** 先取 $x$ 向紧支撑、光滑、准周期的 $z$。对每个源先分离普通自由空间核 $G_{\kappa_P}(t-s)$ 及其源法向导数。其连续层势使用 T2.2 的单侧 $H^2$ 结论及普通 Green 公式。这里满足 T2.2 所需的解析正则源曲线、光滑密度与邻近源分离条件；只对这个普通层势使用该结论。

剩余核 $\widetilde G-G$ 在真实源对角线附近等于光滑代理修正：该邻域内 $m=0$，自由空间奇性恰好消掉。在对角线以外，物理周期像与代理点均有正距离。切换线离自身源的周期高度距离为 $d/2$。因此在任一紧的源、目标集合上，剩余核及本证明用到的一、二阶分支导数一致有界。对普通奇异层势的边界极限不交换有奇性的逐点微分与源积分。

源曲线和目标曲线的高度函数解析且不恒定，各自只有有限个临界值。排除其有限个高度原像以及 $s_y=0$ 后，固定源的各切换线横截材料边界，得到有限个光滑边和角点的分片。对剩余核的每个光滑分支应用第二 Green 公式。它的体项、边项对 $s$ 都绝对可积：源长度有限，密度有界，相关核导数一致有界，而当前 $z$ 光滑且纵向紧支撑。故 Fubini 允许把这些 Green 公式对源积分。

在一条水平切换线上，下片外法向是 $+e_y$，上片外法向是 $-e_y$。两侧相加的 Green 边项为
$$
(\partial_yF_{\mathrm{lower}}-\partial_yF_{\mathrm{upper}})\overline z
+(F_{\mathrm{upper}}-F_{\mathrm{lower}})\overline{z_y}
=-\mathcal J_1\overline z+\mathcal J_0\overline{z_y},
$$
其中 $F=\tau\partial^{\mathrm{br}}_{\nu_s}\widetilde G-\sigma\widetilde G$。
普通分片 Green 公式只给边积分；此时尚未作沿边分部积分，角点不产生点项。相加材料片、胞元，并按 (SW4) 配对上下边，得到
$$
R(z)=R^{\mathrm{br}}_\partial(z)-\sum_PR_{\mathrm{sw},P}(z),
\tag{SW15}
$$
$$
R^{\mathrm{br}}_\partial(z)=
\sum_{\Gamma\in\mathscr E_{\mathrm{mat}}\cup\mathscr E_{\mathrm{art}}\cup\mathscr E_\Sigma}
\int_\Gamma\left(J^{\mathrm{br}}_1\overline z+
J^{\mathrm{br}}_0\overline{\partial_{\nu_\Gamma}z}\right),
$$
$$
R_{\mathrm{sw},P}(z)=\int_{\Gamma_P}\sum_{[a,b]\subset\Lambda_s^P}
\int_a^b(\mathcal J_1\overline z-\mathcal J_0\overline{z_y})\,\mathrm{d}x\,\mathrm{d}s.
\tag{SW16}
$$
这一步证明的是 $L^2$ 场的弱恒等式。连续叠加移动切换线可能产生尖点；没有使用积分场自身逐片 $H^2$ 或分片 Helmholtz 的断言。对边界值，去掉零测的切换源后可对光滑剩余核用控制收敛；其单侧值等于上述源积分。边界通量则始终按 (SW1)--(SW2) 的分支定义。

**第 3 步：接缝上的 tie。** 若 $s_y\ne0$，源的切换线不在上下接缝，且 $m(X+d)=m(X)+1$；因此回卷层势的上、下边界值和分支导数精确相差 $q$。若 $s_y=0$，MATLAB 在 $X=\pm d/2$ 分别取 $m=\pm1$，逐点差为
$$
\widetilde G(X=d/2,Y)-q\widetilde G(X=-d/2,Y)
=qK(-d/2,Y)-K(d/2,Y),
\tag{SW17}
$$
其一阶导数也可不匹配。单源的相对单侧接缝迹同样未必匹配。

正则解析闭源曲线不可能整条为水平线，所以 $\{s:s_y=0\}$ 为弧长零测集。光滑剩余核在接缝邻域有一致界，由控制收敛，连续源积分中这一例外不贡献接缝残差。故**回卷层势部分**的 (SW4) 为零。其余自由空间层势或附加光滑项若不精确准周期，相应接缝残差仍保留在 $Q_{\mathrm{grp}}^{\mathrm{br}}$。有限源求积可能恰好在 tie 放置节点；其接缝诊断不能仅据 (SW17) 归为舍入误差。

### 3. 证明：Claim 1，同一个多项式控制全梯度线迹

**Claim 1，状态：已证明。** 对固定源的全部共线段 $\Lambda=\Lambda_s^P$，
$$
\|z\|_\Lambda^2+\ell^2\|\nabla z\|_\Lambda^2
\le C_{\mathrm{line}}^2\|(A+\mu)z\|_{\mathcal H}^2.
\tag{SW18}
$$

**第 4 步。** 每段的法向领子是 $(a,b)\times(h-\delta,h+\delta)$。固定源时，各段的 $x$ 内部互不相交，故覆盖重数为一。$2\delta<d$ 保证经过准周期识别后也没有额外覆盖。领子可以穿过材料界面，因为测试场 $z$ 全局属于 $H^2_\beta(B)$。

T4.2 的条件在这里逐项为：法向映射单射；曲率为零；$\delta\kappa_*=0<1$；覆盖重数 $N=1$。所以它的 $\tau=\delta/6$，给出 (SW10) 的 $D_0,D_1$。先对光滑 $z$ 用其标量一维证明，再分别用于 $\partial_xz$、$\partial_yz$，得到
$$
\|z\|_\Lambda^2\le D_0\|z\|_2^2+D_1\|\nabla z\|_2^2,
$$
$$
\|\nabla z\|_\Lambda^2
\le D_0\|\nabla z\|_2^2
+D_1\bigl(\|z_{xy}\|_2^2+\|z_{yy}\|_2^2\bigr)
\le D_0\|\nabla z\|_2^2+D_1\|D^2z\|_F^2.
\tag{SW19}
$$
这里只对两个分量求和：$|z_{xy}|^2+|z_{yy}|^2\le|D^2z|_F^2$，没有额外的因子二。标量迹证明只使用一阶体导数，所以通过光滑逼近可用于 $H^1$ 的两个梯度分量；不要求它们各自属于 $H^2$。

按 T4.3 的证明，
$$
\|z\|_2^2\le\rho_{\min}^{-1}\|z\|_{\mathcal H}^2,
\quad \|\nabla z\|_2^2=(Az,z)_{\mathcal H},
\quad \|D^2z\|_F^2=\|\Delta z\|_2^2\le\rho_{\max}\|Az\|_{\mathcal H}^2.
$$
Hessian 恒等式也可直接由混合 Fourier 变换逐频率的
$\xi^4+2\xi^2\beta_m^2+\beta_m^4=(\xi^2+\beta_m^2)^2$ 看出。
把 (SW19) 与值迹相加，恰得到 T4.3 的同一个 $p$。其自伴性、正移位 $\mu>0$、谱下界 $\lambda_0$ 和体范数条件均已满足，故 T4.3 给出 (SW18)。无穷多个共线段由有限并的估计及单调收敛得到。Claim 1 得证。

### 4. 证明：Claim 2，统一点值常数

**Claim 2，状态：已证明。** 每个 $z\in H^2_\beta(B)$ 有连续代表，且任意点 $t\in\overline B$ 均满足
$$
|z(t)|\le C_{\mathrm{pt}}(\alpha)\|(A+\mu)z\|_{\mathcal H}.
\tag{SW20}
$$

采用幺正的混合 Fourier 约定
$$
z(x,y)=\frac1{\sqrt{2\pi d}}\sum_{m\in\mathbb Z}
\int_{\mathbb R}\widehat z_m(\xi)
e^{\mathrm{i}\xi x+\mathrm{i}\beta_my}\,\mathrm{d}\xi,
\qquad
\|z\|_2^2=\sum_m\int_{\mathbb R}|\widehat z_m(\xi)|^2\,\mathrm{d}\xi.
\tag{SW21}
$$
加权 Cauchy--Schwarz 及
$$
\frac1{2\pi}\int_{\mathbb R}(c+\xi^2)^{-2}\,\mathrm{d}\xi
=\frac1{4c^{3/2}}\quad(c>0)
$$
给出
$$
|z(t)|^2\le S(\alpha)\|(\alpha-\Delta)z\|_2^2.
\tag{SW22}
$$
级数 $S(\alpha)$ 收敛，因为其项在 $|m|\to\infty$ 时为 $O(|m|^{-3})$。同一 Cauchy--Schwarz 估计使 (SW21) 绝对收敛；截去 Fourier 尾的误差一致趋零，因而定义连续代表。此点值适用于墙、接缝和材料交点。

由 $-\Delta z=\rho Az$、质量系数界和 $A\ge\lambda_0$，
$$
\|(\alpha-\Delta)z\|_2
\le\frac\alpha{\sqrt{\rho_{\min}}}\|z\|_{\mathcal H}
+\sqrt{\rho_{\max}}\|Az\|_{\mathcal H}
\le\left(\frac{\alpha}{\sqrt{\rho_{\min}}(\lambda_0+\mu)}
+\sqrt{\rho_{\max}}\right)\|(A+\mu)z\|_{\mathcal H}.
$$
这里分别使用谱乘子 $(\lambda+\mu)^{-1}$ 和 $\lambda/(\lambda+\mu)$ 的界。结合 (SW22) 得 Claim 2。

### 5. 证明：沿线分部积分、对偶权重和所有端点

**第 5 步。** 对固定源及一条段，$g_0,g_x,g_y$ 在其闭段附近光滑。由 Claim 1 对 $z$ 和 $z_x$ 的迹估计，光滑逼近的线迹在 $H^1(a,b)$ 中收敛；其弱切向导数就是 $z_x$ 的迹。Claim 2 又使逼近的点值一致收敛。因此可以把光滑函数的沿线分部积分传到 $z\in H^2_\beta(B)$，端点值正是其连续代表的值。由 (SW14)，
$$
\int_a^b(\mathcal J_1\overline z-\mathcal J_0\overline{z_y})\,\mathrm{d}x
=\int_a^b(A_0\overline z+A_1\overline{z_x}-\mathcal J_0\overline{z_y})\,\mathrm{d}x
+[E\overline z]_a^b.
\tag{SW23}
$$
端点符号明确为 $E(b;s)\overline{z(b,h(s))}-E(a;s)\overline{z(a,h(s))}$。它仍属于在 (SW15) 中被减去的 $R_{\mathrm{sw}}$。

线项中的对偶向量是
$$
(A_0,\ell^{-1}A_1,-\ell^{-1}\mathcal J_0)
\quad\hbox{与}\quad(z,\ell z_x,\ell z_y).
$$
因此 (SW8) 的权重恰是 $1,\ell^{-2},\ell^{-2}$，与 SP-1 修补后的 S′ 一致。对全部共线段作一次 Cauchy--Schwarz，再用 Claim 1，得线项绝对值至多
$C_{\mathrm{line}}e'_s\|(A+\mu)z\|_{\mathcal H}$。
Claim 2 给每个端点 $C_{\mathrm{pt}}|E|\|(A+\mu)z\|_{\mathcal H}$。对源积分及分片组求三角不等式，即得到 (SW12) 的两个切换项。

在相邻两段的共同端点，带号系数是 $E_{\mathrm{left}}-E_{\mathrm{right}}$。只有证明这两个系数相等才可消去。原始墙跳跃在 (SW5) 中归属一个胞元，并不允许把 (SW23) 的另一端删掉。材料交点也用同一规则。端点依赖源不会产生 $a'(s)$ 或 $b'(s)$：这里只在固定源下对 $x$ 分部积分，之后对 $s$ 积分，从未对源参数微分。

### 6. 证明：引线的平方尾与端点绝对值尾

**第 6 步。** 以下暂省略引线符号 $\varsigma$；左右各用各自的 $\mathsf P,p,r,c$。

对于 (SW5) 的任一边界组，令 $\mathsf L:\mathbb C^K\to Y$ 将参考状态映到该组的加权边界跳跃。$Y$ 是相应曲线 $L^2$ 直和空间；远端墙比较状态 $v$ 与下一胞元的 $\mathsf Pv$。每面墙归更靠近中心的胞元，每对上下边配一次。该映射线性且有界：普通层势的迹由 T2.2 给出，剩余分支通量有前述一致界，定义域有限维。由此逐项满足 T3.8 的线性映射、Hilbert 空间、固定传播及收缩幂条件，取
$$
\Theta=\sum_{a=1}^K\|\mathsf Le_a\|_Y^2
$$
即可直接引用其 (PT2)：
$$
\sum_{j=N}^\infty\|\mathsf L\mathsf P^jc\|_Y^2
\le\frac{\Theta}{1-r^2}
\left(\sum_{h=0}^{p-1}\|\mathsf P^h\|_2^2\right)\|\mathsf P^Nc\|_2^2.
\tag{SW24}
$$
尾上界加在相应 $\varepsilon_{g,\mathrm{br}}^2$ 内，之后开方并乘 $C_g$。

对于切换线，对每个参考源 $s$ 定义线性映射
$$
\mathsf L_{\mathrm{line}}(s):\mathbb C^K\longrightarrow
L^2(\Lambda_s^{\mathrm{ref}};\mathbb C^3),\qquad
v\longmapsto(A_0,\ell^{-1}A_1,-\ell^{-1}\mathcal J_0),
$$
并置 $\Theta_{\mathrm{line}}(s)=\sum_a\|\mathsf L_{\mathrm{line}}(s)e_a\|_2^2$。它的几何、核和密度映射固定，故有界。T3.8 再给
$$
(e'_s)^2\le\sum_{j=0}^{N-1}\|\mathsf L_{\mathrm{line}}(s)\mathsf P^jc\|_2^2
+\frac{\Theta_{\mathrm{line}}(s)}{1-r^2}
\left(\sum_{h=0}^{p-1}\|\mathsf P^h\|_2^2\right)\|\mathsf P^Nc\|_2^2.
\tag{SW25}
$$
必须先把该尾加进固定源的平方和，再开方对 $s$ 积分。若希望写成单独相加的 $Q$ 尾，可再用 $\sqrt{a+b}\le\sqrt a+\sqrt b$，得到
$$
Q_{\mathrm{line,tail}}\le
\frac{C_{\mathrm{line}}\|\mathsf P^Nc\|_2}{\sqrt{1-r^2}}
\left(\sum_{h=0}^{p-1}\|\mathsf P^h\|_2^2\right)^{1/2}
\int_{\Gamma_P}\sqrt{\Theta_{\mathrm{line}}(s)}\,\mathrm{d}s.
\tag{SW26}
$$

端点则定义所有端的线性行映射
$E_\epsilon(s;v)=L_\epsilon(s)v$，包括一个胞元内所有连通段的左右端；令
$$
B_{\mathrm{end}}=\int_{\Gamma_P}\sum_\epsilon\|L_\epsilon(s)\|_2\,\mathrm{d}s<\infty.
$$
将 $j=N+ip+h$，$0\le h<p$ 代入 (SW3)，有
$$
\|\mathsf P^jc\|_2\le\|\mathsf P^h\|_2r^i\|\mathsf P^Nc\|_2.
$$
这一次不平方，直接求和得
$$
\sum_{j=N}^\infty\int_{\Gamma_P}\sum_\epsilon
|E_\epsilon(s;\mathsf P^jc)|\,\mathrm{d}s
\le\frac{B_{\mathrm{end}}}{1-r}
\left(\sum_{h=0}^{p-1}\|\mathsf P^h\|_2\right)\|\mathsf P^Nc\|_2.
\tag{SW27}
$$
端点残差尾是 (SW27) 乘 $C_{\mathrm{pt}}$。分母为 $1-r$；T3.8 的 $1-r^2$ 不能代替它。

这些积分有限的原因也明确：参考源曲线紧，密度映射连续，各切换跳跃及端点系数有统一界，段数有统一有限上界。平方和与绝对值和均因此收敛。

### 7. 证明：全局延拓及引用条件核对

**第 7 步。** 普通自由空间层势在参考胞元上属于 $L^2$，源积分的光滑剩余项也属于 $L^2$。参考胞元场映射 $\mathcal U:\mathbb C^K\to L^2(\mathcal C,\rho)$ 线性有界。(SW3) 与 T3.8 相同的分块几何级数给出
$$
\sum_{j\ge0}\|\mathcal U\mathsf P^jc\|_{\mathcal H(\mathcal C)}^2<\infty.
$$
故 $\widehat u\in\mathcal H$。这没有要求回卷源积分场的梯度属于 $L^2$。

边界项由 (SW5) 和 Cauchy--Schwarz 有界；切换项由 Claims 1--2 以及 (SW25)、(SW27) 有界，且无穷源、胞元求和绝对收敛。它们都是 $D(A)$ 上关于 $\|(A+\mu)z\|_{\mathcal H}$ 的连续反线性泛函。左端 $R$ 同样连续，因为
$\|(A-\mu)z\|_{\mathcal H}\le\|(A+\mu)z\|_{\mathcal H}$。

取只依赖 $x$ 的光滑截断，再对周期规范 $e^{-\mathrm{i}\beta y}z$ 作平滑逼近，可把任意 $H^2_\beta(B)$ 函数在 $H^2$ 范数下逼近为纵向紧支撑的光滑准周期函数。$\rho$ 的上下界使 $H^2$ 范数与 $A+\mu$ 图范数等价，这也是 T2.3 所用的算子域性质。因此 (SW15) 从第 2 步的测试函数延拓到全部 $D(A)$；由以上各项界得到 (SW12)。$\square$

为避免把已审结论用到错误对象，引用的适用范围汇总如下。

| 已检查的结果 | 本文使用的假设及逐项对应 | 所得结论 |
|---|---|---|
| T2.1--T2.2 | 连续光滑密度、解析材料曲线、精确局部波数；真实自作用源允许位于材料边界，其余像和代理与相应光滑分支的闭目标域分离 | 自由空间部分的单侧迹及 $L^2$；光滑剩余项允许 Fubini。没有把 T2.2 直接用于移动切换线叠加后的场，也没有采用物理坐标下未经回卷的代理表示。 |
| T2.3 | 正实质量系数、固定准周期自伴算子、$\mu>0$、$\widehat u\in\mathcal H$、接缝按 (SW4) 配对、完整残差的图范数界 | 接缝的方向与相位；下面的预解式谱距离推论。原逐片 Helmholtz、$H^2$ 假设所负责的 Green 公式已由第 2--7 步替换，故并非声称原 T2.3 可不加修改地直接套用。 |
| T4.2 | 单射平直领子、曲率零、$2\delta<d$、固定源下覆盖重数一；边界组另验证自身几何 | (SW19) 的标量及梯度迹估计。 |
| T4.3 | 上述迹估计、质量上下界、非负自伴 $A$ 与谱底 $\lambda_0$、正移位 $\mu$ | 同一个多项式 $p$ 和 (SW10)；无维数附加因子。 |
| T3.8 | 参考状态到 Hilbert 残差空间的固定线性映射、每面墙归属一次、状态 $\mathsf P^jc$、收缩幂 (SW3) | (SW24)--(SW25)；不用于端点的绝对值和，后者由 (SW27) 单独证明。 |

**当前配置的几何条件核对（已证明）。** `test/bie-bound/switch-v1/pilot_config.m` 给出 $d=1$、$x\in[-0.5,0.5]$、$H=1.1$、星形缩放一，以及三瓣曲线参数 $a=0.12,0.20$、$R=0.2$。由 `+geom/construct_cont.m` 的星形公式和 `pilot_geometry.m` 的三瓣公式，分别有
$$
s_x=0.2(1.5+0.3\cos5\theta)\cos\theta,\qquad
s_y=0.2(1+0.3\cos5\theta)\sin\theta,
$$
$$
(s_x,s_y)=\frac{0.2(1+a\cos3\theta)}{\sqrt{1+a^2/2}}
(\cos\theta,\sin\theta).
$$
所以所有源均满足 $|s_x|\le0.36$、$|s_y|\le0.26$，严格位于胞元内。三瓣曲线是正半径的解析极坐标图。星形的角度导数分子满足
$$
s_xs_y'-s_ys_x'
=0.04\left((1.5+0.3\cos5\theta)(1+0.3\cos5\theta)
-0.75\sin5\theta\sin\theta\cos\theta\right)
\ge0.04(0.84-0.375)>0.
$$
其横、纵坐标的符号分别与 $\cos\theta,\sin\theta$ 相同，故极角严格增加一周，没有自交，速度不为零。由此核实了源曲线的解析性、正则性、嵌入性及高度不恒定。对同胞元的所有目标，
$|Y|=|x-s_x|\le0.5+0.36=0.86<1.1$；引线平移在差坐标中抵消。因此这里没有遗漏 $Y=\pm H$ 切换，此检查不依赖采样极值。这个粗界不排除切换段与材料曲线相交；定理已经保留了这些交点的全部端项。

### 8. 谱距离推论

**状态：在定理 SW 条件及 $0\le Q<U=\|\widehat u\|_{\mathcal H}$ 下已证明。** 有
$$
\operatorname{dist}(\mu,\sigma(A))\le\frac{2\mu Q}{U-Q}.
\tag{SW28}
$$

**证明。** 复用 T2.3 的预解式论证。其所需输入是 (SW15) 所确定的完整残差及 (SW12)，不是 $\widehat u\in D(A)$。若 $\mu\in\sigma(A)$，结论显然。否则 $z=(A-\mu)^{-1}\widehat u\in D(A)$，且 $R(z)=U^2$。记 $\operatorname{dist}(\mu,\sigma(A))=\delta_\mu>0$，T2.3 的谱乘子步骤给出
$$
U^2\le Q\|(A+\mu)z\|_{\mathcal H}
\le Q\left(1+\frac{2\mu}{\delta_\mu}\right)U.
$$
由 $U>Q$ 移项即得 (SW28)。$\square$

数值使用可将 $Q$ 换成可靠上界、$U$ 换成正的可靠下界，并检查分母为正。该结论控制候选到整个谱的距离；这里没有附加谱隔离、简单性或某个导模身份的结论。

## Part B：端点推前测度的集体估计

### 9. 命题 EP：先合并同一面墙上的端点

EP 指 endpoint pairing（端点配对）。这里使用 $H^{3/2}$ 墙迹与其对偶 $H^{-3/2}$，直接对测度定义 Fourier 范数。无需把推前测度先写成可能有奇性的密度。

**状态：在定理 SW 条件下已证明。** 选出所有位于竖墙 $x=x_w$ 的端点。将每个端按来源胞元、分片和左／右端分别编号为 $e$；其源参数域记作 $\Gamma_e$，允许只是一条源曲线的可测子集。其高度为 $h_e(s)$，带号系数定义为
$$
\gamma_e(s)=
\begin{cases}
 E(b;s),&e\text{ 是段的右端},\\
-E(a;s),&e\text{ 是段的左端}.
\end{cases}
$$
所有 $E$ 都含 (SW13) 的回卷相位。选定共同的半开高度区间 $[-d/2,d/2)$；若把高度改成 $h+kd$，同一配对的系数须改成 $q^k\gamma$。这样 $\gamma\overline{z(x_w,h)}$ 不变。

在每面墙上定义有限复测度 $\zeta_w$：对有界 Borel 函数 $\varphi$，
$$
\int\varphi(y)\,\mathrm{d}\zeta_w(y)
=\sum_{e\text{ 在墙 }w}\int_{\Gamma_e}
\gamma_e(s)\varphi(h_e(s))\,\mathrm{d}s.
\tag{EP1}
$$
其总变差至多
$$
V_w=\sum_{e\text{ 在墙 }w}\int_{\Gamma_e}|\gamma_e(s)|\,\mathrm{d}s.
$$
内引线墙的两侧在这里一起求和，故可能出现 $E_{\mathrm{left}}-E_{\mathrm{right}}$ 的真实抵消。不同源只要在同一墙上，也在取范数前相加。令未位于这些竖墙上的端点绝对值总量为 $M_{\mathrm{other}}$，于是
$$
M_{\mathrm{end}}=\sum_w V_w+M_{\mathrm{other}}.
$$
这允许保留材料交点等端点，不额外要求所有切换段贯穿整个胞元。

定义复 Fourier 矩及加权对偶范数
$$
\widehat\zeta_{w,m}=\frac1{\sqrt d}
\sum_{e\text{ 在墙 }w}\int_{\Gamma_e}
\gamma_e(s)e^{-\mathrm{i}\beta_mh_e(s)}\,\mathrm{d}s,
\tag{EP2}
$$
$$
\|\zeta_w\|_{-3/2,\alpha}^2
=\sum_{m\in\mathbb Z}
\frac{|\widehat\zeta_{w,m}|^2}{4(\alpha+\beta_m^2)^{3/2}}.
\tag{EP3}
$$
这是与下面的加权 $H^{3/2}_\beta$ 墙迹范数对偶的精确归一化；有限测度总有有限的 (EP3)。再定义
$$
C_{\mathrm{vol}}(\alpha)^2
=\sup_{\lambda\ge\lambda_0}
\frac{\alpha^2/\rho_{\min}+2\alpha\lambda+\rho_{\max}\lambda^2}
{(\lambda+\mu)^2}
=\max\left\{\rho_{\max},
\frac{\alpha^2/\rho_{\min}+2\alpha\lambda_0+\rho_{\max}\lambda_0^2}
{(\lambda_0+\mu)^2}\right\}.
\tag{EP4}
$$
则 (SW12) 的整个端点项可以替换为
$$
Q_{\mathrm{end}}^{\mathrm{coll}}(\alpha)
=C_{\mathrm{vol}}(\alpha)
\left(\sum_w\|\zeta_w\|_{-3/2,\alpha}
+\sqrt{S(\alpha)}M_{\mathrm{other}}\right).
\tag{EP5}
$$
其中 coll 指 collective（在同一墙上先合并）。允许任取 $\alpha>0$ 或再对 $\alpha$ 取下确界。对相同 $\alpha$，有
$$
Q_{\mathrm{end}}^{\mathrm{coll}}(\alpha)
\le C_{\mathrm{vol}}(\alpha)\sqrt{S(\alpha)}M_{\mathrm{end}}
\le C_{\mathrm{pt}}(\alpha)M_{\mathrm{end}}.
\tag{EP6}
$$
因此此路线在同一 $\alpha$ 下不劣于原逐源点估计。允许优化 $\alpha$ 时，该顺序仍成立。第一项可利用源间及墙两侧的相消，第二项已经改进了点常数。

### 10. 命题 EP 的完整证明

**证明。** 设墙迹的准周期 Fourier 系数为
$$
z_m(x_w)=\frac1{\sqrt d}\int_{-d/2}^{d/2}
z(x_w,y)e^{-\mathrm{i}\beta_my}\,\mathrm{d}y.
$$
对 (SW21) 的每个 $m$ 单独在 $\xi$ 上作加权 Cauchy--Schwarz，得
$$
|z_m(x_w)|^2\le\frac1{4(\alpha+\beta_m^2)^{3/2}}
\int_{\mathbb R}(\alpha+\xi^2+\beta_m^2)^2
|\widehat z_m(\xi)|^2\,\mathrm{d}\xi.
$$
所以
$$
\sum_m4(\alpha+\beta_m^2)^{3/2}|z_m(x_w)|^2
\le\|(\alpha-\Delta)z\|_2^2.
\tag{EP7}
$$
此处的常数为一，且与墙位置无关。因 $\alpha>0$，左边就是一个与通常 $H^{3/2}_\beta$ 范数等价、但归一化完全指定的范数。

$|\widehat\zeta_{w,m}|\le V_w/\sqrt d$ 与 $S(\alpha)<\infty$ 保证 (EP3) 收敛。特别地，$\|a\delta_h\|_{-3/2,\alpha}=|a|\sqrt{S(\alpha)}$，与 (SW22) 的归一化一致。由 (EP7) 的 Cauchy--Schwarz，墙迹的 Fourier 级数绝对一致收敛。因此可逐项对有限测度积分，得到
$$
\int\overline{z(x_w,y)}\,\mathrm{d}\zeta_w(y)
=\sum_m\widehat\zeta_{w,m}\overline{z_m(x_w)},
$$
$$
\left|\int\overline{z(x_w,y)}\,\mathrm{d}\zeta_w(y)\right|
\le\|\zeta_w\|_{-3/2,\alpha}\|(\alpha-\Delta)z\|_2.
\tag{EP8}
$$

现在保留体范数中的交叉项，而不用 (SW11) 推导中的三角不等式。$x$ 截断与准周期边界抵消给出
$$
\|(\alpha-\Delta)z\|_2^2
=\alpha^2\|z\|_2^2+2\alpha\|\nabla z\|_2^2+\|\Delta z\|_2^2
\le\frac{\alpha^2}{\rho_{\min}}\|z\|_{\mathcal H}^2
+2\alpha(Az,z)_{\mathcal H}+\rho_{\max}\|Az\|_{\mathcal H}^2.
$$
对这个多项式使用 T4.3 已检查的同一谱乘子方法，得到
$$
\|(\alpha-\Delta)z\|_2
\le C_{\mathrm{vol}}(\alpha)\|(A+\mu)z\|_{\mathcal H}.
\tag{EP9}
$$
它只使用算子的自伴性、质量上下界和谱底，与材料界面的光滑性无关。

为核实 (EP4) 中最后的显式最大值，对其有理函数微分；导数符号由
$$
\alpha\mu-\alpha^2/\rho_{\min}+(\rho_{\max}\mu-\alpha)\lambda
$$
决定。若 $\rho_{\max}\mu-\alpha\ge0$，该线性函数递增，唯一可能的内部驻点为极小值。若该系数小于零，则 $\alpha>\rho_{\max}\mu\ge\rho_{\min}\mu$，常数项也为负，函数在 $\lambda\ge0$ 上递减。故上确界只需检查 $\lambda_0$ 和 $\lambda\to\infty$，正是 (EP4)。

由 (EP8)--(EP9) 对墙求和，未合并的其他端点用 (SW22) 与 (EP9)，得到 (EP5)。无穷墙的求和由 $\sum_wV_w\le M_{\mathrm{end}}<\infty$ 保证。又因为
$$
\|\zeta_w\|_{-3/2,\alpha}\le\sqrt{S(\alpha)}V_w,
$$
以及对 $\lambda\ge0$ 有
$$
\alpha^2/\rho_{\min}+2\alpha\lambda+\rho_{\max}\lambda^2
\le(\alpha/\sqrt{\rho_{\min}}+\sqrt{\rho_{\max}}\lambda)^2,
$$
可得
$$
C_{\mathrm{vol}}(\alpha)
\le\frac{\alpha}{\sqrt{\rho_{\min}}(\lambda_0+\mu)}+\sqrt{\rho_{\max}}.
$$
这就证明 (EP6)。$\square$

**极值高度为什么不是障碍。** 这是命题已证明范围的说明。在 $h'_e\ne0$ 的源弧上，(EP1) 的密度可以写成各原像的 $\gamma_e(s)/|h'_e(s)|$ 之和；高度极值可能使该写法出现可积奇性。证明只用推前有限测度及其总变差，完全不要求上述密度属于 $L^2$，也不要求 $h'_e$ 有正下界。(EP2) 始终在源曲线上积分，不包含 $1/|h'_e|$。

### 11. 实验线程需要计算什么

以下有限公式及尾估计都是命题 EP 的已证明推论。

1. 在同一物理墙上收集所有相邻胞元、所有源曲线的**带号复系数** $\gamma_e(s)$，保留 (SW13) 的回卷相位、密度相位和左右端符号。先积分得到 (EP2)，再取绝对值；不能从逐源绝对值重建这些矩。
2. 计算 $|m|\le M$ 的 $\widehat\zeta_{w,m}$，同时给 $V_w$ 可靠上界。若近似矩为 $\widetilde\zeta_{w,m}$，有绝对误差上界 $\epsilon_{w,m}$，则
   $$
   \|\zeta_w\|_{-3/2,\alpha}^2
   \le\sum_{|m|\le M}
   \frac{(|\widetilde\zeta_{w,m}|+\epsilon_{w,m})^2}{4(\alpha+\beta_m^2)^{3/2}}
   +V_w^2 S_{>M}(\alpha),
   \tag{EP10}
   $$
   $$
   S_{>M}(\alpha)=\frac1{4d}\sum_{|m|>M}(\alpha+\beta_m^2)^{-3/2}.
   $$
   设 Fourier 间隔 $\omega=2\pi/d$ 且 $\omega M>|\beta|$。两侧正项递减，积分比较给出可直接使用的尾界
   $$
   S_{>M}(\alpha)\le\frac1{4d\omega}\sum_{\pm}
   \frac1{\sqrt{\alpha+(\omega M\pm\beta)^2}
   \left(\sqrt{\alpha+(\omega M\pm\beta)^2}+\omega M\pm\beta\right)}.
   \tag{EP11}
   $$
   这是对 $\int_M^\infty(\alpha+(\omega x\pm\beta)^2)^{-3/2}\,\mathrm{d}x$ 的显式计算；把 $M$ 换成 $M+1$ 给同一正项尾的下积分估计。
3. 只合并已计算胞元的端点时，在截断墙保留已计算胞元的那个端；被省略胞元的所有端由 (SW27) 控制。用较小的 $C_{\mathrm{vol}}(\alpha)\sqrt{S(\alpha)}$ 乘 (SW27)，即可补端点尾。线项仍按 (SW25)；原 $Q_{\mathrm{grp}}^{\mathrm{br}}$ 仍按 (SW24)。

可靠源求积须在回卷分支变化或端点归属变化处作分段，或另给跨越这些点的误差界。以上公式不把一份有限源求积当成连续源场的精确积分。

### 12. run-002 能支持的幅度估计

**本节是已有数据的普通算术重算，不是实际算例的可靠上界。** 仅只读使用
`test/bie-bound/switch-v1/output/run-002/prime-n3072-{center,negative,positive}-sources.csv`
及同目录 `prime.json`；没有运行新的场计算。CSV 的表头为
`t,weight,e_prime,endpoint_amplitude_sum,line_tail_square,endpoint_tail_amplitude`。

三个文件各有 3072 行。从 `weight * endpoint_amplitude_sum` 求和得到
$$
M_{\mathrm{end}}^{\mathrm{CSV}}=5.08596205024601\times10^{-11}.
$$
该列已经把左右端与引线胞元的绝对值相加，**不保存复相位、逐墙分配或带号的端点系数**。例如同一点的系数 $(a,-a)$ 与 $(a,a)$ 给出相同的绝对值和，却分别给出零与 $2a$ 的合并系数。因此从这些 CSV 不能推断 (EP2) 的相消大小。

不过不使用相消，(EP6) 的中间项已经能给出改进的幅度估计。取
$$
d=1,\quad\beta=0.5,\quad\rho_{\min}=1,\quad\rho_{\max}=17,
\quad\mu=(1.5584378941820909)^2,\quad\alpha=10.
$$
此时
$$
17(\lambda+\mu)^2-(100+20\lambda+17\lambda^2)
=(34\mu-20)\lambda+17\mu^2-100>0\quad(\lambda\ge0).
$$
两个系数的正性以所列十进制波数作为精确有理数做了代数检查。因此 (EP4) 给出精确表达式 $C_{\mathrm{vol}}(10)=\sqrt{17}$。以 $|m|\le10000$ 的和及 (EP11) 计算，普通算术值为
$$
S(10)\approx0.00947084043189,\qquad
\sqrt{17S(10)}\approx0.4012533954.
$$
原 `prime.json` 的点常数为 $0.7834823943490669$。所以只改用这个联合乘子、保留 CSV 中所有绝对值，就得到下列估计：

| 项 | 原 S′ | 使用 $\sqrt{17S(10)}$，尚未利用源相消 |
|---|---:|---:|
| 端点项 | $3.9847617247\times10^{-11}$ | $2.0407595417\times10^{-11}$ |
| 线项 | $2.2271410616\times10^{-11}$ | 相同 |
| 切换项合计 | $6.2119027863\times10^{-11}$ | $4.2679006033\times10^{-11}$ |

端点估计约为原值的 $0.51214$。再加所报 $Q_{\mathrm{grp}}^{\mathrm{br}}\approx4.09\times10^{-12}$，总量约 $4.68\times10^{-11}$；与单盘允许量 $6.35\times10^{-11}$ 比较，普通预算约有 $1.36$ 倍余量。这里只改变估计公式，所定义的场及密度均保持不变。

短检查使用 `conda run -n octave python` 的标准库，在 `tmp/` 为工作目录执行，耗时不足一秒，没有写输出文件。计算内容是 CSV 加权求和、一个正项 Fourier 级数及两项有理数符号检查；没有运行实验。显示的小数不是向外舍入区间。原 run-002 的源加密门未通过、后来经理按预算尺度接受，以及未认证的观测传播比率，仍按 [[research/projects/bie-enclosure/implementation/switch-v1|switch-v1]] 的记录保留；本证明不将它们提升为可靠输入。

### 13. 交接与核验记录

- **Part A：** 定理 SW 及谱距离推论在列出条件下已证明。相对已修补的 S′，跳跃符号、对偶权重、$p$、$C_{\mathrm{line}}$ 和端点 $L^1$ 尾均不变。点常数写成固定 $\alpha$ 或下确界，避免无须使用的极小点存在假设。
- **Part B：** 命题 EP 在相同条件下已证明。新增 (EP2)--(EP5) 的墙上集体估计；即使仍逐源取绝对值，也可把 $C_{\mathrm{pt}}(\alpha)$ 换成更小的 $C_{\mathrm{vol}}(\alpha)\sqrt{S(\alpha)}$。未进行可选的线项集体估计。
- **证明缺口：** 本文无 TODO 证明步骤。当前配置的源曲线基本性质和无平面波切换已由显式公式核实。实际数值使用仍须核验代理分离、边界组领子、连续积分误差和收缩幂证书；现有浮点记录不替代这些可靠输入。集体估计的实际相消需另算复 Fourier 矩。
- **引用核验：** 已检查 `reliable-bound.md` 的 T2.1--T2.3、T4.2--T4.3、T3.8 及对应审查；另检查 S-1--S-3 和 SP-1 的原文。这里只引用这些已读的内部结果；新的点值、墙迹、乘子和尾估计均在本文证明，没有引入未核验的外部文献定理。Proof literature verification completed.
- **记号：** 沿用 $\mathcal J_0,\mathcal J_1,A_0,A_1,E,p$；$C_{\mathrm{vol}}$ 表示新的体范数乘子，$\gamma_e$ 表示带方向的端点系数，$\zeta_w$ 表示同墙合并后的有限复测度，$\widehat\zeta_{w,m}$ 是实验线程须计算的复矩。这些对象分别承担常数、方向、相消与有限评价的作用。周期长度用 $d$，微分用 $\mathrm{d}$，虚数单位用 $\mathrm{i}$。
