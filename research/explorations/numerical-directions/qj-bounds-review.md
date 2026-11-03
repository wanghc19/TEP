# Review of the Goerisch truncation bounds

Scope: Review only of the requested parts of `qj-bounds-proof.md`, with `qj-bounds-problem.md`; the specified coverage proof in `test/numerical-directions/qj-cert-v2/README.md`; v2 `pm.m`, `poly2.m`, `interface_model.m`, `interface_certificate.m`, `interface_residual.m`, `interface_fields.m`, `qj_certificates.m`, `taper_certificate.m`, `geometry_certificate.m`, `exact_rt3_basis.m`, and `four_corners.m`; v1 `exact_basis.py` and `exact_rt3_basis.m`; and the supporting v2 `curve_model.m`, relevant construction/inventory routines in `direct_native.m`, `direct_pipeline.m`, `goerisch_fitted_geometry.m`, `qj_run.m`, and retained run-004 scalar certificates.

**Result: 0 blockers, 1 important caveat, 0 minor caveats.** Under the supplied (H) and Proposition 1, the reviewed construction supports the stated enclosure, with floating-point rounding excluded as stipulated. Q-1 concerns the generality of rule (4.5); its missing hypothesis is satisfied by the actual certificate's arguments.

| Item | Verdict | One-line finding |
|---|---|---|
| Lemma 2.1 | correct | The flux identity gives the real cross term, the normalization identity, and nonnegative defect by Cauchy–Schwarz. |
| Lemma 2.2 | correct | Equation (2.5) proves both directions of the strict sign-region equivalence, including the necessary positive denominators. |
| Lemma 2.3 | correct | The derivatives, curvature signs, qualified monotonicity statements, and counterexample are correct. |
| Mesh certificate, Lemma 3.1 and (3.1)–(3.4) | correct | The continuous, boundary-zero correction is globally Lipschitz; contraction proves surjectivity and the determinant estimate. |
| Fitted-map formulas (3.5)–(3.8) | correct | The collapsed Jacobian, area factor, removable singularity, and deformation bound have the stated factors. |
| Lemma 3.2, membership | correct | Four shared cubic trace values, exact phase matching, and the zero-trace taper give the required global space membership. |
| Lemma 3.3, Piola admissibility | correct | Matching flux densities give distributional divergence in L² and the stated boundary cancellation. |
| Lemma 4.1 | correct | Positive weights give the factor 2 in (4.1); direct polynomial integration gives the factor 1 in (4.2). |
| Rule (4.3) | correct | The coefficient sum bounds the polynomial on the normalized square, also with the stated complex-coefficient overestimate. |
| Rule (4.4), conjugation, and degree truncation | correct | The three product-error terms and the deleted-coefficient allowance bound the uniform error. |
| Rule (4.5), sine/cosine | Q-1 | The general complex-model setting needs an explicit real-valued polynomial hypothesis for this particular rule. |
| Rule (4.6), reciprocal | correct | The denominator separation and geometric-series tail give the stated two error terms. |
| Lemma 4.2 | correct | The residual-square and weight errors give (4.7) without separating the large cancelling terms. |
| Lemma 4.3 | correct | The self-map and contraction hypotheses prove existence, uniqueness, and the final-defect estimate. |
| Section 5.1, density formulas | correct | The adjugate transpose, determinant denominator, and physical taper derivative match the energy and mass. |
| Section 5.1, exactness table | correct | The four degrees are 4, 6, 8, 8; the Duffy factor gives sufficient tensor orders 3, 4, 5, 5. |
| Lemma 5.1 and sign of (5.4) | correct | The parameter-square orientation gives native minus true mass, hence the displayed minus sign. |
| Lemma 5.2 and (5.6) | correct | Integrating the two field-difference terms against the absolute Jacobian gives all four constants. |
| Equations (5.7)–(5.9) | correct | Scalarization proves the vector interpolation bound; the interpolant derivative and Fourier-mode constants are valid. |
| Theorem 6.1 | correct | The affine sign tests, monotonicity in S, and fixed-sign affine-ratio argument prove the four-corner enclosure. |
| Equation (6.8) | correct | The stable expression is algebraically identical to the affine ratio, including infeasible corners with negative defect. |
| v2 coverage argument | correct | The homotopy preserves each pair union; a changed owner must meet the swept separator, and retained branches cover that set. |
| v2 absolute sliver correction argument | correct | The componentwise square-difference bound and absolute-Jacobian area bound remain valid under overlap and repeated coverage. |
| `pm.m` / `poly2.m`: multiplication | correct | Both implementations propagate the three terms of (4.4) with coefficient norms that are upper bounds. |
| `pm.m` / `poly2.m`: truncation | correct | Deleted coefficients are added to the error; discarding guess errors in inverse iteration is followed by an independent final-defect certificate. |
| `pm.m` / `poly2.m`: reciprocal | correct | Constant-coefficient centers are allowed; coefficient bounds certify kappa and a positive denominator before division. |
| `poly2.m`: rational triangle integration | correct | Its midpoint center uses the supplied whole-triangle determinant extrema, and its stopping test bounds the integrated geometric-series tail. |
| `pm.m` / `poly2.m`: sine/cosine as used | correct | All certificate calls have real polynomial arguments and include Taylor, input-model, and applicable product-truncation errors. |
| `pm.m` / `poly2.m`: panel moments | correct | Square moments, triangle factorial moments, panel scaling, and area-times-uniform-error allowances agree. |
| `interface_model.m`: certified inverse | correct | Corner bounds control the affine derivative on each cube; self-map, guess containment, and final-defect tests implement Lemma 4.3. |
| `interface_model.m`: branch margin | correct | The triangle displacement estimate places an actual native root in the retained cube; the common injective cube identifies overlapping extensions. |
| `interface_certificate.m`: `LOCAL_smooth` | correct | Polynomial integration includes inverse and geometry errors, while subdivision sums integral errors and takes maxima of component bounds. |
| `interface_certificate.m`: `LOCAL_sliver` | correct | Both native differences and both fitted-side bounds are retained; area and residual-change bounds give a nonnegative correction for the run's fixed s greater than 1. |
| `interface_residual.m` | correct | The three common-denominator numerators, material factor, inverse determinant, and collapse factor reproduce S. |
| `interface_fields.m` | correct | The native inverse gradient and original physical taper are used for the same native field in every branch. |
| `qj_certificates.m`: E | correct | Exact affine contributions, certified rational contributions, and taper contributions cover the native energy. |
| `qj_certificates.m`: native M | correct | Untapered mass uses polynomial-exact integration; taper mass adds its uniform-model error. |
| `qj_certificates.m`: C₀ and bias | correct | The determinant order and negative material contrast implement (5.5); the v2 localized bias replaces the older bias while retaining integration and taper errors. |
| `qj_certificates.m`: smooth S | correct | Affine, common nonaffine, and noninterface taper pieces are included, leaving fitted-interface pieces to v2. |
| `taper_certificate.m` | correct | The physical-x chain rule and the extra numerator-error divided by the positive determinant bound cover E, M, and smooth S. |
| `geometry_certificate.m` | correct | Quadratic extrema bound each determinant; vertex Frobenius bounds control the affine derivative and the fitted deformation. |
| `exact_basis.py` / `exact_rt3_basis.m` | correct | Exact rational verification confirms the edge-density identities and the interior kernel basis; both MATLAB coefficient tables agree. |
| `four_corners.m` | correct | All twelve affine sign tests and the minimum/maximum stable endpoints implement Theorem 6.1. |
| Combined reported enclosure | correct | Run-004 assembles all three templates and supplies the stated E/M rectangle and S upper bound to the passing four-corner certificate. |

## Q-1 — Rule (4.5) needs a real-valued polynomial model

**Form:** 3, missing hypothesis, demonstrated by a counterexample.  
**Class:** important caveat.  
**Location:** `research/explorations/numerical-directions/qj-bounds-proof.md:513–539`, especially line 534.

**Quoted text:**

> “For complex coefficients one may use … The following rules are all uniform on the panel.”

> “Sine and cosine: if the true real argument differs from P by at most ε, choose a real center a, bound N(P−a) ≤ D, and Taylor-expand sine or cosine about a through order L.”

The claimed error is $D^{L+1}/(L+1)!+\varepsilon$.

**Argument.** In the preceding complex polynomial-model setting, a real target argument does not force its approximating polynomial to be real-valued. On any panel take the true argument identically zero, the constant polynomial $P=i$, model error $e=-i$, $\varepsilon=1$, center $a=0$, $D=1$, and $L=3$. These satisfy the displayed hypotheses. The prescribed sine polynomial is

$$
P-\frac{P^3}{6}=\frac76 i.
$$

Its error relative to $\sin 0=0$ is $7/6$, whereas (4.5) allows only

$$
\frac1{4!}+1=\frac{25}{24}<\frac76.
$$

The real Taylor remainder and the real Lipschitz constant used in the proof cannot be applied along a complex argument. If $P$ is understood to be real-valued, the rule and its proof are correct; that restriction is the missing hypothesis in the general model statement.

**Smallest repair.** Add “$P$ is real-valued on the panel” to the sine/cosine rule. Equivalently, for a real target argument replace a complex $P$ by $\operatorname{Re}P$ before composing; this preserves the input error bound and does not enlarge the coefficient bound about a real center.

**Effect on the requested interval.** This is not an implementation blocker. The sine/cosine inputs actually used in `taper_certificate.m:11–13`, `qj_certificates.m:92–93`, and `interface_fields.m:13–14` are real coordinate polynomials multiplied and shifted by real scalars. In the last case, `interface_model.m:19–20` constructs X from the real native geometry and the real part of the curve correction. Thus the required restriction holds throughout the reviewed certificate.

## Verification record

The reviewed run-004 scalar certificate uses

$$
E\in[11.470912271614043,\ 11.470912271618044],\qquad
M\in[4.7230110180143914,\ 4.7230110180281955],
$$

$$
S_+=2.9475799376947328\times10^{-10},\qquad
s=3.4287286707248672.
$$

These values and the reported endpoints are in `test/numerical-directions/qj-cert-v2/output/run-004/science/interface-certificate.json`, with the E and smooth-S components in `certificates.json`. Independent scalar evaluation on the serialized inputs gives positive minima of approximately 3.0141, 0.9454, and 4.3916 for H, D_mu, and −D_nu, respectively, and confirms the stable/affine-ratio identity. This check addresses the assembly; floating-point rounding remains outside this review.

The basis verification executed the exact-fraction construction and assertions in memory, omitting the script's file-writing tail. It checked 72 complete edge-polynomial identities, 288 edge-moment entries, and 144 interior duality entries, and compared both MATLAB tables with the resulting integer matrix. The complete FEM/certification computation was not rerun.

Review literature verification completed. The supplementary Gauss citation was checked against NIST DLMF §3.5(v), equations (3.5.18)–(3.5.20_1): positive weight 1 on a finite interval gives positive Gaussian weights and exactness through degree 2n−1; affine scaling and tensor products give the rules used here. The manuscript also proves these facts directly. [NIST DLMF, Gauss Quadrature](https://dlmf.nist.gov/3.5#v).

All requested items were reviewed. The proof, problem statement, README, implementation, and retained outputs were not modified; only this review file was written.
