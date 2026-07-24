# Muller-DtN Coupling Options

This note compares three possible center-region couplings.

## Scheme A: Keep The Current Homogeneous Background Component

Unknowns:

\[
  (\eta,\xi),\qquad
  \eta=\begin{bmatrix}\tau\\-\sigma\end{bmatrix},\qquad
  \xi=\begin{bmatrix}\xi^\rightarrow\\\xi^\leftarrow\end{bmatrix}.
\]

Center BIE row:

\[
  A_{\mathrm{QP}}\eta+B_{\partial\Omega^0}\xi=0.
\]

Port equations:

\[
  \Pi_{\ell,N}^\pm\eta+\Pi_{h,N}^\pm\xi
  =
  \Lambda^\pm
  \left(\Pi_{\ell,D}^\pm\eta+\Pi_{h,D}^\pm\xi\right).
\]

Advantages:

- closest to existing `scat_ld_lead_in.m` and `tep_edc_scan_local.m`;
- keeps the current Rayleigh coefficient anchoring strategy;
- gives a clean A/B comparison against outgoing trace matching.

Risks:

- still depends on a single-cell representation assumption;
- coefficient nullspace may survive and must be checked by field reconstruction;
- \(\xi\) can be ill-conditioned for high evanescent channels if anchoring is
  not handled carefully.

Current recommendation: primary prototype path.

## Scheme B: Add Wall Traces Or Wall Densities To The BIE

Unknowns would include traces or layer densities on

\[
  \partial\Omega^0,\qquad \Gamma^-,\qquad \Gamma^+.
\]

Then one can eliminate wall Neumann or Dirichlet data using the DtN equations.

Advantages:

- may eliminate \(u_h[\xi]\);
- resembles standard bounded-domain BIE-DtN couplings;
- may make the physical trace unknowns explicit.

Risks:

- artificial wall endpoints and quasi-periodic top/bottom matching are delicate;
- hypersingular or Calderon blocks may be required;
- current Kress/Nystrom code is optimized for smooth obstacle boundaries, not
  open wall segments with corners;
- implementation complexity is significantly higher.

Current recommendation: backup theoretical route, not first prototype.

## Scheme C: Center FEM/Volume Discretization Plus Lead DtN

Use a volume discretization in the center cell and attach lead DtN maps on the
vertical artificial boundaries.

Advantages:

- closest to the Joly/Coatleven finite-element setting;
- useful as an independent validation reference;
- avoids some BIE representation-nullspace questions.

Risks:

- introduces a new numerical stack into a BIE-focused project;
- mesh generation and material-interface accuracy add project complexity;
- not ideal as the main implementation path unless BIE-DtN coupling fails.

Current recommendation: validation benchmark only.

## Comparison Table

| Scheme | Main unknowns | Removes xi? | Closest to code? | Main risk | Recommendation |
| --- | --- | ---: | ---: | --- | --- |
| A | `eta, xi` | No | Yes | representation/nullspace | Primary |
| B | obstacle plus wall traces/densities | Possibly | No | wall BIE complexity | Backup |
| C | volume/FEM unknowns | Yes | No | new discretization stack | Reference only |

## Current Recommendation

Proceed with Scheme A until the homogeneous and simple periodic-lead DtN tests
are reliable. Revisit Scheme B only if \((\eta,\xi)\) nullspaces or conditioning
make Scheme A unsuitable.

