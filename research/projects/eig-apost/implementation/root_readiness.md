<!-- Root-readiness candidate-domain experiment design -->

# Root-readiness gate design

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: plan
- Origin Date: 2026-08-07
- Verification Status: PRE-IMPLEMENTATION REVIEWED — controlled diagnostic only
- Version Label: eig-apost-root-readiness-v1.1
- Git Base: d699ae9ffa2d9f9a23c0d1cdd58fffc00357162b

This document freezes the experiment immediately after
[[research/projects/eig-apost/implementation/aug-bie-review|the Stage 2 augmented BIE
review]]. Its governing mathematical sources are
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]],
[[research/projects/eig-apost/phase3-analysis/s-estimator|the candidate estimator]], and
[[research/projects/eig-apost/phase4-report/method.tex|the Phase 4 method]]. The target
case and reference policy come from
[[research/projects/eig-apost/phase3-analysis/p-benchmark|the benchmark plan]].

The current state is `CONTROLLED_DIAGNOSTIC_PENDING`. No root-readiness decision is
available until one exact proxy-system constructor has been compared through the paths
below. The physical label remains `PHYSICAL_ROOT_READY=STOP`. The originally planned
`ROOT_READINESS_SAMPLED_DISCRETE_GO` is a dormant re-entry criterion, not an outcome of
this version.

> **Post-experiment status (does not modify this frozen pre-registered design).** The
> controlled diagnostic is complete; see
> [[research/projects/eig-apost/implementation/root_result|the post-experiment result]]
> and
> [[research/projects/eig-apost/implementation/root_readiness_review|the Root-readiness
> review]]. The operational state is
> `ROOT_READINESS=BLOCKED_UPSTREAM_PROVENANCE` and `PHYSICAL_ROOT_READY=STOP` because
> the production helper's internal $A_{\mathrm{pr}},b_{\mathrm{pr}}$ identity remains
> `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. The next root-search stage is not authorized.
> The preceding `CONTROLLED_DIAGNOSTIC_PENDING` paragraph is retained as the historical
> pre-run state under which the gates below were frozen.

## Context and claim boundary

The experiment asks whether the current Stage 2 matrix assembly can be turned into one
fixed-representation complex-$k$ evaluator suitable for a later numerical root-isolation
experiment. It does not count roots or solve for one.

The dependency chain is

```text
target double-ellipse parameters
  -> real-axis locator only
  -> one frozen proxy compression and one anchored branch chart
  -> fixed-representation F_aug(k) at adjacent tail levels
  -> sampled branch/proxy/factor/CR ledgers on one complex disk
  -> discrete implementation readiness only
```

The following distinctions are mandatory.

- ESTABLISHED: Stage 2 fixed-dimensional block order and the corrected density
  coordinate have passed their finite-dimensional tests.
- CONDITIONAL: after freezing the compression and branches, the test-local matrix
  evaluator is analytic wherever all named square factors are nonsingular and the
  underlying Hankel functions stay on the frozen local chart.
- PROVISIONAL: a real singular-value dip is only a locator for a candidate disk.
- BLOCKED: continuous center-BIE kernel--field equivalence, continuous representation
  injectivity, absence of physical spurious roots, and any interpretation as a guided
  eigenvalue.

Finite samples of reciprocal condition estimates cannot prove that a closed disk is
pole-free. A numerical rank test, raw/reduced Schur agreement, Cauchy--Riemann test, or
stable singular-value dip cannot replace the continuous kernel--field theorem. The
experiment therefore never emits `ROOT_READY=GO`, `EIGENVALUE_FOUND`, `POLE_FREE_PROVED`,
or an estimator/effectivity value.

## Frozen actual case

The positive case is the provisional target family from the benchmark plan, not the
circle-lead Stage 2 smoke.

| Quantity | Frozen value |
|---|---|
| quasiperiodic parameter | $\beta=0.8$ |
| exterior scan interval | $k\in[0.04,0.18]$ |
| material index | $n_{\mathrm{ref}}=3$ |
| interior wavenumber | $k_{\mathrm{int}}(k)=n_{\mathrm{ref}}k$ |
| bulk ellipse semiaxes | $(0.40,0.30)$ |
| defect ellipse semiaxes | $(0.28,0.21)$ |
| ellipse placement and rotation | cell-centered, unrotated |
| cell walls | $X_L=-1$, $X_R=1$ |
| longitudinal cell length | $L=2$ |
| transverse period | $d=2\pi$ |
| Rayleigh truncation | $M=7$, hence $p=15$ |
| boundary nodes | 60 on each ellipse |
| scan tail level | $j_{\mathrm{scan}}=3$ |
| root-candidate levels | $j=3,4$ |
| analytic-consistency endpoint levels | $j=0,4$ |

The proxy parameters remain those of Stage 2: physical periodic axis `y`, $H=1.8$,
proxy distance $0.7$, 40 side points, 40 top points, 24 proxy sources per edge, and
plane-wave order 8. Both ellipses use the Stage 2 corrected density coordinate

$$
  \xi=D_h\eta,\qquad B=D_hB^{\mathrm{phys}},\qquad
  \mathcal E=\mathcal E^{\mathrm{phys}}D_h^{-1}.
$$

The bulk one-cell scattering matrix and defect center blocks are assembled locally from
these scaled objects. Production `bloch.construct_S` is not an oracle for either ellipse.
A circle-lead fallback may be retained as `CIRCLE_LEAD_INTERFACE_SMOKE`, but it cannot
earn the positive readiness label.

## Fixed proxy compression

Let the overdetermined proxy system at spectral parameter $k$ be

$$
  A_{\mathrm{pr}}(k)c(k)=b_{\mathrm{pr}}(k),
  \qquad A_{\mathrm{pr}}(k)\in\mathbb C^{m\times n_{\mathrm{pr}}},
  \quad m>n_{\mathrm{pr}}.
$$

The production pointwise `lsqminnorm`/`pinv` path is not a holomorphic evaluator because
its least-squares map depends on conjugate transposes. At the real coarse locator
$k_{\mathrm{seed}}$, compute one thin SVD

$$
  A_{\mathrm{pr}}(k_{\mathrm{seed}})=U_0\Sigma_0V_0^*.
$$

If the exact constructor shows that the one-sided full chart is rank-deficient or fails
its conditioning gate, the reviewed fallback candidate freezes the reduced rank

$$
  r=\max\left\{q:\frac{\sigma_q}{\sigma_1}\ge10^{-8}\right\},
  \qquad U_r=U_0(:,1{:}r),\quad V_r=V_0(:,1{:}r).
$$

The actual $k_{\mathrm{seed}}$ is selected by the scan, so the accepted representation
label is `TRUNCATED_PROXY_CHART_R<r_seed>`, with the integer substituted from the exact
constructor and frozen selection rule. No numerical rank is asserted before that
diagnostic. The seed gap must satisfy
$\sigma_r/\sigma_{r+1}\ge2$; otherwise projector reproducibility must pass before the
chart is usable. Write $c_r=V_ra_r$ and solve

$$
  \bigl(U_r^*A_{\mathrm{pr}}(k)V_r\bigr)a_r(k)
  =U_r^*b_{\mathrm{pr}}(k).
$$

This is a frozen two-sided Petrov--Galerkin discretization, not the production
least-squares solution. For fixed $U_r,V_r,r$, its solution is meromorphic in $k$ wherever
$U_r^*A_{\mathrm{pr}}(k)V_r$ is nonsingular. Conjugation occurs only in the seed constants.
Recomputing either subspace, reselecting $r$, or changing the reduced coordinates away
from the seed is forbidden. The entries and hashes of $U_r,V_r$, the phase-invariant
projectors $U_rU_r^*,V_rV_r^*$, $r$, and the seed singular values belong to the
representation fingerprint. An unchanged-source repeat must reproduce the two projectors
relatively to $10^{-10}$.

For residual $r_{\mathrm{pr}}=A_{\mathrm{pr}}c_r-b_{\mathrm{pr}}$, record at every node

$$
\begin{aligned}
  r_P&=\frac{\lVert U_r^*r_{\mathrm{pr}}\rVert_2}
    {\max(1,\lVert b_{\mathrm{pr}}\rVert_2)},\\
  r_{P,\mathrm{back}}&=
    \frac{\lVert U_r^*r_{\mathrm{pr}}\rVert_2}
    {\max(1,\lVert U_r^*A_{\mathrm{pr}}V_r\rVert_2\lVert a_r\rVert_2+
      \lVert U_r^*b_{\mathrm{pr}}\rVert_2)},\\
  r_{\perp}&=\frac{\lVert(I-U_rU_r^*)r_{\mathrm{pr}}\rVert_2}
    {\max(1,\lVert b_{\mathrm{pr}}\rVert_2)},\\
  r_{\mathrm{full}}&=\frac{\lVert r_{\mathrm{pr}}\rVert_2}
    {\max(1,\lVert b_{\mathrm{pr}}\rVert_2)},\\
  r_{\mathrm{fullsys}}&=\frac{\lVert r_{\mathrm{pr}}\rVert_2}
    {\max(1,\lVert A_{\mathrm{pr}}\rVert_2\lVert c_r\rVert_2+
      \lVert b_{\mathrm{pr}}\rVert_2)}.
\end{aligned}
$$

Three paths must be built from one exact returned $A_{\mathrm{pr}}(k),b_{\mathrm{pr}}(k)$
and compared with the same formulas:

1. `PRODUCTION_POINTWISE_SOLVE`: call the exact solver branch used by
   `kernel.precomp_proxy` on the returned system;
2. `EXPLICIT_FULL_SVD_REFERENCE`: form the minimum-norm SVD solution from that same
   system, recording the singular values and the exact rank tolerance;
3. `TRUNCATED_PROXY_CHART_R<r_seed>`: only if the first diagnostic supports the reviewed
   fixed two-sided reduced chart, construct it from the same seed SVD and never reselect
   it.

For every path record $r_P$, $r_{P,\mathrm{back}}$, $r_{\perp}$,
$r_{\mathrm{full}}$, `full_system_backward_diagnostic`, coefficient norm, and the exact
solver/rank label. The full-system quantity is descriptive and is not a linear-solve
residual. Only the projected residual and projected backward residual use the provisional
$10^{-11}$ solve gate; the reduced factor uses the provisional rcond gate $10^{-8}$.
No cap on the full-system diagnostic is frozen from pilot data.

The discarded interactive reconstruction produced mutually inconsistent residual and
object-mismatch values, including the previously quoted $0.283$, $7.18\times10^{-4}$,
and rank-126 comparisons. They are labeled `DISCARDED_PILOT_RECONSTRUCTION`, are not
evidence about the exact constructor, and set no gate or decision. In particular, no
current numerical rank, reduced rank, coefficient norm, residual, rcond, or object
mismatch is asserted in this design.

The controlled diagnostic first requires the production helper and the reconstructed
production path to agree in coefficients, Green values, and derivatives to $10^{-11}$.
It then compares the explicit full-SVD and any proposed reduced chart in Green values and
derivatives, defect/bulk $A_{\mathrm{QP}}$, and corrected scattering blocks. The hard
compatibility gate is $10^{-5}$ for each object. These comparisons do not make any path
QP Green truth. Independently evaluate quasiperiodic and top/bottom conditions at
half-grid-shifted points not used in $A_{\mathrm{pr}}$ and report their normalized
residuals without selecting a post-hoc threshold.

A seed-frozen row subset is an independent cross-check only; it must not be mixed with
the primary reduced chart or used to repair a failed gate.

## Current-code controlled diagnostic

The only implementation authorized by this version is a minimal diagnostic in
`test/root-ready/`. At $k=0.095,0.100,0.105$, it reconstructs the same
$A_{\mathrm{pr}}(k),b_{\mathrm{pr}}(k)$ and evaluates the three named paths with the
unified residual, coefficient norm, projected residual, compressed-factor rcond, and
full-system backward diagnostic. It must prove that the returned system is byte- or
entrywise identical to the system consumed by the production helper. A reduced chart is
formed only after the exact seed singular values select its rank; those subspaces are
then frozen at $k=0.100$ and are not reselected at neighboring points.

Using the same real-axis branches and density scaling, it also records pairwise
differences in Green values and derivatives, defect/bulk $A_{\mathrm{QP}}$, and corrected
defect/bulk scattering matrices. The production-to-candidate relative mismatch gate is
$10^{-5}$ for each object. This is a compatibility gate, not a claim that production is
truth.

The diagnostic emits `CONTROLLED_DIAGNOSTIC_COMPLETE` with either
`EXACT_CONSTRUCTOR_MATCH` or `EXACT_CONSTRUCTOR_MISMATCH`, followed by the exact
path metrics. It does not emit `ROOT_READINESS_STOP` or a GO label without a new review
of those exact results. Candidate scan, disk sampling, full-$F$ CR tests, root count,
Newton solve, and estimator quantities remain `NOT_AUTHORIZED_PENDING_DIAGNOSTIC`.

The Skeptic pre-implementation verdict is PASS WITH CONDITIONS for this diagnostic only.
The exact constructor must reproduce production coefficients and Green data to
$10^{-11}$; all paths must consume identical $A_{\mathrm{pr}},b_{\mathrm{pr}}$ and use
the same residual formulas; the $10^{-5}$ object gate may reject a candidate but may
never be relaxed. A second identical-source run and post-experiment Skeptic review are
mandatory. This verdict leaves `ROOT_READINESS_BLOCKED_PENDING_DIAGNOSTIC` and
`PHYSICAL_ROOT_READY=STOP` unchanged.

## Dormant re-entry protocol: anchored analytic chart

The port orders $m=-M{:}M$ and proxy plane-wave orders $m=-8{:}8$ each use

$$
  \beta_m=\beta+\frac{2\pi m}{d},\qquad
  \gamma_m(k)^2=k^2-\beta_m^2.
$$

At $k_{\mathrm{seed}}$, select the physical outgoing/decaying values
$\gamma_{m,0}$. Continue those values on the candidate disk with one fixed logarithm
branch as prescribed in the Phase 4 method. The same continued values must be injected
into all of the following:

1. port Rayleigh phases and incident traces;
2. the plane-wave blocks of $A_{\mathrm{pr}}(k)$;
3. the outer plane-wave evaluation in the quasi-periodic Green matrix;
4. all center and lead BIE blocks that consume these objects.

Calling `bloch.rayleigh_channels`, recomputing a principal square root inside
`kernel.precomp_proxy`, or recomputing it in the outer path of
`kernel.qpgreen_mfs_pairmat` does not satisfy this gate. At every sampled node, require
the branch algebra and anchor-continuation errors to be at most $10^{-12}$, and require
the branch identifier and ordering fingerprint to match the seed.

The remainder of this document is a pre-registered re-entry protocol only. It is not
executed by the current early-stop diagnostic.

## Dormant re-entry: candidate locator and compression freeze

The global real locator uses 29 equally spaced points on $[0.04,0.18]$. It may use the
production pointwise least-squares proxy because this pass only locates candidates. A
Wood, proxy, BIE, doubling, terminal, dimension, or nonfinite failure at any scan point
stops the scan; points are never silently omitted.

At level $j_{\mathrm{scan}}=3$, define

$$
  s(k)=\frac{\sigma_{\min}(F_{3,h}^{\mathrm{aug}}(k))}
  {\max(1,\lVert F_{3,h}^{\mathrm{aug}}(k)\rVert_2)}.
$$

A locator candidate must be a strict interior grid minimum, satisfy $s(k)\le10^{-3}$,
and have both neighboring values at least $1.5s(k)$. Rank candidates by smaller $s(k)$,
breaking numerical ties by smaller $k$. If none exists, the result is
`NO_SCREENED_DIP` and the stage stops without changing geometry or thresholds.

Freeze $U_r,V_r,r$ once at the selected coarse candidate. Two successive nine-point
refinements use that same reduced chart and the same representation. Each refinement must
retain a strict interior minimum. The coarse and final locations must agree within two
final-grid steps.
The scaled center block of the unit smallest right singular direction must have norm at
least $10^{-3}$, and its normalized overlap between the two refinements must be at least
$0.9$. These tests only stabilize the locator; they do not establish a root or
multiplicity.

Report the production-LS versus reduced-chart matrix mismatch at the anchor and
refinements. It is diagnostic evidence about the approximation change, not a reason to
recompute the chart.

## Dormant re-entry: reduced-chart sensitivity gate

Analytic consistency alone does not establish adequate proxy accuracy. Before a
root-readiness label is available, repeat the real refinements and sampled disk
diagnostics with the seed-frozen ranks
$r=r_{\mathrm{seed}}-2,r_{\mathrm{seed}}-1,r_{\mathrm{seed}}$. None of these charts
may reselect its rank away from the common seed. Also run one predeclared
proxy-resolution refinement:
48 side points, 48 top points, 28 proxy sources per edge, and plane-wave order 10. The
refined proxy chooses its own seed rank by the same $10^{-8}$ relative-singular-value
rule and then freezes it.

Let $\mathfrak C$ contain the three base-rank charts and the refined-proxy chart. Their
lifted augmented matrices have the same $(n+8p)$ dimensions and ordering. For any two
charts $a,b\in\mathfrak C$, node $k$, and level $j$, define the pairwise spectral-norm
spread

$$
  e_{ab}(k,j)=
  \frac{\lVert F_{j,h}^{(a)}(k)-F_{j,h}^{(b)}(k)\rVert_2}
  {\max(1,\lVert F_{j,h}^{(a)}(k)\rVert_2,
          \lVert F_{j,h}^{(b)}(k)\rVert_2)}.
$$

The chart spread is the maximum of $e_{ab}$ over every unordered pair, levels
$j=0,3,4$, and the stated node set. The locator spread uses the final real locator
nodes. The boundary spread uses all 32 boundary nodes of the accepted disk; center and
half-radius spreads are recorded separately. No average may replace this maximum.

Across the three base ranks and the refined proxy, require:

1. final locator positions differ by at most two base final-grid steps;
2. center-direction overlaps are at least $0.9$;
3. each chart passes its own full, backward, coefficient-norm, and off-collocation gates;
4. 16- and 32-node disk availability gives the same pass/fail classification;
5. the boundary-separation minima differ by at most $50\%$;
6. on the accepted boundary, the largest relative full-$F$ chart spread is at most one
   tenth of the smallest relative boundary separation;
7. at the final locator, the largest relative full-$F$ chart spread is at most one tenth
   of the smallest positive locator value $s(k)$ across the four charts.

The final condition prevents chart uncertainty from being comparable to the separation
that a later contour calculation would rely on. Before these sensitivity checks pass,
the maximum label is `ANALYTIC_EVALUATOR_REDUCED_SMOKE`. If locator identity, disk
availability, or boundary separation changes materially, the stage stops for root search.
The next root/correction experiment must likewise stop if chart uncertainty is comparable
to an adjacent-level root shift.

## Dormant re-entry: candidate disk and sampled availability

Center the disk at the final refined locator $k_c$. Let $\Delta k_f$ be the final real
grid step, and let $d_{\mathrm{br}}$ be the distance from $k_c$ to $0$ and to every
relevant port/proxy branch point $\pm\beta_m$. The initial radius is

$$
  r_0=\min(2\Delta k_f,\tfrac14 d_{\mathrm{br}}).
$$

Evaluate the attempts $r_0,r_0/2,r_0/4$ in this order. Each attempt uses nested 16- and
32-point boundary samples, the center, and eight points on the half-radius circle. Keep
all attempts and all failures in the ledger. A later attempt may pass, but the report
must state why each larger disk failed. No fourth shrink, shifted center, changed proxy,
changed discretization, or threshold adjustment is allowed after results are seen.

At levels $j=0,3,4$, every sampled node records the full Stage 2 representation fingerprint
and the factors below:

- non-Wood and anchored-branch margins;
- seed-frozen proxy factor $U_r^*A_{\mathrm{pr}}(k)V_r$;
- center and bulk-ellipse BIE matrices and solve residuals;
- every doubling factor through level 4;
- left and right terminal factors and far blocks;
- $K_{ee}$ and the representation stack;
- boundary separation $s(k)$ of the full augmented matrix.

Dormant thresholds are as follows. Proxy full-system and off-collocation accuracy caps
remain pending the exact-constructor diagnostic and a new review.

| Gate | Threshold |
|---|---|
| distance from $0$ and all branch points | disk radius at most one quarter of the minimum distance |
| seed selected-rank relative singular value | at least $10^{-8}$ |
| seed singular-subspace gap | at least 2, or projector reproducibility at most $10^{-10}$ |
| reduced proxy factor rcond | at least $10^{-8}$ |
| proxy projected residual and projected backward residual | each at most $10^{-11}$ |
| proxy full residual | report only pending exact-constructor review |
| full-system backward diagnostic | report only; not a solve residual |
| independent off-collocation residual | report only pending independent proxy review |
| real-axis Green and full-$F$ mismatch | at most $10^{-5}$ |
| center and lead BIE rcond | at least $10^{-6}$ |
| BIE solve residual | at most $10^{-9}$ |
| doubling, terminal, far-block, and $K_{ee}$ rcond | at least $10^{-8}$ |
| other square-factor solve residual | at most $10^{-9}$ |
| full augmented boundary separation | at least $10^{-8}$ |
| 16-to-32-node sampled minimum change | at most $50\%$ relative, with no new failure |

The reduced proxy factor, bulk lead BIE solve, and internal doubling solves are part of
the raw evaluator construction; their singularities are evaluator poles. In contrast,
singular center $A_c$, terminal factors, far blocks, and $K_{ee}$ are representation or
elimination failures and possible zeros of an auxiliary system, not poles of the raw
$F_{j,h}^{\mathrm{aug}}$ function, because the raw assembly does not invert them. Their
failure blocks physical interpretation or the reduced cross-check but must not be
misreported as a raw-matrix pole.

Passing the samples establishes only `SAMPLED_DOMAIN_AVAILABLE`. It is not a proof that
an unsampled interior evaluator pole is absent or that the raw matrix has no interior
zeros. A later contour experiment must carry this limitation explicitly.

## Dormant re-entry: full-matrix Cauchy--Riemann gate

For the test-local evaluator and endpoint levels $j=0,4$, define at an interior test point
$k$ and real step $h$

$$
\begin{aligned}
  D_x(h)&=\frac{F(k+h)-F(k-h)}{2h},\\
  D_y(h)&=\frac{F(k+\mathrm{i}h)-F(k-\mathrm{i}h)}{2\mathrm{i}h},\\
  e_{\mathrm{CR}}(h)&=
  \frac{\lVert D_x(h)-D_y(h)\rVert_F}
  {\max(1,\lVert D_x(h)\rVert_F,\lVert D_y(h)\rVert_F)}.
\end{aligned}
$$

Use the disk center and the eight half-radius nodes. Set

$$
  h_0=\min(r/32,10^{-4}\max(1,|k_c|))
$$

For $D\in\{D_x,D_y\}$ also define the final-step spread

$$
  e_D=
  \frac{\lVert D(h_0/4)-D(h_0/2)\rVert_F}
  {\max(1,\lVert D(h_0/4)\rVert_F,\lVert D(h_0/2)\rVert_F)}.
$$

Test $h_0,h_0/2,h_0/4$ at $k_c$ and the eight half-radius off-axis nodes. The scan seed
may be added only when its complete stencil stays inside the same accepted disk and uses
the same frozen chart. At every tested point and endpoint level, require

$$
  e_{\mathrm{CR}}(h_0/4)\le10^{-6},\qquad
  e_{D_x}\le10^{-6},\qquad e_{D_y}\le10^{-6}.
$$

The CR sequence must be non-increasing from $h_0/2$ to $h_0/4$, unless both values are at
a documented rounding floor supported by all involved matrix differences being within
100 machine epsilons of their scale. Failure is `FULL_F_CR_DEFECT` and cannot be
repaired by differentiating only the Rayleigh phase or only the reduced matrix.

This is a numerical consistency test for the implemented finite-dimensional evaluator.
It does not prove analyticity of a continuous operator family.

## Dormant re-entry: mandatory falsification cases

All negatives run through the same branch, proxy, evaluator, ledger, and availability
checks used by the positive case.

| Case | Mutation | Required outcome |
|---|---|---|
| pointwise outgoing square root | use a manufactured propagating seed $|k|>|\beta_m|$ and cross the real axis while recomputing and sign-correcting principal roots | CR/branch defect greater than $\max(10^{-3},100e_{\mathrm{CR}}^{\mathrm{good}})$ |
| adaptive least squares | use an inconsistent tall manufactured system and recompute `pinv`/SVD at every complex stencil node | the same quantitative CR rejection |
| adaptive compression | recompute $U_r,V_r$, or $r$ away from the seed | deterministic `REPRESENTATION_DRIFT` from the fingerprint; no CR-size requirement |
| outer-path principal root | use a separate propagating manufactured seed $|k|>|\beta_m|$ and explicit Green targets satisfying $|Y|>H$, keep proxy branches anchored, and recompute only the outer plane-wave roots | branch/CR rejection in that fixture; do not call it a full-$F$ mutation because actual ellipse pair targets may not activate this path |
| one-node branch flip | change one continued $\gamma_m$ sign | branch fingerprint rejection |
| explicit antiholomorphic full matrix | use $F_{\mathrm{bad}}(k)=F(k)+10^3\overline{k}e_1e_1^*$ in the frozen $240\times240$ augmented layout through the same full-$F$ CR checker | defect greater than $\max(10^{-3},100e_{\mathrm{CR}}^{\mathrm{good}})$ |
| singular proxy compression | force $U_r^*A_{\mathrm{pr}}V_r$ singular at a sampled node | `PROXY_COMPRESSION_POLE`; downstream unavailable |
| hidden meromorphic pole | manufactured scalar factor with a pole inside but not on the coarse boundary samples | sampled checks must not be reported as a pole-free proof |
| zero-field density | reuse the Stage 2 representation-nullspace negative | `PHYSICAL_ROOT_READY=STOP` |
| near-threshold factor | sweep one doubling or terminal factor across its frozen rcond gate | deterministic availability transition; no singular solve |
| circle-lead fallback | replace the bulk ellipse by the Stage 2 circle | smoke label only; target-domain GO forbidden |

The fixed-row-subset compression is an alternative diagnostic. Agreement or disagreement
with it is reported; it is neither a truth oracle nor a fallback that can convert a failed
primary compression into a pass.

## Data and symbol contract

The Engineer must add the following mappings to
[[research/projects/eig-apost/implementation/SYMBOL|the symbol ledger]] before code is
accepted. Existing Stage 2 meanings remain unchanged.

| Mathematical object | Required code variable | Meaning |
|---|---|---|
| $A_{\mathrm{pr}}(k),b_{\mathrm{pr}}(k)$ | `proxy_A`, `proxy_b` | full overdetermined proxy system |
| $U_0,\Sigma_0,V_0$ | `proxy_U_seed`, `proxy_s_seed`, `proxy_V_seed` | thin seed SVD used only to select the fixed reduced chart |
| $r,U_r,V_r$ | `proxy_rank`, `proxy_U`, `proxy_V` | frozen two-sided Petrov--Galerkin coordinates |
| $a_r(k),c_r(k)=V_ra_r(k)$ | `proxy_reduced_coefficients`, `proxy_coefficients` | reduced and lifted proxy coefficients |
| $\mathcal D(k_c,r)$ | `candidate_disk` | sampled candidate domain, not a proof object |
| $D_x,D_y,e_{\mathrm{CR}}$ | `derivative_real`, `derivative_imag`, `cr_defect` | full-$F$ analytic-consistency diagnostics |
| $s(k)$ | `relative_sigma_min` | locator or boundary separation only |
| $\max e_{ab}$ | `relative_full_F_chart_spread` | maximum pairwise spectral-norm chart spread on the declared node/level scope |
| $10^3,e_1e_1^*$ | `mutation_alpha`, `mutation_matrix` | frozen antiholomorphic full-$F$ negative |

The representation descriptor contains geometry/material data, $D_h$ fingerprints,
port and proxy orders, branch seeds and identifiers, $r$, the complete entries and hashes
of $U_r,V_r$, both phase-invariant projectors, row/column order, phase origins, levels,
terminal closure, and source manifest. It must be identical across all accepted
evaluations of one chart.

The current implementation belongs only in `test/root-ready/`. Its evidence bundle
contains at least `config.txt`, `proxy-paths.csv`, `object-consistency.csv`,
`results.mat`, `run.log`, `report.md`, and `reproducibility.txt`. The config records
the exact constructor identity, solver/rank rules, the discarded interactive
reconstruction provenance, and source hashes. Dormant scan/domain/CR output names are
recorded as `NOT_AUTHORIZED_PENDING_DIAGNOSTIC`, not generated as fabricated empty
evidence. The
hard runtime limit is 3600 seconds; timeout yields an incomplete report and never a
positive label.

## Decision rule and next gate

For the current code, return `CONTROLLED_DIAGNOSTIC_COMPLETE` and the exact constructor,
solver, rank, residual, coefficient, and object-consistency records. Until those records
receive a new Researcher/Skeptic review, the decision remains
`ROOT_READINESS_BLOCKED_PENDING_DIAGNOSTIC`; it is neither GO nor evidence-based STOP.
The diagnostic may not change a chart, normalization, rank, or threshold after seeing
outputs. `REVISE` is reserved for an incomplete or incorrect diagnostic implementation.

The dormant `ROOT_READINESS_SAMPLED_DISCRETE_GO` decision rule becomes active only after
a separately reviewed proxy repair reproduces independent off-collocation accuracy,
repasses Stage 2 algebra integration, and then passes every locator, sensitivity, disk,
factor, representation, boundary-separation, CR, mutation, and reproducibility gate
above. Only then would a separate frozen-disk contour/root experiment be authorized.

Even after a discrete root is qualified, a real-case conditional estimator still
requires adjacent-level correction validation and an independently resolved
$k_{\infty,h}^{\mathrm{ref}}$; a reliable interval additionally requires the independent
saturation and remainder bounds specified in the Phase 3 estimator analysis.

## Review questions

1. Does the frozen Petrov--Galerkin compression, including its full and orthogonal
   collocation residuals, preserve a defensible discrete analytic family without being
   mislabeled as least squares?
2. Do the branch injections cover every current pointwise square-root path used by the
   full BIE evaluator?
3. Can any positive label be misread as continuous pole-freeness, kernel--field
   equivalence, or a guided eigenvalue?
4. Are the locator, domain, CR, factor, and mutation gates capable of failing before root
   isolation, without post-result parameter tuning?
5. If this design passes, is the smallest defensible next action the separate frozen-disk
   discrete root-isolation experiment described above?

## Pre-execution provenance-closure addendum

### Addendum Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: pre-registered corrective experiment
- Origin Date: 2026-08-07
- Verification Status: RESEARCHER REVISED / PRE-RUN REVIEW CONDITIONS INCORPORATED / NOT RUN
- Version Label: eig-apost-provenance-closure-v1.1
- Governing Result:
  [[research/projects/eig-apost/implementation/root_result|Root-readiness result]]
- Governing Review:
  [[research/projects/eig-apost/implementation/root_readiness_review|Root-readiness
  review]]
- Symbol Authority:
  [[research/projects/eig-apost/implementation/SYMBOL|Symbol and code-variable ledger]]

This addendum freezes the smallest test-only experiment that may follow the completed
controlled diagnostic. It does not rewrite the pre-registered design above, reinterpret
the old failure rows as passes, or authorize the dormant complex-domain or root stages.
The package source remains read-only.

### Question and operational claim

The unmodified `kernel.precomp_proxy` interface cannot return the collocation matrix and
right-hand side that it consumes. Therefore
`production_internal_A_b_identity` remains `NOT_DIRECTLY_OBSERVED`, with stable reason
`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`, in every outcome of this experiment.

The operational question is narrower: can a test-local, source-exact copy of the frozen
package implementation return its already existing local `A` and `b` without changing
the executable arithmetic, reproduce the package's public proxy output bitwise in the
same process, and supply one shared pair to every comparison solver? A pass establishes
only source-derived shared-system provenance and emits
`SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`.

The copy-returned arrays are denoted
$A_{\mathrm{pr}}^{\mathrm{copy}}(k)$ and
$b_{\mathrm{pr}}^{\mathrm{copy}}(k)$ only in this addendum. The superscript is necessary:
it distinguishes returned test-local data from the production-internal arrays that are
not directly observable.

### Authorized files and evidence preservation

All new implementation belongs under `test/root-ready/provenance-closure/`. The
instrumented source copy is
`test/root-ready/provenance-closure/LOCAL_precomp_proxy_instrumented.m`. The unmodified
package `+kernel/precomp_proxy.m` and every other package file remain read-only.

The existing `test/root-ready/output/` directory is historical evidence and must not be
overwritten. In particular, the three failed mirrored-output values
$2.798540\times10^{-7}$, $5.531552\times10^{-10}$, and
$1.250388\times10^{-9}$ remain authoritative results for the earlier independently
reconstructed arithmetic path. The new source-exact-copy path uses separate output
directories `test/root-ready/provenance-closure/output/baseline/` and
`test/root-ready/provenance-closure/output/repeat/`. Before both runs are complete, all
new evidence is private to `test/root-ready/provenance-closure/output.inprogress/`; the
final `output/` tree must not exist. The completed two-run tree is published by one
same-filesystem atomic rename from `output.inprogress/` to `output/`. Neither an
in-progress tree nor a tree without the required completion marker is authoritative.

No candidate scan, complex disk, Cauchy--Riemann test, contour count, Newton solve,
eigenvalue, adjacent-level correction, or estimator may be added to this experiment.

### Source-exact copy and allowed transform

The frozen package file has SHA-256
`3a16825064e5762f3486373fee702e94c34fa3cfdfb3b774f78f3b27eb2f9a60`.
The frozen byte span begins at the first byte of the configuration marker on package line
21, whose first executable assignment is `d = pars1.d;`, and ends after the newline that
follows the final `proxy.C_down = ...` assignment on package line 160. It has SHA-256
`eb116bc9a359b9a50d6804891939cdfeb2b6a17eacb8a6a2a3a8e7d29bebd82c`.

The only allowed executable transform is the function declaration

```matlab
function proxy = precomp_proxy(pars1,pars2)
```

to

```matlab
function [proxy,A,b,coeffs] = ...
  LOCAL_precomp_proxy_instrumented(pars1,pars2)
```

The variables `A`, `b`, and `coeffs` already exist and are assigned on every ordinary
return path, so no executable output assignment is permitted. Test-specific help text
may be inserted before the first executable assignment. After excluding the declaration,
help text, and closing function `end`, the copied executable block must be byte-for-byte
identical to the frozen package block and have the frozen body hash above.

The verifier must open both files in binary mode, locate the frozen ASCII marker bytes,
and compare and hash the selected raw `uint8` spans. It must not normalize `CRLF`, `CR`,
or any other byte sequence, and it must not decode and re-encode the span before hashing.
Consequently, a copy that differs only by line endings fails `source_exact_copy_body`.

Before any numerical comparison, static inspection must also confirm that the executable
block contains no dependence on the function name, output count, call stack, random
state, mutable global state, or dynamic evaluation. At the frozen revision the relevant
forbidden constructs include `mfilename`, `nargout`, `dbstack`, `eval`, `evalin`,
`assignin`, `persistent`, `global`, `rand`, and `rng`. The single environment-dependent
solver branch, `exist('lsqminnorm','file')`, is recorded and must have one value shared by
the package and copy calls in the same Octave process.

### Frozen inputs and common-system rule

The real frequencies $k=0.095,0.100,0.105$, $\beta=0.8$, $d=2\pi$, source location,
base/refined proxy parameters, ratio-rank rule $10^{-8}$, Green probes, geometries,
channel order, density scaling, and all downstream objects remain unchanged.

The serialized input values are frozen as follows.

| Input group | Frozen value |
|---|---|
| Spectral nodes | `k_nodes = [0.095,0.100,0.105]`, `k_seed = 0.100` |
| Periodic problem | `beta = 0.8`, `d = 2*pi`, `nref = 3`, `periodic_axis = y` |
| Primary Green source | `primary_source = [0,0]` |
| Base proxy | `H = 1.8`, `proxy_dist = 0.7`, `N_side = 40`, `N_top = 40`, `N_proxy_edge = 24`, `M_pw = 8` |
| Refined proxy | `H = 1.8`, `proxy_dist = 0.7`, `N_side = 48`, `N_top = 48`, `N_proxy_edge = 28`, `M_pw = 10` |
| Green probe sources | `[-0.15,0.10,0.22;0.07,-0.13,0.18]` |
| Green probe targets | `[0.25,-0.20,0.05,-0.10;-0.11,0.17,0.24,-0.20]` |
| Defect geometry | centered ellipse, axes `[0.28,0.21]`, `ntot = 60` |
| Bulk geometry | centered ellipse, axes `[0.40,0.30]`, `ntot = 60` |
| Rayleigh data | `rayleigh_M = 7`, `L = 2`, `walls = [-1,1]`, `channel_order = RAYLEIGH_NATIVE_ORDER` |
| Density scaling | `h = curvelen/size(C,2)`, `speed = sqrt(C(2,:).^2+C(5,:).^2)`, `density_scale = sqrt(h*[speed,speed]).'` |
| Shifted residual rule | `off_collocation_rule = SHIFTED_DENSIFIED_MIDPOINT_2X` |

At each configuration, call the package and copy exactly once at each of the three
frequencies and cache the complete returned record. The cached record at
$k_{\mathrm{seed}}=0.100$ supplies the one thin SVD used to select and freeze the
configuration's ratio rank and projectors. No second copy call or second assembly is
allowed at the seed frequency. At each configuration and frequency:

1. call the unmodified package and the source-exact copy sequentially in one process with
   identical `pars1` and `pars2`;
2. retain the package result only as the public-output anchor;
3. obtain $A_{\mathrm{pr}}^{\mathrm{copy}}$,
   $b_{\mathrm{pr}}^{\mathrm{copy}}$, and `coeffs` from the copied call;
4. feed those exact returned arrays to the pointwise pseudoinverse, explicit SVD, and
   seed-frozen reduced paths; and
5. use the independently assembled shifted system only for off-collocation diagnostics,
   never as the collocation system of a solver-comparison row.

Every solver-comparison row stores the raw-byte fingerprints of the shared matrix and
right-hand side. A fingerprint hashes a header containing the class, dimensions, and
recorded machine endianness, followed by the raw IEEE-754 bytes of the column-major real
part and then the raw bytes of the column-major imaginary part. MAT-file serialization is
not a valid fingerprint. The exact solver-label set is
`package_public_anchor`, `copy_production`, `pinv_default`,
`explicit_svd_pinv_tol`, and `ratio_rank_rseed`. Thus there are exactly six shared-system
rows, exactly five solver rows per shared-system row, and exactly thirty solver rows in
total. Coverage is bidirectional: every shared-system row must map to exactly those five
distinct solver labels, and every solver row must map to exactly one shared-system row.
No duplicate, missing, extra, or unmatched row is permitted. All five rows in a group
must carry the same two fingerprints as their unique copy-returned constructor row.

`config.txt` is a complete human-readable serialization of the frozen inputs, not merely
a threshold summary. It records the version and run label; all three frequencies and
$k_{\mathrm{seed}}$; $\beta$, $d$, `nref`, and the periodic-axis convention; the primary
source; both proxy configurations including `H`, `proxy_dist`, `N_side`, `N_top`,
`N_proxy_edge`, and `M_pw`; the Green source and target probes; bulk and defect axes and
`ntot`; `rayleigh_M`, `L`, wall locations, channel-order identifier, and the exact density
scaling formula identifier; the five solver labels and expected row counts; every frozen
threshold; runtime limit; manifest scope; expected artifact list; both commands; solver branch;
and every recorded source path and SHA-256. Numeric arrays are serialized with at least
17 significant decimal digits, while exact semantic choices use stable text labels.

### Frozen gates

Gates are evaluated in the following order. A failed upstream gate makes every dependent
quantity unavailable; no threshold may be changed after a run.

| Gate | Frozen success condition | Failure or unavailable label |
|---|---|---|
| `package_source_lock` | package full-file SHA-256 equals the frozen value | `PACKAGE_SOURCE_DRIFT` |
| `source_exact_copy_body` | copied executable-body hash equals the frozen body hash and byte comparison succeeds | `SOURCE_COPY_BODY_MISMATCH` |
| `source_copy_context_independence` | all forbidden constructs are absent and the solver branch is shared | `SOURCE_COPY_CONTEXT_DEPENDENCE` |
| `execution_manifest_complete` | every frozen direct-call manifest path is a distinct existing regular file and every digest is a valid 64-digit lowercase SHA-256 rather than `MISSING` or `HASH_FAILED` | `EXECUTION_MANIFEST_INCOMPLETE` |
| `package_copy_public_output_bitwise` | `q`, `Z`, `H`, `C_up`, and `C_down` are bitwise equal in the same process | `PACKAGE_COPY_PUBLIC_OUTPUT_MISMATCH` |
| `copy_coefficients_bitwise` | returned `coeffs` is bitwise equal to the flattened copied proxy output | `COPY_COEFFICIENT_EXTRACTION_MISMATCH` |
| `shared_A_b_raw_fingerprints` | bidirectional exact row coverage holds and every one of the five solver rows carries its unique constructor row's fingerprints | `SHARED_A_B_FINGERPRINT_MISMATCH` |
| `mirrored_constructor_coefficient_output_reproduction` | package/copy coefficient-output difference is at most $10^{-11}$ | `MIRRORED_CONSTRUCTOR_COEFFICIENT_OUTPUT_REPRODUCTION_FAILURE` |
| `mirrored_constructor_proxy_field_output_reproduction` | package/copy proxy-field-output difference is at most $10^{-11}$ | `MIRRORED_CONSTRUCTOR_PROXY_FIELD_OUTPUT_REPRODUCTION_FAILURE` |
| `mirrored_constructor_residual_output_reproduction` | package/copy residual-output difference is at most $10^{-11}$ | `MIRRORED_CONSTRUCTOR_RESIDUAL_OUTPUT_REPRODUCTION_FAILURE` |
| `object_compatibility_resolution` | every resolution row and its maximum are at most $10^{-5}$ | `OBJECT_COMPATIBILITY_RESOLUTION_FAILURE` |
| `object_compatibility_downstream` | every Green, $A_{\mathrm{QP}}$, and scattering row and its maximum are at most $10^{-5}$ | `OBJECT_COMPATIBILITY_DOWNSTREAM_FAILURE` |
| `object_compatibility_all` | resolution and downstream object gates both pass | `OBJECT_COMPATIBILITY_FAILURE` |
| `synthetic_source_mutation_rejected` | a deterministic in-memory arithmetic-token mutation is rejected before numerical evaluation | `SOURCE_MUTATION_NOT_REJECTED` |
| `two_run_reproducibility` | numeric difference is at most $10^{-13}$ and execution manifests, source/body hashes, raw-array fingerprints, and projector fingerprints agree | `PROVENANCE_REPRODUCIBILITY_FAILURE` |
| `artifact_bundle_complete` | every non-marker artifact passes the frozen checks, the completion marker is written last with matching hashes, and the final tree is published only by the atomic rename | `ARTIFACT_BUNDLE_INCOMPLETE` |

The three $10^{-11}$ and all $10^{-5}$ thresholds are unchanged from the controlled
diagnostic. Off-collocation readiness still has no pass threshold and remains a
diagnostic-only value. The ratio rank is selected by the unchanged $10^{-8}$ rule rather
than forced to a post-result value. Its projectors and their fingerprints must reproduce
between the two new runs; equality to projectors from the older mirrored constructor is
reported, not required to repair or reject provenance. The historical comparison loads
the read-only `test/root-ready/output/results.mat`, records its SHA-256, and matches rows
by configuration. It reports availability, ranks, dimensions, left/right relative
Frobenius differences, and bitwise equality after recomputing both historical projector
fingerprints with the new raw-byte rule. `EQUAL`, `DIFFERENT`, and `UNAVAILABLE` are
reporting states, not gates, and none enters the aggregate pass.

### Mandatory synthetic negative

The source verifier receives an in-memory synthetic copy in which exactly one occurrence
of the first Green prefactor `1i/4` is changed to `1i/5`. The test first requires that the
target occurrence count is exactly one in the selected mutation location. It must then
emit `SOURCE_COPY_BODY_MISMATCH` without writing or executing the mutated function.
Rejecting this negative is mandatory evidence that the source-exact-copy gate can fail.

### Two-run artifacts and transactional publication

The required per-run artifact set is `config.txt`, `source-copy.csv`,
`shared-system.csv`, `solver-comparison.csv`, `off-collocation.csv`,
`projector-fingerprint.csv`, `historical-projector.csv`, `resolution.csv`,
`downstream-mismatch.csv`, `gate.csv`, `results.mat`, `run.log`, `report.md`, and
`completion.marker`. The aggregate `output/reproducibility.txt` compares the two
preserved runs. The execution manifest covers the test driver, wrapper, instrumented
copy, frozen package source, design, and directly called project helpers. It is labeled
`DIRECT_PROJECT_CALLS_ONLY` and does not claim transitive completeness.

Publication follows this fixed transaction:

1. The baseline command refuses to run if either final `output/` or
   `output.inprogress/` already exists. It creates `output.inprogress/baseline/`, runs
   once, closes `run.log`, writes every non-marker artifact, and validates the complete
   baseline bundle. Only then may it prepare `artifact_bundle_complete = true` and write
   the baseline `completion.marker` last; the pass is authoritative only together with
   that valid marker. The in-progress tree is preserved for the repeat and is not yet
   public evidence.
2. The repeat command requires a valid baseline marker, refuses any final `output/`, and
   writes `output.inprogress/repeat/` without altering the baseline. It compares against
   that baseline, closes its log, writes the aggregate reproducibility file and every
   non-marker repeat artifact, and validates the full two-run tree.
3. Before the marker is written, the final bundle check verifies every required
   non-marker path, nonzero file size, expected CSV header and the row count prescribed
   by gate availability, loadable `results.mat` with the correct run label, closed log,
   manifest completeness, matching source/body/shared/projector records, and the final
   gate and operational state. A timeout or any failed check leaves
   `artifact_bundle_complete = false`, writes no completion marker, performs no rename,
   and cannot emit a positive label.
4. After that check passes, the repeat `completion.marker` is written last. It records
   the version, run label, `artifact_bundle_complete = 1`, final operational label, and
   SHA-256 of every non-marker artifact. A same-filesystem atomic rename then publishes
   the entire `output.inprogress/` tree as `output/`. No code path may write directly to
   the final tree or overwrite a completed or in-progress run.

The positive string `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS` may be computed only as a
candidate in memory before finalization. It is authoritative only after the complete
repeat marker has been checked and the atomic rename has succeeded. Any label-bearing
file visible only below `output.inprogress/`, or any final tree without a valid marker,
has status `ARTIFACT_BUNDLE_INCOMPLETE` and cannot support the claim.

The hard runtime limit remains 3600 seconds. Timeout, missing artifacts, a changed source
hash, or a nonreproduced second run can never produce a positive provenance label.

### Decision and exact claim boundary

The aggregate operational pass requires every required gate above to pass, including
`execution_manifest_complete`, the synthetic negative, the second run, and both runs'
`artifact_bundle_complete` gates. Its only positive label is
`SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`. This label permits the following claims:

1. for the frozen package source and recorded process environment, the copied executable
   arithmetic is source-exact;
2. the unmodified package public proxy output and copied public output are bitwise equal
   at the frozen inputs;
3. every test-local comparison solver consumes one returned pair
   $A_{\mathrm{pr}}^{\mathrm{copy}},b_{\mathrm{pr}}^{\mathrm{copy}}$ with reproduced
   raw-byte fingerprints; and
4. the sampled object-compatibility evidence satisfies the unchanged $10^{-5}$ gate.

The label never means that the unmodified package's internal arrays were directly
observed. It does not establish package-version-independent equivalence, transitive
dependency completeness, MATLAB parity, a holomorphic complex-$k$ chart, a pole-free
disk, continuous kernel--field equivalence, a guided root, an eigenvalue, an error
estimator, effectivity, or certification.

Until the completed artifacts receive a new Researcher/Skeptic review,
`ROOT_READINESS=BLOCKED_UPSTREAM_PROVENANCE`,
`ROOT_READINESS_SAMPLED_DISCRETE_GO=0`, and `PHYSICAL_ROOT_READY=STOP` remain unchanged.
If the source-derived provenance label is accepted after review, it may authorize only a
separate full analytic root-readiness design. It does not authorize root isolation.
