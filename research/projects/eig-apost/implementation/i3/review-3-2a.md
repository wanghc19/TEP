# I3.2 条件性离散证书谱包含定理独立审查

## 审查结论

- Design ID：`I3.2-CONDITIONAL-DISCRETE-CERTIFICATE-V1`
- 设计：[[research/projects/eig-apost/implementation/i3/design-3-2a|design-3-2a]]
- 最终设计 SHA-256：`866539515bcad70a0cd5a8e217067945b4716cc5d21e3cb8685ad81435bbdca3`
- Researcher verdict：`AGREED`
- Skeptic verdict：`DESIGN PASS`（高置信度）
- 阶段 verdict：`I3_2_CONDITIONAL_THEOREM_ESTABLISHED / APPLICATION HYPOTHESES OPEN`
- 实验：`NO NEW EXPERIMENT`

本审查接受一个严格的条件性定理，不接受当前已有可靠误差界的主张。定理说明：有限证书
$z_h$ 若通过确定性映射 $\mathcal T$ 定义同一个非零连续试验场
$u_h^{\mathrm c}=\mathcal T(z_h)\in V$，且已证明的 cap 给出该场的连续弱残量上界与场范数下界，
则可以构造与连续自伴算子谱相交的区间。只有再证明该区间完全落在同一算子的 certified
projected essential gap 内，才能说区间中至少存在一个离散特征值。

当前 `fbie-a1` 只提供 ordinary-double 中心值和 indicator candidate；它没有提供定理所需的
strict caps。circle action $256\to512$ ratio $0.77408786032496468>0.20$ 仍是 I3.1 的内部
caveat 和未来 I3.3 empirical-cap target，但不阻止本条件性定理成立。

## 1. 数学对象和证明审查

设计固定非负自伴算子 $A$、质量空间 $H$、form domain

$$
V=D\bigl((A+\gamma I)^{1/2}\bigr),
\qquad
\gamma=\mu_h=\widehat k_h^2,
$$

并定义

$$
R_h(v)=a(u_h^{\mathrm c},v)-\mu_h(u_h^{\mathrm c},v)_H.
$$

其中 $z_h\in Z_h$ 是 I3.2 的局部有限证书记号，不是历史
[[research/projects/eig-apost/phase3-analysis/s-estimator|s-estimator]] 中曾用相同字形表示的
$V$-Riesz representative。历史理论不回写；本设计已立即消除该阅读冲突。

证明令

$$
t(\lambda)=\frac{\lambda-\mu_h}{\lambda+\gamma},
\qquad
B_h=t(A),
$$

由有界 functional calculus 定义 $B_h$，避免把形式 sandwich 误当作要求中间向量属于
$D(A)$ 的普通强算子乘积。onto isometry

$$
U:V\to H,
\qquad
Uv=(A+\gamma I)^{1/2}v
$$

把 residual quotient 写成 $\|B_hUu_h^{\mathrm c}\|_H/\|Uu_h^{\mathrm c}\|_H$。自伴算子谱定理
给出到 $\sigma(B_h)$ 的距离。设计又显式使用 $\sigma(B_h)$ 的紧性取到最小点，并排除
$t(\lambda)$ 在 $\lambda\to\infty$ 时产生的闭包点 $1$；因为严格
$\overline q_h<1$，见证必须来自有限的 $\lambda\in\sigma(A)$。两侧解不等式得到精确非对称区间

$$
J_h^\lambda=
\left[
\max\left\{0,
\frac{\mu_h-\overline q_h\gamma}{1+\overline q_h}
\right\},
\frac{\mu_h+\overline q_h\gamma}{1-\overline q_h}
\right].
$$

该证明的量词、operator domain/codomain、Riesz identification、spectral mapping、闭包桥和端点
代数均通过审查。证明没有用 finite determinant zero、score minimizer、离散精确根或 candidate
漂移代替连续 residual。

## 2. 严格证书接口和结论边界

严格输入假设是

$$
\|R_h\|_{V'}
\le M_{\mathrm{exact}}(z_h)
\le\widetilde M_h+\epsilon_M,
$$

$$
\|u_h^{\mathrm c}\|_V^2
\ge\widetilde N_h-\epsilon_N>0,
$$

所以

$$
\overline q_h=
\frac{\widetilde M_h+\epsilon_M}
{\sqrt{\widetilde N_h-\epsilon_N}}.
$$

numerator 和 denominator 必须消费同一个 canonical $z_h$、同一个 $\mathcal T$ 和同一个 saved
candidate。$\epsilon_M$ 必须覆盖 wall、circle、volume、evaluator、Fourier、lift、Bloch、
full-$P$ tail 和 arithmetic omissions；只有带证明的结构零才能取零。$\epsilon_N$ 必须覆盖同一
trial 的 field-lower omissions。设计没有冻结等分 cap、结果后工作盒或按 observed component
大小分配。

机器 Boolean 不是证明。未来严格实例化必须保存 canonical certificate/hash、重构定义、backend、
舍入模式、proof objects 或 witnesses，并由冻结 checker 验证 O1--O10。特别地，
$\gamma=\mu_h=\widehat k_h^2$ 是一个相关的精确对象；未来 outward arithmetic 必须保留这一
相关性，而不是计算两个独立的近似平方。

本轮只建立 generic theorem。`fbie-a1` 的 ordinary output 不能实例化
$\epsilon_M,\epsilon_N$；actual outward residual/field/tail caps、same-operator gap 和 gap
containment 留给 I3.4。无 certified gap 时，严格区间至多给出与全谱相交，不能升级为离散
特征值存在。

## 3. `fbie-a1` 数值预算复核

预算只读取历史 artifact 中的普通双精度值：

$$
\widehat k_h=1.832770289108157,
\qquad
\widetilde M_h=2.29786516751043\times10^{-10},
$$

$$
\widetilde N_h
=\texttt{estimator.field\_lower\_squared}
=4.959111810675795.
$$

$\widetilde N_h$ 直接取保存的 squared quantity；没有对 report 中舍入后的 field lower 再平方。
普通比值约为 $1.0318643108971928\times10^{-10}$，仍不是严格 $\overline q_h$。

仅要求 $\overline q_h<1$ 的 frontier 是

$$
(\widetilde M_h+\epsilon_M)^2
<\widetilde N_h-\epsilon_N.
$$

该边界严格。坐标轴为

$$
\epsilon_M<2.22690633158477703
\quad(\epsilon_N=0),
$$

$$
\epsilon_N
<\widetilde N_h-\widetilde M_h^2
=4.959111810675795-5.2801843280577365\times10^{-20}
\quad(\epsilon_M=0).
$$

对冻结绝对频率宽度 $\tau_k^{\mathrm{pre}}=10^{-6}$，

$$
q_{\mathrm{res}}
=\frac{10^{-6}}
{\sqrt{4\widehat k_h^2+10^{-12}}}
=2.72811057103771594\times10^{-7}.
$$

分辨率可行域是

$$
\widetilde M_h+\epsilon_M
\le q_{\mathrm{res}}\sqrt{\widetilde N_h-\epsilon_N}.
$$

其两个轴截距为

$$
\epsilon_M\le6.07294883936662387\times10^{-7},
\qquad
\epsilon_N\le4.95911110122031616.
$$

这两项不能同时取到。Researcher、Engineer 和 Skeptic 均复核了 strict $q<1$ frontier、non-strict
width frontier 和轴值。高精度十进制预算仍不是 outward certificate；严格实现必须读取 actual
binary64 artifact 并 directed-round。

## 4. 严格、经验和可靠存在性分层

- **I3.2 strict theorem：** 只要严格 cap 假设成立且 $\overline q_h<1$，就得到
  `CONDITIONAL_SPECTRAL_INTERSECTION`。
- **I3.3 empirical layer：** 固定同一个 $z_h$ 后的 nested refinement 最多给出
  `EMPIRICALLY_SUPPORTED_ERROR_CAP` 和 `EMPIRICAL_NOMINAL_TRANSFORM`。same-chain refinement
  不是 independent effectivity reference；二者必须分开。
- **I3.4 reliable application：** 只有 actual outward caps、same-$A$ certified gap、containment
  和绝对/gap-relative resolution 闭合，才能得到
  `RESOLVED_DISCRETE_EIGENVALUE_EXISTS_IN_INTERVAL`。

严格区间缺 gap 时保留连续谱相交；区间穿过 gap edge 时也不声称交点避开本质谱；gap
containment 已成立但宽度失败时保留离散特征值存在性，只报告
`EXISTS_BUT_RESOLUTION_INSUFFICIENT`。经验 $q_{\mathrm{emp}}\ge1$ 与经验 width 失败使用独立
status，不与严格 failure 混写。

## 5. 文献核验和剩余义务

本轮核验本地 [[ref/ref_data/Fliss2013.pdf|Fliss (2013) original]]：Sonia Fliss,
“A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal
Waveguides,” *SIAM Journal on Scientific Computing* 35(2), B438--B461 (2013),
[DOI 10.1137/12086697X](https://doi.org/10.1137/12086697X)。Proposition 3.1（PDF p. 7）在其
fixed-$\beta$ 模型中给出非负自伴算子和本质谱刻画；Proposition 3.3（PDF p. 8）说明 gap 内谱
只含孤立、有限重特征值，可在 gap edges 聚集。

该来源不自动证明当前 sharp-disk coefficient、Bloch 参数、尺度、operator identity 或 certified
inner gap edges。逐项映射和 gap certification 仍是 I3.4 proof obligation。

## 6. 里程碑和历史完整性

2026-08-24 起当前 I3 规划采用四个独立里程碑：

1. I3.1：`PRELIMINARY OBJECTIVE ACHIEVED / COMPUTED ESTIMATOR CANDIDATE`；保留 circle-action
   caveat。
2. I3.2：本条件性证书谱包含定理已经建立；实际 application hypotheses 仍 open。
3. I3.3：经验 error caps 和 independent effectivity validation。
4. I3.4：outward enclosure、certified gap、离散存在性和 upper-bound feasibility。

旧 I3.2/I3.3 标签在历史 design、review、code、test index 和 append-only output 中保持原样；本轮
只同步当前 README、STATUS、DECISIONS、ROADMAP 和 open-problem ledger。没有 MATLAB/Octave
实现，没有新 attempt、command 或 output。

## 7. 完成报告

- Task mode：`Proof from scratch`，随后由 Skeptic 独立 design/proof audit。
- Source file：`design-3-2a.md`，定理 2.1。
- Target environment：新设计中的“条件性谱包含定理”及证明。
- Output file：本独立审查。
- 新增 theorem/label：定理 2.1，仅为项目内 design 编号。
- Verified reference：Fliss (2013), Proposition 3.1（PDF p. 7）与 Proposition 3.3（PDF p. 8）。
- 本轮下载文献：无；使用项目已有本地原文。
- Literature status：`Proof literature verification completed.`
- Remaining proof gaps：定理本身无剩余 gap；circle-action empirical-cap/effectivity 属于 I3.3，
  当前 `fbie-a1` 到 strict cap、same-$A$ certified gap 和 actual application 的义务属于 I3.4，
  均不是定理证明缺口。
