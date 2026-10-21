# I4.1 文献检索记录

状态：`FORMAL SEARCH COMPLETE FOR METHOD DRAFT`
检索日期：2026-08-28
协议：[[research/projects/eig-apost/implementation/i4/search-plan|I4.1 frozen search plan]]

本文件采用追加式记录。平台若不提供稳定的总命中数，则只报告实际返回并人工筛查的
result set，不把搜索引擎估算数伪装成 PRISMA 总数。搜索摘要只用于发现；进入
[[research/projects/eig-apost/implementation/i4/sources|I4.1 source matrix]] 的关键方法主张均另行回到
本地全文、publisher/DOI 页面、作者 AAM、institutional repository 或官方软件文档核验。

## 2026-08-28 — 本地证据优先筛查

### 平台与查询

- 平台：repository `rg`、`ref/README.md`、`ref/reference.bib`、本地 PDF；PDF 文本只读提取使用
  Ghostscript `txtwrite`，没有运行数值程序。
- 查询族：`supercell`、`line defect`、`guided mode`、`finite element`、`DtN`、`RtR`、
  `PML`、`plane wave`、`effectivity`、`reference`、`localization`、`spurious`。
- 起点：[[research/projects/eig-apost/phase2-sources/r-sources|Phase 2 source verification]]、
  [[research/projects/eig-apost/phase2b-novelty/r-sources|Phase 2b source verification]]、
  [[research/projects/eig-apost/phase2-sources/search-log|Phase 2 search log]]。

### 命中与筛选

- 实际检查 I4.1 直接相关本地全文 13 篇：Fliss (2013)、Fliss--Klindworth--Schmidt
  (2015)、Klindworth (2015)、Giani (2013)、Bonnet-Ben Dhia--Gmati (1995)、
  Coatléven (2012)、Joly--Li--Fliss (2006)、Huang--Lu--Li (2007)、
  Gopalakrishnan et al. (2025)、Engström--Giani--Grubišić (2016)、
  Xi--Gong--Sun (2024)、Li--Lu (2007) 和 Yu--Hu--Lu--Rathsfeld (2022)。
- 核心纳入：Fliss (2013) 的 fixed-quasimomentum continuous problem、gap 内指数衰减和
  supercell 边界；Fliss et al. (2015)/Klindworth (2015) 的 high-order FEM、RtR 和
  supercell confinement 比较；Giani (2013) 的 line-defect supercell FEM、field、
  residual refinement 和 rich-space reference；Bonnet-Ben Dhia--Gmati (1995) 的 guided
  eigenproblem exact-boundary truncation 先验近邻。
- 后备纳入：PML/DWR、DtN-FEM 和公开 PWE 实现只用于比较、失败模式或 future cross-check，
  不直接支持主 reference 的误差界。
- 排除：同一 BIE/QZ chain 的加密、参数不匹配的 published number、只求 fixed-frequency
  Bloch wavenumber 且不能反解 fixed-$\beta$ 对象的路线。

### 原文核验位置

- Fliss (2013)：PDF pp. 6--9 的 supercell discussion、Theorem 3.5 和 gap 内指数衰减；
  pp. 11--20 的 half-guide DtN 与 FEM construction。
- Fliss--Klindworth--Schmidt (2015)：PDF pp. 1--6 的问题/RtR 定义；pp. 25--31 的
  nonlinear solve、DtN failure 和 RtR comparison。
- Klindworth (2015)：Chapter 4 的 supercell formulation/limitations，Chapters 6--7 的
  high-order FEM DtN/RtR；PDF pp. 102--104 的 rich/reference comparison；p. 153 的
  unclosed numerical-analysis limitation。
- Giani (2013)：PDF pp. 2--10 的 variational FEM/residual estimator；p. 11 的
  rich-space reference/effectivity；pp. 15--16 的 removed-column line-defect supercell；
  pp. 18--19 的 finite-rectangle/Dirichlet truncation limitation。

### 获取状态

- 以上核心全文已经是合法公开/作者/机构副本并在 `ref/ref_data/` 中完成既有身份核验；
  本轮只链接，没有复制证据卡，也没有新增 PDF。
- Soussi (2005；Crossref online 2006) 仍只有 SIAM DOI/正式摘要和权威元数据可访问；publisher full text closed。

## 2026-08-28 — Query family A：FEM、supercell 与 transparent boundary

### 实际查询

平台：通用 web academic search，结果回到 SIAM、ScienceDirect、Springer、arXiv 或作者/机构页。

```text
"photonic crystal waveguide" "guided modes" finite element DtN eigenvalue fixed beta
"periodic waveguide" guided mode finite element PML eigenvalue convergence
Soussi supercell convergence defect modes photonic crystal 10.1137/040616875
"photonic crystal waveguide" plane wave expansion guided mode convergence sharp interface
```

### 命中与筛选

- 返回结果中筛查 18 个研究/出版页面，去除重复和非 eigenmode scattering 页面后保留 6 个
  实质记录。
- 纳入 Fliss/Klindworth 的 FEM-DtN 原文页面和 Soussi DOI 元数据。
- 排除 waveguide-bend scattering、只报告 device transmission 的 PWE 应用和无法匹配
  continuous operator 的工程设计论文。
- ScienceDirect 的 Fliss/Klindworth numerical-realization 页面直接说明：supercell 对弱局域
  mode 成本高；DtN 将无界问题化为 bounded NEP；high-order FEM 用于离散。该页面与本地全文
  身份一致。

### 获取与障碍

- Fliss/Klindworth 全文已有本地作者/公开副本。
- Soussi DOI `10.1137/040616875`：publisher 页面为 `Get Access`；未绕过 paywall，
  没有下载 PDF。正式摘要只支持 exponential supercell convergence 和 background
  supercell-eigenvalue characterization，不支持本项目的具体 constants 或 field threshold。

## 2026-08-28 — Query family B：反例、spectral pollution、PML 与 sharp-interface PWE

### 实际查询

```text
supercell method defect modes photonic crystal spectral pollution spurious eigenvalues
PML eigenvalue problem spurious modes spectral pollution photonic crystal waveguide FEM
plane wave expansion discontinuous dielectric photonic crystal convergence Gibbs Fourier factorization
2021 2022 2023 2024 2025 finite element guided modes periodic photonic crystal waveguide fixed quasi momentum
site:epubs.siam.org PML eigenvalue problem spurious eigenvalues waveguide modes
site:link.springer.com PML eigenvalue problem spurious modes waveguide
site:arxiv.org perfectly matched layer eigenvalue spurious modes photonic crystal
"spurious modes" "perfectly matched layer" eigenvalue
```

### 命中与筛选

- 两组返回结果共筛查 24 个研究页面；保留 8 个与失败模式直接相关的 primary/authoritative
  records。
- Cancès--Ehrlacher--Maday (2012) 区分 ordinary finite-section Galerkin 的 gap pollution 与
  supercell no-pollution result；其对象为 periodic Schrödinger/local defect，故只作理论近邻，
  不直接替代 line-defect fixed-$\beta$ 证明。
- Nannen--Wess (2018) 直接研究 complex-scaled/PML resonance eigenproblem 的 artificial
  eigenvalues；该反例不是 projected-gap bound-mode theorem，但足以阻止把 PML spectrum
  不加筛查地当主 reference。
- David--Benisty--Weisbuch (2006)、Shen--He (2002) 和 Norton--Scheichl (2013) 均指出
  discontinuous coefficients 下 naive PWE 的 slow convergence/formulation sensitivity；
  Norton--Scheichl 的 institution page 提供合法 AAM，并明确 trapped modes 的 convergence
  受 eigenfunction regularity 控制。
- 没有发现会把 PML 或 unmodified PWE 提升到主路线、或否定 fitted FEM supercell 候选的
  新证据。

### 获取与障碍

- Cancès et al. 的 arXiv `1111.3892` 为公开全文；本轮不需新增本地 PDF。
- Norton--Scheichl 的 University of Bath 页面提供 accepted manuscript；只使用 institutional
  元数据与正文级已公开结论，不新增 PDF。
- 部分 PWE/PML publisher PDFs closed；只使用 publisher 摘要或已有公开全文，不绕过权限。

## 2026-08-28 — Query family C：完全匹配 benchmark/data

### 实际查询

```text
"radius" "0.2" "permittivity" "17" photonic crystal waveguide missing row
"beta=0.5" "photonic crystal waveguide" guided mode
"missing column" rods "17" photonic crystal guided mode
"sqrt(17)" photonic crystal waveguide Helmholtz
```

### 命中与筛选

- 筛查返回的 16 个页面；0 个同时匹配 period $1$、$R=0.2$、coefficient $17$、center
  missing column、fixed $\beta=0.5$、当前 scalar transmission operator 和频率归一化。
- 部分页面只匹配 `radius 0.2`，但 permittivity 为 `11.56`；另一些 `17` 是频率或无关参数。
  全部排除为 I4.1 reference data。
- 结论：没有可核验的 exact-parameter public benchmark。Huang--Lu--Li、Giani 等 published
  values 只能验证方法族或数量级，不能成为当前 model 的 reference eigenpair。

## 2026-08-28 — Query family D：公开实现与 cross-reference

### 实际查询

```text
site:readthedocs.io meep MPB photonic crystal waveguide line defect mode solver documentation
site:github.com NanoComp mpb photonic crystal waveguide line defect example
site:mit.edu MPB photonic crystal waveguide tutorial line defect
MIT Photonic Bands MPB official manual targeted eigensolver defect modes
```

### 命中与筛选

- 筛查 10 个 official/manual/example pages；纳入 MPB official manual/user-interface pages。
- MPB 官方说明支持 periodic dielectric eigenvalues 和 eigenfields、targeted eigensolver、field
  output、resolution/mesh/tolerance axes，适合形成 independent PWE auxiliary check。
- `target-freq` 只能在未来由 reference-own preregistration 决定，不能用当前 $\widehat k_h$
  自动选最近 root；这是信息隔离条件，不是 MPB 自带保证。
- 由于 scalar polarization weak form、circle representation 和 sharp-interface resolution 仍需
  项目级核对，MPB 不选作主 reference。

## 2026-08-28 — backward/forward citation 与近五年更新

### 实际查询

```text
"A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes" citing 2020 2021 2022 2023 2024
"Robin-to-Robin transparent boundary conditions" photonic crystal guided modes citing
"Convergence of the Supercell Method" photonic crystals line defect follow-up finite element
"photonic crystal wave-guide" guided modes transparent boundary finite element 2024
photonic crystal line defect guided mode spectral element finite element independent benchmark
fictitious source superposition guided defect modes photonic crystal exact method line defect
periodic line defect guided mode boundary element independent finite difference eigenvalue
photonic crystal line defect eigenmode finite difference frequency domain convergence benchmark
```

### 命中与筛选

- 两轮返回结果共筛查 27 个页面；保留 7 个实质来源或方法记录。
- 找到 Wilcox et al. (2005) FSS infinite-cladding method、Kim--Kwon (2015) one-dimensional
  supercell convergence、若干 cavity cross-method benchmarks；它们拓宽候选，但没有比
  fitted FEM supercell 更好地同时匹配 current scalar line defect、实现可得性与信息隔离。
- FSS 依赖 quasiperiodic response/Bloch-mode machinery，且 exact current-parameter public
  implementation/data 未发现；保留后备，不作主路线。
- 近五年结果主要集中于 resonance/PML、scattering 或不同 Maxwell geometry；没有改变主选择。
- 连续两轮新增查询均未产生会改变主路线或 blocker 分类的方法，满足 frozen plan 的停止条件。

## 2026-08-28 — 元数据定向核验

```text
"Planewave expansion methods for photonic crystal fibres" DOI Norton Scheichl
"Numerical realization of Dirichlet-to-Neumann transparent boundary conditions" DOI authors
"Modeling of defect modes in photonic crystals using the fictitious source superposition method" DOI
"Periodic Schrödinger operators with local defects and spectral pollution" DOI
```

- Norton--Scheichl：*Applied Numerical Mathematics* 63 (2013), 88--104，DOI
  `10.1016/j.apnum.2012.09.008`；University of Bath AAM 可公开下载。
- Fliss--Klindworth numerical realization：*Computers & Mathematics with Applications*，DOI
  `10.1016/j.camwa.2013.03.005`；本地 thesis/journal source chain 可核对全文细节。
- Wilcox et al.：*Physical Review E* 71, 056606 (2005)，DOI
  `10.1103/PhysRevE.71.056606`；PubMed 核验身份和摘要。
- Cancès--Ehrlacher--Maday：*SIAM Journal on Numerical Analysis*，DOI
  `10.1137/110855545`；公开 arXiv `1111.3892`。

## 检索流与停止记录

```text
外部 query strings：32
人工筛查的返回页面：约 95（同一 DOI/论文页面去重前）
本地直接相关全文检查：13
I4.1 source matrix 纳入/后备/失败证据：14
exact-parameter public benchmark：0
本轮新增 PDF：0
closed-access key source：Soussi (2005；online 2006)；Petropoulos--Turc (2025) 仅属非主线近邻
```

该计数是可复查的 scoped search log，不声称穷尽所有数据库。停止原因是五个预注册方法族均已
覆盖、主路线已有可写的 mathematical formulation、两轮补充检索未改变选择、反面证据与
访问障碍均已记录。停止检索不授权 experiment design 或 computation。

## 2026-08-28 — Skeptic 后的元数据更正

本节只更正已核验来源身份；没有新增 query、来源、下载或内容主张。

- Soussi 的卷期引用采用 SIAM print year 2005：*SIAM J. Numer. Anal.* 43(3), 1175--1201；
  Crossref online year 为 2006。上文的双年份标记均指同一 DOI `10.1137/040616875`。
- Cancès--Ehrlacher--Maday 更正为 *SIAM J. Numer. Anal.* 50(6), 3016--3035 (2012)，DOI
  `10.1137/110855545`。
- Nannen--Wess 的 DOI 更正为 `10.1007/s10543-018-0694-0`。
