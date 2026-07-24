# Search log

Search cutoff: **2026-07-20** (Asia/Shanghai). Queries were executed against
general scholarly web search and then checked against journal, DOI, arXiv, HAL,
or author pages. Search snippets were used only for discovery.

## Repository and corpus discovery

| Date | Query / route | Main result | Decision |
|---|---|---|---|
| 2026-07-20 | `find`/`rg` over draft-like files and `ref/*.pdf` | Located `draft/draft.tex`/PDF, four older `pre/` families, and 13 local PDFs | Selected `draft/draft.tex` by timestamp and content; read all local PDFs at least at introduction/problem/main-result/numerics/conclusion level |

## A. Line-defect guided modes

| Date | Actual query (variants grouped only when the intent was identical) | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `photonic crystal line defect guided modes eigenvalue exact computation`; `periodic line defect waveguide guided mode computation` | Ammari--Santosa (2004); Fliss (2013); Klindworth--Schmidt--Fliss (2014); Fliss--Klindworth--Schmidt (2015) | Included. These directly address existence or exact numerical computation. |
| 2026-07-20 | `line defect periodic medium nonlinear eigenvalue problem guided modes`; `defect modes periodic waveguide Dirichlet-to-Neumann` | Same DtN chain plus supercell literature | Bulk-band and point-defect results retained only as method comparisons. |
| 2026-07-20 | `exact computation guided modes photonic crystal waveguide`; `line defect photonic crystal guided modes FEM supercell multipole scattering matrix PML` | Exact DtN method and FEM implementation; supercell methods are accurate mainly for well-confined modes | Included direct papers; excluded device-design papers with no eigenproblem details. |

## B. Transparent boundary, DtN, propagation, RtR

| Date | Actual query | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `Dirichlet-to-Neumann periodic half guide`; `exact boundary conditions periodic waveguide` | Joly--Li--Fliss (2006), Fliss--Joly (2009), Coatléven (2012), Fliss (2013) | Included; separated absorbed scattering from lossless guided modes. |
| 2026-07-20 | `propagation operator periodic waveguide Riccati`; `cell propagation operator guided modes` | Compact propagation operator and stationary Riccati construction already explicit in the Joly/Fliss chain | Included; this construction is not new in the draft. |
| 2026-07-20 | `Robin-to-Robin periodic waveguide guided modes`; `Robin-to-Robin transparent boundary conditions guided modes photonic crystal wave-guides`; `forbidden frequencies periodic waveguide Robin-to-Robin` | Fliss--Klindworth--Schmidt, BIT 55 (2015), 81--115, DOI 10.1007/s10543-014-0521-1 | Included. It removes the countable DtN forbidden-frequency obstruction in the guided-mode computation. |
| 2026-07-20 | `transparent boundary condition photonic crystal line defect` | DtN/RtR chain and Bloch-wave scattering truncations | PML-only engineering papers excluded unless they supplied convergence or band-edge evidence. |

## C. Boundary integral methods

| Date | Actual query | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `boundary integral guided modes photonic crystal waveguide`; `boundary element line defect photonic crystal eigenvalue` | No verified paper found that exactly combines a Müller interface-only central-cell BIE with periodic-half-guide DtN/RtR for the Fliss line-defect eigenproblem | This is an evidence-qualified gap, not a priority claim. Photonic-crystal-fiber BEM mode solvers are a different geometry. |
| 2026-07-20 | `Muller integral equation periodic waveguide guided mode`; `boundary integral nonlinear eigenvalue photonic crystal` | Barnett--Greengard (2010) for bulk bands; 2024 EABE photonic-crystal-fiber BEM NEP paper; Hiptmair--Moiola--Spence (2022) on spurious BIE quasi-resonances | Included as formulation/algorithm prior art, not as direct line-defect solutions. |
| 2026-07-20 | `boundary integral DtN photonic crystal unit cell`; `scattering matrix boundary integral guided modes` | Yuan--Lu--Antoine (2008) constructs unit-cell DtN maps by BIE; earlier transfer/scattering/DtN band formalisms are summarized there | Included. It makes “replace FEM by BIE” alone too weak. |
| 2026-07-20 | `Müller photonic crystal band structure boundary integral`; `line defect boundary integral photonic crystal guided modes` | Barnett--Greengard exact QP Müller equivalence and high-order BIE band calculations | Direct overlap with Theorem 2 proof and singular-value detection; geometry remains bulk, not line defect. |

## D. Bloch modes and modal completeness

| Date | Actual query | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `Bloch mode expansion periodic waveguide completeness`; `Floquet modes completeness periodic waveguide`; `operator pencil periodic waveguide modes` | Hohage--Soussi (2013), Theorem 2.2: Riesz basis and infinite Jordan form | Included and treated as decisive against ordinary-eigenvector-only completeness. |
| 2026-07-20 | `generalized eigenfunctions periodic waveguide DtN`; `stable subspace Bloch modes periodic half guide` | Zhang (2021) generalized spectrum decomposition; Zhang (2023) generalized-eigenfunction DtN with exponential truncation and FEM error estimate | Included; closest forward developments to Conjecture 1 and stable-trace truncation. |
| 2026-07-20 | `Keldysh theorem waveguide mode completeness` | Keldysh-based density/completeness results for closed electromagnetic waveguides, e.g. Halla--Monk (2024) | Context only: different closed full-Maxwell guide, not direct line-defect prior art. |

## E. TE and discontinuous principal coefficients

| Date | Actual query | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `TE photonic crystal line defect guided modes`; `divergence form line defect photonic crystal`; `discontinuous coefficient line defect waveguide spectrum` | Brown--Hoang--Plum--Radosz--Wood (2017), JLMS 95, 942--962; multiband arXiv:1901.05102 | Included. These explicitly allow discontinuous divergence-form coefficients and prove weak-defect gap localization. |
| 2026-07-20 | `weighted normal derivative transmission photonic crystal waveguide`; `boundary integral TE photonic crystal` | Yuan--Lu--Antoine (2008) treats E/H polarizations in unit-cell DtN; weighted transmission conditions are standard in BIE form | Included as evidence that TE coefficient weighting alone is not a primary novelty. |

## F. Difficult spectral regimes

| Date | Actual query | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `band edge guided modes photonic crystal waveguide numerical`; `poorly confined guided mode supercell convergence photonic crystal` | Fliss (2013) exponential-decay estimate; Klindworth--Schmidt--Fliss (2014) comparison showing supercell deterioration; RtR 2015 includes near-band-edge modes | Included; a new study must add controlled BIE/modal errors or a genuinely harder threshold regime. |
| 2026-07-20 | `embedded eigenvalue periodic line defect`; `bound state in continuum line defect photonic crystal` | Many physics/design papers, few matching the draft's scalar half-guide setting | Not used for novelty conclusions without a matching operator formulation. |
| 2026-07-20 | `leaky modes periodic line defect complex resonance`; `line defect resonance photonic crystal complex frequency` | Resonance/PML/scattering-matrix literature exists, but no completed targeted chain to the draft's operator | Recorded as insufficiently searched; complex resonances remain candidate, not established novelty. |
| 2026-07-20 | `Wood anomaly guided modes periodic waveguide`; `unit-circle Bloch multipliers periodic waveguide` | Barnett--Greengard/Cho--Barnett robust scattering formulations and periodic radiation-condition theory | The draft excludes Wood anomalies; handling them would require a different representation and spectral theory. |

## G. Numerical nonlinear eigenvalue methods

| Date | Actual query | Principal verified results | Exclusions / decision |
|---|---|---|---|
| 2026-07-20 | `nonlinear eigenvalue problem guided modes photonic crystal`; `smallest singular value scan nonlinear eigenvalue periodic waveguide`; `smallest singular value photonic crystal band structure boundary integral` | Barnett--Greengard (2010) explicitly proposes scanning the smallest singular value; Fliss/Klindworth use fixed-point/Newton/Chebyshev approaches | Grid scanning is established heuristic practice, not a contribution. |
| 2026-07-20 | `contour integral nonlinear eigenvalue photonic crystal`; `Sakurai Sugiura guided modes`; `Beyn method photonic crystal eigenvalue` | Brennan--Embree--Gugercin (2023) review; Binkowski--Zschiedrich--Burger (2020); Lyu--Li--Lin (2025) semi-infinite photonic crystals | Included. Contour integration is mature; novelty could lie in a certified operator/BIE coupling and physical residual filter. |
| 2026-07-20 | `Beyn nonlinear eigenvalue boundary element photonic`; `contour integral guided mode nonlinear eigenvalue waveguide` | 2024 EABE photonic-crystal-fiber BEM NEP comparison and general BEM contour papers | Different geometry but strong algorithmic prior art. |

## MFS / quasiperiodic Green-function supplementary searches

| Date | Actual query | Principal verified results | Decision |
|---|---|---|---|
| 2026-07-20 | `quasiperiodic Green function method of fundamental solutions proxy sources Rayleigh expansion`; `three-cell quasiperiodic Green function proxy sources` | Luan--Sun--Zhuang (2019); Barnett--Greengard (2010); Cho--Barnett near/far method; Cho (2019) 3-D MFS periodization | Included as method prior art. |
| 2026-07-20 | `near-field proxy sources quasiperiodic Green function`; `robust integral equation quasi-periodic scattering proxy points Barnett` | Immediate-neighbor free-space sources plus proxies and Rayleigh matching predate the draft; Cho--Barnett explicitly use left/right neighbors and Schur complements | The three-cell idea alone is a straightforward extension unless accompanied by a new stability/error theorem or new regime. |

## Backward citation chaining

| Seed | References followed | Finding |
|---|---|---|
| Joly--Li--Fliss (2006) | earlier exact boundary, propagation, and periodic-guide work cited in Sections 1, 4--6 | Confirms propagation/Riccati roots; its Remark 5.1 is the completeness question later solved by Hohage--Soussi. |
| Fliss (2013) | Ammari--Santosa (existence), Joly/Fliss exact conditions, supercell theory, band-gap spectral references | Confirms exact bounded nonlinear DtN equivalence and distinguishes well-confined from poorly confined modes. |
| Barnett--Greengard (2010) | Müller transmission BIEs, QP Green functions, proxy/periodization and transfer/scattering/DtN band methods | Confirms Theorem 2's proof architecture and smallest-singular-value scan are established for bulk band structure. |
| Brown et al. (2017) | TM weak-defect results, Floquet/negative Sobolev tools, Maxwell gap results | Confirms TE/discontinuous divergence-form line-defect spectral theory is already substantive. |
| Yuan--Lu--Antoine (2008) | earlier unit-cell DtN, transfer and scattering matrices | Confirms interface-only computation of cell DtN for arbitrary cylinder shapes predates the draft. |

## Forward citation chaining

| Seed | Later works checked | Finding |
|---|---|---|
| Joly--Li--Fliss (2006) | Fliss--Joly (2009), Coatléven (2012), Fliss (2013), Hohage--Soussi (2013), Zhang (2023) | Evolution from absorbed propagation to exact guided-mode DtN and generalized modal DtN. |
| Fliss (2013) | Klindworth--Schmidt--Fliss (2014); Fliss--Klindworth--Schmidt (2015); Zhang (2023); Lyu--Li--Lin (2025) | FEM implementation, Newton/Chebyshev solve, group velocity, RtR removal of forbidden frequencies; later modal/contour alternatives. No verified Müller line-defect BIE equivalent was found. |
| Barnett--Greengard (2010) | Cho--Barnett (2015), Liu--Barnett (2016), Cho (2019), later robust periodic solvers | Near-neighbor plus proxy/free-space periodization and Wood-robust techniques are mature. |
| Hohage--Soussi (2013) | Zhang (2021, 2023) | Generalized eigenfunction decomposition is turned into an explicit DtN approximation with exponential modal truncation. |
| Yuan--Lu--Antoine (2008) | recursive-doubling and extended-device DtN work cited by Zhang (2023) | Cell DtN and propagation/scattering computations are established; a new contribution needs coupling, certification, or a new spectral regime. |

## External BibTeX verification sources

External bibliography entries in `report/references.bib` were checked against:

- SIAM article pages/DOI records for Fliss (2013), Ammari--Santosa
  (2004), Zhang (2021, 2023), Dohnal--Schweizer (2018), and the contour
  NEP review;
- Springer DOI metadata for Fliss--Klindworth--Schmidt (2015);
- Elsevier/ScienceDirect records for Yuan--Lu--Antoine (2008),
  Klindworth--Schmidt--Fliss (2014), Barnett--Greengard (2010),
  Luan--Sun--Zhuang (2019), Binkowski et al. (2020), and Lyu et al.
  (2025);
- Wiley DOI metadata for Brown et al. (2017);
- arXiv original records when no verified journal version was used.

## Exclusion rules and residual uncertainty

- Bulk band-structure papers are not counted as solving the line-defect
  eigenproblem, though their cell BIE and scanning constructions are prior art.
- Forced scattering papers are method prior art, not guided-mode theorems.
- Point defects, fibers, slabs, closed guides, and full-Maxwell guides are marked
  as different geometries rather than silently conflated.
- Device-design papers without reproducible operator or convergence details were
  excluded from the direct set.
- For complex resonances, Wood anomalies, and a general lossless Cauchy-relation
  theory, the search is insufficient to support a priority claim. The correct
  wording is: **截至本次检索尚未发现直接重合工作，但现有证据不足以断言该方向为首次提出。**
