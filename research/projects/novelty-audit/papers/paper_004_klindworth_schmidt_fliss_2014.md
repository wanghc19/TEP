# Paper 004

**Title:** Numerical Realization of Dirichlet-to-Neumann Transparent Boundary Conditions for Photonic Crystal Wave-Guides  
**Authors:** Dirk Klindworth, Kersten Schmidt, Sonia Fliss  
**Year / journal:** 2014, *Computers & Mathematics with Applications* 67(4), 918--943  
**DOI:** 10.1016/j.camwa.2013.03.005  
**URL:** https://doi.org/10.1016/j.camwa.2013.03.005  
**Local file:** None  
**Search route:** Forward chain from Fliss (2013); Elsevier record.

1. **Geometry:** Infinite 2-D planar photonic-crystal line-defect waveguide.
2. **PDE/polarization:** Scalar guided-mode problem.
3. **Spectral parameter:** Nonlinear frequency/eigenvalue at fixed quasi-momentum.
4. **Spaces/radiation:** Exact periodic-half-guide DtN condition.
5. **Exterior reduction:** Cell local problems and Riccati equation.
6. **Discretization:** High-order FEM; Newton iteration and direct Chebyshev interpolation of the nonlinear operator.
7. **Theory:** Differentiability of DtN maps and a group-velocity formula supplement Fliss (2013).
8. **Numerics:** Direct comparison with supercell; near-band-edge modes demonstrate supercell modeling error.
9. **Assumptions:** Same periodic lead structure and DtN well-posedness restrictions as the underlying method.
10. **Limitations:** Volume FEM and DtN forbidden frequencies; no BIE/stable trace relation.
11. **Draft relation:** Prior art for practical nonlinear solve, group velocity, and difficult poorly confined benchmarks. The draft's singular-value grid is algorithmically weaker without certification.
12. **Exact passages:** Elsevier abstract; Sections 3--7 described in the published introduction, pp. 918--943.
13. **Assessment:** **Already solved** for numerical DtN realization and more advanced than the draft's current line-defect numerics.
