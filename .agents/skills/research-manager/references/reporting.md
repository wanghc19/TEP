# Reporting to the user

The manager writes every document the user reads. Never forward a worker's
text as it is; rewrite it.

## Language and style

- Write in the language the user uses with you, plainly and directly. Use
  the terminology rules of the repository (for example the required terms
  for estimates and guaranteed bounds).
- Lead with the answer to the user's question, then the evidence, then what
  is still open.
- Use short sentences and the project's notation. Give numbers with the
  quantity they measure and its reference value.
- No process logs, evidence labels, hashes, or tool narration.

## Strength of statements

Keep three kinds of statement visibly apart:

- computed numbers (estimates, observations);
- conditional conclusions, with the conditions listed once;
- proved results, with the source or proof location.

Predictions and planned results are labelled as such where they appear.

## Corrections

If an earlier report was wrong, say so at the top of the next report: what
was wrong, the corrected statement, and why it changed. Update the affected
files in the same step.

## Questions to the user

When a decision belongs to the user, end the report with the question,
2–4 options with their costs, and a recommendation.

## Where reports go

- Short answers stay in the conversation.
- Stage results go into the project's summary file for that line of work
  (a README or status file named in the repository rules or in the log),
  written in the user's language.
- Durable results go to their final location; scratch notes stay in the
  scratch directory.
