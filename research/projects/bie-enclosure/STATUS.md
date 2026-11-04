# 状态

更新日期：2026-11-04。

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

## 进行中

- 草稿 `draft/bie-enclosure/`：第 1–5 节已按报告改完，改动处蓝色标注，待全文送审。

## 主要风险

- 可靠的 $\varepsilon$ 在 $10^{-12}$ 量级，需要约 12 位抵消；外层包络界可能太松，可能要用 Taylor 面板加直接求和（先导中直接求和 768 点 360 秒）。
- 接合墙法向跳跃随源节点仍在下降（OP-BE-3）。
- MFS 核回卷切换线的缺陷（OP-BE-6）可能吃掉一部分余量；可能要换以胞元为界的核。
