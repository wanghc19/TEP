# Switch-line and Kress proof review

Result: **0 blockers, 1 important caveat, 2 minor caveats.** Proposition S needs the boundary-flux identification in S-1 and the corrections in S-2–S-3. Its proposed absolute switch-residual bound is valid with that repair. T3.2, T3.4a, T3.1 and T3.3 are correct under their stated hypotheses. Both priority groups were completed; no items remain TODO.

Scope: Review only of switch-line.md and the requested steps of reliable-bound.md, using the previous reliable-bound-review.md, +kernel/qpgreen_mfs_pairmat.m, +kernel/precomp_proxy.m, +geom/construct_cont.m, the configuration, geometry and relevant field-evaluation functions in test/bie-bound/budget-v1/, and the local Trefethen2014.pdf and Dahne2020.pdf; MFS means method of fundamental solutions, and BIE means boundary integral equation. Floating-point rounding, performance and the size of the switch residual were excluded.

## Step-by-step verdicts

Line numbers below refer to switch-line.md for S and reliable-bound.md for T.

| Item | Verdict | One-line check |
|---|---|---|
| S §1: coordinate swap and wrapped kernel, lines 7–14 | correct | Physical $y$ is the first computational coordinate; the phase and the three longitudinal branches match the code. |
| S §1: branchwise Helmholtz equation, line 18 | correct | The primary source is the only singularity inside the computational box; all proxies lie outside it. |
| S §1: exact seam assertion, line 19 | S-3 | Quasi-periodicity holds away from the switches, but the pointwise and single-source seam assertions need the stated qualification. |
| S §1: switch location and $j_0,j_1$, lines 20–27 | correct | The upper branch has index $m+1$, giving the displayed jumps times $e^{i\beta(m+1)d}$. |
| S §1: unwrapped proxy separation, line 29 | correct | For the configured star, the source at angle $-2\pi/5$ plus the proxy $(X,Y)=(0.7,0)$ lies inside the background of the core cell. |
| S: meaning of source and target derivatives, lines 36, 42–43 | S-1 | The code supplies one-sided branch derivatives; these must also define the flux used in the sourcewise Green identity. |
| S: single-layer jumps, lines 42–43 | correct | The contributions are $-\sigma[\widetilde G]$ and $-\sigma[\partial_y\widetilde G]$. |
| S: double-layer jumps, lines 42–43 | correct | With branch derivatives, $[\partial_{\nu_s}\widetilde G]=-\alpha(\nu_{s,y}j_1+\nu_{s,x}j_0')$, where $\alpha=e^{i\beta(m+1)d}$ and primes differentiate $Y$. |
| S: double-layer normal-flux jump, line 43 | correct | Differentiating on each branch gives $-\alpha(\nu_{s,y}j_2+\nu_{s,x}j_1')$, with $j_2=-j_0''-\kappa^2j_0$. |
| S: Fubini for the switch pairing, lines 49–55 | correct | The switch is separated from its own source and proxies; bounded densities and the uniform line trace bound give absolute integrability in source and target. |
| S: Fubini near the physical source diagonal, line 52 | correct | Subtract the ordinary free-space layer first; its standard boundary limits are retained, while the switching remainder is uniformly regular near that diagonal. |
| S: endpoints and corners of fixed-source pieces | correct | Piecewise Green's formula has only edge integrals; no tangential integration by parts produces endpoint terms, and exceptional tangency heights have source measure zero. |
| S: inherited physical-boundary residual, lines 52, 69 | S-1 | Integrating branch derivatives is not generally the same as differentiating the integrated field. |
| S: sign of the additional Green term, line 55 | S-2 | With both jumps defined as upper minus lower, the additive term has the opposite sign. |
| S: flat collars crossing materials, line 58 | correct | The auxiliary field is globally $H^2$; horizontal collars of disjoint segments have multiplicity one, including after quasi-periodic continuation when $2\delta<d$. |
| S: flat constants from T4.2–T4.3 | correct | $D_0=(1+\eta)/(2\delta)$ and $D_1=(1+\eta^{-1})\delta/6$ apply with curvature zero and $N=1$. |
| S: stated value $C_{\rm line}=1.0356$ | correct | For the report's $\ell=1$, $\mu=\widehat k^2$, $\rho_{\min}=1$, $\rho_{\max}=17$, $\delta=1/5$, the explicit choice $\eta=7/6$ makes this an upper bound. |
| S: weighted Cauchy–Schwarz, line 61 | correct | Pair $(\mathcal J_1,\ell^{-1}\mathcal J_0)$ with $(z,-\ell\partial_yz)$ and apply the flat trace bound. |
| S: source integration and sum over pieces, lines 64–69 | correct | The triangle inequality gives exactly $C_{\rm line}\sum_P\int_\Gamma e_s\,ds$; S-1 identifies the boundary functional to which it is added. |
| S: lead cells, line 72 | correct | For each reference source, translated segments are collinear with disjoint longitudinal interiors; their squared norms sum and their finite-dimensional state maps admit the T3.8 tail estimate. |
| S: possible plane-wave switches, line 79 | correct | In the named configuration, same-cell targets have $\lvert t_x\rvert\le0.5$ and sources have $\lvert s_x\rvert\le0.36$, so $\lvert Y\rvert\le0.86< H=1.1$. |
| T3.2: combined Müller kernel and splitting, lines 522–527 | correct | The hypersingular difference is formed before interpreting the remaining logarithmic kernel as an ordinary integral. |
| T3.2: analytic source-strip hypotheses, lines 529–536 | correct | Periodicity, holomorphy and uniform bounds are imposed on the density-weighted split factors, with arc length included. |
| T3.2: Fourier coefficients of log-sine, line 548 | correct | $L$ has mean zero and coefficients $-1/\lvert m\rvert$ for nonzero integer $m$. |
| T3.2: retained modes and Nyquist convention, line 548 | correct | Modes of magnitude below $n$ are exact; every remaining mode aliases to frequencies of magnitude at most $n$, with total absolute coefficient at most one. |
| T3.2: error for a single mode, line 548 | correct | The exact and interpolated convolution multipliers each have magnitude at most one, so their difference is at most two. |
| T3.2: logarithmic tail constant, lines 550–552 | correct | Twice the two-sided Fourier tail is $4H e^{-2\pi an}/(1-e^{-2\pi a})$. |
| T3.2: smooth-part error, lines 543, 553 | correct | The nonzero multiples of $N$ give $2G/(e^{2\pi aN}-1)$. |
| T3.2: complex-target definition (Q2d), lines 564–578 | correct | Joint holomorphy and uniform coefficient decay give the analytic continuation by an absolutely locally uniformly convergent Fourier series. |
| T3.2: complex aliasing factor, lines 579–585 | correct | Both original and aliased frequencies are bounded by the original mode magnitude, giving $2e^{2\pi b\lvert m\rvert}$ per omitted mode. |
| T3.2: constants in (Q2c) | correct | Only the logarithmic tail loses strip width from $a$ to $a-b$; the source trapezoid term retains $a$. |
| T3.2: $F_\kappa,E_\kappa$ and (Q3), lines 588–602 | correct | The $Y_0$ logarithmic term gives $-F_\kappa\log q/(4\pi)$; the harmonic-number series has the displayed $(-1)^j/(2\pi)$ sign and coefficient. |
| T3.2: single-layer $A,B$, lines 604–609 | correct | Factoring $q=4\sin^2\pi(t-s)H$ gives the displayed split on the compatible logarithm branch certified in T3.0. |
| T3.2: normal derivatives, lines 611–614 | correct | Holding the two normals fixed gives $q_x=2(x-y)\cdot\nu_x$, $q_y=-2(x-y)\cdot\nu_y$, and $q_{xy}=-2\nu_x\cdot\nu_y$. |
| T3.2: two-wave-number cancellation, line 616 | correct | $F_{\kappa_e}-F_{\kappa_c}=O(q)$ cancels the wave-number-independent $1/q$ hypersingular part; $q_x,q_y=O((t-s)^2)$ remove the other nonlogarithmic quotients. |
| T3.2: analytic correction terms, line 616 | correct | This assertion uses T2.1/T3.0 source separation and analytic branches; it does not include an unsegmented source-dependent wrapping switch. |
| T3.2: entire-series remainder, lines 618–620 | correct | Beyond the first omitted term, the positive-term ratio is at most $x/(p+2)^2<1$. |
| T3.2: harmonic-number remainder and density factor, lines 622–623 | correct | $H_{j+1}/H_j=1+1/((j+1)H_j)$ decreases with $j$, and multiplication by the density envelope gives $M_A D_0(a),M_B D_0(a)$. |
| T3.4a: fixed finite sum and separate quadrature error, lines 685–705 | correct | The theorem concerns a finite monopole/dipole sum with source weights already included. |
| T3.4a: source complexification, lines 745–750 | correct | $\lvert tv_j\rvert\le R/3$ gives $\lvert q_j-R^2\rvert\le7R^2/9$ and $\operatorname{Re}q_j\ge2R^2/9$. |
| T3.4a: analyticity of the kernel branch, line 752 | correct | The entire $q$ disk lies strictly in the right half-plane, away from the square-root and Hankel cuts and the origin. |
| T3.4a: value and first-derivative envelopes, lines 718–719, 754–759 | correct | $\|r_j\|_2\le4R/3$ gives $M_0=A_0$ and $M_1=(8R/3)A_1$. |
| T3.4a: mixed derivative and $M_2$, lines 720, 761–765 | correct | The two terms have norms at most $4A_2(4R/3)^2$ and $2A_1$, respectively. |
| T3.4a: vector Cauchy remainder, lines 767–770 | correct | The contour integral bounds the vector coefficient by $Ms^{-n}$, giving exactly $\zeta_p=s^{-p-1}/(1-s^{-1})$. |
| T3.4a: value estimate (F3), lines 732–735 | correct | Applying the scalar remainder to each monopole and dipole and summing absolute source strengths gives (F3). |
| T3.4a: gradient estimate (F4), lines 738–772 | correct | Apply the vector remainder to the gradient and mixed derivative; target differentiation commutes with each finite Taylor polynomial. |
| T3.4a: complex dipoles and normal projections, line 743 | correct | Bilinear dot products satisfy the Euclidean norm inequality, and a real unit normal cannot increase the gradient error. |
| T3.4a: zero-radius cluster, line 774 | correct | All offsets vanish, so degree zero reproduces both the monopole and the fixed-direction dipole sum. |
| T3.4a: enclosure of the $q$ disk, line 778 | correct | Its enclosing rectangle has real part at least $2R^2/9$, so the same analytic branches apply throughout. |
| T3.4a: derivative identities (F6), lines 780–785 | correct | $H_0'=-H_1$ gives the first identity, and $4q\mathcal G''+4\mathcal G'+\kappa^2\mathcal G=0$ gives the second. |
| T3.4a: $A_2$ from $A_0,A_1$, lines 788–790 | correct | $\lvert q\rvert\ge q_{\min}=2R^2/9$ yields the stated quotient bound. |
| T3.4a: common target-box envelope, lines 794–798 | correct | $s=R_{\min}/(3a)$ works for every target, the union covers its $q$ disk, and $R_{\max}$ safely enlarges $M_1,M_2$. |
| T3.4a: alternative radius, lines 800–808 | correct | $b=sa<(\sqrt2-1)R$ is exactly the condition $2Rb+b^2<R^2$; the displayed derivative constants follow from $\|r\|\le R+b$. |
| T3.4a: Cartesian moments (F7), lines 812–824 | correct | The multinomial expansion gives the $v^\alpha/\alpha!$ normalization and the dipole derivative of order $\alpha+e_r$. |
| T3.4a: parent translation (F8), lines 828–835 | correct | Expanding $(d+v)^\alpha/\alpha!$ gives the displayed factorials and requires only child moments of degree at most $\lvert\alpha\rvert$. |
| T3.4a: tree error accumulation, line 837 | correct | Accepted clusters and directly evaluated leaves partition the source set for each target, so their absolute errors add once. |
| T3.4a: complex targets and other FMM algorithms, lines 837–841 | correct | The statement explicitly requires a separate complex-target or higher-derivative certificate and does not claim to cover extra expansion translations. |
| T3.1: period and analytic-strip data, lines 446–470, 486–490 | correct | T3.0 fixes period one and the positive arc-length branch; the theorem additionally requires bounds on the actual residuals throughout the strip. |
| T3.1: reflection-conjugation, lines 492–495 | correct | $f^\sharp(z)=\overline{f(\bar z)}$ is holomorphic on the symmetric strip and has the same uniform bound. |
| T3.1: integrand bound, lines 494–495 | correct | The real-axis integrand is the desired squared residual times arc length, and its complex extension is bounded by $M_F$. |
| T3.1: coefficient decay, line 514 | correct | Contour shifts within the open strip, followed by a limit to its width, give $M_F e^{-2\pi a\lvert m\rvert}$. |
| T3.1: aliasing sum and rescaling, lines 509, 514–516 | correct | Summing both tails at frequencies $rN$ gives $2M_F/(e^{2\pi aN}-1)$, exactly the period-one rescaling of the cited theorem. |
| T3.1: node-error contribution, lines 497–509 | correct | The Euclidean triangle inequality followed by the nonnegative upper arc-length weight gives the displayed node bound. |
| T3.3: analytic panel and coefficient errors, lines 631–642 | correct | The vector Cauchy bound gives the stated geometric Taylor tail, while coefficient errors contribute $\sum_j\eta_jh^j$. |
| T3.3: passage to $L^2$, lines 648–661 | correct | A uniform error $e$ on a panel of length $2h$ has $L^2$ norm at most $\sqrt{2h}\,e$. |
| T3.3: upper and lower squared bounds, lines 649–651 | correct | The forward and reverse triangle inequalities give both bounds, with the lower norm clipped at zero before squaring. |
| T3.3: polynomial integral, lines 654–658 | correct | Integrating each monomial product gives the parity factor and denominator $j+k+1$. |
| T3.3: real derivative remainder, line 663 | correct | Taylor's integral remainder gives $D_{p+1}h^{p+1}/(p+1)!$ in vector norm. |
| T3.3: Kress-to-coefficient certificate, line 665 | correct | A holomorphic error bounded by $E_K$ on the complex target disk has coefficient error at most $E_K/R_0^j$. |

The analytic-strip and disk hypotheses in the last two groups are substantive conditions on the function being integrated. For the wrapped kernel, a source parameter at which $t_y-s_y=\pm d/2$ is an additional branch boundary even when source and target are well separated. Q2 cannot be applied across a nonzero jump at that boundary. Likewise, absence of a physical source point alone does not certify a Taylor disk for the source-integrated wrapped field. Apply the stated theorems on domains with certified analytic branches, or separately enclose the integrals across switches. This is an application restriction of the correct conditional theorems, not a change to their constants.

## S-1 — Identify the boundary flux in the sourcewise extension

**Form:** 3 — Missing hypothesis/identification. **Class:** important caveat.

**Quoted text:** switch-line.md, line 52:

> “在 T2.3 的假设下，把 T2.3 证明中的残差恒等式按源 $s$ 分解”

and line 69:

> “$Q=Q_{\rm grp}+C_{\rm line}\sum_P\int_\Gamma e_s\,ds$.”

The inherited T2.3 uses derivatives of the integrated field, requires that field to be piecewise $H^2$ and Helmholtz (reliable-bound.md, line 332), and defines its residuals using those traces. A continuous superposition of moving switches does not in general have those properties. In particular, its normal derivative is not automatically the source integral of the branch derivatives returned by the kernel.

**Argument.** Write $F_s(t)$ for the integrand in switch-line.md, line 36, and $\nabla^{\rm br}$ for differentiation on the selected smooth branch. Away from the ordinary physical source singularities, differentiation in distributions gives

$$
\partial_y\int_\Gamma F_s(t)\,ds
=\int_\Gamma\partial_y^{\rm br}F_s(t)\,ds
 +\int_\Gamma \mathcal J_0(t;s)\,
       \delta\bigl(t_y-h(s)\bigr)\,ds,
$$

where $h(s)$ is the switch height in the selected cell. At regular heights the last term is a sum over sources at that height, divided by the magnitude of the derivative of source height with respect to arc length. It need not vanish. Consequently, on a boundary with a nonzero $y$ component of its normal, the two flux definitions can differ. At critical source heights the superposed field need not even be $H^1$; integration of a nonzero jump near a nondegenerate height extremum can produce a square-root cusp.

The local model $F_a(y)=\mathbf1_{y>a}\cos(\kappa(y-a))$, $0<a<1$, exhibits the derivative discrepancy without any source singularity. Each branch solves Helmholtz, and on $0<y<1$,

$$
u(y)=\int_0^1 F_a(y)\,da=\frac{\sin(\kappa y)}{\kappa},
\qquad
u'(y)=\cos(\kappa y),\qquad
\int_0^1\partial_y^{\rm br}F_a(y)\,da=\cos(\kappa y)-1.
$$

Here $\mathcal J_0=1$, $\mathcal J_1=0$. The switch pairing supplies exactly the boundary difference between the last two fluxes. Adding it to a Green formula that already uses $u'$ counts that difference again. Thus the sourcewise proof does not establish the displayed formula with an unchanged, actual-normal-trace interpretation of $Q_{\rm grp}$.

**Smallest repair.** State Proposition S as a weak Green identity for the defined $L^2$ field. Define the boundary flux to be the source integral of the branchwise kernel derivative, with the usual one-sided limits for the ordinary free-space layer. Form $Q_{\rm grp}^{\rm br}$ from these boundary fluxes and the field values. This matches the derivative convention in qpgreen_mfs_pairmat.m, lines 116–121, and the value/normal matrices in budget_run.m, lines 593–613.

For a smooth compactly supported test field, sourcewise Green's formula then gives, with the jumps printed in the proposal,

$$
(\widehat u,(A-\mu)z)_{\mathcal H}
=R_{\partial}^{\rm br}(z)-\sum_P R_{{\rm sw},P}(z).
$$

To justify the source exchange, first separate off the ordinary singular free-space layer. The remaining branch functions and their relevant derivatives are uniformly bounded on compact source/target sets: the switches are a distance $d/2$ from their own source, and the proxies have positive separation. Integrating their piecewise Green identities is legitimate. Fixed-source corner intersections have zero edge measure and add no term. The usual longitudinal cutoff and the stated summable lead-state bounds extend this identity to the resolvent test field.

The two already checked functional bounds now give

$$
Q=Q_{\rm grp}^{\rm br}
 +C_{\rm line}\sum_P\int_\Gamma e_s\,ds.
$$

The same resolvent algebra as T2.3 applies without imposing piecewise Helmholtz or $H^2$ regularity on the superposed wrapped field. If actual normal traces are retained instead, explicitly include the boundary correction from the displayed distributional derivative, or establish its cancellation. No extra endpoint term is needed for the branchwise-flux formulation.

## S-2 — Reverse the sign of the additive switch term

**Form:** 1 — Failed step. **Class:** minor caveat; the absolute bound is unchanged.

**Quoted text:** switch-line.md, lines 46, 55 and 58 define both jumps as “上侧减下侧” and use

$$
R_{\rm sw}(z)=\int_\Gamma\int_{\Lambda_s^P}
(\mathcal J_1\bar z-\mathcal J_0\overline{\partial_yz}),
$$

as the additional term, “总符号按 T2.3 的约定”.

**Argument.** T2.3 uses the outward Green pairing $(\partial_nF)\bar z-F\overline{\partial_nz}$. The lower piece has outward normal $+e_y$ on the switch and the upper piece has outward normal $-e_y$. Their sum is

$$
(\partial_yF_{\rm lower}-\partial_yF_{\rm upper})\bar z
 +(F_{\rm upper}-F_{\rm lower})\overline{\partial_yz}
=-\mathcal J_1\bar z+\mathcal J_0\overline{\partial_yz}.
$$

**Repair.** Either negate the definition on line 55 or retain that definition and subtract $R_{\rm sw}$ in the Green identity, as in S-1. The formulas for $e_s$ and the upper bound for $Q$ remain unchanged.

## S-3 — Qualify exact quasi-periodicity at a switch on the seam

**Form:** 1 — Failed step. **Class:** minor caveat for the continuous-source bound.

**Quoted text:** switch-line.md, line 19:

> “$\widetilde G_\kappa(\cdot,s)$ 精确满足 $\beta$ 准周期。所以胞元顶底接缝上的跳跃 $J_{\Sigma,0},J_{\Sigma,1}$ 恒为零（budget-v1 测到的只是舍入）。”

**Argument.** Away from half-integers, the wrapping index satisfies $m(X+d)=m(X)+1$, and the asserted phase relation follows. At the two ties $X=-d/2$ and $X=d/2$, however, MATLAB's round-away-from-zero convention gives $m=-1$ and $m=1$. Writing $q_\beta=e^{i\beta d}$,

$$
\widetilde G(d/2,Y)-q_\beta\widetilde G(-d/2,Y)
=q_\beta K(-d/2,Y)-K(d/2,Y)=q_\beta j_0(Y).
$$

The returned first derivative has the analogous defect $q_\beta j_1(Y)$. Moreover, even a consistent half-open value convention cannot make the *opposite one-sided seam traces* agree for a single source whose switch is the seam: their difference is $-q_\beta j_0$. A nonzero fit residual is enough to invalidate the literal per-source assertion.

For an analytic closed source curve, sources at height zero form an arc-length null set. Thus this exception does not introduce a seam residual into the continuous source integral with the stated smooth densities. It does affect the assertion about pointwise kernel values and about a finite quadrature diagnostic: a source node on the tie can contribute a fit-residual term even in exact arithmetic.

**Repair.** State quasi-periodicity away from the switch, and zero seam residual for the continuous-source field after source integration. Use a consistent half-open wrapping convention if pointwise translation covariance is needed, and include source-quadrature/tie contributions in interpreting a finite seam diagnostic instead of attributing all of it to rounding.

## Source and verification record

Review literature verification completed. Trefethen–Weideman, *The Exponentially Convergent Trapezoidal Rule*, SIAM Review 56(3), 385–458 (2014), Theorem 3.2 and (3.16), printed p. 396/PDF p. 12, were checked in the local PDF: a $2\pi$-periodic holomorphic function bounded by $M$ in the symmetric strip has error at most $4\pi M/(e^{aN}-1)$. Substituting $\theta=2\pi t$, using strip width $2\pi a$ and dividing the integral by $2\pi$ gives Q1. [Author copy](https://people.maths.ox.ac.uk/trefethen/publication/PDF/2014_149.pdf).

Dahne–Salvy, *Computation of Tight Enclosures for Laplacian Eigenvalues*, arXiv:2003.08095v2, §§2.1–2.2, printed/PDF pp. 6–7, was checked for the limited attribution about combining Taylor expansions before enclosure and using an interior subdomain for a norm lower bound. Q4 was verified from its own proof. [Preprint](https://arxiv.org/abs/2003.08095). The Kress Fourier, Hankel-series, derivative and moment identities were checked directly; no uninspected external theorem is needed for those steps.

For the stated flat-line number, an exact-rational Python check through the requested Conda environment verified the following sufficient certificate. Set $c_*=1.0356^2$, use $\eta=7/6$ and the displayed decimal $\widehat k$ as an exact rational, and form

$$
c_*(\lambda+\mu)^2-
\left[D_0+(D_1+D_0)\lambda+17D_1\lambda^2\right].
$$

Its leading coefficient is positive and its discriminant is negative, so it is positive for every real $\lambda$. This establishes the claimed upper bound without relying on the approximate optimizer. Short scalar diagnostic calculations were also used to inspect the geometric proxy witness; no experiment or MATLAB run was performed.

The reviewed proof and code files were not modified. Only this review file was written.
