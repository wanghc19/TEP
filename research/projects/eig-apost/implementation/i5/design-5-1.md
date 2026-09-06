# I5.1 design: evaluation-only artificial-wall tail instance

## Scope and authority

This design instantiates only the conditional $B_{\Gamma_\pm}$ theorem in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-wall-tail]].
It consumes the frozen bundle produced by the I3 full-boundary reconstruction
and follows the side/sign convention in
[[research/projects/eig-apost/implementation/i3/design-3-1f]].  It does not
alter or rerun the candidate eigenpair, BIE density solve, QZ selection, or
propagation matrices.  It does not estimate $B_\Upsilon$, $B_{\rm lift}$, the
complete $\|R\|_{\mu,*}$, a quotient, or an eigenvalue error.

The executable is `test/i5/wall-tail-a1/wall_tail_a1.m`.  Its interface is

```matlab
result = wall_tail_a1(artifact_path, output_path)
```

Both paths are explicit inputs.  The function reads only the MAT artifact and
MATLAB source constants; it does not read Markdown, Git metadata, manifests,
or historical reports.  Every output is labeled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`: the mathematical remainder formulas are
used, but ordinary floating-point evaluation is not an outward-rounded
certificate.

## Frozen instance and assumptions

The expected artifact schema is `staged.certificate`, `staged.raw_maps`, and
`staged.ordinary_anchor` from
`test/i3/e-cap/input/fbie-a1-certificate.mat`.  The current geometry fixes the
circle center at $(0,0)$, $X_L=-1/2$, $X_R=1/2$, and $R=0.2$, hence

$$
\delta=\min\{-X_L,X_R\}-R=0.3.
$$

The code rejects a different center convention rather than guessing one.
The finite density contract is

$$
\widehat T_\tau
=\frac1{256}\operatorname{fftshift}(\operatorname{fft}(\tau_{\rm native})),
\qquad
\widehat T_\sigma
=\frac1{256}\operatorname{fftshift}
  (\operatorname{fft}((-\sigma)_{\rm native})),
$$

with orders $-128{:}127$ and no midpoint phase.  The frozen notation is
$\eta=(\tau,-\sigma)^T$; the code name for its second coordinate is
`single_layer_density_sigma`.  The artifact's historical label
`[tau;zeta], zeta=-sigma` is mandatory at the input boundary only.  The target
midpoint phase used by old wall-output DFTs is not part of this source-density
transform.

The first run fixes $M=256$, $J=32$, block length
$J_\varsigma^{\rm blk}=32$,

$$
a=\frac12\log(D/R),\qquad D=|x_w|=0.5,
$$

and $N_q=4096$.  In particular $0<a<\log(D/R)$.  All flat-wall density
orders $-256{:}255$ and all center Rayleigh orders $-48{:}48$ lie in the
finite part.

## Step-to-check algorithm

### 1. Schema, branch, and support

Form

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\gamma_m^2=\widehat k^2-\beta_m^2,
$$

using the outgoing/decaying branch.  Check every retained order for a nonzero
radicand and the correct branch sign.  Compare orders $-48{:}48$ to the frozen
`branch_port` as an ordinary consistency audit.  Check

$$
\frac{2\pi}{d}(M+1)-|\beta|>\widehat k,
$$

which proves that every omitted order is strictly evanescent.  Verify the
wall-density and center-Rayleigh supports are covered.

The shifted-energy and artificial-interface trace weights use the frozen
notation

$$
\mu=\widehat k^2,
\qquad
\lambda_m=\sqrt{|\beta_m|^2+\mu},
\qquad
\omega_m=2\lambda_m\tanh(h_{\rm tr}\lambda_m),
\qquad h_{\rm tr}=\frac12.
$$

### 2. Density normalization

Split `eta_unit_256` into the native $\tau$ and stored $-\sigma$ maps and
apply the
preceding FFT exactly once.  Set

$$
T_\tau=\sqrt{2\pi R}\widehat T_\tau,
\qquad
T_\sigma=\sqrt{2\pi R}\widehat T_\sigma.
$$

The code obtains $T_\sigma$ from the stored $-\sigma$ block; the sign does
not affect the normalization or any norm bound.

Check discrete Parseval and the artifact density-coordinate label.  No BIE
solve or density refinement is allowed.

### 3. Finite wall coefficient rows

For each retained $m$, evaluate the exact Rayleigh circle-to-wall target-normal
integrand at the $N_q$ equispaced source angles.  For a wall at $x_w$ with
$\varsigma=\operatorname{sign}(x_w)=n_w\cdot e_x$ and
$D=|x_w|$, write

$$
E_{\varsigma,m}(z)
=\exp\!\left(\mathrm i\gamma_m[D-\varsigma R\cos z]\right)
 \exp\!\left(-\mathrm i\beta_mR\sin z\right),
$$

$$
q_{\varsigma,m}(A)
=\int_0^{2\pi}\frac{R}{2\sqrt d}E_{\varsigma,m}(\theta)
\left\{
\mathrm i[\varsigma\gamma_m\cos\theta+\beta_m\sin\theta]
t_\tau(\theta;A)+t_{-\sigma}(\theta;A)
\right\}\,d\theta.
$$

Here $t_\tau(\theta;A)$ and $t_{-\sigma}(\theta;A)$ are the frozen finite density
maps after composition with a finite state map $A$.  This displayed row is
the simplified cell-outward derivative of the frozen layer ansatz; it fixes the source
normal, target normal, and stored $-\sigma$ density sign in one formula.  It
is evaluated by the periodic trapezoidal rule.  The finite flat-wall parts are
exact modal algebra on the frozen coefficients:

$$
Q_{L,m}^{\rm flat}=\frac12(\xi_{L,m}-E_m\xi_{R,m}),
\qquad
Q_{R,m}^{\rm flat}=\frac12(-E_m\xi_{L,m}+\xi_{R,m}),
\qquad E_m=e^{\mathrm i\gamma_mL}.
$$

Their sums define $\widetilde Q_L,\widetilde Q_R$.

### 4. Analytic trapezoid remainder

For the vector density maps, compute

$$
D_\tau(a)=\sum_\ell
\|\widehat T_{\tau,\ell}\|_2e^{|\ell|a},
\qquad
D_\sigma(a)=\sum_\ell
\|\widehat T_{\sigma,\ell}\|_2e^{|\ell|a}.
$$

The implementation deliberately uses the conservative branch-aware strip
bound, rather than the sharper orthogonality refinement.  For a propagating
order, put

$$
\log\Phi_{m}^{\rm pr}
=R(|\gamma_m|+|\beta_m|)\sinh a.
$$

For an evanescent order $\gamma_m=\mathrm i\kappa_m$, put

$$
\log\Phi_m^{\rm ev}
=-\kappa_mD
+R\left(\kappa_m\cosh a+|\beta_m|\sinh a\right).
$$

For either branch use

$$
L_m(a)=(|\gamma_m|+|\beta_m|)\cosh a
$$

and

$$
M_{a,m}(A)
=\frac{R}{2\sqrt d}\Phi_m
\left[L_m(a)D_\tau(A,a)+D_\sigma(A,a)\right].
$$

Then use

$$
\epsilon^Q_m=\frac{4\pi M_{a,m}}{e^{aN_q}-1}
$$

from the authority note.  All exponentials used only to form this upper bound
are assembled in the logarithmic domain.  If its display value lies below
`realmin`, the implementation records the logarithm and replaces the ordinary
display by `realmin`; this enlarges the displayed mathematical remainder and
avoids a silent zero.

Form each composed row remainder directly, without cancellation:

$$
\epsilon_{+,m}
=\epsilon_{R,m}(G_+)+\epsilon_{L,m}(G_+P_+),
\qquad
\epsilon_{-,m}
=\epsilon_{L,m}(G_-)+\epsilon_{R,m}(G_-P_-).
$$

The singleton errors are $\epsilon_{L,m}(G_+c_+)$ and
$\epsilon_{R,m}(G_-c_-)$.

### 5. Side, sign, and singleton indexing

Build only the theorem rows

$$
\widetilde\ell_+
=\widetilde Q_RG_++\widetilde Q_LG_+P_+,
\qquad
\widetilde\ell_-
=\widetilde Q_LG_-+\widetilde Q_RG_-P_-.
$$

For $q^{\rm cen}=[q_L;q_R]$, form componentwise

$$
d_{L,m}=\mathrm i\gamma_m(q_{L,m}-E_mq_{R,m}),
\qquad
d_{R,m}=\mathrm i\gamma_m(E_mq_{L,m}-q_{R,m}),
$$

embed only orders $-48{:}48$, and form the two disjoint center/first rows

$$
\widetilde j^{\rm cf}_{-}=-d_L+\widetilde Q_RG_-c_-,
\qquad
\widetilde j^{\rm cf}_{+}=d_R+\widetilde Q_LG_+c_+.
$$

Executable audits check the frozen identities for $G_\pm$, the stored I3
$J_\pm$ association, the center derivative, wall order embedding, and the new
analytic rows against the stored ordinary maps.  Stored I3 maps never enter
the bound; their comparison is labeled ordinary and non-certifying.

### 6. Whole-matrix propagation

For each side $\varsigma\in\{-,+\}$ compute ordinary spectral norms of
$P_\varsigma^r$, $0\le r<J_\varsigma^{\rm blk}$, and
$P_\varsigma^{J_\varsigma^{\rm blk}}$.  If the latter is not below one, stop.
Otherwise assemble

$$
K_\varsigma=
\frac{\sum_{r=0}^{J_\varsigma^{\rm blk}-1}
\|P_\varsigma^r\|_2^2}
{1-\|P_\varsigma^{J_\varsigma^{\rm blk}}\|_2^2}.
$$

This is a full-matrix block-power calculation; no eigenvalue-by-eigenvalue or
spectral-radius substitution is allowed.  Since the norms are ordinary
floating-point values rather than outward upper bounds, this experiment does
not claim to close the theorem's certified block-power gate.

### 7. Positive-distance constants and assembly

Compute $A_{\tau,\varsigma},A_{\sigma,\varsigma}$ and their first-cell
singleton analogues from the normalized density maps exactly as defined in the
authority note.  Evaluate $\mathcal C_\varsigma(M)^2$ and
$\mathcal C_{\varsigma,0}(M)^2$ in logarithmic form so that
the factor $e^{-4\pi\delta(M+1)/d}$ cannot silently underflow.

Finally assemble the authority note's disjoint finite and omitted pieces,

$$
B_{\Gamma_\pm}\le
\sqrt{\overline F_{M,J}^2+T_{M,J}^2}
\le\overline F_{M,J}+T_{M,J}.
$$

The result records both right-hand sides, every component of $T^2$, all row
remainder maxima and logarithms, and the mandatory non-certification label.

## Success criteria and failure semantics

The run is operationally complete only if:

1. the schema, branch, non-Wood, support, density-label, side, sign, and index
   audits execute and all structural gates pass;
2. both ordinary block-power contractions satisfy
   $\|P_\varsigma^{J_\varsigma^{\rm blk}}\|_2<1$ with
   $J_\varsigma^{\rm blk}=32$;
3. all finite rows, remainders, density constants, $\mathcal C$ values,
   $\overline F^2$, and $T^2$ are finite and nonnegative;
4. the output says `claim_scope = B_GAMMA_PM_ONLY`,
   `roundoff_excluded = true`, and
   `reliability_certified = false`;
5. no solver, density refinement, QZ decomposition, or propagation-matrix
   construction is called.

An operational failure is fixed and rerun in `attempt-1`.  Adjacent-resolution
drift, a convergence plateau, and historical I3 values are never stopping
criteria.  A later outward-rounded implementation may use the explicit
remainder threshold in the theorem, but this ordinary run cannot itself be
reported as a reliable numerical upper bound.

The ordinary I3 cross-check is intentionally outside the bound.  In the
frozen instance, the analytic $Q_L,Q_R$ rows agree with the saved ordinary
maps at roughly $10^{-18}$ relative scale, but multiplication by the frozen
$G_\varsigma$ and cancellation in $\ell_\varsigma$ amplify machine-level
absolute changes to percent-level relative changes in the very small internal
rows.  This is not repaired by a safety factor; it is recorded as a
conditioning caveat and is another reason the output remains
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Planned resources

The function loads one roughly 39 MiB artifact and holds at most two
$4096\times513$ complex kernel arrays, two $4096\times194$ density arrays,
and several $513\times194$ or $513\times97$ maps.  The planned complete run is
under 10 minutes and below 1 GiB peak memory.  It is evaluation-only and shares
one attempt lifecycle under `test/i5/wall-tail-a1/output/attempt-1/`.

## Shape-general parameter-curve extension

The follow-up evaluator is deliberately separate from the accepted
circle-special evaluator.  `test/i5/wall-tail-a1/wall_tail_a1.m` and its
existing output remain frozen.  The new core is
`test/i5/wall-curve-a1/wall_tail_curve_a1.m`, with interface

```matlab
result = wall_tail_curve_a1(artifact_path, curve_contract_path, output_path)
```

The circle regression adapter is
`build_circle_contract_a1(artifact_path, curve_contract_path)`.  Only this
adapter knows that the present geometry is a circle.  It recovers the omitted
geometry by calling `geom.construct_cont` with the frozen radius and writes a
data-only curve contract.  The general evaluator never uses $R\cos t$,
$R\sin t$, a Bessel formula, or a circle Fourier diagonal.

### General finite row

Let $r(t)=(x(t),y(t))$ be a counter-clockwise, regular, $2\pi$-periodic
parameterization and put

$$
v(t)=\sqrt{x'(t)^2+y'(t)^2},
\qquad
\nu(t)=\frac{(y'(t),-x'(t))}{v(t)}.
$$

For a wall $x=X_\varsigma$, define
$\rho_\varsigma(t)=\varsigma(X_\varsigma-x(t))>0$.  In the frozen density
coordinate $(\tau,-\sigma)$ the exact target-normal row is

$$
q_{\varsigma,m}(A)
=\frac1{2\sqrt d}\int_0^{2\pi}
e^{\mathrm i\gamma_m\rho_\varsigma(t)-\mathrm i\beta_my(t)}
\left[
\mathrm i(\varsigma\gamma_my'(t)-\beta_mx'(t))t_\tau(t;A)
+v(t)t_{-\sigma}(t;A)
\right]dt.
$$

This uses $v\nu=(y',-x')$ and therefore introduces no discrete division by
speed in the double-layer term.  The single-layer term retains the parameter
measure $v(t)dt$ explicitly.  Substitution of the project circle contour
recovers the earlier circle-special row, but that substitution is used only
by the adapter and regression audit.

### General strip contract

For a selected $a>0$, a non-circle curve is admissible only if a separate
geometry argument supplies mathematically justified finite constants

$$
I_x(a),\ I_y(a),\ V_x(a),\ V_y(a),\ V_s(a),\
\delta_{-,a},\ \delta_{+,a}>0.
$$

They bound the imaginary parts of $x,y$, the moduli of $x',y'$ and the
analytic speed branch, and the real part of each complexified wall
separation.  The curve and speed branch must be analytic and nonzero in the
closed strip.  With the same density constants $D_\tau,D_\sigma$ as above,
the conservative shape-general integrand bound is

$$
M_{\varsigma,m}
=\frac{\Phi_{\varsigma,m}}{2\sqrt d}
\left[
(|\gamma_m|V_y+|\beta_m|V_x)D_\tau+V_sD_\sigma
\right].
$$

For propagating modes use

$$
\Phi_{\varsigma,m}^{\rm pr}
=\exp(|\gamma_m|I_x+|\beta_m|I_y),
$$

and for $\gamma_m=\mathrm i\kappa_m$ use

$$
\Phi_{\varsigma,m}^{\rm ev}
=\exp(-\kappa_m\delta_{\varsigma,a}+|\beta_m|I_y).
$$

The periodic trapezoid remainder remains

$$
\epsilon_{\varsigma,m}(A)
=\frac{4\pi M_{\varsigma,m}(A,a)}{e^{aN_q}-1}.
$$

The circle adapter supplies the exact specializations

$$
I_x=I_y=R\sinh a,
\quad
V_x=V_y=R\cosh a,
\quad
V_s=R,
\quad
\delta_{\varsigma,a}=D_\varsigma-R\cosh a.
$$

### General high-mode density constant

Let $v_{\max}$ be an explicit real-axis speed upper bound.  Parseval and
Cauchy--Schwarz give, for the ordinary parameter Fourier coefficients,

$$
\|\tau\|_{L^1(ds)}
\le 2\pi v_{\max}\|\widehat T_\tau x\|_2.
$$

Thus the previous $A_{\tau,\varsigma},A_{\sigma,\varsigma}$ definitions are
retained with the general factor $2\pi v_{\max}$.  For the regression circle
$v_{\max}=R$, so this is exactly the earlier $2\pi R$ factor.  The subsequent
positive-distance $\mathcal C(M;A,B)$ and full-$P_\varsigma$ formulas are
unchanged, with $\delta$ read from the curve contract rather than inferred
from a radius.

### Current artifact and missing geometry

The frozen certificate contains the density and all state/propagation data,
but it does not contain a geometry selector, center, contour samples,
parameter derivatives, or strip constants.  These are not blockers for the
current instance:

1. the existing producer fixes `geom.construct_cont(N,'circle',0,0,R)` and
   aligns the 256 density samples with $t_j=2\pi j/256$;
2. the builder re-evaluates the authority geometry at 256 and 4096 nodes;
3. it writes only
   `test/i5/wall-curve-a1/input/circle-contract-a1.mat`;
4. no eigenpair, BIE density, QZ object, or propagation matrix is regenerated.

No star or other non-circle input is created in this study.  A future general
shape must provide the same data-only contract and prove its strip constants;
an unsupported or merely sampled analytic bound is a geometry-contract
failure, not an empirical tail estimate.

### Regression and output layout

All generated files stay in the new experiment:

```text
test/i5/wall-curve-a1/
  build_circle_contract_a1.m
  wall_tail_curve_a1.m
  input/
    circle-contract-a1.mat
  output/
    attempt-1/
      result.mat
      run-NN-{operational,complete}.txt
```

The old circle artifact is consumed read-only by explicit path and is never
copied, changed, or overwritten.  The new result records the artifact path,
curve-contract path, curve audit, coefficient enclosures, and the same
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` qualification.

Regression compares the general finite rows, remainder records, density
constants, high-mode logs, $F$, $T$, and the full-$P_\varsigma$ values with
the circle-special evaluation.  An ordinary-roundoff-scaled tolerance is
only a code-equivalence check: it never enters a remainder, a safety factor,
or the stopping rule.

For the stored finite maps, $Q_L,Q_R$ use their ordinary relative defects.
The strongly cancelling $\ell_\varsigma$ and singleton comparisons instead
use absolute differences divided by $\max(1,\|\text{stored row}\|)$; this
prevents a tiny reference row from turning machine-scale absolute noise into
a misleading failed regression.  The common threshold is an implementation
identity tolerance only and is not added to $\epsilon_{\varsigma,m}$.

### Resource plan and success criteria

There is one complete scientific regression run.  Contract generation,
circle-special reference evaluation, shape-general evaluation, and comparison
share that run and the same `attempt-1`.  The planned wall time is below five
minutes and peak workspace below $0.5$ GiB, safely inside both the repository
default budget and the user-authorized outer limits.

Before launch, both new files must pass MATLAB Code Analyzer.  A complete run
requires the curve/grid/orientation/clearance/strip gates, branch and non-Wood
gates, side/sign/index gates, and both block-power contractions to pass.  It
must record zero spectral, BIE-density, QZ, and propagation-matrix solves.
Any ordinary regression tolerance is reported separately from the theorem
inputs.  Regardless of regression agreement, the result remains ordinary
floating point and cannot be called a certified numerical upper bound.

### Completed circle regression

The single declared run completed in
`test/i5/wall-curve-a1/output/attempt-1/`.  It consumed the frozen artifact
read-only, generated
`test/i5/wall-curve-a1/input/circle-contract-a1.mat`, and wrote
`test/i5/wall-curve-a1/output/attempt-1/result.mat`.  The earlier
`test/i5/wall-tail-a1/output/attempt-1/result.mat` was not a governing input
and retained its 2026-09-06 13:47:12 CST modification time.

The ordinary shape-general evaluation gave

$$
\overline F_{256,32}
=1.8732039079101324\times10^{-10},
\qquad
T_{256,32}
=3.5217504928603392\times10^{-32}.
$$

Both displayed combined bounds were
$1.8732039079101324\times10^{-10}$.  The geometry, outgoing branch,
density, side/sign/index, ordinary regression, non-Wood, and
omitted-evanescent gates all passed.  The frozen-map regression defects were
$1.8808308472918602\times10^{-18}$ and
$1.1589003111869179\times10^{-18}$ for $Q_L,Q_R$.  The cancellation-safe
scaled absolute defects were at most
$3.6691329182703657\times10^{-15}$ for the internal rows and
$1.5478375293503543\times10^{-15}$ for the singleton rows.  These are
implementation checks only and were not added to any remainder or stopping
criterion.

For the general theorem's G4 gate, the implemented factor
$2\pi v_{\max}$ is precisely the consequence of the two explicit
dominating bounds

$$
M^{\mathrm{up}}=2\pi v_{\max}I,
\qquad
L^{\mathrm{up}}=2\pi v_{\max}.
$$

Indeed,
$\sqrt{L^{\mathrm{up}}}
\|(M^{\mathrm{up}})^{1/2}C\|_F
=2\pi v_{\max}\|C\|_F$.
Thus the evaluator instantiates G4 through a mass-matrix domination and a
length upper bound; it does not substitute an unweighted nodal norm.  For the
circle contract $v_{\max}=R$, recovering the earlier $2\pi R$ factor.

The complete MATLAB command took 13.873845416 seconds.  Contract generation
took 0.259384125 seconds, the evaluator call took 0.660815958 seconds, the
evaluator's saved internal time was 0.611435292 seconds, and its workspace
proxy was 90.957354546 MiB.  MATLAB Code Analyzer reported zero issues for
both new files.  The run performed zero eigenpair, BIE-density, QZ, or
propagation-matrix solves.

All persisted values remain labeled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` with `reliability_certified = false`.
Passing the general-curve regression does not provide outward-rounded
arithmetic and does not extend the claim beyond $B_{\Gamma_\pm}$.

## Read-only regular-image implementation audit

The general $B_\Upsilon$ and $B_{\mathrm{lift}}$ reductions require uniform
complex-strip bounds for the local-free-subtracted quasi-periodic Green
kernel through mixed normal order.  A bounded Engineer audit found no such
certificate in the current code:

- `+kernel/precomp_proxy.m` and `+kernel/qpgreen_mfs_pairmat.m` build a finite
  MFS proxy plus finite outgoing Rayleigh approximation.  They return value,
  gradient, and target Hessian data but no infinite-dimensional remainder,
  exact-Wood failure certificate, or near-Wood lower bound.
- `+op/construct_A_QP.m` subtracts the primary free singularity and evaluates
  the diagonal regular part through the same finite proxy.  This is useful for
  ordinary samples, not a uniform exact-kernel enclosure.
- the archived Linton Eq. (2.65) implementations support ordinary value and
  derivative checks at finite tuples $(a_E,M_1,M_2,N)$, but their truncation
  acceptance is based on inter-tuple changes.  No spectral, image, Taylor, or
  special-function tail field is present.
- the I3 v4 table adds interpolation and an inherited empirical uncertainty;
  it cannot enter a strict I5 remainder.

The theory-to-data verdict is now `Kpq CONDITIONAL GO` and
`NEW EVALUATOR CONDITIONALLY IMPLEMENTABLE`.  Equations (M-R-tail),
(M-I-tail), (M-T-tail), and (M-L10)--(M-L14) in `s-material-tail.md` provide
the previously missing reciprocal, real-image, Taylor, and branch-free local
truncation tails.  Existing code still implements none of those certificates.
The constants $K_{pq}$ depend only on the frozen
$\widehat k,\beta,d$ and geometry, so a future evaluator would not need to
resolve the candidate, BIE densities, QZ subspaces, or propagation matrices.
It must enclose the finite complex-tube geometry, non-Wood margins, normal
weights, retained `erfc`/exponential-integral values, and the displayed ratio
gates.  The shape-general local free-space panel constants are specified
separately in `s-local-panel.md`; no incomplete $K_{pq}$-only scientific run
is started here.

### Wall-to-boundary data boundary

The new $p=0,1$ wall-to-boundary lemma is not the action evaluated by
`wall-curve-a1`: that completed experiment maps the material curve to the
artificial walls for $B_{\Gamma_\pm}$.  Its contract nevertheless supplies
$a$, the wall positions, tangent upper bounds, speed upper bound, and signed
complex clearances.  For the current circle the additional theorem quantities
are available without any solve:

$$
\vartheta_{-,a}=\vartheta_{+,a}=R,
\qquad P_\Lambda=2\pi R,
\qquad \Sigma_a=\sigma_a=Ra.
$$

At $R=0.2$, $D=0.5$, and
$a=\tfrac12\log(2.5)$, the ordinary displayed values are
$D-R\cosh a\approx0.278640563788214$ and
$Ra\approx0.0916290731874155$.  These values are not persisted as a new
wall-to-boundary certificate.  Such an evaluator would use a separate
experiment and add `speed_lower`, `boundary_length`, `arclength_imag_upper`,
`signed_arclength_strip_lower`, and a positive full-wall-support non-Wood
margin with a branch ledger.  No rerun of the completed $B_{\Gamma_\pm}$
experiment is mathematically warranted, and none is performed.

## Shape-general local-panel implementation decision

The authority is (P1)--(P29) of `s-local-panel.md`.  Its independent Skeptic
audit returned `PASS WITH CONDITIONS`: the proof reduces the local
free-space self-action to finite enclosures, but those enclosures have not
been instantiated.  This section is therefore an implementation decision,
not a completed evaluator or a numerical result.

A future minimal evaluator would use the following stages.

1. Read the frozen state/density coefficient maps and a validated curve
   contract; do not resolve the eigenpair, densities, QZ factors, or
   propagation matrices.
2. Combine the two material free-space kernels before bounding, subtract the
   periodic logarithm, and enclose the cancellation-safe chord and normal
   divided differences from (P3)--(P10).  Insert each identity jump exactly
   once.
3. Split each retained source panel as in (P11)--(P14).  Evaluate its
   logarithmic moments and Taylor polynomial with finite enclosures, and
   attach the proved singular, regular, off-diagonal, and entire-series
   remainders.  Project the resulting target action into each retained
   arclength-Fourier row using a validated target-row quadrature with its own
   finite remainder; an ordinary sampled target grid is only a diagnostic.
4. Form the normal local tail from (P20) and the value/lifting local tail from
   (P29), including the density and identity terms specified there.
5. For every retained or omitted modal row, add the local, regular-image, and
   off-surface row bounds by the same triangle inequality.  Only after this
   modal combination may the existing block-power or Lyapunov propagation
   argument be applied.  No cancellation among the three actions is used.
6. Persist the finite rows, every remainder and gate, and the resulting
   module-local verdict with the roundoff caveat.

The current circle contract does not yet persist the finite certificates
needed by these stages.  In addition to its real-node samples and wall-strip
data, the future input/result boundary needs validated fields for
`boundary_length`, `reach_lower`, `curvature_upper`, `speed_lower`,
`speed_upper`, `speed_derivative_upper`, and the required higher curve jets;
the corresponding density-derivative coefficient bounds; the
`chord_quotient_enclosure` and `normal_divided_difference_enclosures`; the
four first-target factors and four second-target factors denoted by
$C^\#$ and $R^\#$ in (P15)--(P29); the panel subdivision, periodic-log moment,
Taylor-derivative, off-diagonal chord, and entire-kernel series certificates;
and the retained target-row quadrature remainder.  For the circle, length,
reach, curvature, speed, and all curve jets can be generated directly from
the authoritative radius formula without a solve, but ordinary samples of
the existing nodes do not certify them.

One future complete run is planned for less than 20 minutes and less than
0.75 GiB peak memory; the hard limits are 45 minutes and 3 GiB for all stages
of that run together.  No run is started in this round.  Both complete
$B_\Upsilon$ and $B_{\mathrm{lift}}$ still require two uninstantiated finite
enclosure families: the regular-image $K_{pq}$ certificates and the local
panel certificates above.  Neither family currently has an implementation,
and a sampled grid cannot supply the theorem constants.  Outward-rounded
arithmetic is outside this round's scope; an ordinary floating-point display
would remain `NON_CERTIFIED_ROUNDOFF_EXCLUDED` and would not change the
`CONDITIONAL GO` verdict.

## Residual-numerator evaluator and completed attempt-1

This later implementation closes the two finite families identified above;
it appends to and does not alter the completed wall design.  The source is
`test/i5/residual-numerator-a1/residual_numerator_a1.m`, and its data-only
input is built by `build_residual_numerator_input_a1.m`.  Both functions take
explicit paths and refuse to overwrite an existing input or result.

### Exact-QP regular-image evaluator

The governing decomposition is

$$
G_\beta^{\mathrm{QP}}=G^{\mathrm{free}}+H_\beta.
$$

`LOCAL_ewald_regular_coordinates` evaluates the finite Ewald representation
of $H_\beta$ directly.  It retains reciprocal orders $|m|<N_R$, nonzero
images $0<|j|<N_I$, and Taylor orders $0{:}N_T$, then subtracts the
branch-free local canonical term.  It returns derivatives in the order
$(00,10,01,20,11,02)$.  Source-normal, target-normal, and mixed-normal
contractions are formed afterward, so $K_{00},K_{01},K_{10},K_{11}$ retain
their distinct normal weights.

`LOCAL_ewald_certificate` independently assembles the M-R reciprocal tail,
M-I omitted-image tail, M-T retained-image Taylor tail, and M-L branch-free
factorial tail from `s-material-tail.md`.  It retains every finite $1/q_m$,
requires the outgoing branch and nonzero retained denominators, and checks
all first-omitted-term ratios.  The regular retained-row radius is the sum of
the finite-Ewald source-trapezoid remainder, the four Ewald truncation tails
acting on the real-source density integral, and the target-row trapezoid
remainder.  No MFS proxy, interpolation drift, or comparison with a second
Ewald tuple enters a radius.  Finite `Faddeeva_erfc`, `expint`, exponential,
and polynomial values remain ordinary floating-point centers.

### Shape-general local free-space evaluator

The local center is the Müller-combined Kress action.  Exterior and interior
kernels are combined before absolute values; cotangent terms in the normal
action cancel before the spectral derivative; value and normal identities
are inserted once.  Chord and hypersingular factors use only the
cancellation-safe quantities of (P3)--(P10), never bare $1/q$ or $1/q^2$.

The retained-row enclosure uses the direct analytic Kress specialization
(P30)--(P34) in `s-local-panel.md`.  The result therefore states
`P11_P14_taylor_panel_used=false` and
`equivalent_kress_alias_enclosure_used=true`: it separately persists the
logarithmic alias factor, smooth source-trapezoid factor, propagated source
radius, and target-row radius.  This is an alternative proved enclosure, not
a relabeling of an unimplemented panel Taylor rule.  A zero-free normalized
chord, fixed analytic logarithm branch, and simultaneous target/source shift
are mandatory gates.

For the normal center, the implemented source radius uses the actual Maue
form in (P31M)--(P31N), not the direct hypersingular factors.  It persists
$A'_{\tau,a}=\sum_n|n|e^{a|n|}\|C_{\tau,n}\|_2$, the weighted
single-layer-difference log/smooth bounds, and the target-tangential
derivative bounds.  The universal cotangent terms are cancelled in
$N_2^{(e)}-N_2^{(i)}$ before these absolute bounds are applied.

The circular adapter supplies these general-contract fields using the exact
identity $c(z,w)=R^2$.  The evaluator consumes only curve and certificate
fields, uses neither a circle Fourier/Bessel diagonalization nor a radial
collar theorem, and rejects a general curve lacking the same certificates.
The identity-inclusive (P20) and (P29) bounds remain high-mode fallbacks.
The selected high tail is the smaller of that fallback and an independently
valid combined analytic-strip tail; both values and the selected route are
persisted.

The 256-point `run-04` retained every unambiguous mode $|\ell|\le127$ and put
both Nyquist directions into the tail.  Its explicit lifting-tail
contribution was $1.6212330523568548\times10^{-6}$, exceeding the preset
$10^{-6}$ budget.  That proved remainder, not inter-grid drift, triggered the
512-point tier.  Preliminary `run-05` established that partition, but its
first Skeptic review found that the normal source radius used direct-$T$
instead of Maue factors.  Corrected `run-06` retains $|\ell|\le255$, puts
both Nyquist directions into the tail, and uses (P31M)--(P31N).  The frozen
256 density coefficients are merely evaluated on the finer grid; no density
solve is performed.

### Material-normal and lifting assembly

For every retained angular order, `LOCAL_combined_rows` first forms

$$
d_{0,\ell}=d_{0,\ell}^{\rm loc}
 +d_{0,\ell}^{\rm reg}+d_{0,\ell}^{\rm off},
\qquad
d_{1,\ell}=d_{1,\ell}^{\rm loc}
 -d_{1,\ell}^{\rm reg}-d_{1,\ell}^{\rm off},
$$

and adds the three row radii by the triangle inequality.  Trace or tubular
weights are applied only afterward.  The center state, retained propagated
cells, block-power cell tail, and angular tail remain disjoint.  The
artificial-wall value lift uses the audited center/singleton/left/right/full-
$P$ convention; it is combined in energy with the material lift and the
factor two is applied only once.  The final assembly is

$$
{\cal M}=B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}.
$$

The accepted ordinary wall scalar is copied into the new input with its
source path and field.  Historical output is not read at runtime.

### Gates, stopping, and failure semantics

Acceptance requires the geometry and density audits, outgoing/non-Wood and
finite-denominator gates, normalized-chord/log-branch gates, local and Ewald
ratio gates, off-surface clearance, both full-matrix block contractions,
finite retained rows with explicit source/target radii, complete wall value
lifting, and both preset $10^{-6}$ tail budgets.

NaN, Inf, a wrong branch, zero denominator, failed ratio, or invalid index is
an operational failure.  A finite tail above budget is saved as
`FINITE_BOUND_STOPPING_TOLERANCE_FAILED_ORDINARY` and may justify the next
predefined evaluation tier.  No adjacent-grid difference, plateau,
Richardson estimate, empirical safety factor, MFS residual, or FEM/BIE
agreement is computed or used.

### Attempt-1 provenance and numerical result

The final MATLAB R2023b batch sequence was `addpath; checkcode;
build_residual_numerator_input_a1; residual_numerator_a1`, with explicit paths
recorded in `output/attempt-1/run-06-log.txt`.  Planned resources were 900
seconds and 768 MiB; hard limits were 2700 seconds and 3072 MiB.  The combined
process took 16.546608125 seconds, including Code Analyzer and input
generation.  The builder took 0.257003458 seconds, the evaluator's saved
internal time was 2.1182619166666665 seconds, and its workspace proxy was
118.28492259979248 MiB.  The OS peak RSS was unavailable because the outer
macOS timing command triggered an XType startup failure; no OS peak is
claimed.  Code Analyzer reported zero issues.

The new `input/residual-numerator-a1-r4.mat` contains 512-point curve jets,
normals and arclength weights; length/reach/curvature/speed bounds; self-tube
and normal bounds; cancellation-safe real and complex normalized-chord data;
and all Ewald/panel/cutoff gates.  It neither replaces the frozen artifact nor
overwrites earlier I5 inputs.

`result-run-06.mat` gives

| contribution | finite squared | omission tail squared | displayed bound |
|---|---:|---:|---:|
| material normal $B_\Upsilon$ | $3.2193220359367991\times10^{-20}$ | $1.3677685284608814\times10^{-37}$ | $1.7942469272474174\times10^{-10}$ |
| material value-lift energy | $2.7355844433165910\times10^{-23}$ | $1.4975288023347799\times10^{-34}$ | $1.0460562974011611\times10^{-11}$ after factor two |
| artificial-wall lift energy | $3.1139087765059116\times10^{-29}$ | $8.6948911397344519\times10^{-47}$ | included in total lift |

Consequently,

$$
\begin{split}
B_{\Gamma_\pm}&=1.8732039079101324\times10^{-10},\\
B_\Upsilon&=1.7942469272474174\times10^{-10},\\
B_{\mathrm{lift}}&=1.0460568927625959\times10^{-11},\\
{\cal M}&=3.7720565244338099\times10^{-10}.
\end{split}
$$

The shares are $49.6600169106\%$, $47.5668091298\%$, and
$2.77317395958\%$.  All six primary gates and the combined stopping gate
passed.  Both block norms were below $6.591\times10^{-18}$, the finite
non-Wood radicand margin was $3.1090469326375971$, and all four solve counts
are zero.

For the requested diagnostic prediction, the authority remains
`phase3-analysis/s-estimator.md` and `implementation/i3/design-3-2a.md`:

$$
q_{\rm pred}=\frac{{\cal M}}{\sqrt{\widetilde N}},
\quad
\lambda_-=\frac{\mu-q_{\rm pred}\gamma}{1+q_{\rm pred}},
\quad
\lambda_+=\frac{\mu+q_{\rm pred}\gamma}{1-q_{\rm pred}}.
$$

With the stored ordinary $\widetilde N=4.959111810675795$ and
$\gamma=\mu=3.359046932637597$, `run-06` has
$q_{\rm pred}=1.6938550447966990\times10^{-10}$.  The predicted
$\mu$-interval has center $3.3590469326375976$, half-width
$1.1379472919514910\times10^{-9}$, and full width
$2.2758945839029820\times10^{-9}$.  The corresponding $\widehat k$ interval
has center $1.8327702891081570$, half-width
$3.1044472001593563\times10^{-10}$, and full width
$6.2088944003187127\times10^{-10}$.

Every number in this subsection is tagged
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`; `reliability_certified` remains false.
The interval is a non-certified prediction, not an eigenvalue enclosure.

The independent final Skeptic verdict for corrected `run-06` is `PASS` with
high confidence and no blocker.  In particular, (P31M)--(P31N) were checked
against the two terms of the actual Maue `Tdiff` center, including the
parameter derivative of $\tau$, the absence of an extra source-speed factor
in the $\Delta N$ term, and cotangent cancellation before absolute values.
The only review note was to complete the run ledger; `run-06-log.txt` now has
status `COMPLETE_RESIDUAL_NUMERATOR_ORDINARY` and records all resources,
components, gates, prediction fields, and zero solve counts.
