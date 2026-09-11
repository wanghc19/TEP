# I5.1c design: nonzero-center residual-numerator enclosure

## Scope and governing result

I5.1c tightens the conditional finite majorant of I5.1b without changing its
continuous residual decomposition.  It evaluates only the frozen candidate,
density coefficients, QZ-selected states, propagation matrices, Rayleigh
coefficients, reconstruction rule, and accepted wall data.  It performs no
eigenvalue, BIE, QZ, propagation, denominator, or effectivity solve.

The governing result is (KR-1) of
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-kress-real]]:

$$
\|R\|_{\mu,*}
\le
\widehat B_{\Gamma_\pm}+\widehat B_\Upsilon
+\widehat B_{\mathrm{lift}},
$$

$$
\widehat B_{\mathrm{lift}}
=2\sqrt{\overline F_{\mathrm{lift}}^2+T_{\mathrm{lift}}^2}.
$$

The I5.1b zero-center enclosure bounded the complete local and off-surface
actions by absolute radii.  It was finite but discarded their principal
cancellation.  I5.1c replaces those two zero centers by signed, computable
finite centers and retains explicit source, target, kernel-series, and
off-surface quadrature radii.  The exact regular-image action remains centered
at zero until a separately enclosed special-function evaluator is available;
its radius must therefore enclose that complete action.

The shape-general theorem remains authoritative.  The circle identities used
below are only an adapter for the current frozen geometry and do not enter the
theorem hypotheses.

## Nonzero-center theorem used by the evaluator

For a retained row $|\ell|<L$, let $K$ be the exact local integrand pair,
$K_Q$ its signed finite-series pair, $\mathcal A$ the exact source-integration
operator, $Q_N$ the Kress product rule, $\mathcal D$ the exact target Fourier
functional, and $\mathcal D_N$ its $N$-point trapezoidal rule.  The implemented
local center is

$$
\widetilde d_\ell^{\mathrm{self}}
=\mathcal D_N[J+Q_NK_Q].
$$

The exact algebraic telescope

$$
\begin{split}
d_\ell^{\mathrm{self}}-\widetilde d_\ell^{\mathrm{self}}
={}&\{\mathcal D[J+\mathcal AK]-\mathcal D_N[J+\mathcal AK]\}\\
&+\mathcal D_N[(\mathcal A-Q_N)K]
+\mathcal D_N[Q_N(K-K_Q)]
\end{split}
$$

gives

$$
\|d_\ell^{\mathrm{self}}-\widetilde d_\ell^{\mathrm{self}}\|
\le
\epsilon_\ell^{\mathrm{tgt}}
+\epsilon_\ell^{\mathrm{src}}
+\epsilon_\ell^{\mathrm{series}}.
$$

The identity $J$ is in the center and target derivative bound exactly once.
It is absent from the source and series radii.  The series radius covers only
the difference between the exact signed kernel and its retained signed series;
it is not an unsigned bound for the finite operator.

With pointwise row-operator enclosures
$\delta_{r,ij}\ge\|K_r(t_i,u_j)-K_{r,Q}(t_i,u_j)\|_2$, define

$$
E_{\mathrm{ser},i}
=\sum_j|R_{ij}|\delta_{1,ij}
+\frac{2\pi}{N}\sum_j\delta_{2,ij},
\qquad
\epsilon_\ell^{\mathrm{series}}
=\frac{2\pi}{N\sqrt P}\sum_i s(t_i)E_{\mathrm{ser},i}.
$$

This finite expression is used for every retained $\ell$ and owns only the
third term of the telescope.

Let $\widetilde d_\ell^{\mathrm{off}}$ be the signed finite off-surface
Rayleigh center formed from the complete frozen finite Rayleigh support.  The
value action adds its raw value row.  The normal action subtracts its raw
normal row because the material-tail auxiliary convention is
$A_w^\nu=-\partial_\nu u_w$.  Only its retained target-quadrature error enters
$\epsilon_\ell^{\mathrm{off}}$; the off-surface high tail controls omitted
target-boundary Fourier rows $|\ell|\ge L$, not omitted Rayleigh source modes.
The regular-image center is zero and its radius encloses its complete exact
action.

Define, before taking absolute values,

$$
C_\ell^{\mathrm{val}}
=\widetilde d_\ell^{\mathrm{self,val}}
+\widetilde d_\ell^{\mathrm{off,raw,val}},
\qquad
C_\ell^{\mathrm{nor}}
=\widetilde d_\ell^{\mathrm{self,nor}}
-\widetilde d_\ell^{\mathrm{off,raw,nor}},
$$

$$
\epsilon_\ell
=\epsilon_\ell^{\mathrm{src}}
+\epsilon_\ell^{\mathrm{tgt}}
+\epsilon_\ell^{\mathrm{series}}
+\epsilon_\ell^{\mathrm{reg}}
+\epsilon_\ell^{\mathrm{off}}.
$$

Here the absent regular-image center is already owned by
$\epsilon_\ell^{\mathrm{reg}}$.  If $\mathscr C_\ell^\chi$ is the unit-density
version of $C_\ell^\chi$, the side maps and radii are

$$
C_{\varsigma,\ell}^\chi=\mathscr C_\ell^\chi G_\varsigma,
\qquad
\epsilon_{\varsigma,\ell}^\chi
=\delta_\ell^\chi\|G_\varsigma\|_2.
$$

The singleton uses $\mathscr C_\ell^\chi q_0$ and
$\delta_\ell^\chi\|q_0\|_2$.  Hence for every unit-density coefficient $x$,

$$
\|d_\ell(x)\|
\le \|\mathscr C_\ell x\|+\delta_\ell\|x\|.
\tag{I5.1c-1}
$$

Consequently the material finite normal and lifting energies are

$$
\overline F_\Upsilon^2
=\sum_{|\ell|<L}\frac1{b_\ell}
\left[
(|C_{0,\ell}^{\mathrm{nor}}|+\epsilon_{0,\ell}^{\mathrm{nor}})^2
+\sum_{\varsigma\in\{-,+\}}\sum_{n=0}^{J-1}
(\|C_{\varsigma,\ell}^{\mathrm{nor}}P_\varsigma^nc_\varsigma\|
+\epsilon_{\varsigma,\ell}^{\mathrm{nor}}
\|P_\varsigma^nc_\varsigma\|)^2
\right],
\tag{I5.1c-2}
$$

$$
\overline F_{\mathrm{lift},\Upsilon}^2
=\sum_{|\ell|<L}e_{\ell,\mathrm{val}}
\left[
(|C_{0,\ell}^{\mathrm{val}}|+\epsilon_{0,\ell}^{\mathrm{val}})^2
+\sum_{\varsigma\in\{-,+\}}\sum_{n=0}^{J-1}
(\|C_{\varsigma,\ell}^{\mathrm{val}}P_\varsigma^nc_\varsigma\|
+\epsilon_{\varsigma,\ell}^{\mathrm{val}}
\|P_\varsigma^nc_\varsigma\|)^2
\right].
\tag{I5.1c-3}
$$

The artificial-wall lifting finite square is added to (I5.1c-3) as a
disjoint collar contribution.  Crucially, (I5.1c-3) multiplies by
$e_{\ell,\mathrm{val}}$; division by a trace weight belongs only to
(I5.1c-2).

The same complete $C_{\varsigma,\ell}$ and $\epsilon_{\varsigma,\ell}$ are
used for the $n\ge J$ block-power tail.  With
$\sum_{n\ge0}\|P_\varsigma^nx\|^2\le K_\varsigma\|x\|^2$, the two retained-row
operator envelopes are

$$
\omega_{\varsigma,L}^{\Upsilon}
=\sum_{|\ell|<L}
\frac{(\|C_{\varsigma,\ell}^{\mathrm{nor}}\|
+\epsilon_{\varsigma,\ell}^{\mathrm{nor}})^2}{b_\ell},
$$

$$
\omega_{\varsigma,L}^{\mathrm{lift}}
=\sum_{|\ell|<L}e_{\ell,\mathrm{val}}
(\|C_{\varsigma,\ell}^{\mathrm{val}}\|
+\epsilon_{\varsigma,\ell}^{\mathrm{val}})^2.
\tag{I5.1c-4}
$$

The retained-row low-cell terms are explicitly

$$
\sum_\varsigma\omega_{\varsigma,L}^{\Upsilon}
K_\varsigma\|P_\varsigma^Jc_\varsigma\|_2^2,
\qquad
\sum_\varsigma\omega_{\varsigma,L}^{\mathrm{lift}}
K_\varsigma\|P_\varsigma^Jc_\varsigma\|_2^2.
$$

The local,
regular-image, and off-surface high-$|\ell|$ sequence norms are first added
within the same physical defect and only then squared.  Disjoint wall and
material collars are summed after squaring.  This is the tail construction of
(KR-28) and (KR-31), not a second retained-row radius.

## Current-circle signed series adapter

Put $h=t-u$, $x=4R^2\sin^2(h/2)$,
$p_T=R^2\sin h$, $p_n=x/2$, and $\ell_R=\log(R^2)$.  For
$\alpha_\kappa=\kappa^2/4$, define the signed coefficients

$$
a_{\kappa,n}=\frac{(-\alpha_\kappa)^n}{(n!)^2},
\qquad
y_{\kappa,0}=0,
\qquad
y_{\kappa,n}=H_na_{\kappa,n}\quad(n\ge1),
$$

$$
b_{\kappa,m}=-2(m+1)a_{\kappa,m+1},
$$

$$
r_{\kappa,m}
=-\frac{a_{\kappa,m+1}}{2\pi}
+2c_\kappa^0(m+1)a_{\kappa,m+1}
+\frac{(m+1)y_{\kappa,m+1}}\pi,
$$

where

$$
c_\kappa^0=\frac{\mathrm i}{4}
-\frac{\log(\kappa/2)+\gamma_E}{2\pi}.
$$

The $J$ and regular $Y$ series retain orders $0,\ldots,Q$, while the shifted
$J$, $J^{[1]}$, and $\mathfrak c$ series retain
$0,\ldots,Q-1$.  Their first omitted orders are therefore $Q+1$ and $Q$,
respectively.  The existing factorial-tail ratio gates must be strictly below
one.  With

$$
q_{\kappa,n}
=\left(-\frac{\ell_R}{4\pi}+c_\kappa^0\right)a_{\kappa,n}
+\frac{y_{\kappa,n}}{2\pi},
$$

and, only for the current CCW circle with its stated outward normal,

$$
W_Q=\frac{\ell_R}{4\pi}
(J_{\kappa_e,Q}^{[1]}-J_{\kappa_i,Q}^{[1]})
+(\mathfrak c_{\kappa_e,Q}-\mathfrak c_{\kappa_i,Q}),
$$

the cancellation-safe split is

$$
S_{\kappa,1}=-\frac{R}{4\pi}J_{\kappa,Q},
\qquad
S_{\kappa,2}=R q_{\kappa,Q},
$$

$$
D_{\kappa,1}=D_{\kappa,1}^*
=\frac{x}{8\pi}J_{\kappa,Q}^{[1]},
\qquad
D_{\kappa,2}=D_{\kappa,2}^*
=-\frac1{4\pi}
+x\left(\frac{\ell_R}{8\pi}J_{\kappa,Q}^{[1]}
+\frac12\mathfrak c_{\kappa,Q}\right).
$$

Only differences of the last expressions enter the defects:

$$
\Delta D_1=\frac{x}{8\pi}\Delta J_Q^{[1]},
\quad
\Delta D_2=\frac{x}{2}W_Q,
\quad
\Delta C_1^{\mathrm{tan}}
=\frac{p_T}{4\pi}\Delta J_Q^{[1]},
\quad
\Delta C_2^{\mathrm{tan}}=p_TW_Q.
$$

Here every $\Delta$ means exterior minus interior, in particular
$\Delta S_j=S_{\kappa_e,j}-S_{\kappa_i,j}$.  The equality
$D_{\kappa,j}=D_{\kappa,j}^*$ in the displayed circle formulas is an adapter
identity only; it is not used by the shape-general theorem.

Thus the common cotangent and $x^{-1}$ principal parts cancel before any
absolute value is taken.  For
$\eta=(\eta_1,\eta_2)^{\mathsf T}=(\tau,-\sigma)^{\mathsf T}$ and
$A_j=\kappa_e^2S_{\kappa_e,j}-\kappa_i^2S_{\kappa_i,j}$, the signed complete
integrands are

$$
K_j^{\mathrm{val}}
=\Delta D_j\eta_1-\Delta S_j\eta_2,
$$

$$
K_j^{\mathrm{nor}}
=-A_j\cos(h)\eta_1
-\frac{\Delta C_j^{\mathrm{tan}}}{R}\eta_1'
+\Delta D_j\eta_2.
\tag{I5.1c-5}
$$

The identity centers are $J_{\mathrm{val}}=\eta_1$ and
$J_{\mathrm{nor}}=-\eta_2$.  The Kress logarithmic weights already contain
their integration scale; the smooth $K_2$ sum is multiplied by $2\pi/N$.
The offset table is the exact periodic index
`mod((0:N-1)-(0:N-1).',N)+1`.

## Input, output, and ownership ledger

The versioned experiment is `test/i5/residual-numerator-v2/`.  It has explicit
entry points

```matlab
experiment_input = build_residual_numerator_input_v2( ...
  artifact_path, curve_contract_path, wall_finite_squared, ...
  wall_tail_squared, input_path, wall_provenance_label)

result = residual_numerator_v2(input_path, output_path)
```

The builder reads only the named frozen I3 artifact and curve certificate and
receives the wall finite and tail squares as explicit scalars.  It writes a
self-contained input bundle.  The evaluator reads only that bundle and writes
only its explicit create-once result path.  Neither entry point reads Markdown,
Git metadata, repository layout, or an earlier experiment output.

| contribution | center | retained radius | omitted tail | ownership rule |
|---|---|---|---|---|
| local identity and self action | signed finite Kress and target DFT row | source plus target plus tail-only series | (KR-24)--(KR-25) | identity occurs only in the center and target bound |
| regular image | zero | complete exact-action Ewald radius | explicit regular-image angular tail | an absorbed Taylor tail is not added again |
| off surface | signed finite Rayleigh row using the complete frozen finite source support | retained target quadrature | positive-distance target-Fourier tail | retained $|\ell|<L$ and omitted $|\ell|\ge L$ target rows are disjoint |
| propagation | complete combined row map | complete retained row radius | block-power tail from $n\ge J$ | the low-cell map is not identity-only |
| artificial wall | accepted existing center/radius data | its accepted retained radius | wall high-mode and cell tail | disjoint from the material collar |

All solve counts for eigenpairs, densities, QZ subspaces, and propagation
matrices must be zero.

## Cutoffs, gates, and failure semantics

The residual cutoff $L$ is selected and frozen from the complete explicit
local, regular-image, and off-surface omission tails.  Then the even evaluation
count satisfies

$$
N>2\max\{L,M_\eta\}.
$$

With $L$ fixed, $N$ may increase only to meet a predeclared retained-row
radius tolerance.  The cell cutoff $J$ may increase only to meet the explicit
block-power allocation.  No selection uses an inter-level difference,
convergence plateau, Richardson extrapolation, fitted rate, or empirical
safety factor.

The run fails closed for NaN or Inf, a dimension or index mismatch, a retained
Nyquist row, a density-sign or normal-sign mismatch, a non-Wood or outgoing
branch failure, an invalid factorial or Ewald ratio, a missing source, target,
series, Fourier, off-surface, regular-image, or cell-tail owner, an identity
count other than one, a lifting weight used in the denominator, or a nonzero
solve count.  A finite majorant that exceeds its tightness allocation is still
persisted and reported as a failed tightness gate.

Every number is ordinary floating point and is labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.  It can instantiate the mathematical
finite-plus-tail construction only under the documented real-arithmetic and
primitive-function enclosure conditions; it is not an outward-rounded
certificate.

## Review and run budget

Researcher review established the nonzero-center telescope and the signed
circle adapter.  The independent pre-code Skeptic verdict was `GO` with the
mandatory conditions recorded above.  A second static review is required
after implementation and before execution, followed by an independent result
review.

The planned canonical MATLAB run, including input construction and evaluation,
is at most 8 minutes and 1.6 GiB peak resident memory.  It is one scientific
attempt under the default 30-minute plan, 40-minute hard stop, and 2 GiB hard
memory limit of `test/AGENTS.md`.  Operational repairs reuse
`output/residual-numerator-a1/`.  Actual command, elapsed time, peak memory,
output paths, gates, and numerical results will be appended only after the
run.

## Bounded retained/high regular-image revision

Run-01 showed that the positive-width regular-image zero-center radius created
an $N$-independent normal floor of $1421.9904464646568$.  This was a valid but
unnecessarily coarse retained-row use of the strip certificate.  The bounded
revision applies the same Ewald finite-plus-tail theorem on two disjoint target
Fourier sets:

- for retained $|\ell|<L$, it evaluates the complete zero-center action bound
  on the real boundary, using real displacements, zero imaginary displacement,
  source and target normal components bounded by one, and certified density
  $L^1(\mathrm ds)$ row norms;
- for omitted $|\ell|\ge L$, it retains the width-$0.2$ complex-strip
  full-action bound required for exponential target-Fourier decay.

Writing $K_{pq}^{(0)}$ for the real-axis exact regular-image kernel bounds, the
retained radii are

$$
\epsilon_{\ell,\mathrm{reg}}^{\mathrm{val},(0)}
=\sqrt P\,[K_{01}^{(0)}A_\tau+K_{00}^{(0)}A_\sigma],
$$

$$
\epsilon_{\ell,\mathrm{reg}}^{\mathrm{nor},(0)}
=\sqrt P\,[K_{11}^{(0)}A_\tau+K_{10}^{(0)}A_\sigma].
$$

Both $K_{pq}^{(0)}$ values contain their retained reciprocal, retained
nonzero-image, branch-free local finite terms and all M-R/M-I/M-L remainders.
M-T is absorbed once in the retained-image full-action bound.  The real-axis
radius is not added to the high-mode strip tail.  The additional fail-closed
gates are `retained_real_axis_full_action`,
`high_target_fourier_strip`, `retained_high_target_index_disjoint`, and
`M_T_absorbed_once_per_index_scope`.

This revision remains zero-centered for the regular image and does not claim a
signed special-function enclosure.  It changes no center, density, propagation
state, or strong-residual formula.

## Constant-speed target-alias refinement

The current geometry certificate supplies an exact constant-speed
parameterization.  This property is not specific to a circle and may hold for
any smooth curve after arclength parameterization.  For $|\ell|<N/2$, the
exact DFT alias identity and (KR-23) give the alternative target radius

$$
\epsilon_{\ell}^{\mathrm{tgt,alias}}
\le
\frac{Q_2P^{3/2}}{4\pi^2}A_{\ell,N},
\qquad
A_{\ell,N}=\sum_{q\ne0}|\ell+qN|^{-2}.
$$

The evaluator encloses $A_{\ell,N}$ with the explicit terms
$1\le q\le Q_A=64$ on both sides.  With $a=|\ell|$ and $q_0=Q_A+1$, each
remaining monotone series is bounded by its first omitted term plus its
integral:

$$
\begin{split}
A_{\ell,N}\le{}&
\sum_{q=1}^{Q_A}[(qN-a)^{-2}+(qN+a)^{-2}]\\
&+(q_0N-a)^{-2}+[N(q_0N-a)]^{-1}\\
&+(q_0N+a)^{-2}+[N(q_0N+a)]^{-1}.
\end{split}
$$

The retained target radius is the minimum of this bound and (KR-19).  These
are two bounds for the same target error and are not added.  Fail-closed gates
require certified constant speed, $|\ell|<N/2$, finite $Q_2$, positive tail
denominators, and the explicit finite-sum-plus-integral-tail construction.

## Canonical attempt and provenance

All three executions below belong to the same scientific method and therefore
reuse `test/i5/residual-numerator-v2/output/residual-numerator-a1/`.  Run-01
implemented the reviewed signed local and off-surface centers.  Run-02 was the
bounded retained/high regular-image correction.  Run-03 added only the
proved constant-speed target-alias alternative above and is the final result.
No execution solved an eigenproblem, BIE system, QZ problem, or propagation
problem.

The explicit frozen inputs were

- `test/i3/e-cap/input/fbie-a1-certificate.mat` for the candidate, densities,
  QZ-selected states, propagation matrices, and Rayleigh data;
- `test/i5/wall-curve-a1/input/circle-contract-a1.mat` for the current curve
  certificate; and
- the accepted artificial-wall squares
  $3.5088928806097918\times10^{-20}$ and
  $1.2402726533962042\times10^{-63}$, supplied as scalar builder arguments.

The canonical command form was

```text
/usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath(repo); addpath(experiment); checkcode(builder); checkcode(evaluator); build_residual_numerator_input_v2(artifact,curve,wall_finite_sq,wall_tail_sq,input,label); residual_numerator_v2(input,output);"
```

The attempt logs did not persist the original shell argument vector or the
non-authorizing descriptive `label`, so this is the complete reproducible core
rather than a claimed character-for-character transcript.  The three
create-once `(input,output)` pairs were respectively
`(residual-numerator-v2.mat,result.mat)`,
`(residual-numerator-v2-run-02.mat,result-run-02.mat)`, and
`(residual-numerator-v2-run-03.mat,result-run-03.mat)`; their diaries and
resource files carry the corresponding run numbers.

The planned budget for each execution was at most 8 minutes and 1.6 GiB; the
scientific-attempt limits were 30 minutes planned, 40 minutes hard, and 2 GiB
hard memory.  The observed resources were

| execution | purpose | elapsed | maximum RSS |
|---|---|---:|---:|
| run-01 | signed local/off-surface center | 17.81 s | 1023131648 bytes |
| run-02 | retained real-axis regular radius | 17.37 s | 1063583744 bytes |
| run-03 | constant-speed target alias bound | 18.27 s | 1010253824 bytes |

The run-02 scientific evaluation completed correctly.  A later read-only
diagnostic initially requested a nonexistent report field and failed; the
failed diagnostic and its corrected audit are both retained.  This did not
change or rerun the scientific computation.

## Final run-03 numerical result

Run-03 selected $L=256$ and $N=514$, satisfying
$N>2\max\{L,M_\eta\}$.  Every reported scalar is labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.  The finite-plus-tail assembly is

| quantity | finite square | tail square | component bound |
|---|---:|---:|---:|
| artificial wall | $3.5088928806097918\times10^{-20}$ | $1.2402726533962042\times10^{-63}$ | $1.8732039079101324\times10^{-10}$ |
| material normal | $9040379.054306915$ | $1.1504507314502783$ | $3006.7225021204808$ |
| lifting | $140060464291.15997$ | $1978187.5735129558$ | $748498.34329471563$ |

Thus the persisted ordinary floating-point majorant is

$$
\widehat{\mathcal M}=751505.06579683628.
$$

The material tail square contains a local Fourier norm
$1.0725905750023095$, a regular-image high norm
$4.3355574740697292\times10^{-19}$, an off-surface high norm
$7.4344181578157276\times10^{-21}$, and a low-cell square
$1.8986649341259547\times10^{-7}$.  The lifting tail square contains the
corresponding values $1406.4805617464724$,
$3.1758719627299378\times10^{-16}$,
$6.208012752484522\times10^{-18}$, and $0.0029422831013296256$, plus the two
disjoint collar squares $4.7237321401724473\times10^{-11}$ and zero.

The constant-speed target bounds reduce the retained local target maxima to
$0.0074369915644510592$ for value and $0.063607714304987059$ for normal.  The
remaining dominant zero-center regular-image radii are
$136.37489934999303$ and $1094.7813067510401$.  Hence the complete maximum
retained radius is $1095.3128606361292$, above the declared tolerance
$10^{-6}$.  The material and lifting omission-tail allocations also fail.
These three tightness failures are persisted; they do not erase the finite
majorant, but they prevent an instance-level `COMPLETE` conclusion.

All 33 required-true gates and all four required-false gates passed.  The
audit found no nonfinite value or negative radius among 205830 checked
entries, and all four solve counts were zero.  The final status is
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY`; this priority status string does
not imply that either tail allocation passed.

The independent final Skeptic verdict is `GO` only for the structural
finite inequality in the declared roundoff-excluded scope.  Tightness and
stopping are `FAIL`.  The shortest next step is a rigorously enclosed nonzero
center for the regular-image normal action; increasing $N$ alone cannot
remove its $1094.7813067510401$ zero-center floor.
