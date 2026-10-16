# I8.3 frozen-field estimate

`estimate_i8.m` independently reconstructs one equal-area star-center field at
$k_0=1.7562818500073463$. It does not call the I8 scan or read an earlier
result. The baseline uses $(N,M)=(256,48)$ with the fixed
$(160,160,80,32)$ proxy tuple. The optional authorized comparison changes only
$N$ to 384.

The center density and both lead propagation coordinates are frozen once per
run. The same physical field is then evaluated on the two non-native boundary
grids $N_e=512,768$. Each level includes the center material jump, 40 lead
cells on each side plus an observed geometric-tail candidate, the two
center-lead walls, 40 internal walls on each side plus their observed tail,
and the disk mass. The disk grids are $16\times32$ without angular shift and
$32\times64$ with a half-step angular shift.

For each level the code forms

$$
\epsilon_{\rm num}
=\sqrt{E_n+d^{-2}E_v},\qquad
D_{\rm num}=U_{\rm num}-C_{\rm num}\epsilon_{\rm num},
$$

and, only when all numerical components and gates are available and
$D_{\rm num}>0$,

$$
R_{\rm num}
=\frac{2\mu_{\rm num}C_{\rm num}\epsilon_{\rm num}}{D_{\rm num}}.
$$

Here $\mu_{\rm num}$ is the ordinary-double product `k0*k0`. None of these
quantities is a certified spectral bound.

## Results

The primary baseline is `output/attempt-1/run-01`. The independently audited
saved matrices are in `run-02`. The authorized $N=384$ comparison is separate
in `run-03`; it does not replace the baseline.

| field solve | $N_e$ | $\epsilon_{\rm num}$ | $U_{\rm num}$ | denominator | $R_{\rm num}$ |
|---|---:|---:|---:|---:|---:|
| $N=256$ | 512 | 2.4810755427659055e-7 | 0.11608305829685453 | 0.11608100556767394 | 1.0909099843762415e-4 |
| $N=256$ | 768 | 2.4810755428251100e-7 | 0.11608305827964590 | 0.11608100555046526 | 1.0909099845639975e-4 |
| $N=384$ | 512 | 5.7169987099404970e-10 | 0.11608305829685364 | 0.11608305356686865 | 2.5136763609586296e-7 |
| $N=384$ | 768 | 5.7170281120679010e-10 | 0.11608305827964505 | 0.11608305354963573 | 2.5136892889947825e-7 |

Both runs use `mu_num=3.0845259366652269` and
`Cnum=8.273545666859006`. Their numerical reference intervals
$[\mu_{\rm num}-R_{\rm num},\mu_{\rm num}+R_{\rm num}]$ are
$[3.0844168456667704,3.0846350276636834]$ for $N=256$ and
$[3.0845256852962981,3.0845261880341557]$ for $N=384$. These intervals
inherit the uncertified status of $R_{\rm num}$.

The 512-to-768 relative changes in $R_{\rm num}$ are
$1.7211\times10^{-10}$ for $N=256$ and $5.1431\times10^{-6}$ for $N=384$.
These are two-grid observations, not error bounds. Re-solving at $N=384$
reduces the fine-grid $\epsilon_{\rm num}$ and $R_{\rm num}$ by factors of
about 434.0 while the mass changes by only $7.4\times10^{-15}$ relatively.
The result therefore has strong field-discretization sensitivity and does not
establish spatial convergence.

The four matching metrics at the same fixed $k_0$ are:

| field solve | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| $N=256$ | 9.0463849720091667e-14 | 1.4973105978156506e-16 | 4.3645331331577957e-14 | 1.5283249311405522e-14 |
| $N=384$ | 9.3568050265877250e-14 | 1.5486897110120407e-16 | 4.5737927708008503e-14 | 1.6016012041195884e-14 |

Fine-grid squared component pairs are:

| component | $N=256$: value / normal | $N=384$: value / normal |
|---|---:|---:|
| center material | 8.487355401908733e-29 / 6.155735849152025e-14 | 1.4159039714954695e-29 / 3.268435710697176e-19 |
| lead finite | 2.135715043803062e-30 / 1.805340249013551e-28 | 2.001566116342210e-30 / 1.973303509841985e-28 |
| lead tail candidate | 4.891051748465424e-72 / 4.136897086358085e-70 | 4.586484274539881e-72 / 4.524926188643061e-70 |
| center-lead walls | 1.374371550348341e-27 / 4.751944651965787e-25 | 1.812867051382246e-27 / 4.804353073019892e-25 |
| internal walls | 1.858317227955461e-27 / 5.020132169364636e-26 | 1.875586883978836e-27 / 4.893477696602319e-26 |
| wall tail candidate | 4.236492206828154e-69 / 1.147882950906250e-67 | 4.288009212386928e-69 / 1.118856572548725e-67 |
| total | 3.319698047366693e-27 / 6.155735849204582e-14 | 3.704614541192380e-27 / 3.268441006371322e-19 |

The lead value/normal tail ratios are about 0.09104 and the wall ratios are
about 0.0908--0.0910 at both field orders. Those tails are observed geometric
candidates and are not certified one-sided bounds. Some individually tiny
lead/wall normal terms change by 17--36% between evaluation grids; the small
total-grid changes must not be read as uniform relative convergence of every
component.

## Audits and resources

The internal audit passed; its saved baseline maximum defect was
$2.5317114522742139\times10^{-13}$. The separate Skeptic audit recomposed the saved matching,
density, propagation, material, wall, tail, mass, and scalar objects. Its
maximum defects were $4.2989660483593291\times10^{-15}$ for $N=256$ and
$4.2658611063915778\times10^{-15}$ for $N=384$.

| run | role | entry/wall seconds | peak tree RSS | result |
|---|---|---:|---:|---|
| run-01 | primary $N=256$ field | 404.164903 / 429.975669 | 1,180,565,504 B | exit 0 |
| run-02 | saved-matrix audit | -- / 15.981093 | 1,126,285,312 B | exit 0 |
| run-03 | optional $N=384$ field and audit | 391.492373 / 408.956486 | 1,542,520,832 B | exit 0 |

The cumulative monitored wall time is 854.913248 seconds. The monitor was
configured with a 2.3 GB early-stop threshold and 0.1-second sampling; no run
reached the threshold and no foreign MATLAB process was observed. MATLAB
`checkcode` reported one inherited `INUSD` advisory at line 630 for the unused
local `q` argument in `LOCAL_wall_level`; `audit_i8.m` had no advisories.
The current production source is byte-for-byte identical to the `source.m`
snapshots used by both field runs.

## Reproduction

The following starts a fresh baseline in the next unused run directory. It
must be executed only with an authorized fresh or remaining I8.3 computation
budget; it does not clear or bypass the monitor ledger.

```bash
run_dir=test/i8/estimate-v1/output/attempt-1/run-04
matlab_expr=$(cat <<'MATLAB'
repo=pwd;
expdir=fullfile(repo,'test','i8','estimate-v1');
rundir=fullfile(expdir,'output','attempt-1','run-04');
addpath(repo); addpath(expdir);
[result,evidence]=estimate_i8(1.7562818500073463,256);
save(fullfile(rundir,'scientific.mat'),'result','evidence','-v7.3');
audit=audit_i8(result,evidence);
save(fullfile(rundir,'audit.mat'),'audit');
fid=fopen(fullfile(rundir,'result.json'),'w');
fprintf(fid,'%s\n',jsonencode(result,'PrettyPrint',true)); fclose(fid);
fid=fopen(fullfile(rundir,'audit2.json'),'w');
fprintf(fid,'%s\n',jsonencode(audit,'PrettyPrint',true)); fclose(fid);
assert(audit.all_pass);
MATLAB
)
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
  I83_WALL_LIMIT_SECONDS=1845 I83_RSS_LIMIT_BYTES=2300000000 \
  bash test/i8/estimate-v1/monitor.sh "$run_dir" "$matlab_expr"
```

`result.json` and `parts.csv` contain the compact primary ledger.
`scientific.mat` retains the full primitive evidence, while `audit2.json`
contains the independent recomposition. The field, jumps, tail candidates,
mass, $C_{\rm num}$, and $R_{\rm num}$ are numerical diagnostics only.
