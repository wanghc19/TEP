# Research status

更新日期：2026-08-11。

状态词含义：`established in archived mainline` 仅表示冻结主线给出了论证，不等于已完成独立来源核验；`needs review` 表示已有陈述或证明草案但仍需严格审计；`tentative` 表示研究性判断；`unresolved` 表示尚未解决。

## 当前阶段

此前的统一目标是在固定实数准周期参数 $\beta$ 下研究二维周期线缺陷波导的导模，
并建立中心胞元 Müller--Rayleigh 表示与左右周期半波导出射 Cauchy 关系之间的连续
耦合。该路线现已暂停；当前把 fixed-$\beta$ line-defect guided-mode eigenvalue 的
numerical half-guide DtN 后验误差作为专题候选方向。其 manufactured NEP、Half-guide
map 与 Augmented BIE 离散实现门已经通过；历史 Root-readiness diagnostic 及其后续
Ewald/MFS/Rayleigh、SLP/DLP 和有限 $M_{\mathrm{trace}}$ 结果保留为离散数值证据。
2026-08-11 起 I4 数值工作暂停，当前改为 continuous DtN/BIE method reconstruction：
精确 DtN 由半无限 PDE 定义，physical center pencil $\mathcal F(k)$ 先于 BIE、QZ 和矩阵。
旧 finite-tail/doubling 主方法已降为 legacy/cross-check。当前不得组装
$A_{\mathrm{def}}$，不得运行 DtN wall、locator、complex disk 或 root isolation；
`PHYSICAL_ROOT_READY=STOP`。连续—离散桥接、真实 root 和 estimator 尚未建立，也没有
活动中的 `research/mainline/`。

原主线冻结于 Git 标签 `mainline-muller-cauchy-2026-07-26`，文件移至
`research/archive/muller-cauchy-2026-07/`。冻结版本主要考虑实数 `k`、严格公共
投影带隙、非 Wood 参数、分片常数正材料和广义 Bloch/Jordan 模态，并允许左右
半波导不同。该归档只作历史参考；除非任务明确选择它，否则不支配后续新方向。

## 专题状态

| 状态 | 专题 | 实际结论 |
|---|---|---|
| active investigation / I4 numerics paused | `research/projects/eig-apost/` | 当前 Phase 4 重构稿以 PDE-defined exact DtN 和 physical $\mathcal F(k)$ 为连续主对象；continuous BIE 是待证明的 realization，ordered QZ 只计算 finite-pencil deflating subspace。旧 finite-tail 稿完整归档为 legacy。既有 implementation checkpoints 与三路径数值门保留为历史/部件证据，但不授权 $A_{\mathrm{def}}$ 或 locator。恢复 I4 前须关闭项目 ledger 的 OP-M0-1--OP-M0-4；真实 root、next-level correction、remaining-error estimator 和独立 $k_{\mathrm{ref}}$ 均未完成。 |
| paused archive | `research/archive/muller-cauchy-2026-07/` | 冻结的 Müller--广义 Bloch--Cauchy 主线；商空间版本的核/场等价仍有未闭合的外部定理适配和表示论前提。 |
| paused | `research/projects/half-guide-dtn/` | Stage 1 完成了符号审计、齐次半导 DtN/Riccati 验证和耦合方案建议；周期障碍半导、完整中心耦合及 MATLAB 最终验证尚未完成。该路线未整合进冻结主线。 |
| completed project | `research/projects/cell-representation/` | 专题任务已完成：原始无条件猜想过强；给出了直接 Green 表示和带显式正则性、非 Wood 及互补问题条件的修正版。其纠正后的表示结构和商空间策略已进入冻结主线，但其中的表示定理仍为 `needs review`。 |
| completed project | `research/projects/novelty-audit/` | 文献与创新性审计及带边/共振扩展已完成。结论是多数单独组件已有先例；潜在贡献在精确耦合、无伪根核定理及认证求解器的交叉处，不能据此宣称优先权。 |
| completed planning artifact | `research/planning/muller-cauchy/` | 路线图任务已完成；它列出证明依赖、风险和退路，不表示其中定理已经证明。 |

## 冻结主线中相对确定的结果

- `established in archived mainline`：固定 $\beta$ 的加权自伴算子框架，以及弱形式与分片传输形式的等价。
- `established in archived mainline; source review pending`：两种周期端的本质谱为左右背景谱之并，冻结主线附录 A 给出证明；严格公共带隙是该归档中扫描与局域化框架的基础。
- `established as framework choice`：出射对象首先作为 Cauchy 关系处理；只有 Dirichlet 投影可逆时才写成 DtN 图。
- `established as necessary formulation choice`：一般情形必须允许广义 Floquet 模态和 Jordan 链，不能只使用普通 Bloch 特征向量。
- `established as safety policy in the archive`：中心密度和全局代数未知量的唯一性不能预设；冻结版本的主定理采用表示零空间的商。

## 未解决问题与 proof gaps

- `needs review`：把 Hohage--Soussi 型广义模态/Riesz 基结果适配到冻结版本的分片传输半波导和双分量、面向中心区的 Cauchy 迹。
- `unresolved`：公共带隙目前只严格排除了平移算子单位圆上的点谱；单位圆全谱排除仍需另证。
- `needs review`：中心胞元 Müller--Rayleigh 表示的满射性、互补交换波数问题、Green 消去恒等式和表示例外集合。
- `unresolved`：显式刻画并控制中心表示零空间 `N_c` 与全局表示零空间 `N_rep`；不取商的无伪根结论尚未建立。
- `unresolved`：主要核--导模等价仍依赖冻结版本正则集中的模态和表示假设，不能作为已完成定理引用。
- `conjectural`：自然方形实现、参考算子加紧扰动以及 Fredholm 指标为零。
- `future`：离散谱正确性、无谱污染、认证轮廓求解器、精确带边和复共振理论。
- `needs review`：英文版和中文版的符号、内容与引用核验段尚未完全同步；冻结版本中还有失效的旧路线图路径。

## 转向期间的工作规则

1. 在新方向可以明确命名并形成稳定框架以前，不建立空的 `research/mainline/`。
2. 零散但可保留的方向讨论进入 `research/planning/`；只有形成多文件、多轮调查后才在 `research/projects/` 建立专题。
3. 不在冻结目录中继续日常开发；若恢复 Müller--Cauchy 路线，应从冻结标签建立分支，或记录决定后重新建立活动主线。
4. 归档中的未证明结论、待核验引用和中英文差异保持原有成熟度，不因归档而自动升级或失效。
5. 新方向形成后，应更新 `research/DECISIONS.md`、本文件和 `research/README.md`，再决定是否建立新的 `research/mainline/`。

当前活动专题是偏工程实现的特征值后验误差研究，但数值 I4 已暂停。下一阶段不是
full analytic Root-readiness，而是关闭 continuous exact-DtN domain、physical/BIE
kernel bridge、one-cell pencil/ordered-QZ uniform separation 与正确的 projected/regular
approximation topology 四个 formulation blockers。只有这些门关闭并重新设计
$A_{\mathrm{def}}$ 后，才可重新申请 locator 和 analytic-disk readiness；此前不得启动
任何 DtN wall、locator、contour、complex root matching 或 estimator 计算，也不升级为
统一研究方向。
冻结路线若被恢复，其优先事项仍是单位圆全谱排除、
广义 Floquet/Riesz 基适配、中心表示满射性和表示零空间刻画；具体记录见
`research/archive/muller-cauchy-2026-07/review-log.md`。
