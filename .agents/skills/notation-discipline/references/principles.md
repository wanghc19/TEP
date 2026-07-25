# Notation principles

Apply these principles in every mode.

## Prefer transparency

Prefer a transparent expression to an opaque alias when the alias adds no new
concept. Compare the local cost of the expanded expression with the long-term
memory and lookup cost of the symbol. Favor expansion when it remains clear and
exposes the active operator, kernel, image, constraint, intersection, or
quotient.

Do not use expression length or occurrence count alone. Retain or introduce a
nonstandard symbol only for a positive reason:

1. stable independent mathematical meaning;
2. a long or complex recurring expression that obstructs reading;
3. a central domain, codomain, kernel, image, quotient, constraint space, or
   theorem subject;
4. a necessary distinction between genuine mathematical roles;
5. standard and unambiguous field notation;
6. a recurring structure or invariant; or
7. clearer structure across a multi-step calculation.

Insufficient reasons include a shorter display, speculative future usefulness,
formality, customary symbol proliferation, or one or two adjacent uses.

## Minimize detours, not detail

Require every introduced symbol, space, operator, lemma, parameter, and abstract
framework to perform a clear function in the exact argument. Challenge one-use
wrappers, alias chains, unnecessary generality, duplicate notation, remote
definitions, and helpers that only rename a direct argument.

Preserve exact definitions, domains, codomains, quantifiers, parameter ranges,
source-hypothesis checks, intermediate estimates, conclusion bridges, and all
reasoning needed for verification.

Before introducing an object, ask:

1. Does it have stable mathematical meaning?
2. Would inlining improve readability without harmful repetition?
3. Does it support several later steps?
4. Does it discharge a real proof obligation?
5. Is the argument being generalized beyond the target?
6. Would removal expose useful mathematical structure?

A long elementary proof may be simpler than a short proof built from opaque
notation or black-box machinery.
