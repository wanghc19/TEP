# Real-variable Kress bound for the residual numerator

This note bounds the local material self-action entering $B_\Upsilon$ and
$B_{\mathrm{lift}}$.  It uses the common symbols of this directory and adds
only the evaluation node count $N$, the frozen-density node count $N_\eta$,
the residual Fourier cutoff $L$, and the
complete Kress integrands $K_1,K_2$.  In particular, it does not redefine the
failed complex-strip objects in `s-local-panel.md`.

## Final residual-numerator bound

For the exact-kernel field determined by the frozen finite coefficients, set

$$
\widehat B_{\Gamma_\pm}
=\sqrt{\overline F_{\Gamma_\pm}^2+T_{\Gamma_\pm}^2},
\qquad
\widehat B_\Upsilon
=\sqrt{\overline F_\Upsilon^2+T_\Upsilon^2},
$$

$$
\widehat B_{\mathrm{lift}}
=2\sqrt{\overline F_{\mathrm{lift}}^2+T_{\mathrm{lift}}^2}.
$$

Under the finite gates stated below,

$$
\boxed{
\|R\|_{\mu,*}
\le
B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}
\le
\widehat B_{\Gamma_\pm}
+\widehat B_\Upsilon
+\widehat B_{\mathrm{lift}}.
}
\tag{KR-1}
$$

The three square roots are not three evaluations of the same defect.  They
come from the three disjoint strong-residual assignments in the topic
`README.md`.

| term | strong residual controlled | finite part | omitted part | governing bounds |
|---|---|---|---|---|
| $\widehat B_{\Gamma_\pm}$ | raw-field normal jump on each artificial wall, counted once | retained Rayleigh rows in finitely many cells | high evanescent modes and the half-guide cell tail | positive distance, retained-row enclosure, and Lyapunov or block power from [[research/projects/eig-apost/phase3-analysis/residual-bound/s-wall-tail]] |
| $\widehat B_\Upsilon$ | raw-field material normal defect $j_\Upsilon$ | the identity jump and the local, regular-image, and off-surface centers are first added in each retained modal row | local algebraic Fourier tail, Ewald/regular-image tail, off-surface tail, and half-guide tail | the real Kress theorem below, the trace weight in [[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail]], and its Ewald and separated-action estimates |
| $\widehat B_{\mathrm{lift}}$ | the complete form $a(e,v)-\mu b(e,v)$ of the fixed value-jump correction | retained wall and material value-defect rows, including each identity jump once | local algebraic value tail, Ewald/off-surface value tails, wall tails, and half-guide tail | the real Kress theorem below and the tubular right inverse in [[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail]] |

Thus source Kress and target DFT errors occur only in retained local rows;
local Fourier omission occurs only beyond $L$; Ewald and
positive-distance tails concern different kernel pieces; and propagation
tails concern cells beyond the retained cell cutoff.  These index and kernel
partitions prevent double counting.

## Finite certified inputs

The following finite data are required.  They do not require recomputing the
frozen eigenpair, densities, QZ subspaces, or propagation matrices.

1. The frozen values $\widehat k,\beta,\rho$, the finite density coefficients,
   their original representation size $N_\eta$, and their largest absolute
   parameter-Fourier degree $M_\eta$.  The latter is the maximum over every
   density appearing in an identity, layer, or Maue term.
2. A regular injective parameter curve
   $z\in C_{\mathrm{per}}^{p+2}(\mathbb T;\mathbb R^2)$, $p\ge2$, with
   certified bounds for $|z^{(q)}|$, $0\le q\le p+2$, a speed lower bound
   $s(t)=|z'(t)|\ge s_->0$, and

   $$
   |z(t)-z(u)|\ge c_0\left|\sin\frac{t-u}{2}\right|.
   $$

3. Reach, curvature, collar-disjointness, material, wall-clearance,
   non-Wood, outgoing-branch, and density-mass certificates required by the
   three existing modules.
4. Finite enclosures of the complete local $K_1,K_2$ derivatives in
   (KR-15), obtained from the diagonal-safe construction below, together with
   retained special-function series remainders.
5. The regular-image Ewald finite enclosures and explicit reciprocal, image,
   Taylor, and branch-free local tails of `s-material-tail.md`, plus the
   off-surface row enclosures of that note.
6. Retained row centers, their source and target radii, and either the
   Lyapunov or block-power certificate for each frozen propagation matrix.

A valid implementation may obtain item 4 by a finite interval covering or a
Taylor-model covering.  The covering must include the whole parameter torus,
use the cancellation-safe diagonal formula on diagonal boxes, use analytic
series remainders, and use outward enclosures for every primitive operation.
A sampled maximum is not a replacement.  In the present project, ordinary
floating-point evaluation may be displayed only as
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` and does not instantiate this input list.

## Cutoffs and stopping rule

The frozen density size and the two adjustable integers have different
meanings.

- $N_\eta$ records how the frozen density was produced; it is not changed.
- $L\ge1$ retains residual rows $|\ell|<L$.
- $N$ is the even Kress and target-evaluation node count.

First choose and freeze $L$ using only the explicit material
normal and lifting omission tails in (KR-24)--(KR-25).  Then choose

$$
N
>2\max\{L,M_\eta\}
\tag{KR-2}
$$

and, with $L$ fixed, increase only $N$ until
the retained-row radii in (KR-20)--(KR-21) meet their allocated tolerances.
Finally increase the cell cutoff only until the displayed Lyapunov or
block-power tails meet their allocations.  No step uses inter-level drift,
a convergence plateau, Richardson extrapolation, a fitted rate, or an
empirical safety factor.  In particular, the rule
$L\approx N/2$ is inadmissible.

## Frozen-instance gate

The theorem below is a finite algorithm, but the present frozen instance is
not yet `GO`.  It becomes `GO` only after the following quantities have been
enclosed and inserted into (KR-1):

1. the complete local value and normal constants in (KR-15), especially the
   second derivatives of the
   $C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}}$ and
   $D_{\kappa_e,2}^*-D_{\kappa_i,2}^*$ contributions;
2. independent $L$ and $N$ satisfying
   (KR-2), and every retained source/target row radius;
3. the already specified finite Ewald, off-surface, trace/lifting, and
   propagation gates.

The current coupling of the residual cutoff to one half of the evaluation
grid cannot satisfy this gate.  Existing run values therefore remain
conditional even when they look stable.

## Strong residual and module ownership

Let $u_{h,M}$ be the broken exact-kernel field and let $e$ be the fixed value
lifting, so that $\widehat u=u_{h,M}+e\in V_\beta$.  In every material piece
$K$,

$$
(-\Delta-\mu\rho_K)u_{h,M}=0.
$$

Broken integration by parts, applied only to $u_{h,M}$, gives

$$
R(v)
=\sum_\Sigma\langle j_\Sigma,v|_\Sigma\rangle
+\sum_\Upsilon\langle j_\Upsilon,v|_\Upsilon\rangle
+a(e,v)-\mu b(e,v).
\tag{KR-3}
$$

The material local value and normal actions are

$$
H^{\mathrm{val}}(t)
=\tau(t)+(K_e-K_i)\tau(t)+(S_e-S_i)\sigma(t),
\tag{KR-4}
$$

$$
H^{\mathrm{nor}}(t)
=(T_i-T_e)\tau(t)+\sigma(t)+(K_i^*-K_e^*)\sigma(t).
\tag{KR-5}
$$

The identities $\tau$ and $\sigma$ are included exactly once.  Regular-image
and off-surface actions contain no copy of either identity.  Moreover,

$$
|a(e,v)-\mu b(e,v)|\le2\|e\|_\mu\|v\|_\mu.
\tag{KR-6}
$$

Equation (KR-3), the wall trace inequality, the material trace inequality,
and (KR-6) reduce the proof of (KR-1) to finite-plus-tail estimates for the
three assigned coefficient families.

## Kress splits and diagonal cancellation

Write

$$
g(t-u)=\log\left(4\sin^2\frac{t-u}{2}\right).
$$

On the two sides of a material interface, write
$\kappa_e=\widehat k\sqrt{\rho_{\mathrm{out}}}$ and
$\kappa_i=\widehat k\sqrt{\rho_{\mathrm{in}}}$.  These are the two wavenumbers
passed to the bare Kress split functions.

For either action in (KR-4)--(KR-5), the complete local integrand is

$$
K(t,u)=K_1(t,u)g(t-u)+K_2(t,u).
\tag{KR-7}
$$

Here $K_1,K_2$ already include the relevant frozen density
$\eta=(\eta_1,\eta_2)^{\mathsf T}=(\tau,-\sigma)^{\mathsf T}$, source
Jacobian, normal, tangent, and Maue factors.  They are not bare kernel
factors.  Denote the bare single-layer, source-normal double-layer,
target-normal adjoint, and Maue tangential split factors by
$S_{\kappa,j}$, $D_{\kappa,j}$, $D_{\kappa,j}^*$, and
$C_{\kappa,j}^{\mathrm{tan}}$, respectively, and put

$$
T_z(t)=\frac{z'(t)}{s(t)},
$$

Then the factors used below are

$$
K_j^{\mathrm{val}}
=(D_{\kappa_e,j}-D_{\kappa_i,j})\eta_1(u)
+(S_{\kappa_i,j}-S_{\kappa_e,j})\eta_2(u),
\tag{KR-8}
$$

$$
K_j^{T_e-T_i}
=(\kappa_e^2S_{\kappa_e,j}-\kappa_i^2S_{\kappa_i,j})
[T_z(t)\cdot T_z(u)]\tau(u)
+\frac{C_{\kappa_e,j}^{\mathrm{tan}}
-C_{\kappa_i,j}^{\mathrm{tan}}}{s(t)}\tau'(u),
\tag{KR-9}
$$

$$
K_j^{\mathrm{nor}}
=-K_j^{T_e-T_i}
-(D_{\kappa_i,j}^*-D_{\kappa_e,j}^*)\eta_2(u),
\qquad j=1,2.
\tag{KR-10}
$$

Thus (KR-9) is the Maue-regularized split of the explicit operator
$T_e-T_i$, whereas the normal residual (KR-5) uses
$T_i-T_e=-(T_e-T_i)$.  The first minus sign in (KR-10) records exactly this
operator sign; the second density coordinate is $\eta_2=-\sigma$.

These signs and source-speed conventions agree with
`+kernel/kress_mn_splits.m`, `+kernel/kress_l_splits.m`, and the `Tdiff`
assembly in `test/i5/residual-numerator-a1/residual_numerator_a1.m`.

The following formula removes the only delicate diagonal terms without using
a circular geometry.  Put

$$
x(t,u)=|z(t)-z(u)|^2,
\qquad
c(t,u)=\frac{x(t,u)}{4\sin^2((t-u)/2)},
$$

$$
p_T(t,u)=z'(t)\cdot[z(t)-z(u)],
$$

$$
p_n(t,u)=
\left[\frac{(z_2'(t),-z_1'(t))}{s(t)}
\cdot(z(t)-z(u))\right]s(u).
$$

The chord hypothesis gives $c\ge c_0^2/4$.  Define the entire functions

$$
J_\kappa^{[1]}(x)=\frac{\kappa J_1(\kappa\sqrt x)}{\sqrt x},
$$

$$
G_\kappa^{[0]}(x)=J_0(\kappa\sqrt x),
\qquad
c_\kappa^0=\frac{\mathrm i}{4}
-\frac1{2\pi}\left(\log\frac \kappa2+\gamma_E\right),
$$

$$
\mathfrak c_\kappa(x)
=-\frac{G_\kappa^{[0]}(x)-1}{2\pi x}
+2c_\kappa^0\frac{\mathrm d}{\mathrm dx}G_\kappa^{[0]}(x)
+\frac1\pi\frac{\mathrm d}{\mathrm dx}Y_\kappa^{\mathrm{reg}}(x),
\tag{KR-11}
$$

where $Y_\kappa^{\mathrm{reg}}$ is the entire harmonic-number series used in the exact
free-space Green expansion in `s-local-panel.md`.  Every quotient in
(KR-11) has its power-series value at $x=0$.

Direct differentiation of that Green expansion gives

$$
-\frac{\mathrm i\kappa}{4\sqrt x}H_1^{(1)}(\kappa\sqrt x)
-\frac{J_\kappa^{[1]}(x)}{4\pi}g(t-u)
=-\frac1{2\pi x}
+\frac{J_\kappa^{[1]}(x)}{4\pi}\log c(t,u)
+\mathfrak c_\kappa(x).
\tag{KR-12}
$$

Let $\Delta$ mean exterior minus interior and set

$$
W(t,u)
=\frac{\Delta J^{[1]}(x(t,u))}{4\pi}\log c(t,u)
+\Delta\mathfrak c(x(t,u)).
$$

The $x^{-1}$ term in (KR-12) is independent of the wavenumber.  Therefore it
cancels before absolute values, as does the common cotangent term in the
hypersingular split, and

$$
\boxed{
C_{\kappa_e,2}^{\mathrm{tan}}(t,u)
-C_{\kappa_i,2}^{\mathrm{tan}}(t,u)=p_T(t,u)W(t,u),
\qquad
D_{\kappa_e,2}^*(t,u)-D_{\kappa_i,2}^*(t,u)=p_n(t,u)W(t,u).
}
\tag{KR-13}
$$

This identity, rather than separate estimates of the two hypersingular
kernels, governs the normal row.

For $E=\partial_u$ or $E=\partial_t+\partial_u$,

$$
E^2(pW)=(E^2p)W+2(Ep)(EW)+p(E^2W),
\tag{KR-14}
$$

where $EW,E^2W$ follow by the ordinary chain and product rules from
$x,\log c,J_\kappa^{[1]}$, and $\mathfrak c_\kappa$.  On the diagonal,

$$
c(t,t)=s(t)^2,
\qquad p_T(t,t)=p_n(t,t)=0,
$$

$$
\partial_up_T(t,t)=-s(t)^2,
\qquad
\partial_u^2p_T(t,t)=-z'(t)\cdot z''(t),
$$

$$
\partial_up_n(t,t)=0,
\qquad
\partial_u^2p_n(t,t)
=-s(t)n(t)\cdot z''(t),
$$

$$
\partial_uW(t,t)
=\frac{\Delta J^{[1]}(0)}{4\pi}\frac{s'(t)}{s(t)}.
$$

Consequently,

$$
\partial_u^2(C_{\kappa_e,2}^{\mathrm{tan}}
-C_{\kappa_i,2}^{\mathrm{tan}})(t,t)
=-[z'(t)\cdot z''(t)]W(t,t)
-2s(t)^2\partial_uW(t,t),
$$

$$
\partial_u^2(D_{\kappa_e,2}^*-D_{\kappa_i,2}^*)(t,t)
=-s(t)[n(t)\cdot z''(t)]W(t,t),
$$

and, for $q=0,1,2$,

$$
(\partial_t+\partial_u)^q
(C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}})(t,t)
=(\partial_t+\partial_u)^q
(D_{\kappa_e,2}^*-D_{\kappa_i,2}^*)(t,t)=0.
$$

These are diagonal-safe second-order formulas.  A finite enclosure uses

$$
z(t)-z(u)
=(t-u)\int_0^1z'(t-\theta(t-u))\,\mathrm d\theta
$$

and the analogous twice-divided normal chord.  On diagonal boxes their
derivatives are enclosed through these integrals and the entire series in
(KR-11), with factorial or first-omitted-term ratio tails.  Off the diagonal,
finite boxes use a certified positive lower bound for $x$.  Taking the
maximum of the resulting finite box enclosures covers the torus and is not a
sampled maximum.

It follows in particular that, under the stated $C^{p+2}$ curve contract,

$$
K_1^{\mathrm{val}},K_2^{\mathrm{val}},
K_1^{\mathrm{nor}},K_2^{\mathrm{nor}}
\in C^p(\mathbb T^2).
$$

For implementation, define the actual finite derivative enclosures

$$
S_{j,p}
=\sup_t\int_0^{2\pi}|\partial_u^pK_j(t,u)|\,\mathrm du,
\qquad
C_{j,q}
=\sup_{t,u}|(\partial_t+\partial_u)^qK_j(t,u)|,
\quad0\le q\le p.
\tag{KR-15}
$$

Because $K_j$ are the complete integrands, (KR-15) includes every density
derivative and every Jacobian or Maue factor.  Their bounds are obtained by
the finite Leibniz rule applied to the primitive interval/Taylor enclosures;
there is no unnamed operator norm.

## Source Kress and target DFT remainders

Let $N$ be even and
$\mathcal I_N=\{-N/2+1,\ldots,N/2\}$.  If $r_N(n)$ is the representative of
$n$ in $\mathcal I_N$, put

$$
\omega(0)=0,
\qquad \omega(n)=|n|^{-1}\quad(n\ne0),
$$

$$
C_{p,N}^{K}
=\sum_{n\notin\mathcal I_N}
|\omega(r_N(n))-\omega(n)|\,|n|^{-p},
$$

$$
C_{p,N}^{T}=2N^{-p}\sum_{q=1}^\infty q^{-p}.
$$

At an evaluation-grid target $t=t_i$, the exact source-action error satisfies

$$
E_{\mathrm{src}}(t)
\le
S_{1,p}(t)C_{p,N}^{K}
+S_{2,p}(t)C_{p,N}^{T}.
\tag{KR-16}
$$

Here $S_{j,p}(t)$ denotes the integral in (KR-15) before taking its target
supremum.  The first constant has the explicit finite upper bound

$$
C_{p,N}^{K}
\le
2N^{-p}\left(2H_{N/2-1}+\frac2N\right)
\left(2^p+\frac{2^{p-1}}{p-1}\right)
+(N/2)^{-p-1}+\frac2p (N/2)^{-p},
\tag{KR-17}
$$

and

$$
C_{p,N}^{T}
\le2N^{-p}\left(1+\frac1{p-1}\right).
$$

Indeed, integration by parts gives a factor $|n|^{-p}$ for the Fourier
coefficient of the complete integrand.  The continuous logarithmic
multiplier is $-2\pi/|n|$, while the Kress rule uses the multiplier belonging
to $r_N(n)$.  At a grid target,
$e^{\mathrm int_i}=e^{\mathrm ir_N(n)t_i}$, so this proves (KR-16), including
the single positive Nyquist representative.  Formula (KR-16) is not asserted
for an arbitrary off-grid target.  Ordinary trapezoidal aliases give the
second term.

To bound target derivatives without differentiating $g$, change variables
$u=t-h$ and put $D=\partial_t+\partial_u$.  Then

$$
\mathcal H_q:=\|H^{(q)}\|_\infty
\le
\|J^{(q)}\|_\infty
+8\pi\log2\,C_{1,q}+2\pi C_{2,q}.
\tag{KR-18}
$$

Let

$$
a(t)=\int_0^ts(\theta)\,\mathrm d\theta,
\qquad P=a(2\pi),
\qquad \xi_\ell=\frac{2\pi\ell}{P},
$$

$$
\Psi_\ell(t)=s(t)H(t)e^{-\mathrm i\xi_\ell a(t)}.
$$

For $p=2$,

$$
\begin{split}
\|\Psi_\ell''\|_\infty\le{}&
\|s''\|_\infty\mathcal H_0
+2\|s'\|_\infty\mathcal H_1
+\|s\|_\infty\mathcal H_2\\
&+|\xi_\ell|
\left(3\|s\|_\infty\|s'\|_\infty\mathcal H_0
+2\|s\|_\infty^2\mathcal H_1\right)
+\xi_\ell^2\|s\|_\infty^3\mathcal H_0.
\end{split}
$$

The normalized target DFT radius is

$$
\epsilon_\ell^{\mathrm{tgt}}
\le
\frac{4\pi\zeta(2)}{\sqrt P\,N^2}
\|\Psi_\ell''\|_\infty,
\tag{KR-19}
$$

There is a sharper real-variable alternative whenever the chosen parameter is
constant speed.  Since
$d_m=\sqrt P\,\widehat H_m$ and (KR-23) gives

$$
|d_m|\le
\frac{Q_2P^{3/2}}{4\pi^2|m|^2},
\qquad m\ne0,
$$

the exact DFT alias identity, valid for $|\ell|<N/2$, yields

$$
\epsilon_{\ell}^{\mathrm{tgt,alias}}
\le
\frac{Q_2P^{3/2}}{4\pi^2}
\sum_{q\in\mathbb Z\setminus\{0\}}|\ell+qN|^{-2}.
\tag{KR-19a}
$$

This is not a circle theorem: it requires only a constant-speed periodic
parameterization and the certified $C^2$ bound in (KR-22).  For a finite
evaluation, set $a=|\ell|$, choose an integer $Q_A\ge1$, and bound the series
in (KR-19a) by

$$
\begin{split}
A_{\ell,N,Q_A}:={}&
\sum_{q=1}^{Q_A}\left[(qN-a)^{-2}+(qN+a)^{-2}\right]\\
&+(q_0N-a)^{-2}+\frac1{N(q_0N-a)}\\
&+(q_0N+a)^{-2}+\frac1{N(q_0N+a)},
\qquad q_0=Q_A+1.
\end{split}
\tag{KR-19b}
$$

The last four terms are the first omitted term plus the monotone integral
tail on each side.  Hence an implementation may use the smaller of (KR-19)
and the right-hand side of (KR-19a) with the series replaced by (KR-19b).
The two formulas enclose the same target DFT error and are alternatives, not
two radii to be added.

Propagation of source radii gives

$$
\epsilon_\ell^{\mathrm{src}}
\le
\frac{2\pi}{N\sqrt P}
\sum_{i=0}^{N-1}
s(t_i)E_{\mathrm{src}}(t_i).
\tag{KR-20}
$$

Write $H=J+H^{\mathrm{op}}$, where $H^{\mathrm{op}}$ is the integral in
(KR-7).  Let $\widetilde H_i^{\mathrm{op}}$ be its Kress center and define
$\widetilde d_\ell^{\mathrm{self}}$ by applying the target DFT once to
$J(t_i)+\widetilde H_i^{\mathrm{op}}$.  Thus the identity jump occurs exactly
once.  The exact local self row satisfies

$$
\|d_\ell^{\mathrm{self}}-\widetilde d_\ell^{\mathrm{self}}\|
\le
\epsilon_\ell^{\mathrm{self}}
:=\epsilon_\ell^{\mathrm{src}}
+\epsilon_\ell^{\mathrm{tgt}}
+\epsilon_\ell^{\mathrm{series}}.
\tag{KR-21}
$$

The source and series terms act only on $H^{\mathrm{op}}$; the target term
uses the derivative bound for the complete $H=J+H^{\mathrm{op}}$.  The last
term contains only the explicitly truncated Bessel/Green series.  Source
error, target error, series error, and identity therefore concern successive
or disjoint operations and are each added once.

For clarity, this is a nonzero-center enclosure, not a triangle enclosure of
the complete action about zero.  Let $K=(K_1,K_2)$ be the exact pair of
complete integrands and $K_Q=(K_{1,Q},K_{2,Q})$ its signed finite-series pair.
Let $\mathcal A K$ be the exact source integral and let

$$
(Q_NK)(t_i)
=\sum_{j=0}^{N-1}R_{ij}K_1(t_i,u_j)
+h_N\sum_{j=0}^{N-1}K_2(t_i,u_j),
\qquad h_N=\frac{2\pi}{N},
$$

be the Kress rule.  If $\mathcal D$ is the exact target Fourier functional
and $\mathcal D_N$ its $N$-point trapezoidal rule, then

$$
\begin{split}
d_\ell^{\mathrm{self}}
-\widetilde d_\ell^{\mathrm{self}}
={}&\bigl\{\mathcal D[J+\mathcal AK]
-\mathcal D_N[J+\mathcal AK]\bigr\}\\
&+\mathcal D_N[(\mathcal A-Q_N)K]
+\mathcal D_N[Q_N(K-K_Q)].
\end{split}
\tag{KR-21a}
$$

The three braces in (KR-21a) are bounded, in order, by
$\epsilon_\ell^{\mathrm{tgt}}$,
$\epsilon_\ell^{\mathrm{src}}$, and
$\epsilon_\ell^{\mathrm{series}}$.  In particular,
$\epsilon_\ell^{\mathrm{series}}$ encloses only the omitted terms of the
signed kernel series.  It cannot be replaced by an unsigned enclosure of the
whole finite operator, because doing so discards the cancellation retained in
$\widetilde d_\ell^{\mathrm{self}}$.

More explicitly, suppose the diagonal-safe series construction gives

$$
\delta_{r,ij}^\chi
\ge
\|K_r^\chi(t_i,u_j)-K_{r,Q}^\chi(t_i,u_j)\|_2,
\qquad r\in\{1,2\},\quad
\chi\in\{\mathrm{val},\mathrm{nor}\}.
$$

Define

$$
E_{\mathrm{ser},i}^\chi
=\sum_{j=0}^{N-1}|R_{ij}|\delta_{1,ij}^\chi
+h_N\sum_{j=0}^{N-1}\delta_{2,ij}^\chi.
$$

Then the computable radius

$$
\epsilon_\ell^{\mathrm{series},\chi}
:=\frac{h_N}{\sqrt P}
\sum_{i=0}^{N-1}s(t_i)E_{\mathrm{ser},i}^\chi
\tag{KR-21b}
$$

encloses $\mathcal D_N[Q_N(K-K_Q)]$ for every retained $\ell$.  The
factorial tails of the circle instance, or a shape-general interval/Taylor
covering, fill the $\delta_{r,ij}^\chi$ boxes.  Formula (KR-21b) contains no
unsigned copy of the retained finite center.

## Local Fourier omission

Arclength differentiation gives

$$
Q_2:=\|\partial_a^2H\|_{L^1(\mathrm ds)}
\le
2\pi\left(
\frac{\mathcal H_2}{s_-}
+\frac{\|s'\|_\infty\mathcal H_1}{s_-^2}
\right).
\tag{KR-22}
$$

Hence the exact normalized coefficient satisfies

$$
\|d_\ell^{\mathrm{self}}\|
\le\frac{Q_2}{\sqrt P\,|\xi_\ell|^2},
\qquad \ell\ne0.
\tag{KR-23}
$$

Let $b_\ell$ be the material trace weight and suppose its displayed collar
formula gives $b_\ell\ge c_{\mathrm{tr}}|\xi_\ell|$ for
$|\ell|\ge L$.  Then

$$
\sum_{|\ell|\ge L}
\frac{\|d_\ell^{\mathrm{self,nor}}\|^2}{b_\ell}
\le
\frac{2Q_{2,\mathrm{nor}}^2}{Pc_{\mathrm{tr}}}
\left(\frac P{2\pi}\right)^5
\left[L^{-5}
+\frac{L^{-4}}4\right].
\tag{KR-24}
$$

For the tubular lifting weight
$e_\ell^{\mathrm{tub}}=C_0^{\mathrm{tub}}
+C_1^{\mathrm{tub}}\xi_\ell^2$,

$$
\begin{split}
\sum_{|\ell|\ge L}
e_\ell^{\mathrm{tub}}\|d_\ell^{\mathrm{self,val}}\|^2
\le\frac{2Q_{2,\mathrm{val}}^2}{P}\bigg[&
C_0^{\mathrm{tub}}
\left(\frac P{2\pi}\right)^4
\left(L^{-4}
+\frac{L^{-3}}3\right)\\
&+C_1^{\mathrm{tub}}
\left(\frac P{2\pi}\right)^2
\left(L^{-2}
+L^{-1}\right)
\bigg].
\end{split}
\tag{KR-25}
$$

These are the only local omissions.  They do not contain retained Kress or
target errors.

## Assembly of the three modules

For every retained material row, first form the physical center and radius.
If `raw` denotes the orientation used by the regular-image and off-surface
auxiliary evaluators, then

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
-\widetilde j_\ell^{\mathrm{off,raw,nor}},
$$

$$
\epsilon_\ell^\chi
=\epsilon_\ell^{\mathrm{self},\chi}
+\epsilon_\ell^{\mathrm{reg},\chi}
+\epsilon_\ell^{\mathrm{off},\chi},
\qquad \chi\in\{\mathrm{val},\mathrm{nor}\}.
\tag{KR-26}
$$

The self center already contains the identity exactly once; no separate
identity row is added.  The identity has no source-action or series error,
but it is included in the target-integration and Fourier-tail bounds.  The
regular-image part may use a zero center only when its radius encloses the
complete exact regular-image action, including the retained Ewald finite sum
and every unretained reciprocal, image, and branch-free local term.  A Taylor
tail already absorbed by such a full-action radius is not added again.  This
retained zero-center radius needs only the real-axis constants of (M-action):

$$
\epsilon_{\ell}^{\mathrm{reg,val}}
\le\sqrt P\,[K_{01}(0)A_\tau+K_{00}(0)A_\sigma],
\qquad |\ell|<L,
$$

$$
\epsilon_{\ell}^{\mathrm{reg,nor}}
\le\sqrt P\,[K_{11}(0)A_\tau+K_{10}(0)A_\sigma],
\qquad |\ell|<L.
\tag{KR-26b}
$$

The complete regular-image high target-Fourier tail instead uses the
positive-width strip constants in (M-Fourier).  The real-axis retained rows
$|\ell|<L$ and strip-bounded omitted rows $|\ell|\ge L$ are disjoint; their
two bounds are not added to one another.  Each Ewald full-action certificate
must separately pass its branch and truncation gates, with M-T absorbed or
added exactly once in that index scope.  The
off-surface center uses the complete frozen finite Rayleigh support.  Its
retained radius contains only its target quadrature error; its
$|\ell|\ge L$ tail controls omitted target-boundary Fourier rows, not omitted
Rayleigh source modes.  All three centers are added before taking an absolute
value, and all three radii are added before the material trace or lifting
weight is applied.

Let $\mathscr C_\ell^\chi$ be the resulting unit-density center row and
$\delta_\ell^\chi$ its radius.  On side
$\varsigma\in\{-,+\}$ define

$$
C_{\varsigma,\ell}^\chi
=\mathscr C_\ell^\chi G_\varsigma,
\qquad
\epsilon_{\varsigma,\ell}^\chi
=\delta_\ell^\chi\|G_\varsigma\|_2.
$$

For the center singleton, use
$C_{0,\ell}^\chi=\mathscr C_\ell^\chi q_0$ and
$\epsilon_{0,\ell}^\chi=\delta_\ell^\chi\|q_0\|_2$.  Thus, for every side
state vector $x$,

$$
\|j_{\varsigma,\ell}^\chi(x)\|
\le
\|C_{\varsigma,\ell}^\chi x\|
+\epsilon_{\varsigma,\ell}^\chi\|x\|.
\tag{KR-26a}
$$

The same $C_{\varsigma,\ell}$, containing the local and off-surface nonzero
centers and any nonzero regular-image center and already composed with
$G_\varsigma$, must be used both for retained cells and for the $n\ge J$
block-power or Lyapunov tail.  An identity-only row map is not an upper bound
for that tail, and $G_\varsigma$ must not be composed a second time.

For each side $\varsigma\in\{-,+\}$, define

$$
\overline\omega_{\varsigma,L}^\Upsilon
=\sum_{|\ell|<L}
\frac{(\|C_{\varsigma,\ell}^\Upsilon\|
+\epsilon_{\varsigma,\ell}^\Upsilon)^2}{b_\ell}.
$$

With a retained cell cutoff $J$,

$$
\begin{split}
\overline F_\Upsilon^2
=\sum_{|\ell|<L}\frac1{b_\ell}
\bigg[&
(\|\widetilde j_{0,\ell}^\Upsilon\|
+\epsilon_{0,\ell}^\Upsilon)^2\\
&+\sum_{\varsigma\in\{-,+\}}\sum_{n=0}^{J-1}
(\|C_{\varsigma,\ell}^\Upsilon
P_\varsigma^nc_\varsigma\|
+\epsilon_{\varsigma,\ell}^\Upsilon
\|P_\varsigma^nc_\varsigma\|)^2
\bigg].
\end{split}
\tag{KR-27}
$$

Let $\mathcal C_{\Upsilon,0}$ and
$\mathcal C_{\Upsilon,\varsigma}$ be formed as follows.  Take the square root
of each squared local bound (KR-24), complete regular-image high-$|\ell|$
Fourier tail built from its certified Ewald full-action bound, and
off-surface target-Fourier tail; add these weighted sequence norms for the
same physical defect; only then square the sum where it occurs below.  The
internal M-R/M-I/M-T/M-L terms construct the regular-image full-action bound
and are not added as a second error.  This is the triangle inequality, not an
addition of already-squared nonorthogonal tails.  With Lyapunov certificates,

$$
\begin{split}
T_\Upsilon^2
=\mathcal C_{\Upsilon,0}^2
+\sum_{\varsigma\in\{-,+\}}\big[&
\overline\omega_{\varsigma,L}^\Upsilon
(P_\varsigma^Jc_\varsigma)^*Y_\varsigma
(P_\varsigma^Jc_\varsigma)\\
&+\mathcal C_{\Upsilon,\varsigma}^2
c_\varsigma^*Y_\varsigma c_\varsigma\big].
\end{split}
\tag{KR-28}
$$

The block-power replacement is exactly the one displayed in
`s-wall-tail.md`: replace each quadratic form $x^*Y_\varsigma x$ by
$K_\varsigma\|x\|^2$.  In particular, the retained-row low-cell part is

$$
\sum_{\varsigma\in\{-,+\}}
\overline\omega_{\varsigma,L}^\Upsilon
K_\varsigma\|P_\varsigma^Jc_\varsigma\|^2.
\tag{KR-28a}
$$

Equations (KR-27)--(KR-28) give

$$
B_\Upsilon\le\sqrt{\overline F_\Upsilon^2+T_\Upsilon^2}.
\tag{KR-29}
$$

For lifting, let $\mathcal D$ be the finite set of physical wall and material
value defects, each counted once, and let $e_{d,\ell}$ be its explicit wall
or tubular lifting weight.  Form every retained defect row by the analogue
of (KR-26).  Its material self center is the single DFT of
$J_{\mathrm{val}}+\widetilde H^{\mathrm{op}}$ and already contains the value
identity; no additional identity row is added.
Then

$$
\overline F_{\mathrm{lift}}^2
=\sum_{d\in\mathcal D}\sum_{\ell\ \mathrm{retained}}
e_{d,\ell}
(\|\widetilde a_{d,\ell}\|+\epsilon_{d,\ell})^2.
\tag{KR-30}
$$

For propagated defects, (KR-30) is expanded into singleton and
$0\le n<J$ terms exactly as in (KR-27).  Let
$T_{\mathrm{lift}}$ be constructed by taking the square root of each squared
local value bound (KR-25), regular-image Ewald value tail, off-surface
material tail, and artificial-wall value tail; adding the resulting weighted
norms when they act in the same collar; and only then squaring and summing
over disjoint collars.  Their Lyapunov or block-power cell tails follow the
same rule.  This is precisely
the finite expression in `s-lift-tail.md`, with its failed local P32 radius
replaced by (KR-21) and its local omission replaced by (KR-25).  Therefore

$$
B_{\mathrm{lift}}
\le2\sqrt{\overline F_{\mathrm{lift}}^2+T_{\mathrm{lift}}^2}.
\tag{KR-31}
$$

In particular, for one propagated material value defect the finite part and
the low-cell envelope have the sign and weight pattern

$$
\sum_{|\ell|<L}e_{\ell,\mathrm{val}}
\left[
(|\widetilde d_{0,\ell}|+\epsilon_{0,\ell})^2
+\sum_{\varsigma\in\{-,+\}}\sum_{n=0}^{J-1}
(\|C_{\varsigma,\ell}^{\mathrm{val}}P_\varsigma^nc_\varsigma\|
+\epsilon_{\varsigma,\ell}^{\mathrm{val}}
\|P_\varsigma^nc_\varsigma\|)^2
\right],
\tag{KR-31a}
$$

$$
\omega_{\varsigma,L}^{\mathrm{lift}}
=\sum_{|\ell|<L}e_{\ell,\mathrm{val}}
(\|C_{\varsigma,\ell}^{\mathrm{val}}\|
+\epsilon_{\varsigma,\ell}^{\mathrm{val}})^2.
\tag{KR-31b}
$$

Thus the lifting energy multiplies by $e_{\ell,\mathrm{val}}$ in both the
finite sum and the low-cell propagation tail.  Division by this weight is the
material-normal trace rule and is inadmissible for lifting.
The explicit retained-row low-cell lifting contribution is

$$
\sum_{\varsigma\in\{-,+\}}
\omega_{\varsigma,L}^{\mathrm{lift}}
K_\varsigma\|P_\varsigma^Jc_\varsigma\|^2.
\tag{KR-31c}
$$

Finally, `s-wall-tail.md` already proves

$$
B_{\Gamma_\pm}
\le\sqrt{\overline F_{\Gamma_\pm}^2+T_{\Gamma_\pm}^2}.
\tag{KR-32}
$$

Adding (KR-29), (KR-31), and (KR-32) to (KR-3) proves (KR-1).

## Why the errors do not overlap

For a retained local row, insert and subtract the exact source action sampled
at the target nodes.  The first difference is (KR-16); the second is the
target trapezoidal error (KR-19).  The series truncation is a third, earlier
kernel-evaluation difference.  This proves (KR-21) by three applications of
the triangle inequality.  No retained row belongs to (KR-24) or (KR-25).

The exact quasi-periodic Green function is split into the local free image,
the regular-image part, and separated off-surface actions.  Their centers are
added in (KR-26), while their omitted weighted norms are combined by triangle
inequality.  Cell indices $n<J$ and $n\ge J$ are disjoint.  Finally, (KR-3)
places raw normal defects and the complete lifting form in different
functionals.  Hence identity, source, target, Fourier, Ewald, off-surface,
and half-guide contributions are each counted exactly once.

## Theorem status and implementation boundary

**Theorem.**  Under the finite input gates above, equations
(KR-1)--(KR-32) give a reliable, shape-general, finite-plus-tail upper bound
for the continuous residual numerator of the frozen reconstruction.  The
proof uses no circular Fourier/Bessel diagonalization and no unknown exact
solution norm.

The theorem is a conditional implication: every quantity on its right-hand
side has a finite enclosure algorithm, but the current frozen instance has
not supplied the diagonal derivative enclosures in (KR-15) or rerun the
assembly with independent $L$ and $N$.
Therefore the theorem-level route is `GO`, while the current instance is
`CONDITIONAL GO`.  Ordinary floating-point stability cannot remove this
condition.

Kress source: Rainer Kress, “Boundary Integral Equations in Time-Harmonic
Acoustic Scattering,” *Mathematical and Computer Modelling* 15 (1991),
229--243, formulas (2.3)--(2.11) and (3.1)--(3.2), after conversion from the
paper's factor-two operators to the project's bare-potential normalization.

## Shape-general nonzero regular-image normal center

This section repairs only the complex-strip geometry used to enclose a
nonzero retained regular-image normal center.  It does not alter the local
Kress theorem above, the Ewald decomposition in `s-material-tail.md`, or the
physical signs in (KR-26).  In particular, no modulus, complex conjugation,
or real unit-normal construction is used away from the real curve.

Let

$$
\overline S_a=\{w\in\mathbb C:|\operatorname{Im}w|\le a\}
$$

and assume that the $2\pi$-periodic parameterization $z=(z_1,z_2)$ is
holomorphic on an open neighborhood of $\overline S_a$ and is real-valued,
regular, and injective on the real axis.  Every source or target strip below
has width at most $a$.  Define

$$
\chi(w)=z_1'(w)^2+z_2'(w)^2
$$

and require a certified lower bound

$$
\inf_{|\operatorname{Im}w|\le a}|\chi(w)|\ge\chi_->0.
$$

Because the open strip is simply connected, there is a holomorphic branch
$s_c=\sqrt\chi$.  Fix the unique branch which equals the positive real speed
$|z'|$ on the real axis, and set

$$
n_c=(z_2',-z_1'),
\qquad
\nu_c=\frac{n_c}{s_c}.
$$

This branch is $2\pi$-periodic: $s_c(w+2\pi)$ and $s_c(w)$ are two
holomorphic square roots and agree on the real axis.  The real orientation
gate requires that $\nu_c(t)$ equal the prescribed outward unit normal.

Let $H_\beta=G_{e,\beta}^{QP}-G_e^{\mathrm{free}}$ be the exact regular-image
kernel and let $H_{\beta,Q}$ be a retained finite Ewald expression.  The
retained expression includes the retained reciprocal terms, retained
nonzero images, retained Taylor orders, and retained branch-free local
canonical series.  Let the frozen densities $\tau$ and $\sigma$ be finite
trigonometric row maps from a finite state space to $\mathbb C$.  With
$X=z(t)-z(u)$, define the retained raw normal integrand by

$$
K_Q^{\mathrm{nor}}(t,u)
=-\nu_c(t)^{\mathsf T}\nabla_X^2H_{\beta,Q}(X)n_c(u)\tau(u)
+s_c(u)\nu_c(t)\mathbin\cdot\nabla_XH_{\beta,Q}(X)\sigma(u).
\tag{RNC-1}
$$

Define $K^{\mathrm{nor}}$ by replacing $H_{\beta,Q}$ with $H_\beta$.
On the real axis, (RNC-1) is exactly the source-normal followed by
target-normal action because $\nabla_{x'}=-\nabla_X$ and
$n_c(u)=s(u)\nu(u)$.  Thus the mixed-normal term has the minus sign and the
target-normal single-layer term has the plus sign.  The physical normal
defect later subtracts this raw regular-image row as in (KR-26).

For the arclength Fourier coefficient, define

$$
a_c(w)=\int_0^w s_c(\zeta)\,\mathrm d\zeta,
\qquad
P=a_c(2\pi),
\qquad
\xi_\ell=\frac{2\pi\ell}{P}.
$$

Then $a_c(w+2\pi)=a_c(w)+P$.  For a row-valued function $f$, put

$$
\mathcal D_\ell f
=\frac1{\sqrt P}\int_0^{2\pi}
s(t)f(t)e^{-\mathrm i\xi_\ell a(t)}\,\mathrm dt,
\qquad a=a_c|_{\mathbb R},
$$

and let $\mathcal A K(t)=\int_0^{2\pi}K(t,u)\,\mathrm du$.  The holomorphic
target integrand is

$$
\Psi_{Q,\ell}(w)
=s_c(w)(\mathcal A K_Q^{\mathrm{nor}})(w)
e^{-\mathrm i\xi_\ell a_c(w)}.
$$

It is $2\pi$-periodic.  For target-strip estimates one should use the
cancellation-safe identity

$$
s_c(t)K_Q^{\mathrm{nor}}(t,u)
=-n_c(t)^{\mathsf T}\nabla_X^2H_{\beta,Q}(X)n_c(u)\tau(u)
+s_c(u)n_c(t)\mathbin\cdot\nabla_XH_{\beta,Q}(X)\sigma(u).
\tag{RNC-2}
$$

The parameter phase $e^{-\mathrm i\ell t}$ is interchangeable with this
arclength phase only under a separately certified constant-speed identity
$a_c(t)=Pt/(2\pi)$.  Otherwise the arclength phase above is mandatory for
the trace and lifting weights used in this project.

Let $Q_{N_s}$ be the source trapezoidal rule with
$h_s=2\pi/N_s$, and let $\mathcal D_{N_t,\ell}$ be the target trapezoidal
rule for $\mathcal D_\ell$, with $h_t=2\pi/N_t$.  For the exact regular row
$d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
=\mathcal D_\ell\mathcal A K^{\mathrm{nor}}$ and a computed retained center
$\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}$, the exact telescope is

$$
\begin{split}
d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
={}&\mathcal D_\ell\mathcal A(K^{\mathrm{nor}}-K_Q^{\mathrm{nor}})\\
&+(\mathcal D_\ell-\mathcal D_{N_t,\ell})
\mathcal A K_Q^{\mathrm{nor}}\\
&+\mathcal D_{N_t,\ell}(\mathcal A-Q_{N_s})K_Q^{\mathrm{nor}}\\
&+\left(\mathcal D_{N_t,\ell}Q_{N_s}K_Q^{\mathrm{nor}}
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}\right).
\end{split}
\tag{RNC-3}
$$

The four lines own, respectively, Ewald omission, target quadrature, source
quadrature, and retained finite evaluation.  They are algebraically
disjoint.

For source quadrature, require holomorphy on
$t=t_i\in\mathbb R$, $|\operatorname{Im}u|\le b$, and certified bounds

$$
M_{Q,i}^{\mathrm{src}}
\ge\sup_{|\operatorname{Im}u|\le b}
\|K_Q^{\mathrm{nor}}(t_i,u)\|_2.
$$

Then

$$
E_{Q,i}^{\mathrm{src}}
=\frac{4\pi M_{Q,i}^{\mathrm{src}}}{e^{bN_s}-1},
\qquad
\epsilon_{\ell,\mathrm{src}}^{\mathrm{nor}}
\le\frac{h_t}{\sqrt P}
\sum_{i=0}^{N_t-1}s(t_i)E_{Q,i}^{\mathrm{src}}.
\tag{RNC-4}
$$

The constants $M_{Q,i}^{\mathrm{src}}$ include the source-strip density,
$n_c$, and $s_c$ bounds and the retained first- and second-coordinate
derivative bounds.  They do not require a target--source product strip.

For target quadrature, require holomorphy on
$|\operatorname{Im}t|\le a_t$, $u\in\mathbb R$, and define

$$
A_Q^{\mathrm{nor}}(a_t)
\ge\sup_{|\operatorname{Im}t|\le a_t}
\|(\mathcal A K_Q^{\mathrm{nor}})(t)\|_2,
$$

$$
s_{+,a_t}\ge\sup_{|\operatorname{Im}t|\le a_t}|s_c(t)|,
\qquad
\Sigma_{a_t}\ge\sup_{|\operatorname{Im}t|\le a_t}
|\operatorname{Im}a_c(t)|.
$$

The retained kernel constants give, for example,

$$
A_Q^{\mathrm{nor}}(a_t)
\le K_{Q,11}(a_t,0)A_\tau+K_{Q,10}(a_t,0)A_\sigma,
$$

where $A_\tau,A_\sigma$ are rigorous real-axis $L^1(\mathrm ds)$ row-map
bounds for the frozen densities.  Therefore

$$
\epsilon_{\ell,\mathrm{tgt}}^{\mathrm{nor}}
\le
\frac{4\pi s_{+,a_t}A_Q^{\mathrm{nor}}(a_t)
e^{|\xi_\ell|\Sigma_{a_t}}}
{\sqrt P\,(e^{a_tN_t}-1)}.
\tag{RNC-5}
$$

If the separately proved constant-speed alias bound is also available, the
smaller of the two target bounds may be used; they bound the same error and
must not be added.

Finite evaluation must enclose the complete weighted node summand.  Define

$$
W_{\ell,ij}
=s(t_i)e^{-\mathrm i\xi_\ell a(t_i)}
K_Q^{\mathrm{nor}}(t_i,u_j)
$$

and let $\widetilde W_{\ell,ij}$ be its computed counterpart.  Require

$$
\delta_{\ell,ij}^{\mathrm{eval}}
\ge\|W_{\ell,ij}-\widetilde W_{\ell,ij}\|_2,
\qquad
\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
=\frac{h_th_s}{\sqrt P}\sum_{i,j}\widetilde W_{\ell,ij}.
$$

Then

$$
\epsilon_{\ell,\mathrm{eval}}^{\mathrm{nor}}
\le\frac{h_th_s}{\sqrt P}
\sum_{i,j}\delta_{\ell,ij}^{\mathrm{eval}}.
\tag{RNC-6}
$$

This enclosure owns target speed, arclength phase, geometry, densities, and
all retained special-function values and first- and second-coordinate
derivatives.  Ordinary library values for `erfc`, the Faddeeva function, or
the exponential integral do not by themselves establish (RNC-6).

Let $T_{rs}^{\mathrm{rec}}$, $T_{rs}^{\mathrm{img}}$,
$T_{rs}^{\mathrm{tay}}$, and $T_{rs}^{\mathrm{loc}}$ be the M-R, M-I, M-T,
and M-L coordinate-derivative remainders from `s-material-tail.md`, through
$r+s\le2$.  Contract their sum with the certified complex-normal component
bounds as in (M-K-tail), giving
$\mathcal E_{11}^{\mathrm{Ew}}$ and
$\mathcal E_{10}^{\mathrm{Ew}}$.  Then

$$
\epsilon_{\ell,\mathrm{Ew}}^{\mathrm{nor}}
\le\sqrt P\left(
\mathcal E_{11}^{\mathrm{Ew}}A_\tau
+\mathcal E_{10}^{\mathrm{Ew}}A_\sigma\right).
\tag{RNC-7}
$$

When $H_{\beta,Q}$ contains Taylor orders $0,\ldots,N_E$, M-T is the first
omitted Taylor remainder and occurs in (RNC-7), not in the center.  The
retained-row radius is

$$
\epsilon_{\ell,\mathrm{reg}}^{\mathrm{nor}}
=\epsilon_{\ell,\mathrm{Ew}}^{\mathrm{nor}}
+\epsilon_{\ell,\mathrm{tgt}}^{\mathrm{nor}}
+\epsilon_{\ell,\mathrm{src}}^{\mathrm{nor}}
+\epsilon_{\ell,\mathrm{eval}}^{\mathrm{nor}},
\qquad |\ell|<L.
\tag{RNC-8}
$$

No term in (RNC-8) is also part of the high target-Fourier tail.  For the
full exact regular action, define

$$
\sigma_{a_h}
=\min\left\{
\inf_t[-\operatorname{Im}a_c(t-\mathrm ia_h)],
\inf_t[\operatorname{Im}a_c(t+\mathrm ia_h)]
\right\}>0
$$

and suppose
$A_{\mathrm{reg}}^{\mathrm{nor}}(a_h)$ bounds the full exact action on the
target strip.  Contour shifting then gives the disjoint high-mode estimate

$$
\|d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}\|_2
\le\frac{2\pi s_{+,a_h}}{\sqrt P}
A_{\mathrm{reg}}^{\mathrm{nor}}(a_h)
e^{-|\xi_\ell|\sigma_{a_h}},
\qquad |\ell|\ge L.
\tag{RNC-9}
$$

For retained modes, the physical material-normal center and radius are
therefore assembled as

$$
\widetilde j_\ell^{\mathrm{nor}}
=\widetilde j_\ell^{\mathrm{self,nor}}
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
-\widetilde j_\ell^{\mathrm{off,raw,nor}},
$$

$$
\epsilon_\ell^{\mathrm{nor}}
=\epsilon_\ell^{\mathrm{self,nor}}
+\epsilon_{\ell,\mathrm{reg}}^{\mathrm{nor}}
+\epsilon_\ell^{\mathrm{off,nor}}.
$$

Thus the signed centers are combined before taking a norm, while the three
radii are added by the triangle inequality.  The local identity remains
inside the self center exactly once.

**Theorem (nonzero retained regular-image normal center).**  Equations
(RNC-1)--(RNC-9) are valid for a general single-chart smooth curve provided
the following fail-closed gates hold:

1. the holomorphic curve extension and a positive lower enclosure for
   $|\chi|$ hold on every strip actually used;
2. the periodic square-root branch matches the positive real speed, and the
   real normal has the prescribed outward orientation;
3. $s_c$, $n_c$, $\nu_c$, $a_c$, $\Sigma_{a_t}$, and
   $\sigma_{a_h}$ have finite certified bounds with $\sigma_{a_h}>0$;
4. the separate target-real/source-strip and target-strip/source-real domains
   meet no periodic image, complex null-cone singularity, or inconsistent
   special-function branch of the retained representation;
5. outgoing, non-Wood, small-denominator, and all M-R/M-I/M-T/M-L ratio and
   first-omitted-index gates pass through coordinate derivative order two;
6. (RNC-6) is supplied by a reliable finite special-function and derivative
   evaluation enclosure;
7. retained $|\ell|<L$ and omitted $|\ell|\ge L$ are disjoint, and retained
   and omitted Ewald, off-surface, and cell-propagation terms each have one
   owner.

**Proof.**  Nonvanishing of $\chi$ on a simply connected strip gives a
holomorphic logarithm and hence the stated square-root branch.  Its real-axis
normalization and the identity theorem give periodicity.  Formula (RNC-1)
follows by applying the target normal derivative to the source-normal and
single-layer actions and using $\nabla_{x'}=-\nabla_X$.  Multiplication by
$s_c(t)$ gives (RNC-2), so the arclength phase and complete target integrand
are holomorphic under the separate target-strip gate.

Insert $H_{\beta,Q}$, the exact source trapezoidal rule, and the exact target
trapezoidal rule in succession to obtain (RNC-3).  A bounded $2\pi$-periodic
holomorphic function on a strip of half-width $c$ has Fourier coefficients
bounded by its strip supremum times $e^{-c|m|}$; summing the aliases
$m=qN$, $q\ne0$, gives $4\pi M/(e^{cN}-1)$.  This proves (RNC-4) and
(RNC-5).  The finite triangle inequality proves (RNC-6), and (M-K-tail)
together with the $L^1(\mathrm ds)$ density bounds proves (RNC-7).  Summing
the four disjoint lines of (RNC-3) proves (RNC-8).  Finally, shifting the
arclength phase to the lower strip for $\ell>0$ and the upper strip for
$\ell<0$ proves (RNC-9).  No target--source product-strip deformation and no
circle-specific Fourier/Bessel diagonalization is used.  $\square$

The theorem is `ESTABLISHED` as a conditional implication.  A current
instance nonzero center remains `CONDITIONAL` until gate 6 is supplied:
ordinary Faddeeva or exponential-integral evaluations do not certify the
finite retained center even when floating-point roundoff is excluded.  The
smallest remaining obligation is a finite series, continued-fraction, or
interval enclosure for every retained special-function value and first- and
second-coordinate derivative appearing in (RNC-6).

## Library-independent zero-centre fallback

This section gives a deliberately coarse fallback which does not use a
sampled Kress action, a target DFT centre, or a retained special-function
value.  It is shape-general: the only geometric inputs are certified bounds
for one regular $C^{p+2}$ parameter curve and, where a complex-strip tail is
used, certified strip bounds for that curve.  The current circle is only one
adapter which supplies those bounds.

For a complex finite vector or matrix put

$$
|z|_\#=|\operatorname{Re}z|+|\operatorname{Im}z|,
$$

and form induced matrix $1$-norm upper bounds from column sums of
$|\cdot|_\#$.  Let $P_-\le P\le P_+$ be certified perimeter bounds.  All
finite arithmetic in this section is regarded as exact; ordinary
floating-point rounding is excluded.

### Elementary upper primitives

The implementation uses $3<\pi<22/7$ with the direction selected separately
at every occurrence.  For $x>0$ define $U_0(x)=\max\{1,x\}$ and, for a
fixed finite $q\ge0$,

$$
U_{j+1}(x)=\frac12\left(U_j(x)+\frac{x}{U_j(x)}\right),
\qquad
S_\#(x)=U_q(x),
\qquad
s_\#(x)=\frac{x}{S_\#(x)}.
\tag{ZF-1}
$$

Then $s_\#(x)\le\sqrt{x}\le S_\#(x)$; every Newton update preserves the
upper-bound direction.  For $x\ge0$, $Q\ge0$, and
$x/(Q+2)<1$, define

$$
E_Q^+(x)=\sum_{n=0}^{Q}\frac{x^n}{n!}
+\frac{x^{Q+1}}{(Q+1)!\,[1-x/(Q+2)]},
\qquad
E_Q^-(x)=\left(\sum_{n=0}^{Q}\frac{x^n}{n!}\right)^{-1}.
\tag{ZF-2}
$$

Termwise comparison gives $e^x\le E_Q^+(x)$ and
$e^{-x}\le E_Q^-(x)$.  Factorials are generated by the recurrence
$f_{n+1}=(n+1)f_n$.  The remaining elementary replacements are

$$
|\log x|\le x+x^{-1},
\qquad
\tanh x\ge\frac{x}{1+x},
\qquad
|\sinh x|,\ \cosh x\le E_Q^+(|x|).
\tag{ZF-3}
$$

The middle inequality follows from
$e^{2x}\ge1+2x$.  Consequently no call to a library implementation of
`sqrt`, `exp`, `log`, `gammaln`, a trigonometric or hyperbolic function, a
matrix norm, or an FFT is part of the governing fallback bound.  A lower
input is used for decay, reciprocal-wavenumber and trace denominators; an
upper input is used for growth, derivative weights and lifting weights.

### Complete zero-centre retained rows

Every retained finite centre, including the value and normal identity, is
set to zero.  The radius, rather than a sampled centre, contains the complete
continuous action.  If $J_0^\chi$ is the complete identity/jump upper and
$C_{1,0}^{\chi},C_{2,0}^{\chi}$ are the density-, Jacobian-, normal- and
Maue-inclusive real-torus constants from (KR-15), define

$$
r_{\mathrm{self}}^{\chi}
=\frac{P_+}{\sqrt{P_-}}
\left(J_0^\chi+8\pi_+\log_+2\,C_{1,0}^{\chi}
+2\pi_+C_{2,0}^{\chi}\right),
\qquad \chi\in\{\mathrm{val},\mathrm{nor}\}.
\tag{ZF-4}
$$

Here $\pi_+=22/7$, $\log_+2=1$, and the factor $P_+/\sqrt{P_-}$ is evaluated
as the directional upper $P_+/s_\#(P_-)$, not
$P_+/S_\#(P_-)$.  The identity contribution is included once through
$J_0^\chi$ and is not hidden in either Kress integrand constant.  Density
mass is not multiplied into (ZF-4) again.  If the frozen density is defined
by an $N_\eta$-point finite DFT,
the library-free coefficient input is supplied by

$$
\|\widehat\eta_m\|_1
\le \frac1{N_\eta}\sum_{j=0}^{N_\eta-1}
\sum_q\left(|\operatorname{Re}\eta_{j,q}|
+|\operatorname{Im}\eta_{j,q}|\right),
\tag{ZF-5}
$$

and derivatives use the finite sum of $|m|^q$ times this bound.  Formula
(ZF-5) is used only under the gate that the frozen density is the stated
finite DFT with an explicit representative set.  For the current even grid
that set is the half-open range $-N_\eta/2,\ldots,N_\eta/2-1$; its single
Nyquist representative is audited explicitly rather than hidden behind a
false strict inequality.

Let $A_{\mathrm{reg}}^\chi(0)$ and
$A_{\mathrm{off}}^\chi(0)$ be pointwise action suprema per unit
$\|\cdot\|_{1,\#}$ state.  Their normalized target-Fourier radii are

$$
r_{\mathrm{reg}}^\chi
=\frac{P_+}{s_\#(P_-)}A_{\mathrm{reg}}^\chi(0),
\qquad
r_{\mathrm{off}}^\chi
=\frac{P_+}{s_\#(P_-)}A_{\mathrm{off}}^\chi(0).
\tag{ZF-5a}
$$

The regular action uses a whole-action elementary Ewald bound.  It may either
bound each retained nonzero image before Taylor expansion, thereby absorbing
M-T, or retain Taylor orders and add M-T; these alternatives are never added
together.  M-R, M-I, the chosen M-T ownership, and M-L occur once.  The
off-surface action uses the whole finite-Rayleigh positive-distance bound.
Both use (ZF-1)--(ZF-3) rather than retained special-function centres.  For
the Ewald reciprocal factor one may use
$|\operatorname{erfc}w|\le1+2|w|e^{|w|^2}/\sqrt\pi$ together with its exact
first two derivative identities and (ZF-1)--(ZF-2); no retained library
`erfc` value is needed.  The local logarithmic constants use
$0<\gamma_E<1$.  The complete retained unit-state radius is

$$
r_\ell^{\chi}
=r_{\mathrm{self}}^{\chi}
+r_{\mathrm{reg}}^{\chi}
+r_{\mathrm{off}}^{\chi},
\qquad |\ell|<L.
\tag{ZF-6}
$$

Every term in (ZF-6) is thus a normalized coefficient-row bound relative to
the same unit $\|\cdot\|_{1,\#}$ state.  The superscript $\chi$ fixes the
value or normal action, so no defect is transferred between $B_\Upsilon$ and
$B_{\mathrm{lift}}$.

### Whole half-guide sum and final assembly

For a frozen propagation matrix $P_s$, choose a block length $b$ and set

$$
q_s=\|P_s^b\|_{1,\#},
\qquad
\mathcal C_s(c_s)
=\|c_s\|_{1,\#}^2
\frac{\sum_{r=0}^{b-1}\|P_s^r\|_{1,\#}^2}{1-q_s^2},
\qquad q_s<1.
\tag{ZF-7}
$$

This one expression owns every side cell $n\ge0$; no separately retained or
low-cell contribution is then added.  Submultiplicativity gives

$$
\sum_{n=0}^{\infty}\|G_sP_s^nc_s\|_1^2
\le \|G_s\|_{1,\#}^2\mathcal C_s(c_s).
\tag{ZF-8}
$$

Define

$$
\mathcal S
=\|q_0\|_{1,\#}^2
+\sum_{s\in\{-,+\}}\|G_s\|_{1,\#}^2\mathcal C_s(c_s).
\tag{ZF-9}
$$

With certified lower normal-trace weights $\underline b_\ell>0$ and upper
tubular lifting weights $\overline e_{\ell,\mathrm{val}}$, put

$$
\overline F_\Upsilon^2
=\mathcal S\sum_{|\ell|<L}
\frac{(r_\ell^{\mathrm{nor}})^2}{\underline b_\ell},
\qquad
\overline F_{\mathrm{lift},\Upsilon}^2
=\mathcal S\sum_{|\ell|<L}
\overline e_{\ell,\mathrm{val}}(r_\ell^{\mathrm{val}})^2.
\tag{ZF-10}
$$

The trace lower bound uses $\tanh x\ge x/(1+x)$; the lifting weight uses only
upper geometric and material inputs.  For $|\ell|\ge L$, the complete
$p=2$ real-variable local tail includes the identity even when the density
has finite parameter-Fourier support.  Add the local, regular-image and
off-surface *sequence norms* before squaring because they act on the same
material collar:

$$
T_\Upsilon^2
=\mathcal S
\left(T_{\mathrm{self}}^{\mathrm{nor}}
+T_{\mathrm{reg}}^{\mathrm{nor}}
+T_{\mathrm{off}}^{\mathrm{nor}}\right)^2,
$$

$$
T_{\mathrm{lift},\Upsilon}^2
=\mathcal S
\left(T_{\mathrm{self}}^{\mathrm{val}}
+T_{\mathrm{reg}}^{\mathrm{val}}
+T_{\mathrm{off}}^{\mathrm{val}}\right)^2.
\tag{ZF-11}
$$

Each $T_*^\chi$ in (ZF-11) is a weighted high-mode sequence norm per unit
$\|\cdot\|_{1,\#}$ state, consistent with the retained radii in (ZF-6).
The local $Q_2$ used here is built from the identity-inclusive derivative
upper for the complete action.

The artificial-wall normal and artificial-wall value parts are evaluated by
the same policy, but no previously evaluated finite mismatch is accepted as
an enclosure.  Starting from the exact frozen Rayleigh coefficient rows, the
flat-wall algebra is bounded term by term: propagating phases have modulus
one, evanescent phases use one or (ZF-2), every $1/\gamma_m$ uses a certified
positive square-root lower, and the curve-to-wall source action uses the
real-axis positive-distance triangle bound.  Centre/first-cell singletons are
listed separately from the all-$n\ge0$ side sequences.  The positive-distance
bound owns only omitted Rayleigh modes, and (ZF-7) owns all side cells.
Different material and wall collars are added in energy only under an
explicit disjoint-collar gate.  Denote the resulting disjoint energies
by $\overline F_{\Gamma_\pm}^2,T_{\Gamma_\pm}^2$ and
$\overline F_{\mathrm{lift},\Gamma}^2,
T_{\mathrm{lift},\Gamma}^2$.  Then

$$
\widehat B_{\Gamma_\pm}
=S_\#(\overline F_{\Gamma_\pm}^2+T_{\Gamma_\pm}^2),
$$

$$
\widehat B_\Upsilon
=S_\#(\overline F_\Upsilon^2+T_\Upsilon^2),
$$

$$
\widehat B_{\mathrm{lift}}
=2S_\#\!\left(
\overline F_{\mathrm{lift},\Upsilon}^2
+T_{\mathrm{lift},\Upsilon}^2
+\overline F_{\mathrm{lift},\Gamma}^2
+T_{\mathrm{lift},\Gamma}^2\right).
\tag{ZF-12}
$$

The notation $S_\#(x)$ in (ZF-12) means the square-root upper in (ZF-1),
not $S_\#(x)^2$.  Although this arithmetic square-root upper is intentionally
loose, it preserves the inequality.  Equations (ZF-10)--(ZF-12) therefore
give

$$
\boxed{
\|R\|_{\mu,*}
\le \widehat B_{\Gamma_\pm}
+\widehat B_\Upsilon
+\widehat B_{\mathrm{lift}}.}
\tag{ZF-13}
$$

The reliability gate is the conjunction of the geometry, finite-density,
outgoing/non-Wood, reciprocal-denominator, Ewald M-R/M-I/M-T/M-L,
positive-distance, local $p=2$ tail, trace/lifting, block-power, finite-value,
and zero-solve gates.  Retained $|\ell|<L$ and omitted $|\ell|\ge L$ are
disjoint.  Source and target quadrature owners are absent because no sampled
finite action is used.  A tightness failure does not invalidate (ZF-13), but
failure of any reliability gate does.

**Proof.**  Equations (ZF-1)--(ZF-3) follow from the arithmetic--geometric
mean inequality followed by the monotone Newton update, the ratio test
applied from the first omitted exponential term, and $e^{2x}\ge1+2x$.
The periodic logarithm satisfies the safe estimate
$\int_0^{2\pi}|\log(4\sin^2(u/2))|\,\mathrm du\le8\pi\log2$; applying the
complete integrand bounds and the triangle inequality proves (ZF-4).
Indeed its signed mean is zero, while its positive part is at most
$2\log2$ on a set of length at most $2\pi$; hence the absolute integral is
twice the positive integral and obeys the displayed estimate.
The finite DFT triangle inequality proves (ZF-5).  The existing Ewald and
positive-distance decompositions, with every scalar evaluation replaced by
(ZF-1)--(ZF-3), prove (ZF-6).  Split $n=rb+j$, apply the induced $1$-norm and
sum the geometric series to obtain (ZF-7)--(ZF-9).  Apply the trace and
lifting inequalities mode by mode to get (ZF-10); apply the disjoint
real-variable and positive-distance tails to get (ZF-11).  Finally add
different collars in energy and apply the outer triangle inequality, giving
(ZF-12)--(ZF-13).  No circular operator diagonalization, inter-level drift,
or finite special-function centre is used.  $\square$

The fallback is an established implication.  It becomes an instance-level
roundoff-excluded reliable bound only after all of the fail-closed scalar and
module gates above are evaluated successfully.

### Mode-dependent retained-row corollary

The uniform retained radius in (ZF-6) is not required.  This corollary keeps
the same zero centre and the same omitted-mode owners, but takes the smaller
of two independently proved bounds for each *individual physical action*.
It does not take a minimum after local, regular-image, and off-surface actions
have been combined.

Write the normalized arclength coefficient of one unit-state action as

$$
d_\ell^\chi
=\frac1{\sqrt P}\int_0^P H^\chi(s)
e^{-\mathrm i\xi_\ell s}\,\mathrm ds,
\qquad \xi_\ell=\frac{2\pi\ell}{P}.
\tag{ZF-14}
$$

Suppose the identity-inclusive local certificate supplies

$$
Q_{2,\chi}\ge\int_0^P
|\partial_s^2H_{\mathrm{self}}^\chi(s)|\,\mathrm ds.
$$

For $\ell\ne0$, two integrations by parts in (ZF-14) give

$$
|d_{\ell,\mathrm{self}}^\chi|
\le \frac{Q_{2,\chi}}{\sqrt P\,|\xi_\ell|^2}
\le
\frac{Q_{2,\chi}P_+^2}
{4\pi_-^2s_\#(P_-)|\ell|^2}.
\tag{ZF-15}
$$

There is no $Q_2/|\ell|^2$ candidate at $\ell=0$.  Thus, with the whole
local radius from (ZF-4), define

$$
r_{\ell,\mathrm{self}}^\chi=
\begin{cases}
r_{\mathrm{self}}^\chi,&\ell=0,\\
\displaystyle\min\!\left\{r_{\mathrm{self}}^\chi,
\frac{Q_{2,\chi}P_+^2}
{4\pi_-^2s_\#(P_-)|\ell|^2}\right\},&\ell\ne0.
\end{cases}
\tag{ZF-16}
$$

For $j\in\{\mathrm{reg},\mathrm{off}\}$, let
$r_{j,0}^\chi$ be its real-axis whole-action radius.  A general-curve target
strip certificate additionally supplies a positive signed-arclength shift
$\sigma_a^-$, an upper strip speed $V_{a,+}$, and a pointwise action upper
$A_j^\chi(a)$.  Contour displacement in the sign selected by $\ell$ gives

$$
r_{j,\ell}^{\chi,\mathrm{strip}}
=\frac{2\pi_+V_{a,+}}{s_\#(P_-)}A_j^\chi(a)
E_Q^-\!\left(\alpha_-|\ell|\right),
\qquad
\alpha_-:=\frac{2\pi_-\sigma_a^-}{P_+}>0,
\tag{ZF-17}
$$

and $r_{j,\ell}^\chi=min\{r_{j,0}^\chi,
r_{j,\ell}^{\chi,\mathrm{strip}}\}$.  For the current constant-speed circle
adapter, (ZF-17) reduces to the parameter-strip rate $e^{-a|\ell|}$; the
general statement is (ZF-17), not a circular Fourier/Bessel identity.

Finally put

$$
r_\ell^\chi
=r_{\ell,\mathrm{self}}^\chi
+r_{\ell,\mathrm{reg}}^\chi
+r_{\ell,\mathrm{off}}^\chi,
\qquad |\ell|<L,
\tag{ZF-18}
$$

and replace the uniform radii in (ZF-10) by (ZF-18).  Each minimum is valid
because both entries bound the same exact normalized coefficient.  The three
physical actions are still joined by the triangle inequality before trace or
lifting weighting.  Equations (ZF-15)--(ZF-18) use only $|\ell|<L$; the
identity-inclusive local and strip sequence tails in (ZF-11) continue to own
exactly $|\ell|\ge L$.  Consequently this replacement neither omits nor
duplicates a Fourier mode, and (ZF-13) remains valid.  Any larger finite $L$
is reliable when the same geometry, strip, trace, lifting, propagation, and
finite-value gates pass; its choice is not evidence from inter-level drift.

### Direct zero-centre artificial-wall corollary

The fallback must not use a historically evaluated wall action as an
enclosure unless that action's evaluation error is certified.  This
corollary instead reconstructs both wall bounds from frozen finite
coefficient maps and the shape-general positive-distance inequality.  It is
independent of the material cutoff $L$.

Let $s_L=-1$, $s_R=1$, $D_x=X_R-X_L$, and

$$
\beta_m=\beta+\frac{2\pi m}{d},\qquad
E_m=\exp(\mathrm i\gamma_mD_x),\qquad
\psi_m(y)=d^{-1/2}\exp(\mathrm i\beta_my).
$$

For $w\in\{L,R\}$ put $d_w(t)=s_w(X_w-x(t))$ and suppose
$d_w(t)\ge\delta_w^->0$.  The stored density coordinate is
$\eta=(\tau,\zeta)^{\mathsf T}$ with $\zeta=-\sigma$.  For any frozen state
map $A$, the exact curve actions are

$$
\begin{split}
C_{w,m}^{\mathrm{val}}(A)x
={}&\frac1{2\gamma_m\sqrt d}\int_\Upsilon
 \exp(\mathrm i\gamma_md_w-\mathrm i\beta_my)\\
&\quad\times\bigl[(s_w\gamma_m\nu_x+\beta_m\nu_y)
 \tau(Ax)-\mathrm i\zeta(Ax)\bigr],\mathrm ds,
\end{split}
\tag{ZF-19}
$$

$$
\begin{split}
C_{w,m}^{\mathrm{nor}}(A)x
={}&\frac1{2\sqrt d}\int_\Upsilon
 \exp(\mathrm i\gamma_md_w-\mathrm i\beta_my)\\
&\quad\times\bigl[\mathrm i(s_w\gamma_m\nu_x+\beta_m\nu_y)
 \tau(Ax)+\zeta(Ax)\bigr],\mathrm ds.
\end{split}
\tag{ZF-20}
$$

Thus the target normal derivative cancels the Green coefficient
$1/\gamma_m$.  The normalized flat-wall terms are

$$
F_{L,m}^{\mathrm{val}}
=\frac{\mathrm i}{2\gamma_m}(\xi_{L,m}+E_m\xi_{R,m}),
\qquad
F_{R,m}^{\mathrm{val}}
=\frac{\mathrm i}{2\gamma_m}(E_m\xi_{L,m}+\xi_{R,m}),
\tag{ZF-21}
$$

$$
F_{L,m}^{\mathrm{nor}}
=\tfrac12(\xi_{L,m}-E_m\xi_{R,m}),
\qquad
F_{R,m}^{\mathrm{nor}}
=\tfrac12(-E_m\xi_{L,m}+\xi_{R,m}).
\tag{ZF-22}
$$

There is no additional $d^{-1/2}$ in (ZF-21)--(ZF-22), because each
$\xi_{w,m}$ is already a coefficient in the orthonormal basis $\psi_m$.
The factor $1/2$ in (ZF-22) is the wall jump and is counted exactly once.

Certify $0<q_m^-\le|\gamma_m|\le q_m^+$,
$|\beta_m|\le b_m^+$, $\phi_m\ge|E_m|$, and

$$
\Phi_{w,m}\ge
\sup_{t\in\mathbb T}
\left|\exp(\mathrm i\gamma_md_w(t)-\mathrm i\beta_my(t))\right|.
$$

Let $A_\tau(A)$ and $A_\zeta(A)$ bound the density
$L^1(\mathrm ds)$ norms per unit $\|x\|_{1,\#}$.  For a finite
trigonometric density these are obtained without sampling maxima by the
coefficient triangle inequality; for example
$A_\tau(A)=P_+\sum_j\rho((\tau_j)A)$, where the finite coefficients include
their normalization.  Then (ZF-19)--(ZF-20) give

$$
c_{w,m}^{\mathrm{val}}(A)
=\frac{\Phi_{w,m}}{2q_m^-s_\#(d)}
\bigl[(q_m^++b_m^+)A_\tau(A)+A_\zeta(A)\bigr],
\tag{ZF-23}
$$

$$
c_{w,m}^{\mathrm{nor}}(A)
=\frac{\Phi_{w,m}}{2s_\#(d)}
\bigl[(q_m^++b_m^+)A_\tau(A)+A_\zeta(A)\bigr].
\tag{ZF-24}
$$

Here $s_\#(d)$ is the lower square-root construction from (ZF-1).
Combining (ZF-21)--(ZF-24) term by term, with $|E_m|\le\phi_m$, defines
complete zero-centre row bounds $q_{w,m}(A)$ for the normal action and
$v_{w,m}(A)$ for the value defect.  The latter also contains the shared-trace
selector row $g_{w,m}A$.  In particular,

$$
a_{+,m}=q_{R,m}(G_+)+q_{L,m}(G_+P_+),\qquad
a_{-,m}=q_{L,m}(G_-)+q_{R,m}(G_-P_-).
\tag{ZF-25}
$$

The center/first-cell rows are disjoint from the $n\ge0$ sequences.  Writing
$q_{\mathrm{cen}}=(q_L,q_R)^{\mathsf T}$, their direct bounds follow from

$$
d_L=\mathrm i\gamma_m(q_L-E_mq_R),\qquad
d_R=\mathrm i\gamma_m(E_mq_L-q_R),
$$

$$
j_{-,m}^{\mathrm{cf}}=-d_L+Q_{R,m}G_-c_-,\qquad
j_{+,m}^{\mathrm{cf}}=d_R+Q_{L,m}G_+c_+.
\tag{ZF-26}
$$

For wall lifting, use the frozen $D_+$ and $D_-$ maps directly for the
central traces and the frozen $G_+$ and $G_-$ maps directly for the side
sequences.  If $D_\pm$ are instead extracted from $G_\pm$, first verify the
exact identities $G_+=[D_+;D_+P_+]$ and
$G_-=[D_-P_-;D_-]$.  No approximate floating-point equality is promoted to
an exact algebraic identity.  The central defects are bounded directly from

$$
h_L^{\mathrm{cen}}=D_-c_--(q_L+E_mq_R),\qquad
h_R^{\mathrm{cen}}=D_+c_+-(E_mq_L+q_R).
\tag{ZF-27}
$$

The four internal collars are

$$
V_RG_+P_+^nc_+,quad V_LG_+P_+^{n+1}c_+,quad
V_LG_-P_-^nc_-,quad V_RG_-P_-^{n+1}c_-.
\tag{ZF-28}
$$

The two actions meeting the same normal wall are added before squaring in
(ZF-25), whereas the four physically disjoint value collars in (ZF-28) are
squared separately.  Applying (ZF-7) to every $n\ge0$ sequence and applying
the wall trace and wall-lift weights once gives
$\overline F_{\Gamma_\pm}^2$ and
$\overline F_{\mathrm{lift},\Gamma}^2$ in (ZF-12).

For the current frozen finite supports use the independent wall cutoff
$M_w=256$.  The half-open flat and direct-input support is exactly
$-256{:}255$; its $m=256$ extension is zero, while the curve radius at
$m=256$ is retained.  The positive-distance curve tail begins on both sides
at $|m|=257$.  Thus retained $|m|\le256$ and omitted $|m|\ge257$ are
disjoint, and $M_w$ is not the material cutoff $L$.

Equations (ZF-19)--(ZF-28), together with the existing positive-distance
tail, prove the wall terms in (ZF-12) without a finite kernel evaluation.
The fail-closed gates are: outgoing non-Wood branches and positive $q_m^-$;
positive signed clearances; the normalized wall basis and density sign; exact
half-open flat/direct support and the $m=256$ zero extension; direct use of
the declared frozen $D_\pm,G_\pm$ maps (or exact $G_\pm$ block identities
if extraction is used); the exterior model constants in the trace/lift
weights; disjoint collars; block-power contraction; finite nonnegative
arithmetic bounds; and exclusion of all historical computed wall rows,
jumps, and stored mismatches from governing totals.  Under these gates, the
direct wall construction completes (ZF-13) in the same roundoff-excluded
sense as the other fallback modules.

### Fourth-derivative local coefficient corollary

The local part of (ZF-16) admits a stronger, still zero-centred real-variable
bound when the curve and complete action certificate have four derivatives.
This is an interface theorem for a general $C^6$ regular curve; the current
circle supplies one explicit geometry adapter but is not a theorem
hypothesis.

Let $v(t)=|z'(t)|$, $w(t)=v(t)^{-1}$, and suppose

$$
0<v_-\le v(t)\le v_+,qquad
V_j\ge\|v^{(j)}\|_\infty,quad j=1,2,3.
$$

Define

$$
W_0=v_-^{-1},\qquad W_1=V_1v_-^{-2},
$$

$$
W_2=2V_1^2v_-^{-3}+V_2v_-^{-2},
$$

$$
W_3=6V_1^3v_-^{-4}+6V_1V_2v_-^{-3}+V_3v_-^{-2}.
\tag{ZF-29}
$$

These bound $|w^{(j)}|$ for $0\le j\le3$.  With

$$
\begin{aligned}
A_{41}&=W_0W_1^3+4W_0^2W_1W_2+W_0^3W_3,\\
A_{42}&=7W_0^2W_1^2+4W_0^3W_2,\\
A_{43}&=6W_0^3W_1,\qquad A_{44}=W_0^4,
\end{aligned}
\tag{ZF-30}
$$

and complete identity-inclusive bounds
$H_q^\chi\ge\|\partial_t^qH_{\mathrm{self}}^\chi\|_\infty$,
$1\le q\le4$, put

$$
Q_{4,\chi}=2\pi_+v_+
\sum_{j=1}^4A_{4j}H_j^\chi.
\tag{ZF-31}
$$

Since $\partial_s=w\partial_t$, direct differentiation gives

$$
\begin{split}
\partial_s^4H={}&
[w(w')^3+4w^2w'w''+w^3w''']H'\\
&+[7w^2(w')^2+4w^3w'']H''
+6w^3w'H'''+w^4H''''.
\end{split}
$$

Consequently $Q_{4,\chi}\ge
\int_0^P|\partial_s^4H_{\mathrm{self}}^\chi|,\mathrm ds$.
For constant speed $v$ this reduces to
$Q_{4,\chi}=2\pi_+H_4^\chi/v^3$.

Four integrations by parts in (ZF-14) give, for $\ell\ne0$,

$$
|d_{\ell,\mathrm{self}}^\chi|
\le\frac{Q_{4,\chi}}{\sqrt P|\xi_\ell|^4}
\le\frac{A_{4,\chi}}{|\ell|^4},
\qquad
A_{4,\chi}:=
\frac{Q_{4,\chi}P_+^4}
{16\pi_-^4s_\#(P_-)}.
\tag{ZF-32}
$$

Thus the retained local radius for $\ell\ne0$ is the minimum of its
whole-action, $A_{2,\chi}/|\ell|^2$, and
$A_{4,\chi}/|\ell|^4$ bounds.  The zero mode still uses only the
whole-action bound.

The same fourth-derivative estimate gives the following two-sided omitted
local squares:

$$
T_{4,\mathrm{nor}}^2(L)
=\frac{2Q_{4,\mathrm{nor}}^2P_+^8}
{c_{\mathrm{tr}}^-(2\pi_-)^9}
\left(L^{-9}+\frac{L^{-8}}8\right),
\tag{ZF-33}
$$

$$
\begin{split}
T_{4,\mathrm{val}}^2(L)=2Q_{4,\mathrm{val}}^2
\bigg[&\frac{P_+^7C_0}{(2\pi_-)^8}
\left(L^{-8}+\frac{L^{-7}}7\right)\\
&+\frac{P_+^5C_1}{(2\pi_-)^6}
\left(L^{-6}+\frac{L^{-5}}5\right)\bigg].
\end{split}
\tag{ZF-34}
$$

Here $b_\ell\ge c_{\mathrm{tr}}^-|\xi_\ell|$ and
$e_\ell^{\mathrm{val}}\le C_0+C_1|\xi_\ell|^2$ are the same trace and lift
bounds used in the $p=2$ tail.  The estimates
$\sum_{n=L}^\infty n^{-r}\le L^{-r}+L^{1-r}/(r-1)$ prove
(ZF-33)--(ZF-34).  One may take the smaller of the complete $p=2$ and $p=4$
local tail squares because both bound the same set $|\ell|\ge L$; the chosen
local tail norm is then added to the regular and off-surface tail norms
before squaring.  Retained and omitted indices remain disjoint.

For a general curve the certificate producer must enclose all diagonal-safe
mixed derivatives needed for $H_1,\ldots,H_4$, as well as
$v_-,v_+,V_1,V_2,V_3$.  For the current constant-speed circle adapter,
$D=\partial_t+\partial_u$ annihilates every split factor depending only on
$t-u$, so the existing elementary finite-plus-tail $J/Y$ factor bounds and
frozen density derivatives through order five suffice.  This is a geometry
certificate, not Fourier/Bessel operator diagonalization.  The normal
Maue term containing $\tau'$ is why order five is required.  Identity and
density normalization are included once.  Every denominator, series-ratio,
finite/nonnegative, and tail-ownership condition is fail closed.

### Coefficientwise finite-density DFT-ball corollary

The derivative inputs in (KR-15), (ZF-31), and (ZF-32) need not use one
uniform upper for every density Fourier coefficient.  The following finite
construction gives coefficientwise balls without a library FFT or a
trigonometric-function call.  It concerns only the declared finite density
interpolant and is independent of the inclusion shape.

Let $N_\eta=256$ and

$$
\mathcal I_\eta=\{-128,\ldots,127\}.
$$

For either frozen nodal row map $E_j=E(t_j)$ ($E=\tau$ or
$E=\zeta=-\sigma$), with $t_j=2\pi j/N_\eta$ and
$j=0,\ldots,255$, define the exact trigonometric interpolant by

$$
E(t)=\sum_{m\in\mathcal I_\eta}\widehat E_m e^{\mathrm imt},
\qquad
\widehat E_m=\frac1{N_\eta}\sum_{j=0}^{N_\eta-1}
\omega^{jm}E_j,
\qquad
\omega=e^{-2\pi\mathrm i/N_\eta}=e^{-\mathrm i\pi/128}.
\tag{ZF-35}
$$

The half-open set contains the single even-grid Nyquist representative
$m=-128$; $m=128$ is not a second coefficient.

Construct a rational rectangle for $\omega$ by half angles.  Start with the
exact values $c_1^-=c_1^+=0$ and $s_1^-=s_1^+=1$, corresponding to
$\cos(\pi/2)$ and $\sin(\pi/2)$.  For $r=2,\ldots,7$, set

$$
\begin{aligned}
c_r^-&=s_\#\!\left(\frac{1+c_{r-1}^-}{2}\right),&
c_r^+&=S_\#\!\left(\frac{1+c_{r-1}^+}{2}\right),\\
s_r^-&=s_\#\!\left(\frac{1-c_{r-1}^+}{2}\right),&
s_r^+&=S_\#\!\left(\frac{1-c_{r-1}^-}{2}\right).
\end{aligned}
\tag{ZF-36}
$$

Here $s_\#$ and $S_\#$ are the lower and upper square-root constructions in
(ZF-1).  Monotonicity of the positive square root and the half-angle
identities show that

$$
c_7^-\le\cos(\pi/128)\le c_7^+,
\qquad
s_7^-\le\sin(\pi/128)\le s_7^+.
$$

Put

$$
\omega_c=\frac{c_7^-+c_7^+}{2}
-\mathrm i\frac{s_7^-+s_7^+}{2},
\qquad
\rho_\omega=\frac{c_7^+-c_7^-+s_7^+-s_7^-}{2}.
\tag{ZF-37}
$$

Then $|\omega-\omega_c|_\#\le\rho_\omega$.  Generate balls for all powers
needed in (ZF-35) by

$$
p_0=1,\quad \rho_0^{\mathrm{pow}}=0,\qquad
p_{r+1}=p_r\omega_c,
$$

$$
\rho_{r+1}^{\mathrm{pow}}
=|p_r|_\#\rho_\omega
+|\omega_c|_\#\rho_r^{\mathrm{pow}}
+\rho_r^{\mathrm{pow}}\rho_\omega,
\qquad 0\le r<255.
\tag{ZF-38}
$$

Induction using submultiplicativity of $|\cdot|_\#$ gives
$|\omega^r-p_r|_\#\le\rho_r^{\mathrm{pow}}$ for $0\le r\le255$.
Write $\operatorname{mod}_{256}(jm)$ for the representative of $jm$ in
$\{0,\ldots,255\}$ and define, componentwise in the frozen state index $k$,

$$
\widetilde E_{m,k}
=\frac1{N_\eta}\sum_{j=0}^{N_\eta-1}
p_{\operatorname{mod}_{256}(jm)}E_{j,k},
\qquad
\delta_{m,k}
=\frac1{N_\eta}\sum_{j=0}^{N_\eta-1}
\rho_{\operatorname{mod}_{256}(jm)}^{\mathrm{pow}}|E_{j,k}|_\#,
\tag{ZF-39}
$$

and

$$
b_m^E=\max_k\left(|\widetilde E_{m,k}|_\#+\delta_{m,k}\right).
\tag{ZF-40}
$$

Equations (ZF-38)--(ZF-40) imply

$$
\max_k|\widehat E_{m,k}|_\#\le b_m^E,
\qquad
A_{E,q}:=\sum_{m\in\mathcal I_\eta}|m|^qb_m^E
\ge
\sup_t\|\partial_t^qE(t)\|_{\infty,\#},
\quad0\le q\le5.
\tag{ZF-41}
$$

The second inequality is the finite Fourier triangle inequality.  Thus
$A_{\tau,q}$ and $A_{\zeta,q}$ may replace the uniform-coefficient density
derivative uppers in the complete value and normal integrands.  The normal
Maue factor uses $A_{\tau,q+1}$ for $0\le q\le4$.  Since both the old
uniform construction and (ZF-41) bound the same derivative, their minimum
may be used at each order.

The centres $\widetilde E_m$ are auxiliary centres for exact frozen density
coefficients, not centres for a local, regular-image, off-surface, or wall
action.  Their radii own only the finite map from the declared nodal density
to its exact finite trigonometric interpolant.  They introduce no source
quadrature, target DFT, kernel-series, Ewald, Fourier-omission, or cell-tail
remainder.  The residual actions in (ZF-4)--(ZF-13) remain zero-centred;
source Jacobians, normals, Kress factors, identity terms, trace/lift weights,
and propagation factors remain owned exactly where they were before and are
not multiplied into (ZF-41).

The construction fails closed unless: $N_\eta=256$ and the no-midpoint nodal
phase in (ZF-35) are the declared frozen-density convention; the support is
exactly $\mathcal I_\eta$ with the Nyquist representative present once; all
arguments in (ZF-36) are nonnegative and every lower/upper square-root pair
is ordered; $\rho_\omega$, all $\rho_r^{\mathrm{pow}}$, all
$\delta_{m,k}$, all $b_m^E$, and
all $A_{E,q}$ are finite and nonnegative; the modular indices lie in
$\{0,\ldots,255\}$; $\zeta=-\sigma$ is used; and density, Jacobian, and
identity ownership each pass their existing single-count gates.  A library
FFT, `sin`, or `cos` value may be recorded only as a diagnostic and cannot
authorize the bound.  As throughout (ZF-1)--(ZF-34), ordinary arithmetic
rounding is excluded rather than outward-enclosed.
