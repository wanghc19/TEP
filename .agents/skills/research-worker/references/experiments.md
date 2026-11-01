# Experiments

Follow the repository's rules for experiment layout, budget, storage, and
protected directories. This file adds the working rules.

## Before running

- Estimate wall time and peak memory of the complete run from a small run
  or from earlier records, and write the estimate in the experiment README
  before the full run. Do not launch a run expected to exceed the budget.
- Write only inside the experiment directory the prompt names, plus any
  other file the prompt names explicitly.
- Treat earlier outputs and other worktrees as read-only inputs. Load only
  the variables you need. Never write, copy, or move files there.
- Keep scientific parameters in source or in explicit arguments; the entry
  point takes input and output directories as arguments.

## Reusing existing code

- Copy helpers into the experiment instead of editing shared or protected
  code.
- Before using copied code for new results, reproduce one existing recorded
  number with it, and report the agreement (relative difference).
- Check conventions that copying can break: phase and sign conventions,
  normalization, weights, index offsets, units.

## Checks

- Run every check the prompt lists. If one fails, stop and report rather
  than adjusting the method until the check passes.
- Prefer checks that compare two independent computations of the same
  number (two formulas, two quadrature orders, two refinement levels).
- Report each check as: what was compared, the two values or their
  difference, and pass/fail against the tolerance stated in advance.

## Monitoring and limits

- Launch every run through the repository's monitoring launcher. The
  launcher samples memory and enforces the limits itself; do not poll
  processes by hand.
- If the sandbox blocks the launcher or the solver (for example process
  listing or solver startup), rerun the same command once through the
  tool's escalated-permission request, with a one-line justification. This
  approved channel is the normal route, not a workaround.
- If the escalation is denied, or the run still fails, do not try other
  routes. Report the exact command and the full error and wait.
- At the hard time or memory limit, stop the run, keep its log, and report.

## Reporting

- The experiment README gives: purpose, method, reproduction command,
  results table, checks, cost (wall time, peak memory), and what the result
  means for the question asked.
- Every reported number must come from an output file; name the file.
- Keep large outputs out of version control and record how to regenerate
  them.
