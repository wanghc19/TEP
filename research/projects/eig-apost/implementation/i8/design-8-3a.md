# I8.3：新星形候选的冻结场数值距离估计设计

## 1. 范围与状态

- Design ID: `I8.3-STAR-RAW-V1`
- Status: `CONTINUATION COMPLETE; INDEPENDENT REVIEW PASS WITH CONDITIONS`
- Review: [[research/projects/eig-apost/implementation/i8/review-8-3a|review-8-3a]]
- Entry: `[result,evidence] = estimate_i8(k0,center_ntot,lead_ntot)`
- Claim boundary: `ORDINARY-DOUBLE UNCERTIFIED RNUM ONLY`

本轮只在 [[research/projects/eig-apost/implementation/i8/design-8-1b|I8.1b]] 的新候选

$$
k_0=1.7562818500073463
$$

重建一次 baseline 冻结场，并沿用
[[research/projects/eig-apost/implementation/i7/design-7-4a|I7.4 raw-field chain]] 与
[[test/i8/flow-v1/README|旧 I8 flow]] 的普通数值评价。它不扫描、不重做 inertia、不计算新位置，
也不把 $R_{\rm num}$ 称为谱距离证书。旧 I8 flow 的场与数值不能作为本轮输入。

## 2. 冻结模型、坐标与参数

模型固定为 $\beta=0.5$、$d=1$、$X_L=-0.5$、$X_R=0.5$；lead 是半径 $0.2$、
`epsrel=17` 的圆，中心是公共五瓣星形全部六行乘
$s_*=\sqrt{0.04/0.0618}$、`epsrel=2`。baseline 配置为
`(ntot,nside,ntop,nproxy,mpw,M)=(256,160,160,80,32,48)`。中心和 lead 都必须经修正后的公共
`bloch.construct_S` 返回 physical density；实验不得再次施加 square-root quadrature scaling。

令 $\widehat k_0$ 是输入 double 的 exact binary64 dyadic，数学参数定义为 exact-real square

$$
\mu=\widehat k_0^2.
$$

普通 MATLAB 标量另存 `mu_num=fl(k0*k0)`，仅用于本轮 double 的 $C_{\rm num}$ 与
$R_{\rm num}$。本候选的 `mu_num` 是 `3.0845259366652269`，而 exact dyadic square 约为
`3.08452593666522673420986057516`；两者之差约 $1.63\times10^{-16}$。不得称 `mu_num` 为 exact
square，也不得从 `mu_num` 反求或替换 $k_0$。材料波数、
Rayleigh 根和核函数均从同一 $k_0$、$\beta$、$d$ 普通评价；其舍入没有被认证。

从 fresh $A_{\rm phys}=D_rA_{\rm def}D_c$ 的最小 right singular vector 得到
$q=D_cv=[a^L;b^R]$，再统一作一次 Euclidean normalization 和 phase anchor。中心 physical density

$$
\eta_c=[\tau_c;\zeta_c]
=\operatorname{fl}(H_La^L+H_Rb^R),\qquad \zeta_c=-\sigma_c,
$$

以及 lead 的 $G_\pm,P_\pm,c_\pm$ 都在本轮 fresh 构造后冻结。所有 material、wall、tail 和 mass
使用同一个最终 $q$ 与这些 frozen arrays；共同 scale/phase 不影响齐次比值，但不得在分项间重新归一化。
传播 state 固定为

$$
x_{+,n}=G_+P_+^nc_+,\qquad x_{-,n}=G_-P_-^nc_-.
$$

QZ 必须为 $K/K/0/0$，$P_\pm$ 的 right-solve、trace-coordinate 与 recurrence 残差须通过既有门；
neutral 或 indeterminate 子空间不得强取。

## 3. 同一冻结场的两层 raw 评价

两层都使用 frozen 256-node density 的 trigonometric interpolant，不重新解 density：

| Level | material source/target | wall source/target | disk grid |
|---|---:|---:|---:|
| coarse | 512 | 512 | $16\times32$, unshifted angle |
| fine | 768 | 768 | $32\times64$, half-angle shifted |

因此 coarse--fine 差同时含 source/target quadrature 与 evaluator 变化，不是 density 离散收敛，也不
隔离单个误差来源。若 $A_N^s$ 是公共 `op.construct_A_QP` 的 scaled matrix，
$W_N=\operatorname{diag}\sqrt{(2\pi/N)[v_N;v_N]}$，则 frozen physical density 的 raw action 为

$$
r_N=W_N^{-1}A_N^sW_N\eta_N+B_Nq,\qquad
a_N=r_N(1{:}N),\qquad j_N=-r_N(N+1{:}2N).
$$

第二 block 的 identity 已包含在公共 operator 中，不能删除或在外部重复。中心星形 singleton 直接用
$\eta_c$；lead 圆的同一个 raw action 依次作用于 $x_{\pm,n}$。每层保存 signed vectors、弧长权重、
平方范数、scale roundtrip 和 raw-coordinate consistency；只保存模长总数不足以审计法向符号。

## 4. 完整普通数值分项

每层必须逐项保存并且每条物理界面只计一次：

1. center-star material singleton；
2. 左右各 $n=0,\ldots,39$ 的 lead-circle material 项；
3. 两条 center--lead wall singleton；
4. 左右各 $40$ 条 internal lead wall；
5. material 与 internal-wall 各自从第 41 项开始的 observed infinite-tail candidate。

墙迹必须由同一 frozen raw center/lead layer fields 在物理墙直接评价，不能用有限 Rayleigh scattering
trace 代替。左、右 center--lead value jumps 分别取 `lead.right-center.left` 与
`lead.left-center.right`；normal signs 沿现有 raw chain 分别取 `lead.dx-center.dx` 与
`center.dx-lead.dx`。internal wall 继续使用相邻 $G_\pm P_\pm^nc_\pm$ 的配对式。
QZ pencil、trace-coordinate 和 recurrence residual 只检查传播坐标与递推；它们不再作为一项独立
jump energy 加入，因为所得不匹配已经由 physical internal-wall 项计入。直接 physical-wall 评价也
已经包含 frozen layer field 超出 retained Rayleigh channels 的内容，不能另加一次“遗漏模态”项。

尾项只在 next term finite 且观察比率 $0\le r<1$ 时取 $e_{40}/(1-r)$，并明确标为 candidate，
不是 one-sided bound。ratio 不合格、tail 非有限或任何分项缺失时不得用零补齐，完整
$R_{\rm num}$ 不可形成。fine 层汇总

$$
E_v=E_v^{\rm material}+E_v^{\rm wall},\qquad
E_n=E_n^{\rm material}+E_n^{\rm wall},\qquad
\varepsilon_{\rm num}=\sqrt{E_n+E_v/d^2}.
$$

safe disk 固定为 $B((3/8,0),1/16)$，位于中心背景区；每层直接评价同一个 center raw field，并取

$$
U_{\rm num}=\left(\pi(1/16)^2\,\operatorname{mean}|u|^2\right)^{1/2}
$$

的 fine-grid 值。几何 clearance 与 coarse--fine disk 变化都要保存。该有限子域积分在 exact
arithmetic 中对应全域质量的一部分，但这里的 quadrature 没有单侧余项，所以 `U_num` 不是
$\underline U$。

## 5. Sampled geometry、$C_{\rm num}$ 与状态

沿用两层 4096/8192 star geometry 检查、collar half-width $h=0.004$、arc band $0.01$、
sampled $\kappa_*$、$\theta=1-h\kappa_*>0$ 和 sampled noncollision/clearance gates。只有这些门均通过
才在数值公式中取 $N_{\rm ov}=1$。令

$$
c_0=\frac1{\theta h},\qquad c_1=\frac{h}{2\theta},
$$

$$
C_{\rm num}=\left[
\frac{c_0}{\mu_{\rm num}^2}
+\frac{c_1+c_0}{4\mu_{\rm num}}+17c_1
\right]^{1/2}.
$$

这是非凸星形 sampled geometry 给出的数值常数，不是 $\overline C$。coarse 与 fine 各自保存
$\varepsilon_{\rm num},U_{\rm num},D_{\rm num},R_{\rm num}$ 和状态，用于直接检查完整组合量；正式
结果取 fine level，不以两层平均。若所有分项、tail candidate、fresh audit 与 sampled geometry 通过且

$$
D_{\rm num}=U_{\rm num}-C_{\rm num}\varepsilon_{\rm num}>0,
$$

则报告

$$
R_{\rm num}=\frac{2\mu_{\rm num}C_{\rm num}\varepsilon_{\rm num}}{D_{\rm num}}
$$

并标为 `UNCERTIFIED_RNUM`。若分项或 tail 不完整，报告 finite prefix 与原因；若 denominator 非正，
报告 `NO_FINITE_RNUM`；audit 或 geometry 失败则分别报告实际失败，不得仍输出成功状态。任何正值都不
升级为连续谱包含、特征值误差或认证上界。

## 6. 可选敏感性、预算与交付

主结果只来自上述 baseline frozen field。若 center-material normal 项超过 fine
$\varepsilon_{\rm num}^2$ 的 $50\%$、baseline frozen field 的两层主要总量已显示数值稳定、且实测
剩余预算足以完成 fresh solve、两层评价与 audit，主代理可显式决定在相同 $k_0,M=48$ 下追加一次
`ntot=384` fresh-field 敏感性评价。它必须单独标为 optional；该 field 有自己单位范数的 $q$，只能
比较各自齐次 $R_{\rm num}$ 与分项，不能把两个 field 的 q、density 或 components 混合。它不能自动
替换 baseline、补齐 tail 或改变完成门；若贡献未达触发条件或预算不足则不运行。本轮不扫描
MFS/proxy 参数。

历史 raw-only 与 audit 成本约数分钟，预计 baseline 两层评价和独立审计为 4--8 分钟；按本轮
实现的保守预估，峰值约 1.8--2.1 GB。即使执行一次可选 `ntot=384`，仍应留在全部运行、debug 与 audit 共用的 2700 秒及
$3{,}000{,}000{,}000$ bytes process-tree 上限内。不得并发 MATLAB。交付须保存 fresh q/density/
propagation provenance、两层全部分项与 changes、tail ratios、disk ledger、geometry、$\mu_{\rm num}$、
$C_{\rm num}$、denominator、$R_{\rm num}$、失败原因、资源、源码快照和独立 audit；运行不得读取旧输出、
Git 或本文档。`estimate_i8` 只返回内存对象；create-once 保存、源码快照和资源记录由外部 monitored
launcher 负责，以保持数值入口可移植。

## 7. 实际执行：baseline 主结果

2026-10-15 的 baseline fresh run 位于
[[test/i8/estimate-v1/output/attempt-1/run-01/result.json|run-01]]；独立重建 audit 位于
[[test/i8/estimate-v1/output/attempt-1/run-02/audit2.json|run-02]]。两层均得到
`UNCERTIFIED_RNUM`：

| nodes | $\varepsilon_{\rm num}$ | $U_{\rm num}$ | $D_{\rm num}$ | $R_{\rm num}$ |
|---:|---:|---:|---:|---:|
| 512 | $2.4810755427659055\times10^{-7}$ | $0.11608305829685453$ | $0.11608100556767394$ | $1.0909099843762415\times10^{-4}$ |
| 768 | $2.4810755428251100\times10^{-7}$ | $0.11608305827964590$ | $0.11608100555046526$ | $1.0909099845639975\times10^{-4}$ |

两层的 $R_{\rm num}$ 相对变化是 $1.7211\times10^{-10}$，disk mass 相对变化是
$1.4824\times10^{-10}$。fine 层的 center-material normal square 为
$6.155735849152025\times10^{-14}$，占 total normal square 的
$0.999999999991462$；wall normal square 只占 $8.5351\times10^{-12}$，而 lead-material normal
只占约 $2.93\times10^{-15}$。因此，本例的普通数值 defect 几乎全部来自 center-star material normal
项。512--768 层之间某些极小 wall/lead 分量有较大的相对变化，不改变上述 total 稳定性，也不能据此
宣称单个 evaluator 误差已被隔离。

baseline entry 用时 $404.164903375$ s，受监测 wall time 为 $429.975669$ s，峰值 process-tree RSS
为 $1{,}180{,}565{,}504$ bytes。run-02 从保存的完整 evidence 独立重建矩阵、场、全部 components、mass
和最终标量，`all_pass=true`，最大缺陷为 $4.298966048359329\times10^{-15}$；它没有把结果升级为认证。
center-material normal 的占比超过预注册的 $50\%$ 门，baseline 两层主要总量稳定且剩余预算充足，故
主代理按第 6 节显式启动单独的 `ntot=384` sensitivity field。该可选结果不会替代本节 baseline 主结果。

## 8. 实际执行：可选 `ntot=384` 敏感性

[[test/i8/estimate-v1/output/attempt-1/run-03/result.json|run-03]] 在同一 $k_0,M=48$ 与同一 auxiliary
tuple 下 fresh 重建 `ntot=384` 场；它没有读取 baseline 输出，并对自己的 $q$ 独立作单位范数归一化。
两层结果为：

| nodes | $\varepsilon_{\rm num}$ | $U_{\rm num}$ | $D_{\rm num}$ | $R_{\rm num}$ |
|---:|---:|---:|---:|---:|
| 512 | $5.716998709940497\times10^{-10}$ | $0.11608305829685364$ | $0.11608305356686865$ | $2.5136763609586296\times10^{-7}$ |
| 768 | $5.717028112067901\times10^{-10}$ | $0.11608305827964505$ | $0.11608305354963573$ | $2.5136892889947825\times10^{-7}$ |

optional field 的两层 $R_{\rm num}$ 相对变化为 $5.1431\times10^{-6}$，mass 相对变化为
$1.4824\times10^{-10}$。fine center-material normal square 为
$3.2684357106971763\times10^{-19}$，仍占其 total normal square 的 $0.9999983798$。但是，它比 baseline
对应中心项小约 $1.88339\times10^5$ 倍；其 $\varepsilon_{\rm num}$ 与 $R_{\rm num}$ 都约为 baseline
的 $0.00230425$ 倍。这个量级变化是明确的 source-field discretization 敏感性证据：baseline 仍是按
预注册合同交付的主结果，optional 也只是一套独立敏感性场；两点不能建立 `ntot` 收敛率，不能据此把
较小值替换成认证上界或声称真实 defect 已收敛。

按本项目状态口径，完整 ordinary-double 分项及其重建一致性是 `ESTABLISHED (numerical)`；baseline
对 `ntot=256\to384` 的 source-discretization robustness 已被这次数量级变化 `REFUTED`；只有两个
`ntot`，因此空间收敛仍是 `UNRESOLVED`；两套 $R_{\rm num}$ 都只是各自 frozen field 下的
`CONDITIONAL` 数值量。

run-03 entry 用时 $391.492373208$ s，受监测 wall time 为 $408.956486$ s，峰值 process-tree RSS 为
$1{,}542{,}520{,}832$ bytes。其同一运行保存的独立 reconstruction audit
[[test/i8/estimate-v1/output/attempt-1/run-03/audit2.json|all pass]]，最大缺陷为
$4.265861106391577\times10^{-15}$。本轮 baseline、两次 audit 与 optional 的累计受监测 wall time 为
$854.913248$ s，全轮峰值就是上述 run-03 峰值，未超预算。两套 field 的状态均为
`UNCERTIFIED_RNUM`，且 `certified=false`；本轮没有扫描、inertia 或进一步 `ntot` 阶梯。

## 9. 续轮：center 512 / lead 256

续轮不改变模型、候选或评价公式。固定
$k_0=1.7562818500073463$、$M=48$、`nside=160`、`ntop=160`、`nproxy=80`、`mpw=32`，只取

$$
n_c=512,\qquad n_\ell=256.
$$

center 与 lead 必须由各自节点数 fresh 构造。令 $q_{512,256}$ 是 center-512 scattering 与 lead-256
QZ/DtN 共同组装的 fresh $A_{\rm phys}$ 最小 right singular vector，经 column-weight recovery 后只作一次
单位范数归一化与 phase anchor。随后分别冻结

$$
\eta_c^{512}=\operatorname{fl}(H_{c,L}^{512}a^L+H_{c,R}^{512}b^R)
$$

和 lead-256 的 $G_\pm,P_\pm,c_\pm$；不得读取或混用历史 `(256,256)`、`(384,384)` 的 $q$、density
或传播 state。对 $N\in\{512,768\}$，中心与 lead 的 raw actions 分别使用

$$
r_{c,N}=W_{c,N}^{-1}A_{c,N}^sW_{c,N}I_{512\to N}\eta_c^{512}+B_{c,N}q_{512,256},
$$

$$
r_{\ell,N}=W_{\ell,N}^{-1}A_{\ell,N}^sW_{\ell,N}I_{256\to N}\eta_\ell^{256}
 +B_{\ell,N}x_{\ell},
$$

其中 $I_{n\to N}$ 是 frozen trigonometric density 的插值。所有 material、center--lead wall、internal
wall、infinite-tail candidate 与 disk mass 仍来自同一个 fresh hybrid field，完整分项和状态门保持第
3--5 节不变。

本续轮以 $N=768$ 为主结果。$N=512$ 时，中心材料 action 满足 $I_{512\to512}=I$，target 又与原中心
配点重合；该中心项是 native/algebraic diagnostic，不是独立的 non-native 复核。因此 512--768 的
center-material 差只能透明报告，不能称为评价网格收敛率。lead-256 的两层材料评价均为 non-native；
wall target 与 disk target 不在材料边界，它们的两层结果仍可作为同一 frozen field 的数值变化记录，
但不得用这些部分变化消除中心配点 caveat。

历史 `(256,256)` 与新 `(512,256)` 只在配置轴上改变 center 节点数，可以作为两个独立归一化 fresh
field 的 center-only sensitivity 比较；它仍只有两个点，不建立收敛率。历史 `(384,384)` 同时改变
center 和 lead，不能与前两者排成纯 center 序列，也不能用于归因 center 改善。续轮不扫描、不重做
inertia、不新增理论或认证门；正式输出继续标为 `UNCERTIFIED_RNUM` 或实际 fail-closed 状态。

### 9.1 实际结果

正式结果保存在
[[test/i8/estimate-v1/output/attempt-1/run-05/result.json|run-05]]；节点账本确认 center geometry、density、
$A_{\rm QP}$ 的阶数分别为 $512$、$1024$、$1024$，lead 对应为 $256$、$512$、$512$，matching 阶数
保持 $194$，所有尺寸门均通过。两层普通数值为：

| $N$ | center native | $\varepsilon_{\rm num}$ | $U_{\rm num}$ | $D_{\rm num}$ | $R_{\rm num}$ |
|---:|:---:|---:|---:|---:|---:|
| 512 | yes | $9.135068819702066\times10^{-13}$ | $0.11608305829685367$ | $0.11608305828929573$ | $4.0165490283803493\times10^{-10}$ |
| 768 | no | $1.6039135669302043\times10^{-12}$ | $0.11608305827964506$ | $0.11608305826637501$ | $7.0521608619273644\times10^{-10}$ |

正式主值是 $N=768$ 行。$N=512$ 的 center-material normal square 只有
$2.458164336299298\times10^{-30}$，而 $N=768$ 为
$2.038038951622580\times10^{-24}$；前者是配点重合后的 native residual。相应两层
$R_{\rm num}$ 相差约 $43.0\%$，所以本续轮没有 512--768 evaluator convergence 结论。fine total normal
square 为 $2.568905612184280\times10^{-24}$，其中 center-material 占约 $79.33\%$，wall 占约
$20.66\%$；disk mass 两层相对变化仍只有 $1.4824\times10^{-10}$。这些是完整 ordinary-double
分项，不是 one-sided enclosure。

三组 fresh fields 必须按下表分别解释：

| $(n_c,n_\ell)$ | fine $\varepsilon_{\rm num}$ | fine center normal square | fine $R_{\rm num}$ | 比较用途 |
|---:|---:|---:|---:|---|
| $(256,256)$ | $2.481075542825110\times10^{-7}$ | $6.155735849152025\times10^{-14}$ | $1.0909099845639975\times10^{-4}$ | center-only 轴的旧端点 |
| $(384,384)$ | $5.717028112067901\times10^{-10}$ | $3.2684357106971763\times10^{-19}$ | $2.5136892889947825\times10^{-7}$ | center 与 lead 同时改变的历史敏感性 |
| $(512,256)$ | $1.6039135669302043\times10^{-12}$ | $2.038038951622580\times10^{-24}$ | $7.0521608619273644\times10^{-10}$ | center-only 轴的新端点 |

在 lead 固定为 256 时，$(256,256)\to(512,256)$ 使 fine $R_{\rm num}$ 小约
$1.54692\times10^5$ 倍，center normal square 小约 $3.02042\times10^{10}$ 倍。这建立强烈的 center
节点敏感性，但只有两个分别归一化的 fresh fields，仍不建立收敛率；$(384,384)$ 不能补成第三点。

[[test/i8/estimate-v1/output/attempt-1/run-05/audit2.json|独立 audit]] 重建全部两层分项，
`all_pass=true`，最大缺陷为 $4.298966048359329\times10^{-15}$，同时核对 center/lead 节点账本与
native flags。run-05 entry 用时 $394.471511292$ s，受监测 wall time 为 $415.277293$ s，峰值
process-tree RSS 为 $1{,}214{,}922{,}752$ bytes。此前 run-04 只是 multiline launcher 未执行 batch 的
操作失败，没有科学评价；同一 budget ID 的累计 wall time 为 $431.851594$ s。正式状态仍为
`UNCERTIFIED_RNUM`、`certified=false`。center-512 的 native coarse action 与只有两个 center-only fresh
fields 都是 `important caveat`：它们限制 evaluator 与空间稳健性解释，但不阻止本轮普通数值主值交付。
