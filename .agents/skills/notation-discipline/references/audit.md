# Audit mode

Use this workflow to inspect notation without editing the manuscript.

## Inventory

Fix the exact file, chapter, section, theorem, proof, or equation range. For each
nonstandard symbol, record:

- exact definition and first-definition location;
- mathematical role and semantic class;
- scope and approximate use pattern;
- synonymous or near-synonymous notation;
- conflicting and visually confusable uses; and
- cross-file, cross-section, or cross-language uses within scope.

## Classify

Give each candidate one recommendation with mathematical and readability
reasons:

- **Retain**: independent meaning or substantial multi-step clarity.
- **Inline and retire**: transparent alias without semantic gain.
- **Merge**: unjustified duplicate notation.
- **Rename**: necessary but misleading, conflicting, or nonstandard.
- **Retypeset**: correct object but incorrect semantic typography or spacing.
- **Localize**: useful only in a local derivation.
- **User decision required**: genuine unresolved tradeoff.

Write every proposed transformation explicitly, including its scope and the
reason it preserves meaning. Distinguish typographic label changes from genuine
variable renames.

Stop after presenting the proposed map. Do not modify the manuscript until the
user accepts or amends it.

## Completion report

Report scope, all classifications, reasons, exact proposed mappings, and a
confirmation that no manuscript edits were made.
