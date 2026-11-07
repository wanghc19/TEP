# Literature benchmark version 1

BIE means boundary integral equation, TM transverse magnetic, TE transverse electric, FMM fast multipole method, QZ generalized Schur decomposition and RSS resident set size, SVD singular value decomposition, PWE plane-wave expansion, and FSS fictitious source superposition. W3 denotes three missing rows. I9 in source filenames is the inherited search experiment identifier.

**Yes.** At the printed propagation constant $\alpha_0d=1.67541$, the BIE gives $d/\lambda=0.32000027429728717$, which rounds to the published 0.32. In the direction actually solved in the paper, fixing the frequency at 0.32 gives $\alpha_0d=1.6754070618796773$, which rounds to all six printed significant digits. The second branch gives 0.3325241794052307 at $\beta d=0.2$, consistent with the graphical value of about 0.3325. [Botten et al., Figs. 2–3, p. 141](https://www.ijmot.com/ijmot/uploaded/oTKv4AYm42.pdf#page=9).

## Published benchmark and parameter cards

Botten et al., *Highly Accurate Modelling of Generalized Defect Modes in Photonic Crystals using the Fictitious Source Superposition Method* (2006), §III, printed p. 141, Fig. 2, give a numerical pair for the fundamental mode. [Publisher full text, p. 141](https://www.ijmot.com/ijmot/uploaded/oTKv4AYm42.pdf#page=9). The target is $d/\lambda=0.32$ at $\alpha_0d=1.67541$. The frequency was prescribed and the propagation constant computed in the paper. We hold the printed propagation constant fixed and compute the frequency. Fig. 3(b) also gives a graphical check for the second mode. At $\beta d=0.2$ the curve reads about 0.3325 (graphical reading uncertainty about 0.00003).

| Source | Physical and numerical data | Selection |
|---|---|---|
| Klindworth, Schmidt & Fliss (2014), §2.2 p. 2, §7 p. 22 and Fig. 9 p. 25 | Hexagonal translations $(1,0),(1/2,\sqrt{3}/2)$, circular air holes of radius 0.31, dielectric 11.4, one homogeneous defect row of transverse width $\sqrt{3}/2$. At tangential phase $0.3(2\pi)$ the magnetic-field examples give $\omega/(2\pi)=0.2548,0.2989,0.2347$. | The numerical examples use TE and continuity of the weighted normal derivative. The TM equation appears in the general formulation. |
| Fliss, Klindworth & Schmidt (2015), §5.1 p. 107, §5.2 p. 109 and Fig. 7 p. 110 | Hexagonal air holes of radius 0.31 in dielectric 11.4. The 0.2173 point at $k/(2\pi)=0.45$ is a TE surface mode with a Dirichlet wall. | The surface calculation sets the last cell equal to a bulk cell and replaces the top cladding by a Dirichlet wall. A two-cladding guide width does not apply. |
| Huang, Lu & Li (2007), Eq. (1), p. 3, Fig. 1, and Figs. 2–3, pp. 10–12 of the local preprint | Square rods in air, $r/L=0.375$, $\epsilon=10$, one missing row, width $L$. At $\omega L/(2\pi c)=0.8$ Fig. 3 gives $\beta L/(2\pi)=0.3346$ (odd) and 0.2773 (even). | Correct electric polarization. The results use a finite supercell. Increasing its width to $m=16$ gives a consistency check. The 0.800 PWE result on p. 12 also uses a supercell. |
| Botten et al. (2006), §II.A and §III, Figs. 1–3 | Infinite hexagonal claddings, $r/d=0.2$, indices 3 inside and 1 outside, three missing layers, electric field parallel to cylinders (TM). Fig. 2 supplies the printed pair above. | Chosen. The regular hexagonal row staggering is visible in Fig. 2(a). Its normalized layer spacing is $h=\sqrt{3}/2$. |

## Geometry and units

Exchange the paper's tangential and normal axes to place the guide along our $y$ axis. In units of $d=1$, our $\beta=\alpha_0d$, $k=\omega d/c=2\pi d/\lambda$. Thus $0.32\times 2\pi=0.64\pi=2.0106192983$. The density values are $3^2=9$ and $1^2=1$. Take row centers at $x=jh$ and remove $j=-1,0,1$. The center ports at $x=\pm1.5h$ enclose homogeneous air. The first intact rows on both sides have $y=-1/4$ modulo 1. The second intact rows have $y=+1/4$. The complete rectangular lead period is $2h$. The circles clear each row port by $h/2-0.2$ and each periodic seam by $1/4-0.2$.

## Computation

The example2-v1 search normally builds one scattering matrix per lead cell, for a single closed curve. Its air ports use $\gamma_m^2=k^2-(\beta+2\pi m/d)^2$ and its layer solver uses exterior wavenumber $k$ and interior wavenumber $k\sqrt{\rho}$. A uniform dielectric background can be handled for TM by solving at $k\sqrt{\rho_e}$ with all densities divided by $\rho_e$. That change of units would leave the TE interface law of the first two papers unresolved.

For W3 the new code solves on each separate offset circle with its true coordinates. Let $A,B$ be two consecutive row scattering matrices, with incoming amplitudes $a_L,b_R$. The rightgoing and leftgoing amplitudes at their shared port are
$$
u=(I-R_A^R R_B^L)^{-1}(T_A^{LR}a_L+R_A^R T_B^{RL} b_R),\qquad v=R_B^L u+T_B^{RL}b_R.
$$
The outgoing waves are $b_L=R_A^L a_L+T_A^{RL}v$ and $a_R=T_B^{LR}u+R_B^R b_R$. The solve checks the shared-port residual. The order of the two rows reverses between the positive and negative leads. Their decaying subspaces use the forward and reciprocal QZ pencils, respectively. The empty center uses diagonal free propagation across $3h$. All density resolutions keep the original proxy controls (160 side/top, 80 proxy nodes per edge and 32 plane waves), FMM tolerance $10^{-12}$ and root-polishing tolerance $2\times10^{-14}$.

The example parameters, search configuration, geometry, lead physics and determinant search are copied from [example2-v1](../example2-v1/README.md). The changes are the row composition and coordinates, explicit frequency window, nine-point gap check and recorded multiplier distances. The I9 search adapter and resource monitor are from [solver-cost-v1](../solver-cost-v1/README.md). The classifier, Chebyshev stopping tests, singular-value confirmation and shared BIE kernels retain their original arithmetic. The matrix-join regression doubles both periods of the second repository example by composing identical rows.

## Results and checks

| Mode | Run | N | M | $d/\lambda$ | Candidates | $\sigma_{min}/\sigma_{max}$ | Lead distance L / R | Wall s | Peak GiB |
|---|---:|---:|---:|---:|---:|---:|---|---:|---:|
| fundamental | 004 | 64 | 12 | 0.32000027429728717 | 1 | 5.77e-14 | 0.64590470 / 0.64590470 | 37.69 | 0.832 |
| fundamental | 005 | 64 | 24 | 0.32000027429728717 | 1 | 5.76e-14 | 0.64590470 / 0.64590470 | 33.95 | 1.051 |
| fundamental | 006 | 128 | 12 | 0.32000027429728717 | 1 | 5.81e-14 | 0.64590470 / 0.64590470 | 40.27 | 0.907 |
| fundamental | 007 | 128 | 24 | 0.32000027429728717 | 1 | 5.73e-14 | 0.64590470 / 0.64590470 | 43.47 | 0.912 |
| fundamental | 008 | 256 | 12 | 0.32000027429728717 | 1 | 5.83e-14 | 0.64590470 / 0.64590470 | 66.39 | 0.969 |
| fundamental | 009 | 256 | 24 | 0.32000027429728717 | 1 | 5.8e-14 | 0.64590470 / 0.64590470 | 71.10 | 0.942 |
| second | 010 | 64 | 12 | 0.33252417940523071 | 1 | 2e-14 | 0.75124993 / 0.75124993 | 24.74 | 0.890 |
| second | 011 | 64 | 24 | 0.33252417940523071 | 1 | 2.07e-14 | 0.75124993 / 0.75124993 | 25.35 | 1.071 |
| second | 012 | 128 | 12 | 0.33252417940523066 | 1 | 1.96e-14 | 0.75124993 / 0.75124993 | 30.22 | 0.892 |
| second | 013 | 128 | 24 | 0.33252417940523066 | 1 | 1.95e-14 | 0.75124993 / 0.75124993 | 29.67 | 0.953 |
| second | 014 | 256 | 12 | 0.33252417940523071 | 1 | 2.04e-14 | 0.75124993 / 0.75124993 | 46.84 | 0.972 |
| second | 015 | 256 | 24 | 0.33252417940523071 | 1 | 2.07e-14 | 0.75124993 / 0.75124993 | 55.45 | 0.897 |

The multiplier distance is $\min_j ||\lambda_j|-1|$ on the outward lead pencil. Each of the nine scan points and every subsequent matching evaluation passed the gap tests on both sides. The entire specified window was searched at each resolution. Every row gave one candidate with fresh SVD confirmation and the complete search status. Raw frequencies, determinants, candidate lists, preflight checks and monitors are in the numbered outputs. [Scalar results](output/results.csv) and [checks](output/checks.json).

- **Regression.** Example 2 has recorded $k=1.8916961400527375$. Run-002 returned 1.8916961400527368 with its original lead rows. Run-003 exercised the two-row scattering join in both leads and returned 1.8916961400527366, an absolute difference of $8.88\times10^{-16}$ (relative $4.70\times10^{-16}$), inside the $2\times10^{-14}$ tolerance.
- **Source and units.** After the refinement runs we reread the parameter passages and captions cited in the four cards. Fig. 2(a) confirms the half-period stagger and three missing rows. Its caption gives the printed pair. On Fig. 3(b), the ordinate ticks are 0.001 apart. The red curve at abscissa 0.2 lies about half a tick above 0.332. The numerical value differs from the reading 0.3325 by $2.42\times10^{-5}$. The hand conversion of the prescribed 0.32 gives $k=2.0106192983$. Independent conversion of each saved $k$ back to $d/\lambda$ reproduces every tabulated value.
- **Digits.** The six fundamental frequencies are identical in binary64. The second-mode spread is $5.55\times10^{-17}$, with 16 common rounded significant digits. Run-016 replaced the interpolant derivative by a centered frequency derivative at each fine root. The real correction left the fundamental unchanged and shifted the second mode by one binary64 step in frequency. Thus at least 16 significant digits are stable in these real-valued refinement tests. The complex Newton corrections have imaginary parts of magnitude $1.80\times10^{-14}$ and $8.57\times10^{-15}$ in $k$, respectively. These figures document sensitivity at fixed proxy settings and floating arithmetic. They do not give an absolute frequency-error bound.
- **Reciprocal check.** Run-016 took the fine-grid model explicitly from run-009 and fixed $k=0.64\pi$. The computed propagation constant differs from the printed 1.67541 by $2.94\times10^{-6}$, within its half-unit rounding interval of $5\times10^{-6}$. The fresh physical singular-value ratio was $5.83\times10^{-14}$. [Reciprocal and polishing controls](output/run-016/reciprocal.json).

Total monitored wall time was 670.26 s (11.17 min), including both regressions, the twelve search runs, the reciprocal control and the initial 17.86 s diagnostic-record failure. Peak process-tree RSS across the runs was 1.071 GiB. All recorded preflight checks found the machine free of competing numerical jobs.

The solver paper can cite the printed infinite-cladding TM dispersion pair as an external correctness check for the staggered-row and empty-guide calculation. The second branch adds a graphical dispersion check. External frequency agreement extends to the two digits supplied for the fundamental, and external propagation-constant agreement extends to six significant digits. The finer digits in the table come from this implementation’s refinement study.

## Runs and forecasts

Use the same determinant interpolation, real polishing, fresh singular-value check and decaying-subspace selection for the regression and the two modes. Each search classifies both leads first on a nine-point frequency grid and then at every search evaluation. The regression searches example 2 on [1.85,1.93] around its previously reported candidate, with 256 nodes per rod and M48. Forecast 1–4 min, under 1.6 GiB based on example2-v1. All launches require the idle numerical process check and use the 30/40 min, 3 GiB monitor.



Run-001 stopped while assigning the first classification record to an untyped MATLAB struct. Run-002 repeats the regression with the record fields declared. Forecast remains 1–4 min and <1.6 GiB.

Run-002 reproduced the example-2 frequency on the original single-row representation. Run-003 additionally repeats each example-2 lead row twice per rectangular cell, exercising the row join used for W3 in both directions. The physical claddings and center remain identical. Complete forecast 50–100 s and <1.6 GiB.

For both W3 modes the planned ladder uses N=64,128,256 density nodes per row and M=12,24 independently. The fundamental window is $d/\lambda\in[0.314,0.326]$ and the second-mode window is [0.331,0.335]. Each of the twelve separate searches is forecast at 30–120 s and <1.6 GiB. Count candidates on the qualified subwindows and report any exclusions. Compare normalized frequencies at identical printed Bloch parameters. Count common rounded significant digits over the whole ladder as empirical refinement agreement.

Fig. 2 specifies the frequency to two digits and prints the propagation constant to six significant digits. A reciprocal check after the fundamental ladder fixes $d/\lambda=0.32$, uses the fine model and solves for $\alpha_0d$ in [1.67536,1.67546]. A fresh physical singular-value ratio checks the zero of the phase-normalized determinant. The same run checks both fine-grid roots with a separate centered-difference determinant derivative ($h=10^{-6}$ in $k$), retaining the original and polished results. This distinguishes discretization spread from the effect of the fixed polishing tolerance. Complete forecast 25–90 s, <1.6 GiB.

## Reproduction commands

Set `ROOT` to the checkout, `EX="$ROOT/test/bie-bound/litbench-v1"` and `MATLAB` to the MATLAB R2023b executable. Commands use fresh output directories and eleven MATLAB/OpenMP threads. The host also needs the FMM2D MATLAB interface. N counts density nodes per circular row and M is the Rayleigh half-width, giving $2M+1$ channels on each port.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 "$EX/launch.py" --package-root "$ROOT" --fmm "$ROOT/vendor/fmm2d/matlab" --matlab "$MATLAB" --mode regression --size 256 --order 48 --output "$EX/output/run-103"
PYTHONDONTWRITEBYTECODE=1 python3 "$EX/ladder.py" --package-root "$ROOT" --fmm "$ROOT/vendor/fmm2d/matlab" --matlab "$MATLAB" --mode fundamental --first 104 --output "$EX/output"
PYTHONDONTWRITEBYTECODE=1 python3 "$EX/ladder.py" --package-root "$ROOT" --fmm "$ROOT/vendor/fmm2d/matlab" --matlab "$MATLAB" --mode second --first 110 --output "$EX/output"
PYTHONDONTWRITEBYTECODE=1 python3 "$EX/launch.py" --package-root "$ROOT" --fmm "$ROOT/vendor/fmm2d/matlab" --matlab "$MATLAB" --mode reciprocal --size 256 --order 24 --parameters "$EX/output/run-109/result.json" --second-parameters "$EX/output/run-115/result.json" --output "$EX/output/run-116"
```
