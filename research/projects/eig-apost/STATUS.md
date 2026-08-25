# Eigenvalue a posteriori error status

更新日期：2026-08-25。

## 当前状态

- **2026-08-25 I3.2 same-trial evaluation-cap 负结果：** `ecap-a1` 已消费并保留为
  `I3_2_EXECUTION_UNAVAILABLE` implementation failure；它在 `LOCAL_identity` 的 integer/double
  arithmetic 停止，随后 report open permission 又使 shell exit 1。Revision E `ecap-a2` 通过
  certificate identity，并完成冻结的 7 个 image、3 个 circle、3 个 wall 及 Riccati/Gauss
  same-trial evaluation levels。实际 retained memory $664.47068214416504$ MiB 超过 $640$ MiB
  hard limit，所以在 cap/full-$P$/$q$/interval 前停止，状态为
  `I3_2_RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED`。已到达的 diagnostics 另有
  actual-$\Delta T$ contraction $2.2946515117026931>0.80$、finite-image Bloch
  $0.071741947137921119>10^{-10}$、analytic-kernel aggregate `Inf` 三项资格失败。这些是
  ordinary same-chain negative evidence，不是 independent reference 或 strict cap。当前 I3.2
  包含已建立的 conditional theorem 与 same-trial empirical-cap application；I3.3 只保留
  independent reference/effectivity；I3.4 负责 strict enclosure、certified gap 和 existence。
  全部 strict/reliable/independent/existence flags 仍 false。独立审查见
  [[research/projects/eig-apost/implementation/i3/review-3-2b|review-3-2b]]。

- **2026-08-24 I3.2 条件性离散证书谱包含定理：**
  [[research/projects/eig-apost/implementation/i3/design-3-2a|design-3-2a]] 已由 Researcher
  接受并由 Skeptic `DESIGN PASS`。对 finite certificate $z_h$ 定义的 exact continuous trial，
  若严格 caps 给出 residual dual-norm 上界和同一 trial 的 field-norm 下界，则
  $\bar q_h<1$ 推出显式非对称区间与 $\sigma(A)$ 相交；同一算子的 certified projected gap
  包含该区间时，才进一步推出 gap 内至少存在一个离散特征值。`fbie-a1` 的普通双精度预算给出
  $q_{\mathrm{res}}=2.72811057103771594\times10^{-7}$、$\epsilon_M$ 轴
  $6.07294883936662387\times10^{-7}$ 和 $\epsilon_N$ 轴
  $4.95911110122031616$，但不是严格 cap。定理已经建立，实际 application hypotheses 仍 open；
  本轮没有新实验。独立审查见
  [[research/projects/eig-apost/implementation/i3/review-3-2a|review-3-2a]]。

- **2026-08-24 I3.1 全边界胞元 BIE indicator candidate：**
  [[research/projects/eig-apost/implementation/i3/design-3-1f|design-3-1f]] 将 $M=48$ 只用于共享
  wall trace 输入，以独立 $256/512$ wall response、circle Müller action、显式 value lifts 和
  full-$P$ tails 计算连续弱残量对象。正式 `fbie-a1` 已完成并消费，得到 wall/circle/value-lift
  components $1.8732026085453917\times10^{-10}$、$2.9776880587814564\times10^{-15}$、
  $4.246327820844503\times10^{-11}$，field lower $2.2269063318145634$，故
  $q=1.0318643108971929\times10^{-10}$；名义区间为
  $[1.83277028891904,1.8327702892972739]$。唯一 warning 是 circle action $256\to512$ ratio
  $0.77408786032496468>0.20$，所以 verdict 为
  `PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`。wall 与 actual $\Delta T$ checks 通过；
  $M=48$ 是 input-only，所有 512 个已计算 circle modes 进入 $q$ 且 angular-tail 门通过，
  outside-$M$ share $3.6179\%$ 只是描述性诊断。未计算 Fourier tail 仍未 enclosure。I3.1
  状态为 `PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`。circle-action caveat
  已由上方 I3.2 same-trial application 继续诊断；它不阻止条件性定理。I3.3 只做 independent
  reference/effectivity；全部 outward/gap/existence flags 仍 false，另属 I3.4。详见
  [[research/projects/eig-apost/implementation/i3/review-3-1f|review-3-1f]]。

- **2026-08-24 I3.1 纯 BIE 边界残量 indicator candidate：**
  [[research/projects/eig-apost/implementation/i3/design-3-1e|design-3-1e]] 使用 shared wall
  Dirichlet traces、finite-density exact rectangular-Green trial、value-only circle collar 和
  full-$P$ boundary Grams，避免 Q1/RT0 体网格。`pbie-a1` 已完成 finite-density boundary
  action，但在记录第一个 warning 时因 fieldless struct schema 以
  `MATLAB:heterogeneousStrucAssignment` 停止；这是 implementation failure。Revision A 只统一
  typed warning schema，科学公式、参数与阈值不变。正式 `pbie-a2` 随后得到 residual triangle
  sum $2.4605912515933872\times10^{-10}$、field lower candidate $2.2269063318145634$、
  $q=1.1049370224693775\times10^{-10}$，以及名义 $k$ 区间
  $[1.8327702889056474,1.8327702893106665]$；宽度
  $4.0501912934587381\times10^{-10}$。三个 nonblocking warnings 是 wall $256\to512$ change
  $0.23020558465752644$、nonzero-mode $T$ oracle 最大误差 $1.4438757363102721$ 与 outside-$M$
  share $0.51468601513057144$。数学 exact-kernel/collar 对象已定义，但 512 点 continuity/$H^1$、
  residual/field/tail outward enclosure、projected gap 和全部 reliability flags 都未闭合。用时
  $117.91992858333333$ s，peak $242.98618412017822$ MiB，无 retry。独立 verdict 为
  `PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`；见
  [[research/projects/eig-apost/implementation/i3/review-3-1e|review-3-1e]]。这是已由上方
  `fbie-a1` 更新的历史 indicator；其名义区间仍不得解释成连续离散特征值存在性、唯一 mode、
  误差上界或按当时编号的旧 I3.2 independent reference。

- **2026-08-22 I3.1 BIE-collar 弱残量 V3 正式负结果：**
  [[research/projects/eig-apost/implementation/i3/design-3-1d|design-3-1d]] 已获 Researcher
  `AGREED` 和 Skeptic `DESIGN PASS`。选定路线从真实 one-cell BIE incoming data 构造
  安全 circle/wall collar、全局 conforming Q1 companion、RT0 functional majorant 和
  full-$P$ tail。首次 `bie-a1` 因旧 evaluator 接口仍读取字段 `kstar`，在 evaluator 和科学阶段
  之前以 `EXECUTION_UNAVAILABLE` 结束；append-only output 保留不改。Revision A 只由持久化
  `kseed` 为两次 `eval_i21` 调用创建局部兼容字段。第二次 `bie-a2` 已通过 safe-field evaluation，
  但因 MATLAB 不接受转置结果上的直接 `(:)` 索引而在 Q1 之前停止；这是实现语法失败，不是
  科学负结果。Revision B 只把四处该语法改为保持节点顺序的 `reshape`；只读 `checkcode` 与
  独立 spec-to-code 审查均通过后，正式 `bie-a3` 已运行。finite input、branch/Wood、propagation、
  BIE density、one-sided surface trace 和 safe-field evaluation 通过；程序随后在 coarse lead
  RT0-majorant 预因子处以 `HDIV_FLUX_UNRESOLVED` 停止。失败矩阵已经含 true-circle polar
  correction，且 integration-object gate 尚未先行检查，所以当前只可判定 composite
  quadrature/assembly 未资格化，不能归为 $H(\mathrm{div})$ 理论失败。RT0 flux、majorant、tail、
  indicator 和 prediction interval 均未形成。用时 $379.523247125$ s，peak active-object
  memory $89.6576280594$ MiB，无 retry。独立 verdict 为
  `POST-RUN PASS / VALID NEGATIVE / REVISE BEFORE CONTINUATION`；详见
  [[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]]。该 attempt 没有
  estimator；当前 I3.1 状态已由上方 `fbie-a1` 结果更新，按当时编号的旧 I3.2 当时不可开始。

- **2026-08-21 I3.1 Q1--RT0 弱残量正式负结果：**正式 `weak-a1` 固定
  $\widehat k_h=1.832770289108157$、$n_{\mathrm{tot}}=256$、$M=48$、两层 Q1 网格和全部
  phase/scale、tail、refinement 门。finite input、frozen-$P$ propagation、coarse/fine Q1--RT0、
  base Grams 与 full-$P$ tails 通过；fine phase/scale repeat 中 center 的 $A,B$ Gram 及左右
  first-cell 的 $A$ Gram 的
  Hermitian defect 超过 $10^{-12}$，最大为 $6.2442\times10^{-10}$，producer 因而停止于
  `MAJORANT_QUADRATURE_UNRESOLVED`。base coarse/fine computed $q$ 为约 $0.1792/0.1520$，但
  尚未通过完整资格链；$B/\gamma$ layer change 约 $0.277>0.20$，fine nominal width 约
  $0.564\gg10^{-6}$，只能作为后续负向诊断。运行用时 $22.5326065$ s，peak active-object
  memory $341.8422213$ MiB，无 retry；独立 verdict 为 `POST-RUN PASS / VALID NEGATIVE`。
  该 V2 路线的下一门为 scale-covariant Gram qualification，之后仍有 mesh/width blocker；尚无
  estimator，按当时编号的旧 I3.2 当时不可开始。详见
  [[research/projects/eig-apost/implementation/i3/review-3-1c|independent review]]。

- **2026-08-16 I3.1 lead-aware reconstruction 正式负结果：**冻结 `lead-a3` 固定
  $\widehat k_h=1.832770289108157$、$n_{\mathrm{tot}}=256$、$M=48$ 及全部设计参数。finite
  input、density representation 和 frozen-$Z$ propagation 均通过；但固定 BIE-informed fit 的
  holdout error 在 $J=4$ 为约 $4.522421$，在 $J=8$ 增至约 $5.138028$，高于预注册 $0.20$，
  producer 因而在 `CONFORMING_RECONSTRUCTION_UNRESOLVED` 首败处停止。center correction、
  field/residual/$H^2$ Grams、quadrature、infinite tail 和 strong-residual ratio 均为
  `NOT_REACHED`。training/holdout targets 距材料圆只有约 source-panel arc scale 的
  $0.86\%/1.08\%$，direct close layer-potential evaluation 未单独资格化，所以不能把失败单因
  归咎于 bubble basis 或 fit metric。`lead-a3` 用时 $373.254082$ s，peak active-object memory
  $62.706804$ MiB，无 retry；独立 verdict 为 `PASS WITH CONDITIONS / VALID NEGATIVE`。I3.1
  继续活动，但尚无 estimator，按当时编号的旧 I3.2 当时不可开始，也不自动授权新 attempt。详见
  [[research/projects/eig-apost/implementation/i3/review-3-1b|independent review]]。

- **2026-08-15 I3.1 中心空列强残量 baseline：**第一层目标仍是 saved candidate 到当前
  continuous projected gap 内正离散特征频率集合的距离；只有后续必须跟踪特定 mode 时才升级
  为 $|k_*-\widehat k_h|$。finite one-step projected-root correction 即使代数成立，也只预测
  finite/projected root 位移，现已降为 OPTIONAL 内部诊断。首个 `center-a1` 在 saved candidate
  处构造了属于 continuous strong-operator domain 的中心空列紧支撑场，得到场范数
  $0.840017038309255$、强残量范数 $18.848991951433035$ 和 computed ratio
  $22.43882099031153$。积分加密稳定，但固定单胞 cutoff 导数项主导，名义区间跨过零；正式
  当前解释为 `FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`，因此它不能冻结为旧 I3.2
  empirical estimator。普通积分尚非可靠 enclosure，sharp-disk projected-gap contract 也未建立，
  故没有现行 I3.4 连续离散特征值存在性或上界结论；这两项不是现行 I3.3 经验验证的前置条件。
  后续全波导 BIE-informed
  Fourier--Hermite/bubble trial 已于 2026-08-16 正式运行并在
  reconstruction fit 首败；见上一条。continuous weak residual 保留为后备。

- **2026-08-14 I2.3 Rayleigh/Fourier cutoff 单轴：**正式 `m-drift-a2` 固定
  $n_{\mathrm{tot}}=160$，只改变 $M=32,40,48$ 及其派生维数；物理参数、fine proxy、搜索区间、
  五点 dyadic 规则、$L=0,\ldots,11$、candidate functional、solver 和 winner 规则保持不变。
  三层 saved candidate 均为 $1.832770289108157$，全部直接 candidate drift 为零，相邻 mode
  identity 均为 `SAME_MODE`；gauge、repeat、raw residual、factor、field 和 boundary 门均通过。
  状态为 `PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE /`
  `CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY`。terminal half-width
  $9.3132\times10^{-11}$ 只作 sub-grid minimizer 搜索尺度。`m-drift-a1` 曾在 evaluator 前因
  MATLAB struct schema 错误失败，用时约 $22.18$ s、零 evaluator、无 output；Revision A 后
  a2 无 retry，用时 $171.956$ s，active-object snapshot peak $148.171$ MiB。I2.1 count 不附着
  这三个固定-$n_{\mathrm{tot}}$ level；零 observed shift 也不证明 minimizer/root 收敛或误差界。
- **2026-08-14 I2.3 跨离散阶数 candidate 漂移：**唯一 `drift-a1` 只改变边界 Nyström
  阶数 $n_{\mathrm{tot}}=160,208,256$；$M=48$、proxy、物理参数、搜索圆盘、candidate
  functional、locator、solver 与 mode-identity 规则均固定。三层候选均为
  $\widehat k_n=1.832770289108157$，相邻与端到端
  $\Delta^{\mathrm{cand}}=0$。三层最低 residual、factor、field、boundary、repeat 门均通过，
  相邻层 mode identity 均为 `SAME_MODE`。正式当前状态为
  `I2_3_PASS_WITH_CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。
  terminal interval 半宽 $u_n=9.3132\times10^{-11}$ 只作潜在 sub-grid score minimizer 的
  search-resolution diagnostic，不是 saved candidate uncertainty，也不参与 candidate drift。
  MATLAB 用时 $294.984424$ s，active-object snapshot peak $163.769340$ MiB，无失败或 retry。
  冻结 artifact 中原 `DRIFT_UNRESOLVED / I3 STOP` machine fields 保持不变，但当前 I3 可开始
  误差来源与 independent-reference 设计；仍不得声称 minimizer/root 零漂移或收敛。
- **2026-08-13 candidate--error 总路线复审：**项目只保留两个最终目标：提出连续物理问题的
  数值 eigenvalue candidate；估计该 candidate 到真实连续特征值的误差，并研究可计算上界。
  底层 global physical operator 的自伴、正谱和适定条件下 exact-DtN 等价说明目标正频率
  $k$ 位于实轴；这支持实轴优先，但不把任一 finite determinant zero 证明为精确实数。I2.2
  当前只复用 I1.3 已确定的端点，检查一致定义的 endpoint sign count 是否出现稳定的
  inertia-like jump，并同时报告 structure defect、unresolved band 与 jump/no-jump。它不重做
  scan，不运行 locator，也不把 exact finite Hermitian 或 finite-real-zero 身份设为阶段目标。
  I2.3 已在预先冻结的不同离散阶数上比较同一物理 mode 的 saved candidate，并报告
  terminal-cell/minimizer-localization diagnostic 与最低 residual/factor/field/boundary/
  mode-identity 检查；首个结果为 `NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`，不设置 I2.4。
  I3 可按 `candidate -> error sources -> computable estimate -> independent truth -> upper bound`
  开始设计。exact finite structure、额外 contour、复数 refinement 以及未被 estimator 使用的
  derivative/adjoint/transport 均为 OPTIONAL。
- **2026-08-13 I2.2 Hermitian-part endpoint sign count：**唯一 `inertia-a1` 在冻结 fine、
  $M=48$ evaluator 的 I1.3 L14 nodes 3/5 上完成。raw $H=A_{\mathrm{def}}^D/T$ 到
  $H_{\mathrm{sym}}=(H+H^*)/2$ 的相对 $2$-norm distance 为
  $1.39\times10^{-16}$ 与 $1.60\times10^{-16}$。以预注册绝对 band 分类，左端 counts 为
  $(194,0,0)$，右端为 $(193,1,0)$，故 $\Delta_-=+1$、`JUMP / SINGLE_JUMP`；$50/100/200$
  sensitivity 完全稳定，且两端最小绝对 eigenvalue 分别约为主 band 的 $316$ 与 $595$ 倍。
  MATLAB 用时 $20.0001$ s，active-object snapshot peak $63.4584$ MiB，无失败或 retry。
  该结果只为 candidate 提供 Hermitian-part numerical corroboration；raw-$H$ inertia 仍
  unavailable，不证明区间内 crossing、严格实根、continuous eigenvalue 或误差估计。I2.2
  据此完成；后续 I2.3 的实际结果见本节首条。
- **2026-08-13 I2.2 实轴结构资格：**阶段 verdict 为
  `PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE`。I2.1 的对称小圆盘内 count one
  若再结合冻结有限维零集的实轴 Schwarz 对称，便会迫使唯一 zero 位于实轴；但 continuous
  self-adjointness、I1/I2 unit-circle QZ gap 和 smooth Fliss Track A gap 都不能单独关闭这条
  离散结构链。当前最低成本候选是在 $T$ 可逆实点与原矩阵奇异等价、右核可逆搬运的
  Dirichlet-coordinate mismatch $H=A_{\mathrm{def}}^DT^{-1}$。当前已证明 $A$--$H$ 点态奇异
  等价、$T$ 在冻结 nearest-shoulder interval 上可逆和 empty-center block Hermitian；实际
  MFS/collocation/QZ half-guide graph 的 exact Lagrangian/Hermitian identity 未闭合。因此
  Revision A 两端点 structure diagnostic 已实际完成：两端 $T$ 的 `rcond` 均为 $0.5$，
  $\sigma_{\min}(T)\approx0.9958518$，$A=N_0-LT$ 与 $A=HT$ defects 为
  $10^{-21}$--$10^{-19}$，raw $H$/graph/DtN structure defects 为 $10^{-16}$ 量级。后者只作
  implementation diagnostic；两个 proof flags 仍为 false，因此 inertia 为 unavailable/NaN，
  endpoint separation/jump 均 `NOT_REACHED`，没有运行 locator 或复扫描。详见
  [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]] 与
  [[research/projects/eig-apost/implementation/i2/review-2-2|independent review]]。
- **2026-08-13 新路线 I2.1 同一离散对象单根隔离：**
  `test/i2/k-count/` 在冻结 fine、$M=48$、$K=97$ 的未平衡
  $194\times194$ $A_{\mathrm{def}}^D(k)$ 上完成 Method 1B factor-aware count。指定圆盘中心为
  $k_c=1.8327703475952146$，半径为 $3.8146972647368216\times10^{-7}$。proxy reduced、
  BIE $A_{QP}$、64 个 original/reversed resolvents、4 个 fixed-section $C$ 和 2 个
  $\widehat D$ factors 的 32/64 winding 均为 zero；主矩阵 raw count 为 $1$ 与
  $0.99999999999999967$。26 个正式 gates 全部通过，Skeptic、Engineer 和 Researcher
  均给出 `PASS WITH CONDITIONS`，I2.1 blocker 为 0。full 用时 $412.089480375$ s，峰值
  $197.61942958831787$ MiB；含启动失败和两次 smoke 的累计正式预算为
  $450.64840354166665/7200$ s。结论只是在 sampled analytic/fixed-chart 经验资格下，圆盘内
  有一个按代数重数计的 finite-dimensional determinant zero；尚未定位 root、验证非零场、
  导数单根、continuous physical eigenvalue 或 estimator。I2.2 已完成最低实轴结构诊断但
  未关闭 exact-Hermitian 门；该门只封闭 strict inertia theorem。下一门是只在既有端点检查
  一致定义的 sign-count/inertia-like jump，作为 candidate 可信度诊断；不能自动启动 locator、
  complex solve 或重做宽扫描。
- **2026-08-12 新路线 I1.4 sampled complex-$k$ readiness：**
  `test/i1/k-ready/` 围绕 $k_*=1.8327703475952146$、
  $r_0=3.8146972647368216\times10^{-7}$ 运行固定 $M=48$、固定 frame/chart/rank 的
  anchored complex-$k$ 验证。V4 的 82 node、820 factor、164 branch、164 QZ、8 closure、
  36 CR 和 6 CR-negative rows 全通过；QZ 始终为 97/97/0/0，最小 overlap 为
  $0.9999999999999398$，最大 CR defect 为 $5.80\times10^{-7}<10^{-6}$。V4 唯一
  ordinary-negative failure 是对称物理模型中不可辨识的 `transmission_swap`，其 verdict
  保持失败。V5 锁定并导入 V4 positive evidence，以非对称 $K=3$ assembly oracle 得到
  identifiability $0.212904$、formula error $0$、swap change $0.129922$，最终组合 verdict 为
  `I1_4_PASS_WITH_CONDITIONS / SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS`。本轮 locator、
  contour、root 和 estimator 调用均为 0；结果只允许下一阶段另行预注册经验型 I2
  isolation，不是 root 或 eigenvalue。
- **2026-08-12 width-driven zoom v2：** `test/i1/k-scan/output/zoom2/` 在不改变
  homogeneous missing-column 模型、$M=48$ trace 带宽和 coarse/fine 空间层的条件下，完成
  15 个区间层与 33 个唯一 $k$ 点。167 个 hard gates 全部通过，最终已评估区间宽度为
  $7.6293945294736432\times10^{-7}<10^{-6}$；coarse/fine 最小位置在全部层无漂移，最终
  候选为 $k=1.8327703475952146$，物理 $s_1$ 分别为
  $8.32008721372168\times10^{-8}$ 与 $8.3200886232193094\times10^{-8}$，物理
  $\sigma_1$ 约为 $1.11983\times10^{-8}$。QZ 的
  stable/unstable/neutral/indeterminate 计数始终为 97/97/0/0，regular-infinite count
  为 87--88；最小 transport overlap 为 $0.9999959813$。最终三个 $q$ 值的相对变化为
  $0.4691$ 与 $0.5582$，故不是
  $10^{-3}$ 平台。verdict 为 `I1_3_PASS_WITH_CONDITIONS /
  M48_DISCRETE_NESTED_GRID_CANDIDATE`；这不是 locator root 或 eigenvalue。
- **2026-08-12 historical zoom v1 stop：** `test/i1/k-scan/output/zoom/` 的第一级保持
  $k=1.83125$、$s_1=2.1640756292144498\times10^{-3}$。strict-interior minimum、
  coarse/fine minimum drift、左右奇异向量 overlap、raw/physical index、
  $\sigma_1/\sigma_2=0.0042345678386558434$、QZ、chart、branch 和 neighbor transport
  全部通过；唯一失败项是 immediate-neighbor prominence
  $1.0556203927304477<1.25$。本轮状态为 `STOP / DESIGN-GATE-INCONCLUSIVE`，权威报告是
  `test/i1/k-scan/output/zoom/report.md`。该失败是 shrinking-grid 局部 prominence 门的
  实验设计 blocker，不否定宽扫候选、matrix/QZ/chart，也不是 $10^{-3}$ plateau 证据；
  现有两层数据不能判断后续是否会达到 $10^{-5}$ 以下。该 verdict 不追溯改写；其
  shrinking-prominence 设计 blocker 已由独立 v2 关闭。
- **2026-08-12 新路线 I1.3 update：** `test/i1/k-scan/` 在保持 sharp-disk periodic leads
  与 homogeneous missing center column 不变的前提下，完成 MATLAB real-$k$ continuity 和
  $M=12\to24\to48$ 分层筛查。$M=48$ continuity 的 stable/unstable 始终为 97/97，
  neutral/indeterminate 始终为 0/0，最小相邻 subspace overlap 为 $0.999958$。
  最终记录离散实轴候选 $k=1.83125$，其 $s_1=2.164\times10^{-3}$、prominence
  $=3.112$、$\sigma_1/\sigma_2=4.235\times10^{-3}$；coarse/fine 最小左右奇异方向约为 1，
  raw/physical 最低点一致。该点不是 locator root 或 eigenvalue。中心差分绝对收敛门通过，
  但 graph-basis FD mutation 为 $3.65\times10^{-11}>10^{-12}$，故
  `FD_DERIVATIVE_READY=false`。阶段 verdict 为
  `I1_3_PASS_WITH_CONDITIONS / M48_DISCRETE_REAL_AXIS_CANDIDATE_RECORDED`。随后 v2 zoom
  把候选局部加密至 $k=1.8327703475952146$；后续 I1.4 sampled readiness 已条件通过，
  但 derivative-based Newton、root/eigenvalue 和 estimator 仍未开始或授权。
- **2026-08-11 新路线 I1.2 direct-$M=48$ update：** `test/i1/hg-adef/` 保留已通过的
  manufactured 与 $M=5,8$ low-order mechanism oracle，并用 MATLAB `lsqminnorm` 直接生成
  $M=48$、$K=97$ coarse/fine one-cell maps。block absolute/action、full-pencil、
  original/reversed ordered-QZ、stable/Cauchy projector、代数 Dirichlet chart、DtN action
  和 $A_{\mathrm{def}}^{D/G}$ Schur 门全部通过。四个 QZ pass 均为 97 stable / 97 unstable、
  0 neutral / 0 indeterminate；最大 QZ residual、projector change、DtN action change 和
  Schur error 分别为 $5.25\times10^{-15}$、$7.06\times10^{-15}$、
  $6.52\times10^{-16}$ 和 $4.30\times10^{-16}$。权威状态为
  `I1_2_M48_PASS_WITH_CONDITIONS`。本轮未形成或施加 generalized-Sylvester separation
  operator；`production_separation=NOT_EVALUATED_CAVEAT`，chart 只称代数上条件良好。
  经验型 I1.3 参数连续性、$A_{\mathrm{def}}'$ 开发和 candidate reconnaissance 已获授权；
  locator 结论、contour、root isolation、真实 eigenvalue 和 estimator 声明仍未授权。
- 当前连续主路线为
  `exact half-guide PDE -> continuous DtN -> continuous center BIE--DtN operator
  \(\mathcal F(k)\) -> BIE/Fourier one-cell pencil -> ordered-QZ stable graph ->
  discrete DtN/augmented graph -> matrix representation`。真实 guided eigenvalue 由
  $\ker\mathcal F(k)\ne\{0\}$ 定义；QZ 只计算离散 stable deflating subspace。
- 旧的“有限多个 cells + 远端闭合 + doubling”方法完整归档为
  [[research/projects/eig-apost/phase4-report/legacy-tail.tex|superseded finite-tail formulation]]，
  以后只作 cross-check、reference sequence 或 tail diagnostic，不定义主问题或主 estimator。
- 现行理论稿为
  [[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]]；
  该稿现已加入 original/reversed 双 QZ pass、projective infinite-pair policy、双向
  Sylvester separation、absolute chart-margin gates，以及当前 empty-center 的
  $2K\times2K$ safe-DtN 和 $4K\times4K$ full-graph 公式。设计与审查见
  [[research/projects/eig-apost/implementation/i1/design|I1 discrete design]] 和
  [[research/projects/eig-apost/implementation/i1/review|I1 design review]]。
  two-level projected difference 在没有独立 saturation/remainder 前只称
  next-level correction，不称 remaining-error estimator。
- 本次权威变化记录于
  [[research/projects/eig-apost/DECISIONS|2026-08-11 decision record]]；Phase 1--2 历史
  文件保持原文。
- 工作流：Academic Research Suite / Deep Research，现处于受审查的理论方法重构阶段。
- 论文定位：以可运行、可复现、具有代表性真实案例的 empirical estimator 为当前目标；
  theorem-level certification 是更强的未来方向，不作为默认阶段门。
- 阶段：Phase 1--3 已完成范围、来源、novelty 和历史理论方案；旧 Phase 4 finite-tail
  方法稿已 supersede，当前 Phase 4 为连续 DtN/BIE 方法重构。此前已完成三个
  Octave implementation checkpoints：manufactured NEP、Half-guide map 和
  Augmented BIE / center coupling。Root-readiness 的第一轮 early-stop diagnostic
  保留为历史负结果，后续 source-derived proxy provenance-closure 已完成并通过独立审查。
  I4 首轮双椭圆 full analytic complex-$k$ baseline/repeat 在 locator 处得到可复现的
  `NO_SCREENED_DIP`，现保留为历史负例。当前主模型已改为相同周期端与 Fliss
  missing-column geometry；新的 exact-profile FD track 找到可信 projected-gap 候选，
  sharp-disk BIE track 已完成 21 点 Rayleigh-budget screening：旧 transmission-rank/
  affine blocker 被 projective ordered-QZ/doubling core 取代。最新三路径诊断先用真 Ewald
  real/reciprocal decomposition 复现 Linton Tables 2--5 的五个函数值，再对同一冻结圆周
  密度比较 Ewald full kernel、package MFS 和 Rayleigh extractor。Ewald--Rayleigh 的
  single-layer Dirichlet 系数在当前正间距、实数非 Wood 参数上闭合到
  $6.10\times10^{-16}$。新的 MATLAB derivative qualification 继续使用根目录
  `Faddeeva_erfc.mexmaca64`，Linton 五点最大误差为 $5.07\times10^{-11}$；解析 Ewald
  gradient/Hessian 通过 value-only Richardson、Rayleigh derivative、Helmholtz、mixed
  derivative、source/target sign 及 Ewald 单轴加密。package `lsqminnorm` 的五个项目函数值
  最大误差降到 $5.14\times10^{-10}$，但负横向分离 hold-out 的三个 Hessian 分量仍为
  $1.46\times10^{-8}$--$1.60\times10^{-8}$。将过强的全六分量门修正为
  action-specific dependencies 后，历史 $p/d=0.7$ run 的 full SLP--D 通过，而 SLP--N
  出现 $10^{-8}$ 级 proxy self failure。Researcher 随后识别出该 source curve 越过最近
  周期镜像奇点；新 `test/archive/legacy-route-v1/i4-proxy-rule/` 只预注册 $p/d=0.2$，固定 MATLAB
  `lsqminnorm`、原科学门与四个单轴 refinement。最终 canonical 中 SLP--N 的
  E--P/P--R 最大误差为 $3.42\times10^{-14}$/$3.47\times10^{-14}$，四轴 self 最大为
  $1.61\times10^{-13}$；共同配置下 SLP--D 也通过。因此 OP-I4-1f 已关闭。随后新的
  `test/archive/legacy-route-v1/i4-dlp-trace/` 严格按 DLP--D、DLP--N、$M_{\mathrm{trace}}$ 顺序运行：DLP--D 与
  DLP--N 的三路径最大 coefficient 误差分别为 $1.39\times10^{-14}$ 与
  $1.19\times10^{-13}$，四轴 wall self 最坏为 $1.40\times10^{-13}$；独立半网格重构
  将 $M_{\mathrm{trace}}=48$ 的最坏误差和 omitted energy 分别压到
  $7.08\times10^{-12}$ 与 $5.00\times10^{-13}$。OP-I4-1h 与 OP-I4-6 因而在当前制造
  密度、实数非 Wood 参数和有限 $M_{\mathrm{ref}}=96$ 意义下关闭。
- 状态：`active investigation -- I3.1 preliminary objective achieved; I3.2 theorem established / empirical cap unresolved`。
  `ntot` 与 $M$ 两条三层单轴实验的 saved candidate 均完全相同且 `SAME_MODE`；I3.1 已开始
  saved-candidate continuous residual 研究。中心空列 strong-residual baseline 已完成，但 ratio
  $22.43882099031153$ 由固定单胞 cutoff 主导，分辨率不足；全波导 BIE-informed smooth
  trial 又在 fixed holdout fit 首败；Q1--RT0 V2 随后在 fine phase/scale Gram qualification
  首败；BIE-collar V3 再在 coarse lead composite RT0-majorant assembly 首败。纯 BIE
  `pbie-a2` 先形成 finite indicator；全边界 `fbie-a1` 又关闭旧 wall/$T$/outside-$M$ 问题，但
  circle-action refinement ratio $0.7741$ 仍使 ordinary candidate 未获内部资格。I3.2
  条件性证书定理不以该诊断为前置；同一阶段的 `ecap-a2` 已完成 same-trial evaluation，但因
  $664.470682>640$ MiB 资源门使本次 empirical cap 未计算。三项 fail-open evaluation
  qualification failures 按冻结 component gates 也会使 cap unresolved；I3.3 只负责
  independent reference/effectivity。
  reliability/enclosure flags、current-model projected gap 与 absolute/gap-relative resolution
  则是 I3.4 相应存在性和上界结论的门。第一层不要求唯一 mode。该状态不表示 sub-grid
  minimizer、finite root 或连续真值零漂移，也不构成收敛证据。
- 历史阶段门（均不构成当前实现授权）：manufactured root/correction pipeline 曾为窄范围
  `GO`，finite-tail Half-guide map 曾为 Stage 1 `GO`，Augmented BIE 曾为
  `STAGE2_DISCRETE_ALGEBRA_GO`；provenance-closure 曾为
  `PASS WITH CONDITIONS`，其 operational label 为
  `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`。历史 I4 numerical verdict 为
  `PARTIAL SUCCESS -- I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / EWALD_DERIVATIVE_REFERENCE_CERTIFIED /
  SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 / DLP_D_N_MTRACE48_CERTIFIED`；这些标签现只作为
  已完成的离散数值证据保留，不构成继续实现的授权。OP-I4-1e 中旧矩阵的授权已被方法重构
  决定撤销并由新路线 I1 设计取代；direct $M=48$ static $A_{\mathrm{def}}$ 与分层 real-axis
  candidate screen、sampled complex-disk readiness 与 I2.1 factor-aware count 已通过经验门；
  当前只有圆盘内一个按代数重数计的 finite-dimensional zero，尚无 root 坐标或 physical
  eigenvalue。新的 $A_{\mathrm{def}}^{D/G}$ 现有
  $M=5,8$ low-order、$M=48$ actual static oracle 和离散候选
  $k=1.8327703475952146$，但尚无 production separation 或 analytic derivative。现有证据支持 exact-profile finite-strip
  candidate 与 sharp-disk BIE 离散候选，但不支持 qualified BIE root、
  连续 kernel--field equivalence、unconditional effectivity 或 certified interval。

## 实现 checkpoint

| Checkpoint | 结果 | 已验证 | 明确未验证 |
|---|---|---|---|
| Manufactured NEP | `GO`; `conditional/empirical` | 固定维数 contour count、bordered Newton、root qualification、projected correction 和四个负例；末级 tail effectivity 为 `0.999987793` | BIE/DtN、branch cut、pole、representation kernel、common discretization error |
| Legacy finite-tail Half-guide map | Stage 1 historical `GO` | 非交换 Redheffer/terminal/Cayley 次序、exact analytic cell、固定 $k=0.10$ 的中心圆形介质夹杂单胞（旧报告称 `EDC cell`）same-cell QZ/doubling smoke 和负例传播；Case B 最终误差 $1.93\times10^{-15}$ | 只作 discrete infinity-treatment cross-check；不定义连续 DtN，缺独立 PDE truth、operator convergence 与 $C^1$ error control |
| Augmented BIE | `STAGE2_DISCRETE_ALGEBRA_GO`; `ROOT_READY=STOP` | 固定九块 $(n+8p)$ assembly、scaled density coordinate、raw/reduced Schur agreement、七级 availability 与 failure ledger；unchanged-source 复现差为 $0$ | 连续表示单射性、kernel--field equivalence、pole-free analytic neighborhood、root/eigenvalue/estimator |
| Root-readiness proxy diagnostic and provenance closure | `PASS WITH CONDITIONS`; historical `GO` to full analytic complex-$k$ Root-readiness, revoked 2026-08-11; `PHYSICAL_ROOT_READY=STOP` | 历史受控诊断的 $10^{-5}$ object gate 通过；新 source-exact copy 在 6 个 shared systems/30 个 solver rows 上使三个原 $10^{-11}$ output gates 以 0 误差通过；双跑数值差为 0，manifest/shared/projector fingerprints 一致 | production 内部 $A_{\mathrm{pr}},b_{\mathrm{pr}}$ 仍不可直接观测；off-collocation 与 historical projectors 非门控；未运行 complex disk、CR、root、Newton、eigenvalue 或 estimator |
| Historical double-ellipse full analytic complex-$k$ Root-readiness | evidence `PASS WITH CONDITIONS`; scientific `REPRODUCIBLE STOP / NO_SCREENED_DIP` | 29/29 locator 点 available；$s(k)$ 从 $0.2083091449$ 严格降至 $s(0.18)=0.03539366850$；baseline/repeat 全表数值差为 0 | 已被新主模型取代；没有 interior dip 或 seed，chart/disk/factor/full-$F$ CR 未运行 |
| Revised I4 Fliss missing-column benchmark, Rayleigh budget and three-path kernel audit | `PARTIAL SUCCESS`; `I4_FD_CANDIDATE_READY`; `BIE_RAYLEIGH_BUDGET_SCREENED`; `EWALD_VALUE_REFERENCE_CERTIFIED`; `EWALD_DERIVATIVE_REFERENCE_CERTIFIED`; `SLP_D_N_CERTIFIED_PROXY_RATIO_0P2`; `DLP_D_N_MTRACE48_CERTIFIED`; `PHYSICAL_ROOT_READY=STOP` | exact smooth profile 的 N80 strip 候选 $\lambda_h=3.460975044$；sharp-disk candidate windows 为 $[5,20]$、$[19,20]$；MATLAB 真 Ewald value/gradient/Hessian reference 通过；共同 $p/d=0.2$ 的四个 SLP/DLP wall actions 在 Ewald/MFS/Rayleigh 三路径上通过。DLP--D/DLP--N 最大 coefficient 误差为 $1.39\times10^{-14}$/$1.19\times10^{-13}$，DLP 四轴 self 最坏为 $1.40\times10^{-13}$，半网格有限带测试认证当前 $M_{\mathrm{trace}}=48$ | 认证只覆盖当前几何、实数非 Wood 点、两制造密度与有限 $M_{\mathrm{ref}}=96$；没有完成额外 $n_{\mathrm{tot}}/N_y$/Ewald wall ladder。package proxy 列表有一个重复角点，rank/edge-tail 仅为诊断。balanced $A_{\mathrm{def}}$/scanner、locator、root 与 estimator 未认证 |
| Current I1.2 half-guide to $A_{\mathrm{def}}$ joint validation | `I1_2_M48_PASS_WITH_CONDITIONS`; `I1_2_EMPIRICAL_READY`; empirical I1.3 authorized | manufactured assembly；$M=5,8$ exact-small-sep mechanism；direct $M=48$ MATLAB `lsqminnorm` maps；双向 QZ 97/97 计数、projectors、代数 chart、DtN action 与 $A_{\mathrm{def}}^{D/G}$ Schur 门 | production separation 未计算，chart 不是 perturbation-certified；$A_{\mathrm{def}}'$ 尚未实现。locator、contour、root/eigenvalue 和 estimator 继续停止 |
| Current I1.3 real-$k$ continuity, candidate reconnaissance and bounded zoom | `I1_3_PASS_WITH_CONDITIONS / M48_DISCRETE_NESTED_GRID_CANDIDATE` | $M=48$ count/QZ/chart/subspace-coarse/fine continuity；中心差分二阶收敛；$M=12\to24\to48$ 分层筛查；v2 在 15 层、33 点、167 门全通过后得到 $k=1.8327703475952146$、$q=8.32009\times10^{-8}$，最终宽度 $7.6294\times10^{-7}$ | 固定 $M=48$ 不是 trace convergence；FD mutation 未过 $10^{-12}$，production derivative 不可用 |
| Current I1.4 sampled complex-$k$ readiness | `I1_4_PASS_WITH_CONDITIONS / SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS`; empirical I2 isolation ready | $r_0=3.8147\times10^{-7}$ disk；anchored branch/frame/chart/rank；82/820/164/164 node/factor/branch/QZ rows、8 closure、36 CR、6 CR-negative rows；V5 identifiable assembly-order closure | 未运行 locator/contour/root；固定 $M=48$ 不是 trace convergence；无 production separation、unsampled-pole theorem 或 $A_{\mathrm{def}}'$；对称 physical transmission labels 不可动态辨识 |
| Current I2.1 factor-aware root count / I2.2 endpoint sign count | I2.1 `PASS WITH CONDITIONS`; I2.2 `PASS WITH CONDITIONS / HERMITIAN_PART_SINGLE_JUMP` | I2.1 32/64 主 winding 均为 one；I2.2 的 raw $H$ strict-inertia 路线保留历史 STOP，但当前 $H_{\mathrm{sym}}$ 两端 counts 为 $(194,0,0)$ 与 $(193,1,0)$，$50/100/200$ bands 稳定 | 该 difference 只作 numerical corroboration；raw-$H$ inertia 仍 unavailable，尚无实根、root 坐标、连续 eigenvalue 或 estimator |
| Current I2.3 cross-discretization drift | `PASS WITH CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE` | `ntot=160,208,256` 与固定 $n_{\mathrm{tot}}=160$ 的 $M=32,40,48$ 两条单轴实验均返回完全相同的三层 saved candidate；最低 raw diagnostics、gauge/repeat 与相邻 `SAME_MODE` 门通过 | terminal half-width 只作 sub-grid minimizer 搜索分辨率；不证明 minimizer/root 零漂移、收敛或误差界。I3.1 已达成 preliminary objective，I3.2 条件性定理已建立，但尚无 reliable enclosure |

实现权威入口为
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i0-manufactured/design|manufactured NEP design]]、
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i1-finite-tail/half_guide_map|Half-guide map design]] 和
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i2-aug-bie/aug-bie|Augmented BIE design]]；相应独立审查为
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i0-manufactured/nep-review|manufactured NEP review]]、
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i1-finite-tail/half_guide_review|Half-guide review]]、
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i2-aug-bie/aug-bie-review|Augmented BIE review]] 和
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i3-provenance/root_readiness_review|Root-readiness review]]；
本轮数值解释见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i3-provenance/root_result|I3 Root-readiness result]]、
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-result|I4 result]] 和
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-review|I4 review]]；当前替换 benchmark 见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-fliss|I4 Fliss benchmark]]，最新 BIE port
预算见 [[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-rayleigh|I4 Rayleigh budget]]，谱提取与
proxy-solver 收敛诊断见
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/i4-numerical-qualification/i4-extract|I4 spectral extraction closure]]。

## 已完成

- 读取仓库与 `research/` 的协作、权威和命名规则。
- 确认当前没有活动中的 `research/mainline/`，冻结主线不支配本专题。
- 对与特征值、Bloch 模态、奇异值扫描、收敛测试和 Green 函数基准有关的代码、
  草稿、结果文件和本地文献索引完成入口级盘点。
- 建立 Phase 1 专题目录、材料清单和首轮收敛问题。
- 用户已确认单句 RQ、首阶段范围、estimator 目标和 reference-truth 层级；已生成
  `phase1-scope/rq-summary.md`。
- Methodology Reflection、Checkpoint 1 和用户修订已完成；`phase1-scope/p-method.md`
  允许 Phase 2 调查，但在 DtN definition/construction 明确前不冻结实验实现。
- 已从 Fliss 原文独立澄清 half-guide DtN：先解半波导 Dirichlet problem，再取有符号
  Neumann trace；Riccati 是构造而非定义。
- 已核验 Joly、Fliss、Coatléven 的数值链均由 FEM/mixed FEM 生成 cell DtN blocks。
- 已核验三类 BIE--DtN 机制：Calderón operator quotient、special-solution trace
  quotient，以及 BIE unit-cell RtR + half-array Riccati。
- 已找到 line-defect PCW DtN 文献数据和 Petropoulos--Turc (2025) 的 BIE/Riccati
  近邻验证架构。
- 已核验 Güttel--Tisseur 的 matrix-level simple-root sensitivity、Moskow 的
  operator-level nonlinear eigenvalue correction，以及 two-level difference 必须另加
  saturation/tail assumption 才能代表剩余误差。
- 已把当前需要的公开全文统一保存并核验于 `ref/ref_data/`；临时渲染仍留在
  `research/tmp/`。
- 历史 Phase 3 曾选定首版 finite-tail hierarchy：固定 BIE/cell scattering 离散，只令
  cell count $N=2^j$ 增长。2026-08-11 起该选择已被 supersede，只保留为 cross-check、
  reference sequence 或 tail diagnostic，不再称精确 DtN hierarchy。
- 已建立 Phase 3 目录并写入 DtN 数据链、分层误差预算、projected correction、
  effectivity criteria、双椭圆 benchmark 和未来实现路线。
- 已按当前 port convention 推导左右 finite-tail DtN 的法向符号，并用独立随机复矩阵
  直接消元核对两段 scattering 组合公式；随后已在 Half-guide Stage 1 用现有 one-cell
  BIE/scattering 接口完成固定参数的 Octave smoke 核对。
- 已明确区分实轴 $\sigma_{\min}$ 极小点、离散 NEP 实际零点和精确 guided eigenvalue；
  root qualification 失败时不得报告 eigenvalue estimator。
- 已把 $\eta_j=\lvert \delta_j^{\mathrm{map}} \rvert$ 设为 doubling hierarchy 的 primary
  candidate，并把
  “effectivity 趋近 1”列为需要证明/反驳的核心发表命题，而非当前结论。
- 已建立 `phase2b-novelty/`，冻结 C1--C6 claim decomposition、检索边界、证据等级和
  `PASS / PASS WITH CONDITIONS / REVISE / STOP` 判据。
- 首轮检索已核验 Li--Lu (2007)、Yu--Hu--Lu--Rathsfeld (2022) 和
  Gopalakrishnan et al. (2025) 的公开全文，并把所需 PDF 保存到 `ref/ref_data/`。
- 首轮结果已经排除宽泛的“首个 photonic-crystal/line-defect eigenvalue estimator”
  表述，并形成待全文闭合的近邻清单；后续闭合结果列于下两项。
- 已补齐并全文核验 Giani (2013)、Engström--Giani--Grubišić (2016)、
  Boureghda--Choutri--Rezgui (2022)、Choutri (2008)、Xi--Gong--Sun (2024)、Lin--Lv
  (2025) 和 Klindworth (2015)，并按 `ref/ref_data/` 规则同步更新索引与 BibTeX。
- 已完成 backward/forward citation chasing、2024--2026 更新检索、C1--C6 claim matrix
  和 devil's-advocate checkpoint；正式 novelty verdict 为 `PASS WITH CONDITIONS`。
- 已确认 C1、C2 和 C3 的问题设置与计算部件已有直接先例；候选核心只能是 C4--C5：
  numerical half-guide DtN error 到 fixed-$\beta$ guided eigenvalue shift 的 computable
  estimator 及 simple-root effectivity。
- 已全文核验 Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al. (2000)，按规则登记为
  `ref/ref_data/Bonnet1995.pdf` 和 `ref/ref_data/Djellouli2000.pdf`。前者直接证明 exact Fourier boundary
  operator 截断下的 guided eigenvalue 先验收敛，后者给出 local boundary + FEM 和
  independent-reference comparison；两者进一步阻断宽泛 C4，但不覆盖 computable
  posterior half-guide DtN $k$-shift estimator 或 simple-root effectivity。
- 已在 `phase2b-novelty/r-gate.md` 中补充 C1--C6 的操作性定义，区分连续真根 $k_*$、
  固定 BIE/port 离散的极限根 $k_{\infty,h}$ 与 finite-tail 根 $k_{j,h}$，并解释
  projected correction、effectivity index 与 asymptotically exact estimator。
- 已按 ARS deep-research Phase 3 continuation 完成一轮 researcher/skeptic 并行调查与
  交叉复核；skeptic 充当 falsification-oriented human challenger。
- 已核验 Güttel--Tisseur 的 simple-root perturbation、bordered implicit determinant、
  Beyn contour method 与 argument-principle root count；Fliss 的 half-guide DtN/Riccati
  定义与 convergence statements 已定位到原文。Ehrhardt 的 finite scattering/doubling
  只作为数值先例，不作为当前二维 BIE convergence theorem。
- 已把 root 搜索具体化为固定公共表示的 augmented finite-tail NEP：实轴 scan 只定位，
  anchored analytic Rayleigh chart 保证局部解析性，小型 pole-free contour 隔离一个
  complex root，bordered implicit determinant Newton 完成 refinement。
- 已识别当前 `bloch.rayleigh_channels` 的 pointwise principal-square-root convention
  不适合 complex analytic root search；实现时必须改用从 physical seed 延拓的局部分支。
- 已修正 estimator 的层级含义与符号：
  $\delta_j^{\mathrm{map}}$ 一阶预测 $k_{j+1,h}-k_{j,h}$，在
  $e_{j+1}=o(e_j)$ 时估计 coarse tail
  $|k_{j,h}-k_{\infty,h}|$，不估计 fine-level tail。
- 已把未收敛 root defect、map correction 与 total next-level predictor 分开，并给出
  simple-root $C^1$ expansion 下 effectivity 趋于 $1$ 的条件化推导。
- 已给出依赖独立 saturation bound 与 correction remainder 的严格区间；同时以精确
  oscillatory scalar counterexample 证明有限个 observed ratios 不能生成 certificate。
- 已用一个非正规 `2 x 2` manufactured NEP 检查 correction 的符号和渐近 effectivity，
  并用 oscillatory scalar hierarchy 检查 false-asymptotic gate；这些是 Python
  algebraic sanity checks，不是项目 MATLAB validation。
- 历史 writer 曾把 Phase 2--3 的 finite-tail 理论和实现协议整理为旧
  `phase4-report/method.tex`；该 13 页版本现完整归档为
  `phase4-report/legacy-tail.tex`，不删除推导和审查记录。
- 历史独立 skeptic 曾逐式核对 augmented equations、analytic chart、bordered Newton、
  projected correction、coarse/fine 解释、条件 effectivity 证明和 reliable interval；
  writer 未改变 researcher 的核心数学逻辑。
- 历史稿曾按 skeptic 初轮 `REVISE` 意见补入同维 $F_{\infty,h}$ scattering-block lift、
  far-block 一致可逆性与 kernel bridge 条件、完整 doubling Schur pole gate、Fliss DtN
  的谱适用域，以及紧圆盘上的 $C^1$ 范数；delta-audit verdict 为
  `PASS WITH CONDITIONS`。
- 历史稿曾清理 notation conflicts：center extractors 改记为 $\mathcal E_L,\mathcal E_R$，
  三个标量反例与主 NEP 符号分离，并内联双侧 DtN map-difference 诊断。
- 历史 finite-tail PDF 曾完成逐页渲染检查；当前连续 DtN/BIE `method.pdf` 已重新生成并
  另行检查。
- 已在唯一活动目录 `implementation/i1/` 冻结离散 $A_{\mathrm{def}}$ 设计。两位
  独立 Skeptic 先后发现并促成修复 left reversed-pair reference、双向 `DIF/sep`、
  seed-cluster continuation 和 ratio-only chart gate；最终均报告 design-level blocker 为
  0。稳定定义已同步写入 `method.tex`，16 页 `method.pdf` 已重新构建并逐页渲染检查。
- 随后的 I1.2 已在 `test/i1/hg-adef/` 实现并运行 manufactured、MATLAB $M=5,8$
  low-order 和 direct $M=48$ static half-guide 联合验证；package 源码仍未修改。
  $M=48$ 的双向 QZ、参考墙、coarse/fine graph、代数 chart、DtN action 与公式级
  $A_{\mathrm{def}}^{D/G}$ 已通过。production separation 未计算并保留为 caveat；
  $A_{\mathrm{def}}'$ 留给已授权的经验型 I1.3。
- 已在 `test/archive/legacy-route-v1/eig-apost-nep/` 完成 manufactured `2 x 2` analytic NEP 的 Octave 实现、
  两次确定性复现和 skeptic 审查；该实验只关闭有限维算法门。
- 已在 `test/archive/legacy-route-v1/hg-map/` 完成 Half-guide map Stage 1：非交换代数、exact analytic cell、
  固定物理 smoke、Wood/Robin/order 负例和数值向量复现均通过；完整 artifact-byte
  reproducibility 尚未建立。
- 已在 `test/archive/legacy-route-v1/aug-bie/` 完成 Augmented BIE Stage 2：A1/A2 manufactured oracles、实际
  ellipse/circle interface smoke、七个 finite-tail levels、availability/failure negatives
  与 source-aware unchanged-source rerun 均通过。最大 actual raw Schur error 为
  $3.16\times10^{-17}$，wrong-coordinate mutation mismatch 为 $7.22\times10^{-2}$。
- 已在 `test/archive/legacy-route-v1/root-ready/` 完成历史 Root-readiness early-stop proxy diagnostic 及两次
  unchanged-source Octave 运行。修正后的 $10^{-5}$ object-compatibility gate 中 78/78
  downstream rows 和 3/3 resolution rows 通过，aggregate max 为
  $1.898508\times10^{-9}$；rank 126/144 的 projector fingerprints、直接调用源码清单和
  数值向量完全复现。
- 历史受控诊断确认当前 `kernel.precomp_proxy` 接口不暴露其内部实际消费的
  $A_{\mathrm{pr}},b_{\mathrm{pr}}$；测试只能镜像构造并比较输出。coefficient、proxy
  field 与 residual 的三个 $10^{-11}$ gates 分别以 $2.798540\times10^{-7}$、
  $5.531552\times10^{-10}$ 和 $1.250388\times10^{-9}$ 失败，因而没有启动 root-stage
  计算。
- 已在 `test/archive/legacy-route-v1/root-ready/provenance-closure/` 完成 source-exact test-local copy、
  共享 $A,b$ cache、原阈值 gate、synthetic mutation negative 和 transactional
  baseline/repeat。6 个 shared systems 对应 30 个 solver rows；复制体与 package public
  output bitwise 一致，三个原 $10^{-11}$ output gates 的差异均为 0。
- provenance-closure 双跑均由 Conda `octave` 环境完成，baseline/repeat 用时分别为
  $6.4742$ s 和 $6.6299$ s；repeat 数值相对差为 0，11 项 direct-call manifest、
  shared-system 和 projector fingerprints 全部一致，原子发布与 marker hashes 经
  Engineer 独立复算通过。
- 已在 `test/archive/legacy-route-v1/root-ready/analytic-readiness/` 完成 I4 source-derived branch-injected
  evaluator、29 点 locator、fixed-chart/disk/CR/factor/negative 的 fail-closed 管线和
  transactional baseline/repeat。两次权威 Octave 运行 exit code 均为 0，所有科学表
  完全复现，aggregate numeric difference 为 0，19 项 direct-source manifest 与双 marker
  验证通过。
- I4 在 locator 处得到 `NO_SCREENED_DIP`：29/29 点 available，$s(k)$ 在
  $[0.04,0.18]$ 上严格下降，从 $0.2083091449$ 到右端点的 $0.03539366850$。没有 strict
  interior minimum，最小值仍约为 $10^{-3}$ 门限的 $35.4$ 倍，因此 chart、complex disk、
  factor ledger、full-$F$ CR 和七个依赖 seed 的 negatives 均按协议未运行。
- I4 Researcher 分析和 Skeptic post-run review 均认定 STOP 有效且可解释：证据为
  `PASS WITH CONDITIONS`，科学结论为 `REPRODUCIBLE STOP / NO_SCREENED_DIP`，I5 不获
  授权。该结论现只作为历史双椭圆 negative 保存。
- 已在 `test/archive/legacy-route-v1/i4-fliss-2013/` 完成 Fliss missing-column 双轨 benchmark。exact smooth FD
  baseline 给出主候选 $\lambda_h=3.460975044$，中心质量比例 $0.4959$、端部比例
  $6.97\times10^{-10}$、八/十二周期尾长相对位移 $2.32\times10^{-7}$；相对论文值差
  $0.116\%$。
- targeted N80/N120 edge confirmation 得到 $\varepsilon_{80,120}=7.91\times10^{-4}$、
  safe gap $(1.981350,5.386819)$ 和 candidate margin $1.479625$，四个冻结门全部通过，
  因而状态为 `TRACK_A_PROJECTED_GAP_CONFIRMED / I4_FD_CANDIDATE_READY`。
- sharp-disk 旧 affine/逐模态 pencil diagnostics 保留为历史失败路径。新的 projective
  ordered-QZ/doubling core 完成 15 个 $(\delta,k)$ low cases、三个尺度控制和三个 high
  pairs；canonical $\delta=0.30$ 与 small-clearance $\delta=0.10$ 分别观察到
  $[5,20]$、$[19,20]$ right-censored candidate windows。$\delta=0.20$ 在目标 $k$ 有两个
  neutral pairs，属于 parameter-specific projected-band 情形，不记作算法失败。
- 三个 high extractor errors 为 $1.499\times10^{-7}$、$4.282\times10^{-8}$ 和
  $1.438\times10^{-7}$，均未过 $10^{-8}$。因此全局
  `M_trace=NA / M_stable=NA / interval=NOT_CERTIFIED`，状态为
  `BIE_RAYLEIGH_BUDGET_SCREENED / TRACE_EXTRACTOR_BLOCKED`。
- canonical extractor-only 实验中的 Bessel closed form 与 package extractor 都直接使用
  Rayleigh modal kernel；它们的一致性只验证同一个 modal integral 的闭式公式、梯形求积
  和代码实现，不再作为 qpgreen 谱表示或 sum--integral interchange 的独立闭环。
- 新 `test/archive/legacy-route-v1/i4-three-path/` 实验以 Linton 式 (2.65) 的真 Ewald split 建立独立 value
  reference：Tables 2--5 五点最大误差 $5.07\times10^{-11}$，项目点
  Ewald--Rayleigh 最大误差 $1.11\times10^{-16}$。同一冻结密度先经完整 Ewald kernel
  积分再做 wall Fourier projection，与 Rayleigh extractor 的 SLP--D 系数最大差为
  $6.10\times10^{-16}$。这只在当前实数非 Wood、clearance $0.3$ 和冻结密度/模态范围内
  通过，不自动推广到导数、复杂 $k$ 或一般曲线。
- package MFS 在五个 canonical/hold-out point 上最大误差为 $4.89\times10^{-8}$，在
  Linton 五个原始点上最大误差为 $6.01\times10^{-8}$；SLP--D
  中 Ewald--MFS 和 MFS--Rayleigh 最大误差为 $4.69\times10^{-8}$。分别只加密
  $N_{\mathrm{side}},N_{\mathrm{top}},N_{\mathrm{proxy,edge}},M_{\mathrm{pw}}$ 时，系数变化为
  $7.52,5.99,3.72,4.45\times10^{-8}$，而 $n_{\mathrm{tot}}$ 与 $N_y$ 变化仅约
  $2.8\times10^{-11}$。当前 blocker 因而定位为 Octave augmented-MFS/proxy/solver path。
- cheap solver diagnostic 证明默认 `pinv` path 复现上述 point error；economy-SVD 在
  relative $\tau=3\times10^{-16}$ 时把三个冻结点降到 $3.95\times10^{-12}$，但同阈值
  `pinv(A,tol)` 产生 $5.98\times10^{-5}$，因此不能把问题简化为 cutoff-only，也未授权
  derivative/Hessian/wall 验证。
- 新 `test/archive/legacy-route-v1/i4-three-path-derivatives/` 已完成 MATLAB Ewald 解析导数资格化。Linton
  Tables 2--5 五点最大误差仍为 $5.07\times10^{-11}$；value-only Richardson、独立
  Rayleigh derivative、Helmholtz residual、mixed-derivative symmetry、source/target sign
  以及 $a,M_1,M_2,N$ 单变量加密均通过。此结论认证 point-level Ewald gradient/Hessian，
  不自动认证 wall layer actions。
- MATLAB pilot 锁定根目录 MEX、package `lsqminnorm` 和三个 package 精确路径。项目函数值
  最大误差为 $5.14\times10^{-10}$；全部一阶导数通过，但 `holdout_B` 的
  $G_{xx},G_{xy},G_{yy}$ 分别为 $1.46\times10^{-8}$、$1.60\times10^{-8}$、
  $1.59\times10^{-8}$，因此在 wall 前以 `P_POINT_KERNEL_UNCERTIFIED` 早停。
- 独立 fixed-$A,b$ 点诊断中 physical-y wrapper 与手工交换后的 computational-x 调用
  逐分量误差为 0；package Hessian 与同一 P 场的 Richardson gradient-FD 最坏误差为
  $2.12\times10^{-11}$。默认 `lsqminnorm` residual 为 $7.79\times10^{-8}$，不同 solver
  的六元组 spread 为 $3.04\times10^{-8}$。relative-$10^{-14}$ economy-SVD 的最坏
  Ewald 点误差为 $2.90\times10^{-11}$，但它只证明 rank/tolerance 是决定变量，不能
  静默替代 public package 路径。该问题是 DLP--N 的下游 Hessian blocker，不覆盖较早
  action 的 component-specific 资格。
- action-specific full run 中 SLP--D 全部通过：E--P/P--R 最大系数误差为
  $4.33\times10^{-10}$，P proxy self 最大为 $3.97\times10^{-10}$，因此旧 full SLP--D
  P-path blocker 已关闭。SLP--N 的系数三角、$n_{\mathrm{tot}}$、$N_y$、Ewald、tail 和
  $M_{\mathrm{pw}}$ 加密均通过，但 P 的 Nside/Ntop/Nedge self changes 分别为
  $6.56\times10^{-9}$、$2.58\times10^{-9}$、$1.09\times10^{-8}$。该历史 run 的 blocker 是
  `SLP_N_UNCERTIFIED_P_GX_PROXY_SELF_CONVERGENCE`；DLP--D/DLP--N 按用户冻结顺序未运行。
- 新 `test/archive/legacy-route-v1/i4-proxy-rule/` 没有继续加密历史 $p/d=0.7$，而是按最近周期镜像奇点先验
  唯一冻结 $p/d=0.2$。MATLAB pilot 的两个 $G_x$ 点 Ewald 误差最坏为
  $2.18\times10^{-14}$，training/错位 hold-out residual 为 $10^{-12}$--$10^{-11}$。
  canonical 的 SLP--D/SLP--N E--P 最大误差为 $1.64\times10^{-14}$、
  $3.42\times10^{-14}$；SLP--N Nedge/Nside/Ntop/$M_{\mathrm{pw}}$ self 为
  $4.14\times10^{-14}$、$2.12\times10^{-14}$、$3.03\times10^{-14}$、
  $1.61\times10^{-13}$。最终源码哈希写入 report 后复跑用时 $69.037429$ s，故
  `SLP_D_N_CERTIFIED_PROXY_RATIO_0P2` 与 OP-I4-1f 正式关闭。
- 新 `test/archive/legacy-route-v1/i4-dlp-trace/` 在任何 wall matrix 前完成 1.71 s MATLAB pilot。三个冻结点的
  $G_x,G_y$ 对 Ewald 最大误差为 $7.88\times10^{-14}$，四轴 point self 最坏为
  $7.64\times10^{-14}$；五个 level 的 rank 精确复现 $(302,328,302,302,330)$，且 public
  `lsqminnorm` residual 与 duplicate-column minimum-norm sanity 全部通过。95.539849 s
  canonical 随后按顺序认证 DLP--D、DLP--N 与 $M_{\mathrm{trace}}=48$。DLP--D/DLP--N
  E--P 最大误差为 $1.39\times10^{-14}$/$1.19\times10^{-13}$，DLP--N 最坏四轴 wall self
  为 $1.40\times10^{-13}$；四个 SLP/DLP actions 在 $|m|\le96$ 的逐模态三角全部通过。
  半网格直接 E/P 墙场的 $M=48$ 最坏重构误差为 $7.08\times10^{-12}$，omitted energy
  为 $5.00\times10^{-13}$。完整产物含 9,264 个 coefficient rows 与 49,152 个 wall
  samples；OP-I4-1h 和 OP-I4-6 在冻结范围内关闭。
- Researcher 与 Skeptic 均只认可 screening 结果，不授权 real-axis locator 或 complex
  root isolation。
  `production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` 作为 claim boundary 保持不变。
- 已识别并在 Stage 2 局部规避 variable-speed geometry 的 density-scaling mismatch；
  production `bloch.construct_S` 与 `scat_ld_lead_in` 尚未全局修改或验证。
- MATLAB R2023b 已运行 derivative qualification、point-only solver diagnostic、
  历史 action-specific early-stop wall run、singularity-aware proxy-rule pilot/full，以及
  新 DLP/trace pilot/full。所有新增实验代码和产物只位于 `test/` 下。

## 尚未进行

- 尚未证明 exact half-guide solution operator 与 $\Lambda_\pm(k)$ 在所选复邻域上的
  holomorphy，也未把 projected gap、half-guide Dirichlet spectrum、Wood threshold、cell
  poles 和 BIE representation poles 分成一个完整 analytic-domain ledger。
- 尚未证明 physical variational pencil $\mathcal F(k)$ 与 continuous BIE schema 的
  representation completeness、injectivity、kernel--field equivalence、Fredholm index 和
  adjoint consistency；因此 BIE matrix kernel 还不能等同于真实 guided mode。
- 尚未证明 continuous one-cell relation 到 BIE/Fourier generalized pencil 的 primal/adjoint
  $C^1$ consistency，也未得到 stable/unstable cluster 的 uniform `DIF/sep`、safe chart 或
  带固定 impedance/Riesz map 的 Cauchy-relation/Robin 合同。
- 原先要求的
  $\|\Lambda-E_M\Lambda_{h,M}Q_M\|_{H^{1/2}\to H^{-1/2}}\to0$ 对一阶非紧 DtN 和有限秩
  lift 通常不可能。尚需在 projected consistency + eigentrace regularity、principal-symbol
  subtraction + compact remainder、或 regular Galerkin convergence 三条路线中证明一条。
- 新的 $A_{\mathrm{def}}^{D/G}$ 理论设计、real one-cell/QZ/graph/$A_{\mathrm{def}}$、
  selected complex disk、anchored branch/chart、factor/pole ledger、full-$F$ CR 和 I2.1
  factor-aware contour count 均已完成；尚未执行 root refinement、root-point 左右近核与非零
  场资格化、adjacent-level root matching 或 derivative pairing，且这些工作未获本轮授权。
- 尚未得到独立 saturation 常数和 computable correction remainder；相邻层差只能称
  next-level correction，不能称 remaining-error estimator。
- 尚未修复并回归验证 production variable-speed density scaling；当前 ellipse 的修正
  只存在于 `test/archive/legacy-route-v1/aug-bie/` 的实验路径。
- 尚未直接捕获 production 调用内部实际消费的
  $A_{\mathrm{pr}},b_{\mathrm{pr}}$；本轮关闭的是冻结源码与 Octave 环境中的
  source-derived operational provenance，而不是更强的 runtime internal-array identity。
- 尚未建立独立 $k_{\mathrm{ref}}$、BIE/port refinement、MATLAB parity 或真实缺陷晶体
  waveguide benchmark。
- Leclerc et al. (2026) 的 HAL manuscript 尚处于 embargo；在全文核验与投稿前
  citation update 完成以前，不冻结 priority claim。

## 当前门槛

当前门是
`I2_3_PASS_WITH_CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`；历史
I2.2 structure preflight 状态为 `I2_2_STOP_THEORY_GATE`，但它只否定 raw finite $H$ 的
定理级 inertia 解释，不否定当前数值 endpoint diagnostic。现行方法已经具备正确层级：
physical half-guide PDE 定义 exact $\Lambda_\pm$，physical center variational pencil
$\mathcal F(k)$ 在截断前定义真实根，continuous BIE 只作待证明的等价 realization，
ordered QZ 只计算 finite pencil 的 deflating subspace。旧 finite-tail 方法已降为 legacy。

direct $M=48$ one-cell pencil、左右 Cauchy blocks、manufactured/low-order mechanism、
双向 QZ、coarse/fine graph、代数 chart、DtN 和 Schur 验证均已完成。I1.3 进一步完成
real-$k$ count/projector/chart 连续性和 width-driven candidate sampling，记录
$k=1.8327703475952146$、$q=8.3200886232193094\times10^{-8}$。历史 v1 的
shrinking-prominence stop 保留，但设计 blocker 已由独立 v2 关闭。I1.4 又在冻结小复圆盘上
完成 anchored branch、fixed chart/rank、factor/QZ/graph、loop closure、full-$F$ CR 和负例门，
最终条件通过。I2.1 随后在同一冻结圆盘上完成 factor-aware argument-principle count：所有
实际 inverse factors 的 32/64 winding 为 zero，主 $A_{\mathrm{def}}^D$ 的 32/64 winding 为
one，并经独立跑后审查条件通过。
[[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 的 OP-M0-1--4
继续阻止把 candidate 提升为已证明的 continuous physical eigenvalue 和 theorem-level
error claim；它们不阻止提出 candidate 或构造 empirical indicator。production separation/
graph tangent 只在具体 estimator 实际需要时升级。OP-M0-5 的 saturation/remainder 是
`IMPORTANT CAVEAT`，不阻止 next-level correction 或 independent-truth-validated empirical
estimator，但会阻止 computable upper bound。

因此可以说“该冻结有限维圆盘内条件性 count one”，但不得给出尚未计算的 root 坐标，也
不得把它称为 derivative-qualified simple root 或 continuous physical eigenvalue。最终三个
$q$ 值仍显著变化，也不得描述为 plateau。四个 M0 理论问题和 production derivative 仍未
完成；历史 I2.2 已资格化实直径上点态奇异等价表示，但 exact finite Hermitian 与
whole-interval same-family 证明失败关闭，数学 inertia 不可用。当前 I2.2 不翻转该历史结论，
只把预注册端点的 sign-count/inertia-like jump 当作 candidate 可信度诊断。I2.3 随后在冻结
离散阶数与统一 candidate 规则下完成 `ntot` 与 $M$ 两条单轴的 same-mode saved candidate
序列、signed/absolute observed drift、terminal-cell diagnostic 与最低原始检查；两条轴各自
三层 candidate 完全相同且 mode identity 通过，故为
`NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`。I3 现可接收这两条 conditional algorithmic
hierarchy，并识别 location/solve/evaluator、空间/trace、half-guide、
BIE/QZ structure 和 continuous bridge 等误差来源，并决定 matching、derivative、adjoint、
denominator 或 independent reference 中哪些是必需输入；不得为了复用某个 simple-root 公式，
预先把 exact finite zero 身份设成项目终点。
既有 Fliss FD candidate 和 SLP/DLP/$M_{\mathrm{trace}}$ 数值证据继续保留，但不缩短上述
理论—离散桥接链。仍不创建 `research/mainline/`，也不使用绝对优先权表述。

## 新 session handoff

- 唯一允许写入的 worktree 是 `/Users/whc/Documents/Work/epost`，当前分支为
  `codex/epost`，本轮路线复审基准提交为 `fcc38bd`。不得修改主分支所在目录，也不得删除该
  worktree。
- 新 session 应先读取仓库根目录与 `research/` 下的 `AGENTS.md`，再读取本文件、
  [[research/projects/eig-apost/implementation/README|implementation stage overview]]、
  [[research/projects/eig-apost/implementation/i2/README|current I2 guide]]、
  [[research/projects/eig-apost/implementation/i2/design|I2.1 frozen design]]、
  [[research/projects/eig-apost/implementation/i2/review|I2.1 independent review]]、
  [[test/i2/k-count/README|I2.1 experiment index]]、
  [[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 frozen design]]、
  [[research/projects/eig-apost/implementation/i2/review-2-2|I2.2 independent review]]、
  [[test/i2/h-inertia/README|I2.2 experiment index]]、
  [[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 frozen design]]、
  [[research/projects/eig-apost/implementation/i2/review-2-3|I2.3 independent review]]、
  [[test/i2/k-drift/README|I2.3 ntot-axis experiment index]]、
  [[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 M-axis frozen design]]、
  [[research/projects/eig-apost/implementation/i2/review-2-3m|I2.3 M-axis independent review]]、
  [[test/i2/m-drift/README|I2.3 M-axis experiment index]]、
  [[research/projects/eig-apost/implementation/i3/README|I3 error-estimation guide]]、
  [[research/projects/eig-apost/phase1-scope/questions|Phase 1 commitments]]、
  [[research/projects/eig-apost/phase1-scope/p-method|Phase 1 analytical framework]]、
  [[research/projects/eig-apost/phase2-sources/synthesis-dtn|DtN source synthesis]]、
  [[research/projects/eig-apost/phase2-sources/r-nep-error|NEP error sources]]、
  [[research/projects/eig-apost/implementation/i1/design|current I1 discrete design]]、
  [[research/projects/eig-apost/implementation/i1/review|current I1 review]]、
  [[research/projects/eig-apost/phase4-report/method.tex|current continuous method]]、
  [[research/projects/eig-apost/phase4-report/legacy-tail.tex|legacy finite-tail formulation]] 和
  [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]]。Phase 1--2 文件
  保持历史原文，不因本次重构回写。
- 新路线当前 verdict 是
  `I2_3_PASS_WITH_CONDITIONS / NO_OBSERVED_CANDIDATE_DRIFT / SAME_MODE`；I1 dip 中心为
  $k=1.8327703475952146$，I2.1 已确认冻结圆盘内一个按代数重数计的 determinant zero，但
  尚未运行 root locator/refinement；历史 v1 zoom 的
  `STOP / DESIGN-GATE-INCONCLUSIVE` 只作为不追溯改写的设计负例保留。历史 I4 数值标签仍保留为
  `PARTIAL SUCCESS -- I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / EWALD_DERIVATIVE_REFERENCE_CERTIFIED /
  SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 / DLP_D_N_MTRACE48_CERTIFIED`；
  `REPRODUCIBLE STOP / NO_SCREENED_DIP` 只描述历史双椭圆实验。I3 的
  `root_readiness_review.md` Section L 与 `root_result.md` Section I 继续作为 provenance
  历史边界；不得把历史 I3 的下一阶段授权覆盖当前 BIE blocker。
- 路线、连续—离散理论与 proof obligation 审查默认采用 Researcher + Skeptic：Researcher
  重建主线，Skeptic 独立检查本末倒置、过度证明和真实 blocker。Engineer 只在已有设计授权
  后承担实现与资源核对，不得反向以某版代码结构定义理论路线。Skeptic
  必须按当前工程目标区分 `BLOCKER`、`IMPORTANT CAVEAT`、`MINOR CAVEAT`，只有
  blocker 能停止阶段，并优先建议廉价 numerical sanity check；主 agent 负责综合、更新
  [[research/projects/eig-apost/implementation/open-problems|open-problem ledger]] 和
  handoff。
- 历史 operational provenance 状态仍保留
  `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`；历史 numerical qualification 标签包括
  `I4_FD_CANDIDATE_READY / BIE_RAYLEIGH_BUDGET_SCREENED /
  EWALD_VALUE_REFERENCE_CERTIFIED / EWALD_DERIVATIVE_REFERENCE_CERTIFIED /
  SLP_D_N_CERTIFIED_PROXY_RATIO_0P2 / DLP_D_N_MTRACE48_CERTIFIED`；
  `production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` 和
  `PHYSICAL_ROOT_READY=STOP` 保持不变。这些历史状态不是当前阶段 gate；I2.1 的已完成 gate 是
  `I2_1_PASS_WITH_CONDITIONS / CONDITIONAL_EMPIRICAL_FINE_M48_COUNT_ONE`。I2.2 历史 raw-$H$
  支线状态仍为 `PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE`；当前后续结果为
  `PASS WITH CONDITIONS / HERMITIAN_PART_SINGLE_JUMP`。后者只描述两个冻结端点的 surrogate
  sign-count difference，不把历史 theory gate 翻转成 raw-$H$ inertia，也不得解释为 qualified
  root、continuous eigenvalue 或 estimator。
- 新路线 I1.2 的 manufactured、MATLAB $M=5,8$ mechanism 和 direct $M=48$ static arms 已在
  `test/i1/hg-adef/` 通过；I1.3 又在 `test/i1/k-scan/` 记录 fixed-$M=48$ 离散候选
  $k=1.8327703475952146$；I1.4 在 `test/i1/k-ready/` 达到 sampled fixed-$M=48$ readiness。
  I2.1 在 `test/i2/k-count/` 达到条件性 finite-dimensional count one。production derivative
  因 FD mutation 门失败仍不可用；I2.2 两肩 structure diagnostic 与后续 Hermitian-part
  sign-count 已完成。后者观察到稳定 `SINGLE_JUMP`，但保留 exact-Hermitian 与
  whole-interval caveats，未形成 mathematical raw-$H$ inertia、实根或 continuous eigenvalue。
  I2.3 已完成两条预注册 candidate 漂移实验：$n_{\mathrm{tot}}=160,208,256$ 与固定
  $n_{\mathrm{tot}}=160$ 的 $M=32,40,48$。两条轴的三层均通过最低原始诊断并确认
  `SAME_MODE`，saved candidate 完全相同。因此当前项目得到两条 conditional algorithmic
  hierarchy。I3.1 的中心空列 strong-residual baseline 由固定单胞 cutoff 主导且分辨率不足；
  lead-aware reconstruction 又在 fixed holdout fit 首败，尚未形成 continuous residual 或
  estimator。不得把 observed candidate equality 报告成 sub-grid
  minimizer、exact finite real zero 或连续 eigenvalue 的零漂移，也不得称已收敛或自动转入
  复平面实验。
- 历史新增内容现归档于 `test/archive/legacy-route-v1/i4-rayleigh-budget/`、
  `test/archive/legacy-route-v1/i4-extract/`、`test/archive/legacy-route-v1/i4-three-path/`、
  `test/archive/legacy-route-v1/i4-three-path-derivatives/`、
  `test/archive/legacy-route-v1/i4-proxy-rule/`、
  `test/archive/legacy-route-v1/i4-dlp-trace/` 与本专题
  STATUS/README/ledger/report 文档；package 源码未修改。MATLAB R2023b qualification、
  action-specific pilot、历史 early-stop full wall run、point-only fixed-system diagnostic、
  proxy-rule pilot/full 与 DLP/trace pilot/full 已运行；最终 DLP/trace full 用时
  $95.539849$ s 并通过顺序门。
  历史 Octave canonical 用时 $531.181285$ s。

新 session 若调用 Engineer，只能在 I3 的另行设计明确需要 sub-grid minimizer、非零 level
shift 或新离散轴后承担相应实现；不得重跑 I2.2 或 `drift-a1`、结果后移动窗口、重新宽扫、
自动运行复数 refinement，或扩张 exact finite-Hermitian 证明支线。
不得重复或绕开已经通过的 manufactured、low-order、direct $M=48$ static oracle、I1.3
实轴 candidate、I1.4 sampled readiness 与 I2.1 count-one result；
理论侧继续处理 OP-M0-1 的 concrete exact-DtN/analytic-domain contract 和 OP-M0-2 的 physical/BIE
kernel bridge。不得以 balanced matrix 或固定点数值 sanity check 跳过连续—离散证明义务，
也不得把当前有限 $M_{\mathrm{ref}}=96$ 制造密度认证外推为完整
$H^{1/2}\to H^{-1/2}$ operator-norm convergence。
