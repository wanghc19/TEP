# 决定

## 2026-11-04 新建项目（用户）

- FEM 线暂停后（[[research/projects/fem-goerisch/DECISIONS|fem-goerisch DECISIONS]] 同日条），BIE 可靠区间独立成项目 `research/projects/bie-enclosure/`，目录分类与 fem-goerisch 相同。
- ChatGPT Pro 报告移入 `theory/reliable-bound.md`，原文不改，审查写进配对的 `-review` 文件。
- 论文草稿改为被追踪的 `draft/bie-enclosure/`；`draft/tmp/bie-theory-rewrite/` 保留不动。
- 审查线程与 sol 同时派工；等审查回复后再分批提交。

## 2026-11-04 场的定义（经理建议；报告审查已确认 T2.1–T2.3）

采用报告 T2 的路线：把实际的 augmented MFS 有限表示（固定的密度、MFS 修正系数和传播系数）定义为数学场，上下接缝的准周期失配作为一类新界面计入 $\varepsilon$。理由：I9.2 的接缝跳跃平方只占 $\varepsilon^2$ 的约 0.1%，而另一条路线要给 $G_{\rm MFS}-G_{\rm QP}$ 的可计算界，更贵。
