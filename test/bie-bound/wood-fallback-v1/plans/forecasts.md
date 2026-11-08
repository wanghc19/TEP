## Forecasts and boundaries

Run 001 repeats the regular-window example-1 regression, coarse determinant search only, 20–90 s and 1.1 GiB. Source functions and launcher/monitor were copied from pole-free-v1. Five computational threads, 2 GiB peak and no field files. The half-width 0.02 window about Wood omits both detuning 0.1 controls by construction. Those roots require additional regular windows centered on the prior branch frequencies.

Run 001 returned 1.5584378941820876, within 4.45e-16 of the reference. Run 002 tests four searches at the Example 1 positive 0.0001 branch phase. Forecast 2–10.5 min and 1.2 GiB, 150 s per frequency search, plus startup and field diagnostics. The cap is checked before each cell evaluation.

Run 003 compares the original and distance-reuse proxy fits at three frequencies and repeats the regular regression through the guarded search. Forecast 20–80 s, under 1.2 GiB. The local fit preserves the outgoing least squares matrix, ordering and right-hand side, and evaluates each distinct binary64 Hankel radius once.

Run 003 gave identical proxy coefficients at all three test frequencies; the guarded regular search returned 1.5584378941820878. Run 004 forecasts 2–4 min and 1.3 GiB for eight regular-control searches (two branch signs, both routes and grids). Run 005 forecasts 2–5 min and 1.4 GiB for twelve local reference roots and Green sensitivity checks. The changed fit uses 192 side/top and 96 proxy sources per edge, exact Fourier data at the two remote boundaries and FMM tolerance 1e-14. Timing includes a new density and lead solve for each frequency.

Runs 006–007 pilot the fine Example 1 grid and the W3 two-row lead. Planned times 200 s / 280 s respectively, peak below 1.4 GiB each. Each search independently guards physical frequencies before cell assembly, including node tests and Newton polish. Both data sets use the physical acceptance criteria of pole-free-v1.

### Reuse across widths

The initial half-width 0.02 search excludes 0.01. For a smaller exclusion, search only the two newly admitted strips. Reuse the frequency intervals and physically tested proposals on the unchanged outer panels. Both routes share the initial outer plain panels. Each subsequent strip uses its route's own chart and interpolant. The tables give the new strip cost and cumulative cost separately. The 150 s search cap includes the elapsed determinant work of reused panels. An unfinished outer search prevents a completion claim at the next width. The independent-window pilot uses no such reuse.

Runs 008 and 009 are nested pilots on both grids for Example 1 at positive detuning 0.001 and W3 at negative detuning 0.0001. Forecasts 9.6 / 6.7 min, 1.4 GiB each, below 1 MB output. For the field decision only, the local copy skips the unrelated volume energy, horizontal seam and old divided closure. The material and four-wall quadratures and their thresholds are unchanged.

The retained-window branch test uses the square-root interpolant on each side of Wood. Width does not vary in this test, so each phase is an independent two-grid search. Only independently paired physical proposals receive a changed-Green calculation. Frequencies interpolated inside the band are branch estimates and never seed a search.

Forecasts for subsequent serial blocks (1.4 GiB each, under 1 MB output per block): run 010 outer strips 430 s, 011 branch phases 1–5 440 s, 012 outer strips 500 s, 013 branch phases 6–10 440 s, 014 outer strips 275 s, 015 branch phases 11–15 440 s. The forecasts include the fine grid and physical tests; the scan blocks include a local reference for paired roots. Narrow strips are scheduled subject to the remaining 5400 s: W3 600 s, closest Example 1 phases 620 s, intermediate phases 900 s and outermost phases 680 s. A block whose forecast does not fit is deferred. The earlier pilot roots for a matching phase, grid, route and width can be explicit outer-panel inputs.

Run 010 also extends the completed independent square-root panels to 1e-5 for the fine closest positive Example 1 phase and both positive 0.01 W3 grids. Its revised forecast is 780 s, still under 1.4 GiB. These handoffs retain the cumulative 150 s search allowance and save the outer-panel costs as separate records.

The W3 negative 0.0001 pilot took 581 s for both grids. The forecasted 600 s narrow-W3 block therefore covers only the positive 0.0001 phase. Any further phase is scheduled separately against the remaining compute allowance.

Run 016 extends both square-root grids at Example 1 positive detuning 0.01 from 0.001 to 0.0001. Forecast 245.1 s, 1.4 GiB and less than 1 MB; 504.1 s of compute remained before launch.

Run 017 extends the two run-016 records to 0.00001. The coarse outer strip completed and the fine outer strip reached its cap. Forecast 69.9 s, 1.4 GiB and under 1 MB; 325.4 s of compute remained.

Run 018 measures the remaining fine-grid plain search at Example 1 positive detuning 0.0001, exclusion 0.0001. The coarse independent pilot used 122.15 s. The fine-grid forecast with the completed outer handoff is 113.6 s of additional monitored time, 1.4 GiB and under 1 MB; 272.0 s remained.

Run 019 compares the fine-grid plain strip with the run-016 square-root strip at Example 1 positive detuning 0.01, exclusion 0.0001. Forecast 114.0 s, 1.4 GiB and under 1 MB. The two-grid block did not fit the 173.8 s remaining.

Run 020 checks the fine-grid frequency reference at the four nearest nominal phases (both signs and both models). Compare 192/96 with 224/112 boundary points/proxies per edge at the same spectral boundary data and FMM tolerance. Run 005 took 153 s for 12 local pairs including sensitivity calculations. Forecast 72 s for four pairs without sensitivities, 1.4 GiB and under 1 MB. No remaining width test fit the 102.7 s allowance at its prelaunch forecast.
