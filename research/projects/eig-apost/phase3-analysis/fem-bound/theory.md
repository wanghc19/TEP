# FEM 原生场的无限波导谱距离上界

日期：2026-10-23。构造性理论首稿；独立审查以
[[research/projects/eig-apost/phase3-analysis/fem-bound/r-theory|r-theory]] 为准。
范围由 [[research/projects/eig-apost/phase3-analysis/fem-bound/p-scope|p-scope]] 冻结。
本文件给出新推导，不把文献中的源问题定理当作已有的 I9 谱距离定理。

**结论层级。** 以下定理在明确的连续与网格假设下给出可计算上界；第 7 节有不依赖
辅助求解、真实界面切割或未知常数的保守实现。尚未对 I9.3 输出评价任何新数值，
也未证明点谱存在、唯一性、估计尖锐性或新的网格认证。后几项不作为基本谱距离定理的前提。

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

定义与基础工具只用 Sobolev 迹/拼接、闭形式表示、Riesz 表示及非负自伴算子的谱定理。
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
仅写出 (6) 还不是完成了可计算估计；第 4、7 节消除其无限维 supremum。

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

## 6. 文献适配：已核实内容与本文件新桥梁

定向记录见 [[research/projects/eig-apost/implementation/i9/r-fem-lit|r-fem-lit]]；
这里只保留当前推导必要的假设映射，不复制综述。2026-10-23 从本地 PDF 重新提取并核对下列原文。

### Chaumont-Frelet (2025)

Théophile Chaumont-Frelet, *A posteriori error estimates for the finite element discretization
of second-order PDEs set in unbounded domains*, arXiv:2503.22297v1, 2025，预印本。
[稳定来源](https://arxiv.org/abs/2503.22297v1)，
[[ref/ref_data/Chaumont-Frelet2025.pdf|本地 PDF]]。
核验位置为 §2.9、§3.1（PDF p.6）、Theorem 3.1（p.7）、Corollary 3.2（p.8）、
§3.4 及 Theorem 3.5（p.9）。

按原文条件顺序对照：

| 原文条件/结论 | 本项目对应与差异 |
|---|---|
| 开集 $\Omega$ 上 $H^1_0(\Omega)$，有限 conforming simplicial mesh，离散场在人工边界取零并零延拓 | 原生场的人工端零延拓相同；上下为复准周期迹而非 Dirichlet，且网格曲边。因此不能直接引用原文定理代替证明；命题 1、定理 2 已分别证明所需拼接与接缝消去。 |
| §3.1 的 $\kappa$ 可测、一致正且有界，$f\in L^2(\Omega)$，正定反应扩散源问题 | 取 $\kappa^2=s\rho$、$f=(\mu_h+s)\rho u$，符合正性与有界性；源紧支撑，所以该源问题没有域外源项。连续形式已在 (14) 建立。 |
| Theorem 3.1：$\sigma\in H(\operatorname{div},\Omega_h)$，逐单元满足 $\operatorname{div}\sigma$ 与 $f-\kappa^2u_h$ 的多项式矩平衡；保留人工端 $(\sigma\cdot n,v)$ 和域外源项 | 对应 $\sigma=-p$，本文件不假设矩平衡；以 (9) 中完整 $s^{-1/2}\rho^{-1/2}$ 体项替代局部投影/Poincaré 估计。原文所需矩条件未为 I9.3 验证，不调用其平衡结论。 |
| Corollary 3.2 再要求人工端法向迹属于 $L^2$；以显式 simplex 迹常数估计端项 | (9) 保留相同类型端项，但 (12) 在原无限条带直接证明常数，避开把直边 simplex 常数直接移植到曲边三角形。 |
| §3.4 的局部 Raviart–Thomas 问题、Galerkin 正交性与分片常数假设用于构造平衡通量；Theorem 3.5 给源问题能量误差可靠界 | I9.3 使用近似几何和求积，不能预设对真实 $\rho$ 精确 Galerkin 正交；本文件任意相容 $p$ 均可行，所以辅助离散误差由剩余缺陷付费。未移植原文局部效率、次数稳健性或其局部构造。 |

**已核实文献结论**是上述正定源问题能量可靠估计及人工端贡献。
**本项目新推导**是加权复准周期形式的 (9)–(12)、一般谱测度反演 (15)–(18)、
以及曲边原生场的第 7 节有限评价链。没有声称这些步骤的优先权或该预印本已经覆盖 I9。
原文 Proposition 3.4 的证明中出现与 (3.2)、(3.6) 不一致的反应项加号；这里不依赖
该推导或局部平衡存在性，按本文件定义直接核验散度与符号。

### Giani (2013)

Stefano Giani, *An a posteriori error estimator for hp-adaptive continuous Galerkin methods
for photonic crystal applications*, Computing 95 (2013), 395–414。
[DOI](https://doi.org/10.1007/s00607-012-0244-6)，[[ref/ref_data/Giani2013.pdf|本地 PDF]]。
Definition 3／式 (22)，印刷 p.403（PDF p.9），把残差分为单元体项与内部边
法向通量跳跃；Theorems 1–2，印刷 p.404（PDF p.10），在离散特征值收敛到指定
模型特征值的假设下给含隐常数及高阶余项的可靠性估计。

本文件借鉴其残差构成，由 (7) 重新推导本模型的准确版本；不调用该论文的特征值
可靠性定理，因为有限矩形、对齐材料、收敛假设与未知余项未提供当前无限域的显式谱距离。
其 $A$ 是扩散系数矩阵、$B$ 是质量系数；对应本模型应取扩散矩阵为单位阵、质量为 $\rho$，
不得因论文记号把当前 $A(\beta)$ 或 $\beta$ 改作局部系数。

## 7. 曲边 P2 与完全有限的可计算评价

### 7.1 不必把近似界面当作真实界面

本模型的材料界面只改变质量系数，能量形式的最高阶系数始终为 1。
一张覆盖准确矩形的合法曲边网格定义了 $B_N$ 上的真实 $H^1$ 函数，即使它的
贴合边不是原解析材料界面。把**同一个物理函数**代入真实 $\rho$ 的 (6)、(9)
已经针对原算子，不需先构造几何 lift。几何近似影响求出的 $u_h$，但不要求它是
真实几何下的 Galerkin 特征函数。这一点不适用于未加说明的几何外边界变化或
材料依赖的扩散系数模型。

为了取得较小界，可在真材料切割区域上积分 (9) 和 $U^2$。也可令 $\rho_h$ 为
保存的单元材料标签，从它得到辅助量，同时明确保留失配。例如逐点恒等式为

$$
\operatorname{div}p+\mu_h\rho u
=\operatorname{div}p+\mu_h\rho_hu+\mu_h(\rho-\rho_h)u,
\quad
U^2=\int_{B_N}\rho_h|u|^2+\int_{B_N}(\rho-\rho_h)|u|^2.
\tag{20}
$$

由三角不等式可分别控制 (20)，但不能只将 $\rho_h$ 积分换名为真实积分。
以下更保守的完整路线只用 $\rho_{\min},\rho_{\max}$，因此不留下真实界面位置的未知误差。

### 7.2 零通量后备：只有多项式积分和 Jacobian 下界

参考三角形为 $\widehat K=\{(\xi_1,\xi_2):\xi_1,\xi_2\geq0,
\xi_1+\xi_2\leq1\}$。对每个单元，令
$J_K=DF_K$、$d_K=\det J_K$，选择已验证的常数
$0<\underline d_K\leq\min_{\widehat K}d_K$。定义

$$
\begin{aligned}
m_0&=\sum_K\int_{\widehat K}|\widehat u_K|^2d_K\,\mathrm{d}\xi
      =\|u\|_{L^2(B)}^2>0,\\
\overline E&=\sum_K\frac1{\underline d_K}
 \int_{\widehat K}|\operatorname{adj}(J_K)^{\mathsf T}
            \widehat\nabla\widehat u_K|^2\,\mathrm{d}\xi,\\
\underline U_0&=\sqrt{\rho_{\min}m_0},\qquad
\overline\eta_{s,0}=
 \sqrt{\overline E+\frac{\mu_h^2}{s}\rho_{\max}m_0}.
\end{aligned}
\tag{21}
$$

**推论 5（显式有限后备界）。** 在上述网格资格下，(21) 满足定理 3 的全部
标量条件，故以 $\tau=\overline\eta_{s,0}/\underline U_0$ 代入 (15) 得到
原无限算子的有限上界。无辅助 PDE、平衡通量、真实界面切割、未知迹常数或谱隔离输入。

**证明。** 变量变换给

$$
\int_K|\nabla u|^2
=\int_{\widehat K}
 \frac{|\operatorname{adj}(J_K)^{\mathsf T}\widehat\nabla\widehat u_K|^2}{d_K}
 \,\mathrm{d}\xi
\leq\frac1{\underline d_K}\int_{\widehat K}
 |\operatorname{adj}(J_K)^{\mathsf T}\widehat\nabla\widehat u_K|^2\,\mathrm{d}\xi.
\tag{22}
$$

因此 $\|\nabla u\|_2^2\leq\overline E$，并有
$\rho_{\min}m_0\leq U^2\leq\rho_{\max}m_0$。
取定理 2 中 $p=0$，端项为零，
$M_s(0)^2=\|\nabla u\|_2^2+\mu_h^2U^2/s\leq\overline\eta_{s,0}^2$。
非零相容场及正 Jacobian 保证 $m_0>0$，故 $\underline U_0>0$。证毕。

(21) 真正可作有限精确评价：$|\widehat u_K|^2d_K$ 为至多六次多项式，
$|\operatorname{adj}(J_K)^{\mathsf T}\widehat\nabla\widehat u_K|^2$ 为至多四次多项式；
逐单项使用

$$
\int_{\widehat K}\xi_1^a\xi_2^b\,\mathrm{d}\xi
=\frac{a!\,b!}{(a+b+2)!}\qquad(a,b\in\mathbb N_0)
\tag{23}
$$

即可评价，无求积余项。$d_K$ 为二次多项式；其最小值可由顶点、每条边的一维
驻点以及内部驻点检验，退化二次情形需保留边界/驻点集合，或以 Bernstein 细分
给正下界。后一方法在严格正的紧参考三角形上经过有限足够细分必能给正证书。
相位的指数是明确可计算常数；精确算术可符号保留，实际评价则控制它和平方根的单侧误差。
本轮只证明该算法链，没有对 9750 单元执行它。

这条后备界可能很宽，尤其 $\rho_{\max}/\rho_{\min}=17$ 及不平衡梯度项会放大它；
但它已闭合可计算性，不能把“不尖锐”改称理论 blocker。

### 7.3 非零通量、求积与辅助离散

为缩小 $M_s$，可在原网格上以 contravariant Piola 映射构造相容通量：

$$
p(F_K(\xi))=\frac{J_K(\xi)\widehat p_K(\xi)}{d_K(\xi)},\qquad
(\operatorname{div}p)(F_K(\xi))
=\frac{\widehat{\operatorname{div}}\widehat p_K(\xi)}{d_K(\xi)}.
\tag{24}
$$

须用一致的边方向保证内部法向连续，以相位配对上下法向自由度；人工端可保留
$g_\pm$ 并用 (9)，也可强制为零。局部或全局最小二乘只用于选取有限系数，
不要求辅助求解达到无限维精确最优；最终实际 $p$ 的 (9) 才是验收量。
因此辅助离散、未完全平衡和代数残差不会被当作零，而是留在两项缺陷中。

若直接使用真实材料，则 (24) 后的被积函数是每个真实材料切割片上的显式有理函数；
分母有 $\underline d_K>0$，可使用解析积分、带误差界的求积或有界区间细分。
若不做真实切割，仍可把每个积分点的材料值保守包围在 $[1,17]$，或分别对
$\{1,4,17\}$ 的候选表达式取上界，再积分上包络。这会保守，但不遗漏几何误差。
对曲线分类未定的小片采用 $[1,17]$ 保守包围，也允许直接终止并保留其非零宽度。

原 I9.3 的 $8\times8$ Duffy 规则没有为真实材料切割或有理刚度/通量积分提供自动误差界。
用它重新得到一个普通数值不是定理 3 所需的单侧输入。最低限度评价链 (21)–(23)
特意避免该依赖；更尖锐实现必须报告每个积分的上/下界和未分辨几何小片贡献。

### 7.4 输入清单与最小实现交接

| 量或资格 | 当前输出直接提供 | 还需的理论一致处理 |
|---|---|---|
| $k_h$、reduced coefficients、节点/单元拓扑、材料标签 | `run-02/evidence.mat`；`LOCAL_export` 保存同源 raw 数据 | 冻结指定代表模式，按 $P_\beta$ 精确解释准周期关系；不换用 BIE 向量 |
| $F_K,\widehat u_K,J_K,d_K$ | 六节点坐标、`triangle_p2`、约束和全系数足够重建 | 逐单元双 Lipschitz、公共边一致、全局覆盖/无重叠以及准确外边界资格 |
| $\rho_{\min}=1,\rho_{\max}=17,s>0$ | 模型配置，$s=\mu_h$ 可固定 | 不需要新的拟合或真实特征值 |
| $m_0,\overline E,\underline U_0,\overline\eta_{s,0}$ | 原始数据足够，现成标量尚未保存 | 按 (21)–(23) 精确多项式积分及 $\underline d_K$；已保存质量归一化不能替代真实质量下界 |
| 较小的 $\overline\eta_s$ | 当前无相容通量输出 | 构造 (24) 的有限通量，核验法向/相位约束并可靠评价 (9) |
| 真实 $U$ 或较小质量下界 | 当前材料标签和矩阵属于近似界面 | 真系数切割积分、(20) 失配界，或始终保留 (21) 的保守下界 |
| 点谱存在/模态身份 | 有限域筛选不提供 | 另证包含区间不交本质谱；不纳入本轮最低实现任务 |

最小下一步只是在获准实现后读取既有输出，构造精确相位的原生场并验证有限网格资格，
评价 (21)–(23) 与 (15)。此步骤不需要重跑 FEM、不需要扩大截断、不需要模态追踪。
只有需要缩小已经成立的界时，再构造有限通量；本轮不写该实现、不运行实验。

## 8. 证明状态、自检与审查接口

本文件由 Researcher 起草，独立结论只由
[[research/projects/eig-apost/phase3-analysis/fem-bound/r-theory|r-theory]] 给出。
问题账目统一由项目维护者登记，本节只说明论证的可降级点。

| 编号 | 主张与当前构造性状态 | 最弱环节/失败时的最小降级 |
|---|---|---|
| C1 | `ESTABLISHED`：(1)–(5) 与相容输入下，零延拓属于形式域 | 若全局网格或准确相位不成立，对该原始数据的应用为 `BLOCKED`；抽象定理不受影响 |
| C2 | `ESTABLISHED`：(9)–(12) 给显式弱残差上界，含人工端 | 若选取的 $p$ 不满足法向连续/接缝条件，舍弃该 $p$，退回 $p=0$ |
| C3 | `ESTABLISHED`：(15)–(18) 给原无限算子全谱距离上界 | 若单侧输入未评价，仍是已证算法定理，不能宣布已得到该 candidate 的数值上界 |
| C4 | `ESTABLISHED`：(21)–(23) 提供有限可计算后备，不遗留真实界面未知项 | 网格资格与相位是输入条件；宽界只影响实用性，未实现不推翻定理 |
| C5 | `CONDITIONAL`：当前 I9.3 保存场可按上述流程实例化 | 既有数值审计不代替本轮未执行的精确网格/积分评价；不宣称已经完成数值证书 |
| C6 | `CONDITIONAL`：区间中的谱点为点谱 | 另需排除本质谱；失败时仅保留全谱距离结论 |

已进行的符号/逻辑自检：$\rho$ 只加权质量；原生场不需强定义域；$s>0$；左右人工端和
上下导数接缝不删除；谱定理不要求离散基；候选与辅助通量缩放一致；零通量给有限后备；
未把近似材料矩阵当作真实系数积分。自检不替代独立审查。

技能记录：`rigorous-proof` 模式为 **Proof from scratch**，新文件的命题 1、定理 2–3、
推论 4–5 及相应“证明”段均在本次授权范围；`notation-discipline` 为 **Writing**。
新增 $s,\eta_s,p,e_s,w_s,\underline U,\tau,R_s$ 分别承担正移位、弱缺陷范数、辅助通量、
源误差/解、可靠质量下界及最终标量转换的角色；$\rho_{\min},\rho_{\max}$ 避免与左右
lead 下标混淆。$\Lambda$ 保留给 DtN，不用作求和集合；中心 inclusion 没有额外分支下标。

文献状态：**Proof literature verification completed.** 本文件依赖的谱与形式步骤已在
正文连接，CF 和 Giani 仅作经核对的适配/构成来源，不作为未证明桥梁。没有新下载或
修改书目；临时重提取位于 `tmp/fem-bound/`。未启动 MATLAB、FEM/BIE/FMM、实验脚本，
未修改 main、源码、已有输出或独立审查文件。
