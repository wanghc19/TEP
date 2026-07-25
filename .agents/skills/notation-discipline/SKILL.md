---
name: notation-discipline
description: Keep mathematical notation transparent, necessary, unambiguous, and easy to trace while preserving rigorous, detailed, and preferably elementary reasoning. Use when writing mathematical definitions, propositions, theorems, derivations, or proofs where new notation or intermediate objects may be introduced; when auditing a manuscript for unnecessary symbols, opaque aliases, symbol conflicts, inconsistent semantic typography, differential or imaginary-unit formatting, redundant spaces, operators, or abstraction layers; or when applying a user-approved notation refactor without changing mathematical logic. Trigger for English requests such as "reduce notation", "audit mathematical notation", "check symbol conflicts", "simplify symbols", or "notation refactor", and Chinese requests such as “减少符号”、“检查符号是否必要”、“检查符号冲突”、“审查记号”、“简化数学记号” or “符号重构”.
---

# Notation Discipline

## Purpose

Reduce the reader's symbol-memory burden, unnecessary abstraction layers, and conceptual detours while preserving correctness, rigor, logical completeness, detail, and elementary accessibility.

Optimize:

- unnecessary symbols;
- aliases that merely wrap transparent expressions;
- intermediate objects without independent mathematical meaning;
- frameworks more general than the target requires;
- competing notations for the same object;
- one glyph assigned to incompatible mathematical roles;
- typography that fails to distinguish variables from semantic labels or constants;
- alias chains that force the reader to search backward for definitions.

Do **NOT** optimize proof length as an end in itself. Never remove proof obligations, hypothesis checks, intermediate derivations, or necessary explanations merely to make a proof appear shorter.

## Select the Task Mode

Use exactly one primary mode unless the user explicitly combines them.

1. **Writing mode**: Control notation while drafting or extending definitions, statements, derivations, or proofs.
2. **Audit mode**: Inspect a whole manuscript or a user-specified scope and recommend which symbols to retain, inline, merge, rename, or localize. Do not edit unless the user has also authorized edits.
3. **Refactor mode**: Apply only user-approved notation changes. Preserve mathematical meaning and proof logic, and leave no residue of retired symbols within the authorized scope.

If the mode is ambiguous, default to read-only audit mode. Do not silently proceed from audit to refactor.

## Governing Priorities

Resolve conflicts in this order:

1. mathematical correctness;
2. logical completeness and step-by-step verifiability;
3. precision of hypotheses, quantifiers, dependencies, and conclusions;
4. elementary accessibility and transparency;
5. directness of the mathematical route;
6. minimal notation and abstraction layers;
7. textual brevity.

Never sacrifice a higher priority to improve a lower one. When used with a rigorous proof or citation-verification workflow, preserve every required source check, hypothesis check, and logical step.

## Core Rule: Prefer Transparency to Opaque Brevity

Apply this rule throughout the task:

> Prefer a longer transparent mathematical expression over a shorter opaque alias whenever the alias does not introduce a genuinely new mathematical concept.

For example, if a symbol is defined only as the kernel of an already clearly named operator, has no independent structural role, does not carry a repeatedly used complex constraint, and is not a central object of later results, prefer writing `\ker \mathcal M(k,\beta)` over defining `\mathcal Z_c(k,\beta):=\ker\mathcal M(k,\beta)`.

Do not treat expression length alone as sufficient reason to create an alias. Compare:

- the local reading cost of the expanded expression;
- the long-term memory and lookup cost of the new symbol;
- whether the new name communicates a concept not already visible on the right-hand side.

Prefer expansion when the expression remains clear, structurally informative, and not seriously repetitive.

## Simplicity First: Minimize Detours, Not Proof Detail

Choose the most direct mathematical route that completely proves the exact target. Interpret simplicity as reducing unnecessary intermediate objects, abstraction frameworks, aliases, and generalizations—not mechanically reducing lines or pages.

Before introducing a symbol, space, operator, intermediate proposition, or abstract framework, ask:

1. Would an expert in this area introduce this object to prove this exact result?
2. Does it have independent and stable mathematical meaning, or does it merely rename an existing expression?
3. Would inlining its definition make the proof easier to read without causing harmful repetition?
4. Does it support several later steps, or is it used only once locally?
5. Does it discharge a real proof obligation, or merely restate the problem in different notation?
6. Is the argument being generalized beyond what the current theorem needs?
7. Would removing the symbol expose an operator, constraint, kernel, image, intersection, or quotient that the reader needs to see?

Use the expert question to evaluate the route and the abstraction, **not** the exposition length. A long elementary proof can be simpler than a short proof built from opaque notation and black-box machinery.

## Preserve Useful Detail; Remove Unhelpful Complexity

Preserve or add, when needed:

- exact definitions, domains, and codomains;
- quantifiers, parameter ranges, and dependencies;
- condition-by-condition checks for cited theorems;
- key intermediate equalities, inequalities, and estimates;
- explicit implications from known conclusions to the target;
- elementary derivations required for verification;
- explanations of genuinely confusable spaces, operators, or boundary conditions;
- constraints actually used by the proof.

Challenge or remove:

- one-use symbols for short transparent expressions;
- wrapper definitions with no semantic gain;
- alias chains such as defining `A` by `B` and `B` by `C`;
- auxiliary spaces or operators used once and clearer when expanded;
- generality, parameters, or abstractions not required by the result;
- multiple symbols for the same object;
- abbreviations that hide constraints relevant at the current step;
- helper lemmas that only rename a direct argument and add no reusable content;
- low-value notation whose definition is remote from every use.

## Decide Whether a Symbol Is Necessary

Introduce or retain nonstandard notation only for a concrete positive reason. Valid reasons include:

1. The object has independent, stable mathematical meaning and remains relevant later.
2. The defining expression is long or structurally complex, recurs enough to obstruct reading, and gains clarity from a name.
3. The object is a central domain, codomain, kernel, image, quotient, constraint space, or subject of a main theorem.
4. The notation distinguishes formally similar objects with genuinely different mathematical roles.
5. It is standard, unambiguous notation in the relevant field.
6. The name captures a recurring structure or invariant rather than merely shortening characters.
7. Expansion would obscure the main structure across a multi-step calculation.

The following reasons are insufficient by themselves:

- "the expression is somewhat long";
- "the displayed equation becomes shorter";
- "it may be useful later";
- "mathematical papers normally introduce many symbols";
- "this can be viewed as a new space";
- "giving it a name looks more formal";
- the expression appears only in one or two adjacent lines.

Do not decide by occurrence count alone. Repeated transparent expressions may remain easier to read when expanded because they expose the active constraint. Conversely, a central object may deserve a name even if it appears only a few times.

## Audit Symbol Conflicts and Semantic Typography

Check not only whether a symbol is necessary, but also whether it is unambiguous and typeset according to its semantic role.

### Detect symbol conflicts

For every symbol, record its meaning and scope. Flag a conflict when the same glyph denotes different objects or roles within a scope where a reader could reasonably confuse them. Check the local formula, surrounding argument, section, full manuscript, authorized related files, and parallel language versions as appropriate.

Distinguish:

- **direct conflicts**: the same notation denotes two mathematical objects in overlapping scopes;
- **latent conflicts**: a symbol is reassigned later or elsewhere without a sufficiently clear scope boundary;
- **typographic conflicts**: an italic variable and a semantic label use the same apparent glyph without a stable typographic distinction.

For example, if italic `D` denotes a domain while `D` in `\pi_D` means the Dirichlet label, write the label as `\pi_{\mathrm{D}}`. If two conflicting uses are both genuine mathematical variables, rename one of them; do not rely on a subtle font distinction alone.

### Distinguish semantic classes by typography

Apply these conventions unless the user or a governing style guide specifies otherwise:

- Use mathematical italics for variables, sets, domains, variable indices, and operator-valued variables such as `A`, `T`, or `\mathcal M`.
- Use upright roman type for textual or semantic labels derived from names, properties, boundary-condition types, or classifications, such as `\mathrm{D}` for Dirichlet, `\mathrm{N}` for Neumann, and `\mathrm{out}` for outgoing.
- Use established operator commands such as `\ker`, or `\operatorname{...}` for named operators. Do not mechanically set every operator-valued variable upright.
- Use upright `\mathrm{i}` for the imaginary unit, but retain italic `i` when it is an index or variable.
- Use upright `\mathrm{d}` for a differential, but retain italic `d` when it is an ordinary variable or parameter.

Treat these changes as semantic, not cosmetic. Determine the role from context before changing the glyph.

### Typeset differential spacing by context

In an integral, place a thin space `\,` immediately before the upright differential:

```latex
\int_\Omega f(x)\,\mathrm{d}x
```

Do not include that integral spacing inside a derivative fraction:

```latex
\frac{\mathrm{d}}{\mathrm{d}x},
\qquad
\frac{\mathrm{d}u}{\mathrm{d}x}
```

If defining a global command for the differential glyph, define only the upright glyph, not a leading thin space:

```latex
\newcommand{\diffd}{\mathrm{d}}
```

Add `\,` at each integral call site, for example `\int f(x)\,\diffd x`, while using `\diffd` without that space inside derivative fractions. Never perform a blind replacement of every `d` or `i`; classify each occurrence first.

## Writing Mode

### 1. Fix the target and existing notation

State the exact result being pursued. Inventory standard notation, user-defined objects already in force, their semantic roles and scopes, and notation the user has not authorized changing.

### 2. Write the transparent expression first

At the first appearance of a candidate object, prefer its complete expression. Do not create an abbreviation merely because a formula might become longer.

### 3. Run the necessity test

Apply the criteria above before assigning a new symbol. Keep the expanded form unless a positive reason justifies naming it.

### 4. Check the mathematical route

Require every intermediate space, operator, lemma, and parameter to perform a clear proof function. Remove layers that only restate the problem, serve a single transparent use, or support an unnecessary generalization.

### 5. Complete the detailed reasoning

Retain all necessary definitions, hypothesis checks, intermediate steps, and conclusion bridges. Never interpret fewer symbols as fewer proof steps.

### 6. Re-audit the notation burden

Check whether:

- every new symbol is necessary and defined before use;
- a one-use alias can be inlined;
- a wrapper symbol or alias chain remains;
- parallel notation denotes the same object;
- one glyph denotes incompatible objects or semantic roles;
- variables, semantic labels, the imaginary unit, and differentials use the correct typographic class;
- integral differentials use `\,\mathrm{d}` while derivative fractions contain no integral-only spacing;
- an abbreviation hides a constraint the reader should see;
- removing a symbol makes formulas longer but the argument easier to follow.

## Audit Mode

### 1. Fix the scope

Audit the whole work or the exact chapter, section, theorem, proof, or equation range specified by the user.

### 2. Build a notation inventory

For each nonstandard symbol, record:

- the symbol and exact definition;
- its first definition location;
- its mathematical role;
- its semantic class: variable, set, domain, index, label, named operator, operator-valued variable, constant, differential, or other;
- its scope and approximate use pattern;
- synonymous or near-synonymous notation;
- conflicting uses of the same glyph and visually confusable symbols;
- cross-file, cross-section, or cross-language use.

### 3. Classify each candidate

Assign one recommendation and explain it:

- **Retain**: independent meaning or substantial multi-step clarity;
- **Inline and retire**: an alias for a transparent expression with no semantic gain;
- **Merge**: duplicates another notation without a justified distinction;
- **Rename**: necessary but misleading, conflicting, or nonstandard;
- **Retypeset**: the underlying symbol is appropriate, but its typographic class or contextual spacing is wrong;
- **Localize**: useful only within a local derivation and not as global notation;
- **User decision required**: a real readability tradeoff remains.

Do not call a symbol "unnecessary" without stating the mathematical and readability reasons.

### 4. Produce an exact proposed map

Write every proposed transformation explicitly, for example:

- `\mathcal Z_c(k,\beta)` -> `\ker\mathcal M(k,\beta)`;
- `X_1` and `X_2` -> `X`, together with the reason they denote the same object;
- Dirichlet label `\pi_D` -> `\pi_{\mathrm{D}}`, while an unrelated domain variable `D` remains italic;
- integral `\int f(x)\,dx` -> `\int f(x)\,\mathrm{d}x`, without inserting `\,` into `\frac{\mathrm{d}}{\mathrm{d}x}`;
- global `Y` -> an inline local expression in the stated derivation.

### 5. Stop for confirmation

Do not modify the manuscript. Wait for the user to accept, reject, or amend the recommendations.

## Refactor Mode

Refactoring necessarily changes the selected notation text. Treat the user-approved notation map as the full authorization boundary. Do not combine it with an unrequested proof repair or rewrite.

### 1. Freeze the authorized changes

Record:

- target files and scope;
- approved symbols to inline, retire, merge, rename, or retypeset;
- exact old-to-new mappings;
- theorem statements, proof logic, equation numbers, labels, cross-references, and citations that must remain semantically unchanged.

### 2. Find every dependency

Search for:

- definitions and ordinary uses;
- inline and displayed mathematics;
- subscripted, superscripted, and parameterized variants;
- contextual uses of the same glyph as a variable, label, constant, index, or differential;
- LaTeX macro definitions and invocations;
- theorem, lemma, proof, remark, caption, appendix, and index text;
- grammatical references such as "this space" or "the above operator";
- corresponding uses in other authorized files or language versions.

### 3. Apply a complete, surgical transformation

Change only the approved notation and directly dependent grammar. Adjust parentheses, parameters, scope, quantifiers, operator precedence, semantic font class, and context-dependent spacing as required. Do not rely on blind global text replacement when mathematical scope or semantic role may change.

Do not reorder the argument, strengthen or weaken a result, introduce a replacement abstraction, or rewrite adjacent prose merely for style.

### 4. Verify mathematical invariance

Confirm individually that the refactor preserves:

1. assumptions and parameter ranges;
2. domains and codomains;
3. quantifiers and their scope;
4. theorem conclusions;
5. proof dependencies;
6. equalities, inequalities, and logical implications;
7. cited results and their hypothesis matching;
8. equation labels, cross-references, and citations unless separately authorized.

### 5. Enforce zero residue

Search the full authorized scope for every retired or renamed symbol. Include:

- original LaTeX spellings;
- spacing and brace variants;
- macro forms;
- italic/upright forms and spacing variants;
- subscripted, superscripted, and parameterized forms;
- plain-text names and explanatory prose;
- comments and captions;
- all authorized cross-file and cross-language occurrences.

Require zero old-symbol residue, no undefined new symbols, no naming collision, and no partial replacement.

### 6. Check readability and typesetting

Ensure expanded expressions remain readable and unambiguous. If inlining causes severe repetition, ambiguity, or layout damage, stop extending the change, report the concrete problem, and propose a new compromise. Do not invent another alias without user approval.

## Prohibitions

- NEVER delete proof steps or hypothesis checks in the name of simplicity.
- NEVER use line count, page count, or character count as the primary complexity metric.
- NEVER name every repeated expression automatically.
- NEVER create a global symbol for a one-use, short, transparent expression.
- NEVER generalize beyond the theorem's needs unless the user requests it or the proof genuinely requires it.
- NEVER edit during audit mode without explicit authorization.
- NEVER apply unapproved adjacent rewrites during refactor mode.
- NEVER use blind global replacement when mathematical scope could change.
- NEVER resolve a collision between two genuine variables only by applying a subtle font change; rename one clearly.
- NEVER set every operator-valued variable upright merely because it represents an operator.
- NEVER replace all `d` or `i` mechanically without distinguishing differentials and the imaginary unit from ordinary variables and indices.
- NEVER encode integral-only `\,` spacing inside a global command for the differential glyph.
- NEVER declare a refactor complete before the zero-residue check.
- NEVER prefer a shorter abbreviation merely because it saves characters when it is harder to interpret, locate, or distinguish.

## Coordinate with Rigorous Proof Workflows

When a task also proves or audits a theorem:

1. First establish the exact statement, proof obligations, source requirements, and theorem hypotheses under the rigorous proof workflow.
2. Then use this skill to control the route, notation, and intermediate objects.
3. Preserve every item the rigorous workflow requires the proof to display explicitly.
4. Keep notation that genuinely helps match hypotheses one by one; otherwise write the full condition directly.
5. Prefer a longer direct or elementary proof over a shorter black-box proof when that improves transparency and matches the user's requested level.

Rigor and logical completeness always override notation economy.

## Completion Report

For **writing mode**, report:

- every nonstandard symbol introduced and why it is necessary;
- symbol conflicts and semantic typography decisions made during drafting;
- candidate aliases deliberately left expanded;
- unresolved notation tradeoffs requiring user judgment.

For **audit mode**, report:

- files and scope reviewed;
- retain, inline, merge, rename, retypeset, localize, and user-decision recommendations;
- reasons and exact proposed mappings;
- confirmation that no manuscript edits were made.

For **refactor mode**, report:

- files and scope changed;
- exact mappings applied;
- symbol-conflict and semantic-typography changes applied;
- mathematical-invariance check results;
- zero-residue search scope and result;
- unresolved cross-file, cross-section, or cross-language dependencies;
- any issue that could not be handled safely.

## Final Checklist

Before finishing, confirm that:

- the mathematics remains correct, complete, detailed, and step-by-step verifiable;
- simplicity was not confused with fewer proof steps;
- every retained nonstandard symbol has concrete mathematical or reading value;
- no short opaque wrapper alias remains without justification;
- no unnecessary intermediate object, alias chain, or generalization remains;
- no unresolved symbol conflict remains within the audited scope;
- variables, semantic labels, named constants, and differentials are distinguished by context-appropriate typography;
- every integral differential uses a preceding `\,`, while derivative fractions contain no integral-only spacing;
- a longer transparent expression was not abbreviated merely because it contains more characters;
- audit recommendations and actual modifications stayed strictly separate;
- every applied refactor preserved the statement and proof logic;
- every retired or renamed symbol has zero residue in the authorized scope.
