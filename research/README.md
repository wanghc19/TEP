# Research workspace

2026-11-08，用户决定停止整个 BIE 导模课题：[[research/projects/bie-enclosure/README|bie-enclosure]] 及英文稿 `draft/bie-siam/` 不投稿、不再研究，原因见 [[research/projects/bie-enclosure/DECISIONS|DECISIONS]]。

2026-11-08，[[research/explorations/bie-dtn-2026-11-08/README|周期波导 BIE／DtN 查新归档]] 收录 Sol 的八项调查与原文复核。在已知文献调研范围内，BIE 特征值求解器这一块未找到尚未解决的有价值问题，未发现值得为固定 Bloch 参数导模计算单独立项的问题；[[draft/bie-solver/README|bie-solver]] 稿不再作为独立论文推进。

2026-10-30，[[research/weekly-literature/README|每周文献调研]] 已归档 10 月五批共 13 篇；公开全文、版本与校验信息、逐篇方法/创新性评估均已整理，跨批结论见 [[research/weekly-literature/synthesis]]。这是限定文献范围的研究记录，不提升任何当前数值结果的认证等级，也不建立统一主线。

2026-10-27，[[research/projects/eig-apost/implementation/i9/review-9-6a#9. R2：D2 run-03 实际结果审查|I9.6a D2实际审查R2]]：**REVISE，上界资格尚未闭合**。D1空成功出口已补；bulk近整矩形替代的复缺陷矩误差未受控，机器上界标签须收窄。主层报告 $R_k=1.42815\times10^{-4}$，源矩包围占半径91.76%，实用目标未达且不能归因为candidate变差。正式墙钟302.5766秒、MATLAB子树采样峰值2.713GB；目标流程总成本下降未建立。最小后续为冻结场的bulk资格及F/P评价收紧，未授权执行。本轮仅更新审查/入口，未修改理论、设计、实验或运行数值计算。问题见 [[research/projects/eig-apost/implementation/i9/README#I9.6 后验估计问题账目|I9.6账目]]；以下D2“未运行”等表述保留当时历史范围。

2026-10-27续，I9.6a已原位修订为 [[research/projects/eig-apost/implementation/i9/design-9-6a|D2修复设计]]：冻结场，实际几何细带剪裁、直接缺陷/缺陷矩、带余项范数及完整成功出口；一次投影分块留存。方法补充见 [[research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound|理论§11]]，本轮独审追加于 [[research/projects/eig-apost/phase3-analysis/fem-bound/r-dtn-bound|r-dtn-bound]]。尚未实现或运行，精度及成本待验证；下方D1审查保持历史范围。

2026-10-27，[[research/projects/eig-apost/implementation/i9/review-9-6a|I9.6a实际结果审查]]已交付：**REVISE，上界交付未完成**。主层普通 $R_k=1.16586\times10^{-5}$；可靠成功路径尚未实现。平台的纯native归因及必然下限未获支持；普通诊断墙钟203.65秒不代表可靠估计成本。最小后续为冻结场的可靠切割评价块，本轮未执行。以下2026-10-26内容为理论交接历史。

`research/` 保存尚处于研究、核查和整合阶段的理论工作。这里允许出现猜想、未证明命题、proof gap 和待核验引用；它不是正式论文草稿的替代品。

## 当前阶段

2026-10-26，I9.6新增 [[research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound|FEM＋DtN自身谱距离理论]]、[[research/projects/eig-apost/phase3-analysis/fem-bound/r-dtn-bound|独立审查]]及 [[research/projects/eig-apost/implementation/i9/design-9-6a|待执行设计]]。常系数正定源重构与有限Fourier／多项式评价面向原无限算子，不使用BIE或谱隔离；小量机制已给，当前实例精度和可靠积分预算未测。本轮仅理论与设计，不运行实验或改main；问题统一见 [[research/projects/eig-apost/implementation/i9/README#I9.6 后验估计问题账目|I9.6账目]]。

以下为I9.5b及更早阶段记录。

2026-10-26，[[research/projects/eig-apost/implementation/i9/review-9-5b|I9.5b FEM＋DtN实际结果审查]]：**PASS WITH CONDITIONS**。D2正式run-02交付 $k=1.558438079544167$，BIE参考差 $1.85362\times10^{-7}$，较E.2缩小约10.97倍；完整墙钟30.318秒、MATLAB子进程树采样峰值1.582GB。粗网一次翻边成功，正常粗细及Q10/Q12链通过；Q零差只表示当前停止分辨率内一致。缺曲线采样偏差/QZ原始块，另有未保留探针；不宣称全部合同交齐、真误差或同精度提速。本轮仅审查及更新研究文档，未重跑或改实验代码，不创建/恢复goal。

以下为已完成阶段记录。

2026-10-26，[[research/projects/eig-apost/implementation/i9/review-9-5a|E.2 实际结果审查]]：**PASS WITH CONDITIONS，仅限普通算术完整数值链**。
新candidate $k_h=1.558439927483915$；新场主 $R$ 为Q10 $0.004627470466476482$、Q8 $0.004625864372333271$，对旧最佳同阶下降约69.47%。
受监控完整科学链515.14695675秒、采样峰值1,759,723,520字节；同合同成本下降未建立。真材料积分、薄片元、H+及BIE参考条件仍须披露。
用户已清除goal，本轮没有建立或恢复goal；只读审查源码/已有结果并维护研究文档，未重跑实验，不自动进入下一轮。

以下保留历史阶段记录。

2026-10-23 续研 [[research/projects/eig-apost/phase3-analysis/fem-bound/p-scope|FEM 原生场谱距离专题 v2]]，
研究曲边 RT2 非零通量、真实材料积分与可核验的小量机制。
旧零通量后备已被解析证明无实用分辨率，不再作为精度评价的完成依据；新版已完成独审，
数学/可计算性通过，精度机制有条件通过，实际 I9.3 数值仍待评价。
状态见 [[research/projects/eig-apost/STATUS|项目状态]]，问题见
[[research/projects/eig-apost/implementation/i9/README#FEM 原生场理论问题账目|I9 理论账目]]。
本轮不进行数值实验、不修改 main 草稿、不建立或提升统一主线；下方保留各历史阶段记录。

当前没有活动中的统一理论主线。原 Müller--Cauchy 主线已于 2026-07-26 冻结在
Git 标签 `mainline-muller-cauchy-2026-07-26`，并移至
`research/archive/muller-cauchy-2026-07/`。`research/projects/eig-apost/` 已确认
fixed-$\beta$ line-defect guided-mode eigenvalue 后验误差的 research question。新路线已完成
I1 candidate discovery/readiness 与 I2 的局部有限维 count、Hermitian-part 端点 sign count 和
两条单轴 candidate 比较；I2 的六个 saved candidates 均为
$1.832770289108157$，相邻层均确认为同一 mode。该结果只表示在相同扫描规则下没有观察到
candidate drift，不证明 score minimizer、finite root 或连续 eigenvalue 已收敛。

I3.1 已以全边界胞元 BIE 得到 ordinary-double continuous-residual estimator candidate，阶段为
`PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`。自 2026-08-24 起，I3.2
包含已建立的条件性离散证书谱包含定理，以及固定同一 trial 的 empirical evaluation-cap
application。正式 `ecap-a2` 已通过 certificate identity 并完成 same-trial evaluation，但在 cap、
full-$P$ contraction、$q$ 和 interval 前以 $664.470682$ MiB 超过 $640$ MiB hard limit，故当前为
`EMPIRICAL_CAP_UNRESOLVED`；actual-$\Delta T$、finite-image Bloch 和 analytic-kernel 三项资格也
未通过。原 I3.3 已迁移至未来 I4.1，只登记使用独立方法/reference 对经验 estimator 进行
effectivity validation；原 I3.4 已迁移至未来 I4.2，继续登记 strict outward enclosure、
certified projected gap 和离散特征值存在性。I4.1、I4.2 当前均未启动；可靠区间、gap 和
存在性只属于 I4.2。
该专题仍不构成新的统一主线。
在形成可以明确命名且经过审核的统一框架以前，不建立空的 `mainline/` 作为占位。

## 层级

- `archive/`：冻结的历史主线和其他归档材料。除非任务明确指定某一归档或 Git
  标签，否则它们不是当前数学表述和符号的权威来源。
- `projects/`：独立专题研究、文献检索和 Codex 长任务输出。当前包含特征值后验误差
  范围界定、半波导 DtN 可行性研究、单胞表示研究和论文创新性审计。每个专题的结论
  只在其自身范围内有效。
- `planning/`：尚未形成具体专题的新想法、研究路线、证明依赖、风险、备选结果和
  未来工作安排。它负责规划，不替代正式数学陈述。
- `mainline/`：仅在出现经人工审核的活动统一理论时建立；届时它重新成为
  `research/` 内数学表述和符号的第一权威。

一般内容流向为：

```text
research/planning/
    → research/projects/
    → [人工审核后建立或更新] research/mainline/
    → draft/
```

该箭头表示“经审核后可能整合”，不是自动晋升：

- 专题结论不得自动进入 `mainline/`；
- 归档内容不得因曾经属于主线而自动恢复为当前权威；
- 将来 `mainline/` 中的内容也不代表已经可以直接进入论文草稿；
- 只有经过明确的人工审核，内容才可以进入 `draft/`；
- `pre/` 是阶段性演示或展示材料；
- `legacy/` 是历史材料，不是当前研究的权威来源，除非任务明确要求历史追溯。

新 agent 应先读根目录 `AGENTS.md`，再读本文件、`research/STATUS.md` 和
`research/NOTATION.md`，随后只读取与任务相关的规划或专题文件。只有任务明确选择
冻结路线时，才读取相应归档。
