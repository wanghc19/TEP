<!-- Publication route and theorem/experiment ladder -->

# Publication route

状态：研究路线设计；不构成创新性、正确性或可发表性的既成结论。

## 1. Candidate contribution

首篇论文的最聚焦候选贡献是：对 fixed-$\beta$、isolated simple guided mode，在固定
BIE/port discretization 下，以 self-adjoint finite-tail doubling 构造 half-guide DtN
层级，并用 nonlinear simple-root projected correction 给出 infinity-truncation
eigenvalue error 的 asymptotically quantitative estimator。

论文不把 BIE、DtN、doubling、奇异值扫描或一般 NEP perturbation 单独宣称为新。候选
新意只可能位于以下交叉处：

`BIE cell map -> structure-preserving half-guide truncation -> guided-mode NEP -> computable projected estimator -> independent-reference effectivity`。

其中 operator construction 与 estimator acceptance criteria 分别由
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]] 和
[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]] 具体化。

Phase 2b 已对该完整交叉给出 search-bounded `PASS WITH CONDITIONS`；正式冻结 novelty
claim 前仍须补齐 gate 列出的三篇全文，并在投稿前更新 forward citation search。详见
[[research/projects/eig-apost/phase2b-novelty/r-gate|Phase 2b novelty gate]]。

## 2. Theorem ladder to investigate

先在固定维数离散层面研究，避免把尚未证明的 BIE convergence 混入首个定理。

1. **Map convergence.** 在 cell transfer/scattering pencil 有稳定--不稳定谱分离、远端
   closure 与相应 invariant graph 横截时，证明 terminated reflection/DtN map 随 tail
   length $N$ 收敛到 stable half-guide map，并给出由 multiplier separation 控制的速率。
2. **Simple-root transfer.** 在 $F(k_*)$ 有孤立简单零点且
   $y^*F'(k_*)x \ne 0$ 时，把 DtN map perturbation 转成 $k_N-k_*$ 的一阶展开。
3. **Doubling estimator.** 若 leading tail term 非零且 $N_{j+1}=2N_j$，研究是否可得
   $\lvert k_{j+1}-k_* \rvert=o(\lvert k_j-k_* \rvert)$；若成立，则

   $$
     \frac{|\delta_j|}{|k_j-k_*|}\longrightarrow 1,
   $$

   其中 $\delta_j$ 是从 $F_{j+1}-F_j$ 计算的 projected correction。
4. **Inexact computation.** 给出 root residual、derivative difference、linear solve
   residual 和 map algebra error 必须小于主 correction 的哪些量级，才能保留上述
   asymptotic conclusion。

第 3 项是最有价值也最容易失败的理论环节。若只能证明 $O(1)$ effectivity 而不能趋近
$1$，仍满足当前用户目标；若连 $O(1)$ 都不能稳定得到，则降级为 indicator，不足以
支撑预定论文主张。

## 3. Why doubling changes the estimator model

定义 finite-tail root error

$$
  e_N:=k_N-k_*.
$$

若对 cell count 存在 leading expansion

$$
  e_N=C\theta^N+o(\theta^N),
  \qquad |\theta|<1,
$$

则 doubling 给出 $e_{2N}=o(e_N)$。因此相邻 root shift

$$
  k_{2N}-k_N=e_{2N}-e_N
$$

本身就渐近等于 $-e_N$。这比假定每个 $j$ 层具有固定 contraction ratio 更符合
$N_j=2^j$ 的层级。故首版以 $\eta_j=\lvert \delta_j \rvert$ 为 primary estimator；常比率的
$1/(1-q)$ tail correction 只保留为诊断，不作为核心理论模型。

## 4. Numerical evidence required

一篇有说服力的计算论文至少需要以下证据；具体实验矩阵与误差隔离规则见
[[research/projects/eig-apost/phase3-analysis/p-benchmark|benchmark plan]] 和
[[research/projects/eig-apost/phase3-analysis/s-errors|error budget]]：

1. map 层：Dirichlet/real-Robin/zero-incoming sequences 与 QZ/Riccati limit 一致；
2. root 层：每个 $k_j$ 是实际 simple zero，而非仅为 $\sigma_{\min}$ 极小点；
3. correction 层：$\delta_j$ 预测 $k_{j+1}-k_j$，linearization defect 下降；
4. truth 层：至少一个独立 FEM/supercell solver 与 BIE 路线给出相同 $k$ digits；
5. effectivity 层：多个代表性根上 $\eta_j/\lvert k_j-k_{\mathrm{ref}} \rvert$ 稳定为 $O(1)$，理想趋近 $1$；
6. falsification 层：固定饱和 DtN 后改变 BIE nodes，不出现用户指出的两位有效数字
   漂移或非单调恶化；
7. failure 层：至少保留一个接近 termination resonance、较弱 multiplier separation
   或较差 root conditioning 的失败/退化例。

## 5. Reference and publication gates

- **Gate P0:** 同一 geometry 上没有可信 $k_{\mathrm{ref}}$，不写 effectivity claim。
- **Gate P1:** 只有 shared-cell-map 的 doubling/QZ agreement，只能写 map validation。
- **Gate P2:** 加入 trace-subspace agreement，可写 partial cross-formulation evidence，
  不能称完全独立。
- **Gate P3:** 加入独立 FEM/supercell 或第二套独立高精度 solver 后，才进入完整论文
  数据生成。
- **Gate P4:** 理论 ladder 至少关闭 map convergence、simple-root transfer 和
  doubling estimator 的离散版本，才考虑向 `research/mainline/` 提升；提升仍需人工
  审核。

若停在 P2，可先形成方法报告或短篇 computational study；若达到 P3 但 T3 失败，可把
论文改成“conditioning-aware correction and diagnostics”，但必须降低 estimator 主张。

## 6. Provisional paper structure

1. fixed-$\beta$ guided-mode problem and exact half-guide DtN；
2. BIE cell scattering map and structure-preserving finite-tail DtN；
3. simple-root perturbation and doubling estimator；
4. implementation diagnostics and error budget；
5. two-ellipse benchmark, independent reference and effectivity；
6. failure regimes, cost and limitations。

当前不创建论文正文，也不把上述章节复制到冻结主线。
