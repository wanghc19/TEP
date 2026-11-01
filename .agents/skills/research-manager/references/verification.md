# Verification

Check a worker's result before you report it. Spend the effort where an
error would change the next decision.

## Always

- **Files exist and match the reply.** Open what the worker wrote. The final
  reply is not evidence.
- **Numbers come from outputs.** For each number you will report, find it in
  an output file (JSON, CSV, log) and compare. Recompute any derived number
  (ratio, difference, rate) yourself.
- **Protected files unchanged.** Use `git status` and `git diff` on the
  directories the repository marks as protected, shared code, and earlier
  experiments.
- **Storage and budget.** Check the reported cost against the limits in the
  repository rules, and the worktree size if there is a limit.
- **Scope.** The worker wrote only where the prompt allowed.

## Experiments

- Read the main code path, not only the README. Check the conventions most
  likely to be wrong: signs and phases, normalization, weights, index
  offsets, which field or level is used.
- Reproduce one key number independently when it decides the next step:
  a short script of your own, a different formula, or a direct read of the
  raw output.
- Check that every required check was run, and that its tolerance was set
  before the run.

## Literature

- Open at least one cited source per verdict and check the stated theorem
  against the text: setting, hypotheses, conclusion, location.
- Check the summary in both directions: missing direct prior work
  (a group known for this type of result), and inflated prior work (a paper
  credited with a setting or a bound it does not have).

## Proofs and reviews

- For each objection, check that it has one of the four forms and that the
  form is real (the step really fails, the counterexample satisfies the
  hypotheses).
- For each "correct" verdict on a key step, read the step yourself.
- Apply repairs yourself or delegate them; record which objection each
  repair answers.

## Writing quality

- Over-defensive: repeated hedges, rejection without a concrete reason,
  "no direction found", process logs. Ask for a rewrite or rewrite it
  yourself in the user-facing document.
- Over-claiming: estimates presented as bounds, partial reproduction
  presented as full, sources cited without location.

## Record

Write in the manager log what you checked, how, and the result, in one line
per check. If a check failed, record the correction and tell the user.
