<!-- Per-source evidence cards for BIE and DtN interfaces -->

# BIE-DtN interface evidence cards

状态：第一轮原文核验完成。不要把一般 bounded-domain Calderón 公式自动等同于
periodic half-guide DtN。

## Yuan--Lu--Antoine (2008): special-solution cell DtN

- **文献：** J. Yuan, Y. Y. Lu, X. Antoine, *Modeling Photonic Crystals by Boundary
  Integral Equations and Dirichlet-to-Neumann Maps*, J. Comput. Phys. 227(9),
  4617--4629, DOI `10.1016/j.jcp.2008.01.014`。
- **核验介质：** 作者主页全文已保存为 `ref/ref_data/Yuan2008.pdf`；PDF
  第 10--14、17 页已逐页视觉核验；正式元数据由 Elsevier 页面交叉核验。
- **“直接算”方式：** 选 $J$ 个满足单胞 Helmholtz/transmission 方程的特殊解
  $\phi_j$。在单胞外边界的 $J$ 个点采样其值组成 $U$，采样其法向导数组成 $Q$，
  直接以 $\Lambda_h=Q U^{-1}$ 得到离散 unit-cell DtN，见原文式 (32) 后的构造。
- **BIE 的位置：** 对任意截面 cylinder，以不同入射角的平面波激发同一穿透散射体；
  用 transmission BIE 解所有特殊解。BIE 矩阵只在 inclusion 边界离散，可复用一次
  LU 处理多右端；再在单胞边界评价 field/normal derivative。
- **离散：** 光滑 inclusion 用 kernel splitting 与 Nyström/trapezoidal quadrature；
  文中给出 single/double layer transmission system 及场和导数的 potential evaluation。
- **已知数值风险：** 全局特殊解矩阵 $U$ 在点数增大时会病态；论文对非圆截面只报告
  约 3--4 位有效数字，并明确指出过大的边界采样数会降低精度。
- **范围限制：** 这是有限 unit cell 的 DtN，不是 Fliss 半波导 DtN；它证明 BIE 可
  替代 FEM 生成单胞 DtN 数据，但仍需额外机制选择半无限方向的衰减分支。

## Lu--Lu (2014): Calderón/BIE operator quotient

- **文献：** W. Lu, Y. Y. Lu, *Efficient High Order Waveguide Mode Solvers Based on
  Boundary Integral Equations*, J. Comput. Phys. 272, 507--525,
  DOI `10.1016/j.jcp.2014.04.028`。
- **核验介质：** 作者主页全文与 Elsevier 正式页面；原文第 4--7 页公式由全文文本
  定位核验。
- **直接 DtN：** 对光滑有界齐次域，在作者的算子归一化与法向约定下，Calderón
  方程为 $(I+K)u=S \partial_n u$ 和 $(K'-I)\partial_n u=T u$，从而
  $\Lambda=(K'-I)^{-1}T$，$N=(I+K)^{-1}S$；$T$ 是 hypersingular operator。
- **例外与稳定性：** 公式要求避开相应 Dirichlet/Neumann 内部特征值；分片光滑边界
  还需 corner correction。本文发展了 hypersingular kernel splitting。
- **范围限制：** 这里的 DtN 是单个齐次子域共同边界上的 map；它不是周期半带 map，
  也不自动编码半波导的衰减/出射条件。

## Huang--Lu--Li (2007): line-defect PCW by merged cell DtN

- **文献：** Y. Huang, Y. Y. Lu, S. Li, *Analyzing Photonic Crystal Waveguides by
  Dirichlet-to-Neumann Maps*, J. Opt. Soc. Am. B 24(11), 2860--2867 (2007)。
- **核验介质：** 作者主页全文 `yuexia4.pdf`；关键定义、单胞合并、数值例子及结论已
  由全文页码核验。
- **方法：** 先用圆柱波直接构造普通/缺陷 elementary-cell DtN；通过消去内部边界
  trace 合并为 line-defect supercell DtN；再在 supercell 两端建立关于
  $\rho=\exp(\mathrm{i}\,\beta L)$ 的线性特征值问题。
- **与目标的接近程度：** 物理对象是二维光子晶体线缺陷 guided modes；但参数方向是
  固定频率求 $\beta$，而目标 RQ 是固定 $\beta$ 求 $k$。文中也采用有限宽 supercell，
  并非 Fliss 半波导 DtN。
- **可用参考数值：** 缺一排圆柱、$\varepsilon=10$、$r=0.375L$ 时，在
  $\omega L/(2 \pi c)=0.8$ 报告 $\beta L/(2 \pi)=0.3346$ 与 `0.2773`；后者用
  MIT Photonic-Bands 的加密 PWE 得到反向频率 `0.800`（三位有效数字）。另一个
  有限 slab 例在频率 `0.23` 报告四个 $\beta L$ 值。
- **限制：** 论文只宣称 3--4 位有效数字；不足以单独充当十位参考真值，但满足“至少
  一篇可靠文献给出相近数据”的最低 fallback。

## Petropoulos--Turc (2025): BIE cell RtR plus half-array Riccati

- **文献：** P. G. Petropoulos, C. Turc, *Domain Decomposition Multiple Scattering
  Solvers by Semi-Infinite and Infinite Arrays of Discrete Identical Scatterers in Two
  Dimensions*, Phil. Trans. R. Soc. A 383, 20240355,
  DOI `10.1098/rsta.2024.0355`。
- **核验介质：** Royal Society/NJIT 正式元数据、正式摘要与 indexed text。当前没有
  可合法下载的公开 PDF；方法架构由正式摘要直接支持，细节性数值精度只作次级线索。
- **方法：** 在带两个虚拟竖直壁的单胞上，用 layer potentials、boundary integral
  operators 与 Fourier/Sommerfeld 表示直接计算 unit-cell Robin-to-Robin map；随后
  通过 operator Riccati equation 得到半无限阵列 transmission maps。
- **验证线索：** indexed text 描述了大有限阵列 hierarchical Schur-complement 解和
  准周期 Green 函数 BIE 交叉比较；其中具体 digit claims 在取得可核验全文前不作为
  本项目接受阈值或 reference truth。
- **范围限制：** 当前论文处理自由空间中的声软 obstacles，而非穿透 dielectric
  inclusions、$\beta$-quasiperiodic strip 或 guided-mode eigenproblem。它是构造与验证
  架构的强近邻证据，不提供目标模型的现成定理。

## Yuan--Lu (2007): recursive doubling of DtN maps

- **文献：** L. Yuan, Y. Y. Lu, *A Recursive-Doubling Dirichlet-to-Neumann-Map
  Method for Periodic Waveguides*, J. Lightwave Technol. 25(11), 3649--3656,
  DOI `10.1109/JLT.2007.907742`。
- **核验介质：** 作者主页全文与 Optica/IEEE 元数据。
- **方法：** 将相邻有限段的 2-by-2 block DtN map 通过消去公共界面 trace 合并；
  周期结构按 $1,2,4,\ldots$ 单元递归倍增，成本随周期数为 $O(\log N)$。
- **作用：** 提供一个不解 stationary Riccati 方程的“大有限段趋近半无限端”数值路线，
  可作为未来 DtN reference sequence；但原文目标是有限周期散射且单段 map 由
  Chebyshev collocation 生成，不是本项目的 BIE 半波导结果。

## Ehrhardt--Sun--Zheng (2009): finite-tail StS sequence

- **文献：** M. Ehrhardt, J. Sun, C. Zheng, *Evaluation of Exact Boundary Mappings for
  One-Dimensional Semi-Infinite Periodic Arrays*, Commun. Math. Sci. 7, 347--364,
  DOI `10.4310/CMS.2009.v7.n2.a4`；本地全文 `ref/ref_data/Ehrhardt2009.pdf`。
- **核验介质：** 作者公开全文；PDF pp. 7--8、15 已逐页视觉核验，WIAS 书目页交叉
  核验期刊信息。
- **方法：** 对 $N$ 个周期胞元组成的有限尾端构造 Sommerfeld-to-Sommerfeld
  scattering blocks，并令远端 incoming Robin datum 为零。利用 block elimination 的
  doubling relations，$N=2^j$ 时只需 $j$ 次合并；在 stop band 中有限尾 reflection
  map 直接趋近半无限 exact StS map。
- **数值证据：** 原文以 $N=2^{20}$ 的 doubling 结果作 reference，Figure 3.1 展示
  finite-tail map 对 $N$ 的快速收敛；pass band 的 lossless limit 还需 absorption 与
  extrapolation，且 resonance 附近退化。
- **对本项目的用途：** 目标首阶段已限定 lead multipliers 远离单位圆，正适合把
  $N=2^j$ 选作“只改变非周期方向截断”的单一 DtN hierarchy。它给出 map sequence，
  但没有把 map error 转化为 guided eigenvalue error；后一步仍由 NEP perturbation
  formula 完成。

## 当前代码与上述文献的接口

- `bloch.construct_S` 已经用 `A_QP`、Rayleigh incident fields 和 BIE far-field
  extractors 构造一个周期 lead cell 的四个 scattering blocks。因而 `A_QP` 可继续
  作为 **single-cell scattering solve** 的组件，无需把它改名为 DtN。
- 固定 Rayleigh channel dimension 和 inclusion quadrature 后，可直接对这些 cell
  blocks 做 Redheffer/Schur doubling，形成 $N=2^j$ 个 cell 的 reflection map。该步骤
  不需要调用 `bloch.solve_modes` 或 outgoing trace-subspace selection。
- 对右半波导左端口，若代码约定 $D=a+b$、$N_x=\mathrm{i}\,\Gamma(a-b)$，且 $b=R_j a$，则

  $$
    \Lambda_j
    =\mathrm{i}\,\Gamma(I-R_j)(I+R_j)^{-1},
  $$

  前提是 $I+R_j$ 可逆。左半波导和中心域外法向需要单独核对符号。这个 Cayley
  transform 是从 scattering coordinate 恢复 DtN，不是从 trace-subspace 定义 DtN。
