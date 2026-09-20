# I6.1a 首轮预解式谱距离实验设计

## 任务时限与写入边界

实际起点：2026-09-18 13:14:06 UTC（北京时间 21:14:06）。
绝对截止：2026-09-18 16:14:06 UTC（北京时间次日 00:14:06）。
最迟 15:59:06 UTC 进入最后十五分钟的审查与交付；所有讨论、编程、运行、重跑都计入
同一三小时窗口。本轮开始已确认工作树为 `/Users/whc/Documents/Work/epost`、分支
`codex/epost`，不切换 main，不提交 Git。

每次完整科学运行的硬限为 2700 秒和进程树合计 3,000,000,000 bytes RSS，无宽限。
各阶段共用一次预算；错误修复后的重跑使用同 attempt 的下一 run，但不重置全局时限。
启动前要有完整计算的时间与内存估计，运行中保存进度和资源记录。

唯一可写位置是 `test/i6/resolvent-v1/`。主 agent 拥有本设计、README 和 review；
Engineer 拥有 MATLAB 源码、局部辅助程序、运行配置、源码快照及结果。Researcher 和
Skeptic 只读。所有代理已收到相同截止时间、资源上限和文件所有权。
不修改 i5、公共 package、理论、draft、参考文献或上级维护文档。

## 目标与数学合同

权威是当前磁盘上的 `resolvent-bound/` 五文件，特别是 T4、T9--T10、F14 和 N1--N9。
固定同一 candidate、实 $\beta$、几何、材料、密度、中心状态以及完整 $P_\pm,c_\pm$。
不重新搜索 candidate，不构造 lift。计量对象为 actual paired value jump 与普通法向
导数 jump 的 $L^2$ 范数，分母对象为同一 raw 场的质量范数。

选择明确长度 $\ell_*$，按 T9--T10 形成

$$
\varepsilon_{\partial,\ell_*}^2
=\sum_{\Gamma\in\mathscr E}
(\|j_\Gamma\|_2^2+\ell_*^{-2}\|a_\Gamma\|_2^2),\qquad
\overline Q=\overline C\,\overline\varepsilon_{\partial,\ell_*}.
$$

定义

$$
D=\underline U-\overline Q,\qquad
R_{\mathrm{spec}}=
\frac{2\mu\overline Q+\overline\varepsilon_{\mathrm{vol}}}{D}.
$$

只有 $D>0$ 且相应假设适用时才报告有限谱距离估计。值/法向缺陷、singleton、有限胞元
与无限尾分别保存。精确 PDE/QP 必须从冻结连续表示核对；非零时增加对应项。
保留全部 $P_\pm$，不使用独立标量模态简化。

首选最短基线：重新形成 signed-row 的 $L^2$ 控制量，使用完整矩阵块幂尾；raw 质量
从有限安全区域得到下界。旧负阶法向总量及旧 $B_{\mathrm{lift}}$ 不作为新范数输入。
具体科学输入、分辨率和完整运行预测由实现检查后在本文件追加，并保存为代码配置；
文档本身不充当运行授权或参数文件。

## 运行与诊断规则

- 同一数学方案的路径、字段、维数、符号、缓存或等价分块修复，沿用 attempt，创建新 run。
- 修改科学分辨率、截断、collar、质量区域或评价方法时，新建 attempt，并记录发现、原因、
  改动及保持不变的冻结对象；预先声明的自适应规则按其合同运行。
- 每次 run 保留失败日志、实际配置和源码版本证据，不覆盖历史失败。
- 不因宽界或分母首次非正停工；先分清实现错误、缺少项、相消损失、质量下界弱或真保守性。
- 不删除正误差项，不设未知尾为零，不把采样最大值当连续上界，不取分母绝对值。
- 完整单侧认证不是启动门。结果分别标识可靠包围、特殊函数/舍入层未覆盖的非认证理论
  公式评价，以及仅诊断性经验量；三者不得混用。

## 验收检查

保存 candidate 和 frozen-field identity 的显式科学字段，检查 NaN/Inf、非负性、尺度、
界面归属、完整传播尾、raw 质量、分母及最终区间代数。近零量的相对变化不单独构成
失败门，使用绝对变化及其对最终界的影响判断。

入口只接受明确科学输入/配置和 MATLAB 依赖，通过正常 MATLAB path 解析，不读取
Markdown、README、Git、哈希或历史最终结果。辅助 launcher 可以记录资源和出处，
不得改变计算的科学对象。最后由 Skeptic 独立审查源码和实际结果；不声称离散特征值
存在或唯一，除非另有同一算子的独立带隙依据。

## 同一 raw 场的中心质量：局部解析推导

Researcher 已核对当前冻结实例中心为空列。i5
`signed_wall_center_v7.m` 中 `q_center` 的前后两段分别给出左右锚定 Rayleigh
振幅，其值迹为 $q_L+Eq_R$、$Eq_L+q_R$；这与旧输入的中心坐标定义相同。
本段是本实验内新增的局部推导，不修改原理论。

令 $w=X_R-X_L$，$\psi_m=d^{-1/2}e^{\mathrm i\beta_my}$，则中心场为

$$
u(x,y)=\sum_m\psi_m(y)
\left(q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}
+q_{R,m}e^{\mathrm i\gamma_m(X_R-x)}\right).
$$

**中心质量引理。** 在已核对的空中心、常数材料 $\rho_e$ 情形，设

$$
\begin{array}{c|cc}
&A_m&B_m\\\hline
\gamma_m\in\mathbb R\setminus\{0\}&w&\sin(\gamma_m w)/\gamma_m\\
\gamma_m=\mathrm i\kappa_m,\ \kappa_m>0
&(1-e^{-2\kappa_mw})/(2\kappa_m)&w e^{-\kappa_mw}\\
\gamma_m=0&w&w
\end{array}
$$

则

$$
U_{\mathrm{cen}}^2=\rho_e\sum_m
\left[\frac{A_m+B_m}{2}|q_{L,m}+q_{R,m}|^2
+\frac{A_m-B_m}{2}|q_{L,m}-q_{R,m}|^2\right]
\le\|u\|_{\mathcal H}^2.
\tag{C1}
$$

**证明。** 在完整横周期积分时，归一化 $\psi_m$ 的正交性消去不同模态的交叉项。
每模沿 $x$ 的两个对角积分均为 $A_m$，交叉积分为实数 $B_m$。
展开右侧的和、差平方即等于该 $2\times2$ Gram 二次型。
其本征值 $A_m\pm B_m\ge0$；中心之外的质量非负，故为全场质量下界。证毕。

实现使用 `expm1` 和零附近的连续极限减少消去，保存每模贡献及最小
$A_m\pm B_m$。不允许无条件将负贡献截断为零来掩盖错误。
解析公式在精确算术下是下界；普通浮点评价值尚未向外包围时明确标为非认证评价。
此选择不改变 raw 场，也不需要求解全波导辅助场 $z$。

### 本实例的中心材料归属

Skeptic 独立确认当前冻结实例为 empty center。故中心材料 singleton 为空；材料的
左右序列从 $G_\pm c_\pm$ 开始。$q_{\mathrm{center}}$ 只用于中心质量和两条中心/首胞
人工墙。旧 i5 material assembly 中把 `q_center` 放入中心圆行状态列表的历史做法
不能直接移植为本实例实际材料界面。本轮按物理分区重新记账，不制造中心 inclusion，
也不把删除一个不存在的界面贡献包装为缩小误差项的科学优化。

## L2 高模尾：本实验的局部公式转换

以下从现有 i5 系数包围重算无权 $L^2$ 尾，而不复用其负阶最终量。
Researcher 给出推导，Skeptic 检查实现的参数单位与常数归属。记材料周长为
$p_\Gamma$，弧长正交 Fourier 系数为
$\widehat f_m=p_\Gamma^{-1/2}\int_0^{p_\Gamma}f(s)
e^{-2\pi\mathrm i m s/p_\Gamma}\,\mathrm ds$。

### 材料 local 和 strip 尾

若周期完整行 $F$ 的第 $p$ 阶导数满足
$\int\|\partial_s^pF(s)\|_{\mathrm{op}}\,\mathrm ds\le Q_p$，积分分部给

$$
|\widehat{Fx}_m|
\le\frac{Q_p}{\sqrt{p_\Gamma}}
\left(\frac{p_\Gamma}{2\pi|m|}\right)^p\|x\|_2.
$$

因而对整数 $M_{\mathrm{mat}}\ge1$，

$$
T_{\mathrm{loc},p}^2
\le\frac{2Q_p^2}{p_\Gamma}
\left(\frac{p_\Gamma}{2\pi}\right)^{2p}
\left(M_{\mathrm{mat}}^{-2p}
+\frac{M_{\mathrm{mat}}^{1-2p}}{2p-1}\right)\|x\|_2^2.
\tag{C2}
$$

最后一步由正整数尾的首项加积分界得到。已有 $p=2,4$ 分别包围同一 local 尾时可取
较小者。`local.derivative_certificate.nor.Q2/Q4` 是法向行对应的来源字段；实现必须
保留其输入坐标归一化。不能在有限部分改用实际状态、却在尾中混用另一种 density 范数。

若已有 strip 证书给
$|\widehat{Fx}_m|\le\sqrt{p_\Gamma}A e^{-\zeta|m|}\|x\|_2$，$\zeta>0$，则

$$
T_{\mathrm{strip}}^2
\le\frac{2p_\Gamma A^2 e^{-2\zeta M_{\mathrm{mat}}}}
{1-e^{-2\zeta}}\|x\|_2^2.
\tag{C3}
$$

弧长 strip 半宽 $a_s$ 对应 $\zeta=2\pi a_s/p_\Gamma$；角参数 strip 半宽
$a_t$ 对应 $\zeta=a_t$。必须按实际输入字段转换，不能混用长度与角度。
local、regular-image、off-surface 属同一跳跃，三项先各开平方再相加。
状态能量只包括实际存在的左右材料序列，不含空中心的 $q_{\mathrm{center}}$。

### 人工墙高模尾

墙保留 $|m|\le256$ 时，遗漏从 $m_0=257$ 开始。令
$q_0=2\pi/d$、$b=|\beta|$、$k_e=\widehat k\sqrt{\rho_e}$，
$\delta>0$ 为真实材料到墙距离下界，$r=e^{-2\delta q_0}$。定义

$$
\begin{aligned}
S_0&=\frac{r^{m_0}}{1-r},\\
S_1&=r^{m_0}\left(\frac{m_0}{1-r}+\frac{r}{(1-r)^2}\right),\\
S_2&=r^{m_0}\left(\frac{m_0^2}{1-r}
+\frac{2m_0r}{(1-r)^2}+\frac{r(1+r)}{(1-r)^3}\right).
\end{aligned}
$$

若已有完整行的 density envelope 为

$$
|j_m|\le\frac{e^{-\delta\kappa_m}}{2\sqrt d}
(2\kappa_m A_\tau+A_\sigma),
\qquad \kappa_m=\sqrt{\beta_m^2-k_e^2}>0,
$$

利用 $\kappa_m\le q_0|m|+b$ 及
$\kappa_m\ge q_0|m|-b-k_e$，两侧高模的平方和不超过

$$
C_{j,\mathrm{high}}^2
=\frac{e^{2\delta(k_e+b)}}{2d}
\left[4A_\tau^2(q_0^2S_2+2q_0bS_1+b^2S_0)
+4A_\tau A_\sigma(q_0S_1+bS_0)+A_\sigma^2S_0\right].
\tag{C4}
$$

因子 $1/(2d)$ 已含正负两侧。值行使用
$b_0=q_0m_0-b-k_e>0$、$R_\beta=1+k_e/b_0$ 和
$C_a=e^{\delta(k_e+b)}(2R_\beta A_\tau+A_\sigma/b_0)/(2\sqrt d)$，得到

$$
T_{a,\mathrm{high}}^2\le2C_a^2S_0.
\tag{C5}
$$

最后整个值缺陷平方再乘 $\ell_*^{-2}$。有限 flat density 在上述遗漏模外为零须由
输入支持检查确认。singleton 使用自己的实际首胞 density envelope；内部墙使用
包含 $G_\pm,G_\pm P_\pm$ 的完整 paired row envelope，再对外部 $P_\pm^nc_\pm$
按 N7 求和一次。两种位置的传播因子含义不同，不省略也不重复施加。

所有公式是连续尾的解析界；用普通浮点形成常数时，特殊函数和舍入的未覆盖层单独
标注，不把它们静默设成零。

## Attempt 1：首轮冻结合同

13:27 UTC 前的输入核对得到以下原始科学对象（最终以 run 保存的显式配置和
identity 字段为准）：

| 参数 | 冻结值 |
|---|---:|
| $\widehat k$ | 1.832770289108157 |
| $\mu$ | 3.3590469326375971 |
| $\beta$ | 0.5 |
| $d,L$ | 1, 1 |
| 背景 inclusion 半径 $R$ | 0.2 |
| $\rho_e,\rho_{\mathrm{disk}}$ | 1, 17 |
| $X_L,X_R$ | -0.5, 0.5 |
| 双侧 collar $h$ | 0.04 |
| $\kappa_*,\theta,N_{\mathrm{ov}}$ | 5, 0.8, 1 |
| $\ell_*$ | 1 |
| 单侧状态维数 $K$ | 97 |

原始冻结输入是 `test/i3/e-cap/input/fbie-a1-certificate.mat`，由 i5 输入合同引用；
本轮仅读其科学数据，不重新求解。Engineer 将必要的 signed rows、连续误差常数和
曲线合同作为显式科学输入传给新入口，不读取旧最终 estimator 或历史报告。
本目录中有效入口接收 `input/frozen-candidate.mat` 和
`input/i5-v7-attempt6-signed-rows.mat`。首 run 曾误选未通过的旧 attempt-7 包
`input/i5-v7-signed-rows.mat`，在输入检查处失败，详见审查记录；两者均保留。
行包提供行级评价数据及连续误差常数，不提供新的
raw 场；新入口比对候选频率、圆几何、密度 Fourier 系数、模态范围和完整传播块证书。
所有场状态、传播矩阵及中心质量均取前者。输入核查阶段曾只读查看 MAT 的 schema、
字段和冻结标量，未进行另一轮候选搜索或完整科学评价。

首轮预计 2--4 分钟、进程树峰值少于 0.8 GB；使用 $J=16$ 个有限胞元、完整
$P$ 的块长 32、人工墙保留 $|m|\le256$、材料值和法向均保留 $|m|<1024$。
13:30 UTC、首次科学运行之前，确定两类材料跳跃统一采用 v7 signed Fourier 行及
完整解析高模尾。该选择复用同一个 raw 场，避免再引入另一套 RI 常数包，属于
attempt 1 启动前的完整配置冻结。所有程序修复保留 run 证据；启动后的科学配置
变化仍须按 attempt 规则处理。

圆形是当前冻结实例的已知几何，不是把一般理论的 inclusion 假设改为圆形。
圆 collar 的内半径 $R-h>0$；圆之间间距和圆到人工墙距离大于 $2h$，
竖墙之间间距也大于 $2h$。故此实例的 collar 单射与不重叠可直接从有限几何参数
验证，不必数值求 reach。使用点窗口 $I=[\mu,\mu]$ 评价 T9。

此时 $c_0=N_{\mathrm{ov}}/(\theta h)$、
$c_1=N_{\mathrm{ov}}h/(2\theta)$，直接评价

$$
\overline C^2=
\frac{c_0}{\rho_{\min}\mu^2}
+\frac{c_1+\ell_*^2c_0}{4\mu}
+\ell_*^2c_1\rho_{\max}.
$$

曲率只进入 collar Jacobian；材料上下界进入体范数估计。不依赖未知谱距离、
未知精确特征函数或另解一次无限波导预解式。$\ell_*=d=1$ 是本实例尺度选择，
并非忽略值与导数的量纲差异；值缺陷始终同步乘 $\ell_*^{-2}$。

### PDE 与准周期缺陷的依据

`implementation/i3/design-3-1f.md` 的连续场定义使用有限三角 density 配合精确
准周期层势核（原文第 123--143、175--183 行），并在第 277--283、293--309 行
说明对应的 Bloch 拼接及逐片 Helmholtz 性质。Researcher 本轮只读核对此定义与
冻结输入。故本轮的科学对象是由这些有限系数定义的精确连续 raw 场；其体内与
上下准周期缺陷为结构性零。MATLAB 对迹、行及常数的数值评价不是重新定义一个
截断核 raw 场。特殊函数与舍入的单侧包围仍未建立，因而最终数值只称非认证的
理论上界公式评价，不把上述结构性零当作浮点误差已经被控制的证据。
