# +bloch package

## Purpose

The `+bloch` package builds and post-processes Bloch-mode data for one periodic lead cell.  It provides Rayleigh channel metadata, incident Cauchy-data right-hand sides, far-field extractors, a one-cell scattering matrix, Bloch generalized eigenmodes, wall trace coefficients, and outgoing port-trace selection.

## Public functions

`bloch.rayleigh_channels(k, beta, d, M, L)` constructs Rayleigh channel metadata using explicit formulas only.  It returns a `channels` struct with mode indices, transverse wavenumbers `beta_m`, longitudinal wavenumbers `gamma_m`, direct cell phases, and counts; it does not use geometry, BIE assembly, or scattering matrices.

`bloch.incident_rhs(geom, rayleighchan, X_L, X_R)` constructs left- and right-incident Rayleigh Cauchy-data right-hand sides on the inclusion boundary.  It returns `B_L` and `B_R` matrices of size `2N`-by-`K`; it only evaluates incident field formulas and does not assemble or solve a BIE system.

`bloch.farfield_extractors(geom, rayleighchan, X_L, X_R, curvelen)` constructs extraction matrices for outgoing scattered Rayleigh coefficients.  It returns `F_L`, `F_R`, and an auxiliary debug struct; it builds linear maps from `eta = [tau; -sigma]` to scattered coefficients and does not include the direct cell phase.

`bloch.construct_S(geom, kext, kint, pars1, proxy, curvelen, rayleighchan, X_L, X_R)` constructs the one-cell Rayleigh scattering matrix.  It assembles `A_QP`, builds incident right-hand sides and far-field extractors, solves the multi-RHS BIE system, and returns an `S_cell` struct with scattering blocks, solve data, and diagnostics.

`bloch.solve_modes(S_cell, opts)` solves the Bloch generalized eigenvalue problem from an existing one-cell scattering matrix.  It returns a `modes` struct containing finite Floquet multipliers, eigenvectors, wall amplitudes, trace coefficients, generalized eigenproblem matrices, and preliminary `|lambda|` classifications.

`bloch.mode_traces(lambda, V, rayleighchan)` computes Dirichlet and x-derivative trace coefficients from Bloch eigenvectors.  It is a pure linear-algebra post-processing routine and returns a `traces` struct with left- and right-wall amplitudes and trace matrices.

`bloch.select_port_traces(modes, traces, portSign, opts)` selects outgoing or decaying Bloch traces for one center port.  It returns `D_out`, `N_out`, and a `selected` metadata struct, applying the correct outward-normal sign for `portSign = '+'` or `portSign = '-'`.

## Main data structures

`rayleighchan` or `channels` is returned by `bloch.rayleigh_channels`.  Important fields are `k`, `beta`, `d`, `L`, `M`, `K`, `m`, `beta_m`, `gamma_m`, and `phase`, where `phase = exp(1i*gamma_m*L)`.

`geom` is the boundary geometry used by the incident and far-field routines.  Numeric geometry is expected to be the `geom.construct_cont` matrix with boundary coordinates and tangents; selected routines also accept compatible structs with coordinate, normal, and speed or tangent fields.

`B_L` and `B_R` are incident Cauchy-data matrices.  Their first `N` rows are Dirichlet traces and their last `N` rows are outward Neumann traces for the boundary normal convention used by the existing Muller assembly.

`F_L` and `F_R` are far-field extraction matrices of size `K`-by-`2N`.  They map the BIE density vector `eta = [tau; -sigma]` to outgoing scattered Rayleigh coefficients on the left and right cell walls.

`S_cell` is returned by `bloch.construct_S`.  Its key fields are the scattering blocks `R_L`, `T_LR`, `T_RL`, `R_R`, the full block matrix `S`, BIE data such as `A_QP`, `B_L`, `B_R`, `F_L`, `F_R`, solved densities `H_L`, `H_R`, copied `channels`, phase matrix `E`, wall coordinates `X_L`, `X_R`, and residual diagnostics.

`modes` is returned by `bloch.solve_modes`.  It stores `lambda`, `V`, amplitudes `a_L`, `b_L`, `a_R`, `b_R`, trace coefficients `D_L`, `Dx_L`, `D_R`, `Dx_R`, generalized eigenproblem matrices `A_sc`, `B_sc`, preliminary index fields, copied channel data, and raw eigenpairs.

`traces` is returned by `bloch.mode_traces`.  It stores `lambda`, amplitudes `a_L`, `b_L`, `a_R`, `b_R`, trace matrices `D_L`, `N_L`, `D_R`, `N_R`, the channel count `K`, and copied channel data.

`selected` is returned by `bloch.select_port_traces`.  It records the selected logical index vector, the requested `portSign`, selected multipliers, the number of selected modes, and the tolerance used.

## Conventions

- `L` and `R` in `S_cell`, `modes`, and `traces` denote the left and right walls of one cell, not positive or negative half-axis leads.
- The scattering convention in `S_cell` is `[b^L; a^R] = [R_L, T_RL; T_LR, R_R] * [a^L; b^R]`.
- `a` amplitudes are right-going Rayleigh amplitudes and `b` amplitudes are left-going Rayleigh amplitudes.
- `kext` is the exterior/background wavenumber; some notes may call the same quantity `omega`.
- `gamma_m` is chosen with `imag(gamma_m) >= 0` in `bloch.rayleigh_channels`.
- The direct one-cell phase is stored in `rayleighchan.phase` and is added only to the transmission blocks inside `bloch.construct_S`.
- `bloch.farfield_extractors` maps `eta = [tau; -sigma]` to scattered outgoing coefficients only; it does not add direct incident transmission.
- `N_L` and `N_R` from `bloch.mode_traces` are x-derivative trace coefficients.  `bloch.select_port_traces` converts them to center-port outward-normal traces, including the minus sign for `portSign = '-'`.
- `modes.idx.right_decay`, `modes.idx.left_decay`, and `modes.idx.neutral` are preliminary `|lambda|` classifications, not a replacement for `bloch.select_port_traces`.
- Keep `flag`-like or sign inputs in the existing style: `portSign` is the character or string scalar `'+'` or `'-'`.

## Typical workflow

```matlab
rayleighchan = bloch.rayleigh_channels(kext, beta, d, M, L);

S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
  rayleighchan, X_L, X_R);

mode_opts.lambda_tol = 1e-8;
mode_opts.normalize = 'V';
modes = bloch.solve_modes(S_cell, mode_opts);

traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);

[D_plus, N_plus, selected_plus] = bloch.select_port_traces( ...
  modes, traces, '+', mode_opts);
[D_minus, N_minus, selected_minus] = bloch.select_port_traces( ...
  modes, traces, '-', mode_opts);
```
