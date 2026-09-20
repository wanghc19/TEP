# 独立理论审查、修复及复核记录

## 结论

**PASS WITH CONDITIONS。** 在 `s-trace.md` 假设 G 及 `s-framework.md` 假设 U
（或已明确的体/seam 缺陷扩展）下，T4 和 F1--F2 的证明闭合。
没有遗留的当前定理 blocker。可进入未来 I6 的数值设计，但没有评价本实例的
$C_{\mathrm{tr}}$、$\varepsilon_\partial$、raw 质量下界或分母，亦没有可靠谱包含结果。

“with conditions”指必须满足并在实例中核对已列假设，不是用尚未证明的辅助命题替代
关键步骤。剩余事项统一记在本文第 4 节；本轮不修改上级问题台账。

## 1. 实际协作及职责

主 agent 确认 `codex/epost`，只读核对 main 最新 draft、epost i5 和
`residual-bound`，统一写入本目录。实际启动的子代理为：

- Researcher（任务 `researcher`）：构造正移位体范数界、准周期 Fourier 全局
  $H^2$ 论证、双侧 collar 迹常数及无限周期几何证书。它独立核算并确认最终
  $1/(4\mu)$、$\rho_+$ 和双侧一维 $1/h,h/2$ 系数，返回完整证明与可计算性边界。
- Skeptic（任务 `skeptic`）：使用 Review only，对已经落盘的证明逐行独立审查，
  检查 G、T1--T5、F1--F14、N3--N9；不修改任何研究正文。它在 framework
  审查中给出一项有界修订要求，主 agent 修复后再次复核。

两名子代理均被明确告知共享工作树、唯一写入边界及只读职责；没有并发覆盖正文。
实际循环为：构造与独立假设检查 → T4 初稿审查 → Green/谱连接审查 →
接缝假设及声明修复 → 全部修复和数值接口复核。
审查结论建立在下面逐项证明核对上；角色意见一致本身不作为证明依据。

## 2. 审查发现、回应与复核

| 编号 | 独立发现及分类 | 主 agent 回应/准确位置 | 复核状态 |
|---|---|---|---|
| S01 | **blocker，仅针对“原始裸假设无条件推出 (4)”的主张**：单连通不保证可积边界或法向迹，周期性也未自动给无限族统一常数 | 不保留该过强主张；在 G 增加 $C^2$、统一 collar、有限覆盖重数，并在 `s-trace` 第 6 节给出非整流边界/累积人工墙反例 | 已关闭；修正版定理通过 |
| S02 | **important caveat**：值迹和导数迹量纲不同；只改 trace 一侧不足 | 原式限于固定无量纲坐标；物理单位版本 T9/T10 同时引入 $\ell_*$ 及对偶权重 | 已复核通过 |
| S03 | **minor caveat**：T1 不应先验假定原定义域的导数边界迹属于 $L^2$ | T1 明记 $H^{-1/2}$ 广义法向迹，然后用 Fourier 证明 $H^2$ 升阶 | 已复核通过 |
| S04 | **important caveat / bounded REVISE**：F10 将非紧水平 QP 接缝加入界面集合，但 G 初稿只列闭曲线/闭合竖线 | G 显式允许完整水平嵌入直线，参数在 $\mathbb R$，$h<d/2$；重数加一，T6 及单调收敛不变 | 修复后复核通过；exact-QP 主结论从未依赖该缺口 |
| S05 | **minor caveat**：有体缺陷版仍引用 U 中 $r=0$ 易生形式歧义 | F2 明确以 $\rho^{-1}r\in\mathcal H$ 替换 F4；F14 补明 $\overline\varepsilon_{\mathrm{vol}}\ge\varepsilon_{\mathrm{vol}}$ | 已复核通过 |
| S06 | **important caveat**：旧材料 $+/-$ 缺陷不能整对无映射移植 | F3 明定 in/out；列明旧 draft 两种侧向下到底哪一个符号需取负 | 已复核通过 |
| S07 | **important caveat**：旧 i5 的单侧 shared-data、后期 paired jump、旧提升总量、旧负阶法向范数不是同一个输入 | F3 与 N1/N2 使用最新 paired rows；N3--N5 重新形成 $L^2$；不复用 $B_{\mathrm{lift}}$ 为新缺陷 | 已复核通过；实例仍待评价 |
| S08 | **important caveat**：有限曲线与幂界必须真实包围全对象，不能把旧布尔门或采样当证明 | T12--T13、N3--N8 明列有限参数/行/幂界，并区分普通浮点和单侧包围 | 理论合同通过；转入第 4 节 |

原始版本中过强的 G 范围已修复；没有把尚存分歧隐藏为共同意见。
当前无未解决的实质数学分歧；以下事项仍限制未来实例结论。

## 3. 逐项通过的证明义务

| 证明义务 | 独立核对结果 |
|---|---|
| 算子与模型 | F1 是全条带分布 Laplacian 定义域，包含物理 transmission、两项 QP 及有限能量；没有单胞 Dirichlet 替换或加权通量 |
| 全局正则性 | T1 的 QP 延拓不产生接缝面源；Fourier 乘子给全局 $H^2$ 和 Frobenius Hessian 恒等式，没有跨 $\rho$ 求导 |
| 正移位常数 | T3 由 $\|Av-\mu v\|^2\ge0$ 得到 $1/(4\mu)$；T4 由 $\Delta v=-\rho Av$ 得到 $\rho_+$；不需要 $\delta_{\mathrm{spec}}$ |
| 一维/局部迹 | T5 的双侧平均给 $1/h,h/2$；Jacobian 下界只给一次 $\theta^{-1}$；对 Cartesian 梯度作迹不产生曲率导数 |
| 无限界面族 | T11 对有限子集先估计、再单调收敛；重数只出现一次，T8/T9 没有胞元总数或 $N_{\mathrm{ov}}^2$ |
| 有限几何资格 | T12 的近弧切向投影及远弧弦距矛盾正确；T13 与有限模板/远平移排除给可评价资格，不需求精确 reach |
| Green 符号 | F7 两片的外法向之和正是 $j\overline z+a\partial_\nu\overline z$，material in→out 和 wall near→far 均匹配 |
| 无穷远极限 | F8 的全部符号正确；额外体项与 $a\partial_\nu\chi_R$ 项分别由体 $L^2$ 和界面直和控制而消失，没有使用 raw 全局 $H^1$ |
| QP 缺陷 | F10/F11 的相位与正负号正确；修复后的 G 覆盖水平接缝；上下边只计一次 |
| 谱代数 | F13 由 $u+2\mu z$ 与自伴预解式范数给出；F12/F14 分母条件、体缺陷分子和单位正确，不展开本质谱离散基 |
| 有限行 Gram | N3/N4 是有限行到 $L^2$ 的三角界；i5.1j $Q_0,R_0$ 只在精确同一对象下复用 |
| Fourier 尾 | N5 Parseval 系数与 QP gauge 导数正确；明确取消旧负阶权重后重评 |
| 完整传播尾 | N6 singleton/首胞/内部墙无重计；N7/N8 用完整矩阵幂，允许非正规/Jordan，Lyapunov 替代也成立 |
| raw 分母 | N9 的有限 patch 质量下界正确，遗漏质量非负；仍单独要求 $u\in\mathcal H$，没有循环推理 |

## 4. 本专题唯一的剩余事项表

| 项目 | 分类与影响范围 | 最小后续动作 | 状态 |
|---|---|---|---|
| 本实例完整界面几何资格 | **important caveat**：限制实例化，不阻止已证明定理或 I6 设计 | 从真实曲线及周期包围盒给 $\kappa_*,h,\theta,N_{\mathrm{ov}}$；逐个模板和例外面核对归属 | 未执行 |
| raw exact-kernel 正则性及 PDE/QP | **important caveat**：未满足时不得应用 F6；可用 F9--F11 扩展 | 核对有限密度、曲线光滑性、精确核恒等式；若非零则计算相应体/seam 项 | 未执行实例核验 |
| 两种实际跳跃的完整 $L^2$ 上界 | **important caveat**：限制实例谱界 | 复用 paired signed rows、行半径和完整 $P$，按 N3--N8 重评；法向高模不沿用负阶权重 | 未执行 |
| raw 质量下界与分母正性 | **important caveat**：限制有效性；失败只报告无信息 | 用 N9 评价有限安全 patch，再检查 $\underline U>\overline Q$ | 未执行 |
| 特殊函数和浮点单侧包围 | **important caveat**：限制“可靠数值上界”，不是本轮理论 blocker | 使用来源可追踪的 primitive/求积误差包围及有限矩阵、平方根、除法单侧运算 | i5 遗留条件继续未关闭 |
| 本质谱 gap 认证 | **important caveat**：只限制离散特征值存在性解释，不限制全谱距离定理 | 由独立已确认的 gap 输入检查包含区间严格落入其中 | 不属本轮工作 |
| 常数紧性、分族 collar、自适应尺度 | **minor caveat**：影响实用性，不影响正确性 | 先观察未来评价的主导项，再决定是否改进共同 $h$ 或行半径 | 延后 |

没有把“未来必须评价的有限输入”包装为当前已得到数值；也没有将最优常数、所有参数泛化、
全浮点认证或整个 gap 项目升级为本轮的前置理论门槛。

## 5. 证明与记号工作流完成报告

| 项目 | 记录 |
|---|---|
| Task mode | 主 agent/Researcher：Proof from scratch；Skeptic：Review only；正文记号 Writing，独立记号 Audit |
| Source file | 原目标式由用户本轮提供；算子精确定义来自 main `s-modelproblem.tex` 的 `eq:fixed-beta-operator` |
| Output files | 本目录 README、s-framework、s-trace、r-theory、p-numerics 五文件 |
| Target environment | `s-trace` 的引理 T1/T2/T3/T5、定理 T4 及各自“证明”；`s-framework` 命题 F1、定理 F2 及其“证明”；`p-numerics` N4/N8/N9 的直接证明 |
| New labels/numbers | Markdown 手工标签 T1--T13、(4)、F1--F14、N1--N9；T/F 同时分别给局部命题和公式编号，正文按“引理/定理/命题”或括号区分；没有宣称 LaTeX 自动编号已编译 |
| Authorized outside-environment content | 用户已明确授权的新定义、假设、记号映射、反例、计算接口和本审查报告，均限本专题目录 |
| Original-text integrity | 未修改任何已有正文；Skeptic 未写文件；既有未提交修改保留 |
| Insertion/repair blocks | 修订仅涉及新专题 G 的水平接缝范围、T1 广义迹说明及 F2/F14 的体缺陷声明，无原位旧文插入模式 |
| Verified references | README 记录本地 Barnett2018 实际 v2 的 Theorem 1.8/(7.1) 与 Barnett2010 的 (2)--(4)；仅背景核验，不作本证明前提 |
| Verified book pages | 无书籍定理引用 |
| Downloads / missing references | 未下载；无证明所需但缺失的非基础文献依赖；按用户要求只读使用外部本地 PDF，不复制到 ref |
| Steps awaiting literature verification | 无；主常数、Green 极限和尾界均在本专题展开 |
| Remaining proof gaps | 在已列假设内无遗留缺口；实例资格和数值评价见第 4 节 |
| Literature status | Proof literature verification completed. Review literature verification completed. |

记号审查通过：$\mathscr E$、$\delta_{\mathrm{spec}}$、$\ell_*$ 均有必要含义，
$\eta$ 留给 density，$\Lambda_\pm$ 留给 DtN；没有拆分 $\Omega_0$ 或省略完整
$P_\pm$。最终静态检查仅检查文本、公式标签及写入范围，未调用 MATLAB、Octave
或其他数值实验。
