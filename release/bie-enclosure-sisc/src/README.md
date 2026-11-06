# Package source

`matlab/` holds the MATLAB code used by `reproduce` (search, densities, B fit); `python/` holds the Python code used by both layers for the reliable evaluation (`residual/`, `mass/`, `enclosure/`, `band/`, and the empty-center family in `ex2/`). `.m` files are MATLAB source and `.py` files are Python source.

## Abbreviations in file and identifier names

Several MATLAB files were copied from the authors' research code and keep their original names:

| Name | Meaning |
|---|---|
| `h2d_directch` | Helmholtz two-dimensional direct charge evaluation |
| `qpgreen_mfs_pairmat` | quasi-periodic Green function, method of fundamental solutions, pair matrix |
| `precomp_proxy` | precompute proxy sources |
| `construct_cont` | construct contour |
| `construct_S` | construct scattering matrix |
| `construct_A_QP` | construct quasi-periodic operator matrix |
| `kress_l_splits` | Kress double-layer kernel splits |
| `kress_mn_splits` | Kress single-layer and tangential-derivative kernel splits |
| `quad_kress_rvec` | Kress quadrature row vector |
| `triginterp` | trigonometric interpolation |

Identifiers inside copied helpers may contain the historical labels `I9` (experiment 9), `CM` (compressed moments), `SI` (self-interaction), `CK` (cell kernel), `CG` (grouped trace constant), `RE` (reliable evaluation), `PA` (proxy aggregation), `QP` (quasi-periodic), `TEP` (transmission eigenvalue problem), and `CFIE` (combined-field integral equation). They label algorithms only; none of them names a runtime dependency.

Other abbreviations: BIE = boundary integral equation; MFS = method of fundamental solutions; FMM = fast multipole method; SVD = singular value decomposition; QZ = generalized Schur decomposition; Arb/Acb = real/complex ball arithmetic; LDL* = lower-triangular/diagonal/conjugate-transpose factorization.
