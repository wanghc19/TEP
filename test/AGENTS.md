# Test Directory Guidelines

- This directory is for experimental implementations and numerical validation.
- Each experiment must have its own subdirectory.
- The active experiment directory is the only writable location by default.
- Keep generated files, figures, logs, and reports inside the corresponding experiment folder.
- Experimental code must not modify files outside its own experiment directory unless explicitly requested.
- Do not modify existing packages or main project code during experiments unless explicitly requested.
- Promote only validated results to the main research documentation.

## MATLAB runtime portability

- Any MATLAB entry point that is actually run must depend only on MATLAB itself and the
MATLAB source files that are genuinely required for the numerical computation.
- Executable MATLAB code must not read, parse, hash, validate, or require any human-facing
Markdown file, design or review document, README, status file, freeze file, manifest, Git
metadata, generated report, historical output, or other non-code artifact in order to run.
- Do not make execution conditional on repository-relative paths, absolute paths,
directory depth, filenames recorded in documentation,
or a particular layout under `test/`.  If an
experiment directory and its required MATLAB/package functions are moved together and
placed on the MATLAB path, the experiment must still run without source edits.
- Resolve MATLAB dependencies through normal MATLAB function resolution.  A launcher may
add the experiment directory or required package roots to the MATLAB path, but numerical code must not discover a repository root, reconstruct sibling paths, or require the original worktree layout.
- Scientific parameters and necessary runtime configuration must live in MATLAB source or
be supplied as explicit function inputs.  Documentation and provenance may describe a run,
but they must never control or authorize execution.
- Untracked SHA-256 files may be retained as optional machine-side provenance.
MATLAB execution must not depend on them, and human-facing documentation must not display
SHA-256 values or other content hashes.
