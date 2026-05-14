# `crystal_2d`

This folder contains small validation scripts for the 2D periodic-crystal checks used before continuing the linear-defect scattering implementation.

The scripts here are **not** meant to be production scattering solvers. Their purpose is to isolate and test whether the Bloch-mode and 2D quasiperiodic-BIE machinery are consistent in simple reference configurations.

---

## Purpose

The main goal is to support the validation ladder for the linear-defect scattering project:

1. **Step 1: empty-cell consistency**
2. **Step 2: perfect-crystal consistency**

These tests are designed to answer a narrow question:

> Does the current Bloch-mode / transfer formulation produce the same horizontal Bloch phase as a Barnett-style 2D quasiperiodic formulation, and does the linear-defect scattering formulation reduce correctly when there is no actual defect?

---

## Step 1: empty-cell consistency

Step 1 is a smoke test.

The idea is to remove the center obstacle and check that any new linear-defect / periodic-crystal workflow reduces to the already implemented empty-defect-cell formulation.

Expected comparison target:

```text
scat_edc_lead_in.m
```

This test is useful for catching obvious implementation mistakes, such as:

- wrong port ordering;
- wrong sign for the left wall outward normal;
- swapped `+/-` and `L/R` conventions;
- inconsistent Rayleigh phase origins.

However, Step 1 is not a strong physical validation, because it only checks consistency with the previous empty-defect-cell code.

---

## Step 2: perfect-crystal consistency

Step 2 is the main validation target.

Set the three reference-cell obstacles and periods to be identical:

```text
Omega_minus = Omega_0 = Omega_plus
L_minus     = L_0     = L_plus
```

with the same material parameters and the same relative obstacle placement in each cell.

Then the linear-defect geometry degenerates into a perfect 2D periodic crystal artificially cut into cells. In this case, a correct incoming Bloch mode should pass through the center cell without generating a real reflection.

---

## Step 2a: Barnett-style phase comparison

This test does **not** involve scattering.

Fix

```text
omega
beta
```

where `beta` is the project notation for the y-quasimomentum, so that the y-direction phase is

```text
exp(1i * beta * d)
```

Then compare two ways of finding the horizontal Bloch multiplier:

### Method A: Barnett-style 2D quasiperiodic BIE scan

For

```text
lambda = exp(1i * a),   a in [-pi, pi)
```

assemble a 2D doubly-quasiperiodic Müller matrix

```text
A_QP_2d(omega, beta, lambda)
```

and compute

```text
sigma_min(A_QP_2d)
```

The expected Bloch phases are located at dips of this function.

This route uses a 2D quasiperiodic Green function

```text
G_QP^(omega)
```

which is periodic/quasiperiodic in both cell directions. The intended implementation is via new kernel routines such as:

```text
kernel.precomp_proxy2d
kernel.qpgreen2d
kernel.qpgreen2d_pairmat
```

rather than by reusing the existing one-directional `qpgreen_mfs_pairmat`, whose internal logic includes open-direction Rayleigh expansions.

### Method B: transfer / Bloch-mode eigenproblem

Use the already implemented Bloch-mode workflow for a single perfect-periodic lead cell.

This fixes `(omega, beta)` and solves directly for the horizontal Floquet multiplier

```text
lambda
```

Only modes with

```text
abs(lambda) ≈ 1
```

should be compared to the real-phase Barnett-style scan.

### Expected result

The arguments of the transfer/Bloch-mode multipliers

```text
arg(lambda_j)
```

should lie near dips of

```text
a -> sigma_min(A_QP_2d(omega, beta, exp(1i*a))).
```

This test checks whether the current transfer/Bloch-mode package is finding the same 2D Bloch waves as the Barnett-style formulation.

---

## Step 2b: no-reflection perfect-crystal scattering

After Step 2a succeeds, use the same perfect-crystal geometry in the lead-incoming scattering formulation.

For a right-going incoming Bloch mode from the negative lead, the reflected outgoing amplitude on the negative port should be approximately zero:

```text
a_s_minus ≈ 0
```

The transmitted field on the positive port should match the same Bloch wave continued through one cell, up to the chosen trace normalization and phase-origin convention.

This test is stronger than Step 1 because the geometry is no longer empty; it contains a dielectric obstacle, but the full structure is still perfectly periodic and therefore should not scatter.

---

## Recommended script roles

The exact script names may change, but scripts in this folder should stay focused on validation. Suggested roles are:

```text
crystal2d_step1_empty_consistency.m
```

Compare the new workflow against the existing empty-defect-cell formulation.

```text
crystal2d_step2a_barnett_scan.m
```

Scan `lambda = exp(1i*a)` and compare `sigma_min(A_QP_2d)` dips with transfer/Bloch-mode eigenvalues.

```text
crystal2d_step2b_pc_no_reflection.m
```

Run the perfect-crystal lead-incoming scattering check and verify that the reflected component is small.

Helper scripts should use clear names and should not hide major physical assumptions.

---

## Notation reminders

Use the project convention:

- `L/R` refers only to the left/right wall of a single cell.
- `+/-` refers to positive/negative half-leads or positive/negative ports.
- The three reference cells are:
  ```text
  C^-, C^0, C^+
  ```
  written in notes as:
  ```text
  \mathcal C^-, \mathcal C^0, \mathcal C^+
  ```
- The three obstacle shapes are:
  ```text
  Omega_-, Omega_0, Omega_+
  ```
- The center-cell artificial boundaries are:
  ```text
  Gamma_-, Gamma_+
  ```
- The center obstacle boundary is temporarily denoted:
  ```text
  Sigma = partial Omega_0
  ```

For Barnett-style comparisons, use the project convention:

```text
lambda = horizontal Bloch multiplier
beta   = y-quasimomentum
exp(1i * beta * d) = y-direction Bloch phase
```

Avoid using Barnett’s original `beta` symbol for the y-direction phase without translating it into the project notation.

---

## What counts as success?

A script in this folder should print explicit diagnostics, such as:

```text
minimum sigma_min over scan
locations of sigma_min dips
transfer/Bloch lambda values with abs(lambda) near 1
distance from arg(lambda) to nearest sigma_min dip
BIE residual norm
port matching residual norm
reflection norm in the no-defect perfect-crystal test
```

For convergence checks, compare observables as discretization parameters are refined, for example:

```text
boundary nodes N
Rayleigh truncation M
proxy source count
check point count
```

The most important quantities are not only linear-system residuals, but also stable convergence of physically meaningful outputs such as Bloch multipliers and reflected/transmitted amplitudes.

---

## Non-goals

This folder is not intended to implement the full linear-defect scattering workflow. That belongs in the main scattering scripts, such as future `scat_ld_*` scripts.

This folder is also not meant to solve the general 2D band-structure problem robustly. The first Barnett-style scan may use a direct 2D quasiperiodic Green function and may fail near empty-cell resonances. That is acceptable for the current validation stage, provided the test parameters are chosen away from such resonances.
