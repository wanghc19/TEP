# 真实周期胞元的有限 Fourier 谱隙见证

2026-10-30；证明模式：Proof from scratch。目标是当前两种真实三叶形周期端、$\beta=1/2$ 的共同谱隙 $[a,b]=[12/5,123/50]$。本文把 [[research/explorations/interface-threshold/spectral_certification_alternatives#7. 本质谱 gap：一个独立而完全有限的充分判据|A3]] 写成可直接评价的有限合同，不声称 Schur 补原理的新颖性。当前结果与未闭合项见 [[research/explorations/spectral-counting/STATUS]]；对应代码位于 `test/spectral-counting/gap-v1/`。

## 1. 固定模型与完整算子

单位胞元取二维环面 $\mathbb T^2=(-1/2,1/2)^2$。真实 inclusion 为极坐标域 $0\le r<r_\alpha(t)$，其中

$$
r_\alpha(t)=r_0(1+\alpha\cos3t),\qquad
r_0=\frac1{5\sqrt{1+\alpha^2/2}},\qquad
\alpha\in\{3/25,1/5\},\qquad
\rho_\alpha=1+16\mathbf1_{D_\alpha}.
$$

它完全位于单位胞元内部，面积为 $\pi/25$，向两方向周期延拓。左右端分别使用上述两个参数，不反射或平均。胞元中心的平移只使 Fourier 矩阵酉合同；当前实现固定中心为原点。这里证明的是这些精确有理输入定义的预定解析模型；旧 MATLAB 常量和中间几何系数的二进制舍入没有被当作同一份精确几何数据，也没有宣称本证书界住旧场的全部几何误差。

在 $\mathcal H_\alpha=L^2(\mathbb T^2,\rho_\alpha)$ 上，对每个实 $\theta\in[-\pi,\pi]$，由闭形式

$$
\mathfrak a_\theta[u,v]=\int_{\mathbb T^2}
(-\mathrm i\nabla+(\theta,\beta))u\cdot
\overline{(-\mathrm i\nabla+(\theta,\beta))v},
\qquad D(\mathfrak a_\theta)=H^1_{\rm per}(\mathbb T^2)
$$

定义非负自伴算子 $A_\alpha(\theta)$。由于权重实正有界且主部常系数，其定义域为 $H^2_{\rm per}$，作用为 $\rho_\alpha^{-1}K_\theta$，其中
$K_\theta=(-\mathrm i\partial_x+\theta)^2+(-\mathrm i\partial_y+\beta)^2$。紧嵌入给离散谱，按重数排列为 $\lambda_j(\theta)$。以下在未加权 $L^2$ 中评价自伴 pencil $K_\theta-\lambda\rho_\alpha$；它的零点和负方向数分别对应 $A_\alpha(\theta)$ 的谱及阈下本征值数。这里没有对跳变密度求导，也没有变更为散度型主部。

## 2. 有限块与全部遗漏方向

取正交 Fourier 基 $e_{nm}=\exp(2\pi\mathrm i(nx+my))$，$P_N$ 投影到 $|n|,|m|\le N$，$Q_N=I-P_N$。令 $R_N=P_N\rho_\alpha P_N$，其矩阵元为 $\widehat\rho_{n-n',m-m'}$，并令

$$
B_\theta(\lambda)=\operatorname{diag}\big((2\pi n+\theta)^2+(2\pi m+\beta)^2\big)-\lambda R_N.
$$

对任意 $\theta\in[-\pi,\pi]$，遗漏动能具有显式下界

$$
\tau_N=\min\{((2N+1)\pi)^2+\beta^2,\ (2\pi(N+1)-\beta)^2\}.
\tag{F1}
$$

第一项用于 $|n|\ge N+1$，第二项用于 $|m|\ge N+1$；另一坐标动能分别用 $\beta^2$ 和 0 下界。因 $\rho_\alpha-9$ 的乘法范数为 8，且 $P_NQ_N=0$，有

$$
\|P_N\rho_\alpha Q_N\|\le8.
\tag{F2}
$$

可选收紧为 $\|P_N\rho Q_N\|^2=\|18R_N-17I-R_N^2\|$，因为 $\rho^2=18\rho-17$；本轮基线采用 (F2)，不依赖数值拟合的 Fourier 尾。

**命题 F1（两有限符号数的胞元证书）。** 给定 $0<a_*<b_*$，令

$$
h=\tau_N-17b_*>0,\qquad \delta=64b_*^2/h.
\tag{F3}
$$

固定某个 $\theta_0$。若两个有限 Hermitian 矩阵 $B_{\theta_0}(a_*)$ 和 $B_{\theta_0}(b_*)-\delta I$ 都非奇异，且负惯性均为同一整数 $\ell$，则

$$
\sigma(A_\alpha(\theta_0))\cap[a_*,b_*]=\varnothing,
\qquad \#\{\lambda_j(\theta_0)<a_*\}=\ell.
\tag{F4}
$$

**Proof.** 在 $P_N\oplus Q_N$ 分块，尾块 $D=Q_N(K_{\theta_0}-\lambda\rho)Q_N\ge hI$，定义域为 $Q_NH^2_{\rm per}$。交叉块范数不超过 $8b_*$，故精确 Schur 补 $S$ 满足

$$
B_{\theta_0}(b_*)-\delta I
\le B_{\theta_0}(\lambda)-\delta I
\le S\le B_{\theta_0}(\lambda)\le B_{\theta_0}(a_*).
$$

有限维 min–max 于是使 $S$ 的前 $\ell$ 个特征值严格负，其余严格正，且端点也无零特征值。完成平方
$q[x+y]=\langle Sx,x\rangle+\|D^{1/2}(y+D^{-1}C^*x)\|^2$
的三角变换保持形式域，因为 $D^{-1}C^*x\in Q_NH^2_{\rm per}$。完整 pencil 可逆且负惯性为 $\ell$。加权紧胞元问题的变分原理把该惯性等同于阈下本征值数，得到 (F4)。证毕。

## 3. 从节点到完整 Floquet 区间

**命题 F2（与截断阶无关的覆盖）。** 对所有 $j$ 和实 $\theta,\theta_0$，

$$
|\sqrt{\lambda_j(\theta)}-\sqrt{\lambda_j(\theta_0)}|
\le|\theta-\theta_0|,
\tag{F5}
$$

这里使用 $\rho\ge1$。若子区间中心为 $\theta_0$、半径不超过 $r<\sqrt a$，在该中心以 F1 排除扩张区间

$$
a_*=(\sqrt a-r)^2,\qquad b_*=(\sqrt b+r)^2,
\tag{F6}
$$

即可排除该整个子区间上的原目标 $[a,b]$。有限个闭子区间覆盖 $[-\pi,\pi]$，左右端分别通过，即得共同 projected gap。

**Proof.** 对任意非零周期 $u$，梯度三角不等式给
$|\sqrt{\mathfrak a_\theta[u,u]}-\sqrt{\mathfrak a_{\theta_0}[u,u]}|\le|\theta-\theta_0|\|u\|_{L^2}\le|\theta-\theta_0|\|u\|_{\mathcal H_\alpha}$。
在每个 $j$ 维子空间对单位向量取上确界，再对所有该类子空间取下确界，交换参数，得到 (F5)。若某 $\lambda_j(\theta)\in[a,b]$，则其同索引节点值由 (F5) 属于 (F6)，矛盾。此论证允许带交叉、重数及不同节点采用不同编号；不假设带边在对称点，也不以有限采样代替覆盖。证毕。

实现若只取得 $a_-$ 不大于 (F6) 的左端和 $b_+$ 不小于右端，则排除更大区间 $[a_-,b_+]$ 仍有效。必须保持 $a_->0$，并用 $b_+$ 计算 (F3)。节点位置本身也使用可靠的 $\pi$ 包围。

## 4. 真实材料 Fourier 矩的可靠评价

记 $x(t)=r_\alpha(t)\cos t$、$y(t)=r_\alpha(t)\sin t$。零 Fourier 系数精确为 $\widehat\chi_{00}=\pi/25$。对整数 $(p,q)\ne(0,0)$，选择绝对值较大的非零坐标分量。若选 $p$，Green 公式给

$$
\widehat\chi_{pq}=\int_0^{2\pi}
\frac{\mathrm i\,y'(t)}{2\pi p}
\exp[-2\pi\mathrm i(px(t)+qy(t))],\mathrm dt.
\tag{F7}
$$

若选 $q$，将前因子换成 $-\mathrm i x'(t)/(2\pi q)$。这是对真实解析曲线的恒等式，无几何近似；$\widehat\rho_{pq}=\mathbf1_{(p,q)=0}+16\widehat\chi_{pq}$。

对复条带 $|\operatorname{Im}t|\le s$，三角积化和差给

$$
H_s=r_0[\sinh s+\tfrac\alpha2(\sinh4s+\sinh2s)],\qquad
J_s=r_0[\cosh s+\alpha(2\cosh4s+\cosh2s)].
$$

于是 $|\operatorname{Im}x|,|\operatorname{Im}y|\le H_s$，$|x'|,|y'|\le J_s$，(F7) 被积函数绝对值不超过

$$
M_{pq}(s)=\frac{J_s}{2\pi\max(|p|,|q|)}
\exp[2\pi(|p|+|q|)H_s].
$$

**命题 F3（显式真实曲线求积余项）。** 对 $J$ 个等距节点的周期梯形积分 $T_J$，

$$
|\widehat\chi_{pq}-T_J|\le
\frac{4\pi M_{pq}(s)}{\exp(Js)-1}.
\tag{F8}
$$

**Proof.** 整个被积函数为周期整函数。将 Fourier 系数积分路径移至上／下边界，得第 $k$ 系数绝对值不超过 $M_{pq}(s)e^{-|k|s}$。梯形平均仅保留频率为 $J$ 整倍数的系数；几何级数求和给 $2\pi\sum_{m\ne0}M_{pq}(s)e^{-|m|Js}$，即 (F8)。三角表达式直接给上述 $H_s,J_s$，无经验导数估计。证毕。

可以用 $y\mapsto-y$ 对称性得 $\widehat\chi_{p,-q}=\widehat\chi_{pq}$，再用实密度得 $\widehat\chi_{-p,q}=\overline{\widehat\chi_{pq}}$。这只节省真实材料积分，不减少 Floquet 参数覆盖范围。

## 5. 有限矩阵符号的可靠算术

矩阵装配和 (F1)–(F8) 用外向球算术，输出包含真实数的区间。普通数值特征向量矩阵 $U$ 只提供可选变换，不承载可靠性。将其二进制浮点数当作精确 dyadic 数据，用球算术计算 $H=U^*BU$，其中 $B$ 为待判定 Hermitian 真矩阵的包围。

**命题 F4（可审查的惯性判据）。** 若逐行可靠证明

$$
|H_{ii}|>\sum_{j\ne i}|H_{ij}|,
\qquad H_{ii}\ne0,
\tag{F9}
$$

则 $U$ 可逆，$B$ 的负惯性恰为负对角元个数。

**Proof.** 将 $H=D+E$，其中 $D$ 为实对角。由 (F9)，$D+tE$ 在所有 $0\le t\le1$ 均严格行对角占优，故非奇异（若有核向量，取最大模分量所在行即矛盾）。该路径 Hermitian，惯性由连续性不变。特别地 $H$ 非奇异，因而方阵 $U$ 必可逆；合同保持惯性，所以 $B,H,D$ 负惯性相同。证毕。

若 $U$ 的列只近似正交，证明仍成立；无需将普通本征分解残差当作严格误差界。球区间中的对角虚部必须包含零，真实 Hermitian 性由数学装配保证；使用真实对角的实部区间判号。任何未决行都返回失败，不调阈值强行通过。

## 6. 独立的材料矩与有限符号复核

为避免两个程序仅重复同一梯形积分，另用极坐标面积积分的有限 Taylor 展开。设 $z=\exp(\mathrm it)$，$\operatorname{CT}$ 表示 Laurent 多项式常数项，

$$
H(z)=\tfrac12(p-\mathrm iq)z+\tfrac12(p+\mathrm iq)z^{-1},\qquad
G(z)=1+\tfrac\alpha2(z^3+z^{-3}).
$$

**命题 F5（独立的面积矩包围）。** 对任意非负整数 $J$，令 $R=r_0(1+\alpha)$、$Z=2\pi\sqrt{p^2+q^2}R$，则

$$
\widehat\chi_{pq}=
2\pi\sum_{j=0}^J
\frac{(-2\pi\mathrm i)^j r_0^{j+2}}{j!(j+2)}
\operatorname{CT}(H^jG^{j+2})+e_J,
\qquad |e_J|\le\frac\pi{25}\frac{Z^{J+1}}{(J+1)!}.
\tag{F10}
$$

**Proof.** 在极坐标面积积分中，对 $\exp[-2\pi\mathrm i s(p\cos t+q\sin t)]$ 展开至 $J$ 次。实相位上的 Taylor 积分余项绝对值不超过 $Z^{J+1}/(J+1)!$，因为沿实线的指数模为 1；乘真实面积 $\pi/25$ 得误差。有限项的径向积分给 $r(t)^{j+2}/(j+2)$，角向积分为 $2\pi$ 倍 Laurent 常数项，得到 (F10)。证毕。

该复核同时用无选主元的球算术 $LDL^*$ 消元代替 F4：若每个计算枢轴的可靠实区间都排除零，则每步精确消元都有定义，单位下三角合同把真实 Hermitian 矩阵化成这些真实实枢轴的对角阵。故负枢轴数给真实惯性；任何枢轴含零即判未决。此检查不读取或复用普通特征向量，也不将浮点 LDL 作为证书。两种积分和两种惯性算法独立，但共享当前真实模型与 Arb 算术后端，不能称为两个软件后端的独立证明。

## 7. 对原缺陷算子的本质谱结论

**命题 F6（周期端谱隙排除缺陷本质谱）。** 设原条带的密度实正有界，在有限中心之外分别精确等于本文左右周期密度。若 F1–F2 的有限见证覆盖两侧和完整 Floquet 区间，则原自伴缺陷算子 $A=-\rho^{-1}\Delta$ 满足

$$
\sigma_{\rm ess}(A)\cap[a,b]=\varnothing.
\tag{F11}
$$

**Proof.** 固定 $\mu\in[a,b]$。在未加权条带空间中写
$F_\mu=-\Delta-\mu\rho:H^2_\beta\to L^2$。
两侧周期 pencil 的 Floquet 胞元族在每个实参数可逆；在固定周期 gauge 定义域上随参数连续，参数空间紧，故其逆一致有界。椭圆估计再给全周期端逆 $G_\pm:L^2\to H^2_\beta$。

取实光滑 cutoffs $\chi_-,\chi_0,\chi_+$，满足平方和为 1，中心项紧支撑，左右尾项支撑处材料分别恰为其周期模板。取 $G_0=(-\Delta+c)^{-1}$，$c>0$，并令

$$
G=\chi_-G_-\chi_-+\chi_0G_0\chi_0+\chi_+G_+\chi_+.
$$

直接交换常系数主部与 cutoffs，得到 $F_\mu G=I+K_1$、$GF_\mu=I+K_2$。余项仅含紧支撑一阶交换子和中心紧支撑零阶材料差：局部 $H^2\hookrightarrow H^1$ 紧嵌入使前者紧，局部 $H^2\hookrightarrow L^2$ 紧嵌入及有界密度使后者紧，分别作用在 $L^2$ 与 $H^2_\beta$。故 $F_\mu$ Fredholm。乘法 $f\mapsto\rho^{-1}f$ 是输出空间到 $L^2(\rho)$ 的有界同构，且 $H^2$ 范数与 $A$ 的图范数等价，因而 $A-\mu$ 也 Fredholm。自伴算子的本质谱恰为非 Fredholm 参数集，得到 (F11)。证明没有对不连续密度求导。证毕。

这只排除本质谱。区间中仍可没有导模、存在多个导模，或存在半条带 Dirichlet 表面态；本命题不给出它们的数目或排除结论。证明桥梁采用 [[research/planning/review-3h-20261030#6. bulk gap 到原无限算子：可直接补入的证明桥梁|独立复核建议]]，仅证明本任务所需方向。

## 8. 证据范围与证明报告

新增手工编号 F1–F6 的 Proof 块位于 §§2–7，及所需模型、公式与算法说明；没有修改既有证明。只使用 Fourier 完备性、紧嵌入、谱变分原理、自伴 Fredholm 判据及有限维惯性等标准基础，并写明本问题的连接步骤；专门的 Schur、参数覆盖、求积及符号判据均在本文直接证明。无书籍页码或待下载文献作为本证明的未闭合前提；不以此宣称领域原创性。

证明结论本身不证明程序已执行全部可靠步骤。只有真实材料矩、全部参数子区间、两侧有限符号与无限尾都通过，才能报告本任务目标谱隙。该谱隙仍不排除半条带 Dirichlet 表面态，不证明中心导模存在、计数或简单性，也不把 I9/I10 半径提升为可靠上界。

软件实现的外向包围依赖 python-flint/Arb 的公开算术合同；实际版本、命令、预算、错误和运行结果见 [[test/spectral-counting/gap-v1/README]]。API 参考：[arb](https://python-flint.readthedocs.io/en/latest/arb.html)、[acb](https://python-flint.readthedocs.io/en/latest/acb.html)、[acb_mat](https://python-flint.readthedocs.io/en/latest/acb_mat.html)，访问 2026-10-30。2026-10-30 的 `certify-02.json` 已逐侧、逐格通过，`audit-02.json` 已独立重建矩并通过全部枢轴；独立人工审查的最终范围与状态以 [[research/planning/review-3h-20261030]] 为准。

**来源精确定位。** Trefethen–Weideman (2014), Theorem 3.2、式 (3.16)，印刷 p.396／PDF 第12页，给出周期条带解析函数的 $4\pi M/(e^{sJ}-1)$ 梯形误差；本题 (F7) 是周期整函数，$H_s,J_s$ 核对了该定理所需一致界。[作者公开全文](https://people.maths.ox.ac.uk/trefethen/sirev56-3_385.pdf) 已于 2026-10-30 保存为 `ref/ref_data/Trefethen2014.pdf`。Herbst–Levitt–Cancès (2020), §V、式 (7)–(8)，PDF 第5页，讨论有限／无限块及壳层估计；其赝势假设不作为本文跳变密度判据的输入。[arXiv v2](https://arxiv.org/pdf/2004.13549v2) 同日保存为 `ref/ref_data/Herbst2020.pdf`。书目见 [[ref/README]]；F1–F6 的专门连接步骤已在本文直接证明，没有借来源标题代替适用条件。

**Completion report.** Task mode: `Proof from scratch`。Source/target: 本文件 §§1–7。Output: 新增 F1–F6 及局部公式 (F1)–(F11)，没有改写旧证明、LaTeX 环境或编号。Authorized outside-proof changes: 独立新实验、研究入口、文献目录和本轮报告。Original-text integrity: 既有理论原文保留。Verified references/downloads: 上述两份公开全文及指定结果。Remaining proof inputs: G1 实例有限输入现已输出；G2、C1 不属于 F1–F6 结论，仍见唯一账目。Proof status: 自足推导与可靠计算完成；人工复核范围单独记录，不把软件后端当作形式验证内核。
