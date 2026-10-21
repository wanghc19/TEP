# I5.1b real-variable residual-numerator experiment

This version instantiates (KR-15)--(KR-32) of
`s-kress-real.md` for the frozen reconstruction.  It is separate from the
historical unversioned I5 attempts and never overwrites them.

The intended sequence is:

```matlab
build_residual_numerator_input_v1( ...
  artifact_path, curve_contract_path, wall_finite_squared, ...
  wall_tail_squared, input_path, wall_provenance_label);
residual_numerator_v1(input_path, output_path);
```

The artifact, curve-contract, and output arguments are explicit paths.  The
builder constructs the circle adapter of the KR-15 certificate from the frozen
artifact, verifies the independently accepted curve contract, validates the
explicit wall finite/tail squares as finite and nonnegative, and writes a
self-contained data-only input.  The optional wall provenance label is
descriptive only and never authorizes a value.  No executable reads a
historical experiment output.  The evaluator is deliberately fail-closed.  A
sampled maximum, an inter-grid difference, or a historical ordinary result
cannot set a theorem gate.

The builder checks the predeclared $L=32,64,128,256$ schedule, freezes the
first complete-angular-tail pass (or $L=256$ for a finite failed-tolerance
report), and only then chooses the smallest even $N>2\max\{L,M_\eta\}$ for
the frozen $N_\eta=256$, $M_\eta=128$ density representation.  It may be run
only after the pre-run review is `GO`.
Generated inputs belong in `input/`; the first attempt writes only under
`output/residual-numerator-a1/`.  Operational repairs reuse that attempt.

The post-run portability repair preserved the original run-02 input and result
under filenames ending in `-run-02-historical-wall.mat`.  Those files are
evidence only.  The contract-conforming run-04 input and result use the
canonical create-once names.  Run-04 completed in 16.68 seconds at a measured
959,922,176-byte maximum resident set size.  It selected $L=256$, $N=514$ and
returned

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\widehat{\mathcal M})
=(1.8732039079101324\times10^{-10},7256.776268586179,
2296548.3364069569,2303805.1126755434).
$$

All structural gates passed, but the retained-radius and both tail allocations
failed.  The canonical status is
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY`.  The post-run Skeptic verdict is
`GO` for the contract-conforming finite majorant, not for its tightness
allocations or an outward-rounded certificate.

Every ordinary floating-point output is labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.  No eigenpair, density, QZ, or propagation
solve is permitted.
