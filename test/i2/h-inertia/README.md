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
$k_c=1.8327703475952146$. It does not scan for a dip, locate a root, or refine
a root. The current follow-up explicitly forms
$H_{\mathrm{sym}}=(H+H^*)/2$ and counts its endpoint signs as numerical
corroboration only; it does not alter the raw matrix or define raw-$H$ inertia.

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

and the same endpoint gates used by the completed I2.2 diagnostic. The raw
matrix remains non-Hermitian, so its mathematical inertia remains unavailable.
The current experiment counts only the signs of its Hermitian part and labels
that result as corroboration.

## Active source

The experiment now has two focused MATLAB entry points:

| File | Role |
|---|---|
| `check_h_struct.m` | Configuration, fixed row selectors, I2.1 evaluator calls, endpoint object construction, numerical gates, compact result, and report |
| `check_h_inertia.m` | Standalone endpoint evaluator, $H_{\mathrm{sym}}$ construction, operator-norm unresolved-band check, and sign-count report |

It depends only on MATLAB, one `eval_i21` resolved from the normal MATLAB path,
and all MATLAB dependencies genuinely required by that evaluator. It does not
locate the repository or read project documentation, Git state, old outputs,
or human-facing metadata.

The optional structure-only attempt is explicitly named `compact-a1`. From any working directory,
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

The completed frozen follow-up attempt is explicitly named `inertia-a1`:

```matlab
check_h_inertia('inertia-a1');
```

It writes only `result.mat` and `report.md` under a new
`output/inertia-a1/`. The schema separates unavailable raw-$H$ inertia from
the available `HERMITIAN_PART_SIGN_COUNT`; `JUMP`, `NO_JUMP`, and
`UNRESOLVED` are all acceptable outcomes. Do not launch concurrent processes
with the same tag. A failure before final output publication may leave no local
artifact; it must be reported from the command output and must not trigger an
automatic retry with the same tag.

The one authorized attempt completed without retry in `20.0001 s`, with an
active-object snapshot peak of `63.4584 MiB`. The Hermitian-part counts were
`(194,0,0)` at $k_L$ and `(193,1,0)` at $k_R$, so
$\Delta_-=+1$, $\Delta_+=-1$ and the preregistered result is
`JUMP / SINGLE_JUMP`. The $50/100/200$ band-sensitivity triples were identical.
This is the completed current attempt; do not reuse the tag.

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

A successful `inertia-a1` can only report whether the Hermitian-part sign count
shows `JUMP`, `NO_JUMP`, or `UNRESOLVED` at the two frozen endpoints after the
same object and factor gates pass. It cannot turn small Hermitian defects into
an exact raw-$H$ inertia proof and cannot support a root coordinate, continuous
physical eigenvalue, or posterior eigenvalue-error estimate.
