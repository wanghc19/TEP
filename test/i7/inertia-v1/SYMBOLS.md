# I7.2 endpoint-diagnostic symbol ledger

Shared I7 geometry, channel, QZ, DtN, and batched-kernel names retain the
meanings recorded in `../scan-v1/SYMBOLS.md`. The additions below implement
`research/projects/eig-apost/implementation/i7/design-7-2a.md`; ordinary loop
indices, timers, path strings, and formatting values are omitted.

| Code name | Kind and scope | Source and meaning | Type and shape | Defined / consumed |
|---|---|---|---|---|
| `kvals`, `labels` | endpoint constants | Design section 1: fixed left/right endpoints $1.753125$ and $1.75625$ | real $1\times2$ and cell $1\times2$ | entry / `LOCAL_endpoint` |
| `model`, `cfg`, `M` | frozen inputs | Design section 1: I7 center-ellipse model, fine tuple $(256,160,160,80,32)$, and $M=48$ | scalar structs and integer | entry / constructors |
| `q` | mathematical amplitude order | Design section 2: $q=[a^L;b^R]$ | complex $2K$ column | implicit input to `T`, `N0`, `Adef` |
| `T` | trace matrix | Design section 2: maps $q$ to $d=[d_L;d_R]$ | complex $2K\times2K$ | `LOCAL_endpoint` / `H` and evidence |
| `N0` | center-normal matrix | Design section 2: maps $q$ to center-outward $n=[n_L;n_R]$ with normals $[-\partial_x;+\partial_x]$ | complex $2K\times2K$ | `LOCAL_endpoint` / identity diagnostic |
| `L` | exterior DtN block | Design section 2: $\operatorname{blkdiag}(\Lambda_-,\Lambda_+)$ | complex $2K\times2K$ | `LOCAL_endpoint` / identity diagnostic |
| `Adef` | matching matrix | Design section 3: independently assembled residual matrix for $n-Ld$ | complex $2K\times2K$ | `LOCAL_endpoint` / `H` and evidence |
| `H` | raw trace operator | Design section 3: right solve $H=A_{\mathrm{def}}/T$ | complex $2K\times2K$ | `LOCAL_endpoint` / `Hsym` and evidence |
| `Hsym` | Hermitian surrogate | Design section 4: $(H+H^*)/2$ | Hermitian $2K\times2K$ | `LOCAL_endpoint` / eigensolver and evidence |
| `assembly_error` | reliability scalar | Design section 3: normalized $\|A_{\mathrm{def}}-(N_0-LT)\|_F$ residual | nonnegative real scalar | `LOCAL_endpoint` / object gate and result |
| `solve_error` | reliability scalar | Design section 3: normalized $\|A_{\mathrm{def}}-HT\|_F$ residual | nonnegative real scalar | `LOCAL_endpoint` / object gate and result |
| `scale_2`, `distance_2` | band scalars | Design section 4: $s=\|H_{\mathrm{sym}}\|_2$ and $d_H=\|H-H_{\mathrm{sym}}\|_2$ | nonnegative real scalars | `LOCAL_endpoint` / uncertainty bands |
| `multipliers`, `eta` | count bands | Design section 4: $c=(50,100,200)$ and $\eta_c=d_H+c n\epsilon\max(1,s)$ | real $1\times3$ rows | `LOCAL_endpoint` / sign counts and evidence |
| `eigenvalues`, `counts` | surrogate spectrum data | Design section 4: eigenvalues of `Hsym` and $(+,-,?)$ counts for each band | real $2K$ column and integer $3\times3$ | `LOCAL_endpoint` / result and evidence |
| `object_gate`, `diagnostic_pass`, `diagnostic_reason` | endpoint status | Design sections 3 and 5: reliability tests and first failed test | logical scalars and char | `LOCAL_endpoint` / scientific outcome |
| `delta_negative`, `delta_positive` | endpoint differences | Design section 4: right count minus left count in the main $c=100$ band | integer scalars | entry / jump classification |
| `scientific_outcome`, `jump_kind` | interpretation | Design section 4: `JUMP`, `NO_JUMP`, or `UNRESOLVED`, separate from execution | char | entry / `result` |
| `result`, `evidence` | returned artifacts | Design section 5: compact status versus full matrices/eigenvalues required by the I7.2 output contract | scalar structs | entry / batch caller files |
