# Completion reporting

Report at the end of every pass:

1. selected task mode;
2. source file and theorem number or name;
3. target environment type and exact location;
4. output file, if any;
5. work completed in this pass;
6. changes made outside the target environment, if authorized;
7. every new environment, label, and resulting number;
8. each reference used and exact result number;
9. printed and PDF pages for verified book citations;
10. references downloaded during this pass;
11. references absent from local `ref/`;
12. steps still awaiting verification;
13. remaining proof gaps; and
14. preliminary or completed literature status.

If the theorem was supplied only in conversation, write:

```text
Source file: not provided; the theorem was supplied by the user in the current conversation.
```

For each missing reference, also give complete bibliographic information, a
stable accessible URL, why it could not be downloaded, its suggested `ref/`
filename, and the dependent proof steps.

Add the mode-specific information:

- **Review only**: each finding, location, effect, and minimum repair; confirm
  that the proof file was not modified.
- **In-place repair**: integrity-check result and every added or revised `P`,
  `C`, `R`, and `U` block with location and purpose.
- **Complete rewrite**: replaced environment, new proof strategy, confirmation
  that no new proof file was created, and outside-environment diff result.
- **Proof from scratch**: where the proof was written, or confirmation that no
  proof file was written.

Use this minimum structure:

```text
Task mode:
Proof status:
Source file:
Output file:
Theorem number or name:
Target environment and location:
Work completed in this pass:
Authorized changes outside the target environment:
New environments, labels, and numbers:
Original-text integrity check:
Outside-environment diff check:
Insertion blocks added or revised:
Review-only findings:
Verified references:
Verified book pages:
References downloaded in this pass:
References missing locally:
Steps awaiting literature verification:
Remaining proof gaps:
```
