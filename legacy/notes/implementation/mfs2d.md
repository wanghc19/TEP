# `mfs2d.md`

# 二维准周期 Green 函数的 MFS / proxy 构造

本文整理用于 Step 2a 的二维 doubly-quasiperiodic Green function 构造。目标是实现一组新的 kernel 函数：

```text
kernel.precomp_proxy2d
kernel.qpgreen2d
kernel.qpgreen2d_pairmat
```

它们用于构造完美二维周期晶体中的 Barnett-style 矩阵

$$
A_{\mathrm{QP,2d}}(\omega,\beta,\lambda),
$$

并通过扫描

$$
\lambda=e^{\mathrm{i}a}
$$

寻找

$$
\sigma_{\min}(A_{\mathrm{QP,2d}})
$$

的 dips，与当前 Bloch-mode / transfer formulation 中固定 $(\omega,\beta)$ 求出的 Floquet multiplier $\lambda$ 对比。

本文中的准周期 Green 函数仍记为

$$
G_{\mathrm{QP}}^{(\omega)}.
$$

但必须强调：这里的 $G_{\mathrm{QP}}^{(\omega)}$ 是 **二维周期** 的 Green function，同时满足 $x$ 与 $y$ 两个方向的 quasiperiodicity。它不同于已有的一维周期 `qpgreen_mfs` / `qpgreen_mfs_pairmat`。

---

## 1. 几何、phase 与目标函数

考虑矩形 unit cell

$$
U=[X_-,X_+]\times[Y_-,Y_+],
$$

其中

$$
L_x=X_+-X_-,
\qquad
 d=Y_+-Y_-.
$$

$x$ 方向的 Floquet multiplier 记为

$$
\lambda.
$$

在 Step 2a 中通常扫描

$$
\lambda=e^{\mathrm{i}a},
\qquad
 a\in[-\pi,\pi).
$$

$y$ 方向使用当前项目中的 quasi-momentum $\beta$，对应 phase 为

$$
\theta_y=e^{\mathrm{i}\beta d}.
$$

二维准周期 Green function 应满足

$$
G_{\mathrm{QP}}^{(\omega)}(x+L_x e_x,y)
=
\lambda\,G_{\mathrm{QP}}^{(\omega)}(x,y),
$$

$$
G_{\mathrm{QP}}^{(\omega)}(x+d e_y,y)
=
\theta_y\,G_{\mathrm{QP}}^{(\omega)}(x,y),
$$

其中这里 $x$ 是 target coordinate，第二个 argument $y$ 是 source coordinate。

等价地，对坐标差

$$
r=x-y
$$

定义

$$
G_{\mathrm{QP}}^{(\omega)}(r)
=
\sum_{m,n\in\mathbb Z}
\lambda^m\theta_y^n
G^{(\omega)}(r-mL_x e_x-nd e_y),
$$

其中 free-space Helmholtz Green function 是

$$
G^{(\omega)}(r)
=
\frac{\mathrm{i}}{4}H_0^{(1)}(\omega |r|).
$$

这个 lattice sum 在数值上不直接求。本文采用 MFS / proxy periodization。

---

## 2. 为什么不能复用一维 `qpgreen_mfs_pairmat`

已有的一维周期函数 `qpgreen_mfs_pairmat` 的结构是：

1. 先把 source-target difference 折回一个周期 strip；
2. 在近场区域使用 singular source 加 proxy correction；
3. 在远离 strip 的上下区域使用 Rayleigh plane-wave expansion；
4. 通过 `periodic_axis='x'/'y'` 交换坐标来复用同一个一维周期 computational kernel。

这适用于一维 periodic / 另一方向 open 的 waveguide Green function。

二维周期情形不同：

- 没有 open direction；
- 没有上下 far-field Rayleigh expansion region；
- 只需要在一个 unit cell 内评价 kernel；
- $G_{\mathrm{QP}}^{(\omega)}$ 要同时满足 $x$ 与 $y$ 两个方向的 quasi-periodic boundary discrepancy；
- MFS/proxy correction 应当直接对 cell boundary 的四条边施加二维 quasi-periodicity。

因此新的二维函数不应调用一维 `qpgreen_mfs_pairmat` 的内部逻辑。特别是不要沿用其中的

```matlab
idx_in = abs(Y) <= H;
idx_up = Y > H;
idx_dn = Y < -H;
```

以及 `C_up/C_down` plane-wave expansion。

二维版本只需要：

```text
free-space singular Green part
+
proxy/MFS correction enforcing two-direction quasiperiodicity
```

---

## 3. MFS ansatz：singular source + proxy correction

对每个 source point $y$, 令

$$
r=x-y.
$$

二维准周期 Green function 写成

$$
G_{\mathrm{QP}}^{(\omega)}(x,y)
\approx
G^{(\omega)}(x,y)
+
R_{\mathrm{proxy}}^{(\omega)}(x,y),
$$

其中

$$
R_{\mathrm{proxy}}^{(\omega)}(x,y)
=
\sum_{\ell=1}^{P}
q_\ell(y)\,
G^{(\omega)}(x,z_\ell).
$$

这里：

- $G^{(\omega)}(x,y)$ 是 physical singular source；
- $z_\ell$ 是放在 unit cell 外部的 proxy source points；
- $q_\ell(y)$ 是为了消除 free-space singular source 的 quasi-periodic discrepancy 而求出的 proxy strength；
- proxy correction 在 $U$ 内是 homogeneous Helmholtz solution，因此不能单独产生 source singularity。

所以绝不能只用 proxy sources 近似整个 $G_{\mathrm{QP}}^{(\omega)}$。正确结构必须保留 free-space singular source。

---

## 4. Proxy source 与 check points

### 4.1 Proxy source curve

`precomp_proxy2d` 应构造围绕 unit cell 的 proxy source points

$$
Z=\{z_\ell\}_{\ell=1}^{P}.
$$

推荐第一版使用包围矩形 cell 的 proxy circle：

$$
z_\ell=c_U+R_{\mathrm{proxy}}
(\cos t_\ell,\sin t_\ell),
\qquad
 t_\ell=\frac{2\pi\ell}{P}.
$$

其中 $c_U$ 是 cell center。

也可以后续改成 proxy box 或 superellipse，但第一版 circle 足够。

### 4.2 Check points

为了 enforce quasi-periodicity，在四条边上布置 check points。

左/右边：

$$
x_L(s)=(X_-,s),
\qquad
x_R(s)=(X_+,s),
\qquad s\in[Y_-,Y_+].
$$

下/上边：

$$
x_B(t)=(t,Y_-),
\qquad
x_T(t)=(t,Y_+),
\qquad t\in[X_-,X_+].
$$

对每组 check points，施加 value discrepancy 与 coordinate-normal derivative discrepancy。

建议使用 coordinate derivatives，而不是 outward normal derivatives：

- 左右边使用 $\partial_x$；
- 上下边使用 $\partial_y$。

这样可以避免 outward normal sign 的混乱。

---

## 5. Discrepancy equations

令

$$
u(x)
=
G^{(\omega)}(x,y)
+
\sum_{\ell=1}^{P}q_\ell(y)G^{(\omega)}(x,z_\ell).
$$

对每个 source point $y$，要求 $u$ 满足：

### 5.1 左右 quasi-periodicity

Value:

$$
u(x_R(s))-\lambda u(x_L(s))=0.
$$

$x$-derivative:

$$
\partial_x u(x_R(s))
-
\lambda \partial_x u(x_L(s))
=0.
$$

### 5.2 上下 quasi-periodicity

Value:

$$
u(x_T(t))-\theta_y u(x_B(t))=0.
$$

$y$-derivative:

$$
\partial_y u(x_T(t))
-
\theta_y \partial_y u(x_B(t))
=0.
$$

把 proxy part 与 free-space singular part 分开，可写成

$$
A_{\mathrm{proxy}}q(y)
=
-d_{\mathrm{free}}(y).
$$

其中 $A_{\mathrm{proxy}}$ 只由 proxy sources 在 check points 上的 discrepancy 组成，$d_{\mathrm{free}}(y)$ 是 free-space singular source $G^{(\omega)}(\cdot,y)$ 造成的 discrepancy。

---

## 6. `precomp_proxy2d`

### 6.1 Purpose

`kernel.precomp_proxy2d` 负责构造二维周期 MFS 的几何与 factorization。

建议接口：

```matlab
function proxy2d = precomp_proxy2d(pars2d, opts)
```

其中 `pars2d` 至少包含：

```matlab
pars2d.k        % omega
pars2d.beta     % y quasi-momentum beta
pars2d.lambda   % x Floquet multiplier lambda
pars2d.X_minus
pars2d.X_plus
pars2d.Y_minus
pars2d.Y_plus
```

或等价地使用：

```matlab
pars2d.cell = struct('X_minus',..., 'X_plus',..., ...
                     'Y_minus',..., 'Y_plus',...);
```

`opts` 可包含：

```matlab
opts.N_proxy
opts.N_check_x
opts.N_check_y
opts.proxy_radius_factor
opts.solver   % 'qr', 'svd', or '\'
opts.regularization
```

### 6.2 Output fields

建议 `proxy2d` 包含：

```matlab
proxy2d.Z                 % 2-by-P proxy source coordinates
proxy2d.check_L
proxy2d.check_R
proxy2d.check_B
proxy2d.check_T
proxy2d.A_proxy
proxy2d.factorization     % QR/SVD data for repeated solves
proxy2d.cell
proxy2d.phase_x           % lambda
proxy2d.phase_y           % exp(1i*beta*d)
proxy2d.k
proxy2d.beta
proxy2d.opts
```

如果使用 QR factorization，可保存：

```matlab
[Q,R,E] = qr(A_proxy, 0);
proxy2d.Q = Q;
proxy2d.R = R;
proxy2d.E = E;
```

如果使用 SVD，可保存：

```matlab
[U,S,V] = svd(A_proxy, 'econ');
```

### 6.3 Proxy matrix construction

对于每个 proxy source $z_\ell$，计算：

左右 value discrepancy:

$$
G^{(\omega)}(x_R(s_j),z_\ell)
-
\lambda G^{(\omega)}(x_L(s_j),z_\ell).
$$

左右 $x$-derivative discrepancy:

$$
\partial_xG^{(\omega)}(x_R(s_j),z_\ell)
-
\lambda\partial_xG^{(\omega)}(x_L(s_j),z_\ell).
$$

上下 value discrepancy:

$$
G^{(\omega)}(x_T(t_j),z_\ell)
-
\theta_yG^{(\omega)}(x_B(t_j),z_\ell).
$$

上下 $y$-derivative discrepancy:

$$
\partial_yG^{(\omega)}(x_T(t_j),z_\ell)
-
\theta_y\partial_yG^{(\omega)}(x_B(t_j),z_\ell).
$$

把这些 rows 叠起来构成

$$
A_{\mathrm{proxy}}\in\mathbb C^{N_{\mathrm{disc}}\times P}.
$$

其中

$$
N_{\mathrm{disc}}=2N_{\mathrm{check},y}+2N_{\mathrm{check},x}.
$$

### 6.4 Source-independent factorization

$A_{\mathrm{proxy}}$ 不依赖 physical source point $y$。因此 `precomp_proxy2d` 应只做一次 factorization。之后 `qpgreen2d` / `qpgreen2d_pairmat` 对每个 source point 只需要组装 RHS

$$
-d_{\mathrm{free}}(y)
$$

并用预分解求解 proxy strengths。

---

## 7. `qpgreen2d`

### 7.1 Purpose

`kernel.qpgreen2d` 用于评价单个 source point 对多个 target points 的二维准周期 Green function 及其导数。

建议接口：

```matlab
function [pot, grad, hess, aux] = qpgreen2d(src, trg, pars2d, proxy2d)
```

其中：

```matlab
src    % 2-by-1 source coordinate
trg    % 2-by-nt target coordinates
```

输出：

```matlab
pot        % 1-by-nt or nt-by-1
grad       % 2-by-nt, grad wrt target coordinate
hess       % 3-by-nt, [G_xx; G_xy; G_yy] wrt target coordinate
aux.q      % proxy strengths for this source
aux.res    % proxy discrepancy residual
```

### 7.2 Evaluation formula

先求 RHS

$$
d_{\mathrm{free}}(y).
$$

它由 free-space Green source $G^{(\omega)}(\cdot,y)$ 在 check points 上的 discrepancy 组成。然后解

$$
A_{\mathrm{proxy}}q(y)
=
-d_{\mathrm{free}}(y).
$$

最后在 target points 上评价：

$$
G_{\mathrm{QP}}^{(\omega)}(x,y)
\approx
G^{(\omega)}(x,y)
+
\sum_{\ell=1}^{P}
q_\ell(y)G^{(\omega)}(x,z_\ell).
$$

导数同理：

$$
\nabla_xG_{\mathrm{QP}}^{(\omega)}(x,y)
\approx
\nabla_xG^{(\omega)}(x,y)
+
\sum_{\ell=1}^{P}
q_\ell(y)\nabla_xG^{(\omega)}(x,z_\ell),
$$

$$
\nabla_x^2G_{\mathrm{QP}}^{(\omega)}(x,y)
\approx
\nabla_x^2G^{(\omega)}(x,y)
+
\sum_{\ell=1}^{P}
q_\ell(y)\nabla_x^2G^{(\omega)}(x,z_\ell).
$$

### 7.3 Source derivatives

For BIE double-layer terms one often needs source-normal derivatives, i.e.

$$
\partial_{\nu_y}G_{\mathrm{QP}}^{(\omega)}(x,y).
$$

Because the proxy strengths $q_\ell(y)$ depend on the source point $y$, source derivatives are not obtained by simply holding $q_\ell$ fixed. The correct route is to differentiate the discrepancy system.

Let

$$
Aq(y)=-d(y),
$$

where $A=A_{\mathrm{proxy}}$ is independent of $y$. Then

$$
Aq_{,r}(y)=-d_{,r}(y),
$$

and

$$
Aq_{,rs}(y)=-d_{,rs}(y).
$$

Thus source derivatives of the proxy correction reuse the same factorization of $A$.

---

## 8. `qpgreen2d_pairmat`

### 8.1 Purpose

`kernel.qpgreen2d_pairmat` should build dense target-by-source matrices for the two-direction quasiperiodic Green function.

Suggested interface:

```matlab
function [pot_ext, gradx_ext, grady_ext, ...
          hessxx_ext, hessxy_ext, hessyy_ext, aux] = ...
    qpgreen2d_pairmat(src, trg, pars2d, proxy2d)
```

where:

```matlab
src  % 2-by-ns
trg  % 2-by-nt
```

The output sizes are:

```matlab
pot_ext    % nt-by-ns
gradx_ext  % nt-by-ns, target x derivative
grady_ext  % nt-by-ns, target y derivative
hessxx_ext % nt-by-ns, target xx derivative
hessxy_ext % nt-by-ns, target xy derivative
hessyy_ext % nt-by-ns, target yy derivative
```

### 8.2 Batch solve over all source points

For each source point $y_j$, form

$$
d_{\mathrm{free}}(y_j).
$$

Stack them into a RHS matrix

$$
D_{\mathrm{free}}
=
\begin{bmatrix}
d_{\mathrm{free}}(y_1)&\cdots&d_{\mathrm{free}}(y_{n_s})
\end{bmatrix}.
$$

Then solve

$$
A_{\mathrm{proxy}}Q
=
-D_{\mathrm{free}},
$$

where

$$
Q=
\begin{bmatrix}
q(y_1)&\cdots&q(y_{n_s})
\end{bmatrix}.
$$

This gives all proxy strengths at once.

Then evaluate direct and proxy contributions on all target-source pairs:

$$
G_{\mathrm{QP}}(x_i,y_j)
\approx
G(x_i,y_j)
+
\sum_{\ell=1}^{P}
G(x_i,z_\ell)Q_{\ell j}.
$$

Matrix form:

$$
G_{\mathrm{QP}}
\approx
G_{\mathrm{direct}}(\mathrm{trg},\mathrm{src})
+
G_{\mathrm{proxy}}(\mathrm{trg},Z)Q.
$$

Similarly,

$$
G_{x,\mathrm{QP}}
\approx
G_{x,\mathrm{direct}}(\mathrm{trg},\mathrm{src})
+
G_{x,\mathrm{proxy}}(\mathrm{trg},Z)Q,
$$

and likewise for $G_y,G_{xx},G_{xy},G_{yy}$, if only target derivatives are required.

### 8.3 Source derivatives and BIE blocks

For boundary integral operators, one must be careful about whether derivatives are target-side or source-side:

- $S$ uses $G$;
- $D$ uses $\partial_{\nu_y}G$;
- $D^*$ uses $\partial_{\nu_x}G$;
- $T$ uses $\partial_{\nu_x}\partial_{\nu_y}G$.

The six-output convention inherited from `qpgreen_mfs_pairmat` is target-derivative oriented. This is enough for target-normal derivatives and Hessians with respect to target coordinates, but source-normal derivatives require source derivative data.

For assembling $A_{\mathrm{QP,2d}}$ reliably, `qpgreen2d_pairmat` should eventually expose source derivative matrices, for example through `aux`:

```matlab
aux.srcgradx
aux.srcgrady
aux.trgsrc_xx
aux.trgsrc_xy
aux.trgsrc_yx
aux.trgsrc_yy
aux.proxy_strengths
aux.proxy_residual
```

---

## 9. Differentiating proxy strengths

For source derivatives, reuse the same proxy factorization.

If

$$
Aq(y)=-d(y),
$$

then for source coordinate direction $r$,

$$
Aq_{,r}(y)=-d_{,r}(y).
$$

For second source derivatives,

$$
Aq_{,rs}(y)=-d_{,rs}(y).
$$

Then

$$
\partial_{y_r}G_{\mathrm{QP}}(x,y)
=
\partial_{y_r}G(x,y)
+
\sum_{\ell=1}^P
q_{\ell,r}(y)G(x,z_\ell),
$$

because proxy source locations $z_\ell$ are fixed.

For mixed target-source derivatives,

$$
\partial_{x_p}\partial_{y_r}G_{\mathrm{QP}}(x,y)
=
\partial_{x_p}\partial_{y_r}G(x,y)
+
\sum_{\ell=1}^P
q_{\ell,r}(y)\partial_{x_p}G(x,z_\ell).
$$

---

## 10. Validation tests for `qpgreen2d`

Before using the kernel in $A_{\mathrm{QP,2d}}$, test the kernel itself.

### 10.1 Target-side quasiperiodicity

For random interior target points $x$ and source points $y$, verify:

$$
G_{\mathrm{QP}}(x+L_xe_x,y)
-
\lambda G_{\mathrm{QP}}(x,y)
\approx 0,
$$

$$
\partial_xG_{\mathrm{QP}}(x+L_xe_x,y)
-
\lambda\partial_xG_{\mathrm{QP}}(x,y)
\approx 0,
$$

$$
G_{\mathrm{QP}}(x+de_y,y)
-
\theta_yG_{\mathrm{QP}}(x,y)
\approx 0,
$$

$$
\partial_yG_{\mathrm{QP}}(x+de_y,y)
-
\theta_y\partial_yG_{\mathrm{QP}}(x,y)
\approx 0.
$$

### 10.2 Source-side quasiperiodicity

Because the Green function is a kernel, source shifts should obey inverse phase relations:

$$
G_{\mathrm{QP}}(x,y+L_xe_x)
-
\lambda^{-1}G_{\mathrm{QP}}(x,y)
\approx 0,
$$

$$
G_{\mathrm{QP}}(x,y+de_y)
-
\theta_y^{-1}G_{\mathrm{QP}}(x,y)
\approx 0.
$$

Source-derivative versions should also be tested if `aux.srcgrad*` is used.

### 10.3 Simultaneous translation

For lattice vector $a$, check

$$
G_{\mathrm{QP}}(x+a,y+a)
=
G_{\mathrm{QP}}(x,y),
$$

since the difference $x-y$ is unchanged.

### 10.4 Diagonal regular part

For self-interaction corrections in BIE assembly, test the regular part

$$
R_{\mathrm{proxy}}^{(\omega)}(y,y)
=
\sum_{\ell=1}^{P}
q_\ell(y)G^{(\omega)}(y,z_\ell)
$$

and its derivatives for smoothness along $\Sigma$.

The free-space singular part should still be handled by the existing Kress / singular quadrature. Only the regular proxy correction is evaluated on the diagonal by ordinary smooth formulas.

---

## 11. Validation tests for `qpgreen2d_pairmat`

### 11.1 Consistency with scalar `qpgreen2d`

For a small set of sources and targets, compare each column of `qpgreen2d_pairmat` with direct calls to `qpgreen2d`.

### 11.2 Quasiperiodic boundary discrepancy matrix residual

For all sources in a batch, compute

$$
A_{\mathrm{proxy}}Q+D_{\mathrm{free}}
$$

and report

$$
\frac{\|A_{\mathrm{proxy}}Q+D_{\mathrm{free}}\|}
{\|D_{\mathrm{free}}\|}.
$$

This should be small.

### 11.3 Convergence in proxy parameters

Increase:

```text
N_proxy
N_check_x
N_check_y
proxy_radius_factor
```

and verify convergence of:

```text
G_QP(trg,src)
grad G_QP(trg,src)
sigma_min(A_QP_2d)
```

---

## 12. Relation to Step 2a

Once `qpgreen2d_pairmat` is reliable, it can be used to construct the Barnett-style matrix

$$
A_{\mathrm{QP,2d}}(\omega,\beta,\lambda).
$$

Then Step 2a proceeds as follows:

1. Fix $(\omega,\beta)$.
2. Scan

   $$
   a\in[-\pi,\pi),
   \qquad
   \lambda=e^{\mathrm{i}a}.
   $$

3. For each $\lambda$, call `precomp_proxy2d`.
4. Use `qpgreen2d_pairmat` to assemble $A_{\mathrm{QP,2d}}$ on $\Sigma$.
5. Compute

   $$
   \sigma_{\min}(A_{\mathrm{QP,2d}}).
   $$

6. Compare dips in $a$ with the arguments of transfer/Bloch-mode eigenvalues

   $$
   \lambda_j
   $$

   satisfying

   $$
   |\lambda_j|\approx1.
   $$

This validates whether the transfer/Bloch-mode package is finding the same horizontal Bloch phases as the Barnett-style two-dimensional quasiperiodic BIE formulation.

---

## 13. Implementation notes

### 13.1 Names

Use names that avoid conflict with one-dimensional periodic kernel functions:

```text
kernel.precomp_proxy2d
kernel.qpgreen2d
kernel.qpgreen2d_pairmat
```

Do not overload `qpgreen_mfs` or `qpgreen_mfs_pairmat`, because their internal open-direction Rayleigh expansion logic is not compatible with the fully two-dimensional periodic Green function.

### 13.2 Minimal first implementation

A minimal first version can implement:

- value and target derivatives only;
- `qpgreen2d` for point-source Dirichlet benchmark;
- `qpgreen2d_pairmat` matching the existing six-output signature.

But before using it for Müller $A_{\mathrm{QP,2d}}$, source derivatives must be handled correctly. Otherwise double-layer and hypersingular blocks may be wrong.

### 13.3 Recommended development order

1. `precomp_proxy2d`
2. `qpgreen2d` with value and target derivatives
3. kernel quasiperiodicity tests
4. `qpgreen2d_pairmat` value and target derivatives
5. source derivative extension
6. diagonal regular correction tests
7. Barnett-style $A_{\mathrm{QP,2d}}$ assembly
8. Step 2a comparison with transfer/Bloch modes

---

## 14. Summary

The two-dimensional quasiperiodic MFS Green function should be built as

$$
G_{\mathrm{QP}}^{(\omega)}(x,y)
\approx
G^{(\omega)}(x,y)
+
\sum_{\ell=1}^{P}
q_\ell(y)G^{(\omega)}(x,z_\ell),
$$

where $q_\ell(y)$ is chosen so that the total field satisfies both

$$
x\text{-quasiperiodicity with multiplier }\lambda
$$

and

$$
y\text{-quasiperiodicity with multiplier }e^{\mathrm{i}\beta d}.
$$

This is the direct two-dimensional analogue of the current MFS/proxy philosophy, but without any open-direction Rayleigh expansion. It is therefore not compatible with reusing the internal logic of the existing one-dimensional `qpgreen_mfs_pairmat`, although the free-space kernel evaluation utilities and many implementation patterns can be reused.
