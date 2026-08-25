# I1 discrete $A_{\mathrm{def}}$ review

## Scope and process

This review covers only
[[research/projects/eig-apost/implementation/i1/design|the discrete I1 design]].
No code was assembled and no Octave, MATLAB, DtN, locator, contour, or root computation was
run. Two independent Skeptics reviewed the design:

1. continuous-to-discrete hierarchy, trace spaces, normals, signs, dimensions, Schur
   equivalence, and legacy augmented-BIE mapping;
2. projective QZ, stable graph, chart safety, analyticity policy, derivative, balancing, and
   implementation feasibility.

Each reviewer first returned `REVISE`. The design was edited and returned to the same
reviewer until both reported zero design-level blocker.

## Issues found and resolved

| Initial classification | Issue | Resolution |
|---|---|---|
| `BLOCKER` | The left QZ frame did not say whether it represented $z_L$ or $z_R$, which becomes fatal for a regular $\lambda=\infty$ pair. | The left pass is now the reversed relation $B_{\mathrm{sc}}z_R=\mu A_{\mathrm{sc}}z_R$; its frame is directly `RIGHT_CELL_WALL`. Multiplier transport is forbidden. |
| `BLOCKER` | One generalized Sylvester separation direction was being used as if it controlled both deflating-subspace sensitivities. | Original and reversed QZ passes now each retain selected/complement blocks, both Sylvester directions, and a conservative two-direction gate. LAPACK `DIF` estimates remain labelled diagnostics. |
| `BLOCKER` | Pointwise modulus sorting on a complex disk could switch the selected cluster. | Modulus selects only at the real seed. The same isolated cluster is continued; loss of count, separation, or overlap makes the disk unavailable. |
| `BLOCKER` | A weighted reciprocal condition alone can accept a nearly vertical graph; for $D=\varepsilon$, $N=1$, scalar `rcond` equals one. | Dirichlet and Robin charts now use an absolute weighted projection margin $\sigma_{\min}$ for transversality, a separate solve condition number for roundoff, and graph-error divided by the margin. |
| `IMPORTANT CAVEAT` | Exact and discrete DtN notation was mixed in finite matrices. | $\Lambda_\pm$ is reserved for the PDE-defined exact map; finite matrices use $\Lambda_{\pm,h,M}$. |
| `IMPORTANT CAVEAT` | Common-$M$ test restriction, graph-coordinate norm, legacy extractor Cauchy signs, and derivative availability were incomplete. | The coefficient duality and $P^*$ restriction are explicit; chart norms use the induced Cauchy graph Gram; old extractors are mapped to complete D/N blocks; production derivative remains explicitly unavailable. |

## Final Skeptic 1 verdict: spaces, signs, and dimensions

`PASS WITH CONDITIONS` for the finite-dimensional design. Final design-level
`BLOCKER = 0`.

The reviewer confirmed:

- $m=-M{:}M$, $K=2M+1$, and the stated trial/test sizes are internally consistent;
- $\nu_-=-e_x$ and $\nu_+=e_x$ produce the stated left/right Cauchy signs;
- the current $2K\times2K$ safe-DtN matrix is the exact Schur reduction of the
  $4K\times4K$ graph matrix when both Dirichlet charts are invertible;
- the general $(n+2K)$ and $(n+4K)$ center-BIE extensions are dimensionally consistent;
- the reversed-pair left frame is now at the correct reference plane, including regular
  infinite pairs;
- the old $(n+8K)$ finite-tail matrix and far amplitudes have been correctly removed from
  the primary formulation.

Remaining implementation caveat: the absolute weighted `margin_D/R` gates and the
near-vertical graph negative must not be replaced by ratio-only conditioning.

## Final Skeptic 2 verdict: QZ, chart, and implementation

`PASS WITH CONDITIONS`, high confidence. Final design-level `BLOCKER = 0`.

### `IMPORTANT CAVEAT`

- Production `DIF/sep` has not been qualified. Only the small exact-separation assembly
  oracle is currently allowed; a production `xTGSEN/xTGSYL` backend requires a separate
  review of `IJOB`, both `DIF` values, norm, normalization, `PL/PR`, and `INFO`.
- Production $A_{\mathrm{def}}'$ is unavailable because no analytic subspace-tangent
  provider has been frozen. `DERIVATIVE_AVAILABLE=false` continues to block full CR,
  Newton correction, locator, and root work.
- The fixed-row overlap gate must later record its smallest singular value, condition and
  disk minimum. It may not repivot within a disk.

### `MINOR CAVEAT`

- The reversed stable frame retains the historical block names $(A_u,B_u)$. This is
  acceptable only if every artifact also records the reversed pass and
  `RIGHT_CELL_WALL` state-plane label.

## Proof gaps outside the design verdict

The following remain `BLOCKER` for physical/root interpretation, even though they do not
invalidate the finite-dimensional assembly contract:

- half-guide PDE holomorphy and a uniformly separated cluster on the selected complex disk;
- primal/adjoint $C^1$ consistency from the continuous one-cell relation to the
  BIE/Fourier pencil;
- graph-to-DtN and derivative error propagation for the production backend;
- center BIE kernel--field equivalence and exclusion of spectral pollution;
- physical adjoint pairing and eigentrace regularity;
- any saturation/remainder statement needed to turn a next-level correction into a
  remaining-error estimator.

## Authorization boundary

The stable finite-dimensional definitions may be incorporated into `method.tex`.
The next stage may call an Engineer only to implement a new test-local static assembly
oracle with manufactured graph inputs and exact small-problem separation. It may not run
production DtN wall qualification, a real-axis locator, complex disk, contour, root
isolation, or estimator.

Final verdict: `I1_A_DEF_DESIGN_PASS_WITH_CONDITIONS`.
