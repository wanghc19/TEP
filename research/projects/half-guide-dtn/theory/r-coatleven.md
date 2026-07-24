# Coatleven Comparison

This is an initial applicability analysis of Coatleven 2012 relative to the
current TEP DtN attempt.

## Checked Source

Local file: `pdf/Coatleven2012.pdf`.

The PDF metadata identifies:

- title: `Helmholtz equation in periodic media with a line defect`;
- author: Julien Coatleven;
- journal: Journal of Computational Physics, 231 (2012), 1675-1704;
- DOI: `10.1016/j.jcp.2011.10.022`.

## Shared Structure With This Project

Coatleven studies an unbounded periodic medium perturbed by an unbounded line
defect. The solution strategy has two separations:

1. use a Floquet-Bloch transform along the line defect direction;
2. use DtN maps to close the remaining transverse periodic half-guides.

This is structurally close to the current project because the present TEP code
also separates a center region from periodic left/right leads and uses a
quasi-periodic parameter along the transverse direction.

## DtN Construction

On pp. 1681-1684 of the local PDF, Coatleven reproduces the Joly/Fliss local
cell construction for quasi-periodic boundary conditions. The propagation
operator \(R\) is defined by taking boundary data from the current cell wall to
the next cell wall:

\[
  R u = w(u)|_{C_1}.
\]

The local cell problems \(e_0(u)\) and \(e_1(u)\) impose Dirichlet data on the
left or right boundary of a single cell. The four blocks \(T_{pq}\) are then
used in

\[
  T_{10}X^2+(T_{00}+T_{11})X+T_{01}=0,
  \qquad \rho(X)<1.
\]

The half-guide boundary coefficient is written as

\[
  K=T_{00}+T_{10}R.
\]

As in the Joly notes, this \(K\) must be translated into the current project
port convention before being used as \(N^\pm=\Lambda^\pm D^\pm\).

## Absorption And Lossless Limit

Coatleven's rigorous setup uses absorption. In Section 8, the author explicitly
states that the no-absorption case is not fully treated theoretically because a
well-posedness result is lacking. The limiting absorption principle is used as
the expected physical guide, and numerical observations require many more
quadrature points when absorption is zero.

Implication for this project:

- absorbing DtN is the safest mathematically;
- common band gaps may permit a direct decaying DtN;
- general lossless pass bands should not be treated as automatically covered by
  Coatleven's proof.

## Coupling Difference

Coatleven couples the DtN maps to a generalized Lippmann-Schwinger equation.
The current TEP project wants to couple DtN maps to a center-cell Muller BIE:

\[
  A_{\mathrm{QP}}\eta+B_{\partial\Omega^0}\xi=0.
\]

The DtN half-guide construction is reusable in spirit, but the central coupling,
nullspace checks, and physical-field reconstruction must be rederived for the
Muller unknowns \((\eta,\xi)\).

## Initial Conclusion

Coatleven supports using Joly-style local-cell Riccati DtN maps for periodic
half-guides with quasi-periodic transverse boundary conditions. It does not by
itself prove the proposed TEP Muller-DtN eigenvalue formulation, especially in
lossless pass bands or near thresholds.

