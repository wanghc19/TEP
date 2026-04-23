# AGENTS.md

## Scope
This repository contains MATLAB code for numerical experiments on periodic waveguides and related eigenvalue problems.

## Always follow
- Do not change the mathematical model unless explicitly requested.
- Preserve function input/output interfaces unless explicitly requested.
- Comments must be in English.
- Use 2-space indentation.
- Prefer local helper functions with `LOCAL_` prefixes.

## File headers
- For every newly created source file, add a brief header comment at the top stating what the file does.
- The header comment should be concise and written in English.

## When editing code
- For nontrivial refactors, summarize the plan before coding.
- Keep changes as localized as possible.
- Prefer readable vectorization over clever but opaque rewrites.
- Preserve numerical behavior up to normal floating-point roundoff.

## Validation
- Do not run MATLAB automatically.
- After making code changes, stop and let the user run MATLAB manually.
- Do not claim the code was executed unless it actually was.
- Instead, report:
  1. what changed
  2. which file/functions were modified
  3. the exact MATLAB command(s) the user should run manually to validate the change
  4. what outcome is expected if the change is correct
- If static inspection suggests possible issues, mention them explicitly.

## Output contract
- Modify files in place.
- Do not paste full files back into chat unless explicitly requested.
- Report:
  1. short summary of changes
  2. functions modified
  3. tests/commands run and results