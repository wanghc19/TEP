# FEM–DtN–Goerisch 特征值包含区间

本项目把 [[research/explorations/numerical-directions/README|numerical-directions]] 中做成的方法独立成项目：对 $y$ 周期线缺陷波导的固定 $\beta$ 导模特征值，用 FEM + DtN 试探场、Lehmann–Goerisch 型四角证书和隔离假设 (H) 的认证，给出截断误差意义下可靠的包含区间（舍入用舍入误差估计处理）。

缩写：FEM = 有限元方法；DtN = Dirichlet-to-Neumann 映射；BIE = 边界积分方程（只作参考解）。

## 已有结果（单一算例，$\beta=0.5$）

- 主区间 $[2.4287286691977,\,2.4287286736602]$，宽 $4.462\times10^{-9}$；(H) 已认证（舍入排除），舍入误差估计不威胁任何判断。
- 论文与讲义：`draft/fem-goerisch/`。
- 证明：[[research/explorations/numerical-directions/qj-bounds-proof|qj-bounds-proof]]（四角证书）、[[research/explorations/numerical-directions/h-cert-proof|h-cert-proof]]（(H) 的认证）、[[research/explorations/numerical-directions/goerisch-width|goerisch-width]]（宽度与命题 5）、[[research/explorations/numerical-directions/dtn-inertia-count|dtn-inertia-count]]（计数定理）；各自的复核与审查记录在同一目录。
- 舍入与成本：[[research/explorations/numerical-directions/rounding-estimate|rounding-estimate]]、[[research/explorations/numerical-directions/accel-probe|accel-probe]]。
- 实验（只读，不移动）：`test/numerical-directions/` 下 `fem-pipeline-v1`（试探场与根）、`qj-cert-v2`（$E,M,S$ 与四角区间）、`gap-ends-v1`（谱隙端点）、`h-cert-v1`（表面态）、`h-dtn-v1`（DtN 下界矩阵）、`h-core-v1`（芯区计数）、`rounding-estimate-v1`、`accel-probe-v1`。

## 本项目的目标

1. 把现有代码改成可换参数（几何、材料、窗口、$\beta$、缺陷）的流程，代码清单见 [[research/projects/fem-goerisch/implementation/code-inventory|code-inventory]]。
2. (H) 分两种算法交付：常规计算以 (H) 为前提，做浮点检查并报告余量；另交付严格验证 (H) 的算法，需要时运行（[[research/projects/fem-goerisch/DECISIONS|DECISIONS]] 2026-11-04 条）。
3. 稳健性：用参数族看余量随参数的变化，以及能否构造 (H) 不成立的例子（两个不相交的一阶区间 $I_1$）。尚未开始设计。

## 约定

- 新代码放在 `test/fem-goerisch/`，按 `test/AGENTS.md` 的实验目录规则；在流程稳定、准备发布之前不新建共享包。
- 顶层只放四个项目文件：本 README、[[research/projects/fem-goerisch/STATUS|STATUS]]（只写当前状态，保持简短）、[[research/projects/fem-goerisch/DECISIONS|DECISIONS]]、[[research/projects/fem-goerisch/open-problems|open-problems]]（唯一的问题清单）。
- 其余文件按类型放进子目录，不按阶段分，也不为单个引理建目录：
  - `theory/`：问题陈述、证明、证明复核与审查；
  - `implementation/`：代码清单、流程设计、各阶段的实验报告；
  - `literature/`：查新与文献调研。
- 复核和审查与被审文件放在同一目录，文件名加后缀配对，例如 `h-cert-proof.md` 与 `h-cert-proof-review.md`。
- 一个主题一个报告：重跑和补充写进原报告，不另开新文件。
- `research/explorations/numerical-directions/` 的旧文件不移动，作为本方法的历史来源，只在这里链接。
