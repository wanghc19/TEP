# BIE 导模特征值的可靠包含区间

本项目研究：对 $y$ 周期线缺陷波导的固定 $\beta$ 导模，用 BIE 候选 $(\widehat k,\widehat u)$ 和基于预解式的谱距离定理，给出截断误差意义下可靠的谱距离界 $\operatorname{dist}(\mu,\sigma(A(\beta)))\le 2\mu Q/(U-Q)$，其中 $\mu=\widehat k^2$，$Q=C\varepsilon$。目标是在 40 分钟、3 GiB 内得到全宽不超过 $5\times10^{-9}$ 的区间，并说明它相对 FEM 路线（[[research/projects/fem-goerisch/README|fem-goerisch]]）的优点。

缩写：BIE = 边界积分方程；MFS = 基本解方法（augmented MFS 用来近似准周期 Green 函数）；QP = 准周期；FMM = 快速多极方法；FEM = 有限元方法。

**2026-11-08 停止（用户决定）**：本项目及其英文稿 `draft/bie-siam/`、求解器稿 `draft/bie-solver/` 全部停止，不再研究；原因见 `draft/bie-siam/README.md`“停止”一节和 [[research/projects/bie-enclosure/DECISIONS|DECISIONS]]。以下内容为历史记录。

## 已有材料

- 理论：[[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]]（ChatGPT Pro 报告：两引线本质谱、MFS 场与接缝、求积误差界、更小的迹常数、加速；待审查）。
- 论文草稿：`draft/bie-enclosure/`（由 `draft/tmp/bie-theory-rewrite/` 复制并按报告修改）。
- 先导与查新（留在原处，只链接）：[[research/explorations/numerical-directions/bie-eval-pilot|bie-eval-pilot]]（同一个场的浮点评价，$W\le1.55\times10^{-9}$）、[[research/explorations/numerical-directions/bie-novelty|bie-novelty]]（查新）。
- 实验：`test/bie-bound/`（`eval-pilot-v1` 只读；新实验按版本另建目录）。I9.2 的原始实验 `test/i9/` 只读。

## 约定

与 [[research/projects/fem-goerisch/README|fem-goerisch]] 相同：

- 顶层只放本 README、[[research/projects/bie-enclosure/STATUS|STATUS]]、[[research/projects/bie-enclosure/DECISIONS|DECISIONS]]、[[research/projects/bie-enclosure/open-problems|open-problems]]。
- `theory/`：问题陈述、证明、复核与审查；`implementation/`：流程设计与实验报告；`literature/`：查新与文献调研。
- 复核和审查与被审文件放在同一目录，文件名加后缀配对，例如 `reliable-bound.md` 与 `reliable-bound-review.md`。
- 一个主题一个报告；重跑和补充写进原报告。
- `research/explorations/numerical-directions/` 的旧文件不移动。
