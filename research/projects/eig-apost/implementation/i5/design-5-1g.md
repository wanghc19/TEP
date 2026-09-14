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
