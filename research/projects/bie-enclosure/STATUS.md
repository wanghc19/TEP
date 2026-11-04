# 状态

更新日期：2026-11-04。

## 已完成

- 固定场浮点评价先导与查新（见 README 链接）。
- ChatGPT Pro 报告 [[research/projects/bie-enclosure/theory/reliable-bound|reliable-bound]]，经理核对了：Fliss 2013 Remark 2.1(2) 允许左右引线不同（读了本地 PDF）；T1.1 的参数逆与 Weyl 序列论证；T2.3 接缝 Green 公式的符号；T4.2 保留 Jacobian 的迹引理（$T_\kappa$ 公式数值复现）与 T4.3 联合乘子；$C=9.571/7.668/4.695$ 与墙上 $C=1.0356$ 数值复现；圆盘平均值恒等式。未细查：T3.2 Kress 界、T3.4a 源簇 Taylor 树、T1.3 衰减、T2.2 正则性。
- 粗估（浮点，非可靠）：接缝跳跃平方约 $4.4\times10^{-27}$，只占 $\varepsilon^2$ 的 0.1%；按分组迹常数 $Q\approx7.7\times10^{-12}$（原 $1.97\times10^{-11}$），$W\approx6.1\times10^{-10}$。

- 报告审查（2026-11-04，审查线程，用时 8.5 分钟）[[research/projects/bie-enclosure/theory/reliable-bound-review|reliable-bound-review]]：0 个 blocker、1 个 important caveat、0 个 minor。R-1：带隙证书式 (T1.7) 中负的特征值下界要先截成 0 再开方，已在草稿中改正。两组优先项都判为正确，审查者核对了 Fliss 2013、Trefethen–Weideman 2014、Dahne–Salvy 2020 的原文。第二组（T3.1–T3.3、T2.4）和低优先项每项只有一行结论，审得较浅；T3.2 Kress 界、T3.4a 源簇 Taylor 树在实现可靠评价前应再细审一次。

## 进行中（2026-11-04 派出）

- sol：预算实验 `test/bie-bound/budget-v1/`（分组 $C_g$、接缝计入 $\varepsilon$、$U$ 的下界、接合墙 768/1536 下降的来源），报告 `implementation/budget-v1.md`。
- 草稿 `draft/bie-enclosure/`：第 1–5 节已按报告改完（两引线、MFS 场与接缝、分组迹常数、圆盘质量下界、带隙证书），改动处蓝色标注"待审查"，等审查结果再定稿。

## 主要风险

- 可靠的 $\varepsilon$ 在 $10^{-12}$ 量级，需要约 12 位抵消；外层包络界可能太松，可能要用 Taylor 面板加直接求和（先导中直接求和 768 点 360 秒）。
- 单个圆盘给出的 $U$ 下界可能太弱。
- 接合墙法向跳跃在 1536 点下降约 60%；先导里源求积节点与评价节点一起变化，所以不知道是场变了还是外层求积没收敛。
