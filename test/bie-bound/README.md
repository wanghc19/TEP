# BIE：boundary integral equation（边界积分方程）

FMM 是 fast multipole method（快速多极方法），MFS 是 method of fundamental solutions（基本解方法），QP 是 quasi-periodic（准周期）。`eval-pilot-v1` 是 fixed-field evaluation pilot version 1，固定场评价先导第一版。

本目录先判断 I9.2 的谱距离估计是否受评价误差限制。具体入口、复现命令与成本见 [eval-pilot-v1/README.md](eval-pilot-v1/README.md)。

`budget-v1` 是 fixed-field enclosure error budget version 1，固定场包含区间的误差预算第一版。
`switch-v1` 是 MFS wrap switch-line defect version 1，回卷切换线缺陷与加入该项后的浮点预算。
`srcsplit-v1` 是 source-split quadrature version 1，源分支断点分段求积与接合墙残差诊断。
`switch-rel-v1` 是 reliable switch-line bound version 1，以 Arb 球算术包住回卷核切换项、连续源积分及引线传播尾。
`matrel-v1` 是 material reliable pilot version 1，中心材料曲线残差的可靠评价与成本先导。
`selfint-v1` 是 self-interaction version 1，实 Chebyshev 自作用与源缓存的可靠先导。
`central-rel-v1` 是 central material reliable bound version 1，整条中心材料曲线的可靠残差与并行成本。
`cellker-v1` 是 cell-bounded kernel version 1，三近像与胞元外代理核的同密度浮点残差比较。
`proxyagg-v1` 是 proxy source aggregation version 1，全局代理源汇总与实节点插值的两面板可靠先导。
`cellfit-v1` 是 cell kernel field fit version 1，逐核／逐场代理拟合的五组浮点预算与可靠先导。
`cellrel-v1` 是 cell kernel reliable evaluation version 1，胞元核 B 的中心整曲线可靠残差与引线实际状态列先导。
`grouprel-v1` 是 group reliable evaluation version 1，胞元核 B 的五组可靠残差与一次完整并行运行。
