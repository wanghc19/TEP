# `tep_debug_tblock.m` Note

This diagnostic compares three T-block views for one fixed test case:

1. the old KR/reference T-block from `tep_scan_local2.m`
2. the current Kress-style T-block from `tep_scan_local3.m`
3. decomposition-level quantities:
   - raw T-difference kernel
   - logarithmic part `log_kernel .* N1diff`
   - smooth remainder `N2diff`

For selected rows near the diagonal, the script prints and plots:

- `raw_difference`
- `N1diff`
- `log_part`
- `N2diff`
- new Kress T-block entry
- old/reference T-block entry
- their difference

Symptoms to watch for:

1. bad `N1diff`:
   - diagonal value not near zero
   - nearest-neighbor values do not decrease toward the diagonal

2. bad `N2diff`:
   - large spikes, blow-up, or strong oscillation near the diagonal

3. failed cot cancellation:
   - large residual in the printed cot-cancellation check

4. old/new T-block mismatch:
   - near-diagonal `|new T|` much larger than `|old T|`
   - large rowwise magnitude separation in the semilogy plots
