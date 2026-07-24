Title: An Integral Method for Solving Nonlinear Eigenvalue Problems  
Authors: Wolf-Jürgen Beyn  
Year: 2012  
Journal / archive: Linear Algebra and its Applications 436(10), 3839--3863; arXiv:1003.1580  
DOI: 10.1016/j.laa.2011.03.030  
URL: https://doi.org/10.1016/j.laa.2011.03.030  
Local file: none  
Search route: required contour-NEP query and backward chain from photonic NEPs.

1. **Geometry:** abstract finite-dimensional analytic matrix function.
2. **PDE/polarization:** not applicable.
3. **Parameter:** complex eigenvalue.
4. **Class:** isolated zeros/eigenvalues of a holomorphic NEP.
5. **Radiation:** supplied by the application, not the solver.
6. **Periodic leads:** none.
7. **Multiplier selection:** none.
8. **Method:** contour moments and Keldysh theorem.
9. **NEP:** `T(z)v=0` with analytic `T`.
10. **Eigensolver:** rank-revealing SVD of moment matrices and reduced linear EVP.
11. **Main result:** Sections 2--3 reduce the NEP via contour integrals; the core
    simple/multiple-eigenvalue algorithms and perturbation results occupy
    journal pp. 3844--3857.
12. **Convergence:** quadrature and perturbation analysis.
13. **Branches:** branch points/cuts inside the contour violate the assumptions.
14. **Spurious roots:** rank and residual checks, but application poles must be
    handled separately.
15. **Numerics:** benchmark NEPs.
16. **Limitations:** no physical outgoing or meromorphic pole subtraction.
17. **Draft relation:** usable only after all nonanalytic MATLAB decisions are
    removed from `T(k)`.
18. **Reusable theory:** Keldysh moment reduction.
19. **Reusable numerics:** complete eigenvalue count in a branch-free domain.
20. **Assessment:** generic solver is established and not a novelty claim.
