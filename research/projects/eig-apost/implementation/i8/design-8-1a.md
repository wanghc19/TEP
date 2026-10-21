# I8.1：等面积光滑星形中心的完整数值流程设计

## 1. 状态、目标与结论边界

- Design ID: `I8.1-STAR-FLOW-V1`
- Status: `RUN COMPLETE; INDEPENDENT REVIEW FINAL PASS WITH CONDITIONS`
- Claim boundary: `FINITE-DIMENSIONAL CHECKS AND UNCERTIFIED NUMERICAL DISTANCE ESTIMATE`

本阶段把中心 inclusion 从椭圆改为公共 `geom.construct_cont` 的光滑五瓣星形，重新完成候选搜索、
肩点 Hermitian-part 符号计数、两条离散轴的同模态比较，以及同一冻结 raw 场的非 Fourier 界面缺陷、
质量与 $R_{\rm num}$ 评价。物理模型、修正后的 density-coordinate chain 和 half-guide 方法沿用
[[research/projects/eig-apost/implementation/i7/README|I7]]；旧 I7 数值不作本轮输入。

本轮只要求可复现的普通双精度结果。曲率、collar、$C_{\rm num}$、盘质量、传播尾和
$R_{\rm num}$ 都是数值量，不是单侧包含；不建立新的连续余项定理，不把候选称为特征值，也不把
$R_{\rm num}$ 称为误差界或谱包含。I6 的 T9--T10、F14 与 N9 只提供公式结构，适用边界见
[[research/projects/eig-apost/implementation/i7/design-7-4a|I7.4]]。

## 2. 冻结模型与等面积星形

固定

$$
\beta=0.5,\qquad d=1,
$$

左右 lead inclusion 是半径 $0.2$、`epsrel=17` 的圆；中心 inclusion 是 `epsrel=2` 的单连通光滑
星形；背景 `epsrel=1`，人工墙为 $X_L=-0.5,X_R=0.5$。baseline 空间配置为

$$
(N,n_{\rm side},n_{\rm top},n_{\rm proxy},m_{\rm pw},M)
=(256,160,160,80,32,48),\qquad K=2M+1=97.
$$

公共星形在乘公共因子 $0.2$ 前的 Fourier 参数化为

$$
\begin{aligned}
x_0(t)&=1.5\cos t+0.15\cos6t+0.15\cos4t,\\
y_0(t)&=\sin t+0.15\sin6t-0.15\sin4t.
\end{aligned}
$$

由 Fourier 正交性，其公共实现面积为

$$
\pi(0.2)^2\left(1.5+6(0.15)^2-4(0.15)^2\right)=0.0618\pi.
$$

I8 再乘

$$
s_*:=\sqrt{0.04/0.0618}=0.8045179867091297,
$$

使面积为 $0.04\pi$，与半径 $0.2$ 的圆等面积。缩放必须作用于 `C(1:6,:)` 的位置、一阶和二阶
参数导数；只缩放位置会破坏法向、曲率与边界积分权重。lead 圆不缩放。

该公共曲线确为单连通简单星形。令 $c(t)=0.3\cos 5t$，则未乘公共正缩放前可写成
$x=(1.5+c)\cos t$、$y=(1+c)\sin t$，并且

$$
x y'-y x'=(1.5+c)(1+c)+0.5c'\sin t\cos t
\ge 0.84-0.375=0.465>0.
$$

因此曲线不经过原点，极角严格递增并绕原点一周；结合下面的正 speed 门，它给出 smooth simple
radial star，而不需要为本轮数值任务另建自交判定理论。

对 CCW 参数化使用

$$
v=(x'^2+y'^2)^{1/2},\qquad
\nu=(y',-x')/v,\qquad
\kappa=(x'y''-y'x'')/v^3.
$$

预检的 32768 点 ordinary diagnostics 为

$$
\begin{gathered}
x\in[-0.24577005225113085,0.28962647521528667],\\
|y|\le0.2004746122547105,\qquad
\min v=0.11263251813927815,\\
\kappa\in[-79.90587575136036,34.200345242692705].
\end{gathered}
$$

这些值只冻结数值检查的期望尺度，不能冒充区间证书。

## 3. 修正密度坐标与中心 matching

所有 cell scattering 必须调用当前公共 `bloch.construct_S`。若 `op.construct_A_QP` 返回

$$
A_s=W A_{\rm raw}W^{-1},
$$

公共路径须在 scaled system 中乘右端、求解，再恢复 physical density；输出
`H_L,H_R` 始终映到 $\eta=[\tau;\zeta]$，其中 $\zeta=-\sigma$。I8 不增加第二次 density scaling。

中心 cell map 与 amplitude 顺序固定为

$$
\begin{bmatrix}b^L\\a^R\end{bmatrix}
=\begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
\begin{bmatrix}a^L\\b^R\end{bmatrix},
\qquad q=[a^L;b^R].
$$

令 $G=\operatorname{diag}(\gamma_m)$，左右 half-guide DtN 为 $L_-,L_+$，则

$$
A_{\rm def}=
\begin{bmatrix}
(\mathrm iG-L_-)R_L-(\mathrm iG+L_-)&(\mathrm iG-L_-)T_{RL}\\
(\mathrm iG-L_+)T_{LR}&(\mathrm iG-L_+)R_R-(\mathrm iG+L_+)
\end{bmatrix}.
$$

沿用 I7 的 row/column weights，

$$
A_{\rm phys}=D_rA_{\rm def}D_c.
$$

每个点的四个指标必须来自同一个 $k$、同一配置和同一组矩阵：
$\sigma_{\min}(A_{\rm def})$、其 ratio、$\sigma_{\min}(A_{\rm phys})$ 及其 ratio。

## 4. 阶段 A：baseline 候选搜索与定位

只用 baseline 配置在

$$
k_j=1.45+0.025j,\qquad j=0,\ldots,32
$$

评价 33 点 screen。有效点按 `aphys_ratio` 取最小；无效点保存具体原因并排除，不赋人造大分数。
这只是给定区间的有限扫描，不称全局搜索。若 minimum 位于 screen 端点，交付当前边界最佳点，
不构造区间外点。

若当前 winner 是严格内点且两个相邻点均有效，以这两个邻点为新闭区间，作 11 点均匀扫描。
每层仍按全部已完成的 baseline 有效点取 `aphys_ratio` 最小值；只有 winner 再次为严格内点且两邻点
有效时才进入下一层。最多五层；边界 winner、invalid bracket 或第五层完成即停止。初始 strict dip
持续存在时，第五层完整邻点间距目标约为 $1.6\times10^{-5}$。不设 dip 深度门，不拟合或外推
连续 minimizer。

最终候选 $k_0$ 是全部已完成 baseline 有效评价的 `aphys_ratio` argmin。其最后一对有效相邻点记为
$k_L<k_0<k_R$，用于阶段 B；若没有双侧有效邻点，肩点计数状态为 unresolved，但候选及全部有效结果
仍交付。定义

$$
\delta_k=64\epsilon_{\rm mach}\max(1,|k_0|).
$$

跨层 `linspace` 结果若满足 $|k-k_0|\le\delta_k$，只视为同一理论网格点的浮点近重复，不得充当
肩点；从其余全部有效评价中取最近的左、右点。本轮最小扫描步长 $8\times10^{-6}$ 远大于
$\delta_k$，因此该规则只去掉 ulp 级重复，不改变有限扫描尺度。扫描 cache 只在完全相同的
model/config/$k$ 下复用。

## 5. 阶段 B：肩点计数与两条离散轴

### 5.1 肩点 Hermitian-part 符号计数

仅在 baseline 的 $k_L,k_R$ 评价。令

$$
T=\begin{bmatrix}I+R_L&T_{RL}\\T_{LR}&I+R_R\end{bmatrix},
$$

$$
N_0=\begin{bmatrix}
\mathrm iG(R_L-I)&\mathrm iG T_{RL}\\
\mathrm iG T_{LR}&\mathrm iG(R_R-I)
\end{bmatrix},\qquad
L=\operatorname{blkdiag}(L_-,L_+).
$$

独立检查 $A_{\rm def}=N_0-LT$，再形成

$$
H=A_{\rm def}/T,\qquad H_{\rm sym}=(H+H^*)/2.
$$

以 $n=2K$、$s_H=\|H_{\rm sym}\|_2$、$d_H=\|H-H_{\rm sym}\|_2$ 定义

$$
\eta_c=d_H+cn\epsilon_{\rm mach}\max(1,s_H),\qquad c\in\{50,100,200\}.
$$

分别计数 $\lambda<-\eta_c$、$|\lambda|\le\eta_c$、$\lambda>\eta_c$。三档完整 triples、
`rcond(T)`、独立组装和右解残差必须保存。它是 Hermitian-part surrogate；稳定 jump 也不证明连续根。

### 5.2 `ntot` 与 $M$ 两条检查

只在同一个 $k_0$ 比较三配置：

| Name | `ntot` | $M$ | Role |
|---|---:|---:|---|
| `B` | 256 | 48 | final selected baseline |
| `N` | 384 | 48 | boundary-axis check |
| `M` | 256 | 64 | Rayleigh-axis check |

不增加六配置网格或联合高配。对每个配置重新计算同一点的四指标。若 $v$ 是
$A_{\rm phys}$ 的右奇异向量，比较前必须恢复

$$
q=D_cv,\qquad d=Tq,
$$

即 physical Dirichlet wall-trace Fourier coordinates；不得直接比较 $v$。`B--M` 按真实
$m=-M{:}M$ 标签分别对 left/right blocks 零填充；`B--N` 不重排 mode。报告 phase-invariant overlap、
primary--competitor cross-overlap、$\sigma_1/\sigma_2$ 和高于共同 cutoff 的 squared-norm fraction。
若 primary gap 不超过

$$
\delta_A=1000n\epsilon_{\rm mach}\max(1,\|A_{\rm phys}\|_2),
$$

则本轮保守记同模态 unresolved，不强配单向量，也不扩展新的 cluster 实现。simple case 的既有诊断门为
primary overlap 至少 $0.99$、双向 cross-overlap 至多 $0.5$；它只支持有限维同模态证据。

## 6. 非凸 collar 与数值 $C_{\rm num}$

星形含负曲率，椭圆 reach 公式不适用。固定 numerical collar 半宽

$$
h=0.004,\qquad b_{\rm arc}=0.01.
$$

令 $K_*=\max|\kappa|$。预检给出
$\theta_{\rm samp}=1-hK_*\approx0.6803765$ 及
$K_*(b_{\rm arc}/2+h)\approx0.71915<1$。正式几何诊断固定使用 $4096$ 与 $8192$ 点两层
dense geometry grids，并检查：

1. speed 正且位置/一阶/二阶导数均按 $s_*$ 缩放；
2. 短弧长距离至少 $b_{\rm arc}$ 的 sampled chord minimum 大于 $2h=0.008$；
3. $r=\pm h$ 的 sampled normal offsets 在远弧对上保持分离；结合 local-factor 门记录 sampled
   tube noncollision implication；
4. 中心、lead、人工墙及其相关周期副本之间的 sampled separation 大于 $2h$。

这些是非凸 tube 的数值资格检查，不是 T12 区间证书。只有检查通过时才以
$N_{\rm ov}=1$ 形成 ordinary trace constant；失败则 $C_{\rm num}$ 和 $R_{\rm num}$ unavailable，
但前面的候选与有限维检查仍交付。

令 $\mu=k_0^2$、$\rho_-=1$、$\rho_+=17$、$\ell_*=1$，取

$$
c_0=\frac{N_{\rm ov}}{\theta_{\rm samp}h},\qquad
c_1=\frac{N_{\rm ov}h}{2\theta_{\rm samp}},
$$

$$
C_{\rm num}^2=
\frac{c_0}{\rho_-\mu^2}
+\frac{c_1+\ell_*^2c_0}{4\mu}
+\ell_*^2c_1\rho_+.
$$

`C_num` 必须明确标为 sampled geometry formula value，不得写成 $\overline C$。

## 7. 阶段 C：同一冻结 raw 场的 $R_{\rm num}$

只在最终 `B` 候选重新构造并冻结 $q$、中心 physical `eta256`、lead cell maps 与
$G_\pm,P_\pm,c_\pm$。这些对象不能来自 screen 中的另一点、I7 文件或更低筛选配置。
全部后续加密保持这组场系数不变，不在 512/768 节点重新求解 density。

reference raw field 定义为这些冻结系数作用于 exact free/QP layer potentials 与 Rayleigh modes；
公共 MFS/proxy path 是它的普通数值 evaluator。分片 PDE 和 quasiperiodicity 为 reference
representation 的结构性质，不能由小 MFS residual 推出 evaluator error 为零，更不能据此升级
$R_{\rm num}$。本轮不包围 exact raw field 与 MFS evaluator 之间的差。

### 7.1 材料、墙与胞元尾

中心星形和 lead 圆的 signed material jumps、两条 center--lead 墙及内部墙都用同一 physical-density
raw field 直接评价。两套独立非 native 节点数固定为 $512$ 和 $768$；baseline $256$ 配点残差若保存，
只作代数诊断，不进入 refinement pair。每套都使用冻结 `eta256` 的同一个 trig interpolant。

两侧各显式累加 40 个 lead cells。第 41 项与最后有限项的 geometric ratio 若有限且位于 $[0,1)$，
可形成 observed tail candidate；否则只交付 finite prefix。该尾不具单侧上界语义。保存 coarse/fine
各材料、center--lead wall、internal wall、finite prefix 和 tail candidate 分项，并报告绝对值与 drift；
小 native residual 或两层接近不称连续收敛。$512/768$ 两层会同时改变 layer evaluator 的 source 与
target 节点；盘质量还同时改变 polar quadrature。因此这些 drift 只给出同一冻结场的综合评价稳定性，
不分别隔离源求积、target 评价或 MFS/proxy evaluator error，也不是重新求解 density 的离散收敛。

若 end-to-end 主流程完成且预算允许，可在同一墙上比较 direct MFS trace 与 retained Rayleigh 加
shape-general high-mode reconstruction，作为 evaluator discrepancy 诊断；不扫描 MFS/proxy 配置，
该对照失败记 important caveat，不阻断已经完成的普通数值估计。

令 ordinary 总 value/normal jump squares 为 $E_v,E_n$，则

$$
\varepsilon_{\rm num}=\sqrt{E_n+\ell_*^{-2}E_v}.
$$

### 7.2 同场安全盘质量

固定

$$
D=B((0.375,0),0.0625).
$$

其左端 $0.3125$ 比 sampled star 的最大 $x$ 坐标大 $0.0228735248$，到右墙距离为 $0.0625$。
正式运行仍须在两层 geometry grids 上复核整个盘处于背景并保存 boundary-distance minimum。

直接评价同一 frozen raw field，使用 polar quadrature
$(N_r,N_\theta)=(16,32)$ 和 $(32,64)$；fine angular nodes 相对 coarse 作半步错位。定义

$$
U_{\rm num}=\left(Q_D(|u|^2)\right)^{1/2},
$$

其中盘内 $\rho=1$。保存两层值、absolute/relative drift 和点值/梯度诊断；主质量输入取 fine disk
quadrature。`U_num` 是有限子域质量的普通数值近似，不记为 `Uunder` 或 certified lower bound。

### 7.3 条件公式

若几何门、全部有限 ordinary components 与 observed tails 有效，且

$$
Q_{\rm num}=C_{\rm num}\varepsilon_{\rm num},\qquad
D_{\rm num}=U_{\rm num}-Q_{\rm num}>0,
$$

则输出

$$
R_{\rm num}=\frac{2\mu C_{\rm num}\varepsilon_{\rm num}}{D_{\rm num}}.
$$

若分母非正或某一完整普通分项 unavailable，仍保存实际数值与首个失败原因，不虚设零或换候选。
即使 $R_{\rm num}$ 很小，它也只是 `UNCERTIFIED_RNUM`；不输出 certified spectral interval。

## 8. 资源、输出与停止语义

Engineer 独占 MATLAB，所有实现、debug、candidate、检查、raw evaluation 和 audit 共用 2700 s
计算预算；launcher 以 2,300,000,000 bytes 作提前 RSS 终止并以 0.1 s 采样，任务上限仍不得超过
3,000,000,000 bytes。禁止并发 MATLAB。开始 stage 前按已用时间和实测单点评价成本判断能否完成，
优先保证 baseline candidate、肩点和一组完整固定场评价。

同一方法的程序修复留在一个 attempt，保留每次 run 证据；只有科学方案改变才开新 attempt。
所有新文件名包含扩展名在内不超过 15 个字符。正式输出至少包括 `result.mat/json`、`evidence.mat`、
`scan.csv`、`parts.csv`、`audit.json`、`chkpt.mat`、`source.m`、`monitor.sh` 及逐 run 资源记录。
MATLAB 入口不读取 Markdown、Git 或旧输出作为数值输入。

结果状态至少区分：

- `FLOW_COMPLETE / UNCERTIFIED_RNUM`：全流程与独立 audit 完成，$R_{\rm num}$ 有限；
- `FLOW_COMPLETE / NO_FINITE_RNUM`：数值分项完成但分母或 observed tail 不给有限公式；
- `PARTIAL_NUMERICAL_FLOW`：候选或部分检查有效，但后续 stage 未完整完成；
- `EXECUTION_FAILED`：连当前 stage 的有限数值对象也无法形成。

边界 minimum、浅 dip、计数不跳、离散漂移或较大的 $R_{\rm num}$ 都不是拒绝交付的理由。

## 9. 理论到代码的最小映射

| Design object | Code role | Governing source |
|---|---|---|
| equal-area star $C_*$ | `LOCAL_cellmap`, `LOCAL_curve`, `LOCAL_geom_level` | public `geom.construct_cont` plus $s_*$ |
| $A_{\rm def},A_{\rm phys}$ | `LOCAL_matching` | I7.1 matching convention |
| $H_{\rm sym}$ counts | `LOCAL_inertia`, `LOCAL_counts` | I7.2 surrogate count |
| physical trace $d=Tq$ | `LOCAL_mode_check` | I7.3 coordinate rule |
| $C_{\rm num}$ | `LOCAL_geometry`, `LOCAL_Cnum` | T9 formula, sampled inputs |
| $\varepsilon_{\rm num}$ | `LOCAL_components` | T10 interface ledger, ordinary evaluation |
| $U_{\rm num}$ | `LOCAL_mass_diagnostic` | N9 finite-subregion idea, numerical quadrature |
| $R_{\rm num}$ | top-level finite-formula gate | F14 formula, uncertified inputs |

Canonical variable meanings are frozen in [[research/projects/eig-apost/implementation/i8/SYMBOLS|I8 symbols]].

## 10. 实际执行与结果

### 10.1 运行记录

同一 `attempt-1` 保留了三次证据：

- `run-01` 在任何科学评价前因 MATLAB struct 预分配错误退出；
- `run-02` 完成扫描后暴露跨层 `linspace` 中心点相差一 ulp、会被误认作左肩的问题。主代理主动停止
  该 run，并按第 4 节的 $\delta_k$ 规则修复；其肩点和后续部分结果不作正式科学证据；
- [[test/i8/flow-v1/output/attempt-1/run-03/result.json|run-03]] 从头运行，不读取旧输出，完整结束并由
  [[test/i8/flow-v1/output/attempt-1/run-03/audit2.json|独立算术 audit]] 复核；正式
  [[test/i8/flow-v1/output/attempt-1/run-03/source.m|入口快照]] 与
  [[test/i8/flow-v1/output/attempt-1/run-03/audit_src.m|audit 快照]] 随结果保存。

三次受监测 MATLAB wall time 合计 $2182.365128$ s，小于 $2700$ s；全程峰值进程树 RSS 为
$1{,}182{,}564{,}352$ bytes，小于提前终止门 $2.3\times10^9$ bytes。正式 `run-03` wall time 为
$1228.056123$ s，exit code 为零。

### 10.2 候选、肩点与有限维检查

33 点 screen 与五层 11 点定位均数值有效；停止原因为达到预注册的五层上限。正式当前扫描最佳点为

$$
k_0=1.7562800000000001,\qquad
(k_L,k_R)=(1.7562720000000001,1.7562879999999998).
$$

完整邻点间距约为 $1.6\times10^{-5}$。它仍是有限网格当前最佳点，不是连续 minimizer 或已确认
特征值。最终 baseline 四指标同点同矩阵为

| Metric | Value |
|---|---:|
| `adef_sigma` | $1.5876231719907793\times10^{-5}$ |
| `adef_ratio` | $2.6277513150613766\times10^{-8}$ |
| `aphys_sigma` | $7.851843183673099\times10^{-6}$ |
| `aphys_ratio` | $2.7494686301593333\times10^{-6}$ |

在 $k_L$ 与 $k_R$，三档 $c=50,100,200$ 的 $(n_-,n_0,n_+)$ 分别稳定为
$(0,0,194)$ 与 $(1,0,193)$，故 Hermitian-part surrogate 的负计数差为 $+1$。左右 `rcond(T)` 为
$0.5169931582$ 与 $0.5169930181$，独立组装 defect 不超过 $1.12\times10^{-18}$，右解 residual
不超过 $5.07\times10^{-19}$。该 jump 只属于冻结离散肩点的 surrogate。

同一 $k_0$ 的 `B--N` 与 `B--M` primary overlap 都在舍入范围内等于 $1$，最大 competitor
cross-overlap 为 $2.326\times10^{-5}$；`M` 配置高于共同 $M=48$ 的 squared-norm fraction 为
$5.713\times10^{-32}$。三者 simple gap 均远大于各自 $\delta_A$，同模态门通过。这里只检查固定点的
两条单轴稳定性；没有在 `N` 或 `M` 配置上重新扫描候选位置。

### 10.3 sampled geometry 与 raw-field 数值量

$4096/8192$ 点几何门都通过。两层面积 defect 不超过 $5.56\times10^{-17}$，六行缩放 defect 为零，
$K_*=79.90587575136033$、$\theta_{\rm samp}=0.6803764969945587$，远弧 chord minimum 分别为
$0.0097726824$ 与 $0.0097705093$，安全盘 boundary clearance 为 $0.0228735248$。这些仍是 sampled
nonconvex-collar diagnostics，不是 reach 或 tube 证书。修正 density-coordinate control 的最大 defect
为 $4.292\times10^{-15}$。

fine $768$ 节点评价中，normal ledger 由 center--lead wall 项
$2.5248370658795346\times10^{-10}$ 主导；center material normal 项为
$6.155731778315746\times10^{-14}$，其余 lead/internal/tail normal 项更小。若只看相对 drift，lead
material normal 的 $512/768$ 变化约 $0.3292$，但两层绝对量都在 $10^{-28}$ 尺度，不能据此说主导
缺陷不稳定。综合 fine 数值为

$$
\varepsilon_{\rm num}=1.5891672785007143\times10^{-5},\qquad
U_{\rm num}=0.11608313379588661,
$$

$$
C_{\rm num}=8.273559292601668,\qquad
D_{\rm num}=0.11595165309884123>0,
$$

因此公式给出

$$
R_{\rm num}=0.0069952390495916393.
$$

第 41/40 胞元观测比约为 $0.091$，只支持本轮 geometric tail candidate；$512/768$ source/target
和 disk grids 同时改变，所得 drift 是综合 evaluator stability。`run-03` 内部 audit 最大 defect
$2.640\times10^{-13}$，独立 audit 最大 defect $7.344\times10^{-14}$，均通过各自门。

**结论（`CONDITIONAL`）：** 完整 ordinary numerical flow 已执行，有限维候选、肩点 surrogate jump、
固定点单轴同模态和有限 $R_{\rm num}$ 都有可复现证据。由于 nonconvex collar、layer evaluator、
quadrature、观测尾和盘质量均未作单侧包含，最终状态只能是 `UNCERTIFIED_RNUM`，不能推出谱距离证书。
独立审查结论为 `FINAL PASS WITH CONDITIONS`，详见
[[research/projects/eig-apost/implementation/i8/review-8-1a|review-8-1a]]。
