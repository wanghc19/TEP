# Test Directory Guidelines

- This directory is for experimental implementations and numerical validation.
- Each experiment must have its own subdirectory.
- The active experiment directory is the only writable location by default.
- Keep generated files, figures, logs, and reports inside the corresponding experiment folder.
- Experimental code must not modify files outside its own experiment directory unless explicitly requested.
- Do not modify existing packages or main project code during experiments unless explicitly requested.
- Promote only validated results to the main research documentation.

## Execution budgets

- Estimate the wall time and peak memory of the complete declared experiment
  before launch.
- Unless the user explicitly authorizes another budget in advance, one complete
  scientific run has a 30-minute planned wall-time limit and a 2 GiB
  peak-memory limit.
- Do not start a run expected to exceed either limit; stop the design and report
  the resource blocker.
- Treat 30 minutes as a soft runtime limit. Continue only when objective
  progress evidence shows that completion is imminent, and allow at most one
  grace period of 10 minutes.
- Treat 40 minutes and 2 GiB as hard limits. Stop and report at either limit;
  do not grant a second extension.
- All commands, stages, checkpoints, and subprocesses required for one complete
  scientific result share the same runtime budget. Do not split a known
  over-budget computation to reset the clock.
- This shared budget applies to one correctly configured complete run, not
  cumulatively across failed debugging runs.
- Time spent in an operationally failed or debugging run is not charged against
  the corrected rerun. Each corrected rerun receives a fresh 30-minute soft
  limit and the same bounded grace period in the same attempt directory.

## Attempt lifecycle

- Creating an attempt directory does not consume the attempt.
- Reuse the same attempt directory throughout one conversation for
  implementation, debugging, fixes, and reruns of the same scientific method.
- Code, path, dependency, schema, environment, or other operational failures do
  not consume the attempt. Fix them in place and rerun in the same directory.
- Keep failed-run evidence in the same attempt directory and distinguish runs
  with logs or run identifiers; do not create a new attempt merely to preserve
  outputs.
- Create the next attempt directory only after the previous attempt completed
  its declared full run and the scientific method or frozen contract itself
  failed, requiring a materially different method.
- A correctly implemented method that cannot fit the frozen resource budget may
  be closed as a resource failure before a new method receives the next attempt
  identifier.
- Multiple attempt directories in one conversation are allowed only under the
  preceding completed-method-failure rule.

## MATLAB runtime portability

- Any MATLAB entry point that is actually run must depend only on MATLAB itself and the
MATLAB source files that are genuinely required for the numerical computation.
- Executable MATLAB code must not read, parse, hash, validate, or require any human-facing
Markdown file, design or review document, README, status file, freeze file, manifest, Git
metadata, generated report, historical output, or other non-code artifact in order to run.
- Do not make execution conditional on repository-relative paths, absolute paths,
directory depth, filenames recorded in documentation,
or a particular layout under `test/`.  If an
experiment directory and its required MATLAB/package functions are moved together and
placed on the MATLAB path, the experiment must still run without source edits.
- Resolve MATLAB dependencies through normal MATLAB function resolution.  A launcher may
add the experiment directory or required package roots to the MATLAB path, but numerical code must not discover a repository root, reconstruct sibling paths, or require the original worktree layout.
- Scientific parameters and necessary runtime configuration must live in MATLAB source or
be supplied as explicit function inputs.  Documentation and provenance may describe a run,
but they must never control or authorize execution.
- Untracked SHA-256 files may be retained as optional machine-side provenance.
MATLAB execution must not depend on them, and human-facing documentation must not display
SHA-256 values or other content hashes.
