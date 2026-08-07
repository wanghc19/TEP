# Half-guide map skeptic review

## Material Passport

- Origin role: independent Research Skeptic
- Review stage: Stage 1, pre-implementation
- Review date: 2026-08-02
- Verification status: `INDEPENDENTLY REVIEWED / IMPLEMENTATION PENDING`
- Governing theory:
  [[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]],
  [[research/projects/eig-apost/phase3-analysis/s-root|root qualification]], and
  `research/projects/eig-apost/phase4-report/method.tex`

## 1. Audit frame

The target is the proposed route

$$
  S_{\mathrm{cell}}
  \longrightarrow S_{2^j}
  \longrightarrow \widehat R_{\pm,j}
  \longrightarrow \Lambda_{\pm,j},
$$

with an ordered-QZ half-guide reflection map used as a same-cell-map limit
cross-check.  This stage asks whether the scattering convention, noncommuting
Redheffer products, terminal closure, normal signs, Cayley transform, and QZ
stable/unstable graph formulas are specified tightly enough to implement and
falsify.

The material inspected comprises the governing Phase 3/report formulas and the
current `bloch.construct_S`, `bloch.solve_modes`, `bloch.mode_traces`, and
`bloch.select_port_traces` interfaces.  No half-guide implementation or result
exists yet.  Parameter-screening values supplied for the proposed real case are
treated as claims to be reproduced by the experiment, not as authority.

The analytic case is allowed to validate matrix algebra and conventions only.
The real BIE case may validate integration of the existing cell solver into the
map pipeline, but it does not by itself provide independent physical DtN truth.

## 2. Stage 1 verdict

**PASS WITH CONDITIONS -- GO FOR IMPLEMENTATION, high confidence.**

The paper formulas are mutually consistent under the stated scattering
convention, and the main finite-QZ analytic oracle in Section 3.5 is correct.
The Researcher and Engineer have accepted the hard conditions in Sections 4--6
as the implementation contract, including separate noncommuting algebra tests.
Implementation may therefore start.  Passing the future numerical stage remains
conditional on those gates being present in the written plan and actual shared
code paths.  In particular, the diagonal main oracle alone would not falsify the
most likely ordering errors, and the proposed $k=0.20$ case is a Wood/cutoff
point as well as an `A_QP` conditioning failure.

## 3. Formula audit

### 3.1 Scattering convention and Redheffer composition

The only admissible block convention is

$$
  \begin{bmatrix}b^L\\a^R\end{bmatrix}
  =
  \begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
  \begin{bmatrix}a^L\\b^R\end{bmatrix}.
$$

For segment $A$ followed by segment $B$, direct elimination of the two internal
amplitudes gives

$$
\begin{aligned}
  R_L^{AB}
  &=R_L^A+T_{RL}^A R_L^B
    (I-R_R^A R_L^B)^{-1}T_{LR}^A,\\
  T_{LR}^{AB}
  &=T_{LR}^B(I-R_R^A R_L^B)^{-1}T_{LR}^A,\\
  T_{RL}^{AB}
  &=T_{RL}^A(I-R_L^B R_R^A)^{-1}T_{RL}^B,\\
  R_R^{AB}
  &=R_R^B+T_{LR}^B(I-R_R^A R_L^B)^{-1}
    R_R^A T_{RL}^B.
\end{aligned}
$$

These formulas agree with the Phase 3 authority.  Their multiplication order is
essential.  The implementation must use linear solves and ledger both Schur
factors; an oracle obtained by copying these four formulas is not independent.
The oracle must instead solve the unreduced internal-amplitude equations for
multiple right-hand sides.

### 3.2 Unified terminal reflection convention

Freeze the terminal operator $C$ as the map from the outgoing far-wall
amplitude to the returning amplitude:

$$
  b_f^R=C_+a_f^R
  \quad\hbox{on the right},
  \qquad
  a_f^L=C_-b_f^L
  \quad\hbox{on the left}.
$$

With this definition,

$$
\begin{aligned}
  \widehat R_+
  &=R_L+T_{RL}(I-C_+R_R)^{-1}C_+T_{LR},\\
  \widehat R_-
  &=R_R+T_{LR}(I-C_-R_L)^{-1}C_-T_{RL}.
\end{aligned}
$$

The equivalent forms with $C(I-RC)^{-1}$ are valid, but the code and ledger
must select one form rather than silently commute $C$ and $R$.  The direct
terminal oracle must solve the original scattering and boundary equations.

The closures are

$$
  C=0 \quad\hbox{(zero incoming)},
  \qquad
  C=-I \quad\hbox{(Dirichlet)}.
$$

For the same real Robin condition on each far boundary,

$$
  \partial_{n_f}u+\zeta u=0,
  \qquad \zeta\in\mathbb R,
$$

the outward normals are $+e_x$ at the right far wall and $-e_x$ at the left
far wall.  With $D=a+b$ and $\partial_xu=\mathrm{i}\Gamma(a-b)$, both sides
therefore give

$$
  C=(\mathrm{i}\Gamma-\zeta I)^{-1}
    (\mathrm{i}\Gamma+\zeta I).
$$

The Robin parameter and its units must be frozen; the proposed first check uses
$\zeta=1$.  The actual solve factor, its algebraically paired factor, solve
residual, and reciprocal condition estimate belong in the pole ledger.

### 3.3 Center outward normals and the DtN Cayley map

At the center right port, $b=\widehat R_+a$ and the outward normal is $+e_x$.
At the center left port, $a=\widehat R_-b$ and the outward normal is $-e_x$.
Both yield

$$
  \Lambda_\pm
  =\mathrm{i}\Gamma(I-\widehat R_\pm)
   (I+\widehat R_\pm)^{-1}.
$$

The common appearance does not assume symmetric leads.  The order is part of
the definition: $\Gamma$ stays leftmost and $(I+\widehat R)^{-1}$ acts on the
right.  A MATLAB left solve of the full numerator would compute a different
operator for noncommuting matrices.  The analytic test must therefore use a
noncommuting $\Gamma$ and reflection map and compare against the raw
Dirichlet/Neumann relation.

### 3.4 Ordered-QZ graph maps

The current cell pencil is

$$
  A_{\mathrm{sc}}
  =\begin{bmatrix}-R_L&I\\T_{LR}&0\end{bmatrix},
  \qquad
  B_{\mathrm{sc}}
  =\begin{bmatrix}0&T_{RL}\\I&-R_R\end{bmatrix},
$$

with eigenvector state $v=(a_L,b_L)^{\mathsf T}$ and
$A_{\mathrm{sc}}v=\lambda B_{\mathrm{sc}}v$.  If an ordered right-decaying
invariant subspace is partitioned as

$$
  Z_s=\begin{bmatrix}A_s\\B_s\end{bmatrix},
  \qquad |\lambda|<1,
$$

then the right half-guide map is

$$
  R_+=B_sA_s^{-1}.
$$

For the positive-$x$ pencil, left decay is represented by the unstable cluster

$$
  Z_u=\begin{bmatrix}A_u\\B_u\end{bmatrix},
  \qquad |\lambda|>1,
$$

and the left half-guide map is

$$
  R_-=A_uB_u^{-1}.
$$

These quotients are available only if the pencil is regular, the stable and
unstable subspaces each have dimension $K$, no neutral or indeterminate mode is
present, and $A_s$ and $B_u$ are full rank and acceptably conditioned.  Sorting
individual eigenvectors is not a substitute for an ordered invariant subspace
when multipliers cluster.

### 3.5 Main exact analytic gap oracle

For each of two uncoupled channels, take

$$
  S_\rho=
  \begin{bmatrix}\mathrm{i}\rho&t\\t&\mathrm{i}\rho\end{bmatrix},
  \qquad
  t=\sqrt{1-\rho^2},
  \qquad
  \rho\in\{0.6,0.8\}.
$$

This scattering matrix is nonsingular, unitary, and reciprocal.  For the right
graph $b=\mathrm{i}a$, the cell equations give

$$
  \lambda=\frac{t}{1+\rho}
  =\sqrt{\frac{1-\rho}{1+\rho}}=:\vartheta.
$$

For the left graph $a=\mathrm{i}b$, they give

$$
  \lambda=\frac{t}{1-\rho}=\vartheta^{-1}.
$$

Thus $\vartheta=1/2,1/3$, the reciprocal multipliers are $2,3$, and all are
finite and separated from the unit circle.  The exact half-guide reflections
are

$$
  R_+=R_-=\mathrm{i}I.
$$

For real positive diagonal $\Gamma$,

$$
  \mathrm{i}\Gamma(I-\mathrm{i}I)(I+\mathrm{i}I)^{-1}
  =\Gamma.
$$

This is the correct main exact oracle for QZ selection, graph direction,
doubling convergence, and the Cayley value.  Because it is diagonal and
commutes with $\Gamma$, it does not test noncommuting product order.  The full
$K\ge2$ noncommuting direct-elimination and Cayley cases in Findings 1--3 are
therefore mandatory complements, not optional diagnostics.  Empty propagation
with $R_\infty=0$ may be retained only as an additional sanity check.

### 3.6 Pre-formal Robin-resonance amendment

The first implementation attempt exposed an exact resonance in the originally
proposed Robin fixture.  For one diagonal channel of the main analytic case,

$$
  \gamma=1,
  \qquad
  \zeta=1,
  \qquad
  C=\frac{\mathrm{i}\gamma+\zeta}
          {\mathrm{i}\gamma-\zeta}=-\mathrm{i}.
$$

Since the exact half-guide reflection is $R_\infty=\mathrm{i}$,

$$
  1-C R_\infty=0.
$$

This is not a harmless conditioning diagnostic.  Write the state after $N$
cells as a combination of the stable and unstable eigenvectors,

$$
  \begin{bmatrix}a_N\\b_N\end{bmatrix}
  =A\vartheta^N\begin{bmatrix}1\\\mathrm{i}\end{bmatrix}
   +B\vartheta^{-N}\begin{bmatrix}\mathrm{i}\\1\end{bmatrix}.
$$

The resonant far condition $b_N=-\mathrm{i}a_N$ forces $A=0$ and retains the
unstable component.  Consequently the center reflection is

$$
  \frac{b_0}{a_0}=-\mathrm{i},
$$

not the target $+\mathrm{i}$.  Apparent cancellation in the terminated formula,
or stabilization of successive finite maps, can therefore converge to the
wrong branch.  The zero reciprocal condition estimate is a true stop signal and
must not receive an exemption.

The Robin closure is an auxiliary cross-check rather than a change to the
underlying cell, QZ oracle, Dirichlet hierarchy, or theory.  It is therefore
legitimate, before the formal run, to replace the accidentally resonant fixture
by the single preselected real value

$$
  \zeta=0.7.
$$

For $\Gamma=\operatorname{diag}(1,2)$ this is separated from both channel
values.  The amendment is acceptable only if the failed first run is preserved,
the version/configuration change is recorded before the formal run, every
conditioning threshold remains unchanged, and no further adaptive Robin tuning
is allowed.  The old $\zeta=1$ case must remain as a mandatory
`TERMINAL_RESONANCE` negative case executed through the shared terminal gate;
all downstream map and Cayley quantities are then `unavailable`.

## 4. Blocking findings

1. **MAJOR -- noncommuting direct-elimination oracle required.**  Use $K\ge2$
   full complex, nonsymmetric blocks.  All four composed blocks must be compared
   with a direct internal-amplitude solve.  Scalar, diagonal, commuting, or
   mirror-symmetric data cannot detect the principal order errors.
2. **MAJOR -- terminal convention and signs must be single-sourced.**  The design,
   symbol ledger, code fields, and report must all use the $C$ convention above.
   Dirichlet, Robin, and zero-incoming closures must pass separate right and left
   direct-elimination tests.  Section 3.6's zero-rcond Robin case cannot be
   exempted merely because a reduced expression appears to cancel.
3. **MAJOR -- Cayley right multiplication must be falsifiable.**  A noncommuting
   test must fail if the denominator is applied on the left or if $\Gamma$ is
   moved through the reflection map.
4. **MAJOR -- QZ availability is conditional.**  Hard gates must cover pencil
   regularity, generalized invariant-subspace residual, finite/neutral mode
   counts, unit-circle separation, and the conditioning of $A_s$ and $B_u$.
   Failed gates propagate `unavailable`; no pseudoinverse may silently create a
   reflection map.
5. **CRITICAL IF MISCLASSIFIED -- $k=0.20$ is not a gap test.**  With
   $\beta=0.8$ and $d=2\pi$, the $m=-1$ transverse wavenumber is $-0.2$.
   Hence at $k=0.20$,

   $$
     \gamma_{-1}=\sqrt{k^2-(\beta-1)^2}=0.
   $$

   This is a Wood/cutoff point, and the reported
   `rcond(A_QP) approximately 4.9e-6` separately indicates a cell-BIE pole risk.
   It must stop before map or QZ interpretation and be labelled accordingly;
   an apparent multiplier split cannot rescue it.
6. **MAJOR -- one real point supports only a smoke claim.**  The proposed
   $k=0.10$ screen reports 15 stable and 15 unstable multipliers, minimum
   unit-circle separation about $0.279$, and `rcond(A_QP)` about $0.239$ for
   $M=7$ and `ntot=60`.  The formal run must reproduce these diagnostics and a
   non-Wood margin.  They can support a one-point integration check, not a
   general gap theorem, BIE convergence claim, or independent physical DtN
   accuracy statement.
7. **MAJOR -- a complete pole and representation ledger is mandatory.**  The
   gate must cover `A_QP`, every pair of doubling Schur factors, both terminal
   factors, every $I+\widehat R$ Cayley factor, the QZ pencil, and the graph
   blocks.  The representation fingerprint must include dimension, block
   order, Rayleigh-mode order, $\Gamma$, phase origin, basis normalization,
   scaling, walls, and terminal $C$.

## 5. Evidence and claim hierarchy

- The unitary reciprocal case in Section 3.5 has independent analytic truth
  $R_{\pm,\infty}=\mathrm{i}I$ and $\Lambda_{\pm,\infty}=\Gamma$.  It is the
  primary finite-QZ gap oracle.  Empty propagation is only an additional sanity
  check and does not replace it.
- Noncommuting manufactured scattering data validate Redheffer, terminal, and
  Cayley algebra only; they do not validate `bloch.construct_S` physically.
- At $k=0.10$, doubling and QZ share the same `S_cell`.  Their agreement is an
  internal cross-check of infinity treatment, not independent truth.
- Dirichlet, Robin, and zero-incoming sequences also share the same cell map.
  Agreement among them is useful falsification evidence, not method
  independence.
- Without an independent PDE/FEM/supercell reference, the real-case report must
  stop at `same-cell-map internal cross-check`.

## 6. Pre-registered hard gates required for GO

Before code execution, freeze numerical thresholds and stable failure labels for:

1. analytic direct-elimination errors for all four Redheffer blocks and both
   terminal directions;
2. all linear-solve residuals and reciprocal condition estimates, with no
   explicit inverse;
3. non-Wood margin $\min_m|\gamma_m|$ before `A_QP` construction;
4. `A_QP` relative residual and conditioning;
5. representation fingerprints at every level and for every closure;
6. QZ pencil regularity, stable/unstable/neutral/infinite counts, invariant
   residual, unit-circle separation, and graph-block conditioning;
7. Cayley residual and conditioning;
8. transmission decay, successive doubling-map differences, and closure-to-QZ
   discrepancies;
9. upstream-failure propagation to `unavailable` downstream fields; and
10. provenance labels distinguishing analytic truth, same-cell cross-check,
    screening input, and unavailable reference truth.

The formal configuration uses $\zeta=0.7$.  The resonant $\zeta=1$ fixture is a
negative gate test, not a member of the accepted closure-convergence sequence.

## 7. What survived scrutiny

- The Phase 3 scattering convention matches `bloch.construct_S` and
  `bloch.solve_modes`.
- The four written Redheffer formulas have the correct noncommuting order.
- The right and left Dirichlet terminated maps follow from direct elimination.
- With center-domain outward normals, the two DtN formulas correctly have the
  same algebraic form.
- The proposed QZ graph directions, right $B_s/A_s$ and left $A_u/B_u$, are
  correct for the existing positive-$x$ multiplier convention.
- The proposed unitary reciprocal analytic cell has the claimed finite
  reciprocal multipliers and exact reflection/DtN maps.
- Raising $k=0.20$ as a mandatory negative/stop case is useful, provided both
  its Wood and cell-BIE-pole mechanisms are reported.

## 8. Minimal resolution and next gate

Sections 3 and 6 are now the accepted implementation contract.  They must be
encoded in the half-guide design, symbol ledger, experiment plan, and output
schema before the formal run; this documentation may proceed in parallel with
implementation.  No change to the governing mathematical model is needed.  The
Stage 2 review will inspect the actual test code and preserved outputs,
including whether each negative case reaches the shared production gate rather
than receiving a hard-coded expected label.

## 9. Open gaps

- No half-guide implementation, raw output, or reproducibility evidence has yet
  been reviewed.
- The proposed $k=0.10$ screening values have not been independently reproduced
  in this review.
- No independent physical DtN reference is currently identified for the real
  inclusion case.
- Robustness under port/BIE refinement, nearby regular $k$, asymmetric leads,
  clustered multipliers, or weak graph-block conditioning remains untested.

## Stage 2: post-experiment review

### A. Audit frame

The audited artifact is the frozen `eig-apost-half-guide-map-v1.1` experiment,
implemented by `test/hg-map/hg_map_experiment.m` and
`run_hg_map_experiment.m`, together with every file in `test/hg-map/output/`
and the preserved `pilot-universal-terminal-gate/` bundle.  The frozen design
and this review are authoritative for formulas, cases, exclusions, gates, and
the claim boundary; code, logs, and generated tables are evidence rather than
authority.

The question is whether the implementation supports the restricted claim that
the half-guide linear-algebra chain works at one frozen real EDC cell and agrees
internally with an ordered-QZ graph formed from that same cell.  Success requires
all algebra, one-cell, QZ, terminal, convergence, exclusion, representation, and
ledger gates in the frozen design.  It expressly excludes an independent
physical DtN validation, a frequency-interval result, a limiting-absorption
result, and a discretization-convergence claim.  The review used static
formula-to-code comparison, all text/CSV/SVG/log artifacts, a read-only load of
`results.mat`, the preserved failed pilot, the Engineer's two successful runs,
and the main agent's independent exit-zero rerun with 442 ledger rows and no
bad status.

### B. Verdict

**PASS, high confidence.**  The repaired implementation satisfies the frozen
Stage 1 `GO` criterion.  The formulas and block orders match the freeze, both
ordered-QZ passes and all four invariant residuals are present, the positive and
negative cases share the relevant production helpers, every mandatory ledger
factor is now recorded and gated, all reported numerical gates pass, and the
report does not promote the real-cell QZ comparison to independent physical
truth.  No blocking issue remains for the stated one-point internal claim.

### C. Strongest challenge

The strongest remaining challenge is inferential rather than computational:
finite-section doubling and ordered QZ start from the same real-cell
`S_cell`.  Their agreement can falsify inconsistency between the two infinity
treatments, but it cannot validate the physical or discretization accuracy of
that shared cell.  The final report states exactly this boundary, so the
challenge limits future claims rather than overturning the present one.

### D. Findings

1. **OBSERVATION -- the QZ Cayley-ledger defect is resolved.**  Location:
   `LOCAL_add_qz_cayley_reference` and the Case A/Case B call sites.  Each case
   stores `Lambda_plus` and `Lambda_minus`, records exactly one QZ Cayley row per
   side, and `LOCAL_doubling_run` reuses those stored references.  The two Case B
   rows are `PASS`, with reciprocal condition estimates
   `0.9696777706426013` and `0.9696777706426027` and solve residuals about
   `3.42e-16`.  A future decisive regression test is that there remain exactly
   two such Case B rows and that either failed status makes the runner fail.

2. **MINOR -- the reproducibility record is meaningful but incomplete.**
   Location: `LOCAL_repro_vector`, `LOCAL_compare_previous`, and
   `reproducibility.txt`.  Evidence: a 15-scalar vector, including the final
   `all_pass` bit, agrees exactly with the previous run; current source hashes
   match the files, and the independent rerun exited zero and recovered 442
   ledger rows with no bad status.  However, the comparison omits raw matrices,
   full tables, fingerprints, and artifact hashes, records neither run's exit
   code, and its pass bit is not conjoined with `results.all_pass`.  Consequence:
   it supports repeatability of the selected diagnostics, not byte-identical or
   full-state reproducibility.  Decisive test: preserve a two-run manifest with
   exit codes and hashes of all required deterministic artifacts, or compare and
   gate the full numeric result state.

3. **MINOR -- the representation fingerprint guard remains self-referential.**
   Location: each case's recomputation of its fingerprint from the same live
   inputs.  The emitted fingerprints match the frozen cases by static
   inspection, but later coordinated drift in the live configuration and its
   generated fingerprint would not fail this comparison.  Consequence: source
   hashes and review currently supply the freeze check, rather than an
   independent expected fingerprint in code.  Decisive test: compare each
   emitted fingerprint with a separately frozen expected value.

4. **OBSERVATION -- the negative cases are classified correctly.**  At
   $k=0.20$, only `bloch.rayleigh_channels` is called; the observed primary stop
   is `WOOD_POINT`, while `CELL_BIE_POLE_RISK` is explicitly secondary and has
   `USER_SUPPLIED_PRIOR_SCREENING` provenance.  No BIE, QZ, map, DtN, or QZ
   comparison is exposed.  The $\zeta=1$ case stops at the same terminal gate
   used inside the positive production map path, and its pass condition now
   checks the actual emitted availability flags and `NaN` values.  The preserved
   pilot records the original zero-rcond failure, and its timestamp precedes the
   frozen $\zeta=0.7$ design and formal run; no evidence of post-result retuning
   was found.

### E. Implementation audit

The noncommuting Redheffer formulas, right/left terminal maps, paired raw solves,
and leftmost-$\Gamma$ right-solve Cayley formula retain the frozen order.  The
QZ pencil is formed as specified; stable and unstable leading subspaces come
from separate ordered-QZ passes, both graph divisions are right solves, and all
four generalized-Schur residuals plus both fixed-point residuals are gated.
The ledger contains 442 rows: 440 `PASS` and the two expected
terminal-resonance stops.  The mandatory BIE, Redheffer, terminal, finite-map
and QZ-reference Cayley, graph, and fixed-point factors are represented.  The
saved result has all A0, Case A, Case B, negative-case, ledger, and overall pass
bits true; the repaired resonance row has four false availability flags and
three `NaN` downstream values.

The main numerical limitation is intentional: doubling and QZ share the same
`S_cell`, so their agreement cannot detect physical or discretization error in
that cell.  No `ntot` refinement, nearby-frequency robustness, or independent
physical reference was run.  The final report states this limitation correctly.

### F. What survived

- The A0 noncommuting response, associativity, terminal, and trace checks pass;
  the reversed Cayley order is rejected with residual about `1.76e-1`.
- Case A has the exact stable/unstable counts, minimum unit gap `0.5`, and final
  map/DtN error at most `5.07e-16`.
- Case B is non-Wood with minimum channel magnitude about `0.1732`;
  `rcond(A_QP)` is about `0.2394`, and the BIE residual is about `5.70e-16`.
  Its QZ split is 15 stable and 15 unstable modes with no neutral, infinite, or
  indeterminate pairs and minimum unit gap about `0.2790`.
- Case B transmission decays from about `0.756` at one cell to `8.05e-10` at
  64 cells.  Every closure/side error decreases over the last three levels;
  the final maximum map/DtN error is about `1.93e-15`, and the final closure
  spread is zero at stored precision.
- The report limits these facts to a one-point same-cell internal cross-check
  and does not call either $k=0.20$ or QZ an independent physical truth.

### G. Minimal resolution

No blocking repair remains.  The next optional gate improvement is to preserve
a two-run manifest with OS exit codes and hashes of every required deterministic
artifact, and to compare emitted representation fingerprints with separately
frozen expected strings.  These improvements would strengthen automation but
are not required to sustain the restricted Stage 1 claim.

### H. Open gaps

No MATLAB run was reviewed; the numerical evidence is from Octave.  Full
artifact-byte reproducibility, BIE discretization convergence, nearby regular
frequencies, asymmetric leads, clustered or weakly separated multipliers,
poorly conditioned graph blocks, and an independent physical DtN reference
remain unverified.  These gaps prohibit broader physical conclusions but do
not contradict the stated one-point internal result.
