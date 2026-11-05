# 状态

更新日期：2026-11-05。

## 已完成

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

- 自作用加速方案（理论线程，[[research/projects/bie-enclosure/theory/selfint-accel|selfint-accel]]，待审查；经理已复算关键数）：
  - 推荐 A3：在 40 个实 Chebyshev 点上算 Kress 和（$N=1152$，源条带 $a=0.08$，128 位），再插值成多项式；不再在复目标点上求和。预测自作用每面板 1.3–1.8 秒（原 27 秒），新增误差 $<4\times10^{-17}$。
  - A2：Kress 误差界多一个 $1/n$ 因子，节点数可再降。D2：自作用单独做多项式后，其余部分的 Taylor 尾项从 $2.9\times10^{-15}$ 降到 $7.6\times10^{-18}$，$e_I$ 预计减半。D1：同一曲线复用源几何和源矩，每面板再省约 4 秒。
  - 近远分裂（B）和直接求目标系数（C）误差可控，但按单块计时更慢，不推荐。
  - 自作用替换后，每面板约 19–24 秒，最大一项变成混合代理系数（16.8 秒）。单进程外推约 107–110 分钟（245 分钟那组计数）。

## 进行中

- 等用户决定：selfint-accel 送审，以及让 astra 在面板 0、1 上验证 A3（<3 秒、$e_{\rm self}\le10^{-16}$）。

- 草稿 `draft/bie-enclosure/`：第 1–5 节已按报告改完，改动处蓝色标注，待全文送审。

## 主要风险

- 可靠的 $\varepsilon$ 在 $10^{-12}$ 量级，需要约 12 位抵消；外层包络界可能太松，可能要用 Taylor 面板加直接求和（先导中直接求和 768 点 360 秒）。
- 切换项已是可靠上界，只放大 1.14 倍。剩下的成本风险在 $Q_{\rm grp}$：直接把现有节点全改成 Arb 约要 94 分钟以上，必须靠面板 Taylor 模型和源矩压缩；实测单价之前不能说比 FEM 便宜。
- 单盘质量下界余量太小；可靠质量必须用八个柱内盘（目标 $\underline U\ge1.20$）。
- 迹常数 $C_g$ 仍是 budget-v1 的扫描值，还需要几何证书。
