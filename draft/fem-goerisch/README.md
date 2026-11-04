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

## 全文证明审查后的修改（2026-11-04）

审查意见：`research/explorations/numerical-directions/paper-review-pro.md`（ChatGPT Pro，1 个 blocker、10 个 minor，经理逐条核对属实）。按用户要求只改不再送审。两个文件都已重新编译。

| 意见 | 问题 | 修改（论文 / 讲义） |
|---|---|---|
| O1（blocker） | 主区间和 $I_1$ 的显示端点向内取整，写出的区间不包含可靠区间 | 端点向外取整：$[2.4287286691977,\ 2.4287286736602]$，$I_1=[2.4286785150,\ 2.4287788272]$；摘要、正文、结果表与讲义各处同改 |
| 安全取整（随 O1 一并处理） | 其他界值的显示位数也有向不安全方向舍入的 | 上界向上、下界向下、区间向外：界面 $S$ 区间、$S_+$、表面态表（$\lambda_{\min}(C_-)$、残差、尾项）、$K_+$、$K_-$、$b_H^2$、$a_H$、左侧放大因子 2.03、DtN 表（$r$、$K_+r$、上下界之差、两个 $\lambda_{\min}$）、$C_h$ 表、$\delta_h$、积分余项 $1.2209\times10^{-10}$、$\varepsilon\le2.0621\times10^{-9}$。所有结论的不等式按新显示值仍成立 |
| O2 | 论文面板检验缺 $r_i<k_L$ | 论文 §5.2 加 $0\le r_i<k_L<k_U$（讲义原已有） |
| O3 | 论文一般端点计数缺端点可逆 | 论文 §5.3 加“$[a,b]$ 在一个带隙中，$\mathsf B_a$、$\mathsf B_b$ 可逆”（讲义原已有） |
| O4 | 矩阵束多减了一次 $\bm M^q$；“大于”不是等价条件 | 两处都改为矩阵束 $(\bm T_{\rm low},\bm M^q)$，$n(\bm L)\le1\iff\mu_2\ge\delta_h$。已核对 h-core-v1 `core_run.m`：报告的 $\mu$ 就是这个矩阵束的特征值 |
| O5 | 首胞通量关系中的 $G$ 没有定义 | 按 h-dtn-v1 代码（`dtn_flux.m`、README）把首胞单独写：输入为 11 个低频 Fourier 迹 $g$，$w=Gg$，$G$ 把它们映到墙上节点值；$N_0=N_bG$ 连接首胞与第 1 个胞，$F_b=N_bP$ 连接重复胞。审查建议的 $G:=P$ 与代码不符，未采用 |
| O6 | 芯区一侧没有宽 $\tfrac14$ 的均匀领口（星形夹杂离右端口 0.14） | 领口只对半导波一侧和纯周期介质的墙两侧断言 |
| O7 | 把表面态的排除归于 (H) | 表面态由 (P) 处理；“不是 $A$ 的谱”改为“不一定是 $A$ 的谱点” |
| O8 | Rayleigh 误差带符号；宽度为 $C_W(\theta-\lambda_*)$ 不是无条件的；4.7% 的归因没有依据 | 删去“只让 $\theta-\lambda_*$ 变大”；宽度关系只在 $|qR|\ll\theta-\lambda_*$ 时陈述；4.7% 只作诊断。涉及论文贡献 1、§3.3、§4.1、§7.1、§7.3，讲义第 1、4、5、12 节 |
| O9 | 梯度分支差不与缝宽成比例 | 比例关系只对值分支陈述；梯度分支差由多项式分支差模型直接取界 |
| O10 | 正弦、余弦模型规则需要 $P$ 取实值 | 引理条件改为 $f$、$P$ 都实值，证明中注明 |
| O11 | “这些方法都要求谱分离”不适用于所有被引方法 | 分离要求只归于特征值簇的包含（Cancès 等） |

## 舍入误差估计（2026-11-04）

依据：`research/explorations/numerical-directions/rounding-estimate.md`（第 8b 阶段，经理核查）。两个文件都已重新编译。

- 新增一节"舍入误差估计"（论文、讲义各一节，标签 `sec:rounding`）：方法（$\gamma_n$、Weyl、后向稳定性，引 Higham 2002 的引理 3.1、式 (3.5)、§4.2、定理 10.3、11.3）、各检验的余量与估计比值、区间端点位移（宽度的 0.20%、0.23%）、可容许性、观测与估计的对比、结论与局限。
- 摘要、引言"关于可靠"、结构段、四角结果段、结论与局限（讲义：第 1 节、第 6 节开头、第 14 节）指向这一节。主张仍是"截断误差意义下可靠"，舍入是估计。
- 打印位数：DtN 表的 $r$、$K_+r$、上下界之差改为 2–3 位，两个 $\lambda_{\min}$ 改为 4 位，删去"两侧 $r$ 相同到 7 位"；芯区计数的移位由 0.3653736907（枢轴 $1.1\times10^{-10}$）改为 0.36（h-core 复制代码 run-007 中已算：恰 1 个负特征值，最小枢轴 0.0059），结论写成 $\lambda_2(\bm L)\ge0.36$；$\tilde{\bm L}$ 的特征值改为 7 位。
- 主区间端点、$E$、$M$、$I_1$ 的显示位数不变（截断误差意义下的数字），新节说明它们哪些位超出舍入误差估计。

## 素材来源（只供写作者核对，讲义正文不引用）

- 区间定理与宽度：`research/explorations/numerical-directions/goerisch-width.md`
- 计数定理：`research/explorations/numerical-directions/dtn-inertia-count.md`
- 四角证书：`qj-bounds-proof.md`；数值：`test/numerical-directions/qj-cert-v1/`、`qj-cert-v2/`
- (H)：`h-cert-proof.md`；数值：`test/numerical-directions/h-cert-v1/`、`h-dtn-v1/`、`h-core-v1/`
- 管线与成本：`test/numerical-directions/fem-pipeline-v1/`、`gap-ends-v1/`
- 模型、DtN 约化：`draft/fem-dtn-epost/main.tex` §2–§5
