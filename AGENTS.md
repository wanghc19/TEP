# AGENTS.md

## Scope
This repository contains MATLAB code for numerical experiments on periodic waveguides and related eigenvalue problems.

## Always follow
- Do not change the mathematical model unless explicitly requested.
- Preserve function input/output interfaces unless explicitly requested.
- Comments must be in English.
- Use 2-space indentation.
- Prefer local helper functions with `LOCAL_` prefixes.

## Documentation comments
- For every newly created source file, add a clear English header comment block at the top of the file.
- For substantial new MATLAB files, prefer an explicit labeled format such as:
  `% Purpose:`
  `% Main algorithm:`
  `% Based on:`
  `% Main changes:`
  `% Numerical goal:`
- The header should explain:
  1. the purpose of the file,
  2. the main algorithm or workflow,
  3. which earlier file it is based on, if any,
  4. the main differences relative to that earlier file,
  5. the numerical goal, study target, or expected output.
- The header should be specific enough that a reader can understand why the file exists without reading the whole file.
- Avoid overly short or generic descriptions.

- For user-adjustable input parameters near the top of the file, add necessary English comments explaining their meaning and role.
- Document parameters that control geometry, scan intervals, grid sizes, refinement levels, discretization sizes such as `ntot`, and stopping or selection criteria.
- Parameter comments should explain purpose and usage, not merely repeat the variable name.
- When introducing a new parameter, add or update nearby comments so that a reader can understand how to use it.

- For MATLAB `.m` files, place the file header comment block before the main code.

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