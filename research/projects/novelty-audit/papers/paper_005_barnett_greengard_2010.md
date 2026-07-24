# Paper 005

**Title:** A New Integral Representation for Quasiperiodic Fields and Its Application to Two-Dimensional Band Structure Calculations  
**Authors:** Alex H. Barnett, Leslie Greengard  
**Year / journal:** 2010, *Journal of Computational Physics* 229(19), 6898--6914  
**DOI:** 10.1016/j.jcp.2010.05.029  
**URL:** https://doi.org/10.1016/j.jcp.2010.05.029  
**Local file:** `ref/Barnett2010.pdf`  
**Search route:** Local seed; backward/forward BIE chain.

1. **Geometry:** A periodic bulk unit cell with penetrable inclusions.
2. **PDE/polarization:** Piecewise-constant scalar Helmholtz/Maxwell reductions.
3. **Spectral parameter:** Frequency and two Bloch phases.
4. **Spaces/radiation:** Quasiperiodic cell fields; no half-guide radiation.
5. **Exterior reduction:** QP/free-space layer-potential representation; later a robust free-space neighboring-image/auxiliary-wall formulation.
6. **Discretization:** Spectral Nyström; smallest-singular-value band search.
7. **Theory:** Theorem 4 proves Bloch eigenvalue iff the QP Müller operator is singular away from empty-cell resonances. Lemmas 9--10 and Appendix A prove uniqueness using a swapped-wavenumber complementary transmission problem.
8. **Numerics:** Spectral accuracy and robust band diagrams; explicit diagnosis of QP Green-function resonance failures.
9. **Assumptions:** Smooth interfaces, non-Wood/non-empty-resonant parameters for the QP formulation.
10. **Limitations:** Bulk band structure only; standard QP kernel fails at exceptional parameters, prompting the augmented formulation.
11. **Draft relation:** Closest overlap with Theorem 2, the Müller--Rayleigh block, and (sigma_{min}) scanning. Draft Appendix A reproduces this proof architecture and currently contains a mixed-(k,nk) QP double-layer typo at source line 243.
12. **Exact passages:** Theorem 4, Remark 5, Remark 6, Remark 8, Lemmas 9--10, Appendix A, Section 6.
13. **Assessment:** **Already solved/strong overlap** for exact QP Müller nullspace equivalence and scanning; draft's independent homogeneous Rayleigh augmentation is at most a partial extension until proved correctly.
