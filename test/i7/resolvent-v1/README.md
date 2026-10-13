# I7.4 corrected-density resolvent estimate

This experiment evaluates the frozen I7 ellipse-center candidate at
`khat = 1.755995740875`.  It uses the corrected physical density coordinates,
the raw boundary action $A_{raw}=D^{-1}A_sD$, physical artificial-wall fields,
and the resolvent spectral-distance expression
$R=2\mu\bar C\epsilon/(\underline U-\bar C\epsilon)$.

The formal result is a **finite diagnostic and conditional scalar estimate**,
not a certified spectral inclusion.  The formal fresh run is `run-05`; it
constructs the physical objects, performs an independent matrix audit, and
runs the Arb scalar calculation without reading an earlier result.

## Frozen model and configuration

- $\beta=0.5$, center ellipse semiaxes $(0.25,0.16)$, center relative
  parameter $2$.
- Lead inclusions are circles of radius $0.2$ with relative parameter $17$;
  the exterior parameter is $1$.
- Final spatial tuple is `(ntot,nside,ntop,nproxy,mpw) =
  (256,160,160,80,32)` with Rayleigh order `M = 48` and `K = 97`.
- Candidate amplitudes use the minimum right singular vector of `Aphys`, with
  the saved normalization and phase convention.
- The center density is the saved binary64 physical sample vector
  $[\tau;\zeta]$, where $\zeta=-\sigma$.  The 512-node material evaluation is
  the trigonometric interpolation of that same 256-node density; it is not a
  new density solve.

The implementation files are:

- `estimate_i7_resolvent.m`: physical construction and numerical components;
- `audit_i7_resolvent.m`: independent fresh-matrix reconstruction;
- `certify_scalars_i7.py`: Arb geometry, propagation, wall-tail, mass, and
  conditional scalar arithmetic;
- `SYMBOLS.md`: mathematical symbol-to-variable ledger.

## Formal run-05 result

The formal artifacts are under `output/attempt-1/run-05/`.  The independent
audit passed with maximum defect `2.3430668573812629e-13`, below its `1e-11`
tolerance.

| Quantity | Value | Status |
|---|---:|---|
| `adef_sigma` | `1.0113801620671042e-10` | numerical |
| `adef_ratio` | `1.6739838415360645e-13` | numerical |
| `aphys_sigma` | `5.0025687287374273e-11` | numerical |
| `aphys_ratio` | `1.7513129037661042e-11` | numerical |
| $\epsilon$ | `1.0116161391167468e-10` | candidate, not an upper bound |
| sampled mass candidate | `0.11463157444478528` | diagnostic |
| $\bar C$ | `2.863846920155989` | certified geometry constant |
| $\underline U$ | `0.08973136188400639` | certified same-field lower bound, rounded down |
| $\bar C\epsilon$ | `2.897113764389588e-10` | conditional on candidate $\epsilon$ |
| denominator | `0.08973136159429502` | conditional, positive |
| $R$ | `1.991123525767936e-8` | conditional, uncertified |
| conditional $\lambda$ interval | `[3.0835210220599048, 3.0835210618823754]` | not a spectral inclusion |

The formal scalar status is `UNCERTIFIED_F14_ESTIMATE`.  Strictly established
sub-results include $\mu=\widehat k^2$ as the exact real-arithmetic square
of the frozen binary64 $\widehat k$ (the exact fraction is
`3908827299671091099331090780849/1267650600228229401496703205376`),
the collar/strip geometry and $\bar C$, full-matrix propagation
contractions, the separate
$|m|>48$ wall tail, and the same-field safe-disk mass lower bound.  The
separate Arb $|m|>48$ wall-tail bounds, rounded up, are `6.612899834e-66` for the
squared value contribution and `6.300147540e-61` for the squared normal
contribution; they are not added again to the full-node wall diagnostic.

The following obligations remain open:

- a one-sided continuous ellipse material-jump upper bound, including the
  stored-density versus `Hmap*q` evaluation roundoff;
- retained/full artificial-wall upper bounds and enclosure of the numerical
  quasi-periodic evaluator error;
- a one-sided infinite-cell action tail bound.

Closing the first item requires a shape-general Arb Kress and smooth
`log(g(t,s))` remainder, rather than a circle-radius substitution.  Therefore
the conditional $R$ above must not be quoted as a certificate.

## Component detail

`run-06/component-detail.json` and `.csv` export the fresh `run-05` scalars
without recomputing the physical problem.

| Component | Squared value | Squared normal | Interpretation |
|---|---:|---:|---|
| center material | `1.8194738297815184e-30` | `1.1002890647906295e-28` | raw boundary action |
| lead material, 40 cells each side | `2.2883582582396657e-30` | `1.493298294740897e-28` | finite prefix |
| lead observed tail | `5.3176098294074893e-72` | `3.4724586979603008e-70` | uncertified candidate |
| center-to-lead walls | `1.7685599757563255e-27` | `1.0233596737731471e-20` | dominant numerical term |
| internal walls, 40 cells each side | `1.9801110042308786e-27` | `7.1379345715630134e-26` | finite prefix |
| wall observed tail | `4.6098893336050223e-69` | `1.6612301369862369e-67` | uncertified candidate |
| complete numerical total | `3.7527788120752258e-27` | `1.0233668376435922e-20` | finite diagnostic |

The observed lead-tail ratios are `0.09107163916249504` for both value and
normal terms.  The observed wall-tail ratios are `0.09096187669637885` and
`0.09105309813050079`.  These geometric extrapolations are diagnostics, not
one-sided bounds.  The 256-to-512 wall changes are `0.019705353158575575` for
the squared value and `8.190719414779718e-5` for the squared normal term.

The native-grid versus fixed-density cross-grid material changes in
`result.json` are also diagnostics.  The native 256-node residual is small by
construction, so those relative changes are not a convergence test.

## Reproduction

Run from the repository root.  `run-07` is the next unused directory at the
time of this report.  The monitor refuses to overwrite an existing run and
enforces a 900-second wall limit, a 2.3 GB early-stop threshold, serialized
MATLAB execution, and 0.1-second resource sampling.  This command activates
the project Python environment, resolves its Python executable through the
environment, and runs the numerical estimate, independent audit, and Arb
calculation in one monitored process tree without reading prior output.

```bash
eval "$(conda shell.bash hook)"
conda activate octave
export I74_PYTHON="$(command -v python)"
run_dir=test/i7/resolvent-v1/output/attempt-1/run-07
matlab_expression=$(cat <<'MATLAB'
repo=pwd;
source_dir=fullfile(repo,'test','i7','resolvent-v1');
run_dir=fullfile(source_dir,'output','attempt-1','run-07');
addpath(repo);
addpath(source_dir);
mkdir(fullfile(run_dir,'source'));
files={'estimate_i7_resolvent.m','audit_i7_resolvent.m', ...
  'SYMBOLS.md','certify_scalars_i7.py'};
for j=1:numel(files)
  copyfile(fullfile(source_dir,files{j}), ...
    fullfile(run_dir,'source',files{j}));
end
public_files={fullfile('+bloch','construct_S.m'), ...
  fullfile('+op','construct_A_QP.m'), ...
  fullfile('+kernel','qpgreen_mfs_pairmat.m'), ...
  fullfile('+kernel','h2d_directch.m'), ...
  fullfile('test','i7','refine-v1','run_matlab_monitored.sh')};
for j=1:numel(public_files)
  [~,name,ext]=fileparts(public_files{j});
  copyfile(fullfile(repo,public_files{j}), ...
    fullfile(run_dir,'source',[name ext]));
end
issues_estimate=checkcode(fullfile(source_dir, ...
  'estimate_i7_resolvent.m'),'-struct');
issues_audit=checkcode(fullfile(source_dir, ...
  'audit_i7_resolvent.m'),'-struct');
save(fullfile(run_dir,'code-check.mat'), ...
  'issues_estimate','issues_audit');
p1=which('bloch.construct_S');
p2=which('op.construct_A_QP');
p3=which('kernel.qpgreen_mfs_pairmat');
p4=which('kernel.h2d_directch');
assert(strcmp(p1,fullfile(repo,'+bloch','construct_S.m')));
assert(strcmp(p2,fullfile(repo,'+op','construct_A_QP.m')));
assert(strcmp(p3,fullfile(repo,'+kernel','qpgreen_mfs_pairmat.m')));
assert(strcmp(p4,fullfile(repo,'+kernel','h2d_directch.m')));
assert(~contains(path,[filesep 'tmp']));
fid=fopen(fullfile(run_dir,'runtime-paths.txt'),'w');
fprintf(fid, ...
  'construct_S=%s\nconstruct_A_QP=%s\nqpgreen=%s\nh2d=%s\n', ...
  p1,p2,p3,p4);
fclose(fid);
[result,evidence]=estimate_i7_resolvent(run_dir);
audit=audit_i7_resolvent(result,evidence);
assert(audit.all_pass);
save(fullfile(run_dir,'independent-audit.mat'),'audit');
text=jsonencode(audit,'PrettyPrint',true);
fid=fopen(fullfile(run_dir,'independent-audit.json'),'w');
assert(fid>=0);
fprintf(fid,'%s\n',text);
fclose(fid);
py=getenv('I74_PYTHON');
assert(~isempty(py) && isfile(py));
setenv('PYTHONDONTWRITEBYTECODE','1');
setenv('PYTHONPATH',[fullfile(repo,'test','i6','resolvent-v3','vendor') ...
  pathsep fullfile(repo,'test','i6','resolvent-v3')]);
cmd=sprintf('"%s" "%s" "%s" "%s"',py, ...
  fullfile(source_dir,'certify_scalars_i7.py'), ...
  fullfile(run_dir,'numerical-input.json'), ...
  fullfile(run_dir,'scalar-report.json'));
[py_status,py_output]=system(cmd);
fprintf(1,'%s',py_output);
assert(py_status==0);
MATLAB
)
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
I73_WALL_LIMIT_SECONDS=900 I73_RSS_LIMIT_BYTES=2300000000 \
bash test/i7/refine-v1/run_matlab_monitored.sh \
  "$run_dir" "$matlab_expression"
```

The compact result is `result.json`, the full matrices are in
`scientific.mat`, the independent audit is `independent-audit.json`, and the
strict/conditional scalar record is `scalar-report.json`.

## Run and resource ledger

| Run | Wall seconds | Peak tree RSS bytes | Exit | Role |
|---|---:|---:|---:|---|
| `run-01` | `222.778350` | `1088667648` | `0` | Offset-curve prototype; rejected because 256-to-512 material changes were `0.93`--`0.998` |
| `run-02` | `17.606960` | `978190336` | `130` | Deliberate pre-material interruption to use the exact geometry-`C` weights in $D$ |
| `run-03` | `164.532928` | `1123418112` | `0` | Corrected boundary-action numerical run |
| `run-04` | `23.885752` | `1076461568` | `0` | Saved-data Arb mass audit; superseded by fresh `run-05` |
| `run-05` | `178.672574` | `1209221120` | `0` | Formal fresh estimate, independent audit, and Arb scalar |
| `run-06` | `20.774869` | `954613760` | `0` | Scalar component export only; no physical recomputation |

The cumulative monitored wall time is `628.251433` seconds.  The maximum tree
RSS is `1209221120` bytes, below both the 2.3 GB early-stop threshold and the
3,000,000,000-byte task limit.  Runs were serial and no external MATLAB process
was present.

The task ran from `2026-10-06T00:28:37Z` through final acceptance checks at
`2026-10-06T01:56:50Z`: `5293` seconds (88 minutes 13 seconds), below the
two-hour limit.  The machine-readable ledger is `output/task-time.json`.

`run-02` records `process monitoring failed` because the deliberate Ctrl-C
arrived while the monitor's `ps` subprocess was active.  The monitor cleaned
the task group; authorized live checks found neither run-owned PID and no other
MATLAB process before `run-03` began.  It contains no scientific result.
