# Paper 013

**Title:** Robust Fast Direct Integral Equation Solver for Quasi-Periodic Scattering Problems with a Large Number of Layers  
**Authors:** Min Hyung Cho, Alex H. Barnett  
**Year / journal:** 2015, *Optics Express* 23(2), 1775--1799  
**DOI:** 10.1364/OE.23.001775  
**URL:** https://doi.org/10.1364/OE.23.001775  
**Local file:** None  
**Search route:** Forward chain from Barnett--Greengard; proxy/three-cell query.

1. **Geometry:** Many arbitrary periodic 2-D layers.
2. **PDE/polarization:** Scalar Helmholtz transmission/TM grating scattering.
3. **Spectral parameter:** Fixed frequency and incident Bloch phase.
4. **Spaces/radiation:** Quasiperiodic side matching and outgoing Rayleigh expansions.
5. **Exterior reduction:** Free-space kernels on the central period and immediate left/right neighbors; proxies represent distant copies; Schur complements eliminate auxiliaries.
6. **Discretization:** High-order Nyström and fast direct block solver.
7. **Theory:** Formulation is robust at Wood anomalies and avoids QP Green-function divergence.
8. **Numerics:** Up to 1000 layers and (3\times10^5) unknowns with high accuracy.
9. **Assumptions:** Layered geometry and appropriate proxy enclosure/resolution.
10. **Limitations:** Forced scattering, not a line-defect mode eigensolver.
11. **Draft relation:** Shows that the “3-cell near field + proxy far field + Rayleigh matching” architecture is existing method prior art.
12. **Exact passages:** Abstract and Sections 2--5; DOI record.
13. **Assessment:** **Already solved** at the method-architecture level; a new stability theorem for the draft's QP Green evaluator could still be useful.
