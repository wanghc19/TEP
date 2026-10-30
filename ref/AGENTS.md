# Reference guidance

The root `AGENTS.md` also applies.

- Verify bibliographic metadata and source identity; do not guess missing fields.
  Use lawful public full texts for downloads.
- Update both `README.md` and `reference.bib` when references change, ordered by
  first-author surname and then year. Keep index entries concise.
- Store reference documents in the sibling `TEP_ref/`, accessed through
  `ref/ref_data/`. Catalog paths are relative to `ref/` and start with `ref_data/`.
- Name downloaded papers `<FirstAuthorSurname><PublicationYear>.pdf`, adding
  `a`, `b`, etc. for collisions; verify existing files before reusing a name.
- Do not commit reference documents. Only `README.md`, `reference.bib`, and
  this `AGENTS.md` are tracked under `ref/`.
