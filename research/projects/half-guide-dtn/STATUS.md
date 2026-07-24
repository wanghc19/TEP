# Status

## Current Stage

Stage 1 completed: repository inventory, literature/source setup,
Joly/Coatleven sign audit, and homogeneous-lead DtN prototype.

## Completed

- Confirmed repository root: `/Users/whc/Documents/Work/TEP`.
- Created isolated attempt directory structure.
- Read the full user research brief and repository `AGENTS.md`.
- Confirmed there are pre-existing modified/untracked files outside `attempt/`;
  this attempt did not modify them.
- Located the requested local PDFs and notes under repository paths rather than
  `/mnt/data`.
- Inspected the key Bloch and trace-matching files:
  `+bloch/rayleigh_channels.m`, `+bloch/construct_S.m`,
  `+bloch/solve_modes.m`, `+bloch/mode_traces.m`,
  `+bloch/select_port_traces.m`, `+bloch/farfield_extractors.m`,
  `+bloch/incident_rhs.m`, `+op/construct_A_QP.m`,
  `scat_ld_lead_in.m`, and `tep_edc_scan_local.m`.
- Wrote the first code inventory, Joly derivation, Coatleven comparison,
  equivalence notes, coupling comparison, numerical-method notes, literature
  log, BibTeX file, and report draft.
- Implemented `attempt/prototype/run_all.m` for homogeneous DtN validation.
- Ran one non-interactive Octave sanity check. It produced the expected output
  files and returned exit code 0.
- Compiled the draft report to `attempt/report/feasibility_report.pdf` with
  `latexmk`; the command returned exit code 0.

## Current Conclusions

- Rayleigh modes are ordered by `m=-M:M`; `gamma_m` uses the branch
  `imag(gamma_m)>=0`.
- Existing Bloch trace routines use x-derivative traces first, then convert to
  center-port outward normal signs in `bloch.select_port_traces`.
- For the homogeneous right-port orientation checked here, Joly's local-cell
  blocks satisfy the Riccati equation with `R=exp(1i*gamma*L)`, while the TEP
  outward-normal DtN is
  \[
    \Lambda_{\mathrm{TEP}}=-(T_{00}+T_{01}R)=i\gamma.
  \]
- In a lossless mixed case, the propagating channel remains neutral
  `abs(lambda)=1`, so the absorbing selection `rho(R)<1` does not select it.
  Adding absorption moves the selected branch inside the unit disk.
- Scheme A, keeping `(eta, xi)`, remains the recommended first Muller-DtN
  coupling path.

## Open Issues

- Need to deepen the code inventory for field reconstruction and central
  Muller block traces `Pi_l,D/N` and `Pi_h,D/N`.
- Need to verify publisher DOI/URL metadata for Joly and all secondary sources.
- Need to implement non-diagonal matrix DtN construction for a simple periodic
  obstacle lead.
- Need to decide whether the first obstacle-lead prototype should reuse
  `bloch.construct_S` as a diagnostic route or build local-cell DtN blocks
  directly.
- Need final MATLAB validation by the user; only Octave rough sanity checking
  has been run.

## Files Created Or Modified In This Attempt

- `attempt/README.md`
- `attempt/STATUS.md`
- `attempt/NEXT_STEPS.md`
- `attempt/DECISIONS.md`
- `attempt/theory/current_code_inventory.md`
- `attempt/theory/joly_dtn_derivation.md`
- `attempt/theory/coatleven_comparison.md`
- `attempt/theory/equivalence_analysis.md`
- `attempt/theory/coupling_options.md`
- `attempt/theory/dtn_numerical_methods.md`
- `attempt/literature/source_log.md`
- `attempt/literature/literature_review.md`
- `attempt/report/references.bib`
- `attempt/report/feasibility_report.tex`
- `attempt/report/feasibility_report.pdf`
- `attempt/prototype/run_all.m`
- `attempt/experiments/homogeneous_dtn_validation.csv`
- `attempt/experiments/homogeneous_dtn_validation.md`
- `attempt/experiments/experiment_summary.md`

## Current Recommended Scheme

Use Scheme A for the first coupling prototype: keep the current central-cell
unknowns `(eta, xi)` and replace only the outgoing port-trace equations by DtN
equations. For discrete DtN construction, use the local-cell Riccati/QZ route as
the main research path and scattering-to-DtN only as a diagnostic bridge.

## Main Risks

- The lossless pass-band DtN may fail to be a single-valued bounded operator
  without limiting absorption or a Cauchy-data relation formulation.
- The Dirichlet trace block of a selected outgoing modal subspace can be
  singular or badly conditioned, so `Lambda = N / D` may be numerically and
  structurally unsafe.
- The central single-cell representation may retain a coefficient nullspace
  even after DtN replacement; physical nonzero-field checks remain necessary.
- The first Octave run printed `error: ignoring const execution_exception& while
  preparing to exit` despite exit code 0 and complete outputs. Treat this as an
  Octave environment warning unless it reappears with a nonzero exit code or
  missing files.

## Validation Run

Rough Octave command run:

```bash
conda run -n octave octave --no-gui --quiet --eval "addpath(genpath(pwd)); run('attempt/prototype/run_all.m')"
```

Result:

- exit code 0;
- homogeneous Riccati residuals about `1e-15`;
- project DtN relative errors about `4e-17`;
- lossless stable count `16/17` selected channel branches because one channel is
  propagating/neutral;
- absorbing stable count `17/17` selected channel branches for both tested
  absorption values.

Draft report compile command:

```bash
cd attempt/report
latexmk -pdf -interaction=nonstopmode -halt-on-error feasibility_report.tex
```

Result: exit code 0. The shell emitted sandbox/locale warnings, but `latexmk`
reported all targets up to date and produced `feasibility_report.pdf`.
