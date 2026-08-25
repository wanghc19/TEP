# I3.1 BIE-collar weak residual

This directory implements the reviewed V3 design
[[research/projects/eig-apost/implementation/i3/design-3-1d|design-3-1d]]. It reconstructs
one-cell BIE fields only at qualified targets, repairs circle and wall traces into a
periodic-gauge conforming Q1 companion, and applies an RT0 functional majorant with
full-matrix lead tails.

The implementation has one entry and two scientific helpers. `i31_bie_cell.m`
owns BIE densities, one-sided traces, safe-target evaluation, and the bounded
value/first-gradient quasiperiodic kernel. `i31_fe_cell.m` owns the conforming
Q1 collar companion and RT0 majorant. This split follows the two scientific
objects and keeps each substantial helper below 1000 lines.

## Formal result

Researcher and Engineer agreed on the frozen implementation, and Skeptic gave the final
spec-to-code pass before execution. The append-only `bie-a3` attempt completed with shell exit
zero and producer status

```text
I3_1_HDIV_FLUX_UNRESOLVED
```

Finite input, branch/Wood, propagation, BIE density, one-sided surface trace, and safe field
evaluation passed. The first unavailable condition arose in the coarse lead RT0-majorant
pre-factor: the free-block scaling diagonal contained at least one nonfinite or nonpositive
entry. The machine label is preserved, while the independent review explains that the matrix
already contains the true-circle polar correction and had not yet passed its integration-object
gate. This result therefore identifies a composite majorant quadrature/assembly blocker; it does
not show that the continuous $H(\mathrm{div})$ theory failed.

No RT0 flux, Gram, full-$P$ tail, functional-majorant components, normalized indicator, or
prediction interval was formed. The authoritative interpretation is
[[research/projects/eig-apost/implementation/i3/review-3-1d|review-3-1d]].

Runtime was 379.523247125 s and peak active-object memory was 89.6576280594 MiB, with no
attempt-local retry. The attempt stayed below the 900/1800 s and 512 MiB limits. Its output
directory contains only `result.mat` and `report.md`.

## Consumed frozen contract and actual command

- Attempt: `bie-a3`.
- Schema: `TEP_I3_1_BIE_COLLAR_WEAK_RESIDUAL_V3_REV_B`.
- Output: `test/i3/b-resid/output/bie-a3/`; it was absent before the run and is now immutable
  append-only evidence.
- Candidate: $\widehat k_h=1.832770289108157$; $n_{\mathrm{tot}}=256$, $M=48$.
- Q1 levels: $64\times128$ and $96\times192$; circle collars use
  $\delta_c=\delta_w=0.04$.
- Source qualification: the solved $256$-point density is interpolated to $512$ points
  only for surface traces, safe rings, and overresolved walls.
- Budget: expected $8$--$15$ min and $200$--$400$ MiB; soft/hard limits are
  $900/1800$ s and the active-object limit is $512$ MiB.
- Attempt-local retry count was zero; two prior failed attempts are recorded separately.
  Any further work requires a new append-only attempt and a reviewed minimal revision;
  scientific parameters and thresholds remain frozen.

The actual command used after the independent spec-to-code pass was:

```bash
matlab -batch "addpath(fullfile(pwd,'test','i3','b-resid'),fullfile(pwd,'test','i2','k-count')); check_b_resid('bie-a3');"
```

This command and the consumed `bie-a3` tag are recorded for audit only and must not be run again.
Any later execution requires a new attempt tag and a new run authorization.

Current state: `POST-RUN PASS / VALID NEGATIVE / HDIV_FLUX_UNRESOLVED / NO ESTIMATOR`.
The ordinary-double result did not reach an estimator candidate; it is not an I3.2 independent
reference or a reliable spectral interval.

## Consumed startup attempt

`bie-a1` is immutable append-only history. MATLAB returned shell exit code 0, while the
producer recorded `EXECUTION_UNAVAILABLE` with identifier `MATLAB:nonExistentField` and
message `Unrecognized field name "kstar".` after 0.04598954166666667 s and 0 MiB. No
scientific stage or evaluator computation was entered. The output directory was created
and contains `result.mat` and `report.md`.

Revision A keeps `kseed` as the only persisted semantic field. Immediately before the two
legacy `eval_i21` calls, the entry creates a local adapter configuration whose legacy
`kstar` field equals `kseed`; this compatibility field is not stored in `result.config`.
No scientific algorithm, parameter, threshold, failure order, or resource limit changed.

`bie-a2` is also immutable append-only history. It passed finite input, branch/Wood,
propagation, BIE density, one-sided surface trace, and safe-field evaluation, then stopped
before Q1 reconstruction with `MATLAB:m_improper_grouping`. The exact parser message points
to `i31_fe_cell.m` line 131, column 29; elapsed time was 222.9809575416667 s and peak
active-object memory was 89.65762805938721 MiB. Q1 and all later stages are `NOT_REACHED`.
Its output contains only `result.mat` and `report.md`.

Revision B mechanically replaces the four invalid expressions `xx.'(:)` and `yy.'(:)` in
the two mesh constructors by `reshape(xx.',[],1)` and `reshape(yy.',[],1)`. This preserves
the node ordering used by `ids` and changes no scientific parameter, threshold, or formula.

Before the formal `bie-a3` run, the independently approved read-only MATLAB Code Analyzer
preflight was:

```bash
matlab -batch "files={fullfile(pwd,'test','i3','b-resid','check_b_resid.m'),fullfile(pwd,'test','i3','b-resid','i31_bie_cell.m'),fullfile(pwd,'test','i3','b-resid','i31_fe_cell.m')}; for j=1:numel(files), fprintf('\\n%s\\n',files{j}); disp(checkcode(files{j},'-id')); end"
```

This preflight did not execute the experiment or create an attempt output. It completed before
the formal run with no parser, undefined-use, or scientific-dataflow blocker. Style and advisory
warnings were recorded without changing the frozen scientific code.
