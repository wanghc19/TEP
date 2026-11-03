# BIE 路线状态：既有记录核查

## 目的

本次判断的目标是：在内谱隙中交付一个至少含一个点谱特征值、以 $\mu=k^2$ 计全宽约 $5\times10^{-9}$ 的保证区间。唯一性不是总目标；直接 FEM＋Goerisch 的命题 1 才额外使用隔离假设 (H)。现行总结明确保留了这个区别，并称 BIE 已有“精度达标的估计”。本报告核查“估计”能否升级为目标中的“保证区间”。[方向总结:487–490](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/README.md:487)

**结论：当前星形中心、左右不同三瓣形引线的 BIE 数值估计全宽为 $1.54917\times10^{-9}$，但尚无对应可靠界。题述 $2.42\times10^{-4}$ 来自 FEM＋DtN 的 I9.6 源重构，且其无条件上界资格仍受 B3 限制。较早圆形模型确有可靠 BIE 全谱距离证书，全宽约 $3.30\times10^{-7}$；它既不是当前模型，也没有完成点谱存在所需的本质谱排除。** 各项原文与前提见下表；这些区别会改变是否继续投入 (H) 的决策。

检索范围：项目及总研究 STATUS、DECISIONS、implementation 的符号表/open-problems/I6–I10 README 与审查、相关理论、test/I6–I10 README，以及 numerical-directions 的阶段记录；按数值、`Rnum`、`Rspec`、`B3`、`certified`、BIE 主线/替代/外部参照等词追踪。未运行 MATLAB，未读取大型 MAT；本文宽度换算仅为既有半径乘二或既有端点相减。

## BIE 结果及保证形式

以下 $R$ 均为 **$\mu$ 谱距离半径**，$W=2R$ 为全宽；候选搜索窗口宽度另列，不能混入误差半径。模型与保证形式都必须一起比较。

| 数值 | 来源 | 保证形式及原文 | 前提条件／尚缺的输入 |
|---|---|---|---|
| **当前 I9.2**：$k=1.5584378941820909$；$R_{\rm num}=7.745852555568109\times10^{-10}$，故 $W_{\rm num}=1.5491705111136218\times10^{-9}$ | [I9.2 数值:73–84](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:73)；模型为中心 $\rho=4$ 星形、左右 $a=0.12/0.20$ 三瓣形、引线 $\rho=17$，[配置:9–19](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:9) | **谱距离数值估计，无保证。** 原文：“结果是 `UNCERTIFIED_RNUM`，不是可靠上界、残差范数或实际特征值误差。”[原文:4–5](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:4) | 使用下述 F14 形式，但曲线几何、求积、FMM 误差及观察比率尾均未认证；只有一个评价网格。$U_{\rm num}$ 是局部背景圆盘范数的普通评价，尚非可靠下界。[质量:17–18](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:17)、[尾:102–106](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:102)、[限制:154–164](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:154) |
| **较早 I6 v2**：$\mu=3.3590469326375971$；$R=4.0547573451465766\times10^{-9}$，故 $W=8.1095146902931532\times10^{-9}$ | [I6 v2:9–20](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v2/README.md:9) | **上界公式的未认证数值评价。** 原文：“这是 resolvent 理论谱距离上界公式的普通浮点评价，未认证”。这个约 $4\times10^{-9}$ 是半径，按本任务全宽标准尚大于目标。 | 连续核／求积余项已有数学公式，但特殊函数、组装、相消、传播／迹常数与质量的舍入未作单侧包围。[限制:120–129](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v2/README.md:120) |
| **较早 I6 v3，圆形模型**：$R\le1.64933909531673\times10^{-7}$；向外区间 $[3.359046767703687789,3.359047097571506853]$，其全宽 $3.29867819064\times10^{-7}$ | [I6 v3:76–93](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:76)；圆形介质 $\rho=17$、半径约 $0.2$，[精确输入:14–18](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:14) | **可靠全谱距离上界。** 原文状态为 `CERTIFIED_SPECTRAL_DISTANCE_UPPER_BOUND`；“该区间与全谱相交；没有带隙认证，因此不作离散特征值存在、唯一性或编号声明。”[状态:68–74](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:68)、[范围:92–93](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:92) | 固定有限输入定义同一精确场；完整准周期核、传播收缩、连续与无限余项、质量下界及最终公式均作 Arb 包围，依赖库的包含性合同和正常硬件执行。[合同:20–27](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:20)、[独审:156–179](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i6/review-6-1c.md:156)；尚缺本质谱排除才能交付点谱存在。 |
| **较早 I8，另一星形模型**：中心512／引线256；评价512／768时 $R=4.0165490283803493\times10^{-10}$／$7.0521608619273644\times10^{-10}$，全宽约 $8.03310\times10^{-10}$／$1.41043\times10^{-9}$ | [I8 数值:49–64](/Users/whc/Documents/Work/dot-research/test/i8/estimate-v1/README.md:49)；等面积缩放星形中心 $\rho=2$、圆形引线，[模型:33–35](/Users/whc/Documents/Work/dot-research/test/i8/fmm-est-v1/README.md:33) | **数值估计。** 原文：“None of these quantities is a certified spectral bound.”；区间继承 `uncertified` 身份。[原文:39–40](/Users/whc/Documents/Work/dot-research/test/i8/estimate-v1/README.md:39)、[区间:58–64](/Users/whc/Documents/Work/dot-research/test/i8/estimate-v1/README.md:58) | 两档评价含原生节点与非原生节点的混合，不能充当独立评价网格收敛测试。[解释:66–70](/Users/whc/Documents/Work/dot-research/test/i8/estimate-v1/README.md:66)；不能将其更小数值转移到 I9 的不同材料和引线。 |
| **I8 同场 FMM／直接评价**：768点时 $R=7.0632274130478178\times10^{-10}$／$7.06045248570906\times10^{-10}$ | [I8 FMM:102–110](/Users/whc/Documents/Work/dot-research/test/i8/fmm-est-v1/README.md:102) | **数值估计及后端一致性检查。** 原文：“Both results have positive denominators and status `UNCERTIFIED_RNUM`.” | 只在同一固定场上切换光滑 proxy 评价后端，不重新求场；保留上述 I8 模型与未认证限制。[入口说明:9–20](/Users/whc/Documents/Work/dot-research/test/i8/fmm-est-v1/fmm_est_i8.m:9) |
| **I9.6，实际为 FEM＋DtN 源重构**：控制层 $R_\mu=1.2104310\times10^{-4}$，$W=2.4208620\times10^{-4}$；主层 $R_\mu=4.4511618\times10^{-4}$，$W=8.9023236\times10^{-4}$ | [实际审查数表:218–241](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/review-9-6a.md:218) | **有剩余资格条件的公式评价；现有审查未确认其可靠上界身份。** 实验 README 声称 `EXACT_ARITHMETIC_UPPER_BOUND`，[README:8–12](/Users/whc/Documents/Work/dot-research/test/i9/dtn-bound-v1/README.md:8)；后续独审明确收窄为“下列为有明确剩余资格条件的公式评价值；尚不是本审查确认的原无限算子谱距离上界。”[独审:193–202](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/review-9-6a.md:193) | 定理 2 的单侧输入、同场条件及正分母必须成立；实际 bulk 源矩积分的 B3 资格仍开着，浮点舍入也未认证。它不是 BIE 输入路径，见下一节。 |

这些表中数值都能追到具体报告，但保证强度不同。尤其 I6 v3 已完成的可靠结果不能遗漏；其较宽值也不能被解释成 BIE 在当前目标下的精度下限：v3 为预算选用 $N=280,Q=10$，而 v2 用 $N=1026,Q=32$，当时达到的是 $10^{-6}$ 目标，没有继续收紧。[I6 配置及停止原因:130–136](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:130)

**BIE 上界真正依赖的条件。** F2/F14 要求：正且有界的材料权重；统一、可核验的曲线 collar／曲率／重叠常数（假设 G）；同一非零 $L^2_\rho$ 分片 $H^2$ 场，分片 PDE 和准周期匹配成立、全界面跳跃范数有限（假设 U）；以及可靠输入 $\underline U\le\|u\|_\rho$、$\bar\varepsilon_\partial$、$\bar C$，满足 $\underline U>\bar C\bar\varepsilon_\partial$。若有体内缺陷还须加入其上界。定理给出

$$
\operatorname{dist}(\mu,\sigma(A))\le
\frac{2\mu\bar C\bar\varepsilon_\partial+\bar\varepsilon_{\rm vol}}
{\underline U-\bar C\bar\varepsilon_\partial}.
$$

这里没有预先使用模态计数、孤立窗口或待求谱点的分离常数。迹定理明写“本结果不要求该窗口是谱隙”；F14 后又明写只有区间严格落在同一算子的本质谱空隙中，才能推出孤立有限重特征值。[G 与材料条件:5–47](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace.md:5)、[U:113–129](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:113)、[F2/F14及点谱条件:249–307](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:249)

**其余参考数值核对。**

| 题述参考 | 核对结果与来源 |
|---|---|
| P3/RT3 命题 1 全宽 $4.70\times10^{-9}$，需 (H) | 确认。推荐平方积分值为 $4.69595266302784\times10^{-9}$，区间 $[2.4287286689238803,2.4287286736198332]$；现有计算为普通浮点，谱隙端点未认证。[实验:5、19–22](/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v3/README.md:5)、[命题对照:194](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/goerisch-width.md:194) |
| 同场命题 5 全宽约 $1.00\times10^{-4}$，无 (H) | 确认，更具体为 $1.003\times10^{-4}$。命题 5 只给与全谱相交；点谱仍需排除该区间内本质谱。[命题:163–169](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/goerisch-width.md:163)、[数值:194](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/goerisch-width.md:194) |
| R/RT3 全宽 $1.89\times10^{-7}$ | 确认，固定 v2/run-003 值为 $1.88632275544841\times10^{-7}$。这里 R 是重构试探场＋Goerisch，不是 BIE 路线。[实验表:17](/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v3/README.md:17) |
| “I9.6 BIE/DtN 可靠界 $2.42\times10^{-4}$” | 数值作为控制层 **$\mu$ 全宽**成立；方法与保证标签均须更正为上表所列 FEM 源重构、B3 未闭合的公式评价。[独审:202、229](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/review-9-6a.md:202) |

## I9.6 界的前提（与 (H) 的关系）

**没有隐藏的 (H)、谱点计数、单重性、带隙端点或目标谱点分离常数。** 理论原文：“candidate 不重新求解，BIE 不进入源、常数、参数选择或验收。本稿不要求已知附近谱点个数、特征值单重性、谱隔离圆或带隙下端。”决策记录也明确：“BIE data, a spectral count, and spectral isolation are not estimator inputs.”[理论:27–31](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound.md:27)、[决策:48–54](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/DECISIONS.md:48)

它实际需要下列输入资格：

1. 固定 FEM 场经有限硬截定义合法的 $L^2$ 输入 $u$；网格映射、覆盖及索引须定义几乎处处唯一的场。系数不必精确解离散特征方程，重构必须使用原物理相位。[理论:96–100](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound.md:96)
2. $s>0$，$w=(-\Delta+s)^{-1}((\mu\rho+s)u)$。使用的 $1/(s+q_*^2)$ 是这个常系数正定源算子的逆范数界，不是 $A$ 在候选附近的谱分离信息。[理论:104–144](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound.md:104)
3. 同一个 $u,\mu,s,D$ 下，$\varepsilon_0\ge\|w-w_d\|_0$、$\delta_u\ge\|u-v_R\|_0$、$E_v\ge\|v_R-w_d\|_0$、$D_0\le\|w_d\|_0$，且 $D_0>\varepsilon_0$。定理 2 才给 $R_\mu=C_\rho(\delta_u+E_v+\varepsilon_0)/(D_0-\varepsilon_0)$。[理论:192–222](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound.md:192)

实际 run-03 的 B3 问题发生在第 3 项：面积近似为整矩形的剪裁片被当作整矩形积分；对复数／带符号源缺陷矩，扩域不自动保留所需单侧方向，且没有计入差集贡献。审查没有断言本次半径已被低估，但拒绝“所有非舍入误差已包含”的无条件标签。最小修复是确认四角包含后才走整矩形分支，否则保留真剪裁或包围差集矩。[B3及修复:251–261](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/review-9-6a.md:251)

当前 implementation 台账仍写“B3 OPEN；REPORTED R CONDITIONAL”，并明确“无BIE/模态数/谱隔离输入；当前R身份受B3限制”。在本次检索的后续 numerical-directions、项目状态及实验记录中，未找到关闭该项的记录。因此不能只凭后来总结的“可靠”措辞升级原结果。[台账:255–260](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/README.md:255)

“BIE 不需要 (H)”在其 F14 理论下成立；I9.6 也无此假设，但它是另一条方法。二者若要交付本任务的**点谱**区间，都仍需区间内无本质谱；这个条件允许其中有多个离散特征值，严格弱于 (H) 的单谱点要求。[BIE:300–307](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:300)、[I9.6:219–235](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound.md:219)、[命题 5:169、191](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/goerisch-width.md:169)

## 主线地位变化的记录

**未找到一条将整个 BIE 路线因“无法达到本任务保证宽度”而正式放弃的决策。** 找到的是不同对象、不同范围的调整：

| 日期与记录 | 原文及实际调整 | 对当前目标仍成立的理由 |
|---|---|---|
| 2026-08-11，DECISIONS | 标题“Continuous DtN/BIE method supersedes finite-tail formulation”；旧“finite cells + remote closure + doubling”降为交叉检查／尾诊断。[原文:58–74](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/DECISIONS.md:58) | 被替换的是有限尾闭合主表述；该记录本身保留连续 DtN/BIE 路线，不能用来证明 BIE 被撤下。 |
| 2026-10-27，DECISIONS、I9 README、项目 STATUS | “Neither the solver nor the theorem makes continued refinement of the I9.6 enclosure the default research priority.”；同时“B3 remains a genuine qualification gap for the old unconditional bound.”[决策:28–34](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/DECISIONS.md:28)、[I9 README:5–11](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/README.md:5)、[STATUS:18–25](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/STATUS.md:18) | 调整对象是 FEM 源重构估计器。理由是持续细分可能主要减少评价误差，未解决场缺陷一阶估计与特征值精度的失配；当时也明确“尚未证明旧路线无效”。该理由仍支持不默认扩大 I9.6 积分，却不能迁移为 BIE 失败的结论。[阶段分析:390–402、432–434](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/p-next.md:390) |
| 2026-10-27／28，I10 决策 | “BIE is only a final external comparison.”；随后“BIE is a final external reference.”[DECISIONS:3–7、19–23](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/DECISIONS.md:3) | 这是 FEM 富集实验的输入独立性约束和参照分工。选择理由是三模板 FEM 路径短、可用变分结构、可能避免另建全域源盒；原记录明示这只是成本潜力。[阶段分析:462](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/p-next.md:462) |
| 2026-11-01，numerical-directions P3 收尾 | 直接 P3 达到更窄区间，比较对象是重构试探场 **R**；两者仍沿用未认证谱假设。[结果与解释:373–413](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/README.md:373) | 支持直接 P3 取代 R 作为 Goerisch 试探场，尚未比较当前 BIE 完整认证与直接 P3 完整认证的成本。 |
| 2026-11-02，numerical-directions 阶段 4a 与“下一步” | 一处写“方向已定为数值方法论文：用直接高阶 FEM + DtN 和 Lehmann–Goerisch…”；另一处仍写“待用户决定：是否把研究线改为‘直接高阶 FEM + Goerisch’，并让 R 不再作为试探函数”。紧接着保留“BIE 路线不要求这种局部唯一性，仍能得到精度达标的估计”。[417](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/README.md:417)、[487–488](/Users/whc/Documents/Work/dot-research/research/explorations/numerical-directions/README.md:487) | 文档对改线状态存在不一致；不能据此认定用户已经决定整体放弃 BIE。约 $5\times10^{-9}$ 的**保证**目标要求重新比较各自缺失的认证工作，而非只比较浮点宽度。 |

上述否定结论的检索范围包括总／项目 STATUS、DECISIONS、implementation README/open-problems、I9/I10 阶段审查及 numerical-directions README；未将实验中“BIE 只作外部参照”扩大为全项目路线淘汰决定。

## 成本

### 当前 I9 模型：从模型到候选，再到数值估计

内存列统一为十进制 GB 的**采样进程树 RSS**。没有独立阶段峰值的地方明确标缺失；同一个整次运行峰值不能当作每个阶段各自测得的峰值。I9.2 使用 11 线程，因而也不能直接把下表同后来的双线程 Goerisch 实验作速度排名。[I9.2 环境与监控:139–146](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:139)

| 阶段 | 时间 | 内存 | 已测／缺失与来源 |
|---|---:|---|---|
| I9.1 数值共同间隙探索 | 28.410 s | 阶段峰值缺失；整次科学进程 1.423 GB | 已测。这里是 Bloch 数值分类，尚非连续本质谱排除证书。[搜索成本:502–515](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:502)、[分类结果:486–491](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:486) |
| I9.1 代表点／等引线检查 | 12.956 s | 同上 | 已测，同一成本表。 |
| I9.1 粗搜索／细搜索／新鲜确认 | 39.880 / 508.243 / 5.740 s | 同上 | 已测。三模板构造、引线求解与匹配包含在这些阶段内；读取的账目没有把全部 lead 消元和 QZ 单独汇总。[搜索成本:502–515](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:502)、[调用计数:493–500](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:493) |
| I9.1 其余科学进程／科学进程合计 | 47.759 / **642.987 s** | 整次 1.423 GB | 已测；候选 $k=1.5584378941820909$，末轮搜索窗口全宽 $1.6209256159527285\times10^{-14}$ 是求根定位尺度，不是连续谱误差证书。[候选:475–486](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:475)、[成本:509–515](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:509) |
| I9.1 绘图／科学启动到绘图结束 | 18.865 / **713.262 s** | 绘图进程 1.037 GB | 已测；进程时长之和是 661.852 s，与全程墙钟不同。另有失败及诊断 205.487 s，不能抹掉，也不应计入成功配置的单次成本。[账目:510–520](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:510) |
| I9.2 配置导出 | 19.933 s | 0.789 GB | 已测，独立于正式数值评价。[设置成本:145–147](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:145) |
| I9.2 固定频率下三胞元构场 | 3.397 s | 阶段峰值缺失；本次完整进程 1.389 GB | 已测，从头生成同一候选频率的场，未重做频率搜索。[入口:4–5、23–26](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:4)、[时间:127–140](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:127) |
| I9.2 材料界面及尾／纵向人工墙 | 10.253 / 29.621 s | 同上 | 已测；尾项仍是观察比率估计。[时间:130–131](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:130)、[尾:102–106](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:102) |
| I9.2 周期接缝额外诊断／局部质量 | 19.357 / 8.587 s | 同上 | 已测。接缝值用于一致性诊断，不加入精确准周期场的公式缺陷。[定义:32–34](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:32)、[成本:132–133](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:132) |
| I9.2 几何／标量／内部审计，保存，启停及其余时间 | 6.364 / 4.291 / 14.214 s | 同上 | 已测，互斥分账。[时间:134–139](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:134) |
| I9.2 完整数值评价进程 | **96.084 s** | **1.389 GB** | 已测，终点是未认证 $R_{\rm num}$，不含 I9.1 搜索、单独配置导出及独立审查程序。[成本及范围:137–160](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:137) |
| 当前曲线模型的可靠几何／核／连续求积与无限尾／质量下界／向外公式 | **缺失** | **缺失** | I9.2 明列未完成这些认证；不能借用 I6 圆形证书的时长填入。[I9.2 限制:154–164](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:154) |
| 包住最终区间的本质谱排除 | **缺失** | **缺失** | F14 要求单独完成，数值共同间隙分类不能代替。[F14 后条件:304–307](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:304) |
| 从模型到目标点谱保证区间的完整流程 | **缺失** | **缺失** | 没有当前模型完成上述保证步骤的运行记录。 |

两个成功科学进程的历史时长相加为 $642.9869550421136+96.0841365=739.0710915421136$ s，约 12.3 分钟。这只是两个独立运行到**数值估计**的已测子账合计，未含上表所有附加环节，更不是模型到可靠点谱区间的总成本。[两个原始时长](/Users/whc/Documents/Work/dot-research/test/i9/search-v1/README.md:510)、[I9.2 时长](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:137)

### 历史证书及题述成本的归属核对

| 记录 | 时间、内存 | 正确成本边界 |
|---|---|---|
| I6 v2 普通评价 | 34.584 s，1.034 GB | 固定场后处理，没有候选搜索；结果未认证。[运行:52–54](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i6/review-6-1b.md:52)、[固定输入:22–25](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v2/README.md:22) |
| I6 v3 最终可靠评价 | 119.464 s，0.866 GB | 从固定圆形模型输入的导出到 Arb 证书，未认证此前搜索，也未证明本质谱间隙；此前失败／修复另有逐次账目。[范围:25–38](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:25)、[逐次成本:144–158](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:144) |
| I7 非圆推广与部分认证 | 累计 628.251 s，1.209 GB | 六次调用含失败修复与导出；完整连续跳跃上界仍未建立，不能视为完成可靠界的时间。[审查:109–129](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i7/review-7-4a.md:109) |
| I9.6 run-03 | **302.5766 s，2.713 GB** | **控制层和主层合计**，不是每层5分钟，也不是单独源矩认证成本。互斥阶段为输入及自测5.1204、先导19.7572、两层预测／bulk74.8634、几何引擎121.5055、聚合18.9070、纠正6.1942、模范数15.0477、审计保存6.7897、图表保存7.7531、余项0.4141 s；函数总计276.3523 s。RSS 覆盖 MATLAB 子树，未覆盖外层启动器及后续汇总。[分账及范围:284–303](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/review-9-6a.md:284) |
| I10.1 fine 富集 run-02 | **127.844845 s，2.509 GB**；lead 消元39.1 s、QZ/DtN17.4 s | 题述128／39／17数值正确；属于 FEM 的 P2/P3/P4 primary/check 多条链及交付流程，不是 BIE 时长，也不是单独 P4 的冷启动成本。31.3 s 的 P4 子链漏掉必需 P3 等前序工作。[I10 成本:167–183](/Users/whc/Documents/Work/dot-research/test/i10/enrich-v1/README.md:167) |

## 对方向 1 的含义

1. **当前记录不能回答“BIE 已经完成保证目标”。** 它回答的是“当前 BIE 估计已达宽度要求，且理论谱包含不需要 (H)”。差距在连续跳跃、质量、几何和无限尾的可靠评价，以及保证区间内无本质谱；没有理由额外为 BIE 先证明局部唯一性。[I9.2 限制:154–164](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:154)、[F14:284–307](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:284)
2. **$2.42\times10^{-4}$ 不能用来证明 BIE 保证界太宽而应退出。** 它属于另一种 FEM 输入与源重构；原审查还保留 B3。另一方面，旧圆形 BIE 可靠界证明这条认证机制确实实现过，但不足以填补当前曲线模型的缺口。[I9.6 身份及资格:193–206](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i9/review-9-6a.md:193)、[I6 可靠结果:68–93](/Users/whc/Documents/Work/dot-research/test/i6/resolvent-v3/README.md:68)
3. **直接 P3 的已测优势针对 R，不等于已完成 BIE 比较。** P3/RT3 的 $4.69595\times10^{-9}$ 是有 (H) 的普通浮点实现结果；当前 BIE 的 $1.54917\times10^{-9}$ 是无隔离假设的普通谱距离估计。两者到保证区间的剩余工作不同，现有成本表缺少双方完整认证终点，不能据此宣布某条路线整体更便宜。[P3 状态及宽度:5、19–22](/Users/whc/Documents/Work/dot-research/test/numerical-directions/goerisch-v3/README.md:5)、[BIE 状态:4–5、84](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:4)
4. **更值得先估价的是当前 BIE 连续跳跃认证的移植工作。** I7 已将非圆推广的剩余项定位到双参数几何、$\log g$、对角极限、复条带及 Kress/Bessel/Ewald 余项；当时完整 $\bar\varepsilon_\partial$ 未建立。当前 I9 的双侧不同引线还须保留各自传播与尾项。这个明确的实现缺口，比把 I9.6 宽界视为 BIE 结论更适合与 (H) 认证成本比较。[I7 定位:110–126](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/implementation/i7/review-7-4a.md:110)、[I9 双侧规则:23–26](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:23)

## 补跑计划（未执行）

**无需原样重跑 I9.1 全窗搜索或 I9.6。** 唯一值得安排的数值补充是：对当前 I9.2 的**同一固定场**作一次独立评价先导，回答现有 $10^{-9}$ 级估计能否承受评价误差，以及这段后处理的真实成本。它不能代替上述单侧认证实现；若只是确认旧公式的保证身份，本次读记录已经足够。[I9.2 尚缺的检查:154–164](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:154)

- **固定输入与最小变化。** 保持 $k=1.5584378941820909$、三种真实曲线、中心512／左右256、$M=48$ 及两侧完整传播系数；只比较同一场的 FMM 768／1536非原生评价，以及直接后端768评价。材料、墙、局部质量分别记录差异；独立处理左右尾，不能重求密度后冒称同场检查。现有 I9.2 入口从固定频率重新构场并将密度固定，故若复用保存系数须新增显式输入包装。[I9.2 配置与同场约定:9–26](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:9)
- **入口。** 以 `estimate_i9_numeric()`、`estimate_i9_config.m`、`run_estimate.py` 为当前模型基线；主函数没有配置或旧场参数，不能假装现成支持上述比较，应在获准的新实验中复制所需 helper 并添加显式输入。借用 `fmm_est_i8(k0,output_dir)` 的“构场一次、只切换评价后端”结构，不采用其不同模型参数。已有 I9.2 汇总／审计入口为 `summarize_estimate.py`、`audit_estimate.py`。[I9.2 函数:1–28](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/estimate_i9_numeric.m:1)、[启动入口:47–67](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:47)、[I8 结构:1–20](/Users/whc/Documents/Work/dot-research/test/i8/fmm-est-v1/fmm_est_i8.m:1)
- **监控量。** 分开计时模型／配置加载、固定场生成或加载、几何、材料跳跃、人工墙、尾项、质量、标量区间、额外核查、启动与输出；保存每段及全程采样峰值 RSS。输出 $C,\varepsilon,U,Q,U-Q,R,W=2R$，两侧尾的依据、PDE／准周期场定义、各误差项是普通评价还是单侧包围，以及是否另有本质谱排除。仅在得到真正单侧输入后才报告可靠区间。[公式与同场范围:32–40](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:32)、[可靠输入:284–307](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:284)
- **预算估计。** 当前单次 FMM 评价96.084 s／1.389 GB；较早不同模型的两档 FMM＋同场直接评价为353.323 s／1.443 GB，其中直接跳跃190.380 s、直接质量78.579 s。以此为类比，当前三模板及1536评价的先导暂估 **6–10分钟、1.5–2.0 GB**，启动前仍应按实际批量重估；这不是实测或可靠认证成本预测。采用串行监控，软限30分钟、硬限40分钟、进程树RSS硬限3 GB。[I9.2 成本:127–147](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:127)、[I8 类比成本:154–170](/Users/whc/Documents/Work/dot-research/test/i8/fmm-est-v1/README.md:154)、[既有监控入口:64–67](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:64)
- **继续／停止条件。** 先检查独立评价是否已把估计推至目标之外；若是，报告实际瓶颈后停止扩展。若差异足够小，也只据此为可靠评价分配预算，下一步仍是非圆核与连续余项的单侧实现。作为预算标尺，暂把现有 $C_{\rm num},U_{\rm num},\mu_{\rm num}$ 当作准确值时，$W\le5\times10^{-9}$ 要求 $\varepsilon\lesssim6.63190\times10^{-12}$；现有普通值为 $2.05479\times10^{-12}$。这个约3.23倍余量只是由 F14 反解的规划数，不能支付尚未知的误差或替代证书。[现有输入:78–84](/Users/whc/Documents/Work/dot-research/test/i9/estimate-v1/README.md:78)、[F14:284–297](/Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework.md:284)

未执行该先导。当前仍缺：当前曲线模型的完整连续跳跃上界实现及其实测成本、最终区间内的本质谱排除成本；普通浮点重跑本身无法关闭这两项。
