# Real-variable interpolation bound for material value-jump lifting

## Scope, status, and final bound

This note replaces only the **material value-jump evaluation** inside the
minimum-energy lifting theorem in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail]].
It does not change the global simultaneous jump quotient, the factor-one
product Cauchy--Schwarz proof, the material-normal or wall-normal residual,
the frozen reconstruction, or the artificial-wall Rayleigh evaluation.  The
theorem is shape general.  The current circle is only an instance adapter and
is not used in the proof.

For the exact complete material value-jump row balls specified below, define
the finite material energy $E_{\mathrm{mat,fin}}^{\mathrm{RI}}$, the propagated
cell tail $E_{\mathrm{mat,cell}}^{\mathrm{RI}}$, and the unchanged artificial-wall
Rayleigh energy $E_{\mathrm{wall}}$ by (RI-17)--(RI-19).  Then

$$
\boxed{
B_{\mathrm{lift}}^{\mathrm{RI}}
\le
\left(
E_{\mathrm{mat,fin}}^{\mathrm{RI}}
+E_{\mathrm{mat,cell}}^{\mathrm{RI}}
+E_{\mathrm{wall}}
\right)^{1/2}.}
\tag{RI-1}
$$

Consequently the complete residual numerator obeys

$$
\boxed{
\|R\|_{\mu,*}
\le
B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}^{\mathrm{RI}}.}
\tag{RI-2}
$$

There is no outer factor $2$ in (RI-1).  Formula (RI-1) is one comparison
upper for the global simultaneous quotient $q_{\mathrm{all}}$ of (ME-3); it
is not a sum of independently minimized per-interface quotients.

The theorem implication is `ESTABLISHED` under the stated exact row-ball and
geometry inputs.  The independently reviewed frozen run 04 selects $N=514$
and gives the `PASS WITH CONDITIONS` conditional ideal values

$$
\begin{gathered}
\epsilon_N^{(0),\mathrm{sel}}=6.0278441945300462\,10^{-6},
\qquad L_{\mathrm{total}}=1624.2467206052913,\\
R_0=2.642100809251934,
\qquad R_1=3315231.5072913063,
\qquad \mathcal R=744.24301691330515,\\
E_{\mathrm{mat,fin}}^{\mathrm{RI}}=1609125.8284670974,
\qquad
E_{\mathrm{mat,cell}}^{\mathrm{RI}}
=6.0667993516236794\,10^{-10},\\
E_{\mathrm{wall}}=5.9767862107677079\,10^{-30},
\qquad
B_{\mathrm{lift}}^{\mathrm{RI}}=1268.5132354323696,\\
\mathcal M_{\mathrm{RI,ideal}}=1268.5132360299708.
\end{gathered}
\tag{RI-3a}
$$

Here $L_{\mathrm{total}}$ is the persisted complete exact-action derivative
upper used in (RI-20); it is not a sampled Lipschitz estimate.

These are ordinary roundoff-excluded values, not a fully reliable or
outward-rounded result.  The tightness verdict is `STOP`:
$E_{\mathrm{mat,fin}}^{\mathrm{RI}}$ is dominated by the $d_j=0$ global
first-derivative radius.  Increasing $N$ is not the recommended repair.  The
shortest next step is a nonzero signed derivative center with complete panel
balls.  Moreover
$\Delta_{\mathrm{sf}}=\mathrm{UNRESOLVED}$ and
$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$ remain unchanged.  Thus the
governing statement is still

$$
\|R\|_{\mu,*}
\le \mathcal M_{\mathrm{RI,ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}},
\qquad
\mathcal M_{\mathrm{RI,ideal}}
:=B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}^{\mathrm{RI}}.
\tag{RI-3}
$$

No material value-jump Fourier coefficient, material cutoff $L_0$ or $L_1$,
material Fourier tail, material target DFT, or material target FFT occurs in
(RI-1)--(RI-3).  The artificial-wall Rayleigh representation is the explicit
exception.

## Owners

| owner | controlled object | counted location |
|---|---|---|
| identity | the material value identity/jump row | inside the signed physical row once |
| local | diagonal-safe Kress source rule and kernel-series remainder | node and derivative-panel row balls |
| regular image | exact quasi-periodic regular-image center and M-R/M-I/M-T/M-L remainders | the same signed row balls |
| off surface | frozen wall-to-boundary Rayleigh action and its finite evaluation remainder | the same signed row balls |
| real target interpolation | error between the complete physical row and one continuous piecewise-linear center | $R_0$ in (RI-10) |
| real target derivative | error between the derivative of the complete physical row and the derivative of that same center | $R_1$ in (RI-10) |
| propagated cells | cells beyond the retained cell depth | (RI-18), once per side |
| artificial wall | retained and omitted wall Rayleigh modes | unchanged (ME-21)--(ME-30) |

Local, regular-image, off-surface, and identity centers are combined with
their physical signs before any row norm is taken.  Their analytic radii are
then added by the triangle inequality.  The value and derivative errors in
(RI-10) are two components of one $H^1$ comparison norm, not duplicate
residual owners.

## Finite inputs and stopping rule

For every material interface and every frozen state-row label, the evaluator
requires:

1. a single closed, simple $C_{\mathrm{per}}^{p+2}$ chart with $p\ge2$, its
   perimeter, a positive speed lower bound, a chord--arc bound, reach,
   curvature, and all clearances needed by the existing local, regular-image,
   and off-surface theorems;
2. one pre-registered even evaluation size $N>2M_\eta$, whose nodes supply
   both the source rule and the arclength interpolation partition, with
   positive panel lengths and a reused periodic seam node;
3. complete signed value-row balls at all panel endpoints and complete signed
   first arclength-derivative row balls over every panel;
4. the collar constants $W_{0,\Lambda},W_{1,\Lambda}$ from (ME-13)--(ME-14)
   and one fixed auxiliary inverse length $\alpha_\Lambda>0$;
5. the frozen state maps, propagation matrices and starting states, together
   with the existing Lyapunov or block-power certificates;
6. the unchanged artificial-wall inputs and gates in (ME-21)--(ME-30).

Pre-register one even schedule, with every candidate satisfying
$N>2M_\eta$.  For each candidate compute no row center: the selector uses
only the complete zeroth-order node source, kernel-series, and Ewald analytic
radius.  All remaining candidate-independent analytic gates must also pass.
Choose the first strict radius-pass candidate.  At that selected $N$, use the
same nodes as the interpolation partition and evaluate the complete centers
once.  The first-derivative certificate is not a selector: the current
adapter takes $d_j=0$ and uses a complete exact-action derivative upper as
$r'_j$.  It remains a mandatory analytic admissibility gate for the finite
majorant.  No independent target-panel or target-FFT selector exists.

The resulting $R_0,R_1$, cell tail, and tightness tests are persisted.  Their
failure to meet a performance allocation triggers a route upgrade but does
not invalidate an otherwise finite analytic majorant.  A nonfinite or failed
analytic enclosure still stops without a majorant.  No inter-level drift,
plateau, Richardson extrapolation, fitted order, or empirical safety factor
is a stopping rule.

## Complete signed row

Let $\Lambda$ be one material interface, parametrized by arclength
$s\in\mathbb R/P_\Lambda\mathbb Z$.  Let $X\simeq\mathbb C^m$ be one finite
frozen input space.  It may be either the density-coordinate space before a
state map or a state space after that map, but one implementation must choose
one convention.  Write the physical row as

$$
A(s)
=A^{\mathrm{id}}(s)+A^{\mathrm{loc}}(s)
+A^{\mathrm{reg}}(s)+A^{\mathrm{off}}(s)
\in\mathcal L(X,\mathbb C).
\tag{RI-4}
$$

The signs in (RI-4) are the physical value-jump signs.  Assume
$A\in W_{\mathrm{per}}^{1,\infty}
(0,P_\Lambda;\mathcal L(X,\mathbb C))$.  This regularity is not inferred from
sampled data; it is certified by the component row-ball producers described
below.

Choose

$$
0=s_0<s_1<\cdots<s_J=P_\Lambda,
\qquad h_j=s_{j+1}-s_j>0,
\tag{RI-5}
$$

and reuse the same center at the periodic seam, $c_J=c_0$.  Suppose finite
operator-row balls give

$$
\|A(s_j)-c_j\|_{\mathrm{op}}\le r_j,
\qquad
\|A'(s)-d_j\|_{\mathrm{op}}\le r'_j
\quad(s\in[s_j,s_{j+1}]).
\tag{RI-6}
$$

All norms in (RI-6) are row/operator $2$-norms in the complete frozen state
space; they are not entrywise sampled maxima.

## Piecewise-linear center and explicit remainder

Let $C_h=I_hc$ be the continuous periodic piecewise-linear function with
nodal values $c_j$.  Its weak derivative on panel $j$ is

$$
b_j=\frac{c_{j+1}-c_j}{h_j}.
\tag{RI-7}
$$

The independent derivative center $d_j$ in (RI-6) must not replace $b_j$ in
the center derivative.  Define

$$
L_j=\|d_j\|_{\mathrm{op}}+r'_j,
\qquad
\eta_j=\|d_j-b_j\|_{\mathrm{op}}+r'_j.
\tag{RI-8}
$$

For $s=s_j+\theta h_j$, $0\le\theta\le1$, put

$$
\rho_j(\theta)
=(1-\theta)r_j+\theta r_{j+1}
+2h_j\theta(1-\theta)L_j.
\tag{RI-9}
$$

Then

$$
\|A(s)-C_h(s)\|_{\mathrm{op}}\le\rho_j(\theta),
\qquad
\|A'(s)-b_j\|_{\mathrm{op}}\le\eta_j.
$$

Indeed, if $I_hA$ denotes the exact endpoint interpolant, then

$$
A(s)-I_hA(s)
=(1-\theta)(A(s)-A(s_j))
+\theta(A(s)-A(s_{j+1})),
$$

and the derivative bound in (RI-6) gives
$\|A(s)-I_hA(s)\|_{\mathrm{op}}
\le2h_j\theta(1-\theta)L_j$.  Interpolating the endpoint balls proves the
first inequality.  The second is the triangle inequality applied to
$A'-d_j+d_j-b_j$; no unconditional $2L_j$ bound is used.

Define the two squared operator-error integrals

$$
\begin{aligned}
R_0
&:=\sum_jh_j\int_0^1\rho_j(\theta)^2\,d\theta\\
&=\sum_j\left[
\frac{h_j}{3}(r_j^2+r_jr_{j+1}+r_{j+1}^2)
+\frac{h_j^2L_j}{3}(r_j+r_{j+1})
+\frac{2h_j^3L_j^2}{15}\right],\\
R_1&:=\sum_jh_j\eta_j^2,
\end{aligned}
\tag{RI-10}
$$

and the Hermitian state Gram matrices

$$
\begin{aligned}
Q_0
&:=\sum_jh_j\left[
\frac{c_j^*c_j+c_{j+1}^*c_{j+1}}3
+\frac{c_j^*c_{j+1}+c_{j+1}^*c_j}{6}
\right],\\
Q_1&:=\sum_jh_jb_j^*b_j.
\end{aligned}
\tag{RI-11}
$$

The exact piecewise-linear mass integrals give, for every $x\in X$,

$$
\|C_hx\|_{L^2}^2=x^*Q_0x,
\qquad
\|C_h'x\|_{L^2}^2=x^*Q_1x,
\tag{RI-12}
$$

$$
\|(A-C_h)x\|_{L^2}^2\le R_0\|x\|_2^2,
\qquad
\|(A'-C_h')x\|_{L^2}^2\le R_1\|x\|_2^2.
\tag{RI-13}
$$

## Direct real-variable comparison with minimum energy

The shape-general comparison theorem (ME-13) gives

$$
\overline w_{\Lambda,\ell}
\le W_{0,\Lambda}+W_{1,\Lambda}|\xi_\ell|,
\qquad \xi_\ell=\frac{2\pi\ell}{P_\Lambda}.
$$

Fix $\alpha_\Lambda>0$ with units of inverse length and set

$$
a_{0,\Lambda}
=W_{0,\Lambda}+\frac{W_{1,\Lambda}\alpha_\Lambda}{2},
\qquad
a_{1,\Lambda}=\frac{W_{1,\Lambda}}{2\alpha_\Lambda}.
\tag{RI-14}
$$

Since
$|\xi|\le(\alpha_\Lambda+\xi^2/\alpha_\Lambda)/2$, Parseval gives for the
comparison energy contribution

$$
\mathcal E_\Lambda(f)
:=\sum_{\ell\in\mathbb Z}
\overline w_{\Lambda,\ell}|f_\ell|^2
\le
a_{0,\Lambda}\|f\|_{L^2(\Lambda)}^2
+a_{1,\Lambda}\|\partial_sf\|_{L^2(\Lambda)}^2.
\tag{RI-15}
$$

Fourier coefficients occur only in this proof of the fixed trace inequality;
the evaluator uses the right-hand side of (RI-15) and never forms them.
Equation (ME-15a) supplies a valid alternative norm comparison, but it is not
the governing estimator here.

Let

$$
H_\Lambda=a_{0,\Lambda}Q_0+a_{1,\Lambda}Q_1,
\qquad
\mathcal R_\Lambda
=\sqrt{a_{0,\Lambda}R_0+a_{1,\Lambda}R_1}.
\tag{RI-16}
$$

Minkowski's inequality applied once in the weighted product
$L^2\times L^2$ yields

$$
\mathcal E_\Lambda(Ax)^{1/2}
\le \sqrt{x^*H_\Lambda x}
+\mathcal R_\Lambda\|x\|_2.
$$

This proves the local comparison bound without defining or adding an
independent per-interface minimum quotient.

## Finite states, propagation, and global assembly

For each interface, let $\mathscr S_\Lambda$ be the finite set of
nonpropagated singleton row/state pairs $(A_{\Lambda,r},x_{\Lambda,r})$.
For each side $\varsigma\in\{-,+\}$, the current adapter uses a base row
$A_{\Lambda}^{\mathrm{base}}$ on the density-coordinate space and applies
the frozen density-to-state map $G_\varsigma$ once to
$P_\varsigma^nc_\varsigma$.  For the formulas below set

$$
H_{\Lambda,\varsigma}
=G_\varsigma^*H_{\Lambda}^{\mathrm{base}}G_\varsigma,
\qquad
\mathcal R_{\Lambda,\varsigma}
=\mathcal R_{\Lambda}^{\mathrm{base}}\|G_\varsigma\|_2.
$$

Build $H_{\Lambda,r},\mathcal R_{\Lambda,r}$ from each singleton's row
balls.  Define

$$
\Phi_{\Lambda,a}(x)
:=\sqrt{x^*H_{\Lambda,a}x}
+\mathcal R_{\Lambda,a}\|x\|_2.
$$

For a retained cell depth $J_{\mathrm{cell}}$,

$$
E_{\mathrm{mat,fin}}^{\mathrm{RI}}
=\sum_\Lambda\left[
\sum_{r\in\mathscr S_\Lambda}
\Phi_{\Lambda,r}(x_{\Lambda,r})^2
+\sum_{\varsigma\in\{-,+\}}
\sum_{n=0}^{J_{\mathrm{cell}}-1}
\Phi_{\Lambda,\varsigma}
(P_\varsigma^nc_\varsigma)^2
\right].
\tag{RI-17}
$$

Suppose the existing block-power certificate gives

$$
\sum_{n\ge J_{\mathrm{cell}}}
\|P_\varsigma^nc_\varsigma\|_2^2
\le
K_\varsigma
\|P_\varsigma^{J_{\mathrm{cell}}}c_\varsigma\|_2^2.
$$

Then

$$
E_{\mathrm{mat,cell}}^{\mathrm{RI}}
=\sum_{\Lambda,\varsigma}
\left(
\sqrt{\|H_{\Lambda,\varsigma}\|_2}
+\mathcal R_{\Lambda,\varsigma}
\right)^2
K_\varsigma
\|P_\varsigma^{J_{\mathrm{cell}}}c_\varsigma\|_2^2.
\tag{RI-18}
$$

If a code path instead precomposes $G_\varsigma$ into its certified row
balls, it uses the resulting $H_{\Lambda,\varsigma}$ and
$\mathcal R_{\Lambda,\varsigma}$ directly and omits the preceding
substitution.  Whenever a base-row certificate is used, the only admissible
transformation is

$$
H_{\Lambda}^{\mathrm{base}}\longmapsto
G_\varsigma^*H_{\Lambda}^{\mathrm{base}}G_\varsigma,
\qquad
\mathcal R_{\Lambda}^{\mathrm{base}}\longmapsto
\mathcal R_{\Lambda}^{\mathrm{base}}\|G_\varsigma\|_2,
$$

and it occurs exactly once.  The evaluator may not apply $G_\varsigma$ both
inside and outside the row.

Let $E_{\mathrm{wall}}$ be exactly the sum of the retained, high-mode, and
propagated artificial-wall comparison energies in (ME-21)--(ME-30):

$$
E_{\mathrm{wall}}
=E_{\mathrm{wall,fin}}+E_{\mathrm{wall,high}}
+E_{\mathrm{wall,cell}}.
\tag{RI-19}
$$

The material collars and wall collars have pairwise disjoint supports, every
comparison function has zero trace on its collar rim, and the corrections
belong to the broken energy-square-summable Hilbert direct sum in (ME-1).
Constructing all their corrections at once therefore gives one admissible
element of the affine fibre in (ME-3), so

$$
q_{\mathrm{all}}(a)^2
\le
E_{\mathrm{mat,fin}}^{\mathrm{RI}}
+E_{\mathrm{mat,cell}}^{\mathrm{RI}}
+E_{\mathrm{wall}}.
$$

Combining this inequality with the factor-one product Cauchy--Schwarz bound
(ME-5) proves (RI-1).  At no point is a sum of independently minimized
full-domain quotients used.

## Shape-general row-ball interface

For a general parameter $t$, arclength differentiation is
$\partial_s=|z'(t)|^{-1}\partial_t$.  The following finite certificates are
sufficient for (RI-6):

1. **Local row.**  The diagonal-continuous Kress split, including the density
   and source Jacobian, supplies zeroth- and first-target-derivative source
   remainders.  One admissible interface is

   $$
   S_{j,p}^{(q)}
   \ge
   \sup_{t\text{ in target panel}}
   \int_0^{2\pi}
   \left|
   \partial_u^p(\partial_t+\partial_u)^q
   K_j^{\mathrm{val}}(t,u)
   \right|\,du,
   \qquad q\in\{0,1\}.
   $$

   The density is inside $K_j^{\mathrm{val}}$.  Diagonal divided
   differences, logarithmic subtraction, and all source-rule remainders are
   enclosed before the physical row is formed.  The current $p=4$ source
   theorem is sufficient; a conservative producer may request density
   derivatives through order $p+1$.
2. **Regular-image row.**  A first target derivative of a value action uses
   coordinate derivatives of the regular kernel through total order two.
   Every retained Ewald term and M-R/M-I/M-T/M-L tail remains enclosed, with
   outgoing branch and non-Wood gates unchanged.
3. **Off-surface row.**  Differentiate the finite frozen Rayleigh action once
   in the target arclength direction and enclose its finite evaluation and
   off-surface remainder.
4. **Identity row.**  Apply the value identity once, including its exact
   first arclength derivative through the frozen density row.

These component balls are combined according to (RI-4).  A sampled maximum
of $A'$ or agreement between two panel partitions is not an admissible
certificate.

For the current adapter, the panel derivative ball in (RI-6) is specialized
to

$$
d_j=0,
\qquad
r'_j\ge\sup_{s\in[s_j,s_{j+1}]}
\|A'(s)\|_{\mathrm{op}}.
\tag{RI-20}
$$

Thus $L_j=r'_j$ and $\eta_j=\|b_j\|_{\mathrm{op}}+r'_j$.  The right-hand side
of (RI-20) is a complete exact-action analytic upper assembled from all four
owners in (RI-4); it is not a derivative center, a sampled maximum, or an
$N$-selection quantity.

## Fail-closed gates

The evaluator passes only if:

1. the broken energy-square-summable Hilbert direct sum in (ME-1) is the
   governing space, every material and artificial-wall collar is pairwise
   disjoint from every other selected collar, and every collar comparison
   function has zero trace on its outer rim;
2. all chart, speed, chord--arc, reach, curvature, clearance, and collar
   hypotheses pass;
3. the selected $N$ satisfies $N>2M_\eta$, the arclength partition covers the
   interface exactly, all $h_j$ are
   positive, and the periodic seam center is reused;
4. all complete signed endpoint and derivative-panel balls in (RI-6) pass,
   including local diagonal cancellation, regular-image order-two Ewald
   derivatives and off-surface first derivatives;
5. every reused module is bound automatically to the current frozen artifact,
   curve parametrization and orientation, material parameters, and collar
   scientific identity by direct field comparison rather than by a free
   Boolean assertion;
6. all radii are finite and nonnegative, $Q_0,Q_1,H_\Lambda$ are Hermitian
   positive semidefinite enclosures, and every state-map owner occurs once;
7. every Lyapunov or block-power certificate and every unchanged wall
   Rayleigh gate passes;
8. an owner audit confirms that no material Fourier coefficient, material
   $L_0/L_1$, material Fourier tail, material target DFT, or material target
   FFT enters the calculation;
9. the output retains the exact labels
   `CONDITIONAL_IDEAL_MAJORANT_COMPLETE_SF_FP_UNRESOLVED`,
   `$\Delta_{\mathrm{sf}}=\mathrm{UNRESOLVED}$`, and
   `$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$` until those layers receive
   separate enclosures.

The frozen run 04 closes the finite $d_j=0$ certificate and therefore yields
a conditional ideal majorant, but it fails the tightness objective.  The
next bounded obligation is to replace $d_j=0$ by a nonzero signed derivative
center and complete panel balls without changing the selected-$N$ owner
ledger.  This is not a material high-Fourier derivative or tail certificate,
and increasing $N$ alone does not address the dominant radius.
