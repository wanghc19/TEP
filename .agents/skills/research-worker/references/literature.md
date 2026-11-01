# Literature

Manage references by the current repository's rules (catalog, file naming,
storage location, download policy). This file adds rules for searching and
for summarizing.

## Search coverage

- Search for direct prior work on the project's own problem: the same model
  class, the same quantity, the same type of result (for example a
  guaranteed bound, a convergence rate, a computer-assisted proof). Check the
  groups that are known for that type of result, not only the general
  method literature.
- Search both directions in time: the classical source of a method and its
  recent uses.
- Report the queries or venues you covered in one short line, so the manager
  can see a gap.

## Read before you summarize

- Summarize only what you read in the source itself (the paper, or the book
  section). Abstracts, citing papers, and search snippets are leads, not
  sources; label them as such if you must mention them.
- For every theorem you report, give the exact location: theorem or
  equation number, and page.
- Download only lawful public full texts. If a source is not accessible,
  say so and give its complete bibliographic data; do not summarize it from
  memory.

## Do not inflate prior work

An inflated summary shrinks the space of possible directions for no reason.
For every paper you summarize:

1. **State what it does, in its own setting.** Model and domain, hypotheses,
   which quantity is bounded or computed, whether the result is analytic or
   numerical, the order of the bound (first or second order, guaranteed or
   estimated), and where in the paper it is.
2. **Separate "did" from "could be extended to".** A method that could in
   principle apply to the project's problem has not been applied to it.
   Write extensions as "possible extension", and name the step where the
   extension would need new work.
3. **List what it does not do.** At least one concrete item relevant to the
   project (for example: no numerical trial field, only first-order bounds,
   bounded domain only, no gap verification).
4. **Match before you exclude.** A paper rules out a candidate direction only
   if it covers the same setting and the same claim. If any element differs,
   record the difference as the opening, not as a reason to drop the
   candidate.
5. **No umbrella phrases.** Do not write "X has been solved", "this is
   standard", or "fully covered by" without the exact statement and its
   location.

## Verdicts

When the prompt asks for a verdict per direction, use these three, each with
the matching evidence:

- **Done**: a source proves the same claim in the same setting (give the
  location).
- **Partial**: sources cover some ingredients; list which are covered (with
  locations) and which are new.
- **Open**: no source found after the stated search coverage.
