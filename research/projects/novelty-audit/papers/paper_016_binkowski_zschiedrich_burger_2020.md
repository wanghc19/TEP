# Paper 016

**Title:** A Riesz-Projection-Based Method for Nonlinear Eigenvalue Problems  
**Authors:** Felix Binkowski, Lin Zschiedrich, Sven Burger  
**Year / journal:** 2020, *Journal of Computational Physics* 419, 109678  
**DOI:** 10.1016/j.jcp.2020.109678  
**URL:** https://doi.org/10.1016/j.jcp.2020.109678  
**Local file:** None  
**Search route:** Required contour-integral/photonic NEP query; Elsevier record.

1. **Geometry:** General nonlinear eigenproblems with nanophotonic resonator examples.
2. **PDE/polarization:** Application dependent, including Maxwell discretizations.
3. **Spectral parameter:** Complex nonlinear eigenvalue.
4. **Spaces/radiation:** Encoded in the black-box operator evaluation.
5. **Exterior reduction:** Not prescribed; accepts a nonlinear matrix/operator function.
6. **Discretization:** Contour quadrature/Riesz projections and a reduced nonlinear solve.
7. **Theory:** Retrieves physically relevant eigenvalues inside a contour without linearization.
8. **Numerics:** Quantum and nanophotonic examples.
9. **Assumptions:** Analytic/meromorphic operator and invertibility on the contour.
10. **Limitations:** Does not by itself distinguish physical from representation-induced poles unless the supplied operator is certified.
11. **Draft relation:** A mature replacement for global (sigma_{\min}) grid scans. Innovation would require adapting it to the relation-valued BIE while filtering spurious nullspaces.
12. **Exact passages:** Abstract and algorithm/numerical sections, JCP 419, 109678.
13. **Assessment:** **Already solved** as a general NEP algorithm; **potentially useful component**, not draft novelty alone.
