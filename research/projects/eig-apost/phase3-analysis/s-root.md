<!-- Analysis section: distinction between a real-axis singular-value minimum and an NEP root -->

# Root qualification

状态：Phase 3 风险审计；以下是 estimator 使用条件和数值协议，不是已证明结论。

## 1. Three objects must remain distinct

固定 $\beta$ 后，必须区分：

1. 实轴 coarse scan 给出的 $\sigma_{\min}(F_j(k))$ 局部极小点；
2. 近似 nonlinear operator $F_j(k)$ 的实际简单零点 $k_j$；
3. 精确 half-guide DtN operator $F(k)$ 的目标零点 $k_*$。

第 1 项只负责定位第 2 项。若 $\sigma_{\min}$ 在 `1e-3--1e-5` 形成平台，第 1 项完全可能
不是第 2 项；此时不能把 simple-root perturbation formula 用在该点，也不能把平台高度
解释成 $\lvert k_j-k_* \rvert$。

## 2. Why the remote closure matters

对 $N_j=2^j$ 个 cell 的 finite segment，直接令远端 incoming scattering amplitude 为零，
等价于让有限段继续向一个人工外部介质辐射。这个 finite-level map 可以收敛到半无限
periodic tail，但有限 $j$ 的中心耦合一般不是自伴有界 eigenproblem；其真正零点可能
离开实轴。若仍只在实轴扫描，得到的通常只是一个 singular-value minimum。

因此，首版实 $k$ estimator 采用结构保持的 finite-tail closure：远端施加齐次
Dirichlet，或预先冻结的 real Robin condition。zero-incoming sequence 只用于
half-guide map 交叉验证；若未来以它产生 eigenvalue sequence，则必须求复 $k$ 零点并
把问题改写成 resonance-style validation，不能沿用首版实根协议。

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

## 4. How $k_j$ is qualified

coarse scan 后，首版采用局部 nonlinear singularity solve，而不是继续无限加密实轴
grid。候选 $k_j$ 至少通过：

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
5. 允许复 $k$ 作审计时，$\lvert \operatorname{Im} k_j \rvert$ 与离散/求解容差相容。

若这些条件失败，只能报告 singular-value minimum 和平台诊断，$\delta_j$、effectivity
和 “eigenvalue error estimator” 均标为 unavailable。

## 5. Structure-preserving cross-checks

- 比较 Dirichlet、一个冻结的 real Robin 和 zero-incoming 三种 half-guide map 是否随
  $j$ 趋向同一 QZ/Riccati map；它们不是三种独立 BIE 方法，但能暴露 termination error。
- 对 finite-level Dirichlet/Robin coupled problem 检查 root 的 imaginary part、离散
  self-adjoint defect 和左右 null-vector conditioning。
- 若 Dirichlet 与 real Robin 的根差在 $j$ 增加时不下降，不能声称已隔离 infinity
  truncation；应先检查 port truncation、termination resonance 和 map composition。
