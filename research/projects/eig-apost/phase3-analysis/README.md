# Phase 3：I3.1 连续物理残量路线

本目录先研究 I2 实际保存的 numerical candidate $\widehat k_h$ 到当前 continuous projected
gap 内正离散特征频率集合的距离

$$
e_h^{\mathrm{gap}}
=\operatorname{dist}\bigl(\widehat k_h,
\mathcal K_{\mathrm{disc}}(A;G_\lambda)\bigr),
$$

其中 $G_\lambda\subset(0,\infty)$ 是需要针对当前模型认证的 continuous projected essential
gap，且
$\mathcal K_{\mathrm{disc}}(A;G_\lambda)
=\{\sqrt{\lambda}:\lambda\in\sigma_{\mathrm{disc}}(A)\cap G_\lambda\}$。
只有确需跟踪特定 mode 时，才升级到 $e_h^*=|k_*-\widehat k_h|$。

I3.1 的主线必须直接服务这个误差。有限矩阵的精确零点、连续 score minimizer 和相邻有限层
零点位移都不是项目最终交付物；只有当它们确实进入上述连续谱误差的估计时，才可作为辅助量。

## 当前路线

本轮撤下 finite one-step projected-root correction 的主线地位。即使其有限维扰动公式完全
成立，它也只预测 saved candidate 到某个有限矩阵零点、或相邻 projected finite family
零点之间的位移，不能控制两个离散层共有的偏差。I2.3 已直接比较算法保存的 candidates，
所以继续把该有限根位移作为 I3.1 的前置对象会重复有限层内部问题。

一般的最短路线是：

1. 取 I2 已保存的 $\widehat k_h$，令 $\mu_h=\widehat k_h^2$；
2. 从 I2 的边界密度、Fourier 系数和物理采样场构造非零的连续能量空间场
   $u_h^{\mathrm c}$；
3. 在连续自伴算子的弱形式中计算 $u_h^{\mathrm c}$ 在参数 $\mu_h$ 处的残量泛函；
4. 用该残量在能量空间对偶范数中的大小构造可计算指标；
5. 若可靠 residual interval 完全位于当前连续算子的 projected essential gap，则先得到区间内
   至少存在一个连续离散特征值；只有区间宽度不超过看结果前冻结的频率分辨率，才接受为
   第一层分辨率级结论；
6. I3.2 再用独立 reference 检查这个冻结指标是否跟踪误差；若未来确需指定某个 mode，才
   另做唯一目标识别，I3.3 再研究严格误差上界。

连续弱残量只要求重构场属于连续问题的能量空间。一般情况下，要求场属于强算子的定义域会
更苛刻；但当前模型的 homogeneous empty center column 提供了一个可立即检查的特殊情形。
首个冻结实验把该空列中的有限 Fourier 场乘以固定
$\chi(x)=\cos^2(\pi x)$ 并在单胞外延零，由于 $\chi=\chi'=0$ 于端点，得到的场属于强算子
定义域。因而 `center-a1` 可以直接计算 continuous strong residual，而无需先完成一般 lead-field
repair 或 Riesz dual-norm solve。

该 baseline 得到 computed ratio $22.43882099031153$。普通 Simpson 加密稳定，但没有给出可靠
积分 enclosure；更重要的是，固定单胞 cutoff 的导数项主导 residual，名义区间跨过零并远宽于
预注册频率分辨率。因此它是一个有效的 `FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT` 负结果，
不是可移交 I3.2 的 estimator。下一项 I3.1 研究应减少 cutoff defect 或回到一般 weak-residual
路线，而不是先认证同一个过宽区间。

## 阅读顺序

1. [[research/projects/eig-apost/phase3-analysis/s-estimator|Continuous residual estimator theory]]：
   连续弱残量、谱距离命题、gap 内存在性、预注册分辨率与可选唯一目标识别；
2. [[research/projects/eig-apost/phase3-analysis/s-dtn-chain|Field reconstruction and residual chain]]：
   从 I2 数据到连续或分片连续场，以及 residual 各组成项；
3. [[research/projects/eig-apost/phase3-analysis/s-root|Existence and target identification]]：
   saved candidate、可靠谱区间、gap 内离散特征值和指定目标的区别；
4. [[research/projects/eig-apost/phase3-analysis/s-errors|Coverage and omitted errors]]：
   residual 覆盖、数值近似和遗漏项；
5. [[research/projects/eig-apost/phase3-analysis/p-implement|Design readiness]]：进入
   `design-3-1.md` 前真正需要关闭的最小条件。

`p-benchmark.md` 属于 I3.2 的独立 reference 问题，`p-paper.md` 属于结果形成后的写作问题。
它们不得参与 I3.1 公式选择和调节。

## OPTIONAL finite-matrix diagnostics

原有限维一步公式仍可用于两个局部问题：saved grid candidate 到附近有限矩阵零点的位移，
以及某一离散加密对有限矩阵零点的一阶影响。它需要共同空间、附近简单零点、左右向量、
完整 $k$ 导数和非零横截斜率。只有实际启用该诊断时，这些条件才成为其局部门槛。

该诊断不得称为 continuous-eigenvalue error estimator，不得阻止 continuous-residual 主线，也不得成为
`design-3-1.md` 的 readiness gate。

## 当前状态

- 理论方向：`CONTINUOUS RESIDUAL MAINLINE`；
- 已闭合：残量到某个连续谱点距离的抽象自伴谱命题；中心空列 compact-support 强残量
  baseline 的连续定义域和残量公式；
- 已完成实验：[[research/projects/eig-apost/implementation/i3/design-3-1|design-3-1]] 的
  `center-a1`，独立结论见
  [[research/projects/eig-apost/implementation/i3/review-3-1|review-3-1]]；
- 未闭合：一个同时保持 continuous conformity 且具有项目分辨率的 reconstruction/residual
  indicator；普通 quadrature 的 reliable enclosure；当前 sharp-disk continuous projected gap；
- 第一层目标：可靠区间进入 projected gap，且其正频率宽度不超过预注册分辨率；
- 第二层可选升级：只有确需命名某个 mode 时才证明唯一目标身份；
- I3.1 当前状态：`CENTER STRONG-RESIDUAL BASELINE COMPLETE / RESOLUTION INSUFFICIENT`；
- I3.2：尚不可开始；须先得到有用分辨率的冻结 estimator candidate。
