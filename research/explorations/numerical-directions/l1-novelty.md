# L1 novelty check

L1 has a plausible contribution as a computable enclosure algorithm for the dielectric guide. The gap inequality, source-problem lifting, and Rayleigh-quotient perturbation arguments already have close precedents. The combination still to establish is the explicit finite-to-continuous error budget for this reconstruction, with a second-order enclosure whose accuracy and cost improve on the existing first-order bound. This survey found no complete implementation and refinement demonstration of that combination in the stated setting.

The verdicts below refer to each **full component in the stated dielectric-strip setting**. “Partial” identifies both the existing ingredient and the remaining application or analysis; it does not make the existing ingredient a novelty claim. In particular, the abstract theorem required for C1 already applies unchanged to the selfadjoint strip operator, under Paper 1's assumed spectral isolation.

## 1. Component verdicts

| Component | Verdict | Closest sources and locations | Finding |
|---|---|---|---|
| **C1: two-sided enclosure inside an essential spectral gap of the periodic line-defect operator** | **Partial** | [S1], Theorem 10.8, printed pp.356–357; Theorems 10.10 and 10.29, pp.357–360 and 386–388. [S2], Corollary 2.6, PDF p.7, and §3.3, pp.11–14. | The selfadjoint gap theorem is already available verbatim, including essential spectrum below and above. Numerical periodic Schrödinger gap applications also exist. An implementation for the specified mass-weighted, quasiperiodic strip with different leads was not located. |
| **C2: numerical FEM field lifted into the operator domain, with reliable residual control** | **Partial** | [S1], §10.2.2, Eq.(10.52) and Theorem 10.21, pp.374–377; Example 10.27, pp.381–383. [S11], Theorem 2.1 and Eqs.(8)–(9), author-preprint pp.3–6. | Inverse source problems and FEM/flux inclusion machinery already exist, including unbounded elliptic domains. L1 still needs the particular constant-coefficient source solve for its truncated FEM+DtN input and a computable strong-residual budget on the whole strip. |
| **C3: finite representation to exact reconstructed Rayleigh quotient, controlled in energy norm** | **Partial** | [S1], Remark 10.22(b), pp.376–377; Lemma 10.25, p.380, and Remark 10.26, p.381. [S12], Theorem 3.7, PDF p.6. | Guaranteed control of unknown source-solution Gram quantities and mixed residual/vector Rayleigh perturbation bounds are existing ingredients. The specific Fourier/source approximation and tail bounds for transferring the computed quotient of \(w_d\) to that of \(w\) were not located. |
| **C4: second-order guaranteed gap enclosure with bounded effectivity under refinement, demonstrated numerically** | **Partial** | [S7], Lemma 3.2, PDF p.7; [S8], Theorem 16, PDF pp.26–27; [S13], Theorem 5.3, PDF pp.24–25, and §6.1, pp.29–30. | Quadratic gap-enclosure convergence is proved; asymptotically exact effectivity is observed for guaranteed bounded-domain estimates. The full combination of guarantee, bounded actual-error effectivity, and refinement data for this unbounded periodic guide was not located. |
| **C5: lead band certification and exclusion of other spectrum** | **Partial — tools only** | [S31], Theorems 1–2, printed pp.1039–1040, and Theorem 7, p.1046; [S32], Theorem 6.1, prepublication pp.14–15; [S1], Remark 10.11(g), p.363. | Verified bulk gaps and one-dimensional periodic-gap exclusion are available. Counting all guide eigenvalues in the chosen strip gap requires an additional argument. Paper 1 may retain its explicit one-spectral-point assumption. |

**Search coverage:** queries combined “Plum Brown Hoang Wood Radosz” with waveguide/enclosure/computer-assisted proof, “spectral gap eigenvalue enclosure” with Lehmann–Goerisch/Zimmermann–Mertins/second-order spectrum, “Kato–Temple” with FEM/reconstruction/periodic/Schrödinger, “Rayleigh quotient” with energy error/source reconstruction, and “guaranteed a posteriori guided modes” with DtN/Fliss/Klindworth/Halla/Engström; full texts covered arXiv, KIT and author repositories, EMS, the local Springer books, and papers in IMA J. Numer. Anal., Numerische Mathematik, Math. Comp., SIAM journals, J. Phys. A, ZAMP, J. London Math. Soc., BIT, Computing, Computers & Mathematics with Applications, and Pure and Applied Analysis.

## 2. Sources and their actual scope

Locations marked “printed” use the publication's page numbers. “PDF p.” counts from the first page of the identified local or public manuscript. The numbering of the inspected version is used throughout. The local reference catalog supplies publication metadata; the statements below were checked in source text.

### S1. Nakao–Plum–Watanabe: the closest construction framework

Mitsuhiro T. Nakao, Michael Plum, and Yoshitaka Watanabe, *Numerical Verification Methods and Computer-Assisted Proofs for Partial Differential Equations*, Springer Series in Computational Mathematics **53**, Springer, Singapore, 2019. [Book DOI](https://doi.org/10.1007/978-981-13-7669-6). Inspected local `books/Nakao2019.pdf`, Chapter 10.

**Setting and result.** Theorem 10.8, printed pp.356–357, assumes a selfadjoint operator, a nonzero trial vector in its operator domain, and an open interval containing its Rayleigh quotient and exactly one spectral point. With quotient \(\theta\), normalized residual \(\delta\), and interval endpoints \(\alpha,\beta\), it gives

\[
\theta-\frac{\delta^2}{\beta-\theta}
\;\leq\;\lambda\;\leq\;
\theta+\frac{\delta^2}{\theta-\alpha}.
\]

There is no compact-resolvent or lowest-eigenvalue restriction. This is the theorem L1 needs, with the same isolation assumption. Theorems 10.10 and 10.29 give corresponding multiple-vector Lehmann and Goerisch bounds within intervals free of essential spectrum.

**Reconstruction and finite data.** Section 10.2.2, Eq.(10.52), printed p.375, explicitly starts with numerical vectors outside the associated operator domain and replaces them by inverse-source solutions inside that domain. Here the associated operator acts in the energy Hilbert space of the bilinear-form problem; this distinction matters when comparing its residual norm with L1's physical weighted \(L^2\) residual. Example 10.27, pp.381–383, specializes the construction to \(-\Delta u+cu=\lambda gu\) on a **bounded or unbounded** domain, with bounded coefficients and a coercive shift. Lemma 10.25, p.380, replaces the unknown source-solution Gram matrix by an admissible auxiliary Gram matrix. Its proof expresses the excess as a Gram matrix of auxiliary errors, hence quadratically in their norm. Theorem 10.29 turns those computable quantities into eigenvalue bounds in a gap.

**Remaining L1 work.** These are substantial prior parts of C1–C3. Bounded discontinuous weights and an unbounded domain alone do not distinguish L1 from this framework. The book supplies neither L1's constant-coefficient Fourier/Yukawa reconstruction from a hard-truncated \(L^2\) source nor its scalar finite-to-exact quotient transfer and refinement/cost analysis. Its concrete acoustic-waveguide example, Example 10.38, pp.404–406, uses homogeneous ends and a symmetry class whose target lies below the essential threshold; Table 10.2 encloses that target through a finite-domain lower comparison eigenvalue and a Dirichlet upper comparison eigenvalue at fixed truncation length.

### S2. Boulton–Levitin: the closest numerical periodic-gap application

Lyonell Boulton and Michael Levitin, “On Approximation of the Eigenvalues of Perturbed Periodic Schrödinger Operators,” *Journal of Physics A: Mathematical and Theoretical* **40**(31) (2007), 9319–9329. [DOI](https://doi.org/10.1088/1751-8113/40/31/010); [public manuscript](https://arxiv.org/pdf/math/0702420). Inspected local `Boulton2007.pdf`.

**Setting and result.** The operator is \(-\Delta+V_{\rm per}+V_{\rm defect}\) on \(\mathbb R^N\), with a localized defect in one periodic background. The quadratic projection uses numerical trial spaces in the operator domain. Corollary 2.5, PDF p.6, encloses spectrum by the real part of a quadratic root plus/minus its imaginary part; Corollary 2.6, p.7, sharpens localization quadratically when the target is isolated. Section 3.3, pp.11–14, computes internal-gap eigenvalue enclosures in **one and two dimensions**. Section 3.1, p.9, discusses compactly supported conforming trial functions with sufficient differentiability.

**Remaining L1 work.** The application has a localized Schrödinger potential defect, rather than a dielectric line-defect fibre with different periodic leads. It uses domain-conforming trials; L1 reconstructs FEM+DtN input. The inclusion theorem uses exact projected forms; the inspected numerical section supplies no interval treatment of matrix quadrature and rounding. Its examples leave C4's bounded actual-error effectivity under guide refinement unestablished.

### S3. Brown–Hoang–Plum–Wood: first-order waveguide spectral localization

B. Malcolm Brown, Vu Hoang, Michael Plum, and Ian G. Wood, “On Spectral Bounds for Photonic Crystal Waveguides,” in C. Bandle et al. (eds.), *Inequalities and Applications*, ISNM **157**, Birkhäuser, 2009, pp.23–30. [Chapter DOI](https://doi.org/10.1007/978-3-7643-8773-0_3). Inspected local `books/Bandle2009.pdf`, PDF pp.70–77, printed pp.23–30.

**Setting and result.** The operator is the divergence-form \(-\operatorname{div}(\epsilon^{-1}\nabla)\) on full space, with a homogeneous straight defect strip in a periodic medium. Section 3, Eq.(5), printed p.25, applies a Weinstein inclusion to the shifted inverse operator in \(H^{-1}\) and maps it back to an interval containing spectrum. Equation (6), pp.25–26, majorizes that defect using a trial function and an \(H(\operatorname{div})\) flux. Equations (7)–(8), p.26, choose a separated smooth trial supported inside the homogeneous strip and obtain analytic spectral localization. Section 4, pp.27–29, evaluates this construction with an explicit polynomial transverse trial.

**Remaining L1 work.** The chapter establishes a first-order spectral-set inclusion. It contains no FEM+DtN reconstructed trial, two-sided Kato–Temple refinement for an identified fibre eigenvalue, finite-to-exact Rayleigh transfer, or refinement effectivity study. Section 3 below corrects the earlier summary accordingly.

### S4. Zimmermann–Mertins: arbitrary essential spectrum

S. Zimmermann and U. Mertins, “Variational Bounds to Eigenvalues of Self-Adjoint Eigenvalue Problems with Arbitrary Spectrum,” *Zeitschrift für Analysis und ihre Anwendungen* **14**(2) (1995), 327–345. [DOI](https://doi.org/10.4171/ZAA/677); [public full text](https://ems.press/content/serial-article-files/34815?nt=1).

**Setting and result.** Theorem 1.1, printed pp.330–331, characterizes eigenvalues adjacent to a shift through inverse-residual variational quotients over operator-domain trial spaces. Theorems 1.3–1.4, pp.332–333, introduce complementary formulations associated with Goerisch's construction. Arbitrary essential spectrum is permitted; the method is designed for eigenvalues in spectral gaps.

**Remaining L1 work.** This supplies general enclosure machinery, including numerical trial spaces. The examples and constructions do not supply L1's periodic dielectric lead reconstruction, quotient-transfer error budget, or C4 refinement demonstration.

### S5. Davies–Plum: pollution-free localization and its Lehmann connection

E. B. Davies and Michael Plum, “Spectral Pollution,” *IMA Journal of Numerical Analysis* **24**(3) (2004), 417–438. [DOI](https://doi.org/10.1093/imanum/24.3.417); [public manuscript](https://arxiv.org/pdf/math/0302145).

**Setting and result.** For the paper's bounded selfadjoint operator and finite trial spaces, Theorem 10, PDF p.13, gives convergent upper and lower bounds for a single eigenvalue in an isolated interval using the approximate spectral-distance function. Theorem 11, pp.14–15, connects the optimized bounds with Lehmann/Zimmermann–Mertins bounds.

**Remaining L1 work.** The results control spectral pollution and enclosure, rather than the construction and certification of L1's continuous trial field. The periodic-guide source approximation and finite quotient transfer are absent.

### S6. Levitin–Shargorodsky: second-order relative spectrum

Michael Levitin and Eugene Shargorodsky, “Spectral Pollution and Second-Order Relative Spectra for Self-Adjoint Operators,” *IMA Journal of Numerical Analysis* **24**(3) (2004), 393–416. [DOI](https://doi.org/10.1093/imanum/24.3.393); [public manuscript](https://arxiv.org/pdf/math/0212087).

**Setting and result.** Definition 2.3, PDF p.8, takes trial spaces in the domain of a general selfadjoint operator. Theorem 2.5, p.9, guarantees spectrum in the interval centered at the real part of a second-order spectral point, with radius its imaginary part. Lemma 5.2, pp.24–25, excludes such points from a disk whose diameter is a spectral void. The examples include operators with essential spectrum and numerical discretizations.

**Remaining L1 work.** The source does not implement the dielectric strip problem or its reconstruction. The phrase “second-order spectrum” alone gives no bounded-effectivity statement for C4.

### S7. Boulton–Strauss: quadratic enclosure convergence in a gap

Lyonell Boulton and Michael Strauss, “Eigenvalue Enclosures and Convergence for the Linearized MHD Operator,” *BIT Numerical Mathematics* **52**(4) (2012), 801–825. [DOI](https://doi.org/10.1007/s10543-012-0389-x); [public manuscript](https://arxiv.org/pdf/1109.3588).

**Setting and result.** Lemmas 3.1–3.2, PDF p.7, give two-sided inverse-residual bounds when \([a,b]\) contains one discrete eigenvalue of a selfadjoint operator. If the eigenspace is approximated with graph-norm error \(\varepsilon_n\), Lemma 3.2 proves enclosure width \(O(\varepsilon_n^2)\). The applications are reduced MHD differential-operator systems with essential spectrum and numerical trial spaces.

**Remaining L1 work.** This is a direct precedent for quadratic gap-enclosure convergence. Its graph-norm approximation assumption and MHD discretization leave L1's reconstruction, certified finite-data errors, and actual-error effectivity on the dielectric guide to establish.

### S8. Barrenechea–Boulton–Boussaïd: local two-sided bounds

Gabriel R. Barrenechea, Lyonell Boulton, and Nabile Boussaïd, “Local Two-Sided Bounds for Eigenvalues of Self-Adjoint Operators,” *Numerische Mathematik* **135**(4) (2017), 953–986. [DOI](https://doi.org/10.1007/s00211-016-0822-1); [public full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC5445552/); [author PDF](https://strathprints.strath.ac.uk/56730/8/Barrenechea_etal_NM_2016_local_two_sided_bounds_for_eigenvalues_of_self_adjoint_operators.pdf).

**Setting and result.** Theorem 16, author-PDF pp.26–27, proves quadratic accuracy of local one-sided bounds from shifted graph-norm eigenspace approximation. The target interval contains only discrete spectrum; compact resolvent for the whole operator is unnecessary. Section 6 demonstrates the method with numerical Maxwell cavity trial spaces.

**Remaining L1 work.** The theorem already covers the abstract internal-gap issue. Its approximation parameter is a graph-norm error, rather than the actual error of L1's computed eigenvalue or quotient, and the numerical application is a bounded cavity.

### S9. Hinchcliffe–Strauss: a form-domain alternative for gap computation

James Hinchcliffe and Michael Strauss, “Spectral Enclosure and Superconvergence for Eigenvalues in Gaps,” *Integral Equations and Operator Theory* **84**(1) (2016), 1–32. [DOI](https://doi.org/10.1007/s00020-015-2247-0); [public manuscript](https://arxiv.org/pdf/1401.4066v3).

**Setting and result.** Theorems 4.6 and 5.3, PDF pp.14 and 20, prove squared eigenspace-approximation convergence for the nonselfadjoint perturbation approach \(A+iP\), including its Galerkin discretization. Example 6.2, p.25, uses compactly supported P1 FEM trial spaces for a perturbed periodic Schrödinger operator on \(\mathbb R\), with eigenvalues in internal gaps.

**Remaining L1 work.** This is an important alternative to demanding an operator-domain FEM trial directly. It supplies neither L1's scalar residual/Rayleigh transfer certificate nor its numerical guide effectivity study.

### S10. Boulton–Hobiny: convergence of the quadratic method

Lyonell Boulton and Aatef Hobiny, “On the Convergence of the Quadratic Method,” *IMA Journal of Numerical Analysis* **36**(3) (2016), 1310–1333. [DOI](https://doi.org/10.1093/imanum/drv036); [public manuscript](https://arxiv.org/pdf/1307.0313v2).

**Setting and result.** Theorem 2.3, PDF p.7, gives spectral inclusion from a quadratic projection root. Corollary 4.6, p.19, quantifies discretization and interval-truncation convergence for one-dimensional Schrödinger operators. Section 5, pp.20–25, computes enclosures and convergence rates for oscillator examples.

**Remaining L1 work.** The numerical examples use confining potentials. The source gives useful enclosure-convergence analysis, rather than an internal-gap periodic-guide demonstration with bounded actual-error effectivity.

### S11. Behnke–Mertins–Plum–Wieners: guaranteed FEM waveguide bounds

Henning Behnke, Ulrich Mertins, Michael Plum, and Christian Wieners, “Eigenvalue Inclusions via Domain Decomposition,” *Proceedings of the Royal Society of London A* **456** (2000), 2717–2730. [DOI](https://doi.org/10.1098/rspa.2000.0635); [public author full text](https://www.researchgate.net/publication/2484711_Eigenvalue_Inclusions_Via_Domain_Decomposition). The example is also reproduced in [S1], pp.404–406.

**Setting and result.** Theorem 2.1 and Eqs.(8)–(9), author-preprint pp.3–6, use conforming quadratic FEM fields and Raviart–Thomas fluxes for Goerisch inclusions with spectral separation. Section 4, pp.8–10, describes interval evaluation and verified small matrix problems. Section 4.1 proves enclosures for an infinite Neumann strip with a compact symmetric obstacle. Symmetry reduction puts its target below the remaining essential-spectrum threshold.

**Remaining L1 work.** This is already a guaranteed numerical enclosure on an unbounded waveguide. The ends are homogeneous, and the symmetry-reduced target lies below the essential bottom. Remark 2.5, pp.5–6, leaves optimal convergence order unproved. L1's periodic internal gap and finite source-reconstruction transfer are different tasks.

### S12. Zhu–Argentati–Knyazev: Rayleigh-quotient perturbation

Peizhen Zhu, Merico E. Argentati, and Andrew V. Knyazev, “Bounds for the Rayleigh Quotient and the Spectrum of Self-Adjoint Operators,” *SIAM Journal on Matrix Analysis and Applications* **34**(1) (2013), 244–256. [DOI](https://doi.org/10.1137/120884468); [public manuscript](https://arxiv.org/pdf/1207.3240v2).

**Setting and result.** For a bounded selfadjoint operator, Theorem 3.7, PDF p.6, bounds the change of Rayleigh quotient using projected residuals and the angle between two trial vectors. Its proof uses the compression to their two-dimensional span. Corollary 3.11, p.7, gives the familiar quadratic error identity when one vector is an eigenvector.

**Remaining L1 work.** The scalar perturbation algebra has a direct precedent; finite-dimensional compression also prevents global unboundedness alone from being a convincing novelty distinction. L1 must supply computable energy/source-error bounds for its two approximate fields and preserve their useful order after truncation and normalization.

### S13. Cancès–Dusson–Maday–Stamm–Vohralík: guaranteed bounds and effectivity

Eric Cancès, Geneviève Dusson, Yvon Maday, Benjamin Stamm, and Martin Vohralík, “Guaranteed A Posteriori Bounds for Eigenvalues and Eigenvectors: Multiplicities and Clusters,” *Mathematics of Computation* **89**(326) (2020), 2563–2611. [DOI](https://doi.org/10.1090/mcom/3549); [public manuscript](https://arxiv.org/pdf/2008.04140). Inspected local `Cances2020.pdf`.

**Setting and result.** Section 2.1, PDF p.4, assumes a bounded-below selfadjoint operator with compact resolvent. Definition 5.1 reconstructs equilibrated fluxes. Theorem 5.3, pp.24–25, guarantees a squared-residual upper bound for a cluster's sum of eigenvalue errors, with separation and, for the sharper case, regularity assumptions. Section 6.1, pp.29–30, observes effectivity tending to one on the square; §6.2 treats periodic-cell planewaves.

**Remaining L1 work.** The guarantee and numerical effectivity are genuine precedents in their compact-resolvent setting. An equilibrated flux is not, by itself, a reconstructed primal field in the physical operator domain. The infinite periodic defect strip lies outside the compact-resolvent hypothesis.

### S14. Carstensen–Gedicke: guaranteed FEM upper and lower bounds

Carsten Carstensen and Joscha Gedicke, “Guaranteed Lower Bounds for Eigenvalues,” *Mathematics of Computation* **83**(290) (2014), 2605–2629. [DOI](https://doi.org/10.1090/S0025-5718-2014-02833-0). Inspected local author manuscript `Carstensen2014.pdf`.

**Setting and result.** Theorem 3.1, PDF p.6, gives explicit lower bounds for the smallest Dirichlet Laplace eigenvalue on a bounded polygon using Crouzeix–Raviart FEM, algebraic residual control, and a conforming postprocessed upper bound. Theorem 4.1, p.12, proves efficiency of the enclosure width in terms of squared energy error and algebraic terms on graded meshes. Theorem 5.1 extends the treatment to higher indexed eigenvalues under additional assumptions.

**Remaining L1 work.** The conforming postprocessing gives an energy-space function. The paper treats a bounded-domain compact problem, rather than an internal essential gap or a globally reconstructed DtN field.

### S15. Liu–Plum: recent high-order FEM/Goerisch combination

Xuefeng Liu and Michael Plum, “A Two-Stage Finite Element Approach for High-precision Guaranteed Lower Eigenvalue Bounds,” arXiv:2512.23182 (2025). [Full text](https://arxiv.org/pdf/2512.23182).

**Setting and result.** Section 2, PDF p.6, assumes a compact embedding/operator for the abstract variational problem. Theorem 4.3, p.19, uses a certified lower bound for the next indexed eigenvalue together with high-order conforming FEM and Lehmann–Goerisch data to sharpen lower bounds. The source-problem/auxiliary-vector comparison in Eq.(4.5), p.17, is another direct precedent for controlling unknown source quantities. Section 5 gives numerical high-order and graded-mesh comparisons for bounded Laplace and Steklov problems.

**Remaining L1 work.** This confirms that combining coarse spectral information, high-order FEM, and classical inclusion formulas is an existing and useful algorithmic strategy. Its compact setting supplies neither L1's internal-gap isolation nor its infinite-strip finite-representation certificate.

### S16. Cancès–Ehrlacher–Maday: supercell convergence in internal gaps

Eric Cancès, Virginie Ehrlacher, and Yvon Maday, “Non-consistent Approximations of Self-adjoint Eigenproblems: Application to the Supercell Method,” *Numerische Mathematik* **128** (2014), 663–706. [DOI](https://doi.org/10.1007/s00211-014-0626-0); [public manuscript](https://arxiv.org/pdf/1205.0331). Inspected local `Cances2014.pdf`.

**Setting and result.** Theorem 5.1, PDF pp.14–15, proves spectral exactness of supercells for a localized perturbation of a periodic Schrödinger operator on \(\mathbb R^d\). With its potential regularity assumptions, it bounds eigenspace error by exponentially small supercell error plus spectral-discretization error, and eigenvalue error by the square of that expression. Theorem 5.2, p.16, includes numerical integration error.

**Remaining L1 work.** These are convergence estimates with unspecified constants and a sufficiently-large-discretization condition. They leave a computable a posteriori interval to another construction. The background is the same at infinity; L1 has different leads and uses exact-lead elimination rather than a periodic supercell.

### S17. Herbst–Levitt–Cancès: numerical Kato–Temple on Bloch cells

Michael F. Herbst, Antoine Levitt, and Eric Cancès, “A Posteriori Error Estimation for the Non-Self-Consistent Kohn–Sham Equations,” *Faraday Discussions* **224** (2020), 227–246. [DOI](https://doi.org/10.1039/D0FD00048E); [public manuscript](https://arxiv.org/pdf/2004.13549v2). Inspected local `Herbst2020.pdf`.

**Setting and result.** The fixed-Bloch Hamiltonian acts on a bounded periodic cell and is discretized by planewaves. Theorem 2, Eq.(4), PDF p.3, presents a residual-squared Kato–Temple estimate. Section V, Eqs.(7)–(8), p.5, bounds the next band using an infinite/finite Schur complement. Sections VI–VII, pp.5–7, include floating-point interval control and band-energy error bars.

**Remaining L1 work.** This is a close computational precedent for squared-residual bounds and computable spectral-complement information. The cell fibres have compact resolvent; they contain no localized line-defect field. Its pseudopotential tail estimates and finite planewave representation differ from L1's discontinuous dielectric source. For L1, use [S1]'s explicit Rayleigh-to-endpoint denominators rather than transplanting the gap notation of Eq.(4).

### S18. Dupuy–Dusson–Lygatsika: unbounded-domain molecular residual bounds

Mi-Song Dupuy, Geneviève Dusson, and Ioanna-Maria Lygatsika, “A Posteriori Error Estimates for Schrödinger Operators Discretized with Linear Combinations of Atomic Orbitals,” *SIAM Journal on Numerical Analysis* **63**(6) (2025), 2395–2420. [DOI](https://doi.org/10.1137/24M1700697); [public manuscript](https://arxiv.org/pdf/2410.04943v3). Inspected local `Dupuy2025.pdf`.

**Setting and result.** Assumptions 2.1–2.2, PDF p.3, concern molecular Schrödinger operators on \(\mathbb R^d\), with essential spectrum \([0,\infty)\) and negative bound states. Theorems 3.5 and 3.9, pp.8 and 10, give eigenfunction and computable squared-residual eigenvalue bounds under the stated separation assumptions. The LCAO trial functions already belong to \(H^2\).

**Remaining L1 work.** The targets lie below the essential bottom. Remark 3.4, p.8, explicitly substitutes a computed next Ritz eigenvalue for the required guaranteed separation in the numerical examples; those displayed practical bounds therefore lose the full guarantee. The paper supplies no periodic internal-gap FEM+DtN reconstruction.

### S19. Liu: spectral-Galerkin lower bounds

Xuefeng Liu, “Guaranteed Lower Eigenvalue Bounds for Spectral Galerkin Methods with Application to Schrödinger Operators,” arXiv:2607.04247 (2026). [Full text](https://arxiv.org/pdf/2607.04247). Inspected local `Liu2026.pdf`.

**Setting and result.** Theorem 2.2, PDF p.5, gives indexed lower bounds from the projection-error constant under Assumption 2.1. Its abstract assumptions should be read directly, rather than replaced by a blanket compact-resolvent claim. The concrete unbounded extension, §4.4, Lemma 4.17 and Eq.(4.32), pp.18–19, uses confining potentials and exterior-potential separation. Section 5 contains bounded-interval and confining full-space examples.

**Remaining L1 work.** The full-space examples use confinement, rather than an internal gap of periodic essential spectrum. Remark 5.1, p.21, reserves final certification of the displayed multidimensional lower-bound digits for a companion computation. The projection-constant correction can also dominate the much smaller Ritz error (§5.1, Table 1, p.20); convergence of bounds alone does not settle C4.

### S20. Liu: singular potentials on full space

Xuefeng Liu, “Explicit Two-Sided Eigenvalue Bounds for Schrödinger Operators with Singular Potentials via Finite Element Method,” arXiv:2605.05177 (2026). [Full text](https://arxiv.org/pdf/2605.05177).

**Setting and result.** Lemma 1, PDF pp.5–6, transfers a Neumann-truncation lower bound to a full-space discrete eigenvalue **below the essential bottom**, provided the exterior potential minimum exceeds that eigenvalue. Theorem 3, p.20, gives explicit bounds for the truncated problem using composite enriched Crouzeix–Raviart FEM and potential-approximation control. Remark 4, p.6, gives the full-space Dirichlet–Neumann bracket.

**Remaining L1 work.** The confinement criterion is unavailable for a periodic internal-gap target. Section 7, PDF p.31, separates explicit mathematical bounds from a future fully verified floating-point implementation. It supplies neither a periodic-guide source reconstruction nor C3's quotient transfer.

### S21. Brown–Hoang–Plum–Wood after 2009: weighted line defects

B. M. Brown, V. Hoang, M. Plum, and I. Wood, “On the Spectrum of Waveguides in Planar Photonic Bandgap Structures,” *Proceedings of the Royal Society A* **471**(2176) (2015), 20140673. [DOI](https://doi.org/10.1098/rspa.2014.0673); [public manuscript](https://arxiv.org/pdf/1204.0998). Inspected local `Brown2015.pdf`.

**Setting and result.** This is a weighted Laplacian on a quasiperiodic strip with a sign-definite line defect in one periodic background. Theorem 1, PDF p.9, proves creation of a gap eigenvalue under its explicit perturbation condition. Theorem 3, p.18, rules out accumulation of strip eigenvalues at the background band edges under the paper's assumptions.

**Remaining L1 work.** These are existence and finiteness results. They furnish no a posteriori enclosure algorithm for an arbitrary computed mode, reconstructed trial field, or refinement effectivity data. Their hypotheses also restrict the background and sign of the defect.

### S22. Brown–Hoang–Plum–Radosz–Wood: TE weak-defect localization

B. M. Brown, V. Hoang, M. Plum, M. Radosz, and I. Wood, “Gap Localization of TE-Modes by Arbitrarily Weak Defects,” *Journal of the London Mathematical Society* **95**(3) (2017), 942–962. [DOI](https://doi.org/10.1112/jlms.12046); [public manuscript](https://arxiv.org/pdf/1511.03723). Inspected local `Brown2017.pdf`.

**Setting and result.** Theorem 2.1, PDF p.3, assumes a positive, sufficiently weak coefficient perturbation of a periodic divergence-form operator and proves a quasiperiodic, transversely localized gap eigenfunction. Discontinuous bounded coefficients are allowed.

**Remaining L1 work.** The theorem controls existence under weak positive perturbation. It gives no numerical trial-field enclosure, Rayleigh transfer, or refinement study for a prescribed candidate in a heterogeneous-lead guide.

### S23. Brown–Hoang–Plum–Radosz–Wood: multiband counting

B. M. Brown, V. Hoang, M. Plum, M. Radosz, and I. Wood, “Gap Localization of Multiple TE-Modes by Arbitrarily Weak Defects,” *Journal of the London Mathematical Society* **102**(2) (2020), 773–795. [DOI](https://doi.org/10.1112/jlms.12337); [public manuscript](https://arxiv.org/pdf/1901.05102). Inspected local `Brown2020.pdf`, whose preprint title ends “Multiband Case.”

**Setting and result.** Theorem 3, PDF p.16, gives an exact number of created eigenvalues for a sufficiently weak positive line defect, assuming nonconstant band functions and quadratic nondegeneracy at the relevant band edge. The number is determined by the band-edge mode pairs.

**Remaining L1 work.** This is a possible counting ingredient only when its perturbation and band-edge hypotheses hold. It gives neither a verified count for L1's fixed contrast and different leads nor a computed-candidate error enclosure.

### S24. Fliss: exact DtN reduction for guided modes

Sonia Fliss, “A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides,” *SIAM Journal on Scientific Computing* **35**(2) (2013), B438–B461. [DOI](https://doi.org/10.1137/12086697X). Inspected local `Fliss2013.pdf`.

**Setting and result.** Theorem 4.1, PDF p.10, makes the half-guide problem well posed away from essential spectrum and the stated Dirichlet exceptions. Theorem 4.5, p.13, proves equivalence of the full guided-mode problem and the bounded center problem with frequency-dependent exact DtN maps and transverse quasiperiodicity.

**Remaining L1 work.** The theorem supplies the continuous nonlinear reduction used to generate candidates. It does not attach guaranteed eigenvalue intervals to discretized DtN/FEM computations or construct L1's global source field.

### S25. Klindworth–Schmidt–Fliss: numerical DtN, including different leads

Dirk Klindworth, Kersten Schmidt, and Sonia Fliss, “Numerical Realization of Dirichlet-to-Neumann Transparent Boundary Conditions for Photonic Crystal Wave-Guides,” *Computers & Mathematics with Applications* **67**(4) (2014), 918–943. [DOI](https://doi.org/10.1016/j.camwa.2013.03.005). Inspected local `Klindworth2014.pdf`.

**Setting and result.** Section 3 constructs the nonlinear bounded-domain eigenproblem from periodic half-strip DtN maps. Sections 7.1–7.3, PDF pp.22–25, compare FEM and interpolation convergence with reference computations. Section 7.4, p.26, computes a guide with **different periodic media on its two sides**.

**Remaining L1 work.** Heterogeneous periodic leads and numerical DtN root finding already exist. The reported convergence comparisons provide no guaranteed continuous eigenvalue enclosure or C3 transfer bound. The presence of different leads alone is therefore a weak novelty distinction.

### S26. Fliss–Klindworth–Schmidt: Robin-to-Robin reduction

Sonia Fliss, Dirk Klindworth, and Kersten Schmidt, “Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides,” *BIT Numerical Mathematics* **55**(1) (2015), 81–115. [DOI](https://doi.org/10.1007/s10543-014-0521-1). Inspected local `Fliss2015.pdf`.

**Setting and result.** Theorem 4.1, PDF p.20, gives an equivalent bounded-center formulation using Robin-to-Robin maps. Section 5, pp.27–31, demonstrates numerical guided-mode computation and improved behavior near exceptions of the Dirichlet formulation.

**Remaining L1 work.** This addresses the reduction's robustness. It gives no fully computable two-sided eigenvalue-error certificate or global trial-field quotient transfer.

### S27. Klindworth: scope of the DtN convergence evidence

Dirk Klindworth, *On the Numerical Computation of Photonic Crystal Waveguide Band Structures*, doctoral thesis, Technische Universität Berlin, 2015. [Repository DOI](https://doi.org/10.14279/depositonce-4917). Inspected local `Klindworth2015.pdf`.

**Setting and result.** Section 8.2, printed p.143 / PDF p.153, explicitly distinguishes observed FEM convergence of the DtN/RtR constructions from a numerical-analysis proof. The thesis reports numerical band-structure methods and their convergence studies.

**Remaining L1 work.** This source supplies a precise boundary on its own claims. Its statement concerns the analysis available there; later absence of a theorem is assessed from the other sources in this survey, rather than inferred from the thesis alone.

### S28. Fliss–Joly–Lescarret: periodic outlets at infinity

Sonia Fliss, Patrick Joly, and Vincent Lescarret, “A Dirichlet-to-Neumann Approach to the Mathematical and Numerical Analysis in Waveguides with Periodic Outlets at Infinity,” *Pure and Applied Analysis* **3**(3) (2021), 487–526. [DOI](https://doi.org/10.2140/paa.2021.3.487). Inspected local HAL manuscript `Fliss2021.pdf`.

**Setting and result.** Theorems 3.5 and 3.8, PDF pp.17 and 19, establish half-guide and full forced-problem solvability outside their exceptional sets. Theorem 4.13, p.28, characterizes the outgoing propagation operator by the Riccati equation and a flux condition. Proposition 4.14, p.32, gives the associated DtN formula.

**Remaining L1 work.** This is exact continuous periodic-port analysis, including propagating regimes. Guided resonances affect solvability of the forced problem; they do not receive certified numerical eigenvalue intervals here. Discretized port-error and trial-field transfer bounds remain separate tasks.

### S29. Halla–Nannen: waveguide eigenvalue convergence

Martin Halla and Lothar Nannen, “Two Scale Hardy Space Infinite Elements for Scalar Waveguide Problems,” *Advances in Computational Mathematics* **44** (2018), 611–643. [DOI](https://doi.org/10.1007/s10444-017-9549-5). Inspected local `Halla2018.pdf`.

**Setting and result.** Section 4.2, Eq.(4.4), printed p.631 / PDF p.21, bounds a simple isolated resonance's eigenvalue error by the product of primal and adjoint approximation errors, for sufficiently accurate discretization. The method uses Hardy-space infinite elements in straight separable outlets.

**Remaining L1 work.** The convergence estimate contains an unspecified constant and concerns nonselfadjoint resonance approximation. It supplies neither a computed guaranteed interval for the selfadjoint periodic-gap mode nor L1's reconstruction/transfer construction.

### S30. Photonic FEM estimators and rational operator bounds

**S30a.** Stefano Giani, “An A Posteriori Error Estimator for hp-Adaptive Continuous Galerkin Methods for Photonic Crystal Applications,” *Computing* **95**(5) (2013), 395–414. [DOI](https://doi.org/10.1007/s00607-012-0244-6). Inspected local `Giani2013.pdf`. Theorems 1–2, printed p.404 / PDF p.10, give residual-indicator estimates for eigenspaces and eigenvalues, with unspecified constants and higher-order terms. Section 2's defect computations use supercells or truncation; §5 compares effectivity against a high-order FEM reference. The continuous unbounded-domain truncation and a fully computable interval are outside the proved estimate.

**S30b.** Christian Engström, Stefano Giani, and Luka Grubišić, “Efficient and Reliable hp-FEM Estimates for Quadratic Eigenvalue Problems and Photonic Crystal Applications,” *Computers & Mathematics with Applications* **72**(4) (2016), 952–973. [DOI](https://doi.org/10.1016/j.camwa.2016.06.001). Inspected local `Engstrom2016.pdf`. Theorem 2.4, printed p.956 / PDF p.5, controls eigenspace error by residuals with resolvent and conditioning factors; Theorem 4.3, p.963 / PDF p.12, bounds dual residuals by FEM indicators on a periodic cell. Section 5 studies numerical effectivity. The implicit factors and bounded-cell model leave a guaranteed periodic-lead eigenvalue enclosure to establish.

**S30c.** Christian Engström, Heinz Langer, and Christiane Tretter, “Rational Eigenvalue Problems and Applications to Photonic Crystals,” *Journal of Mathematical Analysis and Applications* **445**(1) (2017), 240–279. [DOI](https://doi.org/10.1016/j.jmaa.2016.07.048); [public preprint](https://arxiv.org/pdf/1507.06381), titled “Non-linear Eigenvalue Problems and Applications to Photonic Crystals.” Theorem 3.13 and Corollary 3.14, PDF pp.12–13, bound eigenvalues on either side of a Lorentz pole using eigenvalue brackets of a compact-resolvent base operator and coupling bounds. The photonic application uses bounded Bloch cells with dispersive material coefficients. These are rational material-pole estimates, rather than residual-squared DtN guided-mode certificates under refinement.

### S31. Hoang–Plum–Wieners: certified photonic band gaps

Vu Hoang, Michael Plum, and Christian Wieners, “A Computer-Assisted Proof for Photonic Band Gaps,” *Zeitschrift für angewandte Mathematik und Physik* **60** (2009), 1035–1052. [DOI](https://doi.org/10.1007/s00033-008-8021-2). Inspected local published `Hoang2009a.pdf`.

**Setting and result.** Theorems 1–2, printed pp.1039–1040, give Rayleigh–Ritz upper and Goerisch lower Bloch-cell eigenvalue bounds, with verified separation and matrix conditions. Section 4 obtains separation through homotopy. Theorem 7, p.1046, extends bounds from a finite quasi-momentum grid to a covering of the Brillouin zone by explicit resolvent perturbation radii, thereby proving a band gap.

**Remaining L1 work.** These are certified bulk bands, rather than a count of localized defect eigenvalues. For L1, apply the coverage argument on the longitudinal quasi-momentum slice at fixed transverse quasi-momentum, separately for both leads, with valid curved-interface integration bounds.

### S32. Nagatou–Plum–Nakao: verified exclusion inside periodic gaps

Kaori Nagatou, Michael Plum, and Mitsuhiro T. Nakao, “Eigenvalue Excluding for Perturbed-Periodic One-Dimensional Schrödinger Operators,” *Proceedings of the Royal Society A* **468**(2138) (2012), 545–562. [DOI](https://doi.org/10.1098/rspa.2011.0159); [public full text](https://citeseerx.ist.psu.edu/document?doi=854ed5ac1226921c94efa646c9037d8331f5897a&repid=rep1&type=pdf).

**Setting and result.** The potential on \(\mathbb R\) is periodic plus a decaying perturbation. Theorem 6.1, prepublication pp.14–15, excludes an entire closed interval outside the essential spectrum by verifying explicit interpolation/tail inequalities and an interval linear system whose solution satisfies Eq.(6.25). Remark 6.2(d), p.15, includes rounding errors. Section 7, Table 1, p.16, reports certified eigenvalue-free subintervals of a periodic gap.

**Remaining L1 work.** Its scalar one-dimensional Green-function and interpolation estimates require replacement for L1's two-dimensional quasiperiodic strip and different leads.

### S33. Brown–Hoang–Plum–Wood: three-dimensional line-defect counting

B. M. Brown, V. Hoang, M. Plum, and I. Wood, “Spectrum Created by Line Defects in Periodic Structures,” *Mathematische Nachrichten* **287**(17–18) (2014), 1972–1985. [DOI](https://doi.org/10.1002/mana.201300165); [public manuscript](https://arxiv.org/pdf/1306.6256).

**Setting and result.** The weighted Laplacian is posed on \(\mathbb R^3\), with a defect periodic in one direction and compactly supported in the other two. Under the paper's band-edge assumptions, Theorems 1–3, PDF pp.7–12, give the number of gap eigenvalues for sufficiently small positive perturbations. Theorem 4, p.12, proves finiteness for arbitrary-size nonnegative perturbations under the standing assumptions.

**Remaining L1 work.** The counting results concern a prescribed perturbation class. They provide no numerical-candidate enclosure, source reconstruction, or verified count for L1's fixed heterogeneous-lead model.

### S34. Carstensen–Stiebert: recent bounded-domain localization tools

**S34a.** Carsten Carstensen and Tim Stiebert, “Old and New Schrödinger Eigenvalue Localisation,” arXiv:2604.21074 (2026). [Full text](https://arxiv.org/pdf/2604.21074). Inspected local `Carstensen2026.pdf`. Section 2, PDF pp.3–4, uses compact embeddings. Theorems 3.1 and 5.2, pp.6 and 14, give explicit lower bounds using Crouzeix–Raviart and extra-stabilized discretizations; the latter treats piecewise-constant potentials. The numerical comparisons concern bounded Schrödinger problems. The internal essential gap and exterior source reconstruction of L1 remain outside this setting.

**S34b.** Carsten Carstensen and Tim Stiebert, “Galerkin Error Reduction and Eigenvalue Localisation for Conforming FEM,” *Numerische Mathematik* (2026). [DOI](https://doi.org/10.1007/s00211-026-01577-9). Inspected local published `Carstensen2026a.pdf`. Theorem 3.1, PDF p.18, bounds indexed eigenvalues above and below using the conforming Ritz value and a computable energy-to-weaker-norm projection-error constant. Theorem 5.4, p.23, gives the modified Schrödinger lower bound. The compact embeddings stated in §§2–3 restrict direct application to bounded auxiliary or cell problems; a continuous periodic-guide enclosure needs an additional exterior argument.

## 3. Re-check of Brown–Hoang–Plum–Wood 2009

The Stage 1 sentence “the broad guarantee already exists” is too broad if read as a guarantee for the present computed guided-mode eigenvalue. The chapter proves analytic spectral localization for its divergence-form operator and homogeneous defect strip: an interval obtained from the shifted inverse defect contains **some spectrum**. When such an interval lies in a background gap, this establishes defect-created spectrum there. Its worked field is a separated analytic trial supported in the defect strip, and its illustrated intervals vary analytic trial and material parameters.

The accurate replacement is: **Brown–Hoang–Plum–Wood provide a guaranteed first-order spectral inclusion for their straight-defect model.** They provide neither a numerical FEM+DtN eigenpair enclosure nor a second-order bound for a uniquely identified quasiperiodic fibre eigenvalue. The closest prior framework for L1's source lifting and computable inclusion data is [S1]; the closest inspected numerical periodic internal-gap enclosure is [S2]. This changes the comparison baseline without treating the 2009 theorem as weaker than it is.

## 4. The candidate new combination

The candidate contribution is an explicit, computable realization of **C2 + C3 feeding the existing C1 theorem**, followed by a C4 accuracy/cost analysis and demonstration: take the actual FEM+DtN candidate, use a positive constant-coefficient source solve to produce an operator-domain field on the whole weighted quasiperiodic strip, and certify the residual, normalization, and Rayleigh-quotient transfer from its finite Fourier/source representation, including source projection, numerical moments, interfaces, and exterior tails. Under the stated assumption that exactly one spectral point lies in the enclosing gap, classical Kato–Temple then yields a second-order enclosure. The new mathematical work would be explicit reconstruction/transfer estimates and their approximation rates, sufficient to preserve the squared-residual gain at a quantified cost. Standard source lifting, Rayleigh perturbation algebra, and the gap inequality should be credited as existing tools. The numerical contribution would establish that this particular computable combination gives sharper guaranteed bounds than the current first-order reconstruction bound on the repository model. A complete implementation of this combination was not located in the inspected sources.

For **C4**, specify the eigenvalue approximation used in the effectivity denominator and report both enclosure width and its reference error under refinement. The quadratic graph-norm estimates in [S7] and [S8] already give the relevant abstract order. Bounded effectivity against the actual Rayleigh error requires more: spectral contributions below and above a gap eigenvalue can cancel in the Rayleigh error while contributing positively to residual size, as follows from the spectral representation used in [S1], Theorem 10.8's proof, pp.356–357. A theorem asserting that ratio therefore needs an error-equivalence or noncancellation hypothesis; a numerical claim needs an observed bounded ratio for the stated refinement sequence. This qualification affects the proposed guarantee and should be explicit in the L1 plan.

## 5. C5 tools for later isolation certification

- **Lead band enclosures at fixed transverse quasi-momentum:** use [S31]'s verified Ritz/Goerisch cell bounds and its resolvent covering theorem on the remaining longitudinal Bloch parameter. Apply this to each lead and intersect the resulting gaps. Geometry integration and matrix arithmetic must be enclosed in these calculations.
- **Spectral reduction to the center:** [S24], Theorem 4.5, supplies the exact frequency-dependent DtN formulation; [S25], §7.4, demonstrates different periodic media on opposite sides. A validated count through this formulation would need continuous-to-discrete port control and bookkeeping for half-lead Dirichlet poles.
- **Local eigenvalue inclusions after isolation information is available:** [S4], Theorem 1.1, and [S1], Theorems 10.10/10.29, give Lehmann-type bounds in internal gaps. [S1], Remark 10.11(g), explicitly warns that these inclusion formulas do not furnish eigenvalue exclosures; an unobserved mode remains possible without a count.
- **Verified exclusion in periodic gaps:** [S32], Theorem 6.1, already certifies eigenvalue-free subintervals for a perturbed-periodic operator on \(\mathbb R\), using explicit tails and verified finite linear systems. Extending its scalar Green-function estimates to the strip is a concrete route to investigate. Exclusion outside a candidate's small interval must still be combined with a count or local uniqueness inside it.
- **Homotopy and comparison:** [S11], §3, and [S1], §10.2.4, provide verified separation/counting mechanisms for eigenvalues below the essential bottom. An internal-gap adaptation needs relative counting or a suitable spectral transformation; their below-bottom homotopy alone does not certify L1's internal-gap count. [S23], Theorem 3, provides a different counting route only for its sufficiently weak positive-defect, nondegenerate-band-edge setting.
- **Certified spectral-complement bounds:** [S17], §V, Eqs.(7)–(8), gives a useful Schur-complement template for band separation. Its bounded Bloch-cell complement estimate would need a validated periodic-port counterpart for the full guide.
- **Projection-error constants and auxiliary eigenvalues:** [S34a], Theorems 3.1/5.2, and [S34b], Theorem 3.1, give recent bounded-domain lower-bound tools. They can support cell or coercive auxiliary calculations after checking the boundary conditions and geometry; their compact-embedding proof does not count full-strip gap modes.

These tools support a later isolation project. Paper 1 can state the one-spectral-point condition once as an assumption and prove its enclosure conditional on that condition.

## 6. Downloaded files and inaccessible originals

**Downloaded files: none.** Existing local PDFs and public full texts were sufficient for the component comparison.

- **Henning Behnke and Friedrich Goerisch**, “Inclusions for Eigenvalues of Selfadjoint Problems,” in Jürgen Herzberger (ed.), *Topics in Validated Computations*, Studies in Computational Mathematics **5**, North-Holland, Amsterdam, 1994, pp.277–322. [Book bibliographic record](https://ci.nii.ac.jp/ncid/BA25224500). A lawful accessible full text of the original chapter was not located. It may affect C1–C3 and C5. Its results are not summarized from citations; [S1] supplies the directly inspected modern statements used above.
- **Tosio Kato**, “On the Upper and Lower Bounds of Eigenvalues,” *Journal of the Physical Society of Japan* **4** (1949), 334–339. [DOI](https://doi.org/10.1143/JPSJ.4.334). The original public full-text endpoint was inaccessible. It affects the historical attribution of C1; the applicable inequality was read in [S1], Theorem 10.8.
- **Xuefeng Liu**, “A Framework of Verified Eigenvalue Bounds for Self-adjoint Differential Operators,” *Applied Mathematics and Computation* **267** (2015), 341–355. [DOI](https://doi.org/10.1016/j.amc.2015.03.048); [author manuscript](https://mathweb.sc.niigata-u.ac.jp/~xfliu/pdf/AMC_2015.pdf). The author-PDF request timed out. This source may affect C2, C4, and C5; the present verdicts use the inspected [S14], [S15], [S19], and [S31] rather than an abstract-only interpretation of this paper.
- **Yoshitaka Watanabe, Kaori Nagatou, Michael Plum, and Mitsuhiro T. Nakao**, “Verified Computations of Eigenvalue Exclosures for Eigenvalue Problems in Hilbert Spaces,” *SIAM Journal on Numerical Analysis* **52**(2) (2014), 975–992. [DOI](https://doi.org/10.1137/120894683). Full text was not accessible through the inspected public links. It may affect C5's exclusion machinery; its theorem hypotheses are left unassessed, and no component verdict rests on its abstract.

The uninspected originals above leave historical priority details unresolved. They do not support an assertion that the complete L1 combination is either covered or new. No inspected source demonstrates C1–C4 together for the specified dielectric guide.

[S1]: https://doi.org/10.1007/978-981-13-7669-6
[S2]: https://arxiv.org/pdf/math/0702420
[S3]: https://doi.org/10.1007/978-3-7643-8773-0_3
[S4]: https://ems.press/content/serial-article-files/34815?nt=1
[S5]: https://arxiv.org/pdf/math/0302145
[S6]: https://arxiv.org/pdf/math/0212087
[S7]: https://arxiv.org/pdf/1109.3588
[S8]: https://pmc.ncbi.nlm.nih.gov/articles/PMC5445552/
[S9]: https://arxiv.org/pdf/1401.4066v3
[S10]: https://arxiv.org/pdf/1307.0313v2
[S11]: https://doi.org/10.1098/rspa.2000.0635
[S12]: https://arxiv.org/pdf/1207.3240v2
[S13]: https://arxiv.org/pdf/2008.04140
[S14]: https://doi.org/10.1090/S0025-5718-2014-02833-0
[S15]: https://arxiv.org/pdf/2512.23182
[S16]: https://arxiv.org/pdf/1205.0331
[S17]: https://arxiv.org/pdf/2004.13549v2
[S18]: https://arxiv.org/pdf/2410.04943v3
[S19]: https://arxiv.org/pdf/2607.04247
[S20]: https://arxiv.org/pdf/2605.05177
[S21]: https://arxiv.org/pdf/1204.0998
[S22]: https://arxiv.org/pdf/1511.03723
[S23]: https://arxiv.org/pdf/1901.05102
[S24]: https://doi.org/10.1137/12086697X
[S25]: https://doi.org/10.1016/j.camwa.2013.03.005
[S26]: https://doi.org/10.1007/s10543-014-0521-1
[S27]: https://doi.org/10.14279/depositonce-4917
[S28]: https://doi.org/10.2140/paa.2021.3.487
[S29]: https://doi.org/10.1007/s10444-017-9549-5
[S30a]: https://doi.org/10.1007/s00607-012-0244-6
[S30b]: https://doi.org/10.1016/j.camwa.2016.06.001
[S30c]: https://arxiv.org/pdf/1507.06381
[S31]: https://doi.org/10.1007/s00033-008-8021-2
[S32]: https://citeseerx.ist.psu.edu/document?doi=854ed5ac1226921c94efa646c9037d8331f5897a&repid=rep1&type=pdf
[S33]: https://arxiv.org/pdf/1306.6256
[S34a]: https://arxiv.org/pdf/2604.21074
[S34b]: https://doi.org/10.1007/s00211-026-01577-9
