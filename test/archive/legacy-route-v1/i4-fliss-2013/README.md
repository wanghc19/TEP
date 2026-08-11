# I4 Fliss 2013 dual-track experiment

This isolated experiment compares two deliberately different numerical models
for a line defect that is periodic in $y$ and localized in $x$ at fixed
$\beta$. It does not modify any package or research source file.

## Track A: exact smooth profile

Track A discretizes the Fliss 2013 coefficient with unit periods,

$$
\rho_p(x,y)=1+16\exp\!\left(-\frac{x_{\mathrm{loc}}^2+y_{\mathrm{loc}}^2}{0.2^2}\right),
$$

and replaces the central column $|x|<0.5$ by $\rho_0=1$. Sparse second-order
finite differences solve

$$
-\Delta u=\omega^2\rho u.
$$

The perfect-cell calculation samples the $x$-Bloch parameter on nested grids
to report a discrete band-edge uncertainty. Finite strips use homogeneous
Dirichlet conditions at their $x$ ends, fixed $\beta$ quasiperiodicity in $y$,
and 8/12 perfect-cell tails on each side. Outputs include normalized EVP
residuals, center/end weighted-mass fractions, and the phase-invariant 8/12
weighted-mass-vector overlap.

The positive controls are $(\beta,\omega^2)=(0.5,3.465)$ and
$(1.42,10.46)$. Fliss's prose mentions $1.9$ for the second example while the
figure caption states $1.42$; this experiment follows the figure caption. Only
the first control enters the scientific gate, with the frozen 2% reference
tolerance. The second is diagnostic-only.

The pilot uses a nested-theta diagnostic and is explicitly exploratory. The
baseline uses $N=40$ versus $N=80$ spatial refinement, 81 standard and 81
half-step-shifted theta nodes at $N=80$, and bounded local evaluations near
the reference-adjacent band extrema. Its gap gate requires adjacent-edge
uncertainty at most $10^{-3}$, conservative gap width greater than 20 times
that uncertainty, and candidate margin at least 10 times that uncertainty.
The primary 8/12 tail gate uses relative eigenvalue shift at most $10^{-3}$.
No Track A contrast continuation is run; the output records that gate as
`not-run`.

## Track B: sharp-disk diagnostic

Track B uses the existing public BIE/Bloch packages with a sharp homogeneous
disk of radius $0.2$. Its contrast homotopy is

$$
n(s)^2=1+16s,
$$

and the continuation starts at $s=1$. This is not the smooth Fliss material.
It reports only projected-gap multiplier counts and the scale-normalized
real-axis diagnostic $\sigma_{\min}(A_{\mathrm{def}})/
\sigma_{\max}(A_{\mathrm{def}})$. A dip is not called a root or eigenvalue.
Projected-gap candidates are counted from `count_unit == 0` independently of
whether the outgoing trace spaces are usable. Missing Bloch multipliers or
bad outgoing-mode counts produce the explicit decision
`BIE_MODE_COMPLETENESS_BLOCKED`; they are never summarized as “no gap.”

## Profiles and commands

Run from any directory with the experiment directory on the MATLAB/Octave
path. The shell timeout and the in-process checks both enforce the 10,800
second cap.

Pilot:

```text
perl -e 'alarm shift; exec @ARGV' 10800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_i4_fliss_experiment('pilot');"
```

Baseline:

```text
perl -e 'alarm shift; exec @ARGV' 10800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_i4_fliss_experiment('baseline');"
```

Generated files are confined to `output/pilot/` or `output/baseline/`:

- `results.mat`
- `run.log`
- `config.txt`
- `report.md`
- `exact-bands.csv`
- `exact-strip-modes.csv`
- `exact-tail-comparison.csv`
- `bie-samples.csv`
- `bie-summary.csv`
- `negative-controls.csv`

The no-defect Track A strip, manufactured end-supported vector, exact analytic
homogeneous-medium Track B scan, and explicit no-root-claim gate are required
negative controls.

## Independent follow-up diagnostics

The targeted strong-edge confirmation evaluates only the band-1 upper edge
and band-2 lower edge near the baseline $\theta=-\pi$ extremizer. It uses 11
shared bounded theta samples at each of $N=80$ and $N=120$, which is below the
12-EVP-per-edge-per-$N$ limit. A nested coarse subset of those same samples
contains $\theta=-\pi$ and supplies the fine-versus-coarse $\eta_\theta$
terms; no extra EVP is added. It writes only to
`output/targeted-edge-confirm/`.

```text
perl -e 'alarm shift; exec @ARGV' 1800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_targeted_edge_confirm();"
```

The sharp-disk pencil diagnostic reconstructs only the frozen
$k=1.85$, $s=1$, $\beta=0.5$ sample for $M=10$ and $M=5$. It records the
singular values and numerical ranks of both transmission blocks and the
projective QZ $\alpha/\beta$ classification. It does not repair package mode
extraction or make a defect-root claim. Its outputs are confined to
`output/bie-pencil-diagnostic/`.

```text
perl -e 'alarm shift; exec @ARGV' 1800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_bie_pencil_diagnostic();"
```

The single-point bidirectional pencil diagnostic evaluates the frozen
$k=1.85$, $s=1$, $\beta=0.5$ cell for $M=5$ and $M=10$. It obtains the
right-port basis from $A v=\lambda Bv$ and the left-port basis directly from
$Bw=\mu Aw$, without forming reciprocal multipliers. The readiness gates
cover exact small-multiplier counts, per-mode residuals, conjugate pairing,
port-local trace normalization/rank/conditioning, the applicable $M=5$
legacy span, and three fixed complex column-rescaling tests of the normalized
$A_{\mathrm{def}}$ diagnostic. Outputs are confined to
`output/bie-bidirectional-pencil/`. The expected runtime is 5--15 seconds,
with a hard 60-second cap.

```text
perl -e 'alarm shift; exec @ARGV' 60 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_bie_bidirectional_pencil_diagnostic();"
```

The bounded M4/M5 scan uses the same 49 real-axis points on
$[1.55,2.15]$ for both truncations. Every usable point passes mode-count,
two-sided outgoing-count, unit-circle exclusion, and normalized Bloch
residual gates. Only matched strict interior coarse minima are refined in
their neighboring coarse intervals; endpoint and global fallbacks are
disabled. This is a non-gating smoke diagnostic: it does not create a root,
eigenvalue, or downstream seed claim. The strongest possible label is
`M4_M5_STABLE_REAL_AXIS_DIP_DIAGNOSTIC`. Outputs are confined to
`output/bie-m4-m5-scan/`.

```text
perl -e 'alarm shift; exec @ARGV' 1800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_bie_m4_m5_scan();"
```

## Executed status

- Pilot and baseline completed with exit code 0. The baseline took
  401.53 seconds.
- `targeted-edge-confirm` completed in 2.48 seconds and passed with
  $\varepsilon_{80,120}=7.91\times10^{-4}$, safe gap
  $(1.981350,5.386819)$, and candidate $\lambda_h=3.460975044$.
- `bie-pencil-diagnostic` completed in 1.97 seconds and identified the
  transmission-rank mechanism behind the missing M10 multipliers.
- `bie-bidirectional-pencil` completed in 2.06 seconds. M5 and M10 were both
  blocked by the frozen mode-residual and reciprocal-pairing gates, despite
  full-rank normalized traces.
- `run_bie_m4_m5_scan` is implemented but deliberately not run. Its upstream
  port-basis authorization failed, so any legacy real-axis dip would be
  non-gating and scientifically uninterpretable.

The current combined verdict is `I4_FD_CANDIDATE_READY` for the exact smooth
Track A and `BIE_PROJECTIVE_SUBSPACE_BLOCKED` for the sharp-disk Track B.
