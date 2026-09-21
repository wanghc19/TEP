# I6.1c 独立认证审查

本文件由主 agent 整理实际 Researcher、Engineer、Skeptic 的工作证据。Skeptic 保持只读。
认证目标是三个单侧界及 F14 的严格谱距离，不把无运行错误或数值一致视为认证。
运行前数学审查与实际程序/产物验收分开记录。

## 已完成的迁移核对

开始 Git 分支为 `codex/epost`，唯一未跟踪内容是原非 Fourier 专题。
`implementation/i6/` 当时已存在但为空，没有覆盖已有文件。
主 agent 将原目录迁为 `test/i6/resolvent-v2/`，41 个原文件在更新当前文档前逐字节核对一致。
设计/审查/符号文件移至本目录；当前链接、复现路径和版本范围已更新。
历史输出、失败日志、源码快照和 v2 计算源码保持原状。
已跟踪 v1（包括其 design-6-1a.md）没有改动。

## 构造—独立审查—修复

| 项目 | 分类与处理 |
|---|---|
| 精确 $\mu$ | blocker，定义层已关闭：stored `mu_h` 与 exact `khat` 的实平方相差 $-245781849136169/2^{100}$；统一取后者，前者只作诊断。实际全部核/墙尾是否同用仍须代码门 |
| 精确几何 | important caveat，已明确：按 MAT binary64 dyadic，不把打印 0.2/0.04 猜回 $1/5,1/25$。Researcher 未找到相反 exact rational 契约；认证针对该冻结数值对象 |
| density DFT | blocker，待程序门：必须验证 exact 样本的数学 DFT，不能把普通 FFT 输出当精确系数 |
| 特殊函数与相消 | blocker，待程序门：完整 local/regular/off/wall 中心必须球包围，包含 $\operatorname{erfc}$、$E_1$、根号与指数；普通中心加安全系数不成立 |
| 传播块长 1 | 初审误建议用 $\|I\|_F^2=97$；主 agent 指出 N7 允许精确谱范数 $p_0=1$，Skeptic 复核更正。最终 $K=1/(1-r^2)$，$r\ge\|P\|_F<1$ |
| 材料尾所有权 | C6 的 $M_A$ 仅包围前 $G$ 行，乘 $\|G\|_F$ 和 $\|P^Jc\|$ 各一次；不得重复传播。墙完整行已含 near/far 状态，不能机械多插一个 $P$ |
| 质量下界 | C4 的解析 Gram 公式正确；$\lambda_\pm$ 真实非负时下端与 0 取最大合法，必须以单侧算术落实 |
| 十进制输出 | blocker，运行前已指出：固定 120 位 Decimal 不能对任意二进端点标成 exact；应整数精确展开或分别 floor/ceil。canonical dyadic 本身可以作为证据 |
| 较低 Q/N | 非 blocker：首轮冻结 Q10/N280，次数门 $139<140$ 正确；保留增大的 continuous local tail。宽但有限的严格结果必须保留 |

## 已形成证明的独立审查

Skeptic 对 [design-6-1c.md](design-6-1c.md) 的 C1--C7 逐项核对，结论为
**PASS WITH CONDITIONS（数学连接，置信度高）**，无证明 blocker：

- exact input、$\mu$ 分数和偏差经独立有理数复核；PDE、Rayleigh 与 F14 对象一致。
- 球包含归纳和先有符号合并后取模方向正确；常数必须来自 Arb/精确整数。
- C3 对 T9 的点窗口实例成立，前提实际 collar 分离和正性区间门通过。
- C4 的传播/倏逝 Gram、和差分解和单侧下界成立。
- C5 的完整矩阵收缩、零次幂谱范数和 C6 材料尾成立。
- C7 的 F14 单侧方向及正分母、最终区间外扩成立。

Skeptic 保留的实现重点是墙完整配对行的所有权，以及 NF1 连续 local tail、
regular $M_R,M_I,M_T,M_L$、source/target 余项和墙模态尾全部移植。
理论证明不能代替这些程序门。

## 实际运行验收门

下列为运行前定义的验收清单；最终 run-10 已全部通过，证据与结论见末节：

1. 无损输入、复数实虚部、精确参数和数学 DFT；
2. 有限有符号节点的球包围，全部特函和矩阵运算；
3. 连续核/源/目标误差、全部墙项及无限尾；
4. collar、$\overline C$、$\underline U>0$、完整 $P$ 收缩；
5. $\overline\varepsilon_\partial$ 汇总、$D>0$ 和 F14；
6. exact dyadic 和向外十进制区间；
7. 源码/输入快照、运行预算、错误留痕及完整独立 v3 入口。


运行前进一步修复：

- 主 agent 发现 regular canonical 多项式系数的 Python 整数除整数会先生成 double，
  之后转 Arb 无法恢复该遗漏误差；已要求在除法前转为 Arb，并全局检查同类表达式。
- 主 agent 发现固定 Decimal 精度的 exact 字符串声明不成立；Engineer 已改为整数乘
  $5^{-e}$ 的精确有限十进制展开，canonical dyadic 始终保留。
- Skeptic 核对墙 singleton 的 $D_\pm$ 与 $G_\pm$ 近中心块来源：保留冻结 $D_\pm$；
  若改用 selector 取块则须逐元素精确相等，不能以接近替代。远侧块与重乘 $DP$
  不强求精确相等，其差属于实际跳跃。
- Skeptic 指出 J 选择代码控制的是传播状态能量尾，而非乘 action 因子后的尾平方。
  首次运行前已统一设计为前者；最终各 action 的完整尾仍全部计入。


## 运行前代码审查的关闭项

Skeptic 对完整 v3 实现给出 **GO / PASS WITH CONDITIONS**：未发现剩余数学或实现
blocker，实际运行与产物门仍须检查。Researcher 另作 Ewald 四尾、canonical 局部补偿、
源次数精确性和 reflected-square 目标余项审计，未发现未计入的连续项或支选择问题。

- 墙遗漏高模从首胞起计：已修为 $K\|c\|^2$；保留模态的胞元尾使用 $K\|P^Jc\|^2$。
- 精确外部密度以 `rho_exterior=1` 作为显式科学配置导出，Python 合同单独验证。
- 所有特函和矩阵中心使用 Arb；没有把高精度一致、有限采样或任意倍数当作认证。
- canonical 多项式、Ewald 尾、所有分母和非 Wood 分支使用区间正性门。
- 原整数字段通过严格无损往返后传输，manifest 保存类型；不伪称原存储都是 double。

## 调试留痕

| attempt / run | 实际结果与处理 | 分类 |
|---|---|---|
| 1 / 01 | 进程树读取被 sandbox 拒绝，尚未导出/科学计算；仅本任务进程组被终止，保留 `failure.json` 和启动日志；转为允许监控的执行环境 | 运行环境修复；无有效谱结果，峰值不可用 |
| 1 / 02 | MATLAB 导出在原整数字段处失败；20.53 秒，采样峰值 844103680 bytes；原 double-only 假设改为精确 integer roundtrip 合同 | 程序输入类型修复，同一科学对象 |
| 1 / 03 | 完成 local/regular 后，复数 Rayleigh 参数传入仅接受实参的 `exp_i`；111.07 秒，采样峰值 821608448 bytes；改为等价 `(i*theta).exp()` | 球类型接口修复，同一科学方案 |

每次失败有独立配置、日志及源码快照；尚未得到 `certificate.json` 的 run 均不作为
有效认证结果。原结果不覆盖；科学配置未因上述程序修复改变。


主 agent 又发现整数类型合同的边缘问题：仅整数往返相等可能被 int64 的饱和转换误导。
已要求增加 $|x|\le2^{53}$ 的充分条件。对本次 run-06 的全部原整数字段作独立二进读取：
$d=L=1$、$\rho_{\mathrm{disk}}=17$、$M=48$、$K=97$、墙 selector 为 0/1、
阶数范围 $-256{:}255$，全部通过范围与整数门；故当前冻结对象无未关闭转换误差。
这项泛化合同修复不改变科学输入，不因无关的大整数反例否定当前结果。


### 非有限值的实际定位与等价修复

run-04 材料平方汇总为 NaN，立即按无效运行终止；145.75 秒，采样峰值 894959616 bytes。
run-05 增加逐层有限性门后，在 `local_value[1,0]` 定位首个非有限值，48.33 秒，
890699776 bytes。用共同网格差 $2\pi(r-s)/N$ 后，run-06 的 local 门通过，但
`regular_value[1,0]` 仍非有限，94.83 秒，874119168 bytes。仅固定 regular self-pair
还不足以处理不同但对称的节点；run-07 仍失败，97.55 秒，892715008 bytes。

主 agent 在相同 vendor/192-bit 环境作了独立 API 单元核查：设
`x=arb.pi()/140; z=x-x`，得到跨零小实球；`z**2` 的 finite 检查为 false，
`z*z` 和 `acb(z)**2` 的 finite 检查为 true，exact-zero 平方也为 true。
因此问题是该通用实数幂接口在跨零球上的域限制，不能归因于物理奇点或删去对角项。
所有可能跨零的实坐标平方须使用严格等价乘法；canonical 正则核的对角值完整保留。
每个阶段的有限性门保留，旧的仅打印“PASS”不能当作非有限值已排除的证据。
上述修复均不改节点数、核阶数、冻结场或误差预算，故属于同 attempt 程序纠错。


### 墙值移植错误及最终标量记账

run-08 虽返回正常退出码并生成组件 JSON，但墙值平方为 9.013689，分母为负。
Researcher、Engineer、Skeptic 与主 agent 各自对照精确平面 Green 系数核对，发现
$i/(2\gamma)$ 被错误写成 $+1/(2i\gamma)$。曲线除以 $i\gamma$ 的系数没有错误。
这不是“合法但保守”的界，而是已知符号移植错误；原 JSON status 不能认证目标的完整
边界缺陷，旁置 `diagnosis.json` 明确 `scientific_result_valid=false`，原结果不重写。
修复保留完整 signed 配对行，并增加逐模 `2*gamma*flat-i`、`i*gamma*curve-1`
包含零的恒等式门。恒等式的数学依据见设计补充，而非仅靠该数值门。

run-09 已得到数学有效的有限上界 $R_{\mathrm{spec}}\le1.649339095316729\times10^{-7}$。
Researcher 独立核对其三界、正分母、向外 F14 与区间。主 agent 的精确 Fraction 审计发现
唯一序列化记账差：材料右侧法向 total 上端比各个分别序列化的分项上端之和小
$2^{-249}$，约 $1.105429575052089\times10^{-75}$。这是内部球先求和与分别取上端后
再求和之间的末位差，不是核余项遗漏，也不使原内部球给出的数学上界失效。
Skeptic 已独立精确复核。run-09 保留为有效结果及其 `scalar-audit.log`。

run-10 只将各类总量统一为“先取已返回的 point upper，再相加并向外取上端”，
不改任何科学配置、中心、核余项或 raw 场。此保守性单侧修复使机器证书能由独立
精确有理数程序逐项复合；仍属同 attempt 的程序记录修复。

`material_high_mode_applicable=false` 表示未对材料跳跃作 target Fourier 截断，
不是一个失败门，也不是未知尾设零。连续 local/kernel/source/target 余项与无限胞元尾
均另行入账；人工墙的所有遗漏模态尾仍明确保留。


## 最终独立审查：PASS WITH CONDITIONS

Skeptic 最终结论为 **PASS WITH CONDITIONS，置信度高**；条件仅为下述已明示的冻结对象与 Arb 合同范围，没有未关闭的目标 blocker。

最终权威产物是 [run-10/certificate.json](../../../../../test/i6/resolvent-v3/output/attempt-1/run-10/certificate.json)，
对应 [scalar-audit.json](../../../../../test/i6/resolvent-v3/output/attempt-1/run-10/scalar-audit.json)。
Researcher、Skeptic 分别只读检查实际产物，主 agent 另以完全独立的 Python Fraction
算术核对 96 个球记录；全部检查通过。当前 5 个运行核心源与 run-10/source 逐字节一致；
run-09/10 的 28 个科学二进输入完全相同，路径元数据不参与数学评价。

| 验收项 | 最终状态与证据 |
|---|---|
| 同一精确输入与密度 DFT | PASS：无损 binary64/整数合同；数学 DFT 在 Arb 中；所有处同用 exact khat 平方 |
| 有限节点与特函 | PASS：local/regular/off/wall 的矩阵及半径 finite 门，特函和强相消均为球包含 |
| 连续与无限余项 | PASS：NF1 local、源/目标、Ewald 四尾、全部墙和胞元尾完整；高模/胞元尾所有权区分 |
| trace 上界 | PASS：collar 分离/覆盖门、Arb C3；Fraction 另从精确输入直接复算有理 C 平方公式 |
| raw 质量正下界 | PASS：归一化基下空中心解析 Gram；下端与向下根号方向通过 |
| 三界、正分母与 F14 | PASS：所有分项上端可直接复合；分母严格正，F14 向外；无旧 lift |
| 输出与复现 | PASS：96 个 dyadic/完整十进制一致；源码/输入/资源记录齐全，独立入口不读历史报告 |
| 资源 | PASS：最终 119.463565 秒；0.25 秒进程树采样峰值 866287616 bytes，无监控错误 |

最终便读的可靠界（上界已向上、下界已向下）为

$$
\overline C\le2.34995201038114,\qquad
\overline\varepsilon_\partial\le1.30332365404084\times10^{-8},\qquad
\underline U\ge1.24751965127352,
$$

$$
\overline Q\le3.06274804099054\times10^{-8},\qquad
D\ge1.24751962064604>0,\qquad
\operatorname{dist}(\mu,\sigma(A(\beta)))
\le1.64933909531673\times10^{-7}.
$$

向外区间为 $[3.359046767703687789,\;3.359047097571506853]$。
实际计算使用完整 dyadic，而非这些便读舍入值；不将 $R_{\mathrm{spec}}$ 称为 residual 范数。
已达到 $10^{-6}$ 目标，无需 attempt-2。完整分项和全部 run 资源见 v3 README。

**Blocker：无。** 已发现的非有限值、墙值符号和序列化问题均有失败证据及修复复核。
run-08 因已知公式错误排除；run-09 有效数学界保留，run-10 完成可组合机器证书。

**Important caveat：范围与可信基础。** 认证针对已明确的冻结 dyadic 模型和 exact-kernel
raw 场，依赖 Arb/FLINT 的包含性合同及已审查的公式实现；不是软件栈的独立形式化验证。
不认证原候选搜索、整个 BIE 求解器、本质谱带隙、离散性、唯一性或编号。
这些不阻止本轮全谱距离认证，也不将它降为普通浮点公式评价。

**Minor caveat：资源测量。** 866287616 bytes 是每 0.25 秒观测的进程树峰值，
不是操作系统连续精确峰值；记录远低于 3000000000 bytes。run-01 在监控不可用时终止，
其峰值不可获得，不能报为零。

实现、运行与独立审查均已完成；保留上述范围限制，不留未说明的认证误差项。

交付计时记录：2026-09-20 09:11:13 UTC，总墙钟 4972.7 秒。
最终范围核对通过：epost 授权目录外 2619 个文件、main 1932 个文件、共享 ref 95 个文件的大小/修改时间摘要与起点一致；
tracked Git diff 为空。未 commit/push；所有仍需将来同步的上级维护记录均未在本轮改写。
