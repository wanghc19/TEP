<!-- Analysis section: candidate estimators, diagnostics, and effectivity criteria -->

# Candidate estimator

适用前提：[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]] 已通过。
若当前点只是实轴 $\sigma_{\min}$ 极小点而不是 $F_j$ 的简单零点，本文件中的
eigenvalue correction 不可用。

## 1. Primary quantities

相邻 doubling 层 projected correction：

$$
  \eta_j:=|\delta_j|.
$$

它首先估计 $\lvert k_{j+1}-k_j \rvert$。若 tail error 对 cell count 指数衰减，而层级采用
$N_{j+1}=2N_j$，则下一层剩余误差应为当前层的高阶小量；此时 $\eta_j$ 也是到精确
half-guide root 的候选 asymptotically exact estimator。该升级必须由下节的 doubling
gate 和独立 reference 验证，不能只靠公式命名。

同时直接计算 root increment

$$
  d_j:=|k_{j+1}-k_j|
$$

并报告 linearization consistency

$$
  c_j:=\frac{|\delta_j-(k_{j+1}-k_j)|}{d_j}.
$$

当 $d_j$ 已接近舍入误差时不报告 $c_j$，避免除以噪声。

## 2. Doubling asymptotic gate

用下一层 correction 定义经验 separation ratio

$$
  q_j:=\frac{|\delta_{j+1}|}{|\delta_j|}.
$$

$N_j=2^j$ 时，主候选模型不是“对 $j$ 具有固定 contraction ratio”，而是预测
$q_j$ 随 $j$ 下降并趋向零。只有以下两层门都通过，才把 $\eta_j$ 从 next-step
predictor 升级为 remaining-error estimator：

1. $\delta_j$ 与实际 $k_{j+1}-k_j$ 一致，且 $c_j$ 下降；
2. 至少两个连续 $q_j<1$，整体下降，且 correction sign/phase 与单个 dominant tail
   contribution 相容。

首轮可把 $q_j\le 0.25$ 且 $q_{j+1}<q_j$ 作为“已进入 doubling asymptotic regime”的
provisional empirical gate；阈值必须在 screening 后、正式 effectivity 数据前一次性
冻结。若 gate 不通过，只报告 next-step prediction，不报告到 $k_*$ 的 estimator。

可附加报告 two-step signed correction $\lvert \delta_j+\delta_{j+1} \rvert$ 作为 tail diagnostic；
常比率模型的 $\lvert \delta_j \rvert/(1-q_j)$ 与 doubling 的超线性层级并不自然，不作为主结果。

## 3. Conditioning and auxiliary diagnostics

每个根同时报告：

- transverse slope $s_j=\lvert y_j^*F_j'(k_j)x_j \rvert$；
- unscaled condition proxy $1/s_j$，并注明矩阵与 basis scaling；
- $\sigma_{\min}(F_j(k_j))$；
- $\lVert \Lambda_{j+1}-\Lambda_j \rVert$；
- doubling Schur rcond、terminal-elimination rcond、`rcond(I+widehat R_j)` 和 cell BIE
  relative residual；
- relative singular residual、projected Newton defect 与 derivative step。

若 $s_j$ 很小，根对 DtN perturbation 高度敏感，较大的 $k$ error 可能与很小的 map
error 同时出现。这是 estimator 应揭示的信息，不应通过 rescaling 隐去。

## 4. Effectivity against reference truth

reference 的独立性分级与可接受来源见
[[research/projects/eig-apost/phase3-analysis/p-benchmark|reference-truth ladder]]。

对有独立 reference 的 case 定义

$$
  \mathcal I_j
  :=\frac{\eta_j}{|k_j-k_{\mathrm{ref}}|}.
$$

首篇论文的最低成功标准：

1. $\delta_j$ 对 next-level root shift 的方向和量级正确，且 $c_j$ 随 $j$ 下降；
2. 至少三个代表性 simple guided modes 上，$\mathcal I_j$ 在渐近层级保持在 $[0.5,2]$，并
   趋向稳定常数；
3. effectivity 的好坏不能通过排除困难但仍满足预设范围的样本来改善；
4. reference uncertainty 必须小于被评价 error 的约 $10\%$，否则只报告区间或
   lower-confidence result。

$[0.5,2]$ 与 $10\%$ 是预注册式实验阈值，不是理论结论。若预试显示它们不现实，应在
正式数据生成前统一修改并记录理由。

## 5. Failure interpretations

- $\eta_j$ 准确预测 next-level shift，但 doubling gate 失败：一阶 NEP correction 可用，
  但不能估计到精确 half-guide 的剩余误差。
- map difference 小而 $\eta_j$ 大：目标根条件差，分母放大是物理/数值事实。
- $\delta_j$ 与 root increment 不一致：未进入线性扰动区、左右向量不准、导数不准，
  或 $F_j$ 不在公共空间。
- $\sigma_{\min}$ 平台而 $k_j$ 稳定：平台可能由 common discretization floor 引起；需做
  `ntot` 和 port-order 反证测试。
- QZ/Riccati 与 doubling 不一致：infinity treatment 尚未可信，不进入 eigenvalue
  effectivity study。
- real-axis minimum 的 relative singular residual 或 projected Newton defect 不小：
  当前不是已确认的 NEP root，所有 eigenvalue-estimator quantities 标为 unavailable。
