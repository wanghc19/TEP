# Literature verification

Apply this workflow in every task mode. Do not present an unverified literature
claim as verified.

## Locate and store sources

Use the literature location prescribed by the current mathematical project's
instructions. In this repository, use `ref/ref_data/`. Never store task
literature in the skill's `references/` directory.

Before using an external result:

1. Check `ref/ref_data/` for the intended source.
2. If absent, search lawful public sources such as publisher and journal sites,
   DOI pages, arXiv, author sites, and institutional repositories.
3. Download an available lawful public full text into `ref/ref_data/`.
4. Never bypass a paywall, login, CAPTCHA, or access control or use an obviously
   unauthorized source.

Name an Agent-downloaded source `<FirstAuthorSurname><PublicationYear>.pdf`,
adding `a`, `b`, and so on for collisions. Verify that the download is an
openable PDF, matches the intended title, authors, year, and version, and
contains the result being cited.

## Record citations precisely

For each cited publication:

1. Give complete bibliographic information.
2. Give a DOI, publisher page, or another stable URL and, when available, a
   public full-text URL.
3. Identify the exact result number.
4. Do not cite only a chapter or section.
5. For an unnumbered result, state that it is unnumbered and give the page and
   uniquely identifying context; never invent a number.
6. Never claim a result number, page, hypothesis, or conclusion was verified
   unless the source itself was inspected.

For every inspected source, locate the exact result, preserve its hypothesis
order and terminology, match each hypothesis to an established fact, and state
its exact conclusion. If the proof needs a different conclusion, prove the
bridge explicitly.

## Results that need no citation

Use without citation, and without a status label, results taught in a first
graduate course and stated in their usual form, for example:

- Cauchy–Schwarz, triangle, Hölder, Young, and Pythagoras in inner-product
  and normed spaces;
- orthogonal projections have norm at most one; best approximation in a
  closed subspace is the orthogonal projection;
- elementary calculus: monotonicity from the sign of the derivative, the
  mean value theorem, integration by parts for smooth functions;
- algebraic expansion of sesquilinear forms; elementary inequalities between
  real numbers;
- for a selfadjoint operator $L\ge c>0$: $\|L^{-1}\|\le c^{-1}$.

Cite a source for named theorems with nontrivial hypotheses (spectral theorem,
representation theorems for forms, trace and embedding theorems, Plancherel,
sharp-constant inequalities) and for anything outside such a course. If a
reader in the field would accept the step without a reference, do not ask for
one.

## First pass with missing sources

Do not stop the entire task merely because a source is unavailable. Mark each
dependent step unverified, continue only conditionally, and identify the exact
literature claim required. Do not guess result numbers or pages.

Mark status per step, not per document. Only the steps that depend on an
uninspected source carry the label "conditional on <source, result>"; all
other steps are stated normally, without labels or qualifiers. If at least one
step is conditional, assign exactly one applicable first-pass status in the
completion report:

```text
Preliminary proof; literature verification is incomplete.
Preliminary review; literature verification is incomplete.
```

Use the review status only in Review-only mode. Put the status in the
completion report, not into the text of the proof or the reviewed document,
and list the conditional steps next to it.

## Second pass

After missing sources are supplied, recheck the entire dependent argument. For
each new source:

1. verify bibliographic identity, edition, and version;
2. locate the exact result;
3. give printed and PDF pages for a book when they differ;
4. recheck every hypothesis in source order;
5. compare the actual conclusion with the earlier conditional assumption; and
6. recheck every deduction to the target.

If the source differs from the preliminary assumption, revise the argument
rather than merely changing the citation.

If no step depends on an uninspected source, or once all such citations and
dependent inferences pass, the report uses exactly one applicable completed
status:

```text
Proof literature verification completed.
Review literature verification completed.
```
