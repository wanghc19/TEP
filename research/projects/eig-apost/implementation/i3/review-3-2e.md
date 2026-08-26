# I3.2 e-cap-v4 review

## Bounded design review

The v4 review is limited to the two requested scientific changes: scalar
$B_{X,\infty}+C_XN^{-p_X}$ fits and the shifted $H^{1/2}$ trace right inverse.
It does not reopen the frozen candidate, QZ/BIE solve, propagation matrices,
density representation, MFS parameters, field anchor, or claim flags.

Researcher initially returned `REVISE` because the circle annulus side,
boundary conditions, and energy measure were not explicit. The design now
freezes an exterior background collar, $h_\ell(R)=1$,
$h_\ell(R+\delta_\Gamma)=0$, and
$E_{\Gamma,\ell}=-h_\ell'(R)$ with the required $r/R$ Jacobian. It also fixes
the $L^2(\Gamma,\mathrm ds)$-orthonormal Fourier coefficients, applies the wall
constant separately to both wall defects, defines the empirical field
candidate at zero safely, and gives the two total scalar additions unique
roundoff ownership. Researcher then returned `RESEARCHER AGREED`.

Engineer initially returned `REVISE` pending an explicit scalar-versus-factor
fit choice and the exact coupled levels. The design now fits the four scalar
sequences required by the user, uses
$N_\Gamma=(1024,1280,1536,2048)$ and $N_W=2N_\Gamma$, and specifies five
files, streamed panel actions, compact Grams, the deterministic one-dimensional
fit, and fail-open output. Engineer then returned `ENGINEER AGREED`.

The estimated workload is approximately $2.31\times10^8$ streamed pair
queries. Based on the v3 timings, the fixed MFS table plus four coupled actions
should take approximately $470$--$570$ seconds, with a conservative estimate
below $650$ seconds. The compact-memory estimate is $0.75$--$1.0$ GiB. Direct
dense square Kress matrices are prohibited; with streamed panels, no current
resource blocker is identified.

**R--E verdict:** `AGREED`.

Skeptic checked the outer-annulus normalization, the separate wall-side
constant, all four scalar fit/LOO objects, unique GQP/full-$P$/roundoff
ownership, the once-only denominator correction, and the five-file streamed
resource contract. No decisive design blocker was found.

**Skeptic DESIGN verdict:** `SKEPTIC DESIGN PASS`.

Implementation is now authorized. A separate bounded spec-to-code review is
still required before the formal attempt.

## Bounded implementation review

The implementation contains exactly five MATLAB files. Engineer implemented
the embedded single-MFS coupled boundary module: four logical coupled actions,
eight physical family actions, same-action value/normal defects, streamed
Kress self quadrature, positive-distance cross quadrature, frozen normal
dual-trace weights, and finest unique GQP-only pieces. Engineer returned
`ENGINEER IMPLEMENTATION READY` after MATLAB `checkcode` reported zero
messages.

Researcher implemented the shifted trace module: the two wall weights, the
exterior-annulus $8192$-step vectorized ODE, one finest-set circle constant,
the four singleton blocks, and the unique value-GQP factors. A non-formal
actual-certificate/manufactured-map smoke test returned `COMPLETE`, with
$C_{E,W}\approx3.6311089513$, $C_{E,\Gamma}\approx3.8713871083$, and a
single-mode oracle defect of approximately $2.073\times10^{-15}$. This smoke
did not create a formal attempt artifact.

The thin entry, full-$P$/fit/cap module, and output module implement the
frozen scalar fit, once-only error ownership, once-corrected field candidate,
fail-open component publication, and all-false claim flags. Across all five
files MATLAB `checkcode` reports zero messages; `git diff --check` passes.
Static searches find no old experiment helper, image-sum evaluator,
Rayleigh-field evaluator, `interpft`, eigendecomposition, or pseudoinverse
call. The formal attempt has not been run.

Skeptic's first bounded code pass found one cap-ownership issue: the direct
change of the summed majorant was used for the full-$P$ row, so cancellation
could make it smaller than the frozen componentwise rule. The implementation
now retains that direct change as a diagnostic only and uses
$\epsilon_{W,P}+\epsilon_{\Gamma,P}+\epsilon_{V,P}$ as the cap-bearing
majorant full-$P$ row. The repaired file again has zero `checkcode` messages,
and `git diff --check` remains clean.

**Skeptic spec-to-code verdict:** `SKEPTIC SPEC-TO-CODE PASS`.

## ecap-v4-a1 result and retry ledger

The formal MATLAB command used the frozen certificate and the registered
entry. Retry ordinal 1 completed in $473.733511291667$ seconds. Read-only
artifact inspection then found two reporting omissions: the saved fit records
were not expanded in `report.md`, and the shifted-trace table showed operator
map norms rather than the requested full-$P$-contracted wall/circle defect
norms. The fit-record change was output-only. The component norms were added
as diagnostics by splitting the already assembled total shifted factor along
its known circle/wall row boundary and applying the unchanged complete-$P$
endpoint and frozen tail formula to each block. Total $L$, every majorant and
cap row, and the field formula continued to use the original total factor.
Skeptic returned `SKEPTIC SPEC-TO-CODE PASS` for this final mapping.

Retry ordinal 2 overwrote only the authorized `ecap-v4-a1` directory and is
the final readable artifact. It completed in $482.324267$ seconds with no true
blocker. The coupled sequences are:

| $N_\Gamma$ | $N_W$ | $B_W$ | $B_\Gamma$ | $L$ | $B_{V,H^{1/2}}$ | $\mathcal M$ |
|---:|---:|---:|---:|---:|---:|---:|
| 1024 | 2048 | 1.8723931672626784e-10 | 4.2948635997945844e-13 | 7.8613563163392003e-12 | 1.5722712632678401e-11 | 2.0339151571892571e-10 |
| 1280 | 2560 | 1.8723233569637603e-10 | 4.2773643511271022e-13 | 9.1182842935347239e-12 | 1.8236568587069448e-11 | 2.0589664071855821e-10 |
| 1536 | 3072 | 1.8724083898284372e-10 | 4.2718541508641197e-13 | 1.0287506098604093e-11 | 2.0575012197208186e-11 | 2.0824303659513832e-10 |
| 2048 | 4096 | 1.8724053381984950e-10 | 4.2895211946436049e-13 | 1.2705936467740524e-11 | 2.5411872935481048e-11 | 2.1308135887479491e-10 |

The combined wall shifted norms are
$[5.0061556346366400,5.2836443435903983,4.9347426904330213,
4.9424086092294877]\times10^{-13}$, and the circle shifted norms are
$[1.9755980037050125,2.3025756538959694,2.6166985134720155,
3.2491083968583446]\times10^{-12}$. The constants are $C_A=2$,
$C_{E,W}=3.631108951273724$, and finite-mode empirical
$C_{E,\Gamma}=3.8713871082870885$. The single-mode normalization oracle
defect is $2.0733940998835803\times10^{-15}$ and passes.

The wall full four-point fit is invalid at the registered search endpoint.
All four leave-one-out fits are valid. Their $(p,B_\infty)$ pairs are
$(58.542842967962081,1.8724068649622975\times10^{-10})$,
$(64.015798592209521,1.8724068640134662\times10^{-10})$,
$(123.12094255632113,1.8723643475811280\times10^{-10})$, and
$(123.12094255632113,1.8723658733960988\times10^{-10})$. Their largest
all-level residual is $3.9365467511472493\times10^{-9}$, the leave-one-out
asymptote spread is $4.2517381169433504\times10^{-15}$, and the wall fit cap
is $3.9365508502089862\times10^{-9}$. The circle, volume, and total sequences
meet the registered absolute/GQP plateau rule; their fit caps are respectively
$1.7667043779485247\times10^{-15}$,
$9.6891603028026471\times10^{-12}$, and
$9.6898431558691979\times10^{-12}$. Consequently no $p$ or $B_\infty$ is
claimed for those plateau rows.

The empirical component cap rows $(\mathrm{fit},\mathrm{GQP},
\mathrm{roundoff},\mathrm{full}\text{-}P,\mathrm{total})$ are:

- wall: $(3.9365508502089862\mathrm e{-9},
  1.3041910582195686\mathrm e{-10},2.5482955817474362\mathrm e{-15},
  3.2079098130572105\mathrm e{-23},4.0669725043265571\mathrm e{-9})$;
- circle: $(1.7667043779485247\mathrm e{-15},
  9.0282297834564374\mathrm e{-11},4.8614336016548157\mathrm e{-18},
  7.3311527311443827\mathrm e{-21},9.0284069407707062\mathrm e{-11})$;
- value lifting: $(9.6891603028026471\mathrm e{-12},
  5.9283599959671802\mathrm e{-9},5.1937831143987052\mathrm e{-16},
  1.9555680591747299\mathrm e{-19},5.9380496758438513\mathrm e{-9})$.

The total majorant rows are fit
$9.6898431558691979\times10^{-12}$, GQP component sum
$6.1490613996237014\times10^{-9}$, roundoff
$4.7481456311795222\times10^{-14}$ including the separately reported
two-addition term $4.4408920985006262\times10^{-14}$, and componentwise
full-$P$ sum $2.0292003774674795\times10^{-19}$. Thus
$\epsilon_M^{\rm emp}=6.1587987244388017\times10^{-9}$.

The frozen ordinary anchor is $4.959111810675795$ and
$\epsilon_N^{\rm emp}=1.0320473565707022\times10^{-5}$. After exactly one
subtraction and the companion correction,
$N_{\rm comp,lower}=4.9591014901456401$. The computed
$q_{\rm emp}=2.8613177943907790\times10^{-9}$ gives the nominal interval
$[1.8327702838640185,1.8327702943522952]$, of width
$1.0488276691589249\times10^{-8}<10^{-6}$.

The compact object memory proxies are $1352.2561798095703$ MiB for the
boundary/MFS module, $307.15531539916992$ MiB for shifted lifting, and
$0.064709663391113281$ MiB for fit/cap. They are not OS RSS measurements.
The only saved warning is `BOUNDARY_RECOMBINATION_WARNING`; the finest wall
recombination diagnostic is $6.4204247093106411\times10^{-4}$, while the
finest Kress split recombination is $7.2879622370530211\times10^{-18}$.
The artifact records no unresolved row and an empty first blocker. Image-sum,
Rayleigh-field, density-resolve, cubic-lifting, and Gauss-lifting calls are
zero.

Reliability, outward-enclosure, projected-gap, existence,
independent-reference, and reliable-interval flags are all `false`. The
result is `EMPIRICAL / UNQUALIFIED`; the finite $q_{\rm emp}$ and narrow
nominal interval are not a strict upper bound, reliable or certified
enclosure, or spectral existence statement.
