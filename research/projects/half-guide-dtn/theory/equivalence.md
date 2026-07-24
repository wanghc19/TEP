# Equivalence Analysis

This is an initial theoretical chain for the proposed DtN formulation. It is not
a complete proof.

## Candidate Discrete/Continuous Formulation

The target equation is

\[
\mathcal A_{\mathrm{DtN}}(k,\beta)
\begin{bmatrix}\eta\\\xi\end{bmatrix}=0,
\]

where

\[
\mathcal A_{\mathrm{DtN}}=
\begin{bmatrix}
A_{\mathrm{QP}} & B_{\partial\Omega^0}\\
\Pi_{\ell,N}^+ - \Lambda^+\Pi_{\ell,D}^+
&
\Pi_{h,N}^+ - \Lambda^+\Pi_{h,D}^+
\\
\Pi_{\ell,N}^- - \Lambda^-\Pi_{\ell,D}^-
&
\Pi_{h,N}^- - \Lambda^-\Pi_{h,D}^-
\end{bmatrix}.
\]

Here

\[
  N^+=+\partial_xu|_{\Gamma^+},\qquad
  N^-=-\partial_xu|_{\Gamma^-}.
\]

## 1. Absorbing Problem

Assumption: introduce absorption by

\[
  k^2\mapsto k^2+i\varepsilon,\qquad \varepsilon>0.
\]

Literature support from Joly and Coatleven:

- half-guide Dirichlet problems are well posed;
- the propagation operator \(R_\varepsilon\) exists and satisfies
  \(\rho(R_\varepsilon)<1\);
- the local-cell Riccati equation has a unique compact solution satisfying the
  stable spectral-radius condition;
- DtN maps can be computed from local problems.

Derivation for this project:

If the center Muller representation is valid and unique modulo no physical
nullspace, then imposing

\[
  N^\pm=\Lambda^\pm_\varepsilon D^\pm
\]

on the two artificial boundaries is equivalent to attaching the two absorbing
periodic half-guides. The bounded-domain formulation is then equivalent to the
absorbing unbounded problem.

Unproved project-specific point:

- The center single-cell representation with \((\eta,\xi)\) must represent all
  relevant exterior center-cell solutions and must not introduce coefficient
  null vectors that generate zero physical field.

## 2. Lossless Common Band Gap

Working conjecture:

If \((k,\beta)\) lies in a common spectral gap of both left and right leads, all
physically admissible half-guide modes decay exponentially away from the center.
Then a decaying DtN may be defined without an explicit limiting absorption
procedure, and the stable propagation operator should satisfy

\[
  \rho(R)<1.
\]

This is the safest lossless regime for defect-mode eigenvalue searches.

Required checks:

- no lead guided mode at the same \((k,\beta)\);
- no threshold or band-edge degeneracy;
- stable/unstable multiplier separation is numerically robust;
- Dirichlet trace is a valid graph coordinate for the Cauchy-data relation.

## 3. General Lossless Frequencies

In a pass band, propagating Floquet multipliers lie on the unit circle. A simple
\(\rho(R)<1\) criterion no longer selects outgoing propagating modes. One needs
limiting absorption, a flux/group-velocity selection, or a more general outgoing
Cauchy-data relation.

Known or expected difficulties:

- band edges create non-separated multipliers and possible Jordan chains;
- Wood anomalies make Rayleigh channel formulas singular;
- lead guided modes can create poles or non-uniqueness in DtN;
- embedded eigenvalues require extra care because outgoing radiation and
  square-integrability diverge as concepts.

## Candidate Proposition

Under the assumptions below, \((k,\beta)\) is a Bloch eigenvalue of the original
line-defect problem if and only if

\[
\mathcal A_{\mathrm{DtN}}(k,\beta)
\begin{bmatrix}\eta\\\xi\end{bmatrix}=0
\]

has a nontrivial coefficient vector generating a nonzero physical field.

Assumptions:

1. \((k,\beta)\) is either absorbing with \(\varepsilon>0\) or lies in a common
   lossless band gap of both leads.
2. The two half-guide DtN maps are well-defined as graphs over Dirichlet traces.
3. The center Muller/Rayleigh representation spans the needed center-cell
   solution space.
4. Coefficient null vectors corresponding to zero physical field are excluded by
   reconstruction or normalization checks.
5. No local lead DtN pole, threshold, or center representation resonance is
   present.

Current status: this is a derivation/conjectural proposition for the project,
not yet a theorem.

