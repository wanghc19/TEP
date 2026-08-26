# I3.2 empirical cap v2: MFS/Kress same-trial evaluation

## 1. Status, scope, and authority

- **Design status:** `RESEARCHER--ENGINEER AGREED`; `SKEPTIC DESIGN PASS`.
- **Future experiment:** `test/i3/e-cap-v2`.
- **Future schema:** `TEP_I3_2_ECAP_V2_MFS_KRESS_V1`.
- **Future append-only attempt:** `ecap-v2-a1`.
- **Claim boundary:** every numerical cap in this design is an
  `EMPIRICALLY SUPPORTED ERROR CAP`; the final claim is always
  `EMPIRICAL / UNQUALIFIED`.

This design replaces neither [[research/projects/eig-apost/implementation/i3/design-3-1f|the frozen full-boundary trial design]] nor the strict conditional theorem in
[[research/projects/eig-apost/implementation/i3/design-3-2a|I3.2 theorem design]]. It creates a new evaluator for the already frozen finite-density trial. It does not use, call, repair, or reinterpret any field evaluator under `test/i3/e-cap`. The only permitted historical runtime input is
`test/i3/e-cap/input/fbie-a1-certificate.mat`.

The following old objects remain unchanged: candidate, certificate, QZ state,
$P_\pm$, wall traces, BIE densities, lift supports and shapes, majorant formulas,
refinement numbers, thresholds, prior designs, reviews, code, and outputs. No
formal run is authorized before both a Skeptic `DESIGN PASS` and a later
Skeptic `spec-to-code PASS`.

## 2. Frozen continuous trial and the center-cell boundary

### 2.1 Lead/material cells

For a frozen two-wall state $a\in\mathbb C^{194}$, the certificate defines

$$
\begin{bmatrix}\tau_\Gamma\\ \zeta_\Gamma\end{bmatrix}
=E_\Gamma a,\qquad
\xi_L=E_La,\qquad \xi_R=E_Ra,
$$

where `eta_unit_256`, `xi_left_unit_512`, and `xi_right_unit_512` store
$E_\Gamma,E_L,E_R$. The density coordinate is exactly
$[\tau;\zeta]$ with $\zeta=-\sigma$. In every material cell the mathematical
trial is

$$
u_h^{\rm raw}(x)
=\sum_{b\in\{L,R,\Gamma\}}
\left[D_b\tau_b(x)-S_b\zeta_b(x)\right],
$$

with $\tau_L=\tau_R=0$ and $\zeta_L=-\xi_L$,
$\zeta_R=-\xi_R$. Thus both artificial-wall contributions are single layers,
but the representation is still the stated all-boundary $D\tau-S\zeta$
trial. The exterior operators use the quasi-periodic Green function and the
circle-interior operators use the free-space Green function at
$k_i=\widehat k_h\sqrt{\rho_{\rm disk}}$.

The native circle coefficient order is $-128{:}127$ and the native wall
density order is $-256{:}255$, in both cases retaining the negative Nyquist
coefficient. Refinement evaluates the same finite trigonometric density; it
never changes a coefficient, density convention, layer representation, or
BIE solution.

### 2.2 Center empty cell

The frozen design defines the empty connector cell $C_0$ by an analytic
homogeneous field. The certificate contains its wall traces, outward fluxes,
and center/first-cell singleton residual coordinates, but it contains no
separate center-cell wall-layer density. Re-expressing $C_0$ by a new wall BIE
would change the trial and require a prohibited solve.

Accordingly, v2 applies every new layer-potential evaluation axis only to
lead/material cells. It carries only the analytic center-side wall trace,
outward flux, center-side lift source, and center field-lower trace unchanged.
The first-lead side of a center/first-wall singleton is not frozen: its raw
value, outward flux, and lead-side value-lift source are recomputed from the
first material cell at every applicable wall target, wall source, and GQP
level. Thus

$$
j_{C/L}^{(a)}=q_{C,\mathrm{out}}+q_{L,\mathrm{out}}^{(a)},
\qquad
a_{L,\mathrm{lift}}^{(a)}=g_C-u_{L,\mathrm{raw}}^{(a)},
$$

and analogously on the right. Only the analytic center terms have
`center_empirical_axes=NONE`; the first-lead terms participate in the same
aligned differences as every other material-cell action. Saved complete
center/first singletons are comparison diagnostics only and never enter a v2
ordinary center. The entry calls no Rayleigh evaluator and applies no
Fourier/Rayleigh field multiplier.

This is the sole non-inventive interpretation of the frozen certificate. If
the all-boundary requirement is instead interpreted as requiring a new
center-cell density, the first blocker is
`CENTER_LAYER_DENSITY_NOT_IN_FROZEN_CERTIFICATE`; the experiment must stop
rather than solve for one.

### 2.3 Meaning of $M=48$

$M=48$ means only that the shared total Dirichlet wall trace has 97 input
coefficients,

$$
g_M(y)=\sum_{m=-48}^{48}d_m
\exp\!\left(\mathrm i(\beta+2\pi m/d)y\right).
$$

It is not a cell-field expansion, circle-density cutoff, circle residual
bandwidth, or kernel approximation parameter. Fourier operations are allowed
only for the frozen wall trace, the periodic trigonometric representation of
Nystr\"om densities and Kress quadrature, and modal norms of already computed
boundary residuals.

## 3. Identity and forbidden-operation contract

The input helper must whitelist only `staged.input_contract`,
`staged.certificate`, and the scalar/factor data in `staged.ordinary_anchor`
that are explicitly required for comparison. It must never consume
`staged.raw_maps` or `staged.historical_diagnostics`; these fields are cleared
immediately after schema rejection/allowlisting.

Before and after every scientific module, the implementation records a
deterministic identity digest of all frozen numerical arrays plus basis,
ordering, origin, and density-coordinate metadata. It checks

$$
M=48,\quad K=97,\quad d=1,\quad R=0.2,\quad \beta=0.5,
$$

the exact array dimensions, finite values, the negative-Nyquist conventions,
and the $[\tau;\zeta]$ sign label. The following counters must remain zero:

- candidate, QZ, propagation, BIE, and density solves;
- old-`e-cap` calls and raw-map consumption;
- image-sum, Ewald, Linton/lattice-sum, incident-field, far-field, and
  Rayleigh-trial actions;
- `interpft` calls and any unphased physical-wall interpolation.

The runtime also requires the following exact MFS ledger:

| item | expected count |
|---|---:|
| `kernel.precomp_proxy` | 6 |
| MATLAB `lsqminnorm` path selected | 6 |
| `pinv` fallback selected | 0 |
| MFS outer plane-wave evaluator | 0 |

Before the first proxy construction, the runtime verifies MATLAB and a
nonempty `which('lsqminnorm')`. Dependencies are resolved only through normal
MATLAB function resolution. Source identity is checked statically during the
pre-run spec-to-code review and may be recorded in machine-side provenance,
but executable MATLAB neither hashes sources nor reads a manifest, review,
repository layout, or historical artifact to authorize execution.

The static audit verifies that the resolved `precomp_proxy` implementation
selects `lsqminnorm` when it is available. The runtime proof is then the typed
$6/6/0/0$ call ledger above, not a source-path or source-hash gate. A ledger
mismatch is an implementation blocker.

A nonzero forbidden counter or identity drift is an implementation blocker,
not a refinement warning.

## 4. MFS-only quasi-periodic Green function

### 4.1 Only permitted kernel chain

The only quasi-periodic kernel construction is

$$
\mathtt{kernel.precomp\_proxy}
\longrightarrow
\mathtt{kernel.qpgreen\_mfs\_pairmat},
$$

with `periodic_axis='y'`, MATLAB `lsqminnorm`, $H=1.1$, and
`proxy_dist=0.2`. The implementation may call `kernel.h2d_directch` only as
the free-space primitive already used by these verified MFS routines and by
the regular-remainder diagonal construction. It may not call
`kernel.qpgreen2d`, an image sum, or a fallback kernel.

For all boundary pairs, the computational nonperiodic difference satisfies
$|\Delta x|\leq1<H$. Hence the MFS pair evaluator's outer plane-wave branch
must have execution count zero. Internal plane waves in `precomp_proxy` are
part of the MFS kernel construction; they are not a field representation of
$u_h$.

### 4.2 Production and refinement tuples

The production proxy tuple is

$$
(N_{\rm side},N_{\rm top},N_{\rm edge},M_{\rm pw})
=(160,160,80,32).
$$

The penultimate proxy comparisons are the base tuple
$(120,120,64,24)$ and the four one-axis tuples obtained by setting only one
of $N_{\rm side},N_{\rm top},N_{\rm edge},M_{\rm pw}$ to its production
value. These choices come from the existing proxy-rule validation and are
frozen before v2 results. Historical approximately ten-digit accuracy is an
empirical scale only, not zero error or a strict enclosure.

### 4.3 Smooth-remainder interpolation

Direct evaluation of millions of relative boundary pairs against roughly 320
proxy sources would violate the time/memory contract. V2 therefore
interpolates only the smooth MFS proxy remainder. The singular nearest
free-space primary is always evaluated analytically and integrated by Kress.

In computational difference coordinates,

$$
X_0=\Delta y-\operatorname{round}(\Delta y/d)d,
\qquad Y=\Delta x,
$$

on $[-d/2,d/2]\times[-1,1]$. Production uses a $257\times257$ table; the
interpolation ladder is $65,129,257$. Six computational fields are tabulated:
value, two target gradients, and three target Hessian entries. Construction
uses blocked calls to the MFS proxy-source field.

MATLAB `round` owns exact half-period ties away from zero. Consequently
$+d/2$ folds to $-d/2$ and $-d/2$ folds to $+d/2$; both closed-table endpoint
values are retained. For a table of order $n$, the uniform nodes are
$X_p=-d/2+pd/(n-1)$ and $Y_q=-1+2q/(n-1)$. In each coordinate, the query
uses the four consecutive nodes beginning at

$$
i_0=\min\{\max\{\lfloor (x-x_{\min})/h\rfloor-1,0\},n-4\},
$$

and the tensor product of the four cubic Lagrange weights. Thus both seam
endpoints use inward one-sided $4\times4$ stencils; no index wraps and no
endpoint values are averaged.

The proxy remainder is not separately periodic. Every query uses
$m=\operatorname{round}(\Delta y/d)$, multiplies all six interpolated
computational fields by $\exp(\mathrm i\beta m d)$, and remaps

$$
(G_x,G_y)_{\rm phys}=(G_Y,G_X)_{\rm comp},
$$

$$
(G_{xx},G_{xy},G_{yy})_{\rm phys}
=(G_{YY},G_{XY},G_{XX})_{\rm comp}.
$$

No derivative of the piecewise-constant fold phase is introduced; this is
exactly the executed `qpgreen_mfs_pairmat` rule away from the seam and its
declared one-sided trace at the tie.

The direct interpolation oracle uses the four interior computational
holdouts

$$
(-0.4375,-0.73),\ (-0.183,0.31),\ (0.117,-0.47),\ (0.421,0.82),
$$

and the eight seam holdouts
$X_0=\pm d/2$, $Y\in\{-0.8,-0.2,0.3,0.9\}$. It compares each of the six
physical fields against `qpgreen_mfs_pairmat` minus the analytic primary.
For each derivative order, the metric is the maximum absolute defect divided
by the maximum direct magnitude plus `realmin`; the frozen qualification
threshold is $2\times10^{-9}$. A separate complete-kernel Bloch shift oracle
uses these four $Y$ values and threshold $10^{-10}$. Finite failure is a
nonblocking scientific warning that makes kernel qualification false;
nonfinite interpolation or an undefined fold is a blocker.

## 5. Boundary grids and rectangular Kress action

### 5.1 Fixed midpoint grids

All evaluation grids are fixed midpoints,

$$
\theta_j=\frac{2\pi(j+1/2)}{N},\qquad
y_j=-\frac d2+\frac{d(j+1/2)}N.
$$

The native circle density coefficients originate from the endpoint grid
$2\pi j/256$ and must retain that FFT-origin convention before direct
trigonometric evaluation. Wall density coefficients are evaluated directly
in the frozen physical Bloch basis; no sample interpolation is needed.

Independent source and target axes reuse the already frozen numerical level
values:

| family | source quadrature $N_s$ | targets $N_t$ |
|---|---|---|
| circle | $512,1024,2048$ | $512,1024,2048$ |
| wall | $1024,2048,4096$ | $1024,2048,4096$ |

The target axis holds both source families at their finest levels; the source
axis holds the target at its finest level and refines both source families as
the paired triples

$$
(N_{s,\Gamma},N_{s,W})=(512,1024),(1024,2048),(2048,4096).
$$

Thus a circle-target source comparison includes both circle self and
wall-to-circle source-quadrature changes, while a wall-target source
comparison includes both wall/distinct-wall and circle-to-wall changes. No
separate cross-source cap row exists. Every source grid is a direct evaluation
of the same native density interpolant. `source_quadrature_refinement_count`
may increase, while `density_resolve_count` remains zero.

### 5.2 Rectangular product weights

For source nodes $s_j=s_0+2\pi j/N_s$ and arbitrary targets $t_i$, define

$$
R_j^{N_s}(t_i)=-\frac{4\pi}{N_s}
\left[
\sum_{p=1}^{N_s/2-1}\frac{\cos(p(t_i-s_j))}{p}
+\frac1{N_s}\cos\!\left(\frac{N_s}{2}(t_i-s_j)\right)
\right].
$$

For
$K(t,s)=A(t,s)\log(4\sin^2((t-s)/2))+B(t,s)$, the action is

$$
\sum_j\left[R_j^{N_s}(t_i)A(t_i,s_j)
+\frac{2\pi}{N_s}B(t_i,s_j)\right]\phi_N(s_j).
$$

Coincident source/target points use the analytic split limits. Mandatory
rectangular circle splits use the following literal package conventions. Let
$r=z(t)-z(s)$, $\rho=|r|$, $v_s=|z'(s)|$,
$\nu_s=(y'(s),-x'(s))$, and $n_t=(y'(t),-x'(t))/|z'(t)|$. Away from the
diagonal,

$$
M=\frac{\mathrm i}{4}H_0^{(1)}(k\rho)v_s,
\qquad M_1=-\frac1{4\pi}J_0(k\rho)v_s,
$$

$$
L=\frac{\mathrm ik}{4}\frac{r\cdot\nu_s}{\rho}H_1^{(1)}(k\rho),
\qquad L_1=-\frac{k}{4\pi}\frac{r\cdot\nu_s}{\rho}J_1(k\rho),
$$

$$
L^*=-\frac{\mathrm ik}{4}\frac{r\cdot n_t}{\rho}H_1^{(1)}(k\rho)v_s,
\qquad
L_1^*=\frac{k}{4\pi}\frac{r\cdot n_t}{\rho}J_1(k\rho)v_s,
$$

$$
N=-\frac{\mathrm ik}{4}\frac{z'(t)\cdot r}{\rho}H_1^{(1)}(k\rho),
\qquad
N_1=\frac{k}{4\pi}\frac{z'(t)\cdot r}{\rho}J_1(k\rho).
$$

Writing $\Lambda=\log(4\sin^2((t-s)/2))$, the smooth parts are
$M_2=M-M_1\Lambda$, $L_2=L-L_1\Lambda$,
$L_2^*=L^*-L_1^*\Lambda$, and

$$
N_2=N-\frac1{4\pi}\cot\frac{t-s}{2}-N_1\Lambda.
$$

At coincidence, with
$\chi=(x'y''-y'x'')/|z'|^2$ and Euler's constant $c_E$,

$$
M_1=-\frac{v_s}{{4\pi}},\qquad
M_2=\frac12\left[\frac{\mathrm i}{2}-\frac{c_E}{\pi}
-\frac1{2\pi}\log\!\left(\frac{k^2v_s^2}{4}\right)\right]v_s,
$$

$$
L_1=L_1^*=N_1=0,\qquad
L_2=L_2^*=-\frac{\chi}{4\pi},\qquad
N_2=\frac{z'\cdot z''}{4\pi|z'|^2}.
$$

For $h_s=2\pi/N_s$, let $\mathcal R[A,B]=R^{N_s}\!\odot A+h_sB$.
The free hypersingular difference is implemented literally as

$$
A=\mathcal R[k_o^2M_{1,o}-k_i^2M_{1,i},
k_o^2M_{2,o}-k_i^2M_{2,i}]\odot
\frac{z'(t)\cdot z'(s)}{v_tv_s},
$$

$$
B=\mathcal R[N_{1,o}-N_{1,i},N_{2,o}-N_{2,i}]
\operatorname{diag}(v_s^{-1}),
\qquad
(T_o-T_i)_{\rm free}\tau=A\tau+B D_s\tau.
$$

Here $D_s$ is `utils.triginterp(N_s)` conjugated only by the declared
midpoint-origin shift; equivalently it differentiates the directly evaluated
same density interpolant at the source nodes. The smooth QP correction is

$$
-h_s\sum_j n_t^T\nabla_x^2R^{QP}(x_t,x_j)n_jv_j\tau_j.
$$

For a straight quotient wall, set $a=d/(2\pi)$ and form the complete gauged
parameter kernel

$$
\widetilde M_W(t,s)=
e^{-\mathrm i\beta y_t}G^{QP}(x_t,y_t;x_s,y_s)
e^{\mathrm i\beta y_s}a.
$$

To extend the local gauged singular coefficient smoothly around the quotient,
let

$$
E(x)=\begin{cases}0,&x\leq0,\\ e^{-1/x},&x>0,\end{cases}
$$

$$
\chi(r)=\begin{cases}
1,&0\leq r\leq\pi/4,\\
\dfrac{E(\pi/2-r)}{E(\pi/2-r)+E(r-\pi/4)},
&\pi/4<r<\pi/2,\\
0,&r\geq\pi/2,
\end{cases}
$$

and let $w(\delta)=\delta-2\pi\lfloor(\delta+\pi)/(2\pi)\rfloor$ and
$q(\delta)=\chi(|w(\delta)|)w(\delta)$. The cutoff is zero near the wrap
discontinuity, so $q$ is a smooth periodic function and equals the physical
local parameter difference for $|w|\leq\pi/4$. The only wall logarithmic
split is

$$
A_W=-\frac{a}{4\pi}e^{-\mathrm i\beta a q(t-s)}
J_0(k_o a|q(t-s)|),\qquad
B_W=\widetilde M_W-A_W\Lambda.
$$

At coincidence, $B_W$ is the stated $M_2$ free limit plus
$aR^{QP}(0)$. The free same-wall target-normal kernel is identically zero;
the cell-interior outward normal action is the smooth MFS $K^*$ correction
plus $\frac12\xi$. These wall formulas, rather than a circle geometry helper,
are the only wall-self implementation.

Mandatory pre-formal oracles are:

1. equality with `quad.quad_kress_rvec` on aligned grids
   $N=32,64,128$, with relative defect at most $10^{-14}$;
2. the off-grid logarithmic Fourier identity

$$
\int_0^{2\pi}\log\!\left(4\sin^2\frac{t-s}{2}\right)
e^{\mathrm i\ell s}\,ds
=-\frac{2\pi}{|\ell|}e^{\mathrm i\ell t},\qquad \ell\ne0;
$$

   for $N_s=64$, modes $\ell=-16{:}16\setminus\{0\}$, and targets
   $t_i=2\pi(i+1/3)/17$, with relative defect at most $5\times10^{-13}$;
3. square-grid agreement at $N=256$ for free-space $S,D,D^*$ and
   $T_o-T_i$ with the active package Kress assembly, threshold $10^{-12}$;
4. a mismatched circle oracle with $N_s=512$, $N_t=1024$ and
   $\ell=-8{:}8$. Its reference is

$$
\left[t_\ell(k_o)-t_\ell(k_i)\right]e_\ell
+T_{\rm reg}^{QP}e_\ell,
\qquad
t_\ell(k)=\frac{\mathrm i\pi k^2R}{2}
J_\ell'(kR)H_\ell^{(1)\prime}(kR),
$$

   where the regular term is an independent blocked direct MFS
   mixed-derivative contraction, not the interpolated assembled matrix. The
   constituent-scaled defect and the $512\to1024$ reference change use the
   definitions of `design-3-1f` and threshold $0.20$;
5. manufactured wall physical Bloch modes $m=-4{:}4$, evaluated with
   $(N_s,N_t)=(512,1024)$ and compared with $N_s=4096$ at the same targets.
   Value and cell-interior outward-normal relative $L^2$ changes have
   threshold $0.20$; the physical/gauge seam, midpoint-origin, negative
   Nyquist, and explicit $+\frac12$ jump identities have threshold
   $10^{-10}$. The same oracle records
   $\|\widetilde M_W-(A_W\Lambda+B_W)\|$ at the target/source pairs; its
   scale-covariant recombination threshold is $10^{-12}$.

### 5.3 Self and cross actions

- Circle self-interaction uses rectangular Kress splits for the free primary
  and the interpolated smooth MFS remainder.
- Wall self-interaction uses its own straight quotient-wall periodic
  logarithmic split. The wall density first enters the periodic gauge; the
  complete action is returned to the physical Bloch gauge. No modal Green or
  Rayleigh multiplier is allowed.
- Wall--circle, distinct-wall, and distinct-circle interactions have positive
  separation and use streamed smooth trapezoid action.
- Normal and hypersingular actions reproduce the source/target derivative
  signs and the $A+B\partial_s$ Kress construction used by the verified
  M\"uller assembly.

With $n_\Gamma$ pointing from the material into the background, the frozen
jump table is

$$
\gamma_D^{\rm ext}D_o=\frac12I+K_o,\qquad
\gamma_D^{\rm int}D_i=-\frac12I+K_i,
$$

$$
\partial_n^{\rm ext}S_o=-\frac12I+K_o^*,\qquad
\partial_n^{\rm int}S_i=\frac12I+K_i^*.
$$

Therefore the exterior-minus-interior diagnostic is

$$
j_D=\tau+(K_o-K_i)\tau-(S_o-S_i)\zeta,
$$

$$
j_N=(T_o-T_i)\tau+\zeta+(K_i^*-K_o^*)\zeta.
$$

The frozen weak residual uses the opposite orientation,
$j_\Gamma=\partial_n u_i-\partial_n u_o=-j_N$. Both arrays and the sign identity
are saved; the $B_\Gamma$ factor uses $j_\Gamma$.

Wall cell-interior outward normal action is
$(\frac12I+K^*)\xi$. Source differentiation is minus target
differentiation, and the smooth mixed-normal remainder is
$-n_t^T(\nabla_x^2R)n_s$.

## 6. Residual components and lifting

The same frozen value-only wall strips and circle collars produce

$$
B_W,\qquad B_\Gamma,\qquad B_V,\qquad
\mathcal M_h=B_W+B_\Gamma+B_V.
$$

Raw wall normal jumps enter only $B_W$; raw circle normal defects enter only
$B_\Gamma$; raw wall/circle value defects enter only the explicit lifting
source factor in $B_V$. A raw difference is never added twice.

Wall Fourier weights and circle Riccati weights retain the formulas of
`design-3-1f`. Riccati steps are $512,1024,2048$. Lift Gauss orders are
$32,64,128$, including the circle $r/R$ Jacobian and the actual
$\rho^{-1/2}$ weight. All computed wall/circle modes enter the corresponding
factor; outer Fourier tails are diagnostics, not enclosures.

Each module returns aligned positive factors, not differences of Grams. For
two levels, the comparison object is

$$
W_{\Delta,a}=(F_{a,2}-F_{a,1})^*(F_{a,2}-F_{a,1})\succeq0.
$$

The volume factor is the canonical direct sum of its circle and wall rows
before the single volume full-$P$ contraction. Circle and wall parts do not
receive independent tail scalars that are later combined.

## 7. Full-$P$ and empirical caps

### 7.1 Nonnormal finite-tail evaluation

All contractions retain the complete $97\times97$ matrices:

$$
W_{2N}=W_N+(P^N)^*W_NP^N,\qquad P^{2N}=P^NP^N,
$$

at $N=8,16,32$. Diagonalization, individual multiplier replacement,
$P^{-1}$, Jordan deletion, and spectral-radius-only tails are forbidden.
The center/first-cell singletons and the plus/minus off-by-one associations
remain those of `design-3-1f`.

For an aligned component factor, $D_X(F_2,F_1)$ is the norm of the complete
augmented difference coordinate: zero difference for the fixed analytic
center term plus the recomputed first-lead singleton difference, zero-padded
direct actions through level 32, and the difference of the two nonnegative
ordinary tail coordinates. It is not a raw Fourier norm or
$\|W_2-W_1\|$.

### 7.2 Standard three-level rule

For every target, source, Riccati, Gauss, interpolation, and full-$P$ axis,
define

$$
d_1=\max\{|B_1-B_0|,D_X(F_1,F_0)\},\qquad
d_2=\max\{|B_2-B_1|,D_X(F_2,F_1)\}.
$$

Let $n_a$ be the typed complex multiply-add/comparison count for the two
aligned differences, and

$$
\omega_a=100n_a\epsilon_{\rm mach}
\max\{|B_0|,|B_1|,|B_2|,\|F_0\|,\|F_1\|,\|F_2\|,
\mathrm{realmin}\}.
$$

The frozen contraction gate is $d_2\leq0.5d_1$. When it passes, the empirical
remainder is $R_a=2\max\{d_2,\omega_a\}$. A finite failure is nonblocking, but
that axis cap is unresolved; results and subsequent objects are still saved.
No alternative ratio or multiplier may be chosen after seeing data.

Family-specific Fourier shell diagnostics are derived from the same aligned
target factors. They are reported separately but are not added again when
already represented by the target-axis difference.

### 7.3 MFS uncertainty without double counting

All proxy/interpolation variants are converted to component differences only
on the registered diagnostic boundary grids

$$
(N_{s,\Gamma},N_{t,\Gamma})=(512,512),\qquad
(N_{s,W},N_{t,W})=(1024,1024),
$$

with the corresponding mixed $512\times1024$ and $1024\times512$ cross
actions. They use the same full-$97\times97$ propagation and component
association as the finest objects. Let $H$ denote the combined-high proxy and
let $c$ range over the base and four one-axis proxy variants, all represented
on the common 129 table. Define the diagnostic-grid difference

$$
d_{X,{\rm proxy}}^{\rm diag}=
\max_c\max\left\{
|B_{X,{\rm diag}}^{H,129}-B_{X,{\rm diag}}^{c,129}|,
D_X(F_{X,{\rm diag}}^{H,129},F_{X,{\rm diag}}^{c,129})
\right\}.
$$

The separated GQP pieces are fixed as follows:

| component | separated factor pieces included in the scale |
|---|---|
| $W$ | wall-density $\partial_nS^{QP}$; circle-density $\partial_nD^{QP}$; circle-density $-\partial_nS^{QP}$, including the recomputed first-lead flux singleton |
| $\Gamma$ | wall-density $\partial_nS^{QP}$ on the circle; complete exterior circle $T^{QP}\tau$ piece; complete exterior circle $-K^{QP,*}\zeta$ piece |
| $V$ | on both wall and circle value targets: wall $S^{QP}\xi$, circle $D^{QP}\tau$, and circle $-S^{QP}\zeta$, each passed through its frozen lifting factor, including the recomputed first-lead-side lift singleton |

For each listed piece $p$, form its complete aligned component factor with
the same center/first and full-$P$ association as the total. The
noncancelling scale is the triangle sum

$$
s_{X,G}=\sum_{p\in\mathcal P_X}D_X(F_{X,p},0).
$$

Thus $s_{X,G}^{\rm diag}$ and $s_{X,G}^{\rm fine}$ are mechanical values on
the diagnostic and single production-finest actions; cancellations between
different boundary operators are not used to shrink them.

For the two circle normal pieces, `complete exterior` means the analytic free
primary plus the MFS smooth remainder. The earlier word `regular` referred to
the already regularized M\"uller hypersingular/adjoint difference action; it
did not mean `MFS remainder only`. Primary/remainder cancellation inside one
complete operator piece is not separated or tuned. This is a frozen empirical
mapping limitation and remains part of the `EMPIRICAL / UNQUALIFIED` caveat.

Every streamed module increments a typed arithmetic ledger: one count for
each complex multiply-add in a boundary-factor product, 31 counts for each
one-field $4\times4$ tensor-cubic query, and the literal dense multiply/add
counts used by each full-$P$ recurrence and factor comparison. Let
$n_{X,{\rm scale}}$ be the ledger count used to form
$s_{X,G}^{\rm diag}$ and let $n_{X,{\rm rel}}$ be the combined count for the
two scales, factor differences, scalar subtraction, division, and maximum.
The allowances are uniquely

$$
\omega_{X,{\rm scale}}
=100n_{X,{\rm scale}}\epsilon_{\rm mach}
\max\{s_{X,G}^{\rm diag},\mathrm{realmin}\},
$$

$$
\omega_{X,{\rm rel}}
=100n_{X,{\rm rel}}\epsilon_{\rm mach}.
$$

An exact-zero separated scale is legal only when every separated factor is
bitwise zero; then its GQP contribution is zero. Any other nonpositive or
nonfinite scale makes the GQP cap unresolved. Define

$$
r_{X,{\rm proxy}}=
\frac{d_{X,{\rm proxy}}^{\rm diag}}
{\max\{s_{X,G}^{\rm diag},\omega_{X,{\rm scale}}\}}.
$$

With $\omega_{X,{\rm rel}}$ the dimensionless arithmetic allowance, the
coarse-to-finest empirical mapping is

$$
R_{X,{\rm proxy}}
=2\max\{r_{X,{\rm proxy}},2\times10^{-9},
\omega_{X,{\rm rel}}\}\,s_{X,G}^{\rm fine}.
$$

The $2\times10^{-9}$ relative floor is the preregistered empirical mapping
from the existing MFS qualification scale. It is not a theorem.
Interpolation uses aligned diagnostic factors to form relative
$r_{X,1}$ and $r_{X,2}$ for $65\to129\to257$. It must satisfy
$r_{X,2}\leq0.5r_{X,1}$; on success,

$$
R_{X,{\rm interp}}
=2\max\{r_{X,2},\omega_{X,{\rm rel}}\}\,s_{X,G}^{\rm fine}.
$$

On failure the interpolation cap is unresolved and no alternate grid or
mapping is permitted. Finally,

$$
\epsilon_{X,GQP}^{\rm emp}
=R_{X,{\rm proxy}}+R_{X,{\rm interp}},
\qquad X\in\{W,\Gamma,V\}.
$$

This amount is inserted exactly once in its component. Direct point oracle
defects, raw kernel differences, factor differences, and Bloch seam defects
are diagnostics feeding this single envelope, not extra summands.
Every result emits
`GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL`. This mapping does not claim
coverage of unresolved fine angular content. Nonfinite or nonpositive
diagnostic/finest scales, or a mismatch in diagnostic/fine full-$P$
association, make the GQP cap unresolved. The raw kernel envelope remains a
diagnostic and is not added a second time.

The field lower consumes only the shared wall trace, analytic wall weight,
frozen state, and $P_\pm$. Therefore

$$
\epsilon_{N,GQP}^{\rm emp}=0
$$

only if the executed dependency audit confirms that no kernel or boundary
action enters the field module. Otherwise the denominator cap is unresolved.

### 7.4 Component and total caps

For $X\in\{W,\Gamma,V\}$,

$$
\epsilon_X^{\rm emp}
=\sum_{a\in\mathcal A_X}R_{X,a}
+\epsilon_{X,GQP}^{\rm emp}
+R_{X,{\rm arithmetic}},
$$

where the incidence table is fixed as follows:

| component | axes |
|---|---|
| $W$ | wall target, wall source, full-$P$, GQP |
| $\Gamma$ | circle target, circle source, Riccati, full-$P$, GQP |
| $V$ | circle/wall value target, circle/wall source, lift Gauss, combined-volume full-$P$, GQP |

Wall and circle Fourier shells are diagnostic-only ledger rows with
$R_{X,{\rm Fourier}}=0$: the target-axis summand already contains their
aligned high-mode change. The total numerator cap is

$$
\epsilon_{\mathcal M}^{\rm emp}
=\epsilon_W^{\rm emp}+\epsilon_\Gamma^{\rm emp}+\epsilon_V^{\rm emp}.
$$

The new ordinary centers $B_W^\star,B_\Gamma^\star,B_V^\star$ come only from
the valid v2 evaluator,
$\mathcal M_h^\star=B_W^\star+B_\Gamma^\star+B_V^\star$. Historical ordinary
values are comparison diagnostics and are not reused as a v2 center.

## 8. Field lower, $q_{\rm emp}$, and nominal interval

The field lower remains the finite shared-trace quantity

$$
N_h^\star
=\sum_{\text{walls counted once}}
\sum_m b_m^{\rm w}|g_m|^2,
$$

with the frozen first-wall and $P_\pm$ indexing. Let
$N_8^{\rm dir},N_8^{\rm gram},N_8^{\rm comp}$ be the same frozen $N=8$
finite partial computed, respectively, by direct-factor action,
Gram-quadratic contraction, and compensated binary-tree accumulation. The
ordinary denominator center is fixed uniquely as

$$
N_h^\star=N_8^{\rm dir}.
$$

Let $N_{\rm hist}$ be the frozen ordinary-anchor value, and let
$N_{16}^{\rm dir},N_{32}^{\rm dir}$ use the same direct-factor path and
indexing with only the full-$P$ partial length increased. The one-sided
observed downward term is

$$
A_N^{\rm obs}
=\left[N_{\rm hist}-N_h^\star\right]_+
+\left[N_8^{\rm dir}-N_{16}^{\rm dir}\right]_+
+\left[N_{16}^{\rm dir}-N_{32}^{\rm dir}\right]_+,
\qquad [x]_+=\max\{0,x\}.
$$

The comparison operation ledger counts every complex multiply-add, real
reduction, and displayed subtraction used by these four values. With that
recorded count $n_{N,{\rm cmp}}$, set

$$
\omega_{N,{\rm cmp}}
=100n_{N,{\rm cmp}}\epsilon_{\rm mach}
\max\{\operatorname{realmin},|N_{\rm hist}|,
|N_8^{\rm dir}|,|N_{16}^{\rm dir}|,|N_{32}^{\rm dir}|\},
\qquad
A_N=A_N^{\rm obs}+\omega_{N,{\rm cmp}}.
$$

For the three $N=8$ paths define

$$
r_N=\max_{a,b\in\{{\rm dir},{\rm gram},{\rm comp}\}}
|N_8^a-N_8^b|,
$$

$$
s_N=\max\{\operatorname{realmin},
|N_8^{\rm dir}|,|N_8^{\rm gram}|,|N_8^{\rm comp}|\},
\qquad
\omega_N=100n_N\epsilon_{\rm mach}s_N,
$$

where $n_N$ is the recorded maximum operation count among the three paths.
The unique empirical denominator cap is

$$
\epsilon_N^{\rm emp}=A_N+2\max\{r_N,\omega_N\}.
$$

Positive full-$P$ growth from $N=8$ to $16$ or from $16$ to $32$ is reported
but contributes zero to the one-sided downward term. A negative increment or
$r_N>\omega_N$ is a nonblocking scientific warning and remains included by
the formula. The executed dependency ledger must show that this field
quantity consumes only the frozen shared wall trace, trace weights, and full
$P$ matrices; hence wall, circle, lifting, Riccati, and GQP action axes are
structural zero rows, including $\epsilon_{N,GQP}^{\rm emp}=0$. This zero is
invalid if any action or kernel module is referenced by the field-lower call
graph.

If all required empirical caps are finite and
$N_h^\star-\epsilon_N^{\rm emp}>0$, define

$$
q_{\rm emp}=
\frac{\mathcal M_h^\star+\epsilon_{\mathcal M}^{\rm emp}}
{\sqrt{N_h^\star-\epsilon_N^{\rm emp}}}.
$$

For $q_{\rm emp}<1$, apply the frozen asymmetric transform in $\mu$ and then
take square roots to report the nominal $k$ interval. The report states
whether its width is below $10^{-6}$. This is never a reliable interval,
strict upper bound, or existence statement.

## 9. Module, memory, and runtime contract

The thin entry `check_e_cap_v2` performs only the append-only output guard,
certificate dispatch, resource gates, state transitions, and output. The
scientific modules are separate function files:

- `i32v2_certificate_input`;
- `i32v2_gqp_module` and the sole GQP pair/remainder gateway;
- `i32v2_rect_kress_weights`;
- `i32v2_circle_module`;
- `i32v2_wall_module`;
- `i32v2_lifting_module`;
- `i32v2_fullp_cap_module`;
- `i32v2_result_output`.

Each module returns only compact metrics, aligned finest factors required by
later modules, uncertainty summaries, counters, and memory records. It must
not retain pair matrices, raw target samples, coarse arrays, interpolation
workspaces, or old raw maps. Every module records entry, local peak, retained,
largest object, and cleared-object memory. Pair products are streamed in
panels; full wall--circle rectangles are never retained.

Every return has the common fields
`schema,status,available,warnings,first_blocker,audit,counters,memory`.
The additional return/death contract is literal:

| module | permitted retained numerical fields and maximum shapes | consumer | death point |
|---|---|---|---|
| certificate | $P_\pm,D_\pm:97\times97$; $G_\pm:194\times97$; $c_\pm:97\times1$; $q_C:194\times1$; $E_\Gamma:512\times194$; $E_{L/R}:512\times194$; analytic center/shared vectors at most $512\times1$ | circle, wall, lifting, full-$P$ | density maps after wall; state matrices after full-$P$ |
| GQP | six-field production tables $65\times65\times6$, $129\times129\times6$, $257\times257\times6$; five variant tables or variant-minus-production tables $129\times129\times6\times5$; scalar proxy/interpolation/oracle ledgers | circle, wall, GQP cap | nonproduction tables immediately after all three diagnostic component factors/scales; production 257 table after wall; metrics after output |
| circle | finest aligned normal factors $F_{\Gamma,\pm}:2048\times97$; value-defect factors $V_{\Gamma,\pm}:2048\times97$; scalar level/cap/scale ledgers | lifting, full-$P$ | value factors after lifting; normal factors after full-$P$ |
| wall | finest internal-jump factors $F_{W,\pm}:4096\times97$; four side/value factors at most $4096\times97$; two recomputed first-lead singleton vectors at most $4096\times1$; scalar level/cap/scale ledgers | lifting, full-$P$ | value/singleton factors after lifting; jump factors after full-$P$ |
| lifting | combined lead factors $F_{V,\pm}:10240\times97$; center/first lift singleton coordinates at most $16384\times1$, consisting of four mutually orthogonal wall-strip blocks of at most $4096\times1$ each | full-$P$ | after full-$P$ |
| full-$P$ cap | scalar centers/caps, at most $97\times97$ Grams, interval/flag/warning/resource ledgers | output | publication complete |

The common recursive ownership audit walks every returned struct/cell field,
records its full field path, class, size, and `whos` bytes, and rejects a
numeric field exceeding its table shape or any name containing
`pair,kernel_matrix,raw_samples,coarse,workspace,raw_maps`. After each death
point, the entry clears the owner and repeats the walk over every live
struct/cell; a surviving forbidden path is
`RETURNED_DENSE_REFERENCE_RETAINED`.

Memory is an explicit conservative proxy, not an OS resident-set claim. At a
probe it is

$$
M_{\rm proxy}=M_{\rm live}+M_{\rm local}+M_{\rm COW}+M_{\rm publish},
$$

where $M_{\rm live}$ is the sum of `whos.bytes` for all registered entry-owned
variables, $M_{\rm local}$ is the sum for the module's explicitly registered
working arrays, $M_{\rm COW}$ is the largest shared input payload, and
$M_{\rm publish}=64$ MiB is reserved from the start for the partial artifact.
Each memory row stores all four terms, the largest named object, and the
module retained bytes.

Boundary application uses at most 128 target rows by 256 source columns per
panel; MFS table construction uses at most 512 difference targets per direct
proxy call. After every panel, the module updates compact partial metrics and
checks elapsed time and $M_{\rm proxy}$. A hard breach returns immediately
with the typed blocker and current compact data, so publication does not
depend on finishing the module. The publication-safe projection deletes MFS
tables, finest factors, raw/common-grid arrays, and incomplete panel arrays,
but retains completed scalar/Gram metrics, completed-panel/level/variant
indices, operation ledgers, and resource rows. Soft time is checked before every new module;
hard time and memory are checked at every panel. No uncheckpointed panel may
be enlarged after timing evidence is observed.

The MFS difference tables reduce proxy-source work to roughly
$6\times257^2\times320$ interactions. Registered diagnostic actions add an
estimated 250--900 seconds. Expected total runtime is therefore 13--32
minutes and expected peak is below 340 MiB. The 1500/1800 second soft/hard
gates remain unchanged, so hard time is a genuine preregistered blocker risk.
The hard active-memory gate is 2048 MiB. Crossing a soft gate prevents
starting a new module; crossing a hard gate saves the partial artifact with
the first blocker. No variant, level, or oracle may be removed to avoid that
outcome.

## 10. Failure semantics and outputs

The exact future output is
`test/i3/e-cap-v2/output/ecap-v2-a1`. Directory creation consumes the tag;
there is no retry or overwrite. A caught blocker must still save readable
`result.mat` and `report.md` containing completed objects and resource data.
The only formal command is

```text
matlab -batch "addpath(fullfile(pwd,'test','i3','e-cap-v2')); check_e_cap_v2('ecap-v2-a1',fullfile(pwd,'test','i3','e-cap','input','fbie-a1-certificate.mat'));"
```

The entry rejects every other attempt string and a pre-existing exact output
directory. It accepts the certificate only as an explicit function input and
rejects it by schema, frozen numerical digest, or semantic identity mismatch,
never by filename or path. It never discovers or reads historical output.

Only nonfinite data, dimension/identity failure, an unsolvable required linear
system, exact Wood/pole/branch failure, unavailable full-$P$ tail, nonpositive
required norm weight, a forbidden execution path, or hard time/memory limit
may stop execution. Finite refinement, interface, oracle, phase, shell, tail,
or interval failures are nonblocking warnings. They may leave a cap or
$q_{\rm emp}$ unresolved, but must not erase later finite diagnostics.

The artifact reports the frozen trial digest at every level, MFS parameters
and empirical evidence, zero image-sum audit, self/cross quadrature methods,
all numerator and denominator cap components, ordinary centers, field lower,
$q_{\rm emp}$, nominal interval and width test, warnings, unresolved items,
and the first blocker.

The following flags are always false:

- `outward_residual_upper`;
- `outward_field_lower`;
- `outward_tail_enclosure` and `certified_tail`;
- `certified_projected_gap`;
- `independent_reference`;
- `reliable_spectral_interval`;
- `continuous_eigenvalue_exists`.

The final label is always `EMPIRICAL / UNQUALIFIED`.

## 11. Review gates

Before implementation, Skeptic must explicitly approve:

1. the fixed analytic-center term versus recomputed first-lead
   value/flux/lift singleton terms and their aligned differences;
2. the MFS-only static and runtime closure;
3. nonperiodic proxy-remainder interpolation and seam handling;
4. rectangular circle and wall Kress formulas and jump signs;
5. separate source/target/no-resolve axes;
6. actual $T_o-T_i$ oracle;
7. componentwise, nonduplicated GQP propagation;
8. trace-only proof of $\epsilon_{N,GQP}=0$;
9. full-$P$ augmented differences and combined-volume association;
10. resource and append-only failure contracts.

After implementation and manufactured-oracle validation, Skeptic must conduct
a separate spec-to-code review. Only an explicit `spec-to-code PASS` authorizes
the formal `ecap-v2-a1` command.

## 12. `ecap-v2-a2` type-repair contract

This section is an append-only amendment after the blocked `ecap-v2-a1`
result. It changes numerical representation and retry ownership only. The
frozen trial, QZ/BIE state, densities, levels, thresholds, MFS-only kernel,
Kress and jump formulas, actual hypersingular difference, full-$P$ formulas,
cap and field-lower formulas, resource gates, and all claim flags are
unchanged.

### 12.1 Raw identity object and canonical computation view

The raw certificate remains byte-for-byte unchanged and is used only for
schema/semantic validation and the preregistered external numerical digest.
Before conversion, the loader must verify that `d` is a finite scalar and
that `double(raw.certificate.d)==1.0`. The raw digest is never computed from a
converted object.

After that gate, the formal entry constructs exactly one deterministic
canonical computation view. Every scientific module consumes only this view;
no module may receive or reconstruct the raw certificate. The canonical view
has:

- `d=1.0`, `rho_disk=17.0`, `M=48.0`, and `K=97.0`, all of class `double`;
- finite double continuous physics, matrices, densities, traces, anchors, and
  residual data;
- double-valued exact integers for all levels, panel sizes, Fourier orders,
  quadrature counts, Riccati/Gauss/full-$P$ counts, and indices before they
  enter division, normalization, geometry, Fourier, Green-kernel, Kress, or
  quadrature arithmetic; and
- logical values only as branch controls.

Every exact-integer conversion is checked for finiteness, integer value, and
exact representability. A shared production validator is called at the GQP,
circle, wall, lifting, and full-$P$ entries. It verifies the stage-required
double fields, shapes, finite values, `d==1.0`, positive spacings, registered
count tuples, and the canonical identity stamp. A type/class/spacing failure
is a typed implementation blocker.

The raw external digest ledger and canonical intra-run digest ledger are
separate. The raw owner is released after its last registered identity check;
the canonical density fields die after wall action, while the canonical state
and anchor survive through lifting/full-$P$. Verified stamps replace hashing
arrays after their declared death points.

Continuous physical constants, ratios, tolerances, and floating arithmetic
literals touched by this repair are written explicitly as double literals,
such as `1.0`, `2.0`, and `0.5`. Discrete loop and indexing literals may retain
integer meaning, but inherited MATLAB integer classes are never permitted in
scientific arithmetic.

### 12.2 Production-shared actual-certificate preflight

Static inspection and manufactured tests are insufficient. Before a formal
`a2` invocation, a nonformal preflight must load the actual frozen
certificate through the production identity gate, build the canonical view,
and dynamically execute the same production helpers used by the formal run.
It must verify:

1. positive finite double values of $d/N$ at every registered circle and wall
   source level;
2. finite double exterior/interior wavenumbers, wall Fourier wavenumbers,
   midpoint grids, and quadrature spacings;
3. a production MFS GQP construction with the unchanged `6/6/0/0` call
   ledger;
4. the production-shared circle wall-source action with 128 actual circle
   targets, $N_s=4096$, and streamed source panels of at most 256 columns;
5. a production-shared rectangular/off-grid Kress panel with the actual
   density prolongation, midpoint origin, spacing, and convention checks;
6. the shared wall, lifting, and full-$P$ entry type validator, production
   wall/circle lift weights, and actual $P_\pm c_\pm$ products; and
7. unchanged raw digest/classes, zero scientific solves, and no formal output
   creation.

The identity-mutation, Kress/jump/actual-$T$ boundary test, full-$P$/Fourier
shell test, mandatory MFS preflight, early hard-memory checkpoint, and late
GQP checkpoint tests must also pass. The actual preflight may retain and reuse
its production GQP tables within that test only; it does not authorize reuse
in the formal experiment.

### 12.3 Exact `a2` overwrite and retry ledger

The user explicitly replaces the earlier append-only rule for the exact tag
`ecap-v2-a2`. The entry accepts only this tag. If and only if its exact output
directory already exists, the entry may remove that exact directory and
recreate it. It must never remove or overwrite `ecap-v2-a1`, another attempt,
the output root, or a path derived from an unvalidated attempt.

The MATLAB configuration carries a static retry ordinal. Before every rerun,
the ordinal is incremented and the review receives an append-only row with
the prior invocation's command, status, first blocker, repair, and resource
summary. Runtime code never reads a historical result, review, Markdown file,
or output to choose scientific parameters. The artifact reports the ordinal,
whether an exact `a2` directory was replaced, and the frozen prior-attempt
ledger. The first planned `a2` invocation has ordinal 1 and zero prior `a2`
retries.

Researcher and Engineer returned `DESIGN AGREED` for this amendment. Skeptic
DESIGN and spec-to-code reviews remain mandatory before formal execution.

### 12.4 Canonical numerical-equivalence gate

The first Skeptic design audit identified one missing identity boundary. An
intra-run digest of a self-generated computation view cannot by itself prove
equivalence to the externally frozen raw object. The canonicalizer is
therefore frozen as a pure recursive class conversion over every whitelisted
leaf:

- struct and cell shape, field membership, cell ordering, array shape, and
  element ordering are preserved;
- every numeric leaf is replaced by `double(raw_leaf)` and no other numerical
  operation is permitted;
- complex real and imaginary parts are preserved elementwise;
- logical, character, string, and semantic metadata leaves are unchanged; and
- no leaf is removed, inserted, reordered, prolonged, recomputed, or
  normalized beyond the MATLAB class conversion itself.

Before releasing raw data, the canonicalizer audits every leaf for class rule,
shape, ordering, finite status where scientifically required, and exact
elementwise equality to `double(raw_leaf)`. The view is then compared against
an independently preregistered expected canonical digest stored as a literal
in MATLAB source. This digest was computed before implementing the production
canonicalizer by a separate design-time oracle applying the frozen pure
conversion rule. Runtime code does not recompute the expected value from its
own output.

Every module validator accepts only the stamp produced after both the
raw-to-canonical leaf audit and the expected canonical-digest comparison. A
self-consistent digest generated from an unverified view is insufficient. A
nonformal negative test must change one canonical numerical value and a second
test must exchange or omit a mapped field; both must typed-block before the
first scientific module. Raw and canonical digests and their death stamps
remain distinct.

### 12.5 Independently anchored post-wall release view

Implementation inspection found that a compact digest generated from the
same released object and stored in its authentication struct would provide
only accidental-integrity checking. It cannot authorize lifting or full-$P$
because the data and asserted digest could be changed together. This is a
design correction to the identity/death contract only; it does not change the
trial, numerical levels, thresholds, boundary actions, lifting, full-$P$,
majorant, cap, field-lower, or claim formulas.

The fixed post-wall projection has identifier
`I32V2_POST_WALL_RELEASE_V1`. It retains exactly the following fields, in the
listed order:

- certificate: `K`, `R`, `beta`, `d`, `rho_disk`, `gamma`, `delta_c`,
  `delta_w`, `Pplus`, `Pminus`, `cplus`, `cminus`, `center_wall_jumps`, and
  `mu_h`;
- ordinary anchor: `N_tilde`, `lead_field_factor_plus`, and
  `lead_field_factor_minus`; and
- input contract: `density_maps_released_after_wall=true` and the fixed
  `projection_id`.

All density maps, $G_\pm$, wall orders, source grids, and cell wall locations
therefore die before lifting. The entry keeps the already audited wall order
$M=48$ in its compact result ledger; $M$ is not a scientific input after this
death point.

A second independent design-time oracle must compute and preregister a
literal `expected_released_digest` from the expected full canonical object
under this exact projection. A third literal,
`expected_release_manifest_digest`, binds the manifest schema, projection
identifier, full and released view schemas, expected parent canonical digest,
expected released digest, exact field lists, and death point. Runtime release
code must:

1. authenticate the complete live view against the independent full digest;
2. project only the registered leaves and verify exact child-parent equality;
3. compare the live released digest to the independent released literal; and
4. compare the reconstructed manifest to the independent manifest literal.

Lifting and full-$P$ repeat the live released-digest and manifest checks at
entry. Stored Booleans, stored live digests, source stamps, or self-consistent
rehashing are audit evidence only and cannot authorize computation. Full views
are rejected at lifting/full-$P$; released views are rejected at GQP, circle,
and wall. There is no formal skip, override, or test mode.

Negative tests must typed-block, before scientific work, a retained numerical
mutation, deletion or addition of a retained field, a field mismatch, a
self-consistent forged data/digest/stamp combination, and a rewritten parent
digest. Manufactured low-level oracles remain separate from the formal module
gate; the actual frozen-certificate preflight exercises every formal module
entry.
