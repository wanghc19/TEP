<!-- Analysis section: separated error budget for the DtN-first study -->

# Error budget

2026-08-13 路线复审后，本页的 finite-tail E4 分层保留为历史实例；现行 I2--I3 的共同主线
是 continuous real eigenvalue、discrete approximation、consistency/discretization error 与
posterior correction。finite Hermitian/reciprocity defect 不再作为实轴搜索许可门，而应与
root solve、linear algebra、evaluator 和跨层 discretization 分开记录。当前项目级误差定义以
[[research/projects/eig-apost/phase4-report/method.tex|continuous method]] 为准。

E4 的 operator construction 见
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]]；E7--E8
的通过条件分别见
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]] 与
[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]]。

## 1. Error sources

| 层级 | 误差源 | 可计算 diagnostic | 首轮处理 |
|---|---|---|---|
| E0 | 几何/材料与连续模型选择 | 参数表、clearance、projected gap | 冻结；不计入数值 estimator |
| E1 | exact DtN reduction/formulation | sign test、homogeneous/known case | 先验证等价与符号 |
| E2 | inclusion BIE/Kress quadrature | `ntot` sweep、BIE residual、block change | 首轮固定，随后反证测试 |
| E3 | QP Green/proxy/Rayleigh port discretization | proxy residual、`M`/proxy sweep、channel tail | 首轮固定在预检平台 |
| E4 | finite-tail approximation to half-guide DtN | closure comparison、$\Lambda_{j+1}-\Lambda_j$、transmission decay | **首轮目标误差** |
| E5 | doubling/terminal/Cayley linear algebra | Schur rcond、terminal rcond、$I+\widehat R_j$ rcond、solve residual | 设为远小于 E4 |
| E6 | fixed-$k$ matrix evaluation | repeated evaluation、determinism | 设为远小于 E4 |
| E6s | finite structure preservation | raw anti-Hermitian、reciprocity/Lagrangian defect、跨层变化 | 先作未校准 structure diagnostics/uncertainty components；不手工对称化，不作为实轴搜索许可门，换算 root error 仍需 refinement 与 slope |
| E7 | candidate numerical qualification | 原矩阵 residual、near-kernel separation、field/factor/boundary checks、repeatability | 登记 candidate credibility 和 uncertainty；不要求证明 exact finite root |
| E8 | first-order estimator remainder | correction-vs-next-root mismatch、tail ratio | 通过三层数据评价 |
| E9 | reference truth uncertainty | independent-method spread | 与 effectivity 一起报告 |

## 2. 首轮冻结表

只把 doubling depth $j$ 作为主 refinement parameter。下列量在一次 DtN study 中固定：

- $\beta$、bulk/defect ellipse、材料参数和 cell periods；
- bulk 与 defect inclusion 的 boundary nodes，provisional value 为 `ntot=120`；
- Rayleigh half-width、QP Green/proxy parameters 和 arithmetic precision；
- center formulation、matrix scaling、root scan/refinement rule；
- 远端 Dirichlet closure 及用于交叉检查的 real Robin parameter；
- linear solve tolerance 与 derivative finite-difference rule。

若任何冻结 diagnostic 随 $j$ 显著变化，说明误差没有被隔离，该组数据不得进入
effectivity table。

## 3. 误差隔离的定量要求

设当前 tail estimator 为 $\eta_j$。用于发表的样本至少应满足：

- projected Newton defect 小于 $0.05 \eta_j$，且 relative singular residual 到达预设
  线性代数容差；
- doubling、Cayley 和 BIE multi-RHS 的相对 solve residual 不主导 projected numerator；
- derivative step 改变一倍时，$\lvert y_j^*F_j'(k_j)x_j \rvert$ 的变化不超过目标 effectivity
  tolerance；
- terminal elimination、$I+\widehat R_j$ 与 doubling Schur factors 没有接近数值奇异；
  若接近则该点标为 method breakdown，不用更小 tolerance 掩盖。

常数 $0.05$ 是实验设计阈值，不是理论常数；Phase 3 数值预试后可以统一修订，但不能
逐例调节。

## 4. BIE 贡献的强制反证测试

在选定足够大的 $j_{\mathrm{ref}}$ 后，固定 DtN construction，只改变 inclusion boundary nodes，
至少测试 `60,80,100,120,150` 中几档可行值。

- 若 $k$ 的前两位有效数字发生变化，E2 必须提升为共同主误差源。
- 若加密后误差或 condition diagnostics 非单调增大，应检查 special-solution/Rayleigh
  basis conditioning、QP Green accuracy 和 scaling，不得继续声称 Kress error negligible。
- 只有当 `ntot` 变化远小于 DtN effectivity study 的目标误差，才能在首篇论文中把
  E2 作为 controlled background error。

## 5. 不能合并的量

- $\sigma_{\min}(F_j(k_j))$ 是矩阵近奇异 diagnostic，不是 E4 的误差估计。
- $\lVert \Lambda_{j+1}-\Lambda_j \rVert$ 是 map-level change，不含 eigenvalue sensitivity。
- $\lvert k_{j+1}-k_j \rvert$ 是相邻离散根差，不自动等于到极限的剩余误差。
- 实轴 $\sigma_{\min}$ 极小点不是自动存在的离散 NEP root；root qualification 失败时 E8
  没有定义。
- QZ/Riccati 与 doubling 的一致只排查 E4/E5，不排查共同的 E2/E3。
