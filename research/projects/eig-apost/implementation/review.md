# Skeptic review

## Material Passport

- Origin Skill: `academic-research-suite/reviewer`
- Origin Mode: `review`
- Origin Date: 2026-08-02
- Verification Status: `INDEPENDENTLY REVIEWED`
- Version Label: `eig-apost-manufactured-v1.2`
- Repro Lock: `test/eig-apost-nep/output/reproducibility.txt`

## Stage 1: pre-implementation review

### Decision

**REVISED, THEN GO.**

The fixed-dimensional analytic model is mathematically coherent and is suitable for a
first test of contour counting, bordered Newton, root qualification, projected corrections,
and empirical effectivity. It is not a test of the physical BIE/DtN formulation.

### Formula audit

For

$$
  F_j(k)=
  \begin{bmatrix}
    s+c s^2+\varepsilon_j&\alpha\\
    0&1+q s
  \end{bmatrix},
  \qquad
  s=k-k_\star,
$$

the selected branch is

$$
  s_j=\frac{-1+\sqrt{1-4c\varepsilon_j}}{2c}.
$$

Because $1+2c s_j=\sqrt{1-4c\varepsilon_j}$, the signed map correction is

$$
  \delta_j^{\mathrm{map}}
  =\frac{\varepsilon_j-\varepsilon_{j+1}}
  {\sqrt{1-4c\varepsilon_j}}>0.
$$

It has the same direction as $k_{j+1}-k_j$, and

$$
  \frac{|\delta_j^{\mathrm{map}}|}{|k_j-k_\star|}\longrightarrow1.
$$

Thus the sign and coarse-tail effectivity target in the plan are correct.

### Issues found and closed before implementation

1. Estimator levels $0{:}3$ require root levels $0{:}4$. The design now distinguishes
   these ranges explicitly.
2. In the triangular model, $F_j'(k_j)x_j$ and
   $(F_{j+1}-F_j)(k_j)x_j$ are collinear, so the left-vector factor cancels in the
   correction quotient. The plan now requires analytic left/right directions,
   phase-invariant angle checks, and two-sided residuals, and it narrows the claim: this
   example does not validate general nonnormal left-vector sensitivity.
3. Scan, contour, quadrature, Newton, derivative, residual, slope, singular-gap, border,
   estimator, and effectivity thresholds are frozen before execution.
4. The real-axis dip case is correctly described as having no real root but one complex
   root. Small and large contours must count zero and one, respectively.
5. Tail and total effectivity coincide in this manufactured model; no common discretization
   error separation is claimed.
6. Root pollution is deterministic, using a prescribed $10^{-4}$ offset rather than
   relying on accidental early termination.
7. The correction is checked against an analytic complex oracle; the total correction is
   also checked by both its sum definition and an independent direct fine-level
   projection.
8. The singular-gap index is fixed as `singular_values(end-1)` under descending SVD order.
9. Level-dependent scaling is detected from actual scale metadata by the common gate; a
   negative-case label may not be assigned directly.
10. The complex seed, Newton stopping rule, finite-difference tolerance, and stable CSV
    encoding are fully specified.

### Pilot-01 protocol amendment

Pilot-01 failed at $j=0$, radius $0.32$, because 64 contour nodes produced count
`1.000004424832`, outside the unchanged `1e-8` gate. At 128 nodes the count was
`1.0000000000196`, and the contour remained separated from singularity. The failed run is
preserved under `test/eig-apost-nep/pilot-01/`.

The Skeptic approved a formal-run amendment from 64/128 to 128/256 nodes at every level and
both radii. No radius or tolerance changed. This strengthens quadrature resolution without
weakening the gate. If the formal run still fails, further adaptive tuning is prohibited.

### Remaining caveats

- The polynomial test has no branch cut or internal pole. A passing contour test cannot be
  extrapolated to a BIE pole ledger or an anchored Rayleigh chart.
- The manufactured exact limit root makes tail and total errors identical.
- No independent saturation constant or computable correction-remainder bound is present;
  the output must remain `conditional/empirical` and cannot be called certified.
- Actual BIE block mapping, augmented kernel equivalence, map convergence, and physical
  guided-mode validation remain unresolved.

## Stage 2: post-experiment review

### Decision before the reproducibility gate

**CONDITIONAL GO, high confidence.**

No core mathematical error or deviation from the frozen algorithm was found. The v1.2
evidence supports the deliberately narrow manufactured $2\times2$ NEP claim. The only
remaining gate at the time of this review was the pre-registered two-run reproducibility
manifest.

Closure rule: if `test/eig-apost-nep/output/reproducibility.txt` records two zero exit codes,
byte-identical deterministic artifacts, and equality of the reloaded MAT result structures,
the Stage 2 decision is **GO** without another mathematical revision. Otherwise the decision
remains **REVISE** and the non-determinism must be explained.

### Evidence supporting the narrow claim

1. The implementation uses the frozen parameters, root levels $0{:}4$, estimator levels
   $0{:}3$, 128/256 contour nodes, two radii, three Newton seeds, dual stopping rule, and
   fixed qualification thresholds.
2. Map-oracle errors are at most approximately $3.7\times10^{-16}$, and direct-total
   correction errors are at most approximately $4.4\times10^{-19}$.
3. Five root errors are at most approximately $1.4\times10^{-14}$; bilateral residual,
   singular-gap, slope, border-conditioning, derivative, and analytic-direction gates pass.
4. Every accepted contour count passes the $10^{-8}$ gate. The weakest boundary relative
   singular value is approximately $1.85\times10^{-3}$, above the $10^{-4}$ threshold.
5. Linearization consistency decreases from approximately $4.49\times10^{-2}$ to
   $3.05\times10^{-6}$, while effectivity increases from approximately $0.7943$ to
   $0.999988$, in agreement with the analytic oracle.
6. The contour miss, root pollution, level scaling, and real-axis dip cases trigger their
   pre-registered labels through shared gates wherever the mathematical objects coincide.
7. Pilot-01 and formal-01 remain in the experiment directory, preserving the contour-
   resolution failure and the later CSV serialization failure.

### Remaining limitations

- A single parameter set and the special hierarchy
  $\varepsilon_{j+1}=\varepsilon_j^2$ do not establish parameter robustness.
- The triangular model cancels the left-vector factor in the correction quotient; analytic
  direction checks do not validate general nonnormal left-vector sensitivity.
- The contour was selected with analytic root knowledge, and the model has no BIE pole,
  branch cut, representation nullspace, or common discretization error.
- The metadata gate detects declared level scaling, not an undisclosed internal rescaling.
- Agreement at four estimator levels reproduces the manufactured asymptotic trend; it is
  not an experimental proof of a general convergence theorem.

### Recommended next step

After the reproducibility gate closes, no additional benchmark is needed for this narrow
manufactured claim. The next high-value task is the actual augmented operator: complete the
row-by-row BIE/lead-block mapping, common representation, pole ledger, and kernel--field
equivalence. A non-collinear nonnormal NEP benchmark is needed only before expanding the
claim to general left-vector-sensitive projected corrections.
