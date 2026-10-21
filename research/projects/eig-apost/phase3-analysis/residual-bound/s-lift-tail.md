# Value-defect lifting: explicit weights and the first unresolved tail

## Target and local notation

This note treats only the value-defect contribution
$B_{\mathrm{lift}}$ to the continuous residual numerator.  It uses the
common symbols in this directory's `README.md` without redefining them.  New
local symbols are the material wavenumber
$\kappa_e=\widehat k\sqrt{\rho_e}$, the wall and material collar widths
$\delta_w,\delta_c$, the general tubular constants
$C_0^{\rm tub},C_1^{\rm tub},e_\ell^{\rm tub}$, the
cubic profile $\chi$, the wall lifting weight $e_m^w$, the circle lifting
weight $e_\ell^\Upsilon$, its upper-bound constants $C_0,C_2$, the wall-mode
cutoff $M$, the residual Fourier cutoff $L$ retaining $|\ell|<L$, the finite
energy part $F_{M,L}^{\mathrm{lift}}$, the omitted
energy tail $T_{M,L}^{\mathrm{lift}}$, the general off-surface rows
$q_{0,w,\ell}$ and their bound $C_{0,w}$, and the regular-image strip constant
$A_a$.  The omitted-mode sections use the finite wall support $\mathcal I_w$,
its exact row amplitudes $h_{\Upsilon,m}$ and source-side signs $s_m$, the
off-surface strip bound $B_{\Upsilon,\mathrm{off}}$, and the corresponding
energy tails $T_w,T_{\Upsilon,\mathrm{off}},T_{\Upsilon,\mathrm{reg}}$, all
defined at their first display.  In particular, $\Gamma_\pm$ remain artificial
interfaces and $\Upsilon$ remains the material interface.

The outcome is `CONDITIONAL GO` for the complete
$B_{\mathrm{lift}}$ module under the required shape-general proof.  The
lifting operator and its all-mode weights are explicit; both the regular-image
self-value action and the general local free-space panel now have conditional
finite algorithms.  Their finite constants have not been instantiated.
Positive distance closes the remaining off-surface actions.

## Strong residual route

The raw exact-kernel field has the value defects $a_{\Sigma,r}$ and
$a_\Upsilon$ defined in the topic `README.md`.  Let $e$ be the correction
constructed below.  It makes $\widehat u=u_{h,M}+e$ continuous while leaving
the normal-defect modules assigned to the raw field.  Its complete weak
contribution is

$$
R_{\mathrm{lift}}(v)=a(e,v)-\mu b(e,v),
\qquad v\in V_\beta.
$$

The Cauchy--Schwarz and triangle inequalities give the deliberately safe
bound

$$
|R_{\mathrm{lift}}(v)|
\le 2\|e\|_\mu\|v\|_\mu,
\qquad
B_{\mathrm{lift}}:=2\|e\|_\mu.
$$

Thus this module needs an upper bound for the energy of the explicitly
constructed correction, not an unknown trace or exact-solution norm.

## General-boundary tubular lifting theorem

Let $\Lambda$ be an embedded closed $C^3$ material interface with perimeter
$P_\Lambda$, parameterized by arclength

$$
{\boldsymbol r}:\mathbb R/P_\Lambda\mathbb Z\longrightarrow\Lambda,
\qquad |{\boldsymbol r}'(s)|=1.
$$

Assume that the union of the material interfaces under consideration has
reach at least $r_*>0$ and that

$$
|\kappa(s)|\le\kappa_*
$$

for the signed curvature.  Choose two collar widths
$0<h_\pm<r_*$ such that

$$
\theta_\pm:=1-h_\pm\kappa_*>0,
\qquad
\Theta_\pm:=1+h_\pm\kappa_*.
$$

Then the two normal-coordinate maps

$$
F_\pm(s,t)={\boldsymbol r}(s)\pm t\nu(s),
\qquad 0\le t\le h_\pm,
$$

are injective on the selected collars, the collars of distinct components
are disjoint, and their Jacobians $J_\pm$ satisfy

$$
\theta_\pm\le J_\pm(s,t)\le\Theta_\pm.
$$

The injectivity and disjointness are explicit hypotheses supplied by the
reach bound; no star-shaped or convexity condition is used.

Let $\chi\in C^1([0,1])$ satisfy

$$
\chi(0)=1,
\qquad \chi(1)=\chi'(0)=\chi'(1)=0,
$$

and put

$$
I_0=\int_0^1|\chi(t)|^2\,dt,
\qquad
I_1=\int_0^1|\chi'(t)|^2\,dt.
$$

For $a\in H^1(\Lambda)$, define

$$
(E_\pm a)(F_\pm(s,t))
=c_\pm a(s)\chi(t/h_\pm),
\qquad c_+-c_-=-1.
$$

Thus the difference between the two traces of $Ea=(E_+a,E_-a)$ is $-a$.
The normal derivative of the correction vanishes both at the material
interface and at the safe collar rims.
If $0<\rho\le\overline\rho_\pm$ on the two collars, define

$$
C_0^{\rm tub}
=\sum_{q\in\{-,+\}}|c_q|^2\Theta_q
\left(\frac{I_1}{h_q}
+\mu\overline\rho_qh_qI_0\right),
$$

$$
C_1^{\rm tub}
=\sum_{q\in\{-,+\}}|c_q|^2
\frac{h_qI_0}{\theta_q}.
$$

**Theorem (general-boundary tubular lifting right inverse).**
Under the preceding hypotheses, $E:H^1(\Lambda)\to
H^1(U_+)\times H^1(U_-)$ is a right inverse for the negative trace jump and

$$
\|Ea\|_\mu^2
\le C_0^{\rm tub}\|a\|_{L^2(\Lambda)}^2
+C_1^{\rm tub}\|\partial_sa\|_{L^2(\Lambda)}^2.
\tag{T-lift}
$$

**Proof.**  In the coordinates $(s,t)$ the metric is diagonal.  Directly,

$$
\begin{split}
\|E_qa\|_\mu^2
=|c_q|^2\int_0^{P_\Lambda}\int_0^{h_q}
\bigg[&
J_q\frac{|a|^2}{h_q^2}|\chi'(t/h_q)|^2
+J_q^{-1}|\partial_sa|^2|\chi(t/h_q)|^2\\
&+\mu\rho J_q|a|^2|\chi(t/h_q)|^2
\bigg]dt\,ds.
\end{split}
$$

Insert $J_q\le\Theta_q$, $J_q^{-1}\le\theta_q^{-1}$ and
$\rho\le\overline\rho_q$, then scale $t=h_q\widehat t$.  Summing the two
disjoint collars gives (T-lift).  The trace identity follows from
$\chi(0)=1$ and $c_+-c_-=-1$; the two zero-normal statements follow from
$\chi'(0)=\chi'(1)=0$.  $\square$

Use the arclength Fourier basis

$$
\varphi_\ell(s)=P_\Lambda^{-1/2}e^{\mathrm i\xi_\ell s},
\qquad \xi_\ell=\frac{2\pi\ell}{P_\Lambda}.
$$

If $a=\sum_\ell a_\ell\varphi_\ell$, (T-lift) gives the explicit all-mode
upper weights

$$
e_\ell^{\rm tub}=C_0^{\rm tub}+C_1^{\rm tub}\xi_\ell^2.
\tag{T-weight}
$$

Suppose further that $a(s)$ extends holomorphically to
$|\operatorname{Im}s|\le a_*$ and is bounded there by $A_*$.  Contour
shifting gives

$$
|a_\ell|\le\sqrt{P_\Lambda} A_*
e^{-2\pi a_*|\ell|/P_\Lambda}.
$$

For the first omitted residual order $L$ and
$r_a=e^{-4\pi a_*/P_\Lambda}$, put

$$
S_0(L,r_a)=\frac{r_a^L}{1-r_a},
$$

$$
S_2(L,r_a)=r_a^L\left[
\frac{L^2}{1-r_a}
+\frac{2Lr_a}{(1-r_a)^2}
+\frac{r_a(1+r_a)}{(1-r_a)^3}
\right].
$$

Then the omitted lifting energy satisfies

$$
\sum_{|\ell|\ge L}e_\ell^{\rm tub}|a_\ell|^2
\le2P_\Lambda A_*^2\left[
C_0^{\rm tub}S_0(L,r_a)
+C_1^{\rm tub}\left(\frac{2\pi}{P_\Lambda}\right)^2S_2(L,r_a)
\right].
\tag{T-tail}
$$

This is a geometry-explicit right-inverse and tail theorem.  It uses only
$P_\Lambda$, the supplied reach and curvature bounds, collar widths, material upper
bounds, $\mu$, and the fixed profile.  For several interfaces, apply it on
the disjoint collars componentwise; propagated state maps are summed by the
same Lyapunov or block-power certificate used elsewhere in this topic.
No external theorem is invoked: the proof uses only the displayed tubular
metric identity, one-dimensional integration, Parseval, and a contour shift.

## Frozen flat-wall and circular specialization

Put

$$
\chi(t)=1-3t^2+2t^3,
\qquad 0\le t\le1.
$$

Direct polynomial integration gives

$$
\int_0^1|\chi'(t)|^2\,dt=\frac65,
\qquad
\int_0^1|\chi(t)|^2\,dt=\frac{13}{35}.
$$

For one side of an artificial interface, with inward collar coordinate
$0\le s\le\delta_w$, lift a value defect $a(y)$ by

$$
e_w(s,y)=-a(y)\chi(s/\delta_w).
$$

If $a=\sum_m a_m\psi_m$ and the collar material is $\rho_e$, Parseval gives
the exact mode energy

$$
\|e_w\|_\mu^2
=\sum_{m\in\mathbb Z}e_m^w|a_m|^2,
\qquad
e_m^w
=\frac{6}{5\delta_w}
+\frac{13\delta_w}{35}(\beta_m^2+\mu\rho_e).
$$

The two defects $a_{\Sigma,1}$ and $a_{\Sigma,2}$ are lifted in their
respective nonoverlapping collars and are squared separately.  They are not
cancelled against one another.

On a circular component of $\Upsilon$ with radius $R$, write

$$
a_\Upsilon(\theta)
=\sum_{\ell\in\mathbb Z}a_{\Upsilon,\ell}
(2\pi R)^{-1/2}e^{\mathrm i\ell\theta}.
$$

Use half-amplitude lifts in the exterior and interior collars,

$$
e_{\mathrm{out}}(r,\theta)
=-\tfrac12a_\Upsilon(\theta)
\chi\!\left(\frac{r-R}{\delta_c}\right),
$$

$$
e_{\mathrm{in}}(r,\theta)
=+\tfrac12a_\Upsilon(\theta)
\chi\!\left(\frac{R-r}{\delta_c}\right).
$$

Assume $0<\delta_c<R$ and put
$r_{\mathrm{out}}(t)=R+\delta_ct$ and
$r_{\mathrm{in}}(t)=R-\delta_ct$.  For one angular mode the exact two-collar energy
weight is

$$
e_\ell^\Upsilon
=\frac14\sum_{p\in\{\mathrm{in},\mathrm{out}\}}
\int_0^1
\left[
\frac{r_p(t)}{R\delta_c}|\chi'(t)|^2
+\delta_c\left(
\frac{\ell^2}{Rr_p(t)}
+\mu\rho_p\frac{r_p(t)}R
\right)|\chi(t)|^2
\right]dt.
$$

Because $r_{\mathrm{out}}(t)+r_{\mathrm{in}}(t)=2R$, and with
$\rho_{\max}=\max(\rho_{\mathrm{in}},\rho_{\mathrm{out}})$, this has the
explicit all-mode bound

$$
e_\ell^\Upsilon\le C_0+C_2\ell^2,
$$

$$
C_0=\frac{3}{5\delta_c}
+\frac{13\mu\rho_{\max}\delta_c}{70},
\qquad
C_2=\frac{13\delta_c}{70(R^2-\delta_c^2)}.
$$

No empirical annulus ODE or finite-mode maximum is needed for this safe
bound.  Since the frozen collars are mutually disjoint, their squared
energies add.

## Finite part

Suppose finite coefficient enclosures have been computed,

$$
|a_{\Sigma,r,m}-\widetilde a_{\Sigma,r,m}|
\le\epsilon_{\Sigma,r,m},
\qquad |m|\le M,
$$

$$
|a_{\Upsilon,\ell}-\widetilde a_{\Upsilon,\ell}|
\le\epsilon_{\Upsilon,\ell},
\qquad |\ell|<L.
$$

The finite computed upper part of the lifting energy is

$$
F_{M,L}^{\mathrm{lift}\,2}
=\sum_{\Sigma,r}\sum_{|m|\le M}
e_m^w
(|\widetilde a_{\Sigma,r,m}|+\epsilon_{\Sigma,r,m})^2
+\sum_\Upsilon\sum_{|\ell|<L}
e_\ell^\Upsilon
(|\widetilde a_{\Upsilon,\ell}|+\epsilon_{\Upsilon,\ell})^2.
$$

This is finite algebra once the value rows receive analytic quadrature or
special-function enclosures.  The old inter-level action drift cannot serve
as any $\epsilon$.

## Omitted wall modes

For a separated material-boundary-to-wall value action, the general theorem
in `s-wall-tail.md` supplies a strict high-Rayleigh bound without requiring a
circle.  With $\gamma_m=\mathrm i\kappa_m$ and density constants
$A_\tau,A_\sigma$ formed as in the artificial-interface note,

$$
|a_m|
\le\frac{e^{-\kappa_m\delta}}{2\kappa_m\sqrt d}
\left[(\kappa_m+|\beta_m|)A_\tau+A_\sigma\right].
$$

Let $M_+=M+1$, $q_0=2\pi/d$,
$t_{M_+}=q_0M_+-|\beta|>\kappa_e$,
$\kappa_{M_+}=\sqrt{t_{M_+}^2-\kappa_e^2}$, and
$r=e^{-2\delta q_0}$.
Then

$$
H_{M_+}=\left(1+\frac{t_{M_+}}{\kappa_{M_+}}\right)A_\tau
+\frac{A_\sigma}{\kappa_{M_+}},
$$

and, with

$$
S_j(M_+,r)=\sum_{n=M_+}^\infty n^jr^n,
\qquad j=0,1,2,
$$

the explicit formulas are

$$
S_0=\frac{r^{M_+}}{1-r},
\quad
S_1=r^{M_+}\left(\frac{M_+}{1-r}+\frac r{(1-r)^2}\right),
$$

$$
S_2=r^{M_+}\left(
\frac{M_+^2}{1-r}+\frac{2M_+r}{(1-r)^2}
+\frac{r(1+r)}{(1-r)^3}
\right).
$$

Writing

$$
C_w^0=\frac6{5\delta_w}+\frac{13\delta_w\mu\rho_e}{35},
\qquad C_w^2=\frac{13\delta_w}{35},
$$

gives the computable one-defect tail

$$
\sum_{|m|>M}e_m^w|a_m|^2
\le\frac{e^{2\delta(\kappa_e+|\beta|)}H_{M_+}^2}{2d}
\left[
C_w^0S_0+C_w^2
(q_0^2S_2+2q_0|\beta|S_1+\beta^2S_0)
\right].
$$

For propagated state maps, replace $A_\tau,A_\sigma$ by their operator
bounds and sum $\|P_\varsigma^nc_\varsigma\|_2^2$ using the same Lyapunov or
block-power certificate as in `s-wall-tail.md`.  This closes only the
off-surface wall contribution.

## General finite-wall support on a material boundary

The shape-general finite-wall-support lemma in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail#General off-surface wall-to-boundary action]]
applies here with $p=0$.  Its curve speed branch, signed complex clearance,
non-Wood retained modes, and signed arclength-strip gates are
(M-off-geometry), (M-off-clearance), and (M-off-arclength).  It gives retained
arclength Fourier rows $q_{0,w,\ell}$ with the explicit finite quadrature
remainder (M-off-quad), and

$$
\|q_{0,w,\ell}(A)\|_2
\le C_{0,w}(A,a)e^{-|\xi_\ell|\sigma_a}.
$$

For the first omitted residual order $L$ and
$r_a=e^{-4\pi\sigma_a/P_\Lambda}$, the complete high-boundary-mode lifting
tail of this action is therefore

$$
\sum_{|\ell|\ge L}e_\ell^{\rm tub}
\|q_{0,w,\ell}(A)\|_2^2
\le2C_{0,w}(A,a)^2\left[
C_0^{\rm tub}S_0(L,r_a)
+C_1^{\rm tub}\left(\frac{2\pi}{P_\Lambda}\right)^2S_2(L,r_a)
\right].
\tag{T-off-tail}
$$

Every retained row is widened once by $\epsilon_{0,w,\ell}^{\rm tgt}$ from
(M-off-quad).  Different physical sources in the same value defect are
combined by the weighted $\ell^2$ triangle inequality, not by an assumed
orthogonality or observed cancellation.  For the center/singleton map and the
side maps $P_\varsigma^nc_\varsigma$, the same Lyapunov or block-power
certificate as in `s-wall-tail.md` sums the propagated cells.  Consequently
the general finite-wall-support action is closed once its finite geometric
and denominator gates pass; it does not share the regular-image kernel
remainder below.

For a general boundary the material part of the finite lifting energy uses

$$
\overline F_{L}^{\rm tub\,2}
=\sum_{|\ell|<L}e_\ell^{\rm tub}
(\|\widetilde a_{\Upsilon,\ell}\|_2
+\epsilon_{\Upsilon,\ell})^2.
\tag{T-general-finite}
$$

Formula (T-general-finite) replaces, rather than supplements, the circular
material summand in $F_{M,L}^{\mathrm{lift}}$; thus no value defect is counted
twice.

## General-boundary regular-image value corollary

The unified general-boundary regular-image theorem in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail#Unified general-boundary regular-image theorem]]
applies here with target-normal order $p=0$.  In that notation the regular
value action is

$$
{\cal R}_0(z;A)
=\int_\Lambda\left[
D_{\nu',x'}H_\beta({\boldsymbol r}(z),{\boldsymbol r}(s'))
t_\tau(s';A)
+H_\beta({\boldsymbol r}(z),{\boldsymbol r}(s'))t_\sigma(s';A)
\right]ds'.
$$

If the unified constants $K_{01}(a_*)$ and $K_{00}(a_*)$ are available, then

$$
\sup_{|\operatorname{Im}z|\le a_*}\|{\cal R}_0(z;A)\|_2
\le A_{0,{\rm reg}}(A,a_*)
:=K_{01}(a_*)A_\tau(A)+K_{00}(a_*)A_\sigma(A).
\tag{T-K0}
$$

Add, by the triangle inequality, the corresponding strip constants for every
off-surface source and for the local free-space panel action.  Calling the
sum $A_{0,{\rm tot}}$, formula (T-tail) supplies the omitted lifting-energy
bound with $A_*=A_{0,{\rm tot}}$.

For a noncircular boundary, the local free-space single- and double-layer
operators are not diagonal in arclength Fourier coordinates.  A finite
density therefore does not have finite output support.  Before the preceding
corollary closes the complete tail, a panelwise proof must subtract the local
logarithmic singularity analytically, integrate its explicit template, and
give a certified strip or derivative remainder for the regular panel part.
In particular it must supply a finite number satisfying

$$
\sup_{|\operatorname{Im}z|\le a_*}
\|{\cal L}^{\rm loc}_0(z;A)\|_2
\le A_{0,{\rm loc}}(A,a_*).
\tag{T-local-gate}
$$

Neither a circular diagonal multiplier nor observed angular decay proves
(T-local-gate).  Instead, the shape-general real-axis theorem in
`s-local-panel.md` subtracts the periodic logarithm, encloses retained rows,
and proves the identity-inclusive algebraic lifting tail (P29).  Thus the
local part is `CONDITIONAL GO` without assuming a complex strip for the
logarithmic action.  Its separate finite-wall-support action is already
covered by (T-off-tail), subject only to the explicit finite curve gates
stated there.

The explicit Ewald estimates (M-R-tail), (M-I-tail), (M-T-tail), and
(M-L10)--(M-L14) in `s-material-tail.md` apply to $K_{00}$ and $K_{01}$.
They make the regular-image value action `CONDITIONAL GO`, subject to the
listed finite enclosures.  This is independent of (T-local-gate), which may
not be inferred from sampled self-action values.

For each state map let $T_{\Upsilon,\mathrm{loc}}$ be the square root of
(P29), and let $T_{\Upsilon,\mathrm{an}}$ combine the regular-image and
off-surface value tails.  They belong to the same value defect and therefore
enter the lifting energy by

$$
T_{\Upsilon,\mathrm{all}}
\le T_{\Upsilon,\mathrm{loc}}+T_{\Upsilon,\mathrm{an}}.
\tag{T-local-combine}
$$

The corresponding retained local, regular-image, off-surface, and identity
rows are added before multiplication by $e_\ell^{\rm tub}$.  No orthogonality
or observed cancellation is used.

## Frozen circular specialization

With the draft-compatible density coordinate
$\eta=(\tau,-\sigma)^{\mathsf T}$, the circle value defect decomposes as

$$
a_\Upsilon
=(I+K_e^{QP}-K_i)\tau
+(S_e^{QP}-S_i)\sigma
+A_{w\to\Upsilon}^{\mathrm{value}}\xi.
$$

Here $\sigma$ denotes the actual single-layer density in the reconstructed
field.  The frozen artifact stores $-\sigma$ as its second coordinate; code
must change the sign exactly once at that input boundary.

The identity and same-center free-space $S/K$ actions preserve the finite
angular support of the frozen trigonometric densities.  The wall-to-circle
term is off surface and has a finite explicit strip bound.  Indeed, after
including the center-to-circle phase in the finite row amplitude, write its
frozen Rayleigh representation as

$$
a_{\Upsilon,\mathrm{off}}(\theta;A)
=\sum_{m\in\mathcal I_w}h_{\Upsilon,m}(A)
\exp\!\left(
-\mathrm i s_m\gamma_mR\cos\theta
+\mathrm i\beta_mR\sin\theta
\right),
$$

where $\mathcal I_w$ is the finite support of the frozen wall densities,
$s_m\in\{-1,+1\}$ records which wall is the source, and every factor
$1/\gamma_m$ is included in $h_{\Upsilon,m}$.  The retained non-Wood gate
makes all these amplitudes finite.  For $|\operatorname{Im}\theta|\le a$,
define the branch-correct exponent

$$
\chi_m(a)=
\begin{cases}
R(|\gamma_m|+|\beta_m|)\sinh a,
&\gamma_m\in\mathbb R,\\
R(\kappa_m\cosh a+|\beta_m|\sinh a),
&\gamma_m=\mathrm i\kappa_m,\ \kappa_m>0.
\end{cases}
$$

Then

$$
B_{\Upsilon,\mathrm{off}}(A,a)
:=\sum_{m\in\mathcal I_w}
\|h_{\Upsilon,m}(A)\|_2
e^{\chi_m(a)}
$$

is therefore a computable bound for the strip supremum.  The evanescent case
retains $e^{\kappa_mR}$ at $a=0$; the earlier expression with only
$\kappa_mR\sinh a$ was not an upper bound and is not used.  Contour shifting and
the circle lifting weights give

$$
T_{\Upsilon,\mathrm{off}}
=\sqrt{4\pi R}\,B_{\Upsilon,\mathrm{off}}(A,a)
\sqrt{C_0S_0^a+C_2S_2^a}.
$$

For propagated state maps, the row norms in this finite sum combine with the
same whole-matrix propagation certificate already used above.  Thus this
off-surface contribution has no unassigned analytic remainder.  The remaining
action uses

$$
H_\beta=G_e^{QP}-G_e^{\mathrm{free}}.
$$

For a frozen state map $A$, define

$$
\mathcal H_\beta(\theta;A)
=\int_\Upsilon
\left[
\partial_{\nu'}H_\beta(x(\theta),x')t_\tau(x';A)
+H_\beta(x(\theta),x')t_\sigma(x';A)
\right]ds'.
$$

The first unresolved inequality is: choose a geometrically admissible
$a>0$ and compute, without an empirical safety factor, a finite $A_a$ such
that

$$
\sup_{|\operatorname{Im}\theta|\le a}
\|\mathcal H_\beta(\theta;A)\|_2\le A_a.
\tag{*}
$$

The bound must cover every nonzero periodic image, or an equivalent Ewald or
Rayleigh remainder, with the outgoing branch and all small denominators
checked.  Current frozen artifacts and project proofs do not provide such an
$A_a$.

If (*) were supplied, contour shifting would give

$$
|a_{\Upsilon,\ell}|
\le\sqrt{2\pi R}\,A_a e^{-a|\ell|}
$$

for this regular-image component.  With $r_a=e^{-2a}$, define

$$
S_0^a=\frac{r_a^L}{1-r_a},
$$

$$
S_2^a=r_a^L\left[
\frac{L^2}{1-r_a}
+\frac{2Lr_a}{(1-r_a)^2}
+\frac{r_a(1+r_a)}{(1-r_a)^3}
\right].
$$

The omitted regular-image circle lifting energy would then satisfy

$$
\sum_{|\ell|\ge L}e_\ell^\Upsilon|a_{\Upsilon,\ell}|^2
\le4\pi R A_a^2(C_0S_0^a+C_2S_2^a).
$$

Let $T_w^2$ be the sum of the explicit artificial-wall collar tails above.
For each material circle, let $T_{\Upsilon,\mathrm{off}}$ be an energy-norm
bound for all its omitted positive-distance sources, and put

$$
T_{\Upsilon,\mathrm{reg}}
=\sqrt{4\pi R}\,A_a
\sqrt{C_0S_0^a+C_2S_2^a}.
$$

The off-surface and regular-image fields occupy the same circle collar and
need not be orthogonal, so combine them by the triangle inequality.  Under
(*), define

$$
T_{M,L}^{\mathrm{lift}\,2}
=T_w^2
+\sum_\Upsilon
(T_{\Upsilon,\mathrm{off}}+T_{\Upsilon,\mathrm{reg}})^2.
$$

The finite and omitted index sets are disjoint and the lift collars are
disjoint.  The preceding triangle inequality handles nonorthogonal sources
within one circle collar.  Therefore the coefficient enclosures, Parseval,
and the explicit weights prove the conditional chain

$$
B_{\mathrm{lift}}
\le2\sqrt{
F_{M,L}^{\mathrm{lift}\,2}+T_{M,L}^{\mathrm{lift}\,2}}
\le2\left(F_{M,L}^{\mathrm{lift}}+T_{M,L}^{\mathrm{lift}}\right).
$$

This circular specialization tends to zero geometrically and supplies its own
drift-free stopping rule:
increase $L$ until the displayed right-hand side is below a preassigned
circle-tail tolerance.  It is retained only as an audit of the frozen input;
the governing shape-general proof instead uses (T-local-combine), including
the algebraic local tail (P29), and does not rely on circular diagonal support.

## Verdict and shortest next step

Established here are the strong-residual assignment, the general tubular
right inverse and its arclength-Fourier tail, the cubic wall weight, the
all-angular-mode circle specialization, the off-surface wall tail, and the
exact consequence of a regular-image strip bound.  The regular-image
$K_{0q}$ action is now `CONDITIONAL GO` by the Ewald construction in
`s-material-tail.md`.  The shape-general local free-space action is also
`CONDITIONAL GO` by (P11)--(P29) of `s-local-panel.md`.  Combining
them by (T-local-combine) makes the complete module `CONDITIONAL GO`,
not an instantiated bound.  The circle diagonal action is not used.

For a general boundary, the geometric lifting theorem is `ESTABLISHED`, while
the complete tail awaits finite implementation of the local-panel and unified
$K_{0q}$ bounds.  The finite-wall-support part also
requires the explicit, independently checkable curve gates
(M-off-geometry), (M-off-clearance), and (M-off-arclength).  The current circle
satisfies those geometric gates for a sufficiently narrow strip, but the
self-action constants are not supplied by the current artifacts.

The shortest next step is a single shape-general finite evaluator for the
local-panel and Ewald certificates.  All analytic truncation tails are
explicit.  Resolution
agreement, a Fourier plateau, FEM/BIE
agreement, or ordinary numerical stability cannot replace (*).  Nothing in
this note bounds $B_\Upsilon$, $B_{\Gamma_\pm}$, or the total
$\|R\|_{\mu,*}$.

## I5.1g superseding minimum-energy lifting theorem

This section supersedes only the lifting constant and the arbitrary-profile
collar weights used earlier in this file.  It does not change the strong
residual decomposition, the frozen reconstruction, or any normal-defect
module.  In particular, the factor $2$ in the earlier definition of
$B_{\mathrm{lift}}$ is replaced by the sharp product-space
Cauchy--Schwarz factor $1$ proved below.  The theorem is shape general; the
current circle is only one admissible input geometry.

### Simultaneous jump quotient and the factor one

Let $\{\Omega_r\}_{r\in\mathcal R}$ be all material pieces and guide cells
meeting a value-defect interface, and let

$$
V^{\mathrm{br}}
=\bigoplus_{\mu,r\in\mathcal R}V_r
:=\left\{e\in\prod_{r\in\mathcal R}V_r:
|e|_{\mu,\mathrm{br}}<\infty\right\},
$$

where every $V_r$ is the closed $H^1(\Omega_r)$ subspace carrying the
protected outer and quasiperiodic boundary conditions.  Put

$$
|e|_{\mu,\mathrm{br}}^2
=\sum_{r\in\mathcal R}\int_{\Omega_r}
\bigl(|\nabla e_r|^2+\mu\rho_r|e_r|^2\bigr)\,dx,
\qquad
0<\rho_{r,-}\le\rho_r\le\overline\rho_r,
\quad \mu>0.
\tag{ME-1}
$$

For the full collection $\mathfrak G$ of material and artificial interfaces,
fix one orientation on each interface and define the *simultaneous* jump map

$$
J_{\mathrm{all}}e
=\bigl(\operatorname{Tr}_{\Gamma,+}e_+
-\operatorname{Tr}_{\Gamma,-}e_-\bigr)_{\Gamma\in\mathfrak G}.
\tag{ME-2}
$$

[Proof Addition P1 Start]

**Trace-product value space and boundedness.**  For a material interface let
$Y_\Gamma=H^{1/2}(\Gamma)$ with its arclength trace norm, and for an
artificial wall let $Y_\Gamma=H^{1/2}_\beta(0,d)$ with the normalized
quasiperiodic Fourier norm.  Give the countable product the Hilbert topology

$$
Y_{\mathrm{all}}
:=\bigoplus_{\Gamma\in\mathfrak G}Y_\Gamma
=\left\{g=(g_\Gamma):
\sum_{\Gamma\in\mathfrak G}\|g_\Gamma\|_{Y_\Gamma}^2<\infty\right\}.
\tag{ME-P1.1}
$$

The theorem uses the following explicit uniform trace-incidence hypothesis.
There are constants $C_{\mathrm{tr},r}$ such that the sum of the squared
trace norms over all selected faces incident on $\Omega_r$ is at most
$C_{\mathrm{tr},r}^2\|u_r\|_{H^1(\Omega_r)}^2$, and

$$
C_J^2
:=2\sup_{r\in\mathcal R}
\left[C_{\mathrm{tr},r}^2
\max\left\{1,(\mu\rho_{r,-})^{-1}\right\}\right]<\infty.
\tag{ME-P1.2}
$$

For a finite family, the supremum in (ME-P1.2) is just a finite maximum.
For the periodic half guides it follows from one cell trace constant and the
uniformly finite number of incident selected faces.  The inequality
$\|x-y\|^2\le2(\|x\|^2+\|y\|^2)$, the trace bounds, and (ME-1) then give

$$
\|J_{\mathrm{all}}e\|_{Y_{\mathrm{all}}}^2
\le C_J^2|e|_{\mu,\mathrm{br}}^2.
\tag{ME-P1.3}
$$

Thus (ME-2) means the bounded operator
$J_{\mathrm{all}}:V^{\mathrm{br}}\to Y_{\mathrm{all}}$; it is not a map
into an untopologized Cartesian product.  The raw jump datum in (ME-3) is
required to belong to $Y_{\mathrm{all}}$.  No closed-range assumption is
used below.

[Proof Addition P1 End]

If $a=(a_\Gamma)_{\Gamma\in\mathfrak G}$ is the raw reconstructed value jump,
define

$$
q_{\mathrm{all}}(a)
:=\inf\left\{|e|_{\mu,\mathrm{br}}:
e\in V^{\mathrm{br}},\ J_{\mathrm{all}}e=-a\right\}.
\tag{ME-3}
$$

The explicit zero-rim collars below make the constraint set nonempty.  The
trace map is continuous, so the constraint set is closed.  Coercivity in
(ME-1) and orthogonal projection onto $\ker J_{\mathrm{all}}$ therefore give
a unique minimum-energy correction $e_{\min}$.  If a future domain does not
supply these Hilbert-space hypotheses, (ME-3) remains an infimum and no
attainment claim is made.

[Proof Addition P2 Start]

**Closed fibre and attainment on the countable direct sum.**  Each $V_r$ is
complete in its energy norm because $\mu\rho_{r,-}>0$ makes that norm
equivalent to the $H^1(\Omega_r)$ norm.  The square-summable direct sum in
(ME-1) is therefore a Hilbert space with the energy inner product.  By
(ME-P1.3), $K:=\ker J_{\mathrm{all}}$ is a closed subspace.

Whenever one correction $e_0$ with $J_{\mathrm{all}}e_0=-a$ exists, the
complete fibre is exactly $e_0+K$, hence is nonempty and closed.  Let $P_K$
be the Hilbert orthogonal projection onto $K$ and put
$e_{\min}=e_0-P_Ke_0$.  Then $J_{\mathrm{all}}e_{\min}=-a$ and, for every
$k\in K$,

$$
|e_{\min}+k|_{\mu,\mathrm{br}}^2
=|e_{\min}|_{\mu,\mathrm{br}}^2+|k|_{\mu,\mathrm{br}}^2.
\tag{ME-P2.1}
$$

This proves existence and uniqueness of the minimizer and shows that its
norm equals (ME-3).  The construction is independent of the chosen $e_0$.
If the fibre is empty, the infimum is $+\infty$; the comparison right inverse
in Proof Addition P3 is the theorem's fail-closed nonemptiness gate.

[Proof Addition P2 End]

For $v$ in the continuous test space, retain the lifting term in its weak
form:

$$
R_{\mathrm{lift}}(v)
=\sum_r\int_{\Omega_r}
\bigl(\nabla e_{\min,r}\cdot\nabla\overline v_r
-\mu\rho_r e_{\min,r}\overline v_r\bigr)\,dx.
\tag{ME-4}
$$

Apply Cauchy--Schwarz once to the product vectors

$$
X_e=(\nabla e_r,\sqrt{\mu\rho_r}\,e_r)_r,
\qquad
Y_v=(\nabla v_r,-\sqrt{\mu\rho_r}\,v_r)_r.
$$

Both product norms are the corresponding energy norms.  Consequently

$$
|R_{\mathrm{lift}}(v)|
\le q_{\mathrm{all}}(a)\,\|v\|_\mu,
\qquad
\boxed{B_{\mathrm{lift}}=q_{\mathrm{all}}(a)}.
\tag{ME-5}
$$

There is no triangle inequality between the gradient and mass terms and no
factor $2$.  Nor may (ME-3) be replaced by a sum of independently minimized
full-domain interface quotients.  The computable bound below instead builds
one simultaneous comparison correction with pairwise disjoint supports.

### Shape-general two-sided comparison weight

Let a material interface $\Lambda$ have a single closed, simple,
$C_{\mathrm{per}}^{p+2}$ chart, $p\ge4$, and arclength parametrization
$r:\mathbb R/P\mathbb Z\to\Lambda$.  Write

$$
\phi_\ell(s)=P^{-1/2}e^{\mathrm i\xi_\ell s},
\qquad
\xi_\ell=\frac{2\pi\ell}{P}.
\tag{ME-6}
$$

Assume a certified reach, curvature bound, and two side clearances.  Choose
$h_q>0$, $q\in\{+,-\}$, so that the maps

$$
F_q(s,t)=r(s)+q\,t\nu(s),
\qquad 0\le t\le h_q,
$$

are injective, all selected collars for all interfaces are pairwise
disjoint, and

$$
0<\theta_q:=1-h_q\kappa_*
\le J_q(s,t)\le
\Theta_q:=1+h_q\kappa_*.
\tag{ME-7}
$$

For one Fourier mode define

$$
A_q=\Theta_q,
\qquad
B_{q,\ell}=\frac{\xi_\ell^2}{\theta_q}
+\mu\overline\rho_q\Theta_q,
\tag{ME-8}
$$

and, with the continuous $B_{q,\ell}=0$ limit understood,

$$
\kappa_{q,\ell}
=\sqrt{A_qB_{q,\ell}}\,
\coth\!\left(h_q\sqrt{B_{q,\ell}/A_q}\right).
\tag{ME-9}
$$

Indeed the zero-rim profile

$$
f_{q,\ell}(t)=
\frac{\sinh(\alpha_{q,\ell}(h_q-t))}
{\sinh(\alpha_{q,\ell}h_q)},
\qquad
\alpha_{q,\ell}=\sqrt{B_{q,\ell}/A_q},
\tag{ME-10}
$$

has $f(0)=1$, $f(h_q)=0$ and minimizes
$A_q\int|f'|^2+B_{q,\ell}\int|f|^2$, with cost
$\kappa_{q,\ell}$.  The tubular metric bound (ME-7) shows that this
one-dimensional cost is an upper bound for the physical collar energy.
Extension by zero across $t=h_q$ is in $H^1$ because its trace vanishes;
no condition on $f'(h_q)$ is needed, and no artificial normal residual is
created because (ME-4) is not integrated by parts.

For a jump coefficient $a_\ell$, minimize
$\kappa_{+,\ell}|c_+a_\ell|^2+
\kappa_{-,\ell}|c_-a_\ell|^2$ subject to $c_+-c_-=-1$.  The result is

$$
c_+=-\frac{\kappa_{-,\ell}}
{\kappa_{+,\ell}+\kappa_{-,\ell}},
\qquad
c_-=\frac{\kappa_{+,\ell}}
{\kappa_{+,\ell}+\kappa_{-,\ell}},
$$

$$
\overline w_{\Lambda,\ell}
=\frac{\kappa_{+,\ell}\kappa_{-,\ell}}
{\kappa_{+,\ell}+\kappa_{-,\ell}}.
\tag{ME-11}
$$

Thus the explicitly constructed simultaneous collar correction satisfies
$J_{\mathrm{all}}\overline E=-I$ and

$$
q_{\mathrm{all}}(a)^2
\le |\overline Ea|_{\mu,\mathrm{br}}^2
\le\sum_{\Lambda\in\mathfrak G}
\sum_{\ell\in\mathbb Z}
\overline w_{\Lambda,\ell}|a_{\Lambda,\ell}|^2.
\tag{ME-12}
$$

[Proof Addition P3 Start]

**Countable comparison right inverse.**  Let

$$
Y_{\mathrm{cmp}}
:=\left\{a\in Y_{\mathrm{all}}:
\sum_{\Lambda\in\mathfrak G}\sum_{\ell\in\mathbb Z}
\overline w_{\Lambda,\ell}|a_{\Lambda,\ell}|^2<\infty\right\}.
\tag{ME-P3.1}
$$

For a finite set of interfaces and Fourier modes, construct
$\overline E_Fa$ with (ME-10)--(ME-11), choosing the two traces so that
$c_+-c_-=-1$.  Its zero-rim trace and the fixed orientation give
$J_{\mathrm{all}}\overline E_Fa=-a_F$.  The uniform metric bounds replace
the physical collar energy by the constant-coefficient surrogate before
Fourier modes are summed; Fourier orthogonality then gives the corresponding
finite version of the second inequality in (ME-12).  Pairwise collar
disjointness makes the energies of different physical interfaces add.
For a material interface this statement uses the arclength-normalized basis
and weights (ME-6)--(ME-11); for an artificial wall it uses the distinct
normalized quasiperiodic basis and flat-collar weights (ME-21)--(ME-22).
No common arclength basis is imposed on the two interface types.

For $a\in Y_{\mathrm{cmp}}$, the same estimate applied to differences of
two finite truncations shows that $\overline E_Fa$ is Cauchy in
$V^{\mathrm{br}}$.  Let its limit be $\overline Ea$.  Boundedness of
$J_{\mathrm{all}}$ and convergence of the Fourier truncations in the trace
product imply

$$
J_{\mathrm{all}}\overline Ea=-a,
\qquad
|\overline Ea|_{\mu,\mathrm{br}}^2
\le\sum_{\Lambda,\ell}
\overline w_{\Lambda,\ell}|a_{\Lambda,\ell}|^2.
\tag{ME-P3.2}
$$

Thus $Y_{\mathrm{cmp}}\subset\operatorname{Ran}J_{\mathrm{all}}$, the fibre
in (ME-3) is nonempty for every datum used by the theorem, and (ME-12)
follows from the minimizing property proved in P2.  This is one simultaneous
global construction; it is not a sum of independently minimized full-domain
quotients.

[Proof Addition P3 End]

The first inequality has the displayed direction because $q_{\mathrm{all}}$
is the minimum over all simultaneous corrections.  Formula (ME-11) is an
optimized *comparison upper*, not a diagonalization of the true
variable-curvature Dirichlet-to-Neumann map.

For reference, $\coth x\le1+x^{-1}$ gives

$$
\overline w_{\Lambda,\ell}\le W_{0,\Lambda}
+W_{1,\Lambda}|\xi_\ell|,
\tag{ME-13}
$$

where

$$
C_{0,q}=\frac{\Theta_q}{h_q}
+\Theta_q\sqrt{\mu\overline\rho_q},
\qquad
C_{1,q}=\sqrt{\frac{\Theta_q}{\theta_q}},
$$

$$
W_{0,\Lambda}=\frac{C_{0,+}+C_{0,-}}4,
\qquad
W_{1,\Lambda}=\frac{C_{1,+}+C_{1,-}}4.
\tag{ME-14}
$$

For a fixed, non-kernel shift $\vartheta_{\mathrm{tr}}>0$, define

$$
\|a\|_{H^{1/2}_{\vartheta_{\mathrm{tr}}}(\Lambda)}^2
=\sum_\ell\sqrt{\vartheta_{\mathrm{tr}}^2+\xi_\ell^2}
|a_\ell|^2,
$$

$$
C_{\mathrm{lift},\Lambda}^2
:=\sup_\ell
\frac{\overline w_{\Lambda,\ell}}
{\sqrt{\vartheta_{\mathrm{tr}}^2+\xi_\ell^2}}<\infty.
\tag{ME-15}
$$

In particular, (ME-13) and the two-dimensional Cauchy--Schwarz inequality
give the finite computable bound

$$
C_{\mathrm{lift},\Lambda}^2
\le\sqrt{
\left(\frac{W_{0,\Lambda}}{\vartheta_{\mathrm{tr}}}\right)^2
+W_{1,\Lambda}^2}.
\tag{ME-15a}
$$

The governing evaluator should use the sharper per-mode weights in (ME-11),
not the norm constant in (ME-15).

### Fourth-order material tail

For retained $|\ell|<L$, suppose
$|a_{\Lambda,\ell}-\widetilde a_{\Lambda,\ell}|
\le\epsilon_{\Lambda,\ell}$.  Define

$$
F_{\Lambda,L}^2
=\sum_{|\ell|<L}\overline w_{\Lambda,\ell}
(|\widetilde a_{\Lambda,\ell}|+\epsilon_{\Lambda,\ell})^2.
\tag{ME-16}
$$

Let the local self-action component satisfy
$Q_{\Lambda,4}^{\mathrm{loc}}
\ge\int_0^P|\partial_s^4a_\Lambda^{\mathrm{loc}}(s)|\,ds$.
Four integrations by parts give, for $\ell\ne0$,

$$
|a_{\Lambda,\ell}^{\mathrm{loc}}|
\le\frac{Q_{\Lambda,4}^{\mathrm{loc}}}
{\sqrt P\,|\xi_\ell|^4}.
\tag{ME-17}
$$

Hence, for $L\ge1$,

$$
T_{\Lambda,4}^{\mathrm{loc}\,2}
=\frac{2(Q_{\Lambda,4}^{\mathrm{loc}})^2}{P}
\left\{
W_{0,\Lambda}\left(\frac P{2\pi}\right)^8
\left(L^{-8}+\frac{L^{-7}}7\right)
+W_{1,\Lambda}\left(\frac P{2\pi}\right)^7
\left(L^{-7}+\frac{L^{-6}}6\right)
\right\}
\tag{ME-18}
$$

bounds the complete omitted set $|\ell|\ge L$.  For a non-arclength chart
$z(t)$, a computable interface is

$$
q_0=a_\Lambda^{\mathrm{loc}},
\qquad q_{j+1}=|z'|^{-1}\partial_tq_j,
\qquad
Q_{\Lambda,4}^{\mathrm{loc}}
\ge\int_0^{2\pi}|q_4(t)|\,|z'(t)|\,dt.
\tag{ME-19}
$$

Its enclosure requires the certified speed lower bound and geometry/density
derivatives, not a sampled maximum.

For the material jump, local, regular-image, and off-surface components are
first combined as the one physical coefficient.  Retained centers and radii
are added by the triangle inequality before applying (ME-16).  In the omitted
set, (ME-18) owns only the local p4 component; the regular-image and
off-surface bounds retain their own proven tails.  A safe aggregate is

$$
T_{\Lambda}^{\mathrm{mat}}
\le T_{\Lambda,4}^{\mathrm{loc}}
+T_\Lambda^{\mathrm{reg}}+T_\Lambda^{\mathrm{off}},
\tag{ME-20}
$$

followed by one square.  None of these three tails owns an artificial-wall
mode or a propagation tail.

### Artificial-wall quasiperiodic corollary

On a vertical wall of period $d$, use the normalized quasiperiodic basis

$$
\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_my},
\qquad
\beta_m=\beta+\frac{2\pi m}{d}.
\tag{ME-21}
$$

For two flat collars of widths $h_\pm$, put

$$
\lambda_{q,m}=\sqrt{\beta_m^2+\mu\overline\rho_q},
\qquad
\kappa_{q,m}^w=\lambda_{q,m}\coth(h_q\lambda_{q,m}),
$$

$$
\overline w_m^w
=\frac{\kappa_{+,m}^w\kappa_{-,m}^w}
{\kappa_{+,m}^w+\kappa_{-,m}^w}.
\tag{ME-22}
$$

This is the flat-wall specialization of (ME-11).  It uses a Dirichlet
zero-rim profile, not the free-end hyperbolic-cosine trace minimizer used for
the wall-normal dual norm.  Moreover

$$
\overline w_m^w\le A_w+B_w|\beta_m|
\le U_0+U_1|m|,
\tag{ME-23}
$$

with

$$
A_w=\frac14\left(
h_+^{-1}+h_-^{-1}
+\sqrt{\mu\overline\rho_+}
+\sqrt{\mu\overline\rho_-}\right),
\quad B_w=\frac12,
$$

$$
U_0=A_w+B_w|\beta|,
\qquad U_1=B_w\frac{2\pi}{d}.
\tag{ME-24}
$$

Here $k_e=\widehat k\sqrt{\rho_e}$ is the exterior wavenumber; it equals
$\widehat k$ only when $\rho_e=1$.  Let $m_0=M_w+1=257$,
$\Delta_\beta=2\pi/d$, and require

$$
b_0=\Delta_\beta m_0-|\beta|-k_e>0.
\tag{ME-25}
$$

For each actual wall-jump row label $s$ and each sign
$\epsilon\in\{+,-\}$, combine *all* physical curve actions in that jump
before taking absolute values.  The existing positive-distance theorem gives
a computable constant $D_{s,\epsilon}$, including the normalized Green
factor $1/(2\sqrt d)$, every density $L^1(ds)$ bound, every
$1/\gamma_m$ value factor through the lower bound $b_0$, and every frozen
source/state contraction, such that

$$
|a_{s,\epsilon n}(x)|
\le C_{s,\epsilon}e^{-\delta\Delta_\beta n}\|x\|_2,
\qquad n\ge m_0,
$$

$$
C_{s,\epsilon}
=e^{\delta(k_e+|\beta|)}D_{s,\epsilon}.
\tag{ME-26}
$$

This definition is fail closed unless $D_{s,\epsilon}$ is the bound for the
complete actual jump, not for one curve action in isolation.  A direct
construction sums, with the applicable state-map norm, the terms
$[2R_\beta\|\tau\|_{L^1}+b_0^{-1}
\|\sigma\|_{L^1}]/(2\sqrt d)$, where $R_\beta$ is a certified upper
bound for $|\beta_m|/\kappa_m$ on $|m|\ge m_0$.

Let $r_w=e^{-2\delta\Delta_\beta}$ and

$$
S_0^w=\frac{r_w^{m_0}}{1-r_w},
\qquad
S_1^w=r_w^{m_0}
\left(\frac{m_0}{1-r_w}+\frac{r_w}{(1-r_w)^2}\right).
\tag{ME-27}
$$

Then the complete omitted set $|m|\ge257$ obeys

$$
T_{s,w}^2
\le\bigl(C_{s,+}^2+C_{s,-}^2\bigr)
\bigl(U_0S_0^w+U_1S_1^w\bigr)\|x\|_2^2.
\tag{ME-28}
$$

For a propagated sequence, the factor $\|x\|_2^2$ in (ME-28) is summed by
the existing Lyapunov or block-power certificate exactly once.  A central
singleton uses its own $D_{s,\epsilon}$ and no propagation factor.  The flat
density support $-256{:}255$ is zero outside that set, while the curve row at
$m=256$ remains retained; thus retained $|m|\le256$ and omitted
$|m|\ge257$ are disjoint and exhaustive.

Fix the wall orientation to point away from the central cell.  With
$V_w=g_w-F_w-C_w$ as in (I5.1f-21), the two central/first jumps are exactly

$$
a_-^{\mathrm{cf}}
=h_L^{\mathrm{cf}}-V_RG_-c_-,
\qquad
a_+^{\mathrm{cf}}
=h_R^{\mathrm{cf}}-V_LG_+c_+,
\tag{ME-29}
$$

where $h_L^{\mathrm{cf}}=D_-c_--(q_L+E q_R)$ and
$h_R^{\mathrm{cf}}=D_+c_+-(E q_L+q_R)$.  On every internal wall the trace in
the cell farther from the centre is minus the trace in the nearer cell, so

$$
a_{+,n}=(V_RG_+-V_LG_+P_+)P_+^nc_+,
$$

$$
a_{-,n}=(V_LG_--V_RG_-P_-)P_-^nc_-,
\qquad n\ge0.
\tag{ME-30}
$$

Equations (ME-29)--(ME-30) replace, rather than supplement, the historical
separate central mismatches, lead singletons, and four $V_{L/R}$ sequences.
They count the physical wall jump once.  The shared selector may be cancelled
only under an exact shared-trace identity gate; otherwise the two raw traces
must be formed before subtraction.

### Complete lifting upper and stopping gates

Let $F_{\Lambda,L}$ contain retained actual-jump row centers and all analytic
row radii for interface $\Lambda$.  Let $T_\Lambda$ contain the disjoint
local, regular-image, off-surface, artificial-wall high-mode, and propagation
owners described above.  Pairwise collar disjointness and (ME-12) give

$$
\boxed{
B_{\mathrm{lift}}
\le\left[
\sum_{\Lambda\in\mathfrak G}
\bigl(F_{\Lambda,L}^2+T_\Lambda^2\bigr)
\right]^{1/2}.}
\tag{ME-31}
$$

There is no outer factor $2$.  Within one physical jump, nonorthogonal
local/regular/off or left/right curve actions are combined before applying
the weight.  Different Fourier indices and pairwise disjoint collars are
combined in squares.  Propagation is applied once after the actual jump row
has been formed.

The result is `ESTABLISHED` under the following fail-closed inputs:

1. the global energy direct-sum and simultaneous jump convention
   (ME-1)--(ME-3), with every physical interface present once;
2. certified $C^{p+2}$ chart, perimeter, speed lower bound, reach, curvature,
   side clearances, positive $\theta_q$, collar injectivity and pairwise
   disjointness;
3. positive $\mu$, material lower bounds for coercivity, and the stated
   sidewise upper bounds $\overline\rho_q$;
4. retained actual-jump coefficient balls, the arclength $Q_4$ enclosure,
   and disjoint $|\ell|<L$ versus $|\ell|\ge L$ ownership;
5. for walls, the normalized basis, non-Wood/branch and $b_0>0$ gates, the
   complete constants $D_{s,\epsilon}$ with all $1/\gamma_m$ and
   $1/(2\sqrt d)$ factors, the exact (ME-29)--(ME-30) sign/index ledger, and
   retained $|m|\le256$ versus omitted $|m|\ge257$ ownership;
6. a zero trace on every collar rim, exact shared-selector identity or direct
   raw trace subtraction, and one Lyapunov/block-power owner per propagated
   sequence.

Select $L$ and the wall cutoff from (ME-18), the existing regular/off-surface
tails, and (ME-28) until their preassigned budgets hold.  Only then choose
the evaluation size with $N>2\max\{L,M_\eta\}$ and increase $N$ solely to
meet a proved retained-row radius.  Inter-level drift, a plateau, or an
empirical safety factor is not a stopping rule.

The theorem is independent of circular Fourier/Bessel diagonalization and of
an arbitrary fixed profile.  It does not enclose special-function or ordinary
finite-arithmetic errors: the corresponding $\Delta_{\mathrm{sf}}$ and
$\Delta_{\mathrm{fp}}$ remain unresolved.  The v6 frozen-instance evaluation
of (ME-11)--(ME-31) passed its analytic and ownership gates and therefore has
status `PASS WITH CONDITIONS / GO` only for the conditional ideal majorant.
Any reliable, certified, or outward-rounded instance claim remains `STOP`
until both unresolved error layers are enclosed.

[Proof Addition P4 Start]

## I5.1h full signed physical-jump $p=6,8$ certificate

This addition replaces only the three separately bounded material
value-jump high-mode owners in (ME-20).  It leaves every retained coefficient
ball, artificial-wall jump, propagation tail, normal residual, and the
minimum-energy weights unchanged.  The purpose is to form the exact physical
jump before taking a derivative norm.

Let $X$ be the finite frozen state space with its Euclidean norm.  For one
material interface write the exact row-valued value jump, with all source
maps already composed into $X^*$, as

$$
\mathscr A(t)=J(t)+\int_{-\pi}^{\pi}
\left\{K_1^{\mathrm{self}}(t,t-h)g(h)
+[K_2^{\mathrm{self}}+K^{\mathrm{reg}}](t,t-h)\right\}\,\mathrm dh
+\mathscr A^{\mathrm{off}}(t),
\tag{ME-P4.1}
$$

where $g(h)=\log(4\sin^2(h/2))$.  Equation (ME-P4.1) is an equality with the
physical signs: the value identity is in $J$ once, the regular image is added
to the smooth local split before enclosure, and the off-surface action is
added as a row in the same state space.  No separately absolutized
self/regular/off action is a governing high-mode object below.

Let $p\in\{6,8\}$ and assume a single regular
$C_{\mathrm{per}}^{p+2}$ chart with certified speed lower bound, chord--arc
bound, and derivatives through order $p+2$.  On a finite target/relative
product covering $I_a\times H_b$, require row balls
$\mathbb B(c,r)=\{c+e\in X^*: \|e\|_2\le r\}$ such that, for
$0\le q\le p$,

$$
(\partial_t+\partial_u)^qK_1^{\mathrm{self}}(t,u)
\in\mathbb B(c_{1,q;ab},r_{1,q;ab}),
\tag{ME-P4.2}
$$

$$
(\partial_t+\partial_u)^q
[K_2^{\mathrm{self}}+K^{\mathrm{reg}}](t,u)
\in\mathbb B(c_{2,q;ab},r_{2,q;ab}),
\tag{ME-P4.3}
$$

and

$$
J^{(q)}(t)+(\mathscr A^{\mathrm{off}})^{(q)}(t)
\in\mathbb B(c_{0,q;a},r_{0,q;a}).
\tag{ME-P4.4}
$$

The regular kernel, source density, Jacobian, and physical sign are combined
inside (ME-P4.3), not after its radius is formed.  If a source representation
uses a different finite state map, that map must first be composed into
$X^*$.  Diagonal panels in (ME-P4.2)--(ME-P4.3) use the cancellation-safe
Kress divided differences; no naked singular quotient is interval-evaluated.

Let the signed logarithmic moment be enclosed by

$$
\int_{H_b}g(h)\,\mathrm dh
\in[\widetilde m_b-\delta_b,\widetilde m_b+\delta_b],
\qquad
\Lambda_b\ge\int_{H_b}|g(h)|\,\mathrm dh.
\tag{ME-P4.5}
$$

Here $\delta_b\ge0$ and $\Lambda_b$ are finite certified scalar bounds.
Define

$$
C_{q,a}=c_{0,q;a}+
\sum_b\left(\widetilde m_bc_{1,q;ab}+|H_b|c_{2,q;ab}\right),
$$

$$
R_{q,a}=r_{0,q;a}+
\sum_b\left(\Lambda_br_{1,q;ab}
+\delta_b\|c_{1,q;ab}\|_2+|H_b|r_{2,q;ab}\right),
\qquad
H_{q,a}^{\mathrm{full}}=\|C_{q,a}\|_2+R_{q,a}.
\tag{ME-P4.6}
$$

Changing variables to $u=t-h$ before differentiation keeps $g(h)$ fixed.
Integration of the row balls and the triangle inequality only for their
radii show

$$
\sup_{t\in I_a}\|\partial_t^q\mathscr A(t)\|_2
\le H_{q,a}^{\mathrm{full}}.
\tag{ME-P4.7}
$$

Thus the signed centers in (ME-P4.6) retain every cancellation that the
finite row-ball arithmetic proves.  An unsigned component norm may enlarge a
radius, but it may not replace the signed center.

Put $s=|z'|$ and $w=s^{-1}$.  Define scalar coefficient functions recursively
by

$$
a_{1,1}=w,
\qquad
a_{n+1,q}=w(a_{n,q}'+a_{n,q-1}),
\qquad
a_{n,0}=a_{n,n+1}=0.
\tag{ME-P4.8}
$$

Induction gives the exact real-variable chain rule

$$
\partial_s^p\mathscr A
=\sum_{q=1}^p a_{p,q}(t)\partial_t^q\mathscr A.
\tag{ME-P4.9}
$$

Certified interval automatic differentiation of (ME-P4.8), using only the
declared speed jets, supplies
$A_{p,q;a}\ge\sup_{I_a}|a_{p,q}|$.  Therefore

$$
Q_{\Gamma,p}^{\mathrm{full}}
:=\sum_a|I_a|s_a^+
\left(\sum_{q=1}^pA_{p,q;a}H_{q,a}^{\mathrm{full}}\right)
\ge\int_\Gamma
\|\partial_s^p\mathscr A(s)\|_2\,\mathrm ds.
\tag{ME-P4.10}
$$

This is a real-variable certificate.  It does not assume a complex strip for
the local action and does not use circle Fourier/Bessel diagonalization.

Let

$$
\mathscr A_\ell=P^{-1/2}\int_0^P
\mathscr A(s)e^{-\mathrm i\xi_\ell s}\,\mathrm ds,
\qquad \xi_\ell=2\pi\ell/P.
$$

For $\ell\ne0$, $p$ integrations by parts in the periodic real variable give

$$
\|\mathscr A_\ell\|_2
\le\frac{Q_{\Gamma,p}^{\mathrm{full}}}
{\sqrt P\,|\xi_\ell|^p}.
\tag{ME-P4.11}
$$

Using the harmonic comparison weight
$\overline w_{\Lambda,\ell}\le W_{0,\Lambda}
+W_{1,\Lambda}|\xi_\ell|$, the complete omitted set $|\ell|\ge L$ satisfies

$$
\begin{aligned}
(T_{\Gamma,p}^{\mathrm{full}}(L))^2
:=\frac{2(Q_{\Gamma,p}^{\mathrm{full}})^2}{P}
\bigg[&W_{0,\Lambda}\left(\frac P{2\pi}\right)^{2p}
\left(L^{-2p}+\frac{L^{1-2p}}{2p-1}\right)\\
&+W_{1,\Lambda}\left(\frac P{2\pi}\right)^{2p-1}
\left(L^{1-2p}+\frac{L^{2-2p}}{2p-2}\right)\bigg].
\end{aligned}
\tag{ME-P4.12}
$$

The right side is an upper bound, despite the definition used to name it,
because
$\sum_{n=L}^\infty n^{-r}\le L^{-r}+L^{1-r}/(r-1)$.
For $p=6$ its two sums have orders $L^{-11}$ and $L^{-10}$; for $p=8$
they have orders $L^{-15}$ and $L^{-14}$.  If both complete certificates
pass, use

$$
T_\Gamma^{\mathrm{full}}(L)
=\min\{T_{\Gamma,6}^{\mathrm{full}}(L),
T_{\Gamma,8}^{\mathrm{full}}(L)\}.
\tag{ME-P4.13}
$$

This minimum is valid because both operands bound the same complete omitted
set.  A failed $p=8$ gate removes that operand; it does not invalidate a
passed $p=6$ certificate.

For retained $|\ell|<L$, first form one sampled signed physical row

$$
\widetilde{\mathscr A}(t_i)
=\widetilde{\mathscr A}^{\mathrm{self}}(t_i)
+\widetilde{\mathscr A}^{\mathrm{reg}}(t_i)
+\widetilde{\mathscr A}^{\mathrm{off}}(t_i),
$$

and apply the target DFT once to obtain
$\widetilde{\mathscr A}_{\ell,N}$.  The value identity is already in the
self row.  A retained ball has the form

$$
\|\mathscr A_\ell-\widetilde{\mathscr A}_{\ell,N}\|_2
\le\epsilon_{\ell}^{\mathrm{src}}
+\epsilon_{\ell}^{\mathrm{tgt}}
+\epsilon_{\ell}^{\mathrm{series}}
+\epsilon_{\ell}^{\mathrm{Ewald}}
+\epsilon_{\ell}^{\mathrm{off}}.
\tag{ME-P4.14}
$$

The five terms are successive edges of one evaluation graph: source Kress
quadrature, local kernel series, regular-image analytic Ewald
truncation/quadrature, off-surface analytic source/node evaluation, and the
single target DFT of the combined physical row.  A radius may be zero only
after its exact edge is absent.  Ewald or series tails used inside
(ME-P4.2)--(ME-P4.4) are magnitude certificates for the exact derivative and
are not re-added to the high-mode sum.

More explicitly, introduce only for this ownership check the six rows
$\mathscr A_\ell^{[0]},\ldots,\mathscr A_\ell^{[5]}$: the first is the exact
coefficient and each following row replaces exactly one of, in order, the
source Kress integral, local kernel series, regular Ewald evaluation,
off-surface evaluation, and target Fourier integral by its retained finite
rule.  The last row is $\widetilde{\mathscr A}_{\ell,N}$.  The five radii in
(ME-P4.14) enclose respectively
$\|\mathscr A_\ell^{[r-1]}-\mathscr A_\ell^{[r]}\|_2$, with the target term
assigned to $r=5$ and the other labels assigned to their named replacements.
Thus

$$
\mathscr A_\ell-\widetilde{\mathscr A}_{\ell,N}
=\sum_{r=1}^5
(\mathscr A_\ell^{[r-1]}-\mathscr A_\ell^{[r]})
$$

is a telescope.  Every exact-to-retained replacement occurs once, so the
five owners are mutually exclusive even though their row errors need not be
orthogonal.  Reordering independent replacements changes neither this
ownership nor the triangle bound.

For a constant-arclength target grid, define

$$
A_{\ell,N,Q}^{(p)}
=\sum_{q=1}^Q[(qN-|\ell|)^{-p}+(qN+|\ell|)^{-p}]
+\mathcal R_{\ell,N,Q}^{(p)},
\tag{ME-P4.15}
$$

where, with $q_0=Q+1$,

$$
\begin{aligned}
\mathcal R_{\ell,N,Q}^{(p)}={}&
(q_0N-|\ell|)^{-p}
+\frac{(q_0N-|\ell|)^{1-p}}{N(p-1)}\\
&+(q_0N+|\ell|)^{-p}
+\frac{(q_0N+|\ell|)^{1-p}}{N(p-1)}.
\end{aligned}
$$

Then the target owner in (ME-P4.14) may use the explicit alternative

$$
\epsilon_{\ell}^{\mathrm{tgt},p}
\le\frac{Q_{\Gamma,p}^{\mathrm{full}}P^{p-1/2}}{(2\pi)^p}
A_{\ell,N,Q}^{(p)},
\qquad |\ell|<N/2.
\tag{ME-P4.16}
$$

For a nonconstant-speed chart, the evaluator must instead certify the
phase-weighted parameter-rule derivative or a validated constant-arclength
reparametrization.  Formula (ME-P4.16) may not be used merely because the
target nodes look nearly equispaced.

The full signed high tail (ME-P4.13) *replaces* all three material local,
regular-image, and off-surface high tails in (ME-20); those old tails are not
added.  Retained balls (ME-P4.14) own $|\ell|<L$, (ME-P4.13) owns
$|\ell|\ge L$, the material block-power certificate owns cell propagation
once, and (ME-28) owns only artificial-wall high modes.  These sets and
operations are disjoint.  The lifting bound remains (ME-31), with the new
material high owner substituted.

The implication (ME-P4.1)--(ME-P4.16) is `ESTABLISHED`.  A frozen-instance
use becomes `CONDITIONAL GO` only after all finite row balls
(ME-P4.2)--(ME-P4.4) pass.  The current full-p6 frozen instance is `BLOCKED`:
the first present implementation blocker is a complete real-variable
$q=6$ enclosure for the regular-image part of (ME-P4.3), including all
retained Ewald terms and reciprocal/image/local truncation tails after six
target/source chain derivatives.  Existing material-tail certificates stop
at coordinate order two.  A conditional implementation may generate these
balls by finite interval jet arithmetic and bound every infinite
differentiated term family by its first omitted term divided by a proved
ratio below one.  For $p=8$, the same obligation extends to order eight and
requires a $C^{10}$ geometry certificate.

Finite special-function evaluation and ordinary arithmetic are not enclosed
by this theorem.  Their contributions remain
$\Delta_{\mathrm{sf}}=\mathrm{UNRESOLVED}$ and
$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$.

### Fail-safe two-band signed recapture

If the order-six regular-image derivative gate does not close, the existing
retained-row and p4 component theorems still give a finite, nonempirical
fallback.  Freeze a core cutoff $L_0$ and choose $L_1>L_0$.  Compute one
complete signed physical coefficient ball (ME-P4.14) for every mode in

$$
\mathcal I_{\mathrm{band}}
=\{\ell:L_0\le|\ell|<L_1\}.
\tag{ME-P4.17}
$$

With the exact harmonic weights, define its propagated comparison
contribution by

$$
F_{\mathrm{band}}^2
:= S_{\mathrm{state}}
\sum_{L_0\le|\ell|<L_1}
\overline w_{\Lambda,\ell}
(\|\widetilde{\mathscr A}_{\ell,N}\|_2+\epsilon_\ell)^2.
\tag{ME-P4.18}
$$

Here $S_{\mathrm{state}}$ is the already proved singleton-plus-block-power
state-energy envelope and is applied once.  For $|\ell|\ge L_1$, use the
existing established p4 component tails at the new cutoff,

$$
T_{\mathrm{far}}(L_1)
:= T_{4}^{\mathrm{self}}(L_1)
+T^{\mathrm{reg}}(L_1)+T^{\mathrm{off}}(L_1),
\tag{ME-P4.19}
$$

The three component bounds in (ME-P4.19) are first added by the triangle
inequality and that one sum is then squared.  Because the middle and far
bands are orthogonal Fourier index sets, their complete propagated high
contribution obeys the sharper square sum

$$
H_{\Gamma,\mathrm{high}}^2(L_0,L_1,N)
\le F_{\mathrm{band}}^2
+S_{\mathrm{state}}T_{\mathrm{far}}(L_1)^2.
\tag{ME-P4.20}
$$

Formula (ME-P4.19) is not a full signed p6 claim: it deliberately retains
the proved component triangle only on the far band.  The core
$|\ell|<L_0$, signed recapture band (ME-P4.17), and far tail
$|\ell|\ge L_1$ are pairwise disjoint and exhaustive.  Old component tails
starting at $L_0$ are replaced by (ME-P4.18)--(ME-P4.20), not added to them.
Writing $F_{\Lambda,L_0}$ and $T_{\Lambda,\mathrm{cell}}(L_0)$ for the
existing core finite-cell and block-power contributions restricted to
$|\ell|<L_0$, the complete two-band substitution in (ME-31) is

$$
\begin{aligned}
B_{\mathrm{lift}}^2\le{}&
\sum_{\Lambda\in\mathfrak G_{\mathrm{mat}}}
\left[F_{\Lambda,L_0}^2
+T_{\Lambda,\mathrm{cell}}(L_0)^2
+F_{\Lambda,\mathrm{band}}^2
+S_{\mathrm{state},\Lambda}T_{\Lambda,\mathrm{far}}(L_1)^2\right]\\
&+\sum_{\Lambda\in\mathfrak G_{\mathrm{wall}}}
\left(F_{\Lambda}^2+T_{\Lambda}^2\right).
\end{aligned}
\tag{ME-P4.21}
$$

Here $F_{\Lambda,\mathrm{band}}$ and the far term already use the complete
state envelope, so no second band/far cell term is added.  The last sum is
exactly the unchanged artificial-wall finite/high/propagation owner from
(ME-31); it contains no material coefficient.

Choose $L_1$ and then $N>2\max\{L_1,M_\eta\}$ solely from two predeclared
budgets.  First freeze the first analytically admissible $L_1$ for which
$\sqrt{S_{\mathrm{state}}}T_{\mathrm{far}}(L_1)$ meets the high-tail
budget.  With that $L_1$ fixed, freeze the first strict admissible $N$ for
which
$[S_{\mathrm{state}}\sum_{L_0\le|\ell|<L_1}
\overline w_{\Lambda,\ell}\epsilon_\ell(N)^2]^{1/2}$ meets the retained
radius budget.  For accounting, their orthogonal square sum is

$$
H_{\mathrm{band,rad}}^2(L_1,N)
:=S_{\mathrm{state}}
\left[
\sum_{L_0\le|\ell|<L_1}
\overline w_{\Lambda,\ell}\epsilon_\ell(N)^2
+T_{\mathrm{far}}(L_1)^2
\right].
\tag{ME-P4.22}
$$

No band center is evaluated until one pair is frozen.  If no $L_1$ meets the
high-tail budget but an analytic $L_1$ exists, freeze the largest analytic
$L_1$ and force the next route upgrade.  For that fixed $L_1$, if no $N$
meets the radius budget but an analytic strict $N$ exists, freeze the largest
such $N$ and retain the forced upgrade.  Evaluate only this frozen pair and
report its conditional finite majorant.  If either stage has no analytic
candidate, stop with no majorant.  No inter-level center drift enters this
rule.

[Proof Addition P4 End]
