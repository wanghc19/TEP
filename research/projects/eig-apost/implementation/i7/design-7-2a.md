# I7.2 Hermitian-part 端点符号计数设计

## 1. 目标与冻结范围

- Design ID: `I7.2-HSYM-ENDPOINT-V1`
- Status: `CORRECTED-DENSITY RERUN COMPLETE; PASS WITH CONDITIONS`
- Independent review: [[research/projects/eig-apost/implementation/i7/review-7-2a|I7.2 review]]
- 目标：在两个既定端点计算 raw $H$ 的 Hermitian part 符号计数，为 I7.1 dip 提供一项低成本
  numerical corroboration。
- 非目标：raw-$H$ inertia、严格 Hermitian 证明、root refinement、跨阶稳定性、连续特征值证明或
  误差认证。

方法沿用 [[research/projects/eig-apost/implementation/i2/design-2-2#19 当前路线修订 Hermitian-part endpoint sign-count|I2.2 第 19 节]]
的诊断语义，但所有矩阵由 I7 当前模型独立构造。实验实现放在 `test/i7/inertia-v1/`；运行代码不得
读取本设计、README、Git 或历史输出。

冻结参数为：

| 项目 | 值 |
|---|---:|
| $\beta$、period $d$ | $0.5, 1$ |
| walls $X_L,X_R$ | $-0.5, 0.5$ |
| circular leads | radius $0.2$, `epsrel=17` |
| center inclusion | ellipse semi-axes $(0.25,0.16)$, `epsrel=2` |
| final spatial tuple | $(256,160,160,80,32)$ |
| Rayleigh order | $M=48$, $K=97$ |
| endpoints | $k_L=1.753125$, $k_R=1.75625$ |

端点不得因结果移动、交换或加密。本轮只评价这两个点，不调用 locator 或新扫描。

## 2. 端口、迹和法向

中心 scattering map 的未知量与输出保持 I7.1 约定：

$$
q=\begin{bmatrix}a^L\\b^R\end{bmatrix},
\qquad
\begin{bmatrix}b^L\\a^R\end{bmatrix}
=
\begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}q.
$$

所有 trace block 统一按 `[left; right]` 排列。令 $G=\operatorname{diag}(\gamma_m)$：

| block | Dirichlet trace | center outward Neumann trace | direction | lead map |
|---|---|---|---|---|
| left | $d_L=(I+R_L)a^L+T_{RL}b^R$ | $n_L=\mathrm{i}G[(R_L-I)a^L+T_{RL}b^R]$ | $-\partial_x$ | $\Lambda_-d_L$ |
| right | $d_R=T_{LR}a^L+(I+R_R)b^R$ | $n_R=\mathrm{i}G[T_{LR}a^L+(R_R-I)b^R]$ | $+\partial_x$ | $\Lambda_+d_R$ |

因此只需三个具有独立数值职责的矩阵：

$$
T=
\begin{bmatrix}
I+R_L&T_{RL}\\
T_{LR}&I+R_R
\end{bmatrix},
\qquad
N_0=
\begin{bmatrix}
\mathrm{i}G(R_L-I)&\mathrm{i}GT_{RL}\\
\mathrm{i}GT_{LR}&\mathrm{i}G(R_R-I)
\end{bmatrix},
$$

$$
L=\operatorname{blkdiag}(\Lambda_-,\Lambda_+).
$$

这里 $Tq=[d_L;d_R]$、$N_0q=[n_L;n_R]$，matching residual 为
$[n_L-\Lambda_-d_L;n_R-\Lambda_+d_R]$。

## 3. 独立 $A_{\mathrm{def}}$ 与 raw $H$

必须先按 I7.1 已核对的四块公式独立组装

$$
A_{\mathrm{def}}=
\begin{bmatrix}
(\mathrm{i}G-\Lambda_-)R_L-(\mathrm{i}G+\Lambda_-)&
(\mathrm{i}G-\Lambda_-)T_{RL}\\
(\mathrm{i}G-\Lambda_+)T_{LR}&
(\mathrm{i}G-\Lambda_+)R_R-(\mathrm{i}G+\Lambda_+)
\end{bmatrix}.
$$

这里使用未加 I7.1 row/column weights 的 raw $A_{\mathrm{def}}$。不得用 $N_0-LT$ 定义
$A_{\mathrm{def}}$，否则第一个恒等式检查会成为自证。令 $n=2K=194$，
冻结的坐标/求解可靠性诊断门为

$$
\operatorname{rcond}(T)\ge 10^{-8},
$$

$$
r_{\mathrm{id}}=
\frac{\lVert A_{\mathrm{def}}-(N_0-LT)\rVert_F}
{\max\{1,\lVert A_{\mathrm{def}}\rVert_F+\lVert N_0\rVert_F+
\lVert L\rVert_F\lVert T\rVert_F\}}
\le 1000n\epsilon_{\mathrm{mach}}.
$$

只用 MATLAB right solve

$$
H=A_{\mathrm{def}}/T
$$

因此 $H$ 在 physical trace coordinates 中把 $d=Tq$ 映到 $n-Ld$。同时检查

$$
r_{\mathrm{solve}}=
\frac{\lVert A_{\mathrm{def}}-HT\rVert_F}
{\max\{1,\lVert A_{\mathrm{def}}\rVert_F+
\lVert H\rVert_F\lVert T\rVert_F\}}
\le 1000n\epsilon_{\mathrm{mach}}.
$$

禁止 `inv`、`pinv`、整体归一化或为改善结构而重组另一套 $A_{\mathrm{def}}$。

## 4. Hermitian-part 三带计数

raw $H$ 不要求 Hermitian。对每个端点只构造

$$
H_{\mathrm{sym}}=\frac{H+H^*}{2},
\qquad
s=\lVert H_{\mathrm{sym}}\rVert_2,
\qquad
d_H=\lVert H-H_{\mathrm{sym}}\rVert_2.
$$

对 $c\in\{50,100,200\}$ 定义

$$
\eta_c=d_H+cn\epsilon_{\mathrm{mach}}\max(1,s).
$$

$c=100$ 是主带。$H_{\mathrm{sym}}$ 的实 eigenvalues $\lambda_j$ 按

$$
\lambda_j>\eta_c\Rightarrow +,
\qquad
\lambda_j<-\eta_c\Rightarrow -,
\qquad
|\lambda_j|\le\eta_c\Rightarrow \text{unresolved}
$$

分类，等号归入 unresolved。每个 band 的三类计数之和必须为 $n$。若任一端点三带计数不一致、
主带存在 unresolved，或第 3 节的 $T$ 条件数、identity、right-solve 任一可靠性门失败，则整体
科学结果为 `UNRESOLVED`；否则令

$$
\Delta_-=n_-(k_R)-n_-(k_L),
\qquad
\Delta_+=n_+(k_R)-n_+(k_L).
$$

$\Delta_-\ne0$ 记 `JUMP`，$\Delta_-=0$ 记 `NO_JUMP`。三种结果都合规，不预设 jump 的方向或大小。
$d_H$ 只量化 raw $H$ 到本次 Hermitian part 的距离；$\eta_c$ 只是 surrogate
structure/roundoff resolution band，不是 raw-$H$ eigenvalue error、$k$ 误差、离散误差或谱认证。

## 5. 运行门、输出与预算

每个端点必须核验冻结模型与 shapes、QZ stable/unstable count、neutral/indeterminate pair、线性
求解 warning、finite 值、$T$ 条件数和两项残差。Hermitian eigensolve 的 imaginary leakage 参考门为
$100n\epsilon_{\mathrm{mach}}\max(1,s)$。若有限 $H/H_{\mathrm{sym}}$ 和谱已经完整算出，但 $T$ 条件数、
identity、right-solve、band sensitivity、主带 unresolved 或有限 $H$ 所伴随的求解 warning 门失败，
仍可记 `execution_pass=true`，但科学结果必须是 `UNRESOLVED`，并保存首个失败原因。QZ 分类不合格时
不得提取子空间；非有限对象、right solve/eigensolve 无法完成、明显 imaginary leakage、计数不能形成
完整 partition 或运行被资源门终止时，均记 execution failure。不得强行取实部、绕过 QZ 或补造计数。

保存每端的 $k$、`rcond(T)`、$r_{\mathrm{id}}$、$r_{\mathrm{solve}}$、$s$、$d_H$、三组 $\eta_c$、
eigenvalue extrema、三带 counts，以及 $\Delta_\pm$、`JUMP/NO_JUMP/UNRESOLVED`、运行命令和资源
记录。输出必须分开 `raw_inertia_available=false` 与
`surrogate_sign_count_available=true`。

两点的预计 MATLAB 时间为几十秒，process-tree peak RSS 约 $1.3$ GB；串行运行，不叠加其他 MATLAB
进程。本轮正式运行、debug 与 audit 的全部 MATLAB 计算累计不得超过 1800 s；任一时刻的
process-tree RSS 不得超过 3,000,000,000 bytes，并为独立审查和交付预留时间。若资源门失败，保存
实际原因；不得移动端点、降低冻结空间配置或把低阶结果补作正式结果。

允许的最强结论是：同一冻结 fine/$M=48$ evaluator 的 Hermitian-part endpoint sign count 是否为
I7.1 dip 提供数值佐证。即使得到 `JUMP`，也不能声称 raw $H$ 有严格实根、candidate 已是 continuous
eigenvalue，或已经得到 posterior error estimate。未决解释只在
[[research/projects/eig-apost/implementation/i7/README#I7 待办与问题|I7 唯一问题表]]跟踪。

## 6. 修正前历史端点结果

> **2026-09-29 状态。** 下列 `attempt-1/run-01` 数值使用修正前的
> `bloch.construct_S` 密度坐标链，仅保留为历史有限矩阵快照。现行公共函数已修正平方根求积密度
> 坐标；使用相同入口、模型、配置和端点的独立复验正在
> [[test/i7/inertia-v1/README#Corrected-density rerun|实验 README]] 跟踪。

`attempt-1/run-01` 在冻结端点和配置上完成，`execution_pass=true`，两端的坐标/求解诊断门均通过。
下表的 counts 按 $(n_+,n_-,n_{\mathrm{unresolved}})$ 排列；三个 band 的 triple 在每个端点完全
相同。

| endpoint | `rcond(T)` | $r_{\mathrm{id}}$ | $r_{\mathrm{solve}}$ | $s$ | $d_H$ | $\eta_{100}$ | min eig | min abs eig | counts $c=50/100/200$ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| $k_L=1.753125$ | $0.51766478180359732$ | $7.7553407108811573\times10^{-19}$ | $5.55519314320784\times10^{-19}$ | $604.17561555534121$ | $0.0069403631805661781$ | $0.0069403657831525337$ | $0.010244089942464089$ | $0.010244089942464089$ | $(194,0,0)$ / $(194,0,0)$ / $(194,0,0)$ |
| $k_R=1.75625$ | $0.51763717683588528$ | $5.8232041509314594\times10^{-19}$ | $3.8366990628339002\times10^{-19}$ | $604.17557925199674$ | $0.006976092528270513$ | $0.0069760951308567125$ | $-0.012954744810377465$ | $0.012954744810377465$ | $(193,1,0)$ / $(193,1,0)$ / $(193,1,0)$ |

因此 $\Delta_-=+1$、$\Delta_+=-1$，预注册分类为 `JUMP / SINGLE_JUMP`，且
`band_sensitivity=STABLE`。同一正式命令的额外矩阵/count audit 得到 Hermitian-part、eigenvalues
和 counts defect 均为 0。该结果只说明冻结 I7 evaluator 的 Hermitian-part endpoint sign count 支持 dip；raw
$H$ 的 $d_H$ 非零，故结论仍不是 raw-$H$ inertia、严格实根或连续特征值认证。

入口 runtime 为 $21.43027775$ s；受监测 wall time 为 $42$ s，process-tree peak RSS 为
$1{,}107{,}099{,}648$ bytes，没有失败运行。实际命令与完整保存值见
[[test/i7/inertia-v1/output/attempt-1/run-01/command.txt|command]]、
[[test/i7/inertia-v1/output/attempt-1/run-01/result.json|result]] 和
[[test/i7/inertia-v1/output/attempt-1/run-01/audit.json|matrix/count audit]]。

## 7. 2026-09-29 修正密度坐标复验

`attempt-1/run-02` 用未修改的 `check_i7_inertia()` 入口、冻结模型、配置、端点和三组 band，
但两类 cell 均经过已修正的公共 `bloch.construct_S`。运行不读取 run-01，所有对象门、谱门、
partition 和同进程矩阵复算均通过。

| endpoint | `rcond(T)` | $d_H$ | $\eta_{100}$ | min abs eig | counts $c=50/100/200$ |
|---|---:|---:|---:|---:|---|
| $k_L=1.753125$ | $0.51702058265282613$ | $2.053125626861299\times10^{-13}$ | $2.6027916682723556\times10^{-9}$ | $0.021226887784655889$ | $(194,0,0)$ / $(194,0,0)$ / $(194,0,0)$ |
| $k_R=1.75625$ | $0.5169934488000496$ | $2.1757952844695718\times10^{-13}$ | $2.6028037788554658\times10^{-9}$ | $0.001880568371886166$ | $(193,1,0)$ / $(193,1,0)$ / $(193,1,0)$ |

因此修正后仍为 $\Delta_-=+1$、$\Delta_+=-1$ 和 `JUMP / SINGLE_JUMP`。这只更新冻结
fine/$M=48$ 的 Hermitian-part 数值佐证；修正后的 I7.3 跨离散同模态证据仍待独立复验。入口
runtime 为 $17.265248375$ s，受监测 wall time 为 $28.184776$ s，process-tree peak RSS 为
$1{,}140{,}686{,}848$ bytes。完整当前结果、复现命令和历史边界见
[[test/i7/inertia-v1/README#Corrected-density rerun|I7.2 实验 README]]。
