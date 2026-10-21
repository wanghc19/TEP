# I6 非 Fourier 界面范数实验设计

> 迁移说明（2026-09-20）：本文件来自上一轮非 Fourier 专题，适用于
> `test/i6/resolvent-v2/`（原 `test/i6/resolvent-nonfourier-v1/`）。
> 下文研究、运行时间与非认证结论属于上一轮；本次仅迁移文档并更新当前路径。
> 历史运行产物及源码快照未改。新认证设计与审查见 design-6-1c.md、review-6-1c.md。

## 工作合同

实际起点：2026-09-20 01:29:35 UTC；绝对截止：04:29:35 UTC。
04:14:35 UTC 前进入最后十五分钟的审查与交付。每次完整科学运行共享 2700 秒和
3,000,000,000 bytes 进程树 RSS 硬限，无宽限。程序修复不重置总时钟。
开始已确认 `/Users/whc/Documents/Work/epost` 位于 `codex/epost`，工作树干净。
唯一写入目录为 `test/i6/resolvent-v2/`，不 commit 或 push。

主 agent 负责本设计、README、审查记录及总时钟；Researcher 只读构造与核对公式；
Engineer 负责 MATLAB、局部依赖、输入和运行产物；Skeptic 只读独立审查。
所有代理共享工作树，禁止覆盖其他所有者文件。初启服务容量错误经重试恢复，
总时限没有重置。既有理论、旧实验、main draft、共享 package 均只读。

新局部证明采用 rigorous-proof 的 **Proof from scratch** 模式，只写在本文件；
既有理论保持原文。新记号采用 notation-discipline 的 **Writing** 模式。
不下载或扩展文献，不把上级维护规则解释成额外写入授权。

## 不变的数学对象

权威为 resolvent-bound 的 T9--T10、F14、N1--N9。只读核对当前 main
`draft/zh/s-modelproblem.tex` 的 `eq:fixed-beta-operator`：物理算子是全条带
$A(\beta)=-\rho^{-1}\Delta$，定义域包含全局分布 Laplacian、普通导数 transmission、
上下两项准周期条件和全条带有限能量，不是人工胞元 Dirichlet 算子。

同一冻结 candidate、密度、$q_{\mathrm{center}}$、$G_\pm,P_\pm,c_\pm$ 全部不变。
预期标量为 $\widehat k=1.832770289108157$、$\mu=3.3590469326375971$、
$\beta=0.5$、$d=L=1$、$R=0.2$、$\rho_e=1$、$\rho_{\mathrm{disk}}=17$；
入口须读取并验证科学输入，不从文档解析这些数值。
中心是空列，没有中心材料 singleton；两条中心/首胞人工墙仍需计入。
每个 inclusion 是单个单连通区域；圆形是冻结实例事实，不由单连通推出。

材料法向取内向外，$a=u^{\mathrm{out}}-u^{\mathrm{in}}$，
$j=\partial_\nu u^{\mathrm{in}}-\partial_\nu u^{\mathrm{out}}$。
使用完整有符号跳跃，先合并 local、regular-image、off-surface，再施加同一个状态
并取范数。曲线积分使用 $\mathrm ds=R\,\mathrm dt$，只计一次。
$\mathscr E$ 表示界面集合，$\Lambda_\pm$ 保留给 DtN，$\eta$ 保留给 density。

人工墙、中心解析质量、trace 常数和 F14 可沿用基线的有效公式并从冻结数据重评。
不构造 lift，不沿用旧负阶法向范数，不以旧最终 residual 标量作为新输入。
最终目标是谱距离估计

$$
\mathcal R_{\mathrm{spec}}=
\frac{2\mu\overline C\,\overline\varepsilon_\partial+
\overline\varepsilon_{\mathrm{vol}}}
{\underline U-\overline C\,\overline\varepsilon_\partial},
\qquad
\underline U>\overline C\,\overline\varepsilon_\partial.
$$

它不是 residual 范数。完整浮点包围不是本轮前置门，但全部连续源/目标积分误差
必须有明确所有者，不能把未知项归入“未认证”后删掉。

## 旧路线瓶颈与本轮改动

I6 `resolvent-v1/output/attempt-1/run-04` 基线为
$\mathcal R_{\mathrm{spec}}=7.387058992105812\times10^{-4}$。
主导项是材料普通法向高模平方 $3.4066674818514996\times10^{-9}$，来自
local 四阶导数尾系数乘全 lead 状态能量上界，而非真实有限跳跃或胞元尾。

I5 当前最新非 Fourier 尝试是 `residual-numerator-v8`（设计/审查 I5.1j）。
它直接合并值跳跃，但使用零导数中心及全局导数球
$L_A=1624.2467206052913$，得到 $R_0=2.642100809251934$、
$R_1=3315231.5072913063$；提升量因此约 1268.5。
旧 lifting 的 $R_1$ 有不随加密消失的损失，不能原样作为本轮直接 $L^2$ 路线。

本轮拟直接对有符号节点值的平方作曲线求积，并展开连续求积余项；不建立材料
跳跃的 Fourier 系数、target FFT 或高模尾。原始有限密度的 Fourier 表示、
Kress 源求积权以及人工墙的 Rayleigh 表示仍允许使用，作用须分别标明。
圆实例的局部核拆分给出额外的有限多项式结构，有望消除不必要的源四阶导数包络；
这项性质不得宣称对任意单连通曲线自动成立。

## Attempt / run 与输出规则

方案或科学配置改变，新建 attempt 并记录原因；同方案程序修复保留 attempt、增加
run 编号。每个 run 保留源码、配置、日志、资源采样、失败证据和机器可读分项。
入口只接受显式科学 MAT 输入及源码配置，不读取 Markdown、Git、哈希或历史最终量。

独立审查重点为：源求积和目标积分余项各自完整；有符号配对与 $\mathrm ds$；
完整 $P$ 的无限胞元尾；同 raw 场的质量；分母及 F14；特殊函数/舍入认证层级。
目标 $10^{-6}$ 的 tightness 不替代正确性，也不成为合法有限结果的交付门槛。

## 本轮局部引理与完整误差连接

以下由 Researcher 构造，主 agent 整理，Skeptic 独立核对。这里只针对当前冻结圆形
实例，新增结论不修改 resolvent-bound。令 $p_\Gamma=2\pi R$，$F_a(t),F_j(t)$
分别为材料的完整值/普通法向跳跃行，映射 $\mathbb C^{194}\to\mathbb C$。
节点 $t_r=2\pi r/N$，$r=0,\ldots,N-1$。$C_{A,r}$ 是直接源求积形成的有符号
行中心，$A\in\{a,j\}$，满足
$\|F_A(t_r)-C_{A,r}\|_2\le r_{A,r}$。

### 引理 1：当前圆的 retained local 源求积精确性

局部消奇拆分只含 $x=2R^2(1-\cos(t-s))$ 的有限多项式及 $\sin(t-s)$、
$\cos(t-s)$ 因子。沿用原始有限 density 支持 $m=-128,\ldots,127$，
截取整函数核级数到 $Q=32$。有限拆分的三角次数逐项为：

| 拆分 | 次数上界 |
|---|---:|
| $S_1,S_2$ | $Q$ |
| $D_1,D_2$（含 $x$） | $Q$ |
| $C_1,C_2$（含 $\sin(t-s)$） | $Q$ |
| $A_1\cos(t-s),A_2\cos(t-s)$ | $Q+1$ |

原始 $\tau,\zeta=-\sigma$ 及 $\tau'$ 的支持最大绝对阶均为 128；导数只改变
系数，不扩大支持。因此各 smooth source factor 乘 density 的次数至多
$D=128+Q+1=161$。若 $N$ 为偶数且 $D<N/2$，在每个真实 target 节点，
Kress 对数权与普通周期梯形对这些 retained source 项均精确（精确算术）。

**证明。** $x$ 是一次三角多项式；$J,Y$ retained 多项式次数为 $Q$，
$J^{[1]}$ 和 cancellation factor 次数为 $Q-1$，乘 $x$ 或 $\sin(t-s)$
至多增加一。$A$ 项的额外 $\cos(t-s)$ 给出 $Q+1$。有限乘积次数相加。
对 $L(\theta)=\log(4\sin^2(\theta/2))$，其积分矩为 0（零阶），以及
$-2\pi/|m|$（非零整数阶）。这些矩可由
$2\operatorname{Re}\log(1-r e^{\mathrm i\theta})$ 的幂级数积分后令 $r\uparrow1$
得到；对数奇性可积保证极限。源码中的 Kress 权恰满足

$$
\sum_{r=0}^{N-1}w_r e^{\mathrm i m t_r}
=\begin{cases}0,&m=0,\\-2\pi/|m|,&0<|m|<N/2,\end{cases}
$$

这是有限根单位和的直接计算。普通梯形也对这些非零阶给零、零阶给 $2\pi$。
有限线性组合与 target 平移保持等式，因此所有 retained source 项精确。证毕。
这里的有限源支持用于验证既有核求积权；没有生成材料跳跃的 target Fourier 系数，
也没有用其系数平方或高模尾评价界面范数。

### 引理 2：连续核级数尾与局部解析延拓

定义已知有限密度系数的行范数和

$$
T_{\tau,q}(a)=\sum_{m=-128}^{127}|m|^q e^{a|m|}\|\tau_m\|_2,
\qquad
T_{\zeta,q}(a)=\sum_{m=-128}^{127}|m|^q e^{a|m|}\|\zeta_m\|_2,
$$

其中 $q=0,1$（$q=0$ 时零阶因子为 1）。令 $L_{\log}=8\pi\log2$。
以 $D_1,D_2,S_1,S_2,A_1,A_2,C_1,C_2$ 表示完整实差角 kernel factor 的绝对上界；
它们来自现有整函数系数及几何级数尾的显式有限公式。$\Delta D_1,\ldots$ 表示
对应的 exact-minus-retained factor 上界。因
$\int_0^{2\pi}|L(\theta)|\,\mathrm d\theta\le L_{\log}$，连续 local 节点误差可取

$$
\begin{aligned}
r_{L,a}={}&L_{\log}(\Delta D_1T_{\tau,0}(0)+\Delta S_1T_{\zeta,0}(0))
+2\pi(\Delta D_2T_{\tau,0}(0)+\Delta S_2T_{\zeta,0}(0)),\\
r_{L,j}={}&L_{\log}(\Delta A_1T_{\tau,0}(0)+R^{-1}\Delta C_1T_{\tau,1}(0)
+\Delta D_1T_{\zeta,0}(0))\\
&+2\pi(\Delta A_2T_{\tau,0}(0)+R^{-1}\Delta C_2T_{\tau,1}(0)
+\Delta D_2T_{\zeta,0}(0)).
\end{aligned}
\tag{NF1}
$$

这些是连续遗漏核积分的上界，替代旧 $p=4$ 源误差和旧离散 series radius；三者不能
同时叠加，也不能仅把旧源误差设零而不补连续尾。identity 在 retained 节点值中计一次，
没有 kernel-series 尾。

令 $M_{L,a}(a)$ 等于上式值行中的 $\Delta$ 换成完整上界、$T(0)$ 换成 $T(a)$，
再加 identity 项 $T_{\tau,0}(a)$；$M_{L,j}(a)$ 类似，再加 $T_{\zeta,0}(a)$。
则这两个数包围 local 完整精确行在 $|\operatorname{Im}t|\le a$ 的行范数。

**证明。** 圆 local 行为实差角卷积。把卷积写成固定实变量 $\theta=t-s$ 后，
所有 kernel factor 保持在实差角；将有限 density 的自变量延拓为 $t-\theta$。
系数各自增长至多 $e^{a|m|}$，$\tau'$ 多一个 $|m|$。
可积实对数核提供支配函数，有限密度又是整函数，所以该表达解析且实轴上等于原行。
不把 complex target 直接穿过自作用奇点。三角不等式及上述 $L^1$ 矩给出包络；
将 factor 换成遗漏尾即得 (NF1)。$R^{-1}$ 来自 Maue 中的弧长导数，kernel 中既有
源 Jacobian 不再另乘。证毕。

regular-image 的源梯形余项及 $M_R,M_I,M_T,M_L$ 全部沿用其连续解析证书；
off-surface 是完整冻结 Rayleigh 支持的直接和，没有遗漏源模态。

$$
C_{a,r}=C_{L,a,r}+C_{R,a,r}+C_{O,a,r},\qquad
C_{j,r}=C_{L,j,r}-C_{R,j,r}-C_{O,j,r},
\tag{NF2}
$$

$$
r_{A,r}=r_{L,A}+r_{R,A,r},\qquad
M_A(a)=M_{L,A}(a)+M_{\mathrm{reg},A}(a)+M_{\mathrm{off},A}(a).
\tag{NF3}
$$

$M_{\mathrm{reg},A},M_{\mathrm{off},A}$ 使用相同宽度 $a$ 的完整 target-strip action 上界，normal 的解析单位法向
也在包络内；不能只取 retained kernel 上界。所有正负边界都须成立。

### 引理 3：直接平方求积及其余项

若完整精确 $F_A$ 在闭 strip $|\operatorname{Im}t|\le a$ 的邻域解析、$2\pi$ 周期，且
$\|F_A(t)\|_2\le M_A(a)$，对任意状态 $x\in\mathbb C^{194}$，令

$$
E_A=\frac{2p_\Gamma M_A(a)^2}{e^{aN}-1},\qquad
I_A(x)=\frac{p_\Gamma}{N}\sum_{r=0}^{N-1}
\bigl(|C_{A,r}x|+r_{A,r}\|x\|_2\bigr)^2+E_A\|x\|_2^2.
\tag{NF4}
$$

则 $\|F_Ax\|_{L^2(\Gamma)}^2\le I_A(x)$。

**证明。** 对 $f(t)=F_A(t)x$ 定义解析反射
$f^\sharp(z)=\overline{f(\overline z)}$。$H(z)=f^\sharp(z)f(z)$ 解析、实轴为
$|f|^2$，strip 上绝对值至多 $M_A(a)^2\|x\|_2^2$。
将 $H(z)\cot(Nz/2)$ 沿高 $2a$ 的周期矩形积分，竖边周期相消，留数给出
梯形节点和；上下边的 $\cot$ 分别与 $\mp\mathrm i$ 相差至多
$2/(e^{aN}-1)$。上下 $H$ 积分均可移到实轴。因此

$$
\left|\int_0^{2\pi}|f(t)|^2\,\mathrm dt-
\frac{2\pi}{N}\sum_r|f(t_r)|^2\right|
\le\frac{4\pi M_A(a)^2\|x\|_2^2}{e^{aN}-1}.
$$

矩形竖边可先平移避开节点，周期性保证同一结论；strip 端点必要时由稍窄矩形取极限。
乘 $\mathrm ds=R\,\mathrm dt$，再对每个真实节点使用
$|f(t_r)|\le|C_{A,r}x|+r_{A,r}\|x\|_2$，即得 (NF4)。
这里余项施于完整精确行，不是近似行中心；所以节点球与积分余项分别负责两类误差，
没有遗漏两者交互项。复系数及实 $\beta$ 的正负均不破坏解析反射。证毕。

### 全胞元汇总

有限部分对 $x=G_\pm P_\pm^nc_\pm$，$n=0,\ldots,J-1$，直接使用 (NF4)。
余下部分使用有限 operator 上界

$$
B_A(G)^2=\frac{p_\Gamma}{N}\sum_r
\bigl(\|C_{A,r}G\|_2+r_{A,r}\|G\|_F\bigr)^2+E_A\|G\|_F^2,
\tag{NF5}
$$

以及 N7 的完整矩阵块幂系数 $K_\pm$，得到

$$
\sum_{n=J}^{\infty}\|F_AG_\pm P_\pm^nc_\pm\|^2
\le B_A(G_\pm)^2K_\pm\|P_\pm^Jc_\pm\|_2^2.
\tag{NF6}
$$

证明先在 (NF4) 使用有限行矩阵范数，再用原理论 N7--N8。$G$ 在行内、$P^Jc$ 在外，
各只出现一次。没有中心材料项。两类材料项、基线人工墙全部项按 T10 加平方，
值项乘 $\ell_*^{-2}$，最后进入 F14。

## Attempt 1 冻结配置

首轮固定 $N=1026$、参数 strip 宽 $a=0.2$、整函数截断 $Q=32$、每侧有限胞元
$J=16$、传播块长 32。于是 $161<513$，没有 Nyquist 边界模式。
Ewald split/reciprocal/image/local/Taylor 截断分别为 $2,5,3,18,18$，
流式 target block 为 4。取 $\ell_*=1$，collar、trace 常数、质量区域与 I6 基线相同。
这些是科学配置；启动后改变其中任一控制项须另建 attempt。

预先冻结 $N=1026$ 是为了给解析目标求积余项留出余量，不能根据节点采样最大值
宣称 strip 上界。运行前由 Engineer 确认完整资源估计，Skeptic 检查上述条件在代码中
逐项兑现；通过后启动 `output/attempt-1/run-01/`。

Engineer 于 01:50 UTC 前给出完整首 run 预估：1--3 分钟、进程树峰值小于 2 GB。
采用分块计算避免存储多套 $N\times N$ 核矩阵；watchdog 每约 0.25 秒采样任务进程树，
达到 2700 秒或 3,000,000,000 bytes 时立即 SIGKILL 该进程组，无额外宽限。
源码和配置在每个 run 启动前复制到独立目录；旧有效结果不得覆盖。

## 推导与记号工作流记录

本轮三个引理及 (NF1)--(NF6) 是在本文件新增的局部证明，Skeptic 的独立逐项审查
记录在 `review-6-1b.md`。引理 1 的 finite-source Kress 矩直接从当前只读
`+quad/quad_kress_rvec.m` 核对并在上文推导；引理 2 展开 circle convolution；
引理 3 展开 cot 轮廓公式。原理论 N7--N8 负责唯一的完整传播尾连接。
没有调用未经核验的外部定理来替代这些步骤，没有下载文献；在已列圆形、有限源支持
及解析 strip 条件下无剩余证明缺口。Proof literature verification completed.

新增的 $p_\Gamma$（周长）、$C_{A,r},r_{A,r}$（节点行及半径）、$T_{\tau,q},T_{\zeta,q}$
（密度 strip 包络）、$M_A$（完整行 strip 包络）、$E_A,I_A,B_A$（目标积分误差、
状态范数上界、尾 operator 上界）均服务于明确的有限计算。裸 $a$ 仅在参数 strip
宽度的小节出现；界面值跳跃始终写 $a_\Gamma$ 或类型下标 $A=a$，不改旧物理定义。
没有把 $\Lambda$ 用为求和指标，未引入 inclusion 分支下标。
