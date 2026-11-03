# Computable certification of the isolation hypothesis (H)

**Proof manuscript for h-cert-problem.md.**  
**Model and data:** the problem statement supplied on 2026-11-03.  
**Arithmetic convention:** all finite linear algebra is treated as exact; floating-point rounding is excluded, exactly as requested. Spatial truncation, Fourier tails, Bloch-parameter covering, artificial truncation of the leads, and integration errors are included in the mathematical bounds below.

## 1. Summary and precise status

The four requested ingredients admit explicit finite certificates. The principal new ingredient is a surface-state certificate constructed from the **full periodic resolvent**. Its boundary operator has a positive derivative in the spectral parameter. Consequently, equality of two certified endpoint inertias excludes surface states throughout the window; a mesh of 171 spectral parameters is unnecessary.

There are also useful changes to the final counting calculation:

1. A finite matrix correction can absorb the DtN approximation errors, giving the requested inequalities with $\varepsilon^+=\varepsilon^-=0$. The corrections remain in the matrices; no approximation error is discarded.
2. Adding the exact port Riesz representatives to the core trial space makes every retained port coefficient of its energy-orthogonal complement zero. Thus all corresponding $\delta_{\pm,k}$ vanish exactly.
3. Completing the complement square gives a sharper lower matrix at the upper endpoint, with no free Young parameters and no global stiffness deflation.
4. Only an upper bound $n(t_{\alpha_+})\le1$ is needed for the final isolation argument. The lower bound $n(t_{\alpha_-})\ge0$ is automatic, and the supplied first-order interval already meets the spectrum strictly inside the window.

The status of the conclusions must be distinguished carefully.

| Item | Mathematical result supplied | Numerical status for the stated geometry |
|---|---|---|
| (A) Periodic band gap | Fourier-complement inertia theorem, a proved Bloch modulus, and an explicit integration remainder | A complete finite covering test was executed for both leads. Under the stipulated rounding-excluded convention, it certifies the larger common gap $k\in[1.318,2.375]$, hence the requested window. Reproduction code and all covering endpoints are included in Appendix A. |
| (B) Surface states | Endpoint-only count theorem; computable low boundary block, Fourier tail bounds, and half-lead resolvent bounds | The required four low boundary matrices and their residual Grams have not been computed. The theorem is a finite sufficient certificate, not an assertion that the supplied QZ scans already prove (B). |
| (C) DtN bounds | Explicit quadratic residual bounds, including an all-trace lower matrix with $\varepsilon^-=0$ | Applicable after (B) supplies endpoint half-lead resolvent bounds. Actual extension/flux residual matrices remain to be assembled. |
| (D) Projection constant | A finite formula for the existing curved FE space; also an explicit constant for a proposed spectral space with port enrichment | The alternative space gives $C_h$ analytically. The formula on the existing FE space requires its actual matrices. |
| Final (H) | A sharpened finite inertia implication, proved below | Not yet numerically established: the surface certificate, corrected DtN matrices, and final corrected core inertia remain to be evaluated. |

**A limitation of the surface certificate:** for each material it excludes surface states on *both* sides of a cut in the pure periodic lead. The project only needs the left half for $a=0.12$ and the right half for $a=0.20$. The stronger two-orientation test is sufficient, but it might fail because of a surface state on an unused orientation. The trefoil has no $x$-reflection symmetry, so the two orientations cannot be identified. Section 3 explains exactly what a failure means.

This manuscript does not claim a general real Robin boundary condition with no surface eigenvalues, and it does not use the desired half-lead resolvent to certify its own existence. The dependency order is
$$
\boxed{
\text{periodic gap}
\ \longrightarrow\
\text{full-periodic boundary certificate}
\ \longrightarrow\
\text{half-lead resolvent bounds}
\ \longrightarrow\
\text{DtN matrix bounds}
\ \longrightarrow\
\text{core inertia}.
}
$$

### 1.1 Notation and conventions

The strip is $\mathbb R\times I$ with $I=(-1/2,1/2)$, and the core is
$D=(-1/2,1/2)\times I$. The physical ports are $x_\pm=\pm1/2$.
The material equals $1$ outside the inclusions. The core inclusion has density $4$ and boundary
$$
c_0(t)=0.2\bigl((1.5+0.3\cos5t)\cos t,\,
(1+0.3\cos5t)\sin t\bigr).
$$
A lead inclusion centered in each period cell has density $17$ and boundary
$$
c_a(t)=R_a(1+a\cos3t)(\cos t,\sin t),
\qquad R_a=\frac{0.2}{\sqrt{1+a^2/2}}.
$$
Use $a=0.12$ on the physical left and $a=0.20$ on the physical right.
The pure periodic lead for each $a$ repeats that inclusion with its original orientation in every cell. The self-adjoint operator in the weighted space is $A=-\rho^{-1}\Delta$, with the prescribed transverse quasi-periodicity. The target value is approximately $\lambda_*=2.4287286700$; the independent spectral-intersection interval about this value is used only as the premise stated below.


Set
$$
\alpha_-=1.7424,\qquad \alpha_+=5.6169,\qquad
\mathcal W=[\alpha_-,\alpha_+],
$$
$$
\beta_k=0.5+2\pi k,\qquad q_k=(1+\beta_k^2)^{1/2}.
$$
The trace norm is
$$
\|g\|_{\mathcal T}^2=\sum_{k\in\mathbb Z}q_k|g_k|^2.
$$
Forms are linear in their first argument. A matrix representing a form has entries $H_{ij}=h(\varphi_j,\varphi_i)$, so its quadratic form is $c^*Hc$. All matrix order inequalities are Hermitian Loewner inequalities. The notation $n(H)$ counts strictly negative eigenvalues, with multiplicity.

The given Theorem 1 and the independent spectral-intersection statement for the first-order interval are used as premises. The conditional Lehmann–Goerisch enclosure is not used to prove its own isolation hypothesis.

### 1.2 How integration enclosures enter the formulas

All displayed integral matrices mean exact integrals, or rigorously enclosed versions used in the indicated safe direction. Here is an explicit common rule.

If $H_0$ is Hermitian and $|(H-H_0)_{ij}|\le e_{ij}$, with $e_{ij}=e_{ji}\ge0$, then
$$
\|H-H_0\|_2\le \max_i\sum_j e_{ij}=:\epsilon_H,
\qquad
H_0-\epsilon_HI\preceq H\preceq H_0+\epsilon_HI.
\tag{1.1}
$$
This follows from $\|E\|_2\le\sqrt{\|E\|_1\|E\|_\infty}$.

For inverse matrices, if $\lambda_{\min}(H_0)=\mu>\epsilon_H$, then
$$
\|H^{-1}-H_0^{-1}\|
\le\frac{\epsilon_H}{\mu(\mu-\epsilon_H)}.
\tag{1.2}
$$
If also $\|F-F_0\|\le\epsilon_F$, an explicit bound for
$F^*H^{-1}F-F_0^*H_0^{-1}F_0$ is
$$
\frac{\epsilon_F(2\|F_0\|+\epsilon_F)}{\mu-\epsilon_H}
+\frac{\|F_0\|^2\epsilon_H}{\mu(\mu-\epsilon_H)}.
\tag{1.3}
$$
Expand the difference and use the inverse identity to prove both formulas. These rules, or sharper finite matrix enclosures, cover the projection and residual Gram formulas below. They do not introduce a new infinite-dimensional assumption.

## 2. Item (A): a periodic band certificate without a comparison eigenproblem

This section changes the **certification space** to a small plane-wave space. It does not change the material, the port locations, or the target window.

### 2.1 A finite Fourier/complement inertia theorem

Use the fixed periodic gauge in the longitudinal variable. On a unit cell let
$$
\psi_{m,n}(x,y)=e^{2\pi imx}e^{i\beta_ny},
\qquad
d_{m,n}(\theta)=(2\pi m+\theta)^2+\beta_n^2.
$$
These functions are an orthonormal unweighted $L^2$ basis, and
$$
a_\theta(u,u)=\sum_{m,n}d_{m,n}(\theta)|u_{m,n}|^2.
$$

Let $\mathcal I$ be a finite index set, $P$ its $L^2$ projection, and
$$
\Lambda_{\mathcal I}(\theta)
=\inf_{(m,n)\notin\mathcal I}d_{m,n}(\theta).
$$
For $1\le\rho\le R$ define
$$
K_{\mathcal I}(\theta)=\operatorname{diag}_{\mathcal I}d_{m,n}(\theta),
\quad
M_{\mathcal I}=\left(\int\rho\psi_j\overline{\psi_i}\right),
\quad
M_{\mathcal I}^{(2)}=\left(\int\rho^2\psi_j\overline{\psi_i}\right),
$$
$$
G_{\mathcal I}=M_{\mathcal I}^{(2)}-M_{\mathcal I}^2,
\qquad
T_{\mathcal I}(\lambda,\theta)=K_{\mathcal I}(\theta)-\lambda M_{\mathcal I}.
$$
The matrix $G_{\mathcal I}$ is positive semidefinite: it is the Gram matrix of $(I-P)(\rho\psi_j)$.

**Theorem A.1.** Suppose $\lambda\ge0$ and
$$
c_{\mathcal I}:=\Lambda_{\mathcal I}(\theta)-\lambda R>0.
$$
Set
$$
T_{\mathcal I}^-(\lambda,\theta)
=T_{\mathcal I}(\lambda,\theta)
-\frac{\lambda^2}{c_{\mathcal I}}G_{\mathcal I}.
\tag{2.1}
$$
Then
$$
n(T_{\mathcal I})\le n(a_\theta-\lambda b)
\le n(T_{\mathcal I}^-).
\tag{2.2}
$$
If the two finite matrices are nonsingular and have the same negative inertia $j$, then $\lambda$ is not a cell eigenvalue and exactly $j$ cell eigenvalues lie below it.

**Proof.** Write $u=v+w$ with $v=Pu$, $w=(I-P)u$. Both the kinetic form and the unweighted mass have no cross term. On the complement,
$$
(a_\theta-\lambda b)(w,w)\ge c_{\mathcal I}\|w\|_0^2.
$$
The cross term is $-2\lambda\operatorname{Re}\langle(I-P)\rho v,w\rangle_0$. Completing the square gives
$$
(a_\theta-\lambda b)(u,u)
\ge c_v^*T_{\mathcal I}^-c_v
+c_{\mathcal I}
\left\|w-\frac{\lambda(I-P)\rho v}{c_{\mathcal I}}\right\|_0^2.
\tag{2.3}
$$
Restriction to the trial space proves the first inequality in (2.2). For the second, projection of a negative subspace onto the trial space is injective, and (2.3) makes the finite projected form negative on every nonzero projected vector.

The complement form is also coercive in its $H^1$ norm, since it is at least
$(1-\lambda R/\Lambda_{\mathcal I})a_\theta$ there. It has an exact finite Schur complement $S$ satisfying
$$
T_{\mathcal I}^-\preceq S\preceq T_{\mathcal I}.
$$
If both comparison matrices have $j$ negative eigenvalues and no zero, the $j$th eigenvalue of $S$ is negative and its $(j+1)$st is positive. Thus $S$, and then the full form operator, is invertible. The compact-resolvent min-max principle identifies its inertia with the eigenvalue count. The case $j=0$ uses only the positive lower comparison. $\square$

For $\mathcal I=\{|m|\le N_x,\ |n|\le N_y\}$ and $|\theta|\le\pi$,
$$
\Lambda_{\mathcal I}(\theta)
=\min\left\{
[2\pi(N_x+1)-|\theta|]^2+0.25,\,
[2\pi(N_y+1)-0.5]^2+\theta^2
\right\}.
\tag{2.4}
$$
This is the minimum over the two omitted coordinate strips.

For either lead, $\rho=1+16\,1_\Omega$. Put
$$
B_{\mathcal I}=\left(\int_\Omega\psi_j\overline{\psi_i}\right).
$$
Then
$$
M_{\mathcal I}=I+16B_{\mathcal I},\qquad
M_{\mathcal I}^{(2)}=I+288B_{\mathcal I},\qquad
G_{\mathcal I}=256(B_{\mathcal I}-B_{\mathcal I}^2).
\tag{2.5}
$$
Keeping this Gram matrix, rather than replacing it by a scalar contrast bound, is important for the small Fourier-space certificate.

### 2.2 A proved modulus and finite phase panels

**Lemma A.2.** Every ordered cell eigenvalue satisfies
$$
|\sqrt{\lambda_j(\theta)}-\sqrt{\lambda_j(\phi)}|
\le|\theta-\phi|.
\tag{2.6}
$$

**Proof.** The triangle inequality in the shifted-gradient norm gives, for every nonzero periodic-gauge $u$,
$$
\sqrt{\frac{a_\theta(u,u)}{b(u,u)}}
\le
\sqrt{\frac{a_\phi(u,u)}{b(u,u)}}
+|\theta-\phi|\frac{\|u\|_0}{\sqrt{b(u,u)}}
\le
\sqrt{\frac{a_\phi(u,u)}{b(u,u)}}+|\theta-\phi|.
$$
Take the min-max over $j$-dimensional spaces and then interchange $\theta,\phi$. $\square$

Consider a panel centered at $\theta_i$ with radius $r_i$, and choose $k_L>r_i$, $k_U>k_L$. For the present index $j=1$, the following finite tests suffice:
$$
\lambda_{\min}\!\left(
T_{\mathcal I}((k_L-r_i)^2,\theta_i)
\right)<0,
\tag{2.7}
$$
$$
c_{\mathcal I}((k_U+r_i)^2,\theta_i)>0,\qquad
\lambda_2\!\left(
T_{\mathcal I}^-((k_U+r_i)^2,\theta_i)
\right)>0.
\tag{2.8}
$$
The first gives a Ritz upper bound for $\lambda_1(\theta_i)$. The second bounds the number of nonpositive directions at the upper threshold by one; the first already supplies one strictly negative direction there. Thus the upper threshold is not an eigenvalue, and
$\lambda_2(\theta_i)>(k_U+r_i)^2$. Applying (2.6) proves
$$
\lambda_1(\theta)<k_L^2,\qquad
\lambda_2(\theta)>k_U^2
$$
throughout the panel.

This argument certifies the band index itself: it is $j=1$. It does not assume an unverified number of bands below the gap.

The geometry is invariant under $y\mapsto-y$. Reflection in $y$ followed by complex conjugation maps the $(\theta,\beta_0)$ fiber to the $(-\theta,\beta_0)$ fiber and preserves the forms. Hence
$$
\lambda_j(\theta)=\lambda_j(-\theta).
\tag{2.9}
$$
Only $[0,\pi]$ needs to be covered. This argument uses no $x$-reflection symmetry.

### 2.3 Explicit integration remainder for the plane-wave matrices

For a nonzero lattice frequency $\xi=2\pi(d_m,d_n)$, the divergence theorem gives
$$
b_\xi:=\int_\Omega e^{i\xi\cdot x}\,dx
=-\frac{i}{|\xi|^2}
\int_0^{2\pi}e^{i\xi\cdot c(t)}
\bigl(\xi_xc_y'(t)-\xi_yc_x'(t)\bigr)\,dt.
\tag{2.10}
$$
The coefficient at zero is exactly $b_0=0.04\pi$, because
$R_a^2(1+a^2/2)=0.04$.

If a $2\pi$-periodic analytic function has modulus at most $\mathcal M$ on
$|\operatorname{Im}t|\le s$, its $J$-point periodic trapezoid rule has error at most
$$
\frac{4\pi\mathcal M}{e^{sJ}-1}.
\tag{2.11}
$$
Indeed, shift the Fourier coefficient contour to the strip boundaries to obtain
$|\widehat f_n|\le\mathcal M e^{-s|n|}$. The discrete mean retains exactly the Fourier coefficients with indices in $J\mathbb Z$. Sum the nonzero aliased coefficients as a geometric series. This also proves absolute convergence of every step used.

For the trefoil,
$$
c_x=R_a\left[\cos t+\frac a2(\cos4t+\cos2t)\right],
\quad
c_y=R_a\left[\sin t+\frac a2(\sin4t-\sin2t)\right].
$$
On the strip,
$$
|\operatorname{Im}c_i|\le
C_{\rm im}(s):=
R_a\left[\sinh s+\frac a2(\sinh4s+\sinh2s)\right],
$$
$$
|c_i'|\le
C_1(s):=
R_a\left[\cosh s+\frac a2(4\cosh4s+2\cosh2s)\right].
$$
The integrand including the prefactor in (2.10) is consequently bounded by
$$
\mathcal M_\xi
\le
\frac{|\xi_x|+|\xi_y|}{|\xi|^2}
C_1(s)\exp\!\left((|\xi_x|+|\xi_y|)C_{\rm im}(s)\right).
\tag{2.12}
$$

For $N_x=N_y=6$, all differences satisfy $|d_m|,|d_n|\le12$. Take $s=0.1$. The explicit formulas with $a\le0.2$, $R_a\le0.2$ give
$C_{\rm im}<0.033$, $C_1<0.33$ and $\mathcal M_\xi<8$. Here
$(|\xi_x|+|\xi_y|)/|\xi|^2\le1/(2\pi)$ for a nonzero integer lattice frequency. Elementary Taylor bounds for the exponential and hyperbolic functions verify these loose inequalities if their evaluation also needs an explicit finite remainder.

Thus $J=2048$ gives the uniform coefficient error
$$
\epsilon_b=\frac{32\pi}{e^{204.8}-1}<1.15\times10^{-87}.
\tag{2.13}
$$
For $d=169$, let $e_B=d\epsilon_b$. If tildes denote quadrature matrices, then
$$
\|B-\widetilde B\|\le e_B,\quad
\|M-\widetilde M\|\le16e_B,\quad
\|G-\widetilde G\|\le256e_B(3+e_B).
\tag{2.14}
$$
The last inequality follows from $\|B\|\le1$ and $\|\widetilde B\|\le1+e_B$.

In (2.7) test the *upper* matrix
$\widetilde T+16\lambda e_BI$. In (2.8) test the *lower* matrix
$$
\widetilde T^-
-\left[
16\lambda e_B+
\frac{\lambda^2}{c_{\mathcal I}}256e_B(3+e_B)
\right]I.
\tag{2.15}
$$
These directions include every integration truncation error.

### 2.4 Executed finite certificate and periodic resolvent distances

The following independent calculation uses only the stated analytic trefoil geometry, not the unavailable FE mesh.

| Quantity | Value |
|---|---:|
| Common certified gap in $k$ | $[1.318,\,2.375]$ |
| Plane-wave index set | $|m|,|n|\le6$ |
| Matrix dimension per lead | $169$ |
| Curve trapezoid points | $2048$ |
| Accepted common panels on $[0,\pi]$ | $118$ |
| Adaptive midpoint tests used to find them | $235$ |
| Smallest / largest accepted panel width | $\pi/4096$ / $\pi/4$ |
| Minimum lower negative sign margin, both leads | greater than $1.3972\times10^{-4}$ |
| Minimum upper positive sign margin, both leads | greater than $7.5205\times10^{-3}$ |
| Minimum complement denominator on accepted panels | greater than $1572.32$ |
| Maximum shifted upper threshold used | less than $7.66016$ |
| Maximum matrix integration correction in (2.15) | less than $2.87\times10^{-83}$ |

The finite signs were evaluated using ordinary floating-point linear algebra. Under this problem's convention, rounding in those finite operations is excluded. The analytic error (2.13), the infinite Fourier complement, and the entire phase covering are accounted for. For a later rounding-inclusive proof, the same finite signs and matrix inverses must be enclosed in the project's interval arithmetic. The printed decimal margins are summaries; the explicit finite inequalities and the reproduction code are the certificate specification.

The result is
$$
\sup_\theta\lambda_{1,a}(\theta)<1.318^2,
\qquad
\inf_\theta\lambda_{2,a}(\theta)>2.375^2,
\qquad a\in\{0.12,0.20\}.
\tag{2.16}
$$
Consequently we may use the certified distances
$$
d_{\rm per}(\lambda)
=\min\{\lambda-1.318^2,\ 2.375^2-\lambda\},
\qquad \lambda\in\mathcal W,
\tag{2.17}
$$
and, in particular,
$$
d_{\rm per}(\alpha_-)=0.005276,\qquad
d_{\rm per}(\alpha_+)=0.023725,\qquad
d_{\rm per}(\mathcal W)\ge0.005276.
\tag{2.18}
$$
These are distances to the *periodic* spectrum. They are not yet distances to a half-lead spectrum.

### 2.5 Algorithm, size, and cost

Assemble the inclusion Fourier coefficients once per material. Form (2.5), then check (2.7)–(2.8) on all accepted panels, with (2.15). A cover is checked by exact integer endpoint comparisons; Appendix A supplies it. Rechecking the final certificate requires two sign/eigenvalue tests of order $169$ for each of $118$ panels and each of two leads: $472$ small Hermitian tests. Finding the panels adaptively used additional rejected panels.

A uniform grid based only on the sampled lower margin would need roughly $610$ phase points on $[0,\pi]$ before reserving an approximation budget. The adaptive cover concentrates work near $\theta=\pi$. The Fourier-complement method avoids a difficult reference eigenproblem and avoids repeated $29{,}000$-dimensional cell eigenvalue calculations.

## 3. Item (B): surface states from a full-periodic boundary operator

This section has three separate tasks: a count theorem, a finite boundary-operator certificate, and quantitative resolvent bounds needed by (C). All computations preceding the half-lead resolvent formula use only the periodic gap from (A).

### 3.1 Full-periodic resolvent, trace normalization, and layer operators

Fix one of the two materials and translate a cell-wall cut to $x=0$. Continue that material periodically on the entire strip. Do not reflect the inclusion when treating the other orientation. Write
$$
\mathscr H=L^2_\rho(\mathbb R\times I),\qquad
\mathscr V=H^1_{\beta_0}(\mathbb R\times I),
$$
$$
L_\lambda=-\Delta-\lambda\rho,\qquad
\mathscr R_\lambda=(A^{\rm per}-\lambda)^{-1}.
$$
For an unweighted volume source $f$, define
$R_\lambda f=\mathscr R_\lambda(\rho^{-1}f)$. If
$d_\lambda\le\operatorname{dist}(\lambda,\sigma(A^{\rm per}))$, then
$$
\|R_\lambda f\|_\rho\le d_\lambda^{-1}\|f/\sqrt\rho\|_0,
\qquad
|\langle f,R_\lambda f\rangle_0|
\le d_\lambda^{-1}\|f/\sqrt\rho\|_0^2.
\tag{3.1}
$$
The form inverse $\mathscr V^*\to\mathscr V$ also exists. With energy
$a+b_\rho$, its norm is at most $1+(\lambda+1)/d_\lambda$ for $\lambda\ge0$:
the inverse multiplier in the spectral representation is $(t+1)/(t-\lambda)$.

Let $\tau u=u(0,\cdot)$ and let $\mathsf Q=\operatorname{diag}(q_k)$. The full-line trace inequality is
$$
\|\mathsf Q^{1/2}\tau u\|_{\ell^2}^2
\le\frac12\int_{\mathbb R\times I}(|\nabla u|^2+|u|^2).
\tag{3.2}
$$
For each Fourier mode, completing the square separately on the two half-lines gives
$\int_0^\infty(|v'|^2+q_k^2|v|^2)\ge q_k|v(0)|^2$; summing the two sides proves (3.2).
The extension
$\sum_k g_ke^{-q_k|x|}e^{i\beta_ky}$ gives a bounded right inverse of $\tau$.
Thus $\tau$ is onto $\mathcal T$ and $\tau^*$ is injective.

Define
$$
S_\lambda=\tau L_\lambda^{-1}\tau^*:\mathcal T^*\to\mathcal T,
$$
$$
\mathscr B_\lambda
=\mathsf Q^{1/2}S_\lambda\mathsf Q^{1/2}:\ell^2\to\ell^2,
\qquad
\mathscr T_\lambda
=L_\lambda^{-1}\tau^*\mathsf Q^{1/2}:\ell^2\to\mathscr H.
\tag{3.3}
$$
Here $\mathsf Q^{1/2}$ on the source side is the isometry from $\ell^2$ to $\mathcal T^*$. These definitions use the **full-periodic** form inverse and therefore remain meaningful when a half-lead has a Dirichlet eigenvalue.

### 3.2 Kernel equivalence and positive principal part

Let $A_{D,L}$ and $A_{D,R}$ denote the two Dirichlet half-operators formed by this one cut and this one material.

**Lemma B.1.** For $\lambda\notin\sigma(A^{\rm per})$, the map
$c\mapsto\mathscr T_\lambda c$ is an isomorphism
$$
\ker\mathscr B_\lambda
\ \simeq\
\ker(A_{D,L}-\lambda)\oplus\ker(A_{D,R}-\lambda).
\tag{3.4}
$$

**Proof.** If $\mathscr B_\lambda c=0$, the field
$w=\mathscr T_\lambda c$ has zero trace. Its equation has a source supported only on the cut. Testing on either open half-strip gives the homogeneous equation, so its two restrictions are Dirichlet eigenfunctions. If $w=0$, injectivity of $\tau^*$ implies $c=0$.

Conversely, glue a pair of Dirichlet eigenfunctions across their zero traces into $w\in\mathscr V$. The functional $L_\lambda w$ annihilates $\ker\tau$. Because $\tau$ has a bounded right inverse, this functional factors uniquely as $\tau^*f$ for some $f\in\mathcal T^*$. Thus
$w=L_\lambda^{-1}\tau^*f$ and $S_\lambda f=0$. If $f=0$, full-periodic invertibility gives $w=0$. The source normalization gives the claimed isomorphism. This proof does not require a classical normal derivative. $\square$

**Lemma B.2.** For every real $\lambda$ in a periodic gap,
$$
\mathscr B_\lambda=\frac12I+\text{a compact self-adjoint operator}.
\tag{3.5}
$$

**Proof.** Use $L_0=-\Delta+1$, $V_0=1+\lambda\rho$ and
$T_0=L_0^{-1}\tau^*\mathsf Q^{1/2}$. Its $k$th column is
$$
(T_0)_k=\frac1{2\sqrt{q_k}}e^{-q_k|x|}e^{i\beta_ky},
\qquad
\|(T_0)_k\|_0=\frac1{2q_k}.
$$
Consequently $T_0:\ell^2\to L^2$ is compact. Applying the resolvent identity twice yields
$$
\mathscr B_\lambda
=\frac12I+T_0^*V_0T_0+(V_0T_0)^*R_\lambda(V_0T_0).
\tag{3.6}
$$
The additional terms are compact and self-adjoint. $\square$

In particular, $\mathscr B_\lambda$ is Fredholm, has finite-dimensional kernel, and has finite negative inertia.

### 3.3 The endpoint-only surface count

**Theorem B.3.** Let $[a,b]$ lie inside a gap of the full-periodic operator, and suppose $\mathscr B_a,\mathscr B_b$ are invertible. Then
$$
n(\mathscr B_a)-n(\mathscr B_b)
=
\sum_{\lambda\in(a,b)}
\left[
\dim\ker(A_{D,L}-\lambda)+
\dim\ker(A_{D,R}-\lambda)
\right].
\tag{3.7}
$$
The sum is finite. In particular, equality of the endpoint inertias implies
$$
[a,b]\cap\sigma(A_{D,L})
=[a,b]\cap\sigma(A_{D,R})=\varnothing.
\tag{3.8}
$$

**Proof.** Differentiating the full-periodic form resolvent gives
$$
\mathscr B_\lambda'
=\mathscr T_\lambda^{*,\rho}\mathscr T_\lambda,
\qquad
(\mathscr B_\lambda'c,c)=\|\mathscr T_\lambda c\|_\rho^2.
\tag{3.9}
$$
The last quantity is strictly positive for every nonzero $c$, because
$\mathscr T_\lambda$ is injective.

At a zero $\lambda_0$, let $F=\ker\mathscr B_{\lambda_0}$ and decompose
$\ell^2=F\oplus F^\perp$. By (3.5), the complementary block is boundedly invertible at $\lambda_0$ and remains so nearby. The finite-dimensional Schur complement on $F$ is
$$
H(\lambda)=P_F\mathscr B_\lambda P_F
-P_F\mathscr B_\lambda P_{F^\perp}
(P_{F^\perp}\mathscr B_\lambda P_{F^\perp})^{-1}
P_{F^\perp}\mathscr B_\lambda P_F.
$$
At $\lambda_0$ the off-diagonal blocks vanish. Therefore
$$
H(\lambda_0)=0,\qquad
H'(\lambda_0)=P_F\mathscr B_{\lambda_0}'P_F>0.
$$
The finite positive matrix on the right makes $H(\lambda)$ negative definite just below $\lambda_0$ and positive definite just above it. Every zero is isolated, and the negative inertia drops by exactly $\dim F$.

There can be only finitely many zeros on $[a,b]$: an accumulation point would also be a zero by continuity, contradicting its local isolation; the endpoints are invertible. Sum the drops and apply Lemma B.1.

If the difference is zero, there is no kernel anywhere on the interval. The Fredholm property gives invertibility of every $\mathscr B_\lambda$. The explicit resolvent construction in Section 3.7 then proves resolvent membership for the decoupled Dirichlet operator, so the conclusion is absence of spectrum, not just absence of eigenvectors. $\square$

This is a count theorem for the full-periodic single-layer operator. It is not a claim that the problem's DtN count theorem can be continued through its poles without modification.

There is also a uniform inverse bound with no spectral-parameter covering. If the two endpoint inertias equal $m$ and
$$
\operatorname{dist}(0,\sigma(\mathscr B_a))\ge b_a>0,\qquad
\operatorname{dist}(0,\sigma(\mathscr B_b))\ge b_b>0,
$$
then
$$
\|\mathscr B_\lambda^{-1}\|
\le\frac1{\min(b_a,b_b)},\qquad a\le\lambda\le b.
\tag{3.10}
$$
Indeed $\mathscr B_a\preceq\mathscr B_\lambda\preceq\mathscr B_b$.
The first $m$ ordered eigenvalues stay at most $-b_b$, and the remainder of the spectrum stays at least $b_a$, by min-max below the essential spectral point $1/2$. For $m=0$, use $\mathscr B_\lambda\ge\mathscr B_a\ge b_aI$.

### 3.4 Explicit exponential Fourier tails

The simple reference in (3.6) proves compactness. The following reference gives much better quantitative tails.

Let
$$
\mathcal L=\{k:\beta_k^2\le\alpha_+\}=\{0\},
\quad
\kappa_k=
\begin{cases}
q_k,&k\in\mathcal L,\\
\sqrt{\beta_k^2-\lambda},&k\notin\mathcal L.
\end{cases}
$$
Define
$$
L_b=-\partial_x^2+\operatorname{diag}(\kappa_k^2),
\qquad
V_\lambda=L_b-L_\lambda
=\lambda(\rho-1)+(\lambda+1)\Pi_{\mathcal L}.
\tag{3.11}
$$
This is a bounded nonnegative self-adjoint perturbation of the diagonal reference. Set
$$
T=L_b^{-1}\tau^*\mathsf Q^{1/2},
\qquad
T_k(x,y)=\frac{\sqrt{q_k}}{2\kappa_k}
e^{-\kappa_k|x|}e^{i\beta_ky},
\qquad
D_0=\operatorname{diag}\frac{q_k}{2\kappa_k}\succeq\frac12I.
$$
Twice using the resolvent identity gives the exact formula
$$
\mathscr B_\lambda
=D_0+T^*V_\lambda T+(V_\lambda T)^*R_\lambda(V_\lambda T).
\tag{3.12}
$$

Let $\Pi_M$ retain $|k|\le M$, containing $\mathcal L$, and let
$Q_M=I-\Pi_M$. The given trefoils satisfy $\rho=1$ on $|x|<a$ with the rigorous choice $a=1/4$: every radius is below $0.24$, while a cut is $0.5$ from the neighboring centers.

Put
$$
n_k=\frac{\sqrt{q_k}}{2\kappa_k^{3/2}},
\quad
a_M=\max_{|k|>M}n_ke^{-a\kappa_k},
\quad
b_{\rm out}=\max_{|k|\le M}n_ke^{-a\kappa_k},
$$
$$
v_c=16\lambda,\qquad v_w=\frac{16\lambda}{\sqrt{17}},
\qquad
c_P=\|\rho^{-1/2}V_\lambda T\Pi_M\|.
\tag{3.13}
$$
The constant $c_P^2$ is the largest eigenvalue of a finite explicit source Gram. A wholly analytic substitute is
$$
c_P\le v_w b_{\rm out}+(\lambda+1)n_0.
\tag{3.14}
$$

**Lemma B.4.** With $K=\mathscr B_\lambda-D_0$,
$$
\|Q_MKQ_M\|\le h_M:=
\left(v_c+\frac{v_w^2}{d_\lambda}\right)a_M^2,
$$
$$
\|\Pi_MKQ_M\|\le x_M:=
a_M\left(v_cb_{\rm out}+\frac{c_Pv_w}{d_\lambda}\right).
\tag{3.15}
$$

**Proof.** Fourier orthogonality gives
$\|1_{\{|x|\ge a\}}TQ_M\|=a_M$ and the analogous low-space bound $b_{\rm out}$. On a high input the $\Pi_{\mathcal L}$ term vanishes. The direct high block in $T^*V_\lambda T$ is bounded by $v_ca_M^2$, and its low-high block by $v_cb_{\rm out}a_M$.

Also
$\|\rho^{-1/2}V_\lambda TQ_M\|\le v_wa_M$, because
$(\rho-1)/\sqrt\rho$ is zero outside the inclusion and equals $16/\sqrt{17}$ inside. Apply (3.1) to the second term in (3.12), for its high-high and low-high blocks respectively. Add the bounds. The same weighted estimate and the triangle inequality prove (3.14). $\square$

All maxima in these formulas are finite computations. On the high set,
$n_ke^{-a\kappa_k}$ decreases with $|\beta_k|$, since its logarithmic derivative is
$$
\frac{|\beta_k|}{2(1+\beta_k^2)}
-\frac{3|\beta_k|}{2(\beta_k^2-\lambda)}
-\frac{a|\beta_k|}{\sqrt{\beta_k^2-\lambda}}<0.
$$
Thus $a_M$ is evaluated at $k=-(M+1)$.

### 3.5 A finite Schur certificate for boundary inertia and inverse norm

Let
$C=\Pi_M\mathscr B_\lambda\Pi_M$. Suppose finite Hermitian matrices
$\widehat C,E$, with $E\succeq0$, satisfy
$$
\widehat C-E\preceq C\preceq\widehat C+E.
$$
If
$$
t_M:=\frac12-h_M>0,
$$
the high block is at least $t_MI$. Its exact Schur complement $S$ obeys
$$
C_-:=\widehat C-E-\frac{x_M^2}{t_M}I
\preceq S\preceq
C_+:=\widehat C+E.
\tag{3.16}
$$

**Theorem B.5.** If $C_-,C_+$ are nonsingular and have the same negative inertia $m$, then $\mathscr B_\lambda$ is invertible and
$n(\mathscr B_\lambda)=m$.

**Proof.** The Schur correction is positive semidefinite and bounded by
$x_M^2/t_M$. This gives (3.16). Ordered eigenvalues place the first $m$ eigenvalues of $S$ below zero using $C_+$, and the remaining eigenvalues above zero using $C_-$. Block Gaussian elimination is a bounded invertible congruence with the positive high block, proving the assertion. $\square$

For an explicit inverse bound, let
$$
\gamma=\min\left\{
-\lambda_m(C_+)\ \text{if }m>0,\quad
\lambda_{m+1}(C_-)\ \text{if }m<2M+1
\right\}>0,
$$
omitting absent sign classes. Then
$$
\|\mathscr B_\lambda^{-1}\|
\le
\frac{(1+x_M/t_M)^2}{\min(t_M,\gamma)}.
\tag{3.17}
$$
This follows from the same triangular factorization: the inverse triangular factor has norm at most $1+x_M/t_M$.

A simpler sufficient scalar test uses
$e=\|E\|$ and
$$
s_M=\sigma_{\min}(\widehat C)-e-x_M^2/t_M>0.
\tag{3.18}
$$
It gives the inertia of $\widehat C$ and permits $\gamma=s_M$ in (3.17). The matrix-valued test (3.16) is usually sharper.

Only four such endpoint calculations are needed: two materials times two endpoints. Equal endpoint counts for each material give (P) on the entire closed window.

For the certified endpoint distances (2.18), the coarse source bound (3.14), and $a=1/4$, the Schur tail penalties are approximately:

| $M$ | $x_M^2/t_M$ at $\alpha_-$ | $x_M^2/t_M$ at $\alpha_+$ |
|---:|---:|---:|
| 6 | $1.968\times10^{-6}$ | $8.990\times10^{-6}$ |
| 8 | $2.206\times10^{-9}$ | $1.002\times10^{-8}$ |
| 10 | $2.744\times10^{-12}$ | $1.241\times10^{-11}$ |
| 12 | $3.656\times10^{-15}$ | $1.649\times10^{-14}$ |

The displayed values are rounded summaries of the explicit formulas, not substitutes for evaluating them with the chosen arithmetic convention. They show that boundary truncations of order $17$–$21$ are reasonable starting points. The missing issue is the low-block spectral margin and its response residual, not an uncontrolled infinite boundary tail.

### 3.6 A finite low-block computation with no half-lead assumption

Let $p=2M+1$ and $F_i=V_\lambda T_i$ for the retained modes. Choose arbitrary full-strip trial functions $Z_i\in H^2_{\beta_0}$ with compact longitudinal support. A concrete choice is compactly supported $C^2$ cubic B-splines in $x$, multiplied by finitely many transverse Fourier modes.

Define
$$
r_i=F_i-L_\lambda Z_i,\qquad
(G_r)_{ij}=\int\frac{r_j\overline{r_i}}{\rho},
$$
and the Hermitian stationary-action matrix
$$
(J_Z)_{ij}
=\langle F_j,Z_i\rangle_0+\langle Z_j,F_i\rangle_0
-s_\lambda(Z_j,Z_i).
\tag{3.19}
$$
For a coefficient vector $c$, put $F_c=\sum c_iF_i$, $Z_c=\sum c_iZ_i$ and
$u=R_\lambda F_c$. Expanding $s_\lambda(u-Z_c,u-Z_c)$ gives the exact identity
$$
c^*\bigl(F^*R_\lambda F-J_Z\bigr)c
=\langle r_c,R_\lambda r_c\rangle_0.
$$
By (3.1),
$$
-\frac{G_r}{d_\lambda}
\preceq F^*R_\lambda F-J_Z
\preceq\frac{G_r}{d_\lambda}.
\tag{3.20}
$$
Therefore use
$$
\widehat C=D_0|_{\Pi_M}+(T\Pi_M)^*V_\lambda(T\Pi_M)+J_Z,
\qquad E=G_r/d_\lambda,
\tag{3.21}
$$
with integration enclosure errors added as in Section 1.2.

This is a quadratic residual certificate. The response need not solve a finite-box eigenvalue problem accurately in a spectral sense; any conforming trial response with small measured residual suffices.

**Finite construction and convergence.** Minimize
$\|(F_i-L_\lambda Z_i)/\sqrt\rho\|_0^2$ over a common finite compact $H^2$ space. Its normal matrix is positive definite: zero residual on a homogeneous trial difference would give a full-periodic eigenfunction at $\lambda$, excluded by (A). One factorization serves all $p$ sources.

All integrals are finite computable. Outside the compact trial support, $r_i=F_i$. Here
$$
F_i=\left[\lambda(\rho-1)+(\lambda+1)1_{\{i=0\}}\right]T_i.
$$
Products of sources are a periodic cell function times
$e^{-(\kappa_i+\kappa_j)|x|}$. When the support ends at cut-aligned integer locations, the two infinite tails are geometric series of one-cell integrals. The positive and negative tails use their respective cell integrals; no reflection symmetry is assumed. The same observation evaluates $T^*V_\lambda T$ and the source Grams.

Arbitrary residual accuracy is attainable. The operator domain of $A^{\rm per}$ is $H^2_{\beta_0}$: if $u$ belongs to the operator domain, then $-\Delta u=\rho A^{\rm per}u\in L^2$, and the full-strip Fourier characterization gives $H^2$; the converse follows from the boundedness and positivity of $\rho$. Compact-longitudinal smooth functions with finite transverse Fourier sums are dense in $H^2_{\beta_0}$. Approximate each $R_\lambda F_i$ in this graph norm. Its residual tends to zero, and the least-squares minimizer does at least as well. Increasing support and resolution therefore reaches every positive residual tolerance in finitely many stages.

This proves finite attainability, not a small universal support length. The source decay $\kappa_0=q_0\approx1.118$ does not bound the decay length of the periodic response near a band edge.

**Optional Bloch-cell implementation.** The same action can be computed by a Bloch integral, avoiding a long full-strip trial support. For $x\in[0,1]$,
$$
\sum_{n\in\mathbb Z}e^{-in\theta}e^{-\kappa|x+n|}
=
\frac{e^{-\kappa x}}{1-e^{-\kappa-i\theta}}
+\frac{e^{-\kappa(1-x)+i\theta}}{1-e^{-\kappa+i\theta}}.
\tag{3.22}
$$
Multiply by $\sqrt{q_i}/(2\kappa_i)$ and $e^{i\beta_i y}$, apply the periodic $V_\lambda$, and use the gauge $e^{-i\theta x}$ if working in a fixed periodic space. The full-line action $F^*R_\lambda F$ is the normalized integral of the cell resolvent actions over $\theta\in[-\pi,\pi]$.

For arbitrary $H^2$ cell trials, (3.20) applies fiberwise and can be integrated. For $H^1$ FE trials, use an $H(\operatorname{div})$ flux and the form inverse bound $1+(\lambda+1)/d_\lambda$ with the residual Gram of
$$
\left(\nabla Z_i-p_i,\,
\frac{F_i+\lambda\rho Z_i+\operatorname{div}p_i}{\sqrt\rho}\right).
$$
All cell functions and fluxes must carry both prescribed Bloch phases.

There is a finite, albeit potentially expensive, integration fallback. If $F_0,F_1$ bound the fixed-gauge source operator and its $\theta$ derivative from $\mathbb C^p$ to $L^2_{1/\rho}$, then the action derivative has norm at most
$$
L_\theta=
\frac{2F_0F_1}{d_\lambda}
+\frac{2F_0^2}{d_\lambda}
\sqrt{\frac{\lambda}{d_\lambda^2}+\frac1{d_\lambda}}.
\tag{3.23}
$$
To prove this, differentiate the source terms and the shifted kinetic form, use
$\|u\|_\rho\le F_0/d_\lambda$,
$a_\theta(u,u)\le F_0^2(\lambda/d_\lambda^2+1/d_\lambda)$, and
$|\partial_\theta a_\theta(u,u)|\le2\|u\|_0\|(\partial_x+i\theta)u\|_0$.
A normalized $N_\theta$-panel midpoint integral has error at most
$\pi L_\theta/(2N_\theta)$, by integrating the Lipschitz error in each panel. The source formula (3.22) has denominators bounded below by $1-e^{-\kappa}$, so $F_0,F_1$ have explicit geometric-series bounds or can be enclosed by the given integration machinery.

Near the lower edge, this first-order parameter bound may be costly. Higher-order polynomial enclosures for the finite matrix inverse and the explicit source formula can be used instead. A local inverse is certified by a finite Neumann-series residual test. Neither version assumes a half-lead resolvent. The compact $H^2$ construction remains the simplest complete finite-computability proof.

### 3.7 Quantitative half-lead resolvent bounds

Suppose $\mathscr B_\lambda$ has been certified invertible. For $f\in\mathscr H$, let
$u=\mathscr R_\lambda f$ and $z=\mathsf Q^{1/2}\tau u$.
Then
$$
u_D=u-\mathscr T_\lambda\mathscr B_\lambda^{-1}z
$$
has zero trace and solves the two Dirichlet half-problems. The adjoint identity is
$z=\mathscr T_\lambda^{*,\rho}f$. Lemma B.1 gives uniqueness. Thus the decoupled Dirichlet resolvent is
$$
\mathscr R_{D,\lambda}
=\mathscr R_\lambda-
\mathscr T_\lambda\mathscr B_\lambda^{-1}\mathscr T_\lambda^{*,\rho}.
\tag{3.24}
$$
In particular, either half-lead satisfies
$$
\operatorname{dist}(\lambda,\sigma(A_{D,\mathrm{half}}))
\ge d_{\rm half}(\lambda):=
\left[
d_\lambda^{-1}
+\|\mathscr T_\lambda\|^2\|\mathscr B_\lambda^{-1}\|
\right]^{-1}>0.
\tag{3.25}
$$
An upper bound for either norm on the right is sufficient.

One fully analytic estimate is
$$
\|\mathscr T_\lambda\|^2
\le\frac12\left[\frac{\lambda+1}{d_\lambda^2}+\frac1{d_\lambda}\right].
\tag{3.26}
$$
For $\|f\|_\rho=1$, put $u=\mathscr R_\lambda f$. Then
$$
a(u,u)+b_\rho(u,u)
=(\lambda+1)\|u\|_\rho^2+\operatorname{Re}(f,u)_\rho
\le\frac{\lambda+1}{d_\lambda^2}+\frac1{d_\lambda}.
$$
Apply (3.2) and take adjoints.

A much tighter computable estimate reuses the response trials from (3.19). Since
$\mathscr T_\lambda\Pi_M=T\Pi_M+R_\lambda F$, set
$$
U_i=T_i+Z_i,\qquad
a_{\rm low}=
\sqrt{\lambda_{\max}\left(\int\rho U_j\overline{U_i}\right)}
+\frac{\sqrt{\lambda_{\max}(G_r)}}{d_\lambda}.
\tag{3.27}
$$
This bounds $\|\mathscr T_\lambda\Pi_M\|$. For the tail put
$$
b_{\rho,Q}
=\max_{|k|>M}n_k\sqrt{1+16e^{-2a\kappa_k}},
\qquad
a_{\rm high}=b_{\rho,Q}+\frac{v_wa_M}{d_\lambda}.
$$
The first term follows by splitting the unweighted norm and the material contribution outside the collar; the second follows from (3.1). Therefore
$$
\|\mathscr T_\lambda\|^2\le a_{\rm low}^2+a_{\rm high}^2.
\tag{3.28}
$$
The infinite maximum is attained at the smallest omitted $|\beta_k|$, since both factors decrease there. Source tails and the integrals involving $U_i$ are handled as in Section 3.6.

Use the endpoint-specific distances in (2.18). Replacing both by the smaller whole-window distance unnecessarily worsens (C).

### 3.8 Essential spectrum of the Dirichlet half-leads

**Proposition B.6.**
$$
\sigma_{\rm ess}(A_{D,L})
=\sigma_{\rm ess}(A_{D,R})
=\sigma(A^{\rm per}).
\tag{3.29}
$$
Outside this set, half-lead spectral points are isolated eigenvalues of finite multiplicity.

**Proof.** Fix $\lambda\notin\sigma(A^{\rm per})$. By Lemma B.2,
$\mathscr B_\lambda$ has closed range and a bounded Moore–Penrose inverse on its kernel orthogonal complement. Let
$F_D=\ker(A_{D,L}-\lambda)\oplus\ker(A_{D,R}-\lambda)$, which is finite-dimensional by Lemma B.1.

For $f\perp_\rho F_D$, the vector
$\mathscr T_\lambda^{*,\rho}f$ is orthogonal to $\ker\mathscr B_\lambda$. Replace $\mathscr B_\lambda^{-1}$ in (3.24) by that Moore–Penrose inverse. The resulting function has zero trace and solves the Dirichlet equation with source $f$. Project its output onto $F_D^\perp$ if necessary; this preserves its trace, operator domain, and equation. The construction is bounded. Hence the decoupled self-adjoint Dirichlet operator has closed range equal to $F_D^\perp$ and finite kernel. It is Fredholm, proving that $\lambda$ is not in either essential spectrum.

Conversely, a point $\lambda\in\sigma(A^{\rm per})$ has a cell Bloch eigenfunction extended to the whole strip. This follows from the supplied Floquet decomposition; bounded contrast and compact phase space ensure the union at any finite energy is attained. Multiply the extended eigenfunction by
$\chi((x-R^2)/R)$, with a fixed smooth compactly supported nonzero cutoff, and normalize. For large $R$ it is supported away from the cut in the right half-strip. Its unnormalized norm is of order $\sqrt R$. The residual consists of
$-2R^{-1}\chi'\partial_xu-R^{-2}\chi''u$, whose normalized norm is $O(R^{-1})$ by cellwise boundedness of the Bloch mode and its gradient. The normalized functions tend weakly to zero and form a singular Weyl sequence. Negative translates give the left half-strip.

The Bloch functions have local $H^2$ regularity, by the constant principal Laplacian and bounded $\rho$, so these residuals belong to $L^2_\rho$. The self-adjoint Weyl criterion proves the reverse inclusion for both halves. A self-adjoint Fredholm spectral point is an isolated eigenvalue of finite multiplicity, completing the statement. $\square$

### 3.9 Algorithm, cost, and the two-orientation limitation

For each material:

1. Take $d_\lambda$ from (2.17) at $\lambda=\alpha_-,\alpha_+$.
2. Use the cut-aligned material and the certified collar $a=1/4$.
3. Start with $M=8$ or $10$. Construct the $p=2M+1$ sources and compact response trials, or their Bloch-cell equivalents.
4. Enclose $\widehat C,E$, compute $h_M,x_M,t_M$, and test the two finite matrices in (3.16).
5. Refine the response space or increase $M$ until the endpoint inertia and an inverse bound are certified.
6. Compare the two endpoint inertias. Equality gives no surface states throughout the closed window.
7. Compute (3.27)–(3.28), then (3.25), for use by (C).

For compact tensor trials, if there are $N_x$ longitudinal spline unknowns and $2N_y+1$ transverse modes, each of the four cases needs one positive least-squares factorization of order
$N_x(2N_y+1)$ and $p$ backsolves. The final inertia matrices have order only $p$. The number of lead cells needed in $N_x$ depends on the actual response and residual; it cannot be inferred from the source decay or from the QZ stable-subspace singular value.

The Bloch version uses, per material and endpoint, $N_\theta$ cell factorizations and $pN_\theta$ backsolves, plus residual/flux and parameter-integration checks. Existing cell matrices can be reused. The current data do not determine a justified numerical value of $N_\theta$.

If the endpoint inertias differ after successful endpoint enclosures, the difference is the **actual number of surface eigenvalues of the pair of half-leads**, not a discretization warning. Monotone endpoint counting can then bisect and isolate the poles. A smaller window retaining the independent first-order spectral intersection may avoid them. If an unused orientation has an unavoidable pole, an orientation-selective refinement or a different cut is needed; the present sufficient criterion should then be reported as unsuccessful for that window.

The existing $Z_0$ singular values $0.763$ and $0.739$ do not supply a lower bound for $\sigma_{\min}(\mathscr B_\lambda)$, and they inspect only the physical orientations. No such conversion is assumed here.

## 4. Item (C): one-sided DtN bounds with finite matrix corrections

The result applies to either physical half-lead, in an inward coordinate $x\ge0$. Coordinate reversal does not identify the two material orientations. Each half is constructed and integrated separately.

### 4.1 Explicit half-lead form inverse constants

Let
$$
\mathcal V_0=H^1_{\beta_0,0}(\Omega),\qquad
e_\Omega=a_\Omega+b_\Omega,\qquad s_\lambda=a_\Omega-\lambda b_\Omega.
$$
The mass in $e_\Omega$ is weighted by $\rho$. Let $\mathcal B_\lambda$ be the bounded form operator on this energy space:
$$
e_\Omega(\mathcal B_\lambda u,v)=s_\lambda(u,v).
$$
If $\lambda$ belongs to the half-lead resolvent, the unitary form-domain representation identifies $\mathcal B_\lambda$ with the multiplier $(t-\lambda)/(t+1)$.

Let $d_+$ and $d_-$ be certified lower distances to the spectral parts respectively above and below $\lambda$. Then
$$
-K_-I\preceq\mathcal B_\lambda^{-1}\preceq K_+I,
$$
$$
K_+=1+\frac{\lambda+1}{d_+},
\qquad
K_-=\max\left\{0,\frac{\lambda+1}{d_-}-1\right\}.
\tag{4.1}
$$
If there is no spectrum below $\lambda$, take $K_-=0$. The proof is the pointwise bound for $(t+1)/(t-\lambda)$ on the two spectral parts.

Without separate one-sided distances, (3.25) supplies the valid common bound
$$
K_+,K_-\le K_\lambda:=
1+\frac{\lambda+1}{d_{\rm half}(\lambda)}.
\tag{4.2}
$$
The lower DtN bound needs only $K_+$, so replacing it by $K_\lambda$ is safe. A periodic band margin alone is not a valid substitute for $d_{\rm half}$: a surface eigenvalue just outside the window could be closer to the endpoint.

### 4.2 Quadratic residual bounds on any finite trace space

Let $g_1,\ldots,g_m$ be independent traces. Choose compactly supported
$u_i\in H^1_{\beta_0}(\Omega)$ with exact trace $g_i$. Choose compactly supported quasi-periodic fluxes
$p_i\in H(\operatorname{div},\Omega)$, with zero normal flux at their artificial far boundary. No normal condition is imposed at the physical port, because test functions in $\mathcal V_0$ vanish there.

Define
$$
r_{1,i}=\nabla u_i-p_i,\qquad
r_{2,i}=\operatorname{div}p_i+\lambda\rho u_i,
$$
$$
Q_{ij}=s_\lambda(u_j,u_i),\qquad
R_{ij}=\int r_{1,j}\cdot\overline{r_{1,i}}
+\int\frac{r_{2,j}\overline{r_{2,i}}}{\rho}.
\tag{4.3}
$$
The residual Gram $R$ is positive semidefinite.

**Theorem C.1.** For $g_c=\sum_i c_i g_i$,
$$
c^*(Q-K_+R)c
\le\Lambda(\lambda)(g_c,g_c)
\le c^*(Q+K_-R)c.
\tag{4.4}
$$

**Proof.** Let $w=E(\lambda)g_c$ and $z=u_c-w\in\mathcal V_0$. The exact extension is $s_\lambda$-orthogonal to $\mathcal V_0$, so
$$
\Lambda(g_c,g_c)=s_\lambda(u_c,u_c)-s_\lambda(z,z).
$$
Let $f$ be the $e_\Omega$-Riesz vector of the residual functional
$\ell(\varphi)=s_\lambda(u_c,\varphi)$. Then
$\mathcal B_\lambda z=f$ and
$$
s_\lambda(z,z)
=e_\Omega(f,\mathcal B_\lambda^{-1}f).
\tag{4.5}
$$
Integration by parts using $p_c$ gives
$$
\ell(\varphi)
=\int r_{1,c}\cdot\overline{\nabla\varphi}
-\int r_{2,c}\overline\varphi.
$$
Internal fluxes cancel by $H(\operatorname{div})$ conformity. The far flux is zero, and the physical trace of $\varphi$ is zero. Cauchy–Schwarz yields
$\|f\|_{e_\Omega}^2=\|\ell\|_{e_\Omega^*}^2\le c^*Rc$.
Apply (4.1) in (4.5). $\square$

The result is quadratic in the measured residual. A small error is not estimated by subtracting two independent enclosures for large DtN energies.

### 4.3 The requested upper condition (D+)

For the original nodal trace basis, let $D_{\rm raw}$ be the Hermitian raw DtN matrix. Its exact trace Gram is
$$
G_{ij}=\sum_kq_k(g_j)_k\overline{(g_i)_k}.
$$
Compute any positive-definite $G_-\preceq G$. One finite construction is a partial Fourier sum through $|k|\le K$, with its integration error subtracted. Such a partial Gram is eventually positive definite because the trace basis is finite and independent and the Fourier projections converge on it.

The explicit constant
$$
\boxed{
\varepsilon^+
=\max\left\{0,\lambda_{\max}\left(
G_-^{-1/2}[Q+K_-R-D_{\rm raw}]G_-^{-1/2}
\right)\right\}
}
\tag{4.6}
$$
proves (D+). The bracket is at most $\varepsilon^+G_-\preceq\varepsilon^+G$.

Alternatively make the permitted **design change**
$$
\boxed{D_{\rm cert}=Q+K_-R,\qquad \varepsilon^+=0.}
\tag{4.7}
$$
The enlargement remains in the finite matrix. Use upper enclosures of $Q$ and $R$ when applying (4.7). For (4.6), use the corresponding safe enclosure of the bracket and a lower enclosure of $G$.

This supplies the requested lower-endpoint theorem. Section 6 shows why it can be omitted from the most economical final (H) computation.

### 4.4 A high Fourier lift in the homogeneous collar

For the all-trace lower bound, use the exact low trace basis
$g_i=e^{i\beta_i y}$, $|i|\le M$. Write $g=g_L+h$, with $h$ supported in $|k|>M$.

Assume $\rho=1$ on $0<x<b$. For the present half-leads take $b=1/4$. Choose $a,L>0$ with $a+L=b$ and let
$$
\chi(x)=
\begin{cases}
1,&0\le x\le a,\\
1-3t^2+2t^3,\quad t=(x-a)/L,&a<x<a+L,\\
0,&x\ge a+L.
\end{cases}
$$
Then $\chi\in C^1$ is piecewise $C^2$,
$$
|\chi'|\le\frac3{2L},\qquad |\chi''|\le\frac6{L^2}.
$$

Set
$$
\beta_*=\min_{|k|>M}|\beta_k|=2\pi(M+1)-0.5,
\quad
\kappa_k=\sqrt{\beta_k^2-\lambda},
\quad
\kappa_*=\sqrt{\beta_*^2-\lambda},
$$
and require $\beta_*^2>\lambda$. Define
$$
L_Hh=\sum_{|k|>M}h_k\chi(x)e^{-\kappa_kx}e^{i\beta_ky},
\qquad
p_H=\nabla L_Hh.
\tag{4.8}
$$
Its PDE residual is supported on $J=(a,a+L)\times I$:
$$
f_H=(-\Delta-\lambda)L_Hh
=\sum_{|k|>M}h_k(-\chi''+2\kappa_k\chi')
e^{-\kappa_kx}e^{i\beta_ky}.
\tag{4.9}
$$

**Lemma C.2.** The lift is bounded from $\mathcal T$ to $H^1$, has trace $h$, and its gradient belongs to $H(\operatorname{div})$ with zero far normal trace. Moreover,
$$
s_\lambda(L_Hh,L_Hh)\ge a_H\|h\|_{\mathcal T}^2,
\qquad
a_H=\sqrt{\frac{\beta_*^2-\lambda}{\beta_*^2+1}},
\tag{4.10}
$$
$$
\|f_H\|_0^2\le b_H^2\|h\|_{\mathcal T}^2,
\qquad
b_H^2=\frac12
\left(\frac6{L^2\kappa_*}+\frac3L\right)^2e^{-2a\kappa_*}.
\tag{4.11}
$$

**Proof.** For $l_k=\chi e^{-\kappa_kx}$, integration of an exact derivative gives
$$
\int_0^\infty(|l_k'|^2+\kappa_k^2|l_k|^2)
=\kappa_k+\int_0^\infty|\chi'|^2e^{-2\kappa_kx}
\ge\kappa_k.
$$
Divide by $q_k$, minimize over the high modes, and apply Parseval to obtain (4.10). The extra derivative integral is bounded by
$9e^{-2a\kappa_k}/(8L^2\kappa_k)$, and
$\int|l_k|^2\le1/(2\kappa_k)$; these also give boundedness of the lift in $H^1$.

For the residual of each mode,
$$
\|(-\chi''+2\kappa_k\chi')e^{-\kappa_kx}\|_0^2
\le
\left(\frac6{L^2}+\frac{3\kappa_k}{L}\right)^2
\frac{e^{-2a\kappa_k}}{2\kappa_k}.
$$
Since $q_k\ge\kappa_k$, its ratio to $q_k$ is at most
$\frac12(6/(L^2\kappa_k)+3/L)^2e^{-2a\kappa_k}$, a decreasing function of $\kappa_k$. This proves (4.11). Since $\chi'$ is continuous and zero at the joins, no distributional point masses arise in the second derivative.
Thus $\operatorname{div}p_H=-\lambda L_Hh-f_H\in L^2$.

All statements follow first for finite Fourier sums and then by the proved bounds. The physical normal trace need only belong to $H^{-1/2}$; it need not be an $L^2$ function. $\square$

### 4.5 An all-trace lower DtN matrix with zero scalar penalty

Use the low-mode fields and fluxes from (4.3), with exactly the low Fourier traces. On $J$ define
$$
z_i=u_i+K_+r_{2,i},
\qquad
Z_{ij}=\int_J z_j\overline{z_i}.
\tag{4.12}
$$
Form this Gram from the combined fields to preserve their cancellation.

**Theorem C.3.** Suppose
$$
A_H:=a_H-K_+b_H^2>0.
\tag{4.13}
$$
Then the finite Hermitian matrix
$$
\boxed{
\widehat\Lambda
=Q-K_+R-\frac{b_H^2}{A_H}Z
}
\tag{4.14}
$$
satisfies
$$
\boxed{
\Lambda(\lambda)(g,g)\ge
\widehat g^*\widehat\Lambda\,\widehat g
\quad\hbox{for every }g\in\mathcal T.
}
\tag{4.15}
$$
Here $\widehat g=(g_k)_{|k|\le M}$. Thus (D−) holds with $\varepsilon^-=0$.

**Proof.** Use $u=u_c+L_Hh$ and $p=p_c+p_H$ for $g=g_L+h$. The proof of Theorem C.1 applies to this single arbitrary trace and yields
$$
\Lambda(g,g)\ge
s_\lambda(u,u)
-K_+\left[
\int|r_{1,c}|^2+
\int\frac{|r_{2,c}-f_H|^2}{\rho}
\right].
\tag{4.16}
$$
Green's identity for the high lift gives
$$
s_\lambda(u_c,L_Hh)=\int_Ju_c\overline{f_H}.
$$
Its port term vanishes because the trace of $u_c$ has only low modes and the normal derivative of $L_Hh$ has only high modes. This is an $H^{1/2}$–$H^{-1/2}$ pairing, or equivalently the limit of the finite Fourier-sum identities.

Expand (4.16), using $\rho=1$ on $J$. Its right side is
$$
c^*(Q-K_+R)c
+s_\lambda(L_Hh,L_Hh)-K_+\|f_H\|_0^2
+2\operatorname{Re}\int_J(u_c+K_+r_{2,c})\overline{f_H}.
$$
Writing $t=\|h\|_{\mathcal T}$, (4.10)–(4.13) bound this below by
$$
c^*(Q-K_+R)c+A_Ht^2
-2b_H\sqrt{c^*Zc}\,t.
$$
Complete the scalar square:
$A_Ht^2-2b_H\sqrt{c^*Zc}\,t\ge-(b_H^2/A_H)c^*Zc$.
This proves (4.14)–(4.15). $\square$

For integration enclosures, the safe implementation is
$$
\widehat\Lambda
=Q_--K_+R_+
-\frac{b_H^2}{a_H-K_+b_H^2}Z_+,
\tag{4.17}
$$
where $Q_-\preceq Q$, $R_+\succeq R$, $Z_+\succeq Z$, with certified scalar bounds in the conservative directions.

The high tail's positive principal energy has absorbed its coupling to the low modes. This is why the scalar trace penalty can be zero despite a nonzero approximation error.

An optional sharper finite penalty retains modewise information. Let
$$
q_k^{H}=\kappa_k+\int|\chi'|^2e^{-2\kappa_kx},\quad
F_k^H=\|(-\chi''+2\kappa_k\chi')e^{-\kappa_kx}\|_0^2,
\quad d_k^H=q_k^H-K_+F_k^H.
$$
Condition (4.13) implies $d_k^H>0$. Define the vector
$$
(a_k)_i=\int_J
(-\chi''+2\kappa_k\chi')e^{-\kappa_kx}e^{i\beta_ky}
\overline{z_i}.
$$
Completing each high-mode square gives the smaller correction
$$
\sum_{|k|>M}\frac{a_ka_k^*}{d_k^H}
\preceq\frac{b_H^2}{A_H}Z.
\tag{4.18}
$$
Any finite number of columns can be computed explicitly, and the remaining tail bounded by restarting (4.10)–(4.11) at a larger cutoff. The simpler formula (4.14) already suffices for validity.

### 4.6 Finite construction and attainable accuracy

A complete finite construction is:

1. Choose finitely many physical lead cells and an explicit compact collar lift $\ell_i$ with trace $g_i$.
2. Set $u_i=\ell_i+w_i$, where $w_i$ lies in a conforming FE space with zero port and far traces.
3. Choose $p_i$ in a conforming Raviart–Thomas space, with exact transverse phase matching and zero far normal flux.
4. Minimize the finite positive quadratic residual in (4.3), or use the existing QZ extension followed by a smooth cutoff and a conforming flux reconstruction.
5. Enclose $Q,R,Z$, check (4.13), and assemble (4.7) or (4.17).

For homogeneous trace differences, a zero least-squares residual would give a compactly supported Dirichlet eigenfunction at $\lambda$, excluded by the previously certified half-lead resolvent. Thus the normal matrix is positive definite on an independent field/flux basis. A single factorization serves all trace right-hand sides.

For completeness, let $w=E(\lambda)g$. Then
$(w,\nabla w)\in H^1\times H(\operatorname{div})$ solves the PDE. Use a smooth cutoff $\chi_N$ equal to one near the port, and set
$u_N=\chi_Nw$, $p_N=\chi_N\nabla w$. Their residuals are
$w\nabla\chi_N$ and $\nabla\chi_N\cdot\nabla w$. With uniformly bounded cutoff derivatives these tend to zero in the required norms by $H^1$ tail integrability. Conforming approximation of this compact pair, retaining its exact trace through the fixed lift, makes the finite residual arbitrarily small. Consequently every positive residual tolerance is attainable by finite support enlargement and refinement. This proves convergence, not a predetermined number of cells.

For a raw discrete extension, the stable QZ subspace and a decaying transfer matrix may be useful for constructing the trial fields. They are not used as a continuous resolvent certificate.

### 4.7 Expected constants and cost

Take $a=L=1/8$ in the homogeneous collar. At $\lambda=\alpha_+=5.6169$, formula (4.11) gives:

| $M$ | $b_H^2$ | $a_H$ |
|---:|---:|---:|
| 8 | $3.96025\times10^{-4}$ | $0.9989466$ |
| 10 | $1.57112\times10^{-5}$ | $0.9992972$ |
| 12 | $6.38711\times10^{-7}$ | $0.9994979$ |
| 14 | $2.63645\times10^{-8}$ | $0.9996235$ |
| 16 | $1.09938\times10^{-9}$ | $0.9997073$ |
| 20 | $1.94910\times10^{-12}$ | $0.9998085$ |

For illustration only, if an independently certified one-sided distance were $d_+=0.05$, then $K_+=133.338$ and $K_+b_H^2\approx1.47\times10^{-7}$ at $M=16$. This is not an inference from the sampled periodic edge. Section 7 gives examples using the actual certified periodic distances and hypothetical, explicitly identified boundary margins.

Let $T_{\rm tr}=\operatorname{diag}(q_k)_{|k|\le M}$ and
$$
r=\|T_{\rm tr}^{-1/2}RT_{\rm tr}^{-1/2}\|.
$$
The scalar-equivalent low residual penalty is $K_+r$. A target $K_+r\le4\times10^{-4}$ requires
$r\le4\times10^{-4}/K_+$. For $K_+\approx133$, this means $r\lesssim3.0\times10^{-6}$, or residual operator norm about $1.7\times10^{-3}$. These are planning tolerances, not measured residuals.

With $m=2M+1$ low modes, a straightforward construction uses one field/flux factorization on $N_c$ cells per endpoint and lead, followed by $m$ backsolves. An uncondensed P3 plus RT3 least-squares system is roughly $1.4\times10^5N_c$ unknowns using the supplied cell triangle count; this is a structural estimate, not a measured system size. Local elimination, template reuse, a QZ-generated field, or patchwise flux reconstruction can reduce the work. The final matrices are only $m\times m$. Modes whose explicit collar lifts already meet the residual tolerance need no global response solve.

For the original nodal (D+) comparison, $m$ is about $144$. This extra lower-endpoint work is not necessary for the final isolation implication proved below.

## 5. Item (D): projection constants with natural ports and quasi-periodicity

The energy form on the core is unweighted:
$$
e(u,v)=a_D(u,v)+\sigma(u,v)_0,\qquad \sigma>0.
$$
The material interface affects integration over the trial space, but it does not enter the exact reference modes of this energy.

### 5.1 An explicit spectral-space constant

On $D=(-1/2,1/2)\times I$, set
$$
\psi_{m,k}(x,y)=c_m\cos(m\pi(x+1/2))e^{i\beta_ky},
\quad m\ge0,\quad k\in\mathbb Z,
$$
where $c_0=1$ and $c_m=\sqrt2$ for $m>0$. They are an orthonormal unweighted $L^2$ basis. Let
$$
a_{m,k}=(m\pi)^2+\beta_k^2+\sigma.
$$
For every $u\in H^1_{\beta_0}(D)$,
$$
\|u\|_0^2=\sum|u_{m,k}|^2,\qquad
\|u\|_e^2=\sum a_{m,k}|u_{m,k}|^2.
\tag{5.1}
$$
These are form-domain Parseval identities, obtained from the cosine/sine derivative formulas in $x$ and Fourier Parseval in $y$. They do not impose a Neumann boundary condition on $u$.

**Proposition D.1.** If the trial space contains
$W_{\mathcal I}=\operatorname{span}\{\psi_{m,k}:(m,k)\in\mathcal I\}$ and
$$
a_*=\inf_{(m,k)\notin\mathcal I}a_{m,k},
$$
then the projection hypothesis (C) holds with
$$
\boxed{C_h=a_*^{-1/2}.}
\tag{5.2}
$$

**Proof.** For $w\perp_e V_h$, all retained coefficients vanish because
$W_{\mathcal I}\subset V_h$. Sum
$\sum_{\notin\mathcal I}|w_{m,k}|^2
\le a_*^{-1}\sum_{\notin\mathcal I}a_{m,k}|w_{m,k}|^2$.
For the space $W_{\mathcal I}$ itself, equality is attained by a lowest omitted mode whenever the infimum is attained. $\square$

For the rectangle $0\le m\le N_x$, $|k|\le N_y$,
$$
a_*=\sigma+\min\left\{
[(N_x+1)\pi]^2+0.25,\,
[2\pi(N_y+1)-0.5]^2
\right\}.
\tag{5.3}
$$

### 5.2 Exact port enrichment

**Design change.** Add to the chosen trial space the exact representatives
$r_{\pm,k}$ from the supplied Lemma 7 for every $|k|\le M$ used by (4.15):
$$
V_h=V_{\rm base}+
\operatorname{span}\{r_{+,k},r_{-,k}:|k|\le M\}.
\tag{5.4}
$$
For every $w\perp_e V_h$,
$$
(\tau_\pm w)_k=e(w,r_{\pm,k})=0,\qquad |k|\le M.
\tag{5.5}
$$
Thus the retained $\delta_{\pm,k}$ vanish **exactly**. If $V_{\rm base}$ contains $W_{\mathcal I}$, the constant (5.2) remains valid.

The explicit representatives are
$$
r_{+,k}(x,y)=
\frac{\cosh(\kappa_k^\sigma(x+1/2))}
{\kappa_k^\sigma\sinh(\kappa_k^\sigma)}
e^{i\beta_ky},
\quad
r_{-,k}(x,y)=
\frac{\cosh(\kappa_k^\sigma(1/2-x))}
{\kappa_k^\sigma\sinh(\kappa_k^\sigma)}
e^{i\beta_ky},
$$
where $\kappa_k^\sigma=\sqrt{\beta_k^2+\sigma}$. Integration by parts with their interior equation $(-\Delta+\sigma)r=0$ and their prescribed normal derivatives verifies the representative identity.

This enrichment matters. For a pure cosine truncation and a retained $k$, the representative error is
$$
\|r_{\pm,k}-P_{W_{\mathcal I}}r_{\pm,k}\|_e^2
=2\sum_{m>N_x}\frac1{(m\pi)^2+\beta_k^2+\sigma}
\sim\frac2{\pi^2N_x}.
\tag{5.6}
$$
It decays too slowly to regard the port penalty as negligible without checking it. Adding two explicit functions per frequency avoids that loss.

Remove any linear dependencies before forming an inverse matrix. For a spectral base, the two residual representatives at each $k$ have an explicit $2\times2$ energy Gram, so stable independent combinations can be selected by a finite Gram factorization.

With $\sigma=1$ and $\lambda=\alpha_+$,
$q_{\max}=4\alpha_++1=23.4676$. The explicit rectangular choices give:

| $(N_x,N_y)$ | Base dimension | $C_h$ | $q_{\max}C_h^2$ | $q_{\max}C_h^2/(1-q_{\max}C_h^2)$ |
|---|---:|---:|---:|---:|
| $(15,8)$ | $272$ | $0.0198895$ | $0.00928355$ | $0.00937054$ |
| $(31,16)$ | $1056$ | $0.00994657$ | $0.00232175$ | $0.00232715$ |
| $(47,24)$ | $2352$ | $0.00663127$ | $0.00103196$ | $0.00103303$ |
| $(63,32)$ | $4160$ | $0.00497352$ | $0.00058049$ | $0.00058083$ |

A spectral ellipse rather than a rectangle saves modes; a cutoff near $(48\pi)^2$ uses about $1827$ modes. The rectangle has the advantage of the immediately explicit formula (5.3).

For example, the $2352$-dimensional base with $M=16$ needs at most $66$ added port representatives, giving a core test of order at most $2418$. This is an allowed change of the inertia-test space, independent of the curved mesh used for the Lehmann–Goerisch calculation.

### 5.3 A finite constant on the existing curved FE space

Changing the space is not required to obtain a theorem. The following formula applies to **any** conforming finite space with the stated port and phase conditions.

Let $H=K+\sigma M^1$ be its positive energy matrix. Choose $a_*>0$ and a finite set $\mathcal I$ containing every exact reference mode with $a_\ell<a_*$. Define
$$
F_{i\ell}=e(\psi_\ell,\varphi_i),\qquad
R=\operatorname{diag}_{\ell\in\mathcal I}(a_\ell)-F^*H^{-1}F.
\tag{5.7}
$$
The exact modes have zero normal derivative on the ports, so
$$
F_{i\ell}=a_\ell\int_D\psi_\ell\overline{\varphi_i}.
$$
Only explicit mode/FE mass integrals are required, including on curved elements.

Put
$$
b_\ell=\frac{(1-a_\ell/a_*)_+}{a_\ell^2},\qquad
D_b=\operatorname{diag}\sqrt{b_\ell}.
$$

**Theorem D.2.** A valid projection constant on the existing space is
$$
\boxed{
C_h^2=\frac1{a_*}+\lambda_{\max}(D_bRD_b).
}
\tag{5.8}
$$

**Proof.** Let $r_\ell=\psi_\ell-P_h\psi_\ell$. Orthogonal projection gives
$R_{ij}=e(r_j,r_i)$, proving (5.7). For $w\perp_e V_h$,
$$
e(w,r_\ell)=e(w,\psi_\ell)=a_\ell w_\ell.
$$
By (5.1),
$$
\|w\|_0^2-\frac1{a_*}\|w\|_e^2
=\sum_\ell(1-a_\ell/a_*)|w_\ell|^2
\le\sum_{\ell\in\mathcal I}b_\ell|e(w,r_\ell)|^2.
$$
The squared norm of the finite analysis map
$w\mapsto(\sqrt{b_\ell}\,e(w,r_\ell))_\ell$
is the largest eigenvalue of its Gram matrix $D_bRD_b$.
This proves (5.8). $\square$

This proof needs no interpolation constant, no point evaluation bound, and no unproved regularity constant for a curved mesh. For enclosures, use an upper matrix for $R$ and an upper bound for the largest eigenvalue; Section 1.2 supplies explicit inverse-error propagation.

A cutoff near $(48\pi)^2$ requires roughly $1800$ right-hand sides after one sparse factorization of $H$. A finite Gram eigenvalue calculation follows. Block processing avoids storing all responses at once. The actual correction in (5.8) is not determined by the statement “48 subdivisions per side.”

A cheaper upper bound replaces $\lambda_{\max}$ by the trace
$\sum b_\ell R_{\ell\ell}$. It is valid but can lose a factor comparable to the number of reference modes. Its sufficiency must be checked.

A third permitted design is to retain the existing FE space and add both $W_{\mathcal I}$ and the port representatives. Then (5.2) holds immediately, and the existing approximating power is retained, at the cost of the extra basis functions and mixed integrals.

## 6. A sharper core theorem and the final isolation implication

### 6.1 Lower matrix after exact port enrichment

Fix $\lambda=\alpha_+$ and assume the all-trace inequalities (4.15) for both physical half-leads. Assume the chosen core space contains all corresponding port representatives, so (5.5) holds.

Define
$$
q(x)=\lambda\rho(x)+\sigma,\qquad
q_{\max}=\lambda\rho_{\max}+\sigma,
$$
$$
H=(e(\varphi_j,\varphi_i)),\qquad
Q=\left(\int_Dq\varphi_j\overline{\varphi_i}\right),
$$
$$
T_{\rm low}=H-Q+\sum_\pm B_\pm^*\widehat\Lambda_\pm B_\pm.
\tag{6.1}
$$
Here $B_\pm$ contains the exact low Fourier coefficients of the core traces. Suppose a projection constant has been certified and
$$
c_W=1-q_{\max}C_h^2>0.
\tag{6.2}
$$

For each basis function let $z_i\in\mathcal H$ be the unique $e$-Riesz representative of its weighted mass functional:
$$
e(z_i,w)=\int_Dq\varphi_i\overline w.
$$
Let
$$
G_{ij}=e((I-P_h)z_j,(I-P_h)z_i).
\tag{6.3}
$$

**Theorem S.1.** If a finite Hermitian matrix $\overline G\succeq G$ is certified, then
$$
\boxed{
n(t_\lambda)\le
n\left(T_{\rm low}-\frac{\overline G}{c_W}\right).
}
\tag{6.4}
$$

**Proof.** Write $u=v+w$, $v=P_hu$, $w\perp_e V_h$.
The energy cross term is zero. By (5.5), every retained port coefficient of $w$ is zero. Applying the all-trace lower bounds to $\tau_\pm(v+w)$ therefore produces only the finite boundary term in $v$. The negative volume term gives
$$
t_\lambda(u,u)
\ge c_v^*T_{\rm low}c_v
+c_W\|w\|_e^2
-2\operatorname{Re}\int_Dqv\overline w.
$$
If $z_v^W=(I-P_h)\sum_i(c_v)_iz_i$, the last functional is
$e(z_v^W,w)$ and $\|z_v^W\|_e^2=c_v^*Gc_v$. Hence
$$
t_\lambda(u,u)
\ge
c_v^*\left(T_{\rm low}-\frac{\overline G}{c_W}\right)c_v
+c_W\left\|w-\frac{z_v^W}{c_W}\right\|_e^2.
\tag{6.5}
$$
Projection of any negative subspace onto $V_h$ is injective, since a nonzero vector with zero projection has positive lower bound. Its projected finite form is negative on every nonzero projected vector. This proves (6.4). No invertibility of the final lower matrix is needed for the abstract inequality. $\square$

This theorem replaces the mass and port Young estimates of the supplied Theorem 2. The conditions $\varepsilon^-=0$ and $\delta_{\pm,k}=0$ have been obtained by explicit constructions, not assumed as limits.

### 6.2 A finite, spatially sensitive mass-coupling Gram

Choose finitely many exact core modes $\psi_\ell$ so that every omitted mode has $a_\ell\ge a_*$. Compute
$$
F_{\ell i}=\int_Dq\varphi_i\overline{\psi_\ell},
\qquad
M^{q^2}_{ij}=\int_Dq^2\varphi_j\overline{\varphi_i}.
$$
Then the explicit matrix
$$
\boxed{
\overline G
=
F^*\operatorname{diag}(a_\ell^{-1})F
+\frac1{a_*}(M^{q^2}-F^*F)
-QH^{-1}Q
}
\tag{6.6}
$$
satisfies $\overline G\succeq G\succeq0$.

**Proof.** The full reference expansion of $z_i$ has coefficient
$F_{\ell i}/a_\ell$. Thus its energy Gram is
$\sum_{\ell}F_\ell^*F_\ell/a_\ell$.
For omitted modes, $1/a_\ell\le1/a_*$. By $L^2$ Parseval their source Gram is
$M^{q^2}-F^*F\succeq0$. The energy Gram of the projection $P_hz_i$ is exactly
$QH^{-1}Q$, because $Q$ is Hermitian. Subtracting that projection Gram proves (6.6). $\square$

This improvement uses the true spatial support of $\rho=4$ and the actual trial functions. It can be considerably sharper than a worst-case material bound. Its numerical size still requires its finite integrals. In particular, the star's area fraction alone does not justify a weighted projection constant.

If a separately certified constant $b_q<1$ gives
$\int_Dq|w|^2\le b_q\|w\|_e^2$ on the complement, the proof of Theorem S.1 permits $c_W=1-b_q$. Formula (6.6) is already a concrete spatially weighted improvement for the cross term and requires no such additional certificate.

### 6.3 An inexpensive scalar version

Weighted Cauchy–Schwarz and the projection bound give
$$
\left|\int_Dqv\overline w\right|^2
\le
\left(\int_Dq|v|^2\right)
q_{\max}C_h^2\|w\|_e^2.
$$
Therefore
$G\preceq q_{\max}C_h^2Q$ and Theorem S.1 gives
$$
\boxed{
L_{\rm scalar}
=
H-\frac{Q}{1-q_{\max}C_h^2}
+\sum_\pm B_\pm^*\widehat\Lambda_\pm B_\pm,
\qquad
n(t_\lambda)\le n(L_{\rm scalar}).
}
\tag{6.7}
$$
The scalar mass inflation is exactly $1/(1-q_{\max}C_h^2)$.
It is the completed-square version of the complement estimate, with no free parameters $\theta,\theta_\pm$ and no trace penalty.

If (6.7) fails the desired inertia, first try the matrix correction (6.6), or increase the explicit spectral cutoff. No new infinite-dimensional argument is needed.

### 6.4 Only the upper endpoint is needed

**Theorem S.2 (final finite certificate for H).** Assume:

- the full-periodic gaps of (A);
- successful endpoint surface certificates of Theorem B.5 with equal endpoint counts for each material, giving (P);
- the independent first-order interval $I_1\subset(\alpha_-,\alpha_+)$ meets $\sigma(A)$, as supplied in the problem;
- the two upper-endpoint all-trace DtN matrices from Theorem C.3;
- a conforming core space with exact port enrichment, a certified projection constant, and $c_W>0$;
- one of the finite lower matrices in (6.4) or (6.7), denoted $L_{\rm cert}$, satisfies $n(L_{\rm cert})\le1$.

Then $(\alpha_-,\alpha_+)$ contains exactly one spectral point, and it is a simple eigenvalue.

**Proof.** The surface certificates give the closed-window hypothesis (P). The supplied Theorem 1 applies. By Theorem S.1,
$n(t_{\alpha_+})\le1$, while $n(t_{\alpha_-})\ge0$ automatically. Hence
$$
\sum_{\lambda\in[\alpha_-,\alpha_+)}
\dim\ker(A-\lambda)
=n(t_{\alpha_+})-n(t_{\alpha_-})\le1.
$$
Under (P), the spectrum in the window consists of finitely many eigenvalues of finite multiplicity. Since $I_1$ meets it strictly inside, the sum is at least one. Thus it equals one and the unique interior eigenvalue is simple. $\square$

The lower-endpoint $U_h$ and (D+) remain available from Section 4.3 if desired. They are not a required numerical gate for this final theorem. This removes a computation at the narrower lower band margin.

## 7. Feasibility, useful diagnostics, and total work

### 7.1 What the supplied raw FE numbers can and cannot decide

The reported smallest absolute raw matrix eigenvalues,
$1.65\times10^{-4}$ and $1.53\times10^{-4}$, are not invariant under a change of FE basis. Multiplying all basis functions by a scalar multiplies these eigenvalues by its square without changing the underlying form or its inertia. They therefore cannot be compared directly with an error stated in an energy or trace norm. The value $\|T_h\|_1\approx83.7$ does not fix that problem.

The sampled periodic margin also is not the positive spectral margin of the reduced core form. It measures a different operator. A mass-inflation estimate of order $10^{-3}$ is useful for planning, but it does not by itself prove that the corrected core has one negative eigenvalue.

Here is a proper finite perturbation test. On the **same trial space and in the same basis**, let $T_0$ be a nominal core matrix and let $H_0\succ0$ be a declared reference Gram, preferably its energy matrix. Suppose a computable positive semidefinite $E$ satisfies
$$
L_{\rm cert}\succeq T_0-E.
$$
Set
$$
\gamma_2=\lambda_2(H_0^{-1/2}T_0H_0^{-1/2}),
\qquad
\epsilon=\|H_0^{-1/2}EH_0^{-1/2}\|.
$$
Then
$$
\boxed{\gamma_2>\epsilon\quad\Longrightarrow\quad n(L_{\rm cert})\le1.}
\tag{7.1}
$$
This is the eigenvalue min-max perturbation bound: the second eigenvalue of the normalized corrected matrix is at least $\gamma_2-\epsilon>0$. For preservation of the *entire* inertia, a two-sided perturbation norm smaller than the smallest absolute normalized eigenvalue suffices. The weaker condition (7.1) is all the final theorem needs.

If the trial space is changed or enriched, the old raw FE matrix is not a matrix on that new space. Its positive margin must be recomputed there. Directly counting the fully corrected finite matrix is usually sharper than estimating a global perturbation norm.

### 7.2 The main quantitative bottleneck is the half-resolvent estimate

The periodic distances have actually been certified in (2.18). The following examples show why a measured layer Gram matters. They are **conditional planning scenarios**, not measurements of the missing boundary matrices.

Assume, for illustration, that the finite surface certificate supplies
$\operatorname{dist}(0,\sigma(\mathscr B_\lambda))\ge0.1$.

| Endpoint | Periodic distance used | Bound (3.26) for $\|\mathscr T_\lambda\|^2$ | Resulting coarse $d_{\rm half}$ | Resulting coarse $K_\lambda$ |
|---|---:|---:|---:|---:|
| $\alpha_-$ | $0.005276$ | about $49354.4$ | about $2.03\times10^{-6}$ | about $1.35\times10^6$ |
| $\alpha_+$ | $0.023725$ | about $5898.84$ | about $1.69\times10^{-5}$ | about $3.91\times10^5$ |

If instead the response Gram (3.27)–(3.28) certifies
$\|\mathscr T_\lambda\|^2\le4$, keeping the same hypothetical boundary gap, then (3.25) gives
$$
d_{\rm half}(\alpha_-)\ge
\frac1{0.005276^{-1}+40}\approx0.0043566,
$$
$$
d_{\rm half}(\alpha_+)\ge
\frac1{0.023725^{-1}+40}\approx0.0121729.
$$
The corresponding common form-inverse constants are approximately $630.5$ and $544.6$. These examples do not predict that the Gram equals $4$; they identify the missing observable that controls the error budget.

At the upper endpoint, $K_+\approx545$ and $M=16$ give
$K_+b_H^2\approx6.0\times10^{-7}$, so the analytic high tail easily passes (4.13). A low residual budget $K_+r\le4\times10^{-4}$ then asks for
$$
r\lesssim7.34\times10^{-7},
\qquad
\sqrt r\lesssim8.57\times10^{-4}.
$$
With the coarse $K_+\approx3.91\times10^5$, the same target asks for
$\sqrt r\lesssim3.2\times10^{-5}$. Larger $M$ controls the high tail, but it does not repair an unnecessarily large low-mode resolvent constant. The actual $Z$ matrix in (4.14) must also be evaluated; the scalar $b_H^2$ alone is not the whole coupling penalty.

For the surface low-block calculation itself, (3.20) amplifies the residual Gram by only $1/d_{\rm per}$: about $190$ at the lower endpoint and $42.2$ at the upper endpoint. For example, a boundary matrix error budget $\|E\|\le0.01$ requires
$$
\sqrt{\|G_r\|}\le\sqrt{0.01d_{\rm per}},
$$
approximately $0.00726$ and $0.0154$, respectively. This tolerance is illustrative and must be chosen relative to the actually computed boundary gap in (3.16).

### 7.3 Core complement budget

The explicit spectral-plus-port space with $(N_x,N_y)=(47,24)$, $\sigma=1$, gives
$$
C_h=0.00663127\ldots,\qquad
q_{\max}C_h^2=0.00103196\ldots,\qquad
\frac1{1-q_{\max}C_h^2}=1.00103303\ldots.
$$
There is no global stiffness deflation and no port-representative penalty. This is compatible in scale with the problem's desired $10^{-3}$ complement budget. It is not a numerical proof of the final inertia.

The actual scalar correction from (6.7) is
$$
\frac{q_{\max}C_h^2}{1-q_{\max}C_h^2}\,Q.
$$
If this is too large in the core's measured positive directions, use the spatially sensitive $\overline G$ in (6.6), or increase the spectral cutoff. The $(63,32)$ choice reduces the scalar inflation to about $5.81\times10^{-4}$ with a base dimension $4160$.

There is consequently a concrete route to a less lossy test than the supplied Theorem 2. What cannot be concluded from the input table is that its finite positive margin exceeds the resulting DtN and mass corrections. That final inequality or inertia must be computed.

### 7.4 Work estimate for the recommended route

The cut and window stay as stated. The recommended core certification space is the explicit spectral space with port enrichment. Use separate cutoffs $M_B$ for the single-layer certificate and $M_C$ for the DtN lower matrix; they need not be equal.

| Stage | Finite operations | Typical starting dimensions |
|---|---|---|
| (A), already executed | $472$ small Hermitian sign tests after two geometry assemblies | $169$ per test; $2048$ curve nodes |
| (B), compact-response version | Four common least-squares factorizations; $4(2M_B+1)$ response right-hand sides; eight small Schur-bound inertia tests | $M_B=8$–$10$, boundary matrices $17$–$21$; response dimension determined by support/residual |
| (B), Bloch alternative | Four collections of $N_\theta$ cell factorizations, each with $2M_B+1$ right-hand sides | Existing cell spaces or Fourier spaces; parameter integration certified separately |
| (C), upper endpoint only | Two field/flux factorizations on finite physical leads, each with $2M_C+1$ right-hand sides, or reuse QZ fields and reconstruct fluxes | $M_C=16$–$20$; direct uncondensed mixed size about $1.4\times10^5N_c$ per side |
| (D), explicit spectral option | Analytic reference Gram and projection constant; true material and mixed port integrals | Base $2352$ plus at most $66$ port functions for $M_C=16$ |
| (D), existing FE alternative | One sparse energy factorization, about $1800$ reference-mode right-hand sides, finite Gram bound | Existing $28629$ core DOFs |
| Final count | One Hermitian inertia test after all safe corrections | At most $2418$ for the stated spectral-plus-port choice |
| Optional original (D+) | Two additional lower-endpoint extension/flux calculations | About $144$ nodal traces per side |

These are counts and structural dimensions, not a promised wall-clock runtime. The expensive part can be the residual certification of full-strip and half-strip responses near a band edge. Reusing cell factorizations, templates, and the existing QZ fields is valuable, but its success is decided by the certified residuals.

### 7.5 Recommended implementation order

First reproduce Appendix A. Next implement the four single-layer low blocks and their Schur certificates, before investing in a high-accuracy core test. This determines whether the stronger two-orientation surface criterion succeeds.

If it does, compute the upper-endpoint layer Grams and half-resolvent constants. Construct the upper-endpoint DtN lower matrices with measured residuals. Assemble the explicit spectral-plus-port core and start with the scalar matrix (6.7). Count that matrix directly. If its second eigenvalue is not positive, inspect the finite penalty contributions, use (6.6), or refine the specific dominant residual.

If the surface endpoint counts differ, locate the poles first and decide whether an allowed window or cut change avoids them. This is a mathematically meaningful branch of the computation, not a reason to replace the missing certificate by the existing scan.

## 8. Assumptions and discrete obligations

### 8.1 Mathematical assumptions used

1. **The stated differential operator and material.** The principal part is the constant Laplacian; $\rho$ is real, bounded, and bounded below by $1$, with the stated values $17$ in lead inclusions and $4$ in the core inclusion. No coefficient multiplies the gradient.
2. **The stated geometry and phase.** The strip and core are the given rectangles; the longitudinal lead period is $1$; the transverse phase is exactly $\beta_0=0.5$.
3. **Conforming form domains.** The energy spaces have the prescribed quasi-periodicity, natural core ports, and Dirichlet half-lead ports when specified.
4. **Floquet decomposition.** The periodic spectrum is the union of the compact-resolvent fiber spectra, as supplied in the problem. The comparison, phase modulus, and band index are proved here.
5. **Lead collar.** The analytic trefoil radius bound gives $\rho=1$ for distance $1/4$ from either side of a pure-lead cut. Only $y$-reflection is used for the phase symmetry.
6. **The supplied reduced count theorem.** Theorem 1 is used only after (P) has been certified. Its validity is a premise of the task.
7. **Independent spectral intersection.** The supplied first-order interval meets $\sigma(A)$ strictly inside the window without using (H).
8. **Certified integration capability.** Integrals of the explicit piecewise-smooth fields and true material geometry can be enclosed with explicit remainders, as allowed by the task. Section 2 provides its own sharper remainder for the executed band calculation.
9. **Arithmetic convention.** Finite matrix operations and function evaluations are treated in the rounding-excluded model. No rounding-inclusive numerical theorem is asserted.
10. **Finite acceptance tests.** Strict positivity, inverse bounds, endpoint inertia equality, and the final count are conclusions of the specified finite tests when they pass. They are not assumed numerical facts.

No a priori half-lead resolvent, no $x$-reflection symmetry, no continuum inference from a stable discrete graph, and no mesh-size-only value of $C_h$ is used.

### 8.2 Code facts that must be satisfied or checked

| Obligation | Where it is needed |
|---|---|
| Use the true analytic material geometry, not a polygonal replacement | All mass, source, and residual integrals |
| Correct phase factors on both identified transverse boundaries | Every FE, Fourier, spline, and flux space |
| Correct material orientation for the physical left and right half-leads | Surface and DtN constructions |
| Exact low Fourier trace normalization and consistent matrix order | $B_\pm$, $\widehat\Lambda_\pm$, and port representatives |
| Global $H^2$ conformity of compact full-strip response trials, including matching first derivatives at support joins | Volume-residual certificate (3.20) |
| Alternatively, $H^1$ conformity plus $H(\operatorname{div})$ flux conformity with correct Bloch phases | Bloch-cell form-residual alternative |
| Exact physical traces of the low DtN lifts, zero far traces, and zero far flux | Theorem C.1 and finite truncation validity |
| $H(\operatorname{div})$ conformity across element and material interfaces | Cancellation of residual boundary terms |
| Exact inclusion of all required port representatives in the core space | Vanishing retained traces of the complement |
| Independent core basis and positive energy Gram | Projection formulas and finite inverse operations |
| Correct safe directions for every integral and matrix enclosure | All certified inequalities |
| Residual Grams formed from the residual fields before enclosure | Preservation of quadratic smallness |
| Finite endpoint inertia and nonzero Schur-gap tests recorded for each material | Theorem B.3 and half-resolvent constants |
| Final corrected core inertia recorded after every penalty | Theorem S.2 |

The reported side subdivision count, matching wall nodes, and $144$ wall DOFs remain code facts “to be confirmed” if the existing nodal construction is used. They are not needed by the independent plane-wave band certificate or by the proposed spectral core.

If raw QZ responses are reused, the code must additionally verify that the chosen fields and reconstructed fluxes actually have the prescribed traces and phases. Merely having $|\zeta|<1$ in a finite pencil does not discharge any continuous residual or spectral obligation.

## 9. Remaining numerical gates and exact failure conditions

The mathematical methods are complete finite certificates. The following computations are still open for this project.

| Gate | Exact missing output | What would close it |
|---|---|---|
| B1: endpoint boundary operators | For each material and each endpoint, $\widehat C,E,h_M,x_M$, and a strict finite Schur gap | The two matrices in (3.16) are nonsingular and have the same inertia |
| B2: no surface poles in the window | The two endpoint inertias for each material | Equality for each material; then Theorem B.3 gives (P) |
| B3: useful upper-endpoint half resolvent | A bound for $\|\mathscr T_{\alpha_+}\|^2$ and the certified boundary inverse norm | Equations (3.25), (3.27), and (3.28) give a numerical $K_+$ |
| C: all-trace lower DtN | Upper-endpoint field/flux matrices $Q,R,Z$ for both physical half-leads | Check $a_H-K_+b_H^2>0$ and assemble (4.17) |
| D, if keeping only the existing FE base | Its energy/mode cross matrices | Evaluate (5.8); this gate disappears with the explicit spectral base |
| Final H | The fully corrected finite core matrix | Certify $n(L_{\rm cert})\le1$, preferably by a strict positive second normalized eigenvalue or direct inertia |

If B1 fails, increase the response accuracy or boundary cutoff; a small approximate gap is not a reason to assert invertibility. If B2 fails after B1 succeeds, actual surface eigenvalues have been counted for the pair. If C's residual correction is too large, improve the endpoint resolvent estimate or field/flux approximation. If the final core count exceeds one, the current lower bound is insufficient; inspect the finite penalties and refine them before drawing a conclusion about the actual spectrum.

The existing data do not provide B1–B3, the residual matrices in C, or the corrected core matrix. Thus they do not yet prove (H). What this manuscript adds is a noncircular route with explicit finite tests for every missing step, an executed periodic band certificate, and a less lossy final reduction.

## 10. Sources and relation to the literature

The geometry, the current FE observations, the supplied count theorem, and the independent spectral-intersection premise are taken from the user-supplied problem statement, h-cert-problem.md, Sections 1–3. Numerical values explicitly identified as newly executed in Section 2 come from Appendix A, not from that FE data.

The specialized estimates and surface-count theorem used in this manuscript have been proved above. The following sources were checked for context:

1. **S. Fliss**, “A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides,” *SIAM Journal on Scientific Computing* 35 (2013), B438–B461. [Author preprint, arXiv:1202.4928v2](https://arxiv.org/abs/1202.4928v2), especially Theorem 4.1 and Remark 4.2, manuscript pp. 10–11. Theorem 4.1 permits exceptional half-band Dirichlet frequencies and gives a symmetry-based exclusion when the cell has the required longitudinal reflection symmetry. That symmetry is unavailable here. Remark 4.2 discusses a Robin-to-Robin alternative; it is not used as a substitute for the Hermitian, quantitatively certified construction in this manuscript.
2. **V. Hoang, M. Plum, C. Wieners**, “A computer-assisted proof for photonic band gaps,” *Zeitschrift für angewandte Mathematik und Physik* 60 (2009), 1035–1052. [Primary preprint hosted by KIT](https://publikationen.bibliothek.kit.edu/1000007941/246229). It develops finite-parameter eigenvalue enclosures and a perturbative phase covering. Section 2 above uses a directly proved Fourier-complement comparison for the present constant-principal-part problem, so no homotopy base eigenproblem or unverified numerical constant from that paper is needed.

The other literature pointers in the problem are not needed as black-box theorems for this proof. In particular, no unverified Riccati characterization, polygonal-domain interpolation constant, or general Robin pole-free claim is an assumption.

## Appendix A. Self-contained reproduction of the executed band certificate

The code below contains the entire accepted covering as an exact integer endpoint chain. Every panel endpoint is an integer multiple of $\pi/4096$. Adjacent endpoints define consecutive panels, so coverage is checked without interpolation between unlisted sample points.

The implementation uses NumPy and SciPy for the finite calculations. It includes the proved curve integration error and the infinite Fourier-complement penalty. It deliberately does not implement interval arithmetic for finite-operation rounding, which the problem excludes.

Save the following block as h-band-reproduce.py and run it with Python. For predictable use of local computational resources, a single BLAS thread is sufficient. The reproduction script is included in this Markdown so that the deliverable is self-contained.

```python
"""Reproduce the finite certificate for both periodic-lead gaps.

Requires NumPy and SciPy. Run: OPENBLAS_NUM_THREADS=1 python h-band-reproduce.py
The certificate includes Fourier tails, phase interpolation, and the analytic
2048-point trapezoidal remainder. Finite matrix arithmetic/eigenvalues are
interpreted in the problem's rounding-excluded model. This implementation uses
ordinary floating point, not interval arithmetic or a rounding-error bound.
"""
import json
import numpy as np
from scipy.linalg import eigh

N, J, SCALE = 6, 2048, 4096
KLOW, KHIGH = 1.318, 2.375
MN = np.array([(m, n) for m in range(-N, N + 1)
                        for n in range(-N, N + 1)])
DIM = len(MN)  # 169

# Exact panel endpoints are these INTEGERS times pi/4096.
END = ([0, 1024, 1536, 2048, 2560, 2816, 3072, 3200,
        3328, 3392, 3456, 3520, 3584, 3616, 3648, 3680, 3712, 3744]
       + list(range(3760, 3889, 16)) + list(range(3896, 3953, 8))
       + list(range(3956, 4005, 4)) + list(range(4006, 4047, 2))
       + list(range(4047, 4097)))
assert END[0] == 0 and END[-1] == SCALE
assert all(l < h for l, h in zip(END, END[1:]))
assert len(END) - 1 == 118  # A consecutive chain covers [0, pi] exactly.


def indicator_matrix(a):
    """B_ij = integral_D exp(2 pi i ((m_j-m_i)x+(n_j-n_i)y))."""
    t = 2 * np.pi * np.arange(J) / J
    radius = .2 / np.sqrt(1 + a * a / 2)
    r, dr = radius * (1 + a * np.cos(3 * t)), -3 * radius * a * np.sin(3 * t)
    x, y = r * np.cos(t), r * np.sin(t)
    dx, dy = dr * np.cos(t) - r * np.sin(t), dr * np.sin(t) + r * np.cos(t)
    integers = np.arange(-2 * N, 2 * N + 1)
    coeff = np.empty((4 * N + 1, 4 * N + 1), complex)
    for i, m in enumerate(integers):
        qx, qy = 2 * np.pi * m, 2 * np.pi * integers[:, None]
        q2 = qx * qx + qy * qy
        wave = np.exp(1j * (qx * x[None, :] + qy * y[None, :]))
        flux = qx * dy[None, :] - qy * dx[None, :]
        integral = np.sum(wave * flux, axis=1) * (2 * np.pi / J)
        nz = q2[:, 0] > 0
        coeff[i, nz] = -1j * integral[nz] / q2[nz, 0]
        if m == 0:
            coeff[i, 2 * N] = .04 * np.pi  # Exact inclusion area.
    dm = MN[None, :, 0] - MN[:, None, 0]
    dn = MN[None, :, 1] - MN[:, None, 1]
    B = coeff[dm + 2 * N, dn + 2 * N]
    return (B + B.conj().T) / 2


# On |Im t| <= .1, every nonzero coefficient integrand has modulus < 8.
# Therefore each coefficient error is <= 32*pi/(exp(.1*J)-1).
EPS_B_ENTRY = 32 * np.pi / np.expm1(.1 * J)
EPS_B = DIM * EPS_B_ENTRY
EPS_M = 16 * EPS_B
EPS_G = 256 * EPS_B * (3 + EPS_B)
templates = []
for a in (.12, .20):
    B = indicator_matrix(a)
    templates.append((np.eye(DIM) + 16 * B, 256 * (B - B @ B)))

lower_min = upper_min = denominator_min = np.inf
lambda_max = upper_error_max = 0.
for l, h in zip(END, END[1:]):
    theta = np.pi * (l + h) / (2 * SCALE)
    r = np.pi * (h - l) / (2 * SCALE)
    assert 0 <= theta <= np.pi and KLOW > r
    low, high = (KLOW - r) ** 2, (KHIGH + r) ** 2
    K = np.diag((2 * np.pi * MN[:, 0] + theta) ** 2
                + (.5 + 2 * np.pi * MN[:, 1]) ** 2)
    tail = min((2 * np.pi * (N + 1) - abs(theta)) ** 2 + .25,
               (2 * np.pi * (N + 1) - .5) ** 2 + theta ** 2)
    denominator = tail - 17 * high
    assert denominator > 0
    upper_error = high * EPS_M + high ** 2 / denominator * EPS_G
    for M, G in templates:
        # lambda_1(T(low)+low*EPS_M*I) < 0 gives a true trial direction.
        eig1 = eigh(K - low * M, subset_by_index=[0, 0],
                    check_finite=False)[0][0]
        # lambda_2(Tminus(high)-upper_error*I) > 0 bounds full inertia <= 1.
        eig2 = eigh(K - high * M - high ** 2 / denominator * G,
                    subset_by_index=[0, 1], check_finite=False)[0][1]
        negative_margin = -eig1 - low * EPS_M
        positive_margin = eig2 - upper_error
        assert negative_margin > 0 and positive_margin > 0
        lower_min = min(lower_min, negative_margin)
        upper_min = min(upper_min, positive_margin)
    denominator_min = min(denominator_min, denominator)
    lambda_max = max(lambda_max, high)
    upper_error_max = max(upper_error_max, upper_error)

# The proved inequality |sqrt(lambda_j(theta))-sqrt(lambda_j(phi))|
# <= |theta-phi| extends both midpoint signs to every point of each panel.
# y-reflection composed with conjugation gives the same bands at -theta.
# Thus both full periodic leads have no spectrum in [1.318^2, 2.375^2].
print(json.dumps({
    "mode_dimension": DIM, "leads": 2, "common_panels": len(END) - 1,
    "phase_coverage": "[-pi, pi], exact consecutive integer endpoints + symmetry",
    "coefficient_error": EPS_B_ENTRY, "mass_matrix_error": EPS_M,
    "G_matrix_error": EPS_G, "max_upper_lambda": lambda_max,
    "min_tail_denominator": denominator_min,
    "max_upper_matrix_error": upper_error_max,
    "min_lower_negative_margin": lower_min,
    "min_upper_positive_margin": upper_min,
    "distance_to_original_window_at_least": "0.005276 (exact decimal)",
    "rounding": "excluded by the problem; no interval arithmetic used"
}, indent=2))
```

The expected smallest sign margins are approximately $1.3972238392\times10^{-4}$ and $7.5205045129\times10^{-3}$. A later rounding-inclusive implementation should certify the same finite signs; it need not change the analytic tail or phase-covering proofs.











