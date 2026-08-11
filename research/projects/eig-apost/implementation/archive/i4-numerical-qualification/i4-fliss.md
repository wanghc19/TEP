# I4 Fliss missing-column benchmark

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: plan/run/validate
- Origin Date: 2026-08-08
- Verification Status: PARTIAL SUCCESS; TRACK A CANDIDATE READY; TRACK B BLOCKED
- Version Label: eig-apost-i4-fliss-v1.0
- Governing Method: [[research/projects/eig-apost/phase4-report/method.tex|conditional method]]
- Open Problems: [[research/projects/eig-apost/implementation/open-problems#I4|I4 ledger]]

## Scope decision

The primary I4 real case now has identical left and right periodic media and one
changed center column. The earlier unequal-ellipse configuration remains a historical
negative locator result and no longer determines whether the primary model has a root
candidate.

Two numerical tracks are kept strictly separate.

1. `fliss-smooth-fd` discretizes the period-one smooth coefficient reported by Fliss,
   with

   $$
   \rho_p(x,y)=1+16\exp\left(-\frac{x_{\mathrm{loc}}^2+y_{\mathrm{loc}}^2}{0.2^2}\right)
   $$

   in every perfect cell and $\rho_0=1$ in the center column. It is the only track
   allowed to test the reported primary point $(\beta,\lambda)=(0.5,3.465)$, where
   $\lambda=k^2$.

2. `sharp-disk-bie-surrogate` uses a radius-$0.2$ disk with constant refractive-index
   ratio $n=\sqrt{17}$ and continuation through $n=3,2,1.5$. It matches the peak and
   approximately the integrated contrast, but it is not the Fliss coefficient and cannot
   pass the paper-value reproduction gate.

All new experiment code and generated artifacts belong under `test/i4-fliss-2013/`.
No package source is modified.

## Track A discrete projected spectrum

For fixed $\beta$, the perfect-cell discretization is

$$
K_h(\theta,\beta)u=\lambda M_{\rho,h}u,
\qquad \theta\in[-\pi,\pi],
$$

with phases $\exp(\mathrm{i}\theta)$ and $\exp(\mathrm{i}\beta)$ across the $x$ and
$y$ cell boundaries. The reported object is the discrete spectrum

$$
\sigma_{\mathrm{ess}}^h(\beta)
=\bigcup_j
\left[
\min_\theta\lambda_{j,h}(\theta,\beta),
\max_\theta\lambda_{j,h}(\theta,\beta)
\right],
$$

not an uncertified exact essential spectrum.

For a band edge $e$, the frozen empirical uncertainty is

$$
\varepsilon_e=\max\left\{
|e_{80}^{\mathrm{loc}}-e_{40}^{\mathrm{loc}}|,
|e_{80}^{\mathrm{loc}}-e_{80}^{\mathrm{grid}}|,
|e_{80}^{\mathrm{loc}}-e_{80}^{\mathrm{shift}}|
\right\}.
$$

An accepted gap requires both edge uncertainties at most $10^{-3}$ in $\lambda$,
width greater than $20\max\varepsilon_e$, and a candidate distance of at least
$10\max\varepsilon_e$ from both adjacent bands. Eigenpairs use the normalized backward
residual

$$
r_{\mathrm{EVP}}
=\frac{\lVert Ku-\lambda Mu\rVert}
{\lVert Ku\rVert+|\lambda|\lVert Mu\rVert}
\le 10^{-10}.
$$

The finite-strip positive control compares eight and twelve perfect cells on each side.
It must reject end-localized states, retain a center-localized state with recentered
mass overlap at least $0.95$, and reproduce $3.465$ within two percent. The paper-value
gate is only a reproduction check; spatial and tail self-convergence are reported
separately.

## Continuation and Track B boundary

The smooth-profile continuation starts at $s=1$ and decreases through
$1,7/8,\ldots,1/8$ in

$$
\rho_p^{(s)}=1+16s\exp\left(
-\frac{x_{\mathrm{loc}}^2+y_{\mathrm{loc}}^2}{0.2^2}
\right).
$$

It may terminate normally when the gap closes or the tracked branch reaches the discrete
band union. It is not required to persist to $s=0$, where the defect and gap disappear.

Track B uses the public one-cell scattering and empty-column trace-matching interfaces
with $L=d=1$. Its projected-gap and real-axis singular-value scans are diagnostics only.
Endpoint fallback minima, Wood-threshold features, changing mode counts, or
refinement-unstable classifications cannot seed complex root isolation.

## Stage boundary

The completed benchmark closes the empirical projected-gap blocker for Track A but not
the BIE root-readiness blocker.

## Executed evidence

The exact-profile baseline and the targeted adjacent-edge confirmation were run with
Octave. For the primary case $\beta=0.5$, the twelve-cell-tail strip returned

$$
\lambda_h=3.4609750440405129,
\qquad
k_h=\sqrt{\lambda_h}=1.860369598773457,
$$

with normalized residual $1.01\times10^{-12}$, center mass fraction $0.4959$, end mass
fraction $6.97\times10^{-10}$, eight/twelve-tail relative shift
$2.32\times10^{-7}$, and mass-vector overlap $0.99999991$. The relative difference from
the reported Fliss value $3.465$ is $0.116\%$.

The original baseline kept its preregistered N40/N80 edge gate and therefore remained
`gap_gate_pass=0`. A separate N80/N120 targeted confirmation did not overwrite that
result. It obtained

$$
\varepsilon_{80,120}=7.908512\times10^{-4},
\qquad
G_{\mathrm{safe}}=(1.9813502436,5.3868187296),
$$

with candidate margin $1.4796248004$ and maximum normalized residual
$7.98\times10^{-13}$. All four targeted edge, width, margin, and residual gates passed.
The combined full-Brillouin-zone baseline and targeted refinement therefore support
`TRACK_A_PROJECTED_GAP_CONFIRMED` and `I4_FD_CANDIDATE_READY`. These labels mean a
credible finite-difference eigenvalue candidate in the exact smooth profile, not a
qualified infinite-domain BIE root.

Track B did not reach a usable real-axis defect scan. At $M=10$, the one-way Bloch
pencil retained only $32$ of the expected $42$ finite multipliers because both
transmission blocks had numerical rank $11$ for $K=21$. A bidirectional small-multiplier
diagnostic restored full trace counts and well-conditioned normalized trace bases, but
the decisive pencil gates still failed. At $M=5$, the maximum forward/reverse normalized
residuals were $3.15\times10^{-6}$ and $9.43\times10^{-4}$ against the $10^{-8}$ gate,
and the reciprocal-conjugate pairing defect was $1.58\times10^{-5}$ against the
$10^{-6}$ gate. The normalized traces were full rank and well conditioned, but the
assembled $44\times44$ $A_{\mathrm{def}}$ had numerical rank only $8$ at the recorded
relative threshold; its $1.18\times10^{-17}$ normalized singular value is therefore not
an interpretable dip. The $M=10$ failures were larger. Consequently the status is
`BIE_PROJECTIVE_SUBSPACE_BLOCKED`; the implemented M4/M5 real-axis smoke scan was not
run.

## Final I4 boundary

The revised benchmark is a partial success: it supplies the first credible real-case
eigenvalue candidate and confirms its empirical discrete projected gap, so the earlier
monotone double-ellipse locator is no longer evidence that the Fliss missing-column
model has no solution. It does not authorize root isolation. Before a BIE locator can
be interpreted, a scale-balanced projective ordered-QZ or equivalent deflating-subspace
construction must pass residual, reciprocal-subspace, trace-rank, and scaling gates.
The center/propagation matrix must also receive block-level equilibration, and the
bounded scanner must be connected to the accepted bidirectional bases rather than the
legacy affine mode path.
For the exact Gaussian model, an additional model-consistent infinite-domain evaluator
is also required; the sharp-disk surrogate cannot inherit the Track A candidate.

The benchmark does not provide a fixed analytic chart, pole-free complex disk, contour
root count, bordered Newton root, eigenvalue estimator, or effectivity. Those objects
remain downstream gates in [[research/projects/eig-apost/implementation/archive/i4-numerical-qualification/i4-result|the
historical I4 result]] and the project ledger.
