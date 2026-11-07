# Red-team guidance

Read the root, research, and test guidance. This directory is the authorized
exception to the default `test/` location for adversarial checks.

- Keep new case code, analysis, downloads, logs, and outputs here. Existing
  research, experiments, manuscripts, references, and Claude files are read-only
  unless explicitly authorized otherwise. Do not commit, change branches, or
  edit other worktrees without explicit authorization.
- Follow `test/AGENTS.md` for run budgets, monitoring, and version/run records,
  including the default 3 GiB peak-memory limit. Start with short serial checks;
  do not run numerical work concurrently without coordination.
- State each case's suspicion, falsification criterion, dependencies, and
  resource estimate before execution. Disclose reused implementation and data.
- Distinguish confirmed findings, conditional conclusions, suspicions, resolved
  issues, and open questions. A confirmed failure requires proof or reproducible
  evidence; a toy example alone does not refute the production candidate.
- Preserve the selected field/data identity, assumptions, and result status.
  Distinguish numerical support from proof and $k$ from $\mu=k^2$.
