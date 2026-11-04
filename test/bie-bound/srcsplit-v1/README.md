# srcsplit-v1：source-split quadrature version 1

BIE 为 boundary integral equation；MFS 为 method of fundamental solutions；FMM 为 fast multipole method；RSS 为 resident set size。本实验固定 budget-v1 的场，诊断源回卷断点、墙残差与求和误差。所有数字均为浮点估计。

run-001 是直接核可行性检查，不构场：已有 FMM2D 的 h2ddir 明确执行全对直接求和；与 MATLAB h2d_directch 的128个点比对，绝对容差2e-13。测8192个差坐标目标的耗时，按完整墙求积的配对数外推；预估5–30秒、0.7–1.2 GiB。完整实验计划使用1536墙目标并抽取768；16阶Gauss的12/24/48总面板（192/384/768源点），面板边界包含所有分支断点；同节点数梯形对照，加1536源的FMM/直接对照。待吞吐量测定后写完整预算再运行。

启动器显式传输出、共享包和FMM路径，通过复制的监控器、MATLAB R2023b、11线程、OMP_DYNAMIC=FALSE运行。例：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/srcsplit-v1/launch.py --formula pilot --output test/bie-bound/srcsplit-v1/output/run-001 --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab
```

## run-002 完整预估和方案调整

run-001：直接代理核8192目标耗时0.48308 s，MATLAB直接核对照最大差8.71e-16；总15.362 s、0.8013 GiB。原方案仅直接代理求和预估2295.6 s，余量不足，不启动。改为12阶Gauss、8/16/32总面板（96/192/384点），同节点梯形对照仍保留全部1536目标；1536源的FMM评价全部目标、直接对照768目标。投影所有密度到其完整原生三角多项式，低节点梯形不截断密度频率。新直接代理预计约1148 s，加FMM、密度评价、断点和输出，完整24–28 min、峰值≤1.6 GiB；与先导合计仍在30 min软限内。每目标仅处理4个高度，差坐标块≤8192，不存大矩阵。

断点以解析高度的单调区间求根；每段至少一个基础面板，其余按长度分配，总面板数固定并逐档二分。记录所有目标/曲线的根数、根参数、残差。根残差容差2e-14，曲线原生一致性1e-13、任意点密度与interpft一致性1e-12；先复现Q5（相对1e-10）。收敛判读记录各档变化，不预设结果必须收敛。

完整命令与先导相同，改为 `--formula full --output test/bie-bound/srcsplit-v1/output/run-002`。

## run-003：单档源加密确认的预估

run-002 的分段192→384点仍有明显接合墙变化，另做768源点确认。384源点时，目标768→1536的墙总平方相对变化仅4.17e-5，因此确认档只用768目标，区分源与目标两个方向。入口 `srcsplit_fine` 复制同一计算路径，只运行一个分段规则，不重复梯形和后端比较。按384源/1536目标已测204.624 s的相同配对数，完整预估210–260 s、峰值≤1.3 GiB。启动前扣除前两次监控用时，把剩余30/40分钟预算显式传给监控器。

确认档重新按相同输入构造固定场一次，复现同一Q5；不改变波数、密度求解或代理参数。完整对照在run-002中共用一次构场，run-003仅为补充确认。最细两档的接合墙法向平方若相对变化<1%，判为在当前浮点尺度上趋稳，否则如实报告未收敛，不继续加档。

## 实测结果

全部运行完成，无数值断言失败。run-003 的384→768源加密比较以768目标为准：左右法向平方相对变化−0.4125%／−0.4044%，通过预先声明的1%趋稳判据。墙 epsilon 相对变化−0.3146%；接合墙值平方和变化−36.57%，该小分项还未收敛。原生密度与场保持固定，确认档 Q5 与主对照逐位相同。

断点数（1536目标）：中心0/2/4根对应771/645/120个目标，左0/2根对应895/641，右对应863/673。768子集分别385/323/60、447/321、431/337。根高度残差≤4.44e-16。`*-counts.csv` 三列是目标序号、y、根数；`*-breakpoints.csv` 五列是目标序号、y、源参数、源高度、方程残差。相同曲线左右墙共用断点，周期副本通过回卷表示。

`split-*-direct-t*.csv` 与 `trap-*-*-t*.csv` 九列为y、左值/右值/左法向/右法向的实部，然后四个虚部，支持独立重算法向及值平方。`result.json` 保存内墙、尾、所有设置和检查。`combined-summary.json` 的源误差参照是最细分段场，并非解析真值。

后端差：同为1536源/768目标，FMM与直接法向跳跃最大差2.775e-14/2.121e-14，L2差9.070e-15/9.651e-15。法向平方差仅−0.1082%/+0.0521%；值跳跃最大差≤1.201e-15。未分段1536源相对分段768源的法向L2差4.201e-13/4.717e-13，是后端差的46.3/48.9倍。未分段384→1536的观测误差阶1.015/1.098，支持源分支跳跃导致代数收敛。

固定组数据逐项录入 `srcsplit_settings.m`（出处 budget-v1/budget.json），数值入口不读取旧输出。最细墙 epsilon=7.6336310141e-13，总 epsilon=1.4748572558e-12，Q_grp=4.0088154357e-12；加固定切换项4.268e-11后，单盘/12盘余量1.36052111/14.96385881，两者均满足当前数值预算。

## 成本与复现

| 运行 | 内容 | 总墙时(s) | 峰值GiB |
|---|---|---:|---:|
| run-001 | 已安装的编译直接核与MATLAB核比较及吞吐量 | 15.362 | .801300 |
| run-002 | 完整三档分段/同节点梯形、1536源FMM/直接 | 1370.552 | 1.134064 |
| run-003 | 768源/768目标单档分段确认 | 225.215 | 1.027512 |

三次合计1611.129秒（26.85分钟），未使用软限延期。run-003启动时扣除前两次1385.914秒，传入剩余软限414秒、硬限1014秒。每个场计算进程只构场一次；总计两个相同输入的构场，核先导不构场。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/srcsplit-v1/launch.py --formula full --output test/bie-bound/srcsplit-v1/output/run-002 --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/srcsplit-v1/launch.py --formula fine --output test/bie-bound/srcsplit-v1/output/run-003 --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab --soft-seconds 414 --hard-seconds 1014
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/srcsplit-v1/compare_runs.py test/bie-bound/srcsplit-v1/output/run-001 test/bie-bound/srcsplit-v1/output/run-002 test/bie-bound/srcsplit-v1/output/run-003
```

MATLAB命令须经升级权限调用；重现选择新的空输出目录，按当次监控记录扣除共享预算，不能覆盖历史输出。`srcsplit_run(out,config,settings)`、`srcsplit_fine(out,config,settings)` 是数值入口；后者只做确认档。`summarize.py` 和 `compare_runs.py` 只对显式传入的本实验输出做算术汇总。

## 完整对照表

以下法向平方单位为1e-24，接合墙值平方和单位为1e-27，内墙包含左右及观测比率尾。每档耗时覆盖该规则全部曲线、两面墙与全部实际目标；抽取子集不重复计时。

| Rule | Source | Target | Backend | Left normal | Right normal | Junction value | Inner normal | Seconds |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| split | 96 | 768 | direct | 1.22629284e+12 | 7.73001645e+09 | 1.26373519e+12 | 3.27077274 | 52.830 |
| split | 96 | 1536 | direct | 1.1799574e+12 | 7.65869841e+09 | 1.19601485e+12 | 3.22083785 | 52.830 |
| trap | 96 | 768 | direct | 369.46259 | 1215118.95 | 138636.867 | 6.35292081 | 52.194 |
| trap | 96 | 1536 | direct | 368.884636 | 1215120.11 | 138637.095 | 6.30703548 | 52.194 |
| split | 192 | 768 | direct | 35.203095 | 51.2618955 | 39.360225 | 0.0810871719 | 102.572 |
| split | 192 | 1536 | direct | 35.0532697 | 51.0545089 | 39.294245 | 0.0811382048 | 102.572 |
| trap | 192 | 768 | direct | 12.1548162 | 17.8123656 | 5.07931223 | 1.72041971 | 113.456 |
| trap | 192 | 1536 | direct | 12.0127455 | 17.5869401 | 5.09735774 | 1.7417642 | 113.456 |
| split | 384 | 768 | direct | 0.202986442 | 0.295265217 | 4.52031717 | 0.081063234 | 204.624 |
| split | 384 | 1536 | direct | 0.202676566 | 0.295491592 | 4.52629771 | 0.0811160125 | 204.624 |
| trap | 384 | 768 | direct | 3.17840519 | 4.98707292 | 3.45149895 | 0.514284794 | 204.994 |
| trap | 384 | 1536 | direct | 3.17643658 | 5.10731724 | 3.4624795 | 0.507832944 | 204.994 |
| trap | 1536 | 768 | fmm | 0.380078922 | 0.520838368 | 2.99898185 | 0.106233009 | 204.735 |
| trap | 1536 | 1536 | fmm | 0.389097488 | 0.583428035 | 2.99873673 | 0.107009752 | 204.735 |
| trap | 1536 | 768 | direct | 0.379667724 | 0.521109796 | 2.96354276 | 0.106159514 | 413.113 |
| split | 768 | 384 | direct | 0.202197888 | 0.293583029 | 2.86662542 | 0.0808068464 | 207.014 |
| split | 768 | 768 | direct | 0.202149195 | 0.294071055 | 2.86744667 | 0.0810644964 | 207.014 |
