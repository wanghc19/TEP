# Guided-mode eigensolver validation literature audit

状态：`SOURCE-VERIFIED METHODOLOGY SYNTHESIS / NO NUMERICAL EXPERIMENT`

检索与核验日期：2026-09-02。

## 研究问题与结论边界

本专题调查 fixed-$\beta$ periodic waveguide、DtN/RtR、trace/propagation operator、
Riccati、recursive doubling、BIE 和相邻 photonic eigenvalue estimator 文献在没有已知
真值时怎样论证数值结果可信。它补充
[[research/projects/eig-apost/implementation/i4/sources|I4.1 source matrix]]，但不改写已经冻结的
I1--I4 数学模型、证书、实验输出或历史 verdict。

本文件使用三种证据标签：

- `SOURCE-DIRECT`：来源全文直接支持，且给出 section、page、equation、table 或 figure locator；
- `CROSS-SOURCE INFERENCE`：多个来源与当前项目条件组合后的方法论推断，不冒充原文结论；
- `UNVERIFIED`：只核验了 metadata/abstract，或全文没有回答该项问题。

核心结论如下。

1. Fliss (2013) 证明的是无界导模问题与有限胞元 DtN nonlinear eigenproblem 的 continuous exact
   equivalence；其数值节没有 exact/semi-analytic eigenvalue、独立 reference、离散误差表、
   a priori eigenpair convergence theorem、computable a posteriori estimator 或 enclosure。
   标题中的 “exact computation” 指 exact transparent reduction，不认证最终离散 eigenvalue。
2. DtN/RtR guided-mode 主线通常以 same-method $h/p$ refinement、supercell width、boundary order、
   root/iteration residual、跨实现比较以及 localization/parity/band-gap membership 说明 solver
   “算得合理”。这些证据可以排查很多错误，但不能排除共同模型或离散偏差。
3. 有 guided-eigenvalue a priori boundary-truncation theory：Bonnet--Ben Dhia--Gmati (1995) 对
   homogeneous-cladding Fourier boundary operator 给出超代数谱逼近；Choutri (2008) 与
   Boureghda--Choutri--Rezgui (2022) 对局部人工边界给出随人工半径衰减的先验误差。它们的
   constants/regularity information 不是当前离散量可计算的后验上界。
4. 本次核验的 BIE/DtN/RtR guided eigensolver 核心来源中，没有一篇给出覆盖最终离散、
   artificial-boundary/trace truncation 与浮点误差的 certified interval enclosure。
5. 光子特征值 a posteriori 文献确实报告 effectivity，但通常把 rich finite-element solution 或
   semi-analytic benchmark 当作 truth proxy；理论可靠性/效率仍可能含隐藏常数、高阶项或固定
   PML-model error。它们不是自动可移植到当前 BIE/QZ reconstruction 的 certificate。
6. 当前把稳定的 BIE+DtN candidate 当作 empirical baseline，观察独立 curved-$P_2$ FEM ladder
   是否向它靠近，符合该领域常见验证实践；最多支持 cross-method positional consistency 和
   candidate credibility，不能支持 BIE estimator effectivity 或 true-error upper bound。

## 检索协议、边界与 citation chasing

检索按 academic-research-suite 的 deep-research/literature-review 流程进行：先以既有
[[ref/README|reference index]] 和 Phase 2/2b source trails 为种子，再检索题名、作者、DOI、
publisher、arXiv、HAL 与机构仓储；摘要只筛选，方法结论只取全文。共核验 22 篇本地公开全文，
另对 Petropoulos--Turc (2025) 只核验权威 metadata/abstract。没有运行数值实验或重新计算论文数据。

Backward/forward chasing 的主链为：

1. Fliss (2013) 向后追到 Joly--Li--Fliss (2006) 的 propagation/Riccati exact boundary map，向前追到
   Klindworth--Schmidt--Fliss (2014)、Fliss--Klindworth--Schmidt (2015) 和 Klindworth (2015)；
2. Yuan--Lu--Antoine (2008) 与 Lu--Lu (2014) 的 BIE/DtN 链向前追到 Yu et al. (2022) 和
   Petropoulos--Turc (2025) 的 recursive/half-array boundary operators；
3. Bonnet--Ben Dhia--Gmati (1995) 的 truncation theory 向后/向前对照 Djellouli et al. (2000)、
   Choutri (2008)、Boureghda et al. (2022)、Xi--Gong--Sun (2024) 与 Lin--Lv (2025)；
4. Giani (2013) 的 photonic estimator 链对照 Engstrom--Giani--Grubisic (2016) 与
   Gopalakrishnan et al. (2025) 的 effectivity practice。

检索边界：本轮没有把所有数据库的 cited-by 结果穷尽，也没有得到 Soussi (2005) 与
Petropoulos--Turc (2025) 的合法公开全文。因此下文只说“本次核验语料中”，不使用无边界的
“first”“唯一”或“此前无人”等 novelty 表述。

## 核心来源证据矩阵

### A. Guided-mode、band-structure 与 BIE/DtN/RtR eigensolvers

| 来源与原文定位 | eigenproblem 与方法 | exact/semi-exact truth | reference 定义 | 理论误差分析 | 数值误差指标 | refinement axes | 人工边界/trace order | 独立验证 | 最终支持的 claim | 对 eig-apost 的意义 |
|---|---|---|---|---|---|---|---|---|---|---|
| Fliss, “A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides,” *SIAM J. Sci. Comput.* 35 (2013), B438--B461, [DOI](https://doi.org/10.1137/12086697X), [[ref/ref_data/Fliss2013.pdf|full text]]. Theorem 3.5; Theorem 4.5; §5, pp. 20--22; conclusion p. 23 | fixed-$\beta$ self-adjoint line-defect guided eigenproblem；one-cell DtN、propagation operator Riccati equation、nonlinear eigenproblem | 无 exact eigenvalue、analytic dispersion 或 manufactured mode | 无 reference value；只给 dispersion roots 与两个 field plots | `SOURCE-DIRECT`：continuous DtN reduction exact，mode exponential decay；没有离散 eigenpair convergence/error theorem | $\log|\mu_1-\alpha^2|$ 曲线、dispersion branches、mode fields | 文中 numerical section 未给 mesh/order ladder | 未定义独立 Fourier $M$ ladder；local FE/mixed-FE trace discretization没有系统 order study | 无 | solver formulation 与示例可行；不支持 finite eigenvalue error、effectivity 或 enclosure | “exact”只能支撑 continuous model reduction；当前 estimator 不能借标题获得认证 |
| Klindworth--Schmidt--Fliss, “Numerical Realization of Dirichlet-to-Neumann Transparent Boundary Conditions for Photonic Crystal Wave-Guides,” *Comput. Math. Appl.* 67 (2014), 918--943, [DOI](https://doi.org/10.1016/j.camwa.2013.03.005), [[ref/ref_data/Klindworth2014.pdf|full text]]. §2, p. 4; §5.3--5.4, pp. 22--25, Figs. 7--10 | high-order curved-cell FEM realization of DtN guided-mode nonlinear eigenproblem | 无外部 exact eigenvalue；连续 TBC 对原无界问题无 modeling error | same iterative DtN method at polynomial degree $p=20$；supercell 与 direct Chebyshev 方法对照该 reference | 没有离散 nonlinear eigenpair a priori/a posteriori theorem | absolute eigenfrequency error、mean eigenvalue error、mode fields | $p$ refinement；supercell width $n$；Chebyshev degree/iterative construction | 不是 separate Fourier $M$；boundary trace 与 cell field 同由 high-order FEM $p$ 离散 | supercell 与 direct-Chebyshev 为算法/模型交叉检查，但 reference 仍来自 same DtN family | high-order realization exhibits $p$ convergence and supercell convergence plateaus | 是“rich same-method reference + cross-method check”的直接文献先例，不是 certified truth |
| Fliss--Klindworth--Schmidt, “Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides,” *BIT Numer. Math.* 55 (2015), 81--115, [DOI](https://doi.org/10.1007/s10543-014-0521-1), [[ref/ref_data/Fliss2015.pdf|full text]]. §§2--4; §5, especially journal pp. 102--110 | same guided NEP；RtR avoids DtN poles；Chebyshev approximation and high-order FEM | 无 exact eigenvalue | approximate common roots、higher-order/self-refined computations；DtN/RtR mutual comparison | continuous RtR equivalence/regularity；没有 full discretization eigenpair error estimator | distance-function minima、iteration error、Chebyshev-node error、condition numbers、fields | FEM $p$、iteration、Chebyshev interpolation nodes | trace operator accuracy由 $p$ 与 Chebyshev nodes 控制；没有 computable $M$ tail bound | DtN vs RtR，尤其 near local/global Dirichlet spectra | RtR numerical robustness and common-root consistency | condition number/branch structure是有用 diagnostic；仍不能给当前 eigenvalue error |
| Klindworth, *On the Numerical Computation of Photonic Crystal Waveguide Band Structures*, TU Berlin thesis (2015), [DOI](https://doi.org/10.14279/depositonce-4917), [[ref/ref_data/Klindworth2015.pdf|full text]]. Chs. 4, 6--7; §6 numerical studies; §8.2 “Numerical analysis …” | supercell、DtN/RtR high-order FEM、path following for band structures | 无独立 exact guided eigenvalue | Newton final iterate；same-method $p=20$；supercell $n$ compared with DtN $p=7$/$20$ | `SOURCE-DIRECT`：thesis outlook explicitly says rigorous numerical analysis of discrete DtN/RtR NEPs remains open | absolute eigenfrequency error、branch continuation、fields、condition numbers | $p$、supercell width、iteration/path steps | no separate Fourier $M$；trace resolution follows curved-cell high-order FEM | supercell vs DtN/RtR and continuation consistency | extensive numerical evidence for asymptotic convergence，not a proof/error certificate | 直接阻断“早期 DtN/RtR 已给离散误差理论”的误读 |
| Huang--Lu--Li, “Analyzing Photonic Crystal Waveguides by Dirichlet-to-Neumann Maps,” *JOSA B* 24 (2007), 2860--2867, [DOI](https://doi.org/10.1364/JOSAB.24.002860), [[ref/ref_data/Huang2007.pdf|full text]]. §3, Figs. 3--6 and convergence discussion | fixed-frequency line-defect mode，supercell DtN，求 Bloch wavenumber | 无 exact propagation constant | same method $N=19$；published finite-difference result；plane-wave/MPB check | 无 eigenvalue a priori/a posteriori estimate | relative $\beta$ error、inter-level change、dispersion、field parity/localization、bulk shaded region | supercell size $N$；boundary series/order $m$；PWE resolution | $m=10$，repeat $m=16$ “nearly identical”；经验选择 | finite difference and PWE/MPB only agree to limited digits | solver locations and mode identities are plausible | 当前 FEM-to-BIE approach符合该 cross-method practice；不产生 effectivity denominator |
| Li--Lu, “Computing Photonic Crystal Defect Modes by Dirichlet-to-Neumann Maps,” *Opt. Express* 15 (2007), 14454--14466, [DOI](https://doi.org/10.1364/OE.15.014454), [[ref/ref_data/Li2007.pdf|full text]]. §3, Tables/Figs. 2--6 | point-defect DtN NEP；smallest-singular-value root search | no analytic defect eigenvalue；published benchmark only a few digits | same-method $N=16$ and $p=12$ references；published numerical/experimental context | 无 posterior bound/enclosure | relative eigenfrequency error、inter-level drift、smallest singular value、mode fields | Fourier/grid order $N$；number of surrounding rings $p$ | empirical ladder；paper recommends example-specific $N\ge7$, $p\ge9$ for six digits；near gap edge needs larger $p$ | published values/context | good example-specific convergence，not universal certified accuracy | smallest singular value和level drift只能筛 candidate，不能验证 current estimator |
| Yuan--Lu--Antoine, “Modeling Photonic Crystals by Boundary Integral Equations and Dirichlet-to-Neumann Maps,” *J. Comput. Phys.* 227 (2008), 4617--4629, [DOI](https://doi.org/10.1016/j.jcp.2008.01.014), [[ref/ref_data/Yuan2008.pdf|full text]]. §§3--4, Tables 1--2 | unit-cell BIE builds DtN；Bloch band/eigenvalue computation | circular-cylinder local scatterer has analytic multipole field；不是最终 band-eigenvalue truth | repeated $N_1,N_2,m$；same-method finer level；published plane-wave results | BIE formulation analysis；无 computed eigenvalue a posteriori bound | inter-level Bloch-wavenumber/frequency differences、band diagrams、conditioning | interface nodes $N_1$；cell-boundary order $N_2$；multipole/order $m$ | parameters jointly increased；too large order can worsen conditioning；无 automatic tail bound | PWE literature | BIE/DtN band results are mutually consistent | local analytic operator test不能冒充 global guided-eigenvalue effectivity |
| Lu--Lu, “Efficient High Order Waveguide Mode Solvers Based on Boundary Integral Equations,” *J. Comput. Phys.* 272 (2014), 507--525, [DOI](https://doi.org/10.1016/j.jcp.2014.04.028), [[ref/ref_data/Lu2014.pdf|full text]]. §4, convergence tables and Figs. 3--8 | BIE NtD/DtN high-order waveguide mode solvers | analytic Hankel solution tests local boundary map；global propagation constants没有 exact truth | extrapolated high-resolution value from same BIE family；published rib-waveguide results | high-order discretization rationale；无 a posteriori bound | absolute propagation-constant error、observed order、field/domain-size sensitivity | boundary panels/nodes；BIE formulation；truncated-domain size | no universal $M$ rule；resolution ladder and extrapolation | two BIE formulations + published results | high-order convergence and cross-formulation consistency | Richardson-like extrapolation是惯例，但仍可能保留共同 BIE bias |

### B. Propagation operators、recursive doubling 与 truncation theory

| 来源与原文定位 | eigenproblem 与方法 | exact/semi-exact truth | reference 定义 | 理论误差分析 | 数值误差指标 | refinement axes | 人工边界/trace order | 独立验证 | 最终支持的 claim | 对 eig-apost 的意义 |
|---|---|---|---|---|---|---|---|---|---|---|
| Joly--Li--Fliss, “Exact Boundary Conditions for Periodic Waveguides Containing a Local Perturbation,” *Commun. Comput. Phys.* 1 (2006), 945--973, [DOI](https://doi.org/10.4208/cicp.2006.v1.p945), [[ref/ref_data/Joly2006.pdf|full text]]. §5, especially p. 962 and convergence figures | forced/local-perturbation waveguide scattering；exact boundary map via propagation/Riccati | authors explicitly state no actual physical solution is known | finest mesh/same method；spectral-decomposition vs modified-Newton；boundary-location check | continuous exact boundary condition and limiting absorption；not an eigenvalue error theorem | relative $L^2$ field difference、mesh rate、boundary-location invariance、mode pattern | mesh size；artificial-boundary location；solver construction | trace split into $N$ piecewise constants；没有 systematic $N$ rule/error bound | two numerical constructions only | strong self-consistency for scattering solver | “exact boundary”不等于 exact finite solution；文中主动承认缺真值 |
| Coatléven, “Helmholtz Equation in Periodic Media with a Line Defect,” *J. Comput. Phys.* 231 (2012), 1675--1704, [DOI](https://doi.org/10.1016/j.jcp.2011.10.022), [[ref/ref_data/Coatleven2012.pdf|full text]]. convergence theorems and §5 | line-defect scattering via Floquet--Bloch/DtN and FEM | homogeneous case permits analytic/Hankel qualitative check；非通用 exact solution | same mesh with large Floquet quadrature $N_k=200$ | a priori estimates for Floquet quadrature/truncation and FEM，not guided eigenvalue estimator | relative $H^1$ field error、observed vs theoretical rate | $N_k$；mesh/order | theory controls transform quadrature/truncation；not the current eigenvalue trace $M$ | analytic special case only | scattering approximation converges | shows a priori tail theory can exist without yielding computable eigenvalue effectivity |
| Yuan--Lu, “A Recursive-Doubling Dirichlet-to-Neumann-Map Method for Periodic Waveguides,” *J. Lightwave Technol.* 25 (2007), 3649--3656, [DOI](https://doi.org/10.1109/JLT.2007.907742), [[ref/ref_data/Yuan2007.pdf|full text]]. numerical examples/tables | waveguide scattering，recursive doubling of cell DtN；不是 guided NEP | 无 exact global solution | COST 268 benchmark；FD eigenmode-expansion reference；finer-grid same method；published FDTD/eigenmode results | 无 a posteriori/certified error | relative reflectance error、digits agreement、field/flux behavior | spatial grid；PML/order；doubling levels；Padé/Chebyshev parameters | empirical fixed/refined choices | independent benchmark/methods | scattering solver accuracy to reported digits | recursive doubling本身不提供 current eigenvalue estimator validation |
| Ehrhardt--Sun--Zheng, “Evaluation of Scattering Operators for Semi-Infinite Periodic Arrays,” *Commun. Math. Sci.* 7 (2009), 347--364, [DOI](https://doi.org/10.4310/CMS.2009.v7.n2.a4), [[ref/ref_data/Ehrhardt2009.pdf|full text]]. §§3--5 | semi-infinite array scattering-to-scattering maps，doubling/Riccati | one test array has analytic StS map | 20-doubling result；$\epsilon$ limit/extrapolation；analytic test | limiting-absorption convergence；not finite-computation enclosure | relative operator errors、doubling decay、energy-flux structure | absorption $\epsilon$；doublings；discretization | no universal $M$ bound；convergence/structure checks | analytic special case and alternate array constructions | boundary maps are numerically consistent | operator residual/flux checks可纳入 solver QA，但不等同 eigenvalue truth |
| Yu--Hu--Lu--Rathsfeld, “PML and High-Accuracy Boundary Integral Equation Solver for Wave Scattering by a Locally Defected Periodic Surface,” *SIAM J. Numer. Anal.* 60 (2022), 2592--2625, [DOI](https://doi.org/10.1137/21M1439705), [[ref/ref_data/Yu2022.pdf|full text]]. convergence theorems and §5 | locally defected periodic-surface scattering；PML+BIE+Riccati/NtD | flat-interface case exact；complex geometry uses fine self-reference | exact flat solution or high-resolution same method | rigorous PML/truncation convergence on compact physical sets；not guided eigenvalue a posteriori estimate | relative field error、Riccati residual、iteration decay、parameter sensitivity | PML strength/length；mesh/quadrature；iteration | PML error理论 + parameter ladder；not a Fourier $M$ eigenvalue enclosure | exact flat case | high-order scattering solver and PML convergence | good operator-level benchmark pattern；不能替 current eigenvalue effectivity |
| Bonnet--Ben Dhia--Gmati, “Spectral Approximation of a Boundary Condition for an Eigenvalue Problem,” *SIAM J. Numer. Anal.* 32 (1995), 1263--1279, [DOI](https://doi.org/10.1137/0732058), [[ref/ref_data/Bonnet1995.pdf|full text]]. Theorem 6.4 | homogeneous-cladding optical-fiber guided eigenproblem；exact Fourier boundary operator truncated at order $N$ | continuous separated exterior gives exact boundary operator | mathematical exact operator；no numerical truth table needed | eigenvalue/eigenspace superalgebraic a priori convergence under regularity/isolation assumptions | theoretical spectral/eigenfunction norms | Fourier truncation $N$ | $N$ controlled asymptotically by theorem；constants not computable from current discrete output | no numerical independent validation | boundary spectral truncation converges | proves relevant a priori precedent，not computable posterior error or enclosure |
| Djellouli--Bekkey--Choutri--Rezgui, “A Local Boundary Condition Coupled to a Finite Element Method to Compute Guided Modes of Optical Fibres…,” *Math. Methods Appl. Sci.* 23 (2000), 1551--1583, [DOI](https://doi.org/10.1002/1099-1476(20001125)23:17%3C1551::AID-MMA160%3E3.0.CO;2-%23), [[ref/ref_data/Djellouli2000.pdf|full text]]. numerical sections | weak-guidance fiber eigenproblem；local Robin ABC+FEM | circular step-index fiber has analytic/semi-analytic dispersion values | analytic circular case；published values for graded profiles | approximation/domain analysis，not computable posterior estimator | relative propagation-constant error、boundary-radius/mesh sensitivity、mode fields | mesh；artificial radius $R$ | local ABC，not Fourier $M$；vary $R$ empirically/theoretically | analytic and literature values | ABC+FEM accuracy for tested fibers | 一个可移植的 semi-analytic benchmark template |
| Choutri, “Étude de l'erreur de troncature du domaine pour un problème aux valeurs propres,” *C. R. Math.* 346 (2008), 233--237, [DOI](https://doi.org/10.1016/j.crma.2007.12.003), [[ref/ref_data/Choutri2008.pdf|full text]]. Proposition 4.1, Corollary 4.2 | optical-fiber guided eigenproblem with local artificial boundary | 不依赖 numerical truth | exact infinite-domain eigenpair as analysis object | eigenvalue/eigenfunction domain-truncation error decays exponentially with radius，with noncomputable constants | theory only | radius $R$ | radius selected by asymptotic estimate，not computable finite-run certificate | none | a priori domain truncation convergence | 与 current periodic trace $M$ 不同，不能直接当 estimator proof |
| Boureghda--Choutri--Rezgui, “On Domain Error Truncation in a Problem of Guided Modes Computation in Optical Fibers,” *Mediterr. J. Math.* 19 (2022), 79, [DOI](https://doi.org/10.1007/s00009-022-02022-5), [[ref/ref_data/Boureghda2022.pdf|full text]]. main error theorem and conclusion | exact DtN vs approximate local boundary for optical-fiber modes | no new exact numerical benchmark | continuous exact eigenpair in theorem；cites prior numerics | exponential a priori eigenvalue/eigenfunction error in truncation radius；hidden constants | theory only | radius $R$ | no Fourier $M$; choose $R$ through asymptotic theory | none | theoretical domain truncation control | confirms a priori control is not synonymous with a computable posterior bound |
| Xi--Gong--Sun, “Analysis of a Finite Element DtN Method for Scattering Resonances of Sound Hard Obstacles” (2024), [arXiv/DOI](https://doi.org/10.48550/arXiv.2404.09300), [[ref/ref_data/Xi2024.pdf|full text]]. Theorem 3.11, Remark 3.12, §4 | sound-hard scattering-resonance holomorphic NEP；Fourier DtN+FEM | unit disk has exact Hankel resonance poles | exact disk poles；otherwise inter-level values | a priori spectral convergence jointly in DtN order $N$ and FE space；not a posteriori | relative pole error/inter-level error、observed order、eigenfunctions | FE refinement；DtN $N$ | numerical tests fix $N=20$ as “large enough”；no run-specific certified tail | exact disk only | resonance NEP convergence | supports a two-axis $h$/$M$ benchmark design，not theorem transfer to guided modes |
| Lin--Lv, “An Adaptive Finite Element DtN Method for the Acoustic-Elastic Interaction Problem in Periodic Structures,” *Adv. Comput. Math.* 51 (2025), 41, [DOI](https://doi.org/10.1007/s10444-025-10253-9), [[ref/ref_data/Lin2025.pdf|full text]]. Theorem 1 and numerical section | periodic acoustic-elastic scattering；adaptive FEM with truncated Fourier DtN | flat/simple case exact；other cases use rich reference | exact solution or fine adaptive solution | residual reliability-type estimate plus explicit exponentially decaying DtN truncation term；hidden multiplicative constant；not eigenvalue enclosure | energy/$H^1$ error、estimator decay、adaptive rate | mesh adaptivity；DtN $N$ | choose $N$ so theoretical truncation term is below FEM estimator/tolerance | exact/rich reference | computable truncation term can be coupled to residual in scattering | strongest structural analogue for adding an $M$ term，but current eigenvalue/simple-root transfer remains open |
| Petropoulos--Turc, “Domain Decomposition Multiple Scattering Solvers by Semi-Infinite and Infinite Arrays of Discrete Identical Scatterers in Two Dimensions,” *Phil. Trans. R. Soc. A* 383 (2025), 20240355, [DOI](https://doi.org/10.1098/rsta.2024.0355) | BIE Fourier unit-cell RtR、Riccati half-array、multiple scattering | `UNVERIFIED` | `UNVERIFIED` | abstract says formulation/solver；finite-error theorem not verified | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` | numerical examples mentioned in abstract only | only architecture/identity verified | no public full text located；不得用来支持 validation 或 $M$ claims |

### C. A posteriori estimator 与 effectivity practice

| 来源与原文定位 | eigenproblem 与方法 | exact/semi-exact truth | reference 定义 | 理论误差分析 | 数值误差指标 | refinement axes | 人工边界/trace order | 独立验证 | 最终支持的 claim | 对 eig-apost 的意义 |
|---|---|---|---|---|---|---|---|---|---|---|
| Giani, “An A Posteriori Error Estimator for $hp$-Adaptive Continuous Galerkin Methods for Photonic Crystal Applications,” *Computing* 95 (2013), 395--414, [DOI](https://doi.org/10.1007/s00607-012-0244-6), [[ref/ref_data/Giani2013.pdf|full text]]. estimator theorems; numerical §§4--5 | conforming $hp$-FEM photonic eigenproblem，including a line-defect supercell | no analytic line-defect eigenvalue | very rich finite-element space is called “exact” numerical reference | residual eigenfunction/eigenvalue reliability/efficiency with higher-order terms/hidden constants；not certified numerical interval | eigenvalue/eigenfunction error、estimator、effectivity、DOF convergence、fields | $h$ and $hp$ adaptivity | supercell/model truncation not included in estimator | reference is same FEM family | estimator tracks adaptive discretization error on fixed finite model | establishes expected effectivity plots，also shows “exact” may mean rich discrete reference |
| Engström--Giani--Grubišić, “Efficient and Reliable $hp$-FEM Estimates for Quadratic Eigenvalue Problems and Photonic Crystal Applications,” *Comput. Math. Appl.* 72 (2016), 952--973, [DOI](https://doi.org/10.1016/j.camwa.2016.06.001), [[ref/ref_data/Engstrom2016.pdf|full text]]. theory sections and numerical §5 | quadratic photonic NEP；residual and dual-weighted-residual estimators | no closed-form photonic root | much finer goal-oriented FE space，claimed high-digit reference | a priori approximation plus residual/DWR posterior estimates，with assumptions/constants | eigenvalue/eigenfunction errors、residual/DWR estimator、effectivity | $h$/$hp$ adaptive levels | no periodic-lead Fourier $M$ | rich-space reference from same model | DWR can show near-unit effectivity；residual estimator may track error while effectivity is far from one | “decreasing together”与“effective near one”必须分开报告 |
| Gopalakrishnan--Grosek--Pinochet-Soto--VandenBerge, “Adaptive Resolution of Fine Scales in Modes of Microstructured Optical Fibers,” *SIAM J. Sci. Comput.* 47 (2025), B108--B130, [DOI](https://doi.org/10.1137/24M1651605), [[ref/ref_data/Gopalakrishnan2025.pdf|full text]]. Bragg-fiber benchmark and later application sections | PML-truncated microstructured-fiber nonlinear eigenproblem；DWR adaptivity | Bragg fiber has semi-analytic eigenvalue | semi-analytic benchmark；complex fibers use final adaptive iterate | DWR estimate for fixed PML discrete model；does not certify PML truncation | Hausdorff cluster eigenvalue error、effectivity、field fine scales、loss stabilization | adaptive mesh levels；PML settings in model studies | no Fourier $M$；PML error separated from FE estimator | semi-analytic benchmark then complex application | estimator benchmark can be separated from realistic application | directly supports“一个 semi-analytic effectivity case + 一个复杂 consistency case”的论文结构 |

## “exact computation”与 finite numerical accuracy

### Fliss (2013) 的准确含义

`SOURCE-DIRECT`：Theorem 4.5 把 gap 内原无界 fixed-$\beta$ guided-mode problem 与有限 defect cell 上
含 exact half-guide DtN maps 的 nonlinear eigenproblem 等价，并保持特征值 multiplicity；Riccati
equation 刻画 exact propagation operator。因而“exact”排除的是把无限 exterior 换成有限 supercell、
PML 或 local absorbing condition 所产生的 continuous modeling error。

它不排除以下 finite-computation errors：

- cell PDE 与 trace 的 FE/mixed-FE discretization；
- propagation/Riccati operator 的有限矩阵近似；
- nonlinear root search 与 branch tracking；
- quadrature、linear algebra 与 floating-point errors。

§5 的两个 numerical examples 使用 smooth periodic Gaussian coefficient 和缺陷 coefficient；作者给出
dispersion/minimum curves及两个 mode fields，图中示例约为 $(\beta,\omega^2)=(0.5,3.465)$ 与
$(1.42,10.46)$。没有 exact eigenvalue、semi-analytic dispersion、manufactured solution、reference
table、mesh/order convergence table、residual norm、effectivity 或 enclosure。结论把 accuracy/time
comparison 留给后续工作。因此该论文充分支持 “continuous DtN formulation is exact” 和
“the algorithm produced plausible modes”，不支持 “reported eigenvalues have certified error”。

### 相邻论文的同一用法

Joly--Li--Fliss (2006) 的 “exact boundary condition”、Klindworth--Schmidt--Fliss (2014) 的
“without modeling error” 以及 Ehrhardt--Sun--Zheng (2009) preprint 标题中的 “exact boundary mappings”
也都是 operator/model 层陈述。即便某个离散序列被证明收敛到 exact operator，指定有限 order 的误差
仍需显式 computable bound 才能称 certified；asymptotic convergence 本身不产生当前 run 的 enclosure。

## 没有真值时，论文实际怎样验证

按本次核验语料，常见做法从多到少可归纳为：

1. **same-method rich reference/self-convergence**：把 $p=20$、更细 mesh、更大 supercell、更多 rings、
   更高 boundary order 或最后 adaptive iterate 当 reference；报告 inter-level drift 或相对差。
2. **cross-formulation/cross-method consistency**：DtN 对 supercell、DtN 对 RtR、两种 BIE formulation、
   BIE 对 PWE/finite difference/FEM 或 published benchmark。它减小单个 implementation bug 的可能性，
   但不能排除 shared modeling bias。
3. **extrapolation**：由同一高阶 BIE sequence 外推 propagation constant；该 truth proxy 的不确定性
   必须小于待评误差，才能用于 effectivity。
4. **operator/local exact test**：圆柱 Hankel/multipole、flat interface 或 analytic StS map。这验证 building
   block，不直接验证 global guided eigenvalue。
5. **mode/physics/structure checks**：localization、symmetry/parity、branch continuation、gap containment、
   energy flux、unitarity/reciprocity、condition number。它们用于 mode identity 和 implementation sanity，
   不能替代 eigenvalue error measurement。

本次核心 guided-eigensolver 语料中没有 manufactured guided-mode solution。可用的更强 benchmark 是：

- Djellouli et al. (2000) 的 circular step-index fiber semi-analytic/dispersion values；
- Xi--Gong--Sun (2024) 的 unit-disk analytic Hankel resonances，但它是 scattering resonance；
- Gopalakrishnan et al. (2025) 的 semi-analytic Bragg-fiber mode；
- Yuan--Lu--Antoine (2008)、Lu--Lu (2014) 的 analytic local cylinder/operator tests，不能当 global truth。

## 人工边界/trace truncation order 的文献做法

文献里的 $M$ 并不总是同一个对象，必须先区分：Fourier DtN cutoff、boundary FEM polynomial degree、
BIE nodes/multipoles、supercell width 与 recursive-doubling levels。

| 处理类别 | 代表来源 | 实际选择方式 | 能支持什么 |
|---|---|---|---|
| a priori Fourier spectral convergence | Bonnet--Ben Dhia--Gmati (1995)；Xi--Gong--Sun (2024) | theorem 给出 $N\to\infty$ 谱收敛；数值中仍可能直接固定一个“足够大”的 $N$ | asymptotic convergence；没有 computable finite-$N$ upper bound |
| posterior residual + explicit DtN tail | Lin--Lv (2025) | 让理论 exponential tail term 小于 mesh estimator/tolerance | scattering energy-error control 的结构先例；不是 guided-eigenvalue enclosure |
| empirical order ladder | Huang--Lu--Li (2007)；Li--Lu (2007)；Yuan--Lu--Antoine (2008) | 增大 $m/N$ 直到 digits 或曲线稳定；与 mesh/rings 一起调整 | observed sensitivity，not reliability |
| trace discretized by high-order FEM | Fliss (2013)；Klindworth--Schmidt--Fliss (2014)；Fliss et al. (2015) | 用同一 curved-cell $p$ refinement 或 Chebyshev nodes，不存在单独 Fourier $M$ | discretization convergence evidence |
| PML/recursive operator parameters | Yuan--Lu (2007)；Yu et al. (2022)；Ehrhardt et al. (2009) | doubling/absorption/PML/mesh parameter studies；sometimes exact special case | operator/scattering convergence，not guided-eigenvalue posterior estimate |
| no systematic study in numerical section | Fliss (2013) | 未报告独立 $M$ ladder 或 finite-order bound | 不能从论文数值图推断 trace error 已 negligible |

因此当前论文若使用 $M$，最低要求不是引用“exact DtN”，而是明确 $M$ 的数学对象，并给出：
固定其他轴的 $M$-ladder、与 $h$/quadrature/root tolerance 的联合 plateau 检查、tail/residual quantity，以及
任何声称 upper bound 时所需的 computable constant 和 assumptions。

## 三种论文标准不能互换

### 1. 新 eigensolver 证明“算得合理”

最低证据是 correct continuous reduction，加上所有 material discretization axes 的 refinement、root/operator
residual、branch/mode identity、localization/parity/gap containment，并尽可能有 semi-analytic 或 independent
cross-method check。结论应写成 numerical consistency/observed convergence，而不是 true-error bound。

### 2. A posteriori estimator 证明“估得合理”

还需要一个 uncertainty 明显小于被测 error 的 truth/reference，并在多级 refinement 上报告

$$
\mathrm{eff}_h=\frac{\eta_h}{|k_h-k_\star|}
\quad\text{或论文明确采用的倒数定义},
$$

同时固定定义方向。应覆盖 asymptotic 与 pre-asymptotic levels、至少一个困难 regime、simple-root/cluster
matching、eigenfunction或subspace identity，并展示失败或失效条件。若 reference 与 estimator 共用同一
BIE/QZ chain，必须论证 denominator 不循环。

只观察 $\eta_h$ 与 inter-level drift 同时下降可以支持 correlation，不能单独支持 effectivity；只在一个
unresolved truth point 上给 ratio 更不充分。

### 3. Certified solver 证明“误差有保证”

还需 computable constants 或 validated interval/resolvent/inclusion theorem，验证 spectral isolation、
simple-root/existence hypotheses，并把 field discretization、trace/artificial-boundary truncation、quadrature、
nonlinear root error 与 roundoff 全部计入 outward enclosure。本次核验语料中的 guided BIE/DtN/RtR solver
没有达到这一标准；Giani/Engström/Gopalakrishnan 的 effectivity studies 也不等同 interval certification。

## 对当前 BIE/FEM comparison 的方法论判断

本节只解释
[[research/projects/eig-apost/implementation/i4/review-4-1c#Q. Formal post-run artifact, resource and claim review|I4.1c review §Q]]
已经记录的数值事实，不修改其 artifact 或 verdict。当前数据为

$$
k_{\mathrm{BIE+DtN}}=1.832770289108157,
\qquad
k_{\mathrm{FEM}}^{\mathrm{curved},P_2}=1.8328570940899811,
$$

两者位置距离为 $8.6804981824\times10^{-5}$；curved-$P_2$ FEM 的 observed resolution descriptor 为
$9.8154173157\times10^{-5}$。FEM mesh ladder 又从 $s=6,9,12$ 向稳定 BIE candidate 靠近。

`CROSS-SOURCE INFERENCE`：把 BIE candidate 当 empirical baseline 检查 FEM convergence，符合
Klindworth--Schmidt--Fliss (2014) 的 DtN/supercell 交叉比较、Huang--Lu--Li (2007) 的 DtN/PWE/FD
比较以及多篇 BIE 文献的 common practice。它支持：

- 两个独立离散表述在 $10^{-4}$ 量级达到 positional consistency；
- 当前 FEM ladder 的方向与“向稳定 BIE candidate 收敛”相容；
- target branch/location 由单方法 implementation error 造成的可能性降低。

它不支持：

- 任一方法的 true error 小于 $10^{-4}$；
- BIE 比 FEM 更准确，或 BIE value 是 certified truth；
- 当前 BIE-derived estimator 的 reliability、effectivity 或 $10^{-9}$ 级 accuracy；
- continuous guided eigenvalue existence、唯一性或 enclosure。

原因是 FEM observed resolution 与方法间距离同量级，且没有独立 truth uncertainty 小于 estimator 所指的
误差尺度；同一 BIE baseline 不能循环地验证从该 BIE chain 构造的 estimator。

## 当前 estimator 论文的最低现实验证包

若目标是发表 **empirical a posteriori estimator validation**，而不是 certified solver，最低可辩护方案是：

1. **一个 exact/semi-analytic benchmark**：continuous problem、normalization、simple-root assumptions 与
   current residual reconstruction 相匹配；独立求得 $k_\star$，其 uncertainty 明显低于最小 tested error。
2. **多轴 effectivity study**：对 $h$、trace order $M$、BIE quadrature/operator resolution 与 nonlinear
   solve tolerance 分轴/联合 refinement；同时报告 actual error、$\eta_h$、effectivity、mode identity、
   derivative/conditioning 和 pre-asymptotic behavior。
3. **当前 sharp-disk application**：保留 BIE internal ladder、curved-FEM mesh/domain ladder、field overlap、
   localization/parity/gap evidence 和 cross-method positional comparison；明确把它称为 application-level
   consistency，而不是 effectivity。
4. **claim boundary**：如果复杂问题没有精度远高于 $10^{-9}$ 的独立 reference，不要求强造该 reference；
   只要论文不在该例上声称 $10^{-9}$ true error/effectivity/certification，就可以把 benchmark 与 realistic
   application 的证据职责分开。
5. **若声称 reliability/certification**：必须另行闭合 computable constants、all-tail bounds、spectral
   isolation/existence 与 outward rounding；上述最低 empirical package 不足以支持 certified claim。

Gopalakrishnan et al. (2025) 的“semi-analytic Bragg benchmark + complex fiber application”是这套结构的
直接先例。为增强论文说服力，benchmark 最好不只一个 resolution point，并应至少覆盖一个较弱 confinement、
near-gap-edge 或 estimator pre-asymptotic regime；这属于 `CROSS-SOURCE INFERENCE` 的审稿风险控制建议，
不是任一来源的硬性出版规则。

## 反面证据与风险登记

- 漂亮 dispersion/mode plots 可证明 candidate 有物理形态，不能测量 eigenvalue error；Fliss (2013) 是最清楚例子。
- same-method rich reference 无法排除 common bias；Klindworth--Schmidt--Fliss (2014)、Giani (2013) 和
  Lu--Lu (2014) 都需要这一限定。
- smallest singular value 只说明离散矩阵接近 singular；不提供 continuous residual norm、root conditioning
  或 simple-root guarantee。
- boundary order plateau 可能来自 mesh、quadrature 或 ill-conditioning floor；Yuan--Lu--Antoine (2008)
  明确显示过大 order 会带来 conditioning 问题。
- position agreement 可能错配 branch；必须同时检查 continuation、field overlap/localization、symmetry/parity
  与 projected/bulk-gap membership。
- “exact DtN”若不同时报告 DtN numerical realization 的 resolution，容易被误读为 final eigenvalue exactness。

## 新来源、访问障碍与 ref 维护

本轮新增并核验公开全文：

- Dirk Klindworth, Kersten Schmidt, Sonia Fliss (2014),
  [[ref/ref_data/Klindworth2014.pdf|ref_data/Klindworth2014.pdf]]；author/project public copy；
  [institutional public full text](http://opus4.kobv.de/opus4-matheon/files/1200/KlindworthSchmidtFliss2013.pdf)；
  DOI `10.1016/j.camwa.2013.03.005`。PDF identity、28 pages 与 publisher metadata 已交叉核对。

未能合法公开取得全文：

- Sofiane Soussi, “Convergence of the Supercell Method for Defect Modes Calculations in Photonic Crystals,”
  *SIAM J. Numer. Anal.* 43 (2005), 1175--1201, DOI `10.1137/040616875`：publisher full text closed；
  本专题不以 abstract 证明它覆盖 current fixed-$\beta$ line-defect assumptions。
- David C. Petropoulos, Catalin Turc (2025)，上表论文，DOI `10.1098/rsta.2024.0355`：核验了
  Royal Society/NJIT/PubMed metadata 与 abstract，但没有找到合法公开全文；所以其 numerical reference、
  truncation order 与 error metric 全部标 `UNVERIFIED`。

## Handoff

本专题只形成文献证据和方法论结论。没有重新计算 effectivity，没有运行 MATLAB、Octave、Python guided-mode
computation 或其他数值实验；没有改动 I4.1c design/review/artifacts。后续若据此设计 estimator benchmark，
必须另开经授权的 Researcher--Engineer--Skeptic gate，不能把本文件视为实验授权。
