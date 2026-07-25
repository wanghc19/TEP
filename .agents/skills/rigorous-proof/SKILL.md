---
name: rigorous-proof
description: Enforce a rigorous workflow for proving, reviewing, repairing, rewriting, and source-verifying mathematical theorems, lemmas, propositions, and corollaries. Use for English requests to prove or establish a result from scratch, review or audit an existing proof, fill proof gaps or repair a proof in place while preserving original text, completely replace a proof whose strategy has substantially changed, or verify citations and theorem hypotheses. Also use for Chinese requests containing intents such as 从零开始证明、证明定理、只审查、检查证明、审查证明、补全证明、修正证明、原位修订、完整重写证明、核验引用、检查参考文献 or 检查定理条件.
---

# Rigorous Proof

Use the requested language. Preserve original bibliographic titles and source
notation when appropriate.

## Choose one mode

Select and report exactly one primary mode before beginning:

1. **Proof from scratch**: construct a proof from the statement and assumptions.
2. **Review only**: inspect an existing proof without modifying it.
3. **In-place repair**: preserve all original text and add marked repair blocks.
4. **Complete rewrite**: replace the target environment's body in the original
   file when the proof strategy has changed substantially.

Default to **Review only** for requests to check, review, or audit and whenever
edit authorization is unclear. Use **In-place repair** for requests to complete,
fix, or fill gaps unless the user explicitly requests a rewrite. Use
**Complete rewrite** only with explicit authorization.

## Constrain every file write

Before any file write, identify the exact file, theorem or statement, insertion
location, and target environment. Use a `proof` environment by default unless
the user specifies another environment.

Confine all changes to the target environment. For a new proof with no existing
environment, create the selected environment only at the uniquely specified
location. If the target is ambiguous, stop and request clarification.

Do not change content outside the target environment unless the user explicitly
authorizes it. Treat additions such as a new lemma, proposition, definition, or
remark as outside-scope changes requiring separate authorization. After an
authorized outside addition, report its content, label, and resulting number;
do not claim an automatically generated number was verified unless it was
actually resolved.

These boundaries govern file writes. A proof returned only in conversation does
not require a document environment.

## Load the applicable instructions

Read each applicable reference completely before acting:

- Every mode: [literature-verification.md](references/literature-verification.md)
  and [reporting.md](references/reporting.md).
- Proof from scratch: [proof-from-scratch.md](references/proof-from-scratch.md).
- Review only: [review-only.md](references/review-only.md).
- In-place repair: [in-place-repair.md](references/in-place-repair.md).
- Complete rewrite: [complete-rewrite.md](references/complete-rewrite.md).

Do not load unrelated mode files merely for completeness.

## Core contract

Before formal reasoning:

1. State the assumptions, quantifiers, and conclusion precisely.
2. Define every nonstandard symbol.
3. Give the domain, codomain, and action of every operator or mapping.
4. State relevant spaces, topology, norms, regularity, parameter ranges, and
   boundary conditions.
5. Report ambiguity or missing assumptions before deciding whether proof can
   continue.

For every cited theorem:

1. Identify the inspected source and exact result.
2. List its hypotheses in source order and match each to an established fact.
3. State exactly what the theorem yields.
4. Prove or cite every nontrivial implication from that conclusion to the
   current target.

Omit further proof only for genuinely standard foundational results. If that
classification is reasonably disputable, prove the step or cite it.

Never present an uninspected literature claim as verified. Never apply a result
with an unmet hypothesis. Mark unavailable-source dependencies as conditional
and unresolved.

Store task literature in the mathematical project's `ref/` directory, never in
this skill's `references/` directory. The latter contains workflow instructions
only.

For long arguments, use purpose-specific steps such as definitions, hypothesis
verification, theorem application, and deduction of the target. Add a separate
notation step only when it materially aids verification.

## Completion gate

Do not declare the proof or review complete until:

- every proof obligation is discharged or explicitly recorded as a gap;
- every relied-on citation and theorem hypothesis has been verified;
- every cited conclusion has been connected to the target;
- the selected mode's file-integrity rules have passed; and
- the report required by [reporting.md](references/reporting.md) is complete.
