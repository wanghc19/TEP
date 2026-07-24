# Notation and assumptions

## Geometry and coefficients

The horizontal-period quotient is the cylinder

\[
\mathscr X_\beta=\mathbb R\times(\mathbb R/d\mathbb Z),
\qquad u(x,y+d)=e^{i\beta d}u(x,y).
\]

The displayed center cell is
\(C=(X_L,X_R)\times(0,d)\).  The inclusion \(\Omega\) has a `C^2`
boundary \(\Sigma\), is compactly contained in the open cell, and is separated
from the vertical ports.  The normal \(\nu\) on \(\Sigma\) points from the
inclusion into the background.  The main theorem is stated for real
\(k>0\), real \(\beta\), and real \(n>0\), with exterior and interior
wavenumbers

\[
k_e=k,\qquad k_i=nk.
\]

The transmission conditions are \(\gamma^+u=\gamma^-u\) and
\(\partial_\nu^+u=\partial_\nu^-u\).  These are the TM conditions in the
draft.  A weighted TE flux condition would change the Muller system and is
outside this investigation.

## Function spaces in plain language

- `L^2` consists of square-integrable fields.  Two fields that differ on a set
  of area zero are identified.
- `H^1` consists of `L^2` fields whose first weak derivatives are also `L^2`.
  A weak derivative is defined by integration by parts against smooth compactly
  supported test functions, so pointwise differentiability is unnecessary.
- For a Lipschitz boundary, the boundary value of an `H^1` field belongs to
  `H^{1/2}`.  The exponent `1/2` measures the half derivative lost on taking a
  trace.
- If an `H^1` Helmholtz solution has `Delta u` in `L^2`, its outward conormal
  derivative is naturally a functional on `H^{1/2}` and therefore belongs to
  the dual space `H^{-1/2}`.

The solution class is

\[
u_e\in H^1_\beta(C\setminus\overline\Omega),\qquad
u_i\in H^1(\Omega),
\]

with the Helmholtz equations understood weakly and the two transmission
equalities understood in `H^{1/2}(Sigma)` and `H^{-1/2}(Sigma)`.  For the
step-by-step Green calculation one may first assume piecewise `H^2`; density of
smooth data and continuity of all trace and potential maps then give the `H^1`
version.

## Quasiperiodic Fourier spaces

Set

\[
\beta_m=\beta+\frac{2\pi m}{d},\qquad
\psi_m(y)=d^{-1/2}e^{i\beta_my}.
\]

For \(f=\sum f_m\psi_m\), define

\[
\|f\|_{H^s_\beta}^2
=\sum_{m\in\mathbb Z}(1+|\beta_m|^2)^s|f_m|^2.
\]

This is the Fourier definition of the quasiperiodic Sobolev space on one
horizontal period.  The Dirichlet trace uses `s=1/2`; the Neumann trace uses
`s=-1/2`.

Choose

\[
\gamma_m=(k^2-\beta_m^2)^{1/2},\qquad
\operatorname{Im}\gamma_m\geq0.
\]

A Wood threshold occurs when \(\gamma_m=0\).  Away from thresholds, a
homogeneous field has the unique modewise form

\[
h=\sum_m a_m e^{i\gamma_m(x-X_L)}\psi_m
  +\sum_m b_m e^{-i\gamma_m(x-X_R)}\psi_m.
\]

The natural coefficient space on a finite cell is

\[
\ell^2_{1/2,\beta}\times\ell^2_{1/2,\beta},\qquad
\sum_m(1+|\beta_m|^2)^{1/2}(|a_m|^2+|b_m|^2)<\infty.
\]

For large evanescent orders the two anchored exponentials decay inward from
opposite ports; direct integration shows that the `H^1` energy of each order is
comparable to \(|\beta_m|(|a_m|^2+|b_m|^2)\).  This explains the half-order
weight used in the draft.

## Layer potentials and jumps

Let \(\Phi_\kappa=(i/4)H_0^{(1)}(\kappa|x-z|)\), and define

\[
S_\kappa\sigma=\int_\Sigma\Phi_\kappa\sigma\,ds,
\qquad
D_\kappa\tau=\int_\Sigma\partial_{\nu_z}\Phi_\kappa\tau\,ds.
\]

The exterior potentials use the `y`-quasiperiodic outgoing Green function and
are denoted by `S_QP` and `D_QP`; the interior potentials use the free-space
kernel.  Superscript `+` means the exterior trace and `-` the interior trace.
The convention consistent with the draft's Muller matrix is

\[
\gamma^\pm D\tau=K\tau\pm\tfrac12\tau,
\qquad
\partial_\nu^\pm S\sigma=K'\sigma\mp\tfrac12\sigma.
\]

Thus \(D\) jumps by `+tau` and the normal derivative of \(S\) jumps by
`-sigma`.  The natural density pair is

\[
(\tau,\sigma)\in H^{1/2}(\Sigma)\times H^{-1/2}(\Sigma).
\]

With the code/draft vector \(\eta=(\tau,-\sigma)^T\), the interface mismatch
of the common-density field is

\[
A_{\rm QP}\eta=
\begin{bmatrix}
I+K_e-K_i&S_i-S_e\\
T_e-T_i&I+K_i'-K_e'
\end{bmatrix}\eta.
\]

On a `C^2` interface this is identity plus a compact operator on
`H^{1/2} x H^{-1/2}`: the leading singularities of the equal-type operators
cancel in each difference, while the nonzero quasiperiodic images are smooth
near `Sigma`.

## Three different spectral exclusions

1. **Wood exclusion:** needed for the standard quasiperiodic Green function and
   for two distinct exponential solutions in every Fourier order.
2. **Physical guided modes:** zeros of the homogeneous physical mismatch
   operator.  They are intended solutions in the TEP problem and do not by
   themselves make a field representation false.
3. **Complementary or swapped transmission modes:** outgoing fields with
   wavenumber `k_e` inside and `k_i` outside.  They control injectivity and
   completeness of the common-density synthesis map.  Excluding them is the
   substantive additional hypothesis missing from Conjecture 1.

