# BIE：boundary integral equation（边界积分方程）

FMM 是 fast multipole method（快速多极方法），MFS 是 method of fundamental solutions（基本解方法），QP 是 quasi-periodic（准周期）。`eval-pilot-v1` 是 fixed-field evaluation pilot version 1，固定场评价先导第一版。

本目录先判断 I9.2 的谱距离估计是否受评价误差限制。具体入口、复现命令与成本见 [eval-pilot-v1/README.md](eval-pilot-v1/README.md)。

`budget-v1` 是 fixed-field enclosure error budget version 1，固定场包含区间的误差预算第一版。
`switch-v1` 是 MFS wrap switch-line defect version 1，回卷切换线缺陷与加入该项后的浮点预算。
`srcsplit-v1` 是 source-split quadrature version 1，源分支断点分段求积与接合墙残差诊断。
`switch-rel-v1` 是 reliable switch-line bound version 1，以 Arb 球算术包住回卷核切换项、连续源积分及引线传播尾。
