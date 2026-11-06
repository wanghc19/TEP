"""Write the experiment index after the eight accepted rows exist.
Input: explicit experiment directory. Output: README with commands and records.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);a=p.parse_args();root=Path(a.experiment).resolve();rows=json.loads((root/'tables/reference-results.json').read_text());assert len(rows)==8
old=(root/'README.md').read_text();forecasts=[s for s in old.splitlines() if s.startswith('Before ')];table=(root/'tables/tables.md').read_text();task='/Users/whc/Documents/Work/dot-research'
text=f'''# Resolution study version 1

Resolution separates field discretization from evaluation accuracy. BIE = boundary integral equation; FEM = finite element method; DtN = Dirichlet-to-Neumann; FMM = fast multipole method; MFS = method of fundamental solutions; RT3 = Raviart–Thomas degree 3; P2/P3 = polynomial finite elements of degree 2/3; Arb/Acb = real/complex ball arithmetic; RSS = resident set size; GiB = gibibyte; CSV = comma-separated values; JSON = JavaScript Object Notation; CPU = central processing unit; CM = coupled source moments. `detsearch` means determinant search; `eval_settings` means evaluation settings.

The root source tree is an unchanged copy of pipeline-v1 for the reference reproduction. `varied/` is its parameterized copy, with source headers naming the owner. No protected experiment, shared package or reference data was changed. Five field rows start with empty outputs. Three evaluation rows read only the exact field/fit and band result of this experiment's reference row; paths are explicit in scientific-inputs.json. All intervals use the original spectral-distance theorem and the original analytic remainder rules.

## Parameters and boundaries

Field arguments: center/lead boundary nodes and Rayleigh M; state/port dimensions are derived from exported modes, and the B fit has1+2(2M+1) right-hand sides. Evaluation arguments: target panel factor1/2, fixed Chebyshev nodes48/64, main precision128/192. Target counts are192 central,64 per lead,16 per vertical wall,8 per seam before multiplication. Source partitions and expansion orders are unchanged. L=64 gives fixed interpolation degree63; center local Taylor degree52 and the independently adaptive self-interaction degree stay unchanged and are zero-padded for addition. Main192-bit arithmetic replaces128-bit assignments; existing192-bit conversions and higher-precision controls stay. Disk integration is recomputed at the selected main precision.

Full rows include classification/search, density rebuild and B fit, residuals, independent audit, mass, two C certificates/assembly,472 band sign tests, startup/exit and metadata. Fixed-field rows exclude search/rebuild/fit and reuse the same-field band certificate; they recheck interval placement. Every row retains the stable original checks. Resource limits are30min soft/40min hard,3GiB process-tree RSS, one heavy job at a time; every launch records a ps preflight. MATLAB uses11 computational threads, residuals8 processes, OMP_DYNAMIC=FALSE.

## Reproduction

Use a fresh run number; a nonempty output is refused. Replace paths explicitly on another machine. For the unchanged reference:

```sh
python3 {root}/run_pipeline.py \\
  --output {root}/output/run-101 \\
  --package-root {task} \\
  --search-path {task}/test/i9/search-v1 \\
  --fmm-root {task}/vendor/fmm2d/matlab \\
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \\
  --conda /Users/whc/opt/miniconda3/condabin/conda
```

For the parameterized path use `varied/run_pipeline.py` with the same public path arguments and a new output. Add:

| Scientific row | Extra arguments |
|---|---|
|256/128/128,M48|`--center-nodes 256 --lead-nodes 128 --rayleigh-M 48`|
|384/192/192,M48|`--center-nodes 384 --lead-nodes 192 --rayleigh-M 48`|
|512/256/256,M40|`--center-nodes 512 --lead-nodes 256 --rayleigh-M 40`|
|512/256/256,M56|`--center-nodes 512 --lead-nodes 256 --rayleigh-M 56`|
|twice all target panels|`--field-source {root}/output/run-101 --panels 2`|
|64 fixed Chebyshev nodes|`--field-source {root}/output/run-101 --chebyshev 64`|
|192-bit main precision|`--field-source {root}/output/run-101 --precision 192`|

Each launcher contains the copied monitor and explicit commands; request escalated execution as in the task. The queue scripts were development controllers; individual public drivers need no pilot/check-file prerequisite. `summarize.py --runs RUN... --output {root}/tables` checks/readbacks outputs and emits compact CSV/JSON; `report_tables.py --input .../reference-results.json --output .../tables` makes the expanded tables. `pilot.py` documents the13-target parameter-plumbing regression. No scientific runtime reads reports or Git metadata.

## Results and checks

The accepted rows are run-001,003,006,007,008,010,011,012. Reference vs pipeline-v1 run-002: identical candidate bits, five residual bounds,Q,width. The13-target copied-path pilot (run-002) has zero relative difference,133.623s,1.016GiB. All accepted rows retain independent residual integration/coverage, full-port vs state-column checks, N+10 tail checks, two C configurations, two-precision and exact-rational assembly. Band tests are rerun on full rows and explicitly reused on same-field rows. The source/fit path equality and candidate bits are checked for every same-field row.

The ordinary same-field residual estimate is the square root of the floating sum of finite-state polynomial integral midpoints. It removes model-error additions; the separately recorded infinite tail remains bounded. It is not another double-precision kernel evaluation. Per-group values, weighted contributions, mass balls, all checks and stage times are in `tables/reference-results.json` and `resolution.csv`; raw per-target and stage records remain under each run.

run-004 stopped in decimal printing after residual/mass checks: a scaled ball straddled an integer. The copied formatter now extracts its outward endpoint before ceil/floor. run-005 checked the repair at two precisions and against exact-rational assembly; run-006 repeated the whole configuration. run-009 was discarded after the monitor scan raced with archival of completed output; its orphaned process group was stopped. The monitor now tolerates files disappearing during the scan, and archival occurs only between runs. run-010 repeats the evaluation. Neither repair changes a certificate formula or relaxes a numerical gate. Full timing/RSS after run-009's monitoring exception is unavailable; its last331.506s and sampled2.493GiB are partial records. Failed/development costs are separate from selected-configuration costs.

Large owned JSON files are losslessly gzip-compressed only between completed runs; every compression is checked by decompressing and comparing the exact original content. `archive.json` lists recoverable files; `gzip -dk FILE.json.gz` restores one without removing its archive. Postprocessors read either representation. The reference field/fit and band result needed by later runs stay uncompressed. Compression is outside measured scientific wall time. The new directory and full worktree respect the task's storage limits.

## Recorded prelaunch forecasts

Reference:14–16min,2.3GiB. Parameter-plumbing pilot:3–4min,2.3GiB. Formatting check:10s,0.2GiB.

'''+ '\n\n'.join(forecasts)+'\n\n## Full comparison tables\n\n'+table
(root/'README.md').write_text(text);print('README written')
