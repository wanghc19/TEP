# I2.3 Rayleigh/Fourier 阶数单轴 candidate 漂移设计

## 1. 状态、问题与结论边界

- Origin Skill: `academic-research-suite / experiment-agent`
- Design ID: `I2.3-M-DRIFT-V1`
- Design Status: `FROZEN RESEARCHER--ENGINEER AGREEMENT / SKEPTIC DESIGN REVIEW PENDING`
- Freeze Date: `2026-08-14`
- Claim Boundary: `CONDITIONAL EMPIRICAL THREE-LEVEL SAVED-CANDIDATE DRIFT`

### Researcher--Engineer agreement

Researcher 与 Engineer 在实现前已明确 `AGREED`：唯一 levels 为 $M=32,40,48$；固定
$n_{\mathrm{tot}}=160$ 与 fine proxy；每个 $M$ 独立 seed/frame；production 使用 natural-half
selectors，alternate 使用本设计冻结的 parent permutation过滤/重映；candidate functional、
locator、公共 coefficient/wall/probe identity、direct saved-candidate drift、failure语义及
600/1200秒、512 MiB资源门均以本文件为唯一合同。该 agreement 只授权形成 design candidate；
实现完成后仍须 Skeptic 独立跑前审查。

### Revision A：a1 preflight失败与a2机械修复

正式 `m-drift-a1` 在 config preflight失败，wall time为22.177848167秒、exit code为1，
`eval_i21` 调用数为0，且没有创建 output目录或artifact。终端原文为：

```text
Subscripted assignment between dissimilar structures.
```

stack为 `LOCAL_config` line 199 / `check_m_drift` line 32；error identifier未显示，记录为
`NOT_RECORDED`。原因是无字段 `struct([])` 随后接受八字段 whole-element struct赋值。该tag虽无
artifact仍视为已消费，不得复用或重试。

Researcher--Engineer明确 `AGREED`、Skeptic接受的 Revision A 只把它改为同字段、同顺序的
$1\times3$ struct array预分配，并将唯一后续正式tag改为 `m-drift-a2`。a2的 `result.mat` 记录
`prior_failed_attempt_count=1`、上述a1 failure summary与 `retry_count=0`。本修订不改变 $M$、
$K$、阈值、窗口、locator、winner、$A_{\mathrm{phys}}$、identity、资源门、evaluator或任何数学
解释。实验入口与运行记录见 [[test/i2/m-drift/README|M-axis experiment index]]。

本实验只回答一个问题：固定圆盘 Nyström 阶数、几何、物理参数、proxy、求解器、扫描窗口、
网格规则、candidate functional 和 winner 规则时，只改变人工边界保留的 Rayleigh/Fourier
阶数 $M$，算法保存的同一数值 mode candidate 是否发生观测漂移。

对每个 $M$，算法交付的 candidate 是冻结 locator 返回并保存的 terminal-grid winner
$\widehat k_M$。candidate drift 直接定义为

$$
\Delta^{\mathrm{cand}}_{ab}=\widehat k_{M_b}-\widehat k_{M_a}.
$$

terminal interval 半宽只作潜在连续-$k$ score minimizer 的 search-resolution diagnostic；
它不是 $\widehat k_M$ 的 uncertainty，不进入 candidate drift，也不构成 I3 停止门。

本实验不证明 sub-grid minimizer、finite root 或 continuous eigenvalue 的漂移，不给收敛阶、
saturation、误差归因、posterior estimator 或误差上界。candidate 有漂移、无漂移、mode switch、
mode identity unresolved 或 candidate unresolved 都是合法输出；不得为得到预期结果修改 $M$、
窗口、网格、阈值或解释。

## 2. Authority 与不可变 parents

项目级对象分离和当前 I2.3 解释由
[[research/projects/eig-apost/DECISIONS|project decisions]]、
[[research/projects/eig-apost/implementation/i2/README|I2 guide]] 和
[[research/projects/eig-apost/implementation/i2/review-2-3|ntot-axis review]] 支配。
此前的 $n_{\mathrm{tot}}$ 单轴设计、runner 和 append-only output 保持不变；统一入口为
[[test/i2/k-drift/README|ntot-axis experiment index]]。

本实验复用正常 MATLAB path 上唯一的 `eval_i21` 及其必要 package dependencies，但不修改
I2.1 evaluator、`check_k_drift.m` 或任何已有 output。MATLAB runtime 不读取 Git、Markdown、
freeze、manifest、历史 MAT 或旧 output。parent/source identity 只在运行前由静态审查核对。

I2.1 count one 使用 $n_{\mathrm{tot}}=256,M=48$；本实验固定
$n_{\mathrm{tot}}=160$，因此该 count 不直接附着于本实验的任何 level，包括 $M=48$。
本阶段不为任何 $M$ 重跑 contour count。

旧 `drift-a1` 的 $n_{\mathrm{tot}}=160,M=48$ point 使用一个由
$n_{\mathrm{tot}}=256,M=48$ seed产生的 common frame；本实验的 $M=48$ level则按本设计在
$n_{\mathrm{tot}}=160$ 独立产生 seed/frame。因此旧 candidate 和 mode identity不是本实验的
algorithmic parent，不设必须相等的运行门。跑后独立 review预注册一项只读 context comparison：
比较旧 `drift-a1` 的 $n_{\mathrm{tot}}=160,M=48$ 与新 $M=48$ 的 saved candidate difference、
weighted wall/probe overlap及最低 residual/factor状态。该 comparison不进入 runtime、不改变
本实验内部三层 verdict；任何差异只能作为 frame-context caveat报告。

## 3. 唯一离散轴与三个 levels

唯一科学轴为

```text
PORT_RAYLEIGH_FOURIER_CUTOFF_M_AT_FIXED_NTOT160_FINE_PROXY
```

预注册三个严格递增 levels：

$$
M\in\{32,40,48\},
\qquad K=2M+1\in\{65,81,97\}.
$$

$M=32$ 与冻结 proxy plane-wave order 相接，$M=40$ 是等步中间层，$M=48$ 是既有最高
trace order。不得运行后替换、增删或重排 levels。

| Field | $M=32$ | $M=40$ | $M=48$ | Semantics |
|---|---:|---:|---:|---|
| `level.ntot` | 160 | 160 | 160 | fixed |
| `N_side,N_top,N_proxy_edge,M_pw` | 160,160,80,32 | same | same | fixed fine proxy |
| $K=2M+1$ | 65 | 81 | 97 | axis-derived |
| `A_QP` order | 320 | 320 | 320 | fixed by `ntot` |
| proxy / shifted proxy | $960\times450$ / $1920\times450$ | same | same | fixed |
| scattering RHS columns | 130 | 162 | 194 | $2K$ |
| pencil / $A_{\mathrm{def}}^D$ | 130 | 162 | 194 | $2K$ |
| graph $A_{\mathrm{def}}^G$ | 260 | 324 | 388 | $4K$ |
| stable / unstable dimension | 65 / 65 | 81 / 81 | 97 / 97 | $K/K$ |

物理参数固定为 $\beta=0.5$、$d=1$、$R=0.2$、$s=1$、
$X_L=-0.5$、$X_R=0.5$、proxy height $1.1$ 与 proxy distance $0.2$。
double precision、MATLAB public `lsqminnorm`、branch convention、wall labels、normal signs、
QZ ordering rule、chart rule、candidate functional、solver 和所有非 $K$-派生阈值均固定。

改变 $M$ 会共同改变 Fourier basis、RHS/extractors、pencil、graph、weights 和矩阵维数。
这些都是单一 trace-cutoff axis 的派生结果；本实验不得把 observed drift 单独归因给其中某一项。

### 3.1 完整 evaluator 与本实验阈值

除明确写成 $K$-scaled 的项外，三个 levels 使用完全相同的数值：

| Gate | Frozen value |
|---|---:|
| proxy rank ratio | $10^{-8}$ |
| proxy rank gap | $2$ |
| proxy projector repeat | $10^{-10}$ |
| proxy reduced/full/shifted factor rcond | $10^{-8}$ |
| proxy projected residual | $10^{-11}$ |
| proxy full/shifted residual | $10^{-5}$ |
| proxy seed identity | $10^{-12}$ |
| branch identity | $10^{-12}$ |
| QZ residual | $10^{-10}$ |
| QZ continuation overlap | $0.9$ |
| cross-cluster chordal margin | $100K\epsilon_{\mathrm{mach}}$ |
| fixed-row / Dirichlet chart margin | $100K\epsilon_{\mathrm{mach}}$ |
| fixed-row / chart condition times epsilon | $10^{-9}$ |
| fixed-row / chart small-solve residual | $10^3K\epsilon_{\mathrm{mach}}$ |
| BIE factor rcond | $10^{-8}$ |
| BIE solve residual | $10^{-10}$ |
| graph Schur residual | $10^3K\epsilon_{\mathrm{mach}}$ |
| Dirichlet factor rcond | $10^{-8}$ |
| graph lift / D/N boundary residual | $10^{-10}$ |
| candidate score / $r_{12}$ | $10^{-3}$ / $0.1$ |
| raw left/right backward error | $10^{-8}$ |
| SVD triplet residual | $10^3(2K)\epsilon_{\mathrm{mach}}$ |
| center / graph / wall / probe participation | $10^{-3}$ |
| adjacent primary overlaps | $0.99$ |
| primary--secondary cross-overlap | $0.5$ |
| repeat matrix / score | $10^{-12}$ / $10^{-12}$ |
| repeat coefficient overlap | $1-10^{-10}$ |
| selector-gauge matrix / score | $10^{-12}$ / $10^{-12}$ |
| selector-gauge representation overlaps | $1-10^{-10}$ |

`eval_i21` 返回的每一个 factor必须 `available=true` 且 `pass=true`；不得在 runner 中另选
较宽阈值。neutral/indeterminate counts必须为零，所有 finite guards必须通过。上述常数和公式
逐项进入 test-local config；不得只以“继承 evaluator默认值”代替。

## 4. Per-$M$ frame、selectors 与 gauge oracle

每个 $M$ 在同一 $k_\star$ 独立建立 port branch、QZ seed frame 和 fixed chart。不得截断或复用
$M=48$ 的 `seed_Z`，也不得跨 $M$ continuation QZ subspace。

production primary selectors 使用同一维数派生规则：

$$
\mathcal R_+(M)=1{:}K,
\qquad
\mathcal R_-(M)=K+1{:}2K.
$$

这条规则不读取 candidate、score 或运行结果。每个 level 必须记录完整 selector 顺序、fixed-row
margin/condition/residual、Dirichlet chart condition 与 solve residual。

为防止 row ordering 制造伪 $M$ drift，冻结一个 seed-only alternate gauge oracle。取既有
$M=48$ plus/minus selector permutations，按 Fourier 标签保留 $|m|\le M$ 后重映到当前
$1{:}K$ 与 $K+1{:}2K$。在同一个 per-$M$ raw seed QZ basis 上，用 alternate order 重新计算
normalization、$D_\pm,N_\pm,\Lambda_\pm,A_{\mathrm{def}}^D$、physical weighting 和 mode，
不增加 evaluator 调用。要求：

$$
\frac{\|A_{\mathrm{def,alt}}^D-A_{\mathrm{def}}^D\|_F}
{\max(1,\|A_{\mathrm{def}}^D\|_F)}\le10^{-12},
$$

$$
|s_{1,\mathrm{alt}}-s_1|\le10^{-12},
$$

且 raw coefficient、weighted wall trace 与九点 probe field 的 phase/scale-invariant overlap
都至少为 $1-10^{-10}$。alternate fixed-row 和 Dirichlet solves 必须 full rank、finite，并满足
与 production chart 相同的 $K$-scaled门。失败分类为 `SELECTOR_GAUGE_DRIFT`；不得换 selector。

alternate 的两项 $M=48$ parent permutations在本设计中直接冻结为：

```text
plus48 = [89 41 35 71 92 12 16 10 66 70 93 33 9 69 79 30 36 ...
  62 64 84 95 40 18 91 94 58 61 13 85 90 24 32 42 60 28 74 21 ...
  97 22 55 77 96 38 14 17 2 20 1 67 75 37 43 72 5 80 81 82 7 ...
  68 39 25 19 78 29 6 76 86 59 8 4 65 83 23 31 3 73 57 63 56 ...
  26 88 27 11 87 15 34 54 44 53 45 52 46 51 47 50 48 49]

minus48 = [162 132 117 174 103 124 134 140 173 194 101 172 186 ...
  120 167 168 170 178 189 100 153 180 192 110 118 121 125 169 175 ...
  176 185 119 160 164 179 108 113 114 131 165 171 183 193 111 128 ...
  133 139 159 181 190 191 106 129 157 163 135 116 127 155 177 102 ...
  104 126 130 137 156 184 109 138 187 115 136 154 161 166 158 123 ...
  98 122 105 188 112 152 99 182 107 151 141 150 142 149 143 148 ...
  144 147 145 146]
```

它们与历史 `check_k_drift.m` 的 frozen selectors逐元素相同，但本实验 runtime只使用上面
写入新入口的数值，不读取旧源码。对 `plus48` 中的旧行 $r$，令 $m=r-49$；保留
$|m|\le M$ 并重映为 $m+M+1$。对 `minus48` 中的旧行 $r$，令 $m=r-146$；保留
$|m|\le M$ 并重映为 $K+m+M+1$。必须得到当前 top/bottom half各自的完整排列；否则
在任何数值计算前失败。

## 5. Candidate functional

对每个 $M$ 和每个实 $k$，令 $A_M=A_{\mathrm{def}}^D(k)$。按 Fourier orders
$m=-M{:}M$ 定义

$$
b_m=\sqrt{1+|\beta_m|^2},
\qquad
w_{r,m}=b_m^{-1/2},
\qquad
w_{c,m}=\left(b_m+\frac{|\gamma_m|^2}{b_m}\right)^{-1/2}.
$$

将权重复制到左右 port blocks，定义

$$
B_M=A_{\mathrm{phys},M}=D_{r,M}A_MD_{c,M},
\qquad
s_1(k;M)=\frac{\sigma_{\min}(B_M)}{\sigma_{\max}(B_M)}.
$$

这是所有 levels 唯一的 locator functional。每个实际求值点保存完整 $2K$ 奇异值、
$s_1$ 与 $r_{12}=\sigma_1/\sigma_2$。不同维数下 score 的大小只服务各自相同规则的 locator，
不得被单独解释为 score convergence。

若 $B_Mv_1=\sigma_1u_1$，则 raw right port vector与 raw left algebraic covector为

$$
q=D_{c,M}v_1,
\qquad
\ell^*=u_1^*D_{r,M}.
$$

最低 candidate 门保持：$s_1\le10^{-3}$、$r_{12}\le0.1$；raw left/right normalized
backward error 不超过 $10^{-8}$；SVD triplet residual 不超过
$10^3(2K)\epsilon_{\mathrm{mach}}$。

## 6. 固定窗口与 locator

三个 levels 使用完全相同的 I2.1 实直径：

$$
I_0=[1.8327699661254881,\;1.8327707290649411],
$$

中心和半径为

$$
k_\star=1.8327703475952146,
\qquad
r_0=3.8146972647368216\times10^{-7}.
$$

每个 $M$ 独立运行同一五点 dyadic locator：

1. 在当前 interval 的五个等距点求值，并缓存相同 double $k$；
2. 所有 node gates 先通过，score 才可参与排序；
3. 最小 score 必须唯一、严格位于三个 interior nodes，且 runner-up gap 大于 $10^{-12}$；
4. 下一 interval 是 winner 的两个相邻点；
5. 固定运行 $L=0,\ldots,11$，正常 terminal spacing 为
   $9.3132279666\times10^{-11}$；每层正常共有 27 个唯一求值点；
6. 禁止插值、拟合、移动或扩张窗口、golden-section、Newton、Brent 或 complex refinement。

保存的 candidate 是 terminal-grid winner $\widehat k_M$。terminal interval 和半宽仅描述
潜在 sub-grid minimizer 的定位尺度。endpoint winner、tie、node failure 或无法到达 terminal
spacing 都返回 `CANDIDATE_UNRESOLVED`；这是合法结果，不允许在同一 attempt 中改窗补救。

## 7. Node 与 candidate 最低健康门

每个实际 node 必须满足：

- `node.pass=true`，实际 $M,K,n_{\mathrm{tot}}$、proxy、RHS、pencil、chart、
  $A_{\mathrm{def}}^{D/G}$ 尺寸与 Section 3 一致；
- stable/unstable 为 $K/K$，neutral/indeterminate 为零；branch、QZ、overlap、fixed-row、
  chart、proxy、BIE、Schur 和所有 factors 通过冻结 evaluator 门；
- shared Fourier labels上的 $\beta_m$ 必须完全相同，$\gamma_m$ 与 phase 的跨-$M$ 差不超过
  $10^{-12}$；proxy shape、rank 与 seed fingerprint相同；
- 所有矩阵、weights、scores 和 singular values finite。

terminal candidate 还必须记录并通过：

- raw left/right residual 与 backward error；
- SVD triplet residual；
- $A_{\mathrm{def}}^G$ lift/Schur parity；
- Dirichlet 与 Neumann boundary defects 各不超过 $10^{-10}$；graph kernel defect 原样记录，
  但不另设结果导向阈值；
- center 与 graph participation，各至少 $10^{-3}$；
- 所有直接相关 factor health。

以上任一失败都保留该 level 的已有数值，但不把它连接成 qualified hierarchy。

## 8. 跨维公共 mode identity

### 8.1 三个公共表示

令 $M_{\max}=48$。所有按 Fourier order 标记的向量都通过零填充嵌入
$m=-48{:}48$；低 $M$ 不复制未知高阶系数，高 $M$ tail 不被截掉。

第一表示是 physical-weight coordinate

$$
p=D_{c,M}^{-1}q=v_1,
$$

将左右 blocks 分别零填充到共同 $2(2M_{\max}+1)$ 空间。

第二表示由 raw $q=(q_L,q_R)$ 构造。令
$E_M=\operatorname{diag}(e^{\mathrm i\gamma_m(X_R-X_L)})$，则

$$
d_L=q_L+E_Mq_R,
\qquad
d_R=E_Mq_L+q_R,
$$

$$
t_M=\begin{bmatrix}\sqrt b\,d_L\\ \sqrt b\,d_R\end{bmatrix},
$$

再按 Fourier labels 零填充到共同 weighted wall-trace 空间。

第三表示是在固定九点

$$
\mathcal P=\{(x,y):x,y\in\{-1/4,0,1/4\}\}
$$

重构的 physical probe field：

$$
f_M(x,y)=\frac1{\sqrt d}\sum_{m=-M}^{M}
\left[q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}+
q_{R,m}e^{-\mathrm i\gamma_m(x-X_R)}\right]e^{\mathrm i\beta_my}.
$$

三个表示都必须 finite、nonzero；wall/probe participation 相对 $\|q\|_2$ 至少为
$10^{-3}$。另记录高 $M$ 在低 $M$ 公共子空间之外的 coefficient 与 wall-trace tail fraction；
tail 不单设结果导向阈值，因为完整零填充 overlap 已包含它的影响。

### 8.2 相邻 identity 与 competitor

对相邻 $(32,40)$、$(40,48)$，使用

$$
\rho(x,y)=\frac{|x^*y|}{\|x\|_2\|y\|_2}
$$

计算 phase/scale-invariant overlap。要求 primary $p$、wall trace 与 probe field overlaps
都至少为 $0.99$。用 wall inner product 对高 $M$ 结果做 phase alignment只作审计，不改变
overlap verdict。

第二右 singular vector $v_2$ 也通过相同 $q_2=D_{c,M}v_2$、零填充、wall 与 probe 映射。
primary--secondary 的三个公共表示必须双向检查，全部 cross-overlaps 的最大值不超过 $0.5$。
若 primary gates 和 competitor gates 都通过，分类 `SAME_MODE`；若 competitor 表明混线，分类
`MODE_SWITCH`；表示、secondary 或 mapping 不可用则为 `MODE_IDENTITY_UNRESOLVED`。

不得按 candidate 数值最近、QZ eigenvalue 最近或不同维 raw $q$ 直接 overlap 来认定同一 mode。
$(32,48)$ 的 identity 只报告，不作为附加 hard gate。

shared overlap helper 在运行前用固定非平凡缩放/相位
$10^8e^{\mathrm i\pi/7}$、$10^{-8}e^{-\mathrm i\pi/7}$、正交向量和 unavailable case
验证；oracle verdict 不含预期生产答案。

## 9. Repeat 与 candidate drift

每个 terminal candidate 在同一 per-$M$ frame 下重算一次。要求：

- $A_{\mathrm{def}}^D$ relative Frobenius difference不超过 $10^{-12}$；
- $s_1$ difference不超过 $10^{-12}$；
- common physical coefficient overlap至少为 $1-10^{-10}$；
- factor availability/pass pattern、dimension、selectors、branch/QZ/chart signature一致。

repeat只检查 fixed-candidate reproducibility，不证明 winner ranking 或 sub-grid minimizer 稳定。

仅当两个 levels 都有通过的 candidate 且 identity 为 `SAME_MODE` 时，直接计算
$\Delta^{\mathrm{cand}}_{ab}$ 和 $|\Delta^{\mathrm{cand}}_{ab}|$：

| Condition | Candidate-drift label |
|---|---|
| $\Delta^{\mathrm{cand}}_{ab}=0$ | `NO_OBSERVED_CANDIDATE_DRIFT` |
| $0<|\Delta^{\mathrm{cand}}_{ab}|\le10^{-6}$ | `OBSERVED_CANDIDATE_DRIFT_SUBTARGET` |
| $|\Delta^{\mathrm{cand}}_{ab}|>10^{-6}$ | `OBSERVED_CANDIDATE_DRIFT_SEVERE` |

$10^{-6}$ 是运行前冻结的项目尺度，不从 observed drift、terminal cell 或 score 调整。
terminal half-width单独报告，不与 candidate difference相加或比较。大、小、零或非单调 candidate
drift 都是有效结果。mode switch、identity unresolved 或 candidate unresolved 则不强行形成
same-mode drift pair。

只要三个 candidate、两项相邻 `SAME_MODE`、最低健康门和 repeats 全部通过，就形成
`CONDITIONAL_ALGORITHMIC_M_AXIS_HIERARCHY`；candidate 是否相同不影响该流程 verdict。

## 10. 实现、证据与失败语义

实验目录为 `test/i2/m-drift/`。唯一新 MATLAB 入口为 `check_m_drift.m`，stem 为13个字符；
它是单一 function file，内部只放本实验必要的 `LOCAL_` helpers，不新增其他 MATLAB 文件，
不调用或修改 `check_k_drift.m`。

Revision A 后唯一正式 tag 为 `m-drift-a2`，输出严格为：

```text
test/i2/m-drift/output/m-drift-a2/result.mat
test/i2/m-drift/output/m-drift-a2/report.md
```

已有同名目录时必须在计算前拒绝；单进程、单 attempt、不得自动 retry。runtime 只依赖 MATLAB、
`eval_i21` 和实际 package functions；不得读文档、Git、freeze、历史 output 或固定仓库路径。

`result.mat` 至少保存：完整 config、runtime paths、per-$M$ seed/frame摘要、primary/alternate
selectors与 gauge metrics、所有实际 locator $k$/score/singular values、terminal intervals、三个
candidates与最低 raw diagnostics、common representations、identity/competitor metrics、repeats、
direct candidate drifts、资源、first failure 和 claim boundary。`report.md` 简洁列出用户要求的
candidate、terminal minimizer scale、residual/factor/field/boundary、mode identity、signed/absolute
drift、命令、时间、memory、失败/retry和 caveats。

执行错误、对象尺寸/branch/QZ/chart/factor/gauge failure、candidate unresolved、mode switch 和
mode-identity unresolved必须保留首个失败和已有数据。不得自动换 $M$、窗口、selector、阈值或
算法。若 failure发生在 output创建前，终端命令输出是该失败记录；同 tag 不重试。

## 11. 资源预算与唯一命令

每个 $M$ 恰有一个 seed，正常 locator 包含该中心点并总计27个唯一点，另有一个 terminal repeat。
三层合计84次 evaluator 调用；alternate gauge只重用 raw seed对象，不新增 evaluator call。
最大 dense objects为 $A_{\mathrm{def}}^G\in\mathbb C^{388\times388}$、
$A_{QP}\in\mathbb C^{320\times320}$ 和固定 proxy rectangles。

根据 `drift-a1` 的84次同类调用成本以及低 $M$ 的较小 dense matrices，预估 wall time为
150--220秒，peak active-object memory低于200 MiB。冻结 soft target 600秒、hard acceptance gate
1200秒、active-object snapshot gate 512 MiB。hard gate是 evaluator调用间检查，不是异步 watchdog。

从 repository root运行的唯一正式命令为：

```sh
matlab -batch "addpath(fullfile(pwd,'test','i2','m-drift'),fullfile(pwd,'test','i2','k-count')); check_m_drift('m-drift-a2');"
```

未经 Skeptic 对冻结设计和实现的一致性给出独立跑前通过，不得执行该命令。

## 12. 验收与结论边界

正式 review 必须逐项回答：

1. $M=32,40,48$ 是否是唯一变化的科学轴，所有固定量是否一致；
2. 每个 level 是否得到 saved candidate、terminal minimizer diagnostic与最低健康证据；
3. 相邻 candidates 是否经三个公共表示判为 `SAME_MODE`、`MODE_SWITCH` 或
   `MODE_IDENTITY_UNRESOLVED`；
4. 每对 qualified candidates 的 signed/absolute direct drift是多少；
5. 是否观察到严重 candidate drift，判据是否仍为预注册 $10^{-6}$；
6. 是否形成 conditional algorithmic M-axis hierarchy；
7. 实际命令、总耗时、peak口径、失败和 retry次数；
8. 哪些 caveats仍阻止 minimizer/root/convergence/continuous-error解释。

通过的 same-mode hierarchy只说明：在固定 `ntot=160` 和完全相同的扫描算法下，三个不同
Rayleigh/Fourier cutoffs交付了可直接比较的离散 candidates。它不说明 candidate 稳定性等于
连续谱收敛，也不把有限层漂移变成误差上界。
