# I6 非 Fourier 路线独立审查

> 迁移说明（2026-09-20）：本文件来自上一轮非 Fourier 专题，适用于
> `test/i6/resolvent-v2/`（原 `test/i6/resolvent-nonfourier-v1/`）。
> 下文研究、运行时间与非认证结论属于上一轮；本次仅迁移文档并更新当前路径。
> 历史运行产物及源码快照未改。新认证设计与审查见 design-6-1c.md、review-6-1c.md。

本记录由主 agent 汇总实际 Researcher、Engineer、Skeptic 的工作。Skeptic 全程只读，
不修改程序或本报告。审查按 blocker / important caveat / minor caveat 分类；
只影响本轮非认证公式评价正确性的 blocker 阻止相应交付。

## 运行前的挑战与回应

| 项目 | 分类、发现与处理 |
|---|---|
| I5 v8 失败因素 | 核对当前 design/review-5-1j 与 v8 README：零导数中心配合全局导数球产生过大的 RI 误差，不是 Fourier 尾或胞元尾。新路线不移植该导数球 |
| 精确源求积 | 需关闭的 blocker：必须逐项证明 retained split 乘有限密度次数小于 Nyquist。Skeptic 核对 $Q=32$、最大次数 161、$N/2=513$，Kress 与普通梯形精确性通过 |
| 连续遗漏核 | 需关闭的 blocker：旧离散 series radius 不能单独充当连续积分遗漏界。改为完整连续 log/smooth 尾，含 $\tau,\zeta,\tau'$ 与 Maue 的 $1/R$；旧源 $p=4$ 和旧离散尾不再重计 |
| local 解析延拓 | 需关闭的 blocker：不能将 complex target 穿过自作用奇点。圆的实差角卷积改为 shift-density 延拓，完整 kernel $L^1$ 界保持，有限 density 提供 $e^{a|m|}$ 增长 |
| 目标积分误差 | 需关闭的 blocker：有限采样或网格加密不能作上界。对完整精确行的反射解析平方使用 cot 轮廓余项，节点球另行计入，含交互项 |
| 曲线权重 | 已核对：target 权重为 $p_\Gamma/N=2\pi R/N$ 一次，source Jacobian 已在各核拆分内；导数不是 $\rho$ 加权通量 |
| 无限胞元 | 已核对公式：有限部分先作用真实状态；尾使用 operator 上界及完整 $P_\pm$，$G$ 与传播因子各一次；中心无材料 singleton |
| frozen raw 一致性 | 必须在代码/产物核对：candidate、密度、完整 $P,c,G,q$ 不重解，墙和中心质量取同一输入 |
| 认证层级 | important caveat：特殊函数与一般浮点舍入未向外包围、质量未向下包围；只能报告非认证的理论谱距上界公式评价 |
| 几何适用范围 | important caveat：本轮改进使用冻结圆形与有限源密度的结构，不能宣称任意单连通 inclusion 均有同一精确源求积性质 |

## 已形成证明的独立审查

Skeptic 对 `design-6-1b.md` 的三个局部引理和 (NF1)--(NF6) 完成独立核对：
source 次数 ledger、Kress 矩、连续 kernel 尾、shift-density 延拓、解析反射、
cot 常数 $4\pi R=2p_\Gamma$、节点半径所有权以及前 $G$ operator 尾均正确。
结论为：**局部理论可作为 run 前 GO；代码须另行逐项审查。**

修订已落实：strip 行包络使用 $M_{\mathrm{reg},A},M_{\mathrm{off},A}$，
避免与 Ewald remainder 的 $M_R$ 混义；解析域写为闭 strip 的邻域。
研究正文只在新实验设计中新增，没有修改既有理论或旧实验。

下列记录是产物形成后追加的代码、实际分项和资源审查；理论预审与运行验收分别保留。

## 代码、实际运行与独立复核

运行前，Skeptic 逐项核对 (NF4)--(NF6) 在 MATLAB 的落实：先合并有符号行，
曲线权重仅一次，源 continuous tail 与 exact-strip remainder 分开，$G$、完整 $P$
各一次，空中心无材料 singleton，墙和质量使用同一冻结输入。
初版入口沿用了旧 validator/summary/launcher 字段；Engineer 在科学运行前修复，
Skeptic 关闭这些代码 blocker，给出 run 前 GO。

实际执行只有 attempt-1 的两个 run：

1. run-01：MATLAB_PREFDIR 是相对路径，MATLAB 在进入科学阶段前退出。
   用时 1.083770583 秒，采样峰值 RSS 159956992 bytes。原日志及源码已保留。
2. run-02：全部 CLI 路径先转为绝对路径；没有变更科学配置。
   完成所有科学阶段，用时 34.583710125 秒，采样峰值 RSS 1034289152 bytes，return code 0。
   已保留输入/源码快照、MAT/JSON、日志及约 0.25 秒间隔的进程树采样。

Skeptic 从实际 JSON 独立重算材料与墙各层平方和、总值/法向缺陷、平方根、
$\overline Q=\overline C\overline\varepsilon_\partial$、分母、F14 及区间；按存储 double
逐项一致。主 agent 另外独立复算上述聚合与分项，全部通过。
所有实质检查门通过；`center_material_present=false`、材料 singleton 数量 0、
两侧首胞材料和中心墙各 2 是预期物理对象声明，不能错误地视为失败门。

$$
\begin{aligned}
\overline C&=2.3499520103811307,\\
\overline\varepsilon_\partial&=3.2041084219027955\times10^{-10},\\
\underline U&=1.2475196512735218,\\
\overline Q&=7.5295010275295862\times10^{-10},\\
\underline U-\overline Q&=1.2475196505205717>0,\\
R_{\mathrm{spec}}&=4.0547573451465766\times10^{-9}.
\end{aligned}
$$

区间 $[3.3590469285828397,\;3.3590469366923545]$ 是 $\mu$ 的区间。
Skeptic 确认节点半径中 local 连续核尾、regular source/$M_R,M_I,M_T,M_L$、
完整 off-surface、目标 contour remainder 和完整传播尾均有明确所有者。
材料的高模字段标为不适用，不能把它解释成漏掉未知尾。
Researcher 对实际分项复核也给出 GO，没有发现缺失的连续误差项。

源输入逐字节核对与基线/权威副本一致；run-02 的五个 MATLAB 源码快照与交付源码
逐文件一致。Engineer 完成 MATLAB checkcode、Python 语法编译及实际 MATLAB 运行。
常规 Java package warning 不影响运行，未发现非预期 NaN/Inf、非负性失败或分母错误。

## 结果挑战、回应与剩余项

| 分类 | 挑战与结论 |
|---|---|
| blocker，已关闭 | 是否把有限采样冒充连续上界？没有：retained source 次数门、连续核尾、完整 strip 包络与 contour remainder 均进入公式 |
| blocker，已关闭 | 是否遗漏无限胞元或重复传播？材料有限部分加完整 $P$ 尾；墙 singleton、有限、胞元尾及墙模态尾均计入；$G$ 与传播因子没有重复 |
| blocker，已关闭 | 是否混用更好的旧分子/分母？没有：同一个输入的 density、完整 $P,c,G,q$ 形成全部项；质量和 trace 常数重评且与基线相同 |
| important caveat | 同一有符号中心有强相消，不能把其极小数值直接宣称为真实跳跃上界。当前节点球控制的是连续截断/求积误差，尚未包围特殊函数及一般浮点误差 |
| important caveat | 质量未向下舍入，trace/传播与特殊函数未单侧包围。`mass_is_certified_lower=false`，整体状态为 `NON_CERTIFIED_FORMULA_EVALUATION`；没有严格谱包含声明 |
| important caveat | PDE/准周期为零仅针对精确核定义的数学 raw 场。若以后改用截断核定义 raw 场，必须另评体内和 seam 缺陷 |
| important caveat | 新源精确性使用圆、有限 density 支持及 $161<513$；不能推广为“单连通即足够” |
| minor caveat | 墙同公式重评使用当前共享几何 $N=1026,a=0.2$，旧基线为 $N=16384,a=0.3$；墙法向平方变化 $-2.655024454007252\times10^{-25}$，不是 raw 改变或本轮改善主因 |
| minor caveat | 资源为约 0.25 秒采样的进程树 RSS 峰值，不是 OS 连续峰值；记录没有触限，watchdog 超限即终止任务组 |

最终 Skeptic 决定为 **PASS WITH CONDITIONS（本轮非认证公式评价层级，置信度高）**，
当前层级无剩余 blocker。Researcher 的独立结论为 **GO**。
二者意见一致不是证明替代品：其依据是 design-6-1b.md 三个局部证明、逐项源码映射及上述
实际分项复算。认证层面的未关闭条件保留，不包装成严格谱包含。

相较旧基线 $7.387058992105812\times10^{-4}$，估计改善约 182182.5 倍；
目前人工墙法向占总缺陷平方 96.3929%，材料法向约 3.6022%，后者又主要是 regular
$M_I,M_L$ 半径。扩大材料节点数不针对当前主导损失。目标已完成，未启动第二 attempt。

未来若需严格认证，必要工作是特殊函数/舍入的上界、质量的单侧下界以及 trace/传播
标量的可靠包围；如果未来要解释成离散特征值存在，还需独立的本质谱带隙依据。
这些均未冒充本轮完成，也不作为当前普通浮点交付的前置门槛。


## 静态检查的实际命令与提示

Engineer 实际执行 `python3 -m py_compile test/i6/resolvent-v2/run_with_limits.py`，
退出码 0，无输出。实际使用 MATLAB R2023b `-batch` 对五个 `.m` 文件逐一调用
`checkcode(path,'-id')`，退出码 0：主入口 1 条 MSNU（过期抑制标记）；local helper
4 条提示（2 条 NASGU、1 条 DEFNU、1 条 INUSD）；其余三个 helper 为 0 条。
这是静态检查完成，**不是零警告**。上述提示属于未用变量、未调用诊断函数、未用参数
和过期抑制标记，没有改变已审查的实际执行路径；未为消除提示改动已跑源码。

## 收尾记录

最终文档经 Skeptic 复核，数值、对象范围、认证层级及墙网格变化解释均准确。
未启动额外科学运行，没有活动的本任务 MATLAB/watchdog 进程。
对 epost（排除本新目录）、main TEP 和 TEP_ref 的文件数量、大小及修改时间摘要
与任务开始记录逐一比较，全部一致；Git 状态仅出现本实验新目录。
确认未修改授权目录外的项目文件，未 commit 或 push。

任务起点：2026-09-20 01:29:35 UTC；最终验收记录时刻：2026-09-20 02:06:06 UTC。
截至此记录总墙钟 2191.5 秒（约 36.52 分钟），包括阅读、协作、实现、
失败修复、两次启动、审查及文档；不是两次 run 耗时之和。
绝对截止为 04:29:35 UTC，本轮提前完成，无预算重置。
