# I7.3 跨离散符号计数与同模态数值稳定性设计

## 1. 状态、问题与结论边界

- Design ID: `I7.3-DISCRETIZATION-STABILITY-V1`
- Status: `CORRECTED-DENSITY A+B COMPLETE; STABLE_SAME_MODE; NO_DRIFT_RESOLVED_AT_SPACING_1E-5; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Independent review: [[research/projects/eig-apost/implementation/i7/review-7-3a|review-7-3a]]
- Claim boundary: `CONDITIONAL FINITE-DIMENSIONAL NUMERICAL STABILITY`

本阶段只检验 [[research/projects/eig-apost/implementation/i7/design-7-2a|I7.2]] 的
Hermitian-part endpoint jump 与中心低奇异模态在两条分开的离散轴上是否保持，并核对它们在同一
physical Dirichlet trace 坐标中的 mode identity。它不证明 raw $H$ inertia、连续特征值、连续
最小点、收敛阶或误差界。相似度、稳定计数与可选局部网格漂移都只是数值证据；零网格漂移也不称
收敛。

### 2026-09-29 修正密度坐标后的复验

本轮按修正后的公共 `bloch.construct_S` 从零重算本设计的两个既有阶段，不读取 2026-09-26 的
MAT 文件或数值结果。阶段 A 先完成六配置的 $k_L,k_0,k_R$ 共 18 点；阶段 B 再完成六配置共享的
11 点局部网格，共 66 点。当前中心点改为修正后 I7.1 的
$k_0=1.755995740875$。除这个中心点替换及其传参外，物理模型、六配置、六条比较边、坐标映射、
判据和结果语义均不变。第 12、13 节的旧数值明确是密度坐标修正前的历史证据，不作为本轮输入或
当前结论。

本轮 MATLAB、debug 与 audit 共享 1800 s 计算预算，process-tree RSS 用户硬上限为 3 GB；正式
launcher 仍采用 2,300,000,000-byte 提前终止线、0.1 s 采样和无并发 MATLAB 门。顺序固定为
A 及其 audit 后清理大矩阵，再运行 B 及其 audit；任何阶段失败都保留 checkpoint，不以旧结果补足。

运行时只依赖新实验 MATLAB 入口及其实际数值依赖，不读取本设计、README、Git 或旧输出。
I7.2 的结果只给出比较对象和边界，不作为运行输入。关联的既有方法与 caveat 见
[[research/projects/eig-apost/implementation/i7/review-7-2a|I7.2 review]]、
[[research/projects/eig-apost/implementation/i2/design-2-3|I2.3 boundary-axis design]] 和
[[research/projects/eig-apost/implementation/i2/design-2-3m|I2.3 trace-axis design]]。

## 2. 冻结模型、点与六个配置

物理模型保持不变：$\beta=0.5$、period $d=1$、两侧 circular lead inclusion radius
$0.2$ 且 `epsrel=17`；中心是 axes $(0.25,0.16)$ 的单连通 ellipse，`epsrel_center=2`；人工墙
$X_L=-0.5,X_R=0.5$。三个固定点是

$$
k_L=1.753125,\qquad
k_R=1.75625,\qquad
k_0=1.755995740875.
$$

proxy 配置固定为
`(nside,ntop,nproxy,mpw)=(160,160,80,32)`。六个配置为：

| Name | `ntot` | $M$ | $K=2M+1$ | Role |
|---|---:|---:|---:|---|
| `B` | 256 | 48 | 97 | I7.2 baseline |
| `M56` | 256 | 56 | 113 | pure $M$ axis |
| `M64` | 256 | 64 | 129 | pure $M$ axis |
| `N384` | 384 | 48 | 97 | pure `ntot` axis |
| `N512` | 512 | 48 | 97 | pure `ntot` axis |
| `J` | 512 | 64 | 129 | joint high configuration |

比较图的六条 hard edges 固定为
`[B,M56]`、`[M56,M64]`、`[B,N384]`、`[N384,N512]`、
`[M64,J]` 和 `[N512,J]`，即代码索引
`[1 2;2 3;1 4;4 5;3 6;5 6]`。
`B--J` 只作首末摘要，不增加一个混合 refinement axis。

## 3. 接口兼容与不变参数职责

公共 `bloch.construct_S` 对每个 inclusion 边界 order $N=\texttt{ntot}$ 构造

$$
A_{QP}\in\mathbb C^{2N\times2N},\quad
B_L,B_R\in\mathbb C^{2N\times K},\quad
F_L,F_R\in\mathbb C^{K\times2N},
$$

并一次求解 $2K$ 个 right-hand sides。因此六配置的 $A_{QP}$ 阶分别为
$512,768,1024$，而 $2K$ 只为 $194,226,258$；`M64` 和 `J` 没有代数尺寸障碍。

`kernel.precomp_proxy` 的固定配置给出

$$
2n_{\mathrm{side}}+4n_{\mathrm{top}}=960
$$

个 equations，以及

$$
4n_{\mathrm{proxy}}+2(2m_{\mathrm{pw}}+1)=320+130=450
$$

个 unknowns。`nside=160` 是 proxy periodic-wall collocation，不是 Rayleigh channel 的墙面
拟合维数；`mpw=32` 是 proxy Green representation 的 plane-wave order，不是散射端口 cutoff
$M$。因此它们无需随 $M$ 同步改变。若高 $M$ 的实际 proxy、BIE、QZ 或 solve gate 失败，保存
失败并把稳定性判为 unresolved；不得静默调高 proxy 参数。任何同步改变 proxy 的检查只能另列
supplementary configuration，不可冒称纯 $M$ 轴。

## 4. 三个对象与坐标映射

沿用 I7.2 的 amplitude order $q=[a^L;b^R]$ 和 physical trace order
$d=[d_L;d_R]$。中心 trace map、matching matrix 与 Hermitian part 为

$$
d=Tq,\qquad
H=A_{\mathrm{def}}/T,\qquad
H_{\mathrm{sym}}=\frac{H+H^*}{2}.
$$

$H$ 是对 physical trace $d$ 的 operator，所以 $H_{\mathrm{sym}}$ 的右 eigenvectors 已经是
`[left;right]` Dirichlet Fourier coordinates，不再乘 $T$。

对 weighted matching matrix

$$
A_{\mathrm{phys}}=D_rA_{\mathrm{def}}D_c,
$$

若 $v_j$ 是右 singular vector，则先恢复 amplitude，再映射到相同 physical trace：

$$
q_j=D_cv_j,\qquad d_j=Tq_j.
$$

不得把 $v_j$ 或 $q_j$ 直接与 $H_{\mathrm{sym}}$ eigenvector 比较。每个配置必做：在
$k_L,k_R$ 保存 $H_{\mathrm{sym}}$ 的完整 eigenvalue spectrum、nearest-zero primary 和
next competitor eigenvectors；在 $k_0$ 保存 $A_{\mathrm{phys}}$ 的完整 singular spectrum、
最小及次小右 singular vectors和它们映射后的 $d_1,d_2$。若 $k_0$ 已形成
$H_{\mathrm{sym}}$，可保存其 spectrum 作诊断，但不新增解释或验收门。

三类 primary trace 只在相同 $k$、相同对象下沿第 2 节六条配置 edges 比较：分别比较
$H_{\mathrm{sym}}(k_L)$、$A_{\mathrm{phys}}(k_0)$ 和
$H_{\mathrm{sym}}(k_R)$。本实验不把不同 $k$ 或不同 operator 的向量 overlap 设成 mode-identity
门，也不由它们推断一条连续 branch。

## 5. Mode identity、tail 与近简并回退

令共同最大 cutoff 为 $M_{\max}=64$。把每个 trace 的 left/right blocks 分开，按真实标签
$m=-M{:}M$ 零填充到 $m=-64{:}64$；不得移动 block boundary、复制缺失系数或按 array index
直接对齐。对有限非零向量使用 phase/scale-invariant overlap

$$
\rho(x,y)=\frac{|x^*y|}{\|x\|_2\|y\|_2}.
$$

较高 $M$ 向量相对较低 cutoff $M_c$ 的新增高模能量占比为

$$
E_{\mathrm{tail}}=
\frac{\|P_{|m|>M_c}d\|_2^2}{\|d\|_2^2},
$$

其中 projection 同时作用于 left/right blocks。每条 edge 保存相对 edge-low $M_c$ 的 total 与
left/right fractions；每个 high-$M$ 对象还固定报告 $|m|>48$ 的 total 与 left/right fractions。
$1-E_{\mathrm{tail}}$ 是相应共同 mode fraction。高 overlap 必须与这些 squared-norm energy
fractions 一同解释，tail 不单设结果导向阈值。

对 $H_{\mathrm{sym}}$，primary index 最小化 $|\lambda|$，competitor 是第二小
$|\lambda|$；报告
$|\lambda_1|/|\lambda_2|$、signed-spectrum separation
$\min_{j\ne1}|\lambda_j-\lambda_1|$，并用与选择规则一致的 gap

$$
g_H=\min_{j\ne1}\bigl||\lambda_j|-|\lambda_1|\bigr|
$$

判定 near degeneracy。这样 $+a$ 与 $-a$ 的 equal-$|\lambda|$ tie 不会被误判为 simple。
对 $A_{\mathrm{phys}}$，报告
$g_A=\sigma_2-\sigma_1$ 和 $\sigma_1/\sigma_2$。令 $n=2K$，分别冻结

$$
\delta_H=1000n\epsilon_{\mathrm{mach}}
  \max(1,\|H_{\mathrm{sym}}\|_2),\qquad
\delta_A=1000n\epsilon_{\mathrm{mach}}
  \max(1,\|A_{\mathrm{phys}}\|_2).
$$

若 $g_H>\delta_H$ 或 $g_A>\delta_A$，对象视为 numerically simple。每条 identity edge
要求 primary overlap 至少 $0.99$，并要求两个方向的 primary--competitor cross-overlaps 最大值
不超过 $0.5$。实际 gap、ratio 与全部 cross-overlaps 必须保存，不能只保存 verdict。

若 gap 不超过对应 $\delta$，不强选单向量：cluster 恰由所有满足
$\bigl||\lambda_j|-|\lambda_1|\bigr|\le\delta_H$ 的 eigenvectors，或所有满足
$\sigma_j\le\sigma_1+\delta_A$ 的 right singular vectors组成；cluster rank 没有预设上限，最多
为 $n$。因此必须保留完整 eigenspace/SVD right basis，或在无法形成完整 cluster 时 fail
unresolved，不能只用已保存的前两列代替。后者每列都按 $v\mapsto TD_cv$ 映射。零填充后
orthonormalize。两端
cluster rank 相同时用
$\sigma_{\min}(Q_a^*Q_b)$ 作 subspace overlap并要求至少 $0.99$；rank 不同则
`MODE_IDENTITY_UNRESOLVED`，双向 projection 只作诊断。这个 machine-scale cluster 是最小的
数值退化保护，不是谱分离保证或误差认证。

## 6. 符号与代码映射

| Mathematical object | Code role | Meaning |
|---|---|---|
| $N$ | `cfg.ntot` | inclusion boundary Nyström order |
| $M,K$ | `M`, `K=2*M+1` | Rayleigh cutoff and channel count |
| $q$ | `q = colwt.*v` | incoming amplitude `[aL;bR]` |
| $d$ | `trace = T*q` | physical Dirichlet trace `[left;right]` |
| $T$ | `T` | center amplitude-to-trace map |
| $A_{\mathrm{def}}$ | `Adef` | unweighted matching matrix |
| $D_r,D_c$ | `rowwt`, `colwt` | frozen I7 physical row/column weights |
| $A_{\mathrm{phys}}$ | `Aphys` | `Dr*Adef*Dc` |
| $H,H_{\mathrm{sym}}$ | `H`, `Hsym` | trace-coordinate right solve and Hermitian part |
| $\lambda_j,\sigma_j$ | saved spectra | Hsym eigenvalues and Aphys singular values |
| $\rho,E_{\mathrm{tail}}$ | overlap/tail diagnostics | same-mode evidence in common trace coordinates |

## 7. Mandatory gates、结果语义与证据

先串行完成六配置乘三个固定点，共 18 个 evaluations；不得把可选扫描插入其间。每点保存
configuration、$k$、matrix dimensions、QZ counts、warnings、timing 和必要 matrices/vectors。
复用 I7.2 的 fail-closed 条件：stable/unstable 必须为 $K/K$，neutral/indeterminate 为零；所有
对象 finite；`rcond(T)>=1e-8`；独立 `Adef=N0-L*T` 组装残差和 `H*T=Adef` 右解归一化残差均
不超过 $1000n\epsilon_{\mathrm{mach}}$；solve warning 为空。SVD/eig residual 也以
$1000n\epsilon_{\mathrm{mach}}$ 乘相应 matrix scale 作门。

每个 endpoint 仍用 I7.2 的

$$
\eta_c=\|H-H_{\mathrm{sym}}\|_2+
cn\epsilon_{\mathrm{mach}}\max(1,\|H_{\mathrm{sym}}\|_2),
\qquad c\in\{50,100,200\},
$$

完成 full triples。I7.3 stability gate 只把六配置的左右 endpoints 纳入符号计数验收：左右两端
三带都须稳定且无 unresolved；左端 $n_-=0$、右端 $n_-=1$，所以每个配置都有
$\Delta n_-=+1$。不同 $M$ 的 $n_+$ 随 matrix order 变化，不把它误作 drift。中心 $k_0$ 的主验收
对象是 $A_{\mathrm{phys}}$；中心若顺带形成 $H_{\mathrm{sym}}$，其 band-unresolved 只作诊断，不触发
endpoint count failure。全部 hard identity edges 还须通过第 5 节 simple-mode 或 subspace gate。

结果分层为：

- `STABLE_SAME_MODE`：18 点各自适用的 object gates、12 个 endpoint sign gates 与全部 hard
  identity edges 通过；
- `NUMERICAL_STABILITY_UNRESOLVED`：evaluation完成，但 count、condition、residual、warning、
  identity、cluster rank 或 competition gate 未通过；
- `EXECUTION_FAILED`：QZ/solve/eig/SVD 无法完成、对象非有限或资源硬门触发。

任何配置失败都保留已有证据并继续其他安全配置，但不得强取不合格子空间。即使得到
`STABLE_SAME_MODE`，结论仍只是六个有限离散对象的条件性数值稳定性。

入口必须在 point/config 层捕获预先分类的科学或数值失败，记录首个原因并继续其余安全配置；
unexpected programming error 仍 fail closed。每个完成或已捕获失败的 point 后都把当前
result/evidence 写入 formal output 的 partial checkpoint，最终成功再写完整 artifact。进程被资源
monitor hard-kill 时，最后一个 checkpoint 与 monitor/log 是可交付失败证据；不得声称未返回的
对象已完成。

## 8. 统一局部网格、位置漂移口径与资源门

本轮先 fresh 重算第 7 节 A 阶段的 18 点，再执行六配置的 local position-drift B 阶段；所有物理量
和 auxiliary/proxy 参数保持第 2 节取值，不执行 `AUX`。B 阶段不重复 $k_L,k_R$ 两个肩点。入口
可以保留每个 local point 原有的 $H_{\mathrm{sym}}$ 等 incidental diagnostics 以避免重写核心路径，
但不报告新的 endpoint 结果。
初始且当前唯一承诺的网格为

$$
k_j=k_0+(j-6)10^{-5},\qquad j=1,\ldots,11,
$$

nominal interval 为 `[1.755945740875,1.756045740875]`，实际 double endpoints 必须从本轮
MATLAB 产物记录，不能手抄预测；nominal spacing $d_k=10^{-5}$。六配置使用完全相同的
11 点和同一 `aphys_ratio`，包括 fresh $k_0$，共 66 evaluations；不读取旧矩阵、不 cache 旧点、
不拟合、不扩窗，也不实现自动细化。每个配置按有效点中的 `aphys_ratio` argmin 选择 sampled-grid
winner，同时报告同一点的 `aphys_sigma`、相对 `B` 的直接 winner drift、本轮 score improvement 和
两侧 neighbor score differences；另列 `aphys_sigma` 自己的 sampled argmin 仅作诊断，不用它改变
`aphys_ratio` 的选择规则。若 winner 是严格内点，位置 bracket 是相邻两个采样点组成的
区间，并把 grid spacing $d_k=10^{-5}$ 与完整邻点间距 $2d_k=2\times10^{-5}$ 并列报告；若 winner
在端点，则标为 boundary-limited，不构造越界 bracket。无效点记录原因并排除，但单点失败不立即
中止其他安全点。

同模态检查继续在 physical Dirichlet trace 坐标进行。每个 local $k$ 都沿第 2 节六条 edges 复用
现有 same-$k$ comparison：$A_{\mathrm{phys}}$ right singular vector 仍先经
$q=D_cv,d=Tq$ 映射，再比较 primary/competitor。每点 compact 保存 primary/competitor spectra、
cluster delta、physical traces 及 scalar diagnostic flag/reason；core gates 仍在点内执行，但 full
SVD residual 与完整 matrices 只为每配置 winner 保留。比较后释放其余大矩阵；若对象不再
numerically simple，则依第 5 节标为 identity unresolved，不强行配对。六配置返回相同 sampled
winner 只能表述为“在 spacing
$10^{-5}$ 的已完成网格未分辨出位置漂移”；这不是 zero error、sub-grid minimum、十位定位或
convergence。还必须报告完整 sampled curves 和 neighbor differences；数值平台或近并列会进一步
限制位置可辨性，不能由 array argmin 的次序给出更强结论。

本轮固定在共同 11 点网格后终止：winner 相同就报告 spacing $10^{-5}$ 下未分辨出漂移，winner
不同就只报告实际 sampled-grid drift；若出现 boundary/invalid，也照实报告有限覆盖及失败原因。
不因结果形态触发扩区、额外 5 点、fitting、extrapolation 或更细网格。

本轮全部 MATLAB、debug 与 audit 累计不超过 1800 s，用户给定的 process-tree RSS 硬上限仍为
3,000,000,000 bytes，且不得并发。正式执行采用更保守的 2,300,000,000-byte 提前终止线：启动前
确认没有其他 MATLAB/Octave；运行中每 0.1 s 同时采样本任务完整进程树 RSS 与系统中全部
MATLAB 进程 RSS，任一达到提前终止线或发现并发 MATLAB，就停止本任务进程、保留 checkpoint 与
monitor/log，不操作来源不明的其他进程。历史实测中 A、B 与 audit 分别约为 $365.18$ s、
$1250.06$ s 和 $13.89$ s，合计约 $1629.13$ s；因此当前 A 后 B 的完整复验在 1800 s 内只有约
$171$ s 余量。实际成本以本轮监测为准，不增加第二轮、`AUX` 或探索性计算。A 完成并保存/audit
后释放大矩阵，再串行进入 B；若实测剩余预算不足以安全完成 B 与最终 audit，必须保留 A 证据并
停止，不能删减科学门或借用旧结果。
阶段 A 成功才关闭 fixed-point stability；阶段 B 只增加有限网格的位置漂移证据，不改变其完成门或
科学判据。任何时刻达到 1800 s 或 2,300,000,000 bytes 提前终止线，立即停止本任务并保存现有证据。

以下两段只记录 2026-09-26 的资源事件，不描述本轮运行。Operational preflight 曾误启动一次
MATLAB `checkcode` 命令；进程在约 0.9 s 内以 exit 137
终止，未进入静态检查或任何 scientific point evaluation，未生成 artifact，RSS 未采样。该失败
只记入同一 run 的 operational log 和保守累计 wall time，不改变任何科学配置或 attempt。

随后用户报告一个来源未知的 MATLAB 任务曾占用约 17 GB 并导致强制重启。现有证据不能把该事故
归因于 I7.3；重启后主代理确认没有 MATLAB 进程，Engineer 也确认尚未启动 scientific run。
该事件只触发上述资源监测修订，不改变模型、六配置、比较图或结果语义。

## 9. 历史预注册的 `AUX` 联合辅助拟合加密（本轮不执行）

本轮明确不执行 `AUX`，且它不是完成条件；以下内容只保留 2026-09-26 的预注册配置和解释边界。

为区分“只在 `ntot`/$M$ 轴上观察到平台”与“proxy fit 也已受检”，预注册一个非 mandatory
辅助配置：保持 `ntot=512`、$M=64$ 及全部物理量不变，只把
`(nside,ntop,nproxy,mpw)` 联合提高到 `(240,240,120,48)`。它命名为 `AUX`，角色固定为
`JOINT_AUXILIARY_PROXY_FIT_REFINEMENT`；四个拟合参数共同变化，不能从结果中归因某一个参数，
也不能把它加入纯 `ntot` 或纯 $M$ ladder。

该 proxy fit 有

$$
2(240)+4(240)=1440
$$

个 equations 和

$$
4(120)+2(2(48)+1)=674
$$

个 unknowns；$A_{QP}$ order 仍为 $1024$，Rayleigh $K$ 仍为 $129$，所以没有新的代数尺寸
障碍。独立 `AUX` stage 不读取 mandatory MAT 或其他历史产物，而是在同一进程 fresh-evaluate
`J` 和 `AUX` 各自的 $k_L,k_0,k_R$，共 6 个 evaluations；运行内只形成三个相同 $k$、相同对象的
`J--AUX` comparisons，不做局部 scan。fresh `J` 是即时 control，不是新离散轴。逐点对象门、
endpoint counts 和 simple/cluster rules 与主六配置完全相同。跑后 audit 可报告 fresh `J` 与
mandatory `J` 的复算差异，但 `AUX` runtime 不以旧产物为输入。不得为恢复 jump、提高 overlap
或制造 dip 再调参数。

`AUX` 不得延迟 mandatory 六配置的实现或运行。mandatory 完成后，令 $\tau_J$ 为 `J` 三点中
最大实测耗时；只有当前已用时间、已批准 optional work 和保守 `AUX` 预算共同满足

$$
t_{\mathrm{used}}+9\tau_J\le2400\ \mathrm{s}
$$

且 mandatory 的 peak tree RSS 与 peak all-MATLAB RSS 都低于 2.3 GB，主代理才可另行授权它，
仍保留 300 s 收尾。这里 $3\tau_J$ 预算 fresh `J`，另以每个 `AUX` point 不超过
$2\tau_J$ 的保守投影预算其余 $6\tau_J$。若
optional scan 也将执行，两项 projection 必须一起计入同一个 2400 s 门。`AUX` 通过只能说明
这组联合 proxy-fit 加密未破坏 fixed-point counts/mode identity；失败是独立 sensitivity caveat，
不反向改写六配置结果。若不执行，则本轮只能报告 `ntot`/$M$ 平台，proxy 拟合离散的影响仍未测，
不能归因平台来源。

## 10. 2026-09-29 修正密度坐标后阶段 A 结果

当前 fixed-point 结果保存在
`test/i7/refine-v1/output/attempt-1/run-08/fixed/result.json`，同目录 `audit.json` 通过。
18/18 点有效，六配置的三个 $c$ 带在左右端点分别给出 $n_-=0$ 与 $n_-=1$、unresolved 为零，
所以每个配置都有 $\Delta n_-=+1$。六个中心点都出现一个 $H_{\mathrm{sym}}$ band-unresolved
eigenvalue；按第 7 节冻结规则，它只作诊断，中心 $A_{\mathrm{phys}}$ object gate 全部通过。

| Config | $d_H(k_L)$ | $d_H(k_R)$ | endpoint $n_-$ |
|---|---:|---:|---|
| `B` | $2.053125626861299\times10^{-13}$ | $2.1757952844695718\times10^{-13}$ | $0\to1$ |
| `M56` | $1.7896837769818797\times10^{-13}$ | $1.9315029336600774\times10^{-13}$ | $0\to1$ |
| `M64` | $2.3525238369337333\times10^{-13}$ | $2.3575573002234417\times10^{-13}$ | $0\to1$ |
| `N384` | $1.4283760109372483\times10^{-13}$ | $1.9819400640600291\times10^{-13}$ | $0\to1$ |
| `N512` | $1.9066299996174268\times10^{-13}$ | $1.6814498580484897\times10^{-13}$ | $0\to1$ |
| `J` | $2.6280010581193412\times10^{-13}$ | $2.0255191613586635\times10^{-13}$ | $0\to1$ |

完整 point gates 与 diagnostics 见当前产物 `fixed/points.csv`；上表只摘录进入 endpoint 结论的量。

| Config | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| `B` | $1.0113801620671046\times10^{-10}$ | $1.6739838415360665\times10^{-13}$ | $5.0025687287374273\times10^{-11}$ | $1.7513129037661042\times10^{-11}$ |
| `M56` | $1.0113337297569616\times10^{-10}$ | $1.4351103224081291\times10^{-13}$ | $5.0023479271823017\times10^{-11}$ | $1.7512356049555016\times10^{-11}$ |
| `M64` | $1.0113895968614702\times10^{-10}$ | $1.2560100350202761\times10^{-13}$ | $5.0026179341700115\times10^{-11}$ | $1.7513301297381378\times10^{-11}$ |
| `N384` | $1.0113517695200213\times10^{-10}$ | $1.6739368476688536\times10^{-13}$ | $5.0024383566187489\times10^{-11}$ | $1.7512672627392381\times10^{-11}$ |
| `N512` | $1.0113424612739088\times10^{-10}$ | $1.6739214411440174\times10^{-13}$ | $5.0023755495118554\times10^{-11}$ | $1.7512452750559667\times10^{-11}$ |
| `J` | $1.0113861394426398\times10^{-10}$ | $1.2560057413704718\times10^{-13}$ | $5.0026350871172081\times10^{-11}$ | $1.7513361346886731\times10^{-11}$ |

18 条 hard-edge/object comparisons 全部为 `SIMPLE_VECTOR / SAME_MODE` 并通过；最小 primary
overlap 为 $0.9999999999999994$，最大 cross-overlap 为
$5.1934739087163063\times10^{-14}$，最大 $|m|>48$ total squared tail 为
$1.1929356645472612\times10^{-30}$。六配置 `aphys_ratio` 的绝对 span 为
$1.0052973317143901\times10^{-15}$，`aphys_sigma` span 为
$2.8715993490638703\times10^{-15}$。图中自动纵轴会放大这些差异；它们不能解释为显著 dip 加深或
离散收敛率。

阶段 A 结论为 `STABLE_SAME_MODE`，限于六个修正密度坐标后的 finite-dimensional fixed-point
objects。baseline 左右端点的 counts 与修正后 I7.2 相同，$d_H$ 也分别为
$2.053125626861299\times10^{-13}$ 与 $2.1757952844695718\times10^{-13}$；独立 eigensolver 路径
可带来约 $10^{-12}$ 的 nearest-eigenvalue 舍入差，不能声称两份 spectrum 逐位相同。入口 runtime
为 $350.80521704166665$ s，阶段 wall 为 $358.846955$ s；完整资源与总预算见第 11 节。
fixed audit 复核 18 points 和 18 comparisons，四指标最大绝对差为
$4.5047767089100715\times10^{-18}$，overlap 最大绝对差为
$4.440892098500626\times10^{-16}$。

与第 12 节修正前结果比较时，左右 endpoints 的 $k_L,k_R$ 相同，因而 $d_H$ 可直接比较：六配置
均从约 $6.94\times10^{-3}$/$6.98\times10^{-3}$ 降到当前约
$1.43\times10^{-13}$--$2.63\times10^{-13}$，而 endpoint count jump 保持 $0\to1$。中心四指标
则不是 same-$k$ 回归：旧表在 $k_0=1.7545053299700002$，当前表在
$k_0=1.755995740875$，绝对位置差为 $1.4904109049997949\times10^{-3}$。当前指标比旧表小约
$5.75\times10^{-8}$ 倍只能描述各自采样点的 before/after 结果，不能把全部变化归因于密度修正，
也不能混同为本轮六配置相对 `B` 的离散漂移。

## 11. 2026-09-29 修正密度坐标后阶段 B 结果

当前 local 结果保存在
`test/i7/refine-v1/output/attempt-1/run-08/local/result.json`，同目录 `audit.json` 通过。实际 double
interval 为 `[1.7559457408749999,1.7560457408750001]`，nominal spacing 为 $10^{-5}$。66/66 点
有效且 point diagnostics 全部通过；六配置的 `aphys_ratio` sampled winner 与 `aphys_sigma` 自身
sampled argmin 都是 index 6，即 $k_0=1.755995740875$。

| Config | winner $k$ | bracket | full neighbor spacing | left ratio gap | right ratio gap |
|---|---:|---|---:|---:|---:|
| `B` | $1.755995740875$ | $[1.755985740875,1.756005740875]$ | $2.0000000000131024\times10^{-5}$ | $1.4870276308128473\times10^{-5}$ | $1.4870251468814921\times10^{-5}$ |
| `M56` | $1.755995740875$ | $[1.755985740875,1.756005740875]$ | $2.0000000000131024\times10^{-5}$ | $1.4870276308333567\times10^{-5}$ | $1.4870251470121332\times10^{-5}$ |
| `M64` | $1.755995740875$ | $[1.755985740875,1.756005740875]$ | $2.0000000000131024\times10^{-5}$ | $1.4870276307434020\times10^{-5}$ | $1.4870251469271948\times10^{-5}$ |
| `N384` | $1.755995740875$ | $[1.755985740875,1.756005740875]$ | $2.0000000000131024\times10^{-5}$ | $1.4870276307207669\times10^{-5}$ | $1.4870251468980830\times10^{-5}$ |
| `N512` | $1.755995740875$ | $[1.755985740875,1.756005740875]$ | $2.0000000000131024\times10^{-5}$ | $1.4870276308077021\times10^{-5}$ | $1.4870251469884793\times10^{-5}$ |
| `J` | $1.755995740875$ | $[1.755985740875,1.756005740875]$ | $2.0000000000131024\times10^{-5}$ | $1.4870276307492001\times10^{-5}$ | $1.4870251468153824\times10^{-5}$ |

阶段 B 在相同 $k_0$ 复算的每配置四指标与第 10 节 fixed 结果逐项 double-exact 相同，最大绝对差
为 0。66 条 same-$k$ hard-edge comparisons 全部为 `SIMPLE_VECTOR / SAME_MODE` 并通过；最小
primary overlap 为 $0.9999999999999994$，最大 cross-overlap 为
$3.6251735206506948\times10^{-14}$，最大 $|m|>48$ total squared tail 为
$8.5821055331273043\times10^{-32}$。local audit 的四指标最大绝对误差为
$4.5047767089100715\times10^{-18}$，trace relative error 为
$1.2208197869149605\times10^{-16}$，comparison 最大绝对误差为
$3.3306690738754696\times10^{-16}$。

因此结果为 `NO_DRIFT_RESOLVED_AT_SPACING_1E-5`：在这个共同的 11 点有限网格上，六配置没有分辨出
sampled winner 的位置漂移。它不证明 sub-grid minimum、位置误差界、连续最小点或收敛。B entry
runtime 为 $1255.9446958333333$ s，stage wall 为 $1259.272412$ s。A+B、保存、绘图与两个 audit
处于同一 monitored MATLAB process；总 wall 为 $1630.584183$ s，peak task-tree 与 all-MATLAB
RSS 均为 $1,505,230,848$ bytes，exit code 0，未发现 external MATLAB root，低于 1800 s 与
2,300,000,000-byte 提前终止线。本轮没有执行 `AUX` 或额外细化。

## 12. 修正前历史：Mandatory run-04 实际结果

正式结果保存在
`test/i7/refine-v1/output/attempt-1/run-04/result.json`，独立产物一致性检查保存在同目录
`audit.json`。18 个 mandatory points 全部有效，六配置的 endpoint counts 在三个 $c$ 值下均为
$n_-(k_L)=0$、$n_-(k_R)=1$ 且 unresolved 为零，因此每个配置都有
$\Delta n_-=+1$。18 条 hard-edge/object comparisons 全部采用 simple-vector 分支并通过：primary
overlap 的最小值为 $0.9999999999999998$，最大 cross-overlap 为
$4.4955713621624767\times10^{-14}$，而 $|m|>48$ 的最大 total squared-energy fraction 为
$7.434813581313716\times10^{-31}$。实际 gap 均远大于对应 machine-scale cluster threshold：
$H_{\mathrm{sym}}(k_L)$ 的最小 gap 约 $3.8479$、$H_{\mathrm{sym}}(k_R)$ 约 $3.8335$，而最大
$\delta_H$ 约 $4.61\times10^{-8}$；$A_{\mathrm{phys}}(k_0)$ 的最小 gap 约 $1.3639$，而最大
$\delta_A$ 约 $1.64\times10^{-10}$。没有触发 cluster fallback。

| Config | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| `B` | $1.7569097354396994\times10^{-3}$ | $2.9079455324122206\times10^{-6}$ | $8.695780272222505\times10^{-4}$ | $3.039999327579421\times10^{-4}$ |
| `M56` | $1.7569097354423450\times10^{-3}$ | $2.4931030870994640\times10^{-6}$ | $8.695780272235643\times10^{-4}$ | $3.039999327584020\times10^{-4}$ |
| `M64` | $1.7569097354393332\times10^{-3}$ | $2.1818458777629957\times10^{-6}$ | $8.695780272222487\times10^{-4}$ | $3.039999327579417\times10^{-4}$ |
| `N384` | $1.7569097354359138\times10^{-3}$ | $2.9079455324059542\times10^{-6}$ | $8.695780272202431\times10^{-4}$ | $3.039999327572403\times10^{-4}$ |
| `N512` | $1.7569097354430150\times10^{-3}$ | $2.9079455324177055\times10^{-6}$ | $8.695780272237895\times10^{-4}$ | $3.039999327584807\times10^{-4}$ |
| `J` | $1.7569097354567865\times10^{-3}$ | $2.1818458777846710\times10^{-6}$ | $8.695780272253854\times10^{-4}$ | $3.039999327590384\times10^{-4}$ |

沿纯 $M$ 轴，`adef_sigma` 的 span 只有 $3.01\times10^{-15}$，但 `adef_ratio` 从
$2.91\times10^{-6}$ 降到 $2.18\times10^{-6}$。由同一数据反算的
$\sigma_{\max}(A_{\mathrm{def}})$ 则从 $604.1756$ 增到 $805.2401$；所以 ratio 下降来自未加权
matrix scale 随端口阶数增长，不能解释为 dip 加深。物理加权后的 `aphys_sigma` 与
`aphys_ratio` 在纯 $M$ 轴上的 spans 分别为 $1.32\times10^{-15}$ 和
$4.60\times10^{-16}$，在纯 `ntot` 轴上分别为 $3.55\times10^{-15}$ 和
$1.24\times10^{-15}$。两端 $\|H-H_{\mathrm{sym}}\|_2$ 在各轴上的变化也只有约
$10^{-15}$。这是两个已测试离散轴上的明显 finite-dimensional plateau；不提供误差界，也不说明
proxy fit 已独立稳定。中心 $H_{\mathrm{sym}}$ 在六配置下均有一个 band-unresolved eigenvalue，
但中心 count 从未被预注册为 endpoint jump gate；中心验收对象是 $A_{\mathrm{phys}}$ singular mode。

结果的预注册语义因此为 `STABLE_SAME_MODE`，仍严格限于六个 finite-dimensional fixed-point
objects。入口 runtime 为 $340.25536841666667$ s，monitor wall time 为 $365.178545$ s，peak task
tree 与 all-MATLAB RSS 均为 $1,943,863,296$ bytes，未发现 external MATLAB root。跑后 audit
通过 18 points 和 18 comparisons 的独立产物重算；其四标量最大绝对差为
$7.047314121155779\times10^{-18}$，overlap 最大绝对差为
$2.220446049250313\times10^{-16}$。由实测得到 optional local-grid projection
$11\sum_r\tau_r=1268.4317245416667$ s，`AUX` projection
$9\tau_J=300.8579025$ s。该轮 local 66 点历史结果见第 13 节，但 fresh `J--AUX` 六点仍
明确不执行。因此 proxy tuple 敏感性仍未检验，现有平台不能归因于某一固定 auxiliary 参数已经
收敛。

## 13. 修正前历史：Local run-06 实际结果

正式 local 结果保存在
`test/i7/refine-v1/output/attempt-1/run-06/result.json` 和同目录 `scientific.mat`。六配置在 actual
double interval `[1.7544553299700001,1.7545553299700003]` 上各完成相同 11 点，共 66/66 valid，
所有 point diagnostics 通过。每个配置的 `aphys_ratio` sampled argmin 都是 index 6，

$$
k=k_0=1.7545053299700002.
$$

六个 `aphys_sigma` 自身的 sampled argmin 也都是同一 index 6；它们只作为一致性诊断，没有改变
ratio 选择规则。每个 winner 都由相同两个有效邻点
`[1.7544953299700001,1.7545153299700003]` 严格夹住，实际完整邻点间距为
$2.0000000000131024\times10^{-5}$。左侧 ratio gap 在
$[3.640444832375537,3.6404448597543524]\times10^{-7}$，右侧在
$[3.640253961360255,3.640253981513947]\times10^{-7}$；因此这不是由 sampled tie 决定的 array
argmin。六个 winner 的四指标与 mandatory run-04 在相同 $k_0$ 的保存值逐项完全相同。

11 个 $k$ 上的六条 hard edges 共给出 66 个 same-$k$ physical-trace comparisons，全部为
`SIMPLE_VECTOR / SAME_MODE` 并通过。最小 primary overlap 为 $0.9999999999999996$，最大
primary--competitor cross-overlap 为 $4.095494860270543\times10^{-14}$；没有触发 cluster
fallback。结果字段为 `NO_DRIFT_RESOLVED_AT_SPACING_1E-5`：它只表示在 nominal spacing
$10^{-5}$ 的共同有限网格上没有分辨出六配置 winner drift。它不是位置误差界、sub-grid minimum、
连续极小点或 convergence statement。因为六个 minima 都已由有效邻点严格夹住，按第 8 节终止规则
不执行更细网格、拟合或外推；`AUX` 也未执行。

入口 runtime 为 $1236.5274695833334$ s，monitor wall time 为 $1250.057854$ s；0.1 s 监测下的
peak task-tree 与 all-MATLAB RSS 均为 $1,606,238,208$ bytes，未发现 external MATLAB root，
exit code 为 0。跑后 audit 保存在 `output/attempt-1/run-07/audit.json`，复核 6 个 winners 和 66 个
same-$k$ edges 并通过；四指标最大绝对差为 $7.047314121155779\times10^{-18}$，weight 与 trace
重建相对差分别为 $1.089228815481544\times10^{-16}$ 和
$1.053762435480628\times10^{-16}$，comparison 最大绝对差为
$3.3306690738754696\times10^{-16}$。audit wall time 为 $13.889967$ s，peak tree RSS 为
$1,238,335,488$ bytes。本轮 I7.3 全部 MATLAB wall 保守累计为 $1699.729068$ s；其中新 local、
保留的停止证据与 audit 合计 $1320.661824$ s，低于 2700 s 总门。独立审查最终为
`PASS WITH CONDITIONS`；有限网格未分辨漂移的结论边界保持不变。
