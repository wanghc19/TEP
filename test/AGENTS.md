# Experiment guidance

The root `AGENTS.md` also applies.

## Scope and resources

- Give each experiment its own directory. By default, write only in the active
  experiment directory, keeping code, logs, outputs, and reports there.
  Changes outside it require explicit authorization.
- Estimate complete-run time and peak memory before launch. Unless the user
  specifies otherwise, use a 30-minute planned/soft limit, a 40-minute hard
  limit, and a **3 GiB peak-memory hard limit**. Do not launch a run expected
  to exceed its budget.
- Allow at most one extension beyond 30 minutes, only with objective evidence
  of imminent completion, and never beyond 40 minutes. Stop and report at a
  hard limit. Monitor resources during execution.
- All stages and subprocesses of one scientific result share its budget; do not
  split computation to reset the clock. A corrected rerun after an operational
  failure receives a fresh run budget; this is not a cumulative debugging budget.

## Experiment versions, runs, and retained results

- For new experiments, default to `test/iN/name-vN/output/run-001/`, without an
  `attempt-*` layer. The `-vN` suffix identifies an experiment plan or implementation
  version; `run-NNN` identifies an individual execution.
- Reuse the experiment version for debugging and reruns; give each execution a
  distinct run directory and retain failure logs. Do not create a new version
  merely for code, path, dependency, or environment fixes or to preserve logs.
- Use a new version for substantial changes to the experiment plan or
  implementation. Record parameter comparisons in explicit configurations; add
  meaningful case directories only when needed, not another generic attempt layer.
- Preserve historical directories, numbering, and references, including existing
  `attempt-*` paths. This convention does not authorize moving old outputs or
  rewriting their callers and records.
- Follow the root reproducibility and large-output rules. Promote only validated
  results to research records, with their limitations stated.

## Numerical runtime portability

- Numerical entry points use explicit numerical inputs/configuration and the
  code required for computation. They must not read documentation, designs,
  reviews, Git metadata, manifests, or hashes to configure or authorize a run,
  or require old outputs as hidden prerequisites.
- Keep scientific parameters in MATLAB source or explicit arguments. Resolve
  functions normally on the MATLAB path; a launcher may supply paths, but the
  numerical code must not discover repository roots or require a fixed directory
  layout. Moving the code and its dependencies must not require source edits.
- Machine-side provenance is optional and cannot be a numerical dependency.
  Keep content hashes out of human-facing research reports.
