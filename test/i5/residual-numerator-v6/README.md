# I5.1g minimum-energy lifting experiment

This version instantiates the minimum-energy value-jump comparison in
`design-5-1g.md` and (ME-1)--(ME-31) of `s-lift-tail.md`.  It preserves the
v5 signed local, regular-image, off-surface, and artificial-wall normal
actions, but replaces only the value-jump lifting assembly:

$$
B_{\mathrm{lift}}^{\mathrm{ME}}
=\left(F_{\mathrm{lift},\Upsilon}^2+T_{\mathrm{lift},\Upsilon}^2
+F_{\mathrm{lift},\Gamma}^2+T_{\mathrm{lift},\Gamma}^2\right)^{1/2}.
$$

There is no historical factor two.  Material values use the two-sided
harmonic comparison weight (I5.1g-3).  Artificial-wall values use the flat
harmonic weight (I5.1g-11) after forming the physical paired jumps
(I5.1g-12)--(I5.1g-13a).  The wall-normal and material-normal modules are
unchanged.

The current circle is only a geometry-certificate adapter.  It stores the
material exterior/interior and wall neighbour/central collar data as four
separate side records.  The governing comparison and assembly use only the
perimeter, widths, curvature/Jacobian bounds, material upper bounds, and the
general signed row/radius interfaces.  No Fourier--Bessel operator
diagonalization is used.

## Portable interface

```matlab
build_residual_numerator_input_v6(artifact_path, curve_contract_path, input_path);
residual_numerator_v6(input_path, output_path);
```

Both paths to authoritative data are explicit.  The builder reads no
historical experiment input/output, Markdown, Git state, or repository
layout.  It copies the required finite data into a create-once v6 input and
performs zero eigenpair, BIE-density, QZ, and propagation-matrix solves.

The first scientific attempt uses:

```text
input/residual-numerator-v6-run-01.mat
output/attempt-1/result-run-01.mat
output/attempt-1/run-01-log.txt
output/attempt-1/resource-run-01.txt
output/attempt-1/audit-run-01.txt
```

The planned complete builder/evaluator run is at most 30 minutes and 2 GiB;
the launcher enforces hard limits of 45 minutes and 3 GiB.  It may be run
only after independent pre-run review returns `GO`.

## Governing ownership

| code object | governing object | ownership |
|---|---|---|
| `geometry.material_lift_collars.plus/minus` | (I5.1g-2) | separately stored exterior/interior collar certificates |
| `weights.minimum_energy.harmonic_weight` | (I5.1g-3) | retained material value rows and their block-power cell tail, once |
| `local.high_tail.val` | (I5.1g-9) | local omitted modes $|\ell|\ge L$ only |
| `regular/off_surface` high value tails | (I5.1g-8)--(I5.1g-10) | affine harmonic-weight geometric moments, each physical action once |
| `wall.minimum_energy.paired_*` | (I5.1g-12)--(I5.1g-14) | actual left/right traces paired before one wall weight |
| `wall.minimum_energy.high_tail_ledger` | (I5.1g-15)--(I5.1g-21) | complete paired positive-distance actions for $|m|\ge257$ |
| `configuration.minimum_energy_lifting_factor` | (I5.1g-1), (ME-5) | exactly one in the final evaluator |
| `geometry.lift_geometry_gates.material_transverse_periodic_copies_disjoint` | collar hypothesis in (ME-7) | verifies $2(R+h)\le d$ independently of the cell-height clearance |
| `gates.simultaneous_jump_list_complete` | global $J_{\rm all}$ ownership in (ME-1)--(ME-5) | combines the three-interface label audit with retained, cell-tail, and high-tail owner ledgers from both material and wall assemblies |

Retained material modes are $|\ell|<L$; local/regular/off-surface omitted
modes are $|\ell|\ge L$.  Wall retained modes are $|m|\le256$ and the
positive-distance wall tail starts at $|m|=257$.  Cell block-power tails and
high-mode tails are disjoint owners.

## Claim boundary

Every analytic quadrature, kernel-series, Ewald, Fourier, positive-distance,
and block-power remainder remains present.  Finite special-function and
ordinary arithmetic evaluation errors remain literal strings
`delta_sf=UNRESOLVED` and `delta_fp=UNRESOLVED`.  Results are therefore
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` conditional diagnostics, not certified
residual or eigenvalue enclosures.

## Canonical attempt-1 result

After the independent pre-run `GO`, run 01 used the nine explicit arguments
shown above with the artifact
`test/i3/e-cap/input/fbie-a1-certificate.mat` and the curve contract
`test/i5/wall-curve-a1/input/circle-contract-a1.mat`.  The command was:

```text
zsh test/i5/residual-numerator-v6/run_residual_numerator_v6.sh \
  /Users/whc/Documents/Work/epost \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v6 \
  /Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat \
  /Users/whc/Documents/Work/epost/test/i5/wall-curve-a1/input/circle-contract-a1.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v6/input/residual-numerator-v6-run-01.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v6/output/attempt-1/result-run-01.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v6/output/attempt-1/run-01-log.txt \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v6/output/attempt-1/resource-run-01.txt \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v6/output/attempt-1/audit-run-01.txt
```

The SHA-256 values recorded by the final read-only audit are
`bb502ed97bfda5d60bd653fcb9e75f67fe15e86e053e160750ed5a735280e1b3`
for the frozen certificate,
`1d4ecd0aa9e84fc37fb45ea7580b7e72a07afc7fd0d336faf772666e67807073`
for the curve contract,
`45f1b4900a84aa1df59215375907b43938ac362833dfce3c2d6fb434fb94c684`
for the generated v6 input, and
`f4f662f9fb43c30b9bdf9690181fcfd11d6912079fbabc6eb8fce3730ebe2825`
for the persisted result.  These hashes are an external provenance audit;
they are not an analytic error enclosure.

The analytic selection chose $L=256$ and $N=1024$.  Its high-mode and
retained-local contributions were respectively
$3.3773890072149280\mathbin{\cdot}10^{-2}$ and
$2.2275416281249936\mathbin{\cdot}10^{-2}$, both below their preallocated
$10^{-1}$ thresholds.  The conditional ideal values are

| quantity | value |
|---|---:|
| $\widehat B_{\Gamma_\pm}$ | $1.8732119857082978\mathbin{\cdot}10^{-10}$ |
| $\widehat B_\Upsilon$ | $1.5565169597620056\mathbin{\cdot}10^{-4}$ |
| $\widehat B_{\mathrm{lift}}^{\mathrm{ME}}$ | $3.3621248621896728\mathbin{\cdot}10^{-2}$ |
| $\mathcal M_{\mathrm{ideal}}$ | $3.3776900505194128\mathbin{\cdot}10^{-2}$ |

Compared with v5,
$B_{\mathrm{lift}}=0.056438633545021551$ and
$\mathcal M_{\mathrm{ideal}}=0.056448305344888337$, the new values are
$59.5713370613\%$ and $59.8368725134\%$ of their predecessors: reductions
of $40.4286629387\%$ and $40.1631274866\%$, respectively.  The improvement
comes from the proved factor-one simultaneous quotient and optimized
two-sided harmonic comparison weights, not from inter-level drift.  The
material high-mode lifting norm remains the dominant term, so this run does
not interpret the reduction as evidence that unresolved evaluation errors
are small.

The material squared decomposition is: finite normal
$2.9349845522948468\mathbin{\cdot}10^{-10}$, finite lifting
$1.3882242854553804\mathbin{\cdot}10^{-7}$, cell normal
$6.1655917067299586\mathbin{\cdot}10^{-24}$, cell lifting
$2.9162757273922883\mathbin{\cdot}10^{-21}$, high normal
$2.3933952005038075\mathbin{\cdot}10^{-8}$, and high lifting
$1.1302495364668471\mathbin{\cdot}10^{-3}$.  The wall squared bounds are
$3.5089231434012241\mathbin{\cdot}10^{-20}$ (normal) and
$3.5019484979849107\mathbin{\cdot}10^{-29}$ (lifting).

The evaluator and all fail-closed analytic gates passed; all solve counts were
zero.  The result status is
`CONDITIONAL_IDEAL_MAJORANT_COMPLETE_SF_FP_UNRESOLVED`: neither
`delta_sf` nor `delta_fp` is resolved, so the four displayed bounds remain
conditional ordinary-floating-point diagnostics.  MATLAB R2023b completed in
26.25 s.  `/usr/bin/time -l` recorded 1,141,817,344 bytes maximum RSS and the
whole-process-tree watchdog recorded 1,209,520 KiB over 27 s, within both the
planned 30-minute/2-GiB budget and the 45-minute/3-GiB hard limits.

The persisted minimum-energy coefficient has range
$[15.237473472248155,780.78182496579905]$.  Its two one-sided comparison
costs have ranges
$[30.053725504118507,1561.5512598142857]$ and
$[30.908143579508508,1561.5760402455305]$.  No single
$\vartheta_{\rm tr}$ was selected for an additional scalar
$C_{\rm lift}$ bound; the per-mode harmonic weights above are the governing
and tighter finite comparison.

The retained material lifting norm is
$3.7258881967329352\mathbin{\cdot}10^{-4}$, its material high-mode lifting
norm is $3.3619184054150500\mathbin{\cdot}10^{-2}$, and its block-power cell
lifting tail is $5.4002552971061359\mathbin{\cdot}10^{-11}$.  The wall
lifting finite, propagation-tail, high-mode-tail, and total norms are,
respectively,
$5.9177263353292294\mathbin{\cdot}10^{-15}$,
$9.8880294304120916\mathbin{\cdot}10^{-24}$, $0$, and
$5.9177263353292294\mathbin{\cdot}10^{-15}$.  The zero high-mode wall value
is the persisted floating-point evaluation of the explicit positive-distance
formula, not a claim that the mathematical tail is identically zero.

The state-weighted centre cancellation ratios are
$6.480563813935847\mathbin{\cdot}10^{-14}$ (material value),
$9.5627596500150457\mathbin{\cdot}10^{-14}$ (material normal),
$2.3168377368851614\mathbin{\cdot}10^{-16}$ (wall value), and
$3.9102064543295692\mathbin{\cdot}10^{-11}$ (wall normal).  These are
diagnostics only and do not reduce any radius.  The input structural gate,
all 33 required-true gates, all four required-false gates, the zero-solve
gate, and the final real/finite/nonnegative gate passed.  The total-reliable
gate remained false because `delta_sf` and `delta_fp` are unresolved.

An independent post-run Skeptic audit returned `PASS WITH CONDITIONS / GO`
for this conditional ideal result and `STOP` for any certified or reliable
claim.  The post-run scalar extraction did not call either builder or
evaluator.  It used `/usr/bin/time -l` with MATLAB `-batch` to load the two
explicit files above and print the stored weight, tail, cancellation, and gate
fields; it took 12.51 s with 734,986,240 bytes maximum RSS and changed no
artifact.
