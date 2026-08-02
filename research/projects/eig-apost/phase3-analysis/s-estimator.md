<!-- Analysis section: candidate estimators, diagnostics, and effectivity criteria -->

# Candidate estimator

适用前提：[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]] 已通过。
若当前点只是实轴 $\sigma_{\min}$ 极小点而不是 $F_j$ 的简单零点，本文件中的
eigenvalue correction 不可用。

## 1. Primary quantities

固定 $h$，记 $k_{j,h}$ 为 $F_{j,h}$ 的精确简单根，$k_{\infty,h}$ 为 exact half-guide
map 在同一离散空间中的根。取 unit-norm right/left null vectors $x_j,y_j$，并令

$$
  d_j:=y_j^*F_{j,h}'(k_{j,h})x_j\ne0.
$$

主 map correction 是

$$
  \delta_j^{\mathrm{map}}
  :=-
  \frac{
    y_j^*\bigl(F_{j+1,h}-F_{j,h}\bigr)(k_{j,h})x_j
  }{d_j},
  \qquad
  \eta_j:=\bigl|\delta_j^{\mathrm{map}}\bigr|.
$$

它的一阶目标是 signed increment $k_{j+1,h}-k_{j,h}$。若
$e_j:=k_{j,h}-k_{\infty,h}$ 且 $e_{j+1}=o(e_j)$，则
$\delta_j^{\mathrm{map}}\sim-e_j=k_{\infty,h}-k_{j,h}$。因此 $\eta_j$ 估计的是
coarse-level tail error $|k_{j,h}-k_{\infty,h}|$，不是 fine-level error
$|k_{j+1,h}-k_{\infty,h}|$。

实际 root solver 给出 $\widetilde k_{j,h}$ 时，令 $\widetilde x_j,\widetilde y_j$ 为该点的
近似 singular vectors，$\widetilde d_j=\widetilde y_j^*
F_{j,h}'(\widetilde k_{j,h})\widetilde x_j$，并分别计算

$$
\begin{aligned}
  \delta_j^{\mathrm{root}}
  &:=-\frac{\widetilde y_j^*F_{j,h}(\widetilde k_{j,h})\widetilde x_j}
             {\widetilde d_j},\\
  \delta_j^{\mathrm{map}}
  &:=-\frac{\widetilde y_j^*
    (F_{j+1,h}-F_{j,h})(\widetilde k_{j,h})\widetilde x_j}
    {\widetilde d_j},\\
  \delta_j^{\mathrm{tot}}
  &:=\delta_j^{\mathrm{root}}+\delta_j^{\mathrm{map}}
   =-\frac{\widetilde y_j^*F_{j+1,h}(\widetilde k_{j,h})\widetilde x_j}
            {\widetilde d_j}.
\end{aligned}
$$

$\delta_j^{\mathrm{tot}}$ 是 $k_{j+1,h}-\widetilde k_{j,h}$ 的一阶 predictor；若只研究
map truncation，则 root defect 必须远小于 $\eta_j$，否则不能把 map part 单独解释。

直接计算 matched root increment

$$
  a_j:=k_{j+1,h}-k_{j,h}
$$

并报告 linearization consistency

$$
  c_j:=\frac{|\delta_j^{\mathrm{map}}-a_j|}{|a_j|}.
$$

当 $|a_j|$ 已接近 root-solve 或 matrix-evaluation error 时不报告 $c_j$，避免除以噪声。

数值实现只需一次 coarse root solve 和一次 fine-map evaluation：

1. 求 $\widetilde k_{j,h}$ 及 $F_{j,h}(\widetilde k_{j,h})$ 的最小左右 singular vectors；
2. 在完全相同的 unknown ordering、scaling 和 branch chart 下，只把 tail blocks
   更新为 level $j+1$，计算
   $F_{j+1,h}(\widetilde k_{j,h})\widetilde x_j$；
3. 用已通过 step study 的 $\widetilde d_j$ 形成三个 corrections，并输出
   $\eta_j=|\delta_j^{\mathrm{map}}|$、root residual、slope、singular gap 和 conditioning；
4. 求 $k_{j+1,h}$ 不是 estimator 本身所必需，只在 validation 阶段用于计算 $c_j$。

## 2. Conditional asymptotic exactness

下述结论是 finite-dimensional simple-root perturbation argument，不是当前 BIE map 已经
满足的定理。假设在共同邻域 $U$ 中：

1. $F_{\infty,h}$ 与 $F_{j,h}$ analytic and regular，且 $F_{j,h}\to F_{\infty,h}$ in
   $C^1(U)$；
2. 对某个 $\varepsilon_j\to0$，
   $F_{j,h}-F_{\infty,h}=\varepsilon_jG+o(\varepsilon_j)$，并且
   $\varepsilon_{j+1}=o(\varepsilon_j)$；
3. $k_{\infty,h}$ 是 isolated simple root，
   $d_\infty=y_\infty^*F_{\infty,h}'(k_{\infty,h})x_\infty\ne0$；
4. leading projected coefficient
   $a=y_\infty^*G(k_{\infty,h})x_\infty\ne0$；
5. 全部 levels 使用同一 representation。

simple-root expansion 给出

$$
  k_{j,h}-k_{\infty,h}
  =-\varepsilon_j\frac{a}{d_\infty}+o(\varepsilon_j),
  \qquad
  \delta_j^{\mathrm{map}}
  =+\varepsilon_j\frac{a}{d_\infty}+o(\varepsilon_j).
$$

故

$$
  \frac{\eta_j}{|k_{j,h}-k_{\infty,h}|}\longrightarrow1.
$$

这是 $\eta_j$ 成为 asymptotically exact coarse-tail estimator 的充分条件。当前未证明
finite-tail BIE map 具有该 $C^1$ expansion，也未排除 leading coefficient cancellation。

## 3. Reliable interval requires an independent bound

令 $e_j=k_{j,h}-k_{\infty,h}$。若独立理论给出 saturation bound

$$
  |e_{j+1}|\le\bar q|e_j|,
  \qquad 0\le\bar q<1,
$$

并且 correction remainder 有可验证上界

$$
  |(k_{j+1,h}-k_{j,h})-\delta_j^{\mathrm{map}}|\le r_j,
$$

则严格得到

$$
  \boxed{
  \frac{\max(0,|\delta_j^{\mathrm{map}}|-r_j)}{1+\bar q}
  \le |k_{j,h}-k_{\infty,h}|
  \le
  \frac{|\delta_j^{\mathrm{map}}|+r_j}{1-\bar q}
  }.
$$

若 $\bar q$ 来自已证明的 map/root saturation 或可验证 stable-subspace bound，并且
$r_j$ 包含 nonlinear Taylor remainder、$F_{j+1,h}'-F_{j,h}'$、singular-vector error、
matrix evaluation error 和 root-solve error，才可把该区间称为 reliable。若用数值 roots
估计 $r_j$，必须加入各 root error 与 correction-evaluation error 的上界。

有限个 observed ratios

$$
  q_j^{\mathrm{obs}}
  :=\frac{|\delta_{j+1}^{\mathrm{map}}|}
          {|\delta_j^{\mathrm{map}}|}
$$

只作 asymptotic diagnostic，不能构造 certificate。一个精确反例是

$$
  F_j(k)=k-e_j,\qquad
  e_j=0.8^{2^j}\cos\!\left(2^j\frac{2178\pi}{10007}\right),\qquad
  k_{\infty}=0.
$$

其 projected correction 是 exact increment，但两个 observed ratios 可依次约为
$0.23775$ 和 $0.00660$，下一比率却约为 $1.02151$。因此有限个下降的 $q_j^{\mathrm{obs}}$
不能证明未来 contraction。只有 observed ratios 时，输出标签必须是
`conditional/empirical estimator`，不得输出 certified interval。

共同表示是 estimator 的必要条件。标量例
$F_j(k)=k-k_j$ 与 $\widetilde F_j(k)=\alpha_j(k-k_j)$ 有相同 roots，但后者的 projected
correction 等于

$$
  \widetilde\delta_j
  =\frac{\alpha_{j+1}}{\alpha_j}(k_{j+1}-k_j).
$$

所以 level-dependent scaling 会污染方向和量级；独立归一化 $x_j,y_j$ 的 complex phase
则在同一 projected quotient 中抵消，不构成问题。

## 4. Conditioning and auxiliary diagnostics

每个根同时报告：

- transverse slope $s_j=\lvert y_j^*F_j'(k_j)x_j \rvert$；
- unscaled condition proxy $1/s_j$，并注明矩阵与 basis scaling；
- $\sigma_{\min}(F_j(k_j))$；
- $\lVert \Lambda_{j+1}-\Lambda_j \rVert$；
- doubling Schur rcond、terminal-elimination rcond、`rcond(I+widehat R_j)` 和 cell BIE
  relative residual；
- relative singular residual、projected Newton defect 与 derivative step。

若 $s_j$ 很小，根对 DtN perturbation 高度敏感，较大的 $k$ error 可能与很小的 map
error 同时出现。这是 estimator 应揭示的信息，不应通过 rescaling 隐去；$1/s_j$ 只在
固定 representation 中作 transverse-slope proxy，不是 representation-invariant physical
condition number。

## 5. Effectivity against reference truth

reference 的独立性分级与可接受来源见
[[research/projects/eig-apost/phase3-analysis/p-benchmark|reference-truth ladder]]。

必须拆分 tail effectivity 与 total effectivity：

$$
\begin{aligned}
  \mathcal I_j^{\mathrm{tail}}
  &:=\frac{\eta_j}{|k_{j,h}-k_{\infty,h}^{\mathrm{ref}}|},\\
  \mathcal I_j^{\mathrm{total}}
  &:=\frac{\eta_j}{|k_{j,h}-k_*^{\mathrm{ref}}|}.
\end{aligned}
$$

$\mathcal I_j^{\mathrm{tail}}$ 检查 estimator 声称的 finite-tail error layer。
$\mathcal I_j^{\mathrm{total}}$ 只有在独立 refinement 表明
$|k_{\infty,h}-k_*|$ 明显小于 tail error 或另有控制时才有意义；否则不能用它评价
本 estimator。

首篇论文的最低成功标准：

1. $\delta_j^{\mathrm{map}}$ 对 next-level root shift 的方向和量级正确，且 $c_j$ 随
   $j$ 下降；
2. 至少三个代表性 simple guided modes 上，$\mathcal I_j^{\mathrm{tail}}$ 在渐近层级保持
   在 $[0.5,2]$，并趋向稳定常数；
3. effectivity 的好坏不能通过排除困难但仍满足预设范围的样本来改善；
4. reference uncertainty 必须小于被评价 error 的约 $10\%$，否则只报告区间或
   lower-confidence result。

$[0.5,2]$ 与 $10\%$ 是预注册式实验阈值，不是理论结论。若预试显示它们不现实，应在
正式数据生成前统一修改并记录理由。

## 6. Failure interpretations

- $\eta_j$ 准确预测 next-level shift，但没有独立 saturation/remainder bound：一阶 NEP
  correction 可作 conditional/empirical tail estimator，但不能报告 certified interval。
- map difference 小而 $\eta_j$ 大：目标根条件差，分母放大是物理/数值事实。
- $\delta_j^{\mathrm{map}}$ 与 root increment 不一致：未进入线性扰动区、左右向量不准、
  导数不准，或 $F_j$ 不在公共空间。
- $\sigma_{\min}$ 平台而 $k_j$ 稳定：平台可能由 common discretization floor 引起；需做
  `ntot` 和 port-order 反证测试。
- QZ/Riccati 与 doubling 不一致：infinity treatment 尚未可信，不进入 eigenvalue
  effectivity study。
- real-axis minimum 的 relative singular residual 或 projected Newton defect 不小：
  当前不是已确认的 NEP root，所有 eigenvalue-estimator quantities 标为 unavailable。
