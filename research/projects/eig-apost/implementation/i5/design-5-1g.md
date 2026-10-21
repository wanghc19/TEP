# I5.1g minimum-energy value-jump lifting design

## Scope and result

I5.1g replaces the historical arbitrary cubic lifting profile by the
shape-general minimum-energy comparison theorem (ME-1)--(ME-31) in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail]].
It changes only the value-jump lifting upper.  The artificial-wall normal
module, the material normal module, the exact-kernel reconstruction, and all
frozen eigenvalue, density, QZ, Rayleigh, and propagation data remain
unchanged.

The broken space is the energy-square-summable Hilbert direct sum over all
material pieces and guide cells; the bare Cartesian product is not used when
the half-guide family is countable.  The governing statement is

$$
B_{\mathrm{lift}}
=q_{\mathrm{all}}(a)
\le
\left[
\sum_{\Lambda\in\mathfrak G}
\bigl(F_{\Lambda,L}^2+T_\Lambda^2\bigr)
\right]^{1/2}.
\tag{I5.1g-1}
$$

Here $q_{\mathrm{all}}$ is one simultaneous minimum over every physical
value-jump constraint.  It is not a sum of per-interface full-domain minima.
The factor multiplying the correction energy is exactly $1$, not the
historical factor $2$.  The proof applies Cauchy--Schwarz once to
$(\nabla e,\sqrt{\mu\rho}e)$ and
$(\nabla v,-\sqrt{\mu\rho}v)$.

The theorem is `ESTABLISHED` under its explicit geometry and coefficient
gates.  The current frozen instance remains `CONDITIONAL GO` until the new
weights and paired wall jumps are evaluated.  Special-function and ordinary
finite-arithmetic effects remain
$\Delta_{\mathrm{sf}}=\mathrm{UNRESOLVED}$ and
$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$.

## Material-interface weights

For each material component store its perimeter $P$, two collar widths
$h_q$, curvature bound $\kappa_*$, Jacobian bounds

$$
\theta_q=1-h_q\kappa_*>0,
\qquad
\Theta_q=1+h_q\kappa_*,
\qquad q\in\{+,-\},
\tag{I5.1g-2}
$$

and sidewise material upper bounds $\overline\rho_q$.  For
$\xi_\ell=2\pi\ell/P$, compute

$$
A_q=\Theta_q,
\qquad
B_{q,\ell}=\frac{\xi_\ell^2}{\theta_q}
+\mu\overline\rho_q\Theta_q,
$$

$$
\kappa_{q,\ell}
=\sqrt{A_qB_{q,\ell}}\,
\coth\!\left(h_q\sqrt{B_{q,\ell}/A_q}\right),
\qquad
\overline w_{\Lambda,\ell}
=\frac{\kappa_{+,\ell}\kappa_{-,\ell}}
{\kappa_{+,\ell}+\kappa_{-,\ell}}.
\tag{I5.1g-3}
$$

Use the continuous limit $\kappa_{q,\ell}=A_q/h_q$ if
$B_{q,\ell}=0$.  The current problem has $\mu>0$, so this limit is an audit
branch rather than the expected path.  Do not silently assign equal $+$ and
$-$ data: equality is permitted only after the two stored side certificates
have been compared.

The retained material contribution is

$$
F_{\Lambda,L}^2
=\sum_{|\ell|<L}\overline w_{\Lambda,\ell}
\bigl(\|\widetilde a_{\Lambda,\ell}\|_2
+\epsilon_{\Lambda,\ell}\bigr)^2.
\tag{I5.1g-4}
$$

The center is the complete physical value jump.  In the current signed-centre
ledger this means

$$
\widetilde a_{\Lambda,\ell}
=\widetilde a_{\ell}^{\mathrm{self,val}}
+\widetilde a_{\ell}^{\mathrm{reg,raw,val}}
+\widetilde a_{\ell}^{\mathrm{off,raw,val}},
$$

$$
\epsilon_{\Lambda,\ell}
=\epsilon_{\ell}^{\mathrm{self,val}}
+\epsilon_{\ell}^{\mathrm{reg,val}}
+\epsilon_{\ell}^{\mathrm{off,val}}.
\tag{I5.1g-5}
$$

The identity jump is inside the self row once.  The regular and off-surface
rows have no identity.  The same complete center and radius are used before
any propagation or cell-tail operation.

For the singleton state $q_0$, side maps $G_\varsigma$, propagation matrices
$P_\varsigma$, and state vectors $c_\varsigma$, the explicit retained
material sum is

$$
\begin{aligned}
F_{\Lambda,L}^2
=\sum_{|\ell|<L}\overline w_{\Lambda,\ell}
\Bigg[&
\bigl(\|\widetilde j_\ell q_0\|_2
+\epsilon_\ell\|q_0\|_2\bigr)^2\\
&+\sum_{\varsigma\in\{+,-\}}
\sum_{n=0}^{J-1}
\bigl(\|\widetilde j_\ell G_\varsigma
P_\varsigma^nc_\varsigma\|_2
+\epsilon_\ell\|G_\varsigma
P_\varsigma^nc_\varsigma\|_2\bigr)^2
\Bigg].
\end{aligned}
\tag{I5.1g-5a}
$$

Here $\widetilde j_\ell$ and $\epsilon_\ell$ are the complete row and radius
in (I5.1g-5).  If the block-power certificate gives
$\sum_{n\ge J}\|P_\varsigma^nc_\varsigma\|_2^2
\le\mathcal C_\varsigma\|P_\varsigma^Jc_\varsigma\|_2^2$, its single owner is

$$
T_{\Lambda,\mathrm{cell}}^2
=\sum_{\varsigma\in\{+,-\}}
\mathcal C_\varsigma\|P_\varsigma^Jc_\varsigma\|_2^2
\sum_{|\ell|<L}\overline w_{\Lambda,\ell}
\bigl(\|\widetilde j_\ell G_\varsigma\|_2
+\epsilon_\ell\|G_\varsigma\|_2\bigr)^2.
\tag{I5.1g-5b}
$$

Equations (I5.1g-5a)--(I5.1g-5b) replace only the historical lifting
multiplier and outer factor.  They do not alter the frozen state maps or the
normal-defect assembly.

## Material omitted modes

Compute a reliable enclosure

$$
Q_{\Lambda,4}^{\mathrm{loc}}
\ge\int_0^P|\partial_s^4a_\Lambda^{\mathrm{loc}}(s)|\,ds.
\tag{I5.1g-6}
$$

For a general parameter $t$, implement the recursion

$$
q_0=a_\Lambda^{\mathrm{loc}},
\qquad q_{j+1}=|z'|^{-1}\partial_tq_j,
\qquad
Q_{\Lambda,4}^{\mathrm{loc}}
\ge\int_0^{2\pi}|q_4(t)|\,|z'(t)|\,dt.
\tag{I5.1g-7}
$$

This is a certificate computation; a sampled maximum is not accepted.  Set

$$
C_{0,q}=\frac{\Theta_q}{h_q}
+\Theta_q\sqrt{\mu\overline\rho_q},
\qquad
C_{1,q}=\sqrt{\frac{\Theta_q}{\theta_q}},
$$

$$
W_0=\frac{C_{0,+}+C_{0,-}}4,
\qquad
W_1=\frac{C_{1,+}+C_{1,-}}4.
\tag{I5.1g-8}
$$

The local p4 tail is

$$
T_{\Lambda,4}^{\mathrm{loc}\,2}
=\frac{2(Q_{\Lambda,4}^{\mathrm{loc}})^2}{P}
\left\{
W_0\left(\frac P{2\pi}\right)^8
\left(L^{-8}+\frac{L^{-7}}7\right)
+W_1\left(\frac P{2\pi}\right)^7
\left(L^{-7}+\frac{L^{-6}}6\right)
\right\}.
\tag{I5.1g-9}
$$

This term owns only the local omitted Fourier component.  Regular-image and
off-surface omitted components retain the explicit tails proved in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail]]
and
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-kress-real]].
Because those components need not be orthogonal, use

$$
T_\Lambda^{\mathrm{mat}}
\le T_{\Lambda,4}^{\mathrm{loc}}
+T_\Lambda^{\mathrm{reg}}+T_\Lambda^{\mathrm{off}}
\tag{I5.1g-10}
$$

and square only the combined result.  No material tail owns a wall or cell
propagation term.

## Artificial-wall weights

For the normalized wall basis

$$
\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_my},
\qquad
\beta_m=\beta+\frac{2\pi m}{d},
$$

store two flat collar widths $h_q$ and two sidewise upper material bounds
$\overline\rho_q$.  Compute

$$
\lambda_{q,m}=\sqrt{\beta_m^2+\mu\overline\rho_q},
\qquad
\kappa_{q,m}^w=\lambda_{q,m}\coth(h_q\lambda_{q,m}),
$$

$$
\overline w_m^w
=\frac{\kappa_{+,m}^w\kappa_{-,m}^w}
{\kappa_{+,m}^w+\kappa_{-,m}^w}.
\tag{I5.1g-11}
$$

This Dirichlet zero-rim lifting weight must not be confused with the
$2\lambda_m\tanh(h_{\mathrm{tr}}\lambda_m)$ wall-normal trace weight.  The
normal module is unchanged.

For retained $|m|\le256$, define $V_w=g_w-F_w-C_w$ and orient every wall
away from the central cell.  With

$$
h_L^{\mathrm{cf}}=D_-c_--(q_L+E q_R),
\qquad
h_R^{\mathrm{cf}}=D_+c_+-(E q_L+q_R),
$$

the two central/first jumps are

$$
a_-^{\mathrm{cf}}=h_L^{\mathrm{cf}}-V_RG_-c_-,
\qquad
a_+^{\mathrm{cf}}=h_R^{\mathrm{cf}}-V_LG_+c_+.
\tag{I5.1g-12}
$$

The internal jumps, with the trace farther from the central cell minus the
trace nearer to it, are

$$
a_{+,n}=(V_RG_+-V_LG_+P_+)P_+^nc_+,
$$

$$
a_{-,n}=(V_LG_--V_RG_-P_-)P_-^nc_-,
\qquad n\ge0.
\tag{I5.1g-13}
$$

If the analytic row radii of $V_L,V_R$ are $\epsilon_{L,m},
\epsilon_{R,m}$, the paired row centers and radii are

$$
\widetilde W_{+,m}=\widetilde V_{R,m}G_+
-\widetilde V_{L,m}G_+P_+,
\qquad
r_{+,m}=\epsilon_{R,m}\|G_+\|_2
+\epsilon_{L,m}\|G_+P_+\|_2,
$$

$$
\widetilde W_{-,m}=\widetilde V_{L,m}G_-
-\widetilde V_{R,m}G_-P_-,
\qquad
r_{-,m}=\epsilon_{L,m}\|G_-\|_2
+\epsilon_{R,m}\|G_-P_-\|_2.
\tag{I5.1g-13a}
$$

The central/first analytic radii are respectively
$\epsilon_{R,m}\|G_-c_-\|_2$ and
$\epsilon_{L,m}\|G_+c_+\|_2$.  Errors in the finite flat, phase, selector,
and central terms remain in
$\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$;
they are not silently set to zero by (I5.1g-13a).

Equations (I5.1g-12)--(I5.1g-13) are the governing rows.  Delete no historical
data, but do not also add the old central rows, the two first-cell collars,
or the four separate $V_{L/R}$ sequences.  The actual physical jump is
counted once.  A shared selector is cancelled only after an exact identity
gate; otherwise form both raw traces and subtract them.

For a row center $C_m$ and analytic radius $r_m$, define the new weighted row
functional

$$
\Omega_w(C,r)
=\sum_{|m|\le256}\overline w_m^w
(\|C_m\|_2+r_m)^2.
\tag{I5.1g-14}
$$

Use $\Omega_w$ on the complete paired row in (I5.1g-13), then multiply by
the existing block-power sum once.  A central/first row in (I5.1g-12) has no
propagation factor.  Do not apply the new weight separately to $V_L$ and
$V_R$ before pairing.

## Artificial-wall omitted modes

Put

$$
m_0=257,
\quad \Delta_\beta=2\pi/d,
\quad k_e=\widehat k\sqrt{\rho_e},
\quad b_0=\Delta_\beta m_0-|\beta|-k_e>0.
\tag{I5.1g-15}
$$

The equality $k_e=\widehat k$ is permitted only under the explicit
$\rho_e=1$ gate.  The affine weight bound is

$$
\overline w_m^w\le U_0+U_1|m|,
$$

$$
U_0=\frac14\left(
h_+^{-1}+h_-^{-1}
+\sqrt{\mu\overline\rho_+}
+\sqrt{\mu\overline\rho_-}\right)+\frac{|\beta|}{2},
\qquad
U_1=\frac\pi d.
\tag{I5.1g-16}
$$

For each complete actual-jump row label $s$ and sign
$\epsilon\in\{+,-\}$, construct the positive-distance bound

$$
|a_{s,\epsilon n}(x)|
\le C_{s,\epsilon}e^{-\delta\Delta_\beta n}\|x\|_2,
\qquad n\ge257.
\tag{I5.1g-17}
$$

The constant $C_{s,\epsilon}$ must include all physical curve actions in the
paired row, the quasi-periodic Green normalization $1/(2\sqrt d)$, density
$L^1(ds)$ bounds, the $1/\gamma_m$ value factor using $b_0$, the exterior
wavenumber, and the complete frozen state-map contraction.  It is not legal
to reuse a constant for one curve action after the actions have been paired.
A direct interface from the existing separated-action theorem is

$$
C_{s,\epsilon}
=e^{\delta(k_e+|\beta|)}D_{s,\epsilon},
\tag{I5.1g-18}
$$

where each contributing curve/map term in $D_{s,\epsilon}$ is bounded by

$$
\frac{1}{2\sqrt d}
\left(2R_\beta\|\tau\|_{L^1(ds)}
+\frac{\|\sigma\|_{L^1(ds)}}{b_0}\right)
\times\text{its frozen state-map norm},
\tag{I5.1g-19}
$$

and $R_\beta\ge\sup_{|m|\ge257}|\beta_m|/\kappa_m$ is certified.  Sum all
terms in one actual jump before inserting (I5.1g-18).

With $r_w=e^{-2\delta\Delta_\beta}$, define

$$
S_0^w=\frac{r_w^{257}}{1-r_w},
\qquad
S_1^w=r_w^{257}
\left(\frac{257}{1-r_w}+\frac{r_w}{(1-r_w)^2}\right).
\tag{I5.1g-20}
$$

Then

$$
T_{s,w}^2
\le(C_{s,+}^2+C_{s,-}^2)
(U_0S_0^w+U_1S_1^w)\|x\|_2^2.
\tag{I5.1g-21}
$$

For (I5.1g-13), sum $\|P_\pm^nc_\pm\|_2^2$ by the existing block-power
certificate once.  For (I5.1g-12), use its fixed state vector and no
block-power factor.  The frozen flat-wall density support $-256{:}255$ is
zero outside that half-open set.  The curve coefficient at $m=256$ is still
retained, so $|m|\le256$ and $|m|\ge257$ are disjoint and exhaustive.

## Input and field contract

The evaluator consumes only frozen data and separately generated geometry
certificates.

| Theorem object | Required finite input | Code-side requirement |
|---|---|---|
| $\mu$ and $\overline\rho_q$ | shifted energy parameter and sidewise material upper bounds | use an unambiguous local alias; do not infer a material side from a row label |
| $P,h_q,\kappa_*,\theta_q,\Theta_q$ | perimeter, side collar widths, reach/curvature/clearance certificate | store both sides; gate (I5.1g-2), injectivity, and disjointness |
| $\overline w_{\Lambda,\ell}$ | derived from (I5.1g-3) | stable positive evaluation of $x\coth x$ and finite positive result |
| material jump balls | existing signed self/regular/off centers and analytic radii | combine into one physical jump before weighting |
| $Q_{\Lambda,4}^{\mathrm{loc}}$ | interval/Taylor enclosure of (I5.1g-7) for the local self action | sampled maxima and inter-grid drift forbidden |
| $h_\pm^w,\overline\rho_\pm^w$ | two wall collar certificates | no automatic equality of the sides |
| $V_L,V_R,h_{L/R}^{\mathrm{cf}},G_\pm,P_\pm,c_\pm$ | frozen wall rows and maps | assemble exactly (I5.1g-12)--(I5.1g-13) |
| wall retained radii | existing curve-row quadrature and finite-evaluation radii | pair left/right actions before (I5.1g-14) |
| $D_{s,\epsilon}$ | complete positive-distance density/map constants | include $1/(2\sqrt d)$ and $1/\gamma_m$ ownership |
| propagation | existing Lyapunov or block-power certificate | apply once to the paired row |

No frozen artifact field or historical MATLAB API is renamed.  New field
names belong only to the I5.1g evaluator and must be recorded in
`implementation/i5/SYMBOL.md` if implementation proceeds.

## Assembly and stopping rule

For each material component, use (I5.1g-4) for retained modes and the square
of (I5.1g-10) for omitted modes.  For each physical wall, use
(I5.1g-12)--(I5.1g-14), (I5.1g-21), and exactly one block-power tail.
Pairwise disjoint collars then give

$$
\widehat B_{\mathrm{lift}}^{\mathrm{ME}}
=\left[
\sum_{\Lambda\in\mathfrak G}
\bigl(F_{\Lambda,L}^2+T_\Lambda^2\bigr)
\right]^{1/2}.
\tag{I5.1g-22}
$$

The complete numerator remains

$$
\|R\|_{\mu,*}
\le
\widehat B_{\Gamma_\pm}
+\widehat B_\Upsilon
+\widehat B_{\mathrm{lift}}^{\mathrm{ME}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}.
\tag{I5.1g-23}
$$

Only the lifting term changes.  Select $L$ from the explicit material tails
and select the wall cutoff from (I5.1g-21).  Then choose even $N$ with

$$
N>2\max\{L,M_\eta\}
\tag{I5.1g-24}
$$

and increase $N$ only when a proved retained-row radius misses its assigned
tolerance.  No resolution drift, plateau, Richardson estimate, or safety
factor is admissible.

## Fail-closed gates and failure semantics

The evaluator returns conditional failure unless all of the following hold:

1. the global broken energy space and simultaneous jump list are exhaustive;
2. every physical value jump is represented exactly once and the correction
   sign is $J_{\mathrm{all}}e=-a$;
3. every collar is injective, has positive Jacobian lower bound, terminates at
   a zero-trace rim, and is disjoint from every other selected collar;
4. all sidewise material bounds and $\mu$ are positive and finite;
5. every retained coefficient has a center and analytic radius, with the
   identity owned once;
6. local p4, regular-image, off-surface, wall-high, and cell tails have
   disjoint owner and index ledgers;
7. wall orientation and state indices match (I5.1g-12)--(I5.1g-13), the
   shared selector is either proved identical or not cancelled, and
   $b_0>0$;
8. all $D_{s,\epsilon}$ constants cover complete paired actions with their
   normalizations and all propagation tails use one proved block-power bound;
9. cutoff choice is remainder driven and (I5.1g-24) holds strictly.

A finite but wide upper is reported as such.  A missing geometry, row-radius,
normalization, or owner gate is a mathematical `CONDITIONAL` result, not a
reason to insert a sampled or empirical substitute.

## Current status and review record

The Researcher derived (I5.1g-1)--(I5.1g-24) from the global strong residual
and elementary one-dimensional minimization.  No external theorem is invoked;
the only functional-analytic ingredients are trace continuity, coercivity,
closed affine projection, and product-space Cauchy--Schwarz.  The independent
Skeptic returned `PASS WITH CONDITIONS / GO` after requiring the simultaneous
jump quotient, the complete wall quasiperiodic corollary, fixed wall
orientation, and explicit tail ownership.  Those conditions are included
above.

After the theorem and pre-run reviews, the v6 canonical run instantiated these
rows with $L=256$ and $N=1024$.  It obtained

$$
\widehat B_{\Gamma_\pm}=1.8732119857082978\,10^{-10},\qquad
\widehat B_\Upsilon=1.5565169597620056\,10^{-4},
$$

$$
\widehat B_{\mathrm{lift}}^{\mathrm{ME}}
=3.3621248621896728\,10^{-2},\qquad
\mathcal M_{\mathrm{ideal}}=3.3776900505194128\,10^{-2}.
$$

The material retained, high-mode, and block-power-cell lifting norms are,
respectively,
$3.7258881967329352\,10^{-4}$,
$3.3619184054150500\,10^{-2}$, and
$5.4002552971061359\,10^{-11}$.  The complete artificial-wall lifting norm
is $5.9177263353292294\,10^{-15}$.  The retained harmonic comparison weight
ranges from $15.237473472248155$ to $780.78182496579905$; it is the governing
modewise substitute for a single scalar $C_{\mathrm{lift},\Gamma}$.
Relative to the v5 values
$B_{\mathrm{lift}}=0.056438633545021551$ and
$\mathcal M_{\mathrm{ideal}}=0.056448305344888337$, the new lifting and total
values decrease by $40.4286629387\%$ and $40.1631274866\%$.  This comparison
is descriptive only; the selection and reliability gates do not use
inter-run drift.

All analytic ownership, geometry, cutoff, propagation, finite/nonnegative,
and zero-solve gates passed.  The independent post-run Skeptic verdict is
`PASS WITH CONDITIONS / GO` for the conditional ideal result and `STOP` for
any reliable or certified claim.  Finite special-function and ordinary
floating-point enclosure errors remain
$\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$ with both terms `UNRESOLVED`.
Consequently the run establishes only

$$
\|R\|_{\mu,*}
\le \mathcal M_{\mathrm{ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}},
$$

conditional on the exact-special-function/real-arithmetic layer documented
above.  It does not supersede the wider I5.1e roundoff-excluded fallback.
The complete command, numerical decomposition, and resources are recorded in
`test/i5/residual-numerator-v6/README.md`; the independent review is
`review-5-1g.md`.

## Attempt 2: piecewise real-variable certificate for $Q_{\Gamma,4}$

This section preregisters the I5.1g attempt-2 theorem-to-code contract.  It
does not change (I5.1g-1)--(I5.1g-24), any frozen field, or the three-module
ownership.  It replaces only the global absolute derivative majorants used
to certify the local Kress source error, target DFT error, and local omitted
Fourier tail.  In particular, it is not a sampled-max refinement and its
validity does not depend on comparison with v6.

### Source of the v6 width

For the current circle adapter, `signed_local_center_v6.m` first bounds every
entire-series factor on the full interval
$x\in[0,4R^2]$, then applies global Leibniz triangles to the complete frozen
density, and finally forms

$$
H_q^\chi
=\|J_\chi^{(q)}\|_\infty
+8\pi\log(2)C_{1,q}^\chi+2\pi C_{2,q}^\chi,
\qquad
Q_{\Gamma,4}^\chi=2\pi H_4^\chi/R^3.
\tag{I5.1g-25}
$$

Here $\chi\in\{\mathrm{val},\mathrm{nor}\}$.  The construction is a valid
global triangle enclosure, but it discards target localization, relative
coordinate localization, and all phase information in the finite density.
The local value high tail is proportional to
$(Q_{\Gamma,4}^{\mathrm{val}})^2$, which explains why this otherwise valid
certificate is the dominant width owner in v6.

### Finite product covering

Write the exact, density-inclusive local action in relative coordinates as

$$
H^\chi(t)=J^\chi(t)+\int_{-\pi}^{\pi}
\left[K_1^\chi(t,t-h)g(h)+K_2^\chi(t,t-h)\right]\mathrm dh,
\qquad
g(h)=\log\left(4\sin^2\frac h2\right).
\tag{I5.1g-26}
$$

The $K_j^\chi$ are the complete signed Kress integrands: they already contain
the frozen density $\eta=(\tau,-\sigma)^{\mathsf T}$, source Jacobian,
normal/tangent factors, and the Maue factor.  In the normal case the common
cotangent and hypersingular principal parts are cancelled before a box is
bounded.

Let $\{I_a\}_{a=1}^{n_t}$ partition the target circle and let
$\{H_b\}_{b=1}^{n_h}$ partition the wrapped relative interval
$[-\pi,\pi]$.  Use periodic lifts to define

$$
\mathcal B_{ab}
=\{(t,u):t\in I_a,\ h=t-u\pmod{2\pi}\in H_b\},
\qquad \mathrm D_\parallel=\partial_t+\partial_u.
\tag{I5.1g-27}
$$

The two partition dimensions have different meanings: $n_t$ localizes the
target variable, while $n_h$ localizes the relative source coordinate.  All
boxes cover the torus, with overlap only on their closed endpoints.  A box
meeting $h=0$ must use the divided-difference/diagonal formulas for
$D_{\kappa,2}^*$ and
$C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}}$; direct
interval evaluation of a naked $1/q$ or $1/q^2$ is forbidden.

For $0\le q\le4$, require finite certified bounds

$$
C_{j,q;ab}^\chi
\ge\sup_{\mathcal B_{ab}}
\|\mathrm D_\parallel^qK_j^\chi(t,u)\|_{2\leftarrow2},
\qquad
C_{j,4;ab}^{\chi,\mathrm{src}}
\ge\sup_{\mathcal B_{ab}}
\|\partial_u^4K_j^\chi(t,u)\|_{2\leftarrow2}.
\tag{I5.1g-28}
$$

Here and in (I5.1g-30)--(I5.1g-32), the complete integrand is a row map
from the frozen state coefficient vector to the scalar trace defect, and
$\|\cdot\|_{2\leftarrow2}$ is its Euclidean row/operator norm.  It is not an
entrywise maximum.  For a genuinely scalar factor this norm reduces to the
ordinary absolute value.

They are produced by interval or Taylor-model evaluation of the explicit
diagonal-safe formulas.  Every Taylor remainder is bounded from the declared
$C^6$ geometry jets and the exact finite density coefficients; an enclosure
must not assume a fifth derivative of a merely $C^4$ complete integrand.
Direct interval evaluation of the displayed fourth-derivative formula is the
fallback.  In the Maue term, four source derivatives require density
derivatives through order five because the complete integrand already
contains $\tau'$.

Let $\Lambda_b$ be a certified upper for
$\int_{H_b}|g(h)|\,\mathrm dh$.  For the symmetric diagonal panel
$H_b=[-b,b]$, $0<b\le1$, the elementary sine bounds give

$$
\Lambda_b
\le4b\left(1-\log b+\log\frac\pi2\right).
\tag{I5.1g-29}
$$

Every non-diagonal panel has a certified positive lower bound for
$|\sin(h/2)|$ and may use its interval supremum times $|H_b|$.
The relative partition includes $0$ and the sign-change points
$\pm\pi/3$ as explicit breakpoints.  Thus all logarithmic moments are finite
analytic enclosures, not values inferred from nodes.

Changing variables before differentiating gives
$\mathrm dK(t,t-h)/\mathrm dt=\mathrm D_\parallel K(t,t-h)$, so the logarithm is never
differentiated.  Dominated differentiation is justified by
$K_j^\chi\in C^4(\mathbb T^2)$ and $g\in L^1(-\pi,\pi)$.  If

$$
J_{q,a}^\chi\ge\sup_{t\in I_a}
\|(J^\chi)^{(q)}(t)\|_{2\leftarrow2},
$$

then

$$
H_{q,a}^\chi
:=J_{q,a}^\chi+
\sum_b\left(C_{1,q;ab}^\chi\Lambda_b
+C_{2,q;ab}^\chi|H_b|\right)
\ge\sup_{t\in I_a}
\|(H^\chi)^{(q)}(t)\|_{2\leftarrow2}.
\tag{I5.1g-30}
$$

This is the first strict improvement opportunity over (I5.1g-25): the
integration in $h$ and then in $t$ is retained instead of being replaced by
one full-torus supremum.

### Piecewise arclength derivative and the local high tail

Put $s(t)=|z'(t)|$ and $w(t)=s(t)^{-1}$.  On each target panel certify
$s_a^+\ge\sup_{I_a}s$ and

$$
\begin{aligned}
A_{41,a}&\ge\sup_{I_a}|w(w')^3+4w^2w'w''+w^3w'''|,\\
A_{42,a}&\ge\sup_{I_a}|7w^2(w')^2+4w^3w''|,\\
A_{43,a}&\ge\sup_{I_a}|6w^3w'|,
&A_{44,a}&\ge\sup_{I_a}|w^4|.
\end{aligned}
\tag{I5.1g-31}
$$

The chain rule already proved in (ZF-29)--(ZF-31), now integrated panel by
panel, gives the shape-general certificate

$$
Q_{\Gamma,4}^{\chi,\mathrm{pw}}
:=\sum_a |I_a|s_a^+
\left(\sum_{j=1}^4A_{4j,a}H_{j,a}^\chi\right)
\ge\int_\Gamma
\|\partial_s^4H^\chi\|_{2\leftarrow2}\,\mathrm ds.
\tag{I5.1g-32}
$$

Consequently (ME-17)--(ME-18) remain valid after replacing the global
$Q_{\Gamma,4}^{\mathrm{loc}}$ by
$Q_{\Gamma,4}^{\mathrm{val},\mathrm{pw}}$.  The analogous normal quantity
may replace the normal p4 alternative.  Constant speed merely reduces
(I5.1g-31) to $A_{44}=s^{-4}$; it is an instance simplification, not a
theorem hypothesis.

### Piecewise source and target radii

At each exact evaluation target $t_i\in I_a$, (I5.1g-28) gives

$$
S_{j,4}^\chi(t_i)
\le\sum_b |H_b|C_{j,4;ab}^{\chi,\mathrm{src}}.
\tag{I5.1g-33}
$$

Insert these two bounds in (KR-16)--(KR-17), and propagate them with
(KR-20).  This replaces only the source Kress radius.  The source density,
Jacobian, normal, and Maue factors are already present in (I5.1g-28) and are
not multiplied a second time.

For a shape-general target rule, form

$$
\Psi_\ell^\chi(t)
=s(t)H^\chi(t)e^{-\mathrm i\xi_\ell a(t)},
\qquad a'(t)=s(t),
\tag{I5.1g-34}
$$

and use interval automatic differentiation of the certified jets in
(I5.1g-30)--(I5.1g-31) to obtain

$$
P_{\ell,4;a}^\chi
\ge\sup_{t\in I_a}
\|\partial_t^4\Psi_\ell^\chi(t)\|_{2\leftarrow2}.
$$

This last bound has no hidden differentiation constant.  If
$S_{r,a}\ge\sup_{I_a}|s^{(r)}|$, $0\le r\le4$, define

$$
G_{r,a}^\chi
=\sum_{k=0}^r\binom rk S_{k,a}H_{r-k,a}^\chi,
\qquad 0\le r\le4,
$$

and, with $x_\ell=|\xi_\ell|$,

$$
\begin{aligned}
E_{0,a}&=1, & E_{1,a}&=x_\ell S_{0,a},\\
E_{2,a}&=x_\ell S_{1,a}+x_\ell^2S_{0,a}^2,\\
E_{3,a}&=x_\ell S_{2,a}+3x_\ell^2S_{0,a}S_{1,a}
+x_\ell^3S_{0,a}^3,\\
E_{4,a}&=x_\ell S_{3,a}+4x_\ell^2S_{0,a}S_{2,a}
+3x_\ell^2S_{1,a}^2+6x_\ell^3S_{0,a}^2S_{1,a}
+x_\ell^4S_{0,a}^4.
\end{aligned}
$$

The finite Leibniz bound

$$
P_{\ell,4;a}^\chi
:=\sum_{r=0}^4\binom4rG_{r,a}^\chi E_{4-r,a}
\tag{I5.1g-34a}
$$

follows from the exact fourth derivative of
$e^{-\mathrm i\xi_\ell a(t)}$ and uses only the displayed certified jets.

For the constant-speed branch, including the current circle adapter, let
$r_\ell=|\ell|<N/2$, choose the
fixed alias cutoff $Q_A\ge1$, and put $q_0=Q_A+1$.  The finite sum plus the
first omitted term and monotone integral tail is

$$
\begin{aligned}
A_{\ell,N,Q_A}^{(4)}={}&
\sum_{q=1}^{Q_A}\left[(qN-r_\ell)^{-4}+(qN+r_\ell)^{-4}\right]\\
&+(q_0N-r_\ell)^{-4}
+\frac{1}{3N(q_0N-r_\ell)^3}\\
&+(q_0N+r_\ell)^{-4}
+\frac{1}{3N(q_0N+r_\ell)^3}.
\tag{I5.1g-35}
$$

The p4 coefficient bound and the exact DFT alias identity then give

$$
\epsilon_{\ell}^{\chi,\mathrm{tgt,alias}}
\le
\frac{Q_{\Gamma,4}^{\chi,\mathrm{pw}}P^{7/2}}{(2\pi)^4}
A_{\ell,N,Q_A}^{(4)},
\qquad |\ell|<N/2.
\tag{I5.1g-35a}
$$

The powers of $P$ and $2\pi$ in (I5.1g-35a) are forced by the normalized
arclength coefficient
$P^{-1/2}\int_0^PH(s)e^{-2\pi\mathrm i\ell s/P}\,\mathrm ds$; no additional
factor is applied downstream.  This is exactly the p4 analogue of
(KR-19a)--(KR-19b), including its single Nyquist convention.

For a nonconstant-speed chart, the independent general-parameter alternative
uses (I5.1g-34)--(I5.1g-34a).  Since the target trapezoidal rule integrates
the already phase-weighted periodic function $\Psi_\ell$, its aliases are at
$qN$ and four integrations by parts give

$$
\epsilon_{\ell}^{\chi,\mathrm{tgt,param}}
\le\frac{2\zeta(4)}{\sqrt P\,N^4}
\sum_a|I_a|P_{\ell,4;a}^\chi.
\tag{I5.1g-35b}
$$

The normalization in (I5.1g-35b) is the one in (KR-19): the target
functional is
$P^{-1/2}\int_0^{2\pi}\Psi_\ell(t)\,\mathrm dt$ and its discrete rule is
$(2\pi/N)P^{-1/2}\sum_i\Psi_\ell(t_i)$.  Formula (I5.1g-35a) bounds the
coefficients of $H$ and therefore contains $|\ell+qN|^{-4}$; formula
(I5.1g-35b) bounds the Fourier aliases of $\Psi_\ell$ and therefore contains
$(qN)^{-4}$ but has $\ell$ inside $P_{\ell,4;a}^\chi$.  These two derivations
must not be mixed.

Whenever both branch hypotheses are certified, the evaluator may use the
smaller complete bound (I5.1g-35a) or (I5.1g-35b); it may not add the two
alternatives or use their difference as evidence.

### Exact owner telescope

The retained local center remains the signed finite-series Kress action.  No
new center is introduced.  The exact identity (KR-21a) is retained verbatim:

$$
\begin{aligned}
d_\ell^{\mathrm{self}}-\widetilde d_\ell^{\mathrm{self}}
={}&\{\mathcal D_\ell[J+\mathcal AK]
-\mathcal D_{\ell,N}[J+\mathcal AK]\}\\
&+\mathcal D_{\ell,N}[(\mathcal A-Q_N)K]
+\mathcal D_{\ell,N}[Q_N(K-K_Q)].
\end{aligned}
\tag{I5.1g-36}
$$

The three lines are owned once by target DFT, source Kress, and finite-series
truncation, respectively.  The identity $J$ occurs only in the first line
and in the center.  Retained positive series terms plus factorial tails used
inside (I5.1g-28) bound the *magnitude of the exact kernel* and are certificate
constants, not a second additive series error.  The additive
$\epsilon_\ell^{\mathrm{series}}$ continues to be exactly (KR-21b).

After (I5.1g-36), self, regular-image, and off-surface centers and radii are
combined with the physical signs in (KR-26).  The new p4 omitted tail owns
only the local set $|\ell|\ge L$; existing regular-image and off-surface tails
retain their separate owners and the three norms are added before one square
as in (ME-20).  Retained rows, cell block powers, wall rows, wall high modes,
and the minimum-energy weights are unchanged.  Propagation is applied once
to the already assembled physical jump.

### Shape-general enclosure interface and circle adapter

The governing certificate accepts a finite, complete interval/Taylor cover
of (I5.1g-27), curve jets through order six, positive speed and chord-arc
bounds, diagonal divided-difference enclosures, and exact finite density
coefficient balls through derivative order five.  Direct interval formulas
must enclose every value of every box; sampled node maxima, fitted safety
factors, and inter-level drift are rejected.

For the current circle only, the adapter may evaluate
$x(h)=4R^2\sin^2(h/2)$ and its derivatives on each $H_b$, reuse the existing
finite $J/Y/J^{[1]}/\mathfrak C$ series with their first-omitted factorial or
ratio tails on the restricted $x$ interval, and enclose the finite
trigonometric density on $u=t-h$ by coefficient-based interval or Taylor
arithmetic.  This is a finite geometry adapter.  It neither diagonalizes a
circle operator nor changes the shape-general theorem.

The present code exposes only global positive derivative arrays and global
density row sums.  The *complete shape-general box branch* therefore remains
`CONDITIONAL GO` until the boxwise producer closes, most critically, all
fourth derivatives of
$K_2^{\mathrm{nor}}$ across $h=0$, including
$D_{\kappa_e,2}^*-D_{\kappa_i,2}^*$ and
$C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}}$ with the Maue
$\tau'$ term.  This is a finite certificate obligation, not an unknown true
solution norm.

### Current-circle value-only convolution shortcut

Attempt 2 need not wait for the complete normal/source box producer before
testing whether the local *value* high tail can meet its stage allocation.
For the current circle, translation invariance in the chosen constant-speed
parameter gives the exact factorization

$$
K_j^{\mathrm{val}}(t,t-h)
=F_{j,\tau}(h)\,E_\tau(t-h)
+F_{j,\zeta}(h)\,E_\zeta(t-h),
\qquad j\in\{1,2\}.
\tag{I5.1g-36a}
$$

$E_\tau$ and $E_\zeta$ are the complete frozen row maps from a state vector
to $\tau$ and $\zeta=-\sigma$.  Equality (I5.1g-36a), rather than a separately
chosen sign convention, defines the scalar factors: each $F_{j,r}$ contains
the source Jacobian and the signed exterior-minus-interior kernel difference
used by the physical value action.  The two material kernels are combined
before an absolute value is taken.

For each relative panel certify

$$
F_{j,r;b}^{\#}\ge\sup_{h\in H_b}|F_{j,r}(h)|,
\qquad
\Phi_r:=\sum_b
\left(F_{1,r;b}^{\#}\Lambda_b+F_{2,r;b}^{\#}|H_b|\right),
\quad r\in\{\tau,\zeta\}.
\tag{I5.1g-36b}
$$

The factor bound is obtained from the signed finite $J/Y/J^{[1]}/\mathfrak C$
series on the panel's restricted $x(h)$ interval plus its explicit factorial
or first-ratio tail.  It is not the sum of separately absolutized interior
and exterior whole-action bounds.

If the exact half-open frozen density support is $\mathcal I_\eta$ and
$E_r(t)=\sum_{m\in\mathcal I_\eta}\widehat E_{r,m}e^{\mathrm imt}$, define
the finite coefficient certificate

$$
\mathcal L_{r,4}
:=2\pi\left(
\sum_{m\in\mathcal I_\eta}|m|^8
\|\widehat E_{r,m}\|_{\mathrm F}^2
\right)^{1/2}.
\tag{I5.1g-36c}
$$

Parseval, Cauchy--Schwarz on $[0,2\pi]$, and
$\|A\|_{2\leftarrow2}\le\|A\|_{\mathrm F}$ prove

$$
\int_0^{2\pi}\|E_r^{(4)}(t)\|_{2\leftarrow2}\,\mathrm dt
\le\mathcal L_{r,4}.
$$

Differentiating (I5.1g-26) at fixed $h$ puts all four target derivatives on
$E_r(t-h)$.  Young's $L^1$ convolution inequality therefore yields

$$
Q_{\Gamma,4}^{\mathrm{val,conv}}
:=R^{-3}\left[
\mathcal L_{\tau,4}
+\Phi_\tau\mathcal L_{\tau,4}
+\Phi_\zeta\mathcal L_{\zeta,4}
\right]
\ge\int_\Gamma
\|\partial_s^4H^{\mathrm{val}}\|_{2\leftarrow2}\,\mathrm ds.
\tag{I5.1g-36d}
$$

The first term owns the value identity exactly once.  The factor $R^{-3}$
is $R^{-4}$ from four arclength derivatives times $R$ from
$\mathrm ds=R\,\mathrm dt$.  Formula (I5.1g-36d) may replace only the value
$Q_4$ in (ME-18) and in the constant-speed target alternative
(I5.1g-35a).  The normal and source Kress radii retain their previously
proved global certificates until the full box producer passes.  This
shortcut uses finite-density Parseval and a direct kernel-series enclosure;
it is an instance adapter, not circle Fourier/Bessel operator
diagonalization and not an assumption of the shape-general theorem.

For selection and reporting, record one active branch.  Under
`shape-general-full-box`, "every analytic gate" means all gates in
(I5.1g-27)--(I5.1g-35b).  Under `current-circle-value-convolution`, it means:

1. the frozen chart is certified to be the stated exact, constant-speed
   circle with the governing normal orientation;
2. the equality (I5.1g-36a), including source Jacobian, density sign, and the
   signed exterior-minus-interior factors, is verified algebraically;
3. every $F_{j,r;b}^{\#}$ encloses the signed finite factor on the complete
   relative panel plus all series tails, and the panels cover
   $[-\pi,\pi]$ with the diagonal logarithmic moment enclosed;
4. the exact half-open density support, coefficient row maps, and the finite
   Parseval/Frobenius quantities (I5.1g-36c) are complete and finite;
5. the identity is included exactly once in (I5.1g-36d); and
6. the unchanged v6 complete source-Kress, normal, series, index, and
   owner/telescope gates all pass.

The shortcut does not require the inactive target-box and Maue-fourth-
derivative gates merely to replace the value $Q_4$.  Conversely, it does not
authorize replacing the normal or source certificates.  The common
regular/off-surface, propagation, lifting-weight, special-function, and
finite-arithmetic gates remain active under both branches.

### Preregistered candidates and stopping rule

The two-dimensional panel schedule is

$$
(n_t,n_h)\in\{(16,32),(32,64),(64,128),(128,256)\}.
\tag{I5.1g-37}
$$

$I_a$ is the uniform $n_t$ target partition.  The base uniform $n_h$
relative partition is refined by inserting
$0,\pm\pi/3,\pm\pi$; the two cells adjacent to zero are treated as one
symmetric diagonal panel for (I5.1g-29).  Thus $n_h$ names the base relative
resolution, not the final number of boxes after mandatory breakpoints.

For the current frozen $M_\eta=128$, preregister

$$
L\in\{64,128,256,512,1024\},
\qquad N\in\{514,1024,2048,4096\}.
\tag{I5.1g-38}
$$

Search $L$ from small to large and, for each $L$, search the panel pairs in
the displayed order.  For the circle-convolution branch only $n_h$ enters
the active value certificate; $n_t$ remains the preregistered resolution for
the future full-box branch and is not used as evidence.  Freeze the first
pair for which every analytic gate of the declared active branch passes and
the complete material high-mode norm

$$
H_{\mathrm{mat}}(L)
=\sqrt{S_{\mathrm{state}}}
\left(T_{4,\mathrm{val}}^{\mathrm{loc,pw}}(L)
+T_{\mathrm{val}}^{\mathrm{reg}}(L)
+T_{\mathrm{val}}^{\mathrm{off}}(L)\right)
\tag{I5.1g-39}
$$

is strictly below one half of the preregistered target

$$
B_{\mathrm{target}}
=\frac{3.3621248621896728\times10^{-2}}{10}
=3.3621248621896728\times10^{-3}.
\tag{I5.1g-40}
$$

This performance target does not enter the proof of any candidate bound.
If no pair reaches the performance target, retain the last analytically
admissible finite bound for reporting and invoke the v7 upgrade gate below.
If no candidate passes all analytic gates, stop with no majorant; a finite
sampled value is not a fallback.

Only after $L$ and the panel pair are frozen, filter the registered $N$ list
by the strict theorem condition

$$
N>2\max\{L,M_\eta\}.
\tag{I5.1g-41}
$$

Thus the admissible lists are $\{514,1024,2048,4096\}$ for
$L=64,128,256$, $\{2048,4096\}$ for $L=512$, and $\{4096\}$ for
$L=1024$.  For each admissible $N$, evaluate only the complete local
source--target--series row radius
$\epsilon_\ell^{\mathrm{self,val}}(N)$ and its proved propagation envelope,

$$
H_{\mathrm{ret}}(N)
:=\left[
S_{\mathrm{state}}
\sum_{|\ell|<L}\overline w_{\Lambda,\ell}
\bigl(\epsilon_\ell^{\mathrm{self,val}}(N)\bigr)^2
\right]^{1/2}.
$$

$S_{\mathrm{state}}$ is the same exact center-singleton plus two half-guide
block-power state-energy envelope used in (I5.1g-39); it is applied once and
contains no residual-action center.  $H_{\mathrm{ret}}$ contains only the
value/lifting row radius; it contains no material-normal radius.

Select the first strict admissible $N$ for which all retained source, target,
series, index, and finite-enclosure gates pass and
$H_{\mathrm{ret}}(N)<B_{\mathrm{target}}/2$.  This is the only authorization
to increase $N$.  No signed center or complete $B_{\mathrm{lift}}$ is
computed for rejected $N$ values.  If no candidate passes this radius gate
but at least one $N$ passes every analytic gate, freeze the largest such
analytic-admissible $N$, mark the v7 upgrade as mandatory, and continue to
the one center/majorant evaluation below.  If no $N$ passes every analytic
gate, stop with no majorant.

After $N$ is frozen, evaluate the signed center and complete conditional
ideal $B_{\mathrm{lift}}^{\mathrm{attempt\,2}}$ exactly once.  That complete
value is used only in the v7 route gate (I5.1g-42); it is never fed back into
the $N$ selector.  Thus a finite conditional majorant is reported whenever
an analytic-admissible $N$ exists, even if its retained-radius tightness gate
failed; the failure forces, rather than replaces, the v7 comparison.

Irrespective of which finite candidate is reported, attempt 2 must advance to
v7 if either

$$
B_{\mathrm{lift}}^{\mathrm{attempt\,2}}
\ge\frac1{10}B_{\mathrm{lift}}^{\mathrm{v6}}
\quad\text{or}\quad
\frac{H_{\mathrm{mat}}(L)}
{B_{\mathrm{lift}}^{\mathrm{attempt\,2}}}\ge\frac12.
\tag{I5.1g-42}
$$

This is a route-selection gate demanded by the stage objective, not a
reliability argument.  Every finite majorant remains valid or invalid solely
according to its analytic gates.

### Attempt-2 fail-closed checklist

Before a run, the Skeptic should require all of the following:

1. the active branch is persisted.  For the full-box branch, the target and
   relative partitions have the distinct meanings in (I5.1g-27), cover the
   full torus, and implement the mandatory diagonal and logarithmic
   breakpoints.  For the circle-convolution branch, the relative panels cover
   the full period and the six shortcut gates above all pass;
2. under the full-box branch, every bound in (I5.1g-28) is a complete
   interval/Taylor enclosure with no sampled maximum, and the
   density/Jacobian/normal/Maue factors occur exactly once.  Under the
   shortcut branch, (I5.1g-36a)--(I5.1g-36d) replace only this value-$Q_4$
   obligation and the unchanged v6 normal/source gates are still required;
3. under the full-box branch, all diagonal $K_2^{\mathrm{nor}}$ formulas are
   cancellation safe, the normal Maue branch includes density derivatives
   through order five, and
   $\mathrm D_\parallel=\partial_t+\partial_u$ is applied only after the
   relative-coordinate substitution.  Under the shortcut branch, target
   differentiation at fixed $h$ is applied only to the finite density row
   maps as proved in (I5.1g-36d);
4. the active target formula is complete: the full-box branch uses
   (I5.1g-34)--(I5.1g-35b), while the constant-speed shortcut uses
   (I5.1g-35)--(I5.1g-35a) with (I5.1g-36d).  Alternatives bound the same
   error and are minimized, never added;
5. every active formula uses finite, nonnegative, complete enclosures and
   every inactive-branch field is excluded from the pass conjunction;
6. the three differences in (I5.1g-36) are exhaustive and disjoint, the
   identity occurs once, and certificate series tails are not re-added as an
   error owner;
7. local, regular-image, off-surface, wall, and cell-propagation tails retain
   disjoint index/operation owners and the physical signs are applied before
   the triangle bound;
8. the pair/L selector follows (I5.1g-37)--(I5.1g-40), and the per-$L$ list
   of $N$ values is filtered strictly by (I5.1g-41).  Candidate $N$ values
   are compared only through the value/lifting quantity
   $H_{\mathrm{ret}}(N)<B_{\mathrm{target}}/2$; no normal radius enters it,
   and signed centers are not evaluated until one $N$ is frozen.  If none
   passes the radius threshold, the largest analytic-admissible $N$ is frozen
   and v7 is mandatory; only absence of every analytic-admissible $N$ causes
   `STOP` with no majorant;
9. the selected signed center and complete $B_{\mathrm{lift}}$ are evaluated
   once, and the mandatory v7 gate (I5.1g-42) is evaluated without feeding
   either quantity back into the $N$ selector;
10. finite special-function and floating-point errors remain
    $\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$, both unresolved unless
    separately enclosed.
