# Shape-general local free-space panel theorem

## Target, status, and local notation

This note treats only the local free-space self-action shared by the material
normal defect $B_\Upsilon$ and the value-defect contribution
$B_{\mathrm{lift}}$.  It uses the common symbols of this directory's
`README.md`.  New local symbols are the material kernel difference $F$, its
entire coefficients $A,B,a$, the periodic logarithm $\lambda$, the chord
quotient $c$, the four difference kernels
${\mathsf S}_\Delta,{\mathsf K}_\Delta,{\mathsf K}_\Delta^*,
{\mathsf T}_\Delta$, and the finite bounds introduced below.

The analytic verdict is `CONDITIONAL GO`.  The common logarithm, jump terms,
hypersingular principal cancellation, finite panel remainder, and complete
omitted-mode bounds are explicit and do not use circular diagonalization.
The remaining conditions are finite interval enclosures of curve divided
differences, kernel-series coefficients, density norms, and retained panel
rows.  None depends on an unknown exact solution.

## Strong local defects and jump ownership

Let the fixed unit normal point from the material interior to the exterior and
use the project free-space fundamental solution

$$
G_\kappa(x,y)=\frac{\mathrm i}{4}H_0^{(1)}(\kappa|x-y|).
$$

The single-, double-, adjoint-double-, and hypersingular boundary operators
are denoted by $S_\kappa,K_\kappa,K_\kappa^*,T_\kappa$, respectively.  Their
local contributions to the two strong defects are

$$
a_\Upsilon^{\mathrm{loc}}
=\tau+(K_e-K_i)\tau+(S_e-S_i)\sigma,
\tag{P1}
$$

$$
j_\Upsilon^{\mathrm{loc}}
=(T_i-T_e)\tau+\sigma+(K_i^*-K_e^*)\sigma.
\tag{P2}
$$

The identity $\tau$ is the double-layer value jump and the identity $\sigma$
is the single-layer normal jump.  They occur exactly once in (P1)--(P2).
Neither belongs to the regular-image or off-surface actions.

## Branch-explicit kernel difference

Put $q=|x-y|^2$ and, for $\kappa>0$, define

$$
J_\kappa(q)=\sum_{n=0}^\infty
\frac{(-\kappa^2q/4)^n}{(n!)^2},
\qquad
D_\kappa(q)=\sum_{n=1}^\infty
\frac{(-1)^nH_n(\kappa^2q/4)^n}{(n!)^2},
$$

$$
c_\kappa=\frac{\mathrm i}{4}
-\frac1{2\pi}\left(\log\frac\kappa2+\gamma_E\right).
$$

The defining series for $J_0$ and $Y_0$, derived in
`s-material-tail.md`, give

$$
G_\kappa(q)
=-\frac1{4\pi}J_\kappa(q)\log q
+c_\kappa J_\kappa(q)+\frac1{2\pi}D_\kappa(q).
\tag{P3}
$$

Define $F=G_{\kappa_e}-G_{\kappa_i}$ and

$$
A(q)=-\frac{J_{\kappa_e}(q)-J_{\kappa_i}(q)}{4\pi},
$$

$$
B(q)=c_{\kappa_e}J_{\kappa_e}(q)
-c_{\kappa_i}J_{\kappa_i}(q)
+\frac{D_{\kappa_e}(q)-D_{\kappa_i}(q)}{2\pi}.
$$

Then

$$
F(q)=A(q)\log q+B(q),
\qquad
A(q)=q\,a(q),
\qquad
a(0)=\frac{\kappa_e^2-\kappa_i^2}{16\pi},
\tag{P4}
$$

where $a$ and $B$ are entire.  Thus the wavenumber-independent leading
logarithm cancels before any absolute bound is taken.

## Four difference kernels and principal cancellation

Let ${\boldsymbol r}:\mathbb R/P_\Lambda\mathbb Z\to\Lambda$ be an embedded
$C^3$ arclength curve.  Write

$$
r={\boldsymbol r}(s)-{\boldsymbol r}(t),
\qquad q=r\mathbin\cdot r,
\qquad n_s=\nu(s),\quad n_t=\nu(t).
$$

Direct differentiation of $q$ gives

$$
{\mathsf S}_\Delta=F(q),
\qquad
{\mathsf K}_\Delta=-2(r\mathbin\cdot n_t)F'(q),
$$

$$
{\mathsf K}_\Delta^*=2(r\mathbin\cdot n_s)F'(q),
$$

$$
{\mathsf T}_\Delta
=-2(n_s\mathbin\cdot n_t)F'(q)
-4(r\mathbin\cdot n_s)(r\mathbin\cdot n_t)F''(q).
\tag{P5}
$$

Consequently (P1) uses
$\tau+{\mathsf K}_\Delta\tau+{\mathsf S}_\Delta\sigma$, while (P2) uses
$\sigma-{\mathsf T}_\Delta\tau-{\mathsf K}_\Delta^*\sigma$.
For $h=s-t$, arclength Taylor expansion yields

$$
q=h^2+O(h^4),\qquad
r\mathbin\cdot n_t=O(h^2),\qquad
r\mathbin\cdot n_s=O(h^2),\qquad
n_s\mathbin\cdot n_t=1+O(h^2).
$$

Inserting (P4) into (P5) proves that the two individual hypersingular
$h^{-2}$ principal parts cancel and

$$
{\mathsf T}_\Delta(s,t)
=-\frac{\kappa_e^2-\kappa_i^2}{4\pi}\log|h|+O(1).
\tag{P6}
$$

Thus $T_i-T_e$ in (P2) is an ordinary integrable logarithmic kernel; it must
not be estimated as the difference of two separate finite-part norms.

## Exact periodic logarithm subtraction

Define

$$
\lambda(h)=\log\left(4\sin^2\frac{\pi h}{P_\Lambda}\right),
\qquad
c(s,t)=\frac{q(s,t)}{4\sin^2(\pi(s-t)/P_\Lambda)}.
\tag{P7}
$$

Embeddedness makes $c$ positive off the diagonal, and arclength regularity
gives a positive continuous diagonal extension.  Hence
$\log q=\lambda+\log c$.  Put

$$
U_1=A'(q)\log c+\frac{A(q)}q+B'(q),
$$

$$
U_2=A''(q)\log c+\frac{2A'(q)}q-\frac{A(q)}{q^2}+B''(q).
$$

Each kernel has the exact split

$$
{\mathsf L}(s,t)=C_{\mathsf L}(s,t)\lambda(s-t)
+R_{\mathsf L}(s,t),
\tag{P8}
$$

where

$$
C_{\mathsf S}=A,
\qquad R_{\mathsf S}=A\log c+B,
$$

$$
C_{\mathsf K}=-2(r\mathbin\cdot n_t)A',
\qquad R_{\mathsf K}=-2(r\mathbin\cdot n_t)U_1,
$$

$$
C_{\mathsf K^*}=2(r\mathbin\cdot n_s)A',
\qquad R_{\mathsf K^*}=2(r\mathbin\cdot n_s)U_1,
$$

$$
C_{\mathsf T}
=-2(n_s\mathbin\cdot n_t)A'
-4(r\mathbin\cdot n_s)(r\mathbin\cdot n_t)A'',
$$

$$
R_{\mathsf T}
=-2(n_s\mathbin\cdot n_t)U_1
-4(r\mathbin\cdot n_s)(r\mathbin\cdot n_t)U_2.
\tag{P9}
$$

The apparently singular $U_2$ is never enclosed separately.  Write
$A=qa$ and set

$$
\pi_s=r\mathbin\cdot n_s,\qquad
\pi_t=r\mathbin\cdot n_t,\qquad
m=n_s\mathbin\cdot n_t.
$$

Then the cancellation-safe form is

$$
\begin{split}
R_{\mathsf T}={}&-2m[(a+qa')\log c+a+B']\\
&-4\pi_s\pi_t(2a'+qa'')\log c
-4\frac{\pi_s\pi_t}{q}a\\
&-8\pi_s\pi_ta'-4\pi_s\pi_tB''.
\end{split}
\tag{P10}
$$

The quotient $\pi_s\pi_t/q$ extends continuously to zero on the diagonal.  Thus
every factor in (P10), unlike $U_2$ alone, has a finite interval enclosure.
The same divided-difference construction shows that all $C_{\mathsf L}$ and
$R_{\mathsf L}$ in (P8) have continuous extensions; in particular

$$
C_{\mathsf T}(s,s)
=-\frac{\kappa_e^2-\kappa_i^2}{8\pi}.
$$

## Finite retained-panel part and its remainder

Choose

$$
0<\delta\le\min\left\{\frac{P_\Lambda}{6},
\frac1{2\kappa_*},\frac{r_*}{2}\right\},
$$

where $r_*$ is a reach lower bound and $\kappa_*$ is a curvature upper bound.
For a frozen density component $\phi$, Taylor expand

$$
g_s(h)=C_{\mathsf L}(s,s+h)\phi(s+h)
$$

through degree $M$.  The finite singular panel part is

$$
\sum_{j=0}^M\frac{\partial_h^jg_s(0)}{j!}
\int_{-\delta}^{\delta}h^j\lambda(h)\,dh.
\tag{P11}
$$

The moments are fixed one-dimensional quantities and can be enclosed by
analytic recurrence or validated one-dimensional quadrature.  If

$$
G_{M+1}\ge
\sup_{s,|h|\le\delta}|\partial_h^{M+1}g_s(h)|,
$$

then

$$
\left|\int_{-\delta}^{\delta}\lambda(h)
[g_s(h)-P_{M,s}(h)]\,dh\right|
\le\frac{G_{M+1}}{(M+1)!}\mathfrak m_{M+1},
$$

$$
\mathfrak m_j
=\frac{4\delta^{j+1}}{j+1}
\left[\log\frac{P_\Lambda}{4\delta}+\frac1{j+1}\right].
\tag{P12}
$$

Indeed, $\delta\le P_\Lambda/6$ implies
$|\lambda(h)|\le2\log(P_\Lambda/(4|h|))$.  The regular factor has the Taylor
remainder

$$
\left|\int_{-\delta}^{\delta}
[R_{\mathsf L}\phi-P_{M,s}^R]\,dh\right|
\le\frac{2\delta^{M+2}}{(M+1)!(M+2)}
\sup|\partial_h^{M+1}(R_{\mathsf L}\phi)|.
\tag{P13}
$$

Off-diagonal panels have a certified positive chord lower bound and use the
same derivative rule without singular subtraction.  A degree-$M$ retained
row enclosure may conservatively assume
${\boldsymbol r}\in C^{M+3}$ and the finite density basis in $C^{M+1}$.
The entire series are truncated constituent by constituent, before the
differences defining $A,a,B$ are formed.  Let $|q|\le Q$,
$x_\kappa=\kappa^2Q/4$, and
$(n)_r=n!/(n-r)!$.  For $0\le r\le N+1$ define

$$
\rho_{J,r,N}(\kappa,Q)
=\frac{x_\kappa}{(N+2)(N+2-r)}<1,
$$

$$
T_{J,r,N}(\kappa,Q)
=\frac{(N+1)_r(\kappa^2/4)^{N+1}Q^{N+1-r}}
{((N+1)!)^2[1-\rho_{J,r,N}(\kappa,Q)]}.
$$

For the harmonic-number series put

$$
\rho_{D,r,N}(\kappa,Q)
=\rho_{J,r,N}(\kappa,Q)
\left(1+\frac1{N+2}\right)<1,
$$

$$
T_{D,r,N}(\kappa,Q)
=\frac{H_{N+1}(N+1)_r(\kappa^2/4)^{N+1}Q^{N+1-r}}
{((N+1)!)^2[1-\rho_{D,r,N}(\kappa,Q)]}.
\tag{P14}
$$

These formulas follow from the exact consecutive ratios
$x_\kappa/[(n+1)(n+1-r)]$ and the bound
$H_{n+1}/H_n\le1+1/(n+1)$.  Apply them separately to
$J_{\kappa_e},J_{\kappa_i},D_{\kappa_e},D_{\kappa_i}$ and add by the triangle
inequality.  The series for $a=A/q$ is the one-index shift of the two
$J$ series.  The series for $B$ is bounded by the two $J$ tails multiplied
by $|c_{\kappa_e}|,|c_{\kappa_i}|$ plus the two $D$ tails divided by
$2\pi$.  Thus no ratio of a possibly vanishing combined coefficient is used.
Finite interval subdivision stops only when (P12)--(P14) and the interval
widths meet assigned tolerances.

## Shape-general local tail for the normal defect

The elementary bound

$$
\int_0^{P_\Lambda}|\lambda(h)|\,dh\le4P_\Lambda\log2
\tag{P15}
$$

follows from
$|\log(2\sin x)|\le|\log\sin x|+\log2$.  Let
$A_\tau^\infty,A_\sigma^\infty$ dominate the $L^\infty$ operator norms of
the finite density maps.  For a general $2\pi$-periodic parameter $t$ with
speed $v(t)$, finite coefficient maps

$$
\tau(t;x)=\sum_n C_{\tau,n}x\,e^{\mathrm i n t},
\qquad
\sigma(t;x)=\sum_n C_{\sigma,n}x\,e^{\mathrm i n t}
$$

give, for example,

$$
A_\tau^\infty=\sum_n\|C_{\tau,n}\|_2,
\qquad
A_\sigma^\infty=\sum_n\|C_{\sigma,n}\|_2.
\tag{P16}
$$

Suppose $0<v_-\le v\le v_+$.  The normal identity satisfies

$$
A_{\sigma,0}^s
:=\sup_{\|x\|_2=1}\|\sigma(\cdot;x)\|_{L^2(ds)}
\le\sqrt{2\pi v_+}\,A_\sigma^\infty.
\tag{P17}
$$

Let $C_{\mathsf L}^\#,R_{\mathsf L}^\#$ be finite interval upper bounds for
the continuous factors in (P8)--(P10), and define

$$
\begin{split}
M_N^{\rm act}:={}&
[4P_\Lambda\log2\,C_{\mathsf T}^\#
+P_\Lambda R_{\mathsf T}^\#]A_\tau^\infty\\
&+[4P_\Lambda\log2\,C_{\mathsf K^*}^\#
+P_\Lambda R_{\mathsf K^*}^\#]A_\sigma^\infty.
\end{split}
\tag{P18}
$$

Equations (P2), (P8), and (P15) give the operator-norm inequality

$$
\|j_\Upsilon^{\rm loc}(x)\|_{L^2(ds)}
\le (A_{\sigma,0}^s+\sqrt{P_\Lambda}M_N^{\rm act})\|x\|_2.
\tag{P19}
$$

For $N=L+1$ put

$$
d_N=\sum_{q\in\{-,+\}}\theta_q\tanh(h_q|\xi_N|).
$$

The general trace theorem in `s-material-tail.md` gives
$b_\ell^\Lambda\ge d_N|\xi_\ell|$ for $|\ell|\ge N$.  For every finite state
vector $x$, Parseval therefore proves

$$
\boxed{
\sum_{|\ell|\ge N}
\frac{|j_{\Upsilon,\ell}^{\rm loc}(x)|^2}{b_\ell^\Lambda}
\le
\frac{(A_{\sigma,0}^s+\sqrt{P_\Lambda}M_N^{\rm act})^2}
{d_N|\xi_N|}\|x\|_2^2.
}
\tag{P20}
$$

This tail includes the identity density $\sigma$ and assumes no finite
arclength-Fourier support.  It decays algebraically and yields the drift-free
local stopping gate obtained by requiring the right side to meet its assigned
tolerance.  The stated trace lower bound follows from
$\sqrt{\theta_q/\Theta_q}\ge\theta_q$ and
$\sqrt{\theta_q\Theta_q}\ge\theta_q$, followed by monotonicity of $\tanh$.

## Shape-general local tail for the lifting contribution

The target derivatives are

$$
\partial_s^2{\mathsf S}_\Delta
=F''(q)q_s^2+F'(q)q_{ss},
$$

$$
\partial_s^2{\mathsf K}_\Delta
=-2\{p_{ss}F'+2p_sq_sF''
+p[F'''q_s^2+F''q_{ss}]\},
\qquad p=r\mathbin\cdot n_t.
\tag{P21}
$$

The factors $q_s=O(h)$ and $p=O(h^2)$ cancel the apparent $q^{-1}$ and
$q^{-2}$ powers.  Hence

$$
\partial_s^2{\mathsf L}
=C_{{\mathsf L},2}\lambda+R_{{\mathsf L},2},
\qquad {\mathsf L}\in\{{\mathsf K}_\Delta,{\mathsf S}_\Delta\},
\tag{P22}
$$

with continuous divided-difference factors.  For the single layer, a
cancellation-safe logarithmic coefficient and regular factor are

$$
C_{{\mathsf S},2}=q_s^2A''+q_{ss}A',
$$

$$
\begin{split}
R_{{\mathsf S},2}={}&q_s^2(2a'+qa'')\log c
+\frac{q_s^2}{q}a+2q_s^2a'+q_s^2B''\\
&+q_{ss}[(a+qa')\log c+a+B'].
\end{split}
\tag{P23}
$$

Here $q_s^2/q$ extends to $4$ on the diagonal.  For the double layer use

$$
\begin{split}
-\frac12R_{{\mathsf K},2}={}&p_{ss}[(a+qa')\log c+a+B']\\
&+2p_sq_s(2a'+qa'')\log c
+2\frac{p_sq_s}{q}a+4p_sq_sa'+2p_sq_sB''\\
&+pq_{ss}(2a'+qa'')\log c
+\frac{pq_{ss}}q a+2pq_{ss}a'+pq_{ss}B''\\
&+pq_s^2(3a''+qa''')\log c
+3\frac{pq_s^2}{q}a'+3pq_s^2a''\\
&-\frac{pq_s^2}{q^2}a+pq_s^2B''',
\end{split}
\tag{P24}
$$

$$
\begin{split}
C_{{\mathsf K},2}=-2\{&p_{ss}A'
+2p_sq_sA''+p[q_s^2A'''+q_{ss}A'']\}.
\end{split}
\tag{P25}
$$

The quotients

$$
\frac{p_sq_s}{q},\qquad
\frac{pq_{ss}}q,\qquad
\frac{pq_s^2}q,\qquad
\frac{pq_s^2}{q^2}
$$

have finite continuous diagonal extensions determined by the curve jet.
They, rather than uncancelled powers of $1/q$, are the interval-evaluation
objects.

If additionally $|v_t|\le v_1$, the identity density obeys

$$
\begin{split}
A_{\tau,2}^s
:={}&\sup_{\|x\|_2=1}\|\partial_s^2\tau(\cdot;x)\|_{L^2(ds)}\\
\le{}&\sqrt{2\pi v_+}\left[
v_-^{-2}\sum_n n^2\|C_{\tau,n}\|_2
+v_1v_-^{-3}\sum_n|n|\|C_{\tau,n}\|_2
\right].
\end{split}
\tag{P26}
$$

Let $C_{{\mathsf L},2}^\#,R_{{\mathsf L},2}^\#$ enclose (P22)--(P25) and
put

$$
\begin{split}
M_V^{(2)}:={}&
[4P_\Lambda\log2\,C_{{\mathsf K},2}^\#
+P_\Lambda R_{{\mathsf K},2}^\#]A_\tau^\infty\\
&+[4P_\Lambda\log2\,C_{{\mathsf S},2}^\#
+P_\Lambda R_{{\mathsf S},2}^\#]A_\sigma^\infty.
\end{split}
\tag{P27}
$$

Then the corresponding operator-norm inequality is

$$
\|\partial_s^2a_\Upsilon^{\rm loc}(x)\|_{L^2(ds)}
\le (A_{\tau,2}^s+\sqrt{P_\Lambda}M_V^{(2)})\|x\|_2.
\tag{P28}
$$

With the tubular lifting weights
$e_\ell^{\rm tub}=C_0^{\rm tub}+C_1^{\rm tub}\xi_\ell^2$ from
`s-lift-tail.md`, Parseval proves for every finite state vector $x$

$$
\boxed{
\sum_{|\ell|\ge N}e_\ell^{\rm tub}
|a_{\Upsilon,\ell}^{\rm loc}(x)|^2
\le
\left[\frac{C_0^{\rm tub}}{|\xi_N|^4}
+\frac{C_1^{\rm tub}}{|\xi_N|^2}\right]
(A_{\tau,2}^s+\sqrt{P_\Lambda}M_V^{(2)})^2\|x\|_2^2.
}
\tag{P29}
$$

This tail includes the identity density $\tau$.  It yields a drift-free
stopping gate and does not assume that a finite parameter-Fourier density has
finite arclength-Fourier support.

## Theorem, computability, and claim boundary

**Theorem (shape-general local panel finite-plus-tail bound).**
Assume an embedded regular $C^3$ parameter curve with computable
$P_\Lambda,r_*,\kappa_*,v_-,v_+,v_1$ and the divided-difference enclosures
used above.  Assume the finite density maps and their coefficient norms are
given.  For retained degree $M$, assume the additional
$C^{M+3}/C^{M+1}$ curve/density derivative enclosures required by
(P11)--(P14).  Then the retained local rows have the explicit finite
singularity-subtracted enclosure (P11)--(P14), and every omitted local normal
and value mode is covered by (P20) and (P29), respectively.

After the source-panel action is enclosed, each retained arclength Fourier
row is completed by validated target integration of that enclosed
target-dependent action plus the identity $\tau$ or $\sigma$.  A composite
Taylor rule uses the same finite target-derivative enclosures and the
ordinary integral remainder on each target panel.  Its enclosure width is
added once to the source-panel and kernel-series remainders; it is not
estimated by comparing two target grids.

**Proof.**  Equations (P3)--(P6) prove the kernel-level cancellation before
absolute values.  Equations (P7)--(P10) isolate the only periodic logarithm
and replace each apparent negative power by a continuous divided difference.
Taylor's theorem and the elementary logarithmic moments give
(P11)--(P14).  Young's inequality in the form used in (P18)--(P19), the
trace-weight lower bound, and Parseval give (P20).  Two exact target
derivatives, the same logarithm split, the parameter-to-arclength identity,
and Parseval give (P21)--(P29).  All source actions are combined by triangle
inequality, so no inter-component cancellation is used after the required
kernel-level Müller cancellation.  $\square$

For a finite state map $A$, apply the theorem to each state
$x=P_\varsigma^nc_\varsigma$ and to the singleton states.  The same Lyapunov
or block-power certificates as `s-wall-tail.md` sum (P20) and (P29) over the
omitted half-guide cells.  Regular-image, off-surface, local, and identity
actions contributing to the same modal defect are first combined by the
triangle inequality for that row or high-mode constant.  Only the singleton,
retained-cell, propagated-cell, and retained/omitted angular partitions are
disjoint.

The first uninstantiated inequalities are the finite enclosures

$$
C_{\mathsf T}^\#,R_{\mathsf T}^\#,
C_{\mathsf K^*}^\#,R_{\mathsf K^*}^\#,
C_{{\mathsf S},2}^\#,R_{{\mathsf S},2}^\#,
C_{{\mathsf K},2}^\#,R_{{\mathsf K},2}^\#,
$$

together with the retained panel remainders.  They are finite computations
from frozen coefficients and geometry, not analytic unknowns.  This local
theorem therefore has status `CONDITIONAL GO`.  It does not itself evaluate
the regular-image Ewald constants, the separated wall action, or either full
residual module, and it gives no denominator or eigenvalue enclosure.

## Independent Skeptic review

After one bounded revision, the independent review verdict is
`PASS WITH CONDITIONS` with high confidence and no blocker.  The revision:

1. included the identity densities in the $L^2/H^2$ tails rather than assuming
   finite arclength-Fourier support;
2. replaced a generic coefficient-ratio assertion by the explicit primitive
   gates (P14);
3. used only cancellation-safe divided differences in (P10), (P23), and
   (P24);
4. stated (P20) and (P29) for each state vector before the half-guide sum; and
5. combined physical actions in the same modal defect by triangle inequality.

The remaining review conditions are finite instantiation of the displayed
geometry, density, divided-difference, kernel-series, source-panel, and target
row enclosures.  Ordinary samples or inter-grid changes do not satisfy those
conditions.

## Direct Kress-product specialization for an analytic curve contract

The following specialization closes the retained-row condition without
replacing the shape-general kernel cancellation (P3)--(P10).  It is an
alternative to evaluating the panelwise Taylor centers (P11)--(P14), not a
claim that an ordinary Kress value is exact.

Let $N=2m$ and let ${\cal K}_N=\{-m+1,\ldots,m\}$.  After the exterior and
interior kernels have been combined and the periodic logarithm has been
subtracted, write either the value or the normal source action at a fixed
target node as

$$
I_i=\int_0^{2\pi}
\{\lambda(t_i-v)F_i(v)+G_i(v)\}\,dv,
\qquad
\lambda(u)=-\sum_{n\ne0}\frac{e^{inu}}{|n|}.
\tag{P30}
$$

For the normal row, $F_i,G_i$ in (P30) mean the already combined Maue--Kress
integrands: the cotangent terms have cancelled before absolute values and the
derivative of the finite trigonometric density is evaluated exactly.  Assume
that a normalized-chord certificate fixes a zero-free analytic branch of
$\log c$ on $|\operatorname{Im}v|\le a$ and supplies

$$
\|F_i(v)\|_2\le M_{F,i},
\qquad
\|G_i(v)\|_2\le M_{G,i}.
$$

Then the Kress product-rule center $Q_i^K$ satisfies

$$
\boxed{
\|I_i-Q_i^K\|_2
\le
4\pi M_{F,i}e^{-am}
\frac{1+e^{-a}}{1-e^{-a}}
+\frac{4\pi M_{G,i}}{e^{aN}-1}.
}
\tag{P31}
$$

Indeed, the Kress weights retain the Fourier multipliers $-|n|^{-1}$ on
${\cal K}_N$.  Aliasing every omitted coefficient to its representative in
${\cal K}_N$, using the strip estimate
$\|\widehat F_i(n)\|_2\le M_{F,i}e^{-a|n|}$, and summing the two geometric
tails gives the first term of (P31).  The standard periodic trapezoid alias
sum for $G_i$ gives the second.  Thus (P31) includes the Nyquist convention
of the implemented Kress weights.

For the Maue normal center, the constants in (P31) must follow the actual
Maue split rather than the direct ${\mathsf T}_\Delta$ split.  Let
$J_e^\#,J_i^\#$ and $D_e^\#,D_i^\#$ bound the entire $J$ and $D$ series on
the certified strip chord domain, let $L_c\ge|\log c|$, and write

$$
\begin{split}
C_M={}&\frac{\kappa_e^2J_e^\#+\kappa_i^2J_i^\#}{4\pi},\\
R_M={}&C_ML_c
+\kappa_e^2\left(|c_{\kappa_e}|J_e^\#+\frac{D_e^\#}{2\pi}\right)
+\kappa_i^2\left(|c_{\kappa_i}|J_i^\#+\frac{D_i^\#}{2\pi}\right).
\end{split}
\tag{P31M}
$$

If $V_a$ bounds the analytic speed, $T_a$ bounds the normalized target/source
tangent dot product, and $C_{\partial F}^\#,R_{\partial F}^\#$ bound the
target arclength derivative of $F$ with the target tangent projection, define

$$
A_{\tau,a}=\sum_n e^{a|n|}\|C_{\tau,n}\|_2,
\qquad
A'_{\tau,a}=\sum_n |n|e^{a|n|}\|C_{\tau,n}\|_2.
$$

Then the actual Maue source integrands are bounded by

$$
\begin{split}
M_F^{\rm Maue}&=V_aT_aC_MA_{\tau,a}
 +C_{\partial F}^\#A'_{\tau,a},\\
M_G^{\rm Maue}&=V_aT_aR_MA_{\tau,a}
 +R_{\partial F}^\#A'_{\tau,a}.
\end{split}
\tag{P31N}
$$

Here the universal cotangent terms in $N_2^{(e)}-N_2^{(i)}$ cancel
algebraically before (P31N) is bounded.  Substitution of (P31N) into (P31)
therefore encloses the same Maue--Kress center that is evaluated numerically;
using $C_{\mathsf T}^\#,R_{\mathsf T}^\#$ in its place would not do so.

Let $H(t)$ be the exact local action, including the appropriate identity
density once, and let

$$
d_\ell=P_\Lambda^{-1/2}\int_0^{2\pi}
v(t)H(t)e^{-i\xi_\ell s(t)}\,dt.
$$

If on $|\operatorname{Im}t|\le a$ the curve certificate gives
$|v(t)|\le V_a$, $|\operatorname{Im}s(t)|\le Y_a$, and
$\|H(t)\|_2\le M_H$, the target trapezoid error is

$$
\epsilon_{\ell}^{\rm tgt}
\le
\frac{4\pi V_aM_H e^{|\xi_\ell|Y_a}}
{\sqrt{P_\Lambda}(e^{aN}-1)}.
\tag{P32}
$$

If $E_i^K$ denotes the right side of (P31), the propagated source radius is

$$
\epsilon_{\ell}^{\rm src}
\le
\frac{2\pi}{N\sqrt{P_\Lambda}}
\sum_{i=0}^{N-1}v(t_i)E_i^K.
\tag{P33}
$$

Consequently every non-Nyquist row $|\ell|\le m-1$ has the computable
enclosure

$$
\boxed{
\|d_\ell-\widetilde d_\ell^K\|_2
\le \epsilon_{\ell}^{\rm src}+\epsilon_{\ell}^{\rm tgt}.
}
\tag{P34}
$$

The cutoff is therefore fixed by the explicit alias and high-mode tails.  The
two Nyquist directions $\ell=\pm m$ are both assigned to the omitted tail;
the single aliased Nyquist slot is never counted as two retained rows.

This corollary remains shape-general: a noncircular curve must provide the
same zero-free normalized-chord, analytic-log, speed, arclength, and split
factor bounds.  For the current circle input those bounds can be generated
exactly from $c(z,w)=R^2$, but the evaluator consumes the certificate fields
rather than a Fourier/Bessel diagonalization.  Equations (P20) and (P29)
remain independent identity-inclusive high-mode fallbacks.  No refinement
difference appears in (P31)--(P34).
