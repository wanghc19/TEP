# Red-team scope

The user's independent adversarial-verification task explicitly selects this
directory instead of the root default `test/` location. All new analyses,
programs, downloads, temporary extracts, parameters, logs and results stay here.
Read the repository root, research and test guidance. Existing research,
experiments, manuscripts, references and Claude files are read-only.

- Work in `/Users/whc/Documents/Work/epost`, branch `codex/epost`.
- Do not commit, change branches, or edit `main` or existing files outside here.
- Each complete scientific run: estimate time and memory first; planned limit
  30 minutes, hard limit 40 minutes, peak memory 2 GiB. Use short serial runs
  first, monitor subprocess memory, retain failed operational logs in the same
  attempt. Do not run numerical work concurrently without coordination.
- Every case states its mathematical suspicion, expected observable,
  falsification criterion, implementation dependencies and resource estimate
  before execution. Existing code reuse must be explicit; it is not independent
  implementation evidence.
- Classifications: CONFIRMED, CONDITIONAL, SUSPECTED, RESOLVED, OPEN. A confirmed
  method failure requires proof or a reproducible counterexample. A toy-model
  failure only refutes the inference it tests, not the production candidate.
- Distinguish numerical support from proof and k from mu = k^2; preserve source
  field identity, all declared conditions, and original output status.
- MATLAB entries accept numerical inputs and paths explicitly, never read
  documentation or Git metadata to authorize or configure numerical execution.
- Use English source comments and 2-space indentation. Use `$...$` and
  `$$...$$` in Markdown mathematics. Do not display content hashes in prose.

The root agent owns README, baseline snapshot, shared findings ledger, exact
mechanism cases and final decision. Other file ownership is assigned explicitly.
