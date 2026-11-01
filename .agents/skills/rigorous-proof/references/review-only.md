# Review only

Use this workflow only after selecting **Review only** mode.

Do not modify the proof under review. Reading local references and downloading
lawful public references into the project-prescribed literature location are
permitted; in this repository, use `ref/ref_data/`. List every downloaded file
in the completion report.

## Review workflow

1. Fix the exact file, theorem, proof, and requested review scope.
2. Reconstruct the claim, assumptions, definitions, and dependency chain.
3. Check each inference, cited theorem, hypothesis match, and conclusion bridge.
4. Distinguish definite errors from unresolved source dependencies and from
   merely unclear exposition.
5. Check whether the proof proves the stated conclusion under the stated
   assumptions, not a nearby result.

Review only what was asked. Statements the document declares as assumptions,
expectations, estimates, or plans are outside the review unless the user asks
otherwise; so are strategy, novelty, and style.

## Every finding has a form

A finding must be one of:

1. **Failed step**: quote the step and say exactly why it does not follow.
2. **Counterexample**: give a concrete case that satisfies the stated
   hypotheses and violates the conclusion.
3. **Missing hypothesis**: name it and show where the argument fails without
   it.
4. **Wrong citation**: the cited result does not state what is used, or its
   hypotheses are not met; quote the cited statement.

Concerns without one of these forms are not findings: "may need more rigor",
"should be verified", "consider adding", "it is unclear whether". A missing
citation is a finding only when the step is not a standard result (see
`literature-verification.md`) and is not proved in the text. Ambiguous wording
is a finding only when two readings lead to different validity; give both
readings.

If a step is correct, mark it correct and add nothing.

## Classify by effect

- **Blocker**: a stated result is false or not proved as stated.
- **Important caveat**: a hypothesis is missing, and the result holds once it
  is added.
- **Minor caveat**: presentation only; validity is not affected.

For every finding, report:

1. file, theorem, and exact location;
2. its form (1–4) and class;
3. effect on validity; and
4. for a blocker or important caveat, the minimum repair: the added
   hypothesis, the corrected statement, or the replacement step.

Keep repair suggestions in the report. Do not insert them into the source file.
Explicitly confirm at completion that the proof file was not modified.
