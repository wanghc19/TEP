# I4.1 来源核验矩阵

状态：`VERIFIED CORPUS FOR METHOD DRAFT`
检索协议：[[research/projects/eig-apost/implementation/i4/search-plan|search plan]]
检索记录：[[research/projects/eig-apost/implementation/i4/search-log|search log]]

## 证据标签

- `SOURCE-DIRECT`：来源正文或权威 primary page 直接支持，且下表给出 locator。
- `CROSS-SOURCE INFERENCE`：由两篇以上来源与当前 continuous specification 组合推出；
  不是任一来源已经为当前 exact geometry 证明的结果。
- `UNVERIFIED FOR CURRENT MODEL`：来源存在，但没有完成当前 polarization、参数或收敛
  映射；不得用作主 reference 结论。

来源质量按本领域校准：同行评审 mathematical/numerical primary source 为主，博士论文用于
实现细节，official software documentation 只支持公开实现能力。没有把搜索摘要当成定理正文。

## 核心来源

| 来源身份 | DOI / 权威链接与类型 | 原文核验与公开状态 | 支持对象和原文位置 | current problem match | 对 independence、mode ID、resolution 的意义 | 状态 |
|---|---|---|---|---|---|---|
| Sonia Fliss, “A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides,” *SIAM J. Sci. Comput.* 35(2), B438--B461 (2013) | [DOI](https://doi.org/10.1137/12086697X)；peer-reviewed；[arXiv](https://arxiv.org/abs/1202.4928) | 全文已核验；公开；[[ref/ref_data/Fliss2013.pdf|ref_data/Fliss2013.pdf]] | fixed-quasimomentum self-adjoint guided eigenproblem；gap 内离散谱；Theorem 3.5 的 field exponential decay；pp. 6--9 的 supercell interpretation；Theorem 4.5 的 bounded DtN equivalence | `HIGH`：同类 line defect 和 fixed parameter；当前 sharp disks 是该框架内的 piecewise coefficient，但不是论文数值 profile | decay/localization 与 projected-gap membership 可作独立 mode ID；supercell width 是 reference axis；不直接给本项目 supercell error constant | `SOURCE-DIRECT`（框架/decay）；exact sharp-disk convergence 为 `CROSS-SOURCE INFERENCE` |
| Sonia Fliss, Dirk Klindworth, Kersten Schmidt, “Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides,” *BIT Numer. Math.* 55, 81--115 (2015) | [DOI](https://doi.org/10.1007/s10543-014-0521-1)；peer-reviewed | 全文已核验；公开作者稿；[[ref/ref_data/Fliss2015.pdf|ref_data/Fliss2015.pdf]] | pp. 1--6：same line-defect guided PDE、RtR well-posedness；pp. 25--31：high-order FEM/NEP、DtN failure at Dirichlet spectra、RtR comparison；正文比较 weakly confined supercell cost | `HIGH` at PDE family；paper geometry/material differs | FEM+RtR 是主 supercell 的不同 infinity treatment，也是与 BIE/QZ 不同的后备 reference；同时提供 supercell near-band-edge caveat | `SOURCE-DIRECT` |
| Dirk Klindworth, *On the Numerical Computation of Photonic Crystal Waveguide Band Structures*, TU Berlin doctoral thesis (2015) | [DOI](https://doi.org/10.14279/depositonce-4917)；doctoral thesis/institutional | 全文已核验；公开；[[ref/ref_data/Klindworth2015.pdf|ref_data/Klindworth2015.pdf]] | Chapter 4：supercell formulation/limitations；Chapters 6--7：high-order FEM DtN/RtR、derivatives、path following；pp. 102--104：rich computation/reference comparison；p. 153：transparent-boundary numerical analysis gap | `HIGH` at formulation, `MEDIUM` at exact material | 提供 future-implementable FEM/RtR map 和 branch continuation；明确 reference differences 不是 certified error | `SOURCE-DIRECT` |
| Stefano Giani, “An A Posteriori Error Estimator for hp-Adaptive Continuous Galerkin Methods for Photonic Crystal Applications,” *Computing* 95, 395--414 (2013) | [DOI](https://doi.org/10.1007/s00607-012-0244-6)；peer-reviewed | 全文已核验；公开作者稿；[[ref/ref_data/Giani2013.pdf|ref_data/Giani2013.pdf]] | pp. 2--10：generic weighted variational eigenproblem、conforming $hp$-FEM、residual adaptation；p. 11：rich-space “exact” reference/effectivity；pp. 15--16：removed-column line-defect supercell and field；pp. 18--19：Dirichlet finite rectangle but no infinity-error estimator | `HIGH` geometrically；paper example polarization/coefficients must be remapped to $A=I$, $B=q$ | 直接支持 fitted conforming FEM 可返回 eigenvalue+field；also warns rich FEM value is empirical and domain truncation remains separate | `SOURCE-DIRECT` |
| Sofiane Soussi, “Convergence of the Supercell Method for Defect Modes Calculations in Photonic Crystals,” *SIAM J. Numer. Anal.* 43(3), 1175--1201 (2005) | [DOI](https://doi.org/10.1137/040616875)；peer-reviewed | 身份、卷页和 publisher abstract 已核验；按 SIAM 卷期的 print year 2005 引用，Crossref online year 为 2006；publisher full text closed；本地 PDF 无 | official abstract：2-D TE/TM compact-defect supercell frequencies exponential convergence、eigenfunction quasi-independence in wave vector、background supercell eigenvalue characterization | `PARTIAL`：compact defect theorem，不是 fixed-$\beta$ line defect 的逐假设核验 | 支撑 twist-band collapse 和 background-band discrimination 的理论邻近；不能声称 theorem 已原样覆盖 current operator | abstract 为 `SOURCE-DIRECT`；迁移为 `UNVERIFIED FOR CURRENT MODEL` |
| Eric Cancès, Virginie Ehrlacher, Yvon Maday, “Periodic Schrödinger Operators with Local Defects and Spectral Pollution,” *SIAM J. Numer. Anal.* 50(6), 3016--3035 (2012) | [DOI](https://doi.org/10.1137/110855545)；peer-reviewed；[arXiv 1111.3892](https://arxiv.org/abs/1111.3892) | 公开 preprint；identity/abstract/theorem scope 核验；本轮未新增本地 PDF | ordinary finite-section Galerkin can pollute gaps；supercell model has no spectral pollution in its periodic Schrödinger/local-defect setting；approximate projectors provide no-pollution alternative | `PARTIAL`：operator class adjacent, not a checked theorem for line-defect fixed-$\beta$ generalized Helmholtz | 要求先计算 independent bulk gap、检查 background bands，不把 arbitrary finite-strip root 当 defect mode | `SOURCE-DIRECT` for source operator；current transfer is `CROSS-SOURCE INFERENCE` |

## 离散、透明边界与 uncertainty 近邻

| 来源身份 | DOI / 类型 | 原文与路径 | 直接支持 | 匹配与限制 | I4.1 用途 | 状态 |
|---|---|---|---|---|---|---|
| Anne-Sophie Bonnet-Ben Dhia, Nabil Gmati, “Spectral Approximation of a Boundary Condition for an Eigenvalue Problem,” *SIAM J. Numer. Anal.* 32(4), 1263--1279 (1995) | [DOI](https://doi.org/10.1137/0732058)；peer-reviewed | 全文核验；[[ref/ref_data/Bonnet1995.pdf|ref_data/Bonnet1995.pdf]]；p. 13, Theorem 6.4 | exact Fourier boundary operator truncation下 guided eigenvalue/eigenspace superalgebraic a priori convergence | homogeneous-cladding fiber，不是 periodic lead；constants not computable a posteriori | 证明“guided eigenproblem + boundary approximation”有理论先例；不把 last difference 升格为 bound | `SOURCE-DIRECT`，current use 为近邻 |
| Jay Gopalakrishnan, Jacob Grosek, Gabriel Pinochet-Soto, Pieter VandenBerge, “Adaptive Resolution of Fine Scales in Modes of Microstructured Optical Fibers,” *SIAM J. Sci. Comput.* 47(1), B108--B130 (2025) | [DOI](https://doi.org/10.1137/24M1651605)；peer-reviewed OA | 全文核验；[[ref/ref_data/Gopalakrishnan2025.pdf|ref_data/Gopalakrishnan2025.pdf]] | PML-truncated Maxwell fiber eigenproblem、DWR FEM eigenvalue estimator、field refinement、independent semi-analytic effectivity benchmark | different vector Maxwell/fiber/PML problem；estimator covers fixed PML model, not PML truncation error | 说明 future effectivity 必须把 reference model error 与 FEM error 分开；不支持 current reference bound | `SOURCE-DIRECT` |
| Yingxia Xi, Bo Gong, Jiguang Sun, “Analysis of a Finite Element DtN Method for Scattering Resonances of Sound Hard Obstacles” (2024) | [arXiv 2404.09300](https://arxiv.org/abs/2404.09300)；preprint / later journal metadata in local catalog | 全文核验；[[ref/ref_data/Xi2024.pdf|ref_data/Xi2024.pdf]]；pp. 4--13, Theorem 3.11 | holomorphic resonance NEP 的 DtN Fourier-tail + FEM spectral convergence | sound-hard resonance，不是 self-adjoint guided mode | transparent-boundary reference 可有 two-axis ladder；不可把 resonance theorem直接迁移 | `SOURCE-DIRECT` / `UNVERIFIED FOR CURRENT MODEL` |
| Lothar Nannen, Markus Wess, “Computing Scattering Resonances Using Perfectly Matched Layers with Frequency Dependent Scaling Functions,” *BIT Numer. Math.* 58, 373--395 (2018) | [DOI](https://doi.org/10.1007/s10543-018-0694-0)；peer-reviewed OA | publisher open full text/PMC 核验；本轮不新增 PDF | PML resonance eigenproblems can generate artificial/spurious resonances dependent on discretization and scaling | resonance setting，不是 real gap bound mode | PML candidate 必须额外做 parameter stability and spurious-mode filtering；因此不选主 reference | `SOURCE-DIRECT` for caveat |

## Plane-wave、公开实现与替代 exact-cladding 方法

| 来源身份 | DOI / 类型 | 核验状态 | 直接支持 | 匹配与限制 | I4.1 决定 | 状态 |
|---|---|---|---|---|---|---|
| Richard A. Norton, Robert Scheichl, “Planewave Expansion Methods for Photonic Crystal Fibres,” *Appl. Numer. Math.* 63, 88--104 (2013) | [DOI](https://doi.org/10.1016/j.apnum.2012.09.008)；peer-reviewed；[University of Bath record/AAM](https://researchportal.bath.ac.uk/en/publications/planewave-expansion-methods-for-photonic-crystal-fibres) | institutional AAM and metadata available；本轮未新增 PDF | discontinuous coefficients limit eigenfunction regularity and prevent exponential PWE convergence；regularization not automatically beneficial | compact fiber cross-section, not line defect | PWE/MPB only auxiliary unless a resolution ladder demonstrates sharp-interface stability | `SOURCE-DIRECT` |
| Aurélien David, Henri Benisty, Claude Weisbuch, “Fast Factorization Rule and Plane-Wave Expansion Method for Two-Dimensional Photonic Crystals with Arbitrary Hole-Shape,” *Phys. Rev. B* 73, 075107 (2006) | [DOI](https://doi.org/10.1103/PhysRevB.73.075107)；peer-reviewed | publisher identity and abstract核验；full text未纳入 local corpus | modified Fourier factorization improves slow convergence caused by field discontinuities; includes waveguide supercells | operator/polarization mapping not checked | supports PWE caveat/possible remedy only | abstract `SOURCE-DIRECT`; current method `UNVERIFIED` |
| MIT Photonic Bands (MPB), official manual and user interface | [official documentation](https://mpb.readthedocs.io/en/stable/)；software documentation | official public documentation verified；无论文 PDF 新增 | computes periodic dielectric eigenfrequencies and eigenfields; supports field output, resolution, mesh, tolerance, symmetries and targeted solve | fully vectorial Maxwell software; current scalar polarization mapping and circle subpixel treatment not frozen | public independent implementation candidate, but only auxiliary until exact weak-form mapping and target-independent selection are checked | `SOURCE-DIRECT` for capabilities; `UNVERIFIED FOR CURRENT MODEL` |
| S. Wilcox, L. C. Botten, R. C. McPhedran, C. G. Poulton, C. Martijn de Sterke, “Modeling of Defect Modes in Photonic Crystals Using the Fictitious Source Superposition Method,” *Phys. Rev. E* 71, 056606 (2005) | [DOI](https://doi.org/10.1103/PhysRevE.71.056606)；peer-reviewed；[PubMed](https://pubmed.ncbi.nlm.nih.gov/16089667/) | identity and official abstract verified；未保存来源不明 PDF | infinite cladding, fictitious sources, quasiperiodic response fields and Bloch-mode one-dimensional averaging; targets extended modes near cutoff | likely needs cylinder multipole/Bloch infrastructure and current-parameter implementation; shares modal/infinite-cladding ideas with current chain | substantive backup, not selected due implementation/evidence/independence ambiguity | abstract `SOURCE-DIRECT`; current fit `UNVERIFIED` |

## Published benchmark/data 核验

### 结果

`NO EXACT-PARAMETER PUBLIC BENCHMARK FOUND`。

检索未发现同时满足 period $1$、$R=0.2$、background $1$、disk coefficient $17$、中心缺一整列、
fixed $\beta=0.5$、$u$ 与 $\partial_n u$ 连续的 transmission 和同一频率归一化的公开 eigenvalue+field
data。以下既有来源只作方法族/数量级核验：

- Huang--Lu--Li (2007)，[[ref/ref_data/Huang2007.pdf|ref_data/Huang2007.pdf]]：line-defect
  DtN 但固定频率求 Bloch wavenumber，且 geometry/contrast 不同。
- Giani (2013)：removed-column line defect，但 coefficients、polarization 和 published target
  不同。
- Fliss/Klindworth numerical examples：continuous profile/lattice 与 current sharp disks 不同。

因此这些数据不得参与 I4.1 root selection 或 future effectivity denominator。

## 访问障碍

| 来源 | 障碍 | 已核验层级 | 对方法选择的影响 |
|---|---|---|---|
| Soussi (2005；online 2006), DOI `10.1137/040616875` | SIAM publisher full text closed (`Get Access`)；未找到可确认合法的作者/机构全文 | identity、卷页、DOI、publisher abstract | 不阻止选择 empirical supercell reference；阻止声称其 theorem 已逐假设覆盖 current fixed-$\beta$ line-defect operator 或提供可用 constant |
| Petropoulos--Turc (2025), DOI `10.1098/rsta.2024.0355` | 既有 Phase 2 检查未取得合法公开 PDF | publisher/institution metadata and abstract | 只影响 BIE-RtR 近邻细节；因其并非主 FEM route，不改变选择 |
| 部分 PWE/PML publisher versions | publisher PDF closed；author/institution abstract/AAM availability varies | authoritative metadata/abstract；只对有限 claim 使用 | 已有核心全文足以比较；不以未核验细节支持主选择 |

## 跨来源依赖图

1. **Continuous identity**：Fliss (2013) + current project physical specification。
2. **Selected finite problem**：Fliss (2013) supercell interpretation + Giani (2013) line-defect
   conforming FEM + current mapping $A=I$, $B=q$。
3. **Mode identification**：Fliss exponential decay + Soussi abstract-level twist quasi-independence +
   Giani field localization；对 current geometry 的组合是 `CROSS-SOURCE INFERENCE`。
4. **Resolution boundary**：Giani rich-space reference + Klindworth supercell/RtR comparison +
   Soussi convergence abstract；共同支持 refinement ladder，不共同产生 certified upper bound。
5. **Counterevidence**：Cancès et al. 的 gap pollution warning、Nannen--Wess 的 PML spurious
   modes、Norton--Scheichl 的 sharp-interface PWE limit。

以上依赖中没有一项直接证明未来任一 branch 的最细 level 误差被
$\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$ 包住；这些量只能是 observed resolution descriptors。
