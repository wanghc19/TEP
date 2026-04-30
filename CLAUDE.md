# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project summary

MATLAB codebase for computing **transmission eigenvalues** of 2D periodic dielectric waveguides. The core numerical problem: find wavenumbers \(k\) where the smallest singular value \(\sigma_{\min}(A_N(k))\) of a boundary-integral-equation (BIE) system matrix drops near zero. The BIE couples interior Helmholtz fields (single-layer, double-layer, adjoint, hypersingular operators) to exterior quasi-periodic fields evaluated via the **augmented Method of Fundamental Solutions (MFS)** (proxy sources + plane-wave expansions).

The active branch `kress` is replacing Kapur-Rokhlin (KR) near-diagonal corrections in the hypersingular T-block with **Kress/Kussmaul-Martensen product quadrature** for logarithmic-kernel singularities. The other three Muller-difference blocks (S, D, D') were already transitioned to direct kernel differences with analytic diagonal limits in `tep_scan_local2.m`.

## How to run

No build step. Open MATLAB, `cd` to the repo root, and run any top-level script by name:

```matlab
tep_scan_global         % Global-to-local adaptive scan over full k-interval
tep_scan_local          % Single-dip recursive refinement (vectorized assembly)
tep_scan_local2         % S/D/D' blocks as continuous kernels, T-block on KR path
tep_scan_local3         % Kress-style T-block (most recent; currently broken)
tep_conv_local          % Convergence study across ntot_list for one eigenvalue
tep_kpert_local         % Ultra-local k-perturbation diagnostic around known k*
tep_debug_tblock        % T-block assembly diagnostic (KR vs Kress comparison)
tep_debug_tblock_n1_scaling  % N1 scaling diagnostic for Kress T-block
quad_demo_7_1_kress     % Standalone Kress quadrature convergence demo
```

**Never run MATLAB automatically.** After code changes, tell the user which script to run and what outcome to expect.

## Architecture

### Dependency order

```
precomp_proxy.m          -- precomputes MFS proxy coefficients (sources + plane-wave coeffs);
                            must be called before qpgreen_mfs
    ↓
qpgreen_mfs.m            -- evaluates the quasi-periodic exterior Green's function
                            (potential, gradient, Hessian) at target points
    ↓
LOCAL_construct_A        -- assembles the 4×4 block BIE matrix A_N(k) for a given
    (inside each script)    wavenumber k, geometry C, and proxy data
    ↓
svd / svds               -- computes sigma_min of A_N(k)
    ↓
LOCAL_recursive_dip_refine  -- recursive interval-halving scan to find k minimizing sigma_min
    ↓
Reporting / plotting helpers
```

`precomp_proxy.m` and `qpgreen_mfs.m` are the only standalone function files. All other logic lives in `LOCAL_*` helper functions at the bottom of each script.

### Script genealogy (chronological)

| Script | Relation to predecessor |
|---|---|
| `archive/demoeigen1-3` | Original fixed-k eigenvalue demos |
| `archive/demoeigen3_recursive_dip` | First recursive dip refinement |
| `tep_scan_local.m` | Vectorized assembly via `LOCAL_qpgreen_mfs_pairmat` |
| `tep_scan_local2.m` | S/D/D' blocks: kernel differences + analytic diag limits; T-block still KR |
| `tep_scan_local2_1.m` | Route-B: narrow near-diagonal band uses Phi_k subtraction for S/D/D' |
| `tep_scan_local3.m` | **Current target**: Kress-style T-block, S/D/D' as continuous kernels |
| `tep_scan_global.m` | Coarse-to-fine adaptive scan over full k-range with multiple dips |
| `tep_conv_local.m` | Convergence study: sigma_min vs ntot for one candidate eigenvalue |
| `tep_kpert_local.m` | Tests sensitivity of sigma_min to tiny k-perturbations |
| `tep_debug_tblock.m` | Side-by-side KR vs Kress T-block diagnostics |

### Key parameters (shared across scripts)

- `flag_geom`: `'ellipse'` or `'star'` — boundary shape
- `ntot`: number of boundary discretization nodes
- `d = 1.0`: periodicity length along x
- `beta`: Bloch phase (typically `0.5 * 2*pi/d`)
- `er = 13`: relative permittivity; interior refractive index `nref = sqrt(er)`
- `pars2`: MFS proxy geometry (H, proxy_dist, N_side/top/proxy_edge, M_pw)

### Kress T-block assembly (tep_scan_local3)

The T-difference kernel is split as:

```
Ndiff(s,t) = log(4 sin²((s-t)/2)) · N1diff(s,t) + N2diff(s,t)
```

where `N1diff` and `N2diff` are smooth. The log part uses Kussmaul-Martensen weights; the smooth part uses the periodic trapezoid rule. The cot/principal-value term cancels in the difference kernel. The three other Muller blocks (S, D, D') use direct off-diagonal kernel differences and analytic diagonal limits — no KR correction.

## Code conventions (from AGENTS.md)

- 2-space indentation
- Comments in English
- Local helper functions prefixed with `LOCAL_`
- New files must have a header comment block: Purpose, Main algorithm, Based on, Main changes, Numerical goal
- Preserve function signatures unless explicitly changing them
- Do not change the mathematical model unless asked
- Prefer readable vectorization over clever tricks
- Preserve numerical behavior up to floating-point roundoff
