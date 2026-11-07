# BIE + DtN mathematical and implementation audit

任务模式：`rigorous-proof` **Review only**。问题是当前 I9.1/I9.2 BIE 候选及其约 $10^{-10}$ 数值半径能支持什么，以及哪些最小失败机制可能推翻过强推论。读取实际实现、原始 JSON 和定理正文；未改原证明或生产代码。模型/版本/原始数据见 [[redteam/baseline/bie]]。

本记录为构造性证据审计，不代替独立Skeptic裁决。结论严格限定为当前被检查的源码和算例；没有因为尚未认证就判定数值候选错误。

## 1. 依赖图和审核对象

连续物理算子 → 半无限衰减Cauchy关系 → 可逆Dirichlet图下的DtN → 中心匹配矩阵 → 奇异值候选。另有独立逻辑链：冻结连续层势场 → 真实材料与人工界面跳跃 → 全界面迹常数与非零场质量 → 谱距离包含。**第二条链不必先证明第一条离散核与全部物理本征场之间满射/单射；它对任意合格的非零trial成立。**

审核范围：`resolvent-bound/s-framework.md` F1–F2，`s-trace.md` T1–T5；I9源码及配置；`+bloch/construct_S.m`、`rayleigh_channels.m`、`+op/construct_A_QP.m`、`+kernel/{precomp_proxy,qpgreen_mfs_pairmat,h2d_directch}.m` 的相关路径。一般有限维线性代数、闭形式表示定理和谱定理按基础结果使用，没有把未读取外部专题定理当成认证依据。

## 2. 十项数学基础核对

| 项目 | 状态及证据性质 | 原始证据、结论与界限 |
|---|---|---|
| 连续算子、定义域、Hilbert空间 | **RESOLVED / ESTABLISHED（此项怀疑）** | `s-framework.md:9–45` 定义 $L^2_\rho$ 中的非负自伴 $-\rho^{-1}\Delta$；全局分布Laplacian和准周期导数配对，未将raw分片场直接放进强定义域。闭形式论证在正有界材料下成立。 |
| Bloch、几何、偏振 | **RESOLVED / ESTABLISHED（源码一致性）** | $e^{\mathrm i\beta d}$，$\beta=.5,d=L=1$；`rayleigh_channels.m:51–58` 的 $\beta_m=\beta+2\pi m/d$。内部 $k_{\rm int}=\sqrt\rho k$。形状与FEM解析式相符；没有观察到 $\rho$ 与折射率混淆。仅针对当前普通导数连续的标量模型。 |
| 界面传输和法向 | **RESOLVED / ESTABLISHED（代数符号）** | `s-framework.md:81–109,153–167`；`estimate_i9_numeric.m:195–212,443–444,481–486`。左人工界面用 $-e_x$、右用 $+e_x$；材料采用外减内值、内减外导数。与Green公式一致。 |
| DtN定义、区间、极点、正则性 | **CONDITIONAL / CONDITIONAL** | `search_i9_physics.m:219–228` 为 $\Lambda_\pm=N_\pm D_\pm^{-1}$；仅在Dirichlet投影可逆时合法。finite-QZ `GAP` 不自动排除半导Dirichlet极点，也不认证连续gap。见B03。 |
| 连续到离散等价 | **OPEN / PROVISIONAL** | `construct_S.m:102–160` 正确保留平方根求积坐标；匹配 $A_{\rm def}=N_0-\Lambda T$ 的有限代数恒等式可核对。Nyström/proxy/Rayleigh截断到连续图的全误差及无漏模态结论未由这些矩阵恒等式建立。 |
| 候选及模态追踪 | **CONFIRMED / ESTABLISHED（算法能力边界）** | `search_i9_run.m:253–270,309–376` 最小化加权最小奇异值比并缩小实际采样区间；同频重算四指标。未用物理场overlap跟踪，未做连续谱计数。窄dip和小sigma不能识别简单模态。 |
| 误差定理、范数、常数 | **CONDITIONAL / CONDITIONAL** | F2及T1–T5在G/U假设下给连续谱距离；证据和公式见B01、B02。程序使用普通数值输入，不能升级成已认证定理实例。 |
| 全部无限端及评价截断误差 | **OPEN / PROVISIONAL** | 有左右独立40胞元前缀和观测尾外推；未提供该固定连续trial剩余无穷端的一侧上界，kernel评价、求积、几何常数和质量的单侧包围也未闭合。有限Rayleigh幅度空间本身可定义trial；若该trial的全部连续缺陷和所需范数已可靠控制，F2不另要求将其DtN逼近误差或被省略幅度逐一界定到精确DtN。连续DtN等价性/无漏模态问题属于上一行的另一个目标。 |
| 矩阵残差是否冒充谱上界 | **RESOLVED / ESTABLISHED（当前源码）** | `estimate_i9_numeric.m:75–98` 用jump公式形成 $R_{\rm num}$ 并明确 `certified=false`、`UNCERTIFIED_RNUM`；没有把 `aphys_sigma` 直接输出成连续谱上界。将此结果解释为“已保证 $10^{-10}$”才是过度推论。 |
| 两路线共享未验证模块 | **RESOLVED / ESTABLISHED（字面共享DtN）**；共同假设 **OPEN** | FEM `refine_i102.m:1917–1985` 用本地FE Schur-QZ；未调用BIE包。不存在直接复用BIE DtN矩阵的证据；共同的模型、图假设、QZ稳定子空间选择仍需独立结构测试。 |

## 3. 可追溯发现

### B01 — 数值半径被解释为严格半径是不成立的推论

**CONFIRMED / ESTABLISHED（声明边界）；不是已确认代码错误。** 原始 `estimate-v1/.../run-01/result.json:2–4,97–102` 输出 `UNCERTIFIED_RNUM`、`certified=false`，$R_{\rm num}=7.745852555568109\times10^{-10}$ 是 $\mu$尺度；换算 $k$尺度约 $2.48513\times10^{-10}$。即便所有普通诊断正确，仍没有无条件包含。

定理要求的单侧数据为

$$
\underline U\le\|u\|_{L^2_\rho},\qquad
\overline\varepsilon\ge\varepsilon_\partial,\qquad
\overline C\ge C_{\rm tr},\qquad
\underline U>\overline C\,\overline\varepsilon.
$$

此时才有

$$
\operatorname{dist}(\mu,\sigma(A(\beta)))
\le\frac{2\mu\overline C\overline\varepsilon}
{\underline U-\overline C\overline\varepsilon}.
$$

代码分别以采样几何（`numeric.m:250–278,281–323`）、普通边界积分和尾外推（174–192,506–514）、局部圆盘求积（617–644）代替这些单侧输入。`geometry.certified=false` 和 `mass.one_sided_certified=false` 与此一致。原始结果有限并不能补上这些资格。

影响：阻止“已获得严格误差保证”，不阻止普通数值证据的使用。最小补充是固定同一场验证主要连续jump评价和kernel误差，不先重新求更好candidate。若只做数值路线决策，应保留原状态并采用独立场/参数不变量测试。

### B02 — 残差定理主推导在其明确假设下没有发现反例

**CONDITIONAL / CONDITIONAL；局部论证已逐步核对。** 在正有界材料、实准周期参数、G统一collar以及U分片正则性/平方可积性/精确分片PDE下，F1由分片Green公式得到原始jump恒等式。截断项控制明确使用 $u,z,\nabla z\in L^2$ 及平方可和界面迹，不暗设端面通量逐点为零（`s-framework.md:169–205`）。

T1通过准周期Fourier变换得到 $\|D^2v\|_2=\|\Delta v\|_2$，T2正移位控制不依赖未知谱隙，T3的一维迹不等式和T4重叠计数给出全界面常数；T5仅在实际几何证书成立时提供collar单射。代码在 $d=1$ 使用的常数与T9一致。

F2使用 $z=(A-\mu)^{-1}u$，由谱定理
$\|(A-\mu)^{-1}\|=1/\operatorname{dist}(\mu,\sigma(A))$，再移项得上式；这里不存在以待证误差界为假设的循环。F2只产生谱集合距离；升级为gap中离散特征值、特定编号、简单性或唯一性需要独立证据（F2末尾300–307行明确说明）。

最弱环节在其数值实例输入，特别是 exact-kernel field 和普通代理核评价的桥接，而不在已检查的代数移项。无法认证输入时，最小降级为 ordinary diagnostic，不必宣布F2错误。

### B03 — 带隙不能代替DtN图正则性，当前搜索缺少显式图敏感性门

**CONFIRMED / ESTABLISHED（一般推论被反例否定）**：有限稳定空间已与单位圆分离，不代表Dirichlet投影可逆。最小代数例子取稳定向量 $(1,-1)^\mathsf T$、不稳定向量 $(1,1)^\mathsf T$，乘子分别 $1/2,2$。其稳定Dirichlet迹 $D=A+B=0$，Neumann迹 $N=\mathrm i\gamma(A-B)\ne0$，不存在单值DtN图。这反驳“QZ判GAP便可无条件取DtN”，不构成当前物理算例反例。

**SUSPECTED / PROVISIONAL（实现健壮性）**：BIE `search_i9_physics.m:219–228` 计算并记录 `rcond(Dp/Dm)`，但本函数不使用阈值拒绝近极点；`numeric.m:406–412` 的固定估计图求逆也没有显式阈值。MATLAB奇异/近奇异警告被提升为异常（`physics.m:234–240`、`numeric.m:712–718`），所以不能声称完全无保护；警告阈值和较小矩阵残差仍不构成连续图敏感性控制。当前两lead的finite-QZ distance很大，**没有证据证明当前候选就在极点附近**。

最小检验：固定物理问题，把端口平移一个可行的小距离，以共同Cauchy关系而非单一Dirichlet图比较；同时记录图最小奇异值、全stable projector差和候选场。遇到Dirichlet节点应改用互补图/关系测试，不能靠自动排除问题点来宣称无漏模态。

### B04 — 相邻尾比不足以给全无穷尾上界

**CONFIRMED / ESTABLISHED（一般推论无效）**；当前尾是否有显著误差 **OPEN**。`numeric.m:174–192,506–514` 用 $e_{41}/e_{40}$ 作为几何比，并返回 $e_{41}/(1-r)$；没有证明后续每项比例不超过 $r$。例如 $s_n=4^{-n}+\eta(0.99)^n$，当第二项尚未显现时，相邻比可接近 $1/4$，而最终慢模态的尾远大于该比外推。非正规/Jordan推进还可有多项式因子或暂态增长。

当前原始ratio约为0.142208、0.147407，尾数值极小；这是有利数值证据，不支持夸大为“尾一定造成当前误差”。最小补充：以保存的完整 $P_\pm$ 和jump Gram矩阵独立计算Stein和，并以矩阵幂收缩或Lyapunov余项作一侧上界；还需把有限维场映射到连续积分，不能止于普通Stein求解残差。

### B05 — 外部准周期接缝很小不独立验证代理核

**CONFIRMED / ESTABLISHED（周期化结构及可复现数值现象）；连续核评价误差界及候选影响 OPEN。** `qpgreen_mfs_pairmat.m:87–89,116–121` 通过折回再乘相位定义核；原proxy只在有限collocation点最小二乘匹配（`precomp_proxy.m:105–106,120–121,145–152`）。非平局点的 $G(y+d)=e^{\mathrm i\beta d}G(y)$ 可由折回直接保证，而基础核在折回两侧的连续性及导数匹配仍依赖有限代理近似。

I9.2 `numeric.m:54–67` 将上下接缝只列为数值一致性诊断，不加进 $\varepsilon$。若连续trial明确使用**精确准周期核**，理论上为零是正确的；需要补的是数值核评价到那个精确trial的误差包围。若改将**字面周期化MFS核**定义为trial，必须控制折回线及proxy/plane-wave切换线的分片缺陷，不能沿用原U假设直接令其全为零。

最小实验已预登记并由根代理在 MATLAB 执行，见 [[redteam/cases/qp-wrap/case]] 和 `redteam/results/qp-wrap/attempt-1/result.json`。79/157两组网格的raw梯度差max为 $1.33192\times10^{-10}$/$9.59085\times10^{-11}$，Hessian差max为 $1.08518\times10^{-8}$/$1.26446\times10^{-8}$；外部接缝三项差均为0。实际内部wrap梯度跳跃与预测在三个步距上相符到 $1.60\times10^{-15}$。Hessian两组超过预登记筛查阈值；梯度只一组超过，不能说两组梯度筛查均命中。此现象只在核近似层得到确认，不能直接换算成候选波数误差或证明 exact-kernel trial 不合法。

### B06 — 连续层势、离散点源和离散矩阵必须区分

**CONDITIONAL / CONDITIONAL。** F2的raw场在 `s-framework.md:91–92,113–126` 明确为冻结连续密度的 exact-kernel 层势。`numeric.m:564–567` 用trigonometric interpolation表达固定密度，再用求积评价它。字面的有限Nyström点源和不能无条件替代该连续场：double-layer点源邻域可有 $1/r$ 奇性，二维平方积分可能发散；Kress边界作用也不等于这种字面点源场的普通边界极限。

这不表明既有推导犯了该错；源文定义排除了这个替换。它约束redteam自己的场重建：必须记录连续密度插值、近界面求积与样点排除，不能因若干安全点重合就宣布得到合格连续trial。

最小修复建议：不改生产场，明确其连续数学定义；在同物理区域采用可复核的连续层势评价，并单独报告界面近场误差。若只能比较安全点，结果只标采样场一致性。

### B07 — 现有候选搜寻不足以排除近简并、漏模态和伪模态

**OPEN / PROVISIONAL。** 搜索最小奇异值，保存competitor trace及singular gap（`physics.m:193–216`），但 `run.m` 的候选选择不使用物理模态重叠或子空间。它可以给稳定数值候选，不能证明全窗口全部根已找到。细网格全宽是采样分辨率，非连续本征值隔离证据；原结果已保留右端未解决趋势，没有伪称完备。

最小下一步就是本任务的场/衰减子空间比较。若与FEM重叠接近1，仍需共同非零场、连续残差和隔离/计数信息来区分同一简单模态、同一簇及共同修改问题。不得把某一条路线当作另一条真值。

## 4. 准确的共享风险边界

“两条路线共用同一个未验证DtN代码”在当前I10.2不成立。BIE用散射幅度铅笔，FEM用FE Schur补的二次铅笔；FEM当前文件没有BIE包调用。两者均用复QZ稳定子空间及Dirichlet图，但不是同一个矩阵或同一数值截断。两者解析形状相同是物理一致性要求，不是独立验证的全部。

仍可能共享：材料/偏振定义的错误解释、Bloch相位方向误设、半导图合法性误推、把finite-QZ分类当连续带隙、只看单个近零特征量而漏簇。对这些共同逻辑风险，精确可解模型、切口不变量、正反向衰减配对和子空间比较更有辨别力。

## 5. 交接与未完成项

构造性决定：**GO**，进入固定场比较及已预登记最小机制实验；**尚不能 GO 到“严格同精度性能比较”**。这里没有确认当前candidate错误，也未确认任何根本性数学漏洞。

1. B01是已确认的证据等级边界；任何“已认证”下游声明必须降级。
2. B02是条件定理，弱点在真实输入资格；若这些资格无法建立，定理仍保留，实例退回普通指标。
3. B03–B05给出可决胜的机制；toy反例只否定一般推论，生产故障必须由当前输入再现。
4. B06约束独立场重建的定义，避免审计本身制造不合法trial。
5. B07待mode identity报告与隔离信息补充。

审查完成记录：目标为上述F/T命题的Markdown正文；只在本任务新报告和新诊断文件写入，无原证明环境、标签或公式修改。没有下载外部文献，没有宣称核验外部论文定理编号；连续DtN表示满射及谱gap的全面外部文献适配仍未完成。因此整体文献状态为 **Preliminary review; literature verification is incomplete.** 原文完整性由根代理的任务末端工作区检查统一核对。

检查：直接读源码及原始JSON；以项目Conda Python重算一次 $\mu\to k$ 换算；该环境的MAT读取以 `ModuleNotFoundError: No module named 'scipy'` 退出，未进入数值分析，不属于反例。子代理未自行启动MATLAB/Octave；根代理已监控执行新的 `probe_qp_wrap.m`，本子代理亲自读取新结果。该探针0.449秒；与精确机制同进程的完整墙钟14.704秒、采样峰0.928GB、退出0。`checkcode`及整体文件边界检查由根代理统一完成。
