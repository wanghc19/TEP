# Adversarial Verification / Numerical Red Team

日期：2026-10-28。工作区 `/Users/whc/Documents/Work/epost`，分支 `codex/epost`，
起始提交 `e1866b7`。这是与现有研究主线独立的验证任务；不会自动推广到论文、
主线、生产代码或Claude工作文件。目标是可信的研究路线决策，不以找到Bug或维护
某个方法为成功条件。

## 阅读入口

1. [[redteam/archive/eig-apost-2026-10/reports/method_decision|研究路线决策]]：当前可作什么决定、不能作什么决定。
2. [[redteam/archive/eig-apost-2026-10/reports/mode_identity|物理模态身份]]：实际保存场的共同区域比较。
3. [[redteam/archive/eig-apost-2026-10/reports/error_certification|误差认证含义]]：两个小半径的不同证据身份。
4. [[redteam/archive/eig-apost-2026-10/reports/shared_dtn_risks|共享DtN风险]]：共同假设和实际独立实现。
5. [[redteam/archive/eig-apost-2026-10/reports/findings|统一发现与OPEN账目]]：分类、证据、最小下一步。
6. [[redteam/archive/eig-apost-2026-10/theory/review|独立第二读者审查]]：红队自身推导的核对及修正。
7. [[redteam/archive/eig-apost-2026-10/reports/verification|执行和文件边界]]：成功/失败日志、静态检查与并发改动。

## 冻结范围与运行规则

- 原物理模型是二维条带上的 $-\Delta u=\mu\rho u$、$\mu=k^2$，固定实Bloch
  参数、正材料权重、普通法向导数传输。基线分别从原实现和数据核实，不从旧报告
  推定当前对象；见 [[redteam/archive/eig-apost-2026-10/baseline/bie]]、[[redteam/archive/eig-apost-2026-10/baseline/fem]]。
- 所有新代码、分析、下载/提取、数据、日志和图均在 `redteam/`。
  `research/`、`test/`、公共包、论文、参考库及其他人的文件只读。
  用户明确指定本目录，覆盖根AGENTS对新实验默认放在test的规则。
- 不修改数学模型或生产接口，不复制一套求解器冒充独立实现，不提交、不推送，
  不切换分支。源版本和原有未提交改动均留档。
- 每案例先记录怀疑、预测观测、反证/通过判据、依赖、耗时/内存估计，再执行。
  单个完整科学运行计划不超过30分钟；最多一次有进度依据的10分钟宽限；
  40分钟和2 GiB为硬限。当前只运行短而串行的诊断，不重跑超预算的g48求解。
- 用MATLAB R2023b执行所有新MATLAB诊断；Conda `octave`环境的Python仅做
  启动/监控/JSON/文件完整性工作。没有用Octave替代MATLAB特定路径。
- 同方法调试复用 `attempt-1`，保留失败日志。依赖缺失、沙箱限制、结构赋值错误
  属操作失败，不构成数学反例。运行器 `run_guard.py` 在启动前检查监控权限，
  0.25秒采样进程树；采样峰值不是操作系统保证的绝对峰值。
- 数值入口只接受显式参数或数据文件，不读取Markdown/Git来决定计算。
  指纹仅为可选外层溯源，科学运行不依赖它们。

## 证据纪律

| 分类 | 定义 |
|---|---|
| CONFIRMED | 有明确论证或可复现数据确认的特定命题；必须注明是理论机制、数值事实还是生产故障 |
| CONDITIONAL | 结论在明确列出的额外条件下成立；不能把缺失条件视为已满足 |
| SUSPECTED | 有具体技术机制，但不足以确认当前实例失败 |
| RESOLVED | 排除了明确限定的怀疑；不表示整个方法已获证明 |
| OPEN | 缺少决定性证据；须给最小下一步 |

每项同时记录“已证明、数值支持、未经证明、被反例否定”。不把有限测试通过写成
严格正确性证明，不将小矩阵残差、求根区间或两路线差当成真误差。玩具反例只能
反驳其命中的推断，不能直接推翻当前生产candidate。所有区间必须标清 $k/\mu$。

## 本轮四阶段覆盖

| 阶段 | 本轮已做 | 当前边界 |
|---|---|---|
| 1 数学与实现 | 两条路线的十项审计，直接读证明、原程序及原始结果；核验局部定理/源文 | 连续DtN全适用域、谱隔离及严格评价尚未全面闭合 |
| 2 物理模态 | 保存场重建、同区域真实材料加权比较、相位、能量、端口及衰减检查 | 具体数值与近场求积限制见mode_identity；没有秩1连续谱证书 |
| 3 最小攻击 | C01–C04精确机制；C05真实BIE核折回探针 | 未做实际算例切口平移、近简并参数族或大规模扫描 |
| 4 公平成本 | 核对已有成本、范围及资源记录，制定同可信目标的比较合同 | 核心连续认证门未通过，因此不宣称同精度性能胜负，不运行新benchmark |

## 目录与复现

`baseline/` 保存候选/参数/版本及原有状态；`theory/` 保存审计和原文摘取；
`cases/` 保存预登记合同和MATLAB；`results/` 保存原始MAT/JSON、日志、资源记录；
`reports/` 为决策与统一账目。原始生产结果留在其原路径，并通过baseline链接，不覆盖。

精确机制和QP探针的成功共同启动命令位于
`results/exact-mechanisms/attempt-1/20261028T050348.754869Z-run.json`，可逐字复现。
模态提取与比较的命令/修订诊断记录位于 `results/mode-identity/attempt-1/`。
目录内的相应case文档列出所需公共函数、保存数据和FMM依赖；未安装任何新依赖。

新增代码分工：root负责独立小模型、资源启动器及综合；BIE审计者负责原核探针；
模态分工负责新FE评价器和保存BIE表示的比较。第三方分工独立检查root的证明和
跨路线推论，纠正了“同一谱簇等于同一多重本征空间”的原措辞。没有跨外部模型
上传私有源码，也未把已有审查PASS当作本轮结论。
