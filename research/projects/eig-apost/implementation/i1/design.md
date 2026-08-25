# I1 discrete $A_{\mathrm{def}}$ design

## 1. Status, scope, and authority

This document freezes the discrete design for the conditional center BIE--DtN family
$\mathcal F_{\mathrm{BIE}}(k)$. Only after the kernel--field and regular-approximation
hypotheses are met may that family represent the physical $\mathcal F(k)$. This document
contains no numerical result and authorizes no DtN evaluation, locator, contour, or root
isolation.

The current physical I1 model has identical sharp-disk periodic leads and a homogeneous
missing center column. Consequently its center density dimension is

$$
n=0.
$$

The $n>0$ center-BIE formula below is a conditional extension for a future inclusion in the
center column. It does not enlarge the current physical claim and remains subject to the
kernel--field bridge in OP-M0-2.

The authority hierarchy is:

1. the half-guide PDE defines the exact $\Lambda_\pm(k)$;
2. the continuous center problem and those exact maps define $\mathcal F(k)$;
3. BIE/Fourier discretization and ordered QZ approximate its ingredients;
4. $A_{\mathrm{def}}(k)$ is only a matrix representation of the resulting discrete family;
5. balancing is only a coordinate change.

Neither a finite trace subspace nor QZ is used to define the exact DtN.

## 2. Fourier trial and test coordinates

Let the periodic wall coordinate be $y\in(0,L_y)$ and freeze

$$
\psi_m(y)=L_y^{-1/2}\exp(\mathrm{i}\beta_m y),
\qquad
\beta_m=\beta+\frac{2\pi m}{L_y},
\qquad m=-M,\ldots,M.
$$

Write

$$
K=K_M=2M+1,
\qquad
\gamma_m(k)^2=k^2-\beta_m^2,
\qquad
\Gamma(k)=\operatorname{diag}(\gamma_m(k)).
$$

The branch of every $\gamma_m$ is anchored once at a real projected-gap point and continued
on one declared complex disk. Wood points are excluded. The physical wall order $M$ is not
the proxy evaluator order $M_{\mathrm{pw}}$ and is not automatically certified by the
manufactured-density value $M_{\mathrm{trace}}=48$.

Dirichlet and Neumann coefficient norms represent $H^{1/2}_\beta$ and
$H^{-1/2}_\beta$:

$$
\|d\|_{D,M}^2=\sum_{m=-M}^{M}\langle\beta_m\rangle |d_m|^2,
\qquad
\|n\|_{N,M}^2=\sum_{m=-M}^{M}\langle\beta_m\rangle^{-1}|n_m|^2,
$$

where $\langle t\rangle=(1+t^2)^{1/2}$ in the current nondimensional variables. The
implementation must return the corresponding diagonal Gram matrices
$G_{D,M}$ and $G_{N,M}$, not only Euclidean arrays. Across orders, trial prolongation is
zero-padding in this fixed ordering. Freeze the coefficient duality

$$
\langle n,d\rangle_{N,D}=d^*n.
$$

For $M'>M$, let $P_{M\to M'}^D$ be Dirichlet zero-padding. The dual-compatible Neumann
restriction is

$$
R_{M'\to M}^N=(P_{M\to M'}^D)^*,
\qquad
\langle n',P_{M\to M'}^Dd\rangle_{N,D}
=\langle R_{M'\to M}^Nn',d\rangle_{N,D}.
$$

In words, $P_{M\to M'}^D$ embeds the retained coefficients for $M'>M$ by zero padding;
the displayed identity, rather than an independently chosen Euclidean truncation, defines
the Neumann restriction.

## 3. Normals and amplitude convention

The normals point from the center column into the leads:

$$
\nu_-=-e_x,
\qquad
\nu_+=e_x.
$$

At either wall, $a$ denotes the positive-$x$ Rayleigh amplitude and $b$ the negative-$x$
amplitude. Thus the wall Cauchy data are

$$
D=a+b,
\qquad
N_-=-\mathrm{i}\Gamma(a-b),
\qquad
N_+=\mathrm{i}\Gamma(a-b).
$$

The $N_-$ convention is the center-outward convention and is the negative of a left
half-guide-outward convention. No sign may be inferred from mirror symmetry.

## 4. Continuous-to-discrete correspondence

For a center trial object $x$, the conditional continuous BIE family is

$$
\mathcal F_{\mathrm{BIE}}(k)x=
\begin{bmatrix}
\mathcal B(k)x\\
\mathcal N_-(k)x-\Lambda_-(k)\mathcal D_-(k)x\\
\mathcal N_+(k)x-\Lambda_+(k)\mathcal D_+(k)x
\end{bmatrix}.
$$

After choosing BIE trial/test bases, Fourier restriction, and discrete half-guide maps, the
unbalanced discrete operator is

$$
\mathcal F_{h,M}(k):\mathcal X_{c,h,M}\longrightarrow
\mathcal Y_{B,h,M}\times\mathbb C_N^K\times\mathbb C_N^K.
$$

Its matrix in the frozen bases is $A_{\mathrm{def},h,M}(k)$. For the current empty center,
$\mathcal Y_{B,h,M}$ and the density part of $\mathcal X_{c,h,M}$ are absent, and the center
solution is represented exactly within the retained homogeneous Rayleigh subspace. Calling
this matrix a representation of the physical $\mathcal F(k)$ remains conditional on the
continuous kernel--field and regular-approximation results in OP-M0-1--OP-M0-4.

## 5. One-cell scattering pair

For one ordinary lead cell, freeze

$$
\begin{bmatrix}b^L\\a^R\end{bmatrix}
=
\begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
\begin{bmatrix}a^L\\b^R\end{bmatrix},
$$

where every scattering block is $K\times K$. With
$z_L=(a^L,b^L)^{\mathsf T}$ and $z_R=(a^R,b^R)^{\mathsf T}$, define

$$
A_{\mathrm{sc}}=
\begin{bmatrix}-R_L&I\\T_{LR}&0\end{bmatrix},
\qquad
B_{\mathrm{sc}}=
\begin{bmatrix}0&T_{RL}\\I&-R_R\end{bmatrix},
\qquad
A_{\mathrm{sc}}z_L=B_{\mathrm{sc}}z_R.
$$

The Floquet relation $z_R=\lambda z_L$ gives the generalized pencil

$$
A_{\mathrm{sc}}z=\lambda B_{\mathrm{sc}}z.
$$

The pair is $2K\times2K$. Its phase planes, port normalization, source geometry, and all
scattering-block fingerprints are required metadata.

## 6. Projective ordered QZ and left/right graphs

### 6.1 Projective classification

Represent a generalized eigenvalue by a projective pair $(\alpha,\vartheta)$ satisfying
$\lambda=\alpha/\vartheta$ when $\vartheta\ne0$. After the common pencil scaling in
Section 6.3, first compute

$$
r_j=(|\alpha_j|^2+|\vartheta_j|^2)^{1/2}.
$$

Let $\epsilon_{\mathrm{qz,raw}}$ be the normalized backward residual of the unreordered QZ
pair and freeze

$$
\tau_{\mathrm{proj}}
=\max(100\epsilon_{\mathrm{mach}},10\epsilon_{\mathrm{qz,raw}}).
$$

Thus the floating-point uncertainty band contains the observed QZ backward error. The
normalization

$$
(\widehat\alpha_j,\widehat\vartheta_j)
=(\alpha_j,\vartheta_j)/r_j
$$

is performed only after $r_j>\tau_{\mathrm{proj}}$ passes. The following policy is frozen:

- the pencil must be regular;
- $r_j\le\tau_{\mathrm{proj}}$ is a numerically indeterminate pair and is a failure;
- a regular infinite pair
  $|\widehat\vartheta_j|\le\tau_{\mathrm{proj}}$ and
  $|\widehat\alpha_j|>\tau_{\mathrm{proj}}$ is allowed in the positive-$x$
  unstable cluster;
- a pair satisfying
  $\bigl||\widehat\alpha_j|-|\widehat\vartheta_j|\bigr|
  \le\tau_{\mathrm{proj}}$ is numerically neutral and is a failure;
- at the real seed, right decay has exactly $K$ pairs with
  $|\widehat\alpha|<|\widehat\vartheta|-\tau_{\mathrm{proj}}$;
- at the real seed, left decay has exactly $K$ pairs with
  $|\widehat\alpha|>|\widehat\vartheta|+\tau_{\mathrm{proj}}$.

This replaces any rule that bans all infinite pairs.

### 6.2 Two ordered factorizations

The right graph is obtained from the stable cluster of $(A_{\mathrm{sc}},B_{\mathrm{sc}})$;
its generalized Schur vector is the ordinary-cell left state
$z_L=(a^L,b^L)^{\mathsf T}$. The left graph is obtained independently from the stable
cluster of the reversed relation

$$
B_{\mathrm{sc}}z_R=\mu A_{\mathrm{sc}}z_R,
\qquad \mu=1/\lambda,
$$

whose generalized Schur vector is the ordinary-cell right state
$z_R=(a^R,b^R)^{\mathsf T}$ at the interface touching the left lead. A regular
$\lambda=\infty$ pair is the regular $\mu=0$ pair. No multiplication by $\lambda$, inverse
multiplier, or propagation of an original-pair unstable $z_L$ is permitted in the left
construction. This two-pass rule avoids a singular reference-plane transport and does not
use trailing Schur vectors from one ordering as the other physical graph.

Write the two interface-ready amplitude frames as

$$
Z_+=\begin{bmatrix}A_s\\B_s\end{bmatrix}\in\mathbb C^{2K\times K},
\qquad
Z_-=\begin{bmatrix}A_u\\B_u\end{bmatrix}
\in\mathbb C^{2K\times K}.
$$

The pair constructor must return the state-plane labels `LEFT_CELL_WALL` and
`RIGHT_CELL_WALL`. A mismatch is a hard failure and may not be repaired by an unrecorded
phase helper.

The modulus classification is used only at the real seed to select two isolated clusters.
On a declared complex disk, these same clusters are continued by deflating-subspace overlap
and spectral separation from the seed; they are never reselected pointwise by modulus.
Later projective counts and unit-circle margins are only no-crossing diagnostics. Loss of
count, separation, or overlap makes the entire disk unavailable instead of changing cluster
membership.

### 6.3 Separation contract

Scale the pair once by

$$
\rho_{\mathrm{sc}}=
\bigl(\|A_{\mathrm{sc}}\|_F^2+\|B_{\mathrm{sc}}\|_F^2\bigr)^{1/2}
$$

before diagnostic norms. The original and reversed ordered QZ passes are treated
separately. For $\sigma\in\{+,-\}$, let $(S_{\sigma,s},T_{\sigma,s})$ be the leading selected
stable block and $(S_{\sigma,c},T_{\sigma,c})$ its trailing complementary diagonal block
from the same pencil and the same QZ pass. The trailing Schur vectors are not used as the
opposite physical graph; their diagonal blocks are used only for separation.

Define the two dimensionless generalized Sylvester operators

$$
\begin{aligned}
\mathscr L_{\sigma,u}(R,L)
&=(S_{\sigma,s}R-LS_{\sigma,c},\;
T_{\sigma,s}R-LT_{\sigma,c}),\\
\mathscr L_{\sigma,l}(R,L)
&=(S_{\sigma,c}R-LS_{\sigma,s},\;
T_{\sigma,c}R-LT_{\sigma,s}),
\end{aligned}
$$

after the same pair normalization, and set

$$
\operatorname{sep}_{\sigma,u}=\sigma_{\min}(\mathscr L_{\sigma,u}),
\qquad
\operatorname{sep}_{\sigma,l}=\sigma_{\min}(\mathscr L_{\sigma,l}),
\qquad
\operatorname{sep}_\sigma
=\min(\operatorname{sep}_{\sigma,u},\operatorname{sep}_{\sigma,l}).
$$

The two directions correspond to distinct deflating-subspace sensitivities. In a small
assembly oracle they may be formed explicitly. A production backend may instead call
LAPACK `xTGSEN/xTGSYL`, but it must record `IJOB`, both `DIF` components, norm convention,
`PL/PR`, `INFO`, and the common normalization. A 1-norm or Frobenius-norm `DIF` estimate is
a numerical diagnostic, not silently identified with the exact singular-value definition
and not claimed as a theorem-level lower bound. Qualification requires either the exact
small-oracle values or a separately reviewed conservative estimate for both directions;
otherwise it returns `QUALIFIED_HALF_GUIDE_GRAPH=false`.

Let $\epsilon_{\mathrm{pair},\sigma}$ be the larger of the normalized one-cell
adjacent-level pair change and the ordered-QZ backward residual for pass $\sigma$, and
define the numerical indicator

$$
\epsilon_{\mathrm{graph},\sigma}
=\frac{\epsilon_{\mathrm{pair},\sigma}}{\operatorname{sep}_\sigma}.
$$

Before either QZ graph is called numerically qualified, require for both signs

$$
\operatorname{sep}_\sigma>100K\epsilon_{\mathrm{mach}},
\qquad
\epsilon_{\mathrm{graph},\sigma}\le10^{-9}.
$$

The second gate reserves a factor ten below the existing $10^{-8}$ coefficient target. If
the adjacent-level cell estimate or a qualified two-direction separation estimate is not
available, the object may be used only by the assembly oracle and must carry
`QUALIFIED_HALF_GUIDE_GRAPH=false`. Unit-circle distance is recorded but cannot replace
this separation contract.

The original stable Schur block additionally requires $T_{+,s}$ to be safely solvable if a
forward propagator $T_{+,s}^{-1}S_{+,s}$ is requested. The reversed stable graph needs no
inverse multiplier. Neither propagator is required merely to form a Cauchy graph.

## 7. Cauchy blocks and analytic frame transport

Using the already frozen left-wall state $Z_+$ and right-wall state $Z_-$, define

$$
\begin{aligned}
D_{s,+}&=A_s+B_s,&
N_{s,+}&=\mathrm{i}\Gamma(A_s-B_s),\\
D_{s,-}&=A_u+B_u,&
N_{s,-}&=-\mathrm{i}\Gamma(A_u-B_u).
\end{aligned}
$$

Every block is $K\times K$. To eliminate arbitrary QZ column gauges on a complex disk,
choose at the seed a fixed row-selection matrix $H_\pm\in\mathbb C^{K\times2K}$ such that
$H_\pm Z_\pm(k_0)$ is safely invertible, then freeze

$$
\widehat Z_\pm(k)=Z_\pm(k)[H_\pm Z_\pm(k)]^{-1}.
$$

The seed row set may be chosen by rank-revealing QR, but it is never repivoted inside the
disk. The normalization is invariant under $Z_\pm(k)\mapsto Z_\pm(k)T(k)$ for nonsingular
$T(k)$. Seed-cluster continuation occurs before this normalization. A loss of cluster
overlap or fixed-row overlap is a disk-level factor-ledger failure. Pointwise
SVD/Procrustes phase alignment is forbidden because it need not preserve holomorphic
dependence.

## 8. Dirichlet, Robin, and full-graph realizations

### 8.1 Safe Dirichlet chart

When the weighted Dirichlet projection is safe, define

$$
\Lambda_{\pm,h,M}=N_{s,\pm}D_{s,\pm}^{-1}.
$$

It is formed by a right linear solve, never by `inv` or `pinv`. Define the graph-coordinate
Gram matrix and weighted Dirichlet chart matrix by

$$
G_{G,\pm}=D_{s,\pm}^*G_{D,M}D_{s,\pm}
+N_{s,\pm}^*G_{N,M}N_{s,\pm},
\qquad
\overline D_{s,\pm}=G_{D,M}^{1/2}D_{s,\pm}G_{G,\pm}^{-1/2}.
$$

The square roots in this line are used only for conditioning diagnostics; they do not
renormalize the analytic frame. A reciprocal condition number alone is insufficient: for
$K=1$, $D=\varepsilon$ and $N=1$ give a well-conditioned scalar $D$ but an unsafe, nearly
vertical graph. Freeze the distinct quantities

$$
\operatorname{margin}_D(D_{s,\pm})
=\sigma_{\min}(\overline D_{s,\pm}),
\qquad
\operatorname{cond}_D(D_{s,\pm})
=\frac{\sigma_{\max}(\overline D_{s,\pm})}
{\sigma_{\min}(\overline D_{s,\pm})}.
$$

A chart is safe only if

$$
\operatorname{margin}_D(D_{s,\pm})>100K\epsilon_{\mathrm{mach}},
\qquad
\frac{\epsilon_{\mathrm{graph},\pm}}
{\operatorname{margin}_D(D_{s,\pm})}\le10^{-9},
\qquad
\operatorname{cond}_D(D_{s,\pm})\epsilon_{\mathrm{mach}}\le10^{-9},
$$

where $\epsilon_{\mathrm{graph},\pm}$ is the separated-subspace error indicator from the
previous section. The margin gate controls amplification from a nearly vertical graph;
the condition gate separately controls the right solve. The same chart must remain safe
over the declared disk; it cannot switch pointwise.

### 8.2 Fixed Robin chart

If the Dirichlet chart is unsafe, freeze

$$
J_M=\operatorname{diag}(\langle\beta_m\rangle),
\qquad \eta=1
$$

in the current nondimensional units and test

$$
H_{\eta,\pm}=N_{s,\pm}+\mathrm{i}\eta J_MD_{s,\pm}.
$$

For the Robin chart use

$$
\overline H_{\eta,\pm}
=G_{N,M}^{1/2}H_{\eta,\pm}G_{G,\pm}^{-1/2}
$$

in the same graph-coordinate normalization. Record

$$
\operatorname{margin}_R(H_{\eta,\pm})
=\sigma_{\min}(\overline H_{\eta,\pm}),
\qquad
\operatorname{cond}_R(H_{\eta,\pm})
=\frac{\sigma_{\max}(\overline H_{\eta,\pm})}
{\sigma_{\min}(\overline H_{\eta,\pm})},
$$

and require

$$
\operatorname{margin}_R(H_{\eta,\pm})>100K\epsilon_{\mathrm{mach}},
\qquad
\frac{\epsilon_{\mathrm{graph},\pm}}
{\operatorname{margin}_R(H_{\eta,\pm})}\le10^{-9},
\qquad
\operatorname{cond}_R(H_{\eta,\pm})\epsilon_{\mathrm{mach}}\le10^{-9}.
$$

Only then define

$$
R_{\eta,\pm}=
(N_{s,\pm}-\mathrm{i}\eta J_MD_{s,\pm})H_{\eta,\pm}^{-1}.
$$

For center Cauchy row matrices $(C_D,C_N)$, the port row is

$$
(C_N-\mathrm{i}\eta J_MC_D)
-R_{\eta,\pm}(C_N+\mathrm{i}\eta J_MC_D).
$$

The choice $\eta=1$ is frozen before numerical inspection. A dimensional implementation
must record the reference inverse length used in $J_M$.

### 8.3 Full Cauchy relation

If neither fixed chart is safe, retain the coefficient $c_\pm\in\mathbb C^K$ and impose

$$
C_Dx=D_{s,\pm}c_\pm,
\qquad
C_Nx=N_{s,\pm}c_\pm.
$$

No DtN is formed. This is a discrete Cauchy relation; it is not renamed as an exact
continuous DtN.

## 9. Current empty-center assembly

Let the center walls be $X_L<X_R$, $W=X_R-X_L$, and freeze

$$
E(k)=\operatorname{diag}\bigl(\exp(\mathrm{i}\gamma_m(k)W)\bigr).
$$

Use incident-wall anchored unknowns

$$
q=\begin{bmatrix}a_c^-\\b_c^+\end{bmatrix}\in\mathbb C^{2K},
$$

where $a_c^-$ enters the center at the left wall and $b_c^+$ enters it at the right wall.
The retained homogeneous center field has

$$
\begin{aligned}
D_-&=[I\ \ E]q,&
N_-&=[-\mathrm{i}\Gamma\ \ \mathrm{i}\Gamma E]q,\\
D_+&=[E\ \ I]q,&
N_+&=[\mathrm{i}\Gamma E\ \ -\mathrm{i}\Gamma]q.
\end{aligned}
$$

### 9.1 Safe-DtN matrix

With column order $(a_c^-,b_c^+)$ and row order `(left port, right port)`, the equations
$N_\pm-\Lambda_{\pm,h,M}D_\pm=0$ give

$$
\boxed{
A_{\mathrm{def}}^{D}(k)=
\begin{bmatrix}
-(\mathrm{i}\Gamma+\Lambda_{-,h,M})
&(\mathrm{i}\Gamma-\Lambda_{-,h,M})E\\
(\mathrm{i}\Gamma-\Lambda_{+,h,M})E
&-(\mathrm{i}\Gamma+\Lambda_{+,h,M})
\end{bmatrix}}
\in\mathbb C^{2K\times2K}.
$$

No $E^{-1}$ appears because both incident amplitudes are anchored at their own walls.

### 9.2 Full-graph matrix

With column order $(a_c^-,b_c^+,c_-,c_+)$ and row order
`(left D, left N, right D, right N)`, define

$$
\boxed{
A_{\mathrm{def}}^{G}(k)=
\begin{bmatrix}
I&E&-D_{s,-}&0\\
-\mathrm{i}\Gamma&\mathrm{i}\Gamma E&-N_{s,-}&0\\
E&I&0&-D_{s,+}\\
\mathrm{i}\Gamma E&-\mathrm{i}\Gamma&0&-N_{s,+}
\end{bmatrix}}
\in\mathbb C^{4K\times4K}.
$$

When $D_{s,\pm}$ are invertible, exact block elimination of $c_\pm$ gives
$A_{\mathrm{def}}^{D}$. This Schur identity is a mandatory assembly oracle.

## 10. Conditional nonempty-center extension

Let $\xi\in\mathbb C^n$ be the scaled center BIE density and freeze

$$
A_c\xi+B_La_c^-+B_Rb_c^+=0,
$$

with $A_c\in\mathbb C^{n\times n}$ and $B_L,B_R\in\mathbb C^{n\times K}$. Let
$D_{\xi,\pm},N_{\xi,\pm}\in\mathbb C^{K\times n}$ be the complete density-to-wall
Fourier Cauchy maps. For

$$
x_h=(\xi,a_c^-,b_c^+)\in\mathbb C^{n+2K},
$$

define

$$
\begin{aligned}
C_{D,-}&=[D_{\xi,-}\ \ I\ \ E],&
C_{N,-}&=[N_{\xi,-}\ \ -\mathrm{i}\Gamma\ \ \mathrm{i}\Gamma E],\\
C_{D,+}&=[D_{\xi,+}\ \ E\ \ I],&
C_{N,+}&=[N_{\xi,+}\ \ \mathrm{i}\Gamma E\ \ -\mathrm{i}\Gamma].
\end{aligned}
$$

The safe-DtN assembly is

$$
\boxed{
A_{\mathrm{def}}^{D}=
\begin{bmatrix}
A_c&B_L&B_R\\
C_{N,-}-\Lambda_{-,h,M}C_{D,-}\\
C_{N,+}-\Lambda_{+,h,M}C_{D,+}
\end{bmatrix}}
\in\mathbb C^{(n+2K)\times(n+2K)}.
$$

The full graph assembly is

$$
\boxed{
A_{\mathrm{def}}^{G}=
\begin{bmatrix}
A_c&B_L&B_R&0&0\\
D_{\xi,-}&I&E&-D_{s,-}&0\\
N_{\xi,-}&-\mathrm{i}\Gamma&\mathrm{i}\Gamma E&-N_{s,-}&0\\
D_{\xi,+}&E&I&0&-D_{s,+}\\
N_{\xi,+}&\mathrm{i}\Gamma E&-\mathrm{i}\Gamma&0&-N_{s,+}
\end{bmatrix}}
\in\mathbb C^{(n+4K)\times(n+4K)}.
$$

The current formula is its $n=0$ specialization. These center-density blocks are not
authorized for production until the old augmented-BIE representation has been requalified
against the new continuous formulation. When $D_{s,-}$ and $D_{s,+}$ are invertible,
eliminating $c_-$ and $c_+$ from the general graph matrix preserves the
$(A_c,B_L,B_R)$ row and gives the displayed general safe-DtN matrix exactly.

## 11. Complete dimension and ordering table

| Object | Rows $\times$ columns | Frozen order or meaning |
|---|---:|---|
| $R_L,T_{RL},T_{LR},R_R$ | $K\times K$ | input/output orders $m=-M{:}M$ |
| $A_{\mathrm{sc}},B_{\mathrm{sc}}$ | $2K\times2K$ | state $(a^L,b^L)$ |
| $Z_+,Z_-$ | $2K\times K$ | top $a$, bottom $b$; $Z_+$ is `LEFT_CELL_WALL`, $Z_-$ is `RIGHT_CELL_WALL` |
| $D_{s,\pm},N_{s,\pm},\Lambda_{\pm,h,M}$ | $K\times K$ | rows Fourier modes, columns graph coordinates |
| $q$ | $2K\times1$ | $(a_c^-,b_c^+)$ |
| $A_{\mathrm{def}}^D$, current | $2K\times2K$ | rows `(left N-DtN D, right N-DtN D)` |
| graph unknown, current | $4K\times1$ | $(a_c^-,b_c^+,c_-,c_+)$ |
| $A_{\mathrm{def}}^G$, current | $4K\times4K$ | rows `(left D, left N, right D, right N)` |
| $\xi$ | $n\times1$ | scaled center density; absent for current model |
| safe unknown, general | $(n+2K)\times1$ | $(\xi,a_c^-,b_c^+)$ |
| graph unknown, general | $(n+4K)\times1$ | $(\xi,a_c^-,b_c^+,c_-,c_+)$ |
| $A_{\mathrm{def}}^D$, general | $(n+2K)\times(n+2K)$ | BIE row, left port, right port |
| $A_{\mathrm{def}}^G$, general | $(n+4K)\times(n+4K)$ | BIE row, left D/N, right D/N |

## 12. Derivative, adjoint, and balancing contract

On the anchored branch,

$$
\gamma_m'(k)=\frac{k}{\gamma_m(k)},
\qquad
E'(k)=\mathrm{i}W\Gamma'(k)E(k).
$$

For a safe Dirichlet chart,

$$
\Lambda_{\pm,h,M}'=
(N_{s,\pm}'-\Lambda_{\pm,h,M}D_{s,\pm}')D_{s,\pm}^{-1}.
$$

For a port row
$P_\pm=C_{N,\pm}-\Lambda_{\pm,h,M}C_{D,\pm}$,

$$
P_\pm'=C_{N,\pm}'-\Lambda_{\pm,h,M}'C_{D,\pm}
-\Lambda_{\pm,h,M}C_{D,\pm}'.
$$

Therefore $A_{\mathrm{def}}'$ includes derivatives of $\Gamma$, $E$, every center block,
the transported QZ subspace, the selected chart, and the DtN or Robin map. A fixed-frame
analytic derivative is the target; centered finite differences and Cauchy--Riemann checks
are later validation oracles, not its definition.

This design does not yet freeze a differentiated spectral-projector or generalized
Sylvester tangent solver for $Z_\pm'$. Consequently the first assembly oracle must return
`DERIVATIVE_AVAILABLE=false` and may test derivatives only on manufactured analytic graph
frames supplied directly by the oracle. A production $A_{\mathrm{def}}'$ remains
unavailable until an analytic subspace-tangent algorithm and its residual/CR gates receive
a separate I1 review.

Store unbalanced $A_{\mathrm{def}}$ and $A_{\mathrm{def}}'$ as authoritative outputs.
Balancing must use invertible left/right maps frozen at the seed over one disk:

$$
\widetilde A=L_0A_{\mathrm{def}}R_0,
\qquad
\widetilde A'=L_0A_{\mathrm{def}}'R_0.
$$

If a later implementation makes $L$ or $R$ depend on $k$, it must use the full product
rule. Right vectors map as $x=R_0\widetilde x$; unbalanced row covectors satisfy
$\ell^*=\widetilde\ell^*L_0$. The correction quotient is evaluated with the unbalanced
$A_{\mathrm{def}}'$ and the recorded trial/test Gram maps. A Euclidean left singular vector
is not called a physical adjoint until the dual-compatible restriction and Riesz maps have
been specified.

## 13. Legacy augmented-BIE map

| Historical object | New treatment |
|---|---|
| scaled density $\xi=D_h\eta$ | retain only for the conditional nonempty-center extension; absent now |
| $A_c,B_L,B_R$ | retain conditionally after new kernel--field qualification; absent now |
| density-to-wall extractors | the historical scaled extractors satisfy $D_{\xi,-}=\mathcal E_L$, $N_{\xi,-}=+\mathrm{i}\Gamma\mathcal E_L$, $D_{\xi,+}=\mathcal E_R$, $N_{\xi,+}=+\mathrm{i}\Gamma\mathcal E_R$ at the frozen phase planes; a direct wall evaluator replaces rather than aliases them |
| direct cross-wall phase | retain as $E$; same-side direct reflection remains zero in homogeneous center |
| incoming order $(a_c^-,b_c^+)$ | retain |
| center outgoing amplitudes | eliminate into Cauchy rows |
| four finite-tail far amplitudes | discard from the primary formulation |
| finite-tail scattering and terminal Dirichlet rows | replace by QZ Cauchy graph/DtN/Robin rows |
| old $(n+8K)$ augmented matrix | superseded; current graph has size $4K$, general graph $n+4K$ |
| doubling level $N_j=2^j$ and finite-tail estimator | legacy cross-check only |
| density scaling, sign, raw/reduced, factor and failure ledgers | reuse as validation patterns |

At $M=5$, $K=11$ and the current graph matrix is $44\times44$, like the historical empty
defect matrix. Equality of size is not equality of method: the half-guide rows and anchoring
are different, so historical numerical values do not certify this design.

The extractor identities in the table use the scaled density coordinate
$\xi=D_h\eta$ and therefore
$\mathcal E_{L/R}=\mathcal E_{L/R}^{\mathrm{phys}}D_h^{-1}$. They also require the same
Fourier ordering and wall phase origins as $E$. Any new direct wall evaluator must verify
these identities before it may replace the historical extractor path.

## 14. Required implementation interface

The next Engineer stage, if authorized, must be test-local and split into pure constructors:

1. `cell_pair`: returns $A_{\mathrm{sc}},B_{\mathrm{sc}}$, block order, reference planes,
   fingerprints, solve residuals, and level metadata.
2. `halfguide_graph`: returns the original-pair $z_L$ frame and reversed-pair $z_R$ frame,
   their exact state-plane labels, $D_{s,\pm},N_{s,\pm}$, projective pair ledger, counts,
   QZ residuals, two-direction separation definitions/values, fixed-frame overlaps, and
   `qualified` booleans. It never silently drops a pair.
3. `halfguide_chart`: returns exactly one frozen realization label
   `DIRICHLET_DTN`, `ROBIN_RTR`, or `CAUCHY_RELATION`, together with condition/error gates.
4. `center_blocks`: returns the current $n=0$ Cauchy rows, or the conditional $n>0$ BIE and
   complete wall maps, plus $\Gamma,E$ and their derivatives.
5. `assemble_a_def`: returns the unbalanced matrix, row/column group offsets, dimensions,
   Gram matrices, and an availability/failure ledger. It returns a derivative only when a
   separately qualified graph-tangent provider sets `DERIVATIVE_AVAILABLE=true`.
6. `balance_a_def`: returns frozen invertible coordinate maps separately from the
   unbalanced object; it never overwrites the latter.

No constructor may call `pinv`, silently truncate rank, switch solver, switch chart,
repivot the analytic frame inside a disk, or reorder modes without a recorded permutation.
Unavailable objects must return an explicit failure label and no fabricated matrix.

## 15. First assembly-oracle acceptance contract

The first permitted experiment contains no locator. It must test:

- dimensions, row/column orders, and exact formulas for the $2K$ and $4K$ current matrices;
- Schur elimination equivalence of graph and safe-DtN forms;
- invariance under arbitrary nonsingular changes of QZ graph basis;
- acceptance of regular infinite left pairs and rejection of indeterminate/neutral pairs;
- right/left reference-plane and normal-sign mutation negatives;
- $T_{RL}/T_{LR}$ swap negative;
- absence of $E^{-1}$ and comparison with the badly scaled historical anchoring;
- agreement of Dirichlet, Robin, and full-graph kernels at manufactured safe points;
- derivative formula against multistep finite differences and complex-$k$ CR only after
  a fixed analytic frame is available;
- balanced/unbalanced kernel invariance and correct vector transport;
- common-$M$ prolongation metadata and actual-field tail diagnostics before later root use.

Passing this oracle authorizes only the next I1 qualification milestone. It does not close
OP-M0-1--OP-M0-4 and does not authorize a locator or root claim.

## 16. Theory status

### Available finite-dimensional facts

- the scattering-to-pencil algebra;
- projective generalized eigenvalue classification;
- ordered-QZ deflating subspaces and backward error;
- generalized Sylvester separation as a subspace conditioning measure;
- graph-basis invariance and the Dirichlet-chart Schur identity;
- fixed-chart derivative and simple matrix-NEP left/right correction algebra.

### Results still required from this project

- half-guide solution-operator holomorphy and one constant separated cluster on the chosen
  complex disk;
- primal/adjoint $C^1$ consistency from continuous one-cell Cauchy relation to the
  BIE/Fourier pencil;
- continuous center BIE completeness, injectivity, Fredholm index, and kernel--field bridge;
- regular spectral approximation or an appropriate graph/compact-remainder convergence
  result excluding pollution;
- safe transport from finite-dimensional graph error to the projected DtN and its
  derivative uniformly on the disk;
- physical adjoint pairing and eigentrace regularity needed for the correction;
- saturation/remainder assumptions if a next-level correction is later interpreted as
  remaining error.

These gaps block physical/root and theorem-level estimator claims. They do not invalidate
the frozen finite-dimensional algebra, which is the sole object of the next assembly oracle.
