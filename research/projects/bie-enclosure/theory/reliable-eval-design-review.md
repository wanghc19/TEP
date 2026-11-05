# Review of the reliable evaluation design

**0 blockers, 0 important caveats, 1 minor caveat.** Sections 2–3 and Proposition CM prove the bounds needed for the central-material evaluator under their stated analytic and enclosure hypotheses. Section 4 proves the disk-mass bounds, and Section 5 proves the lead-tail certificate (RE24). RE-1 concerns the justification and logarithmic domain of the optional stopping formula (RE25).

This Review only pass covers reliable-eval-design.md. The geometry assertions in §7.1 and the manager's arithmetic checks were accepted as inputs. Line numbers below refer to the design. The verdicts concern the evaluation formulas and their hypotheses. Actual disk clearances, complex-domain bounds and propagation certificates are inputs to the proposed calculation.

| Step | Verdict | One-line check |
|---|---|---|
| Proposition G, star and lead curves, lines 44–72 | correct | The accepted bounds give $\lvert t_y-s_y\rvert<499/1000<d/2$ for every same-cell material pair, including both lead geometries. |
| G, wrap convention and periodic images | correct | The canonical pair has $m=0$. Translating target and source vertically by $k_t d,k_s d$ gives the constant index $m=k_t-k_s$, the same reduced difference and the fixed phase $q^{k_t-k_s}$. |
| G, longitudinal lead cells | correct | Translating the reference source and target together into a lead cell preserves both difference coordinates. |
| Continuous seam jumps, line 76 | correct | SW Step 3 removes the arc-length-null seam ties for the wrapped layer and its branch flux. Each configured Rayleigh mode and its derivative acquire the same factor $q$ under a transverse period. |
| §2.1, Müller cancellation | correct | Both material traces use the same double-layer density. The leading hypersingular term is independent of wave number and cancels in the difference before quadrature. |
| §2.1, logarithmic split and local terms | correct | T3.2 (Q3) gives the remaining log-sine term and analytic remainder after forming the removable quotients. The one-sided local density terms are evaluated separately. |
| (RE5), real targets | correct | For period one, $N=2n$, symmetric Nyquist interpolation, and density- and speed-weighted strip bounds, the two constants and both exponents agree with T3.2 (Q2). |
| (RE5), complex targets | correct | Uniform split-factor bounds on the complex target domain and source strip give (Q2c). Only the logarithmic tail loses width $b$, and (Q2d) defines its continuation. |
| Smooth material proxy contribution | correct | G fixes the real branch on the whole source period. The separate T3.0 complex-separation checks establish the analytic domain used for this smooth contribution. |
| Theorem S, Gauss nodes, line 107 | correct | Fewer than $n$ interior sign changes would give a polynomial of degree below $n$ whose product with the monic orthogonal polynomial has nonzero integral. |
| Theorem S, exactness and positivity | correct | Division by the orthogonal polynomial gives exactness through degree $2n-1$. Applying exactness to each squared Lagrange basis function gives positive weights summing to $2h$. |
| (RE6), vector error and constant | correct | The vector Cauchy remainder starts at degree $2n$. Integration and the positive quadrature each have norm $2h$, giving the stated factor $4h$. |
| (RE6), complex target and node enclosures | correct | A common bound $M$ over the target disk gives a uniform remainder. An enclosure of the exact quadrature sum supplies the separate finite-evaluation error. |
| Theorem R, (RE7) | correct | On each uncertain source interval the integral change is at most its parameter length times the supremum of the weighted branch difference. |
| Root coverage and ties, lines 123–129 | correct | Monotone arcs isolate regular roots, covering intervals retain possible merging roots, and isolated ties have zero source measure. |
| §2.4, analytic branches | correct | Each panel uses the continuation of its selected branch on a certified domain, including speed, distance and special-function branch checks. |
| §2.4, inner error ledger | correct | Kress, panel, uncertain-root and finite-evaluation errors add. On a complex target disk this bounds the fixed-reference integral, and (RE9) separately covers real branch changes. |
| Theorem O, source-band length, lines 147–155 | correct | Integrating $\lvert h'\rvert\ge c\lvert s-s_0\rvert^{q-1}$ on each monotone side gives the inverse-length bound of order $\Delta^{1/q}$. |
| O, target Hölder regularity | correct | The fixed-branch variation is locally Lipschitz, and only sources in the shifted height band change branch, giving exponent $1/q_*$. |
| O, analyticity at regular heights | correct | The local inverse of the height map is holomorphic at a simple root. Integrating holomorphic branch functions between these endpoints gives a locally analytic target function. |
| O, derivative polynomials and (RE8) | correct | Differentiation gives the displayed polynomials in $\cos\theta$. The accepted nonzero resultants exclude a common root of $Q,Q'$, and $Q(\pm1)\ne0$ excludes $\sin\theta=0$ at a stationary point. |
| O, conclusions for the configured curves | correct | The critical points are nondegenerate, giving exponent $1/2$ on walls. The material residual is analytic on its real parameter circle by G and the analytic self-interaction split. |
| Theorem M, (RE9)–(RE10) | correct | The true and center-selected branch integrals agree off $B_I$. On $B_I$ the supremum covers both branch values at the actual target throughout the panel. |
| M, moving endpoints | correct | The comparison is an integral over the set of changed sources. Its bound remains valid at a merging root and uses no endpoint derivative. |
| M, (RE11) | correct | The uniform error is the sum of the real branch-change bound, the scaled coefficient errors, and the geometric Cauchy tail for $R>h$. |
| M, (RE12) and polynomial norm | correct | The uniform error contributes at most $\sqrt{\lvert I\rvert}e_I$ in $L^2$. The deterministic polynomial supplies $V_I$, whose upper enclosure is used in the bound. |
| (RE13), regular moving intervals | correct | The affine map supplies the Jacobian $(b(t)-a(t))/2$. On the common certified complex domain it gives an analytic integral on a fixed parameter interval. |
| (RE14), root and endpoint perturbation | correct | In the common contraction disk the error obeys $e\le q_I e+d_I$. A holomorphic primitive bounds an endpoint change by path length times the kernel bound. |
| (RE15), target coefficient errors | correct | A holomorphic quadrature error uniformly bounded by $E_I$ on a disk of radius $R_0>h$ has coefficient errors $E_I/R_0^j$ and the displayed geometric sum. |
| §3.4, signed coefficient assembly | correct | The polynomial coefficients combine both sides and all local and smooth terms with their signs. The certified errors of these operations enter the error allowance. |
| (RE16), group assembly | correct | The finite panels partition the measured interfaces up to null endpoints. The omitted lead cells contribute the squared tail $T_g$ before the square root. |
| (RE17), group simplification | correct | The Euclidean triangle inequality for the vectors of panel norms gives the stated upper bound. The reverse norm comparison uses the exact deterministic polynomial norm. |
| CM, kernel and domain, lines 460–468 | correct | The expansion concerns a smooth matrix kernel on one fixed branch, with joint holomorphy on the specified product neighborhood and $R_s>h_s$. |
| (RE26), truncation and moment errors | correct | Source Cauchy bounds give $\|B_j(t)\|\le M/R_s^j$ uniformly in the complex target. Integration of the geometric tail against the density gives the first term and the finite moment errors give the second. |
| (RE27), Fourier moments | correct | The center phase follows from $s=c_s+u$. Parity gives the zero mode, and integration by parts gives the displayed boundary powers and minus sign for nonzero frequency. |
| CM, density bound and matrix extension | correct | The real-panel Fourier triangle bound gives $D_S=2h_s\sum_m\|\eta_m\|$. The same estimate applies to matrix moments in a subordinate norm. |
| CM with (RE15), line 499 | correct | For $R_t>h_t$, (RE26) bounds a holomorphic error uniformly over the target disk and therefore incurs at most the multiplier $1/(1-h_t/R_t)$. Calculated kernel-coefficient errors are accounted for separately. |
| (RE28), Hankel coefficient recurrence | correct | The coefficient of $v^n$ in $\zeta\mathcal G''+\mathcal G'+(\kappa^2/4)\mathcal G=0$ gives $(n+1)^2a_{n+1}$ and the displayed denominator at $\zeta_0\ne0$. |
| §4.1, eight in-column disks | correct | The interior field uses the ordinary continuous free-space layer. Certified center-side membership and boundary clearance greater than $R$ put the closed disk inside its homogeneous column. |
| §4.1, disjointness and mass addition | correct | Pairwise distances use globally translated disk centers. Disjoint disks with certified wall and seam clearance have additive mass contributions. |
| Theorem D, branch-fixed auxiliary field | correct | Uniform positive separation of every branch-fixed source image and proxy permits target differentiation under the integral on a neighborhood of the disk. The center values agree. |
| (RE18)–(RE19) | correct | T3.6 bounds the unweighted disk norm of the auxiliary field. The difference costs at most $\sqrt{\pi}R e_D$, followed by clipping, squaring and multiplication by $\rho_b$. |
| In-column specialization, line 317 | correct | Setting $e_D=0$ recovers the T3.6 lower bound from the certified center amplitude and Bessel factor. |
| (RE20), changed-source strip | correct | A changed pair crosses one cut when $R<d/2$. Its displacement from the cut is at most $R$, including a lower-cut crossing after translation by $d$. |
| (RE20), branch difference | correct | Up to a unit phase and sign the difference is $\Psi_\kappa$. The source-normal derivative is bounded by its gradient norm. The source integrals use SW arc length, equivalently $\lvert r'(s)\rvert\,ds$ in period-one coordinates. |
| §4.3, branch-fixed proxy clearance | correct | The branch-fixed argument is at most $R$ from the original box when $Y$ stays in its prescribed range. Subtracting $R$ from the proxy clearance is therefore valid, with physical-image clearance checked separately. |
| (RE21), rectangle alternative | correct | A uniform model error on the whole rectangle gives an $L^2$ loss of at most $\sqrt{\lvert B_j\rvert}e_j$. The retained disjoint rectangles give additive lower bounds. |
| Theorem L, (RE22) | correct | The representation includes source speed, target weights, local terms and the next-cell map $\mathsf P$ in the wall comparison. The common-density hypersingular difference is formed before taking kernel bounds. |
| (RE23), log-sine and density bounds | correct | Concavity and reflection give $\int_0^1\lvert L\rvert\le 2+2\log 2$. The coefficient norm sum bounds $\|H_b(s)\|$ uniformly. |
| (RE23), operator norm | correct | The pointwise matrix bound times $\sqrt{\lvert I_g\rvert}$ controls each boundary norm. Squaring and summing gives $B_L^2$ for the direct sum. |
| (RE24), contraction tail | correct | Writing $j=N+ip+h$ and using $\|\mathsf P^p\|\le r<1$ gives the squared-series factor $1/(1-r^2)$, with every transient power retained. |
| Main stopping rule, line 427 | correct | Testing $C_g\sqrt{T_g}$ against the group budget uses precisely the tail included in (RE16). The contracting-power assumption makes the test succeed eventually for positive budget. |
| Optional stopping depth (RE25), lines 429–435 | RE-1 | The formula follows directly from decay of the selected state. Its stated derivation as a one-step operator contraction does not follow from that hypothesis. |
| §7.2, T2.1–T2.3 and SW | correct | Ordinary layer regularity is used for the free-space part. SW supplies the full weak residual, and the spectral-distance step requires the combined upper bound to be smaller than the mass lower bound. |
| §7.2, T3.0 and T3.2 | correct | The design requires the relevant complex branches, strip bounds, kernel split, period, even quadrature order and Fourier continuation used by the cited estimates. |
| §7.2, T3.4a and T3.5 | correct | F6 supplies the local differential identity, CM supplies the complex-target error bound, and the stated ball evaluations must enclose the chosen analytic branches. |
| §7.2, T3.6 | correct | The disk estimate is used on the interior Helmholtz field or on the separated branch-fixed auxiliary field, with certified center amplitude and homogeneous-disk containment. |
| §7.2, T3.8 and SW24 | correct | Their block-series proof applies with the established $B_L^2$ upper bound on the squared operator norm and the certified contracting matrix power. |
| §7.2, T4.2–T4.3 and EP | correct | The trace constants require their stated collar hypotheses. EP concerns the separate switch-endpoint contribution. |

## RE-1 — Derive the optional depth from the state estimate

**Form 1, failed step. Class: minor caveat.** The issue is confined to the explanation of (RE25). For positive parameters the displayed depth is sufficient.

Line 429 assumes $\|\mathsf P^jc\|\le C_*r_*^j$. Line 435 then states “这个式子由 (RE24) 的逐步收缩特例解出。” A bound on this particular orbit does not supply the one-step operator hypothesis $\|\mathsf P\|\le r_*$ needed to specialize (RE24) with $p=1$ and $r=r_*$. For example, take $\mathsf P=\operatorname{diag}(1/2,3/4)$ and $c=(1,0)^T$. The state bound holds with $C_*=1$ and $r_*=1/2$, while $\|\mathsf P\|_2=3/4$.

**Smallest repair.** Sum the state estimate directly. For $0<r_*<1$,

$$
\left(\sum_{j=N}^{\infty}\|\mathsf L\mathsf P^jc\|_Y^2\right)^{1/2}
\le B_L C_*\left(\sum_{j=N}^{\infty}r_*^{2j}\right)^{1/2}
=\frac{B_L C_*r_*^N}{\sqrt{1-r_*^2}}.
$$

Comparison with $\epsilon>0$ gives (RE25) when $B_LC_*>0$. If $B_LC_*=0$ the tail is zero from $N=0$. If $r_*=0$ the state hypothesis makes the tail zero from $N=1$. These cases can be handled directly before taking logarithms.

Review literature verification completed for the internal results used here. The cited normalization and hypotheses were checked in reliable-bound.md and switch-line-proof.md. The wrap convention was checked in +kernel/qpgreen_mfs_pairmat.m, lines 84–89. The fixed material densities and disk coordinate convention were checked in the budget-v1 field definition. Only this review file was written.
