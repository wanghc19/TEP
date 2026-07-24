# Paper 001

**Title:** Exact Boundary Conditions for Periodic Waveguides Containing a Local Perturbation  
**Authors:** Patrick Joly, Jing-Rebecca Li, Sonia Fliss  
**Year / journal:** 2006, *Communications in Computational Physics* 1(6), 945--973  
**DOI:** 10.4208/cicp.2006.v1.p945  
**URL:** https://doi.org/10.4208/cicp.2006.v1.p945  
**Local file:** `ref/Joly2006.pdf`  
**Search route:** Local seed; backward and forward chain.

1. **Geometry:** A periodic waveguide with a localized perturbation and a semi-infinite periodic outlet.
2. **PDE and polarization:** Scalar time-harmonic Helmholtz, covering acoustics/TM-type reductions; an absorption parameter is introduced.
3. **Spectral parameter:** Frequency is fixed in the scattering problem; cell propagation eigenvalues are Bloch multipliers.
4. **Function spaces and radiation condition:** (H^1) absorbed solution; decay follows from the propagation operator's spectral radius (<1).
5. **Exterior-domain reduction:** One-cell operators define a compact propagation operator (R^+); the exact DtN map is expressed from (R^+).
6. **Numerical discretization:** Cell problems plus a stationary operator Riccati equation; FEM context.
7. **Main theoretical results:** Theorem 3.1 gives existence, compactness, injectivity, and (ho(R^+)<1); Theorem 4.1 gives the unique Riccati solution satisfying the spectral-radius selection.
8. **Main numerical results:** Demonstrates computation of the propagation/DtN operators; lossless selection is discussed rather than fully established.
9. **Explicit assumptions:** Positive absorption, periodic exterior, compatible cell trace spaces.
10. **Limitations/open questions:** Remark 5.1 explicitly lacks a proof that eigenfunctions are complete; Section 8 says the rigorous analysis relies on absorption and the limit is future work.
11. **Relation to current draft:** Direct prior art for the absorbing-DtN remark (draft lines 392--433), cell propagation/Riccati logic, and Bloch multipliers (lines 1036--1150).
12. **Exact passages:** Theorems 3.1 and 4.1; Remarks 4.2, 5.1, 6.1--6.3; Section 8.
13. **Assessment:** **Already solved** for the absorbed propagation/DtN construction; lossless relation-valued formulation remains technically different.
