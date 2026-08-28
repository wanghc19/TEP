# I4.1a 独立 FEM supercell reference 数值实验设计

## Material Passport

- Origin Skill: `academic-research-suite / experiment-agent`
- Origin Mode: `plan`
- Origin Date: `2026-08-28`
- Verification Status: `UNVERIFIED / DESIGN REVIEW PENDING`
- Version Label: `i4_1a_design_v1`

## 0. 状态、目的和权限边界

- **Design ID:** `I4.1A-FEM-SUPERCELL-REFERENCE-V1`
- **Researcher:** `BOUNDED REVISION COMPLETE / GO TO SAME SKEPTIC RE-REVIEW`
- **Skeptic:** `RE-REVIEW PENDING`
- **Implementation:** `NOT STARTED`
- **Formal run:** `NOT AUTHORIZED UNTIL DESIGN AND SPEC-TO-CODE REVIEWS PASS`
- **唯一 future attempt tag:** `femref-a1`
- **唯一 active experiment directory:** `test/i4/femref-a1/`

本设计把已通过方法审查的
[[research/projects/eig-apost/implementation/i4/method-4-1|I4.1 independent-reference method]]
具体化为一次盲态 reference-production experiment。实验只用自包含、基于 MATLAB base
functionality 的 geometry-fitted conforming $P_1$ FEM，计算 fixed-$\beta$ bulk projected gap 和
该 gap 内的完整 supercell defect branch/cluster inventory。它不调用 current BIE/QZ chain，不读取
I3 estimator、candidate、density、field、review、Markdown、Git 或历史 output。

I4.1a 的终点是揭盲前冻结的 empirical reference collection，或一个具有完整 ledger 的合法失败
状态。它不计算 effectivity ratio；只有本次 reference artifact 经 post-run Skeptic review 接受后，
才能在另行设计的 reveal/comparison gate 中输入 current candidate 和 estimator。这样可避免在
reference mesh、branch selector 或 stop rule 中泄漏 current information。

本轮不得修改现有 package/main code、I1--I3 历史产物或
[[research/projects/eig-apost/implementation/i4/method-4-1|method manuscript]]，不得创建第二个
attempt。本设计受
[[research/projects/eig-apost/implementation/i4/method-review|method review]] 的 empirical
claim boundary 约束。

## 1. 研究问题、成功标准和 claim boundary

### 1.1 精确问题

在不消费 current BIE/QZ information 的条件下，自包含 fitted FEM supercell 是否能在冻结的
资源预算内：

1. 独立解析 fixed-$\beta$ ordinary lead 的目标 projected gap；
2. 枚举该 gap 内每一个 observed defect branch/cluster，而非选择某个最近 root；
3. 用 FEM/geometry、supercell width、twist resolution 和 algebraic tolerance 四个轴形成逐支
   empirical resolution ledger；
4. 输出全部 qualified branches 的
   $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$、fields 和
   $\boldsymbol\Delta_{\mathrm{ref}}^{\mathrm{obs}}$，或 fail closed？

### 1.2 一级成功状态

只有以下各门同时通过，才输出 `REFERENCE_COLLECTION_READY`：

- continuous specification identity 和 quasiperiodic seam checks 通过；
- independent bulk gap、edge refinement 和 whole raw-gap edge-buffer gate 通过；
- finest spectrum inventory 的上下 sentinel、所有 twist slices 和 cluster bookkeeping 通过；
- every observed localized branch 均已延拓、分类并通过 branch-wise multi-axis resolution；
- coverage ledger 中没有未分配 root、未解析 cluster、edge ambiguity 或失踪 branch；
- 至少一条 localized branch qualified；
- 运行未越过 wall-time/memory hard limits。

`NO_LOCALIZED_BRANCH` 只有在 bulk gap 和全 inventory/coverage 均通过、raw-gap edge buffer 中没有
任何 eigenobject，且没有任何 root 通过冻结的 observed localization screen 时，才是有效负结果。
它只表示 `NO BRANCH QUALIFIED UNDER THE FROZEN OBSERVED SCREEN`，不否定 continuous guided mode
存在。其他 scientific failures 仍可构成执行完整、可审查的 negative artifact，但不得导出非空
reference truth。

### 1.3 允许与禁止的结论

若 `REFERENCE_COLLECTION_READY`，只允许称 finest result 为 **independent empirical observed
reference collection**。即使所有 refinement changes 很小，也不得声称：

- certified $\varepsilon_{\mathrm{ref}}$ 或 true-error upper bound；
- continuous gap-discrete spectrum 的 certified completeness/count；
- continuous eigenvalue existence、certified gap 或 I4.2 result；
- current estimator 的 effectivity、reliability 或 efficiency；
- 与 current field 同 mode，或某个 reference branch 是 nearest current root。

若揭盲后的 future denominator 不大于
$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$，应输出
`REFERENCE_RESOLUTION_DOMINATES`；不得回到本 attempt 调整 mesh、window、threshold 或 selector。

## 2. 冻结的 exact continuous problem

横向周期胞元为 $Y=(-1/2,1/2)$，无界波导为

$$
\Omega=\mathbb R\times Y.
$$

ordinary lead cell
$C_j=(j-1/2,j+1/2)\times Y$ 的中心为 $(j,0)$。除 $j=0$ 外，每个 cell 含半径
$R=0.2$ 的 exact sharp disk；中心整列缺失并保持 homogeneous background。系数为

$$
q(x,y)=
\begin{cases}
17,&(x-j)^2+y^2<R^2\text{ for some }j\ne0,\\
1,&\text{otherwise}.
\end{cases}
$$

固定 $\beta=0.5$，physical field 满足

$$
u(x,y+1)=e^{\mathrm i\beta}u(x,y).
$$

寻找 $k>0$ 和非零、沿 $|x|\to\infty$ 局域的 $u\in H^1_\beta(\Omega)$，使

$$
-\Delta u=k^2q u,
$$

且 exact circular interfaces 上 $u$ 与 $\partial_\nu u$ 连续。令 $\lambda=k^2$，弱形式为

$$
a(u,v)=\lambda m(u,v),\qquad
a(u,v)=\int_\Omega\nabla u\cdot\nabla\overline v,
\qquad
m(u,v)=\int_\Omega q u\overline v.
$$

这是 $A=I$、$B=q$ 的 scalar problem；实现若形成
$-\nabla\cdot(q^{-1}\nabla u)=\lambda u$ 或把 $\beta$ 乘上额外 period，立即输出
`CONTINUOUS_MODEL_MISMATCH`。权威连续对象见
[[research/projects/eig-apost/phase4-report/method|current continuous method]]。

## 3. 独立离散方法和 geometry contract

### 3.1 Bulk 与 defect supercell

bulk problem 使用 ordinary cell $(-1/2,1/2)\times Y$，对 $x$ 施加 Bloch phase
$e^{\mathrm i\alpha}$、对 $y$ 施加 $e^{\mathrm i\beta}$。对每个
$\alpha\in[0,\pi]$ 求 volume generalized eigenproblem。由于 coefficient 关于 $x$ reflection
对称，负 $\alpha$ 只作 symmetry identity，不另算一套；实现必须在 $\alpha=0,\pi$ 检查配对
seam，而不能仅凭口头使用该对称性。

defect supercell 为

$$
\Omega_N=(-N-1/2,N+1/2)\times Y,
\qquad L_N=2N+1,
$$

含 $j=-N,\ldots,-1,1,\ldots,N$ 的 ordinary disks，中心 $j=0$ 缺失。边界条件为

$$
u(x+L_N,y)=e^{\mathrm i\vartheta}u(x,y),
\qquad
u(x,y+1)=e^{\mathrm i\beta}u(x,y),
$$

其中 $\vartheta\in[0,\pi]$；负 twist 由同一 $x$ reflection symmetry 覆盖。每个
$\vartheta$ 直接组装 volume stiffness/mass forms，并求 lowest generalized eigenobjects。禁止
构造 BIE、DtN、RtR、QZ、one-cell map 或 current density。

### 3.2 自包含 fitted mesh

当前 MATLAB 安装没有 PDE Toolbox，本设计也不依赖 Gmsh、FreeFEM、MPB 或任何外部 mesher。
future implementation 只允许使用 base MATLAB 的 `delaunayTriangulation`、`triangulation`、
`sparse` 和 `eigs` 等普通功能。

每个 level 以规则 Cartesian background points、outer rectangle constraints 和每个 disk 的
regular inscribed polygon constraints 建立 deterministic constrained Delaunay mesh。polygon
vertices 位于 exact circle 上，segment count 是 $4$ 的倍数，故保持 $x/y$ reflection symmetry。
每个 polygon edge 必须是 mesh edge；材料 triangle 由其位于该 closed polygon region 内部判定。
因此每个 finite problem 是 sharp **polygon-interface** conforming FEM，而不是 curved-circle
exact geometry。continuous target 仍是第 2 节的 exact circle；polygonal variational crime 与
$P_1$ space 一起沿 FEM/geometry axis refinement，不得隐藏成 exact geometry。

为避免 boundary sliver，距离 polygon curve 小于 $h/3$ 的 background lattice point 被
deterministically 移除，再加入同角度的 radius $R/2$ interior ring 和 $R+h/2$ exterior ring。
outer periodic boundaries 保留完全相同的 node coordinates。任何 constraint 丢失、重复 node、
inverted triangle、跨 interface triangle 或最低角小于 $3^\circ$ 均输出
`MESH_QUALITY_UNRESOLVED`。

每个 level 保存两个几何诊断：

$$
\epsilon_{\mathrm{area}}(n_\Gamma)
=1-\frac{n_\Gamma\sin(2\pi/n_\Gamma)}{2\pi},
\qquad
\epsilon_{\mathrm H}(n_\Gamma)
=R\bigl(1-\cos(\pi/n_\Gamma)\bigr).
$$

它们分别是 inscribed polygon 的 relative area deficit 和 circle-to-chord Hausdorff distance。
这些量只核对 geometry refinement；不是 eigenvalue-error bounds。finest level 要求
$\epsilon_{\mathrm H}\le5\times10^{-4}$。

### 3.3 Quasiperiodic reduction

先在 full nodal mesh 上组装 real $K$、$M$，再由 master/slave prolongation $P$ 同时合并 top/bottom
和 left/right nodes：

$$
U_{\mathrm{top}}=e^{\mathrm i\beta}U_{\mathrm{bottom}},
\qquad
U_{\mathrm{right}}=e^{\mathrm i\phi}U_{\mathrm{left}},
$$

bulk 中 $\phi=\alpha$，defect 中 $\phi=\vartheta$；top-right corner 的 factor 必须为
$e^{\mathrm i(\beta+\phi)}$。reduced matrices 为

$$
K_{\phi}=P^*KP,\qquad M_{\phi}=P^*MP.
$$

必须保存 node-pair counts、corner factor、seam-coordinate mismatch 和 phase identity。若
任一对应坐标差超过 $10^{-13}$，或显式 seam residual 超过 $10^{-12}$，输出
`QUASIPERIODIC_SEAM_UNRESOLVED`。

## 4. 冻结搜索域和 independent bulk-gap gate

### 4.1 只作 cue 的宽区间

固定宽 cue interval 和 solver guard 为

$$
I_{\mathrm{cue}}=[1.65,2.05],
\qquad
I_{\mathrm{guard}}=[1.25,2.45].
$$

$I_{\mathrm{cue}}$ 只登记目标物理频带的大范围，不含 current saved candidate 的精确值。任何 root
通过、branch ranking 或 refinement stop 均不得使用离 $1.85$、current $\widehat k_h$ 或 current
field 的距离。

### 4.2 Bulk levels

bulk levels 固定为：

| ID | subdivisions per unit $s$ | $h=1/s$ | polygon segments $n_\Gamma$ | $\alpha$ grid | eigensolver tolerance |
|---|---:|---:|---:|---:|---:|
| B1 | 12 | $1/12$ | 24 | 17 equispaced nodes on $[0,\pi]$ | $10^{-9}$ |
| B2 | 18 | $1/18$ | 36 | 17 nodes | $10^{-10}$ |
| B3 | 24 | $1/24$ | 48 | 17 nodes | $10^{-11}$ |
| B4 | 24 | $1/24$ | 48 | 33 nodes | $10^{-11}$ |

在每个 $\alpha$ 请求并完整返回 lowest `nev = 40` eigenpairs，并要求第 40 个 frequency 高于
$2.45$；否则输出 `SPECTRUM_INVENTORY_TRUNCATED`，不得运行自适应追加 root count。第 5.1 节的
`flag/count/finite/order/residual/multiplicity` complete-return hard gates 同样适用于每个 bulk solve。
每个 band 的 observed range 由所有 $\alpha$ samples 的 extrema 构造；相邻 band ranges 的 complement
给出 observed projected gaps。

另在 B4 的预注册 phases

$$
\mathcal A_{\mathrm{count}}={0,\pi/4,\pi/2,3\pi/4,\pi}
$$

各请求一次 `nev = 48` count sentinel，tolerance 仍为 $10^{-11}$。sentinel 必须完整返回 48 个
objects，且其 lowest 40 个按 cluster-preserving ordered list 与 corresponding 40-root solve 在
$10^{-8}$ frequency tolerance 内逐项一致；41--48 号均不得落回 target raw gap。任一 gate 失败即
`SPECTRUM_INVENTORY_TRUNCATED`。这五次 solve 是固定 union 的一部分，不是结果后追加。

目标 gap 必须是 B4 中唯一一个其 open interior 完整包含 $I_{\mathrm{cue}}$、且两 edge 均位于
$I_{\mathrm{guard}}$ interior 的 gap。没有或多于一个时输出 `BULK_GAP_UNRESOLVED`。该规则由整个
宽 interval 唯一化 gap，不使用某个 current root。

令 B4 edge 为 $g_-^{(4)},g_+^{(4)}$。逐 edge 定义

$$
\delta_{g,\pm}^{\mathrm{obs}}
=\left|g_\pm^{(4)}-g_\pm^{(2)}\right|
+\left|g_\pm^{(4)}-g_\pm^{(3)}\right|,
$$

其中 B2--B3 反映 FEM/geometry，B3--B4 反映 $\alpha$ sampling。只有 B1--B2 与 B2--B4 edge
changes 不增，或末级 change 小于 observed gap width 的 $0.5\%$，才通过 bulk refinement。
经验 safe interior 定义为

$$
G_{\mathrm{safe}}^{\mathrm{obs}}
=\bigl(g_-^{(4)}+\delta_{g,-}^{\mathrm{obs}},
g_+^{(4)}-\delta_{g,+}^{\mathrm{obs}}\bigr).
$$

若为空或宽度小于 raw observed gap width 的 $80\%$，输出 `BULK_GAP_UNRESOLVED`。这里的 safe
只表示 edge-uncertainty diagnostic，不是 certified subset of the continuous gap，也不把第一层
target 从 raw observed gap 缩成 safe interior。defect inventory 必须覆盖整个 raw observed gap

$$
G_{\mathrm{raw}}^{\mathrm{obs}}=(g_-^{(4)},g_+^{(4)}).
$$

本次 attempt 不预注册一个额外的“edge-buffer delocalized proof”。因此只要
$G_{\mathrm{raw}}^{\mathrm{obs}}\setminus G_{\mathrm{safe}}^{\mathrm{obs}}$ 中出现任何 eigenobject，
无论它看似 localized、delocalized、clustered 或 unresolved，均立即输出
`BULK_GAP_UNRESOLVED`，whole-gap `coverage_pass=false`。只有 raw-gap edge buffer 在每个冻结
FEM/$N$/twist/algebraic inventory slice 都为空，才可继续 safe-interior branch qualification。这个
更强的 all-level/all-slice 空-buffer规则避免把 potential localized branch 以“已登记排除”或
“coarse level 后来消失”为由遗漏。

## 5. 完整 defect spectrum 和 branch/cluster inventory

### 5.1 Solver contract

每个 reduced pair $(K_\vartheta,M_\vartheta)$ 使用
`[V,D,flag] = eigs(K,M,40,'smallestabs',opts)`；主 tolerance 为 $10^{-11}$、`maxit = 800`，
Arnoldi subspace 至少为 $80$。起始向量只由 mesh node coordinates 的固定解析函数产生，不使用
随机 current field；若需要 deterministic perturbation，固定 `rng(4101,'twister')` 并记录。

每个 eigenpair 以 $u^*Mu=1$ 归一化，并检查

$$
r_{\mathrm{alg}}
=\frac{\|Ku-\lambda Mu\|_2}
{(\|K\|_1+|\lambda|\|M\|_1)\|u\|_2}
\le 10^{-9}.
$$

每次 solve 的 complete-return hard gates 是：

1. `flag == 0`，`size(V,2) == 40` 且 `numel(diag(D)) == 40`；
2. 40 个 eigenvalues 和 vectors 全部 finite；relative imaginary part 不超过 $10^{-10}$，real part
   positive；
3. 频率按 nondecreasing order 稳定排序，排序后不去重、不丢 multiplicity，且
   $\|V^*MV-I\|_2\le10^{-7}$；
4. 所有 40 个 $r_{\mathrm{alg}}\le10^{-9}$，cluster multiplicities 之和恰为 40；
5. $K/M$ Hermitian defect 不超过 $5\times10^{-13}$，`chol(M)` 成功；
6. 第 40 个 frequency 高于 $g_+^{(4)}+0.10$，并至少有一个 frequency 低于
   $g_-^{(4)}-0.10$。

任何一项失败均输出 `SPECTRUM_INVENTORY_TRUNCATED`，不能把 partial convergence 送入 branch
stage。frequency distance 不超过 $10^{-6}$ 或不超过相邻 residual scale 的 $20$ 倍者合并为
cluster；该操作只分组 ordered list，不删除重复值。cluster multiplicity 和 whole subspace 一起
跟踪，禁止强拆成 nearest scalar root。

每个 slice 先把 $G_{\mathrm{raw}}^{\mathrm{obs}}$ 内全部 objects 写入 ledger，再执行第 4.2 节的
empty edge-buffer gate；只有该门通过才在 $G_{\mathrm{safe}}^{\mathrm{obs}}$ 做 branch
qualification。

finest $N=5$、$(s,n_\Gamma)=(24,48)$ 的五个 $\Theta_5$ algebraic repeats 同时充当预注册 count
sentinels：loose solve 请求 `nev = 48`、tolerance $10^{-8}$，必须满足上方相同 gates（把 requested
count 替换为 48）。其 lowest 40 个 ordered objects/cluster multiplicities 必须与 tight 40-root
solve 一致，frequency mismatch 不超过 $10^{-7}$；41--48 号不得落入 raw gap。失败仍是
`SPECTRUM_INVENTORY_TRUNCATED`，不是运行后扩大 `nev` 的授权。

### 5.2 冻结的 directed refinement ladder

不运行全 Cartesian product。以下 directed ladder 使四个误差轴分别可见，并控制预算：

| Axis | Frozen levels | Common comparison grid |
|---|---|---|
| FEM/geometry | $N=5$，$(s,n_\Gamma)=(12,24),(18,36),(24,48)$ | $\Theta_5$ |
| supercell | $N=3,4,5$，$(s,n_\Gamma)=(18,36)$；另加 final-geometry $N=4,5$，$(24,48)$ cross-axis corner | $\Theta_5$ |
| twist | $N=5$，$(s,n_\Gamma)=(24,48)$，$\Theta_5,\Theta_9,\Theta_{17}$ | nested grids |
| algebraic | finest geometry at $\Theta_5$，tolerances $10^{-8}$ and $10^{-11}$ | identical matrices/start vectors |

其中

$$
\Theta_m=\left\{\frac{r\pi}{m-1}:r=0,\ldots,m-1\right\},
\qquad m\in\{5,9,17\}.
$$

所有可复用 nodes 只求一次。新增的 final-geometry $N=4$、$\Theta_5$ 恰为五次 solves；它在揭盲前
测量 FEM/geometry 与 supercell interaction，不得以 medium geometry 的 $N=4\to5$ 变化替代。
distinct defect eigensolves 的计划数从 $42$ 增至 $47$；bulk main union 为 $67$，另有五个固定
48-root count sentinels，总 bulk count 为 $72$。完整正式运行共 $119$ 次 eigensolves。实现必须在
progress ledger 记录 planned/completed counts，不能以拆 command 方式重置预算。

### 5.3 Branch continuation 与 common-core field

同 mesh 相邻 twists 以 mass overlap matrix 延拓 clusters；不同 $N$/mesh levels 在共同 physical
core

$$
C_{\mathrm{core}}=(-2.5,2.5)\times Y
$$

上比较。common-core diagnostic grid 固定为 $161\times65$ tensor nodes；在 exact circles 上的
points 去除，余点用 triangle barycentric interpolation，按 exact $q$ 加权。simple branch 是
multiplicity-one cluster。simple-branch phase-free overlap 要求至少 $0.90$；multiplicity-$m$
cluster 用两个 $m$-dimensional subspaces 的 principal-angle overlap，minimum singular value 要求
至少 $0.80$。cluster dimension $m$ 必须在全部 $\Theta_{17}$ slices、FEM levels、$N$ levels 和
algebraic repeat 中相同；任何 merge/split、dimension change、外部 eigenvector 混入或 continuation
不唯一均输出 `REFERENCE_SET_COVERAGE_UNRESOLVED`，不得选择一个方便的 basis 强拆。

对每个 $M$-orthonormal cluster basis $U$ 和任意 physical region $D$，定义 restricted-mass Gram

$$
G_D(U)=U^*M_DU.
$$

若 $U$ 换成 $UQ$，其中 $Q$ unitary，则 $G_D$ 只作 unitary similarity；因此后文只使用其
extremal eigenvalues，不使用任一 basis vector 的单独 mass。fields artifact 可以保存一个
deterministic $M$-orthonormal basis 以便重建，但必须标记 `NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY`；
scientific CSV 和 qualification 只保存 subspace dimension、Gram spectra、principal angles 和
spectral envelopes。

在 $\vartheta=0$ 和 $\pi$，parity signature 定义为 full-mass compressed reflection
$U^*M\mathcal R_xU$ 的 spectrum；对 exact invariant parity subspace，其 eigenvalues 为 $\pm1$，且
$U\mapsto UQ$ 只作 unitary similarity。每个 compressed eigenvalue 的实部大于等于
$0.80$ 标记 even，小于等于 $-0.80$ 标记 odd；其余标记 `PARITY_AMBIGUOUS`。signature 是
basis-invariant multiset。parity ambiguity 不删除一个已解析 cluster，但阻止 future
target-specific upgrade，并输出 `MODE_ID_AMBIGUOUS`。

## 6. 独立 mode qualification 和 coverage gate

### 6.1 Frozen field functionals

对 mass-normalized simple field 定义

$$
L_0(u)=\int_{C_0}q|u|^2,
\qquad
L_{\mathrm{core}}(u)=\int_{|x|<3/2}q|u|^2,
$$

以及 supercell outer-tail

$$
T_N(u)=\int_{|x|>N-3/2}q|u|^2.
$$

对 multiplicity-$m$ cluster subspace $U_j(\vartheta)$，冻结 basis-invariant quantities

$$
L_{0,j}^-(\vartheta)=\lambda_{\min}(G_{C_0}(U_j(\vartheta))),
\qquad
L_{\mathrm{core},j}^-(\vartheta)
=\lambda_{\min}(G_{|x|<3/2}(U_j(\vartheta))),
$$

$$
T_{N,j}^+(\vartheta)
=\lambda_{\max}(G_{|x|>N-3/2}(U_j(\vartheta))).
$$

simple branch 是 $m=1$ 的特例。finest $N=5$ branch/cluster 必须对 **全部**
$\vartheta\in\Theta_{17}$ 满足

$$
L_{0,j}^-(\vartheta)\ge0.15,
\qquad
L_{\mathrm{core},j}^-(\vartheta)\ge0.60,
\qquad
T_{5,j}^+(\vartheta)\le0.02.
$$

另外，对每个共同 $\vartheta\in\Theta_5$，medium-geometry $N=3,4,5$ matching cluster 必须逐
slice 满足
$T_{5,j}^+(\vartheta)\le0.8T_{4,j}^+(\vartheta)$ 和
$T_{4,j}^+(\vartheta)\le0.8T_{3,j}^+(\vartheta)$；若 terminal quantity 不超过 $10^{-4}$，只要求
该 slice 不出现超过 $10^{-4}$ 的反弹。final-geometry $N=4\to5$ 也逐 slice 应用同一规则。
实现同时保存 across-twist aggregates
$\min_\vartheta L_{0,j}^-$、$\min_\vartheta L_{\mathrm{core},j}^-$ 和
$\max_\vartheta T_{N,j}^+$，但 verdict 来自上述 every-slice quantifier，不来自平均值。这些条件
只识别 frozen observed localization，不证明 continuous decay theorem 的 constants。

### 6.2 Twist collapse

对每个 stable multiplicity-$m$ branch/cluster，在每个 twist slice 先保存其完整 spectral envelope

$$
E_j(\vartheta)=[k_{j,-}(\vartheta),k_{j,+}(\vartheta)]
=[\min_{1\le r\le m}k_{j,r}(\vartheta),
\max_{1\le r\le m}k_{j,r}(\vartheta)].
$$

再从 twist grid 得到 basis-independent branch envelope

$$
k_j^{\min}=\min_{\vartheta}k_{j,-}(\vartheta),\quad
k_j^{\max}=\max_{\vartheta}k_{j,+}(\vartheta),\quad
\bar k_j=\frac{k_j^{\min}+k_j^{\max}}2,
\quad
w_j^{\mathrm{twist}}=\frac{k_j^{\max}-k_j^{\min}}2.
$$

$N=3,4,5$ 的 medium-geometry $\Theta_5$ half-width 必须逐级不增；final geometry 的
$N=4\to5$ 还必须满足 $w_{5,j}\le0.8w_{4,j}$。若 corresponding terminal half-width 已不超过
observed safe-gap width 的 $10^{-4}$，允许数值平台。cluster internal splitting、twist variation
和 multiplicity 都已包含在 envelope width 内，不得另选一条 basis-dependent eigenvalue curve。
若 stable dimension/envelope 无法唯一形成，输出 `REFERENCE_SET_COVERAGE_UNRESOLVED`；若形成但
collapse gate 失败，输出 `SUPERCELL_RESOLUTION_UNAVAILABLE`。

### 6.3 Complete coverage

coverage ledger 必须逐 level/twist 保存：

- lower/upper spectral sentinels；
- gap 内每个 raw eigenvalue、cluster ID、multiplicity 和 residual；
- branch continuation edges、overlaps、appear/disappear events；
- localization、tail、parity 和 resolution decision；
- 每个 excluded object 的唯一排除理由。

只有以下条件同时成立，`coverage_pass=true`：

1. every finest-twist raw-gap eigenobject 属于一个 dimension-stable branch/cluster；
2. every localized coarse/intermediate branch 要么 continuation 到 finest level，要么作为 unresolved
   branch 触发失败；
3. every frozen level/twist raw-gap edge buffer 均为空；任何 edge-buffer object 已按第 4.2 节使
   `BULK_GAP_UNRESOLVED`，不能登记排除后继续；
4. 没有仅因位置不接近 cue/current root 而排除的 object；
5. 每个 localized branch/cluster 都按 every-slice invariant gates 通过 resolution；不能把 unresolved
   localized subspace 静默删除。

只要 cluster enumeration、multiplicity 或 continuation 有一项 unresolved，就输出
`REFERENCE_SET_COVERAGE_UNRESOLVED`。一个 branch 只因 parity ambiguous 仍可留在一级 empirical
set；一个 branch 因 resolution unresolved 则使 whole first-layer collection fail closed。

## 7. 四轴 observed resolution

对任一 cluster spectral envelope $E=[a,b]$ 定义 basis-invariant endpoint distance

$$
d_E([a,b],[c,d])=\max\{|a-c|,|b-d|\}.
$$

simple branch 是 singleton envelope。以下所有 axis comparison 都要求 multiplicity 相同、subspace
continuation 已通过；否则不是给一个大 scalar uncertainty，而是
`REFERENCE_SET_COVERAGE_UNRESOLVED`。对每支已 continuation 的 branch/cluster $j$，在共同
$\Theta_5$ 上定义

$$
\delta_{\mathrm{FEM},j}^{\mathrm{obs}}
=d_E(E_{(24,48),j},E_{(18,36),j}),
$$

先记

$$
d_{N,j}^{\mathrm{fine}}
=d_E(E_{N=5,(24,48),j},E_{N=4,(24,48),j}),
\qquad
d_{N,j}^{\mathrm{med}}
=d_E(E_{N=5,(18,36),j},E_{N=4,(18,36),j}),
$$

再把 final-geometry change 及其与 medium-geometry change 的 visible interaction 都纳入

$$
\delta_{N,j}^{\mathrm{obs}}
=d_{N,j}^{\mathrm{fine}}
+|d_{N,j}^{\mathrm{fine}}-d_{N,j}^{\mathrm{med}}|.
$$

twist-sampling change 为

$$
\delta_{\mathrm{sample},j}^{\mathrm{obs}}
=d_E(E_{\Theta_{17},j},E_{\Theta_9,j}),
$$

algebraic change 则逐 slice 比较完整 cluster envelope：

$$
\delta_{\mathrm{alg},j}^{\mathrm{obs}}
=\max_{\vartheta\in\Theta_5}
d_E(E_j^{(10^{-11})}(\vartheta),E_j^{(10^{-8})}(\vartheta)).
$$

method contract 要求 twist component 至少包含 finest repeated-defect band half-width，因此取

$$
\delta_{\mathrm{twist},j}^{\mathrm{obs}}
=w_{\Theta_{17},j}+\delta_{\mathrm{sample},j}^{\mathrm{obs}},
$$

并报告

$$
\Delta_{\mathrm{ref},j}^{\mathrm{obs}}
=\delta_{\mathrm{FEM},j}^{\mathrm{obs}}
+\delta_{N,j}^{\mathrm{obs}}
+\delta_{\mathrm{twist},j}^{\mathrm{obs}}
+\delta_{\mathrm{alg},j}^{\mathrm{obs}}.
$$

这里的 `+` 是 conservative observed sensitivity bookkeeping，不是 error calculus。

末两级 changes 还必须与其前一相邻 envelope change 比较。FEM 使用
$d_E(E_{18},E_{12})$，medium-$N$ 使用 $d_E(E_{N=4},E_{N=3})$，twist 使用
$d_E(E_{\Theta_9},E_{\Theta_5})$。各 axis 通过的条件是末级 change 不超过前级的 $0.8$，或末级
change 小于 safe-gap width 的 $5\times10^{-4}$。另外 final-geometry
$d_{N,j}^{\mathrm{fine}}$ 必须通过第 6.2 节的 $N=4\to5$ collapse，且其 interaction term 必须作为
$\delta_{N,j}^{\mathrm{obs}}$ 的一部分保留。
algebraic component 必须同时满足

$$
\delta_{\mathrm{alg},j}^{\mathrm{obs}}
\le10^{-8}\max(1,|\bar k_j|)
$$

以及不超过其余三个 components 最大值的 $5\%$。最终
$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 不得超过 safe-gap width 的 $2\%$。任一条件失败，输出
`REFERENCE_RESOLUTION_UNRESOLVED`；不得用 monotone/exponential fit 替代观测值。

qualified reference object 是 finest $\Theta_{17}$ spectral envelope
$E_{\mathrm{ref},j}=[k_j^{\min},k_j^{\max}]$、中心
$k_{\mathrm{ref},j}=(k_j^{\min}+k_j^{\max})/2$ 和 frozen multiplicity $m_j$。在
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 中每个 stable cluster 贡献这个中心一次并携带 multiplicity；
其 internal splitting/twist extent 已进入 $w_{\Theta_{17},j}$ 和
$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$。reference field object 是 $\vartheta=0$ 的整个 finest
$M$-orthonormal subspace；只有 $m_j=1$ 才另存 canonical phase-aligned vector。任何 unresolved
cluster 不输出 basis-dependent center、field 或 scalar resolution，而使 collection fail closed。

## 8. 信息隔离、reveal gate 和 attempt lifecycle

### 8.1 运行输入白名单

MATLAB scientific inputs 只能来自 source 内的显式 physical/configuration struct：period、$R$、
$q_{\mathrm{in}}=17$、$q_{\mathrm{out}}=1$、missing-column index、$\beta=0.5$、第 4--7 节的 grids、
tolerances 和 thresholds。model identifier 固定为
`scalar-laplace-q17-r0p2-beta0p5-missing0-v1`。

运行代码不得读取或搜索：

- 任何 Markdown、README、design/review/status、Git metadata 或 human-facing manifest；
- `research/`、I1--I3 `test/`、历史 output 或 package result；
- current $\widehat k_h$、estimator、BIE density、QZ vectors、field 或 nominal interval；
- repository root、sibling path 或 absolute repository path。

代码和 required helper files 被整体移动并加入 MATLAB path 后必须仍可运行。output path 只由
entry function 的显式 `run_id` 和该 function 所在目录形成；它不通过目录深度发现仓库。

### 8.2 Freeze 与 reveal

正式 run 完成后先冻结：

- full bulk and defect inventories；
- coverage/resolution ledger；
- `reference-collection.mat` 和 machine-readable CSVs；
- source/environment/run provenance；
- success/failure status。

本 attempt 不含 reveal code，也不接收 current numeric inputs。Skeptic 只有在检查 artifacts、budget
和 claim boundary 后，才能允许 future comparison。可在 MATLAB 完成后由外部只读工具记录
artifact SHA-256；MATLAB 运行不得读取或依赖 hash。

### 8.3 Attempt reuse

`test/i4/femref-a1/` 是本方法唯一 attempt directory。implementation、debug、schema/path/environment
修复及纠正后重跑都留在该目录。运行由显式 `run_id` 区分，例如 `run-001`、`run-002`；代码不得
扫描旧 output 自动选择 ID。operational failure 不消费 attempt。只有 correctly implemented full
run 证明本冻结 M1 method 本身失败、且另行审查选择实质不同的 M2/RtR 等方法后，才允许新
attempt；本设计不授权该转换。

## 9. Stage 顺序、future file map 和 exact command

### 9.1 不可重排的 stages

1. `SPEC_AND_ENVIRONMENT`：建立 source-owned specification；检查 base MATLAB dependencies，
   不读 repository metadata；
2. `MESH_ORACLES`：build bulk/supercell meshes；检查 interface、periodic pairs、quality 和 DOF caps；
3. `BULK_INVENTORY`：运行 B1--B4、gap/refinement/sentinel gates；失败即停止 defect solve；
4. `DEFECT_INVENTORY`：按 directed ladder 计算所有 slices，不做 nearest-root selection；
5. `BRANCH_AND_COVERAGE`：cluster continuation、localization、tail、parity、coverage；
6. `RESOLUTION`：逐支形成 four-axis ledger 和 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$；
7. `BLIND_EXPORT`：原子写入 blinded collection、fields、ledgers 和 terminal status；
8. `STOP_BEFORE_REVEAL`：正常退出，不读取 current result。

bulk gate 失败后不得继续 defect stage；这不是 retry。每个 reached stage 都先写 progress row，再写
stage artifact，最后原子更新 terminal summary。

### 9.2 Theory-to-future-code map

Engineer 应优先实现一个 substantial function file `run_i4_1a.m`，并按 root `AGENTS.md` 用
`LOCAL_` subfunctions 分组；只有清晰度确有需要时才增加同目录 helper files。

| Theory/design object | Future responsibility | Required artifact |
|---|---|---|
| physical constants and frozen grids | `LOCAL_spec` | `model.csv`, `config.csv` |
| polygon fitted bulk/supercell meshes | `LOCAL_build_mesh` | `mesh-ledger.csv`, finest mesh in `fields.mat` |
| phase prolongation $P$ | `LOCAL_phase_reduce` | `seam-checks.csv` |
| volume $a,m$ | `LOCAL_assemble_p1` | Hermitian/mass/triangle checks |
| bulk bands and observed gap | `LOCAL_bulk_inventory` | `bulk-bands.csv`, `bulk-gaps.csv` |
| generalized eigenobjects | `LOCAL_low_spectrum` | `spectrum-inventory.csv`, residuals |
| clusters and continuation | `LOCAL_track_branches` | dimensions, spectral envelopes, `branch-edges.csv`, principal-angle ledger |
| restricted-mass Grams and parity compression | `LOCAL_mode_labels` | Gram spectra, every-slice aggregates, `branch-inventory.csv` |
| coverage rule | `LOCAL_coverage_gate` | `coverage-ledger.csv` |
| basis-invariant four-axis envelope changes | `LOCAL_resolution` | `branch-resolution.csv` |
| blinded collection | `LOCAL_export` | `reference-collection.mat`, `fields.mat` |
| run status/progress | `LOCAL_record` | `progress.csv`, `failures.csv`, `run-summary.mat` |

No future module may call current BIE/QZ functions or parse a human-facing file.

### 9.3 Exact first formal command

在 `test/i4/femref-a1/` 作为 working directory，且 design review、implementation、Researcher
theory-to-code check 和 Skeptic spec-to-code review 全部通过后，唯一 first formal command 为：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-001')"
```

`/usr/bin/time` 只供外部记录 wall time 和 peak RSS；MATLAB science 不读取它。若 `run-001` 是
operational failure，修复后由同一审查链批准显式 `run-002`，仍在 `femref-a1`，不得覆盖旧日志。

## 10. 输入、output schema 和 atomicity

### 10.1 输入

唯一 runtime argument `run_id` 是 artifact label，不改变 science。全部科学参数位于
`LOCAL_spec`；没有 `.mat`/Markdown/history input。entry function 若接到既存 output directory，
立即以 `OUTPUT_COLLISION` 停止，不覆盖；是否换用新 run ID 由外部显式决定。

### 10.2 Required outputs

每个 run 写入本地 `output/<run_id>/`：

| File | Content | Required even on scientific failure? |
|---|---|---|
| `run-summary.mat` | terminal status, reached stages, elapsed, counts, model ID | yes |
| `config.csv` | all frozen scientific parameters and thresholds | yes |
| `progress.csv` | stage, planned/completed solves, elapsed, ETA evidence | yes |
| `mesh-ledger.csv` | DOF, triangles, constraints, quality, geometry diagnostics | if mesh reached |
| `seam-checks.csv` | node pairs, phase/corner/Hermitian checks | if mesh reached |
| `bulk-bands.csv` | every level/phase/eigenvalue/residual | if bulk reached |
| `bulk-gaps.csv` | gap edges, changes, safe interval and gate | if bulk reached |
| `spectrum-inventory.csv` | every defect eigenobject before qualification | if defect reached |
| `branch-edges.csv` | continuation and overlap records | if branch stage reached |
| `branch-inventory.csv` | cluster IDs/dimensions, spectral envelopes, Gram spectra, all-twist localization/tail/parity/decision | if branch stage reached |
| `coverage-ledger.csv` | every included/excluded/unresolved object and reason | if coverage reached |
| `branch-resolution.csv` | all four components and $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ | if resolution reached |
| `reference-collection.mat` | blinded centers, envelopes, multiplicities, per-cluster resolution or empty set plus failure | yes at terminal export |
| `fields.mat` | finest anchor subspaces, optional simple-mode vector, mesh and normalization data；cluster basis marked noncanonical | only for reached branches |
| `failures.csv` | typed warnings/failures in first-occurrence order | yes |
| `matlab.log` | console/diary, dependency versions, exception stack | yes |

CSV numeric values use `%.17g`; complex values use separate real/imag columns。matrices/fields only进入
MAT file，CSV 保持审查级 scalar ledger。temporary files 使用 `.partial` suffix，成功 close 后 rename；
terminal summary 只在其依赖 artifacts 成功 close 后发布。任何 schema 写出失败属于
`EXECUTION_UNAVAILABLE`，不消费 attempt。

## 11. Failure states 和停止规则

| State | Trigger | Interpretation / next action |
|---|---|---|
| `CONTINUOUS_MODEL_MISMATCH` | weak form, material, phase or geometry identity mismatch | blocker；修 specification，不比较数字 |
| `DEPENDENCY_UNAVAILABLE` | required base MATLAB function absent | operational failure；same attempt repair only if dependency claim was wrong |
| `MESH_QUALITY_UNRESOLVED` | interface/quality/periodic mesh gate fails | scientific object unavailable；不 solve |
| `QUASIPERIODIC_SEAM_UNRESOLVED` | node/phase/corner identity fails | implementation/scientific blocker |
| `SPECTRUM_INVENTORY_TRUNCATED` | 40/48-root flag/count/finite/order/residual/multiplicity or sentinel gate fails | coverage unavailable；不得增加 roots post hoc |
| `BULK_GAP_UNRESOLVED` | unique wide-cue gap、edge refinement or raw-gap empty-buffer gate fails | valid unresolved result；不得缩成 safe-interior target |
| `NO_LOCALIZED_BRANCH` | full raw-gap inventory and empty-buffer gate pass but no branch qualifies under frozen observed localization screen | valid screen-negative；不否定 continuous guided mode；no reference set |
| `REFERENCE_SET_COVERAGE_UNRESOLVED` | missing/untracked root or cluster | first layer fail closed |
| `MODE_ID_AMBIGUOUS` | parity/target label ambiguous but set branch resolved | first layer may survive；future target-specific comparison blocked |
| `FEM_RESOLUTION_UNAVAILABLE` | FEM/geometry axis fails | no qualified collection |
| `SUPERCELL_RESOLUTION_UNAVAILABLE` | $N$/tail/twist collapse fails | no qualified collection；future M2 needs new design |
| `REFERENCE_RESOLUTION_UNRESOLVED` | sampling/algebraic/total-resolution gate fails | no qualified collection/effectivity |
| `REFERENCE_INFORMATION_LEAKAGE` | code/design consumes current chain data | discard artifact；cannot repair by relabeling |
| `RESOURCE_BUDGET_UNAVAILABLE` | predicted/runtime cap fails | stop same attempt, report resource blocker |
| `EXECUTION_UNAVAILABLE` | code/path/schema/environment exception | operational failure；preserve log and fix same attempt |
| `OUTPUT_COLLISION` | explicit run directory already exists | operational stop；do not overwrite |

只记录 first scientific failure 作为 terminal cause，同时保留此前 warnings；不得捕获异常后继续产出
看似成功的 collection。

## 12. 预算估算和监控合同

### 12.1 静态规模估算

finest defect mesh 为 $N=5$、$L_N=11$、$s=24$、$n_\Gamma=48$。Cartesian nodes 约
$(11\cdot24+1)(24+1)=6625$；加入 circle/ring nodes 并做 periodic reduction 后，预计
$7000$--$9000$ reduced DOF。实现预分配 hard preflight caps：

- reduced DOF 不超过 `12000`；
- `nnz(K)+nnz(M)` 不超过 `2,000,000`；
- main `nev = 40`、count-sentinel `nev = 48`，Arnoldi subspace 不超过 `100`；
- 一次只保留当前 solve 的 factor/workspace，禁止把所有 eigenvectors/matrices 同时缓存。

按 complex sparse matrices、shift-invert factor/work vectors、最多 48 eigenvectors、mesh/CSV buffers 和
MATLAB runtime overhead 估算，scientific objects 约 $0.45$--$0.75$ GiB，含 sparse-factor fill 和
runtime safety factor 后预计 peak RSS **不超过 $1.2$ GiB**。若实现静态 audit 推导出超过
$1.5$ GiB 的 peak estimate，不得正式运行；应回到同一 design review，而不是靠硬限试跑。

bulk 为 67 次 main small-cell solves，加五个 48-root count sentinels，共 72 次；defect 在原 42 次
union 上增加五个 final-geometry $N=4$ corner solves，共 47 次。五个 loose algebraic solves 已兼任
defect count sentinels，不另计 command；完整 union 为 **119 eigensolves**。按 bulk
$0.5$--$1.5$ s、coarse defect $5$--$15$ s、finest defect $20$--$35$ s，并计入 `nev=48` 的额外
work、meshing、tracking、export 和 MATLAB startup，计划 wall time 约 **21 min**，conservative
upper estimate **29.8 min**。新增 $N=4$ mesh 小于 finest $N=5$ mesh，不提高 simultaneous object
peak；预计 peak RSS 仍不超过 **1.2 GiB**。因此设计仍在默认 30 min / 2 GiB 计划上限内，但时间
余量只有约 $0.2$ min；spec-to-code gate 必须用 actual DOF/fill 和 solver-count 重新估算。若该跑前
估算超过 30 min，立即标记 `RESOURCE_BUDGET_UNAVAILABLE`，不得 launch。

### 12.2 正式监控

Code Runner 每 30 s 检查 process alive、RSS、`progress.csv` 更新和 completed/planned solves；90 s
无 progress 仅作 `OUTPUT_STALL` advisory，因为单次 sparse factorization 可较长。MATLAB 每个 solve
完成后记录 elapsed、instantaneous stage rate 和 remaining-solve ETA。

- 预计超过 30 min 或 2 GiB 时不得 launch；
- RSS 达 2 GiB 立即 hard stop；
- 30 min 只有在至少 $90\%$ planned solves 已完成、最近五个 solve rate 有限，且 ETA 不超过
  10 min 时，才允许唯一 grace period；
- 40 min 是 hard stop，无第二次 extension；
- MATLAB startup、bulk、defect、export 和所有 subprocess 均共享同一预算。

如果实现产生的 actual finest DOF 超过第 12.1 节 caps，程序必须在 eigen solve 前输出
`RESOURCE_BUDGET_UNAVAILABLE`。不得通过减少 branch inventory、删除 refinement axis 或拆 command
来满足预算。

## 13. 跑前审查与 post-run acceptance checklist

### 13.1 Design/Skeptic gate

Skeptic 必须逐项判断：exact-circle target 与 polygonal discrete geometry 是否诚实区分；wide cue
是否未变成 nearest-root selector；40/48-root complete-return sentinel 是否足以形成 empirical
inventory；all-twist basis-invariant cluster continuation、empty edge-buffer、coverage 和 resolution
failure 是否 fail closed；final-geometry $N=4\to5$ corner 是否进入 $\delta_N$；P1 accuracy limitation
是否被正确降级；预算是否可执行。只有 `PASS` 或 `PASS WITH CONDITIONS` 且无 unresolved blocker
才交 Engineer。

### 13.2 Researcher theory-to-code gate

Engineer implementation 完成后，Researcher 只核对第 9.2 节 map：continuous constants、phase signs、
volume forms、polygon geometry level、all-root inventory、field functionals 和 four-axis formulas。
不得以 smoke output 改 design。任何公式/threshold drift 都退回同一 Engineer 修复。

### 13.3 Skeptic spec-to-code gate

正式运行前，Skeptic 必须检查：唯一 experiment directory；无 current-chain imports；无 Markdown/Git/
history reads；没有 absolute repository path；exact command、run ID、schema、stage order、first-failure
and budget monitors 均对应设计。通过前不得运行 scientific solve。

### 13.4 Post-run verdict boundary

正式 run 后，同一 Skeptic 在 `review-4-1a.md` 追加 artifact、budget、retry ledger、branch coverage、
resolution、negative evidence 和 claim boundary。只有 post-run review 完成后，主 agent 才可把经过
验证的状态最小同步到 I4 guide/项目 STATUS。本设计不授权 `design-4-1b.md`、effectivity reveal、
I4.2、package change 或 second method。

## 14. Researcher 决定、假设和最弱环节

**Decision: `GO TO SAME SKEPTIC RE-REVIEW`.** Researcher 已完成 review §G 的有界修订；当前没有
design-level blocker。静态预算为 21 min 计划值、29.8 min conservative upper、1.2 GiB peak
estimate，仍低于 30 min / 2 GiB，但时间余量很小，必须在 spec-to-code gate 复算。

`IMPORTANT CAVEAT`：自包含 $P_1$ polygon-fitted FEM 的 terminal empirical resolution 很可能远粗于
I3 estimator 的 nominal scale。这个风险不否定 independent reference experiment，但很可能使 future
effectivity denominator 被 `REFERENCE_RESOLUTION_DOMINATES` 阻止。设计因此不以“得到 effectivity
number”为成功条件，而以 complete blind inventory、honest resolution 或合法 failure 为成功的实验
产物。

`IMPORTANT CAVEAT`：polygon area/Hausdorff diagnostics 不是 exact-circle eigenvalue error bound；
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 也可能共享 pre-asymptotic bias。四轴 changes 只有 empirical
意义。若 finest changes 不下降，必须输出 resolution failure，不能把位置接近预期值作为补救。

`MINOR CAVEAT`：只采样 $[0,\pi]$ 使用了 $x$ reflection symmetry；implementation 必须保存 boundary
phase/reflection oracles。任何破坏 symmetry 的 mesh generation 都使该 reduction unavailable，而不是
静默只算半个 twist zone。

最小下一门是同一 Skeptic 的 design re-review；在其完成前不创建
`test/i4/femref-a1/`，不运行 MATLAB，也不开展 reveal/effectivity comparison。
