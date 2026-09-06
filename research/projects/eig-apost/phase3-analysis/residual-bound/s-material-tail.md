# Material-interface normal defect: conditional tail and exact blocker

## Target and local notation

This note treats only the material-interface normal contribution $B_\Upsilon$
to the continuous residual numerator.  It keeps the common symbols of this
directory's `README.md`.  New local symbols are the material wavenumbers
$\kappa_e=\widehat k\sqrt{\rho_{\mathrm{out}}}$ and
$\kappa_i=\widehat k\sqrt{\rho_{\mathrm{in}}}$, the material collar width
$\delta_c$, the radial ratio $\underline r_c=(R-\delta_c)/R$, the general
curve parameter $t$, holomorphic speed branch $\vartheta$, arclength map $S$,
strip geometry constants $\vartheta_{\pm,a},X'_a,Y'_a,X_a,Y_a,
\delta_{w,a},\sigma_a$, off-surface rows $q_{p,w,\ell}$ and bounds
$A_{p,w},C_{p,w}$, and the explicit trace-weight lower bound
$\underline\vartheta_\ell$,
the retained angular cutoff $L$, the cell cutoff $J$, the finite part
$\overline F_{L,J}^\Upsilon$, the omission tail $T_{L,J}^\Upsilon$, and the
regular-image mixed-normal strip constant $A_{\mathrm{reg}}^\nu(A,a)$.  The
Ewald reduction additionally defines the split $a_E$, $h=a_E/d$, the
dimensionless $\eta$, reciprocal/image/Taylor cutoffs $N_R,N_I,N$, coordinate
remainders $T_{rs}$, and the local cancelled function ${\cal C}_\eta$.
The proof also defines the finite wall amplitudes $h_m(A)$ and signs $s_m$,
the off-surface constant $A_{\mathrm{off}}^\nu$, high-angular constants
$\mathcal C_{\Upsilon,\varsigma},\mathcal C_{\Upsilon,0}$, Lyapunov matrices
$Y_\varsigma$, and their block-power replacements $K_\varsigma$ at first use.

The conditional finite-plus-tail theorem below is explicit.  The Ewald
construction now reduces $A_{\mathrm{reg}}^\nu(A,a)$ to finitely many
complex-tube, ratio, non-Wood, normal, and finite-evaluation enclosures, so
the general regular-image component is `CONDITIONAL GO`.  The shape-general
local free-space theorem in `s-local-panel.md` likewise reduces its retained
rows and omitted modes to finite enclosures.  The complete module is therefore
`CONDITIONAL GO`, but it has not been instantiated: neither family of finite
constants has been evaluated.  The proof does not use circular
diagonalization.  The finite wall action additionally requires the displayed
curve-strip certificates.

Throughout the Ewald construction, $\kappa_e>0$, $a_E>0$, and hence the
dimensionless parameter $\eta=(\kappa_e d/(2a_E))^2$ is strictly positive;
$\log\eta$ is the real logarithm.

## Strong defect and its trace norm

On each material interface let $\nu$ point from the material interior to the
exterior; the frozen instance is circular, but the definition is not.
Piecewise integration by parts gives

$$
j_\Upsilon
=\partial_\nu u_{h,M}^{\mathrm{in}}|_\Upsilon
-\partial_\nu u_{h,M}^{\mathrm{out}}|_\Upsilon.
$$

The value correction $e$ has zero interface-normal derivative by its frozen
cubic construction, and its complete form contribution already belongs to
$B_{\mathrm{lift}}$.  It is not counted here.

### General material-normal trace theorem

Let $\Lambda$ be an embedded closed $C^3$ material interface with perimeter
$P_\Lambda$, parameterized by arclength

$$
{\boldsymbol r}:\mathbb R/P_\Lambda\mathbb Z\longrightarrow\Lambda,
\qquad |{\boldsymbol r}'(s)|=1.
$$

Assume that the union of the interfaces has reach at least $r_*>0$ and that
$|\kappa(s)|\le\kappa_*$.  Choose pairwise disjoint inner and outer collars
with widths $0<h_\pm<r_*$ and put

$$
\theta_\pm=1-h_\pm\kappa_*>0,
\qquad
\Theta_\pm=1+h_\pm\kappa_*.
$$

In the normal coordinates
$F_\pm(s,t)={\boldsymbol r}(s)\pm t\nu(s)$, the Jacobian $J_\pm$ lies in
$[\theta_\pm,\Theta_\pm]$.  Suppose
$\rho\ge\underline\rho_\pm>0$ on the respective collars.  In the
arclength Fourier basis

$$
\varphi_\ell(s)=P_\Lambda^{-1/2}e^{\mathrm i\xi_\ell s},
\qquad
\xi_\ell=\frac{2\pi\ell}{P_\Lambda},
$$

define

$$
\lambda_{\pm,\ell}^2
=\mu\underline\rho_\pm
+\frac{\xi_\ell^2}{\theta_\pm\Theta_\pm},
$$

$$
b_\ell^\Lambda
=\sum_{q\in\{-,+\}}
\theta_q\lambda_{q,\ell}
\tanh(h_q\lambda_{q,\ell})>0.
\tag{M-weight}
$$

**Theorem (general material-interface trace inequality).**
For every conforming $v\in V_\beta$, writing
$v|_\Lambda=\sum_\ell g_\ell\varphi_\ell$, one has

$$
\sum_\Lambda\sum_{\ell\in\mathbb Z}
b_\ell^\Lambda|g_\ell|^2\le\|v\|_\mu^2.
\tag{M-trace}
$$

Consequently, if
$j_\Lambda=\sum_\ell j_{\Lambda,\ell}\varphi_\ell$ in the dual sense,

$$
\left|\sum_\Lambda\langle j_\Lambda,v|_\Lambda\rangle\right|
\le
\left(
\sum_\Lambda\sum_{\ell\in\mathbb Z}
\frac{|j_{\Lambda,\ell}|^2}{b_\ell^\Lambda}
\right)^{1/2}\|v\|_\mu.
\tag{M-dual}
$$

**Proof.**  In one collar the exact metric formula is

$$
\int_0^{P_\Lambda}\int_0^{h_q}
\left[
J_q|v_t|^2+J_q^{-1}|v_s|^2+\mu\rho J_q|v|^2
\right]dt\,ds.
$$

It is bounded below by

$$
\theta_q\int_0^{P_\Lambda}\int_0^{h_q}
\left[
|v_t|^2+\frac{|v_s|^2}{\theta_q\Theta_q}
+\mu\underline\rho_q|v|^2
\right]dt\,ds.
$$

Parseval separates the arclength Fourier modes.  For a mode with boundary
value $g_\ell$, direct minimization with a free far endpoint gives

$$
\inf_{z(0)=g_\ell}\int_0^{h_q}
(|z'|^2+\lambda_{q,\ell}^2|z|^2)\,dt
=\lambda_{q,\ell}\tanh(h_q\lambda_{q,\ell})|g_\ell|^2.
$$

The minimizer is the elementary hyperbolic-cosine profile.  Sum both sides
and then all disjoint material collars to obtain (M-trace).  Weighted
Cauchy--Schwarz proves (M-dual).  $\square$

For $n=|\ell|\ge1$, set

$$
c_q^{\rm tr}=\sqrt{\frac{\theta_q}{\Theta_q}},
\qquad
d_q^{\rm tr}=\frac{h_q}{\sqrt{\theta_q\Theta_q}}.
$$

Then

$$
b_\ell^\Lambda
\ge |\xi_\ell|\sum_{q\in\{-,+\}}
c_q^{\rm tr}\tanh(d_q^{\rm tr}|\xi_\ell|).
\tag{M-high-weight}
$$

If an analytic normal-action row has strip supremum $A_*$, contour shifting
gives
$\|j_{\Lambda,\ell}\|_2\le\sqrt{P_\Lambda} A_*
e^{-2\pi a_*|\ell|/P_\Lambda}$.  With

$$
N=L_{\rm cut}+1,
\quad r_a=e^{-4\pi a_*/P_\Lambda},
\quad
D_N=\sum_q c_q^{\rm tr}
\tanh\!\left(\frac{2\pi N}{P_\Lambda}d_q^{\rm tr}\right),
$$

(M-high-weight) yields the explicit tail

$$
\sum_{|\ell|>L_{\rm cut}}
\frac{\|j_{\Lambda,\ell}\|_2^2}{b_\ell^\Lambda}
\le
\frac{P_\Lambda^2A_*^2}{\pi D_N}
\frac{r_a^N}{N(1-r_a)}.
\tag{M-dual-tail}
$$

This trace theorem uses only length, the supplied reach and curvature bounds,
collar widths, lower material bounds, and $\mu$.  It has no circular or
star-shaped hypothesis.

### Frozen circular trace specialization

For a circular component of radius $R$, use

$$
\phi_\ell(\theta)=(2\pi R)^{-1/2}e^{\mathrm i\ell\theta},
\qquad
j_\Upsilon=\sum_{\ell\in\mathbb Z}j_{\Upsilon,\ell}\phi_\ell.
$$

Take disjoint inner and outer collars of the same width
$0<\delta_c<R$.  Define

$$
\lambda_{\mathrm{out},\ell}^2
=\mu\rho_{\mathrm{out}}
+\frac{\ell^2}{R(R+\delta_c)},
\qquad
\lambda_{\mathrm{in},\ell}^2
=\mu\rho_{\mathrm{in}}+\frac{\ell^2}{R^2},
$$

$$
\underline\vartheta_\ell
=\lambda_{\mathrm{out},\ell}
\tanh(\lambda_{\mathrm{out},\ell}\delta_c)
+\underline r_c\lambda_{\mathrm{in},\ell}
\tanh(\lambda_{\mathrm{in},\ell}\delta_c)>0.
$$

For fixed boundary value $g$, direct minimization gives

$$
\inf_{z(0)=g}\int_0^{\delta_c}
(|z'|^2+\lambda^2|z|^2)\,ds
=\lambda\tanh(\lambda\delta_c)|g|^2.
$$

The minimizer is the elementary hyperbolic-cosine solution with a free far
endpoint.  Bounding $r/R$ and the angular coefficient separately in the two
collars therefore proves, for every $v\in V_\beta$,

$$
\sum_\Upsilon\sum_{\ell\in\mathbb Z}
\underline\vartheta_\ell
|(v|_\Upsilon)_\ell|^2\le\|v\|_\mu^2.
$$

Consequently,

$$
\left|\sum_\Upsilon\langle j_\Upsilon,v|_\Upsilon\rangle\right|
\le B_\Upsilon\|v\|_\mu,
\qquad
B_\Upsilon^2
:=\sum_\Upsilon\sum_{\ell\in\mathbb Z}
\frac{|j_{\Upsilon,\ell}|^2}{\underline\vartheta_\ell}.
$$

This uses constant one and no unknown trace constant.  For
$n=|\ell|\ge1$ it also gives the useful explicit estimate

$$
\underline\vartheta_\ell
\ge\underline r_c\frac nR\tanh\!\left(\frac{n\delta_c}{R}\right),
$$

so the dual weight contains the required $O(n^{-1})$ high-angular factor.

## Exact-kernel decomposition

The artifact stores $\eta=(\tau,-\sigma)^{\mathsf T}$; $\sigma$ below is the
actual single-layer density after changing that sign once at the input
boundary.  With $\mathcal T$ denoting the hypersingular operator and
$K^*$ the adjoint double-layer operator, the stated in-minus-out convention
gives

$$
j_\Upsilon
=(\mathcal T_i-\mathcal T_e^{QP})\tau
+(I+K_i^*-(K_e^{QP})^*)\sigma
+A_{w\to\Upsilon}^{\nu}\xi.
$$

Here the wall term is fixed by

$$
A_{w\to\Upsilon}^{\nu}\xi
:=-\partial_\nu u_w^{\mathrm{out}}|_\Upsilon,
$$

because the wall-generated field occurs only in the exterior contribution of
the in-minus-out defect.

### Frozen circular local free specialization

Put $H_\beta=G_e^{QP}-G_e^{\mathrm{free}}$.  The identity and same-center
free-circle part is diagonal in the circular Fourier basis.  For example,
the individual free hypersingular multiplier is

$$
t_\ell(\kappa)
=\frac{\mathrm i\pi\kappa^2R}{2}
J_\ell'(\kappa R)H_\ell^{(1)\prime}(\kappa R),
\qquad \kappa\in\{\kappa_i,\kappa_e\}.
$$

Its $|\ell|$ growth must be retained in the finite rows.  Because the frozen
$\tau,\sigma$ are finite trigonometric polynomials, this diagonal part has no
omitted angular support once $L$ covers their support.

### General local free-space panel gate

The preceding diagonal-support conclusion is specific to the frozen circle.
On a noncircular boundary, a finite density does not imply finite output
support for a local free-space layer operator.  The complete general-boundary
action must first be decomposed as

$$
\text{jump identity}+\text{local free-space action}
+\text{regular-image action}+\text{off-surface action}.
$$

For a panel not containing the target, positive separation permits an
analytic or derivative-based quadrature enclosure.  On the target panel, the
local logarithmic singularity must be subtracted at the function level before
evaluation.  For the normal module, the common principal
$(s-s')^{-2}$ part of the two free hypersingular kernels must be cancelled
analytically before the remaining integrand is bounded.  The explicit
singular template is integrated separately; the regular panel remainder
receives a joint-strip or finite-derivative quadrature bound.

For $p=0$ (value) and $p=1$ (target normal), this route must supply both

$$
\sup_{|\operatorname{Im}z|\le a}
\|{\cal L}^{\rm loc}_p(z;A)\|_2
\le A_{p,{\rm loc}}(A,a)<\infty
\tag{M-local-strip}
$$

and rigorous enclosures for every retained arclength Fourier row.  Neither
sampled smoothness nor the circular diagonal multipliers prove
(M-local-strip).  The shape-general theorem in `s-local-panel.md` closes
the same local contribution by a weaker real-axis route: it combines the two
material kernels before bounding, subtracts the periodic logarithm, encloses
every retained row, and proves the algebraic normal tail (P20).  Hence the
local component is `CONDITIONAL GO` without assuming (M-local-strip).

For each state map, let $\mathcal C_{\Upsilon,\mathrm{loc}}(L)$ be the square
root of (P20) and let
$\mathcal C_{\Upsilon,\mathrm{an}}(L)$ be the combined regular-image and
off-surface high-mode bound.  These actions contribute to the same modal
defect, so they are combined by the weighted sequence-space triangle
inequality,

$$
\mathcal C_{\Upsilon,\mathrm{all}}(L)
\le\mathcal C_{\Upsilon,\mathrm{loc}}(L)
+\mathcal C_{\Upsilon,\mathrm{an}}(L).
\tag{M-local-combine}
$$

The retained local, regular-image, off-surface, and identity rows are likewise
added before their trace weights are applied.  Formula
(M-local-combine), not an orthogonality assumption, supplies each
$\mathcal C_{\Upsilon,\varsigma}(L)$ used in the half-guide sum below.

## General off-surface wall-to-boundary action

This subsection closes the finite-wall-support action on a separated general
boundary without using a circular parameterization.  Only in this subsection,
write the boundary as a regular $2\pi$-periodic analytic curve

$$
{\boldsymbol r}(t)=(x(t),y(t)),
\qquad
\vartheta(t)=\sqrt{x'(t)^2+y'(t)^2}>0
\quad (t\in\mathbb R).
$$

Assume that $x,y$ extend holomorphically to an open neighborhood of the closed
strip $S_a^t=\{z:|\operatorname{Im}z|\le a\}$ and that
$g(z)=x'(z)^2+y'(z)^2$ has there a nonvanishing, periodic, holomorphic square
root $\vartheta(z)$ which agrees with the positive real speed.  Require the
computable bounds

$$
0<\vartheta_{-,a}\le|\vartheta(z)|\le\vartheta_{+,a},
\qquad
|x'(z)|\le X'_a,
\qquad
|y'(z)|\le Y'_a.
\tag{M-off-geometry}
$$

For a fixed orientation put

$$
\nu(z)=\varepsilon_\nu
\frac{(y'(z),-x'(z))}{\vartheta(z)},
\qquad \varepsilon_\nu\in\{-1,+1\}.
$$

Let

$$
S(z)=\int_0^z\vartheta(\zeta)\,d\zeta,
\qquad P_\Lambda=S(2\pi),
\qquad \xi_\ell=\frac{2\pi\ell}{P_\Lambda}.
$$

Then $S(z+2\pi)=S(z)+P_\Lambda$.  Consider a wall $x=X_w$ and suppose the
real curve is on one side of it.  With

$$
s_w=\operatorname{sign}(x(t)-X_w),
\qquad d_w(z)=s_w(x(z)-X_w),
$$

require, for every evanescent retained order, the signed complex-clearance
certificate

$$
\delta_{w,a}:=\inf_{z\in S_a^t}\operatorname{Re}d_w(z)>0.
\tag{M-off-clearance}
$$

Let $\mathcal I_w$ be the finite frozen wall support, let
$\gamma_m^2=\kappa_e^2-\beta_m^2$ use the outgoing/decaying branch, and require
$\gamma_m\ne0$ for every $m\in\mathcal I_w$.  If
$\zeta_{w,m}(A)$ is the normalized wall Fourier row, define

$$
h_{w,m}(A)=\frac{\mathrm i}{2\gamma_m\sqrt d}\zeta_{w,m}(A),
\qquad
E_{w,m}(z)=e^{\mathrm i\gamma_md_w(z)+\mathrm i\beta_my(z)}.
$$

If a stored row already includes the Green multiplier, that row is
$h_{w,m}$ and the multiplier is not applied again.  Put

$$
L_{w,m}(a)
=\frac{|\gamma_m|Y'_a+|\beta_m|X'_a}{\vartheta_{-,a}}.
$$

For propagating orders take

$$
\Phi_{w,m}^{\rm pr}(a)
=\exp\{\gamma_mX_a+|\beta_m|Y_a\},
\quad
X_a=\sup_{S_a^t}|\operatorname{Im}x|,
\quad
Y_a=\sup_{S_a^t}|\operatorname{Im}y|,
$$

whereas for $\gamma_m=\mathrm i\kappa_m$, $\kappa_m>0$, take

$$
\Phi_{w,m}^{\rm ev}(a)
=\exp\{-\kappa_m\delta_{w,a}+|\beta_m|Y_a\}.
$$

Denote the appropriate one by $\Phi_{w,m}(a)$ and set

$$
{\cal T}_{p,w}(z;A)
=\sum_{m\in\mathcal I_w}h_{w,m}(A)E_{w,m}(z)
\left[\mathrm i\{s_w\gamma_m\nu_x(z)+\beta_m\nu_y(z)\}\right]^p,
\quad p\in\{0,1\}.
$$

Thus $p=0$ is the value trace used by the lifting module and $p=1$ is the
target-normal trace used here.  Directly from (M-off-geometry),

$$
\sup_{S_a^t}\|{\cal T}_{p,w}(z;A)\|_2
\le A_{p,w}(A,a),
\tag{M-off-action}
$$

where

$$
A_{p,w}(A,a)
=\sum_{m\in\mathcal I_w}
\|h_{w,m}(A)\|_2
\Phi_{w,m}(a)W_{p,w,m}(a),
$$

with $W_{0,w,m}=1$ and $W_{1,w,m}=L_{w,m}$.  In particular, a general target
normal has a tangential-to-wall component; the factor $1/\gamma_m$ may not be
cancelled silently in the $p=1$ bound.  When the primitive row is
$\zeta_{w,m}$, the displayed definition of $h_{w,m}$ makes its
$1/(2\sqrt d\,|\gamma_m|)$ weight explicit; when the artifact already stores
$h_{w,m}$, no second multiplier is present in either the action or this bound.

The normalized arclength Fourier row is

$$
q_{p,w,\ell}(A)
=\frac1{\sqrt{P_\Lambda}}\int_0^{2\pi}
\vartheta(t){\cal T}_{p,w}(t;A)e^{-\mathrm i\xi_\ell S(t)}\,dt.
$$

Define $\Sigma_a=\sup_{S_a^t}|\operatorname{Im}S|$.  Its $N_t$-point
periodic trapezoidal approximation has the explicit remainder

$$
\|q_{p,w,\ell}-\widetilde q_{p,w,\ell}^{(N_t)}\|_2
\le\epsilon_{p,w,\ell}^{\rm tgt}
:=\frac{4\pi\vartheta_{+,a}A_{p,w}(A,a)
e^{|\xi_\ell|\Sigma_a}}
{\sqrt{P_\Lambda}(e^{aN_t}-1)}.
\tag{M-off-quad}
$$

Indeed the complete parameter-space integrand is holomorphic and periodic;
the two-sided Fourier-alias sum is a geometric series.  For a boundary-mode
tail also require

$$
\sigma_a:=\min\left\{
\inf_t[-\operatorname{Im}S(t-\mathrm ia)],
\inf_t[\operatorname{Im}S(t+\mathrm ia)]\right\}>0.
\tag{M-off-arclength}
$$

Contour shifting then gives

$$
\|q_{p,w,\ell}(A)\|_2
\le C_{p,w}(A,a)e^{-|\xi_\ell|\sigma_a},
\qquad
C_{p,w}=\frac{2\pi\vartheta_{+,a}}{\sqrt{P_\Lambda}}A_{p,w}.
\tag{M-off-Fourier}
$$

For the normal contribution take $p=1$.  If $N=L+1$ is in the high-frequency
range of (M-high-weight), put

$$
r_a=e^{-4\pi\sigma_a/P_\Lambda}.
$$

Then the complete omitted boundary-mode tail of this wall action obeys

$$
\sum_{|\ell|\ge N}
\frac{\|q_{1,w,\ell}(A)\|_2^2}{b_\ell^\Lambda}
\le
\frac{P_\Lambda C_{1,w}(A,a)^2}{\pi D_N}
\frac{r_a^N}{N(1-r_a)}.
\tag{M-off-dual-tail}
$$

This follows from $b_\ell^\Lambda\ge(2\pi/P_\Lambda)D_N|\ell|$,
$1/|\ell|\le1/N$, and the two-sided geometric sum.  It uses no observed
Fourier decay.

Equations (M-off-quad) and (M-off-Fourier) enter the barred finite rows and
high-boundary-mode constants, respectively.  Applied to the center/singleton
map and to each side map $P_\varsigma^nc_\varsigma$, their row norms combine
with the same whole-matrix Lyapunov or block-power certificate as the other
actions.  Thus the four disjoint singleton, retained-cell, propagated-cell,
and high-boundary-mode index sets are preserved.  This is a finite modal
action: once (M-off-geometry), (M-off-clearance), (M-off-arclength), and the
finite non-Wood gates are certified, it has no infinite kernel remainder.

### Frozen circular specialization

For a frozen wall mode write, after absorbing its center phase, modal solve,
state map, and every $1/\gamma_m$ into $h_m(A)$,

$$
u_m(\theta;A)=h_m(A)
\exp\!\left(
-\mathrm i s_m\gamma_mR\cos\theta
+\mathrm i\beta_mR\sin\theta
\right).
$$

Its target-normal derivative is

$$
\partial_\nu u_m
=\mathrm i(-s_m\gamma_m\cos\theta+\beta_m\sin\theta)u_m.
$$

For a propagating order, the strip envelope is

$$
\|h_m(A)\|_2e^{\kappa_eR\sinh a}\kappa_e\cosh a.
$$

For an evanescent order $\gamma_m=\mathrm i\kappa_m$, it is

$$
\|h_m(A)\|_2
e^{R(\kappa_m\cosh a+|\beta_m|\sinh a)}
(|\beta_m|\cosh a+\kappa_m\sinh a).
$$

These are the circular specializations of (M-off-action); in particular the
evanescent factor retains the real-axis contribution $e^{\kappa_mR}$ at
$a=0$.  Summing over the finite frozen wall support defines a computable
$A_{\mathrm{off}}^\nu(A,a)$.  Every order is classified by the sign of
$\kappa_e^2-\beta_m^2$; equality is a Wood failure.  A small nonzero
$\gamma_m$, or any small modal denominator already contained in $h_m$, may
make the bound large but may not be cancelled, clipped, or replaced by a
threshold.  Full half-guide propagation is closed by the same Lyapunov or
block-power certificate as in `s-wall-tail.md`.

For the current circle adapter, the general geometry gates themselves reduce
exactly to

$$
\vartheta(z)=R,
\quad S(z)=Rz,
\quad P_\Lambda=2\pi R,
\quad X'_a=Y'_a=R\cosh a,
\quad X_a=Y_a=R\sinh a,
$$

$$
\delta_{w,a}=D-R\cosh a,
\qquad \Sigma_a=\sigma_a=Ra.
$$

With the frozen $D=1/2$, $R=1/5$ and the existing contract choice
$a=\tfrac12\log(5/2)$, all these quantities are finite and
$D-R\cosh a>0$.  Thus the current circle closes the general curve branch,
speed, clearance, and signed-arclength gates analytically; only the retained
non-Wood test is numerical.  This instance check uses the circle only as the
chosen data, not as an assumption of (M-off-action), and it does not affect
the self-action blockers below.

## Unified general-boundary regular-image theorem

Assume that the arclength parameterization of $\Lambda$ extends as a
$P_\Lambda$-periodic holomorphic map ${\boldsymbol r}(z)$ to

$$
S_a=\{z:|\operatorname{Im}z|\le a\}.
$$

Its fixed normal has the corresponding holomorphic continuation $\nu(z)$.
The strip must remain inside an embedded complex tube: it may not meet a
nonzero periodic image or a branch singularity of the Green representation.
Subtract the local free kernel before differentiation,

$$
H_\beta(x,x')
=G_{e,\beta}^{QP}(x,x')-G_e^{\rm free}(x-x').
$$

Let $D_x^{(0)}$ be the identity and
$D_x^{(1)}=\nu(z)\mathbin\cdot\nabla_x$, with the analogous source
operators.  For $p,q\in\{0,1\}$ define

$$
K_{pq}(a)
=\sup_{z\in S_a,\ s'\in[0,P_\Lambda]}
\left|
D_x^{(p)}D_{x'}^{(q)}
H_\beta({\boldsymbol r}(z),{\boldsymbol r}(s'))
\right|.
\tag{M-Kpq}
$$

Thus $K_{00}$ is the value-kernel bound, $K_{01}$ and $K_{10}$ are the two
one-normal bounds, and $K_{11}$ is the mixed-normal second-derivative bound.
A target-angle derivative is tangential and cannot replace $K_{10}$ or
$K_{11}$.

For a frozen state map $A$, let $A_\tau(A)$ and $A_\sigma(A)$ be rigorous
$L^1(ds)$ operator bounds for the actual densities, meaning

$$
A_\tau(A)
\ge\sup_{\|x\|_2=1}\|t_\tau(\cdot;Ax)\|_{L^1(ds)},
\qquad
A_\sigma(A)
\ge\sup_{\|x\|_2=1}\|t_\sigma(\cdot;Ax)\|_{L^1(ds)}.
$$

They may be computed from the exact arclength mass matrix as in
`s-wall-tail.md`.  Define

$$
\begin{split}
{\cal R}_p(z;A)
=\int_\Lambda\big[&
D_x^{(p)}D_{x'}^{(1)}H_\beta
t_\tau(s';A)\\
&+D_x^{(p)}H_\beta t_\sigma(s';A)
\big]ds',
\end{split}
$$

where both kernels are evaluated at
$({\boldsymbol r}(z),{\boldsymbol r}(s'))$.

**Theorem (unified regular-image action bound).**
Suppose all four numbers in (M-Kpq) have finite, rigorous, computable
enclosures.  Then, for $p\in\{0,1\}$,

$$
\sup_{z\in S_a}\|{\cal R}_p(z;A)\|_2
\le A_{p,{\rm reg}}(A,a)
:=K_{p1}(a)A_\tau(A)+K_{p0}(a)A_\sigma(A).
\tag{M-action}
$$

Define its normalized arclength Fourier rows by

$$
r_{p,\ell}(A)
=\int_0^{P_\Lambda}{\cal R}_p(s;A)
\overline{\varphi_\ell(s)}\,ds.
$$

They satisfy

$$
\|r_{p,\ell}(A)\|_2
\le\sqrt{P_\Lambda} A_{p,{\rm reg}}(A,a)
e^{-2\pi a|\ell|/P_\Lambda}.
\tag{M-Fourier}
$$

If a retained row is computed by the $N_t$-point periodic trapezoidal rule,
its target-integration remainder is

$$
\epsilon_{p,\ell}^{\rm tgt}
\le
\frac{2\sqrt{P_\Lambda} A_{p,{\rm reg}}(A,a)
e^{2\pi a|\ell|/P_\Lambda}}
{e^{2\pi aN_t/P_\Lambda}-1}.
\tag{M-target-quad}
$$

If the source integral is also discretized, require joint holomorphy in a
source strip $|\operatorname{Im}w|\le b$ after the local free subtraction.
If its complete source integrand is bounded by $M_p(a,b)$ uniformly for
$z\in S_a$, its periodic $N_s$-point source error is at most

$$
\epsilon_p^{\rm src}(a,b)
\le\frac{2P_\Lambda M_p(a,b)}
{e^{2\pi bN_s/P_\Lambda}-1}.
\tag{M-source-quad}
$$

This uniform row error contributes at most
$\sqrt{P_\Lambda}\epsilon_p^{\rm src}$ to an exact retained Fourier coefficient and
is added once to (M-target-quad).

**Proof.**  The $L^1$ density bounds and the definitions of $K_{p1}$ and
$K_{p0}$ give (M-action) directly.  Shift the target arclength contour by
$-\operatorname{sign}(\ell)\mathrm ia$ to obtain (M-Fourier).  After scaling
the period $P_\Lambda$ to $2\pi$, the alias sum for the periodic trapezoidal rule is
a two-sided geometric series; this gives (M-target-quad).  Applying the same
argument in the source variable gives (M-source-quad).  $\square$

No external theorem is invoked in this conditional implication: it uses only
the definitions of the four kernel constants, $L^1$ integration, contour
shifting, and the explicitly summed trapezoidal aliases.

For $p=0$, combine (M-Fourier) with the tubular lifting weights in
`s-lift-tail.md`.  For $p=1$, combine it with (M-dual-tail).  Add the local
panel constant, off-surface constant, and regular-image constant by the
triangle inequality before forming a tail.  Retained coefficient enclosures
enter the barred finite rows once.  Low arclength modes beyond cell $J$ and
all high arclength modes over the half-guide are summed by the same verified
Lyapunov or block-power certificate as in `s-wall-tail.md`.

A reliable stopping rule requires the assigned source, target, and local
panel remainders and the complete analytic-plus-propagation tail to be below
fixed tolerances.  It never uses inter-level drift.

The strongest inequality that the regular-image construction must supply is
the case

$$
\sup_{z\in S_a,\ s'\in[0,P_\Lambda]}
\left|
\nu(z)^{\mathsf T}\nabla_x\nabla_{x'}
[G_{e,\beta}^{QP}-G_e^{\rm free}]
({\boldsymbol r}(z),{\boldsymbol r}(s'))\nu(s')
\right|
\le\overline K_{11}(a)<\infty.
\tag{M-first-blocker}
$$

The bound must be computed only from the frozen wavenumber, $\beta,d$, and
the complex-tube geometry.  It must prove the local singularity cancellation
before evaluation, exclude all Wood orders, retain every small
$1/\gamma_m$, and cover the $\gamma_m^2$, $\gamma_m\beta_m$, and
$\beta_m^2$ weights created by mixed differentiation together with the full
all-image or Ewald remainder.  The project material available before this
study supplied no such derivative remainder.  The Ewald construction and the
branch-free local cancellation below close its infinite reciprocal, image,
Taylor, and local truncation tails, leaving only the finite certificates
stated after (M-L14).  Thus the regular-image theorem is now a precise
conditional algorithm, not yet a frozen-instance numerical certificate.
Independently, the complete shape-general module still requires the local
panel gate (M-local-strip).

### Bounded source and implementation audit of the Ewald route

The locally archived original is C. M. Linton, *Journal of Engineering
Mathematics* **33** (1998), 377--402, DOI
`10.1023/A:1004377501747`.  Equation (2.65), PDF p. 13 / journal p. 389, is an
exact two-series Ewald representation.  Its derivation assumes a small
positive imaginary part of the wavenumber and states that the real-wavenumber
formula follows by analytic continuation; its split parameter is any
$a_E>0$.  The reciprocal series contains Linton's $1/q_m$, equivalently the
project's $1/\gamma_m$ up to the fixed branch factor, so the present use also
requires the non-Wood gate.  The following page states the tradeoff
between the two infinite sums and the asymptotic
$E_n(x)\sim x^{-1}e^{-x}$, but it does not state a finite, uniform remainder
for value, first derivatives, or mixed second derivatives on a complex
target/source tube.

The project implementation does not fill that gap.  The production
`+kernel/qpgreen_mfs_pairmat.m` is a finite free-kernel-plus-proxy/Rayleigh
approximation.  The archived Linton evaluator truncates (2.65) at finite
$(M_1,M_2,N)$ and checks changes under enlarged tuples; its derivative
extension differentiates the same truncated sums.  Neither path stores a
spectral, spatial, Taylor, or special-function remainder.  The historical
agreement and refinement changes are ordinary numerical evidence and are
forbidden as the stopping rule here.  Consequently the original source
verifies the infinite representation and branch denominators, but not
(M-first-blocker).  The next two subsections provide the missing uniform Ewald
truncation theorem from scratch.  An I5 $K_{pq}$ evaluator remains conditional
until its finite enclosures implement those formulas.

### Explicit Ewald tails away from the local image

The source audit nevertheless permits a proof-from-scratch reduction of the
missing Ewald theorem to its local $j=0$ term.  Let

$$
(X,Y)={\boldsymbol r}(z)-{\boldsymbol r}(w)
$$

on the certified target/source complex tube, and supply finite bounds
$R_X,R_Y,I_X,I_Y,U_X,U_Y$ for $|X|,|Y|,|\operatorname{Im}X|,
|\operatorname{Im}Y|,|\operatorname{Re}X|,|\operatorname{Re}Y|$,
respectively.  To avoid conflict with the curve-strip width, denote Linton's
positive Ewald split parameter by $a_E$ and put

$$
h=\frac{a_E}{d},
\qquad
\eta=\left(\frac{\kappa_e d}{2a_E}\right)^2,
\qquad b=\frac{2\pi}{d}.
$$

Every finite reciprocal denominator is retained, and exact Wood orders are
excluded.

Linton writes the real-axis formula with $|X|$.  The reciprocal bracket is the
sum over $\epsilon=\pm1$ below, so replacing $X$ by $-X$ only exchanges its
two terms.  It is therefore an even entire function of signed complex $X$;
the continuation used here does not complexify the nonholomorphic map
$|X|$.

#### Reciprocal tail

Retain $|m|<N_R$.  On the two tail rays set

$$
t_{\sigma,n}=bn+\sigma\beta,
\qquad
q_{\sigma,n}=\sqrt{t_{\sigma,n}^2-\kappa_e^2},
\qquad \sigma\in\{-1,+1\},\quad n\ge N_R,
$$

and require

$$
t_{\sigma,n}>\kappa_e,
\qquad
q_{\sigma,n}\ge2h^2U_X.
\tag{M-R-gate}
$$

For $\epsilon\in\{-1,+1\}$, the reciprocal bracket contains

$$
F_{\sigma,n,\epsilon}(X)
=e^{\epsilon q_{\sigma,n}X}
\operatorname{erfc}\left(\frac{q_{\sigma,n}}{2h}+\epsilon hX\right).
$$

The elementary complex identity

$$
\operatorname{erfc}(u)
=\frac2{\sqrt\pi}e^{-u^2}
\int_0^\infty e^{-t^2-2ut}\,dt
$$

gives the exact Gaussian cancellation

$$
F_{\sigma,n,\epsilon}(X)
=\frac2{\sqrt\pi}
e^{-q_{\sigma,n}^2/(4h^2)-h^2X^2}
\int_0^\infty
e^{-t^2-q_{\sigma,n}t/h-2\epsilon hXt}\,dt.
\tag{M-R-cancel}
$$

Let $\mu_j=\tfrac12\Gamma((j+1)/2)$ and

$$
P_0=\mu_0,
$$

$$
P_1=2h^2R_X\mu_0+2h\mu_1,
$$

$$
P_2=(4h^4R_X^2+2h^2)\mu_0
+8h^3R_X\mu_1+4h^2\mu_2.
$$

Condition (M-R-gate) makes the real part of the remaining linear exponent
nonpositive.  Differentiating (M-R-cancel) under the integral therefore gives,
for $r=0,1,2$,

$$
\left|\partial_X^r
\sum_{\epsilon=\pm1}F_{\sigma,n,\epsilon}(X)\right|
\le\frac{4P_r}{\sqrt\pi}
\exp\left(-\frac{q_{\sigma,n}^2}{4h^2}+h^2I_X^2\right).
$$

Consequently, for $r+s\le2$, the reciprocal truncation error is bounded by

$$
T_{rs}^{\rm rec}
\le\frac{P_re^{h^2I_X^2}}{d\sqrt\pi}
\sum_{\sigma=\pm1}\sum_{n=N_R}^\infty
\frac{t_{\sigma,n}^{s}}{q_{\sigma,n}}
\exp\left(-\frac{q_{\sigma,n}^2}{4h^2}
+t_{\sigma,n}I_Y\right).
\tag{M-R-tail-series}
$$

This retains the $t^2/q$ weight from two $Y$ derivatives.  The Gaussian
cancellation means that $X$ derivatives do not require an artificial extra
$q$ or $q^2$ factor.  Define $A_{\sigma,n}^{(s)}$ by the summand in
(M-R-tail-series), and put

$$
\rho_{\sigma,s}
=\left(1+\frac b{t_{\sigma,N_R}}\right)^s
\exp\left[-\frac{b(2t_{\sigma,N_R}+b)}{4h^2}+bI_Y\right].
$$

If $\rho_{\sigma,s}<1$, the successive ratio is no larger than
$\rho_{\sigma,s}$, hence

$$
\sum_{n=N_R}^\infty A_{\sigma,n}^{(s)}
\le\frac{A_{\sigma,N_R}^{(s)}}{1-\rho_{\sigma,s}}.
\tag{M-R-tail}
$$

#### Omitted nonzero real-image tail

Write the real-space inner sum as

$$
H_\eta(z)=\sum_{n=0}^\infty\frac{\eta^n}{n!}E_{n+1}(z)
=\int_1^\infty e^{-zt+\eta/t}\frac{dt}{t},
\qquad \operatorname{Re}z>0.
$$

Direct integration gives

$$
|H_\eta(z)|,|H_\eta'(z)|
\le e^\eta\frac{e^{-\operatorname{Re}z}}{\operatorname{Re}z},
$$

$$
|H_\eta''(z)|
\le e^\eta e^{-\operatorname{Re}z}
\left(\frac1{\operatorname{Re}z}
+\frac1{(\operatorname{Re}z)^2}\right).
\tag{M-E-bounds}
$$

For image $j$ let $z_j=h^2[X^2+(Y-jd)^2]$.  Retain $|j|<N_I$, and for
$n\ge N_I$ set

$$
u_n=h^2[(nd-U_Y)^2-I_X^2-I_Y^2],
\qquad L_n=nd+R_Y.
$$

Require

$$
N_Id>U_Y,
\qquad u_{N_I}>0.
\tag{M-I-gate}
$$

For $\alpha\in\{0,1,2\}$ put

$$
\rho_\alpha
=\left(1+\frac d{L_{N_I}}\right)^\alpha
\exp\{-h^2d[2(N_Id-U_Y)+d]\}<1,
$$

and, for $q\in\{1,2\}$, define

$$
{\mathscr S}_{\alpha,q}
=\frac{2L_{N_I}^\alpha e^{-u_{N_I}}u_{N_I}^{-q}}
{1-\rho_\alpha}.
$$

The factor two covers both image rays.  Equations (M-E-bounds),
$z_X=2h^2X$, $z_Y=2h^2(Y-jd)$ and $z_{XX}=z_{YY}=2h^2$ give

$$
T_{00}^{\rm img}\le\frac{e^\eta}{4\pi}{\mathscr S}_{0,1},
$$

$$
T_{10}^{\rm img}\le\frac{e^\eta}{4\pi}(2h^2R_X){\mathscr S}_{0,1},
\qquad
T_{01}^{\rm img}\le\frac{e^\eta}{4\pi}(2h^2){\mathscr S}_{1,1},
$$

$$
T_{20}^{\rm img}\le\frac{e^\eta}{4\pi}
\left[(2h^2R_X)^2({\mathscr S}_{0,1}+{\mathscr S}_{0,2})
+2h^2{\mathscr S}_{0,1}\right],
$$

$$
T_{11}^{\rm img}\le\frac{e^\eta}{4\pi}
(2h^2R_X)(2h^2)({\mathscr S}_{1,1}+{\mathscr S}_{1,2}),
$$

$$
T_{02}^{\rm img}\le\frac{e^\eta}{4\pi}
\left[(2h^2)^2({\mathscr S}_{2,1}+{\mathscr S}_{2,2})
+2h^2{\mathscr S}_{0,1}\right].
\tag{M-I-tail}
$$

These bounds sum every Taylor order on every omitted image, so no part of
them is counted in the next tail.

#### Taylor tail on retained nonzero images

For $N\ge2$, let

$$
\Pi_N(\eta)=e^\eta-\sum_{n=0}^N\frac{\eta^n}{n!}.
$$

For each $0<|j|<N_I$, require

$$
u_j:=\inf_{\mathcal D}\operatorname{Re}z_j>0
\tag{M-T-gate}
$$

on the certified complex tube $\mathcal D$, and define

$$
Z_{X,j}=\sup_{\mathcal D}|2h^2X|,
\qquad
Z_{Y,j}=\sup_{\mathcal D}|2h^2(Y-jd)|,
$$

$$
\Theta_j=\Pi_N(\eta)\frac{e^{-u_j}}{u_j}.
$$

Because all omitted $E_p$ in $H_\eta,H_\eta',H_\eta''$ have $p\ge2$,

$$
T_{00,j}^{\rm tay}\le\frac{\Theta_j}{4\pi},
$$

$$
T_{10,j}^{\rm tay}\le\frac{Z_{X,j}\Theta_j}{4\pi},
\qquad
T_{01,j}^{\rm tay}\le\frac{Z_{Y,j}\Theta_j}{4\pi},
$$

$$
T_{20,j}^{\rm tay}
\le\frac{(Z_{X,j}^2+2h^2)\Theta_j}{4\pi},
\qquad
T_{11,j}^{\rm tay}
\le\frac{Z_{X,j}Z_{Y,j}\Theta_j}{4\pi},
$$

$$
T_{02,j}^{\rm tay}
\le\frac{(Z_{Y,j}^2+2h^2)\Theta_j}{4\pi}.
\tag{M-T-tail}
$$

#### Coordinate-to-normal remainder and the exact local blocker

Let $T_{rs}$ be the sum of (M-R-tail), (M-I-tail), and (M-T-tail), plus an
as-yet unavailable local term $T_{rs}^{\rm loc}$.  If the target and source
normal component bounds are $N_{t,x},N_{t,y},N_{s,x},N_{s,y}$, then the
coordinate remainders enter the four kernel constants through

$$
{\cal E}_{00}=T_{00},
$$

$$
{\cal E}_{10}=N_{t,x}T_{10}+N_{t,y}T_{01},
\qquad
{\cal E}_{01}=N_{s,x}T_{10}+N_{s,y}T_{01},
$$

$$
\begin{split}
{\cal E}_{11}={}&N_{t,x}N_{s,x}T_{20}
+(N_{t,x}N_{s,y}+N_{t,y}N_{s,x})T_{11}\\
&+N_{t,y}N_{s,y}T_{02}.
\end{split}
\tag{M-K-tail}
$$

The source-translation minus sign does not affect these absolute bounds.
Thus the reciprocal, omitted-image, retained-nonzero-image, and normal-weight
parts of the Ewald remainder are explicit and drift-free.

The first remaining term is local.  With

$$
z_0=h^2(X^2+Y^2),
$$

every nontrivial complex tube containing the real diagonal normally has
$\inf_{\mathcal D}\operatorname{Re}z_0<0$; a purely imaginary tangential
displacement already gives a negative leading real part.  Hence the integral
definition used in (M-E-bounds) cannot bound the $j=0$ image.  The object that
must be regularized before truncation is, up to the already fixed project
sign,

$$
{\cal C}_\eta(z)
=-\frac1{4\pi}\sum_{n=0}^\infty
\frac{\eta^n}{n!}E_{n+1}(z)
+\frac{\mathrm i}{4}H_0^{(1)}(2\sqrt{\eta z}).
\tag{M-local-cancel}
$$

The first unproved inequality is to construct a branch-free finite
${\cal C}_{\eta,N}^{\rm can}$ and prove

$$
\max_{r=0,1,2}\sup_{z\in Z_0}
\left|\partial_z^r
[\mathcal C_\eta(z)-\mathcal C_{\eta,N}^{\rm can}(z)]\right|
\le{\mathscr T}_{r,N}^{\rm loc}(\eta,Z_0),
\qquad {\mathscr T}_{r,N}^{\rm loc}\longrightarrow0.
\tag{M-local-first-blocker}
$$

Termwise truncation of Eq. (2.65) does not prove this: a finite $n$ sum
contains only a partial $J_0$ logarithmic coefficient and therefore does not
cancel the complete Hankel logarithmic branch.  The shortest repair is to use
the integer-order recurrence for $E_{n+1}$, extract the whole series

$$
\sum_{n=0}^\infty\frac{(-\eta z)^n}{(n!)^2}
=J_0(2\sqrt{\eta z}),
$$

cancel its $J_0\log z$ term analytically against the Hankel expansion, and
only then bound the factorial tail of the resulting entire series.  The next
subsection carries out this cancellation directly from the defining power
series and resolves (M-local-first-blocker).

### Branch-free local cancellation and factorial tail

The recurrence

$$
nE_{n+1}(z)=e^{-z}-zE_n(z)
$$

gives, by induction for $n\ge0$,

$$
E_{n+1}(z)
=\frac{(-z)^n}{n!}E_1(z)
+\frac{e^{-z}}{n!}
\sum_{j=0}^{n-1}(n-1-j)!(-z)^j,
\tag{M-L1}
$$

where the second sum is empty for $n=0$.  Define four entire series

$$
J_\eta(z)=\sum_{n=0}^\infty\frac{(-\eta z)^n}{(n!)^2},
\qquad
S(z)=\sum_{n=1}^\infty\frac{(-z)^n}{n\,n!},
$$

$$
D_\eta(z)=\sum_{n=1}^\infty
\frac{(-1)^nH_n(\eta z)^n}{(n!)^2},
$$

$$
Q_\eta(z)=\sum_{n=1}^\infty\frac{\eta^n}{(n!)^2}
\sum_{j=0}^{n-1}(n-1-j)!(-z)^j,
\tag{M-L2}
$$

where $H_n=\sum_{j=1}^n1/j$.  Equation (M-L1) yields

$$
H_\eta(z)=J_\eta(z)E_1(z)+e^{-z}Q_\eta(z).
\tag{M-L3}
$$

For completeness, the needed integer-order Hankel identity follows from the
defining series rather than an external tail theorem.  Start from

$$
J_\nu(w)=\sum_{n=0}^\infty
\frac{(-1)^n(w/2)^{2n+\nu}}
{n!\Gamma(n+\nu+1)},
$$

$$
Y_\nu(w)=
\frac{J_\nu(w)\cos(\pi\nu)-J_{-\nu}(w)}{\sin(\pi\nu)}.
$$

The series and its order derivative converge uniformly on compact subsets
away from the chosen logarithm cut.  Using
$\psi(n+1)=H_n-\gamma_E$ and taking the $\nu\to0$ limit gives

$$
Y_0(w)=\frac2\pi\left[
\left(\log\frac w2+\gamma_E\right)J_0(w)
-\sum_{n=1}^\infty
\frac{(-1)^nH_n(w^2/4)^n}{(n!)^2}
\right].
\tag{M-L4}
$$

Likewise, $E_1'(z)=-e^{-z}/z$ and the $z\to0$ constant give

$$
E_1(z)=-\gamma_E-\log z-S(z).
\tag{M-L5}
$$

Set $w=2\sqrt{\eta z}$.  Substitution of (M-L3)--(M-L5) into
(M-local-cancel) cancels every $\log z$ term and yields the branch-free
identity

$$
\boxed{
{\cal C}_\eta(z)
=\frac1{4\pi}J_\eta(z)
[S(z)-\log\eta-\gamma_E+\mathrm i\pi]
-\frac{e^{-z}}{4\pi}Q_\eta(z)
+\frac1{2\pi}D_\eta(z).
}
\tag{M-L6}
$$

Both sides initially agree off the cut; the right side is entire and hence is
the unique continuation across $z=0$ and the complex null cone.  The project
Green convention is the global negative of the Linton convention, which does
not change any $K_{pq}$ bound and must be applied exactly once in code.

Let $N\ge2$ and truncate each outer series in (M-L2) at $N$, giving
$J_{\eta,N},S_N,D_{\eta,N},Q_{\eta,N}$.  The canonical finite local part is

$$
\boxed{
{\cal C}_{\eta,N}^{\rm can}(z)
=\frac1{4\pi}J_{\eta,N}(z)
[S_N(z)-\log\eta-\gamma_E+\mathrm i\pi]
-\frac{e^{-z}}{4\pi}Q_{\eta,N}(z)
+\frac1{2\pi}D_{\eta,N}(z).
}
\tag{M-L7}
$$

This finite expression contains no $E_1,Y_0,H_0^{(1)}$, or $\log z$.  It is
therefore directly evaluable at $z=0$.

Suppose the local complex tube has $|z|\le R_0$ and choose any $B>R_0$.  Put

$$
x=\eta B,
\qquad x_Q=\eta(1+B),
\qquad c_\eta=\log\eta+\gamma_E-\mathrm i\pi.
$$

Require the four finite ratio gates

$$
\rho_J=\frac{x}{(N+2)^2}<1,
\qquad
\rho_S=\frac{B(N+1)}{(N+2)^2}<1,
$$

$$
\rho_D=\frac{x}{(N+2)^2}
\left(1+\frac1{N+2}\right)<1,
\qquad
\rho_Q=\frac{x_Q(N+1)}{(N+2)^2}<1.
\tag{M-L8}
$$

Termwise ratios and $H_{n+1}/H_n\le1+1/(n+1)$ give

$$
\tau_J=\frac{x^{N+1}}{((N+1)!)^2(1-\rho_J)},
$$

$$
\tau_S=\frac{B^{N+1}}
{(N+1)(N+1)!(1-\rho_S)},
$$

$$
\tau_D=\frac{H_{N+1}x^{N+1}}
{((N+1)!)^2(1-\rho_D)},
$$

$$
\tau_Q=\frac1{1+B}
\frac{x_Q^{N+1}}
{(N+1)(N+1)!(1-\rho_Q)}.
\tag{M-L9}
$$

The last inequality uses

$$
\sum_{j=0}^{n-1}(n-1-j)!B^j
\le(n-1)!(1+B)^{n-1}.
$$

Since $|J_\eta|\le e^{\eta B}$, $|S|\le e^B-1$, and
$|e^{-z}|\le e^B$ on $|z|\le B$, the complete local function remainder is

$$
\boxed{
\tau_C(N,B)=\frac1{4\pi}\left[
\tau_J(e^B-1+|c_\eta|)
+e^{\eta B}\tau_S+e^B\tau_Q
\right]+\frac{\tau_D}{2\pi}.
}
\tag{M-L10}
$$

Cauchy's formula on the concentric disks gives, for $r=0,1,2$,

$$
\boxed{
\sup_{|z|\le R_0}
|\partial_z^r({\cal C}_\eta-{\cal C}_{\eta,N}^{\rm can})|
\le\frac{r!}{(B-R_0)^r}\tau_C(N,B).
}
\tag{M-L11}
$$

This is the explicit quantity requested in (M-local-first-blocker), and it
tends to zero factorially.  For a finite-part enclosure define

$$
J_N^\#(B)=\sum_{n=0}^N\frac{(\eta B)^n}{(n!)^2},
\qquad
S_N^\#(B)=\sum_{n=1}^N\frac{B^n}{n\,n!},
$$

$$
D_N^\#(B)=\sum_{n=1}^N
\frac{H_n(\eta B)^n}{(n!)^2},
$$

$$
Q_N^\#(B)=\sum_{n=1}^N\frac{\eta^n}{(n!)^2}
\sum_{j=0}^{n-1}(n-1-j)!B^j.
$$

Then

$$
M_N(B)=\frac1{4\pi}J_N^\#(B)[S_N^\#(B)+|c_\eta|]
+\frac{e^B}{4\pi}Q_N^\#(B)+\frac1{2\pi}D_N^\#(B)
\tag{M-L12}
$$

satisfies $\sup_{|z|\le B}|{\cal C}_{\eta,N}^{\rm can}(z)|\le M_N(B)$.
Thus

$$
\sup_{|z|\le R_0}
|\partial_z^r{\cal C}_{\eta,N}^{\rm can}(z)|
\le\frac{r!M_N(B)}{(B-R_0)^r},
\qquad r=0,1,2.
\tag{M-L13}
$$

Finally let $L_r=r!\tau_C(N,B)/(B-R_0)^r$.  The local coordinate
truncation remainders are

$$
T_{00}^{\rm loc}=L_0,
$$

$$
T_{10}^{\rm loc}\le2h^2R_XL_1,
\qquad
T_{01}^{\rm loc}\le2h^2R_YL_1,
$$

$$
T_{20}^{\rm loc}\le4h^4R_X^2L_2+2h^2L_1,
$$

$$
T_{11}^{\rm loc}\le4h^4R_XR_YL_2,
$$

$$
T_{02}^{\rm loc}\le4h^4R_Y^2L_2+2h^2L_1.
\tag{M-L14}
$$

Adding (M-L14) to the reciprocal and nonzero-image tails closes every Ewald
truncation remainder through second coordinate order.  Equations (M-L12)--
(M-L13) enclose the local finite part.  Finite reciprocal and nonzero-image
terms still require their ordinary special-function evaluations to be
enclosed, but this is a finite, explicitly specified computation rather than
an unknown kernel norm.  Therefore the general regular-image $K_{pq}$ theorem
is `CONDITIONAL GO`: its remaining conditions are the finite complex-tube
geometry, ratio, non-Wood, normal, and finite-evaluation enclosures.  This
does not close the independent local free-space singular-panel action
(M-local-strip).

## Frozen circular specialization of the conditional reduction

Complexify the target angle only:

$$
x(z)=c+R(\cos z,\sin z),
\qquad
\nu(z)=(\cos z,\sin z).
$$

For a frozen state map $A$, define the row-valued regular action

$$
\mathcal J_\beta^{\nu\nu}(z;A)
=R\int_0^{2\pi}
\left\{
\nu(z)^{\mathsf T}
[\nabla_x\nabla_{x'}H_\beta(x(z),x(\varphi))]
\nu(\varphi)t_\tau(\varphi;A)
+\nu(z)\mathbin\cdot\nabla_xH_\beta(x(z),x(\varphi))
t_\sigma(\varphi;A)
\right\}d\varphi.
$$

An overall sign change caused by a source-normal convention does not change
the bound.  A frozen-instance evaluator must choose a geometrically admissible
$a>0$ and compute a finite number, from frozen data alone, such that

$$
\sup_{|\operatorname{Im}z|\le a}
\|\mathcal J_\beta^{\nu\nu}(z;A)\|_2
\le A_{\mathrm{reg}}^\nu(A,a).
\tag{*}
$$

The general Ewald theorem above supplies a conditional algorithm for (*).
Its finite implementation must use the outgoing/decaying branch, retain every
near-Wood $1/\gamma_m$, and keep the $\gamma_m^2$,
$\gamma_m\beta_m$, and $\beta_m^2$ factors created by mixed normal
derivatives.  A value-kernel strip bound does not imply (*), and target-normal
differentiation is not target-angle tangential differentiation.  The circle
formulas in this specialization are not used to prove the general theorem.

## Conditional finite part and tail

Let

$$
A_{\mathrm{tot}}^\nu(A,a)
=A_{\mathrm{off}}^\nu(A,a)+A_{\mathrm{reg}}^\nu(A,a).
$$

If (*) holds, contour shifting gives

$$
\|j_{\Upsilon,\ell}(A)\|_2
\le\sqrt{2\pi R}\,A_{\mathrm{tot}}^\nu(A,a)e^{-a|\ell|}.
$$

Set $r=e^{-2a}$, $N=L+1$, and take $L$ no smaller than the finite
free-circle support.  The high-angular tail for one state map is

$$
\sum_{|\ell|>L}
\frac{\|j_{\Upsilon,\ell}(A)\|_2^2}
{\underline\vartheta_\ell}
\le\mathcal C_\Upsilon(A,a,L)^2,
$$

$$
\mathcal C_\Upsilon(A,a,L)^2
=\frac{4\pi R^2A_{\mathrm{tot}}^\nu(A,a)^2}
{\underline r_c\tanh(N\delta_c/R)}
\frac{r^N}{N(1-r)}.
$$

For each retained propagated row and the vector of fixed center-circle
singletons require

$$
\|\ell_{\varsigma,\ell}^\Upsilon
-\widetilde\ell_{\varsigma,\ell}^\Upsilon\|_2
\le\epsilon_{\varsigma,\ell}^\Upsilon,
\qquad
\|j_{0,\ell}^{\Upsilon,\mathrm{sing}}
-\widetilde j_{0,\ell}^{\Upsilon,\mathrm{sing}}\|_2
\le\epsilon_{0,\ell}^\Upsilon.
$$

The same strip bound supplies a periodic-trapezoid remainder.  With $N_q$
nodes, the normalized coefficient error is bounded by

$$
\epsilon_{\varsigma,\ell}^{\mathrm{quad}}
\le\sqrt{\frac{R}{2\pi}}
\frac{4\pi A_{\mathrm{tot}}^\nu(A,a)e^{|\ell|a}}
{e^{aN_q}-1},
$$

to which any explicit finite special-function evaluation enclosure is added
once.  Define

$$
\overline\omega_{\varsigma,L}^\Upsilon
=\sum_{|\ell|\le L}
\frac{(\|\widetilde\ell_{\varsigma,\ell}^\Upsilon\|_2
+\epsilon_{\varsigma,\ell}^\Upsilon)^2}
{\underline\vartheta_\ell}.
$$

Let $\mathcal C_{\Upsilon,\varsigma}(L)$ be the preceding high-angular
constant for the side-$\varsigma$ state map, and let
$\mathcal C_{\Upsilon,0}(L)$ be the same constant for all fixed center-circle
singletons, combined as a direct sum over distinct circles.  The complete
finite part is

$$
\overline F_{L,J}^{\Upsilon\,2}
=\sum_{|\ell|\le L}\frac1{\underline\vartheta_\ell}
\left[
(\|\widetilde j_{0,\ell}^{\Upsilon,\mathrm{sing}}\|_2
+\epsilon_{0,\ell}^\Upsilon)^2
+\sum_{\varsigma\in\{-,+\}}\sum_{n=0}^{J-1}
\left(
\|\widetilde\ell_{\varsigma,\ell}^\Upsilon
P_\varsigma^nc_\varsigma\|_2
+\epsilon_{\varsigma,\ell}^\Upsilon
\|P_\varsigma^nc_\varsigma\|_2
\right)^2
\right].
$$

With Lyapunov certificates, the complete omission tail is

$$
T_{L,J}^{\Upsilon\,2}
=\mathcal C_{\Upsilon,0}(L)^2
+\sum_{\varsigma\in\{-,+\}}
\left[
\overline\omega_{\varsigma,L}^\Upsilon
(P_\varsigma^Jc_\varsigma)^*Y_\varsigma
(P_\varsigma^Jc_\varsigma)
+\mathcal C_{\Upsilon,\varsigma}(L)^2
c_\varsigma^*Y_\varsigma c_\varsigma
\right].
$$

For the block-power alternative, define $K_\varsigma$ as in
`s-wall-tail.md` and replace the two quadratic forms in each side summand by

$$
K_\varsigma\|P_\varsigma^Jc_\varsigma\|_2^2,
\qquad
K_\varsigma\|c_\varsigma\|_2^2,
$$

respectively.  The singleton, retained-cell, propagated-cell, and angular
index sets are disjoint.  The coefficient enclosures and the whole-matrix
summation therefore prove

$$
B_\Upsilon
\le\sqrt{\overline F_{L,J}^{\Upsilon\,2}
+T_{L,J}^{\Upsilon\,2}}
\le\overline F_{L,J}^\Upsilon+T_{L,J}^\Upsilon.
$$

The stopping rule is fixed before evaluation: meet assigned finite-row
remainder budgets and require $T_{L,J}^\Upsilon\le\tau_\Upsilon$.  No
inter-level drift enters it.

## Verdict

The general material trace inequality, its explicit high-mode weight, the
general finite-wall-support action, half-guide summation, conditional finite
part, and consequences of the unified $K_{pq}$ bounds are established by the
displayed elementary estimates.  The Ewald reciprocal, omitted nonzero-image,
retained nonzero-image Taylor, and branch-free local remainders are explicit
through second coordinate order.  Hence the general regular-image $K_{pq}$
construction is `CONDITIONAL GO`; only the finite certificates listed after
(M-L14) remain.  The local free-space theorem in `s-local-panel.md` is
also `CONDITIONAL GO`: its only missing quantities are the finite
divided-difference and retained-panel enclosures.  Combining the two by
(M-local-combine) makes the complete shape-general $B_\Upsilon$ module
`CONDITIONAL GO`, not an instantiated bound.  The finite wall action also requires
(M-off-geometry), (M-off-clearance), and (M-off-arclength).  The current circle
satisfies these geometric gates for a sufficiently narrow strip, but no
circle diagonalization is used to replace the general local algorithm.

The shortest next step is one shape-general evaluator implementing the finite
local-panel, Ewald, off-surface, and retained-row enclosures, followed by the
existing Lyapunov/block-power sum.  A 256--512 action difference, observed
angular decay, or smooth-looking trace cannot replace those enclosures.  This
note does not bound $B_{\Gamma_\pm}$,
$B_{\mathrm{lift}}$, or the total $\|R\|_{\mu,*}$.
