# I4.1c curved isoparametric P2 FEM reference experiment design

Status: **`RESEARCHER DESIGN FROZEN / SAME SKEPTIC DESIGN REVIEW REQUIRED / NOT IMPLEMENTED / NOT RUN`**.

This design is a new experiment under the accepted independent-reference method in
[[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]].  It changes only the
interface geometry representation of the completed straight-sided $P_2$ experiment governed by
[[research/projects/eig-apost/implementation/i4/design-4-1b|design-4-1b]] and
[[research/projects/eig-apost/implementation/i4/review-4-1b#AE. Final post-run review of run-002/execution-002|review-4-1b §AE]].
The old `femref-a1` and `femref-a2` sources, artifacts, reviews and conclusions are immutable
evidence and are not runtime inputs.

## 1. Context, question and claim boundary

### 1.1 Context snapshot

| Item | Frozen value |
|---|---|
| Exact question | Can a conforming six-node isoparametric $P_2$ FEM with quadratic curved disk-interface edges produce a finite, residual-valid, field-bearing empirical reference for the same fixed-$\beta$ guided-mode problem? |
| Current stage | New I4.1c design; no `femref-a3` implementation or output exists at freeze time. |
| Method authority | [[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]] and its [[research/projects/eig-apost/implementation/i4/method-review|method review]]. |
| Implementation evidence | The completed straight-sided P2 run and final post-run review in `femref-a2`; they are planning evidence only. |
| Requested artifact | At least one create-once curved-P2 eigenvalue/eigenfunction selected by current-run FEM information, followed where time permits by independent refinement axes. |
| Success criterion | A legal curved mesh, finite Hermitian forms with SPD mass, a converged eigenpair with reconstructable field, deterministic FEM-only mode identity, canonical publication, and Skeptic post-run review. |
| Exclusions | No estimator, effectivity, BIE/QZ-guided selection, certified error bound, continuous gap/existence theorem, rational/NURBS geometry, or package/main-code change. |

The constructive design status is `CONDITIONAL`: the local mapping and validation contract below
are mathematically determined, while their MATLAB implementation and numerical outputs remain
unverified until the Engineer and Skeptic gates pass.

### 1.2 Allowed output

The strongest allowed result is a **non-certified empirical curved-$P_2$ reference candidate**

$$
k_{\mathrm{ref}}^{\mathrm{curved},P_2},
\qquad
\lambda_{\mathrm{ref}}^{\mathrm{curved},P_2}
=\left(k_{\mathrm{ref}}^{\mathrm{curved},P_2}\right)^2,
$$

with a complete field identity record and whatever refinement components were actually observed.
If only the first legal branch is completed, it is published as
`PRELIMINARY_EMPIRICAL_CURVED_P2_REFERENCE`; incomplete axes are explicit `NaN` values and caveats,
not a reason to suppress that reference.

No quantity in this experiment is a certified $\varepsilon_{\mathrm{ref}}$, confidence interval,
continuous-spectrum enclosure, continuous eigenvalue-existence result or estimator effectivity.
Position agreement with any later-revealed number cannot strengthen this claim.

## 2. Absolute lifecycle, files and create-once identities

The lifecycle origin supplied to the collaboration is

$$
T_0=1788262898
\quad\text{(2026-09-01T11:41:38Z)},
$$

and the immutable total deadline is

$$
T_{\mathrm{end}}=T_0+18000=1788280898.
$$

Research, review, implementation, debugging, preflight, formal science and publication share this
deadline.  It is never reset by a new process or execution label.  The only writable experiment
directory is `test/i4/femref-a3/`; this design is the only Researcher-owned file.

The exact prospective identities are:

- actual-representation preflight: `resource-preflight-001/execution-001`;
- formal curved-P2 science: `run-001/execution-001`.

Both are create-once.  A completed, scientific-negative, resource or publication terminal consumes
its execution label.  A source, path, schema, controller or environment failure preserves its
leaf and, after bounded Researcher--Engineer--Skeptic repair, uses the smallest unused explicit
`execution-002`, `execution-003`, and so on under the same `run-001` or preflight parent.  No leaf
is overwritten, and no operational retry creates a new attempt directory.

For every executable command starting at $T_{\mathrm{run}}$, the only wall deadline is

$$
T_{\mathrm{run,hard}}
=\min\{T_{\mathrm{run}}+2700,T_{\mathrm{end}}\}.
$$

The only memory predicate is inclusive aggregate process-tree RSS

$$
R_{\mathrm{tree}}\ge3221225472\ \mathrm{B}.
$$

There is no lower wall/RSS limit, forecast stop, reserve, stall rule, guard, grace period or
capacity simulation.  A controller converts the two absolute wall endpoints to one monotonic
alarm, samples a deduplicated target process tree, kills it immediately at either hard predicate,
and keeps the alarm armed through atomic summary-last publication.  Resource estimates in Section
12 are planning evidence only.

## 3. Unchanged continuous and supercell problem

The continuous model is unchanged from I4.1a/b.  Let

$$
\Omega=\mathbb R\times\left(-\frac12,\frac12\right).
$$

The period is $1$, the exact material disks have radius $R=0.2$, the column at $x=0$ is missing,
$q=17$ in every remaining disk and $q=1$ outside, and $\beta=0.5$.  The exact problem is

$$
-\Delta u=\lambda q u,
\qquad \lambda=k^2,
$$

with continuity of $u$ and $\partial_\nu u$ across every exact circular interface and

$$
u(x,y+1)=e^{\mathrm i\beta}u(x,y).
$$

For the defect supercell

$$
\Omega_N=(-N-1/2,N+1/2)\times(-1/2,1/2),
$$

the second phase condition is

$$
u(x+2N+1,y)=e^{\mathrm i\vartheta}u(x,y).
$$

The discrete weak form remains

$$
\int_{\Omega_N}\nabla u\cdot\nabla\overline v
=\lambda\int_{\Omega_N}q\,u\overline v.
$$

The bulk problem uses one ordinary cell with $x$ phase $e^{\mathrm i\alpha}$.  No change to
polarization, coefficient placement, normalization, phase sign, supercell period or $\lambda=k^2$
is permitted.

## 4. Curved conforming $P_2$ geometry

### 4.1 Topology and geometry nodes

The deterministic constrained-Delaunay **vertex connectivity** and its complete legality checks are
inherited from the final `femref-a2` original-connectivity path.  Each sorted global active edge
owns exactly one global midpoint geometry/field node.  For a local triangle ordered

$$
(v_1,v_2,v_3,e_{12},e_{23},e_{31}),
$$

the six Lagrange functions are

$$
N_i=\ell_i(2\ell_i-1),\quad i=1,2,3,
$$

$$
N_4=4\ell_1\ell_2,\qquad
N_5=4\ell_2\ell_3,\qquad
N_6=4\ell_3\ell_1.
$$

All polygon-interface endpoint vertices lie on their exact circle.  An active edge is an interface
edge only when it is an exact row of the frozen circle-constraint inventory.  Its midpoint is put
at radius $R$ and at the unwrapped angular midpoint of its two endpoints on that same disk.
Every non-interface edge, including all outer and periodic edges, uses the arithmetic midpoint.
The edge table is global, so the two incident elements share the same physical midpoint and field
DOF.  Each interior interface edge must have incidence two and opposite finite material labels on
its two incident triangles.

This construction interpolates the true circle at endpoints and arc midpoints but is still a
polynomial quadratic approximation between them.  Increasing $g$ is therefore a genuine geometry
axis.  The method must not be described as exact-circle geometry or silently changed to a rational
arc, NURBS or another geometry family.

### 4.2 Isoparametric map and forms

On the reference triangle

$$
\widehat T=\{(\xi,\eta):\xi\ge0,\ \eta\ge0,\ \xi+\eta\le1\},
$$

with $(\ell_1,\ell_2,\ell_3)=(1-\xi-\eta,\xi,\eta)$, define

$$
F_T(\xi,\eta)=\sum_{a=1}^6X_aN_a(\xi,\eta),
\qquad
J_T=\frac{\partial F_T}{\partial(\xi,\eta)}.
$$

At each quadrature point, the local forms are assembled as

$$
(K_T)_{ab}
=\int_{\widehat T}
(J_T^{-\mathsf T}\widehat\nabla N_b)\cdot
(J_T^{-\mathsf T}\widehat\nabla N_a)
\det J_T\,\mathrm d\xi\,\mathrm d\eta,
$$

$$
(M_T)_{ab}
=\int_{\widehat T}q_TN_bN_a\det J_T\,\mathrm d\xi\,\mathrm d\eta.
$$

No affine area/gradient formula, absolute determinant in place of orientation validation, mass
lumping, interface smoothing or material averaging is allowed.  The coefficient $q_T$ is constant
on each curved element and is inherited from the two-sided fitted-interface label; localization
forms use the same map and physical quadrature coordinates.

### 4.3 Exact quadratic determinant check in binary64

Writing

$$
F_T=A_{00}+A_{10}\xi+A_{01}\eta+A_{20}\xi^2+A_{11}\xi\eta+A_{02}\eta^2,
$$

the coefficient vectors are frozen as

$$
\begin{aligned}
A_{00}&=X_1,\\
A_{10}&=-3X_1-X_2+4X_4,\\
A_{01}&=-3X_1-X_3+4X_6,\\
A_{20}&=2X_1+2X_2-4X_4,\\
A_{02}&=2X_1+2X_3-4X_6,\\
A_{11}&=4X_1-4X_4+4X_5-4X_6.
\end{aligned}
$$

Thus

$$
d_T(\xi,\eta)=\det J_T
=c_{00}+c_{10}\xi+c_{01}\eta+c_{20}\xi^2+c_{11}\xi\eta+c_{02}\eta^2.
$$

The implementation forms these coefficients directly and finds the global minimum of this
quadratic over $\widehat T$ by evaluating all three vertices, every in-interval stationary point
of the three one-dimensional edge restrictions, and the interior stationary point when it exists
and lies in $\widehat T$.  These candidates are exhaustive for a quadratic on a triangle.  Define

$$
\tau_{\det}=512\epsilon_{\mathrm{mach}}
\max\left\{1,\sum_{i,j}|c_{ij}|\right\}.
$$

Every element must have finite coefficients and

$$
\min_{\widehat T}d_T>\tau_{\det}.
$$

Direct determinant evaluation at every assembly and validation point must be positive and agree
with the coefficient polynomial within $512\epsilon_{\mathrm{mach}}$ times the local coefficient
scale.  Failure is `CURVED_MAPPING_INVALID`, a discrete mathematical blocker.  Passing is only a
strict **numerical** orientation check; it is not an interval-arithmetic certificate.

## 5. Quadrature and curved-element validation

### 5.1 Duffy--Gauss ladder

Let $(r_i,w_i)_{i=1}^Q$ be the deterministic $Q$-point Gauss--Legendre rule on $[0,1]$.  The
triangle rule is the tensor Duffy map

$$
\xi=r_i,\qquad \eta=(1-r_i)r_j,qquad
\widehat w_{ij}=w_iw_j(1-r_i).
$$

Here the interval weights satisfy $\sum_iw_i=1$, so
$\sum_{i,j}\widehat w_{ij}=1/2$; this is the reference-triangle area convention used by the
barycentric-monomial identity below.

The only scientific quadrature orders are

$$
Q\in\{4,6,8\}.
$$

For a quadratic map, $N_aN_b\det J_T$ has total polynomial degree at most six.  Therefore the
$Q=4$ Duffy rule integrates the element mass polynomial exactly in exact arithmetic.  The
stiffness integrand is generally rational because of $J_T^{-1}$ and is not covered by an affine
polynomial-degree argument.  Its resolution is assessed by the independent $Q=4\to6\to8$ ladder;
$Q=6$ supplies the first preliminary solve and $Q=8$ is the final anchor authority when valid.

Each generated one-dimensional rule must integrate $r^m$, $0\le m\le2Q-1$, and each Duffy rule
must integrate every barycentric monomial of total degree at most $2Q-2$ against

$$
\int_{\widehat T}\ell_1^a\ell_2^b\ell_3^c
=\frac{a!b!c!}{(a+b+c+2)!}
$$

within $2\times10^{-13}$ relative/absolute tolerance.  On every curved mesh, the constant and
physical monomials $1,x,y,x^2,xy,y^2$ are compared across $Q=4,6,8$.  Mass matrices at $Q=4,6,8$
must agree to the inherited $10^{-11}$ P1-embedding/operator scale; stiffness changes remain
published empirical quadrature evidence rather than an artificial cancellation gate.

### 5.2 Mandatory pre-eigensolve mathematical checks

Before any spectrum on a mesh/phase may be used, the implementation must verify:

1. the $6\times6$ nodal interpolation identity, partition of unity and zero summed reference
   gradient to the inherited $5\times10^{-14}$/$5\times10^{-13}$ tolerances;
2. $F_T$ interpolates all six geometry nodes, every circle endpoint and curved midpoint has radial
   error at most `coordinate_tolerance`, and non-interface midpoint arithmetic is exact to the
   same scale;
3. every shared curved edge has the same quadratic physical trace from both incident elements
   after orientation reversal.  Endpoint, midpoint and at least two interior edge probes must agree;
4. every curved interface loop is closed, ordered, non-self-intersecting and remains inside its
   owning cell; nonincident curved interface traces may not cross or touch;
5. the global determinant-minimum contract in Section 4.3 passes for every element;
6. the Duffy monomial checks, curved constant/low-monomial checks and mass exactness checks pass;
7. the independently assembled reference-linear subspace on the **same curved map and same
   quadrature** obeys the local and global P1-in-P2 identities below;
8. full and reduced stiffness/mass entries are finite, raw Hermitian defects are at most
   $5\times10^{-13}$, and the mass is SPD under the fill-reduced Cholesky check;
9. vertex and midpoint periodic pairings, seam phases and the corner product phase are valid; and
10. nonlinear field reconstruction maps fixed reference probes forward and back with finite
    coordinate residual no larger than $5\times10^{-12}\max\{1,h_T\}$.

Items 1--10 protect mathematical correctness.  Failures are implementation/representation
blockers to that mesh, not scientific evidence against curved FEM.  One failed refinement mesh is
recorded and skipped; an invalid preliminary anchor must be repaired in the same `femref-a3`
attempt rather than converted into a new method.

### 5.3 P1 subspace on the curved geometry

Let

$$
E_T=
\begin{pmatrix}
1&0&0\\0&1&0\\0&0&1\\
1/2&1/2&0\\0&1/2&1/2\\1/2&0&1/2
\end{pmatrix}.
$$

The independent three-function forms use the reference basis
$(\ell_1,\ell_2,\ell_3)$ but the same variable $J_T$, the same $q_T$ and the same Duffy points as
the six-function forms.  They must satisfy

$$
E_T^*K_T^{(2)}E_T=K_T^{(1,\mathrm{curved})},
\qquad
E_T^*M_T^{(2)}E_T=M_T^{(1,\mathrm{curved})}
$$

to relative Frobenius tolerance $10^{-11}$.  The corresponding full/reduced embedding must commute
with both quasiperiodic prolongations and pass on the anchor at $\vartheta=\pi/4$ using $Q=8$.
This validates the curved-map basis and phase implementation; it is not a P1 eigenvalue experiment
or a mode-identity rule.

## 6. Quasiperiodic reduction and eigensolver

The complete vertex-plus-shared-midpoint DOF set is reduced exactly as in the reviewed P2 method.
Every full row has one unit-modulus prolongation entry.  Right/top slaves receive
$e^{\mathrm i\vartheta}$ or $e^{\mathrm i\alpha}$ and $e^{\mathrm i\beta}$; the corner receives the
order-independent product.  Because outer boundaries are straight, their midpoint pairing remains
coordinate-bijective.

For canonical sparse reduced mass $M_\phi$, positive definiteness is checked with

$$
p=\operatorname{symamd}\!\left(\operatorname{spones}(M_\phi+M_\phi^*)\right),
\qquad
\operatorname{chol}(M_\phi(p,p)).
$$

The permutation is validated and the factor is cleared immediately after its flag and `nnz` are
recorded.  It is never stored in a pair or field artifact.

Defect calls use

```text
[V,D,flag] = eigs(K,M,48,'smallestabs',opts)
```

with `opts.p=96`, `maxit=800`, `tol=1e-10`, `isreal=false`, `disp=0` and the deterministic
master-coordinate start vector inherited from design-4-1b Section 15.3.  The loose algebraic axis
uses only `tol=1e-8`.  Bulk calls use 40 roots, `p=80`, `maxit=800` and `tol=1e-9`.

If a preliminary 48-root slice has numerical ceiling below $k=3.35$, or the five preliminary
slices have no rankable three-twist component, all five preliminary slices receive the single
allowed 60-root extension with `p=100`.  Its first 48 roots, ordered clusters, multiplicities and
exact-mass principal subspaces must agree with the immutable 48-root authority as in I4.1b.  An
agreement pass makes 60 roots sole active authority; failure retains valid 48-root fields and marks
coverage partial.  There is no other root-count, shift, tolerance or retry adaptation.

Every active slice requires flag zero, the requested finite positive roots, maximum normalized
residual at most $10^{-9}$, mass-orthogonality defect at most $10^{-7}$ and a finite complete
field subspace.  A whole cluster is never split to manufacture a scalar.

## 7. Curved field reconstruction and mode identity

### 7.1 Nonlinear inverse map

Straight-triangle `pointLocation`, affine barycentric interpolation and every P1 field formula are
forbidden for curved fields.  For each element, the six Lagrange geometry nodes are converted to
the equivalent quadratic Bernstein control points, whose convex hull supplies a conservative
physical bounding box.  A query point tests only boxes containing it.  On each candidate it solves

$$
F_T(\xi,\eta)=x
$$

by deterministic damped Newton iteration using the clipped affine-vertex barycentric seed followed,
if necessary, by the centroid, six interpolation nodes and $Q=4$ Duffy nodes in fixed order.  A
solution is accepted only when its residual meets Section 5.2, its barycentric coordinates lie in
the reference triangle to the frozen coordinate tolerance, and its evaluated determinant is
positive.  Multiple accepted traces use largest minimum barycentric coordinate and then smallest
triangle ID.  Failure to reconstruct a required field gives `CURVED_FIELD_RECONSTRUCTION_INVALID`;
it cannot be downgraded to a localization or parity caveat.

Reference-probe forward/inverse tests are run before an eigensolve.  Common-grid points lying on an
exact circle are removed in reflection pairs.  All remaining field samples use the six $N_a$ at
the solved nonlinear coordinates.  Cross-mesh overlap uses the same symmetric
$161\times65$ physical grid and positive exact-$q$ trapezoidal weights as the accepted P2 method.

### 7.2 FEM-only branch inventory and rank

The source search interval remains

$$
W_3=[0.45,3.25],
$$

and $I_{\mathrm{cue}}=[1.65,2.05]$ is an initial label only.  It never selects a root.  Every
finite, positive, residual-valid, field-bearing whole cluster intersecting $W_3$ enters the
inventory.  On each mesh, adjacent twists are assigned by the complete dummy-augmented
maximum-total-principal-overlap rule already reviewed for I4.1b.  Frequency is only a later exact
tie-break; no BIE/current-root distance is an input.

A rankable branch contains objects at at least three consecutive points of

$$
\Theta_5=\{0,\pi/4,\pi/2,3\pi/4,\pi\}
$$

and at least two real continuation edges.  Its ascending rank is

$$
(-n_\vartheta,-n_{\mathrm{edge}},-O_{\min},r_{\max},c_{\mathrm{miss}},
-L_{\mathrm{core}},p_{\mathrm{parity}},w_\lambda,i_{\min}).
$$

The quantities have the exact I4.1b meanings: branch persistence, field overlap, residual,
spectrum coverage, physical localization, empirical common-grid parity, envelope width and
immutable object ID.  Localization, parity, sampled bulk gap, weak overlap, births/deaths and
refinement contraction are diagnostics and caveats, never filters on a numerically valid object.

Endpoint parity at $\vartheta=0,\pi$ uses the reflected common-grid field/subspace compression,
not a mesh-node symmetry assumption.  Localization/core/tail quantities use curved-map field
quadrature and are published with their availability status.

## 8. Preliminary-first and final reference authority

The preliminary stage uses the anchor

$$
(N,s,g,Q)=(4,9,24,6)
$$

at all five $\Theta_5$ points.  It ranks current-run curved-P2 branches and atomically publishes
`preliminary-result.mat` and `preliminary-fields.mat` before any refinement.  If its winner has
eigenvalue envelope $[\lambda_-,\lambda_+]$, then

$$
\lambda_{\mathrm{pre}}=\frac{\lambda_-+\lambda_+}{2},
\qquad
k_{\mathrm{pre}}=\sqrt{\lambda_{\mathrm{pre}}}.
$$

The final anchor independently solves the same $(N,s,g)=(4,9,24)$ geometry with $Q=8$ and ranks
its objects by the same FEM-only tuple.  The common-grid assignment between $Q=6$ and $Q=8$ is
published.  The $Q=8$ rank-one component is the canonical final curved-P2 winner even if it differs
from the preliminary-matched component; both identities must then be reported.  If a valid $Q=8$
winner exists, its envelope midpoint defines
$k_{\mathrm{ref}}^{\mathrm{curved},P_2}$ and
$\lambda_{\mathrm{ref}}^{\mathrm{curved},P_2}$.  If no $Q=8$ field survives but the preliminary
artifact is valid, $k_{\mathrm{pre}}$ is delivered instead with
`PRELIMINARY / QUADRATURE_REFINEMENT_UNAVAILABLE` and no fabricated final scalar.

All later axes field-match to the frozen final winner.  They cannot reorder it.  No diagnostic or
refinement failure can overwrite the preliminary or final field authorities.

## 9. Frozen solve schedule and refinement axes

The topology parameters are deliberately inherited from the resource-feasible coarse P2 path, not
from the fine P1 schedule.  The exact stages are:

| Stage | Configuration | Phases | $Q$ | Calls |
|---|---|---|---:|---:|
| preliminary | $(N,s,g)=(4,9,24)$ | $\Theta_5$ | 6 | 5 |
| final anchor | $(4,9,24)$ | $\Theta_5$ | 8 | 5 |
| mesh $h$ | $(4,6,24)$ and $(4,12,24)$ | $\Theta_5$ | 8 | 10 |
| interface geometry | $(4,9,16)$ and $(4,9,32)$ | $\Theta_5$ | 8 | 10 |
| supercell | $(3,9,24)$ and $(5,9,24)$ | $\Theta_5$ | 8 | 10 |
| twist | four new points in $\Theta_9\setminus\Theta_5$ on final anchor | additions only | 8 | 4 |
| quadrature coarse | $(4,9,24)$ | $\Theta_5$ | 4 | 5 |
| algebraic loose | $(4,9,24)$ | $\Theta_5$ | 8 | 5 |
| bulk diagnostic | ordinary cell $(s,g)=(9,24)$ | 17 points on $[0,\pi]$ | 8 | 17 |

Thus the base schedule has

$$
5+5+10+10+10+4+5+5+17=71
$$

guided-spectrum calls.  The sole five-call preliminary 60-root extension gives a maximum of 76.
No old schedule is rerun and no result-dependent mesh, $g$, $N$, quadrature order, phase grid,
window or solver parameter is allowed.

Execution priority is immutable: preliminary publication first; $Q=8$ final anchor second; then
$h$ and $g$ comparisons; then $N$, twist, $Q=4$, algebraic and bulk stages.  A hard stop after the
first publication therefore leaves a reviewable eigenpair.  A stage-local failure preserves its
reason and continues the remaining fixed stages when resources and mathematical validity permit.

Expected topology is unchanged by moving shared midpoint coordinates.  Planning evidence from the
accepted straight-sided run is:

| Configuration | Expected full/reduced P2 DOF |
|---|---:|
| $(4,6,24)$ | $3465/3344$ |
| $(4,9,24)$ | $5017/4836$ |
| $(4,12,24)$ | $7473/7232$ |
| $(4,9,16)$ | $4249/4068$ |
| $(4,9,32)$ | $5785/5604$ |
| $(3,9,24)$ | $3853/3708$ |
| $(5,9,24)$ | $6181/5964$ |

These are planning expectations, not lower/upper runtime gates; actual $V,T,E$, full/reduced DOF,
operator `nnz` and factor `nnz` must be recorded.

## 10. Empirical resolution

For the field-matched final component, let $k_C$ be the midpoint scalar of configuration $C$.  The
observed quantities are

$$
\delta_h=\max\{|k_{s9}-k_{s6}|,|k_{s12}-k_{s9}|\},
$$

$$
\delta_g=\max\{|k_{g24}-k_{g16}|,|k_{g32}-k_{g24}|\},
$$

$$
\delta_N=\max\{|k_{N4}-k_{N3}|,|k_{N5}-k_{N4}|\},
$$

$$
\delta_\vartheta=|k_{\Theta_9}-k_{\Theta_5}|,
\qquad
\delta_Q=\max\{|k_{Q6}-k_{Q4}|,|k_{Q8}-k_{Q6}|\},
$$

$$
\delta_{\mathrm{tol}}=|k_{10^{-10}}-k_{10^{-8}}|.
$$

Unavailable values remain `NaN`.  The reported finite-component sum is

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}
=\delta_h+\delta_g+\delta_N+\delta_\vartheta+\delta_Q+\delta_{\mathrm{tol}}
$$

only when all six components exist; otherwise the sum over finite terms is reported beside the
explicit `EMPIRICAL_RESOLUTION_PARTIAL` inventory and may not conceal missing axes.  Also report
the $Q=4\to6$ and $Q=6\to8$ stiffness/operator changes, geometry radial-trace defect, determinant
minimum and branch field overlaps.  Drift contraction and quadrature flattening are observations,
not acceptance thresholds or error bounds.

Neither $\delta_g$ nor $\delta_Q$ certifies the exact-circle error; the polynomial curved edge is
still approximate.  No extrapolation is promoted to an uncertainty bound.

## 11. Information isolation and late BIE distance

Active MATLAB may consume only literal physical/scientific constants in its own source and caches
created below the current execution directory.  It must not read Markdown, Git, `femref-a1`,
`femref-a2`, any historical output, BIE/QZ values or fields, densities, the I3 estimator or a prior
reference.  It must not discover a repository root or depend on an absolute repository path.  A
copied I4.1b source file is only an implementation starting point; all historical-input paths and
straight-field formulas must be absent from the active call graph.

The search windows, configurations, rank and branch rules above are frozen before the later value

$$
k_{\mathrm{BIE+DtN}}=1.832770289108157
$$

is used.  Only after the canonical curved-P2 scalar and field artifact have been atomically
committed may the Skeptic, in a read-only review-side calculation, report

$$
d_{\mathrm{BIE}}
=\left|k_{\mathrm{ref}}^{\mathrm{curved},P_2}
-1.832770289108157\right|.
$$

This number is an absolute positional distance between two independent computations.  It cannot
select another FEM component, trigger a rerun, alter an axis or be called estimator effectivity or
certified error.

## 12. Actual preflight, resources and implementation boundary

The zero-guided-eigensolve preflight builds and validates six actual assembly/validation
representations on five distinct topologies:

```text
bulk-s9-g24-Q8
defect-N4-s9-g24-Q6
defect-N4-s9-g24-Q8
defect-N4-s12-g24-Q8
defect-N4-s9-g32-Q8
defect-N5-s9-g24-Q8
```

The two anchor quadratures reuse one mesh, so this is five distinct topologies and six
assembly/validation rows.  For each it records mesh/topology counts, interface/radius/trace defects,
global determinant minimum, Duffy monomial defects, curved P1-in-P2 defects, full/reduced operator
`nnz`, phase/seam defects, SPD permutation/factor `nnz`, inverse-map round-trip defects and reached
RSS markers.  It calls no guided `eigs`, spectrum selector, branch tracker or reference publisher
and performs no capacity simulation.

The authoritative preflight leaves are exactly `representation.tsv`, concise `run.log`, append-only
`resource.tsv` and atomic summary-last `preflight-summary.tsv`.  A successful preflight establishes
representation feasibility only; formal launch still requires Researcher theory-to-code and
same-Skeptic exact spec/resource review.

Because the curved method preserves the accepted topology and sparsity pattern, the largest
planned reduced dimension remains about $7232$.  The completed straight-sided 61-call result used
$232.450046$ s and peak aggregate RSS $1055391744$ B.  The new 71/76 calls retain the same maximum
Arnoldi dimension; $Q=8$ raises assembly work to 64 reference points per element but does not retain
64 copies of a matrix or field.  Streaming one mesh/pair at a time, clearing the SPD factor and
retaining only selected fields gives the prospective planning range

$$
T_{\mathrm{formal}}\approx600\text{--}1200\ \mathrm{s},
\qquad
R_{\mathrm{peak}}\approx1.1\text{--}1.6\ \mathrm{GiB}.
$$

The actual-only preflight is expected below $300$ s and $1.3$ GiB.  These estimates are
`PROVISIONAL`, do not create a launch gate and do not justify a lower controller threshold.  Only
an objective measured lower bound proving that even the preliminary five-slice anchor cannot fit
the remaining lifecycle or 3 GiB may produce `RESOURCE_IMPOSSIBILITY` before launch.

After same-Skeptic design approval, the Engineer may create only `test/i4/femref-a3/`, beginning
from copied I4.1b code if useful.  The minimal active files are one substantial MATLAB function,
one no-argument preflight controller, one no-argument formal controller, `README.md` and
`SYMBOLS.md`.  The implementation must contain the mathematical validation above, minimal
create-once publication, concise logging and hard-resource control; no broad audit ledger, mirror,
checkpoint framework, hash gate or capacity model is part of the runtime.

## 13. Artifacts, terminals and failure semantics

### 13.1 Formal artifacts

The formal execution may publish only:

- immutable `preliminary-result.mat` and `preliminary-fields.mat` immediately after the valid
  $Q=6$ preliminary winner;
- immutable `final-result.mat` and `final-fields.mat` after the $Q=8$ winner is frozen;
- optional `refinement-result.mat` and `refinement-fields.mat` containing matched axes and bulk
  diagnostics without mirroring the preliminary/final authorities;
- concise append-only `run.log`;
- append-only controller `resource.tsv`;
- atomic summary-last `run-summary.csv`; and
- a minimal current-run `work/terminal.tsv` plus current-run caches.

All MAT artifacts contain the exact source specification, mesh/geometry/quadrature validation,
spectrum authority, complete selected subspaces, nonlinear common-grid samples, assignment/rank,
scalar and claim boundary needed for review.  A `.partial` file is non-authoritative failure debris.

### 13.2 Valid terminals

Successful scientific labels are:

- `CURVED_P2_PRELIMINARY_EMPIRICAL_REFERENCE` after stage-one publication;
- `CURVED_P2_EMPIRICAL_REFERENCE_REFINEMENT_PARTIAL` when a final winner exists but one or more
  axes are missing; and
- `CURVED_P2_EMPIRICAL_REFERENCE_REFINEMENT_COMPLETE` when all six axes exist.

Every label appends `NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY`.

The only reasons for completing the lifecycle without any reference are:

1. the curved mapping or weak discretization is mathematically inconsistent and cannot be repaired
   locally without changing the method;
2. every usable preliminary mesh/phase pair has illegal topology, nonpositive $\det J$, nonfinite
   or non-Hermitian forms, or non-SPD mass;
3. every usable preliminary eigensolve fails convergence, finite positive spectrum, residual,
   orthogonality or field reconstruction;
4. no three-consecutive-twist field component exists after the frozen 60-root extension;
5. the actual command reaches its hard wall, lifecycle epoch or 3 GiB process-tree RSS predicate
   before preliminary publication; or
6. the create-once preliminary authority cannot be written atomically.

A single operational failure, a failed refinement mesh, incomplete bulk/gap evidence, weak
localization, parity ambiguity, lack of drift contraction, quadrature non-flattening or a partial
uncertainty ladder is not a no-reference condition.  Preserve the raw failure and continue the
fixed legal suffix when time permits.  If a hard stop occurs after preliminary publication, the
controller reports the hard terminal while retaining the immutable preliminary evidence for
Skeptic review.

## 14. Researcher--Engineer--Skeptic gates

1. The same Skeptic reviews this design.  Only a mathematical, implementation-correctness,
   objective-resource or publication blocker can return `REVISE` or `BLOCKED`.
2. After design PASS, the Engineer implements only `femref-a3`.  The same Researcher checks the
   exact theory-to-code map: global interface midpoint ownership, $F_T/J_T/\det J_T$, determinant
   minimization, Duffy rules, curved P1 embedding, phase reduction, nonlinear inverse map,
   schedule, branch rank, artifacts and isolation.
3. The same Skeptic performs exact spec-to-code and resource review.  A preflight may run only
   after that review has no blocker.  Its artifacts receive an immediate post-preflight review.
4. Formal science requires a refreshed theory/spec-to-code review after any preflight repair.
   Only then may the no-argument formal controller create the exact run identity.
5. The same Skeptic appends every execution, repair and resource fact to
   `review-4-1c.md`, then completes the post-run numerical, artifact and claim-boundary verdict.
   Only that verdict can authorize minimal project-status synchronization.

No gate authorizes a BIE-guided rerun, estimator read, effectivity comparison, modification of
I1--I3/package/main code, or modification of `femref-a1`/`femref-a2`.

## 15. Theory-to-code map and Researcher decision

| Frozen mathematical object | Future implementation responsibility | Required review evidence |
|---|---|---|
| exact circles and constrained vertex mesh | curved geometry builder | endpoint/midpoint radius, interface-edge incidence and material-side checks |
| shared six-node topology | global edge owner | one midpoint DOF per edge and identical adjacent traces |
| $F_T,J_T,d_T$ | isoparametric evaluator | nodal map, determinant coefficients/global minimum and finite inverse |
| Duffy $Q=4,6,8$ | quadrature generator/validator | one-dimensional and triangle monomial defects, physical low-monomial ladder |
| $a_T,m_T$ | curved assembler | variable-$J$ formulas, finite/raw-Hermitian forms, SPD evidence |
| reference-linear subspace | independent curved P1 assembler | local/global $E^*K_2E$, $E^*M_2E$ and phase commutation |
| periodic space | vertex/midpoint prolongation | seam, unit phases and corner consistency |
| $(\lambda,U)$ | generalized eigensolver | flags, roots, residual, orthogonality and whole clusters |
| $F_T^{-1}$ and $U(x)$ | nonlinear sampler | round-trip probes, deterministic ownership and six-function fields |
| branch/rank | current-run P2 tracker | complete objects, field overlaps, localization/parity and total FEM-only rank |
| preliminary/final scalar | create-once publisher | selected object IDs, envelope, fields and immutable claim boundary |
| six empirical axes | refinement collector | raw matched scalars, missing-value inventory and non-certified sum |
| hard resources | external controller | actual deadline, aggregate tree RSS, kill and summary-last evidence |

The strongest falsification test is a curved interface element whose coefficient-derived determinant
minimum is nonpositive even though sampled quadrature determinants are positive.  Section 4.3 must
reject it.  A second decisive test maps fixed reference probes forward and requires the nonlinear
inverse to recover them; an affine/P1 sampler must fail this fixture.  A third compares $Q=4,6,8$
on the same curved map, separating exact mass-polynomial behavior from rational-stiffness
quadrature drift.

The weakest remaining step is empirical global geometry accuracy: polynomial quadratic arcs are
not exact circles, and observed $g/Q/h$ changes do not bound their common bias.  This is an
`IMPORTANT CAVEAT`, not a blocker to the explicitly preliminary empirical target.

**Researcher decision: `GO TO THE SAME SKEPTIC FOR I4.1c DESIGN REVIEW`.**  The accepted P2
topology/resource evidence and the new preliminary-first schedule do not presently prove a
resource impossibility.  Implementation, preflight, formal MATLAB, output creation, BIE distance
calculation and project-status synchronization remain blocked until their respective gates pass.

## 16. Append-only Researcher theory-to-code gate

### 16.1 Initial implementation audit -- 2026-09-01T12:31:09Z

Scope: static inspection of the first Engineer implementation in `test/i4/femref-a3/`; no MATLAB,
controller or numerical execution was performed.

The global interface midpoint owner, curved $F_T/J_T/\det J_T$ assembly, exhaustive quadratic
determinant candidate set, Duffy $Q=4,6,8$ convention, same-map $P_1\subset P_2$ assembly, vertex
and midpoint phases, nonlinear common-grid locator, 71/76 call schedule, FEM-only branch rank,
create-once identities, information isolation and exact wall/RSS controller predicates are
statically traceable to Sections 2--15.  This part is `ESTABLISHED BY SOURCE INSPECTION`, not by
execution.

Initial verdict: **`REVISE / NO EXECUTION`**.  Four bounded implementation mismatches remain:

1. the source uses a $10^{-12}$ curved-embedding tolerance instead of the frozen $10^{-11}$;
2. its quadrature component computes
   $\max\{|k_{Q8}-k_{Q4}|,|k_{Q6}-k_{Q8}|\}$ instead of the frozen
   $\max\{|k_{Q6}-k_{Q4}|,|k_{Q8}-k_{Q6}|\}$;
3. the curved-versus-affine fixture tests a point on the curved trace but not fixed points on both
   sides of the interface, including the region between the chord and quadratic trace; and
4. the preflight table and preliminary canonical result do not yet preserve enough of the already
   computed quadrature, curved embedding, mapping, geometry, phase and field-map validation values
   for the required independent artifact review.

These are local implementation/publication-contract issues.  They do not change the continuous
model, weak form, curved-$P_2$ method, schedule, selection or claim boundary.  The same Engineer may
repair them in place; the Researcher must re-audit the exact lines and the same Skeptic must perform
spec-to-code review before `resource-preflight-001/execution-001` is allowed.

### 16.2 Focused implementation re-audit -- 2026-09-01T12:35:17Z

The same Engineer repaired the four Section 16.1 items without changing the mathematical method:

1. the source now uses the frozen $10^{-11}$ local/global embedding tolerance;
2. the dedicated quadrature helper now computes exactly
   $\max\{|k_{Q6}-k_{Q4}|,|k_{Q8}-k_{Q6}|\}$;
3. the nonlinear locator fixture now tests a fixed interface point, a point between its chord and
   quadratic trace, and a point on the opposite side; it requires positive recovered Jacobians,
   opposite material owners, deterministic shared-trace ownership, small forward residual and an
   explicit failure of affine-triangle membership for the between-chord-and-trace point; and
4. the concise preflight row now preserves Duffy, local/global/reduced embedding, phase
   commutation, seam, geometry, determinant and inverse-map defects, while preliminary/final
   result payloads preserve the corresponding mesh-validation structures.

The focused source re-audit also reconfirmed the six-row/five-topology preflight, full retained-grid
coverage counts, $Q=6$ preliminary-first publication, independent $Q=8$ winner, exact 71/76 solve
accounting, FEM-only assignment/rank, current-run-only inputs and the exact 2700 s/lifecycle/3 GiB
controller predicates.  Perl controller syntax and `git diff --check` pass.  MATLAB semantics and
all numerical tolerances remain `UNVERIFIED BY EXECUTION`.

Researcher theory-to-code verdict: **`PASS / GO TO SAME-SKEPTIC SPEC-TO-CODE REVIEW / NO MATLAB
YET`**.  If that independent review has no blocker, the exact next executable is only
`resource-preflight-001/execution-001`; formal `run-001/execution-001` remains blocked pending the
post-preflight review and refreshed theory/spec-to-code gate.

### 16.3 Preflight `execution-001` operational failure -- 2026-09-01T12:38:02Z

After the same Skeptic authorized the representation preflight, the create-once leaf
`resource-preflight-001/execution-001` terminated at the controller's resource-enforcement layer:

- controller terminal: `RSS_ENFORCEMENT_UNAVAILABLE`;
- immediate cause: sandboxed `/bin/ps` process-tree measurement was unavailable;
- whole-command wall time: $0.001963$ s;
- observed aggregate peak RSS: $0$ B;
- MATLAB signal: $9$ before MATLAB startup; and
- scientific terminal: `UNAVAILABLE`.

No mesh, assembly, validation or eigensolve began.  This is `ESTABLISHED OPERATIONAL FAILURE`, not
evidence about the curved-$P_2$ representation or its resource use.  The leaf, summary and resource
ledger are immutable and consumed.

The bounded repair authority is only to make process-tree RSS measurement work in the current
sandbox while retaining the same inclusive 3 GiB predicate, 2700 s/lifecycle wall predicates,
process-tree scope and create-once publication semantics.  It may not introduce another resource
limit, forecast, stall, guard or scientific change.  The sole prospective retry identity is
`resource-preflight-001/execution-002`; `execution-001` must not be overwritten.  The Engineer may
patch only the controller/core identity allowlist needed for that leaf, after which the Researcher
and same Skeptic must re-review the focused diff before execution.  Formal
`run-001/execution-001` remains blocked.

### 16.4 Focused operational-repair review -- 2026-09-01T12:38:37Z

The repaired preflight controller and core allowlist now admit exactly
`resource-preflight-001/execution-002`; the formal identity remains exactly
`run-001/execution-001`.  The consumed `execution-001` directory remains present and is not an
allowed active identity.  No scientific constant, curved-map formula, validation, solve schedule,
rank, artifact schema or claim boundary changed.  Both controllers retain the same lifecycle
epoch, 2700 s command wall cap, inclusive 3 GiB aggregate process-tree RSS predicate and
create-once output claim.  Perl syntax and `git diff --check` pass.

The focused environment probe confirms that `/bin/ps` remains unavailable inside the restricted
sandbox.  Therefore `execution-002` must be launched only in the approved host execution context
where the unchanged process-tree measurement is permitted; launching it in the same restricted
sandbox would knowingly repeat the operational failure and is not authorized.  This execution-
context requirement enables the declared 3 GiB measurement and is not a lower scientific/resource
gate.

Researcher focused verdict: **`PASS WITH EXECUTION-CONTEXT CONDITION / GO TO SAME-SKEPTIC REVIEW /
NO MATLAB YET`**.  If the same Skeptic confirms this identity and environment repair, only
`resource-preflight-001/execution-002` may run.  Formal `run-001/execution-001` remains blocked
until the successful preflight artifact review and refreshed formal theory/spec-to-code gate.

### 16.5 Preflight `execution-002` representation result -- 2026-09-01T12:42:41Z

The host-observed create-once leaf `resource-preflight-001/execution-002` ran MATLAB and consumed
75.731769 s with measured aggregate process-tree peak RSS 914505728 B.  The bulk
`bulk-s9-g24-Q8` representation passed mesh, topology, curved assembly, phase reduction, Hermitian,
SPD and publication checks.  Its recorded determinant minimum was
$5.5471598555610212\times10^{-4}$, radial trace defect
$1.3723246503338782\times10^{-6}$, Duffy defects below
$7.8\times10^{-15}$, local/global curved embedding defects below
$1.2\times10^{-15}$ and seam residual zero.

The next row, `p2-anchor-Q6`, completed mesh topology and curved assembly but stopped during
`FIELD_MAP_BEGIN` with
`CURVED_FIELD_RECONSTRUCTION_INVALID: The deterministic two-sided curved-interface fixture
failed.`  No guided eigensolve ran.  The controller terminal was `PREFLIGHT_OUTPUT_INCOMPLETE`
because the six-row preflight did not reach its complete terminal.  The consumed leaf and all raw
artifacts remain immutable.

This localizes a contradiction inside the new implementation fixture, not the nonlinear-location
method or mathematical representation: the same anchor had already reached a finite assembled
curved mesh, while the failure message did not preserve which fixture predicate failed or its raw
owners, material labels, barycentric minima and residuals.  The bounded repair may only (i) make
the fixed two-sided fixture consistent with its stated geometry/material orientation and
deterministic trace rule, and (ii) append the raw fixture values before any fixture failure.  It may
not alter $F_T$, the locator/inverse algorithm, common grid, continuous model, weak form, mesh,
quadrature, phases, schedule, rank, resource limits or claim boundary.

The only prospective retry is `resource-preflight-001/execution-003`; the core/controller identity
allowlist may change only to that create-once leaf.  The same Researcher and Skeptic must review the
focused diff before execution.  Formal `run-001/execution-001` remains blocked.

### 16.6 Focused fixture-repair review -- 2026-09-01T12:43:54Z

Source inspection identifies the `execution-002` failure as a fixture contradiction: the fixture
required the trace owner to equal the minimum incident triangle ID, whereas the frozen locator first
maximizes the minimum recovered barycentric coordinate and uses triangle ID only for an exact tie.
The locator and inverse map were unchanged.

The repaired fixture now requires the trace owner to be one of the two incident elements and
repeats the identical trace query to require the same owner and barycentric coordinates.  It retains
the independent between-chord-and-trace material-inside condition, the opposite-side
material-outside condition, shared-trace count, positive determinant, forward recovery and affine-
membership counterexample.  Before any failure it appends `CURVED_FIXTURE_RAW` with owners,
material labels, incident elements, barycentric minima, shared count, inverse residual and repeated-
query values.  This is the smallest diagnostic needed to falsify the repaired fixture; it does not
alter field samples or branch selection.

The active preflight identity is now exactly `resource-preflight-001/execution-003`; prior leaves
remain present and formal remains `run-001/execution-001`.  Controller hard predicates and all
scientific code outside the fixture/log-call plumbing are unchanged.  Perl syntax and
`git diff --check` pass; MATLAB remains unrun after the patch.

Researcher verdict: **`PASS / GO TO SAME-SKEPTIC FOCUSED REVIEW / PREFLIGHT execution-003 ONLY`**.
If the same Skeptic finds no blocker, `resource-preflight-001/execution-003` may run in the approved
host process-observation context.  Formal science remains blocked pending a complete preflight and
its artifact review.

### 16.7 Successful preflight and refreshed formal gate -- 2026-09-01T12:51:29Z

The create-once `resource-preflight-001/execution-003` completed naturally with scientific terminal
`PREFLIGHT_COMPLETE`.  All six prescribed assembly/validation rows on five topologies passed.  The
whole command used 310.361142 s and measured aggregate process-tree peak RSS 978026496 B.

The observed representation envelope was:

- largest full/reduced P2 dimension: $7473/7232$;
- largest stiffness/mass `nnz`: 83168 each;
- largest fill-reduced Cholesky factor `nnz`: 230867;
- global minimum observed curved Jacobian determinant:
  $3.7306130112806373\times10^{-4}>0$;
- maximum nonlinear inverse-map residual:
  $1.736147931666065\times10^{-12}<5\times10^{-12}$;
- maximum Duffy interval/triangle monomial defect: below $7.8\times10^{-15}$;
- maximum local/global curved embedding defect: below $1.5\times10^{-15}$;
- maximum seam residual: $1.2412670766236366\times10^{-16}$; and
- uncovered and multiply-interior common-grid counts: zero on every defect row.

The raw two-sided fixtures also exhibit the intended owners on opposite material sides, one shared
trace, repeatable trace ownership and between-chord-and-trace barycentric evidence.  These data
establish numerical representation feasibility for the tested meshes; they do not validate an
eigenpair or certify exact geometry.

The measured preflight leaves 2243198976 B of headroom below the 3 GiB hard predicate.  Its largest
mesh/factor and field-locator stages were exercised.  The formal eigensolver, simultaneous selected
fields and complete 71/76 schedule remain unmeasured, so this headroom is empirical resource
evidence, not an upper bound.  At this audit epoch about 13809 s remained before
$T_{\mathrm{end}}$, while the immutable formal command cap remains 2700 s.  There is no measured
resource lower bound or mathematical evidence that the preliminary five-slice anchor cannot fit.

The refreshed formal source audit reconfirms:

1. only `run-001/execution-001` is admitted and its create-once directory does not yet exist;
2. $Q=6$ five-twist fields are solved, FEM-ranked and published before any $Q=8$ or refinement
   object can affect them;
3. the $Q=8$ winner is independently ranked, with preliminary/final overlap reported rather than
   used to replace that winner;
4. the call count is 71, or 76 only under the single frozen preliminary coverage extension;
5. Cholesky factors are cleared immediately, generalized residuals and mass orthogonality are
   checked, whole clusters and six-function nonlinear field samples feed the FEM-only rank;
6. the adjacent-$Q$ uncertainty formula, six empirical axes and partial-result downgrade match
   Section 10;
7. preliminary/final/refinement result and field leaves are create-once, and a valid preliminary
   authority survives a later stage failure; and
8. no active source reads historical FEM output, Markdown, Git, BIE/QZ, density or estimator data.

Researcher post-preflight verdict: **`PASS / GO TO SAME-SKEPTIC FORMAL SPEC-TO-CODE AND RESOURCE
GATE / NO FORMAL RUN YET`**.  If that independent gate has no blocker, the sole next scientific
execution is `run-001/execution-001` in the same approved host process-observation context.  No
BIE-distance calculation, result promotion or effectivity comparison is authorized before its
post-run review.

### 16.8 Read-only post-run inspector gate -- 2026-09-01T13:06:40Z

The formal create-once run subsequently completed `run-001/execution-001` with 71/71 solves and
published the preliminary, final and refinement result/field pairs plus summary, resource and work
terminal leaves.  Before interpreting their internal branch and field records, the Engineer added
a read-only inspector and monitored create-once controller with prospective identity
`artifact-review-001/execution-001`.

Static theory-to-inspector inspection establishes that this helper:

- reads only the six current `run-001/execution-001` MAT leaves and their current summary,
  resource and terminal text;
- never calls the FEM core, `eigs`, a publisher, `save`, `movefile` or a scientific-output writer;
- checks text/scalar consistency and $\lambda=k^2$ without replacing any frozen value;
- prints selected object IDs, rank, classification, root/phase/dimension, residual, localization,
  parity, coverage and current tracking overlap directly from the result/field authorities;
- prints the stored geometry, quadrature, curved-embedding, determinant and nonlinear-field
  validation structures;
- prints the frozen axis scalars and observed deltas, and recomputes common-grid overlap only from
  the stored matched-axis and final field samples using the same weighted principal-subspace
  formula; and
- contains no BIE/QZ value, estimator, density, historical-output, Markdown or Git input.

The inspector's only writes are its controller-owned create-once review log, resource ledger and
summary-last leaf.  The controller retains the lifecycle/2700 s/3 GiB process-tree predicates.
The nearest-final-phase overlap printed for the four added twist points is a labeled branch-
continuation diagnostic, not a new root match, rank or result mutation.  Any missing duplicated
field-leaf metadata is reported as a schema caveat and cannot erase the companion result authority.

Researcher inspector verdict: **`PASS / GO TO SAME-SKEPTIC INSPECTOR REVIEW /
artifact-review-001/execution-001 ONLY`**.  If independently approved, this read-only extraction may
run in the host process-observation context.  It cannot authorize a rerun, alter the winner, compute
the late BIE distance, promote a result or perform effectivity.

### 16.9 Final Researcher post-run assessment -- 2026-09-01T13:16:37Z

The read-only `artifact-review-001/execution-001` completed naturally in 13.887655 s with peak
aggregate RSS 919322624 B and terminal `PASS_WITH_SCHEMA_CAVEATS`.  It cross-checked the formal
summary, work terminal and final resource row, then mapped the immutable result and field pairs
without changing them.

#### 16.9.1 Empirical reference and field identity

The independently FEM-ranked final $Q=8$ anchor authority is

$$
\lambda_{\mathrm{ref}}^{\mathrm{curved},P_2}
=3.3593651273559701,
\qquad
k_{\mathrm{ref}}^{\mathrm{curved},P_2}
=1.8328570940899811.
$$

The preliminary $Q=6$ scalar was $1.8328570940899886$; it was frozen before the final anchor and
differs by only $7.55\times10^{-15}$.  Both stages independently selected objects
`[8, 32, 55, 78, 101]`, the scalar root-9 component at all five twists, with one-dimensional field
at every slice.  The final branch has four continuation edges, minimum within-branch overlap
0.99999991179010128, and maximum normalized residual
$1.167537059550097\times10^{-16}$.  Its classification is
`field-tracked / noncertified / no-effectivity`.

Across the branch, $L_{\mathrm{core}}\ge0.96429178406871063$ and the maximum tail diagnostic is
0.0030561968315734531.  Both endpoint twists are empirically even, with parity-invariance defects
about $5.15\times10^{-4}$.  All five 48-root slices cover the frozen $W_3$ window, so no 60-root
extension was used.  The $Q=6$ and $Q=8$ same-phase field overlaps are unity to roundoff; the
reported preliminary-to-final minimum match is 0.99999999999999978.  The field leaves contain
finite nonempty subspaces and common-grid samples on 1300 vertices, 2418 triangles, 3717 edges and
5017 full P2 DOFs (4836 reduced DOFs in the preflight row).

#### 16.9.2 Refinement and empirical uncertainty

The field-matched scalar ladder is

| Axis | Coarse | Anchor/intermediate | Fine/refined |
|---|---:|---:|---:|
| mesh $s$ | $k_{s6}=1.8329271291562377$ | $k_{s9}=1.8328570940899811$ | $k_{s12}=1.8328176106479204$ |
| interface $g$ | $k_{g16}=1.8328849181855693$ | $k_{g24}=1.8328570940899811$ | $k_{g32}=1.8328473278767723$ |
| supercell $N$ | $k_{N3}=1.8328567990799984$ | $k_{N4}=1.8328570940899811$ | $k_{N5}=1.8328570969854137$ |
| quadrature $Q$ | $k_{Q4}=1.8328570940913185$ | $k_{Q6}=1.8328570940899886$ | $k_{Q8}=1.8328570940899811$ |

The added-twist scalar and loose-tolerance scalar both equal the final scalar at stored precision.
All ten matched-axis field groups are nonempty.  Their minimum reported overlaps with the
same/nearest final twist range from 0.99998210429072887 on $N=3$ to unity to roundoff; hence every
axis tracks the same field-bearing component by the frozen FEM-only rule.

The observed components are

$$
\delta_h=7.0035066256579626\times10^{-5},
\quad
\delta_g=2.7824095588213638\times10^{-5},
\quad
\delta_N=2.9500998266485112\times10^{-7},
$$

$$
\delta_{\vartheta}=0,
\quad
\delta_Q=1.3298251388960125\times10^{-12},
\quad
\delta_{\mathrm{tol}}=0,
$$

and the pre-registered finite-component sum is

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}
=9.8154173157283253\times10^{-5}.
$$

All six components exist, so the artifact status `EMPIRICAL_RESOLUTION_COMPLETE` is correct.  The
mesh component dominates, followed by geometry.  The stiffness change contracts from
$5.8950813762003697\times10^{-9}$ for $Q=4\to6$ to
$1.6511941432603152\times10^{-14}$ for $Q=6\to8$; mass and low-monomial changes are at roundoff.

#### 16.9.3 Mathematical diagnostics, caveats and claim boundary

The final anchor records determinant minimum $5.5471598555598828\times10^{-4}$, determinant-
polynomial defect $7.7889084071358639\times10^{-16}$, radial quadratic-trace defect
$1.3723246506114339\times10^{-6}$, nonlinear inverse residual
$4.0652427628008786\times10^{-13}$, zero uncovered/multiply-interior grid points and passing
two-sided fixture.  Local/global curved $P_1\subset P_2$ defects are below
$1.4\times10^{-15}$.  All 17 bulk diagnostic slices returned finite spectra, but the current
artifact supplies sampled spectrum inventories, not a certified continuous bulk-gap or existence
argument.

The 13 schema caveats are missing duplicated metadata in companion field/refinement leaves:
`spec`, validation, selection, spectrum authority and scalar fields are held by the paired result
leaves, while mesh/subspaces/common-grid samples are held by the field leaves.  Object IDs, selected
counts, scalar/text authority and field finiteness cross-check successfully across those pairs.
Because all canonical files are create-once, these duplication omissions must remain explicit
caveats; they neither change the selected component nor justify overwriting an authority.

The empirical sum and all individual drifts remain non-certified.  Three-point $h$, $g$ and $N$
ladders do not prove asymptoticity; polynomial quadratic arcs do not exactly represent circles; no
interval estimator bounds their common bias; sampled bulk spectra do not prove a continuous gap;
and no theorem-level guided-mode existence claim follows.  The result is therefore an empirical
curved-$P_2$ reference with strong field/refinement persistence, not a certified error bound.

Researcher final verdict: **`PASS WITH SCHEMA AND NONCERTIFICATION CAVEATS / GO TO SAME-SKEPTIC
POST-RUN REVIEW`**.  The frozen FEM winner and its field identity are interpretable.  Only the
Skeptic may now compute the late, non-selective BIE positional distance and issue the final post-run
verdict.  No rerun, estimator effectivity comparison or result promotion is authorized by this
Researcher assessment.
