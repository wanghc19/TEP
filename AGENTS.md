# AGENTS.md

## Scope

This repository contains MATLAB code and research material for numerical
experiments on periodic waveguides and related eigenvalue problems.

## Directory-specific guidance

- Before working on files under `research/`, read and follow
  `research/AGENTS.md` in addition to this file.
- The nested file governs research authority, notation, naming, temporary
  material, and handoff rules; this root file continues to apply everywhere.

## Always follow

- Do not change the mathematical model unless explicitly requested.
- Preserve function input/output interfaces unless explicitly requested.
- Write comments in English and use 2-space indentation.
- Prefer local helper functions with `LOCAL_` prefixes.
- For theorem proofs or proof audits, use `$rigorous-theorem-proof` unless the
  user explicitly opts out.

## MATLAB source documentation

- Give every new source file a clear English header explaining its purpose and
  workflow. For substantial MATLAB files, also state the earlier file it is
  based on, the main differences, and the numerical goal or expected output.
- For substantial MATLAB files, use these labels when applicable:
  - `% Purpose:`
  - `% Main algorithm:`
  - `% Based on:`
  - `% Main changes:`
  - `% Numerical goal:`
- In scripts, put the header before executable code. In function files, put
  MATLAB help text immediately after the `function` signature, starting in
  column 1; do not add a separate file header above the signature unless needed
  for licensing or package metadata.
- For substantial function files, prefer labeled help sections such as
  `Purpose`, `Input`, `Output`, `Main algorithm`, and `Notes` as appropriate.
- Explain user-adjustable parameters near their definitions, especially
  geometry, scan intervals, grid sizes, refinement levels, discretization sizes
  such as `ntot`, and stopping or selection criteria.
- In scripts or tests with several logical stages, add short comments in the
  form `% --- stage N: brief description ---` before major blocks.
- Group numerous `LOCAL_` helpers by role. Start each group with a marker in the
  exact form `%% ==================== Role name ====================`, followed
  by one English sentence describing the group.
- When documenting mathematical logic, kernels, jump relations, block
  operators, or matrix assembly, include the defining LaTeX-style formulas when
  they materially improve clarity.

## When editing code

- For nontrivial refactors, summarize the plan before coding.
- Keep changes localized and preserve numerical behavior up to ordinary
  floating-point roundoff.
- Prefer readable vectorization over clever but opaque rewrites.

## LaTeX temporary files

* Clean LaTeX build artifacts only by running `latexmk -c` in the corresponding LaTeX project directory, or by passing the relevant main `.tex` file explicitly.
* Do not use `rm`, recursive deletion, broad globs, or manually maintained extension lists for routine LaTeX cleanup.
* Do not use `latexmk -C` unless the user explicitly requests removal of generated PDFs and other primary outputs.
* Never delete LaTeX sources, bibliography files, styles, classes, figures, data, or other project assets as part of cleanup.
* If the relevant LaTeX project or main file cannot be identified reliably, do not clean anything; report the ambiguity instead.

## Validation

- Do not run MATLAB automatically. Let the user perform final MATLAB validation,
  and never claim MATLAB was run unless it actually was.
- Codex may use Octave for rough sanity checks. Prefer non-interactive commands
  such as `conda run -n octave octave --eval "..."` or
  `conda run -n octave octave script_name.m`.
- If interactive Octave is necessary, use `conda activate octave` followed by
  `octave --no-line-editing`.
- For substantial new MATLAB files with local helpers, prefer function files
  with subfunctions; do not rely on script files with trailing local functions
  for Octave validation.
- Do not rely on Octave GUI features or plotting. Treat Octave results only as
  compatibility and sanity checks, not final numerical validation.
- After code edits, report what changed, the files/functions modified, Octave
  commands and results, exact MATLAB commands for manual validation, and the
  expected successful outcome.
- Report any possible issues found by static inspection or Octave.

## Output contract

- Modify files in place and do not paste complete files into chat unless asked.
- Report a short change summary, modified files/functions, and checks run with
  their results.
