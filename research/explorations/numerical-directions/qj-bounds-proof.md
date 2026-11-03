# Truncation-reliable bounds for the Goerisch quantities $q$ and $J$

**Proof and implementable certificate for the supplied problem.**  
**Date:** 2026-11-03.  
**Status:** The algebraic enclosure and the integration certificates below are proved. The numerical tolerances and runtime for the particular run have not been certified, because its mesh nodes, field and flux coefficients, interface subdivision counts, and geometric margins were not supplied.

All mathematics in this document uses exact real arithmetic. Floating-point rounding is excluded, as requested. The spectral isolation assumption (H) and Proposition 1 of the problem statement are premises. Neither is reproved here.

## 1. Summary of results and their limits

The requested reduction can be completed, subject to explicit geometric and conformity certificates. In particular:

1. For any fixed real $s>0$, exact normalization gives
   $$
   J=\frac{S(s)}M+\frac2s-\frac q{s^2},\qquad
   \delta:=qJ-1
   =\frac{qS(s)}M-\frac{(q-s)^2}{s^2}\ge0.
   $$
   Thus $qS(s)/M$ is an upper bound, not generally the exact value of $\delta$. Both the trial field and its flux are normalized conceptually by the same factor $M^{-1/2}$; no numerical normalization is necessary.

2. The sign conditions (C) are exactly equivalent to
   $$
   \mu<q<\nu,\qquad
   \mu\nu\delta<(q-\mu)(\nu-q).
   $$
   Endpoint monotonicity in $\delta$ holds in this region. Monotonicity in $q$ does **not** hold throughout it. Section 2 gives the precise region and a counterexample.

3. The recommended final certificate works directly with the four corners of
   $$
   [E_-,E_+]\times[M_-,M_+]
   $$
   and one upper bound $S_+$. It retains the dependence between energy, mass, normalization, and residual. Its sign tests are affine functions of $E,M$, and its endpoint extrema require only four evaluations. The theorem and complete proof are in Section 6.

4. For all smooth element integrands, an explicit polynomial approximation with a uniform error gives a rigorous quadrature bound. The construction uses polynomial arithmetic, sine/cosine Taylor remainders, and geometric-series bounds for reciprocals. No unexplained analyticity radius or unknown derivative constant appears. Most affine, untapered elements are exactly integrated by a $5\times5$ Duffy rule.

5. The existing native-field/fitted-flux construction can be retained. Boxes that cross native element edges must receive a bound covering every possible native branch. An adaptive procedure is proved to terminate for any positive absolute integration tolerance under the stated geometric certificates. A cheap additional mass-correction estimate is given in Section 5.3. These results do **not** by themselves establish a small runtime multiplier.

6. Transporting the field to the fitted mesh removes the internal branch changes, but the taper must be retained. Admissibility of this change is proved; negligible enlargement of the spectral interval is **conditional on an explicit perturbation or recomputed-width test**.

7. Genuine polynomial normal-flux jumps can be repaired by explicit local $RT_3$ lifts. The resulting residual inflation has a computable upper bound. A small sampled trace discrepancy alone does not justify treating the original flux as admissible.

8. **The written mass-correction convention has a sign inconsistency.** For the displayed counterclockwise parameterizations and
   $P(u,w)=\Pi_2c(u)+w(c(u)-\Pi_2c(u))$, the standard determinant
   $\det(P_u,P_w)$ integrates “native region minus true region.” The correction to the native mass therefore has a **minus** sign. This identifies an inconsistency in the supplied formulas, not a verified implementation bug: the actual code might reverse arc orientation or determinant columns.

There is no valid proof, from the reported order-16/order-24 agreement alone, of the requested numerical accuracy. The finite certificates below replace that empirical check.

### 1.1 Notation and model used in the proof

Write
$$
B=\mathbb R\times(-1/2,1/2),\qquad
D=(-13.5,13.5)\times(-1/2,1/2),\qquad
\alpha=e^{i\beta_0},\quad \beta_0=0.5.
$$
The space $V=H^1_{\beta_0}(B)$ has top/bottom trace relation
$v(x,1/2)=\alpha v(x,-1/2)$. The material coefficient is the **true** coefficient $\rho$, with $1\le\rho\le17$. We use
$$
a(u,w)=\int_B\nabla u\cdot\overline{\nabla w},\quad
b(u,w)=\int_B\rho u\overline w,\quad a_1=a+b.
$$
All complex inner products are linear in their first argument. For a nonzero compactly supported trial field $v\in V$, let
$$
E=\int_D|\nabla v|^2,\qquad
M=\int_D\rho|v|^2>0,\qquad q=1+E/M.
$$
For an admissible flux $p$, put
$$
S(s)=\int_D\left|p-\frac{\nabla v}{s}\right|^2+
\int_D\frac{|\operatorname{div}p+\rho(1-1/s)v|^2}{\rho}.
$$
The parameter $s$ is selected once and held fixed during certification.

The spectral numbers are
$$
\mu=\alpha_-+1=2.7424,\qquad
\nu=\alpha_++1=6.6169.
$$
The enclosure below concerns the eigenvalue $\lambda$, with the shift $\gamma=1$ already subtracted. We reserve $E$ for the unnormalized energy and write $F_t$ for the spectral endpoint, avoiding the two uses of $E$ in the problem statement.

The reference triangle is
$$
\widehat K=\{(\xi,\eta):\xi,\eta\ge0,\ \xi+\eta\le1\},\qquad
|\widehat K|=1/2.
$$
The native quadratic map is $F_K$; the fitted map is $\widetilde F_K$. The field coefficients are $\widehat u_K\in P_3(\widehat K)$. The flux coefficients are
$$
\widehat p_K\in RT_3(\widehat K)
=P_3(\widehat K)^2+\widehat xP_3(\widehat K).
$$
Here $P_j$ means polynomials of total degree at most $j$. In particular, an $RT_3$ vector has degree at most four, its divergence has degree at most three, and its normal flux density on a reference edge has degree at most three.

## 2. Algebraic reduction

### Lemma 2.1. Exact normalization and nonnegative defect

**Hypotheses.** Let $v\in V$, $\operatorname{supp}v\subset\overline D$, $M>0$, and assume the exact flux identity
$$
\int_Dp\cdot\overline{\nabla\varphi}
+\operatorname{div}p\,\overline\varphi=0
\qquad(\varphi\in V).
\tag{2.1}
$$
All displayed integrals are finite. Define the product-space inner product
$$
\langle(p,r),(p',r')\rangle_X
=\int_Dp\cdot\overline{p'}+\int_D\rho r\overline{r'},
$$
and
$$
Tv=(\nabla v,v),\qquad
w_v=(p,\operatorname{div}p/\rho+v).
$$
Let $J=\|w_v\|_X^2/M$, the $J$ of Proposition 1 after normalization.

Then, for every fixed $s>0$,
$$
J=\frac{S(s)}M+\frac2s-\frac q{s^2},
\tag{2.2}
$$
$$
0\le\delta=qJ-1
=\frac{qS(s)}M-\frac{(q-s)^2}{s^2}
\le\frac{qS(s)}M.
\tag{2.3}
$$

**Proof.** The normalized trial and flux are $v/\sqrt M$ and $p/\sqrt M$. Their product-space vector is $w_v/\sqrt M$. Identity (2.1) gives
$$
\langle w_v,Tv\rangle_X=M,\qquad
\|Tv\|_X^2=E+M=qM.
$$
Expanding the squared norm,
$$
S(s)=\|w_v-Tv/s\|_X^2=MJ-2M/s+qM/s^2,
$$
which proves (2.2). Multiplying by $q$ and completing the square gives (2.3), except for nonnegativity. Cauchy–Schwarz gives
$$
M^2=|\langle w_v,Tv\rangle_X|^2
\le(MJ)(qM),
$$
so $qJ\ge1$. The cross term remains $2M/s$ for complex fields because this inner product equals the real number $M$. ∎

**Consequences.** The present computation of $qS(s)/M$ is conservative when admissibility is exact; it is an equality only when $s=q$. Nothing in this proof requires that $s$ be a reliably rounded or certified approximation to $q$. If $s$ is poorly chosen, the upper bound may simply be large.

If $\delta=0$, equality in Cauchy–Schwarz gives $w_v=Tv/q$. Substitution into (2.1) yields $a_1(v,\varphi)=q\,b(v,\varphi)$. When $\mu<q<\nu$, the enclosure is the singleton $\{q-1\}$; there is no exceptional limiting argument to implement.

### Lemma 2.2. Exact sign region

**Hypotheses.** Let $0<\mu<\nu$, $q>0$, and $\delta\ge0$, and set $J=(1+\delta)/q$. The conditions (C) from Proposition 1 hold if and only if
$$
\boxed{\mu<q<\nu,\qquad
\mu\nu\delta<(q-\mu)(\nu-q).}
\tag{2.4}
$$

**Proof.** Put
$$
D_t=q-t(1+\delta),\quad
R_t=(q-t)^2+t^2\delta,\quad d=\nu-\mu.
$$
Then
$$
\widehat B_2(t)=R_t/q,\qquad
\widehat\kappa(t)=D_t/R_t.
$$
Direct expansion gives
$$
dD_\mu-R_\mu=-dD_\nu-R_\nu
=(q-\mu)(\nu-q)-\mu\nu\delta.
\tag{2.5}
$$
If (C) holds, the positive denominators permit cross multiplication. The right-hand side of (2.5) is positive, hence $(q-\mu)(\nu-q)>0$, giving $\mu<q<\nu$. Conversely, (2.4) gives $R_\mu,R_\nu>0$, and (2.5) proves both strict inequalities in (C). ∎

Throughout (2.4),
$$
D_\mu>0,\qquad D_\nu<0.
\tag{2.6}
$$
Indeed,
$$
\delta<\frac{q-\mu}{\mu}\frac{\nu-q}{\nu}
<\frac{q-\mu}{\mu},
$$
and $D_\nu<0$ follows from $q<\nu$. An identity useful later is
$$
(q-\mu)(\nu-q)-\mu\nu(qJ-1)
=q(\mu+\nu-q-\mu\nu J).
\tag{2.7}
$$

### Lemma 2.3. Endpoint derivatives and the precise monotonicity qualification

Define
$$
F_t(q,\delta)
=\frac{q(q-t)}{q-t(1+\delta)}-1
=q-1+\frac{qt\delta}{q-t-t\delta}.
\tag{2.8}
$$
On (2.4), Proposition 1 gives $\lambda\in[F_\nu,F_\mu]$, and
$$
\partial_\delta F_t=\frac{qt(q-t)}{[q-t(1+\delta)]^2},
\tag{2.9}
$$
$$
\partial_qF_t
=1-\frac{t^2\delta(1+\delta)}{[q-t(1+\delta)]^2},
\qquad
\partial_q^2F_t
=\frac{2t^2\delta(1+\delta)}{[q-t(1+\delta)]^3}.
\tag{2.10}
$$

**Proof.** These follow by differentiating (2.8); the denominators are nonzero by (2.6). ∎

Thus $F_\nu$ decreases with $\delta$ and is concave in $q$; $F_\mu$ increases with $\delta$ and is convex in $q$. On the corresponding branches,
$$
\partial_qF_\mu\ge0
\iff q\ge\mu[1+\delta+\sqrt{\delta(1+\delta)}],
\tag{2.11}
$$
$$
\partial_qF_\nu\ge0
\iff q\le\nu[1+\delta-\sqrt{\delta(1+\delta)}].
\tag{2.12}
$$
These are additional conditions, not consequences of (C). For example,
$$
\mu=1,\quad \nu=6,\quad q=2,\quad\delta=1/2
$$
satisfy (2.4), but $\partial_qF_\mu=-2$. Near the supplied numerical data both inequalities have very large margins.

## 3. Geometry, membership, and flux admissibility

The following certificates address construction facts; they are not consequences of a small numerical residual.

### 3.1 A sufficient global mesh certificate

A **valid mesh** here means a finite conforming partition of $\overline D$, with pairwise disjoint element interiors, matching edge parameterizations up to reversal, and orientation-preserving bi-Lipschitz element maps. Paired horizontal edges must have the same physical $x$-parameterization. The fitted mesh must trace the actual material interfaces, with the correct material label on every element.

**Lemma 3.1.** Suppose the native mesh is valid. Define
$$
\Psi|_{F_K(\widehat K)}=\widetilde F_K\circ F_K^{-1}.
$$
Assume the corrections agree on shared edges, vanish on $\partial D$, and a certified bound satisfies
$$
\eta_{\rm geom}\ge
\max_K\sup_{\widehat K}
\left\|D(\widetilde F_K-F_K)(DF_K)^{-1}\right\|_2,
\qquad \eta_{\rm geom}<1.
\tag{3.1}
$$
Then $\Psi$ is a global bi-Lipschitz bijection of $\overline D$ onto itself, the fitted elements form a valid geometric partition, and
$$
(1-\eta_{\rm geom})|x-y|
\le|\Psi(x)-\Psi(y)|
\le(1+\eta_{\rm geom})|x-y|,
\tag{3.2}
$$
$$
\det D\widetilde F_K
\ge(1-\eta_{\rm geom})^2\det DF_K>0.
\tag{3.3}
$$

**Proof.** Let $g=\Psi-\mathrm{id}$. It is continuous across edges and has piecewise derivative norm bounded by $\eta_{\rm geom}$. Integration along line segments in the convex rectangle, or equivalently the weak derivative characterization followed by the Lipschitz representative, gives
$|g(x)-g(y)|\le\eta_{\rm geom}|x-y|$.
Extend $g=0$ outside $D$. This preserves the bound: a segment from an interior point to an exterior point meets $\partial D$, where $g=0$. For each $z\in\mathbb R^2$, the iteration $x\mapsto z-g(x)$ is a contraction. Its unique fixed point solves $\Psi(x)=z$. Thus the extended map is bijective and fixes the exterior; it maps $D$ onto itself. The distance estimates follow immediately.

Every singular value of $I+Dg$ is at least $1-\eta_{\rm geom}$. Its determinant is positive because $I+\tau Dg$, $0\le\tau\le1$, remains invertible and starts with positive determinant. Since
$D\widetilde F_K=(I+Dg)DF_K$, (3.3) follows. ∎

Identifying the fitted partition with the true material regions additionally uses the exact-arc construction and the verified material labels; it does not follow from a norm bound alone.

The same proof can certify the native mesh. Start with the straight triangulation of the vertices, verify its finite straight-edge topology, and let $B_K$ be its affine Jacobian. A sufficient test is
$$
\max_K\sup_{\widehat K}\|(DF_K-B_K)B_K^{-1}\|_2<1,
\tag{3.4}
$$
with shared corrections zero on the outer boundary. A failed sufficient test does not prove invalidity; a different certificate may be used.

All matrix-norm upper bounds can be replaced by explicit Frobenius-norm bounds. Positive determinant lower bounds and upper matrix bounds can be obtained from the finite polynomial/Taylor procedures in Section 4. Testing determinants only at Gauss points is insufficient.

### 3.2 The fitted correction and its removable coordinate singularity

For an interface edge with endpoints $a,b$ and opposite vertex $c$, define
$$
\Phi(r,t)=\widehat v_c+
r[(1-t)\widehat v_a+t\widehat v_b-\widehat v_c],
\quad 0\le r,t\le1.
$$
Then $|\det D\Phi|=r$. Put
$$
d(t)=c(\theta_j+t\Delta\theta)-\Pi_2c(t),\quad
R=\nabla(\lambda_a+\lambda_b),\quad L=\nabla\lambda_b.
$$
The collapsed physical map and its Jacobian with respect to the original reference coordinates are
$$
G(r,t)=F_K(\Phi(r,t))+r^3d(t),
\tag{3.5}
$$
$$
A(r,t):=D\widetilde F_K(\Phi(r,t))
=DF_K(\Phi(r,t))
+r^2[3d(t)R^T+d'(t)(L-tR)^T].
\tag{3.6}
$$
Indeed, $\nabla t=(L-tR)/r$; multiplying by $r^3$ gives (3.6). The right-hand side extends analytically to $r=0$. The physical area measure is
$$
dx=r\,j(r,t)\,dr\,dt,\qquad j=\det A>0.
\tag{3.7}
$$

In the original reference coordinates the correction is generally only $C^2$ at the opposite vertex: derivatives of order $k\le2$ are bounded by constants times $r^{3-k}$, and extend by zero there. This causes no high-order quadrature problem **when the complete integrand is expressed using (3.6) in collapsed coordinates**. One must not differentiate the singular expression for $t$ repeatedly without first canceling these factors.

The actual supremum in (3.1) has the explicit bound
$$
\max_K\sup_{\widehat K}\left\|D(\widetilde F_K-F_K)(DF_K)^{-1}\right\|_2\le
\max_K
\left(3D_{0,K}|R|+
D_{1,K}\max_{0\le t\le1}|L-tR|\right)
\sup_{\widehat K}\|(DF_K)^{-1}\|_2,
\tag{3.8}
$$
where $D_{0,K}\ge\sup|d|$, $D_{1,K}\ge\sup|d'|$. One may choose the right-hand side as $\eta_{\rm geom}$. Section 5.3 gives inexpensive bounds; subdivision and direct Taylor bounds can sharpen them.

### Lemma 3.2. Membership of the trial field

**Hypotheses.** On either valid mesh, assume all four cubic edge values match in the common edge parameter on internal edges and are related by $\alpha$ on paired top/bottom edges. Let $u_h=\widehat u_K\circ F_K^{-1}$, or its fitted counterpart. Let $\chi\in W^{1,\infty}(D)$ depend only on $x$ and vanish at $x=\pm13.5$. Define $v=\chi u_h$ on $D$, extended by zero in $B\setminus D$.

Then $v\in V$, with support in $\overline D$.

**Proof.** Each local field is $H^1$ because the inverse element map is Lipschitz. Equality of the four edge values means equality of the entire degree-three trace polynomial. Common edge parameterizations therefore give equal physical traces. Elementwise integration by parts shows that interior boundary distributions cancel, so $u_h\in H^1(D)$. Multiplication by $\chi$ preserves this space and gives
$\nabla v=\chi\nabla u_h+\chi'u_he_x$.
The zero vertical trace permits extension by zero without a boundary distribution. The horizontal phase relation is unchanged because $\chi$ depends only on $x$. ∎

For the given taper, on each of the four taper cells,
$$
\phi(x)=\frac{\pi}{2}(|x|-11.5),\quad
\chi(x)=\frac{1+\cos\phi(x)}2,\quad
\chi'(x)=-\frac{\pi}{4}\operatorname{sgn}(x)\sin\phi(x).
\tag{3.9}
$$
Each cell has a fixed sign of $x$ and one analytic formula. The break lines are cell walls. Elsewhere $\chi=1$ in the interior support. Its global $C^1$ regularity is more than is needed for the membership proof.

### Lemma 3.3. Exact Piola constraints imply admissibility

For a fitted element let
$$
p\circ\widetilde F_K
=\frac{D\widetilde F_K\,\widehat p_K}{\det D\widetilde F_K}.
$$
Parameterize a reference edge affinely by $t\in[0,1]$. Define its outward flux density
$$
\zeta_{K,e}(t)=
\widehat L_e\,\widehat p_K(\widehat c_e(t))\cdot\widehat n_{K,e},
\tag{3.10}
$$
where $\widehat L_e$ is the reference edge length. This is a cubic polynomial. For the common physical parameterization $c_e(t)$,
$$
p(c_e(t))\cdot n_{K,e}(t)\,|c_e'(t)|=\zeta_{K,e}(t).
\tag{3.11}
$$

Assume, after all parameter reversals have been made, that
$$
\zeta_{K,e}+\zeta_{L,e}=0
\quad\text{on every interior edge},
\tag{3.12}
$$
$$
\zeta_{K,e}=0
\quad\text{on vertical exterior edges},
\tag{3.13}
$$
$$
\zeta_T+\alpha\zeta_B=0
\quad\text{on paired horizontal edges}.
\tag{3.14}
$$
Then $p\in H(\operatorname{div},D)$, (P1)–(P3) hold, and (2.1) is valid.

**Proof.** Change of variables in the weak integration-by-parts formula gives the Piola identities
$$
\operatorname{div}p\circ\widetilde F_K
=\frac{\widehat{\operatorname{div}}\widehat p_K}
{\det D\widetilde F_K}
\tag{3.15}
$$
and (3.11). The determinant lower bounds give local square integrability. Condition (3.12) cancels all internal boundary distributions, proving the global $H(\operatorname{div})$ assertion. The edge speed is bounded away from zero by the geometric bounds, so the normal trace is $L^2$. Conditions (3.13)–(3.14) give the specified exterior traces. For $\varphi\in V$, the paired horizontal boundary terms cancel because
$$
p_y^T\overline{\varphi^T}-p_y^B\overline{\varphi^B}
=\alpha p_y^B\overline{\alpha\varphi^B}
-p_y^B\overline{\varphi^B}=0.
$$
Summing elementwise integration by parts proves (2.1). ∎

Four exactly matched moments against $1,t,t^2,t^3$ suffice to establish each cubic identity: the difference is then orthogonal to itself and has zero $L^2$ norm. Physical unit-normal values on a curved edge need not themselves be polynomial; **the densities (3.10)–(3.11) are the polynomial objects**.

The reported $8\times10^{-14}$ sample error cannot decide whether (3.12) holds exactly. Shared master edge coefficients with exact phase/reversal operations prove it in the arithmetic model of this problem. Independently stored inconsistent coefficients require a repair or a different theorem.

### 3.3 Explicit optional repair of normal-flux jumps

This is a clearly identified **flux construction change**, used only if exact conformity is not already established.

**Lemma 3.4.** Let $\widehat e$ be the edge opposite vertex $a$, with ordered endpoints $b,c$, and let $\lambda_c$ be the barycentric coordinate of $c$. For $d\in P_3([0,1])$, define
$$
\mathcal L_{\widehat e}d(\widehat x)
=\frac{\widehat x-a}{2|\widehat K|}\,
d(\lambda_c(\widehat x)).
\tag{3.16}
$$
It lies in $RT_3$, has outward flux density $d(t)$ on $\widehat e$, zero normal trace on the other two edges, and
$$
\widehat{\operatorname{div}}\mathcal L_{\widehat e}d
=\frac{2d(\lambda_c)+\lambda_cd'(\lambda_c)}{2|\widehat K|}.
\tag{3.17}
$$

**Proof.** Formula (3.16) is a cubic vector polynomial plus $\widehat x$ times a cubic polynomial. On the two edges through $a$, the vector $\widehat x-a$ is tangent. On the opposite edge its outward normal component equals the altitude, whose product with the edge length is $2|\widehat K|$. Finally,
$(\widehat x-a)\cdot\nabla\lambda_c=\lambda_c$, proving (3.17). ∎

For an interior density jump $j_e=\zeta_K+\zeta_L$, assign correction $-j_e/2$ to both sides in the common parameter. For a horizontal pair, set
$$
j_e=\zeta_T+\alpha\zeta_B,\qquad
d_T=-j_e/2,\quad d_B=-\overline\alpha j_e/2.
\tag{3.18}
$$
On vertical exterior edges assign $d=-\zeta$. Express each correction in its local parameter, sum the lifts on each reference triangle, and Piola-map them to obtain a correction $e_p$. Then $p_*=p+e_p$ satisfies (3.12)–(3.14) exactly; the lifts on different edges do not interfere.

Let $S_{\rm br}$ denote the elementwise residual for the original, possibly broken flux. The correction $e_p$ can itself be broken, so every divergence of $e_p$ in the following formulas is taken **elementwise**; the final $p_*$ is globally admissible. Put
$$
\mathcal L=\sum_K\int_K
\left(|e_p|^2+\frac{|\operatorname{div}e_p|^2}{\rho_K}\right).
$$
The residual vector changes by
$(e_p,\operatorname{div}e_p/\sqrt\rho)$, so
$$
\boxed{S_*(s)\le
\left(\sqrt{S_{{\rm br},+}}+\sqrt{\mathcal L_+}\right)^2}
\tag{3.19}
$$
whenever the two quantities on the right are reliable upper bounds. This is the triangle inequality in the direct sum of the two $L^2$ spaces.

For an entirely explicit bound, let
$$
m_K\le\inf_{\widehat K}\det D\widetilde F_K,\quad m_K>0,
\qquad H_K\ge\sup_{\widehat K}\|D\widetilde F_K\|_2,
$$
and let $\widehat e_K$ be the sum of the reference lifts. Then
$$
\mathcal L_+
=\sum_K\left[
\frac{H_K^2}{m_K}\int_{\widehat K}|\widehat e_K|^2+
\frac1{\rho_Km_K}
\int_{\widehat K}|\widehat{\operatorname{div}}\widehat e_K|^2
\right].
\tag{3.20}
$$
This follows by Piola change of variables. The polynomial integrals are exact finite sums, using
$$
\int_{\widehat K}\xi^i\eta^j\,d\xi\,d\eta
=\frac{i!j!}{(i+j+2)!}.
\tag{3.21}
$$
The identity follows by integrating first in $\eta$ and then using repeated integration by parts for the resulting beta integral.

The algebra in Section 2 is applied **only to the repaired flux** if repair was needed. It is not applied to $S_{\rm br}$ as though the broken flux were admissible.

## 4. Explicit integration certificates

This section supplies the finite procedures used in the element estimates. “Certified interval” below means an inclusion proved by exact arithmetic inequalities, not an instruction to rely on unspecified interval software.

### Lemma 4.1. Positive-rule polynomial certificate

Let $C$ be a rectangle of area $|C|$, and let
$$
Q_Cf=\sum_iw_if(z_i),\qquad w_i\ge0,\qquad \sum_iw_i=|C|.
$$
Suppose a real polynomial $P$ and $\varepsilon\ge0$ satisfy
$$
|f(z)-P(z)|\le\varepsilon\qquad(z\in C).
$$
Then
$$
\left|\int_Cf-
\left(Q_Cf+\int_CP-Q_CP\right)\right|
\le2|C|\varepsilon.
\tag{4.1}
$$
Alternatively,
$$
\left|\int_Cf-\int_CP\right|\le|C|\varepsilon.
\tag{4.2}
$$
The same statements hold on an interval, with length instead of area.

**Proof.** Subtract $P$. The integral of $f-P$ and its positive quadrature sum each have absolute value at most $|C|\varepsilon$. The triangle inequality gives (4.1); the integral bound alone gives (4.2). ∎

If the tensor degree of $P$ is at most $2n-1$ in each coordinate, the $n\times n$ Gauss–Legendre rule integrates $P$ exactly, and the correction in (4.1) vanishes. For larger degrees the explicitly computable correction must be retained. There is no need to restrict a polynomial certificate to the original quadrature order.

For completeness, the positive-weight and exactness facts used here have an elementary proof. Let $\pi_n$ be the monic degree-$n$ polynomial orthogonal to all lower degrees on $[0,1]$; its coefficients are obtained from a positive-definite moment system. It has $n$ distinct interior roots: otherwise the product of its interior sign-changing linear factors would have degree below $n$, and its product with $\pi_n$ would have constant nonzero sign, contradicting orthogonality. Use the roots as nodes and $w_i=\int_0^1\ell_i$, with $\ell_i$ the cardinal polynomials. Division by $\pi_n$ proves exactness through degree $2n-1$. Exactness applied to $\ell_i^2$ gives $w_i=\int\ell_i^2>0$, and exactness applied to $1$ gives $\sum w_i=1$. Scaling and tensor products give the stated rectangle rule.

These standard Gauss properties are also recorded in the checked reference [Q], §3.5(v), equations (3.5.18)–(3.5.20_1). Equations (4.1)–(4.2) are proved above; we do not invoke an external quadrature remainder theorem.

**Point-evaluation error.** If $Q_Cf$ is formed using values $\widetilde f_i$ with certified errors $|f(z_i)-\widetilde f_i|\le e_i$, add $\sum_iw_ie_i$ to the right of (4.1). In particular, stopping Newton inversion at a small empirical residual is not automatically exact evaluation. Lemma 4.3 gives an inversion certificate. Formula (4.2) avoids inverse evaluations at quadrature nodes altogether.

In every application, the collapse factor $r$ or $1-r$ is included in $f$; $Q_C$ itself is the positive tensor rule on the rectangle.

### 4.1 A finite polynomial-error arithmetic

Map a panel to $z_1,z_2\in[-1,1]$. Represent a scalar function by
$$
f=P+e,\quad |e|\le\varepsilon,\qquad
P=\sum_{\alpha}p_\alpha z^\alpha.
$$
Use the explicit coefficient bound
$$
N(P)=\sum_\alpha|p_\alpha|\ge\sup_{[-1,1]^2}|P|.
\tag{4.3}
$$
For complex coefficients one may use
$|p_\alpha|\le|\operatorname{Re}p_\alpha|+|\operatorname{Im}p_\alpha|$, so no nontrivial square-root evaluation is needed for an upper bound. The following rules are all uniform on the panel.

- **Addition:** add polynomials and add errors.
- **Multiplication:** for models $(P,\varepsilon)$, $(Q,\zeta)$, use polynomial $PQ$ and error
  $$
  N(P)\zeta+N(Q)\varepsilon+\varepsilon\zeta.
  \tag{4.4}
  $$
- **Conjugation:** conjugate coefficients and leave the error unchanged.
- **Degree truncation:** deleting a collection of polynomial terms adds the sum of their coefficient moduli to the error.
- **Sine and cosine:** if the true real argument differs from $P$ by at most $\varepsilon$, choose a real center $a$, bound $N(P-a)\le D$, and Taylor-expand sine or cosine about $a$ through order $L$. The polynomial composition has error at most
  $$
  \frac{D^{L+1}}{(L+1)!}+\varepsilon.
  \tag{4.5}
  $$
  The first term is the real Taylor remainder; the second uses the global Lipschitz constant $1$. Any subsequent polynomial truncation is accounted for separately.
- **Reciprocal:** let the real denominator have model $d=P+e$, $|e|\le\varepsilon$. Choose $d_0>0$ and certify
  $$
  N(P-d_0)\le\kappa d_0,\quad 0\le\kappa<1,\qquad
  a=(1-\kappa)d_0-\varepsilon>0.
  $$
  With
  $$
  R_L=\frac1{d_0}\sum_{j=0}^L(1-P/d_0)^j,
  $$
  use the error
  $$
  \left|\frac1d-R_L\right|
  \le
  \frac{\kappa^{L+1}}{d_0(1-\kappa)}
  +\frac{\varepsilon}{a(1-\kappa)d_0}.
  \tag{4.6}
  $$

**Proof of the rules.** Addition and conjugation are immediate. Expand
$(P+e)(Q+f)-PQ$ to obtain (4.4); $|z^\alpha|\le1$ proves the truncation rule. Every real derivative of sine and cosine has modulus at most one, proving (4.5). For (4.6), $P\ge(1-\kappa)d_0$, $d\ge a$, the finite geometric-series tail bounds $|1/P-R_L|$, and
$|1/d-1/P|\le\varepsilon/[a(1-\kappa)d_0]$. ∎

Matrix operations are performed entrywise. Determinants and adjugates are finite polynomial combinations. Thus these rules give computable enclosures for every expression used below. Integral constants are explicit: on a normalized square the integral of a monomial is zero if either exponent is odd and is $4/[(i+1)(j+1)]$ otherwise; include the panel rescaling factor. Triangle moments are given by (3.21).

One may take the elementary constants and evaluations as exact inputs, as allowed in the question. If they are instead approximated by finite series, their remainders become additional input errors in these same rules.

**Termination for smooth expressions.** On a compact panel with every true denominator bounded strictly away from zero, sufficiently fine subdivision permits the reciprocal condition with $\kappa<1$. Sine/cosine Taylor tails and geometric-series tails tend to zero. Retaining sufficiently many polynomial terms therefore gives any prescribed positive uniform error. This proves a finite procedure; it does not assert that one fixed polynomial degree suffices on every mesh.

### Lemma 4.2. Preserve the small residual before squaring

Suppose complex residual components satisfy
$$
R_i=P_i+e_i,\quad |e_i|\le\varepsilon_i,\quad b_i=N(P_i),
$$
and a nonnegative weight satisfies
$$
w=P_w+e_w,\quad |e_w|\le\varepsilon_w,\quad 0\le w\le w^+.
$$
Then $P_f=P_w\sum_i|P_i|^2$ approximates
$f=w\sum_i|R_i|^2$ with
$$
|f-P_f|
\le
w^+\sum_i(2b_i\varepsilon_i+\varepsilon_i^2)
+\varepsilon_w\sum_i b_i^2.
\tag{4.7}
$$
Any coefficient deletion from $P_f$ adds its bound as in Section 4.1.

**Proof.** For each component,
$\big||R_i|^2-|P_i|^2\big| \le2|P_i|\varepsilon_i+\varepsilon_i^2$.
Multiply this by $w$, then bound the difference between $w\sum|P_i|^2$ and $P_w\sum|P_i|^2$. ∎

The residual components, or their common-denominator numerators in Section 5, must be formed **before** taking coefficient bounds. Separately bounding large terms such as $\int|p|^2$, $\int|\nabla v|^2/s^2$, and their cross term generally destroys the accuracy advantage of the small residual.

### Lemma 4.3. Certified native inverse and a polynomial inverse defect bound

Let $C$ be a parameter panel, with known physical map $G:C\to\mathbb R^2$. Let $F$ be one native quadratic map, $y_0\in\mathbb R^2$, and
$$
Y=y_0+[-R,R]^2.
$$
Choose an invertible constant matrix $B_0$. In the vector/matrix infinity norm, certify
$$
\sup_{y\in Y}\|I-B_0DF(y)\|_\infty\le\kappa<1,
\tag{4.8}
$$
$$
\sup_{z\in C}\|B_0(F(y_0)-G(z))\|_\infty
\le(1-\kappa)R.
\tag{4.9}
$$
Then, for every $z\in C$, there is exactly one $y(z)\in Y$ satisfying $F(y(z))=G(z)$.

If a vector polynomial $Y_P(z)$ takes values in $Y$, and
$$
\sup_{z\in C}\|B_0(F(Y_P(z))-G(z))\|_\infty\le\varepsilon_F,
$$
then
$$
\|y(z)-Y_P(z)\|_\infty
\le\frac{\varepsilon_F}{1-\kappa}.
\tag{4.10}
$$

**Proof.** The map
$T_z(y)=y-B_0(F(y)-G(z))$
has Lipschitz constant at most $\kappa$ on the convex cube $Y$. Equation (4.9) makes it a self-map. The contraction iteration yields a unique fixed point; invertibility of $B_0$ identifies it with a root. Also
$$
\|y-Y_P\|_\infty
\le\kappa\|y-Y_P\|_\infty+
\|T_z(Y_P)-Y_P\|_\infty,
$$
which proves (4.10). ∎

All tests in this lemma use polynomial bounds and the known trigonometric map $G$. A numerical inverse or Newton iteration may supply the *guess* $y_0,B_0,Y_P$; (4.8)–(4.10) certify the result independently.

There is also a finite constructive way to obtain $Y_P$. Expand $G$ at the panel center. For a quadratic $F$, matching each new total degree in $F(Y_P)=G$ gives a $2\times2$ linear system with the center Jacobian; all quadratic products involving lower degrees are already known. Solve these systems up to the chosen degree and check the resulting defect by (4.10). Approximate center roots can instead be used directly with the defect test; a formally exact center root is not necessary.

There is an elementary termination argument independent of a formal inverse series. Under (4.8)–(4.9), define exact contraction iterates
$$
Y_0(z)=y_0,\qquad
Y_{k+1}(z)=Y_k(z)-B_0(F(Y_k(z))-G(z)).
$$
They remain in $Y$ and satisfy
$$
\sup_C\|Y_k-y\|_\infty\le\kappa^kR.
$$
Each finite iterate is an elementary expression in $G$ and the quadratic $F$, so Section 4.1 produces a vector polynomial approximation with componentwise error at most $\varepsilon_k$. Its inverse error is at most $\varepsilon_k+\kappa^kR$. Choosing finite $k$ and a finite polynomial order proves arbitrary positive inverse accuracy. A Taylor guess followed by the defect test is usually more efficient.

To certify one physical native branch, the resulting enclosure for $y(C)$ must lie in $\widehat K$. If it straddles an edge, retain all possible branches or subdivide. “Choose the larger minimum barycentric coordinate” without an inclusion proof is not a branch certificate.

## 5. Bounds for $E,M,S$ by element type

### 5.1 Native energy and native material mass

Write, on a native element,
$$
A=DF_K,\quad j=\det A,\quad U=\widehat u_K,\quad
V=\chi(F_{K,x})U,
$$
$$
h=\nabla_{\widehat x}V
=\chi(F_{K,x})\nabla U+
\chi'(F_{K,x})U\,\nabla F_{K,x}.
$$
The exact reference densities are
$$
e_K=\frac{|(\operatorname{adj}A)^Th|^2}{j},
\qquad
m_K^{\rm nat}=\rho_K^{\rm native}|V|^2j.
\tag{5.1}
$$
The energy has no material-interface approximation: it is exactly the energy of the chosen native trial function. The native mass must still be corrected to the true material coefficient.

**Proof of (5.1).** The physical gradient is $A^{-T}h=(\operatorname{adj}A)^Th/j$. Multiply its squared modulus by the Jacobian $j$. The mass follows directly by change of variables. ∎

For a Duffy map $\xi=z,\eta=(1-z)t$, include the factor $1-z$ in each square density. Apply Lemma 4.1 and the arithmetic in Section 4.1 to all nonpolynomial cases.

The exact polynomial cases are:

| Element and integral | Reference polynomial degree | Sufficient tensor Gauss order |
|---|---:|---:|
| Affine geometry, $\chi=1$, energy $E_K$ | $4$ | $3$ |
| Affine geometry, $\chi=1$, native mass $M_K^{\rm nat}$ | $6$ | $4$ |
| Quadratic native geometry, $\chi=1$, native mass | at most $8$ | $5$ |
| Affine geometry, $\chi=1$, full residual $S_K$, common native/fitted element | at most $8$ | $5$ |

To verify the orders, a total-degree-$d$ polynomial becomes a polynomial of degree at most $d+1$ in $z$ and at most $d$ in $t$ after multiplying by the Duffy factor. A Gauss rule exact through degree $2n-1$ therefore suffices when $2n-1\ge d+1$.

For the last row, $\widehat p$ has degree at most four, $\nabla\widehat u$ degree two, and $\widehat{\operatorname{div}}\widehat p$ and $\widehat u$ degree at most three. Constant affine Jacobians do not change these degrees. For curved native energy with no taper, the numerator in (5.1) has degree at most six and the denominator degree at most two. It is generally rational, so polynomial exactness cannot be asserted.

Every taper element uses the analytic formulas (3.9) and the explicit sine/cosine remainder. The exactness rows do not apply there. “Noninterface implies affine” must be checked from the midside nodes; if it fails, use the nonpolynomial certificate rather than this shortcut.

### 5.2 True mass: exact signed homotopy identity

For each positively oriented inclusion boundary, use a global increasing-angle arc parameter and write
$$
q_e(u)=\Pi_2c(u),\quad d_e(u)=c(\theta_e+u\Delta\theta_e)-q_e(u),
$$
$$
P_e(u,w)=q_e(u)+wd_e(u),\qquad
j_e(u,w)=\det(q_e'(u)+wd_e'(u),d_e(u)).
\tag{5.2}
$$
The local notation $q_e$ is only a curve and must not be confused with the scalar Rayleigh quantity $q$.

**Lemma 5.1.** Assume the true and native inclusion boundaries are simple closed curves with the same positive orientation and corresponding arc endpoints. Let $f$ be continuous on a closed rectangle containing both enclosed regions and every swept set. Then
$$
\int_{\Omega_{\rm true}}f-\int_{\Omega_{\rm native}}f
=
-\sum_e\int_0^1\int_0^1 f(P_e(u,w))j_e(u,w)\,dw\,du.
\tag{5.3}
$$
The maps $P_e$ need not be one-to-one, and $j_e$ need not have constant sign.

**Proof.** First suppose $f$ is smooth. Choose a one-form $\omega$ with $d\omega=f\,dx\wedge dy$; for example take
$\omega=(\int_{x_0}^x f(s,y)\,ds)\,dy$
on a containing rectangle. Stokes' theorem on the parameter square gives
$$
\int f(P_e)\det(P_{e,u},P_{e,w})
=\int_{q_e}\omega-\int_{c_e}\omega.
$$
The square boundary travels along $q_e$ forward at $w=0$, and along $c_e$ backward at $w=1$. The other two sides collapse because the endpoints match. Summing arcs and applying the planar Green formula gives the negative of the desired region difference. For continuous $f$, approximate uniformly by smooth functions. The physical areas and $\int|j_e|$ are finite, so the identity passes to the limit. ∎

Apply this with $f=|v|^2$, which is continuous by Lemma 3.2. If $\Delta\rho_e=\rho^{\rm in}_e-1$, the exact mass is
$$
\boxed{
M=M_{\rm nat}
-\sum_e\Delta\rho_e
\int_{[0,1]^2}|v(P_e(u,w))|^2j_e(u,w)\,du\,dw.}
\tag{5.4}
$$

The stated curve orientations can be checked without inference from a drawing. For the trefoil relative to its center,
$\det(c,c')=r(\theta)^2>0$.
For the center curve put
$A=.3+.06\cos5\theta$, $B=.2+.06\cos5\theta$. Then
$$
\det(c,c')
=AB-.03\sin5\theta\cos\theta\sin\theta
\ge .24\cdot .14-.015=.0186>0.
$$
Its polar angle increases once around the origin, so it too has the stated positive orientation.

Consequently, adding the **positive** signed integral with the determinant order in (5.2) is the opposite correction. A plus sign is correct if the code uses the reverse arc orientation or the determinant $\det(P_w,P_u)$. The implementation convention must be checked before reusing the reported mass.

For exact integration of (5.4), use Lemma 4.3 to select native branches and Lemma 4.1 on smooth panels. On unresolved panels use the signed range procedure of Section 5.4. This handles native-branch changes; applying one smooth high-order remainder to the whole square generally does not.

### 5.3 A cheap mass correction using only the known boundary trace

The following estimate can avoid inverse-map evaluation in the sliver altogether. It is an approximation **with an explicit bias bound**, not a claim that this bias always fits the requested tolerance.

Let
$$
f_{0,e}(u)=|v(q_e(u))|^2
=\chi(q_{e,x}(u))^2\,|\widehat u_e(u)|^2,
$$
where $\widehat u_e$ is the shared cubic edge polynomial. Define
$$
C_{0,e}
=-\Delta\rho_e\int_0^1f_{0,e}(u)
\left[\det(q_e',d_e)+\frac12\det(d_e',d_e)\right]du.
\tag{5.5}
$$
This is an analytic one-dimensional integral on each taper branch, built only from known polynomials and the curve formulas.

**Lemma 5.2.** Suppose bounds hold on an arc and every segment $w\mapsto P_e(u,w)$:
$$
|v(q_e(u))|\le V_e,\quad |\nabla v|\le L_e
\ \text{a.e. on the swept segments},
$$
$$
|d_e|\le D_{0,e},\quad |d_e'|\le D_{1,e},\quad
|q_e'|\le Q_{1,e}.
$$
The field must be continuous across every native edge met by these segments. If $C_e$ is the exact correction in (5.4) for this arc, then
$$
\boxed{
|C_e-C_{0,e}|\le B_e:=
\Delta\rho_e\left[
2V_eL_eD_{0,e}^2
\left(\frac{Q_{1,e}}2+\frac{D_{1,e}}3\right)
+
L_e^2D_{0,e}^3
\left(\frac{Q_{1,e}}3+\frac{D_{1,e}}4\right)
\right].}
\tag{5.6}
$$

**Proof.** Piecewise integration along a segment and continuity at each crossing give
$$
|v(P_e(u,w))-v(q_e(u))|\le wL_eD_{0,e}.
$$
The estimate also follows from the Lipschitz representative of the continuous piecewise $W^{1,\infty}$ field. Hence
$$
\big||v(P_e)|^2-|v(q_e)|^2\big|
\le2V_eL_ewD_{0,e}+L_e^2w^2D_{0,e}^2.
$$
Also
$|j_e|\le D_{0,e}(Q_{1,e}+wD_{1,e})$.
Multiply these inequalities, integrate $w$ from zero to one, and then integrate $u$. Integrating $j_e$ itself in $w$ gives (5.5). ∎

For an interval $I\subset[0,1]$, use local bounds on $I$ and multiply the right-hand side of (5.6) by $|I|$, with all primes still denoting differentiation in the original $u$. Summing these improves the certificate. It does **not** eliminate the actual difference $C_e-C_{0,e}$. If the resulting bias budget remains too large, integrate the original sliver integrand with certified branch handling.

Here are finite recipes for every constant:

- $V_e$: bound the known edge expression $\chi(q_{e,x})\widehat u_e$.
- $L_e$: use (5.1)'s gradient formula on every native triangle that could meet the swept segments. The coverage must be certified; using all triangles is a valid, if conservative, fallback.
- $D_{0,e},D_{1,e},Q_{1,e}$: directly bound the polynomial/trigonometric expressions by Section 4.1, optionally subdividing $u$.
- A convenient analytical displacement bound is
  $$
  D_{0,e}\le
  \frac{\Delta\theta_e^3 C_{3,e}}{72\sqrt3},
  \qquad
  C_{3,e}\ge\sup_\theta|c'''(\theta)|.
  \tag{5.7}
  $$
  For $C_{1,e}\ge\sup|c'|$, simple additional bounds are
  $$
  Q_{1,e}\le2\Delta\theta_e C_{1,e},\qquad
  D_{1,e}\le3\Delta\theta_e C_{1,e}.
  \tag{5.8}
  $$

**Proof of (5.7)–(5.8).** The scalar quadratic interpolation remainder at $0,1/2,1$ is bounded by
$\Delta\theta^3C_3|u(u-1/2)(u-1)|/6$.
It follows by subtracting a suitable multiple of this cubic and applying Rolle's theorem three times. Its cubic factor has maximum modulus $1/(12\sqrt3)$. For a vector curve, scalarize along the unit direction of its interpolation error at the point in question, proving the same norm bound.

For (5.8), write the interpolant relative to the middle point:
$$
q_e'(u)=L_0'(u)[c(\theta_e)-c(\theta_e+\Delta\theta_e/2)]
+L_2'(u)[c(\theta_e+\Delta\theta_e)-c(\theta_e+\Delta\theta_e/2)],
$$
where $L_0'=4u-3$, $L_2'=4u-1$, and
$|L_0'|+|L_2'|\le4$.
Each bracket has norm at most $\Delta\theta C_1/2$. Thus $Q_1\le2\Delta\theta C_1$. Add the bound $\Delta\theta C_1$ for the derivative of the exact arc to obtain $D_1\le3\Delta\theta C_1$. ∎

The given curves have particularly simple derivative bounds. Identify $\mathbb R^2$ with $\mathbb C$, remove the lead translation, and write
$$
z_{\rm lead}(\theta)
=R_a\left(e^{i\theta}+\frac a2e^{4i\theta}
+\frac a2e^{-2i\theta}\right),
$$
$$
z_{\rm center}(\theta)
=.25e^{i\theta}+.05e^{-i\theta}
+.03e^{6i\theta}+.03e^{-4i\theta}.
$$
For every integer $k\ge1$, differentiation and the triangle inequality give
$$
C_{k,\rm lead}=R_a\left[1+\frac a2(4^k+2^k)\right],
\qquad
C_{k,\rm center}=.30+.03(6^k+4^k).
\tag{5.9}
$$
For example $C_{3,\rm center}=8.7$.

For one inclusion with equal parameter steps $\Delta\theta$, global bounds $V,L,C_1,C_3$, and $A_3=C_3/(72\sqrt3)$, (5.6)–(5.8) give the fully explicit estimate
$$
\sum_e B_e
\le\Delta\rho\left[
8\pi VL A_3^2C_1\,\Delta\theta^6
+\frac{17\pi}{6}L^2A_3^3C_1\,\Delta\theta^9
\right].
\tag{5.10}
$$
Indeed, the first term per arc is bounded by $4\Delta\rho VL A_3^2C_1\Delta\theta^7$, the second by
$(17/12)\Delta\rho L^2A_3^3C_1\Delta\theta^{10}$, and there are $2\pi/\Delta\theta$ arcs. This gives a potentially useful high-order mass estimate, but its actual magnitude requires the missing $N_\Gamma$ and field constants.

If
$M_{\rm nat}\in[\widehat M_{\rm nat}-\varepsilon_{\rm nat}, \widehat M_{\rm nat}+\varepsilon_{\rm nat}]$
and
$C_{0,e}\in[\widehat C_{0,e}-\varepsilon_{0,e}, \widehat C_{0,e}+\varepsilon_{0,e}]$,
then
$$
M\in
\left[
\widehat M_{\rm nat}+\sum_e\widehat C_{0,e}
-\varepsilon_{\rm nat}-\sum_e(\varepsilon_{0,e}+B_e),
\
\widehat M_{\rm nat}+\sum_e\widehat C_{0,e}
+\varepsilon_{\rm nat}+\sum_e(\varepsilon_{0,e}+B_e)
\right].
\tag{5.11}
$$
All contributions from all 27 cells must be included.

### 5.4 The existing mixed mesh: certified integration across native edges

This route changes the **integration procedure only**. It preserves the original $v,p$.

Integrate $E$ on native charts. For $M$, either use Sections 5.2–5.3 or integrate directly on the fitted charts, where $\rho$ is exact and constant. Integrate $S$ on fitted charts.

On a fitted interface chart let $G,A,j$ be (3.5)–(3.7), and write
$$
P=\widehat p_K\circ\Phi,\qquad
H=(\widehat{\operatorname{div}}\widehat p_K)\circ\Phi.
$$
On a panel certified to belong to native element $L$, let
$Y=F_L^{-1}\circ G$, certified by Lemma 4.3, and evaluate
$$
V=\chi(G_x)\widehat u_L(Y),
$$
$$
g=\chi(G_x)\,DF_L(Y)^{-T}\nabla\widehat u_L(Y)
+\chi'(G_x)\widehat u_L(Y)e_x.
\tag{5.12}
$$
Then the exact square densities are
$$
f_M=rj\rho_K|V|^2,
$$
$$
f_S=\frac rj\left(
\left|AP-\frac jsg\right|^2+
\frac1{\rho_K}
\left|H+\rho_K(1-1/s)Vj\right|^2
\right).
\tag{5.13}
$$
For ordinary Duffy charts replace $r$ by the corresponding collapse factor $1-r$. Formula (5.13) follows by substituting the Piola flux and divergence and multiplying by $rj$.

**Form the two residual numerators in (5.13) before bounding or squaring.** Section 4 then produces smooth-panel certificates.

For panels crossing native edges, use the following explicit algorithm.

1. Subdivide the fitted parameter square into rectangles. Bound each physical image using the known $G$.
2. Use certified inverse enclosures and barycentric inequalities to assign a single native branch wherever possible. Precomputed element bounding boxes may eliminate impossible candidates.
3. On an unassigned panel $C$, retain every native element that could contain a physical point. Produce an enclosure $f\in[\ell_C,u_C]$ valid for all those branches and all points of $C$. Finite global coefficient bounds, determinant lower bounds, and the expressions (5.12)–(5.13) always give such an enclosure. For $S$, taking $\ell_C=0$ is permissible.
4. Add
   $$
   \int_Cf\in |C|[\ell_C,u_C].
   \tag{5.14}
   $$
   Subdivide panels with excessive uncertainty. Smooth panels use (4.1) or (4.2). Continue until the summed errors fit the global budget.

A useful improvement to (5.14) is polynomial subtraction. If a common polynomial $P_C$ satisfies
$$
\ell_C\le f-P_C\le u_C
$$
for every possible branch, use
$$
\int_Cf\in
\int_CP_C+|C|[\ell_C,u_C].
\tag{5.15}
$$
This controls the variation or jump rather than the entire magnitude of $f$. One can obtain it by bounding each branch's polynomial difference from $P_C$, together with its error. It is especially helpful for the continuous mass integrand.

The same range procedure applies to the **signed** sliver density in (5.4); positivity of that integrand is not assumed.

**Theorem 5.3. Finite accuracy for the unchanged construction.** Assume the finite native and fitted meshes satisfy Section 3, with strictly positive Jacobian margins. Never omit an actual branch. Refine candidate image covers and inverse searches so that branches proved impossible are removed and surviving ranges become spatially localized, as specified below. Then the above procedure, with sufficiently fine subdivision and sufficiently accurate smooth-panel certificates, yields $E,M,S$ bounds of arbitrarily small positive absolute widths in finitely many operations.

A fully finite branch-search rule is available. Subdivide the closed reference triangles of candidate native elements and bound their physical images. Exclude a candidate when all its image boxes are separated from the fitted panel image. Refine these image covers along with the fitted panels. Search inverse certificates over dyadic reference centers and radii, using increasingly accurate inverse-Jacobian guesses. At a point strictly inside one native element, all other closed elements have positive distance from it, and the true invertible Jacobian admits a strict contraction certificate in a small neighborhood. These searches therefore eventually discard spurious branches and discover a smooth branch away from native edges. For a residual crossing panel, global bounds suffice until its area is small; for a continuous mass panel, use the localized surviving reference boxes to tighten the value range.

**Proof.** All field and flux branches and the displayed densities are bounded on their compact charts. The native edges form a finite union of curves of physical area zero. On every fitted chart with $r>0$, the map is locally bi-Lipschitz; the preimage of those curves has area zero there. The remaining line $r=0$ also has parameter area zero. Thus the full branch-change set in the square has area zero.

At every point outside this set, the inverse lies strictly inside one native element. Small enough panels admit that branch and a contraction certificate. The native branch is analytic locally, and the elementary approximation rules give arbitrarily small errors. The total area of panels left near the closed branch-change set tends to zero under refinement. Their contributions, bounded by a finite common range times their area, therefore tend to zero. Uniform refinement of the remaining compact pieces, together with their polynomial approximation, gives any prescribed positive absolute tolerance. Since the desired tolerance is positive, some finite refinement and finite approximation order suffice. For the mass sliver integral there is a simpler argument: $|v(P(u,w))|^2j(u,w)$ is continuous on the compact square, since the field traces match. Spatially localized native-branch ranges converge to the same value even at a native edge. Uniform refinement therefore makes the Riemann enclosure width tend to zero. Fixed global per-element bounds may be used as initial safe bounds, but must be tightened locally for this convergence assertion. ∎

The theorem proves eventual accuracy, not spectral convergence of a nonsmooth integrand and not a mesh-independent operation count. A pure range implementation may be far too expensive at the desired tolerance. The exactness shortcuts, common-polynomial subtraction, and template reuse are intended to avoid that fallback on most elements.

### 5.5 Optional inexpensive residual bound from smooth branch extension

Sometimes the original residual can be certified without fully resolving every crossing. This is an **integration alternative**, not a change to the physical field.

Suppose the corresponding native branch admits a certified smooth inverse extension over each entire fitted element. Call the resulting local extension $v_0$; it need not be globally conforming and will not be used in Proposition 1. Compute the residual of this extension with the fitted $p,\rho$ by Section 4, giving $S_0\le S_{0,+}$.

Suppose the actual and extended fields differ only on certified sets of areas at most $A_j$, and on them
$$
|\nabla(v-v_0)|\le G_j,\qquad
|v-v_0|\le U_j,\qquad \rho\le\rho_j^+.
$$
Then, by the triangle inequality for the residual vectors,
$$
S(s)\le
\left(\sqrt{S_{0,+}}+\eta_s\right)^2,
\qquad
\eta_s^2=
\sum_jA_j\left[\frac{G_j^2}{s^2}
+\rho_j^+(1-1/s)^2U_j^2\right].
\tag{5.16}
$$
All quantities can be bounded with the same inverse and polynomial certificates. A crude geometric swept-area upper bound for an arc is
$$
A_e\le\int_{[0,1]^2}|j_e|
\le D_{0,e}(Q_{1,e}+D_{1,e}/2).
\tag{5.17}
$$
Use it for an element mismatch only after certifying that the mismatch lies in the corresponding swept set. It is an upper bound even with overlapping coverage.

Formula (5.16) can be tried before expensive cut refinement. If it exceeds the residual budget, refine the actual crossing integrals. Small displacement alone is not evidence that (5.16) is sharp enough.

### 5.6 Common fitted-mesh trial field: explicit design change

**Design change.** Replace the original field by
$$
\widetilde v|_{\widetilde F_K(\widehat K)}
=\chi(x)\widehat u_K\circ\widetilde F_K^{-1}.
\tag{5.18}
$$
The physical taper is essential; omitting it from the transport formula can destroy zero-extension membership. Lemma 3.2 proves $\widetilde v\in V$. Keep the same admissible flux unless Section 3.3 requires repair.

In the interface coordinates define
$$
U=\widehat u_K\circ\Phi,\quad
Z=\nabla\widehat u_K\circ\Phi,\quad
V=\chi(G_x)U,
$$
$$
h=\chi(G_x)Z+\chi'(G_x)U A^Te_x.
$$
Set
$$
R_1=AP-\frac1s(\operatorname{adj}A)^Th,
\qquad
R_2=H+\rho_K(1-1/s)Vj.
$$
Then the complete integrands are
$$
\boxed{
f_E=\frac rj|(\operatorname{adj}A)^Th|^2,\quad
f_M=rj\rho_K|V|^2,\quad
f_S=\frac rj\left(|R_1|^2+\frac{|R_2|^2}{\rho_K}\right).}
\tag{5.19}
$$
They are real analytic on the closed collapsed square and a neighborhood of it whenever the determinant is positive there and the correct analytic taper branch is used. Thus Section 4 applies without native inverse maps, sliver corrections, or internal branch changes. Formulas (5.19) also supply the explicit constants for all fitted interface elements.

This construction is valid but not automatically as accurate as the old one.

**Lemma 5.4. Quantitative acceptance test for transport.** Let $w=\widetilde v-v$, and define
$$
\varepsilon_0=\|w\|_\rho,\qquad
\varepsilon_1=\|\nabla w\|_{L^2},\qquad
\eta_s=\sqrt{\varepsilon_1^2/s^2+(1-1/s)^2\varepsilon_0^2}.
$$
For the same $p,s$,
$$
|\sqrt{\widetilde M}-\sqrt M|\le\varepsilon_0,\quad
|\sqrt{\widetilde E}-\sqrt E|\le\varepsilon_1,
$$
$$
|\sqrt{\widetilde S(s)}-\sqrt{S(s)}|\le\eta_s.
\tag{5.20}
$$
Furthermore, if $\varepsilon_0<\sqrt M$,
$$
|\widetilde q-q|
\le
\frac{
2\sqrt{qM\delta}\sqrt{\varepsilon_1^2+\varepsilon_0^2}
+\varepsilon_1^2+(q-1)\varepsilon_0^2
}{
(\sqrt M-\varepsilon_0)^2
}.
\tag{5.21}
$$

**Proof.** The first two inequalities are reverse triangle inequalities. The residual changes by
$(-\nabla w/s,\sqrt\rho(1-1/s)w)$, whose norm is $\eta_s$, proving (5.20).

For (5.21), admissibility gives
$$
a_1(v,w)-q\,b(v,w)
=\langle Tv-qw_v,Tw\rangle_X,\qquad
\|Tv-qw_v\|_X^2=qM\delta.
$$
Expand $\widetilde M(\widetilde q-q)$. Its linear term is twice the real part of the displayed form residual; its quadratic term is
$\varepsilon_1^2+(1-q)\varepsilon_0^2$.
Apply Cauchy–Schwarz, use $q\ge1$, and use
$\widetilde M\ge(\sqrt M-\varepsilon_0)^2$. ∎

The perturbation norms can themselves be certified by the overlay method. A simpler practical acceptance test is to compute a complete enclosure from (5.19) and retain the changed construction only if its certified width meets the target.

At the supplied nominal scale $S\approx2.94715\times10^{-10}$, a sufficient condition for at most $1\%$ residual increase is
$$
\eta_s\le(\sqrt{1.01}-1)\sqrt S\approx8.56\times10^{-8}.
\tag{5.22}
$$
This number is only a planning scale. A rigorous relative guarantee uses a certified positive lower bound for $S$ on the right. The same condition for flux repair is
$\mathcal L_+\le(\sqrt{1.01}-1)^2S$, approximately $7.33\times10^{-15}$. If only $0.5\%$ of residual inflation is available, replace $1.01$ by $1.005$.

A map displacement of order $\Delta\theta^3$ does not imply (5.22): differentiation may introduce a scale $1/h$, and crossing native edges also matters. Hence no unconditional “negligible degradation” assertion is made.

## 6. Assembly into the final eigenvalue interval

### 6.1 Assemble the integral bounds first

Choose one trial field: the original native field, or the explicitly changed field (5.18). Use the **same field and the same admissible flux** in every quantity.

For smooth panels, use (4.1) or (4.2); for crossing panels use (5.14) or (5.15). Sum interval endpoints. If the native mass route is used, include every signed material correction and its error, for example (5.11). If a broken flux was repaired, replace its residual upper bound by (3.19), or directly certify the repaired residual.

The result must be
$$
0\le E_-\le E\le E_+,\qquad
0<M_-\le M\le M_+,\qquad
0\le S(s)\le S_+.
\tag{6.1}
$$
It is permissible to clip a negative energy lower bound to zero. A nonpositive $M_-$ is a failed normalization certificate and must be improved. Local nonnegative residual lower bounds may also be computed, although only $S_+$ is needed for spectral inclusion.

### Theorem 6.1. Recommended four-corner certificate

**Hypotheses.** Assume (H), the supplied Proposition 1, the membership and exact admissibility established in Section 3, a fixed $s>0$, and (6.1). Let
$$
\mathcal R=[E_-,E_+]\times[M_-,M_+].
$$
For $t=\mu,\nu$, define the following affine functions:
$$
N_t(e,m)=e+(1-t)m,
\tag{6.2}
$$
$$
D_t(e,m)=
\left(1-\frac{2t}s+\frac{t}{s^2}\right)m
+\frac{t}{s^2}e-tS_+,
\tag{6.3}
$$
$$
H(e,m)=
\left[\mu+\nu-1-\mu\nu\left(\frac2s-\frac1{s^2}\right)\right]m
+\left(\frac{\mu\nu}{s^2}-1\right)e-\mu\nu S_+.
\tag{6.4}
$$
At each of the four corners $c$ of $\mathcal R$, check
$$
\boxed{H(c)>0,\qquad D_\mu(c)>0,\qquad D_\nu(c)<0.}
\tag{6.5}
$$
If all tests pass, then the exact sign conditions (C) hold and
$$
\boxed{
\lambda\in[L,U],\qquad
L=\min_{c\in\operatorname{vert}\mathcal R}\frac{N_\nu(c)}{D_\nu(c)}-1,
\quad
U=\max_{c\in\operatorname{vert}\mathcal R}\frac{N_\mu(c)}{D_\mu(c)}-1.}
\tag{6.6}
$$

**Proof.** An affine function on a rectangle is a convex combination of its corner values. Therefore all inequalities (6.5) hold throughout $\mathcal R$.

At the true $E,M$, define
$$
J_+=S_+/M+2/s-q/s^2\ge J.
$$
Then
$$
H(E,M)/M=\mu+\nu-q-\mu\nu J_+>0.
$$
Consequently, (2.7) gives
$$
(q-\mu)(\nu-q)-\mu\nu\delta
=q(\mu+\nu-q-\mu\nu J)>0.
$$
Since the true $\delta\ge0$, Lemma 2.2 proves (C) and $\mu<q<\nu$.

For a variable $\sigma$, let
$$
D_t(e,m;\sigma)=
\left(1-\frac{2t}s+\frac{t}{s^2}\right)m+
\frac{t}{s^2}e-t\sigma.
$$
At $(E,M,S)$ the exact spectral endpoint is
$$
\frac{N_t(E,M)}{D_t(E,M;S)}-1.
\tag{6.7}
$$
Its denominator has the positive $\mu$ sign and negative $\nu$ sign by (2.6). At $\sigma=S_+$ it has the same signs by (6.5), and is affine in $\sigma$, so no pole occurs between them. Its derivative in $\sigma$ is
$$
\frac{tN_t(E,M)}{D_t(E,M;\sigma)^2}.
$$
Because $N_t(E,M)=M(q-t)$, increasing $S$ to $S_+$ decreases the lower endpoint and increases the upper endpoint.

It remains to bound (6.7) at $\sigma=S_+$ as $e,m$ vary. If $x=\sum_i\theta_ic_i$ is a convex combination of the corners, then, for any affine $N,D$ whose denominator has fixed nonzero sign,
$$
\frac{N(x)}{D(x)}
=\sum_i\frac{\theta_iD(c_i)}{D(x)}
\frac{N(c_i)}{D(c_i)}.
$$
These weights are nonnegative and sum to one. Thus every ratio lies between its corner ratios. Apply this to the two endpoints and use Proposition 1. ∎

This theorem avoids both an independent $q,\delta$ rectangle and an independent $q,S/M$ bound. It also does not require that the fictitious corner values of $\delta$ be nonnegative. Its sign tests are sufficient, not necessary. If they fail because the integral rectangle is too broad, tighten the bounds; failure is not permission to report an enclosure.

For a stable equivalent evaluation at a corner, put
$$
q_c=1+e/m,\qquad
d_c=q_cS_+/m-(q_c-s)^2/s^2.
$$
Then the ratio in (6.6) equals
$$
q_c-1+\frac{q_ctd_c}{q_c-t-td_c}.
\tag{6.8}
$$
The fixed-sign denominator certificate remains necessary. Formula (6.8) is an algebraic identity even at an infeasible corner with $d_c<0$.

### Proposition 6.2. Simple independent-bound alternative

Define
$$
a=1+E_-/M_+,\quad b=1+E_+/M_-,\quad
d_+=bS_+/M_-.
$$
If
$$
\mu<a\le b<\nu,\qquad
\min\{(a-\mu)(\nu-a),(b-\mu)(\nu-b)\}>\mu\nu d_+,
\tag{6.9}
$$
then
$$
\lambda\in
\left[
\min\{F_\nu(a,d_+),F_\nu(b,d_+)\},
\
\max\{F_\mu(a,d_+),F_\mu(b,d_+)\}
\right].
\tag{6.10}
$$

**Proof.** Lemma 2.1 gives $q\in[a,b]$ and $0\le\delta\le d_+$. The function $(q-\mu)(\nu-q)$ is concave, so its minimum on $[a,b]$ occurs at an endpoint. Thus (6.9) places the full rectangle $[a,b]\times[0,d_+]$ in (2.4). Increase $\delta$ to $d_+$, which widens the interval. At that fixed value, the lower endpoint is concave in $q$, and the upper is convex. Their required extrema are therefore at the endpoints of $[a,b]$. ∎

The manager's proposed specific pairing
$$
L=F_\nu(a,d_+),\qquad U=F_\mu(b,d_+)
$$
is valid if, in addition,
$$
a\ge\mu[1+d_++\sqrt{d_+(1+d_+)}],\qquad
b\le\nu[1+d_+-\sqrt{d_+(1+d_+)}].
\tag{6.11}
$$
Equations (2.11)–(2.12) prove this: the first threshold increases with $\delta$, and the second decreases. Without (6.11), use (6.10), not the unqualified pairing.

An optional sharper scalar bound is
$$
d_+^{\rm coupled}
=\max_{q\in[a,b]}
\left\{q\,\frac{S_+}{M_-}-\frac{(q-s)^2}{s^2}\right\}.
\tag{6.12}
$$
The concave quadratic is maximized at the projection of
$s+s^2S_+/(2M_-)$ onto $[a,b]$. The true $\delta$ is bounded above by (6.12). If its computed maximum is negative, the asserted integral bounds and admissibility are inconsistent; this is a failed certificate. Theorem 6.1 generally preserves more of the original dependence and is preferred.

### 6.2 A joint accuracy budget

The following calculations use the **reported rounded scalars as nominal planning data**. They are not a certified numerical enclosure and do not resolve the mass-sign convention:
$$
q_0=3.428728670724867,\quad
M_0=4.7230110180205935,\quad
\delta_0=2.13952\times10^{-10}.
$$
Assuming $s=q_0$ for this planning calculation gives
$$
S_0\approx\delta_0M_0/q_0
=2.94714965916\times10^{-10}.
$$

| Nominal diagnostic | Value |
|---|---:|
| Lower spectral endpoint | $2.4287286692023492$ |
| Upper spectral endpoint | $2.4287286736560851$ |
| Width $W_0$ | $4.45373590086\times10^{-9}$ |
| Allowance $0.01W_0$ | $4.45373590086\times10^{-11}$ |
| $\partial_\delta F_\mu$ | $13.70035367$ |
| $\partial_\delta F_\nu$ | $-7.11616547$ |
| $\partial_qF_\mu,\partial_qF_\nu$ | approximately $1$ |
| Sign cap $(q_0-\mu)(\nu-q_0)/(\mu\nu)$ | $0.120583649$ |

Thus the sign tests have a large nominal margin; accurate integral bounds, rather than spectral sign margins, are the demanding part of this certification.

The suggested tolerances in the problem consume **overlapping** width budgets. A $q$-radius of $2\times10^{-11}$ alone adds approximately $4\times10^{-11}$ to the width. An additional $1\%$ residual inflation adds approximately another $4.45\times10^{-11}$.

For an explicit planning calculation, use equal relative half-width $r$ for $E,M$, and set $S_+=(1+\epsilon_S)S_0$. Taking $E_0=(q_0-1)M_0$ gives
$$
a=1+(q_0-1)\frac{1-r}{1+r},\qquad
b=1+(q_0-1)\frac{1+r}{1-r},
$$
$$
d_+=\delta_0\,\frac b{q_0}\,
\frac{1+\epsilon_S}{1-r}.
\tag{6.13}
$$
Direct evaluation of (6.10) gives:

| Relative half-width $r$ for each of $E,M$ | Relative $S$ upper allowance | Nominal width penalty |
|---:|---:|---:|
| $5\times10^{-12}$ | $1\%$ | about $2.09065\%$ |
| $2\times10^{-12}$ | $0.5\%$ | about $0.93626\%$ |

A practical starting allocation is therefore **$2\times10^{-12}$ relative half-width for $E,M$, and a total $0.5\%$ upper allowance for $S$**. This total residual allowance includes quadrature, any branch-extension overestimate, any flux repair, and any accepted construction change; those contributions cannot each spend it independently.

Using the nominal values, that means approximately
$$
\varepsilon_E\lesssim2.2942\times10^{-11},\quad
\varepsilon_M\lesssim9.4461\times10^{-12},\quad
S_+-S_0\lesssim1.4736\times10^{-12}.
\tag{6.14}
$$
These are starting budgets, not universally sufficient inequalities for every candidate. The definitive test is to assemble the actual certified interval and check
$$
U-L\le1.01W_{\rm baseline},
\tag{6.15}
$$
where the baseline width and candidate being compared are explicitly recorded. One may use the reported width as a design target; doing so does not retroactively certify that old computation.

If a tolerance is specified relative to an unknown exact $S$, a lower bound $S_->0$ can verify it: $S_+-S_-\le\epsilon S_-$ implies $S_+\le(1+\epsilon)S$. The integration machinery supplies such a lower bound when needed.

### 6.3 Cost and a practical order of implementation

The proof supports the following cost reductions and scaling statements.

1. **Use exact polynomial moments first.** On verified affine untapered elements, $5\times5$ quadrature or exact moments suffice for all three quantities. Relative to $16\times16$ sampling, this is $25/256$ as many sample points on that element class. The reduction concerns evaluation count, not a proved wall-clock speedup.

2. **Cache geometry by the three cell templates.** Native/fitted Jacobians, determinant reciprocal models, interface curves, inverse-branch models, and cut partitions depend on geometry. Reuse them across repeated cells. The four taper cells require their corresponding taper formula. Field and flux coefficient combinations still vary by cell; preserve their cancellations before taking bounds.

3. **Try the one-dimensional mass correction (5.5)–(5.6).** If its certified bias fits the mass budget, the sliver inverses are unnecessary. Otherwise certify the exact sliver correction, or use the direct fitted mass integration.

4. **Certify $S$ on smooth panels first.** Try (5.16) for narrow crossing sets if its inverse extension is certified. Spend adaptive cut refinement only where the bound exceeds the budget.

5. **Use the common fitted field only after testing it.** It removes the main branch-handling cost but changes the candidate. Verify the new width by Theorem 6.1 rather than assuming geometric proximity preserves it.

For $N_a$ affine untapered elements, $N_s$ smooth nonpolynomial panels, $N_c$ crossing panels, Gauss order $n$, and retained bivariate degree $m$, a direct implementation has a contribution of the form
$$
O\!\left(N_aC_{\rm poly}
+N_sn^2C_{\rm eval}
+N_sC_{\rm model}(m)
+N_cC_{\rm range}\right).
\tag{6.16}
$$
All constants represent finite-dimensional polynomial/interval operations described above. Dense two-variable polynomial multiplication with coordinate degree $m$ costs $O(m^4)$ by naive convolution, so merely replacing all $4\times10^7$ point evaluations by dense polynomial arithmetic is not a justified fast strategy. Template caching, affine exactness, sparse polynomial representations, and limiting models to nonpolynomial elements matter.

The missing geometric margins, branch-jump magnitudes, and actual interface counts control $N_s,N_c$ and the required degrees. Therefore the statement “a few times the current evaluation cost” is **not proved from the supplied information**. There is a finite-accuracy theorem and a concrete implementation path; the runtime and the target width remain measurable acceptance tests.

## 7. Table of computable quantities

All “target” entries below use the nominal run only as a planning scale.

| Quantity or certificate | Bound used | Finite computation required | Target or expected relevance |
|---|---|---|---|
| Native mesh validity | (3.4), or another verified global mesh certificate | Straight triangulation checks; polynomial Jacobian and matrix-norm bounds on all elements | Must establish a positive margin; no numeric margin supplied |
| Fitted mesh validity | $\eta_{\rm geom}<1$, (3.1)–(3.3) | Explicit correction derivative (3.6), inverse native Jacobian bounds, panel subdivision if needed | Certifies positivity and absence of overlap; Gauss-point positivity is insufficient |
| Curve displacement $D_0$ | (5.7) or sharper local bound | Curve Fourier coefficients (5.9), $\Delta\theta$, polynomial/Taylor evaluations | $O(\Delta\theta^3)$, with an explicit constant |
| Native field conformity | Exact equality of four edge trace coefficients/values in a common parameter | Shared edge data, cell-wall matching, exact top/bottom phase | Must hold structurally, not merely within a numerical tolerance |
| Flux conformity | (3.12)–(3.14) | Four density moments or polynomial coefficients per edge, including cell walls | Exact constraint, or use repair |
| Flux-repair norm $\mathcal L_+$ | (3.20) | Local lifts; exact polynomial moments; certified $m_K,H_K$ | For a full $1\%$ residual allowance, nominal threshold $7.33\times10^{-15}$; smaller for a shared budget |
| Energy $E$ | (5.1), (4.1)/(4.2), exactness table | Native element polynomials, taper formula, reciprocal determinant certificate | Nominal $11.4709$; suggested half-width $\lesssim2.29\times10^{-11}$ |
| Native mass $M_{\rm nat}$ | Exact polynomial rule away from taper; otherwise Section 4 | Native labels, cubic coefficients, determinant and taper models | Must still receive true-interface correction |
| True mass correction | Exact signed (5.4), or (5.5) plus bias (5.6) | Correct orientation; boundary traces; curve formulas; certified branch handling if exact integration is needed | Part of the total mass half-width budget; cannot omit because the sliver is thin |
| True mass $M$ | (5.11), or direct fitted integration with native branches | Sum all native and correction intervals, or all fitted mass panels | Nominal $4.72301$; suggested half-width $\lesssim9.45\times10^{-12}$ |
| Mixed-mesh residual $S$ | (5.13) and cut-panel certificates; optionally (5.16) | Residual numerators, all possible native branches, exact $\rho$, positive geometry weights | Nominal $2.94715\times10^{-10}$; suggested total upper excess $\lesssim1.47\times10^{-12}$ |
| Common-mesh residual after transport | (5.19), optionally (5.20) | Analytic collapsed expressions and recomputed $E,M,S$ | Easier integration; new residual magnitude is unknown until checked |
| $q$ | $1+E_-/M_+\le q\le1+E_+/M_-$ | Two ratios | Nominal radius about $9.71\times10^{-12}$ for the proposed joint budget |
| $\delta$ | (2.3), or the coupled (6.12) | Upper $S$, energy/mass intervals, the fixed $s$ | Nominal $2.13952\times10^{-10}$; never form a difference of large independently bounded terms |
| Sign conditions (C) | Four-corner affine tests (6.5) | Twelve strict scalar sign tests | Large nominal margin; certify anyway |
| Final endpoints $L,U$ | Theorem 6.1 | Four ratios per endpoint with certified denominator signs | Target width $\le1.01$ times the chosen baseline |
| Relative certification quality | Optional $S_-$, (6.15) | Lower integral bounds and actual assembled width | Required before claiming that a relative allowance was achieved |
| Inverse-map evaluation | (4.8)–(4.10) | Contraction bounds and a polynomial or Newton residual defect | Covers finite inversion error; the heuristic branch fallback is not a proof |

## 8. Assumptions and code obligations

### 8.1 Mathematical assumptions

1. The model, coefficient $\rho$, space $V$, and $\gamma=1$ are those in the supplied problem. The coefficient used in mass and residual integrals is the true coefficient.
2. The spectral isolation assumption (H) is valid for the stated $\alpha_-,\alpha_+$. Its certification is outside this task.
3. Proposition 1 is accepted as a premise exactly as supplied. This document does not claim independent verification of its cited book theorem.
4. The trial field is nonzero and has positive true mass. Its support and phase conditions are proved from the discrete conditions below.
5. An admissible flux is used in the final enclosure, either by exact construction or by the explicit repair.
6. All finite computations are interpreted in exact real arithmetic. Every intentionally truncated series, polynomial approximation, numerical inverse, or integration rule has its displayed mathematical error bound. Floating-point rounding is excluded.
7. Strict geometry and sign conditions used by a certificate are actually proved. They are not inferred from node sampling.
8. For optional transport comparisons, the compared fields and perturbation norms are those stated in Lemma 5.4. The same $s$ and flux are used in its residual inequality.

### 8.2 Facts about the discrete construction that the code must satisfy or certify

1. **Native geometry:** the straight vertex mesh has the claimed topology, and its quadratic deformation produces a valid conforming partition of $D$. Midside nodes on shared edges define the same quadratic curve from both sides.
2. **Fitted geometry:** adjacent elements use the same exact interface arc with compatible parameters; other shared edges remain identical. The global deformation and determinant bounds are certified. Fitted element labels reproduce the true material regions.
3. **Outer geometry:** cell walls, the outer vertical boundary, and paired horizontal edges have the exact common parameterizations required by the phase and taper constructions.
4. **Field conformity:** all four cubic trace degrees of freedom on every internal edge agree, including cell walls. Top/bottom traces are related by the exact phase. A construction based on common master data establishes this more directly than a sampled error report.
5. **Flux conformity:** the cubic flux densities, including their orientations and parameter reversals, satisfy all internal, vertical, and horizontal constraints. If only a numerical discrepancy has been measured, explain whether it is evaluation rounding or an actual coefficient mismatch.
6. **Optional flux repair:** every genuine violating edge is included. The repaired residual, or the inflation bound (3.19), is used in place of the original one.
7. **Taper:** every element uses its correct analytic branch; no unpartitioned element crosses a taper break. Both the native and any transported field retain a zero vertical trace.
8. **Affine shortcut:** a noninterface triangle is treated as affine only after verifying that every midside node is exactly the corresponding edge midpoint in this arithmetic model.
9. **Point location:** every possible native branch on a crossing panel is retained. Limiting a sliver point to the two neighboring triangles is permitted only after proving that those triangles cover its swept set.
10. **Inverse evaluation:** any finite solve has a certified inclusion or defect bound. A Newton stopping criterion by itself does not certify element membership or inverse error.
11. **Mass sign:** the implemented determinant and arc orientations agree with (5.4), or the formula is adjusted consistently. This is especially urgent because the written convention has the opposite sign.
12. **Quadrature:** weights are positive for the rule to which Lemma 4.1 is applied; all collapse factors are included in the integrand. Every approximation, including polynomial deletion, is included in its uniform remainder.
13. **Residual cancellation:** residual vectors or numerators are formed before their size is bounded; no unaccounted cancellation assumption is made.
14. **Global sums:** all elements in all 27 cells and all material corrections are included; the exterior term vanishes only because the chosen trial field is actually supported in $\overline D$.
15. **Normalization and fixed $s$:** the same true $M$ normalizes both the field and flux in the theorem. The parameter $s$ used to compute $S(s)$ is recorded and is not silently replaced by an independently bounded $q$.
16. **Final scalar gate:** $M_->0$ and all strict tests (6.5), or the corresponding fully stated alternative, pass before an interval is labeled certified.

The “to be confirmed” construction facts in the supplied problem remain code obligations. The proofs do not assume that a confirmation has already been obtained.

## 9. What is proved, what remains open, and the smallest next steps

### 9.1 Closed mathematical steps

The following are fully proved above:

- Exact normalization and the fixed-$s$ residual identity.
- The exact sign region, endpoint derivatives, and the qualification missing from the proposed $q$-monotonicity argument.
- The four-corner enclosure, including verification of (C) and control of all normalization dependence.
- Trial membership and Piola admissibility under explicit coefficient constraints.
- Global mesh validity under a finite sufficient deformation bound.
- Explicit quadrature certificates and elementary formulas for every approximation constant.
- Arbitrary positive integration accuracy for the unchanged construction, with rigorous treatment of internal branch changes.
- The corrected signed material-mass identity, including crossing or folded homotopies.
- The boundary-trace mass approximation with an explicit bias constant.
- Exact local repair of polynomial normal jumps and the induced residual bound.
- Admissibility and conditional accuracy of the common fitted-mesh design change.

### 9.2 Steps that cannot be closed from the supplied scalar table

1. **The actual numerical integral intervals.** The mesh nodes, $N_\Gamma$, field/flux coefficients, and geometry margins are absent. Therefore no numerical $E_\pm,M_\pm,S_+$, and hence no certified numerical $[L,U]$, can be reported for this run.

2. **The mass-sign implementation.** The written formulas require the negative sign proved in (5.4). The code's actual orientation and determinant order have not been inspected. If it implements the opposite correction, the baseline mass, Rayleigh quotient, and interval must be recomputed before using the old width as evidence.

3. **Exact flux conformity.** A sampled discrepancy of $8\times10^{-14}$ does not reveal whether it is evaluation rounding of exact constraints or a genuine defect. Inspect the edge coefficient construction or perform the explicit repair.

4. **The claimed small runtime multiplier.** The finite termination proof does not provide such a multiplier. It depends on actual mesh margins and crossing residual sizes. The shortcuts in Section 6.3 provide a concrete route to test.

5. **The claim that field transport is harmless.** It needs the perturbation certificate or the directly recomputed interval. The asymptotic geometric displacement order is insufficient.

6. **The exact $1\%$ width target.** It requires the actual final interval and a joint budget. The original separate tolerances cannot all be spent in full simultaneously.

### 9.3 Minimal implementation path

The smallest change to preserve the current physical candidate is:

1. Verify the mass-correction orientation and the exact field/flux constraints.
2. Add a global native/fitted geometry certificate, preferably once per cell template.
3. Replace high-order sampling on affine untapered elements by exact polynomial integration.
4. Add polynomial-plus-remainder certificates on the smooth elements.
5. Try the boundary-trace mass correction and the smooth-extension residual bound; use certified branch subdivision where either exceeds its budget.
6. Assemble $E_\pm,M_\pm,S_+$, apply the four-corner theorem, and record the resulting width and cost.

This path changes integration and certification, and changes the flux only if conformity needs repair. It does not require rebuilding the spectral method, changing the candidate, certifying the DtN construction, or analyzing the spectral gap again.

If the crossing treatment is too expensive, the smallest trial-field change is (5.18), with the taper retained. Its membership and smooth integration are established, but acceptance remains conditional on the recomputed interval. The available evidence does not justify guaranteeing in advance that this change reaches the target.

## 10. References and source status

**[P] Supplied problem statement.** *Problem statement: truncation-reliable bounds for the Goerisch quantities $q,J$*, 2026-11-03, attached as **qj-bounds-problem.md**. Proposition 1 and assumption (H) are used as premises. The numerical diagnostics in Section 6 are arithmetic illustrations based on its reported scalars.

**[Q] Checked quadrature reference.** F. W. J. Olver, D. W. Lozier, R. F. Boisvert, and C. W. Clark (editors), *NIST Handbook of Mathematical Functions*, Cambridge University Press, 2010; corresponding NIST Digital Library of Mathematical Functions, §3.5(v), **Gauss Quadrature**, equations **(3.5.18)–(3.5.20_1)** for positive weights and polynomial exactness, and **(3.5.19)–(3.5.21)** for the classical derivative remainder and Legendre constant. Checked at [https://dlmf.nist.gov/3.5#v](https://dlmf.nist.gov/3.5#v).

Only the elementary Gauss positivity/exactness properties are used, and they are also proved in Section 4. No external analyticity-based or high-derivative quadrature remainder is assumed. All error inequalities used to certify the integrals are stated and proved in this document.



