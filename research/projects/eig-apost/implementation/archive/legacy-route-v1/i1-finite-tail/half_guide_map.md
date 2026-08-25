# Half-guide map Stage 1 design

## Material Passport

- Origin Skill: `academic-research-suite/experiment-agent`
- Origin Mode: `plan`
- Origin Date: 2026-08-02
- Verification Status: `UNVERIFIED`
- Version Label: `eig-apost-half-guide-map-v1.1`
- Repro Lock: `null`
- Git Base: `20b0cd0f4b26`

The governing theory and code-convention files are:

- `research/projects/eig-apost/phase3-analysis/s-dtn-chain.md`;
- `research/projects/eig-apost/phase3-analysis/s-root.md`;
- `research/projects/eig-apost/phase3-analysis/p-implement.md`;
- `+bloch/construct_S.m`;
- `+bloch/solve_modes.m`.

This document freezes the Stage 1 linear-algebra experiment. It does not replace the
existing manufactured NEP records in this directory.

## Scope and evidence level

Stage 1 validates the map chain

```text
one-cell scattering blocks
  -> Redheffer composition and doubling
  -> finite-tail terminal reflection maps
  -> Cayley DtN matrices
  -> comparison with a generalized-QZ invariant graph
```

There are three fixtures.

1. **Fixture A0, noncommuting algebra.** Fixed $2\times2$ blocks test the Redheffer and
   terminal eliminations directly. A separate noncommuting trace fixture tests the Cayley
   multiplication order.
2. **Case A, analytic gap cell.** A nondegenerate unitary reciprocal diagonal scattering
   cell has finite stable and unstable multipliers and exact half-guide maps. This is the
   independent algebraic truth case.
3. **Case B, one real EDC cell.** `bloch.construct_S` supplies the one-cell blocks and a
   generalized-QZ construction supplies the limiting invariant graph. Doubling and QZ use
   the same one-cell matrix. Their agreement is an internal cross-check of infinity
   treatment, not independent physical DtN truth.

No center coupling, guided-mode root, projected eigenvalue estimator, BIE kernel--field
equivalence, map-convergence theorem, or certified interval is tested here.

## Frozen scattering convention

For every segment,

$$
  \begin{bmatrix}b^L\\a^R\end{bmatrix}
  =
  \begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
  \begin{bmatrix}a^L\\b^R\end{bmatrix}.
$$

The amplitudes $a$ travel in the positive $x$ direction and the amplitudes $b$ travel in
the negative $x$ direction. The subscripts $L,R$ name the walls of a segment. They do not
name the two half-guides.

All four blocks are square $K\times K$ matrices with the same Rayleigh ordering and
normalization at every level. The representation identifier, row and column ordering,
port phase origins, and scaling fingerprints are immutable.

## Redheffer composition and doubling

Let segment $A$ lie to the left of segment $B$. With interface amplitudes $a_1,b_1$,

$$
\begin{aligned}
  b_0&=R_L^A a_0+T_{RL}^A b_1, &
  a_1&=T_{LR}^A a_0+R_R^A b_1,\\
  b_1&=R_L^B a_1+T_{RL}^B b_2, &
  a_2&=T_{LR}^B a_1+R_R^B b_2.
\end{aligned}
$$

Define the two noncommuting Schur factors

$$
  G_A=I-R_R^A R_L^B,
  \qquad
  G_B=I-R_L^B R_R^A.
$$

Direct elimination gives

$$
\begin{aligned}
  R_L^{AB}
  &=R_L^A+T_{RL}^A R_L^B G_A^{-1}T_{LR}^A,\\
  T_{LR}^{AB}
  &=T_{LR}^B G_A^{-1}T_{LR}^A,\\
  T_{RL}^{AB}
  &=T_{RL}^A G_B^{-1}T_{RL}^B,\\
  R_R^{AB}
  &=R_R^B+T_{LR}^B G_A^{-1}R_R^A T_{RL}^B.
\end{aligned}
$$

The implementation must use linear solves and must not form an explicit inverse. Each
formula is checked against a raw sequential solve of the four interface equations above;
the oracle may not call the composed-block formula. Both $G_A$ and $G_B$, their reciprocal
condition estimates, and their solve residuals enter the pole ledger.

One doubling step uses $A=B$. Starting from one cell, level $j$ represents

$$
  N_j=2^j
$$

cells. Fixture A0 supplies the raw-equation composition oracle, while Case A supplies exact
one-cell, multiplier, limiting reflection, and DtN oracles. Associativity is checked by
comparing $(S_A\star S_B)\star S_C$ with $S_A\star(S_B\star S_C)$.

## Terminal reflection maps

The terminal object is a returned-to-outgoing amplitude map $C$. The convention is frozen
as

$$
  b_f^+=C a_f^+
  \quad\hbox{at the right far wall},
  \qquad
  a_f^-=C b_f^-
  \quad\hbox{at the left far wall}.
$$

The three closures are:

$$
  C_0=0
  \quad\hbox{(zero incoming)},
  \qquad
  C_{\mathrm D}=-I
  \quad\hbox{(Dirichlet)},
$$

and one frozen real Robin closure. Let the outward-normal terminal condition be

$$
  N+\zeta D=0,
  \qquad \zeta=0.7.
$$

With $D=a+b$ and the appropriate terminal outward normal on each side, both amplitude
roles give

$$
  C_{\mathrm R}
  =(\mathrm{i}\Gamma-\zeta I)^{-1}
   (\mathrm{i}\Gamma+\zeta I).
$$

### Pre-formal Robin amendment

The first complete smoke run used $\zeta=1$ and exposed an exact terminal resonance in
Case A. For a scalar channel with positive real $\gamma$ and exact stable reflection
$R_+=\mathrm{i}$,

$$
  C_\zeta=(\mathrm{i}\gamma-\zeta)^{-1}(\mathrm{i}\gamma+\zeta),
  \qquad
  1-C_\zeta R_+=0
  \quad\Longleftrightarrow\quad
  \zeta=\gamma.
$$

The first analytic channel has $\gamma=1$, so the old value $\zeta=1$ gives
$C_\zeta=-\mathrm{i}$. The analytic stable vector is $(1,\mathrm{i})^{\mathsf T}$ and the
unstable vector is $(\mathrm{i},1)^{\mathsf T}$. Hence the far condition
$b_f=-\mathrm{i}a_f$ selects the unstable graph and can drive the center reflection to the
wrong branch $-\mathrm{i}$ rather than the target $+\mathrm{i}$. The vanishing terminal
factor is therefore a genuine failure, not a condition-number artifact that may be
exempted.

Before the formal run, the production Robin parameter is uniformly changed to
$\zeta=0.7$. This preserves the Robin formulation, all map formulas, and every threshold;
it only moves the auxiliary cross-check away from the exact channel resonance. For the
Case A channels $\gamma=1,2$,

$$
  |1-\mathrm{i}C_\zeta|
  =\frac{\sqrt{2}|\gamma-\zeta|}{\sqrt{\gamma^2+\zeta^2}}>0.
$$

No terminal condition-number exemption is permitted. The failed smoke run must remain
preserved and linked from the final report. The old $\zeta=1$ configuration becomes the
mandatory `TERMINAL_RESONANCE` negative case and all of its downstream map and DtN
quantities are unavailable.

For an $N$-cell segment, the right and left center-facing reflection maps are

$$
  \widehat R_{+,N}(C)
  =R_{L,N}
   +T_{RL,N}(I-C R_{R,N})^{-1}C T_{LR,N},
$$

$$
  \widehat R_{-,N}(C)
  =R_{R,N}
   +T_{LR,N}(I-C R_{L,N})^{-1}C T_{RL,N}.
$$

This exact order is frozen. Although
$(I-CR)^{-1}C=C(I-RC)^{-1}$ when both sides exist, the implementation uses the displayed
form only. A separate direct-elimination oracle solves the raw scattering equations plus
the terminal relation and must not reuse this formula.

For $C=-I$, the formulas reduce to the Phase 3 Dirichlet maps. For $C=0$, they reduce to
$R_{L,N}$ and $R_{R,N}$.

## Center-facing Cayley DtN maps

At the right center port, $a_c^+$ travels into the lead and
$b_c^+=\widehat R_{+,N}a_c^+$ returns. At the left center port, $b_c^-$ travels into the
lead and $a_c^-=\widehat R_{-,N}b_c^-$ returns. The center-domain outward normals are
$+\partial_x$ on the right and $-\partial_x$ on the left. Both sides therefore give

$$
  \Lambda_{\pm,N}
  =\mathrm{i}\Gamma
   (I-\widehat R_{\pm,N})
   (I+\widehat R_{\pm,N})^{-1}.
$$

The multiplication order is part of the definition: $\Gamma$ remains leftmost and the
factor $(I+\widehat R)^{-1}$ is applied on the right. A left solve would define a different
operator when $\Gamma$ and $\widehat R$ do not commute. The implementation uses a right
linear solve and records `rcond(I + Rhat)` and the solve residual.

## Generalized-QZ invariant-graph reference

The one-cell pencil is exactly the pencil used by `bloch.solve_modes`:

$$
  A_{\mathrm{sc}}
  =\begin{bmatrix}-R_L&I\\T_{LR}&0\end{bmatrix},
  \qquad
  B_{\mathrm{sc}}
  =\begin{bmatrix}0&T_{RL}\\I&-R_R\end{bmatrix},
$$

$$
  A_{\mathrm{sc}}v=\lambda B_{\mathrm{sc}}v,
  \qquad
  v=\begin{bmatrix}a_L\\b_L\end{bmatrix}.
$$

Generalized Schur selection is performed without first classifying an indeterminate pair
as a finite multiplier. If $\mathsf S_{ii},\mathsf T_{ii}$ are the ordered generalized
Schur diagonal pairs, use `qz_pair_tol=1e-12`. A pair is numerically indeterminate when

$$
  |\mathsf S_{ii}|+|\mathsf T_{ii}|
  \le 10^{-12}\max(1,\|A_{\mathrm{sc}}\|_F,\|B_{\mathrm{sc}}\|_F),
$$

and it is infinite when it is not indeterminate and

$$
  |\mathsf T_{ii}|
  \le 10^{-12}\max(|\mathsf S_{ii}|,|\mathsf T_{ii}|).
$$

A valid reference requires a numerically regular pencil, no infinite or indeterminate
modes, exactly $K$ finite stable and $K$ finite unstable multipliers, and no neutral
multipliers. This is a numerical fixed-matrix regularity gate, not a theorem about an
analytic pencil.

Let the right stable Schur subspace be

$$
  Z_s=\begin{bmatrix}A_s\\B_s\end{bmatrix},
  \qquad |\lambda|<1.
$$

If $A_s$ is square and nonsingular, the right half-guide graph is

$$
  R_+^{\mathrm{QZ}}=B_s A_s^{-1}.
$$

Let the left-decaying, positive-$x$ unstable subspace be

$$
  Z_u=\begin{bmatrix}A_u\\B_u\end{bmatrix},
  \qquad |\lambda|>1.
$$

If $B_u$ is square and nonsingular, the left half-guide graph is

$$
  R_-^{\mathrm{QZ}}=A_u B_u^{-1}.
$$

Both are right solves. The QZ ledger records pencil regularity, finite/infinite/indeterminate
counts, stable/unstable/neutral counts, generalized invariant residuals, unit-circle
separation, and the reciprocal condition estimates of $A_s$ and $B_u$.

Use two ordered-QZ passes: one orders the stable set first and the other orders the unstable
set first. In each pass, $Q_{\mathcal D},Z_{\mathcal D}$ are the leading $K$ left and right
Schur vectors and $\mathsf S_{\mathcal D},\mathsf T_{\mathcal D}$ are the leading
$K\times K$ Schur blocks. This avoids treating the trailing block of one upper-triangular
Schur form as an invariant subspace. For $\mathcal D\in\{s,u\}$, freeze the residual as

$$
\begin{aligned}
  r_{A,\mathcal D}
  &=\frac{\|A_{\mathrm{sc}}Z_{\mathcal D}
       -Q_{\mathcal D}\mathsf S_{\mathcal D}\|_F}
      {\max(1,\|A_{\mathrm{sc}}\|_F\|Z_{\mathcal D}\|_F
       +\|\mathsf S_{\mathcal D}\|_F)},\\
  r_{B,\mathcal D}
  &=\frac{\|B_{\mathrm{sc}}Z_{\mathcal D}
       -Q_{\mathcal D}\mathsf T_{\mathcal D}\|_F}
      {\max(1,\|B_{\mathrm{sc}}\|_F\|Z_{\mathcal D}\|_F
       +\|\mathsf T_{\mathcal D}\|_F)}.
\end{aligned}
$$

All four residuals enter the QZ gate.

The invariant graphs must also satisfy the same fixed-point equations used by an infinite
terminal. Freeze

$$
\begin{aligned}
  \mathcal R_+
  &=R_+^{\mathrm{QZ}}-R_L
    -T_{RL}(I-R_+^{\mathrm{QZ}}R_R)^{-1}
      R_+^{\mathrm{QZ}}T_{LR},\\
  \mathcal R_-
  &=R_-^{\mathrm{QZ}}-R_R
    -T_{LR}(I-R_-^{\mathrm{QZ}}R_L)^{-1}
      R_-^{\mathrm{QZ}}T_{RL}.
\end{aligned}
$$

The normalized Frobenius norms of these residuals must not exceed `1e-10`. The factors
$I-R_+^{\mathrm{QZ}}R_R$ and $I-R_-^{\mathrm{QZ}}R_L$ enter the pole ledger with the
same `1e-10` reciprocal-condition threshold.

The reference DtN matrices use the same frozen Cayley formula. In Case B they remain
same-cell internal references, not independent physical truth.

## Frozen fixtures and cases

### Fixture A0: noncommuting elimination and Cayley order

The direct-elimination fixture uses $K=2$ and the following fixed complex blocks:

$$
\begin{aligned}
R_L^A&=\begin{bmatrix}0.10+0.02\mathrm{i}&0.03\\-0.02\mathrm{i}&0.08-0.01\mathrm{i}\end{bmatrix},&
R_R^A&=\begin{bmatrix}0.05&-0.02+0.01\mathrm{i}\\0.04&0.07\end{bmatrix},\\
T_{LR}^A&=\begin{bmatrix}0.85&0.06-0.02\mathrm{i}\\-0.03+0.01\mathrm{i}&0.80\end{bmatrix},&
T_{RL}^A&=\begin{bmatrix}0.82&-0.04\mathrm{i}\\0.05+0.02\mathrm{i}&0.78\end{bmatrix},\\
R_L^B&=\begin{bmatrix}0.06-0.01\mathrm{i}&-0.03\\0.02+0.04\mathrm{i}&0.09\end{bmatrix},&
R_R^B&=\begin{bmatrix}0.07&0.01+0.03\mathrm{i}\\-0.04&0.05+0.02\mathrm{i}\end{bmatrix},\\
T_{LR}^B&=\begin{bmatrix}0.79&0.02+0.03\mathrm{i}\\-0.05\mathrm{i}&0.83\end{bmatrix},&
T_{RL}^B&=\begin{bmatrix}0.81&-0.02+0.01\mathrm{i}\\0.04&0.77\end{bmatrix}.
\end{aligned}
$$

The oracle solves the raw four interface equations for the four canonical exterior inputs.
It does not call the Redheffer helper. The same requirement applies to the raw right and
left terminal equations.

For the Cayley-order check, use

$$
  \Gamma_0=\operatorname{diag}(0.7+0.2\mathrm{i},1.3+0.1\mathrm{i}),
  \qquad
  \widehat R_0=
  \begin{bmatrix}0.10&0.20\\-0.05\mathrm{i}&0.15\end{bmatrix}.
$$

For both canonical outgoing amplitude vectors, the computed matrix must satisfy directly

$$
  \Lambda_0(a+\widehat R_0a)
  =\mathrm{i}\Gamma_0(a-\widehat R_0a).
$$

This fixture is deliberately noncommuting. A formula that moves $\Gamma_0$ or applies the
Cayley inverse on the left must fail the direct identity.

### Case A: analytic unitary reciprocal gap cell

Use

| parameter | value |
|---|---:|
| channel count $K$ | `2` |
| $\rho$ | `[0.6,0.8]` |
| $\Gamma$ | `diag([1,2])` |
| levels | `0:6` |
| Robin $\zeta$ | `0.7` |

Let

$$
  r=\mathrm{i}\rho,
  \qquad
  t=\sqrt{1-\rho^2},
$$

with the square root taken entrywise and positive. The exact one-cell blocks are

$$
  R_L=R_R=\operatorname{diag}(r),
  \qquad
  T_{LR}=T_{RL}=\operatorname{diag}(t).
$$

The cell is nondegenerate, unitary, and reciprocal. Its exact stable multipliers and their
unstable reciprocals are

$$
  \vartheta=\sqrt{\frac{1-\rho}{1+\rho}}
  =\begin{bmatrix}1/2&1/3\end{bmatrix},
  \qquad
  \vartheta^{-1}=\begin{bmatrix}2&3\end{bmatrix}.
$$

The exact right and left half-guide reflection maps and DtN matrices are

$$
  R_+^{\mathrm{exact}}=R_-^{\mathrm{exact}}=\mathrm{i}I,
  \qquad
  \Lambda_+^{\mathrm{exact}}=\Lambda_-^{\mathrm{exact}}=\Gamma.
$$

The three finite terminal sequences must converge to these maps. This case is the only
independent exact gap truth for Stage 1. An empty propagation cell may be retained only as
a non-governing block-order sanity check; it must not replace this case or its gates.

### Case B: real EDC one-cell smoke test

Freeze

| parameter | value |
|---|---:|
| $\beta$ | `0.8` |
| exterior $k$ | `0.10` |
| refractive-index ratio | `3` |
| interior $k$ | `0.30` |
| circle radius | `0.4` |
| $L$ | `2` |
| $d$ | `2*pi` |
| $M$ | `7` |
| $K$ | `15` |
| `ntot` | `60` |
| walls | `X_L=-1`, `X_R=1` |
| levels | `0:6` |
| Robin $\zeta$ | `0.7` |

The circle is centered at the origin. The quasi-periodic Green/proxy parameters are
`periodic_axis='y'`, `H=1.8`, `proxy_dist=0.7`, `N_side=40`, `N_top=40`,
`N_proxy_edge=24`, and `M_pw=8`. No artificial absorption is added.

The pre-run screening evidence supplied by the user for this point is:

- 15 stable and 15 unstable multipliers;
- minimum unit-circle separation approximately `0.279`;
- `rcond(A_QP)` approximately `0.239`.

The provenance label is `USER_SUPPLIED_PRIOR_SCREENING`. No independent stored gap truth
was identified for this task. These values are not assumed as truth; the formal run must
reproduce the gates below using the same one-cell data, and the result remains a one-point
same-cell smoke test.
Because $\beta_m=\beta+m$, the minimum channel magnitude at $k=0.10$ is

$$
  \min_m|\gamma_m|
  =\sqrt{0.2^2-0.1^2}
  =\sqrt{0.03}
  \approx0.173205.
$$

The separate point $k=0.20$ is not a formal map case. The run first constructs only the
channel metadata. For $m=-1$,
$\beta_{-1}=-0.2$ and $\gamma_{-1}=0$, so it is a Wood/cutoff point. Its reported
`rcond(A_QP)` is also approximately $4.9\times10^{-6}$. The run must label it both
`WOOD_POINT` and `CELL_BIE_POLE_RISK` and stop before the cell BIE solve, QZ, or map
interpretation. `WOOD_POINT` is the observed primary stop label;
`CELL_BIE_POLE_RISK` is retained with provenance `USER_SUPPLIED_PRIOR_SCREENING`, not
recomputed after the stop. An apparent multiplier split there is not projected-gap
evidence.

## Data contract

The entry point returns one result structure with:

- `results.config`: frozen inputs, thresholds, representation fingerprints, and source
  hashes;
- `results.case_a`: exact one-cell data, doubled blocks, terminal maps, DtN maps, QZ data, and
  exact-oracle errors;
- `results.case_b`: one-cell BIE diagnostics, doubled blocks, terminal maps, QZ data, and
  same-cell cross-check errors;
- `results.pole_ledger`: every BIE, Redheffer, terminal, Cayley, and graph factor;
- `results.negative_cases`: at least the Wood/BIE-risk exclusion, the shared-gate
  `TERMINAL_RESONANCE`, and direct convention failures;
- `results.all_pass`: conjunction of all mandatory gates.

Every map is stored separately by case, level, side, and closure. Raw complex matrices are
saved before norms are formed. Unavailable downstream values are `NaN` with a stable stop
label, never zero.

## Frozen gates

### Common algebra gates

- Every scattering block is $K\times K$ and finite.
- Sequential raw-equation response versus composed-block response has relative error at
  most `1e-11`.
- Fixture A0 raw-equation versus composed-block relative error is at most `1e-11`.
- Three-segment associativity has relative block error at most `1e-10`.
- Every recorded linear-solve relative residual is at most `1e-11`.
- Every Redheffer, terminal, and Cayley reciprocal condition estimate is at least `1e-10`.
- Any common-representation fingerprint change stops the hierarchy.

### Non-Wood and one-cell gates

- The formal Case B point satisfies `min(abs(gamma_m)) >= 0.1`.
- `rcond(A_QP) >= 1e-2`.
- The BIE multi-right-hand-side relative residual is at most `1e-10`.
- The $k=0.20$ exclusion is recognized before any map or QZ quantity is made available.
- The Case A $\zeta=1$ negative case fails the unchanged terminal-factor gate with
  `TERMINAL_RESONANCE`; downstream map and DtN values are unavailable.

### QZ gates

- The pencil is regular and has no infinite or indeterminate generalized eigenvalues.
- Exactly $K$ finite stable and $K$ finite unstable multipliers are present; the neutral
  count is zero.
- The minimum $||\lambda|-1|$ is at least `1e-1`.
- Every normalized generalized invariant residual is at most `1e-10`.
- `rcond(A_s) >= 1e-10` and `rcond(B_u) >= 1e-10`.
- Both fixed-point residuals are at most `1e-10`, and both fixed-point factors have
  reciprocal condition estimates at least `1e-10`.
- Case A QZ multiplier-set errors against
  $\{1/2,1/3,2,3\}$, graph-map errors against $\mathrm{i}I$, and exact-DtN errors against
  $\Gamma$ are at most `1e-10`.

### Terminal-map and DtN gates

- Fixture A0 direct Redheffer, terminal, and Cayley identity errors are at most `1e-11`.
- In Case A, the final $N=64$ zero-incoming, Dirichlet, and Robin reflection-map errors
  against $\mathrm{i}I$ and DtN errors against $\Gamma$ are at most `1e-10`.
- In Case B, for each side and each closure, the final $N=64$ reflection map differs from
  its QZ graph by at most `1e-8` in relative Frobenius norm.
- In Case B, each final DtN map differs from the QZ-based DtN by at most `1e-8`.
- The final pairwise spread among zero-incoming, Dirichlet, and Robin maps is at most
  `1e-8` on each side.
- Over the last three available levels, each error is nonincreasing up to an absolute
  numerical floor of `1e-12`.

Transmission decay, reciprocity or flux defects, closure-to-closure trajectories, and
`ntot` sensitivity are reported as diagnostics. They are not independent truth and are
not silently promoted to gates.

## Pole and conditioning ledger

Each ledger row records:

- case, level, $N$, side, and closure;
- factor name and matrix size;
- reciprocal condition estimate;
- relative solve or invariant residual;
- applicable threshold;
- `PASS`, `REVISE`, or the stable stop label.

Mandatory entries are `A_QP`, both Redheffer Schur factors at every composition, both
terminal factors for every nonzero closure, every Cayley factor, the generalized-QZ
pencil status, and the graph blocks $A_s,B_u$. A good condition estimate at sampled nodes
does not prove absence of an unsampled analytic pole; Stage 1 makes only fixed-$k$ claims.

## Output and reproducibility contract

The implementation belongs under `test/hg-map/` and writes only below its own
`output/` directory. Required artifacts are:

- `config.txt`;
- `levels.csv`;
- `closures.csv`;
- `qz-reference.csv`;
- `pole-ledger.csv`;
- `negative-cases.csv`;
- `convergence.svg`, written without GUI plotting;
- `run.log`;
- `results.mat`;
- `report.md`;
- `reproducibility.txt` after two successful identical runs.

The report must state that Case B is a one-point real implementation smoke test and
same-cell infinity cross-check. It must not call the QZ result independent physical truth,
must not call $k=0.20$ a gap point, and must not claim a physical DtN accuracy theorem.

## Stage decision

- **GO:** Fixture A0, both cases, and every mandatory ledger and exclusion gate pass. The
  allowed claim is that the half-guide map linear-algebra chain has an initial
  implementation and that the selected EDC point passes a same-cell internal
  infinity-treatment cross-check.
- **REVISE:** Case A passes, but Case B has well-defined, non-Wood, regular one-cell data
  and fails closure convergence, graph conditioning, or the same-cell QZ comparison.
- **STOP:** the scattering convention, direct elimination, Case A exact oracle, non-Wood
  gate, one-cell BIE gate, QZ regularity/count, or representation invariant fails.

The Engineer's minimal plan was confirmed against this freeze on 2026-08-02. Implementation
is authorized only under `test/hg-map/`; the Engineer may not modify this design or the
governing theory files.
