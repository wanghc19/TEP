# FEM 原生场的无限波导谱距离上界

日期：2026-10-23。**v2 / Revision B.1：非零 RT2 通量与精度机制**；独立审查以
[[research/projects/eig-apost/phase3-analysis/fem-bound/r-theory|r-theory]] 为准。
范围由 [[research/projects/eig-apost/phase3-analysis/fem-bound/p-scope|p-scope]] 冻结。
本文件给出新推导，不把文献中的源问题定理当作已有的 I9 谱距离定理。

**本轮目标。** 保留已证的弱残差到全谱距离转换，给出可直接实现的有限维非零通量、
显式小量机制，以及不破坏方程抵消的真实材料积分。旧零通量后备只有可靠性，
不能满足本轮精度目标；第 6 节给出解析否定证据。旧版通过记录不作为 Revision B.1 的审查结论。
尚未评价 I9.3 的任何新数值，也未证明其界必小、点谱存在或唯一性。

## 1. 对象、权威与依赖

采用当前 [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework|resolvent 框架]]
的加权连续算子，与只读 main `draft/zh/s-modelproblem.tex` 中
`eq:weighted-hilbert-space`、`eq:quasiperiodic-space`、`eq:fixed-beta-operator` 对齐。
连续算子记为 $A(\beta)$，固定 $\beta$ 后不依赖候选 $k$；不能把离散匹配铅笔的
$k$ 依赖带进它的定义。

main 的材料叙述使用一个共同周期背景 $\rho_{\mathrm p}$；I9 则有两个不同 lead。
本文件明确采用 I9 的两侧材料函数，保留相同的局部微分算子和形式，不使用共同背景
假设，也不调用 main 中仍为猜想的本质谱等式。当前 main `s-error.tex` 的界面跳跃
取普通梯度的两侧差；旧 `s-framework.md` 第 2 节对更早 draft 符号的冲突说明不是
当前 draft 的现状。

连续假设为：$d>0$、$\beta\in\mathbb R$，

$$
B=\mathbb R\times(-d/2,d/2),\qquad
0<\rho_{\min}\leq\rho(x,y)\leq\rho_{\max}<\infty.
\tag{1}
$$

$\rho$ 是原模型真实系数，沿 $y$ 周期，允许左右不同。I9 中 $d=L=1$、
$\beta=0.5$、$\rho_{\min}=1$、$\rho_{\max}=17$；中心为一个单连通、未额外缩放的
五瓣 inclusion $\Omega_0$，系数为 4；左右独立三瓣 inclusion 的系数为 17，背景为 1。
左右三瓣幅度分别为 $0.12$、$0.20$，保持同一全局朝向，不镜像。
准确曲线见 [[research/projects/eig-apost/implementation/i9/design-9-3a|design-9-3a]] 第 2 节。

依赖链仅为：

$$
\text{相容有限元场及零延拓}
\ \Longrightarrow\ \text{形式弱残差}
\ \Longrightarrow\ \text{显式通量上界}
\ \Longrightarrow\ \text{正移位谱测度恒等式}
\ \Longrightarrow\ \operatorname{dist}(\mu_h,\sigma(A(\beta))).
$$

核心转换只用 Sobolev 迹/拼接、闭形式表示、Riesz 表示及非负自伴算子的谱定理。
不依赖未知真特征函数、紧预解式、Galerkin 精确正交性、相邻模态数、带隙认证或强残差属于 $L^2(B)$。

## 2. Hilbert 空间、算子与 FEM 场身份

所有内积对第一变量线性。设

$$
\mathcal H=L^2(B,\rho\,\mathrm{d}x\,\mathrm{d}y),\qquad
(u,v)_{\mathcal H}=\int_B\rho u\overline v,\qquad
V=H^1_\beta(B)
=\{v\in H^1(B):v(x,d/2)=e^{\mathrm{i}\beta d}v(x,-d/2)\}.
\tag{2}
$$

边界等式取迹意义。形式

$$
a(u,v)=\int_B\nabla u\cdot\nabla\overline v,\qquad u,v\in V
\tag{3}
$$

稠密、非负且闭：材料上下界使 $a(v,v)+\|v\|_{\mathcal H}^2$ 与 $H^1$ 范数等价，
值准周期条件为闭迹条件；内部紧支撑光滑函数的稠密性足以保证在 $\mathcal H$ 中稠密。
形式表示定理定义非负自伴算子

$$
\begin{aligned}
D(A(\beta))&=\{u\in V:\text{存在 }f\in\mathcal H,
\ a(u,v)=(f,v)_{\mathcal H}\ \text{对所有 }v\in V\},\\
A(\beta)u&=f.
\end{aligned}
\tag{4}
$$

内部测试函数给 $A(\beta)u=-\rho^{-1}\Delta u$，其中 $\Delta$ 是全条带分布
Laplacian；Green 配对给出 $\partial_yu$ 的准周期弱迹。对分片光滑函数，(4) 要求
值与普通法向导数连续，没有 $\rho$ 加权刚度或 $\rho\partial_\nu u$ 传输条件。
这正是上述主框架的连续算子。以后为简洁写 $A=A(\beta)$。

给定有限条带

$$
B_N=(x_-,x_+)\times(-d/2,d/2),\qquad x_-<x_+,
\tag{5}
$$

以及非零 $u_h\in H^1(B_N)$，要求上下值精确准周期，左右端迹为零。
I9.3 的 $x_-=-6.5$、$x_+=6.5$，场为六节点等参曲边 $P_2$：
每个参考三角形 $\widehat K$ 上有二次几何图 $F_K$ 和二次场 $\widehat u_K$，
$u_h|_K=\widehat u_K\circ F_K^{-1}$。本文件的网格假设是：

1. 每个 $F_K$ 是双 Lipschitz、保向的图，$\det DF_K$ 在闭参考三角形上严格为正；
2. 相邻曲边的几何参数化与场迹一致，单元内部两两不交、覆盖准确的矩形 $B_N$；
3. 上下直边几何配对一致，所有值自由度，包括边中点，以 $e^{\mathrm{i}\beta d}$ 配对；
   人工端整边三个 $P_2$ 自由度为零。

这些是有限、可核验的输入资格，不由一项面积总和或 Gauss 点上的正 Jacobian 自动推出。
实际检查可由共享节点/边方向与准确矩形外边界开始，再排除非相邻二次边交叉和单元
内部重叠，结合全参考单元的正 Jacobian 验证。若需要纯粹的有限可判定后备，把保存的
节点坐标视为准确有理数，则各 $F_K$ 为有理系数多项式：单元注入性、两单元内部
是否相交，以及其像是否恰好覆盖矩形，都能写成有限实多项式等式/不等式的量词命题，
用实闭域量词消去判定。这是可计算性后备，不声称对本例高效；首选仍是有限曲边
拓扑及相交检查。这里没有用未知谱信息或未知真场解决网格资格。
源码 `test/i9/compare-v1/fem_i9_run.m` 的 `LOCAL_mesh`、`LOCAL_assemble`、
`LOCAL_constraint` 给出了相应数据；既有
[[research/projects/eig-apost/implementation/i9/review-9-3a|I9.3 独审]] 提供 ordinary-arithmetic
的节点、全参考三角形 Jacobian 和约束证据，不自动等于本文件的精确输入证书。
人工端虽为直线，其 $P_2$ 参数化不自动为常速仿射。只有中点节点准确等于两端点的
算术中点时才有此性质；源码的中点平均构造不保证把已保存浮点坐标视为精确数后
仍满足该等式。第 8 节的基本界直接评价插值通量端迹，不要求常速，也不移动几何节点；
只有可选的原生端迹收缩诊断才另行核验这项有限节点等式。

**保存输出的精确身份。** 以保存的 reduced coefficients 为固定复数，按保存的
拓扑重建数学上的 $P_\beta$，并使用准确的 $e^{\mathrm{i}\beta d}$ 定义全系数
$P_\beta\mathbf c_h$。这保留原生 $P_2$ 场空间及自由系数，不重解特征问题，不平滑场。
本轮忽略舍入时，这就是源码约束的精确解释；若把保存的近似相位也作为精确复数，
则其边界条件未必对应准确的 $\beta$，必须先恢复上述相位或显式修正，不能静默跳过。
候选固定为 $\mu_h=k_h^2>0$，$k_h=1.5584630910866906$；定理对任意给定正实候选均成立，
不要求保存的离散特征方程在精确积分下仍成立。

**命题 1（零延拓）。** 令 $u=u_h$ 于 $B_N$，在 $B\setminus B_N$ 令 $u=0$。
则 $u\in V\setminus\{0\}$，并且 $\nabla u$ 为 $\nabla u_h$ 的零延拓。

**证明。** 对任意内部光滑测试函数，将 $B_N$ 内的弱导数恒等式与零场拼接；
左右端的值迹为零，所以分布一阶导数没有端面 Dirac 项，恰为平方可积的分片梯度。
等价地，这是 Lipschitz 域两侧迹相同的 $H^1$ 拼接引理。上下值准周期条件在
$(x_-,x_+)$ 内由假设成立，在其余 $x$ 上两侧都为零，故全条带准周期迹成立。
非零性由原场非零性保持。证毕。

通常 $u\notin D(A)$：单元边、材料贴合边和人工端的法向导数跳跃会进入分布
$\Delta u$。当前 FEM 仅施加值准周期，不能假定导数准周期。

## 3. 弱残差与所有边界项

选择任意明确给定的 $s>0$（默认可取 $s=\mu_h$），令

$$
a_s(v,w)=a(v,w)+s(v,w)_{\mathcal H},\qquad
\|v\|_s^2=a_s(v,v),\qquad
\ell(v)=a(u,v)-\mu_h(u,v)_{\mathcal H},
\qquad
\eta_s=\sup_{0\ne v\in V}\frac{|\ell(v)|}{\|v\|_s}.
\tag{6}
$$

$\ell$ 是 $V$ 上连续的共轭线性泛函，$\eta_s$ 是其对偶范数。
仅写出 (6) 还不是完成了可计算估计；第 4、7–9 节给出实际有限通量及可靠评价。

为说明缺陷构成，把 $B_N$ 按实际 FEM 单元与真实材料界面共同分割为光滑片。
若某条真实材料界面穿过同一单元，$u$ 在该界面两侧的梯度相同，其梯度跳跃为零；
系数的跳跃仍进入体残差。反之，近似材料边也是 FEM 边，其梯度跳跃必须保留。
对所有内部面只计一次，固定从片 1 指向片 2 的法向 $\nu$，记
$j=\partial_\nu u^{(1)}-\partial_\nu u^{(2)}$。分片积分分部给

$$
\begin{aligned}
\ell(v)={}&\sum_K\int_K(-\Delta u-\mu_h\rho u)\overline v
 +\sum_{E\ \mathrm{internal}}\int_E j\overline v\\
&+\int_{y\in(-d/2,d/2)}
 \left[-\partial_xu(x_-,y)\overline{v(x_-,y)}
       +\partial_xu(x_+,y)\overline{v(x_+,y)}\right]\,\mathrm{d}y\\
&+\int_{x_-}^{x_+}
 \left[\partial_yu(x,d/2)-e^{\mathrm{i}\beta d}\partial_yu(x,-d/2)\right]
 \overline{v(x,d/2)}\,\mathrm{d}x.
\end{aligned}
\tag{7}
$$

对一般正则性，边界积分解释为弱迹配对；当前正 Jacobian 的有限曲边 $P_2$ 单元
具有所需单侧光滑性。(7) 的测试函数属于无限条带 $V$，**不在人工端消失**。
因此齐次 Dirichlet 原生场的端面法向导数不能删除。值的 $H^1$ 相容性没有值跳跃项。
最后一行为单次计数的准周期导数接缝缺陷；它不是已知零。

这给出了单元体项、所有内部/材料通量项、左右端和准周期接缝的统一身份。
定理实际直接使用 (6)，不把这些分布量合并成一个虚假的 $L^2$ 强残差。

## 4. 显式通量上界与人工端的两种处理

令 $p\in H(\operatorname{div},B_N;\mathbb C^2)$，即 $p$ 与
$\operatorname{div}p$ 均平方可积；要求上下坐标法向分量满足

$$
p_y(x,d/2)=e^{\mathrm{i}\beta d}p_y(x,-d/2)
\tag{8}
$$

的弱迹条件。内部法向连续包含在 $H(\operatorname{div})$ 中。这里的 $p$ 是任意
辅助通量，不要求它等于 $\nabla u$，不要求局部平衡，也不使用有限元正交性。
设其两个人工端外法向迹 $g_-=p\cdot(-e_x)$、$g_+=p\cdot e_x$ 属于 $L^2$。
定义完全显式量

$$
\begin{aligned}
M_s(p)^2&=\|\nabla u-p\|_{L^2(B_N)}^2
 +\frac1s\|\rho^{-1/2}(\operatorname{div}p+\mu_h\rho u)\|_{L^2(B_N)}^2,\\
C_{\mathrm{end}}&=(2\sqrt{s\rho_{\min}})^{-1/2},\\
\overline\eta_s(p)&=M_s(p)+C_{\mathrm{end}}
 \bigl(\|g_-\|_{L^2}+\|g_+\|_{L^2}\bigr).
\end{aligned}
\tag{9}
$$

**定理 2（含端面的通量可靠界）。** 在第 1–2 节和 (8) 的条件下，

$$
\eta_s\leq\overline\eta_s(p).
\tag{10}
$$

若 $g_-=g_+=0$，$p$ 的零延拓属于全条带 $H(\operatorname{div})$，只需
$\eta_s\leq M_s(p)$。特别地，$p=0$ 总是可行。

**证明。** 有限域 Green 公式、内部法向单值及 (8) 给

$$
\ell(v)=\int_{B_N}(\nabla u-p)\cdot\nabla\overline v
 -\int_{B_N}(\operatorname{div}p+\mu_h\rho u)\overline v
 +\int_{x=x_-}g_-\overline v+\int_{x=x_+}g_+\overline v.
\tag{11}
$$

两项体积分的绝对值按直积空间 Cauchy–Schwarz 不等式至多为
$M_s(p)\|v\|_{s,B_N}\leq M_s(p)\|v\|_s$。
为明确端面常数，视 $v$ 为 $H^1(\mathbb R;L^2(-d/2,d/2))$ 函数。
先对 $x$ 紧支撑的光滑函数，在任意 $t\in\mathbb R$ 从左右分别积分
$\frac{\mathrm{d}}{\mathrm{d}x}\|v(x,\cdot)\|_2^2$
并取平均，得

$$
\|v(t,\cdot)\|_2^2
\leq\|v\|_{L^2(B)}\|\partial_xv\|_{L^2(B)}
\leq\frac{\|\nabla v\|_2^2+s\rho_{\min}\|v\|_2^2}
 {2\sqrt{s\rho_{\min}}}
\leq C_{\mathrm{end}}^2\|v\|_s^2.
\tag{12}
$$

由一维 Hilbert 值 Sobolev 密度与连续迹，把 (12) 延伸到全部 $v\in V$。
对 (11) 两个人工端分别用 (12)，除以 $\|v\|_s$ 并取 supremum 得 (10)。
若两端法向迹为零，零延拓的分布散度没有端面源，故全域 $H(\operatorname{div})$
资格成立。证毕。

**人工端没有被隐藏删除。** 非零 $g_\pm$ 在 (9) 中显式付费；强制 $g_\pm=0$
则相应代价进入 $\nabla u-p$ 和体平衡缺陷。$p=0$ 时梯度能量整体付费，
绝非假设原场 $\partial_xu=0$。若把破碎的 $\nabla u$ 直接当作 $p$，通常违反
内部 $H(\operatorname{div})$ 或接缝条件，不能使用 (10)。

## 5. 正定源问题和无正分母的谱距离公式

记 $U=\|u\|_{\mathcal H}>0$。由 Riesz 表示存在唯一 $e_s\in V$，使

$$
a_s(e_s,v)=\ell(v)\quad(v\in V),\qquad \|e_s\|_s=\eta_s.
\tag{13}
$$

正移位源问题的精确解为

$$
w_s=(\mu_h+s)(A+sI)^{-1}u\in D(A),\qquad
a_s(w_s,v)=(\mu_h+s)(u,v)_{\mathcal H},\qquad e_s=u-w_s.
\tag{14}
$$

所以物理源方程为 $-\Delta w_s+s\rho w_s=(\mu_h+s)\rho u$，源紧支撑于 $B_N$。
辅助源问题适定性来自 $s>0$，不需要在不定 Helmholtz 频率上知道 resolvent 稳定常数。
不必数值求解无限域的 $w_s$；(9) 直接上界其能量误差。

**定理 3（原无限算子的可计算谱距离界）。** 在第 1–2 节条件下，给定任何已确认的
$0<\underline U\leq U$ 和 $\overline\eta_s\geq\eta_s$，置

$$
\tau=\frac{\overline\eta_s}{\underline U},\qquad
R_s=\frac{\tau}{2}\left(\tau+\sqrt{\tau^2+4(\mu_h+s)}\right).
\tag{15}
$$

则

$$
\boxed{\operatorname{dist}(\mu_h,\sigma(A(\beta)))\leq R_s.}
\tag{16}
$$

不要求 $\overline\eta_s<\sqrt{s}\,\underline U$，也不要求已知附近模态数。
可取 (9) 或它的严格向上评价作为 $\overline\eta_s$。

**证明。** 令 $E$ 为 $A$ 的谱投影测度；对 Borel 集 $S\subset[0,\infty)$，
记有限正测度 $\nu_u(S)=\|E(S)u\|_{\mathcal H}^2$。其总质量为 $U^2$。
由 $u\in V=D((A+sI)^{1/2})$ 和 (14)，谱演算给

$$
\eta_s^2=\|(A+sI)^{1/2}e_s\|_{\mathcal H}^2
=\int_{[0,\infty)}\frac{(\lambda-\mu_h)^2}{\lambda+s}\,\mathrm{d}\nu_u(\lambda).
\tag{17}
$$

被积函数至多为常数乘 $1+\lambda$，所以该积分有限；这一步没有要求 $u\in D(A)$。
令 $\delta=\operatorname{dist}(\mu_h,\sigma(A))\geq0$。
对测度支撑中的 $\lambda$，$r=|\lambda-\mu_h|\geq\delta$，并且
$\lambda+s\leq\mu_h+s+r$。函数 $r\mapsto r^2/(\mu_h+s+r)$ 在 $r\geq0$ 单调递增，故

$$
\frac{(\lambda-\mu_h)^2}{\lambda+s}
\geq\frac{\delta^2}{\mu_h+s+\delta},\qquad
\eta_s^2\geq\frac{\delta^2 U^2}{\mu_h+s+\delta}.
\tag{18}
$$

于是 $\delta^2\leq\tau^2(\mu_h+s+\delta)$。求非负二次不等式的正根即得 (15)–(16)；
当 $\tau=0$ 时直接得 $\delta=0$。这使用的是一般谱测度，不是离散特征函数展开。证毕。

最近谱点在闭非空实谱上达到，故
$[\mu_h-R_s,\mu_h+R_s]\cap[0,\infty)$ 至少含一个原无限算子的谱点。
只有另证此区间与同一 $A(\beta)$ 的 Weyl–Fredholm 本质谱不相交，才能进一步说
其中存在孤立有限重特征值。有限网格 band scan、本轮 FEM 模态筛选或 main 中的猜想
均不自动完成该附加条件；基本谱距离界不受此限制。

### 与既有正移位 resolvent 公式的准确衔接

**推论 4（同形、另行推导的正分母界）。** 令 $Q_s=\overline\eta_s/\sqrt{s}$。
若 $Q_s<\underline U$，则

$$
\operatorname{dist}(\mu_h,\sigma(A))
\leq\frac{(\mu_h+s)Q_s}{\underline U-Q_s}.
\tag{19}
$$

**证明。** (13) 给 $\|e_s\|_{\mathcal H}\leq Q_s$，因而
$\|w_s\|_{\mathcal H}\geq U-Q_s\geq\underline U-Q_s>0$。
从 (14) 在 $\mathcal H$ 中计算
$ (A-\mu_h I)w_s=(\mu_h+s)e_s$。
谱定理对 $w_s\in D(A)$ 给
$\delta\|w_s\|_{\mathcal H}\leq\|(A-\mu_h I)w_s\|_{\mathcal H}$，得到 (19)。证毕。

取 $s=\mu_h$，(19) 为 $2\mu_h Q_s/(\underline U-Q_s)$；但这里
$Q_s$ 来自 FEM 弱缺陷的正定源误差，**不是**原 BIE 跳跃 $C\varepsilon_\partial$
加一个体残差。原 BIE 场、其局部质量下界和 I9.3 的
$R_{\mathrm{num}}=0.11866142633964537$ 不参与本文件任何输入。
若正分母失败，(15) 仍给有限界；这不是 candidate 错误的判据。

## 6. 精度目标及旧零通量路线的量级否定

旧版用 $p=0$、材料全域极值和多项式能量上界，得到

$$
\tau_0^2=
\frac{\overline E+\mu_h^2\rho_{\max}m_0/s}{\rho_{\min}m_0}
\geq\frac{17\mu_h^2}{s},\qquad m_0=\|u\|_{L^2}^2.
\tag{20}
$$

式 (15) 的正根满足 $R_s^2=\tau_0^2(\mu_h+s+R_s)>\tau_0^2s$，故

$$
R_s>\sqrt{17}\,\mu_h\approx10.0142\quad(s>0),\qquad
s=\mu_h\Longrightarrow
R_s\geq\frac{\mu_h}{2}(17+\sqrt{425})\approx45.6804.
\tag{21}
$$

这大于比较窗口 $[1.45^2,2.25^2]$ 的宽度 $2.96$；
实际微内缩配置窗口 $[1.451^2,2.249^2]$ 的宽度为 $2.9526$。
撤回“可能偏宽、先评价此后备再决定”的推荐：这个具体后备无需完整评价即可
排除为本轮精度方案。(21) 是**上界输出的下限，不是 FEM 实际误差的下限**。

对目标半径 $r>0$，式 (15) 单调且可准确反解：

$$
R_s\leq r
\quad\Longleftrightarrow\quad
\tau\leq\frac{r}{\sqrt{\mu_h+s+r}}.
\tag{22}
$$

默认 $s=\mu_h$，小 $\tau$ 的转换斜率为 $\sqrt{2\mu_h}\approx2.2040$；
$r=0.1$、$0.01$ 分别要求 $\tau\leq0.0449121$、$0.00453254$。
这些仅为给定候选的标量核算，没有评价原生场或保证目标可达。
后文在 $\operatorname{div}p+\mu_h\rho u$ **先相加再取范数**，保留方程抵消。

## 7. 具体有限维通量：曲边 Piola RT2

### 7.1 参考空间、十五个自由度与可生成基

取 $\widehat K=\{(\xi_1,\xi_2):\xi_1,\xi_2\geq0,\ \xi_1+\xi_2\leq1\}$，定义

$$
\widehat{\mathrm{RT}}_2=[\mathbb P_2]^2
 \mathbin{\oplus}\boldsymbol\xi\,\widetilde{\mathbb P}_2,\qquad
\dim\widehat{\mathrm{RT}}_2=12+3=15.
\tag{23}
$$

$\widetilde{\mathbb P}_2$ 为二次齐次多项式空间。
生成序列为 $1,\xi_1,\xi_2,\xi_1^2,\xi_1\xi_2,\xi_2^2$ 分别乘 $e_1,e_2$，
再加 $\boldsymbol\xi\xi_1^2,\boldsymbol\xi\xi_1\xi_2,\boldsymbol\xi\xi_2^2$。
其参考散度属于 $\mathbb P_2$，与仿射单元的原生 $P_2$ 质量阶相配；
曲边时不宣称精确多项式抵消。

参考边按逆时针参数化：
$(0,0)\to(1,0)$、$(1,0)\to(0,1)$、$(0,1)\to(0,0)$，$t\in[0,1]$。
令 $L_0=1,L_1=2t-1,L_2=6t^2-6t+1$。
每边三个外法向矩为
$\int_0^1(\widehat p\cdot\widehat n)|\widehat c'|L_m(t)\,\mathrm{d}t$，
$m=0,1,2$；内部六矩为
$\int_{\widehat K}\widehat p\cdot r\,\mathrm{d}\xi$，
$r=e_1,\xi_1e_1,\xi_2e_1,e_2,\xi_1e_2,\xi_2e_2$。
边上未归一法向为 $(0,-1),(1,1),(-1,0)$，故全部基矩阵条目为有理数。
将十五泛函作用于十五生成向量，准确求逆得到对偶基 $\widehat\psi_j$。
所需多项式矩为

$$
\int_{\widehat K}\xi_1^a\xi_2^b\,\mathrm{d}\xi
=\frac{a!\,b!}{(a+b+2)!}.
\tag{24}
$$

**引理 5（自由度单值性）。** 十五个矩全零的 RT2 向量必为零。

**证明。** 每边法向为二次多项式，三个零矩使其为零。
$\widehat{\operatorname{div}}\widehat p\in\mathbb P_2$；以该散度的共轭作分部积分测试，
其共轭梯度属于内部矩测试空间的复线性张成，得到散度模平方积分为零。
写 $\widehat p=v+\boldsymbol\xi h_2$，其中 $v\in[\mathbb P_2]^2$、
$h_2$ 二次齐次；最高次散度为 $4h_2$，所以 $h_2=0$。
无散多项式 $v$ 可逐项积分为
$v=(\partial_{\xi_2}\varphi,-\partial_{\xi_1}\varphi)$，
$\varphi\in\mathbb P_3$。零边法向使 $\varphi$ 在连通边界上为同一常数。
减去常数后，$\varphi=c\,\xi_1\xi_2(1-\xi_1-\xi_2)$。
内部矩 $\int v\cdot(0,\xi_1)=\int\varphi=0$，而 bubble 的积分严格正，
故 $c=0$。证毕。

### 7.2 曲边映射、边方向与复准周期装配

在 $K=F_K(\widehat K)$ 上记 $J_K=DF_K$、$d_K=\det J_K>0$，采用

$$
p(F_K(\xi))=\frac{J_K\widehat p}{d_K},\qquad
(\operatorname{div}p)(F_K(\xi))
=\frac{\widehat{\operatorname{div}}\widehat p}{d_K}.
\tag{25}
$$

链式法则和余子式导数相消给第二式；第一式保持有向法向通量矩。
曲边物理法向一般不是弧长的二次多项式，不得替换成未映射向量多项式。

每个全局边固定参数方向和法向 $n_E$。
上下配对边统一取参数随 $x$ 增加、$n_E=e_y$；人工端取外法向。
全局矩为 $z_{E,m}=\int_Ep\cdot n_E L_m(t)\,\mathrm{d}s$。
若单元边参数相对全局方向为 $\kappa_{K,E}\in\{1,-1\}$，
其外法向相对 $n_E$ 为 $\epsilon_{K,E}\in\{1,-1\}$，则局部矩为

$$
d_{K,E,m}=\epsilon_{K,E}\kappa_{K,E}^{\,m}z_{E,m},
\qquad
z_{\mathrm{top},m}=e^{\mathrm{i}\beta d}z_{\mathrm{bottom},m}.
\tag{26}
$$

第一式使用 $L_m(1-t)=(-1)^mL_m(t)$；法向号与参数翻转分别保存。
第二式使用同一 $e_y$，等价于 (8)；若使用各自外法向须另添负号。
内部边共用三矩。人工端三矩**自由，按 (9) 付费**，不置零。
没有顶点通量自由度，无需角点额外约束。

独立边矩与每单元六内部矩组成 $\mathbf c$。
由 (26) 构造单射装配矩阵 $C$，映到所有局部十五系数；
它仅含符号、排列及单位模相位。
法向矩单值性给所得空间 $X_h\subset H(\operatorname{div},B_N)$，
满足 (8)。全零系数可行，故约束相容；不需原 FEM 的平衡条件。

### 7.3 正定二次问题及准确矩阵

全部积分采用**真实 $\rho$**。固定 $\gamma>0$，默认
$\gamma=2C_{\mathrm{end}}^2=1/\sqrt{s\rho_{\min}}$。求

$$
\begin{aligned}
J_\gamma(p)&=\|\nabla u-p\|_2^2+
 \frac1s\|\rho^{-1/2}(\operatorname{div}p+\mu_h\rho u)\|_2^2
 +\gamma\sum_\pm\|p\cdot n\|_{x=x_\pm}^2,\\
p_h^\star&=\operatorname*{arg\,min}_{p\in X_h}J_\gamma(p),\\
\eta_s&\leq\sqrt{1+2C_{\mathrm{end}}^2/\gamma}\,\sqrt{J_\gamma(p)}
\quad(p\in X_h).
\end{aligned}
\tag{27}
$$

最后一式由 (9)、两端范数和不超过平方和的 $\sqrt2$ 倍及加权
Cauchy–Schwarz 得到。默认放大因子为 $\sqrt2$，最终仍可用更紧的 (9)。
这只是辅助通量系统，不修改 FEM 特征求解器或加入 DtN。

设 $\psi_j$ 为全局物理基，第一变量线性约定给系统

$$
\begin{aligned}
H_{ij}&=\int\psi_j\cdot\overline{\psi_i}
+\frac1s\int\rho^{-1}\operatorname{div}\psi_j\,
 \overline{\operatorname{div}\psi_i}
+\gamma\sum_\pm\int_{x=x_\pm}(\psi_j\cdot n)\overline{(\psi_i\cdot n)},\\
b_i&=\int\nabla u\cdot\overline{\psi_i}
-\frac{\mu_h}{s}\int u\,\overline{\operatorname{div}\psi_i},
\qquad H\mathbf c^\star=\mathbf b.
\end{aligned}
\tag{28}
$$

右端散度项为负，材料权重准确抵消。
局部十五基组装后使用 $C^*H_{\mathrm{loc}}C$、$C^*\mathbf b_{\mathrm{loc}}$；
必须使用**共轭转置**。
非零系数对应非零 $p$，二次项至少为 $\|p\|_2^2>0$，故 $H$ Hermitian
positive definite，最小解存在且唯一，无 gauge、均值约束或局部 Neumann 兼容缺口。
每单元六内部自由度可局部静态消元，边 Schur 补仍正定，解后回代。

最终范数先形成 $\nabla u-p$ 和 $\operatorname{div}p+\mu_h\rho u$ 再平方；
**不以巨大常数项、$\mathbf c^*H\mathbf c$ 和交叉项相减生成小残差**。

### 7.4 未精确求解与装配误差

任意有限 $\widetilde{\mathbf c}$ 都给可行通量；可靠重评 (9) 即足以用于定理 3。
若需量化求解精度，准确系统满足

$$
\mathbf r=\mathbf b-H\widetilde{\mathbf c},\qquad
J_\gamma(\widetilde p)-J_\gamma(p_h^\star)=\mathbf r^*H^{-1}\mathbf r.
\tag{29}
$$

**证明。** 最优点处线性项为零；设
$\mathbf e=\widetilde{\mathbf c}-\mathbf c^\star$，则
$\mathbf r=-H\mathbf e$，泛函差为 $\mathbf e^*H\mathbf e$。证毕。

已知 $H\succeq\alpha I$ 时，差值不超过 $\|\mathbf r\|_2^2/\alpha$。
可用完全显式下界：设参考质量 Gram 阵为 $\widehat G$，且
$d_K\in[\underline d_K,\overline d_K]$、$\|J_K\|_2\leq\overline j_K$，则

$$
\alpha=\min_K
 \frac{\underline d_K^2}{\overline j_K^2\overline d_K}
 \frac1{\|\widehat G^{-1}\|_{\mathrm F}}>0.
\tag{30}
$$

因为 $\sigma_{\min}(J_K)\geq\underline d_K/\overline j_K$，
物理质量 Gram 不低于该系数乘 $\widehat G$，而 $C^*C\succeq I$：
每个独立矩出现一次或两次，且相位模为一。
固定有理矩阵 $\widehat G^{-1}$ 可准确生成。该保守下界只用于求解误差证书，
不进入最终直接残差；可由经过核验的局部小矩阵下界替换。

若装配只给 $\widetilde H,\widetilde{\mathbf b}$，并已确认
$\|H-\widetilde H\|_2\leq\varepsilon_H$、
$\|\mathbf b-\widetilde{\mathbf b}\|_2\leq\varepsilon_b$，则

$$
\|\mathbf r\|_2\leq
\|\widetilde{\mathbf b}-\widetilde H\widetilde{\mathbf c}\|_2+
\varepsilon_b+\varepsilon_H\|\widetilde{\mathbf c}\|_2.
\tag{31}
$$

条目区间通过 Frobenius 范数可给这些误差。
若要在求解前确认近似矩阵仍正定，可先将 $\widetilde H$ Hermitian 对称化，
对该矩阵核验 $\varepsilon_H<\alpha/2$；由 (30) 得
$\widetilde H\succeq(\alpha/2)I$。这是可选的装配精度门，不是直接通量界的前提。
更直接的保障是：保留第 8 节显式 witness，可靠评价它与优化输出的实际 (9)，
选较小者。这样无论普通求积/求解如何，都不把近似系统最优性冒充真泛函最优性。

## 8. 显式有限 witness 与小量机制

### 8.1 局部插值及一次边矩平均

在每元取 $q_K=\nabla u|_K$，由已知场/几何求其散度 $\Delta u$ 和逆 Piola 像
$\widehat q_K=d_KJ_K^{-1}(q_K\circ F_K)$。它通常是有理函数。
具体地，$q_K\circ F_K=J_K^{-T}\widehat\nabla\widehat u_K$，从而

$$
(\Delta u)\circ F_K
=d_K^{-1}\widehat{\operatorname{div}}
 \bigl(d_KJ_K^{-1}J_K^{-T}\widehat\nabla\widehat u_K\bigr).
$$

用第 7.1 节十五个矩插值得 $\widehat p_K^0$，推前为 $p_K^0$。
这只是有限局部矩计算，不求未知辅助 PDE。
仿射单元上 $\nabla P_2\subset[\mathbb P_1]^2\subset\mathrm{RT2}$，
故 $p_K^0=q_K$；曲边差异另行评价。

把局部边矩变到全局方向后：

- 内部边以两侧矩的算术平均为共享矩；
- 准周期边先将上边乘 $e^{-\mathrm{i}\beta d}$ 拉回下边，取平均，
  再把上边设置为 $e^{\mathrm{i}\beta d}$ 倍；
- 人工端三矩不变，不平均成零；
- 每单元六内部矩不变。

所得 $p^w\in X_h$ 完全显式。记局部十五系数改变量为 $\boldsymbol\delta_K$，
它只有内部/准周期边分量非零。
内部边的原始矩差恰为
$\int_E(q_K-q_{K'})\cdot n_E L_m\,\mathrm{d}s$，
准周期边为拉回相位后的导数跳跃矩；修正是这些矩的正负一半再加方向变换。
材料贴合边只计在内部边集合一次。真实材料界面穿过同一单元时梯度连续，
不增加虚构跳跃，但进入真实体残差。

RT2 端法向由三个端矩唯一决定，故修正通量在人工端的法向迹**精确为零**。
人工端贡献保持为 $p_K^0$ 的原端迹，不隐藏在内部 lifting。

### 8.2 由局部 Gram 阵给出全部常数

定义物理局部基 Gram 阵

$$
(G_K^0)_{ij}=\int_K\psi_{K,j}\cdot\overline{\psi_{K,i}},\qquad
(G_K^1)_{ij}=\int_K\rho^{-1}\operatorname{div}\psi_{K,j}\,
 \overline{\operatorname{div}\psi_{K,i}}.
\tag{32}
$$

$G_K^0$ 正定，$G_K^1$ 半正定；其元素均是明确可评价的积分。
逐元计算

$$
\begin{aligned}
a_K&=\|q_K-p_K^0\|_2,&
b_K&=\|\rho^{-1/2}(\operatorname{div}p_K^0-\Delta u)\|_2,\\
r_K&=\|\rho^{-1/2}(\Delta u+\mu_h\rho u)\|_2,&
l_K^0&=(\boldsymbol\delta_K^*G_K^0\boldsymbol\delta_K)^{1/2},\\
l_K^1&=(\boldsymbol\delta_K^*G_K^1\boldsymbol\delta_K)^{1/2},&
T_{\mathrm{end}}^2&=\sum_\pm\|p^0\cdot n\|_{x=x_\pm}^2.
\end{aligned}
\tag{33}
$$

$a_K,b_K$ 为有限通量表示误差，$r_K$ 为真实系数体方程缺陷，
$l_K^0,l_K^1$ 为实际跳跃矩产生的 lifting，$T_{\mathrm{end}}$ 为局部插值通量
$p^0|_K=p_K^0$ 的人工端法向迹；它由原生场的十五局部矩确定，可直接有限评价。
不声称这些分组分别等于真正离散误差、截断误差。

**定理 6（有限 witness 控制）。** 用准确矩作第 8.1 节重构，令

$$
W^2=\sum_K(a_K+l_K^0)^2+
 \frac1s\sum_K(r_K+b_K+l_K^1)^2+\gamma T_{\mathrm{end}}^2.
\tag{34}
$$

则

$$
J_\gamma(p_h^\star)\leq J_\gamma(p^w)\leq W^2,\qquad
\eta_s\leq\sqrt{1+2C_{\mathrm{end}}^2/\gamma}\,W.
\tag{35}
$$

**证明。** 每元
$p^w=p_K^0+\sum_j\delta_{K,j}\psi_{K,j}$，
梯度差范数至多 $a_K+l_K^0$。准确恒等式

$$
\operatorname{div}p^w+\mu_h\rho u
=(\Delta u+\mu_h\rho u)
+(\operatorname{div}p_K^0-\Delta u)
+\operatorname{div}\sum_j\delta_{K,j}\psi_{K,j}
\tag{36}
$$

给散度缺陷上界 $r_K+b_K+l_K^1$，保留方程抵消。
修正不改人工端法向迹，故其平方范数和准确等于 $T_{\mathrm{end}}^2$，
得到 $J_\gamma(p^w)\leq W^2$；此步不需要端边常速参数化。
有限最小化与 (27) 得其余结论。证毕。

若需用原生 $\partial_nu$ 诊断端影响，可在每条人工端边的参数速度
$v(t)=|c'(t)|$ 上给出 $0<v_{\min}\leq v(t)\leq v_{\max}$。
三个边矩说明 $v(p_K^0\cdot n)$ 是 $v\partial_nu$ 在参数 $t$ 下到
$\mathbb P_2$ 的 $L^2(\mathrm{d}t)$ 正交投影。先用投影收缩再换权重可得

$$
\|p_K^0\cdot n\|_{L^2(E)}^2
\leq v_{\min}^{-1}\|v\partial_nu\|_{L^2(\mathrm{d}t)}^2
\leq\frac{v_{\max}}{v_{\min}}\|\partial_nu\|_{L^2(E)}^2.
$$

常速仿射且中点等式已核验时该比值为 1，恢复原生端迹的收缩估计。
基本算法使用 (33) 的直接端迹，避免为微小参数非仿射修改原生几何。

$G_K^1$ 的尺度随网格变化；仅声称“无权跳跃趋零”不足，
需核验实际 Gram 权重下的 (33)–(34)。这里不隐藏网格常数。

### 8.3 不准确矩与可核验精度条件

实际矩计算到区间精度后，选定有限代表系数，并准确执行共享边/相位关系，
所得实际 witness 仍相容。
插值与平均是已知有限线性映射，原始矩误差传播为局部系数误差界
$|\varepsilon_{K,j}|\leq e_{K,j}$。
令 $G_K^\partial$ 为人工端法向迹 Gram 阵，则

$$
E_{\mathrm{mom}}^2=
\sum_K\sum_{i,j}
\left|(G_K^0+s^{-1}G_K^1+\gamma G_K^\partial)_{ij}\right|
 e_{K,i}e_{K,j}
\tag{37}
$$

给实际通量与理想 witness 的泛函能量距离上界；
Gram 条目用可靠上包围。
由直积残差向量的三角不等式，

$$
\sqrt{J_\gamma(p^w_{\mathrm{actual}})}
\leq\sqrt{J_\gamma(p^w)}+E_{\mathrm{mom}}
\leq W+E_{\mathrm{mom}}.
\tag{38}
$$

也可用实际局部系数直接重评 (33)，但端迹必须直接评价，
不把理想插值的收缩性自动赋给近似矩。

设最终 norm enclosure 的额外膨胀至多 $E_{\mathrm{eval}}$，
并在优化通量与实际 witness 中按可靠 (9) 择小。
一个有限量可核验的充分目标是

$$
\sqrt{1+2C_{\mathrm{end}}^2/\gamma}\,(W+E_{\mathrm{mom}})
+E_{\mathrm{eval}}
\leq\underline U\,\frac{r}{\sqrt{\mu_h+s+r}}.
\tag{39}
$$

满足即保证输出 $R_s\leq r$；若它因三角不等式保守而失败，直接 (9) 仍可能通过，
失败不证明实际误差大。

这比“最终残差小则界小”多出实际构造：
$p^w$ 由原生场的十五局部矩和一次明确平均生成；
所有体残差、Piola 插值差、jump Gram 范数、端迹无需未知 PDE 即可有限评价。
仿射材料对齐单元上 $a_K=b_K=0$，只余体 PDE、边跳跃和人工端；
曲边额外差异显式保留。

对一列允许原生场、网格/界面近似及截断 $N$ 变化的数据，
若 $\underline U$ 有正下界，$\mu_h,s,\gamma$ 留在正有界区间，
且 $W/\underline U,E_{\mathrm{mom}}/\underline U,E_{\mathrm{eval}}/\underline U\to0$，
则 (15)、(35)、(38) 给 $R_s\to0$。
这是有限构造的充分条件，不是未知最优通量存在论。
**固定 $N=6$ 时只加密 FEM 网格不保证端迹项趋零；
只细化后处理通量/积分更不会改变原生场的真实缺陷。**
固定 80 段材料几何的失配也未必趋零。
端迹是 witness 上界分项，不是实际谱距离的下界。

## 9. 真几何、可终止单侧积分及误差预算

### 9.1 同一原生函数与真实材料

材料最高阶系数恒为 1；合法曲边网格在准确矩形上定义的同一个 $H^1$ 函数
可直接代入真实 $\rho$，不需把场 lift 到另一网格。
但 (27)、(28)、(32)、(33) 与 $U^2$ 必须使用真实材料；
原 $\rho_h$ 质量归一化与 $8\times8$ Duffy 结果不能代替它们。
原标签仅作诊断，准确关系为

$$
\Delta u+\mu_h\rho u
=(\Delta u+\mu_h\rho_hu)+\mu_h(\rho-\rho_h)u.
\tag{40}
$$

第二项仅支撑于真实/曲边材料区域的对称差。
分项报告时可计算
$\mu_h\|\rho^{-1/2}(\rho-\rho_h)u\|_2$；
第一个分项也须用真实 $\rho^{-1/2}$，否则须在同一对称差中另付权重失配。
主算法直接对真实 (40) 之和积分，避免全域材料区间破坏抵消。
积分精化不消除固定原生场相对于真实材料的这项缺陷。

### 9.2 有限分类与积分步骤

下述算法不要求准确求出界面交点，也不预设接口横截、无相切或不经过顶点。

1. **固定输入与正分母。** 固定实际有限系数 $u,p$，在每个闭参考单元
   给出 $d_K\geq\underline d_K>0$。
   二次几何、场、RT2 基及其导数均明确；
   用 Bernstein 系数/区间多项式给每个子片上的有理 integrand 范围。
   分母由 $\underline d_K$ 控制，指数相位及三角常数作有余项评价。

2. **给真实曲线管。** 对每条解析曲线的参数区间细分，用弦加
   $M_2\Delta t^2/8$ 的欧氏误差管包围曲线。
   此处不留未知 $M_2$：中心曲线可展开为
   $x=.3\cos t+.03\cos6t+.03\cos4t$、
   $y=.2\sin t+.03\sin6t-.03\sin4t$，
   可取 $M_2=\sqrt{1.86^2+1.76^2}$。
   对幅度 $a$ 的 lead，令 $R=.2/\sqrt{1+a^2/2}$，坐标为
   $R[\cos t+(a/2)(\cos4t+\cos2t)]$、
   $R[\sin t+(a/2)(\sin4t-\sin2t)]$，
   可取 $M_2=\sqrt2R(1+10a)$。
   负/正侧分别用 $a=.12,.20$，中心及两侧不能互换。
   三角函数端点的有限评价误差也加到管半径。

3. **分类参考子片。** 递归四分参考三角形，以二次 $F_K$ 的 Bernstein
   凸包包围子片像。若它与所有真实曲线管不相交，其连通像材料恒定；
   对一个像中点计算 winding 数确定标签。
   可利用同伦：若该点避开全部管，解析曲线到弦多边形的连续变形不穿过点，
   winding 相同；多边形 winding 由有限有向线段求得。
   无需假设多边形无自交。若某项尚无法判定，继续细分而不是猜测。
   **每个尚未分类的小片使用完整真实候选集合 $\{1,4,17\}$。**
   不能仅取相交管对应的 inclusion 材料与背景：粗中心管可能覆盖处于 lead
   内部、却不接触该 lead 界面管的小片，此时 $\{1,4\}$ 会漏掉真实材料 17。
   完整候选只用于未分类小片，不扩大到已分类区域。

4. **先保留抵消再包围。** 对已分类片，以确定的 $\rho$ 先形成
   $\nabla u-p$、$\operatorname{div}p+\mu_h\rho u$，再取模平方、乘 Jacobian。
   未分类片对 $\rho\in\{1,4,17\}$ 逐值形成同一表达式，取共同范围；
   不先用连续材料区间拆开梯度或质量项。
   非负平方量可取零下界，上界按“参考片面积乘 integrand 上界”付费。
   质量同样包围 $\rho|\widehat u|^2d_K$；
   矩阵/RHS 的实部、虚部可分别作区间积分。
   边矩是有限一维有理积分；直人工端的 RT2 法向平方积分可作一维有理包围，
   只有常速仿射参数资格成立时才简化为多项式积分。

5. **达到明确预算才停止。** 将每片 integrand range 乘参考面积并求和，
   同时细化贡献较大的参考子片和相关曲线管；达到指定正绝对误差预算停止。
   保留未分类片的非零贡献，不把积分资格等同于求积节点数量。
   可以使用带显式余项的高阶求积加速，但必须满足相同单侧预算。
   为使下面的存在性证明落实为会终止的算法，加入均匀细分后备：第 $j$ 个后备层
   将所有参考子片和所有曲线参数段至少细分至统一层级 $j$，并把三角端点、
   指数相位及其他可计算常数的有余项包围宽度至少收紧至初始宽度的 $2^{-j}$。
   每个后备层只做有限工作并重新检验预算；自适应加速不得永久推迟任何后备层。
   这避免只细分少数大项或固定常数包围精度留下不可消除的误差下限。

**命题 7（固定有限输入的积分终止性）。**
对第 2 节的合法网格、I9 有限条光滑解析界面及固定有限系数 $u,p$，
上述每项积分对任意正绝对误差容差均有一个有限细分层达到要求；
采用步骤 5 的均匀后备及同步常数精化，算法在有限步后到达这样的层并终止。

**证明。** $d_K$ 在紧参考单元上严格正，所有有限材料候选 integrand
都有有限界。真实界面是有限长度光滑曲线，面积为零；
双 Lipschitz 逆像仍为零测集。
曲线管、参考子片和常数包围同步细化时，未分类片包含于该零测集趋零的邻域，
所以“面积乘有限上界”总贡献趋零。
在这些片上保留全部三个材料候选只改变有限上界，不改变其趋零结论；
故不会重新引入全域材料极值造成的固定损失。
远离界面的闭集上材料最终固定，integrand 一致连续，
收敛的多项式/有理范围包围宽度随片径及常数包围宽度共同趋零。
避开曲线的点具有正距离，曲线管最终证实这一点，有限多边形 winding 可判定。
有限单元求和后，存在有限共同层使总宽度小于任意给定正预算。
步骤 5 在有限工作后到达每个共同层，因此不存在只知道该层存在却永不到达的调度缺口。
相切、界面经过顶点或与网格边重合只改变零测集合，不影响结论。证毕。

命题证明终止与可计算性，不保证这套直接细分在当前网格上的实际效率。
本轮未实施几何分类。真实/近似材料失配的**残差**可能不小；
它与数值积分的**不确定区间宽度**不同，后者可以由此算法压至任意正容差。

### 9.3 标量预算及验收输出

先求 $m_L\leq U^2\leq m_U$，确认 $m_L>0$，置 $\underline U=\sqrt{m_L}$。
非零场、正材料保证最终能确认正性。
原生未加权质量在参考单元是六次多项式，可用 (24) 提供正下界帮助此门，
但不把全域材料极值用于主残差。

目标 $r$ 对应
$\eta_{\mathrm{goal}}=\underline U\,r/\sqrt{\mu_h+s+r}$。
例如选择预算

$$
\sqrt{\varepsilon_{\mathrm{bulk}}}
+C_{\mathrm{end}}\bigl(\sqrt{\varepsilon_-}+\sqrt{\varepsilon_+}\bigr)
\leq0.1\,\eta_{\mathrm{goal}},
\tag{41}
$$

其中 $\varepsilon_{\mathrm{bulk}}$ 为 $M_s^2$ 的总积分区间宽度，
$\varepsilon_\pm$ 为两个端法向平方范数区间宽度。
因为 $\sqrt{x+\varepsilon}-\sqrt{x}\leq\sqrt\varepsilon$，
(41) 保证积分对最终 $\overline\eta_s$ 的附加膨胀不超过目标十分之一。
矩误差 (37) 或可选求解误差 (31) 可另分配类似预算；
份额是显式工程选择，不是隐藏常数。
如果实际缺陷已主导，盲目收紧积分或求解残差不会自动达到目标。

输出须包括固定场/网格/准确相位身份，$s,\gamma$，$[m_L,m_U]$，
实际 $M_s^2$、左右端范数的单侧区间，未分类区域积分贡献，
witness 的 (33) 分组，矩误差/求解误差记录，以及

$$
\overline\eta_s=M_{s,\mathrm{upper}}
 +C_{\mathrm{end}}(g_{-,\mathrm{upper}}+g_{+,\mathrm{upper}}),\qquad
\tau=\frac{\overline\eta_s}{\underline U},\qquad R_s\ \text{由 (15) 给出}.
\tag{42}
$$

用 (22) 判断是否达成预先目标；失败时区分体方程/真实几何、端项、有限通量表示、
lifting、积分或辅助求解所占贡献。不得将该失败称作真实特征值误差大。

## 10. 工程交接、规模及本轮边界

输入为既有代表 reduced vector、六节点坐标、单元/边拓扑、上下配对，
原解析三类 inclusion 参数和材料，以及 $k_h$；不读取 BIE 密度。
有限算法为：

1. 核验全局网格与准确矩形外边界，重建准确相位的原生场。
2. 固定 $s=\mu_h$、$\gamma=2C_{\mathrm{end}}^2$ 与目标 $r$，
   先用 (22) 明确需要的弱残差水平。
3. 一次生成参考 RT2 基与矩定义，建立 (26) 装配映射。
4. 生成显式 witness，可靠计算真实质量、原生场残差和 (33) 分组。
   此步已能交付有限非零通量界，并给优化前的具体诊断。
   人工端按实际 $p_K^0\cdot n$ 直接积分；不以常速资格失败阻断该分支。
5. 如需优化，按真实 $\rho$ 的 (28) 组装，静态消元内部六矩，
   解边 SPD 系统并回代。装配不精确时保留 (31) 或直接评价保障。
   普通装配矩阵非 SPD、求解失败或没有可用优化输出时，保留第 4 步的可行 witness，
   按 (9) 可靠重评并继续交付；优化失败不阻断该基本有限通量界。
6. 对实际优化通量与 witness 重评 (9)，以可靠上界择小；
   记录严格通量相容、积分余量与辅助求解残差。
7. 输出原无限谱距离 $R_s$ 和目标是否通过；不自动加密、扩域或重新搜索频率。

这些步骤只补通量与后处理；原 FEM 代数残差无需准确为零。
全局网格身份失败会阻断该实例；通量方向/相位错误须修正装配，不能套用 (9)。
即使当次目标失败，也保留正确界与具体诊断，不改用别的场掩盖失败。

### 规模与成本

既有记录 $T=9750$、$P_2$ 总节点数 $19837$；
源码生成上下各 156 边、两人工端各 12 边，共 336 外边。
在相容单矩形圆盘拓扑下，$3T=2E-336$ 给 $E=14793$，
Euler 关系给顶点数 $5044$，与 $5044+14793=19837$ 一致。
这是源码和记录的组合推算，**本轮未审计全部原始拓扑数组**。
识别 156 对准周期边后，

$$
n_{\mathrm{edge}}=3(14793-156)=43911,\qquad
n_{\mathrm{RT2}}=43911+6(9750)=102411
\tag{43}
$$

均为复未知数；静态消元后解 $43911$ 阶复 Hermitian SPD 系统。
人工端 24 条边的 72 复矩包含在内，未设零。
实际拓扑不符合上述资格时，必须重新按边表计数。

参考 $15\times15$ 基矩阵逆仅生成一次；witness 主要成本是局部矩、真实材料分类
和残差/Gram 积分。优化另需每单元 $15\times15$ 局部块、六内部矩消元、
稀疏边系统求解与回代。
装配工作随单元数及实际积分点数增长，每点局部矩阵为固定 $15^2$ 量级；
全局求解成本依赖排序、预条件和稀疏结构，不承诺线性复杂度或计时。
真实界面分类与单侧积分可能成为主要新增成本，应与原 FEM 特征求解分开计量。

### 完成范围

非零方案通过 (34) 给出没有 (21) 固定大量级项的充分界；
只支付方程缺陷、有限通量表示误差、实际跳跃 lifting 及人工端。
式 (39) 将小量条件连到一个已设计的有限构造。
这不预言当前 $N=6$、80 段曲边、$P_2$ 输出的分项大小。
只存在一个抽象 minimizer、矩阵残差小、端部质量小或普通求积稳定，均不够。
本轮完成的是理论与算法说明，未评价新数值、未写实验程序、未启动求解器。

## 11. 定向文献与证明记录

Chaumont-Frelet，*A posteriori error estimates for the finite element discretization of
second-order PDEs set in unbounded domains*，arXiv:2503.22297v1 (2025)，预印本；
[稳定来源](https://arxiv.org/abs/2503.22297v1)，
[[ref/ref_data/Chaumont-Frelet2025.pdf|本地 PDF]]。
已核对 §2.9、§3.1（PDF p.6）、Theorem 3.1（p.7）、
Corollary 3.2（p.8）、§3.4／Theorem 3.5（p.9）。

| 原文假设/结论 | 当前适配 |
|---|---|
| $H^1_0(\Omega)$、有限 simplicial mesh、人工边界零延拓 | 复准周期和曲边差异由命题 1、定理 2 单独处理，未直接套用 |
| 一致正且有界的 $\kappa^2$，$L^2$ 源 | (14) 取 $\kappa^2=s\rho$、源 $(\mu_h+s)\rho u$，源紧支撑 |
| Theorem 3.1 逐单元多项式散度矩平衡，保留人工端及域外源 | 本文 $p\approx\nabla u$ 对应原文 $\sigma=-p$；不需精确矩平衡，完整散度缺陷付费，保留端项 |
| Corollary 3.2 的端迹 $L^2$ 与 simplex 迹常数 | 本文直接证明 (12)，不移植直边常数 |
| §3.4 patch RT 构造依赖 Galerkin 正交性及局部兼容；Theorem 3.5 能量可靠界 | 当前真实几何/积分不等于原离散方程，未移植局部构造或效率结论；使用明确 SPD 系统与有限 witness 替代 |

原文 Proposition 3.4 证明中的反应项加号与其 (3.2)、(3.6) 不一致；
本文不依赖该步骤。RT2 单值性、相位装配及 witness 已在本文证明，
不借未核验的形状常数补缺口。

Giani，*An a posteriori error estimator for hp-adaptive continuous Galerkin methods for
photonic crystal applications*，Computing 95 (2013), 395–414，
[DOI](https://doi.org/10.1007/s00607-012-0244-6)，
[[ref/ref_data/Giani2013.pdf|本地 PDF]]。
Definition 3／(22) 在印刷 p.403（PDF p.9）给体残差与通量跳跃；
Theorems 1–2 在印刷 p.404（PDF p.10）另需离散特征值收敛到指定有限模型特征值，
含隐常数和余项。本文只借鉴构成，(7)、(33) 为当前模型重证。

没有新下载或改书目。$X_h$ 是有限通量空间，$C$ 是装配映射；
$H,\mathbf b$ 只属于辅助 SPD 系统，不是原 FEM 矩阵或连续算子。
沿用 $A(\beta),\rho,\mu_h,U,\eta_s,p$；$\Lambda$ 保留给 DtN，中心不增分支下标。

技能模式为 **Complete rewrite**（用户授权改写同一 theory.md 及支持命题），
notation-discipline 为 **Writing**。
保留命题 1、定理 2–3、推论 4 的正确核心；
撤回零通量精度推荐，新增引理 5、定理 6、命题 7及有限算法。
没有创建替代证明文件。独立审查必须针对 v2 / Revision B.1，不沿用旧 PASS。
**Proof literature verification completed.**
