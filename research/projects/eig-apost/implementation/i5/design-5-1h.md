# I5.1h full signed material-jump high-tail design

## Scope and governing result

I5.1h changes only the material value-jump lifting high-mode evaluation.  It
implements (ME-P4.1)--(ME-P4.22) in `s-lift-tail.md`.  It does not change the
frozen reconstruction, retained physical row definition, minimum-energy
weights, material-normal or wall-normal modules, artificial-wall lifting, or
any propagation matrix.

The attempt-2 conditional ideal result

$$
B_{\mathrm{lift}}=5.5685129828202118\times10^{-4},
\qquad
H_{\mathrm{mat}}=5.5630101040626736\times10^{-4}
$$

triggers the mandatory v7 gate because the material high norm exceeds half
the complete lifting bound.  These ordinary floating-point numbers motivate
the route only; they prove no new bound.

For one material interface, the governing high-mode object is the complete
physical row

$$
\mathscr A=\mathscr A^{\mathrm{self}}
+\mathscr A^{\mathrm{reg}}+\mathscr A^{\mathrm{off}},
\tag{I5.1h-1}
$$

with the value identity contained once in the self term and every component
already composed into the same frozen state space.  The primary theorem is

$$
\sum_{|\ell|\ge L}\overline w_{\Lambda,\ell}
\|\mathscr A_\ell\|_2^2
\le\min_{p\in\mathcal P_{\mathrm{pass}}}
(T_{\Gamma,p}^{\mathrm{full}}(L))^2,
\qquad \mathcal P_{\mathrm{pass}}\subseteq\{6,8\},
\tag{I5.1h-2}
$$

where $T_{\Gamma,p}^{\mathrm{full}}$ is (ME-P4.12).  Order six is primary.
Order eight is evaluated only if the $C^{10}$ geometry and every order-eight
row-ball gate pass; it is an alternative bound of the same omitted set, not
an added tail.

## Full signed derivative producer

Use target panels $I_a$ and wrapped relative panels $H_b$.  Every row ball is
an operator $2$-norm ball in the common finite state space.  For each
$0\le q\le p$, the producer returns:

1. the diagonal-safe local-log ball for
   $(\partial_t+\partial_u)^qK_1^{\mathrm{self}}$;
2. one signed ball for
   $(\partial_t+\partial_u)^q
   (K_2^{\mathrm{self}}+K^{\mathrm{reg}})$, formed before taking a norm;
3. one signed target-row ball for
   $J^{(q)}+(\mathscr A^{\mathrm{off}})^{(q)}$;
4. signed log-moment balls and absolute log moments for every $H_b$.

The source density, Jacobian, source normal, exterior/interior signs, regular
image, off-surface state map, and value identity are each applied once.  The
producer assembles $C_{q,a}$ and $R_{q,a}$ exactly as (ME-P4.6), then uses the
real recurrence

$$
a_{1,1}=s^{-1},
\qquad
a_{n+1,q}=s^{-1}(a_{n,q}'+a_{n,q-1})
\tag{I5.1h-3}
$$

to construct the arclength derivative certificate
$Q_{\Gamma,p}^{\mathrm{full}}$ in (ME-P4.10).  This recurrence, the
finite product covering, and interval row arithmetic are the governing
implementation.  A sampled maximum or inter-panel drift is never a gate.

For the regular-image Ewald families, every retained term is differentiated
by finite interval jet arithmetic.  For every omitted one-sided term family
$f_n$, derivative order $q$, and product box, the producer must supply

$$
\|\mathrm D^q f_n\|_2\le B_{n,q},
\qquad
\frac{B_{n+1,q}}{B_{n,q}}\le r_q<1,
\qquad n\ge n_0,
\tag{I5.1h-4}
$$

and use the explicit tail $B_{n_0,q}/(1-r_q)$.  Reciprocal, nonzero-image,
local-Ewald, and Taylor families have separate first-omitted indices and
ratio gates.  A two-sided family applies (I5.1h-4) separately on both sides.
Every polynomial weight introduced by six or eight chain derivatives is
included in $B_{n,q}$ before the ratio is tested.  Failure of one ratio or
finite-term enclosure fails the complete p6/p8 branch.

The first current blocker is precisely this order-six regular-image row-ball
producer.  The existing Ewald certificate proves coordinate derivatives only
through order two.  Therefore I5.1h cannot label the full-jump p6 instance
`GO` until (I5.1h-4) is instantiated for every Ewald family.  This is a
finite algorithmic obligation, not an unknown exact-solution norm.

## Retained coefficient balls

For $|\ell|<L$, form the sampled physical row (I5.1h-1) first and apply one
target DFT.  Persist

$$
\widetilde{\mathscr A}_{\ell,N}
=\mathcal F_{\ell,N}
(\widetilde{\mathscr A}^{\mathrm{self}}
+\widetilde{\mathscr A}^{\mathrm{reg}}
+\widetilde{\mathscr A}^{\mathrm{off}}),
\tag{I5.1h-5}
$$

and the complete radius

$$
\epsilon_\ell=\epsilon_\ell^{\mathrm{src}}
+\epsilon_\ell^{\mathrm{tgt}}
+\epsilon_\ell^{\mathrm{series}}
+\epsilon_\ell^{\mathrm{Ewald}}
+\epsilon_\ell^{\mathrm{off}}.
\tag{I5.1h-6}
$$

The five terms are the disjoint evaluation-graph edges in (ME-P4.14): exact
source Kress integral to retained source rule, exact local series to retained
series, exact regular Ewald action to retained Ewald rule, exact off-surface
action to retained off-surface rule, and exact target Fourier integral to one
DFT.  The corresponding six intermediate rows telescope from the exact
physical coefficient to (I5.1h-5), so each replacement is owned once.
Centers are added with physical signs before their norm; radii are added by
the triangle inequality.  Series/Ewald tails used to enclose the magnitude
of an exact derivative are certificate constants and are not a second
coefficient-error owner.

On a validated constant-arclength target grid, the target DFT radius may use
(ME-P4.15)--(ME-P4.16).  A general chart must instead provide a certified
phase-weighted parameter-rule remainder or a validated arclength
reparametrization.  In all cases

$$
N>2\max\{L,M_\eta\}
\tag{I5.1h-7}
$$

is strict and the single Nyquist representative follows the existing Kress
convention.

## Owner and telescope ledger

| Set or operation | Sole owner |
|---|---|
| retained $|\ell|<L$ | one full signed center (I5.1h-5) and radius (I5.1h-6) |
| material high $|\ell|\ge L$ under complete p6/p8 | one full signed derivative tail (I5.1h-2); old component tails are removed |
| local source quadrature | `src` edge in (I5.1h-6) |
| local finite kernel truncation | `series` edge in (I5.1h-6) |
| regular analytic finite/tail quadrature | `Ewald` edge in (I5.1h-6); primitive evaluation remains in $\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$ |
| off-surface analytic source/node evaluation | `off` edge in (I5.1h-6); primitive evaluation remains unresolved |
| target Fourier rule | `tgt` edge applied to the complete physical action |
| retained and high cell sequences | existing block-power state envelope, once after the physical row |
| artificial-wall values and high modes | existing paired-wall theorem; never included in (I5.1h-2) |
| material and wall normal residuals | unchanged I5.1g owners |

## Fail-safe two-band signed recapture

If the p6 Ewald gate fails, v7 uses the established retained-row theorem and
existing p4 tails rather than returning design only.  Freeze

$$
L_0=256,
\qquad L_1\in\{512,1024\},
\qquad N\in\{4096,8192\},
\tag{I5.1h-8}
$$

with candidates filtered by (I5.1h-7).  The three sets are

$$
|\ell|<L_0,
\qquad L_0\le|\ell|<L_1,
\qquad |\ell|\ge L_1.
\tag{I5.1h-9}
$$

They are disjoint and exhaustive.  The middle band uses the same complete
signed physical centers and all coefficient radii (I5.1h-5)--(I5.1h-6),
weighted mode by mode by $\overline w_{\Lambda,\ell}$.  The far band uses

$$
T_{\mathrm{far}}(L_1)
=T_4^{\mathrm{self}}(L_1)
+T^{\mathrm{reg}}(L_1)+T^{\mathrm{off}}(L_1),
\tag{I5.1h-10}
$$

where every operand is the already proved component bound at the new cutoff.
This is explicitly not a full-jump p6 result.  The historical component tails
starting at $L_0$ are replaced by the computed middle band plus
(I5.1h-10), not added again.

Before evaluating a band center, compute the propagated radius-only quantity

$$
H_{\mathrm{band}}^2(L_1,N)
=S_{\mathrm{state}}\left[
\sum_{L_0\le|\ell|<L_1}
\overline w_{\Lambda,\ell}\epsilon_\ell(N)^2
+T_{\mathrm{far}}(L_1)^2\right].
\tag{I5.1h-11}
$$

Use the same preregistered budgets $\tau_{\mathrm{high}}$ and
$\tau_{\mathrm{ret}}$ in (I5.1h-12).  First select the first analytically
admissible $L_1\in\{512,1024\}$ for which

$$
\sqrt{S_{\mathrm{state}}}\,T_{\mathrm{far}}(L_1)
<\tau_{\mathrm{high}}.
$$

Only after $L_1$ is frozen, select the first analytically admissible strict
$N\in\{4096,8192\}$ for which

$$
\left[S_{\mathrm{state}}
\sum_{L_0\le|\ell|<L_1}\overline w_{\Lambda,\ell}
\epsilon_\ell(N)^2\right]^{1/2}<\tau_{\mathrm{ret}}.
$$

Equation (I5.1h-11) is the orthogonal accounting ledger, not a third combined
threshold.  Only after both stages freeze their indices is the middle-band
signed center evaluated, once.  If a stage has analytic candidates but none
meets its performance budget, freeze its largest analytic candidate, report
the failed tightness gate, and force the next upgrade.  If either stage has
no analytic candidate, stop with no majorant.  No center drift enters either
selector.

## Final two-band assembly and complete-branch schedule

For the finally selected two-band pair, define

$$
F_{\mathrm{band}}^2
=S_{\mathrm{state}}
\sum_{L_0\le|\ell|<L_1}\overline w_{\Lambda,\ell}
(\|\widetilde{\mathscr A}_{\ell,N}\|_2+\epsilon_\ell)^2.
\tag{I5.1h-11a}
$$

The material two-band high contribution is the orthogonal Fourier square
sum

$$
H_{\Gamma,\mathrm{high}}^2
\le F_{\mathrm{band}}^2
+S_{\mathrm{state}}T_{\mathrm{far}}(L_1)^2.
\tag{I5.1h-11b}
$$

Within $T_{\mathrm{far}}$, the three nonorthogonal component norms in
(I5.1h-10) are added once and the result is squared once.  In the final
lifting assembly, add to (I5.1h-11b) in squares only the core
$|\ell|<L_0$ finite-cell and block-power terms and the unchanged
artificial-wall finite/high/propagation terms, exactly as (ME-P4.21).

The complete p6 branch uses target/relative panel pairs

$$
(n_t,n_h)\in\{(32,64),(64,128),(128,256),(256,512)\},
$$

cutoffs $L\in\{256,512,1024\}$, and the same $N\in\{4096,8192\}$ filtered
by (I5.1h-7).  The predeclared high and retained-radius performance budgets
are each

$$
\tau_{\mathrm{high}}=\tau_{\mathrm{ret}}
=\frac14(5.5685129828202118\times10^{-4}).
\tag{I5.1h-12}
$$

Select the first complete p6 analytic candidate with
$\sqrt{S_{\mathrm{state}}}T_{\Gamma,6}^{\mathrm{full}}
<\tau_{\mathrm{high}}$.
If p6 is analytic but misses this budget and the p8 geometry is available,
evaluate p8 and use the smaller valid complete tail.  After $L$ is frozen,
select $N$ only from the propagated retained radius
$H_{\mathrm{ret}}(N)<\tau_{\mathrm{ret}}$.  Centers are evaluated once after
selection and never feed back into either selector.

## Finite input and fail-closed gates

The v7 input is create once and records:

- the frozen density coefficients and their derivatives through order six,
  and through order eight only for an active p8 branch;
- the common frozen state-map basis used by every signed row;
- a $C^8$ chart certificate for p6, or $C^{10}$ for p8, including speed,
  chord--arc, divided differences, normals, and all interval jets;
- signed and absolute logarithmic moments for every source panel;
- all retained Ewald terms and the separate ratio-tail records
  (I5.1h-4), with first omitted indices;
- finite off-surface derivative row balls with branch, non-Wood, and
  positive-distance gates;
- the exact harmonic lifting weights and one block-power certificate per
  half guide;
- the active branch (`full-p6`, `full-p8`, or `two-band-p4-fallback`) and the
  complete index/owner ledger.

The evaluator fails closed on a missing derivative, product-box coverage,
diagonal cancellation, Ewald ratio, branch, finite/nonnegative radius,
state-map compatibility, strict index, or owner gate.  A wide but finite
analytic result is reported.  A sampled maximum, convergence plateau,
Richardson estimate, empirical safety factor, or center drift never enters a
bound or stopping rule.

The theorem-level p6/p8 implication is `ESTABLISHED`.  The current full-p6
instance is `BLOCKED` until the order-six Ewald derivative certificate
passes.  The two-band fallback is `ESTABLISHED` from existing
retained coefficient balls and p4 component tails and is the minimum runnable
v7 route if that blocker remains.

Finite special-function and floating-point evaluation errors remain
$\Delta_{\mathrm{sf}}=\mathrm{UNRESOLVED}$ and
$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$.  Hence every v7 number is a
conditional ideal diagnostic until those two layers are enclosed.

## v7 implementation mapping: two-band p4 fallback

The runnable fallback is implemented by
`test/i5/residual-numerator-v7/`.  It rebuilds its self-contained input
from the explicit frozen artifact and curve contract; no v1--v6 output is a
runtime dependency.  The code implements only (I5.1h-8)--(I5.1h-12) and
(ME-P4.17)--(ME-P4.22); the full-p6 branch remains fail-closed.

The builder fixes `configuration.core_mode_cutoff=256`, tests
`configuration.L1_schedule=[512,1024]` with no center evaluation, and
freezes the first analytic candidate satisfying
`sqrt(state_energy)*far_norm < two_band_high_allocation`.  For that fixed
$L_1$, it tests only strict `N_schedule=[4096,8192]` and freezes the first
candidate satisfying the weighted middle-band radius allocation.  Both
selectors fall back to the last analytic candidate if the performance budget
fails, while preserving a false tightness gate; no sampled center enters
selection.

`LOCAL_value_radius_edges` is the direct code image of (I5.1h-6):

| code field | exact edge |
|---|---|
| `source` | local source Kress radius |
| `target` | one sum of local, regular, and off-surface target radii |
| `series` | local retained-series omission |
| `Ewald` | regular source radius and M-R/M-I/M-T/M-L |
| `off_analytic` | zero only under `source_quadrature_used=false` |

After $L_1,N$ freeze, one signed physical center is built.  The material
lifting output stores core finite and core cell squares, the middle-band
$S_{\mathrm{state}}$ square, and the far
$S_{\mathrm{state}}T_{\mathrm{far}}(L_1)^2$ square separately.  The band
has no cell owner, and no old value tail beginning at $L_0$ enters the total.
Material normal and paired-wall formulas are unchanged.  The runner has a
30-minute/2-GiB plan and 45-minute/3-GiB hard watchdog.

See [[phase3-analysis/residual-bound/s-lift-tail|minimum-energy lifting
theory]] for the governing proof and
[[implementation/i5/design-5-1g|I5.1g]] for inherited normal/wall mappings.

## v7 canonical run-01 record

The reviewed nine-argument runner rebuilt a self-contained input from
`test/i3/e-cap/input/fbie-a1-certificate.mat` and
`test/i5/wall-curve-a1/input/circle-contract-a1.mat`.  It read no
historical experiment output and performed zero eigenpair, density, QZ, and
propagation solves.  There was no canonical operational failure or repair
run.

The two-stage rule selected $L_1=512$ from candidate far contributions
$[6.8805380479899163\mathbin{\cdot}10^{-5},
8.5549626823059993\mathbin{\cdot}10^{-6}]$.  With $L_1$ fixed, it selected
$N=8192$ from candidate band-radius contributions
$[1.6676740323102459\mathbin{\cdot}10^{-4},
1.1371908078258733\mathbin{\cdot}10^{-5}]$.  Both analytic-candidate
vectors were all true; the first $N$ failed only the performance allocation.
No candidate center was evaluated.

The final conditional ideal values were

$$
(B_{\Gamma_\pm},B_\Upsilon,B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732052703226799\times10^{-10},
9.5955972563422753\times10^{-6},
6.9738911755431085\times10^{-5},
7.9334696332300397\times10^{-5}).
$$

The material lifting square consists of core finite
$1.3169091615375451\times10^{-14}$, core cell
$2.7664543679042261\times10^{-28}$, signed band
$1.2932226075649907\times10^{-10}$, and far p4
$4.7341803829836888\times10^{-9}$.  No old value tail at $L_0$ and no band
cell term are present.  The material normal finite/cell/high squares are
$3.2141087539620648\times10^{-17}$,
$6.7517066305076514\times10^{-31}$, and
$9.2075454564835880\times10^{-11}$.  The unchanged wall normal and lifting
total squares are $3.5088979847646642\times10^{-20}$ and
$1.0921538896743705\times10^{-29}$.

All 49 required-true and four required-false evaluator gates passed, as did
the zero-solve, selection, and finite/nonnegative checks.  The four false
fields are precisely the forbidden empirical methods.  The route-upgrade
gate is false; full p6 remains blocked.  Finite special-function and
floating-point errors remain unresolved, so this record does not establish a
certified or total-reliable bound.

The builder/evaluator elapsed times were 165.06537108333333 s and
0.12176208333333334 s.  Complete wall time was 181.78 s with
1,508,376,576 bytes maximum RSS; the watchdog observed 183 s and
1,567,968 KiB.  The run therefore met the 30-minute/2-GiB plan and the
45-minute/3-GiB hard limits.  The create-once files are under
`test/i5/residual-numerator-v7/output/attempt-1/`.

## v7 attempt-2 tightened allocation record

Attempt 2 changed no theorem or assembly formula.  It fixed
$\tau_{\mathrm{high}}=\tau_{\mathrm{ret}}
=6.9738911755431085\times10^{-5}/4
=1.7434727938857771\times10^{-5}$, retained the preregistered
$L_1\in\{512,1024\}$ and $N\in\{4096,8192\}$ schedules, and added exact
attempt/provenance/selector-owner gates.  The post-selection
`far_lifting_square_fraction` is the far p4 lifting square divided by the
complete lifting-bound square; it is a route diagnostic and never feeds back
into either selector.

The canonical command was the same reviewed nine-argument runner recorded
above, with all five generated targets replaced by their
`output/attempt-2/*-run-01` paths.  It rebuilt a self-contained input from the
same explicit I3 artifact and curve contract and read no historical output.

The analytic far candidates were
$[6.8805380479899163\times10^{-5},8.5549626823059993\times10^{-6}]$,
so the far-only rule selected the asserted $L_1=1024$.  The strict radius-only
$N$ candidates were
$[3.7303224274521529\times10^{-4},2.5435393003395238\times10^{-5}]$.
Neither met the tightened allocation, so the theorem-preserving fallback
froze $N=8192$, reported the conditional majorant, and set the upgrade route.
No candidate center was evaluated.

The resulting conditional ideal tuple was

$$
(B_{\Gamma_\pm},B_\Upsilon,B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732052703226799\times10^{-10},
5.9744219320296460\times10^{-7},
2.6836233016607903\times10^{-5},
2.7433862530337900\times10^{-5}).
$$

Material lifting squares were core finite
$1.3169091615375451\times10^{-14}$, core cell
$2.7664543679042261\times10^{-28}$, band
$6.4698284693441235\times10^{-10}$, and far
$7.3187386495648263\times10^{-11}$.  Material normal finite/cell/high
squares were $3.4120166769828190\times10^{-17}$,
$7.1674559499430504\times10^{-31}$, and
$3.5690305405239873\times10^{-13}$.  Wall normal and lifting total squares
remained $3.5088979847646642\times10^{-20}$ and
$1.0921538896743705\times10^{-29}$.

All 54 required-true and four required-false gates passed, together with the
selection, provenance, finite/nonnegative, and zero-solve audits.  The
far-square fraction was $0.10162326185161630$; hence it did not trigger the
$0.5$ stage gate.  `next_method_required=true` only because the retained
radius allocation failed.  The ordinary wall-lifting high square underflowed
to zero and is not an analytic zero.

The builder/evaluator times were 165.93983816666668 s and
0.18981666666666666 s.  Total wall time was 183.19 s, maximum RSS was
1,958,985,728 bytes, and the watchdog recorded 185 s and 1,740,992 KiB.
This met the 30-minute/2-GiB plan and 45-minute/3-GiB hard limits.  The status
remains `CONDITIONAL_TWO_BAND_P4_MAJORANT_SF_FP_UNRESOLVED`; special-function
and floating-point errors remain unresolved, so no certified or
total-reliable claim follows.

For comparison, $(B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})$ was
$(3.3621248621896728\times10^{-2},3.3776900505194128\times10^{-2})$ in v6
attempt 1, $(5.5685129828202118\times10^{-4},7.1156194372467858\times10^{-4})$
in v6 attempt 2, and
$(6.9738911755431085\times10^{-5},7.9334696332300397\times10^{-5})$ in v7
attempt 1.

## v7 attempt-3 streamed-run record

Attempt 3 preserved the attempt-2 theorem, owners, allocations and
$L_1=1024$, changed the strict radius-only schedule to
$N\in\{8192,16384\}$, and used block size 16.  The regular target DFT and
both off-surface source/target transforms were streamed.  These are algebraic
reorderings only; their ordinary summation changes remain owned by unresolved
$\Delta_{\mathrm{fp}}$.

The far-only contributions were
$[6.8805380479899163\times10^{-5},8.5549626823059993\times10^{-6}]$ and the
radius-only contributions were
$[2.5435393003395238\times10^{-5},1.9609816903680077\times10^{-6}]$.
All candidate gates and both allocations passed, so the selected tuple was
$(L_0,L_1,N)=(256,1024,16384)$ and `route_upgrade_required=false`.

The conditional ideal result was

$$
(B_{\Gamma_\pm},B_\Upsilon,B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732040521480924\times10^{-10},
5.9741385647183627\times10^{-7},
8.7769248875529515\times10^{-6},
9.3745260644300025\times10^{-6}).
$$

Material lifting squares were core finite
$7.8280676297689059\times10^{-17}$, core cell
$1.6444125623459840\times10^{-30}$, band
$3.8469457054218476\times10^{-12}$, and far
$7.3187386495648263\times10^{-11}$.  Material normal finite/cell/high
squares were $2.6185215306824859\times10^{-19}$,
$5.4986154468560517\times10^{-33}$, and
$3.5690305405239873\times10^{-13}$.  Wall normal and lifting total squares
were $3.5088934209840330\times10^{-20}$ and
$5.9767862107677079\times10^{-30}$; the stored wall-lifting high square is an
ordinary underflowed zero, not an analytic zero.

All 55 required-true and four required-false gates passed, together with the
streaming, provenance, selection, finite/nonnegative, and zero-solve audits.
The far lifting-square fraction was $0.95006096675446483$, so
`next_method_required=true` through the independent post-selection
far-dominance gate.  It did not alter the selected cutoff or bound.

The builder/evaluator took 601.30727670833335 s and
0.19272141666666667 s.  Total wall time was 618.57 s with maximum RSS
1,503,281,152 bytes; the watchdog recorded 619 s and 1,501,632 KiB.  Compared
with attempt 2, streaming reduced maximum RSS by 455,704,576 bytes while $N$
doubled.  The run remained within the 30-minute/2.5-GiB plan and
45-minute/3-GiB hard limits.  Its create-once files are under
`test/i5/residual-numerator-v7/output/attempt-3/`.

The persisted status is still
`CONDITIONAL_TWO_BAND_P4_MAJORANT_SF_FP_UNRESOLVED`; no reliable or certified
claim follows.  For comparison, attempt 3 reduced
$(B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})$ to
$(8.7769248875529515\times10^{-6},9.3745260644300025\times10^{-6})$ from
$(2.6836233016607903\times10^{-5},2.7433862530337900\times10^{-5})$ in v7
attempt 2 and the larger v7/v6 values recorded above.
