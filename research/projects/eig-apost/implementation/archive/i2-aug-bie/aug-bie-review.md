<!-- Stage 2 augmented BIE / center-coupling implementation final review -->

# Stage 2 augmented BIE final skeptic review

## A. Audit frame

### Material Passport

- **Audit target:** Researcher 的 2026-08-02 `Stage2 PRE-REVIEW FROZEN` handoff、同日
  blocker-resolution revision 及其落盘版本
  [[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie|Augmented BIE Stage 2 design]]，以及
  Engineer 的 `test/aug-bie/aug_bie_experiment.m`、wrapper 与最终 stable evidence bundle。
- **Claimed contribution:** 构造固定维数的九块 augmented matrix，通过一个直接 raw Schur
  路径与一个 reduced center-scattering 路径核对 center coupling、远端 Dirichlet 闭合和
  level-dependent lead blocks。
- **Current stage:** Stage 2 离散代数实施与 formal rerun 完成；未授权 root search。
- **Authority:** 当前无 active mainline。项目级权威依次取
  [[research/projects/eig-apost/phase4-report/method.tex|Phase 4 method]]、
  [[research/projects/eig-apost/phase3-analysis/s-root|root formulation]]、
  [[research/projects/eig-apost/phase3-analysis/p-implement|implementation route]] 与
  [[research/projects/eig-apost/STATUS|project status]]；本轮 frozen handoff 是待审设计，
  不是已验证结论。
- **Code/material examined:** `+op/construct_A_QP.m`、`+bloch/construct_S.m`、
  `+bloch/incident_rhs.m`、`+bloch/farfield_extractors.m`、
  `+bloch/select_port_traces.m`、`scat_ld_lead_in.m`，以及 Stage 1 的 map、result、review
  artifacts；还审查了 final source hashes、`run.log`、`results.mat`、`algebra.csv`、
  `pole-ledger.csv`、`representation-ledger.csv`、`negative-cases.csv`、`levels.csv`、
  `report.md` 与 `reproducibility.txt`。
- **Assumptions:** 固定 $k=0.10$、$\beta=0.8$、$p=15$、`ntot=60` 的点远离 Wood
  anomaly；左右 bulk cells 沿用 Stage 1 的等速圆形参数化；center ellipse 使用本轮冻结的
  scaled-density formulation。
- **Exclusions:** 不审查 analytic branch、contour count、bordered root solver、连续
  kernel--field theorem、root estimator 或 MATLAB 数值正确性。
- **Success criterion:** 实施协议必须独立暴露 block/sign/order/scaling 错误，区分 BIE pole、
  zero-field representation 与 terminal singularity，并把失败传播为明确的 unavailable；
  成功最多授权固定离散、固定参数的 assembly experiment。

## B. Verdict

**PASS WITH CONDITIONS — high confidence.** 最终 unchanged-source run 报告
`STAGE2_DISCRETE_ALGEBRA_GO=1`、`ALL TESTS PASS`、`REPRODUCED`、relative difference $0$
和 source-manifest equality $1$；本审计独立核对的八个 SHA-256 与 `config.txt` 完全相同。
先前能使结论失效的 circular level oracle、硬编码 representation negatives、错误
failure ledger、无 source-aware reproducibility 以及字面 availability booleans 均已被可执行检验关闭。
正例的 raw/reduced Schur agreement 至多为 $3.16\times10^{-17}$，七个 levels 的七层
availability 均为 true；center/zero-field/left-terminal/right-terminal 负例则保留 raw
$F_{\mathrm{aug}}$ 和 $K_{ee}$，对未定义派生量保存 `NaN`。这些证据支持的范围仅是
冻结离散代数与 interface smoke；它不证明 continuous kernel--field equivalence、
pole-free search domain、root 或 eigenvalue。因此 `ROOT_READY=STOP` 必须保持。

## C. Strongest challenge

最能推翻物理解释的机制是 **zero-field representation kernel**。若存在 $q\ne0$ 使

$$
  A_cq=0,\qquad \mathcal E_Lq=0,\qquad \mathcal E_Rq=0,
$$

则九块系统以所有 port amplitudes 为零、$\xi=q$ 得到代数核，但对应外场可以恒为零。
raw Schur 与 reduced scattering 的相等不能排除该机制，因为二者使用同一 BIE
representation。Phase 4 已明确把 kernel--field equivalence 和 representation nullspace
列为 root 前置义务；固定 $k$ 的矩阵恒等式不能替代它。

## D. Findings

### 1. MAJOR, RESOLVED — pole 与 zero-field representation 必须分离

- **Location:** 首轮 handoff 的 `singular Ac+invisible density` negative 与 frozen revision
  的两个拆分负例；
  [[research/projects/eig-apost/phase3-analysis/s-root|s-root §4]] 和 Phase 4 method 的
  center-kernel discussion。
- **Evidence:** zero-field representation 必然同时含 $A_c$ 的零向量；一个合并负例会同时
  触发 `Ac` singular 与 $[A_c;\mathcal E_L;\mathcal E_R]` rank loss，因而不能验证原因
  识别、优先级或差异化传播。
- **Consequence:** 若不拆分，实现可能把任何 $A_c$ pole 都误报为 zero-field kernel，或
  反过来；这种 ledger 不能支持后续 root 排伪。
- **Resolution/evidence:** revision 已冻结：`CENTER_BIE_POLE` 使用
  $A_c=\operatorname{diag}(1,1,1,0)$ 与满列秩 visible stack；
  `ZERO_FIELD_REPRESENTATION` 使用同一 $A_c$，但令 $e_4$ 成为
  $[A_c;\mathcal E_L;\mathcal E_R]$ 的共同零向量，并检查 density-only augmented
  nullvector。final ledger 中 center 的 $V_c$ rank 为 $4$，zero-field 的 rank 为 $3$；
  两者分别输出 `CENTER_BIE_POLE;RAW_SCHUR_POLE` 和
  `CENTER_BIE_POLE;ZERO_FIELD_REPRESENTATION;RAW_SCHUR_POLE`，且都保持
  `ROOT_READY=STOP`。
- **Uncertainty:** 这仍是 manufactured distinction，不证明实际 ellipse 没有相应机制。
- **Decisive test:** re-review 必须看到两个 negative 均命中预期 primary/all-reason ledger，
  并保留 raw augmented evidence。

### 2. MAJOR, CONTAINED — 现有 BIE 接口存在被圆形测试隐藏的 density-scaling mismatch

- **Location:** `+op/construct_A_QP.m:99-101`、`+bloch/construct_S.m:98-146`、
  `scat_ld_lead_in.m:231-242`。
- **Evidence:** `construct_A_QP` 返回
  $A_c=D_hA_{\mathrm{phys}}D_h^{-1}$，但现有 `construct_S` 和 `scat_ld_lead_in`
  直接配用未缩放的 physical $B$ 与 $\mathcal E$。一致坐标应为

  $$
    \xi=D_h\eta_{\mathrm{phys}},\qquad
    B_s=D_hB,\qquad
    \mathcal E_s=\mathcal E D_h^{-1}.
  $$

  对等速圆，$D_h$ 是标量倍单位阵，scattering map 中缩放恰好抵消；椭圆的 speed 随节点
  变化，不再抵消。
- **Consequence:** 未修正时，ellipse center scattering、density participation 和 field
  reconstruction 都可能错误，而 BIE residual 仍然很小。
- **Resolution/evidence:** Stage 2 在 ellipse center 上显式使用 scaled path；actual
  scaled-density relation 误差为 $1.69\times10^{-16}$，scaled/physical scattering 误差为
  $5.91\times10^{-17}$。A2 的 wrong-scaling mutation 产生 $7.22\times10^{-2}$ mismatch，远大于
  $10^{-3}$ gate。历史 production helper 未修改，因而缺陷在本轮被隔离而非全局修复。
- **Uncertainty:** 仍未验证 `construct_S` 在一般 variable-speed geometry 上的历史输出。
- **Decisive test:** 同一 ellipse 上分别用 scaled path 与显式 unscaled similarity path
  计算 $S_c$，以相对误差比较；raw `construct_S.H_*` 和 `scat_ld_lead_in` density 不得作为
  physical oracle。

### 3. MAJOR, RESOLVED — availability 必须按对象分层

- **Location:** frozen handoff 的 `no pinv; downstream NaN`。
- **Evidence:** 当输入 blocks 有限时，即使 $A_c$ 奇异，九块 $F_{\mathrm{aug}}$ 仍可直接
  组装；不可定义的是依赖 $A_c^{-1}$ 的 $S_c$、reduced oracle 和相应 Schur-equivalence
  claim。zero-field negative 还需要保留 raw matrix 才能展示伪核。
- **Consequence:** 若 gate 在 assembly 前 hard-stop 或把 raw diagnostics 清为 `NaN`，实验将
  丢失最关键的 falsification evidence。
- **Resolution/evidence:** revision 已冻结逐字段状态；primitive finite/dimension/fingerprint/
  scaling 允许时保留 raw $F_{\mathrm{aug}}$，只有未定义的 $S_c$、reduced matrix、raw Schur
  与 root fields 写 `NaN`；同时记录 deterministic `primary_failure_reason` 与包含全部原因的
  ledger。禁止 `pinv`。
- **Final evidence:** shared gate 对每个对象返回 computed availability。序列化证据中
  center/zero-field 的 flags 是 `1011000`，left terminal 是 `1101000`，right terminal 是
  `1110000`；四者的 raw $20\times20$ matrix 和 $16\times16$ $K_{ee}$ 均保留，
  $F_{\mathrm{red}}$ 与 raw Schur 均为 `NaN`。
- **Uncertainty:** 这只覆盖预注册的 exact manufactured failures，未建立 near-threshold
  availability 的数值稳定性。
- **Decisive test:** 任一后续 factor-threshold 变更都应重跑四个 transition vectors、raw
  retention 和 `NaN` sentinel assertions。

### 4. MAJOR, RESOLVED — gate 必须归一化，tall stack 必须用 SVD/rank

- **Location:** frozen handoff 的 `equivalence/residual <=1e-11`、generic `rcond` 和
  `[Ac;EL;ER]` fingerprint。
- **Evidence:** 未归一化 residual/equivalence 随 block scaling 改变；tall matrix
  $[A_c;\mathcal E_L;\mathcal E_R]$ 不能用 square-matrix `rcond` 解释。
- **Consequence:** 同一逻辑在不同 density 或 port scaling 下可能翻转 PASS/FAIL。
- **Resolution/evidence:** revision 已冻结 matrix comparison、solve residual、homogeneous
  residual、relative singular value 与 rank tolerance 的 numerator、denominator 和 norm；
  $[A_c;\mathcal E_L;\mathcal E_R]$ 只用 SVD/rank，不用 `rcond`。algebra、actual smoke、
  increment、forbidden-difference、BIE、mutation、gap 与 commutator thresholds 均已预注册。
- **Final evidence:** actual ledger 对 $V_c$ 报告 relative $\sigma_{\min}=0.9461$ 和
  rank $120$；`pole-ledger.csv` 使用 relative residual/rcond gates，且 A2 similarity 检查在坐标
  变换下以 $10^{-16}$ 量级通过。
- **Uncertainty:** evidence 没有覆盖大尺度重标定或极端病态下的 threshold sensitivity。
- **Decisive test:** 若后续改变 density/port normalization，必须重跑 A2 similarity、
  $V_c$ SVD/rank 和所有 normalized residual gates。

### 5. MINOR, RESOLVED — level-invariance mask 应枚举八个 block 位置

- **Location:** frozen handoff 的 “rows 4,5,7,8 and their two known lead-block positions”。
- **Evidence:** 对固定 columns
  $(\xi,a_c^-,b_c^+,b_c^-,a_c^+,a_f^-,b_f^-,b_f^+,a_f^+)$，允许随 $j$ 变化的恰为
  $(4,4),(4,6),(5,4),(5,6),(7,5),(7,8),(8,5),(8,8)$ 八个 block positions。
- **Consequence:** 只按整行 mask 会漏掉 identity、center 或 zero blocks 的 level drift。
- **Resolution/evidence:** revision 已逐项冻结这八个位置，并要求每块 relative increment
  gate 与 all-other projection gate；reduced oracle 还被禁止调用 raw assembler、raw Schur
  或 read-back path。
- **Final evidence:** 八个 allowed positions 的 per-block checks 在所有 levels 为零，
  all-other projection ratio 为零；独立 primitive-delta sign 和 allowed-slot swap mutations 分别产生
  $0.547$ 和 $0.394$ residual。
- **Uncertainty:** mask 绑定当前冻结 representation；unknown/row order 一旦改变就不再可直接复用。
- **Decisive test:** representation ID 或 block order 变更时，必须重新生成八个 offsets 并复跑两个
  allowed-slot mutations。

### 6. OBSERVATION — $k=0.10$ 只能验证 regular smoke

- **Location:** frozen actual smoke 与 Stage 1 result/review。
- **Evidence:** Case B 只建立该固定点的 non-Wood、条件数和 map algebra；没有 root isolation、
  kernel--field bridge 或外部 reference。
- **Consequence:** 即使 $j=0{:}6$ 全部通过，也不得输出 eigenvalue、root candidate 或物理
  center-mode claim。
- **Uncertainty:** 未检查该点之外的 analytic neighborhood 或 search domain。
- **Decisive test:** 输出必须保留 `UNSCREENED_CENTER_BIE_INTERFACE_SMOKE`，并固定
  `ROOT_READY=STOP`。

### 7. MAJOR, RESOLVED — 旧 A1 的 transmission-swap negative 是 no-op

- **Location:** [[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie|aug-bie v1.0]] 的 A1
  lead table 与 mandatory falsification cases。
- **Evidence:** 旧 A1 冻结 $T_{LR}^-=T_{RL}^-=T_{LR}^+=T_{RL}^+=I$。因此字面交换
  $T_{LR}$ 与 $T_{RL}$ 不改变任何 primitive block、augmented matrix 或 known-vector
  residual，却同时要求该 mutation residual 大于 $10^{-4}$。
- **Consequence:** 未修复的 experiment 无法按文档实现；若 Engineer 继续，只能静默跳过
  negative、改变 mutation 含义或伪造 PASS。
- **Resolution/evidence:** durable patch 已冻结四个 distinct transmissions，并相应重构
  $R_R^-$、$R_L^+$ 与 exact far amplitudes。预检保持 augmented/reduced residual 为
  $1.77\times10^{-17}$/$2.35\times10^{-16}$、normalized gap 为 $3.740\times10^{-2}$、
  两个 terminated-map errors 为 $1.30\times10^{-16}$/$1.24\times10^{-16}$；literal swap 的
  left/right/both residual 为 $2.277\times10^{-2}$/$1.138\times10^{-2}$/
  $2.545\times10^{-2}$，且四个 transmission rcond 均大于 $0.51$。
- **Final evidence:** formal A1 复现 augmented residual $1.77\times10^{-17}$、raw Schur error
  $4.35\times10^{-16}$ 和 left/right/both literal-swap residuals
  $2.277\times10^{-2}/1.138\times10^{-2}/2.545\times10^{-2}$，全部通过冻结 gate。
- **Uncertainty:** manufactured fixture 的灵敏性不代表 actual lead blocks 对所有 swap 都同样灵敏。
- **Decisive test:** 任一 A1 primitive 变更都必须保持 literal-swap residual $>10^{-4}$并
  同时保持 exact known-vector 和 Schur gates。

### 8. CRITICAL, RESOLVED — adjacent-level allowed-block oracle 是 circular read-back

- **Location:** `test/aug-bie/aug_bie_experiment.m:867-912`（formal run 1）。
- **Evidence:** `LOCAL_delta_support` 只接收 `old_F,new_F`，随后从同一 pair 的八个 allowed
  positions 读回 lead blocks，再用它们重建 `expected`。因此 allowed entries 无论放入何种
  值都会与 read-back expected 相同，输出的七个 `delta_allowed_error=0` 是构造恒等式。
- **Consequence:** 八个 slots 内的 block swap、符号错误或错误 lead source 都可在
  `delta_forbidden_ratio=0` 的同时通过，fixed-representation central claim 未被证伪。
- **Resolution/evidence:** 修复后 expected delta 从 independently stored old/new lead structs
  构造，不再 read back $F$。八个 per-block errors 与 forbidden ratio 在 $j=0{:}6$ 皆为
  $0$；allowed-block sign 及 slot-swap mutations 分别给出 $0.547$ 与 $0.394$ residual。
- **Uncertainty:** 检验覆盖冻结的八个 positions，不覆盖未来 representation 变更后的新 layout。
- **Decisive test:** layout 变更后必须由 primitive lead structs 重生 expected delta，并重跑
  sign/slot-swap mutations。

### 9. MAJOR, RESOLVED — representation negatives 没有执行 shared gate，actual ledger 报错对象

- **Location:** `aug_bie_experiment.m:621-623,1022-1037`；formal run 1
  `representation-ledger.csv`。
- **Evidence:** actual rows 存储 `min(svd(F_aug))` 与 `rank(F_aug)=240`，而 frozen detector 是
  tall $V_c=[A_c;\mathcal E_L;\mathcal E_R]$，其列数和满秩值应为 $120$。五个
  `REP_CHANGED_*` cases 没有构造 mutation 或调用 checker，只直接写
  `observed_metric=1, pass=true`。
- **Consequence:** `D_h`、$p$、order、phase 或 padding drift 的“EXPECTED_FAIL”不是测试结果；
  actual zero-field/representation evidence 也被错误命名。
- **Resolution/evidence:** positives 与五种 actual descriptor mutations 现在经过同一
  representation gate。$p$/order/phase/$D_h$/padding 变异均产生
  `DIMENSION_OR_FINGERPRINT_MISMATCH`。actual ledger 正确记录
  $V_c=[A_c;\mathcal E_L;\mathcal E_R]$ 的 relative $\sigma_{\min}=0.9461$ 和 rank $120$，
  不再把 $F_{\mathrm{aug}}$ 的 rank $240$ 写成 representation metric。
- **Uncertainty:** 这是固定 actual point 的离散 rank evidence，不证明连续 representation injectivity。
- **Decisive test:** root 前需建立 continuous kernel--field bridge；任一 representation fingerprint
  变更也必须使五个 mutation regression 重新通过。

### 10. MAJOR, RESOLVED — failure-reason ledger 没有满足首因/全因语义

- **Location:** `negative-cases.csv` 与 `aug_bie_experiment.m:941-1037,1244-1257`。
- **Evidence:** Wood case 在 BIE construction 前停止，却把 `all_failures` 写成
  `LEAD_BIE_POLE`；多数 negative 的 `all_failures` 漏掉 `primary_failure`；`far_left/right`
  若 singular 会在 `LOCAL_factor_failure` 落入 `DIMENSION_OR_FINGERPRINT_MISMATCH`，而不是
  termination/far-block failure。
- **Consequence:** unavailable 虽被置位，但无法追溯正确 failure mechanism；这正是本阶段要
  验证的 failure propagation。
- **Resolution/evidence:** `negative-cases.csv` 中 Wood 只报 `WOOD_POINT`；center/zero
  同时保留 `CENTER_BIE_POLE` 与真实下游原因；left/right far/terminal failures 稳定
  报 `TERMINAL_RESONANCE;RAW_SCHUR_POLE`。所有 negative rows 的 primary 都包含在
  `all_failures`，且 `pass=1`。
- **Uncertainty:** ledger 只覆盖预注册原因；新 factor 或新的 precedence 规则需另行冻结。
- **Decisive test:** 每个新 failure path 必须有一个可执行 negative，并检查 primary 包含于
  all-reason ledger 且不虚构未执行上游检查。

### 11. MINOR, RESOLVED — reproducibility 尚未验证 identical-source 双跑

- **Location:** `reproducibility.txt` 与 `LOCAL_previous/LOCAL_compare_previous`。
- **Evidence:** formal run 1 状态为 `BASELINE_CREATED`；当前 compare path 比较 vector，却没有
  验证 previous/current source-hash manifests 相同。
- **Consequence:** 代码改变但数值恰好相同时也可能被报为 `UNCHANGED_SOURCE_MATCH`。
- **Resolution/evidence:** final pair 先建立 source-changed baseline，再以 identical source 重跑。
  第二次输出 `REPRODUCED`、relative difference $0$、manifest equality $1$；本审计用
  `shasum -a 256` 逐一核对 design、symbol appendix、四个 reused helpers、experiment 和
  wrapper，八个 hash 全部与 `config.txt` 相同。
- **Uncertainty:** skeptic 没有独立重跑 experiment；本结论依赖 Engineer 生成的 stable pair
  与本审计的只读交叉检查。
- **Decisive test:** 任一 manifest-covered source 改变都必须先产生 changed-source baseline，再以
  identical source 得到 `REPRODUCED`。

### 12. MAJOR, RESOLVED — unavailable propagation 仍是硬编码期望，不是被测行为

- **Location:** formal run 2 的 `LOCAL_reduced_oracle`、`LOCAL_raw_schur`、
  `LOCAL_run_negatives` 与 `results.mat/negative_cases`。
- **Evidence:** solve/Schur helpers 没有 guard 或 availability return；negative rows 把
  `raw_available,derived_available` 当作字面 constructor arguments。`results.mat` 只保存 center
  pole 与 zero-field 的 raw matrices，没有 left/right terminal raw matrices，也没有逐字段
  `Sc/Fred/raw_schur/equivalence/root` flags 或 undefined-value `NaN`。terminal cases 未组装其
  augmented $F$ 或 partition $K_{ee}$。
- **Consequence:** CSV 能写出预期 unavailable，但没有证明输入 $A_c$、far 或 $K_{ee}$ failure
  会让正确派生对象 unavailable，同时保留可构造的 raw evidence。
- **Resolution/evidence:** `LOCAL_availability_gate` 现在被 A1、actual levels 与所有
  negatives 共用，computed flags 与独立 expected vectors 比较。center/zero-field/left/right
  terminal 的 flags 分别为 `1011000/1011000/1101000/1110000`；raw matrix 与
  $K_{ee}$ 存在，未定义派生对象是固定尺寸 `NaN`。本审计从 `results.mat`
  直接读回四个 $20\times20$ raw matrices、$16\times16$ $K_{ee}$ 和 sentinels；
  代码在 rcond gate 失败时不解 singular factor。actual $j=0{:}6$ 的全部七层 flags
  为 true，equivalence errors 至多 $4.41\times10^{-17}$。
- **Uncertainty:** exact singular fixtures 不定量说明 near-pole transition 或 tolerance 敏感性。
- **Decisive test:** 在扩展到 search domain 前，对每个 factor 做 near-threshold sweep，并确认
  availability 只在预注册 gate 处翻转、无 singular solve。

## E. Implementation audit

### 九块矩阵与方向

冻结 unknown 顺序

$$
  z=(\xi,a_c^-,b_c^+,b_c^-,a_c^+,a_f^-,b_f^-,b_f^+,a_f^+)^T
$$

与九组 rows 一致，维数为 $n+8p$。lead rows 的非零结构应逐块固定为：

| row group | equation | nonzero variable blocks |
|---|---|---|
| 4 | $b_f^- -R_L^-a_f^- -T_{RL}^-b_c^-=0$ | 4, 6, 7 |
| 5 | $a_c^- -T_{LR}^-a_f^- -R_R^-b_c^-=0$ | 2, 4, 6 |
| 6 | $a_f^-+b_f^-=0$ | 6, 7 |
| 7 | $b_c^+ -R_L^+a_c^+ -T_{RL}^+b_f^+=0$ | 3, 5, 8 |
| 8 | $a_f^+ -T_{LR}^+a_c^+ -R_R^+b_f^+=0$ | 5, 8, 9 |
| 9 | $a_f^++b_f^+=0$ | 8, 9 |

不存在行列数或传播方向矛盾。

### Center direct phase

`construct_S` 的 convention 是

$$
  \begin{bmatrix}b^L\\a^R\end{bmatrix}
  =\begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
   \begin{bmatrix}a^L\\b^R\end{bmatrix},
$$

且 direct phase 只加在 transmissions。因此 center rows 必须使用

$$
  J_{LL}=J_{RR}=0,\qquad J_{LR}=J_{RL}=E_c,
  \qquad E_c=\operatorname{diag}(e^{\mathrm{i}\gamma_m(X_R-X_L)}).
$$

冻结设计正确。必须直接调用以 $X_L,X_R$ 为两种 phase origins 的 `incident_rhs`；
`scat_ld_lead_in` 把左右 incident densities 都锚在 $X_-$，不能不经换相位复用。

### Raw Schur 与 reduced oracle

保留 columns 2--3 和 row groups 5、7，消去 columns
$(1,4,5,6,7,8,9)$ 与 row groups $(1,2,3,4,6,8,9)$，消元块是
$(n+6p)\times(n+6p)$。Dirichlet-terminated maps 为

$$
\begin{aligned}
  \widehat R_-&=R_R^- -T_{LR}^-(I+R_L^-)^{-1}T_{RL}^-,\\
  \widehat R_+&=R_L^+ -T_{RL}^+(I+R_R^+)^{-1}T_{LR}^+.
\end{aligned}
$$

令 $R_d=\operatorname{diag}(\widehat R_-,\widehat R_+)$，则 reduced matrix 是
$I-R_dS_c$，不是 $I-S_cR_d$。冻结的 $p=2$ fixture 有相对 commutator $0.420$，且错误顺序
作用于已知 $x$ 的 residual 为 $0.254$，足以使乘法次序可证伪。实施中 raw Schur 与
reduced oracle 只能共享原始 blocks，不能共享消元/重排 helper 或从一方返回值构造另一方。

### Far Dirichlet 与法向

far rows 是 amplitude identities $a_f^-+b_f^-=0$ 与 $a_f^++b_f^+=0$；不含
$\Gamma$、Neumann trace 或 outward-normal sign。`select_port_traces` 中左 center port 的
$N_{\mathrm{out},-}=-N_R$、右 center port 的 $N_{\mathrm{out},+}=N_L$ 只适用于 Cauchy
trace conversion，不得移入 far rows 或 direct-phase blocks。

### Numerical and reproducibility risks

- $n,p$、unknown/row offsets、center blocks、phase origins、density/port scaling 和 tolerances
  必须跨 $j$ 固定；只有上述八个 lead scattering blocks 可变。
- `D_h` fingerprint 必须包括 node order、`ntot`、$h$、speed vector 和 duplicated density-block
  order；只比较尺寸不足以发现 level-dependent representation drift。
- Wood、one-cell/doubling factors、$A_c$、terminal factors 和 raw-Schur eliminated factor
  任一失败都必须进入 ledger；禁止 `pinv` 或用零矩阵代替 unavailable map。
- actual variable-speed ellipse 的隔离 scaling path、center/zero/terminal multi-reason
  propagation 已有结果；仍未做 near-threshold sensitivity、一般 variable-speed production
  helper 验证或连续算子误差分解。

## F. What survived

1. 九块 unknown/row ordering、每组 signs、directions 和 dimensions 自洽。
2. 从当前 `construct_S` convention 推出的 direct blocks
   $J_{LR}=J_{RL}=E_c$、$J_{LL}=J_{RR}=0$ 正确。
3. 左右 Dirichlet termination formulas 与 reduced order $I-R_dS_c$ 正确。
4. $p=2$ dense nonsymmetric fixture 明确非对易，并有已知 kernel、gap 和多个 mutation
   residual；它能抓住 reversed order、wrong phase、terminal sign 与 port swap。
5. center ellipse 的 scaled/unscaled similarity cross-check 能暴露圆形测试隐藏的坐标错误。
6. 固定 $(n+8p)$ representation 和仅 lead blocks 随 $j$ 变化的要求正确。
7. algebra GO 与 root GO 的分离符合 Phase 4 已冻结的方法门槛。
8. shared availability gate 在可用时保留数值对象，在未定义时保留 raw
   evidence 并写入 fixed-size `NaN` sentinels；这一 failure contract 经正负例共用路径
   验证。

## G. Minimal resolution

本阶段的 blocking repairs、stable rerun 和 skeptic 只读核对已完成。能改变
`ROOT_READY=STOP` 的最小下一阶段 gate 是：

1. 建立 center BIE 的 continuous kernel--field equivalence，并排除相关
   representation nullspace；
2. 在拟议搜索域上证明/检查 Wood、center BIE、doubling 与 terminal factors 的
   pole-free/branch-consistent conditions；
3. 只有通过上述 gate 后，才可设计 root isolation、multiplicity 和独立物理 reference
   实验。

因此本审计授权 `STAGE2_DISCRETE_ALGEBRA_GO`，不授权任何 root、eigenvalue 或
estimator claim。

## H. Open gaps

- frozen handoff/revision 已落盘为
  [[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie|aug-bie v1.0]]，并经逐节核对；已审
  blocks、metrics 或 gates 后续不得静默改变。
- Engineer 已用 Octave 完成最终 source-changed baseline 和 unchanged-source repeat；本
  skeptic 只用 Octave 读取 `results.mat`，没有独立重跑实验。最终输出的数值、
  hash、availability 与 reproduction gates 均经只读核对通过。
- actual ellipse 的 BIE rcond、scaled/unscaled agreement、$j=0{:}6$ Schur agreement 与
  shared availability gates 已在 stable run 中共同通过。
- 未证明 center BIE 的 continuous uniqueness、representation injectivity 或 field
  reconstruction equivalence。
- 未建立包含搜索域的 pole-free/branch-consistent neighborhood。
- 未验证 `construct_S` 在一般 variable-speed geometry 上的历史输出；本轮只审查 Stage 2
  隔离修正，不授权修改 production helper。
- 未审查 root isolation、root conditioning、adjacent-level matching、estimator 或独立物理
  reference。

## Open-problem handoff

按当前工程论文目标重新评估的分类和最小后续检查统一维护在
[[research/projects/eig-apost/implementation/open-problems#I2|I2 open-problem ledger]]。
以上历史审查原文保持不变，不作追溯性改判。
