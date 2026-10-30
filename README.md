# Periodic waveguides and eigenvalue problems

## 项目与阅读入口

本仓库保存二维周期波导及相关特征值、散射问题的 MATLAB 代码、研究材料和讲义。
`eig-apost` 专题研究固定 Bloch 参数下线缺陷局域模态的计算与后验误差估计，
包括 BIE 和 FEM＋DtN 两条数值路线。

| 内容 | 阅读入口 |
| --- | --- |
| 仓库工作约定 | [AGENTS.md](AGENTS.md)；Claude 入口为 [CLAUDE.md](CLAUDE.md) |
| 研究目录与进展 | [研究入口](research/README.md)、[研究状态](research/STATUS.md) |
| 特征值后验误差专题 | [专题入口](research/projects/eig-apost/README.md)、[专题状态](research/projects/eig-apost/STATUS.md) |
| 阶段设计与审查 | [implementation/](research/projects/eig-apost/implementation/) |
| 数值实验 | [test/](test/)；具体参数、运行方式和结果见对应实验目录 |
| FEM＋DtN 讲义与教程 | [draft/fem-dtn-epost/](draft/fem-dtn-epost/) |
| 独立探索 | [research/explorations/](research/explorations/) |

具体进展与数值结果由各专题和实验记录维护，首页不重复汇总。
作判断时核对相关文件与原始结果，并遵守所在目录的 `AGENTS.md`。

## 数学语言与结果表述

以下约定用于仓库文档、研究讨论、实验报告及交接 prompt。
优先说明数学对象、计算操作和结果含义，使用直接、通行的数学语言，少用流程标签。
简化措辞时保留必要假设，不改变数学结论的含义。

### 术语

| 情形 | 使用的表述 |
| --- | --- |
| 用数值方法计算误差或谱距离估计表达式 | “误差估计”或“谱距离估计”；英文用 error estimate 或 spectral-distance estimate |
| 已有数学保证，所给数值不小于目标误差或谱距离 | “可靠上界”；英文用 guaranteed upper bound |
| 上界依赖尚未核实的条件 | “在所列条件下成立的上界”，并说明条件 |
| 计算过程中保持场、候选或参数不变 | “固定场”“固定候选”“固定参数”；英文用 fixed 或 held fixed |
| 增加有限元近似空间中的自由度或多项式次数 | “扩充有限元空间” |

在上述语境中，不使用“严格认证”“冻结”等流程化措辞，也不用 frozen 代替 fixed。
原文引用、文献标题、代码标识和历史结果标签保留原样；解释其含义时使用本节术语。

## 文件命名

- 名称简短、含义明确，并沿用所在目录的命名习惯。
- 仅在缩写已经通用或能明显帮助理解时使用，不为套模板增加前缀、缩写或限定词。
- 不为统一外观重命名已有文件；确需改名时先核对调用与文档引用。
- 子目录有更具体的命名约定时，遵循其适用范围内的规则。
