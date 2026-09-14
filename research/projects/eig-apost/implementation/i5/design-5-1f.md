# I5.1f signed-centre exact-special-function-oracle conditional experiment

## Scope, clock, and claim boundary

This round started at 2026-09-13 09:47:26 CST and has a hard stop at
2026-09-13 12:47:26 CST.  I5.1f evaluates only the frozen candidate,
density, QZ-selected state maps, propagation matrices, Rayleigh data, and
reconstruction rule.  It performs no eigenvalue, BIE-density, QZ,
propagation, denominator, or effectivity solve.

The experiment asks whether retaining signed finite centres can reduce the
ordinary-roundoff-excluded ideal model expression below the phase gate.  Two
global finite-evaluation remainders remain explicitly unresolved:

$$
\Delta_{\mathrm{eval}}
=\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}.
\tag{I5.1f-1}
$$

Here $\Delta_{\mathrm{sf}}$ encloses the final-numerator effect of all
retained transcendental primitive
and branch evaluations, including `erfc`/Faddeeva, $E_1$, exponentials,
logarithms, square roots, phases, and their required coordinate derivatives.
$\Delta_{\mathrm{fp}}$ is the final-numerator remainder for geometry,
density and weight evaluation, matrix products, finite summation, and the
remaining floating-point operations.  It is not assumed to be reducible to
row-action errors while it remains unevaluated.  Neither remainder is set to
zero or assigned a numerical value in
phase 1.  The signed centre is evaluated under the named special-function
oracle condition solely to measure its ideal cancellation.  Every analytic
series, quadrature, Ewald, Fourier, trace/lift, and propagation remainder
remains present.  Consequently its output is
`CONDITIONAL_ON_EXACT_SPECIAL_FUNCTION_EVALUATION` and
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`, never a reliable or certified enclosure.

Let $\mathcal M_{\mathrm{an}}$ be the exact-real-arithmetic value of the
complete centre-plus-analytic-radius expression with exact special-function
primitives.  Let $\mathcal M_{\mathrm{lib}}$ be the value of that same
expression when the library primitive return values are held fixed but all
remaining operations are exact, and let $\mathcal M_{\mathrm{ideal}}$ be the
ordinary finite-arithmetic value written by phase 1.  The unresolved
final-functional remainders mean

$$
\Delta_{\mathrm{sf}}
\ge|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{lib}}|,
\qquad
\Delta_{\mathrm{fp}}
\ge|\mathcal M_{\mathrm{lib}}-\mathcal M_{\mathrm{ideal}}|.
\tag{I5.1f-1a}
$$

The frozen binary inputs are exact data under this experiment's convention;
their approximation to an unknown true solution is outside both remainders.
Equation (I5.1f-1a) is at the final-numerator level, so it also owns nonlinear
norm and square-root propagation and cannot be replaced by a bare kernel-value
error.  The analytic theorem below proves
$\|R\|_{\mu,*}\le\mathcal M_{\mathrm{an}}$; (I5.1f-1a) then supplies the
second inequality in (I5.1f-5).

The governing curve result is shape general: a regular injective single-chart
periodic curve with the real $C^6$ certificate needed by the fourth-order
local bounds, together with separately certified holomorphic strips only for
the regular-image, off-surface, and wall trapezoid estimates.  A merely
$C^6$ curve is not asserted to have such a strip.  The current circle is only
an instance adapter and no Fourier/Bessel operator diagonalization is used.

## Conditional complete numerator theorem

The exact-kernel reconstruction has zero volume residual in each material
piece.  Therefore the artificial-wall normal jump, material normal defect,
and value-defect lifting below exhaust the strong residual; there is no fourth
volume module.

For each retained material order $|\ell|<L$, let the exact unit-density rows
be split into local self, regular-image raw, and off-surface raw actions.  The
physical signed centre is

$$
\widetilde j_\ell^{\mathrm{val}}
=\widetilde j_\ell^{\mathrm{self,val}}
+\widetilde j_\ell^{\mathrm{reg,raw,val}}
+\widetilde j_\ell^{\mathrm{off,raw,val}},
$$

$$
\widetilde j_\ell^{\mathrm{nor}}
=\widetilde j_\ell^{\mathrm{self,nor}}
-\widetilde j_\ell^{\mathrm{reg,raw,nor}}
-\widetilde j_\ell^{\mathrm{off,raw,nor}}.
\tag{I5.1f-2}
$$

The local identity is already inside the self centre exactly once.  There is
no identity in the regular-image or off-surface rows.  For
$\chi\in\{\mathrm{val},\mathrm{nor}\}$ put the analytic row radius

$$
\delta_{\ell,\mathrm{an}}^\chi
=\delta_\ell^{\mathrm{self},\chi}
+\delta_\ell^{\mathrm{reg},\chi}
+\delta_\ell^{\mathrm{off},\chi}.
\tag{I5.1f-3}
$$

The three analytic radii are defined below and have disjoint telescope
owners.  With the singleton $q_0$ and side maps $G_\varsigma$,

$$
C_{0,\ell}^\chi=\widetilde j_\ell^\chi q_0,
\qquad
C_{\varsigma,\ell}^\chi=\widetilde j_\ell^\chi G_\varsigma,
$$

$$
\epsilon_{0,\ell}^\chi=\delta_{\ell,\mathrm{an}}^\chi\|q_0\|_2,
\qquad
\epsilon_{\varsigma,\ell}^\chi
=\delta_{\ell,\mathrm{an}}^\chi\|G_\varsigma\|_2.
\tag{I5.1f-4}
$$

Use (KR-27)--(KR-29) with the normal trace divisor $b_\ell$, and use
(KR-30)--(KR-31c) with multiplication by the lifting weight
$e_{\ell,\mathrm{val}}$.  The same complete centre maps and radii are used in
the $n\ge J$ block-power tail.  Within one material defect the local,
regular-image, and off-surface high-mode sequence norms are added before
squaring.  Wall and material collars are disjoint and are added after
squaring.  Define the ideal module expressions by

$$
\widehat B_{\Gamma_\pm}^{\mathrm{ideal}}
=\sqrt{\overline F_{\Gamma_\pm}^2+T_{\Gamma_\pm}^2},
\qquad
\widehat B_\Upsilon^{\mathrm{ideal}}
=\sqrt{\overline F_\Upsilon^2+T_\Upsilon^2},
$$

$$
\widehat B_{\mathrm{lift}}^{\mathrm{ideal}}
=2\sqrt{\overline F_{\mathrm{lift},\Upsilon}^2
+\overline F_{\mathrm{lift},\Gamma}^2+T_{\mathrm{lift}}^2}.
\tag{I5.1f-5a}
$$

Their ordinary phase-1 values contain every analytic radius but neither
unresolved finite-evaluation remainder and sum to
$\mathcal M_{\mathrm{ideal}}$; their exact-arithmetic counterpart is
$\mathcal M_{\mathrm{an}}$.  By definition, $\Delta_{\mathrm{sf}}$ and
$\Delta_{\mathrm{fp}}$ are already final-functional bounds.  Their
construction must include the zero-centred rowwise Minkowski assembly and
also any evaluation error in analytic certificate constants, geometry,
weights, and matrix norms.  The triangle inequality gives

$$
\boxed{
\|R\|_{\mu,*}
\le \widehat B_{\Gamma_\pm}^{\mathrm{ideal}}
+\widehat B_\Upsilon^{\mathrm{ideal}}
+\widehat B_{\mathrm{lift}}^{\mathrm{ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}
=:\mathcal M_{\mathrm{ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}.}
\tag{I5.1f-5}
$$

The experiment computes only $\mathcal M_{\mathrm{ideal}}$.  Both
$\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$ remain
`UNRESOLVED`, so (I5.1f-5) does not provide a numerical reliable bound.

## Local signed centre and tight real-variable radii

Let $K=(K_1,K_2)$ be the complete density-, Jacobian-, normal-, tangent-,
and Maue-inclusive local integrand, $K_Q$ its signed diagonal-safe finite
series, $Q_N$ the source Kress rule, and $\mathcal D_N$ the target DFT.  The
centre and exact telescope are

$$
\widetilde d_\ell^{\mathrm{self}}
=\mathcal D_N[J+Q_NK_Q],
$$

$$
\begin{split}
d_\ell^{\mathrm{self}}-\widetilde d_\ell^{\mathrm{self}}
={}&\{\mathcal D[J+\mathcal AK]
-\mathcal D_N[J+\mathcal AK]\}\\
&+\mathcal D_N[(\mathcal A-Q_N)K]
+\mathcal D_N[Q_N(K-K_Q)].
\end{split}
\tag{I5.1f-6}
$$

The three lines own target DFT aliasing, source Kress error, and omitted
kernel series.  Thus

$$
\delta_\ell^{\mathrm{self},\chi}
=\epsilon_{\ell,\mathrm{tgt}}^\chi
+\epsilon_{\ell,\mathrm{src}}^\chi
+\epsilon_{\ell,\mathrm{series}}^\chi.
\tag{I5.1f-7}
$$

The series radius is exactly (KR-21b), using only the first omitted terms of
the signed entire $J/Y$ and cancellation-safe divided-difference series.  It
does not contain an unsigned copy of the retained centre.

The source theorem (KR-16)--(KR-17) is valid for any integer $p\ge2$.
I5.1f uses $p=4$:

$$
E_{\mathrm{src}}^\chi(t_i)
\le S_{1,4}^\chi(t_i)C_{4,N}^{K}
+S_{2,4}^\chi(t_i)C_{4,N}^{T},
$$

$$
\epsilon_{\ell,\mathrm{src}}^\chi
\le\frac{2\pi}{N\sqrt P}
\sum_{i=0}^{N-1}s(t_i)E_{\mathrm{src}}^\chi(t_i).
\tag{I5.1f-8}
$$

The constants $C_{4,N}^{K}$ and $C_{4,N}^{T}$ are the explicit harmonic and
integral-test bounds in (KR-17).  The fourth source derivatives include the
frozen density.  In the ideal model use the exact finite-DFT coefficient row
$2$-norm sums

$$
A_{E,q}^{(2)}=\sum_{m\in\mathcal I_\eta}|m|^q
\|\widehat E_m\|_2,
\qquad E\in\{\tau,\zeta\},
\tag{I5.1f-8a}
$$

through $q=4$ and through $q=5$ for the normal Maue term containing
$\tau'$.  The v4 coefficientwise DFT balls (ZF-35)--(ZF-41) are an optional
independent upper, not a mandatory or additional radius.  Error in the
finite DFT used to evaluate (I5.1f-8a) belongs to
$\Delta_{\mathrm{fp}}$.

For the present circle certificate only, put
$x(h)=4R^2\sin^2(h/2)$.  If $F_r\ge\sup_{0\le x\le4R^2}|F^{(r)}(x)|$ and
$X_j\ge\|x^{(j)}\|_\infty$ with $X_j=2R^2$ for $1\le j\le4$, then

$$
\begin{aligned}
B_0(F\circ x)&=F_0,\\
B_1(F\circ x)&=F_1X_1,\\
B_2(F\circ x)&=F_2X_1^2+F_1X_2,\\
B_3(F\circ x)&=F_3X_1^3+3F_2X_1X_2+F_1X_3,\\
B_4(F\circ x)&=F_4X_1^4+6F_3X_1^2X_2+3F_2X_2^2
+4F_2X_1X_3+F_1X_4.
\end{aligned}
\tag{I5.1f-9}
$$

Finite Leibniz sums
$B_q(fg)=\sum_{r=0}^q\binom qrB_r(f)B_{q-r}(g)$, applied to all factors in
the signed $K_j^{\mathrm{val/nor}}$, give
$S_{j,4}^\chi(t)\le2\pi\sup_u|\partial_u^4K_j^\chi(t,u)|$.
The elementary $J$, regular-$Y$, shifted-$J$, and cancellation-safe
$\mathfrak c$ series supply each $F_r$ by a retained absolute sum plus a
first-omitted factorial/geometric tail with ratio strictly below one.  This
is a certificate adapter, not a circle-special theorem.

The signed adapter retains the exact I5.1c ledger

$$
K_j^{\mathrm{val}}=\Delta D_j\tau-\Delta S_j\zeta,
$$

$$
K_j^{\mathrm{nor}}
=-A_j\cos(h)\tau
-\frac{\Delta C_j^{\mathrm{tan}}}{R}\tau'
+\Delta D_j\zeta,
\qquad
A_j=\kappa_e^2S_{\kappa_e,j}-\kappa_i^2S_{\kappa_i,j}.
\tag{I5.1f-9a}
$$

Every $\Delta$ is exterior minus interior.  The normal residual has already
applied $T_i-T_e=-(T_e-T_i)$ in (I5.1f-9a); the common cotangent principal
part is cancelled before this formula.  For source order four, the three
normal products use, respectively,

$$
\sum_{r=0}^4\binom4rB_r(A_j\cos h)A_{\tau,4-r}^{(2)},
\quad
\frac1R\sum_{r=0}^4\binom4rB_r(\Delta C_j^{\mathrm{tan}})
A_{\tau,5-r}^{(2)},
\quad
\sum_{r=0}^4\binom4rB_r(\Delta D_j)A_{\zeta,4-r}^{(2)}.
\tag{I5.1f-9b}
$$

Use $J$ and regular-$Y$ $x$-derivative bounds through order four, and use
shifted-$J$ and $\mathfrak c$ bounds through order four.  The chord factor
$x$ has no $x$ derivative above one; the direct factors satisfy
$|(\mathrm d/\mathrm dh)^r\cos h|\le1$ and
$|(\mathrm d/\mathrm dh)^rp_T(h)|\le R^2$.  Each derivative-series tail is
restarted at its actual first omitted differentiated index and must pass its
own ratio gate.

For constant speed, the target alias radius uses the smaller of the $p=2$
bound (KR-19a) and

$$
\epsilon_{\ell,\mathrm{tgt},4}^\chi
\le A_{4,\chi}
\sum_{q\in\mathbb Z\setminus\{0\}}|\ell+qN|^{-4},
\quad
A_{4,\chi}=
\frac{Q_{4,\chi}P_+^4}
{16\pi_-^4s_\#(P_-)}.
\tag{I5.1f-10}
$$

For a finite cutoff $Q_A$, write $a=|\ell|$, $q_0=Q_A+1$ and bound the last
series by

$$
\begin{split}
\sum_{q=1}^{Q_A}[(qN-a)^{-4}+(qN+a)^{-4}]
&+(q_0N-a)^{-4}+\frac1{3N(q_0N-a)^3}\\
&+(q_0N+a)^{-4}+\frac1{3N(q_0N+a)^3}.
\end{split}
\tag{I5.1f-11}
$$

This is the first omitted term plus the monotone integral tail on each side.
It is valid only when $|\ell|<N/2$.  The same finite-density constants form
the identity-inclusive $H_q$, $Q_2$, and $Q_4$.  For a signed retained
centre, use the telescope radius (I5.1f-7), taking the minimum only between
the p2 and p4 bounds for the same target-error term.  A whole-action or
$A_{2,\chi}/|\ell|^2$ or $A_{4,\chi}/|\ell|^4$ coefficient upper is not by
itself a radius about a nonzero centre.  The optional valid recentered radius
is that coefficient upper plus $\|\widetilde d_\ell\|_2$, but I5.1f does
not need it.  The omitted local tail uses the smaller of
(KR-24)--(KR-25) and (ZF-33)--(ZF-34).  No two alternatives are added.

## Signed regular-image value and normal centres

Let $H_\beta=G_{e,\beta}^{QP}-G_e^{\mathrm{free}}$ and let $H_{\beta,Q}$
contain the retained reciprocal terms, nonzero images, Taylor orders, and
branch-free local canonical terms.  On a certified strip set
$s_c=(z_1'^2+z_2'^2)^{1/2}$, $n_c=(z_2',-z_1')$, and
$\nu_c=n_c/s_c$, using the holomorphic branch matching the positive real
speed.  With $X=z(t)-z(u)$ and $\zeta=-\sigma$, the raw retained integrands
are

$$
K_Q^{\mathrm{reg,val}}
=-n_c(u)\mathbin\cdot\nabla_XH_{\beta,Q}(X)\tau(u)
-s_c(u)H_{\beta,Q}(X)\zeta(u),
\tag{I5.1f-12}
$$

$$
K_Q^{\mathrm{reg,nor}}
=-\nu_c(t)^{\mathsf T}\nabla_X^2H_{\beta,Q}(X)n_c(u)\tau(u)
-s_c(u)\nu_c(t)\mathbin\cdot\nabla_XH_{\beta,Q}(X)\zeta(u).
\tag{I5.1f-13}
$$

The second terms have the displayed minus signs because the stored second
density coordinate is $\zeta=-\sigma$.  Equations (I5.1f-12)--(I5.1f-13)
are raw regular-image actions; the physical value row adds them and the
physical normal row subtracts them as in (I5.1f-2).

For either $\chi$, insert successively $H_{\beta,Q}$, the source trapezoid
$Q_{N_s}$, and the target trapezoid $\mathcal D_{N_t,\ell}$.  The exact
telescope is

$$
\begin{split}
d_{\ell,\mathrm{reg}}^{\mathrm{raw},\chi}
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw},\chi}
={}&\mathcal D_\ell\mathcal A(K^\chi-K_Q^\chi)\\
&+(\mathcal D_\ell-\mathcal D_{N_t,\ell})\mathcal AK_Q^\chi\\
&+\mathcal D_{N_t,\ell}(\mathcal A-Q_{N_s})K_Q^\chi\\
&+(\mathcal D_{N_t,\ell}Q_{N_s}K_Q^\chi
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw},\chi}).
\end{split}
\tag{I5.1f-14}
$$

The four lines own, respectively, the M-R/M-I/M-T/M-L Ewald omission,
target trapezoid, source trapezoid, and finite evaluation.  The analytic
regular radius in (I5.1f-3) is

$$
\delta_\ell^{\mathrm{reg},\chi}
=\epsilon_{\ell,\mathrm{Ew}}^{\chi}
+\epsilon_{\ell,\mathrm{tgt}}^{\chi}
+\epsilon_{\ell,\mathrm{src}}^{\chi},
\tag{I5.1f-15}
$$

while the last line of (I5.1f-14) belongs to (I5.1f-1).  For value use

$$
\epsilon_{\ell,\mathrm{Ew}}^{\mathrm{val}}
\le\sqrt P(\mathcal E_{01}^{\mathrm{Ew}}A_\tau
+\mathcal E_{00}^{\mathrm{Ew}}A_\sigma),
\tag{I5.1f-16}
$$

For normal use

$$
\epsilon_{\ell,\mathrm{Ew}}^{\mathrm{nor}}
\le\sqrt P(\mathcal E_{11}^{\mathrm{Ew}}A_\tau
+\mathcal E_{10}^{\mathrm{Ew}}A_\sigma).
\tag{I5.1f-16n}
$$

The source and target strips use
different certified density constants.  On the source strip of width $b$,
put

$$
D_E(b)=\sum_{m\in\mathcal I_\eta}
e^{|m|b}\|\widehat E_m\|_2,
\qquad E\in\{\tau,\zeta\},
\tag{I5.1f-16a}
$$

and certify
$n_{+,b}\ge\sup|n_c(u)|$ and
$s_{+,b}\ge\sup|s_c(u)|$.  At each real target $t_i$, admissible complete
source-integrand bounds are

$$
M_{Q,i}^{\mathrm{src,val}}
:=n_{+,b}K_{Q,01}(0,b)D_\tau(b)
+s_{+,b}K_{Q,00}(0,b)D_\zeta(b),
$$

$$
M_{Q,i}^{\mathrm{src,nor}}
:=n_{+,b}K_{Q,11}(0,b)D_\tau(b)
+s_{+,b}K_{Q,10}(0,b)D_\zeta(b),
\tag{I5.1f-16b}
$$

with any target-dependent refinements kept inside $M_{Q,i}$.  Hence

$$
\epsilon_{\ell,\mathrm{src}}^\chi
\le\frac{h_t}{\sqrt P}\sum_i s(t_i)
\frac{4\pi M_{Q,i}^{\mathrm{src},\chi}}
{e^{bN_s}-1}.
\tag{I5.1f-16c}
$$

On the target strip of width $a_t$, the source remains real and uses the
real $L^1(\mathrm ds)$ bounds $A_\tau,A_\sigma$.  Define

$$
A_Q^{\mathrm{val}}(a_t)
:=K_{Q,01}(a_t,0)A_\tau+K_{Q,00}(a_t,0)A_\sigma,
$$

$$
A_Q^{\mathrm{nor}}(a_t)
:=K_{Q,11}(a_t,0)A_\tau+K_{Q,10}(a_t,0)A_\sigma.
\tag{I5.1f-16d}
$$

With the holomorphic speed and arclength-phase bounds from RNC-5,

$$
\epsilon_{\ell,\mathrm{tgt}}^\chi
\le\frac{4\pi s_{+,a_t}A_Q^\chi(a_t)
e^{|\xi_\ell|\Sigma_{a_t}}}
{\sqrt P(e^{a_tN_t}-1)}.
\tag{I5.1f-16e}
$$

Equations (I5.1f-16b) and (I5.1f-16d) are separate source-strip and
target-strip gates; no target--source product-strip deformation or real-axis
density bound on a source strip is assumed.

The finite node summands include all weights:

$$
W_{\ell,ij}^{\chi}
=s(t_i)e^{-\mathrm i\xi_\ell a(t_i)}
K_Q^{\mathrm{reg},\chi}(t_i,u_j).
\tag{I5.1f-17}
$$

Thus $\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$ must contract the error in
$W_{\ell,ij}^{\chi}$, not only the kernel primitive.  M-T is the first
omitted Taylor order and is present once in (I5.1f-16), not in the centre.
The $|\ell|\ge L$ regular tail uses the full exact positive-strip action
(RNC-9) and is disjoint from (I5.1f-15).

## Off-surface signed centre

The off-surface centre is the exact finite Rayleigh-support action evaluated
at the target nodes and transformed once.  Its retained analytic radius is
only its certified target-trapezoid error:

$$
\delta_\ell^{\mathrm{off},\chi}
=\epsilon_{\ell,\mathrm{tgt}}^{\mathrm{off},\chi}.
\tag{I5.1f-18}
$$

The finite phases, branches, $1/\gamma_m$, geometry contractions, and DFT
sums belong to $\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$.  The complete
frozen finite Rayleigh source support enters the centre; there is no source
quadrature.  The positive-distance $|\ell|\ge L$ target-Fourier tail owns
only omitted target rows and is not added to (I5.1f-18).

## Signed artificial-wall normal and lifting centres

For retained $|m|\le M_w$, use (ZF-19)--(ZF-20) to evaluate signed
curve-to-wall rows $C_{w,m}^{\mathrm{val/nor}}$ by a source trapezoid.  Its
analytic radius is the shape-general strip remainder
$4\pi M_{w,m}^\chi/(e^{a_wN_w}-1)$, with the complete normalized integrand
inside $M_{w,m}^\chi$.  The exact flat rows are

$$
F_{L,m}^{\mathrm{val}}
=\frac{\mathrm i}{2\gamma_m}(\xi_{L,m}+E_m\xi_{R,m}),
\quad
F_{R,m}^{\mathrm{val}}
=\frac{\mathrm i}{2\gamma_m}(E_m\xi_{L,m}+\xi_{R,m}),
$$

$$
F_{L,m}^{\mathrm{nor}}
=\tfrac12(\xi_{L,m}-E_m\xi_{R,m}),
\quad
F_{R,m}^{\mathrm{nor}}
=\tfrac12(-E_m\xi_{L,m}+\xi_{R,m}),
\qquad E_m=e^{\mathrm i\gamma_m(X_R-X_L)}.
\tag{I5.1f-19}
$$

Put $\widetilde Q_w=F_w^{\mathrm{nor}}+\widetilde
C_w^{\mathrm{nor}}$.  The signed internal normal centres are

$$
\widetilde\ell_{+,m}
=\widetilde Q_{R,m}G_++\widetilde Q_{L,m}G_+P_+,
\quad
\widetilde\ell_{-,m}
=\widetilde Q_{L,m}G_-+\widetilde Q_{R,m}G_-P_-.
\tag{I5.1f-20}
$$

The lead normal singletons are
$-d_{L,m}+\widetilde Q_{R,m}G_-c_-$ and
$d_{R,m}+\widetilde Q_{L,m}G_+c_+$, with
$d_L=\mathrm i\gamma_m(q_L-E_mq_R)$ and
$d_R=\mathrm i\gamma_m(E_mq_L-q_R)$.  The two actions meeting one normal
wall are combined before squaring.  Their propagated analytic row radii are
the two source-trapezoid radii composed with the displayed frozen maps.

For lifting define the signed wall value row

$$
\widetilde V_{w,m}(A)
=g_{w,m}A-F_{w,m}^{\mathrm{val}}(A)
-\widetilde C_{w,m}^{\mathrm{val}}(A).
\tag{I5.1f-21}
$$

The central defects are exactly (ZF-27).  In addition, the two lead collars
$\widetilde V_L(G_+c_+)$ and $\widetilde V_R(G_-c_-)$ occur once.  The
remaining four sequences are exactly (ZF-28):

$$
\widetilde V_RG_+P_+^nc_+,
\quad \widetilde V_LG_+P_+^{n+1}c_+,
\quad \widetilde V_LG_-P_-^nc_-,
\quad \widetilde V_RG_-P_-^{n+1}c_-,
\quad n\ge0.
\tag{I5.1f-22}
$$

Equivalently these are all four $\widetilde V_{L/R}G_\pm P_\pm^nc_\pm$
sequences for $n\ge0$, with indexing shifted as above.  The implementation
must choose one representation: central defects plus the two lead
singletons plus (I5.1f-22), or the equivalent all-four form.  It must not
add both.  Each collar is weighted by the wall lifting weight and squared
separately.  All finite wall phases and arithmetic belong to
$\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$; wall source quadrature, retained
row propagation, $|m|\ge M_w+1$ positive-distance tails, and block-power
tails remain explicit.  Use $M_w=256$, retained $|m|\le256$, and omitted
$|m|\ge257$; the frozen half-open $-256{:}255$ flat support has a zero
$m=256$ extension while the curve row at $m=256$ is retained.

No historical `Jplus`, `Jminus`, stored wall residual, or stored centre
mismatch enters a governing centre.

## Cutoff, stopping rule, and phase decision

Selection is analytic and ordered.

1. Before evaluating a signed centre, test
   $L\in\{32,64,128,256,512,1024\}$ in order and select the first for which
   the complete p4-local, regular-image, and off-surface high-mode
   bounds, after the actual trace/lift and frozen state/block factors, meet
   the predeclared high-mode numerator allocation
   $\tau_{\mathrm{high}}=0.1$.
2. Freeze $L$.  Test the smallest even integer strictly above
   $2\max\{L,M_\eta\}$ and then the applicable values in
   $\{1024,2048,4096\}$.  Select the first $N$ such that
   $N>2\max\{L,M_\eta\}$ and the propagated p4 source, p4 target-alias, and
   local series radii meet the predeclared retained local allocation
   $\tau_{\mathrm{local}}=0.1$.  Increasing $N$ never changes $L$.
3. Select the retained Ewald/source/target cutoffs and wall quadrature so
   their propagated analytic radii, together with the fixed
   $|m|\ge M_w+1$ wall high-mode normal and value tails, meet
   $\tau_{\mathrm{reg+wall}}=0.1$.  Every first-omitted ratio, non-Wood,
   branch, clearance, and strip gate must already pass.
4. Use the existing verified block-power constants and increase the cell
   cutoff only if the explicit propagated cell-tail allocation $0.1$ fails.

The allocations are bounds on their contribution to the final numerator,
not sampled row maxima.  If no scheduled value meets an allocation, use the
largest scheduled value that satisfies the strict index gate and resource
budget, persist the finite result, and record a tightness failure; do not use
the failure to tune from observed centre drift.  The preferred plan is at
most 30 minutes and 2.5 GiB.  The scientific hard limits are 45 minutes and
3 GiB.

After one correct phase-1 run, compute the ideal part
$\mathcal M_{\mathrm{ideal}}$ of (I5.1f-5), leave both unresolved terms
symbolic, and apply the predeclared decision:

- if $\mathcal M_{\mathrm{ideal}}<1$, phase 2 may proceed;
- if $1\le\mathcal M_{\mathrm{ideal}}<87.9091$, phase 2 may proceed only if
  the independent Skeptic finds that special-function evaluation, rather
  than any analytic tail, trace/lift constant, propagation bound, or
  remaining zero-centred contribution, is the dominant unresolved
  uncertainty;
- otherwise stop.

## Finite input and theorem-to-code contract

| theorem object | required frozen or certified input | evaluator owner |
|---|---|---|
| local signed centre | `eta_unit_256`, geometry jets, signed $J/Y/\mathfrak c$ series | local Kress adapter |
| tight density derivatives | exact finite-DFT row $2$-norm sums (I5.1f-8a); optional independent (ZF-35)--(ZF-41) upper | v5 density adapter |
| local source/target/series radii | $S_{j,4}$, $Q_4$, first-omitted series ratios, $L,N$ | local radius builder |
| regular value/normal centres | retained reciprocal/image/Taylor/local-canonical Ewald terms | signed Ewald evaluator |
| regular analytic radii | M-R/M-I/M-T/M-L, source strip, target strip | Ewald certificate builder |
| off-surface centre/radius | complete frozen Rayleigh support and target strip | off-surface evaluator |
| wall normal/value centres | frozen $\xi_{L/R}$, $q^{\rm cen}$, $D_\pm,G_\pm,P_\pm,c_\pm$, general curve row | new signed wall helper |
| trace/lift | explicit $b_\ell$, $e_{\ell,\mathrm{val}}$, wall weights | existing weight certificates |
| cell tails | verified block powers for $P_\pm$ | existing block certificate |
| unresolved finite evaluation | full node summands, not bare special functions | $\Delta_{\mathrm{sf}}$, $\Delta_{\mathrm{fp}}$ records |

The builder reuses the proved v4 p4 formulas but reconstructs their constants
from the current explicit frozen input using (I5.1f-8a).  It must rebuild
every centre and all affected finite/low-cell sums in the same v5 input.  It
must not import a v2 lifting tail, v3 normal-only result, v4
zero-centre retained radius, or a historical wall residual as a governing
quantity.  All forbidden solve counts are zero.

## Fail-closed gates and current status

Required gates are: frozen schema and direct frozen-field contracts, with no
runtime Git/hash dependency; density sign; one local identity;
exterior-minus-interior local signs and cancellation of the common
cotangent/hypersingular principal part before absolute values; exact
half-open density and Rayleigh supports; p4 derivative and first-omitted
ratio certificates; strict $N>2\max\{L,M_\eta\}$; outgoing non-Wood branches
and every $1/\gamma_m$ lower bound; separate valid source and target strips;
nonvanishing holomorphic speed branch with correct real normal; M-R/M-I/M-T/
M-L ownership once; off-surface target ownership once; physical regular/off
normal minus signs; trace division only for normal and lift multiplication
only for value; complete wall singleton/collar indexing; block-power
contraction; finite nonnegative radii; zero forbidden solves; and exclusion
of sampled maxima, inter-level drift, Richardson extrapolation, and empirical
safety factors.

The independent pre-code review returned `PASS WITH CONDITIONS`: the
implementation must keep distinct source- and target-strip gates, must not use
a whole-action coefficient upper as a radius about a nonzero retained centre,
and must persist enough ownership data for the post-run special-function
dominance decision.  The present instance remains `CONDITIONAL`: (I5.1f-1) is
not supplied by ordinary MATLAB special-function or arithmetic calls.  Phase 1
may quantify the ideal signed-centre potential, but cannot restore a reliable
numerator claim.

## Phase 2: finite special-function sensitivity

### Run-02 gate and scope

The independently reviewed phase-1 run selected $L=512$ and $N=2048$ and
returned

$$
\mathcal M_{\mathrm{ideal}}
=0.056448305344888337<1.
\tag{I5.1f-23}
$$

This opens phase 2 but does not resolve either term in (I5.1f-1).  The present
bounded phase-2 calculation first isolates the two non-elementary primitive
families that occur only in the retained regular-image centre:
`Faddeeva_erfc` and `expint`.  Let $\mathcal M_{\mathrm{mix}}$ denote the
complete scalar expression in which these two families have their exact
mathematical values while every other primitive is held at its library return
value.  More precisely, each exact Faddeeva or $E_1$ value is evaluated at the
same fixed library argument supplied to that call in run 02, and the remaining
algebra is exact.  Hence all upstream argument perturbations and all changes in
the other coefficient factors belong to the first telescope term below, while
the second term changes only the two primitive returns at fixed arguments.
Then

$$
\begin{split}
|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{lib}}|
&\le
|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{mix}}|
+|\mathcal M_{\mathrm{mix}}-\mathcal M_{\mathrm{lib}}|,\\
\Delta_{\mathrm{sf,rest}}
&:=|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{mix}}|.
\end{split}
\tag{I5.1f-24}
$$

Here $\Delta_{\mathrm{sf,rest}}$ remains `UNRESOLVED`; it is not moved into
$\Delta_{\mathrm{fp}}$.  It owns all elementary transcendental calls,
principal square roots, constants, geometry and weight primitives, and every
analytic-certificate primitive not owned by the two families above.

### Faddeeva retained-reciprocal gain

Fix all other primitive outputs.  For a retained reciprocal order put

$$
q=(\beta_m^2-\widehat k^2)^{1/2},\qquad
\Phi=\frac{e^{\mathrm i\beta_mY}}{4d q},\qquad
a_\epsilon=\frac q{2h}+\epsilon hX,\qquad
E_\epsilon=e^{\epsilon qX},
\quad \epsilon\in\{-1,1\}.
\tag{I5.1f-25}
$$

Assume the uniform absolute oracle contract

$$
|\operatorname{erfc}(a)-\operatorname{erfc}_{\mathrm{lib}}(a)|
\le\varepsilon_F
\tag{I5.1f-26}
$$

on the complete retained argument set.  Run 02 observed that set inside
$-0.8\le\Re a\le7.1917836710782446$ and
$-0.44081224267237612\le\Im a\le0$, but those ordinary extrema are provenance,
not certified domain bounds.  A strict use of (I5.1f-26) must cover each actual
argument, or an outward superset, directly.

All quantities other than `Faddeeva_erfc` in (I5.1f-25) are the fixed library
values of the mixed telescope.  For this owner only, errors in the six
coordinate derivatives of one retained reciprocal term are bounded by
$U_{pq}^F\varepsilon_F$, where

$$
\begin{aligned}
U_{00}^F&=|\Phi|\sum_{\epsilon=\pm1}|E_\epsilon|,&
U_{10}^F&=|q|U_{00}^F,&
U_{01}^F&=|\beta_m|U_{00}^F,\\
U_{20}^F&=|q|^2U_{00}^F,&
U_{11}^F&=|\beta_m|U_{10}^F,&
U_{02}^F&=|\beta_m|^2U_{00}^F.
\end{aligned}
\tag{I5.1f-27}
$$

The formulas follow by taking the coefficient of
$\operatorname{erfc}(a_\epsilon)$ in the exact retained expressions for
$F_0,F_1,F_2$.  Calls evaluating
$\operatorname{erfc}'$ and $\operatorname{erfc}''$ use exponentials in the
current source and therefore belong to $\Delta_{\mathrm{sf,rest}}$, not to
(I5.1f-27).  Sum (I5.1f-27) over all retained reciprocal orders before normal
contraction.

### Exponential-integral retained-image gain

For one retained nonzero image, let $z>0$ denote its real Ewald argument and
let $a_r=\chi_E^r/r!$.  Set $E^{(0)}=E_1(z)$ and use the exact code recurrence

$$
E^{(r+1)}=\frac{e^{-z}-zE^{(r)}}{r+1}.
\tag{I5.1f-28}
$$

If a fail-closed gate verifies that every fixed library argument lies in the
certified geometry-box range $1.44\le z\le23.68$ and

$$
|E_1(z)-E_{1,\mathrm{lib}}(z)|\le\varepsilon_E,
\qquad 1.44\le z\le23.68,
\tag{I5.1f-29}
$$

then the gain in $E^{(r)}$ is
$g_r=|z|^r/r!$.  With the actual retained order $Q$, define

$$
G_0=\sum_{r=0}^{Q}|a_r|g_r,\qquad
G_1=\sum_{r=1}^{Q}|a_r|g_{r-1},\qquad
G_2=\sum_{r=2}^{Q}|a_r|g_{r-2}.
\tag{I5.1f-30}
$$

These lower limits are forced by the shifts in the implementation: the
initial elementary $e^{-z}/z$ and $e^{-z}(z^{-1}+z^{-2})$ contain no `expint`
error.  With $z_x=2h^2X$, $z_y=2h^2Y_n$, one image contributes

$$
\begin{aligned}
U_{00}^E&=G_0,&
U_{10}^E&=|z_x|G_1,&
U_{01}^E&=|z_y|G_1,\\
U_{20}^E&=|z_x|^2G_2+2h^2G_1,&
U_{11}^E&=|z_xz_y|G_2,&
U_{02}^E&=|z_y|^2G_2+2h^2G_1.
\end{aligned}
\tag{I5.1f-31}
$$

In the mixed telescope the image phase is the fixed library value
$\Phi_n^{\mathrm{img}}
=\exp_{\mathrm{lib}}(\mathrm i\beta nd)/(4\pi_{\mathrm{lib}})$.
Accordingly every right-hand side in (I5.1f-31) is multiplied by
$|\Phi_n^{\mathrm{img}}|$; it must not be replaced by $1/(4\pi)$ using exact
unit modulus.  Sum (I5.1f-31) over every retained nonzero image.  The
ordinary run-02 argument range $[1.44,23.04]$ is only a diagnostic; the larger
interval in (I5.1f-29) follows from the certified component geometry box and
is the required oracle domain.  The `expint` family makes no independent call
inside M-R/M-I/M-T/M-L or the source, target, Fourier, trace, lifting, and
cell-tail certificates.  Its retained-centre error nevertheless propagates
through every explicit finite and split cell state below.

### Coordinate-to-row contraction

For $c\in\{F,E\}$, let $U_{pq,ij}^c$ be the sums above at real target $t_i$
and source $u_j$.  With row-vector density values $\tau_j,\zeta_j$, unit
normals $\nu_i,\nu_j$, and source speed $s_j$, put

$$
\begin{split}
Z_{ij,c}^{\mathrm{val}}=s_j\big[&
(|\nu_{j,1}|U_{10,ij}^c+|\nu_{j,2}|U_{01,ij}^c)
\|\tau_j\|_2+U_{00,ij}^c\|\zeta_j\|_2\big],
\end{split}
\tag{I5.1f-32}
$$

$$
\begin{split}
Z_{ij,c}^{\mathrm{nor}}=s_j\big[&
(|\nu_{i,1}\nu_{j,1}|U_{20,ij}^c
+(|\nu_{i,1}\nu_{j,2}|+|\nu_{i,2}\nu_{j,1}|)U_{11,ij}^c
+|\nu_{i,2}\nu_{j,2}|U_{02,ij}^c)\|\tau_j\|_2\\
&+(|\nu_{i,1}|U_{10,ij}^c+|\nu_{i,2}|U_{01,ij}^c)
\|\zeta_j\|_2\big].
\end{split}
\tag{I5.1f-33}
$$

Let
$p_{\ell i}^{\mathrm{tgt}}
=|\exp_{\mathrm{lib}}(-\mathrm i\xi_\ell a(t_i))|$.
For the fixed-library source and target steps $h_s,h_t$, the normalized
retained row gain is

$$
d_c^\chi=\max_{|\ell|<L}
\frac{h_t}{\sqrt {P_{\mathrm{lib}}}}
\sum_i p_{\ell i}^{\mathrm{tgt}}s_i h_s\sum_j Z_{ij,c}^\chi.
\tag{I5.1f-34}
$$

The displayed phase magnitude is retained because a library phase is not
silently replaced by an exact unit-modulus value.  All speeds, normals,
density values, steps, and normalizations in (I5.1f-32)--(I5.1f-34) are also
the fixed library values of the mixed telescope.  The formulas use absolute
summand errors and therefore require no relative accuracy in the highly
cancelled signed row.

Let $J$ be the already accepted split-cell cutoff and put

$$
S_J=\|q_0\|_2^2
+\sum_{\varsigma\in\{-,+\}}
\left[
\sum_{n=0}^{J-1}\|G_\varsigma P_\varsigma^n c_\varsigma\|_2^2
+C_\varsigma\|G_\varsigma\|_F^2
\|P_\varsigma^Jc_\varsigma\|_2^2
\right],
\tag{I5.1f-35}
$$

where $C_\pm$ are the existing block-power upper bounds for
$\sum_{n\ge0}\|P_\pm^n\|_F^2$.  Thus $S_J$ follows the same explicit
$n<J$ states and the same $n\ge J$ block-power envelope as the computed
finite-plus-cell majorant; it is not replaced by a whole-sequence physical
state bound.  With
$w_\ell^{\mathrm{nor}}=b_\ell^{-1}$ and
$w_\ell^{\mathrm{val}}=e_{\ell,\mathrm{val}}$, define the finite gains

$$
A_c=d_c^{\mathrm{nor}}
\sqrt{S_J\sum_{|\ell|<L}w_\ell^{\mathrm{nor}}}
+2d_c^{\mathrm{val}}
\sqrt{S_J\sum_{|\ell|<L}w_\ell^{\mathrm{val}}},
\qquad c\in\{F,E\}.
\tag{I5.1f-36}
$$

Indeed, (I5.1f-34) bounds the operator row error.  Apply it to the centre
state and to every explicit $G_\pm P_\pm^nc_\pm$ with $n<J$, then use the same
Frobenius and block-power tail bound appearing in (I5.1f-35).  Parseval in the
retained trace/lift weights and
Minkowski give (I5.1f-36).  These two families do not occur in the wall module
or in any high-mode tail.  The global factor two in the value term is the
single lifting factor.  Thus

$$
|\mathcal M_{\mathrm{mix}}-\mathcal M_{\mathrm{lib}}|
\le A_F\varepsilon_F+A_E\varepsilon_E,
$$

$$
\boxed{
|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{lib}}|
\le A_F\varepsilon_F+A_E\varepsilon_E
+\Delta_{\mathrm{sf,rest}}.}
\tag{I5.1f-37}
$$

Consequently one may take the right-hand side of (I5.1f-37) as
$\Delta_{\mathrm{sf}}$ in (I5.1f-1).

If an external oracle instead states exact-relative error contracts, no lower
bound on the two special functions is needed.  For
$a_F=x+\mathrm i y$ with $|y|\le b$, the vertical-path identity

$$
\operatorname{erfc}(x+\mathrm i y)
=\operatorname{erfc}(x)-\frac{2\mathrm i}{\sqrt\pi}
\int_0^y e^{-(x+\mathrm i t)^2}\,dt
$$

and $0<\operatorname{erfc}(x)<2$ on the real axis give

$$
|\operatorname{erfc}(a_F)|
\le U_F:=2+\frac{2b}{\sqrt\pi}e^{b^2}.
\tag{I5.1f-37a}
$$

For real $x\ge a>0$, the integral definition gives

$$
0<E_1(x)\le\frac{e^{-x}}x\le U_E:=\frac{e^{-a}}a.
\tag{I5.1f-37b}
$$

Thus the exact-relative contracts
$|\delta\operatorname{erfc}|\le\eta_F|\operatorname{erfc}|$ and
$|\delta E_1|\le\eta_E|E_1|$ imply (I5.1f-26) and (I5.1f-29) with
$\varepsilon_F=\eta_FU_F$ and $\varepsilon_E=\eta_EU_E$.  Here one may take
$b=0.44081224267237612$ only after the full fixed argument set has passed the
stated box gate, and $a=1.44$ after the corresponding positive-real gate.
The relative denominator in this corollary is the exact function magnitude.
A strict numerical use also requires a reliable upper enclosure of the
elementary expressions $U_F,U_E$; an ordinary floating-point evaluation of
them remains part of the partial ideal sensitivity bookkeeping.

The finite values of $A_F,A_E$ computed in ordinary arithmetic are labelled
`PARTIAL_IDEAL_SENSITIVITY`; their own arithmetic error remains in
$\Delta_{\mathrm{fp}}$.  They become rigorous numerical gains only after a
reliable enclosure of their finite sums.

### Complete remaining-primitive contract

For completeness, the shortest correct continuation does not multiply a
nominal weight by an independently obtained row error.  Let $p$ collect all
remaining primitive values.  For every material finite state $s$ define the
complete feature

$$
F_{s,\ell}^\chi(p)
=\sqrt{w_\ell^\chi(p)}
\big(|j_\ell^\chi(p)s|+r_\ell^\chi(p)\|s\|_2\big).
\tag{I5.1f-38}
$$

For the cell tail define

$$
F_{\varsigma,\ell}^\chi(p)
=\sqrt{w_\ell^\chi(p)C_\varsigma(p)}
\big(\|j_\ell^\chi(p)G_\varsigma(p)\|_2
+r_\ell^\chi(p)\|G_\varsigma(p)\|_F\big)
\|P_\varsigma^J(p)c_\varsigma(p)\|_2.
\tag{I5.1f-39}
$$

Use the analogous complete features for each stored wall label.  High-mode
features are their direct unsquared amplitude formulas, including the exact
trace/lift weights; an underflowed displayed radius is never an exact zero.
The material-normal, wall-normal, and concatenated material/wall value module
bounds are Euclidean norms of these feature vectors.

Partition every remaining primitive occurrence by function and call-site
region.  On predeclared error caps, a complete segment-hull ball replay must
prove

$$
|F_\alpha(p_{\mathrm{an}})-F_\alpha(p_{\mathrm{lib}})|
\le\sum_c R_{\alpha,c}\varepsilon_c.
\tag{I5.1f-40}
$$

All factors in (I5.1f-38)--(I5.1f-39), including weight and radius changes,
belong inside this replay.  Multiplication uses magnitude bounds on the whole
hybrid segment; reciprocal, square root, and logarithm steps require positive
denominator and branch-margin gates.  Absolute values and Euclidean norms use
their one-Lipschitz property.  Fix one independently valid p4 target/high
formula rather than differentiating the numerical `min` or the $L,N$
selection.

If $R_{\mathrm{mat,nor},c}$, $R_{\mathrm{wall,nor},c}$ and the two value
arrays denote the feature gains, Minkowski gives

$$
A_c^{\mathrm{full}}
=\|R_{\mathrm{mat,nor},c}\|_2
+\|R_{\mathrm{wall,nor},c}\|_2
+2\left\|
\begin{bmatrix}
R_{\mathrm{mat,val},c}\\R_{\mathrm{wall,val},c}
\end{bmatrix}\right\|_2.
\tag{I5.1f-41}
$$

This is the complete shape-general final-functional sensitivity contract.  It
does not linearize the final square root and includes all cross-effects through
the segment hull.

The actual remaining classes include principal `sqrt`; context-tagged `exp`
for unit phases, decay, growth, and complex Ewald factors; `log`, `log1p`,
`sin`, `cos`, `sinh`, `cosh`, and `tanh`; and the mathematical constants
$\pi$ and $\gamma_E$.  The instrumented regular helper used `gammaln` on the
integers $1{:}20$ followed by `exp`; the static whole-source audit also finds
the local helper's `gammaln` integer arguments through $34$.  Those calls
remain distinct owners.  Replacing them by a
factorial recurrence would require a new source evaluation and cannot be done
post hoc to the run-02 graph.  The run-02 ledger records, for example,
75,497,472 Faddeeva arguments and 16,777,216 `expint` arguments, while its
elementary-call inventory is explicitly incomplete.  Observed argument extrema
are not certified hulls.

Consequently (I5.1f-37) is a proved partial decomposition, but a numerical
value for the complete $\Delta_{\mathrm{sf}}$ remains blocked by the missing
tagged elementary inventory, segment hulls, and reliable finite gain sums.
No part of that gap may be assigned to $\Delta_{\mathrm{fp}}$.

### Budget and fail-closed gates

Set $\tau_{\mathrm{sf}}=0.005$ and reserve nonnegative allocations
$\tau_F+\tau_E+\tau_{\mathrm{rest}}=0.005$.  A sufficient stopping rule is

$$
A_F\varepsilon_F\le\tau_F,\qquad
A_E\varepsilon_E\le\tau_E,\qquad
\Delta_{\mathrm{sf,rest}}\le\tau_{\mathrm{rest}}.
\tag{I5.1f-42}
$$

One explicit initial allocation is
$\tau_F=\tau_E=0.00125$ and $\tau_{\mathrm{rest}}=0.0025$; if $A_c>0$ the
corresponding oracle requirement is $\varepsilon_c\le\tau_c/A_c$.  This is an
absolute action requirement and is unrelated to the relative size of the
cancelled centre.

Required gates are: fixed run-02 cutoffs and a fixed valid p4 alternative;
complete Faddeeva and `expint` argument coverage; outgoing non-Wood square-root
branches held fixed in the hybrid; first-omitted analytic tails unchanged;
finite nonnegative $U,Z,d,A$; density, Jacobian, source normal, target normal,
target phase, and $P^{-1/2}$ each included once; block-power bounds from the
accepted run; no Faddeeva/`expint` ownership in analytic radii or high tails;
and explicit persistence of $\Delta_{\mathrm{sf,rest}}=
\texttt{UNRESOLVED}$.  No sampled maximum or inter-level drift may be used as
an argument-domain enclosure.

If all three tests in (I5.1f-42) were eventually closed, then

$$
\|R\|_{\mu,*}
\le0.061448305344888337+\Delta_{\mathrm{fp}}.
\tag{I5.1f-43}
$$

In particular, a numerical upper below one would still require
$\Delta_{\mathrm{fp}}<0.9385516946551117$.  At the present stage
$\Delta_{\mathrm{sf,rest}}$ and $\Delta_{\mathrm{fp}}$ are unresolved, so
(I5.1f-43) is a target implication, not a delivered reliable bound.

### Restricted phase-2 run result

The fixed run-02 sensitivity replay completed with all restricted gates true
and returned

$$
S_J=2.9050958701919547,\qquad
A_F=3.0944383348174293\mathbin{\times}10^7,\qquad
A_E=2.4261737348658184\mathbin{\times}10^5.
\tag{I5.1f-44}
$$

Consequently the two allocations $\tau_F=\tau_E=0.00125$ require

$$
\begin{array}{c|cc}
 &\text{uniform absolute error}&\text{uniform exact-relative error}\\ \hline
\operatorname{erfc}&4.0395052825434619\mathbin{\times}10^{-11}
&1.5512180321649638\mathbin{\times}10^{-11}\\
E_1&5.1521454627779673\mathbin{\times}10^{-9}
&3.1313719876758819\mathbin{\times}10^{-8}.
\end{array}
\tag{I5.1f-45}
$$

The ordinary evaluations of (I5.1f-37a)--(I5.1f-37b) used
$U_F=2.6040860786705204$ and $U_E=0.16453316575147345$.  The complete fixed
argument ledgers matched the phase-1 counts: 75,497,472 Faddeeva arguments in

$$
-0.8\le\Re a\le7.1917836710782446,\qquad
-0.44081224267237612\le\Im a\le0,
$$

and 16,777,216 positive-real $E_1$ arguments in $[1.44,23.04]$, itself inside
the predeclared $[1.44,23.68]$ box.  The sensitivity run took 18.04 seconds
wall time and 983,793,664 bytes maximum resident memory.  It performed no
eigenpair, density, QZ, or propagation solve.

These required relative accuracies are not smaller than $10^{-16}$ and hence
do not, by themselves, indicate a precision obstruction.  This is only a
feasibility observation: no verified error contract for the actual MATLAB
returns was supplied, and the gains and $U_F,U_E$ were themselves evaluated in
ordinary arithmetic.  If the two oracle contracts and their reliable finite
gain enclosures were supplied, (I5.1f-37) would give only

$$
\|R\|_{\mu,*}
\le0.058948305344888340
+\Delta_{\mathrm{sf,rest}}+\Delta_{\mathrm{fp}}.
\tag{I5.1f-46}
$$

Thus the run is `PARTIAL_FADDEEVA_E1_SENSITIVITY_ONLY`, not a reliable
numerator certificate.  The first remaining theorem-to-code obligation is a
complete tagged occurrence inventory and segment-hull replay for
(I5.1f-38)--(I5.1f-41).  A shortcut that assigns at most three log-gamma
errors to every factorial coefficient is insufficient: the local
`j_shift` derivative certificate contains

$$
\log\Gamma(m+1)-\log\Gamma(m-r+1)-2\log\Gamma(m+2),
$$

whose coefficientwise absolute log-gamma-error weight is four, and its following
exponential is a separate primitive occurrence.  Moreover `gammaln` occurs in
the local derivative/tail certificates, the regular local-canonical centre,
the regular analytic finite/tail certificates, and the retained-image Taylor
tail.  Those paths change source, target, high-mode, and selected-radius
features.  Bounding only the signed canonical centre therefore cannot bound
the gamma-family contribution to $\Delta_{\mathrm{sf,rest}}$; the first
missing inequality is a segment-hull enclosure of every resulting complete
feature, including denominator and selection gates.  No post-hoc replacement
by exact factorials represents the run-02 computational graph.

### Narrow local log-gamma--exponential certificate sublemma

One strictly narrower part of $\Delta_{\mathrm{sf,rest}}$ can be separated
without claiming a complete gamma- or exponential-family replay.  Starting
from $\mathcal M_{\mathrm{mix}}$, define
$\mathcal M_{\mathrm{mix}}^{\Gamma,\mathrm{loc}}$ by changing only the
integer `gammaln` calls inside the local `LOCAL_entire_series` certificate and
the immediately following real exponential that converts each coefficient
logarithm to a positive term.  Faddeeva and $E_1$ remain exact at their fixed
library arguments, and every other primitive, ratio, geometry quantity,
density value, and signed local centre remains fixed at its run-02 library
value.

Assume, for every actually used integer $n\in\{1,\ldots,34\}$ and every
immediately following coefficient-log argument $x$, that

$$
|\operatorname{gammaln}_{\mathrm{lib}}(n)-\log\Gamma(n)|
\le\varepsilon_\Gamma,
\qquad
|\exp_{\mathrm{lib}}(x)-e^x|\le\eta_e e^x,
\qquad
\varepsilon_\Gamma\ge0,\qquad 0\le\eta_e<1.
\tag{I5.1f-47}
$$

Every log-gamma combination in `LOCAL_entire_series` has coefficientwise
absolute weight at most four, with equality possible for `j_shift`.  Hence,
for an exact positive term $t$ and its stored library term $\widetilde t$,

$$
\frac{e^{-4\varepsilon_\Gamma}}{1+\eta_e}\,\widetilde t
\le t\le
\frac{e^{4\varepsilon_\Gamma}}{1-\eta_e}\,\widetilde t.
\tag{I5.1f-48}
$$

Indeed the log arguments differ by at most $4\varepsilon_\Gamma$, while
(I5.1f-47) sandwiches the library exponential between
$(1-\eta_e)e^x$ and $(1+\eta_e)e^x$.  Put

$$
u_{\Gamma e}:=\frac{e^{4\varepsilon_\Gamma}}{1-\eta_e},
\qquad
c_{\Gamma e}:=u_{\Gamma e}-1.
\tag{I5.1f-49}
$$

The lower factor in (I5.1f-48) and the inequality
$c_{\Gamma e}\ge1-e^{-4\varepsilon_\Gamma}/(1+\eta_e)$ show that the
absolute change of each positive term is at most
$c_{\Gamma e}\widetilde t$.  The first-omitted ratios are gamma-free and are
held fixed here.  Retained positive sums, their ratio tails, the $J/Y$ and
$\mathfrak c$ bounds, the geometry composition, the density contractions,
and the Kress source and series radii are positive linear maps of these
bounds.  Fixed positive identity and retained-coefficient addends preserve
the common bilateral factors in (I5.1f-48).  Thus each stored local source,
target, and series radius has absolute change at most
$c_{\Gamma e}$ times that radius.  Both p2 and p4 target alternatives obey
the same bilateral enclosure, so their minimum does also; no derivative of
the numerical `min` is used.  The same argument applied before squaring gives
the common factor for each p2/p4 high-mode amplitude and hence for their
selected minimum.

Let $r_{\ell,\mathrm{loc}}^\chi$ be the complete stored local
source-plus-target-plus-series radius, and let
$h_{\mathrm{loc},\chi}^2$ be the stored selected local high-tail square, for
$\chi\in\{\mathrm{nor},\mathrm{val}\}$.  Besides the matched $S_J$ in
(I5.1f-35), define the whole-state high-mode factor

$$
S_\infty=\|q_0\|_2^2
+\sum_{\varsigma\in\{-,+\}}
C_\varsigma\|G_\varsigma\|_F^2\|c_\varsigma\|_2^2
\tag{I5.1f-50}
$$

and

$$
D_\chi^2
=S_J\sum_{|\ell|<L}w_\ell^\chi
\big(r_{\ell,\mathrm{loc}}^\chi\big)^2
+S_\infty h_{\mathrm{loc},\chi}^2,
\qquad
D_{\mathrm{loc}}=D_{\mathrm{nor}}+2D_{\mathrm{val}}.
\tag{I5.1f-51}
$$

The first term uses exactly the explicit $n<J$ states and split cell tail;
the second uses the builder's whole-state factor for the local omitted modes.
Minkowski applied to those complete feature vectors gives

$$
|\mathcal M_{\mathrm{mix}}^{\Gamma,\mathrm{loc}}
-\mathcal M_{\mathrm{mix}}|
\le c_{\Gamma e}D_{\mathrm{loc}}.
\tag{I5.1f-52}
$$

With
$\Delta_{\mathrm{sf,rest2}}
:=|\mathcal M_{\mathrm{an}}
-\mathcal M_{\mathrm{mix}}^{\Gamma,\mathrm{loc}}|$, the refined partial
telescope is therefore

$$
|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{lib}}|
\le A_F\varepsilon_F+A_E\varepsilon_E
+c_{\Gamma e}D_{\mathrm{loc}}
+\Delta_{\mathrm{sf,rest2}}.
\tag{I5.1f-53}
$$

This is not a full gamma shortcut.  In particular, regular-image `gammaln`,
all other exponential calls, local logarithms and constants, geometry,
ratios, and weights have unresolved primitive-evaluation effects in
$\Delta_{\mathrm{sf,rest2}}=\texttt{UNRESOLVED}$.  Arithmetic effects in
those quantities remain separately in $\Delta_{\mathrm{fp}}$.

To retain the original $0.0025$ remaining-family allocation, assign $0.00125$
to (I5.1f-52) and $0.00125$ to
$\Delta_{\mathrm{sf,rest2}}$.  For an ordinary computed
$D_{\mathrm{loc}}>0$, the predeclared sufficient caps are

$$
g=\log\!\left(1+\frac{0.00125}{D_{\mathrm{loc}}}\right),
\qquad
\varepsilon_\Gamma=\frac g8,
\qquad
\eta_e=1-e^{-g/2}.
\tag{I5.1f-54}
$$

Then $c_{\Gamma e}=e^g-1$ and
$c_{\Gamma e}D_{\mathrm{loc}}=0.00125$.  A strict use requires reliable
enclosures of $D_{\mathrm{loc}}$ and the elementary expressions in
(I5.1f-49), (I5.1f-54), plus fail-closed verification of the fixed run-02
graph, the integer argument set, positive nonunderflowing exponential returns,
and the bilateral common factor for both p2/p4 alternatives.  Ordinary values
are again only partial ideal sensitivities.

The analogous narrow shortcut does not presently cover the regular-image
log-gamma occurrences.  Although their signed local-canonical centre admits a
real-node positive coefficient triangle with log-gamma weight at most three
and at most two immediate factorial exponentials, the gamma-dependent
$K_Q$ then enters source and target analytic radii through downstream nodes of
the form

$$
\exp_{\mathrm{lib}}\!\left(
\max\{\log_{\mathrm{lib}}(\mathrm{realmin}),
\log_{\mathrm{lib}}(A_\Gamma)-\log_{\mathrm{lib}}(D)\}\right).
$$

Holding these later logarithm and exponential returns fixed stops propagation
of the gamma perturbation, while replacing the expression by $A_\Gamma/D$
does not represent the run-02 library graph.  The first missing inequality is
therefore a segment-hull enclosure for these downstream call nodes.  Until it
is supplied, all regular-image log-gamma effects stay in
$\Delta_{\mathrm{sf,rest2}}$.

The canonical local log-gamma sensitivity run was performed only after the
preceding sublemma and helper passed independent pre-run review.  It gave

$$
\begin{aligned}
S_J&=2.9050958701919547,&
S_\infty&=9490.9211697448736,\\
D_{\mathrm{val}}&=0.028219316657757031,&
D_{\mathrm{nor}}&=9.6715969644649731\times10^{-6},\\
D_{\mathrm{loc}}&=0.056448304912478528.
\end{aligned}
\tag{I5.1f-55}
$$

For the prospective allocation $0.00125$, (I5.1f-54) gives

$$
\varepsilon_\Gamma=0.002737816682536592,
\qquad
\eta_e=0.010891519908669904,
\qquad
c_{\Gamma e}D_{\mathrm{loc}}=0.0012499999999999983.
\tag{I5.1f-56}
$$

All declared gates passed.  The run used 14.52 seconds and a peak resident
set of 779403264 bytes, made no solve, and wrote
`local-certificate-sensitivity-run-01.mat` in the existing attempt.  These
ordinary values have status `PARTIAL_LOCAL_LOGGAMMA_EXP_SENSITIVITY`: they are
not enclosures of the displayed constants, do not show that a library meets
the contracts, and leave $\Delta_{\mathrm{sf,rest2}}$, the full
$\Delta_{\mathrm{sf}}$, and $\Delta_{\mathrm{fp}}$ unresolved.  Independent
post-run review reproduced (I5.1f-55)--(I5.1f-56) and passed only this declared
partial conclusion.

### Repaired narrow regular-image log-gamma composite certificate

The obstruction above can be removed for a named finite subgraph by including
the downstream logarithm and exponential in the same primitive family.  This
does not close the remaining special-function graph.  Starting after the
Faddeeva/$E_1$ and local subgraphs, define a further mixed functional by
replacing only these regular-image calls by exact counterparts:

1. integer `gammaln` calls used by the retained branch-free canonical series,
   `LOCAL_local_ewald_bound`, and retained-image Taylor tail;
2. immediately following exponentials that realize positive factorial
   coefficients; and
3. the gamma-dependent source/target logarithm and final outer exponential in
   each retained analytic radius.

All other primitive returns, arguments, geometry data, densities, phases,
weights, and algebra are held at fixed run-02 library data.  Assume on the
complete named call sets

$$
\begin{aligned}
|\operatorname{gammaln}_{\mathrm{lib}}(n)-\log\Gamma(n)|
&\le\varepsilon_{\Gamma,r},\\
|\exp_{\mathrm{lib}}(x)-e^x|&\le\eta_i e^x
&&\text{for immediate factorial exponentials},\\
|\log_{\mathrm{lib}}(y)-\log y|&\le\varepsilon_{\log}
&&\text{for affected positive actions},\\
|\exp_{\mathrm{lib}}(x)-e^x|&\le\eta_o e^x
&&\text{for their outer exponentials},
\end{aligned}
\tag{I5.1f-57}
$$

where all errors are nonnegative and $0\le\eta_i,\eta_o<1$.  A regular
factorial monomial has log-gamma coefficient weight at most three and at most
two immediate factorial exponentials.  Its exact/library positive ratio is
therefore in $[l_0,u_0]$, where

$$
u_0=\frac{e^{3\varepsilon_{\Gamma,r}}}{(1-\eta_i)^2},
\qquad
l_0=e^{-3\varepsilon_{\Gamma,r}}(1-\eta_i)^2=u_0^{-1},
\qquad c_0=u_0-1.
\tag{I5.1f-58}
$$

The reciprocal lower factor is essential: replacing $(1-\eta_i)^2$ by
$(1+\eta_i)^{-2}$ fails for a convolution of two coefficients containing
reciprocal exponential returns.  Positive sums, ratio tails, contractions,
and fixed positive addends preserve this bilateral enclosure.  Since
$\max\{\log(\mathrm{realmin}),\cdot\}$ is one-Lipschitz, the complete
retained source/target radius ratio lies in $[l_R,u_R]$, with

$$
u_R=\frac{u_0e^{\varepsilon_{\log}}}{1-\eta_o},
\qquad
l_R=l_0e^{-\varepsilon_{\log}}(1-\eta_o)=u_R^{-1},
\qquad c_R=u_R-1.
\tag{I5.1f-59}
$$

The signed canonical centre must be controlled without using cancellation.
Let $J_k,S_k,D_k,Q_k$ be the stored library coefficients in
`LOCAL_C_chi_finite`, and let $c_\chi$ be its stored logarithmic constant.
Define

$$
P_k^\#=\frac{
\sum_{a+b=k}|J_aS_b|+|c_\chi J_k|+2|D_k|}{4|\pi_{\mathrm{lib}}|},
\qquad Q_k^\#=|Q_k|.
\tag{I5.1f-60}
$$

For $r=0,1,2$, $R_0=h^2(R_X^2+R_Y^2)$, and falling factorial $(k)_r$, put

$$
P_r^\#(R_0)=\sum_{k\ge r}(k)_rP_k^\#R_0^{k-r},
\qquad
Q_r^\#(R_0)=\sum_{k\ge r}(k)_rQ_k^\#R_0^{k-r}.
\tag{I5.1f-61}
$$

Let $E^\#$ be the maximum, over the complete actual real-node canonical call
set, of the fixed library magnitude
$|\exp_{\mathrm{lib}}(-\zeta_{ij})/(4\pi_{\mathrm{lib}})|$.  This is a finite
call-set maximum, not an unproved continuum or unit-phase bound.  Set

$$
\begin{aligned}
B_0&=P_0^\#+E^\#Q_0^\#,\\
B_1&=P_1^\#+E^\#(Q_1^\#+Q_0^\#),\\
B_2&=P_2^\#+E^\#(Q_2^\#+2Q_1^\#+Q_0^\#).
\end{aligned}
\tag{I5.1f-62}
$$

With $z_x=2h^2R_X$ and $z_y=2h^2R_Y$, define

$$
\begin{gathered}
b_{00}=B_0,\quad b_{10}=z_xB_1,\quad b_{01}=z_yB_1,\\
b_{20}=z_x^2B_2+2h^2B_1,\quad
b_{11}=z_xz_yB_2,\quad
b_{02}=z_y^2B_2+2h^2B_1.
\end{gathered}
\tag{I5.1f-63}
$$

The fixed-library source and target quadratures must be retained exactly.  If
$\widetilde\tau_j,\widetilde\zeta_j$ are the library evaluations of the two
frozen density polynomials, define

$$
D_\tau=\frac{2\pi_{\mathrm{lib}}}{N}
\sum_j s_j\|\widetilde\tau_j\|_2,
\qquad
D_\zeta=\frac{2\pi_{\mathrm{lib}}}{N}
\sum_j s_j\|\widetilde\zeta_j\|_2,
\tag{I5.1f-64}
$$

and, for each retained mode,

$$
q_\ell=\frac{2\pi_{\mathrm{lib}}}{N\sqrt{P_{\mathrm{lib}}}}
\sum_i s_i
\left|\exp_{\mathrm{lib}}
\!\left(-\mathrm{i}\frac{2\pi_{\mathrm{lib}}\ell}
{P_{\mathrm{lib}}}\,s_i^{\mathrm{arc}}\right)\right|.
\tag{I5.1f-65}
$$

No magnitude-one phase or $q_\ell=\sqrt P$ shortcut is used.  The positive
centre-error row bounds are

$$
\begin{aligned}
d_\ell^{\mathrm{val}}&=q_\ell
\big[(b_{10}+b_{01})D_\tau+b_{00}D_\zeta\big],\\
d_\ell^{\mathrm{nor}}&=q_\ell
\big[(b_{20}+2b_{11}+b_{02})D_\tau
+(b_{10}+b_{01})D_\zeta\big].
\end{aligned}
\tag{I5.1f-66}
$$

Let $r_{\ell,\mathrm{reg}}^\chi$ be the complete stored regular retained
radius and $h_{\mathrm{reg},\chi}$ the stored regular high-mode amplitude.
The regular high expression is a positive algebraic contraction of the action
bound; its exponential strip factor is gamma-free and fixed here.  Thus

$$
e_\ell^\chi=c_0d_\ell^\chi+c_Rr_{\ell,\mathrm{reg}}^\chi,
\qquad
D_{\mathrm{reg},\chi}^2
=S_J\sum_{|\ell|<L}w_\ell^\chi(e_\ell^\chi)^2
+S_\infty(c_0h_{\mathrm{reg},\chi})^2,
\tag{I5.1f-67}
$$

and Minkowski gives

$$
|\Delta\mathcal M_{\Gamma,\mathrm{reg}}|
\le D_{\mathrm{reg},\mathrm{nor}}+2D_{\mathrm{reg},\mathrm{val}}.
\tag{I5.1f-68}
$$

Equations (I5.1f-60)--(I5.1f-66) use coefficientwise triangle inequalities
before the signed Müller combination, radial differentiation, source
contraction, and the actual target quadrature.  The owners are disjoint:
$c_0d_\ell^\chi$ owns the canonical centre,
$c_Rr_{\ell,\mathrm{reg}}^\chi$ owns all retained regular radii, and
$c_0h_{\mathrm{reg},\chi}$ owns the regular high amplitude.

The implementation must fail closed unless the named call sets are complete,
$P_{\mathrm{lib}}$ and $\pi_{\mathrm{lib}}$ are nonzero, every factor,
radius, and weight is finite and nonnegative, source and target quadrature
owner counts match the run-02 graph, every actual stored source and target
normal component has magnitude at most one, and $R_X,R_Y$ bound every actual
finite-node coordinate displacement used in (I5.1f-63).  These last two gates
are what justify the unit component contractions in (I5.1f-66); they are not
an implicit exact-unit-normal assertion about library data.  Finally,
(I5.1f-57) must cover precisely the named calls.  A predeclared allocation
takes $0.000625$ for (I5.1f-68) and leaves
$0.000625$ for a new
$\Delta_{\mathrm{sf,rest3}}=\texttt{UNRESOLVED}$.  One may set all four
contract parameters to a common dyadic $t$, starting at $2^{-4}$ and
decreasing before evaluation until the explicit right side of (I5.1f-68) is
at most $0.000625$.  This stopping rule uses only the proved sensitivity
expression, not inter-level drift.  It does not establish that the actual
library satisfies the resulting contracts.  Every unnamed
primitive-evaluation effect stays in $\Delta_{\mathrm{sf,rest3}}$, and
arithmetic remains in $\Delta_{\mathrm{fp}}=\texttt{UNRESOLVED}$.

The regular-composite helper subsequently passed independent pre-run and
post-run review.  Its fixed call sets contained 4194304 real canonical
arguments in $[0,0.6400000000000003]$, 524288 source-phase arguments, and
2095104 target-phase arguments.  All declared gates passed, and it gave

$$
\begin{aligned}
D_{\mathrm{center,val}}&=61441.61931393947,&
D_{\mathrm{center,nor}}&=117.69570987302981,\\
D_{\mathrm{radius,val}}&=1.2469612186700654\times10^{-8},&
D_{\mathrm{radius,nor}}&=1.2441093650389572\times10^{-10}.
\end{aligned}
\tag{I5.1f-69}
$$

The first passing member of the predeclared dyadic schedule was
$t=2^{-30}=9.313225746154785\times10^{-10}$, for which the right side of
(I5.1f-68) was $0.0005727677356781513$.  The preceding value $2^{-29}$ gave
$0.0011455354742368328$ and failed the fixed $0.000625$ allocation.  Thus the
choice did not use inter-level drift.  The run used 14.87 seconds wall time,
0.699 seconds inside the helper, and 839712768 bytes peak resident memory; it
performed no solve.  Its output is
`regular-gamma-sensitivity-run-01.mat` in the existing attempt.

If the Faddeeva/$E_1$, local, and regular contracts above all hold, their
three partial allocations give the conditional subtotal

$$
\|R\|_{\mu,*}
\le 0.06077107308056649
+\Delta_{\mathrm{sf,rest3}}+\Delta_{\mathrm{fp}}.
\tag{I5.1f-70}
$$

This is not a reliable numerical bound while the last two terms are
unresolved.  In particular, the run establishes required accuracies, not the
actual error of any library primitive.

For a per-family sensitivity form requiring no further experiment, fix
$t_0=1/16$ and define

$$
U_0=\frac{e^{3t_0}}{(1-t_0)^2},\qquad
U_R=\frac{e^{4t_0}}{(1-t_0)^3},\qquad
D_{\mathrm{center}}=D_{\mathrm{center,nor}}+2D_{\mathrm{center,val}},\qquad
D_{\mathrm{radius}}=D_{\mathrm{radius,nor}}+2D_{\mathrm{radius,val}}.
\tag{I5.1f-71}
$$

For
$0\le\varepsilon_{\Gamma,r},\eta_i,\varepsilon_{\log},\eta_o\le t_0$,
Minkowski together with
$-\log(1-\eta)\le\eta/(1-t_0)$ and
$e^s-1\le e^{s_{\max}}s$ gives

$$
|\Delta\mathcal M_{\Gamma,\mathrm{reg}}|
\le A_\Gamma\varepsilon_{\Gamma,r}
+A_i\eta_i+A_{\log}\varepsilon_{\log}+A_o\eta_o,
\tag{I5.1f-72}
$$

where

$$
\begin{aligned}
A_\Gamma&=3(U_0D_{\mathrm{center}}+U_RD_{\mathrm{radius}}),&
A_i&=\frac{2(U_0D_{\mathrm{center}}+U_RD_{\mathrm{radius}})}{1-t_0},\\
A_{\log}&=U_RD_{\mathrm{radius}},&
A_o&=\frac{U_RD_{\mathrm{radius}}}{1-t_0}.
\end{aligned}
\tag{I5.1f-73}
$$

The constants in (I5.1f-69)--(I5.1f-73) are ordinary floating-point partial
sensitivity values.  Reliable use still requires outward enclosures of these
constants, verified primitive contracts, a completed
$\Delta_{\mathrm{sf,rest3}}$ graph, and an arithmetic enclosure for
$\Delta_{\mathrm{fp}}$.  The final independent verdict is therefore
`PASS WITH CONDITIONS` for these partial sensitivity calculations and
`STOP` for a present fully reliable numerator claim.
