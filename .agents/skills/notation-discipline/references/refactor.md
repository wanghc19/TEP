# Refactor mode

Apply only a user-approved notation map. Do not combine it with an unrequested
proof repair or rewrite.

## Freeze authorization

Record target files and scope, exact old-to-new mappings, and the statements,
proof logic, equation numbers, labels, cross-references, and citations that must
remain semantically unchanged.

## Find dependencies

Search definitions and uses; subscripted, superscripted, and parameterized
forms; macro definitions and invocations; contextual uses of the same glyph;
theorems, proofs, remarks, captions, appendices, indexes, comments, and prose;
and authorized related files or language versions.

## Transform surgically

Change only approved notation and directly dependent grammar, parentheses,
parameters, scope, quantifiers, operator precedence, semantic font class, and
contextual spacing. Never use blind replacement where one spelling has multiple
mathematical roles.

Do not reorder arguments, alter assumptions or conclusions, introduce a new
abstraction, or rewrite adjacent prose for style.

## Verify invariance

Check assumptions, parameter ranges, domains, codomains, quantifiers, theorem
conclusions, proof dependencies, equalities, inequalities, implications, cited
results, equation labels, cross-references, and citations individually.

## Require zero residue

Search the full authorized scope for old LaTeX spellings, brace and spacing
variants, macro and font forms, parameterized forms, plain-text names, comments,
captions, and cross-language occurrences. Require zero retired-symbol residue,
no undefined replacement, no collision, and no partial replacement.

If inlining causes serious repetition, ambiguity, or layout damage, stop and
propose a compromise. Do not invent a replacement alias without approval.

## Completion report

Report changed scope, exact mappings, conflict and typography changes,
mathematical-invariance results, zero-residue search and result, unresolved
dependencies, and anything that could not be changed safely.
