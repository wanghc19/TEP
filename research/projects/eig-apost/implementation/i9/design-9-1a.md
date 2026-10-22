# I9.1：非对称双 lead 的共同 projected gap 与候选搜索

## Material Passport

- Origin Skill / Mode: `academic-research-suite / experiment-agent / run-design`
- Origin Date: `2026-10-22`
- Design ID: `I91-ASYMMETRIC-LEADS-V1`
- Status: `EXECUTION COMPLETE; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Claim boundary: `NUMERICAL PROJECTED-GAP CLASSIFICATION AND FINITE-MATRIX CANDIDATES`
- Review: [[research/projects/eig-apost/implementation/i9/review-9-1a|独立审查]]

本合同只研究固定 $\beta=0.5$ 下两种不同周期 lead 的数值共同带隙，以及其中可见 dip 的候选定位。
不计算谱距离、迹常数、跳跃汇总或质量范数，不改变 $\beta$，不增加参数扫描。
旧 [[research/projects/eig-apost/implementation/i8/design-8-4b|I8.4]] 和
[[research/projects/eig-apost/implementation/i8/design-8-5a|I8.5]] 仅供只读代码依据，旧结果不是运行输入。
本次来源为 `+bloch/construct_S.m`、`solve_modes.m`、`mode_traces.m`、`select_port_traces.m`，
以及 `test/i8/scan-v1/scan_i8_point.m` 和搜索管理器。运行只调用新实验源码、公共包和已有 FMM2D。

依赖链为：唯一配置 → 解析几何 → 两侧独立散射矩阵和 Bloch 分类 → 各侧分类区间及交集 →
代表点升档检查 → 共同区间 coarse 全 dip 搜索 → 各分支 fine 重分类/匹配/细化 → bypass 复算和独审。
成功可包括“没有可用共同区间”或“有共同区间但没有可见 dip”，但必须有完整、可解释的原始记录。

## 1. 唯一配置与解析几何

科学参数只在 `test/i9/search-v1/` 的配置函数定义；本文件不能控制 MATLAB。

| 对象 | 冻结值 |
|---|---|
| 周期、胞元 | $d=L=1$，局部壁 $X_L=-0.5,X_R=0.5$，外部材料 $1$ |
| 准周期参数 | $\beta=0.5$ |
| 中心 | 原五瓣 star，全部六行乘 $\sqrt{0.04/0.0618}$，面积 $0.04\pi$，材料 $2$ |
| 负/正 lead | 三瓣径向形状分别 $a_-=0.12,a_+=0.20$，材料分别 $17,17$，各面积 $0.04\pi$ |
| coarse | center $256$、negative lead $128$、positive lead $128$，三个独立字段 |
| fine | center $512$、negative lead $256$、positive lead $256$，三个独立字段 |
| 通道与 proxy | $M=48,K=97$，`nside=160, ntop=160, nproxy=80, mpw=32, H=1.1, proxy_dist=0.2` |
| FMM | 现有官方版本 `550dae5b77b1e006c8ffae37fc832f8c2b536871`，请求容差 $10^{-12}$ |
| 探索与定位 | 初始 $1.45+(0:32)0.025$；局部 $11$ 点；实际整轮 $W\le2\times10^{-14}$ |

令 $c_a=0.2/\sqrt{1+a^2/2}$，使用同一个全局方向的参数 $\theta$：

$$
r=c_a(1+a\cos3\theta),\quad r'=-3c_a a\sin3\theta,\quad
r''=-9c_a a\cos3\theta,
$$
$$
x=r\cos\theta,\quad x'=r'\cos\theta-r\sin\theta,\quad
x''=(r''-r)\cos\theta-2r'\sin\theta,
$$
$$
y=r\sin\theta,\quad y'=r'\sin\theta+r\cos\theta,\quad
y''=(r''-r)\sin\theta+2r'\cos\theta.
$$

六行次序为 $[x;x';x'';y;y';y'']$，参数区间长度 $2\pi$。不对负侧镜像，不交换端口。
$r>0$ 使曲线是围绕原点的一条单值径向边界；$xy'-yx'=r^2>0$、速度
$\sqrt{r^2+(r')^2}\ge c_a(1-a)>0$，支持 CCW、简单闭合及内部单连通的几何检查。
解析面积 $\frac12\int_0^{2\pi}r^2\,d\theta=0.04\pi$；同时保存采样面积、闭合位置/导数误差、
最小速度和边界距离。两侧 $r\le c_a(1+a)<0.24$，故到局部方胞元壁至少约 $0.26$；
中心沿用同一缩放几何并单独记录最小间距。图应显示至少中心与左右各两个周期胞元及全局坐标方向标注。
以上代数性质是解析参数化检查，不是数值边界误差认证。
两侧解析最大半径分别约 $0.223197928596183,0.237635410314402$，因此对所有四面胞元壁的
统一距离下界分别为 $0.276802071403817,0.262364589685598$。正 $a$ 的 $r(\pi-\theta)$
改变三倍角余弦项的符号，因此不具有局部竖轴反射对称；两形状的最大/最小半径比分别为
$1.272727\ldots$ 和 $1.5$，旋转或镜像不能改变该比值，故不是彼此的刚体旋转/镜像副本。

## 2. 两侧独立散射矩阵和方向

全局右行/左行 Rayleigh 振幅始终按 $[a;b]$ 排列。对每个侧别 $s\in\{-,+\}$ 独立构造

$$
\begin{bmatrix}b^L\\a^R\end{bmatrix}
=\begin{bmatrix}R_L^{(s)}&T_{RL}^{(s)}\\T_{LR}^{(s)}&R_R^{(s)}\end{bmatrix}
\begin{bmatrix}a^L\\b^R\end{bmatrix},\quad
A_s=\begin{bmatrix}-R_L^{(s)}&I\\T_{LR}^{(s)}&0\end{bmatrix},\quad
B_s=\begin{bmatrix}0&T_{RL}^{(s)}\\I&-R_R^{(s)}\end{bmatrix}.
$$

$A_sv=\lambda B_sv$ 的 $\lambda$ 沿全局 $+x$ 推进一个胞元。分类对每侧正向铅笔全体齐次特征对进行。
构造负侧衰减空间使用 $(B_-,A_-)$ 的稳定空间，正侧使用 $(A_+,B_+)$ 的稳定空间。
不能将一个 lead 的结果复制给另一侧，不能假设 $R_L=R_R$。负侧选择的空间在相邻周期壁由
Bloch 推进映到自身，因此在接口的右胞元壁使用同一振幅子空间，不是借助左右反射对称。

若 $Z_\pm=[Z_{a,\pm};Z_{b,\pm}]$，$G=\operatorname{diag}(\gamma_m)$，则中心外法向约定为

$$
\Lambda_+=iG(Z_{a,+}-Z_{b,+})(Z_{a,+}+Z_{b,+})^{-1},\qquad
\Lambda_-=-iG(Z_{a,-}-Z_{b,-})(Z_{a,-}+Z_{b,-})^{-1}.
$$

代码使用转置线性求解，不显式求逆。中心 $T,N_0$ 沿用既有定义，
$A_{\rm def}=N_0-\operatorname{diag}(\Lambda_-,\Lambda_+)T$；相同 $\beta_m,\gamma_m$ 权重生成
$A_{\rm phys}$，四指标由同一 $k$、同一矩阵组得到。保留 assembly defect、DtN 求解条件量和残差。
`construct_S` 已完成 square-root quadrature 坐标到 physical density 的逆映射，不额外缩放。
FMM 只替换光滑 proxy 的势/梯度/Hessian；奇异核、Kress、BIE 和多 RHS 解保持原路径。

## 3. Bloch 分类与数值带边

缩放正向铅笔后做 complex QZ，保存完整对角 $\alpha_j,\vartheta_j$、QZ backward residual $e_{\rm qz}$、
各计数和 BIE 相对残差。使用齐次量避免直接形成极大乘子：

$$
h_j=\operatorname{hypot}(|\alpha_j|,|\vartheta_j|),\quad
a_j=|\alpha_j|/h_j,\quad t_j=|\vartheta_j|/h_j,\quad d_j=|a_j-t_j|.
$$

同时近零的齐次对是 indeterminate；单独的零或无穷乘子仍是可分类的极端衰减方向。
底层零判据沿用 $\max(100\,\mathrm{eps},10e_{\rm qz})$。分类保护环为

$$
\tau_{\rm in}=\max(10^{-8},100e_{\rm qz}),\qquad
\tau_{\rm out}=\max(10^{-6},10\tau_{\rm in}).
$$

- `NEAR_UNIT_PROPAGATING`：存在 $d_j\le\tau_{\rm in}$ 且没有下述不确定对，表示数值近单位圆传播证据，不是精确谱证明。
- `UNCERTAIN`：存在 $\tau_{\rm in}<d_j\le\tau_{\rm out}$，或分类不完整；即使同时有近单位圆对也优先记不确定。
- `GAP`：没有 indeterminate，所有 $d_j>\tau_{\rm out}$，严格 stable/unstable 数为 $97/97$，
  并通过 $e_{\rm qz}\le10^{-10}$、BIE relative residual $\le10^{-8}$ 和所有有限值/维数检查。
- `FAILED`/`UNQUALIFIED`：计算错误、坏残差、非有限数据或病态求解；不能作为带隙或普通传播带证据。

这些阈值是本阶段固定的工程资格标准，不等于 FMM 或离散误差界。不得人为挑出 97 个向量再倒推存在带隙。
状态优先级为失败/未合格、齐次不定、不确定环带、近单位圆传播证据、GAP；保存全部逐模态标签，不以总标签抹去混合情形。
两侧同时 `GAP` 才有当前点的 common-gap 资格；其余点不做普通带隙匹配。
负侧还计算 reciprocal 铅笔的全分类；若 forward/reverse 总分类不同，记
`UNCERTAIN_DIRECTION_CLASSIFICATION`，不构造其普通 gap DtN。原始双向数据保留供检查。

先按每侧的完整探索网格识别最大连续 `GAP` 点段。相邻 `GAP` 与 `NEAR_UNIT_PROPAGATING`/`UNCERTAIN`
之间二分到实际 bracket 宽度 $\le10^{-4}$，保存两个实际端点、类型与全部中点。`FAILED` 邻域独立挂起，
不伪装成带边二分、不跨越失败点连接区间。这里定位的是数值分类过渡，未认证真实带边。
窗口边界的 `GAP` 段记为截断区间，不能宣称完整带隙宽度。

每侧取实际 `GAP` 侧端点，向段内部各留 $10^{-3}$ 的搜索 buffer；截断端也保留同样 buffer。
两侧安全区间求交，形成可用 common 区间。若 buffer 后为空则记录 `NO_BUFFERED_INTERIOR`。
若初始没有可用共同区间，或必须处理的内侧边无法在原窗夹住，只允许一次有依据的扩窗到
$[1.25,2.45]$、网格最大步长 $0.025$；已有可用截断区间不为追求完整带宽自动扩窗。
扩窗后仍无可用区间则正常交付带隙结果并停止候选搜索。

## 4. 最小升档检查与搜索合同

每个可用 common 区间选左安全端点、中点、右安全端点，去掉 exact 重复 $k$，分别以两档重算两侧 lead。
记录每侧散射矩阵相对 Frobenius 差、最近单位圆距离、分类计数和残差；该检查不计算中心、不构成收敛序列。
两档均 `GAP` 才支持该代表点。若 fine 代表非 `GAP`，区间记为 `FINE_CLASSIFICATION_UNRESOLVED`；
可在实际重新确认的有效子段继续，但不直接继承 coarse 区间资格。无需额外设任意散射矩阵差的“收敛门”。

共同区间 $[l,r]$ 的 coarse 网格先合并安全端点与区间内本次已有成功 lead 分类的实际 $k$，
排序并仅删除 exact 重复。相邻间距超过 $0.025$ 时均匀补为 $\lceil\Delta k/0.025\rceil$ 段；
若总点数不足 11，再合并 `linspace(l,r,11)` 并 exact 去重。这使最大步长不超过 $0.025$、
至少有 11 点，并复用现有 lead 数据；无需把 coarse 网格限制为均匀 33 点。
每点先重用/计算自己的两侧 lead，只有共同分类合格才构造中心。
所有普通内部局部极小值保留；exact 等值连续平台登记为一个待检查区间；失败及端点下降保留来源和状态。
coarse dip 的邻点 bracket 向左右各扩展一个本轮 coarse 单元，裁到已确认安全 common 区间，然后立即升 fine。
不同档位评分不混用，fine 每个点都重新核对两侧分类。

继承 I8.5 的实际采样、多分支与端点恢复逻辑：每轮 11 点，普通 winner 为 `aphys_ratio` 首次最小行；
内点下一轮使用左右实际邻点；端点 winner 在安全 common 区间内恢复窗口，无法夹住记边界未解决。
可分辨多谷全部分支；只有相邻极小值的共同鞍点相对两谷的显著度都超过
$64\,\mathrm{eps}\max(1,\max|\mathrm{score}|)$ 才作可分辨分裂，否则保留全部小谷的数值歧义簇、
鞍点及来源，用包含全部小谷及外邻点的窗口继续；无法缩小则 `AMBIGUITY_UNRESOLVED`。
不能按 5% 或全局最深阈值删除浅谷，不能用重叠本身判定同一个模态。

正常完成要求 fine、整轮 11 点有效且 common-gap 合格、严格内点 winner、实际
$W=k_{\rm last}-k_{\rm first}\le2\times10^{-14}$。正式 candidate 为该末轮实际首次最小点；累计最佳另存。
同时保存邻点宽度 $w=k_{j+1}-k_{j-1}$ 和各实际步长，不能混同 $W,w,dk$。
小奇异值、一次回升或平台均不提前停止。浮点耗尽、无法缩小、失败、边界、预算分别记录。
每个正式候选 fine 绕过所有缓存完整复算，保存两侧矩阵/QZ 数据、中心匹配矩阵和四指标绝对差。

## 5. 数据、调度与资源

职责分离为纯网格、lead 评价/分类、中心匹配、精确缓存调度、dip 识别、多区间管理和保存展示。
点键必须包括配置、左右几何、空间档位和 `num2hex(k)`；成功分类/成功匹配与失败状态分离。
同一配置的 gap 分类和中心匹配共享 lead；仅保留必要散射块、QZ 数据和通道，避免缓存 BIE 大阵。
大型 lead cache 有固定容量/内存上限；逐点标量永久保存，淘汰后重构应计入新调用而非假报 hit。
不得为每点保存全部密度。候选与最小审查证据单独保存。

记录 lead 请求/实际构造/缓存命中、match 请求/实际点计算/缓存命中、各档不同 $k$、每侧实际构造数，
各 source 区间的每轮节点、winner、状态、分裂/合并来源、所有末端候选和未解决状态。
互斥计算阶段为 `timing.gap`（探索与边分类）、`timing.validation`（代表点及相同 lead 退化检查）、
`timing.coarse/fine`（对应完整匹配点，包含 cache miss 的 lead 构造）、`timing.confirmation`（bypass 全点）。
`lead_log.seconds`、FMM callback 均是这些阶段的内部计时，不再叠加。
相同 lead 退化检查另构造两套 lead 和一个中心，不在普通调度 ledger 中，构造总数须显式加上这项。
该检查的嵌套 callback ledger 只保留内部两 lead 回调，不能据此声称覆盖了该验证的全部 callback；
外层验证时间仍包含中心构造，计时边界不受影响。
图/CSV/JSON/MAT/日志全部在本次 `output/`，从空 output 可完全重建。
数值入口不读 Markdown、Git、旧输出，不依赖本机绝对路径或原始目录层级。

全任务从 `2026-10-22 11:14:55 UTC` 到 `13:14:55 UTC`，设计、失败修复、运行、独审均计入。
正确配置的一次完整科学运行含所有 MATLAB 批次共享 **2400 秒硬限、3,000,000,000 bytes process-tree RSS**，
40 分钟后没有宽限。只有 Engineer 启动 MATLAB，串行；自动记录内存、时间、其他 MATLAB 和退出清理。
预留至少 20 分钟独审/整理。新点成本必须按两套 lead 加一个中心估计，不能照搬 I8 单 lead 秒数。
预运行规划为 coarse 分类约 1–2 秒/点、fine 完整点约 3–4 秒；每 dip 约 180–240 个新 fine 点，
单分支约 9–16 分钟，另留边与代表检查/复算/输出成本。此处是预算推断，实测后及时修正；
若全部已发现分支预计无法容纳，报告资源不足，不静默删浅谷。
操作性失败按同一 attempt 的 run 编号保留；不把“无带隙/无 candidate”作为程序失败重跑。

## 6. 验收和结论边界

最小必要验证包括：解析几何六行；两侧相同输入退化回单 lead 双方向装配；不同输入散射矩阵确有差异；
衰减方向和 $A_{\rm def}=N_0-LT$；单位圆环带边界；多区间/cache/停止人工目标；正式候选 bypass。
独审应从 raw 数据重建齐次分类、匹配权重与四指标，重建所有 coarse 来源去向、实际轮宽、资源和计时。

`ESTABLISHED`：公共端口、密度缩放和铅笔公式已由本地源码核对；解析三瓣形状符合指定六行约定。
`CONDITIONAL`：只有本次合格机器数据才支持对应点/区间的数值带隙和 finite-matrix candidate。
`PROVISIONAL`：预运行成本与新几何离散充分性，须由本次记录支持。

使结果无效的 blocker 是两侧被复用为同一 lead、镜像/端口/法向错误、分类失败被当 gap、跨档或历史结果混用、
未完成宽度却伪报完成、计算/资源错误。有限网格漏窄谷、带边阈值与 128/256 差异、FMM 及离散未认证是
important caveats；单次负载和采样 RSS 限制是 minor caveats。问题统一登记于 I9 README 的问题账目。
本文件是构造性设计，不能代替独立审查 verdict。研究决策：`GO` 到本目录实现和最小验证。
三方以本轮新建代理实际协作，创建调用采用继承主线程模型与 reasoning effort、没有 override；
工具可见的是创建参数与接受状态，没有独立运行时模型遥测，不能升级成运行时模型身份认证。

## 7. 本次执行结果

正式证据目录为 `test/i9/search-v1/output/attempt-1/run-01/`。以下数字读取本次 `state.json`、
`geometry.json`、`status.json`，候选矩阵位于 `candidate-evidence-0203.mat`；未解决端点证据为
`candidate-evidence-0215.mat`。独立审查对原始记录完成 12,649 项检查及 20 个完整局部轮重组，
结论为 `PASS WITH CONDITIONS`、无 blocker；完整审查依据与限制见
[[research/projects/eig-apost/implementation/i9/review-9-1a|review-9-1a]]。

### 7.1 几何与共同区间

两侧解析几何的采样面积分别为 $0.12566370614359165$ 和 $0.12566370614359179$，目标为
$0.12566370614359174$；中心面积 $0.12566370614359171$。两侧最小速度分别
$0.17536980103985786$、$0.15842360687626789$，中心为 $0.11263251813927816$。
六行周期端点最大绝对差均低于 $3.3\times10^{-16}$；两侧 CCW、正径向图、未镜像。
`geometry.png` 展示中心列、左右各三列及三个 $y$ 周期，左右三瓣均朝同一全局方向。

| 对象 | 本次初始 33 点分类 | 数值段和边界 | 实际缓冲后搜索域 |
|---|---|---|---|
| negative lead | 33 点均 `GAP` | $[1.45,2.25]$，左右均 `WINDOW_TRUNCATED` | $[1.4509999999999998,2.2490000000000001]$ |
| positive lead | 33 点均 `GAP` | 同上 | 同上 |
| common | 两侧交集可用 | 两侧真实带边均未夹住，没有把窗口端点当带边 | 同上 |

本次无需扩窗，也没有实际数值带边二分。初始网格与后续实际点共同支持该探索窗口内的
离散 gap 观察；不能据此补出窗口外带边或精确完整 gap 宽度。

三个代表点均通过 coarse/fine 两侧 `GAP`：

| $k$ | negative 最近圆距离 coarse / fine | positive 最近圆距离 coarse / fine | 两侧散射相对差 |
|---|---|---|---|
| $1.4509999999999998$ | $0.484171386454399/0.484171386454400$ | $0.474369157940247/0.474369157940248$ | $1.13498\times10^{-15}$ / $9.72605\times10^{-16}$ |
| $1.8500000000000001$ | $0.678922704059000/0.678922704059000$ | $0.671489503129561/0.671489503129562$ | $2.66474\times10^{-16}$ / $8.05114\times10^{-16}$ |
| $2.2490000000000001$ | $0.558710047023443/0.558710047023445$ | $0.536514997332750/0.536514997332749$ | $1.09092\times10^{-15}$ / $1.93673\times10^{-15}$ |

这些差说明这三个实际点的 lead 分类没有被本次 128/256 切换改变，不是整个窗口的收敛证明。
相同 lead 退化检查在 $k=1.85$ 得到 $A_{\rm def}$ 和 $A_{\rm phys}$ 差均为零；本次不同 lead 的
完整散射矩阵 Frobenius 差为 $0.018984949413932816$，支持“独立且确实不同”的装配证据。

### 7.2 全部 dip 与候选

共同区间 coarse 网格复用已有 lead 点并补点，共 44 个实际节点。发现一个内部 dip（coarse 采样最低点
$k=1.75$、`aphys_ratio` $0.012763955436209416$），fine 初窗为 $[1.7125,1.7875]$。
该来源完成 19 轮 fine；没有观察到可分辨分裂或消失。另有左端下降，fine 在
$[1.4509999999999998,1.5]$ 做一整轮后保持左边界 winner，记录 `BOUNDARY_UNRESOLVED`。
这不是第二个正常定位 candidate，也没有据此改变探索窗口或强求更多谷。

| 量 | 正常 candidate，source 1 | 未解决左边界暂存点 |
|---|---:|---:|
| $k$ | **$1.7585257790608451$** | $1.4509999999999998$ |
| `adef_sigma` | $9.0787008544125310\times10^{-14}$ | $4.2041574606846313$ |
| `adef_ratio` | $1.5026594195573455\times10^{-16}$ | $0.0069584654758720445$ |
| `aphys_sigma` | $4.5313501077829634\times10^{-14}$ | $1.3730572816349851$ |
| `aphys_ratio` | $1.5831424623043270\times10^{-14}$ | $0.32084496179980937$ |
| 实际整轮 $W$ | $1.9761969838327786\times10^{-14}$ | $0.049000000000000155$ |
| 状态 | fine、末轮第 8/11 点、`COMPLETE` | fine、左端点、`BOUNDARY_UNRESOLVED` |
| bypass 四指标绝对差 | 全部 $0$ | 全部 $0$ |

正常候选两侧各有 97 stable、97 unstable、0 near、0 uncertain、0 indeterminate。
negative/positive 最近圆距离分别 $0.6649474848367948/0.6579082975883048$，QZ residual 分别
$4.562474912417267\times10^{-15}/4.462158235097695\times10^{-15}$；outer guard 均 $10^{-6}$。
negative reciprocal 分类也合格。当前指标远小于 $10^{-10}$ 仅作为工程观察，没有用来提前停止。

| fine 轮 | 实际整轮 $W$ | winner `aphys_ratio` |
|---:|---:|---:|
| 1 | $7.500000\times10^{-2}$ | $1.533360\times10^{-3}$ |
| 4 | $6.000000\times10^{-4}$ | $8.636975\times10^{-6}$ |
| 7 | $4.800000\times10^{-6}$ | $2.848694\times10^{-8}$ |
| 10 | $3.840000\times10^{-8}$ | $2.079845\times10^{-10}$ |
| 13 | $3.072000\times10^{-10}$ | $2.157573\times10^{-11}$ |
| 16 | $2.457590\times10^{-12}$ | $9.783587\times10^{-14}$ |
| 17 | $4.916068\times10^{-13}$ | $2.759038\times10^{-14}$ |
| 18 | $9.836576\times10^{-14}$ | $1.763083\times10^{-14}$ |
| 19 | $1.9761969838327786\times10^{-14}$ | $1.5831424623043270\times10^{-14}$ |

完整 19 轮节点和四指标保留在 `history`/`points.csv`；第 5、8、10、11、13 轮的重复最佳评分没有触发停止。
末轮范围 $[1.7585257790608313,1.7585257790608511]$；实际宽度不是位置误差界。

### 7.3 点数、缓存和互斥时间

| 项目 | coarse | fine | 合计 |
|---|---:|---:|---:|
| 匹配搜索不同 $k$ / 新计算 | 44 | 169 | 213 |
| 完整 bypass 复算 | 0 | 2 | 2 |
| 实际完整匹配点调用 | 44 | 171 | 215 |
| lead bundle 不同 $k$ | 46 | 171 | 217 |
| lead bundle 实际构造（每 bundle 两套独立 lead） | 46 | 174 | 220 |

匹配调度 266 次请求，51 次成功 cache hit，避免 51 次完整点调用；lead 调度 255 次请求，35 次 bundle hit，
直接复用 70 套 side-specific lead 构造。两类节省存在包含关系，不相加成统一节省数或加速倍数。
lead cache 上限 96,000,000 bytes，观测 peak 95,974,095 bytes，169 次淘汰；淘汰后的重复构造已计入实算。
加上普通 ledger 外的相同 lead 检查，两侧散射构造总数为 $2\times220+2=442$，中心构造总数 $215+1=216$。

| 互斥阶段 | 秒 |
|---|---:|
| 两侧 gap 识别 | $25.259358250$ |
| 代表升档和退化验证 | $7.608173917$ |
| common coarse 匹配 | $33.542282917$ |
| fine 分支匹配 | $486.573843833$ |
| 两次 fresh 完整复算 | $5.503827250$ |
| 上述计算合计 | $558.487486167$ |
| MATLAB 入口其余几何/人工检查/调度/保存 | $25.885444333$ |
| 进程其余启停/最终展示 | $18.505038042$ |
| 完整正式进程 | **$602.877968542$** |

MATLAB 入口至最后 checkpoint 为 $584.3729305$ 秒。process-tree 采样峰值 RSS
**1,341,112,320 bytes**，正常 exit 0，无残留；低于 40 分钟/3,000,000,000 bytes 硬上限。
运行环境、命令、逐次资源数据及操作性 setup 记录由实验 README 索引；没有把失败 setup、开发或 Python 独审
并入上述成功科学运行速度。没有 direct 基线，因此不报告本次 FMM 加速倍数。

`ESTABLISHED`（本次记录）：独立两侧几何和散射实现、同 lead 退化、实际点 gap 分类、一个正常候选与
一个未解决边界记录、两次复算及预算内运行。`CONDITIONAL`：共同区间是有限采样数值观察，候选是有限矩阵 dip。
未确定窗口外带边、未证明无遗漏或连续谱结论；没有计算或继承任何 $R_{\rm num}$。

独审保留的 important caveats 包括截断带边和有限采样覆盖、左安全边界下降未解决，以及谷底舍入尺度的
微小起伏不能独立解释为多个模态或误差界。采样 RSS 与单次运行负载限制属于 minor caveat。
这些限制不使当前合格点分类和候选复算失效；统一问题账目放在 I9 README，不另建重复清单。
