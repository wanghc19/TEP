# Transition feasibility audit

Audit date: 2026-07-21. This is a read-only audit of the current draft and
MATLAB tree; no MATLAB/Octave execution was performed.

## Executive comparison

| Metric | Band edge | Leaky resonance | Unified enlarged topic |
|---|---|---|---|
| Geometry reuse | extremely high | high | high |
| Code reuse | high near but not at edge | medium | medium-low |
| Theory difficulty | high; very high at exact threshold | very high | extreme |
| Numerical difficulty | high | high | extreme |
| Prior-art risk | medium | high | high but fragmented |
| Publication potential | numerical analysis/theory | computational physics/numerics | multi-paper program |
| Salvage after failure | benchmark, conditioning laws, stable QZ tools | complex BIE kernel, branch tests, resonance benchmark | common software architecture only |
| Near-term main line? | yes, inside-gap approach only | no; backup after analytic refactor | no |

“Reuse” is qualitative because a line count would overstate mathematical reuse.
Geometry and quadrature survive more readily than the radiation-selection proof.

## Theory assets

| Asset | Band-edge reuse | Resonance reuse | Required change / immediate failure |
|---|---|---|---|
| Current dielectric-cylinder line-defect geometry | direct | direct for infinite periodic transverse leads | none geometrically; first benchmarks should simplify leads |
| Fixed-`beta` strip reduction | direct for projected edge | direct only for fixed real `beta`, complex `k`; not for fixed real `k`, complex axial beta | choose one spectral slice and state it explicitly |
| Theorem 1 bounded/global equivalence | inside a strict gap only | not directly | decay and half-guide uniqueness fail at continuous spectrum/complex sheet |
| Outgoing trace-subspace definition | promising relation language | promising | replace pointwise stable-mode selection by an analytic/limiting relation |
| DtN graph interpretation | valid where Dirichlet projection is invertible | meromorphic local tool | graph can blow up or become multivalued at half-guide eigenvalues/thresholds |
| Rayleigh expansion | diagnostic and homogeneous benchmark | reusable locally on a chosen sheet | `gamma_m=sqrt(k^2-beta_m^2)` has branch points; outgoing QNM fields can grow |
| Single-cell representation | reusable away from singular parameters | reusable locally in complex `k` | prove analyticity/Fredholmness and handle branch sheets |
| Müller formulation | direct | high reuse away from branch points | second-kind does not by itself prove no spurious resonant roots |
| Scattering-to-Bloch pencil | direct for near-edge tracking | algebra reusable | ordered stable/unstable split is nonanalytic at unit circle and collisions |
| Stable multiplier selection | works strictly in a gap | fails as universal rule | `abs(lambda)<1` must be replaced by continuation from an absorptive/passive sheet |
| Conjecture 1 | needs Jordan/generalized modes already at edge | insufficient | use invariant subspaces/Jordan chains and flux pairing |
| Conjecture 2 | useful numerical conjecture inside regular region | insufficient | formulate a holomorphic/meromorphic operator and pole-zero certification |

## Code modules

### Module: quasiperiodic Green function

- **Current role:** `+kernel/qpgreen_mfs.m` and
  `qpgreen_mfs_pairmat.m` approximate the quasiperiodic Green function using
  neighboring images, proxy sources, and Rayleigh matching.
- **Reusable for band edge?** High away from a Rayleigh/Wood point; lower at
  `gamma_m=0` because the classical Rayleigh representation is singular.
- **Reusable for resonance?** Medium. Hankel evaluations accept complex
  arguments, but the chosen branch and proxy least-squares solve are not proved
  analytic or stable on a contour.
- **Required modifications:** introduce an explicit sheet object/branch tracker;
  avoid sign flips based on the instantaneous imaginary part; add a shifted-
  Green/free-space-proxy fallback at Wood anomalies; make rank decisions fixed
  over a contour.
- **New validation tests:** reciprocity and quasiperiodicity at complex `k`;
  comparison with direct lattice sums where convergent; loop continuation
  around but not through a branch point; Wood-limit benchmark.
- **Expected difficulty:** high.

### Module: MFS proxy construction

- **Current role:** `+kernel/precomp_proxy.m` solves an overdetermined matching
  system with `lsqminnorm` or `pinv`.
- **Reusable for band edge?** Medium for fixed real parameters.
- **Reusable for resonance?** Low as currently written: SVD/rank thresholds can
  change discontinuously with `k`, destroying holomorphy required by contour
  integration.
- **Required modifications:** preselect a fixed basis and fixed-rank analytic
  factorization, or eliminate proxy coefficients by a contour-consistent block
  system rather than a parameter-dependent pseudoinverse.
- **New validation tests:** Cauchy-Riemann/complex-step consistency of the
  assembled matrix; rank constancy around contours; comparison under proxy
  radius/order changes.
- **Expected difficulty:** high.

### Module: Müller matrix assembly

- **Current role:** `+op/construct_A_QP.m` assembles the central transmission
  operator from layer-potential blocks.
- **Reusable for band edge?** Extremely high; the center geometry is unchanged.
- **Reusable for resonance?** High locally on a fixed kernel sheet.
- **Required modifications:** expose `A(k)` without nonanalytic preprocessing;
  document time convention and Hankel sheet; retain field-reconstruction maps
  for spurious-root tests.
- **New validation tests:** complex-`k` manufactured transmission problem;
  comparison with real-axis scattering limits; zero-density/nonzero-field and
  nonzero-density/zero-field tests.
- **Expected difficulty:** medium-high.

### Module: Rayleigh channel construction

- **Current role:** `+bloch/rayleigh_channels.m` computes
  `gamma=sqrt(k^2-beta_m^2)` and flips signs where `imag(gamma)<0`.
- **Reusable for band edge?** Medium; fine away from grazing, invalid exactly at
  `gamma=0` for extractors containing `1/gamma`.
- **Reusable for resonance?** Low as a holomorphic function because the sign
  test is pointwise and discontinuous.
- **Required modifications:** continue each channel from a declared base point;
  encode the `e^{-i omega t}` convention; forbid contours crossing channel
  branch points or use a local covering variable.
- **New validation tests:** closed-loop monodromy; upper-half-plane passive
  limit; correct lower-half-plane QNM continuation; grazing asymptotics.
- **Expected difficulty:** high.

### Module: one-cell scattering matrix

- **Current role:** `+bloch/construct_S.m` solves the cell BIE for incident port
  traces and constructs a finite scattering matrix.
- **Reusable for band edge?** High, subject to conditioning.
- **Reusable for resonance?** Medium. Complex linear algebra works, but cell
  poles make `S(k)` meromorphic and branch-dependent.
- **Required modifications:** expose pole diagnostics, analytic factorizations,
  and a square system that can be sampled without adaptive rank changes.
- **New validation tests:** unitarity/flux on real lossless points; reciprocity;
  analytic derivative checks; pole-zero cancellation checks.
- **Expected difficulty:** medium-high.

### Module: generalized eigenproblem

- **Current role:** `+bloch/solve_modes.m` calls generalized `eig(A,B)`, removes
  nonfinite values, normalizes, and sorts/classifies modes.
- **Reusable for band edge?** Algebra yes; eigenvectors alone no at repeated or
  defective multipliers.
- **Reusable for resonance?** Low for contour sampling because eigenvalue order
  and normalization jump.
- **Required modifications:** ordered generalized Schur/QZ; invariant-subspace
  tracking; Jordan-chain/cluster handling; biorthogonal flux normalization on
  the real axis; analytic projector rather than sorted eigenvectors.
- **New validation tests:** artificial double multiplier, avoided/crossing
  multipliers, unit-circle passage, forward/backward continuation hysteresis.
- **Expected difficulty:** very high.

### Module: Bloch multiplier selection

- **Current role:** `+bloch/select_port_traces.m` takes `|lambda|<1-tol` on the
  positive lead and `|lambda|>1+tol` on the negative lead, discarding the unit
  circle.
- **Reusable for band edge?** Only strictly inside a gap.
- **Reusable for resonance?** No as a physical definition. Analytic continuation
  of a QNM may produce spatially growing outgoing fields.
- **Required modifications:** select real-axis propagating channels by energy
  flux/group velocity; select complex modes by continuation from a passive
  absorptive problem; keep clusters as graph/Cauchy relations.
- **New validation tests:** homogeneous-guide truth cases; loss-to-zero LAP;
  continuation across a guided-to-leaky transition without branch relabeling.
- **Expected difficulty:** very high and theory-dominant.

### Module: trace matching

- **Current role:** `mode_traces.m`, `select_port_traces.m`, and assembly code
  match central traces to selected lead traces.
- **Reusable for band edge?** High if reformulated as a relation/subspace.
- **Reusable for resonance?** High structurally.
- **Required modifications:** allow multivalued Cauchy relations and clustered
  invariant bases; scale Dirichlet/Neumann traces; preserve analytic bases on a
  contour.
- **New validation tests:** invariance under basis changes; graph-coordinate
  singularity with relation remaining regular; left/right orientation tests.
- **Expected difficulty:** medium after the lead theory exists.

### Module: far-field/Rayleigh extractors

- **Current role:** `+bloch/farfield_extractors.m` maps boundary data to Rayleigh
  amplitudes and rejects `abs(gamma)<1e-12`.
- **Reusable for band edge?** Low at cutoff; useful away from it.
- **Reusable for resonance?** Medium on a fixed sheet.
- **Required modifications:** threshold-scaled channel variables; branch-aware
  amplitudes; distinguish physical residual from exponentially growing QNM norm.
- **New validation tests:** grazing channel with known asymptotics; flux balance
  on real axis; residue normalization at a complex pole.
- **Expected difficulty:** high.

### Module: smallest singular-value scan

- **Current role:** `tep_edc_scan_local.m` scans real `k`, forms `svd(A_def)`,
  refines intervals, and uses real scalar spike criteria.
- **Reusable for band edge?** As a diagnostic baseline only.
- **Reusable for resonance?** Very low; a two-dimensional complex grid is costly
  and singular values are nonholomorphic. It can also confuse poles and zeros.
- **Required modifications:** build an analytic/meromorphic `T(k)` sampler and
  use Beyn/Riesz/argument-principle or rational methods; retain singular values
  only for post-localization conditioning.
- **New validation tests:** known multiple roots; pole next to zero; contour
  count versus dense scan; perturbation under quadrature/order changes.
- **Expected difficulty:** medium after analytic assembly, otherwise impossible.

### Module: band-structure and projected-gap plotting

- **Current role:** `tep_edc_projected_gap_scan.m` labels a projected gap when no
  multiplier satisfies `||lambda|-1|<=tol` and plots real-axis diagnostics.
- **Reusable for band edge?** High as a map, not as a threshold theorem.
- **Reusable for resonance?** Low.
- **Required modifications:** track band derivatives/group velocity, multiplier
  clusters, and distance to Rayleigh branch points; never equate a tolerance
  crossing with a classified threshold.
- **New validation tests:** analytic homogeneous bands; grid-refinement stability;
  comparison of projected edge with separately computed bulk edge.
- **Expected difficulty:** medium.

### Module: cached geometry and quadrature

- **Current role:** stores interfaces, normals, parametrizations, and Nyström
  quadrature data.
- **Reusable for band edge?** Extremely high.
- **Reusable for resonance?** Extremely high.
- **Required modifications:** separate all `k`-independent cache data from
  parameter-dependent branches/factorizations.
- **New validation tests:** cache-on/off equality for complex points; contour
  sample order independence.
- **Expected difficulty:** low.

### Module: complex arithmetic compatibility

- **Current role:** MATLAB matrices and Hankel/Bessel calls accept complex values.
- **Reusable for band edge?** Yes.
- **Reusable for resonance?** Necessary but insufficient.
- **Required modifications:** remove `abs`, parameter-dependent sorting,
  pointwise sign flips, SVD/pseudoinverse rank decisions, and real-only scan
  interfaces from the analytic path.
- **New validation tests:** complex-step derivatives and contour integral of a
  known analytic scalar observable should vanish when no poles are enclosed.
- **Expected difficulty:** medium-high.

## Direction feasibility cards

### Direction: approach a projected band edge from inside the gap

- Geometry/PDE/operator similarity: extremely high / extremely high / high.
- Reusable theory/code: high / high, because decay persists before the edge.
- New mathematics: invariant-subspace perturbation, gap/angle estimates,
  resolvent asymptotics, zero-group-velocity diagnostics.
- New numerics: ordered QZ tracking, threshold-scaled traces, adaptive precision.
- Critical unsolved issue: constants uniform in edge distance.
- Likely failure: the stable/unstable spectral gap closes faster than numerical
  error, so no uniform theorem survives.
- Minimum/full time: 3--5 months / 8--14 months.
- Direct extension? yes. Backup after current novelty failure? yes.
- Recommendation: **A for a near-edge numerical-analysis project; not a claim
  about the exact threshold.**

### Direction: exact threshold relation

- Geometry/PDE/operator similarity: high / high / medium.
- Reusable theory/code: medium / medium.
- New mathematics: LAP at zero group velocity, generalized/polynomial Bloch
  waves, weighted spaces, linear relations instead of DtN graphs.
- New numerics: threshold basis and branch-point-aware discretization.
- Critical issue: uniqueness and physical selection can depend on absorption.
- Likely failure: no single-valued limiting trace operator exists.
- Minimum/full time: 8--12 months / 18--30 months.
- Direct extension? conceptually yes, technically almost a new theory project.
- Recommendation: **C; long-term theory, not the next deliverable.**

### Direction: fixed real beta, complex-frequency resonances

- Geometry/PDE/operator similarity: high / high / medium.
- Reusable theory/code: medium / medium.
- New mathematics: analytic sheets of Rayleigh/Bloch channels, outgoing QNM
  continuation, meromorphic Fredholm pencil, pole/zero equivalence.
- New numerics: analytic proxy/BIE assembly, contour NEP, residue and physical
  certification.
- Critical issue: outgoing mode selection cannot be encoded by instantaneous
  multiplier magnitude.
- Likely failure: branch discontinuities make contour moments meaningless.
- Minimum/full time: 6--10 months / 14--24 months.
- Direct extension? not until analytic assembly is rebuilt. Backup? yes, first
  on homogeneous or finite-width leads.
- Recommendation: **B-/C+ exploratory; higher prior-art risk than band edge.**

### Direction: unified guided/threshold/leaky formulation

- Geometry/PDE/operator similarity: high / high / low-to-medium.
- Reusable theory/code: medium / medium-low.
- New mathematics: a relation-valued analytic family on several sheets with a
  limiting object at branch points; no present source supplies this entire chain.
- Critical issue: a branch point is not an ordinary eigenvalue of a holomorphic
  pencil, so one contour solver cannot cross all regimes unchanged.
- Likely failure: only notation, not operator theory or numerics, is unified.
- Minimum/full time: 12--18 months for a restricted theorem / 3--5 years for the
  advertised full scope.
- Direct extension? no. Backup? no; it is a program title.
- Recommendation: **long-term umbrella, likely two or three papers.**

