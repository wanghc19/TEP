# Canonical data dictionary

`ex1` means example 1; BIE means boundary integral equation; MFS means method of fundamental solutions. Every file is JSON (JavaScript Object Notation), UTF-8 text. The files were produced by this release's cold reproduction. The manifest is a descriptive inventory, not a numerical prerequisite.

## Exact numbers and indices

An array has `shape: [rows, columns]`, `real` and `imag`. The latter contain 16-character hexadecimal IEEE-754 binary64 words, in **column-major** order. A scalar may use a string instead of a one-element list. Decode a word with `struct.unpack('>d', bytes.fromhex(word))[0]`; `arb` converts this binary64 value exactly. Real and imaginary parts are separate exact rational inputs. No decimal parsing of a displayed coefficient is needed. An exact zero can have either binary sign.

`model.json` uses `{"binary64": "word"}` for scalar binary64 parameters and integers for exact integer parameters. Reference bounds use decimal strings or JSON numbers rounded **upward as decimal values** by the production `up` routine. `assemble.py` parses these JSON numbers as decimal strings, then uses Arb and exact rational arithmetic. Reported lower endpoints and mass lower bounds use the opposite direction.

The angle in the code is in radians, $0\le t<2\pi$. Rows of a Fourier array correspond, in order, to its explicit `modes` list. The continuous density is $\sum_m c_m e^{imt}$. The native even-grid Nyquist coefficient is halved between the two modes $\pm N/2$ (the MATLAB `interpft` convention); both are explicitly present. Saved Fourier coefficients, rather than an unevaluated mathematical discrete Fourier transform, define the field.

## Field files

| File / key | Shape or meaning | Equation in the paper |
|---|---|---|
| `fixed-input.json`: `k`, `beta`, `d`, `H` | Exact candidate, transverse phase parameter, transverse period and solve proxy-box half-length | `eq:candidate-mu`, `eq:cell-incident` |
| `curve_parameters` | `[0.2,0.3,1.5,1,1,0.12,0.20,0.2]`, each value binary64: star radius, lobe amplitude, x anisotropy, y base, extra scale, left/right deformations, lead radius | Model in Section 6.1 |
| `incident` | $194\times1$, center incoming Rayleigh amplitudes, first left-incident and then right-incident | `eq:cell-incident` |
| `rayleigh_modes` | Integers $-48,\ldots,48$ | `eq:cell-incident` |
| `pieces[0]` | Center; `tau_coeff`, `zeta_coeff`: $513\times1$ | `eq:exact-density-dft`, `eq:actual-material-jumps` |
| `pieces[1]`, `pieces[2]` | Left/right lead; density maps $257\times194$ | `eq:lead-cell-field` |
| `pieces[s].G` | $194\times97$; state-to-incoming-amplitudes map | `eq:lead-cell-field` |
| `pieces[s].P`, `.c` | $97\times97$ propagation matrix and $97\times1$ first state; subsequent states are **ball products** $P^jc$ | `eq:half-guide-raw-field`, `eq:boundary-propagation-tail` |
| `coefficients.json`: `Z` | $2\times480$ **computational coordinates**: row 1 = physical y; row 2 = physical x | `eq:mfs-field` |
| `B_center` | $480\times1$ actual center point-source coefficients | `eq:mfs-field` |
| `B_negative`, `B_positive` | $480\times97$ actual lead point-source maps; coefficients in cell $j$ are $B_sP_s^jc_s$ | `eq:mfs-field`, `eq:half-guide-raw-field` |
| `disks-input.json`, also `fixed-input.json:disks` | Eight rows: template index (1 center, 2 left, 3 right), local x, local y, radius, material density | `eq:disk-mass-assembly` |
| `band-inputs.json` | Integer phase partition, Fourier and quadrature cutoffs, rational certified gap endpoints and material values | `eq:inclusion-fourier`, Appendix C band certificate |
| `model.json` | Reproduction physical/discretization/qualification settings; verify checks that they describe the supported example | Section 6.1 |

The second density `zeta` is $-\omega$ in the paper's notation. Each free-space layer is $D_\kappa\tau-S_\kappa\zeta$. Background fields add the two near images weighted by the **exact** $e^{\pm i\beta d}$, the fitted B point sources and the Rayleigh incident field. Material interiors use only $D_{\kappa_c}\tau-S_{\kappa_c}\zeta$. The `phase`, `phase_minus`, and old `proxy_Z`/`proxy_c` fields record floating candidate-construction data; they are not substituted for the exact phase or fitted B coefficients in the certified field.

The center curve is
$$(x,y)=R\big((1.5+b\cos5t)\cos t,(1+b\cos5t)\sin t\big),$$
with the saved binary64 $R,b$. A lead curve is
$$(x,y)=\frac{R(1+a\cos3t)}{\sqrt{1+a^2/2}}(\cos t,\sin t),$$
using the saved binary64 $R,a$ and the real square root. Cells have width and height 1; the center is at x=0, the first left/right cells at x=-1/+1. Background density is 1, star density 4, and both lead rods have density 17. The verify entry rejects a different model. It does not assert a result for decimal-exact 0.2/0.3/0.12 geometry.

## Reference files

`results.json` contains the candidate, five-group products, $Q,U,R$, both intervals and comparison tolerances. `trace-constants.json` holds both ball configurations, complete curvature interval covers, separation tests and the finite extrema used for $C_g$. The accompanying CSV displays $\kappa_g,\delta_g,h_g,\eta_g,D_{0,g},D_{1,g}$; `h_display` is for presentation, while the JSON certificate is authoritative. `groups.json` and `lead-tails.csv` contain every side/kind's depth, operator envelope, contraction, finite and tail squares, and the N+10 check. `disks.json` contains all eight disk certificates. `band.json` contains all 472 signs, four LDL* comparisons, the failed control and gap margins. `central-panels.csv` contains the per-panel residual budget. `two-sided-traces.json` records I1's actual traces and fitted proxy contribution. `reproduction-checks.json` records the package cold-run comparison; `verification.json` records the external-copy verification. None of these reference defects is an input to a full verification.

## Empty-center data sets (`ex2-L*`)

`data/ex2-L1/`, `data/ex2-L1.6/`, `data/ex2-L1.9/`, and `data/ex2-L2/` use the same hexadecimal array format. Their respective center widths are 1, 1.6, 1.9, and 2. The left period is 1, the right period is binary64 0.85, and the right rod is rotated by binary64 0.13 radians. The transverse period is 1 and beta is 0.5. The JSON files in `examples/` are scientific parameter files, not result selectors. Their model is copied into the cold run and exported in `fixed-input.json`.

The center piece has `shape: none`, zero density rows (MATLAB JSON represents a zero-row hexadecimal character array as `[""]`; the recorded zero shape controls its interpretation), zero fitted B coefficients and no material interface. Its field is the finite incoming Rayleigh representation. Search uses exactly zero reflection and diagonal free propagation across the center width. The central material and central seam defects are exactly zero. No dummy inclusion is used; unused star parameters in the compatibility vector do not define an interface.

`cell_widths` stores exact binary64 L0, Lminus, Lplus. The `example.angle_negative` and `example.angle_positive` fields specify the rod rotations; analytic geometry and normal vectors include it. Rayleigh ports use their own cell wall locations and the same transverse normalization. The background fit has 480 fixed sources outside the relevant cells. Lead maps and state vectors retain the R1 dimensions, and actual cell j uses the ball product P^j c. `disks-input.json` contains three background disks in the empty center, with rho=1; their containment and pairwise separation are recomputed.

`example-settings.json` records the selected tail-square target, state capacities, worker count and certified k window. The targets for L0=1,1.6,1.9,2 are 1e-6,1e-2,0.1,0.1. `band-inputs.json` gives the full integer phase partition (-4096 to 4096), the side periods and angles, Fourier halfwidth 6, trapezoid count 2048 and the k-window endpoints. The phase conversion is theta=pi*integer/(4096*L_side), and indicator coefficients use 1/(L_side*d). No reflection reduction is used: 236 phase panels per side and 944 signs.

For a contracting block length p, `propagation.py` encloses the powers in balls. It uses the identity norm 1 and Frobenius upper bounds on the other spectral norms, r>=||P^p||<1, and factor sum_(l=0)^(p-1)||P^l||_+^2/(1-r^2). Each tail is B^2*factor*||P^N c||^2. The selected p and a forced p=2 demonstration are recorded, including the first 10 subsequent state norms and the N+10 check. The bound always includes the tail, independently of the chosen cost target.

Each `reference/<example>/summary.json` gives the interval, width, Q/U/R, distance to the floating edge 1.441, a reliable upper bound on ||P_positive||_2, tail depths and settings, band margins and measured costs. The distance to 1.441 is a floating diagnostic; interval containment uses the separately certified window. `groups.json` retains both sides and all three tail kinds, operator envelopes, short powers and finite/tail ratios. The original R1 reference files remain at `reference/` for compatibility and are mirrored in `reference/ex1/`.
