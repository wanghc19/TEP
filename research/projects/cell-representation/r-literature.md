# Literature notes and theorem index

All page references below refer to the printed article page when available;
PDF page numbers are added when they differ.  Local copies were inspected for
the first five items.  No theorem number is recorded unless it was verified.

## Core sources

### Barnett and Greengard (2010)

Alex H. Barnett and Leslie Greengard, “A New Integral Representation for
Quasiperiodic Fields and Its Application to Two-Dimensional Band Structure
Calculations,” *Journal of Computational Physics* 229(19), 6898--6914.
DOI: <https://doi.org/10.1016/j.jcp.2010.05.029>.  Open preprint:
<https://arxiv.org/abs/1001.5464>.

- Section 3, equations (15)--(20), printed pp. 6903--6904: uses exactly the
  same-density free-space-interior/quasiperiodic-exterior representation as the
  draft and derives the identity-plus-difference Muller operator.
- Definition 3 and equation (14), printed p. 6903: identifies divergence of the
  quasiperiodic Green function at empty-cell resonances.
- Theorem 4, printed p. 6904: proves that, away from empty resonances, the
  density operator has a nonzero nullspace exactly at a Bloch eigenvalue.
- Appendix A, printed pp. 6912--6913: gives the Green formulas, proves
  cancellation of opposite quasiperiodic wall terms, and uses a
  swapped-wavenumber complementary transmission problem to prove both
  directions.  This is the central template for the present analysis.
- Limitation: the paper treats a doubly periodic torus, not a finite cell with
  open vertical ports.  Its free-space complementary problem is uniquely
  solvable; on the present quasiperiodic cylinder, a swapped problem may itself
  have guided modes.  The report therefore states this extension conditionally
  instead of silently importing Theorem 4.

### Linton (1998)

C. M. Linton, “The Green's Function for the Two-Dimensional Helmholtz Equation
in Periodic Domains,” *Journal of Engineering Mathematics* 33, 377--402.
DOI: <https://doi.org/10.1023/A:1004377501747>.

- Section 2, equations (2.13)--(2.17), printed pp. 379--380: derives the
  spectral expansion of the one-dimensionally quasiperiodic Green function and
  separates propagating from evanescent orders.
- The factor `1/gamma_m` makes the threshold singularity explicit.
- Role here: fixes the branch/radiation convention and justifies the draft's
  outgoing layer far field away from Wood anomalies.

### Kress (1991)

Rainer Kress, “Boundary Integral Equations in Time-Harmonic Acoustic
Scattering,” *Mathematical and Computer Modelling* 15(3--5), 229--243.
DOI: <https://doi.org/10.1016/0895-7177(91)90068-I>.

- Section 1, printed pp. 230--232: definitions of single and double layers,
  jump relations, Green representation, and the Fredholm uniqueness argument.
- Printed p. 231: explains the classical interior-resonance failure of a pure
  double-layer equation and how a combined representation removes it.
- Role here: supplies the elementary layer-potential logic and demonstrates why
  field uniqueness and density uniqueness are distinct questions.
- Limitation: the article's basic presentation uses continuous densities on a
  `C^2` curve.  Sobolev mapping statements in the report are therefore paired
  with the next source.

### Dominguez, Lyon, and Turc (2016)

Victor Dominguez, Mark Lyon, and Catalin Turc, “Well-Posed Boundary Integral
Equation Formulations and Nystrom Discretizations for the Solution of
Helmholtz Transmission Problems in Two-Dimensional Lipschitz Domains,”
arXiv:1509.04415v2. <https://arxiv.org/abs/1509.04415>.

- Section 3.1: layer potentials, trace relations, and Calderon identities.
- Section 4.1, especially Theorems 4.1--4.4: Sobolev mapping/compactness
  properties and model invertible Calderon combinations.
- Section 4.2, Theorems 4.5--4.8: well-posedness of several transmission BIEs.
- Role here: supports the `H^{1/2} x H^{-1/2}` formulation and the assertion
  that equal-type wavenumber differences gain regularity/are compact.
- Limitation: it is a free-space Lipschitz transmission analysis, so the report
  uses it locally on `Sigma`; periodic radiation is handled separately.

### Hohage and Soussi (2012/2018 preprint copy)

Thorsten Hohage and Sofiane Soussi, “Riesz Bases and Jordan Form of the
Translation Operator in Semi-Infinite Periodic Waveguides,” local file
`pdf/Hohage2013.pdf`; open preprint identifier visible in the PDF:
arXiv:1010.1738v2.

- Theorem 2.2 and Sections 2--3: modal/Riesz-basis description of solutions and
  traces in semi-infinite periodic waveguides.
- Appendix A: explains why propagating-mode selection at crossings and zero
  group velocity is subtler than the scalar homogeneous Rayleigh rule.
- Appendix B, Proposition B.2: an impedance trace yields uniqueness; other
  traces can fail at exceptional frequencies.
- Role here: confirms that radiation/uniqueness conditions in periodic
  waveguides are genuine spectral assumptions, not formal sign choices.

## Additional sources

### Hiptmair, Moiola, and Spence (2022)

Ralf Hiptmair, Andrea Moiola, and Euan A. Spence, “Spurious
Quasi-Resonances in Boundary Integral Equations for the Helmholtz Transmission
Problem,” *SIAM Journal on Applied Mathematics* 82(4), 1446--1469.
DOI: <https://doi.org/10.1137/21M1447052>; open preprint:
<https://arxiv.org/abs/2109.08530>.

- Sections 1.3--1.5 and Theorems 1.10/1.12 relate direct transmission BIEs,
  Calderon projectors, and solution operators for the physical and swapped
  transmission problems.
- Role here: modern rigorous support for separating physical resonances from
  fictitious/complementary transmission resonances.
- This paper is not used as a ready-made periodic-cylinder theorem; the report
  transfers only the structural Calderon mechanism and labels the periodic
  step as an explicit hypothesis.

### McLean (2000)

William McLean, *Strongly Elliptic Systems and Boundary Integral Equations*,
Cambridge University Press, 2000, ISBN 978-0-521-66332-8. Publisher page:
<https://www.cambridge.org/core/books/strongly-elliptic-systems-and-boundary-integral-equations/9B19CE3C32E5D684CFE5D3C0E41D25B0>.

- Chapter 3: Sobolev spaces and traces; Chapter 4: Green identities and
  regularity; Chapters 6--8: surface potentials and boundary integral
  operators.
- Role here: general trace, conormal derivative, and weak Green-identity
  background.
- The exact theorem numbering was not available in the inspected publisher
  sample, so no unverified theorem number is claimed.

## Citation decisions

- Barnett--Greengard Appendix A is cited as a proof template, not as a theorem
  that automatically covers the open-port cylinder.
- Linton is cited for the spectral Green function, not for Sobolev completeness
  of every finite-cell solution; that completeness is proved mode by mode in
  the report.
- Physical guided modes and complementary modes are never conflated.
- No blog, Q&A page, or AI-generated text is used as theoretical evidence.

