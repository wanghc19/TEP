# I3.2 独立 reference：暂缓设计

本页不参与 I3.1 estimator 公式的构造。只有
[[research/projects/eig-apost/phase3-analysis/s-estimator|I3.1 estimator specification]]
冻结后，才设计 I3.2 的 independent-reference validation。

最低原则已由 [[research/projects/eig-apost/implementation/i3/README|I3 guide]] 固定：

1. estimator 公式、任何 calibration constants、样本和排除规则必须在接触 validation truth 前
   冻结；
2. 优先使用与当前 BIE/QZ 不同的数值表述或独立实现；
3. QZ、Riccati 和 doubling 若共享同一个 one-cell map，只能检查 half-guide treatment，不能
   充当整个连续 eigenvalue 的独立 truth；
4. 同方法高分辨率结果只能作共享偏差后备，并报告自身 uncertainty；
5. reference resolution 不足、estimator failure 和适用区间未达到必须分开。

当前没有冻结具体 reference、算法、参数、阈值或实验流程。这样做是为了避免 I3.2 数据反过来
参与 I3.1 公式选择，造成循环验证。
