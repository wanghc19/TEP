# I7.2 corrected-density endpoint diagnostic

This directory contains the fixed-endpoint Hermitian-part sign-count diagnostic
specified by
[[research/projects/eig-apost/implementation/i7/design-7-2a|design-7-2a]].
The entry point remains

```matlab
[result,evidence] = check_i7_inertia();
```

It evaluates only $k_L=1.753125$ and $k_R=1.75625$. It does not call an I7.1
scanner or locator and does not perform an I7.3 discretization comparison.

## Frozen model and coordinates

The model uses $\beta=0.5$, period $d=1$, radius-$0.2$ circular leads with
`epsrel=17`, and one center ellipse with semiaxes $(0.25,0.16)$ and
`epsrel_center=2`. The spatial tuple is $(256,160,160,80,32)$ and $M=48$.

Both circular and elliptical cells call the public `bloch.construct_S`. That
function applies the square-root quadrature density coordinate internally and
returns physical-density scattering blocks. `check_i7_inertia` does not apply a
second density scaling.

For incoming amplitudes $q=[a^L;b^R]$ and physical traces ordered as
$[d_L;d_R]$, the entry constructs

$$
T=\begin{bmatrix}I+R_L&T_{RL}\\T_{LR}&I+R_R\end{bmatrix},
\qquad
N_0=\begin{bmatrix}
\mathrm{i}G(R_L-I)&\mathrm{i}GT_{RL}\\
\mathrm{i}GT_{LR}&\mathrm{i}G(R_R-I)
\end{bmatrix},
$$

and $L=\operatorname{blkdiag}(\Lambda_-,\Lambda_+)$. The left and right
center normals are respectively $-\partial_x$ and $+\partial_x$. The four
matching blocks are assembled independently, then checked against
$A_{\mathrm{def}}=N_0-LT$ before the right solve
$H=A_{\mathrm{def}}/T$.

The reliability gates remain
$\operatorname{rcond}(T)\ge10^{-8}$ and normalized assembly/right-solve
residuals at most $1000n\epsilon_{\mathrm{mach}}$. With
$H_{\mathrm{sym}}=(H+H^*)/2$, $s=\lVert H_{\mathrm{sym}}\rVert_2$, and
$d_H=\lVert H-H_{\mathrm{sym}}\rVert_2$, the three count bands are

$$
\eta_c=d_H+cn\epsilon_{\mathrm{mach}}\max(1,s),
\qquad c\in\{50,100,200\}.
$$

Equality with a band boundary is unresolved. A stable finite-dimensional
`JUMP` is numerical corroboration only; it is not raw-$H$ inertia, a continuous
root, an eigenvalue certificate, or an error bound.

## Corrected-density rerun

The 2026-09-29 [run-02](output/attempt-1/run-02/) used the unchanged entry,
model, spatial configuration, bands, and endpoints through the corrected public
`bloch.construct_S`. It did not load run-01. The execution, object, spectrum,
partition, and three-band sensitivity gates all passed.

Counts are ordered as $(n_+,n_-,n_{\mathrm{unresolved}})$.

| endpoint | `rcond(T)` | assembly residual | right-solve residual | $s$ | $d_H$ | $\eta_{100}$ | min eig | min abs eig | counts $c=50/100/200$ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| $k_L=1.753125$ | $0.51702058265282613$ | $5.4553954713536217\times10^{-19}$ | $3.7747494080452222\times10^{-19}$ | $604.17561555534041$ | $2.053125626861299\times10^{-13}$ | $2.6027916682723556\times10^{-9}$ | $0.021226887784655889$ | $0.021226887784655889$ | $(194,0,0)$ / $(194,0,0)$ / $(194,0,0)$ |
| $k_R=1.75625$ | $0.5169934488000496$ | $5.7764643426271877\times10^{-19}$ | $2.8012171613030743\times10^{-19}$ | $604.17557925199787$ | $2.1757952844695718\times10^{-13}$ | $2.6028037788554658\times10^{-9}$ | $-0.001880568371886166$ | $0.001880568371886166$ | $(193,1,0)$ / $(193,1,0)$ / $(193,1,0)$ |

Thus $\Delta_-=+1$ and $\Delta_+=-1$, giving the preregistered
`JUMP / SINGLE_JUMP` classification. The same-process audit independently
recomputed $H_{\mathrm{sym}}$, its eigenvalues, counts, and the two matrix
identities; both endpoints passed with zero saved/recomputed Hermitian-part and
eigenvalue defects. See the exact [command](output/attempt-1/run-02/command.txt),
[result](output/attempt-1/run-02/result.json),
[endpoint table](output/attempt-1/run-02/endpoints.csv), and
[audit](output/attempt-1/run-02/audit.json).

The entry runtime was $17.265248375$ s. The hardened monitor reported exit code
0, wall time $28.184776$ s, peak process-tree RSS $1,140,686,848$ bytes, and no
external MATLAB process. No failed scientific run or retry was needed.

The corrected count triples match the historical run-01 triples, but the
matrices and spectra are not the historical objects: corrected $d_H$ is at the
$10^{-13}$ scale and the endpoint eigenvalue margins changed materially. The
current claim therefore rests only on run-02. Corrected-density I7.3
cross-discretization and same-mode evidence remains pending and cannot be
inferred from this two-endpoint rerun.

## Historical pre-density-fix result

The 2026-09-25 [run-01](output/attempt-1/run-01/) used the earlier inconsistent
density-coordinate path. It is retained only as a historical finite-matrix
snapshot. It reported left counts $(194,0,0)$ and right counts $(193,1,0)$ for
all three bands, hence `JUMP / SINGLE_JUMP`. Those values are not current
physical-model evidence and are not runtime inputs to the corrected rerun.

| historical endpoint | $d_H$ | $\eta_{100}$ | min abs eig | counts $c=50/100/200$ |
|---|---:|---:|---:|---|
| $k_L$ | $0.0069403631805661781$ | $0.0069403657831525337$ | $0.010244089942464089$ | $(194,0,0)$ / $(194,0,0)$ / $(194,0,0)$ |
| $k_R$ | $0.006976092528270513$ | $0.0069760951308567125$ | $0.012954744810377465$ | $(193,1,0)$ / $(193,1,0)$ / $(193,1,0)$ |

The exact historical invocation is retained in
[`command.txt`](output/attempt-1/run-01/command.txt). Its entry runtime was
$21.43027775$ s, monitored wall time was $42$ s, and peak process-tree RSS was
$1,107,099,648$ bytes.

## Monitored reproduction

Use a new output directory with the hardened 0.1-second monitor. The monitor
rejects concurrent MATLAB and refuses to overwrite existing monitor output.
The following `run-03` path was unused when this text was written; check that it
is still unused before starting a future repetition.

```bash
cd /Users/whc/Documents/Work/epost
run_dir="$PWD/test/i7/inertia-v1/output/attempt-1/run-03"
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
  I73_WALL_LIMIT_SECONDS=300 I73_RSS_LIMIT_BYTES=2300000000 \
  bash test/i7/refine-v1/run_matlab_monitored.sh "$run_dir" \
  "cd(tempdir); addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i7/inertia-v1'); [result,evidence]=check_i7_inertia(); save(fullfile('$run_dir','result.mat'),'result','evidence','-v7.3'); disp(result);"
```

This invocation reads no historical output or Markdown. Reduce the wall cap if
less than 300 seconds remain in the active shared MATLAB budget.
