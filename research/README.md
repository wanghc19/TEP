# Research workspace

`research/` 保存尚处于研究、核查和整合阶段的理论工作。这里允许出现猜想、未证明命题、proof gap 和待核验引用；它不是正式论文草稿的替代品。

## 当前阶段

当前没有活动中的统一理论主线。原 Müller--Cauchy 主线已于 2026-07-26 冻结在
Git 标签 `mainline-muller-cauchy-2026-07-26`，并移至
`research/archive/muller-cauchy-2026-07/`。`research/projects/eig-apost/` 已确认
fixed-$\beta$ line-defect guided-mode eigenvalue 后验误差的 research question，并已
完成 Phase 2b novelty gate、Phase 3--4 方法设计和三个离散实现 checkpoint。最新结果为
`STAGE2_DISCRETE_ALGEBRA_GO`，但 `ROOT_READY=STOP`：它不构成真实 eigenvalue estimator，
也不构成新的统一主线。在形成可以明确命名且经过审核的统一框架以前，不建立空的
`mainline/` 作为占位。

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
