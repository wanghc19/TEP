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
- done（2026-11-07）：E1 等任务比较 `test/bie-bound/solver-cost-v1/`（算例 1，冷启动，11 线程）。误差 $10^{-6}$–$10^{-10}$ 时 FEM P4 快 1.4–2.3 倍；要进入参考区间（宽约 $8.8\times10^{-12}$）时，BIE 128/64/64、$M=6$ 用 38.8 秒、0.81 GiB，FEM P4 g48 用 97.8 秒、1.21 GiB，BIE 快 2.5 倍。BIE 时间基本不随精度变（约 39 秒，主要是 35 次行列式求值）。
- done（2026-11-07）：文献算例 `test/bie-bound/litbench-v1/`：Botten 等 2006 的 W3 波导（六角晶格，TM），$d/\lambda=0.32$ 时 $\alpha_0d=1.67540706$，与原文 1.67541 的 6 位全部一致；第二个模与图 3(b) 一致。
- done（2026-11-07）：失效探查 `test/bie-bound/failure-probe-v1/`。真实存在的问题：（1）Wood 点：算例 1 的导模支在 $\beta\approx1.9815$ 处、W3 在 $\beta\approx2.9750$ 处穿过 $k=|\beta|$；正好在 Wood 点上引线计算失败，离 Wood 点 $10^{-4}$ 以内时行列式搜索超时，根本身仍准到约 $6\times10^{-12}$。（2）端口极点：把端口切线移进引线胞后，$\mathsf D_\pm$ 奇异处出现极点；后备搜索把极点（距导模 0.0022）当作根接受，原因是极点处 $\sigma_{\max}$ 涨到 $2\times10^{13}$，使 $\sigma_{\min}/\sigma_{\max}$ 很小；改用不除以 $\mathsf D$ 的子空间投影匹配后只剩真根。（3）根恰好落在 Chebyshev 节点上时搜索停滞，平移窗口即可。未观察到：中心表示产生的伪根、QZ 与特征向量子空间的差别。
- 待办（等用户决定）：18 项候选文献哪些入库。
- 待办（已知缺陷）：提取矩阵 $\mathsf F^{\rightarrow}_{x_p},\mathsf F^{\leftarrow}_{x_p}$ 只有文字描述，需要写出公式；全节行内公式过密，需要改写。
- 待办：模型节从 `draft/bie-siam/` 第 2.1 节取记号。

## TODO：潜在贡献项（2026-11-07 记录，均未开始，等用户排序）

推导都是管理者的草稿推理，未经证明审查；数值只来自已有实验记录。

- [ ] **C1 无极点端口匹配 + 物理接受判据**（推荐作为核心贡献）。问题：端口切线移动后 $\mathsf D_\pm$ 奇异给出 $\Lambda_\pm=\mathsf N_\pm\mathsf D_\pm^{-1}$ 的极点，后备搜索因 $\sigma_{\max}\approx2\times10^{13}$ 把极点当根接受（`test/bie-bound/failure-probe-v1/`，两种分辨率都复现）。修正方向：不除以 $\mathsf D$ 的子空间投影匹配 $(I-\mathsf Z_s\mathsf Z_s^*)\mathsf Y_s$（探查中四次扫描只剩真根，比值约 $3\times10^{-14}$），接受判据由 $\sigma_{\min}/\sigma_{\max}$ 改为胞壁跳跃检查（假根约 0.05，真根 $10^{-5}$–$10^{-7}$）。需要：定理（投影形式在 $\mathsf D_\pm$ 奇异时成立，零点即物理解）、实现、三个算例加移动切线的重跑。局限：本文算例在原切线下窗口内没有极点。
- [ ] **C2 Wood 点稳健端口**（第二项）。问题：$\gamma_0=0$ 时引线计算失败，离 Wood 点 $10^{-4}$ 以内搜索超时；算例 1 导模支在 $\beta\approx1.9815$、W3 在 $\beta\approx2.9750$ 穿过 Wood 线，画色散曲线必然经过。修正方向：$\gamma_0=0$ 时用常数解和线性解（或 Cauchy 数据端口）替代 Rayleigh 展开。
- [ ] **C3 Chebyshev 节点上的根**（工程修正）。根落在插值节点上使对数行列式跨度超限（25.96 > 18）而停滞；区分"确认过的单零点"与极点，或自动平移窗口。
- [ ] **Q1 衰减子空间维数为何是 $K$**。草稿论证：端口能流形式 $J$ 符号差为 $(K,K)$；实 $k$ 时胞元保持能流（截断不破坏，只要传播阶都在 $|m|\le M$ 内），故衰减、增长子空间都 $J$-中性；无单位模乘子时两者各为 $K$ 维。$\dim\ne K$ 对应四种情形：$k$ 在带内（应取"衰减 + 正能流传播"，维数仍为 $K$，超出本项目范围）、Wood 点（$J$ 退化，与 C2 同源）、传播阶未全包含、离散误差超过乘子到单位圆的距离（带隙边缘）。待做：写成引理（可检验的充分条件），加诊断量（胞元能流守恒误差、$\|\mathsf Z_\pm^*J\mathsf Z_\pm\|$、乘子到单位圆距离），在带隙内部、边缘、Wood 点附近测；交证明审查。
- [ ] **Q2 Rayleigh 阶数 $M$ 的选择理由**。草稿论证：入射系数是另一侧散射体的出射系数，截断影响的是两散射体隔着均匀条带交换的高阶倏逝波，总衰减 $e^{-|\gamma_m|w}$，$w$ 为条带宽度，与切线在条带中的位置无关；规则 $M\gtrsim\frac{d}{2\pi w_{\min}}\ln\frac{C}{\varepsilon}$，另有硬下限（包含所有传播阶）。算例 1：$w_{\min}=0.468$，预测每加一阶误差缩小约 1/19；solver-cost-v1 实测 $M=2\to3$ 缩小约 1/33（只有一对数据点）。待做：实验 `rayleigh-order-v1`（$M=1$–8，三个算例，条带内移动切线检验位置无关性），与 Q1 诊断合并；写成引理，交证明审查。
