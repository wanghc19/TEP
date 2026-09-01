# I4.1b quadratic FEM reference experiment design

Status: **`RESEARCHER DESIGN FROZEN / SAME SKEPTIC DESIGN REVIEW REQUIRED / NOT IMPLEMENTED / NOT RUN`**.

This document freezes one bounded $P_2$ extension of the independent fitted-FEM route in
[[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]]. It is governed by the
claim boundary accepted in
[[research/projects/eig-apost/implementation/i4/method-review|method-review]] and uses the
verified $P_1$ evidence in
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]] and
[[research/projects/eig-apost/implementation/i4/review-4-1a|review-4-1a]] only as prospective
planning evidence. No I4.1a source or artifact is modified by this design.

## 1. Question, scope and claim boundary

The question is whether a straight-sided, conforming, six-node quadratic FEM discretization can
produce a current-run, field-bearing empirical candidate for the same periodic-waveguide problem,
with independently resolved $h$, interface segmentation, supercell, twist and algebraic axes, and
whether a later blinded field audit can identify the component corresponding to the already frozen
$P_1$ target.

The run may establish only:

1. a canonical, purely $P_2$ FEM candidate selected without historical or BIE/QZ information;
2. empirical sensitivity components and a non-certified observed resolution quantity;
3. after a separately gated post-run field audit, a $P_1$-target-matched $P_2$ component.

It may not establish a continuous eigenvalue existence theorem, a certified error bound,
$\varepsilon_{\mathrm{ref}}$, or estimator effectivity. Bulk-gap, localization, parity and finite
spectrum-coverage diagnostics restrict interpretation but do not cancel a numerically valid field.

## 2. Continuous problem and unchanged information boundary

The continuous model is unchanged. On

$$
\Omega=\mathbb R\times\left(-\frac12,\frac12\right),
$$

the period is $1$, the circular material interfaces have exact radius $0.2$, the column at $x=0$
is missing, $q=17$ inside the remaining disks and $q=1$ outside, and

$$
u(x,y+1)=e^{\mathrm i\beta}u(x,y),\qquad \beta=0.5.
$$

The eigenproblem and normalization remain

$$
\int_{\Omega_N}\nabla u\cdot\nabla\overline v
=\lambda\int_{\Omega_N}q\,u\overline v,
\qquad \lambda=k^2,
$$

with the same bulk phase and defect-supercell twist conventions as I4.1a. Straight polygonal
interfaces remain an explicit variational crime; changing their segmentation is a separate
empirical axis and is not an exact-circle error bound.

The active MATLAB entry may consume only source-owned constants and objects created under the
current execution. It must not read Markdown, Git metadata, historical output, BIE/QZ data,
density/eigenvectors, the I3 estimator, or any prior reference result. The old $P_1$ target is not
available to the formal selector. No frequency from I4.1a or BIE may be used to choose a mesh,
shift, root, component or tie-break.

## 3. Exact straight-sided $P_2$ finite element

### 3.1 Local space, nodes and global degrees of freedom

Each physical triangle is affine and straight sided. For barycentric coordinates
$(\ell_1,\ell_2,\ell_3)$, the local node order is vertices $(1,2,3)$ followed by edge midpoints
$(12,23,31)$, and the basis is

$$
\begin{aligned}
\phi_1&=\ell_1(2\ell_1-1),&
\phi_2&=\ell_2(2\ell_2-1),&
\phi_3&=\ell_3(2\ell_3-1),\\
\phi_4&=4\ell_1\ell_2,&
\phi_5&=4\ell_2\ell_3,&
\phi_6&=4\ell_3\ell_1.
\end{aligned}
$$

Every sorted global vertex pair defining an active mesh edge owns exactly one global midpoint DOF.
Adjacent elements therefore share the same midpoint ID; no element-local duplicate midpoint may
survive assembly. The six-node connectivity is

$$
(v_1,v_2,v_3,e_{12},e_{23},e_{31}).
$$

The coefficient $q$ is constant on each fitted triangle, exactly as in I4.1a. The local stiffness
and weighted consistent mass matrices are

$$
(K_T)_{ij}=\int_T\nabla\phi_j\cdot\nabla\phi_i,
\qquad
(M_T)_{ij}=\int_T q_T\phi_j\phi_i.
$$

No mass lumping, curved isoparametric geometry, interface smoothing or post hoc material averaging
is allowed.

### 3.2 Frozen quadrature

One positive seven-point degree-five triangle rule is used for both matrices. Its barycentric points
and weights, normalized so that the weights sum to one and then multiplied by $|T|$, are:

| Orbit | Barycentric coordinates | Weight per point |
|---|---|---:|
| one point | $(1/3,1/3,1/3)$ | $0.225$ |
| three permutations | $(0.059715871789770,0.470142064105115,0.470142064105115)$ | $0.132394152788506$ |
| three permutations | $(0.797426985353087,0.101286507323456,0.101286507323456)$ | $0.125939180544827$ |

Thus the stiffness integrand, of degree at most $2$, and the weighted mass integrand, of degree at
most $4$, are integrated by a rule of degree at least the required $2$ and $4$, respectively.
The same rule is used for the center/core/tail restricted mass forms whenever a triangle belongs
entirely to the corresponding polygonal subdomain; cut diagnostic regions use the separately
frozen common-grid evaluation in Section 7 rather than changing the eigenproblem matrices.

### 3.3 Quasiperiodic reduction for vertices and midpoints

Periodic equivalence classes are constructed for the complete vertex-plus-midpoint DOF set. Vertex
pairs use the unchanged coordinate and phase convention. Each boundary midpoint is paired only with
the midpoint of the boundary edge whose ordered endpoint pair maps to its periodic counterpart.
The trace polynomial on an identified edge is consequently matched at both vertices and its
midpoint. The $x$ phase is $e^{\mathrm i\alpha}$ for a bulk cell and
$e^{\mathrm i\vartheta}$ for a defect supercell; the $y$ phase is $e^{\mathrm i\beta}$.
Corner vertices satisfy the unique product factor
$e^{\mathrm i(\alpha+\beta)}$ or $e^{\mathrm i(\vartheta+\beta)}$ independent of the order of
identification. Every full P2 DOF row has exactly one unit-modulus prolongation entry, every reduced
column has support, and the $x$-then-$y$ and $y$-then-$x$ corner maps must agree.

## 4. Mandatory element and operator validation

These checks protect the discrete mathematical object; they are not a second audit framework.

### 4.1 Checks before a spectrum can be attempted

1. **Nodal interpolation.** Evaluation of the six basis functions at the six local nodes must equal
   the $6\times6$ identity to relative/absolute tolerance $5\times10^{-14}$.
2. **Partition of unity.** At all quadrature nodes and the six interpolation nodes,
   $|\sum_i\phi_i-1|\le5\times10^{-14}$ and
   $\|\sum_i\nabla\phi_i\|\le5\times10^{-13}/h_T$.
3. **Quadrature monomials.** For every $a,b,c\ge0$ with $a+b+c\le5$, the reference-rule result for
   $\ell_1^a\ell_2^b\ell_3^c$ must agree within $2\times10^{-13}$ relative/absolute with

   $$
   \int_T\ell_1^a\ell_2^b\ell_3^c
   =2|T|\frac{a!b!c!}{(a+b+c+2)!}.
   $$

4. **Shared-edge conformity.** Every active edge has one midpoint ID, its incidence is one on the
   outer boundary and two in the interior, and paired periodic edges map vertex and midpoint DOFs
   bijectively with the frozen phase factors.
5. **P1 embedding.** With

   $$
   E_T=
   \begin{pmatrix}
   1&0&0\\0&1&0\\0&0&1\\
   1/2&1/2&0\\0&1/2&1/2\\1/2&0&1/2
   \end{pmatrix},
   $$

   the independently assembled analytic P1 element forms must satisfy
   $E_T^*K_T^{(2)}E_T=K_T^{(1)}$ and
   $E_T^*M_T^{(2)}E_T=M_T^{(1)}$ to $10^{-12}$ relative Frobenius tolerance. The same identity is
   checked after global phase reduction on one coarse and one anchor mesh/twist. This is a bilinear
   consistency check, not a mode-identity test.
6. **Matrix validity.** Before roundoff-only Hermitian canonicalization, the relative Hermitian
   defect of each assembled/reduced stiffness and mass is at most $5\times10^{-13}$; all entries are
   finite, the mass diagonal is positive, and a two-output Cholesky factorization succeeds. The
   vertex and midpoint seam residual is at most $10^{-12}$.

A failure in items 1--6 is `DISCRETE_IMPLEMENTATION_INVALID`, `MESH_INVALID`,
`QUASIPERIODIC_MAP_INVALID`, `MATRIX_NONFINITE`, `MATRIX_NON_HERMITIAN` or `MASS_NOT_SPD` as
appropriate. It is an implementation/discrete-object blocker and cannot be repaired by changing a
scientific threshold.

### 4.2 Checks attached to returned spectra

Every accepted slice must have a zero eigensolver flag, the requested number of finite positive
ordered roots, normalized residual at most $10^{-9}$, mass-orthogonality defect at most $10^{-7}$,
and preserved cluster multiplicity under the $10^{-6}$ frequency clustering tolerance. Failure
invalidates that slice but does not cancel valid slices on other legal configurations.

For every current-run same-geometry companion P1/P2 pair, the first common ordered roots must obey
the Rayleigh--Ritz check

$$
\lambda_j^{(2)}-\lambda_j^{(1)}
\le 20\bigl(r_j^{(1)}+r_j^{(2)}\bigr)
+500\epsilon_{\mathrm{mach}}
\max\{1,|\lambda_j^{(1)}|,|\lambda_j^{(2)}|\}.
$$

This checks the nested-space implementation of the same polygonal geometry. It is not a
field-identity or root-matching rule and may not be used to identify the old P1 target. A violation
is an implementation/numerical blocker; satisfying it is not evidence that index-$j$ P1 and P2
vectors represent the same guided branch.

## 5. Mesh axes and exact solve schedule

### 5.1 P1 evidence and the selected P2 range

The accepted I4.1a mesh ledger gives the following actual P1 values. For a conforming triangulation
with $V$ vertices, $T$ triangles and $B$ outer-boundary edges, the number of full P2 DOFs is
$V+(3T+B)/2$. Pairing periodic boundary midpoints adds $B/2$ reductions, so on these meshes

$$
n_{2,\mathrm{red}}=n_{1,\mathrm{red}}+\frac{3T}{2}.
$$

| Existing $N=5$ P1 mesh | P1 reduced DOFs | Triangles | Same-mesh P2 reduced DOFs |
|---|---:|---:|---:|
| $s=12,g=24$ | 2,224 | 4,448 | 8,896 |
| $s=18,g=36$ | 4,564 | 9,128 | 18,256 |
| $s=24,g=48$ | 7,496 | 14,992 | 29,984 |

The new experiment therefore does not start from the P1 $s=30$ mesh. Its three-level P2 $h$ ladder
is

$$
H_0=(N,s,g)=(5,12,36),\quad
H_1=(5,15,36),\quad
H_2=(5,18,36).
$$

Its independent straight-circle segmentation ladder at fixed $N=5,s=18$ is

$$
G_0=(5,18,24),\quad G_1=(5,18,36),\quad G_2=(5,18,48).
$$

The publication anchor is $A=G_2=(5,18,48)$. The supercell comparison is
$N=4\to5$ on the same $s=18,g=48$ geometry. These choices keep the maximum planned P2 dimension
between the actual same-mesh planning values $18{,}256$ and $29{,}984$ rather than beginning at the
$s=30$ P1 layer. Actual dimensions are recorded, not used as an additional stop threshold.

### 5.2 Windows, phases, root counts and calls

The search windows remain independent of BIE/QZ:

$$
W_0=[1.65,2.05],\quad W_1=[1.25,2.45],\quad
W_2=[0.85,2.85],\quad W_3=[0.45,3.25].
$$

Bulk P2 calls are:

| Mesh | Phases | Roots | Calls |
|---|---|---:|---:|
| $s=12,g=36$ | $\alpha_{17}=\operatorname{linspace}(0,\pi,17)$ | 40 | 17 |
| $s=18,g=36$ | $\alpha_{17}$ | 40 | 17 |
| $s=18,g=48$ | $\alpha_{33}=\operatorname{linspace}(0,\pi,33)$ | 40 | 33 |
| $s=18,g=48$ | $0,\pi/4,\pi/2,3\pi/4,\pi$ | 48 count check | 5 |

Thus the bulk total is $72$ calls. The five count checks must reproduce the first 40 roots within
$10^{-8}$ in frequency while preserving clusters. Bulk-gap and edge-buffer outcomes are diagnostic
classifications only.

Defect P2 calls are:

| Configuration | Mesh | Twists | Tolerance | Roots | Calls |
|---|---|---|---:|---:|---:|
| `p2-h0` | $H_0$ | $\Theta_5$ | $10^{-11}$ | 48 | 5 |
| `p2-h1` | $H_1$ | $\Theta_5$ | $10^{-11}$ | 48 | 5 |
| `p2-h2-g1` | $H_2=G_1$ | $\Theta_5$ | $10^{-11}$ | 48 | 5 |
| `p2-g0` | $G_0$ | $\Theta_5$ | $10^{-11}$ | 48 | 5 |
| `p2-anchor` | $A=G_2$ | $\Theta_{17}$ | $10^{-11}$ | 48 | 17 |
| `p2-n4` | $(4,18,48)$ | $\Theta_5$ | $10^{-11}$ | 48 | 5 |
| `p2-loose` | $A$ | $\Theta_5$ | $10^{-8}$ | 48 | 5 |

Here $\Theta_m=\operatorname{linspace}(0,\pi,m)$. The defect P2 total is $47$ calls. Five additional
current-run companion P1 calls use $A$, $\Theta_5$, tolerance $10^{-11}$ and 48 roots. They serve
only the nested-space Ritz check and the separately reported P1--P2 field/order drift; they do not
enter the pure-P2 canonical rank.

The base total is therefore

$$
72+47+5=124\ \text{eigensolver calls}.
$$

For every anchor twist, let $k_{48}^{(r)}$ be the largest valid returned frequency. If any anchor
slice fails $k_{48}^{(r)}>3.25+0.10$, all 17 anchor twists are recomputed once with 60 roots and the
same tight tolerance. This is the sole conditional coverage rung, so the hard schedule cap is
$124+17=141$ calls. If 60 roots still do not cover $W_3$, record
`SPECTRUM_COVERAGE_PARTIAL`; existing valid fields remain rankable. There is no further window,
root count, shift or adaptive root search.

## 6. Candidate inventory, continuation and canonical P2 selection

Every positive, finite, residual-valid, field-bearing whole cluster intersecting $W_3$ enters the
inventory, including a cluster straddling a window edge. Singletons, births, deaths, dimension
changes, low overlaps and missing refinement components are retained with caveats.

On the same mesh, adjacent-twist subspaces use the exact P2 mass form. Across meshes, each P2 field
is evaluated by the quadratic rule in Section 7 and principal overlaps are computed after weighted
Gram normalization. Every adjacent pair uses a maximum-total-overlap one-to-one assignment. Exact
ties are broken by smaller frequency-envelope distance, target root index, source object ID and
target object ID. These frequency quantities are tie-breaks only, never acceptance gates.

Each connected component, including an untracked singleton, receives a permanent candidate ID and
the following ascending lexicographic key:

1. negative counts of represented P2 axes, linked configurations and linked twists;
2. missing count and finite-part sum of the five P2-internal changes in Section 8;
3. maximum normalized residual;
4. $(-\min L_0,-\min L_{\mathrm{core}},\max T_{\mathrm{tail}})$, with unavailable diagnostics
   projected after finite values;
5. stable parity, ambiguous parity, then unavailable parity;
6. negative covered-window index, covered-slice count and minimum ceiling margin;
7. fixed configuration priority `p2-anchor`, `p2-h2-g1`, `p2-h1`, `p2-h0`, `p2-g0`, `p2-n4`,
   `p2-loose`, followed by twist, root, object and candidate IDs.

The first component is the **canonical P2 winner**. At its highest-priority realization level, the
midpoint of the complete valid twist eigenvalue envelope defines

$$
\lambda_{\mathrm{ref}}^{P_2}
=\frac{\lambda^-+\lambda^+}{2},
\qquad
k_{\mathrm{ref}}^{P_2}=\sqrt{\lambda_{\mathrm{ref}}^{P_2}}.
$$

Multiplicity one yields a mass-normalized vector with global phase fixed by its largest-magnitude
DOF; a multiple cluster publishes the full mass-orthonormal subspace and does not invent a unique
vector. Companion P1 information, old P1 fields and BIE/QZ quantities cannot alter this ranking.

## 7. P2 fields, common grid and mode diagnostics

The common physical grid may use the already frozen $161\times65$ coordinates and positive
$q$-weighted trapezoidal weights, but **not** the P1 interpolation algorithm. On each straight
triangle, a P2 field is evaluated by first computing barycentric coordinates and then applying all
six quadratic basis functions in Section 3.1. Boundary points with multiple containing triangles
use the largest minimum barycentric coordinate and then the smallest triangle ID; continuity must
make the trace independent of this choice. A companion P1 field is evaluated separately with the
three linear barycentric basis functions. P1 samples may never be substituted for P2 samples.

Within- and cross-order Gram matrices use the same positive physical weights. Simple pairs use the
absolute normalized inner product; clusters use all principal singular values and the minimum
principal overlap. The existing $0.90$ simple and $0.80$ cluster values classify strong/weak
continuation but do not delete a valid object.

For every realization, save the complete field/subspace, $L_0$, $L_{\mathrm{core}}$,
$T_{\mathrm{tail}}$, endpoint reflection parity, coverage margin, cluster dimension and all
diagnostic statuses. Localization, parity, bulk-gap, safe-interior, edge-buffer, finite-window
coverage, continuation ambiguity and pre-asymptotic behavior are caveats. They cannot stop spectrum
collection, field publication, ranking or refinement if a valid object exists.

## 8. Empirical resolution and P1--P2 drift

For frequency envelopes $E=[k^-,k^+]$ and $E'=[k'^-,k'^+]$, define

$$
d_\infty(E,E')=\max\{|k^--k'^-|,|k^+-k'^+|\}.
$$

For a tracked P2 component, write $d_{ab}=d_\infty(E_a,E_b)$ and freeze

$$
\delta_h^{\mathrm{obs}}
=d_{H_2,H_1}+|d_{H_2,H_1}-d_{H_1,H_0}|,
$$

$$
\delta_g^{\mathrm{obs}}
=d_{G_2,G_1}+|d_{G_2,G_1}-d_{G_1,G_0}|,
$$

$$
\delta_N^{\mathrm{obs}}=d_{N5,N4},
$$

$$
\delta_{\vartheta}^{\mathrm{obs}}
=\frac{k_{A,17}^+-k_{A,17}^-}{2}
+d_\infty(E_{A,17},E_{A,9}),
$$

$$
\delta_{\mathrm{alg}}^{\mathrm{obs}}
=\max_{\vartheta\in\Theta_5}
d_\infty(E_{A,\mathrm{tight}}(\vartheta),E_{A,\mathrm{loose}}(\vartheta)).
$$

The five current-run companion P1 spectra are assigned to the corresponding anchor P2 inventories
by the same complete field-overlap assignment, using linear evaluation on the P1 side and quadratic
evaluation on the P2 side. For an assigned component define

$$
\delta_{P_1P_2}^{\mathrm{obs}}
=\max_{\vartheta\in\Theta_5}
d_\infty(E_{P_2}(\vartheta),E_{P_1}(\vartheta)).
$$

This cross-order assignment is computed only after the canonical P2 ordering is frozen and cannot
reorder it. When all six quantities are finite, define

$$
\Delta_{P_2}^{\mathrm{obs}}
=\delta_h^{\mathrm{obs}}+\delta_g^{\mathrm{obs}}
+\delta_N^{\mathrm{obs}}+\delta_{\vartheta}^{\mathrm{obs}}
+\delta_{\mathrm{alg}}^{\mathrm{obs}}+\delta_{P_1P_2}^{\mathrm{obs}}.
$$

Missing components remain `NaN`, the total remains `NaN`, and the candidate is labeled
`EMPIRICAL_RESOLUTION_PARTIAL` rather than deleted. Every component and the sum are observed
sensitivities, not upper bounds, confidence intervals or certified continuous errors.

## 9. Old P1 target matching without information leakage

The formal run reports its canonical P2 winner and current-run companion P1--P2 assignments, but it
does not know the historical P1 target. Only after canonical publication and post-run artifact
review may a separately reviewed, read-only audit consume the frozen I4.1a candidate-7 fields and
the I4.1b P2 field authority.

At the five common twists $\Theta_5$, that audit must:

1. reconstruct the old P1 target by candidate ID and stored realization IDs, never by frequency;
2. evaluate old fields with the P1 basis and new fields with the P2 basis on the same physical grid;
3. Gram-normalize complete old/new inventories and perform a global maximum-total-principal-overlap
   assignment at every twist;
4. require a unique strict mutual-best chain, four adjacent continuation edges, the frozen
   simple/cluster overlap threshold, available localization triples and consistent endpoint parity;
5. use frequency-envelope distance only after overlap as the already frozen deterministic tie-break.

If these conditions identify a unique P2 component, publish it separately as
`p1_target_matched_component` with its own $\lambda$/$k$ envelope and empirical P2 resolution. It
does not replace the canonical P2 winner. Otherwise publish `P1_TARGET_IDENTITY_AMBIGUOUS` or
`P1_TARGET_AUDIT_UNAVAILABLE`; neither state permits BIE proximity to resolve the ambiguity. The
audit writes only a create-once review leaf, never the canonical science artifacts, and remains
subject to the unused portion of the same 2700 s/3 GiB budget. It requires its own Researcher
theory-to-code and same-Skeptic spec-to-code gate before execution.

## 10. Minimal current-run artifacts and schemas

The future active experiment is the single attempt `test/i4/femref-a2/`. The exact scientific
identity is create-once `run-001/execution-001`; that namespace is currently absent. MATLAB receives
no runtime data file. All scientific constants are literal source values.

The only authoritative leaves are:

1. `scientific-result.mat`: schema ID, exact spec and schedule, P2 mesh descriptors, element and
   quadrature validation, bulk/defect compact spectra, coverage, every P2 object/component,
   assignments, exact rank keys, canonical P2 winner, six empirical components, current-run
   P1--P2 assignments, terminal, first direct failure and claim boundary;
2. `fields.mat`: six-node P2 connectivity, global edge/midpoint map, material labels, anchor
   $\Theta_{17}$ P2 $W_3$ subspaces, canonical winner realizations, five companion P1 inventories,
   P1/P2 common-grid samples and weights, normalization and diagnostic statuses;
3. `work/`: one create-once mesh cache per mesh and one spectrum cache per attempted solve. A cache
   stores the reached complete spectrum and the $W_3$ fields needed for later continuation; caches
   are current-run data, not a second selection authority;
4. `run.log`: concise append-only stage, mesh, solve-count and terminal messages;
5. `resource.tsv`: controller wall/RSS evidence;
6. `run-summary.csv`: exactly one final row and the last published root artifact.

Completed solve caches are written before a later slice fails. A scientific negative publishes the
reached compact state and exact reason. Operational or resource interruption must not fabricate a
READY science container. No historical ledger, hash mirror, forecast table, benchmark, repeated
schema copy or diagnostic dispatcher is part of the active path.

## 11. Terminal states and lifecycle

A successful terminal is `P2_FEM_CANDIDATE_READY`; it requires at least one finite, positive,
residual-valid, field-bearing $W_3$ component and a deterministic canonical rank. It does not require
gap, localization, parity, all-axis or 60-root diagnostics to pass.

The only scientific/numerical blockers are:

1. no legal P2 mesh/phase space survives the frozen schedule;
2. all applicable matrices are nonfinite, non-Hermitian or have non-SPD mass;
3. every applicable eigensolve or returned field fails finite/positive/residual/orthogonality
   validity;
4. after the complete finite schedule, no legal refinement has any valid field-bearing $W_3$
   object;
5. the element, quadrature, P1-embedding, phase-map or ordered-Ritz validation proves the intended
   conforming P2 implementation invalid;
6. the only hard wall/RSS upper is reached;
7. create-once or canonical publication fails.

A single mesh, slice or object failure is recorded and the remaining legal schedule continues.
Missing continuation, weak localization, parity ambiguity, unresolved bulk gap, partial spectrum
coverage or a non-contracting refinement ladder is a caveat and cannot create a no-candidate
terminal.

Scientific, resource and canonical-publication terminals consume `run-001`. A genuine source,
path, dependency, controller or environment failure preserves immutable evidence but does not
consume the scientific identity. Only after bounded Researcher--Engineer--Skeptic repair and a
complete new pre-run review may the same `femref-a2/run-001` use the smallest unused explicit
create-once execution label. There is no automatic retry, overwrite, new attempt or use of an old
execution as active input.

## 12. Exact resource and command contract

The only inclusive hard resource predicates for the complete result are

$$
T_{\mathrm{hard}}=2700\ \mathrm{s},
\qquad
R_{\mathrm{hard}}=3221225472\ \mathrm{bytes}.
$$

The scientific runner, MATLAB process tree, publication and any subsequently authorized P1-target
field audit share one non-resetting wall budget; peak memory is the maximum authoritative aggregate
process-tree RSS across stages. At either hard upper the current target is stopped immediately.
There is no lower wall/RSS stop, preflight cap, forecast gate, stall rule, cadence rule, reserve,
guard or grace period. Process-tree authority loss is an operational failure, not a third resource
threshold.

Planning evidence is:

- I4.1a `run-007` completed 119 P1 solves in 140.273679 s with peak RSS 1,353,826,304 B and maximum
  P1 reduced dimension 7,496;
- the new base/max requested-root work is 5,416/6,436 versus 5,176 for `run-007`;
- the proposed maximum P2 dimension is conservatively bracketed by the same-mesh evidence
  18,256--29,984;
- streaming one solve at a time avoids simultaneous retention of all eigenvectors, while the
  anchor fields required by the audit are published once.

Using a factor of eight on the observed P1 scientific time for the larger two-dimensional sparse
P2 systems, the maximum root-work ratio $6436/5176$, and 30% for assembly, P2 evaluation,
publication and control gives a prospective scientific estimate of approximately 1,820 s. A later
read-only field audit is assigned a conservative 300 s planning charge, giving about 2,120 s total.
For memory, retaining the observed MATLAB baseline and conservatively scaling sparse factors,
100-vector eigensolver workspaces and anchor-field storage gives 2.65 GiB. Both estimates are below
2700 s and 3 GiB; neither is a runtime stop or success gate. The margins are not large, so if the
same Skeptic finds that the actual implemented call graph or storage model reasonably predicts an
overrun, the design must be `RESOURCE_BUDGET_UNAVAILABLE` before launch rather than silently
reducing the scientific schedule.

After implementation and both static gates, the sole no-argument formal command is frozen as:

```text
cwd: /Users/whc/Documents/Work/epost/test/i4/femref-a2
/usr/bin/perl ./run_formal.pl
```

The runner must literally launch once:

```text
/Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1b('run-001','execution-001')"
```

Neither command is authorized by this design.

## 13. Minimal implementation boundary and review gates

Only after same-Skeptic design approval may one Engineer create `test/i4/femref-a2/` with:

- `run_i4_1b.m` containing the source-owned model, mesh, P2 assembly, validation, spectrum,
  continuation, ranking and publication path;
- `run_formal.pl` containing the fixed no-argument launch and only the 2700 s/3 GiB hard controller;
- a concise `README.md` and `SYMBOLS.md` describing source objects and schemas without controlling
  execution.

The Engineer must not modify `femref-a1`, package/main code, I1--I3, or any historical output. The
implementation should contain only core mathematical checks, create-once publication, concise
logging and resource control; it must not reproduce the I4.1a diagnostic/audit machinery.

The Researcher theory-to-code audit must verify:

1. exact continuous constants, straight-sided P2 basis, global midpoint sharing, phase maps and
   degree-five quadrature;
2. all element/operator/Ritz checks and their non-identity semantics;
3. exact 72 P2 bulk, 47 P2 defect, five P1 companion, and conditional 17-call schedule;
4. P2-specific field evaluation, complete cluster inventory, global assignments and total rank;
5. five P2 internal sensitivity formulas plus separately non-ranking P1--P2 drift;
6. canonical P2 winner is independent of companion/history data and the old P1 target is absent
   from active MATLAB;
7. minimal schema, partial-state truthfulness, lifecycle and no-effectivity boundary;
8. only 2700 s and 3,221,225,472 B are resource uppers.

The same Skeptic must then perform exact spec-to-code/resource review. Only its verdict with no
unresolved blocker may authorize the single formal command. Post-run artifact review precedes any
implementation or execution of the old-P1-target audit, and that audit precedes any later
comparison. No estimator/effectivity step is authorized anywhere in I4.1b by this document.

## 14. Researcher decision

The actual P1 mesh/resource evidence supports a three-level P2 ladder beginning at $s=12$, while
the fixed $s=18$ cross-axis corners keep the largest planned quadratic system below the same-mesh
$s=24$ P2 planning dimension. The maximum 141-call schedule, streaming storage and conservative
resource estimate remain inside the user-authorized hard budget. No current evidence forces a
method change or a resource stop at design time.

**Researcher decision: `GO TO THE SAME SKEPTIC FOR I4.1b DESIGN REVIEW / IMPLEMENTATION AND EXECUTION REMAIN BLOCKED`.**

## 15. Bounded deterministic-graph and spectrum-authority revision

Status: **`D1/D2 DESIGN BLOCKERS CLOSED PROSPECTIVELY / SAME SKEPTIC DELTA REVIEW REQUIRED / NOT IMPLEMENTED / NOT RUN`**.

This section is append-only and has priority where Sections 4--7 or 12 leave a mechanical choice.
It does not change the continuous model, mesh levels, 124/141-call schedule, uncertainty formulas,
resource uppers or claim boundary.

### 15.1 Exact defect graph and object identities

P2 objects are allocated once, before any assignment, in this order:

1. configurations `p2-h0`, `p2-h1`, `p2-h2-g1`, `p2-g0`, `p2-anchor`, `p2-n4`,
   `p2-loose`;
2. increasing twist index within each configuration;
3. increasing minimum root index, then maximum root index, then local cluster index.

The resulting one-based `object_id` is immutable. The exact directed P2 edge graph is:

| Edge family | Source | Target | Twist correspondence |
|---|---|---|---|
| within configuration | every listed P2 configuration at twist index $r$ | the same configuration at $r+1$ | increasing adjacent twists only |
| $h$ axis 1 | `p2-h0` | `p2-h1` | common $\Theta_5$ index $r\mapsto r$ |
| $h$ axis 2 | `p2-h1` | `p2-h2-g1` | common $\Theta_5$ index $r\mapsto r$ |
| geometry axis 1 | `p2-g0` | `p2-h2-g1` | common $\Theta_5$ index $r\mapsto r$ |
| geometry axis 2 | `p2-h2-g1` | `p2-anchor` | $r\mapsto 1,5,9,13,17$ in $\Theta_{17}$ |
| supercell axis | `p2-n4` | `p2-anchor` | $r\mapsto 1,5,9,13,17$ in $\Theta_{17}$ |
| algebraic axis | `p2-loose` | `p2-anchor` | $r\mapsto 1,5,9,13,17$ in $\Theta_{17}$ |

No unlisted direct, reverse, diagonal or coarse-to-fine edge is allowed. In particular there is no
`p2-h0` to `p2-h2-g1`, `p2-g0` to `p2-anchor`, or cross-axis edge. Bulk objects have no edge to a
defect object and never enter defect components.

The anchor views are exact subsets, not separately solved or duplicated graph vertices:

$$
\Theta_5=\Theta_{17}[1,5,9,13,17],
$$

$$
\Theta_9=\Theta_{17}[1,3,5,7,9,11,13,15,17].
$$

Subset views do not create extra continuation edges or persistence counts. The five current-run P1
companion inventories are assigned to the anchor $\Theta_5$ objects only after the complete pure-P2
component graph, rank and canonical winner have been frozen. Those cross-order pairs form a
separate `p1-p2-drift` graph and cannot merge P2 components or alter any pure-P2 rank key.

After all allowed P2 assignments, connected components are ordered by their minimum member
`object_id`; this one-based order is both `component_id` and `candidate_id`. No traversal order,
frequency or assignment discovery order may renumber them.

### 15.2 Complete dummy-augmented assignment

For a directed edge with $n$ source objects and $m$ target objects, form a square assignment of
size $n+m$. Rows are real sources $S_1,\ldots,S_n$ followed by dedicated birth rows
$B_1,\ldots,B_m$; columns are real targets $T_1,\ldots,T_m$ followed by dedicated death columns
$D_1,\ldots,D_n$. An inadmissible cell has infinite first cost and can never be selected.

For a real pair, let $O_{ij}$ be its minimum principal overlap, $d_{ij}$ its frequency-envelope
distance, and $r_j$ the target minimum root index. Pair-cost tuples are:

$$
c(S_i,T_j)=(-O_{ij},0,d_{ij},r_j,
\operatorname{id}(S_i),\operatorname{id}(T_j),0),
$$

$$
c(S_i,D_i)=(0,1,0,0,\operatorname{id}(S_i),0,1),
$$

$$
c(B_j,T_j)=(0,1,0,r_j,0,\operatorname{id}(T_j),2),
$$

$$
c(B_j,D_i)=(0,0,0,0,\operatorname{id}(S_i),
\operatorname{id}(T_j),3).
$$

A real source may use only its own death column, and a birth row may use only its own real target
or any death column. All other real-to-death and birth-to-real cells are inadmissible. For each
complete assignment, sum every tuple component over all $n+m$ selected cells and minimize that
summed tuple lexicographically. Thus the first component maximizes total overlap; the second then
minimizes births plus deaths. Frequency occurs only after overlap and unmatched count. There is no
overlap acceptance threshold: a finite zero-overlap real pair is still preferred to an avoidable
birth-plus-death pair after the first-component tie.

If two complete assignments have exactly the same summed tuple in binary64, choose the
lexicographically smallest vector of selected column indices in the fixed row order
$(S_1,\ldots,S_n,B_1,\ldots,B_m)$. This final rule makes the assignment unique without inspecting a
scientific result. Assigned real pairs alone create graph edges; births, deaths and dummy--dummy
pairs are stored but create no component edge.

The mandatory two-object fixture has the following expected outcomes:

| Inventory/cost pattern | Required assignment | Graph consequence |
|---|---|---|
| $O_{12}=0.9$, $O_{21}=0.8$, $O_{11}=0.4$, $O_{22}=0.3$ | $S_1\to T_2$, $S_2\to T_1$ | crossing edges; total overlap $1.7$ beats $0.7$ regardless of frequency tie terms |
| two sources, one target, $O_{11}=0.8>O_{21}=0.7$ | $S_1\to T_1$, $S_2\to D_2$, $B_1\to D_1$ | one continuation plus one death; $S_2$ remains in its existing component |
| one source, two targets, $O_{11}=0.8>O_{12}=0.7$ | $S_1\to T_1$, $B_2\to T_2$, $B_1\to D_1$ | one continuation plus one birth; $T_2$ starts a new component |
| all four real overlaps equal, and all later summed tuple entries tie | lexicographically smallest complete column-index vector | one reproducible pairing; exact tie is recorded as `ASSIGNMENT_EXACT_TIE` caveat |

The fixture is a static implementation test and performs no guided-mode computation.

### 15.3 Exact generalized eigensolver contract

Every spectrum uses the literal MATLAB call

```text
[V,D,flag] = eigs(K,M,nev,'smallestabs',opts)
```

on the already validated reduced Hermitian pair. The options are fixed as follows:

| `nev` | `opts.p` | `opts.maxit` | `opts.issym` | `opts.isreal` | `opts.disp` |
|---:|---:|---:|---|---|---:|
| 40 | 80 | 800 | `true` | `false` | 0 |
| 48 | 96 | 800 | `true` | `false` | 0 |
| 60 | 100 | 800 | `true` | `false` | 0 |

`opts.tol` is $10^{-9}$ for bulk $s=12,g=36$, $10^{-10}$ for bulk $s=18,g=36$, and
$10^{-11}$ for bulk $s=18,g=48$ main/count calls. It is the configuration tolerance already
listed in Section 5.2 for defect and companion calls. No call may alter `p`, `maxit`, target or
tolerance after seeing a flag, root or coverage result.

For reduced master coordinates $(x_j,y_j)$, including vertex and midpoint masters, define

$$
(v_0)_j=
\left(1+\frac18\cos(\sqrt2 x_j)+\frac18\sin(\sqrt3 y_j)\right)
\exp\!\left(\mathrm i\left[(\sqrt5-2)x_j+(\sqrt7-2)y_j\right]\right),
$$

then set `opts.v0 = v0 / norm(v0)`. The positive amplitude makes this vector nonzero. Master IDs,
not element traversal, determine its order. The same formula applies to P1 and P2 spaces. Random
starts, result-dependent shifts, alternative targets, fallback solvers, expanded `maxit`, changed
subspaces and automatic retries are prohibited. A nonzero flag or incomplete valid root count is a
slice-local eigensolver failure under Section 11.

### 15.4 Conditional 60-root agreement and authority

Every 48-root cache is immutable after publication. If the conditional rung is triggered, each
60-root anchor solve must first pass the ordinary finite/residual/orthogonality gates and then be
compared with the same slice's stored 48-root result:

1. the first 48 ordered frequencies agree to maximum absolute tolerance $10^{-8}$;
2. clustering at the frozen $10^{-6}$ frequency tolerance gives identical ordered cluster
   boundaries and multiplicities for roots 1--48;
3. corresponding 48/60 field subspaces, compared on the same mesh with the exact P2 mass, have
   minimum principal overlap at least $1-10^{-8}$.

If all three checks pass, the 60-root cache is that anchor slice's sole active spectrum authority
for clustering, $W_3$ inventory, fields, continuation, coverage and publication. The 48-root cache
remains immutable count/agreement evidence and must not create duplicate objects.

If any agreement check fails, record `SPECTRUM_EXPANSION_INCONSISTENT`, retain the valid 48-root
cache as that slice's sole active authority, reject the 60-root cache from candidate construction,
and mark global coverage `SPECTRUM_COVERAGE_PARTIAL`. This is a coverage caveat, not a reason to
delete valid 48-root fields or stop ranking. The mixed per-slice authority table is explicit in
`scientific-result.mat`; silent replacement, averaging or merging of 48/60 roots is forbidden.

### 15.5 Global P1 embedding, phase commutation and P2 parity

Let $E_{\mathrm{full}}$ map full P1 vertex coefficients to full P2 coefficients: it is identity on
vertices and assigns each midpoint the arithmetic mean of its two endpoint coefficients. For phase
$\phi$, let $P_1(\phi)$ and $P_2(\phi)$ be the P1 and P2 quasiperiodic prolongations. Construct the
unique reduced embedding $E_{\mathrm{red}}(\phi)$ from the P2 master values of
$E_{\mathrm{full}}P_1(\phi)$ and require the commuting identity

$$
E_{\mathrm{full}}P_1(\phi)
=P_2(\phi)E_{\mathrm{red}}(\phi)
$$

to relative Frobenius tolerance $10^{-12}$. The reduced bilinear identities are

$$
E_{\mathrm{red}}(\phi)^*K_2(\phi)E_{\mathrm{red}}(\phi)=K_1(\phi),
$$

$$
E_{\mathrm{red}}(\phi)^*M_2(\phi)E_{\mathrm{red}}(\phi)=M_1(\phi),
$$

also to relative Frobenius tolerance $10^{-12}$. These global checks are performed at exactly:

- bulk $s=12,g=36$ with nontrivial phase $\alpha=\pi/4$;
- coarse defect `p2-h0` with $\vartheta=\pi/4$;
- anchor defect `p2-anchor` with $\vartheta=\pi/4$.

The independently assembled P1 forms use the same straight polygonal geometry and material labels.
Passing these identities checks phase-space nesting; it does not identify a P1/P2 mode.

The full P2 reflection permutation $R_2$ maps every vertex at $(x,y)$ to the unique vertex at
$(-x,y)$ and maps midpoint edge $\{v_a,v_b\}$ to the midpoint of
$\{R_2v_a,R_2v_b\}$. It must be bijective and involutive, and at endpoint twists must satisfy

$$
R_2^*M_2R_2=M_2
$$

to the frozen Hermitian tolerance. For an endpoint mass-orthonormal cluster basis $U$, form the
Hermitian compression

$$
C_R=U^*M_2R_2U.
$$

After its finite/Hermitian check, classify the cluster `even` if every eigenvalue of $C_R$ is at
least $0.80$, `odd` if every eigenvalue is at most $-0.80$, and `mixed/ambiguous` otherwise. A
missing reflection map, non-Hermitian compression or eigendecomposition failure gives
`parity-unavailable`. Parity status participates only in its already frozen rank position; failure
is a caveat and cannot invalidate a finite field, spectrum or candidate.

### 15.6 Mandatory post-implementation pre-run resource table

Before any formal launch, the implementation handoff must give one static row for each of the nine
distinct P2 meshes:

1. bulk $(s,g)=(12,36),(18,36),(18,48)$;
2. defect $(N,s,g)=(5,12,36),(5,15,36),(5,18,36),(5,18,24),(5,18,48),(4,18,48)$.

Each row must report actual $V,T,B$, derived
$E=(3T+B)/2$, full and reduced P2 DOFs, full/reduced `nnz(K)` and `nnz(M)`, and the applicable
`nev`/`p` pairs $(40,80)$, $(48,96)$ and $(60,100)$. No planning interpolation may replace an
actual implemented mesh count.

A second stage-lifetime table must list bytes and simultaneous residency for: mesh/connectivity and
midpoint maps; full and reduced P2 operators; the sparse-factor allowance; `p=80/96/100` Arnoldi
workspaces; returned eigenvectors; one current spectrum and cluster workspace; accumulated anchor
fields; quadratic common-grid samples/weights; five companion-P1 returns; current-run caches;
MAT-file serialization buffers; one publication copy; controller state; and the measured/justified
MATLAB runtime baseline. It must show explicit clearing/streaming points and calculate the maximum
sum of simultaneously live objects, not a sum over disjoint stages.

The theory-to-code and same-Skeptic spec-to-code reviews must also recompute the full 124/141 call
graph with the literal `p` values above. If the implemented call graph or simultaneous-live table
reasonably predicts whole-result wall time at least 2700 s or aggregate peak RSS at least
3,221,225,472 B, the pre-run terminal is `RESOURCE_BUDGET_UNAVAILABLE`. The schedule, root counts,
fields, assignments and publication evidence may not be reduced to obtain a launch. There remains
no lower wall/RSS, forecast, stall, cadence, reserve, guard or grace execution stop.

### 15.7 Researcher delta decision

The exact graph, assignment completion, generalized eigensolver, conditional-spectrum authority,
global phase-space embedding and endpoint P2 parity are now mechanically determined. The required
actual nine-mesh/storage table closes the implementation-stage resource evidence locator without
changing the current 2,120 s/2.65 GiB prospective estimate.

**Researcher decision: `GO TO THE SAME SKEPTIC FOR FOCUSED I4.1b DELTA REVIEW / IMPLEMENTATION AND EXECUTION REMAIN BLOCKED`.**

## 16. Post-implementation theory-to-code audit and zero-eigensolve resource preflight

Status: **`REVISE / FORMAL RUN BLOCKED / ZERO-EIGENSOLVE PREFLIGHT REQUIRED`**.

This append-only section audits the four-file Engineer implementation against Sections 1--15 and
has priority only for the bounded source corrections and preflight lifecycle below. It does not
change the continuous problem, fitted straight-sided $P_2$ space, mesh axes, 124/141-call schedule,
candidate rules, empirical uncertainty formulas, information boundary, resource uppers or claim
boundary.

### 16.1 Static theory-to-code map

The following mappings are **ESTABLISHED by static source inspection**, but have not been exercised
by MATLAB:

| Frozen object | Current source locator | Static finding |
|---|---|---|
| continuous model, $\lambda=k^2$, windows and tolerances | `run_i4_1b.m:144-216` | period, radius, $q=17/1$, missing column, $\beta=0.5$, four windows, phase grids and residual/Hermitian tolerances agree with Sections 1--5 |
| nine fitted meshes and solve groups | `run_i4_1b.m:333-392`, `447-648`, `1537-1665`, `1957-2027` | three bulk and six defect meshes are present; the call graph is $67+5=72$ P2 bulk, 47 P2 defect and five current-run P1 companion calls, with one conditional 17-call 60-root rung, hence 124/141 |
| six-node conforming $P_2$ topology | `run_i4_1b.m:780-805` | sorted active edges own one globally shared midpoint DOF and local order is $(v_1,v_2,v_3,e_{12},e_{23},e_{31})$ |
| $P_2$ basis, quadrature and P1 embedding | `run_i4_1b.m:807-975` | the six quadratic barycentric functions and gradients are literal; the seven-point rule is tested through total degree five and is used for stiffness and weighted mass; local P1-in-P2 stiffness and mass identities are checked |
| vertex/midpoint phase space and global embedding | `run_i4_1b.m:976-1234` | P1 and P2 masters include corners, top/right slaves receive the product phase, boundary midpoints are paired, and the three named $\pi/4$ global commutator/bilinear checks are present |
| Hermitian/SPD/eigensolver objects | `run_i4_1b.m:1235-1532` | raw reduced forms are checked before canonicalization; mass is Cholesky-tested; the literal generalized `eigs(K,M,nev,'smallestabs',opts)` call uses $p=80,96,100$, `maxit=800`, deterministic vertex/midpoint-master `v0`, fixed tolerances and no result-dependent retry |
| 48/60 spectrum authority | `run_i4_1b.m:1614-1730`, `1908-1927` | immutable 48-root caches are compared by frequency, cluster IDs and exact-mass principal overlap; an agreeing 60-root slice replaces 48 as sole active authority, while disagreement leaves 48 active and only downgrades coverage |
| fields, caveat-only diagnostics and graph | `run_i4_1b.m:2175-2848`, `3350-3478` | all field-bearing whole clusters intersecting $W_3$ are inventoried; localization, parity and P2 common-grid evaluation have separate non-fatal statuses; the exact within/cross-configuration edge list and dummy-augmented lexicographic assignment are present |
| pure-P2 rank and empirical uncertainty | `run_i4_1b.m:2860-3221` | singleton components are rankable; the total key, canonical realization, five P2 sensitivities and finite/`NaN` resolution semantics implement Sections 6--8 |
| P1 companion isolation | `run_i4_1b.m:1957-2170` | pure-P2 components and winner are frozen before P1 solves; the separately evaluated P1 fields enter only a non-ranking assignment and $\delta_{P_1P_2}^{\mathrm{obs}}$ update; no historical P1 target, BIE/QZ quantity or estimator is read |
| canonical/partial artifacts and no-effectivity boundary | `run_i4_1b.m:221-332`, `3223-3511` | current-execution caches precede later use; compact science and field authorities retain terminal and field evidence and explicitly remain empirical/non-certified with effectivity false |
| controller hard resources | `run_formal.pl:10-214` | the fixed command has only inclusive 2700 s and 3,221,225,472 B stops and samples the recursive/PGID MATLAB process tree; there is no lower wall/RSS, forecast, stall or cadence gate |

The P2 and P1 common-grid evaluators are distinct (`run_i4_1b.m:3364-3439`), so the P2 field is not
silently reduced to P1 interpolation. The current MATLAB reads (`run_i4_1b.m:274-277,437-445`) are
limited to caches created under the same execution. No active source path reads Markdown, Git,
historical output, BIE/QZ data, density, estimator or a reference result. The old-P1-target audit in
Section 9 remains unimplemented and cannot affect the formal selector.

### 16.2 Bounded implementation corrections before preflight

Static counterexample review found three **blockers**, each local to implementation rather than the
scientific method:

1. **Object allocation and ranking priority are conflated.** Section 15.1 requires allocation order
   `p2-h0`, `p2-h1`, `p2-h2-g1`, `p2-g0`, `p2-anchor`, `p2-n4`, `p2-loose`, but
   `LOCAL_candidate_inventory` iterates the rank-priority array whose order begins with
   `p2-anchor` (`run_i4_1b.m:214-215,2182-2216`). Because object IDs enter exact assignment ties,
   component IDs and the final rank key, this can change the frozen winner. The bounded repair is
   to add a separate immutable allocation-order list, iterate it for object creation, and retain the
   existing rank-priority values on each object.
2. **The midpoint-reflection shape comparison is not invariantly column-shaped.** At
   `run_i4_1b.m:998-1009`, `expected` is an $E\times1$ vector while the explicit transpose used to
   form `actual` can make it $1\times E$ under MATLAB vector-indexing rules. The bounded repair is
   to compare `expected(:)` with `actual(:)` and leave the reflection permutation and parity
   mathematics unchanged. This must be closed before the first mesh can be regarded as validated.
3. **The runner can publish two different final resource terminals.** It freezes and writes
   `resource.tsv` at `run_formal.pl:139-145`, then performs another deadline decision at lines
   146--150 before `run-summary.csv`. A deadline crossing in that interval can leave the resource
   row `NATURAL_EXIT` while the summary says `WALL_HARD_LIMIT_REACHED`. Replace this with one final
   deadline decision and one immutable terminal used for exactly one resource publication followed
   by summary-last; the same absolute deadline and both existing hard predicates remain unchanged.

In addition, a one-mesh topology failure carrying `MESH_INVALID` is currently not in the
mesh-registry recordable set (`run_i4_1b.m:395-432,780-805`). Section 11 requires a single illegal
mesh to be recorded while the remaining legal schedule continues. The same bounded repair must
route this code as a mesh-local failure; generic source/output failures must still be rethrown and
the all-mesh/no-object terminal remains unchanged.

No other source-local deviation was found in the audited mathematical paths. This is a
**CONDITIONAL** static conclusion: MATLAB syntax/runtime behavior, actual mesh counts, sparse
fill-in and process RSS remain unverified.

### 16.3 Create-once zero-eigensolve preflight

The source-derived peak model is 2.973 GB, close enough to the 3 GiB hard upper that static planning
alone does not authorize 141-call execution. After the corrections in Section 16.2 and their
Researcher/Skeptic delta reviews, freeze the new diagnostic identity
`resource-preflight-001/execution-001` and create-once namespace
`output/resource-preflight-001/execution-001/`. That namespace is presently absent. A launched
complete or resource-terminal preflight consumes this execution label. A genuine reviewed
source/path/dependency/controller/environment failure preserves its immutable leaf and may use the
smallest unused `execution-002`, etc., only after bounded repair and complete re-review; there is no
automatic retry, overwrite, or change of scientific `run-001`.

The preflight is an alternate exact source dispatch, not a scientific run. It may construct and
assemble the frozen objects but must make **zero calls** to `eigs`, `eig`, `svd`, a guided-mode
selector, branch tracking or candidate ranking. It must not create spectra, fields, candidates or
a reference scalar, and it must not read historical output, BIE/QZ data, estimators, Markdown or
Git. It performs only:

1. the same deterministic construction of all nine Section 15.6 meshes and their P1/P2 full and
   reduced phase spaces;
2. finite/Hermitian/SPD, seam, nodal, partition, quadrature and P1-embedding representation checks;
3. for each mesh, actual $V,T,B,E$, P1/P2 full and reduced DOFs, full-form `nnz(K/M)`, and the
   maximum reduced `nnz(K/M)` over its already frozen scheduled phase set;
4. on the largest anchor representation, actual sparse mass-factor storage plus committed
   shape-matched complex buffers for $p=100$, a 60-vector return, the frozen worst-case retained
   field/common-grid/P1-companion capacities and one publication-copy allowance. These buffers are
   representation/RSS evidence only and contain no eigenpair or physical result;
5. external aggregate MATLAB-process-tree RSS measurement for mesh assembly, reduced
   operator/factor, solver-capacity, retained-field/sample and publication-capacity stages, with
   deduplicated process identities.

The only permitted leaf artifacts are `mesh-operators.tsv`, `residency.tsv`, `preflight.log`,
`resource.tsv` and summary-last `preflight-summary.tsv`. The mesh table contains one row per mesh
and all quantities in item 3 plus applicable $(\mathrm{nev},p)$. The residency table records each
named stage, simultaneously live object classes/bytes, MATLAB RSS, aggregate process-tree RSS and
peak. `resource.tsv` records preflight elapsed wall, aggregate peak RSS and terminal. No MAT cache,
spectrum, field or result artifact is allowed.

The preflight controller has no arguments and, after implementation review, is run only as:

```text
cwd: /Users/whc/Documents/Work/epost/test/i4/femref-a2
/usr/bin/perl ./run_preflight.pl
```

It must launch the exact alternate identity in MATLAB R2023b, enforce only elapsed
$\ge2700$ s or aggregate RSS $\ge3221225472$ B, fail closed if RSS authority is lost, and publish
the preflight summary last. There is no lower hard gate, forecast/stall/cadence/reserve rule, and a
small remaining margin is evidence for the Skeptic rather than an automatic failure.

Let the reviewed preflight artifact supply elapsed $T_{\mathrm{pf}}$ and peak
$R_{\mathrm{pf}}$. The scientific controller must not read that artifact at runtime. After
post-preflight review, the Engineer mechanically freezes those two scalars in `run_formal.pl`; its
single absolute deadline is `formal_start + (2700 - T_pf)`, and its cumulative resource record is

$$
T_{\mathrm{cum}}=T_{\mathrm{pf}}+T_{\mathrm{formal}},
\qquad
R_{\mathrm{cum}}=\max\{R_{\mathrm{pf}},R_{\mathrm{formal}}\}.
$$

Thus preflight and formal science share one non-resetting 2700 s/3 GiB budget without making the
MATLAB science path depend on a prior artifact. If measured objects or the corrected source model
reasonably predict $T_{\mathrm{cum}}\ge2700$ s or $R_{\mathrm{cum}}\ge3221225472$ B, the next gate
is `RESOURCE_BUDGET_UNAVAILABLE`; the 124/141 schedule, meshes, roots and fields may not be reduced.

### 16.4 Researcher decision and next gate

**Researcher decision: `REVISE`.** The P2 method and most theory-to-code mappings survive, but the
allocation-order/reflection validation and terminal-publication discrepancies require bounded
Engineer repair. Formal `run-001/execution-001` remains blocked. After those repairs, the same
Researcher must perform a focused static delta audit and the same Skeptic must review both the
corrected mapping and this preflight contract. Only then may the zero-eigensolve
`resource-preflight-001/execution-001` command be considered for authorization. Its measured
artifact and the non-resetting formal-controller arithmetic require a further same-Skeptic
pre-run resource review before any eigensolve.

### 16.5 Exact preflight dispatch clarification

The `run_preflight.pl` controller must literally launch once:

```text
/Applications/MATLAB_R2023b.app/bin/matlab -batch "run_i4_1b('resource-preflight-001','execution-001')"
```

The alternate pair is an exact allowlisted dispatch distinct from formal
`run-001/execution-001`; no argument, environment value or discovered file may select another
identity or mode.

## 17. Focused theory-to-code delta audit of the Section 16 implementation

Status: **`RESEARCHER STATIC PASS / SAME SKEPTIC PREFLIGHT REVIEW REQUIRED / NOT RUN`**.

This append-only audit reopens only the four bounded corrections and the zero-eigensolve preflight
contract in Section 16. The continuous problem, fitted $P_2$ method, 124/141 scientific schedule,
branch/rank/uncertainty rules, P1-companion isolation and empirical claim boundary were checked for
unchanged source ownership but were not re-designed.

### 17.1 Four blocker closures

1. **Allocation order is separated from rank priority.** `LOCAL_spec` now owns the exact
   Section 15.1 allocation order independently of the anchor-first rank priority
   (`run_i4_1b.m:222-225`). `LOCAL_candidate_inventory` allocates in that order, derives the
   independent rank-priority integer by name, and preserves sequential object IDs
   (`run_i4_1b.m:2428-2495`). Assignment tie fields, component IDs and the final rank therefore use
   the prescribed immutable IDs without changing the canonical priority.
2. **Midpoint reflection is shape-safe.** `LOCAL_validate_p2_reflection` compares
   `actual(:)` and `expected(:)` after the same endpoint-induced edge permutation
   (`run_i4_1b.m:1251-1263`). No reflection or parity mathematics changed.
3. **Formal terminal publication is single-decision.** `run_formal.pl:130-147` performs one final
   fresh absolute-deadline decision, freezes `final_terminal` and `final_elapsed`, then writes
   exactly one `resource.tsv` and summary-last `run-summary.csv` from those same values. The former
   second decision is absent; the absolute 2700 s alarm and 3,221,225,472 B aggregate-RSS predicate
   remain the only resource uppers.
4. **A single illegal topology is local.** `MESH_INVALID` is now included with the two existing
   mesh-local recordable codes at `run_i4_1b.m:647-665`; generic source and output failures still
   rethrow. Thus one illegal mesh cannot prematurely erase the remaining schedule, while the
   complete no-valid-mesh/no-valid-object outcomes remain scientific negatives.

These are **ESTABLISHED statically** closures. No MATLAB semantics or numerical object was executed.

### 17.2 Preflight reachability and artifact audit

The exact allowlist at `run_i4_1b.m:32-57` admits only
`run-001/execution-001` and `resource-preflight-001/execution-001`. The preflight branch calls
`LOCAL_resource_preflight` and returns before work-directory creation or any formal inventory.
Its reachable source graph is:

```text
LOCAL_resource_preflight
  -> LOCAL_spec / LOCAL_mesh_schedule
  -> LOCAL_build_mesh
     -> topology, P1/P2 assembly, nodal/quadrature/embedding,
        periodic/reflection, finite/Hermitian/SPD checks
  -> LOCAL_preflight_phases
  -> LOCAL_phase_reduce / LOCAL_phase_reduce_p1
     -> prolongation, seam, Hermitian/SPD and named global embedding checks
  -> LOCAL_value_bytes / LOCAL_commit_complex_capacity
  -> marker, mesh-table and terminal writers
```

None of these reachable functions calls `eig`, `eigs`, `svd`, a spectrum routine, W3 inventory,
tracking, ranking, field publication or reference-scalar construction. The only source occurrences
of `eigs`, `eig` and `svd` remain below formal-only spectrum/object helpers
(`run_i4_1b.m:1536,1662,1970,2556,2581,2799,3614`) and are unreachable after the preflight return.
The preflight does use the required sparse Cholesky SPD checks and shape-matched committed buffers;
those are representation evidence, not eigensolves.

`LOCAL_resource_preflight` constructs all nine frozen meshes, scans their already frozen scheduled
phase sets, records actual $V,T,B,E$, P1/P2 full/reduced dimensions and full/reduced operator
`nnz`, and retains the anchor only for factor/capacity stages (`run_i4_1b.m:231-408`). Its
$p=100$, 60-vector, worst-field, common-grid, five-companion and 512 MiB publication buffers are
committed and held across named stage pauses (`run_i4_1b.m:315-380`), without creating a spectrum
or field object.

The MATLAB branch writes only `mesh-operators.tsv` and `preflight.log`
(`run_i4_1b.m:410-468`). The controller adds only `residency.tsv`, `resource.tsv`, and summary-last
`preflight-summary.tsv` (`run_preflight.pl:228-319`). Hence the Section 16 five-leaf artifact
allowlist is exact; neither scientific MAT file, work cache nor auxiliary result is reachable.
README and SYMBOLS describe the same identity, leaves and no-spectrum boundary
(`README.md:8-47,129-139`; `SYMBOLS.md:9-10,49-52`).

### 17.3 Resources, later shared-budget patch and unchanged science

`run_preflight.pl:10-29,74-175` has no arguments, launches the exact alternate pair, and enforces
only elapsed $\ge2700$ s and deduplicated aggregate MATLAB-process-tree RSS
$\ge3221225472$ B. Its 0.25 s sampling and the MATLAB pauses are observation mechanisms, not lower
stops or pass/fail thresholds. RSS-authority or process-group loss remains an operational
fail-closed state, not a third resource upper.

The preflight and formal science do not yet share data at runtime. This is intentional: after a
reviewed preflight, its measured $T_{\mathrm{pf}}$ and $R_{\mathrm{pf}}$ must be mechanically
frozen into `run_formal.pl`, with remaining deadline $2700-T_{\mathrm{pf}}$ and cumulative peak
$\max(R_{\mathrm{pf}},R_{\mathrm{formal}})$, followed by another static/Skeptic review
(`README.md:129-139`; Section 16.3). No MATLAB path may read the preflight artifact. Until that
post-preflight patch is reviewed, formal `run-001/execution-001` remains blocked.

The formal constants, nine meshes, root counts, tolerances and call construction remain at
`run_i4_1b.m:152-225,585-642,1790-1918,2210-2264`: 72 P2 bulk, 47 P2 defect, five non-ranking
current-run P1 companions, and only the frozen conditional 17-call 60-root rung. The preflight adds
zero scientific calls and cannot alter the P2 graph, rank, uncertainty or P1 isolation.

### 17.4 Researcher decision

**Researcher theory-to-code decision: `PASS TO THE SAME SKEPTIC FOR FOCUSED SPEC-TO-CODE AND
PREFLIGHT-AUTHORIZATION REVIEW`.** No Section 16 implementation blocker remains by static
inspection. This PASS does not authorize `run_preflight.pl`, MATLAB, the formal runner, or any
eigensolve. If the same Skeptic authorizes and the preflight completes, its artifacts and exact
non-resetting budget scalars require post-preflight review before the formal source can be patched
or reconsidered for launch.

## 18. Bounded Section K resource-lifetime and publication revision

Status: **`REVISE / TWO ENGINEER-LOCAL REPAIRS FROZEN / NO EXECUTION`**.

This section supersedes Sections 16--17 only where their preflight residency stages or controller
finalization permit the two Section K counterexamples. It does not reopen the continuous model,
$P_2$ discretization, meshes, 124/141-call schedule, graph/rank, uncertainty, information isolation,
five authoritative artifact names, create-once identities, or claim boundary. The only hard
resource predicates remain

$$
T\ge2700\ \mathrm{s},\qquad R_{\mathrm{RSS}}\ge3221225472\ \mathrm{B}.
$$

### 18.1 Formal-lifetime representation stage

The current disjoint `solver-capacity` and `retained-capacity` stages are insufficient as peak
evidence. Within the existing zero-eigensolve preflight, the Engineer must add one committed
`companion-simultaneous-capacity` stage. Before any member of this stage is cleared, the process
must hold and touch all of the following shape-matched objects simultaneously:

1. the pessimistic retained $P_2$ candidate-field subspaces and common-grid samples already used
   by `retained-capacity`;
2. four completed P1 companion full-field returns plus the current fifth 48-vector reduced and
   full-field returns, so the capacity covers the largest prior/current companion lifetime;
3. the anchor P1 companion full/reduced $K$ and $M$, prolongation and sparse Cholesky factor;
4. one complex $p=96$ Arnoldi workspace and the current 48-vector returned subspace; and
5. the small current companion spectrum/metadata capacity needed to retain that object beside the
   preceding four companions.

These allocations are conservative shape replicas only. They must be committed by deterministic
touches and held together for at least one existing observation sample; they must call no `eig`,
`eigs` or `svd` and must not manufacture a spectrum, field, candidate or reference value. Clearing
the factor/workspace before allocating the retained fields or companions does not satisfy this
contract. The stage's deduplicated aggregate process-tree RSS, not a byte-count formula or an
individual MATLAB PID, is its authority.

The preflight must also retain or add a distinct `publication-simultaneous-capacity` stage matching
the larger formal publication lifetime: retained $P_2$ fields/samples, all five P1 companion
fields, source-side candidate/companion payload capacity and the frozen serialization/publication
copy allowance must coexist. No eigensolver factor is required in this second stage after the
formal companion solve has returned. Both stages are measured; the maximum over every measured
stage is $R_{\mathrm{pf}}$. If static mapping of the implemented formal path reveals a still larger
simultaneous-live set, that actual set must replace the smaller representative rather than be split
across stages. The same five authoritative preflight leaves remain unchanged; `residency.tsv`
records the two named stages, their shape classes and committed byte counts.

### 18.2 Deadline-safe publication state machine

Both `run_preflight.pl` and `run_formal.pl` must use the same bounded publication rule. The single
absolute deadline remains armed until the atomic publication of the final summary; an alarm after
the target exits must abort publication, not merely set a flag that a previously frozen success
ignores. No reserve, earlier deadline, grace period, forecast, stall rule or third resource upper is
permitted.

The minimal consistent implementation is an append-only terminal-event ledger in the existing
`resource.tsv` leaf:

1. At finalization entry the controller opens the create-once resource leaf and writes its header.
   A row before the completion commit may describe the MATLAB target exit only as
   `PUBLICATION_PENDING`; it is not a whole-command success.
2. The controller writes and closes `residency.tsv`, prepares the summary in a same-directory
   temporary leaf, and includes all other pre-summary work while the original alarm remains armed.
   It then obtains one fresh monotonic time. An inclusive wall crossing appends a
   `WALL_HARD_LIMIT_REACHED` event with that time and exits nonzero without a final summary.
3. If still below the deadline, the controller appends one whole-command terminal row and records
   elapsed time only after all pre-summary work. A fresh check immediately before the summary
   commit uses the same absolute deadline. The summary is authoritative only after an atomic rename
   to the frozen summary name and remains the last authoritative artifact.
4. Until that rename succeeds, the armed alarm handler uses the already-open event-ledger file
   descriptor to append a `WALL_HARD_LIMIT_REACHED` correction row with a fresh monotonic elapsed
   value, aborts the publication path and exits nonzero. The last complete event row is authoritative;
   therefore a wall event supersedes any earlier provisional or natural-target row. A final summary
   must not be renamed after this latch. If the summary already exists after its successful atomic
   rename, the completion point has occurred and the handler must not alter its evidence.
5. A non-wall write, flush or rename failure similarly exits nonzero with no final summary and is a
   canonical publication failure. Partial temporary material is non-authoritative failure debris,
   never a sixth result artifact. There is no retry, overwrite or conversion of that failure into
   `NATURAL_EXIT`.

This state machine makes summary presence the success commit, keeps summary-last, and prevents an
elapsed value frozen before residency/resource publication from becoming the reported command
charge. It must be applied to the formal runner now as a static publication-boundary correction,
even though formal execution remains separately blocked pending reviewed $T_{\mathrm{pf}}$ and
$R_{\mathrm{pf}}$. The later non-resetting budget patch does not change this state machine.

### 18.3 Acceptance and authorization boundary

The bounded Engineer revision is accepted for another Researcher static audit only if all of the
following hold:

- the preflight reachable graph still contains zero calls to `eig`, `eigs`, `svd`, spectrum,
  candidate/rank or reference construction;
- source inspection and `residency.tsv` schema show one genuinely simultaneous companion stage and
  the distinct publication stage above, with no early clear that lowers either lifetime;
- the preflight retains exactly its existing create-once identity and five authoritative leaves;
- both controllers keep only the inclusive 2700 s and 3 GiB predicates, keep the same absolute
  deadline through summary commit, and cannot exit zero or leave an authoritative natural terminal
  when that deadline fires during publication;
- formal science, schedules, hard limits and later shared-budget arithmetic are otherwise unchanged.

**Researcher decision: `REVISE / GO TO THE SAME ENGINEER FOR THESE TWO BOUNDED REPAIRS`.** After
implementation, the same Researcher must perform a focused theory-to-code delta audit and the same
Skeptic must re-review it. `resource-preflight-001/execution-001`, formal
`run-001/execution-001`, all output creation, MATLAB/Octave/Python and every eigensolve remain
unauthorized at this gate.

## 19. Focused theory-to-code delta audit of the Section 18 repair

Status: **`RESEARCHER STATIC PASS / SAME SKEPTIC RE-REVIEW REQUIRED / NOT RUN`**.

This audit reopens only the two Section K defects. It is based on static source reachability and
object lifetime; no controller, MATLAB/Octave/Python program, preflight or eigensolve was executed.

### 19.1 Simultaneous-lifetime closure

The preflight now constructs the pessimistic retained $P_2$ field and common-grid capacities before
entering `companion-simultaneous-capacity` (`run_i4_1b.m:344-357`). In that one uninterrupted
scope it simultaneously retains:

- `anchor_mesh`, which owns the full P1 forms, and `companion_pair`, which owns reduced $K$, $M$,
  prolongation and the sparse mass factor (`run_i4_1b.m:361-375`);
- four prior full-field P1 returns, the current full and reduced 48-vector returns, the $p=96$
  Arnoldi workspace and companion metadata (`run_i4_1b.m:363-380`); and
- the previously allocated $P_2$ fields and samples (`run_i4_1b.m:354-355,372-374`).

The marker, byte inventory and one-second observation hold occur before the first relevant `clear`
(`run_i4_1b.m:381-395`). The following `publication-simultaneous-capacity` deliberately releases
the solver-only pair/workspace while retaining the $P_2$ fields/samples and all five P1 full-field
returns; it then co-resides those objects with the source payload and 512 MiB publication copy
(`run_i4_1b.m:395-424`). Thus the two stages represent the formal companion-solve and publication
lifetimes separately without lowering either by phased allocation.

The exact preflight dispatch still calls `LOCAL_resource_preflight` and returns at
`run_i4_1b.m:41-57`. Its reachable graph contains mesh construction, P1/P2 assembly and phase
reduction, Cholesky SPD checks, capacity commits and preflight writers only. All source occurrences
of `eig`, `eigs` and `svd` remain in formal-only spectrum, cluster, tracking or diagnostic helpers
below that return (`run_i4_1b.m:1580,1706,2014,2600,2625,2843,3658`). The five authoritative
preflight leaves remain `mesh-operators.tsv`, `preflight.log`, `residency.tsv`, `resource.tsv` and
summary-last `preflight-summary.tsv`; the summary `.partial` is only the already frozen
non-authoritative atomic-publication temporary.

### 19.2 Controller publication closure

Both controllers now implement the same state machine. They establish one absolute deadline from
the command start and arm it once (`run_preflight.pl:15-21,30-54`;
`run_formal.pl:15-20,29-53`). Their only numerical resource uppers are elapsed
$\ge2700$ s and aggregate target-tree RSS $\ge3221225472$ B
(`run_preflight.pl:104-137`; `run_formal.pl:93-121`). Sampling sleeps remain observations, not
additional stops.

Each runner creates `resource.tsv` as an append-only event ledger, publishes
`PUBLICATION_PENDING`, and keeps the alarm armed while preparing all pre-summary evidence
(`run_preflight.pl:182-213`; `run_formal.pl:164-185`). It then uses the same deadline for the final
elapsed decision, patches and synchronizes the summary temporary, appends and synchronizes the
whole-command terminal, performs one further fresh inclusive check, and atomically renames the
summary last (`run_preflight.pl:215-242`; `run_formal.pl:187-214`).

If the alarm fires before that rename, the handler appends a
`WALL_HARD_LIMIT_REACHED` correction when the ledger is available, emits failure evidence and
exits nonzero; if the summary name already exists, the atomic completion point has already occurred
(`run_preflight.pl:30-53`; `run_formal.pl:29-52`). Explicit deadline and publication-failure paths
likewise append a terminal event and prohibit summary success
(`run_preflight.pl:388-420`; `run_formal.pl:309-341`). The last complete resource event plus
summary presence therefore distinguishes a completed command from a partial wall/publication
failure; the former stale-success path is no longer reachable.

### 19.3 Unchanged science and decision

The formal constants still specify 72 P2 bulk, 47 P2 defect and five current-run P1 companion
solves, with only the frozen conditional 17-call 60-root rung
(`run_i4_1b.m:152-225,1832-1949`). The Section 18 patch adds no scientific call, changes no mesh,
root count, branch/rank, uncertainty, P1 isolation or result claim. README and SYMBOLS map the same
two residency stages, five leaves and event-ledger/summary-last semantics without controlling
execution (`README.md:61-87,124-149`; `SYMBOLS.md:46-57`).

**Researcher decision: `PASS TO THE SAME SKEPTIC FOR FOCUSED STATIC RE-REVIEW`.** The actual stage
RSS and publication behavior remain empirical until an independently authorized preflight; this is
the intended next gate, not a static source blocker. This PASS does not authorize preflight,
formal execution, output creation, MATLAB/Octave/Python or any eigensolve.

## 20. Bounded Section M operational repair and preflight continuation

Status: **`REVISE / TOPOLOGICAL MIDPOINT MAP AND EXECUTION-002 CONTRACT FROZEN / NO EXECUTION`**.

This section supersedes earlier preflight identity and budget text only for the reviewed operational
continuation below. `resource-preflight-001/execution-001` is consumed and immutable. Its failure
does not change the continuous model, fitted $P_2$ basis, weak form, nine meshes, scientific
schedule, simultaneous-capacity stages, five authoritative artifact names or claim boundary.

### 20.1 Topological $P_2$ reflection permutation

The P2 vertex block continues to use the already validated vertex reflection permutation
$r_V$. The midpoint block must no longer call a coordinate-rounded point lookup to decide node
identity. For the rowwise sorted, unique active-edge table

$$
e_j=\{a_j,b_j\},\qquad j=1,\ldots,E,
$$

the implementation must form

$$
\widehat e_j=\operatorname{sort}\{r_V(a_j),r_V(b_j)\}
$$

and find its exact row index $r_E(j)$ in that same sorted edge table. Every reflected edge must be
found exactly once. The full permutation is then constructed combinatorially as

$$
r_{P_2}(i)=r_V(i),\quad 1\le i\le V,
\qquad
r_{P_2}(V+j)=V+r_E(j),\quad 1\le j\le E.
$$

The following checks remain hard representation checks:

1. $r_E$ and $r_{P_2}$ are bijections and involutions;
2. every midpoint map agrees exactly with the reflected endpoint edge lookup above;
3. independently of how identity was chosen,

$$
\max_i\left\|x_{r_{P_2}(i)}-(-x_{i,1},x_{i,2})\right\|_\infty
\le \texttt{coordinate\_tolerance};
$$

4. the existing reflected stiffness/mass and endpoint-induced consistency checks remain in force.

Thus coordinates validate the constructed permutation but cannot select a midpoint partner.
Failure to find a unique reflected active edge is an actual reflection-closure failure; failure of
bijection, involution or endpoint consistency is a discrete-implementation failure. Neither may be
silently repaired with a nearest or rounded-coordinate match.

### 20.2 Exact continuation identity and non-resetting resources

The only prospective continuation is create-once
`resource-preflight-001/execution-002`, in the existing
`output/resource-preflight-001/` parent. The controller and MATLAB exact allowlist must be changed
mechanically to that execution ID for the preflight dispatch; formal remains
`run-001/execution-001`. The new controller must reject a pre-existing `execution-002` directory.
It must neither overwrite nor read, copy, hash or reuse any `execution-001` artifact as active
input. `execution-001` remains the immutable evidence for the source-owned prior constants

$$
T_{\mathrm{prior}}=18.226698\ \mathrm{s},
\qquad
R_{\mathrm{prior}}=1084440576\ \mathrm{B}.
$$

The `execution-002` current-run deadline is therefore

$$
T_{002,\mathrm{remaining}}
=2700-18.226698
=2681.773302\ \mathrm{s}.
$$

Its only wall predicate is equivalently

$$
18.226698+T_{002}\ge2700\ \mathrm{s};
$$

this reviewed remainder is the non-resetting user budget, not an additional lower stop. Memory is
not subtracted. The only cumulative memory predicate is

$$
R_{\mathrm{cum}}=\max\{1084440576,R_{002}\}
\ge3221225472\ \mathrm{B}.
$$

The append-only `resource.tsv` and summary-last record must expose current and cumulative wall
time, current aggregate peak and cumulative peak. Their wall/summary publication state machine is
otherwise exactly Section 18.2. No forecast, reserve, stall rule, grace period or other resource
gate is allowed. Scientific/resource/publication completion or failure consumes `execution-002`;
a further execution ID is not authorized by this section.

### 20.3 Bounded implementation acceptance

The same Engineer may change only:

- the P2 midpoint-permutation construction and its existing validation consumers;
- the preflight identity plumbing from `execution-001` to `execution-002` while preserving the
  formal identity; and
- the exact prior/current/cumulative resource fields and remaining-deadline arithmetic above,
  plus mechanical README/SYMBOLS synchronization.

Acceptance for another Researcher static audit requires exact edge-derived midpoint identities,
all four reflection checks, an unreachable coordinate-round midpoint selector, exact
`execution-002` create-once paths, no `execution-001` read, and source evidence that the only total
hard predicates remain 2700 s and 3,221,225,472 B. The preflight branch must still return before
every `eig`, `eigs`, `svd`, spectrum, field, branch, rank or reference path, and formal science must
remain unchanged.

**Researcher decision: `REVISE / GO TO THE SAME ENGINEER FOR THIS BOUNDED OPERATIONAL REPAIR`.**
After implementation, the same Researcher must perform a focused theory-to-code audit and the same
Skeptic must complete pre-execution review. `execution-002`, formal science, output creation and
all MATLAB/Octave/Python or runner execution remain unauthorized now.

## 21. Focused theory-to-code audit of the Section 20 repair

Status: **`RESEARCHER STATIC PASS / SAME SKEPTIC PRE-EXECUTION REVIEW REQUIRED / NOT RUN`**.

This audit reopens only the midpoint-reflection identity and preflight-continuation plumbing. It
does not authorize or report a program execution.

### 21.1 Edge-induced reflection mapping

The mesh builder still obtains and validates the P1 vertex reflection before topology and assembly
(`run_i4_1b.m:820-865`). After `LOCAL_p2_topology` has supplied its sorted unique edge table, the
patched code maps both endpoints through that vertex permutation, sorts each reflected pair and
uses an exact row lookup in the active-edge table (`run_i4_1b.m:891-895`). It then requires all
edges to be found and the returned edge IDs to be a permutation, followed by the explicit
involution check (`run_i4_1b.m:896-905`).

The P2 permutation is the literal concatenation of the vertex permutation and vertex-count-shifted
edge permutation. It is checked for full bijection and involution before use
(`run_i4_1b.m:907-915`). Only after that identity is frozen does the code evaluate the reflected
midpoint coordinates and require a finite coordinate defect no larger than
`coordinate_tolerance` (`run_i4_1b.m:916-924`). The existing endpoint-induced validator recomputes
the reflected-edge IDs and compares every midpoint entry exactly
(`run_i4_1b.m:925-926,1321-1333`). The later stiffness/mass reflection checks are unchanged.

Consequently, the only remaining call to `LOCAL_reflection_map` in mesh construction selects the
vertex permutation; no coordinate-rounded lookup is reachable for a P2 midpoint identity. The
Section M rounding-bucket counterexample is closed without changing topology, geometry, basis or
forms.

### 21.2 Identity, create-once and cumulative resources

The MATLAB allowlist is exactly formal `run-001/execution-001` or preflight
`resource-preflight-001/execution-002`, and the preflight branch returns before formal work
creation (`run_i4_1b.m:32-57`). The controller fixes the same preflight pair in its constants and
batch string, and claims only a previously absent `execution-002` directory with collision failure
(`run_preflight.pl:13-25,60-76`). No source path reads, copies, hashes or otherwise consumes
`execution-001`; its reviewed values enter only as literal prior wall/RSS constants.

The controller freezes

$$
T_{\mathrm{prior}}=18.226698\ \mathrm{s},\qquad
T_{002,\mathrm{remaining}}=2681.773302\ \mathrm{s},\qquad
R_{\mathrm{prior}}=1084440576\ \mathrm{B}
$$

and arms the one absolute current deadline at `start + WALL_LIMIT_SECONDS`
(`run_preflight.pl:15-25,34-58`). Every memory sample is combined as
$\max\{R_{\mathrm{prior}},R_{002}\}$ before comparison with 3,221,225,472 B
(`run_preflight.pl:127-142`). The event ledger reports prior, current and cumulative wall plus
prior, current and cumulative-maximum RSS (`run_preflight.pl:378-402`); the summary carries the
same fields and patches current and cumulative elapsed values from one final elapsed value
(`run_preflight.pl:454-497`). Thus the only wall predicate is cumulative elapsed at least 2700 s,
and memory remains a peak maximum rather than a subtractive allowance.

### 21.3 Preserved boundaries and decision

The preflight dispatch still returns before all formal occurrences of `eig`, `eigs`, `svd`,
spectrum, field, branch, rank and reference construction. Its simultaneous-capacity stages and
five authoritative leaves are unchanged. `run_formal.pl` retains formal
`run-001/execution-001`; the 72 P2 bulk, 47 P2 defect, five P1 companion and conditional 17-call
schedule remains unchanged. `resource-preflight-001/execution-001` remains present only as
immutable historical evidence, while `execution-002` is absent at this static gate.

**Researcher decision: `PASS TO THE SAME SKEPTIC FOR FOCUSED PRE-EXECUTION RE-REVIEW`.** The
strongest prior counterexamples--rounded midpoint misidentification and reset resource accounting--
are no longer reachable in the reviewed source. This PASS does not authorize `execution-002`,
formal science, output creation or any MATLAB/Octave/Python, runner or eigensolve execution.

## 22. Bounded Section O static memory-lifetime diagnosis

Status: **`BLOCKED FOR THIS ROUND / STATIC DIAGNOSIS ONLY / NO REPAIR OR EXECUTION AUTHORIZED`**.

This section diagnoses only the reached preflight representation path. It does not change the
method, source or lifecycle, and it does not reinterpret the consumed hard-resource result.

### 22.1 Established artifact boundary

The following facts are **ESTABLISHED** by immutable `execution-002` artifacts:

- all three bulk representation stages completed, while
  `mesh-defect-N5-s12-g36` emitted only its broad start marker;
- that broad stage reached aggregate process-tree RSS 3,471,147,008 B and MATLAB-process RSS
  3,360,882,688 B, after which the controller produced `RSS_HARD_LIMIT_REACHED` with signal 9;
- current execution wall time was 38.368379 s, so the two consumed preflights give

$$
T_{\mathrm{cum}}=56.595077\ \mathrm{s},\qquad
T_{\mathrm{remaining}}=2643.404923\ \mathrm{s},
$$

and the cumulative peak is

$$
R_{\mathrm{cum}}=3471147008\ \mathrm{B}>3221225472\ \mathrm{B}.
$$

The stage marker is written before `LOCAL_build_mesh`; its completion marker follows every P2/P1
phase reduction (`run_i4_1b.m:250-301`). Therefore the artifacts do **not** locate the peak inside
mesh generation, full-form assembly, phase reduction, sparse Cholesky or overlap between two
successive pair lifetimes. They also do not establish a defect mesh row, reduced `nnz`, factor
fill, spectrum or field.

### 22.2 Source-level simultaneous lifetimes

The following source ownership is **ESTABLISHED statically**:

1. `mesh` remains live throughout every phase. It owns geometry/topology plus the full P2
   stiffness, weighted mass and three localization masses, and the corresponding full P1 forms
   (`run_i4_1b.m:254-271,943-971`).
2. Each P2 reduction constructs a prolongation, then `stiffness_raw` and `mass_raw`, canonicalizes
   both, and performs sparse `chol(canonical)` for the mass SPD gate
   (`run_i4_1b.m:1461-1480,1558-1582`). The returned `pair` retains reduced $K$, reduced $M$,
   prolongation and the Cholesky `mass_factor` (`run_i4_1b.m:1487-1488`). The P1 reducer repeats
   the same ownership pattern (`run_i4_1b.m:1685-1707`).
3. In preflight, P2 and P1 returned pairs are overwritten on every phase, but the loop needs only
   their stiffness/mass `nnz`; the last pairs are retained to the broad completion marker solely
   for byte reporting (`run_i4_1b.m:260-301`).
4. The formal generalized eigensolvers receive only `pair.stiffness` and `pair.mass`
   (`run_i4_1b.m:1585-1607,1712-1733`). No formal eigensolver, residual, field or branch path
   reads the large reduced-operator `pair.mass_factor`. The only explicit field-level source read
   is preflight byte reporting for `anchor_pair.mass_factor` (`run_i4_1b.m:317-326`). Separate
   factors of small cluster Gram matrices do not justify retaining this reduced mass factor.

The following is a **CONDITIONAL implementation-lifetime inference**, not measured substage
evidence: while the right-hand side of a pair overwrite is constructed, the prior returned pair
can remain owned by the caller; constructing the P1 pair also occurs while the current P2 pair and
the full mesh remain live. Sparse Cholesky additionally needs its input, output factor and internal
symbolic/numeric workspace at overlapping times. MATLAB allocator retention can keep RSS above the
sum of objects visible through `whos`. These mechanisms are consistent with the observed peak, but
the broad marker cannot determine their individual contributions.

### 22.3 Why no intrinsic mesh or method conclusion follows

It is **REFUTED** that the current evidence uniquely attributes 3.47 GB to mesh construction. The
same marker includes all phase reductions, and no completion row supplies the first defect mesh's
counts or object bytes. It is likewise **NOT ESTABLISHED** that the frozen fitted $P_2$ method is
intrinsically over 3 GiB: the returned reduced-mass factor is an SPD-validation implementation
object, is absent from the `eigs` interface, and is not a field, branch, candidate or scientific
output. Conversely, it is also not established that removing that retention alone would suffice;
one necessary factorization or an assembly transient may still exceed the cap.

### 22.4 Minimal future repair candidates, not a frozen implementation

The smallest source-local candidates for a later separately authorized design are **PROVISIONAL,
UNIMPLEMENTED AND UNVALIDATED**:

1. preserve the exact SPD gate but return only its pass/fail result from phase reduction; discard
   the Cholesky factor immediately instead of storing `mass_factor` in the returned pair;
2. apply a deterministic fill-reducing symmetric permutation before sparse Cholesky, while checking
   the same positive-definiteness statement and discarding the permuted factor immediately;
3. in zero-eigensolve preflight, extract each phase's required `nnz` diagnostics and clear the P2
   pair before constructing the P1 pair, then clear the P1 pair before the next phase; and
4. if diagnosis remains necessary, split the broad marker into build, P2-reduction, SPD-factor and
   P1-reduction substages without adding a new resource gate or scientific computation.

Any later repair must retain finite/Hermitian/SPD/seam/embedding checks, the same matrices and
phases, and must prove that no factor needed by a scientific consumer was removed. These candidates
do not authorize code changes or imply that a lower-memory result would erase the already consumed
cumulative peak.

### 22.5 Researcher decision

**Researcher verdict: `BLOCKED FOR THIS ROUND / HAND TO THE SAME SKEPTIC FOR FINAL STATIC
REVIEW`.** The hard RSS outcome has been consumed, formal science remains blocked, and no new
execution identity or rerun is authorized. The weakest surviving step is the unmeasured attribution
among factor fill, old/new pair overlap, assembly temporaries and allocator retention; only a future
explicit lifecycle decision plus new Researcher--Engineer--Skeptic gates could test a bounded
repair.
