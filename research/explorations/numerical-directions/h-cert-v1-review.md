# Review of hypothesis (H) certification: half-lead surface states

Scope: Review only of the requested portions of `h-cert-proof.md`, with `h-cert-problem.md`; the two specified derivation blocks and B3 monotonicity corollary in `test/numerical-directions/h-cert-v1/README.md`; `h_bloch.m`, `h_endpoint.m`, `h_analyze.m`; the reference `LOCAL_curve` in `test/numerical-directions/fem-pipeline-v1/direct_native.m`; and the manifest, main endpoint records and phase-panel tables from runs 007, 009, 010, and 011.

**Result: 0 blockers, 0 important caveats, 0 minor caveats.** With the periodic gap in item (A) supplied as a premise, the reviewed argument and implementation establish (P) for both orientations of each material and the distance bound in (K), in the stipulated arithmetic model. The choice $K_+=279.9$ is an upper bound for $1+6.6169/0.023725=279.899894625\ldots$.

| Item | Verdict | One-line finding |
|---|---|---|
| Section 1.2, (1.1) | correct | Symmetric entrywise error bounds give the stated operator-norm and two-sided Hermitian bounds. |
| Section 1.2, (1.2)–(1.3) | correct | Positive separation of the approximate matrix controls the inverse and all terms in the quadratic-form perturbation. |
| Section 3.1, (3.1) and form inverse | correct | The weighted resolvent and energy-space spectral multipliers give the stated volume and form bounds. |
| Section 3.1, (3.2) | correct | The two half-line inequalities give the factor one-half and the displayed extension proves trace surjectivity. |
| Section 3.1, (3.3) | correct | The source and trace normalizations define bounded layer operators using only the full-periodic inverse. |
| Lemma B.1 | correct | Zero trace gives the two Dirichlet eigenfunctions, and factorization through the surjective trace gives the converse. |
| Lemma B.2 | correct | The reference layer map is compact into L² and the double resolvent identity gives the positive essential spectral point. |
| Theorem B.3, count and spectral exclusion | correct | Positive kernel crossings decrease the boundary negative index, while (3.24) upgrades invertibility to absence of half-lead spectrum. |
| Equation (3.9) | correct | Differentiation gives the weighted response Gram and strict positivity on every nonzero source. |
| Equation (3.10) | correct | Loewner monotonicity and equal endpoint inertias preserve the endpoint separation on both sign classes. |
| Exact formula (3.12) | correct | The reference perturbation includes both the inclusion term and the zero-mode term in (3.11). |
| Lemma B.4, (3.13)–(3.15) | correct | Collar decay and weighted source norms bound both the high block and the low-to-high block. |
| Theorem B.5, (3.16) | correct | The positive high block permits the Schur sandwich, and matching separated finite inertias imply full invertibility. |
| Equation (3.17) | correct | The inverse triangular factor contributes the squared factor and the diagonal inverse uses the smaller separation. |
| Section 3.6, (3.19)–(3.21) | correct | The stationary-action identity has quadratic residual error with the stated two-sided resolvent bound. |
| Bloch source formula (3.22) | correct | The positive and negative longitudinal sums give the two denominators and the numerator phase shown. |
| Fiberwise use of (3.20) | correct | Both Bloch phases and normalized integration preserve the action identity and residual bound. |
| Section 3.7, (3.24) | correct | The trace correction solves the decoupled Dirichlet problem and its adjoint is taken in the weighted space. |
| Equation (3.25) | correct | The direct-sum resolvent norm bounds each half-lead resolvent norm and hence its spectral distance. |
| Equation (3.26) | correct | The full-line trace inequality and the resolvent energy estimate give the displayed layer-norm bound. |
| Equations (3.27)–(3.28) | correct | The low response error and the collar-controlled high response combine by the two-block Cauchy–Schwarz estimate. |
| Poisson derivation: flux and dual norm | correct | The Poisson equation cancels the volume residual and bounds its energy-dual norm by the gradient norm of the Poisson solution. |
| Poisson derivation: matrix H | correct | Fourier orthogonality separates the retained residual and bounds every omitted coefficient using the fixed positive tail denominator. |
| Poisson derivation: E and first response bound | correct | The form inverse gives the factor K, and the squared resolvent multiplier gives K/d for the response norm. |
| Second Poisson identity | correct | Substitution of the resolvent identity gives the three displayed terms, including the positive weighted Poisson norm. |
| Second Poisson bounds and H^(2) | correct | The squared-denominator tail bound and density upper bound 17 give both the action-error and response-error estimates. |
| B3 monotonicity corollary | correct | Zero negative index and invertibility at the lower endpoint give a positive lower bound that persists throughout the remaining periodic gap. |
| Phase integration: fixed polynomial trials | correct | The polynomial coefficients define admissible trials; neither interpolation accuracy nor phase-panel derivative matching is needed. |
| Phase integration: Bernstein-ellipse Gauss remainder | correct | Polynomial exactness and the Chebyshev tail give a bound smaller than the conservative factor used in the code. |
| Phase integration: conjugated factors | correct | Schwarz reflection of each analytic factor agrees with its conjugate on the real axis and preserves the bound on the symmetric ellipse. |
| Bounds t_b, f_b, D_b, and r_b | correct | The fixed gauge, two geometric-series denominators, kinetic diagonal, and bounded material multiplier give the claimed norms. |
| Bounds B_C, B_H, B_U, and B_G | correct | The action and Gram expansions are bounded by these products, with a positive lower bound for the complex kinetic denominators. |
| Phase bound for H^(2) | correct | Squaring the inverse kinetic denominator gives the stated ellipse bound. |
| Curve-trapezoid remainder | correct | The analytic strip, curve derivative bound, exponent bounds, and nonzero denominator separations cover all required primitive moments. |
| Curve-remainder propagation | correct | The matrix dimensions and coefficient bounds in A cover the moment errors and their propagation through the action and residual Grams. |
| `h_bloch.m`: `LOCAL_geometry`, X | correct | The two divergence formulas have the correct signs, the zero mode uses the exact area, and the matrix uses column-minus-row frequencies. |
| `h_bloch.m`: `LOCAL_geometry`, source moment H | correct | The sums of longitudinal rates and differences of transverse frequencies give the source Gram; the zero-exponent case is evaluated exactly. |
| `h_bloch.m`: `LOCAL_sources`, gauge and IT | correct | Both longitudinal branches are retained and the fixed-gauge inclusion moment has the correct divergence denominator. |
| `h_bloch.m`: `LOCAL_sources`, TT | correct | The branch coefficient matrix combines the four source-moment blocks into the inclusion Gram. |
| `h_bloch.m`: reference-layer Fourier coefficients and bg | correct | The rational Fourier coefficients and exact full-cell diagonal integral include the noncompact zero-mode source. |
| `h_bloch.m`: `LOCAL_grams`, J | correct | The matrix implements the two source cross terms minus the trial action in (3.19). |
| `h_bloch.m`: `LOCAL_grams`, G0 and G1 | correct | Background minus inclusion plus corrected inclusion gives the unweighted Gram and the required residual Gram weighted by 1/rho. |
| `h_bloch.m`: `LOCAL_grams`, U | correct | The full-cell and inclusion contributions give the rho-weighted Gram of the reference layer plus trial response. |
| `h_bloch.m`: polynomial certificate trials | correct | Node solves select fixed coefficients, and the residual is recomputed for those polynomial trials at every integration node. |
| `h_bloch.m`: H and H^(2) | correct | The retained residual is kept explicitly and both Fourier-tail formulas use the full unweighted residual Gram. |
| `h_bloch.m`: D_tail per panel | correct | The final minimum in lines 131–134 is constant on the panel and is a valid omitted-mode lower bound. |
| `h_bloch.m`: remainder sums | correct | The phase weights, curve propagation allowance, and additional H^(2) allowance are accumulated in safe directions. |
| `h_bloch.m`: assembly of hat C | correct | The integrated inclusion action is supplemented by D₀ and the exact full-line zero-mode direct term. |
| `h_bloch.m`: E for both methods | correct | Lines 170–174 add the action error and the appropriate first- or second-Poisson Gram errors. |
| `h_bloch.m`: response upper Grams | correct | The separate positive scalar allowances in HU, UU, and VU are passed to the endpoint calculation. |
| `h_endpoint.m`: Schur matrices, inertia, and gamma | correct | The finite blocks and selected sign separations match (3.16) and the definition preceding (3.17). |
| `h_endpoint.m`: (3.17) and (3.25)–(3.28) | correct | The boundary inverse, improved response norm, tail norm, distance, and form constant use the required factors. |
| `h_endpoint.m`: `LOCAL_tail` | correct | The smallest omitted absolute transverse frequency supplies the maximum, with collar width one-quarter and the coarse source bound. |
| `h_analyze.m`: B2 | correct | The endpoint comparison is accompanied by matching Schur inertias and positive gamma in the endpoint checks. |
| `h_analyze.m`: monotonicity value | correct | The zero-index lower endpoint triggers the minimum-distance formula and the corresponding upper-end form constant. |
| Cell placement, orientation, and collar | correct | The inclusion is translated to (1/2,0) without reflection, and its radius leaves a homogeneous collar wider than one-quarter. |
| Claim (P) | correct | Each material's endpoint certificate excludes the spectrum of both half-leads throughout the closed target window. |
| Claim (K), monotonicity value | correct | The extended spectral exclusion gives distance at least 0.023725 and permits K_+=279.9. |
| Alternative constants from (3.25)–(3.28) | correct | The upper-end response and boundary inverse bounds give the reported material-dependent alternatives. |

The retained main runs use 64 phase panels, degree-five trials, order-40 phase Gauss integration, and 2560 curve points. A small independent scalar check of their phase-panel tables confirmed the residual-bound and curve-propagation formulas, the conditions $s<0.5$, $A>3$, $A\epsilon_{curve}<1$, $D_{tail}>1$, and positive Schur tail bounds. The original and translated curve formulas were compared directly. The full endpoint computations and floating-point matrix sign tests were not rerun.

Review literature verification completed: the specialized results used here are proved in the inspected text; item (A) remains the supplied premise. All requested items were reviewed. The reviewed sources and retained outputs were not modified; only this review file was written.
