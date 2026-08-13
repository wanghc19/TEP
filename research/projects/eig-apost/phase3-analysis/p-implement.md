<!-- Future implementation route; no MATLAB changes are authorized by this file -->

# Implementation route

状态：只读设计。当前未获授权修改 MATLAB；以下步骤用于后续单独实施任务。

2026-08-13 路线复审说明：本页的 finite-tail Stage A--D 是历史实施方案，不再构成当前
I2--I3 授权。现行顺序见
[[research/projects/eig-apost/implementation/ROADMAP|implementation ROADMAP]]：continuous
physical eigenvalue candidate $\to$ error sources $\to$ computable estimate $\to$ independent
truth validation/upper-bound feasibility。下面 Stage A--D 的 finite-tail、matching、derivative 和
complex protocol 均是历史或特定公式的条件方案，不得据此提前冻结 I2 之后的算法，也不得默认
启动 complex search。

## Stage A: map-only prototype

1. 复用 `bloch.construct_S`，不调用 `bloch.solve_modes`。
2. 新增纯线性代数的 scattering-map composition/doubling helper。
3. 对 homogeneous guide 或可解析 cell 检查 block order、energy/reciprocity diagnostics
   和 finite-tail convergence。
4. 实现远端 Dirichlet 与一个 real Robin 消元；zero-incoming 只作 map cross-check。
5. 从 terminated reflection maps 构造左右 DtN，核对所有 Schur/Cayley conditioning、
   normal signs 和离散 self-adjoint symmetry。

本阶段的 block convention、composition formula 与 DtN 定义以
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]] 为准。

成功条件：doubling 与 independent fixed-point/QZ result 在远离单位圆的测试点达到预设
tolerance；失败时不进入 guided-mode coupling。

## Stage B: center coupling

1. 为 $E_{\mathrm{defect}}$ 建立保留 BIE 的 center-cell formulation。
2. 明确 center boundary unknowns 与 port Dirichlet traces 的 ordering/scaling。
3. 把 center-port 与 far-port incoming/outgoing amplitudes 保留为 unknown，直接组装
   augmented $F_{j,h}(k)$；不先消去 terminal equations 或作 Cayley transform。
4. 核对 equation/unknown count，证明 augmented kernel 与 finite-tail guided field 等价，
   并排除 center representation nullspace 与 one-cell BIE poles 产生的伪根。
5. 用两个独立 sign tests 检查左右 port Cauchy convention；保留 reduced DtN 与现有
   trace-subspace code 只作 well-conditioned cross-check。

成功条件：相同 $j$、相同 port basis 下矩阵维数固定，$F_{j+1}-F_j$ 可直接形成。

## Stage C: root and estimator

1. 复用 I1/I2.1 已知窄区间与 count one，不重复 coarse real-axis scan。
2. 在原始未手工对称化矩阵上做 derivative-free bounded real-axis residual minimization；没有
   合法 signed scalar 时不称 sign bracket 或 bisection。
3. 从 SVD 取得 unit-norm $x_j,y_j$，检查左右 residual、second singular-value gap、
   border rcond、center participation 和 adjacent-level branch overlap。
4. 把 finite structure diagnostic、evaluator/linear-algebra error 与 candidate residual floor 分账；
   只有无法解释时才另行设计已隔离小圆盘内的 local complex refinement。
5. 对 $y_j^*F_{j,h}'(k_{j,h})x_j$ 做 $s,s/2,s/4$ derivative-step test，导数包含全部
   $k$ dependence。
6. 分别计算 $\delta_j^{\mathrm{root}}$、$\delta_j^{\mathrm{map}}$ 与
   $\delta_j^{\mathrm{tot}}$，再计算 matched $k_{j+1,h}$ 检查 signed first-order prediction。
7. root qualification 通过后可把
   $\eta_j=|\delta_j^{\mathrm{map}}|$ 报告为
   `conditional/empirical coarse-tail estimator`；只有独立得到
   $\bar q<1$ 与 correction remainder 上界时才输出 reliable interval。

两道 gate 的具体判据见
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]] 与
[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]]。

## Stage D: validation and reference

1. 运行 doubling/QZ-Riccati infinity cross-check。
2. 运行 DtN/trace-subspace whole-root internal cross-check。
3. 获得独立 FEM/supercell reference 或明确降级 reference status。
4. 固定 DtN 后运行 `ntot` falsification。
5. 运行 manufactured tests：实轴 singular-value dip 无实根、level-dependent scaling、
   nonnormal simple NEP、oscillatory false-$q$ gate、branch-crossing 和
   termination-localized state。
6. 分开报告 tail effectivity 与 total effectivity，并对数值 root/correction errors
   作 inflation。
7. 生成预注册表格，不手工删除失败点。

## Stop conditions

- 无法在筛选范围找到 isolated simple root；
- unit-circle separation 随合理 discretization 改变而消失；
- Schur/Cayley matrices 系统性病态；
- $\delta_j$ 不能预测 next-level root shift；
- 只能得到稳定的实轴 $\sigma_{\min}$ 极小点，不能确认 $F_j$ 的简单零点；
- contour root count 对 contour 缩放、branch chart 或 quadrature 不稳定；
- augmented kernel-equivalence 或 square regularity 无法建立；
- BIE `ntot` test 显示共同误差大于 DtN tail；
- reference uncertainty 与待估计误差同量级。

触发 stop condition 时应回到 formulation 与
[[research/projects/eig-apost/phase3-analysis/s-errors|error-budget analysis]]，不通过增加
scan density 或收紧线性 solver tolerance 掩盖。
