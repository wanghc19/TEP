# DtN Numerical Methods

This is the initial method comparison for computing periodic half-guide DtN
maps. It will be expanded after periodic-obstacle experiments.

## Method 1: Local Cell DtN Blocks Plus Riccati Equation

For one cell, solve local Dirichlet problems to obtain

\[
  \begin{bmatrix}n_0\\n_1\end{bmatrix}
  =
  \begin{bmatrix}T_{00}&T_{01}\\T_{10}&T_{11}\end{bmatrix}
  \begin{bmatrix}D_0\\D_1\end{bmatrix}.
\]

With the Joly right-lead propagation convention, the stable propagation
operator is selected from

\[
  T_{10}R^2+(T_{00}+T_{11})R+T_{01}=0,
  \qquad \rho(R)<1
\]

in the absorbing case. This method most directly avoids explicit outgoing
Bloch trace synthesis, but a robust matrix Riccati solver is still needed.

Risks:

- Newton iteration needs a stable projection or branch-selection step.
- In a lossless pass band, \(\rho(R)<1\) does not select propagating outgoing
  modes without limiting absorption.
- Near cell Dirichlet resonances, the local block construction can be singular.

## Method 2: Quadratic Eigenvalue Problem / Stable Invariant Subspace

The Riccati equation is associated with

\[
  \left[T_{10}\lambda^2+(T_{00}+T_{11})\lambda+T_{01}\right]\varphi=0.
\]

After linearization, QZ/generalized Schur can select the stable invariant
subspace \(|\lambda|<1\). In finite dimensions this may be more reliable than
Newton for the first prototype because it gives direct spectral diagnostics.

Risks:

- \(|\lambda|\approx1\) makes the stable/unstable split ill-conditioned.
- Multiple or defective multipliers may require generalized Bloch modes.
- Completeness of eigenfunctions is an assumption in the infinite-dimensional
  theory, explicitly noted as open by Joly et al. for general periodic guides.

## Method 3: Scattering Matrix To DtN

Existing code can construct outgoing trace bases

\[
  (D_{\mathrm{out}}^\pm,N_{\mathrm{out}}^\pm).
\]

If \(D_{\mathrm{out}}^\pm\) is square and nonsingular, one can form

\[
  \Lambda^\pm=N_{\mathrm{out}}^\pm(D_{\mathrm{out}}^\pm)^{-1}.
\]

This is useful as a diagnostic bridge and for comparing signs. It is not yet a
true replacement for the outgoing trace-subspace method because the construction
still uses Bloch modes and assumes the outgoing graph can be represented over
Dirichlet data.

Risks:

- \(D_{\mathrm{out}}^\pm\) may be singular or badly conditioned.
- Pseudoinverse use could hide a genuine Cauchy-data relation that is not a
  graph over Dirichlet data.
- Bad outgoing counts already occur in current scans near neutral modes.

## Method 4: Recursive Surface Green Function / Self-Energy

The discrete periodic half-space can often be reduced by a fixed-point Schur
complement or doubling iteration. In a finite-element or finite-difference
setting, this computes a surface self-energy that is algebraically analogous to
a DtN/impedance map.

For the current BIE/Rayleigh discretization this remains a candidate analogy,
not yet an implementation. It may become useful if local-cell blocks are written
as coupled left/right boundary Schur complements.

## Method 5: Absorbing Continuation

Introduce absorption, for example

\[
  k^2\mapsto k^2+i\varepsilon,\qquad \varepsilon>0,
\]

compute \(\Lambda_\varepsilon^\pm\), and study the limit
\(\varepsilon\downarrow0\).

This is theoretically safest for selecting \(R\) because the stable spectrum
lies strictly inside the unit disk. It also matches the Joly/Coatleven framework.

Open numerical question: how small can \(\varepsilon\) be before the stable split
and DtN conditioning become unusable near band edges or Wood anomalies?

