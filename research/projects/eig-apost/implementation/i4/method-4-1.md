# I4.1 独立 reference 方法稿

状态：`METHOD REVIEW PASSED WITH CONDITIONS / NO EXPERIMENT AUTHORIZATION`
方法：`geometry-fitted conforming FEM supercell with twist-band collapse`
证据链：[[research/projects/eig-apost/implementation/i4/sources|sources]]
候选比较：[[research/projects/eig-apost/implementation/i4/methods|methods]]

本文件是 literature/method research artifact。它不是
`design-4-1.md`，不冻结 mesh、supercell size、twist sample、solver、tolerance、run command 或
attempt，也没有产生 reference number 或 effectivity result。

## 1. 方法目标与 claim boundary

目标是在不读取 current estimator、BIE density、QZ eigenvector、same-trial diagnostics 或
$\widehat k_h$ 精确位置的条件下，独立生成 broad window/gap 内所有 independently qualified
guided branches 的 empirical reference collection

$$
\{(k_{\mathrm{ref},j},u_{\mathrm{ref},j},
\Delta_{\mathrm{ref},j}^{\mathrm{obs}}):j\in\mathcal J_{\mathrm{qual}}\}.
$$

该 collection 支持两层、不可混用的 truth contract。第一层只形成有限 observed set
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 及到该集合的 empirical distance；它不自动等于到
continuous gap-discrete spectrum 的距离。第二层才针对一个预先标记的 mode；只有 current
estimator 已冻结为 target-specific，或另有 continuous isolation 使第一层与该 target 等价时，
才允许 single-mode error/effectivity comparison。field label 相同只支持 mode consistency，
本身不完成该升级。

本方法稿最多建立以下 `CONDITIONAL` claim：若 independently computed bulk gap、localized
defect branch、mesh refinement、supercell/twist collapse 和 solver checks 均通过，则 finest frozen
FEM result 可在未来作为 **empirical independent reference**。它不建立：

- certified $\varepsilon_{\mathrm{ref}}$；
- reference error upper bound；
- $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 对 continuous discrete spectrum 的 certified completeness；
- current estimator 的 effectivity、reliability 或 efficiency；
- current $\widehat k_h$ 与某个 reference root 是同一 mode；
- continuous eigenvalue existence/certified gap；这些属于未来 I4.2 或其他严格工作。

`ESTABLISHED` 的只有连续问题定义、方法的离散对象、两层 truth contract 和信息隔离规则；
supercell finest level 是否足够解析、branch coverage 是否充分、
$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 是否小到可用，都必须由未来预注册计算决定。

## 2. 必须完全一致的 continuous guided-mode problem

取横向周期胞元 $Y=(-1/2,1/2)$，无界条带

$$
\Omega=\mathbb R\times Y.
$$

普通 lead cell 宽度为 $1$。在每个 ordinary cell
$C_j=(j-1/2,j+1/2)\times Y$ 中，介质柱为以胞元中心为圆心、半径 $R=0.2$ 的 sharp disk；
中心 $C_0$ 缺去整列介质柱并保持 homogeneous background。定义 piecewise-constant coefficient

$$
q(x,y)=
\begin{cases}
17,&(x,y)\text{ 位于 }j\ne0\text{ 的 lead disk 内},\\
1,&\text{其他位置}.
\end{cases}
$$

固定 $\beta=0.5$，场满足

$$
u(x,y+1)=e^{\mathrm i\beta}u(x,y).
$$

连续特征问题是寻找 $k>0$ 和非零 $u\in H^1_\beta(\Omega)$，使

$$
-\Delta u=k^2q u
\quad\text{in each material subdomain},
$$

且 disk interfaces 上 $u$ 与 $\partial_\nu u$ 连续，$u$ 沿 $|x|\to\infty$ 局域/衰减。令
$\lambda=k^2$，其弱形式为

$$
a(u,v)=\lambda m(u,v)
\quad\text{for all }v\in H^1_\beta(\Omega),
$$

其中

$$
a(u,v)=\int_\Omega\nabla u\cdot\nabla\overline v,
\qquad
m(u,v)=\int_\Omega q u\overline v.
$$

这对应 current continuous transmission contract，即 $u$ 与 $\partial_\nu u$ 均跨界面连续。任何软件中的 TE/TM 名称
只有在其 scalar weak form 可显式化为 $A=I$、$B=q$ 后才算匹配；若得到的是
$-\nabla\cdot(q^{-1}\nabla u)=\lambda u$，则是另一 polarization，必须输出
`CONTINUOUS_MODEL_MISMATCH`，不得比较数字。

连续对象由 [[research/projects/eig-apost/phase4-report/method|current method authority]] 和
[[research/projects/eig-apost/implementation/i2/report|I2 physical summary]] 固定；本稿没有改变
任何公式、证书或历史 conclusion。

## 3. 所选独立方法的数学表述

### 3.1 Supercell periodization

对整数 $N\ge1$，定义包含一个 missing column 和两侧 ordinary lead cells 的 supercell

$$
\Omega_N=(-N-1/2,N+1/2)\times Y,
\qquad
L_N=2N+1.
$$

令 $q_N$ 为上述 $q$ 在 $\Omega_N$ 的限制并沿 $x$ 以周期 $L_N$ 延拓。引入与 current
calculation 无关的 supercell twist $\vartheta\in[-\pi,\pi)$：

$$
u(x+L_N,y)=e^{\mathrm i\vartheta}u(x,y),
\qquad
u(x,y+1)=e^{\mathrm i\beta}u(x,y).
$$

记满足两项条件的空间为 $V_{N,\vartheta,\beta}$。对每个 $\vartheta$，求

$$
a_N(u_{N,j}^{\vartheta},v)
=\lambda_{N,j}^{\vartheta}m_N(u_{N,j}^{\vartheta},v)
\quad\text{for all }v\in V_{N,\vartheta,\beta},
$$

其中积分限制在 $\Omega_N$，并取

$$
m_N(u_{N,j}^{\vartheta},u_{N,j}^{\vartheta})=1.
$$

该问题是 real $\vartheta$ 下的 self-adjoint generalized eigenproblem。它 periodizes the defect，
没有人工 PML，也没有 current half-guide map。

### 3.2 Geometry-fitted conforming FEM

选取严格贴合每个 disk interface 的 conforming mesh，并令
$V_{N,h,p}^{\vartheta,\beta}\subset V_{N,\vartheta,\beta}$ 为 conforming finite-element
space。离散对象为

$$
a_N(u_{N,h,p,j}^{\vartheta},v_h)
=\lambda_{N,h,p,j}^{\vartheta}
m_N(u_{N,h,p,j}^{\vartheta},v_h)
\quad
\text{for all }v_h\in V_{N,h,p}^{\vartheta,\beta}.
$$

等式的数学内容是
$a_N=\lambda_{N,h,p,j}^{\vartheta}m_N$。未来实现必须直接组装这两个 volume forms，不能先
生成 BIE/DtN/QZ object 再包装为 FEM。

Fliss (2013) 直接给 fixed-$\beta$ guided eigenfunction 在 projected gap 内的指数衰减，并说明
supercell 正是利用该性质；Giani (2013) 直接给 conforming FEM removed-column line-defect
supercell eigenvalue 和 field；Soussi (2005；online 2006) 的 publisher abstract 直接报告 compact-defect
supercell frequency exponential convergence 和 wave-vector quasi-independence。把三者组合到
current exact sharp-disk line defect 是 `CROSS-SOURCE INFERENCE`，不是已证明的 numerical
bound。证据 locator 见 [[research/projects/eig-apost/implementation/i4/sources#核心来源|core sources]]。

## 4. 求解对象：guided eigenvalue 与 eigenfunction

主对象不是单个 twist 的某个最近 root，而是搜索域内每条 localized supercell defect band

$$
\mathcal B_{N,j}
=\{\lambda_{N,j}^{\vartheta}:\vartheta\in[-\pi,\pi)\},
$$

及相应 normalized fields $u_{N,j}^{\vartheta}$。定义其 exact-in-$\vartheta$ band summary

$$
\lambda_{N,j}^{\min}=\inf_\vartheta\lambda_{N,j}^{\vartheta},
\qquad
\lambda_{N,j}^{\max}=\sup_\vartheta\lambda_{N,j}^{\vartheta},
$$

$$
\bar\lambda_{N,j}
=\frac{\lambda_{N,j}^{\min}+\lambda_{N,j}^{\max}}{2},
\qquad
w_{N,j}^{\mathrm{twist}}
=\frac{\lambda_{N,j}^{\max}-\lambda_{N,j}^{\min}}{2}.
$$

未来离散 twist set 只近似这些 quantities，必须在 design 中预先冻结；本稿不指定采样数或
节点。每条 finest accepted branch 的 reference frequency central value 为

$$
k_{\mathrm{ref},j}=\sqrt{\bar\lambda_{\mathrm{ref},j}}.
$$

每条 branch 的 reference field 不是把不同 twists 直接平均。它取一条预注册 anchor twist 上的
normalized field，并通过 common-core phase alignment 向相邻 $N,h,p$ levels continuation；
twist band 只度量 repeated-defect interaction。所有 qualified branches 都进入第 6 节的
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$，不能先挑一个与 $\widehat k_h$ 或其 field 最接近者。

## 5. 与 current BIE/QZ chain 的独立性和信息隔离

### 5.1 真实独立性

M1 的输入只有 continuous physical specification：$Y$、period、disk centers/radius、$q$、
missing column、$\beta$ 和 broad search region。数值对象是 volume stiffness/mass forms。
以下 current objects 全部禁止：

- QP Green function、layer potentials、circle/wall BIE densities；
- one-cell scattering matrices、ordered QZ eigenvectors/subspaces、Riccati/propagation maps；
- current row selectors、trace cutoff、proxy geometry、candidate disk；
- I3 estimator components、same-trial cap diagnostics、nominal intervals；
- $|k_{\mathrm{ref}}-\widehat k_h|$ 或 nearest-current-root score。

两条方法共享 geometry、coefficient、$\beta$ 和 continuous PDE 是 continuous matching，不是
shared numerical bias。M1 的 dominant errors 是 volume FEM approximation、circle-fitted mesh、
supercell copy interaction、twist resolution 和 eigensolver residual；current chain 的 dominant
errors 位于 BIE/Nyström、QP kernel、wall/Fourier trace、one-cell map 与 QZ selection。

### 5.2 Blinding order

未来工作只有按以下顺序才可称 independent reference：

1. 从 physical authority 单独生成 reference specification 和 model hash；
2. 冻结 broad window、bulk-gap procedure、all-branch coverage rule、mode-ID contract、refinement
   ladder 和 stop/failure rules；
3. 完成全部 qualified reference branches、fields、coverage/resolution ledger，并写成 immutable
   collection；
4. 再揭示 current $\widehat k_h$、estimator 和 BIE field；
5. 先执行 observed set-distance contract，再仅在额外条件成立时执行 target-specific contract。

若第 2--3 步中任何 choice 由 current estimator 或 candidate-reference difference 调整，结果标记
`REFERENCE_INFORMATION_LEAKAGE` 并失去 I4.1 主 reference 资格。

## 6. 搜索窗口与 target-mode identification

### 6.1 Broad window

当前 $k\approx1.85$ 只允许用于未来 design 中声明一个宽搜索窗口 $I_{\mathrm{broad}}$，使目标
物理频段不会被遗漏。窗口内必须返回所有通过 independent localization criteria 的 branches；
不得以距离 $1.85$ 或 $\widehat k_h$ 最近作为排序/通过条件。

第一层 truth target 是 I3 的整个 gap-discrete spectrum，而不是一个预命名 mode。因此 future
set-distance comparison 还要求 $I_{\mathrm{broad}}$ 覆盖 independently computed target gap 的
完整正频率像；若只搜索局部窗口，它仍可作 mode-location study，但必须输出
`REFERENCE_SET_COVERAGE_UNRESOLVED`，不得报告第一层 effectivity。

### 6.2 Independent projected gap

先对没有 defect 的 ordinary cell，以同一 scalar weak form、fixed $\beta$ 和 $x$-Bloch phase
计算 bulk bands，形成 reference-own approximation of the projected spectrum。只有位于独立
bulk gap interior、并在 bulk refinement 下保持 separated 的 supercell branches 才进入 defect
mode screen。gap edge uncertainty 未解析时输出 `BULK_GAP_UNRESOLVED`。

令 $\mathcal J_{\mathrm{qual}}$ 收集搜索域内所有通过 gap、localization、twist、field continuation
和 resolution gates 的 branches，并定义有限 observed set

$$
\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}
=\{k_{\mathrm{ref},j}:j\in\mathcal J_{\mathrm{qual}}\}.
$$

冻结 artifact 必须同时导出 coverage ledger：搜索域与 gap 的关系、各 refinement level 返回的
全体 branch/cluster、出现或消失的 branches、未解析 multiplicity，以及所有 qualification failures。
只有该 ledger 在预注册规则下显示经验 coverage 足够，才可计算到
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 的 observed distance。即使 coverage gate 通过，
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ 仍只是有限 empirical set；没有 certified count/isolation
时不得把它写成 $\mathcal K_{\mathrm{disc}}(A;G_\lambda)$，也不得把两者的距离声称为相等。

### 6.3 Mode label

对每个 gap branch 记录下列不含 current root 的 label：

$$
\mathfrak m
=(g,\pi_x,\mathcal L,\mathcal T,\mathcal C),
$$

其中 $g$ 是 independent projected-gap index，$\pi_x$ 是在 reflection-compatible anchor
problem 中的 $x$-parity label，$\mathcal L$ 是 center localization signature，$\mathcal T$ 是
outer-cell tail/decay signature，$\mathcal C$ 是 across-level common-core continuation record。

可用的无量纲 field functionals 包括

$$
L_0(u)=\frac{\int_{C_0}q|u|^2}{\int_{\Omega_N}q|u|^2},
\qquad
T_J(u)=\frac{\int_{\Omega_N\setminus\bigcup_{|j|\le J}C_j}q|u|^2}
{\int_{\Omega_N}q|u|^2},
$$

以及把两层 field 限制到共同中心区域、消除 global phase 后的 normalized overlap。这里的
$J$、threshold 和 overlap acceptance 必须在 design 中预注册，本稿不指定数值。

通过条件的科学含义是：branch 位于 independently identified gap；随 $N$ 增大，其 twist width
和 outer mass 收缩；core field 在 common domain 上 continuation；parity/branch label 不交换。
若两个 branches 无法分配 target-specific label，但能分别解析且都进入
$\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$，第一层 set-distance 不要求从中挑选一个。若 cluster
本身无法枚举或解析，输出 `REFERENCE_SET_COVERAGE_UNRESOLVED`；若只阻止指定-mode 选择，
输出 `MODE_ID_AMBIGUOUS`。两种情形都不得以最近 $\widehat k_h$ 消歧。

只有 reference artifact 冻结后，才可将 BIE field 独立评价到同一 physical core，比较 parity、
localization、decay 和 phase-free overlap。该比较只提供 mode-consistency evidence，不证明
对应 branch 是离 $\widehat k_h$ 最近的 continuous spectral point，也不证明 estimator 是
target-specific。若 label 不匹配，合法结果是 `REFERENCE_MODE_MISMATCH`，不是改选另一个更近
root；若 label 匹配但没有第 9 节要求的 target contract，则保留第一层结果并输出
`TARGET_SPECIFIC_UPGRADE_UNAVAILABLE`。

## 7. Reference refinement 与 resolution strategy

主路线要求至少四类 mutually visible axes：

1. **FEM space axis**：在 fixed supercell/twist 上改变 $h$ 和/或 $p$，检查 eigenvalue、
   conforming residual、interface resolution 和 common-core field；
2. **supercell axis**：增加 $N$，检查 band center、twist half-width、outer mass 和 core field；
3. **twist axis**：解析/加密 $\vartheta$ 对 defect band extrema 的近似，防止只取一个 favorable
   phase；
4. **algebraic axis**：收紧 eigensolver tolerance、检查 generalized eigen-residual、重复 phase
   normalization。

axes 的顺序、levels 和 stop thresholds 属于 future design，本稿不指定。reference resolution
只有在同一 branch label、相邻 refinement 和 cross-axis check 都通过时才可报告。单轴 flattening、
单一 rich solve 或位置接近 current candidate 都不构成 resolution。

若目标 branch 靠近 independently computed gap edge，使 field decay 太慢、twist band 在可接受
资源内不收缩，则 M1 输出 `SUPERCELL_RESOLUTION_UNAVAILABLE`。此时可以在新的、另行审查的
future design 中升级到 [[research/projects/eig-apost/implementation/i4/methods#M2 — FEM + RtR transparent boundary|M2 FEM+RtR]]；
不得在同一 attempt 内临时换 boundary treatment。

## 8. 经验 resolution 与 $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$

对每个 $j\in\mathcal J_{\mathrm{qual}}$，设 finest accepted object 为 $k_{f,j}$。对最后两个
qualified FEM levels、supercell levels、twist resolutions 和 algebraic levels，逐 branch 定义
observed changes

$$
\delta_{\mathrm{FEM},j}^{\mathrm{obs}},
\quad
\delta_{N,j}^{\mathrm{obs}},
\quad
\delta_{\mathrm{twist},j}^{\mathrm{obs}},
\quad
\delta_{\mathrm{alg},j}^{\mathrm{obs}}.
$$

其中 $\delta_{\mathrm{twist},j}^{\mathrm{obs}}$ 至少包含 finest defect-band half-width 对频率的
映射，而不是仅含 quadrature change。为方便 future comparison，可报告 conservative observed
envelope

$$
\Delta_{\mathrm{ref},j}^{\mathrm{obs}}
=\delta_{\mathrm{FEM},j}^{\mathrm{obs}}
+\delta_{N,j}^{\mathrm{obs}}
+\delta_{\mathrm{twist},j}^{\mathrm{obs}}
+\delta_{\mathrm{alg},j}^{\mathrm{obs}}.
$$

该加和只是把已观察到的末级 changes 置于同一频率尺度；它没有证明 omitted error 小于这些
changes 的和。collection 必须保存
$\boldsymbol\Delta_{\mathrm{ref}}^{\mathrm{obs}}=(\Delta_{\mathrm{ref},j}^{\mathrm{obs}})_{j\in\mathcal J_{\mathrm{qual}}}$
及每支的 components，
不能用单个最大值掩盖 branch-dependent resolution。除非未来另有 current-model
theorem、verified constants 和 directed arithmetic，禁止写

$$
|k_{*,j}-k_{f,j}|\le\Delta_{\mathrm{ref},j}^{\mathrm{obs}}.
$$

允许的措辞是 `observed reference resolution` 或 `empirical sensitivity envelope`。若 refinement
不稳定、changes 不下降、twist extrema 未解析或 branch identity 失败，则对应 branch 不报告有限
scalar，输出 `REFERENCE_RESOLUTION_UNRESOLVED`。该 branch 是否从 qualified set 移除及是否因此
触发 coverage failure，必须由预注册 coverage rule 决定，不能在揭盲后临时处理。

## 9. Future effectivity comparison 的输入与输出

本节只规定 information contract，不指定 experiment grid、命令或 attempt。

### Reference 在揭盲前必须输出

- physical/model hash 与 scalar weak-form identity；
- frozen search domain、bulk gap record、coverage rule 与 coverage ledger；
- 完整 $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$，以及每支的 $k_{\mathrm{ref},j}$、mode label
  $\mathfrak m_j$ 和 normalized field on a declared common physical region；
- 每支 four-axis resolution ledger、$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 和 collection vector
  $\boldsymbol\Delta_{\mathrm{ref}}^{\mathrm{obs}}$；
- all failure/caveat flags and provenance。

### 揭盲后才允许输入

- current $\widehat k_h$；
- I3 已冻结、单位为 frequency error 的 empirical estimator 值，以及其不可事后更改的 truth-target
  tag：`SET_DISTANCE` 或 `TARGET_SPECIFIC`；
- independently evaluable current physical field，用于同-mode check。

若 estimator 没有冻结的 truth-target tag，立即输出 `ESTIMATOR_TARGET_UNFROZEN`，以下两层均不
形成 effectivity ratio。

### 第一层：observed set-distance

只有 coverage ledger 通过时才定义

$$
d_{\mathrm{set}}^{\mathrm{obs}}
=\operatorname{dist}(\widehat k_h,\mathcal K_{\mathrm{ref}}^{\mathrm{obs}})
=\min_{j\in\mathcal J_{\mathrm{qual}}}
|\widehat k_h-k_{\mathrm{ref},j}|.
$$

这是到有限 empirical reference set 的 observed distance，不是已认证的
$e_h^{\mathrm{gap}}=\operatorname{dist}(\widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda))$。
必须逐支传播 observed
resolution。令 $(x)_+=\max(x,0)$，定义仅作敏感性分析的

$$
d_{\mathrm{set},-}^{\mathrm{obs}}
=\min_j\bigl(|\widehat k_h-k_{\mathrm{ref},j}|
-\Delta_{\mathrm{ref},j}^{\mathrm{obs}}\bigr)_+,
\qquad
d_{\mathrm{set},+}^{\mathrm{obs}}
=\min_j\bigl(|\widehat k_h-k_{\mathrm{ref},j}|
+\Delta_{\mathrm{ref},j}^{\mathrm{obs}}\bigr).
$$

若 coverage 未通过，输出 `REFERENCE_SET_COVERAGE_UNRESOLVED`；若
$d_{\mathrm{set}}^{\mathrm{obs}}=0$ 或 $d_{\mathrm{set},-}^{\mathrm{obs}}=0$，输出
`REFERENCE_RESOLUTION_DOMINATES`。只有 estimator 的 frozen tag 是 `SET_DISTANCE` 且两门均通过，
才可报告描述性的

$$
\mathrm{eff}_{\mathrm{set}}^{\mathrm{obs}}
=\frac{\eta_h^{\mathrm{gap}}}{d_{\mathrm{set}}^{\mathrm{obs}}},
\qquad
\left[
\frac{\eta_h^{\mathrm{gap}}}{d_{\mathrm{set},+}^{\mathrm{obs}}},
\frac{\eta_h^{\mathrm{gap}}}{d_{\mathrm{set},-}^{\mathrm{obs}}}
\right].
$$

即使该 ratio 可报告，也只能称 effectivity against the observed finite reference set；没有另行
coverage theorem 时不能删去 `observed` 或改称 continuous set-distance effectivity。

### 第二层：target-specific comparison

仅在以下至少一项成立时，才允许选择预先标记的 $j_*$ 并使用 single-mode denominator：

1. I3 estimator 在 reference 揭盲前已冻结为对应 mode 的 `TARGET_SPECIFIC` estimator；或
2. 另有 continuous isolation 结论足以证明
   $e_h^{\mathrm{gap}}=|\widehat k_h-k_*|$，而不只是两个数值 field 的 label 相同。

还必须通过 frozen mode label/field consistency；$j_*$ 不得由 nearest-$\widehat k_h$ rule 产生。
满足这些条件后才定义

$$
e_*^{\mathrm{obs}}
=|\widehat k_h-k_{\mathrm{ref},j_*}|.
$$

若 $e_*^{\mathrm{obs}}=0$ 或
$e_*^{\mathrm{obs}}\le\Delta_{\mathrm{ref},j_*}^{\mathrm{obs}}$，仍输出
`REFERENCE_RESOLUTION_DOMINATES`。否则，令 $\eta_h^{\mathrm{target}}$ 表示相应 truth contract
下的 estimator：情形 1 使用已冻结的 target-specific estimator；情形 2 使用因 continuous
isolation 已证明与该 target 等价的 set-distance estimator。只有此时才可形成
$\eta_h^{\mathrm{target}}/e_*^{\mathrm{obs}}$ 及以
$\Delta_{\mathrm{ref},j_*}^{\mathrm{obs}}$ 作分母扰动的 empirical sensitivity band。若只有 field
label 相同而没有上述 estimator/isolation 条件，输出 `TARGET_SPECIFIC_UPGRADE_UNAVAILABLE`；
不得把第一层 set-distance result 改名为同-mode effectivity。

两层中的 sensitivity band 都不是 confidence interval 或 certified effectivity enclosure，因为
$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 不是 true-error bound。位置一致而 field/mode label 不一致时，
结论是 `REFERENCE_MODE_MISMATCH`；field/mode 一致但 denominator unresolved 时，只能说 location
agrees within observed reference resolution。

## 10. 假设、适用范围与合法失败状态

### 假设

- coefficient real、positive、piecewise constant，continuous problem self-adjoint；
- reference search domain covers the independently computed target gap for the first-layer contract；
- each included object is a localized discrete branch；第一层允许多个 branches，第二层另需
  target-specific estimator 或 sufficient continuous isolation；
- fitted conforming FEM faithfully represents $A=I$, $B=q$ and both quasiperiodic phases；
- each qualified supercell branch/cluster can be tracked across the chosen refinement hierarchy；
- empirical coverage and resolution gates are applied before reveal and fail closed。

### 合法失败状态

| 状态 | 含义 | 允许的下一步 |
|---|---|---|
| `CONTINUOUS_MODEL_MISMATCH` | polarization、coefficient、phase 或 normalization 不能映射 | 修正 specification；不得比较数值 |
| `BULK_GAP_UNRESOLVED` | independent lead bands 未解析或 window touches gap edge | 只加密 reference-own bulk problem |
| `NO_LOCALIZED_BRANCH` | broad window 内无独立局域 branch | 报告负结果；不得追随 $\widehat k_h$ 扩窗 |
| `REFERENCE_SET_COVERAGE_UNRESOLVED` | 搜索域未覆盖完整 gap，或 branch/cluster 枚举与 qualification 不完整 | 第一层 fail closed；不得报告 set-distance effectivity |
| `MODE_ID_AMBIGUOUS` | 多 branch 无法由 frozen labels 作 target-specific 区分，但 set membership 可保留 | 只保留 coverage 充分时的第一层；不得 nearest-root |
| `FEM_RESOLUTION_UNAVAILABLE` | volume discretization 不稳定 | future FEM redesign；不改变 current estimator |
| `SUPERCELL_RESOLUTION_UNAVAILABLE` | defect band/tail 未随 $N$ 收缩 | future M2 RtR design 或停止 |
| `REFERENCE_INFORMATION_LEAKAGE` | refinement/selection 消费 current chain 信息 | 丢弃 reference artifact，重新独立预注册 |
| `ESTIMATOR_TARGET_UNFROZEN` | estimator 未携带冻结的 set/target truth tag | 不形成任何 effectivity ratio |
| `TARGET_SPECIFIC_UPGRADE_UNAVAILABLE` | field label 可匹配，但无 target-specific estimator 或 sufficient continuous isolation | 第一层可保留；不得形成 single-mode ratio |
| `REFERENCE_MODE_MISMATCH` | 揭盲后 current/reference field labels 不同 | 不作 target-specific comparison；已通过的第一层 set result 可保留 |
| `REFERENCE_RESOLUTION_DOMINATES` | reference observed resolution 不小于 location difference | 只报告 unresolved，不形成 ratio claim |

这些失败不会否定 I1--I3 历史结果，也不会自动触发 I4.2。

## 11. Theory-to-future-code map

本表只描述 mathematical responsibility；没有指定语言、文件名、API 或 implementation。

| 数学对象 | future module responsibility | 必须导出的审查对象 |
|---|---|---|
| $q$, disks, missing column, $\beta$ | physical specification | model hash、units、phase/polarization map |
| defect-free Bloch cell operator | bulk-gap solver | band extrema、gap interior、refinement ledger |
| $\Omega_N,q_N,V_{N,\vartheta,\beta}$ | supercell geometry/boundary builder | cell count、twist/quasiperiodic orientation、mesh-interface identity |
| $a_N,m_N$ | conforming FEM assembler | stiffness/mass Hermitian defects、coefficient assignment |
| $(\lambda_j,u_j)$ | generalized eigensolver | all returned eigenobjects、residual、normalization、multiplicity/cluster data |
| $\mathfrak m_j$ | independent branch labeler | gap ID、parity、localization、tail、common-core overlap |
| $\bar\lambda_j,w_j^{\mathrm{twist}}$ | twist-band tracker | all extrema provenance、branch continuation |
| $\delta_{\mathrm{FEM},j}^{\mathrm{obs}},\delta_{N,j}^{\mathrm{obs}},\delta_{\mathrm{twist},j}^{\mathrm{obs}},\delta_{\mathrm{alg},j}^{\mathrm{obs}}$ | branch-wise resolution ledger | raw adjacent changes、qualification/failure flags |
| $\mathcal J_{\mathrm{qual}},\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$ | coverage collector | full returned branch/cluster inventory、search-domain coverage、omissions/failures |
| $(k_{\mathrm{ref},j},u_{\mathrm{ref},j},\Delta_{\mathrm{ref},j}^{\mathrm{obs}})_j$ | immutable reference exporter | blinded collection、coverage and provenance |
| $d_{\mathrm{set}}^{\mathrm{obs}},d_{\mathrm{set},\pm}^{\mathrm{obs}}$ | post-freeze set comparator | estimator target tag、coverage gate、observed-set sensitivity |
| $e_*^{\mathrm{obs}}$ | optional target-specific comparator | frozen target/isolation contract、mode match、resolution dominance |

No module may import current BIE/QZ artifacts before the immutable reference export step.

## 12. 关键主张、来源与 epistemic status

| 编号 | 主张 | 原文支持 | Epistemic status |
|---|---|---|---|
| C1 | current fixed-$\beta$ line-defect operator在 projected gap 中的 guided eigenfunctions 指数衰减 | Fliss (2013), Theorem 3.5，[[ref/ref_data/Fliss2013.pdf|full text]] | `ESTABLISHED` for source problem family；current geometry mapping `CONDITIONAL` |
| C2 | supercell 利用 field decay，把 unbounded guided problem近似为 bounded quasiperiodic eigenproblem | Fliss (2013), pp. 6--9；Soussi (2005；online 2006) publisher abstract | `ESTABLISHED` generally；current exact convergence rate `UNVERIFIED` |
| C3 | conforming FEM 可直接求 line-defect eigenvalue 和 field，并以 rich FEM levels 作 empirical reference | Giani (2013), pp. 2--16，[[ref/ref_data/Giani2013.pdf|full text]] | `ESTABLISHED` for cited examples；not certified truth |
| C4 | weak confinement 会使 supercell cost/error变差，RtR 可避免 Dirichlet exceptional frequencies | Fliss et al. (2015), pp. 1--6, 25--31；Klindworth thesis | `ESTABLISHED` |
| C5 | ordinary finite-section gap eigenvalues可能 spectral pollution；supercell/background-band checks 不可省略 | Cancès--Ehrlacher--Maday (2012), arXiv `1111.3892` | `ESTABLISHED` for adjacent operator；current transfer `CONDITIONAL` |
| C6 | PML eigenproblems可能产生 artificial eigenvalues | Nannen--Wess (2018) open full text | `ESTABLISHED` for resonance PML；supports route downgrade |
| C7 | sharp discontinuous coefficients limit naive PWE convergence | Norton--Scheichl (2013) institutional AAM；David et al. (2006) publisher record | `ESTABLISHED` in cited PWE settings |
| C8 | 每支 $\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 是 empirical sensitivity descriptor，不是 upper bound | definition and explicit absence of a current-model theorem | `ESTABLISHED BY DEFINITION`; coverage claim `REFUTED/NOT MADE` |
| C9 | M1 与 current BIE/QZ 在 numerical formulation、dominant discretization errors 和 implementation information 上独立 | object-by-object dependency audit in Sections 3 and 5 | `CONDITIONAL`; future provenance can falsify |
| C10 | 未发现 exact-parameter public benchmark | 32-query scoped log，[[research/projects/eig-apost/implementation/i4/search-log#2026-08-28 — Query family C：完全匹配 benchmark/data|benchmark search]] | `PROVISIONAL / SEARCH-BOUNDED`，不等于证明不存在 |
| C11 | observed finite-set distance 与 continuous gap-set distance 不得等同；single-mode ratio 另需 frozen target-specific estimator 或 sufficient continuous isolation | [[research/projects/eig-apost/implementation/i3/README#阶段定位|I3 two-layer target authority]] 与 Sections 1, 6, 9--11 的 contract | `ESTABLISHED BY PROJECT CONTRACT`；future coverage/isolation 可失败 |

## 方法稿决定

Researcher bounded-revision recommendation：`GO TO SAME SKEPTIC RE-REVIEW`；同一 Skeptic 的
最终 verdict 为 `PASS WITH CONDITIONS`，详见
[[research/projects/eig-apost/implementation/i4/method-review|method review]]。

选择 M1 的最弱环节是：没有取得一篇全文逐假设证明 exact current fixed-$\beta$ sharp-disk
line defect 的 computable supercell error bound。该缺口把 future reference 降级为 empirical，
但不阻止在严格信息隔离、complete-branch empirical coverage gate 和 multi-axis resolution ladder
下把方法送审。coverage 不充分时第一层必须 fail closed；没有 target-specific estimator 或
continuous isolation 时第二层必须停止。若 Skeptic 认定剩余证据使
mode identity 或 reference resolution 仍无法解释，应将状态降为
`DRAFT / METHOD SELECTION BLOCKED`，最小修复是补一条 current-operator-specific convergence
argument 或采用 M2 FEM+RtR；不得用 current BIE/QZ result 填补。
