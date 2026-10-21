# Shape-general local free-space panel theorem

## Target, status, and local notation

This note treats only the local free-space self-action shared by the material
normal defect $B_\Upsilon$ and the value-defect contribution
$B_{\mathrm{lift}}$.  It uses the common symbols of this directory's
`README.md`.  New local symbols are the material kernel difference $F$, its
entire logarithmic and regular coefficients $\mathcal J_\Delta,
\mathcal R_\Delta,\mathfrak j_\Delta$, the periodic logarithm $g$, the chord
quotient $c$, the four difference kernels
${\mathsf S}_\Delta,{\mathsf K}_\Delta,{\mathsf K}_\Delta^*,
{\mathsf T}_\Delta$, and the finite bounds introduced below.

The analytic verdict is `CONDITIONAL GO`.  The common logarithm, jump terms,
hypersingular principal cancellation, finite panel remainder, and complete
omitted-mode bounds are explicit and do not use circular diagonalization.
The remaining conditions are finite interval enclosures of curve divided
differences, kernel-series coefficients, density norms, and retained panel
rows.  In addition, the current P32 shape-general strip instantiation is
`DISPROVED`: its weighted-log/path-length inequality is false, and the
replacement product-strip action certificate has not yet been supplied.
None of these obligations depends on an unknown exact solution.

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
Y_\kappa^{\mathrm{reg}}(q)=\sum_{n=1}^\infty
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
+c_\kappa J_\kappa(q)+\frac1{2\pi}Y_\kappa^{\mathrm{reg}}(q).
\tag{P3}
$$

Define $F=G_{\kappa_e}-G_{\kappa_i}$ and

$$
\mathcal J_\Delta(q)
=-\frac{J_{\kappa_e}(q)-J_{\kappa_i}(q)}{4\pi},
$$

$$
\mathcal R_\Delta(q)=c_{\kappa_e}J_{\kappa_e}(q)
-c_{\kappa_i}J_{\kappa_i}(q)
+\frac{Y_{\kappa_e}^{\mathrm{reg}}(q)
-Y_{\kappa_i}^{\mathrm{reg}}(q)}{2\pi}.
$$

Then

$$
F(q)=\mathcal J_\Delta(q)\log q+\mathcal R_\Delta(q),
\qquad
\mathcal J_\Delta(q)=q\,\mathfrak j_\Delta(q),
\qquad
\mathfrak j_\Delta(0)=\frac{\kappa_e^2-\kappa_i^2}{16\pi},
\tag{P4}
$$

where $\mathfrak j_\Delta$ and $\mathcal R_\Delta$ are entire.  Thus the
wavenumber-independent leading
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
g(h)=\log\left(4\sin^2\frac{\pi h}{P_\Lambda}\right),
\qquad
c(s,t)=\frac{q(s,t)}{4\sin^2(\pi(s-t)/P_\Lambda)}.
\tag{P7}
$$

Embeddedness makes $c$ positive off the diagonal, and arclength regularity
gives a positive continuous diagonal extension.  Hence
$\log q=g+\log c$.  Put

$$
U_1=\mathcal J_\Delta'(q)\log c
+\frac{\mathcal J_\Delta(q)}q+\mathcal R_\Delta'(q),
$$

$$
U_2=\mathcal J_\Delta''(q)\log c
+\frac{2\mathcal J_\Delta'(q)}q
-\frac{\mathcal J_\Delta(q)}{q^2}+\mathcal R_\Delta''(q).
$$

Each kernel has the exact split

$$
{\mathsf L}(s,t)=C_{\mathsf L}(s,t)g(s-t)
+R_{\mathsf L}(s,t),
\tag{P8}
$$

where

$$
C_{\mathsf S}=\mathcal J_\Delta,
\qquad R_{\mathsf S}=\mathcal J_\Delta\log c+\mathcal R_\Delta,
$$

$$
C_{\mathsf K}=-2(r\mathbin\cdot n_t)\mathcal J_\Delta',
\qquad R_{\mathsf K}=-2(r\mathbin\cdot n_t)U_1,
$$

$$
C_{\mathsf K^*}=2(r\mathbin\cdot n_s)\mathcal J_\Delta',
\qquad R_{\mathsf K^*}=2(r\mathbin\cdot n_s)U_1,
$$

$$
C_{\mathsf T}
=-2(n_s\mathbin\cdot n_t)\mathcal J_\Delta'
-4(r\mathbin\cdot n_s)(r\mathbin\cdot n_t)\mathcal J_\Delta'',
$$

$$
R_{\mathsf T}
=-2(n_s\mathbin\cdot n_t)U_1
-4(r\mathbin\cdot n_s)(r\mathbin\cdot n_t)U_2.
\tag{P9}
$$

The apparently singular $U_2$ is never enclosed separately.  Write
$\mathcal J_\Delta=q\mathfrak j_\Delta$ and set

$$
\pi_s=r\mathbin\cdot n_s,\qquad
\pi_t=r\mathbin\cdot n_t,\qquad
m=n_s\mathbin\cdot n_t.
$$

Then the cancellation-safe form is

$$
\begin{split}
R_{\mathsf T}={}&-2m[(\mathfrak j_\Delta+q\mathfrak j_\Delta')\log c
+\mathfrak j_\Delta+\mathcal R_\Delta']\\
&-4\pi_s\pi_t(2\mathfrak j_\Delta'
+q\mathfrak j_\Delta'')\log c
-4\frac{\pi_s\pi_t}{q}\mathfrak j_\Delta\\
&-8\pi_s\pi_t\mathfrak j_\Delta'
-4\pi_s\pi_t\mathcal R_\Delta''.
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
\int_{-\delta}^{\delta}h^jg(h)\,dh.
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
\left|\int_{-\delta}^{\delta}g(h)
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
$|g(h)|\le2\log(P_\Lambda/(4|h|))$.  The regular factor has the Taylor
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
differences defining $\mathcal J_\Delta,\mathfrak j_\Delta,
\mathcal R_\Delta$ are formed.  Let $|q|\le Q$,
$x_\kappa=\kappa^2Q/4$, and
$(n)_r=n!/(n-r)!$.  For $0\le r\le N_{\mathrm{ser}}+1$ define

$$
r_{J,r,N_{\mathrm{ser}}}(\kappa,Q)
=\frac{x_\kappa}{(N_{\mathrm{ser}}+2)(N_{\mathrm{ser}}+2-r)}<1,
$$

$$
T_{J,r,N_{\mathrm{ser}}}(\kappa,Q)
=\frac{(N_{\mathrm{ser}}+1)_r(\kappa^2/4)^{N_{\mathrm{ser}}+1}
Q^{N_{\mathrm{ser}}+1-r}}
{((N_{\mathrm{ser}}+1)!)^2
[1-r_{J,r,N_{\mathrm{ser}}}(\kappa,Q)]}.
$$

For the harmonic-number series put

$$
r_{Y,r,N_{\mathrm{ser}}}(\kappa,Q)
=r_{J,r,N_{\mathrm{ser}}}(\kappa,Q)
\left(1+\frac1{N_{\mathrm{ser}}+2}\right)<1,
$$

$$
T_{Y,r,N_{\mathrm{ser}}}(\kappa,Q)
=\frac{H_{N_{\mathrm{ser}}+1}(N_{\mathrm{ser}}+1)_r
(\kappa^2/4)^{N_{\mathrm{ser}}+1}Q^{N_{\mathrm{ser}}+1-r}}
{((N_{\mathrm{ser}}+1)!)^2
[1-r_{Y,r,N_{\mathrm{ser}}}(\kappa,Q)]}.
\tag{P14}
$$

These formulas follow from the exact consecutive ratios
$x_\kappa/[(n+1)(n+1-r)]$ and the bound
$H_{n+1}/H_n\le1+1/(n+1)$.  Apply them separately to
$J_{\kappa_e},J_{\kappa_i},Y_{\kappa_e}^{\mathrm{reg}},
Y_{\kappa_i}^{\mathrm{reg}}$ and add by the triangle
inequality.  The series for $\mathfrak j_\Delta=\mathcal J_\Delta/q$ is the
one-index shift of the two $J$ series.  The series for
$\mathcal R_\Delta$ is bounded by the two $J$ tails multiplied by
$|c_{\kappa_e}|,|c_{\kappa_i}|$ plus the two $Y^{\mathrm{reg}}$ tails divided by
$2\pi$.  Thus no ratio of a possibly vanishing combined coefficient is used.
Finite interval subdivision stops only when (P12)--(P14) and the interval
widths meet assigned tolerances.

## Shape-general local tail for the normal defect

The elementary bound

$$
\int_0^{P_\Lambda}|g(h)|\,dh\le4P_\Lambda\log2
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
M_{\mathrm{nor}}^{\rm act}:={}&
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
\le (A_{\sigma,0}^s
+\sqrt{P_\Lambda}M_{\mathrm{nor}}^{\rm act})\|x\|_2.
\tag{P19}
$$

For the first omitted residual order $L$ put

$$
d_L=\sum_{q\in\{-,+\}}\theta_q\tanh(h_q|\xi_L|).
$$

The general trace theorem in `s-material-tail.md` gives
$b_\ell^\Lambda\ge d_L|\xi_\ell|$ for $|\ell|\ge L$.  For every finite state
vector $x$, Parseval therefore proves

$$
\boxed{
\sum_{|\ell|\ge L}
\frac{|j_{\Upsilon,\ell}^{\rm loc}(x)|^2}{b_\ell^\Lambda}
\le
\frac{(A_{\sigma,0}^s+\sqrt{P_\Lambda}M_{\mathrm{nor}}^{\rm act})^2}
{d_L|\xi_L|}\|x\|_2^2.
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
=C_{{\mathsf L},2}g+R_{{\mathsf L},2},
\qquad {\mathsf L}\in\{{\mathsf K}_\Delta,{\mathsf S}_\Delta\},
\tag{P22}
$$

with continuous divided-difference factors.  For the single layer, a
cancellation-safe logarithmic coefficient and regular factor are

$$
C_{{\mathsf S},2}=q_s^2\mathcal J_\Delta''
+q_{ss}\mathcal J_\Delta',
$$

$$
\begin{split}
R_{{\mathsf S},2}={}&q_s^2(2\mathfrak j_\Delta'
+q\mathfrak j_\Delta'')\log c
+\frac{q_s^2}{q}\mathfrak j_\Delta
+2q_s^2\mathfrak j_\Delta'+q_s^2\mathcal R_\Delta''\\
&+q_{ss}[(\mathfrak j_\Delta+q\mathfrak j_\Delta')\log c
+\mathfrak j_\Delta+\mathcal R_\Delta'].
\end{split}
\tag{P23}
$$

Here $q_s^2/q$ extends to $4$ on the diagonal.  For the double layer use

$$
\begin{split}
-\frac12R_{{\mathsf K},2}={}&p_{ss}
[(\mathfrak j_\Delta+q\mathfrak j_\Delta')\log c
+\mathfrak j_\Delta+\mathcal R_\Delta']\\
&+2p_sq_s(2\mathfrak j_\Delta'+q\mathfrak j_\Delta'')\log c
+2\frac{p_sq_s}{q}\mathfrak j_\Delta
+4p_sq_s\mathfrak j_\Delta'+2p_sq_s\mathcal R_\Delta''\\
&+pq_{ss}(2\mathfrak j_\Delta'+q\mathfrak j_\Delta'')\log c
+\frac{pq_{ss}}q\mathfrak j_\Delta
+2pq_{ss}\mathfrak j_\Delta'+pq_{ss}\mathcal R_\Delta''\\
&+pq_s^2(3\mathfrak j_\Delta''+q\mathfrak j_\Delta''')\log c
+3\frac{pq_s^2}{q}\mathfrak j_\Delta'
+3pq_s^2\mathfrak j_\Delta''\\
&-\frac{pq_s^2}{q^2}\mathfrak j_\Delta
+pq_s^2\mathcal R_\Delta''',
\end{split}
\tag{P24}
$$

$$
\begin{split}
C_{{\mathsf K},2}=-2\{&p_{ss}\mathcal J_\Delta'
+2p_sq_s\mathcal J_\Delta''
+p[q_s^2\mathcal J_\Delta'''
+q_{ss}\mathcal J_\Delta'']\}.
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
\sum_{|\ell|\ge L}e_\ell^{\rm tub}
|a_{\Upsilon,\ell}^{\rm loc}(x)|^2
\le
\left[\frac{C_0^{\rm tub}}{|\xi_L|^4}
+\frac{C_1^{\rm tub}}{|\xi_L|^2}\right]
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

The following specialization closes the fixed-target source-row condition
without replacing the shape-general kernel cancellation (P3)--(P10).  It is
an alternative to evaluating the panelwise Taylor centers (P11)--(P14), not a
claim that an ordinary Kress value is exact.  The separate target-strip step
(P32) remains subject to the audit below.

Let $N=2m$ and let ${\cal K}_N=\{-m+1,\ldots,m\}$.  For
$\chi\in\{\mathrm{val},\mathrm{nor}\}$, after the exterior and interior
kernels have been combined and the periodic logarithm has been subtracted,
write the corresponding source action at a fixed target node as

$$
I_i^\chi=\int_0^{2\pi}
\{K_{1,i}^\chi(v)g(t_i-v)+K_{2,i}^\chi(v)\}\,dv,
\qquad
g(u)=-\sum_{n\ne0}\frac{e^{inu}}{|n|}.
\tag{P30}
$$

For the normal row, $K_{1,i}^{\mathrm{nor}},K_{2,i}^{\mathrm{nor}}$ in
(P30) mean the already combined
Maue--Kress integrands: the cotangent terms have cancelled in the explicit
$T_e-T_i$ split before absolute values, the normal residual applies
$T_i-T_e=-(T_e-T_i)$, and the derivative of the finite trigonometric density
is evaluated exactly.  Assume
that a normalized-chord certificate fixes a zero-free analytic branch of
$\log c$ on $|\operatorname{Im}v|\le a$ and supplies

$$
\|K_{1,i}^\chi(v)\|_2\le M_{K_1,i}^\chi,
\qquad
\|K_{2,i}^\chi(v)\|_2\le M_{K_2,i}^\chi.
$$

Then the Kress product-rule center $Q_i^{K,\chi}$ satisfies

$$
\boxed{
\|I_i^\chi-Q_i^{K,\chi}\|_2
\le
4\pi M_{K_1,i}^\chi e^{-am}
\frac{1+e^{-a}}{1-e^{-a}}
+\frac{4\pi M_{K_2,i}^\chi}{e^{aN}-1}.
}
\tag{P31}
$$

Indeed, the Kress weights retain the Fourier multipliers $-|n|^{-1}$ on
${\cal K}_N$.  Aliasing every omitted coefficient to its representative in
${\cal K}_N$, using the strip estimate
$\|\widehat K_{1,i}^\chi(n)\|_2\le
M_{K_1,i}^\chi e^{-a|n|}$, and summing the two geometric
tails gives the first term of (P31).  The standard periodic trapezoid alias
sum for $K_{2,i}$ gives the second.  Thus (P31) includes the Nyquist convention
of the implemented Kress weights.

For the Maue normal center, the constants in (P31) must follow the actual
Maue split rather than the direct ${\mathsf T}_\Delta$ split.  Let
$J_e^\#,J_i^\#$ and $Y_e^\#,Y_i^\#$ bound the entire $J$ and
$Y^{\mathrm{reg}}$ series on
the certified strip chord domain, let $L_c\ge|\log c|$, and write

$$
\begin{split}
C_S^T={}&\frac{\kappa_e^2J_e^\#+\kappa_i^2J_i^\#}{4\pi},\\
R_S^T={}&C_S^TL_c
+\kappa_e^2\left(|c_{\kappa_e}|J_e^\#+\frac{Y_e^\#}{2\pi}\right)
+\kappa_i^2\left(|c_{\kappa_i}|J_i^\#+\frac{Y_i^\#}{2\pi}\right).
\end{split}
\tag{P31M}
$$

If $V_a$ bounds the analytic speed, $T_a$ bounds the normalized target/source
tangent dot product, and $C_{\partial T}^\#,R_{\partial T}^\#$ bound the
logarithmic and regular factors in the target arclength derivative with the
target tangent projection, define

$$
A_{\tau,a}=\sum_n e^{a|n|}\|C_{\tau,n}\|_2,
\qquad
A'_{\tau,a}=\sum_n |n|e^{a|n|}\|C_{\tau,n}\|_2.
$$

Then the actual Maue source integrands are bounded by

$$
\begin{split}
M_{K_1}^{T_e-T_i}&=V_aT_aC_S^TA_{\tau,a}
 +C_{\partial T}^\#A'_{\tau,a},\\
M_{K_2}^{T_e-T_i}&=V_aT_aR_S^TA_{\tau,a}
 +R_{\partial T}^\#A'_{\tau,a}.
\end{split}
\tag{P31N}
$$

Here the universal cotangent terms in
$C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}}$ cancel
algebraically before (P31N) is bounded.  Substitution of (P31N) into (P31)
therefore encloses the same Maue--Kress center that is evaluated numerically;
using $C_{\mathsf T}^\#,R_{\mathsf T}^\#$ in its place would not do so.

### P32 target-strip audit

The target-strip argument requires three different objects.  They must not be
identified by an appeal to analytic continuation alone.  For either the value
or normal action, the real-axis objects are

$$
H_{\mathbb R}^{\rm val}(t)
=\tau+(K_e-K_i)\tau+(S_e-S_i)\sigma,
$$

$$
H_{\mathbb R}^{\rm nor}(t)
=(T_i-T_e)\tau+\sigma+(K_i^*-K_e^*)\sigma.
$$

Bundle their signs, the signed source Jacobian, and the density into finitely
many terms.  For $\chi\in\{\mathrm{val},\mathrm{nor}\}$, write the
corresponding real-axis action as

$$
H_{\mathbb R}^\chi(t)=J^\chi(t)+\sum_j\int_0^{2\pi}
\{K_{1,j}^\chi(t,u)g(t-u)+K_{2,j}^\chi(t,u)\}\,du,
\tag{P32a}
$$

where $J^{\mathrm{val}}=\tau$ and $J^{\mathrm{nor}}=\sigma$.
The complete factors $K_{1,j}^\chi$ contain $C_{\mathsf L}(t,u)$, the
appropriate component of $\eta=(\tau,-\sigma)^{\mathsf T}$, and the signed
source speed.  The complete factors $K_{2,j}^\chi$ contain the corresponding
regular factors and the same required density and source terms.  Thus the
source Jacobian is part of $K_{1,j}^\chi,K_{2,j}^\chi$ and may not be silently replaced
by a Euclidean modulus after
complexification.

Let $H_{\rm an}^\chi$ denote the unique holomorphic continuation of
$H_{\mathbb R}^\chi$, if it exists.  The expression currently bounded by the I5
code is instead the simultaneous-shift expression, for $z=x+\mathrm i y$,

$$
\widetilde H^\chi(z)=J^\chi(z)+\sum_j\int_0^{2\pi}
\{K_{1,j}^\chi(z,u+\mathrm i y)g(x-u)
+K_{2,j}^\chi(z,u+\mathrm i y)\}\,du.
\tag{P32b}
$$

Here the logarithm in (P32b) is the real periodic logarithm; it is not a
chosen value of a complex logarithm at $z-(u+\mathrm i y)$.

A shape-general proof of $\widetilde H^\chi=H_{\rm an}^\chi$ is available only under
the following product-strip hypotheses.  On a neighbourhood of the closed
polystrip $S_a\times S_a$, the parameter curve and finite densities must be
periodic and holomorphic; ${\boldsymbol r}'(w)\mathbin\cdot
{\boldsymbol r}'(w)$ must have a nonzero periodic holomorphic signed-square-
root $v(w)$; and

$$
c(z,w)=\frac{({\boldsymbol r}(z)-{\boldsymbol r}(w))\mathbin\cdot
({\boldsymbol r}(z)-{\boldsymbol r}(w))}
{4\sin^2((z-w)/2)}
\tag{P32c}
$$

must extend jointly holomorphically across the periodic diagonal, be
zero-free on the whole polystrip, and possess one periodic holomorphic branch
of $\log c$.  All cancellation-safe divided differences in (P10) and the
Maue form must then extend jointly holomorphically there.  In particular,
there may be no non-diagonal complex null chord in the source-contour sweep.

Under those hypotheses the logarithmic part can be treated without moving a
singular complex logarithm.  If

$$
K_{1,j}^\chi(z,w)=\sum_{p,q\in\mathbb Z}
K_{1,j;pq}^\chi e^{\mathrm i pz+\mathrm i qw},
$$

then on every strict substrip absolute convergence and the Fourier series of
$g$ give

$$
\begin{split}
\int_0^{2\pi}g(x-u)K_{1,j}^\chi(z,u+\mathrm i y)\,du
&=-2\pi\sum_{p\in\mathbb Z}\sum_{q\ne0}
\frac{K_{1,j;pq}^\chi}{|q|}e^{\mathrm i(p+q)z}.
\end{split}
\tag{P32d}
$$

The right side is precisely the holomorphic continuation of the real-axis
logarithmic convolution.  For the regular part, joint holomorphy across the
diagonal permits deformation of the source contour from the real axis to
$u+\mathrm i y$; periodicity cancels the two vertical sides.  The identity
term is continued directly and is still counted once.  In the normal action,
the Maue integration by parts is performed after the interior/exterior
difference: the universal cotangent terms cancel before absolute values, the
periodic endpoint terms cancel, and the punctured-diagonal term tends to zero
because $\partial_h(G_{\kappa_e}-G_{\kappa_i})=O(h\log|h|)$.  These steps prove
$\widetilde H^\chi=H_{\rm an}^\chi$ without any circular Fourier/Bessel
diagonalization.  Bounds on the closed strip additionally require continuity
there (or certification on a wider strip); otherwise (P32) must use a strict
width $b<a$.

The present I5 certificate does not establish these product-strip
hypotheses.  Its Boolean `simultaneous_shift_admissible` does not exclude a
complex null chord during the source-contour deformation and does not certify
the signed-speed or divided-difference extensions.  Therefore (P32d) cannot
currently be applied to the frozen-instance output.

There is also a separate shape-general error in the stored action majorant.
A bound on complex path length alone does not imply

$$
\int_0^{2\pi}|g(x-u)|\,|v(u+\mathrm i y)|\,du
\le4\log2\sup_{|y|\le a}\int_0^{2\pi}|v(u+\mathrm i y)|\,du.
\tag{P32e}
$$

Indeed, $|g|$ is unbounded at $u=x$, whereas an $L^1$ bound on the
second factor does not prevent concentration there.  Explicitly, let

$$
W_n(u)=\frac12\left[1+\frac1n
\left(\frac{\sin(nu/2)}{\sin(u/2)}\right)^2\right].
$$

These positive trigonometric polynomials all have integral $2\pi$.  On
$|u|\le n^{-1}$ they are bounded below by a fixed positive multiple of $n$,
while $|g(u)|$ is bounded below by $2\log n-O(1)$.  Hence
$\int|g(u)|W_n(u)\,du\to\infty$, disproving (P32e) from its stated
$L^1$ datum.  A valid general bound uses

$$
V_a\ge\sup_{w\in S_a}|v(w)|,
\qquad
L_a\ge\sup_{|y|\le a}\int_0^{2\pi}|v(u+\mathrm i y)|\,du,
\qquad
\int_0^{2\pi}|g(x-u)|\,|v(u+\mathrm i y)|\,du
\le8\pi\log2\,V_a.
\tag{P32f}
$$

Consequently valid shape-general strip-action candidates are

$$
\begin{split}
M_H^{\rm val}={}&A_{\tau,a}
+[8\pi\log2\,V_aC_{\mathsf K}^\#+L_aR_{\mathsf K}^\#]A_{\tau,a}\\
&+[8\pi\log2\,V_aC_{\mathsf S}^\#+L_aR_{\mathsf S}^\#]A_{\sigma,a},\\
M_H^{\rm nor}={}&A_{\sigma,a}
+[8\pi\log2\,V_aC_{\mathsf T}^\#+L_aR_{\mathsf T}^\#]A_{\tau,a}\\
&+[8\pi\log2\,V_aC_{\mathsf K^*}^\#+L_aR_{\mathsf K^*}^\#]A_{\sigma,a}.
\end{split}
\tag{P32g}
$$

The previously displayed ordinary values
$M_H^{\rm val}=192.54212145058278$ and
$M_H^{\rm nor}=1295.8632330248495$ are not presently proved bounds for
$H_{\rm an}^\chi$.  They must remain rejected by the theorem gate; no conclusion
is drawn from their observed size.

Now let $H^\chi=H_{\rm an}^\chi$ be an exact local action for which the
hypotheses above and a genuine bound
$\|H^\chi(z)\|_2\le M_H^\chi$ on the closed target strip have been
certified, including the appropriate identity density once, and let

$$
d_\ell^\chi=P_\Lambda^{-1/2}\int_0^{2\pi}
v(t)H^\chi(t)e^{-i\xi_\ell s(t)}\,dt.
$$

If on $|\operatorname{Im}t|\le a$ the curve certificate gives
$|v(t)|\le V_a$, $|\operatorname{Im}s(t)|\le Y_a$, and
$\|H^\chi(t)\|_2\le M_H^\chi$, the target trapezoid error is

$$
\epsilon_{\ell}^{\mathrm{tgt},\chi}
\le
\frac{4\pi V_aM_H^\chi e^{|\xi_\ell|Y_a}}
{\sqrt{P_\Lambda}(e^{aN}-1)}.
\tag{P32}
$$

If $E_i^{K,\chi}$ denotes the right side of (P31), the propagated source
radius is

$$
\epsilon_{\ell}^{\mathrm{src},\chi}
\le
\frac{2\pi}{N\sqrt{P_\Lambda}}
\sum_{i=0}^{N-1}v(t_i)E_i^{K,\chi}.
\tag{P33}
$$

Consequently, after choosing $L$ from the omission tail and imposing
$N>2\max\{L,M_\eta\}$, every retained row $|\ell|<L$ has the computable
enclosure

$$
\boxed{
\|d_\ell^\chi-\widetilde d_\ell^{K,\chi}\|_2
\le \epsilon_{\ell}^{\mathrm{src},\chi}
+\epsilon_{\ell}^{\mathrm{tgt},\chi}.
}
\tag{P34}
$$

The cutoff is therefore fixed by the explicit omission tail before $N$ is
increased to control source and target evaluation errors.  All
$|\ell|\ge L$, including both Nyquist directions $\ell=\pm m$, are assigned
to the omitted tail; the single aliased Nyquist slot is never counted as two
retained rows.

Equations (P32)--(P34) are shape-general only after the product-strip
hypotheses before (P32c), the corrected action bound (P32g), and a genuine
closed-strip bound have all been certified.  They are not instantiated by
the current I5 input.  Equations (P20) and (P29) remain independent
identity-inclusive high-mode fallbacks.  No refinement difference appears in
(P31)--(P34).
