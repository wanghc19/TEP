# Red-team guidance

Read the root, research, and test guidance. This directory holds adversarial
checks of any numerical route in this repository (BIE, FEM + DtN, or later
routes). It is the authorized exception to the default `test/` location for
such checks.

## Layout and write scope

- Each check campaign gets its own directory `redteam/<topic>-vN/`, with runs in
  `output/run-NNN/` as in `test/AGENTS.md`. Write only in the active campaign
  directory and in `redteam/tmp/<task>/`.
- `redteam/tmp/` is untracked scratch, as the root `tmp/` is for other work.
  Outputs that back a finding belong in the campaign's `output/`, with the
  reproduction record that the root reproducibility rules require.
- `redteam/archive/` is historical and read-only. Its old rule files describe
  past campaigns and do not apply to new work.
- Research records, experiments, shared packages, release packages, drafts,
  references, and Claude files are read-only unless explicitly authorized.
  Do not commit, push, change branches, or edit other worktrees without
  explicit authorization.

## Method and resources

- Do not change the mathematical model or the method under test. Call existing
  code with explicit inputs; disclose every reused implementation and data file.
  A modified copy of a solver is not an independent check.
- Follow `test/AGENTS.md` for run budgets, monitoring, versions, and runs,
  including the default 3 GiB peak-memory limit, and the storage limit stated
  in the task. Start with short serial checks; do not run numerical work
  concurrently without coordination.

## Cases and evidence

- Before execution, record each case's suspicion, predicted observation,
  falsification criterion, dependencies, and resource estimate.
- Separate a safe failure (the method stops, rejects its input, or widens its
  result) from a wrong result (a reported enclosure or bound that misses the
  reference value). Only the second refutes a reliability claim.
- Classify findings as CONFIRMED, CONDITIONAL, SUSPECTED, RESOLVED, or OPEN.
  A confirmed failure requires proof or reproducible evidence; a toy example
  refutes only the inference it targets. Give the minimal next step for OPEN.
- State which reference value a comparison uses and how accurate it is.
  Distinguish numerical support from proof and $k$ from $\mu=k^2$.
