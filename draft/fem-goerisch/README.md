# fem-goerisch：FEM--DtN 与 Lehmann--Goerisch 可靠区间讲义

FEM = finite element method（有限元法）；DtN = Dirichlet-to-Neumann；Goerisch 指 Lehmann--Goerisch 特征值区间方法。

- `lecture-notes.tex`：中文详细讲义，自成一体（证明在文中重新整理，不引用 research 文件）。编译：`latexmk -xelatex lecture-notes.tex`，之后 `latexmk -c lecture-notes.tex`。（2026-11-04 由 `main.tex` 改名。）
- `paper.tex`：中文论文草稿（2026-11-04 开始），按论文标准压缩讲义内容：定理与证明简洁写出，引用 `ref/reference.bib` 中已核对的文献，无目录、无 hyperref。编译：`latexmk -xelatex paper.tex`，之后 `latexmk -c paper.tex`。
- `paper-nonote.bst`：`plainnat.bst` 去掉 note 和 url 字段的输出，供 `paper.tex` 使用（`ref/reference.bib` 的 note 字段是内部来源记录，不应出现在论文中）。
- `preamble.tex`：讲义的导言区，由 `draft/fem-dtn-epost/` 复制并补充；`paper.tex` 用自己的导言区（无 hyperref）。

## 讲义进度

用户要求（2026-11-03）：中文详细讲义，证明完整写出、重新整理，不引用 research 中的长文件。

| 节 | 内容 | 状态 |
|---|---|---|
| 1 | 问题与结论 | draft 完成（摘要也已写） |
| 2 | 模型与记号 | draft 完成 |
| 3 | DtN 约化 | draft 完成 |
| 4 | Lehmann--Goerisch 区间 | draft 完成 |
| 5 | 试探场与通量 | draft 完成 |
| 6 | 四角证书 | draft 完成 |
| 7 | (H) 的计数框架 | draft 完成 |
| 8 | 带隙证书 | draft 完成 |
| 9 | 表面态 | draft 完成 |
| 10 | 半导波 DtN 单侧界 | draft 完成（h-dtn-v1 结果已填） |
| 11 | 芯区最终计数 | draft 完成（h-core-v1 结果已填） |
| 12 | 结果与成本 | draft 完成 |
| 13 | 局限 | draft 完成 |

(A)–(D) 结果都已填入（2026-11-04），第 1、11、13 节和摘要已改为“(H) 成立（舍入排除）”。h-core-v1 已通过审查线程复核（0/0/0）。下一步：送审查线程复核全文证明。

写作中的改动（相对原证明）：第 4 节区间定理用谱测度直接证明，条件弱化为 $q<t_+$、$t_-J<1$；第 6 节四角定理相应只需 $D_{t_-}>0$、$D_{t_+}<0$ 和 $q_{\max}<t_+$（原证明另有 $H>0$ 测试）。第 8 节上端面板检验改用 $N_\le\le n+z$ 直接证明，不再用 Schur 补论证。第 9 节以“下端点正定 + 单调性”为主线（推论 9.x），端点计数定理作为一般情形；$\alpha_+$ 处的计算作为一致性检查。第 6 节质量修正界按扫掠恒等式重新推导。第 10 节补了传递矩阵几何级数尾项的引理（h-dtn-v1 README 中只有结论）。这些改动未经审查线程复核。

## 论文草稿进度

| 节 | 内容 | 状态 |
|---|---|---|
| 摘要、1 | 引言 | draft 完成 |
| 2 | 模型与约化形式 | draft 完成 |
| 3 | Lehmann--Goerisch 区间 | draft 完成 |
| 4 | 试探场、通量与积分的可靠界 | draft 完成 |
| 5 | 隔离假设：计数判据与引线检验（5.1 计数判据、5.2 带隙、5.3 表面态） | draft 完成 |
| 6 | 端点处的 DtN 下界与芯区计数（6.1 DtN 下界、6.2 芯区计数与 (H) 的证明） | draft 完成（h-core-v1 结果已填） |
| 7 | 数值结果与讨论（7.1 主要结果、7.2 成本、7.3 结论与局限） | draft 完成 |

2026-11-04 按用户要求由 11 节压缩为 7 节：原第 5–7 节并为第 5 节，原第 8–9 节并为第 6 节，原第 10–11 节并为第 7 节；正文内容未删，原小节降为 subsubsection。

论文草稿的证明是讲义证明的压缩版，未经审查线程复核。引用只用 `ref/README.md` 中已核对的条目，表述按其中的说明。

## 素材来源（只供写作者核对，讲义正文不引用）

- 区间定理与宽度：`research/explorations/numerical-directions/goerisch-width.md`
- 计数定理：`research/explorations/numerical-directions/dtn-inertia-count.md`
- 四角证书：`qj-bounds-proof.md`；数值：`test/numerical-directions/qj-cert-v1/`、`qj-cert-v2/`
- (H)：`h-cert-proof.md`；数值：`test/numerical-directions/h-cert-v1/`、`h-dtn-v1/`、`h-core-v1/`
- 管线与成本：`test/numerical-directions/fem-pipeline-v1/`、`gap-ends-v1/`
- 模型、DtN 约化：`draft/fem-dtn-epost/main.tex` §2–§5
