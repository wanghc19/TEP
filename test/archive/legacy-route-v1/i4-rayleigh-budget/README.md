# I4 Rayleigh-budget experiment

This isolated experiment measures the cost and raw numerical evidence needed
to define two Rayleigh truncation budgets for the sharp-disk I4 cell. It calls
or locally composes existing package operations and does not modify `+bloch`
or any research source.

The currently runnable smoke path uses the frozen physical point
$\delta=0.30$, $R=0.20$, $k=1.8603695988$, $\beta=0.5$,
$n=\sqrt{17}$, and $L=d=1$. Its low reference level uses `ntot=80` and
`Ny_wall=512`. One master BIE solve contains all incident orders through
$M=8$; extraction uses $M_{\mathrm{out}}=70$. Every square $S_M$ for
$M=0,\ldots,8$ is a central input/output restriction of that same master
response with the direct phase embedded. The driver therefore does not repeat
`construct_S` or the BIE solve for each $M$.

For the future $M_{\mathrm{trace}}$ decision, the smoke output records
$M=5,\ldots,70$ tails of the $|m|\leq5$ physical BIE response columns in the
weighted Cauchy norm

$$
\sum_m \left(\langle\xi_m\rangle |D_m|^2+
\langle\xi_m\rangle^{-1}|N_m|^2\right),\qquad
\langle\xi_m\rangle=\sqrt{1+|\beta_m|^2}.
$$

Direct-wall Dirichlet and derivative projection is retained as an upstream
extractor-validation check only. The required `ntot=120`, `Ny_wall=1024`
reference-change gate is not yet executed by this scaffold, so
$M_{\mathrm{trace}}$ is explicitly `NaN` and `INCONCLUSIVE`.

The tail table keeps three quantities separate: the outgoing spectral tail,
the direct-wall projected tail, and their common-mode discrepancy. A noisy
direct-wall floor and the spectral representation's own tail are diagnostics,
not self-certifying evidence for a truncation decision.

For the future $M_{\mathrm{stable}}$ decision, each square restriction records
projective ordered-QZ stable/unstable subspaces, including regular infinite
pairs in the unstable subspace, deflating-subspace residuals, graph and
Riccati fixed-point residuals, and finite-depth Redheffer-doubling reflection
and weighted DtN-action discrepancies. Deterministic relative scattering-data
perturbations of $10^{-12}$ and $10^{-10}$ record the induced weighted
DtN-action condition metric and test the frozen $\kappa\leq 10^4$ bound.
Transmission-block rank is a ledger only, never a gate. The cross-`ntot`
robustness comparison is not yet implemented, so $M_{\mathrm{stable}}$ is
still explicitly `NaN` and `INCONCLUSIVE`.

## Commands

Smoke is the only currently prioritized runnable profile. Its expected runtime
is approximately 3--15 minutes, with the frozen 90-minute hard cap:

```text
perl -e 'alarm shift; exec @ARGV' 5400 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); results=run_i4_rayleigh_budget('smoke');"
```

The refined single-point reference keeps the same physical point and
extractor gate, while using `ntot=160`, `Ny_wall=2048`, and proxy sizes
`N_side=N_top=120`, `N_proxy_edge=64`, `M_pw=24`:

```text
perl -e 'alarm shift; exec @ARGV' 5400 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); results=run_i4_rayleigh_budget_hi_reference();"
```

The single-run `core` and `stress` entry points exist for timing-schema
continuity. Use the batch entry point below for the frozen multi-$\delta$,
multi-$k$, and control workload; none of these entry points alone certifies a
decision:

```text
perl -e 'alarm shift; exec @ARGV' 5400 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); results=run_i4_rayleigh_budget('core');"
```

```text
perl -e 'alarm shift; exec @ARGV' 5400 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); results=run_i4_rayleigh_budget('stress');"
```

The restartable bounded batch is the frozen expanded workload. It runs the 15
low core cases, the three low scale controls, and then the three central-$k$
high cases in endpoint-priority order. The outer alarm and the driver both
enforce the 90-minute cap:

```text
perl -e 'alarm shift; exec @ARGV' 5400 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); batch=run_i4_rayleigh_budget_batch('all');"
```

If the measured ETA cannot accommodate all three high cases, the preregistered
fallback keeps only the $\delta=0.30$ and $\delta=0.10$ high endpoints:

```text
perl -e 'alarm shift; exec @ARGV' 5400 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); batch=run_i4_rayleigh_budget_batch('all-endpoints');"
```

The batch reuses case-local `results.mat` files, writes its summary after every
case, reports low-only cases as `DESCRIPTIVE/REFERENCE_UNCERTIFIED`, and never
turns a provisional per-case budget into a certified global interval while the
reference envelope remains open.

The aggregate separates three meanings that must not be conflated:

- `map_pass_through` is the largest continuously passing same-$M$ QZ,
  doubling, conditioning, and perturbation check from $M=5$ upward. Reaching
  $M=20$ is right-censored pass-through, not a known upper stability boundary.
- `M_action_onset` is the first truncation whose QZ-to-$M=20$ weighted action
  comparison then stays within tolerance; `ntot_action_onset` is the analogous
  independent low/high sensitivity onset.
- `prefix_protocol_M_stable` retains the frozen composite protocol outcome.
  A missing value is not interpreted as algorithmic instability.

For paired high cases, `M_req_candidate` is the maximum of the provisional
spectral trace candidate and the two action onsets. The observed usable-window
fields state whether that requirement lies inside the same-$M$ pass-through
range; all such windows remain reference-uncertified.

The low/high sensitivity gate uses the frozen
`ntot_action_tolerance=1e-7`. `ntot-action-ledger.csv` records, for every
paired high case and every tested $M$, the plus/minus/max weighted action
change, exact low/high output provenance, classification preservation,
same-$M$ gates, and the resulting sensitivity pass. The case summary names
the retained composite-protocol diagnostic
`paired_action_change_at_prefix_endpoint` and separately reports the action
changes at `ntot_action_onset` and `M_req_candidate`.

Reports already stored inside individual case directories are deliberately
case-local: they do not perform low/high pairing. The batch aggregate and its
action ledger are the authority for pairwise `ntot` sensitivity evidence.

After a completed or externally interrupted run, rebuild only the aggregate
from existing case files without recomputing any missing case:

```text
conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-rayleigh-budget'); batch=run_i4_rayleigh_budget_batch('all',true);"
```

Runtime provenance is split explicitly. `summed_case_seconds` is the sum of
the completed numerical case runtimes, while `aggregation_elapsed_seconds` is
only the time spent loading saved results and rebuilding the aggregate. The
original end-to-end numerical batch wall time is not reconstructed from an
aggregate-only run and is therefore not reported as `elapsed_seconds`.

Each profile writes only beneath `output/<profile>/`:

- `results.mat`
- `run.log`
- `config.txt`
- `report.md`
- `rectangular-summary.csv`
- `trace-spectrum.csv`
- `trace-tail.csv`
- `square-summary.csv`
- `transmission-ledger.csv`
- `perturbation.csv`
- `doubling.csv`
- `timings.csv`

Batch summary directories additionally contain `manifest.csv`,
`case-summary.csv`, `ntot-action-ledger.csv`, `gate-summary.txt`,
`global-summary.txt`, and `batch-results.mat`.
