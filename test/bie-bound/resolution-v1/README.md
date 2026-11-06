# Resolution study version 1

Resolution separates field discretization from evaluation accuracy. BIE = boundary integral equation; FEM = finite element method; DtN = Dirichlet-to-Neumann; FMM = fast multipole method; MFS = method of fundamental solutions; RT3 = Raviart–Thomas degree 3; P2/P3 = polynomial finite elements of degree 2/3; Arb/Acb = real/complex ball arithmetic; RSS = resident set size; GiB = gibibyte; CSV = comma-separated values; JSON = JavaScript Object Notation; CPU = central processing unit; CM = coupled source moments. `detsearch` means determinant search; `eval_settings` means evaluation settings.

The root source tree is an unchanged copy of pipeline-v1 for the reference reproduction. `varied/` is its parameterized copy, with source headers naming the owner. No protected experiment, shared package or reference data was changed. Five field rows start with empty outputs. Three evaluation rows read only the exact field/fit and band result of this experiment's reference row; paths are explicit in scientific-inputs.json. All intervals use the original spectral-distance theorem and the original analytic remainder rules.

## Parameters and boundaries

Field arguments: center/lead boundary nodes and Rayleigh M; state/port dimensions are derived from exported modes, and the B fit has1+2(2M+1) right-hand sides. Evaluation arguments: target panel factor1/2, fixed Chebyshev nodes48/64, main precision128/192. Target counts are192 central,64 per lead,16 per vertical wall,8 per seam before multiplication. Source partitions and expansion orders are unchanged. L=64 gives fixed interpolation degree63; center local Taylor degree52 and the independently adaptive self-interaction degree stay unchanged and are zero-padded for addition. Main192-bit arithmetic replaces128-bit assignments; existing192-bit conversions and higher-precision controls stay. Disk integration is recomputed at the selected main precision.

Full rows include classification/search, density rebuild and B fit, residuals, independent audit, mass, two C certificates/assembly,472 band sign tests, startup/exit and metadata. Fixed-field rows exclude search/rebuild/fit and reuse the same-field band certificate; they recheck interval placement. Every row retains the stable original checks. Resource limits are30min soft/40min hard,3GiB process-tree RSS, one heavy job at a time; every launch records a ps preflight. MATLAB uses11 computational threads, residuals8 processes, OMP_DYNAMIC=FALSE.

## Reproduction

Use a fresh run number; a nonempty output is refused. Replace paths explicitly on another machine. For the unchanged reference:

```sh
python3 /Users/whc/Documents/Work/dot-research/test/bie-bound/resolution-v1/run_pipeline.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/resolution-v1/output/run-101 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --search-path /Users/whc/Documents/Work/dot-research/test/i9/search-v1 \
  --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --conda /Users/whc/opt/miniconda3/condabin/conda
```

For the parameterized path use `varied/run_pipeline.py` with the same public path arguments and a new output. Add:

| Scientific row | Extra arguments |
|---|---|
|256/128/128,M48|`--center-nodes 256 --lead-nodes 128 --rayleigh-M 48`|
|384/192/192,M48|`--center-nodes 384 --lead-nodes 192 --rayleigh-M 48`|
|512/256/256,M40|`--center-nodes 512 --lead-nodes 256 --rayleigh-M 40`|
|512/256/256,M56|`--center-nodes 512 --lead-nodes 256 --rayleigh-M 56`|
|twice all target panels|`--field-source /Users/whc/Documents/Work/dot-research/test/bie-bound/resolution-v1/output/run-101 --panels 2`|
|64 fixed Chebyshev nodes|`--field-source /Users/whc/Documents/Work/dot-research/test/bie-bound/resolution-v1/output/run-101 --chebyshev 64`|
|192-bit main precision|`--field-source /Users/whc/Documents/Work/dot-research/test/bie-bound/resolution-v1/output/run-101 --precision 192`|

Each launcher contains the copied monitor and explicit commands; request escalated execution as in the task. The queue scripts were development controllers; individual public drivers need no pilot/check-file prerequisite. `summarize.py --runs RUN... --output /Users/whc/Documents/Work/dot-research/test/bie-bound/resolution-v1/tables` checks/readbacks outputs and emits compact CSV/JSON; `report_tables.py --input .../reference-results.json --output .../tables` makes the expanded tables. `pilot.py` documents the13-target parameter-plumbing regression. No scientific runtime reads reports or Git metadata.

## Results and checks

The accepted rows are run-001,003,006,007,008,010,011,012. Reference vs pipeline-v1 run-002: identical candidate bits, five residual bounds,Q,width. The13-target copied-path pilot (run-002) has zero relative difference,133.623s,1.016GiB. A final exact-rational comparison also checks both reported mu/k endpoints and the width directly against the input decimals. All accepted rows retain independent residual integration/coverage, full-port vs state-column checks, N+10 tail checks, two C configurations, two-precision and exact-rational assembly. Band tests are rerun on full rows and explicitly reused on same-field rows. The source/fit path equality and candidate bits are checked for every same-field row.

The ordinary same-field residual estimate is the square root of the floating sum of finite-state polynomial integral midpoints. It removes model-error additions; the separately recorded infinite tail remains bounded. It is not another double-precision kernel evaluation. Per-group values, weighted contributions, mass balls, all checks and stage times are in `tables/reference-results.json` and `resolution.csv`; raw per-target and stage records remain under each run.

run-004 stopped in decimal printing after residual/mass checks: a scaled ball straddled an integer. The copied formatter now extracts its outward endpoint before ceil/floor. run-005 checked the repair at two precisions and against exact-rational assembly; run-006 repeated the whole configuration. run-009 was discarded after the monitor scan raced with archival of completed output; its orphaned process group was stopped. The monitor now tolerates files disappearing during the scan, and archival occurs only between runs. run-010 repeats the evaluation. Neither repair changes a certificate formula or relaxes a numerical gate. Full timing/RSS after run-009's monitoring exception is unavailable; its last331.506s and sampled2.493GiB are partial records. Failed/development costs are separate from selected-configuration costs.

Large owned JSON files are losslessly gzip-compressed only between completed runs; every compression is checked by decompressing and comparing the exact original content. `archive.json` lists recoverable files; `gzip -dk FILE.json.gz` restores one without removing its archive. Postprocessors read either representation. The reference field/fit and band result needed by later runs stay uncompressed. Compression is outside measured scientific wall time. The new directory and full worktree respect the task's storage limits. Final completion-checks.json records an experiment size of156.92MB, full worktree869.53MB, compact table artifacts155.12kB, successful scientific wall-time sum6478.875s and maximum successful process-tree RSS2.718445GiB. These are separate from the preserved failed/development runs.

## Recorded prelaunch forecasts

Reference:14–16min,2.3GiB. Parameter-plumbing pilot:3–4min,2.3GiB. Formatting check:10s,0.2GiB.

Before run-002 (parameter-plumbing pilot): forecast 3–4 minutes, peak 2.3 GiB. Reuse the run-001 field and compare 13 selected target ledgers (all target kinds, both leads, center0/1) with its original path. Tolerance1e-12 relative on their upper norm squares (center panel norm). No new field is generated. This pilot is separate development/check cost, not one of the eight scientific rows.

Before run-003: field N=256/128/128 M48; complete forecast 900s, peak 2.3GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-004: field N=384/192/192 M48; complete forecast 1000s, peak 2.3GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-006: field N=384/192/192 M48; complete forecast 1000s, peak 2.3GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-007: field N=512/256/256 M40; complete forecast 1000s, peak 2.3GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-008: field N=512/256/256 M56; complete forecast 1200s, peak 2.6GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-009: fixed field, twice all target panels; complete forecast 1250s, peak 2.6GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-010: fixed field, twice all target panels; complete forecast 1250s, peak 2.6GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-011: fixed field, 64 smooth Chebyshev nodes; complete forecast 1150s, peak 2.6GiB. All stages/checks included; 30/40min and 3GiB enforced.

Before run-012: fixed field, 192-bit main arithmetic; complete forecast 1300s, peak 2.7GiB. All stages/checks included; 30/40min and 3GiB enforced.

## Full comparison tables

## 场分辨率

| 设置 / run | 中心材料 | 左材料 | 右材料 | 竖壁 | 接缝 | Q | 2R | 秒 / GiB |
|---|---|---|---|---|---|---|---|---|
| 512/256/256, M=40 / 007 | 1.2615716e-12；3.1416335e-12 | 5.1601794e-14；6.0971802e-14 | 5.2485275e-14；6.4763732e-14 | 1.9832089e-13；2.0537180e-13 | 5.2185191e-15；5.4040531e-15 | 3.4781449e-12 | 2.7340967e-11 | 812.071 / 2.291 |
| 256/128/128, M=48 / 003 | 2.1824100e-7；5.4347551e-7 | 4.7130208e-14；5.5688252e-14 | 9.6563735e-11；1.1915396e-10 | 2.8386195e-13；2.9395409e-13 | 1.0951020e-14；1.1340361e-14 | 5.4359503e-7 | 4.2730883e-6 | 777.587 / 1.718 |
| 384/192/192, M=48 / 006 | 5.0392626e-10；1.2549044e-9 | 4.8468328e-14；5.7269353e-14 | 5.1560629e-14；6.3622774e-14 | 1.9661333e-13；2.0360353e-13 | 6.7636695e-15；7.0041383e-15 | 1.2552359e-9 | 9.8671458e-9 | 764.361 / 2.200 |
| 512/256/256, M=48 / 001 | 1.2615836e-12；3.1416636e-12 | 5.0810501e-14；6.0036824e-14 | 5.2315548e-14；6.4554299e-14 | 2.0345792e-13；2.1069146e-13 | 5.7836900e-15；5.9893175e-15 | 3.4829355e-12 | 2.7378625e-11 | 918.650 / 1.669 |
| 512/256/256, M=56 / 008 | 1.2616066e-12；3.1417207e-12 | 4.9932678e-14；5.8999604e-14 | 5.1661388e-14；6.3747104e-14 | 2.3524969e-13；2.4361352e-13 | 9.9457927e-15；1.0299396e-14 | 3.5183803e-12 | 2.7657249e-11 | 841.226 / 1.910 |

所有行使用可靠质量下界 U=1.23587；各行重算的圆盘下界原始球见 JSON 的 mass_certificate。每格先列 $\epsilon_g$，再列 $C_g\epsilon_g$。

| 设置 | khat | 与参考相差 ulp | 重算的圆盘下界（显示中点） |
|---|---|---|---|
| 512/256/256, M=48 | 1.558437894182088 | +0 | 1.2358712087405960704825068846483253639 |
| 256/128/128, M=48 | 1.5584378941820882 | +1 | 1.2358712087405913582937135564054945204 |
| 384/192/192, M=48 | 1.5584378941820887 | +3 | 1.2358712087405928504567893477833111927 |
| 512/256/256, M=40 | 1.558437894182088 | +0 | 1.2358712087405971907464363782147746551 |
| 512/256/256, M=56 | 1.5584378941820876 | -2 | 1.2358712087405954677581296705566841612 |

## 固定场的评价分辨率

| 设置 / run | 中心材料 | 左材料 | 右材料 | 竖壁 | 接缝 | Q | 2R | 秒 / GiB |
|---|---|---|---|---|---|---|---|---|
| 512/256/256, M=48 / 001 | 1.2615836e-12；3.1416636e-12 | 5.0810501e-14；6.0036824e-14 | 5.2315548e-14；6.4554299e-14 | 2.0345792e-13；2.1069146e-13 | 5.7836900e-15；5.9893175e-15 | 3.4829355e-12 | 2.7378625e-11 | 918.650 / 1.669 |
| 面板×2 / 010 | 1.2615800e-12；3.1416545e-12 | 5.0810501e-14；6.0036824e-14 | 5.2315553e-14；6.4554306e-14 | 2.0345792e-13；2.1069146e-13 | 5.7836899e-15；5.9893174e-15 | 3.4829264e-12 | 2.7378554e-11 | 947.552 / 2.311 |
| L=64 / 011 | 1.2615836e-12；3.1416636e-12 | 5.0810501e-14；6.0036824e-14 | 5.2315548e-14；6.4554299e-14 | 2.0345792e-13；2.1069146e-13 | 5.7836900e-15；5.9893176e-15 | 3.4829355e-12 | 2.7378625e-11 | 583.728 / 2.399 |
| 192 bit / 012 | 1.2615836e-12；3.1416636e-12 | 5.0810501e-14；6.0036824e-14 | 5.2315548e-14；6.4554299e-14 | 2.0345792e-13；2.1069146e-13 | 5.7836900e-15；5.9893175e-15 | 3.4829355e-12 | 2.7378625e-11 | 833.700 / 2.718 |

同场普通浮点参照：从有限状态残差多项式的平方积分中点求和再开方，去掉模型误差加项；无限尾项另列可靠界。它不是另一次双精度核求值，因而不混入不同核算法的舍入噪声。

| 组 | 参考可靠上界 | 同场有限部分浮点估计 | 参考相对加宽 | 所有已测设置中较小可靠上界 |
|---|---|---|---|---|
| 中心材料 | 1.2615836e-12 | 1.2615718e-12 | 0.0009333088% | 1.2615800e-12 (面板×2) |
| 左材料 | 5.0810501e-14 | 5.0810493e-14 | 1.485662e-05% | 5.0810501e-14 (面板×2) |
| 右材料 | 5.2315548e-14 | 5.2315482e-14 | 0.0001253735% | 5.2315548e-14 (192 bit) |
| 竖壁 | 2.0345792e-13 | 2.0345792e-13 | 7.591255e-07% | 2.0345792e-13 (面板×2) |
| 水平接缝 | 5.7836900e-15 | 5.7836876e-15 | 4.19023e-05% | 5.7836899e-15 (面板×2) |

## 成本—宽度

| 设置 | 完整场链 / 固定场后处理 | 秒 | 宽度 2R |
|---|---|---|---|
| 512/256/256, M=48 | 完整场链 | 918.650 | 2.7378625e-11 |
| 256/128/128, M=48 | 完整场链 | 777.587 | 4.2730883e-6 |
| 384/192/192, M=48 | 完整场链 | 764.361 | 9.8671458e-9 |
| 512/256/256, M=40 | 完整场链 | 812.071 | 2.7340967e-11 |
| 512/256/256, M=56 | 完整场链 | 841.226 | 2.7657249e-11 |
| 面板×2 | 固定场后处理 | 947.552 | 2.7378554e-11 |
| L=64 | 固定场后处理 | 583.728 | 2.7378625e-11 |
| 192 bit | 固定场后处理 | 833.700 | 2.7378625e-11 |

| run | 搜索 | 场重建/B拟合 | 可靠残差 | 残差审核 | 质量 | C及装配 | 谱隙 | 启动/编排余项 |
|---|---|---|---|---|---|---|---|---|
| run-001 | 214.613 | 22.894 | 574.332 | 1.250 | 21.418 | 1.190 | 81.496 | 1.458 |
| run-003 | 128.856 | 19.736 | 535.270 | 1.173 | 11.790 | 1.186 | 78.149 | 1.427 |
| run-006 | 139.084 | 18.043 | 508.071 | 1.188 | 16.840 | 1.210 | 78.500 | 1.425 |
| run-007 | 172.533 | 18.126 | 520.953 | 1.193 | 20.427 | 1.215 | 76.206 | 1.417 |
| run-008 | 187.663 | 21.023 | 531.276 | 1.213 | 20.624 | 1.221 | 76.754 | 1.451 |
| run-010 | 0.000 | 0.000 | 923.834 | 1.220 | 19.787 | 1.251 | 0.000 | 1.460 |
| run-011 | 0.000 | 0.000 | 560.000 | 1.226 | 19.778 | 1.253 | 0.000 | 1.471 |
| run-012 | 0.000 | 0.000 | 798.402 | 1.265 | 31.297 | 1.269 | 0.000 | 1.467 |
