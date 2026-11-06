# bie-enclosure：BIE 导模谱距离界论文草稿

BIE = boundary integral equation（边界积分方程）；MFS = method of fundamental solutions（基本解方法）；QP = quasi-periodic（准周期）。

由 `draft/tmp/bie-theory-rewrite/`（未追踪，保留不动）于 2026-11-04 复制而来，2026-11-05 加入胞元核与按场拟合、可靠评价和第 6 节，按 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]] 修改。修改处在 PDF 中以蓝色"[新改]"标注。报告中对应的结果已通过审查（[[research/projects/bie-enclosure/theory/reliable-bound-review|reliable-bound-review]]，0 个 blocker；唯一的 important caveat R-1 已在带隙证书式中改正）；草稿本身的文字尚未送审，全文送审时再去掉标注。

- `main.tex`：主文件，`s-*.tex` 为各节，`a-cellrep.tex` 为附录。
- `data/`：第 6 节作图数据，复制自 `test/bie-bound/pipeline-v1/figures/`（run-002）：`geometry.csv`（一行胞元的界面曲线）、`determinant-nodes.csv` 与 `determinant-coefficients.csv`（行列式节点值与 Chebyshev 系数）、`center-contributions.csv`（中心材料各面板对 $\varepsilon_g$ 的贡献）、`resolution-comparison.csv`、`stage-times.csv`。
- `review/`：外部审阅记录（提示词与审稿报告），见其中的 README。
- `unsrt-nonote.bst`：标准 unsrt 去掉 note 字段（nonote = no note）。
- 编译：`latexmk -xelatex main.tex`，之后 `latexmk -c main.tex`。

## 进度

| 节 | 修改内容 | 状态 |
|---|---|---|
| 1 引言 | 左右引线可以不同；记号表 $L_\pm$ | draft 完成 |
| 2 模型问题 | 两条引线 $\rho_\pm$、$L_\pm$；$D(A)=H^2_\beta$；本质谱为两谱之并（Fliss 注 2.1(2) + 证明）；谱底 $\lambda_0=b_\beta^2/\rho_{\max}$；公共谱隙与指数衰减；新增 2.4 公共谱隙的有限维判据（Lipschitz 界） | draft 完成，对应结果已审查 |
| 3 约化 | 各侧胞元宽 $L_\pm$ 与各自的介质柱 | draft 完成 |
| 4 离散 | 增广 MFS 的说明；左右散射矩阵不同；求解用回卷核与评价用胞元场分开（2026-11-05） | draft 完成 |
| 5 误差 | 场由固定的增广 MFS 表示定义（式 mfs-field）；逐片 $H^2$ 命题；(P2) 删去；接缝作为第三类界面及其跳跃；接缝领子与覆盖重数更正；新增分组迹估计命题（保留 Jacobian + 联合谱乘子）；定理证明加接缝项与分组；人工墙模态尾界标为只适用于精确准周期场；圆盘质量下界；可靠输入清单更新。2026-11-05：胞元核与按场拟合（480 个固定点源）；传播尾项的解析包络与实际状态列；新增 5.x 可靠评价小节（面板界、Chebyshev 节点、球算术） | 2026-11-04 部分已审查；2026-11-05 部分未审查 |
| 6 结果 | 参数；五组缺陷表（中心材料为可靠上界，其余为浮点）；谱距离估计全宽约 2.77e-11；与回卷核、FEM 对比；可靠评价与计算量 | 初稿；其余四组可靠缺陷、$C_g$ 可靠界、带隙证书、模型与几何描述待补 |

蓝色"[新改]"标注共 26 处（2026-11-05 新增 7 处）。原稿的单族迹估计（命题 5.1）保留，作为分组命题的特例。

## 两版重组（2026-11-06 起，进行中）

同一套源文件编译两个版本：`main.tex` 为工作版（蓝字标注演变过程，保留被取代内容），`main-clean.tex` 为对外版（无蓝字、无重复命题）。开关与宏在 `preamble.tex`：
- `\pending{...}`：蓝字说明，只在工作版显示；
- 环境 `workonly`：被取代或重复的内容，只在工作版出现（灰字并标"[工作版保留]"）；
- 环境 `cleanonly`：只在对外版出现的改写，尽量少用。
正文在 `body.tex`；日期在 `body.tex` 中显式写出。重组前的 PDF 在 `archive/`。

进度（done／next／open）：
- done：归档 2026-11-05 与 2026-10-28（theory-rewrite）PDF；第 1 步开关；第 3 步第 2.4 节带隙证书（Fourier 补空间定理＋相位面板判据）；第 4 步第 5 节重组：分组缺陷 $\varepsilon_g$ 取代 $\varepsilon_{\partial,\ell_*}$，定理证明改为分组形式，新附录 B（`a-trace.tex`，迹估计几何与证明，原命题 5.2 只在工作版）与附录 C（`a-reliable.tex`，计入舍入的可靠计算 C.1–C.6），人工界面模态尾界与 $\Theta_\pm$ 逐列取法只在工作版；两版均编译通过、无未定义引用；第 5 步第 4 节：候选定位改为端口约化矩阵 $\mathsf A(k)$ 的行列式 Chebyshev 求根（Boyd），候选输出改为端口振幅 $q$，原 $\sigma_{\min}$ 扫描与 $\mathsf M$ 写法只在工作版；参考文献改用本目录的 `unsrt-nonote.bst`（标准 unsrt 去掉 note 字段，共享 bib 的 note 记录本地 PDF 路径等目录信息，不进论文）；第 7 步引言：贡献改为六项（加入行列式求根、分组迹估计、计入舍入的可靠计算、带隙证书、数值例子占位），“不声称”段按带隙证书改写，结构段加附录 B、C，记号表换为 $\varepsilon_g$、$C_g$、$\ell_g$、$Q$、$\mathsf A(k)$；
- done（续）：第 6 步第 6 节按 pipeline-v1 run-002 重写（模型与离散、行列式求根、可靠区间、分辨率、计算量与 FEM 对照），图用 pgfplots 读 `data/` 中的 CSV；引言“数值例子”已填；
- done（续）：第 8 步：两版编译无错误、无未定义引用（工作版 45 页，对外版 41 页），已 `latexmk -c`；
- 2026-11-06 已提交（ed9b2da）。
- done（第二轮，2026-11-06，与审稿报告一起提交）：E1 “带隙证书”改为“公共谱隙的有限维判据”（第 2.4 节标题），命题名“面板上的谱隙判据”，引用改指具体命题，“带隙”统一为“谱隙”；E2 第 2.4 节说明 $\theta$（引线 $x$ 向 Floquet 参数）与固定的 $\beta$ 的关系，加投影能带示意图 `fig:projected-bands`；E3 第 6 节去掉十六进制，改写为 $\widehat k=438661269969907/2^{48}$；E4 离散 DtN 形式 $\mathsf M_{\rm DtN}$ 及脚注移入工作版，第 3.5 节改名“与 DtN 约化的关系”，第 4.6 节说明 $\mathsf A(k)$ 用 DtN 归一化的原因（与基无关的解析行列式，极点在 Dirichlet 例外值）；E5 第 4.2 节改为“近像分解”（式 `eq:near-image-split`，Barnett–Greengard 结构；密度可用任何近似 $G_\QP$ 的方法求；两段核说明合并为一段），原两段移入工作版；附录 A 加推论 `cor:near-image`（$G_{\rm far}$ 光滑，准周期层势＝近像层势＋光滑修正），定理与证明不变；第 5 节评价场段引用该推论；`preamble.tex` 加 `corollary` 环境；E6 两版编译无错误、无未定义引用（工作版 47 页，对外版 43 页），已 `latexmk -c`；工作版灰字块中有一处 overfull（旧打分式），对外版没有；E7 审稿提示词与报告见 `review/`；
- open：新参考文献 Johansson 2017（Arb）已入库；Boyd 2002 已入库（用户下载）；提交须用户批准；送审等实验结果。
