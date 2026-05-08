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

- When documenting mathematical logic, operator structure, or matrix assembly, do not rely on prose alone.
- Explicitly include the key mathematical formulas in LaTeX-style notation whenever this helps clarify the implementation.
- In particular, for important kernels, block operators, jump relations, or assembled matrix formulas, prefer writing the defining formula explicitly rather than only describing it in words.

- For MATLAB `.m` files, distinguish between scripts and function files:
  - For MATLAB script files, place the file header comment block before the main executable code.
  - For MATLAB function files, place the function header comment block immediately after the `function ...` signature line, as MATLAB help text.
  - The comment block in a function file must start at column 1, without indentation, even though it is inside the function body.
  - Use the function-name style header when appropriate, for example:
    ```matlab
    function [C, curvelen, xxint, xxext] = construct_cont(ntot, flag_geom, nint, next, varargin)
    % CONSTRUCT_CONT Build the TEP contour and optional interior/exterior points.
    %
    % Purpose:
    %   Constructs the common contour matrix used by the TEP scripts.
    %
    % Input:
    %   ntot      - Number of periodic contour samples.
    %
    % Output:
    %   C         - Contour data array.
    %
    % Notes:
    %   Add implementation notes or compatibility notes here.
    ```
  - Do not place a separate file-level comment block above the `function` line unless there is a special reason, such as licensing or package-level metadata.

## When editing code
- For nontrivial refactors, summarize the plan before coding.
- Keep changes as localized as possible.
- Prefer readable vectorization over clever but opaque rewrites.
- Preserve numerical behavior up to normal floating-point roundoff.

## Validation
- Do not run MATLAB automatically.
- After making code changes, stop and let the user run MATLAB manually for final validation.
- Do not claim MATLAB code was executed unless it actually was.
- Codex may use Octave for rough sanity checks when helpful.
- Prefer non-interactive Octave execution when possible, for example via:
  - `conda run -n octave octave --eval "..."`
  - `conda run -n octave octave script_name.m`
- If interactive Octave is needed, use:
  - `conda activate octave`
  - `octave --no-line-editing`
- When creating substantial new MATLAB `.m` files that include local helper functions, prefer writing them as function files rather than script files, since Octave handles this more reliably.
- In particular, do not rely on script files with trailing local functions for Octave-based validation; use a main function with subfunctions instead.
- Do not rely on Octave GUI features or plotting during validation.
- Treat Octave results only as rough compatibility / sanity checks, not as final numerical validation.

- After edits, report:
  1. what changed
  2. which file/functions were modified
  3. any Octave command(s) that were run and their results
  4. the exact MATLAB command(s) the user should run manually to validate the change
  5. what outcome is expected if the change is correct

- If static inspection or Octave-based checking suggests possible issues, mention them explicitly.

## Output contract
- Modify files in place.
- Do not paste full files back into chat unless explicitly requested.
- Report:
  1. short summary of changes
  2. functions modified
  3. tests/commands run and results