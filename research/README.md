# Research workspace

`research/` 保存尚处于研究、核查和整合阶段的理论工作。这里允许出现猜想、未证明命题、proof gap 和待核验引用；它不是正式论文草稿的替代品。

## 当前阶段

当前没有活动中的统一理论主线。原 Müller--Cauchy 主线已于 2026-07-26 冻结在
Git 标签 `mainline-muller-cauchy-2026-07-26`，并移至
`research/archive/muller-cauchy-2026-07/`。`research/projects/eig-apost/` 已确认
fixed-$\beta$ line-defect guided-mode eigenvalue 后验误差的 research question。新路线已完成
I1 candidate discovery/readiness 与 I2 的局部有限维 count、Hermitian-part 端点 sign count 和
两条单轴 candidate 比较；I2 的六个 saved candidates 均为
$1.832770289108157$，相邻层均确认为同一 mode。该结果只表示在相同扫描规则下没有观察到
candidate drift，不证明 score minimizer、finite root 或连续 eigenvalue 已收敛。

I3.1 已以全边界胞元 BIE 得到 ordinary-double continuous-residual estimator candidate，阶段为
`PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`；circle action
$256\to512$ ratio $0.77408786032496468>0.20$ 仍使该 candidate 未获内部数值资格。自
2026-08-24 起，I3.2 改为严格的条件性离散证书谱包含定理；该定理已经建立，但将 ordinary
输出实例化为严格 cap 的 application hypotheses 尚未闭合。旧 I3.2 顺延为 I3.3，研究 empirical
error caps 与 independent effectivity；旧 I3.3 顺延为 I3.4，研究 outward enclosure、认证
projected gap 和离散特征值存在性。circle-action caveat 是 I3.3 的未来 cap 目标，不阻止 I3.2
定理本身；可靠区间、gap 和存在性仍只属于 I3.4。
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
