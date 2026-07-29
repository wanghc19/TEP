<!-- Evidence review: nonlinear eigenvalue perturbation and computable error estimators -->

# Nonlinear eigenvalue error evidence

状态：原文核验完成到足以确定首版 estimator 的数学骨架；尚未证明它适用于当前
BIE--DtN 离散，也尚未得到 remainder 的可计算上界。

## 1. 本专题所需的最小记号

固定 $\beta$。令 $F(k)$ 表示使用精确半波导 DtN 后得到的 guided-mode operator
function，令 $F_l(k)$ 表示只在 DtN 构造层级 $l$ 上近似、其余离散暂时固定后的
operator function。若不同层级改变矩阵维数，必须先给出公共 trace space 或明确的
prolongation；否则下面的矩阵差 $F_{l+1}-F_l$ 没有定义。

记 $k_*$ 为 $F$ 的孤立简单零点，$k_l$ 为 $F_l$ 的对应简单零点。右、左零向量分别
记为 $x$ 和 $y$，即

$$
  F(k_*)x=0,
  \qquad
  y^*F(k_*)=0.
$$

简单性要求的关键横截条件是

$$
  y^*F'(k_*)x\ne 0.
$$

只保留 $F$、$F_l$、$k_*$、$k_l$、$x$、$y$，不另设“残差算子”别名。

## 2. Güttel--Tisseur (2017): finite-dimensional first-order bridge

- **来源：** *The Nonlinear Eigenvalue Problem*, Acta Numerica 26,
  DOI `10.1017/S0962492917000034`；本地全文 `ref/ref_data/Guettel2017.pdf`。
- **原文定位：** PDF pp. 21--24，尤其 Theorem 2.20、式 (2.22)--(2.26)。
- **直接支持：** 对简单非线性特征值，扰动 $\Delta F$ 导致的第一阶位移满足

  $$
    \Delta k
    =-
    \frac{y^*\Delta F(k_*)x}{y^*F'(k_*)x}
    +O(\lVert\Delta F\rVert^2).
  $$

  因而左右零向量投影给出“该误差源真正耦合到目标根的分量”，分母给出根对
  $k$ 的横截斜率。原文还把 residual/backward error 与 forward sensitivity 明确
  分开：小 residual 只有结合 condition number 才能解释为小 eigenvalue error。
- **对本项目的限制：** 该结果直接针对 analytic matrix-valued function；从连续
  BIE--DtN operator 到有限矩阵仍需一致性、稳定性和公共离散空间论证。

## 3. Moskow (2015): operator-level nonlinear eigenvalue correction

- **来源：** *Nonlinear Eigenvalue Approximation for Compact Operators*, Journal of
  Mathematical Physics 56, 113512, DOI `10.1063/1.4936304`；本地全文
  `ref/ref_data/Moskow2015.pdf`。
- **原文定位：** Theorem 4.1 与 Corollary 4.1。
- **直接支持：** 对 analytic compact operator families，在 collectively compact、
  primal/adjoint convergence 和 simple-eigenvalue 非退化条件下，近似 eigenvalue
  有显式一阶 correction；remainder 是 primal 与 adjoint operator errors 的乘积阶。
- **意义：** 这提供了从 matrix formula 回到 operator approximation 的理论模板，且
  与电磁 transmission eigenvalue 的非自伴情形相容。
- **限制：** 当前 guided-mode BIE--DtN function 尚未被写成该文的 compact form，
  collective compactness 和 adjoint approximation 也未验证；不能直接引用其
  corollary 作为本专题定理。

## 4. Bindel--Hood (2013): localization rather than sharp estimation

- **来源：** *Localization Theorems for Nonlinear Eigenvalue Problems*, SIAM Journal on
  Matrix Analysis and Applications 34, 1728--1749, DOI `10.1137/130913651`；本地全文
  `ref/ref_data/Bindel2013.pdf`。
- **直接支持：** analytic matrix-valued functions 可用 nonlinear pseudospectra、
  generalized Gershgorin/Bauer--Fike 型结果定位 eigenvalues，并以 contour 上的
  nonsingularity 保持根计数。
- **用途：** 后续可把它作为“候选根附近是否只有一个根”的独立诊断或较宽的
  localization certificate。
- **限制：** 它不是当前首选的量级 estimator；直接使用通常会比 projected
  first-order correction 更宽。

## 5. Zhang (2023): DtN truncation可呈指数收敛，但对象不同

- **来源：** *A Spectral Decomposition Method to Approximate Dirichlet-to-Neumann Maps
  in Complicated Waveguides*, SIAM Journal on Numerical Analysis 61, 1195--1217,
  DOI `10.1137/22M1485425`；本地全文 `ref/ref_data/Zhang2023.pdf`。
- **原文定位：** DtN spectral truncation、Theorem 14 和最终总误差式 (38)。
- **直接支持：** 在其 radiation-condition 和 regularity 假设下，截断 evanescent
  generalized eigenfunctions 得到的 DtN approximation 指数收敛；数值总误差被分成
  FEM、spectral discretization 和 modal truncation 三项。
- **限制：** 该文研究 forced scattering 与 spectral-decomposition DtN，不是
  fixed-$\beta$ guided eigenvalue，也不是 Riccati/BIE DtN。它只支持“远离中性谱时
  几何/指数 tail model 有文献先例”，不能替代本项目自己的 convergence audit。

## 6. 首版可计算量的正确解释

在同一个离散 trace space 上，先计算 $F_l(k_l)$ 的近似左右零向量 $x_l,y_l$。定义
相邻 DtN 层级导致的 projected correction

$$
  \delta_l
  :=-
  \frac{
    y_l^*\bigl(F_{l+1}(k_l)-F_l(k_l)\bigr)x_l
  }{
    y_l^*F_l'(k_l)x_l
  }.
$$

它的第一含义是预测 $k_{l+1}-k_l$，不是自动预测完整的 $k_*-k_l$。只有在另外验证
DtN hierarchy 已进入渐近区、剩余误差满足稳定的 tail model 后，才可把它升级为
真实误差 estimator。

若连续三个层级给出稳定的增量比

$$
  \widehat q_l
  :=\frac{|\delta_{l+1}|}{|\delta_l|}<1,
$$

则可把 $\lvert \delta_l \rvert/(1-\widehat q_l)$ 作为 geometric-tail 的经验估计。这个分母修正依赖
饱和/几何收敛假设；未验证该假设时必须只报告相邻层 correction。

Phase 3 选定 $N_j=2^j$ 的 finite-tail doubling 后，固定 contraction-ratio 模型已降为
备选诊断：若 tail error 对 cell count 指数衰减，层级比率应随 $j$ 下降，而非趋向固定
常数。当前 primary candidate 已改为 $\lvert \delta_j \rvert$ 本身，并增加 root qualification 与
doubling separation gates；见 `phase3-analysis/s-root.md` 和 `s-estimator.md`。本节保留
原始 Phase 2 推理以记录方法选择的演化，不代表当前采用 $1/(1-\widehat q_l)$。

## 7. 什么程度才算“有说服力”

本专题不以 certified upper bound 为首要目标。按强度从低到高区分：

1. **Indicator：** 与误差相关，但不承诺量级；不足以满足当前 RQ。
2. **Asymptotically quantitative estimator：** effectivity
   $\eta_l/\lvert k_l-k_{\mathrm{ref}} \rvert$ 在多组 benchmark 上保持 $O(1)$，并在 DtN refinement 下趋近
   稳定常数，理想情况下趋近 $1$。这是首篇论文应争取的最低主目标。
3. **Reliable/efficient bound：** 证明 estimator 在显式常数下给出上下界；最强但
   可能过宽，当前不作为首要交付。

因此，首版论文的说服力应来自“一阶公式 + remainder 的渐近解释 + 独立 reference
truth 上的 effectivity study”，而不是把最小奇异值或两级差直接改名为 estimator。

## 8. 对 $\sigma_{\min}$ 平台的解释边界

当零奇异值简单且 $k$ 为实参数时，$\sigma_{\min}(F(k))$ 在根附近的首阶斜率与
$\lvert y^*F'(k_*)x \rvert$ 相关。因此相同的 $\sigma_{\min}$ 可对应非常不同的 $k$ 误差，取决于
横截斜率、矩阵 scaling 和非正规性。当前 `1e-3--1e-5` 平台只能说明离散矩阵没有
更接近奇异；它既不能证明 $k$ 只有 `1e-3--1e-5` 精度，也不能证明根是伪根。

## 9. 尚待关闭的理论缺口

- 选择一个明确的 DtN hierarchy $l$：finite-tail length、doubling depth、port order
  或 Riccati tolerance 不能混成一个参数。
- 证明或数值验证 $F_l$ 在目标根邻域对 $F$ 的一致收敛，并控制 $F_l'$。
- 说明左右零向量在 BIE density scaling、port basis scaling 下如何归一化；检查
  projected correction 对合法 basis change 的不变性。
- 给出可计算 remainder 或至少可反驳的 asymptotic-regime test。
- 将 DtN contribution 与扫描定位、BIE quadrature 和线性代数误差分别记录。
