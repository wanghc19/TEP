# Review of the English SISC draft

**3 blockers, 4 important caveats, 1 minor caveat.** The abstract spectral-distance theorem is correct under its stated field and trace hypotheses; the evaluation rules do not establish all its inputs as written.

Scope: the requested mathematical statements, proofs, input bounds, notation and proof references in `draft/bie-siam/`, compared with the corresponding Chinese text and the accepted internal reviews. Numerical results, assumption verification, implementation and the FEM comparison were not reviewed. No compilation or computation was performed.

## Statement and proof checks

Paths in this table are relative to `draft/bie-siam/`. A verdict on an abstract estimate is separate from the verdict on the proposed computation of its inputs.

| Item | Verdict | One-line check |
|---|---|---|
| `sec-model.tex`, operator and `eq:domain-h2` | correct | The closed nonnegative form gives the stated operator, and Fourier analysis gives its global quasi-periodic $H^2$ domain. |
| `prop:ess`, periodic spectrum | correct | The direct integral, continuity of the band functions and uniform divergence of the high bands give the stated closed union. |
| `prop:ess`, exclusion of other essential spectrum | correct | The localized resolvents give a right parametrix modulo compact operators; self-adjointness completes the Fredholm argument. |
| `prop:ess`, inclusion of both lead spectra | correct | Normalized translated Bloch cutoffs have residual tending to zero and converge weakly to zero. |
| `prop:ess`, use of Fliss | correct | The English text distinguishes the identical-lead proposition from the two-lead extension and supplies its own proof. |
| Spectral lower bound $\lambda_0=b_\beta^2/\rho_{\max}$ | correct | The transverse Poincaré inequality and the upper mass bound give this lower bound, including zero when appropriate. |
| `ass:gap` | correct | It is an explicit assumption; the results that require it identify that dependence. |
| `prop:discrete`, discrete spectrum | correct | Absence of essential spectrum gives isolated eigenvalues of finite multiplicity with accumulation possible only at gap endpoints. |
| `prop:discrete`, exponential decay | correct | The conjugated periodic resolvent has the displayed relative perturbation bound, uniformly in the flattened weight. |
| `lem:lipschitz` | correct | The common-domain gauge transform and min–max principle give the stated Lipschitz constant for the square roots. |
| `thm:complement`, cross-term Gram | correct | $G_{\mathcal I}$ is the Gram matrix of $(I-P)\rho_s\psi_j$, and completing the square gives the displayed lower form. |
| `thm:complement`, both index inequalities | correct | Restriction proves the first inequality; projection is injective on every negative subspace for the second. |
| Rod formulas for $M_{\mathcal I},G_{\mathcal I}$ | correct | Multiplication by the indicator is a projection, giving $G_{\mathcal I}=\delta_s^2(B_{\mathcal I}-B_{\mathcal I}^2)$. |
| `prop:panel` | correct | The strict lower test and non-strict upper test propagate across each panel with the band-root Lipschitz estimate. |
| Reflection reduction and `eq:gap-condition` | correct | Reflection followed by conjugation preserves the transverse phase; the strict endpoint inequalities put the entire interval inside both gaps. |
| `lem:uc` and its supplement proof | correct | Zero extension across the homogeneous port strip, continuation through the connected background and zero Cauchy data on the rods give uniqueness. |
| `prop:reduction`, restriction and injectivity | correct | Global domain functions have matching Cauchy data, and the half-guide uniqueness lemma proves injectivity. |
| `prop:reduction`, surjectivity | correct | Matching values give global $H^1_\beta$; matching fluxes remove interface distributions from the Laplacian. |
| DtN exceptional-value paragraph | R-6 | The countable-exception claim lost its restriction to a common gap. |
| `ass:wood` and the port Cauchy map | correct | Nonzero Rayleigh exponents give the stated invertible value/normal-amplitude map. |
| `thm:center-rep`, extraction and convergence | correct | The port traces determine the incident sequences, and their weighted square summability gives convergence in $H^1$. |
| `thm:center-rep`, auxiliary problem and density signs | correct | The assumed exchanged problem supplies the auxiliary field, and its jumps give both displayed expressions for the densities. |
| `thm:center-rep`, interior and exterior representations | correct | Green's formula has the stated signs; quasi-periodic seam terms and outgoing modal port Wronskians cancel. |
| `thm:center-rep`, uniqueness and empty rod | correct | The complementary field and Rellich argument prove density uniqueness, and the empty-cell solution consists of the incident Rayleigh series. |
| Stable subspaces and `eq:propagation` | correct | The leading Schur blocks give the propagation identities, including nonnormal and multiple multipliers. |
| Discrete DtN graph and basis independence | correct | On an invertible value block, $ND^{-1}$ is unchanged by a change of stable basis. |
| Local analyticity of the discrete port matrix | correct | The stated regular-pencil, separated-cluster and elimination assumptions supply local analytic subspaces and a meromorphic DtN graph. |
| `eq:mfs-field`, fixed field and Helmholtz equation | correct | The continuous densities, unwrapped near images, fixed exterior proxies and exact dispersion relations define a piecewise Helmholtz field. |
| `sm:cor-near-image`, parts $i$–(iii) | R-8 | Removing the three image sources leaves a homogeneous analytic kernel on the stated region, including a neighborhood of the closed cell. |
| `sm:prop-piecewise-h2` and field property (P3) | R-4 | The normal-coordinate lifting used in the proof is not justified by the retained $C^2$ boundary hypothesis. |
| Lead field definition and property (P4) | correct | A bounded reference-cell map and a contracting power of each finite propagation matrix give a square-summable whole-strip field. |
| Interface and seam jump signs | correct | The value jump and the oppositely oriented flux jump reproduce Green's identity, including the factor $e^{i\beta d}$ at the seam. |
| `eq:actual-jumps` and Müller cancellation | correct | The common-density hypersingular terms cancel, and the smooth image, proxy and incident terms remain in the actual jumps. |
| `sm:global-h2` | correct | Fourier Parseval gives $\|D^2v\|_2=\|\Delta v\|_2$, and $\Delta v=-\rho Av$ gives the stated weighted estimate. |
| `prop:trace`, normal-segment estimate | correct | Weighted averaging gives the stated kernel and the bound $\delta/6+\delta h^2/[40(1-h^2)]$. |
| `prop:trace`, collars and grouped constants | correct | Injectivity and the multiplicity on the quasi-periodic cylinder give precisely the factors $N_g,D_{0,g},D_{1,g}$. |
| `prop:trace`, spectral multiplier | correct | The three global energy estimates give $p_g$, and the spectral theorem gives the supremum over $[\lambda_0,\infty$). |
| `thm:distance`, weak Green identity and cutoffs | correct | The proof uses only piecewise regularity, square-integrability of the field and the grouped jumps; the extra cutoff terms tend to zero. |
| `thm:distance`, resolvent argument | correct | Applying the resolvent to an $L^2_\rho$ field is legitimate without placing that field in $D(A)$, and yields $2\mu Q/(U-Q)$. |
| Volume-residual extension | correct | The additional functional has norm at most $\|\rho^{-1}r\|_{\mathcal H}/\delta$, giving the stated addition to the final numerator. |
| `eq:lead-sum` and general-$p$ `eq:tail` | correct | Grouping $j=N+ip+l$ retains every transient power and gives the factor $\sum_{l<p}\|P^l\|_2^2/(1-r^2)$. |
| `eq:disk` | correct | The circular mean identity and Cauchy–Schwarz give the Bessel factor and the point-value lower bound. |
| `eq:panel` | correct | The uniform function error costs at most $\sqrt{\vert I\vert }e_I$ in the $L^2$ norm. |
| Computable-input list and final interpretation | R-1–R-5, R-7 | The list and conditional scalar assembly are correct, but the listed evaluation rules need the repairs below. |
| `sm:lem-cheb`, analytic remainder | correct | Chebyshev aliasing at the roots and the Cauchy coefficient bound give $4M_I\varrho^{1-L}/(\varrho-1)$. |
| `sm:lem-cheb`, node errors | correct | The vector discrete-cosine Parseval identity gives the factor $\sqrt{2L-1}$. |
| `sm:lem-cheb`, coefficient balls | correct | In the Chebyshev basis used in the proof, the basis functions have modulus at most one and the coefficient-radius sum bounds the function error. |
| `sm:lem-regular`, expansion and recurrence | correct | The Helmholtz coefficient recurrence determines each diagonal from a pure derivative and gives the stated expansion. |
| `sm:lem-regular`, truncation and coefficient errors | correct | The bidisk Cauchy bound and the bound on $\Phi_m$ give the two geometric tails and the finite error sum. |
| Source moments, `sm:eq-moment` | correct | Joint holomorphy gives the normalized source-coefficient bounds, with density integration and moment errors charged separately. |
| Propagation of $E_\nu$ to real targets | correct | The normalized Bessel integral gives $\vert\Phi_m(-x)\vert\le1$ for $x\ge0$, so the stated finite coefficient-error factor is sufficient. |
| `sm:lem-green`, radial bounds $g_0,g_1,g_2$ | correct | The Hankel series, harmonic-number bound and differentiated logarithm give the stated scalar envelopes. |
| `sm:lem-green`, Hessian norm | R-7 | The displayed Hessian estimate is proved in operator norm, whereas the section declares Frobenius norms for matrices. |
| Complex source-distance and logarithm bounds | R-5 | The source displacement must bound both complex characteristic coordinates, not merely Euclidean displacement. |
| `sm:eq-kernel`, source-normal column estimate | R-5, R-7 | The value, gradient and source-normal gradient are bounded by the scalar envelopes and the induced Hessian norm. |
| `sm:lem-local` | correct | Plane-wave modulus bounds and Fourier triangle bounds give the envelope; the Cauchy coefficient estimate gives the Taylor tail. |
| Analytic speed and normal weights | R-5 | The positive-real-part test fixes the branches, but the speed bound denoted by $\overline v$ needs its omitted definition. |
| `sm:lem-self` | correct | The Fourier continuation of the log-sine convolution gives $2H_A/(e^{a-R_t}-1)+H_B$. |
| `sm:lem-kress`, exact modes and Nyquist split | correct | The interpolant is convolved exactly with the logarithm; the split Nyquist mode satisfies the stated bound. |
| `sm:lem-kress`, alias sum and smooth term | correct | Periodicity of $w_N$ gives the finite alias sum, and the periodic analytic trapezoid estimate gives the $B$ term. |
| Self-interaction node and interpolation domains | correct | Real-node Kress bounds and the larger interpolation-envelope domain have distinct roles, as in the accepted A2–A3 review. |
| Signed polynomial combination and $V_I$ | correct | The finite polynomial is fixed after charging coefficient errors, and its integrated squared norm is a finite polynomial calculation. |
| Lead cells, finite statewise sums | correct | Each actual state gets its own polynomial and error before the squared $L^2$ bounds are summed. |
| Lead envelopes, propagation and face lengths | R-2 | The wall factor needs a one-step norm, and pointwise face bounds need their physical length factors. |
| Lead envelopes, density and incident contributions | R-3 | The density map does not supply the missing bound on incident amplitudes. |
| Group assembly `sm:eq-eps` | correct | Shared walls and seam pairs are counted once, and the squared tails are added before taking the square root. |
| Supplement disk mass | correct | Containment, disjointness and the clipped lower point-value bounds give additive mass lower bounds for the same field. |
| Collar injectivity test | correct | The polar angle increases along each offset and the radial coordinate increases along a fixed ray, giving global injectivity. |
| Curvature and overlap tests | correct | Interval derivative bounds cover the curves, and the stated lattice separations control the collar multiplicity. |
| Computation of the trace supremum | R-1 | An enclosure containing zero does not prove a vanishing derivative coefficient. |
| Fourier moments for the gap matrices | correct | The divergence-theorem boundary formula and the periodic analytic trapezoid remainder have the stated signs and factors. |
| Matrix-entry perturbations | correct | The $B-B^2$ perturbation costs $e_B(3+e_B)$, and the two matrix tests use opposite safe shifts. |
| Finite matrix sign tests | correct | A negative trial vector supplies the lower count, and positivity on an ((N-1))-dimensional subspace supplies the upper count. |
| Scalar assembly and square-root interval | correct | Upper $Q$, lower $U$, a positive denominator and outward endpoint bounds preserve the spectral inclusion. |
| Requested renamings | correct | $\zeta,\varrho(P),\delta_e,\mathsf a,i,\chi_X$ retain their declared meanings in the statements and proofs that use them. |
| Remaining symbol definitions | R-5, R-8 | The complex displacement/speed bounds and the quasi-periodic phase need the definitions identified below. |
| Proof cross-references | correct | The inspected `\cref` and `\eqref` targets point to the arguments or formulas actually used; R-4 concerns a hypothesis of the referenced proof. |

## R-1 — The uncertain-denominator branch can miss the maximum

**Form 2: counterexample. Class: blocker.**

`draft/bie-siam/sm-reliable.tex:311–313`:

> “If ball arithmetic cannot exclude $2c_g\mu=b_g$, $F$ is monotone and the supremum is $\max\{F(\lambda_0),c_g\}$.”

Take $\mu=1$, $\lambda_0=0$, $a_g=c_g=1$, $b_g=3$. Then

\[
F(\lambda)=\frac{1+3\lambda+\lambda^2}{(1+\lambda)^2},\qquad
F(0)=\lim_{\lambda\to\infty}F(\lambda)=1,\qquad F(1)=\frac54.
\]

The exact denominator $2c_g\mu-b_g=-1$ can have a valid enclosure containing zero, for example $[-2,0]$. The proposed branch returns $1$, below the actual supremum. The issue is the logical use of an inconclusive enclosure, independently of how that enclosure was obtained. Positive coefficients of this type also obey the structure of $p_g$: with unit density and $D_0=1$, choose $D_1=(3+\sqrt5)/2$ and $\ell_g^2=(3-\sqrt5)/2$.

**Repair — replace the last two sentences of the branch by:**

> The endpoint formula applies if $2c_g\mu-b_g=0$ is established exactly. If its enclosure contains zero without establishing equality, refine the enclosure or use the safe upper bound
> \[
> C_g^2\le \frac{\overline a_g}{\mu^2}
>       +\frac{\overline b_g}{4\mu}+\overline c_g,
> \]
> where the bars are upper bounds on the nonnegative coefficients. This follows from $\lambda\ge0$, $\lambda/(\lambda+\mu)^2\le1/(4\mu)$, and $\lambda^2/(\lambda+\mu)^2\le1$.

This error is inherited from `draft/bie-enclosure/a-reliable.tex:384–387`; it is not a consequence of translating the abstract trace estimate.

## R-2 — The explicit face envelopes do not cover the stated general-p tail

**Form 1: failed step. Class: blocker.**

`draft/bie-siam/sm-reliable.tex:237–254` sets

> “$B_{\mathrm{wall}}=(1+r)S_{\mathrm{face}},\qquad B_{\mathrm{seam}}=2S_{\mathrm{face}}$”

and explains that a wall involves $v_j$ and $Pv_j$. The available hypothesis in `sec-bound.tex:247–255` is $\|P^p\|_2\le r<1$, explicitly allowing $p>1$. It does not give $\|Pv\|\le r\|v\|$.

For example, $P=\left[\begin{smallmatrix}0&M\\0&0\end{smallmatrix}\right]$, $M>1$, satisfies $P^2=0$, so $p=2,r=0$ is valid. For the scalar face map $F(v)=v_1$, its unit-state envelope is $S_{\mathrm{face}}=1$. The comparison between two consecutive face values at $v=(0,1)^T$ has magnitude $M$, exceeding $(1+r)S_{\mathrm{face}}=1$. Thus the one-step factor used to construct $\Theta$ does not follow from the contracting-power hypothesis. The abstract formula `eq:tail` is correct.

There is a separate normalization loss in the same display: a pointwise envelope on a wall of length $d$ or a seam segment of length $L_s$ must be multiplied by $\sqrt d$ or $\sqrt{L_s}$. The Chinese text explicitly restricts these formulas to walls and seams of length one (`a-reliable.tex:313`); that restriction is absent here.

**Repair — replace the face-envelope display and its explanation by:**

> Let $\kappa_P\ge\|P\|_2$, independently of the bound $\|P^p\|_2\le r<1$. Let $S_{\mathrm{face}}$ bound the group-weighted value/normal trace vector pointwise on every relevant face for unit states. Then
> \[
> B_{\mathrm{wall}}=\sqrt d\,(1+\kappa_P)S_{\mathrm{face}},
> \qquad B_{\mathrm{seam}}=2\sqrt{L_s}\,S_{\mathrm{face}}.
> \]
> These constants define $\Theta=B^2$; the tail itself still uses the contracting power and all the transient factors in \eqref{eq:tail}. If $p=1$, $\kappa_P=r$ is admissible.

The face maps in this replacement must include the $\ell_g^{-1}$ weight in the value component, as required by `eq:defect`.

## R-3 — The density map does not bound the incident amplitudes

**Form 1: failed step. Class: blocker.**

`draft/bie-siam/sm-reliable.tex:244–251`:

> “$S_{\mathrm{face}}=(S_{\mathrm{ord}}+S_{\mathrm{inc}})\|\mathsf G\|+S_{\mathrm{pt}}$. Here $\mathsf G$ maps states to density coefficients … $S_{\mathrm{loc}}$ and $S_{\mathrm{inc}}$ bound the local and incident Rayleigh terms, the latter by $(\sum_{|m|\le48}2(1+|\gamma_m|^2+\beta_m^2)/d)^{1/2}$.”

The displayed Rayleigh envelope bounds the field per unit norm of the **incident amplitude vector**. It is not a bound per unit density norm. In the right cell, `sec-bound.tex:61–63` defines the actual incident map as

\[
\mathsf A_{\mathrm{inc},+}
=\begin{bmatrix}\mathsf Z_{+,a}\\ \mathsf Z_{+,b}\mathsf P_+\end{bmatrix},
\]

where $\mathsf Z_{+,a},\mathsf Z_{+,b}$ are the two row blocks of $\mathsf Z_+$. Consequently the incident contribution is bounded by $S_{\mathrm{inc}}\|\mathsf A_{\mathrm{inc},+}\|\|v\|$. Nothing stated proves $\|\mathsf A_{\mathrm{inc},+}\|\le\|\mathsf G\|$. A linear map from incident amplitudes to densities supplies no such inequality: its norm can be less than one. The same missing factor occurs in $B_{\mathrm{mat}}$, because $S_{\mathrm{loc}}$ contains incident waves but is multiplied by the density-map norm.

**Repair — insert the following definition and use it in both envelope formulas:**

> Write $\mathsf G_\eta$ for the state-to-density map and $\mathsf A_{\mathrm{inc}}$ for the state-to-incident-amplitude map. Set
> \[
> \mathsf G_{\mathrm{all}}
>   =\begin{bmatrix}\mathsf G_\eta\\\mathsf A_{\mathrm{inc}}\end{bmatrix}.
> \]
> In the formulas for $B_{\mathrm{mat}}$ and $S_{\mathrm{face}}$, replace $\|\mathsf G\|$ by an upper bound for $\|\mathsf G_{\mathrm{all}}\|$. For the right lead,
> $\mathsf A_{\mathrm{inc}}=[\mathsf Z_{+,a};\mathsf Z_{+,b}\mathsf P_+]$; for the left lead it is
> $[\mathsf Z_{-,a}\mathsf P_-;\mathsf Z_{-,b}]$.
> The proxy contribution includes its separate state-to-proxy map.

This gives a common norm that bounds both coefficient blocks. Alternatively, keep separate density and incident terms with their respective map norms. The same unsupported multiplication is present in the Chinese `a-reliable.tex:299–311`.

## R-4 — The piecewise regularity proof lost the analytic-curve hypothesis

**Form 3: missing hypothesis. Class: important caveat.**

`draft/bie-siam/sm-proofs.tex:229–233` assumes separation, trigonometric densities and one background wave number, while `sec-model.tex:10` assumes only $C^2$ material boundaries. The proof then states at `sm-proofs.tex:241–245`:

> “let $w=0$ inside and $w=(\tau(s)-t\omega(s))\chi(t)$ outside … with $F\in L^2_{\mathrm{loc}}$ … while $w$ is smooth up to $\Gamma$ from either side.”

A $C^2$ curve need only have continuous curvature. This particular normal-coordinate extension need not have an $L^2$ Laplacian. For a local arc-length parametrization with curvature $\kappa(s)=|s|^{1/4}$, take $\omega=0$, a smooth density with $\tau'(0)\ne0$, and a region where $\chi=1$. With metric factor $h=1-t\kappa(s)$, the tangential part of its Laplacian is

\[
\frac1h\partial_s\left(\frac{\tau'}h\right)
=\frac{\tau''}{h^2}+\frac{t\kappa'\tau'}{h^3}.
\]

The last term is not locally square-integrable near $s=0$ on a strip with $t\ne0$, since $\kappa'$ has magnitude proportional to $|s|^{-3/4}$. Such an arc is $C^2$ and can be completed to an embedded closed $C^2$ curve. Thus the asserted $F\in L^2$ does not follow from the retained assumptions. This is a defect in the given proof, not a counterexample to a stronger layer-potential regularity theorem proved by another method.

The Chinese proposition explicitly assumes a regular embedded analytic closed curve (`draft/bie-enclosure/s-error.tex:183–184`), as does the reviewed T2.2 source.

**Smallest repair — restore this hypothesis at the start of `sm:prop-piecewise-h2`:**

> Assume that every material boundary admits a regular embedded analytic periodic parametrization, and that the densities are trigonometric polynomials in that parameter.

Apply the assertion of (P3) to these trial geometries. The general operator setting and the conditional spectral-distance theorem can retain $C^2$ boundaries. To retain the proposition itself for $C^2$ boundaries, replace the explicit normal-coordinate construction by an $H^2$ trace lifting with a stated trace-lifting theorem.

## R-5 — Define the complex geometric bounds that make the envelopes valid

**Form 3: missing hypothesis. Class: important caveat.**

`draft/bie-siam/sm-reliable.tex:143–147`:

> “For source disks at distance $d_-\le d\le d_+$ from the target center, source displacement $\delta$ and radius $R$ with $R+\delta<d_-$, take $q_-=(d_--R-\delta)^2$ …”

For the independent complex target coordinates used in `sm:lem-regular`, this conclusion requires bounds on **each** source characteristic coordinate $z_s=x_s+iy_s$ and $w_s=x_s-iy_s$. A Euclidean source-displacement bound, the norm convention declared in this section, does not give the displayed bound with the same $\delta$.

A concrete example is the analytic source curve $r(s)=(\cos s,\sin s)$, source center $s=0$, target center $(2,0)$, and source disk $|s|\le\log2$. The real center distance is $d_-=d_+=1$. Throughout that disk,

\[
\|r(s)-r(0)\|_2
\le\sqrt{(\cosh(\log2)-1)^2+\sinh(\log2)^2}
=\frac{\sqrt{10}}4=:\delta.
\]

Take $R=1/10$; then $R+\delta<1$. Nevertheless, at $s=i\log2$ the source is $(5/4,3i/4)$, so its squared distance to the real target center is

\[
(2-5/4)^2+(0-3i/4)^2=0.
\]

The claimed positive $q_-$ and the two nonvanishing logarithmic factors therefore fail. The squared source speed is identically one, so the separate speed-branch condition does not exclude this example. The full coordinate-wise hypothesis is stated in `proxy-accel.md`, (PA10), and `cellker-eval.md`, (CK11).

In addition, `sm-reliable.tex:252` uses $\overline v$ without defining the upper bound it must provide. Its Chinese definition is a bound for $\sqrt{|x'|^2+|y'|^2}$ on the **complex** strip (`a-reliable.tex:202–206`), not just for the real speed.

**Repair — insert these definitions before the two uses:**

> On every source parameter disk, require
> \[
> \sup_s\max\{|z_s-z_s(c_s)|,|w_s-w_s(c_s)|\}\le\delta,
> \qquad z_s=x_s+iy_s,\quad w_s=x_s-iy_s.
> \]
> The target radius $R$ is the radius in each of the independent coordinates $z,w$. If only a Euclidean complex displacement bound $\delta_E$ is available, use $\delta=\sqrt2\,\delta_E$.

> Let $\overline v$ be an upper bound for $\sqrt{|x'(t)|^2+|y'(t)|^2}$ throughout every complex target domain used, and let $\underline s>0$ satisfy $\Re(x'(t)^2+y'(t)^2)\ge\underline s$ there.

With these meanings, the factorization of the squared distance, logarithm bound and weight factor follow as stated.

## R-6 — Countably many Dirichlet exceptions is a gap statement

**Form 3: missing hypothesis. Class: important caveat.**

`draft/bie-siam/sec-reduction.tex:56–64` first emphasizes that the reduction holds for every $k>0$, and then says:

> “At the countably many exceptional values where it is not [uniquely solvable] … the DtN form fails while Proposition [center reduction] remains valid.”

Without restricting the Dirichlet assertion to a gap, its exceptional set need not be countable. In a homogeneous half-strip with density one, prescribed boundary data $e^{i\beta y}$ and $k^2>\beta^2$, the corresponding longitudinal coefficient satisfies

\[
v_0''+(k^2-\beta^2)v_0=0.
\]

No nonzero solution is square-integrable on the half-line. Thus the finite-energy Dirichlet problem is not solvable for these data for an entire interval of $k$. This example is allowed by taking the rod and background coefficients equal. The unrestricted Cauchy-space reduction is unaffected.

**Repair — replace the exceptional-value sentence by:**

> For $k^2$ in the common gap, the finite-energy half-guide Dirichlet problem is well posed except at a countable set of Dirichlet eigenvalues. At those values the DtN graph description fails, while \cref{prop:reduction} remains valid.

The Chinese source includes exactly this gap restriction (`draft/bie-enclosure/s-reduction.tex:161–163`).

## R-7 — The Hessian estimate uses a different matrix norm

**Form 1: failed step. Class: important caveat.**

`draft/bie-siam/sm-reliable.tex:38–40` declares Frobenius norms for matrices. At lines 130–140 the lemma asserts

> “$\|\nabla^2G\|\le2g_1+4D^2g_2$”

and derives it from

\[
\nabla^2G=2G'I+4G''dd^T.
\]

The displayed argument supplies this bound in the induced Euclidean operator norm. With the declared Frobenius norm it instead supplies

\[
\|\nabla^2G\|_F\le2\sqrt2\,g_1+4D^2g_2,
\]

because $\|I_2\|_F=\sqrt2$. The proof gives no alternative estimate that removes that factor in the Frobenius norm.

**Smallest repair — add a local norm specification to the lemma:**

> In the Hessian estimate only, $\|\nabla^2G\|$ denotes the induced Euclidean operator norm; the value-and-gradient vectors and state matrices retain the Euclidean and Frobenius norms specified above.

This is enough for the subsequent kernel estimate, which uses the Hessian only through a source-normal column: $\|(\nabla^2G)n\|_2\le\|\nabla^2G\|_{2\to2}\|n\|_2$. If a Frobenius estimate for the full Hessian is intended instead, replace $2g_1$ by $2\sqrt2g_1$.

## R-8 — The quasi-periodic phase $q$ is not defined

**Form 3: missing hypothesis/definition. Class: minor caveat.**

`draft/bie-siam/sm-reliable.tex:16` refers to “the phase $q$”, and `sm-proofs.tex:200,212` uses $q^n$ in the near-image identity and its distributional proof. Neither the main text, the supplement nor `shared.tex` defines this $q$. The main text writes $e^{i\beta nd}$ explicitly, and also uses an unrelated integer index $q$ in the Fourier complement space.

**Repair — insert before the near-image formula:**

> Write $q:=e^{i\beta d}$ for the quasi-periodic phase in the near-image formulas.

This restores the definition in the Chinese source and changes no estimate.

## Differences from the Chinese and previously reviewed sources

- **Piecewise regularity:** the analytic embedded-curve hypothesis in `s-error.tex:183–184` and reviewed T2.2 became only the general model's $C^2$ hypothesis. This matters to the supplied lifting proof: R-4.
- **Dirichlet exceptional values:** the phrase restricting the claim to the gap in `s-reduction.tex:161–163` disappeared. This changes the claim: R-6.
- **Lead face envelopes:** the Chinese discussion specifies $p=1$ after bounding the one-step norm and specifies unit wall/seam lengths (`a-reliable.tex:289–314`). The English retains the same envelopes while referring to the general-$p$, general-period formula. This matters: R-2.
- **Complex geometry:** the coordinate-wise displacement condition from (PA10)/(CK11) is not stated in the compressed envelope rule; the Chinese definition of the complex speed bound was also omitted. These conditions matter: R-5.
- **Norm convention:** the blanket Euclidean/Frobenius convention must be reconciled with the Hessian operator estimate. Its use on source-normal columns needs no larger constant after the local clarification in R-7.
- **Phase:** the Chinese definition $q=e^{i\beta d}$ was omitted. This is R-8.
- **Inherited evaluation issues:** the uncertain-denominator fallback and the use of the density-map norm for incident waves are already present in the current Chinese appendix. They remain substantive errors: R-1 and R-3.
- **Unwrapped trial field:** the English agrees with the current Chinese draft's fixed-cell near-image-plus-proxy field. This differs from the older wrapped field in Theorem SW. Explicit seam jumps replace exact seam periodicity, and no interior wrap-switch contribution is needed for this field; the spectral-distance proof accounts for its actual jumps.
- **Chebyshev and Kress estimates:** after the $2\pi$-period normalization, the constants, symmetric Nyquist convention and real-node/complex-envelope domain separation agree with the accepted self-interaction review. No material hypothesis was lost in these estimates.
- **Grouped trace and spectral distance:** the curvature-dependent constant, spectral polynomial, multiplier supremum and resolvent argument retain the reviewed statements. R-1 concerns evaluation of that supremum, not the trace proposition itself.

## Source record

Inspected the English `main.tex`, `supplement.tex`, `shared.tex`, `sec-model.tex`, `sec-reduction.tex`, `sec-discretization.tex`, `sec-bound.tex`, `sm-proofs.tex`, and `sm-reliable.tex`; checked the requested renamed symbols in the remaining English sections. Compared the corresponding portions of Chinese `main-clean.tex`, `s-modelproblem.tex`, `s-reduction.tex`, `s-discretization.tex`, `s-error.tex`, `a-cellrep.tex`, `a-trace.tex`, and `a-reliable.tex`. Consulted `research/NOTATION.md`, `ref/reference.bib`, the six accepted review files named in the request, and the relevant statements in `reliable-bound.md`, `switch-line-proof.md`, `selfint-accel.md`, `reliable-eval-design.md`, `proxy-accel.md`, `cellker-eval.md`, and `cg-cert.md`.

All requested mathematical items were reviewed. The numerical values/tables, empirical search behavior, assumption verification and implementation remain outside this review. Only this review file was written.
