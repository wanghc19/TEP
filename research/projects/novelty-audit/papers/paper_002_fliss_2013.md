# Paper 002

**Title:** A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides  
**Authors:** Sonia Fliss  
**Year / journal:** 2013, *SIAM Journal on Scientific Computing* 35(2), B438--B461  
**DOI:** 10.1137/12086697X  
**URL:** https://doi.org/10.1137/12086697X  
**Local file:** `ref/Fliss2013.pdf`  
**Search route:** Local seed; SIAM record; backward/forward chain.

1. **Geometry:** Two-dimensional periodic photonic crystal with an axial-periodic line defect, unbounded transversely.
2. **PDE/polarization:** Scalar self-adjoint Helmholtz-type model with periodic coefficient.
3. **Spectral parameter:** For fixed axial quasi-momentum (eta), (alpha^2) is the eigenvalue.
4. **Spaces/radiation:** Quasiperiodic (H^1) strip functions and square-integrable/exponentially decaying transverse behavior in a gap.
5. **Exterior reduction:** Exact left/right half-guide DtN maps built from cell operators and propagation operators.
6. **Discretization:** FEM; nonlinear fixed-point eigenproblem.
7. **Theory:** Theorem 3.5 quantifies exponential decay versus distance to essential spectrum. Theorem 4.1 gives half-guide well-posedness except a countable set. Theorem 4.5 proves exact equivalence of global and bounded DtN eigenproblems and preserves multiplicity. Theorems 4.12--4.13 characterize the Riccati/propagation solution.
8. **Numerics:** Computes dispersion curves and highlights poorly confined modes near band edges.
9. **Assumptions:** Gap regime, periodic exterior, scalar self-adjoint setting; classical DtN excludes its poles.
10. **Limitations:** Countable forbidden frequencies; FEM volume discretization; no interface-only BIE.
11. **Draft relation:** This is the closest prior work to draft Theorem 1 and the nonlinear guided-mode formulation. The full Cauchy-relation notation is more general at DtN poles, but the displayed restriction/gluing equivalence is not by itself a new core theorem.
12. **Exact passages:** Theorems 3.5, 4.1, 4.5, 4.9, 4.12, 4.13; Remark 4.2; Section 6.
13. **Assessment:** **Already solved** for global-to-bounded exact guided-mode reduction; **partially overlapping** for a relation-valued BIE implementation.
