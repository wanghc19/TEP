# Paper 012

**Title:** A Meshless Numerical Method for Time Harmonic Quasi-Periodic Scattering Problem  
**Authors:** Tian Luan, Yao Sun, Zibo Zhuang  
**Year / journal:** 2019, *Engineering Analysis with Boundary Elements* 104, 320--331  
**DOI:** 10.1016/j.enganabound.2019.03.034  
**URL:** https://doi.org/10.1016/j.enganabound.2019.03.034  
**Local file:** `ref/Luan2019.pdf`  
**Search route:** Local seed and MFS query.

1. **Geometry:** Periodic array of penetrable obstacles.
2. **PDE/polarization:** Scalar Helmholtz transmission.
3. **Spectral parameter:** Fixed wavenumber and Bloch phase for scattering.
4. **Spaces/radiation:** Quasiperiodicity plus Rayleigh expansion, away from Wood anomalies.
5. **Exterior reduction:** Local MFS/Fourier--Bessel fields matched to truncated Rayleigh expansions.
6. **Discretization:** Meshless least squares/collocation.
7. **Theory:** Theorem 3.1 bounds solution error by jump residual under the non-Wood condition.
8. **Numerics:** Accuracy improves with basis size for multiple penetrable examples.
9. **Assumptions:** Smooth obstacles and (k^2\ne(\alpha_n+\alpha)^2) for all Fourier orders.
10. **Limitations:** MFS ill-conditioning/source placement; scattering only; no Bloch stable-subspace eigenproblem.
11. **Draft relation:** Strong overlap with MFS + Rayleigh matching (draft lines 880--1034); draft adaptation requires a new theorem or stability advantage to count as more than implementation work.
12. **Exact passages:** Theorem 3.1, Sections 3--5, pp. 320--331.
13. **Assessment:** **Straightforward extension/partial overlap** for the MFS construction.
