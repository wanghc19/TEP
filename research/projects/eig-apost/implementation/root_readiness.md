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
