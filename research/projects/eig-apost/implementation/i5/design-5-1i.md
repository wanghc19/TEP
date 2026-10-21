# I5.1i constant-arclength FFT implementation design

## Scope

This is an implementation-only refactor of the accepted I5.1h
`two-band-p4-fallback`.  It changes neither the frozen field, the physical
signs, the five analytic-radius owners, the $L_1$/$N$ selectors, nor the
finite/cell/far energy assembly.  It uses the constant-arclength certificate
of the current geometry adapter to replace six value/normal target-phase action
transforms by three paired helper FFTs, and it factors the target-independent
Kress series tail before any target loop.  The governing mathematics remains
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail|s-lift-tail]]
and [[research/projects/eig-apost/implementation/i5/design-5-1h|I5.1h]].

The current circle is only an instance adapter.  The implementation interface
requires a certified constant speed, uniform arclength nodes, and an arclength
origin; it does not use a Fourier--Bessel diagonalization.

The sections through **Resource and verification plan** record the historical
attempt-4 concatenated/three-paired-transform contract.  The attempt-5
addendum below overrides only that transform scheduling and its resource plan.

## Exact constant-arclength transform

Let

$$
s_j=s_0+jP/N,\qquad j=0,\ldots,N-1,
$$

and let $F_j$ be any already assembled value or normal target sample, including
all source quadrature and the source Jacobian.  For every retained integer
$|\ell|<N/2$,

$$
\frac{\sqrt P}{N}\sum_{j=0}^{N-1}
e^{-2\pi\mathrm i\ell j/N}F_j
e^{-2\pi\mathrm i\ell s_0/P}
$$

is exactly the old target DFT formula in exact arithmetic.  Hence each helper
concatenates its value and normal samples, calls `fft(...,[],1)` once, selects
row `1+mod(ell,N)`, multiplies by $\sqrt P/N$, and finally applies the scalar
$s_0$ phase.  A nonzero $s_0$ is therefore supported.  The ordinary change in
summation order remains inside `delta_fp=UNRESOLVED`.

The builder must fail closed unless the adapter supplies all of:

- `constant_speed_certificate_pass=true`;
- `constant_arclength_fft_pass=true`;
- $s_j=s_0+jP/N$ for all stored nodes;
- $|\ell|<N/2$ for all retained rows.

The six action transforms are represented by exactly three paired helper FFT
calls and zero target-phase matrix exponential calls.  Local pairwise Kress
blocks, regular-image pairwise blocks, and off-surface source-mode blocks remain
size 16; only their final target transform changes.

## Exact circulant Kress-series factorization

For one target, the Kress remainder already has the form

$$
E_i^\chi
\le
\sum_j |r_{i-j}|\,\delta_{1,j}^\chi
+\frac{2\pi}{N}\sum_j\delta_{2,j}^\chi.
$$

The offset map `mod((i-1)-(j-1),N)+1` is a permutation of all $N$ residues.
The analytic factor tails $\delta_{1,j}^\chi,\delta_{2,j}^\chi$ are independent
of the target index.  Summing the normalized target-row bound therefore gives
the exact scalar factorization

$$
\epsilon_{\mathrm{series}}^\chi
=\frac{\sqrt P}{N}
\left[
\left(\sum_{r=0}^{N-1}|r_r|\right)
\left(\sum_{j=0}^{N-1}\delta_{1,j}^\chi\right)
+2\pi\sum_{j=0}^{N-1}\delta_{2,j}^\chi
\right].
$$

This formula is used independently for `val` and `nor`.  The code fails closed
unless the residue list is complete and the factor-tail scalars are real,
finite, nonnegative, and target independent.  The scalar is reused for every
retained row.  No series-tail matrix-vector product remains in the target
blocks, and no radius owner changes.

## Selector and ownership invariants

Attempt 4 retains:

$$
L_1\in\{512,1024\},\qquad N\in\{8192,16384\},
\qquad N>2\max\{L_1,M_\eta\}.
$$

The far-only selector still chooses $L_1$ before any centre evaluation.  With
$L_1$ fixed, the middle-band source/target/series radius alone selects $N$.
Every candidate recomputes its analytic radius and evaluates no centre.  One
physical signed centre is evaluated only after both selectors freeze.  The
expected frozen pair is $(L_1,N)=(1024,16384)$.

The material five-edge map, physical signs, identity ownership, core/band/far
partition, wall terms, block-power tails, and minimum-energy weights are
unchanged from I5.1h attempt 3.  The attempted old/new difference against the
frozen attempt-3 value
$9.3745260644300025\times10^{-6}$ is a diagnostic with tolerance $10^{-12}$;
it enters neither selection nor reliability.

## Interfaces and fail-closed gates

The portable interfaces remain:

```matlab
experiment_input = build_residual_numerator_input_v7( ...
  artifact_path, curve_contract_path, input_path)
result = residual_numerator_v7(input_path, output_path)
```

`artifact_path` and `curve_contract_path` are explicit frozen inputs.  No
historical experiment output, Markdown, Git state, or repository layout is a
runtime authority.  Attempt-4 targets are create-once files under
`output/attempt-4/`.

New required gates are:

- `gates.constant_arclength_fft`;
- `gates.exact_circulant_series_factorization`;
- `gates.three_batched_target_ffts`.

The existing no-sampling/no-drift gates remain mandatory.  Special-function
and ordinary floating-point errors remain `UNRESOLVED`; the result is only a
conditional ideal majorant and cannot be called certified.

## Resource and verification plan

The retained transforms now hold a single concatenated value/normal sample
array per helper and one FFT result, while pairwise blocks remain 16 rows.
The planned complete run is at most 20 minutes and 2.25 GiB; the runner enforces
2695 seconds and 3 GiB.  The exact launch is deferred until an independent
pre-run review returns GO.  Static acceptance requires `git diff --check`, a
clean shell syntax check of the new runner, a banned target-phase scan, and
MATLAB `checkcode` during the later authorized run.

## Attempt-5 sequential action transforms

Attempt 5 leaves every formula, selector, radius, and owner above unchanged,
but avoids simultaneously storing concatenated value/normal FFT workspaces.
Each of the local, regular, and off-surface helpers performs the value FFT,
extracts all retained rows, clears its value transform, and then performs the
normal FFT.  Thus the final centre uses six action FFTs: one value and one
normal call in each of three helpers.  Centre-free preselection still reports
zero FFT and zero target-phase calls for every candidate.

The local transform retains its scale $\sqrt P/N$.  Regular and off-surface
retain the attempt-3 finite graph: target samples are multiplied once by stored
`speed_nodes`, transformed, and scaled by $2\pi/(N\sqrt P)$.  The scalar $s_0$
phase is applied after row selection.  Floating-point effects remain inside
`delta_fp=UNRESOLVED`.

The resource ledger stores 872,415,232 simultaneous pair-work elements and
536,870,912 sequential elements.  Planned resources are 20 minutes and 2.0
GiB, with the same 2695-second/3-GiB hard limits.  A one-sided diagnostic
$M_5\le M_3+10^{-12}$ is stored as `value_nonincrease_gate`; the absolute
difference is also reported.  Neither diagnostic enters selection or
reliability.  The active `pairwork_reduction` gate proves only the strict
reduction in these two element counts; RSS is a post-run measurement and is
not established by that gate.

## Attempts 4--7 outcome

Attempts 4--6 are exact constant-arclength FFT/storage reorderings.  They
change no selector, radius, sign, identity, or tail owner.  Each selected
$(L_0,L_1,N)=(256,1024,16384)$ and agreed up to the unresolved floating-point
reordering term.

Attempt 6 run 02 is the last completed instance.  All 64 required-true and
four forbidden-false checks passed, with

$$
(B_{\Gamma_\pm},B_\Upsilon,B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732040521480924\times10^{-10},
5.974138564715684\times10^{-7},
8.7768399607595434\times10^{-6},
9.3744411376363267\times10^{-6}).
$$

Its 567.47 s wall time was 8.26 percent below attempt 3, but its
1,579,646,976-byte maximum RSS was 5.08 percent above the
1,503,281,152-byte baseline.  Hence the exact pair-work reduction
872,415,232 to 536,870,912 did not meet the requested cost gate.

Attempt 7 used target/source blocks of four and FFT column blocks of 32.
Column separability gives 13 calls per helper for the current 194-state
instance.  Run 01 failed on a centre-free `state_count` scope error.  Run 02
persisted `PRE_RUN_CERTIFICATE_STOP`: numeric FFT-ledger fields had been
included in an all-Boolean layout reduction.  The source now preserves the
prior layout pass and conjoins only `target_block_size_4`, but this repair was
not rerun.  Attempt 7 therefore supplies no accepted numerator or cost result.

All attempts retain `delta_sf=UNRESOLVED` and `delta_fp=UNRESOLVED`.
