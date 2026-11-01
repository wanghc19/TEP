# Proof review

Review the proof only. Do not edit the reviewed file; write the review only
to the file the prompt names. If the repository has a proof-review skill,
follow its review-only mode as well; this file adds the rules below.

## Scope

- Review exactly the statements and sections the prompt names.
- Inputs that the prompt marks as already reviewed are not re-reviewed.
  Check only that they are cited correctly: the cited quantity bounds what
  the text says it bounds, for the same object.
- Out of scope unless the prompt says otherwise: strategy, novelty,
  numerical estimates, style, notation preferences, and statements declared
  as assumptions.

## Every objection has a form

Each objection must be one of:

1. **Failed step**: quote the step and say exactly why it does not follow.
2. **Counterexample**: give a concrete case (operator, function, numbers)
   that satisfies the stated hypotheses and violates the conclusion.
3. **Missing hypothesis**: name it, and show where the argument fails
   without it.
4. **Wrong citation**: the cited result does not state what is used; quote
   the cited statement.

Not accepted: "may need more rigor", "should be verified", "consider adding",
"it is unclear whether", or any concern without one of the four forms. If a
step is correct, mark it correct and add nothing.

## Classify and repair

- **Blocker**: a stated result is false or not proved as stated.
- **Important caveat**: a hypothesis is missing, and the result holds once it
  is added.
- **Minor caveat**: presentation only; validity is not affected.

For each blocker and important caveat, give the smallest concrete repair:
the added hypothesis, the corrected inequality, or the replacement step.

## Output

- A table: item → verdict (correct, or objection id) → one line.
- The objections, numbered, each with its form, class, quoted text,
  argument, and repair.
- A final reply with the counts of blockers, important caveats, and minor
  caveats, and one line per blocker.
