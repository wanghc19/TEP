# Review of the reliable BIE spectral-distance bound

Scope and files inspected: Review only of the requested results in `reliable-bound.md` (BIE means boundary integral equation), using `draft/tmp/bie-theory-rewrite/s-error.tex` and `s-modelproblem.tex` for the supplied draft statements and conventions, and the local PDFs `Fliss2013.pdf`, `Trefethen2014.pdf`, and `Dahne2020.pdf` for the cited passages; the draft spectral-distance theorem and Proposition 5.1 were accepted as premises, and floating-point rounding and performance were excluded.

Result: **0 blockers, 1 important caveat, 0 minor caveats.** Both priority groups were completed. R-1 concerns the domain of the square roots in the grid-to-band recipe (T1.7); it does not invalidate the band-gap criterion (T1.5), the Lipschitz estimate (T1.6), or the spectral-distance argument.

| Item | Verdict | Check |
|---|---|---|
| T1.1: operator domain | correct | Bounded positive mass coefficients and the cylindrical Fourier estimate give the common domain $H^2_\beta(B)$. |
| T1.1: two-lead essential spectrum | correct | The localized right parametrix gives Fredholmness off both lead spectra, and the translated Bloch cutoffs give the reverse inclusion. |
| T1.2 | correct | Removing the essential spectrum leaves isolated finite-multiplicity eigenvalues, with only finitely many in each compact subinterval of the gap. |
| T1.3: exponential decay | correct | The bounded cutoff weights give a uniform inverse and $H^2$ estimate, and the limiting weight yields the stated tail decay. |
| T1.3: explicit sufficient condition | correct | The derivative-resolvent bound gives (T1.3), and solving its quadratic inequality gives exactly (T1.4). |
| T1.4: common-gap certificate (T1.5) | correct | The maximum lower-band upper bound and minimum upper-band lower bound exclude essential spectrum throughout the closed candidate interval. |
| T1.4: Lipschitz bound (T1.6) | correct | The triangle inequality on the fixed gauge-transformed form domain passes through the ordered min-max principle with constant $\rho_{\min,s}^{-1/2}$. |
| T1.4: grid-to-band formula (T1.7) | R-1 | Certified lower eigenvalue bounds must be clipped at zero before taking their square roots. |
| Reading of Fliss Remark 2.1(2) | correct | The local preprint explicitly permits different longitudinal periods and requires the same transverse period; its displayed Proposition 3.1 retains one background. |
| T2.1 | correct | The frozen finite corrections define Helmholtz solutions on the stated pieces when source separation and exact dispersion are imposed. |
| T2.2: boundary $H^2$ regularity | correct | Subtracting the constructed jump lift cancels both interface distributions, after which the local elliptic bootstrap applies. |
| T2.2: proxy sources and artificial corners | correct | Positive separation from the closed piece gives smooth extensions near its artificial boundaries and corners. |
| T2.2: global square integrability | correct | Finite-dimensional reference-cell boundedness and a contracting matrix power give the asserted summable cell norms. |
| T2.3: seam signs and phase | correct | Substituting $z_+=qz_-$ gives $(u_{y,+}-qu_{y,-})\overline z_+ +(qu_- -u_+)\overline{z_{y,+}}$. |
| T2.3: auxiliary resolvent field | correct | For $\mu\notin\sigma(A)$ the resolvent maps every $\widehat u\in L^2(B,\rho)$ into $D(A)$, without any boundary or domain condition on its input. |
| T2.3: spectral-distance estimate | correct | The additional seam pairing and the unchanged cutoff argument give $U^2\le Q(1+2\mu/\operatorname{dist}(\mu,\sigma(A)))U$. |
| Seam collars and covering multiplicity | correct | Quasi-periodic extension gives one flat seam collar; grouped estimates require only the multiplicity within each group. |
| T4.1 | correct | The energy minimizer has energy $2a\tanh(a\delta)$, giving the stated optimal point-trace constant. |
| T4.2: weighted one-dimensional identity | correct | Pairing the two half-interval integrands gives the displayed $T_\kappa$ identity and its upper bound $\tau$. |
| T4.2: $D_0,D_1$ and normal traces | correct | Weighted Cauchy–Schwarz, Young's inequality and the actual collar Jacobian give the constants with exactly one factor of the covering multiplicity. |
| T4.3: polynomial trace bound | correct | The mass, energy and Hessian estimates give $a=D_0/\rho_{\min}$, $b=D_1+\ell_*^2D_0$ and $c=\ell_*^2D_1\rho_{\max}$. |
| T4.3: spectral bottom | correct | Transverse Fourier–Poincaré gives $A\ge b_\beta^2/\rho_{\max}$, hence $\lambda_0=0.25/17=1/68$ for the supplied parameters. |
| T4.3: joint multiplier and its supremum | correct | The selfadjoint spectral calculus applies on $\sigma(A)\subset[\lambda_0,\infty)$, and the endpoint, limiting value and stated stationary point suffice. |
| T3.6: disk mass bound | correct | The regular circular mean is $J_0(\kappa_b r)\widehat u(c)$, and the radial Bessel integral gives the coefficient in (Q5). |
| T3.6: $a_c$ and finite-mode extension | correct | $a_c$ is a certified lower bound for the modulus of the same fixed field at the disk center; the additional Fourier–Bessel modes require the stated coefficient and denominator certificates. |
| T3.8 | correct | The Hilbert–Schmidt bound and grouping $j=N+ip_s+\ell$ reproduce the draft's `boundary-propagation-tail` constant and correctly include the added seam terms. |
| T3.9: Lyapunov tail | correct | Finite telescoping followed by monotone convergence proves (PT3). |
| T3.9: residual correction and approximate Gram | correct | The displayed $D$ satisfies $D-\mathsf P^*D\mathsf P\succeq I$; stability gives positivity of the corrected $S$, and Young's inequality gives (PT5). |
| T3.10 | correct | Upper residual and trace bounds, a lower mass bound and a positive denominator give the stated spectral intersection; the common-gap certificate supplies its discrete-spectrum interpretation. |
| T3.1 | correct | Reflection-conjugation yields a holomorphic integrand, and the two-sided aliasing sum gives $2M_F/(e^{2\pi aN}-1)$. |
| T3.2: Kress bound (Q2) | correct | Each unretained Fourier mode contributes at most twice its coefficient magnitude, including the symmetric Nyquist convention. |
| T3.2: complex targets (Q2c)–(Q2d) | correct | The specified Fourier analytic continuation introduces the stated factor $e^{2\pi b|m|}$ and preserves the smooth-part trapezoid bound. |
| T3.2: analytic kernel splitting (Q3) | correct | The Hankel series has the stated signs and constants, and the two-wave-number difference removes the leading hypersingular part before bounding the analytic factors. |
| T3.3 | correct | The uniform Taylor error gives an $L^2$ error at most $\sqrt{2h}\,e$, producing both bounds in (Q4). |
| T2.4 | correct | Repeated integration by parts gives the endpoint terms with the stated normalization, and the square-sum and integral tests give (T2.10). |
| T3.4a: source-cluster theorem | correct | The complex source disk, derivative envelopes and Cauchy remainder give (F3)–(F4); the moment translations are finite identities. |
| T4.4 | correct | Expanding $p(\lambda)$ about $\mu$ gives the stated quadratic inequality and positive root. |
| T4.5 | correct | The grouped estimates add as $\sum_g C_g\varepsilon_g$, and the variable collar argument differentiates only in the normal coordinate. |
| T4.6 | correct | Minimizing the two reciprocal terms gives the displayed optimal $\ell_*$ and minimum product. |
| T4.7 | correct | The local contraction estimate separates near parameter pairs, and the chord-distance condition separates the remaining pairs. |
| T5 | not reviewed | Screened for a clear mathematical error only; its implementation and cost proposals received no full audit. |
| Draft-change item 1: different leads | correct | The proposed change matches the physical model and the independently proved two-lead statement. |
| Draft-change item 2: seams and modal tails | correct | Exact quasi-periodicity is not implied by the fixed MFS representation, and the old Rayleigh-tail argument does not apply to its general wall trace. |
| Draft-change item 3: collar overlap | correct | Separation by more than the sum of the two half-widths is needed for the stated disjoint-collar inference. |
| Draft-change item 4: spectral bottom | correct | The draft's closed-set formula retains zero, whereas the fixed nonzero transverse phase gives the positive lower bound stated in the report. |
| Draft-change item 5: discrete point sources | correct | A two-dimensional logarithmic monopole is locally square integrable, whereas a nonzero point dipole generally is not. |

## R-1 — Nonnegative lower bounds are needed in (T1.7)

**Form:** 3 — Missing hypothesis. **Class:** important caveat.

**Quoted text:** Lines 251–258 assume only

> “$\ell_{n,i}\le\lambda_{s,n}(\theta_i)\le u_{n,i}$”

and then define

$$
\underline b_s=
\left(\max\left\{0,\min_i\sqrt{\ell_{n_s+1,i}}
-\frac{h_s}{\sqrt{\rho_{\min,s}}}\right\}\right)^2.
$$

**Argument.** A reliable lower bound for a nonnegative eigenvalue need not itself be nonnegative. For example, at any of the fibers under consideration, $\ell_{n_s+1,i}=-1$ is a valid lower bound because the fiber operator is nonnegative. It satisfies the stated enclosure hypothesis, but $\sqrt{\ell_{n_s+1,i}}$ is not a real number. The outer maximum with zero occurs after this square root and does not repair its domain. Thus the grid recipe is not defined for every enclosure permitted by its stated hypotheses. This issue concerns the recipe (T1.7), not the validity of (T1.5) or (T1.6).

**Smallest repair.** Replace each lower bound under the square root by its nonnegative part:

$$
\underline b_s=
\left(\max\left\{0,\min_i\sqrt{\max\{0,\ell_{n_s+1,i}\}}
-\frac{h_s}{\sqrt{\rho_{\min,s}}}\right\}\right)^2.
$$

The fiber nonnegativity already proved in T1.1 makes the clipped value a valid lower eigenvalue bound. Alternatively, explicitly require every lower bound used in (T1.7) to be nonnegative. Neither repair changes the formula when the supplied bounds are already positive.

## Source and verification record

Review literature verification completed for the cited passages used in this review. The inspected Fliss source is *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides*, arXiv:1202.4928v2 (30 January 2013): Remark 2.1(2), printed/PDF p. 4; Proposition 3.1, p. 7; Proposition 3.3, p. 8; Theorem 3.5, p. 9. The report correctly distinguishes the remark's extension from the displayed one-background propositions; T1 supplies its own two-lead and decay proofs.

Trefethen–Weideman, *The Exponentially Convergent Trapezoidal Rule* (2014), Theorem 3.2 and (3.16), printed p. 396/PDF p. 12, have the strip hypothesis and $4\pi M/(e^{aN}-1)$ constant stated in the report. Rescaling the period gives T3.1. Dahne–Salvy, *Computation of Tight Enclosures for Laplacian Eigenvalues*, arXiv:2003.08095v2, §§2.1–2.2, printed/PDF pp. 6–7, support the limited methodological attribution concerning combined Taylor expansions and interior norm bounds; T3.3 and T3.6 were checked from their own proofs.

The trace-kernel identity was also checked at 20 exact rational parameter pairs using standard-library Python through `conda run -n octave python`; this was a sanity check accompanying the algebraic verification. No numerical experiment or interval implementation was reviewed. The supplied draft theorem and Proposition 5.1 were not re-reviewed. The report and draft sources were not modified; only this review file was written.
