# Joly DtN Derivation Notes

This note records the first derivation pass for the local-cell DtN/Riccati
method and the sign conversion needed for the current TEP port convention.

## Literature Facts Checked From Local PDF

Source: `pdf/Joly2006.pdf`, pp. 952-956.

Joly, Li, and Fliss define two local cell solutions \(u_{\epsilon,0}^+\) and
\(u_{\epsilon,1}^+\), with Dirichlet data on the left boundary \(\Gamma^+\)
and the next right boundary \(\Gamma_1^+\). The four local DtN-like blocks are
defined using the cell outward-normal signs

\[
  T_{00}^+ \varphi=-\partial_x u_{\epsilon,0}^+(\varphi)|_{\Gamma^+},
  \qquad
  T_{01}^+ \varphi=+\partial_x u_{\epsilon,0}^+(\varphi)|_{\Gamma_1^+},
\]

\[
  T_{10}^+ \varphi=-\partial_x u_{\epsilon,1}^+(\varphi)|_{\Gamma^+},
  \qquad
  T_{11}^+ \varphi=+\partial_x u_{\epsilon,1}^+(\varphi)|_{\Gamma_1^+}.
\]

Their propagation operator \(R_\epsilon^+\) is characterized by the stationary
Riccati equation

\[
  T_{10}^+R^2+(T_{00}^+ + T_{11}^+)R+T_{01}^+=0,
\]

with the absorbing selection condition

\[
  \rho(R)<1.
\]

They then write their half-guide operator as

\[
  \Lambda_\epsilon^+ = T_{00}^+ + T_{10}^+R_\epsilon^+.
\]

Important caution: this \(\Lambda_\epsilon^+\) is tied to their boundary
equation/sign convention. It is not automatically the same as the TEP project
operator \(D^+\mapsto N^+=+\partial_xu|_{\Gamma^+}\).

## Homogeneous Scalar Check

For one Fourier/Rayleigh channel in a homogeneous cell \([0,L]\), let

\[
  u''+\gamma^2u=0,
  \qquad
  D_0=u(0),\quad D_1=u(L).
\]

Using cell outward-normal derivatives

\[
  n_0=-\partial_xu(0),\qquad n_1=+\partial_xu(L),
\]

the local cell DtN matrix is

\[
  \begin{bmatrix}n_0\\n_1\end{bmatrix}
  =
  \begin{bmatrix}
    \gamma\cot(\gamma L) & -\gamma\csc(\gamma L)\\
    -\gamma\csc(\gamma L) & \gamma\cot(\gamma L)
  \end{bmatrix}
  \begin{bmatrix}D_0\\D_1\end{bmatrix}.
\]

Thus

\[
  T_{00}=T_{11}=\gamma\cot(\gamma L),
  \qquad
  T_{01}=T_{10}=-\gamma\csc(\gamma L).
\]

For the outgoing right half-guide mode

\[
  u(x)=D_0\exp(i\gamma x),
\]

the propagation factor is

\[
  R=D_1D_0^{-1}=\exp(i\gamma L).
\]

Substitution gives the scalar Riccati residual

\[
  T_{10}R^2+(T_{00}+T_{11})R+T_{01}=0.
\]

However, the TEP right-port outward Neumann trace is

\[
  N^+=+\partial_xu(0)=i\gamma D_0.
\]

Because the cell left outward normal is \(-\partial_x\), the project DtN is

\[
  \Lambda_{\mathrm{TEP}}^+
  =-(T_{00}+T_{01}R)
  =i\gamma.
\]

Meanwhile the Joly-style expression gives

\[
  T_{00}+T_{10}R=-i\gamma,
\]

which is the coefficient \(K\) in a boundary condition of the form

\[
  \partial_xu + Ku =0
\]

for a right-going outgoing mode. This explains the apparent sign difference.

## Left Half-Guide Sign Check

For a left outgoing homogeneous mode anchored at the center left boundary
\(x=X_-\),

\[
  u(x)=D_0\exp(-i\gamma(x-X_-)),
\]

one has

\[
  \partial_xu(X_-)=-i\gamma D_0.
\]

The project convention is

\[
  N^-=-\partial_xu(X_-)=i\gamma D_0.
\]

Therefore both homogeneous half-guide DtN maps satisfy

\[
  \Lambda_{\mathrm{TEP}}^-=\Lambda_{\mathrm{TEP}}^+
  =\operatorname{diag}(i\gamma_m)
\]

in the Rayleigh basis, away from cutoffs and local cell Dirichlet resonances.

## Current Working Interpretation

- Joly's local blocks are directly useful, but the final boundary equation must
  be translated into the project trace convention \(N^\pm=\pm\partial_xu\).
- For the right lead, if \(R\) maps one boundary to the next cell in the positive
  \(x\)-direction, then the project DtN is expected to use
  \[
    \Lambda^+_{\mathrm{TEP}}=-(T_{00}+T_{01}R)
  \]
  under the block definitions above.
- For the left lead, either reverse the cell orientation or use the reciprocal
  propagation direction consistently. The final formula should be checked
  against the homogeneous identity \(\Lambda^-_{\mathrm{TEP}}=i\Gamma\).

## Open Items

- Reconcile the exact left-lead block ordering with Coatleven's statement that
  the other half-guide is the same apart from left/right boundary inversion.
- Check whether a general obstacle lead should expose DtN as an operator graph
  rather than a globally defined matrix, especially near guided modes, band
  edges, or thresholds.
- Verify how absorption is best introduced in this project: \(k^2\mapsto
  k^2+i\varepsilon\), complex \(k\), or another convention matching Joly.

