# I2.2 endpoint structure diagnostic

## Scope

This experiment reuses the unique I2.1 `eval_i21` evaluator on the normal
MATLAB path. It evaluates only the two preregistered I1.3 L14 shoulder points

$$
k_L=1.8327701568603514,
\qquad
k_R=1.8327705383300779,
$$

after constructing the continuation frame once at
$k_c=1.8327703475952146$. It does not scan for a dip, locate a root, refine a
root, symmetrize a matrix, or compute inertia.

The active entry point preserves the same finite-dimensional construction

$$
T=\begin{bmatrix}I&E\\E&I\end{bmatrix},
\qquad
N_0=\begin{bmatrix}
-\mathrm{i}\Gamma&\mathrm{i}\Gamma E\\
\mathrm{i}\Gamma E&-\mathrm{i}\Gamma
\end{bmatrix},
$$

$$
L=\operatorname{diag}(\Lambda_-,\Lambda_+),
\qquad
H=A/T,
$$

and the same endpoint gates used by the completed I2.2 diagnostic. Because the
exact finite Hermitian identity and whole-interval same-family continuity proof
remain open, positive, negative, and zero inertia counts remain `NaN`, and the
jump remains `UNAVAILABLE`.

## Active source

The experiment now has one MATLAB file:

| File | Role |
|---|---|
| `check_h_struct.m` | Configuration, fixed row selectors, I2.1 evaluator calls, endpoint object construction, numerical gates, compact result, and report |

It depends only on MATLAB, one `eval_i21` resolved from the normal MATLAB path,
and all MATLAB dependencies genuinely required by that evaluator. It does not
locate the repository or read project documentation, Git state, old outputs,
or human-facing metadata.

The next attempt is explicitly named `compact-a1`. From any working directory,
after placing this experiment, `eval_i21`, and its required package functions
on the MATLAB path, the intended command is:

```matlab
check_h_struct('compact-a1');
```

This command has not been run. It will refuse to overwrite an existing
`output/compact-a1/` directory. A completed attempt writes only:

- `result.mat`;
- `report.md`.

Do not launch concurrent processes with the same attempt name. The existing
directory check is the sole overwrite guard.

There is no `check_h_inertia.m`. That separate entry point is reserved for a
future stage that actually computes and outputs endpoint inertia.

## Preserved history

The append-only `output/diag-a1/` and `output/diag-a2/` directories remain
unchanged. They were produced by the former three-file implementation. Exact
copies of that implementation are retained in the ignored directory
`output/pre-refactor-source/`:

- `cfg_i22.m`;
- `eval_i22.m`;
- `run_i22.m`;
- a short history note.

`diag-a1` stopped on an evidence-schema concatenation error before the right
endpoint. `diag-a2` completed both endpoints and then stopped at
`EXACT_HERMITIAN_NOT_ESTABLISHED`, as designed. Its raw endpoint diagnostics
do not establish inertia or a real root.

## Interpretation boundary

A future successful compact attempt can only confirm that the same frozen
fine-$M=48$ evaluator completed both endpoints, the registered pointwise
$A=N_0-LT$ and $A=HT$ identities closed numerically, and the endpoint
invertibility/health gates passed. It cannot turn small Hermitian defects into
an exact Hermitian proof and cannot support a root coordinate, continuous
physical eigenvalue, or posterior eigenvalue-error estimate.
