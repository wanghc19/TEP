# Frozen analytic derivative derivation

## Coordinates and the single project sign

Let

$$
\Delta x=x_t-x_s,\qquad X=|\Delta x|,\qquad
s_x=\operatorname{sign}(\Delta x),\qquad Y=y_t-y_s.
$$

The analytic Linton calculation is performed in $(X,Y)$. Its internal fields
are named `GX_abs`, `GY`, `GXX_abs`, `GXY_abs`, and `GYY`; these names never
denote physical signed derivatives. After adding reciprocal and real-space
terms, every field receives the one frozen project conversion factor $-1$.
Only then is the physical target mapper applied:

$$
G_x=s_xG_X,\qquad G_y=G_Y,\qquad
G_{xx}=G_{XX},\qquad G_{xy}=s_xG_{XY},\qquad G_{yy}=G_{YY}.
$$

The derivative API rejects $\Delta x=0$. In particular, the negative-$\Delta
x$ holdout must close simultaneously against finite differences and Rayleigh
sums for both $G_x$ and $G_{xy}$.

## Reciprocal derivatives

For $\beta_m=\beta+2\pi m/d$, use the outgoing branch through $q_m$, and set
$h=a/d$, $b_m=q_md/(2a)$, and $u_{m,\epsilon}=b_m+\epsilon hX$ for
$\epsilon\in\{-1,+1\}$. With

$$
\chi(u)=\operatorname{erfc}'(u)=-\frac{2}{\sqrt{\pi}}e^{-u^2},
\qquad \chi'(u)=-2u\chi(u),
$$

define

$$
F_{m,\epsilon}=e^{\epsilon q_mX}\operatorname{erfc}(u_{m,\epsilon}),
$$

$$
\partial_XF_{m,\epsilon}
=\epsilon e^{\epsilon q_mX}
\left[q_m\operatorname{erfc}(u_{m,\epsilon})+h\chi(u_{m,\epsilon})\right],
$$

and

$$
\partial_{XX}F_{m,\epsilon}
=e^{\epsilon q_mX}\left[
q_m^2\operatorname{erfc}(u_{m,\epsilon})
+2q_mh\chi(u_{m,\epsilon})
-2h^2u_{m,\epsilon}\chi(u_{m,\epsilon})\right].
$$

Writing $B_m=F_{m,+1}+F_{m,-1}$, the reciprocal term before the global project
sign is

$$
S_{\mathrm{L}}=-\frac{1}{4d}\sum_m
\frac{e^{\mathrm{i}\beta_mY}}{q_m}B_m.
$$

Its $X$ derivatives replace $B_m$ with $\partial_XB_m$ or
$\partial_{XX}B_m$. Its $Y$, $XY$, and $YY$ derivatives multiply the
corresponding summands by $\mathrm{i}\beta_m$, $\mathrm{i}\beta_m$, and
$-\beta_m^2$, respectively.

## Real-space derivatives and explicit exceptional orders

For image $j$, set $w_j=Y-jd$, $\lambda=(a/d)^2$, and
$z_j=\lambda(X^2+w_j^2)$. Define

$$
E_0(z)=\frac{e^{-z}}{z},
\qquad
E_{-1}(z)=e^{-z}\left(\frac{1}{z}+\frac{1}{z^2}\right).
$$

For $c_n=(kd/(2a))^{2n}/n!$ and
$H(z)=\sum_{n=0}^Nc_nE_{n+1}(z)$, the identity
$E_p'(z)=-E_{p-1}(z)$ gives

$$
H'(z)=-\sum_{n=0}^Nc_nE_n(z),
\qquad
H''(z)=\sum_{n=0}^Nc_nE_{n-1}(z).
$$

Thus the $n=0$ entries of $H'$ and $H''$ explicitly use $E_0$ and $E_{-1}$.
For $z_X=2\lambda X$, $z_Y=2\lambda w_j$, and
$z_{XX}=z_{YY}=2\lambda$, ordinary chain rules give all five derivatives.
The real term before the project sign is

$$
R_{\mathrm{L}}=-\frac{1}{4\pi}\sum_j e^{\mathrm{i}\beta jd}H(z_j).
$$

## Source and target derivatives

With the physical target gradient and Hessian,

$$
\nabla_sG=-\nabla_tG,\qquad
H_{ss}=H_{tt},\qquad H_{ts}=-H_{tt}.
$$

These identities and
$G_{xx}+G_{yy}+k^2G=0$ are mandatory point gates.

## Four raw wall actions

Let $(n_{sx},n_{sy})$ be the circle source normal and let
$n_{tx}=-1$ on the left wall and $n_{tx}=+1$ on the right wall. From physical
target derivatives,

$$
G_{n_s}=-(G_xn_{sx}+G_yn_{sy}),\qquad
G_{n_t}=n_{tx}G_x,
$$

$$
G_{n_tn_s}=n_{tx}(-G_{xx}n_{sx}-G_{xy}n_{sy}).
$$

For $\eta=[\tau;\mu]=[\tau;-\sigma]$, weighted source samples produce

$$
D_{\mathrm{wall}}=G_{n_s}(\tau w)-G(\mu w),
\qquad
N_{\mathrm{wall}}=G_{n_tn_s}(\tau w)-G_{n_t}(\mu w).
$$

Consequently SLP-D, SLP-N, DLP-D, and DLP-N use the matrices
$-G$, $-G_{n_t}$, $G_{n_s}$, and $G_{n_tn_s}$. Since every wall-source pair
has $n_{tx}=s_x$, both-wall magnitude forms are

$$
\mathrm{SLP\mbox{-}N}=-G_X,
\qquad
\mathrm{DLP\mbox{-}N}=-n_{sx}G_{XX}-n_{sy}G_{XY}.
$$

The Rayleigh path first extracts the raw Dirichlet coefficient $D_m$ from
$[0;\rho]$ for SLP or $[\rho;0]$ for DLP. Its raw outward Neumann oracle on
both walls is

$$
N_m=(\mathrm{i}\gamma_m)D_m.
$$

No mandatory comparison divides by $\mathrm{i}\gamma_m$.

## Frozen finite-difference oracle

The independent value-only Ewald stencil uses offsets
$\{-2,-1,0,1,2\}$ with first-derivative weights
$(1,-8,0,8,-1)/(12h)$ and pure second-derivative weights
$(-1,16,-30,16,-1)/(12h^2)$. The mixed derivative uses the tensor product of
the first-derivative weights. Every stencil asserts $2h<|\Delta x|$.

For raw estimates $D_r$ at $h_r=d\,2^{-r}$, $r=7,8,9,10$, the fixed
Richardson sequence is

$$
R_r=\frac{16D_{r+1}-D_r}{15},\qquad r=7,8,9.
$$

All raw estimates and $R_7$ are trend evidence. The sole authority is $R_9$;
the mandatory self check is the $R_8$ to $R_9$ change. This rule applies to
every physical gradient and Hessian component without component-wise tuning.

Source gradients are not certified by assigning a minus sign to target
gradients. Separate value-only stencils perturb $(x_s,y_s)$, and separate
target/source tensor stencils approximate $G_{x_tx_s}$ and $G_{x_ty_s}$.
Mixed-order symmetry is also checked independently by differentiating the
analytic $G_x$ samples in $y_t$ and the analytic $G_y$ samples in $x_t$, with
the same fixed Richardson rule.
