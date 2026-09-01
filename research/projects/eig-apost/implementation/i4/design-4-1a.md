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

## 15. 2026-08-28 prospective mesh-implementation repair revision

### 15.1 Status, authority and historical boundary

**Revision status: `DRAFT / SAME-METHOD IMPLEMENTATION REPAIR CONTRACT /
AWAITING SAME SKEPTIC REVIEW`. Engineer: `NOT AUTHORIZED`. Formal rerun:
`NOT AUTHORIZED`.**

本节只记录 `run-004` 之后的前瞻性授权边界。
[[research/projects/eig-apost/implementation/i4/review-4-1a|review-4-1a §Q]] 以及
`run-001`–`run-004` 的 artifacts、retry ledger、当时的
`VALID SCIENTIFIC NEGATIVE / FROZEN M1 METHOD FAILED / ATTEMPT CONSUMED`
verdict 全部保留为不可覆写的历史记录。本修订不追溯改写那一 verdict，
也不把当时的 review `PASS` 重解释为 reference success。

依据后续明确的 user direction，**仅对 future action authority** 作如下重分类：

- continuous exact-circle guided-mode problem、$P_1$ FEM method、weak form $a(u,v)=\lambda
  m(u,v)$ 和所有 physical parameters 均未失败、未改变；
- `run-004` 建立的前瞻性事实是：当时的 deterministic mesh implementation 没有实现
  本设计第 3.1–3.2 节已经冻结的 $x$-reflection requirement；
- 因此，把 mesh connectivity/material pairing 修复到既有合同是 same-method
  implementation repair，不是 M2、不是新 continuous problem，也不是放松 scientific gate。

Evidence status：`ESTABLISHED` 的是 `run-004` 在 `bulk-s12-g24` 上记录
$2.410043158511017\times10^{-15}$ 的 stiffness-reflection defect、
$0.014666412555809508$ 的 mass-reflection defect、原冻结 tolerance
$5\times10^{-11}$ 以及 $0/119$ eigensolves。`PROVISIONAL` 的是更窄的 root-cause
diagnosis：Delaunay tie-breaking/connectivity 或 connectivity 上的 material pairing 均可解释该
pattern；本修订不在无新证据时强行二选一。

### 15.2 Frozen scientific contract

以下对象继续由本文第 2–12 节冻结，本修订不作任何变更：

1. exact-circle continuous geometry，$R=0.2$、$q_{\mathrm{in}}=17$、
   $q_{\mathrm{out}}=1$、missing index $0$、$\beta=0.5$ 和 frequency normalization；
2. $a(u,v)=\int\nabla u\cdot\nabla\overline v$ 与
   $m(u,v)=\int q u\overline v$ 的 volume $P_1$ weak form，包括现有 local stiffness 与
   consistent weighted-mass formulas；
3. 所有 $(s,n_\Gamma)$、$N$、$\alpha$、$\vartheta$、tolerance、threshold、40/48-root
   gates 和 $72+47=119$ solve schedule；
4. raw-gap/safe-gap、all-slice edge buffer、cluster/subspace、localization/tail、coverage、four-axis
   refinement 及 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 的全部规则；
5. information isolation、wide cue 仅用于 bulk-gap identification、blind export、reveal gate 和
   empirical/non-certified claim boundary；
6. `femref-a1` 作为唯一 attempt directory，以及单个 corrected formal run 共享的
   30 min soft wall、2 GiB hard peak、最多一次 10 min grace 与 40 min hard wall。

该 freeze 意味着：合格修复不得以“更容易通过”为理由改变数值问题，只能使
implementation 实现本来就应满足的 reflection-invariant fitted-mesh contract。

### 15.3 Minimal implementation-repair contract

令 $\rho$ 是当前 node set 上由 $(x,y)\mapsto(-x,y)$ 诱导的节点 involution，
$\mathcal R_x$ 是对应的节点置换矩阵。修复后的 mesh 必须在 **assembly 之前** 满足：

1. outer/background points、disk polygon/ring points、point-removal rule、constraint segment multiset 和
   mesh schedule 不变，只允许 ordering 或 deterministic tie resolution 的实现变化；
2. 每个 unordered triangle $\{i_1,i_2,i_3\}$ 都有唯一的 reflected triangle
   $\{\rho(i_1),\rho(i_2),\rho(i_3)\}$，不能有 unpaired triangle、overlap、hole 或额外
   interface crossing；
3. reflected triangle pair 的 frozen polygon-inside material flag 必须一致；
4. 在不修改 local element formulas 的前提下，assembled $K$、$M$ 必须同时满足

   $$
   \frac{\|K-\mathcal R_x^*K\mathcal R_x\|_1}{\max(1,\|K\|_1)}\le5\times10^{-11},
   \qquad
   \frac{\|M-\mathcal R_x^*M\mathcal R_x\|_1}{\max(1,\|M\|_1)}\le5\times10^{-11};
   $$

5. signed area、constraint-edge、minimum-angle、cross-interface、finest Hausdorff、periodic-pair、
   seam/corner 和 Hermitian oracles 仍按原顺序 fail closed。

Allowed future source scope 只包括 `test/i4/femref-a1/run_i4_1a.m` 中的 mesh connectivity
construction/tie-resolution、直接服务该修复的 `LOCAL_` mesh helpers、上述 pre-assembly
closure diagnostics，以及为下节非 scientific diagnostic 所必需的最小 entry/writer dispatch。
若 code-variable ledger 或 attempt README 因新 diagnostic interface 必须机械同步，只可更新
`test/i4/femref-a1/SYMBOLS.md` 和 `test/i4/femref-a1/README.md`，不得夹带 scientific
parameter 变更。

实现可以选择任意 deterministic construction/tie-resolution，但必须用上述不变性证据验收；
本设计不预选 half-mesh reflection、diagonal rule 或其他具体算法。该 property-based 合同避免
把尚未确证的 root cause 写成新 method assumption。

### 15.4 Explicitly prohibited changes

本修订不授权：

- 用 $(K+\mathcal R_x^*K\mathcal R_x)/2$、
  $(M+\mathcal R_x^*M\mathcal R_x)/2$ 或任何 matrix averaging/post-symmetrization
  掩盖非对称 connectivity/material labels；
- 改动 `LOCAL_assemble_p1` 的 weak-form coefficients/element formulas、改材料标记规则、改变
  point coordinates/removal/ring/polygon/constraint sets、增删 mesh levels；
- 放宽 $5\times10^{-11}$ reflection tolerance，删除 reflection oracle，把其降级为 warning，
  或只检查 $K$ 不检查 $M$；
- 引入 PDE Toolbox、external mesher、BIE/QZ/current estimator 或任何 historical output
  作为运行输入；
- 改 cue/window、root count、solver tolerance、branch selection、refinement ladder、uncertainty
  formula、output claim 或 reveal boundary；
- 删除、覆写或改写 `output/run-001/`–`output/run-004/`，新建 second attempt
  directory，或把 diagnostic artifact 伪装为 reference collection；
- 在本节通过同一 Skeptic review 前让 Engineer 改码，或在完成第 15.6 节门禁前
  启动 formal `run-005`。

### 15.5 Non-eigensolve mesh/oracle diagnostic

一次有边界的 **non-eigensolve, non-scientific** mesh/oracle diagnostic 可作为 Engineer repair 与
formal rerun 之间的 cheapest decisive check。它不是 guided-mode computation，但会构造 mesh、组装
matrices 并计算 numerical oracle defects，因此不得误称为“无任何数值运算”。

如果 Engineer 实现该路径，必须满足：

1. 它使用显式 diagnostic mode，保持 one-argument formal scientific entry 的语义不变；
2. 它只调用 source-owned specification、九个 frozen mesh builders、原 mesh/seam/reflection
   oracles 和 implementation resource preflight，不得调用 `eigs`、bulk/defect inventory、
   branch/coverage/resolution 或 export reference collection；
3. 它在 `test/i4/femref-a1/diagnostics/mesh-repair-001/` 原子写入独立 ledger，至少包含
   九个 mesh IDs、node/constraint/triangle counts、unpaired-triangle count、material-pair
   mismatch count、全部原 quality/oracle values、$K/M$ reflection defects、seam checks、
   completed eigensolves $=0$ 与 preflight wall/memory forecast；
4. 任一 frozen mesh 没有唯一 reflection-closed connectivity/material pairing，任一原 oracle
   失败，或 forecast 超过 30 min / 1.5 GiB，diagnostic 即 fail closed，不得进入
   formal run；
5. diagnostic 不读 `run-001`–`run-004`、Markdown、Git、current estimator 或任何 BIE/QZ
   object，不产生 `output/run-005/`，不被 future formal run 当作 mesh/cache/input 复用。

该 diagnostic 是 same-attempt implementation/debug evidence，不消耗一个 scientific attempt；它自身仍必须
在 30 min / 2 GiB 内完成。由于 corrected formal run 将从 source 重建全部 meshes 并重跑
oracles，不使用 diagnostic cache，这不是把一个 scientific result 拆成多条 command 重置计时。
任何想在 formal run 中复用 diagnostic mesh/artifact 的变更都会使 diagnostic 成为 scientific
workflow 的一部分；本修订明确禁止该做法。

### 15.6 Gates before Engineer and before formal rerun

**Before Engineer acts**，同一 Skeptic 必须对本节给出 `PASS` 或无 unresolved blocker 的
`PASS WITH CONDITIONS`，并明确同意：

1. 上述前瞻性重分类不篡改 §Q 的历史 verdict；
2. repair 只恢复本来已冻结的 reflection property，没有引入新 method 或降低
   scientific gate；
3. allowed/prohibited source scope、diagnostic boundary 和 append-only lifecycle 足以 fail closed。

在该 review gate 完成前，Engineer 不得修改 implementation。

**Before formal rerun**，必须依次满足：

1. Engineer 的 diff 只落在第 15.3 节允许的 implementation/docs 范围；
2. Researcher 完成新的 theory-to-code check，确认第 15.2 节冻结对象零漂移、
   无 matrix post-symmetrization、无 information leakage；
3. 第 15.5 节 diagnostic 完整通过九个 meshes，$0$ eigensolves，且预测不超过
   30 min / 1.5 GiB；
4. 同一 Skeptic 在 `review-4-1a.md` 完成 implementation/diagnostic artifact/spec-to-code
   re-review，无 unresolved blocker，并显式授权唯一 next formal run；
5. `output/run-005/` 不存在，`run-001`–`run-004` 保持未改，正式命令仍是一条：

   ```text
   /usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-005')"
   ```

`run-005` 必须在同一 command/budget clock 中从 source 重建九个 meshes、重跑所有
oracles 和 preflight，然后才能开始冻结的 119-solve union。原 30 min grace 条件、40 min
hard wall 和 2 GiB hard RSS 不变。如果 formal run 的 actual preflight 超过 30 min 或
1.5 GiB，或任一 mesh/oracle 再失败，必须在 eigensolve 前 fail closed 并返回同一
Skeptic；不自动授权 `run-006`。

### 15.7 Acceptance evidence and claim boundary

Repair acceptance 只由以下证据构成：

- source diff 证明修改范围受限；
- diagnostic 证明九个 frozen meshes 的 connectivity/material pairing 和原 mesh/seam/matrix
  oracles 全部通过；
- formal `run-005` 的独立、当次重建 artifacts 再次通过同样 gates；
- formal run 达到的后续 stage 按原 schema 和 fail-closed 规则由同一 Skeptic 做
  post-run review。

Diagnostic pass 仅允许声称“repaired mesh implementation 满足 pre-eigensolve reflection/quality
contract”；它不产生 bulk gap、guided-mode eigenpair、reference collection 或
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$，不推翻 §Q 的历史 negative，也不允许 effectivity reveal。
只有 formal `run-005` 的 reached artifacts 经 post-run review 后，才能按原 claim boundary 形成新的
prospective conclusion。

### 15.8 Researcher decision

**Decision: `GO TO SAME SKEPTIC REVIEW`.**

当前最小 blocker 是本修订尚未获同一 Skeptic 审查，因此 Engineer 与
`run-005` 均未授权。若本节通过，最小下一门是 same-attempt bounded mesh-implementation
repair，随后是 Researcher theory-to-code check、non-eigensolve diagnostic 和同一 Skeptic
spec-to-code/artifact review；不启动新 method、不新建 attempt、不开展任何 effectivity comparison。

## 16. 2026-08-28 post-implementation theory-to-code zero-drift audit

Status: **`THEORY-TO-CODE REVISE / MESH DIAGNOSTIC NOT AUTHORIZED / FORMAL RUN NOT AUTHORIZED`**.

本节是对第 15 节获准 implementation diff 的 Researcher 静态审计。审计只读比较了
`test/i4/femref-a1/run_i4_1a.m`、`README.md`、`SYMBOLS.md` 的完整 diff 及修改点相邻函数；
没有执行 MATLAB、Octave、Python、mesh diagnostic 或 scientific run，也没有读取或改写
`run-001`--`run-004` artifacts。因此下列结论是 source-level mapping 结论，不是 runtime evidence，
也不替代同一 Skeptic 的 pre-execution scope/spec review。

### 16.1 Zero-drift findings that pass static inspection

以下对象相对于第 15.2 节和此前冻结设计保持不变：

1. continuous problem、弱形式、$q$-weighted mass、全部 physical constants 和原始 geometry
   points；ordinary-cell removal、disk ring、polygon、outer/cell-boundary constraints 的生成规则
   及 point/constraint 去重规则没有改动；
2. frozen polygon-centroid material classification 仍在 `LOCAL_build_mesh` 中用同一组
   `inpolygon` 结果形成 `material_inside`；新增 material-pair diagnostic 直接消费该同一
   logical vector，没有另建近似 material oracle；
3. `LOCAL_assemble_p1` 的局部 $P_1$ stiffness、consistent weighted-mass 公式没有改动；
   phase signs、corner identification 以及 $P^*KP$、$P^*MP$ reduction 没有改动；
4. 40/48 complete-return gates、119-solve schedule、B3 alias reuse、root solver、bulk-gap 与
   raw edge-buffer gate、defect branch/cluster inventory、coverage、四轴 refinement、
   empirical uncertainty 和 non-certified claim boundary 没有 diff；
5. 没有新增 matrix post-symmetrization、matrix averaging 或 tolerance relaxation；
   `coordinate_tolerance`、`constraint_tolerance`、`reflection_tolerance` 和 resource floors/caps
   保持冻结值；
6. one-argument formal entry 仍从 source 调用同一 `LOCAL_preflight_audit` 重建九个 meshes，
   不读 `diagnostics/`、历史 output、Markdown、Git 或 reference cache；two-argument dispatch
   在进入 formal path 前立即 return，且静态 control flow 上不经过 `eigs`；
7. two-argument path 的 ID/mode 被锁定为 `mesh-repair-001` / `mesh-diagnostic`，调用同一
   frozen nine-mesh schedule 和 resource forecast，声明 $0$ eigensolves，不导出 reference，
   临时 mesh cache 不供 formal run 复用；30 min / 1.5 GiB preflight 与 30 min / 2 GiB
   shared-budget semantics 没有漂移；
8. `README.md` 和 `SYMBOLS.md` 的实质改动只描述新增 dispatch、repair 和 ledger mapping；
   Git-visible change set 中没有新增 `diagnostics/`、`output/run-005/` 或其他未授权文件/目录。

这些通过项确立的是“原 scientific contract 未被有意改写”，不能补足下述 mesh-validity
blocker。

### 16.2 Blocker: repaired triangles are not yet proven to be a valid planar mesh

`LOCAL_reflection_closed_triangles` 当前对原 constrained-Delaunay triangles 作如下处理：保留
已有 reflected partner 的 triangle orbit；对于缺 partner 的对象保留 negative-$x$ centroid
代表并插入其 reflection，同时丢弃原 positive-$x$ 代表。它随后检查 centered/unbalanced
inventory、unordered duplicate rows，以及 absolute triangle-area sum 与 rectangular domain area
的一致性。`LOCAL_triangle_reflection_diagnostics` 又检查每个 unordered triangle 的唯一 reflected
partner 和 paired material label，constraint oracle 检查原 constraint segments 仍出现在 edge set 中。

这些检查足以证明离散 connectivity/material inventory 的 reflection closure，却不足以证明第
15.3 节明确要求的 **no overlap / no hole / valid conforming planar complex**。具体反例是：局部
triangle overlap 与另一处等面积 hole 可以同时存在；若两者成反射对，则 unordered-row uniqueness、
reflection pairing、total absolute area、constraint presence、minimum angle、material pairing 以及后续
matrix reflection oracle 都可能通过。当前 source 没有 edge-incidence/free-boundary、nonincident-edge
intersection 或等价 topology/conformity oracle。因此 diagnostic 的 `closure_pass` 可能把一个对称但
无效的 triangle complex 标为 `PASS`。

**Classification: `blocker`.** 在补足该证据前，不能声称 deterministic connectivity repair
“genuinely enforces reflection closure without introducing overlap/hole”，也不能执行第 15.5 节
diagnostic。

### 16.3 Smallest bounded implementation obligations

同一 Engineer 的最小有界修订仍只能落在第 15.3 节已授权的 connectivity/oracle plumbing，不得
改变 tie selection、points、constraints、material rule、$P_1$ forms、tolerances、solve schedule 或
scientific gates：

1. 在 formal 与 diagnostic 共用的 `LOCAL_build_mesh` preassembly path 中增加 fail-closed
   planar-complex validity oracle；
2. machine-checkable evidence 至少须证明：unordered triangles 唯一；每条 edge 的 triangle
   incidence 只能为 1 或 2 且绝不大于 2；incidence-1 boundary edge multiset 恰好等于 frozen
   outer-rectangle boundary segmentation，从而不存在 interior free boundary 或缺失 outer boundary；
   nonincident straight edges 不相交；triangle adjacency 覆盖一个 connected rectangular domain；
   frozen constraints 全部仍为 mesh edges；现有 signed-area 和 total-area checks 保留；
3. 若采用严格等价但更便宜的 planar-conformity criterion，必须在 source/ledger 中明确给出等价对象
   与 fail condition，不能只用 area equality 代替 topology；
4. 将上述 counts/pass/reason 写入 mesh ledger，并纳入 diagnostic 的 all-nine-mesh
   `closure_pass`，任何 unresolved classification 都 fail closed；
5. `SYMBOLS.md` 当前把 `connectivity_area_defect` 称作 no-hole/no-overlap gate，须机械降级为
   coverage-area check；`README.md` 的对应表述只能在新 topology oracle 实际存在后声称完整
   no-hole/no-overlap evidence。

### 16.4 Important diagnostic-publication caveat

`LOCAL_run_mesh_diagnostic` 在 system-temporary work directory 成功创建之前先创建最终
`diagnostics/mesh-repair-001/`，而 temporary-work creation 位于 `try` 外。如果该步骤失败，会遗留
一个占用 create-once ID、但没有 terminal machine-readable summary 的目录。这不改变科学公式，
但不完全满足第 15.5 节“create-once、atomic、failure retains terminal status”的 publication
contract。

**Classification: `important caveat`.** 最小修复是先成功创建 disposable work area，再 claim
最终 create-once path；或把该失败纳入能原子发布 terminal summary 的受控路径。每个正式 artifact
仍须用现有 atomic writer，且不得把 diagnostic cache 暴露给 formal run。外部强制终止不在这一
可捕获失败承诺内。

### 16.5 Minor documentation caveat and decision

除 `connectivity_area_defect` 的 overclaim 外，`README.md` / `SYMBOLS.md` diff 是 mechanical
mapping；未发现另一个独立的 scientific drift。该 overclaim 随第 16.3 节同一有界修订处理。

**Researcher decision: `REVISE`.** 当前不授权
`run_i4_1a('mesh-repair-001','mesh-diagnostic')`，更不授权 `run-005`。最小下一门是同一 Engineer
完成第 16.3--16.4 节的 source/ledger/doc 修订；随后由同一 Researcher 再做一次只读
theory-to-code zero-drift audit。只有该 audit 无 blocker 后，才把 source 和 diagnostic scope 交回
同一 Skeptic 作 pre-execution review；Skeptic 的明确授权仍是运行 diagnostic 的必要条件。

## 17. 2026-08-28 bounded repair re-audit

Status: **`THEORY-TO-CODE PASS / HANDED TO SAME SKEPTIC / DIAGNOSTIC NOT YET AUTHORIZED`**.

本节只读复核了第 16.3--16.4 节所要求的有界 source、ledger 和 mechanical documentation
修订。检查对象仍限于 `test/i4/femref-a1/run_i4_1a.m`、`README.md`、`SYMBOLS.md` 的完整
working-tree diff 及修改点相邻函数；没有执行 MATLAB、Octave、Python、mesh diagnostic 或
scientific run，没有读取或改写历史 output。以下为 source/spec mapping verdict，不是 diagnostic
artifact verdict，也不构成运行授权。

### 17.1 Planar-complex repair contract

`LOCAL_planar_complex_diagnostics` 现已在 signed-area gate 之后、material classification 和
$P_1$ assembly 之前由 formal/diagnostic 共用的 `LOCAL_build_mesh` 调用，并 fail closed 地形成：

1. sorted vertex triples 的 unordered-triangle uniqueness；
2. 全部 triangle-edge occurrences 的 incidence inventory，要求每条 unique edge 的 incidence
   恰为 1 或 2，任何 incidence 大于 2 另有显式 nonmanifold count；
3. incidence-1 edge set 与由 frozen point set 在四条 outer-rectangle sides 上诱导的 consecutive
   segmentation 双向集合相等；`interior_free_boundary_count` 和
   `missing_outer_boundary_count` 分别记录两向差集；
4. frozen constraint multiset canonicalization 后的每一 segment 都必须属于同一 unique-edge set；
5. 全部 unique edges 的 deterministic lower-$x$ sweep；由于排序首键是 bounding-box lower
   $x$，inner loop 只在后继 lower $x$ 严格超过当前 upper $x$ 加 tolerance 时停止，因此每一对
   $x$-box 可能相交的 unordered edge pair 恰被考虑一次；$y$-box pruning 同样不会删除真实
   intersection；无共享 node 的候选再由 proper-crossing 和 collinear/touching tests 判定；
6. 由 incidence groups 构造的 triangle edge-adjacency graph 只允许一个 connected component；
7. 原 reflection repair 的 unordered duplicate 与 rectangular total-area checks，以及 repair 后
   strictly-positive signed-area gate均保留。

对第 16.2 节反例的定向复核结果是：area equality 不再单独承担 no-hole/no-overlap 证明；interior
free boundary、missing outer boundary、nonmanifold incidence、nonincident intersection 和 component
五类独立 ledger 会共同使该情形 fail closed。sweep 排除共享-node edge pair 是允许合法 vertex
incidence 所必需；在本冻结 builder 中，repair 的每条 edge 要么来自原 constrained-Delaunay
triangulation，要么是该 edge 在同一 reflection-closed point set 上的镜像。因而共享 node 的部分
共线重叠会要求一个 frozen vertex 位于某条原 edge 或其镜像 edge 的内部，与 source
triangulation 的 straight-line simplicial connectivity 不相容；共享 edge 的同侧 fold 若无该退化，
会产生一对无共享 node 的 crossing edges，并由 sweep 捕获。该结论只适用于第 15.2 节冻结的
point/constraint builder，不推广为任意外部 triangle soup validator。

intersection helper 接收冻结的 `constraint_tolerance = 2e-12`。bounding-box tests 用它作闭合
padding；orientation 的严格异号捕获 proper crossing，而 near-zero cross product 联合 padded
point-on-segment 捕获 collinear/touching。对本项目 $x\in[-5.5,5.5]$、$y\in[-0.5,0.5]$ 的固定
coordinate scale，该阈值覆盖 double-precision collinearity roundoff，并倾向把近接触降级为
failure，而不会把真实 proper crossing 放行。

### 17.2 Ledger, checkpoint and diagnostic closure alignment

`mesh-ledger.csv` header、`artifacts.mesh_rows`、`LOCAL_mesh_oracles`、
`LOCAL_initial_mesh_diagnostic` 和 `LOCAL_mesh_diagnostic_row` 现统一为 36 columns：

- columns 19--23 是 repair-area/reflection/material fields；
- columns 24--33 是 duplicate、incidence、boundary、intersection、component 和 aggregate
  planar pass fields；
- column 34 是 `reached_boundary`，columns 35--36 是 immutable first failure code/reason。

完成 seam 后只写 column 34；failure checkpoint 只回填 columns 35--36。diagnostic
`closure_pass` 对九个 meshes 和九个 seam rows 作硬 gate，并逐列要求 tie/reflection/material、
duplicate/incidence/boundary/intersection 全部为零，boundary count 相等，component 与 aggregate
planar pass 均为 1。constraint retention 同时进入 aggregate planar pass；若它失败，shared
builder 会在返回完整 mesh row 前 checkpoint 并终止，因此不存在 column 13 失败却由
`closure_pass` 放行的路径。

### 17.3 Diagnostic publication and isolation

`LOCAL_run_mesh_diagnostic` 现在先检查 final-ID collision，再成功创建 system-temporary work area，
最后才 claim `diagnostics/mesh-repair-001/`；temporary creation 失败不会占用 create-once final ID。
claim 之后的 environment、九 mesh preflight、ledger/resource publication 均在 terminal-summary
catch path 内。CSV/MAT writers 继续使用 `.partial` 后原子 move，catchable failure 会写入
machine-readable summary。temporary mesh cache 由 cleanup 删除，不作 reference export，也不供
formal path 复用。

two-argument path 在 dispatch 后 return，静态 control flow 不到达唯一 `eigs` call；summary
固定记录 completed eigensolves $=0$、reference exported false 和 non-reference claim boundary。
one-argument formal path 未增加任何 diagnostic/history/Markdown/Git read，并仍从 source 重建九个
meshes。resource preflight 仍计算 40/48 workspaces、symbolic fill、cache/export buffers 和
72 bulk + 47 defect $=119$ solves，将当次 mesh/oracle elapsed 纳入同一 30 min / 1.5 GiB
preflight 与 30 min / 2 GiB shared-budget semantics。

### 17.4 Scientific zero-drift and documentation scope

完整 diff 再次确认 continuous problem、weak form、physical constants、原 point coordinates、
ordinary-cell removal、disk polygon/rings、constraint generation/deduplication、frozen
polygon-centroid material classification、local $P_1$ stiffness/weighted-mass formulas、phase signs、
corner mapping、$P^*KP$ / $P^*MP$、40/48 complete-return gates、119-solve schedule、root solver、
bulk gap/edge-buffer、branch/coverage、四轴 refinement、empirical uncertainty、information isolation
与 claim boundary 均未改变。没有 matrix post-symmetrization、matrix averaging 或 tolerance
relaxation。

`README.md` 已把 `connectivity_area_defect` 降级为 coverage-area check，并把完整
no-hole/no-overlap evidence 正确归于 shared planar oracle；`SYMBOLS.md` 的同一 overclaim 已修正，
新增条目与 source fields/helpers 对齐。Git-visible scope 中没有新增 `diagnostics/`、
`output/run-005/` 或其他未授权文件/目录。

### 17.5 Classification and decision

- **blocker:** none found in the bounded source/spec mapping;
- **important caveat:** none unresolved at this pre-execution gate；runtime mesh/oracle 与 resource
  pass 仍须由尚未运行的九 mesh diagnostic 提供，不能从静态审计推断；
- **minor caveat:** orientation test 复用一个 absolute tolerance，适用于上述 frozen coordinate
  scale，但未来若 rescale geometry，必须重新冻结 scale-aware orientation tolerance；这不影响本轮
  frozen diagnostic。

**Researcher decision: `THEORY-TO-CODE PASS`.** source scope 现交回同一 Skeptic 作
pre-diagnostic spec/code review。Researcher 不授权且未运行
`run_i4_1a('mesh-repair-001','mesh-diagnostic')`；只有同一 Skeptic 明确给出无 unresolved blocker
的运行许可后，才可执行该 create-once diagnostic。`run-005` 继续禁止，直至 diagnostic artifact
及同一 Skeptic 的后续 gate 全部完成。

## 18. 2026-08-28 prospective as-built mass-gate diagnostic

Status: **`PROSPECTIVE DIAGNOSTIC DESIGN / SAME SKEPTIC REVIEW REQUIRED / NOT AUTHORIZED TO IMPLEMENT OR RUN`**.

### 18.1 Historical authority and bounded question

第 15--17 节、review §U、`run-005` 及此前全部 verdict/artifacts 保持历史原文和 append-only
身份。本节不把 `run-005` 重分类为 scientific negative，也不改变其 $0/119$ eigensolves、reached
bulk schema 缺失或 unresolved reduced-mass cause。`run-005` label 永久占用；`run-006` 仍未授权。

本修订只冻结一个 cheapest decisive diagnostic：从当前 frozen MATLAB source 在内存中重新构造
`bulk-s12-g24`，在同一 $\alpha=0$、$\beta=0.5$ 和同一 `LOCAL_spec` 下检查 as-built full mass、
phase prolongation 与 raw reduced mass。它回答：positive consistent $P_1$ mass 与 full-column-rank
$P$ 的正定性 invariant 在 node incidence、master support、assembly/storage 还是 raw `chol` 表示层
首次破裂。它不读取 preserved `run-005/work/bulk-s12-g24.mat`，因为 source rebuild 提供更强的
history-independent reproducibility check；也不读取任何历史 output、diagnostic、Markdown、review、
design、Git、BIE/QZ object、estimator 或 reference collection。

### 18.2 Exact dispatch, source object and namespace

唯一 prospective dispatch 冻结为：

```text
run_i4_1a('mass-gate-001','mass-diagnostic')
```

它只能创建一次：

```text
test/i4/femref-a1/diagnostics/mass-gate-001/
```

若 final path 已存在，必须在读写任何 evidence 前以 `DIAGNOSTIC_COLLISION` fail closed，不覆盖、
追加或复用。one-argument formal entry 与既有 `mesh-repair-001` dispatch 的语义均保持不变。

Diagnostic 必须调用 source-owned `LOCAL_spec` 和 `LOCAL_mesh_schedule`，按 ID 唯一定位
`bulk-s12-g24`，并 assert `kind='bulk'`、$N=0$、$s=12$、$n_\Gamma=24$。随后只复用冻结的
`LOCAL_build_mesh`、`LOCAL_assemble_p1`、`LOCAL_periodic_maps` 和
`LOCAL_phase_reduce(spec,mesh,0,'mass-diagnostic')` 所形成的对象。诊断矩阵严格定义为

$$
M_{\mathrm{full}}=\texttt{mesh.mass\_full},\qquad
P=\texttt{reduced.prolongation},\qquad
M_{\mathrm{red}}=P^*M_{\mathrm{full}}P,
$$

其中 $M_{\mathrm{red}}$ 必须是 `LOCAL_phase_reduce` 当次返回的同一 sparse object；不得复制后再
average、drop、threshold、reorder、symmetrize、regularize 或 change storage。唯一 Cholesky 调用是

```text
[R_partial, chol_flag] = chol(M_red)
```

不得在它之前或之后用 $(M_{\mathrm{red}}+M_{\mathrm{red}}^*)/2$、diagonal shift、modified tolerance
或第二个 repaired matrix 形成替代 verdict。

### 18.3 Exact artifact schema

Final namespace 只允许以下 artifacts；所有 CSV integer-list fields 使用升序、分号分隔的 exact IDs，
空集合写空字符串，MAT payload 保留原 numeric arrays 作为 authority：

1. `mesh-ledger.csv`：复用既有 36-column schema，恰有 `bulk-s12-g24` 一行；
2. `seam-checks.csv`：复用既有 12-column schema，恰有 $\alpha=0$ 的 `mass-diagnostic` 一行；
3. `bulk-bands.csv`：复用既有十列 header
   `level,solve_id,alpha,root_index,frequency,eigenvalue,algebraic_residual,cluster_id,cluster_multiplicity,solver_role`，
   必须为 zero data rows；
4. `bulk-gaps.csv`：复用既有十四列 header
   `level,gap_index,lower_edge,upper_edge,contains_cue,inside_guard,lower_change,upper_change,delta_lower,delta_upper,safe_lower,safe_upper,gate_pass,reason`，
   必须为 zero data rows；
5. `mass-node-incidence.csv`，header 固定为
   `full_node_id,triangle_incidence,triangle_used,master_id,p_row_nnz,p_row_column_id,p_entry_real,p_entry_imag,p_entry_modulus`，
   恰有一行 per full point；triangle incidence 直接由 repaired `mesh.triangles(:)` 计数；
6. `mass-master-groups.csv`，header 固定为
   `master_id,group_size,member_node_ids,p_column_nnz,p_support_node_ids,p_entry_modulus_min,p_entry_modulus_max`，
   恰有一行 per unique master；
7. `mass-matrices.csv`，header 固定为
   `matrix_id,rows,columns,nnz,stored_nonfinite_count,zero_row_count,zero_row_ids,zero_column_count,zero_column_ids,diagonal_real_min,diagonal_real_max,diagonal_max_abs_imag,hermitian_defect_absolute_1,hermitian_defect_normalized_1`，
   恰有 `full-as-built` 与 `reduced-as-built` 两行；absolute defect 是
   $\|M-M^*\|_1$，normalized defect 是 $\|M-M^*\|_1/\max(1,\|M\|_1)$；
8. `mass-chol-pivot.csv`，header 固定为
   `chol_call_completed,chol_error_identifier,chol_error_message,chol_flag,partial_factor_rows,partial_factor_columns,partial_factor_nnz,partial_factor_nonfinite_count,pivot_reduced_id,pivot_master_id,pivot_group_size,pivot_full_node_ids,pivot_triangle_incidences,pivot_p_column_nnz,pivot_p_support_node_ids,pivot_reduced_row_nnz,pivot_reduced_column_nnz,pivot_reduced_support_ids,pivot_full_mass_support_node_ids,pivot_diagonal_real,pivot_diagonal_imag,pivot_row_nonfinite_count,pivot_column_nonfinite_count`，
   恰有一行。若 `chol_flag=0`，全部 pivot-only fields 为空或 `NaN`；若
   $1\leq\texttt{chol\_flag}\leq\dim M_{\mathrm{red}}$，该 flag 就是 failing reduced pivot ID，并必须
   追溯至同号 master group、full-node members、各 member triangle incidences、$P$ column support、
   reduced row/column support 与这些 full nodes 的 full-mass support union；
9. `mass-summary.csv`，header 固定为
   `diagnostic_id,input_kind,model_id,model_digest,mesh_id,phase_kind,alpha,beta,full_point_count,triangle_used_point_count,unused_point_count,unused_point_ids,master_min,master_max,master_unique_count,p_rows,p_columns,p_nnz,p_zero_support_column_count,p_zero_support_column_ids,p_entry_modulus_min,p_entry_modulus_max,chol_flag,completed_eigensolves,reference_exported,evidence_complete`；
10. `mass-summary.mat`：唯一 top-level `payload`，至少保存 frozen identity、points/triangles、
    per-node incidence、unused IDs、`master_index`、group/member arrays、exact $P$、exact
    $M_{\mathrm{full}}$、exact $M_{\mathrm{red}}$、`R_partial`、`chol_flag`、matrix diagnostics 和 pivot
    support identity；
11. `diagnostic-summary.csv/.mat`：terminal lifecycle schema 固定为
    `diagnostic_id,status,input_kind,mesh_id,alpha,completed_eigensolves,reference_exported,bulk_band_rows,bulk_gap_rows,evidence_complete,wall_estimate_minutes,peak_estimate_gib,elapsed_seconds,failure_code,failure_reason,claim_boundary`；MAT 同样只有 top-level `payload`。

`input_kind` 必须等于 `SOURCE_REBUILD_MATCHING_FROZEN_RUN005_SPEC`；
`completed_eigensolves=0`、`reference_exported=false`、`bulk_band_rows=0`、`bulk_gap_rows=0` 是 hard
gates，不是 narrative labels。`mass-summary.mat` 中保存 matrices 仅用于本 diagnostic 的 as-built
audit，不得成为 future formal cache 或 reference input。

### 18.4 Execution order and atomic failure semantics

唯一允许的 stage order 是：

1. validate exact two-input dispatch and final-path collision；
2. create final namespace once，初始化 `diagnostic-summary` 为 `RUNNING`；
3. 立即用 existing atomic CSV writer 创建 header-only `bulk-bands.csv`、`bulk-gaps.csv`，并为
   四个 `mass-*.csv` 建立 schema-complete header-only files；
4. load source-owned spec，唯一选择 frozen mesh item，从 source build 一张 mesh，写一-row
   mesh/seam ledgers；
5. 形成 raw $P$、$M_{\mathrm{full}}$、$M_{\mathrm{red}}$，先计算并保留全部 node/master/matrix
   evidence；
6. 对同一 raw $M_{\mathrm{red}}$ 执行一次 two-output `chol`，保留 partial factor 与 pivot mapping；
7. 原子发布四个 populated mass CSVs、`mass-summary.csv/.mat` 和 terminal
   `diagnostic-summary.csv/.mat`；验证两个 bulk files 仍只有 header；
8. 只有第 7 步全部成功后，才允许对 `chol_flag>0` 抛出 diagnostic terminal error。若
   `chol_flag=0`，以 `MASS_DIAGNOSTIC_COMPLETE_CHOL_PASS` 正常停止；两者都不是 scientific success。

任一 pre-evidence exception 必须写 terminal status `MASS_DIAGNOSTIC_INCOMPLETE` 和 first failure。
`evidence_complete` 只表示第 18.3 节全部 required measurements 已成功计算并原子发布，不表示
structural invariant pass；unused/nonfinite/zero-row、noncontiguous master IDs、$P$ row support 不等于
1 或 zero-support column 都必须作为 complete diagnostic finding 保留，不能提前中止而隐藏后续
raw `chol` evidence。只有 required field 无法计算、two-output `chol` 未返回、`chol_flag` 越界而
pivot identity 无法形成、或 artifact/header row-count mismatch 才使 `evidence_complete=false` 并
fail closed。Intentional Cholesky failure 的 terminal status 是
`MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL`；它要求 evidence complete，不能被 generic
`EXECUTION_UNAVAILABLE` 覆盖。每个 CSV/MAT 使用 `.partial` 后 atomic move；如果证据无法原子发布，
不得抛出或保留一个看似已诊断的 mass verdict。

### 18.5 Allowed implementation plumbing and prohibitions

只有本节经同一 Skeptic review 后，才可把以下 diagnostic-only plumbing 交给同一 Engineer：

- 在 existing entry dispatch 中加入上述 exact ID/mode，同时保持 one-input 和
  `mesh-repair-001` branches byte-for-byte equivalent in semantics；
- 新增 `LOCAL_run_mass_diagnostic`、pure `LOCAL_mass_gate_diagnostics`、pivot-support mapping 和上述
  atomic writers；
- 复用 existing `LOCAL_write_bulk_artifacts` 生成 diagnostic namespace 的 empty bulk headers；
- 对 `README.md` / `SYMBOLS.md` 作 exact dispatch/schema 的 mechanical synchronization。

本轮 implementation 不得修改 one-argument formal stage order、`LOCAL_low_spectrum`、任何 formal
mass raise、formal bulk writer placement 或 run-005 artifacts。尤其在 diagnostic result 前禁止：

- active-DOF removal、node/master reindex、cache rewrite、$P$ support repair 或 $P^*MP$ storage repair；
- matrix post-symmetrization、averaging、thresholding、diagonal shift、pivoting-rule substitution 或
  tolerance relaxation；
- continuous problem、weak form、$q\in\{1,17\}$、geometry、points、constraints、mesh repair、
  $P_1$ formulas、phase signs、periodic equivalence、119-solve schedule、branch/coverage/refinement/
  uncertainty rules、information isolation 或 claim boundary 的任何改变。

Engineer 必须先提交 source diff；Researcher 做 zero-drift/theory-to-code check；同一 Skeptic 做
pre-execution spec/code review。没有这两门，diagnostic command 仍禁止。

### 18.6 Resource, isolation and lifecycle gates

review §U.2 的 preserved evidence 表明完整九-mesh preflight 到 first mass gate 的 external real time
为 20.71 s、maximum RSS 约 0.736 GiB；本 diagnostic 只 build 第一张 coarse mesh、一次 phase
reduction 和一次 `chol`。因此 prospective conservative estimate 冻结为 **2 min wall / 1.0 GiB
peak**，在默认 30 min / 2 GiB limits 内。若实现后的 static/resource review 不能支持小于 30 min
和 2 GiB，则 diagnostic 变为 `RESOURCE_BUDGET_UNAVAILABLE`，不得启动。单条 command 的全部 setup、
mesh build、evidence publication 和 cleanup 共用一只 clock；30 min soft、一次 10 min grace 和
40 min / 2 GiB hard limits 不因 diagnostic stage 或 subprocess 重置。

该 diagnostic 是 `femref-a1` same-attempt implementation evidence，不创建新 attempt、不消费 scientific
attempt，也不恢复 `run-005`。它不得写 `output/`、不得产生 eigenvalue、bulk band/gap row、field、
branch、reference collection 或 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$。唯一 prospective command 是：

```text
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('mass-gate-001','mass-diagnostic')"
```

本节记录命令但不授权或执行它。

### 18.7 Postdiagnostic decision tree

同一 Skeptic 对完整 artifact 做 postdiagnostic review 前，不得采取任何 repair：

1. 若存在 unused nodes、full-mass zero/nonfinite rows、nonpositive/nonfinite diagonal 或 assembly
   support defect，根因归入 active-DOF/assembly/cache representation；仅可另拟最小 indexing 或 cache
   plumbing repair，consistent-mass formula不变；
2. 若 master IDs/groups 或 $P$ 有 zero/duplicate/missing support，根因归入 canonical/master/
   prolongation implementation；仅可另拟保持同一 equivalence classes 与 phase factors 的 support repair；
3. 若 full mass 与 $P$ 正常而 raw reduced mass 出现 zero/nonfinite/support abnormality，根因归入
   $P^*MP$ construction/storage；仅可另拟数学乘积不变的 representation repair；
4. 若全部 structural evidence 正常、`chol_flag>0` 且只剩 tiny non-Hermitian representation 作为解释，
   必须停止；任何 exact-Hermitian canonicalization 都需要新的 explicit specification amendment、
   Researcher theory-to-code map 和同一 Skeptic review，不能作为 silent bug fix；
5. 若 source rebuild 给出 `chol_flag=0` 而 preserved `run-005` 为 nonzero，归类为 unresolved
   reproducibility/cache/environment discrepancy；不自动修 formal source，也不授权 retry；
6. 若 diagnostic incomplete、证据相互矛盾或 resource gate 失败，§U blocker 保持 unresolved。

无论哪一分支，formal reached-bulk artifact repair仍须另行冻结：future one-argument path 在
`BULK_INVENTORY stage-start` 后、任何 mass gate 前原子发布 header-only bulk ledgers，并在 future
mass raise 前发布同一 evidence schema。该 formal patch、任何 representation repair 和新的 formal
run ID 都必须经过后续 Researcher bounded revision、theory-to-code audit 与同一 Skeptic pre-run gate。
**`run-006` 继续未授权。**

### 18.8 Researcher decision

**Decision: `GO TO SAME SKEPTIC REVIEW OF BOUNDED DIAGNOSTIC DESIGN`.**

当前 blocker 不是 diagnostic method 未定义，而是本节尚未通过同一 Skeptic 的独立 design review。
在该 review 给出无 unresolved blocker 的 `PASS` 或 `PASS WITH CONDITIONS` 之前，Engineer 不得落地
source plumbing，任何人不得运行 `mass-gate-001`，也不得修改 formal path 或创建 `run-006`。

## 19. 2026-08-28 mass-diagnostic post-implementation zero-drift audit

Status: **`THEORY-TO-CODE PASS / HANDED TO SAME SKEPTIC / MASS DIAGNOSTIC NOT YET AUTHORIZED`**.

### 19.1 Audit frame and preserved baseline

本节只审计 Engineer 对第 18 节、review §V 所作的 bounded diagnostic plumbing；未运行 MATLAB、
Octave、Python 或任何数值程序，也未创建或读取 `mass-gate-001` artifact。第 17 节已通过的 mesh
source baseline、preserved `mesh-repair-001` artifact、`run-001`--`run-005` 和 review §U--§V 均保持
历史身份。本节不是 diagnostic artifact review，不授权 diagnostic command、formal repair、
representation repair 或 `run-006`。

审计对象是 `run_i4_1a.m` 的 complete entry dispatch、`LOCAL_run_mass_diagnostic`、
`LOCAL_empty_mass_artifacts`、mass CSV/MAT writers、`LOCAL_required_mass_artifacts_present`、
`LOCAL_mass_gate_diagnostics`、`LOCAL_mass_matrix_diagnostics`、`LOCAL_chol_pivot_evidence`，以及它们
实际调用的 unchanged `LOCAL_spec`、`LOCAL_mesh_schedule`、`LOCAL_build_mesh`、
`LOCAL_phase_reduce` 和 existing atomic writers；同时核对 `README.md`、`SYMBOLS.md` 与 Git-visible
directory scope。

### 19.2 Entry, source identity and scientific zero drift

**`ESTABLISHED`。** two-input entry 只接受两个 exact pairs：既有
`mesh-repair-001`/`mesh-diagnostic` 分支仍先命中并立即 return；新增分支只接受
`mass-gate-001`/`mass-diagnostic` 并立即 return。其余 two-input pairs fail closed。one-input formal
entry 在 dispatch 后从原 validation、create-once `output/<run_id>/`、stage order 和 source rebuild
继续，未加入 diagnostic/history read；既有 mesh-diagnostic control flow也未改变。

Mass branch 在任何 evidence read/write 前检查 final namespace collision，只创建
`diagnostics/mass-gate-001/`。它从 `LOCAL_mesh_schedule` 按 exact ID 唯一选择 `bulk-s12-g24`，并硬
assert `kind='bulk'`、$N=0$、$s=12$、$n_\Gamma=24$ 和 `spec.beta=0.5`；随后调用
`LOCAL_build_mesh(spec,mesh_spec,...)` 与
`LOCAL_phase_reduce(spec,mesh,0,'mass-diagnostic')`。因此 source identity 是同一 frozen model、
$\alpha=0$、$\beta=0.5$，不是 preserved cache 或历史 matrix 的替代读取。

完整 source diff 没有改变第 17.4 节已核过的 continuous problem、weak form、$q\in\{1,17\}$、
physical constants、point coordinates、ordinary-cell removal、polygon/ring/constraint construction、
material classification、local consistent $P_1$ formulas、periodic equivalence、phase signs、corner map 或
$P^*KP$/$P^*MP$。formal `LOCAL_low_spectrum` 仍直接以 raw `reduced.mass` 作原有 mass gate 和
`eigs` input；formal bulk-header placement、119-solve schedule、root solver、bulk gap/edge buffer、
branch/coverage、四轴 refinement、empirical uncertainty、information isolation 与 claim boundary 均未
改变。没有 matrix averaging、post-symmetrization、threshold、shift、tolerance relaxation、DOF/master
repair 或 storage repair。

### 19.3 Raw mass evidence and Cholesky identity

**`ESTABLISHED`。** `LOCAL_mass_gate_diagnostics` 从同一当次 `mesh.triangles(:)` 以
`accumarray` 形成 every-full-node triangle incidence 和 unused IDs；从原
`mesh.periodic.master_index` 形成 unique masters、每组 full-node members，并从 exact
`reduced.prolongation` 形成每行/每列 support、zero-support column IDs 和 entry moduli。四份 CSV 的
row widths 分别为冻结的 9、7、14、23 columns；node ledger 恰有 one row per full point，master
ledger 恰有 one row per unique master，matrix ledger 恰有 `full-as-built` 与 `reduced-as-built` 两行，
pivot ledger 恰有一行。

Full/reduced matrix rows直接记录 dimensions、`nnz`、stored nonfinite count、zero rows/columns、
diagonal real extrema、maximum diagonal imaginary magnitude、$\lVert M-M^*\rVert_1$ 和
$\lVert M-M^*\rVert_1/\max(1,\lVert M\rVert_1)$。Diagnostic 内唯一 factorization call 是对
`LOCAL_phase_reduce` 返回的同一 sparse object执行：

```text
[partial_factor, chol_flag] = chol(reduced.mass)
```

该 call 没有 third output、permutation、pre/post canonicalization 或 second verdict matrix。返回 flag
必须是 $0\leq p\leq\dim M_{\mathrm{red}}$ 的 finite real integer；call error 或越界使 measurements
incomplete。$p=0$ 时 pivot-only fields 保持 empty/`NaN`；$1\leq p\leq\dim M_{\mathrm{red}}$ 时直接按
natural 1-based reduced ID $p$ 映射同号 master、group/full nodes、per-member incidences、$P$ column
support、reduced row/column support union、这些 full nodes 的 full-mass support union、diagonal 和
row/column nonfinite counts。partial-factor dimensions、`nnz` 和 nonfinite count 独立记录。MAT payload
保留 points/triangles、incidence、unused IDs、master/group arrays、exact $P$、exact full/reduced mass、
partial factor、raw flag、matrix diagnostics 和 pivot-support identity，而不是只保留 CSV 摘要。

Structural negative findings不会被当作 incomplete 而提前隐藏：unused nodes、noncontiguous masters、
abnormal $P$ support、zero/nonfinite mass support仍可随 valid raw flag形成 complete evidence；只有
required measurement/call/flag/schema/publication不能完成才 fail closed。这与第 18.4 节的 diagnosis
boundary一致。

### 19.4 Artifact lifecycle, isolation and resource gate

**`ESTABLISHED`。** namespace 创建后首先用 existing atomic CSV writer发布 zero-row
`bulk-bands.csv`、`bulk-gaps.csv` 及四个 header-only mass ledgers。随后只 source-build 一张 mesh，
发布恰一行 36-column mesh ledger与恰一行 12-column $\alpha=0$ seam ledger，再发布 populated mass
ledgers和 `mass-summary.csv/.mat`。in-memory hard gates要求 bulk band/gap row counts均为零、node/master/
matrix/pivot 和 mesh/seam row counts完整、`completed_eigensolves=0`、`reference_exported=false`，并要求
全部 required final files存在且无 `.partial` peer。

`diagnostic-summary.mat` 在全部 evidence 之后原子写入，`diagnostic-summary.csv` 是最后写入的原子
commit marker；若它缺失，则 namespace不能按 `SYMBOLS.md` 合同解释为 terminal complete。只有该
terminal pair写入后，`MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL` 才 raise；pre-evidence 或 publication
异常写 `MASS_DIAGNOSTIC_INCOMPLETE`。每个 writer使用 local `.partial` 后 atomic move。Mass path不
创建 work/cache temporary directory，故没有可供 formal path复用或需要 success cleanup 的 mesh
cache；writer failure留下的 `.partial` 反而使 required-artifact gate fail closed。

静态 call graph从 mass branch不到达唯一 `eigs` call、formal cache `load`、field/branch/reference
exports或 `LOCAL_low_spectrum`。它不读 `run-005`、既有 diagnostic、Markdown、review/design、Git、
BIE/QZ、estimator 或 historical output，也不写 `output/`。当前工作树中没有
`diagnostics/mass-gate-001/`，只有 preserved `diagnostics/mesh-repair-001/`；因此 implementation没有
偷跑 diagnostic 或占用 create-once ID。

代码冻结 `wall_estimate_minutes=2`、`peak_estimate_gib=1`，用一只 `tic` 覆盖 namespace、build、
phase reduction、factorization、publication 和 terminal summary。该 prospective estimate沿用 §18.6
依据，低于 30 min/2 GiB default limits；它不是实际 measurement，真正 wall/RSS enforcement仍须由
同一 Skeptic在 pre-execution gate核对 exact command与外部 monitor。Mass path没有 subprocess、
stage 或 cache可用于重置预算。

### 19.5 Documentation and classified findings

§18-specific `README.md` 变更只登记 exact dispatch、source identity、evidence类别、zero-eigensolve/
no-reference boundary、2 min/1 GiB estimate及 formal nonauthorization；`SYMBOLS.md` 新增的 mass
objects、shapes、raw-object/pivot语义和 terminal CSV commit marker均与 source一致，没有把 diagnostic
提升为 reference/effectivity result。

- **blocker:** none found in the bounded §18 source/spec mapping；
- **important caveat:** §V.3 的 source-rebuild limitation保持：若 raw `chol` pass，它只能证明 current
  source未复现 historical failure，不能关闭 `run-005` root cause；此外 2 min/1 GiB仍是待同一 Skeptic
  动态监控的 prospective estimate；
- **minor caveat:** current `README.md` 的既有 mesh-diagnostic paragraph仍写“has not been run”，但
  preserved `diagnostics/mesh-repair-001/diagnostic-summary.csv` 已记录 `PASS`。该陈述不属于新增 mass
  control flow，也不改变任何 diagnostic evidence；本轮无 README 写权限，故只登记为后续最小
  documentation synchronization，而不据此阻止 mass pre-execution review。

### 19.6 Researcher decision and next gate

**Researcher decision: `THEORY-TO-CODE PASS`.** 第 18 节 bounded implementation的 source/spec
mapping已闭合，现按 review §V交回同一 Skeptic作 pre-execution spec/code/resource review。Researcher
不授权且未运行：

```text
run_i4_1a('mass-gate-001','mass-diagnostic')
```

只有同一 Skeptic明确确认本节映射、terminal commit contract和 external 2 min/1 GiB monitoring均无
unresolved blocker后，才可执行 create-once diagnostic。其结果仍须回到同一 Skeptic作 artifact/
postdiagnostic review；formal representation repair、formal bulk-header repair与 `run-006` 继续未授权。

## 20. 2026-08-28 prospective `mass-gate-002` publication repair

Status: **`PROSPECTIVE OPERATIONAL PUBLICATION REPAIR DESIGN / SAME SKEPTIC REVIEW REQUIRED / NOT AUTHORIZED TO IMPLEMENT OR RUN`**.

### 20.1 Immutable history and bounded question

第 15--19 节、review §U--§X、`run-005` 以及
`diagnostics/mass-gate-001/` 的全部 final artifacts和
`mass-node-incidence.csv.partial` 保持 immutable、append-only history。`mass-gate-001` 已永久消费其
create-once ID；不得删除 `.partial`、补写、覆盖、追加、重命名、移动、清理或重跑 001。review §X 的
verdict保持：001 是 `MASS_DIAGNOSTIC_INCOMPLETE / EXECUTION_UNAVAILABLE` operational publication
failure，completed eigensolves为0且没有 durable raw-mass/`chol` verdict；它不证明或否定 reduced-mass
definiteness，不解析 `run-005` root cause，也不消费 scientific attempt。

本修订只回答一个 representation-boundary 问题：怎样在不改变 $P$、$M_{\mathrm{full}}$、
$M_{\mathrm{red}}=P^*M_{\mathrm{full}}P$、raw two-output `chol` 或任何 formal/scientific path 的前提下，
把第 18.3 节已冻结的 evidence rows可靠发布为 CSV。§X 已建立的 first failure mechanism是
`p_row_support(node_id)` 保留为 sparse $1\times1$ numeric，随后 shared scalar serializer对 sparse input
调用 `sprintf` 失败。允许的修复仅是 diagnostic evidence/CSV boundary上的 value-preserving sparse-to-full
scalar representation normalization；它不是 mass representation repair，更不是对 matrix作 dense copy。

### 20.2 Complete mass-row representation audit and exact repair

本节对 002 将发布的全部 mass-related CSV data cells作以下 source-level inventory：

| Ledger | Numeric origin | Static representation judgment | Frozen 002 treatment |
|---|---|---|---|
| `mass-node-incidence.csv` | loop/node IDs、dense incidence/master arrays、sparse $P$ row support、显式 `full` 的 one-entry $P$ value | `p_row_nnz` 是 §X 已证 unsafe sparse scalar；其余 numeric cells是 ordinary full scalar | 在 node-row construction处只对 `p_row_support(node_id)` 取 `full`；不得对整个 $P$ 取 `full` |
| `mass-master-groups.csv` | dense master/member IDs、`numel` counts、`nonzeros(P(:,j))` 的 full value vector及其 extrema | 无已知 sparse scalar；list fields已是 character strings | value不变，并进入下述 all-row hard type audit |
| `mass-matrices.csv` | `size`/`nnz` counts、ID strings、sparse diagonal reductions、matrix norms | diagonal extrema/max-imag可能继承 sparse scalar representation；norm/count outputs是 ordinary scalars | 只对三个 diagonal scalar results取 `full`；不得对 full/reduced matrix或完整 diagonal作 dense copy |
| `mass-chol-pivot.csv` | raw `chol_flag`、partial-factor `size`/`nnz`、support IDs/counts、failed-pivot sparse diagonal entry | positive-flag `pivot_diagonal`可能是 sparse $1\times1$；其他 CSV numeric cells是 ordinary scalars | 只对 selected pivot diagonal scalar取 `full` 后再取 real/imag；partial factor、$P$、mass objects保持 sparse/as-built |
| `mass-summary.csv` | identity、`size`/`nnz`/`numel`、dense extrema、raw flag、boolean gates | 在上述 boundary normalization后应全部为 ordinary scalar或 strings | schema/value不变，并在写入前作同一 hard type audit |
| `diagnostic-summary.csv` | lifecycle counts、elapsed/resource scalars、status/reason strings | 无 sparse source，但它是 terminal commit marker | schema/value不变，并在最后写入前作同一 hard type audit |

Exact minimal normalization被冻结为等价于以下 value semantics；变量名可为现有名称，但不得扩大作用域：

```text
p_row_nnz = full(p_row_support(node_id))
diagonal_real_min = full(min(real(diagonal_values)))
diagonal_real_max = full(max(real(diagonal_values)))
diagonal_max_abs_imag = full(max(abs(imag(diagonal_values))))
pivot_diagonal = full(reduced.mass(pivot_id,pivot_id))
```

Empty-diagonal 和 $p=0$ branches继续返回原 `NaN`/empty semantics；不得为了执行上述转换形成
`full(P)`、`full(M_full)`、`full(M_red)`、`full(R_partial)` 或任何 alternative matrix。

在四张 populated mass ledgers、`mass-summary.csv` 和 terminal `diagnostic-summary.csv` 的各自 writer
调用前，必须通过一个 **diagnostic-only, nonmutating** row audit：每个 numeric/logical cell只能是 empty
或 ordinary full scalar，不能是 sparse且不能是 nonscalar；integer-list cells继续是升序、分号分隔的
character strings。该 helper不得修改 shared `LOCAL_csv_value`、`LOCAL_write_csv` 或任何 formal artifact
row。若四张 evidence rows或 mass-summary row的 audit失败，必须在 writer前以 first failure code
`MASS_EVIDENCE_REPRESENTATION_UNSAFE` 抛回既有 catch，使 terminal status为
`MASS_DIAGNOSTIC_INCOMPLETE`、`evidence_complete=false`；不得继续 populated publication或把 failure
降级为 complete mass verdict。terminal-summary row必须在 terminal MAT/CSV二者之前通过同一 audit；若
这个最后 audit意外失败，则不得写 terminal MAT或 commit CSV，namespace由缺失 commit marker保持
incomplete，而不能保留一个伪 complete summary。这个 audit是 publication/schema gate，不是 scientific
gate，不检查或改变数值正定性、Hermitian defect、support threshold或 `chol_flag`。

### 20.3 Exact ID, dispatch, source identity and artifacts

唯一 prospective corrected dispatch冻结为：

```text
run_i4_1a('mass-gate-002','mass-diagnostic')
```

它只允许创建一次：

```text
test/i4/femref-a1/diagnostics/mass-gate-002/
```

002 execution不得读取、探测后复用、链接、复制或覆盖 001 namespace中的任一 final/partial artifact；也
不得以001 artifact作为 input、cache、oracle或expected value。002 collision只针对自己的 final path，并
必须在任何 002 evidence read/write前 fail closed。Entry须继续 exact-match
`mesh-repair-001`/`mesh-diagnostic`、`mass-gate-001`/`mass-diagnostic` 和新增
`mass-gate-002`/`mass-diagnostic`；不得接受 prefix、numeric suffix、fallback或 arbitrary diagnostic ID。
001 branch若被调用仍必须因 preserved namespace collision而在 evidence前停止，不能借 shared helper变化
恢复或重写001。

除 `diagnostic_id='mass-gate-002'` 与本节冻结的 CSV scalar representation normalization/type audit外，
§18.2--§18.4 完整复用为 002 contract：

- `input_kind='SOURCE_REBUILD_MATCHING_FROZEN_RUN005_SPEC'`；
- source-owned `LOCAL_spec`/`LOCAL_mesh_schedule` 唯一选择 `bulk-s12-g24`，assert `kind='bulk'`、$N=0$、
  $s=12$、$n_\Gamma=24$，并以 $\alpha=0$、$\beta=0.5$ 调用 unchanged mesh/assembly/periodic/phase helpers；
- 同一 exact sparse $P$、$M_{\mathrm{full}}$、raw $M_{\mathrm{red}}$ 和唯一
  `[R_partial,chol_flag]=chol(M_red)`；
- 与 §18.3 byte-for-byte相同的 filenames、CSV headers、column order、row counts、list encoding和 MAT
  payload authority；只允许 artifact identity从001变为002；
- header-only `bulk-bands.csv`/`bulk-gaps.csv`，one-row mesh/seam ledgers、四张 populated mass ledgers、
  `mass-summary.csv/.mat`，以及 `diagnostic-summary.mat` 后 `diagnostic-summary.csv` 最后提交；
- `completed_eigensolves=0`、`reference_exported=false`、zero bulk rows、required row counts、无 `.partial`
  peer及本节 representation audit全部是 `evidence_complete` hard gates；
- complete raw flag $0$ 与 positive flag分别保留
  `MASS_DIAGNOSTIC_COMPLETE_CHOL_PASS` / `MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL`；任一 call、schema、type或
  atomic publication failure保持 `MASS_DIAGNOSTIC_INCOMPLETE`。只有 terminal evidence全部成功后，才可
  对 intentional positive flag抛出 terminal error。

002 是 same `femref-a1` attempt中的 corrected operational diagnostic，不是第二种方法、new scientific
attempt或 formal retry。只有 complete 002 artifact经过同一 Skeptic postdiagnostic review后，§18.7 decision
tree才可应用；002 incomplete、source rebuild与 `run-005` 不一致或证据矛盾时仍按 §18.7 fail closed。

### 20.4 Allowed implementation scope and prohibited drift

只有本节通过同一 Skeptic design review后，才可把以下 bounded implementation交给同一 Engineer：

1. 仅在 `test/i4/femref-a1/run_i4_1a.m` 加入 exact 002 dispatch/identity plumbing、上述五个 scalar
   representation conversions和 diagnostic-only mass-row type audit；
2. 可把 existing mass diagnostic runner参数化为 exact allowlisted ID，但 one-input formal与既有
   mesh/001 branches必须保持相同语义，且 002不得读取001；
3. 仅对 `test/i4/femref-a1/README.md`、`SYMBOLS.md` 作 exact 002 dispatch、representation gate和
   nonauthorization的 mechanical synchronization，不得写结果叙述；
4. 不创建 002 namespace、input/output、temporary artifact或新 source file，直到后续 run gate明确授权。

明确禁止：

- 修改 shared `LOCAL_csv_value`、`LOCAL_write_csv`、MAT/CSV serialization policy或任一 formal writer；
- 修改、清理或读取001 artifacts，改变001/§X verdict，或把001 `.partial` 当作 disposable temporary；
- 修改 $P$ construction/support、master/DOF indexing、$P^*MP$ formula/storage、raw `chol` call、pivot语义、
  matrix Hermitian tolerance，或进行 symmetrization、averaging、thresholding、shift、reordering、regularization；
- 修改 continuous problem、weak form、physical constants、geometry、points、constraints、mesh repair、
  material classification、$P_1$ formulas、phase signs、119-solve schedule、root/branch/coverage/refinement/
  uncertainty rules、information isolation或 claim boundary；
- formal reached-bulk header repair、formal mass repair、任何 eigensolve/reference/effectivity reveal、
  `run-006` 或 project research-document result synchronization。

Engineer source diff完成后，Researcher须逐项作 theory-to-code zero-drift audit，尤其核对所有 mass CSV
numeric cells的 full-scalar invariant、shared serializer未变和001不可达；随后由同一 Skeptic作
pre-execution spec/code/resource review。两门均无 unresolved blocker前，不得运行002。

### 20.5 Budget, exact proposed command and lifecycle

001 的 external record是14.45 s real、743800832 B maximum RSS（约0.693 GiB），且 failure发生在第一张
populated ledger的 first data row。002只增加常数级 scalar `full` conversions和 row-type checks，不改变
mesh、matrix、factorization或 artifact payload规模。因此 prospective budget仍冻结为 **2 min wall / 1.0
GiB peak**，在 default 30 min/2 GiB与40 min/2 GiB hard limits内；这是 estimate，不继承001 measurement。
同一 command的 startup、source rebuild、evidence、publication、failure handling和cleanup共享一次预算，
不得用 stage/subprocess重置。执行时仍须由同一 Skeptic预先认可的 external monitor独立记录 wall/RSS。

唯一 proposed command是：

```text
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('mass-gate-002','mass-diagnostic')"
```

本节只记录命令，不授权 implementation或 execution。若 implementation static review不能继续支持小于
30 min和2 GiB，状态改为 `RESOURCE_BUDGET_UNAVAILABLE` 并停止；不得创建002 namespace试探预算。

### 20.6 Researcher decision

**Decision: `GO TO SAME SKEPTIC REVIEW OF BOUNDED 002 DESIGN`.** 已知 blocker被收缩为 diagnostic-local
CSV scalar representation/publication contract；没有证据支持修改 scientific method、mass representation
或 formal path。当前最小下一门是同一 Skeptic对本节作独立 design review。本节不授权 Engineer、不授权
运行 `mass-gate-002`、不授权 `run-006` 或任何 formal repair；`mass-gate-001` 及其 `.partial` 继续作为
immutable operational-failure provenance保留。

## 21. 2026-08-28 `mass-gate-002` post-implementation zero-drift audit

Status: **`THEORY-TO-CODE PASS / HANDED TO SAME SKEPTIC / 002 NOT AUTHORIZED TO RUN`**.

### 21.1 Audit frame and historical boundary

本节只审计 Engineer按第 20 节、review §Y 实现的 bounded 002 publication repair。未运行 MATLAB、
Octave、Python、002 diagnostic或任何数值程序，未创建/修改 diagnostic artifact。第 15--20 节、
review §U--§Y、`run-005`、`mass-gate-001` terminal verdict及其 `.partial` 均保持历史身份；本节不把
source mapping提升为 runtime/artifact success，也不授权002、formal repair或 `run-006`。

审计范围是 `run_i4_1a.m` 的 exact entry allowlist、parameterized mass runner、六个 mass-related CSV
row boundaries、五处 scalar conversion、`LOCAL_assert_mass_csv_rows`、existing atomic writers及其到
unchanged source/phase/`chol` objects的 call graph，同时核对 `README.md`、`SYMBOLS.md`、001 inventory和
002 namespace absence。

### 21.2 Exact allowlist, namespace isolation and 001 immutability

**`ESTABLISHED`。** Entry只接受三个 exact pairs：mesh 001、mass 001和mass 002各自的 frozen mode；
mass runner内部 `allowed_ids` 又只允许 `mass-gate-001`、`mass-gate-002`，不存在 prefix/suffix、fallback或
arbitrary ID path。002 exact branch把 `diagnostic_id='mass-gate-002'` 传入 runner并立即 return，runner只以
该 selected ID构造 `diagnostics/mass-gate-002/`，在任何 spec/build/evidence前对自己的 final path作
create-once collision check。002 call graph没有指向001 path的 `exist`、`load`、`dir`、copy、move、link或
cache operation；allowlist中的001只是 character identity，不是 artifact read。

001 exact branch仍先传入 `mass-gate-001`，随后对 preserved final namespace作 collision-before-evidence
stop；不会进入 source build、writer或已修 helper，因此不能补写/覆盖001。当前工作树不存在
`diagnostics/mass-gate-002/`，说明 implementation没有占用002 ID或偷跑 diagnostic。

001 current inventory与 review §X逐项一致：11个 files、四个 header-only final mass CSV、同样
header-only的 `mass-node-incidence.csv.partial`、无 `mass-summary.csv/.mat`，terminal CSV仍是
`MASS_DIAGNOSTIC_INCOMPLETE / EXECUTION_UNAVAILABLE`、zero eigensolves、zero bulk rows、no reference。
全部001 files当前 mtime均为 `2026-08-28T23:29:07+0800`，早于第20节 design/review及本次 source/docs的
`23:41`--`23:49` edits；Git diff中没有001 artifact path。当前只读 SHA-256 snapshot为：

| Artifact | SHA-256 |
|---|---|
| `bulk-bands.csv` | `88326c40b7e3f5800c5d60f5ac0d4e84ab9b43b2125356b845aeb09a8a60e9d1` |
| `bulk-gaps.csv` | `c861d04bb607ef5f33e0e70b0310f77865ac57262702ad8306a4158a5e1a887c` |
| `diagnostic-summary.csv` | `80d47a31af769469d21e76f7aad597023f0bf6e14c0b85ae75c4e009bda34349` |
| `diagnostic-summary.mat` | `9beb1d34460880af580bfc1712d4f96546b5f026d08baf5bfa6681b96624702d` |
| `mass-chol-pivot.csv` | `571ff32fc97111b87243031bd0602464a4196a096bc4eecd13c1b4d9f29307d8` |
| `mass-master-groups.csv` | `76b243a7de29bc906f08c2224abb72ebe6b0b7d132e77cbe0b3b53108680ec97` |
| `mass-matrices.csv` | `57321706f6ad3cd6bb18aa66cfcdc7d690eedc66b372ca30be06dfeeaeb31c97` |
| `mass-node-incidence.csv` | `4390be0b74909ecb585cbe8a47a67b50648e8a6159ad2d50e7744162aae40a6f` |
| `mass-node-incidence.csv.partial` | `4390be0b74909ecb585cbe8a47a67b50648e8a6159ad2d50e7744162aae40a6f` |
| `mesh-ledger.csv` | `52909d53e8f4949b4eca8bd4deac8b7d2e414389639482b8a426e6bfdc19d87a` |
| `seam-checks.csv` | `f9ea74298ab6aa68dd4673ed306909270feef66f50f216c1bd5d7ff92c77bd01` |

这些 locator建立本节后的可复核 baseline。由于 §20 implementation前没有持久化001 digest/mtime table，
本节不能声称 cryptographic pre/post equality；上述 inventory/content/temporal/diff evidence是当前可得到的
最强 bounded immutability证据。

### 21.3 Scalar normalization and schema-safe type gate

**`ESTABLISHED`。** 五处 authorized conversions与 §20.2逐项一致且仅改变 scalar storage class：

1. node row只对 selected `p_row_support(node_id)` 取 `full`；sparse $P$ 和 support vector均不 densify；
2. `mass-matrices.csv` 只对 sparse diagonal的 real minimum、real maximum和maximum imaginary magnitude
   三个 reduction results取 `full`；matrix和完整 diagonal不 densify；
3. positive natural pivot只对 selected `reduced.mass(pivot_id,pivot_id)` 取 `full`，再提取 unchanged
   real/imag；raw reduced mass和 partial factor保持 sparse/as-built；
4. 没有 `full(P)`、`full(M_full)`、`full(M_red)`、`full(R_partial)`，没有 averaging、symmetrization、
   threshold、shift、reorder、regularization或第二个 verdict matrix；
5. 唯一 raw `[partial_factor,chol_flag]=chol(reduced.mass)` call及其 natural 1-based mapping未改变。

`LOCAL_assert_mass_csv_rows` 是 diagnostic-only、nonmutating predicate。它先要求 cell matrix与 exact width，
随后逐 cell允许：ordinary nonsparse scalar或 empty numeric/logical、empty/row character vector，以及可选
scalar MATLAB string；它拒绝 sparse numeric/logical、nonscalar nonempty numeric/logical、multiline/nonrow
character和 unsupported object。它不调用 shared serializer作转换，不 flatten vector，也不检查数值
tolerance或 scientific property。Unsafe cell通过 `LOCAL_raise`产生
`MASS_EVIDENCE_REPRESENTATION_UNSAFE`。

Writer order和 frozen widths静态闭合：

| Boundary | Width | Gate position |
|---|---:|---|
| node evidence | 9 | 与其余三张 evidence rows一起，在任何 populated mass writer之前 |
| master evidence | 7 | 同上 |
| matrix evidence | 14 | 同上 |
| pivot evidence | 23 | 同上 |
| mass summary | 26 | 在 `mass-summary.csv` 和 `.mat`之前 |
| terminal summary | 16 | 在 `diagnostic-summary.mat` 和最终 commit CSV二者之前 |

四张 header-only rows也先通过相同 width/type gate。任一 populated evidence或 mass-summary unsafe value会
在 writer前回到 existing catch并形成 incomplete terminal state；terminal row自身若不安全，则 terminal
MAT/CSV均不写，缺最终 CSV commit marker继续 fail closed。合法 identity/status/failure/claim/list character
cells不会被误拒，integer-list encoding仍由 existing list helpers产生。

### 21.4 Scientific, formal, isolation and atomic zero drift

**`ESTABLISHED`。** 002仍从 `LOCAL_spec`/`LOCAL_mesh_schedule` 唯一选择 `bulk-s12-g24`，硬检查
`kind='bulk'`、$N=0$、$s=12$、$n_\Gamma=24$ 和 $\beta=0.5$，并以 $\alpha=0$ 调用 unchanged
mesh/assembly/periodic/phase helpers。$P$、$M_{\mathrm{full}}$、$P^*M_{\mathrm{full}}P$、mesh/seam ledgers、
raw factorization、pivot evidence、MAT payload及 §18.7 decision tree均未改变。

two-input 002 branch在 mass runner后 return，静态 call graph不到达 `LOCAL_low_spectrum`/`eigs`；summary仍
hard-code completed eigensolves为0、reference exported false、zero bulk rows和 non-reference claim。它不读
Markdown、design/review、Git、BIE/QZ、estimator、historical output或 current reference。one-input formal
stage order、formal raw mass gate、shared `LOCAL_csv_value`/`LOCAL_write_csv`、formal headers、119-solve
schedule、branch/coverage/refinement/uncertainty和 claim boundary没有变化。

Artifact lifecycle仍是 header-first、source rebuild、evidence、populated mass CSVs、mass-summary CSV/MAT、
required-artifact hard gate、terminal MAT，最后 terminal CSV commit marker；atomic `.partial`/move writers
未改变。2 min/1 GiB仍是 prospective estimate且002未运行，必须由同一 Skeptic在 pre-execution review确认
external monitor；本静态 PASS不继承001 resource measurement。

### 21.5 Documentation and classified findings

`README.md` 对002只同步 implemented/not-run status、exact dispatch/namespace、001 immutable operational
status、五类 conversion/type gate、unchanged source/schema/zero-eigensolve/no-reference和 2 min/1 GiB
nonauthorization；没有声称002 result。`SYMBOLS.md` 的 allowlist、selected scalar、type-gate inputs和
accepted/rejected cell types与 source一致。§20-specific documentation属于 mechanical synchronization。

- **blocker:** none found；
- **important caveat:** runtime row values、atomic publication和2 min/1 GiB仍须由获准后的002 artifact与
  external monitor验证；这正是下一 Skeptic gate与后续 diagnostic的对象，不能从静态审计推断成功；
- **minor caveat:** 没有 pre-§20 001 digest table，故 immutability只能由 §X-matching content、早期 mtime、
  no-diff路径与本节新 snapshot支持，不能表述为已证 exact hash equality；此外 README中较早的九-mesh
  paragraph仍使用“until ... diagnostic is run”的旧时态，虽不改变002 contract，后续可作最小文档时态同步。

### 21.6 Researcher decision and next gate

**Researcher decision: `THEORY-TO-CODE PASS`.** §20/§Y bounded implementation没有 unresolved source/spec
blocker，现交回同一 Skeptic作 pre-execution spec/code/resource review。Researcher未授权且未运行：

```text
run_i4_1a('mass-gate-002','mass-diagnostic')
```

只有同一 Skeptic明确关闭 §Y.4 conditions、接受本节001证据边界并确认 external monitoring后，才可另行
考虑一次 exact 002 command。任何002结果仍须由同一 Skeptic作 postdiagnostic artifact review；001 mutation、
auto-retry、formal representation/header repair、`run-006` 和 reference/effectivity reveal继续未授权。

## 22. 2026-08-29 proof-backed exact-Hermitian representation amendment

Status: **`PROSPECTIVE SPECIFICATION AMENDMENT / SAME SKEPTIC DESIGN REVIEW REQUIRED / NO IMPLEMENTATION, DIAGNOSTIC OR RUN AUTHORIZED`**.

### 22.1 Authority, historical boundary and exact question

第 1--21 节、[[research/projects/eig-apost/implementation/i4/review-4-1a|review §AA]]、
`run-001`--`run-005`、`mesh-repair-001`、`mass-gate-001`、`mass-gate-002` 及其全部 verdict/artifacts
保持 immutable history。本节不重写 `run-005` 的 frozen-M1-failed historical verdict，也不把002的
zero-eigensolve diagnostic提升为 bulk、guided-mode或 reference result。

本节唯一问题是：在第 2--7 节的 continuous problem、polygon-interface conforming $P_1$ method、
119-solve schedule、branch/coverage/refinement/uncertainty规则和 blind claim boundary完全不变时，如何把
数学上 Hermitian positive-definite 的 reduced generalized eigenproblem表示成 MATLAB 可确定消费的
exact-Hermitian finite-precision objects，并在 first mass failure 前留下 current-run evidence？本节结论分层为：

- **`ESTABLISHED`（exact discrete mathematics）：** frozen full consistent mass以及其 periodic congruence
  严格正定；
- **`ESTABLISHED`（representation identity）：** 下述 one-stored-triangle operator 是 Hermitian canonical
  view，不是 averaging，并且其 raw-to-canonical change 由既有 Hermitian defect支配；
- **`CONDITIONAL`（finite-precision execution）：** 每个 actual canonical mass仍须在 current source/current
  phase上通过 positive diagonal、exact-Hermitian和 two-output `chol` gates；证明不能绕过这些 gates；
- **`BLOCKED PENDING SAME SKEPTIC REVIEW`：** Engineer、任何 source/doc修改、preformal diagnostic和
  `run-006` 均未授权。

### 22.2 Exact spaces, operators and periodic prolongation

固定任一 bulk 或 defect polygonal computational cell $\Omega_h$，以及第 15--17 节 mesh-oracle通过的
conforming、nondegenerate、interface-fitted triangulation $\mathcal T_h$。每个 active node都属于至少一个
positive-area triangle；没有 unused node、duplicate/overlap/hole、lost constraint或 disconnected component。
令

$$
V_h=\{v_h\in C^0(\overline{\Omega_h};\mathbb C):
v_h|_T\in\mathbb P_1(T)\ \text{for every }T\in\mathcal T_h\}
$$

为 full nodal space，$\{\varphi_i\}_{i=1}^{n}$ 为其 nodal basis。polygon-interface coefficient $q_h$ 在每个
triangle上取 frozen material value $1$ 或 $17$，因此 $q_h\ge1$ almost everywhere。以

$$
(K_h)_{ij}=\int_{\Omega_h}\nabla\varphi_j\cdot\nabla\overline{\varphi_i},
\qquad
(M_h)_{ij}=\int_{\Omega_h}q_h\varphi_j\overline{\varphi_i}
$$

定义 full consistent stiffness和mass；这里 $M_h$ 不是 lumped mass。$K_h$ 是 Hermitian positive
semidefinite，$M_h$ 是下一小节所证的 Hermitian positive definite。

对任一 frozen bulk phase $\alpha$ 或 defect twist $\vartheta$，记统一的 $x$ phase为 $\phi$。periodic
prolongation $P_\phi\in\mathbb C^{n\times r}$ 由第 3.3 节的 $x/y$ equivalence classes和
$e^{\mathrm i\phi}$、$e^{\mathrm i\beta}$、corner factor $e^{\mathrm i(\phi+\beta)}$ 构成。冻结的 support
oracles要求：

1. $P_\phi$ 的每一 row恰有一个 modulus-one entry；
2. 每一 column至少被一 row support；
3. master IDs恰为 $1,\ldots,r$，且 node equivalence、phase signs和corner rule不变。

因此不同 columns的 row supports不相交，并且

$$
P_\phi^*P_\phi=\operatorname{diag}(s_1,\ldots,s_r),\qquad s_j\in\mathbb N,quad s_j\ge1.
$$

数学上的 reduced operators仍严格是

$$
\widehat K_\phi=P_\phi^*K_hP_\phi,
\qquad
\widehat M_\phi=P_\phi^*M_hP_\phi.
$$

### 22.3 Direct SPD proof

**Discrete mass positivity claim.** 在第 22.2 节假设下，$M_h$ 是 Hermitian positive definite，
$P_\phi$ 满列秩，并且 $\widehat M_\phi=P_\phi^*M_hP_\phi$ 是 Hermitian positive definite且 rank为$r$。

**Proof from scratch.** 对任意 $c=(c_1,\ldots,c_n)^T\in\mathbb C^n$，令
$u_h=\sum_{j=1}^n c_j\varphi_j$。由 matrix定义，

$$
c^*M_hc=\int_{\Omega_h}q_h|u_h|^2.
$$

右端是实数且非负，因此 $M_h=M_h^*$。若 $c\ne0$，则至少一个 nodal coefficient非零；nodal basis的
线性无关性以及该 active node属于 positive-area triangle，说明 $u_h$ 不是 almost-everywhere zero。
由于 $q_h\ge1$，

$$
c^*M_hc
\ge\int_{\Omega_h}|u_h|^2
>0.
$$

故 $M_h$ 严格正定。

再取任意 $z\in\mathbb C^r$。若 $P_\phi z=0$，则

$$
0=\|P_\phi z\|_2^2
=z^*P_\phi^*P_\phi z
=\sum_{j=1}^r s_j|z_j|^2.
$$

因每个 $s_j\ge1$，必有 $z=0$，所以 $P_\phi$ 满列秩。于是对任意 $z\ne0$，$P_\phi z\ne0$，且

$$
z^*\widehat M_\phi z
=(P_\phi z)^*M_h(P_\phi z)>0.
$$

又因为 $M_h=M_h^*$，有 $\widehat M_\phi^*=\widehat M_\phi$。故 $\widehat M_\phi$ 是$r\times r$
Hermitian positive definite，因而 full rank。证毕。

这个证明的 implementation hypotheses由 frozen mesh planar/support oracles和每个 formal phase的 $P$ ledger
检查；它不是由 raw `chol_flag` 推断。反过来，exact-mathematics SPD也不自动证明 rounded sparse storage或
其 canonical view在机器上可 factorize，所以第 22.6 节 actual `chol` gate仍不可删除。

### 22.4 Deterministic one-stored-triangle canonical view

对本节 allowlist 中任一理论 Hermitian、finite、square raw object $A_{\mathrm{raw}}$，固定只信任其
**strict upper triangle**，定义

$$
U=\operatorname{triu}(A_{\mathrm{raw}},1),
\qquad
\mathcal H(A_{\mathrm{raw}})
=U+U^*+\operatorname{diag}(\operatorname{Re}\operatorname{diag}A_{\mathrm{raw}}).
$$

$\mathcal H$ 是 one-stored-triangle/real-diagonal view。它不计算 $(A+A^*)/2$，不根据 tolerance选择
upper/lower entry，也不 drop、threshold、shift、regularize、reorder或修改 sparsity by magnitude。

**Representation identity and bound.** $\mathcal H(A_{\mathrm{raw}})$ 的 strict lower triangle是 strict
upper triangle的 exact conjugate copy，diagonal为 real，所以它是 Hermitian。若 $A_{\mathrm{raw}}$ 本来
exact Hermitian，则 $\mathcal H(A_{\mathrm{raw}})=A_{\mathrm{raw}}$。令

$$
\eta_{\mathrm{raw}}(A)
=\frac{\|A_{\mathrm{raw}}-A_{\mathrm{raw}}^*\|_1}
{\max(1,\|A_{\mathrm{raw}}\|_1)},
\qquad
\delta_{\mathcal H}(A)
=\frac{\|\mathcal H(A_{\mathrm{raw}})-A_{\mathrm{raw}}\|_1}
{\max(1,\|A_{\mathrm{raw}}\|_1)}.
$$

在 strict upper triangle，$\mathcal H(A)-A=0$；在 strict lower triangle，其 entry恰为
$-(A-A^*)$ 的对应 entry；在 diagonal上，其 magnitude是 $A-A^*$ diagonal magnitude的一半。因此每一
column的 change sum不超过同一 column的 anti-Hermitian defect sum，故

$$
\|\mathcal H(A_{\mathrm{raw}})-A_{\mathrm{raw}}\|_1
\le\|A_{\mathrm{raw}}-A_{\mathrm{raw}}^*\|_1,
\qquad
\delta_{\mathcal H}(A)\le\eta_{\mathrm{raw}}(A).
$$

所以继续使用既有 frozen
$\tau_{\mathrm H}=5\times10^{-13}$ 作为 **raw-to-canonical fail-closed gate** 已足够，不需要放宽或
新增更大的 bound。这个 inequality只量化同一个 rounded representation内部的 anti-Hermitian mismatch；
它不是 eigenvalue error bound、geometry error、$\delta_{\mathrm{alg}}^{\mathrm{obs}}$ 或
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 的替代项。

### 22.5 Exact canonicalization allowlist and consumer identity

第 22.4 节只允许应用于以下对象，未列出的 object一律不 canonicalize：

1. 每个 formal phase的 global reduced pair
   $K_{\phi,\mathrm H}=\mathcal H(P_\phi^*K_hP_\phi)$ 和
   $M_{\phi,\mathrm H}=\mathcal H(P_\phi^*M_hP_\phi)$；
2. 同一 phase/cluster的理论 Hermitian dense global mass Gram、center/core/tail restricted-mass Grams；
3. 仅在 $\vartheta=0,\pi$ 构造的理论 Hermitian parity compression；
4. common-core interpolation中各自的理论 Hermitian self-Gram，用于其自身 Cholesky normalization。

第 1 项的 **同一 in-memory canonical pair** 必须同时供下列 consumers使用：

- `chol(M_phi_H)` gate；
- generalized `eigs(K_phi_H,M_phi_H,...)`；
- 每个 reduced eigenvector的 $M_{\phi,\mathrm H}$ normalization；
- $V^*M_{\phi,\mathrm H}V-I$ orthogonality；
- $K_{\phi,\mathrm H}v-\lambda M_{\phi,\mathrm H}v$ algebraic residual及其 denominator norms。

不得只让 canonical mass通过 `chol` 再把 raw mass交给 `eigs`，也不得让 residual使用 raw $K$ 或 raw
$M$。`spectrum` object必须携带 immutable `operator_contract_id`，证明 solver、normalization、
orthogonality和residual引用同一 canonical pair；raw pair只保留 scalar audit diagnostics，不是第二个 verdict
operator。resource preflight的 sparse pattern/fill estimate也必须由同一 upper-triangle rule的 pattern形成，
但 preflight不以其结果绕过 formal per-phase gates。

对 localization，solver输出的 reduced basis已由同一 $M_{\phi,\mathrm H}$ normalization和orthogonality gate
固定；后续不得再用 raw full mass作第二次 re-normalization而改变 metric。full fields
$U=P_\phi V$ 仍用于保存和物理区域积分。full assembled `mass_center`、`mass_core`、`mass_tail` 保持原
$P_1$ restricted forms、不作任何 matrix repair；只对 finite dense compression $U^*M_DU$ 应用
$\mathcal H$ 后取 basis-invariant extremal eigenvalues。parity compression和common-core self-Grams同理，
且必须先通过同一个 $\tau_{\mathrm H}$ raw gate。

相邻 twist的 cross-Gram、不同 mesh的 cross-Gram以及 rectangular overlap matrices通常不是 Hermitian，
所以不在 allowlist中，保持原数学定义并直接用于 singular values。full assembled $K_h$、$M_h$、所有
restricted full matrices、$P_\phi$、rectangular cross-Grams和exported fields均不 canonicalize。本节同时
要求把当前 derived dense objects上的 $(G+G^*)/2$ averaging替换为上述 one-triangle view；不得新增任何
averaging。

这是一项 **finite-precision representation amendment**：exact weak form、element matrices、quadrature、
material、mesh、phase equivalence和 generalized eigenproblem完全不变，且在 exact Hermitian input上
$\mathcal H$ 是 identity。因此本节仅狭窄 supersede第 15.4、18.2、18.5、20.4 节及此前 blanket
“reduced/dense theoretical-Hermitian object不得 post-process” prohibition中与上述 allowlist冲突的部分。
“不得 average/post-symmetrize full assembled mesh matrices”以及所有未列对象的 prohibition继续有效。

### 22.6 Per-object gates and finite-precision failure semantics

每个 formal phase在 `eigs` 前必须按以下不可跳步顺序完成；derived Hermitian object在其首次 `chol`/`eig`
consumer前使用同一规则：

1. 检查 raw object为 square、finite，并计算 raw absolute/normalized Hermitian defect和raw diagonal；
2. 若 $\eta_{\mathrm{raw}}>\tau_{\mathrm H}$，停止，canonical fields留空，不能用 $\mathcal H$ 隐藏
   mesh/reflection/phase failure；
3. 只有 raw gate通过才构造 $\mathcal H(A)$，记录 absolute/normalized representation delta、canonical
   diagonal、nonfinite count、Hermitian defect，并要求 exact storage identity
   `isequal(A_H,A_H')` 且 canonical defect为0；
4. primary $M_{\phi,\mathrm H}$ 的 diagonal必须 finite且 real part严格为正；随后恰执行一次
   two-output `chol(M_phi_H)`，要求 `flag == 0`；primary $K_{\phi,\mathrm H}$ 不另加 positivity gate；
5. 对需要 `chol` 的 global/common-core self-Gram记录同一 factorization flag；restricted/parity compression
   只在 raw/canonical gates通过后送入 `eig`；
6. 第 22.7 节 evidence checkpoint成功后才能 raise或调用 `eigs`。

raw nonfinite或 raw defect failure沿用 terminal state `QUASIPERIODIC_SEAM_UNRESOLVED`；canonical
nonfinite/nonexact-Hermitian、canonical mass nonpositive diagonal或 nonzero Cholesky flag沿用
`SPECTRUM_INVENTORY_TRUNCATED`；artifact无法原子发布仍是 `EXECUTION_UNAVAILABLE`。machine row的
`first_failure_code` 使用更细的固定 subcode，按以下顺序选择第一个：

1. `RAW_OPERATOR_NONFINITE`；
2. `RAW_HERMITIAN_DEFECT`；
3. `CANONICAL_OPERATOR_INVALID`；
4. `CANONICAL_MASS_DIAGONAL_INVALID`；
5. `CANONICAL_FACTORIZATION_FAILED`。

同一 phase先评估 primary stiffness、再评估 primary mass；两张 evidence rows都形成后才提交 first failure。
若 stiffness raw gate失败，不允许为了产生一个看似成功的 mass verdict而进入 solver；mass row只保存此时
可安全取得的 raw evidence。任何 gate failure都 fail closed，不删除 phase、不改变 root count、不调整
tolerance、不启用 raw fallback。

### 22.7 Reached-bulk artifacts, exact schema and atomic order

future one-input formal path进入 `BULK_INVENTORY` 后，顺序冻结为：

1. 原子提交 `stage-start` progress row；
2. 在任何 formal raw/canonical representation gate、mass `chol` 或 `eigs` 前，创建 current-run
   `bulk-bands.csv` 十列 header、`bulk-gaps.csv` 十四列 header、
   `operator-representation.csv` header和 `operator-representation.mat` empty payload；
3. 每个 phase先形成 primary $K/M$ rows，将 MAT payload以 `.partial`/atomic move更新，再将 CSV以
   `.partial`/atomic move更新；CSV是该 phase checkpoint的最后 commit marker；
4. 只有 MAT/CSV row count、sequence和schema完全一致，才可 raise representation/mass failure或调用
   `eigs`；
5. later derived-object rows使用相同 append-in-memory/atomic-rewrite contract；terminal summary在全部
   reached evidence和 first failure ledger close后才发布。

`bulk-bands.csv` 的 exact header仍为
`level,solve_id,alpha,root_index,frequency,eigenvalue,algebraic_residual,cluster_id,cluster_multiplicity,solver_role`；
`bulk-gaps.csv` 的 exact header仍为
`level,gap_index,lower_edge,upper_edge,contains_cue,inside_guard,lower_change,upper_change,delta_lower,delta_upper,safe_lower,safe_upper,gate_pass,reason`。
两者在 first mass failure时必须保持 zero data rows，但文件本身必须存在。

`operator-representation.csv` 固定为 33 columns：

```text
sequence,stage,solve_id,mesh_id,phase_kind,phase,object_id,object_role,rows,columns,raw_nnz,canonical_nnz,raw_nonfinite_count,canonical_nonfinite_count,raw_hermitian_defect_absolute_1,raw_hermitian_defect_normalized_1,canonical_delta_absolute_1,canonical_delta_normalized_1,canonical_hermitian_defect_absolute_1,canonical_hermitian_defect_normalized_1,canonical_exact_hermitian,raw_diagonal_real_min,raw_diagonal_real_max,raw_diagonal_max_abs_imag,canonical_diagonal_real_min,canonical_diagonal_real_max,canonical_diagonal_max_abs_imag,factorization_kind,canonical_factorization_flag,consumer_contract,gate_pass,first_failure_code,first_failure_reason
```

primary `object_id` 恰为 `reduced-stiffness`、`reduced-mass`；derived rows使用
`cluster-mass-gram`、`center-mass-gram`、`core-mass-gram`、`tail-mass-gram`、
`parity-compression` 或 `common-core-self-gram` 并由 `solve_id`/cluster identity消歧。
`factorization_kind` 只允许 `none` 或 `chol`；无 factorization时 flag为空，primary mass和 self-Gram的
two-output Cholesky flag必须原样记录。primary mass的 `consumer_contract` 固定为
`chol|eigs|normalization|orthogonality|residual`，primary stiffness固定为 `eigs|residual`。

`operator-representation.mat` 只有 top-level `payload`，其 fields固定含 `schema_version`、上述 header、
rows、model ID、planned solve count 119、completed representation checkpoints和 immutable first failure；
不保存 raw/canonical matrices，不读取002 MAT，也不成为 solver cache。任一 scientific raise前至少有
header-only bulk ledgers和截至 first failure的 representation rows。若 header、MAT/CSV mirror、atomic move
或 final commit marker失败，terminal claim只能是 `EXECUTION_UNAVAILABLE`，不得称 mass/gap/spectrum
scientifically unresolved。

### 22.8 Theory-to-code map and preformal gate

同一 Engineer若在未来获得明确授权，只允许按下表做 bounded mapping；本节本身不授权这些改动：

| Frozen object | Prospective responsibility | Required evidence |
|---|---|---|
| raw $P^*K_hP$、$P^*M_hP$ and diagnostics | `LOCAL_phase_reduce` | unchanged seam row plus primary raw fields |
| $\mathcal H$ one-triangle rule | one pure `LOCAL_` helper | exact upper-triangle construction; no averaging branch |
| shared canonical solver pair | `LOCAL_low_spectrum` | one `operator_contract_id`; identical objects at chol/eigs/norm/orthogonality/residual |
| canonical resource pattern | resource preflight | 40/48 workspaces and fill for canonical sparsity; no pre-bulk scientific mass verdict |
| derived Gram allowlist | cluster/localization/common-core helpers | representation rows before dense chol/eig; rectangular cross-Grams untouched |
| reached-bulk publication | formal stage-3 writer | header-first bulk ledgers and operator MAT/CSV checkpoints |
| first failure | existing failure/summary path | representation evidence committed before raise; one immutable first cause |

任何 implementation后，必须先由 Researcher作 exact theory-to-code zero-drift audit，再由同一 Skeptic作
spec/code/resource review。随后还须另行通过一个 **zero-eigensolve、create-once、current-source rebuild**
diagnostic gate：它至少 source-build `bulk-s12-g24` at $\alpha=\pi/4$ 和
`defect-N5-s24-g48` at $\vartheta=\pi/4$，调用与 formal solver相同的 canonical helper，验证 raw ledger、
canonical exact-Hermitian、canonical mass `chol_flag=0` 和 consumer-contract identity；不得读取001/002、
run history、Markdown、Git或 reference。该 diagnostic不得调用 `eigs`，不得输出 band/gap data rows、field
或 reference；prospective resource envelope为 2 min / 1 GiB，超过则不运行。其 create-once ID和 exact
command必须由后续同一 Researcher/Skeptic gate登记，本节故意不命名、不授权、不运行它；失败或 collision
不得自动换 ID。

### 22.9 Allowed scope, budgets, retry semantics and exact potential formal command

通过同一 Skeptic design review也只会允许一个后续 Engineer proposal，prospective source/doc scope限于：

- `test/i4/femref-a1/run_i4_1a.m` 中上述 canonical helper、consumer plumbing、resource pattern和
  header/evidence writers；
- `test/i4/femref-a1/README.md` 与 `SYMBOLS.md` 的 exact schema/dispatch/mechanical synchronization。

不得修改 research method稿、review、I1--I3、package/main code、physical/configuration constants或历史
artifacts。允许的表示修订不包括：

- full assembled $K_h/M_h/M_D$ averaging、post-symmetrization或 material/element formula变化；
- $(A+A^*)/2$、lower/upper averaging、tolerance-based entry selection、drop tolerance、diagonal shift、
  regularization、permutation/reorder或 alternative factorization verdict；
- mesh/geometry/constraints/reflection oracle、phase signs/corner factor、40/48 gates、119 solve union、
  branch/coverage/refinement/$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 规则或 claim boundary变化；
- current BIE/QZ/estimator/history/diagnostic read、002 cache reuse、reference/effectivity reveal；
- overwrite `run-001`--`run-005`、001/002、split command重置预算、silent retry或 second attempt。

canonical construction新增的 transient sparse storage在 `nnz(K)+nnz(M)\le2{,}000{,}000` cap下估计不超过
约 $0.1$ GiB；raw scalar diagnostics和33-column ledger相对较小。因此 prospective peak estimate由1.2 GiB
上调为 **1.3 GiB**。不增加任何 eigensolve；现有29.8 min conservative upper加上119次 $O(\operatorname{nnz})$
triangular view和atomic row publication，prospective plan cap冻结为 **30.0 min**。这只是静态上限，时间余量
为零；implementation后的 canonical fill/DOF/IO forecast只要超过30 min或1.5 GiB preflight cap就立即
`RESOURCE_BUDGET_UNAVAILABLE`，不得 launch。正式运行仍共享30 min / 2 GiB default budget；30 min后只有
§12.2的90%/finite-rate/ETA条件成立才允许唯一10 min grace，40 min和2 GiB是 hard limits。

若全部前置 gates未来均通过，唯一 prospective formal command为：

```text
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('run-006')"
```

`run-006` 只能 create once `output/run-006/`，不得读取/覆盖旧 output。operational code/path/schema/
environment failure保留其 artifacts且不消费 scientific attempt，但任何新 run ID仍须同一 Researcher/Skeptic
gate明确授权；representation/scientific gate failure不得自动 retry。complete frozen-method failure的 attempt
语义仍由第 8.3 节控制，不创建 M2。本节记录命令但 **不授权 Engineer、不授权 diagnostic、不授权
`run-006`**。

### 22.10 Branch-4 evidence, claim boundary and Researcher handoff

§AA verified branch-4 evidence是本修订的唯一 empirical premise：`mass-gate-002` 中 full mass为
$233\times233$、无 zero/nonfinite row/column且 diagonal real part严格正；$P$ 为
$233\times208$、每 row恰一 unit-modulus entry且每 column supported；raw reduced mass为
$208\times208$、无 zero/nonfinite row/column，normalized Hermitian defect仅
$2.7105054312137611\times10^{-19}$。raw `chol_flag=1` 的 first diagonal为
$0.0034722222222222255-1.0842021724855044\times10^{-19}\mathrm i$。这排除了 §18.7 branches 1--3、5、6，
并支持“raw exact-Hermitian storage mismatch”分类；它不单独证明 finite canonical mass SPD，也不代表
all phases已通过。第 22.3 节 exact proof与每个 phase的 canonical Cholesky gate缺一不可。

本节没有产生 bulk band、gap、guided-mode eigenvalue/field、branch、reference resolution或
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$，也没有验证 estimator effectivity。canonical delta只能作为 algebraic
representation audit，不能并入或降低 empirical uncertainty。任何 future successful formal artifact仍受
第 1.3、7、8.2 和13.4节以及
[[research/projects/eig-apost/implementation/i4/method-4-1|I4.1 method claim boundary]] 约束。

**Researcher decision: `GO TO SAME SKEPTIC DESIGN REVIEW`.** 本节的 exact-mathematics proof和 bounded
representation/artifact contract完整，没有 identified proof gap；finite-precision success仍是 gated
condition，不是当前结论。cheapest next gate只是同一 Skeptic对 §22 的 independent proof/spec/budget review；
在其无 unresolved blocker verdict之前不得把 scope交 Engineer。

### 22.11 Rigorous-proof reporting record

- **Task mode:** `Proof from scratch`；
- **Source statement:** review §AA.7 proof obligation和本节第 22.2 节 explicit hypotheses；
- **Target/output:** 本文件 append-only §22；未改写第 1--21 节；
- **Claim proved:** consistent polygon-interface $P_1$ full mass SPD，full-support periodic prolongation满列秩，
  以及 periodic congruence mass SPD/full rank；
- **Representation lemma proved:** upper-triangle/real-diagonal canonical view为 Hermitian identity on exact
  Hermitian input，且 $\delta_{\mathcal H}\le\eta_{\mathrm{raw}}$；
- **Dependencies:** conforming nondegenerate mesh、每 active node有 positive-area support、$q_h\ge1$、每个
  $P$ row恰一 unit-modulus entry且每 column supported；
- **Weakest finite step:** rounded $\mathcal H(M_{\mathrm{raw}})$ 的 positive definiteness不由 anti-Hermitian
  defect bound alone推出，故保留 actual two-output `chol` fail-closed gate；
- **Literature/citations:** self-contained discrete linear-algebra proof；没有 external citation、reference download、
  unverifiable quotation或 missing bibliographic identity；
- **Authorized changes outside target:** none；
- **Remaining proof gaps:** none under the stated hypotheses；implementation和numerical gates尚未执行，不属于
  proof completion。

**Proof literature verification completed.**

### 22.12 2026-08-29 bounded revision after review §AB

Status: **`BOUNDED REVISION COMPLETE / SAME SKEPTIC RE-REVIEW REQUIRED / NO ENGINEER, DIAGNOSTIC OR RUN AUTHORIZED`**.

本小节只关闭 [[research/projects/eig-apost/implementation/i4/review-4-1a|review §AB.8]] 的六项 findings。
第 22.1--22.11 节保持历史原文；其中已通过的 exact SPD proof、$\mathcal H$ formula和
$\delta_{\mathcal H}\le\eta_{\mathrm{raw}}$ inequality继续有效。本修订不改变 raw full matrices/oracles、
no-averaging rule、rectangular cross-Gram boundary、119-solve schedule、continuous/FEM method、claim
boundary或任何 historical artifact。

#### 22.12.1 Unique cluster normalization metric and synchronized bases

第 22.5 节的 global cluster normalization在此唯一冻结为 **canonical reduced metric route**。对任一
formal phase $\phi$，`LOCAL_low_spectrum` 已以同一 in-memory
$K_{\phi,\mathrm H},M_{\phi,\mathrm H}$ 得到按频率 cluster化的 reduced eigenvector block
$V_C^{(0)}$。对每个 cluster $C$ 定义

$$
G_{C,\mathrm{raw}}
=(V_C^{(0)})^*M_{\phi,\mathrm H}V_C^{(0)},
\qquad
G_{C,\mathrm H}=\mathcal H(G_{C,\mathrm{raw}}).
$$

$G_{C,\mathrm{raw}}$ 必须先通过 $\eta_{\mathrm{raw}}\le\tau_{\mathrm H}$ 和 finite gates；
$G_{C,\mathrm H}$ 必须通过 exact-Hermitian、finite、strictly-positive diagonal和

```text
[R_C, flag_C] = chol(G_C_H)
```

的 `flag_C == 0` gate。MATLAB upper factor满足 $R_C^*R_C=G_{C,\mathrm H}$。唯一允许的 basis change是

$$
V_C=V_C^{(0)}R_C^{-1},
\qquad
U_C=P_\phi V_C.
$$

implementation先执行 `V_C = V_C_0 / R_C`，随后从更新后的 $V_C$ **重新形成** `U_C = P_phi * V_C`；
不得独立 normalize $U_C$。可以只作 audit地比较 $U_C$ 与 $U_C^{(0)}/R_C$，但后者不是第二个 authority。
同一 change后必须再次检查

$$
\|V_C^*M_{\phi,\mathrm H}V_C-I\|_2\le10^{-7},
\qquad
\|U_C-P_\phi V_C\|_2
\le10^{-12}\max(1,\|U_C\|_2).
$$

任何 gate失败均为 `REFERENCE_SET_COVERAGE_UNRESOLVED`，且在第 22.12.3 节 derived row checkpoint后
fail closed。禁止以 $U_C^*M_hU_C$、raw $P_\phi^*M_hP_\phi$ 或任何其他 rounded metric作第二次
normalization。

`spectrum` cache在当前 solve内暂存 $V^{(0)}$；完成每个 cluster的上述同步后，形成现有 authority所需的
full basis $U=P_\phi V$。持久 cache只保存 normalized full basis、phase/cluster bookkeeping、parent
`operator_contract_id` 和 cluster `normalization_contract_id`；transient reduced $V$ 在 full basis与
evidence成功提交后释放，不与 $U$ 重复持久缓存。因此不会把 defect eigenvector cache从 full-only扩成
full-plus-reduced；新增 persistent memory只来自 scalar contract IDs和第 22.12.4 节有界 ledger，必须由
resource diagnostic实测。

该 global row的 `object_id` 固定为 `cluster-global-mass-gram`，`factorization_kind='chol'`，
`consumer_contract='cluster-chol|cluster-normalization|restricted-gram-basis|continuation-basis'`。center/core/
tail、parity和common-core self-Grams均消费同一个已同步 $U_C$，不得自行重定 metric。rectangular cross-Grams
仍不 canonicalize。

#### 22.12.2 Deterministic contract identities and corrected schema

每个 distinct mesh/phase operator pair只生成一个 deterministic primary ID：

```text
OP2|<model_digest>|<mesh_id>|<phase_kind>|<lowercase-num2hex(phase)>
```

其中 `phase_kind` 只允许 `bulk-alpha` 或 `defect-theta`；ID不含 solver tolerance、`nev`、run ID、history、
Git或 current-chain value。同一 pair被 tight/count role复用时ID保持相同。primary stiffness row和primary
mass row必须携带完全相同的 ID；每个 resulting `spectrum`、its cache entry和每个 eigenobject row继承该
ID。

每个 derived Hermitian row另有 deterministic ID：

```text
DRV2|<parent-OP2-id>|<object_id>|<context-key>
```

`context-key` 由 source-owned solve ID、cluster ID、slice/configuration ID和必要的 first/second side组成；
不得由 numerical value、branch ranking或 current result生成。derived row的 `operator_contract_id` 是该
`DRV2` ID，`parent_operator_contract_id` 是其唯一 parent `OP2` ID；primary K/M rows的 parent field为空。
cluster cache同时保存 parent `OP2` 和 global normalization `DRV2`，所以 restricted/continuation consumers
可 machine-join 到唯一 solver pair和唯一 normalization。

第 22.7 节33-column proposal由以下 schema完整 supersede：

- **schema version:** `i4a-operator-representation-v2-36`；
- **exact width:** 36 columns；
- **exact header:**

```text
sequence,stage,solve_id,mesh_id,phase_kind,phase,operator_contract_id,parent_operator_contract_id,object_id,object_role,evaluation_status,rows,columns,raw_nnz,canonical_nnz,raw_nonfinite_count,canonical_nonfinite_count,raw_hermitian_defect_absolute_1,raw_hermitian_defect_normalized_1,canonical_delta_absolute_1,canonical_delta_normalized_1,canonical_hermitian_defect_absolute_1,canonical_hermitian_defect_normalized_1,canonical_exact_hermitian,raw_diagonal_real_min,raw_diagonal_real_max,raw_diagonal_max_abs_imag,canonical_diagonal_real_min,canonical_diagonal_real_max,canonical_diagonal_max_abs_imag,factorization_kind,canonical_factorization_flag,consumer_contract,gate_pass,first_failure_code,first_failure_reason
```

`operator-representation.mat` 的唯一 top-level `payload` 必须含
`schema_version='i4a-operator-representation-v2-36'`、`column_count=36`、exact header、rows、row count、
primary-contract inventory、derived-parent inventory、completed checkpoint count和 immutable first failure；
CSV/MAT每一个 cell逐项镜像。MAT仍不保存 raw/canonical matrices、不作 solver cache、不读取001/002。

#### 22.12.3 Prior-object failure row and mirror semantics

`evaluation_status` 只允许：

- `EVALUATED_PASS`；
- `EVALUATED_FAIL`；
- `RAW_ONLY_BLOCKED_BY_PRIOR_OBJECT`。

每个 phase仍恰有 primary stiffness和mass两行。若 stiffness在 raw或canonical gate成为 first failure：

1. stiffness row写 `EVALUATED_FAIL`、`gate_pass=0`，并独占 phase的 nonempty
   `first_failure_code/reason`；
2. mass raw object仍可形成时，mass row只填 identity、contract、dimensions、raw `nnz`、raw nonfinite、raw
   Hermitian defects和raw diagonal fields，写
   `evaluation_status='RAW_ONLY_BLOCKED_BY_PRIOR_OBJECT'`；
3. mass row的全部 canonical fields、`canonical_factorization_flag`、`gate_pass` 和
   `first_failure_code/reason` 必须是 **empty cell serialized as an empty CSV field**；MAT mirror的对应 cell也
   必须是 empty，不得写0、`NaN`、stiffness failure副本或 inferred mass verdict；
4. mass row保留 prospective `factorization_kind='chol'` 和完整 `consumer_contract`，它们只声明若 parent
   phase gate通过时的 intended consumer，不代表本 row执行过 Cholesky；
5. MAT `first_failure.owner_object_id` 和 `owner_sequence` 必须指向 stiffness row。raw mass即使同时显示另一个
   abnormality也只是 preserved unevaluated evidence，不能抢占冻结的 stiffness-first ownership。

若 stiffness通过而mass失败，则 stiffness为 `EVALUATED_PASS/gate_pass=1`，mass为
`EVALUATED_FAIL/gate_pass=0` 并独占 first failure。只有两行 CSV/MAT mirror和 first-failure owner一致地
atomic commit后才允许 raise；row omission、blank mismatch或 double ownership是 `EXECUTION_UNAVAILABLE`。
derived row只有 parent primary pair全部通过后才可存在。

#### 22.12.4 Frozen derived-row and growing-rewrite upper bounds

formal union恰有119 primary pairs，即238 primary rows。defect schedule恰为42个40-root solves和5个48-root
solves，所以 defect cluster-slot upper bound为

$$
42\cdot40+5\cdot48=1920.
$$

在“每个 root都是 singleton raw-gap cluster”的最坏 bookkeeping case下，derived row upper count冻结为：

| Derived object | Upper rows |
|---|---:|
| global canonical cluster Grams | $1920$ |
| center/core/tail restricted Grams | $3\cdot1920=5760$ |
| endpoint parity compressions | $6\cdot2\cdot40+1\cdot2\cdot48=576$ |
| unique cached common-core self-Grams | $1920$ |
| **total derived** | **$10176$** |

common-core self-Gram必须按 configuration/phase/cluster只计算、canonicalize和factorize一次；finest self-Gram
在六个 cross-configuration comparisons间复用。禁止在 pairwise branch候选内重复 factorize或重复写 derived
row。operator ledger maximum因此是 $238+10176=10414$ data rows。

为避免把 row count正确却把 growing rewrite漏出预算，maximum atomic MAT/CSV checkpoint count冻结为：

$$
1\text{ header}
+119\text{ primary}
+47\text{ global-normalization}
+47\text{ restricted/parity}
+47\text{ common-core}
=261.
$$

每个 batch必须在其 first consumer/raise前 commit；empty batch可跳过，所以261是上界而非必须制造的空写入。
resource extrapolation必须按10414 rows和261 checkpoints测量，不得以当前 small diagnostic row count代替。

#### 22.12.5 Representation correctness and resource benchmark diagnostic

preformal zero-eigensolve gate现冻结为以下 exact create-once diagnostic：

```text
diagnostic_id = representation-gate-001
dispatch      = run_i4_1a('representation-gate-001','representation-diagnostic')
namespace     = test/i4/femref-a1/diagnostics/representation-gate-001/
```

若 final namespace已存在，立即 `DIAGNOSTIC_COLLISION`，不得读取、覆盖、追加、换名或自动 retry。它从
current source分别 rebuild `bulk-s12-g24` at $\alpha=\pi/4$ 与
`defect-N5-s24-g48` at $\vartheta=\pi/4$，不读 run-005、001/002、任何 history/Markdown/Git/current/
reference data。它对两者调用与 formal path相同的 phase reduction和 $\mathcal H$ helper，生成四个
primary v2 rows，要求 raw gates、canonical exact-Hermitian和canonical mass `chol_flag=0`；它不得调用
`eigs`，不得形成 eigenvalue、field、band/gap data row、branch、reference或 effectivity object。

Diagnostic required artifacts固定为：两行 `mesh-ledger.csv`、两行 `seam-checks.csv`、header-only
`bulk-bands.csv`/`bulk-gaps.csv`、四行 v2 `operator-representation.csv/.mat`、`progress.csv`、
`representation-resource.csv`、`representation-rss.csv`、`representation-rewrite-benchmark.csv`、
`representation-forecast.csv` 和 atomic summary-last `diagnostic-summary.csv/.mat`。全部 CSV numeric cells用
`%.17g`；MAT mirror只有 top-level `payload`。

`representation-resource.csv` 固定为17 columns：

```text
diagnostic_id,sample_id,mesh_id,phase_kind,phase,component,elapsed_seconds,rss_before_bytes,rss_peak_bytes,rss_increment_bytes,array_bytes_before,array_bytes_peak,array_increment_bytes,primary_pair_count,derived_row_upper_count,rewrite_checkpoint_count,notes
```

`component` 至少分别记录 coarse/fine的 `raw-diagnostics`、`canonical-construction`、`mass-factorization`、
`mat-checkpoint` 和 `csv-checkpoint`。`progress.csv` 在 `COARSE_BULK_BENCHMARK`、
`FINEST_DEFECT_BENCHMARK`、`GROWING_REWRITE_BENCHMARK` 前后原子切换 stage；独立 external monitor每秒采样
process RSS并写五列
`representation-rss.csv`：
`sample_index,elapsed_seconds,stage,sample_id,rss_bytes`。缺任一 stage sample或 `/usr/bin/time` whole-command
record即 diagnostic evidence incomplete。

`representation-rewrite-benchmark.csv` 固定11 columns：

```text
checkpoint_index,checkpoint_kind,rows_before,rows_added,rows_after,mat_seconds,csv_seconds,total_seconds,mat_bytes,csv_bytes,cumulative_seconds
```

benchmark使用 future exact v2 writer在 diagnostic temporary namespace按第 22.12.4 节 exact cumulative
schedule执行至10414 rows和最多261 checkpoints；padding rows必须标记为
`BENCHMARK_PADDING_NO_SCIENTIFIC_OBJECT`，不得进入 final operator evidence或任何 claim，temporary benchmark
files在 timing/hash/byte counts记录后删除。另以 finest canonical mass的 deterministic leading
$48\times48$ principal block形成 non-scientific Hermitian probe，测量 derived raw diagnostics、$\mathcal H$
和 `chol`/`eig` 中较慢者；不生成 eigenmode。该 maximum记为 `derived_seconds_per_row`。

`representation-forecast.csv` 固定21 columns：

```text
baseline_seconds,bulk_primary_pair_count,bulk_primary_seconds_per_pair,defect_primary_pair_count,defect_primary_seconds_per_pair,derived_row_upper_count,derived_seconds_per_row,rewrite_checkpoint_count,rewrite_seconds,additive_seconds,forecast_seconds,forecast_minutes_unrounded,forecast_strictly_below_30,baseline_peak_bytes,incremental_peak_bytes,forecast_peak_bytes,forecast_peak_gib,forecast_at_most_1p5_gib,gate_pass,failure_code,failure_reason
```

使用 raw measured doubles、不得提前 round：

$$
T_{\mathrm{add}}
=72t_{\mathrm{bulk}}
+47t_{\mathrm{defect}}
+10176t_{\mathrm{derived}}
+T_{\mathrm{rewrite}},
\qquad
T_{\mathrm{forecast}}=29.8\cdot60+T_{\mathrm{add}}.
$$

$t_{\mathrm{bulk}}$、$t_{\mathrm{defect}}$ 只含新增 representation diagnostics/canonical construction/
canonical factorization/evidence-row preparation，不含 mesh build或 `eigs`，因此该 diagnostic只估计 additive
representation/I/O cost，不声称重测119-eigensolve baseline。$T_{\mathrm{rewrite}}$ 是 exact growing writer
benchmark，不能以单row write线性猜测。hard preformal wall gate是

$$
T_{\mathrm{forecast}}<1800\ \mathrm{s}
$$

的严格不等式；`1799.999...` 可过，`1800` 不可过。输出以 `%.17g` 保留未舍入值。

Peak gate以原1.2 GiB baseline加上 finest stage在 canonical construction/checkpoint期间相对 stage-entry RSS和
array inventory的较大正 increment：

$$
B_{\mathrm{forecast}}
=1.2\cdot2^{30}
+\max\{0,\Delta B_{\mathrm{RSS}},\Delta B_{\mathrm{array}}\}
\le1.5\cdot2^{30}.
$$

coarse和finest phase必须分别报告 internal timings与 external stage RSS；whole diagnostic还必须在
120 s和1 GiB内完成。任一 timing/RSS/schema/atomic evidence缺失、diagnostic超过2 min/1 GiB、
$T_{\mathrm{forecast}}\ge1800$ 或 $B_{\mathrm{forecast}}>1.5$ GiB，均输出
`RESOURCE_BUDGET_UNAVAILABLE`，不得授权 formal run。Diagnostic自身的 exact prospective command为：

```text
cd /Users/whc/Documents/Work/epost/test/i4/femref-a1
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('representation-gate-001','representation-diagnostic')"
```

本节只冻结 ID/schema/budget/retry semantics；**不授权 implementation或执行该命令**。任何 complete或
incomplete `representation-gate-001` 都永久消费该 diagnostic ID；postdiagnostic artifact/resource review前
不得 repair、换 ID或考虑 `run-006`。

#### 22.12.6 Parity Hermitian bridge and endpoint-only scope

令 $R$ 为 full nodal $x$-reflection permutation。frozen reflection oracle要求

$$
R=R^*=R^{-1},
\qquad
R^*M_hR=M_h.
$$

由 $R^*=R$，第二式为 $RM_hR=M_h$；左乘 $R$ 并用 $R^2=I$ 得
$M_hR=RM_h$。因此

$$
(M_hR)^*=R^*M_h^*=RM_h=M_hR,
$$

所以对任意 endpoint invariant subspace basis $U_C$，compression
$U_C^*M_hRU_C$ 是 Hermitian。该对象只允许在 $\vartheta=0$ 和 $\vartheta=\pi$ 构造、过 raw/canonical
gates并取 parity spectrum。所有 $0<\vartheta<\pi$ slices不得构造 parity matrix或 derived row；
existing `branch-inventory.csv` row固定写
`parity_signature='NOT_APPLICABLE_INTERIOR_TWIST'`、`parity_ambiguous=false`，cache中的 parity spectrum为空。
interior N/A不是 ambiguity，也不得触发 `MODE_ID_AMBIGUOUS`。

#### 22.12.7 Typography correction, preserved gates and handoff

第 22.2 节的 intended formula在本 append-only revision中机械更正并重申为

$$
P_\phi^*P_\phi=\operatorname{diag}(s_1,\ldots,s_r),
\qquad s_j\in\mathbb N,
\qquad s_j\ge1.
$$

旧文本中的 missing backslash仅是排版历史，不改变第 22.3 节证明。

本修订继续禁止 Engineer、source/doc change、canonical diagnostic execution、`run-006`、auto-retry、
history/001/002 mutation、full-matrix symmetrization/averaging、tolerance relaxation、physics/mesh/schedule/
branch/uncertainty drift以及 reference/effectivity reveal。29.8 min不再单独构成 launch evidence；只有第
22.12.5 节 diagnostic correctness、strict wall forecast和peak gates经同一 Skeptic postdiagnostic review通过，
才可在另一次 gate考虑 formal execution。

**Researcher decision: `GO TO SAME SKEPTIC §22 RE-REVIEW`.** AB.8 items 1--6已在 design层逐项唯一化；
exact SPD/canonical proofs保持 `ESTABLISHED`，parity Hermitian bridge亦由 frozen oracle直接证明。resource
feasibility仍为 `CONDITIONAL` 且当前 execution status保持 `BLOCKED / NOT AUTHORIZED`。本修订没有 external
citations、reference downloads或 unresolved proof gap；最弱未验证项是 future diagnostic对10414-row/261-
checkpoint growing writer的实测外推。

**Proof literature verification completed.**

#### 22.12.8 Diagnostic atomic RSS handoff and terminal schema clarification

第 22.12.5 节的 `representation-rss.csv` 是 current diagnostic唯一允许的 external-monitor sidecar。MATLAB
必须先独占完成 final-path collision check、claim create-once namespace，再写
`RSS_MONITOR_ATTACH_READY` progress row并作 bounded wait；Code Runner monitor看到该 row后才在已 claim 的
namespace内创建 `.partial` sidecar和 `monitor-attached` token。MATLAB确认 token后开始 benchmark；在 MATLAB
写出 `RESOURCE_BENCHMARK_READY_FOR_RSS` progress row后，monitor停止采样并原子 rename为 final CSV。
Diagnostic MATLAB只允许读取这个 current-run token/sidecar的 schema和stage RSS values；不得读取任何其他
process、history或 output。该 handshake、wait和monitor均计入同一2 min/1 GiB diagnostic budget。RSS file
finalization后，MATLAB才形成 `representation-resource.csv`、`representation-forecast.csv` 和 terminal
summary；若 monitor未附着、超时、schema错误或任一 required stage无 sample，写
`RESOURCE_EVIDENCE_INCOMPLETE` 并 fail closed。

`diagnostic-summary.csv` 固定为19 columns：

```text
diagnostic_id,status,input_kind,completed_eigensolves,reference_exported,operator_schema_version,primary_rows,derived_row_upper_count,rewrite_checkpoint_upper_count,correctness_pass,resource_evidence_complete,forecast_seconds,forecast_peak_bytes,gate_pass,elapsed_seconds,peak_rss_bytes,failure_code,failure_reason,claim_boundary
```

`diagnostic-summary.mat` 镜像同一 fields并只有 top-level `payload`。全部 required evidence和 external RSS
sidecar close后先原子提交 summary MAT，最后提交 summary CSV；final CSV是唯一 terminal commit marker。
`status` 只允许 `REPRESENTATION_GATE_COMPLETE_PASS`、`REPRESENTATION_GATE_COMPLETE_RESOURCE_FAIL` 或
`REPRESENTATION_GATE_INCOMPLETE`。即使 complete pass，本节仍只产生后续同一 Skeptic postdiagnostic review的
输入，不自行授权 `run-006`。

#### 22.12.9 Final bounded handoff

Diagnostic `input_kind` 固定为 `SOURCE_REBUILD_CURRENT_REPRESENTATION_SPEC_V2`，claim boundary固定为
`ZERO_EIGENSOLVE_REPRESENTATION_AND_RESOURCE_EVIDENCE_ONLY`。本 §22.12 的最终 Researcher disposition为
**`GO TO SAME SKEPTIC RE-REVIEW / EXECUTION REMAINS BLOCKED`**。没有 Engineer、diagnostic或formal command
获得授权；没有 numerical result、citation或新的 proof gap。

**Proof literature verification completed.**

### 22.13 2026-08-29 second bounded revision after review §AC

Status: **`BOUNDED REVISION COMPLETE / SAME SKEPTIC RE-REVIEW REQUIRED / NO ENGINEER, DIAGNOSTIC OR RUN AUTHORIZED`**.

本小节只关闭 [[research/projects/eig-apost/implementation/i4/review-4-1a|review §AC.6]]。第 22.12 节已经
通过的 canonical cluster metric、OP2/DRV2 identities、36-column operator mirror、stiffness-first semantics、
parity proof、row/checkpoint counts、SPD/canonical proofs和 raw/no-averaging boundary全部保留。本小节显式
supersede第 22.12.5、22.12.6、22.12.8中与 external resource authority、benchmark proxy、parity row或
scientific-ledger inheritance冲突的语句。

#### 22.13.1 MATLAB-only diagnostic and post-exit resource authority

`representation-gate-001` 的 MATLAB entry完全独立运行。它不得等待、读取或搜索 external monitor token、
RSS sidecar、`/usr/bin/time` output、process table、review、Markdown、Git或任何 history/output。它不以外部
resource artifact决定 control flow或 terminal status，也不要求在 MATLAB退出前取得 whole-command wall/RSS。
第 22.12.8 节的 token/sidecar handshake、`representation-rss.csv` required artifact和 MATLAB-side
`resource_evidence_complete/peak_rss_bytes` verdict在此全部取消。

MATLAB只写 internal correctness、component timing、array-byte inventory、serialization/rewrite benchmark和
terminal evidence。若 internal correctness及第 22.13.3 节 internal forecast gates通过，terminal status固定为
`REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`；若 correctness complete但 internal
forecast失败，写 `REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`；任何 schema/computation/atomic
incomplete写 `REPRESENTATION_GATE_INCOMPLETE`。第一个 status不是 resource PASS，也不授权任何下一步。

被审 command identity冻结为：working directory
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`，diagnostic ID
`representation-gate-001`，expected MATLAB dispatch
`run_i4_1a('representation-gate-001','representation-diagnostic')`，external command恰为：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('representation-gate-001','representation-diagnostic')"
```

同一 Code Runner必须保留 exact command string、working directory、exit code，以及 process退出后
`/usr/bin/time -lp` 才完成的 `real` 和 maximum resident set size。可选 observational monitor只能在外部
观察同一 command/process并把 record交给 review；它不得写 diagnostic science namespace、不得被 MATLAB
读取，也不得控制 MATLAB执行。command identity若与 terminal diagnostic ID/expected dispatch不一致，或
外部 final record缺失，则 post-exit review为 `RESOURCE_EVIDENCE_INCOMPLETE`；这不允许重跑或让 MATLAB
预先猜测记录。

**唯一 resource verdict authority是命令退出后的同一 Skeptic。** Skeptic在 existing
`review-4-1a.md` 中联合核对：MATLAB terminal/internal artifacts、exact command identity、external `real`、
maximum RSS和可选 observational trace。只有 internal unrounded
$T_{\mathrm{forecast}}<1800$ s、internal array forecast不超过1.5 GiB、whole diagnostic external real不超过
120 s且maximum RSS不超过1 GiB全部成立，才能给 diagnostic resource PASS。MATLAB不修改或同步这个
post-exit verdict。

#### 22.13.2 Size-aware zero-eigenobject benchmark paths

correctness/resource samples改为 **largest bulk** `bulk-s24-g48` at $\alpha=\pi/4$ 和 finest defect
`defect-N5-s24-g48` at $\vartheta=\pi/4$。不再用 `bulk-s12-g24` 代表72个 bulk pairs。两张 mesh都从
current source rebuild，继续 zero eigensolves/no history/no reference。

每张 sample分别计时且不重叠以下 components：

1. `primary-raw-diagnostics`：已形成 raw $K/M$ 后的 finite/diagonal/Hermitian measurements；
2. `primary-canonical-construction`：$\mathcal H(K)$、$\mathcal H(M)$ 及 canonical checks；
3. `primary-mass-factorization`：canonical mass的唯一 two-output `chol`；
4. `global-full-height-probe`：第 22.12.1 节完整 reduced-Gram/synchronized-basis path；
5. `restricted-derived-dense-probe`：center/core/tail、endpoint parity和common-core self-Gram paths，分别留时；
6. `row-preparation`：一次性形成 schema-safe operator rows但不写 file；
7. `growing-rewrite`：第 22.12.4 节 exact 10414-row/261-checkpoint MAT/CSV rewrites。

`row-preparation`只计一次；`growing-rewrite`包含全部 serializer、MAT/CSV conversion、temporary write和atomic
rename成本。per-primary或per-derived operation timings不得再包含 writer cost，避免重复计算。
第 22.12.5 节要求 temporary benchmark hash但没有 schema位置，该 hash要求在此删除；rewrite ledger只保存
frozen timings、row/byte counts和checkpoint identity，temporary files随后删除。

对每个 $m=1,\ldots,48$，在 finest defect reduced height $r$ 上 source-deterministically形成 dense、full-height、
full-column-rank probe $V_m^{(0)}\in\mathbb C^{r\times m}$。第 $\ell$ column由 master-node coordinates的固定
解析函数形成，随后作 deterministic economy QR；若 rank或finite gate失败，diagnostic incomplete。probe
generation/QR单独计时且不进入 additive formal overhead。它不是 eigenvector、不读 current field，也不输出
mode claim。

对每个 width实际执行而非只测 dense $m\times m$ tail：

$$
G_{m,\mathrm{raw}}=(V_m^{(0)})^*M_{\phi,\mathrm H}V_m^{(0)},
\qquad
G_{m,\mathrm H}=\mathcal H(G_{m,\mathrm{raw}}),
$$

```text
[R_m, flag_m] = chol(G_m_H)
V_m = V_m_0 / R_m
U_m = P_phi * V_m
```

并检查

$$
\|V_m^*M_{\phi,\mathrm H}V_m-I\|_2\le10^{-7},
\qquad
\|U_m-P_\phi V_m\|_2
\le10^{-12}\max(1,\|U_m\|_2).
$$

restricted path用同一 $U_m$ 实际形成三个 $U_m^*M_DU_m$、canonicalize并调用 `eig`；endpoint parity实际形成
$U_m^*M_hRU_m$、canonicalize/`eig`；common-core path实际 sample full-height $U_m$、形成 self-Gram、
canonicalize/`chol`。每一类保存 width-indexed elapsed和array inventory。任何 probe gate失败只表明
representation implementation/benchmark unavailable，不是 eigenmode或 method negative。

#### 22.13.3 Cluster-partition resource upper bound

令 measured component costs分别为：primary largest-bulk $t_{B}$、primary finest-defect $t_D$；width-$m$
global full path $g_m$；三个 restricted paths的实际总和 $d_m$；parity $p_m$；common-core self path $c_m$。
这些 cost都排除 row writer。对 $n\in\{40,48\}$ 和任一 cost family
$a\in\{g,d,p,c\}$，冻结 dynamic-programming partition bound

$$
C_a(0)=0,
\qquad
C_a(n)=\max_{1\le m\le\min(48,n)}\{a_m+C_a(n-m)\}.
$$

它枚举一个 `nev=n` solve的全部 positive integer cluster-dimension partitions，因而不会把所有 clusters误当
width 48，也不会低估任一 measured partition。`representation-partition-bounds.csv` 必须保存每个
family/$n$ 的 maximizing ordered partition、cluster count、component sum、solve count和 total contribution。

formal additive overhead使用 actual frozen schedule partition：

$$
\begin{aligned}
T_{\mathrm{add}}={}&72t_B+47t_D\\
&+42C_g(40)+5C_g(48)\\
&+42C_d(40)+5C_d(48)\\
&+12C_p(40)+2C_p(48)\\
&+42C_c(40)+5C_c(48)\\
&+T_{\mathrm{row\ preparation}}+T_{\mathrm{growing\ rewrite}}.
\end{aligned}
$$

这里12个40-root和2个48-root parity solves恰对应六个 tight configuration endpoints及一个 loose-count
configuration endpoints；common-core self objects仍 per configuration/phase/cluster缓存一次。largest-bulk
$t_B$ 保守用于全部72 bulk pairs，finest-defect $t_D$ 保守用于全部47 defect pairs。primary counts、derived
partition operations、row preparation和writer各出现一次，互不重叠。

继续以原29.8 min作为不可降低的 baseline floor：

$$
T_{\mathrm{forecast}}=29.8\cdot60+T_{\mathrm{add}}<1800\ \mathrm{s}.
$$

所有 measured doubles和DP sums以 full precision计算、CSV用 `%.17g`；不得为了取得正余量删减 path、rows、
checkpoint、cluster dimension、schedule或把 cost四舍五入为0。若 strict inequality没有正余量，internal status
必须是 `REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`，failure code
`RESOURCE_BUDGET_UNAVAILABLE`。

internal peak forecast仍为1.2 GiB baseline加上 largest-bulk/finest-defect full-height width-48 path、10414-row
ledger buffer和atomic rewrite buffer中测得的最大正 array-byte increment，要求不超过1.5 GiB。MATLAB只报告
array inventory，不声称 RSS；whole diagnostic的2 min/1 GiB gate留给第 22.13.1 节 post-exit Skeptic以
external `real`/maximum RSS裁定。

#### 22.13.4 Exact diagnostic artifacts and terminal semantics

`representation-gate-001` final namespace只允许以下 required artifacts：

1. `mesh-ledger.csv` 与 `seam-checks.csv`：largest bulk和finest defect各一行；
2. header-only `bulk-bands.csv`、`bulk-gaps.csv`；
3. four-row `operator-representation.csv/.mat`，继续使用
   `i4a-operator-representation-v2-36`；
4. `progress.csv`；
5. `representation-resource.csv`、`representation-probe-costs.csv`、
   `representation-partition-bounds.csv`、`representation-rewrite-benchmark.csv`、
   `representation-forecast.csv`；
6. summary-last `diagnostic-summary.csv/.mat`。

不创建 `representation-rss.csv`、monitor token、hash ledger、band/gap data rows、spectrum、field或 reference。
`representation-resource.csv` supersede旧17-column RSS proposal，固定为15 columns：

```text
diagnostic_id,sample_id,mesh_id,phase_kind,phase,component,width,elapsed_seconds,array_bytes_before,array_bytes_peak,array_increment_bytes,solve_count,nev,partition_role,notes
```

`representation-probe-costs.csv` 固定为7 columns：

```text
sample_id,path,width,elapsed_seconds,gate_pass,failure_code,failure_reason
```

`representation-partition-bounds.csv` 固定为7 columns：

```text
path,nev,maximizing_partition,cluster_count,bound_seconds,solve_count,total_seconds
```

`representation-rewrite-benchmark.csv` 保持11 columns且不含 hash：

```text
checkpoint_index,checkpoint_kind,rows_before,rows_added,rows_after,mat_seconds,csv_seconds,total_seconds,mat_bytes,csv_bytes,cumulative_seconds
```

`representation-forecast.csv` 固定为27 columns：

```text
baseline_seconds,largest_bulk_primary_count,largest_bulk_primary_seconds,finest_defect_primary_count,finest_defect_primary_seconds,global_40_total_seconds,global_48_total_seconds,restricted_40_total_seconds,restricted_48_total_seconds,parity_40_total_seconds,parity_48_total_seconds,common_core_40_total_seconds,common_core_48_total_seconds,row_preparation_seconds,rewrite_seconds,additive_seconds,forecast_seconds,forecast_minutes_unrounded,forecast_strictly_below_30,baseline_peak_bytes,incremental_array_peak_bytes,forecast_peak_bytes,forecast_peak_gib,forecast_at_most_1p5_gib,internal_gate_pass,failure_code,failure_reason
```

`diagnostic-summary.csv` supersede第 22.12.8 节19-column summary，固定为19 columns：

```text
diagnostic_id,status,input_kind,expected_dispatch,completed_eigensolves,reference_exported,operator_schema_version,primary_rows,derived_row_upper_count,rewrite_checkpoint_upper_count,correctness_pass,internal_benchmark_complete,internal_forecast_seconds,internal_array_peak_bytes,elapsed_seconds,failure_code,failure_reason,claim_boundary,external_resource_review_status
```

`external_resource_review_status` 在 MATLAB artifact中只能是
`PENDING_SAME_SKEPTIC_POST_EXIT_REVIEW`；不得预填 PASS/FAIL。`input_kind` 仍为
`SOURCE_REBUILD_CURRENT_REPRESENTATION_SPEC_V2`，claim boundary仍为
`ZERO_EIGENSOLVE_REPRESENTATION_AND_RESOURCE_EVIDENCE_ONLY`。先原子提交 summary MAT，最后提交 summary CSV；
CSV是 MATLAB-owned terminal commit marker，但不声称 post-exit evidence complete。任何外部记录不得回写或
修改这些 science artifacts。

#### 22.13.5 Parity aggregates and minimal OP2 join

existing `branch-inventory.csv` schema和 row meaning保持不变：`parity_signature`、`parity_ambiguous` 是由
$\vartheta=0,\pi$ 两个 endpoint spectra形成的 **branch-level aggregate**，并继续在该 branch的每个 slice row
重复。interior cluster cache只把 local parity spectrum记为空/N/A，不构造 parity operator；不得把
`NOT_APPLICABLE_INTERIOR_TWIST` 写进 existing branch-level aggregate columns。`MODE_ID_AMBIGUOUS` 只由两个
endpoint aggregate触发，interior N/A既不清除也不制造 ambiguity。本段 supersede第 22.12.6 节关于 interior
branch row value的要求，不版本化 branch schema。

`bulk-bands.csv` 和 `spectrum-inventory.csv` headers也保持不变，不新增 OP2 column。每个 formal
`solve_id` 必须在 `operator-representation-v2-36` primary rows中恰映射到一个 OP2；同一 solve的K/M两行
必须给同一 OP2，任一 scientific ledger row通过其 existing unique `solve_id` join到该 OP2。tight/count可
有不同 solve IDs映射到同一 OP2。in-memory spectrum/cache直接保存 OP2，derived DRV2 row再以
`parent_operator_contract_id` 指回它。不得再声称 bulk/spectrum CSV row含或直接继承一个不存在的
`operator_contract_id` field；唯一 artifact authority是 `solve_id -> primary OP2` join。

#### 22.13.6 Authorization and re-review handoff

本修订没有改变任何 formula、threshold、mesh、solver count、branch/refinement/uncertainty rule或 claim。
没有创建/执行 diagnostic，没有生成 eigenobject，没有修改 code/review/docs/artifacts。Engineer、
`representation-gate-001`、`run-006`、auto-retry、history mutation及 reference/effectivity reveal仍未授权。

**Researcher decision: `GO TO SAME SKEPTIC §22.13 RE-REVIEW / EXECUTION REMAINS BLOCKED`.** §AC.6 items 1--5
已逐项关闭：MATLAB/external authority解耦；largest-bulk及full-height partition benchmark闭合；parity branch
schema保持；OP2采用 minimal solve-ID join；未落 schema的 hash requirement已删除。resource feasibility仍是
`CONDITIONAL`；若 future internal或post-exit evidence不能诚实给出正时间余量及全部 peak gates，唯一结果是
`RESOURCE_BUDGET_UNAVAILABLE`，不得为通过而修改冻结规格。

### 22.14 2026-08-29 minimal bounded revision after review §AD

Status: **`MINIMAL REVISION COMPLETE / SAME SKEPTIC RE-REVIEW REQUIRED / NO IMPLEMENTATION OR EXECUTION AUTHORIZED`**.

本小节只关闭 [[research/projects/eig-apost/implementation/i4/review-4-1a|review §AD.5]]；第 22.13 节其余已
通过内容原样保留。

#### 22.14.1 Endpoint parity probe without a new formal pair

primary representation samples仍冻结为 largest bulk `bulk-s24-g48` at $\alpha=\pi/4$ 和 finest defect
`defect-N5-s24-g48` at $\vartheta=\pi/4$。此外只在**同一已 source-rebuild 的 finest defect mesh** 上再形成
$\vartheta=0$ phase reduction，专供 zero-eigenobject endpoint-parity probe。选择 $\vartheta=0$ 而不是
$\pi$，且不得 runtime切换 endpoint。

该 endpoint reduction必须调用与 formal path相同的 periodic reduction、$\mathcal H$、raw/canonical gates、
canonical mass `chol` 和 parity helper。它有独立 deterministic primary ID

```text
OP2|<model_digest>|defect-N5-s24-g48|defect-theta|0000000000000000
```

并在 diagnostic `operator-representation-v2-36` 中恰写 stiffness/mass两行。每个 width-$m$ parity probe的
DRV2 evidence ID为

```text
DRV2|<endpoint-OP2-id>|parity-probe|width-<m>
```

其 `parent_operator_contract_id` 指向上述 endpoint OP2；实际执行
$U_m^*M_hRU_m$、raw/canonical checks和 `eig`，但不调用 `eigs`，不产生 eigenmode、branch、band/gap data、
reference或 effectivity claim。interior $\vartheta=\pi/4$ probe不得构造 parity object。

每个 endpoint width probe先以 $M_{0,\mathrm H}$ 实际完成第 22.12.1 节 global
$G_{m,\mathrm{raw}}/G_{m,\mathrm H}$/`chol`/`V_m/R_m`/`U_m=P_0V_m`及两项 recheck，随后才把同一 normalized
$U_m$ 交 formal parity helper。该 endpoint-global step作为 diagnostic correctness/setup单独记录；$p_m$ timer
只从 normalized $U_m$ 已就绪后开始，计 parity compression、canonicalization和 `eig`，避免与 formal
$C_g(n)$ 重复计费。

$\vartheta=0$ phase reduction、两张 primary rows和48个 parity timings都计入 diagnostic自身 internal elapsed/
array inventory及 post-exit 2 min/1 GiB review；其 primary setup不另加进 formal
$T_{\mathrm{add}}$，因为 formal union仍严格是119 pairs，且第 22.13.3 节的47个 finest-defect primary count已
包含 frozen endpoint solves。只有 measured parity path costs $p_m$ 按12个40-root和2个48-root formal endpoint
solves进入 DP forecast。Diagnostic endpoint OP2/rows不得写入或增加 formal 238-primary-row ledger。

Artifact counts随之重冻结为：

- `mesh-ledger.csv`：2 data rows，largest bulk与finest defect各一张 mesh；
- `seam-checks.csv`：3 data rows，largest bulk $\pi/4$、finest defect $\pi/4$、同一 finest defect $0$；
- `operator-representation.csv/.mat`：6 primary data rows，三个 phase reductions各K/M两行；
- `representation-resource.csv`：至少另有一行
  `component='endpoint-parity-phase-and-global-setup'`，记录 $\vartheta=0$ reduction/global-probe setup的
  internal elapsed与array increment；该行只进入 diagnostic own-budget evidence，不进入 formal additive sum；
- `representation-probe-costs.csv`：六个 width-indexed paths
  `global`、`restricted-center`、`restricted-core`、`restricted-tail`、`endpoint-parity`、`common-core`，
  每个 $m=1,\ldots,48$，共288 derived timing rows；另有 largest-bulk/finest-defect primary raw、canonical、
  factorization六行，共294 rows。

formal padding row upper 10414及 growing checkpoint upper 261完全不变，不把6 diagnostic primary rows或294
timing rows混入它们。

#### 22.14.2 Exact all-row preparation versus growing writer

`row-preparation` benchmark的 timer boundary固定为：从一个尚未分配的 row container开始，在内存中一次性
创建并填满 **恰10414 rows乘36 cells** 的 schema-valid deterministic padding values，执行同一 type/width
gate，并验证 `row_count==10414`、`column_count==36`；到此停止 timer。该 interval不调用 serializer、MAT/CSV
writer、temporary file、atomic rename或 hash。

`representation-resource.csv` schema由第 22.13.4 节15 columns机械扩为17 columns，在 `width` 后加入
`row_count,column_count`：

```text
diagnostic_id,sample_id,mesh_id,phase_kind,phase,component,width,row_count,column_count,elapsed_seconds,array_bytes_before,array_bytes_peak,array_increment_bytes,solve_count,nev,partition_role,notes
```

`row-preparation` row必须机器记录 `row_count=10414,column_count=36`；其他 component的两格为空。

`growing-rewrite` 从已完成、已验证的 prebuilt 10414-row container开始，按第 22.12.4 节 cumulative schedule
独立计时最多261次 schema conversion、MAT/CSV temporary write和atomic rename。它不得重新生成 padding row，
也不得把 `row-preparation` elapsed再次加入任何 checkpoint。Formal forecast只各加一次
$T_{\mathrm{row\ preparation}}$ 和 $T_{\mathrm{growing\ rewrite}}$。

#### 22.14.3 Conservative timing protocol and near-threshold rule

所有 primary component及 width-indexed $g_m,d_m,p_m,c_m$ low-duration timings使用同一个协议：先作2次固定
warm-up并丢弃；再作 **5次** timed repetitions。任一 repetition nonfinite或 negative使 diagnostic
incomplete。令 measured values为 $t_1,\ldots,t_5$，timer quantization floor固定为
$q_t=10^{-4}$ s，正式进入 DP/forecast的 cost是

$$
t_{\mathrm{cons}}
=\max\left\{q_t,
q_t\left\lceil\frac{\max_{1\le j\le5}t_j}{q_t}\right\rceil\right\}.
$$

所以 microsecond/zero-looking interval不会按0外推。10414-row `row-preparation`同样使用2 warm-ups和5 timed
repetitions，并取上述 conservative statistic；261-checkpoint growing rewrite因本身是完整 cumulative
serialization trial，只作一次 untimed empty-writer warm-up，再计一次 exact full schedule，不拆分、不乘一个
乐观 per-write mean。

`representation-probe-costs.csv` supersede第 22.13.4 节7-column proposal，固定为16 columns：

```text
sample_id,path,width,operator_contract_id,parent_operator_contract_id,warmup_count,repeat_count,repeat_min_seconds,repeat_mean_seconds,repeat_max_seconds,coefficient_of_variation,quantization_floor_seconds,conservative_seconds,gate_pass,failure_code,failure_reason
```

primary rows也使用该 schema；endpoint parity rows携带 DRV2/parent OP2。DP只消费
`conservative_seconds`，不得消费 mean或minimum。

Internal strict gate仍要求 unrounded $T_{\mathrm{forecast}}<1800$ s；post-exit同一 Skeptic还必须审查 timing
stability。若任一 repeated component的 coefficient of variation超过0.25，或 positive margin
$1800-T_{\mathrm{forecast}}$ 不大于

$$
\max\left\{1\ \mathrm{s},
\sum_{\mathrm{forecast\ multipliers}}
\bigl(t_{\max}-t_{\min}\bigr)\right\},
$$

resource evidence视为 unstable/too close to threshold，唯一 verdict是 `RESOURCE_BUDGET_UNAVAILABLE`。同一
Skeptic可以因 timer resolution、external wall/RSS variability或 missing repeat evidence作相同降级；不得因
point estimate略低于1800 s而乐观授权。Internal或post-exit gate失败都不能通过减少 repetitions、提高
$q_t$ 精度声明、删 row/path或调整冻结科学规格来修成 PASS。

#### 22.14.4 Authorization boundary

Diagnostic required artifact names、MATLAB/external authority、summary pending semantics、largest-bulk/finest-
defect primary proxies、DP formulas、29.8 min floor、strict $<1800$ s、internal 1.5 GiB、diagnostic post-exit
2 min/1 GiB gates保持第 22.13 节不变；只有本节明确的 mesh/seam/primary/probe row counts和两个 timing schemas
supersede旧值。

**Researcher decision: `GO TO SAME SKEPTIC §22.14 RE-REVIEW / EXECUTION REMAINS BLOCKED`.** 未授权 Engineer、
`representation-gate-001`、`run-006`、docs同步、auto-retry或任何 execution；没有修改 code/review/artifacts，
没有运行数值程序。

### 22.15 2026-08-29 post-implementation theory-to-code audit of §§22--22.14

Status: **`THEORY-TO-CODE REVISE / REPRESENTATION DIAGNOSTIC AND RUN-006 REMAIN UNAUTHORIZED`**.

本节是对 current source `test/i4/femref-a1/run_i4_1a.m`、`README.md` 和 `SYMBOLS.md` 的只读静态映射审计。
它不修改 source/docs/review/artifacts，不执行 MATLAB、Octave、Python或 diagnostic，也不把任何 implementation
状态提升为 numerical result。审计 authority是本稿 §§22--22.14 与
[[research/projects/eig-apost/implementation/i4/review-4-1a|review §AE]]；当前 verdict只决定 source能否交同一
Skeptic作 pre-execution review。

#### 22.15.1 Mappings that are established

以下映射经静态原文核对为 **`ESTABLISHED`**：

1. `LOCAL_canonical_hermitian` 恰实现
   $\mathcal H(A)=\operatorname{triu}(A,1)+\operatorname{triu}(A,1)^*
   +\operatorname{diag}(\operatorname{Re}\operatorname{diag}A)$；没有 averaging、shift、drop、regularization、
   permutation或 full-matrix post-symmetrization。`LOCAL_evaluate_canonical_object` 在 construction前检查 square、
   finite及 frozen $\tau_{\mathrm H}=5\times10^{-13}$ raw defect，随后检查 canonical finite、exact storage
   Hermitian、zero defect、positive real diagonal和 required two-output `chol` flag。
2. `LOCAL_prepare_primary_pair` stiffness-first形成同一 OP2的K/M rows；stiffness失败时mass row使用
   `RAW_ONLY_BLOCKED_BY_PRIOR_OBJECT`，canonical、factorization、gate和failure cells保持空。成功时返回的同一
   in-memory canonical K/M pair被 `LOCAL_low_spectrum` 的 `chol` gate、`eigs`、mass normalization、
   orthogonality和两次 residual calculation共同使用；没有 raw K/M fallback。
3. defect cluster global metric是 $G_C=V_C^*M_{\phi,\mathrm H}V_C$，经同一 canonical/`chol` path后执行
   `V_C/R_C`，再由更新后的 reduced basis形成 `U_C=P_\phi V_C`并作 mass/synchronization recheck。full
   restricted masses保持原 assembled forms；center/core/tail及 endpoint parity square compressions只对 dense
   compression canonicalize，interior parity为空且不制造 ambiguity；common-core只 canonicalize各自 self-Gram，
   same-mesh和cross-mesh rectangular Grams仍直接送入 `svd`。
4. source-owned physical constants、points/rings/polygon/constraint/material rules、consistent $P_1$ element forms、
   phase signs、corner factor、40/48 complete-return gates、72+47=119 solve union、B3 odd-B4 alias、bulk/raw-gap
   coverage、branch continuation、four-axis refinement、$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ empirical-only status、
   blindness和claim boundary均未被§22 plumbing改写。Existing `bulk-bands.csv`、`bulk-gaps.csv`、
   `spectrum-inventory.csv`、branch/coverage及resolution headers也保持原 schema；新增 operator ledger明确使用
   version `i4a-operator-representation-v2-36`，没有静默给旧 scientific ledgers增加列。
5. `representation-gate-001` dispatch是 exact create-once two-argument path；static call graph rebuilds largest bulk
   与 finest defect meshes，形成 $\pi/4,\pi/4,0$ 三个 phase reductions，不调用 `LOCAL_low_spectrum` 或 `eigs`，
   不读取 history/output/Markdown/Git/external resource token，也不导出 spectrum、field或 reference。当前
   namespace与 `run-006` 均不存在。17/16/7/11/27/19-column writer headers、2 mesh/3 seam/6 primary/294 probe
   intended counts、DP schedule counts、29.8 min floor、strict internal wall/array gates和pending-external-review
   terminal vocabulary均已落 source。

#### 22.15.2 Blockers requiring bounded source repair

1. **`BLOCKER` — derived evidence is not committed before its first consumer.** In
   `LOCAL_normalize_defect_clusters`, global rows remain only in `pending_rows` while `V_C/R_C` and $U_C=P_\phi V_C$
   are already consumed, and the batch is written only after all clusters. In `LOCAL_gap_clusters`, restricted and parity
   rows remain pending while `eig` is called, and common-core rows remain pending while normalized samples are formed;
   restricted/parity/common rows are then committed together as one checkpoint. This violates §22.12.4's
   first-consumer checkpoint gate and does not realize the frozen 47 global + 47 restricted/parity + 47 common-core batch
   partition. **Smallest correction:** use bounded prepare/commit/consume passes. Per defect solve, first evaluate and stage all
   global rows, atomically checkpoint that batch, then normalize/synchronize; separately stage and checkpoint all
   restricted/parity rows before their dense `eig` consumers; separately stage and checkpoint common-core self-Gram rows
   before publishing normalized samples to cross-Gram consumers. Any gate/recheck failure must preserve one immutable first
   cause and reached rows without increasing the 10414-row/261-checkpoint upper bounds.
2. **`BLOCKER` — the 261-checkpoint rewrite benchmark is not the formal v2 writer.**
   `LOCAL_benchmark_growing_writer` builds only a reduced five-field MAT payload, starts the MAT timer after payload
   construction, never calls `LOCAL_assert_operator_rows`, never constructs primary/derived inventories, first-failure or
   model/checkpoint metadata, and gives every padding row an empty parent so the derived-parent path is not exercised.
   Formal `LOCAL_write_operator_representation` performs all of those operations, including a growing derived inventory.
   Consequently the current `rewrite_seconds` cannot support the strict resource forecast. **Smallest correction:** extract
   one pure schema/payload-preparation path and one publication path used unchanged by formal and benchmark writers. The
   benchmark's deterministic `BENCHMARK_PADDING_NO_SCIENTIFIC_OBJECT` rows must reproduce 238 primary-parent-empty and up
   to 10176 derived-parent-present row shapes, the exact 261 cumulative schedule, and the same inventories/metadata/type gate.
   Each checkpoint timer begins before the shared preparation/conversion and ends after both atomic MAT and CSV moves. Any
   implementation optimization of inventory construction must be shared by both paths and preserve stable identities.
3. **`BLOCKER` — endpoint parity diagnostic does not call the same formal parity path.**
   `LOCAL_probe_parity_path` independently repeats reflection/compression/canonical/`eig` logic instead of sharing the formal
   implementation in `LOCAL_gap_clusters`. Equality by inspection is not the §22.14.1 same-helper gate and permits future
   drift. **Smallest correction:** factor pure parity preparation and consumption helpers used by both callers, while keeping
   formal evidence checkpointed before dense consumption. The diagnostic remains endpoint-only at $\vartheta=0$ and must not
   enter the formal 119-pair ledger.

#### 22.15.3 Important and minor corrections

1. **`IMPORTANT` — row-preparation timing boundary is too narrow.** `LOCAL_measure_row_preparation` stops each timer
   immediately after row allocation/fill; the required width/type gate runs once outside all five timed repetitions. It also
   lacks the explicit nonfinite/negative repetition hard-incomplete check used by the other repeated timings. Move exact
   10414-by-36 dimension and `LOCAL_assert_operator_rows` checks inside every warm-up/timed action, reject any nonfinite or
   negative repetition as diagnostic incomplete, and apply the same explicit finite/nonnegative check to the single rewrite
   timing fields before forecast. Row construction remains excluded from the writer timer.
2. **`IMPORTANT` — frozen identities are not exact.** Primary `object_id` literals are currently
   `stiffness-reduced`/`mass-reduced`, whereas §22.7 froze `reduced-stiffness`/`reduced-mass`; restricted literals add an
   unregistered `restricted-` prefix. Rename only these evidence literals to the latest non-superseded frozen names. In the
   diagnostic, the width-indexed global Gram row currently stores its parent OP2 in both contract columns; it must receive a
   deterministic DRV2 global-probe ID and retain the OP2 only as `parent_operator_contract_id`.
3. **`IMPORTANT` — terminal correctness count is incomplete.** The present `correctness_pass` checks only 2 mesh, 3 seam,
   6 primary and 294 probe rows. Add hard checks for 8 partition rows, 261 rewrite rows, one 27-column forecast row, exact
   10414-by-36 preparation, zero data rows in both bulk ledgers and absence of any reference/eigensolve object before a
   `...PENDING_EXTERNAL_RESOURCE_REVIEW` status can be written.
4. **`MINOR CAVEAT` — B3 is an explicit non-solve alias exception to the minimal OP2 join wording.** Existing B3 rows carry
   `role='alias-reuse-no-solve'` and their synthetic `B3-reuse-B4-*` IDs do not themselves own primary OP2 rows; the cached
   source B4 spectra do. This preserves the older frozen alias contract and must not be repaired by adding solves or changing
   scientific CSV schemas. The same Skeptic should confirm that §22.13.5's “formal solve ID” excludes these clearly labeled
   alias-only rows, or require a later design-level machine-readable alias join; Engineer must not improvise one here.

#### 22.15.4 Static checks, schema boundary and verdict

Static name inventory found every referenced `LOCAL_` helper defined exactly once and no obvious current signature mismatch;
`git diff --check` passed. This is not a MATLAB parser/runtime result. README/SYMBOLS changes are mechanical mapping/status
text and correctly keep `representation-gate-001` unrun; no representation diagnostic directory or `run-006` output exists.
Because the current writer benchmark omits formal preparation cost and derived evidence crosses its frozen checkpoint gate,
resource feasibility and pre-execution evidence are **`BLOCKED`**, although the canonical mathematics and continuous/scientific
contract mapping remain **`ESTABLISHED`**.

**Researcher verdict: `THEORY-TO-CODE REVISE`.** Return only the bounded obligations in §§22.15.2--22.15.3 to the same
Engineer, then repeat this Researcher static audit and hand the resulting source to the same Skeptic. This verdict does not
authorize `representation-gate-001`, MATLAB/Octave/Python execution, `run-006`, artifact mutation, schema improvisation,
formal retry or effectivity reveal.

### 22.16 2026-08-29 bounded theory-to-code re-audit after review §AF.7 repair

Status: **`THEORY-TO-CODE PASS / SAME SKEPTIC PRE-EXECUTION RE-REVIEW REQUIRED / NO EXECUTION AUTHORIZED`**.

本节只读复核 current `test/i4/femref-a1/run_i4_1a.m`、`README.md` 和 `SYMBOLS.md` 对第 22--22.15 节及
[[research/projects/eig-apost/implementation/i4/review-4-1a|review §AF.7]] 的有界修复。没有修改 source、review、
docs 或 artifacts，没有创建文件或目录，也没有运行 MATLAB、Octave、Python、diagnostic 或 formal command。
本 verdict 只说明静态 theory-to-code mapping 已足以交回同一 Skeptic；它不是 spec-to-code、resource 或 numerical
verdict。

#### 22.16.1 Three pre-consumer checkpoints

下列映射为 **`ESTABLISHED`**：

1. `LOCAL_normalize_defect_clusters` 先为该 defect solve 的全部 reached clusters形成 raw global mass Gram、canonical
   matrix、`chol` factor、DRV2 row和 pending batch；evaluation failure先 checkpoint reached rows再 raise。完整
   global batch在 current source lines 4395--4396 经 `LOCAL_checkpoint_operator_rows` 原子发布后，lines
   4398--4415 才消费 factor执行 `initial_reduced / normalizer`、重建 $U_C=P_\phi V_C$并作 mass 与 synchronization
   recheck。这里 `chol` 是 frozen prepare/evidence step；其 first scientific factor consumer `/` 位于 checkpoint
   之后。
2. `LOCAL_gap_clusters` lines 5043--5105 只形成 center/core/tail canonical compressions及 endpoint-only canonical
   parity object/rows；lines 5107--5108 发布完整 restricted/parity batch，随后 lines 5110--5127 才调用三个
   restricted `eig` consumers 和 shared parity consume helper。Interior phase仍令 parity为空。
3. 同一函数 lines 5130--5158 形成 common-core samples、weights、raw/canonical self-Gram、`chol` factor与 rows；
   lines 5159--5160 发布完整 common-core batch后，lines 5162--5190 才执行 `common_samples / common_factor`、
   orthogonality recheck并把 normalized samples交给后续 rectangular cross-Gram。三个阶段各 solve至多增加一个
   checkpoint；post-checkpoint consumer failure不回写已提交 representation row，而沿 existing terminal failure
   path fail closed。

#### 22.16.2 Shared writer, exact shapes and timing gates

以下 AF.7 repair为 **`ESTABLISHED`**：

- formal 与 benchmark 都调用 `LOCAL_write_operator_representation`。其 outer timer在
  `LOCAL_prepare_operator_payload` 前启动；pure preparation运行同一 36-column assert、stable primary OP2 inventory、
  DRV2-parent inventory、first-failure/model/planned/checkpoint metadata，再依次完成 atomic MAT与CSV publication；
  `total_seconds`只在两次 final move之后停止。
- `LOCAL_prepare_padding_rows` 每次都从 `LOCAL_build_padding_rows` 创建恰 $10414\times36$ cells，并在返回前执行
  exact dimension、`LOCAL_assert_operator_rows` 及 `LOCAL_validate_padding_contract`。因此两次 warm-up和五次 timed
  repetition各自都覆盖相同 gate；timing另有 finite/nonnegative、coefficient-of-variation和quantized conservative
  floor gate。
- padding恰含238个 parent-empty OP2 primary shapes，按 `reduced-stiffness`/`reduced-mass` 交替；其后10176个
  nonempty-parent DRV2 shapes。`LOCAL_benchmark_growing_writer` 的 additions固定为 header、119 primary pairs、47
  global、47 restricted/parity、47 common-core，共261 checkpoints且最终10414 rows；每个 prefix走上述 shared
  writer。`LOCAL_validate_rewrite_rows` 在 forecast前硬检查 checkpoint/rows-before/rows-added/rows-after identity、
  MAT/CSV/total timing和byte fields finite/nonnegative，以及 cumulative seconds单调并等于 total time的累积和。
- row preparation与growing rewrite仍不重叠：前者计完整 in-memory rows及 gates，后者从已验证的 prebuilt container
  开始，并只将 exact 261-call shared publication trial计入 forecast一次。

#### 22.16.3 Shared parity, identities and terminal gate

`LOCAL_prepare_parity_object` 是 formal与diagnostic共同的唯一 reflection compression、canonical evaluation及DRV2
row constructor；`LOCAL_consume_parity_object` 是共同的 `eig`/finite consumer。Formal调用只取前四个 prepare
outputs，diagnostic第五个 output只增加 array-byte evidence；两处函数签名与调用个数一致。Diagnostic仍只在
$\vartheta=0$ 的 source-owned endpoint pair调用该路径，interior $\vartheta=\pi/4$ pair不形成 parity object。

Primary object IDs已冻结为 `reduced-stiffness`、`reduced-mass`；restricted IDs为 `center-mass-gram`、
`core-mass-gram`、`tail-mass-gram`；formal global ID为 `cluster-global-mass-gram`。Width-indexed global probe使用
`DRV2|<parent-OP2>|global-probe|width-<m>`，OP2只存于 parent field；endpoint parity同样使用
`DRV2|<parent-OP2>|parity-probe|width-<m>`。所有 primary rows parent为空，所有 derived padding rows具有 nonempty
OP2 parent。

`LOCAL_representation_completion_gate` 在 pending terminal status前执行17/16/7/11/27-column scalar schema gates、
$10414\times36$ all-row gate及 operator v2 MAT mirror gate，并要求 exact 2 mesh、3 seam、6 primary、294 probe、
8 partition、261 rewrite和一个27-column forecast row；operator mirror必须有3个 primary OP2、0个 derived rows、
4个 completed checkpoints及空 first failure。它同时要求 header-only bulk rows/gaps、0 scientific eigensolves、
no reference export、required current-namespace artifacts存在、forbidden reference/field/spectrum artifacts不存在，且
没有 `.partial`。Summary仍以 MAT后CSV的 atomic summary-last顺序发布；只有 exact correctness通过才可能写
`REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`，resource failure则使用独立 fail-closed status。

#### 22.16.4 Scientific zero-drift and static integrity

以下保持 **`ESTABLISHED`**：

- one-input formal path仍以 source-owned constants、geometry/material/constraints、consistent $P_1$ forms、periodic
  signs/corner factor及同一 canonical K/M pair进入 `chol`、`eigs`、normalization、orthogonality和residual；raw full
  matrices/oracles不作 averaging或 post-symmetrization，frozen $\tau_{\mathrm H}=5\times10^{-13}$ 未放宽。
- 40/48 complete-return gates、72 bulk + 47 defect $=119$ solve union、B3 odd-B4
  `alias-reuse-no-solve`、bulk-gap/edge-buffer coverage、branch/cluster continuation、every-slice localization/tail、
  four-axis refinement和 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ empirical-only formula保持不变。B3仍是明确的
  non-solve alias exception，不伪造 OP2也不增加 solve。
- representation dispatch仍是 exact create-once `representation-gate-001`；其静态 call graph只 rebuild两张 mesh与
  三个 phase reductions，唯一 `eigs` call仍只位于 formal `LOCAL_low_spectrum`。代码没有读取 history、Markdown、
  Git、external resource record或 prior output，也不从 diagnostic导出 spectrum、field或 reference。
- 静态 `LOCAL_` reference/definition set相等；anchored function scan未见 duplicate definition，shared helper的
  output arity与可见调用相容，未发现 obvious MATLAB API、signature或 scope mismatch。此项不是 MATLAB parser或
  runtime验证。`README.md`/`SYMBOLS.md` 的本轮差异只同步 function/schema/status mapping，并仍明确 diagnostic未
  运行。`diagnostics/representation-gate-001/` 与 `output/run-006/` 均不存在；历史 run/diagnostic不在本轮 diff。

#### 22.16.5 Caveats and handoff

- **`MINOR CAVEAT`**：本结论来自只读静态审计；MATLAB parser/runtime、shared atomic writer的实际时间、
  10414-row inventory成本、external whole-command wall/RSS及 numerical gates仍完全未验证。
- **`MINOR CAVEAT`**：B3 alias-only rows不拥有自己的 primary OP2；它们继续以 synthetic solve ID显式指向 reused
  odd-B4 spectrum。这是既有冻结例外，不应由 Engineer改 schema或增加 solve；同一 Skeptic仍可在 pre-execution
  review确认 solve-ID join文字只约束 actual solves。

未发现 unresolved blocker或 important caveat。**Researcher verdict: `THEORY-TO-CODE PASS`.** 下一最小 gate是
同一 Skeptic按 review §AF.8 对 current source做 pre-execution spec/code/resource re-review。此 PASS不授权
`representation-gate-001`、任何 MATLAB/Octave/Python execution、`run-006`、artifact mutation、formal retry、
reference reveal或 effectivity comparison。

## 23. 2026-08-29 user-authorized $2$ GiB representation diagnostic continuation

Status: **`MINIMAL PROSPECTIVE AMENDMENT COMPLETE / SAME SKEPTIC REVIEW REQUIRED / NO IMPLEMENTATION OR EXECUTION AUTHORIZED`**.

### 23.1 Authority, exact question and immutable history

本节只处理用户在 [[research/projects/eig-apost/implementation/i4/review-4-1a|review §AJ]] 之后明确授权的
representation diagnostic 续行：本次 diagnostic 的 external actual RSS 上限改为恰
$2147483648$ bytes；只要实测 RSS 尚未达到该值，不得使用任何更低 memory stop gate。该授权 prospective
supersede §AJ.6--§AJ.8 中“不得换 ID/继续 diagnostic”的停止结论，但不改写、删除或降格 §AJ 对
`representation-gate-001` 的历史审计。

以下事实为 **`ESTABLISHED`**：`diagnostics/representation-gate-001/` 已存在且该 create-once ID 已永久消费；
其 7 个 reached files、external `real 80.74` s、maximum RSS $1355071488$ bytes、primary-only reached
boundary及 `INCOMPLETE / EXTERNAL_RESOURCE_BUDGET_UNAVAILABLE` verdict全部保持 immutable。freeze时
`diagnostics/representation-gate-002/` 不存在，current source也尚未 allowlist该 ID。001 的 reached primary
PASS不能外推到未执行的 294 probes、8 partitions、10414-row preparation、261 growing rewrites或 internal
forecast；因此新授权只允许在不改变 frozen method/evidence workload的前提下取得这些缺失证据，不构成对001的
retry、repair或有利重解释。

本次 design问题严格限定为：在 unchanged zero-scientific-eigensolve representation workload下，如何以唯一、
可执行且不含较低 hidden memory stop的规则取得 complete或fail-closed diagnostic artifact。成功标准是同一
Skeptic先接受本节，随后同一 Engineer仅实现 dispatch/resource-policy差异，再经 Researcher theory-to-code与
Skeptic spec-to-code gates；即使这些 gates全部通过，也只可执行一次下述002 command，且必须回到同一
Skeptic作 postdiagnostic review。`run-006` 在该 review完成前保持禁止。

### 23.2 Exact create-once identity and no-reuse boundary

新 diagnostic identity冻结为：

```text
diagnostic_id = representation-gate-002
dispatch      = run_i4_1a('representation-gate-002','representation-diagnostic')
namespace     = test/i4/femref-a1/diagnostics/representation-gate-002/
```

只有这个 exact pair可以加入 two-argument allowlist；不得接受任意 diagnostic ID、alias或 runtime path input。
002必须从 current MATLAB source重新构造两张 frozen meshes、三个 phase reductions及全部 benchmark inputs；
MATLAB不得读取、加载、复制、链接、hash、比较或复用001的 CSV/MAT、namespace、temporary data或 external
record，也不得读取任何其他 history/output、Markdown、review或 Git information。001 namespace不得被写入、
删除、重命名或补齐。

若002 final namespace在 launch前已存在，无论内容是否完整，必须立即 `DIAGNOSTIC_COLLISION`，且不得读取、
覆盖、追加、删除、换 ID或自动 retry。一次002 invocation无论 complete、incomplete、external stop、MATLAB
error或 environment failure都永久消费002；保留所有 reached final/partial evidence并交 postdiagnostic review。
本节不预授权003或任何其他 replacement ID。

### 23.3 Scientific and evidence workload invariants

以下对象与规则全部 **unchanged**，Engineer不得以降低 memory或 wall cost为由删减、替换或近似：

1. continuous model、geometry/material/quasiperiodic phases、consistent $P_1$ weak forms、periodic prolongation、
   raw/canonical Hermitian rule、mass `chol` gate及所有 tolerances；
2. largest bulk `bulk-s24-g48` at $\alpha=\pi/4$、finest defect `defect-N5-s24-g48` at
   $\vartheta=\pi/4$，以及同一 finest defect mesh的 endpoint $\vartheta=0$；
3. zero scientific `eigs`、no spectrum/field/band-gap data/reference/effectivity export、no BIE/QZ/estimator或
   prior-output input；
4. 2 mesh rows、3 seam rows、6 primary K/M rows、294 probe rows、8 partition rows、exact
   $10414\times36$ padding preparation、261-checkpoint shared formal-v2 growing writer及 one 27-column forecast
   row；
5. two warm-ups/five timed repetitions、$10^{-4}$ s timing floor、coefficient-of-variation与 propagated-spread
   gates、dynamic-programming partitions、$29.8$ min baseline、strict
   $T_{\mathrm{forecast}}<1800$ s和全部 timing formulas；
6. 36/17/16/7/11/27/19-column schemas、header-only 10/14-column bulk ledgers、MAT mirrors、atomic publication、
   summary-last、first-failure、claim boundary与 information-isolation rules。

因此002与001的科学/benchmark workload相同；唯一 prospective差异是 create-once identity以及本节明确冻结的
current-diagnostic memory authority。不得优化掉 full-height objects、all-width probes、row container、writer
checkpoints或重复测量，也不得通过拆分 command、stage或 subprocess重置同一120 s diagnostic budget。

### 23.4 One executable actual-RSS rule

对 `representation-gate-002`，**唯一 current-diagnostic memory stop rule** 是 external observer对同一 MATLAB
process tree取得的 aggregate observed resident-set size

$$
B_{\mathrm{RSS}}^{\mathrm{obs}}\ge2147483648\ \mathrm{bytes}.
$$

第一次观测到该不等式成立时必须立即终止同一 command，无 grace、无继续等待、无自动 retry。反之，只要
$B_{\mathrm{RSS}}^{\mathrm{obs}}<2147483648$ bytes，Code Runner、MATLAB dispatch、internal forecast、array-byte
inventory或任何旧 design/review文字都不得因 memory主动终止、跳过、缩减或提前判失败。尤其不得沿用001的
$1073741824$-byte external stop，也不得把1.5 GiB internal forecast predicate冒充 actual RSS stop。OS、MATLAB
或 filesystem在低于该阈值时自行失败仍按原始 environment/operational failure如实保存；这不是获准设置一个较低
memory stop，也不产生 retry entitlement。

External monitor必须从 command启动后开始观察同一 MATLAB process tree，采样间隔不得大于30 s，并在每个
sample同时记录 process-alive与aggregate RSS；达到阈值的 sample取得后立即发出 stop。`/usr/bin/time -lp`
仍独立记录 whole-command terminal `real`、maximum resident set size及peak memory footprint。Post-exit
external peak authority取所有 preserved aggregate monitor samples与`/usr/bin/time` maximum resident set size中
的最大值；若 latter只在退出后显示已达到2 GiB，则 diagnostic仍判 external resource fail，不能因monitor未命中
瞬时峰值而声称 PASS。

Wall rule保持 unchanged：whole command在120 s达到时立即停止，无 grace。Wall与memory首先触发者控制
external stop；全部 monitoring、MATLAB stages和 subprocess共享同一2 min budget。

### 23.5 Internal 1.5 GiB forecast is non-stopping evidence for 002

第 22.13.3 节的 array inventory与

$$
B_{\mathrm{forecast}}
=1.2\cdot2^{30}+B_{\mathrm{increment}}
$$

计算保持不变。为保持27-column schema与旧 evidence可审计，002仍须如实计算并写出
`baseline_peak_bytes`、`incremental_array_peak_bytes`、`forecast_peak_bytes`、`forecast_peak_gib`和
`forecast_at_most_1p5_gib`；最后一格仍恰表示
$B_{\mathrm{forecast}}\le1.5\cdot2^{30}$，不得伪造为2 GiB comparison或改名。

但是，对002本次 diagnostic，`forecast_at_most_1p5_gib=false` **只是一条 future-formal preflight observation**：
它不得导致 early return、删减后续 benchmark、`REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`、
memory failure code或任何低于2 GiB的 current-diagnostic stop。为消除实现歧义，002 row的
`internal_gate_pass`固定只表示 unchanged non-memory internal gates

```text
internal_gate_pass = forecast_strictly_below_30 && timing_stability_pass
```

其中 `timing_stability_pass`仍包含全部 repetition finite/nonnegative、CV及 propagated-spread/margin requirements。
只有这些 unchanged wall/timing gates失败时，才可在完整 evidence publication后使用既有
`REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`；1.5 GiB observation本身不得进入该 conjunction或
failure reason。若 correctness、schemas、counts及上述 non-memory internal gates通过，MATLAB terminal status
必须是 `REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`，无论1.5 GiB observation为true或
false。

本 dispatch-local supersession不改变尚未获准的 formal `run-006` path或其 current
`spec.preflight_peak_cap_gib=1.5`；它只保证本次 diagnostic不会在 actual RSS低于用户授权2 GiB时被较低 memory
predicate阻断。002的完整 array forecast、actual external peak及1.5 GiB observation必须交同一 Skeptic，由其
在 postdiagnostic review中判断是否仍存在阻止 future formal run的resource blocker；Engineer不得自行把 pending
status解释为 formal memory PASS，也不得执行 `run-006`。

### 23.6 Artifact, terminal and postdiagnostic contract

002 required/forbidden artifact集合、schemas、exact counts、atomic ordering及 completion gate与§§22.13--22.16
相同，只把每个 current-run `diagnostic_id`、`expected_dispatch`和 namespace机械替换为002。所有 artifact必须只
位于002 namespace；external monitor/`time` record不得写入 science namespace或被 MATLAB读取。001 artifact既
不是002的 prerequisite，也不是002 completion gate的输入。

Terminal与 retry语义冻结如下：

- external wall达到120 s或observed RSS达到2147483648 bytes：立即停止，preserve reached evidence，002 consumed；
- schema/computation/atomic/environment failure：`REPRESENTATION_GATE_INCOMPLETE`，002 consumed；
- complete correctness但 unchanged non-memory internal time/stability gate失败：
  `REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`，002 consumed；
- complete correctness与 non-memory internal gates通过：
  `REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`，002 consumed；该 status不是 resource PASS。

无论 MATLAB shell exit为何，只有 process退出后的同一 Skeptic可以在 existing `review-4-1a.md` 追加
postdiagnostic verdict。其最小 audit必须核对 exact command/cwd/exit、30 s-or-finer process/RSS trace、external
peak与wall、全部 required/forbidden artifacts、exact counts/schemas/MAT mirrors、0 scientific eigensolves、
timing/DP/rewrite identities、unrounded forecast、1.5 GiB observation及 claim boundary。完整 postreview之前
不得创建或执行`run-006`、同步 reference/effectivity result或提升 I4.1 status。

### 23.7 Exact prospective command and gate sequence

只有同一 Skeptic在本节 design review中无 unresolved blocker、同一 Engineer完成 bounded implementation、
同一 Researcher给出 theory-to-code PASS且同一 Skeptic再给 spec-to-code/resource pre-execution PASS后，Code
Runner才可在
`/Users/whc/Documents/Work/epost/test/i4/femref-a1` 执行恰一次：

```text
/usr/bin/time -lp /Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1a('representation-gate-002','representation-diagnostic')"
```

该 command不得包装成多个 scientific stages、不得从001恢复进度、不得在失败后重复。Prior 001 external peak低于
2 GiB且wall低于120 s只表明新 envelope没有在相同 reached point前被已知证据否定；后续 probes/writer从未执行，
所以 complete resource feasibility仍为 **`CONDITIONAL`**，不能用001数字保证002将完成。

### 23.8 Researcher disposition and review handoff

本节没有修改 source、README、SYMBOLS、review、STATUS或任何 artifact，没有创建002 namespace，没有运行
MATLAB、Octave、Python或 shell numerical computation，也没有进入 formal/reference/effectivity stage。没有新
literature、citation、数学模型、公式、证书或结论。

**Researcher verdict: `GO TO SAME SKEPTIC DESIGN REVIEW / IMPLEMENTATION AND EXECUTION REMAIN BLOCKED`.**
构造性结论为：用户授权已足以关闭 §AJ 的“无新 ID authority” blocker，并以002建立一个 exact prospective
path；scientific workload与 evidence contract保持 **`ESTABLISHED`**，complete runtime/resource feasibility保持
**`CONDITIONAL`**。Skeptic需要重点审查：(1) 002 create-once/no-reuse边界；(2) 2 GiB actual-RSS rule是否确为
唯一 current-diagnostic memory stop；(3) 1.5 GiB字段作为非停止 evidence与 unchanged future formal preflight
之间是否无歧义；(4) 120 s/30 s monitoring及 terminal/retry semantics；(5) `run-006`是否继续完全冻结。只有该
review通过才可把本节限定的 dispatch/resource-policy change交同一 Engineer。

## 24. 2026-08-29 post-implementation theory-to-code audit for `representation-gate-002`

Status: **`THEORY-TO-CODE PASS / SAME SKEPTIC PRE-EXECUTION REVIEW REQUIRED / NO EXECUTION AUTHORIZED`**.

### 24.1 Audit frame and authority

本节只读核对 current `test/i4/femref-a1/run_i4_1a.m`、`README.md`、`SYMBOLS.md`、preserved
`diagnostics/representation-gate-001/`、002/run-006 path absence against §23及
[[research/projects/eig-apost/implementation/i4/review-4-1a|review §AK]]。没有修改 source/docs/review/artifacts，
没有创建 namespace，也没有运行 MATLAB、Octave、Python、parser、diagnostic或 formal command。本结论只回答
bounded implementation是否忠实落地，不能替代 same-Skeptic spec-to-code/resource review或 runtime evidence。

审计最强反证目标是：002是否仍能在 actual RSS低于2 GiB时被1 GiB或1.5 GiB memory predicate提前停止、标为
internal resource failure或写入含 `array-peak` 的002 failure reason。若任一情况存在，本节必须 `REVISE`。下述
逐项检查未发现该路径；runtime/resource feasibility仍待一次经授权的 create-once execution。

### 24.2 Exact dispatch, validated identity and namespace isolation

以下映射为 **`ESTABLISHED`**：

1. Entry lines 39--67先把两个 inputs限制为character vector/string scalar，再把它们转为 exact strings；
   lines 58--64分别只接受
   `representation-gate-001`/`representation-diagnostic`和
   `representation-gate-002`/`representation-diagnostic`。其他 ID、mode、alias或path进入
   `I4A:InvalidDiagnosticMode`。两个 accepted branches都把已验证的 `diagnostic_id` 作为唯一 argument传给
   `LOCAL_run_representation_diagnostic`；没有 generic representation dispatch。
2. `LOCAL_run_representation_diagnostic(diagnostic_id)` 在line 985只有一个 local definition，current source只有
   lines 60/64两个 one-argument call sites。它只以该 validated ID形成
   `fullfile(entry_dir,'diagnostics',diagnostic_id)`；lines 988--992在任何 evidence access前对 current selected
   namespace作 create-once collision check。002不会对001 path作 collision check。
3. Current representation runner lexical body没有 `load`、read-table/matrix、`fopen`、`copyfile`、artifact hash、
   shell/system或 history-output lookup。001 literal在 whole source仅用于其 exact entry branch与summary的001
   expected-dispatch fallback；002 path没有读取、stat、hash、copy、compare或复用001 artifact。当前 `exist`/`dir`
   evidence checks全部由 selected `diagnostic_dir`限定，temporary rewrite files只位于 current system-temporary
   benchmark namespace。
4. 001 namespace仍恰含 §AJ审计的7个 reached files：header-only bulk ledgers、2-row mesh ledger、3-row seam
   ledger、6-row primary operator CSV及其 MAT mirror、3-row progress ledger。没有代码或文档声称补齐、重跑或
   覆盖001。Freeze时 `diagnostics/representation-gate-002/` 与 `output/run-006/` 均不存在。

该 isolation结论依赖 current entry是 representation local runner的唯一 caller；MATLAB local function scope使
其不是独立 public entry。若 future refactor新增 caller，必须重复 exact-ID audit，不能从本节自动继承。

### 24.3 Summary identity and unchanged schemas

`LOCAL_initial_representation_summary(spec,diagnostic_id)` 在lines 1450--1461显式区分两个 accepted IDs：002的
`expected_dispatch`恰为
`run_i4_1a('representation-gate-002','representation-diagnostic')`，非002 validated branch保持001 exact
dispatch。同一 selected ID进入 `summary.diagnostic_id`、current namespace、resource rows、terminal stub及
summary-last MAT/CSV；不存在硬编码001的002 summary path。

`LOCAL_write_representation_ledgers`仍对 resource/probe/partition/rewrite/forecast分别执行
17/16/7/11/27-column scalar gate；forecast header仍恰有27列，保留
`forecast_at_most_1p5_gib`与`internal_gate_pass`而没有扩列、改名或 schema-version drift。
`LOCAL_write_representation_summary`仍形成19-field row，包含 exact ID、expected dispatch、zero-eigensolve/
no-reference status、internal forecast及 pending external review field；MAT先于CSV原子提交。

README lines 81--118分别把001记为 executed/consumed resource-incomplete history、把002记为 prospective/not-run，
并明确002只写自己的 namespace、source rebuild/no-001 reuse、2 GiB unique external memory stop、1.5 GiB
observation和pending same-Skeptic review。SYMBOLS lines 108、189--190同步 exact IDs、27-column observation及
dispatch-local logical meanings；二者都没有把002、`run-006`或 pending status冒充 execution/resource PASS。

### 24.4 No lower-memory failure on the 002 path

Current forecast block lines 1280--1311仍如实计算

```text
peak_pass = forecast_peak_bytes <= 1.5 * 1024 ^ 3
```

并把该 logical写入27-column row的 `forecast_at_most_1p5_gib`位置。紧接着的 exact dispatch branch为：

```text
if strcmp(diagnostic_id, 'representation-gate-002')
  internal_pass = wall_pass && timing_pass;
else
  internal_pass = wall_pass && peak_pass && timing_pass;
end
```

所以002 `internal_pass`不消费 `peak_pass`。002 failure-reason branch只允许
`Strict wall, CV, timing, or propagated-spread gate failed.`；含 `array-peak` 的旧文字只在else branch。后续
terminal block lines 1326--1340只由 `correctness_pass`和该 dispatch-local `internal_pass`选择 pending、internal
resource fail或incomplete；completion gate只核对 schemas/counts/inventories/isolation，不另读1.5 GiB observation。
Static search未发现 representation runner内任何1 GiB literal、actual-RSS query、lower-memory early return或
另一处 `peak_pass` consumer。因此只要 non-memory computation本身没有 operational failure，002不会因任何低于
2 GiB的 intentional memory gate停止或降级。

Actual process-tree RSS及 $2147483648$-byte stop仍按§23/§AK属于 external Code Runner authority，而不应由
MATLAB读回。Source不含2 GiB monitor是正确的 separation，不是缺失实现；同一 Skeptic必须在 future
pre-execution review确认 exact command与不粗于30 s的 external monitor可用。

历史/未来边界亦保持：001走else branch，继续使用 `wall_pass && peak_pass && timing_pass`，其已消费 artifact不受
影响；formal `LOCAL_spec` lines 2131--2140仍保留 `preflight_peak_cap_gib=1.5`、hard 2.0 GiB、29.8 min
estimate、1.2 GiB baseline与1.3 GiB canonical floor，formal preflight line 4201继续以1.5 GiB fail closed。本轮
没有把002的 current-diagnostic exception全局扩散至 formal path。

### 24.5 Scientific workload, counts and zero-eigensolve boundary

以下 mapping均为 **`ESTABLISHED`**：

- diagnostic仍从 source rebuild `bulk-s24-g48`与`defect-N5-s24-g48`，并形成
  $alpha=\pi/4$、$artheta=\pi/4$、$artheta=0$三个 phase pairs；不存在001 cache/input path；
- width loop仍是 $1,\ldots,48$，保留 global、three restricted、endpoint parity、common-core六条路径、two
  warm-ups/five repeats、CV/quantization/spread gates与四-family DP；
- padding contract仍硬核对238 primary、10176 derived、总计$10414\times36$；writer schedule仍为
  `1 + 119 + 47 + 47 + 47 = 261` checkpoints，row additions总和10414；
- completion gate lines 1365--1448仍要求 exact 2 mesh、3 seam、6 primary、294 probe、8 partition、261 rewrite、
  one $1\times27$ forecast、$10414\times36$ padding、3 primary OP2、4 completed checkpoints、header-only bulk、
  no `.partial`、0 completed scientific eigensolves、no reference export及 forbidden field/spectrum/reference files；
- whole source唯一 `eigs(` call仍在 formal `LOCAL_low_spectrum` line 4256；representation runner不调用
  `LOCAL_low_spectrum`，只使用 allowlisted small dense `eig` probes。因此002没有 scientific eigenpair、field、
  branch、reference或 effectivity output path。

Source-owned geometry/material constants、FEM assembly、periodic reduction、canonicalization、tolerances、119-solve
formal schedule、branch/coverage/refinement/uncertainty rules未被002 dispatch选择修改。002差异仍严格限于 validated
identity、namespace/summary identity与 internal memory-policy conjunction。

### 24.6 Static helper signature and scope audit

Targeted static call/signature检查得到：

- `LOCAL_run_representation_diagnostic`：一个 definition、两个 exact validated one-argument calls；
- `LOCAL_initial_representation_summary`：一个 two-argument definition，main runner与terminal stub各一个
  two-argument call；
- `LOCAL_write_representation_terminal_stub`：一个 five-argument definition与一个 five-argument call；
- `LOCAL_representation_completion_gate`、`LOCAL_write_representation_ledgers`、
  `LOCAL_write_representation_summary`各有唯一 visible definition，调用参数数量与current signatures相容；
- 没有 duplicate targeted definition、arbitrary public diagnostic helper或 obvious variable-scope escape。

这是 lexical/static audit，不是 MATLAB parser、`checkcode`或 runtime result。Long multi-line MATLAB function
signatures只按 visible definitions/call sites逐项核对，本节不声称完成编译级证明。

### 24.7 Falsification, caveats and verdict

最关键 failure test——002的 `internal_pass`或002 failure reason仍依赖1.5 GiB `peak_pass`——被 current exact branch
**refuted**。Namespace leakage test亦未发现001 read/stat/hash/copy/reuse path。Scientific drift test由 exact counts、
single formal `eigs` location及 unchanged spec/constants通过。

- **`MINOR CAVEAT`**：本审计没有运行 MATLAB parser/runtime；allocation、filesystem atomic moves、294 probes、
  261 rewrites、wall与RSS只能由一次 future authorized execution验证。
- **`MINOR CAVEAT`**：source header的 `Based on` section list仍写到 `22--22.15`，未显式列§23；它仍链接同一
  authoritative `design-4-1a.md`，且 README/SYMBOLS已准确记录§23 mapping，因此不影响 executable scope、
  identity或 gate semantics。可在不阻塞002的后续机械文档维护中更正，不得为此改 science。
- **`MINOR CAVEAT`**：summary helper对任何非002 input使用001 fallback；current local scope只有已经exact-validated
  001/002 callers，故现状安全。Future caller若绕过entry validation将使该假设失效，届时必须 fail closed修订，
  不能引用本 PASS。

没有 unresolved blocker或 important caveat。**Researcher verdict: `THEORY-TO-CODE PASS`.** 下一最小 gate是
同一 Skeptic对 current source/docs/namespace作 full spec-to-code/resource pre-execution review；本 PASS不授权
创建002 namespace、执行 MATLAB/Octave/Python、启动 `run-006`、auto-retry、003、artifact mutation、project
result sync或任何 reference/effectivity claim。Runtime/resource feasibility保持 **`CONDITIONAL`**。

## 25. 2026-08-29 user-authorized `representation-gate-003` resource-policy amendment

Status: **`MINIMAL PROSPECTIVE AMENDMENT COMPLETE / SAME SKEPTIC DESIGN REVIEW REQUIRED / NO IMPLEMENTATION OR EXECUTION AUTHORIZED`**.

### 25.1 New authority, exact question and immutable failures

用户在 [[research/projects/eig-apost/implementation/i4/review-4-1a|postdiagnostic review §AM]] 后明确授权一次新的
representation diagnostic尝试，并把本次 whole-command resource upper limits唯一冻结为：elapsed wall
$1800$ s和 aggregate MATLAB process-tree RSS $2147483648$ bytes。除这两个 hard limits外，不得设置、沿用或
事后制造其他阻碍003执行完成的 resource upper；二者均无 grace。

本节 prospective supersede §23--§24、review §§AK--§AM中只适用于001/002的120 s、1 GiB/1.5 GiB current-
diagnostic stop、30 s cadence pass/fail及 internal resource-screen terminal语义，但不删除、改写或降格任何
历史记录。以下保持 **`ESTABLISHED`**：

- `representation-gate-001` consumed且保持§AJ的1 GiB resource-incomplete history；
- `representation-gate-002` consumed且保持§AM的
  `EXTERNAL_MONITOR_PROTOCOL_FAILURE / WALL HARD LIMIT EXCEEDED` history；其保存aggregate peak
  $1227096064$ bytes低于2 GiB，故不是memory failure；
- 两次均只到达three-primary-pair boundary、0 scientific eigensolves，不消费新的scientific attempt，也不提供
  derived/forecast/reference/effectivity evidence；
- freeze时 `diagnostics/representation-gate-003/`、external watchdog namespace及 `output/run-006/` 均不存在，
  current source尚未 allowlist 003。

003的目标仍只是取得完整 zero-scientific-eigensolve representation correctness/resource-observation artifact；
不是重解释001/002、不是新FEM方法、不是formal reference run。成功标准为：相同科学 workload完整发布，external
watchdog证明没有触发唯一两个 hard stops，再由同一 Skeptic作 postdiagnostic review。即使 MATLAB/Watchdog
自然完成，也不自行授权`run-006`。

### 25.2 Exact create-once identity and no-history boundary

新 identity冻结为：

```text
diagnostic_id = representation-gate-003
dispatch      = run_i4_1a('representation-gate-003','representation-diagnostic')
namespace     = test/i4/femref-a1/diagnostics/representation-gate-003/
```

Engineer只能在two-argument entry加入这个 exact pair，并把已经验证的ID传入现有 representation runner；不得
接受 arbitrary ID、alias、path或第三个 argument。003从 current source重新构造全部 meshes、phase reductions、
probe bases及 benchmark rows。MATLAB与watchdog均不得读取、load、stat、hash、copy、compare、link或复用001/002
artifacts、external logs、temporary data或 summaries；也不得读取其他 history/output、Markdown、review、Git、
BIE/QZ/estimator/reference data。

若003 diagnostic namespace已存在，MATLAB必须在evidence access前 `DIAGNOSTIC_COLLISION`；不得读取、覆盖、
补齐、删除、rename、换ID或自动 retry。Watchdog不得预创建science namespace。一次003 MATLAB child成功launch后，
无论 natural completion、incomplete、hard stop、MATLAB/environment/watchdog failure都永久消费003，并保留全部
reached final/partial evidence。本节不授权004或任何 replacement ID。

### 25.3 Only two resource hard stops

令watchdog从自身启动时取得 monotonic start time $t_0$，令$t$为current monotonic time；令
$\mathcal P(t)$ 是该次 dedicated MATLAB process group与以MATLAB root为根的recursive live descendant集合的
union，按PID去重并排除watchdog、outer `/usr/bin/time`及`/bin/ps` sampler。`/bin/ps`的RSS单位按KiB解释，冻结

$$
B_{\mathrm{RSS}}^{\mathrm{agg}}(t)
=1024\sum_{p\in\mathcal P(t)}\operatorname{rss}_{\mathrm{KiB}}(p).
$$

003 external resource controller只允许以下两个 stop predicates：

$$
t-t_0\ge1800\ \mathrm{s},
\qquad
B_{\mathrm{RSS}}^{\mathrm{agg}}(t)\ge2147483648\ \mathrm{bytes}.
$$

任一 predicate第一次成立时，watchdog必须直接向 current MATLAB process group及当次枚举的recursive descendants
发送 `SIGKILL`；不得先发 `SIGTERM`、等待 graceful shutdown、给予第二个 sample或 grace。除此之外，watchdog、
MATLAB、Code Runner及 postreview均不得以 resource理由提前停止003。尤其明确禁止把下列任一项用作 execution
stop、terminal failure或资源资格上限：

- 历史120 s、1 GiB、1.5 GiB或任何低于2 GiB的RSS/array threshold；
- monitor sample gap、nominal cadence、output/progress stall、缺少新CSV row或MATLAB stdout静默；
- RSS growth rate、three-times-RSS heuristic、footprint、virtual size、single-process RSS或internal array forecast；
- $T_{\mathrm{forecast}}$ margin、1.5 GiB observation、CV、spread、JIT/warm-up variation、timer resolution或
  quantization-floor warning；
- “near completion”、prior 001/002 runtime、tool scheduling latency或任何 attempt/stage/subprocess预算重置。

Correctness、canonical algebra、schema/count、atomic publication、collision、information isolation及 scientific
fail-closed gates仍可使MATLAB自然返回 incomplete；它们是evidence/science integrity conditions，不是另设的
resource upper limits。MATLAB/API/filesystem的实际exception也可自然终止process并原样保存，但不得被伪装为
较低 resource stop或自动 retry entitlement。

### 25.4 Fixed-ID external watchdog source

为消除002中由interactive tool scheduling造成的40 s sample gaps和late interrupt，Engineer只可新增一个
fixed-ID external runner source：

```text
test/i4/femref-a1/run_representation_gate_003_watchdog.pl
```

它必须是self-contained `/usr/bin/perl` source，无command-line arguments、无network/CPAN/runtime download、无
shell interpolation，并只使用macOS system Perl/core modules（至少 `strict`、`warnings`、`POSIX`、
`Time::HiRes`、`FindBin`）与 `/bin/ps`。任何 argument都必须在launch前 fail closed。Script以`FindBin`定位existing
experiment directory，只接受下述 fixed diagnostic/log identities；它不得discover repository root或读取human-
facing file来授权运行。

Watchdog child使用list-form `exec`直接启动唯一 MATLAB child command：

```text
/Applications/MATLAB_R2023b.app/bin/matlab
-batch
run_i4_1a('representation-gate-003','representation-diagnostic')
```

不得经过shell、不得改MATLAB arguments。Child在exec前建立以其PID为PGID的dedicated process group；parent也在
fork后立即确认同一PGID。Perl watchdog与outer `/usr/bin/time`留在该group之外。每次sample从
`/bin/ps -axo pid=,ppid=,pgid=,rss=,state=,command=`构造MATLAB-root recursive descendants，并与dedicated
PGID members取union、按live PID去重；因此普通wrapper/worker inheritance、reparent race及同group descendants
均被覆盖。不得把watchdog自身、outer `time`或每次spawn的`ps`计入aggregate。

Wall enforcement必须用 `Time::HiRes::clock_gettime(CLOCK_MONOTONIC)`；calendar time只用于日志。Script从
入口第一条可执行语句启动1800 s clock，并在MATLAB group active期间保持hard-deadline检查。RSS poll nominal
interval固定为1.0 s；每次实际elapsed与gap均记录。该interval只为evidence resolution，不是新的 upper或
pass/fail gate：scheduler delay、单次`ps` unavailable或sample gap不得触发stop。`ps` unavailable必须写
`SAMPLE_UNAVAILABLE`并继续；它可能使postreview的resource evidence不足，但不授权第三种 resource stop。
Wall deadline不依赖stdout/progress或next user/tool turn。

Natural completion只有在MATLAB root已reaped且current dedicated group/recursive live set为空时成立。Hard stop时
直接kill group及current enumerated descendants，作nonblocking reap、flush minimum terminal record并立即退出；
不得设置shutdown wait/grace。Watchdog不得修改MATLAB science artifacts、不得向diagnostic namespace写sidecar，
也不得把external sample传回MATLAB control flow。

### 25.5 Create-once external logging and exact schemas

External evidence namespace冻结为：

```text
test/i4/femref-a1/watchdog/representation-gate-003/
```

Watchdog开始时先确认003 science namespace与该external namespace均不存在；随后只原子claim external namespace，
不得预建science namespace。External namespace collision在MATLAB launch前fail closed且不得删除/overwrite；一旦
external namespace成功claim，即使subsequent fork/exec/logging失败也不得自动重用该watchdog ID，必须交同一
Skeptic分类。MATLAB child一经launch即同时消费diagnostic ID。

External namespace只允许：

```text
samples.tsv.partial        # live, line-buffered and fsync/flush after every row
samples.tsv                # atomic final rename after target terminal handling
watchdog-summary.tsv       # atomic summary-last external commit marker
matlab.stdout.log          # append-only child stdout
matlab.stderr.log          # append-only child stderr
```

`samples.tsv`固定11 columns：

```text
sequence,utc,elapsed_seconds,sample_gap_seconds,matlab_root_pid,process_group_id,live_pid_count,pid_rss_kib_pairs,aggregate_rss_bytes,sample_status,decision
```

`pid_rss_kib_pairs`按numeric PID升序写 `pid:rss_kib` 并以分号分隔；unavailable sample保留empty pair/aggregate和
`sample_status=SAMPLE_UNAVAILABLE`，不得伪造0。`decision`只允许空、`NATURAL_EXIT_OBSERVED`、
`WALL_HARD_LIMIT_KILL`或`RSS_HARD_LIMIT_KILL`。每个sample row必须同时原样mirror到unbuffered watchdog stdout；
sidecar是structured row authority，captured stdout是独立liveness/cross-check evidence。二者不同步只影响
postreview evidence quality，不触发额外execution stop。

`watchdog-summary.tsv`固定18 columns且恰一行：

```text
diagnostic_id,status,stop_reason,start_utc,end_utc,elapsed_seconds,wall_limit_seconds,rss_limit_bytes,matlab_root_pid,process_group_id,sample_count,unavailable_sample_count,aggregate_peak_rss_bytes,child_wait_status,child_exit_code,child_signal,diagnostic_namespace_present,claim_boundary
```

`status`只允许 `TARGET_EXITED`、`WALL_HARD_LIMIT_KILLED`、`RSS_HARD_LIMIT_KILLED`或
`WATCHDOG_OPERATIONAL_INCOMPLETE`；它不是representation/resource PASS。`aggregate_peak_rss_bytes`只取available
aggregate samples的maximum；无available sample则留空，不写0。`claim_boundary`固定为
`EXTERNAL_WALL_AND_AGGREGATE_RSS_CONTROL_ONLY`。Summary不得解析、改写或提升MATLAB science status。

Parent在fork前打开create-once stdout/stderr logs并交child继承；不得truncate existing file。所有 TSV numeric
values以可往返精度输出，text字段不得含tab/newline。若sidecar写失败，watchdog应尽可能继续以stdout记录并执行
两个 hard stops；logging failure本身不是第三个resource threshold，但最终 external status必须
`WATCHDOG_OPERATIONAL_INCOMPLETE`且postreview不得声称完整resource evidence。

### 25.6 Exact outer command and wall authority

经全部 design/code gates通过后，Code Runner只可在
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`执行一次：

```text
/usr/bin/time -lp /usr/bin/perl ./run_representation_gate_003_watchdog.pl
```

Outer `/usr/bin/time`覆盖整个Perl watchdog command，包括launch、monitor、MATLAB target、kill/reap及external
summary finalization；其terminal `real`作为post-exit wall cross-check。Resource stop authority以watchdog monotonic
decision为主：若MATLAB group在elapsed首次达到1800 s仍active，必须当场`SIGKILL`，不存在为log finalization或
reap提供的运行grace。Outer `time`的maximum resident set size主要描述watchdog command，**不得**替代
`samples.tsv`的aggregate MATLAB-tree RSS；memory authority只来自watchdog逐sample aggregate。若sidecar与captured
stdout/outer record矛盾，postreview降级evidence，不得发明第三个stop或自动retry。

Command不得拆分为preflight/science stages，不得由另一shell loop、interactive poll或Codex tool turn承担hard
stop，不得从001/002恢复，也不得修改script arguments、sample interval、limits或paths。Implementation完成后可在
不创建003 namespaces、不launch MATLAB的前提下运行一次 `/usr/bin/perl -c` static syntax check；该check不是
diagnostic run或resource evidence，结果必须进入pre-execution review。

### 25.7 Dispatch-local 27-column observation semantics

003仍执行与001/002相同的 timing、array inventory、DP和forecast calculations，并保持27-column schema不变。
以下 observations必须如实写出，不能删、round-to-pass或覆盖：`forecast_strictly_below_30`、
`forecast_at_most_1p5_gib`、每个probe的repeat min/mean/max/CV/quantization/conservative seconds、row preparation
statistics、partition bounds、rewrite timings及spread/margin inputs。

为同时保留观察结果且避免资源advisory误分类003 execution，forecast row对003固定采用：

```text
advisory_resource_screen = wall_pass && peak_pass && timing_pass
internal_gate_pass       = advisory_resource_screen
```

这里 `internal_gate_pass` 只保存**历史 internal resource-screen observation**，不是003 execution gate。若它为
false，27-column `failure_code`固定为 `ADVISORY_RESOURCE_SCREEN_FALSE`，`failure_reason`必须以
`OBSERVATION_ONLY_NOT_EXECUTION_FAILURE`开头，并逐项机器可读记录
`wall_pass`、`forecast_at_most_1p5_gib`和`timing_pass`的true/false；不得写
`RESOURCE_BUDGET_UNAVAILABLE`、`WALL HARD LIMIT EXCEEDED`、memory exceeded或任何会冒充actual execution
failure的文字。若advisory screen为true，两格留空。

同理，003 probe row因CV超过0.25或zero-looking/timer/JIT variation而false时，16-column row只能使用
`ADVISORY_TIMING_VARIABILITY`与 `OBSERVATION_ONLY_NOT_EXECUTION_FAILURE` reason；不得写
`RESOURCE_BUDGET_UNAVAILABLE`。Growing rewrite的schedule、row identity、serializer、atomic MAT/CSV及finite
numeric evidence gates保持hard correctness/schema gates；仅由clock nesting、timer resolution造成的旧
timing-consistency inequality不得在003抛出execution-stopping error，其原始 timing columns保留供postreview
重算。实际 action exception、wrong row counts、nonfinite data object、write/move failure仍按evidence-integrity
incomplete处理，而不是resource limit。

003 terminal selection完全不消费 `internal_gate_pass`、CV、spread、forecast margin或1.5 GiB observation：

- 若 exact workload、correctness、schemas、counts、inventories、atomic/no-partial及 isolation gates complete，
  MATLAB必须写 `REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`；
- 若上述 evidence/scientific integrity gate失败，写 `REPRESENTATION_GATE_INCOMPLETE`及真实 first cause；
- 003不得写 `REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`。

External watchdog自然终止或hard kill后，只有同一 Skeptic能联合解释MATLAB/external artifacts。Pending不等于PASS，
advisory false也不等于003 execution failure。001的 historical conjunction、002的§23 conjunction及formal
`spec.preflight_peak_cap_gib=1.5`必须原样保留；Engineer只能新增003-specific branches，不能全局删除观察公式或
formal gate。

### 25.8 Scientific workload, artifact and retry invariants

003必须逐项保留：

1. exact continuous model、geometry/material、quasiperiodic phases、consistent $P_1$ weak form、periodic
   prolongation、raw/canonical Hermitian objects、mass `chol`及全部 tolerances；
2. source-rebuilt largest bulk `bulk-s24-g48` at $\alpha=\pi/4$、finest defect
   `defect-N5-s24-g48` at $\vartheta=\pi/4$及同mesh endpoint $\vartheta=0$；
3. 2 mesh、3 seam、6 primary、294 probe、8 partition、exact $10414\times36$ row preparation、261 shared-v2
   writer checkpoints、one 27-column forecast及19-field summary；
4. 36/17/16/7/11/27/19 schemas、10/14 header-only bulk ledgers、MAT mirrors、first-failure、summary-last、atomic/
   no-partial及 required/forbidden file gates；
5. zero scientific `eigs`、no eigenvalue/field/band-gap data/branch/reference/effectivity export、same claim boundary
   与 no-history/no-estimator isolation。

不得为了30 min/2 GiB budget缩减width、warm-ups/repeats、probes、DP families、rows、checkpoints、canonical checks
或artifact publication。不得通过多个commands、children或attempt directories重置预算。003 complete/incomplete都
消费ID，不存在same-ID retry；本节不授权new attempt、004或`run-006`。

### 25.9 Mandatory gate and postdiagnostic review

Sequence冻结为：same-Skeptic design review；same-Engineer bounded MATLAB/README/SYMBOLS及one watchdog source
implementation；same-Researcher theory-to-code audit；same-Skeptic spec-to-code/watchdog pre-execution review；只有
全部通过才执行§25.6 exact command一次。Pre-execution review必须检查Perl source没有hidden threshold、alarm/
monotonic clock、dedicated process group、recursive/PGID RSS union、SIGKILL、collision/log schemas及fixed MATLAB
exec，并核对 `perl -c` result。不得把static PASS冒充watchdog runtime PASS。

Postdiagnostic review至少核对：exact outer/child commands、cwd、IDs/collisions、watchdog stdout与TSV、monotonic
elapsed、outer `time -lp`、all sample PID/RSS arithmetic、stop reason、only-two-limit compliance、MATLAB final/partial
artifacts、all exact counts/schemas、advisory forecast/probe semantics、0 scientific eigs、001/002 immutable及
`run-006` absence。Sample cadence、output stall、CV/spread/forecast/1.5 GiB observation可以限制evidence解释，但
不得事后改写为003 resource stop或execution failure。只有 unresolved correctness/schema/atomic/isolation failure、
actual 1800 s hard stop、actual 2 GiB hard stop或external evidence无法支持结论时，Skeptic才可阻止下一阶段；任何
结果都不自动授权formal run。

### 25.10 Researcher disposition

本节没有修改 code、README、SYMBOLS、review、STATUS或artifacts，没有创建003/watchdog namespaces，没有运行
Perl、MATLAB、Octave、Python或 numerical computation，也没有开始`run-006`。System paths `/usr/bin/perl`、
`/bin/ps`、`/usr/bin/time`及MATLAB executable经只读identity check存在；这不是syntax/runtime验证。

**Researcher verdict: `GO TO SAME SKEPTIC DESIGN REVIEW / IMPLEMENTATION AND EXECUTION REMAIN BLOCKED`.**
New explicit user authority使003 create-once continuation为 **`PROVISIONAL-GO`**；scientific workload/schema/no-
history invariants保持 **`ESTABLISHED`**；watchdog implementation与30 min/2 GiB feasibility仍为
**`CONDITIONAL`**。最弱步骤是Perl process-group/tree accounting与hard-kill behavior尚未实现/静态复核，随后完整
294/10414/261 workload仍未到达。只有同一 Skeptic确认本节没有hidden resource gate后，才可交同一 Engineer。

## 26. 2026-08-29 bounded controller-enforceability revision after review §AN

Status: **`BOUNDED REVISION COMPLETE / SAME SKEPTIC RE-REVIEW REQUIRED / NO ENGINEER OR EXECUTION AUTHORIZED`**.

### 26.1 Scope, authority and preserved contract

本节只关闭 [[research/projects/eig-apost/implementation/i4/review-4-1a|review §AN]] 的两个 controller
`BLOCKER`及相邻 lifecycle caveats。它 prospective supersede §25.3--§25.6、§25.9中关于 RSS-unavailable-
and-continue、whole-outer-command 1800 s、nonblocking reap及 logging failure的冲突文字；§25其余 exact identity、
scientific workload、schemas、advisory observation、no-history和postreview rules原样保留。

以下不变：2 GiB仍是003唯一 memory upper predicate；不增加早于1800 s的reserve/deadline；不恢复120 s、1 GiB、
1.5 GiB、cadence、stall、RSS slope、CV/spread、forecast/JIT/timer-resolution resource stops；continuous model、FEM
forms、2/3/6/294/8/10414/261 counts、36/17/16/7/11/27/19 schemas及zero-scientific-eigensolve boundary不变；
001/002 consumed histories immutable；`run-006`完全冻结。

### 26.2 Exact controller state machine

Watchdog lifecycle冻结为以下单调states，不能跳过或事后重写：

```text
PRELAUNCH
EXTERNAL_LEAF_CLAIMED
PGID_READY_PREEXEC
EXEC_CONFIRMED
RUNNING_RSS_AUTHORITY_VALID
KILL_ISSUED | NATURAL_ROOT_EXITED
TARGET_DEAD_CONFIRMED
EXTERNAL_LEDGER_FINALIZED
```

`EXTERNAL_LEAF_CLAIMED`只消费independent watchdog evidence leaf，不消费science ID。只有CLOEXEC handshake证明
fixed MATLAB `exec`成功，state才进入 `EXEC_CONFIRMED`，此时003 science ID永久消费；其后任何complete、
incomplete、controller kill、MATLAB/environment failure都不得重用003。任何发生在confirmed exec之前的Perl
module/path/collision/fork/pipe/setpgid/redirect/exec failure都不消费science ID，但已claim external leaf仍create-
once且不得自动删除或复用；未来是否有新的external leaf authority必须回同一 review/user，不能由Engineer换名。

### 26.3 CLOEXEC exec-status and pre-exec PGID handshake

Fixed Perl source必须在fork前创建两个anonymous pipes：`exec_status`和`exec_release`。`exec_status` child-write
descriptor用 `Fcntl` 设置 `FD_CLOEXEC`；parent关闭write end，child关闭read end。Lifecycle固定为：

1. Child fork后立即调用 `POSIX::setpgid(0,0)`，验证 `getpgrp()==child_pid`，并把
   `PGID_READY:<pid>:<pgid>` 写入 `exec_status`；随后阻塞等待parent在`exec_release`写exact `EXEC_GO`。
2. Parent也立即调用 `setpgid(child_pid,child_pid)`；`EACCES`只在child已完成同一设置且subsequent Perl builtin
   `getpgrp(child_pid)==child_pid`时可接受。Parent必须验证
   `child_pid>1`、`pgid==child_pid`且`pgid!=supervisor_pgid`，然后才写 `EXEC_GO`。任一pre-exec invariant失败，
   parent写/关闭abort，使用**positive child PID**停止尚未exec的child并wait/reap；不得negative-group kill，
   science ID不消费。
3. Child取得 `EXEC_GO`后按§25.4打开既定stdout/stderr、用list-form执行fixed MATLAB path及exact batch string。
   `exec` failure必须把 `EXEC_ERROR:<errno>:<message>` 写入仍打开的status pipe并 `_exit`。成功exec会由
   `FD_CLOEXEC` 自动关闭write descriptor；parent只有在收到clean EOF、未收到error payload、child尚未被
   reaped且再次用 `getpgrp(child_pid)` 验证dedicated PGID invariant后，才记录 `EXEC_CONFIRMED`并消费003。
4. Target-active clock的zero point是parent完成上述exec+PGID confirmation的同一 monotonic timestamp。不得用
   watchdog source load、parent directory creation、external leaf claim、pipe/fork或pre-exec validation时间构造
   early reserve；也不得等第一张scientific artifact或第一条RSS sample才延后clock。

这种two-sided `setpgid`加release barrier使MATLAB不能在dedicated PGID验证前运行；CLOEXEC EOF则区分真实exec与
fork/pre-exec failure。Watchdog supervisor、outer `/usr/bin/time`及sampler始终不进入dedicated group。

### 26.4 RSS authority invariant and operational-integrity kill

2 GiB memory predicate仍且只仍是

$$
B_{\mathrm{RSS}}^{\mathrm{agg}}(t)\ge2147483648\ \mathrm{bytes}.
$$

但是执行该hard cap要求在target active期间持续拥有可解释的RSS authority。每个attempted sample必须满足全部
authority invariants：

1. `/bin/ps`正常退出，full-table rows按冻结 PID/PPID/PGID/RSS/start-identity/state/command grammar无歧义解析，
   RSS是nonnegative integer KiB；
2. confirmed MATLAB root identity仍对应其original `(pid,start_identity)`，dedicated PGID仍是validated
   `child_pid`且不同于supervisor group；
3. current recursive descendants、current dedicated-PGID members及known-descendant inventory完成union与PID
   去重；任何live known PID都必须通过stable start identity检查，PID reuse的new identity不得继承旧membership；
4. aggregate arithmetic无overflow/nonfinite/negative，且sample row成功写入并flush structured partial sidecar与
   unbuffered watchdog stdout。不得以outer `time`、footprint、single PID或last sample补值。

一旦target已exec而任一上述 invariant丢失，watchdog必须**立即**对已验证dedicated PGID执行下述guarded
`SIGKILL`，并 best-effort对当前identity-verified known descendants逐PID发 `SIGKILL`。Terminal分类固定为：

```text
status      = WATCHDOG_OPERATIONAL_INCOMPLETE
stop_reason = RSS_AUTHORITY_LOST
decision    = OPERATIONAL_INTEGRITY_KILL
```

它明确不是第三resource threshold、不是memory upper crossing，也不得写 `RSS_HARD_LIMIT_KILLED`、
`EXTERNAL_MEMORY_BUDGET_UNAVAILABLE`或声称达到2 GiB。其authority来自fail-closed controller integrity：如果
aggregate cap已无法测量/证明，继续运行会使唯一2 GiB hard cap不可执行。一个或多个prior valid low samples只证明
那些离散时刻；它们不能替代subsequent authority，不能授权在current parsing/coverage/logging failure后继续。

每次authority sample冻结为exact full-table命令

```text
/bin/ps -axo pid=,ppid=,pgid=,rss=,lstart=,state=,command=
```

Parser按前四个integer fields、`lstart`的固定五个tokens、一个state token及其后原样command remainder拆分；若row
缺field、integer非法、`lstart`不能形成stable identity、command remainder缺失或存在任何歧义，则该attempted sample
不是valid low observation，而是立即 `RSS_AUTHORITY_LOST`。这一exact command与grammar同时冻结coverage和logging
所需输入，Engineer不得改用只列PGID、只列root subtree、缓存PID list或outer `time`的较窄snapshot。

Nominal 1 s cadence与actual gap仍只作observation；**延迟本身**不触发kill或额外upper。但每次sample attempt一旦
发生，就必须完整通过上述authority invariants；`SAMPLE_UNAVAILABLE`不再是continue状态。Watchdog stdout或
sidecar的required sample write/flush失败、full-table `ps` failure、root/PGID coverage ambiguity或identity arithmetic
failure均进入同一 immediate operational kill。MATLAB自己的stdout/stderr内容或progress stall仍不参与authority。

### 26.5 Known-descendant inventory and PID-reuse guard

每个valid sample把当时由root parent chain确认的descendant保存为
`(pid,start_identity,first_seen_pgid,first_seen_parent_chain)`。后续即使该PID reparent或离开dedicated PGID，只要
full-table snapshot仍显示相同 `(pid,start_identity)` live，它继续进入aggregate与kill inventory；若PID消失则标记
exited，若同PID出现different start identity则显式标记 `PID_REUSED_EXCLUDED`，不得把新process计入或kill。

`start_identity`固定使用macOS `ps`的stable process-start field，而不是变化的elapsed time或command text；command
只作audit。若该field缺失、grammar无法无歧义解析或known live identity不能判定，即RSS authority loss，按§26.4
kill，不得假定process已退出。这样current recursive/PGID union不再声称单独覆盖全部reparent race；coverage由
append-only known inventory保守补足。

### 26.6 Guarded negative-group kill and target-dead confirmation

任何 `kill 'KILL', -$pgid` 前必须重新执行纯scalar guard：

```text
defined(pgid)
pgid == child_pid
pgid > 1
pgid != supervisor_pgid
dedicated_pgid_was_verified == true
```

并记录guard inputs。任一guard false时绝不执行negative kill，以免误杀watchdog/shell group；立即对仍具stable
identity的known child/descendants逐positive PID kill，external status仍 operational incomplete且不得声称hard cap
完整执行。Guard通过时先negative group `SIGKILL`，再对current/known identity-verified descendants作best-effort
positive kills；不对PID-reused entries发signal。

`KILL_ISSUED`不是`TARGET_DEAD_CONFIRMED`。Watchdog必须blocking `waitpid`直接child以取得exact wait status，并以
subsequent valid process-table/group-existence checks确认validated PGID无live member、known descendant inventory无
same-identity live PID，才可标target dead。Natural root exit也必须完成同一group/known-descendant emptiness check；
若root已exit但worker仍live，target-active interval继续，达到1800 s仍执行hard kill。Reap/identity check failure写
`WATCHDOG_OPERATIONAL_INCOMPLETE`与真实cause；不得伪造natural exit或resource crossing。

### 26.7 Exact 1800 s interpretation without an earlier reserve

为解决§AN Finding 2，本节明确选择：**1800 s约束完整 MATLAB target active lifetime，而不是Perl interpreter与
post-target ledger administration的总和。** Target active interval从§26.3 confirmed exec/PGID-ready monotonic
timestamp开始，到以下较早事件：

- root及全部validated group/known descendants natural dead；或
- watchdog第一次观测target-active elapsed $\ge1800$ s并立即发出guarded `SIGKILL`的timestamp。

不存在早于1800 s的reserve、control deadline、soft limit或grace；1799.999 s不能因wall被kill，1800 s达到即
kill。Hard kill后不再运行任何MATLAB scientific instruction，故随后blocking reap、identity confirmation、partial-
to-final rename及one-row summary是administrative evidence finalization，不是MATLAB继续运行、不是scientific grace、
不是第二run，也不能重置/延长target clock。

为使“达到1800 s立即停止”不依赖1 s observation cadence，parent在§26.3 target-active zero point立即设置唯一
one-shot `Time::HiRes::alarm(1800)`。`SIGALRM` handler只读取预先验证且此后immutable的 `child_pid`、dedicated
`pgid`、`supervisor_pgid`和verification flag，记录in-memory wall-trigger flag/timestamp并直接执行§26.6 guarded
negative-group `SIGKILL`；它不得等待下一次RSS sample、stdout、progress或ledger write。Main loop的monotonic
elapsed comparison只作同一1800 s predicate/deadline的redundant enforcement，二者先触发者都产生exact
`WALL_HARD_LIMIT_KILLED`，不得把alarm与loop解释为两个deadline、reserve或grace。

这与 `test/AGENTS.md` shared-budget原则的最小可执行解释是：全部numerical stages、MATLAB children/subprocesses及
scientific artifact production共享同一未重置target-active clock并最多active到1800 s；pre-exec controller safety
setup不启动numerical target，post-death fixed ledger closure不包含live numerical process。Outer exact
`/usr/bin/time -lp /usr/bin/perl ...` 的 `real`必须完整记录setup、target和finalization总时长，供review披露controller
overhead，但它不形成更早wall kill或把post-death bookkeeping冒充budget grace。

“Bounded finalization”只表示固定、有限的已有samples flush/rename、blocking child reap、one process-table emptiness
confirmation及one summary write；不得sleep等待新science、retry target、重跑`ps`直至有利结果、做network访问或
启动另一process group。不另设finalization seconds cap，因为那会成为新的低wall upper；若这些固定operations
失败/不返回，outer record与partial files如实显示 `WATCHDOG_OPERATIONAL_INCOMPLETE`，但MATLAB已被kill或natural
dead，不存在科学运行grace。

### 26.8 Logging, leaf consumption and terminal vocabulary

External parent directory `test/i4/femref-a1/watchdog/` 可在prelaunch机械创建；它不是evidence或ID consumption。
只有atomic `mkdir watchdog/representation-gate-003/` claim external create-once leaf。Local Perl只要求
`IO::Handle::flush`/unbuffered writes；不得声称`POSIX::fsync`，也不得新增durability dependency。

Prelaunch failure semantics：若发生在external leaf claim前，无leaf/science consumption；若发生在leaf claim后但
confirmed exec前，external leaf consumed、science ID未消费，写best-effort
`WATCHDOG_OPERATIONAL_INCOMPLETE / PRELAUNCH_FAILURE`并禁止auto-retry。Confirmed exec后，以下controller failures
均立即operational kill且science ID consumed：RSS/ps/coverage/log authority loss、dedicated PGID invariant loss、
negative-kill guard failure或unrecoverable watchdog control exception。它们不是resource threshold。

§25.5的11-column sample schema与18-column summary schema不变，只扩充既有text enums：sample `decision`允许
`OPERATIONAL_INTEGRITY_KILL`；summary `status=WATCHDOG_OPERATIONAL_INCOMPLETE`时 `stop_reason`至少区分
`RSS_AUTHORITY_LOST`、`PGID_INVARIANT_LOST`、`KILL_GUARD_FAILED`、`REAP_CONFIRMATION_FAILED`、
`PRELAUNCH_FAILURE`。只有valid aggregate达到2 GiB才允许 `RSS_HARD_LIMIT_KILLED`；只有target-active monotonic
elapsed达到1800 s才允许 `WALL_HARD_LIMIT_KILLED`。Operational branch保留last valid peak或空值，绝不把它改写为
threshold crossing。

Sidecar与unbuffered stdout每个valid sample都必须成功；logging authority loss后即kill。若kill后summary sidecar
无法提交，以stdout/stderr/partial为best-effort record并保持operational incomplete。MATLAB永不读取external leaf。

### 26.9 Outer `time` and postreview authority

Exact outer command保持§25.6不变。`/usr/bin/time -lp`的`real`是total supervisor cross-check；其maximum resident
set size主要是Perl supervisor process accounting，**不是 aggregate MATLAB process-tree RSS authority**，不得用于
填补missing samples、证明低于2 GiB或触发2 GiB predicate。Memory authority只来自每个valid full-tree watchdog
sample；一旦该authority lost，唯一合法动作是§26.4 operational kill。

Postreview必须分别报告 target-active elapsed、kill issuance、target-dead confirmation、ledger-finalization结束及
outer `real`，不得只给一个wall number混淆scientific lifetime与administration。RSS hard-stop verdict必须展示触发
sample的full PID arithmetic；operational loss必须展示last valid sample和authority-loss cause，并明确“2 GiB not
shown reached”。任一branch都不自动授权`run-006`。

### 26.10 Authorization boundary and Researcher verdict

本节没有修改 scientific code、README、SYMBOLS、review、STATUS或artifacts，没有创建003/watchdog namespace，
没有运行Perl、MATLAB、Octave、Python、`perl -c`或 numerical computation。它不授权Engineer、watchdog source
creation、docs/code edits、003 execution、004、new attempt、`run-006`或reference/effectivity sync。

**Researcher verdict: `GO TO SAME SKEPTIC §26 RE-REVIEW / IMPLEMENTATION AND EXECUTION REMAIN BLOCKED`.**
§AN两个blockers的constructive resolution为：RSS authority loss取得明确 operational-integrity kill authority；
1800 s唯一wall predicate改为MATLAB target-active lifetime且无early reserve，post-death ledger closure由outer real
透明记录。Exec/PGID/kill/reap/known-PID state machine现为 **`PROVISIONALLY ESTABLISHED AT DESIGN LEVEL`**；Perl
API、signal/race、process identity parsing及runtime feasibility仍为 **`CONDITIONAL`**。只有同一 Skeptic确认这些
选择可执行且没有隐藏低门，才可另行授权same Engineer。

## 27. 2026-08-29 minimal controller amendment after review §AO

Status: **`BOUNDED REVISION COMPLETE / SAME SKEPTIC RE-REVIEW REQUIRED / NO ENGINEER OR EXECUTION AUTHORIZED`**.

### 27.1 One immutable `EXEC_GO`-anchored deadline

§26.3--§26.7中较晚的exec-confirmation zero point与fresh 1800 s relative timer由本节prospectively supersede。Parent
取得一次且仅一次 `CLOCK_MONOTONIC` timestamp $t_0$，随即把exact `EXEC_GO`写入release pipe；这个release timestamp
就是provisional target-active $t_0$，不可在clean CLOEXEC EOF、PGID recheck、first sample或任何后续state重置。
Immutable absolute deadline固定为

$$
t_{\mathrm{deadline}}=t_0+1800\ \mathrm{s}.
$$

若release write、child `exec`或CLOEXEC confirmation失败，沿用pre-exec failure语义：science ID不消费，并丢弃该
provisional clock/deadline。若exec确认成功，science ID按既定规则消费；parent只计算同一absolute deadline的positive
remaining interval $t_{\mathrm{deadline}}-t_{\mathrm{now}}$并据此arm一次one-shot alarm。若remaining小于或等于零，
不得arm fresh timer，而须立即执行既定guarded `SIGKILL`并分类 `WALL_HARD_LIMIT_KILLED`。Main loop同样只使用
`now >= deadline`这一inclusive comparison；alarm与loop均不得重新累计elapsed、reset/rearm 1800 s或形成另一个
deadline。$t_0$在release syscall前紧邻取得以保证MATLAB不可能在被计时前执行；这段保守accounting不是提前reserve、
soft stop或第三resource predicate。

### 27.2 Dedicated-PGID membership as a nominal enforceability invariant

在nominal target-active operation中，每个identity-verified live known target descendant必须仍属于已经验证的dedicated
PGID。任一此类descendant被full-table authority观察为live且 `pgid != dedicated_pgid`，watchdog必须立即执行§26.6
operational-integrity kill及identity-verified positive-PID cleanup，terminal分类固定为

```text
status      = WATCHDOG_OPERATIONAL_INCOMPLETE
stop_reason = TARGET_LEFT_DEDICATED_PGID
decision    = OPERATIONAL_INTEGRITY_KILL
```

该invariant保证nominal deadline时全部live target members由guarded negative-PGID kill覆盖；它不是wall/RSS crossing、
不是第三resource upper，也不得声称达到1800 s或2 GiB。Known-descendant inventory仍保留用于positive cleanup、PID-
reuse guard与target-dead confirmation，不因此invariant删除或缩窄。

本节仅修复上述两个controller points。唯一resource uppers仍为target-active absolute deadline 1800 s与authoritative
aggregate RSS 2147483648 bytes；scientific workload、schemas、continuous model、001/002 histories与`run-006`边界均
不变。本节不授权Engineer、source/doc modification、`perl -c`、003 execution或`run-006`。

**Researcher verdict: `GO TO SAME SKEPTIC §27 RE-REVIEW / IMPLEMENTATION AND EXECUTION REMAIN BLOCKED`.**

## 28. 2026-08-29 theory-to-code mapping after §AP bounded implementation

Status: **`STATIC MAPPING COMPLETE / ONE CONTROLLER BLOCKER / EXECUTION NOT AUTHORIZED`**.

本节只审计current source diff，不修改code/docs/artifacts，不执行watchdog或MATLAB。Source locators均指本次审计时
工作树中的line numbers；scientific meaning仍由§§22--27与review §AP控制。

### 28.1 MATLAB dispatch and diagnostic mapping

| Frozen object | Exact source mapping | Static finding |
|---|---|---|
| Exact 003 allowlist, ID and dispatch | `test/i4/femref-a1/run_i4_1a.m:37-73`，其中003 pair在`:66-68` | 只有exact `representation-gate-003`加`representation-diagnostic`进入既有representation runner；arbitrary two-input pair fail closed。|
| Create-once science namespace | `run_i4_1a.m:989-1002` | Selected ID只形成`diagnostics/<diagnostic_id>`并先查collision；003 path没有history fallback。|
| Frozen source rebuild and primary objects | `run_i4_1a.m:1040-1096` | 两张mesh、三条phase及六个primary rows沿用既有build/reduce/prepare calls；此dispatch不调用scientific `LOCAL_low_spectrum`。|
| Probe/DP/row/writer workload | `run_i4_1a.m:1098-1213`, `:1221-1236`, `:1257-1284`, `:1760-1933` | 两组各三条primary costs加$6\times48=288$ width rows给294 rows；8条partition、$10414\times36$ preparation及261-checkpoint writer仍由原helpers形成。|
| 27-column advisory record | `run_i4_1a.m:1281-1326`, `:2026-2069` | 003仍诚实记录`wall_pass`、1.5 GiB `peak_pass`、timing/CV/spread及three-way `internal_pass`；false branch只写`ADVISORY_RESOURCE_SCREEN_FALSE / OBSERVATION_ONLY_NOT_EXECUTION_FAILURE`。|
| CV advisory | `run_i4_1a.m:1660-1717` | Nonfinite/negative timing仍是evidence correctness failure；仅CV超过0.25在003写`ADVISORY_TIMING_VARIABILITY`，不成为terminal resource stop。|
| Clock-nesting observation | `run_i4_1a.m:1937-1965` | 003 hard-check只消费exact schedule与finite/nonnegative evidence；`timing_consistency`仍计算但不进入003 `rewrite_pass`。001/002保留原conjunction。|
| Pending terminal and exact summary | `run_i4_1a.m:1332-1381`, `:1469-1500`, `:2091-2110` | 003 correctness complete时无论advisory `internal_pass`都只到`REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW`；exact expected dispatch、19-field summary与`PENDING_SAME_SKEPTIC_POST_EXIT_REVIEW`保持。|
| Count/schema/isolation gate | `run_i4_1a.m:1391-1462` | 36/17/16/7/11/27及2/3/6/294/8/10414/261 exact gates、0 eigensolves、0 reference export和forbidden-output absence均仍是pending-summary必要条件。|

### 28.2 External watchdog mapping

| Frozen controller object | Exact source mapping | Static finding |
|---|---|---|
| Fixed identity, no arguments and external leaf | `test/i4/femref-a1/run_representation_gate_003_watchdog.pl:23-37`, `:42-65` | Exact ID/batch/path constants；`@ARGV==0`；science/external collisions先查，`mkdir watchdog/representation-gate-003`独立atomic claim。|
| Exclusive/atomic external artifacts | `run_representation_gate_003_watchdog.pl:98-127`, `:395-445`, `:704-816` | 11/18-column schemas、exclusive partial/child logs、per-row write+flush、partial-to-final rename及exclusive temporary summary-to-final rename形成external-only ledger。|
| CLOEXEC, release and two-sided PGID | `run_representation_gate_003_watchdog.pl:118-185`, `:450-477` | CLOEXEC status pipe、`PGID_READY`/`EXEC_GO` barrier、parent/child `setpgid`及`pgid==child_pid!=supervisor_pgid`均在fixed list-form MATLAB exec前；clean EOF/PGID/reap checks后才置`science_consumed=1`。|
| One absolute wall deadline | `run_representation_gate_003_watchdog.pl:169-217`, `:219-300` | `target_start`紧邻且先于`EXEC_GO`，唯一`deadline=target_start+1800`；post-confirm只按positive remaining arm，`remaining<=0`立即kill；loop所有wall checks均为inclusive `now>=deadline`，没有fresh 1800 s rearm。|
| Exact 2 GiB predicate | `run_representation_gate_003_watchdog.pl:27-32`, `:302-308` | 唯一memory upper为arbitrary-precision aggregate `>=2147483648` bytes；1 s只用于observation sleep。|
| Full-table RSS authority | `run_representation_gate_003_watchdog.pl:31-35`, `:497-640` | Exact full `/bin/ps` grammar；recursive descendants与dedicated-PGID members union后按PID去重，stable start identity、known inventory及PID-reuse exclusion参与aggregate。|
| Dedicated-PGID membership invariant | `run_representation_gate_003_watchdog.pl:601-621` | 每个identity-verified live known target若离组，返回exact `TARGET_LEFT_DEDICATED_PGID`，由`:278-284`分类为operational-integrity kill；known inventory未被删除。|
| RSS/control-authority loss | `run_representation_gate_003_watchdog.pl:239-285`, `:347-389` | `ps`、parse、identity、membership或required live-log exception均降为`WATCHDOG_OPERATIONAL_INCOMPLETE`，而不冒充2 GiB crossing。|
| Guarded kill, reap and dead check | `run_representation_gate_003_watchdog.pl:187-206`, `:324-345`, `:656-702` | Normal group-kill helper有scalar negative-PGID guard、identity-verified positive cleanup、direct-child blocking reap及group/known-identity dead confirmation；但alarm failure branch存在§28.4 blocker。|
| Exact prospective outer command | `test/i4/femref-a1/README.md:130-159`，尤其`:155-158` | Frozen command为`/usr/bin/time -lp /usr/bin/perl ./run_representation_gate_003_watchdog.pl`；outer maximum RSS明确仅contextual，非aggregate authority。|

### 28.3 Preserved scientific/history boundary

Static call-graph and diff inspection show 003 changes are dispatch-local terminal/advisory/controller branches；representation
scientific calls、DP、row preparation、writer与schemas仍由上表既有helpers承担。`run_i4_1a.m:4300`的唯一`eigs`
call仍只在formal `LOCAL_low_spectrum` path；003 runner未调用它。Frozen scientific constants/counts仍见
`run_i4_1a.m:2116-2188`，formal one-input entry仍见`:76-90`。Watchdog source不含001/002 names、history paths或
`run-006`；MATLAB中的001/002 allowlist及dispatch-local historical semantics保留。Current filesystem中003 science
namespace、003 external leaf及`output/run-006`均不存在。

### 28.4 Controller blocker

**`BLOCKER` — SIGALRM guard/signal failure does not fail closed before blocking reap.** In
`run_representation_gate_003_watchdog.pl:187-205`，若immutable scalar guard失败，或negative group `kill`返回0且
errno不是`ESRCH`，handler只置`alarm_guard_failed=1`；guard-false branch至多kill direct child，signal-failure branch
没有positive cleanup。Main loop在`:220-224`看到该flag后直接`last`，没有调用`:656-672`的guarded helper或
`:674-684`的identity-verified positive cleanup，随后`:324-333`立即进入blocking `waitpid`。因此在exact operational
failure state中，live root/descendants可能继续运行且watchdog无限等待；这不满足§26.6的“guard failure立即positive
cleanup”与§27.1/§AP的1800 s fail-closed enforceability。它不是新增resource threshold，而是现有hard-limit controller
未完整实现。

Cheapest bounded repair是：在进入blocking reap前，alarm guard/signal failure path必须先对所有可identity-verify的
known live PIDs及safe direct child完成positive `SIGKILL`，记录`WATCHDOG_OPERATIONAL_INCOMPLETE /
KILL_GUARD_FAILED`，并继续既定dead confirmation；不得等待仍live target自行退出。修复不得改变deadline、2 GiB
predicate、scientific code或schemas。Researcher不在本节代改source。

另有一个较弱的implementation caveat：`EXEC_GO`后、`science_consumed=1`前的parent-side confirmation exception
在`:347-380`仍按prelaunch分支仅kill direct child；若fixed exec其实已发生但confirmation I/O/PGID recheck失败，
dedicated group descendants的cleanup不完整。Same Engineer可与上述fail-closed repair一并限定处理，仍保持“clean
confirmation前不消费science ID”的冻结语义。

### 28.5 Checks and Researcher decision

- `/usr/bin/perl -c test/i4/femref-a1/run_representation_gate_003_watchdog.pl`返回
  `syntax OK`；仅有host locale从unsupported `C.UTF-8`回落到`C`的warning，不是syntax failure。
- `git diff --check`通过。
- 003 science/external namespaces及`output/run-006`均不存在。
- 没有运行watchdog、MATLAB、Octave、Python或numerical computation。

**Researcher decision: `REVISE / RETURN BOUNDED CONTROLLER CLEANUP TO SAME ENGINEER / EXECUTION AND SAME-SKEPTIC SPEC-TO-CODE VERDICT REMAIN BLOCKED`.**

## 29. 2026-08-29 theory-to-code delta mapping after §28 bounded fix

Status: **`§28 BLOCKER CLOSED IN SOURCE / SAME-SKEPTIC SPEC-TO-CODE REVIEW REQUIRED / NOT RUN`**.

本节只映射§28指出的cleanup/reap delta；§28其余MATLAB、RSS、deadline、schema与claim-boundary mapping不重述。

1. **Release boundary and released-unconfirmed cleanup — mapped.**
   `test/i4/femref-a1/run_representation_gate_003_watchdog.pl:171-177`只在exact `EXEC_GO`完整write成功后置
   `release_sent=1`；partial/failed write不误标released。Parent-side exception在`:357-379`以
   `!science_consumed && release_sent && dedicated_pgid_was_verified`精确识别released-unconfirmed target，保持science
   ID未消费，同时调用既有guarded group/known cleanup，而不再落入仅direct-child的unreleased prelaunch branch。
2. **SIGALRM guard/signal failure — mapped.** Handler在`:190-208`把negative-group guard或signal failure置
   `alarm_guard_failed`；guard-false时还立即尝试exact positive child cleanup。Main loop在`:222-233`将该flag固定分类
   为`WATCHDOG_OPERATIONAL_INCOMPLETE / KILL_GUARD_FAILED`，在任何reap前调用`:683-702`的guarded cleanup；若group
   signal仍失败，该helper先调用safe positive cleanup再raise，不再直接进入blocking wait。
3. **Identity-safe positive cleanup — mapped.** `:704-730`只对current table中与known
   `(pid,start_identity)`一致且live的PID发positive `SIGKILL`，然后单独处理exact direct child。PID reuse entries不会被
   signal；direct-child kill只有accepted count或`ESRCH`才置`child_blocking_reap_safe=1`。
4. **No-hang reap and dead confirmation — mapped.** `:500-522`的reap helper只有child already reaped或上述exact
   positive child kill accepted/`ESRCH`时使用blocking `waitpid(...,0)`；否则只用`WNOHANG`并返回unconfirmed。Normal
   terminal path在`:334-350`、exception path在`:389-405`都把unconfirmed reap/dead check降为operational incomplete，
   不等待live target自行结束。`:732-747`仍要求dedicated group、identity-verified known targets及group-existence probe
   全部dead后才设置target-dead confirmation。
5. **Resource predicates unchanged.** Watchdog source`:27-32`, `:171-219`, `:312-318`仍只有absolute 1800 s
   deadline与aggregate 2147483648-byte inclusive uppers；1 s sample interval仅观察。Latest `SYMBOLS.md:202,209`登记
   `release_sent`及`child_blocking_reap_safe`的同一语义，没有引入120 s、1 GiB、1.5 GiB或其他execution stop。

Static caveat：当SIGALRM negative-group signal返回operational failure时，identity-table cleanup在Perl恢复至main-loop
control point后执行，而不是在signal handler中遍历mutable known inventory；这是为避免signal handler读取stale PID
table。它不再导致blocking reap，且terminal不会声称wall/RSS controller成功，因此不构成§28 blocker；same Skeptic
仍应审查这一failure-latency/Perl safe-signal边界。

Checks：`/usr/bin/perl -c test/i4/femref-a1/run_representation_gate_003_watchdog.pl`返回`syntax OK`（host locale
fallback warning不影响syntax）；`git diff --check`通过；003 science namespace、003 external leaf及`output/run-006`
均不存在。没有运行watchdog、MATLAB、Octave、Python或numerical computation。

**Researcher decision: `GO TO SAME SKEPTIC SPEC-TO-CODE REVIEW / IMPLEMENTATION PRESERVED / EXECUTION REMAINS BLOCKED PENDING THAT VERDICT`.**

## 30. 2026-08-29 kill-before-log and early-reap delta mapping after review §AQ

Status: **`§AQ SOURCE-ORDERING BLOCKER CLOSED / SAME-SKEPTIC FOCUSED RE-REVIEW REQUIRED / NOT RUN`**.

本节只审计§AQ source-only delta；§§28--29其余mapping保持有效。

1. **Process-table failure:** `test/i4/femref-a1/run_representation_gate_003_watchdog.pl:269-275`先在memory中冻结
   `WATCHDOG_OPERATIONAL_INCOMPLETE / RSS_AUTHORITY_LOST`及stop timestamp，再调用guarded group/positive cleanup，
   最后才尝试`OPERATIONAL_INTEGRITY_KILL` row write/flush。
2. **Authoritative-sample/PGID failure:** source`:293-299`先冻结exact authority error（包括
   `TARGET_LEFT_DEDICATED_PGID`），再以current authoritative table kill/positive cleanup，最后写unavailable row；
   log sink不能再延迟live-target termination。
3. **RSS crossing:** source`:317-323`只在authoritative aggregate满足inclusive 2147483648-byte predicate后冻结
   `RSS_HARD_LIMIT_KILLED / RSS_HARD_LIMIT_REACHED`，先kill/positive cleanup，再写包含frozen aggregate的threshold
   row。`LOCAL_record_sample`的sidecar与stdout write+flush仍在`:755-774`且schema不变。
4. **Post-kill publication truthfulness:** 任一required row write/flush failure会进入`:359-407` exception cleanup并把
   final status降为`WATCHDOG_OPERATIONAL_INCOMPLETE`；samples close/atomic rename failure在`:414-423`同样降级，
   summary publication failure在`:447-454`以operational-incomplete stderr事实记录。因此只有threshold row向两个
   required sinks成功发布、reap/dead confirmation成功且samples/summary finalization成功的branch保留
   `RSS_HARD_LIMIT_KILLED`；partial or failed logging不冒充complete RSS terminal。
5. **Early exact reap bookkeeping:** source`:183-190`在early `waitpid(...,WNOHANG)`返回exact child PID时，先保存
   `child_reaped=1`与exact `$?`，再进入原pre-confirmation fail-closed branch；后续reap helper不会重复丢失status。
6. **No contract expansion:** fixed 11/18-column headers仍见`:100-110`；唯一resource uppers仍是`:27-28`的1800 s与
   2147483648 bytes，`:29`的1 s cadence仍只观察。没有新threshold、schema field、retry、ID、namespace或`run-006`
   authority。

Checks：`/usr/bin/perl -c test/i4/femref-a1/run_representation_gate_003_watchdog.pl`返回`syntax OK`（仅host locale
fallback warning）；`git diff --check`通过；003 science namespace、003 external leaf及`output/run-006`均不存在。
没有运行watchdog、MATLAB、Octave、Python或numerical computation。

**Researcher decision: `GO TO SAME SKEPTIC FOCUSED RE-REVIEW / EXECUTION REMAINS BLOCKED PENDING THAT VERDICT`.**

## 31. 2026-08-30 `run-006` core formal path revision

Status: **`PROSPECTIVE CORE-PATH DESIGN / NOT IMPLEMENTED / NOT RUN`**.

本节响应用户在003完成并提交后的新明确授权，只把同一M1 fitted-FEM方法、同一`femref-a1` attempt的下一次formal
execution限定为`run-006` core path。它前瞻性取代旧formal runtime中的资源门和非数学审计负担，但不删除或改写
`run-001`--`run-004`、`representation-gate-001`--`003`、§§1--30或既有review verdict；历史artifacts保持immutable，
`run-006`不得读取、复制或复用它们。只有同一Skeptic design review、Engineer bounded implementation、Researcher
theory-to-code mapping和同一Skeptic spec-to-code review依次通过后，才可启动一次formal command。本节本身不授权实现
或运行。

### 31.1 不变的科学合同

`run-006`仍求解[[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]]及其
[[research/projects/eig-apost/implementation/i4/method-review|method review]]通过的同一continuous problem：
$A=I$、$B=q$、$\beta=0.5$、半径$0.2$的sharp circular interfaces、缺失$x=0$材料柱、$\lambda=k^2$，以及同一
geometry-fitted conforming $P_1$ supercell weak form。以下对象全部冻结，不得借“精简”改变：

1. geometry、材料、quasiperiodic phases、频率归一化和现有bulk/defect mesh、supercell、twist、tolerance schedules；
2. $72$个bulk加$47$个defect的完整$119$-solve union、root counts、sentinels和full branch/cluster inventory；
3. safe-gap、coverage、subspace continuation、collapse、localization、tail、parity/common-core mode identification；
4. FEM、supercell、twist和algebraic四轴refinement，以及经验
   $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$的既有公式、门和“not an upper bound”语义；
5. information isolation：MATLAB只可读取source-owned parameters及本次`run-006`的current-run transient objects，
   不得读取Markdown、Git、历史output、BIE/QZ density/eigenvector、当前estimator或same-trial diagnostics；
6. claim boundary：最多形成finite empirical observed reference collection和经验resolution；不得称为certified
   continuous truth、error bound、existence result或effectivity validation，且必须在任何reveal/comparison前停止。

因此本轮是**同一FEM方法的runtime reduction**，不是新方法、放宽科学门、减少branch coverage或改变历史失败解释。

### 31.2 active core path的三类边界

Engineer必须以“是否直接产生或解释上述数学对象”为唯一删减准则。旧helper名称不是权威；实现可重写为更短的
local helpers，但下面A/B/C职责不可混用。

#### A. 必须保留的数学代码

| Core object | 最小保留内容 | 保留原因 |
|---|---|---|
| Fitted mesh | 生成冻结polygonal circle interfaces与supercell；检查finite coordinates、非退化正面积triangles、每个fitted interface constraint实际存在、每个element有唯一材料标签、periodic boundary node pairing和必要的reflection pairing | 这些条件直接决定$P_1$ space、sharp-interface material integral、quasiperiodic identification及parity解释；缺一项会改变或使离散问题不可解释。 |
| Assembly and phase reduction | 组装stiffness、weighted mass及center/core/tail mass forms；形成唯一消费用Hermitian reduced pair；检查finite entries、实际Hermitian defect、positive mass factorization和phase-seam residual | 这些是弱形式、eigs、归一化、residual与localization quotient的直接离散对象。允许一次数值Hermitian canonicalization，但不得为审计同时保存raw/canonical mirrors。 |
| Low spectra | 冻结的`eigs` calls、root ordering、normalization、finite/positive eigenvalue、solver completion、algebraic residual、orthogonality、root-count sentinel和cluster multiplicity | 它们直接决定完整finite spectral inventory；残量和有限性检查不得因精简删除。 |
| Bulk and defect inventories | frozen target-gap construction、所有$119$个计划solve的role/phase/root inventory及到达的合法早停gate | 主reference不能由“最接近当前$k_h$”的root替代，也不能省略branch coverage。 |
| Branch and mode identity | safe-gap filtering、basis-invariant cluster subspaces、continuation edges、all-object coverage、localization/core/tail、parity、common-core matching和twist/tail collapse | 这些是独立识别同一guided-mode family和排除未局域branch的科学规则。必要的reflection action/compatibility属于这里；与此无关的全图审计不属于这里。 |
| Resolution and reference | 四轴changes、collapse/total gates、qualified finite collection、anchor subspaces/fields及failure-state reached fields | 这些直接形成$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$、reference field和未来只读comparison所需对象。 |

“最小mesh合法性”不表示只检查数组维度：若constraint丢失、element跨越材料interface、triangle退化、periodic pairing
错误或parity所需reflection action不成立，continuous/discrete matching已被破坏，必须fail closed。反之，仅用于生成36列
mesh ledger的duplicate/global graph/Euler/incidence/component/nonincident-intersection inventories，若不改变上述判定，不得留在
active core path。

#### B. 必须从active runtime删除或旁路的非数学审计

下列代码不得在`run-006` call graph中执行，也不得为了复现已消费diagnostic而保留成active formal entry的dead branches：

1. `mesh-repair-*`、`mass-gate-*`、`representation-gate-*` dispatch，以及它们的mass/representation probes、padding、
   width sweeps、row-preparation、writer-rewrite benchmarks和forecast；
2. OP2/DRV2 36-column operator ledger、raw/canonical MAT/CSV mirrors、每个primary/derived object消费前的checkpoint/rewrite及
   `10414`-row/$261$-writer evidence contract；
3. `symbfact`/workspace/resource forecast、1 GiB或1.5 GiB internal screen、CV/spread/JIT/timer-resolution、stall和纯性能
   diagnostics；这些可作为既有003历史证据，但不再是formal correctness或execution stop；
4. exhaustive model/source hashes、repository/environment/cache/provenance inventories、重复dependency assertions、
   first-failure/schema mirrors及为相同scientific object反复重写完整CSV/MAT；
5. 与A类合法性或mode interpretation无直接关系的mesh graph、global intersection、reflection bookkeeping inventories和
   failure-marker expansion；不得仅因旧schema存在而继续计算；
6. 与最终scientific object无关的padding arrays、duplicate payloads、atomic-publication stress paths和历史diagnostic
   watchdog integration。

删除B类代码不允许删除A类有限性、Hermitian/mass、eigensolver residual、localization或coverage checks。Engineer必须在
implementation handoff列出每一条旧formal call edge是“保留为A”“缩为C”还是“不可达/删除为B”；不要求保存历史
diagnostic source可执行性，因为其已提交artifacts和§§22--30 ledger本身就是immutable history。

#### C. 仅保留的最小操作代码

1. exact `output/run-006/` create-once claim，且不得从其他output恢复、续算或调参；
2. MATLAB exception或controller enforcement failure立即停止，写一条简短terminal record，不把operational failure伪装成
   scientific negative；
3. 一个外部resource controller，覆盖完整formal command及其MATLAB process tree，只执行§31.4的$45$ min/$2$ GiB
   hard stops；
4. 简短append-only stage/solve progress、aggregate RSS observation和one-row terminal summary。Sampling interval只服务于
   RSS enforcement和记录，不是额外的cadence pass/fail gate；不得因output stall、CV、spread或forecast停止；
5. 若控制实际aggregate RSS所需的process-tree authority丢失，必须停止并报告
   `OPERATIONAL_RESOURCE_CONTROL_UNAVAILABLE`；这是无法执行已授权$2$ GiB hard limit的operational failure，不是第三个
   resource threshold，也不得声称内存达到$2$ GiB。

### 31.3 最小输出集合

`run-006`只允许一个canonical scientific representation，避免同一对象的schema mirror。Engineer可给文件采用更短名称，
但在spec-to-code review前必须一次性冻结到以下职责，正式运行后不得改名或加第二套镜像：

1. `scientific-result.mat`：冻结spec、最小mesh descriptors、bulk gap/bands、全部defect spectra、branch edges/inventory、
   coverage、四轴resolution、qualified reference collection和到达的field/subspace objects的唯一canonical container；
2. `fields.mat`：仅在确有reached anchor fields时保存mesh、material labels、anchor subspaces/simple-mode representatives和
   qualification status；它不单独提升reference资格；
3. `run-summary.csv`：一行记录`run_id`、scientific terminal、completed/planned solves、collection size、first direct failure、
   empirical claim boundary、whole-command elapsed和observed aggregate peak RSS；
4. `run.log`：只追加stage start、solve count和terminal exception，不保存全对象dump；
5. `resource.tsv`：controller为实际$2$ GiB enforcement留下的最小elapsed/aggregate-RSS ledger。

为控制内存而生成的current-run spectrum/mesh transient cache属于A类内部工作对象，可以位于`output/run-006/work/`，但不是
authoritative artifact，不得读取历史run，也不得为它建立hash/schema/provenance镜像。科学terminal时以
`scientific-result.mat`为唯一解释入口；operational/resource interruption可以只有reached log/summary，不得伪造完整
scientific container。

### 31.4 唯一资源合同与基于现有证据的估计

用户本轮把一个完整`run-006` command的hard budget明确改为：

$$
T_{\mathrm{hard}}=2700\ \mathrm{s},\qquad
R_{\mathrm{hard}}=2147483648\ \mathrm{bytes}.
$$

同一controller、MATLAB、所有subprocess、mesh/solve/postprocess和必要publication共享同一wall clock；不得拆分重置，
没有grace。Elapsed达到或超过$2700$ s，或authoritative aggregate MATLAB-process-tree RSS达到或超过
$2147483648$ bytes时，controller必须立即停止target并给出相应resource terminal。不存在30/40 min、120/1800 s、
1/1.5 GiB、forecast、stall、CV、spread或cadence的lower execution gate。Controller launch/setup必须最小；hard stop后的
reap和terminal record不是继续科学计算或grace，outer command若超过$2700$ s仍须如实归类wall hard-limit exceeded。

现有003工件提供以下**规划证据而非新benchmark**：

- `representation-forecast.csv`把current audited formal forecast分解为$1788$ s scientific baseline和
  $883.67067570833342$ s representation/audit additive，其中writer rewrite单项为
  $674.58177570833345$ s；总计$2671.6706757083334$ s只是带timing variability的advisory；
- 同一文件的baseline peak为$1288490188.8$ bytes，representation-only incremental arrays为$222587516$ bytes，
  合计forecast $1511077704.8$ bytes；
- external watchdog实测003 aggregate peak为$1296187392$ bytes，target-active time为$761.486755$ s，但003完成$0$次
  scientific eigensolve，故它不能单独证明formal runtime。

B类删减正好移除上述$883.67$ s附加量的representation probes、rows和rewrites，而不是减少$119$个scientific solves。
因此删减后的best current planning point为原scientific baseline约$1788$ s（$29.8$ min）加最小controller/log overhead；
内存planning range由约$1.20$ GiB baseline到含旧incremental evidence的$1.4073$ GiB，均低于$2$ GiB。该推断标为
**`CONDITIONAL`**：它不是wall/RSS upper bound，也没有测量$119$个eigensolves；尤其003记录的timing variability禁止把
$1788$ s写成保证。尽管如此，去除有实证分解的$883.67$ s非数学负担后，相对$2700$ s获得约$912$ s设计余量，且现有
aggregate/forecast memory均距$2$ GiB有明确余量，所以当前没有resource `blocker`。Skeptic必须检查Engineer确已让B类
call paths不可达；若仍保留大规模rewrite/probe，则该估计失效并须`REVISE`，不得运行。

### 31.5 formal command、attempt与retry语义

Engineer可为core MATLAB entry和minimal controller各选一次短文件名，但必须满足：controller无scientific CLI参数，内部
literal绑定`run-006`、唯一core entry、$2700$ s和$2147483648$ bytes；Researcher theory-to-code mapping与同一Skeptic
spec-to-code review必须记录并冻结**一个exact no-argument shell command**，之后不得存在备用launcher或手工多阶段命令。
任何static check只能检查syntax/call graph，正式命令之前不得用缩小workload、benchmark或hidden probe运行MATLAB。

`run-006`是同一attempt内一个create-once scientific identity。只有dependency、path、syntax、schema或controller等真实
operational failure才可按`test/AGENTS.md`在同一`femref-a1`和同一`run-006` root内有界修复；失败log必须保留，corrected
execution使用append-only execution label，不覆盖已存在文件，也不新建attempt。任一到达的科学gate、完整method failure、
wall hard limit或RSS hard limit都消费`run-006`，不得以“重试”更改mesh、threshold、solver或科学schedule。

### 31.6 terminal与验收标准

`run-006`只有以下合法terminal classes：

1. `REFERENCE_COLLECTION_READY`：若流程到达defect stage，全部$119$个solve完成；bulk gap、root sentinels、full
   coverage、branch/mode identification、collapse和四轴resolution均通过；canonical collection及reached fields完整，
   同时仍只具有finite empirical claim；
2. **valid scientific negative**：某个A类预注册数学门首先失败，例如bulk gap、spectrum completeness/residual、coverage、
   localization/tail/twist、mode continuation或reference resolution unresolved；只保存到达对象和exact direct reason，
   不要求为了凑满$119$ solves越过已失败的先决门，也不得由B类schema/audit失败触发；
3. **operational failure**：source/dependency/path/controller/publication错误；不消费method conclusion，仅在符合§31.5时允许
   同attempt有界修复；
4. **resource failure**：whole-command wall或aggregate RSS触及唯一hard upper；保存observed terminal并停止，不得给
   scientific/reference结论。

验收还要求：科学call graph只含A+C；`run-006` namespace在formal launch前不存在；历史diagnostic/output未被读取或修改；
没有BIE/QZ/estimator reveal；没有effectivity comparison；没有新增attempt、设计或隐藏pre-run computation。Important或
minor caveat只限制解释，不能阻止本阶段；只有直接破坏同一数学问题、完整branch/reference解释或$45$ min/$2$ GiB
hard-budget enforcement的unresolved issue才是`blocker`。

### 31.7 Researcher design decision

基于003保存的forecast decomposition、aggregate RSS evidence和current formal call graph，核心$119$-solve数学工作在删除
representation/audit rewrites后具有低于新预算的有依据规划估计；当前未发现必须改科学方法才能执行的blocker。最小下一门
是同一Skeptic独立检查本节的A/B/C边界、资源推断、输出集合和valid-negative语义；通过后才交Engineer实现。

**Researcher decision: `GO TO SAME SKEPTIC DESIGN REVIEW / IMPLEMENTATION AND RUN-006 EXECUTION REMAIN BLOCKED`.**

## 32. 2026-08-30 theory-to-code review of the core formal implementation

Status: **`MATHEMATICAL MAPPING PASS / ONE WHOLE-COMMAND CLOCK BLOCKER / NOT RUN`**.

本节只审查current Engineer source diff；不修改MATLAB/Perl、README、SYMBOLS、review或artifacts，也不执行numerical
program。Line locators均指本次审查时的current source。

### 32.1 Frozen mathematics and core call graph

| §31 object | Current source mapping | Researcher finding |
|---|---|---|
| Exact entry/spec | `test/i4/femref-a1/run_i4_1a.m:1-34,135-195` | 只接受literal `run-006`；$q_{\mathrm{in}}=17$、$q_{\mathrm{out}}=1$、radius $0.2$、missing column $0$、$\beta=0.5$、cue/guard windows、phase grids、root counts、solver tolerances和scientific thresholds不变。删去的spec字段只属resource/provenance/operator-ledger。 |
| Mesh/schedules | `run_i4_1a.m:304-811,1031-1196` | 九张$s/n_\gamma/N$ meshes不变；bulk $17+17+33+5=72$，defect $5+5+17+5+5+5+5=47$。Bulk tolerances $10^{-9},10^{-10},10^{-11}$及defect $10^{-11}/10^{-8}$不变。Mesh保留finite connectivity、reflection-compatible constraints、positive/nonduplicate triangles、interface constraints、cross-interface/material、assembly finite、reflection、periodic及finest-geometry gates；wide graph/intersection ledger已删除。 |
| Operators/eigs | `run_i4_1a.m:691-1009` | $P_1$ stiffness、weighted mass、center/core/tail forms不变。Raw Hermitian defect在roundoff canonicalization前检查；mass diagonal/`chol` SPD、seam、finite/positive roots、normalization、residual、orthogonality、ordering、sentinels及multiplicity均保留。 |
| Branch/coverage/mode | `run_i4_1a.m:1236-1858` | 全raw-gap clusters进入restricted Grams、parity、common-core、twist continuation、cross-configuration matching、all-object coverage、localization、tail/twist collapse和ambiguity flag；无nearest-$k_h$ selection或current-chain input。 |
| Four-axis resolution | `run_i4_1a.m:1860-1993` | FEM、supercell、twist、algebraic changes及原collapse/total gates逐式保留；uncertainty仍标记`EMPIRICAL_SENSITIVITY_ENVELOPE_NOT_AN_UPPER_BOUND`。 |
| Canonical output | `run_i4_1a.m:1998-2104` | `scientific-result.mat`唯一保存spec、mesh descriptors、compact bulk/defect/branch、coverage及resolution/collection；`fields.mat`只保存reached subspaces和mesh/material，并明确非effectivity。 |

Static token audit得到**67个unique `LOCAL_*` tokens、67个definitions、0 undefined**。Formal source现为2104 lines；
executable call graph中不存在diagnostic dispatch、OP2/DRV2、mass/representation probes、padding、10414-row/261-writer
rewrite、forecast/preflight、1/1.5 GiB screen、CV/spread/stall、hash/digest、Git/history或BIE/QZ/estimator input。相关词只在
说明deleted paths的header comments中出现。

### 32.2 Terminals, runner and exact command

`run_i4_1a.m:67-130`只在all $119$ solves、coverage、nonempty qualified branch及four-axis resolution全部通过后设置
`SCIENTIFIC_READY / REFERENCE_COLLECTION_READY`；直接数学门进入`SCIENTIFIC_NEGATIVE`，unknown/dependency/
publication exception保持`OPERATIONAL_FAILURE`并rethrow。MATLAB只写`scientific-result.mat`、conditional
`fields.mat`、append-only `run.log`和current-run `work/`。

`run_formal.pl:9-35`固定no arguments、literal `run-006`、exact `run_i4_1a('run-006')`和create-once output claim。
`:118-160`用full `ps` table形成recursive-descendant与dedicated-PGID union并按PID key去重RSS；authority丢失走
operational stop。`:218-245`最后发布`run-summary.csv`，controller非natural exit时不保留READY。

Post-run leaves冻结为`output/run-006/scientific-result.mat`、conditional `fields.mat`、`run.log`、
`resource.tsv`、最后发布的`run-summary.csv`及非权威current-run `work/`。Formal command冻结为在working directory
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`执行：

```text
/usr/bin/perl ./run_formal.pl
```

本节因下述blocker不授权该命令。

### 32.3 Resource-controller blocker

**`BLOCKER — WHOLE-COMMAND WALL CLOCK IS SAMPLED BEFORE REQUIRED FINAL PUBLICATION`.**
`run_formal.pl:16`正确在setup前建立monotonic start，且`:12-13,67-75`只有$2700$ s与$2147483648$ bytes两个
inclusive resource uppers；1 s sleep只采样，无lower gate、stall、CV、spread或forecast stop。RSS mapping通过。

Wall side仍有一个精确缺口：

1. `:44-46`先冻结`$now/$elapsed`再运行external `ps`，`:67`比较的仍是pre-`ps` stale elapsed；
2. child reap后`:103`只计算一次elapsed，随后`:111-115`才写`resource.tsv`、读取terminal draft并发布最终
   `run-summary.csv`；required publication没有fresh deadline comparison，且名为`whole_command_elapsed_seconds`的值
   排除了这些finalization steps；
3. 因而deadline附近的natural exit可在$2700$ s后仍发布`NATURAL_EXIT / SCIENTIFIC_READY`并exit 0，违反§31.4
   setup、target、postprocess和必要publication共享一个wall clock且无grace的合同。这不是style caveat。

最小修复不得引入早于$2700$ s的reserve或第三threshold：只从现有`$start`形成一个immutable absolute deadline；在
`ps`返回后、reap后及每个required final-publication boundary前用fresh monotonic time比较同一deadline；任何
$T\ge2700$ s都必须降为`WALL_HARD_LIMIT_REACHED / RESOURCE_FAILURE`，不得发布或保留success summary。Final summary
elapsed必须取其publication boundary而非line 103的prepublication snapshot。Engineer应采用最短等价实现，不得恢复003的
复杂alarm/identity/logging machinery。

### 32.4 Over-defence and checks

245-line runner的fork/PGID、recursive RSS dedupe、kill/reap、terminal-draft bridge、CSV escaping和minimal terminal
records都直接服务create-once、resource enforcement或claim boundary。Unused process `state`等可删但不构成blocker；
不得因style扩大controller。当前唯一需修复的是§32.3。

- `/usr/bin/perl -c test/i4/femref-a1/run_formal.pl`返回`syntax OK`（仅host locale fallback warning）；
- `git diff --check`通过；
- `output/run-006/`不存在；Git diff未列出任何001--003或`run-001`--`run-005` artifact；
- 没有运行MATLAB、Octave、Python、Perl runner或numerical computation。

**Researcher decision: `REVISE / RETURN THE §32.3 CLOCK-BOUNDARY FIX TO THE SAME ENGINEER / RUN-006 AND SAME-SKEPTIC SPEC-TO-CODE VERDICT REMAIN BLOCKED`.**

## 33. 2026-08-30 controller deadline-fix delta review

Status: **`DEADLINE PREDICATE MAPPED / REPEATED FINAL-PUBLICATION BLOCKER / NOT RUN`**.

本节只审查§32返回后的current `run_formal.pl`；§32.1--32.2的MATLAB mathematics、call graph、outputs及exact command
mapping不重开。

### 33.1 Closed §32 clock points

1. `run_formal.pl:16-17`现在只形成一个immutable
   `deadline = start + 2700`；source没有reserve、grace、fresh 2700 s rearm或第三resource threshold。
2. `:45-50`先完成process-table acquisition，再在消费table/RSS前用fresh monotonic time作inclusive deadline check；
   `:77-92`在nonblocking reap后再检查同一deadline，故§32指出的pre-`ps` stale comparison已关闭。
3. `:100-119`在blocking reap后、读取MATLAB terminal draft前后均检查同一deadline；`:158-164`唯一predicate是
   `now >= absolute_deadline`。一旦成立，`controller_terminal`不能恢复为`NATURAL_EXIT`。
4. `:266-275`在任何non-natural controller terminal下把draft降为`RESOURCE_FAILURE`或
   `OPERATIONAL_FAILURE`，不会把§32之后观察到的wall crossing保留成READY。
5. RSS仍只有`aggregate >= 2147483648`；1 s sleep只采样。没有1/1.5 GiB、30/40 min、120/1800 s、stall、CV、
   spread、forecast或cadence pass/fail gate。

因此§32的deadline identity、post-`ps`/post-reap fresh checks和success downgrade原则已在source中出现。

### 33.2 Bounded over-defence blocker

**`BLOCKER — CORRECTED TERMINALS ARE REPUBLISHED THROUGH MULTIPLE OVERWRITES`.** Finalization
`run_formal.pl:121-155`不是single final decision：

- `resource.tsv`先在`:123-124`写一次，deadline变化时可在`:128-129`写第二次，又可在`:136-137`写第三次；
- `run-summary.csv`先在`:141-142`写一次，post-write crossing时再在`:152-153`写第二次；
- 第一次summary以后，`:145-149`还可能先重写resource。若这次open/close/rename失败，filesystem留下的是旧summary和
  新旧不一致的resource，且承诺的“summary-last”尚未恢复；
- 每个rewrite都重新创建同名`.partial`并rename覆盖已有complete leaf。它不增加数学证据或resource authority，却在
  已有terminal之后增加I/O、collision/rename failure points和claim-conflict paths。

这不是line count或style问题，而是用户明确禁止的非数学重复publication直接扩大formal failure surface。293 LOC中的
fork/PGID、RSS union、kill/reap、draft parsing和CSV escaping仍有C-path职责；需删减的仅是`:121-155`的correct-and-
rewrite loop。

最小修复是**single final decision, one resource write, summary last**：完成target death/reap和一次draft read后，对同一
absolute deadline作一个fresh inclusive final check并冻结controller terminal/elapsed；随后恰好一次发布
`resource.tsv`，再恰好一次最后发布`run-summary.csv`，不得在summary后重写resource，也不得二次发布summary。若实现
需要把serialization preparation放在final decision前，可先准备non-authoritative temporary content，再以冻结terminal作
一次final publication；不得增加lower deadline、reserve、第二计时器或003式publication protocol。Publication异常仍作为
普通operational failure，不通过rewrite修复。

### 33.3 Checks and Researcher decision

- `/usr/bin/perl -c test/i4/femref-a1/run_formal.pl`返回`syntax OK`（仅host locale fallback warning）；
- `git diff --check`通过；
- `output/run-006/`不存在；没有执行Perl runner、MATLAB、Octave、Python或numerical computation。

Exact prospective command仍是在
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`运行
`/usr/bin/perl ./run_formal.pl`，但本节不授权执行。

**Researcher decision: `REVISE / RETURN THE §33.2 SINGLE-PUBLICATION SIMPLIFICATION TO THE SAME ENGINEER / RUN-006 AND SAME-SKEPTIC SPEC-TO-CODE VERDICT REMAIN BLOCKED`.**

## 34. 2026-08-30 single-publication controller delta map

Status: **`§33 BLOCKER CLOSED / STATIC THEORY-TO-CODE PASS / NOT RUN`**.

本节只复核§33.2的bounded source delta；§32的MATLAB mathematics、67/67 call graph、minimal outputs和exact command
mapping继续有效。

1. **One draft read.** `test/i4/femref-a1/run_formal.pl:115`只调用一次
   `read_terminal_draft`；其唯一helper definition在`:200-223`，finalization不存在第二次read或history fallback。
2. **One fresh final decision.** `:116-118`在draft read之后对§33已核验的同一immutable
   `deadline = start + 2700`作一次fresh inclusive check，随后把`final_terminal`和`final_elapsed`冻结。该值之后不再
   reclassify、rearm或进入correct-and-rewrite loop。
3. **Exactly one resource write.** `:119-120`只有一个`write_resource` call；source-wide search除`:186`的helper
   definition外没有第二个caller。`resource.tsv`因此只形成一次complete publication。
4. **Exactly one summary-last.** `:121-122`只有一个`write_summary` call，紧随resource且是exit前最后一个publication；
   source-wide search除`:233`的helper definition外没有第二个caller。不存在summary后的resource rewrite或第二个
   summary。
5. **Hard limits unchanged.** `:12-17,44-98,125-130`仍只有absolute $2700$ s inclusive deadline；
   `:13,65-74`仍只有aggregate $2147483648$-byte inclusive RSS stop。1 s sleep只采样；没有reserve、grace、lower
   wall/RSS、stall、CV、spread、forecast、cadence gate或第三timer。
6. **Failure truthfulness.** Final deadline crossing在freeze前把terminal置为`WALL_HARD_LIMIT_REACHED`；
   `write_summary:233-242`把wall/RSS crossing降为`RESOURCE_FAILURE`，其他non-natural controller result降为
   `OPERATIONAL_FAILURE`，所以finalization不能保留`NATURAL_EXIT / READY`。Publication exception本身直接使runner
   nonzero，不通过重复写入“修复”。

Current runner已由293 lines降至260 lines；剩余fork/PGID、RSS union、kill/reap、draft parser、CSV escaping和single
publication分别直接服务create-once/resource/claim-boundary C-path。Unused `ps state` field是minor style simplification，
没有可改变预算或下一计算的故障面，不构成blocker，也不应再次扩展controller。

Checks：

- `/usr/bin/perl -c test/i4/femref-a1/run_formal.pl`返回`syntax OK`（仅host locale fallback warning）；
- `git diff --check`通过；
- `output/run-006/`不存在；
- 没有运行Perl controller、MATLAB、Octave、Python或numerical computation。

Exact command仍冻结为在
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`执行
`/usr/bin/perl ./run_formal.pl`。本节只移交review，不自行授权formal execution。

**Researcher decision: `GO TO SAME SKEPTIC SPEC-TO-CODE REVIEW / IMPLEMENTATION MAPPING PASSES / RUN-006 EXECUTION REMAINS BLOCKED PENDING THAT VERDICT`.**

## 35. 2026-08-30 §AU bounded implementation delta map

Status: **`STATIC THEORY-TO-CODE PASS / NOT RUN`**.

本节只复核 review §AU 返回的两个 blocker；§31--34 已冻结的 continuous model、fitted-$P_1$ weak form、完整
branch/coverage/refinement/empirical-uncertainty 合同和 single-publication C-path 不重开。

1. **Reached scientific state survives a scientific-negative stage exit.**
   `test/i4/femref-a1/run_i4_1a.m:72-81` 现在先从 bulk/defect stage 接收 inventory、`run_state` 和
   `stage_failure`，再由 top level raise；因此 `:112-124` 的唯一 canonical-negative save 看到的是本次调用已返回的
   state，而不是调用前的空变量。Bulk path 在每个 main solve 的 current-run cache 成功后，于 `:1074-1079` 写入
   frequencies/residuals/path、`completed_phases` 和 count；count sentinel 在 `:1134-1137` 先写 entry/count，再执行
   mismatch gate；target-gap exception 被 `:1098-1111` 转为 failure return，且 refinement failure 前已在
   `:1184-1189` 写入 triggering gap object。Defect path 在每个 spectrum cache 后，于 `:1228-1234` 先形成 summary、
   entry、inventory 和 count，再执行 `:1244-1251` raw-edge-buffer gate及 `:1253-1280` count-sentinel gate。
   所有这些 preregistered scientific failures 都以 failure object 正常返回，top-level canonical artifact 因而保留全部
   已成功到达的 bulk/defect spectra、cache references、counts、entries 和直接 triggering object。Operational I/O/code
   exception 仍按 operational failure fail closed；本修复没有把它伪装成 scientific negative。
2. **READY science is unchanged.** `:141-200` 的模型、参数、phase grids、tolerances和 $72+47=119$ counts未变；
   bulk loops仍是 $17+17+33+5=72$，`LOCAL_defect_schedule:322-339` 仍是
   $5+5+17+5+5+5+5=47$。`REFERENCE_COLLECTION_READY` 仍只可能在 `:83-111` 的完整119-solve、coverage、nonempty
   collection和resolution gates之后形成。Mesh/assembly/phase reduction/eigs、branch identity、四轴resolution及
   $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 的 empirical/non-certified claim boundary没有进入本次source delta。
3. **The same absolute deadline remains live through summary-last and exit.**
   `test/i4/femref-a1/run_formal.pl:7,12-25` 只为既有
   `deadline = start + 2700` 增加一个 one-shot high-resolution alarm，arm value是该同一deadline减去当前monotonic
   time；source没有cancel、reset或第二次arm。它因此贯穿 MATLAB supervision、draft read、唯一resource write、
   summary-last和随后的exit。Handler只对target发出kill、向stderr写明 wall terminal并 `_exit(2)`；它不调用
   `write_resource`/`write_summary`，也不发布、修正或覆盖任何artifact。Loop和final fresh checks仍比较同一absolute
   deadline，alarm只关闭blocking/publication boundary上的zero-exit窗口，不构成第二threshold、reserve、grace或低门。
4. **RSS and deleted B paths remain unchanged.** 唯一memory predicate仍是 `run_formal.pl:79`
   的 aggregate RSS `>= 2147483648` bytes。Static searches未发现重新引入 representation dispatch、OP2/DRV2、
   mirror、checkpoint/rewrite、history/hash/provenance、preflight/forecast、stall/CV/spread或lower wall/RSS gate；源码中
   剩余 `diagnostic` 名称仅标识 reflection、phase/seam和common-core等直接数学量。

Checks：

- `/usr/bin/perl -c test/i4/femref-a1/run_formal.pl` 返回 `syntax OK`（仅host locale fallback warning）；
- `git diff --check` 通过；
- `output/run-006/` 不存在；
- 未运行 Perl controller、MATLAB、Octave、Python、benchmark、diagnostic 或 numerical computation。

**Researcher decision: `PASS / GO TO THE SAME SKEPTIC FOR THE §AU FOCUSED SOURCE RE-REVIEW / RUN-006 EXECUTION REMAINS NOT AUTHORIZED`.**

### 35.1 Evidence-location precision

对§35(1)作append-only措辞精确化：current-run cache files及其stage-local path references在failure gate之前已经形成并
留在`work/`，但`LOCAL_compact_bulk:2114-2131`和`LOCAL_compact_defect:2133-2141`有意从canonical payload删除
cache paths。`scientific-result.mat`保留的是bulk frequencies/residuals/sentinel summaries、defect spectrum summaries、
counts/entries和triggering gap/gate object，而不是第二份cache-path mirror；这正是single scientific authority边界。

## 36. 2026-08-31 `run-007` diagnostic-ranking reference revision

Status: **`PROSPECTIVE CORE REVISION FROZEN / SAME FEM METHOD AND SAME femref-a1 ATTEMPT / NOT IMPLEMENTED / NOT RUN`**.

本节由新的明确授权触发，append-only supersede §§1--35 中把 gap、coverage、localization、parity、collapse 或
refinement quality threshold 当作 candidate-cancelling hard gate 的部分；历史 `run-001`--`run-006`、其 verdict 和
artifacts 全部保持原义。该修订不是 M2/RtR、PML、BIE 或另一 continuous method；它仍是同一 geometry-fitted
conforming $P_1$ FEM supercell method，只把经验 qualification thresholds 改为 candidate classification/ranking
evidence。它不授权本节内 implementation 或 execution。

### 36.1 Immutable scientific and operational boundary

下列对象完全不变：$Omega=\mathbb R\times(-1/2,1/2)$、period $1$、sharp disk radius $0.2$、
$q_{\mathrm{in}}=17$、$q_{\mathrm{out}}=1$、missing column $0$、$\beta=0.5$、
$u(x,y+1)=e^{\mathrm i\beta}u(x,y)$、supercell twist、$A=I$、$B=q$、
$\lambda=k^2$ 以及

$$
\int \nabla u\cdot\nabla\overline v
=\lambda\int q u\overline v.
$$

Geometry-fitted $P_1$ assembly、material assignment、quasiperiodic reduction 和 mass normalization 不变。Active
MATLAB source仍不得读取 Markdown、Git、BIE/QZ density/eigenvector、I3 estimator、same-trial diagnostic、
$\widehat k_h$、`run-001`--`run-006` 或任何 historical/reference output；本轮 search、tracking、ranking、window
extension 和 stopping 只能消费 current-run FEM matrices/eigenpairs/fields及上述 physical specification。揭盲和
effectivity comparison 均不在本节授权内。

Whole-command resource hard uppers仍且仅为

$$
T_{\mathrm{hard}}=2700\ \mathrm{s},
\qquad
R_{\mathrm{hard}}=2147483648\ \mathrm{bytes},
$$

由同一 non-resetting controller 计量；无 lower wall/RSS gate、reserve、grace、forecast、stall、CV、spread 或
cadence pass/fail predicate。

`test/i4/femref-a1/output/run-001`--`run-006` 均已存在而 `output/run-007` 当前不存在，故本节冻结同一
`femref-a1` attempt 的新 exact create-once identity **`run-007`**。不得覆盖、读取或复用旧 run artifacts；launch
confirmed 后 complete/incomplete 均消费 `run-007`。若 implementation 前发现该 root 已出现，必须停止并回到
Researcher--Skeptic gate；不得自行改成另一 ID。

### 36.2 Heuristic gates are diagnostics, not cancellation rules

以下数值和定义保留，便于与历史及跨轴结果解释一致，但一律只产生 diagnostic/caveat/classification，不能停止
spectrum、field、branch、refinement、ranking 或 top-candidate publication：

- initial cue $I_{\mathrm{cue}}=[1.65,2.05]$、former guard $[1.25,2.45]$、full-cue containment、bulk-gap
  uniqueness、bulk refinement、safe-interior ratio和raw/safe edge buffer；
- finest Hausdorff accuracy cap、reflection defect和reflection parity quality；其中非法 connectivity/interface/
  periodic identification仍按§36.8的数学合法性处理；
- localization thresholds $L_0\ge0.15$、$L_{\mathrm{core}}\ge0.60$、tail $\le0.02$、tail plateau、
  collapse factor $0.80$ 和 twist-width collapse；
- simple/cluster overlap thresholds $0.90/0.80$、mutual-best condition、constant cluster-count、parity threshold
  $0.80$ 及 mode-ID ambiguity；
- FEM/supercell/twist/algebraic/total resolution pass thresholds、monotonicity 和
  `REFERENCE_SET_COVERAGE_UNRESOLVED`/`REFERENCE_RESOLUTION_UNRESOLVED` flags；
- 40/48-root agreement、bulk count-sentinel mismatch和spectrum-ceiling margin。

特别地，旧 `BULK_GAP_UNRESOLVED` 只能出现在 `bulk_gap_diagnostic`/classification 中，绝不能再是
scientific terminal、exception、early return 或 empty-candidate reason。A valid field-bearing eigenobject可被标记为
`gap-interior`、`gap-edge`、`embedded-or-bulk-overlap`、`near-continuum`、`weakly-localized`、
`parity-ambiguous`、`pre-asymptotic` 或 `coverage-partial`；任何这些标签都不能删除它或阻止排名。

### 36.3 Finite reference-own spectrum expansion

$I_{\mathrm{cue}}$ 只是初始 search hint。以其宽度 $0.4$ 为与 current chain 无关的固定扩展步长，预注册

$$
W_m=[1.65-0.4m,\,2.05+0.4m],
\qquad m=0,1,2,3,
$$

即

$$
W_0=[1.65,2.05],\quad
W_1=[1.25,2.45],\quad
W_2=[0.85,2.85],\quad
W_3=[0.45,3.25].
$$

所有 windows 和 root counts 在 reveal 前固定；不得因 BIE/QZ location 或 field 改动。Actual eigensolve schedule为：

1. 保留现有9个 fitted meshes、72个bulk solves及7组47个defect solves；bulk 仍为67个40-root main spectra加5个
   48-root count spectra。
2. 47个base defect solves全部直接请求最低48个正 generalized eigenpairs，保留原 mesh、$N$、twist grids及
   tight/loose tolerance role；这是真实的40-to-48 spectrum expansion，不是window label。
3. 对selection authority `fine = (N,s,n_\Gamma,\mathrm{tol},\vartheta\text{-grid})
   =(5,24,48,10^{-11},\vartheta_{17})`，令 $k_{48}^{(r)}$ 是第$r$个twist slice的第48个有效频率，并用
   现有 upper sentinel margin $\mu=0.10$ 定义 window $W_m=[a_m,b_m]$ 的 finite-spectrum coverage diagnostic

   $$
   C_{48,m}=\bigwedge_{r=1}^{17}\left(k_{48}^{(r)}>b_m+\mu\right).
   $$

4. 若 $C_{48,3}$ 为 false，则必须在同一 command、同一 meshes/source、同一 tight tolerance下对**全部17个**
   `fine` twists实际追加60-root solves，形成唯一 expansion rung `fine-expand60`；不得只重算看似接近某个 current
   root 的slice。以第60根同式定义 $C_{60,m}$。若 $C_{48,3}$ 已为 true，不运行60-root rung。
5. Spectrum expansion在 `W3 covered` 或 fixed 60-root cap 达到时确定性停止；没有第三root rung、shift target或
   事后扩窗。若60-root ceiling仍未覆盖 $W_3$，保存 largest covered $m$、每slice ceiling和margin，并标为
   `SPECTRUM_COVERAGE_PARTIAL`。这会降低第6项ranking key和claim strength，但不能取消任何已经数值有效的候选。

Candidate inventory取所有returned clusters中与 $W_3$ 相交的正频率 eigenobjects；cluster跨window edge时保留整个
cluster并加 `WINDOW_EDGE_STRADDLE`。因此扩展不足不会借由full-containment rule删除已有 field。只有§36.8定义的
数学/数值无效对象才不进入candidate inventory。

### 36.4 Candidate generation and threshold-free tracking

每个数值有效candidate object必须含 finite positive $\lambda$、$k=\sqrt\lambda$、mass-normalized eigenfunction/
cluster subspace、normalized residual和current-run mesh/phase identity。Existing cluster tolerance只定义multiplicity
group，不是通过门。

Tracking以`fine`的 $\vartheta=0$ clusters为首选anchor；若该slice无valid object，则按固定优先级
`fine`其余递增twist、`N4-fine`、`fem-medium`、`N4-medium`、`N3-medium`、`fem-coarse`、
`fine-loose-count` 取第一个存在valid object的anchor level/slice。每个anchor cluster按其所在spectrum的递增root index
取得永久 `candidate_id`。

Within-twist及cross-configuration continuation均使用 current-run common-core principal overlap；不同dimension时用
两subspace较小dimension上的最小principal overlap。每一步执行maximum-total-overlap one-to-one assignment，exact tie按
较小frequency-envelope distance、较小target root index、较小source `candidate_id` 依次打破。Birth/death、changing
cluster counts、non-mutual best、overlap低于旧0.90/0.80或dimension变化均写入tracking diagnostics，但不终止和不删除
assigned或unmatched objects；unmatched object作为新branch component保留。

一个rankable candidate须有valid anchor field，并在至少一个不同预注册refinement configuration中有上述确定性
continuation record。Singleton仍保存为`UNTRACKED_AUXILIARY_EIGENOBJECT`，但不声称“跨refinement可追踪”。只要至少
一个rankable candidate存在，程序必须完成排序并交付第一名；不得因gap、localization、parity、coverage或resolution
diagnostic较差而返回no-reference。

### 36.5 Exact lexicographic ranking and selected FEM reference

对每个rankable candidate $j$ 构造下列key，并按所列顺序作**ascending lexicographic order**；这是唯一selection rule：

1. **branch persistence**
   $P_j=(-n_{\mathrm{axes},j},-n_{\mathrm{config},j},-n_{\vartheta,j})$，其中counts分别是出现continuation
   record的四类refinement axes数、七个configuration数和distinct twist slices数；
2. **refinement drift**
   $D_j=(n_{\mathrm{missing},j},\sum\delta_{a,j}^{\mathrm{obs}})$，missing component在stored schema中为`NaN`，
   排序时只通过先比较missing count而置后，不伪造成有限误差；
3. **residual** $R_j=\max$ of normalized residuals over the tracked component，越小越优；
4. **field localization** $L_j=(-\min L_0,-\min L_{\mathrm{core}},\max T_{\mathrm{tail}})$，只排序不通过；
5. **parity** $Q_j=0,1,2$ 分别表示stable assigned parity、ambiguous/mixed parity、parity unavailable；even和odd之间
   不设偏好；
6. **spectrum coverage** $S_j=(-m_{\mathrm{covered}},-n_{\mathrm{covered\ slices}},
   -\min\mathrm{ceiling\ margin})$；
7. **final tie-break**：较小anchor configuration priority、较小anchor twist index、较小root index、较小
   `candidate_id`。

不存在weighted score、nearest-$1.85$、nearest-$\widehat k_h$ 或revealed-field tie-break。第一名记为 $j_1$。在其
richest available branch level上，令全部已追踪twists和cluster multiplicity给出
$[\lambda_{j_1}^{\min},\lambda_{j_1}^{\max}]$，冻结

$$
\lambda_{\mathrm{ref}}^{\mathrm{FEM}}
=\frac{\lambda_{j_1}^{\min}+\lambda_{j_1}^{\max}}{2},
\qquad
k_{\mathrm{ref}}^{\mathrm{FEM}}
=\sqrt{\lambda_{\mathrm{ref}}^{\mathrm{FEM}}}.
$$

Reference field取该richest level的declared anchor-twist mass-normalized subspace；multiplicity one时另以最大幅值DOF为
pivot固定global phase。Multiplicity大于一时只交付subspace，不伪造唯一basis vector。

### 36.6 Refinement ladder and $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$

七个base configurations继续提供FEM、supercell、twist和algebraic axes。对branch frequency envelope
$E=[k^-,k^+]$ 定义

$$
d_\infty(E,E')=\max\{|k^--k'^-|,|k^+-k'^+|\}.
$$

只要对应continuation object存在，就沿用已实现的observable formulas：

$$
\delta_{\mathrm{FEM}}^{\mathrm{obs}}
=d_\infty(E_{N5,s24,\vartheta_5}^{\mathrm{tight}},
E_{N5,s18,\vartheta_5}^{\mathrm{tight}}),
$$

$$
\delta_N^{\mathrm{obs}}
=d_\infty(E_{N5,s24,\vartheta_5},E_{N4,s24,\vartheta_5})
+\left|d_\infty(E_{N5,s24,\vartheta_5},E_{N4,s24,\vartheta_5})
-d_\infty(E_{N5,s18,\vartheta_5},E_{N4,s18,\vartheta_5})\right|,
$$

$$
\delta_{\mathrm{twist}}^{\mathrm{obs}}
=\frac{k_{f,17}^{+}-k_{f,17}^{-}}{2}
+d_\infty(E_{f,17},E_{f,9}),
$$

$$
\delta_{\mathrm{alg}}^{\mathrm{obs}}
=\max_{\vartheta\in\vartheta_5}
d_\infty(E_{f,\mathrm{tight}}(\vartheta),
E_{f,\mathrm{loose}}(\vartheta)).
$$

当四项均finite时定义且只定义

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}
=\delta_{\mathrm{FEM}}^{\mathrm{obs}}
+\delta_N^{\mathrm{obs}}
+\delta_{\mathrm{twist}}^{\mathrm{obs}}
+\delta_{\mathrm{alg}}^{\mathrm{obs}}.
$$

任一axis missing时保存该component为`NaN`、`delta_ref_obs=NaN`及`EMPIRICAL_RESOLUTION_PARTIAL`，但候选仍排名并
可成为第一名。旧collapse/total thresholds只生成per-axis pass/caveat flags。即使四项finite，
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 仍只是 observed sensitivity sum，不是
$|k_*-k_{\mathrm{ref}}^{\mathrm{FEM}}|$ upper bound、confidence interval或certified uncertainty。

### 36.7 Field, spectral and mode classifications

每个candidate至少保存以下non-cancelling labels：

- `cue-member`或`expansion-shell-1/2/3`；
- `gap-interior`、`gap-edge-or-safe-buffer`、`embedded-or-bulk-overlap`或`bulk-gap-unresolved`，由current-run
  bulk spectra、former guard和safe-interior diagnostics给出；
- `localized`或`weakly-localized`，并附全部 $L_0,L_{\mathrm{core}},T_{\mathrm{tail}}$ 和collapse histories；
- `even`、`odd`、`mixed/ambiguous`或`parity-unavailable`；
- `refinement-stable-diagnostic`、`pre-asymptotic-diagnostic`或`resolution-partial`；
- `spectrum-covered-through-Wm`或`spectrum-coverage-partial`，以及near-ceiling margin。

这些labels只控制claim措辞。尤其 `embedded-or-bulk-overlap` 或 `weakly-localized` 的第一名仍必须输出
$k_{\mathrm{ref}}^{\mathrm{FEM}}$、$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$ 和field，但其status须明确是
`EMPIRICAL_FEM_CANDIDATE_WITH_CAVEATS`，不能称continuous guided-mode existence proof或certified reference。

### 36.8 Exact global no-reference blockers

本轮只有以下状态可导致**没有** top FEM candidate；不得新增 heuristic blocker：

1. 所有可用refinement configurations均因非法mesh/phase space而无法形成离散对象：nonfinite/out-of-range或
   duplicate/nonpositive elements、material-interface crossing/missing required constraints、nonbijective periodic pairing或
   invalid quasiperiodic reduction；accuracy-only Hausdorff/reflection size不在此列。
2. 所有potential candidate objects均因nonfinite matrix/eigenobject、raw Hermitian failure、mass non-SPD、eigensolver未返回
   finite positive eigenpair、invalid field、或normalized residual/orthogonality failure而无效。单个level/object失败只记录并
   继续；不能取消其他valid candidate。
3. 完整base加conditional expansion schedule结束后，所有refinement levels合起来仍没有一个valid field-bearing eigenpair
   component能形成§36.4要求的cross-configuration continuation；terminal为
   `NO_TRACKABLE_EIGENPAIR_FIELD_ACROSS_REFINEMENTS`。
4. Whole command达到 $2700$ s或aggregate RSS达到 $2147483648$ B；立即停止，无grace。
5. Create-once canonical artifact无法发布；这是`CANONICAL_PUBLICATION_FAILURE`，不得伪造READY。

Dependency/path/controller/environment错误仍是operational failure，可在保留证据和bounded re-review后按同attempt规则修复；
它们不是FEM scientific no-reference结论。Active source若违反信息隔离，则spec-to-code review必须在launch前阻止执行，不能
靠run-time terminal洗白。

### 36.9 Canonical, field and partial artifact contract

Root仍只允许 `scientific-result.mat`、conditional `fields.mat`、`run.log`、`resource.tsv` 和summary-last
`run-summary.csv`；`work/`保存create-once mesh/spectrum caches和terminal draft，不恢复mirror/checkpoint/history/forecast
系统。

`scientific-result.mat`升级为一个single-authority schema，至少含：`schema_version`、`run_id`、immutable `spec`、
`search_windows`、base/expansion schedule及actual counts、mesh descriptors、bulk/defect spectra、root-ceiling coverage、
all candidate/track inventories、diagnostic/classification ledger、exact rank keys和ordered IDs、four-axis components、
`delta_ref_obs`、`selected_candidate`、terminal、first direct failure和claim boundary。`selected_candidate`必须含
`candidate_id`、`lambda_ref_fem`、`k_ref_fem`、lambda/k envelopes、multiplicity、anchor mesh/twist、rank key、
classification、四个delta components、`delta_ref_obs`和resolution status。

`fields.mat`至少含选中anchor的points/triangles/material identity、mass-normalized subspace、multiplicity、normalization和phase
status；可含其余candidate anchor subspaces，但不得形成第二scalar selection authority。若存在rankable candidate，terminal
必须是 `FEM_REFERENCE_CANDIDATE_READY`，collection size至少1，且summary直接给第一名两个reference scalars和
`EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY` boundary；diagnostic caveats不能把它改成negative。

在§36.8 blocker处停止时，canonical partial artifact仍保存全部已成功到达的current-run spectra/fields、invalid-object reasons、
schedule position和empty selected candidate；resource/operational stop由controller truth覆盖。任何 complete/incomplete launch都
不覆盖旧run，也不把partial写成READY。

### 36.10 Budget estimate

`run-006` 的 $21.435584$ s/$812744704$ B只证明67个bulk solves和controller overhead，不外推为full-run cost。
保守planning仍以§31接受的119-solve core point $1788$ s和此前约 $1.20$--$1.4073$ GiB full-workload evidence为基准。
旧schedule的requested-root work为

$$
67\cdot40+5\cdot48+42\cdot40+5\cdot48=4840.
$$

新base为 $67\cdot40+5\cdot48+47\cdot48=5176$；最坏再加17个60-root fine solves，总量
$6196$，即旧root-work的约 $1.2802$ 倍。按该比例，core planning约 $2289$ s；再给controller、branch processing和single
publication约 $10\%$ planning allowance，whole-command estimate约 $2518$ s，严格小于 $2700$ s。Memory用更保守的
$1.4073$ GiB evidence按60/48线性放大为约 $1.7591$ GiB，低于 $2$ GiB。两者都只是prospective estimates，实际hard
controller仍为唯一资源裁决；不得设置 $2518$ s或 $1.7591$ GiB stop。

因此本设计在max 136 eigensolves、single command、$2700$ s/$2$ GiB内有evidence-based feasibility；若Skeptic认为
root-work scaling不足以支持launch，真正blocker只能是该完整schedule预计越过hard upper，而不能以较低预防门替代用户授权。

### 36.11 Engineer boundary, theory-to-code gate and pre-run acceptance

同一Engineer的未来bounded implementation只可修改 `test/i4/femref-a1/run_i4_1a.m`、`run_formal.pl`、`README.md`和
`SYMBOLS.md`：把exact ID/launcher改为`run-007`，实现48-root base、conditional 60-root fine expansion、threshold-free
tracking、exact ranking/Delta/classifications及本节schema。不得改package/main code、I1--I3、methods/manuscript、design/review
history或`output/run-001`--`run-006`；不得恢复diagnostic/audit mirrors。Implementation阶段不授权run。

Mandatory Researcher theory-to-code audit必须逐项确认：

1. continuous/discrete forms、meshes、phase grids/tolerances和information isolation未变；
2. exact `run-007` allowlist、create-once namespace和旧outputs无read/stat/hash/copy/reuse；
3. `BULK_GAP_UNRESOLVED`及§36.2全部heuristics只写diagnostic，不可达terminal/early-return/candidate filter；
4. base 72+47及conditional 17-by-60 actual eigensolve call graph、coverage formulas和max136 count；
5. births/deaths/low overlap/parity/localization/refinement failures不阻止total assignment/ranking；
6. rank key逐字段、tie-break、$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$、$k_{\mathrm{ref}}^{\mathrm{FEM}}$、field和
   $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 与§36.5--36.7一致；
7. global no-reference paths恰为§36.8，partial/success schemas single-authority且summary-last；
8. controller仍只有absolute 2700 s和aggregate 2147483648 B，且source无BIE/QZ/estimator/effectivity path。

随后同一Skeptic必须给focused design review；Engineer实现后再经Researcher theory-to-code和同一Skeptic exact
spec-to-code/resource review。只有无unresolved blocker的pre-run verdict才能授权从
`/Users/whc/Documents/Work/epost/test/i4/femref-a1`执行一个fixed no-argument runner command。Post-run review完成前不得
同步reference、揭示estimator或进行effectivity comparison。

**Researcher design decision: `GO TO THE SAME SKEPTIC FOR BOUNDED §36 DESIGN REVIEW / NO CURRENT BLOCKER / IMPLEMENTATION AND RUN-007 EXECUTION NOT YET AUTHORIZED`.**

## 37. 2026-08-31 §AX candidate-domain and lifecycle clarification

Status: **`BOUNDED §36 REVISION / NOT IMPLEMENTED / NOT RUN`**.

本节只关闭 review §AX 的唯一 blocker并冻结两个实现歧义；§36的continuous model、$W_0$--$W_3$、base 119加
conditional 17的max-136 schedule、ranking字段顺序、$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ formulas、
$2700$ s/$2147483648$ B、information isolation和no-effectivity boundary全部不重开。

### 37.1 Every valid field-bearing $W_3$ object is rankable

完成当前有限schedule后，所有来自legal configuration、数值有效、field-bearing且frequency cluster与 $W_3$ 相交的
eigenobject/component都进入§36.5的同一个lexicographic ranking。Cross-configuration edge、twist continuation、
overlap threshold或完整refinement axis都不是membership条件。

没有continuation edge的singleton也取得永久`candidate_id`，labels固定为
`UNTRACKED_SINGLE_CONFIGURATION / EMPIRICAL_RESOLUTION_PARTIAL`。为使§36.5第一key自然偏好真实persistence而不设门，
persistence counts改为anchor之外的evidence counts：

$$
n_{\mathrm{axes}}=\#\{\text{axes with a continuation edge}\},\qquad
n_{\mathrm{config}}=\max(\#\{\text{linked configurations}\}-1,0),
$$

$$
n_{\vartheta}=\max(\#\{\text{linked valid twist nodes}\}-1,0).
$$

因此untracked singleton的三项均为0；有persistence的candidate通过原第一key
$(-n_{\mathrm{axes}},-n_{\mathrm{config}},-n_{\vartheta})$ 排在其前面，但singleton绝不被删除。其missing delta components
和`delta_ref_obs`保存为`NaN`。

§36.8(3)由本节完全替换：只有complete base/conditional schedule结束后，**所有legal configurations合计没有任何一个
数值有效、field-bearing、与 $W_3$ 相交的eigenobject/component**，才可返回
`NO_VALID_FIELD_BEARING_W3_EIGENOBJECT`。缺少tracking、continuation、overlap、parity、localization、coverage或
refinement evidence不能产生no-reference terminal。§36.8(1)、(2)、(4)、(5)保持不变。

### 37.2 Total publication level, anchor and missing-value order

对排名第一的component，publication level从其全部valid realizations按下列tuple取唯一最小者：

$$
(-n_{\vartheta}^{\mathrm{valid}},\ p_{\mathrm{config}},\ i_{\vartheta}^{\min},\
i_{\mathrm{root}}^{\min},\ \mathrm{candidate\_id}),
$$

其中先最大化该realization的valid twist count；`configuration` total priority固定为
`fine`、`N4-fine`、`fem-medium`、`N4-medium`、`N3-medium`、`fem-coarse`、
`fine-loose-count`；其后依次取最小valid twist index、最小cluster root index和最小`candidate_id`。Published
$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$、$k_{\mathrm{ref}}^{\mathrm{FEM}}$ 和lambda/k envelopes只用该唯一level的
全部valid twists；published field取该level的最小valid twist index，multiplicity-one phase fixing及higher-multiplicity
subspace规则仍按§36.5。

所有raw missing quantities保留`NaN`，不得原位伪造数值。构造rank-comparison projection时，待最小化scalar的`NaN`
映为$+\infty$，待最大化scalar的`NaN`映为$-\infty$，所以finite总是优于同一lex position的missing；parity
unavailable仍用§36.5的rank 2。Refinement key精确为

$$
D_j=(n_{\mathrm{missing},j},s_{\mathrm{finite},j}),\qquad
s_{\mathrm{finite},j}=\sum_{a:\,\delta_{a,j}^{\mathrm{obs}}\text{ finite}}
\delta_{a,j}^{\mathrm{obs}},
$$

empty finite-part sum定义为0。`delta_ref_obs`只有四项全finite时才取§36.6的和，否则仍为`NaN`；ranking只用上述
missing count加finite-part sum。最终`candidate_id` tie-break保证total order，任何实现不得使用native `NaN` comparison。

### 37.3 Exact `run-007` lifecycle

`run-007`是唯一scientific identity。首次launch冻结append-only execution label `execution-001`；每个execution label只写
自己的create-once leaf namespace，不覆盖先前label。Scientific terminal、wall/RSS resource terminal或canonical publication
failure均消费`run-007`，不得重跑或创建下一execution label。

只有经post-failure review确认为dependency/path/source/controller/environment等真实operational failure时，才不消费
scientific `run-007`；其失败evidence和`execution-001`永久保留。同一Researcher--Engineer--Skeptic完成bounded修订与
pre-run re-review后，仍使用同一`femref-a1/run-007` identity，并冻结最小未用的显式
`execution-002`、`execution-003`等label。不得auto-retry、不得覆盖、不得创建新run ID，也不得由MATLAB读取旧execution
content；runner只可检查当前明确冻结label的collision。§36.9所称root artifact contract逐execution label适用，post-run
review以exact shell exit和对应label的single-authority leaves判定。

Theory-to-code和same-Skeptic focused review必须额外确认：singleton进入排序且persistence为0；§36.8(3)旧terminal不可达；
publication tuple及`NaN` projection逐字段实现；`execution-001` lifecycle无历史science input。通过前仍不授权Engineer或
`run-007` execution。

**Researcher decision: `GO TO THE SAME SKEPTIC FOR FOCUSED §37 RE-REVIEW / §AX BLOCKER CLOSED IN DESIGN / NO IMPLEMENTATION OR RUN AUTHORIZATION`.**

## 38. 2026-08-31 Researcher theory-to-code audit of the §§36--37 implementation

Status: **`REVISE / ONE SOURCE-LOCAL BLOCKER / NOT RUN`**. 本节只审查当前四文件implementation diff；没有运行
MATLAB、Octave、Python、runner或任何数值程序，也没有创建`run-007`。

### 38.1 Static mapping that passed

以下结论为静态源码层面的`ESTABLISHED`，不等同于runtime validation：

1. `run_i4_1a.m`仍冻结相同continuous scalar problem、conforming fitted-$P_1$弱形式、材料与几何、
   $\beta=0.5$、$\lambda=k^2$、mesh/phase/tolerance grids及mass-normalized generalized eigensolve。
   Active source只使用源码常量与current-execution cache；未发现读取historical output、BIE/QZ、density、estimator、
   Markdown或Git的路径。
2. MATLAB和controller均只接受`run-007/execution-001`。Bulk call graph为
   $17+17+33+5=72$，base defect call graph为$5+5+17+5+5+5+5=47$；47个base solves请求48 roots。
   若17个fine base slices不能全部满足第48根高于$W_3$上端加$0.10$，则全部17个slices追加60-root solves，
   所以actual cap为$119+17=136$。Expansion失败slice不会删除其已有valid 48-root spectrum。
3. Top-level正确检查`isempty(candidate_inventory.objects)`，不是检查非空wrapper struct；tracking components从全部
   retained objects建立，因此singleton也形成component。Persistence counts、four observed deltas、missing-count加
   finite-part-sum、`NaN` rank projection、publication-level tuple、$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}$、
   $k_{\mathrm{ref}}^{\mathrm{FEM}}$、multiplicity-one phase fixing和higher-multiplicity subspace均对应§§36--37。
   Gap、coverage、overlap、parity/localization thresholds及missing refinement本身未直接出现在top-level terminal allowlist。
4. Per-mesh和per-spectrum numerical failure均被局部记录后继续；current-run mesh/spectrum caches、canonical MAT、conditional
   fields及summary-last字段保持single-execution audit path。Controller只含inclusive $2700$ s与
   $2147483648$ B两个resource upper；未发现forecast、stall、CV、lower wall/RSS或documentation-controlled gate。

### 38.2 Blocker: a derived diagnostic can still cancel a valid field

`REFUTED`：当前实现尚不能保证§37.1所要求的“每个数值有效、field-bearing、与$W_3$相交的object都进入ranking”。

精确路径在`LOCAL_w3_clusters`。Lines 1497--1509先正确验证finite subspace及full-mass Gram；但lines
1510--1525随后把三个localization restricted Grams和endpoint parity Gram放在同一个outer object-validity `try`内。
这些派生量调用`LOCAL_checked_hermitian(...,'NUMERICAL_OBJECT_INVALID')`。任一localization/parity diagnostic因nonfinite、
Hermitian tolerance或derived eigendecomposition失败，都会落入lines 1571--1577的outer `catch`，把整个cluster写为invalid而
不执行`clusters(end+1)=object`。若它是唯一valid $W_3$ field，top-level随后会错误返回
`NO_VALID_FIELD_BEARING_W3_EIGENOBJECT`。因此parity/localization diagnostic仍是可构造的candidate-cancelling gate；这直接
违反§37.1、review §AY.2(2)及用户限定的no-reference allowlist，属于`BLOCKER`而不是style caveat。

### 38.3 Minimal bounded repair and next gate

Engineer只需在`LOCAL_w3_clusters`及其直接record/classification consumer作source-local修复，不改scientific schedule、
weak form、threshold数值、ranking顺序、schema authority或controller：

1. finite subspace、full-mass normalization、eigenvalue/residual/orthogonality仍是hard object-validity checks；不得降级。
2. Localization restricted-Gram计算使用独立local `try/catch`。失败时保留该object，三个raw metric写`NaN`，保存
   diagnostic-unavailable reason并给`localization-unavailable` caveat；不得写入invalid-object allowlist。
3. Parity Gram使用另一个独立local `try/catch`。失败时保留该object，写空parity values、`parity-unavailable`及reason；
   common-core sampling现有diagnostic-only catch保持不变。
4. Candidate aggregation对上述missing metrics使用§37.2的finite/`NaN` projection，并确保missing diagnostic必定产生
   `EMPIRICAL_FEM_CANDIDATE_WITH_CAVEATS`，但不取消candidate、field或READY terminal。

其余静态mapping没有发现需要扩大修复范围的blocker。修复后必须由同一Researcher只复核上述negative paths、struct fields和
empty/`NaN` consumers，再交同一Skeptic作focused spec-to-code review。当前不得运行`run_formal.pl`或MATLAB。

**Researcher decision: `REVISE / DERIVED LOCALIZATION-PARITY DIAGNOSTIC CAN CANCEL A VALID W3 FIELD / MINIMAL SOURCE-LOCAL REPAIR THEN SAME-RESEARCHER DELTA AUDIT AND SAME-SKEPTIC REVIEW / RUN-007 NOT AUTHORIZED`.**

## 39. 2026-08-31 Researcher delta audit of the §38 source-local repair

Status: **`REVISE / OBJECT-RETENTION BLOCKER CLOSED / ONE NaN-CONSUMER BLOCKER / NOT RUN`**. 本节只静态复核
`LOCAL_w3_clusters`修复及其直接rank/classification consumers。

### 39.1 What the repair closed

`ESTABLISHED`：finite subspace和full-mass normalization仍在outer hard-validity path；upstream finite-positive
eigenvalue、residual及orthogonality gates未改变。Localization restricted Grams和endpoint parity Gram现已分别置于local
`try/catch`。失败时保存`NaN` localization metrics或`parity-unavailable`、status及reason，随后仍执行
`clusters(end+1)=object`；这些派生诊断不再进入`invalid_objects`，所以§38.2的field-deletion/no-object反例已关闭。
未发现该局部差分改变window、schedule、tracking、Delta formulas或hard object-validity checks。

### 39.2 Remaining blocker in the direct consumer

`REFUTED`：§38.3要求的“missing diagnostic必定进入`NaN` rank projection并产生caveat”尚未对multi-realization
component成立。

`LOCAL_candidate_record`仍以无missing flag的`min([objects(ids).L0_min])`、`min(...)`和`max(...)`聚合localization。
MATLAB R2023b的`min`/`max`默认omit missing values；因此一个realization保存`NaN`而同component另一个realizationfinite时，
aggregate仍为finite，现有`~all(isfinite(...))`不会触发，`localization-unavailable`及mandatory caveat均可消失。
同样，`LOCAL_candidate_parity_rank`忽略`parity-unavailable` labels；若一个endpoint parity diagnostic失败而另一个endpoint给出
stable even/odd，rank可仍为0，新增`parity_status/parity_reason`没有consumer，failure caveat再次被掩盖。两条路径不再取消
candidate，但会把有缺失派生诊断的candidate误标为无此caveat，违反§38.3(4)和冻结claim classification。

### 39.3 Minimal remaining repair and gate

Engineer只需修改直接consumer：

1. 先检查component内所有`localization_status`；只有全部`AVAILABLE`才计算三个aggregate，否则显式把三个aggregate都设为
   `NaN`，使现有§37.2 projection、`localization-unavailable`和candidate caveat可达，不依赖`min`/`max`默认missing语义。
2. 用`parity_status/parity_reason`区分正常的`NOT_ENDPOINT_TWIST`与endpoint计算失败；任一endpoint diagnostic failure必须令
   parity classification/rank为unavailable或partial并触发candidate caveat。非endpoint未计算parity本身不新增caveat。
3. 不改object membership、ranking字段顺序、threshold、科学模型、schedule、schema authority或controller。

修复后同一Researcher只需复核上述两个mixed-component反例，再移交同一Skeptic。当前仍不得运行runner或MATLAB。

**Researcher decision: `REVISE / FIELD RETENTION FIXED BUT MIXED-COMPONENT MISSING LOCALIZATION OR ENDPOINT PARITY CAN BE SILENTLY OMITTED / MINIMAL DIRECT-CONSUMER REPAIR THEN SAME-RESEARCHER DELTA AUDIT / RUN-007 NOT AUTHORIZED`.**

## 40. 2026-08-31 Researcher closure audit of the §39 consumers

Status: **`PASS / §38--§39 BLOCKERS CLOSED / STATIC ONLY / NOT RUN`**. 本节只复核§39指定的两个direct consumers。

`ESTABLISHED`：`LOCAL_candidate_record`先显式检查component内全部`localization_status`。只有全部为`AVAILABLE`才聚合
$L_0$、$L_{\mathrm{core}}$和tail；任一missing便显式写三个`NaN`。现有rank projection于是把这些待最小化/最大化的missing
量置后，classification写`localization-unavailable`，candidate status写
`EMPIRICAL_FEM_CANDIDATE_WITH_CAVEATS`；object、field、ranking membership及READY能力均不受取消。

`ESTABLISHED`：`LOCAL_candidate_parity_rank`只在实际endpoint twists上检查parity。没有endpoint或任一endpoint
`parity_status`不是`AVAILABLE`时rank为2并产生`parity-unavailable` caveat；全部endpoint可用时才按共同even/odd给0，
否则给mixed/ambiguous的1。非endpoint的`NOT_ENDPOINT_TWIST`不会单独制造failure gate。该逻辑关闭了§39.2的mixed-endpoint
反例，同时保持§§36--37的parity只排序/分类、不取消候选规则。

本delta未新增terminal、threshold、early return或filter；full-mass/finite-positive eigenobject、residual及orthogonality仍是
hard validity，scientific schedule、ranking字段顺序、Delta formulas、schema authority和resource controller未改变。
未发现剩余source-local blocker。下一步只允许同一Skeptic作focused spec-to-code/resource review；其通过前仍不得执行
`run-007`。

**Researcher decision: `PASS / GO TO THE SAME SKEPTIC FOR FOCUSED SPEC-TO-CODE REVIEW / RUN-007 NOT AUTHORIZED BY THIS AUDIT`.**

## 41. 2026-08-31 Researcher delta audit of the §AZ exception routing

Status: **`REVISE / §AZ ROUTING MOSTLY CLOSED / ONE NUMERICAL-ALLOWLIST NARROWING / NOT RUN`**. 本节只静态复核
§AZ要求的catch、canonical terminal和summary handoff差分。

### 41.1 Routes that are now correct

`ESTABLISHED`：`LOCAL_mesh_registry`只记录显式mesh/seam numerical codes，其他I4A code以及generic
`EXECUTION_UNAVAILABLE`/`OUTPUT_*`均重抛；`LOCAL_attempt_spectrum`同样只记录显式phase/eigensolver/eigenobject numerical
codes，generic/source/output不再伪装成invalid solve。Candidate/object catches继续重抛generic/source/output；其可达的本地
numerical-object failure仍只删除该对象。

`ESTABLISHED`：`LOCAL_publish_scientific`已把`scientific-result.mat`的create-once save failure统一映为
`CANONICAL_PUBLICATION_FAILURE`。Top-level将该code识别为消费性的scientific terminal，但显式跳过第二次
`LOCAL_publish_scientific`，所以不会重复发布同一canonical leaf；随后直接写terminal draft并正常返回，使runner读取exact
terminal并发布summary-last的路径可达。`fields.mat` publication仍使用同一canonical code。该差分没有把generic failure误记为
scientific negative，也没有把canonical failure降为可修复operational failure。

### 41.2 Remaining blocker: one allowed mesh failure now aborts globally

`REFUTED`：numerical allowlist尚未保持不缩窄。`LOCAL_mesh_registry`允许把`MESH_QUALITY_UNRESOLVED`记录为单mesh
numerical failure并继续；该mesh因此不会进入registry。后续对应solve调用`LOCAL_load_mesh`时会再次产生
`MESH_QUALITY_UNRESOLVED`，但`LOCAL_attempt_spectrum`的`recordable`集合只有
`QUASIPERIODIC_SEAM_UNRESOLVED`、`SPECTRUM_INVENTORY_TRUNCATED`和`NUMERICAL_OBJECT_INVALID`。由于
`~recordable`，首次使用该已知失败mesh便全局重抛，其他legal meshes/configurations不再运行。这把§36.8允许的per-mesh
numerical invalid错误升级成global operational stop，违反single mesh failure继续及“所有legal configurations合计无valid
field才no-reference”的合同。

最小修复只是在`LOCAL_attempt_spectrum`的显式`recordable`集合加入`MESH_QUALITY_UNRESOLVED`；generic/source/output及所有
未列出的I4A code仍必须重抛。不得改变mesh checks、scientific allowlist的其他成员、schedule、candidate规则或terminal
classification。修复后同一Researcher只需复核该一行集合与四条异常反例，再移交同一Skeptic；当前不得执行`run-007`。

**Researcher decision: `REVISE / CANONICAL AND GENERIC ROUTING CLOSED BUT MESH_QUALITY_UNRESOLVED IS MISSING FROM THE PER-SOLVE NUMERICAL ALLOWLIST / ONE-LINE SOURCE-LOCAL FIX THEN DELTA AUDIT / RUN-007 NOT AUTHORIZED`.**

## 42. 2026-08-31 Researcher closure audit of the §41 allowlist line

Status: **`PASS / §AZ EXCEPTION-ROUTING BLOCKER CLOSED / STATIC ONLY / NOT RUN`**. `LOCAL_attempt_spectrum`的显式
`recordable`集合现为`MESH_QUALITY_UNRESOLVED`、`QUASIPERIODIC_SEAM_UNRESOLVED`、
`SPECTRUM_INVENTORY_TRUNCATED`和`NUMERICAL_OBJECT_INVALID`。因此registry中缺失的已记录invalid mesh会使对应solve返回
local invalid并由现有schedule loop继续其他meshes/configurations，不再升级成global operational stop。同时
`EXECUTION_UNAVAILABLE`、所有`OUTPUT_*`及任何未列明I4A code仍由同一条件重抛；numerical allowlist没有再扩大或缩窄，
canonical/terminal routing及全部数学路径未改变。未发现剩余blocker。

**Researcher decision: `PASS / GO TO THE SAME SKEPTIC FOR FOCUSED §AZ RE-REVIEW / RUN-007 NOT AUTHORIZED BY THIS AUDIT`.**

## 43. 2026-09-01 `run-008` 样本外 $s=30$ 网格层冻结设计

**Material Passport.** Origin: I4.1a Researcher prospective design；verification status: **未实现、未运行**；适用对象仅为
`test/i4/femref-a1/output/run-008/execution-001`。本节不改写`run-001`--`run-007`的任何事实。

### 43.1 目标、盲法与不变量

本轮只检验现有FEM路线在一个预注册样本外网格层上的延续性。新网格为

$$
N=5,\qquad s=30,\qquad g=60,
$$

且只按以下顺序计算五个既有mesh-refinement twist：

$$
\Theta_5=\left(0,\frac{\pi}{4},\frac{\pi}{2},\frac{3\pi}{4},\pi\right).
$$

每个twist只作一次48-root FEM求解，故本轮恰有5个eigensolver calls；不重跑旧72+47 schedule，不作60-root
扩展。48-root ceiling对$W_3$的覆盖、固定guard interval、safe-interior ratio、edge buffer、bulk-gap、localization和
parity均只记录为diagnostic/caveat，不可取消一个数值有效、带field的对象或branch。

连续问题、拟合界面P1弱形式、几何、材料、准周期相位、$lambda=k^2$、$W_1,W_2,W_3$、cluster和branch
语义、残量/正交容差及information-isolation contract沿用已审查的`run-007`数学路径，不得改变。活动MATLAB
entry point只接收自身冻结常数并写自身namespace；它不得读取任何历史output、BIE/QZ数据、density、estimator、
Markdown或Git状态。旧FEM scalars、预测值和BIE scalar均不得进入mesh、spectrum、branch或selection的活动调用图。

### 43.2 纯FEM对象、延续与候选冻结

每个twist保存48个谱值及残量，并对所有与$W_3$相交的whole cluster保存完整subspace；不得把跨越$W_3$边界的
cluster裁成单根。对每个field-bearing对象保存mesh索引、root/cluster identity、$lambda$与$k$ envelope、原始与
规范化subspace、残量、$L_0,L_{\mathrm{core}},T_{\mathrm{tail}}$、endpoint parity以及既有fixed common-core
grid上的样本与正权重。派生localization/parity计算失败时保留有效field并写`NaN`/明确status。

相邻twist之间使用既有mass-compatible common-core principal overlap作一对一maximum-total-overlap assignment。
每条edge的确定顺序为：较大overlap、较小$k$-envelope distance、较小target root、较小source object id、较小
target object id；birth、death和singleton全部保留。对象id按$Theta_5$顺序、root、cluster id编号，component id按
最小对象id编号，因此exact tie仍有唯一数值输出。

所有component（包括singleton）进入与§§36--37相同的lexicographic ranking在单configuration上的投影：依次优先
更多已覆盖的twist/continuation edges、较少missing refinement entries和较小finite-part drift sum、较小residual、
较强$L_0$与$L_{\mathrm{core}}$、较小$T_{\mathrm{tail}}$、较稳定parity、较充分$W_3$ numerical coverage，最后按
anchor twist、root、object id和candidate id破同分。四个不存在的跨configuration drift均以既有规则记为`NaN`，
在该层对所有候选贡献相同的missing count；`NaN`不能暗中胜过finite值。这里不得加入与旧$k$值或BIE距离有关的
排序键。只要至少一个数值有效、field-bearing的$W_3$对象存在，就必须冻结排名第一的component；未覆盖全部五个
twist只降低persistence并产生`PARTIAL_TWIST_CONTINUATION` caveat，不取消它。

设胜出component全部有效realizations中所有eigenvalues的集合为$\Lambda_{30}$，冻结

$$
\lambda_{30}=\frac{\min\Lambda_{30}+\max\Lambda_{30}}{2},\qquad
k_{30}=\sqrt{\lambda_{30}}.
$$

这与`run-007`的publication scalar定义相同。活动run先永久写定candidate inventory、ranking、winner、
$\lambda_{30}$与$k_{30}$，其后任何身份审查均不得重排、替换或回写这些canonical science字段。

### 43.3 样本外同mode身份审查

`run-007` candidate 7只能由同一Skeptic在`run-008`自然结束并完成上述纯FEM冻结后，用只读artifact audit揭示。
该审查不是MATLAB selector的一部分，不由formal runner调用，也不得写入或改写`run-008` canonical science。若需机器
计算overlap，只允许一个另经theory-to-code/spec-to-code核对的、reviewer-side只读审查路径；它不得调用
MATLAB/Octave experiment entry point，不得读取BIE/estimator，并只能向create-once review-audit leaf追加审查证据。

审查在每个$\vartheta\in\Theta_5$上读取`run-007` fine $(N,s,g)=(5,24,48)$ candidate 7的field subspace和
`run-008`全部$W_3$ field objects。两侧subspace在同一fixed common-core grid与同一正quadrature weights下分别作
Gram normalization，再以最小principal singular value给出mass-compatible overlap。每个twist在两侧完整对象
inventory上作一对一maximum-total-overlap assignment；tie-break依次为较小$k$-envelope distance、较小`run-008`
root、较小`run-007` root及两侧object id。exact equal row/column maximum虽有确定assignment，但身份标为ambiguous。

只有同时满足以下条件才登记`SAME_MODE_SUPPORTED`：胜出新component及旧candidate 7均覆盖全部五个twist；新component
的四条相邻twist continuation edges存在；每个跨网格pair是严格唯一mutual best；simple--simple pair的overlap不低于
$0.90$，任一cluster pair的最小principal overlap不低于$0.80$；五个twist的localization metrics均可读并逐点报告
原值、差值和classification；$artheta=0,\pi$的parity均可读且even/odd label一致。弱localization、bulk-gap unresolved、
coverage不足或threshold边缘本身只产生caveat；它们不是run failure。multiplicity变化若通过cluster阈值可登记
`SAME_MODE_SUPPORTED_WITH_MULTIPLICITY_CAVEAT`。

若完整高overlap链唯一落在另一个`run-008` component，则登记
`SELECTED_BRANCH_MISMATCH / ALTERNATE_MATCH_IDENTIFIED`；否则任何missing twist、非唯一match、低overlap、缺失所要求的
localization/parity证据或endpoint parity冲突均登记`IDENTITY_AMBIGUOUS`。这两类均保留合法`run-008`候选，但禁止把
$k_{30}$接入旧三点profile、禁止揭示BIE comparison，也不触发重跑或按BIE proximity换候选。

上述review-audit若执行，必须与scientific command共用一次`run-008/execution-001`资源账本：总wall time为两阶段
elapsed之和且必须小于2700 s，aggregate peak RSS取两阶段最大值且必须小于3,221,225,472 B；审查只能使用scientific
command结束后的正剩余时间，不得重置预算。审查路径不可用或剩余预算不足时只登记
`IDENTITY_AUDIT_UNAVAILABLE`，BIE继续sealed，不运行新的FEM solve。

### 43.4 预注册profile、预测和sealed comparison

以下旧FEM scalars只作为post-run read-only profile输入，绝不作为活动run的输入：

$$
k_{12}=1.842941342508127,\quad
k_{18}=1.837659912216170,\quad
k_{24}=1.835680010800799.
$$

三点预注册预测为$k_{30}^{\mathrm{pred}}=1.8347168036$。仅在`SAME_MODE_SUPPORTED`或带multiplicity caveat的同mode
状态冻结后，按“finer minus coarser”方向报告

$$
d_{12\to18}=k_{18}-k_{12},\quad
d_{18\to24}=k_{24}-k_{18},\quad
d_{24\to30}=k_{30}-k_{24},
$$

及$D_{a\to b}=|d_{a\to b}|$和

$$
\rho_1=\frac{D_{18\to24}}{D_{12\to18}},\qquad
\rho_2=\frac{D_{24\to30}}{D_{18\to24}}.
$$

零分母使对应ratio为`NaN / UNDEFINED`，不是失败。样本外预测残差固定为
$r_{\mathrm{pred}}=k_{30}-k_{30}^{\mathrm{pred}}$并同时报告$|r_{\mathrm{pred}}|$。

四点$s=(12,18,24,30)$的profile按$k(s)=k_\infty+C s^{-p}$、$p>0$作确定性variable-projection
nonlinear least squares：令$p=\exp(x)$；对每个$x$以QR解$[\mathbf 1,s^{-p}](k_\infty,C)^T\approx k$；
从$x=\log(1/8,1/4,1/2,1,2,4,8)$七个固定starts分别运行同一`fminsearch`，固定
`TolX=1e-12`、`TolFun=1e-24`、`MaxIter=10000`、`MaxFunEvals=50000`。在所有finite endpoints中按
$(\mathrm{SSE},p,\text{start-index})$ lexicographic最小者输出$p,k_\infty,C,\mathrm{SSE}$；同时原样报告所有exit flags。
不存在拟合acceptance threshold；不收敛或rank-deficient只产生`FIT_NUMERICALLY_UNRESOLVED` caveat，不改变$k_{30}$。

BIE+DtN scalar $k_{\mathrm{BIE}}=1.832770289108157$在同mode identity和以上FEM结果全部冻结前保持sealed。之后只作

$$
|k_{30}-k_{\mathrm{BIE}}|<0.0029097217
$$

的严格布尔检验（等号为false）。不得用它改候选、调参或声称effectivity。所有drift、ratio、fit、外推、prediction
residual及BIE位置比较均为empirical、non-certified observation，不是$\varepsilon_{\mathrm{ref}}$、连续谱存在性证明或
certified bound。

### 43.5 工件、失败语义和预算

create-once namespace严格为`run-008/execution-001`；任何已存在leaf均fail closed且不得覆盖。canonical最小集合为
`scientific-result.mat`、`fields.mat`、`run.log`、`resource.tsv`、`run-summary.csv`，另在`work/`保存一个mesh cache和按
上述顺序的五个spectrum caches。`scientific-result.mat`须包含冻结spec、solve ledger、完整$W_3$ inventory、tracking
edges/components、rank keys、winner及$\lambda_{30},k_{30}$；`fields.mat`须包含五个twist上全部$W_3$ objects的full
subspaces和common-core samples/weights，以使mutual-best审查可复现。summary必须最后发布；partial failure须保留此前
完成的有效spectra/fields和明确terminal reason。

唯一可阻止scientific publication的情形是：非法/不可构造的$(5,30,60)$ fitted mesh；nonfinite或raw non-Hermitian
stiffness/mass、mass非SPD；eigensolver失败或无满足既有finite/positive/residual/orthogonality要求的eigenpair；所有五个
twist均无有效field-bearing $W_3$对象；2700 s或3,221,225,472 B hard limit；以及create-once/canonical publication
失败。单个twist失败须记录后继续其余twists；只要尚有有效field candidate就仍排名发布。source/path/dependency等真实
operational failure保留immutable evidence，经有界复审后只能修复同一`run-008/execution-001` execution label，不能
覆盖或换ID。localization、parity、coverage、guard、safe-interior、edge和gap只作diagnostic/caveat。

资源只有用户授权的两个inclusive hard stops：whole-command elapsed达到2700 s或aggregate process-tree RSS达到
3,221,225,472 B时立即停止，无grace。不得加入更低wall/RSS门、forecast、stall、cadence、guard或reserve gate。
`run-007`的119 solves实测140.273679 s、1,353,826,304 B。启动前保守估计将每个新solve先按整个`run-007`命令成本
计，再乘2吸收更细网格和后处理，得到约1402.74 s；memory以面积因子$(30/24)^2$再加20%余量估得
2,538,424,320 B。两者均低于授权hard limits，因此资源层面没有prospective blocker；这些估计只用于GO判断，绝不成为
新的运行停止门。

### 43.6 最小实现边界与gate

Engineer只能在`test/i4/femref-a1/`增加一个独立的`run-008` scientific entry、一个fixed no-argument resource
controller及必要的README/SYMBOLS机械同步；不得修改package/main、历史runner/source或任何`run-001`--`run-007`
artifact。实现必须复用已审查数学helpers的最小必要内容，不恢复diagnostic dispatch、benchmark/forecast、mirror/
rewrite、history/hash/provenance ledgers或其他非数学审计。controller的唯一命令必须从该实验目录启动一次
`run-008/execution-001`，并只执行本节五个48-root solves。

正式运行前，Researcher须逐项完成theory-to-code mapping：exact spec、五次调用图、whole-cluster fields、assignment/
ranking、canonical schema、partial preservation、信息隔离和两个hard stops；同一Skeptic随后完成独立spec-to-code review。
二者通过前不得运行。post-run仍由同一Skeptic核验artifact/resource/result，并按§43.3决定是否允许只读identity audit与
sealed comparison。任何阶段均不得读取estimator或开展effectivity comparison。

**Researcher prospective decision: `GO TO THE SAME SKEPTIC FOR DESIGN REVIEW / RUN-008 NOT YET AUTHORIZED`.**

## 44. 2026-09-01 `run-008` operational-recovery 与机械记号修订

本节是对§BC唯一blocker的有界、前瞻性修订；与§43冲突之处以本节为准。scientific identity与attempt固定为
`run-008`，第一次execution固定为create-once `execution-001`。以下任一terminal outcome均消费`run-008`，不得重跑：

1. scientific/numerical terminal，包括合法negative result；
2. 2700 s或3,221,225,472 B resource terminal；
3. canonical-publication terminal，包括canonical leaf无法完整、唯一且按冻结顺序发布。

只有在post-failure review明确核验为真实source、path、dependency、controller或environment operational failure时，
该失败才不消费scientific `run-008`。此分类不得由runner自行作出，也不得把scientific、resource或canonical-publication
failure改名为operational。确认后必须由同一Researcher限定修订、Engineer实施最小修复，并由同一Skeptic完成完整
pre-run re-review；三道gate重新通过后，才可在同一`run-008`下使用最小未用的显式create-once execution label，第一次
恢复为`execution-002`，此后依次为`execution-003`等。不存在auto-retry、覆盖、复用旧leaf或更换run ID。

每个已启动execution及其leaf永久immutable。后续execution的active science不得读取、统计、复制、hash、比较或以其他
方式使用任何旧execution artifact；旧leaf只可供post-failure审查追溯。恢复execution仍须从冻结输入独立完成同样五个
48-root solves，并受同一个2700 s/3,221,225,472 B hard-budget contract约束。

§43中出现或可能由渲染产生歧义的机械记号统一解释为以下规范拼写：`$\lambda=k^2$`、`$\lambda$ envelope`、
`$\Theta_5$`以及`$\vartheta=0,\pi$`。这只修正LaTeX拼写，不改变任何数学对象。

除上述lifecycle与机械记号外，continuous model、P1弱形式、五次求解、candidate ranking、same-mode identity、profile、
sealed comparison、资源上限、failure allowlist及claim boundary均不重开。

**Researcher delta decision: `GO TO THE SAME SKEPTIC FOR §44 DELTA REVIEW / RUN-008 NOT YET AUTHORIZED`.**

## 45. 2026-09-01 `run-008` implementation theory-to-code audit

### 45.1 Scope and decision

本节只静态审查当前`test/i4/femref-a1/run_i4_1a_refine.m`、`run_refine_formal.pl`及其机械README/SYMBOLS
同步相对§§43--44和review §BD的映射。未执行MATLAB、Octave、Python、runner或任何数值程序，未创建output。

**Researcher audit decision: `PASS / GO TO THE SAME SKEPTIC FOR EXACT SPEC-TO-CODE AND RESOURCE REVIEW / RUN-008 NOT YET AUTHORIZED`.**

未发现会破坏数学对象、五次调用图、资源上限或canonical publication contract的静态blocker。以下结论只覆盖source
mapping和可构造的MATLAB shape；实际mesh、spectrum、RSS与wall time尚未验证。

### 45.2 Continuous/discrete model and exact schedule

- `run_i4_1a_refine.m:142--185`固定与`run-007`相同的period、radius、$q_{\mathrm{in}}=17$、
  $q_{\mathrm{out}}=1$、missing column、$\beta=0.5$、windows、solver/residual/Hermitian/orthogonality tolerances、
  common-core grid及random seed。`LOCAL_build_mesh`、`LOCAL_assemble_p1`、`LOCAL_periodic_maps`、
  `LOCAL_phase_reduce`、`LOCAL_checked_hermitian`和`LOCAL_low_spectrum`保留已运行`run-007`的fitted conforming
  $P_1$几何、material-weighted mass、stiffness、quasiperiodic reduction、raw-Hermitian-before-canonicalization和
  generalized eigenproblem；差分只把triangulation/eigs异常显式路由为既有mesh/spectrum failure，并使$g=60$的
  Hausdorff diagnostic实际求值，不改变弱形式。
- 顶层`run_i4_1a_refine.m:26--102`只接受`run-008`/`execution-001`，只构造
  `defect-N5-s30-g60`一个mesh。`spec.theta_5`严格为
  $(0,\pi/4,\pi/2,3\pi/4,\pi)$；唯一spectrum loop迭代五次，每次把`requested_nev=48`传给唯一
  `LOCAL_low_spectrum`调用。活动调用图中没有bulk、旧72+47 schedule、60-root expansion或第二mesh。
- 每个solve先保留48-root eigenvalues、frequencies、residuals、cluster ids、full fields与phase diagnostic；有限性、
  positivity、mass SPD、raw Hermitian、seam、residual、orthogonality及ordering仍是数值有效性检查。单twist合法数值失败
  进入ledger并继续，全部五个twist均无field-bearing $W_3$对象时才到
  `NO_VALID_FIELD_BEARING_W3_EIGENOBJECT`。

### 45.3 Fields, tracking, ranking and MATLAB shapes

- `LOCAL_w3_clusters`按48-root cluster inventory保留每个与$W_3=[0.45,3.25]$相交的whole cluster；
  `raw_subspace`与full-mass-normalized `subspace`均保留。localization、endpoint parity和common-core sampling各自在
  内层diagnostic catch中降级为明确status/`NaN`/empty，不会删除已经通过finite/mass/residual检查的field object。
- object empty-schema的字段与所有producer/consumer一致；slice ids为column vectors，component member ids可直接索引同一
  object array；cluster envelopes为$1\times2$，publication中的`vertcat`因此为$n\times2$；rank key的所有潜在
  missing diagnostics在排序前由`LOCAL_nan_min`或`LOCAL_nan_negative`投影为`Inf`，没有native `NaN`进入
  `sortrows`。静态LOCAL-symbol检查得到60个symbols；四个跨行signature中的helper
  `LOCAL_assemble_p1`、`LOCAL_candidate_coverage`、`LOCAL_reflection_map`、
  `LOCAL_triangle_reflection_diagnostics`亦均有定义，未见undefined `LOCAL_` call。
- 相邻四对twist仅调用`LOCAL_assign_object_sets`；finite common-core principal overlaps进入带birth/death dummy的
  lexicographic maximum-total assignment，tie keys依次落实overlap、envelope distance、target root和固定object ids。
  union-find只合并已分配edges，未匹配objects自然保留为singleton component。
- `LOCAL_candidate_record`的total rank依次落实$-n_{\mathrm{twist}}$、$-n_{\mathrm{edge}}$、四个缺失refinement
  slots、finite drift sum、residual、localization、parity、coverage及anchor/object ties。不存在旧FEM scalar或BIE
  proximity key。胜出component全部realizations的eigenvalue envelope给出
  $\lambda_{30}=(\min\Lambda_{30}+\max\Lambda_{30})/2$与$k_{30}=\sqrt{\lambda_{30}}$。

### 45.4 Information isolation, artifacts and controller

- MATLAB中唯一`load`为`LOCAL_load_current(entry.path)`，其中`entry.path`只由本execution的`work/s30-pXX.mat`
  构造；唯一输出根由自身source location和exact run/execution ids形成。活动source没有旧FEM values、candidate 7、
  BIE/QZ、density、estimator、Markdown或Git读取。source header中的设计路径只是comment，不进入执行。
- `scientific-result.mat`保存spec、mesh descriptor、五项compact ledger、完整compact object/candidate inventory、tracking、
  total rank和winner；`fields.mat`另保存单mesh、五项ledger、全部$W_3$ objects的raw/normalized subspaces、
  common-core samples/weights及$\lambda_{30},k_{30}$。负路径保留已完成solve ledger/current work caches；
  scientific、operational与canonical-publication路由不会把缺失结果伪装成READY。MATLAB只写terminal draft，controller
  依次发布`resource.tsv`和最后的`run-summary.csv`。
- `run_refine_formal.pl:9--16`固定no-argument、`run-008/execution-001`和exact MATLAB call；create-once leaf先于
  launch建立。唯一resource thresholds是absolute monotonic elapsed达到2700 s及deduplicated MATLAB process-tree RSS
  达到3,221,225,472 B；没有更低wall/RSS、forecast、stall、CV、reserve或grace predicate。process-table/PGID/reap
  失败保持operational fail-closed，不能产生READY。该controller除run/execution/scalar names和新RSS上限外，与已审查并
  完成`run-007`的controller路径一致。

### 45.5 Deferred identity audit and remaining gate

reviewer-side candidate-7 identity audit尚未实现，**不阻止**本次scientific run先以完全current-run的FEM规则永久冻结
$k_{30}$：§43明确把identity failure/unavailability降为post-run interpretation gate，且当前claim仅为
`EMPIRICAL_OUT_OF_SAMPLE_FEM_CANDIDATE_NO_EFFECTIVITY`。这一缺口仍严格阻止四点same-mode convergence profile、
sealed BIE reveal/comparison及任何reference/effectivity结论。

若scientific run后要计算跨网格overlap，必须另行实现一个不被MATLAB/Octave experiment entry调用、不回写canonical
science、只读`run-007` immutable caches与`run-008` fields的reviewer audit路径，并再次完成Researcher
theory-to-code与同一Skeptic spec-to-code review。它只能使用`resource.tsv`所示scientific elapsed之后的
$2700\ \mathrm{s}$正剩余量，且两阶段RSS峰值均不得越过3,221,225,472 B；否则诚实登记
`IDENTITY_AUDIT_UNAVAILABLE`。本节不授权该路径、sealed comparison或effectivity。

## 46. 2026-09-01 candidate-7 reviewer-side identity audit 冻结合同

### 46.1 Scope, target consistency and authority

review §BF已核验`run-008/execution-001`为合法、已消费的pure-FEM scientific run：5/5 solves，canonical winner为
candidate 3，$k_{30}=0.78423535336082628$，whole-command wall为35.917169 s，aggregate peak RSS为
1,073,594,368 B。本节不改写这些canonical事实，也不授权新的FEM solve、MATLAB/Octave entry、BIE读取、profile fit或
effectivity comparison。

§43.3原文字只允许canonical winner与旧candidate 7相同时继续profile；而用户的样本外问题是检验**旧candidate 7所代表
的同一FEM mode**在$s=30$层的延续。由于threshold-free pure-FEM total rank可合法把另一个低频branch排第一，这两者并非
同一个selection question。若坚持原限制，即使field identity把旧candidate 7唯一匹配到另一个新component，也会错误阻止
用户预注册的same-mode refinement问题。因此本节作如下最小优先修订：

1. canonical pure-FEM winner candidate 3及其$\lambda_{30},k_{30}$永久不变，review audit不得重排或回写它；
2. audit若仅凭FEM field evidence把旧candidate 7唯一匹配到一个`run-008` component，则从该既有component按同一envelope
   midpoint规则派生`lambda30_candidate7`与`k30_candidate7`；
3. 若该component不是candidate 3，保留§43.3的selection事实
   `SELECTED_BRANCH_MISMATCH / ALTERNATE_MATCH_IDENTIFIED`，但它不再禁止candidate-7 profile；经post-audit review确认
   identity后，`k30_candidate7`而非canonical winner的$k_{30}$可接入旧三点FEM profile及随后late BIE位置比较；
4. 该修订不允许用旧$k$值、frequency proximity或BIE选择component。identity不唯一时不产生`k30_candidate7`，profile与
   BIE继续禁止。

这是目标变量澄清，不是active selection变更。§§43--45中与第3点冲突的“alternate component一律禁止profile”文字以本节
为准；continuous model、weak form、canonical ranking、资源和claim boundary均不重开。

### 46.2 Exact read-only inputs and implementation boundary

未来audit只允许读取以下immutable files，路径由audit source所在`test/i4/femref-a1/`相对解析，不搜索其他output：

- `output/run-007/execution-001/scientific-result.mat`，schema必须为`i4a-diagnostic-ranking-v2`；
- `output/run-007/execution-001/work/mesh-defect-N5-s24-g48.mat`；
- `output/run-007/execution-001/work/fine-p01.mat`、`fine-p05.mat`、`fine-p09.mat`、`fine-p13.mat`、
  `fine-p17.mat`，且五个phase必须依次为$0,\pi/4,\pi/2,3\pi/4,\pi$；
- `output/run-008/execution-001/scientific-result.mat`，schema必须为`i4a-s30-refinement-v1`；
- `output/run-008/execution-001/fields.mat`，schema必须为`i4a-s30-fields-v1`。

audit实现限定为`identity_audit.py`及fixed no-argument `run_identity_audit.pl`，可对README/SYMBOLS作机械同步；不得修改
MATLAB source、runner、canonical artifacts或历史output。Python须以`/usr/bin/python3 -I -S`运行，仅使用stdlib，
通过`ctypes`直接调用
`/Applications/MATLAB_R2023b.app/bin/maca64/libhdf5-1.8.8.dylib`读取MATLAB v7.3 HDF5；禁止`numpy`、`scipy`、
`h5py`及任何下载依赖。decoder只实现本节allowlisted numeric/logical/char/struct/cell/reference/complex字段，必须遵守
MATLAB column-major dimensions、`MATLAB_class`和`#refs#`引用；未知class、dangling ref、schema/id/shape不一致均使
`audit_terminal=IDENTITY_AUDIT_UNAVAILABLE`，不得猜测或按频率补对象。

唯一可写leaf为create-once
`output/run-008/execution-001/review-audit/identity-001/`；terminal files只允许
`identity-audit.json`与最小`resource.tsv`，不得回写`scientific-result.mat`、`fields.mat`、work caches或
`run-summary.csv`。计算在memory中完成后才以exclusive create-once方式发布RFC 8259 JSON；missing值写`null`并配套
status，禁止非标准`NaN`。任何已有`identity-001` leaf均fail closed，不得覆盖或auto-retry；真实operational failure的
后续处置必须另经Researcher--Engineer--Skeptic授权，本节不预授权`identity-002`。

### 46.3 Old candidate-7 reconstruction

audit在旧scientific artifact中按字段`candidate_id==7`查找candidate，不得按array position猜测；取其
`realization_ids`后，只保留对应object同时满足

$$
\texttt{configuration}=\texttt{fine},\qquad
\texttt{theta\_index}\in(1,5,9,13,17).
$$

每个目标index必须恰有一个object，`solve_id`必须分别为`fine-p01,p05,p09,p13,p17`，其`mesh_id`必须为
`defect-N5-s24-g48`。从object读取`root_indices`、dimension、$lambda/k$ envelopes、localization和parity；从对应
spectrum cache读取同一`root_indices`的`vectors_full`列，并逐项核对cluster ids、frequencies/eigenvalues与compact
object一致。旧tracking还必须证明candidate 7的`fine` objects在完整$	heta_{17}$ metadata中具有相邻continuation chain；
这里不读取另外12个field caches。

旧common-core representation严格重建既有MATLAB规则：在
$[-2.5,2.5]\times[-0.5,0.5]$的$161\times65$ tensor grid上使用trapezoidal weights；移除到
$x=-2,-1,1,2$四个radius-$0.2$ interfaces距离不超过$10^{-12}$的点；用$q=17$ inside、$q=1$ outside加权。
对旧mesh作P1 barycentric interpolation；边界点在所有满足barycentric tolerance的triangles中先最大化最小
barycentric coordinate，再取最小triangle index，连续P1 trace不允许随triangle choice改变结果。找不到covering triangle、
nonfinite field或nonpositive weight均使audit unavailable。

### 46.4 Per-twist overlap and deterministic assignment

在每个目标twist上，不只重建candidate-7 object，还重建旧`fine` configuration中全部与$W_3$相交objects的subspaces；
新侧使用`run-008/fields.mat`同twist的全部objects。两侧每个sample matrix $S$分别以同一positive weights形成
$G=S^*WS$，要求Hermitian finite positive definite，再作right-Cholesky normalization。跨网格pair的matrix为

$$
A_{ij}=\widehat S_{7,i}^*W\widehat S_{8,j},
$$

并保存全部principal singular values及$O_{ij}=\min\sigma(A_{ij})$。小型Gram/SVD只可用确定性pure-Python
Cholesky与cyclic Hermitian-Jacobi实现；固定double arithmetic、cyclic index order及终止标准，未收敛则audit unavailable，
不得降低§43阈值。工具按twist stream input，不能同时materialize五个48-field caches。

每个twist在完整old-fine/new-$s30$ object inventories上执行与scientific source相同的dummy-augmented
maximum-total lexicographic assignment。真实pair tuple依次为

$$
(-O_{ij},0,d_k,\text{new root},\text{old object id},\text{new object id}),
$$

birth/death tuple的第二项为1；$d_k$只作既有tie-break，绝不作identity gate。对于candidate-7目标row，assigned pair还必须
是strict mutual best：其overlap须严格大于同row和同column所有其他finite overlaps；exact tie为ambiguous。JSON须保存每个
twist的old/new object ids、root indices、dimensions、full overlap与frequency-distance matrices、assignment pairs、目标pair的
全部singular values、row/column runner-up与strict gaps、阈值和pass flags。

### 46.5 Continuation, localization, parity and exact statuses

五个candidate-7目标pairs只有同时满足下列条件才支持same-mode identity：

1. 五个pair均为maximum assignment中的strict mutual best；simple--simple时$O\ge0.90$，任一cluster时
   $O\ge0.80$；
2. 五个matched new object ids属于同一个`run-008` component，且该component有连接五个twists的四条相邻edges；旧侧
   candidate 7也通过§46.3的fine-chain metadata检查；
3. 五对old/new localization triples均finite；JSON逐点保存old值、new值、signed difference及两侧classification。弱或跨
   threshold变化只作caveat，不取消identity；
4. $artheta=0,\pi$两端old/new parity均available且even/odd labels逐端一致；中间twists parity保持not applicable。

若满足且所有对应dimensions相同，`candidate7_identity_status=SAME_MODE_SUPPORTED`；若仅有multiplicity变化但cluster
principal-overlap条件通过，则为`SAME_MODE_SUPPORTED_WITH_MULTIPLICITY_CAVEAT`。任一required evidence缺失、非唯一、
低overlap、continuation不闭合或endpoint parity冲突时为`IDENTITY_AMBIGUOUS`；输入/HDF5/linear-algebra不可执行时为
`IDENTITY_AUDIT_UNAVAILABLE`。不得把位置差异单独解释为`DIFFERENT_MODE`。

另保存`selection_relation`：identity component等于canonical winner时为
`PURE_FEM_WINNER_IS_IDENTITY_COMPONENT`；不等时为
`PURE_FEM_WINNER_DIFFERS_IDENTITY_COMPONENT`，并同时保存§43事实
`SELECTED_BRANCH_MISMATCH / ALTERNATE_MATCH_IDENTIFIED`；无唯一identity component时为
`NO_UNIQUE_IDENTITY_COMPONENT`。

在两种`SAME_MODE_SUPPORTED*`状态下，audit从identity component全部五个realizations的eigenvalues重新形成
$\Lambda_{30}^{(7)}$并定义

$$
\lambda_{30}^{(7)}=\frac{\min\Lambda_{30}^{(7)}+\max\Lambda_{30}^{(7)}}{2},\qquad
k_{30}^{(7)}=\sqrt{\lambda_{30}^{(7)}}.
$$

JSON字段名固定为`lambda30_candidate7`和`k30_candidate7`，并与run-008 science中同一candidate的stored publication
scalar交叉核对；其他status下两字段为`null`。`profile_gate`仅可为
`ELIGIBLE_AFTER_POST_AUDIT_REVIEW`或`NOT_ELIGIBLE`。工具不得包含或读取旧三点scalar、prediction或BIE值，因而不能自行
执行profile或sealed comparison。

### 46.6 JSON evidence, resource budget and gates

`identity-audit.json`至少包含：schema/version与exact input ids；candidate-7筛选表；五个old/new inventories；全部per-twist
overlap/assignment evidence；old/new continuation edges；localization/parity tables；canonical pure winner的只读identity；
matched component id；`candidate7_identity_status`、`selection_relation`、`lambda30_candidate7`、
`k30_candidate7`、所有caveats和`profile_gate`。JSON不得包含BIE/estimator数据、effectivity或certified wording。

统一预算以已消费scientific wall 35.917169 s和peak 1,073,594,368 B为起点。audit controller的唯一wall predicate为

$$
35.917169+T_{\mathrm{audit}}\ge2700,
$$

即从audit command启动起不可重置的剩余2664.082831 s；唯一memory predicate为audit process-tree RSS达到
3,221,225,472 B，combined peak记录为旧peak与audit peak的最大值。不得添加更低门、forecast、stall、guard、reserve或
grace。`resource.tsv`只记录prior/audit/combined wall、prior/audit/combined peak及terminal。§BF的read-only HDF5检查少于
25 s、peak 171,982,848 B；即使对streamed full assignment保守预估600 s和1.5 GiB，combined约635.92 s、1.5 GiB，仍低于
授权上限，因此没有prospective resource blocker，该估计不是停止门。

同一Engineer只可在本节边界内实现上述两个reviewer-side files及机械文档同步。实现后必须先由Researcher完成
theory-to-code audit，再由同一Skeptic完成spec-to-code/resource review；两者通过前不得执行identity audit。执行后仍须由
同一Skeptic审查JSON与resource artifacts；只有该post-audit review接受`SAME_MODE_SUPPORTED*`，才可在下一道明确授权中
使用`k30_candidate7`作四点profile和late BIE位置比较。任何阶段均不授权estimator/effectivity。

**Researcher prospective decision: `GO TO THE SAME SKEPTIC FOR §46 DESIGN REVIEW / IDENTITY-AUDIT IMPLEMENTATION AND EXECUTION NOT YET AUTHORIZED`.**

### 46.7 Deterministic floating-point completion

为避免Engineer自行选择数值规则，取binary64 $\epsilon=2^{-52}$。barycentric admissibility固定为每个coordinate落在
$[-64\epsilon,1+64\epsilon]$；多triangle命中时先最大化最小barycentric coordinate，再取最小triangle index。
两侧weights数量必须相同且max absolute difference不超过$10^{-14}$。Gram Hermitian relative defect上限沿用
$5\times10^{-13}$，Cholesky每个pivot必须finite且严格为正。对$A^*A$的complex Hermitian cyclic-Jacobi按
$(p,q)$ lexicographic order逐sweep；当off-diagonal Frobenius norm不超过
$64\epsilon\max(1,\|A^*A\|_F)$时停止，最多$100m^2$ sweeps，其中$m$为矩阵阶数。小于0但绝对值不超过同一
$64\epsilon\max(1,\|A^*A\|_F)$尺度的最终eigenvalue截为0；更负或未收敛均登记
`IDENTITY_AUDIT_UNAVAILABLE`。这些只决定审查数值可复现性，不新增identity acceptance或资源gate。

## 47. 2026-09-01 §46 累计预算、assignment 与机械记号修订

本节只修正§46的三个机械/执行歧义；与§46冲突处以本节为准，其余identity、输入、输出、claim与gate均不重开。

1. §BF reviewer-side HDF5 inspection charge前瞻固定为25.000000 s。唯一cumulative wall hard predicate为

   $$
   35.917169+25.000000+T_{\mathrm{audit}}\ge2700,
   $$

   因而audit controller从自身启动起使用不可重置的absolute remaining deadline 2639.082831 s。不得把scientific或
   reviewer charge省略、重置或另立较低wall predicate。`resource.tsv`分别记录
   `scientific_wall_seconds=35.917169`、`review_wall_seconds=25.000000`、`audit_wall_seconds`和三者之和
   `cumulative_wall_seconds`。
2. Memory不作相加；`resource.tsv`分别记录scientific/review/audit peaks与
   `cumulative_peak_rss_bytes=max(scientific,review,audit)`，唯一hard predicate仍为aggregate audit process-tree RSS或该
   cumulative maximum达到3,221,225,472 B。不得新增较低RSS gate。
3. 每个twist的Hungarian/assignment目标是：对一个完整assignment中所有matched/dummy pairs的tuple逐分量求和，再对该
   summed tuple作lexicographic minimization。真实pair首项为$-O_{ij}$，故第一层目标严格等价于最大化所有真实matched
   pairs的**total overlap**；其后才依次应用dummy、frequency-distance、root和object-id tie terms。不得逐pair贪心。

§46中可能由控制字符导致歧义的两个记号权威解释为`$\Theta_{17}$`与`$\vartheta=0,\pi$`；这只修正Markdown/LaTeX
拼写，不改变对象或阈值。

**Researcher delta decision: `GO TO THE SAME SKEPTIC FOR §47 DELTA REVIEW / IDENTITY-AUDIT IMPLEMENTATION AND EXECUTION NOT YET AUTHORIZED`.**

## 48. 2026-09-01 §§46--47 identity-audit theory-to-code review

本节只记录对当前`identity_audit.py`、`run_identity_audit.pl`、`README.md`与`SYMBOLS.md`的静态映射；未读取任何
scientific artifact、BIE/estimator数据，未执行Python、Perl、MATLAB、Octave或controller。该review不授权执行。

### 48.1 已对齐的实现

1. `identity_audit.py:24--57,784--917`固定exact schemas、`run-007/run-008`与`execution-001`，按字段
   `candidate_id == 7`而非数组位置筛选旧candidate，并固定fine配置、twist indices $(1,5,9,13,17)$、exact solve ids、
   phases与mesh identities。该工具只审计已发布FEM fields，不重求或改变continuous model、fitted-$P_1$ weak form、物理参数
   或canonical pure-FEM selection；active source未发现BIE、estimator、Markdown或Git输入。
2. `identity_audit.py:920--1217,1382--1594`从旧mesh作确定性common-grid $P_1$ barycentric interpolation，使用正的
   $q$-weighted trapezoid weights，形成weighted Gram、lower Cholesky right normalization与全部principal overlaps；五个
   twists均使用完整field-bearing old/new inventories。assignment是完整dummy-augmented全局lexicographic optimization，随后
   检查strict mutual best、相邻continuation、localization与endpoint parity；diagnostic不被frequency proximity替代。
3. `identity_audit.py:1630--1718`仅在`identity_supported`时重建identity component的
   `lambda30_candidate7`/`k30_candidate7`并开放`profile_gate`；否则这些scalars保持`null`且profile不可进入。工具未包含旧三点
   profile、BIE scalar或effectivity步骤。
4. `run_identity_audit.pl:10--47,59--149,151--230`固定无参数命令、create-once
   `run-008/execution-001/review-audit/identity-001`、absolute remaining deadline $2639.082831\,\mathrm{s}$、aggregate audit
   process-tree RSS hard upper $3221225472$ bytes，以及scientific/review/audit/cumulative wall和peak-by-maximum记录；未发现较低
   wall/RSS、forecast、stall或guard gate。`README.md:195--221`与`SYMBOLS.md:74--91`正确把该路径标为implemented but not run，
   且明确不改写canonical science。

### 48.2 必须有界修复的实现偏差

1. **Assignment tie-break blocker.** §46.4冻结与scientific source相同的frequency-envelope distance；scientific helper
   `run_i4_1a_refine.m:1839--1840`为`max(abs(first - second))`，但`identity_audit.py:1220--1225`对相交区间返回0并仅对
   不相交区间取gap。这会在total-overlap与dummy层相同时改变确定性的assignment。最小修复是让audit helper使用同一endpoint
   max-absolute-distance；它仍只作既有tie-break，不得成为identity gate或 proximity tuning。
2. **Unsupported-identity publication blocker.** `identity_audit.py:1561--1594`可仅凭assigned ids得到
   `matched_component`，而`identity_audit.py:1619--1628`在`identity_supported == false`时仍可能发布
   `PURE_FEM_WINNER_*_IDENTITY_COMPONENT`及`ALTERNATE_MATCH_IDENTIFIED`。这与§46.5“无唯一受支持identity component时发布
   `NO_UNIQUE_IDENTITY_COMPONENT`”冲突。最小修复是仅在`identity_supported`时发布identity component及selection relation；
   否则public `matched_component_id`为`null`、`selection_relation=NO_UNIQUE_IDENTITY_COMPONENT`、`selection_fact=null`。
   若需保存assignment-only线索，只能另列明确的provisional evidence字段，不得把它命名为identity或使profile gate可达。

其余candidate-7字段选择、五twist field overlap、common-grid representation、Gram/principal-overlap、continuation/localization/parity、
conditional $k_{30}^{(7)}$、create-once publication与累计资源合同在本次静态范围内为`ESTABLISHED`。上述两项会分别改变冻结
assignment和在证据不足时的claim，因此不是style caveat。

**Researcher theory-to-code decision: `REVISE`.** Engineer只需修复§48.2两个source-local点；之后由同一Researcher作delta
mapping，再移交同一Skeptic完成spec-to-code/resource review。Skeptic明确授权前不得执行identity audit。

## 49. 2026-09-01 §48.2 bounded delta review

本节只复核§48.2的两个source-local修复；§48.1已通过部分不重开。未读取artifact、BIE或estimator，未执行audit或任何
数值程序，本节不授权执行。

1. `identity_audit.py:1220--1221`现计算
   `max(abs(first[0] - second[0]), abs(first[1] - second[1]))`，与scientific helper
   `run_i4_1a_refine.m:1839--1840`的`max(abs(first - second))`逐endpoint一致。该量仍只进入既有assignment tie-break，
   没有新增proximity gate。
2. `identity_audit.py:1587--1597,1615--1627`先形成`identity_supported`，随后仅在该值为true时公开identity component与
   `PURE_FEM_WINNER_*` relation。unsupported路径固定
   `matched_candidate_id=None`、`selection_relation=NO_UNIQUE_IDENTITY_COMPONENT`、`selection_fact=None`；
   `identity_audit.py:1708--1717`把这些降级值写入public JSON，并继续保持conditional scalars为`null`及
   `profile_gate=NOT_ELIGIBLE`。内部assignment-only component没有以identity字段对外发布。

两项§48.2 blocker均已关闭，且差分没有改变连续模型、field identity阈值、assignment层级、资源合同或publication namespace。

**Researcher delta decision: `PASS / GO TO THE SAME SKEPTIC FOR SPEC-TO-CODE AND RESOURCE REVIEW`.** 本节仅移交审查；
identity audit仍须等待同一Skeptic的明确授权，不得由Researcher自行执行。

## 50. 2026-09-01 §BI three-blocker bounded delta review

本节只复核§BI.3的三项Engineer修复；§48--49已通过的identity数学与claim mapping不重开。未读取scientific artifact、
BIE或estimator，未执行Python、Perl、audit或数值程序，本节不授权执行。

1. **HDF5 1.8 reference binding closed.** `identity_audit.py:219--233`把library load与binding的`OSError`、
   `AttributeError`或`TypeError`确定性路由为`AuditUnavailable`；`identity_audit.py:306--307`现绑定三参数
   `H5Rdereference(hid_t, H5R_type_t, const void *)`并返回`hid_t`，`identity_audit.py:434--454`以dataset id、object
   reference type 0及reference buffer调用，negative target仍降级为`HDF5_DANGLING_REFERENCE`。旧的
   `H5Rdereference2`调用已从active source消失，不再存在uncaught missing-symbol路径。
2. **Run-008 compact schema closed.** `identity_audit.py:97--104`从旧object schema明确删除仅run-007具有的
   `configuration`，再只为`fields.mat`扩展common-core数组；`identity_audit.py:165--196`分别把
   `NEW_COMPACT_OBJECT_SPEC`用于run-008 `scientific-result.mat`、把`NEW_OBJECT_SPEC`用于field authority。
   `identity_audit.py:674`对compact record的缺省configuration只形成空诊断值，不把它重新设为required field；因此不会再把
   合法run-008 compact inventory误报为schema unavailable。
3. **Hard-wall terminal publication closed.** `run_identity_audit.pl:23--33`仍只从同一start形成absolute
   $2639.082831\,\mathrm{s}$ remaining deadline；`SIGALRM`只置`wall_alarm_fired`并立即SIGKILL target，不再`_exit`。
   `run_identity_audit.pl:65--125`在process-table、RSS与reap判断前后优先检查同一flag/deadline，
   `run_identity_audit.pl:128--162`完成child reap/dead confirmation后再次优先冻结
   `WALL_HARD_LIMIT_REACHED`，再由唯一`write_resource`发布terminal并nonzero退出。唯一resource uppers仍为累计2700 s与
   3,221,225,472 B；1 s sampling只是观测cadence，不是lower wall/RSS、stall、forecast、reserve或grace gate。

三项§BI blocker均由source-local差分关闭；未发现其改变candidate-7 identity规则、continuous model、publication namespace或
累计资源语义。

**Researcher delta decision: `PASS / GO TO THE SAME SKEPTIC FOR FOCUSED PRE-EXECUTION RE-REVIEW`.** 是否执行只能由同一
Skeptic明确授权；本节自身不授权创建或运行`identity-001`。

## 51. 2026-09-01 `identity-001` sandbox operational failure and bounded recovery

本节只处理第一次获准audit command的host/sandbox执行失败，不重开§§46--50的FEM field-identity方法、阈值、assignment、
claim boundary或3 GiB memory upper。

### 51.1 Immutable failure classification

`identity-001`已create once并永久消费。其唯一artifact `resource.tsv`记录
`audit_wall_seconds=0.001110000`、`cumulative_wall_seconds=60.918279000`、
`audit_peak_rss_bytes=0`、`cumulative_peak_rss_bytes=1073594368`、
`controller_terminal=RSS_ENFORCEMENT_UNAVAILABLE`及`python_signal=9`；没有`identity-audit.json`。
直接原因是sandbox拒绝controller所需的`/bin/ps`并返回`Operation not permitted`，controller遂按冻结合同fail closed并终止
Python target。该结果权威分类为`HOST_SANDBOX_OPERATIONAL_FAILURE / PROCESS_TABLE_PERMISSION_DENIED`：它没有执行出FEM
field comparison或identity verdict，不是FEM、candidate-7 identity method、same-mode证据或数值资源的失败；0-byte audit peak
也不得解释为实际memory resolution证据。`identity-001`目录和leaf均保持immutable，不覆盖、不删除、不作为后续active science
input。

### 51.2 Exact bounded recovery identity and cumulative resources

同一`femref-a1/run-008/execution-001` scientific identity保持不变；下一且仅下一create-once reviewer audit id冻结为
`identity-002`，namespace为
`output/run-008/execution-001/review-audit/identity-002/`。Engineer只可机械地把controller的fixed audit id改为
`identity-002`，并把已消费`identity-001` wall charge纳入累计；`identity_audit.py`及其输入、schema、算法、status与输出合同
不得改变，也不得读取或复制`identity-001`。

唯一cumulative wall predicate前瞻修订为

$$
35.917169+25.000000+0.001110+T_{\mathrm{identity-002}}\ge2700,
$$

故`identity-002`从其command start起使用同一absolute、不可重置的remaining deadline
$2639.081721\,\mathrm{s}$。其resource record须分别保存scientific wall、review wall、immutable
`identity-001` operational wall、current `identity-002` wall及总和；不得把前次0.001110 s省略或重置。Memory仍按各阶段
aggregate peak的maximum核算；前次audit peak为0，唯一inclusive hard upper保持3,221,225,472 B。不得新增较低wall/RSS、
forecast、stall、reserve、guard或grace gate。

### 51.3 Execution context and gate

`identity-002`的exact runner command仍是在`test/i4/femref-a1`固定cwd执行
`/usr/bin/perl ./run_identity_audit.pl`，但必须在明确的unsandboxed/escalated context启动，使`/bin/ps -axo ...`可读取
完整process table并实施aggregate process-tree RSS authority。若该authority仍不可用，继续fail closed；不得绕过process-tree
RSS、改用较低proxy、自动重试、覆盖leaf或换新scientific run id。Engineer完成上述两处机械controller差分后，先由同一
Researcher作theory-to-code delta mapping，再由同一Skeptic作focused spec/resource review；只有Skeptic PASS可重新授权一次
`identity-002`执行。

**Researcher prospective decision: `GO TO THE SAME SKEPTIC FOR §51 DELTA REVIEW / IDENTITY-002 IMPLEMENTATION AND EXECUTION NOT YET AUTHORIZED`.**

## 52. 2026-09-01 `identity-002` cross-file authority clarification

本节只消除§51中“仅改controller id”与Python固定publication authority之间的矛盾；与§51冲突处以本节为准。科学输入、
HDF5 decoder、field-identity算法、threshold、assignment、status vocabulary、JSON其余schema、claim boundary与资源hard uppers
均不重开。

1. `identity_audit.py`中的fixed `AUDIT_ID`须机械改为`identity-002`；由该常量产生的JSON `audit_id`和唯一fixed publication
   path同时指向
   `output/run-008/execution-001/review-audit/identity-002/identity-audit.json`。不得保留任何active
   `identity-001` publication/collision target，也不得改变JSON的其他字段、含义或条件性scalar规则。
2. `run_identity_audit.pl`中的fixed `AUDIT_ID`、collision check、create-once leaf及`resource.tsv` path须机械统一为
   `identity-002`。Runner与Python必须在启动前静态同意同一namespace；不得由argument、environment或读取旧artifact动态选择
   id。`identity-001`及其leaf永久immutable，不得读取、复制、rename、覆盖或作为active audit input。
3. `README.md`与`SYMBOLS.md`只作机械同步：`identity-001`记录为已消费的sandbox operational failure，新的prospective
   create-once authority为`identity-002`；不得写成identity method或same-mode verdict，也不得声称已实现、已通过pre-run gate
   或已执行。
4. `identity-002/resource.tsv`的wall分项固定为
   `scientific_wall_seconds=35.917169`、`review_wall_seconds=25.000000`、
   `identity001_wall_seconds=0.001110`、current `identity002_wall_seconds`及其`cumulative_wall_seconds`总和。唯一wall hard
   predicate仍为

   $$
   35.917169+25.000000+0.001110+T_{\mathrm{identity-002}}\ge2700,
   $$

   current absolute remaining deadline为$2639.081721\,\mathrm{s}$。Peak分项同样记录scientific、review、
   `identity001_peak_rss_bytes=0`与current identity-002 peak，`cumulative_peak_rss_bytes`取四者maximum；唯一inclusive memory
   hard upper仍为3,221,225,472 B。不得省略前次charge、重置累计预算或新增较低resource gate。

上述机械差分须先由同一Engineer实现，再经同一Researcher作cross-file theory-to-code delta mapping，并交同一Skeptic完成
focused pre-execution review。实现和执行均不由本节授权。

**Researcher prospective decision: `GO TO THE SAME SKEPTIC FOR §52 DELTA REVIEW / IMPLEMENTATION AND IDENTITY-002 EXECUTION NOT YET AUTHORIZED`.**

## 53. 2026-09-01 §52 cross-file implementation delta review

本节只复核§52授权的机械实现；不重开decoder、identity算法或已通过的resource-controller逻辑。未读取artifact、BIE或
estimator，未执行Python、Perl、audit或数值程序，本节不授权执行。

1. `identity_audit.py:33--40,1677--1685,1739--1747,1759--1768`把complete、unavailable与fixed publication path的
   `AUDIT_ID`统一为`identity-002`；`run_identity_audit.pl:12--49`使用同一fixed id建立collision check与唯一create-once
   leaf。两端权威path均为
   `output/run-008/execution-001/review-audit/identity-002/`，未发现active `identity-001` publication target。
2. `run_identity_audit.pl:15--26,152--165,228--249`固定四阶段nonreset accounting：scientific
   35.917169 s、review 25.000000 s、immutable identity-001 0.001110 s与current identity-002 elapsed；absolute remaining
   deadline为2639.081721 s，cumulative wall为四者之和。Peak同样取scientific、review、identity-001 zero-byte observation与
   current identity-002 aggregate peak的maximum；唯一inclusive RSS hard upper仍为3,221,225,472 B。未新增较低resource gate。
3. Active Python input仍只有冻结的run-007/run-008 FEM authorities；runner只把identity-001的已审查wall/peak常量用于预算账目，
   不读取其目录或artifact。`identity_audit.py`相对§50审查快照除fixed `AUDIT_ID`外，decoder、schemas、field inventory、
   interpolation、Gram/principal overlap、assignment、continuation/localization/parity、status与conditional publication均无变化。
4. `README.md:195--228`与`SYMBOLS.md:74--92`一致记录identity-001为immutable sandbox operational failure、identity-002为
   prospective/not executed，并同步exact namespace、remaining wall与四阶段资源字段；没有宣称same-mode result或pre-run PASS。

§52的cross-file矛盾已关闭，且机械差分未改变scientific或identity claim。

**Researcher theory-to-code decision: `PASS / GO TO THE SAME SKEPTIC FOR FOCUSED PRE-EXECUTION DELTA REVIEW`.** 本节不授权
执行`identity-002`；只有同一Skeptic可给出一次性执行授权。

## 54. 2026-09-01 HDF5 1.8.12 member-name ownership diagnostic and bounded recovery

本节只处理§BN确认的operational HDF5 binding failure。检查为read-only/static：未加载scientific fields、BIE或estimator，
未执行audit或数值程序，未修改source。FEM field-identity方法、输入、threshold、assignment、status、claim boundary与3 GiB
hard upper均不重开。

### 54.1 Exact-library evidence and ownership contract

1. MATLAB app未随附可定位的`H5Tpublic.h`或`H5public.h`；因此不能把其他本机HDF5 header冒充bundle authority。Exact dylib
   `/Applications/MATLAB_R2023b.app/bin/maca64/libhdf5-1.8.8.dylib`的embedded strings三次确认版本1.8.12，文件名不是版本
   authority。
2. Local `nm -gU`确认该dylib导出`H5Tget_member_name`、`H5Tget_member_index`、`H5Tget_member_offset`、
   `H5Tget_member_type`、`H5MM_xstrdup`与`H5MM_xfree`，但不导出`H5free_memory`。Local
   `otool -tvV -p _H5Tget_member_name`显示compound/enum路径tail-call`H5MM_xstrdup`；
   `otool -tvV -p _H5MM_xstrdup`显示以libSystem `malloc`分配，`otool -tvV -p _H5MM_xfree`显示以libSystem `free`
   释放。Dylib与`/usr/bin/python3`的`otool -L`均列出`/usr/lib/libSystem.B.dylib`。
3. 精确1.8.12上游source/header合同与该binary行为一致：`H5Tget_member_name`返回新分配的name copy；
   `H5free_memory`是在1.8.13才加入，用于避免不同runtime allocator问题。官方release-specific说明见
   [HDF5 1.8 release information](https://support.hdfgroup.org/documentation/hdf5/latest/rel_spec_18.html)，精确tag source见
   [HDF5 1.8.12 H5T.c](https://github.com/HDFGroup/hdf5/blob/hdf5-1_8_12/src/H5T.c)。因此对当前固定macOS bundle，
   复制name后调用同一libSystem `free`或exact-dylib内部`H5MM_xfree`在ABI上均与实际allocator配对；但前者依赖共享
   libSystem事实，后者依赖非public internal symbol。两者可解释ownership，却都不是最小风险实现。

以上结论为`ESTABLISHED`的fixed-host ABI事实；不推广至Windows、不同HDF5 build或未来MATLAB版本。

### 54.2 Frozen allocation-free source repair

选定的最小修复是完全避免member-name allocation，而不是绑定任何deallocator：

1. 在`Hdf5MatFile._bind()`中删除`H5Tget_member_name`与不存在的`H5free_memory` bindings；新增public
   `H5Tget_member_index`，signature固定为`int H5Tget_member_index(hid_t, const char *)`。
2. `_read_complex()`仍先要求exactly two compound members，但不再按index取得allocated name。它依次以固定bytes
   `b"real"`、`b"imag"`调用`H5Tget_member_index`；两个返回index必须均nonnegative、互异且落在`[0,2)`，否则保持现有
   `HDF5_COMPLEX_TYPE_UNSUPPORTED/UNAVAILABLE` fail-closed语义。随后按所得indices调用原有`H5Tget_member_type`、
   `H5Tget_member_offset`、float-class与4/8-byte checks，其他read/decode逻辑不变。
3. Exact dylib已静态确认导出`H5Tget_member_index`，其local disassembly按name作`strcmp`并返回existing index，不分配caller-owned
   buffer。不得绑定internal `H5MM_xfree`、不得调用cross-version `H5free_memory`、不得泄漏`H5Tget_member_name`返回值，也不得
   用字段顺序假设替代`real/imag` name validation。

该修复只改变complex-member discovery的ownership实现，不改变decoder接受的数学对象、field values或identity算法。

### 54.3 Prospective `identity-003` lifecycle and non-reset resources

`identity-001`与`identity-002`均永久消费、immutable且不得作为active input。若本节经同一Skeptic设计审查通过，下一候选
create-once audit id才可冻结为`identity-003`，namespace为
`output/run-008/execution-001/review-audit/identity-003/`；Python、JSON `audit_id`、publication path、runner collision/leaf及
README/SYMBOLS必须机械统一。实现仍须经过Researcher theory-to-code与同一Skeptic pre-execution review，且只能沿用§51的
escalated context；本节不授权实现或执行。

Prior consumed wall为

$$
35.917169+25.000000+0.001110+2.053772=62.972051\ \mathrm{s}.
$$

故`identity-003`的唯一cumulative wall predicate与absolute remaining deadline为

$$
62.972051+T_{\mathrm{identity-003}}\ge2700,
\qquad
T_{\mathrm{remaining}}=2637.027949\ \mathrm{s}.
$$

Future resource schema须分别记录scientific、review、identity-001、identity-002与current identity-003 wall/peak，再形成wall sum与
peak maximum；identity-001/002的wall分别固定0.001110 s与2.053772 s，peaks分别0与966656 B。Prior cumulative peak仍为
1,073,594,368 B，唯一inclusive memory hard upper仍为3,221,225,472 B。不得重置前次charge或新增较低wall/RSS、forecast、
stall、reserve、guard或grace gate。

**Researcher prospective decision: `GO TO THE SAME SKEPTIC FOR §54 DESIGN REVIEW / IDENTITY-003 IMPLEMENTATION AND EXECUTION NOT AUTHORIZED`.**

## 55. 2026-09-01 §54/§BO bounded theory-to-code review

本节只复核§BO授权的allocation-free与`identity-003`机械实现。未读取artifact、BIE或estimator，未执行Python、Perl、audit或
数值程序；`identity-003` namespace仍不存在，本节不授权执行。

1. `identity_audit.py:296--307`已完全移除`H5Tget_member_name`、`H5free_memory`与internal deallocator binding，改为
   `H5Tget_member_index(hid_t, const char *) -> int`。`identity_audit.py:496--537`仍先要求exactly two members，分别按name
   查询`real/imag`，要求indices nonnegative、in-range、distinct，再沿用原`H5Tget_member_type`、float-class、offset、4/8-byte
   size与complex read checks；没有field-order假设、allocated name或ownership leak。
2. `identity_audit.py:33--40,1671--1679,1733--1741,1753--1762`把complete、unavailable、JSON `audit_id`与fixed
   publication path统一为`identity-003`；`run_identity_audit.pl:12--51`的fixed id、collision与create-once leaf一致指向
   `output/run-008/execution-001/review-audit/identity-003/`。Identity-001/002没有active input或publication path。
3. `run_identity_audit.pl:15--28,154--169,232--254`固定五阶段nonreset accounting：scientific 35.917169 s、review
   25.000000 s、identity-001 0.001110 s、identity-002 2.053772 s与current identity-003 elapsed；remaining deadline精确为
   2637.027949 s。五个RSS peaks分别记录并取maximum，prior peak仍1,073,594,368 B，唯一inclusive hard upper仍为
   3,221,225,472 B；未新增较低gate。
4. `README.md:195--232`与`SYMBOLS.md:74--92`正确区分两个immutable operational failures和prospective/not-executed
   identity-003，并同步namespace、allocation-free binding与五阶段资源字段。相对§53审查快照，除§BO明确授权的complex-member
   discovery、ID、resource字段与docs外，decoder其余schemas/paths、interpolation、Gram/principal overlap、assignment、
   continuation/localization/parity、status、conditional scalar与claim boundary均无变化。

§BO实现与§54完全映射，没有遗留implementation blocker。

**Researcher theory-to-code decision: `PASS / GO TO THE SAME SKEPTIC FOR FOCUSED PRE-EXECUTION REVIEW`.** 本节不授权执行或
创建`identity-003`；一次性execution authority只能由同一Skeptic给出。

## 56. 2026-09-01 prospective `profile-001` scalar postprocess

本节落实§BQ `PASS WITH CONDITIONS`后允许设计的candidate-specific scalar postprocess。它不是新FEM run，不读取或计算
field/eigenpair，不读取estimator，也不进行effectivity。Canonical pure-FEM winner仍是candidate 3；本节的$s=30$值只属于
经§BQ接受为旧candidate 7延续的candidate 9。所有输出均为empirical、non-certified observation。

### 56.1 Fixed identity, files and information isolation

唯一prospective create-once leaf固定为
`test/i4/femref-a1/output/run-008/execution-001/review-audit/profile-001/`，成功时且仅时包含按顺序发布的
`profile.json`与最后发布的`resource.tsv`。实现边界仅为两个新文件：

- `test/i4/femref-a1/profile_postprocess.m`；
- `test/i4/femref-a1/run_profile_postprocess.pl`。

MATLAB entry不得接受argument、environment-selected scalar或path，不得调用`load`、`read*`、`fileread`、Git、Markdown、
history或任何`output/`读取，也不得读取identity JSON。它只使用本节逐字冻结的literal scalars，在内存中计算后只写fresh leaf
中的`profile.json`；runner独占create-once collision/lifecycle与`resource.tsv`。不得读BIE以选candidate或调fit：BIE scalar已在
FEM identity和$k_{30}^{(7)}$冻结后才由§BQ接受进入本节，因此这里只作固定late positional comparison。

### 56.2 Frozen scalar inputs and direct derived quantities

MATLAB source固定

$$
s=(12,18,24,30),\qquad
k=(1.842941342508127,\,1.837659912216170,\,1.835680010800799,\,1.834721598133798),
$$

以及

$$
k_{30}^{\mathrm{pred}}=1.8347168036,\qquad
k_{\mathrm{BIE}}=1.832770289108157,\qquad
D_{\mathrm{old}}=0.0029097217.
$$

按finer-minus-coarser方向逐字计算并输出

$$
d_{12\to18}=k_{18}-k_{12},\quad
d_{18\to24}=k_{24}-k_{18},\quad
d_{24\to30}=k_{30}-k_{24},
$$

$D_{a\to b}=|d_{a\to b}|$及

$$
\rho_1=\frac{D_{18\to24}}{D_{12\to18}},\qquad
\rho_2=\frac{D_{24\to30}}{D_{18\to24}}.
$$

零分母只使对应ratio为JSON `null`并登记`UNDEFINED_ZERO_DENOMINATOR`，不是failure。样本外量固定为
$r_{\mathrm{pred}}=k_{30}-k_{30}^{\mathrm{pred}}$及$|r_{\mathrm{pred}}|$。Late BIE只输出
$D_{30,\mathrm{BIE}}=|k_{30}-k_{\mathrm{BIE}}|$和严格布尔
`D_30_BIE < D_old`；等号必须为false。不得把该boolean解释为effectivity、误差界或mode-selection证据。

### 56.3 Exact QR variable-projection fit

Profile模型保持§43.4的

$$
k(s)=k_\infty+C s^{-p},\qquad p=\exp(x)>0.
$$

对每个$x$形成$A(x)=[\mathbf 1,s^{-p}]$，固定用economy QR
`[Q,R]=qr(A,0)`和`[k_inf;C]=R\(Q'*k(:))`，再以
`SSE=sum(abs(A*[k_inf;C]-k(:)).^2)`作为唯一objective。只有$x,p,A,R,k_\infty,C,SSE$全部finite且$R$的两个diagonal
在binary64中均非零时，该endpoint为finite/full-rank；否则objective为`Inf`并按numeric-unresolved记录，不设置condition-number
或fit-acceptance threshold。

七个starts严格依序为

$$
x_0=\log(1/8,1/4,1/2,1,2,4,8).
$$

每个start独立运行同一`fminsearch`，options逐字为`TolX=1e-12`、`TolFun=1e-24`、`MaxIter=10000`、
`MaxFunEvals=50000`，不增加bounds、weights或其他termination rule。JSON保存七个start indices、$x_0$、endpoint $x$、$p$、
$k_\infty$、$C$、SSE和全部exit flags。Winner在所有finite/full-rank endpoints中按
`(SSE,p,start_index)`作ascending lexicographic最小选择；exitflag不参与排序。若winner的exitflag非正或根本没有finite winner，
`fit_status=FIT_NUMERICALLY_UNRESOLVED`；前一种仍报告finite winner scalars，后一种把winner index、$p,k_\infty,C,SSE$写为
JSON `null`。否则`fit_status=FIT_RESOLVED`。不存在以fit quality取消$k_{30}$、drifts、prediction或BIE comparison的路径。

### 56.4 Exact JSON and failure contract

`profile.json`固定`schema_version=i4a-candidate7-profile-v1`、`profile_id=profile-001`、
`terminal=PROFILE_POSTPROCESS_COMPLETE`，并至少包含：candidate context（old candidate 7/new candidate 9/canonical candidate 3）、
全部literal inputs、三段signed/absolute drifts、两个ratios及statuses、prediction residual及absolute value、七-start fit ledger、
winner与fit status、late-BIE absolute difference与strict boolean、`certification_status=EMPIRICAL_NON_CERTIFIED`、
`effectivity_performed=false`。所有JSON numbers必须finite；任何nonfinite/unavailable numeric只能编码为RFC 8259 `null`，不得出现
`NaN`或`Infinity` token。MATLAB须在全部计算和sanitization后一次写出该文件；不得写额外log、temporary、MAT或CSV artifact。

Fit rank deficiency、nonpositive exitflag或无finite endpoint是合法complete postprocess中的caveat，不消费另一profile ID。只有
source/dependency/MATLAB exception、nonfinite direct frozen arithmetic、2700 s/3 GiB hard stop、create-once collision或
profile/resource publication failure是terminal failure；均fail closed且不得伪造complete JSON。Leaf一经创建即消费
`profile-001`，成功或失败都不得覆盖、自动重跑或换ID；prelaunch collision不创建新leaf。

### 56.5 Runner, non-reset resources and gates

Runner固定无参数，在`test/i4/femref-a1`为cwd，以exact MATLAB_R2023b command
`/Applications/MATLAB_R2023b.app/bin/matlab -batch "profile_postprocess"`启动一次dedicated process group。它复用已审查的
absolute-deadline、recursive/PID-deduplicated aggregate process-tree RSS、fail-closed authority-loss、guarded kill/reap/dead与
create-once resource publication语义；必须在允许`/bin/ps -axo ...`的escalated/unsandboxed context执行。

Prior consumed wall和peak固定为

$$
T_{\mathrm{prior}}=92.655067\ \mathrm{s},\qquad
R_{\mathrm{prior}}=1073594368\ \mathrm{B}.
$$

唯一wall predicate为

$$
92.655067+T_{\mathrm{profile-001}}\ge2700,
\qquad
T_{\mathrm{remaining}}=2607.344933\ \mathrm{s},
$$

唯一memory predicate为current MATLAB process-tree RSS或
`max(1073594368,profile001_peak_rss_bytes)`达到3,221,225,472 B。`resource.tsv`最小字段固定为
`prior_wall_seconds`、`profile001_wall_seconds`、`cumulative_wall_seconds`、`prior_peak_rss_bytes`、
`profile001_peak_rss_bytes`、`cumulative_peak_rss_bytes`、controller terminal、MATLAB exit code与signal。不得重置prior charge，
不得增加较低wall/RSS、forecast、stall、cadence、reserve、guard或grace gate。基于run-008/identity stages，保守启动估计为
300 s与1.5 GiB，低于剩余预算；该估计仅支持prospective GO，不是stop或acceptance rule。

Runner仅在MATLAB natural zero exit且`profile.json`已发布时把terminal记为`NATURAL_EXIT`，随后create-once发布
`resource.tsv`；hard/operational/MATLAB/publication failure必须用明确non-success terminal并尽可能发布resource evidence。
Post-run仍须由同一Skeptic核验两个artifacts、预算、fit ledger、late comparison与claim boundary；不得同步为certified reference，
不得进入estimator/effectivity。

### 56.6 Implementation and review gate

同一Engineer只可在§56边界内新增上述两个文件；任何README/SYMBOLS状态同步须保持mechanical/prospective并由Skeptic明确纳入
实现授权。实现后先由同一Researcher完成scalar/formula/options/schema/controller theory-to-code mapping，再由同一Skeptic完成
focused spec-to-code/resource review。两道pre-run gate通过前不得创建或执行`profile-001`。

**Researcher prospective decision: `GO TO THE SAME SKEPTIC FOR §56 DESIGN REVIEW / PROFILE-001 IMPLEMENTATION AND EXECUTION NOT AUTHORIZED`.**

## 57. 2026-09-01 `profile-001` theory-to-code review

本节只静态审计`profile_postprocess.m`与`run_profile_postprocess.pl`对§56及review §BR的映射。未运行MATLAB、
Octave、Perl或postprocess，未创建或读取`profile-001` artifact，也未读取scientific output、BIE/estimator artifact、
Markdown作为active input或Git metadata。

1. **Frozen scalars and direct quantities map exactly.** `profile_postprocess.m:18--54`逐字固定
   $s=(12,18,24,30)$、四个candidate-7 identity-component $k$值、预注册$k_{30}^{\mathrm{pred}}$、late
   $k_{\mathrm{BIE}}$与$D_{\mathrm{old}}$。三段`diff(k_values)`方向为finer-minus-coarser，absolute drifts、两个
   consecutive ratios、signed/absolute prediction residual、late absolute distance与严格`<` boolean均与§56.2一致；
   zero denominator只产生`null`-eligible `NaN`和`UNDEFINED_ZERO_DENOMINATOR`，不形成新gate。
2. **QR variable projection and total order map exactly.** `:56--90,149--187`使用七个固定
   $x_0=\log(1/8,1/4,1/2,1,2,4,8)$、exact `fminsearch` options、$p=\exp(x)$、
   `qr(A,0)`、`R\(Q'*k(:))`和唯一SSE objective。`x,p,A,R,k_\infty,C,\mathrm{SSE}`的finite检查及
   exact nonzero diagonal-$R$检查实现§56.3的binary64 full-rank条件；`:73--89`仅在finite/full-rank endpoints中按
   `(SSE,p,start_index)` ascending lexicographic排序，exitflag不参与排序且只决定resolved/unresolved status。
3. **Schema, null downgrade and information isolation otherwise map.** `:92--125`保留old candidate 7/new candidate 9/
   canonical candidate 3的不同身份，发布七-start ledger、direct quantities、fit status、late comparison、
   `EMPIRICAL_NON_CERTIFIED`与`effectivity_performed=false`。`jsonencode(...,'ConvertInfAndNaN',true)`把unavailable
   numerics降为RFC 8259 `null`，随后拒绝任何残留`NaN`/`Infinity` token。Source无argument、`load`、`read*`、
   `fileread`、history/BIE artifact、estimator、Markdown或Git读取；late-BIE literal不进入fit、winner或candidate选择。
4. **Runner identity and resource constants map, subject to the publication blocker below.**
   `run_profile_postprocess.pl:10--22,33--46`固定no-argument MATLAB_R2023b command、exact
   `run-008/execution-001/review-audit/profile-001` create-once leaf、92.655067 s prior charge、2607.344933 s remaining
   absolute deadline、1,073,594,368-byte prior peak与3,221,225,472-byte sole RSS upper。`:64--162,164--240`使用
   recursive PID-deduplicated process-tree RSS、fail-closed process-table handling、natural-zero/profile-present success及
   create-once `resource.tsv`；没有lower wall/RSS、forecast、stall、cadence或fit gate。

### 57.1 Publication blocker and bounded repair

`profile_postprocess.m:129`调用`fopen(profile_path,'x','n','UTF-8')`。本仓库已有同一MATLAB API的直接运行反例：
`research/projects/eig-apost/implementation/i3/review-3-2b.md:54--55`记录`fopen(path,'x')`返回
`Invalid permission.`并使已完成计算后的report publication失败。因此当前source会在所有scalar计算完成后确定性地无法创建
必需的`profile.json`；runner随后只能给出non-success terminal。该问题阻止§56的唯一主要交付物，分类为`blocker`，但它只是
一行publication implementation defect，不涉及profile数学、BIE隔离、schema、预算或claim boundary。

最小source-local修复是在`:129`使用MATLAB_R2023b支持的write permission，并继续由runner在启动前以原子`mkdir`独占全新的
`profile-001` leaf；不得改变path、payload、fit、lifecycle或新增artifact。由于leaf collision已经是create-once authority，
MATLAB只需在该fresh runner-owned leaf内创建`profile.json`，无需恢复历史output读取、临时文件或第二publication protocol。
修复后应由同一Researcher只复核该publication delta，再交同一Skeptic作focused spec-to-code/resource review。

**Researcher theory-to-code decision: `REVISE`.** 唯一确认的blocker是unsupported `fopen(...,'x',...)`；本节不授权执行、
不授权创建`profile-001`，也不授权新FEM、estimator或effectivity工作。

## 58. 2026-09-01 §57 publication delta review

本节仅复核§57指定的单行修复，不重开§57已通过的scalar、fit、schema、information-isolation、runner或resource mapping。
`profile_postprocess.m:126--142`保留exact `profile-001/profile.json` path、single write、byte-count与close checks，只把
`:129`的unsupported `fopen(...,'x',...)`改为MATLAB_R2023b支持的`fopen(...,'w','n','UTF-8')`。该entry没有因修复
增加任何output read或第二publication path；`run_profile_postprocess.pl:43--45`仍在fork前拒绝existing leaf并用一次原子
`mkdir`独占fresh `profile-001` directory，故`'w'`只会在本次runner-owned新leaf内创建目标文件，不会覆盖既有run artifact。
§57唯一blocker已经关闭，未发现该单行delta引入的新blocker。

**Researcher delta decision: `PASS / GO TO THE SAME SKEPTIC FOR FOCUSED SPEC-TO-CODE REVIEW`.** 本节不授权执行、
不授权创建`profile-001`，也不授权新FEM、estimator或effectivity工作。
