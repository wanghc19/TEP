# Review of the final core count for isolation hypothesis (H)

Scope and files inspected: Review only of claim (D), with the supplied upstream premises accepted and rounding excluded; inspected `h-cert-proof.md` §§5.1, 5.2, 6.1, 6.3, 6.4 and (7.1), its trapezoid bound (2.11), `h-cert-problem.md` §2 for the supplied counting statement, the requested sections and proof block of `test/numerical-directions/h-core-v1/README.md`, `core_space.m`, `core_curve.m`, `core_material.m`, `core_run.m`, supporting `core_checks.m` and `report_core.py`, `certificate.json`, `checks.json`, run-001/run-002 `science/result.json`, run-003 `science/validation.json`, both `h-dtn-v1` certificate JSON files for input conventions, and `fem-pipeline-v1/direct_native.m` and `direct_native_config.m` for geometry and material conventions. Here `h-core-v1` denotes version 1 of the core count for hypothesis (H).

Result: **0 blockers, 0 important caveats, 0 minor caveats.** Under the supplied premises and exclusion of floating-point rounding, the reviewed construction establishes $n(L_{\rm cert})=1$ and the conclusion of Theorem S.2.

| Item | Verdict | Check |
|---|---|---|
| §5.1: form-domain identities (5.1) | correct | Cosine and transverse Fourier expansions give both norms on $H^1_{\beta_0}(D)$ without imposing port boundary conditions on the functions. |
| §5.1: Proposition D.1, (5.2) | correct | Energy orthogonality to the enriched space eliminates every retained reference coefficient, so the omitted-mode bound remains valid. |
| §5.1: rectangular cutoff (5.3) | correct | The two ways to leave the index rectangle give exactly the displayed minimum at $\beta_0=0.5$. |
| §5.2: exact representatives, (5.4)–(5.5) | correct | The homogeneous interior equation and unit outward derivative at the designated port give the stated Riesz identities and zero retained traces on the complement. |
| §6.1: Theorem S.1 | correct | Exact port enrichment removes all retained boundary terms involving the complement; completing the energy square gives (6.5). |
| §6.1: negative-index implication | correct | Projection is injective on every negative subspace, and the projected finite form is negative there. |
| §6.3: scalar matrix (6.7) | correct | Weighted Cauchy–Schwarz gives $G\preceq q_{\max}C_h^2Q$, yielding the mass factor $1/c_W$. |
| §6.4: Theorem S.2 | correct | The supplied count on $[\alpha_-,\alpha_+)$ is at most one, while the interior spectral intersection makes it at least one, including multiplicity. |
| §7.1: perturbation statement (7.1) | correct | Congruence by $H_0^{-1/2}$ and the eigenvalue min-max bound give a strictly positive second eigenvalue after the stated perturbation. |
| README: space and projection constant | correct | The 1056 cosine–Fourier functions plus 66 representatives retain the stated $a_*$ and $C_h=a_*^{-1/2}$. |
| README: representative energy Gram and traces | correct | The Gram is $[\mathrm{ct},\mathrm{cs};\mathrm{cs},\mathrm{ct}]/q$, with the displayed left and right trace rows. |
| README: tail Gram and energy normalization | correct | Subtracting $V_k^*D_k^{-1}V_k$ removes the energy projection, and the inverse upper Cholesky factor normalizes the residual representatives. |
| README: analytic unweighted mass | correct | The base–representative block is $D_k^{-1}V_k$; direct cosh integration gives both representative–representative formulas. |
| README: material mass decomposition | correct | With $\rho=1+3\mathbf1_{\rm star}$, $Q=(\lambda+1)M^1+3\lambda M^{\rm star}$. |
| README: boundary moments and zero denominators | correct | The two divergence formulas have the stated signs; either nonzero denominator is valid, and the constant case uses the exact star area. |
| README: complex strip bounds and trapezoid remainder | correct | The Fourier form of the boundary controls its real and imaginary parts and derivatives, giving $4\pi g\exp(\mathrm{growth})/\operatorname{expm1}(hJ)$. |
| README: grouping exponential moments | correct | Reflection symmetry in $y$, the cosine product identity and the exact representative exponential formulas justify the frequency grouping and real parts. |
| README: raw entrywise error to operator error | correct | The symmetric nonnegative entrywise envelope bounds the Hermitian error by its maximum row sum. |
| README: propagation through $P$ | correct | The congruence error is bounded by $\|P\|_1\|P\|_\infty$ times the raw row-sum bound. |
| README: $c_W$, $\epsilon$ and safe shift | correct | With $c_W>0$, multiplying the normalized star error by $3\lambda/c_W$ and subtracting $\epsilon I$ gives a lower matrix. |
| README: counting and integration enclosure | correct | The shifted matrix is below the exact scalar lower matrix, and its negative index bounds the continuous count in the required direction. |
| `core_space.m`: raw basis and tail Gram | correct | The mode ordering, normalization, energy cross block and two-port Gram implement the stated enriched space. |
| `core_space.m`: coefficient map $P$ and $H=I$ | correct | Its columns are normalized base modes and normalized residual representatives, so $P^*H_{\rm raw}P=I$ in exact arithmetic. |
| `core_space.m`: `B_left`, `B_right` | correct | The right cosine trace includes $(-1)^m$, and both raw trace matrices are multiplied by the same coefficient map $P$. |
| `core_space.m`: $a_*$ and norm bound | correct | The cutoff constant and `norm(P,1)*norm(P,inf)` implement the required projection and congruence bounds. |
| `core_curve.m`: curve and orientation | correct | The center-cell curve and its derivatives agree with `direct_native.m` at `star_scale=1`; the boundary has positive orientation. |
| `core_curve.m`: moment formula and remainder | correct | The code chooses the larger nonzero denominator, handles the constant moment exactly, and applies the derived strip bound to every other moment. |
| `core_material.m`: cosine–cosine block | correct | Difference and sum frequencies, transverse reflection and normalization factors give the correct raw Gram entries and error sums. |
| `core_material.m`: mixed and representative blocks | correct | The two-term and four-term exponential products use the correct left/right weights, offsets and transverse frequency differences. |
| `core_material.m`: normalized error | correct | All block errors enter the corresponding row sums, followed by the safe basis-change norm factor; Hermitian symmetrization preserves the bound. |
| `core_run.m`: $Q$, $U$ and boundary term | correct | Upper Cholesky factors satisfy $R^*R=\widehat\Lambda$, so $U^*U$ equals the two boundary contributions in the same basis as $Q$. |
| `core_run.m`: center and $L_{\rm cert}$ | correct | The code forms $I-Q/c_W+U^*U$ and subtracts exactly the propagated integration error. |
| `core_run.m`: LDL inertia | correct | Counting the signs of all one- and two-dimensional diagonal blocks gives the Hermitian inertia by congruence. |
| `core_run.m`: shifted LDL test | correct | One negative direction and no zero pivot for `center-safe_gamma*I` imply $\lambda_2(\mathrm{center})>\mathrm{safe\_gamma}$. |
| `core_run.m`: combined finite tests | correct | The direct count is one, and `safe_gamma>epsilon` gives a strictly positive second eigenvalue of $L_{\rm cert}$. |
| DtN input normalization and Fourier ordering | correct | Both JSON inputs use the same unscaled coefficients, indices $-16,\ldots,16$, frequencies and physical port order as the core trace matrices. |
| `certificate.json` against run-002 | correct | The dimension, constants, count, shifted eigenvalue data, error and positive second-eigenvalue bound agree with the source record. |
| `checks.json` against the source records | correct | The counting-related summaries agree with the recorded tests, and the additional validation entries reproduce run-003. |
| Claim (D) and hypothesis (H) | correct | The finite upper bound on the negative index and the supplied interior spectral intersection satisfy the remaining hypotheses of Theorem S.2. |

There are no objections to enumerate. All requested items were reviewed.

Read-only consistency checks confirmed the exported data, both input frequency conventions, $a_*$, the mass-error propagation and both recorded LDL tests. The source record gives $\epsilon=2.0620331764508243\times10^{-9}$ and $\mathrm{safe\_gamma}-\epsilon=0.36537368868193165>0$. No MATLAB experiment was rerun.

Review literature verification completed. The supplied upstream results were used only as premises. The proof and implementation files were not modified; only this review file was written.
