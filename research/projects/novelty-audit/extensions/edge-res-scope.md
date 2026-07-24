# Band-edge and resonance extension scope

Search cutoff: **2026-07-21 (Asia/Shanghai)**.

## Frozen baseline

The baseline is the completed 2026-07-20 audit. Its report, six innovation
directions, ranking, main route, conservative backup route, stop criteria, and
turn criteria are immutable in this extension. The pre-extension hashes and
dirty-worktree inventory are recorded in
`checkpoints/pre_extension_2026-07-21.md`.

The old audit covered fixed-real-`beta` guided eigenvalues in projected gaps,
Fliss-type DtN/RtR truncation, generalized Bloch modes, a Müller central-cell
representation, one-cell scattering pencils, spurious BIE kernels, and real-axis
smallest-singular-value scans. Its six directions were, in their original order:

1. spurious-free Müller--Cauchy-relation guided-mode operator;
2. error/conditioning of generalized stable Bloch Cauchy relations;
3. contour NEP plus physical-field residual certification;
4. joint error control for poorly confined modes near a band edge;
5. different left/right periodic leads;
6. Wood anomalies, unit-circle multipliers, or complex leaky resonances.

The old main route remains the proof repair + generalized stable relation +
spurious-free kernel theorem + contour/residual certification route. The old
conservative backup (called backup A in the addendum) remains high-order
Müller--RtR plus convergence, complete contour counting, residual filtering,
and near-edge benchmarks. Their old priorities and stop/turn criteria are not
reinterpreted here.

The frozen priority order is direction 1 plus direction 3 as the theorem/solver
main line, directions 2 and 4 as second priority, direction 5 as third priority,
and direction 6 as fourth/exploratory. The baseline risk table judged direction
6 highest overall; directions 2 and 4 next on theory/edge conditioning;
direction 1 high on proof risk; direction 5 moderate; and direction 3 lowest as
an implementation component. This risk ordering is not revised.

The baseline also advised against using any of the following as a standalone
main innovation: a TM-to-TE substitution, reproving Fliss bounded equivalence,
replacing FEM by BIE alone, reproducing the scattering-to-Bloch pencil,
MFS/Linton validation alone, adding plots without analysis, or calling a
standard contour solver without resolving poles/spurious kernels. Those
negative recommendations remain in force.

## Incremental scope

This round adds three evidence layers:

- a twelve-way distinction among bulk edges, fixed-`beta` projected edges,
  half-guide thresholds, unit-circle multipliers, repeated/defective
  multipliers, zero group velocity, cutoff/grazing, approach to essential
  spectrum, threshold eigenvalues, threshold resonances, poorly confined gap
  modes, and band-edge bifurcations;
- a thirteen-way distinction among leaky modes, resonant modes, quasinormal
  modes, scattering/resolvent poles, complex-frequency and complex-propagation
  eigenproblems, outgoing NEPs, guided resonances, quasi-guided modes, high-Q
  resonances, and nearby-BIC resonances;
- prior-art and feasibility audits for a common central Müller operator coupled
  to a relation-valued periodic-lead trace condition on real-gap, propagating,
  complex-frequency, and threshold regimes.

## Keyword overlap and work not repeated

Overlap terms include periodic waveguide, line defect, DtN/RtR, Bloch modes,
translation/scattering operator, Müller BIE, generalized eigenproblem, contour
NEP, and physical residual. The previous 20 paper notes, 31-column matrix,
claim audit, proof-error diagnosis, and six-direction ranking are not redone.
Existing papers reappear only when a new threshold/resonance fact is extracted.

## Evidence still needed after the baseline

The baseline lacked theorem-level evidence for threshold radiation selection,
zero-group-velocity degeneracy, complex-frequency Bloch branch continuation,
the sign dictated by the time convention, Wood/Rayleigh branch points in a
complex NEP, and direct BIE prior art for leaky photonic-crystal waveguides.
It also had not audited whether the MATLAB path is a holomorphic matrix-valued
function. Those gaps are the subject of this extension.

## Scope boundary

Photonic-crystal slabs/fibers, gratings, homogeneous open waveguides, and BICs
are adjacent rather than geometrically identical. They are used only to audit
method components. No absence-of-search-result is converted into a priority
claim. In particular, “complex arithmetic runs” is not treated as proof of an
analytic continuation, and `|lambda|<1` is not treated as a universal complex-
frequency outgoing condition.
