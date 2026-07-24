# Research workspace

`research/` 保存尚处于研究、核查和整合阶段的理论工作。这里允许出现猜想、未证明命题、proof gap 和待核验引用；它不是正式论文草稿的替代品。

## 层级

- `mainline/`：当前统一理论主线，也是 `research/` 内数学表述和符号的第一权威。英文入口为 `research/mainline/theory.tex`，中文入口为 `research/mainline/theory-zh.tex`。主线中的命题仍需依据其状态标记和 `research/mainline/review-log.md` 判断成熟度。
- `projects/`：独立专题研究、文献检索和 Codex 长任务输出。当前包含半波导 DtN 可行性研究、单胞表示研究和论文创新性审计。
- `planning/`：研究路线、证明依赖、风险、备选结果和未来工作安排。它负责规划，不替代正式数学陈述。

一般内容流向为：

```text
research/projects/
    → research/mainline/
    → draft/
```

该箭头表示“经审核后可能整合”，不是自动晋升：

- 专题结论不得自动进入 `mainline/`；
- `mainline/` 中的内容也不代表已经可以直接进入论文草稿；
- 只有经过明确的人工审核，内容才可以进入 `draft/`；
- `pre/` 是阶段性演示或展示材料；
- `legacy/` 是历史材料，不是当前研究的权威来源，除非任务明确要求历史追溯。

新 agent 应先读根目录 `AGENTS.md`，再读本文件、`research/STATUS.md` 和 `research/NOTATION.md`，随后只读取与任务相关的主线、规划或专题文件。
