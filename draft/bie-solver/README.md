# bie-solver：两侧不同周期引线的线缺陷导模 BIE 求解器（SIAM 草稿，第一版）

BIE = boundary integral equation（边界积分方程）；DtN = Dirichlet-to-Neumann；QZ = 广义 Schur 分解；SIAM = Society for Industrial and Applied Mathematics。

2026-11-07 用户决定把候选计算从 `draft/bie-siam/`（保证区间论文）拆出来单独成文。两篇的分工：

- 本稿：固定 $\beta$ 时怎样算导模候选。内容包括端口 Rayleigh 展开、每个胞元的 Müller 型 BIE 与准周期 Green 函数、引线胞散射矩阵与稳定 Schur 子空间、中心消元与离散 DtN、行列式求根。只做数值方法论文，不给候选的误差界。
- `draft/bie-siam/`：给定候选数据，构造试探场，证明谱距离界并可靠计算区间。它只引用本稿说明数据从哪里来，正确性不依赖本稿。

## 文件

- `main.tex`：主文件，宏包、宏定义、摘要、各节 `\input`、结论。
- `sec-intro.tex`：引言。问题、三种失效现象、贡献（定位 B）、路线图。
- `sec-model.tex`：模型、间隙条带与 $w_{\min}$、导模、公共带隙、Rayleigh 阶与 Wood 点、计算任务与五项要求、两类表示奇异。
- `sec-method.tex`：单胞离散。Rayleigh 端口与 Cauchy 坐标、准周期层势与 Müller 方程、提取矩阵 $\mathsf F$ 的显式公式、引线胞散射矩阵、中心胞。
- `sec-leads.tex`：引线束、能流、引理 A（衰减子空间维数 $K$）、全离散判据、有序 QZ。
- `sec-closure.tex`：DtN 闭合及其极点、加边闭合（定理 B）、解析标架、实频投影检验、求根与物理接受判据。注记 `rem:holomorphy` 已按证明审查（`research/projects/bie-enclosure/theory/holomorphy-remark-review.md`）改写。
- `sec-truncation.tex`：Rayleigh 阶的选择。条带压缩（命题）、根误差定理、选阶规则、端口位置无关、引线、首阶公式。来源 `research/projects/bie-enclosure/theory/rayleigh-truncation.md`（审查 11/1/0）。
- `sec-wood.tex`：Wood 点。失效位置（`wood-probe-v1`）、回退方案（切分窗口、排除 $|k-k_W|<\delta$ 的带并报告）。插值变量与 $\delta$ 规则来自 `wood-fallback-v1`。
- `sec-experiments.tex`：数值实验。算例、文献算例、无极点闭合、Rayleigh 阶、与 FEM 的成本比较、Wood 点附近。
- `sec-appendix.tex`：附录。判据（命题 4.6）的完整证明；条带压缩命题与根误差定理的完整证明。
- `sec-acknowledgments.tex`：致谢与 AI 使用声明（按 SIAM AI 政策 2.0）。
- `fig-waveguide.tex`：几何示意图，取自 `draft/bie-siam/`。
- `latexmkrc`、`siamplain-nonote.bst`：与 `draft/bie-siam/` 相同。
- 编译：在本目录运行 `latexmk main.tex`，之后运行 `latexmk -c main.tex`。

## 起草计划（2026-11-07，用户批准起草已完成部分）

按阶段写，每阶段写完即存盘：

1. `main.tex` 重排节结构；`sec-model.tex`（模型、两条引线、单胞、导模、公共带隙、Wood 点、计算问题 P）；`fig-waveguide.tex` 从 `draft/bie-siam/` 复制。
2. `sec-method.tex` 重写为“单胞离散”：Rayleigh 端口、层势与 Müller 方程、提取矩阵 $\mathsf F$ 的显式公式、引线胞散射矩阵、中心胞。
3. `sec-leads.tex`：引线束、能流恒等式、引理 A（维数 $K$）、全离散判据、有序 QZ。
4. `sec-closure.tex`：DtN 闭合及其极点、加边闭合（定理 B）、行列式分解、解析标架、实频投影检验、求根与物理接受判据。
5. `sec-truncation.tex`：截断模型的条带压缩、根误差定理、选阶规则、截线不变性、首阶公式。
6. 引言只写问题定义与失效现象；数值节只列已完成结果的提纲。贡献陈述、摘要、Wood 点（C2）、RtR 对照留待之后。

状态：见下面“进度”。

## 进度

- done（2026-11-08）：加入致谢节 `sec-acknowledgments.tex`（AI 使用声明，按 SIAM AI 政策 2.0，改写自 `draft/bie-siam/sec-acknowledgments.tex`），放在附录后、参考文献前。TODO 2 处：代码与数据发布的引用；作者本人核查的内容。暂不考虑页数（用户读后再删改）。
- done（2026-11-08）：术语统一（用户定）：lead → periodic half-strip $S_\pm$（§2.1 定义），lead cell → periodicity cell，center cell → defect cell，lead pencil → Floquet eigenvalue problem \eqref{eq:floquet}（定义处括号注明即 matrix pencil，并定义 regular）；标题与页眉同步改。依据：Joly–Li–Fliss 2006（half-guide、artificial boundary）、Fliss 2013（half-band）、Klindworth–Schmidt–Fliss 2014 与 Fliss–Klindworth–Schmidt 2015（half-strips $S^\pm$、defect cell $C_0$、periodicity cells）、Fliss–Joly–Lescarret 2021（periodic half-waveguide、artificial boundary），均不用 lead。LaTeX 标签（sec:leads、sec:pencil、eq:pencil、sec:center 等）未改名。编译 25 页，无 overfull，无未定义引用。
- done（2026-11-08）：按用户要求删去对可靠区间论文的全部引用（`\companion` 宏已删；本文将先于该文投稿）。成本表最后一档由“落入可靠区间”改为相对数值参考值 $k_{\rm ref}=1.558437894182088$ 误差低于 $10^{-11}$，表中配置与时间不变；摘要、引言、结论相应改写，不再出现“guaranteed interval”。中心胞两条竖直端口线改称 artificial (vertical) boundary（首次定义在 §2.1），“port state / port amplitudes”作为振幅数据的名称保留。核查 `wood-fallback-v1` 后填入 §7 的插值变量与 $\delta$ 规则、§8.6 的完成率、根误差表与导模支检查。编译 24 页，无 overfull，无未定义引用。剩余 TODO 2 处：附录 $D(A)=H^2_\beta(B)$ 的引用；首阶公式与 $H^2$ 改进证明的去向。
- done（2026-11-07）：第一版草稿（定位 B）。用户决定先按定位 B 写：贡献为加边闭合、引线子空间维数与判据、Rayleigh 阶的根误差界、精度与成本；Wood 点写成局限并给回退方案；不含 RtR 比较和 Wood 稳健胞元（路线 A，见 `research/projects/bie-enclosure/route-a-plan.md`）。新写：摘要、贡献、`sec-wood.tex`、实验节各小节与成本表、附录证明、结论；`rem:holomorphy` 按审查改写，解析标架段改用局部标架。编译 23 页，无 overfull，无未定义引用。剩余 TODO 5 处，另有 `\companion` 占位：Wood 回退的插值变量、$\delta$ 规则与实验结果（等 `wood-fallback-v1`），附录中 $D(A)=H^2_\beta(B)$ 的引用，首阶公式与 $H^2$ 改进的证明放附录还是补充材料。
- done（2026-11-07）：阶段 1–6 初稿写完，可以编译（17 页，无 overfull，无未定义引用）。各节剩余 TODO 17 处，另有 main.tex 中的摘要和结论：贡献陈述、摘要、结论、Wood 点（C2）、RtR 对照（E6）、判据的附录证明、根误差定理的完整证明、注记 `rem:holomorphy` 送证明审查、Botten 2006 等未入库文献、数值节图表与成本边界。

- done（2026-11-07）：建骨架，方法节移入，可以编译（4 页，无 overfull，无未定义引用）。
- done（2026-11-07）：查新 [[bie-solver-novelty]]，总评 B（直接推广）。最接近的是 Fliss–Klindworth–Schmidt 2015（同一固定 $\beta$ 模型，允许两侧不同包层，FEM + RtR）、Petropoulos–Turc 2025（BIE 胞 RtR 与稳定束闭合，但是声软同质阵列的受迫散射）、Botten 等 2006（线导模即 $\det Z(k,\alpha_0)=0$，多极展开，单一体材料）。单独成文的条件：等任务、等精度下与高阶 FEM–DtN/RtR 比误差和成本（E1），再加圆柱情形与 Botten/Dossou 边界方法对照（E2 的最简部分）。12 项审稿检查：4 项已有记录，5 项部分，3 项缺失。贡献陈述草案和应避免的说法见查新文件。
- done（2026-11-07）：E1 等任务比较 `test/bie-bound/solver-cost-v1/`（算例 1，冷启动，11 线程）。误差 $10^{-6}$–$10^{-10}$ 时 FEM P4 快 1.4–2.3 倍；要进入参考区间（宽约 $8.8\times10^{-12}$）时，BIE 128/64/64、$M=6$ 用 38.8 秒、0.81 GiB，FEM P4 g48 用 97.8 秒、1.21 GiB，BIE 快 2.5 倍。BIE 时间基本不随精度变（约 39 秒，主要是 35 次行列式求值）。
- done（2026-11-07）：文献算例 `test/bie-bound/litbench-v1/`：Botten 等 2006 的 W3 波导（六角晶格，TM），$d/\lambda=0.32$ 时 $\alpha_0d=1.67540706$，与原文 1.67541 的 6 位全部一致；第二个模与图 3(b) 一致。
- done（2026-11-07）：失效探查 `test/bie-bound/failure-probe-v1/`。真实存在的问题：（1）Wood 点：算例 1 的导模支在 $\beta\approx1.9815$ 处、W3 在 $\beta\approx2.9750$ 处穿过 $k=|\beta|$；正好在 Wood 点上引线计算失败，离 Wood 点 $10^{-4}$ 以内时行列式搜索超时，根本身仍准到约 $6\times10^{-12}$。（2）端口极点：把端口切线移进引线胞后，$\mathsf D_\pm$ 奇异处出现极点；后备搜索把极点（距导模 0.0022）当作根接受，原因是极点处 $\sigma_{\max}$ 涨到 $2\times10^{13}$，使 $\sigma_{\min}/\sigma_{\max}$ 很小；改用不除以 $\mathsf D$ 的子空间投影匹配后只剩真根。（3）根恰好落在 Chebyshev 节点上时搜索停滞，平移窗口即可。未观察到：中心表示产生的伪根、QZ 与特征向量子空间的差别。
- 待办（等用户决定）：18 项候选文献哪些入库。
- done（2026-11-07）：提取矩阵已写出显式公式（`eq:extract-kernels`、`eq:extract`），方法节已按显示公式重写。
- done（2026-11-07）：模型节记号取自 `draft/bie-siam/` 第 2.1 节。

## TODO：潜在贡献项（2026-11-07 记录，均未开始，等用户排序）

推导都是管理者的草稿推理，未经证明审查；数值只来自已有实验记录。

- [x] **C1 无极点端口匹配 + 物理接受判据**（推荐作为核心贡献）。2026-11-07 完成：定理 B 见 [[port-subspace]]（审查 12/12 成立，[[port-subspace-review]]）；实现与验证见 `test/bie-bound/pole-free-v1/`（切线偏移时旧路线接受极点、新路线只返回真根；切线对齐时旧路线拒绝、新路线找到真根；9 类算例 18 次计数一致）。注意：物理判据的绝对阈值 0.005 偏弱，排除极点主要靠加边形式本身。以下为原始记录。问题：端口切线移动后 $\mathsf D_\pm$ 奇异给出 $\Lambda_\pm=\mathsf N_\pm\mathsf D_\pm^{-1}$ 的极点，后备搜索因 $\sigma_{\max}\approx2\times10^{13}$ 把极点当根接受（`test/bie-bound/failure-probe-v1/`，两种分辨率都复现）。修正方向：不除以 $\mathsf D$ 的子空间投影匹配 $(I-\mathsf Z_s\mathsf Z_s^*)\mathsf Y_s$（探查中四次扫描只剩真根，比值约 $3\times10^{-14}$），接受判据由 $\sigma_{\min}/\sigma_{\max}$ 改为胞壁跳跃检查（假根约 0.05，真根 $10^{-5}$–$10^{-7}$）。需要：定理（投影形式在 $\mathsf D_\pm$ 奇异时成立，零点即物理解）、实现、三个算例加移动切线的重跑。局限：本文算例在原切线下窗口内没有极点。
- [ ] **C2 Wood 点稳健端口**（第二项）。问题：$\gamma_0=0$ 时引线计算失败，离 Wood 点 $10^{-4}$ 以内搜索超时；算例 1 导模支在 $\beta\approx1.9815$、W3 在 $\beta\approx2.9750$ 穿过 Wood 线，画色散曲线必然经过。修正方向：$\gamma_0=0$ 时用常数解和线性解（或 Cauchy 数据端口）替代 Rayleigh 展开。
- [x] **C3 Chebyshev 节点上的根**（工程修正）。2026-11-07 在 `pole-free-v1` 中解决：对数跨度不再否决，改用插值系数尾部和网格外检查，次数 8 即收敛。以下为原始记录。根落在插值节点上使对数行列式跨度超限（25.96 > 18）而停滞；区分"确认过的单零点"与极点，或自动平移窗口。
- [x] **Q1 衰减子空间维数为何是 $K$**。2026-11-07 引理 A 已证明并通过审查（[[port-subspace]]）；带内计数要求单位模乘子半单；全离散判据 (10) 用束在单位圆上的最小奇异值。`test/bie-bound/rayleigh-order-v1/` 的诊断与判据相容，但未做可靠比较。以下为原始记录。草稿论证：端口能流形式 $J$ 符号差为 $(K,K)$；实 $k$ 时胞元保持能流（截断不破坏，只要传播阶都在 $|m|\le M$ 内），故衰减、增长子空间都 $J$-中性；无单位模乘子时两者各为 $K$ 维。$\dim\ne K$ 对应四种情形：$k$ 在带内（应取"衰减 + 正能流传播"，维数仍为 $K$，超出本项目范围）、Wood 点（$J$ 退化，与 C2 同源）、传播阶未全包含、离散误差超过乘子到单位圆的距离（带隙边缘）。待做：写成引理（可检验的充分条件），加诊断量（胞元能流守恒误差、$\|\mathsf Z_\pm^*J\mathsf Z_\pm\|$、乘子到单位圆距离），在带隙内部、边缘、Wood 点附近测；交证明审查。
- [ ] **Q2 Rayleigh 阶数 $M$ 的选择理由**。2026-11-07 实验 `test/bie-bound/rayleigh-order-v1/` 完成：实测有效宽度大于 $w_{\min}$（例 1 0.738/0.468，例 2 0.698/0.429，W3 0.928/0.466）；切线位置检验不具区分力（截断空间本身与位置无关）；引理在写（`theory/rayleigh-truncation.md`）。以下为原始记录。草稿论证：入射系数是另一侧散射体的出射系数，截断影响的是两散射体隔着均匀条带交换的高阶倏逝波，总衰减 $e^{-|\gamma_m|w}$，$w$ 为条带宽度，与切线在条带中的位置无关；规则 $M\gtrsim\frac{d}{2\pi w_{\min}}\ln\frac{C}{\varepsilon}$，另有硬下限（包含所有传播阶）。算例 1：$w_{\min}=0.468$，预测每加一阶误差缩小约 1/19；solver-cost-v1 实测 $M=2\to3$ 缩小约 1/33（只有一对数据点）。待做：实验 `rayleigh-order-v1`（$M=1$–8，三个算例，条带内移动切线检验位置无关性），与 Q1 诊断合并；写成引理，交证明审查。
