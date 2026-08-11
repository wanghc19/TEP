# Pre-Same-Backend Proxy Solver Summary

This preserves the final summary immediately before the Skeptic's decisive
same-backend correction. It is superseded and must not be used as the active
causal classification.

- Earlier decision: `CUTOFF_CAUSAL_AND_CLOSED`
- Runtime: `6.6841368675` seconds
- Manual tau: `3e-16`
- Earlier default ranks high/higher: `185/214`
- Earlier restored-direction count: `40`
- Default point error: `4.5181876388e-08`
- Selected point error: `3.9495213948e-12`
- Selected improvement: `1.1439835836e+04`

The superseded runner used `max(size(A))*eps(s1)` for the default cutoff.
The corrected runner uses Octave's documented
`max(size(A))*norm(A)*eps`, evaluates explicit same-backend pseudoinverses,
and requires that evidence before assigning a causal label.
