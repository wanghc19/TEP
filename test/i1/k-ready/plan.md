# I1.4 frozen plan

## Claim boundary

This experiment asks only whether the fixed-$M=48$ I1.3 dip belongs to one
sampled, fixed-coordinate, analytic discrete BIE--DtN--$A_{\mathrm{def}}$
family.  A pass is **sampled discrete root readiness**, not a root,
eigenvalue, pole-free theorem, derivative qualification, or estimator result.
Locator, contour, Newton, root isolation, and estimator flags stay false.

## Frozen parent and model

- Scientific parent: `test/i1/k-scan/output/zoom2/result.mat`, lineage token
  `8b72c9c67c7feb5c0cc204ee02287d61fcba7752395102db13e10b0ae1d8e969`.
- Centre: $k_*=1.8327703475952146$.
- I1.3 spacing: $\Delta k=1.9073486323684108\times10^{-7}$.
- Geometry, contrast, walls, $M=48$, mode order, and coarse/fine spatial
  levels are copied exactly from the frozen I1.3 configuration.
- The authoritative CR objects are the unbalanced matrices
  $A_{\mathrm{def}}^D$ and $A_{\mathrm{def}}^G$.  The $|\gamma|$-weighted
  physical score is used only for real-anchor parity and anti-collapse
  diagnostics.

## Fixed analytic representation

1. One logarithmically continued branch supplies every port- and proxy-order
   $\gamma_m(k)$.  No positive-path consumer may recompute a pointwise square
   root.
2. For each spatial level, a thin SVD of the unsolved proxy matrix at $k_*$
   freezes $U_r,V_r,r$, where
   $\sigma_j/\sigma_1\geq10^{-8}$.  Off seed, the only proxy solve is
   $U_r^*A_{\rm pr}(k)V_r z=U_r^*b_{\rm pr}(k)$ and $c=V_rz$.  There is no
   off-seed SVD, `lsqminnorm`, `pinv`, rank change, or solver switch.
3. At $k_*$ only, projective modulus labels the $K=97$ selected cluster.
   Off seed, the entire cluster is continued from its predeclared parent by
   overlap of generalized right eigenspaces; the $K$ largest projection scores
   define a candidate cluster, which is then reordered as a whole.  Eigenvalue
   labels may permute within either cluster.  The score gap between selected
   and complementary candidates and the chordal selected/complement spectral
   separation are recorded.  Membership is never selected by off-seed
   modulus.  The I1.3 row selectors, wall labels, Dirichlet chart, and unknown
   order are fixed.
4. Every actually inverted proxy, BIE, fixed-row, and Dirichlet-chart factor is
   recorded with reciprocal condition estimate and solve residual.  An unsafe
   factor fails closed; no chart or representation is changed.

## Gates

Existing I1 gates are unchanged: solve/QZ residual $10^{-10}$, block maximum
$10^{-8}$, weighted block/pencil/DtN/$A_{\mathrm{def}}$ action
$2\times10^{-9}$, subspace/Cauchy distance $10^{-7}$, overlap $0.9$, fixed-row
and chart margin $100K\epsilon$, condition times $\epsilon$ of $10^{-9}$,
Schur/solve residual $10^3K\epsilon$, anchor score reproduction $10^{-10}$,
$r_{12}\leq0.1$, coarse/fine score ratio at most 2, and basis/scalar
invariance $10^{-12}$.

New I1.4 gates are frozen as follows.

- The proxy rank choice must have either adjacent singular-value gap at least
  2 or deterministic projector repeat error at most $10^{-10}$.
- The reduced proxy factor must have `rcond` at least $10^{-8}$; projected
  residual and backward error are at most $10^{-11}$.
- Each $A_{\mathrm{QP}}$ factor must have `rcond` at least $10^{-8}$ and its
  multiple-right-hand-side solve residual must be at most $10^{-10}$.
  Each fixed-row factor must satisfy `rcond` at least
  $\epsilon/10^{-9}$, margin greater than $100K\epsilon$, and solve residual
  at most $10^3K\epsilon$.  Each Dirichlet block must have `rcond` at least
  $10^{-8}$ and must also pass the existing weighted chart margin,
  condition-times-$\epsilon$, and $10^3K\epsilon$ solve-residual gates.
  These are all factors inverted by the positive evaluator; proxy full and
  shifted residuals are recorded as diagnostics, not silently promoted to a
  different solve.
- At the real anchor, the new representation must agree with the I1.3
  `lsqminnorm` representation to $10^{-8}$ in maximum block entry and
  $2\times10^{-9}$ in weighted block, pencil, and $A_{\mathrm{def}}$ action.
- Branch algebra and round-trip errors are at most $10^{-12}$.
- Cluster continuation must preserve dimensions 97/97.  The difference
  between the smallest selected and largest complementary parent-subspace
  projection scores and the minimum selected/complement projective chordal
  distance must each exceed
  $\tau_{\rm cl}=\max(100K\epsilon,10\epsilon_{\rm QZ})$, where
  $\epsilon_{\rm QZ}$ is the larger original/reversed raw or reordered QZ
  backward residual at that node.  Parent/child selected-subspace overlap must
  be at least 0.9, and neutral/indeterminate counts must remain zero.  Modulus
  counts are recorded only as no-crossing diagnostics.
- For full-matrix central differences, the final CR defect, final two-step
  change in the real derivative, and final two-step change in the imaginary
  derivative are each at most $10^{-6}$.  The last CR defect must not increase,
  except at a documented $100\epsilon$ rounding floor.
- Let $q=(q_L,q_R)$ be the unit right minimum direction of
  $A_{\mathrm{def}}^D$ and let $z=(q,c_-,c_+)$ be its graph lift obtained with
  the already qualified Dirichlet factors.  Require
  $\min(\|q_L\|,\|q_R\|)/\|q\|\geq10^{-3}$ and
  $\min(\|c_-\|,\|c_+\|)/\|z\|\geq10^{-3}$, with graph lift residual at most
  $10^{-10}$.  These are the homogeneous-center and two half-guide
  participations for the present $n=0$ missing-column model; no aggregate
  value may hide a failed side, factor, or node.

## Disk, nodes, and stop rule

Let $d_b$ be the nearest branch-point distance over all port and proxy orders.
The first radius is

$$
r_0=\min(2\Delta k,d_b/4)=3.8146972647368216\times10^{-7}.
$$

Only $r_0,r_0/2,r_0/4$ may be attempted, in that order.  Each attempt uses the
centre, eight half-radius nodes, and nested 16/32-point boundaries.  The fixed
continuation tree is a star from the centre to every node.  Closure is checked
on the four cardinal boundary nodes by a second fixed route through the
preceding counter-clockwise cardinal node; direct/second-route subspace overlap
must be at least 0.9.  CR uses the centre and the eight half-radius nodes on
both spatial levels, with
$h_0=\min(r/32,10^{-4}\max(1,|k_*|))$ and $h_0,h_0/2,h_0/4$.

The first complete passing disk is accepted.  Within an attempt, the first
hard failure stops downstream checks and records them as `NOT_EVALUATED`.
Only the next predeclared smaller radius may then run.  No threshold, rank,
chart, solver, node set, or model may change.  Three failed attempts imply
`I1_4_FAIL`.

## Required negatives

The same checkers must reject: one actual consumer recomputing a pointwise
square root; an off-seed proxy SVD/`lsqminnorm`/rank reselection; off-seed
modulus QZ membership reselection; one actual port/proxy branch sign flip; an
actual selected/complement QZ-label swap; row repivot/fingerprint drift; a
near-vertical Dirichlet graph; a singular reduced proxy factor; a full-matrix
$10^3\overline{k}e_1e_1^*$ contamination; and $k$-dependent $|\gamma|$
physical weighting passed to the CR checker.  The existing actual wall-normal,
reference-plane, $T_{RL}/T_{LR}$, $E^{-1}$, and row-order mutations must also
remain detectable above $10^{-8}$.  The anti-holomorphic CR defect must exceed
$\max(10^{-3},100\,d_{\rm good})$.

## Verdict vocabulary

- `PASS`: every necessary gate passes on at least one predeclared disk.
- `PASS_WITH_CONDITIONS`: every empirical readiness gate passes, while the
  preregistered non-blocking theory caveats remain explicit.
- `FAIL`: a named representation, branch, subspace, chart, factor, CR, parity,
  anti-collapse, or negative-control gate fails on all allowed attempts.

Production separation, a theorem excluding unsampled poles, analytic
$A_{\mathrm{def}}'$, continuous spectral approximation, and trace-order
convergence are not evaluated here and cannot be upgraded by this experiment.
