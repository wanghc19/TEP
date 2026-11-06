# 状态

更新日期：2026-11-06。

## 已完成

- 分辨率实验（resolution-v1，审稿意见 I11 第 3 点，astra，经理已核对原始输出，见 [[research/projects/bie-enclosure/implementation/resolution-v1|resolution-v1]]）：参考行与 pipeline-v1 run-002 逐位相同。密度节点 256/384/512（M=48）给全宽 $4.27\times10^{-6}$、$9.87\times10^{-9}$、$2.74\times10^{-11}$，粗场误差几乎全在中心材料组；M=40/56 只改变全宽约 1%；同一场上面板加倍、L=64、192 位精度对全宽的影响不超过 $3\times10^{-6}$（相对），可靠上界只比浮点值高约 $10^{-5}$（相对）。结论：区间宽度跟随场的分辨率，不跟随评价精度。各行 584–948 秒，峰值不超过 2.72 GiB。FEM 设置事实已带出处列出；FEM 与 BIE 的几何参数在 binary64 下有 $2^{-56}$ 级差别（FEM 存 0.25，BIE 用 binary64 的 0.2 乘 5/4），没有多网格 FEM 的代价—宽度序列。同场三行沿用参考行的谱隙证书（窗口余量 0.69/3.21，远大于区间宽度）。

- 冷启动完整流程（pipeline-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/pipeline-v1|pipeline-v1]] 末节）：从空目录一次跑完带隙分类、行列式求根、密度重建、B 拟合、五组可靠残差、八盘质量、$C_g$、装配与 472 项含舍入带隙检查。候选 $\widehat k=1.558437894182088$；可靠区间 $k\in[1.5584378941776960,\,1.5584378941864800]$，全宽 $2.738\times10^{-11}$，为 FEM 的 1/163；区间内至少有一个孤立有限重特征值（不声称唯一）。端到端 827 秒（13.8 分钟）、峰值 1.84 GiB；FEM 完整 66.8 分钟，去掉唯一性部分 12.5 分钟。粗节点 256/128/128 全宽 $4.27\times10^{-6}$。这是论文第 6 节的数值例子。
- 固定场浮点评价先导与查新（见 README 链接）。
- ChatGPT Pro 报告 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]]，经理核对了：Fliss 2013 Remark 2.1(2) 允许左右引线不同（读了本地 PDF）；T1.1 的参数逆与 Weyl 序列论证；T2.3 接缝 Green 公式的符号；T4.2 保留 Jacobian 的迹引理（$T_\kappa$ 公式数值复现）与 T4.3 联合乘子；$C=9.571/7.668/4.695$ 与墙上 $C=1.0356$ 数值复现；圆盘平均值恒等式。未细查：T3.2 Kress 界、T3.4a 源簇 Taylor 树、T1.3 衰减、T2.2 正则性。
- 粗估（浮点，非可靠）：接缝跳跃平方约 $4.4\times10^{-27}$，只占 $\varepsilon^2$ 的 0.1%；按分组迹常数 $Q\approx7.7\times10^{-12}$（原 $1.97\times10^{-11}$），$W\approx6.1\times10^{-10}$。已被下面的 budget-v1 取代；接缝量其实只是舍入量（见 OP-BE-6）。

- 报告审查（2026-11-04，审查线程，用时 8.5 分钟）[[research/projects/bie-enclosure/theory/reliable-bound-review|reliable-bound-review]]：0 个 blocker、1 个 important caveat、0 个 minor。R-1：带隙证书式 (T1.7) 中负的特征值下界要先截成 0 再开方，已在草稿中改正。两组优先项都判为正确，审查者核对了 Fliss 2013、Trefethen–Weideman 2014、Dahne–Salvy 2020 的原文。第二组（T3.1–T3.3、T2.4）和低优先项每项只有一行结论，审得较浅；T3.2 Kress 界、T3.4a 源簇 Taylor 树在实现可靠评价前应再细审一次。
- 预算实验 budget-v1（sol，2026-11-04；经理已核对，见 [[research/projects/bie-enclosure/implementation/budget-v1|budget-v1]] 末节）。全部是浮点估计：
  - 分组迹常数：中心 2.490、左引线 1.181、右引线 1.234、墙与接缝 1.036；中心曲线分段反而更差。
  - $\varepsilon=1.518\times10^{-12}$（墙源 3072／目标 1536），$Q_{\rm grp}=4.09\times10^{-12}$，中心法向跳跃占 77%。
  - 12 张不交圆盘的 Q5 质量下界 $U_{\rm low}=1.357$；原 $U=0.1234$ 只是一张小圆盘上的积分。
  - (B0) 余量：原 $U$ 15.5 倍，12 盘 171 倍。
  - 接合墙下降来自源求积，3072 源仍未收敛。
  - 新 blocker OP-BE-6：MFS 核的回卷切换线在胞元内部，单核跳跃约 $10^{-12}$，现有 $\varepsilon$ 未计入；接缝跳跃因回卷只是舍入量。

- 切换线缺陷（OP-BE-6，2026-11-04）：
  - 理论：[[research/projects/bie-enclosure/theory/switch-line|switch-line]] 的命题 S 与 S′ 都已审查，0 个 blocker。审查记录见 [[research/projects/bie-enclosure/theory/switch-line-kress-review|switch-line-kress-review]] 和 [[research/projects/bie-enclosure/theory/switch-line-sprime-review|switch-line-sprime-review]]。同一轮审查细审了 T3.1、T3.2、T3.3、T3.4a，全部正确；但可靠求积要在切换参数处分段。
  - 数值（switch-v1，经理已核对）：命题 S 给 $Q_{\rm sw}=1.41\times10^{-9}$，(B0) 不成立；命题 S′ 给 $6.21\times10^{-11}$（线段项 $2.23\times10^{-11}$，端点项 $3.98\times10^{-11}$）。(B0) 余量：单盘 0.96，不够；12 盘 10.6，成立。
  - 结论：质量下界必须用多圆盘或星内大圆盘；整体余量约 10 倍。

- 墙上源求积（OP-BE-3，srcsplit-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/srcsplit-v1|srcsplit-v1]]）：
  - 原因：墙目标点对应的源参数跨过回卷切换处时，被积函数不连续，梯形求积只剩约一阶收敛。FMM 误差只改变 0.1%，不是原因。
  - 在切换参数处分段求积后收敛：$\varepsilon=1.475\times10^{-12}$，$Q_{\rm grp}=4.01\times10^{-12}$。
  - 加上命题 EP 的切换项：(B0) 余量单盘 1.36、12 盘 15.0。全部是浮点估计。
  - 材料组（占 $Q_{\rm grp}$ 的 77%）仍用梯形源求积；后来命题 G 证明它没有回卷切换，梯形求积在那里不受这个问题影响。

- 切换线完整证明（理论线程）： [[research/projects/bie-enclosure/theory/switch-line-proof|switch-line-proof]]；审查 [[research/projects/bie-enclosure/theory/switch-line-proof-review|switch-line-proof-review]] 为 0/0/0（逐步列出检查，用时约 8 分钟）：
  - 定理 SW：命题 S、S′ 的完整证明，常数不变。
  - 命题 EP：同一面墙的端点先合并成复测度，再用 $H^{-3/2}$ 对偶范数估计。不算相消时，点乘子也从 0.783 降到 0.401。
  - 经理已重算：端点项 $2.04\times10^{-11}$，切换项合计 $4.27\times10^{-11}$，加 $Q_{\rm grp}$ 后约 $4.68\times10^{-11}$；单盘余量 1.36（原 0.96）。浮点估计。

- 切换项可靠上界（switch-rel-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/switch-rel-v1|switch-rel-v1]]）：
  - 用 Arb 对核跳跃做分片 Chebyshev 插值并给出误差界，源积分用面板上确界乘长度，不用浮点求积。
  - 可靠 $\overline Q_{\rm sw}\le4.85\times10^{-11}$，是浮点值的 1.14 倍。两条引线 $p=1$ 即收缩（$r\le0.387$）。
  - 全流程 148 秒、1.35 GiB；一次含 320 个代理的 Arb 核求值平均 0.024 秒。
  - 混合余量（$Q_{\rm grp}$ 与质量仍是浮点）：单盘 1.21、12 盘 13.3。
- 可靠评价设计（理论线程，[[research/projects/bie-enclosure/theory/reliable-eval-design|reliable-eval-design]]；审查 [[research/projects/bie-enclosure/theory/reliable-eval-design-review|reliable-eval-design-review]] 为 0 个 blocker、0 个 important、1 个 minor，逐步列出检查，用时约 9 分钟；唯一的 minor 是可选停止深度 (RE25) 的推导写错了理由，公式本身成立，已改）：
  - 命题 G：本几何中三条材料曲线的源、目标高度差都小于 $d/2$，材料自作用没有回卷切换（经理已运行 §7.1 的有理检查）。这更正了 srcsplit-v1 后“材料组也会碰到切换参数”的推测。
  - 定理 S、R、O、M：分支面板 Gauss 求积、断点定位、目标正则性和目标 Taylor 模型的误差界；命题 CM：源矩压缩。
  - 定理 D：质量下界。八个柱内盘可以直接用 T3.6（目标 $\underline U\ge1.20$）；背景盘要加分支固定的辅助场。
  - 定理 L：引线尾只用密度映射和核包络，不需要逐个计算 97 个基状态。
  - 判断：比 FEM 更窄的可靠区间看来可以做到；成本是否低于 FEM 的 67 分钟还不能定。决定性检查是中心材料曲线（占 $Q_{\rm grp}$ 的 77%）的组合残差证书和实测单价。按设计的面板数，平均混合系数单价要在约 7–9 个核单位以内才不超过 67 分钟。

- 中心材料可靠先导（matrel-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/matrel-v1|matrel-v1]]）：
  - 认证了中心曲线的 2/192 段：可靠上界 $4.67\times10^{-15}$，同段浮点 $2.45\times10^{-15}$。每面板绝对误差约 $10^{-14}$，远小于全曲线浮点 $\varepsilon=1.26\times10^{-12}$。
  - 八个柱内盘：可靠 $\underline U\ge1.23587$（质量下界，几何已认证）。
  - 单价：混合系数 $\chi_{ts}=4.2$，在设计范围内；但自作用的复域半径只允许 192 个目标面板（设计假设 64），且整周期 Kress 每面板 27 秒。
  - 单进程外推 126–245 分钟，高于 FEM 的 67 分钟（FEM 是 11 线程墙钟）。并行未测。

- 自作用加速方案（理论线程，[[research/projects/bie-enclosure/theory/selfint-accel|selfint-accel]]，审查 0/0/0；经理已复算关键数）：
  - 推荐 A3：在 40 个实 Chebyshev 点上算 Kress 和（$N=1152$，源条带 $a=0.08$，128 位），再插值成多项式；不再在复目标点上求和。预测自作用每面板 1.3–1.8 秒（原 27 秒），新增误差 $<4\times10^{-17}$。
  - A2：Kress 误差界多一个 $1/n$ 因子，节点数可再降。D2：自作用单独做多项式后，其余部分的 Taylor 尾项从 $2.9\times10^{-15}$ 降到 $7.6\times10^{-18}$，$e_I$ 预计减半。D1：同一曲线复用源几何和源矩，每面板再省约 4 秒。
  - 近远分裂（B）和直接求目标系数（C）误差可控，但按单块计时更慢，不推荐。
  - 自作用替换后，每面板约 19–24 秒，最大一项变成混合代理系数（16.8 秒）。单进程外推约 107–110 分钟（245 分钟那组计数）。

- 实目标自作用先导（selfint-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/selfint-v1|selfint-v1]]）：
  - 面板 0、1 全部通过：自作用 1.49／1.47 秒（原 27 秒），$e_{\rm self}\le3.3\times10^{-18}$；每面板误差 $e_I$ 从 $5.9/14.6\times10^{-15}$ 降到 $2.0/2.6\times10^{-15}$。两段可靠上界 $2.472\times10^{-15}$，同段浮点 $2.449\times10^{-15}$，只放大 1.01 倍。
  - 源缓存（D1）后每面板 19.8 秒，单进程 0.27 GiB；最大一项是代理混合系数（16.6 秒）。
  - 面板 6 的自作用误差 $1.56\times10^{-16}$，超过工作门槛 $10^{-16}$（大复域的弦长下界只有 $3.3\times10^{-5}$），按规则停下，未做并行。可在该面板把节点 40 改为 44。
  - 单进程外推 95 分钟（代理混合占 70 分钟）；FEM 67 分钟是 11 线程墙钟，并行墙钟未测。

- 整条中心材料曲线可靠上界（central-rel-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/central-rel-v1|central-rel-v1]]）：
  - $\varepsilon_{\rm center}\le1.265348\times10^{-12}$，是浮点值的 1.0033 倍；192 个面板全部有证书，16 个面板把插值节点加到 41–43。
  - 8 进程：墙钟 10.2 分钟，CPU 75 分钟，峰值 1.71 GiB。全流程墙钟外推 17.6 分钟（FEM 67 分钟，11 线程），未计引线状态代数、$C_g$ 证书、带隙证书。
  - 预测全宽约 $4.1\times10^{-10}$（FEM 的 1/10.8），其中切换项占 $Q$ 的 92%；其余组和 $C_g$ 仍是浮点值。

- 胞元核浮点检查（cellker-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/cellker-v1|cellker-v1]]）：
  - 新核：三个近像 + 胞元外 480 个代理点，不回卷；接缝失配约 $2\times10^{-15}$（旧核切换线跳跃 $10^{-12}$–$10^{-10}$）。代理点物理位置都在胞元外。
  - 沿用旧密度、不重解：$Q=\sum_gC_g\varepsilon_g=3.53\times10^{-12}$，没有切换项；预测全宽 $2.77\times10^{-11}$，比现在的 $4.1\times10^{-10}$ 小 15 倍，约为 FEM 的 1/160。全部是浮点估计，$C_g$ 仍是扫描值。
  - 中心材料占新 $Q$ 的 89%；墙残差降到原来的 28%；两条引线材料变为约 4 倍，但合计只有 $1.6\times10^{-13}$。不需要重解。

- 代理项加速理论（proxy-accel，理论线程，经理已核对数值，见 [[research/projects/bie-enclosure/theory/proxy-accel|proxy-accel]]）：
  - 推荐：所有源在原点汇总成一个全局正则 Helmholtz 展开（阶 576、源级数 72 项），再在每个目标面板用 48 个实 Chebyshev 节点插值。
  - 误差：代理部分 $<1.1\times10^{-17}$，面板 0、1 的 $e_I<1.4\times10^{-17}$（以实验中各球半径通过门槛为条件）。
  - 成本预测：设置 80–120 秒，在线 0.4–0.7 秒／目标（现为 16.6 秒）；串行全流程 39–41 分钟。粗目标网格和改阶数只省不到 1 分钟，暂不做。
  - 针对现有回卷核；换成胞元核时数学可沿用，常数和区域要重做。

- 全局代理源汇总实测（proxyagg-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/proxyagg-v1|proxyagg-v1]]）：
  - 面板 0、1：$e_I$ 从 $2.0/2.6\times10^{-15}$ 降到 $2.6/3.6\times10^{-18}$（代理部分 $2.7\times10^{-19}$，自作用成为主项）；$V_I$ 不变。
  - 一次设置 71 秒，之后每目标非自作用 0.48 秒（原 16.6 秒），每目标合计 1.95 秒；峰值 0.18 GiB。
  - 外推：单进程全流程 39.3 分钟，8 进程墙钟约 9.9 分钟（未实测并行）。仍是旧回卷核。

- 胞元核的快速可靠评价理论（cellker-eval，理论线程，经理已核对数值，见 [[research/projects/bie-enclosure/theory/cellker-eval|cellker-eval]]）：
  - 胞元核满足草稿谱距离定理的条件，没有切换项；稿件只需在 `eq:mfs-field` 后补一段说明（正文已给出段落）。
  - 两种代理：A 按核拟合（代理随源移动，沿用 proxy-accel 的源汇总）；B 按场拟合（固定 480 点源，一次 SVD 拟合全部 195 个右端，代理部分无源循环）。推荐 B。
  - 预测（全部五组的残差评价，不含 $C_g$ 与带隙证书）：A 单进程 26.3、8 进程 9.3 分钟；B 单进程 18.8、8 进程 7.4 分钟。面板 0、1 的 $e_I$ 预测 $<2.60/3.51\times10^{-18}$。
  - B 换了场，五组要重算；浮点小检查中中心接缝约 $2\times10^{-15}$，材料、墙点与 A 相差约 $10^{-15}$。

- 胞元核按场拟合先导（cellfit-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/cellfit-v1|cellfit-v1]]）：
  - 五组浮点：B（按场拟合）$Q=3.521\times10^{-12}$，是 A 的 0.998 倍；宽度预测 $2.77\times10^{-11}$；源点加倍变化约 $10^{-16}$。选 B。
  - 可靠试点：中心面板 0、1 的 $e_I$ 为 $2.40/3.31\times10^{-18}$；墙段、接缝、引线目标均在 $10^{-20}$ 以下。中心在线非自作用 0.25 秒／目标。
  - 成本：引线的 194 列状态映射使边界近像区域准备（约 23 秒／段，共 37.6 分钟）和引线材料（12.8 秒／目标，共 27 分钟）成为主项；串行预测 81 分钟。八进程报告值 47 分钟按区域准备全串行计，若区域准备也并行，同口径外推约 15.5 分钟。都未运行。

- 胞元核 B 整曲线与引线状态列（cellrel-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/cellrel-v1|cellrel-v1]]）：
  - 中心整条曲线可靠上界 $\varepsilon_{\rm center}\le1.261590\times10^{-12}$，是浮点值的 1.0004 倍；8 进程实测墙钟 83 秒，峰值 0.25 GiB。
  - 右引线只用实际状态列（59 个胞元，尾项用独立包络）：材料段贡献与 194 列相差 $4\times10^{-7}$（相对）；材料目标含准备快 2.4 倍，墙区域快 3–37 倍。
  - 外推（只有中心为实测）：单进程 34.3 分钟；8 进程区域准备串行 18.0、分发 7.2 分钟。不含可靠 $C_g$、带隙证书。

- 其余四组可靠缺陷与五组整体实测（grouprel-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/grouprel-v1|grouprel-v1]]）：
  - 可靠 $\varepsilon_g$：中心 $1.2616\times10^{-12}$、左引线 $5.097\times10^{-14}$、右引线 $5.201\times10^{-14}$、竖墙 $2.156\times10^{-13}$、接缝 $6.994\times10^{-15}$；与浮点值之比 1.0004／0.836／0.818／0.9997／0.986。两侧材料可靠值低于浮点值，经理判断是浮点评价的噪声，待下一阶段对照确认。
  - 五组 408 个目标一次运行：8 进程墙钟 8.6 分钟，CPU 54.7 分钟，峰值 2.17 GiB（实测）。第一次尝试因区间过估计出现 NaN 而停止，修复为同一复矩形二分。
  - 左引线 $\|P_-\|_F\le0.3814$，深度 52–56；右引线 56–58。
- 迹常数证书与 A 证书核对（cg-cert，理论线程，经理已核对，见 [[research/projects/bie-enclosure/theory/cg-cert|cg-cert]]）：
  - 可靠 $C_g$ = 2.490254／1.181583／1.233941／1.035553／1.035553，比扫描值大不到 0.025%。新证明：星形曲线领子单射判据 CG1、周期副本分离 CG2、区间细分曲率界 CG4、有限极值 CG5。
  - FEM 的 A 证书与 BIE 引线的模型约定一致，可引用；带隙余量 0.69／3.21。条件：A 的有限矩阵运算未计入舍入。
  - 经理用可靠 $C_g$ 与可靠 $\varepsilon_g$ 重算：$Q=3.4965\times10^{-12}$，全宽 $2.749\times10^{-11}$（FEM 的 1/162）。正式向外舍入组装待下一阶段。
- 最终可靠区间（enclosure-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/enclosure-v1|enclosure-v1]]）：
  - 向外舍入：$Q\le3.49654\times10^{-12}$，$R\le1.37428\times10^{-11}$，$k\in[1.5584378941776817,\,1.5584378941865001]$，全宽 $2.74856\times10^{-11}$，约为 FEM 的 1/162。(T1.5) 余量 0.6916／3.2119。经理用精确有理数独立重算，逐位一致。
  - 这是在报告所列条件下的可靠上界；A 证书的舍入条件已由 bandrel-v1 补齐。
  - 引线差异（OP-BE-7）：右引线实测，来自双精度法向跳跃的抵消噪声；左侧按同机制推断。
  - 已测阶段合计 19.8 分钟（拼接记录，非冷启动端到端）：候选搜索 10.7、五组残差 8.6、其余约 0.5 分钟。
- 正式搜索改用行列式求根（detsearch-v1，sol，浮点，经理已核对，见 [[research/projects/bie-enclosure/implementation/detsearch-v1|detsearch-v1]]）：11 线程科学进程 158 秒（I9 为 643 秒），match 38 次（I9 为 213 次）；候选 1.558437894182088，与 I9 差 $2.9\times10^{-15}$；未触发回退，强制回退也得同一候选。下游要用新 $\widehat k$ 重跑。
- 带隙证书 A 计入舍入（bandrel-v1，astra，经理已核对，见 [[research/projects/bie-enclosure/implementation/bandrel-v1|bandrel-v1]]）：两侧 118 面板共 472 项符号检查全部以 Arb 通过（单进程 77 秒）。最终区间的 (T1.5) 现在包含舍入，enclosure-v1 区间不需任何数值前提，是报告所列理论条件下的可靠上界。
- 搜索加速可行性（detscan-v1，sol，浮点，经理已核对，见 [[research/projects/bie-enclosure/implementation/detscan-v1|detscan-v1]]）：
  - $\det A_{\rm def}(k)$ 在 I9 窗口 $[1.451,2.249]$ 上可插值：64 阶 Chebyshev 系数降到 $10^{-14}$ 平台，节点处无极点（rcond 最小 0.038）。
  - 只找到一个近实根，抛光后与 I9 候选差 $2.2\times10^{-15}$；右端 2.249 的趋势不是根。
  - 实测 71 次评价、222 秒（5 线程），I9 为 213 次、548 秒。经理推算：32 阶加 2–3 步抛光约 36 次，约 1.6 分钟（未运行）。

## 进行中

- 草稿重组（建议已给用户）：第 5 节只留定义—定理—用法，迹常数几何与证明移附录 B，$\varepsilon_g$／$U$／带隙矩阵检查的截断与舍入控制合为附录 C；第 2 节带隙证书改成 A 的实际方法。
- 下一步：用新搜索做一次冷启动全流程实测（搜索→重建→B 拟合→五组残差→$C_g$→装配→带隙检查）。

- 草稿：胞元核、按场拟合、实际状态列和 cellrel-v1 的数值已写入 `draft/bie-enclosure/`（第 4、5 节补段，第 6 节初稿，2026-11-05），等用户检查。

- 草稿 `draft/bie-enclosure/`：第 1–5 节已按报告改完，改动处蓝色标注，待全文送审。

## 主要风险

- 可靠的 $\varepsilon$ 在 $10^{-12}$ 量级，需要约 12 位抵消；外层包络界可能太松，可能要用 Taylor 面板加直接求和（先导中直接求和 768 点 360 秒）。
- 切换项已是可靠上界，只放大 1.14 倍。剩下的成本风险在 $Q_{\rm grp}$：直接把现有节点全改成 Arb 约要 94 分钟以上，必须靠面板 Taylor 模型和源矩压缩；实测单价之前不能说比 FEM 便宜。
- 单盘质量下界余量太小；可靠质量必须用八个柱内盘（目标 $\underline U\ge1.20$）。
- 迹常数 $C_g$ 仍是 budget-v1 的扫描值，还需要几何证书。
