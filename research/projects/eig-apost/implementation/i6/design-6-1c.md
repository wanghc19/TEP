# I6.1c：非 Fourier 跳跃范数与谱距离的认证

## 范围、时间和所有权

任务起点 2026-09-20 07:48:21 UTC，绝对截止 10:48:21 UTC；最迟 10:33:21 进入收尾。
单次完整计算共享 2700 秒及 3000000000 bytes 进程树 RSS 硬限，无宽限。
迁移、阅读、实现、debug、等待和审查全部计入总时钟。

本轮已核对 `codex/epost`，开始时只有 `test/i6/resolvent-nonfourier-v1/` 未跟踪。
它已迁为 `test/i6/resolvent-v2/`，41 个原文件逐字节保留；设计/审查/符号文件移至本目录。
已跟踪的 `test/i6/resolvent-v1/` 保持原状。v2 当前文档更新链接，但计算源码、历史日志、
原始结果和源码快照不改。新完整认证实现独占 `test/i6/resolvent-v3/`，不以旧 summary
或结果 MAT 作为科学输入。main、i5、公共 package 和既有 phase3 理论均只读。

Researcher 只读构造认证依据；Engineer 拥有 v3 源码、输入和运行产物；Skeptic 独立只读
审查形成的论证、代码和产物；主 agent 统一写本目录及迁移后的 v2 当前文档。
本文件为 rigorous-proof **Proof from scratch**、notation-discipline **Writing**；
新增命题 C1--C7 的目标位置是下述同名小节。旧理论不修订。

权威为 [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace|T9--T10]]、
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework|F14]]、
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/p-numerics|N1--N9]]，
以及本目录 [design-6-1b.md](design-6-1b.md) 的 NF1--NF6。
本轮只认证全谱距离，不认证此前 BIE/candidate 搜索、谱带隙或离散特征值编号。

## C1：同一精确输入对象

每个冻结 MAT double 的实部和虚部分别解释为其存储比特代表的精确二进有理数。
原存储为整数类的字段保持其精确整数意义，仅在逐元素整数往返完全相等时无损转为
binary64 传输，且验证数值绝对值不超过 $2^{53}$；manifest 保留原 `stored_class`。
不接纳一般有损转换。该范围门排除整数饱和转换造成的虚假往返相等。
包括物理参数、有限 density 样本、$G_\pm,P_\pm,c_\pm,q_{\mathrm{center}}$ 及有限墙源映射。
不把十进制打印近似反推成另一个模型参数。例如

$$
\widehat k=\frac{2063515897770803}{1125899906842624},\quad
R=\frac{3602879701896397}{18014398509481984},\quad
h=\frac{5764607523034235}{144115188075855872}.
$$

后两数打印为 0.2、0.04，但本次不替换为 $1/5,1/25$；$\beta=1/2,d=L=1,\rho_e=1,
\rho_{\mathrm{disk}}=17$ 本来就可精确表示。此选择严格绑定冻结输入文件；不是对一族
未知模型参数的敏感度认证。参数 strip 宽等新增算法控制值应单独声明其精确含义。

谱参数定义为实数乘积

$$
\mu:=\widehat k^2=
\frac{4258097860352843097504719264809}{1267650600228229401496703205376}.
\tag{C1}
$$

存储字段 `mu_h` 仅用于身份与偏差诊断，其精确值与 (C1) 之差为
$-245781849136169/2^{100}$，约 $-1.9388769199645244\times10^{-16}$。
`fl(khat*khat)==mu_h` 不证明实数相等；C、墙尾、Rayleigh 波数及 F14 不能混用二者。
数学 raw 场一直由冻结有限 density 作用于完整精确核及有限 Rayleigh 和定义。
所有波数据同一个 (C1) 构造，所以逐片 PDE 及准周期条件精确，体内和 seam 缺陷为零。
不引入 lift，也不重新求解 BIE 或辅助预解式场。

**精确输入传递证明。** 每个有限 binary64 都可写为整数乘 $2$ 的整数幂；在 $2^{53}$ 范围内通过原整数类往返检验的整数转换也精确。将其位型或
无损二进数据传至球算术，以此二进有理数作 singleton，即得到原数而非其十进制近似。
复数按实虚部传递。冻结 $\eta_r$ 定义有限三角插值系数

$$
\eta_m=\frac1{256}\sum_{r=0}^{255}\eta_r
\exp(-2\pi\mathrm i mr/256),\qquad m=-128,\ldots,127.
\tag{C2}
$$

以可靠球算术评价根单位和得到包含这些数学系数的球；FFT 只能作为已验证 DFT 的
实现，普通 MATLAB FFT 数值不能直接视为 exact 系数。之后有限线性组合、矩阵乘法
均在这些球内完成，因此分子分母针对同一精确 raw 场。证毕。

## C2：算术与特殊函数合同

本轮选用本地隔离安装的 python-flint/Arb 球算术。基本运算、根号、指数、对数、
三角函数、$\operatorname{erfc}$、$E_1$ 和所需整函数都须返回含精确值的球；
$\pi$、Euler 常数取库常数，阶乘取精确整数，不使用旧双精度 Euler 字面或 `gammaln`
去近似整数阶乘。全部比较门必须证明整个区间有要求的符号，而非检查 midpoint。
库和硬件依其公布合同可信；本轮不声称形式化验证整个球算术库。

官方 [包含性与精确输入合同](https://python-flint.readthedocs.io/en/latest/general.html#inexact-numbers-and-numerical-evaluation)
明确实/复数及矩阵运算返回可靠误差球。已核对官方 [arb 类型与端点接口](https://python-flint.readthedocs.io/en/latest/arb.html)：
二元整数元组表示精确二进浮点，`abs_upper`/`abs_lower` 返回定向端点。
已核对 [acb 特殊函数接口](https://python-flint.readthedocs.io/en/latest/acb.html)：
`erfc` 是互补误差函数，`z.expint(1)` 是 $E_1(z)$，不能误用 $\operatorname{Ei}$。
这些是软件接口合同，无定理编号，不引用不存在的编号。

**包含性证明。** 输入 singleton 包含真值；每个已验证算术原语将输入集合映到包含
其像的输出球，因此有限程序按操作顺序归纳保持包含性。求模、平方、累加亦然。
若中心球 $\mathbb C_r$ 包含 retained 的有符号值，且连续截断半径为 $r_r\ge0$，则
真实值满足 $|f(t_r)|\le\sup|\mathbb C_r|+r_r$。先在球内有符号合并各物理贡献再取模，
自然包含强相消及其舍入损失。不能用中点值加任意安全倍数替代球包含。
所有 bound 公式中的非负和、乘、除、幂用向外端点，分母必须有严格正下界。证毕。

非有限球、含零的分母或无法证明的分支条件使对应认证门失败，不能被普通浮点诊断覆盖。
极小的正尾保留球算术任意指数，不以 underflow 后的零替代。

## C3：trace 常数的上界

圆形是冻结实例事实，不由 inclusion 单连通推出。以精确 $R,h,d,L$ 验证
$\theta=1-h/R>0$，以及材料 collar 与相邻材料副本、墙 collar、上下周期副本的
分离条件。中心是空列，材料与墙族的覆盖重数为 1，曲率界 $\kappa_*=1/R$。
所有这些不等式通过向外区间后，T9 可取 $\ell_*=d=1$，点窗口 $I=[\mu,\mu]$，

$$
c_0=\frac1{\theta h},\qquad c_1=\frac h{2\theta},\qquad
C^2=\frac{c_0}{\rho_-\mu^2}+
\frac{c_1+\ell_*^2c_0}{4\mu}+\ell_*^2c_1\rho_+.
\tag{C3}
$$

**证明。** 几何门给出 T9 的共同 collar 与覆盖证书，正材料界为 $1,17$。
(C3) 即适用定理的显式常数式。对精确输入向外评价右侧，并取非负平方根上端
$\overline C$，由 C2 保证 $C\le\overline C$。不依赖未知谱距或未知特征函数。证毕。

## C4：raw 质量的正下界

空中心列宽 $L_0=X_R-X_L=1$，横向使用归一化准周期 Rayleigh 基。对每个冻结模态，
令 $b_m=\beta+2\pi m/d$，以 (C1) 的同一 $\mu$ 构造 outgoing 波数。
必须严格判定 $\mu-b_m^2$ 的符号；本实例无需 Wood 极限分支。
设两侧系数为 $q_{L,m},q_{R,m}$。

若 $\gamma_m=\sqrt{\mu-b_m^2}>0$，取
$A_m=L_0$、$B_m=\sin(\gamma_mL_0)/\gamma_m$。
若 $\kappa_m=\sqrt{b_m^2-\mu}>0$，取

$$
A_m=\frac{1-e^{-2\kappa_mL_0}}{2\kappa_m},\qquad
B_m=L_0e^{-\kappa_mL_0}.
$$

令 $\lambda_{m,\pm}=A_m\pm B_m$，则

$$
U_0^2=\frac12\sum_m\left(
\lambda_{m,+}|q_{L,m}+q_{R,m}|^2+
\lambda_{m,-}|q_{L,m}-q_{R,m}|^2\right).
\tag{C4}
$$

**证明。** 横向正交性消去不同模态的交叉项。直接积分两支 $x$ 向指数给出 Gram
矩阵 $\left(\begin{smallmatrix}A&B\\B&A\end{smallmatrix}\right)$；其特征值为
$\lambda_\pm\ge0$。将系数变换为和、差即得 (C4)，与 v2 解析质量公式相同。
各项平方模及 $\lambda$ 以球算术包围；利用真实非负性，可以将下端与 0 取最大后
作非负乘积下界。求和开方取下端得 $\underline U\le U_0$。
有限中心区域质量不大于全条带质量，故 $\underline U\le\|u\|_{\mathcal H}$。
被遗漏的外部质量非负，不需积分其无限尾；成员资格由下节收缩给出。
必须实际证明 $\underline U>0$。求积一致或加密差不参与这个下界。证毕。

## C5：完整传播矩阵的认证尾

对每侧完整 $P_\pm$，以其精确输入逐项计算

$$
r_\pm\ge\|P_\pm\|_F\ge\|P_\pm\|_2,\qquad
r_\pm<1,\qquad K_\pm=\frac1{1-r_\pm^2}.
\tag{C5}
$$

**证明。** $\|P^nx\|_2\le r^n\|x\|_2$，平方求和即给 $K$。
这是 N7 块长 1 的特例；零次幂用精确 $\|I\|_2=1$，不必用 $\|I\|_F=\sqrt{97}$。
保留矩阵的全部元素，没有假定正规性或独立标量模态。对有限状态用球矩阵向量乘得到
$P^nc$。若完整材料行的实轴范数不超过 $M_A$，则

$$
\sum_{n\ge J}\|F_AGP^nc\|_{L^2(\Gamma)}^2
\le p_\Gamma M_A^2\|G\|_F^2K\|P^Jc\|_2^2.
\tag{C6}
$$

因为点态范数不超过 $M_A\|G\|_F\|P^nc\|$，积分长度 $p_\Gamma$，再应用 (C5)。
$G$ 和 $P^Jc$ 各出现一次。$M_A$ 可取已验证的完整 strip 行包络，故没有新的无限维优化。
墙行已经包含远侧 $GP$，沿 N1--N2 对其完整行使用同一几何求和，不能再次插入远侧传播。
各有限胞元场映射有界和 (C5) 同时保证 exact-kernel raw 场属于全条带加权 $L^2$。证毕。

## C6：连续材料和人工墙缺陷上界

保持 design-6-1b 的 NF1--NF6 及同一 physical signs。材料法向内向外，
$a=u^{\mathrm{out}}-u^{\mathrm{in}}$，$j=\partial_\nu u^{\mathrm{in}}-
\partial_\nu u^{\mathrm{out}}$，是普通导数，不是加权通量。

对每个实际有限状态 $x=G_\pm P_\pm^nc_\pm$，以球算术先计算 local/regular/off
有符号和。local retained 源 Kress 与普通梯形在次数门 $128+Q+1<N/2$ 下精确；
NF1 的连续遗漏核尾仍计算。regular 的源求积余项和 $M_R,M_I,M_T,M_L$ 逐项上评；
off 是完整冻结源 Rayleigh 支持。各层特殊函数、密度转换、坐标与矩阵舍入包含在中心球中。
不使用 MATLAB 特殊函数未证明的 ulp 假设。

令 $S_{A,r}$ 为该状态 retained 有符号值的模上端，$r_{A,r}$ 为连续核/源误差的行上界，
$M_A$ 为同宽 strip 中完整行范数上界。则

$$
\|F_Ax\|_{L^2(\Gamma)}^2
\le \frac{p_\Gamma}{N}\sum_r
\left(S_{A,r}+r_{A,r}\|x\|_2\right)^2
+\frac{2p_\Gamma M_A^2}{e^{aN}-1}\|x\|_2^2.
\tag{C7}
$$

**证明。** C2 包围每个有限中心；NF1--NF3 包围连续核、源及完整解析行，所有右侧
常数经球算术向上取得。NF4 的反射解析平方及 cot 轮廓证明直接适用，给出 (C7)。
先作有符号和再求模，所有节点半径交互项保留，$\mathrm ds=R\,\mathrm dt$ 只计一次。
有限部分两侧求和，无中心材料 singleton；无限部分用 (C6)。人工墙复用完整配对值行、
普通法向行及解析墙模态尾，有限中心和全部尾系数均需可靠上界；两条中心/首胞墙独立
计入，内部墙与首胞材料的 $n=0$ 分别记账。最后 T10 给出

$$
\overline\varepsilon_\partial^2=
\overline\varepsilon_{j,\mathrm{mat}}^2+
\overline\varepsilon_{j,\mathrm{wall}}^2+
\ell_*^{-2}\left(\overline\varepsilon_{a,\mathrm{mat}}^2+
\overline\varepsilon_{a,\mathrm{wall}}^2\right).
\tag{C8}
$$

每类平方包含 singleton（如有）、有限部分和无限胞元尾；墙另有完整模态尾。
材料没有 target Fourier 截断，不能将此表述为“未知高模尾为零”。证毕。

本节是认证算法的充分条件；在代码和实际产物逐项通过前，不称本次数值认证已经完成。
若某层仍为普通 double，整个 $\overline\varepsilon_\partial$ 门即未关闭。

## C7：向外谱距离与区间

设实际计算已证明 C3--C6 的三个界，取可靠标量上/下端

$$
\overline Q=\operatorname{up}(\overline C\overline\varepsilon_\partial),\quad
D=\operatorname{down}(\underline U-\overline Q)>0,\quad
\overline R=\operatorname{up}\!\left(\frac{2\mu_+\overline Q}{D}\right),
\tag{C9}
$$

其中 $\mu\in[\mu_-,\mu_+]$ 是 (C1) 的可靠包围，不是未知谱窗口；体内缺陷为零。
最终端点取

$$
I_{\mathrm{spec}}=
[\operatorname{down}(\mu_- -\overline R),\;
 \operatorname{up}(\mu_+ +\overline R)].
\tag{C10}
$$

**证明。** F14 中各分子因子非负、分母严格正，以相应单侧端点替换只扩大右侧。
故 $\operatorname{dist}(\mu,\sigma(A(\beta)))\le\overline R$。
由 C1 的包围及端点向外舍入可知 $[\mu-\overline R,\mu+\overline R]\subseteq I_{\mathrm{spec}}$。
谱为闭集，因此该区间与全谱相交。若 $\mu$ 本已在谱上距离为零，结论仍成立。
本结论不区分本质谱与离散谱，不推出某个离散特征值存在、唯一或编号。证毕。

输出须保存 exact dyadic/可靠球及向外十进制字符串；nearest JSON float 只作诊断。
例如对精确二进端点乘 $10^p$ 后用整数 floor/ceil 可得到可靠十进制端点，不能将
默认舍入的 `float(ball)` 或省略 radius 的显示字符串当作认证证据。

## Attempt-1 首次运行配置合同

首次科学运行前冻结 $Q=10,N=280,a=1/5$（strip 宽精确有理数），Arb 精度 192 bits。
次数门为 $128+10+1=139<N/2=140$。Ewald split/reciprocal/image/local/Taylor 参数
分别为 2/5/3/18/18，墙模态截断 256，Cauchy factor 为 $3/2$。
材料 target-source 对数为 78400，约为 384 节点方案的一半，目的是给完整 Arb 核
评价保留 45 分钟预算。Q10 的 local 连续核尾会较 v2 增大，全部按 C6 上评，不能省略。
Researcher 的纸面量级仅用于选择配置，不是任何认证输入。

完整传播尾按 C5--C6，块长 1。有限胞元数预声明自适应序列
$J\in\{16,24,32,48,64\}$，按传播状态能量尾
$K_+\|P_+^Jc_+\|_2^2+K_-\|P_-^Jc_-\|_2^2\le10^{-24}$ 选首个通过的 $J$；
此预算不是最终 action 的尾平方；乘上完整材料/墙 operator 因子后的尾必须照常全部计入。
若 cap 64 仍未达预算，保留实际严格尾上界，不把预算目标当作已证上界。
此自适应不改 raw 场且是首次配置的一部分，不因正常增大 $J$ 新建 attempt。

Engineer 对一次完整 run 的初始预估为 8--20 分钟、进程树 RSS 小于 2.5 GB；
MATLAB 无损导出、Arb 三个界及最终公式、文件保存共享一个 2700 秒/3 GB 监控周期。
API/preflight 不得冒充或拆分同一完整科学运行。科学配置改变另建 attempt；
程序纠错仍在同一 attempt 增加 run，失败日志和快照保留。

若首轮严格界宽于 $10^{-6}$，只要分母正且认证门全通过即作为有效结果保留。
只有在剩余预算足够时，才考虑 Q32/N324 或 N384 等明确的新 attempt；
不能为获得小数删除 Q10 的正余项或混用不同 attempt 的分子、分母。

## 证明与文献状态

新增命题 C1--C7 及公式 (C1)--(C10) 只写在本文件，使用原 T9--T10、F14、N1--N9
和 design-6-1b 的 NF1--NF6；未改其原文。软件原语使用上面已核对的官方接口，并与 vendor 0.9.0 的类型接口/元数据匹配，
无新增书籍引用或下载，未修改共享 ref。此处的数学连接证明完成；具体程序是否满足
球算术和完整误差合同，仍由 review-6-1c.md 的实际代码/结果审查决定。
Proof literature verification completed.


## 连续余项的补充审计说明

Researcher 独立核对 canonical Ewald 局部多项式：$J_NS_N$ 保留完整 $2N$ 次卷积；
局部正则补偿为整多项式与指数的组合，在对角点不调用有支问题的 $E_1$ 或对数。
Cauchy 半径 $B=3R_0/2$ 下，各级数比值、$B-R_0>0$ 及零至二阶导数余项
必须通过区间门。regular 的实节点半径分别计入 $M_R,M_I,M_T,M_L$；完整 strip
行用完整 image 包络，已吸收 $M_T$，不能在该行中再重复增加另一份 $M_T$。

目标求积对 $f=F_Ax$ 使用解析反射 $f^\sharp(z)=\overline{f(\overline z)}$。
$f^\sharp f$ 在实轴等于 $|f|^2$；cot 轮廓给出 (C7) 的 $2p_\Gamma/(e^{aN}-1)$。
local 的解析延拓通过固定实差角上的对数可积卷积及有限 density 移位建立，
不把 complex target 穿过未消去的对角核奇点。regular 非零 image 的实部正性、
reciprocal/non-Wood 以及 off-surface clearance 均按失败即停止的区间门检查。
这些解析条件是球算术之外的必要证明部分，不能由“高精度一致”替代。

墙保留模态为 $-256{:}256$，遗漏模态为 $|m|\ge257$；二者不重叠且完整。
遗漏模态须覆盖所有胞元，使用 $K_\pm\|c_\pm\|^2$，加上两条 singleton；
保留模态的无限胞元尾才使用 $K_\pm\|P_\pm^Jc_\pm\|^2$。两种尾不可混用。


## 质量、墙与曲线积分的归一化核对

横向基为 $\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_m y}$，在长度 $d$ 上正交归一。
因此中心 Rayleigh Gram 及竖直墙 Parseval 都没有额外的 $d$ 因子；墙系数的构造本身
含 $1/(2\sqrt d)$。空中心的材料密度是 $\rho_e=1$，故质量不再乘另一材料系数。
材料曲线不采用该 Parseval 恒等式，单独使用 $\mathrm ds=R\,\mathrm dt$，源 Jacobian
和目标权重各在自己的积分中出现一次。虽然本实例 $d=1$ 会掩盖误乘 $d$ 的数值问题，
Researcher 已对照原始基函数及 raw 评价器逐式核对，当前公式归一化一致。


## 墙值核的符号恒等式

v2 平面 Green 值系数是 $\mathrm i/(2\gamma_m)$，而
$(\mathrm i\gamma_m)^{-1}=-\mathrm i/\gamma_m$。因此若记程序局部量
`inv_i_gamma = 1/(i*gamma)`，平面值行的系数必须为 `-inv_i_gamma/2`：

$$
V^{\mathrm{flat}}_{L,m}=
\frac{\mathrm i}{2\gamma_m}
\left(\xi_{L,m}+e^{\mathrm i\gamma_m L_0}\xi_{R,m}\right).
$$

右侧交换 $L,R$，曲线法向行转值行的系数仍为正的 `inv_i_gamma`。
这是从精确 Green 核到配对值行的代数恒等式，不以小残差或与 v2 数字接近作为证明。
run-08 的移植错误及修复见审查记录；错误 run 的 status 字符串不构成物理对象认证。
