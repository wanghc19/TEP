# Review of Proposition S′

Result: **0 blockers, 1 important caveat, 0 minor caveats.** The signs of $A_0,A_1,E$ are correct. Proposition S′ gives the proposed residual bound for $\ell=1$; for general $\ell>0$, correct the residual weights as in SP-1. The point constant at $\alpha=14.18$ is approximately $0.7834824007$.

Scope: Review only of §2′ of switch-line.md, using its repaired §2, switch-line-kress-review.md, and reliable-bound.md, T4.2–T4.3 and T3.8. The branchwise-flux weak Green identity is an accepted premise. Floating-point rounding, implementation, cost and the numerical size of the switch residual were excluded.

## Verdicts

Line numbers refer to switch-line.md.

| Step | Verdict | One-line check |
|---|---|---|
| Branchwise-flux convention, lines 52–63 | correct | S′ rewrites the same $R_{\rm sw}$; it does not replace the branchwise flux by a derivative of the source-integrated field. |
| Tangential differentiation of jumps, line 101 | correct | On a fixed horizontal segment, both one-sided branches are smooth and the wrapping phase is constant in $x$. |
| Helmholtz substitution, line 102 | correct | Each branch has the same constant wave number within the material piece, so $[\partial_y^2\widetilde G]=-\partial_xg_x-\kappa^2g_0$. |
| Source-normal derivative convention | correct | On each branch, $\partial_{\nu_s}\widetilde G=-n_x\partial_x\widetilde G-n_y\partial_y\widetilde G$, with the source and its normal held fixed during the $x$ integration. |
| Expansion of $\mathcal J_1$ | correct | $\mathcal J_1=A_0+\partial_xE$, where $E=\tau(n_yg_x-n_xg_y)$. |
| Integration by parts, lines 108–111 | correct | $\int E_x\bar z=[E\bar z]_a^b-\int E\overline{z_x}$, and $A_1=-E$. |
| Signs of $A_0,A_1,\mathcal J_0,E$, lines 117–120 | correct | All four displayed expressions have the correct signs. |
| Endpoint orientation | correct | The contribution is $E(b)\bar z(b)-E(a)\bar z(a)$ when the segment is oriented by increasing physical $x$. |
| Regularity for integration by parts, line 105 | correct | The line trace of $z\in H^2_\beta(B)$ has an $L^2$ tangential derivative and continuous endpoint values; no point value of $\nabla z$ is needed. |
| Claim 1: full-gradient line trace, line 135 | correct | Summing the component estimates gives $D_0\|\nabla z\|_2^2+D_1\|D^2z\|_F^2$, without a factor of two. |
| Claim 1: same polynomial $p$ and $C_{\rm line}$ | correct | Adding the value estimate gives exactly the coefficients $D_0/\rho_{\min}$, $D_1+\ell^2D_0$, and $\ell^2D_1\rho_{\max}$ from T4.3. |
| Definition of $e'_s$, line 130 | SP-1 | Its weights are not dual to the trace norm in Claim 1 unless $\ell=1$. |
| Claim 2: mixed Fourier normalization, lines 136–143 | correct | A unitary inverse transform has prefactor $(2\pi d)^{-1/2}$, yielding precisely $S(\alpha)=d^{-1}\sum_m[4(\alpha+\beta_m^2)^{3/2}]^{-1}$. |
| Claim 2: point values for $H^2_\beta(B)$ | correct | The reciprocal-weight integral is finite, so Fourier inversion gives a continuous representative and a uniform point bound. |
| Claim 2: passage from $\Delta$ to $A$, line 143 | correct | $\|\Delta z\|_2\le\sqrt{\rho_{\max}}\|Az\|_{\mathcal H}$ and $\|z\|_2\le\rho_{\min}^{-1/2}\|z\|_{\mathcal H}$. |
| Claim 2: spectral multipliers, line 146 | correct | $\|z\|_{\mathcal H}\le(\lambda_0+\mu)^{-1}\|(A+\mu)z\|_{\mathcal H}$ and $\|Az\|_{\mathcal H}\le\|(A+\mu)z\|_{\mathcal H}$. |
| Claim 2: minimization and numerical value | correct | Each $\alpha>0$ gives a valid bound; at $14.18$ its value is about $0.7834824007$, and scalar minimization gives about $0.7834823943$ near $14.18314$. |
| Claim 3: integration over sources, line 149 | correct | The integral triangle inequality applies to both the line functional and the endpoint functional. |
| Claim 3: inner walls between lead cells | correct | Both incident segment ends must be retained; taking their separate absolute values is safe even if their signed coefficients do not cancel. |
| Claim 3: propagation tail | correct | The stated cell-by-cell absolute sum converges under the inherited contracting-power assumption, with the $L^1$ tail specified below. |
| Endpoints on material curves in other configurations | correct | Split into homogeneous segments and include every segment endpoint; the displayed point terms then cover these intersections as well. |
| Additional corner or moving-endpoint terms | correct | There is only one tangential integration by parts at fixed source; no derivative of $a_s$ or $b_s$ is taken and no further corner term appears. |
| Combined $Q$, line 126 | SP-1 | With the corrected weights, or with $\ell=1$, it bounds the residual functional in the repaired weak Green identity. |

## SP-1 — Use the dual residual weights, or restrict to $\ell=1$

**Form:** 3 — Missing hypothesis. **Class:** important caveat.

**Quoted text:** Line 130 defines

$$
e_s'^2=\int_{\Lambda_s^P}
\left(\ell^{-2}|A_0|^2+|A_1|^2+|\mathcal J_0|^2\right)\,dx,
$$

while Claim 1, line 135, bounds

$$
\|z\|_\Lambda^2+\ell^2\|\nabla z\|_\Lambda^2
\le C_{\rm line}^2\|(A+\mu)z\|_{\mathcal H}^2.
$$

**Argument.** After the integration by parts, the line integrand in $R_{\rm sw}$ is

$$
A_0\bar z+A_1\overline{z_x}-\mathcal J_0\overline{z_y}.
$$

The coefficient vector dual to $(z,\ell z_x,\ell z_y)$ is
$(A_0,\ell^{-1}A_1,-\ell^{-1}\mathcal J_0)$. Its squared norm has weights
$1,\ell^{-2},\ell^{-2}$, not $\ell^{-2},1,1$. For example, with $\ell=2$ and scalar data $A_0=z=1$, $A_1=\mathcal J_0=z_x=z_y=0$, the proposed weighted Cauchy–Schwarz step would assert $1\le1/2$. Thus Claim 1 does not give the claimed general-$\ell$ estimate from the printed $e'_s$.

**Smallest repair.** For the present $\ell=1$ calculation, explicitly state $\ell=1$ in S′; nothing numerical changes. To retain arbitrary $\ell>0$, replace line 130 by

$$
\boxed{\displaystyle
e_s'^2=\int_{\Lambda_s^P}
\left(|A_0|^2+\ell^{-2}|A_1|^2+
\ell^{-2}|\mathcal J_0|^2\right)\,dx.}
$$

Then Cauchy–Schwarz uses exactly Claim 1, with its unchanged $C_{\rm line}$. The endpoint term and all integration-by-parts signs remain unchanged.

## Checked identities and endpoint accounting

No sign corrections are needed. With the definitions printed on lines 117–120, the full fixed-source switch pairing is

$$
\int_a^b(\mathcal J_1\bar z-\mathcal J_0\overline{z_y})\,dx
=\int_a^b
\left(A_0\bar z+A_1\overline{z_x}
-\mathcal J_0\overline{z_y}\right)\,dx
+[E\bar z]_a^b.
$$

This remains the $R_{\rm sw}$ that is **subtracted** in the weak Green identity on line 57. Taking absolute values gives the proposed positive contributions to $Q$.

For a common endpoint $p$ between two consecutive segments, the signed endpoint contributions combine as

$$
\bigl(E_{\rm left}(p)-E_{\rm right}(p)\bigr)\overline{z(p)}.
$$

They cancel only when the two coefficients agree. The separate bound
$C_{\rm pt}(|E_{\rm left}(p)|+|E_{\rm right}(p)|)
\|(A+\mu)z\|_{\mathcal H}$ is valid without that equality. In particular, assigning an inner wall to only one cell, as is possible for a preassembled wall-jump residual, would not justify dropping one of these two endpoint contributions.

For completeness, the tail appropriate to the endpoint sum is as follows. Let $v_j=\mathsf P^jc$ be the state in lead cell $j$. Let the endpoint coefficients be the fixed linear functionals
$E_\epsilon(s;v)=L_\epsilon(s)v$, including **all** ends of all connected segments in that cell, and set

$$
B_{\rm end}=\int_\Gamma\sum_\epsilon\|L_\epsilon(s)\|_2\,ds.
$$

If $\|\mathsf P^p\|_2\le r<1$, the inherited propagation hypothesis gives

$$
\boxed{\displaystyle
\sum_{j=N}^\infty\int_\Gamma\sum_\epsilon
|E_\epsilon(s;\mathsf P^jc)|\,ds
\le
\frac{B_{\rm end}}{1-r}
\left(\sum_{h=0}^{p-1}\|\mathsf P^h\|_2\right)
\|\mathsf P^Nc\|_2.}
$$

Indeed, write $j=N+ip+h$ and sum the bound
$\|\mathsf P^jc\|_2\le\|\mathsf P^h\|_2r^i\|\mathsf P^Nc\|_2$ without squaring. Multiply this tail by $C_{\rm pt}$. The $1/(1-r^2)$ formula of T3.8 bounds a sum of **squares**, so it cannot be substituted for this endpoint tail. Line integrals may still use the squared tail after grouping their disjoint segments in an $L^2$ norm; alternatively their cell-by-cell norm sum admits the same $L^1$ argument.

If a switch intersects a material curve, apply the identity separately on every connected homogeneous segment. The conditions are that the branch kernels are smooth up to those ends, their wave number is constant on each open segment, and every end is included in the endpoint sum. Global $z\in H^2_\beta(B)$ gives the same continuous point value from all incident pieces. Under these conditions the displayed endpoint terms are the entire contribution: there is no additional corner term. A material endpoint may be omitted only after proving cancellation of its incident signed $E$ coefficients. Source-dependent endpoints cause no extra term because the subsequent operation is integration in $s$, not differentiation in $s$.

## Point constant and verification record

Use $\beta_m=\beta+2\pi m/d$ and the unitary normalization

$$
z(x,y)=\frac1{\sqrt{2\pi d}}
\sum_{m\in\mathbb Z}\int_{\mathbb R}
\widehat z_m(\xi)e^{i\xi x+i\beta_my}\,d\xi,
\qquad
\|z\|_2^2=\sum_m\int_{\mathbb R}|\widehat z_m(\xi)|^2\,d\xi.
$$

Weighted Cauchy–Schwarz yields the asserted constant because

$$
\frac1{2\pi d}\sum_m\int_{\mathbb R}
\frac{d\xi}{(\alpha+\xi^2+\beta_m^2)^2}
=\frac1d\sum_m\frac1{4(\alpha+\beta_m^2)^{3/2}}.
$$

The sum is finite, which also gives absolute Fourier inversion for the continuous representative of an $H^2$ function. The point estimate holds uniformly at walls, seams and material intersections.

Summing the scalar line-trace estimate for the two gradient components uses
$|\partial_y\partial_xz|^2+|\partial_y^2z|^2\le|D^2z|_F^2$ and
$|\partial_xz|^2+|\partial_yz|^2=|\nabla z|^2$. This is why Claim 1 has no extra dimensional factor. The cited T4.3 spectral multiplier then applies to the same polynomial.

A short Python check was run from tmp/ through the requested Conda environment. The sum defining $S$ used modes $-4096,\ldots,4096$ and lower/upper integral bounds for the remaining positive decreasing tails. Writing $c=2\pi/d$, the integral upper tail starting at $M$ is

$$
\frac1{4dc}\sum_{\pm}
\frac1{\sqrt{\alpha+(cM\pm\beta)^2}
\left(\sqrt{\alpha+(cM\pm\beta)^2}+cM\pm\beta\right)};
$$

using $M+1$ gives the lower integral tail. With rounding excluded as requested, this brackets the expression at $\alpha=14.18$ approximately between
$0.7834824006661$ and $0.78348240066795$. Thus $0.78348$ is consistent as an approximate value; $0.783483$ is a conservative decimal choice for this derived bound. A scalar minimization returned $\alpha\approx14.18314$ and approximately $0.7834823943$; the fixed-$\alpha$ bound does not depend on proving global optimality.

Review literature verification completed for the invoked previously reviewed statements: the uses of T4.2, T4.3 and T3.8 were checked against their displayed proofs. No external literature dependency was introduced. The reviewed files were not modified; only this review file was written.
