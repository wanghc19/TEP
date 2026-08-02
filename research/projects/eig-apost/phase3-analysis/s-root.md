<!-- Analysis section: distinction between a real-axis singular-value minimum and an NEP root -->

# Root qualification

状态：Phase 3 条件化设计；下述搜索方案在列明的解析域、等价性与简单根假设下成立，
但尚未在当前 BIE 离散上完成实现验证。

## 1. Three objects must remain distinct

固定 $\beta$ 后，必须区分：

1. 实轴 coarse scan 给出的 $\sigma_{\min}(F_j(k))$ 局部极小点；
2. 近似 nonlinear operator $F_j(k)$ 的实际简单零点 $k_j$；
3. 精确 half-guide DtN operator $F(k)$ 的目标零点 $k_*$。

第 1 项只负责定位第 2 项。若 $\sigma_{\min}$ 在 `1e-3--1e-5` 形成平台，第 1 项完全可能
不是第 2 项；此时不能把 simple-root perturbation formula 用在该点，也不能把平台高度
解释成 $\lvert k_j-k_* \rvert$。

标量反例 $F(k)=k-a+\mathrm{i}\epsilon$ 在实轴 $k=a$ 有严格
$\sigma_{\min}$ minimum，却没有实根；这直接排除“实轴 dip 自动等于 eigenvalue”的推断。

整个 hierarchy 固定 BIE/port discretization $h$。所有 $F_{j,h}$ 必须具有相同维数、
unknown ordering、port phase origin、basis normalization、mass/flux pairing、row/column
scaling 和 auxiliary-variable convention。共同且与 $j$ 无关的可逆变换可以使用；
level-dependent scaling 会改变 projected correction，因而不允许。

## 2. Reduced finite-tail cross-check

对 $N_j=2^j$ 个 cell 的 finite segment，直接令远端 incoming scattering amplitude 为零，
等价于让有限段继续向一个人工外部介质辐射。这个 finite-level map 可以收敛到半无限
periodic tail，但有限 $j$ 的中心耦合一般不是自伴有界 eigenproblem；其真正零点可能
离开实轴。若仍只在实轴扫描，得到的通常只是一个 singular-value minimum。

Dirichlet 或预先冻结的 real Robin closure 仍可生成结构保持的 finite-tail
cross-check，zero-incoming sequence 则用于 half-guide map 交叉验证。但在证明
weighted-Hermitian structure 以前，三种 finite-level functions 的根都按复 $k$ 搜索，
不能预设根留在实轴。

## 3. Dirichlet-terminated reflection maps

令 $S_j$ 是 $N_j$-cell segment 的 scattering matrix，blocks 与
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]] 相同。
右端施加 $D^R=a^R+b^R=0$ 后，从中心右边界看到的 reflection map 是

$$
  \widehat R_{+,j}^{D}
  =R_{L,j}-T_{RL,j}(I+R_{R,j})^{-1}T_{LR,j}.
$$

左端施加 $D^L=a^L+b^L=0$ 后，从中心左边界看到的 reflection map 是

$$
  \widehat R_{-,j}^{D}
  =R_{R,j}-T_{LR,j}(I+R_{L,j})^{-1}T_{RL,j}.
$$

两式来自消去远端 amplitudes。实现时只解线性系统，不形成显式逆，并记录
$I+R_{R,j}$、$I+R_{L,j}$ 的 reciprocal condition estimates。终端 Dirichlet
resonance 或 termination-localized state 会表现为这些 factors 病态或根序列不稳定，
必须作为 failure case 报告。

独立静态核对使用 `4 x 4` 随机复 scattering blocks，分别直接解远端 Dirichlet
constraint 和使用上述两个 reduced maps；右、左 map differences 为 `6.397e-17`、
`6.728e-17`，对应 Dirichlet constraint residuals 为 `6.974e-17`、`6.547e-17`。
该检查只确认矩阵消元，不确认物理 self-adjointness 或 MATLAB block convention。

在当前中心域向外法向约定下，令 $\widehat R$ 代表相应一侧的 terminated reflection，
则

$$
  \Lambda_{±,j}^{D}
  =\mathrm{i}\,\Gamma(I-\widehat R_{±,j}^{D})
   (I+\widehat R_{±,j}^{D})^{-1}.
$$

这个 Cayley transform 还需要 $I+\widehat R$ 可逆。对实 $k$、真实材料和 projected
gap，连续 finite-domain DtN 应具有相应的 self-adjoint symmetry；离散检查必须使用
与 port basis 一致的 trace mass/flux pairing，不能只看未缩放矩阵是否逐元素 Hermitian。

## 4. Primary root function: augmented coupling

主 root function 不先形成 terminal Schur complement 或 reflection-to-DtN Cayley
transform。把 center BIE unknown、center-port incoming/outgoing amplitudes 和左右
far-port amplitudes 一起作为 unknown，并同时列出：

1. center BIE 与两侧 port Cauchy matching equations；
2. 左右 $N_j$-cell scattering equations；
3. 两个 far-port 齐次 Dirichlet conditions
   $a^\pm_{\mathrm{far}}+b^\pm_{\mathrm{far}}=0$。

更具体地，设 center BIE density block $\xi$ 的长度为 $n$，每个 port block 的长度为
$p$。按

$$
  z=
  (\xi,a_c^-,b_c^+,b_c^-,a_c^+,a_f^-,b_f^-,b_f^+,a_f^+)^T
$$

排列 $n+8p$ 个 unknowns。center BIE 与 extractors 写成

$$
\begin{aligned}
  A_c\xi+B_La_c^-+B_Rb_c^+&=0,\\
  b_c^- -F_L\xi-J_{LL}a_c^- -J_{LR}b_c^+&=0,\\
  a_c^+ -F_R\xi-J_{RL}a_c^- -J_{RR}b_c^+&=0.
\end{aligned}
$$

其中 $J$ blocks 包含实现中的 direct incident/phase terms。左右 finite-segment equations
按现有 scattering convention 分别是

$$
\begin{aligned}
  b_f^- -R_L^-a_f^- -T_{RL}^-b_c^-&=0,\\
  a_c^- -T_{LR}^-a_f^- -R_R^-b_c^-&=0,\\
  a_f^-+b_f^-&=0,\\
  b_c^+ -R_L^+a_c^+ -T_{RL}^+b_f^+&=0,\\
  a_f^+ -T_{LR}^+a_c^+ -R_R^+b_f^+&=0,\\
  a_f^++b_f^+&=0.
\end{aligned}
$$

前三组 center equations 有 $n+2p$ 行，后六组有 $6p$ 行，因此形成
$F_{j,h}(k)z=0$ 的 square $(n+8p)\times(n+8p)$ matrix。其维数与 $j$ 无关，只有
finite-segment scattering blocks 随 $j$ 改变。这里 $+$/$-$ 表示右/左 lead，不表示
Hermitian adjoint。

若 $A_c$ 在搜索域可逆，消去 $\xi$ 恢复 center defect scattering equations；再消去
far amplitudes 才恢复前两节的 reduced map。这给出可直接测试的代数等价链。对实际 BIE
仍必须证明无 representation nullspace，并证明

$$
  \ker F_{j,h}(k)\ne\{0\}
  \quad\Longleftrightarrow\quad
  \text{the terminated finite-tail problem has a nonzero guided field}.
$$

该等价性还要求 contour 内 one-cell `A_QP(k)` 可逆，或改用能显式容纳其 poles 的
formulation；否则 center representation nullspace 或 cell-solve pole 可能产生伪根。
前两节的 Schur/Cayley form 仅作 well-conditioned cross-check，不作为主 root function。

## 5. One analytic chart per local search

现有 `bloch.rayleigh_channels` 在每个点重新调用 principal square root 并强制
$\operatorname{Im}\gamma_m\ge0$；传播通道跨越实轴时这不是单一解析函数。局部复根
搜索必须在中心点 $k_c$ 选择 physical seed $\gamma_{m,c}$，再在不含 branch point 的
simply connected 区域中作 analytic continuation。例如在包含搜索 contour 的圆盘内用

$$
  \gamma_m(k)=\gamma_{m,c}
  \exp\!\left[
    \frac12\operatorname{Log}\!\left(1+\frac{k-k_c}{k_c-\beta_m}\right)
    +\frac12\operatorname{Log}\!\left(1+\frac{k-k_c}{k_c+\beta_m}\right)
  \right].
$$

圆盘半径小于 $k_c$ 到 $\pm\beta_m$ 的距离，并固定同一 logarithm branch。搜索域还必须
避开 $k=0$、Wood points、Hankel/QP Green branch cuts 和 BIE poles。不得在 contour
quadrature nodes 上分别重选 square-root branch。

## 6. Search actual complex zeros

实轴 $\sigma_{\min}$ scan 只产生候选 $k_c$。随后：

1. 取围绕 $k_c$ 的小型 pole-free complex contour，用 argument principle 或 Beyn
   moments 计算 root count；缩放 contour 后 count 必须稳定且等于 $1$；
2. contour 上 $\sigma_{\min}(F_{j,h})$ 必须与零分离；
3. 用 bordered implicit determinant 求根。固定 borders $b,c$，每一步解

   $$
     \begin{bmatrix}F_{j,h}(k)&b\\c^*&0\end{bmatrix}
     \begin{bmatrix}x(k)\\f(k)\end{bmatrix}
     =
     \begin{bmatrix}0\\1\end{bmatrix}.
   $$

   再以右端 $[-F_{j,h}'(k)x;0]$ 解出 $f'(k)$，并更新
   $k\leftarrow k-f(k)/f'(k)$；
4. 至少两个初值和一个 contour-moment 初值收敛到同一 complex root。

一般 complex matrix function 的零点有两个实自由度；不能只对一个实 $k$ 解两条独立
条件。即使物理目标应为实根，也先在复平面求解，再把
$|\operatorname{Im}k|$ 与 matrix evaluation、branch continuation 和 root-solve error
比较。若无法解释 imaginary part，只能报告 complex resonance candidate。

## 7. How $k_j$ is qualified

contour isolation 与 bordered solve 后，候选 $k_j$ 至少通过：

1. relative singular residual
   $\rho_j=\sigma_{\min}(F_j(k_j))/\lVert F_j(k_j) \rVert$ 到达预设线性代数容差；
2. projected Newton defect

   $$
     \nu_j=
     \left|
       \frac{y_j^*F_j(k_j)x_j}{y_j^*F_j'(k_j)x_j}
     \right|
   $$

   小于当前 DtN estimator 的固定比例；
3. $\lvert y_j^*F_j'(k_j)x_j \rvert$ 明确远离零；
4. 从两个初值启动的局部 solve 收敛到同一根；
5. second-smallest singular value 与 smallest singular value 明确分离；
6. contour count 为 $1$，bordered matrix 的 rcond 可接受；
7. derivative 包含 BIE、material wavenumber、Rayleigh phase 和 finite-tail map 的全部
   $k$ dependence；anchored centered differences 在步长 $s,s/2,s/4$ 上稳定；
8. 相邻层使用同一 branch chart，并以 center-field eigendirection overlap 匹配同一根；
9. $\lvert \operatorname{Im} k_j \rvert$ 与 matrix evaluation、branch 和求解误差相容；
10. center-field participation 不随 $j$ 消失，`A_QP` 与所有 Schur factors 不过度病态。

若这些条件失败，只能报告 singular-value minimum 和平台诊断，$\delta_j$、effectivity
和 “eigenvalue error estimator” 均标为 unavailable。

## 8. Structure-preserving cross-checks

- 比较 Dirichlet、一个冻结的 real Robin 和 zero-incoming 三种 half-guide map 是否随
  $j$ 趋向同一 QZ/Riccati map；它们不是三种独立 BIE 方法，但能暴露 termination error。
- 对 finite-level Dirichlet/Robin coupled problem 检查 root 的 imaginary part、离散
  self-adjoint defect 和左右 null-vector conditioning。
- reduced DtN/Schur eigenproblem 只在所有 elimination factors well-conditioned 时与
  augmented root 交叉核对。
- 只有先证明或数值核验一个正定、与 $j$ 无关的 weight $W$ 满足
  $WF_{j,h}(k)=F_{j,h}(k)^*W$，才可改用实轴 signed-eigenvalue/inertia search。普通
  $\sigma_{\min}$ 极小点不能替代该结构条件。
- 若 Dirichlet 与 real Robin 的根差在 $j$ 增加时不下降，不能声称已隔离 infinity
  truncation；应先检查 port truncation、termination resonance 和 map composition。
