# Research status

更新日期：2026-07-24。

状态词含义：`established in current mainline` 仅表示主线当前给出了论证，不等于已完成独立来源核验；`needs review` 表示已有陈述或证明草案但仍需严格审计；`tentative` 表示研究性判断；`unresolved` 表示尚未解决。

## 总目标与当前主线

总目标是在固定实数准周期参数 `beta` 下，研究二维周期线缺陷波导的导模，并建立中心胞元 Müller--Rayleigh 表示与左右周期半波导出射 Cauchy 关系之间的连续耦合。当前主线的目标是证明耦合算子的商核与全局导模空间自然同构，同时显式排除或商去表示诱发的零场向量。

主线入口是 `research/mainline/theory.tex` 和 `research/mainline/theory-zh.tex`。当前范围主要是实数 `k`、严格公共投影带隙、非 Wood 参数、分片常数正材料和广义 Bloch/Jordan 模态。主线已经允许左右半波导不同；这与较早路线图的“首个证明包采用相同左右端”冻结范围不一致，`needs review`。

## 专题状态

| 状态 | 专题 | 实际结论 |
|---|---|---|
| active | 主线证明与审计 | 商空间版本的 Müller--广义 Bloch--Cauchy 核/场等价是当前主要 proof target。 |
| paused | `research/projects/half-guide-dtn/` | Stage 1 完成了符号审计、齐次半导 DtN/Riccati 验证和耦合方案建议；周期障碍半导、完整中心耦合及 MATLAB 最终验证尚未完成。该路线未整合进主线。 |
| completed project | `research/projects/cell-representation/` | 专题任务已完成：原始无条件猜想过强；给出了直接 Green 表示和带显式正则性、非 Wood 及互补问题条件的修正版。其纠正后的表示结构和商空间策略已进入主线，但主线表示定理仍为 `needs review`。 |
| completed project | `research/projects/novelty-audit/` | 文献与创新性审计及带边/共振扩展已完成。结论是多数单独组件已有先例；潜在贡献在精确耦合、无伪根核定理及认证求解器的交叉处，不能据此宣称优先权。 |
| completed planning artifact | `research/planning/muller-cauchy/` | 路线图任务已完成；它列出证明依赖、风险和退路，不表示其中定理已经证明。 |

## 相对确定的结果

- `established in current mainline`：固定 `beta` 的加权自伴算子框架，以及弱形式与分片传输形式的等价。
- `established in current mainline; source review pending`：两种周期端的本质谱为左右背景谱之并，主线附录 A 给出证明；严格公共带隙因此是当前扫描与局域化框架的基础。
- `established as framework choice`：出射对象首先作为 Cauchy 关系处理；只有 Dirichlet 投影可逆时才写成 DtN 图。
- `established as necessary formulation choice`：一般情形必须允许广义 Floquet 模态和 Jordan 链，不能只使用普通 Bloch 特征向量。
- `established as safety policy`：中心密度和全局代数未知量的唯一性不能预设；当前定理采用表示零空间的商。

## 未解决问题与 proof gaps

- `needs review`：把 Hohage--Soussi 型广义模态/Riesz 基结果适配到当前分片传输半波导和双分量、面向中心区的 Cauchy 迹。
- `needs review`：中心胞元 Müller--Rayleigh 表示的满射性、互补交换波数问题、Green 消去恒等式和表示例外集合。
- `unresolved`：显式刻画并控制中心表示零空间 `N_c` 与全局表示零空间 `N_rep`；不取商的无伪根结论尚未建立。
- `unresolved`：主要核--导模等价仍依赖主线正则集中的模态和表示假设，不能作为已完成定理引用。
- `conjectural`：自然方形实现、参考算子加紧扰动以及 Fredholm 指标为零。
- `future`：离散谱正确性、无谱污染、认证轮廓求解器、精确带边和复共振理论。
- `needs review`：英文版和中文版的符号、内容与引用核验段尚未完全同步；主线中还有失效的旧路线图路径。

## 当前优先级

1. 审计并同步中英文主线的符号、定理状态和引用来源，不改变未核实结论的等级。
2. 逐项核查 `prop:relation-Bloch` 的外部定理假设在当前传输迹空间中的适用性。
3. 审计 `thm:center-representation` 的表示满射性和零空间刻画，再处理主定理中的 `N_rep`。
4. 仅在上述工作闭合后研究 Fredholm 强化；数值离散和代码映射属于后续阶段。

下一步最自然的工作是对主线第 3、4 节做一次有明确假设清单的严格证明审计，并把结果更新到 `research/mainline/review-log.md`、本文件以及必要时的 `research/DECISIONS.md`。
