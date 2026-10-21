# I3.2 e-cap-v4: coupled residual fits and shifted trace lifting

## 1. Scope and claim

This design governs the independent experiment `test/i3/e-cap-v4` and the
overwriteable attempt `ecap-v4-a1`. It changes two numerical parts of the I3.2
empirical evaluation-cap application:

1. scalar residual/majorant sequences are fitted to an unknown nonzero limit;
2. the cubic strong-source lifting is replaced by a shifted trace norm and a
   trace right inverse.

The candidate, QZ state, $P_\pm$, wall trace, finite BIE densities, density
trigonometric interpolants, all-boundary layer-potential trial, full-$P$ tail
formula, ordinary field anchor, and all claim flags are frozen. No BIE or
density is solved. No old e-cap experiment helper is called. The only runtime
input from history is the frozen `fbie-a1-certificate.mat`; common verified
MFS and Kress primitives may be resolved normally on the MATLAB path.

Every conclusion is `EMPIRICAL / UNQUALIFIED`. In particular, no returned
quantity is a strict upper bound, reliable interval, certified enclosure, or
spectral-existence statement. This experiment remains method-dependent and is
not the independent reference reserved for I3.3. See
[[research/projects/eig-apost/implementation/i3/design-3-2a|I3.2 conditional theorem]]
for the separate strict conditional statement.

## 2. Minimal implementation and forbidden paths

The experiment contains at most five MATLAB files:

1. `check_e_cap_v4.m`: frozen configuration, certificate whitelist, dispatch,
   resource gates, and checkpoints;
2. `i32v4_boundary_sequence.m`: one fixed MFS table and four coupled boundary
   actions;
3. `i32v4_hhalf_lift.m`: shifted trace weights, the annulus ODE, and the one
   single-mode normalization oracle;
4. `i32v4_fit_cap.m`: full-$P$ contractions, scalar fits, empirical rows,
   field candidate, $q_{\rm emp}$, and the nominal interval; and
5. `i32v4_output.m`: compact `result.mat` and `report.md` output.

Executable code contains no SHA or digest, Git or source provenance, ownership
audit, identity ledger, repository discovery, MFS variant, image sum, parameter
sweep, or unrelated exception framework. Runtime checks are limited to sizes,
finite values, positive required norm weights, necessary linear-system and ODE
availability, the single-mode normalization oracle, and hard resource gates.

The fixed resource gates are $2048$ MiB and $1800$ seconds. Module memory
figures are compact MATLAB object proxies and are not reported as OS RSS.
Creating `output/ecap-v4-a1` does not consume the attempt permanently. Within
this task, the exact directory may be overwritten after a minimal repair; no
other attempt may be deleted.

## 3. Frozen trial and coupled levels

The trial in every material cell remains

$$
u_h(x)=\sum_{b\in\{L,R,\Gamma\}}
\bigl[D_b\tau_b(x)-S_b\zeta_b(x)\bigr].
$$

Only its numerical boundary evaluation changes. The circle and wall density
samples at every level are direct evaluations of the same frozen finite
trigonometric interpolants. The coupled levels are

$$
N_i=N_{\Gamma,i}\in\{1024,1280,1536,2048\},
\qquad N_{W,i}=2N_i\in\{2048,2560,3072,4096\}.
$$

At each $i$, one logical coupled boundary action performs one circle action and
one wall action. On each family, source and target counts are equal. The action
returns both value and normal defects. Hence the complete experiment executes
four logical coupled actions and eight physical family actions. There are no
separate target, source, self, or cross refinement cap axes. Self and cross
pieces may be retained as compact diagnostics, but only the total defect enters
the residual sequence.

$M=48$ denotes only the 97 coefficients of the prescribed artificial-wall
Dirichlet trace. It does not truncate circle modes, the layer-potential field,
or any boundary residual.

## 4. Fixed quasi-periodic Green function and self action

The only quasi-periodic Green-function construction is the verified MFS path
with

$$
(H,d_{\rm proxy},N_{\rm side},N_{\rm top},N_{\rm edge},M_{\rm pw})
=(1.1,0.2,160,160,80,32).
$$

One $2049\times2049$ six-field smooth-remainder table is used. There is no
MFS sweep, alternative table, spot qualification, image-sum fallback, or
Rayleigh field action. The inherited empirical GQP relative uncertainty is

$$
\rho_G=10^{-10}.
$$

For each residual row, its GQP term is $\rho_G$ times the sum of the full-$P$
norms of uniquely registered, non-cancelling GQP-only pieces after the row's
own trace weight. A physical total residual is not added again. Arithmetic
roundoff is excluded from this scale and reported separately.

Circle self interactions use the Kress split/product action, the correct jump
relations, and the actual exterior-minus-interior hypersingular difference.
Wall self interactions use the periodic-gauge Kress action and the correct
jump. Positive-distance wall--circle, opposite-wall, and other cross actions
use streamed smooth quadrature. The implementation panels all large actions;
it never materializes a full $4096^2$ dense Kress matrix.

## 5. Normal residual sequences

At each level, the total adjacent-wall outward Neumann sum and material-circle
normal defect are transformed only after layer-potential evaluation. With the
same frozen dual-trace weights and complete $P_\pm$ associations as the frozen
majorant, their full-P norms define

$$
B_W(N_i),\qquad B_\Gamma(N_i).
$$

Each center includes the unchanged complete-matrix infinite-tail formula at
$J=32$. The nonnormal and Jordan coupling in $P_\pm$ is retained; no modal
diagonalization is allowed.

## 6. Shifted $H^{1/2}$ trace lifting

### 6.1 Wall defects

On $I=(-d/2,d/2)$ use the orthonormal quasiperiodic basis

$$
\psi_m(y)=d^{-1/2}e^{\mathrm i\alpha_my},
\qquad \alpha_m=\beta+\frac{2\pi m}{d}.
$$

For midpoint samples, the coefficient convention is

$$
a_{s,m}=\frac{\sqrt d}{N_W}\sum_{j=0}^{N_W-1}
a_s(y_j)e^{-\mathrm i\alpha_my_j},\qquad s\in\{L,R\}.
$$

Define

$$
\lambda_m^W=\sqrt{\gamma+\alpha_m^2},\qquad
\|a_s\|_{H^{1/2}_\gamma}^2
=\sum_m\lambda_m^W|a_{s,m}|^2.
$$

The strip correction has $h(0)=1$ and $h(\delta_W)=0$. Its minimum energy for
one mode is $\lambda_m^W\coth(\lambda_m^W\delta_W)$. Therefore

$$
C_{E,W}^2=\coth(\lambda_{\min}^W\delta_W),\qquad
\lambda_{\min}^W=\min_{m\in\mathbb Z}\lambda_m^W.
$$

The same constant acts separately on left and right defects; the two defects
are never cancelled before taking their squared norms.

### 6.2 Circle defect and annulus ODE

For

$$
a_\Gamma=u_{\rm out}|_\Gamma-u_{\rm in}|_\Gamma,
$$

use the $L^2(\Gamma,\mathrm ds)$-orthonormal basis

$$
\phi_\ell(\theta)=(2\pi R)^{-1/2}e^{\mathrm i\ell\theta},
\qquad
a_{\Gamma,\ell}=\frac{\sqrt{2\pi R}}{N_\Gamma}
\sum_{j=0}^{N_\Gamma-1}a_\Gamma(\theta_j)
e^{-\mathrm i\ell\theta_j}.
$$

The negative Nyquist coefficient is retained. Set

$$
\lambda_{\Gamma,\ell}=\sqrt{\gamma+\ell^2/R^2},\qquad
\|a_\Gamma\|_{H^{1/2}_\gamma}^2
=\sum_\ell\lambda_{\Gamma,\ell}|a_{\Gamma,\ell}|^2.
$$

The correction is frozen to the exterior background collar
$r\in[R,R+\delta_\Gamma]$, disjoint from both wall strips. For every mode
retained at the finest level, solve

$$
-h_\ell''-\frac1r h_\ell'
+\left(\frac{\ell^2}{r^2}+\gamma\right)h_\ell=0,
\qquad h_\ell(R)=1,
\qquad h_\ell(R+\delta_\Gamma)=0.
$$

With the above boundary normalization, define

$$
E_{\Gamma,\ell}
=\int_R^{R+\delta_\Gamma}
\left(|h_\ell'|^2+
\left(\frac{\ell^2}{r^2}+\gamma\right)|h_\ell|^2\right)
\frac rR\,\mathrm dr
=-h_\ell'(R)>0.
$$

The finite-mode empirical right-inverse constant is

$$
C_{E,\Gamma}^2=
\max_{\ell\in\{-1024,\ldots,1023\}}
\frac{E_{\Gamma,\ell}}{\lambda_{\Gamma,\ell}}.
$$

This finest-set constant is fixed across all four levels. It does not enclose
the uncomputed infinite angular tail.

The ODE is integrated in $t=\log r$ by a fixed vectorized RK4 solve with 8192
steps. The only normalization oracle uses one retained mode, checks wall and
circle midpoint coefficient normalization, the strip energy, and the annulus
energy against the corresponding modified-Bessel value. It is one composite
single-mode oracle, not an oracle family.

### 6.3 Global lifted factor

Set

$$
C_A=1+\frac{\mu_h}{\gamma}.
$$

At every level, complete $P_\pm$ powers and the frozen tail formula act on the
weighted total value-defect factors. The resulting global quantity satisfies

$$
L(N_i)^2=C_{E,W}^2
\left(\|a_L\|_{H^{1/2}_\gamma}^2+
\|a_R\|_{H^{1/2}_\gamma}^2\right)
+C_{E,\Gamma}^2\|a_\Gamma\|_{H^{1/2}_\gamma}^2,
$$

and replaces the old cubic source term through

$$
B_{V,H^{1/2}}(N_i)=C_A L(N_i).
$$

No old Gauss lifting, cubic profile, strong-source weight, or $O(m^2)$ source
multiplier is executed or added to this quantity.

## 7. Four scalar sequences and general fits

Define

$$
\mathcal M(N_i)=B_W(N_i)+B_\Gamma(N_i)+B_{V,H^{1/2}}(N_i).
$$

For each scalar sequence

$$
X\in\{W,\Gamma,V,\mathcal M\},
$$

fit

$$
B_X(N)=B_{X,\infty}+C_XN^{-p_X},\qquad p_X>0.
$$

The code uses the algebraically equivalent stable column
$x_i=(N_i/N_1)^{-p}$; its fitted amplitude is rescaled, while
$B_{X,\infty}$ and $p_X$ are unchanged. It never fits $\log B_X$.

For the full four-point set and each of the four leave-one-out sets, write
$s=p/(1+p)$. A fixed grid of 4095 interior points in $s\in(0,1)$ locates the
best interior bracket, followed by `fminbnd`. A grid-endpoint minimizer makes
that fit invalid. At fixed $p$, ordinary two-column linear least squares
determines $B_{X,\infty}$ and the normalized amplitude. A fit is valid only if

- all inputs, predictions, $p$, and coefficients are finite;
- $p>0$ and $B_{X,\infty}\ge0$;
- the two-column problem has rank two and
  `rcond(A'*A) >= 1e-12`; and
- the minimizer is not at the numerical search endpoint.

For every valid fit $S$, evaluate its prediction on all four registered
levels, including the held-out point. If at least one of the five fits is
valid, define

$$
\epsilon_{X,\mathrm{fit}}
=\max_{S\,\mathrm{valid}}
|\widehat B_{X,\infty}^{,S}-B_X(N_4)|
+\max_{S\,\mathrm{valid}}\max_{1\le i\le4}
|B_X(N_i)-\widehat B_X^{,S}(N_i)|.
$$

If there is no valid fit, that component is unresolved without invalidating
the other three sequences. Adjacent differences are diagnostics only.

For a component whose entire sequence is below its already computed GQP plus
arithmetic floor, the component is labeled `PLATEAU`; its fit row is
$\max_i|B_X(N_i)-B_X(N_4)|$. The fit optimizer is not used for acceptance in
that case.

## 8. Full-$P$, GQP, roundoff, and empirical aggregation

Sequence centers use $J=32$ and the frozen infinite-tail formula. The separate
full-$P$ empirical row uses no geometric contraction gate:

$$
\epsilon_{X,P}=\max_{J\in\{8,16\}}
|B_X^{(J)}(N_4)-B_X^{(32)}(N_4)|.
$$

For $X\in\{W,\Gamma,V\}$, report

$$
\epsilon_X^{\rm emp}
=\epsilon_{X,\mathrm{fit}}+
\epsilon_{X,G}+\epsilon_{X,\mathrm{round}}+\epsilon_{X,P}
$$

when every required row is finite. The direct total fit is used for the
majorant cap; component fit caps are not summed again:

$$
\epsilon_{\mathcal M}^{\rm emp}
=\epsilon_{\mathcal M,\mathrm{fit}}
+\sum_{X\in\{W,\Gamma,V\}}
\left(\epsilon_{X,G}+\epsilon_{X,P}\right)
+\epsilon_{\mathcal M,\mathrm{round}}.
$$

The total roundoff has unique ownership:

$$
\epsilon_{\mathcal M,\mathrm{round}}
=\sum_X\epsilon_{X,\mathrm{round}}+
100\,\epsilon_{\rm mach}\,2
\max\{1,|B_W|,|B_\Gamma|,|B_V|,|\mathcal M|\}.
$$

The last term covers only the two scalar additions in $\mathcal M$. No tail,
GQP piece, roundoff path, or component fit is counted twice.

## 9. Companion field candidate and nominal interval

The ordinary trace-only anchor and its empirical denominator cap are evaluated
with the frozen full-$P$ formula. Define

$$
r_N=\max\{0,\widetilde N_h-\epsilon_N\},
$$

$$
N_{\mathrm{comp,lower}}
=\left[\max\{0,\sqrt{r_N}-L(N_4)\}\right]^2.
$$

$\epsilon_N$ is subtracted exactly once. Per the user-frozen formula,
$\epsilon_L$ is not added to $L(N_4)$. Therefore this quantity is only an
empirical companion field-lower candidate, not an enclosure. If $r_N=0$ or
$N_{\mathrm{comp,lower}}=0$, $q_{\rm emp}$ and the interval are unresolved,
while all independent rows remain published.

When $\epsilon_{\mathcal M}^{\rm emp}$ and
$N_{\mathrm{comp,lower}}>0$ are finite, set

$$
q_{\rm emp}=
\frac{\mathcal M(N_4)+\epsilon_{\mathcal M}^{\rm emp}}
{\sqrt{N_{\mathrm{comp,lower}}}}.
$$

If $q_{\rm emp}<1$, the nominal algebraic $\mu$ interval is

$$
\left[
\max\left\{0,\frac{\mu_h-q_{\rm emp}\gamma}{1+q_{\rm emp}}\right\},
\frac{\mu_h+q_{\rm emp}\gamma}{1-q_{\rm emp}}
\right],
$$

and the report takes square roots to obtain the nominal $k$ interval. Its
width is compared with $10^{-6}$ but never upgraded to a reliable claim.

## 10. Fail-open result contract

Nonfinite essential inputs, invalid dimensions, unusable required linear
systems, nonpositive required weights, a failed necessary ODE solve, an exact
MFS pole/undefined branch, unavailable full-$P$ tail, a hard resource limit,
or an unreadable artifact is a true execution blocker. A failed scalar fit,
large fit residual, nonmonotone sequence, warning from boundary recombination,
$q_{\rm emp}\ge1$, zero companion field candidate, or a wide interval is a
scientific warning or unresolved row. It does not erase independently finite
components.

The final report contains all four sequences; wall/circle shifted norms;
$C_A,C_{E,W},C_{E,\Gamma}$; all valid fit and leave-one-out records; fit, GQP,
roundoff, and full-$P$ rows; field quantities; resource diagnostics; retries;
warnings; unresolved rows; and the first true blocker. Reliability,
outward-enclosure, projected-gap, existence, independent-reference, and
reliable-interval flags are always false.
