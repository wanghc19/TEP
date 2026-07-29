<!-- Future implementation route; no MATLAB changes are authorized by this file -->

# Implementation route

状态：只读设计。当前未获授权修改 MATLAB；以下步骤用于后续单独实施任务。

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
3. 组装 $F_j(k)$，并用两个独立 sign tests 检查左右 DtN。
4. 保留现有 trace-subspace code 只作 cross-check，不复制其 definition。

成功条件：相同 $j$、相同 port basis 下矩阵维数固定，$F_{j+1}-F_j$ 可直接形成。

## Stage C: root and estimator

1. 用 coarse scan 只定位候选；局部 nonlinear singularity solve 求实际 $k_j$，不得把
   $\sigma_{\min}$ 极小点直接当根。
2. 从 SVD 取得 unit-norm $x_j,y_j$。
3. 对 $y_j^*F_j'(k_j)x_j$ 做 derivative-step convergence test。
4. 计算 $\delta_j$，再计算实际 $k_{j+1}$ 检查 first-order prediction。
5. 只有 root qualification 与 doubling gate 都通过，才把 $\eta_j=\lvert \delta_j \rvert$ 报告为
   remaining-error estimator。

两道 gate 的具体判据见
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]] 与
[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]]。

## Stage D: validation and reference

1. 运行 doubling/QZ-Riccati infinity cross-check。
2. 运行 DtN/trace-subspace whole-root internal cross-check。
3. 获得独立 FEM/supercell reference 或明确降级 reference status。
4. 固定 DtN 后运行 `ntot` falsification。
5. 生成预注册表格，不手工删除失败点。

## Stop conditions

- 无法在筛选范围找到 isolated simple root；
- unit-circle separation 随合理 discretization 改变而消失；
- Schur/Cayley matrices 系统性病态；
- $\delta_j$ 不能预测 next-level root shift；
- 只能得到稳定的实轴 $\sigma_{\min}$ 极小点，不能确认 $F_j$ 的简单零点；
- BIE `ntot` test 显示共同误差大于 DtN tail；
- reference uncertainty 与待估计误差同量级。

触发 stop condition 时应回到 formulation 与
[[research/projects/eig-apost/phase3-analysis/s-errors|error-budget analysis]]，不通过增加
scan density 或收紧线性 solver tolerance 掩盖。
