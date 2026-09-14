# I5.1h independent review

## Verdict

The shape-general full signed-jump $p=6/8$ theorem is `PASS`, but its current
full-$p=6$ instance is `STOP/BLOCKED`: the regular-image Ewald certificate
does not yet provide the required sixth target-derivative row balls and
differentiated omitted-family ratio bounds.  The two-band $p=4$ fallback is
`PASS`.  Its streamed v7 attempt-3 implementation is `PASS`, and the frozen
conditional ideal instance is `PASS WITH CONDITIONS / GO`.

A reliable or certified numerical claim is `STOP`.  Both
$\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$ remain `UNRESOLVED`, and no
outward-rounded backend was used.  In particular, the stored zero for the
wall value high tail is ordinary floating-point underflow, not an analytic
zero.

## Theorem and ownership audit

The review checked the minimum-energy factor one, the countable product trace
map, the core/band/far partition, signs, and the five-edge coefficient-error
telescope.  For value rows the disjoint owners are:

| edge | owner |
|---|---|
| source | local Kress source radius |
| target | the sum of local, regular-image, and off-surface target radii |
| series | local retained kernel-series omission |
| Ewald | regular source radius plus M-R/M-I/M-T/M-L |
| off analytic | zero only under the stored `source_quadrature_used=false` gate |

The retained core $|\ell|<L_0$, signed band
$L_0\le |\ell|<L_1$, and far tail $|\ell|\ge L_1$ are mutually exclusive and
exhaustive.  No old value tail beginning at $L_0$ and no separate band cell
tail enters the v7 assembly.  Material normal uses its separately recorded
$|\ell|<L_1$ retained range.  Rejected candidates have no centre evaluation;
the selected physical centre is evaluated once after both cutoffs freeze.

## Pre-run revisions

The first v7 pre-run review found an incomplete local far-tail owner chain and
an inaccurate shared finite-range label.  The implementation was revised so
that local, regular, and off-surface far owners all carry the current $L_1$,
and finite normal/value owners are recorded separately as $|\ell|<L_1$ and
$|\ell|<L_0$.  A second bounded revision closed the attempt-2 provenance gate.
Both repairs changed only ledgers and fail-closed gates, not numerical
formulas.

Before attempt 3, the review checked that streaming is algebraically
equivalent to the unstreamed calculation: source and target blocks are
disjoint and exhaustive, and the physical signs, normals, density factors,
speed factor, and $2\pi/(N\sqrt P)$ target normalization are unchanged.
Floating-point summation-order changes remain owned by unresolved
$\Delta_{\mathrm{fp}}$.

## Frozen runs

| run | $(L_0,L_1,N)$ | $\widehat B_{\Gamma_\pm}$ | $\widehat B_\Upsilon$ | $\widehat B_{\mathrm{lift}}$ | $\mathcal M_{\mathrm{ideal}}$ | instance gate |
|---|---|---:|---:|---:|---:|---|
| v7 attempt 1 | $(256,512,8192)$ | $1.8732052703226799\,10^{-10}$ | $9.5955972563422753\,10^{-6}$ | $6.9738911755431085\,10^{-5}$ | $7.9334696332300397\,10^{-5}$ | all selector allocations pass |
| v7 attempt 2 | $(256,1024,8192)$ | $1.8732052703226799\,10^{-10}$ | $5.9744219320296460\,10^{-7}$ | $2.6836233016607903\,10^{-5}$ | $2.7433862530337900\,10^{-5}$ | retained-radius tightness fails; finite conditional majorant passes |
| v7 attempt 3 | $(256,1024,16384)$ | $1.8732040521480924\,10^{-10}$ | $5.9741385647183627\,10^{-7}$ | $8.7769248875529515\,10^{-6}$ | $9.3745260644300025\,10^{-6}$ | all selector allocations pass |

For attempt 3 the lifting squares are

$$
7.8280676297689059\,10^{-17}
+1.6444125623459840\,10^{-30}
+3.8469457054218476\,10^{-12}
+7.3187386495648263\,10^{-11},
$$

from core, core cell, signed band, and far $p=4$ owners.  The far term is
$95.006096675446483\%$ of the complete lifting square, so the independent
post-selection `next_method_required` gate remains true even though both
cutoff allocations pass.  This diagnostic does not feed back into the
reported bound.

Attempt 3 passed 55/55 required-true and 4/4 required-false gates, with zero
eigenpair, BIE-density, QZ, and propagation solves.  Its wall time was
618.57 s and maximum RSS was 1,503,281,152 bytes; the watchdog recorded 619 s
and 1,501,632 KiB.  It stayed below the 30-minute/2.5-GiB plan and the
45-minute/3-GiB hard limits.

## Claim boundary and next obligation

The reviewed numerical statement is only

$$
\|R\|_{\mu,*}
\le 9.3745260644300025\,10^{-6}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}.
$$

It is `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.  The shortest analytic tightness
upgrade is the already formulated full signed-jump $p=6$ route; its first
missing frozen-instance input is the complete order-six regular-image Ewald
row-ball and omitted-tail certificate.  A reliable numerical claim also
requires finite special-function and floating-point enclosures, including
the wall-tail underflow path.
