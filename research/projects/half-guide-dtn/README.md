# DtN Half-Guide Research Attempt

This directory contains an isolated research attempt on replacing the current
outgoing trace-subspace / Bloch-trace synthesis formulation by direct
Dirichlet-to-Neumann (DtN) maps for the left and right periodic half-guides.

All files produced by this attempt are kept inside `attempt/`. Existing package
code outside this directory is read-only for this study until a final feasibility
recommendation is mature enough to propose package changes.

## Directory Map

- `STATUS.md`: persistent state, completed work, current conclusions, and risks.
- `next-steps.md`: concrete recovery instructions and next commands/tasks.
- `DECISIONS.md`: assumptions, design choices, and alternatives.
- `literature/`: literature review notes and source URLs.
- `theory/`: derivations, code inventory, and formulation comparisons.
- `prototype/`: standalone MATLAB/Octave prototypes for DtN experiments.
- `experiments/`: numerical outputs, logs, figures, and summaries.
- `report/`: final LaTeX feasibility report and bibliography.
- `logs/`: command logs and environment notes.

## Current Scope

The first phase focuses on:

1. inventorying the current TEP/Bloch-trace implementation;
2. reviewing the Joly/Coatleven DtN strategy at a level sufficient to avoid
   sign and ordering mistakes;
3. deriving a minimal homogeneous-lead DtN validation problem;
4. implementing an independent prototype that checks Riccati and invariant
   subspace constructions against the analytic homogeneous DtN.

Later phases should add periodic-obstacle lead DtN blocks, coupling to the
central Muller BIE, and comparison with the existing trace-matching scans.
