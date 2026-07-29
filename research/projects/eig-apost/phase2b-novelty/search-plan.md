<!-- Reproducible novelty search plan for the eig-apost candidate contribution -->

# Phase 2b search plan

## 1. Search-bounded question

截至 2026-07-26，在可检索的英文同行评审论文、正式会议论文、专著章节和可核验
preprint 中，是否已有工作实质覆盖以下候选贡献：在 fixed-$\beta$ periodic line-defect
guided-mode eigenvalue problem 中，以 BIE 构造 cell boundary map，以 finite-tail 或
doubling 逼近 half-guide DtN，并给出无穷远截断导致的 eigenvalue error 的可计算后验
估计及 effectivity 验证？

该问题只允许产生 search-bounded 结论，不允许产生“全局首次”结论。

## 2. Claim decomposition

| 编号 | 候选环节 | 需要排除的已有结论 |
|---|---|---|
| C1 | fixed-$\beta$ line-defect guided-mode eigenvalue | 已有相同物理对象和谱参数设置 |
| C2 | BIE cell map 与 half-guide DtN/RtR/NtD | 已有等价 boundary-map 构造 |
| C3 | structure-preserving finite-tail 或 doubling hierarchy | 已有相同半无限尾部近似 |
| C4 | DtN truncation 到 eigenvalue shift 的 computable estimator | 已有针对同类根的定量后验估计 |
| C5 | simple-root projected correction 与 effectivity | 已有等价校正及渐近有效性结论 |
| C6 | 独立 formulation/reference truth 验证 | 已有同类 benchmark 与有效数字认证 |

公式或一般工具本身不视为候选创新。只有 C1--C5 的实质交叉可能通过 gate；C6 是证据
强度要求，不单独构成理论创新。

## 3. Search layers

1. 本地 corpus：`ref/ref_data/`、[[research/projects/eig-apost/phase2-sources/r-sources|Phase 2
   来源矩阵]] 和旧 [[research/projects/novelty-audit/README|novelty audit]]。
2. Crossref/DOI、出版社、作者或机构仓储：核验正式元数据和合法公开全文。
3. arXiv、OpenAlex、Semantic Scholar 及通用学术网页检索：发现同义术语和近年工作。
4. backward chasing：检查 Fliss、Joly、Giani、Li--Lu、Yuan--Lu 等核心来源的参考文献。
5. forward chasing：查找引用上述核心来源且同时出现 estimator、truncation、BIE、DtN
   或 guided eigenvalue 的工作。

## 4. Query families

```text
(photonic crystal waveguide OR line defect) AND
  (guided mode OR eigenvalue) AND
  (a posteriori error OR estimator OR eigenvalue error)

(fixed beta OR quasiperiodic OR quasi-periodic) AND
  (guided mode OR defect mode) AND
  (Dirichlet-to-Neumann OR DtN) AND
  (error estimator OR truncation error)

(boundary integral OR BIE OR boundary element) AND
  (periodic waveguide OR semi-waveguide OR half-guide) AND
  (DtN OR NtD OR RtR OR transparent boundary) AND
  (Riccati OR doubling OR finite section OR finite tail)

(nonlinear eigenvalue OR operator function) AND
  (a posteriori OR projected correction OR eigenvalue estimator) AND
  (DtN OR boundary truncation OR domain truncation)

(guided mode OR defect mode) AND
  (domain truncation OR supercell OR finite section) AND
  (eigenvalue error OR effectivity OR exponential convergence)
```

对每个 query family 追加目标作者、题名片段和术语变体，例如 `Poincare-Steklov`、
`impedance map`、`marching operator`、`recursive doubling`、`quadratic eigenvalue` 和
`residual estimator`。

## 5. Inclusion and exclusion

纳入：

- 明确覆盖 C1--C5 至少一项，或可能实质覆盖至少两项的来源；
- 同行评审原始论文、正式章节或存在性可独立核验的 preprint；
- 英文全文优先；若最接近来源只能读取摘要，则保留但标记 `access-limited`；
- 基础来源不限年份，检索截止日期为 2026-07-26。

排除：

- 只讨论 scattering 而没有可迁移的 half-guide boundary-map/truncation 机制；
- 只估计 FEM/BEM mesh error，且没有 eigenvalue 或 truncation 联系；
- 只给 band-structure/supercell convergence 图而没有误差结论；
- 只出现一般 NEP condition number，未连接到 DtN/domain truncation；
- 无法核验存在性的引用、二手博客和搜索摘要拼接。

排除不等于“无关”：能够削弱宽泛创新声明的近邻来源进入 `claim-matrix.md`，但标记为
`adjacent` 而不是 `exact`。

## 6. Verification rules

- DOI、题名、作者、年份和 venue 至少通过 DOI/出版社或机构仓储核验一次。
- 核心近邻必须回到原文，定位 problem class、method、error quantity 和 conclusion。
- 需要且可合法下载的全文保存到 `ref/ref_data/`，命名遵守
  `<FirstAuthorSurname><PublicationYear>.pdf`；下载后核验题名页身份。
- 只读摘要的来源不得支撑“没有 estimator”“没有 proof”一类否定性判断。
- “未找到完全重合工作”必须同时报告数据库/搜索层、时间边界、最后检索日期和最接近
  来源；不得改写成全局不存在。

## 7. Gate outcomes

| 结果 | 条件 | 后续动作 |
|---|---|---|
| `PASS` | 未发现实质覆盖 C1--C5 的单篇或同一研究系列；核心近邻均完成原文核验 | 保留窄化候选贡献，并使用 search-bounded wording |
| `PASS WITH CONDITIONS` | 未发现完整覆盖，但关键近邻全文不可得、forward chasing 不完整或某一术语族覆盖不足 | 允许低成本理论探索，不允许冻结 novelty claim |
| `REVISE` | 已有工作覆盖 C1--C4，剩余差异主要是实现或验证细节 | 重写 RQ/贡献，重新过 gate |
| `STOP` | 已有工作实质覆盖 C1--C5，或剩余差异不足以形成可发表问题 | 停止当前论文主张，转向新的误差对象或失败机制 |

无论 gate 结果如何，单独的 BIE、DtN、doubling、simple-root perturbation 和
singular-value scan 均不得作为创新点。
