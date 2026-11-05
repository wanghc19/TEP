# Cell kernel field fit version 1

cellfit means cell kernel field fit. BIE means boundary integral equation; MFS means method of fundamental solutions; CM means compressed source moments; SVD means singular value decomposition; RSS means resident set size. Arb/Acb are real/complex ball arithmetic.

Purpose: compare all five floating residual groups for per-kernel A and per-field B, then measure reliable pilot targets. Inputs and outputs are explicit; earlier experiments are read-only.

Plan: one MATLAB process rebuilds the common field once, exports A and the 195-column B fit, then evaluates both groups at 768/1536 sources. Prior A new-only cost is about 300 s. Forecast including B: 450–700 s, under 2.2 GiB (prior whole comparison 1.43 GiB). Source and material matrix storage remain transient. Run-001 budget 30/40 minutes, 3 GiB; output forecast below 30 MB. Arb forecasts will follow the exported coefficients and pilot.

run-001 stopped after field construction: MATLAB decoded heterogeneous JSON pieces as a cell array; the input check used parentheses instead of braces. run-002 uses the corrected JSON indexing, with the same 450–700 s and 2.2 GiB forecast.

run-003 forecast: 900–1500 s and below 2.4 GiB for the old-kernel central reproduction, shared n=80 source contractions, central A/B polynomials and independent controls, one full 194-column right-lead material map, and one physical right junction wall/top seam segment. MATLAB run-002 completed before this launch. Fixed-point harmonic tables are reused between center and right-lead coefficients. The lower-order comparison uses central A M=80 to 76; a 32-mode drop at that local truncation is predicted to exceed CK12, so four modes are removed instead. No field or full matrix cache is written to disk.

run-003 reproduced both old proxyagg e_I values, then stopped in the new distance-bound implementation: a real-valued Acb distance was passed to Arb's `lower()` method. The fix checks zero imaginary part and extracts the real ball. run-004 retains the same forecast (900–1500 s, below 2.4 GiB), skipping only the already completed old-baseline rerun. All failed output is retained.

run-005 forecast: 400–650 s, below 1.0 GiB. This supplementary check rebuilds the compact in-memory expansions and adds independent full-residual controls for the right-lead material, wall and seam pilots. The lead uses 2304-source Kress sums at 256 bits; wall/seam controls use direct source CM and point-source sums. It records the actual exterior-proxy clearance and target complex-image checks. It does not run a whole curve or refit a field. Headline production timings remain run-004; controls have their own timers.

## Entry points and numerical definition

- `launch.py` / `field_budget.m`: rebuild the common MATLAB field, fit/export both definitions, and evaluate five floating groups. `field_fit.m` performs one scaled SVD for 195 right-hand sides. Auxiliary outgoing amplitudes are fit variables only, not part of the new field.
- `launch_arb.py` / `central_pilot.py`: exact-input Arb pilots, with optional `--baseline` for the old wrapped kernel and `--extended` for the lead/wall/seam targets.
- `expansion.py`: source moments and regular Helmholtz coefficients. Moment balls remain in all coefficient and node operations; CK6's moment-radius term is therefore paid in final node radii, not added again.
- `extended.py`, `lead_self.py`, `map_models.py`: full lead matrix models, Kress self-interaction, polynomial integration and propagation tails. CM means compressed source moments. RE/CK/SI are the equation labels in the project theory notes.
- `verify_targets.py`: independent 256-bit full-residual controls; it uses 2304 Kress sources for the lead and direct source/point sums for walls and seams.
- `cost_update.py`: explicit scalar postprocessor for the measured-component extrapolation.

The original exact input is copied under `output/input/`; `copy-check.json` records equality with the supplied input. A's 480 coefficients and B's center/left/right matrices are newly fitted and stored in `run-002/coefficients.json` as exact binary64 hexadecimal data. All later ball calculations use those inputs. The exact phase is exp(i beta d), and Rayleigh exponents satisfy the exact dispersion relation.

A uses three near images and moving proxy layers. B retains the same near images and interior field, replacing only the exterior proxy correction by 480 fixed point sources. Proxies lie on physical x=+-1.45 or y=+-1.35. Actual saved coordinates and analytic source domains have positive clearance. Seam signs are phase*bottom-top for value, top-phase*bottom for the y derivative. Five-group floating tails use the original 40-cell rule; the reliable lead pilot instead proves the Frobenius contraction and uses CK19/CK20a.

Source models use 160 center / 64 lead panels, degree 80, radii .055 / .12. Center near-image expansion: R=.6, M=128; lead: R=.6, M=72. A proxy: R=.9, M=288 globally, truncated to 80/64 at center/lead material nodes. B: R=1.1, M=144 globally, 52/64 at material nodes. Boundary near-image regions use M=80, R=.08/.16 for wall/seam. J=14 regular basis terms; 48 real Chebyshev nodes, rho=4.5; node arithmetic 128 bits, conversion 192 bits. The central self/local path is unchanged. Lead self-interaction uses the exact trilobe geometry and rho=17 in the same radial/Kress formulas, N=1152, L=48, target radius .12 and source strip .16; all speed, divided-chord and Q3 checks execute.

## Reproduction commands

Run from the stated repository; use a fresh output number when reproducing. The monitor owns time and process-tree memory enforcement. MATLAB uses 11 threads; Arb uses one thread.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellfit-v1/launch.py --input test/bie-bound/cellfit-v1/output/input/fixed-input.json --output test/bie-bound/cellfit-v1/output/run-002 --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellfit-v1/launch_arb.py --output test/bie-bound/cellfit-v1/output/run-004 --conda /Users/whc/opt/miniconda3/condabin/conda --script central_pilot.py --forecast 1500 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/cellfit-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/cellfit-v1/output/run-002/coefficients.json --extended
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellfit-v1/launch_arb.py --output test/bie-bound/cellfit-v1/output/run-005 --conda /Users/whc/opt/miniconda3/condabin/conda --script verify_targets.py --forecast 650 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/cellfit-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/cellfit-v1/output/run-002/coefficients.json
```

Run-003 used the central-pilot command with `--baseline --extended`. The old path finished before the operational distance-type error. Its two `old/new-panel-*.json` files give the exact baseline reproduction. Run-004 skipped this completed check.

## Floating results

All rows below use 1536 material/source nodes and 768 wall/seam targets; source doubling changes only wall/seam evaluation. Source counts are 768 and 1536.

| Group epsilon | A | B |
|---|---:|---:|
| Center material | 1.261365494476923e-12 | 1.261067545508922e-12 |
| Left material and tail | 6.257096588750796e-14 | 6.099776372973704e-14 |
| Right material and tail | 6.604229998350952e-14 | 6.361665236378694e-14 |
| Walls and tail | 2.145943333075345e-13 | 2.156101615888481e-13 |
| Seams and tail | 9.605025927078110e-15 | 7.095361405873469e-15 |
| Q | 3.528353283534536e-12 | 3.521213646758767e-12 |
| Predicted full width, U=1.23587 | 2.773564461541605e-11 | 2.767952142922023e-11 |
| Sum C_g abs(delta epsilon), 768 to 1536 | 1.299540596759476e-16 | 1.358048035880012e-16 |

Q_B/Q_A=.9979764960586325. The largest relative change from the old A table is 1.542e-8; center 4.379e-9. Both floating gates pass. These Q/width values use the existing floating trace constants, not completed reliable group bounds.

## Reliable pilot results

The following displayed e values are rounded upward. They bound model error for the exact saved field under CK/SI domain conditions checked by the code. V is the new residual polynomial's integral, recomputed rather than reused from an old kernel. Only the stated pilot segments are covered.

| Target | A e_I | B e_I | A V | B V |
|---|---:|---:|---:|---:|
| Center panel 0 | 2.387678e-18 | 2.403277e-18 | 1.2684042645e-29 | 1.2519163497e-29 |
| Center panel 1 | 3.296929e-18 | 3.312528e-18 | 1.4713085101e-29 | 1.4216459981e-29 |
| Right junction wall | 3.388617e-22 | 6.694983e-23 | 1.7055624391e-27 | 1.6360607649e-27 |
| Center top/bottom seam pair | 2.020852e-22 | 4.284278e-23 | 5.6495560764e-31 | 5.6310276150e-31 |
| Right material map, all 97 states | 1.140731e-20 | 1.022515e-20 | 5.4673895426e-29 | 5.2939734586e-29 |

For the lead row, V is the Frobenius map integral. The finite 40-cell polynomial integrals are 6.4267312722e-29 / 6.2225843694e-29. The corresponding segment epsilon upper bounds including infinite tails are 8.016694e-15 / 7.888340e-15. Every source map has all 194 port columns before multiplication by G. For B, the fixed proxy has 97 state columns. With p=1, ||P||_F<.386733375; S_w<.674163568, S_v<1.176242795 and ||P^40 c||<2.340647e-17. CK20a gives segment operator constants below 7.394184e-15 / 7.275973e-15 and tail squares below 3.522165e-62 / 3.410448e-62. The implementation combines to one state-map error and multiplies by sqrt(S_v), a conservative version of CK18 retaining polynomial cancellation.

Central self errors remain 2.342775e-18 / 3.264226e-18; local tails 4.073029e-20 / 2.852974e-20. Total smooth errors are A 4.172838e-21, B 1.977158e-20. Node errors stay below 2e-20 and conversion below 1e-21. Both CK13 gates pass. The lead's self interpolation error is below 7.619068e-22 and local error below 1.063874e-29; full per-term ledgers are in the JSON files.

## Primary measured costs

| Component | A seconds | B seconds | Boundary |
|---|---:|---:|---|
| Fit all coefficients | .74146 | 3.00985 | MATLAB, all templates |
| Center proxy expansion | 44.81626 | .16351 | Arb, shared source setup separate |
| Right-lead proxy expansion | 56.20438 | .36131 | All columns; B reuses center point table |
| Center panel 0 non-self | .26492 | .24769 | Includes local terms, nodes, conversion and combination |
| Center panel 1 non-self | .28000 | .25586 | Same boundary |
| Right-lead material target | 13.85012 | 12.79832 | Self, local, nodes, model/state algebra; no setup/controls |
| Right junction wall online | 10.03915 | 4.16238 | Both traces, actual first-cell state |
| Seam pair online | .43042 | .25873 | Both traces |

Shared setup: center source 27.17687 s, center near .86055 s, right-lead source 38.15853 s, right-lead near 14.11445 s. A center boundary near region costs 1.46–1.49 s; the full 194-column right-lead wall region costs 22.75855 s, of which 22.39430 s is matrix formation/contraction. Center self time is 1.66747 / 1.58039 s. Lead self total 4.91178 s comprises .13349 domains, .70779 source grid, 1.93579 kernel, 2.07803 matrix multiplication, .05494 conversion and small remainder. Lead local terms cost 4.12593 s. A/B lead nodes cost 3.78878/2.89428 s, model algebra .67865/.51710 s, state/norm .34498/.34923 s. Independent controls are additional: A central proxy about 72 s per panel versus B .18–.19 s; no control time is hidden in the online rows.

## Checks and resource records

- A group reproduction: maximum relative difference 1.5412963351e-8 (central 4.3786494430e-9), below 1% / .01%. Old wrapped-kernel e_I exactly reproduces 2.6495208364838675e-18 and 3.558771497506436e-18.
- Both weighted source-doubling changes are below 1e-14. Q_B/Q_A passes 1.1. All central tight gates pass.
- B direct point sums and regular expansions agree inside the error radii, for center and all lead columns. Independent full-residual controls at 256 bits also pass: maximum lead/wall/seam differences below 6.98e-36 / 1.17e-35 / 1.58e-35. The lead control doubles Kress sources to 2304. A wall/seam use one independent point each, B uses three each. Repeating the extended targets did not change any displayed e_I/e_map value.
- Polynomial Gram integration and independent Gauss integration have maximum relative difference 1.4966859653e-38. A's actual material truncation 80 to 76 changes the physical tail by 39.0563637931, equal to the CK9 prediction, and e_I remains 2.3904229426e-18 below its gate.
- The actual input copy, aggregate checks and monitor values are recorded in `output/input/copy-check.json` and `output/checks.json`. Raw finite-ball ledgers and polynomials are in the individual run files. No whole-curve reliable bound is asserted here.

| Run | Purpose | Monitor wall s | Peak process-tree GiB | Outcome |
|---|---|---:|---:|---|
| 001 | Floating startup | 24.3482 | 1.0393 | JSON cell-array indexing error |
| 002 | A/B five groups and fit | 328.9194 | 1.5498 | Passed |
| 003 | Old baseline plus new setup | 102.1001 | .2117 | Baseline passed; Acb/Arb distance accessor error |
| 004 | Primary reliable pilots | 401.7920 | .3692 | Passed; CPU 394.6745 s |
| 005 | Full independent target controls | 377.3666 | .5086 | Passed; CPU 370.9722 s |

Total monitored time, including failures: 1234.5262 s. Main Arb calculations are serial; no parallel result is claimed. The experiment retains about 15 MB, below 100 MB. Failed logs remain in place. MATLAB/Arb monitor commands and resource samples are retained per run.

## Updated cost projection and decision

The measured full-column work changes the prior cost forecast substantially. `cost_update.py` predicts from the actual primary pilot; it does not optimize or run the full pipeline. It counts 192 central and 128 lead material panels, 48 center boundary faces and 96 lead boundary faces. A right-lead region represents the unmeasured left/remaining regions. Online center-face work uses half the measured seam pair; lead-face work uses the measured junction pair less that center estimate, plus the measured full state/norm algebra. All 144 boundary-region setups are counted, and the lead source grid is conservatively rebuilt at the measured per-target price. For controls, the same three-point policy is applied to two center material panels and one wall/seam panel per template; charging a measured junction pair to each template is a conservative planning rule.

| Predicted cost | A | B |
|---|---:|---:|
| Shared/fitted/region setup, s | 2546.14 | 2392.07 |
| Material online, s | 2136.92 | 1998.32 |
| Wall/seam online plus state algebra, s | 986.55 | 426.91 |
| Independent controls, s | 977.24 | 15.00 |
| Shared mass allowance, s | 34.70 | 34.70 |
| Serial total, min | 111.36 | 81.12 |
| Eight-worker wall prediction, min | 54.03 | 47.00 |

The eight-worker formula is setup + 34.7 + (online + controls)/(8*.7751952721), with all setup paid serially. The efficiency and mass allowance are prior measured inputs to the projection. The remaining wall-clock behavior, left-template costs, different target domains, coefficient distribution and complete eight-worker memory are unmeasured. The main increase over the old 26.3/18.8 minute serial forecast is 2255.56 s of ordinary-image boundary-region preparation with full columns, followed by lead local/self/matrix algebra. B removes the expensive moving-proxy preparation and controls, but it does not remove these shared costs.

Both eight-worker predictions are below FEM's 67 min wall, for residual evaluation only. Reliable trace constants C_g, the band-gap certificate when identifying an eigenvalue, and actual coefficient distribution remain outside the measured boundary. This is not a measured end-to-end speed comparison.

Decision: use B for the next whole-curve computation with the saved run-002 coefficients. Both decisive gates pass: Q_B <= 1.1 Q_A with settled source doubling, and center e_I/online non-self time satisfy the tight limits. The complete reliable five-group interval still requires the remaining panels and trace constants.

```sh
python3 test/bie-bound/cellfit-v1/cost_update.py --floating test/bie-bound/cellfit-v1/output/run-002/result.json --primary test/bie-bound/cellfit-v1/output/run-004/summary.json --controls test/bie-bound/cellfit-v1/output/run-005/summary.json --output test/bie-bound/cellfit-v1/output/cost-projection.json
```
