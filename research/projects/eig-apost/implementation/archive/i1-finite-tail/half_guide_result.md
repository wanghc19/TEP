# Half-guide map Stage 1 result

## Material Passport

- Origin Skill: `academic-research-suite/experiment-agent`
- Origin Mode: `validate`
- Origin Date: 2026-08-02
- Verification Status: `ANALYZED / NUMERIC REPRO-VECTOR VERIFIED`
- Version Label: `eig-apost-half-guide-result-v1`
- Governing Design: `eig-apost-half-guide-map-v1.1`

## 1. Question, authority, and decision

The question is whether the implemented one-cell scattering to finite-tail reflection and
DtN chain meets the frozen Stage 1 gates, and whether center coupling may begin. The
acceptance authority is
[[research/projects/eig-apost/implementation/archive/i1-finite-tail/half_guide_map|the frozen Stage 1 design]],
with [[research/projects/eig-apost/implementation/SYMBOL|the local symbol ledger]] and
[[research/projects/eig-apost/implementation/archive/i1-finite-tail/half_guide_review|the pre-implementation skeptic review]]
fixing the claim boundary. The implementation and evidence inspected were
`test/hg-map/hg_map_experiment.m`, `test/hg-map/run_hg_map_experiment.m`,
`+bloch/construct_S.m`, and every file under `test/hg-map/output/`, including the preserved
`pilot-universal-terminal-gate/` bundle and both `results.mat` files.

**Decision: `GO`.** The narrow Stage 1 goals were met, and Stage 2 center coupling may
begin. This is a go only for the implemented half-guide linear-algebra chain and a one-point
same-cell EDC cross-check. It is not validation of a physical half-guide DtN truth, a gap
interval, a center-coupled eigenproblem, or an a posteriori eigenvalue estimator.

## 2. Findings against the frozen gates

### A0 noncommuting algebra

**`ESTABLISHED` for the fixed fixture.** The raw-interface and Redheffer responses agree to
$1.7354\times10^{-17}$, and the three-segment associativity error is
$3.5143\times10^{-16}$. The largest terminal raw-equation mismatch is
$1.2570\times10^{-16}$. The direct Cayley trace residual is
$5.1581\times10^{-17}$, whereas the deliberately reversed multiplication order has residual
$1.7562\times10^{-1}$. Thus the fixture both accepts the frozen noncommuting order and
rejects the nearest wrong Cayley order. These results validate matrix algebra and solve
orientation only.

### Case A exact gap oracle

**`ESTABLISHED` for the frozen analytic cell.** Ordered QZ finds exactly two stable and two
unstable finite multipliers, with no neutral, infinite, or indeterminate pair and minimum
unit-circle separation $0.5$. The multiplier-set, graph-map, and QZ-based DtN errors against
the exact values are respectively $2.7541\times10^{-16}$,
$4.9651\times10^{-16}$, and $6.0403\times10^{-16}$. At $N=64$, all three closures and both
sides have maximum map error $4.2277\times10^{-16}$ and maximum DtN error
$5.0634\times10^{-16}$; the final closure spread is $4.9651\times10^{-17}$. The final-three-
level monotonicity gate passes.

The production Robin value $\zeta=0.7$ remains uniformly away from the terminal gate: its
minimum Case A terminal reciprocal condition estimate over all levels is $0.399197$, and
the $N=64$ value is $0.400597$. Hence the analytic convergence result is not obtained by a
condition-number exemption.

### Case B real EDC point at $k=0.10$

**`ESTABLISHED` as a fixed-discretization, same-cell internal cross-check.** The computed
non-Wood margin is

$$
  \min_m |\gamma_m|=0.173205>0.1.
$$

The cell BIE has `rcond(A_QP) = 0.239399` and relative multi-right-hand-side residual
$5.6995\times10^{-16}$. Ordered QZ returns 15 stable and 15 unstable finite multipliers,
no neutral, infinite, or indeterminate pair, and minimum unit-circle separation $0.279044$.
The graph reciprocal condition estimates are $0.985882$ and $0.955311$; the largest listed
deflating or fixed-point residual is $9.5987\times10^{-16}$.

At $N=64$, the largest finite-tail/QZ reflection-map discrepancy over both sides and all
closures is $1.9267\times10^{-15}$, the largest DtN discrepancy is
$7.9240\times10^{-17}$, and the stored closure spread is zero at printed precision. The
three terminal sequences pass the final-three-level monotonicity gate, while the two
transmission Frobenius norms decay from about $0.756$ at $N=1$ to
$8.05\times10^{-10}$ at $N=64$.

This evidence checks two infinity treatments constructed from the same one-cell matrix.
It does not independently validate `bloch.construct_S`, establish a physical DtN error,
or prove convergence with respect to $M$, `ntot`, proxy resolution, or $k$.

### Negative cases and the preserved amendment

**`ESTABLISHED` at the registered gates.** At the Wood fixture $k=0.20$, floating-point
channel construction gives $\min_m|\gamma_m|=5.27\times10^{-9}$, representing the exact
cutoff value zero. `WOOD_POINT` is raised before `construct_S`, QZ, map, or DtN availability.
`CELL_BIE_POLE_RISK` remains explicitly labelled as user-supplied prior screening and was
not recomputed after the Wood stop.

The preserved $\zeta=1$ pilot has `all_pass = 0`: eight terminal ledger rows fail, covering
both sides and both primary/paired factors at $N=32$ and $N=64$, with reciprocal condition
estimate zero. Nevertheless, its printed $N=64$ Robin map errors fall at roundoff level.
This is the predicted misleading surface convergence and supports, rather than weakens,
the universal terminal gate. The formal run preserves $\zeta=1$ as
`TERMINAL_RESONANCE`, records reciprocal condition estimate zero, and marks every downstream
map, DtN, and QZ-comparison field unavailable with `NaN` values.

The resonance negative calls the shared `LOCAL_terminal_gate` directly rather than the
throwing `LOCAL_terminal_map` wrapper. Therefore shared-gate classification and downstream
unavailability are verified, while exception-dispatch behavior is not a separate tested
claim. This distinction does not alter the frozen Stage 1 gate.

## 3. Ledger, representation, and reproducibility

The formal pole ledger contains 442 rows: 440 `PASS` rows and the two expected
`EXPECTED_TERMINAL_RESONANCE` rows, with no `FAIL` or unclassified status. Among ordinary
passing matrix factors, the smallest finite reciprocal condition estimate is the Case B
`A_QP` value $0.239399$; the largest solve-like residual is its
$5.6995\times10^{-16}$ residual. The source hashes stored in `config.txt` match the current
frozen design, symbol ledger, `construct_S`, and experiment source. Static inspection finds
no explicit `inv` call and no call to `bloch.solve_modes`.

The first post-analysis audit found that the two Case B QZ-reference Cayley factors were
used but missing from the mandatory ledger. The ledger-only repair added one
`I_plus_Rhat` row per side without changing theory, cases, or tolerances. Their reciprocal
condition estimates are $0.9696777706426013$ and $0.9696777706426027$, with solve residuals
about $3.42\times10^{-16}$; both pass the unchanged gates. The same repair binds the Robin
negative assertion to the emitted row's actual availability flags and `NaN` values.

The stored second-run comparison has a 15-component registered numerical vector with
`max_abs_difference = 0`. A main-agent independent execution of the exact registered
command exited zero, returned all gates equal to one, passed the MAT assertions, and again
found 442 ledger rows with zero bad status, including exactly two passing Case B
QZ-reference Cayley rows. The MAT checks also confirmed the actual Robin row's unavailable
flags and `NaN` values. This verifies the registered numerical core exactly for the observed
Octave environment.

Paired exit-code records and paired SHA-256 manifests for every generated artifact were not
stored; only the current artifact hashes were captured independently. Consequently the
whole output bundle is **`PARTIALLY_REPRODUCIBLE` at artifact level**, not demonstrated to
be byte-identical. This limits reproducibility wording but does not change the Stage 1
numerical gate. The files identify Octave 10.3.0 as the generating runtime; MATLAB parity
has not been validated and remains a manual project gate.

## 4. Falsification and claim limits

The failed Robin pilot, the reversed Cayley-order fixture, the raw interface/terminal
oracles, and the Wood early stop directly attack the most likely convention, cancellation,
and availability failures. All survived after the single recorded pre-formal amendment to
$\zeta=0.7$, without relaxing any threshold. No inferential statistics or population-level
claims are present: the 11 statistical-fallacy categories were checked, with structural,
base-rate, regression-to-mean, survivorship, causal, and reverse-causal categories not
applicable. Look-elsewhere and forking-path risk is limited by the frozen fixtures,
thresholds, one recorded amendment, and preserved failed pilot.

The experiment does not test asymmetric leads, clustered or defective multipliers, weak
graph conditioning, nearby regular frequencies, port/BIE refinement, an independent PDE
reference, or a center-coupled eigenvalue. Failure in any of those regimes would narrow or
revise the corresponding future claim; it would not retroactively falsify the fixed A0 or
Case A calculations.

## 5. Next gate and review handoff

Stage 2 may use the frozen left/right map conventions and implementation. Its smallest
useful gate is a row-by-row center-coupling design with an exact manufactured coupling
oracle, direct unreduced-equation comparison, unchanged availability propagation, and a
complete factor ledger. It must retain Case B's `same-cell internal cross-check` label and
must not treat the present QZ agreement as independent physical truth.

Claims for independent review are:

1. The fixed A0 fixture establishes the implemented noncommuting Redheffer, terminal, and
   Cayley order to the registered tolerances.
2. The fixed Case A experiment reproduces its exact multipliers, half-guide maps, and DtN
   matrices and passes all three terminal sequences without a conditioning exemption.
3. The fixed Case B experiment passes the non-Wood, one-cell BIE, ordered-QZ, doubling,
   closure, and DtN gates only as a same-cell internal cross-check.
4. The Wood and Robin exclusions reach their shared gates and propagate unavailable
   downstream values; the Robin wrapper's thrown-exception path is not separately tested.
5. The registered numerical vector is exactly reproduced, but byte-identical paired
   artifacts and MATLAB parity remain unverified.
6. On these boundaries, Stage 1 is `GO` and Stage 2 center coupling may begin.

The weakest steps are the lack of independent physical truth for Case B and the incomplete
artifact-level reproducibility record. If the registered numerical comparison later fails,
the smallest downgrade is `REVISE` for implementation reproducibility. If only paired file
hashes differ while registered values and MAT assertions remain exact, the scientific
claims remain unchanged but the artifact verdict stays `PARTIALLY_REPRODUCIBLE`.
