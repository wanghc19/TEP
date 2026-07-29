# Phase 2b source verification

状态：核心来源核验完成。本文区分 `local original verified`、出版社原文核验和
摘要/元数据级核验；只有原文级证据用于否定某篇来源是否包含 estimator、proof 或
effectivity。

## 1. 精确物理对象与透明边界基线

### Fliss (2013)

S. Fliss, “A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes
in Photonic Crystal Waveguides,” *SIAM Journal on Scientific Computing* 35(2),
B438--B461 (2013), [DOI](https://doi.org/10.1137/12086697X).

- 身份与证据：[[ref/ref_data/Fliss2013.pdf|Fliss2013.pdf]] 原文已核验。
- 原文边界：固定传播方向准周期参数后，定义左右半波导 Dirichlet problem 与 DtN，
  将线缺陷 guided-mode 问题约化为 defect strip 上的非线性特征值问题；半波导 DtN
  由胞元问题与 Riccati/传播算子构造。
- 门控意义：C1 已被覆盖，C2--C3 的非 BIE 版本已有基线；该文没有数值 DtN 误差到
  特征值偏移的可计算后验 estimator 或 effectivity。

### Fliss--Klindworth--Schmidt (2015) 与 Klindworth (2015)

S. Fliss, D. Klindworth, and K. Schmidt, “Robin-to-Robin Transparent Boundary
Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides,”
*BIT Numerical Mathematics* 55, 81--115 (2015),
[DOI](https://doi.org/10.1007/s10543-014-0521-1); D. Klindworth,
*On the Numerical Computation of Photonic Crystal Waveguide Band Structures*, doctoral
thesis, TU Berlin (2015), [DOI](https://doi.org/10.14279/depositonce-4917).

- 身份与证据：[[ref/ref_data/Fliss2015.pdf|Fliss2015.pdf]] 与
  [[ref/ref_data/Klindworth2015.pdf|Klindworth2015.pdf]] 题名页和全文已核验。
- 原文定位：Fliss et al. pp. 25--31 给出 fixed-$k$ 搜索 $\omega$ 的 DtN/RtR NEP、
  quasi-Newton 与 Chebyshev 数值比较；其“error in frequency”来自与更细计算的比较，
  不是后验界或 estimator。Klindworth thesis Chapter 6--7 给出 DtN/RtR 的高阶 FEM
  离散、导数、Newton/path-following 与 supercell 对照；PDF pp. 102--104 以 $p=20$
  或 DtN 解作 reference；PDF p. 153 明确指出 DtN/RtR 透明边界的数值分析尚未完成，
  离散非线性特征值问题的标准渐近收敛仍缺严格证明。
- 门控意义：不能把“DtN/RtR 求 fixed-$\beta$ line-defect guided mode”“导数驱动的
  Newton”或“高精度色散曲线”作为创新。论文机会必须落在尚未给出的 numerical-DtN
  error estimator 与 effectivity，而不是求解器本身。

## 2. BIE 与半无限周期尾部近邻

### Li--Lu (2007)

S. Li and Y. Y. Lu, “Computing Photonic Crystal Defect Modes by Dirichlet-to-Neumann
Maps,” *Optics Express* 15(22), 14454--14466 (2007),
[DOI](https://doi.org/10.1364/OE.15.014454).

- 身份与证据：[[ref/ref_data/Li2007.pdf|Li2007.pdf]] 原文已核验。
- 原文边界：用 special solutions 构造 cell DtN，有限 rings 外边界取零 Dirichlet，
  消元得到 $B(\omega)$；以 $\sigma_{\min}$ 搜索并用 $N=16$、$p=12$ 结果作数值参考。
- 门控意义：覆盖 point-defect DtN NEP、奇异值定位和截断层数 convergence study；
  不提供单次结果的 computable truncation estimator 或 effectivity。

### Yu--Hu--Lu--Rathsfeld (2022) 与 Petropoulos--Turc (2025)

X. Yu, G. Hu, W. Lu, and A. Rathsfeld, “PML and High-Accuracy Boundary Integral
Equation Solver for Wave Scattering by a Locally Defected Periodic Surface,” *SIAM
Journal on Numerical Analysis* 60(5), 2592--2625 (2022),
[DOI](https://doi.org/10.1137/21M1439705); P. G. Petropoulos and C. Turc,
“Domain Decomposition Multiple Scattering Solvers for Two-Dimensional Semi-Infinite
Periodic Arrays,” *Philosophical Transactions of the Royal Society A* (2025),
[DOI](https://doi.org/10.1098/rsta.2024.0355).

- 身份与证据：[[ref/ref_data/Yu2022.pdf|Yu2022.pdf]] 原文已核验；Petropoulos--Turc 的 DOI、
  publisher primary text 与机构元数据已核验。
- 原文边界：Yu et al. 用 BIE 计算 unit-cell NtD，定义 semi-waveguide NtD 与
  marching operator，并以 Riccati/recursive doubling 计算；Petropoulos--Turc 给出
  BIE RtR + half-array Riccati 的相近 scattering 架构。
- 门控意义：C2--C3 的工程链已有直接先例，但两者均是 scattering；没有 fixed-$\beta$
  guided eigenvalue shift estimator。

## 3. Guided eigenvalue domain-truncation error

### Bonnet-Ben Dhia--Gmati (1995)

A.-S. Bonnet-Ben Dhia and N. Gmati, “Spectral Approximation of a Boundary
Condition for an Eigenvalue Problem,” *SIAM Journal on Numerical Analysis*
32(4), 1263--1279 (1995), [DOI](https://doi.org/10.1137/0732058).

- 身份与证据：[[ref/ref_data/Bonnet1995.pdf|Bonnet1995.pdf]] 的题名页、正文与 DOI 已核验。
- 原文定位：PDF pp. 1--6 把均匀包层光纤的全平面导模问题等价约化到圆形有界域，
  exact boundary operator 由全部 Fourier modes 构成；数值半离散只保留
  $|p|\leq N$。PDF p. 13 的 Theorem 6.4 对非线性 fixed-point eigenvalues 给出：对
  每个 $s>0$，存在依赖于 $s$、mode index、人工半径和参数的常数 $C$，使

  $$
    0\leq \lambda_m-\lambda_m^N\leq \frac{C}{N^{2s}}.
  $$

  后续结果还把该收敛传递到 eigenspaces/eigenfunctions，并允许有限重数。
- 门控意义：这是“exact boundary operator 的数值截断导致 guided eigenvalue error”
  的直接先例，比摘要级判断更强。因此一般的 DtN/Fourier truncation eigenvalue
  convergence 不能作为创新。其估计是依赖未知常数与精确正则性的先验谱逼近结果，
  不能从一次或相邻两次计算直接得到误差量级；也没有 BIE periodic half-guide、
  simple-root projected correction 或 effectivity。

### Djellouli--Bekkey--Choutri--Rezgui (2000)

R. Djellouli, C. Bekkey, A. Choutri, and H. Rezgui, “A Local Boundary Condition
Coupled to a Finite Element Method to Compute Guided Modes of Optical Fibres under
the Weak Guidance Assumptions,” *Mathematical Methods in the Applied Sciences*
23(17), 1551--1583 (2000),
[DOI](https://doi.org/10.1002/1099-1476(20001125)23:17%3C1551::AID-MMA160%3E3.0.CO;2-%23).

- 身份与证据：[[ref/ref_data/Djellouli2000.pdf|Djellouli2000.pdf]] 的题名页、正文和 publisher
  DOI 已核验。
- 原文定位：PDF pp. 2--4 区分圆边界上的 exact nonlocal DtN 与所提 local Robin 型
  artificial boundary condition，明确后者不是原全平面问题的等价条件；Sections 3--4
  分析 bounded eigenproblem 并给出 $P_1$ FEM generalized eigenproblem；Section 5
  以圆形 step-index 解析 dispersion curves 和既有文献值比较传播常数，报告典型相对
  误差与 mesh sensitivity。
- 门控意义：覆盖 guided eigenvalue、approximate boundary condition、FEM 实现和
  reference comparison，但没有针对单次计算的 boundary-truncation posterior
  estimator，也没有 BIE、周期半波导、doubling 或 simple-root effectivity。

### Choutri (2008)

A. Choutri, “Étude de l'erreur de troncature du domaine pour un problème aux valeurs
propres,” *Comptes Rendus Mathématique* 346(3--4), 233--237 (2008),
[DOI](https://doi.org/10.1016/j.crma.2007.12.003).

- 身份与证据：[[ref/ref_data/Choutri2008.pdf|Choutri2008.pdf]] 原文已核验。
- 原文定位：PDF pp. 2--4 将全平面 weak-guidance optical-fiber eigenproblem 改写为
  bounded-domain exact boundary operator problem，再用局部 Robin 条件近似；
  Proposition 4.1 与 Corollary 4.2 给出随人工半径 $R$ 指数衰减的 eigenvalue 与
  eigenfunction 先验估计。
- 门控意义：开放导模特征值的“域截断误差量级”不是新问题；其常数与精确谱量不可由
  当前离散结果直接计算，也没有 effectivity。

### Boureghda--Choutri--Rezgui (2022)

A. Boureghda, A. Choutri, and H. Rezgui, “On Domain Error Truncation in a Problem of
Guided Modes Computation in Optical Fibers,” *Mediterranean Journal of Mathematics*
19, 79 (2022), [DOI](https://doi.org/10.1007/s00009-022-02022-5).

- 身份与证据：[[ref/ref_data/Boureghda2022.pdf|Boureghda2022.pdf]] 全文已核验。
- 原文定位：PDF pp. 2--6 定义全平面光纤导模特征值与圆形人工边界上的 modified-
  Bessel exact DtN；pp. 7--10 用局部 Robin operator 替代 exact nonlocal DtN；
  pp. 13--20 给出 eigenvalue/eigenspace/eigenfunction 随 $R$ 指数衰减的误差界。
- 门控意义：这是 C4 的最强物理近邻，但对象是均匀包层光纤，不是周期线缺陷；没有
  BIE、finite-tail/doubling、可计算后验量或 simple-root projected correction。

### Marletta (2004)

M. Marletta, “Eigenvalue Problems on Exterior Domains and Dirichlet to Neumann Maps,”
*Journal of Computational and Applied Mathematics* 171, 367--391 (2004),
[DOI](https://doi.org/10.1016/j.cam.2004.01.019).

- 身份与证据：出版社 original full text 已核验；未找到可公开保存的 PDF。
- 原文边界：研究 exterior Schrödinger problem 中截断域/截断 potential 对 inner-boundary
  DtN 的逼近，证明谱包含与 spectral exactness；数值例同时警告病态离散可产生伪
  eigenvalues。
- 门控意义：提供 C3--C4 的一般谱逼近背景，但不是 posterior estimator，也不涉及
  periodic line defect 或 BIE cell map。

## 4. A posteriori estimator 与 nonlinear eigenvalue 近邻

### Giani (2013)

S. Giani, “An A Posteriori Error Estimator for hp-Adaptive Continuous Galerkin Methods
for Photonic Crystal Applications,” *Computing* 95(5), 395--414 (2013),
[DOI](https://doi.org/10.1007/s00607-012-0244-6).

- 身份与证据：[[ref/ref_data/Giani2013.pdf|Giani2013.pdf]] 全文已核验。
- 原文定位：PDF pp. 2--10 把应用约化为有界域 FEM eigenproblem，给出 residual
  estimator、eigenfunction reliability 与 eigenvalue-error estimate；p. 11 定义
  effectivity，并用 rich FEM space 的“exact eigenvalues”作参考；pp. 15--16 的 line
  defect 采用 supercell，pp. 18--19 的 semi-infinite example 固定有限矩形与 Dirichlet
  截断，均不估计无穷远截断误差。
- 门控意义：宽泛的 line-defect photonic-crystal eigenvalue estimator 声明被阻断；
  本项目仍可区分为 numerical half-guide DtN truncation error。

### Engström--Giani--Grubišić (2016)

C. Engström, S. Giani, and L. Grubišić, “Efficient and Reliable hp-FEM Estimates for
Quadratic Eigenvalue Problems and Photonic Crystal Applications,” *Computers &
Mathematics with Applications* 72(4), 952--973 (2016),
[DOI](https://doi.org/10.1016/j.camwa.2016.06.001).

- 身份与证据：[[ref/ref_data/Engstrom2016.pdf|Engstrom2016.pdf]] 全文已核验。
- 原文定位：PDF pp. 1--8 建立 quadratic Fredholm operator function 的 residual 与
  invariant-pair estimates；pp. 9--13 研究固定频率、求复 Bloch wavevector 的 periodic
  unit-cell problem；pp. 14--20 给出 DWR practical estimator、effectivity，并以更细
  goal-oriented FEM 的 8--12 位结果作 reference。
- 门控意义：NEP residual/DWR、左右向量与 effectivity 均有先例；但没有 line defect、
  half-guide DtN 或 infinity-truncation estimator。

### Gopalakrishnan et al. (2025)

J. Gopalakrishnan, J. Grosek, G. Pinochet-Soto, and P. VandenBerge, “Adaptive Resolution
of Fine Scales in Modes of Microstructured Optical Fibers,” *SIAM Journal on Scientific
Computing* 47(1), B108--B130 (2025),
[DOI](https://doi.org/10.1137/24M1651605).

- 身份与证据：[[ref/ref_data/Gopalakrishnan2025.pdf|Gopalakrishnan2025.pdf]] 及正式 open
  publisher text 已核验。
- 原文边界：研究 PML-truncated Maxwell fiber eigenproblem 的 DWR FEM eigenvalue
  estimator，以半解析 Bragg-fiber propagation constant 验证 effectivity；主要估计固定
  PML model 上的 FEM eigenvalue error，而非 PML/infinity truncation error。
- 门控意义：guided optical eigenvalue + a posteriori + independent truth/effectivity 的
  宽泛组合已有先例。

## 5. DtN truncation 的最新交叉近邻

### Xi--Gong--Sun (2024)

Y. Xi, B. Gong, and J. Sun, “Analysis of a Finite Element DtN Method for Scattering
Resonances of Sound Hard Obstacles,” arXiv:2404.09300 (2024).

- 身份与证据：[[ref/ref_data/Xi2024.pdf|Xi2024.pdf]] 题名页与全文已核验。
- 原文定位：PDF pp. 4--8 定义 exact circular DtN 与 Fourier-truncated $T^N$；
  Theorem 3.11（PDF p. 13）把 DtN tail 与 FEM approximation 传递到 holomorphic
  resonance NEP 的 eigenvalue error；Remark 3.12 给出先验收敛率；unit disk 用解析
  Hankel zeros 作 truth。
- 门控意义：已覆盖“DtN truncation $\rightarrow$ nonlinear spectral shift”的一般理论
  桥梁，但估计依赖精确 generalized eigenspace/tail 与未知常数，不是 computable
  a posteriori estimator；问题也是 scattering resonance。

### Lin--Lv (2025)

L. Lin and J. Lv, “An Adaptive Finite Element DtN Method for the Acoustic-Elastic
Interaction Problem in Periodic Structures,” *Advances in Computational Mathematics*
51(4), 41 (2025), [DOI](https://doi.org/10.1007/s10444-025-10253-9).

- 身份与证据：[[ref/ref_data/Lin2025.pdf|Lin2025.pdf]] 全文已核验。
- 原文定位：PDF pp. 10--20 定义 element/edge residual 与 DtN tail term；Theorem 1
  给出包含 FEM error 和指数衰减 DtN truncation term 的 computable a posteriori
  estimate，并用该项选择 truncation order；数值例含解析 scattering solution。
- 门控意义：周期结构中的 computable DtN truncation posterior term 已有直接先例；
  但它是带入射场的线性 scattering BVP，不是 eigenvalue error。

### Leclerc et al. (2026)

A. Leclerc, H. Barucq, M. Duruflé, C. Gout, and A. Tonnoir, “Linearized Absorbing
Boundary Conditions for Helmholtz Eigenvalue Problems,” *Computers & Mathematics with
Applications* 211, 59--75 (2026),
[DOI](https://doi.org/10.1016/j.camwa.2026.03.008).

- 当前证据：出版社 abstract、indexed primary text、结论、Crossref metadata 与 HAL
  记录已核验。文章研究开放 cable/fiber cross-section 的 propagating guided modes，
  以 Newton rational approximation 线性化 eigenvalue-dependent nonlocal/local ABC，
  并用圆形半解析案例比较精度与成本。
- 访问限制：HAL `hal-05550756` 的 PDF 截至 2026-12-15 处于 embargo；当前不能用摘要
  支撑“全文绝无 estimator”的绝对否定，只能确认公开 problem statement 与主要贡献
  不以 posterior estimator 为目标。
- 门控意义：guided eigenvalue + approximate boundary condition + semi-analytical truth
  已有 2026 年直接近邻，进一步要求本项目把创新限定在 computable posterior shift 与
  effectivity。

## 仍需补齐的全文

Bonnet-Ben Dhia--Gmati (1995) 与 Djellouli et al. (2000) 已完成本地全文核验。当前只剩
Leclerc et al. (2026) 的 HAL accepted manuscript 尚不可公开取得；
[HAL record](https://hal.science/hal-05550756) 标示公开日期为 2026-12-15。在此之前，
对该文“没有 posterior estimator”的判断仍限定于 publisher primary text、摘要与公开
结论，不能写成全文级绝对否定。
