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
weight $e_\ell^\Upsilon$, its upper-bound constants $C_0,C_2$, the retained
cutoffs $M,L$, the finite energy part $F_{M,L}^{\mathrm{lift}}$, the omitted
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

For $N=L_{\rm cut}+1$ and
$r_a=e^{-4\pi a_*/P_\Lambda}$, put

$$
S_0(N,r_a)=\frac{r_a^N}{1-r_a},
$$

$$
S_2(N,r_a)=r_a^N\left[
\frac{N^2}{1-r_a}
+\frac{2Nr_a}{(1-r_a)^2}
+\frac{r_a(1+r_a)}{(1-r_a)^3}
\right].
$$

Then the omitted lifting energy satisfies

$$
\sum_{|\ell|>L_{\rm cut}}e_\ell^{\rm tub}|a_\ell|^2
\le2P_\Lambda A_*^2\left[
C_0^{\rm tub}S_0(N,r_a)
+C_1^{\rm tub}\left(\frac{2\pi}{P_\Lambda}\right)^2S_2(N,r_a)
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
\qquad |\ell|\le L.
$$

The finite computed upper part of the lifting energy is

$$
F_{M,L}^{\mathrm{lift}\,2}
=\sum_{\Sigma,r}\sum_{|m|\le M}
e_m^w
(|\widetilde a_{\Sigma,r,m}|+\epsilon_{\Sigma,r,m})^2
+\sum_\Upsilon\sum_{|\ell|\le L}
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

Let $N=M+1$, $q_0=2\pi/d$,
$t_N=q_0N-|\beta|>\kappa_e$,
$\kappa_N=\sqrt{t_N^2-\kappa_e^2}$, and $r=e^{-2\delta q_0}$.
Then

$$
H_N=\left(1+\frac{t_N}{\kappa_N}\right)A_\tau
+\frac{A_\sigma}{\kappa_N},
$$

and, with

$$
S_j(N,r)=\sum_{n=N}^\infty n^jr^n,
\qquad j=0,1,2,
$$

the explicit formulas are

$$
S_0=\frac{r^N}{1-r},
\quad
S_1=r^N\left(\frac N{1-r}+\frac r{(1-r)^2}\right),
$$

$$
S_2=r^N\left(
\frac{N^2}{1-r}+\frac{2Nr}{(1-r)^2}
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
\le\frac{e^{2\delta(\kappa_e+|\beta|)}H_N^2}{2d}
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

For $N=L_{\rm cut}+1$ and
$r_a=e^{-4\pi\sigma_a/P_\Lambda}$, the complete high-boundary-mode lifting
tail of this action is therefore

$$
\sum_{|\ell|\ge N}e_\ell^{\rm tub}
\|q_{0,w,\ell}(A)\|_2^2
\le2C_{0,w}(A,a)^2\left[
C_0^{\rm tub}S_0(N,r_a)
+C_1^{\rm tub}\left(\frac{2\pi}{P_\Lambda}\right)^2S_2(N,r_a)
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
=\sum_{|\ell|\le L}e_\ell^{\rm tub}
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
\rho_m(a)=
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
e^{\rho_m(a)}
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

for this regular-image component.  With
$r_a=e^{-2a}$ and $N_L=L+1$, define

$$
S_0^a=\frac{r_a^{N_L}}{1-r_a},
$$

$$
S_2^a=r_a^{N_L}\left[
\frac{N_L^2}{1-r_a}
+\frac{2N_Lr_a}{(1-r_a)^2}
+\frac{r_a(1+r_a)}{(1-r_a)^3}
\right].
$$

The omitted regular-image circle lifting energy would then satisfy

$$
\sum_{|\ell|>L}e_\ell^\Upsilon|a_{\Upsilon,\ell}|^2
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
