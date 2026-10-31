# Stage 2: decomposition of the reliable eigenvalue bound

The control radius is **209.51 times the BIE reference error**. Moment enclosures account for a factor of **2.48**. Removing those allowances and the other auxiliary terms leaves an $E_v$ contribution **57.8 times** the reference error. That remaining comparison combines the trial field, the first-order spectral inequality, and material weights; the retained scalars do not separate them. In particular, the records leave open whether a second-order bound applied to I9.6's reconstructed field would already solve most of the problem. [J96] [REF]

All error comparisons use the boundary integral equation (BIE) value as a numerical reference. I9.6's theorems bound distance to the continuous spectrum; identifying and isolating the particular guided eigenvalue requires additional spectral information. The reported reliable values follow the exact-arithmetic convention in the experiment README, with floating-point rounding still unverified. [T96] (Theorems 1–2) [R96]

## Factor budget

The fixed values are $k_0=1.558438079544167$, $\mu_0=2.4287292477733113$, and $k_B=1.5584378941820909$. Small arithmetic gives

$$
\Delta k=1.853620761\times10^{-7},\qquad
\Delta\mu=(k_0-k_B)(k_0+k_B)=5.77750601436\times10^{-7}.
$$

The control values are $R_\mu=1.210431044764066\times10^{-4}$ and $R_k=3.883523325076688\times10^{-5}$, hence $R_\mu/\Delta\mu=209.50754$ and $R_k/\Delta k=209.51013$. [J96] (`k`, `mu`, control `exact`) [REF]

For the following algebra, write $Q=\delta_u^++E_v^++\varepsilon_0^+$ and $Q_0=Q-\text{moment term}$. The control values are $Q=1.14158801324\times10^{-5}$, $Q_0=4.60600455769\times10^{-6}$, and $E_v=3.14971990860\times10^{-6}$. The table gives an exact scalar factorization up to displayed rounding; its material and defect rows deliberately use a stated coefficient benchmark. [J96] (control)

| Factor | Control value | Meaning and what the records establish |
|---|---:|---|
| Moment allowance, $Q/Q_0$ | **2.47848** | Computed from the recorded upper terms. This is the numerator sensitivity to removing the moment allowance while holding the other recorded quantities fixed. [J96] |
| Other auxiliary terms, $Q_0/E_v$ | **1.46235** | Computed from $\delta_u$, $c_RE_R$, and $E_y/b_M$. Includes their actual approximation allowances as well as evaluation slack. [J96] |
| Material coefficient benchmark, $C_\rho/(2\mu_0)$ | **2.18282** | $C_\rho=10.60296059075$ versus the coefficient $2\mu_0=4.85745849555$ in material $\rho=1$. Algebraic comparison; an actual gain of this size would require the defect to lie mainly in that material. [J96] [T96] (equations (6)–(8)) |
| Defect versus eigenvalue benchmark, $2\mu_0E_v/\Delta\mu$ | **26.48138** | Remaining ratio after the preceding coefficient comparison. It combines field/reconstruction quality and first-order spectral slack. It is not a measured eigenfunction error. [J96] [REF] |
| Finite denominator, $1/(D_0^- -\varepsilon_0^+)$ | **1.00000807** | Computed; the denominator is $0.999991925818$. It causes negligible inflation. [J96] |
| Conversion to $k$, $(k_0+k_B)/(k_0+\sqrt{\mu_0-R_\mu})$ | **1.00001240** | Computed; conversion changes the error ratio by about $0.00124\%$. [J96] [REF] [T96] (equations (11a)) |

Thus $2.47848\times1.46235\times2.18282\times26.48138\times1.00000807\times1.00001240\simeq209.51013$. The more direct comparison, without a material benchmark, is $209.51013=2.48249\times84.39506$: reliable control $R_k$ divided by ordinary control $R_k$, then ordinary control $R_k$ divided by $\Delta k$. Neither factorization assigns an independent numerical factor to “field error” and “first order.” [J96] [REF]

The additive budget helps distinguish the parts of that product. The last column is each control contribution to $R_\mu$, divided by $\Delta\mu$; its sum is $209.50754$. [J96] [REF]

| Input term | Control ordinary value | Control upper value | Control contribution / $\Delta\mu$ |
|---|---:|---:|---:|
| $E_v$ | $3.149720\times10^{-6}$ | same | **57.805** |
| $\delta_u$ | $1.609061\times10^{-7}$ | $1.682473\times10^{-7}$ | 3.088 |
| $c_RE_R$ | $9.069383\times10^{-7}$ | $9.069812\times10^{-7}$ | 16.645 |
| $E_y/b_M$ | $3.810561\times10^{-7}$ | same | 6.993 |
| Moment term | omitted | $6.809876\times10^{-6}$ | **124.977** |
| $\varepsilon_{\rm alg}$ | omitted | zero, remainders charged elsewhere | zero |

Every entry comes from [J96] (control `ordinary`, `exact`, and `exact.contributions`). The ordinary column uses prediction values for $E_R$ and $\delta_u$, whereas the reliable source has received a coefficient correction; its ratio to the reliable result is a diagnostic comparison rather than a uniform quadrature safety factor. [R96] (“Interpretations to review,” item 9) [CODE] (`LOCAL_ordinary_d2`)

The source-moment allowance supplies $59.65\%$ of the control radius. Apart from it, the upper/ordinary ratios are only $1.04562$ for $\delta_u$ and $1.0000473$ for $E_R$, and unity at the recorded precision for $E_v$, $E_y$, and $D_0$. On the main grid, the corresponding ratios are $1.59542$ and $1.0011015$; the moment term supplies $91.76\%$ of $R_\mu$, and the reliable/ordinary $R_k$ ratio is $12.2493$. These numbers identify the moment enclosure as the large *evaluation* loss. [J96] (both levels)

## 1. Inequality chain and its order

1. **Original continuous problem and input $u$.** On $B=\mathbb R\times(-1/2,1/2)$ with quasiperiodicity $\beta=0.5$, the operator $A=-\rho^{-1}\Delta$ is nonnegative and selfadjoint in $\mathcal H=L^2(B,\rho)$, with $\rho\in\{1,4,17\}$. The finite DtN equation is nonlinear in $\mu$, but this underlying operator is linear. I9.6 takes the recovered finite element method (FEM) field in the center and retained lead cells and sets it to zero outside $D$; this defines $u\in L^2(B)\setminus\{0\}$. Selection and truncation can worsen the field, but this step applies no error inequality and promises no mesh order. [T96] (§1) [R96]

2. **Strong-domain reconstruction $w$.** Set $s=\mu_0>0$, $L_s=-\Delta+s$, $f=(\mu_0\rho+s)u$, and $w=L_s^{-1}f$. The inverse acts on the full quasiperiodic strip, mapping $L^2$ into $H^2_\beta\subset D(A)$. The exact identity
   $$\rho(A-\mu_0)w=(\mu_0\rho+s)(u-w)$$
   makes $u-w$ the relevant defect. No inequality is lost here. Smoothing repairs the strong-domain problem of the hard-truncated input, while its departures from the eigenfield remain in the defect. This identity is linear in that defect. [T96] (equations (3)–(7))

3. **Theorem 1, spectral measure.** For this nonzero $w\in D(A)$,
   $$\operatorname{dist}(\mu_0,\sigma(A))\le\frac{\|\rho^{-1/2}(\mu_0\rho+s)(u-w)\|_0}{\|w\|_{\mathcal H}}.$$
   This is first order in a strong residual, of Weinstein type. It can be very loose when small field components away from the target mode contribute strongly to the residual. It contains no Rayleigh centering or spectral separation that would make the off-mode contribution quadratic. [T96] (Theorem 1, first inequality in (8))

4. **Theorem 1, global material and norm comparison.** Replace the numerator multiplier by $C_\rho$ and $\|w\|_{\mathcal H}$ by $\|w\|_0$:
   $$\operatorname{dist}(\mu_0,\sigma(A))\le C_\rho\frac{\|u-w\|_0}{\|w\|_0}.$$
   These replacements can lose a finite material-dependent factor, discussed below. They preserve first-order dependence on the defect and do not change its mesh exponent. [T96] (second inequality in (8))

5. **Finite $w_d$, proxy $v_R$, and reconstruction allowance.** Project $f$ onto broken rectangular $Q_1$, approximate its moments by $\widetilde f_R$, retain transverse Fourier modes $|m|\le M$, and define $w_d=L_s^{-1}P_M\widetilde f_R$. Its longitudinal Yukawa convolutions and exterior exponential tails remain part of the field. Separately, $v_R$ is a compactly supported rectangular $Q_2$ proxy for $u$. The finite algorithm supplies
   $$\|w-w_d\|_0\le\varepsilon_0=c_RE_R+\min\{\delta_c/(s+\beta^2),\overline C_G\delta_1\}+E_y/b_M+\varepsilon_{\rm alg}.$$
   The source-projection factor $c_R=\sqrt{h_x^4+h_y^4}/\pi^2$ is second order in auxiliary rectangle width, multiplying $E_R$. The Fourier factor $b_M^{-1}$ is $O(M^{-2})$. Moment and algebraic errors enter linearly. These auxiliary smoothing orders do not make the final spectral inequality second order in the physical residual; $Q_2$ also gives no automatic cubic proxy rate across FEM element edges. [T96] (equations (12)–(18a), (19)–(25), §8.3)

6. **Theorem 2, triangle split.** Direct enclosures give $\|u-v_R\|_0\le\delta_u$ and $\|v_R-w_d\|_0\le E_v$. Hence
   $$\|u-w\|_0\le\delta_u+E_v+\varepsilon_0.$$
   Cancellation between the differences is discarded, so a large factor is possible. The dependence is first order in each norm. With exact auxiliary data the procedure converges to $\|u-w\|_0$ for the fixed input; refining auxiliary grids leaves that input unchanged. The recorded lower bound $\max\{0,E_v^- -\delta_u^+-\varepsilon_0^+\}$ is zero on both levels, so the current enclosures do not measure the actual triangle slack. [T96] (Theorem 2 and Proposition 4) [J96]

7. **Theorem 2, positive denominator.** Reverse triangle gives $\|w\|_0\ge D_0^- -\varepsilon_0^+>0$, and therefore
   $$R_\mu=\frac{C_\rho(\delta_u^++E_v^++\varepsilon_0^+)}{D_0^- -\varepsilon_0^+}.$$
   A nearly vanishing denominator would be dangerous. Here it is $0.999991925818$ on control and $0.999961284115$ on main, so this is negligible compared with the numerator losses. The division preserves residual order. [T96] (Theorem 2) [J96]

8. **Conversion to wavenumber.** Since $R_\mu<\mu_0$, use $R_k=R_\mu/(k_0+\sqrt{\mu_0-R_\mu})$. The actual reference difference satisfies $\Delta k=\Delta\mu/(k_0+k_B)$. The nearly equal divisors explain the negligible conversion factor in the table. Conversion preserves first- or second-order dependence. [T96] (equations (11a)) [J96] [REF]

“First order” here refers to dependence on a residual or field defect. Under the additional approximation assumptions stated in §8.3, native $P_2$ field error $O(h^3)$ and eigenvalue error $O(h^4)$ would yield an $O(h^3)$ reconstruction bound when auxiliary errors are controlled. That hypothetical mismatch would make the ratio grow under refinement. Those rates have not been established for this data family. [T96] (equations (30)–(31) and §8.3)

## 2. What is still hidden inside the factors?

**Material constant.** The pointwise coefficients $(\mu_0r+s)/\sqrt r$ are $4.85746$, $6.07182$, and $10.60296$ in materials $r=1,4,17$. Thus the numerator-only loss lies between unity and $2.18282$. The additional denominator replacement can lose up to $\sqrt{17}=4.12311$. Together, replacing the first inequality of Theorem 1 by the second can lose between unity and $9$; the actual value depends on where both $u-w$ and $w$ lie. The factor $2.18282$ in the table is consequently a benchmark, not an identified savings. A single material-resolved integration of the two norms in the first inequality of (8), on an accurately reconstructed field, would determine this loss. Merely changing the shift changes $w$ and all the other terms too. [J96] (`constants`) [T96] (equations (8)–(9))

**Auxiliary error and triangle slack.** Holding the reported finite quantities fixed and removing the moment allowance gives a control formula scale $R_k\simeq1.5669\times10^{-5}$; retaining only $E_v$ gives $1.0715\times10^{-5}$, or about $57.8\,\Delta k$. On main the analogous scales are $1.1764\times10^{-5}$ and $1.0699\times10^{-5}$. These are sensitivity calculations, because improving source moments can also change the reconstructed field. One accurate evaluation of the direct same-input norm $\|u-L_s^{-1}(\mu_0\rho+s)u\|_0$ would determine the combined proxy/reconstruction/triangle slack. [J96] [REF]

**Field defect versus eigenvalue error.** With the current global constant and normalization, a first-order radius comparable to $\Delta\mu$ would require a defect budget about $\Delta\mu/C_\rho=5.44896\times10^{-8}$, whereas $E_v$ is about $3.15\times10^{-6}$. After using the background-material coefficient benchmark instead, the corresponding budget is $\Delta\mu/(2\mu_0)=1.18941\times10^{-7}$, producing the remaining factor $26.48$. Neither comparison directly measures the distance to an eigenfunction. For an exact eigenfield $\phi$ with eigenvalue $\lambda$, the same reconstruction satisfies
$$\phi-L_s^{-1}(\mu_0\rho+s)\phi=-(\mu_0-\lambda)L_s^{-1}(\rho\phi).$$
Thus even a perfect eigenfield has a defect when evaluated at the displaced candidate. A normalized, phase-aligned comparison with a substantially more accurate continuous field, including its leads, would determine actual field error; the present scalar outputs lack that comparison. [J96] [REF] [T96] (equations (31))

There is also a useful perfect-field comparison with no homogeneous-material assumption. The eigen-equation gives $\rho\phi=-\Delta\phi/\lambda$, hence
$$L_s^{-1}(\rho\phi)=\lambda^{-1}(I-sL_s^{-1})\phi,\qquad \|I-sL_s^{-1}\|_{0\to0}\le1.$$
For a unit-norm exact eigenfield evaluated at $\mu_0$, the reconstruction defect is therefore at most $|\mu_0-\lambda|/\lambda$. Substituting the reference value gives $2.3788190\times10^{-7}$, about $13.24$ times smaller than control $E_v$. If $E_v$ accurately represents the true defect, displacement of the frequency alone is insufficient to explain it. The actual enclosure still allows a zero direct-defect lower bound, and the reconstruction can amplify field error, so this comparison does not establish a $13.24$-fold eigenfunction-error ratio. [T96] (equations (3)–(7), (31)) [J96] [REF]

**First order versus second order.** No independent measured factor is available. The decisive missing functional is the true-material Rayleigh quotient of I9.6's exact reconstructed $w$,
$$\theta=\frac{\int_B|\nabla w|^2}{\int_B\rho|w|^2}.$$
The same chain actually bounds $\|(A-\mu_0)w\|_{\mathcal H}/\|w\|_{\mathcal H}$ by $R_\mu$, not just the distance to spectrum. Hence $|\theta-\mu_0|\le R_\mu$, and its variance about $\theta$ is at most $R_\mu^2$. Under the additional one-sided separation $\sigma(A)\cap(\theta,\lambda_+)=\varnothing$, the strong-residual Temple inequality gives a correction at $\theta$ at most $R_\mu^2/(\lambda_+-\theta)$. This follows from the spectral-measure argument behind [T95] (Theorem C and Corollary C1); it requires $w\in D(A)$, already supplied by [T96] (§2).

Using the historical *assumed* $\lambda_+=2.1875^2=4.78515625$ and the safe substitution $\theta\le\mu_0+R_\mu$, the control correction is at most $6.2180\times10^{-9}$ in $\mu$, about $1.995\times10^{-9}$ in $k$. The main correction is $8.4096\times10^{-8}$ in $\mu$. At the original candidate, the control result would instead read
$$\operatorname{dist}(\mu_0,\sigma(A))\le|\mu_0-\theta|+6.2180\times10^{-9}.$$
If $\theta$ is close to the reference eigenvalue, the current reconstructed field is already adequate for a much sharper conditional bound. If $|\mu_0-\theta|$ is large, trial-field improvement remains necessary. Computing and enclosing this one Rayleigh quotient would distinguish those outcomes; validating the separation is a further, substantial task. A Rayleigh quotient below the target would require the corresponding lower-side separation or a two-sided enclosure. The existing $\varepsilon_0$ controls an $L^2$ error; enclosing $\theta$ additionally requires energy-norm or direct functional remainder control. Applying Temple directly to the finite $w_d$ would require its own residual evaluation. [J96] [T95] (Corollaries C1–C3) [T96] (equations (10), (16)–(18a)) [REF]

## 3. Trial-field quality: what the existing data say

The I9.5 Rayleigh shift belongs to a different input. Its fixed candidate is $k_h=1.5584630910866906$, $\mu_h=2.4288072062794823$, and its tail-field Rayleigh quotient is $\mu_R=2.4287910444662266$. Consequently $\mu_R-\mu_h=-1.61618132557\times10^{-5}$. The shift is indeed $27.97$ times I9.6's reference $\mu$ error, but this compares different candidates and different trial fields. For I9.5's own candidate, the reference error is $7.85363\times10^{-5}$ in $\mu$; its Rayleigh shift is only $20.58\%$ of that error, and its Rayleigh quotient remains $6.23744\times10^{-5}$ above the reference. This older result demonstrates that changing the continuous trial field changes its Rayleigh center substantially; it supplies no current value for $\theta$. [OLD] [CFG95] [J95] [REF]

I9.5 glues the native field at $x=\pm(c_g+1/2)$ to discrete Floquet tails and closes the outer wall at zero. The best quoted case has $c_g=1$ and $12$ appended cells per side. Cases $(c_g,\text{tail cells})=(3,10)$ and $(5,8)$ have the same outer-wall location but larger relative closure amplitudes: roughly $7\times10^{-5}$ and $5\times10^{-4}$, versus $10^{-5}$ for $(1,12)$. The multipliers have moduli at most about $0.377$ and $0.384$, and wall-trace matching is within $6\times10^{-16}$. Value matching and decay are good, while the piecewise $P_2$ field and its derivatives still enter the physical residual. [R95] (finite-tail construction and results)

I9.6 instead recovers the FEM+DtN field at its newer fixed candidate, retains $16$ cells per side, and uses a hard cutoff, for $33$ cells total and $\|u\|_0=1$. Its stored propagation-norm factors are $0.400553$ and $0.406689$. The discrete continuation's omitted squared masses are bounded by $3.48656\times10^{-15}$ and $6.20771\times10^{-15}$, giving a combined omitted norm $9.84595\times10^{-8}$. This diagnoses truncation of the discrete continuation, rather than its error against a continuous lead mode. Moreover, the crude reconstruction sensitivity from (30)–(31) amplifies that norm by at most $1+C_T=17.3201$, allowing a defect change as large as $1.7053\times10^{-6}$. Thus the small omitted mass alone does not resolve the tail's contribution to $E_v$. [J96] (`native.tails`) [CODE] (tail calculation) [T96] (equations (27), (30)–(31))

The more direct I9.6 observations are:

- $E_v$ changes by only $0.1483\%$, from $3.14972\times10^{-6}$ to $3.14505\times10^{-6}$, when the auxiliary grid doubles. On main, $\delta_u^+=8.25309\times10^{-8}$ is much smaller than $E_v$; a better $Q_2$ proxy alone has limited scope. [J96]
- On main, the Yukawa exterior tail contributes $0.1445\%$ of $E_v^2$, and the proxy's omitted Fourier modes contribute $0.1052\%$. Most of the measured defect is inside the source box and retained Fourier band. [J96] (`T_d_squared`, `T_v`, `E_v`)
- Summing the existing main mode records gives $30.793\%$ of the in-box defect squared in $|m|\le3$, and $33.367\%$ in the bands $\bigl||m|-48j\bigr|\le3$, $j=1,\ldots,5$. The first such band contributes $31.142\%$. This is consistent with a native-grid imprint, alongside a substantial low-mode component. [M96]
- The main cell records place $44.07\%$, $11.24\%$, and $44.70\%$ of the in-box defect squared in the left lead, center, and right lead; cells beyond index $8$ contribute only $0.0160\%$. These locate the finite defect, without separating geometric, FEM, and source-evaluation effects. [C96]

The hypothesis is therefore plausible in its residual sense: auxiliary refinement leaves a persistent defect associated with the fixed recovered field. A discrete $P_2$ field, approximate interface geometry/material integration, and lead recovery can affect that field more strongly than the scalar eigenvalue; an eigenvalue can benefit from variational cancellation that a norm of the field defect discards. The current records still permit a large first-order spectral overestimate for a field whose *Rayleigh quotient* is already accurate. The missing $\theta$ prevents deciding whether field improvement is necessary for a sharp second-order bound. [T96] (§8.3) [R96] (D1 results and caveats)

## 4. Why I9.5's Temple radius stayed large

I9.5 already gained substantially from second order. For its best baseline, $\overline\eta_R=0.00792873185186$, $U=0.999964937244$, and $\tau=\overline\eta_R/U=0.00792900986480$, so $\tau^2=6.28692\times10^{-5}$. With $s=1.21440360314$ and assumed $\lambda_+=4.78515625$, the gap above the Rayleigh quotient is $\lambda_+-\mu_R=2.35636520553$ and $(\lambda_++s)/(\lambda_+-\mu_R)=2.54610781005$. Substituting into Corollary C1,
$$
x_T=\frac{(\lambda_++s)\tau^2}{(\lambda_+-\mu_R)+(\lambda_++s)\tau^2/(\mu_R+s)}
=1.60064721809\times10^{-4}.
$$
The extra denominator term is tiny; the input $\tau^2$, rather than a small spectral-gap denominator, keeps this radius large. [J95] [T95] (equations (11))

The flux majorant is dominated by its body term $0.0079257543$ and gradient difference $\|\nabla u-p\|=0.0078840323$; the end contribution is only $2.98\times10^{-6}$. Optimizing the flux by the recorded three majorization-minimization steps lowers $\eta$ to $0.0079085870$, while the gradient difference stays near $0.0078834815$. The Temple correction consequently improves only to $1.5925\times10^{-4}$. An improved tail termination or another small flux optimization cannot remove that measured body scale. The flux majorant also has its own slack, so its gradient difference is not an exact eigenfunction-error measurement. [R95] (attempt-2 results)

Transferring the baseline interval back to its fixed candidate adds $|\mu_h-\mu_R|=1.61618\times10^{-5}$, giving $R_{\rm cond}=1.76226535064\times10^{-4}$. Compared with its own first-order radius $0.0151938341$, that is already an improvement by $86.22$ times. It nevertheless exceeds I9.6's control radius because the two methods use different fields and different residual evaluations. At the same assumed gap, making $x_T$ comparable to the newer reference error $5.77751\times10^{-7}$ would require $\tau\simeq4.76356\times10^{-4}$, about $16.65$ times smaller, as well as a sufficiently accurate Rayleigh center. [J95] [J96] [REF]

The later I9.5 joint-refinement experiment supports the importance of its input: $\eta$ falls to $0.00242288$, the gradient difference to $0.00241511$, and conditional $x_T$ to about $1.4948\times10^{-5}$. The roughly squared improvement follows the residual reduction. It changed the candidate, mesh, geometry, and field together, so it gives a direction for improvement rather than a clean allocation to one cause. [R95] (attempt-3 results)

## 5. Ranked losses and concrete changes

1. **First-order use of the persistent field defect: largest unresolved source.** The $E_v$ term alone corresponds to about $57.8$ reference errors with the current global weights, or $26.5$ under the stated background-coefficient benchmark. First compute a reliable Rayleigh quotient of the existing I9.6 reconstructed $w$. If its shift from $\mu_0$ is close to $\Delta\mu$, use a second-order enclosure with certified separation; the present control residual would allow a correction around $6.2\times10^{-9}$ in $\mu$ under the stated upper-gap assumption, potentially reducing the current reference ratio close to unity. The cost is accurate material-weighted functionals of the Fourier/Yukawa field and a certified exclusion interval for the periodic-lead problem; the latter may dominate. If the Rayleigh shift is large, improve the native field and its lead continuation first, for example with higher-order FEM and controlled interface geometry. A first-order route would need roughly a $58$-fold reduction in the present $E_v$ scale with the current constant; its cost includes higher-order lead elimination and a higher-order field adapter. These gains are alternatives to test, not factors to multiply together. [J96] [REF] [T95] (C1–C3) [T96] (§8.3)

2. **Moment enclosures: largest directly identified evaluation loss.** Tighten the true-material source moments using more selective subdivision, smaller retained batches, or sharper treatment of curved-interface strips. Holding the other terms fixed, eliminating this allowance reduces the control radius by about $2.48$ times, and the main radius by about $12.14$ times in the numerator. Current engine stops are `PIECE_LIMIT`; both levels retain most of their time allowance. Cost is additional certified geometric integration, with careful control of retained intermediate data. The existing complete run took $302.6$ s, including $121.5$ s in the engine, which gives a cost baseline rather than a forecast for a tighter evaluation. [J96] [R96] (D2 results and costs)

3. **Global material/norm comparisons: potentially substantial, presently unmeasured.** Evaluate the first inequality of Theorem 1 using material-resolved residual energy and weighted field mass. The numerator-only potential gain is at most $2.18$; including weighted normalization, the algebraic range extends to $9$. Its actual rank relative to the moment loss remains unknown. Cost is reliable integration of the reconstructed field over the curved material regions and its exterior tails; the current unweighted Fourier norm shortcut deliberately avoids this work. [T96] (equations (8)–(9), §6) [J96]

4. **Other auxiliary allowances: smaller, measured scope.** Refine the rectangular source projection and Fourier cutoff together, while controlling their moments. Removing these terms after the moment allowance gives another factor $1.46$ on control, but only $1.10$ on main. Current $E_v$ changes little, so auxiliary refinement alone has limited remaining gain. It costs more source/Fourier coefficients and norm evaluation, with no new native eigenproblem. [J96]

The finite denominator and conversion to $k$ are negligible losses at this candidate. The main outstanding decision is whether the Rayleigh center of I9.6's *already reconstructed* field is accurate enough for second order. I9.5's older Rayleigh shift cannot answer that same-field question. [J96] [J95]

This pass reviewed the stated inequalities and performed arithmetic on retained records only. The theory and experiment files were unchanged. No experiment or external literature retrieval was needed. The uncomputed quantities are the same-field Rayleigh center, the direct/material-weighted defect norms, the actual continuous field error, and certified spectral separation.

[T96]: /Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound.md
[T95]: /Users/whc/Documents/Work/dot-research/research/projects/eig-apost/phase3-analysis/fem-bound/s-eq-temple.md
[R96]: /Users/whc/Documents/Work/dot-research/test/i9/dtn-bound-v1/README.md
[R95]: /Users/whc/Documents/Work/dot-research/test/i9/eq-temple-v1/README.md
[CODE]: /Users/whc/Documents/Work/dot-research/test/i9/dtn-bound-v1/dtn_bound_i96.m
[CFG95]: /Users/whc/Documents/Work/dot-research/test/i9/eq-temple-v1/eq_mm_d1_config.m
[OLD]: /Users/whc/Documents/Work/dot-research/test/i9/compare-v1/README.md
[REF]: /Users/whc/Documents/Work/dot-research/test/i10/refine-v1/README.md
[J96]: /Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03/result.json
[M96]: /Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03/modes.csv
[C96]: /Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03/cells.csv
[J95]: /Users/whc/Documents/Work/epost/test/i9/eq-temple-v1/output/attempt-2/run-01/result.json
