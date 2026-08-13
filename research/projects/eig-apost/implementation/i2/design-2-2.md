# I2.2 实轴结构资格与端点 inertia 设计

## 摘要：本阶段做什么、不做什么

1. I2.2 **不重复** I1.3 已完成的宽区间实轴扫描、dip 搜索或逐层网格加密。
2. I1.3 已负责发现显著 dip；I2.1 已负责确认其邻域复圆盘内存在一个按代数重数计的
   finite-dimensional determinant zero。
3. 本阶段转而尝试证明或严格资格化：在已知实轴邻域中，候选 $H(k)$ 与原始 $A(k)$
   是否具有相同不可逆点、nullity 或 determinant-zero 集合。
4. 只有同一对象与精确结构条件成立后，才允许在 I1.3 已知 dip 邻域中预先冻结的左右
   肩点检查 inertia。
5. 本阶段不是新的 root locator，不进行复平面扫描，也不在本轮重复实轴 dip 定位；不运行
   bisection、Newton、Brent、局部复数 refinement 或任何二维扫描。

当前证明审查已得到一个 fail-close 结论：$A$--$H$ 的有限维奇异等价、中心坐标变换 $T$
在目标实区间的可逆性，以及 empty-center 部分的 Hermitian 性可以证明；但是当前
MFS/collocation、`lsqminnorm`、BIE 与 ordered-QZ 组成的实际 finite half-guide graph 尚无
exact-arithmetic Lagrangian identity。因此本 revision 的
`exact_finite_hermitian_proof=false`。此外，当前证据也没有建立整个肩点闭区间上同一
branch/QZ subspace/chart/factor family 的无极点连续性，因此独立冻结
`continuous_same_family_interval_proof=false`。首次正式运行只允许形成两个端点的
`STRUCTURE_DIAGNOSTIC_ONLY` 证据；任何针对 $H$ 的 eigensolve、`ldl` 或其他 inertia
算法必须在调用前被硬停止，结果写为
`UNAVAILABLE/NaN`，首科学失败固定为 `EXACT_HERMITIAN_NOT_ESTABLISHED`。

## 1. Material Passport、状态和权威性

- Origin Skill: `academic-research-suite / experiment-agent`；`rigorous-proof / proof from scratch`
- Collaboration: `Researcher--Engineer FINAL AGREED / independent Skeptic review required`
- Design ID: `I2.2-H-INERTIA-DIAGNOSTIC-V1`
- Design Status: `FROZEN CANDIDATE / PRE-RUN SKEPTIC REVIEW PENDING`
- Freeze Date: `2026-08-13`
- Theory Status: `PARTIAL PROOF / EXACT FINITE HALF-GUIDE HERMITIAN IDENTITY BLOCKED`
- Run Scope: `TWO-ENDPOINT STRUCTURE DIAGNOSTIC ONLY`
- Claim Boundary: `FROZEN FINE-M48 FINITE-DIMENSIONAL OBJECT`

本文件同时承载 I2.2 本轮的理论命题、证明尝试、假设、未闭合义务、数值设计、证据合同和
停止规则，不另建零散证明文件。实验材料统一从
[[test/i2/h-inertia/README|I2.2 endpoint-structure experiment index]] 进入；本文件不直链
零散源码、CSV、MAT 或日志。

本文件不修改或重解释 I1、I2.1 历史。I2.1 的冻结设计、source manifest、freeze、运行报告
和 append-only outputs 保持 immutable。即使本轮诊断失败，I2.1 的条件性 count-one 结论
仍保持原 verdict。

## 2. 三方职责与冻结共识

- **Researcher：**定义 $A,T,N_0,H$，证明点态奇异等价、全区间 $T$ 可逆和 center block
  Hermitian；审查 half-guide Lagrangian/Hermitian 证明能否闭合，并限定 inertia 命题。
- **Engineer：**核对 I2.1 evaluator 的实际输出，冻结两个端点、只读复用方案、数据结构、
  append-only evidence、资源、失败语义和禁止调用。
- **Skeptic：**独立审查理论证明、冻结设计、实现与跑后证据；不参与结果辩护，不以小结构
  defect 替代 exact identity。

Researcher 与 Engineer 已明确讨论并 `FINAL AGREED`：当前只能运行一次两个端点的 raw
structure diagnostic；inertia 在理论门前不可定义。Skeptic 必须在首次正式运行前审查本设计
和实现一致性。未经明确授权，不得创建 output。

## 3. Immutable parents 与对象身份

| Role | Frozen artifact | SHA-256 / identity |
|---|---|---|
| I1.3 L14 shoulders、seed rows 与 candidate | `test/i1/k-scan/output/zoom2/result.mat` | `e168638af0536f2671f0fd9d34a37432926953a5b722cbef6da3eaa1fe96678a` |
| I2.1 count-one result | `test/i2/k-count/output/m1-a1/result.mat` | `da1cd8097e9c22c0a4cdd3600f37454bbf2e50274604f894e51d3a54b19bac79` |
| I2.1 reviewed freeze manifest | `test/i2/k-count/freeze.sha256` | file SHA `36b0d11f0fe5fdd5d6dc71471d663eb537d8844588566e852ed71c9519414a7f`; aggregate `4b60840ea14210d51754f7fbe3f839266eab8a399ff7682202326c61c2d913c4` |
| I2.1 evaluator | `test/i2/k-count/eval_i21.m` | `90848b525d30df23f58ac03f5eac897b1089b4ee21b95f5b30c5019f9b44b990` |
| I2.1 configuration | `test/i2/k-count/cfg_i21.m` | `7c7b7feadd3dec6bdc25c9d0789ef3257b0d91a819bd3500635b7725f7904ce2` |

新 runner 必须重算本表、I2.1 freeze 中全部 scientific sources 及 I2.1 四个 I1 parents。
I2.2 只读调用 `cfg_i21('full')` 和 `eval_i21`，不得调用 `run_i21`，不得编辑、复制或覆盖
I2.1 源与 outputs。I1.3 parent 只提供冻结端点和 row selectors；两个正式端点都必须由同一
I2.1 fine evaluator 重新计算，不能复用 I1.3 的旧矩阵或混入 coarse level。

冻结模型保持：identical sharp-disk periodic leads、homogeneous missing center column、
$\beta=0.5$、period $d=1$、disk radius $R=0.2$、$X_L=-0.5$、$X_R=0.5$、$M=48$、
$K=97$、fine spatial level。branch anchor、proxy rank/chart、original/reversed QZ seed
clusters、fixed rows、Dirichlet chart、mode/row order、normal、solver 和所有 inherited gates
与 I2.1 完全相同。

## 4. 三类区间与冻结端点

三类容易混淆的实区间必须同时记账：

1. I1.3 L14 完整 evaluated outer interval：

   $$
   I_{\mathrm{L14}}=
   [1.8327697753906247,\ 1.8327705383300779].
   $$

   它的左端位于 I2.1 圆盘外，不能把它整体的端点结论直接与 I2.1 count one 合并。

2. I2.1 count 圆盘的实直径：

   $$
   I_D=[k_c-r_0,k_c+r_0]
   =[1.8327699661254881,\ 1.8327707290649411],
   $$

   其中

   $$
   k_c=1.8327703475952146,
   \qquad r_0=3.8146972647368216\times10^{-7}.
   $$

3. I2.2 正式冻结的 nearest-shoulder interval：

   $$
   I_{\mathrm{sh}}=[k_L,k_R]
   =[1.8327701568603514,\ 1.8327705383300779].
   $$

选择规则在运行前固定为：`I1.3 L14 nodes immediately adjacent to the recorded interior
minimum`。在 L14 五点顺序中，$k_L$、$k_c$、$k_R$ 分别是 node 3、4、5；两肩距
$k_c$ 都为一个 L14 spacing

$$
h=1.9073486323684108\times10^{-7},
\qquad r_0=2h.
$$

因此 $I_{\mathrm{sh}}$ 严格位于 $I_D$ 内。新 runner 必须从 parent fields 机械核验 node
indices、level、spacing、$k_L<k_c<k_R$、对称距离和 strict containment；不得把 L14 outer
interval、disk diameter 或结果后选择的其他点改称本轮端点。$k_c$ 只用于建立冻结 seed
frame，不作新的 dip 或 inertia 采样。

## 5. 有限维对象与严格奇异等价

简称 I2.1 的未平衡 safe-DtN matrix 为

$$
A(k)=A_{\mathrm{def}}^D(k)\in\mathbb C^{2K\times2K}.
$$

令

$$
\Gamma(k)=\operatorname{diag}(\gamma_m(k)),
\qquad
E(k)=\operatorname{diag}\!\left(e^{\mathrm{i}\gamma_m(k)W}\right),
\qquad W=X_R-X_L=1,
$$

并定义

$$
T(k)=
\begin{bmatrix}
I&E(k)\\
E(k)&I
\end{bmatrix},
\qquad
N_0(k)=
\begin{bmatrix}
-\mathrm{i}\Gamma&\mathrm{i}\Gamma E\\
\mathrm{i}\Gamma E&-\mathrm{i}\Gamma
\end{bmatrix}.
$$

把左右 finite safe-DtN 写为 $\Lambda_-(k),\Lambda_+(k)$，令

$$
L(k)=\operatorname{diag}(\Lambda_-(k),\Lambda_+(k)).
$$

### 命题 5.1：actual block identity

I2.1 的实际 block assembly 满足

$$
A(k)=N_0(k)-L(k)T(k).
$$

**证明。** 第一 block row 为

$$
[-\mathrm{i}\Gamma,\ \mathrm{i}\Gamma E]
-\Lambda_-[I,E]
=[-(\mathrm{i}\Gamma+\Lambda_-),\
(\mathrm{i}\Gamma-\Lambda_-)E].
$$

第二 block row 同理为

$$
[(\mathrm{i}\Gamma-\Lambda_+)E,\
-(\mathrm{i}\Gamma+\Lambda_+)].
$$

这与 `eval_i21` 的 $A_{\mathrm{def}}^D$ 公式逐块相同。证毕。

### 命题 5.2：$T$ 可逆点上的奇异等价

若 $T(k)$ 可逆，定义

$$
H(k):=A(k)T(k)^{-1}.
$$

则

$$
A=HT,
\qquad
\ker H=T\ker A,
\qquad
\operatorname{rank}H=\operatorname{rank}A,
\qquad
\operatorname{nullity}H=\operatorname{nullity}A,
$$

且

$$
\det A=\det H\det T.
$$

**证明。** $H=AT^{-1}$ 直接给出 $A=HT$。若 $Aq=0$，则
$H(Tq)=Aq=0$；反之若 $Hd=0$，取 $q=T^{-1}d$，则 $Aq=Hd=0$。故
$\ker H=T\ker A$。右乘可逆矩阵不改变 rank 和 nullity，determinant 恒等式由乘法性得到。
左零向量不变，因为 $\ell^*H=0$ 当且仅当 $\ell^*AT^{-1}=0$，当且仅当
$\ell^*A=0$。证毕。

因此本阶段称“同一 singularity/nullity”，不称“严格同核”。若未来要把 I2.1 的整个复圆盘
count 从 $A$ 转给 $H$，还需要 $T$ 在整盘解析且 zero-free；本轮仍把 count 保留在原 $A$，
只需实区间上 $T$ 可逆。

实现必须以 MATLAB right solve `H=A/T` 形成 $H$，禁止 `inv`、`pinv` 或独立重组一个
“看起来更 Hermitian”的旁系矩阵。必须同时核验 $A=N_0-LT$ 和 $A=HT$ 的 normalized
residual。

## 6. $T$ 在整个两肩区间上的可逆性

每个 Fourier channel 的 block 为

$$
T_m(k)=
\begin{bmatrix}1&E_m(k)\\E_m(k)&1\end{bmatrix}.
$$

固定 Hadamard block transform 把 $T_m$ 对角化为 $1+E_m$ 与 $1-E_m$，所以

$$
\sigma_{\min}(T(k))
=\min_m\{|1+E_m(k)|,|1-E_m(k)|\}.
$$

### 命题 6.1：whole-interval lower bound

在 $I_{\mathrm{sh}}$ 上，$\sigma_{\min}(T(k))>0.995$。

**证明。** 当前 $\beta_m=0.5+2\pi m$、$W=1$。

- $m=0$ 是唯一传播 channel。对整个 $I_{\mathrm{sh}}$，直接由端点范围可保守得
  $1.7<\gamma_0(k)=\sqrt{k^2-0.25}<1.8$。于是

  $$
  |1-e^{\mathrm{i}\gamma_0}|=2\sin(\gamma_0/2)>2\sin(0.85)>1.5,
  $$

  $$
  |1+e^{\mathrm{i}\gamma_0}|=2\cos(\gamma_0/2)>2\cos(0.9)>1.2.
  $$

- 对 $m\ne0$，$|\beta_m|>5.7$ 而 $k<1.9$，所以
  $\gamma_m=\mathrm{i}\eta_m$ 且 $\eta_m>5.3$。因此
  $|E_m|=e^{-\eta_m}<0.005$，从而 $|1\pm E_m|>0.995$。

取全部 channels 的最小值得证。这个证明同时排除该实区间上的 Wood threshold 与
empty-slab Dirichlet resonance。证毕。

数值端点仍须记录 $\min_m|1-E_m^2|$、$\sigma_{\min}(T)$、`rcond(T)` 和 right-solve
residual，作为实现一致性 oracle；它们不替代 whole-interval 证明。冻结数值门为
`rcond(T)>=1e-8`、$\min_m|1-E_m^2|\ge10^{-8}$。

## 7. center block 的 Hermitian 证明

令

$$
C_0(k)=N_0(k)T(k)^{-1}.
$$

按 channel 写 $e=e^{\mathrm{i}\gamma W}$，则

$$
N_{0,m}T_m^{-1}
=\frac1{1-e^2}
\begin{bmatrix}
-\mathrm{i}\gamma(1+e^2)&2\mathrm{i}\gamma e\\
2\mathrm{i}\gamma e&-\mathrm{i}\gamma(1+e^2)
\end{bmatrix}.
$$

若 $\gamma\in\mathbb R$ 且 $\sin(\gamma W)\ne0$，它等于

$$
\gamma
\begin{bmatrix}
\cot(\gamma W)&-\csc(\gamma W)\\
-\csc(\gamma W)&\cot(\gamma W)
\end{bmatrix};
$$

若 $\gamma=\mathrm{i}\eta$、$\eta>0$，它等于

$$
\eta
\begin{bmatrix}
\coth(\eta W)&-\operatorname{csch}(\eta W)\\
-\operatorname{csch}(\eta W)&\coth(\eta W)
\end{bmatrix}.
$$

两者都是 real symmetric。结合第 6 节的 resonance 排除，得到

$$
C_0(k)=C_0(k)^*,\qquad k\in I_{\mathrm{sh}}.
$$

这证明的是按当前 block convention 的 empty-center finite Fourier DtN。法向、符号和
ordering 已由第 5 节 actual identity 核验；它不证明 half-guide finite DtN Hermitian。

## 8. half-guide Hermitian 证明尝试与未闭合义务

对任一侧 finite Cauchy graph，设 $D=D_s(k)$、$N=N_s(k)$，并且 $D$ 可逆。当前
safe-DtN 为

$$
\Lambda=ND^{-1}.
$$

### 命题 8.1：Lagrangian identity 与 Hermitian DtN 等价

在 $D$ 可逆时，

$$
\Lambda=\Lambda^*
\quad\Longleftrightarrow\quad
D^*N=N^*D.
$$

**证明。** 若 $D^*N=N^*D$，左乘 $D^{-*}$、右乘 $D^{-1}$ 得
$ND^{-1}=D^{-*}N^*$，右边正是 $(ND^{-1})^*$。反向乘回 $D^*$ 与 $D$ 即得。证毕。

I1 冻结的 coefficient duality 是 $d^*n$。I1 chart 中的 $G_D,G_N$ 只用于 Sobolev norm
和 transversality/conditioning diagnostics；`gram=(gram+gram')/2` 也只处理 graph-coordinate
Gram。它们不能被改写成新的物理 pairing，更不能作为 $\Lambda$ 自伴的证明。

### 证明尝试结论：`BLOCKED`

实际 finite chain 包含：MFS/proxy 过采样 collocation、public `lsqminnorm`、Nyström/BIE
one-cell scattering、有限 Fourier channel generalized pencil、ordered QZ stable subspace、
fixed-row normalization 和 finite Dirichlet chart。现有设计与实现没有给出 exact discrete
flux conservation、$J$-unitary/symplectic pencil identity 或结构保持 Petrov--Galerkin
pairing。因此不能从连续 PDE reciprocity/self-adjointness 推出 actual arrays 在 exact
arithmetic 下满足

$$
D_{s,\pm}^*N_{s,\pm}=N_{s,\pm}^*D_{s,\pm}.
$$

故不能证明 $\Lambda_\pm=\Lambda_\pm^*$，也不能证明

$$
H=C_0-\operatorname{diag}(\Lambda_-,\Lambda_+)
$$

在整个实区间 exact Hermitian。fixed-row gauge 在 $ND^{-1}$ 中消去，但这不补上 flux
identity。数值上很小的 Lagrangian、$\Lambda$ 或 $H$ defect 只能检查实现，不得把
`exact_finite_hermitian_proof=false` 改成 true。

标量反例 $h(k)=k-a+\mathrm{i}\varepsilon$ 说明：无论 $\varepsilon$ 多小，实轴上都没有
zero；而手工 Hermitian part $k-a$ 却有 sign change。因此禁止把 $H$ 替换成
$(H+H^*)/2$，也禁止以该矩阵的 inertia 声称原 $A$ 有实根。

## 9. inertia 命题与当前不可用性

### 条件命题 9.1

设 $H:I\to\mathbb C^{n\times n}$ 连续且对全部 $k\in I$ 有 $H(k)=H(k)^*$。若两端
可逆且负 inertia indices 不同，则 $I$ 内至少有一点使 $H$ 奇异。

**证明。** Hermitian matrix 的有序实特征值随连续 matrix path 连续。若两端负特征值个数
不同，至少一条特征值分支必须穿过零。证毕。

若令 $I=I_{\mathrm{sh}}$，再结合：

1. 第 6 节的 $T$ 全区间可逆；
2. 第 5 节的 $A$--$H$ 奇异等价；
3. $I_{\mathrm{sh}}\subset\operatorname{int}(I_D)$；
4. I2.1 圆盘内总 algebraic count one；

那么可信的非零 inertia jump 会支持：I2.1 圆盘内唯一 determinant zero 位于实轴肩点区间。
它仍不定位 root，也不证明 continuous physical eigenvalue。

当前命题 9.1 的 exact-Hermitian 前提未满足。因此本 revision 必须在任何针对 $H$ 的
`eig`、`ldl` 或 inertia arithmetic **之前** hard branch；I2.1 evaluator 内为继续冻结 QZ
cluster 而调用的 generalized `eig(...,'qz')` 不属于 inertia 计算：

- `theory_gate=0`；
- `exact_finite_hermitian_proof=0`；
- `continuous_same_family_interval_proof=0`；
- `inertia_available=0`；
- `n_pos=n_neg=n_zero=NaN`；
- `min_abs_eig=NaN`；
- `algorithm=NOT_RUN_EXACT_HERMITIAN_GATE`；
- `inertia_jump=UNAVAILABLE`。

`ENDPOINT_SEPARATION_INSUFFICIENT` 和 `NO_INERTIA_JUMP` 均为 `NOT_REACHED`。这就是本轮
正式的左右端点 inertia 结果语义，不得为满足表面输出而生成正负 counts。

即使未来关闭 pointwise exact-Hermitian 缺口，也不能只翻转该单一 flag。只有另行证明同一
finite family 在整个闭区间上连续、保持同一 branch/QZ subspace/chart/ordering，且所有实际
inverse factors 无 singularity，`continuous_same_family_interval_proof` 才可改为 true；两门
同时成立后才允许计算并解释 inertia。

## 10. 文献核验与有限维--连续边界

本轮只使用项目已经收录的 Sonia Fliss, “A Dirichlet-to-Neumann Approach for the Exact
Computation of Guided Modes in Photonic Crystal Waveguides,” *SIAM Journal on Scientific
Computing* 35(2), 2013, B438--B461, DOI `10.1137/12086697X`
（[[ref/ref_data/Fliss2013.pdf|本地原文]]）。没有下载新文献。已逐页核验：

| 原文 | 支持的连续结论 | 不能转移成什么 |
|---|---|---|
| Proposition 3.1，PDF p. 7 | 固定实 $\beta$ 的 $A(\beta)$ 自伴、正，essential spectrum 由 projected bulk spectrum 给出 | 当前 sharp-disk continuous gap；finite BIE/QZ Hermitian |
| Proposition 3.3，PDF p. 8 | gap 内谱若存在，为有限重孤立 eigenvalues | 不保证存在，不把 dip 变成 root |
| Theorem 4.1，PDF pp. 10--11 | half-guide Dirichlet problem 在原文条件下除可数例外外适定；指定镜像条件可去例外 | 当前 fixed-$\beta$ discrete flux identity |
| Proposition 4.3，PDF pp. 11--12 | exact DtN 对实参数有界且 norm-continuous | complex holomorphy或finite collocation identity |
| Theorem 4.5，PDF p. 13 | unbounded guided problem 与 bounded exact-DtN problem 等价并保持重数 | 当前 continuous BIE kernel--field bridge |
| Proposition 4.8，PDF p. 14 | bounded-domain $A_0(\beta,\alpha)$ 自伴、compact-resolvent、下有界 | raw $A_{\mathrm{def}}^D$ 或 finite $H$ Hermitian |
| Theorem 4.9，PDF pp. 14--15 | min--max eigenvalues 及参数连续性 | 当前 inertia 前提自动成立 |
| Proposition 4.10，PDF p. 16 | guided modes 可写成实方程 $\mu_m(\beta,\omega)=\omega^2$ | 当前 frozen finite zero 已在实轴 |

这些原文结果只支持 continuous exact physical route。smooth Fliss numerical Track A 的 gap
不能转移给当前 sharp-disk 模型；I1/I2 的 97/97 unit-circle QZ split 也只是 finite-pencil
sampled hyperbolicity，不是 continuous projected-gap theorem。OP-M0 的 continuous
holomorphy、kernel--field、regular approximation 和 spectral-pollution blockers 保持开放。

## 11. 唯一允许的数值实验

实验目录固定为 `test/i2/h-inertia/`，唯一 append-only tag 为 `output/diag-a1/`。本轮不设
smoke；在 design、implementation 与 static freeze 经 Skeptic 审查后，只允许运行一次：

```matlab
addpath(fullfile(pwd,'test','i2','h-inertia'));
run_i22('diagnostic');
```

正式 shell command 由实验 README 登记。runner 执行：

1. runtime/source/freeze/I1.3/I2.1 lineage；
2. 加载 I1.3 fixed row selectors；
3. 用 I2.1 evaluator 在 $k_c$ 建立 seed frame；
4. 只评估 $k_L,k_R$；
5. 记录 inherited branch/QZ/chart/factor health；
6. 构造 $T,N_0,L,H=A/T$；
7. 记录 equality、solve、$T$ 和 raw structure diagnostics；
8. 在 inertia core 之前同时读取 frozen `exact_finite_hermitian_proof=false` 与
   `continuous_same_family_interval_proof=false`，写 NaN/UNAVAILABLE；
9. append-only 发布失败证据和 mechanical report。

禁止第三个科学点、扫描、自动加点、区间改变、root locator、bisection、Newton、Brent、
complex refinement、contour、derivative 或 estimator。seed 的 evaluator 调用不作 dip 检查。

## 12. 数据结构和原始证据

至少保存：

| Artifact | 内容 |
|---|---|
| `configuration.csv` | Design ID、两个 proof flags、端点、阈值、预算、禁止调用 |
| `objects.csv` | fine/M48/K97、全部 shapes/order/normal/branch/chart identity |
| `lineage.csv` | I1.3、I2.1 result、I2.1 freeze 与 parents 的 expected/actual hashes |
| `provenance.csv`、`source-manifest.csv` | MATLAB/public `lsqminnorm`、Git/dirty state、actual sources 和 hashes |
| `endpoints.csv` | L/R 的 $k$、L14 node、disk containment、evaluator time 和 pass |
| `factors.csv`、`qz.csv` | inherited factor、branch、QZ、fixed-row/chart evidence |
| `structure.csv` | $T$、identity、center、graph、$\Lambda$ 和 raw $H$ diagnostics |
| `inertia.csv` | theory gate、NaN counts、UNAVAILABLE 和禁止算法标签 |
| `gates.csv`、`failures.csv` | 顺序门、首失败与 NOT_REACHED gates |
| `endpoint-matrices.mat` | 两端的 $A,T,N_0,H,D_\pm,N_\pm,\Lambda_\pm$ 和 raw pencil，用于独立复算 |
| `result.mat`、`report.md`、`run.log` | compact result、机械报告和非空运行日志 |

不得把 proxy/BIE 大型中间 dense arrays 落盘。`endpoint-matrices.mat` 是本实验目录内的原始
证据；implementation 文档仍只链接本目录 README，不直链该文件。

`structure.csv` 每端至少记录：

- `T_rcond`、`T_sigma_min`、`min_abs_1_minus_E2`、right-solve residual；
- $A-[N_0-LT]$ identity defect；
- $A-HT$ defect；
- $C_0=N_0/T$ Hermitian defect；
- $\Lambda_-$、$\Lambda_+$ Hermitian defects；
- $D_\pm^*N_\pm-N_\pm^*D_\pm$ 的 Lagrangian defects；
- raw $H-H^*$ defect；
- finite flags。

Hermitian/Lagrangian defect 统一为

$$
\frac{\|X-X^*\|_F}{\max(1,\|X\|_F)}.
$$

identity 和 solve residual 的分母必须包含所有参与量。结构 defects 没有能够自动翻转 proof
flag 的阈值；它们只作 implementation oracle。禁止形成或保存 $(H+H^*)/2$。

## 13. 独立数值门、失败顺序与验收

冻结 independent gates：

- inherited I2.1 evaluator、branch、QZ、fixed-row、Dirichlet、Schur、proxy/BIE factor gates
  原样保持；
- `rcond(T)>=1e-8`；
- $\min_m|1-E_m^2|\ge10^{-8}$；
- normalized block identity 和 right-solve residual 不超过 $10^3(2K)\epsilon$；
- all recorded values finite，NaN 只允许出现在预注册的 unavailable inertia fields。

首失败按以下顺序冻结：

1. `OUTPUT_EXISTS`；
2. `RUNTIME_OR_SOURCE_FAILURE`；
3. `PARENT_OR_PROVENANCE_FAILURE`；
4. `OBJECT_OR_ENDPOINT_DRIFT`；
5. `EVALUATOR_FAILURE`；
6. `BRANCH_QZ_CHART_DRIFT`；
7. `FACTOR_HEALTH_FAILURE`；
8. `T_NOT_INVERTIBLE`；
9. `EQUIVALENCE_IDENTITY_FAILURE`；
10. `STRUCTURE_DIAGNOSTIC_NONFINITE`；
11. `EXACT_HERMITIAN_NOT_ESTABLISHED`；
12. `CONTINUOUS_SAME_FAMILY_INTERVAL_NOT_ESTABLISHED`；
13. `ENDPOINT_SEPARATION_INSUFFICIENT`；
14. `NO_INERTIA_JUMP`；
15. `TIMEOUT_OR_RESOURCE_STOP`。

运行中资源 stop 立即优先，科学顺序只对已经形成的 gates 判首失败。当前预注册的首科学失败
是第 11 项；第 12 项也保持失败，第 13、14 项不得执行。若更早门失败，保存原始端点 partial evidence，并准确
区分对象漂移、$T$、identity、factor、structure nonfinite 与 theory gap。

本 revision 不存在数值 PASS 路径。完整诊断的正确 verdict 是

`I2_2_STOP_THEORY_GATE / STRUCTURE_DIAGNOSTIC_ONLY`。

允许保留的结论只有：点态 $A$--$H$ identity 是否按实现闭合、$T$ 数值可逆性、两端 inherited
object health，以及 graph/$\Lambda$/raw-$H$ structure defect 的量级。不得报告 inertia
jump、实根、root 坐标、continuous physical eigenvalue 或 estimator。

## 14. 资源预算和停止规则

| 项目 | 冻结预算 |
|---|---:|
| 预计总耗时 | 20--30 s |
| target / hard stop | 60 s / 180 s |
| peak memory hard bound | 512 MiB |
| 最大方阵 | $512\times512$ |
| 最大矩形 dense array | $1920\times450$ |
| 科学点 | 2 endpoints；另有 1 次 seed-only evaluator |

预计 peak 为 180--200 MiB。不得形成 Sylvester/Kronecker 巨矩阵。若运行时间、内存或单点
成本明显恶化，停止并保留 evidence，不删门、不复制 I2.1 full campaign、不自动 retry。

Engineer 在正式 freeze 前曾误发起一次只读 MAT schema MATLAB `-batch load(...)` 命令；进程
约 2.3 s 后在 startup/crash-report 权限层 fatal exit，未进入 `load`、未调用 evaluator、未
创建 output 或修改仓库。该非实验启动失败必须在 README、review 和最终资源/失败历史中披露，
但不作为 `diag-a1` runner attempt，也不提供任何数值证据。

## 15. Evidence 发布与不可覆盖性

`output/diag-a1/` 已存在时 runner 必须在写入前 hard fail。任何进入 output 的尝试均不得
重用 tag。report 必须从 ledgers 机械生成；先保存 CSV/MAT/failure，再原子发布 report。
failure 或 evidence-finalization failure 也必须尽最大努力保留非空 log、abort 和 partial
ledgers。不得手改 output、删除失败、挑端点、补造 inertia 或用最终文档覆盖 raw verdict。

source manifest 至少包含本设计、新 config/wrapper/runner、只读 I2.1 config/evaluator、
`i21_kproxy`、`kproxy/kchan/kgreen/kbie` helpers、I2.1 freeze 和 evaluator 实际调用的 package
dependencies；这些只读依赖不得因未复制到新目录而漏记。记录 MATLAB version、public `lsqminnorm` path、
Git SHA、dirty summary、UTC，以及 `pinv/root/locator/derivative/estimator/scan/point-addition/
method-switch` 零计数。

## 16. Skeptic 跑前与跑后审查合同

跑前 Skeptic 必须逐项确认：

1. 证明没有把 continuous self-adjointness 或数值 small defect 冒充 finite exact identity；
2. 三类区间与 L14 node 3/4/5、I2.1 containment 解析正确；
3. wrapper 只读调用同一 I2.1 evaluator，不复制、修改或混用 coarse 对象；
4. $T,N_0,L,H$ 与 actual code formula 一致，$H$ 用 right solve；
5. 两个 proof flags 在所有针对 $H$ 的 `eig/ldl/inertia` 调用前同时 hard stop，源中无手工
   symmetrization；继承的 QZ continuation 不得被误记成 inertia；
6. inherited object/factor gates、identity thresholds、failure priority 与本文件一致；
7. output append-only、证据 schema、日志和资源路径完整；
8. freeze manifest 覆盖本设计和全部 executable sources。

跑后 Skeptic 独立复算 hashes、parent contents、endpoint identity、$T$、structure defects、NaN
inertia、首失败、rows、report/result/log 和资源，并检查没有遗漏、覆盖、阈值迎合或伪造。

## 17. 结论边界和下一步

本设计已经证明：

- actual $A=N_0-LT$ block identity；
- $T$ 可逆点上 $H=A/T$ 与 $A$ 同 singularity/nullity，右核由 $T$ 搬运；
- $T$ 在整个 shoulder interval 上有保守 separation；
- center block $N_0T^{-1}$ 在该实区间 Hermitian；
- 若 exact Hermitian path 和可信 inertia jump 成立，如何与 I2.1 count one 合并。

未证明且阻止 inertia 的是：current frozen QZ Cauchy graph 在 exact arithmetic 下满足
$D^*N=N^*D$；whole-interval finite graph/chart/factor continuity 也仍只有 sampled/conditional
支持。二者分别由两个冻结 proof flags 表示，任何一个未闭合都阻止 inertia；当前首失败是
顺序更早的 exact Hermitian blocker。

因此本轮运行后不得自动进入一维或复数求根。若要继续，必须先另行决定：

1. 是否能以结构保持离散、可证明的 antiunitary zero-set symmetry，或其他同一对象论证关闭
   exact-realness；
2. 若不能，是否接受只在 I2.1 小圆盘内做局部 complex refinement 来估计 imaginary part。

任一方法切换都需要新的 Researcher--Engineer 共识、设计、freeze 和 Skeptic 审查；不允许
用本轮 endpoint diagnostics 结果后修改区间、矩阵、阈值、坐标、符号或解释。

## 18. Revision A：`diag-a1` evidence-schema 失败与唯一修复

### 18.1 不可变失败记录

首次获授权的 `output/diag-a1/` 已于 2026-08-13 运行，并在第二个端点开始前发生
`MATLAB:catenate:dimensionMismatch`。首个已完成的左端点产生了 partial ledgers，但 runner
在把 $1\times8$ seed-object struct array 与 $1\times13$ endpoint-object struct array 纵向
拼接时失败；右端点没有求值，`endpoint-matrices.mat` 也尚未得到任何端点矩阵。因此该 attempt
只能解释为

`I2_2_DIAGNOSTIC_FAIL / RUNTIME_OR_SOURCE_FAILURE / evidence-schema implementation failure`，

不能解释为两端结构诊断完成，更不能解释为 inertia 或实根结果。其 `result.mat` SHA-256 为
`fd56da97c38ff93f6d63ea007ddb3c23c0f44542983fa61c4e4e7b6674ad9c12`，runner elapsed 为
`16.368607833333332 s`。原 `freeze.sha256`、`output/diag-a1/` 及其全部 append-only artifacts
保持 producer-time 不可变，不得修补、删除、覆盖或复用。

### 18.2 Researcher--Engineer 修复共识

Researcher 与 Engineer 在读取原始失败 evidence 后 `FINAL AGREED`：允许的 Revision A 只包括：

1. 所有增长中的 struct ledgers 先核对完全相同的字段 schema，再统一用 `(:)` 转为列向量追加；
2. 新增 `EVIDENCE_SCHEMA_FAILURE` failure taxonomy，并保留 MATLAB 原始 identifier/message；
3. 将 `diag-a1` 的 result hash、status、first failure、identifier 和 elapsed 注册为不可变 parent；
4. 使用新的 append-only tag `output/diag-a2/` 和新的 `freeze-a2.sha256`；
5. 在 report/result/provenance 中单列 revision identity，并把约 `2.3 s` 的非实验 startup、
   `diag-a1` 的 `16.368607833333332 s` 与 `diag-a2` 本身分列计入 campaign history。

Revision A 不得改变端点、scientific objects、I2.1 evaluator、矩阵公式、thresholds、proof flags、
inertia 禁止路径、资源上限或结论解释。尤其
`exact_finite_hermitian_proof=false` 与
`continuous_same_family_interval_proof=false` 保持不变；`diag-a2` 即使完整执行，也仍应在
`EXACT_HERMITIAN_NOT_ESTABLISHED` 停止，并把两端 inertia 写成 `NaN/UNAVAILABLE`。

### 18.3 Revision A 运行合同

`diag-a2` 仍使用第 11 节登记的同一 MATLAB command body；只是 config 把输出解析到新 tag。
`output/diag-a2/` 在运行前必须不存在。`freeze-a2.sha256` 必须覆盖本文件的 Revision A、修订后的
config/runner、未改的 evaluator 和全部只读 I2.1 dependencies，并由 Skeptic 重新完成跑前静态审查。
该修订不构成自动 retry 授权；未经新的 Skeptic verdict 不得运行。若 `diag-a2` 再次失败，必须
保留其 evidence 并停止，不能复用 tag 或进一步自动重试。
