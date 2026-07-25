# Semantic typography

Use these rules when auditing or changing symbol conflicts, semantic font
classes, imaginary units, differentials, or contextual LaTeX spacing.

## Detect conflicts

Record every symbol's meaning and scope. Flag direct conflicts in overlapping
scopes, latent reassignment without a clear boundary, and typographic conflicts
between visually identical variables and semantic labels. Check the local
formula, surrounding argument, section, manuscript, authorized related files,
and parallel language versions as appropriate.

Rename one of two conflicting genuine variables; do not rely on a subtle font
distinction. For a variable and a semantic label, use typography to expose the
distinction, for example a domain variable `D` versus a Dirichlet label
`\mathrm{D}`.

## Assign semantic classes

Unless a governing style guide says otherwise:

- use mathematical italics for variables, sets, domains, indices, and
  operator-valued variables such as `A`, `T`, or `\mathcal M`;
- use upright roman type for textual labels and classifications such as
  `\mathrm{D}`, `\mathrm{N}`, and `\mathrm{out}`;
- use established operator commands such as `\ker` or `\operatorname{...}` for
  named operators without mechanically uprighting every operator-valued
  variable;
- use `\mathrm{i}` for the imaginary unit and italic `i` for an index or
  variable; and
- use `\mathrm{d}` for a differential and italic `d` for an ordinary variable.

Classify each occurrence from context before changing it.

## Differential spacing

Place a thin space before an upright differential in an integral:

```latex
\int_\Omega f(x)\,\mathrm{d}x
```

Do not insert integral-only spacing into a derivative fraction:

```latex
\frac{\mathrm{d}}{\mathrm{d}x},
\qquad
\frac{\mathrm{d}u}{\mathrm{d}x}
```

If defining a differential macro, define only the glyph:

```latex
\newcommand{\diffd}{\mathrm{d}}
```

Add `\,` at integral call sites and omit it inside derivative fractions. Never
replace every `d` or `i` mechanically.
