# Writing

The reader is a manager who has to check your work quickly, and through the
manager a researcher who wants to know what is true. Write for them.

## State each result once, at its true strength

Use exactly one of three strengths for every claim:

- **Estimate**: a number computed without a guarantee ("error estimate",
  "the run gives ...").
- **Conditional result**: true if listed conditions hold; list them once,
  next to the claim.
- **Reliable bound / theorem**: proved, with every hypothesis checked.

Say it once, in the place where it belongs. Do not repeat the qualification
in every following sentence. Do not upgrade an estimate into a bound, and do
not downgrade a proved result by hedging it.

## Put the answer first

- Start each report and each section with the result: the number, the
  verdict, the formula.
- Then give the evidence: which file, which check, which source location.
- Then at most one line `Main risk:` per item, naming the single most likely
  way the result could be wrong. Omit it if there is none worth naming.

## Do not write these

- Process logs: what you tried first, in which order, how long it took,
  unless the prompt asks for cost.
- Evidence-level or confidence labels, timestamps, content hashes, git or
  storage narration.
- Chains of negations ("this does not show X, does not imply Y, is not
  automatically Z"). If a limitation matters, state it once as a positive
  sentence: "This holds only for ...".
- Defensive filler: "should be verified", "may need more rigor", "further
  work is required" without saying exactly what.
- Restating the prompt.

## Plain style

- Short sentences, concrete nouns, the same name for the same object.
- Use the notation of the project's notation file; define any new symbol
  where it first appears.
- Tables for numbers that will be compared; prose for reasoning.
- Write in the language the prompt asks for; default to English.

## Over-claiming is the other failure

Plain writing is not a license to claim more. A short report that states an
estimate as a bound, or a partial reproduction as a full one, is worse than
a hedged one. The rule is exactness, not optimism.
