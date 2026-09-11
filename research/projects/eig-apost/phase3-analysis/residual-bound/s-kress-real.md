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
