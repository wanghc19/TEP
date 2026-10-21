# I5 residual numerator v8: real-interpolation bridge

This version instantiates the governing direct bridge in
`s-lift-real-interpolation.md`, (RI-5)--(RI-18), on the frozen circle data.
The MATLAB entry points read only two explicit scientific inputs: the frozen I3
artifact and the accepted circle contract. They do not read Git metadata,
Markdown, manifests, or historical experiment output, and they perform no
eigenpair, BIE-density, QZ, or propagation-matrix solve.

## Method and ownership

The source-size schedule is pre-registered as $N\in\{514,1026\}$ with even
$N>2M_\eta$. Selection uses only the complete $q=0$ node-ball radius (local
source Kress plus kernel-series radii, regular source quadrature plus
$M_R/M_I/M_T/M_L$, and the zero off-surface source radius authorized by exact
finite Rayleigh support). The first radius at most $10^{-3}$ is selected; if no
candidate meets that allocation, the last analytic candidate is retained and
the tightness gate is false. Candidate centres are never evaluated and no
inter-level drift is used.

The selected $N$ is also the real-node interpolation partition; there is no
second target-panel or target-FFT selector.  The $q=1$ condition is an analytic
admissibility gate, not a selection radius: the code takes $d_j=0$ and encloses
the complete first arclength derivative by $r'_j=L_A$.  The post-freeze
interpolation radius and block-power tail are persisted against a pre-registered
tightness allocation.  A failed performance allocation sets
`route_upgrade_required` but does not invalidate the finite conditional
majorant.

After selection, the code evaluates one physical signed value row at the real
nodes,

$$
c_j=A_{\mathrm{local}}(s_j)+A_{\mathrm{regular}}(s_j)
  +A_{\mathrm{off}}(s_j),
$$

before any state-map norm. There is no material target FFT, target alias
radius, Fourier cutoff, or Fourier tail in the active path. The $q=1$ data are
not part of source selection: the derivative centre is $d_j=0$ and its radius
is the complete exact-action triangle bound
$L_A=L_{\mathrm{local}}+L_{\mathrm{regular}}+L_{\mathrm{off}}$.

The periodic piecewise-linear bridge stores $Q_0,Q_1,R_0,R_1$, where $R_0$
and $R_1$ are already squared error integrals, and forms
$H=a_0Q_0+a_1Q_1$ and $R=(a_0R_0+a_1R_1)^{1/2}$. Finite side states use
$G_\pm P_\pm^n c_\pm$ with $G_\pm$ exactly once. The block tail uses
$G_\pm^*HG_\pm$ and $R\lVert G_\pm\rVert_2$, again exactly once. The accepted
material-normal, wall-normal, and closed-wall lifting scalars are explicit
source constants in the v8 source; no old result is loaded at runtime. Their
contract is bound automatically to the exact frozen artifact and curve bytes,
the frozen physical parameters, and the collar geometry. The builder and
evaluator both require pairwise-disjoint material/wall comparison collars and
periodic copies, zero comparison rims, and the broken-energy direct sum before
using factor one.

All ordinary finite and special-function evaluations remain labelled
`UNRESOLVED`. A finite output is therefore a conditional ideal majorant, not an
outward-rounded or fully reliable enclosure.

## Files and explicit interface

- `build_residual_numerator_input_v8(artifact_path, curve_contract_path, input_path)`
- `residual_numerator_v8(input_path, result_path)`
- `signed_local_center_v8.m`, `signed_regular_image_v8.m`, and
  `signed_off_surface_v8.m` are self-contained experiment helpers.
- `run_residual_numerator_v8.sh` accepts nine explicit absolute paths:
  repository root, experiment directory, artifact, curve contract, generated
  input, result, run log, resource log, and audit log.

The intended first-run targets are create-once files such as
`input/residual-numerator-v8-input-run-01.mat` and
`output/attempt-1/{result-run-01.mat,run-01-log.txt,resource-run-01.txt,audit-run-01.txt}`.
Operational repairs must use new `run-02` filenames in the same attempt.

## Resource and run contract

The planned complete run is at most 30 minutes and 1.8 GiB. The launcher stops
the exact MATLAB process tree at 2395 seconds or 2 GiB RSS, whichever occurs
first. It writes all generated files only to the explicit targets, checks every
target for create-once semantics before launch, runs MATLAB Code Analyzer, and
records MATLAB output, `/usr/bin/time -l`, watchdog RSS, and an audit diary.
The canonical launch is:

```sh
test/i5/residual-numerator-v8/run_residual_numerator_v8.sh \
  /absolute/path/to/epost \
  /absolute/path/to/epost/test/i5/residual-numerator-v8 \
  /absolute/path/to/frozen-artifact.mat \
  /absolute/path/to/circle-contract.mat \
  /absolute/path/to/epost/test/i5/residual-numerator-v8/input/residual-numerator-v8-input-run-01.mat \
  /absolute/path/to/epost/test/i5/residual-numerator-v8/output/attempt-1/result-run-01.mat \
  /absolute/path/to/epost/test/i5/residual-numerator-v8/output/attempt-1/run-01-log.txt \
  /absolute/path/to/epost/test/i5/residual-numerator-v8/output/attempt-1/resource-run-01.txt \
  /absolute/path/to/epost/test/i5/residual-numerator-v8/output/attempt-1/audit-run-01.txt
```

Do not launch until the independent pre-run review returns `GO`.

## Attempt-1 canonical result

Runs 01--03 were create-once operational diagnostics; they failed before
creating a scientific input or result. Run-04 is the first completed canonical
evaluation. It selected $N=514$ from the pre-registered source-radius schedule,
with maximum node radius $6.0278441945300462\times10^{-6}$. All builder and
evaluator reliability gates passed, while $\Delta_{\mathrm{sf}}$ and
$\Delta_{\mathrm{fp}}$ remain `UNRESOLVED`.

The interpolation bridge produced

$$
R_0=2.642100809251934,
\qquad
R_1=3315231.5072913063,
\qquad
R=744.24301691330515.
$$

The resulting conditional ideal values are

$$
\widehat B_{\Gamma_\pm}=1.8732040521480924\times10^{-10},
\quad
\widehat B_\Upsilon=5.974138564715684\times10^{-7},
$$

$$
\widehat B_{\mathrm{lift}}=1268.5132354323696,
\qquad
\mathcal M_{\mathrm{ideal}}=1268.5132360299708.
$$

The lifting energy squares are

$$
E_{\mathrm{mat,fin}}=1609125.8284670974,
\quad
E_{\mathrm{mat,cell}}=6.0667993516236794\times10^{-10},
\quad
E_{\mathrm{wall}}=5.9767862107677079\times10^{-30}.
$$

The width is dominated by the global zero-centred derivative radius
$L_A=1624.2467206052913$, not by material Fourier omission (which is absent),
the cell tail, or the wall term. Increasing $N$ does not remove this floor.
The shortest useful next route is a signed nonzero derivative-centre/panel-ball
certificate; ordinary source-grid refinement is not recommended.

Run-04 took 15.01 seconds with maximum RSS 964214784 bytes. The process-tree
watchdog recorded 17 seconds and 1076960 KiB. Exact executed-source identities
are stored in `output/attempt-1/source-run-04.txt`.
