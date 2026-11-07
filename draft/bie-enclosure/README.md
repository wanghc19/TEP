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
- 第三轮（2026-11-06 起，按 `review/referee-report-2026-11-06.md` 修改不需要实验的部分，未提交）：R1 I1 材料界面的实际跳跃公式，删去“QZ 数据恰好自洽”；R2 I2 式 (C.4) 按 (面板, 状态) 计误差；R3 I3 式 (5.22) 按组分解并含接缝；R4 I5 乘子按 $\lambda\leftrightarrow1/\bar\lambda$ 成对；R5 I6 定理 4.2 补 Rayleigh 级数收敛论证，删去“互补系统”条件（由交换问题唯一性推出），说明实正波数时交换问题的唯一性；R6 I7 指数衰减证明的权；R7 I8 附录 C.5 归一化 $1/(L_sd)$ 与“整函数”的适用范围；R8 I9 离散行列式解析性的条件；R9 M1 $\mu$ 区间与 $k$ 区间的措辞、$\mu\ge R$ 条件；R10 M2 记号（代理系数映射改名、$\mathsf E(L_\pm)$、引言跳跃类型含接缝、图 7 图注）；R11 M3 推论 A.1 的密度空间与区域；R12 M4 附录 C.4 退化分支与 Hessian 范数；R13 I4 几何参数的定义（先核对各可靠阶段是否用同一套 binary64 几何）；R14 B1 的文字部分（第 6 节给出 $\ell_g$ 等中间量，补写附录 C.2 的复域包络）；R15 I10 用现有文献重写定位（新文献待用户批准）。不做：I11 新实验。
  - done：R1（式 `eq:actual-material-jumps`；“自洽”段改为精确算术下成立）；R2（C.2 逐状态误差 $e_{I,j}$；尾项常数改为实现所用的解析包络 $B_\pm^2$，原多项式 Frobenius 取法移入工作版——原文与实现不一致，审稿人未指出）；R3（式 5.22 按组 $b_{g,\pm}$，含接缝，$N_{\rm cell}$ 每组每侧分别选取）；R4（$(\lambda,1/\bar\lambda)$，核对 Joly2006 原文：其设定为横截面有界、无横向相位）；R5（定理 4.2 删去互补系统条件，附录 A 补级数收敛、密度唯一性与交换问题唯一性的证明）；R6；R7；R8；R9（引言改为 $\mu$ 区间全宽并给出波数区间全宽 $8.8\times10^{-12}$，第 6 节“$I_{\rm spec}$ 中有特征值”，表头，$I_k$ 下端 $\max\{0,\cdot\}$，FEM 唯一性与舍入的措辞）；R10（代理系数映射改名 $\mathsf X_\pm$，$\mathsf E(L_+)$，引言含接缝，图 7 图注）；R11；R12；R13（附录 C.1 与第 6.1 节：目标几何为 binary64 参数，谱隙判据与迹常数覆盖两套参数，缺陷只在 binary64 几何上算）；R14（第 6.3 节新增表 `tab:results-trace`（$\kappa_g,\delta_g,h_g,\eta_g,D_{0,g},D_{1,g}$，$\ell_g=N_g=1$）、表 `tab:results-tails`（每组每侧 $N_{\rm cell}$、$B_\pm$、尾/有限比、分侧缺陷）、墙与接缝的中心部分、圆盘数据；数据只读取自 run-002 的 03-residuals、05-mass、06-enclosure；顺带改正第 6.1 节左侧 $N_{\rm cell}$ 范围 52–54→52–56；附录 C.2 补中心面板误差四个分量、权 $|r'|^{1/2}$ 的主支延拓、$V_I$ 的计算、包络 $B_\pm$ 的构成，均按代码核对）；R15（引言新段“与已有谱包含方法的关系”，只用已入库文献：BetckeTrefethen2005、Betcke2007、BarnettHassellTacy2018、DahneSalvy2020、Temple1928、NakaoPlumWatanabe2019、BehnkeMertinsPlumWieners2000、BrownHoangPlumWood2009、HoangPlumWieners2009；第 1 项贡献注明 Robin-to-Robin 也避开例外值；附录 A 唯一性证明注明是 Barnett–Greengard 附录 A 互补场论证的版本，已读原文核对）。两版编译通过、无未定义引用（工作版 51 页，对外版 46 页），已 `latexmk -c`。
- 第三轮（续，用户 2026-11-06 批准）：新文献入库并在引言引用：BarnettGreengard2011、BarnettHassell2011、DaviesPlum2004、DesclouxTolley1983、MolerPayne1968、ZimmermannMertins1995；Moler–Payne、Barnett–Greengard 2011 已按原文核对；Descloux–Tolley 无法获取原文，正文与 Betcke 2007 引理 2.1 的转述并引，并据此改正引言中区域分解的归属。I11 实验分三阶段：A `test/bie-bound/resolution-v1`（场分辨率与评价分辨率分开、各组预算与代价、FEM 设置事实，已交 astra）；B 第二个例子（空中心、$L_-\neq L_+$、无 $y$ 反射对称、全相位谱隙判据）；C 靠近谱隙边缘的模态（收缩弱、$p>1$）。本轮全部修改待审稿意见改完后统一提交。
- 定位（用户 2026-11-06）：本中文稿是详细研究笔记；正式投稿版以后用 `vendor/siamart_251216/` 的 SIAM 模板另做（约 20 页，附可复核代码）。审稿意见 B1 剩余部分与 M5 留给投稿版。
- 第三轮（续二，未提交）：附录 C.2 补全推导（由 theory/selfint-accel、cellker-eval、proxy-accel、reliable-bound T3.2 移入）：引理 `lem:chebyshev-interp`（带节点误差的插值，$\sqrt{2L-1}$ 因子）、`lem:regular-expansion`（正则 Helmholtz 展开与源矩误差）、`lem:green-envelope`（基本解及导数的包络）、`lem:local-terms`、`lem:self-envelope`（自作用目标包络 $2H_A/(e^{a-R_t}-1)+H_B$）、`lem:kress-real`（实目标 Kress 误差；改正原式 `eq:kress-error`：原为周期 1 的粗界，实现用的是周期 $2\pi$ 的锐界）与自作用误差账 `eq:self-error`；cellker-eval、proxy-accel 两份笔记尚无独立审查。第 6 节按实验 A 重写：FEM 比较补来源、网格与阶数、自由度、DtN、停止标准、几何的 $2^{-56}$ 差别，区分方法保证与本次实现（窄区间以 (H) 为前提）；第 6.4 节改为场分辨率与评价分辨率两表；去掉“窄约 163 倍”（引言与第 6.5 节改为用时与宽度并列）；第 6.3 节写明前提的检验与复核所在。两版编译通过，无未定义引用。
- 第三轮（续三，未提交）：第 6.6 节第二个例子（example2-v1 run-015：几何、图 `data/geometry2.csv`、候选、区间、各组表、领子/质量/全相位谱隙判据、用时），引言贡献列表补一句；第 6.1 节注明第一个例子用反射对称只覆盖一半相位；附录 C.5 相位覆盖改为一般 $[-\pi/L_s,\pi/L_s]$。
- 第三轮（续四，未提交）：第 6.7 节靠近谱隙端点的导模（gapedge-v1：沿空中心宽度 $L_0$ 的浮点序列表 `tab:results-gapedge-float`，$L_0=1.6,1.9,2$ 的可靠区间与汇总表 `tab:results-gapedge`，截断深度与 $r_+$ 的关系，$p=2$ 尾界的检验），引言补一句。两版编译通过、无未定义引用（工作版 60 页，对外版 55 页），已 `latexmk -c`。
- 第三轮未做：可复现包与 M5 压缩留给投稿版。
- 2026-11-07：英文稿证明审查（[[research/projects/bie-enclosure/theory/siam-draft-review|siam-draft-review]]）指出的问题中，附录 C 同样存在的四处已同步改正并以蓝字标注：R-1 上确界退化分支（球不能排除零时不能当作单调，原文移入工作版）；R-2 墙包络的一步范数 $r_1$ 与长度因子；R-3 $\mathsf G$ 是状态到入射振幅的映射；R-5 源位移按两个特征坐标取界；另 R-7 Hessian 取算子范数。R-4、R-6、R-8 中文稿本来写对。两版编译通过、无未定义引用（工作版 61 页，对外版 55 页），已 `latexmk -c`。
- open：新参考文献 Johansson 2017（Arb）已入库；Boyd 2002 已入库（用户下载）；提交须用户批准；送审等实验结果。
