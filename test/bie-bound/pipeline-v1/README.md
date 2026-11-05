# Full BIE pipeline version 1

Pipeline means the full boundary integral equation (BIE) route. FEM is finite element method; DtN is Dirichlet-to-Neumann; MFS is method of fundamental solutions; FMM is fast multipole method; Arb/Acb are real/complex ball arithmetic; RSS is resident set size; CSV and JSON are compact text outputs.

Plan: from an empty directory, gap classification and determinant search, rebuild/export at the resulting frequency, fit B once, certify all five groups, certify eight fixed interior disks, recompute trace constants and outward assembly, and repeat all 472 band tests. No earlier numerical output is a computation input. Baseline comparison is separate after the run.

Forecast before launch: 12–16 minutes and 2.5 GiB peak process-tree RSS. Search about 176 s; field export and B fit about 25 s including MATLAB startup; groups about 518 s; mass about 21 s; trace/assembly 2 s; band 77 s; orchestration/audits allowance 30 s. All stages share 1800/2400 s and 3 GiB. MATLAB uses 11 threads; groups uses eight one-thread workers; other Arb stages are serial. The driver will record and reject competing heavy scientific processes before timing.

## Implementation and handoffs

`run_pipeline.py` refuses a nonempty output directory, performs the ps preflight, and starts one outer process-tree monitor. Its worker calls separately monitored stages under the remaining shared budget. The root monitor includes the driver, nested monitors, MATLAB startup/exit and all Arb workers. Stage monitor times are not added to the outer time again.

1. `search/`: copied detsearch-v1 production algorithm. Only numerical I9 source files are copied to the new run's inputs directory; the gap and representative validation precede determinant localization. No old bracket, saved field or candidate enters production.
2. `field/`: copied matrel-v1 rebuild and exact binary64 export, plus cellfit-v1 B fit. The returned candidate is an explicit `pilot_config(k)` argument and is checked against the export hex. Propagation receives that same config. Eight disk locations/radii are fixed scientific geometry encoded exactly in disk_geometry.m; their geometric conditions and new-field values are recomputed in the mass stage. The unused floating residual and disk-selection scans are omitted. The fixed 480 proxy positions are generated directly by cell_fit's position formula; the per-kernel A coefficients are unnecessary and are not fitted. B uses the original single scaled SVD and all 195 right-hand sides.
3. `residual/`: grouprel-v1 run-007 arithmetic, envelope fallbacks, 80 states, eight workers and 409 tasks (408 production targets plus an independent reference task). Old numerical-value assertions are comparison diagnostics for the newly rebuilt field. Genuine domain, tail, integral, finite-map and coverage checks remain. The independent audit follows the same-run target outputs.
4. `mass/`: matrel-v1 eight-disk geometry and order-30 Arb quadrature; input comes only from the new field export. The material-interior representation is unchanged by the background B fit.
5. `enclosure/`: enclosure-v1 two curve configurations and two-precision/outward assembly. The old hard-coded epsilon equality is replaced by positive five-entry same-run readback. Published C caps must be reverified for the new mu. U=1.23587 is used only after the new disk certificate exceeds it. Exact rational R is recomputed independently.
6. `band/`: bandrel-v1 all 472 signs, four independent LDL* checks and a deliberate failing control, using the new export and new interval.

`audit_entry.py` records scientific/code reads and rejects numerical files under earlier experiment output directories. `scientific-inputs.json` lists every explicit handoff; `opened-files.jsonl` gives observed Python reads including dependencies. MATLAB performs no data-file reads in search or field export; each stage writes its loaded MATLAB/MEX code paths to dependencies.json. The only data files used by reliable stages are produced earlier in that same run. `paper_records.py` is separate postprocessing: it reads the explicit old enclosure solely for the requested comparison after production is complete.

Scientific settings: center/left/right boundary nodes 512/256/256; Rayleigh M=48 (97 channels); wrapped density-solve proxy H=1.1, distance=.2, side/top=160/160, edge=80, plane waves=32; FMM tolerance 1e-12. B fit: 480 fixed sources, margin .35, H=1.1, 240 collocation nodes per side, 1440-by-610 scaled system, SVD cutoff 1e-14, 195 right-hand sides and 768 source nodes. Reliable targets: 192 center, 64 per lead, 32 junction walls, 32 interior walls, 24 seam pairs; local degree52, real interpolation48, source degree80; 128-bit main/192-bit conversion arithmetic. Center self Kress nodes1152 with adaptive L>=40; finite lead preparation80 plus one adjacent state, relative squared tail <=1e-6, N+10 overlap check. Mass order30; C certificates192/160 bits; band128 bits and169 modes with2048 quadrature points. Detailed domain radii/orders are retained in each target/setup output.

## Accepted reference run-002

The candidate is `1.558437894182088`, binary64 `3ff8ef5c92c5bf30`. The reliable mu interval is `[2.4287286700090116072547296, 2.4287286700363902315765767]`; the k interval is `[1.5584378941776960035929265, 1.5584378941864799995494084]`. The full mathematical width is at most `2.73786243218470e-11` (outward-printed endpoints differ by `2.73786243218471e-11`). Q <= `3.482935419894950973e-12`, U >= `1.23587`, R <= `1.36893121609235e-11`.

| Stage | Driver seconds | Threads/workers | Stage sampled peak GiB |
|---|---:|---:|---:|
| Gap classification + determinant search | 175.575760292 | 11 MATLAB threads | .9882 |
| Density rebuild + export + B fit | 18.249249000 | 11 MATLAB threads | 1.1690 |
| Five residual groups | 528.170423583 | 8 single-thread workers | 1.8191 |
| Independent residual audit | 1.142964667 | 1 | .0068 |
| Eight-disk mass | 20.927044375 | 1 | .1595 |
| Trace constants + assembly | 1.148123375 | 1 | .0025 |
| Complete band certificate | 80.523619125 | 1 | .2061 |
| Preparation, outer startup/output, orchestration and environment | 1.382512874 | — | — |
| End to end | **827.119697291** | — | **1.838531494** |

Short-stage sampled peaks can miss the process maximum. The outer monitor enforces the aggregate resource limit throughout. Worker time is 826.246983875 s; source preparation .001834875 s, seven stage timers 825.737184417 s, orchestration .507964583 s (including .441085417 s of environment metadata). Outer/preflight/exit overhead is .872713416 s. These disjoint parts reproduce the enclosing timer. The residual stage used 3322.105986 CPU seconds. Field work inside MATLAB: rebuild 3.326882375 s, export .680699208 s, B fit 2.977268125 s, fit output .226231625 s. MATLAB startup and exit remain in the corresponding driver stage.

Checks: the nonempty-output refusal was exercised; observed scientific reads were all same-run files; exact k hex passed search-to-export. The independent residual audit reproduced all five upper bounds and covered 408 targets. Two C configurations and 192/160-bit assemblies agree in the printed interval; independent exact rational assembly agrees in printed R. All 472 band signs, four independent inertia checks and the deliberately failing control passed. T1.5 margins exceed .691604670009 and 3.211896329963. The k interval contains the new candidate and overlaps the old enclosure.

Relative changes from enclosure-v1: center/left/right epsilon -0.000535%/-0.3187%/+0.5867%; U +6.52e-15 relative; R -0.3892%. Wall/seam bounds decreased 5.61%/17.30%. New density coefficients differ by about 1e-15, but the rank-258 truncated SVD refit changes central B coefficients by .09957 in L1 (old L1 4.96959). Proxy positions are identical. These small cancellation residuals are sensitive to refitting; all new-field bounds were recomputed. `field-comparison.json` retains the comparison inputs, explicitly used only after production.

The fixed-example conditions are those of the spectral-distance theorem, the ball-certified piecewise field and lead tails, valid interior disks and trace collars, U>Q, and the rounding-inclusive common-gap certificate with its continuous error bounds. The conclusion is at least one point-spectrum eigenvalue in the interval. It makes no uniqueness claim.

## Reproduction and records

Run from the repository working directory, through the permission escalation required for the monitor and MATLAB. The driver itself invokes the copied monitor; do not wrap individual stages with independent reset budgets.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/pipeline-v1/run_pipeline.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/pipeline-v1/output/run-004 --package-root /Users/whc/Documents/Work/dot-research --search-path /Users/whc/Documents/Work/dot-research/test/i9/search-v1 --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --conda /Users/whc/opt/miniconda3/condabin/conda
```

Optional `--resolution coarse` changes native center/left/right nodes to 256/128/128 in search and field generation. The default reference resolution is 512/256/256. No certificate settings change. The driver passes the searched frequency to the explicit field argument; no saved candidate is an input.

Postprocess the accepted run (comparison inputs never enter production):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/pipeline-v1/paper_records.py --run test/bie-bound/pipeline-v1/output/run-002 --baseline test/bie-bound/enclosure-v1/output/run-001/result.json --output test/bie-bound/pipeline-v1/figures
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/pipeline-v1/compare_fields.py --help
```

`figures/geometry.csv` is a seven-cell drawing crop of the infinite geometry; `determinant-nodes.csv` uses the recorded logarithmic normalization; `determinant-coefficients.csv` retains all recorded interpolation degrees; `center-contributions.csv` stores the 192-panel contributions and split metadata. `reference-results.json` and `stage-times.csv` retain raw scalars, model, configuration, environment, checks and timings for independent table reconstruction. Figure arithmetic is ordinary plotting arithmetic and does not feed the certificate.

Environment: Apple M3 Pro, 5 performance + 6 efficiency cores, 18 GiB, macOS 14.8.7; MATLAB 23.2.0.2365128 R2023b, OMP_DYNAMIC=FALSE; Python 3.14.4, python-flint .9.0, FLINT 3.6.0. The FMM2D source is the explicit `vendor/fmm2d/matlab` argument; loaded MEX paths are saved in field dependencies. Preflight ps found no competing heavy scientific process. Environment metadata and actual file-read manifests are in the run.

The FEM comparison is a historical sum, 4009.012 s (P+Q 717.806, A17.595, B1845.260, C1414.214, D14.137), at 11 threads, with width 4.4623318373737675e-9 and rounding excluded. Without B+C the sum is 749.538 s and does not independently certify H. Thus this BIE cold start is 4.85 times faster than the full historical sum, but 10.35% slower than the sum without B+C, while delivering a different existence/uniqueness conclusion. The historical FEM table starts with an available window; BIE also includes 28.014 s of window exploration. Subtracting only that measured stage retrospectively gives 799.105 s versus 749.538 s without B+C (6.61% longer), not a separately measured benchmark. Sources: `research/projects/fem-goerisch/implementation/code-inventory.md:163–178`, `research/projects/fem-goerisch/implementation/pipeline-v1.md:21`, `research/projects/eig-apost/STATUS.md:14`.

## Preserved operational records

Operational run-001 stopped after the completed search: LOCAL_action still called the newly explicit pilot_config without its k argument. Search candidate was 1.558437894182088. Monitored end-to-end 194.896 s, peak .9811 GiB. The configuration is now passed into propagation/action; unused floating-evaluation helpers were removed. No certificate check failed. Run-002 restarts from an empty directory with the same 12–16 minute / 2.5 GiB complete-run forecast and a fresh operational-retry budget.

Optional coarse run-003 forecast, after the accepted full run: 10–14 minutes, peak 2.3 GiB. The sole scientific discretization change is center/left/right native nodes 256/128/128, in both the determinant match and downstream density generation. The initial coarse gap classifier, Rayleigh M=48, fit settings, certificate orders, 80-state preparation, mass disks and band tests remain unchanged. It starts a fresh complete run with its own 30/40-minute result budget. The reference branch retains the accepted numerical path.

## Optional complete coarse run-003

Native nodes 256/128/128 yielded k=1.5584378941820882 (hex `3ff8ef5c92c5bf31`), mu interval `[2.4287265334785796047657683, 2.4287308065668236182364441]`, width <=4.2730882440134706758e-6. End-to-end 744.230028834 s, peak 1.891754150 GiB. All same-run input, dual assembly/rational, residual coverage and 472 band checks passed. The candidate lies in the interval and both intervals overlap.

Stage seconds: search108.941155042, field17.459857375, groups524.118917958, audit1.157600875, mass11.651165542, C/assembly1.164486417, band78.664614375; remaining preparation/startup/output/metadata1.072231250. The sum equals the outer timer. Residual CPU3236.498533 s. The center epsilon is2.1824099293864493e-7 and contributes99.978% of Q=5.43595020563790910899794e-7; right-material epsilon9.656373494227858e-11. This field gives a much wider enclosure despite a candidate only one ulp away. The reference resolution is the paper's narrow-interval row; the coarse run is a measured resolution comparison, not an accuracy-equivalent speedup.

`figures-coarse/` contains the same compact data products for run-003. `figures/resolution-comparison.csv` collects both measured rows. To repeat its postprocessing, use the same paper_records command with `--run .../run-003 --output .../figures-coarse`. Coarse reproduction adds `--resolution coarse` to the driver command and uses a fresh numbered directory.

All three recorded attempts, including the operational failure and the optional coarse result, consumed 1766.245514416 s of driver wall time in total. This cumulative cost is separate from either successful cold-start row. Retained figure CSV/JSON files total under 1 MB; all original experiment outputs remain untouched.
