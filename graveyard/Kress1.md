<!-- Remark: 这份笔记的T-block: Kress / Maue form for the difference kernel一节存在问题, 直接导致了tep_local_scan3.m实现错误 -->

## Kussmaul-Martensen quadrature rule
Given a kernel
$$
N(s,t) = \log(4\sin^2\frac{s-t}{2})N_1(s,t) + N_2(s,t)
$$
then if $t_j = \frac{j}{N}2\pi$, one has
$$
\int_0^{2\pi}\log(4\sin^2\frac{s-t}{2})g(t)dt \approx \sum_{j = 1}^N R_j^{(N)}(s)g(t_j)
$$
where
$$
R_j^{(N)} = -\sum_{m = 1}^{N/2-1} \frac{2}{m}\cos m(s - t_j) - \frac{2}{N}\cos \frac{N}{2}(s - t_j)
$$
and the matrix element
$$
N(t_k, t_j) = R_{|j-k|}^{(0)}N_1(t_k, t_j) + N_2(t_k,t_j)
$$

## T-block: Kress / Maue form for the difference kernel

For the hypersingular block, start from the Maue identity
$$
(T_\kappa \varphi)(x)
=
\kappa^2 \int_\Gamma \Phi_\kappa(x,y)\,(n_x\cdot n_y)\,\varphi(y)\,ds_y
-
\partial_{s_x}\int_\Gamma \Phi_\kappa(x,y)\,\partial_{s_y}\varphi(y)\,ds_y.
$$

For a $2\pi$-periodic parametrization $z(t)$ of the smooth boundary, Kress rewrites ~~the kernel~~上面这个核kernel的第二个部分 in the form
$$
N(t,\tau)
=
\frac{1}{2\pi}\cot\frac{\tau-t}{2}
+
N_1(t,\tau)\log\!\left(4\sin^2\frac{t-\tau}{2}\right)
+
N_2(t,\tau),
$$
where the Cauchy term is treated separately, and $N_1,N_2$ are smooth. 

For the free-space Helmholtz kernel at wavenumber $\kappa$, the logarithmic coefficient is
$$
N_{1,\kappa}(t,\tau)
=
-\frac{\kappa}{2\pi}\,
\frac{ z'(t)\cdot\bigl(z(\tau)-z(t)\bigr)}{r(t,\tau)}
\,J_1\!\bigl(\kappa r(t,\tau)\bigr),
\qquad
r(t,\tau)=|z(t)-z(\tau)|.
$$
This is the coefficient of the logarithmic singularity after Kress' splitting. 

The smooth remainder is
$$
N_{2,\kappa}(t,\tau)
=
N_\kappa(t,\tau)
-
\frac{1}{2\pi}\cot\frac{\tau-t}{2}
-
N_{1,\kappa}(t,\tau)\log\!\left(4\sin^2\frac{t-\tau}{2}\right).
$$
Again, this is exactly the remainder after removing the Cauchy term and the logarithmic term. 

For the diagonal limit, Kress gives
$$
N_{2,\kappa}(t,t)
=
\frac{1}{2\pi}
\frac{ z_1'(t)z_1''(t)+z_2'(t)z_2''(t)}
      {[z_1'(t)]^2+[z_2'(t)]^2}.
$$
In the scanned/OCR text the equality sign is corrupted, but from the context this is the diagonal value of $N_2(t,t)$. 

Moreover,
$$
N_{1,\kappa}(t,t)=0.
$$
This follows from the explicit formula for $N_{1,\kappa}$ by a local expansion of $z(\tau)-z(t)$ as $\tau\to t$.

### Difference kernel for our problem

Write the exterior quasi-periodic Green function as
$$
G_k^{\mathrm{qp}}(x,y)=\Phi_k(x,y)+R_k(x,y),
$$
where $R_k$ is the regular proxy/MFS remainder near $x=y$.

For the Müller difference block,
$$
T^\Delta := T_{nk}^{\mathrm{free}} - T_k^{\mathrm{qp}},
$$
the Cauchy principal value term cancels, so the final parameterized kernel has the form
$$
N^\Delta(t,\tau)
=
N_1^\Delta(t,\tau)\log\!\left(4\sin^2\frac{t-\tau}{2}\right)
+
N_2^\Delta(t,\tau).
$$

Here the logarithmic coefficient is just the free-space difference:
$$
N_1^\Delta(t,\tau)
=
N_{1,nk}(t,\tau)-N_{1,k}(t,\tau),
$$
since the proxy/MFS remainder is smooth and contributes only to the smooth part. In particular,
$$
N_1^\Delta(t,t)=0.
$$

The smooth part is
$$
N_2^\Delta(t,\tau)
=
N_{2,nk}(t,\tau)-N_{2,k}(t,\tau)-N_{R_k}(t,\tau),
$$
where $N_{R_k}$ denotes the contribution coming from the regular part $R_k$.
Equivalently: **all proxy/MFS terms are absorbed into $N_2^\Delta$**.

On the diagonal,
$$
N_2^\Delta(t,t)
=
N_{2,nk}(t,t)-N_{2,k}(t,t)-N_{R_k}(t,t).
$$

## Discretization

For the logarithmic part, use the Kussmaul-Martensen rule
$$
\int_0^{2\pi}\log\!\left(4\sin^2\frac{s-t}{2}\right)g(t)\,dt
\approx
\sum_{j=1}^N R_j^{(N)}(s)\,g(t_j),
\qquad
t_j=\frac{2\pi j}{N},
$$
with
$$
R_j^{(N)}(s)
=
-\sum_{m=1}^{N/2-1}\frac{2}{m}\cos m(s-t_j)
-\frac{2}{N}\cos\frac{N}{2}(s-t_j).
$$

For the smooth part, use the periodic trapezoid rule with weight
$$
h = \frac{2\pi}{N}.
$$

Therefore the T-difference matrix is assembled as
$$
A^{(T)}_{ij}
=
R_j^{(N)}(t_i)\,N_1^\Delta(t_i,t_j)
+
h\,N_2^\Delta(t_i,t_j),
\qquad i,j=1,\dots,N,
$$
with
$$
N_1^\Delta(t_i,t_i)=0,
\qquad
N_2^\Delta(t_i,t_i)=\text{analytic diagonal limit}.
$$

## Pseudocode

```text
Given nodes t_i = 2π i / N and geometry z(t_i), z'(t_i), z''(t_i):

1. Build Kress logarithmic weights Rlog(i,j)
2. Set h = 2π / N

3. For each pair (i,j):
   if i ≠ j:
      compute r = |z_i - z_j|

      compute free-space N1 at nk:
         N1_int = N1_formula(kappa = n*k, i, j)

      compute free-space N1 at k:
         N1_ext_center = N1_formula(kappa = k, i, j)

      set
         N1diff(i,j) = N1_int - N1_ext_center

      compute free-space smooth remainder N2 at nk:
         N2_int = N2_formula(kappa = n*k, i, j)

      compute free-space smooth remainder N2 at k:
         N2_ext_center = N2_formula(kappa = k, i, j)

      compute proxy/MFS smooth contribution:
         N2_proxy = N2_proxy_formula(i, j)

      set
         N2diff(i,j) = N2_int - N2_ext_center - N2_proxy

   else:
      N1diff(i,i) = 0

      N2_int_diag = N2_diag_formula(kappa = n*k, i)
      N2_ext_center_diag = N2_diag_formula(kappa = k, i)
      N2_proxy_diag = N2_proxy_diag_formula(i)

      N2diff(i,i) = N2_int_diag - N2_ext_center_diag - N2_proxy_diag

4. Assemble T-block:
   A_T(i,j) = Rlog(i,j) * N1diff(i,j) + h * N2diff(i,j)