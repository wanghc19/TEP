# I3.1 中心空列连续强残量实验设计

## 摘要与冻结状态

- **Design ID:** `I3.1-CENTER-STRONG-RESIDUAL-V1`
- **Design status:** `FROZEN RESEARCHER--ENGINEER AGREEMENT / SKEPTIC REVIEW REQUIRED / NO RUN`
- **Researcher--Engineer agreement:** `AGREED`（2026-08-14）
- **正式 attempt:** `center-a1`
- **主要输出语义:** `CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE`

本实验在 I2 保存的实数 candidate

$$
\widehat k_h=1.832770289108157,
\qquad \mu_h=\widehat k_h^2
$$

处，只重算一次冻结的 fine evaluator，并从其近核向量构造中心空列中的有限 Fourier 场。
用一个固定 cutoff 把该场延拓为全局非零 conforming 场，再直接计算 continuous physical
operator 的强残量。实验不定位 finite-matrix zero，不扫描 $k$，不计算矩阵导数，也不恢复旧的
finite-root correction 路线。

精确构造给出一个真正作用于 continuous operator 的 residual-to-spectrum 公式；但首次实现只用
普通双精度复合 Simpson 积分，没有 outward rounding 或严格积分余项。因此正式数值只能称
**computed continuous strong-residual estimator candidate**，不能称 certified upper bound。
此外，当前 sharp-disk continuous projected essential gap 尚未建立，所以本次不能把“到整个连续谱
的距离”升级为“candidate 附近存在 gap 内离散特征值”，更不能识别唯一目标 mode。

本设计由 Researcher 给出 operator/domain/证明义务，由 Engineer 核对实际 evaluator 数据、积分
实现和资源。双方明确同意本文第 2--10 节；独立 Skeptic 跑前审查通过以前不得运行。

## 1. 科学问题与最短路线

I3.1 当前最短问题是：I2 的 saved candidate 和近核向量能否产生一个非零
$u_h^{\mathrm c}\in D(A)$，使

$$
\eta_{\lambda,h}^{\mathrm s}
=\frac{\|(A-\mu_h I)u_h^{\mathrm c}\|_H}
{\|u_h^{\mathrm c}\|_H}
$$

实际可计算？若可以，自伴谱定理直接给

$$
\operatorname{dist}(\mu_h,\sigma(A))
\leq \eta_{\lambda,h}^{\mathrm s}.
$$

这条路线比重构左右半无限 lead 的完整 BIE density、胞元传播、trace repair 和 Riesz dual norm
更短。它成立的特殊原因是当前缺陷中心列完全为空，材料系数等于 $1$，且 I2 已保存中心列两侧
Rayleigh/Fourier 系数。代价是 cutoff 只横跨一个空胞元；它产生的 defect 不随
$n_{\mathrm{tot}}$ 或 $M$ 自动消失，数值可能很大。因此它首先是 continuous-residual baseline，
不是已经证明能跟踪 $e_h^{\mathrm{gap}}$ 的渐近 estimator。

## 2. Continuous operator、空间与假设

固定 I1--I2 的横向准周期参数 $\beta=0.5$ 和周期 $d=1$。一个横向周期条带记为

$$
B=\mathbb R\times(-d/2,d/2).
$$

材料系数 $\rho$ 是折射率平方。continuous physical operator 为

$$
A=-\rho^{-1}\Delta
$$

并作用在加权 Hilbert 空间

$$
H=L^2(B,\rho\,\mathrm dx\,\mathrm dy),
\qquad
\|v\|_H^2=\int_B\rho|v|^2\,\mathrm dx\,\mathrm dy.
$$

其定义域采用 Fliss 的准周期实现：

$$
D(A)=\left\{v\in H^1(B):\Delta v\in L^2(B),\quad
v,\partial_yv\text{ 在 }y=\pm d/2\text{ 满足同一 }\beta\text{-准周期条件}\right\}.
$$

本设计依赖以下已核对或明确冻结的假设：

1. $A$ 在 $H$ 上是非负自伴算子；这是 continuous fixed-$\beta$ 模型的性质，不是离散矩阵
   Hermitian 的结论。
2. 当前 center column 为 $[X_L,X_R]=[-1/2,1/2]$ 内的 homogeneous empty column，且其中
   $\rho=1$；所有材料界面都在该空列之外。
3. 实数 $\widehat k_h$ 远离当前 Fourier 表示的 Wood point；`eval_i21` 使用 I2 冻结 branch。
4. evaluator 返回的 $q=(q_L,q_R)$ 按 I2 的 wall Fourier order 排列，且能形成非零中心场。

若第 1 或第 2 项不适用于实际模型，本设计的 continuous 解释失效，不得把计算降格成有限矩阵
residual 后继续沿用同一名称。

## 3. 从 I2 近核向量到中心场

本次固定 fine 配置

$$
n_{\mathrm{tot}}=256,\qquad M=48,\qquad K=2M+1=97.
$$

令 $A_{\mathrm{def}}^D(\widehat k_h)\in\mathbb C^{194\times194}$ 为 I2 的 Dirichlet-coordinate
缺陷矩阵。沿用 I1--I2 的行列权重

$$
A_{\mathrm{phys}}=D_rA_{\mathrm{def}}^DD_c.
$$

取 $A_{\mathrm{phys}}$ 最小奇异值对应的单位右奇异向量 $v_1$，原始 wall coefficient 为

$$
q=D_cv_1=\begin{bmatrix}q_L\\q_R\end{bmatrix}\in\mathbb C^{194}.
$$

实验先以 $\|q\|_2$ 归一化；归一化只固定表示，不改变下面的 residual ratio。对
$m=-M,\ldots,M$，定义

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\gamma_m^2=\widehat k_h^2-\beta_m^2,
$$

其中 $\gamma_m$ 使用 evaluator 已冻结的同一 square-root branch。中心空列场为

$$
u_0(x,y)=\frac1{\sqrt d}\sum_{m=-M}^M\phi_m(x)e^{\mathrm i\beta_my},
$$

$$
\phi_m(x)=q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}
+q_{R,m}e^{-\mathrm i\gamma_m(x-X_R)}.
$$

其 $x$ 导数为

$$
\phi_m'(x)=\mathrm i\gamma_m
\left(q_{L,m}e^{\mathrm i\gamma_m(x-X_L)}
-q_{R,m}e^{-\mathrm i\gamma_m(x-X_R)}\right).
$$

精确算术中的逐模恒等式 $\gamma_m^2+\beta_m^2=\widehat k_h^2$ 给出
$-\Delta u_0=\mu_hu_0$。实际实现必须保留由 double-precision $\gamma_m$ 产生的数值色散差

$$
\delta_m=\beta_m^2+\gamma_m^2-\mu_h,
$$

而不能在代码中把它手工置零。这一中心场只使用 homogeneous center PDE，不声称左右 lead field
已被重构。

## 4. Compact cutoff、定义域与强残量

固定

$$
\chi(x)=
\begin{cases}
\cos^2(\pi x),& |x|\leq1/2,\\
0,& |x|>1/2.
\end{cases}
$$

必须准确称 $\chi$ 为 $C^1\cap W^{2,\infty}$ 的分片光滑函数，不能称为 $C^\infty$ cutoff。
在 $x=\pm1/2$ 有 $\chi=\chi'=0$；因此

$$
u_h^{\mathrm c}(x,y)=\chi(x)u_0(x,y)
$$

零延拓后属于 $H^2(B)\subset D(A)$。横向准周期性由每个
$e^{\mathrm i\beta_my}$ 保持；人工端点上函数和一阶导数同时为零，所以分布 Laplacian 不产生
delta 项。由于 residual 的支撑完全位于 $\rho=1$ 的空列，

$$
r_h=(A-\mu_hI)u_h^{\mathrm c}
=-\chi''u_0-2\chi'\partial_xu_0
+\frac{\chi}{\sqrt d}\sum_{m=-M}^M
\delta_m\phi_m(x)e^{\mathrm i\beta_my}.
$$

这里

$$
\chi'(x)=-\pi\sin(2\pi x),
\qquad
\chi''(x)=-2\pi^2\cos(2\pi x)
$$

只在 $(-1/2,1/2)$ 内使用。Fourier 正交性把二维范数精确约化为一维积分：

$$
U^2=\|u_h^{\mathrm c}\|_H^2
=\sum_{m=-M}^M\int_{-1/2}^{1/2}|\chi(x)\phi_m(x)|^2\,\mathrm dx,
$$

$$
R^2=\|r_h\|_H^2
=\sum_{m=-M}^M\int_{-1/2}^{1/2}
|-\chi''(x)\phi_m(x)-2\chi'(x)\phi_m'(x)
+\chi(x)\delta_m\phi_m(x)|^2\,\mathrm dx,
$$

$$
\eta_{\lambda,h}^{\mathrm s}=R/U.
$$

若 $U>0$，自伴谱定理给出精确数学结论

$$
\operatorname{dist}(\mu_h,\sigma(A))\leq\eta_{\lambda,h}^{\mathrm s}.
$$

该命题只保证靠近整个 continuous spectrum 的某个谱点；若 interval 接触 essential spectrum，
它不保证 candidate 附近存在离散 guided eigenvalue。

## 5. 冻结输入与唯一运行路径

实验只在一个点运行：

1. 用 I2.1 anchor $k_\star=1.8327703475952146$ 和 fine 配置调用一次
   `eval_i21('seed',...)`，得到冻结 proxy、branch、QZ frame 和 rows；
2. 用同一 frame 在 $\widehat k_h=1.832770289108157$ 调用一次
   `eval_i21('point',...)`；
3. 由该 point 的 $A_{\mathrm{def}}^D$ 重算 $A_{\mathrm{phys}}$、最小奇异向量和 $q$；
4. 计算第 4 节的一维 norms 和 ratio。

物理参数、geometry、proxy、solver、branch、QZ ordering、fixed rows、chart、weighting 与 fine
configuration 全部沿用 I2.3 的 $n_{\mathrm{tot}}=256,M=48$ 配置。不得读历史 `result.mat`，
不得从已有 output 导入 $q$，不得改 candidate，也不得在失败后扫描邻点。

## 6. 数值积分与内部检查

### 6.1 Composite Simpson ladder

在 $[-1/2,1/2]$ 上用等距复合 Simpson rule，预注册偶数子区间数

$$
N_x\in\{512,1024,2048\}.
$$

每层分别保存 $U_N$、$R_N$ 和 $\eta_{\lambda,N}=R_N/U_N$。另分别保存
$-\chi''\phi_m$、$-2\chi'\phi_m'$ 和 $\chi\delta_m\phi_m$ 三个 residual component 的
norm；总 residual 仍按三者先相加再取 norm，不能把 component norms 直接相加。另定义

$$
\delta_{\mathrm{disp}}
=\max_m\frac{|\delta_m|}
{\max\{\mu_h,|\beta_m|^2+|\gamma_m|^2,\mathrm{realmin}\}}
$$

作为数值色散诊断保存，但不把它从总 residual 中扣除。内部数值稳定门为

$$
\frac{|\eta_{\lambda,2048}-\eta_{\lambda,1024}|}
{\max(|\eta_{\lambda,2048}|,\mathrm{realmin})}
\leq10^{-10}.
$$

所有 norm 必须 finite，并在先令 $\|q\|_2=1$ 后满足

$$
U_{2048}>10^{-12}.
$$

该 ladder 只检查普通双精度积分已经稳定，不估计 Simpson remainder，也不提供 outward
enclosure。

### 6.2 相位和缩放不变性

以

$$
q'=10^8e^{\mathrm i\pi/7}q
$$

重复 $N_x=2048$ 的 norm ratio。要求

$$
\frac{|\eta_\lambda(q')-\eta_\lambda(q)|}
{\max(|\eta_\lambda(q)|,\mathrm{realmin})}
\leq10^{-12}.
$$

这验证结果不依赖奇异向量的任意整体尺度和复相位。它不是与连续真值的外部验证。

### 6.3 输入质量诊断

point 必须通过同一个冻结 evaluator 的 branch、QZ、chart、factor 和 graph health gates；同时
保存 $A_{\mathrm{phys}}$ score、raw 左右残量/backward error、near-null separation、graph
Dirichlet/Neumann/kernel defect 以及 center/wall/probe participation 的最小摘要。它们说明输入
向量不是显然的代数或零场伪影，但不进入 $\eta_{\lambda,h}^{\mathrm s}$ 的 continuous 公式，也
不替代 strong residual。

## 7. 覆盖、忽略项与结果名称

本次 **覆盖**：

- 当前 saved candidate $\mu_h=\widehat k_h^2$；
- 由当前 fine near-null wall vector 决定的中心有限 Fourier 场；
- center homogeneous PDE；
- double-precision branch 产生的 $\delta_m$ 色散 residual，而不是把它手工当成零；
- 固定 cutoff 产生的全部体 residual；
- 当前 reconstructed field 到整个 continuous spectrum 的 strong-residual 距离关系。

本次 **不覆盖**：

- 左右周期 lead 中与 I2 mode 相符的全局场；
- BIE density、cell-to-cell propagation、half-guide tail 和材料界面 reconstruction error；
- Fourier cutoff $|m|>48$、boundary Nyström 和 proxy 对真实 mode 的误差；
- 当前 sharp-disk continuous projected essential gap；
- gap 内连续离散谱的唯一性、multiplicity 或指定 $k_*$ 的身份；
- Simpson 积分和 floating-point error 的可靠上包络。

因此通过内部门后的正式名称为
`CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE`。不得称
`empirical eigenvalue-error estimator`，不得把 $\eta_{\lambda,h}^{\mathrm s}$ 直接写成
$|k_*-\widehat k_h|$ 的估计，更不得称 certified upper bound。

固定单胞 cutoff 是重要 caveat：即使 I2 离散趋于完善，$\chi'$ 和 $\chi''$ 项也不会自动消失。
如果得到 $O(1)$ 的 residual，这是合法结果，说明该最短 reconstruction 对目标误差缺乏分辨率；
不得在同一 attempt 中放宽 cutoff、增加普通胞元或换 reconstruction 以追求更小数值。

## 8. 未来可靠区间、gap 与预注册分辨率

若未来对数值 residual 得到可靠上包络 $\overline\eta_{\lambda,h}$，则可定义

$$
I_h^\lambda=[\mu_h-\overline\eta_{\lambda,h},
\mu_h+\overline\eta_{\lambda,h}].
$$

只有 $I_h^\lambda\subset(0,\infty)$ 时才映射为

$$
I_h^k=[\sqrt{\mu_h-\overline\eta_{\lambda,h}},
\sqrt{\mu_h+\overline\eta_{\lambda,h}}].
$$

在看结果前冻结

$$
\tau_k^{\mathrm{pre}}=10^{-6},
\qquad
\rho_G^{\mathrm{pre}}=0.1.
$$

$\tau_k^{\mathrm{pre}}$ 继承 I1 候选搜索所采用的可接受频率区间宽度尺度；
$\rho_G^{\mathrm{pre}}=0.1$ 要求预注册的绝对分辨率尺度本身不超过 continuous gap 的十分之一。
若 certified gap $G_k$ 存在，权威门为

$$
\operatorname{diam}(I_h^k)\leq\tau_k^{\mathrm{pre}},
\qquad
\tau_k^{\mathrm{pre}}\leq
\rho_G^{\mathrm{pre}}\operatorname{diam}(G_k).
$$

本次没有 reliable numerical enclosure，也没有当前 continuous projected gap，故
gap containment、discrete-eigenvalue existence、absolute/gap-relative resolution 和 unique
target 全部固定为 `NOT_REACHED`。预注册这两个数值不允许把 `NOT_REACHED` 改成经验通过。

## 9. 失败顺序与 fail-close 语义

失败按下列顺序记录首项，不以较晚的理论缺口掩盖较早的实现问题：

1. 输出目录已存在、MATLAB/dependency 不满足、seed/point 异常或资源越界：
   `EXECUTION_UNAVAILABLE`；
2. seed/point 的冻结 evaluator health gate 失败：
   `FINITE_DISCRETE_INPUT_UNAVAILABLE`；
3. $q$ 非 finite、$\|q\|_2=0$ 或 $U_{2048}\leq10^{-12}$：
   `NONZERO_CONFORMING_FIELD_UNAVAILABLE`；
4. norm 非 finite、Simpson ladder 或 phase/scale invariance 门失败：
   `CONTINUOUS_STRONG_RESIDUAL_UNRESOLVED`；
5. 上述门通过后：保存 computed estimator candidate，并把首个尚未关闭的严格升级门记为
   `RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE`；
6. `PROJECTED_GAP_NOT_ESTABLISHED` 同时作为当前独立理论 blocker；gap containment、频率
   resolution、gap 内离散谱存在和 unique target 均记 `NOT_REACHED`。

第 5 项不是实验失败：它准确限定本次输出只能作内部 residual indicator。第 6 项也不撤销第 5
项已计算的 continuous residual。

只允许以下最小重试：修正启动命令或明显的 schema/implementation bug，并换一个新的 append-only
attempt tag；每次修改和原因写入新 report。不得因 residual 大、gap 不可用或分辨率失败而改变
candidate、cutoff、quadrature ladder、阈值或字段解释。

## 10. 实现、schema、输出与资源

### 10.1 单入口原则

优先只新建

```text
test/i3/s-resid/check_s_resid.m
```

并依赖正常 MATLAB path 上唯一的 `eval_i21` 和必要 package functions。不得复制 I2.1 evaluator，
不得搜索 repository root，不得读取 Git、Markdown、历史 output、manifest 或 hash。

脚本长度由科学模块决定，不设机械行数上限；若实现超过约 1000 行，只有在 field construction、
quadrature、qualification 或 report writer 已形成清楚的独立科学模块时才允许拆分。不得为抽象、
未来扩展、provenance 或大范围防御而拆分；单入口仍是首选。

### 10.2 Append-only 输出

正式输出目录为

```text
test/i3/s-resid/output/center-a1/
```

运行前只检查该目录不存在。输出只含：

```text
result.mat
report.md
```

建议 compact schema `TEP_I3_1_CENTER_STRONG_RESID_V1` 至少保存：

- `attempt`、candidate、$\mu_h$、fine config 和 cutoff；
- seed/point input-health 摘要与有限矩阵原始诊断；
- $q$ norm、branch-ordered $\beta_m,\gamma_m$；
- 三层 Simpson 的 $U_N,R_N,\eta_{\lambda,N}$，三个 residual-component norms，以及
  $\|r_{\mathrm{disp}}\|/\max(R,\mathrm{realmin})$；
- 每个 mode 的 $\delta_m$ 和归一化最大色散差；
- finest-level convergence 与 phase/scale-invariance defect；
- covered/ignored term flags；
- `reliable_numerical_enclosure=false`、
  `projected_gap_established=false` 及所有后续 `NOT_REACHED` fields；
- first failure、总耗时、峰值 active snapshot 和 retry count。

### 10.3 命令与资源

跑前审查通过后的正式命令为

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','s-resid'), ...
  fullfile(pwd,'test','i2','k-count')); check_s_resid('center-a1');"
```

成本只有一次 fine seed、一次 candidate point 和三个很小的一维积分。按历史 evaluator 约
$20$ 秒、$63$ MiB 的量级，预估总耗时 $20$--$40$ 秒、峰值低于 $100$ MiB；冻结 soft/hard
wall time 为 $60/180$ 秒，active snapshot 上限为 $256$ MiB。达到 soft limit 后不再启动新阶段；
达到 hard limit 或内存上限立即 fail close 并写出可用诊断，不自动增加资源。

## 11. 验收与下一步

首次正式 run 只有同时满足下列条件才算交付了 I3.1 的最小 computed indicator：

1. fine seed 和 saved-candidate point 使用同一冻结 evaluator/frame 并通过输入 health；
2. $u_h^{\mathrm c}$ 非零且定义域论证适用；
3. 三层积分 finite，finest 两层 ratio 稳定，phase/scale test 通过；
4. report 明确给出 $U$、$R$、$\eta_{\lambda,h}^{\mathrm s}$ 和固定 cutoff caveat；
5. machine fields 保留 `RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE`、
   `PROJECTED_GAP_NOT_ESTABLISHED` 及后续 `NOT_REACHED`，不越界解释。

通过只允许 I3.1 报告一个可复现、直接作用于 continuous operator 的 strong-residual estimator
candidate。下一项最小科学 gate 不是 finite-root refinement，而是判断是否值得为该同一 residual
建立可靠积分 enclosure；只有 enclosure 可用后，才有必要认证当前 sharp-disk projected gap 并
检查 interval containment。若 fixed-cell cutoff residual 已明显大于项目尺度，合法结论是该最短
reconstruction 缺乏目标分辨率，后续应在另行设计中决定是否重构 lead field，而不是修改本次
冻结实验。

相关理论入口见 [[research/projects/eig-apost/phase3-analysis/s-estimator|continuous residual theory]]、
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|field reconstruction boundary]]；I2 输入见
[[research/projects/eig-apost/implementation/i2/report|I2 stage report]]。
