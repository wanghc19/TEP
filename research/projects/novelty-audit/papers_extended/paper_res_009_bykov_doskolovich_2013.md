Title: Numerical Methods for Calculating Poles of the Scattering Matrix With Applications in Grating Theory  
Authors: Dmitry A. Bykov; Leonid L. Doskolovich  
Year: 2013  
Journal / archive: Journal of Lightwave Technology 31(5), 793--801; arXiv:1206.3388  
DOI: 10.1109/JLT.2012.2234723  
URL: https://doi.org/10.1109/JLT.2012.2234723  
Local file: none  
Search route: required scattering-matrix pole/contour query.

1. **Geometry:** periodic metal-dielectric diffraction grating.
2. **PDE/polarization:** Maxwell scattering matrix.
3. **Parameter:** complex frequency.
4. **Class:** resonant grating modes as scattering-matrix poles.
5. **Radiation:** outgoing Fourier/Rayleigh scattering channels.
6. **Periodic leads:** periodic grating basis.
7. **Multiplier selection:** not a periodic half-lead Bloch split.
8. **Method:** scattering matrix.
9. **NEP:** poles of `S(omega)` / zeros of `S^{-1}`.
10. **Eigensolver:** iterative linearization and Cauchy moments.
11. **Main result:** pole expansion equations (3)--(9); generalized eigenvalue
    linearization equations (13)--(15); improved iteration in Section IV.
12. **Convergence:** numerical convergence and stability for large S matrices.
13. **Branches:** assumes an analytic neighborhood of the chosen contour/pole.
14. **Spurious roots:** avoids unstable `1/det S=0` equation (10) and exploits
    the rank structure of residues.
15. **Numerics:** grating pole near `1.859e15-1.613e12 i` s^-1.
16. **Limitations:** no BIE or threshold crossing.
17. **Draft relation:** existing one-cell S could support this workflow only
    after its branches and poles are exposed.
18. **Reusable theory:** Laurent/residue factorization.
19. **Reusable numerics:** all-poles contour and local refinement.
20. **Assessment:** already solves the generic pole-search component.

