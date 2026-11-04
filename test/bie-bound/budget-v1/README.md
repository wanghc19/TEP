# budget-v1: fixed-field enclosure error budget version 1

BIE = boundary integral equation; MFS = method of fundamental solutions; QP = quasi-periodic; FMM = fast multipole method. 本实验估计固定 I9.2 场的分组迹常数、接缝、圆盘质量和源／目标分离预算。

数值输入由 pilot_config.m 和 budget_run 的显式 settings 给出。数值入口不读取文档、旧输出或目录元数据。复制的监控器限 11 线程、30 分钟软限、40 分钟硬限、3 GiB RSS；不保存场 MAT。

运行前预估：run-001 构场、768 复现、四档源节点的墙扫描、1536 材料与接缝、圆盘质量共 12–20 分钟，峰值 2.5 GiB。3072 源墙只保留一侧层矩阵，预计不超过 2.5 GiB。若前面墙扫描耗时已使总预测超过 30 分钟，省略3072并明确记录。

run-001 完成：基线 epsilon 与先导相同，构场次数 1，密度／代理系数／传播矩阵保持不变。MATLAB 共 754.03 秒，峰值 1.71484 GiB，无 MAT 输出。最终 epsilon = 1.517963848e-12，Q_grp = 4.091949475e-12；原 U 配分组常数的 B0 余量为 15.5234，12 盘 Q5 为 170.7364。所有结果均为浮点估计。

核查：两条迹常数复现；10 段值／法向平方和分别与中心总量相符至 1e-13 相对精度；12 盘两两分离且避开材料、墙与接缝；Q6 的 64／128 点结果相差 4.44e-16 相对量；原盘积分重现 U 至 4.16e-17 绝对差。预算汇总脚本对上述分段和、净空以及 Q_w <= Q_grp 作断言。

尚未收敛的是墙的源评价：1536 到 3072 源仍使两接合墙法向平方下降约 36%。现核的源／目标周期差回卷与 T2.1 分片精确场的对应关系也须先核对。完整结论见 research/projects/bie-enclosure/implementation/budget-v1.md。

## 入口与复现

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/budget-v1/launch.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/budget-v1/output/run-002 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab
PYTHONDONTWRITEBYTECODE=1 conda run -n octave python -I \
  test/bie-bound/budget-v1/geometry_budget.py \
  --output test/bie-bound/budget-v1/output/run-002 --nodes 2048 --dense 65536
PYTHONDONTWRITEBYTECODE=1 conda run -n octave python -I \
  test/bie-bound/budget-v1/assemble_budget.py \
  --run test/bie-bound/budget-v1/output/run-002
```

先运行MATLAB再在同一目录生成几何与预算，避免把已有输出当作隐含输入。run-001 中几何计算与MATLAB并行，输出文件名相互独立。`budget_run(out,config,settings)` 与各 Python 入口均使用显式参数。数学场由原生三角密度、原有代理核与传播系数指定；所有源节点档都不重求密度或QZ。

源／目标扫描一次评价1536个目标，再抽取隔点子集得到768的外层积分。这使两档共享完全相同的点值；源0表示中心512、引线256的原生设置。源768、1536、3072三档用于全部三条曲线。完整墙点值与每组有限和／数值尾均保留；材料用1536阶Kress，接缝用1536源／1536目标。

geometry_budget.py 从同样的星形 Fourier 参数式和等面积三瓣形计算几何。它逐对相交法线并检查周期副本，寻找浮点半宽极限；随后按T4.2–T4.3的有限驻点公式与标量优化选择参数。该扫描不是几何证书。

mass：23×23粗点网格覆盖中心和最近的两引线胞元，分别评价背景与柱内的原始层势。半径取材料距离、胞元墙及水平接缝距离最小值的0.96倍，并封顶0.2；按Q5正贡献贪心选最多12个全局不交圆盘。Q6保留m=-4:4，在0.8R圆周上用64、128点比较。
