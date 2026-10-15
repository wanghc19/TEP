# I8.2：星形候选的五配置固定点检查设计

## 1. 状态与结论边界

- Design ID: `I8.2-STAR-FIXED-V1`
- Status: `COMPLETE; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Entry: `check_i8(k0,halfwidth)`
- Claim boundary: `FINITE-DIMENSIONAL HERMITIAN-PART COUNTS AND MODE STABILITY ONLY`

本轮固定 [[research/projects/eig-apost/implementation/i8/design-8-1b|I8.1b]] 的
binary64 候选

$$
k_0=1.7562818500073463
$$

并在两个肩点和五个离散配置上重算矩阵。它不重新定位 $k_0$，不计算谱距离或 $R_{\rm num}$，也不
声称 raw-$H$ inertia、连续根或离散收敛。Hermitian-part 符号计数沿用
[[research/projects/eig-apost/implementation/i7/design-7-2a|I7.2]]；physical-trace 同模态比较沿用
[[research/projects/eig-apost/implementation/i7/design-7-3a|I7.3]]，但只保留本轮五配置和两条轴。

## 2. 模型、固定点与配置

物理模型保持 I8.1：$\beta=0.5$，period $d=1$；左右 lead 是半径 $0.2$、`epsrel=17` 的圆；
中心是六行统一乘 $s_*=\sqrt{0.04/0.0618}$ 的公共五瓣星形、`epsrel=2`；人工墙为
$X_L=-0.5,X_R=0.5$。公共 `bloch.construct_S` 已在 scaled system 求解后恢复 physical density，
本入口不得增加第二次 density scaling。

初始波数半宽 $h_k=10^{-5}$，每个配置都使用由同一 binary64 运算形成的

$$
k_L=k_0-h_k,\qquad k_C=k_0,\qquad k_R=k_0+h_k.
$$

初始实际端点为 `1.7562718500073462` 和 `1.7562918500073463`；保存值以运行时 double 为准。
固定 `(nside,ntop,nproxy,mpw)=(160,160,80,32)`，五配置为

| Name | `ntot` | $M$ | $K=2M+1$ | Axis |
|---|---:|---:|---:|---|
| `B` | 256 | 48 | 97 | baseline |
| `N384` | 384 | 48 | 97 | boundary |
| `N512` | 512 | 48 | 97 | boundary |
| `M56` | 256 | 56 | 113 | Rayleigh |
| `M64` | 256 | 64 | 129 | Rayleigh |

公共 cell solve 的 $A_{QP}$ 阶为 $512,768,1024$，最大端口批次只有 $2K=258$ 个 right-hand
sides。固定 proxy fit 有

$$
2n_{\rm side}+4n_{\rm top}=960
$$

个 equations 和 $4n_{\rm proxy}+2(2m_{\rm pw}+1)=450$ 个 unknowns。`nside` 是 proxy wall
collocation，`mpw` 是 proxy plane-wave order，都不是 Rayleigh cutoff；故 $M=64$ 在接口和尺寸上
相容，无需同步改变其他参数。若实际 proxy、BIE、QZ 或 solve 门失败，只能报告 unresolved，不能
静默调高辅助配置。

## 3. 三点矩阵与符号计数

amplitude order 固定为 $q=[a^L;b^R]$，physical trace order 为 $d=[d_L;d_R]$。每点独立构造

$$
T=\begin{bmatrix}I+R_L&T_{RL}\\T_{LR}&I+R_R\end{bmatrix},\qquad
N_0=\begin{bmatrix}
\mathrm{i}G(R_L-I)&\mathrm{i}GT_{RL}\\
\mathrm{i}GT_{LR}&\mathrm{i}G(R_R-I)
\end{bmatrix},
$$

$$
L=\operatorname{blkdiag}(\Lambda_-,\Lambda_+),\qquad
H=A_{\rm def}/T,\qquad H_{\rm sym}=\frac{H+H^*}{2}.
$$

$A_{\rm def}$ 必须用 I8.1 的四块公式独立组装，再检查 $A_{\rm def}=N_0-LT$；不能用该恒等式
定义它。对 $n=2K$ 设

$$
s=\lVert H_{\rm sym}\rVert_2,\qquad
d_H=\lVert H-H_{\rm sym}\rVert_2,
$$

$$
\eta_c=d_H+cn\epsilon_{\rm mach}\max(1,s),\qquad c\in\{50,100,200\}.
$$

每个点保存三组 $(n_+,n_-,n_0)$，等号归入 unresolved $n_0$。符号验收只使用 $k_L,k_R$：
每个 endpoint 的三组 full triples 应一致且 $n_0=0$，再比较各配置的 $n_-$ 和
$\Delta n=(\Delta n_+,\Delta n_-,\Delta n_0)$，其中每一分量都取右端减左端。不同 $M$ 的总维数
和 endpoint 的 $n_+$ 可以不同，不把它误作 drift；jump 比较使用各配置内部的 $\Delta n$，不预设
其值或方向。

$k_C$ 的 counts 单独标为 `CENTER_COUNT_RESOLVED` 或 `CENTER_COUNT_UNRESOLVED`。中心存在 unresolved
eigenvalue 不触发肩点扩张，也不使已完成的有限矩阵 evaluation 失败；它不能代替 endpoint jump。
中心的矩阵、QZ、right-solve 或 eigensolve 门失败仍是对象失败，不能用这一例外绕过。

## 4. 统一肩点扩张

只有完整一轮完成后，若任一配置的任一 endpoint 在任一 $c$ band 有 $n_0>0$，主代理才可显式
选择 $h_k\leftarrow2h_k$。最多扩张两次，即依次使用 $h_k=2\times10^{-5}$、$4\times10^{-5}$。每次必须
fresh 重算全部五配置乘三个点；不得混用不同半宽的 center/endpoints，也不得读取旧矩阵作为数值
输入。center unresolved、配置间 count 不一致、mode overlap 不佳或想得到指定 jump 都不是扩张理由。
两次扩张后仍有 endpoint unresolved，则如实交付 `ENDPOINT_COUNT_UNRESOLVED`。

## 5. Physical-trace 同模态比较

只比较相同 $k$、相同对象和同一 halfwidth stage。四条主 edges 为
`B--N384`、`N384--N512`、`B--M56`、`M56--M64`，并在 $k_L,k_C,k_R$ 分别进入正式 mode 门；
另存 `B` 对其余四配置的 $k_C$ center 摘要，后者不进入正式门。
在 $k_L,k_R$ 比较 $H_{\rm sym}$ 的 nearest-$|\lambda|$ mode。它的右 eigenvector 已在 physical
Dirichlet trace coordinates 中，不再乘 $T$。在 $k_C$ 比较 $A_{\rm phys}=D_rA_{\rm def}D_c$ 的
最小右 singular mode；若 $v$ 是 right singular vector，必须先恢复

$$
q=D_cv=\texttt{colwt.*v},\qquad d=Tq.
$$

不得直接比较 $v$ 或 $q$。跨 $M$ 时按真实 $m=-M{:}M$ 标签分别对齐 left/right blocks，并零填充
缺失 mode；保存 high-$M$ 对象在 edge-low cutoff 之外的 left/right/total squared-norm fractions。

使用 phase/scale-invariant overlap。对 $H_{\rm sym}$ 与 $A_{\rm phys}$ 分别定义

$$
g_H=\min_{j\ne1}\bigl||\lambda_j|-|\lambda_1|\bigr|,
\qquad g_A=\sigma_2-\sigma_1,
$$

$$
\delta_H=1000n\epsilon_{\rm mach}\max(1,\lVert H_{\rm sym}\rVert_2),
\qquad
\delta_A=1000n\epsilon_{\rm mach}\max(1,\lVert A_{\rm phys}\rVert_2).
$$

若 $g>\delta$，simple-mode 门为 primary overlap 至少 $0.99$，且两个方向的 primary--competitor
cross-overlap 最大值不超过 $0.5$。若 $g\le\delta$，不得强配单向量：cluster 包含所有满足
$\bigl||\lambda_j|-|\lambda_1|\bigr|\le\delta_H$ 的 eigenvectors，或
$\sigma_j\le\sigma_1+\delta_A$ 的 right singular vectors；后者每列都按 $v\mapsto TD_cv$ 映射。
零填后 orthonormalize；同 rank cluster 以 $\sigma_{\min}(Q_a^*Q_b)\ge0.99$ 为门，rank 不同则
`MODE_IDENTITY_UNRESOLVED`。保存实际 gaps、ratios、cluster ranks、primary/competitor overlaps 和
tail fractions，不能只保存 verdict。

## 6. 运行门、结果语义与预算

每轮固定 15 点串行运行。每点要求 QZ stable/unstable 为 $K/K$、neutral/indeterminate 为零，全部
对象 finite，无数值/线性求解 warning，并满足

$$
\operatorname{rcond}(T)\ge10^{-8},\qquad
r_{\rm id},r_{\rm solve},r_{\rm eig},r_{\rm svd}
\le1000n\epsilon_{\rm mach}
$$

的相应归一化残差门。SVD 门只在 center 对象需要；endpoint eig 门和 count partition 必须通过。
若执行和对象门通过，结果分开报告 endpoint count stability、center count 状态和 mode identity；只有
五配置的左右 endpoint $n_-$ 与 jump vector 一致，且四条主 edge 的三个对象均通过时才记
`STABLE_SAME_MODE`，否则记 `NUMERICAL_STABILITY_UNRESOLVED`。`jump_present` 只由实际
$\Delta n_-\ne0$ 决定，`NO_JUMP` 也是合规数值结果。任何合规结果都交付；不把相似度称为认证。

参考 I7.3 的 18 点运行约 $351$ 秒，初始 15 点预计约 5--7 分钟。若两次统一扩肩都实际执行，最多
45 点，预计约 15--20 分钟；连同 debug、audit 和所有重跑共享 2700 秒计算预算与
$3{,}000{,}000{,}000$ bytes process-tree RSS 上限，不得并发 MATLAB，并须保留收尾时间。输出包括
每阶段全部点、实际 endpoints、配置和矩阵维数、完整 bands/counts、gates、spectra/modes、edges、
扩肩决策、资源记录与复现命令。运行代码不得读取本设计、Git 或历史输出。

## 7. 实际执行

正式结果见
[[test/i8/check-v1/output/attempt-1/run-01/result.json|run-01 result]] 和
[[test/i8/check-v1/output/attempt-1/run-01/status.txt|resource status]]。初始半宽即完成，未触发扩肩：
$15/15$ 点有效，实际三点为
`[1.7562718500073462, 1.7562818500073463, 1.7562918500073463]`。五配置在三个
$c$ bands 上均给出左肩 $(n_+,n_-,n_0)=(2K,0,0)$、右肩
$(2K-1,1,0)$，所以内部 jump vector 一致为 $(-1,+1,0)$。五个 center 则均为
$(2K-1,0,1)$；这是单独保存的 `SURROGATE_SIGN_UNRESOLVED`，未被当作 endpoint 失败。

四条主 edge 的 $12$ 个同对象比较全为 `SAME_MODE`：最小 primary overlap 为
$0.9999999999999997$，最大双向 competitor cross-overlap 为
$2.325126673691677\times10^{-5}$，$|m|>48$ 的最大 squared-norm tail fraction 为
$5.344658457192319\times10^{-31}$。所有对象门通过，程序状态为 `STABLE_SAME_MODE`；这仍只是
本节开头限定的有限维数值结论。跑后
[[test/i8/check-v1/output/attempt-1/run-02/audit.json|artifact audit]] 复核 $15$ 点、$12$ 条主比较和
$4$ 条 center 摘要并通过，最大记录差异为 $1.161955392472124\times10^{-14}$。正式入口耗时
$244.3254000417$ 秒，正式运行监控 wall time $270.179383$ 秒、process-tree peak RSS
$1{,}035{,}288{,}576$ bytes；含审计的累计监控 wall time 为 $293.254261$ 秒，全轮监测峰值为
$1{,}083{,}080{,}704$ bytes。独立审查见
[[research/projects/eig-apost/implementation/i8/review-8-2a|review-8-2a]]；其条件不改变上述
finite-dimensional claim boundary。
