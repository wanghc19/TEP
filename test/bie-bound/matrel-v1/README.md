# Material reliable pilot, version 1

`matrel` means material reliable. BIE means boundary integral equation, FEM means finite element method, MFS means method of fundamental solutions, CM means compressed source moments, RSS means resident set size, CSV means comma-separated values and JSON means JavaScript Object Notation. Arb and Acb denote arbitrary-precision real and complex ball arithmetic. The filename suffix config denotes configuration. Q5 is the single-disk mass check used in budget-v1.

The accepted result is a reliable upper bound of **4.671678e-15** on the contiguous angular interval $[0,\pi/48]$. The same interval's ordinary floating estimate is 2.4491864e-15, giving a ratio of 1.90744. This covers two of the 192 target panels. The full-curve floating epsilon is 1.2611637248633255e-12. The eight interior disks give **U >= 1.23587120**.

At degrees 52 and 40, the isolated target and mixed coefficient prices are 1.889 and 4.221 historical Arb kernel units respectively. The 320 accepted mixed generations average 4.355 units. A full center at the measured settings projects to 157.84 minutes. RE31 projects to 126.15 minutes with the original 15360 generation count, or 245.36 minutes with the measured central counts and design counts for the remaining templates. The Kress computation takes 27.31 s per target panel. Other geometries use the central prices in these projections. Extra wall subdivision, lead-state algebra/tails and trace-constant certificates are unmeasured.

## Field and mathematical conventions

`export_fixed.m` copies the fixed-field construction from switch-rel-v1. In one MATLAB process it builds the field, reproduces Q5 with relative error zero, computes the budget-v1 floating 1536-node central residual and selects disks by the original budget-v1 procedure. The hexadecimal export includes the center incident amplitudes and integer Rayleigh mode indices. The accepted calculation reads only its own run's export. Exact $e^{i\beta d}$ and exact-dispersion Rayleigh exponents are the field convention. Material self-interactions have branch index zero. The angular-variable integrand is $\sqrt{|r'(\theta)|}(J_1,J_0)$ with $\ell_g=1$. The sign of the second raw Müller row is reversed to obtain $J_1$.

`material.py` builds the target/source derivative matrices and measures the coefficient price. For a Helmholtz kernel, $U_d=(\partial_x-i\partial_y)/k$ and $U_d^{-1}=-(\partial_x+i\partial_y)/k$ multiply to one. A spatial translation has symbol $\exp[k(\delta z U_d-\delta w U_d^{-1})/2]$, where $\delta z=\delta x+i\delta y$ and $\delta w=\delta x-i\delta y$. Expand target and negative source translations to the indicated angular Taylor degrees. Between their coefficient matrices put the sum of the 320 charged spatial derivatives with Laurent index equal to the sum of the two translation indices. Hankel orders are generated from $H_0,H_1$ by the order recurrence. Source Jacobians, both normals and target weights are incorporated in these matrices. This factorization computes the CM mixed jets of the same smooth proxy kernel as the radial recurrence RE28. Four zeroth-order entries overlap an independent direct gradient/Hessian calculation. At each measured pair, the entire zeroth source column overlaps the separately computed target-only jet.

`self_interaction.py` evaluates the signed ordinary free-space difference $\Delta G(q)=a(q)\log q+b(q)$ using Q3. It forms the log-sine split before integration, including the direct hypersingular cancellation. The chord $D=(r(t)-r(s))/(2\sin((t-s)/2))$ is evaluated by finite trigonometric differences on the complex domain. The quotient $q_t q_s/q$ reduces to $4(D\cdot n_t)(D\cdot n_s)/(D\cdot D)$. The entire series through order 40 include a common positive majorant on the remaining coefficients of $a,b$, their first two derivatives and $a/q$. With $j=41$ and $v=2k^2$, the first omitted majorant is $100(j+1)^3v^j/(j!)^2$ on $|q|<2$ and successive ratios are at most $v(j+2)^3/(j+1)^5$. This uses the harmonic number bound $H_j\le j$. Source and target complex boxes must certify positive real parts for both speeds squared and the divided chord squared.

For the accepted panels, `panel.py` uses 192 target and 160 source panels, $p=52$, $n_s=40$, $R_t=0.04$, $R_s=0.055$ and source-strip halfwidth $a=0.0625$ in radians. It computes the normalized source moments by integrating the exponential power series, including its absolute tail. Every zero-frequency moment encloses its independently calculated 384-bit analytic reference. The joint proxy-domain checks require squared distances with positive real part. For $|q|\le Q$, $\operatorname{Re}q\ge l>0$, the Q3 entire-series majorants use $|F^{(m)}|\le b^m e^{bQ}$, $b=k^2/4$, and $|\log q|\le\max(|\log l|,|\log Q|)+\pi/2$. Differentiation gives the $1/l$ and $1/l^2$ terms in `proxy_envelope`. The normal uses a strictly positive lower magnitude from the real part of speed squared.

The Kress sum uses 6144 source nodes, symmetric Nyquist frequencies and RE5 on the complex target disk. A 64-point Cauchy circle of radius $h$ extracts scaled Taylor coefficients. If $M$ bounds the exact free-space response on $R_t$, the discrete Kress response has norm at most $M+E_{\rm Kress}$. The circle Fourier transform aliases coefficients $j+mL$, $m\ge1$. Cauchy's coefficient estimate and the two geometric sums give the added error $(M+E_{\rm Kress})(h/R_t)^L/[(1-(h/R_t)^L)(1-h/R_t)]$. The implementation adds this term separately. Kress arithmetic uses 192 bits, the CM certificate uses 128 bits. The real curve and the complex domains in T3.0 are checked in code. For each degree, the incident, local density, signed Kress and proxy terms are added before extracting a midpoint polynomial and its coefficient radii. The target tail uses the complete response bound. RE16 is summed only over the reported arcs.

`disks.py` checks curve orientation, origin-to-center paths, boundary distance, outer walls, seam clearance and pairwise distance in global coordinates. The eight interior fields have $e_D=0$. Positive Gauss quadrature with Arb Legendre root/weight balls uses RE6 on each separated complex source disk. For an accepted halfwidth $h_s$, $R_s=2h_s$ and the tail is $8h_s M2^{-2n}$. The stored center quadrature ball plus the stored absolute error encloses the disk-center value. The mass uses a lower endpoint for its magnitude and for the positive Bessel combination in RE19.

## Reproduce

Use fresh run directories and the escalated-permission channel for monitored launches. MATLAB uses R2023b with 11 computational/OpenMP threads and OMP_DYNAMIC=FALSE. Each scientific Python stage is serial in the octave environment. The launcher passes the explicit same-run export to the numerical entry point. The following example reproduces the accepted configuration and output schema.

```sh
repo=/Users/whc/Documents/Work/dot-research
exp="$repo/test/bie-bound/matrel-v1"
run="$exp/output/run-003"
conda_bin=/Users/whc/opt/miniconda3/condabin/conda

python3 "$exp/launch_export.py" --output "$run/export" --package-root "$repo" \
  --fmm-root "$repo/vendor/fmm2d/matlab" \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab

python3 "$exp/launch_arb.py" --run "$run" --name timing-final --conda "$conda_bin" \
  --script material.py --forecast 4 -- --stage timing --target-panels 192 \
  --source-panels 160 --target-degree 52 --source-degree 40
python3 "$exp/launch_arb.py" --run "$run" --name central-final --conda "$conda_bin" \
  --script panel.py --forecast 60 -- --stage panels --first 0 --count 1 --S 160 --p 52
python3 "$exp/launch_arb.py" --run "$run" --name adjacent --conda "$conda_bin" \
  --script panel.py --forecast 60 -- --stage panels --first 1 --count 1 --S 160 --p 52
python3 "$exp/launch_arb.py" --run "$run" --name audit --conda "$conda_bin" \
  --script audit.py --forecast 2 -- --panels "$run/central-final/panel-0.json" \
  "$run/adjacent/panel-1.json" --samples "$run/export/floating-samples.csv"
python3 "$exp/launch_arb.py" --run "$run" --name mass-refined --conda "$conda_bin" \
  --script disks.py --forecast 24 -- --order 30
python3 "$exp/cost.py" --run "$run"
```

For the original timing pilot, use `material.py --stage timing` at degrees 24/16. For the one-point timing and strip check select `panel.py --stage sample`. Every monitored stage retains its exact command, log and process-tree resource record. `launch_reference.py` produces signed floating samples separately if an existing same-run export lacks them.

## Accepted evidence and decision

| Quantity | Panel 0 | Panel 1 |
|---|---:|---:|
| Polynomial squared norm | 1.5421951e-30 | 1.9938136e-30 |
| Uniform error upper | 5.922e-15 | 1.464e-14 |
| Reliable arc upper | 2.313071e-15 | 4.058852e-15 |
| Floating arc norm | 1.936718e-15 | 1.499213e-15 |
| Inside-Python wall time | 49.28 s | 49.37 s |

`run-001/central-final/panel-0.json` and `adjacent/panel-1.json` contain the polynomial, individual coefficient radii, source moment radii and errors, branch margins, $V_I$, $e_I$ and timings. The geometry check gives height span below 0.498581, so the moving-cut error is zero. All four independent derivative checks passed on both panels. `audit/audit.json` records a 53-point Gauss cross-check for the squared polynomials (relative discrepancy below 5.4e-35) and a maximum signed sample difference of 1.34e-14 (tolerance 1e-10). A 1536-point trapezoidal sum, with half weight at the two ends of each arc, defines the floating comparison.

`mass-refined/disks.json` contains the individual geometry, Bessel balls, absolute quadrature errors and mass contributions. The order-14 lower bound was 1.1480280; order 30 gives 1.23587120 with maximum center error 7.7360e-8. `cost.json` contains RE31 group/stage prices and their assumptions. `summary.json` at the experiment root retains compact results. The cold isolated-pair prices, including both angular expansions, are 4.147 and 7.405 units. The measured kernel prices exclude the geometry setup that the cost table accounts for as algebra.

The extrapolation is above 67 minutes for this implementation. Its dominant component is the 64-point target-circle extraction of the Kress part. Both tested arcs meet the 10x inflation target. A group-wide ratio needs the rest of the curve. No residual bound is extrapolated to untested panels.

## Forecast and run record

All runs shared 1800 s soft / 2400 s hard and 3 GiB. Summing monitors, including unsuccessful stages and the export check, gives 650.18 s and peak 1.532 GiB. Short processes can finish between memory samples. The final repeat of the ordinary exporter produced identical defining data, Q5, full floating epsilon and signed samples. Only the run-001 export was used for the certificates.

| Stage | Prior forecast, s / GiB | Monitored s | Outcome |
|---|---:|---:|---|
| export | 60 / 2.4 | 55.42 | Q5 and full floating epsilon reproduced |
| timing | 5 / 0.2 | 1.18 | Initial 24/16 unit prices |
| sample / sample-retry / sample-debug | 15–20 / 0.5 | 172.34 / 1.18 / 2.20 | Excess runtime stopped; argument separator fixed; indeterminate complex envelope localized |
| sample-envelope | 5 / 0.25 | 2.27 | Finite Q3 majorant; one Kress target 0.414 s |
| timing-working | 4 / 0.25 | 2.25 | 48/40 unit prices |
| central-pilot / central-first | 60 / 0.4 each | 29.72 / 28.46 | Zero-centered norm needed upper modulus endpoints; equal-precision containment check diagnosed |
| moment-audit | 2 / 0.2 | 1.19 | All 41 exact zero-mode values enclosed by 384-bit reference test |
| panel-zero | 60 / 0.4 | 46.21 | 128 source panels, coarse upper 4.033898e-12; source truncation dominated |
| central-final | 120 / 0.4 for two panels | 101.20 | Panel 0 accepted; adjacent incident rectangle needed subdivision |
| floating-reference / floating-samples / floating-direct | 40 / 1.7 each | 16.52 / 12.20 / 36.69 | Copied helper name collision and optional range toolbox removed; same-export comparator completed |
| adjacent | 60 / 0.4 | 50.50 | Panel 1 accepted with tiled incident majorant |
| audit | 2 / 0.2 | 1.14 | Norm and signed sample checks passed |
| mass / mass-refined | 25 / 0.4; 24 / 0.4 | 10.94 / 20.99 | Geometry cleared; order 30 met the 1.20 target |
| timing-final | 4 / 0.25 | 2.18 | Isolated and cold 52/40 prices |
| run-002/export | 55 / 1.7 | 54.21 | Normal entry point and same-input sample reproduction |

After the one-point pilot, the central free-space term alone forecast about 85 minutes. A full central computation exceeded the per-result limit before paying for the other stages. The work therefore stopped at the measured contiguous subset.

The final incident-wave routine accepts a finite whole-rectangle majorant and uses the positive-real endpoint tiles when needed. The 2 s / 0.2 GiB forecast check took 1.19 s and reproduced both local upper endpoints exactly (9.050260689273488 and 6.339302021277675).
