# Research decisions

这里只记录能由现有文件支持的研究决定。`Revisitable` 表示将来可在新证明或新证据下重新审议。

## 2026-07-13 阶段：DtN 只作为独立可行性路线

- **决定：** 直接半波导 DtN 暂不替换当前主线的出射 Cauchy 关系。若恢复原型工作，优先采用保留中心未知量 `(eta, xi)`、只替换端口行的 Scheme A；局部胞元 Riccati/QZ 是主要研究路线，scattering-to-DtN 只作诊断。
- **理由：** 严格无耗散情形存在单位圆传播分支，Dirichlet 投影也可能奇异或病态；关系表述更稳健。
- **证据：** `research/projects/half-guide-dtn/STATUS.md`，`research/projects/half-guide-dtn/DECISIONS.md`。
- **影响：** 该专题未整合进 `research/mainline/`；后续需先完成周期障碍半导和完整耦合。
- **状态：** Revisitable；当前为 paused。

## 2026-07-14 阶段：修正单胞表示命题

- **决定：** 不再把原始“齐次背景场加公共密度层势且无条件唯一”的表述当作定理。区分总是可用的直接 Green 表示与需要互补交换波数问题可解性的公共密度 Müller 表示，并显式保留表示零空间或商空间。
- **理由：** 原表述遗漏 Wood 阈值、广义阈值解和互补问题的谱条件；密度唯一性不等于物理场唯一性。
- **证据：** `research/projects/cell-representation/proof-log.md`，`research/projects/cell-representation/README.md`，`research/projects/cell-representation/open-questions.md`。
- **影响：** 修正的波数配对、表示例外集合、`N_c` 和商空间结构已写入主线第 4 节及附录 B；其完整严格性仍为 `needs review`。
- **状态：** 当前 formulation 决定已采用；具体假设可重审。

## 2026-07-20 阶段：收窄创新性主张

- **决定：** 不把有界域约化、DtN、普通 Müller BIE、Bloch pencil、奇异值扫描或通用轮廓算法单独宣称为创新。当前候选贡献聚焦于高阶 Müller 中心表示、广义稳定 Bloch Cauchy 关系、无伪根核定理与认证离散的精确交叉。
- **理由：** 创新性审计发现多数单独组件已有直接先例；尚未检索到完全重合工作也不构成优先权证明。
- **证据：** `research/projects/novelty-audit/README.md`，`research/projects/novelty-audit/r-claims.md`，`research/projects/novelty-audit/progress.md`。
- **影响：** 主线应把已知组件标为 background/adaptation，把新颖性押在可严格证明的耦合结果上。
- **状态：** Revisitable，需随新文献更新。

## 2026-07-21 阶段：关系优先、广义模态、商空间默认

- **决定：** 半波导外部对象以闭 Cauchy 关系为主，DtN 仅是正则图坐标；模态必须包含广义 Floquet 模态与 Jordan 链；第一主定理默认采用 `ker A / N_rep` 与导模空间的同构，不取商版本必须另证 `N_rep={0}`。
- **理由：** 这同时处理 DtN 图失效、普通特征向量不完备和表示密度零空间三类风险。
- **证据：** `research/planning/muller-cauchy/README.md`，`research/planning/muller-cauchy/scope.md`，`research/planning/muller-cauchy/p-theorems.md`。
- **影响：** 已整合到主线第 3--5 节。
- **状态：** 当前主线 formulation；若有更强唯一性定理可强化，不应静默改写。

## 2026-07-21 阶段：Fredholm 仅作条件性强化

- **决定：** 不从“第二类结构”直接推出完整耦合算子 Fredholm 指标为零。先完成固定参数的商核--导模等价；Fredholm 只在找到自然方形实现和“可逆参考算子加紧扰动”分解后推进。
- **理由：** 关系行可能是矩形，端口块的紧性与商空间对指标的影响尚未解决。
- **证据：** `research/planning/muller-cauchy/p-proofs.md` 中 L15/T2，`research/planning/muller-cauchy/p-risks.md`，主线第 5 节 `conj:Fredholm`。
- **影响：** Fredholm 结论保持 conjectural，不是当前主定理的前提。
- **状态：** Revisitable。

## 当前阶段：范围差异需重新确认

- **事项：** 路线图冻结的首个证明包排除了不同左右周期端，而当前主线第 2 节和附录 A 已显式处理两种不同周期端。
- **证据：** `research/planning/muller-cauchy/scope.md`；`research/mainline/en/s-setting.tex`；`research/mainline/en/a-essspec.tex`。
- **处理：** 按权威顺序，当前理论任务以主线为准；但应审计第 3--5 节的模态与耦合假设是否也完整支持非对称端，再决定是否把路线图范围正式扩展。
- **状态：** `needs review`，不是已补写的历史决定。

## 2026-07-24 协作政策：进入草稿必须人工审核

- **决定：** `projects/` 的结论不得自动提升到 `mainline/`，`mainline/` 也不得自动提升到 `draft/`。
- **理由：** 专题完成、主线存在陈述和论文可发表性是三个不同层级。
- **影响：** 每次晋升都需明确人工审核，并同步 `research/STATUS.md`、本文件和必要的主线审计记录。
- **状态：** 当前协作规则。
