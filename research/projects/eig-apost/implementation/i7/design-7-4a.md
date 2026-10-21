# I7.4：中心椭圆 raw 场的非 Fourier 预解式评价设计

## 1. 状态、目标与结论边界

- Design ID: `I7.4-ELLIPSE-RESOLVENT-V1`
- Status: `RUN COMPLETE; FINITE DIAGNOSTIC ONLY; TARGET STRICT CERTIFICATE NOT ACHIEVED; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Independent review: [[research/projects/eig-apost/implementation/i7/review-7-4a|PASS WITH CONDITIONS; partial certificates only]]
- Claim boundary: `FULL-SPECTRUM DISTANCE ONLY`

本阶段把修正密度坐标后的 I7.1 候选冻结成一个分片 exact-kernel raw 场，沿用
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace|T9--T10]]、
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework|F14]] 和
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/p-numerics|N6--N9]]，评价材料界面与
人工墙的实际跳跃。目标是在所有单侧余项门关闭时给出
$\operatorname{dist}(\mu,\sigma(A(\beta)))$ 的可靠上界；否则仍交付完整普通数值评价、实际失败门
和已得到的可靠标量，不把未知余项设为零。

本阶段不改变候选、材料、几何或离散，不认证本质谱隙、离散 guided eigenvalue、唯一性或编号，
也不由 I7.2/I7.3 的小矩阵诊断代替连续界面范数。I6 的圆形材料行和空中心质量公式不能直接套到
椭圆。最终结论为 **CONDITIONAL**：预解式结构可复用且同一 raw 场质量下界已经关闭，但椭圆连续
核余项、retained-wall evaluator 与 complete infinite-cell action 仍是严格证书的硬门。

## 2. 冻结模型、候选与精确对象

物理参数固定为

$$
\beta=\frac12,\quad d=1,\quad
k_0=1.755995740875,\quad \mu:=\widehat k_0^2,
$$

其中 $\widehat k_0$ 是 MAT 中 binary64 位型代表的精确二进有理数，$\mu$ 是其实数精确平方，
不能换成打印十进制的再解析值或 MATLAB 已舍入的 `k0*k0`。左右 lead inclusion 是半径 $R=0.2$、
$\rho=17$ 的圆；中心是半轴 $(a,b)=(0.25,0.16)$、$\rho_c=2$ 的轴对齐椭圆；背景 $\rho=1$，
人工墙为 $X_L=-0.5,X_R=0.5$。除 $a=0.25$ 等可精确表示的数外，所有 MATLAB double 都按其
存储 dyadic 解释。这里冻结的是有限系数 $q,H_{L/R},P_\pm$ 的 dyadic 实虚部；核参数不能另把
MATLAB 舍入后的 `kint` 或 `gamma` 冻结成独立物理常数。数学 raw 场必须从 exact
$\mu=\widehat k_0^2$、$\beta$、$d$ 出发，取材料内波数
$k_\rho=\sqrt{\rho\mu}$ 和正确分支
$\gamma_m=\sqrt{\mu-(\beta+2\pi m/d)^2}$。普通 double 对这些函数的舍入属于尚未包围的数值误差。

使用 I7.3 baseline 配置 `(ntot,nside,ntop,nproxy,mpw,M)=(256,160,160,80,32,48)`。
令 $v$ 为 $A_{\mathrm{phys}}$ 最小奇异值对应的冻结右奇异向量，沿用原列权重

$$
q=D_cv=[a^L;b^R].
$$

实现随后用一个共同的正实 norm 和 phase anchor 把 $q$ 归一化、定相；这里仍以 $q$ 记该最终
向量。所有 center/lead densities、jump、wall 与 mass 必须从这个同一个 $q$ 生成，不能混入归一化
前的 amplitudes。F14 中 boundary defect 与 mass 同次缩放，因此这一全场共同 scale/phase 选择不改
最终齐次比值。

离散中心 scattering map 给出候选的 retained Rayleigh projection

$$
[b^L;a^R]=S_cq,\qquad
d_L=a^L+b^L,\quad d_R=a^R+b^R.
$$

`bloch.construct_S` 返回的 `H_L,H_R` 已是未缩放的 physical density。MATLAB 先按

$$
\eta_c=[\tau_c;\zeta_c]=H_La^L+H_Rb^R,\qquad \zeta_c=-\sigma_c,
\tag{I7.4-1}
$$

生成中心密度，且不得再次乘或除 square-root quadrature scale。本轮 raw 对象把最终保存的
`center_density=fl(H_L*aL+H_R*bR)` 自身冻结成独立 exact-dyadic 样本；(I7.4-1) 是生成关系与
一致性 audit，不强称浮点乘积后仍是严格等式。认证 evaluator 对这组 frozen samples 作数学有限
DFT 插值并作用于 exact kernel。公共 proxy/MFS 场及另行以 `Hmap*q` 形成的 boundary/wall action
只是同一 frozen raw 对象的普通数值近似，其 roundoff 与 source quadrature 误差必须保留为未认证项。

左右 stable subspace 写成 $Z_\pm=[A_\pm;B_\pm]$。必须从同一个 ordered QZ 的 stable block
形成完整传播矩阵 $P_\pm$，并保存 pencil identity；仅有谱半径诊断不够。近中心系数由

$$
c_+=(A_++B_+)^{-1}d_R,\qquad
c_-=(A_-+B_-)^{-1}d_L,
\tag{I7.4-2}
$$

若 ordered-pencil interface state 是 $Z_\pm P_\pm^nc_\pm$，则第 $n$ 个实际单胞的 incoming
amplitudes 必须用

$$
G_+=\begin{bmatrix}A_+\\B_+P_+\end{bmatrix},\qquad
G_-=\begin{bmatrix}A_-P_-\\B_-\end{bmatrix},\qquad
x_{\pm,n}=G_\pm P_\pm^nc_\pm.
\tag{I7.4-2a}
$$

$Z_\pm P_\pm^nc_\pm$ 只作 interface trace/recurrence 检查，不能直接作为
`[a^L;b^R]` 输入 density map。QZ 分类、坐标顺序、
$G_\pm$ 近端 block 及单胞 recurrence 都须用独立残差门核对；不强取 neutral 或 indeterminate
子空间。

(I7.4-2)--(I7.4-2a) 记录 $c_\pm,G_\pm$ 的构造来源；本轮冻结的是 MATLAB 最终保存的 binary64
矩阵与向量，不能声称舍入后的对象严格满足这些求解或乘积恒等式。raw lead field 以这些 frozen
dyadics 为系数，所有 coordinate/recurrence 残差通过实际材料与墙跳跃进入缺陷 ledger；普通 evaluator
中的后续矩阵乘法舍入仍是未认证误差。

## 3. 界面清单、方向与 raw 跳跃

材料法向一律从 inclusion 内部指向背景。对每条材料界面定义

$$
a=u^{\mathrm{out}}-u^{\mathrm{in}},\qquad
j=\partial_\nu u^{\mathrm{in}}-\partial_\nu u^{\mathrm{out}}.
\tag{I7.4-3}
$$

中心椭圆只记一次 singleton。以 $B_D,B_N$ 表示 $q$ 的 incident Dirichlet/普通外法向迹，
公共 raw Muller 两行给出

$$
\begin{aligned}
a_c={}&B_Dq+
 [I+D_e^{QP}-D_i,\ S_i-S_e^{QP}]\eta_c,\\
j_c={}&-\left\{B_Nq+
 [T_e^{QP}-T_i,\ I+D_i^*-D_e^{QP,*}]\eta_c\right\}.
\end{aligned}
\tag{I7.4-4}
$$

第二行的 identity 必须保留。该式使用 $\eta=(\tau,\zeta)$、$\zeta=-\sigma$；不得改用 scaled
BIE coordinate。左右 lead 圆继续用 I6 已审查的 circle signed-action 行作用于
$x_{\pm,n}$，其中首胞材料项是 $n=0$，中心椭圆不进入这两个周期序列。

人工墙采用从中心向对应 lead 的法向：左墙 $\nu_w=-e_x$，右墙 $\nu_w=e_x$。同一个 $q$ 和
$S_cq$ 给出中心侧墙迹的 retained Rayleigh projection：

$$
u_c|_{X_L}=a^L+b^L,\quad
\partial_{\nu_w}u_c|_{X_L}=\mathrm i\Gamma(b^L-a^L),
$$

$$
u_c|_{X_R}=a^R+b^R,\quad
\partial_{\nu_w}u_c|_{X_R}=\mathrm i\Gamma(a^R-b^R).
\tag{I7.4-5}
$$

式 (I7.4-5) 只含 $m=-M{:}M$，而且 $S_cq$ 本身只是离散候选近似：即使在 retained 模态内，
它也仍带有 source quadrature 与数值 QP kernel/proxy 误差。完整 exact-kernel center field 还含椭圆
layer density 产生的遗漏 Rayleigh 模态。实际墙 defect 必须用 (I7.4-13) 的同一 raw 场在物理墙上
直接评价；retained projection 只作独立坐标检查。认证时须分别包围 retained-mode 数值误差与遗漏
模态的可靠 $L^2$ 尾，不能把 finite scattering matrix 误作完整墙迹。

以中心为 `in`、lead 为 `out` 时，墙缺陷为
$a_w=u_{\mathrm{lead}}-u_c$、
$j_w=\partial_{\nu_w}u_c-\partial_{\nu_w}u_{\mathrm{lead}}$。
内部 lead 墙继续沿 I6 的配对行与符号。旧 I6 的 empty-center `q_center` 墙 singleton 不可原样复用。
有限界面 ledger 固定为：中心椭圆 singleton、左右中心墙 singleton、两侧各 $J$ 个 lead 圆和内部墙、
以及各自从 $J$ 起的完整传播尾；每条物理界面只计一次。

遗漏墙模态可直接复用 I5 的 shape-general positive-distance bound。令某个实际 density state 的
parameter Fourier coefficients为 $\widehat\tau,\widehat\zeta$，曲线实轴 speed 上界为 $v_{\max}$，并定义

$$
A_\tau=2\pi v_{\max}\|\widehat\tau\|_2,
\qquad A_\zeta=2\pi v_{\max}\|\widehat\zeta\|_2.
\tag{I7.4-5a}
$$

它们分别上界 $\|\tau\|_{L^1(ds)}$ 与 $\|\zeta\|_{L^1(ds)}$。中心椭圆须用本轮实际
`eta_center_256` 的两块系数和 $v_{\max}=a$；lead 圆则用对应 $G_\pm P_\pm^nc_\pm$ 的实际 density
及 $v_{\max}=R$。对距离曲线至少 $\delta>0$ 的墙，取 $q_0=2\pi/d$、$N=M_w+1$、
$t_N=q_0N-|\beta|$、$\kappa_N=(t_N^2-\mu)^{1/2}$，并要求 $t_N>\sqrt\mu$。记

$$
r=e^{-2\delta q_0},\qquad
S_j(r,N)=\sum_{n=N}^{\infty}n^jr^n\quad(j=0,1,2),
$$

$$
H_N=\left(1+\frac{t_N}{\kappa_N}\right)A_\tau
+\frac{A_\zeta}{\kappa_N},
\qquad C_N=2|\beta|A_\tau+A_\zeta.
$$

则两侧 $|m|\ge N$ 的 wall-value 与 wall-normal 模态能量分别满足

$$
E_u^{>M_w}\le
\frac{e^{2\delta(\sqrt\mu+|\beta|)}}{2d}H_N^2S_0(r,N),
\tag{I7.4-5b}
$$

$$
E_n^{>M_w}\le
\frac{e^{2\delta(\sqrt\mu+|\beta|)}}{2d}
\left[4q_0^2A_\tau^2S_2(r,N)
+4q_0A_\tau C_NS_1(r,N)+C_N^2S_0(r,N)\right].
\tag{I7.4-5c}
$$

这是 I5 general-wall bound 对实际 ellipse density 的直接实例化，不使用圆 Bessel diagonal。墙跳跃是
两个 raw fields 的差，因此其 high-tail energy 用
$(\sqrt{E^{(1)}}+\sqrt{E^{(2)}})^2$ 合并。实现必须把 $|m|\le M_w$ 的 direct modal rows 与
(I7.4-5b)--(I7.4-5c) 的尾互斥相加；不得把该尾再加到已经以全节点 trapezoid 形成的同一 full-wall
norm 上而重复计数。普通 double 实现能给出有限保守诊断，但只有所有输入与指数/级数向外包围后
才是认证上界。

对内部 lead 墙，若单胞 high-mode action 满足
$E_{\rm hi}(x)\le\Omega_{\rm hi}\|x\|_2^2$ 且 whole-matrix gate 给出
$\|P\|_2\le r_P<1$，相邻胞差与从第 $J$ 胞起的尾可用

$$
\sum_{n=J}^{\infty}E_{\rm hi}(P^nc-P^{n+1}c)
\le\Omega_{\rm hi}\frac{(1+r_P)^2r_P^{2J}}{1-r_P^2}\|c\|_2^2.
\tag{I7.4-5d}
$$


左右两侧分别应用后相加；center-adjacent walls 保留为 singleton，不再乘该传播因子。

## 4. 椭圆几何、collar 与新迹常数

公共参数化为

$$
r(t)=(a\cos t,b\sin t),\quad
r'(t)=(-a\sin t,b\cos t),
$$

$$
v(t)=|r'(t)|=(a^2\sin^2t+b^2\cos^2t)^{1/2},\quad
\nu(t)=\frac{(b\cos t,a\sin t)}{v(t)},\quad
\kappa(t)=\frac{ab}{v(t)^3}.
\tag{I7.4-6}
$$

因此 $\kappa_{\rm ell}=a/b^2$，椭圆法向管的 reach 为 $b^2/a$；圆的曲率为
$1/R$。这里的全局门不能只由正 Jacobian 推出：填充椭圆外部对闭凸集的 metric projection 唯一；
内部 medial axis 是 major-axis segment，其端点由对称 inward normals 与 $x$ 轴的交点
$x=\pm(a-b^2/a)$ 给出，到边界的最小距离为 $b^2/a$。因此距离边界严格小于 $b^2/a$ 的内外点
都有唯一法向坐标。这一解析 reach 论证足以关闭形状层面的全局单射门；T12 interval chord
certificate 只可作独立复核，不是额外必要条件。实际证书必须对 exact stored dyadics 向外评价，不能把打印值
$9.765625$ 和 $0.1024$ 当作无半径输入。共同选择 $h=0.04$，并证明

$$
h<b^2/a,\qquad
\kappa_*:=\max(a/b^2,1/R),\qquad
\theta:=1-h\kappa_*>0.
\tag{I7.4-7}
$$

椭圆解析 reach 门给出单射证明；也可按 T12 的有限区间弦距证书复核，但单纯节点采样不算证明。
还须用向外区间证明 $2h$ 小于下列所有实际分离下界：

$$
\tfrac12-a,\quad \tfrac12-R,\quad
1-a-R,\quad 1-2R,\quad d-2b,\quad d-2R,
\tag{I7.4-8}
$$

并检查人工墙间距及有限模板的其余可能平移。通过后所有 material/wall collars 互不相交，
可取 $N_{\rm ov}=1$；任何一个间距不确定都不得保留该结论。

取 $\ell_*=d=1$、$\rho_-=1$、$\rho_+=17$，令

$$
c_0=\frac{N_{\rm ov}}{\theta h},\qquad
c_1=\frac{N_{\rm ov}h}{2\theta}.
$$

T9 仍适用于椭圆及圆的共同界面族，新的可靠常数为

$$
\overline C^2=\operatorname{up}\!\left[
\frac{c_0}{\rho_-\mu^2}
+\frac{c_1+\ell_*^2c_0}{4\mu}
+\ell_*^2c_1\rho_+\right].
\tag{I7.4-9}
$$

这里 $h$ 是 collar 半宽，不是边界步长。

## 5. 椭圆非 Fourier 材料行的最小认证合同

椭圆两点距离精确分解为

$$
|r(t)-r(s)|^2=
4\sin^2\!\frac{t-s}{2}\;g(t,s),
$$

$$
g(t,s)=a^2\sin^2\!\frac{t+s}{2}
+b^2\cos^2\!\frac{t+s}{2}.
\tag{I7.4-10}
$$

因此 Kress 权重只可复用 universal 的
$\log(4\sin^2((t-s)/2))$ 部分。$\log g(t,s)$、variable speed、source/target normals、
Maue 切向导数及对角 limits 都属于新的 smooth remainder，必须在连续 target/source strip 上给
可靠导数和求积余项。把 `radius` 换成 `max(a,b)`、把 speed 当常数、或沿用圆的 offset convolution
都会漏项。

首个严格尝试保留 I6 的参数 strip $|\operatorname{Im}t|\le1/5$，但必须以区间算术证明
$v(t)^2$ 与 $g(t,s)$ 在相应复 strip 上不含零，并分别形成 position、normal、kernel derivative、
density growth 和 source quadrature 的单侧界。椭圆周长与弧长权重必须用

$$
\mathrm ds=v(t)\,\mathrm dt,\qquad
\|f\|_{L^2(\Gamma_c)}^2=
\int_0^{2\pi}|f(t)|^2v(t)\,\mathrm dt,
\tag{I7.4-11}
$$

不能使用 $2\pi a$ 或常数 source weight。中心 retained signed row须先按 (I7.4-4) 合并，再取模；
continuous local tail、regular-image Ewald tails、source/target trapezoid remainders 和 off-surface
Rayleigh support 各有唯一 owner。普通 double 节点积分、加密差或 sampled maximum 只作数值诊断。

对一般 strip 宽 $\alpha$，可直接采用下列形状界：

$$
I_x=a\sinh\alpha,\quad I_y=b\sinh\alpha,\quad
V_x=a\cosh\alpha,\quad V_y=b\cosh\alpha,
$$

$$
m_v^2=\frac{a^2+b^2}{2}
-\frac{a^2-b^2}{2}\cosh(2\alpha),\qquad
M_v^2=\frac{a^2+b^2}{2}
+\frac{a^2-b^2}{2}\cosh(2\alpha).
\tag{I7.4-11a}
$$

必须证明 $m_v^2>0$；随后 analytic speed branch 满足
$|v|\le\sqrt{M_v^2}$。由于
$v(z)^2=c-d\cos(2z)$，其中 $c=(a^2+b^2)/2$、$d=(a^2-b^2)/2$，而
$|\cos(2z)|\le\cosh(2\alpha)$，故这里的 $M_v^2=c+d\cosh(2\alpha)$ 直接上界
$|v^2|$；同时 $\operatorname{Re}v^2\ge c-d\cosh(2\alpha)=m_v^2>0$ 固定解析平方根分支。
此外
$\operatorname{Im}((t+s)/2)\le\alpha$，同一个 $m_v^2$ 也使 (I7.4-10) 的 $g$ 与零分离，
从实轴正支连续确定 $\log g$。中心墙的 complex strip clearance 是
$1/2-a\cosh\alpha>0$。这些常数可直接送入 I5 的 shape-general wall row、周期梯形余项和高模尾；
因此完整中心墙并非新的理论路线。

要把中心材料行升级为严格界，主要新增工作是把公共 general-geometry
`kress_l_splits`、`kress_mn_splits` 中的几何 factors 和 diagonal limits 移入球算术，结合
(I7.4-10) 包围 smooth $\log g$、整个 Bessel series tail、source quadrature radius 和完整
target-strip 行。现有 I6 Arb helper 只实现 circle convolution，公共 general helper 又只有 double
节点矩阵；在这项 bivariate continuous remainder 完成前，网格加密不能把它升级为单侧界。

本轮最小普通数值路线仍须完整计入各物理项。用同一 $q$、physical densities 和由 exact 参数定义
但以 double 评价的 kernels，在两组 source/target 节点上：（i）直接重组 boundary-limit Muller
matrix，评价中心椭圆与 lead 圆的 signed material rows；（ii）在两条中心墙及所有相邻 lead 墙上直接评价同一
raw 场的 value/normal jumps，而不是以 $S_cq$ 代替；（iii）逐胞累加两侧冻结数量的 lead 项，
把下一项与观察到的比率所给 geometric tail 单列为 `candidate`；（iv）在安全盘同时评价质量积分与
point/gradient cone candidate。粗细差、offset 外推、观察传播比和 disk sampling 都须完整保存，
但只要对应连续余项未单侧包围，最终状态就是 `FINITE_DIAGNOSTIC_ONLY`。具体地，若 $A_N^s$ 是
`op.construct_A_QP` 返回的 scaled matrix，$h_N=2\pi/N$、

$$
W_N=\operatorname{diag}\sqrt{h_N[v_N;v_N]},
$$

则 physical density 的 boundary action 是

$$
R_N(\eta_N)=W_N^{-1}A_N^sW_N\eta_N.
\tag{I7.4-11b}
$$

$\eta_N$ 只能由冻结 $N=256$ density 的同一个 trig interpolant 在 $N=256,512$ 取值。加上相应
incident rows 后，第一块是 $a_N$，第二块的负号给 $j_N$；$A_N^s$ 已含两块 identity，不能重复加。
普通平方范数用 $h_Nv_N$。$N=256$ 行与生成 density 的离散求解使用同一个矩阵，残差接近
roundoff 是代数控制，不是收敛率；判断普通连续残差时须报告独立 $N=512$ 的 absolute norm，不能因
相对变化分母接近零而把巨大 relative change 单独判作失败。双侧 offset 外推只保留为失败诊断，
不再作为材料主值。

Lead 圆的 I6 circle evaluator可原样用于其自身材料行，但必须输入本次新冻结 density/state；旧 I6
数值产物不是本轮输入。材料总量是中心 singleton、左右有限 lead 序列和完整传播尾的平方和。

## 6. 同一 raw 场的质量下界

I6 的 empty-center 两支 Rayleigh Gram 公式不适用，因为本次中心胞元包含椭圆 scattered field。
选择完全位于中心背景的 exact dyadic 圆盘

$$
D=B(x_*,r_*),\qquad x_*=(3/8,0),\qquad r_*=1/16.
\tag{I7.4-12}
$$

由 $x\ge5/16>a$ 且 $x\le7/16<1/2$ 可知 $D$ 与椭圆和人工墙均有正间隔。盘内使用与
(I7.4-4) 相同 density 和 exact QP kernel 的完整中心外场

$$
u_c(x)=u_{\rm inc}(q;x)+D_e^{QP}\tau_c(x)-S_e^{QP}\zeta_c(x).
\tag{I7.4-13}
$$

其中 finite incident field 必须显式取

$$
u_{\rm inc}(x,y)=\frac1{\sqrt d}\sum_{m=-M}^{M}
\left[a_m^Le^{\mathrm i\gamma_m(x-X_L)}
+b_m^Re^{-\mathrm i\gamma_m(x-X_R)}\right]e^{\mathrm i\beta_my}.
\tag{I7.4-14}
$$

在 $D$ 上令 $x_-=5/16,x_+=7/16$，并记
$E_{L,m}=e^{-\operatorname{Im}\gamma_m(x_--X_L)}$、
$E_{R,m}=e^{-\operatorname{Im}\gamma_m(X_R-x_+)}$。一个直接的梯度上界为

$$
G_{\rm inc}=\frac1{\sqrt d}\sum_m
(|\gamma_m|+|\beta_m|)
\left(|a_m^L|E_{L,m}+|b_m^R|E_{R,m}\right).
\tag{I7.4-15}
$$

本轮优先使用不需要 Ewald panel 的 QP Rayleigh 路线。直接以冻结的 exact-dyadic
`center_density` 形成 $N_0=256$ 的 continuous trig interpolants；不再用 $H,q$ 重乘而改换 raw
对象。为与 `interpft` 一致，偶数 Nyquist coefficient 分成
$n=\pm128$ 两半。对 $x_*=3/8>a$，scattered field 的第 $m$ 个 Rayleigh coefficient是

$$
c_m=\int_0^{2\pi}\frac{\mathrm i}{2d\gamma_m}
e^{\mathrm i\gamma_m(x_*-a\cos t)-\mathrm i\beta_mb\sin t}
\left[-\mathrm i(\gamma_mb\cos t+\beta_ma\sin t)\tau_c(t)
-v(t)\zeta_c(t)\right],\mathrm dt.
\tag{I7.4-15a}
$$

在 $\alpha=1/10$ 上直接计算
$D_\tau=\sum_n|\widehat\tau_n|e^{|n|\alpha}$ 和
$D_\zeta=\sum_n|\widehat\zeta_n|e^{|n|\alpha}$。令
$V_s=\sqrt{M_v^2}$，并取

$$
\Phi_m=\begin{cases}
\exp((|\gamma_m|a+|\beta_m|b)\sinh\alpha),&\gamma_m\in\mathbb R,\\
\exp(-\operatorname{Im}\gamma_m(x_*-a\cosh\alpha)
+|\beta_m|b\sinh\alpha),&\gamma_m\in\mathrm i\mathbb R_+.
\end{cases}
$$

则 $N_q=512$ 的 periodic trapezoid radius 可取

$$
\epsilon_m^{\rm trap}=\frac{4\pi M_m}{e^{\alpha N_q}-1},\qquad
M_m=\frac{\Phi_m}{2d|\gamma_m|}
\left[(|\gamma_m|b+|\beta_m|a)\cosh\alpha\,D_\tau
+V_sD_\zeta\right].
\tag{I7.4-15b}
$$

$\gamma_m$ 必须由 exact $\mu,\beta,d$ 在球算术中取正确分支，不能导入 double `gamma`；任何 Wood
不确定性、strip nonzero 失败或复指数非有限都 fail closed。保留 $|m|\le48$ 的 balls。遗漏点值与
盘梯度尾分别使用 $\delta_*=x_*-a=1/8$、$\delta_D=x_*-r_*-a=1/16$。若
$s_\delta=e^{-\delta q_0}$，记

$$
T_0(\delta)=\frac{s_\delta^N}{1-s_\delta},\qquad
T_1(\delta)=s_\delta^N\left(\frac{N}{1-s_\delta}
+\frac{s_\delta}{(1-s_\delta)^2}\right),\qquad N=49.
$$

用 (I7.4-5a) 的实际 $A_\tau,A_\zeta$ 和 (I7.4-5b) 前定义的 $H_N$，可取

$$
R_*=\frac{e^{\delta_*(\sqrt\mu+|\beta|)}}dH_NT_0(\delta_*),
$$

$$
G_{\rm tail}=\frac{2e^{\delta_D(\sqrt\mu+|\beta|)}}dH_N
\left[q_0T_1(\delta_D)+|\beta|T_0(\delta_D)\right].
\tag{I7.4-15c}
$$

点值球由 incident、$\sum_{|m|\le48}c_m$ 和半径 $R_*$ 合成；盘梯度上界把每个 retained ball 乘
$(|\gamma_m|+|\beta_m|)e^{\operatorname{Im}\gamma_m r_*}$，再加 (I7.4-15) 与
$G_{\rm tail}$。这给出与同一 raw 场一致的 $u_*$ 和 $G_D$。

以下 Ewald panel 路线只作为未采用的等价后备。对 layer 部分定义

$$
F(x,t)=\left[\partial_{\nu(t)}G_{QP}(x,r(t))\tau_c(t)
-G_{QP}(x,r(t))\zeta_c(t)\right]v(t).
$$

把 $[0,2\pi]$ 分成宽 $\Delta_j$、中点 $t_j$ 的 panels。每个 exact Ewald kernel ball 必须含自身
截断余项；再以 interval arithmetic 形成

$$
U_{\rm sc,*}\in
\sum_j\Delta_jF(x_*,t_j)
+B\!\left(0,\sum_j\frac{\Delta_j^2}{4}
\sup_{t\in I_j}|\partial_tF(x_*,t)|\right),
\tag{I7.4-16}
$$

$$
G_{\rm sc}\le\sum_j\Delta_j
\sup_{x\in D,\,t\in I_j}|\nabla_xF(x,t)|,
\qquad G_D=G_{\rm inc}+G_{\rm sc}.
\tag{I7.4-17}
$$

中点余项来自
$\int_{I_j}|t-t_j|\,\mathrm dt=\Delta_j^2/4$，不需要经验收敛率。由于
$\operatorname{dist}(D,\Gamma_c)\ge1/16$，这里没有对角奇异性；I6 Ewald 坐标导数界可在新的
target-disk/source-panel interval domain 上复用。最后取
$u_*=\operatorname{lower}|u_{\rm inc}(x_*)+U_{\rm sc,*}|$。

若球算术证明

$$
u_*\le |u_c(x_*)|,\qquad
\sup_{x\in D}|\nabla u_c(x)|\le G_D,\qquad
m_D:=\max(u_*-r_*G_D,0)>0,
$$

则 N9 给出

$$
\underline U^2=\pi r_*^2m_D^2
\le\int_D|u_c|^2
\le\|u\|_{\mathcal H}^2.
\tag{I7.4-18}
$$

点值与梯度界必须覆盖 incident finite Rayleigh sum、QP layer action、density 插值、连续源求积和
特殊函数余项；它们必须针对同一 raw 场。盘上普通二维 quadrature 可作为 sanity check，但不是
(I7.4-18) 的下界。若 $m_D=0$，本轮仍报告零信息下界和原因，不换候选或凭普通积分补正。

## 7. 精确 PDE、准周期与 $L^2$ 资格

认证 raw 场定义为冻结有限 density 插值作用于由 exact $\mu,\rho,\beta,d$ 决定的 exact free/QP Helmholtz kernels，
并加同一 $q$ 的 finite Rayleigh incident field。因此每个材料片内
$(\Delta+\rho\mu)u=0$；中心及 lead 的 QP kernel/模态表示在 $y$ 方向给出精确
$\beta$-quasiperiodicity。只有在 evaluator 的数学定义确为这些 exact kernels、且坐标/相位 identity
逐项通过时，才可把 volume 和 seam defects 记为严格零；公共 proxy 残差小不提供这一结论。

有限中心胞元的 smooth finite-density 层势分片属于 $L^2$。两个无限 half-guides 还必须对完整
$P_\pm$ 证明 I6 C5 的收缩幂界；优先使用
$r_\pm\ge\|P_\pm\|_F<1$，若改用 N7 block-power 形式则须完整保存所有前缀范数，不能只用
谱半径。配合有限单胞场映射有界性才得到全 raw 场属于 $\mathcal H$。墙和材料尾中的传播因子
各只乘一次。

## 8. I6 合同的复用边界

| I6 object | I7.4 status | 最小门 |
|---|---|---|
| C1 exact input / exact $\mu$ | reuse | 新 MAT 每个 binary64/整数逐项无损导出 |
| C2 Arb inclusion | reuse | 非有限球、含零分母和不确定比较 fail closed |
| C3 / T9 trace constant | re-evaluate | 使用椭圆、圆、墙的 (I7.4-7)--(I7.4-9) |
| C4 empty-center mass | replace | 使用同场安全盘 (I7.4-12)--(I7.4-18) |
| C5 propagation tail | reuse structure | 新 $G_\pm,P_\pm,c_\pm$ 与 full-matrix contraction |
| C6 material/wall defect | partial reuse | lead circles和内部墙复用；中心椭圆与两中心墙重建 |
| C7 / F14 scalar composition | reuse | 所有输入先是可靠单侧界且 $\underline U>\overline Q$ |
| equations C8--C10 | reuse structure | 新 interface ledger、$\ell_*=1$、向外端点字符串 |

## 9. F14、状态语义与交付

令

$$
\overline\varepsilon_\partial^2=
\sum_{\Gamma}
\left(\overline{\|j_\Gamma\|_2^2}
+\ell_*^{-2}\overline{\|a_\Gamma\|_2^2}\right),
\quad
\overline Q=\operatorname{up}(\overline C\,
\overline\varepsilon_\partial).
\tag{I7.4-19}
$$

若第 3--7 节全部可靠门通过且
$D=\operatorname{down}(\underline U-\overline Q)>0$，则体缺陷为零并可输出

$$
\overline R=\operatorname{up}\left(
\frac{2\mu_+\overline Q}{D}\right),\qquad
\operatorname{dist}(\mu,\sigma(A(\beta)))\le\overline R.
\tag{I7.4-20}
$$

状态只能取：

- `CERTIFIED_SPECTRAL_DISTANCE_UPPER_BOUND`：所有结构、几何、连续余项、传播、质量和分母门通过；
- `CERTIFICATION_DENOMINATOR_FAILED`：可靠 $C,\varepsilon_\partial,U$ 已有，但 $U-Q$ 未证明为正；
- `FINITE_DIAGNOSTIC_ONLY`：完整 raw 场普通数值评价完成，但至少一个单侧余项或质量门未认证；
- `FINITE_PREFIX_DIAGNOSTIC_TAIL_UNAVAILABLE`：有限 singleton/逐胞 prefix 已保存，但观察 tail 不满足
  有限 geometric candidate 条件；该状态不虚设尾，也不因结果偏大而丢弃已完成数据；
- `EXECUTION_FAILED`：结构、数值或资源使完整评价未完成。

后两类也必须保存各 singleton、有限序列、尾项、$C$、数值质量、$Q$ 和首个未关闭门；不得用
NaN 之外的编造值补齐，也不得把 formula evaluation 称作实际上界。认证结果无论大小都交付。

Engineer 串行执行且独占 MATLAB；全部 MATLAB/Arb/debug/audit 共用 1800 s，process-tree RSS
硬限 3,000,000,000 bytes，无并发。先完成 exact-object export 和 full ordinary evaluation；剩余预算
才执行 Arb 余项闭合。每阶段原子保存 checkpoint，资源终止时保留 monitor 与最后产物，不读取 I6
旧输出作为科学输入。

## 10. 符号映射

| Symbol | Code object | Meaning |
|---|---|---|
| $q$ | `q_center` | frozen center incoming amplitudes `[aL;bR]` |
| $\eta_c$ | `eta_center_256` | physical `[tau;zeta]`, `zeta=-sigma` on ellipse |
| $x_{\pm,n}$ | `Gplus/Pplus/cplus`, `Gminus/Pminus/cminus` | complete lead port states |
| $a,j$ | `value_jump`, `normal_jump` | (I7.4-3), ordinary derivative |
| $v,\nu,\kappa_*$ | ellipse geometry records | speed, outward normal, common curvature bound |
| $h,\theta,N_{\rm ov}$ | collar records | trace geometry, not discretization spacing |
| $\overline C$ | `trace_upper` | T9 trace constant with all interface templates |
| $\overline\varepsilon_\partial$ | `epsilon_upper` | complete T10 boundary defect upper |
| $\underline U$ | `mass_lower` | same-field safe-disk mass lower |
| $\overline R$ | `spectral_upper` | F14 full-spectrum distance upper, if certified |

## 11. 运行前最小决定门

`GO` 仅表示实现普通完整评价及尝试认证具有清楚合同。运行前必须先通过：中心 density 的 physical
coordinate round trip；(I7.4-1)--(I7.4-5) 的形状和符号 identity；椭圆节点的参数化、法向、speed
和曲率对照；lead stable QZ 与 recurrence；全部输入 finite。椭圆 circle-limit $a=b=R$ 必须复现
原 circle action 到预先记录的普通浮点容差，实际椭圆的 raw row还须与独立 direct evaluation
对照。该 circle control 只能检错，不能替代椭圆连续余项证明。

实际运行已经得到同一 raw 场的 finite diagnostic ledger，并关闭安全盘 point/gradient bounds。
只有在椭圆连续 strip 余项、retained-wall evaluator 与 complete infinite-cell action 上界也关闭时，
才允许执行 (I7.4-20) 的认证标签。

## 12. 实际结果与停止门

正式产物位于 `test/i7/resolvent-v1/output/attempt-1/`。`run-01` 的双侧 offset 材料评价虽正常退出，
但 $256\to512$ 的四项相对变化为 $0.9306$--$0.9984$，故该材料路线被 **REFUTED**；其
$\varepsilon_\partial=0.762146950984352$ 不再作为当前结果。`run-02` 在科学 stage 2 前因 monitor
的 `ps` 收到 `SIGINT` 而退出 130，只是保留的 operational failure。`run-03` 改用
(I7.4-11b) 的 boundary-limit action 后正常完成；这是同一 attempt 内对 offset 程序错误的修复，
没有改变模型、候选或科学方案。当前 ordinary finite diagnostic 为

| quantity | value |
|---|---:|
| center material value squared | $1.8194738297815184\times10^{-30}$ |
| center material normal squared | $1.1002890647906295\times10^{-28}$ |
| lead material value squared | $2.2883582582396657\times10^{-30}$ |
| lead material normal squared | $1.4932982947408970\times10^{-28}$ |
| all wall value squared | $3.7486709799872045\times10^{-27}$ |
| all wall normal squared | $1.0233668117077186\times10^{-20}$ |
| $\varepsilon_{\partial,\mathrm{num}}$ | $1.0116161391167468\times10^{-10}$ |
| sampled mass candidate | $0.11463157444478528$ |

这里 $N=512$ normalized full material actions 的 Frobenius diagnostics 分别为
$1.3287369921200874\times10^{-16}$（center）和
$9.02128781159929\times10^{-17}$（lead）；raw-coordinate identity defect 为
$2.3833961255776436\times10^{-13}$。$N=256$ 是生成 density 的 collocation grid，因此两层接近
roundoff 的 absolute residual 才是事实；其 relative change 不解释为离散收敛率。

`run-04` 没有重算物理候选，只给 frozen `center_density` 与 $q$ 增加严格 Rayleigh/Arb 质量评价。
它证明

$$
|u_c(x_*)|\ge1.0477079134624909,
\qquad G_D\le3.8031986941171465,
$$

$$
m_D\ge0.8100079950801693,
\qquad \underline U=0.089731361884006394.
$$

其中 retained source trapezoid radius 总和不超过
$3.2006203486879587\times10^{-15}$，point high-mode tail 不超过
$1.8034080460374285\times10^{-16}$，disk-gradient high-mode tail 不超过
$3.835906779224561\times10^{-5}$。同一 scalar audit 还严格通过 exact $\mu$、几何/$\overline C$、
两侧 full-$P$ Frobenius contraction 与全部墙 $|m|>48$ 尾；
$\overline C=2.8638469201559887$。

仅把 ordinary $\varepsilon_{\partial,\mathrm{num}}$ 代入已认证的标量链，得到

$$
Q_{\mathrm{num}}=2.8971137643895875\times10^{-10},\quad
D_{\mathrm{num}}=0.08973136159429502,\quad
R_{\mathrm{num}}=1.9911235257679360\times10^{-8}.
$$

这三个量是 conditional formula values，**不是**
$\operatorname{dist}(\mu,\sigma(A(\beta)))$ 的可靠上界。尚未关闭的门恰为：center ellipse 的
continuous singular/source-target material remainder、retained wall QP/kernel/quadrature error，以及由
这些 continuous action bounds 控制的 finite/infinite-cell action upper。I6 当前 Arb 实现中的
`circle_geometry`、`local_factor_bounds`、`derivative_compose(radius)`、`local_split` 和
`local_centers` 都依赖圆的 difference/convolution 结构；ellipse 版本还需约 $256^2$ 个 pair 的
$g(t,s)$、八个 split factors/diagonal limits、四阶 product-strip、smooth-$\log g$/Bessel/Kress
半径及 Ewald domain 重审。该工作不是本轮可审查的小改，因此停止于
`FINITE_DIAGNOSTIC_ONLY`，不宣称严格谱距离认证。

`run-05` 从冻结模型重新构造全部普通数值对象，在同一进程内独立重组 matching/SVD/$q$、传播、
raw action、墙与最终分项，再重新执行严格标量程序；它不读取 `run-03` 或 `run-04` 的科学产物。
独立重组的最大相对 defect 为 $2.3430668573812629\times10^{-13}$，低于预注册的
$10^{-11}$ 门；其中 `center_density_defect`
$=2.1748325292298085\times10^{-16}$ 只核对 `fl(Hq)` 生成来源与冻结 density，不把该浮点生成式
改称 raw 场的严格恒等式。`run-05` 复现
$\varepsilon_{\partial,\mathrm{num}}=1.0116161391167468\times10^{-10}$、
$\underline U=0.089731361884006394$ 和 conditional
$R_{\mathrm{num}}=1.9911235257679360\times10^{-8}$；观察到的逐胞 geometric tail 仍只是 ordinary
diagnostic，不因重组 audit 通过而成为单侧界。

权威交付文件为 [result.json](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/result.json)、
[independent-audit.json](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/independent-audit.json)、
[scalar-report.json](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/scalar-report.json) 和
[monitor-status.txt](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/monitor-status.txt)。正式运行保存的
[ordinary evaluator](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/source/estimate_i7_resolvent.m)、
[independent audit](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/source/audit_i7_resolvent.m) 与
[strict scalar program](../../../../../test/i7/resolvent-v1/output/attempt-1/run-05/source/certify_scalars_i7.py)
是本节数值对应的 source snapshots。

`run-06` 只读 `run-05` 的保存数据并导出
[component-detail.json](../../../../../test/i7/resolvent-v1/output/attempt-1/run-06/component-detail.json)，不重算
物理候选。普通墙法向平方主要来自两条 center--lead 墙：
$1.0233596737731471\times10^{-20}$；左右各 40 个内部墙合计为
$7.1379345715630134\times10^{-26}$。观察传播尾的 normal/value ratios 约为 $0.091$，相应候选尾约
$10^{-67}$--$10^{-69}$，但 `tail_certified=false`，不能据此关闭 infinite-cell action 门。墙节点从
$256$ 到 $512$ 的 ordinary relative changes 为 $1.9705353158575575\times10^{-2}$（value）和
$8.1907194147797177\times10^{-5}$（normal）；它们是固定数据的加密诊断，不是单侧误差界。

结论按证据层次冻结为：

- **ESTABLISHED**：exact-$\mu$ 标量输入、ellipse reach/collar 与 $\overline C$、两侧 full-$P$
  contraction、所有墙 $|m|>48$ 尾，以及 frozen-density 同场质量下界；
- **CONDITIONAL**：把 ordinary boundary defect 代入已认证标量链得到上述 $R_{\mathrm{num}}$；
- **BLOCKED**：严格全谱距离上界仍缺 continuous ellipse material action、retained-wall evaluator 与
  complete infinite-cell action 的单侧上界。

资源记录为：`run-01` $222.778350$ s / $1{,}088{,}667{,}648$ bytes，`run-02`
$17.606960$ s / $978{,}190{,}336$ bytes，`run-03` $164.532928$ s /
$1{,}123{,}418{,}112$ bytes，`run-04` $23.885752$ s / $1{,}076{,}461{,}568$ bytes，
`run-05` $178.672574$ s / $1{,}209{,}221{,}120$ bytes，`run-06`
$20.774869$ s / $954{,}613{,}760$ bytes。累计受监测 wall time 为
$628.251433$ s，任务峰值为 $1{,}209{,}221{,}120$ bytes，均低于 $1800$ s 与
$3{,}000{,}000{,}000$ bytes；`run-02` 的 operational failure 也计入总时长。
