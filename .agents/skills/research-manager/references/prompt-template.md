# Prompt template

Write prompts to workers in English, in this order. Keep each section short;
a worker should be able to start after one reading. Save each prompt as a
file before sending.

```markdown
# <Stage name>: <one-line task>

Follow the research-worker skill, mode: <Experiment | Literature survey |
Direction search | Proof review>.
Time limit: <N> hours from now, including coding, debugging, and runs. If you
run short, write what you have, mark unfinished parts TODO, and stop.

## Goal
<The question this stage answers, and the number or verdict that answers it.
Give the reference values the result will be compared with.>

## Background
<Files to read, each with one line on why. Only what is needed.>

## Inputs (read-only)
<Exact files or directories, which variables to load, and the rule
"never write, copy, or move anything there".>

## Method (suggested)
<Steps. "You may change the method if you find a better one; say why.">

## Checks (all required before reporting)
1. <A reproduction of a known number, with tolerance.>
2. <Two independent computations of the main quantity.>
3. <A convergence or doubling test.>

## Budget and layout
<Experiment directory and run layout from the repository rules; time and
memory budget; storage limit; expected cost; which run goes first; which
files outside the experiment may be edited; commit or not.>

## Output
<File(s) to write and their sections: purpose, method, reproduction command,
results table, checks, cost, meaning for the goal.>

Writing rules: plain, direct English; at most one "Main risk:" line per
item; no evidence-level labels, timestamps, hashes, or git/storage
narration.

Subagents: <"Do not spawn subagents." | the exploration rule below,
filled in>.

Final reply, at most 8 lines: <the numbers or verdicts>, one line per check,
anything unresolved.
```

## Notes

- State reference values in the prompt so the worker can see at once whether
  a result is plausible; do not ask it to rediscover known numbers.
- Name the decisive number. A stage that ends in "more understanding" is
  hard to verify.
- For a proof review, add an explicit out-of-scope list and the four
  objection forms (see the worker's `proof-review.md`).
- For a direction search, restate the scope rule: numerical analysis,
  combinations of existing methods count, no "no direction found".
- For a literature task, list the specific groups or papers to check, and
  restate the no-inflation rule.
- Always write the `Subagents:` line; a thread that is not told may carry
  over an earlier setting.
  - Explicit task (a stated proposition, a proof, a proof review, an
    experiment with a fixed design): "Do not spawn subagents."
  - Default for every task, exploration included: "Do not spawn
    subagents." (user rule, 2026-11-05: subagents only when necessary).
    Use the exploration rule below only when the candidates are clearly
    independent and too many for one thread in the time box; say why in the
    log.
  - Exploration task (find or compare possible methods): "You may spawn at
    most 3 subagents, each with reasoning effort `high` (state it when
    spawning; otherwise they inherit yours), one candidate each. Subagents
    may write code and run small checks, but only in `<scratch>/<task>/`;
    when an experiment is running on the same machine, each check uses one
    process and about one CPU-minute. Each returns: predicted gain (error
    and time), the conditions it needs, proof status (idea / draft /
    checked), and the smallest decisive check. Their proofs are drafts: you
    check every step before it enters the deliverable, and mark anything
    unchecked `unverified`. Only you write the deliverable." Add a time box
    for the exploration phase (about 45 minutes), after which the main
    thread chooses one candidate and completes it.
  - Experiment threads: no subagents unless the user approves a specific
    exception.
  - Give an exploration task one clear goal; list candidates as suggestions,
    not "as many as possible".
