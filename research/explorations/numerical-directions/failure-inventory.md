“numerical-directions” means the search for numerical-analysis research directions connected to this repository's waveguide computations.

# Stage 0: working notes for Claude

The common model below has $y$-quasiperiodicity $\beta=0.5$, periods $d=L=1$, a five-lobe center inclusion of relative permittivity 4, different left/right trilobe inclusions of permittivity 17, and background 1. BIE means boundary integral equation; FEM means finite element method; DtN means Dirichlet-to-Neumann map; FMM means fast multipole method; RT2 means Raviart–Thomas flux elements of order two. $P_p$ denotes degree-$p$ field elements and $\mu=k^2$.

The requested small run-summary files are absent from this checkout. Numbers below come from retained experiment READMEs and linked result reviews; raw outputs were not independently rechecked. No experiments were run. Diagnostics are proposals using existing numerical routines, with a **30-minute total and 3 GiB peak-memory limit per diagnostic**, including regeneration of missing inputs. Their time estimates use recorded runs, not new measurements. Standard-method combinations remain eligible if they improve a guarantee, efficiency, or robustness on this model; literature comparison is deferred to Stage 1.

## N1 — Enrichment radii depend on unproved saturation

- **Setting:** Three-template FEM + DtN, with center and both leads enriched together through $P_2/P_3/P_4$ on each I10.2 mesh.
- **Symptom:** Final conditional $k$ radii are $1.32878\times10^{-7}$, $4.43946\times10^{-9}$, and $3.14510\times10^{-10}$; observed layer-difference ratios are 0.006710, 0.002319, and 0.001211. Each radius still assumes contraction of the remaining continuous error by $1/2$ and a per-root evaluation budget of $10^{-10}$ in $\mu$ ([I10.2 review, §§2–3](../../projects/eig-apost/implementation/i10/review-10-2a.md)).
- **Missing:** A computable remainder guarantee relating the enriched roots to the continuous problem, including unresolved lead and interface errors shared by the layers.
- **Question / method + theorem:** Can enrichment corrections be supplemented by a complementary-space residual solve and explicit lead/interface consistency terms, yielding a guaranteed eigenvalue remainder without assumed saturation? Reuse the infinite-lead mass normalization already implemented in I10; retain explicit spectral-separation hypotheses where needed.
- **Cheapest diagnostic:** Run `refine_i102` for g12 and g24 from empty output; compare same-grid $P_3\to P_4$ corrections with the cross-grid $P_4$ displacement and common-wall mode correlation. About 2 minutes; quantify shared-error sensitivity or expose inconsistent intervals before implementing another field order.
- **Main risk:** Agreement across these meshes can support the construction while leaving common bias undetected.
- **Stage 1 keywords:** saturation-free eigenvalue estimation; complementary-space correction; hierarchical estimators; nonlinear eigenproblem a posteriori bounds; periodic DtN consistency.

## N2 — Curved-material enclosures overwhelm useful precision

- **Setting:** I9.6 source reconstruction of the fixed FEM + DtN field, evaluated against the true analytic inclusions using auxiliary rectangles and Fourier modes.
- **Symptom:** Refining $(N,M)=(256,128)$ to $(512,256)$ increased reported $R_k$ from $3.88352\times10^{-5}$ to $1.42815\times10^{-4}$; the finer source-moment enclosure contributes 91.76% of its radius. All six template/level engines stopped on predicted piece counts, while curved-field evaluation stayed at level 3. An area-tolerance shortcut also leaves signed complex moments without a geometric error allowance ([I9.6 review, §§9.3–9.4](../../projects/eig-apost/implementation/i9/review-9-6a.md#93-实际半径主导项与精度解释)).
- **Missing:** Reliable integration that contracts under refinement with affordable work; the same issue affects I10's unproved numerical-evaluation budget.
- **Question / method + theorem:** Can exact cut-polygon moments, analytic curve-strip remainders, and a joint adaptive allocation for source moments and field defects deliver a prescribed global tolerance? Prove enclosure reliability and a work-versus-tolerance estimate under explicit curvature and element-map bounds.
- **Cheapest diagnostic:** Call `dtn_bound_i96(config,[],out)` twice with its existing smoke configuration, holding the reconstructed field and auxiliary grids fixed and varying only `engine.start_level` from 3 to 4. Compare moment widths, field-defect widths, terminal pieces, and work; about 5 minutes. This probes integration behavior even though the smoke frequency fails native eigenpair qualification.
- **Main risk:** Merely fixing the area shortcut may leave the dominant interval overestimation unchanged.
- **Stage 1 keywords:** certified cut-cell quadrature; curved-interface moment fitting; Bernstein enclosures; adaptive integration complexity; variational crimes; signed thin-strip integration.

## N3 — Flux optimization gives little extra eigenvalue resolution

- **Setting:** Fixed FEM trial field with an RT2 flux and a localized weak-residual majorant, I9.4–I9.5.
- **Symptom:** Explicit edge averaging gave $R_\mu=1.71978$, with weighted body-defect square 1.06828. Optimized fluxes and a finite Floquet tail reduced this to 0.0151938, but three further direct-majorant iterations reached only 0.0151552, a 0.2541% improvement. Pure gradient projection gave 0.0046847 while its complete majorant was about 0.519 ([I9.4 results](../../../test/i9/fem-bound-v1/README.md#本轮实际结果); [I9.5 fixed-field results](../../../test/i9/eq-temple-v1/README.md#结果)).
- **Missing:** An efficient estimator construction that balances gradient fitting and divergence equilibrium well enough to resolve eigenvalue errors; the observed optimization stagnation has several possible causes.
- **Question / method + theorem:** Can locally enriched equilibrated flux patches, chosen by the actual majorant contributions, outperform the fixed RT2 global least-squares construction? Establish reliability and local efficiency, including material oscillation and artificial-end terms, then test whether enrichment improves the gradient/divergence trade-off.
- **Cheapest diagnostic:** Regenerate the I9.3 field with `compare-v1`, then call `eq_temple_i95` in formal mode with tail `[1,12]`; compare weighted/unweighted fluxes and their elementwise gradient, divergence, and end contributions on that same field. About 8–10 minutes, including input regeneration; this establishes where a local enrichment would need to help.
- **Main risk:** A sharper flux majorant may still lose the quadratic accuracy available to an eigenvalue-specific correction.
- **Stage 1 keywords:** equilibrated eigenvalue estimators; local Raviart–Thomas enrichment; functional majorants; contrast-robust efficiency; quadratic eigenvalue error; resolvent Temple estimates.

## N4 — Tiny BIE jumps lack an evaluator error budget

- **Setting:** I9.2's fixed-density BIE field, MFS quasi-periodic Green function, FMM acceleration, and jump-based spectral-distance formula; MFS means method of fundamental solutions.
- **Symptom:** FMM tolerance was requested as $10^{-12}$ while the computed jump quantity was $\epsilon_{\rm num}=2.05479\times10^{-12}$ and $R_\mu=7.74585\times10^{-10}$. Reordering actions on saved matrices changed $R_\mu$ by 9.12 parts per million; material-action components differed by up to $1.64\times10^{-14}$. The requested FMM tolerance has no established conversion to an absolute jump-error bound ([I9.2 review, §§C–D](../../projects/eig-apost/implementation/i9/review-9-2a.md)).
- **Missing:** An accuracy guarantee for a small difference of large layer-potential actions, including common kernel/proxy error and infinite-lead tails.
- **Question / method + theorem:** Can jumps be evaluated as combined source actions, with cancellation-aware absolute tolerances and verified propagation-tail estimates? Derive a backward-error budget through the actual density maps and trace norms, then adapt evaluation accuracy to the desired spectral-distance resolution.
- **Cheapest diagnostic:** Regenerate I9.2 once and run its existing `audit_estimate.py`; compare its recomputed material actions, propagated series, and final radius with the regenerated saved values. About 2–3 minutes; quantify arithmetic sensitivity before adding a fixed-density evaluator comparison.
- **Main risk:** Rearranging identical saved kernels measures arithmetic sensitivity but leaves common evaluator bias unresolved.
- **Stage 1 keywords:** cancellation-aware FMM; absolute error layer potentials; accurate residual evaluation; quasi-periodic MFS error; certified geometric-series tails; compensated summation.

## N5 — Frequency search over-refines one dip without coverage control

- **Setting:** I9.1 BIE/FMM matching search over $k\in[1.451,2.249]$, after sampled two-sided lead classification.
- **Symptom:** The material-4 run used 213 matching evaluations, 438 lead-cell constructions, and 19 fine rounds; fine refinement cost 508.24 s. The final sampling width was $1.62093\times10^{-14}$ while the matching score was near floating-point saturation. The right-boundary trend at 2.249 remained unresolved, and the 33-point lead exploration ended without locating either band edge ([search results](../../../test/i9/search-v1/README.md#completed-material-comparison); [I9.1 review](../../projects/eig-apost/implementation/i9/review-9-1a.md#中心材料参数对照attempt-3-独立追加审查)).
- **Missing:** A stopping rule tied to operator-evaluation accuracy, and an interval exclusion test that makes search coverage auditable.
- **Question / method + theorem:** Can adaptive Chebyshev or rational approximation of the matching operator combine safeguarded local refinement with resolvent-based interval exclusion? Prove a root-exclusion criterion and an evaluation-cost bound in terms of approximation accuracy and local separation; extend the same strategy to specified scattering outputs only after checking the relevant poles and thresholds.
- **Cheapest diagnostic:** Use `search_i9_physics('leads',...)` and `('match',...)` at 21 frequencies around the recorded dip, including offset nodes; repeat five points at FMM requests $10^{-12}$ and $10^{-14}$. About 2–3 minutes; compare the score/evaluator spread with the gain from shrinking the sampling interval.
- **Main risk:** An interpolation residual alone may miss a narrow excursion between sample points.
- **Stage 1 keywords:** certified adaptive frequency sweep; rational operator approximation; nonlinear eigenvalue exclusion; resolvent bounds; adaptive resonance sampling; inexact root finding.

## N6 — Repeated periodic-lead solves dominate high-order cost

- **Setting:** I10's six root chains, with fresh interior elimination and ordered-QZ DtN construction at each frequency; QZ denotes generalized Schur decomposition.
- **Symptom:** The fine run took 127.845 s overall; lead elimination cost 39.13 s and QZ/DtN 17.36 s inside a 109.33 s kernel. The g24/g48 combined lead costs were 10.959/56.490 s. Fine-layer roots required only 4–6 frequencies each, so even local continuation repeatedly pays for large template solves ([I10.1 review, §6.5](../../projects/eig-apost/implementation/i10/review-10-1a.md#65-完整成本及应纠正的账目口径); [I10.2 cost table](../../../test/i10/refine-v1/README.md#成本)).
- **Missing:** A reusable frequency-dependent lead response with an error certificate cheap enough to retain the savings.
- **Question / method + theorem:** Can rational Krylov reduction of the cell Schur response, combined with residual-controlled stable-subspace continuation, reduce repeated factorizations? Bound the resulting center-operator and root errors using computable cell-solve, graph-conditioning, and branch-derivative factors; retain a full-solve fallback near poorly conditioned charts or critical multipliers.
- **Cheapest diagnostic:** Run `refine_i102` for g24 once; use its existing timing ledger and iteration table to allocate lead cost by polynomial order and number of frequency evaluations. About 1–2 minutes; quantify the maximum possible saving before implementing reduction.
- **Main risk:** The error-checking cost may approach that of recomputing the full lead response.
- **Stage 1 keywords:** parametric Schur complement; rational Krylov model reduction; certified DtN interpolation; invariant-subspace continuation; reduced periodic waveguides; output error propagation.

## N7 — Curved mesh repair has only case-by-case reliability

- **Setting:** Curved P2 elements around the concave center star, shared by the FEM center and periodic-lead templates.
- **Symptom:** I9.5b's initial coarse run stopped before any DtN solve because one element had positive minimum Jacobian $3.76\times10^{-8}$ but Jacobian ratio 569.47. Its three vertices were interface nodes, so deleting free background points could not repair it. One same-material edge flip reduced the global ratio to 1.345; the current repair has finite trial limits ([mesh failure and repair](../../../test/i9/fem-dtn-v1/README.md#正式结果-run-01geometry_failed); [I9.5b review, §4](../../projects/eig-apost/implementation/i9/review-9-5b.md#4-d2-网格修补与必要链)).
- **Missing:** A predictable meshing/refinement procedure preserving the analytic interface sampling and periodic constraints while guaranteeing usable curved-element shape quality.
- **Question / method + theorem:** Can curvature-aware point spacing, constrained flips, and verified quadratic-map tests ensure positive Jacobians and controlled shape constants for these concave interfaces? Establish sufficient geometric conditions and a terminating refinement/repair algorithm, then relate those constants to FEM and quadrature stability.
- **Cheapest diagnostic:** Run the existing `fem_dtn_i95b` meshcheck mode, then the formal repaired chain; compare the failing patch, accepted flip, full-element Jacobian extrema, and unchanged interface nodes. About 1–2 minutes; confirm the failure mechanism and exact scope of the existing repair before testing a wider mesh family.
- **Main risk:** The existing bounded flip already solves the recorded instance, so broader robustness gains must be demonstrated.
- **Stage 1 keywords:** valid high-order meshes; curved constrained Delaunay; Bernstein Jacobian certification; concave interface meshing; shape-regular isoparametric elements; terminating mesh repair.

## Re-evaluation of the earlier scattering rejections

[Threshold uncertainty](../bend-scattering-methods/candidates/threshold-uncertainty.md) should return to the Stage 1 comparison list: combine an augmented critical-mode port representation with a computable cell/cutoff error bound and propagate it to a fixed incident channel's reflection amplitude. Standard perturbation theory is an acceptable component. The useful question is whether the combination gives a guarantee or better robustness when cell error and distance to cutoff are comparable. The earlier requirement for an additional nonstandard mechanism is too restrictive under the current criterion. Its worked counterexamples are reduced models; it records no numerical failure of our two-dimensional scattering solver. Keep the actual $y$-quasiperiodic geometry for the demonstration rather than switching to the note's Neumann-sidewall prototype.

[Rejected routes](../bend-scattering-methods/candidates/rejected-routes.md) also deserve narrower reconsideration. Output-specific adjoint estimates with near-kernel deflation can be combined with verified periodic-port errors; certified adaptive frequency sweeps can combine existing rational approximation and exclusion tools. These connect directly to N2/N4/N5/N6. Stage 1 must compare the complete combinations with the strongest applicable baselines using full method/theorem conditions, including which port data they assume exact. The notes' narrow-resonance examples explain why finite samples or conservation checks alone are insufficient. They leave algorithms using operator information eligible. Direct amplitude extraction, impedance coordinates, and extra evanescent modes remain useful ingredients; their research value depends on the resulting guarantee or measured robustness gain on this model.

## Ranking by research promise

1. **N2 — Curved-material enclosures:** A specific, measured bottleneck with clear reliability and complexity targets, reusable by both residual bounds and I10's evaluation budget.
2. **N1 — Enrichment remainders:** The largest potential improvement in usable eigenvalue guarantees, supported by an already effective solver and sharply contracting corrections, though the continuous remainder is difficult.
3. **N6 — Reusable periodic-lead responses:** A substantial measured cost target with natural reduced-model and perturbation analyses, and a direct bridge to repeated scattering calculations.
4. **N5 — Adaptive frequency search:** Hundreds of expensive evaluations and unresolved boundary coverage motivate an algorithm that allocates work according to accuracy and supplies explicit exclusions.
5. **N4 — Accurate BIE jump evaluation:** Closely tied to the observed estimator scale and essential for trustworthy BIE error estimates, with novelty depending on the complete evaluator-to-output guarantee.
6. **N3 — Locally enriched flux estimation:** Strong negative evidence against further fixed-space optimization makes local enrichment worth testing, but integral evaluation and loss of eigenvalue stationarity may still dominate.
7. **N7 — Reliable curved meshing:** A concrete robustness issue with a cheap diagnostic, currently lower priority because a standard local repair already fixes the observed patch.
