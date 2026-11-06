# Gap-edge guided-mode experiment version 1

gapedge means guided mode near a gap edge. BIE: boundary integral equation;
Arb: real ball arithmetic; RSS: resident set size; DtN: Dirichlet-to-Neumann;
PWE: plane-wave expansion; QZ: generalized Schur factorization; MFS: method
of fundamental solutions; FMM: fast multipole method; CSV: comma-separated
values; JSON: JavaScript Object Notation. P is the lead propagation matrix.

Purpose: move the empty-center example toward a common lead gap edge by
varying L0 only, with all model parameters rounded to binary64. Implement
and exercise the general p tail bound. Source code is copied from example2-v1.

Run-001 floating continuation forecast: 3–8 min, 1.3 GiB, below1 MB outputs.
Widths1.0 through1.6 in increments .1; local Newton continuation with no
reliable-result claim. Each row records spectral radius, spectral norm and
smallest contracting power. A reliable run will only be launched after its
state-depth, time, memory and whole-worktree storage forecast fits the limits.

Results: accepted L0=1.6 in accepted-L16.json; completed L0=2.0 in output/run-011; completed L0=1.9 in output/run-012. Regression run-004 passed exactly. General p1/p2 and N+10 checks passed for both completed points. Compact tables: cost-width.csv, tail-comparison.csv, stage-cost.csv, conditions.csv; study-results.json joins their source ledgers.

Run-002 floating forecast: 2–4 min, 1.0 GiB. Widths1.7–2.0; continuation starts from the preceding measured k=1.5814447639159812. Stop if the root leaves the floating common gap.

Run-003 regression forecast: 2–4 min, 0.8 GiB. Explicit first-example field/fit inputs from accepted example2-v1 run-008; recompute right material panel14 and two full enclosure assemblies. This is the permitted target-subset regression, not a new cold first-example search. General-p code is exercised in setup; p1 bounds remain unchanged.

Run-003 stopped at the matrix-identity constructor: this python-flint version has no acb_mat.eye. Replaced it by an exact integer identity; the norm gate is unchanged. Run-004 repeats the same regression, forecast 2–4 min / 0.8 GiB.

Run-004 passed: panel14 relative difference0, complete two-configuration assembly identical; 103.203 s / 0.369 GiB.
Run-005 cold L0=1.6 forecast: search450 s, field20 s, residual725 s (100 states,6 workers), audit/mass/C/assembly15 s, band145 s; total1355 s (20–24 min), peak2.5 GiB. Tail-square / finite-square target1e-2; expected right depth about75 plus10 check. Same-run exact field and fit handoffs are gzip-compressed. Target records are compressed immediately; aggregate records after their last scientific use.

Boundary-radius mapping: a junction combines fields in different local cells. Each proxy tail now uses its own local x endpoint, rather than the maximum of the two endpoints. This remains an enclosing radius; in the equal-width first example both values are identical. The running parent had already imported the old function. Run-005 was stopped before completion; a junction panel had finite V=3.00158006064e-27 but e_I=0.00237701961. Its logs and records are retained. Run-006 repeats the full cold pipeline with the corrected per-field radius.

Run-006 forecast: same100 states/6workers/tail target1e-2, search420 s, field20 s, residual700–850 s, other160 s, total22–25 min, peak2.5 GiB. The broad radius was valid but needlessly large; no check threshold or remainder rule was changed.

## General-power tail and safe direction

For p >=1, calculate the ball matrices P^l. The identity spectral norm is1;
for l>0 use ||P^l||_2 <= ||P^l||_F. With r >= ||P^p||_2 <1,
F_p = sum_{l=0}^{p-1} ||P^l||_{2,+}^2 / (1-r^2), and
T_N = B^2 F_p ||P^N c||^2. This follows by writing j=N+mp+l and summing
the geometric majorant r^(2m). No diagonalization or normality is used.
The wall envelope uses the one-step norm even if the contracting block has
p>1. Selection uses actual computed states; all tail terms are retained.
Each completed group additionally uses p=max(2,p_selected) on the same
states, records short-power norm bounds and the block factor, and checks
N+10 intervals. For p dividing10 it also verifies that the next ten actual
state norms squared plus the renewed tail fit inside the original tail.
This is a valid p>1 demonstration even when p=1 already contracts; it is
not evidence that the physical example needs p>1.

The norm-cost forecast uses r_eff=r^(1/p). Since the actual state can decay
faster than the operator-norm majorant, predicted depths are compared with
measured depths, not substituted for them. Every table distinguishes the
floating spectral norm from a ball Frobenius upper bound on that norm.

Run-006: all residuals, coverage/Gauss audit and general-p checks passed, then mass input loading failed because its args.input reader had not been switched to gzip. Run-007 forecast: explicit continuation probe, re-export20 s + mass/C5 s + band150 s, under4 min / 1.1 GiB. Check the streaming gzip export against run-006 byte for byte, then check downstream stages. It is not a cold-start benchmark. Failed run-005 data were byte-identical to run-006 and retained by relative same-experiment links after comparison; all failure logs remain.

Run-007 passed export byte equality, mass, two-configuration/rational assembly,944 full-phase tests and the failing control. 171.526 s /1.057 GiB. Streaming gzip field export and compressed residual summaries/target records avoid duplicate large files; readers follow explicit same-run archive pointers.
Run-008 cold forecast: search420 s, field23 s, residual585–650 s, other10 s, band145 s; total20–22 min, peak1.8 GiB. Same L0=1.6,100 states,6 workers,1e-2 tail target. Reproduce the run-006 residuals and run-007 enclosure inside this new cold run. Expected incremental retained output below9 MB and peak below the global limit.

The optional --states-left / --states-right arguments cap actual-state columns independently. Both default to --states. This only avoids preparing unnecessary columns on the faster-decaying side; every side still computes N+10 and the same operator envelope and tail formula. Run-008 uses100/100, identical to run-006. Later forecasts may use80 on the left and a larger count on the right.

Candidate rule for the family: retain the complete confirmed list and select the lowest k in the searched common window. This continues the lowest mode without using an old candidate as a search input. The enclosure itself makes no uniqueness claim.

Run-008 stopped at the monitor's conservative990 MB worktree warning after the residual stage, before its independent audit. The worktree stayed below the user's1 GB limit. Its k and epsilon values exactly match run-006. Exact duplicate field files now have relative links within this experiment; per-target records are retained once inside the complete summary after exact JSON readback comparison. No failed logs or scientific records are lost. The copied monitor now reserves3 MB below the unchanged1 GB limit; future forecasts include final summary writes.
Run-009 forecast: full cold L0=1.6 again,20–22 min,2.7 GiB, incremental peak below15 MB and total below997 MB. Same mathematical settings as run-008.

## Manager correction

Run-009 was stopped by the manager as an unnecessary L0=1.6 repeat, not a numerical failure. Accept run-006 (cold search, field, residuals and audit) plus run-007 (mass, C, rational assembly and full-phase band check from those same-experiment outputs) as the reliable L0=1.6 result. Run-008 independently confirms the same k and five residuals. No further L0=1.6 run will be made. Its cost is reported as a measured stage sum with the continuation boundary explicit.
The whole-worktree budget is now2 GB; the monitor stops above1.99 GB using the same measurement, and the experiment stays below1 GB. No further storage cleanup is needed. Individual future target records are retained as well as their summaries.
Run-010 feasibility forecast for L0=2.0: rebuild the field from the explicitly supplied floating candidate, then80/230 state columns with3 workers on seven right-lead targets, and a band-window pilot at(1.45,2.37). Expected5–7 min,2.8 GiB, below15 MB outputs. From run-006, a full80/230 solve is forecast around31–35 min with4 workers, or27–30 min with5; choose the largest worker count whose measured per-process pilot RSS leaves margin below3 GiB. The pilot is not a cold full result. Tail/finite-square target0.1 is proposed; all tails remain included.

Run-010 passed all seven target gates and the16 sign-test band pilot at(1.45,2.37):298.201 s,1.056 GiB. The three right-state workers peaked at0.300/0.307/0.309 GiB for230 columns; the setup process peaked at0.409 GiB. Right interior/seam tasks cost70.7–74.4 s; material target0 cost14.8 s. The right ball one-step bound is0.79529429, two-step0.62180773.
Run-011 cold L0=2.0 forecast:80 left/230 right states,5 workers, tail/finite-square target0.1, certified-window request(1.45,2.37). Expected selected depths about60 left and205–215 right, with10 extra states for the check. Setup103 s; queue900–1050 s (run-006 task totals scaled by columns, checked against run-010); search420–460 s, field23 s, other stages160 s. Total27–30 min; peak forecast2.7 GiB, allowing worker growth beyond the short pilot. Retained outputs below20 MB, temporary peak below45 MB, fitting the2 GB worktree and1 GB experiment limits. All tails are included; target0.1 permits at most sqrt(1.1)-1=4.88% inflation of an individual norm relative to its finite bound, with actual inflation reported after selection. This run starts from an empty directory and uses no pilot field or candidate.

Run-011 residual stage passed:882.624 s scientific,3784.545 CPU s, setup102.709 s, queue779.711 s with5 workers. Selected depths left58/59/63 and right208/196/206 (material/interior/seam); all p1 and forced-p2 N+10 checks passed. The full band stage subsequently passed.
Run-012 forecast, conditional on run-011 completing: cold L0=1.9,5 workers,80/160 state columns, tail-square target0.1, window(1.46,2.37). Expected depths about55 left and125–135 right. Scaled measured residual CPU from run-011 gives roughly2930 CPU s; setup85 s and queue600–700 s, plus search440 s, field25 s, other160 s: total21–24 min. Peak forecast2.3 GiB (run-011 observed1.83 GiB with more columns), output below20 MB, temporary peak below45 MB. This is a new cold result; it reads no run-011 field or candidate.

Run-011 COMPLETE:1501.089 s cold end-to-end, peak1.827057 GiB, all944 full-phase sign tests and independent checks passed. Q=6.23450945472772564e-13, U_used=.647860, full mu width8.1552944188614e-12. Two candidates were found; the predefined lowest-k rule selects1.4555571632845181. The second2.215620347584495 is retained, with no uniqueness claim. The N+10 scalar accounting gives8.0855823972e-12 (0.862% lower); the delivered outward-rounded interval retains all selected tails.

## Reproduction and retained evidence

The full driver accepts all paths explicitly. From the repository directory, the
following starts a fresh L0=2.0 result (the output directory must not exist or
must be empty):

```sh
python3 test/bie-bound/gapedge-v1/run_pipeline.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/gapedge-v1/output/run-013 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --conda /Users/whc/opt/miniconda3/condabin/conda \
  --example empty-rotated --center-width 2.0 --workers 5 \
  --states-left 80 --states-right 230 --tail-ratio 0.1 \
  --k-lower 1.45 --k-upper 2.37
```

For L0=1.9 use a distinct empty output, `--center-width 1.9`,
`--states-right 160` and `--k-lower 1.46`; the other
arguments are unchanged. L0=1.6 is already accepted and was not repeated
after the manager correction. The report and accepted-L16.json name its
continuation boundary. launch_probe.py and resource_pilot.py take explicit
inputs and were used only for the separate resource forecast, not as hidden
inputs to a cold run. Every actual command is also in its command.json.

Model source: example_parameters.m. Propagation bound: residual/propagation.py.
Actual-state selection and p1/p2 checks: residual/groups.py. The intervals,
source ledgers, audit, two-configuration constants and band tests are in each
completed run. Numerical inputs are exact binary64 exports from that same
run; gzip is lossless and each compressed aggregate was read back exactly.
No mathematical remainder or acceptance gate was weakened. The changed
controls are center width, state-column capacities, tail ratio, worker count,
and the explicitly tested band window. The junction proxy radius uses each
field's own local port coordinate; the equal-width regression is unchanged.

study_summary.py regenerates the compact measured tables from the explicit
accepted continuation and completed cold runs. Its N-prediction and N+10
width comparison are ordinary scalar diagnostics, not replacements for the
outward-rounded scientific assembly. The numerical driver never reads them.

Run-012 COMPLETE:1333.256 s cold end-to-end, peak1.381134 GiB. Q=3.86031222574658415e-13, U_used=.648689, full mu width5.2160427687771e-12. Selected depths left54/55/58, right128/121/126; all p1/p2 and N+10 checks, residual audit, rational assembly and944 band tests passed. No target fallback or split occurred in run-011 or run-012.

| L0 | Accepted source | Q upper | U used | Full mu width | Time boundary and seconds | Peak GiB |
|---:|---|---:|---:|---:|---|---:|
|1.6|run-006 + run-007|4.12005038116436373e-13|.648889|6.3518489429721e-12|successful stage sum1180.721; continuation|1.703|
|1.9|run-012|3.86031222574658415e-13|.648689|5.2160427687771e-12|cold end-to-end1333.256|1.381|
|2.0|run-011|6.23450945472772564e-13|.647860|8.1552944188614e-12|cold end-to-end1501.089|1.827|

The right material depth rises72 ->128 ->208. The latter two runs use the same5 workers and0.1 tail-square target. Residual wall time rises718.781 ->882.624 s; CPU3068.596 ->3784.545 s. None of the floating series requires p>1; the forced p2 bounds on actual near-edge states provide the requested general-p demonstration. Full raw short powers and N+10 comparisons are retained.

All compact summaries can be regenerated without solver runs:
```sh
python3 test/bie-bound/gapedge-v1/study_summary.py --accepted test/bie-bound/gapedge-v1/accepted-L16.json --runs test/bie-bound/gapedge-v1/output/run-012 test/bie-bound/gapedge-v1/output/run-011 --output test/bie-bound/gapedge-v1
python3 test/bie-bound/gapedge-v1/floating_summary.py --inputs test/bie-bound/gapedge-v1/output/run-001/series.json test/bie-bound/gapedge-v1/output/run-002/series.json --output test/bie-bound/gapedge-v1/floating-series.csv
python3 test/bie-bound/gapedge-v1/run_ledger.py --input test/bie-bound/gapedge-v1/output --output test/bie-bound/gapedge-v1/run-ledger.csv
```
The floating CSV's distance_to_baseline_k146 column refers only to the earlier1.46 endpoint; run-011 separately certifies1.45. run-ledger.csv counts6919.892 s including failed operations, probes and the manager-stopped repeat; that sum is separate from each selected configuration's cost.
