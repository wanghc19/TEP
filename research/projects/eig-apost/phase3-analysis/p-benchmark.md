<!-- Numerical benchmark and reference-truth plan -->

# Benchmark plan

## 1. Geometry family

目标几何是沿 $y$ 准周期、沿 $x$ 具有两个周期 half-leads 的 line-defect waveguide：

- 每个 ordinary bulk cell 含一个光滑、无旋转的 ellipse $E_{\mathrm{bulk}}$；
- 中心 defect cell 含另一个光滑、无旋转的 ellipse $E_{\mathrm{defect}}$；
- 两者中心先与 cell center 对齐，材料保持当前标量正介质模型；
- 两个 ellipse 的半轴不同，避免把 circle symmetry 当作普遍证据。

provisional screening seed 可取与当前 `radius=0.4` 尺度接近的
$E_{\mathrm{bulk}}=(0.40,0.30)$ 和 $E_{\mathrm{defect}}=(0.28,0.21)$；这些数字只用于寻找 projected gap
和 isolated root，不在筛选成功前冻结，也不得在看到 effectivity 后按结果调参。

## 2. Geometry screening is not validation

先用低成本 projected-gap scan 选择满足以下条件的一组 $\beta$ 与 $k$ 区间：

1. 无 Wood anomaly；
2. bulk Floquet multipliers 与单位圆有明确数值分离；
3. 只出现一个可稳定追踪的 simple guided-mode candidate；
4. inclusion 与 cell walls 有充足 clearance；
5. changing the coarse scan grid does not create/delete the candidate.

筛选完成后冻结 geometry、materials、$\beta$、candidate bracket 和所有 discretization
parameters，再生成正式 estimator 数据。筛选数据不计入 effectivity statistics。

## 3. DtN-only experiment

首轮 nominal inclusion discretization 取 `ntot=120`，理由是本地 all-Kress
`waveguide_1d` ellipse record 在该点数达到约 `8.6e-13` 的 $\sigma_{\min}$；这只是初始
工程选择，不是目标问题的误差证明。

对冻结 case 计算 $j=j_{\min},\ldots,j_{\max}$，其中 $N_j=2^j$。每层记录：

root diagnostics 与 estimator quantities 的定义和通过规则分别见
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]] 和
[[research/projects/eig-apost/phase3-analysis/s-estimator|candidate estimator]]。

- $k_j$, $\sigma_{\min}$, bracket width；
- $\delta_j$, $\eta_j$, doubling ratio $q_j$, $c_j$ 和 root-qualification diagnostics；
- DtN/map differences 与 conditioning diagnostics；
- cell BIE, QP Green/proxy 和 doubling residuals；
- evaluation count 与 wall-clock time。

正式 real-root sequence 采用远端 homogeneous Dirichlet closure；另选一个冻结的
real Robin closure 作结构保持交叉检查。zero-incoming finite-segment sequence 只比较
half-guide maps，除非另行求其复 eigenvalue，否则不进入实根 effectivity 表。

当 transmission blocks、root increments 或 map differences 到达共同 discretization
floor 时停止增加 $j$，不把舍入噪声误认为更高精度。

## 4. Reference-truth ladder

按可信度分层，不把同源结果写成完全独立：

1. **Infinity-treatment cross-check:** finite-tail doubling 与 stable QZ/Riccati fixed-point
   map 在同一 cell BIE discretization 上一致；Dirichlet、real Robin 与 zero-incoming
   maps 应趋向同一 limit。它只验证 half-guide map。
2. **Whole-eigenproblem internal cross-check:** DtN formulation 与现有 trace-subspace
   formulation 在固定 geometry 上给出相同 $k$ digits。两者共享 `A_QP/cell map`，只能
   算部分独立。
3. **Independent reference:** 独立 FEM/supercell 或另一套高精度 solver 对同一双椭圆
   case 给出相同有效数字。达到这一层才可把 $k_{\mathrm{ref}}$ 作为强 reference truth。
4. **Published fallback:** 复现 Huang--Lu--Li (2007) 的 circular line-defect data，
   只作为方法级外部 sanity check。它不是双椭圆 case 的同问题真值。

如果第 3 层暂时不可得，论文必须把双椭圆 reference 标为 internal high-resolution
reference，并降低主张；不能用相近但不同几何的 published number 替代同问题真值。

## 5. BIE falsification experiment

固定已经饱和的 $j_{\mathrm{ref}}$，只改变 bulk 与 defect ellipse 的 boundary nodes。至少报告：

- `ntot`；
- refined $k$；
- 相对最大分辨率的 digit agreement；
- BIE solve residual、QP Green/proxy diagnostic；
- estimator change。

若前两位有效数字浮动或加密后误差增大，暂停“DtN-dominant”主张，回到
[[research/projects/eig-apost/phase3-analysis/s-errors|E2/E3 联合误差分析]]。

## 6. Cost argument

本地 `draft.pdf` Table 4 的全 band scan 有 `27525` 次 $(k,\beta)$ evaluations。正式
estimator 只在少数已定位 roots 附近增加相邻 DtN levels 和 derivative evaluations，
预计每个 root 为几十到几百次 evaluations。实验必须实际报告增量成本，不能只用
渐近符号声称便宜。

## 7. Minimum publishable table set

1. geometry/material/normalization table；
2. projected-gap 与 simple-root diagnostics；
3. DtN level convergence and conditioning table；
4. root qualification and correction-vs-next-root table；
5. independent-reference effectivity table；
6. fixed-DtN `ntot` falsification table；
7. cost breakdown and failure cases。
