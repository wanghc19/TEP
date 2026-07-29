<!-- Analysis section: BIE scattering map, finite-tail DtN, and guided-mode NEP -->

# DtN computation chain

状态：分析设计；公式采用当前 `bloch.construct_S` 的 port convention。两段 scattering
组合公式已通过独立随机复矩阵代数核对，尚未通过 MATLAB 与实际 cell map 数值核对。

## 1. Fixed-beta lead cell

固定 $\beta$ 和试探 $k$。在 $y$-准周期 port basis 中，令 $a^L,b^R$ 为进入一个
bulk cell 的 amplitudes，$b^L,a^R$ 为离开该 cell 的 amplitudes。现有代码返回

$$
  \begin{bmatrix} b^L\\ a^R\end{bmatrix}
  =
  \begin{bmatrix}
    R_L&T_{RL}\\
    T_{LR}&R_R
  \end{bmatrix}
  \begin{bmatrix} a^L\\ b^R\end{bmatrix}.
$$

`bloch.construct_S` 用 `A_QP` 解 inclusion-boundary transmission BIE 的多右端系统，再
由 far-field extractors 得到这四个 blocks。这里 `A_QP` 的角色是 **one-cell BIE
component**，不是 line-defect eigenoperator，也不是 DtN 定义。

## 2. Two finite segments are joined by Schur elimination

设相邻两段分别为 $A$ 和 $B$。消去中间 amplitudes 后，组合 scattering blocks 为

$$
\begin{aligned}
  R_L^{AB}
  &=R_L^A+T_{RL}^A R_L^B
    (I-R_R^A R_L^B)^{-1}T_{LR}^A,\\
  T_{LR}^{AB}
  &=T_{LR}^B(I-R_R^A R_L^B)^{-1}T_{LR}^A,\\
  T_{RL}^{AB}
  &=T_{RL}^A(I-R_L^B R_R^A)^{-1}T_{RL}^B,\\
  R_R^{AB}
  &=R_R^B+T_{LR}^B(I-R_R^A R_L^B)^{-1}
    R_R^A T_{RL}^B.
\end{aligned}
$$

取 $A=B$ 即一次 doubling。由一个 cell 开始，第 $j$ 层代表

$$
  N_j=2^j
$$

个 bulk cells。实现时不得形成显式逆矩阵，而应解相应线性系统，并记录两个 Schur
factors 的 reciprocal condition estimates。

静态核对采用 `3 x 3` 随机复矩阵，分别直接解中间 port amplitudes 和使用上述组合
blocks 计算两侧输出；固定随机种子下，两侧差异的二范数分别为
`2.693e-17` 与 `3.820e-17`。这只核对 Schur elimination 的矩阵代数，不核对现有
MATLAB 代码中的 block 排列、物理归一化或 branch convention。

## 3. Finite-tail reflection and DtN

$S_j$ 的 raw blocks $R_{L,j},T_{RL,j},T_{LR,j},R_{R,j}$ 描述一个两端仍开放的
$N_j$-cell finite segment。首版 guided eigenproblem 不直接在远端令 incoming
amplitude 为零，因为该闭合一般仍有人工泄漏，有限层的真正根可能离开实轴。

为保持实 $k$ eigenproblem 的结构，在右端施加 $D^R=a^R+b^R=0$，消去远端
amplitudes 得

$$
  \widehat R_{+,j}^{D}
  =R_{L,j}-T_{RL,j}(I+R_{R,j})^{-1}T_{LR,j}.
$$

在左端施加 $D^L=a^L+b^L=0$，从中心左边界看到

$$
  \widehat R_{-,j}^{D}
  =R_{R,j}-T_{LR,j}(I+R_{L,j})^{-1}T_{RL,j}.
$$

目标 projected gap 中的工作假设是这两个 terminated reflection maps 随 $j$ 趋向
相应的 half-guide stable maps。zero-incoming 的 $R_{L,j},R_{R,j}$ 仍保留为 map-level
交叉验证序列；它不自动产生可沿实轴追踪的 finite-level eigenvalue。

当前 Rayleigh convention 给出左 port 的 Dirichlet 与正 $x$ 导数系数

$$
  D=a+b,
  \qquad
  N_x=\mathrm{i}\,\Gamma(a-b).
$$

为避免混淆，本文项目把 $\Lambda_+$ 和 $\Lambda_-$ 都定义成：给定中心域边界上的
Dirichlet trace，返回**从中心域指向相应半波导**的法向导数。由右侧
$b=\widehat R_{+,j}^D a$ 得

$$
  \Lambda_{+,j}^{D}
  =\mathrm{i}\,\Gamma(I-\widehat R_{+,j}^{D})
    (I+\widehat R_{+,j}^{D})^{-1}.
$$

左侧中心域向外 amplitude 为 $b$，返回中心域的是
$a=\widehat R_{-,j}^D b$。该端口的正 $x$ 导数是

$$
  N_x=\mathrm{i}\,\Gamma(\widehat R_{-,j}^{D}-I)b,
$$

而从中心域指向左半波导的法向是负 $x$ 方向。因此

$$
  \Lambda_{-,j}^{D}
  =\mathrm{i}\,\Gamma(I-\widehat R_{-,j}^{D})
    (I+\widehat R_{-,j}^{D})^{-1}.
$$

左右两式的代数外形相同，但使用从不同端看到的 terminated reflection；相同外形来自
法向约定和 port convention，不来自结构对称性。除 Cayley factors 外，还必须监控
远端消元中的 $I+R_{R,j}$ 和 $I+R_{L,j}$。进入实现前仍须逐行对照中心域装配中左右
Neumann trace 的符号；详见
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]]。

## 4. Exact and discrete guided-mode functions

令 $F(k)$ 表示中心 defect cell 与精确 half-guide DtN 耦合后的 operator function。
固定 BIE、port 和线性代数参数，仅用 terminated $\Lambda_{+,j}^D,\Lambda_{-,j}^D$
替换精确 DtN，得到同维数矩阵 function $F_j(k)$。

实轴最小奇异值扫描只定位候选。只有局部 nonlinear solve 进一步确认 $k_j$ 是
$F_j$ 的实际简单零点后，才使用 $F_j(k_j)$ 的 unit-norm 左右零向量
$y_j,x_j$ 计算 correction：

$$
  \delta_j
  =-
  \frac{
    y_j^*\bigl(F_{j+1}(k_j)-F_j(k_j)\bigr)x_j
  }{
    y_j^*F_j'(k_j)x_j
  }.
$$

分母可先只计算标量 $y_j^*F_j'(k_j)x_j$。首版采用对称有限差分并对步长做稳定性
检查；complex-step 只有在所有 branch choices 和 code paths 对复 $k$ 保持解析时才可用。

## 5. Three distinct comparisons

这三类比较在 estimator 与 benchmark 中承担不同证据等级；解释规则见
[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]] 和
[[research/projects/eig-apost/phase3-analysis/p-benchmark|reference-truth ladder]]。

1. $\delta_j$ 对比实际相邻根位移 $k_{j+1}-k_j$：检查一阶 correction 是否正确。
2. finite-tail $\Lambda_j$ 对比由 QZ/stable invariant subspace 或 Riccati fixed point
   得到的 $\Lambda_\infty$：只检查 infinity treatment。
3. $k_j$ 对比独立 $k_{\mathrm{ref}}$：评价 estimator 的真实 effectivity。

第 2 项和 finite-tail sequence 共用同一个 cell BIE map，不能冒充整个 eigenvalue 的
双方法 reference truth。
