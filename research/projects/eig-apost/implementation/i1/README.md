# I1 discrete operator readiness

## 当前状态

状态为 `I1_3_PASS_WITH_CONDITIONS / M48_DISCRETE_NESTED_GRID_CANDIDATE`。
I1.2 的 $M=48$ static chain 保持通过；I1.3 在同一 homogeneous missing-column 模型上
完成 real-$k$ 连续性、$M=12\to24\to48$ 分层筛查，以及独立预注册的 width-driven
$M=48$ 局部加密。宽扫先记录 $k=1.83125$；新版局部加密在 15 个区间层、33 个唯一
$k$ 点上正常达到区间宽度 $7.6293945294736432\times10^{-7}<10^{-6}$，最终离散候选为
$k=1.8327703475952146$。coarse/fine 最小位置在全部 15 层完全一致，最终物理
$s_1$ 分别为 $8.32008721372168\times10^{-8}$ 与
$8.3200886232193094\times10^{-8}$；对应物理 $\sigma_1$ 约为
$1.11983\times10^{-8}$。

新版实验的 167 个 hard gates 全部通过：QZ 始终为 97 stable / 97 unstable、
0 neutral / 0 indeterminate；最小相邻 subspace overlap 为 $0.9999959813$，最终
$\sigma_1/\sigma_2=1.6258325\times10^{-7}$，粗细层最小左右奇异向量 overlap 约为 1，
raw/physical 最低点一致。局部和固定肩部 prominence 均只作诊断；历史 v1 zoom 在
第一级因 shrinking-neighbor prominence 门停止的 verdict 保留，但该实验设计 blocker 已由
v2 关闭。最终三个 $q$ 值仍以约 $46.9\%$ 和 $55.8\%$ 变化，故不是
$10^{-3}$ 平台；最终分类为 `LE_1E3_MAGNITUDE`，而非 root-convergence 结论。

该点只称 fixed-$M=48$ finite-dimensional real-axis candidate，不称 root 或 eigenvalue。
中心差分的绝对收敛、二阶比率及粗细层 action 已通过，但 graph-basis mutation 后的导数
变化为 $3.65\times10^{-11}>10^{-12}$；因此 `FD_DERIVATIVE_READY=false`，导数只作诊断，
不得进入 Newton、root correction 或 estimator。production separation 仍为
`IMPORTANT CAVEAT`。I1.4 本轮未开始、未获数值执行授权；anchored complex-$k$ branch、
fixed chart/rank、factor/pole ledger、CR 和实际对象负例仍是进入 locator/root 前的下一门。

## 本目录

- [[research/projects/eig-apost/implementation/i1/design|design.md]]：当前离散
  $A_{\mathrm{def}}$ 的唯一设计权威，含空间、基、符号、维数、QZ、chart、组装、导数和
  实现契约。
- [[research/projects/eig-apost/implementation/i1/review|review.md]]：记录两项独立
  Skeptic 的多轮审查、已修复 blocker、剩余 caveat 和授权边界。数值结果保存在对应
  `test/` 实验中，不在 implementation 内复制 `result.md`。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只记录新路线 I1--I4
  项目级依赖和退出条件。

## I1 内部里程碑

| Milestone | 内容 | 当前状态 | 下一门 |
|---|---|---|---|
| I1.1 理论设计 | 连续 $\mathcal F$ 对应、empty-center $A_{\mathrm{def}}^{D/G}$、符号、尺寸和失败策略 | `PASS WITH CONDITIONS` | design-level blocker 为 0 |
| I1.2 half-guide 到 $A_{\mathrm{def}}$ 的联合验证 | 人工装配、真实 one-cell 双向 QZ、Cauchy graph/safe DtN 和两种 $A_{\mathrm{def}}$ 表示 | `PASS WITH CONDITIONS` | direct $M=48$ static empirical chain 通过；production separation 未计算但不阻止经验推进 |
| I1.3 参数扰动、连续性和 $A_{\mathrm{def}}'$ | 固定分支、subspace transport、导数、adjoint/Gram 与平衡一致性 | `PASS WITH CONDITIONS` | width-driven $M=48$ candidate 通过；FD mutation 门失败，production derivative 仍不可用 |
| I1.4 locator readiness | anchored branch、小复圆盘、factor/pole ledger、必要负例与 anti-collapse | `NOT STARTED / SEPARATE AUTHORIZATION REQUIRED` | 先预注册 anchored complex-$k$ readiness；本轮不运行 locator、contour 或 root isolation |

## 权威和证据边界

连续真实谱对象仍由
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]] 定义。
I1 的当前设计只是它的有限维实现合同；OP-M0 的 kernel--field、continuous-to-cell、
analyticity 和 regular spectral approximation 证明缺口仍由
[[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 管理。

历史 numerical qualification 可作为部件证据，但不等于当前 $A_{\mathrm{def}}$ 已通过。
I1.2 当前实验入口与权威 MATLAB 报告分别为 `test/i1/hg-adef/README.md` 和
`test/i1/hg-adef/output/prod-full/report.md`。I1.3 的统一入口与权威总报告见
[[test/README#I1-K-SCAN-V1|I1-K-SCAN-V1]] 和
`test/i1/k-scan/output/full/report.md`。低阶报告
`test/i1/hg-adef/output/real/report.md` 保持为 mechanism evidence；旧
`output/prod-pilot/report.md` 已明确标为 non-authoritative matrix-free exploration。
历史 v1 zoom 的停止报告为 `test/i1/k-scan/output/zoom/report.md`；其
`ZOOM_SCORE_GATE_FAIL / NESTED_SCORE_GATE` verdict 不作追溯改写。当前 width-driven v2 的
预注册计划和权威报告分别为 `test/i1/k-scan/p-zoom2.md` 与
`test/i1/k-scan/output/zoom2/report.md`，统一入口见
[[test/README#I1-K-SCAN-ZOOM-V2|I1-K-SCAN-ZOOM-V2]]。
统一历史实验入口见
[[test/archive/legacy-route-v1/README#I4-DLP-TRACE-V1|I4-DLP-TRACE-V1]]；旧 augmented-BIE 和
finite-tail 只从
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]] 追溯。

## 推荐阅读顺序

1. [[research/projects/eig-apost/implementation/i1/design|I1 design]]。
2. [[research/projects/eig-apost/implementation/i1/review|I1 review]]。
3. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 和
   [[research/projects/eig-apost/implementation/open-problems#Current I1|current I1 ledger]]。
4. [[research/projects/eig-apost/phase4-report/method.tex|continuous method]]。
