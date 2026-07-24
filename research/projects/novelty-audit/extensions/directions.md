# Incremental innovation directions and backup routes

## Frozen route baseline

The original report's **recommended main route** is in Section “推荐主路线、备用
路线与停止条件 / 推荐主路线”. Its **conservative backup** is the following
subsection and is called **backup A** here solely for cross-reference. The old
wording, ranking, stop criteria, and turn criteria remain unchanged.

## New direction 7

- **Direction name:** Projected-edge approach and stable-trace conditioning.
- **Core question:** quantify the collapse of multiplier separation, decay rate,
  relation angle, and discretization accuracy as a guided mode approaches a
  fixed-`beta` projected edge from inside a gap.
- **Relation to draft:** direct strengthening of old direction 4.
- **Difference from literature:** combine high-order interface BIE error,
  invariant-subspace gap, and physical mode error in one parameter-uniform law.
- **Why potentially innovative:** existing comparisons expose slow confinement,
  but the present search did not verify a BIE-relation condition/error law.
- **Why possibly insufficient:** a benchmark-only study would repeat known
  supercell/DtN observations.
- **Literature still to verify:** threshold resolvent asymptotics, wave-FEM
  subspace perturbation, slow-light conditioning.
- **Continuous target:** estimate the outgoing relation angle versus edge
  distance/group velocity.
- **Discrete target:** prove a joint Nyström--Rayleigh--QZ subspace bound.
- **Algorithm target:** ordered-QZ continuation with adaptive trace scaling.
- **Benchmark:** Fliss/Klindworth poorly confined mode plus a noncircular rod.
- **Minimum publishable unit:** one asymptotic/perturbation bound and a verified
  three-axis convergence study strictly inside the gap.
- **Theory / implementation difficulty:** high / medium-high.
- **Prior-art risk:** medium.
- **Main failure:** constants blow up with no usable pre-asymptotic regime.
- **Salvage:** reproducible threshold-conditioning benchmark and stable QZ tool.
- **New-round priority:** **1 (does not alter the old ranking).**

## New direction 8

- **Direction name:** Limiting-absorption Cauchy relation at a unit-circle
  multiplier.
- **Core question:** define the physical trace relation when group velocity
  vanishes or a Bloch multiplier is repeated/defective.
- **Relation to draft:** replaces the discarded-unit-circle rule by a theorem.
- **Difference from literature:** transport LAP/weighted-space threshold theory
  into a computable relation coupled to the central BIE.
- **Why potentially innovative:** the exact line-defect BIE coupling was not
  found.
- **Why possibly insufficient:** it may be a coordinate rewrite of existing
  radiation theory if no new limit or computation is proved.
- **Literature still to verify:** Krein signatures, threshold scattering
  matrices, Puiseux expansions of periodic operator pencils.
- **Continuous target:** existence/uniqueness of a relation-valued limit.
- **Discrete target:** convergence of clustered generalized traces.
- **Algorithm target:** flux/Jordan-aware relation basis.
- **Benchmark:** analytically soluble periodic guide with a double multiplier.
- **Minimum publishable unit:** one scalar threshold type, no Wood coincidence.
- **Theory / implementation difficulty:** extreme / high.
- **Prior-art risk:** medium-high.
- **Main failure:** LAP depends on damping or the relation is path-dependent.
- **Salvage:** a rigorous negative result and threshold diagnostics.
- **New-round priority:** **4.**

## New direction 9

- **Direction name:** Analytic periodic-lead trace pencil for complex frequency.
- **Core question:** construct an outgoing Bloch Cauchy relation analytic on a
  declared complex-`k` sheet for fixed real `beta`.
- **Relation to draft:** analytic replacement for `abs(lambda)` selection.
- **Difference from literature:** periodic half-leads plus the current
  scattering/BIE trace architecture, rather than homogeneous/slab/fiber exteriors.
- **Why potentially innovative:** no direct complete instance was verified.
- **Why possibly insufficient:** analytic mode continuation and nonlocal
  waveguide boundaries already have strong precedents.
- **Literature still to verify:** complex band structure, Evans functions,
  operator-valued Riesz projectors for Maxwell periodic leads.
- **Continuous target:** meromorphic Fredholm trace projector on a sheet.
- **Discrete target:** contour-consistent QZ/Riesz projector convergence.
- **Algorithm target:** branch tracker seeded in the passive upper half-plane.
- **Benchmark:** homogeneous guide, then one periodic cylinder row.
- **Minimum publishable unit:** branch-free domain away from thresholds.
- **Theory / implementation difficulty:** very high / high.
- **Prior-art risk:** high.
- **Main failure:** unavoidable cell poles or branch monodromy in the contour.
- **Salvage:** a tested complex band/trace continuation package.
- **New-round priority:** **2.**

## New direction 10

- **Direction name:** Müller BIE plus contour resonance solver with physical
  pole certification.
- **Core question:** compute all complex-frequency resonances in a branch-free
  domain and distinguish physical poles from representation/cell poles.
- **Relation to draft:** upgrades old direction 3 from real guided roots to
  complex resonances.
- **Difference from literature:** the contribution must be the certified
  periodic-lead relation/BIE pencil, not Beyn's algorithm.
- **Why potentially innovative:** the exact operator coupling and residual suite
  were not found.
- **Why possibly insufficient:** BIE leaky modes, scattering poles, and contour
  BEM NEPs are established separately.
- **Literature still to verify:** meromorphic NEPs with known poles, determinant
  ratios, nonlinear Jordan chains.
- **Continuous target:** zero/pole correspondence with the resonant resolvent.
- **Discrete target:** no-pollution convergence and contour count stability.
- **Algorithm target:** Beyn/Riesz moments plus pole subtraction and field
  reconstruction.
- **Benchmark:** dielectric disk/cavity, periodic slab, then line defect.
- **Minimum publishable unit:** one polarization and one simple periodic lead.
- **Theory / implementation difficulty:** high / high.
- **Prior-art risk:** high.
- **Main failure:** nonanalytic proxy/mode selection corrupts contour moments.
- **Salvage:** an analytic complex-parameter central BIE and test suite.
- **New-round priority:** **2.**

## New direction 11

- **Direction name:** Guided-to-leaky continuation and real-axis pole crossing.
- **Core question:** track a guided mode as geometry moves it through a spectral
  boundary into a resonance or, under symmetry, a BIC.
- **Relation to draft:** uses existing parameter scans after directions 9--10.
- **Difference from literature:** periodic-half-lead trace relation in the
  dielectric-cylinder line defect.
- **Why potentially innovative:** could reveal a geometry-specific bifurcation
  with certified sheet tracking.
- **Why possibly insufficient:** periodic slab guided-resonance/BIC perturbation
  theory is extensive.
- **Literature still to verify:** line-defect BICs and exceptional points in
  infinite transverse photonic-crystal leads.
- **Continuous target:** local Puiseux/perturbation law for pole motion.
- **Discrete target:** path-independent branch/eigenvector continuation.
- **Algorithm target:** pseudo-arclength continuation with contour recounting.
- **Benchmark:** symmetry-breaking path with an independently computed Q factor.
- **Minimum publishable unit:** one simple crossing and one asymptotic law.
- **Theory / implementation difficulty:** high / high.
- **Prior-art risk:** very high.
- **Main failure:** observed branch is a finite-truncation artifact.
- **Salvage:** robust continuation and BIC/resonance diagnostics.
- **New-round priority:** **3.**

## New direction 12

- **Direction name:** Relation-valued guided/threshold/leaky umbrella.
- **Core question:** identify the maximal domain on which gap-stable,
  propagating-outgoing, complex-outgoing, and threshold-limiting trace spaces
  are parts of one relation family.
- **Relation to draft:** long-term conceptual completion of old direction 6.
- **Difference from literature:** current line-defect geometry and interface-only
  Müller coupling with a common certified implementation.
- **Why potentially innovative:** full intersection not verified.
- **Why possibly insufficient:** may be formal unification of known casewise
  theories and too broad to prove.
- **Literature still to verify:** analytic relations, boundary triples,
  resonance sheets of periodic operators, full-vector Maxwell thresholds.
- **Continuous target:** relation family on a branched cover with LAP boundary
  values.
- **Discrete target:** structure-preserving approximation of its projectors.
- **Algorithm target:** case-aware unified API, not a falsely branch-blind solver.
- **Benchmark:** guided, near-edge, threshold model, and resonance in one geometry.
- **Minimum publishable unit:** none as advertised; split into directions 7/9/10.
- **Theory / implementation difficulty:** extreme / extreme.
- **Prior-art risk:** high.
- **Main failure:** only notation is common.
- **Salvage:** a coherent multi-paper architecture and survey.
- **New-round priority:** **5 (long-term only).**

## New-round ranking only

This ranking does not modify the baseline six directions: 7 first; 9 and 10
joint second; 11 third; 8 fourth; 12 long-term. Direction 7 offers the smoothest
transition. Directions 9--10 require an analytic refactor before scientific
claims. Direction 8 is a deep theory project. Direction 12 is a program title.

## Backup route B: Band-edge stability inside the gap

- **Activation:** the old main theorem loses novelty or exact threshold theory
  is not ready, while reliable guided modes can still be computed in a gap.
- **Relation to old routes:** extends old direction 4 without changing main/A.
- **Stage 1:** track multipliers, group velocity, decay, trace angle, and
  condition numbers toward a projected edge.
- **Stage 2:** separate BIE, Rayleigh, relation, and eigensolver errors; compare
  RtR and supercell.
- **Stage 3:** derive/adapt an error-cost rule and release a benchmark.
- **Minimum result:** one inside-gap stability law plus convergence data.
- **Stop:** no reproducible asymptotic regime under mesh/order refinement.
- **Turn:** if continuous proof fails, publish a certified computational study.
- **Keep:** geometry/quadrature, Müller blocks, scattering matrices, real scans.
- **Build:** ordered-QZ tracking, group-velocity/flux, error budget.
- **Theory / implementation risk:** high / medium.
- **Likely paper:** numerical analysis.

## Backup route C: Complex resonance solver

- **Activation:** old guided-mode route stalls, and a branch-free complex domain
  can be fixed with independent resonance benchmarks.
- **Relation to old routes:** exploratory realization of old direction 6 and
  extension of old contour-certification direction.
- **Stage 1:** make central BIE and homogeneous/simple-lead boundary analytic in
  complex `k`; verify time convention and branches.
- **Stage 2:** add contour counting, pole subtraction, and physical residuals.
- **Stage 3:** replace simple lead by a periodic lead and track one line-defect
  resonance.
- **Minimum result:** certified complex poles for a simple periodic-lead model.
- **Stop:** analytic/meromorphic sampling cannot be made contour-consistent.
- **Turn:** retain the central BIE and use an established DtN/PML exterior.
- **Keep:** central geometry, Nyström quadrature, field reconstruction, cell S.
- **Build:** branch manager, analytic proxy elimination, contour NEP, residue QA.
- **Theory / implementation risk:** very high / high.
- **Likely paper:** computational physics or numerical methods.

## Long-term route: Guided--threshold--leaky relation program

- **Activation:** only after route B establishes near-edge control, route C
  establishes complex-sheet BIE stability, the LAP branch is explicit, and a
  renewed search still finds no direct complete prior art.
- **Relation:** umbrella over old directions 1--4/6 and new directions 7--12;
  it does not replace any baseline route.
- **Stage 1:** regular real/complex sheet without thresholds.
- **Stage 2:** one classified threshold and limiting relation.
- **Stage 3:** continuation across the boundary plus TE/TM or Maxwell extension.
- **Minimum result:** should be split into at least two papers.
- **Stop:** unification is only notation or absorption-dependent with no stated
  physical model.
- **Turn:** publish the regular-sheet theory and threshold work separately.
- **Keep:** all relation/BIE/contour components with explicit regime labels.
- **Build:** weighted-space threshold basis and branched-cover continuation.
- **Theory / implementation risk:** extreme / extreme.
- **Likely output:** two-to-three-paper long-term research program.
