# bie-solver：两侧周期半引线导模的 BIE 求解器

BIE = boundary integral equation（边界积分方程）。英文稿讨论固定 Bloch 波数下的导模候选、加边 Floquet 闭合及 Dirichlet 极点。RtR = Robin-to-Robin，DtN = Dirichlet-to-Neumann，QZ = 广义 Schur 分解。`main.tex` 为入口。在本目录运行 `latexmk main.tex`，生成 `main.pdf`。引用使用 `../../ref/reference.bib`。

**状态（2026-11-08）**：在已知文献调研范围内，BIE 特征值求解器这一块未找到尚未解决的有价值问题（[[research/explorations/bie-dtn-2026-11-08/README|查新归档]]），本稿不再作为独立论文推进。

## 直接模态匹配的文献定位（2026-11-08）

- 在同一物理领域，[Botten 等 2004，式 (38)](https://doi.org/10.1103/PhysRevE.70.056606) 以两侧 Bloch 振幅匹配完整平面波状态，然后求散射矩阵。[Cho–Barnett 2015，期刊版式 (47)、(53)](https://users.flatironinstitute.org/~ahb/papers/mlqp.pdf) 已在周期层受迫散射的边界积分系统中联立界面密度、代理源和上下外区的出射 Rayleigh 振幅。上述两文分别覆盖了模态匹配和保留外区振幅的 BIE 构造。
- 在束缚态计算中，[Istas 等 2018，式 (7)–(10)](https://pure.tudelft.nl/ws/portalfiles/portal/51210594/pdf.pdf) 将紧束缚模型的中心波函数和半无限引线倏逝模系数联立为齐次方程，显式给出消元后的自能形式，并以未消元方程求束缚态。对行波稳定性问题，[Goh–de Rijk，命题 2.3、式 (2.4)](https://math.bu.edu/people/rgoh/research/cgl_stab.pdf) 给出 Riccati–Evans 函数等于完整 Evans 匹配行列式除以两个坐标块行列式的关系。两者是不同模型中的直接代数先例，供补充引文使用。
- 因而，保留 $c_\pm$、避免 Dirichlet 消元、由消元因子解释零极点的通用原理均不宜列为本稿原创。定理 5.2 给出本离散的具体因子和核对应；表 1、图 2 展示特定求解器的失效与恢复。现有证据尚不足以将这两项合为独立的数值分析创新。若调整投稿方向，应先核查另一项分析或算法增量能否超出现有结果。

## 当前结构

| 文件 | 内容 |
|---|---|
| `sec-intro.tex`、`sec-model.tex`、`fig-waveguide.tex` | 文献定位、分段介质、人工竖直边界、传输特征值问题与公共带隙。`fig` 表示 figure。 |
| `sec-method.tex`、`sec-leads.tex` | 胞元边界积分方程、Rayleigh 端口、Floquet 束、有序 QZ、通量中性及衰减维数。 |
| `sec-closure.tex` | 加边核对应、DtN 行列式因子和抵消、人工竖直边界移动引理及与 RtR 的等价性。 |
| `sec-search.tex` | 局部解析标架、搜索、重构和物理场检验，含 Wood 频段的排除规则。 |
| `sec-experiments.tex`、`pole-scan.dat` | 三种边界位置、同频扫描图、异质与 W3 算例、选阶及有限元根值。`dat` 表示 data；文件头注明两列诊断量的数据来源。 |
| `sec-acknowledgments.tex` | AI（artificial intelligence）使用说明和作者待核查事项。 |

`sec` 表示 section。正文中的红色 TODO 标示可选的同胞元 RtR 对照、若增加更强主张所需的收敛证明或计时，以及作者核查与发布信息。定理只刻画声明假设下的离散根。可靠区间稿另见 `../bie-siam/`。

## 数值来源

- `../../test/bie-bound/pole-free-v1/` 的 `results/roots.csv`、`results/old-route.csv`、`results/counts.csv` 记录各网格的加边根、旧搜索状态和扫描计数。18 次扫描采用原始加边矩阵的最小奇异值。
- 扫描图的 83 个共同频率取自 `failure-probe-v1/output/run-023/cut192-near-grid/summary.json` 的 `rows` 与 `pole-free-v1/output/run-010/scan-192.json` 的 `grid`（目录均在 `../../test/bie-bound/` 下）。图中的特殊点分别取自旧扫描的 `minimums`、加边扫描的 `minimums` 及 `pole-free-v1/output/run-018/control.json` 的细网格极点评价。早期四次投影匹配扫描见 `failure-probe-v1/README.md`。
- `litbench-v1/` 的 W3 反算、`rayleigh-order-v1/` 的局部选阶数据和 `solver-cost-v1/` 的 BIE 计时均采用旧 DtN 实现。W3 的固定 Bloch 波数加边结果来自 `pole-free-v1/`。独立有限元根值来自 `solver-cost-v1/`。Wood 数据来自 `wood-fallback-v1/`。
- `sec-appendix.tex`、`sec-truncation.tex` 和 `sec-wood.tex` 是第一版留下的专题材料，当前 `main.tex` 不加载它们。版本 `043edf6` 保留了原稿、近通量守恒矩阵的维数判据、Rayleigh 截断根误差分析和完整 Wood 调查。当前正文不引用这些独立结果。
