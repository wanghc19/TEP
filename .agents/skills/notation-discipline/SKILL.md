---
name: notation-discipline
description: Keep mathematical notation transparent, necessary, unambiguous, and easy to trace while preserving rigorous, detailed, and preferably elementary reasoning. Use when writing mathematical definitions, propositions, theorems, derivations, or proofs where new notation or intermediate objects may be introduced; when auditing a manuscript for unnecessary symbols, opaque aliases, symbol conflicts, inconsistent semantic typography, differential or imaginary-unit formatting, redundant spaces, operators, or abstraction layers; or when applying a user-approved notation refactor without changing mathematical logic. Trigger for English requests such as "reduce notation", "audit mathematical notation", "check symbol conflicts", "simplify symbols", or "notation refactor", and Chinese requests such as “减少符号”、“检查符号是否必要”、“检查符号冲突”、“审查记号”、“简化数学记号” or “符号重构”.
---

# Notation discipline

Reduce symbol-memory burden, opaque aliases, and unnecessary abstraction while
preserving correctness, rigor, detail, and elementary accessibility.

## Choose one mode

Select one primary mode unless the user explicitly combines them:

1. **Writing**: control notation while drafting mathematical content.
2. **Audit**: inspect notation and recommend changes without editing.
3. **Refactor**: apply only a user-approved notation map.

Default to read-only **Audit** mode whenever edit authorization is unclear. Do
not silently turn an audit into a refactor.

## Load the applicable instructions

Read each applicable reference completely before acting:

- Every mode: [principles.md](references/principles.md).
- Writing: [writing.md](references/writing.md).
- Audit: [audit.md](references/audit.md).
- Refactor: [refactor.md](references/refactor.md).
- Symbol conflicts, semantic font classes, differentials, imaginary units, or
  LaTeX spacing: [semantic-typography.md](references/semantic-typography.md).

Do not load unrelated mode files merely for completeness.

## Governing priorities

Resolve conflicts in this order:

1. mathematical correctness;
2. logical completeness and verifiability;
3. precise hypotheses, quantifiers, dependencies, and conclusions;
4. elementary accessibility and transparency;
5. directness of the mathematical route;
6. minimal notation and abstraction;
7. textual brevity.

Never sacrifice a higher priority to improve a lower one. Do not optimize proof
length as an end in itself.

## Core contract

Prefer a longer transparent expression over a shorter opaque alias when the
alias adds no independent mathematical concept. Minimize detours and abstraction
layers, not proof obligations or explanatory detail.

Introduce or retain a nonstandard symbol only when it has a concrete role, such
as stable independent meaning, recurring structural value, or substantial
multi-step clarity. Do not name an expression merely because it is long or
repeated.

Track each symbol's definition, meaning, semantic class, and scope. Detect
conflicts across the authorized scope, including related files and parallel
language versions when applicable.

Never:

- remove proof steps or hypothesis checks for simplicity;
- edit in Audit mode without explicit authorization;
- make an unapproved adjacent change during Refactor mode;
- use blind global replacement where mathematical roles may differ;
- resolve two genuine-variable collisions only through subtle font changes;
- mechanically replace every `d` or `i`; or
- declare a refactor complete before a zero-residue search.

## Coordination with proof work

When the task also proves or audits a theorem, establish the statement, proof
obligations, sources, and theorem hypotheses under the rigorous proof workflow
first. Then apply this skill to notation and route selection. Rigor and logical
completeness always override notation economy.

## Completion gate

Confirm that all edits stayed inside the authorized mode and scope, every
retained nonstandard symbol has a concrete benefit, symbol conflicts are
resolved or reported, and mathematical meaning and proof logic remain intact.
