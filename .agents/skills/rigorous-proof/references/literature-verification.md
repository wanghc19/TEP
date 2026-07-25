# Literature verification

Apply this workflow in every task mode. Do not present an unverified literature
claim as verified.

## Locate and store sources

Use `ref/` at the root of the current mathematical project for task literature.
Never store task literature in the skill's `references/` directory.

Before using an external result:

1. Check `ref/` for the intended source.
2. If absent, search lawful public sources such as publisher and journal sites,
   DOI pages, arXiv, author sites, and institutional repositories.
3. Download an available lawful public full text into `ref/`.
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

## First pass with missing sources

Do not stop the entire task merely because a source is unavailable. Mark each
dependent step unverified, continue only conditionally, and identify the exact
literature claim required. Do not guess result numbers or pages.

Assign exactly one applicable first-pass status:

```text
Preliminary proof; literature verification is incomplete.
Preliminary review; literature verification is incomplete.
```

Use the review status only in Review-only mode.

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

Only after all citations and dependent inferences pass may the report use
exactly one applicable completed status:

```text
Proof literature verification completed.
Review literature verification completed.
```
