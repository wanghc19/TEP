# I8.2 fixed-point discretization check

`check_i8` evaluates the corrected-density I8 equal-area star model at a fixed candidate and two shoulders. It does not relocate the candidate, run I8.3, or certify a continuous eigenvalue. The formal run used `k0=1.7562818500073463` and `halfwidth=1e-5`, giving the actual binary64 points `1.7562718500073462`, `1.7562818500073463`, and `1.7562918500073463`.

The model fixes `beta=0.5`, lead circles of radius `0.2` and relative permittivity `17`, and a center star of relative permittivity `2`. The star is formed by multiplying all six rows returned by `geom.construct_cont(...,'star',...)` by `sqrt(0.04/0.0618)`. All configurations use `(nside,ntop,nproxy,mpw)=(160,160,80,32)`:

|ID|`ntot`|Rayleigh `M`|`K=2M+1`|
|---|---:|---:|---:|
|B|256|48|97|
|N384|384|48|97|
|N512|512|48|97|
|M56|256|56|113|
|M64|256|64|129|

For each point, the entry independently builds `T`, `N0`, `L`, and `Adef`, checks `Adef=N0-L*T`, forms `H=Adef/T` and `Hsym=(H+H')/2`, and evaluates the three sign-count bands with multipliers 50, 100, and 200. Reported four singular metrics use MATLAB's value-only `svd`; the vector SVD is saved separately for residual checks and physical traces `q=colwt.*v`, `t=T*q`.

## Formal result

Run `output/attempt-1/run-01` completed all 15 points. The endpoint gate passed for all five configurations: the negative count triples changed from `[0,0,0]` on the left to `[1,1,1]` on the right, with no endpoint unresolved eigenvalues. Every center had one unresolved surrogate eigenvalue in all three bands; this is recorded as `SURROGATE_SIGN_UNRESOLVED` and does not invalidate the endpoint jump. All 12 adjacent-edge same-object comparisons and all four direct baseline center summaries reported `SAME_MODE`. The compact outcome is `STABLE_SAME_MODE`; this is a numerical fixed-point/discretization result, not a certified Hermitian inertia or continuous-eigenvalue statement.

The B-center four metrics exactly reproduce the I8.1 value-only metrics at the same binary64 `k0`:

- `adef_sigma = 9.0463849720091667e-14`
- `adef_ratio = 1.4973105978156506e-16`
- `aphys_sigma = 4.3645331331577957e-14`
- `aphys_ratio = 1.5283249311405522e-14`

### All point metrics

|Cfg|Point|k|sigma(Adef)|ratio(Adef)|sigma(Aphys)|ratio(Aphys)|seconds|
|---|---:|---:|---:|---:|---:|---:|---:|
|B|L|1.7562718500073462|8.581762456e-05|1.420408695e-07|4.244261981e-05|1.486195786e-05|9.427|
|B|C|1.7562818500073463|9.046384972e-14|1.497310598e-16|4.364533133e-14|1.528324931e-14|8.843|
|B|R|1.7562918500073463|8.581640607e-05|1.420388528e-07|4.244165604e-05|1.486189830e-05|8.424|
|N384|L|1.7562718500073462|8.581762456e-05|1.420408695e-07|4.244261981e-05|1.486195786e-05|19.188|
|N384|C|1.7562818500073463|9.356805027e-14|1.548689711e-16|4.573792771e-14|1.601601204e-14|20.126|
|N384|R|1.7562918500073463|8.581640606e-05|1.420388527e-07|4.244165604e-05|1.486189830e-05|19.186|
|N512|L|1.7562718500073462|8.581762457e-05|1.420408695e-07|4.244261981e-05|1.486195786e-05|33.439|
|N512|C|1.7562818500073463|1.022890258e-13|1.693034764e-16|5.029715707e-14|1.761251359e-14|35.845|
|N512|R|1.7562918500073463|8.581640607e-05|1.420388528e-07|4.244165604e-05|1.486189830e-05|35.019|
|M56|L|1.7562718500073462|8.581762457e-05|1.217775653e-07|4.244261981e-05|1.486195786e-05|9.224|
|M56|C|1.7562818500073463|9.202445199e-14|1.305852239e-16|4.529654981e-14|1.586145511e-14|9.705|
|M56|R|1.7562918500073463|8.581640606e-05|1.217758363e-07|4.244165604e-05|1.486189830e-05|8.694|
|M64|L|1.7562718500073462|8.581762458e-05|1.065739635e-07|4.244261981e-05|1.486195786e-05|8.901|
|M64|C|1.7562818500073463|8.825268930e-14|1.095979868e-16|4.312261577e-14|1.510021044e-14|8.799|
|M64|R|1.7562918500073463|8.581640604e-05|1.065724503e-07|4.244165604e-05|1.486189830e-05|9.434|

### Full matrix and sign-count diagnostics

|Cfg|Pt|rcond(T)|assembly|right solve|dH|s(Hsym)|eta50/100/200|minabs eig|signed eig|counts50;100;200 (p,n,u)|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
|B|L|0.516993|7.07e-19|4.92e-19|1.788e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|7.388e-05|7.388e-05|(194,0,0); (194,0,0); (194,0,0)|
|B|C|0.516993|1.00e-18|5.16e-19|1.920e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|9.738e-14|9.738e-14|(193,0,1); (193,0,1); (193,0,1)|
|B|R|0.516993|8.81e-19|5.96e-19|1.948e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|7.388e-05|-7.388e-05|(193,1,0); (193,1,0); (193,1,0)|
|N384|L|0.516993|7.16e-19|4.94e-19|1.889e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|7.388e-05|7.388e-05|(194,0,0); (194,0,0); (194,0,0)|
|N384|C|0.516993|9.77e-19|5.15e-19|2.458e-13|6.042e+02|1.302e-09/2.603e-09/5.205e-09|1.224e-14|-1.224e-14|(193,0,1); (193,0,1); (193,0,1)|
|N384|R|0.516993|7.74e-19|5.96e-19|1.644e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|7.388e-05|-7.388e-05|(193,1,0); (193,1,0); (193,1,0)|
|N512|L|0.516993|6.10e-19|4.94e-19|1.488e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|7.388e-05|7.388e-05|(194,0,0); (194,0,0); (194,0,0)|
|N512|C|0.516993|1.09e-18|5.16e-19|1.724e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|1.449e-13|-1.449e-13|(193,0,1); (193,0,1); (193,0,1)|
|N512|R|0.516993|6.74e-19|5.96e-19|1.489e-13|6.042e+02|1.301e-09/2.603e-09/5.205e-09|7.388e-05|-7.388e-05|(193,1,0); (193,1,0); (193,1,0)|
|M56|L|0.516993|5.03e-19|4.06e-19|1.762e-13|7.047e+02|1.768e-09/3.537e-09/7.073e-09|7.388e-05|7.388e-05|(226,0,0); (226,0,0); (226,0,0)|
|M56|C|0.516993|6.85e-19|3.93e-19|2.373e-13|7.047e+02|1.768e-09/3.537e-09/7.073e-09|9.405e-14|-9.405e-14|(225,0,1); (225,0,1); (225,0,1)|
|M56|R|0.516993|5.07e-19|4.24e-19|2.022e-13|7.047e+02|1.768e-09/3.537e-09/7.073e-09|7.388e-05|-7.388e-05|(225,1,0); (225,1,0); (225,1,0)|
|M64|L|0.516993|4.70e-19|2.96e-19|3.299e-13|8.052e+02|2.307e-09/4.613e-09/9.226e-09|7.388e-05|7.388e-05|(258,0,0); (258,0,0); (258,0,0)|
|M64|C|0.516993|4.53e-19|3.11e-19|2.293e-13|8.052e+02|2.307e-09/4.613e-09/9.226e-09|1.364e-14|1.364e-14|(257,0,1); (257,0,1); (257,0,1)|
|M64|R|0.516993|4.13e-19|3.41e-19|2.300e-13|8.052e+02|2.307e-09/4.613e-09/9.226e-09|7.388e-05|-7.388e-05|(257,1,0); (257,1,0); (257,1,0)|

### Direct baseline center-mode summaries

|Comparison|status|primary overlap|cross max|gap A|gap B|tail A > common|tail B > common|
|---|---|---:|---:|---:|---:|---:|---:|
|B--N384|SAME_MODE|1|2.325127e-05|1.365e+00|1.365e+00|0.000e+00|0.000e+00|
|B--N512|SAME_MODE|1|2.325127e-05|1.365e+00|1.365e+00|0.000e+00|0.000e+00|
|B--M56|SAME_MODE|0.99999999999999989|2.325127e-05|1.365e+00|1.365e+00|0.000e+00|3.051e-32|
|B--M64|SAME_MODE|0.99999999999999956|2.325127e-05|1.365e+00|1.365e+00|0.000e+00|1.395e-32|


The four direct baseline center comparisons were non-gating summaries; the primary adjacent edges were B--N384, N384--N512, B--M56, and M56--M64 at all three point objects. Full adjacent-edge records, common-mode overlaps, cluster ranks, and tail fractions are in `result.json`.

## Independent saved-matrix audit

The Skeptic-owned `audit_i8.m` independently rebuilt both lead pencils, both DtN maps, `T`, `N0`, `L`, `Adef`, `H`, `Hsym`, all eigensystems/count bands, both weighted matrices and SVDs, and all 16 mode comparisons from the fresh run-01 matrices. Run `output/attempt-1/run-02` passed all 15 points, 12 primary comparisons, and four baseline summaries. Its maximum recorded defect was `1.1619553924721235e-14`; the pencil, DtN, `T`, `N0`, `L`, `Adef`, `H`, `Hsym`, and eta defects were exactly zero. The Aphys and reported-metric defects were `5.62717999294372e-17` and `6.3967928176644762e-18`. Every independently reclassified QZ pencil had counts `K/K/0/0`.

The formal source snapshot had one `checkcode` `NASGU` advisory for the warning-state cleanup handle. The current source marks that intentional handle with `%#ok<NASGU>`; this comment-only change was not used to alter or rerun the numerical result. `audit_i8.m` had no advisory.

## Resources and evidence

|Run|Role|Entry/science wall|Monitored wall|Peak process-tree RSS|Result|
|---|---|---:|---:|---:|---|
|run-01|15-point physical evaluation|244.325400 s|270.179383 s|1,035,288,576 bytes|exit 0|
|run-02|saved-matrix independent audit|--|23.074878 s|1,083,080,704 bytes|exit 0|
|total|shared I8.2 ledger|--|293.254261 s|1,083,080,704 bytes|within 2700 s / 3 GB|

Key artifacts are:

- `output/attempt-1/run-01/scientific.mat`: full `result` and 15-cell matrix `evidence`.
- `output/attempt-1/run-01/result.json` and `points.csv`: compact result and 17-digit point table.
- `output/attempt-1/run-01/resources.csv`, `status.txt`, `run.log`, `command.txt`, and `paths.txt`: monitor and provenance evidence.
- `output/attempt-1/run-02/audit.mat` and `audit.json`: independently recomputed defects, count arrays, eta arrays, and QZ counts.
- `output/attempt-1/run-02/checks.json`: source advisory details.

## Reproduction

Run from the repository root in a fresh unused run directory. This single monitored MATLAB process recomputes the physical matrices and immediately audits those same in-memory objects; it does not read historical output.

```bash
run_dir="test/i8/check-v1/output/attempt-1/run-03"
matlab_expr=$(cat <<'MATLAB'
repo = pwd;
expdir = fullfile(repo,'test','i8','check-v1');
run_dir = fullfile(expdir,'output','attempt-1','run-03');
addpath(repo);
addpath(expdir);
[result,evidence] = check_i8(1.7562818500073463,1e-5);
audit = audit_i8(result,evidence);
save(fullfile(run_dir,'scientific.mat'),'result','evidence','audit','-v7.3');
fid = fopen(fullfile(run_dir,'result.json'),'w');
fwrite(fid,jsonencode(result,'PrettyPrint',true));
fclose(fid);
fid = fopen(fullfile(run_dir,'audit.json'),'w');
fwrite(fid,jsonencode(audit,'PrettyPrint',true));
fclose(fid);
assert(result.execution_pass && audit.all_pass);
MATLAB
)
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
I82_WALL_LIMIT_SECONDS=2700 I82_RSS_LIMIT_BYTES=2300000000 \
bash test/i8/check-v1/monitor.sh "$run_dir" "$matlab_expr"
```

The monitor refuses occupied run evidence, accounts for prior runs under this experiment output root, samples the MATLAB process tree every `0.1` seconds, and is configured to stop this task tree at `2.3e9` bytes before the user hard limit of `3e9` bytes.
