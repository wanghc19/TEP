---
name: research-value
description: Judge whether a step in a numerical-analysis research project is worth doing - tie it to the root deliverable the user approved, name the closest existing result, state the expected gain (faster, more accurate, stronger guarantee, wider scope), and give the minimal check and the condition to continue or stop. Use when the user asks why a step is needed or whether it is worth it, before opening a sub-goal, and, with a full value card, when choosing the next research direction; also for Chinese requests such as 这一步有必要吗、为什么要做这个、值不值得做、更快还是更准、有没有人做过、填价值表、下一步方向.
---

# Research value

A chain of sound steps can drift: to solve A we first solve B, to solve B
we first solve C, until nobody remembers A. This skill ties each step to
the deliverable the user approved and asks what it adds: **faster**, **more
accurate**, **stronger guarantee**, or **wider scope**, and whether the
literature already has it.

## Two modes

**Brief (default).** For small sub-tasks, and to answer a user's question
on why a step is needed. Answer in chat with one short table, no file:

| 原目标 | 本项作用 | 最近对照 | 预期收益 | 最小检查 | 继续或停止的条件 |
|---|---|---|---|---|---|

- 原目标: the approved deliverable (precision, guarantee form, scope,
  cost), with where it was approved.
- 本项作用: which link it unlocks; 必需（总目标） / 只对当前方法必需 /
  不必需.
- 最近对照: the closest existing method or result, and the difference.
- 预期收益: kind of gain, expected number, evidence so far.
- 最小检查: the cheapest check that could change the decision, with its
  prediction written first.
- 继续或停止的条件: which outcome means continue, which means stop or ask.

Fill only what bears on the current decision; reuse what is already known.
Switch to a list if cells get long.

**Full card.** When deliberately choosing the next direction, usually at
the user's request, or when a handover needs the record. Fill
[value-card.md](references/value-card.md), save it in the repository's scratch directory,
and show it to the user.

## Rules for both modes

- **Fix the root goal.** Take precision, guarantee form, scope, and cost
  from the user's words, the record of approval, or the current stage
  configuration, and say which. Ask only if a missing value would change
  the decision; otherwise write e.g. "未指定，暂用已有阶段预算". A plan
  that meets the root only by lowering a requirement is a fallback: name
  the requirement, raise it only after a failure, a budget overrun, or
  when the root is clearly out of reach, and let the user decide.
- **Separate root requirements from method requirements.** A condition
  that only the chosen method needs is required for that method, not for
  the root; then the question is whether this method beats the routes that
  do not need it. "No alternative found" holds only within the search done;
  say how far it went, and do not upgrade it to "unavoidable".
- **Control variables.** Name the indicator. Always control the external
  conditions: problem model and instance, target quantity, target accuracy
  or guarantee, cost boundary, hardware. The methods' own differences
  (hypotheses, guarantee form, trial field, mesh, parameters) may differ
  when whole methods are compared: list them and count their cost. When
  one component is compared, fix the others. Each side uses its best known
  parameters, with the rule that chose them. The instance must satisfy both
  methods' hypotheses.
- **Cost.** To compare routes, set the boundary by the actual use case and
  report every cost inside it. Data prepared outside may stay outside only
  if both sides use it the same way; list it with its cost. To decide
  whether to add a step, report its incremental cost, with shared work
  listed separately. Never present a partial cost as total.
- **Evidence follows the decision and the claim.** Screening uses existing
  surveys, reasoned predictions, and minimal checks. A claim for a paper or
  a status record needs the evidence its type requires
  ([criteria.md](references/criteria.md) §1). The reach of the evidence is
  the reach of the conclusion.
- **Names for people, codes for agents.** Codes from `criteria.md` may
  appear in logs and prompts; text for the user uses names only.
- Every number names its source file. Predictions come before checks.
  Budgets come from the repository rules and the stage.

## Outcomes

- **继续**: within the authorized scope and budget, and the step adds value
  or is required. Do not ask again for approval just because a value check
  was done.
- **先做最小检查**: the evidence cannot decide; a check within budget can.
- **交给用户决定**: the step exceeds the authorization or budget, changes
  the direction, lowers a root requirement, or depends on an open problem
  of unknown cost. Bring a recommendation.
- **建议停止**: the literature already has it in the same scope; nothing
  improves in a fair comparison; or a check refuted the prediction the
  value rested on.

## Files

- [criteria.md](references/criteria.md): indicator tree, definitions, and
  the code-to-name table. Read it for a full card, or when a brief answer
  needs a definition.
- [value-card.md](references/value-card.md): full-card template.
- [example-h.md](references/example-h.md): one step in both modes.
