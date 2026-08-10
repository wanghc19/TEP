<!-- I4 full analytic complex-wavenumber root-readiness experiment design -->

# I4 full analytic complex-wavenumber root-readiness

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: pre-registered code-experiment plan
- Origin Date: 2026-08-07
- Verification Status: PRE-IMPLEMENTATION REVIEWED / PASS WITH CONDITIONS
- Version Label: eig-apost-i4-readiness-v1.0
- Repro Lock: null until the direct-call manifest is frozen by the implementation
- Upstream Dependencies:
  `eig-apost-provenance-closure-v1.1`,
  `eig-apost-provenance-closure-post-run-review-v1.0`, and
  `eig-apost-aug-bie-v1.0`

This document freezes the smallest full analytic complex-$k$ experiment needed to
resolve `OP-I4-1`. It instantiates the dormant re-entry protocol in
[[research/projects/eig-apost/implementation/root_readiness|the I3 Root-readiness
design]] after the accepted source-derived provenance closure. The governing root
qualification logic remains
[[research/projects/eig-apost/phase3-analysis/s-root|the Phase 3 root protocol]] and
[[research/projects/eig-apost/phase4-report/method.tex|the integrated method]].

## Question and maximum claim

The experiment asks whether one test-local, fixed-dimensional augmented matrix family
$F_{j,h}^{\mathrm{aug}}(k)$ behaves as a single analytic numerical evaluator on one
small sampled complex disk, with one anchored Rayleigh chart, one fixed proxy chart,
and every required construction factor available.

A positive result may emit only
`ROOT_READINESS_SAMPLED_DISCRETE_GO`. This label authorizes a separately frozen I5
contour/root-isolation experiment. It does not establish a root, an eigenvalue, a
pole-free theorem, continuous kernel--field equivalence, representation injectivity,
an estimator, effectivity, or certification. `PHYSICAL_ROOT_READY=STOP` remains in
every I4 outcome.

The following computations are forbidden in I4:

- argument-principle or Beyn root counts;
- bordered Newton or any other root solve;
- adjacent-level root matching or simple-root qualification;
- projected root/map corrections, estimators, effectivity, or intervals; and
- any modification of package source or production interfaces.

## Authorized implementation boundary

All implementation and generated evidence belong under the new experiment directory
`test/root-ready/analytic-readiness/`. Package files and every older experiment are
read-only. The implementation may copy the minimum required package arithmetic into
test-local files and change only the interfaces and square-root data flow needed to
inject the frozen branch chart.

The required test-local boundary is:

1. `LOCAL_anchored_rayleigh_channels.m`, which constructs port channel records from
   supplied anchored values;
2. `LOCAL_precomp_proxy_anchored.m`, which uses the proxy-order anchored values,
   returns the unsolved $A_{\mathrm{pr}}(k),b_{\mathrm{pr}}(k)$, and does not perform
   an adaptive complex-$k$ least-squares solve;
3. `LOCAL_qpgreen_mfs_pairmat_anchored.m`, which uses the same supplied proxy-order
   branch for every outer plane-wave target;
4. `LOCAL_construct_A_QP_anchored.m`, whose Green call is redirected only to the
   test-local anchored pair-matrix evaluator; and
5. a local corrected scaled-scattering path plus the frozen I2 nine-block augmented
   assembly and doubling formulas.

Package `bloch.incident_rhs` and `bloch.farfield_extractors` may be called with the
anchored channel record because they consume, but do not recreate, $\gamma_m$.
Package `bloch.rayleigh_channels`, `kernel.precomp_proxy`,
`kernel.qpgreen_mfs_pairmat`, `op.construct_A_QP`, and `bloch.construct_S` are not part
of the positive complex-$k$ evaluator.

The stable provenance label is `SOURCE_DERIVED_BRANCH_INJECTED_TEST_EVALUATOR`. It is
not `SOURCE_EXACT_COPY`. At the real seed, the local pointwise physical branch and
public package outputs are comparison anchors only. The I3 statement
`production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED` remains unchanged.

## Frozen physical and discretization data

| Quantity | Frozen value |
|---|---|
| quasiperiodic parameter | $\beta=0.8$ |
| real scan interval | $[0.04,0.18]$ |
| material index | $n_{\mathrm{ref}}=3$ |
| interior wavenumber | $k_{\mathrm{int}}(k)=3k$ |
| bulk lead ellipse semiaxes | $(0.40,0.30)$ |
| center defect ellipse semiaxes | $(0.28,0.21)$ |
| placement and rotation | cell-centered and unrotated |
| walls and cell length | $X_L=-1$, $X_R=1$, $L=2$ |
| transverse period | $d=2\pi$ |
| port order | $M=7$, hence $p=15$ |
| boundary nodes | 60 per ellipse |
| scan level | $j=3$ |
| sampled levels | $j=0,3,4$ |
| CR endpoint levels | $j=0,4$ |
| terminal closure | frozen Stage 2 far-end Dirichlet closure |

The base proxy uses $H=1.8$, proxy distance $0.7$, 40 side points, 40 top
points, 24 sources per edge, and plane-wave order 8. The single predeclared proxy
refinement uses 48 side points, 48 top points, 28 sources per edge, and plane-wave
order 10.

For both ellipses the only allowed density coordinate is

$$
  \xi=D_h\eta,\qquad
  B=D_hB^{\mathrm{phys}},\qquad
  \mathcal E=\mathcal E^{\mathrm{phys}}D_h^{-1}.
$$

The run records $D_h$, its fingerprint, the two scaling identities, and the fixed I2
row/column order. Re-entry through the uncorrected production variable-speed scaling
path is `SCALING_COORDINATE_MISMATCH` and stops the experiment.

## Anchored Rayleigh chart

For each port or proxy order $m$, set

$$
  \beta_m=\beta+\frac{2\pi m}{d},\qquad
  \gamma_m(k)^2=k^2-\beta_m^2.
$$

At the selected real seed $k_c$, choose the physical outgoing or decaying value
$\gamma_{m,c}$. On a disk that contains none of $\pm\beta_m$, define

$$
  \gamma_m(k)=\gamma_{m,c}\exp\!\left[
    \frac12\operatorname{Log}\!\left(1+\frac{k-k_c}{k_c-\beta_m}\right)
    +\frac12\operatorname{Log}\!\left(1+\frac{k-k_c}{k_c+\beta_m}\right)
  \right],
$$

using the fixed principal logarithm of the two near-one factors. The disk rule below
keeps both factors away from the logarithm cut. The same provider and ordering
fingerprint must supply:

- port phases and incident traces;
- proxy top/bottom plane-wave value and derivative rows;
- outer quasi-periodic Green plane-wave evaluation;
- defect-center BIE construction;
- bulk-lead BIE construction; and
- incident and far-field Rayleigh matrices.

At every sampled node require

$$
  \max_m\frac{|\gamma_m(k)^2-(k^2-\beta_m^2)|}
    {\max(1,|k^2-\beta_m^2|)}\le10^{-12}
$$

and a seed-to-node-to-seed continuation error at most $10^{-12}$. A branch identifier,
mode order, seed values, and provider-source fingerprint are part of every accepted
representation record.

## Real locator and fixed proxy charts

The locator uses 29 equally spaced real points on $[0.04,0.18]$ at $j=3$. This pass
may use the package pointwise proxy solve only to choose a provisional dip. No failed
point may be omitted. Define

$$
  s(k)=\frac{\sigma_{\min}(F_{3,h}^{\mathrm{aug}}(k))}
  {\max(1,\|F_{3,h}^{\mathrm{aug}}(k)\|_2)}.
$$

The selected point is the smallest strict interior minimum satisfying
$s(k)\le10^{-3}$ and with both neighbors at least $1.5s(k)$. Ties go to smaller $k$.
If no point qualifies, emit `NO_SCREENED_DIP` and stop without changing geometry,
grid, threshold, or representation.

At the selected point, form one thin SVD of the returned base proxy system. Select

$$
  r_{\mathrm{seed}}=\max\left\{q:
  \frac{\sigma_q}{\sigma_1}\ge10^{-8}\right\}.
$$

Freeze $U_r,V_r$ and solve only

$$
  (U_r^*A_{\mathrm{pr}}(k)V_r)a_r(k)=U_r^*b_{\mathrm{pr}}(k),
  \qquad c_r(k)=V_ra_r(k).
$$

No SVD, rank, projector, row subset, or coordinate may be recomputed away from the
seed. The base sensitivity set is
$r=r_{\mathrm{seed}}-2,r_{\mathrm{seed}}-1,r_{\mathrm{seed}}$; a nonpositive rank is
unavailable and stops the stage. The refined proxy selects its own seed rank by the
same rule and then freezes it.

The seed selected singular value must be at least $10^{-8}$ relative to $\sigma_1$.
The seed gap $\sigma_r/\sigma_{r+1}$ must be at least 2; otherwise the unchanged-source
baseline/repeat projectors must agree within $10^{-10}$ in relative Frobenius norm.
For $r_{\mathrm{pr}}=A_{\mathrm{pr}}c_r-b_{\mathrm{pr}}$, the frozen collocation
residuals are

$$
\begin{aligned}
  r_P&=\frac{\|U_r^*r_{\mathrm{pr}}\|_2}
    {\max(1,\|b_{\mathrm{pr}}\|_2)},\\
  r_{P,\mathrm{back}}&=
    \frac{\|U_r^*r_{\mathrm{pr}}\|_2}
    {\max(1,\|U_r^*A_{\mathrm{pr}}V_r\|_2\|a_r\|_2+
      \|U_r^*b_{\mathrm{pr}}\|_2)},\\
  r_{\mathrm{full}}&=\frac{\|r_{\mathrm{pr}}\|_2}
    {\max(1,\|b_{\mathrm{pr}}\|_2)}.
\end{aligned}
$$

The reduced factor rcond is at least $10^{-8}$, $r_P$ and
$r_{P,\mathrm{back}}$ are at most $10^{-11}$, $r_{\mathrm{full}}$ is at most
$10^{-5}$, and coefficient norms must be finite.

The independent point set is frozen as `SHIFTED_DENSIFIED_MIDPOINT_2X`: twice as many
side and top/bottom points as the corresponding collocation grid, placed at uniform
cell midpoints. Its six blocks are quasiperiodic value, quasiperiodic derivative, top
value, top derivative, bottom value, and bottom derivative. For block $q$ with shifted
system rows $A_q,b_q$, record

$$
  r_q=\frac{\|A_qc_r-b_q\|_2}{\max(1,\|b_q\|_2)},
  \qquad
  r_{\mathrm{off}}=
  \frac{\|A_{\mathrm{off}}c_r-b_{\mathrm{off}}\|_2}
  {\max(1,\|b_{\mathrm{off}}\|_2)}.
$$

Every one of the six $r_q$ values and $r_{\mathrm{off}}$ must be at most $10^{-5}$.
The shifted assembly uses the same anchored proxy-order provider and the same frozen
coefficients as the collocation evaluation; it may not recompute pointwise roots.

Using each frozen chart, run two successive nine-point refinements around the selected
real minimum. Every refinement retains a strict interior minimum. The coarse and final
positions agree within two final-grid steps. The scaled center part of the smallest
right singular direction has norm at least $10^{-3}$, and the phase-invariant overlap
of the two refinement directions is at least $0.9$.

Across the three base ranks and refined proxy require:

1. final locator positions differ by at most two base final-grid steps;
2. center-direction overlaps are at least $0.9$;
3. 16- and 32-node disk samples give the same availability classification;
4. boundary-separation minima differ by at most $50\%$;
5. maximum boundary full-$F$ chart spread is at most one tenth of the smallest positive
   relative boundary separation; and
6. maximum locator full-$F$ chart spread is at most one tenth of the smallest positive
   locator value across the four charts.

## Candidate disk and sampled factor ledger

Let $\Delta k_f$ be the final real-grid step and let $d_{\mathrm{br}}$ be the minimum
distance from $k_c$ to $0$ and to all port and proxy branch points $\pm\beta_m$. Define

$$
  r_0=\min(2\Delta k_f,\tfrac14d_{\mathrm{br}}).
$$

Try $r_0,r_0/2,r_0/4$ in that order. Keep every attempt and failure. Accept the first,
and therefore largest, attempt that passes its complete node, chart, factor, separation,
and CR conjunction. Failures of earlier larger attempts remain evidence but do not
reject a later permitted shrink. Once an attempt passes, no smaller disk is evaluated
or substituted. The stage stops only when all three attempts fail, or when an upstream
gate independent of radius fails. No fourth shrink, shifted center, changed proxy,
changed discretization, or relaxed threshold is allowed.
Each attempt contains nested 16- and 32-point boundary samples, the center, and eight
equally spaced points on the half-radius circle.

At $j=0,3,4$, every node records representation fingerprints and the following factors.

| Factor or diagnostic | Frozen gate |
|---|---|
| distance from $0$ and all branch points | radius no larger than one quarter of the minimum distance |
| branch algebra and continuation | each at most $10^{-12}$ |
| fixed reduced proxy factor | rcond at least $10^{-8}$ |
| proxy projected residuals | each at most $10^{-11}$ |
| proxy full/off-collocation residual | each at most $10^{-5}$ |
| real-axis package-anchor/anchored Green and full-$F$ mismatch | each at most $10^{-5}$ at the anchor and real refinement nodes only |
| defect and bulk BIE matrices | rcond at least $10^{-6}$ |
| BIE solve residual | at most $10^{-9}$ |
| every doubling factor through level 4 | rcond at least $10^{-8}$ |
| terminal, far-block, and $K_{ee}$ factors | rcond at least $10^{-8}$ |
| other square-factor residual | at most $10^{-9}$ |
| full augmented boundary separation | at least $10^{-8}$ |
| 16-to-32 sampled minimum change | at most $50\%$, with no new failure |

The reduced proxy, bulk-lead BIE, and doubling factors are inverted in the raw evaluator;
their singularities are evaluator poles. Center, terminal, far-block, and $K_{ee}$
failures block representation or reduced interpretation but are not labeled raw-matrix
poles when the raw assembly does not invert them. The ledger stores `factor_role`,
`raw_inverted`, `rcond`, `residual`, `availability`, and `failure_reason` so this
distinction cannot be lost.

Passing the sampled ledger establishes only `SAMPLED_DOMAIN_AVAILABLE`. A hidden
interior pole remains a disclosed limitation, not a theorem-level exclusion.

## Full-matrix Cauchy--Riemann gate

At the center and eight half-radius nodes, and at levels $j=0,4$, set

$$
\begin{aligned}
  D_x(h)&=\frac{F(k+h)-F(k-h)}{2h},\\
  D_y(h)&=\frac{F(k+\mathrm{i}h)-F(k-\mathrm{i}h)}{2\mathrm{i}h},\\
  e_{\mathrm{CR}}(h)&=
  \frac{\|D_x(h)-D_y(h)\|_F}
  {\max(1,\|D_x(h)\|_F,\|D_y(h)\|_F)}.
\end{aligned}
$$

Use $h_0=\min(r/32,10^{-4}\max(1,|k_c|))$ and
$h=h_0,h_0/2,h_0/4$. Require final $e_{\mathrm{CR}}$, real-derivative spread, and
imaginary-derivative spread all at most $10^{-6}$. The CR sequence is non-increasing
from $h_0/2$ to $h_0/4$, unless both values lie at a documented rounding floor and all
matrix differences are within 100 machine epsilons of scale. Failure is
`FULL_F_CR_DEFECT`; differentiating a reduced subblock cannot repair it.

## Mandatory falsification matrix

All eleven cases use the same checkers as the positive path.

| ID | Mutation | Required outcome |
|---|---|---|
| N1 | pointwise outgoing square root across a manufactured propagating real-axis seed | branch/CR defect greater than $\max(10^{-3},100e_{\mathrm{CR}}^{\mathrm{good}})$ |
| N2 | adaptive pointwise `pinv`/SVD on an inconsistent tall analytic system | the same quantitative CR rejection |
| N3 | adaptive recompression or rank reselection away from the seed | deterministic `REPRESENTATION_DRIFT` |
| N4 | outer Green path recomputes principal roots while proxy roots stay anchored | branch/CR rejection in the off-box Green fixture |
| N5 | flip one continued $\gamma_m$ sign | branch fingerprint rejection |
| N6 | add $10^3\overline{k}e_1e_1^*$ to the frozen $240\times240$ full matrix | defect greater than $\max(10^{-3},100e_{\mathrm{CR}}^{\mathrm{good}})$ |
| N7 | force $U_r^*A_{\mathrm{pr}}V_r$ singular at a sampled node | `PROXY_COMPRESSION_POLE`; downstream unavailable |
| N8 | a frozen manufactured scalar factor has a recorded interior pole at $k_p$, while all coarse boundary samples are finite and available | emit `SAMPLED_DOMAIN_AVAILABLE` together with `HIDDEN_INTERIOR_POLE_UNEXCLUDED`, record $k_p$, and keep any pole-free claim unavailable; a report-string check is insufficient |
| N9 | Stage 2 zero-field density / representation-nullspace fixture with the frozen common nullvector | detect the expected rank loss, emit `ZERO_FIELD_REPRESENTATION`, preserve the raw $F$, and make every physical-interpretation field unavailable |
| N10 | sweep one doubling or terminal factor across its rcond gate | deterministic availability transition; no singular solve |
| N11 | replace the bulk ellipse with the Stage 2 circle | `CIRCLE_LEAD_INTERFACE_SMOKE`; target-domain GO forbidden |

Every row is mandatory. A missing, unavailable, or incorrectly accepted negative stops
I4. The seven summary categories in the I3 handoff are satisfied only by the complete
eleven-row matrix above.

## Evidence contract and reproducibility

Each baseline and repeat directory contains at least:

- `config.txt`;
- `source-manifest.csv`;
- `branch-ledger.csv`;
- `locator.csv`;
- `chart-ledger.csv`;
- `sampled-domain.csv`;
- `factor-ledger.csv`;
- `cr.csv`;
- `negative-cases.csv`;
- `gate.csv`;
- `results.mat`;
- `run.log`;
- `report.md`; and
- `completion.marker`.

The aggregate output also contains `reproducibility.txt`. `config.txt` serializes every
frozen number, semantic identifier, command, expected row set, threshold, source path,
and SHA-256 with at least 17 significant digits for numeric arrays. The manifest covers
the design, symbol ledger, driver, wrapper, every test-local derived copy, and every
directly called project helper. It is labeled `DIRECT_PROJECT_CALLS_ONLY`.

Before the first baseline evaluation, the wrapper records the current commit, exact
worktree-status path set, design SHA-256, and complete direct-call manifest. Every dirty
path must belong to the authorized I4 design, ledger, or experiment directory; any
unrelated path stops before numerical sampling. The recorded path set, design, and
manifest may not change between baseline and repeat. This lock cannot
prove that no development run occurred before the frozen baseline, and the final report
discloses that limitation.

Publication uses `output.inprogress/baseline/` and `output.inprogress/repeat/`. Each
marker is written last after row counts, headers, nonzero sizes, loadable `results.mat`,
closed log, manifest, and gate states validate. Only the completed repeat may atomically
rename the staging tree to `output/`. Neither a partial tree nor a tree without valid
markers is evidence. Existing output trees are never deleted or overwritten.

The experiment is deterministic in the frozen Octave environment. Baseline/repeat
numeric vectors, dimensions, representation identifiers, branch/provider fingerprints,
source manifests, chart projector fingerprints, selected disk, and gate classifications
must agree exactly; floating CSV metrics must have symmetric relative difference at most
$10^{-13}$. Timing is recorded but not compared.

The exact commands, run from the repository root, are

```text
perl -e 'alarm shift; exec @ARGV' 3600 conda run -n octave octave --quiet --no-gui --eval "addpath('test/root-ready/analytic-readiness'); run_analytic_readiness('baseline');"
perl -e 'alarm shift; exec @ARGV' 3600 conda run -n octave octave --quiet --no-gui --eval "addpath('test/root-ready/analytic-readiness'); run_analytic_readiness('repeat');"
```

Timeout, source drift, partial output, nonreproduction, or any failed upstream gate can
never emit a positive label. MATLAB is not part of I4 unless Octave cannot correctly
execute the frozen evaluator; such a change requires a new reviewed command and does not
retroactively alter Octave evidence.

## Decision rule

The positive conjunction contains:

1. source, environment, representation, scaling, and branch-provider locks;
2. locator, fixed-chart, proxy-refinement, participation, and chart-spread gates;
3. one accepted disk with complete 16/32 sampling and every factor gate;
4. all full-$F$ CR and derivative-refinement gates;
5. all eleven mandatory negatives;
6. exact artifact coverage and transactional markers; and
7. unchanged-source baseline/repeat reproduction.

Any missing branch consumer, representation drift, missing negative, post-result
retuning, incomplete artifact, or radius-independent upstream failure leaves `OP-I4-1`
open. For disk-dependent node, factor, separation, or CR failures, the deterministic
three-attempt rule applies: only failure of all three radii stops the stage. Every STOP
emits `ROOT_READINESS_SAMPLED_DISCRETE_STOP` with a stable first failure and complete
all-failure ledger.

Only a reviewed complete conjunction may emit
`ROOT_READINESS_SAMPLED_DISCRETE_GO`. Even then, the sole authorization is to design I5;
no I5 code or computation is part of this experiment.
