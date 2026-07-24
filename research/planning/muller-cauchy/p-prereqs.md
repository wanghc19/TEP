# Prerequisite map

The intended reader knows elementary analysis, linear algebra, Helmholtz equations and practical BIEs, but not a full graduate sequence in functional analysis/PDE/operator theory. The order is dependency-driven rather than textbook order.

| Module | Why it is needed | Required depth | Safe to skip | Proof links | Reading | Check questions | Priority |
|---|---|---|---|---|---|---|---|
| **A Sobolev and trace theory** | Every Cauchy relation and layer block lives in fractional/dual spaces; wrong weights make the operator unbounded. | Define `H^s`, Fourier/quasiperiodic `H^s_\beta`, duality, product/quotient norms, Dirichlet and weak Neumann traces; prove a Green identity. | Besov/Triebel scales, nonlinear Sobolev theory, general manifolds beyond smooth curves. | L1, L2, L6, L14 | McLean Chs. 3--4; Fliss (2013) Sec. 4 | Why is `\gamma_N:H^1\to H^{-1/2}` false without PDE graph regularity? Why do Rayleigh Dirichlet and Neumann coefficients carry different weights? | **1** |
| **B Weak Helmholtz transmission** | Sound gluing must not leave an artificial delta source; unique continuation controls zero fields. | Weak forms with piecewise coefficients, distributional jumps, conormal continuity, gluing, Cauchy uniqueness, local elliptic regularity. | Nonlinear PDE, time-domain energy estimates, full microlocal regularity. | L3, L11--L13 | McLean Ch. 4; Colton--Kress Ch. 3; a standard elliptic PDE chapter on weak solutions/regularity | Show by testing that equal Dirichlet traces plus opposite outward conormals remove the port boundary term. When does zero Cauchy data force zero? | **2** |
| **C Helmholtz layer potentials** | L9/L10 and spurious-root analysis depend on jumps and Calderón ranges, not only formulas. | `S,D,D^*,T`, mappings, jumps, Calderón identities, interior/exterior representation/extinction, transmission/Müller blocks, complementary fields. | Fast multipole implementation, 3D vector Maxwell calculus, corner singular quadrature. | L6--L10, T1 | McLean Chs. 6--8; Colton--Kress Ch. 3; Barnett--Greengard Thm. 4 & App. A; Hiptmair et al. Sec. 2 | Derive every `\pm\frac12I` sign from the chosen normal. Can a nonzero density create zero physical field? What projector range does it occupy? | **3** |
| **D Fredholm theory** | “Second kind” alone does not prove injectivity/no-spuriousness; index requires square domain/codomain. | Compactness, Fredholm operator/index, closed range, quotient by kernel, compact perturbations, Fredholm alternative. | General C*-algebras, unbounded essential-spectrum theory beyond what Kato supplies here. | L14--L15, T2 | Kato Ch. IV; McLean BIE Fredholm chapters; Hohage--Soussi Lemma 5.1 | What is the domain/codomain of the index? Why is `I+K` Fredholm but not necessarily injective? What changes after quotienting? | **4** |
| **E Floquet--Bloch waveguide theory** | Outgoing data are stable generalized trace subspaces, not ordinary eigenspaces. | Quasiperiodicity, translation/propagation, projected essential spectrum, stable/unstable spectrum, generalized modes/Jordan chains, Riesz trace bases. | Full solid-state representation theory, higher-dimensional Brillouin-zone topology. | L4--L5, P1--P2 | Fliss (2013) Secs. 3--4; Joly--Li--Fliss Secs. 3--6; Hohage--Soussi Thm. 2.2; Zhang (2021) Secs. 3--5 | Why does `|\lambda|=1` contradict a strict projected gap? Why are associated vectors necessary? In which norm does the trace series converge? | **2 (parallel with B)** |
| **F Invariant subspaces** | The correct numerical object is a stable cluster/Riesz projection, especially near defective multipliers. | Spectral/Riesz projections, stable invariant subspace, Schur/QZ, gap/principal angles, perturbation of clusters. | Detailed Jordan algorithms, pseudospectral theory beyond diagnostic use. | P1, FL3, FT3 | Kato Chs. I & VII; a numerical linear algebra chapter on ordered QZ/subspace angles | Why compare subspaces rather than ordered eigenvectors? What bound contains `\operatorname{sep}^{-1}`? | **5** |
| **G Analytic operator functions** | Guided roots form a nonlinear operator-valued spectrum with poles distinct from physical zeros. | Analytic Fredholm theorem, meromorphic inverse, characteristic values/root functions, algebraic multiplicity, Riesz contour projections, Keldysh idea. | General several-complex-variable operator theory and complete canonical systems. | C1, FT1--FT2, contour-solver TODO | Kato Ch. VII; standard Gohberg--Sigal/Keldysh references; nonlinear-eigenvalue survey already in audit | Distinguish a Green pole, representation pole, and physical characteristic value. When is algebraic multiplicity defined? | **6** |
| **H Spectral approximation** | Future no-pollution claims need operator/subspace convergence, not pointwise matrix convergence. | Collectively compact approximation, Galerkin/Nyström eigenspace convergence, spectral pollution, nonlinear contour convergence, reconstruction certificates. | Adaptive FEM theory and stochastic error analysis. | FL1--FL4, FT1--FT3 | Babuška--Osborn (1991), pp. 641--787; Chatelin (1983); Zhang (2023) | Which convergence plus stability implies root convergence? How can normalized algebraic vectors converge to a zero field? | **7** |

## Suggested six-week theory bootstrapping sequence

1. **Week 1:** A, reproduce quasiperiodic trace norms and weak Neumann trace.
2. **Week 2:** B and the precise proof of L3.
3. **Weeks 2--3:** E, read Hohage--Soussi Theorem 2.2 and map every hypothesis.
4. **Week 3:** C, redo Barnett--Greengard Appendix A with the corrected `k/nk` assignment.
5. **Week 4:** combine C and Hiptmair et al. to attack L10/L13.
6. **Week 5:** D/F, search for a square multitrace `A_0`; do not attempt T2 before this.
7. **Week 6:** G/H only after K1's regular parameter set has stabilized.

## Gate exercises

- **Gate A→B:** write the two-sided Green identity with each artificial-port normal.
- **Gate B/E→coupling:** prove L3 and state P1 without ordinary-eigenvector language.
- **Gate C→K1:** characterize, rather than assume away, `\ker\mathcal R_{\rm field}`.
- **Gate D→T2:** exhibit the exact square `\mathcal A_0`, its inverse, and why every remaining block is compact.
- **Gate G/H→numerics:** draw one contour containing a physical zero but no Green/representation pole and define its algebraic multiplicity.

