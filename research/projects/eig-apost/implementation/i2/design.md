# I2.1 同一离散对象上的单根隔离设计

## 1. 状态、范围与权威性

- Origin Skill: `academic-research-suite / experiment-agent`
- Origin Mode: `researcher--engineer consensus, independent skeptic review`
- Design ID: `I2.1-M1B-RIESZ-COUNT-V1`
- Design Status: `FROZEN METHOD 1B REVISION 2 / PRE-FULL SKEPTIC REVIEW PENDING`
- Freeze Date: `2026-08-13`
- Claim Boundary: `CONDITIONAL EMPIRICAL FINE-M48 FINITE-DIMENSIONAL ROOT COUNT`

本文件冻结 I2.1 的首次正式方法。Researcher 与 Engineer 在读取项目现状、I1 正式收尾、
I1 设计/审查和现有实验实现后，对这里的数学对象、实现路径、阈值、资源和停止规则达成
一致。独立 Skeptic 第二轮设计审查曾给出初始实现授权；`smoke-a1` 跑后触发本文件第 17 节
Revision 1，`smoke-a2` 随后通过跑前与跑后独立审查。跑后发现的 full-parent 自引用问题由
第 18 节 Revision 2 修复；该冻结候选仍须 Skeptic 另行审查，在此之前不得运行 full。

本阶段只回答：I1 实轴 dip 周围的同一个冻结有限维矩阵族，在指定小圆盘内是否有且只有
一个按代数重数计的 determinant zero。它不定位根，不计算向量或导数，不判断几何重数，
也不形成连续物理本征值或后验误差估计。

本文件冻结后不得为了得到预期答案而改半径、节点数、参数语义、阈值、矩阵表示或结果
解释。若 Method 1B 失败，输出和本设计保持不变；第二种方法只能作为新章节追加，重新经过
Researcher--Engineer 协商和 Skeptic 审查后才能实现、运行。

本设计冻结的 parent artifacts 只有以下四个；配置必须逐项写入路径和本节 SHA-256，运行
时重新计算并完全匹配，不得在同类输出中临时选择另一个“更好”的 parent：

| Role | Frozen artifact | SHA-256 |
|---|---|---|
| I1.3 row selectors / candidate | `test/i1/k-scan/output/zoom2/result.mat` | `e168638af0536f2671f0fd9d34a37432926953a5b722cbef6da3eaa1fe96678a` |
| I1.4 affine/QZ pilot lineage | `test/i1/k-ready/output/pilot-a3/result.mat` | `6a4044934f29de74c53684ecb1fb42d64eac0888d21a16c925c28a05deb85857` |
| I1.4 positive sampled-disk parent | `test/i1/k-ready/output/v4-a1/result.mat` | `c4730ba11fb6b8bee5ff72513279b1db0869e752953be86a79694a42c3a1ab34` |
| I1.4 conditional negative closure | `test/i1/k-ready/output/v5-a1/result.mat` | `c250c4cef7ffe5bd51c1465d339663c975db6f7fe7375da0096736efdedaf928` |

## 2. 与 I1 的对象衔接

### 2.1 冻结模型和离散层

I2.1 原样继承 I1.4 的模型及约定：

- identical sharp-disk periodic leads；
- homogeneous missing center column，当前 center density dimension 为 $n=0$；
- Bloch parameter $\beta=0.5$，period $d=1$，disk radius $R=0.2$；
- reference planes $X_L=-0.5$、$X_R=0.5$；
- proxy height $H=1.1$、proxy distance $0.2$；
- trace cutoff $M=48$，故 $K=2M+1=97$；
- 只用 I1 的 `fine` spatial level：`ntot=256`、`N_side=160`、
  `N_top=160`、`N_proxy_edge=80`、`M_pw=32`；
- 沿用 I1 的 Fourier order、unknown/row order、wall normals、phase convention、
  anchored square-root branches、original/reversed QZ cluster、fixed row selectors、
  affine proxy chart/rank 和 solver policy。

不得混入 `coarse` level，不得在 contour 节点重新按模选择 QZ cluster、重新选 fixed rows、
改变 proxy rank、改变 branch signs、改用 balancing、SVD truncation、`pinv` 或其他 solver。

### 2.2 圆盘与主矩阵

圆心和半径直接取 I1.3/I1.4 的冻结值：

$$
k_c=1.8327703475952146,
\qquad
r_0=3.8146972647368216\times10^{-7}.
$$

边界按逆时针参数化：

$$
\Gamma:\quad k(\theta)=k_c+r_0e^{\mathrm i\theta},
\qquad 0\leq\theta<2\pi.
$$

科学主对象是同一套 I1 代码合同产生的、未平衡的 safe-DtN 矩阵

$$
A_{\mathrm{def}}^D(k)\in\mathbb C^{194\times194}.
$$

禁止对含 $k$-dependent physical/Sobolev Gram、奇异值、绝对值、动态 pivot scaling 或
其他非解析权重的矩阵做 winding。$388\times388$ 的 $A_{\mathrm{def}}^G$ 和已有 Schur
identity 只作异常诊断，不替换主对象，也不作为第二套科学计数。

### 2.3 I1 已给出和仍未给出的内容

I1 已给出固定 $M=48$ 的 sampled branch/QZ/chart/factor readiness、实轴 dip 及上述小圆盘，
但没有运行 contour count，也没有排除未采样的 evaluator poles。本设计不会把 I1 的采样
通过写成 pole-free theorem。`DERIVATIVE_AVAILABLE=false` 在 I2.1 保持不变。

## 3. 首选 Method 1B 的形成过程

最初讨论过“直接对 fixed-row 规范化后的 $\widehat D_\pm$ 计 winding”的草案。Skeptic 在
冻结前指出：若 raw QZ frame 为 $Z$、固定行块为 $HZ$，则

$$
\widehat D=D(HZ)^{-1},
\qquad
\operatorname{wind}\det\widehat D
=\operatorname{wind}\det D-\operatorname{wind}\det(HZ).
$$

所以 winding 为零可能只是两个内部零点相消，不能排除 DtN pole。该草案在设计冻结前已经
撤销，没有写代码、没有运行，不构成一次失败实验，也不是允许暗中切换的 Method 2。

Method 1B 增加一个成本受控的 generalized-pencil Riesz-projector screen，专门为 I1 的
fixed-row chart 提供不受 pointwise QZ gauge 污染的经验资格化；实际
$A_{\mathrm{def}}^D$ 仍由 I1 evaluator 合同组装，Riesz projector 不替换科学对象。

## 4. Gauge-free Riesz section

### 4.1 原始和反向矩阵铅笔

I1 的 one-cell scattering blocks 形成

$$
A(k)=
\begin{bmatrix}
-R_L&I\\ T_{LR}&0
\end{bmatrix},
\qquad
B(k)=
\begin{bmatrix}
0&T_{RL}\\ I&-R_R
\end{bmatrix},
$$

两者均为 $194\times194$。右侧 half-guide 使用
$A z=\lambda Bz$ 的单位圆内 cluster；左侧 half-guide 使用 reversed relation
$Bz=\mu Az$ 的单位圆内 cluster。两个 cluster 的维数都必须始终为 $K=97$。

对应的 exact spectral projectors 为

$$
P_+(k)=\frac{1}{2\pi\mathrm i}
\oint_{|\zeta|=1}(\zeta B(k)-A(k))^{-1}B(k)\,\mathrm d\zeta,
$$

$$
P_-(k)=\frac{1}{2\pi\mathrm i}
\oint_{|\zeta|=1}(\zeta A(k)-B(k))^{-1}A(k)\,\mathrm d\zeta.
$$

### 4.2 固定行 section

令 $H_+$、$H_-$ 为 I1 parent 冻结的两个 row-extraction matrices；令
$Z_{0,+}$、$Z_{0,-}$ 为 $k_c$ 处 I1 fixed-row 规范化后的 seed frames，因此
$H_\pm Z_{0,\pm}=I$。定义

$$
C_\pm(k)=H_\pm P_\pm(k)Z_{0,\pm},
$$

$$
Y_\pm(k)=P_\pm(k)Z_{0,\pm}C_\pm(k)^{-1}.
$$

若 Riesz range 在闭盘邻域解析、维数固定为 $K$，并且 $C_\pm$ 在盘内无 zero，则
$Y_\pm$ 是单值解析且满足 $H_\pm Y_\pm=I$。任何张成同一 range 的 QZ frame $Z$ 都满足

$$
Z(H_\pm Z)^{-1}=Y_\pm.
$$

因此这个比较不受 QZ 的任意右乘 gauge 影响。只有该资格化通过后，I1 fixed-row section
形成的 Dirichlet blocks $\widehat D_\pm$ 才允许作为解析 factor 计数。

### 4.3 梯形离散

取 $\zeta_j=e^{2\pi\mathrm i j/N_\zeta}$。由于
$\mathrm d\zeta=\mathrm i\zeta\,\mathrm d\theta$，projector action 必须包含
$\zeta_j$ 权：

$$
P_{+,N_\zeta}(k)Z_{0,+}
=\frac1{N_\zeta}\sum_{j=0}^{N_\zeta-1}
\zeta_j(\zeta_jB-A)^{-1}BZ_{0,+},
$$

$$
P_{-,N_\zeta}(k)Z_{0,-}
=\frac1{N_\zeta}\sum_{j=0}^{N_\zeta-1}
\zeta_j(\zeta_jA-B)^{-1}AZ_{0,-}.
$$

$N_\zeta=32$ 为主离散，$N_\zeta=16$ 必须严格取其偶数索引子集并复用同一批 LU；不得
以另一套旋转节点冒充嵌套比较。

## 5. 必须分别记账的解析 factors

| 对象 | 尺寸 | 数值或物理作用 | 为什么单独检查 |
|---|---:|---|---|
| affine proxy reduced factor $R=U^*A_{\rm proxy}V$ | $260$ | 冻结 rank 的 off-seed proxy correction 真正求逆对象 | 其 zero 会制造 cell evaluator pole |
| BIE factor $A_{QP}$ | $512$ | 从 boundary RHS 得到 density/field coefficients | 其 zero 不能当作 defect root |
| $\zeta B-A$，每个 $\zeta_{32}$ | $194$ | 右侧 Riesz range 的 resolvent | unit-circle crossing 会破坏 analytic cluster |
| $\zeta A-B$，每个 $\zeta_{32}$ | $194$ | 左侧 reversed Riesz range 的 resolvent | 同上 |
| $C_+$、$C_-$，各用 $N_\zeta=16,32$ | $97$ | 固定 seed section 是否覆盖当前 range | 其 zero 表示 fixed-row section 不可用 |
| $\widehat D_+$、$\widehat D_-$ | $97$ | safe-DtN 真正的 Dirichlet inverse | 其 zero 会成为 $A_{\mathrm{def}}^D$ pole |
| $A_{\mathrm{def}}^D$ | $194$ | I2.1 的冻结主矩阵 | 其可靠 winding 给最终 zero count |

raw $H_\pm Z$ 只记录 margin、condition、solve residual 和 row fingerprint，不做 winding；其
determinant phase 会受 QZ gauge 污染。graph `Cfactor` 与两个 $\widehat D$ blocks 重复，
不得作为“额外独立证据”重复计数。proxy full/shifted systems没有被求逆，只保留 I1 residual
门。所有 factor 都必须来自 anchored analytic matrix construction；evaluator unavailable
不得解释成 zero。

## 6. 二维采样与经验覆盖门

### 6.1 $k$ contour

full 只评估一次 64 个 unique boundary nodes：

$$
k_n=k_c+r_0e^{2\pi\mathrm i n/64},
\qquad n=0,\ldots,63.
$$

$N_k=32$ 必须严格使用 $n=0,2,\ldots,62$。两个离散使用同一 orientation 和 closure edge，
不得分别重算成两条可能漂移的 family。

### 6.2 每个采样 $k$ 上的完整 $\zeta$-arc screen

对 $N_\zeta=32$ 的每个节点，记录

$$
2\sin(\pi/64)\,
\|(\zeta_jB-A)^{-1}B\|_1<0.5,
$$

以及 reversed 侧的

$$
2\sin(\pi/64)\,
\|(\zeta_jA-B)^{-1}A\|_1<0.5.
$$

Neumann 条件在该采样 $k$ 上覆盖相邻 $\zeta$ 节点的半弧。它不能被省略或由节点 rcond
代替。

### 6.3 相邻 $k$ 节点的经验分辨率门

对每个 $\zeta_{32}$ resolvent 和每条相邻 $k$ edge，包括 $k_{63}\to k_0$，必须双向记录

$$
\|M(k_n)^{-1}[M(k_{n+1})-M(k_n)]\|_1<0.25,
$$

$$
\|M(k_{n+1})^{-1}[M(k_n)-M(k_{n+1})]\|_1<0.25.
$$

该门与严格嵌套的 $N_k=32/64$ winding、phase closure、QZ separation 和 projector parity
一起构成 sampled empirical $k$-arc-resolution screen。它不控制节点间曲率或非常窄的
excursion，因而不是连续边界或闭盘 pole-free 定理。若比值接近阈值、32/64 变化异常或
QZ separation 变弱，$N_k=128$ 只能作为需要重新评估成本并重新审查的 blocker 解决手段；
本方法不得自动加点。

## 7. 稳定 log-determinant 与 winding

对每个方阵 $F$ 使用 complex LU，约定 $PF=LU$。不显式形成 `det(F)`。记录：

- permutation parity；
- $\sum_j\log|U_{jj}|$；
- permutation parity 与 $U$ diagonal 合成的 wrapped phase；
- $\|PF-LU\|_F/\max(1,\|F\|_F)$；
- `rcond(F)`、最小相对 pivot、finite flag 和 object identity。

若 $p_n$ 为节点 phase，则相邻 phase increment 为 principal wrapped difference，并包含最后
节点回到第一节点的 closure edge。定义经验保守的 phase diagnostic

$$
\delta_n=\min\left\{\pi,
\frac{m\max(m\epsilon,\mathrm{LUres}_n)}{\mathrm{rcond}(F_n)}
\right\},
$$

其中 $m$ 是矩阵阶数。每个参与 winding 的节点必须满足 $\delta_n\leq10^{-2}$，每条边必须
满足

$$
|\operatorname{wrap}(p_{n+1}-p_n)|+\delta_n+\delta_{n+1}<\pi/2.
$$

总和除以 $2\pi$ 后到最近整数的距离必须不超过 $10^{-6}$。这个 diagnostic 不是严格证明的
determinant-phase 误差上界；它必须与下一节的 manufactured oracles 及 $N_k=32/64$ 稳定性
共同使用。$N_k=32$ 和 $64$ 的 rounded
counts 必须相同。可靠性门与期望 count one 无关；count 为 $0$ 或大于 $1$ 是科学结果，
不能触发调参。

## 8. 非循环 manufactured oracle

首次运行任何物理 evaluator 前，smoke 必须用与 full 完全相同的 LU、phase wrapping、closure、
winding 和 Riesz core 运行以下纯代数 oracle。不得另写一套只供 oracle 使用的简化 count
实现。oracle 只验证数值核心，不是第二种物理 count 方法，预计耗时小于 1 s。

令 oracle contour 为 $s_j=e^{2\pi\mathrm i j/N}$，取严格嵌套的 $N=32,64$。冻结：

1. `COUNT_ZERO`：$F_0(s)=\operatorname{diag}(2,3)$，CCW count 必须为 $0$；
2. `COUNT_ONE_ORIENTATION_PARITY`：令 $a=0.2+0.1\mathrm i$、
   $Q=\begin{bmatrix}0&1\\1&0\end{bmatrix}$，
   $F_1(s)=Q\operatorname{diag}(s-a,2)$。CCW count 必须为 $+1$，同一 nodes 反向遍历必须
   为 $-1$；每点 LU log-magnitude/phase 还必须与解析式
   $\det F_1(s)=-2(s-a)$ 在模 $2\pi$ 意义下一致，以单独捕获 permutation-parity 错误；
3. `COUNT_TWO_MULTIPLICITY`：$F_2(s)=\operatorname{diag}((s-a)^2,3)$，CCW count
   必须为 $2$；
4. `BOUNDARY_SINGULAR_FAIL`：$F_b(s)=\operatorname{diag}(s-1,2)$，因 $s_0=1$ 正好落在
   contour 上，必须 fail-close 为 boundary/singularity failure，绝不能返回 count $0$；
5. `RIESZ_WEIGHT_AND_REVERSED`：
   $A_o=\operatorname{diag}(0.1,10)$、$B_o=I$。original projector 的 exact range 为
   $e_1$，reversed projector 的 exact range 为 $e_2$。用本设计含 $\zeta_j$ 权的同一
   $N_\zeta=16,32$ core，必须分别得到
   $P_+=\operatorname{diag}(1,0)$、$P_-=\operatorname{diag}(0,1)$；去掉
   $\zeta_j$ 权的 negative 必须以 Frobenius error 至少 $0.5$ 被拒绝。

前三项的 integer residual、方向和解析 phase/log-magnitude error 均不得超过 $10^{-12}$；
Riesz projector、idempotence 和 exact-range Frobenius error 均不得超过 $10^{-12}$。
boundary singular oracle 必须在 winding 汇总前被拒绝。阈值只由这些小矩阵的解析答案和
double-precision roundoff 决定，与物理目标 count one 无关。

输出逐项写入 `oracles.csv` 和 `gates.csv`。任一 oracle 失败，首失败为
`CORE_ORACLE_FAILURE`，停止所有物理 evaluator；不得修补 oracle expected value、跳过
negative 或使用另一套核心。

## 9. Projector、solve residual 与同一对象 parity

对每个 Riesz resolvent solve $MX=G$，包括 projector 的 $G=B$ 或 $A$ 以及相邻 $k$ edge
的 $G=\Delta M$，冻结 normalized backward residual

$$
\operatorname{res}_{\rm solve}(M,X,G)=
\frac{\|MX-G\|_F}
{\max\{1,\|M\|_F\|X\|_F+\|G\|_F\}}
\leq 10^3(194)\epsilon.
$$

solve residual、LU reconstruction residual、`rcond` 或 finite gate 任一失败，都使该
resolvent unavailable；其 phase 或 norm 不得进入 winding/arc 汇总。

在每个 $k_{64}$ 节点、每一侧，$N_\zeta=16,32$ 都要形成 $P_NZ_0$、$C_N$ 和
$Y_N=P_NZ_0C_N^{-1}$。必须检查：

1. $C_{16}$、$C_{32}$ 的 `rcond` 均不小于 $10^{-8}$；
2. 两个 $C_N$ 各自在 $N_k=32/64$ 上 winding 可靠且 count 为零；
3. $\|C_{32}^{-1}(C_{32}-C_{16})\|_2<0.5$；
4. 对 $N=16,32$，projector-action 嵌套差
   $\|(P_{32}-P_{16})Z_0\|_F/\max(1,\|P_{32}Z_0\|_F)\leq10^{-7}$，并且
   $\|Y_{32}-Y_{16}\|_F/\max(1,\|Y_{32}\|_F)\leq10^{-7}$；
5. 实现不形成或声称拥有完整 $194\times194$ 的 $P_N$；对 $N=16,32$，在相同 fixed
   seed range 上再次调用同一 Riesz-action core，令 $W_N=P_NZ_0$、
   $\widetilde W_N=P_NW_N$，明确检查 restricted idempotence defect
   $\|\widetilde W_N-W_N\|_F/\max(1,\|W_N\|_F)\leq10^{-7}$；另检查
   $\|P_NY_N-Y_N\|_F/\max(1,\|Y_N\|_F)\leq10^{-7}$。报告不得把这些 restricted
   action checks 写成 full-projector norm certificate；
6. 若 $\widehat Z_{\mathrm{QZ}}$ 是 I1 QZ fixed-row section，则
   $\|Y_{32}-\widehat Z_{\mathrm{QZ}}\|_F/
   \max(1,\|\widehat Z_{\mathrm{QZ}}\|_F)\leq10^{-7}$；
7. 两者 orthonormal range projectors 的 2-norm difference 不超过 $10^{-7}$；
8. $\|H_\pm Y_{32}-I\|_F/\sqrt K$ 及 I1 fixed-row residual 通过继承门；
9. original/reversed QZ 各为 $97/97$ stable/unstable、零 neutral/indeterminate，
   cluster separation、seed overlap、row fingerprints 和 branch fingerprints 均通过 I1 门。

这里的 $16/32$ convergence 和 parity 是 exact Riesz projector/chart 合同的经验资格化，不是
projector quadrature 的严格误差界。

## 10. 冻结阈值和最终验收逻辑

### 10.1 基础门

- runtime 必须是 MATLAB；`which('lsqminnorm')` 必须解析到实际公开实现并记录路径/版本；
- `pinv_calls=0`、`fallbacks=0`、`silent_rank_truncations=0`；
- off-seed `lsqminnorm=0`、off-seed proxy SVD/rank change 为零；
- branch/QZ/fixed-row/Dirichlet/Schur/proxy residual/BIE residual 门沿用 I1.4；
- $R$、$A_{QP}$、$C_\pm$、$\widehat D_\pm$ 的 `rcond` 不小于 $10^{-8}$；
- 每个 Riesz resolvent 的 `rcond` 不小于 $10^3(194)\epsilon$；
- 边界 $A_{\mathrm{def}}^D$ 的 `rcond` 不小于
  $10^3(194)\epsilon=4.3076653355456074\times10^{-11}$；
- 所有 dense values、log magnitudes、phases、uncertainties、residuals 和 ratios 均 finite。

### 10.2 计数门链

严格按以下顺序判定，前一层失败时不得继续把后一层结果解释成 root count：

1. runtime、source、solver、尺寸和 object ledger；
2. 全部 manufactured core oracles；
3. parent 和 frozen lineage；
4. 全部 64 节点的 evaluator、branch、QZ、fixed-row、rank、solve 和 residual health；
5. $R$ 和 $A_{QP}$ 在 $N_k=32/64$ 上均可靠 count zero；
6. 两侧 32 个 Riesz resolvents 的 $k$-winding 均为 zero，且双轴 arc screens 通过；
7. $P_{16}/P_{32}$、$C_{16}/C_{32}$、idempotence、fixed-row 和 I1 QZ parity 通过，
   $C_\pm$ 可靠 count zero；
8. $\widehat D_+$、$\widehat D_-$ 在 $N_k=32/64$ 上均可靠 count zero；
9. $A_{\mathrm{def}}^D$ 的 boundary separation 和 phase gates 通过，且 32/64 count 相同；
10. 只有最终 count 恰为 one，I2.1 才可记为条件性通过。

若步骤 1--9 的可靠性门全部通过而最终 count 为 $0$ 或大于 $1$，应分别报告
`ZERO_COUNT` 或 `MULTIPLE_COUNT`；它们不是实现失败，但会阻止 I2.2。

### 10.3 Failure taxonomy 与优先级

首个失败按门链顺序冻结，至少使用下列互斥主标签；次要现象可另列 diagnostics：

1. `PARENT_OR_PROVENANCE_FAILURE`；
2. `MATLAB_OR_SOLVER_FAILURE`；
3. `CORE_ORACLE_FAILURE`；
4. `BRANCH_QZ_CHART_DRIFT`；
5. `EVALUATOR_FAILURE`；
6. `PROXY_OR_BIE_FACTOR_COUNT`；
7. `RESOLVENT_SCREEN_UNAVAILABLE`；
8. `RIESZ_CHART_QUALIFICATION_FAILURE`；
9. `DIRICHLET_POLE_OR_FACTOR_COUNT`；
10. `BOUNDARY_TOO_CLOSE`；
11. `PHASE_UNRESOLVED`；
12. `NUMERICAL_INSTABILITY`；
13. `ZERO_COUNT`；
14. `MULTIPLE_COUNT`；
15. `TIMEOUT_OR_RESOURCE_STOP`。

`NaN`、solve failure、unavailable 或 pole evidence 永远不得编码成 zero。任何 failure 后不得
自动 retry、缩放半径、改变节点、放宽阈值或跳到另一方法。上述顺序只用于已经形成的科学
gates；运行中一旦触发 time/memory/stall stop，必须立即冻结
`TIMEOUT_OR_RESOURCE_STOP` 为首失败并保存 partial ledgers，不得把尚未形成的后续 gate
补记为 evaluator 或 phase failure。

## 11. 实现合同

所有新代码只放在 `test/i2/k-count/`；不得修改 package、`test/i1/`、I1 文档或方法稿。
实现使用 test-local I1.4 evaluator 的最小复制/改造，并在文件头记录 based-on source 和
差异。只构造 fine level，向 count core 暴露：$R$、$A_{QP}$、$A,B$、两侧 I1 normalized
frames、$H_\pm$、$Z_{0,\pm}$、raw/normalized QZ diagnostics、$\widehat D_\pm$、
$A_{\mathrm{def}}^D$、resolvent solve residual 及 $P_{16}/P_{32}$ metrics。

dense matrices 只在内存中用于当点 LU、Riesz action 和相邻 edge checks，不写入输出。每一
时刻只保留当前、前一和 closure 所需首节点数据；不得形成 $O(m^2)\times O(m^2)$ 的
Sylvester/Kronecker 辅助矩阵。

入口固定为：

```matlab
addpath(fullfile(pwd,'test','i2','k-count'));
run_i21('smoke');
```

`smoke-a2` 已在 Skeptic 完成 Revision 1 设计—实现一致性审查后运行。smoke 首先
运行第 8 节全部 oracles，再使用 seed 加四个 cardinal boundary nodes执行相同 evaluator、
LU、Riesz 和 ledger 路径；真实节点部分只检查尺寸、公式、门和计时，不产生科学 winding
verdict。它已通过跑后审查；Revision 2 另行注册 full tag、smoke parent hash 和 producer
digest，并冻结当前 full 实现。只有 Revision 2 再经 Skeptic 审查，才允许运行 full。

## 12. 资源预算和停止规则

| 项目 | 冻结预算 |
|---|---:|
| smoke 目标 / hard stop | $120$ s / $300$ s |
| full 目标 / hard stop | $1200$ s / $1800$ s |
| I2.1 全部正式 MATLAB 运行总上限 | $7200$ s |
| 峰值内存上限 | $512$ MiB |
| 最大单个方阵 | $512\times512$ |
| 既有最大矩形 dense array | $1920\times450$ |

其中 $1920\times450$ 是只用于 residual diagnostic、不被求逆的 shifted proxy array；
常规 collocation proxy array 为 $960\times450$。两者尺寸都必须进入 runtime object ledger，
不得因 shifted array 不参与 winding 而从资源账本中遗漏。
这是 2026-08-13 的资源账本纠错：它只修正实际已构造 dense array 的尺寸和内存口径，
不改变冻结科学对象、Method 1B、采样节点、阈值、验收门或结果解释。

I1 实测 fine evaluator 约 $5.7$--$6.6$ s/node；64 个 boundary nodes 加 seed 约 420 s。
两侧 $64\times32=4096$ 个 $194\times194$ resolvent LU/rcond/projector full-RHS actions，
以及相邻 $k$ edge 双向 guard 的 $8192$ 次 full-RHS triangular solves，是主要新增成本；
含 closure edge 后估计约 480--900 s，其余小矩阵工作预计低于 30 s；full 总预计
15--23 min。实现应流式保留上一节点的 resolvent factors，并为 closure 保存第一次物理
求值得到的首节点 A/B 或 LU 数据；“closure 重构”不得静默调用第 65 次物理 evaluator。
实现不得为方便一次保存全部 $64\times32$ dense matrices。

smoke 的 full 外推必须分别记录固定开销、四个 cardinal nodes 的节点开销，以及三个相继
cardinal connections 加 closure 共四条 production edges 的计时开销，并用平均 edge 成本
外推到含 closure 的 64 条 full edges。这些 edges 连接非相邻 cardinal states，只是
workload/interface probes：不得写入科学 `k-arcs` ledger，也不得把其 Neumann ratios 与
$0.25$ 门比较或解释为连续 $k$ 覆盖证据。

smoke 若显示 full 外推超过 1500 s、单节点持续恶化、内存超过 512 MiB 或不能判断完成
时间，则停止并汇报，不删门、不降低 $N_\zeta$、不自动改用 $N_k=128$。若某一结论只能
依靠超预算验证获得，应保留 blocker，并报告必要性、预计成本和便宜替代，不擅自执行。

## 13. Evidence、provenance 与不可覆盖性

实验目录固定为 `test/i2/k-count/`。当前只允许 append-only output tags：

- `output/smoke-a1/`（保留失败）；
- `output/smoke-a2/`（Revision 1，已通过跑后审查）；
- `output/m1-a1/`（Revision 2 full 候选，待 Skeptic 授权）。

`m1-a1` 在 Revision 2 跑前审查通过前不得创建。第 18 节说明该变更不切换科学方法。

目录已存在时 runner 必须 hard fail。每次尝试即使失败、停止或超时，也应尽最大可能保留：

- `report.md`、compact `result.mat`、`run.log`；
- `oracles.csv`、`nodes.csv`、`factors.csv`、`resolvents.csv`、`k-arcs.csv`、
  `zeta-arcs.csv`；
- `projectors.csv`、`windings.csv`、`gates.csv`、`failures.csv`；
- `provenance.csv`、`lineage.csv`、`source-manifest.csv`；
- 若在完整 ledger 前中止，保留 `abort.md` 和所有 partial ledgers。

report 必须由 raw ledgers 机械汇总，不允许手改 count、删失败行、挑节点、覆盖旧 output 或
补造结果。source manifest 至少 hash：本设计、experiment config、runner、evaluator、count
core、test-local proxy helper、实际调用的 I1/package sources、I1.3 parent `result.mat` 和 I1.4
positive parent/closure材料。另记录 Git SHA、dirty-worktree summary、UTC、MATLAB version、
`lsqminnorm` path、每个配置字段到 runtime 字段的 ledger，以及以下零计数：

`pinv_calls`、`fallbacks`、`silent_rank_truncations`、`rank_changes`、`chart_switches`、
`branch_switches`、`pointwise_modulus_reselections`、`method_switches`。

`implementation/i2/` 的 README、review 和状态页只链接
`test/i2/k-count/README.md` 这一实验索引，不直接链接散落代码、CSV、MAT 或 log，也不复制
原始结果。

## 14. Skeptic 首跑前与跑后审查合同

首跑前 Skeptic 必须独立核对：

1. 配置逐字段确实解析为本文件冻结的 fine/M48/object/contour/two-axis nodes；
2. manufactured suite 调用与正式路径相同的 LU/winding/Riesz core，解析答案和 negatives
   没有硬编码到被测函数；
3. Riesz 公式、$\zeta$ 权、original/reversed pencil、row selectors 和 $C/Y$ 公式正确；
4. 实际 LU phase 包含 permutation parity，所有 factors 来自真正求逆矩阵；
5. resolvent solve、idempotence、range 和 QZ-section parity 精确对应第 9 节公式；
6. 实现没有 Gram weighting、`abs(gamma)`、dynamic pivot/chart/rank/solver 或 coarse/fine 混用；
7. 每个门、阈值、failure priority 和停止规则与本文件一致；
8. smoke/full 输出路径 append-only，失败路径也保存 evidence；
9. 成本估算和最大矩阵与实际 loop/memory layout 一致。

跑后 Skeptic 必须从 CSV/MAT/log 独立重算 source hashes、row counts、phase sums、integer
residuals、32/64 counts、factor zeros、首失败、budget 和 report verdict，并检查没有遗漏、
覆盖、挑选或补造结果。Skeptic 不是结果辩护者。

## 15. 通过后允许和不允许的结论

若全部门通过，唯一允许的主结论是：

> 在冻结 fine、$M=48$ 有限维 evaluator 及本实验经验资格化的解析/fixed-chart 合同下，
> 指定圆盘内 $\det A_{\mathrm{def}}^D(k)$ 有一个按代数重数计的 zero。

其中“经验资格化”不可省略：64 个 $k$ 节点、32 个 $\zeta$ 节点、双轴 guards 和 16/32、
32/64 稳定性仍不控制所有未采样窄 excursion。本实验不得称 strict closed-disk pole-free
certificate。

即使通过，也不支持：

- zero 的位置；
- geometric multiplicity one、derivative-qualified simple root；
- 非零 physical field 或 BIE kernel--field equivalence；
- 连续 half-guide holomorphy、regular approximation 或 spectral-pollution 排除；
- continuous physical guided eigenvalue；
- 后验 correction、effectivity 或 remaining-error estimator。

这些边界分别留给 I2.2--I2.4、I3 和 M0。若任何 factor/解析资格化门失败，最多只能说
“在部分采样点未观察到异常”，不得保留 count-one root 结论。

## 16. 冻结确认

Researcher 与 Engineer 对 Method 1B 的对象、公式、实现映射、参数、门、资源和结论边界
显式 `AGREED`。原 Dhat-only 草案因 zeros-minus-poles blocker 在冻结前撤销。Skeptic
第二轮设计 verdict 为 `PASS WITH CONDITIONS / IMPLEMENTATION AUTHORIZED`，设计级
`BLOCKER=0`；该句只记录首次实现前的历史 verdict。Revision 1 的 `smoke-a2` 已通过独立
跑前和跑后审查。当前等待的是第 18 节 Revision 2 的 full 跑前审查；本文件自身不授权
运行 `m1-a1`。

## 17. 2026-08-13 Method 1B Revision 1

`smoke-a1` 已在 MATLAB R2023b 中运行并以 `i21:ProxyGate` fail-closed 停止；该目录是
不可覆盖的正式失败证据，不产生 root count。跑后只读审查发现 I2 手工移植把 I1 的
projector-repeat 计算

$$
\|Q_aQ_a^*-Q_bQ_b^*\|_2
$$

改写成了从 $\sigma_{\min}(Q_b^*Q_a)$ 先作 $1-\sigma^2$ 再开平方。两者对等维正交列基在
精确算术下等价，但后者在相同子空间处把舍入误差放大到 $O(\sqrt\epsilon)$；fine rank gap
又小于冻结的 2，所以这足以使本应复核同一 rank 的 $10^{-10}$ repeat 门发生实现相关失败。

Researcher 与 Engineer 明确 `AGREED`：Revision 1 保持同一 Method 1B、矩阵对象、轮廓、
rank 定义、solver、门序和全部科学阈值不变，只冻结以下稳定等价计算与证据修复：

1. 对列数相同的 $Q_a,Q_b$，用
   $C=Q_b^*Q_a$ 和 $\|Q_a-Q_bC\|_2$ 计算最大 principal-angle sine；列数不同仍返回
   `Inf`。该式不形成 $960\times960$ projector，也不改变 $10^{-10}$ 门；
2. `ProxyGate` 失败必须保存 $k$、seed 标记、helper availability/failure reason、rank、gap、
   repeat、rcond、projected residual/backward、full/shifted residual、seed identity 及各自阈值和
   pass bit，不能再只保存复合错误名；
3. `run.log` 在 report 发布前记录 command context、mode、source digest、首个异常 message 和
   stack，显式关闭 diary 并验证文件非空；
4. 尚未发生 resource checkpoint 时，peak memory 写 `NaN`，而不是把“未测量”写成零；
   同时记录 checkpoint count；
5. 新的 append-only 尝试 tag 为 `output/smoke-a2/`。`smoke-a1` 保持失败且不得作为 full
   parent。Revision 1 必须重新冻结并经 Skeptic design--implementation review 才可运行
   `smoke-a2`。

本次修订不是 Method 2，也不授权自动重试、放宽阈值或运行 full。full 的输出 tag 和
`smoke-a2/result.mat` hash 只有在 smoke-a2 通过且经独立跑后审查后才能另行冻结；在此之前
runner 必须 hard fail `full`。

## 18. 2026-08-13 Method 1B Revision 2

Revision 1 的 `smoke-a2` 在 MATLAB R2023b 中通过：12 个同核 manufactured oracles、seed 与
四个 cardinal nodes、320 个 resolvent rows、320 个 zeta-arc rows、20 个 projector rows 和
四条仅计时的 edge probes 全部通过；`scientific_count=NaN`。它只证明 full campaign 的接口、
证据与成本 readiness，不是 root count。其 elapsed 为 $34.740040375$ s，full 外推为
$425.46625704166667$ s，active-state peak 为 $180.33086967468262$ MiB。

跑后审查发现旧 parent 合同把两代 implementation digest 错误地要求相等：登记 smoke hash
和 full tag 必然改变当前配置 digest，因此 full 路径不可达。Researcher 与 Engineer明确
`AGREED`：Revision 2 只修复该 provenance transition 和报告/预算口径，不改 Method 1B、
evaluator、矩阵、轮廓、节点、阈值、门序或科学解释。冻结合同为：

1. `smoke-a2/result.mat` 的 SHA-256 固定为
   `85b6e4b1ffa41d6dd4a3f2daba354a56f1db8749a42ac9a4577d69dd6b0c61ca`；
2. 该 parent 内部的 producer implementation digest 固定为
   `c8cbc69e72595171a69df181d7fdf0825c7b84411a73d1538163df69f33127b6`，只验证 parent
   的生产身份；Revision 2 当前 full digest 由新的 freeze 与运行时 source manifest 独立验证，
   两代 digest 预期不同，禁止再次互比；
3. parent gate 还必须检查 schema、design/revision ID、`mode=smoke`、pass/status、空首失败、
   `scientific_count=NaN`、完整 timing/resource 字段、低于 $1500$ s 的外推和所有禁止调用/
   method-switch 零计数；
4. full 的 append-only tag 固定为 `output/m1-a1/`。配置中的 executable flag 只表示该冻结
   候选可在审查后执行，不替代 Skeptic 授权；
5. full 预算必须先计入外部 MATLAB 启动失败约 $1$ s、`smoke-a1` 的
   $2.8188827916666668$ s 和 `smoke-a2` 的 $34.740040375$ s，共
   $38.558923166666666$ s，再加本次 full 耗时；
6. 后续机械报告按 mode 区分结论：smoke pass 只支持 readiness，只有全部科学门通过的 full
   pass 才支持第 15 节的条件性有限维 count。

`smoke-a1` 与 `smoke-a2` 均保持 append-only，不重跑、不手改。Revision 2 必须形成新 freeze
并通过 Skeptic 的 design--implementation 一致性审查后，才允许唯一一次 `m1-a1` full；本节
不授权运行。
