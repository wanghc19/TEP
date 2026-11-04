# Review of Theorem SW and Proposition EP

Result: **0 blockers, 0 important caveats, 0 minor caveats.** Theorem SW, its spectral-distance corollary, and Proposition EP are proved under their stated hypotheses. All requested proof steps were reviewed; no items remain TODO.

Scope: Review only of the requested steps in switch-line-proof.md, using reliable-bound.md (the operator-domain statement in T1.1, T2.1–T2.3, T3.8 and T4.2–T4.3), switch-line-kress-review.md and switch-line-sprime-review.md. SW means switch-line; EP means endpoint pairing. Previously reviewed formulas were checked only for changes and correct application. The numerical recalculations in §12 and the star-curve inequality were not repeated.

## Verdicts

Line numbers refer to switch-line-proof.md.

| Step | Verdict | One-line check |
|---|---|---|
| Step 2: ordinary free-space layer, lines 213–215 | correct | Subtracting the unwrapped primary kernel removes the true source singularity on the $m=0$ branch; T2.2 applies to the resulting ordinary continuous layer separately. |
| Step 2: targets near periodic source images | correct | Positive separation of each compact source curve from the transverse seams gives a positive distance from every nontrivial transverse source image to the closed target cell. |
| Step 2: targets near proxy locations | correct | Every active wrapped difference lies in the closed computational box, whose positive distance from every proxy bounds all required proxy derivatives. |
| Step 2: uniform remainder bounds, line 215 | correct | Near the true diagonal the singularities cancel; on its complement compactness, image separation and proxy separation bound the remainder and its first two branch derivatives. |
| Step 2: exceptional source heights, line 217 | correct | A nonconstant analytic height on a compact regular closed curve has finitely many critical points and finitely many preimages of each excluded height. |
| Step 2: sourcewise Green formula | correct | After removing the ordinary singular layer, the remaining branch functions are smooth on the finitely partitioned target pieces. |
| Step 2: Fubini, line 217 | correct | Bounded remainder derivatives, finite source length, bounded densities and compact longitudinal test support give absolute integrability of the volume and boundary terms. |
| Step 2: corners before tangential integration, line 226 | correct | Green's formula on the transverse pieces produces edge integrals only; there is no endpoint contribution at this stage. |
| Step 2: physical-interface signs, lines 82–90 and 232–235 | correct | Opposite outward normals give $J^{\rm br}_1\bar z+J^{\rm br}_0\overline{\partial_\nu z}$, with the printed material and seam conventions. |
| Step 2: switch sign in (SW15)–(SW16) | correct | The upper-minus-lower switch jumps contribute $-\mathcal J_1\bar z+\mathcal J_0\overline{z_y}$, hence the minus sign before $R_{\rm sw}$. |
| Step 2: boundary values and branchwise flux, line 242 | correct | Dominated convergence identifies the one-sided values, while the flux remains the defined integral of branch derivatives. |
| Step 3: tie set, lines 244–252 | correct | The sources with $s_y=0$ form an arc-length null set; the pointwise tie discrepancy is not asserted to vanish. |
| Step 3: continuous wrapped contribution to (SW4) | correct | Away from that null set, values and all relevant branch derivatives acquire the same factor $q$; the uniform bounds permit passage to their source integrals and seam limits. |
| Step 3: other contributions to the seam residual | correct | Non-quasi-periodic free-space or smooth additions remain in $Q_{\rm grp}^{\rm br}$ rather than being removed with the wrapped contribution. |
| Step 5: extension of tangential integration by parts, line 329 | correct | Graph-norm approximation gives convergence of the value and tangential derivative traces in $H^1(a,b)$, and Claim 2 identifies the endpoint limits with the continuous representative. |
| Step 5: (SW23) and its sign in (SW15) | correct | The formula follows from $\mathcal J_1=A_0+\partial_xE$ and $A_1=-E$; the entire switch pairing is still subtracted. |
| Step 5: dual weights, lines 338–344 | correct | The vectors $(A_0,\ell^{-1}A_1,-\ell^{-1}\mathcal J_0)$ and $(z,\ell z_x,\ell z_y)$ implement the SP-1 correction exactly. |
| Step 5: shared endpoints, line 347 | correct | Adjacent signed contributions combine as $E_{\rm left}-E_{\rm right}$; cancellation requires equality of these coefficients. |
| Step 5: material intersections and moving endpoints | correct | Every connected segment retains its ends, and integration in the source after fixed-source integration by parts introduces no derivatives of endpoint locations. |
| Step 6: boundary-state map and (SW24), lines 353–364 | correct | The fixed bounded map into the weighted boundary Hilbert space, wall ownership and contracting matrix power satisfy T3.8, and the tail enters the squared residual before its square root. |
| Step 6: per-source line map and (SW25), lines 366–379 | correct | T3.8 applies for each fixed reference source, with $\Theta_{\rm line}(s)$ bounding that map's squared operator norm. |
| Step 6: separate line-tail bound (SW26) | correct | Applying $\sqrt{a+b}\le\sqrt a+\sqrt b$ after the squared tail gives the displayed integral of $\sqrt{\Theta_{\rm line}(s)}$ and factor $(1-r^2)^{-1/2}$. |
| Step 6: endpoint tail (SW27), lines 388–405 | correct | The unsquared state estimate summed over $j=N+ip+h$ gives $1/(1-r)$ and retains both endpoints at each inner wall. |
| Step 6: finiteness of source integrals, line 407 | correct | Compact analytic source curves, bounded coefficient maps and a uniform finite bound on the number of horizontal intersections control the line and endpoint maps. |
| Step 7: reference-cell $L^2$ field map, line 411 | correct | The ordinary layer is locally $L^2$, the source-integrated branch remainder is bounded on the reference cell, and the smooth addition is bounded there. |
| Step 7: $\widehat u\in\mathcal H$, lines 411–415 | correct | Finite-dimensional boundedness and the contracting-power squared series give the global mass norm without a hypothesis on $\nabla\widehat u$. |
| Step 7: continuity of the residual terms, lines 417–418 | correct | The boundary trace estimate, line estimate and absolutely summable endpoint bounds make the right-hand side continuous in the $A+\mu$ graph norm. |
| Step 7: continuity of the left-hand side | correct | Selfadjoint nonnegativity gives $\|(A-\mu)z\|_{\mathcal H}\le\|(A+\mu)z\|_{\mathcal H}$, and $\widehat u\in\mathcal H$. |
| Step 7: dense test class, line 420 | correct | Longitudinal cutoffs and periodic smoothing after the gauge transform approximate every $H^2_\beta(B)$ function in $H^2$. |
| Step 7: extension of (SW15) to $D(A)$ | correct | The mass bounds and the cylindrical Fourier estimate give equivalence of the $H^2$ and positive graph norms, so both sides pass to the same limit. |
| §8: resolvent test, lines 453–459 | correct | $\widehat u\in\mathcal H$ suffices for $z=(A-\mu)^{-1}\widehat u\in D(A)$ and $R(z)=U^2$ when $\mu$ is in the resolvent set. |
| §8: spectral-distance inequality (SW28) | correct | The multiplier bound $1+2\mu/\operatorname{dist}(\mu,\sigma(A))$ and $U>Q$ give the displayed radius. |
| EP: signed endpoints and height convention, lines 474–482 | correct | Under $h\mapsto h+kd$, $\gamma\mapsto q^k\gamma$ preserves both $\gamma\overline{z(x_w,h)}$ and the Fourier moments. |
| EP: finite pushforward measure (EP1) | correct | The integrable endpoint coefficients define a finite complex measure with total variation at most $V_w$. |
| EP: wall pairing and remaining endpoints, lines 495–499 | correct | Both sides of each wall are combined before taking a norm; non-wall ends remain explicitly in $M_{\rm other}$. |
| EP: Fourier normalization (EP2)–(EP3) | correct | The factor $d^{-1/2}$ and reciprocal weights $[4(\alpha+\beta_m^2)^{3/2}]^{-1}$ are dual to the wall-trace norm in (EP7). |
| EP: wall-trace estimate (EP7), lines 544–561 | correct | Cauchy–Schwarz in the longitudinal Fourier variable gives the stated factor $1/[4(\alpha+\beta_m^2)^{3/2}]$ for each mode, then summation gives constant one. |
| EP: finite measures in the dual space, line 563 | correct | $\lvert\widehat\zeta_{w,m}\rvert\le V_w/\sqrt d$ and the convergent reciprocal-weight series imply a finite norm; an atom has norm $\lvert a\rvert\sqrt{S(\alpha)}$. |
| EP: uniform convergence and measure integration | correct | (EP7) and summability of the reciprocal weights give absolute uniform convergence of the wall Fourier series, allowing termwise integration against the finite measure. |
| EP: conjugation and pairing (EP8) | correct | Integrating the conjugated Fourier series gives $\sum_m\widehat\zeta_{w,m}\overline{z_m(x_w)}$, followed by the stated weighted Cauchy–Schwarz bound. |
| EP: exact volume identity, lines 574–577 | correct | For $H^2_\beta(B)$, longitudinal cutoff and quasi-periodic boundary cancellation give the cross term $2\alpha\|\nabla z\|_2^2$. |
| EP: mass and Laplacian estimates, lines 578–579 | correct | The bounds are $\|z\|_2^2\le\rho_{\min}^{-1}\|z\|_{\mathcal H}^2$ and $\|\Delta z\|_2^2\le\rho_{\max}\|Az\|_{\mathcal H}^2$, with the energy term exactly $(Az,z)_{\mathcal H}$. |
| EP: joint multiplier (EP9) | correct | Spectral calculus on the nonnegative selfadjoint $A$ gives the polynomial quotient in (EP4) on $\lambda\ge\lambda_0$. |
| EP: explicit supremum in (EP4), lines 589–593 | correct | The derivative's affine numerator allows no interior strict maximum; when its slope is negative, its intercept is also negative, so only the lower endpoint and the limit $\rho_{\max}$ are needed. |
| EP: collective endpoint bound (EP5) | correct | Sum (EP8) over walls, use (EP9), and apply the point estimate to $M_{\rm other}$; $\sum_wV_w<\infty$ justifies the infinite sum. |
| EP: comparison (EP6), lines 595–609 | correct | The total-variation bound gives the first inequality, and $\rho_{\max}\ge\rho_{\min}$ makes the cross term in the comparison square at least $2\alpha\lambda$. |
| EP: optimization in $\alpha$ | correct | The inequalities hold for every common $\alpha>0$ and therefore also after taking the corresponding infima. |
| EP: critical source heights, line 611 | correct | The proof uses the finite pushforward measure directly and does not require its density to be in $L^2$ or the height derivative to be bounded below. |
| EP: finite moments and errors (EP10) | correct | Modewise absolute errors control the retained coefficients, while the omitted coefficients are bounded by $V_w/\sqrt d$. |
| EP: Fourier-tail integral (EP11), lines 629–636 | correct | $\omega M>\lvert\beta\rvert$ makes both tails decreasing, and rationalizing the exact integral gives the displayed denominator and factor $1/(4d\omega)$. |
| EP: truncation wall and lead tail, line 637 | correct | The retained side stays in the computed measure and all omitted ends are bounded by (SW27), multiplied by $C_{\rm vol}(\alpha)\sqrt{S(\alpha)}$. |
| §7 citation table: T2.1–T2.2 | correct | The regularity result is applied to the ordinary free-space layers; separation and direct branch bounds justify the remainder argument without assigning $H^2$ regularity to the superposed wrapped field. |
| §7 citation table: T2.3 | correct | Its seam convention and resolvent algebra are retained, while Steps 2–7 supply the replacement Green identity explicitly. |
| §7 citation table: T4.2 | correct | The flat collars are injective, have zero curvature and multiplicity one, with $2\delta<d$; the stated boundary-group hypotheses cover the other interfaces. |
| §7 citation table: T4.3 | correct | The established trace estimates, positive mass bounds, selfadjoint nonnegativity, spectral bottom and positive shift match the multiplier argument. |
| §7 citation table: T3.8 | correct | Fixed linear maps, Hilbert residual spaces, one-count wall ownership and (SW3) justify the squared tails; the endpoint absolute sum is proved separately. |

## Verification record

Review literature verification completed for the internal results used here. The cited operator-domain and trace/propagation statements were inspected in reliable-bound.md and matched to the objects in the new proof. The earlier S-1–S-3 and SP-1 repairs are incorporated with the same branchwise-flux convention, switch sign, seam exception and dual weights.

No numerical computation, implementation check, or repeat of the manager's listed numerical and geometry checks was performed. The reviewed source files were not modified; only this review file was written.
