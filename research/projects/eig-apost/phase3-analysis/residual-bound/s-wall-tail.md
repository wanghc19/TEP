# Artificial-interface Neumann residual: finite part plus strict tail

## Status and scope

This note records a proof-from-scratch result for one component of the
continuous residual numerator only.  Its conclusion is
`CONDITIONAL GO FOR GENERAL-SHAPE B_{Gamma_pm}`: the mathematical bound is
explicit for separated regular parameter curves.  The current circular
frozen instance has also passed the shape-general evaluator gates in ordinary
floating-point arithmetic, but it is not an outward-rounded certificate.
It is not a bound for the full residual, for the quotient $q$, for an
eigenvalue error, or for a spectral enclosure.

The original circular study started at 2026-09-06 11:10:37 CST.  The present
general-shape extension has a separate start at 2026-09-06 16:42:03 CST and a
hard deadline at 2026-09-06 20:42:03 CST.  Its evaluation-only I5 regression
completed inside its single attempt.

The result connects to the current continuous-residual framework in
[[research/projects/eig-apost/phase3-analysis/s-estimator]], the exact versus
finite half-guide boundary in
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain]], and the frozen
full-boundary trial in
[[research/projects/eig-apost/implementation/i3/design-3-1f]].

## Theory-source audit

The user referred to the numerator in `(q)` in `main:draft/`.  That path no
longer exists on current `main`; it must not be silently replaced.

| role | Git object | path and finding |
|---|---|---|
| current `main` | `14a822b0f7436c3acc11d58a6c7672b0c3f6b64d` | `draft/` is absent; this commit moved it by an `R100` rename to `legacy/draft-2026-07-24/` |
| pre-archive authority | `1d060f9c82b355e7e0e33cee6bcc466d3fc692a4` | `draft/` is present |
| last content change | `7e51c7ec302aee4c3d4a43db1ac9fdc55600dd5d` | last actual change to `draft/draft.tex` |
| current branch | `208f7d711d9c13a6def68da273944d35d333928d` | `codex/epost:draft/` is present and unmodified |

The tree hash is
`9773e9f5ed21dea3cea9b945aae4e70a600af5cf` for
`7e51c7e:draft`, `1d060f9:draft`, current `codex/epost:draft`, and
`main:legacy/draft-2026-07-24`.  Thus the branch copy is byte-identical to the
last authoritative pre-archive tree.  That draft supplies only the strong
transmission model, the Rayleigh branch convention, and the quasi-periodic
Green representation.  It does not define the current three-component
residual or the current $q$.  For those objects this note uses the current
I3/I4 files, especially
[[research/projects/eig-apost/implementation/i3/report]],
[[research/projects/eig-apost/implementation/i3/design-3-2b]],
[[research/projects/eig-apost/implementation/i3/design-3-2d]], and the
continuous-residual and lifting parts of the phase-4 method.

The separate `/Users/whc/Documents/Work/TEP` checkout currently contains an
untracked filesystem directory named `draft/`, but `git ls-tree main draft`
is empty.  That untracked directory is user work and was not modified.  Its
Chinese `draft.pdf` was read once, on the user's later instruction, solely to
copy the notation now frozen in this topic; it is not a theoretical authority
or a live dependency.

No statement below is promoted to `draft/`.

## Closure matrix

In the frozen notation of this topic, $B_{\Gamma_\pm}$ is the
artificial-interface Neumann-jump contribution, $B_\Upsilon$ is the material
normal-transmission contribution, and $B_{\mathrm{lift}}$ is the complete
value-defect correction contribution.  Local symbols introduced in this file
are the half-strip width $h_{\mathrm{tr}}$, exterior material wavenumber
$\kappa_e=\widehat k\sqrt{\rho_e}$, exact trace weight $\omega_m$, Fourier
cutoff $M$, cell cutoff $J$,
coefficient enclosure $(\widetilde\ell,\epsilon)$, and high-mode constant
$\mathcal C_\varsigma(M)$.  The finite-row section additionally uses the
wall sign $s_\varsigma=\nu_\varsigma\cdot e_x$, center-to-wall distance $D$,
complex angle $z$, strip width $a$, trapezoid size $N_q$, Lyapunov matrix
$Y_\varsigma$, and block length $J_\varsigma^{\rm blk}$, each with the
definition displayed there.

| module | frozen input sufficient | finite part directly finite | explicit omission inequality | constants computable | unknown exact solution | half-guide coupling | verdict |
|---|---|---|---|---|---|---|---|
| $B_{\Gamma_\pm}$ | yes: finite densities, $P_\varsigma,c_\varsigma,G_\varsigma$, a parameter-curve contract, $\widehat k,\beta,d$ | yes: finite modal algebra plus finitely many general-curve integrals | yes: positive-distance Rayleigh tail plus a whole-matrix propagation bound | yes, after G1--G10 | no | closed conditionally by a Lyapunov or block-power certificate | `CONDITIONAL GO`; current circle ordinary instance passes |
| $B_\Upsilon$ | yes, after finite geometry certificates are generated | yes: periodic-log subtraction plus retained panel enclosures | yes: algebraic local tail, Ewald regular-image tail, and separated-action tail | explicitly finite but not instantiated | no | reusable Lyapunov/block-power sum | `CONDITIONAL GO` |
| $B_{\mathrm{lift}}$ | yes, after the same finite certificates are generated | yes: identity-inclusive local rows plus regular/off-surface rows | yes: tubular weights with algebraic local and analytic separated tails | explicitly finite but not instantiated | no | reusable Lyapunov/block-power sum | `CONDITIONAL GO` |

The strict distance
$\delta=\operatorname{dist}(\Upsilon,\Gamma_-\cup\Gamma_+)>0$ acts only on a
curve field evaluated off surface at a wall.  It does not control a material
self-trace.  This is why the proof below is deliberately restricted to
$B_{\Gamma_\pm}$.

## Strong residual and the three contributions

Let

$$
B=\mathbb R\times\mathbb T_d,
\qquad
V_\beta=H^1_\beta(B),
$$

and fix the shifted norm

$$
\|v\|_\mu^2
=\int_B\left(|\nabla v|^2+\mu\rho|v|^2\right),
\qquad \mu=\widehat k^2>0.
$$

The material satisfies $\rho\ge 1$ in the present project.  Let
$u_{h,M}$ be the broken field defined by the frozen finite densities
and the mathematically exact layer kernels.  On every material subregion $K$
its volume residual is

$$
r_K=(-\Delta-\mu\rho_K)u_{h,M}=0.
$$

This is an identity of the selected exact-kernel reconstruction, not a claim
that the frozen data approximate an unknown true eigenfunction.

For each artificial interface $\Sigma$, choose the two outward normals of the adjacent
cells and define

$$
j_\Sigma
=\partial_{\nu_1}u_{h,M}^{(1)}|_\Sigma
+\partial_{\nu_2}u_{h,M}^{(2)}|_\Sigma.
$$

For a material circle in $\Upsilon$, let $\nu$ point from the disk interior
to the exterior and define the integration-by-parts defect

$$
j_\Upsilon
=\partial_\nu u_{h,M}^{\mathrm{in}}|_\Upsilon
-\partial_\nu u_{h,M}^{\mathrm{out}}|_\Upsilon.
$$

Let $e$ be the fixed correction whose jumps cancel all value defects of
$u_{h,M}$, so that $\widehat u=u_{h,M}+e\in V_\beta$.  Define

$$
R(v)
=\sum_K\int_K
\left(\nabla\widehat u\cdot\nabla\overline v
-\mu\rho_K\widehat u\overline v\right),
$$

and

$$
\|R\|_{\mu,*}
=\sup_{0\ne v\in V_\beta}\frac{|R(v)|}{\|v\|_\mu}.
$$

Integrating only the raw field $u_{h,M}$ by parts on every material
subregion, using $r_K=0$, and leaving the complete lifting form unintegrated
gives the exact identity

$$
R(v)
=\sum_\Sigma\langle j_\Sigma,v|_\Sigma\rangle
+\sum_\Upsilon\langle j_\Upsilon,v|_\Upsilon\rangle
+R_{\mathrm{lift}}(v),
\qquad
R_{\mathrm{lift}}(v)=a(e,v)-\mu b(e,v).
$$

The signs above are fixed by the stated outward-normal convention.  The last
term, including every derivative of $e$, belongs entirely to
$B_{\mathrm{lift}}$; no normal trace of $e$ is counted again in
$B_{\Gamma_\pm}$ or $B_\Upsilon$.  Moreover,

$$
|R_{\mathrm{lift}}(v)|
\le2\|e\|_\mu\|v\|_\mu.
$$

Consequently, with the three terms assigned exactly as above,

$$
\|R\|_{\mu,*}
\le\mathcal M
:=B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}.
$$

This formula explains the complete strong-residual route, but the theorem
below closes only $B_{\Gamma_\pm}$.

## Exact wall trace weight

Write

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\lambda_m=\sqrt{|\beta_m|^2+\mu}.
$$

Associate to every wall two nonoverlapping half-strips of width
$h_{\mathrm{tr}}$.  In the present unit-cell geometry
$h_{\mathrm{tr}}=1/2$; in general require $2h_{\mathrm{tr}}$ not to exceed
the cell width.  The half-strips assigned to all physical walls are disjoint
up to measure-zero boundaries and count every wall once.

For a fixed Fourier trace $g_m$, the minimum of

$$
\int_0^{h_{\mathrm{tr}}}
\left(|z'(x)|^2+\lambda_m^2|z(x)|^2\right)\,dx
$$

under $z(0)=g_m$ and a free far endpoint is
$\lambda_m\tanh(h_{\mathrm{tr}}\lambda_m)|g_m|^2$.  The minimizer is the elementary
hyperbolic-cosine solution of $-z''+\lambda_m^2z=0$.  Summing the two sides of
each wall, using Parseval and $\rho\ge1$, yields

$$
\sum_\Sigma\sum_{m\in\mathbb Z}
\omega_m|(v|_\Sigma)_m|^2\le\|v\|_\mu^2,
\qquad
\omega_m=2\lambda_m\tanh(h_{\mathrm{tr}}\lambda_m).
$$

Therefore Cauchy--Schwarz gives

$$
\left|\sum_\Sigma\langle j_\Sigma,v|_\Sigma\rangle\right|
\le B_{\Gamma_\pm}\|v\|_\mu,
\qquad
B_{\Gamma_\pm}^2
=\sum_\Sigma\sum_{m\in\mathbb Z}\frac{|j_{\Sigma,m}|^2}{\omega_m}.
$$

The remaining problem is to bound this genuinely infinite sum from frozen
finite data.

## General separated-interface theorem

This section isolates the part of the artificial-wall argument that does not
depend on a circular material interface.  Let

$$
{\cal C}_j={\boldsymbol r}_j([0,2\pi]),
\qquad
{\boldsymbol r}_j(t)=(x_j(t),y_j(t)),
$$

be one of finitely many simple closed, $2\pi$-periodic, regular curves in a
cell.  Assume ${\boldsymbol r}_j\in C^2_{\rm per}$ and put

$$
v_j(t)=|{\boldsymbol r}_j'(t)|>0,
\qquad
L_j=\int_0^{2\pi}v_j(t)\,dt,
\qquad
\nu_j(t)=\varepsilon_j
\frac{(y_j'(t),-x_j'(t))}{v_j(t)},
$$

where $\varepsilon_j\in\{-1,+1\}$ fixes the required physical orientation.
No convexity or star-shaped hypothesis is imposed.  For a vertical wall
$W=\{x=X_w\}$, require that

$$
s_{jw}=\operatorname{sign}(X_w-x_j(t))
$$

is independent of $t$, and define

$$
d_{jw}(t)=s_{jw}(X_w-x_j(t)),
\qquad
\delta_{jw}=\min_t d_{jw}(t)>0,
\qquad
\delta=\min_{j,w}\delta_{jw}>0.
$$

The sign condition follows from separation when a connected curve lies on
one side of the wall, but it is recorded explicitly because it fixes the
normal-derivative signs.  Each listed curve-to-wall action is oriented so
that the target cell-outward normal is $n_w=s_{jw}e_x$.

For a finite state $x\in\mathbb C^q$, represent the two actual layer
densities by

$$
t_{\tau,j}(t;x)={\boldsymbol\phi}_j(t)C_{\tau,j}x,
\qquad
t_{\sigma,j}(t;x)={\boldsymbol\phi}_j(t)C_{\sigma,j}x,
$$

where ${\boldsymbol\phi}_j$ is a finite row of $C^1_{\rm per}$ basis
functions.  For every state require
$t_{\tau,j}(\cdot;x)\in H^{1/2}({\cal C}_j)\cap C^1({\cal C}_j)$ and
$t_{\sigma,j}(\cdot;x)\in H^{-1/2}({\cal C}_j)\cap C^1({\cal C}_j)$.
In particular, both are in $L^1({\cal C}_j,ds)$, as required by the
off-surface estimates below.  Define the exact mass matrix

$$
M_j=\int_0^{2\pi}{\boldsymbol\phi}_j(t)^*
{\boldsymbol\phi}_j(t)v_j(t)\,dt.
$$

Then

$$
\|t_{\tau,j}(\cdot;x)\|_{L^1(ds)}
\le \sqrt{L_j}\|M_j^{1/2}C_{\tau,j}\|_2\|x\|_2,
$$

and the same inequality holds for $\sigma$.  This is Cauchy--Schwarz in
arclength followed by the exact mass-matrix identity.  It remains valid with
a rigorous positive-semidefinite enclosure of $M_j$ that dominates the exact
Gram matrix.  A nodal Euclidean norm without this mass conversion is not an
admissible substitute.

For

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\gamma_m^2=\kappa_e^2-\beta_m^2,
$$

use the outgoing/decaying branch.  The exact target-outward normal Fourier
row at $W$ generated by $u=D\tau+S\sigma$ is

$$
q_{jw,m}(A)=\int_0^{2\pi} f_{jw,m}(t;A)\,dt,
$$

where $A$ is any frozen postmap and

$$
\begin{split}
f_{jw,m}(t;A)
={}&\frac{v_j(t)}{2\sqrt d}
\exp\!\left(\mathrm i\gamma_m d_{jw}(t)
-\mathrm i\beta_my_j(t)\right)\\
&\quad\times
\left\{
\mathrm i\left[s_{jw}\gamma_m\nu_{j,x}(t)
+\beta_m\nu_{j,y}(t)\right]t_{\tau,j}(t;A)
-t_{\sigma,j}(t;A)
\right\}.
\end{split}
\tag{G-row}
$$

The target derivative cancels the Green coefficient's $1/\gamma_m$.
The remaining first-order factor is the source-normal derivative.  The last
minus sign is for the actual single-layer density in $D\tau+S\sigma$; a
stored coordinate equal to $-\sigma$ must be converted exactly once at the
artifact boundary.

For one side $\varsigma\in\{-,+\}$, let ${\cal R}_\varsigma$ list every
curve copy contributing to one internal-wall row, including its frozen
postmap $A_r$.  Set

$$
A_{\tau,\varsigma}
=\sum_{r\in{\cal R}_\varsigma}
\sqrt{L_{j(r)}}
\|M_{j(r)}^{1/2}C_{\tau,j(r)}A_r\|_2,
$$

and define $A_{\sigma,\varsigma}$ analogously.  For a fixed center/first
contribution, define $A_{\tau,\varsigma,0}$ and
$A_{\sigma,\varsigma,0}$ by replacing each operator norm with the
corresponding fixed-vector mass norm and summing the finitely many curve
copies.  The exact retained internal row has the form

$$
\ell_{\varsigma,m}
=\ell_{\varsigma,m}^{\rm flat}
+\sum_{r\in{\cal R}_\varsigma}q_{j(r)w(r),m}(A_r).
\tag{G-retained}
$$

The project-specific formulas
$\ell_{+,m}=Q_{R,m}G_++Q_{L,m}G_+P_+$ and
$\ell_{-,m}=Q_{L,m}G_-+Q_{R,m}G_-P_-$ are instances of
(G-retained); the new definition changes the curve action, not the frozen
side or propagation convention.

### Retained-row quadrature on a general curve

There are two independent rigorous routes.  For a merely $C^2$ curve, the
integrand in (G-row) is $C^1$.  If a computable number satisfies

$$
K_{jw,m,1}(A)
\ge\sup_{0\le t\le2\pi}\|\partial_tf_{jw,m}(t;A)\|_2,
$$

then the periodic $N_q$-point trapezoidal sum obeys

$$
\left\|
\int_0^{2\pi}f_{jw,m}(t;A)\,dt
-\frac{2\pi}{N_q}\sum_{r=0}^{N_q-1}
f_{jw,m}\left(\frac{2\pi r}{N_q};A\right)
\right\|_2
\le\frac{2\pi^2K_{jw,m,1}(A)}{N_q}.
\tag{G-C1}
$$

Indeed, on each grid interval the fundamental theorem of calculus bounds the
integral of the difference from its left endpoint by
$K_{jw,m,1}(A)h^2/2$, where $h=2\pi/N_q$.  Summing the $N_q$ intervals proves
(G-C1).  Periodicity makes this left-endpoint sum the periodic trapezoidal
sum.  Thus $C^2$ regularity gives a route, but a finite enclosure of
$K_{jw,m,1}(A)$ is still a required input.

For the exponential route, assume instead that ${\boldsymbol r}_j$ and
${\boldsymbol\phi}_j$ extend as periodic holomorphic functions to
$|\operatorname{Im}z|\le a$.  Require

$$
g_j(z)=x_j'(z)^2+y_j'(z)^2
$$

to have no zero there and to possess a periodic holomorphic square root
$v_j(z)$ that agrees with the positive real speed.  Define the holomorphic
normal by

$$
\nu_j(z)=\varepsilon_j
\frac{(y_j'(z),-x_j'(z))}{v_j(z)}
$$

and continue the signed distance as
$d_{jw}(z)=s_{jw}(X_w-x_j(z))$; no complex absolute value is used.  Put

$$
J_{j,a}=\sup_{|\operatorname{Im}z|\le a}|v_j(z)|,
\qquad
Y_{j,a}=\sup_{|\operatorname{Im}z|\le a}
|\operatorname{Im}y_j(z)|,
$$

$$
D_{\tau,j}(A,a)=\sup_{|\operatorname{Im}z|\le a}
\|t_{\tau,j}(z;A)\|_2,
$$

with the analogous $D_{\sigma,j}(A,a)$, and

$$
L_{jw,m}(a)=\sup_{|\operatorname{Im}z|\le a}
|s_{jw}\gamma_m\nu_{j,x}(z)+\beta_m\nu_{j,y}(z)|.
$$

For a propagating order, let

$$
X_{j,a}=\sup_{|\operatorname{Im}z|\le a}
|\operatorname{Im}x_j(z)|,
\qquad
\Phi_{jw,m}(a)=
\exp(\gamma_mX_{j,a}+|\beta_m|Y_{j,a}).
$$

For an evanescent order $\gamma_m=\mathrm i\kappa_m$, require

$$
\delta_{jw,a}
=\inf_{|\operatorname{Im}z|\le a}\operatorname{Re}d_{jw}(z)>0
$$

and set

$$
\Phi_{jw,m}(a)
=\exp(-\kappa_m\delta_{jw,a}+|\beta_m|Y_{j,a}).
$$

Then

$$
M_{jw,m}(A,a)
=\frac{J_{j,a}\Phi_{jw,m}(a)}{2\sqrt d}
\left[
L_{jw,m}(a)D_{\tau,j}(A,a)+D_{\sigma,j}(A,a)
\right]
$$

bounds the strip supremum of (G-row).  Contour shifting its Fourier
coefficients and summing the aliases gives

$$
\left\|
\int_0^{2\pi}f_{jw,m}(t;A)\,dt
-\frac{2\pi}{N_q}\sum_{r=0}^{N_q-1}
f_{jw,m}\left(\frac{2\pi r}{N_q};A\right)
\right\|_2
\le\frac{4\pi M_{jw,m}(A,a)}{e^{aN_q}-1}.
\tag{G-analytic}
$$

Errors from the finitely many curve copies add by the triangle inequality.
Either (G-C1) or (G-analytic), together with the finite flat-wall algebra,
must produce exact row enclosures

$$
\|\ell_{\varsigma,m}-\widetilde\ell_{\varsigma,m}\|_2
\le\epsilon_{\varsigma,m},
\qquad |m|\le M,
$$

and analogous singleton enclosures.

### Positive-distance high modes

Choose $M$ to contain the support of every flat-wall and stored center
contribution and require

$$
q_0(M+1)-|\beta|>\kappa_e,
\qquad q_0=\frac{2\pi}{d}.
$$

Every omitted order is then evanescent.  On the real curve,
$|\nu_j|=1$ and direct use of (G-row) gives

$$
|q_{jw,m}(A)x|
\le\frac{e^{-\kappa_m\delta_{jw}}}{2\sqrt d}
\left[
(\kappa_m+|\beta_m|)
\|t_{\tau,j}(\cdot;Ax)\|_{L^1(ds)}
+\|t_{\sigma,j}(\cdot;Ax)\|_{L^1(ds)}
\right].
\tag{G-high}
$$

This retains the source-normal first-order mode weight.  Summing curve copies
and using the mass constants reduces (G-high) to exactly the scalar estimate
used by the geometric tail.  Namely, put

$$
N=M+1,
\quad a_0=q_0N-|\beta|,
\quad r=e^{-2\delta q_0},
\quad t_0=\tanh(h_{\rm tr}a_0),
$$

$$
S_0=\frac{r^N}{1-r},
\qquad
S_1=r^N\left(\frac{N}{1-r}+\frac{r}{(1-r)^2}\right),
$$

and, for nonnegative $A,B$, define

$$
{\cal C}_{\rm gen}(M;A,B)^2
=\frac{e^{2\delta(\kappa_e+|\beta|)}}{4dt_0}
\left[
4A^2(q_0S_1+|\beta|S_0)
+\left(4AB+\frac{B^2}{a_0}\right)S_0
\right].
\tag{G-tail}
$$

Thus

$$
\sum_{|m|>M}\frac{|j_{\varsigma,m}(x)|^2}{\omega_m}
\le {\cal C}_{\rm gen}
(M;A_{\tau,\varsigma},A_{\sigma,\varsigma})^2\|x\|_2^2,
\tag{G-state-tail}
$$

with the fixed-vector analogue obtained from
$A_{\tau,\varsigma,0},A_{\sigma,\varsigma,0}$.  To verify (G-tail), use
$\kappa_m\le|\beta_m|$, replace the bracket in (G-high) by
$2|\beta_m|A+B$, and use
$\omega_m\ge2|\beta_m|t_0$.  For $m=\pm n$,

$$
|\beta_{\pm n}|\le q_0n+|\beta|,
\qquad
e^{-2\delta\kappa_{\pm n}}
\le e^{2\delta(\kappa_e+|\beta|)}r^n.
$$

Expanding the square and inserting
$\sum_{n=N}^\infty r^n=S_0$ and
$\sum_{n=N}^\infty nr^n=S_1$ gives (G-tail), including its two-sided
factor.

### Proof obligations

The general result has the following finite audit gates.

1. **G1:** every ${\boldsymbol r}_j$ is embedded, periodic, $C^2$, regular,
   and has the stated fixed orientation; no star-shaped test is used.
2. **G2:** each curve lies strictly on one side of every wall to which it
   contributes, and every recorded $\delta_{jw}$ is positive.
3. **G3:** the actual $D\tau+S\sigma$ density sign and the target/source
   normal conventions agree with (G-row).
4. **G4:** every density map has the stated function-space regularity, and
   each exact mass matrix or dominating enclosure is available.
5. **G5:** $M$ covers every non-curve finite modal support, no retained order
   is Wood, and the displayed cutoff makes all omitted orders evanescent.
6. **G6:** each retained curve integral has either a verified
   $K_{jw,m,1}$ bound or all analytic-strip bounds, including the nonvanishing
   complex speed and signed complex distance.
7. **G7:** every flat-wall modal division and every small nonzero branch or
   cell-pole denominator is retained in the finite row enclosure; an exact
   zero makes the row unavailable.
8. **G8:** fixed center/first walls and internal propagated walls are indexed
   disjointly, and every physical wall is counted once.
9. **G9:** each $P_\varsigma$ has a verified Lyapunov or block-power
   certificate controlling its complete, possibly nonnormal, power sequence.
10. **G10:** all analytic and quadrature omissions are assigned once;
    ordinary floating-point values are not called certified without a
    separately authorized rounding enclosure.

**Theorem (general separated-interface artificial-wall bound).**
Assume G1--G10.  Define

$$
\overline\omega_{\varsigma,M}
=\sum_{|m|\le M}
\frac{(\|\widetilde\ell_{\varsigma,m}\|_2
+\epsilon_{\varsigma,m})^2}{\omega_m}
$$

and

$$
\begin{split}
\overline F_{M,J}^2
=\sum_{\varsigma\in\{+,-\}}\sum_{|m|\le M}
\frac{1}{\omega_m}
\bigg[&
(|\widetilde j_{\varsigma,0,m}^{\rm cf}|
+\epsilon_{\varsigma,0,m})^2\\
&+\sum_{n=0}^{J-1}
\left(
|\widetilde\ell_{\varsigma,m}P_\varsigma^nc_\varsigma|
+\epsilon_{\varsigma,m}\|P_\varsigma^nc_\varsigma\|_2
\right)^2
\bigg].
\end{split}
$$

Suppose first that exact Hermitian matrices satisfy

$$
Y_\varsigma\succeq0,
\qquad
Y_\varsigma-P_\varsigma^*Y_\varsigma P_\varsigma\succeq I.
$$

Put

$$
\begin{split}
T_{M,J}^2
=\sum_{\varsigma\in\{+,-\}}
\bigg[&
{\cal C}_{\rm gen}
(M;A_{\tau,\varsigma,0},A_{\sigma,\varsigma,0})^2\\
&+\overline\omega_{\varsigma,M}
(P_\varsigma^Jc_\varsigma)^*Y_\varsigma
(P_\varsigma^Jc_\varsigma)\\
&+{\cal C}_{\rm gen}
(M;A_{\tau,\varsigma},A_{\sigma,\varsigma})^2
c_\varsigma^*Y_\varsigma c_\varsigma
\bigg].
\end{split}
$$

Then

$$
B_{\Gamma_\pm}
\le\sqrt{\overline F_{M,J}^2+T_{M,J}^2}
\le\overline F_{M,J}+T_{M,J}.
\tag{G-majorant}
$$

If instead verified numbers satisfy

$$
\|P_\varsigma^{J_\varsigma^{\rm blk}}\|_2
\le\overline a_\varsigma<1,
\qquad
\|P_\varsigma^r\|_2\le\overline p_{\varsigma,r},
\quad 0\le r<J_\varsigma^{\rm blk},
$$

define

$$
K_\varsigma
=\frac{\sum_{r=0}^{J_\varsigma^{\rm blk}-1}
\overline p_{\varsigma,r}^2}{1-\overline a_\varsigma^2}
$$

and replace the two propagated terms by

$$
\overline\omega_{\varsigma,M}K_\varsigma
\|P_\varsigma^Jc_\varsigma\|_2^2,
\qquad
{\cal C}_{\rm gen}
(M;A_{\tau,\varsigma},A_{\sigma,\varsigma})^2
K_\varsigma\|c_\varsigma\|_2^2.
$$

The same conclusion holds.

**Proof.**  The exact wall trace argument preceding this theorem reduces the
artificial-wall functional to the nonnegative series defining
$B_{\Gamma_\pm}^2$.  The mass-matrix calculation bounds every source
$L^1(ds)$ norm.  Direct differentiation of the Rayleigh coefficient proves
(G-row); for omitted evanescent modes its modulus is
$e^{-\kappa_md_{jw}(t)}$, so (G-high), (G-tail), and (G-state-tail) follow by
the displayed elementary geometric sums.

For retained rows, (G-C1) follows interval by interval from the fundamental
theorem of calculus.  Under the alternative analytic hypotheses, contour
shifting gives Fourier coefficient bounds
$\|\widehat f_k\|_2\le M_{jw,m}(A,a)e^{-a|k|}$; the periodic trapezoidal error
is $2\pi\sum_{p\ne0}\widehat f_{pN_q}$, which sums to (G-analytic).  Thus the
barred retained rows bound the exact rows without an unassigned evaluation
error.

Partition the exact series into fixed retained modes, propagated retained
modes with $0\le n<J$, propagated retained modes with $n\ge J$, and all
omitted wall modes.  The first two pieces are bounded by
$\overline F_{M,J}^2$.  For the third, the row enclosures give the matrix
bound

$$
\sum_{|m|\le M}\frac{\ell_{\varsigma,m}^*
\ell_{\varsigma,m}}{\omega_m}
\preceq\overline\omega_{\varsigma,M}I.
$$

The Lyapunov inequality telescopes to

$$
\sum_{n=0}^\infty\|P_\varsigma^nx\|_2^2
\le x^*Y_\varsigma x,
$$

so it bounds the retained tail beginning at $P_\varsigma^Jc_\varsigma$.
Applying (G-state-tail) before the same telescoping sum bounds every omitted
mode over all cells.  The singleton high modes are already separated and give
the first term of $T_{M,J}^2$.  These four index sets are disjoint, so their
squared bounds add without cancellation.  Taking square roots proves
(G-majorant).  The block-power alternative follows by writing
$n=qJ_\varsigma^{\rm blk}+r$ and summing the resulting geometric series.
$\square$

The proof retains the wall trace weight, outgoing branch and cutoff, scalar
geometric sums, barred finite rows, singleton separation, full-$P$
certificate, and four-part partition.  It replaces the circular
parameterization, $2\pi R$ normalization, FFT density norm, circular strip
width, and circle-specific strip envelope by
${\boldsymbol r}_j,v_j,\nu_j,L_j,M_j$ and the general $C^1$ or holomorphic
bounds above.  It uses no circular Fourier, Bessel, or self-action identity.
No external theorem is invoked: the mass estimate, periodic quadrature
remainders, geometric tail, and matrix-power summation are all proved by the
displayed finite-dimensional or one-dimensional arguments.

## Frozen circular specialization and corollary

The following section specializes the general theorem to the frozen circular
geometry.  It preserves the existing sharper closed-form constants and the
artifact-specific Fourier normalization; none of those circular formulas is
needed for the general theorem.

Use the normalized wall Fourier basis $\psi_m(y)$.  For a source point
$(x',y')$ on a circle and a target wall $x=x_w$, the Rayleigh coefficient of
the quasi-periodic Green function is

$$
\widehat G_{w,m}(x',y')
=\frac{\mathrm i}{2\gamma_m\sqrt d}
\exp\left(\mathrm i\gamma_m|x_w-x'|\right)
\exp(-\mathrm i\beta_my'),
\qquad
\gamma_m^2=\kappa_e^2-\beta_m^2.
$$

The branch is the frozen outgoing/decaying branch of the audited draft.  A
Wood order, $\gamma_m=0$, is excluded and must be checked from the frozen
$\kappa_e,\beta,d$ for every finite order used.  The high-mode cutoff
below is chosen so that every omitted order is strictly evanescent.  For such
an order write

$$
\gamma_m=\mathrm i\kappa_m,
\qquad
\kappa_m=\sqrt{\beta_m^2-\kappa_e^2}>0.
$$

For $u=D\tau+S\sigma$, differentiation at the target wall cancels the
$1/\gamma_m$ factor.  Source-normal differentiation of the double layer adds
one factor bounded by $\kappa_m+|\beta_m|$.  If the entire source circle is at
distance at least $\delta$ from the wall, direct differentiation gives

$$
| (\partial_{n_w}u)_m|
\le
\frac{e^{-\kappa_m\delta}}{2\sqrt d}
\left[
(\kappa_m+|\beta_m|)\|\tau\|_{L^1(ds)}
+\|\sigma\|_{L^1(ds)}
\right].
$$

Thus the normal derivative's first-order mode weight is retained explicitly;
the tail is not estimated by exponential decay alone.

### Frozen-density normalization

Let $\widehat T_{\tau}$ and $\widehat T_{\sigma}$ denote the ordinary
trigonometric coefficient maps obtained from the frozen native nodal samples by
the exact phase convention used in `LOCAL_circle_density`, namely the
`fftshift(fft(samples))/256` map together with its reconstruction phase.  Set

$$
T_\tau=\sqrt{2\pi R}\,\widehat T_\tau,
\qquad
T_\sigma=\sqrt{2\pi R}\,\widehat T_\sigma.
$$

These are $L^2(ds)$-orthonormal Fourier coordinates.  Hence

$$
\|\tau\|_{L^1(ds)}
\le\sqrt{2\pi R}\,\|T_\tau x\|_2.
$$

For the two circle actions adjacent to a side-$\varsigma$ internal wall,
where $\varsigma\in\{-,+\}$, define

$$
A_{\tau,\varsigma}
=\sqrt{2\pi R}
\left(
\|T_{\tau,\varsigma}^{(0)}\|_F
+\|T_{\tau,\varsigma}^{(1)}P_\varsigma\|_F
\right),
$$

and define $A_{\sigma,\varsigma}$ analogously.  Equivalently, in ordinary Fourier
coordinates the prefactor is $2\pi R$.  Frobenius norms are explicit upper
bounds for the needed operator norms.

For each of the two fixed center/first wall contributions, let
$A_{\tau,\varsigma,0}$ and $A_{\sigma,\varsigma,0}$ be the sums of the exact
$L^1(ds)$ norms of
the finitely represented circle densities that contribute to that singleton.
The center stored Rayleigh derivative and the flat-wall densities have finite
modal support and do not enter these high-mode constants.

### Explicit sum

Choose $M$ to cover all finite flat-wall density orders and all stored center
Rayleigh orders.  For the frozen artifact this requires at least $M=256$:
the flat-wall support is $-256{:}255$ and the center Rayleigh support is
$-48{:}48$.  Put

$$
N=M+1,
\qquad
q_0=\frac{2\pi}{d},
\qquad
a_0=q_0N-|\beta|>\kappa_e,
$$

$$
r=e^{-2\delta q_0},
\qquad
S_0=\frac{r^N}{1-r},
$$

$$
S_1=r^N
\left(
\frac{N}{1-r}+\frac{r}{(1-r)^2}
\right),
\qquad
t_0=\tanh(h_{\mathrm{tr}}a_0).
$$

For nonnegative $A,B$, define

$$
\mathcal C(M;A,B)^2
=\frac{e^{2\delta(\kappa_e+|\beta|)}}{4dt_0}
\left[
4A^2(q_0S_1+|\beta|S_0)
+\left(4AB+\frac{B^2}{a_0}\right)S_0
\right].
$$

Then set

$$
\mathcal C_\varsigma(M)
=\mathcal C(M;A_{\tau,\varsigma},A_{\sigma,\varsigma}),
\qquad
\mathcal C_{\varsigma,0}(M)
=\mathcal C(M;A_{\tau,\varsigma,0},A_{\sigma,\varsigma,0}).
$$

To prove the formula, for $|m|\ge N$ use

$$
\kappa_m\ge|\beta_m|-\kappa_e,
\qquad
\kappa_m\le|\beta_m|,
\qquad
\omega_m\ge2|\beta_m|t_0.
$$

Also use

$$
|\beta_{\pm n}|
\le q_0n+|\beta|,
\qquad
e^{-2\delta\kappa_{\pm n}}
\le e^{2\delta(\kappa_e+|\beta|)}r^n.
$$

After squaring the preceding normal-derivative estimate and dividing by
$\omega_m$, the two signs of $m$ produce the prefactor $1/(4dt_0)$.  Finally,

$$
\sum_{n=N}^\infty r^n=S_0,
\qquad
\sum_{n=N}^\infty nr^n=S_1.
$$

This proves, for every side state $x$,

$$
\sum_{|m|>M}\frac{|j_{\varsigma,m}(x)|^2}{\omega_m}
\le\mathcal C_\varsigma(M)^2\|x\|_2^2,
$$

and the fixed-singleton analogue with $\mathcal C_{\varsigma,0}(M)^2$.
Moreover,

$$
\mathcal C_\varsigma(M)
=O\left(\sqrt M\,e^{-2\pi\delta M/d}\right).
$$

No unknown analytic-continuation norm occurs in this bound.

## Whole-half-guide propagation certificate

For $\varsigma\in\{-,+\}$, suppose an exact Hermitian matrix $Y_\varsigma$
satisfies

$$
Y_\varsigma\succeq0,
\qquad
Y_\varsigma-P_\varsigma^*Y_\varsigma P_\varsigma\succeq I.
$$

Then, for every $x$,

$$
\sum_{n=0}^\infty\|P_\varsigma^nx\|_2^2
\le x^*Y_\varsigma x.
$$

Indeed,

$$
\|P_\varsigma^nx\|_2^2
\le
(P_\varsigma^nx)^*Y_\varsigma P_\varsigma^nx
-(P_\varsigma^{n+1}x)^*Y_\varsigma P_\varsigma^{n+1}x.
$$

The finite sum telescopes.  Its nonnegative left side is bounded by
$x^*Y_\varsigma x$, hence $P_\varsigma^nx\to0$ and the infinite inequality
follows.  This is a
whole-matrix argument and retains nonnormal transients and Jordan coupling.

A scalar alternative is also finite.  If verified numbers satisfy

$$
\|P_\varsigma^{J_\varsigma^{\rm blk}}\|_2
\le\overline a_\varsigma<1,
\qquad
\|P_\varsigma^r\|_2\le\overline p_{\varsigma,r},
\quad 0\le r<J_\varsigma^{\rm blk},
$$

then

$$
\sum_{n=0}^\infty\|P_\varsigma^nx\|_2^2
\le
\frac{\sum_{r=0}^{J_\varsigma^{\rm blk}-1}
\overline p_{\varsigma,r}^2}
{1-\overline a_\varsigma^2}\|x\|_2^2.
$$

This block-power certificate may replace every occurrence of the Lyapunov
quadratic form below.

## Certified finite coefficient rows

For the right and left half-guides, the exact internal-wall rows must be
audited against the frozen code convention

$$
\ell_{+,m}
=Q_{R,m}G_++Q_{L,m}G_+P_+,
\qquad
\ell_{-,m}
=Q_{L,m}G_-+Q_{R,m}G_-P_-.
$$

The corresponding wall coefficients are

$$
j_{\varsigma,n,m}
=\ell_{\varsigma,m}P_\varsigma^nc_\varsigma,
\qquad n\ge0.
$$

The two fixed center/first contributions are denoted
$j_{\varsigma,0,m}^{\rm cf}$ and
are not inserted again into either internal sequence.

For $|m|\le M$, compute a finite approximation
$\widetilde\ell_{\varsigma,m}$ and a rigorous analytic evaluation remainder
$\epsilon_{\varsigma,m}$ satisfying

$$
\|\ell_{\varsigma,m}-\widetilde\ell_{\varsigma,m}\|_2
\le\epsilon_{\varsigma,m}.
$$

Likewise require

$$
|j_{\varsigma,0,m}^{\rm cf}
-\widetilde j_{\varsigma,0,m}^{\rm cf}|
\le\epsilon_{\varsigma,0,m}.
$$

This distinction is essential: an ordinary quadrature value must never be
substituted for an exact row without its remainder.

One direct remainder construction uses the periodic trapezoidal rule.  If a
$2\pi$-periodic scalar- or finite-vector-valued function $f$ is analytic in
$|\operatorname{Im}\theta|\le a$ and
$\sup\|f(\theta)\|_2\le M_a$, contour shifting its Fourier coefficients and
summing the trapezoidal aliases gives

$$
\left\|
\int_0^{2\pi}f(\theta)\,d\theta
-\frac{2\pi}{N_q}\sum_{j=0}^{N_q-1}
f\left(\frac{2\pi j}{N_q}\right)
\right\|_2
\le\frac{4\pi M_a}{e^{aN_q}-1}.
$$

Here the density is a finite trigonometric polynomial.  Let the wall be
$x=x_w$, the circle center be $(c_x,c_y)$, and put

$$
s_\varsigma=\nu_\varsigma\mathbin\cdot e_x\in\{-1,+1\},
\qquad
D=|x_w-c_x|,
\qquad
z=\theta+\mathrm i\eta.
$$

The sign $s_\varsigma$ is kept distinct from the single-layer density
$\sigma$.  In the complex strip, analytically continue the real-axis identity
$D-s_\varsigma R\cos\theta$ as $D-s_\varsigma R\cos z$; do not take a
complex absolute value.  For a frozen state map $A$, define

$$
E_{\varsigma,m}(z)
=\exp\!\left(\mathrm i\gamma_m
[D-s_\varsigma R\cos z]\right)
 \exp\!\left(-\mathrm i\beta_m[c_y+R\sin z]\right).
$$

The exact circle-to-wall target-normal row of $u=D\tau+S\sigma$ is

$$
q_{\varsigma,m}(A)
=\int_0^{2\pi}f_{\varsigma,m}(\theta;A)\,d\theta,
$$

$$
f_{\varsigma,m}(z;A)
=\frac{R}{2\sqrt d}E_{\varsigma,m}(z)
\left\{
\mathrm i[s_\varsigma\gamma_m\cos z+\beta_m\sin z]
t_\tau(z;A)-t_\sigma(z;A)
\right\}.
$$

The minus sign on $t_\sigma$ is forced by the frozen artifact coordinate
$\eta=(\tau,-\sigma)^T$; equivalently, code may insert its stored second
block directly with a plus sign.  Define

$$
D_\tau(A,a)=\sum_\ell
\|\widehat T_{\tau,\ell}A\|_2e^{|\ell|a},
\qquad
D_\sigma(A,a)=\sum_\ell
\|\widehat T_{\sigma,\ell}A\|_2e^{|\ell|a}.
$$

For a propagating order $\gamma_m>0$, orthogonal rotation of the two real
components gives

$$
|E_{\varsigma,m}(z)|\le e^{\kappa_eR\sinh a},
\qquad
|s_\varsigma\gamma_m\cos z+\beta_m\sin z|
\le\kappa_e\cosh a,
$$

and hence

$$
M_{\varsigma,m}^{\rm pr}(A,a)
=\frac{R}{2\sqrt d}e^{\kappa_eR\sinh a}
\left[
\kappa_e\cosh(a)D_\tau(A,a)+D_\sigma(A,a)
\right].
$$

For an evanescent order $\gamma_m=\mathrm i\kappa_m$,

$$
|E_{\varsigma,m}(z)|
\le\Phi_m^{\rm ev}(a)
:=\exp\!\left(
-\kappa_mD+R[\kappa_m\cosh a+|\beta_m|\sinh a]
\right),
$$

$$
|s_\varsigma\mathrm i\kappa_m\cos z+\beta_m\sin z|
\le |\beta_m|\cosh a+\kappa_m\sinh a,
$$

so that

$$
M_{\varsigma,m}^{\rm ev}(A,a)
=\frac{R}{2\sqrt d}\Phi_m^{\rm ev}(a)
\left[
(|\beta_m|\cosh a+\kappa_m\sinh a)D_\tau(A,a)
+D_\sigma(A,a)
\right].
$$

For the evanescent branch, a fixed strip width

$$
0<a_{\rm ev}<\log(D/R)
$$

preserves exponential decay in $|m|$; the frozen geometry may use
$a_{\rm ev}=\tfrac12\log(D/R)$.  Use $M_{\varsigma,m}^{\rm pr}$ or
$M_{\varsigma,m}^{\rm ev}$ according to the audited branch and set

$$
\epsilon_{\varsigma,m}(A)
=\frac{4\pi M_{\varsigma,m}(A,a)}{e^{aN_q}-1}.
$$

Summing these explicit bounds over the finitely many contributing circles
gives the row enclosure.  The estimates follow by writing the real and
imaginary parts of $\sin z$ and $\cos z$; no external theorem is used.
Flat-wall contributions are finite modal algebra.  Thus no kernel-expansion
or quadrature truncation is left unassigned.  Ordinary floating-point rounding
is outside the present task; a later implementation must label its numbers
non-certified unless outward arithmetic is separately authorized.

Define

$$
\overline\omega_{\varsigma,M}
=\sum_{|m|\le M}
\frac{(\|\widetilde\ell_{\varsigma,m}\|_2
+\epsilon_{\varsigma,m})^2}{\omega_m}.
$$

For the exact finite-mode Gram

$$
G_{\Gamma_\pm,\varsigma}^{(M)}
=\sum_{|m|\le M}
\frac{\ell_{\varsigma,m}^*\ell_{\varsigma,m}}{\omega_m},
$$

the triangle inequality gives

$$
G_{\Gamma_\pm,\varsigma}^{(M)}
\preceq\overline\omega_{\varsigma,M}I.
$$

## Conditional theorem and proof

**Theorem (conditional reliable artificial-wall residual bound).**
Assume all of the following.

1. The strong exact-kernel reconstruction and the wall indexing are those
   defined above, with every physical wall counted once.
2. The distance $\delta>0$, the support cutoff condition, and the non-Wood
   branch conditions above hold.
3. The normalized finite-density maps and the singleton density norms are
   formed as specified above.
4. The coefficient enclosures
   $(\widetilde\ell,\epsilon)$ and
   $(\widetilde j^{\rm cf},\epsilon_0)$ hold for every $|m|\le M$.
5. Each side has either the stated Lyapunov certificate $Y_\varsigma$ or the stated
   block-power replacement.

For a cell cutoff $J\ge0$, define the finite computed upper part

$$
\overline F_{M,J}^2
=\sum_{\varsigma\in\{+,-\}}\sum_{|m|\le M}
\frac{1}{\omega_m}
\left[
(|\widetilde j_{\varsigma,0,m}^{\rm cf}|+\epsilon_{\varsigma,0,m})^2
+\sum_{n=0}^{J-1}
\left(
|\widetilde\ell_{\varsigma,m}P_\varsigma^nc_\varsigma|
+\epsilon_{\varsigma,m}\|P_\varsigma^nc_\varsigma\|_2
\right)^2
\right].
$$

With a Lyapunov certificate, define the strict omission tail

$$
T_{M,J}^2
=\sum_{\varsigma\in\{+,-\}}
\left[
\mathcal C_{\varsigma,0}(M)^2
+\overline\omega_{\varsigma,M}
(P_\varsigma^Jc_\varsigma)^*Y_\varsigma
(P_\varsigma^Jc_\varsigma)
+\mathcal C_\varsigma(M)^2c_\varsigma^*Y_\varsigma c_\varsigma
\right].
$$

If the block-power certificate is used instead, put

$$
K_\varsigma
=\frac{\sum_{r=0}^{J_\varsigma^{\rm blk}-1}
\overline p_{\varsigma,r}^2}
{1-\overline a_\varsigma^2}
$$

and replace the two propagated terms in the side-$\varsigma$ summand by

$$
\overline\omega_{\varsigma,M}K_\varsigma
\|P_\varsigma^Jc_\varsigma\|_2^2,
\qquad
\mathcal C_\varsigma(M)^2K_\varsigma\|c_\varsigma\|_2^2,
$$

respectively.  This is the explicit meaning of the block-power alternative;
no unshown infinite-dimensional norm is introduced.

Then

$$
B_{\Gamma_\pm}
\le\sqrt{\overline F_{M,J}^2+T_{M,J}^2}
\le\overline F_{M,J}+T_{M,J}.
$$

**Proof.**  Partition the nonnegative double series defining
$B_{\Gamma_\pm}^2$ into four disjoint pieces.

1. The fixed center/first coefficients with $|m|\le M$ are bounded by the
   first squared term in $\overline F_{M,J}$.
2. The internal coefficients with $|m|\le M$ and $0\le n<J$ are bounded by
   the second squared term in $\overline F_{M,J}$, because

   $$
   |\ell_{\varsigma,m}P_\varsigma^nc_\varsigma|
   \le
   |\widetilde\ell_{\varsigma,m}P_\varsigma^nc_\varsigma|
   +\epsilon_{\varsigma,m}\|P_\varsigma^nc_\varsigma\|_2.
   $$

3. For $|m|\le M$ and $n\ge J$, use
   $G_{\Gamma_\pm,\varsigma}^{(M)}
   \preceq\overline\omega_{\varsigma,M}I$ and apply the Lyapunov telescoping
   inequality to $P_\varsigma^Jc_\varsigma$.  This gives the middle term of
   $T_{M,J}^2$.
4. For every $|m|>M$, apply the positive-distance bound.  The fixed
   center/first contribution gives $\mathcal C_{\varsigma,0}(M)^2$.  Sum the internal
   bounds $\mathcal C_\varsigma(M)^2
   \|P_\varsigma^nc_\varsigma\|_2^2$ over all $n\ge0$ with the same
   Lyapunov inequality, giving the final term of $T_{M,J}^2$.

The pieces are disjoint in wall and Fourier indices, so their squared bounds
add without using cancellation.  Taking square roots proves the first
inequality; $\sqrt{x^2+y^2}\le x+y$ proves the second.  Every term depends only
on frozen finite data, explicit geometry and material constants, and the
finite certificates in the assumptions.  No exact eigenfunction norm or
fitted safety factor appears.  $\square$

The theorem covers $B_{\Gamma_\pm}$ only.  Even after its assumptions are
instantiated, it does not bound $B_\Upsilon$, $B_{\mathrm{lift}}$, or
$\|R\|_{\mu,*}$ by itself.

## Stopping rule

Choose tolerances $\tau_{\rm eval}>0$ and $\tau_{\Gamma_\pm}>0$ before
evaluating results.
Increase $N_q$ only until the explicit trapezoidal remainders used in
$\overline F_{M,J}$ and $\overline\omega_{\varsigma,M}$ meet their assigned
$\tau_{\rm eval}$ budget.  Increase $M$ and $J$ only until

$$
T_{M,J}\le\tau_{\Gamma_\pm}.
$$

The Fourier part decreases at the proved rate above.  The Lyapunov condition
implies $P_\varsigma^Jc_\varsigma\to0$, so the propagated finite-mode tail also
vanishes.  This
rule does not inspect adjacent-resolution drift, a plateau, an empirical order,
or a reference solution.

## Theory-to-data map

The frozen artifact is
`test/i3/e-cap/input/fbie-a1-certificate.mat`, produced from
`test/i3/fb-resid/output/fbie-a1/result.mat` and consumed by
`test/i3/e-cap-v4/check_e_cap_v4.m`.

| theory object | frozen field or construction | audit note |
|---|---|---|
| $\kappa_e=\widehat k\sqrt{\rho_e}$, with $\rho_e=1$ here | `khat = 1.832770289108157` | read directly as `candidate_wavenumber`; not recomputed |
| $\mu=\widehat k^2$ | frozen fields `mu_h = gamma = 3.3590469326375971` | legacy artifact names only; I5 aliases either to `mu_shift`, never to the Rayleigh $\gamma_m$ |
| $\beta,d,R$ | `beta = 0.5`, `d = 1`, `R = 0.2` | read directly |
| wall positions | `X_L = -0.5`, `X_R = 0.5` | the current circle center is implicitly the origin, so $\delta=0.3$; a generalized evaluator must store its center explicitly |
| circle density map $\eta=(\tau,-\sigma)^T$ | `eta_unit_256`, size $512\times194$ | first and second 256 rows are the native nodal samples for $\tau,-\sigma$; convert once to the stated finite Fourier coordinates, orders $-128{:}127$ |
| flat-wall densities | `xi_left_unit_512`, `xi_right_unit_512`, each $512\times194$ | orders $-256{:}255$; `wall_input_unit_512` is not a density |
| center state | `q_center`, size $194\times1$ | fixed singleton data |
| stable/unstable coordinates | `Dplus`, `Dminus`, each $97\times97$ | read directly |
| propagation | `Pplus`, `Pminus`, each $97\times97$ | never replace by individual multipliers |
| starting states | `cplus`, `cminus`, each $97\times1$ | read directly |
| density states | `Gplus`, `Gminus`, each $194\times97$ | `Gplus=[Dplus;Dplus*Pplus]`, `Gminus=[Dminus*Pminus;Dminus]` |
| finite Rayleigh branch table | `branch_port`, orders $-48{:}48$ | high-order branches must be generated from frozen $k,\beta,d$ and the audited branch rule |

All additional operations in the theorem are evaluation-only.  They do not
resolve the eigenvalue, BIE density, QZ decomposition, or propagation matrices.
An implementation should first audit the exact signs, sides, and off-by-one
indexing in the two displayed $\ell_{\varsigma,m}$ formulas.

## Frozen-instance evaluation and gate

The evaluation-only I5 experiment used $M=256$, $J=32$,
$J_\varsigma^{\rm blk}=32$, $N_q=4096$, and
$a=\tfrac12\log(0.5/0.2)$.  It formed the density Fourier maps once and did
not solve an eigenproblem, BIE system, QZ problem, or propagation problem.
In ordinary MATLAB arithmetic it found

$$
\overline F_{256,32}=1.8731996950648226\times10^{-10},
$$

$$
T_{256,32}=3.3170678940550856\times10^{-32}.
$$

The branch, density, side/sign/index, non-Wood, finite-support, and
omitted-evanescent audits passed.  The ordinary block-power values were

$$
\|P_-^{32}\|_2=6.5904121972554577\times10^{-18},
\qquad
\|P_+^{32}\|_2=6.5904121972619458\times10^{-18},
$$

$$
K_-=1.0925516165740661,
\qquad K_+=1.0925516165740725.
$$

The largest displayed composed-row quadrature remainder was
$4.4501477170144028\times10^{-308}$; values whose proved logarithmic bounds
fell below `realmin` were displayed as `realmin`, an enlargement rather than
a silent zero.  The high-mode logs included
$\log\mathcal C_+^2=\log\mathcal C_-^2=-959.65809391428434$.

The new direct $Q_L,Q_R$ rows agree with the frozen ordinary rows to about
$9\times10^{-19}$ relatively.  Because the subsequent $J$ combinations
strongly cancel, their absolute differences of about
$8.94\times10^{-16}$ and $1.60\times10^{-15}$ become relative differences
of $3.70\%$ and $1.16\%$.  The frozen comparison rows do not enter the bound;
this observation is only a conditioning warning and is not used as a
remainder or stopping rule.

The analytic instance gates are therefore executable and pass in ordinary
arithmetic.  The saved result is nevertheless explicitly
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`: none of the finite norms or arithmetic
operations is outward-rounded.  Thus the displayed

$$
\sqrt{\overline F_{256,32}^2+T_{256,32}^2}
=1.8731996950648226\times10^{-10}
$$

is a non-certified numerical demonstration, not a reliable numerical upper
bound.  This caveat is required by the present exclusion of floating-point
rounding; a convergence plateau, finite QZ residual, or FEM/BIE agreement
cannot replace it.

### Shape-general evaluator regression on the same circle

The separate shape-general core consumes only a data-only parameter-curve
contract.  The circle adapter reconstructed the missing $256$-node geometry
from `geom.construct_cont(256,'circle',0,0,R)` and stored positions,
derivatives, real clearances, speed bounds, and analytic-strip bounds in
`test/i5/wall-curve-a1/input/circle-contract-a1.mat`.  The core itself does
not use a circular parameterization, Bessel function, or circle self-action.

The general density mass gate uses

$$
M^{\rm up}=2\pi v_{\max}I,
\qquad L^{\rm up}=2\pi v_{\max},
$$

and hence

$$
\sqrt{L^{\rm up}}\|\sqrt{M^{\rm up}}C\|_F
=2\pi v_{\max}\|C\|_F.
$$

For the regression circle $v_{\max}=R$, recovering the earlier safe density
constant as an instance of G4 rather than as an unweighted nodal norm.
The run in `test/i5/wall-curve-a1/output/attempt-1/` found

$$
\overline F_{256,32}^{\rm gen}
=1.8732039079101324\times10^{-10},
\qquad
T_{256,32}^{\rm gen}
=3.5217504928603392\times10^{-32}.
$$

The geometry, branch, density, side/sign/index, non-Wood,
omitted-evanescent, and ordinary regression gates all passed.  The $Q_L,Q_R$
relative regression defects were $1.88\times10^{-18}$ and
$1.16\times10^{-18}$.  Regression does not enter a remainder or stopping
rule.  The MATLAB command took $13.873845416$ seconds and the workspace proxy
was $90.957354546$ MiB.  No eigenpair, BIE-density, QZ, or propagation-matrix
solve was performed.  Every displayed number remains ordinary floating point
and is labelled `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Role conclusions and review record

**Researcher.**  The wall trace inequality, general-curve retained row,
positive-distance evanescent tail, and whole-matrix propagation lemma close
the mathematical omission mechanism for $B_{\Gamma_\pm}$ without a circle,
convexity, or star-shaped assumption.  The result is conditional only on the
explicit finite gates G1--G10.  The same distance argument does not close
material self terms in $B_\Upsilon$ or $B_{\mathrm{lift}}$.

**Engineer.**  The frozen artifact contains all finite states and coefficient
maps needed by the theorem.  Both the circle-special and shape-general I5
evaluators completed without any eigenvalue/BIE/QZ/propagation solve.  The
new core is governed only by the parameter-curve contract; its command took
$13.874$ seconds and its workspace proxy was $90.957$ MiB.  Its numbers remain
ordinary and non-certified.

**Skeptic, general-shape review.**  Verdict `PASS` with high confidence.  The
review independently checked both wall signs, target/source normal weights,
the cancellation of $1/\gamma_m$, the mass bound, both periodic quadrature
remainders, the two-sided high-mode sum, four disjoint index sets, and both
complete-matrix propagation alternatives.  No circular, convex, or
star-shaped premise was found in the general theorem.

**Skeptic, first pass.**  Verdict `REVISE`.  Two blockers were found in the
first candidate: it substituted ordinary finite rows into a formula written
for exact rows, and it did not fix the frozen-density normalization or define
the singleton high-mode constant.  This note repairs both by using
$(\widetilde\ell,\epsilon)$ throughout
$\overline F_{M,J},\overline\omega_{\varsigma,M}$, by defining the normalized
Fourier maps, and by defining $\mathcal C_{\varsigma,0}$ from exact singleton
density norms.
The reviewer independently confirmed the wall weight, both signs of the
Fourier tail, the normal-derivative factor, the Lyapunov telescoping argument,
and the $n=J$ split.

**Skeptic, bounded pre-I5 re-review.**  At that review time the verdict was
`PASS WITH CONDITIONS` with high confidence and no unresolved theoretical
blocker.  The barred finite formulas,
density normalization, two-sided high-mode factor, target/source normal
weights, singleton constant, strip bound, $n=J$ split, and claim boundary all
passed.  Its then-remaining important caveat was the frozen-instance gate:
the map/sign/index audit, a Lyapunov or block-power certificate, and actual
finite coefficient enclosures had not yet been instantiated.  A second minor
implementation caveat was removed from the theorem by displaying the
block-power replacements explicitly and by recording the direct singleton
map bound above.

## Claim boundary

Established in this note:

- the strong-volume/wall-normal/circle-normal/lifting decomposition, with no
  defect counted twice;
- the exact wall trace weight and the resulting definition of $B_{\Gamma_\pm}$;
- an explicit positive-distance Fourier/Rayleigh tail including the normal
  derivative weight;
- a whole-matrix half-guide summation lemma;
- the conditional finite-part-plus-tail theorem and a drift-free stopping
  rule.

Not established in this note:

- an outward-rounded finite instance certificate or a reliable numerical
  value of $B_{\Gamma_\pm}$;
- a reliable bound for $B_\Upsilon$, $B_{\mathrm{lift}}$, or the total
  $\|R\|_{\mu,*}$;
- any denominator, quotient, eigenvalue error, spectral identification,
  effectivity, reference accuracy, rounding enclosure, or eigenvalue
  enclosure.

No external theorem is invoked: the trace minimization, contour-shift
trapezoidal remainder, geometric sums, and Lyapunov telescoping used here are
proved or reduced directly to the displayed finite inequalities.
