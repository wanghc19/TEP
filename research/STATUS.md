# Research status

更新日期：2026-08-22。

状态词含义：`established in archived mainline` 仅表示冻结主线给出了论证，不等于已完成独立来源核验；`needs review` 表示已有陈述或证明草案但仍需严格审计；`tentative` 表示研究性判断；`unresolved` 表示尚未解决。

## 当前阶段

此前的统一目标是在固定实数准周期参数 $\beta$ 下研究二维周期线缺陷波导的导模，
并建立中心胞元 Müller--Rayleigh 表示与左右周期半波导出射 Cauchy 关系之间的连续
耦合。该路线现已暂停；当前把 fixed-$\beta$ line-defect guided-mode eigenvalue 的
numerical half-guide DtN 后验误差作为专题候选方向。其 manufactured NEP、Half-guide
map 与 Augmented BIE 离散实现门已经通过；历史 Root-readiness diagnostic 及其后续
Ewald/MFS/Rayleigh、SLP/DLP 和有限 $M_{\mathrm{trace}}$ 结果保留为离散数值证据。
2026-08-11 起旧 I4 数值工作暂停并完成 continuous DtN/BIE method reconstruction：
精确 DtN 由半无限 PDE 定义，physical center pencil $\mathcal F(k)$ 先于 BIE、QZ 和矩阵。
旧 finite-tail/doubling 主方法已降为 legacy/cross-check。新路线 I1.1--I1.2 已完成
离散设计和 static $A_{\mathrm{def}}$ 验证；I1.3 又完成 real-$k$ 连续性、分层筛查与
width-driven $M=48$ 局部加密，阶段为 `PASS WITH CONDITIONS`。新版局部实验在 15 层、
33 个唯一点和 167 个 hard gates 全部通过后，以
$7.6294\times10^{-7}$ 的区间宽度正常结束，记录离散候选
$k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$。coarse/fine 最小位置
全程无漂移；最终三个 $q$ 值仍明显变化，因此不是 $10^{-3}$ 平台。旧 prominence
design-gate stop 保留为历史负例，原设计 blocker 已关闭。I1.4 随后在固定 $M=48$ 小复圆盘
上完成 anchored branch、QZ/graph/DtN、factor、closure、CR 和负例门，阶段为
`PASS WITH CONDITIONS`。I2.1 随后在同一 fine、$M=48$ 小圆盘得到条件性 finite-dimensional
count one；I2.2 的 Hermitian-part 两端 sign count 得到稳定 `SINGLE_JUMP`，只作 candidate
佐证。I2.3 又分别完成边界 Nyström 轴 $n_{\mathrm{tot}}=160,208,256$ 与固定
$n_{\mathrm{tot}}=160$ 的 trace-cutoff 轴 $M=32,40,48$；两条轴的三层最低原始门和
`SAME_MODE` 均通过，且各轴三层 saved candidate 完全相同，故状态为
`PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。terminal-cell 半宽只作
sub-grid minimizer 的搜索分辨率；该结果不是 minimizer/root 零漂移或收敛证据。I3.1 已完成
首个中心空列 continuous strong-residual baseline：computed ratio 为 $22.43882099031153$，积分层
稳定，但固定单胞 cutoff 导数项主导，名义区间跨过零，故状态为
`FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`。这不是可靠存在区间，也不能进入 I3.2。I3.1
继续活动；全波导 BIE-informed Fourier--Hermite/bubble trial 随后正式运行。`lead-a3` 通过
finite input、density representation 和 propagation，但固定 fit 的 $J=4/8$ holdout error
约为 $4.522421/5.138028$，高于 $0.20$，故在
`CONFORMING_RECONSTRUCTION_UNRESOLVED` 首败处停止。center、Gram、tail 和 residual ratio 均
未到达；现有近圆 targets 又不足以区分 close layer-potential evaluation 与 basis/metric 的
贡献。该结果是 `PASS WITH CONDITIONS / VALID NEGATIVE`。随后 Q1--RT0 continuous weak
residual V2 正式 `weak-a1` 通过 base finite input、propagation、Q1--RT0、Gram 与 full-$P$
tail checks，但在 fine phase/scale repeat 的 per-cell Gram Hermitian gate 首败；最大 defect
$6.2442\times10^{-10}$ 高于 $10^{-12}$。该 run 是 `POST-RUN PASS / VALID NEGATIVE`，仍没有
estimator，I3.2 不可开始。BIE-collar V3 正式 `bie-a3` 随后通过 finite input、branch/Wood、
propagation、density、surface trace 与 safe-field 门，但在 coarse lead 的 composite
RT0-majorant 预因子处以 `HDIV_FLUX_UNRESOLVED` 停止。当前只可判定含材料圆修正的
quadrature/assembly 未资格化；没有 flux、majorant、tail、indicator 或 interval。I3.1 仍无
estimator，I3.2 不可开始。
第一层目标仍是
candidate 到 current projected gap 内离散谱集合的距离：可靠区间
进入该 gap 后先得到至少一个离散特征值，且只有通过结果前冻结的 absolute/gap-relative
resolution 才接受为分辨率级结论。唯一目标识别只在特定 mode 跟踪时升级。continuous
residual estimator、sharp-disk projected-gap contract 和 upper bound 尚未建立，也没有
活动中的 `research/mainline/`。

原主线冻结于 Git 标签 `mainline-muller-cauchy-2026-07-26`，文件移至
`research/archive/muller-cauchy-2026-07/`。冻结版本主要考虑实数 `k`、严格公共
投影带隙、非 Wood 参数、分片常数正材料和广义 Bloch/Jordan 模态，并允许左右
半波导不同。该归档只作历史参考；除非任务明确选择它，否则不支配后续新方向。

## 专题状态

| 状态 | 专题 | 实际结论 |
|---|---|---|
| active investigation / I3.1 four valid negative experiments; no estimator | `research/projects/eig-apost/` | PDE-defined physical operator 是连续主对象；I2.1--I2.3 已完成。中心空列 baseline 受固定 cutoff 主导；全波导 trial 在 fixed BIE-informed fit 首败；Q1--RT0 V2 在 phase/scale Gram qualification 首败；BIE-collar V3 又在含圆盘修正的 RT0-majorant 预因子首败。四项都不能进入 I3.2；保持正性的 majorant assembly、tail、mesh/width、可靠 enclosure、独立 $k_{\mathrm{ref}}$ 与 sharp-disk projected-gap contract 均未完成；unique target 仅为可选升级。 |
| paused archive | `research/archive/muller-cauchy-2026-07/` | 冻结的 Müller--广义 Bloch--Cauchy 主线；商空间版本的核/场等价仍有未闭合的外部定理适配和表示论前提。 |
| paused | `research/projects/half-guide-dtn/` | Stage 1 完成了符号审计、齐次半导 DtN/Riccati 验证和耦合方案建议；周期障碍半导、完整中心耦合及 MATLAB 最终验证尚未完成。该路线未整合进冻结主线。 |
| completed project | `research/projects/cell-representation/` | 专题任务已完成：原始无条件猜想过强；给出了直接 Green 表示和带显式正则性、非 Wood 及互补问题条件的修正版。其纠正后的表示结构和商空间策略已进入冻结主线，但其中的表示定理仍为 `needs review`。 |
| completed project | `research/projects/novelty-audit/` | 文献与创新性审计及带边/共振扩展已完成。结论是多数单独组件已有先例；潜在贡献在精确耦合、无伪根核定理及认证求解器的交叉处，不能据此宣称优先权。 |
| completed planning artifact | `research/planning/muller-cauchy/` | 路线图任务已完成；它列出证明依赖、风险和退路，不表示其中定理已经证明。 |

## 冻结主线中相对确定的结果

- `established in archived mainline`：固定 $\beta$ 的加权自伴算子框架，以及弱形式与分片传输形式的等价。
- `established in archived mainline; source review pending`：两种周期端的本质谱为左右背景谱之并，冻结主线附录 A 给出证明；严格公共带隙是该归档中扫描与局域化框架的基础。
- `established as framework choice`：出射对象首先作为 Cauchy 关系处理；只有 Dirichlet 投影可逆时才写成 DtN 图。
- `established as necessary formulation choice`：一般情形必须允许广义 Floquet 模态和 Jordan 链，不能只使用普通 Bloch 特征向量。
- `established as safety policy in the archive`：中心密度和全局代数未知量的唯一性不能预设；冻结版本的主定理采用表示零空间的商。

## 未解决问题与 proof gaps

- `needs review`：把 Hohage--Soussi 型广义模态/Riesz 基结果适配到冻结版本的分片传输半波导和双分量、面向中心区的 Cauchy 迹。
- `unresolved`：公共带隙目前只严格排除了平移算子单位圆上的点谱；单位圆全谱排除仍需另证。
- `needs review`：中心胞元 Müller--Rayleigh 表示的满射性、互补交换波数问题、Green 消去恒等式和表示例外集合。
- `unresolved`：显式刻画并控制中心表示零空间 `N_c` 与全局表示零空间 `N_rep`；不取商的无伪根结论尚未建立。
- `unresolved`：主要核--导模等价仍依赖冻结版本正则集中的模态和表示假设，不能作为已完成定理引用。
- `conjectural`：自然方形实现、参考算子加紧扰动以及 Fredholm 指标为零。
- `future`：离散谱正确性、无谱污染、认证轮廓求解器、精确带边和复共振理论。
- `needs review`：英文版和中文版的符号、内容与引用核验段尚未完全同步；冻结版本中还有失效的旧路线图路径。

## 转向期间的工作规则

1. 在新方向可以明确命名并形成稳定框架以前，不建立空的 `research/mainline/`。
2. 零散但可保留的方向讨论进入 `research/planning/`；只有形成多文件、多轮调查后才在 `research/projects/` 建立专题。
3. 不在冻结目录中继续日常开发；若恢复 Müller--Cauchy 路线，应从冻结标签建立分支，或记录决定后重新建立活动主线。
4. 归档中的未证明结论、待核验引用和中英文差异保持原有成熟度，不因归档而自动升级或失效。
5. 新方向形成后，应更新 `research/DECISIONS.md`、本文件和 `research/README.md`，再决定是否建立新的 `research/mainline/`。

当前活动专题是偏工程实现的特征值后验误差研究。I1.4 sampled readiness、I2.1 条件性
count one、I2.2 endpoint corroboration 与 I2.3 的 `ntot`/$M$ 两条三层同-mode candidate 实验均已完成。I2.3
两条轴均得到 `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。I3.1 的首个中心空列 continuous
strong-residual baseline 已完成，computed ratio 为 $22.43882099031153$；固定单胞 cutoff 主导且
名义区间跨过零，故分辨率不足。全波导 `lead-a3` 又在 fixed BIE-informed holdout fit 首败，
尚未形成 continuous residual；不能把失败单因归咎于 bubble basis，因为 near-circle direct
evaluation 未资格化。Q1--RT0 `weak-a1` 随后在 fine phase/scale Gram qualification 首败；base
diagnostics 还显示 mesh/width 未闭合。BIE-collar `bie-a3` 随后关闭真实 incoming、one-sided
trace 与 safe evaluation 的内部门，却在 coarse lead RT0-majorant 的 composite quadrature/assembly
处首败；没有形成 residual 或区间。四项均不能进入 I3.2。independent reference 仍属于取得有用 estimator
candidate 后的 I3.2。零 observed shift 不能单独验证 correction、收敛或 estimator。
qualified conforming reconstruction/weak residual、sharp-disk projected-gap contract、
预注册 absolute/gap-relative resolution 与 reliable enclosure 继续限制后续 estimator 和上界
声明。unique-target isolation 只限制指定-mode升级。production derivative/separation 与 projected/regular
approximation 只限制相应 finite-correction 或离散谱收敛支线，不再是 I3.1 主线门，也不升级为
统一研究方向。
冻结路线若被恢复，其优先事项仍是单位圆全谱排除、
广义 Floquet/Riesz 基适配、中心表示满射性和表示零空间刻画；具体记录见
`research/archive/muller-cauchy-2026-07/review-log.md`。
