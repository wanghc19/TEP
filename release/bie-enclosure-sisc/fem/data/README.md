# Canonical finite element data

FEM means finite element method; DtN means Dirichlet-to-Neumann; RT3 means Raviart–Thomas degree three; NPZ is a ZIP archive of NumPy arrays; JSON is JavaScript Object Notation.

`ex1/native.json` and `native.npz` describe the actual P3 field. The JSON dictionary recursively records array, structure and cell types, dimensions and field names. Each `array_*` item in the archive is a standard NumPy array, with its dtype also recorded in JSON. Numeric entries preserve their original MATLAB numerical class and binary64 bits, including complex real/imaginary parts. Compressed MAT integer storage is distinguished from the MATLAB double class; the class-aware roundtrip compares shapes, classes and value bits. Object arrays and pickle are not stored.

The `native` variable holds the three quadratic native geometry templates, material labels, interface parameter endpoints and cell indices, P3 nodal connectivity and field coefficients in the center and 13 cells on each side. `example` holds all geometry, density, phase, mesh, taper, quadrature, tolerance and resource parameters. The actual trial is the native field multiplied by the recorded cosine taper; it is zero beyond the two outer cuts. The true material curves enter the integral certificates through their separate analytic definitions and correction strips.

`ex1/flux.json` and `flux.npz` contain `canonical_flux.B`, the integer RT3 basis table, and `canonical_flux.flux`, local coefficients indexed by template, local basis function, cell and triangle. Verify reconstructs the exact-curve Piola maps and checks shared normal moments, quasi-periodic moments and zero exterior normal moments. No field or flux solve is repeated.

The two NPZ files (`native.npz` 13.2 MB, `flux.npz` 61.4 MB) are not tracked in Git; the JSON dictionaries are. Regeneration from a fresh h=1/48 interval run is described in [../README.md](../README.md#arrays-not-tracked-in-git).

`integrals.json` is the post-computation comparison target for E/M/S and the held-fixed scale. It does not supply integral values to the computation.

The remaining JSON files describe the isolation inputs:

- `band.json`: panel chain, both lead identities and computed margins. Verify repeats the indicator integral and all 472 finite sign tests from the bundled source parameters.
- `left-1/`, `left-2/`, `right-1/`, `right-2/`: surface C, residual H and squared-Poisson V2 matrices, response U, analytic integration remainders and diagnostics. Verify reads these integrated matrices and remainders, rebuilds the error matrices and both Schur tests, then checks the zero counts and resolvent constants.
- `surface.json`: endpoints, material and phase metadata, zero endpoint counts and input-derived K constants. Consumers check model and endpoint matches.
- `left/`, `right/`: integrated DtN Q/R/Z matrices and analytic integral/lead-series error allowances. Verify reads these, then rebuilds all-trace lower matrices and high-mode penalties.
- `left-certificate.json`, `right-certificate.json`: explicit physical port orientation, Fourier order, constants and lower-matrix handoffs to the core stage.
- `core-result.json`: comparison target for the core recomputation. Core material integrals, projection constants and finite inertia are rebuilt from the bundled model and the two canonical DtN handoffs.

MATLAB version-5 files exist only as transport in a run directory. `scripts/arrays.py` converts the canonical representation back to MATLAB transport; promotion checks every array's dtype, shape and numeric entries by a full round trip. All FEM integration and finite-matrix bounds here use the original rounding-excluded arithmetic convention.

The saved example struct retains three unused pre-search placeholders: `example.discretization.native.k0`, `mu0`, and `window` are NaN. They are not field coefficients or numerical inputs to verification. The canonical smoke test allows only these named placeholders; every other numeric array must be finite. The actual computed candidate is retained separately in the native result.
