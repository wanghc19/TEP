# Direction search

Use this when the task is to propose, compare, or assess research directions.

## What counts as a direction

A direction is in scope when it can become a numerical-analysis paper:

1. an **algorithm** (new, or a new combination or adaptation of existing
   ones) for a problem in the project's model;
2. an **analysis** of it: error, a posteriori bound, convergence rate,
   stability, or complexity, with at least one statement that can be proved;
3. a **demonstration** on the project's model that the repository's code can
   produce within the project's budget.

Combining or adapting existing methods counts. Novelty may lie in the
setting (a model the method has not been applied to), in the analysis (a
sharper or guaranteed bound), or in the efficiency. "Each ingredient is
known" is not a reason to reject a direction.

Stay in numerical analysis. Pure spectral theory, existence theory, or
physics questions are out of scope unless the prompt asks for them, or a
result there is the one missing step of an in-scope direction (then name
that step and stop there).

## How to assess a candidate

For each candidate, give:

- **Claim**: the theorem or result the paper would state, in one or two
  lines, with its strength (see `writing.md`).
- **Algorithm**: steps, and which existing code covers each step.
- **Analysis**: what must be proved, and which part is standard.
- **Demo**: what to run, expected cost, and the number that would show the
  method works.
- **Closest prior work**: from the literature rules in `literature.md`,
  with the exact difference from this candidate.
- **Blocking step**: the one step most likely to fail, and the smallest
  check that would decide it.

## Rejecting a candidate

Reject only for a concrete reason:

- prior work proves the same claim in the same setting (see the matching
  rule in `literature.md`);
- a step is shown to fail (counterexample, numerical evidence, or a cited
  impossibility result);
- the demo cannot run within the budget, with the estimate shown.

"Hard", "risky", "may not be new", or "needs more study" are not reasons to
reject. Record them as the blocking step instead.

## "No direction found" is not a result

Do not end a search with "no viable direction". If every candidate has a
blocking step, report the ranked candidates with their blocking steps and
the smallest decisive check for each, and recommend which check to run
first. The manager decides whether to drop a line.
