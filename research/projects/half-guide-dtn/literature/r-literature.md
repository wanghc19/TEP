# Literature Review

This is an initial, non-final review. It records what has been checked so far
and what still needs verification before the final feasibility report.

## Joly, Li, Fliss 2006

Full title: `Exact Boundary Conditions for Periodic Waveguides Containing a
Local Perturbation`.

Authors: Patrick Joly, Jing-Rebecca Li, Sonia Fliss.

Venue/year from local PDF: Communications in Computational Physics, 1(6),
945-973, 2006.

Direct relevance:

- Introduces exact boundary conditions for periodic waveguides with a local
  perturbation.
- Defines half-guide propagation operators \(R_\epsilon^\pm\), local cell
  DtN-like blocks \(T_{pq}\), and a stationary operator Riccati equation.
- Uses absorption and a limiting absorption discussion to select the physical
  branch.

Key checked formulas:

\[
  T_{10}R^2+(T_{00}+T_{11})R+T_{01}=0,\qquad \rho(R)<1.
\]

Important difference from current project:

- The paper treats closed waveguides and finite-element style local cell
  problems. The current project uses open Rayleigh ports in a y-quasiperiodic
  setting and a Muller BIE in the center cell.
- The sign of the final boundary operator must be translated carefully to the
  project convention \(N^\pm=\pm\partial_xu\).

## Coatleven 2012

Full title: `Helmholtz equation in periodic media with a line defect`.

Author: Julien Coatleven.

Venue/year/DOI from local PDF metadata: Journal of Computational Physics, 231,
1675-1704, 2012, DOI `10.1016/j.jcp.2011.10.022`.

Direct relevance:

- Handles an unbounded line defect in a periodic medium.
- Uses a Floquet-Bloch transform along the defect and DtN maps in transverse
  periodic half-spaces.
- Reproduces the Joly/Fliss DtN construction for quasi-periodic boundary
  conditions and explicitly states the same Riccati equation and \(K=T_{00}+T_{10}R\).

Important difference from current project:

- Coatleven couples DtN maps to a Lippmann-Schwinger volume formulation, not a
  Muller boundary integral representation on a center obstacle.
- Its rigorous treatment is absorbing. The zero-absorption case is described as
  not fully covered theoretically; numerical evidence is discussed through
  limiting absorption behavior.

## Barnett and Greengard

Full title from local PDF: `A new integral representation for quasiperiodic
fields and its application to two-dimensional band structure calculations`.

Authors: Alex Barnett and Leslie Greengard.

Direct relevance:

- Supports the current project's quasi-periodic BIE/proxy philosophy.
- Important for avoiding quasi-periodic Green function failures at empty-cell
  resonances.

Difference from DtN task:

- Focuses on band-structure calculations in periodic media, not semi-infinite
  periodic half-guide DtN maps.

## Linton 1998

Full title from local PDF: `The Green's function for the two-dimensional
Helmholtz equation in periodic domains`.

Author: C. M. Linton.

Direct relevance:

- Provides periodic Green function formulas and convergence strategies.
- Relevant to the current qpgreen implementation and Rayleigh expansions near
  grazing modes.

Difference from DtN task:

- It is a Green-function computation reference, not a half-guide DtN or Riccati
  method paper.

## Surface Green Function / Self-Energy Literature

The recursive Green function literature for semi-infinite periodic systems is
potentially relevant because the surface self-energy is a discrete analogue of
a half-space impedance/DtN map. The Sancho-Rubio iterative schemes are the main
starting point to verify.

Current status: source URLs and DOI leads have been logged, but this route has
not yet been connected algebraically to the current BIE/Rayleigh discretization.

