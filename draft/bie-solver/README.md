# bie-solver：两侧不同周期引线的线缺陷导模 BIE 求解器（SIAM 草稿，骨架）

BIE = boundary integral equation（边界积分方程）；DtN = Dirichlet-to-Neumann；QZ = 广义 Schur 分解；SIAM = Society for Industrial and Applied Mathematics。

2026-11-07 用户决定把候选计算从 `draft/bie-siam/`（保证区间论文）拆出来单独成文。两篇的分工：

- 本稿：固定 $\beta$ 时怎样算导模候选。内容包括端口 Rayleigh 展开、每个胞元的 Müller 型 BIE 与准周期 Green 函数、引线胞散射矩阵与稳定 Schur 子空间、中心消元与离散 DtN、行列式求根。只做数值方法论文，不给候选的误差界。
- `draft/bie-siam/`：给定候选数据，构造试探场，证明谱距离界并可靠计算区间。它只引用本稿说明数据从哪里来，正确性不依赖本稿。

## 文件

- `main.tex`：骨架。除方法节外，其余各节只有 TODO 提纲。
- `sec-method.tex`：原 `draft/bie-siam/sec-discretization.tex`（提交 cc23eea）原样移入，只把对保证区间论文的交叉引用换成占位宏 `\companion`。还没有按本稿重写。
- `latexmkrc`、`siamplain-nonote.bst`：与 `draft/bie-siam/` 相同。
- 编译：在本目录运行 `latexmk main.tex`，之后运行 `latexmk -c main.tex`。

## 进度

- done（2026-11-07）：建骨架，方法节移入，可以编译（4 页，无 overfull，无未定义引用）。
- done（2026-11-07）：查新 [[bie-solver-novelty]]，总评 B（直接推广）。最接近的是 Fliss–Klindworth–Schmidt 2015（同一固定 $\beta$ 模型，允许两侧不同包层，FEM + RtR）、Petropoulos–Turc 2025（BIE 胞 RtR 与稳定束闭合，但是声软同质阵列的受迫散射）、Botten 等 2006（线导模即 $\det Z(k,\alpha_0)=0$，多极展开，单一体材料）。单独成文的条件：等任务、等精度下与高阶 FEM–DtN/RtR 比误差和成本（E1），再加圆柱情形与 Botten/Dossou 边界方法对照（E2 的最简部分）。12 项审稿检查：4 项已有记录，5 项部分，3 项缺失。贡献陈述草案和应避免的说法见查新文件。
- 待办（等用户决定）：是否做 E1、E2；18 项候选文献哪些入库。
- 待办（已知缺陷）：提取矩阵 $\mathsf F^{\rightarrow}_{x_p},\mathsf F^{\leftarrow}_{x_p}$ 只有文字描述，需要写出公式；全节行内公式过密，需要改写。
- 待办：模型节从 `draft/bie-siam/` 第 2.1 节取记号。
