# Remaining open questions

The main logical status is settled conditionally, but the following items would
require a separate paper-level analysis to remove every hypothesis.

1. **Complementary spectrum for the exact TEP geometry.**  Determine whether
   the swapped-wavenumber quasiperiodic cylinder has guided modes for the
   parameter ranges and inclusion geometries used in the project.  This is a
   continuous spectral question; a finite matrix scan cannot prove absence.
2. **A periodic-cylinder synthesis theorem on Lipschitz interfaces.**  The
   report gives a complete reduction to the complementary outgoing problem and
   proves the smooth-interface version modulo that problem's Fredholm theorem.
   A published theorem covering exactly one periodic direction, open Rayleigh
   ends, ordinary TM transmission, and the mixed QP/free common-density ansatz
   was not located.
3. **Wood thresholds.**  A threshold-safe theorem should replace the standard
   Green function by a shifted/regularized quasiperiodic kernel and add the
   generalized mode `x psi_m`.  This changes the formulation and was therefore
   not silently included.
4. **Inclusions touching the horizontal seam or vertical ports.**  The final
   theorem assumes positive separation.  Seam-crossing inclusions need periodic
   charts; port-touching inclusions destroy the homogeneous collars used to
   define incoming and outgoing Rayleigh coefficients.
5. **Weighted TE transmission.**  If the physical normal flux is
   `a_e partial_nu u_e = a_i partial_nu u_i`, the density vector and swapped
   problem must be rederived with the weights included.
6. **Canonical projection at an exceptional complementary frequency.**  One
   can expect a Fredholm quotient-space statement: densities modulo the kernel,
   with compatibility against the adjoint cokernel.  The exact projector and
   normalization have not been fixed here.
7. **Uniform parameter estimates.**  The report proves/assumes statements at a
   fixed `(k,beta)`.  Uniform bounds deteriorate near Wood thresholds, physical
   guided modes, and complementary resonances and are needed for a robust
   parameter scan theorem.

