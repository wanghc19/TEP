# I1.4 V5 frozen negative-closure plan

V4 remains immutably `I1_4_V4_FAIL`: every positive disk, branch, QZ,
factor, chart, graph, coarse/fine, closure, and repaired CR gate passed, as did
15 of 16 negatives.  The only failure was the physical `T_RL/T_LR` swap,
whose relative change was $1.25\times10^{-14}$ because the frozen homogeneous
missing-column cell is left/right symmetric.  That physical negative is
non-identifiable for this model and is not reclassified as a pass.

V5 is a separate, one-shot algebraic negative closure.  It imports V4 evidence
only if all of the following hold:

1. the fixed SHA-256 hashes of the V4 result, manifest, node, CR, closure,
   negative, and negative-CR artifacts match;
2. every source listed by the V4 manifest still matches its recorded hash;
3. every V4 positive row and every negative-CR row passes;
4. exactly one of the 16 ordinary negatives fails and it is
   `transmission_swap`;
5. V4 made zero locator, contour, root, and estimator calls.

V5 re-executes the existing asymmetric $K=3$ manufactured scattering fixture.
It requires:

- relative $T_{RL}/T_{LR}$ identifiability greater than $10^{-2}$;
- blockwise placement error at most $10^{-12}$ for
  $A=[-R_L\ I;T_{LR}\ 0]$ and $B=[0\ T_{RL};I\ -R_R]$;
- relative change after swapping $T_{RL},T_{LR}$ greater than $10^{-8}$;
- the live `eval_k_v2.m` source to contain the same two placement formulas,
  in addition to its already imported V4 SHA-256 lock.

There is exactly one `output/v5-a1/` run and no fallback.  A pass closes the
transmission-ordering negative only at the assembly-contract level and yields
`I1_4_V5_PASS_WITH_CONDITIONS`.  It does not make the physical swap identifiable
in this symmetric model and does not claim a root, eigenvalue, derivative,
pole-free theorem, or estimator.
