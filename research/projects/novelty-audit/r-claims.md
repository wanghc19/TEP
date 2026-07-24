# Claim-by-claim novelty audit

Draft audited: `draft/draft.tex` (modified 2026-07-20 21:04:36 +0800) and
`draft/appendixA.tex`. Status scale: **A** already established; **B**
straightforward extension; **C** partially new; **D** plausibly new but
insufficiently searched; **E** genuinely unresolved. A status grades the claim
as currently written, not the value of a future strengthened result.

## C1. Global guided mode iff bounded trace-subspace problem (Theorem 1)

- **Draft claim / location:** A pair ((k,\beta)) is a guided eigenpair iff a nonzero center-cell field has both port Cauchy traces in the outgoing half-guide subspaces; `draft.tex` lines 448--507.
- **Closest prior work:** Fliss (2013), Theorem 4.5; Joly--Li--Fliss (2006); Coatléven (2012).
- **Exact overlap:** Fliss proves exact equivalence, on a small defect neighborhood, between the global line-defect eigenproblem and a nonlinear problem with exact left/right DtN conditions, including multiplicity.
- **Important differences:** The draft retains the full Cauchy data relation ((u,\partial_nu)) rather than requiring it to be the graph of a single-valued DtN map.
- **Merely notational? / direct TE--TM change?** In regular graph regimes the difference is algebraic notation. At a DtN pole it could be substantive, but RtR already supplies a pole-resistant exact condition. This is not a TE/TM issue.
- **Analytical / numerical obstacle:** Define the lossless outgoing relation at thresholds and prove it is closed/Fredholm; discretize it without representation nullspaces.
- **Already proved / unproved:** Global-to-bounded equivalence with DtN is proved. A continuous lossless relation theorem covering DtN-forbidden frequencies, unit-circle multipliers, and thresholds is not proved in the draft.
- **Evidence:** Fliss 2013, Theorems 4.1/4.5 and Remark 4.2; Fliss--Klindworth--Schmidt 2015.
- **Current status:** **A** for the displayed equivalence; possible **C/D** only for a strengthened exceptional-frequency relation theorem.
- **Risk:** **High** as a headline novelty. Present it as a formulation lemma unless the exceptional-frequency theorem is added.

## C2. Outgoing Cauchy trace subspace and the DtN graph

- **Draft claim / location:** The outgoing trace space is the graph of DtN when the Dirichlet projection is invertible, but the relation survives graph failure; lines 295--433.
- **Closest prior work / overlap:** DtN transparent conditions in Joly--Li--Fliss and Fliss; RtR in Fliss--Klindworth--Schmidt; general Cauchy-data/Calderón relations make “graph when projection is invertible” elementary.
- **Difference / notational test:** The graph identity is immediate from definitions. Keeping both trace components can matter at a pole, but the draft supplies neither a closed-relation theorem nor a comparison proving superiority to RtR.
- **TE/TM:** No.
- **Obstacles:** Lossless radiation selection, topology, threshold modes, finite-dimensional approximation of a linear relation.
- **Proved / unproved / evidence:** Graph equivalence in regular regimes is standard; pole-resistant RtR is established. The exact scope and numerical conditioning of the draft relation are unproved.
- **Current status:** **B**.
- **Risk:** **High** unless converted into a theorem at forbidden frequencies with an explicit numerical advantage.

## C3. Absorbing DtN construction and lossless limit

- **Draft claim / location:** Add (i\varepsilon) to obtain a unique decaying half-guide solution and invertible Dirichlet projection; lossless limit is not treated; lines 392--433.
- **Closest prior work / exact overlap:** Joly--Li--Fliss (2006), Theorems 3.1/4.1; Coatléven (2012), Theorems 4.3--5.6; Hoang's limiting-absorption work.
- **Differences:** None material in the draft discussion.
- **Direct TE/TM:** No.
- **Obstacles:** Uniform estimates as (arepsilon\downarrow0), propagating/unit-circle modes, embedded eigenvalues.
- **Proved / unproved:** Absorbed construction is proved in prior work. The draft explicitly leaves the hard lossless limit open.
- **Current status:** **A**.
- **Risk:** **Very high** as a contribution; cite as background only.

## C4. Rayleigh expansion and incoming/outgoing coefficient extraction

- **Draft claim / location:** Non-Wood quasiperiodic fields in homogeneous port neighborhoods have unique bidirectional Rayleigh expansions and coefficient formulas; lines 509--643.
- **Closest prior work / overlap:** Linton (1998); Arens--Chandler-Wilde--DeSanto (2006); standard grating radiation theory; Luan--Sun--Zhuang (2019).
- **Differences / notation:** Only orientation and coefficient labels.
- **TE/TM:** The scalar expansion applies to either homogeneous scalar polarization.
- **Obstacles:** Wood anomalies and grazing modes, which the draft excludes.
- **Proved / unproved:** Fully standard off Wood anomalies; the excluded threshold case remains unhandled.
- **Current status:** **A**.
- **Risk:** **Low** if presented as setup, **very high** if claimed as new.

## C5. Exact and unique single-cell representation (Theorem 2)

- **Draft claim / location:** Every cell transmission field has a unique representation by QP exterior layers, free-space interior layers, and an independently specified homogeneous Rayleigh field; lines 699--752 and `appendixA.tex`.
- **Closest prior work:** Barnett--Greengard (2010), Theorem 4, Lemmas 9--10, Appendix A; Müller/Calderón and augmented Trefftz representations.
- **Exact overlap:** The QP/free-space potentials and the swapped-wavenumber complementary transmission field are the same uniqueness mechanism used by Barnett--Greengard. Their theorem proves exact BIE nullspace--Bloch-field equivalence away from stated resonances.
- **Important difference:** The draft states a representation for an arbitrary cell field after separating an independent bidirectional homogeneous Rayleigh component, rather than only the bulk Bloch-nullspace statement.
- **Notational / TE--TM test:** The augmentation is more than notation, but may be a direct range decomposition; it is not a TE/TM modification.
- **Analytical obstacles:** Precise trace spaces and port-neighborhood assumptions; compatibility of QP extension; Wood anomalies; possible auxiliary/transmission resonances; uniqueness of the Rayleigh split.
- **Proof audit:** `appendixA.tex` line 243 writes a mixed operator pair containing `D_QP^(nk)[v^-]` where application of the preceding (k)-wavenumber QP interior lemma requires `D_QP^(k)[v^-]`. Consequently the displayed cancellation is invalid as written. The phase/sign convention and the use of whole-plane swapped-problem uniqueness also need an independent check.
- **Proved / unproved:** Standard constituent representation and complementary-field proof exist. The draft's broader augmented theorem is not currently proved because of the kernel mismatch and unstated exceptional assumptions.
- **Current status:** **C** if repaired and its extra range statement is shown to exceed Barnett; otherwise **B**.
- **Risk:** **Critical**. Do not advertise “exact and unique” before correction and an auxiliary-resonance audit.

## C6. Müller interface operator plus homogeneous Rayleigh component

- **Draft claim / location:** Interface conditions become (A_{\rm QP}\eta+B_{\partial\Omega}\xi=0), a Müller-type second-kind block plus Rayleigh amplitudes; lines 754--813.
- **Closest prior work / overlap:** Barnett--Greengard (2010); Kress (1991); Yuan--Lu--Antoine (2008); Luan--Sun--Zhuang (2019).
- **Difference:** Explicitly includes port-homogeneous amplitudes for a defect cell and is intended to couple to lead traces.
- **Notational / TE--TM:** The block augmentation is a standard Trefftz coupling unless it yields a new Fredholm/spurious-free theorem; weighted TE jumps are standard.
- **Obstacles:** Prove Fredholm index/uniqueness of the full block and distinguish physical kernel from representation kernel; discretize hypersingular/cross-port terms robustly.
- **Proved / unproved / evidence:** Müller well-posedness and bulk QP nullspace equivalence are prior art; the complete line-defect block is conjectural and numerically unvalidated.
- **Current status:** **B/C**.
- **Risk:** **High**, but a strengthened spurious-free BIE--RtR/trace-relation theorem is a viable contribution.

## C7. Completeness of outgoing Bloch traces (Conjecture 1)

- **Draft claim / location:** The outgoing trace space is the closure of the span of decaying Bloch eigenmode traces with (|\lambda|<1); lines 815--844.
- **Closest prior work:** Hohage--Soussi (2013), Theorem 2.2; Zhang (2021); Zhang (2023).
- **Exact overlap/difference:** A Riesz basis and translation-operator Jordan form are proved. Generalized eigenfunctions/Jordan chains are essential; Zhang then builds a DtN and proves exponential modal truncation.
- **Notational / TE--TM:** The omission of generalized modes is mathematical, not notation or polarization.
- **Obstacles:** Defective multipliers, topology of Cauchy traces, unit-circle and threshold modes, coefficient assumptions, left/right orientation.
- **Proved / unproved:** Generalized modal completeness is already proved under periodic-waveguide hypotheses. Ordinary eigenvectors alone need not be complete, so the present conjecture is generally too strong/incorrect.
- **Evidence:** Hohage--Soussi Theorem 2.2 explicitly includes finitely many nontrivial Jordan blocks; Zhang 2023 proves exponential generalized-mode truncation.
- **Current status:** **A** for the corrected generalized statement; **reject/revise** current wording.
- **Risk:** **Critical**. This cannot remain a conjectured contribution without engaging those papers.

## C8. Homogeneous BIE--Rayleigh--Bloch system characterizes guided modes (Conjecture 2)

- **Draft claim / location:** The coupled block is singular iff ((k,\beta)) is a guided eigenpair; lines 850--878.
- **Closest prior work:** Fliss Theorem 4.5; Barnett--Greengard Theorem 4; BIE--DtN/RtR and generalized-modal DtN literature.
- **Overlap:** It composes known global reduction, QP Müller nullspace logic, and modal transparent data.
- **Difference:** The precise all-boundary, relation-valued assembly may be new as an operator package.
- **Notational / TE--TM:** Composition alone is not new. It becomes substantive only with a Fredholm, kernel-isomorphism, and convergence theorem.
- **Obstacles:** Theorem 2's proof gap; generalized-mode coordinates; representation nullspaces; BIE spurious quasi-resonances; truncation mismatch.
- **Proved / unproved:** No proof currently excludes algebraic nullvectors that reconstruct zero or non-outgoing physical fields. Hiptmair--Moiola--Spence shows why small BIE singular values can be spurious.
- **Current status:** **C** as a potentially useful composition; not yet a theorem.
- **Risk:** **Critical**.

## C9. MFS construction of the quasiperiodic Green function

- **Draft claim / location:** Proxy fundamental solutions, QP wall matching, and Rayleigh expansions construct (G_{\rm QP}); lines 880--1034.
- **Closest prior work:** Luan--Sun--Zhuang (2019); Barnett--Greengard (2010); Cho--Barnett (2015); Linton (1998).
- **Exact overlap:** MFS/proxies plus Rayleigh matching and near/far/neighbor periodization are established. Cho--Barnett explicitly uses immediate left/right neighbors and proxy sources.
- **Difference:** The draft computes the QP Green kernel itself and benchmarks a central/three-cell variant in the repository.
- **Notational / TE--TM:** This is an implementation adaptation, not polarization novelty.
- **Obstacles:** Source placement, exponential ill-conditioning, uniform error near Wood anomalies, proof that residual implies kernel error, parameter reuse.
- **Proved / unproved:** Luan gives residual-based error control off Wood anomalies; robust neighbor/proxy methods exist. No new draft stability/convergence theorem is present.
- **Current status:** **B**.
- **Risk:** **High** as primary innovation; useful enabling module only.

## C10. One-cell scattering matrix to Bloch generalized eigenproblem

- **Draft claim / location:** A two-port cell scattering matrix yields a generalized eigenvalue pencil for Bloch multipliers; (|\lambda|<1) gives decaying lead traces; lines 1036--1152.
- **Closest prior work:** Transfer/scattering-matrix band methods summarized by Yuan--Lu--Antoine (2008); wave finite elements; recursive Green/doubling; periodic-waveguide modal schemes.
- **Exact overlap:** Converting incoming/outgoing port amplitudes plus a cell phase condition into a Bloch pencil is standard. Avoiding explicit transfer-matrix inversion is also an established numerical motivation.
- **Difference:** The draft feeds the stable pencil eigentraces directly into its BIE trace relation.
- **Notational / TE--TM:** The pencil itself is a straightforward algebraic rearrangement; not TE/TM.
- **Obstacles:** Stable computation at evanescent extremes, defective/unit-circle multipliers, symplectic/flux structure, convergence from Rayleigh truncation to continuous modes.
- **Proved / unproved:** Standard at the discrete scattering-matrix level; no draft proof of a continuous stable-subspace approximation or conditioning advantage.
- **Current status:** **A/B**.
- **Risk:** **High** as novelty, **low** as an implementation component.

## C11. Stable Bloch eigentraces as a transparent condition without explicit DtN

- **Draft claim / location:** Use stable Bloch port Cauchy traces directly rather than forming a DtN matrix; definition lines 815--829 and construction lines 1117--1150.
- **Closest prior work:** Hohage--Soussi; Dohnal--Schweizer; Zhang 2021/2023; RtR work.
- **Overlap:** Modal transparent boundaries and generalized-modal DtN are established.
- **Difference:** A finite-dimensional *relation* basis can remain meaningful when a Dirichlet block is singular and may avoid explicit graph inversion.
- **Notational / TE--TM:** Potentially more than notation numerically, but only if stable subspace extraction/conditioning is proved and compared with RtR.
- **Obstacles:** QZ/ordered Schur separation near (|\lambda|=1), generalized chains, dimension changes, biorthogonal/flux normalization.
- **Proved / unproved:** No draft convergence or pole-conditioning theorem. No direct same-geometry Müller coupling was found in this search.
- **Evidence:** Zhang 2023 supplies the benchmark exponential modal-DtN result; RtR supplies the benchmark at forbidden frequencies.
- **Current status:** **C** for the precise BIE relation coupling; evidence is insufficient for “first.”
- **Risk:** **Medium-high**, but this is one of the best directions if narrowed and certified.

## C12. TM and TE treatment

- **Draft claim / location:** Selected draft is fully written only for TM; TE appears in repository notes but not as a complete theorem/algorithm/numerical section; model lines 76--193.
- **Closest prior work:** Brown et al. (2017) and multiband sequel; Yuan--Lu--Antoine (2008); Fliss-type scalar theory; standard weighted transmission BIE.
- **Overlap/difference:** TE divergence form and discontinuous coefficients are well established. A unified interface-only TM/TE implementation for the exact line-defect transparent problem could be useful.
- **Notational / direct extension:** Simply replacing normal-derivative continuity by weighted flux continuity is a **direct TE/TM modification** and not enough.
- **Obstacles:** Principal-coefficient discontinuity changes natural trace spaces, Green identities, layer weights, self-adjoint normalization, and possibly the preferred integral formulation.
- **Proved / unproved:** TE existence theory is prior art; the draft has no completed TE derivation or experiment.
- **Current status:** **B** alone; possible **C** as part of a unified certified solver.
- **Risk:** **Very high** as a standalone contribution.

## C13. Nonlinear eigenvalue detection by smallest-singular-value scanning

- **Draft claim / location:** Global grid and recursive dip refinement of (sigma_{\min}); numerical section lines 1304--1464.
- **Closest prior work:** Barnett--Greengard (2010) explicitly recommends (sigma_{\min}) band scanning; Klindworth et al. use Newton/Chebyshev; contour NEP literature including Binkowski et al. (2020), Brennan et al. (2023), and Lyu et al. (2025).
- **Overlap/difference:** Same heuristic, with no completeness guarantee.
- **Notational / TE--TM:** Neither.
- **Obstacles:** Missed multiple/tangent roots; nonnormal pseudospectral dips; poles; representation nullspaces; branch tracking.
- **Proved / unproved:** No proof that all guided modes are found or that dips are physical. Mature contour methods compute all isolated eigenvalues within a contour under analytic/meromorphic assumptions.
- **Current status:** **A**.
- **Risk:** **Very high** as novelty and **high** as the only production detector.

## C14. Existing numerical evidence and publishability

- **Draft claim / location:** MFS agrees with Ewald/Linton in three cases; a homogeneous-lead 1-D-periodic special case shows small singular values; lines 1153--1465. The “Line-Defect waveguide” subsection at line 1466 is empty.
- **Closest prior work:** Fliss/Klindworth numerical line-defect dispersion and group velocity; supercell comparisons; high-order BIE band calculations; Zhang modal error studies.
- **Exact overlap/difference:** MFS benchmark validates a component. It does not validate the full coupled eigenoperator.
- **Analytical/numerical obstacle:** Demonstrate field reconstruction, residuals, convergence in interface/Rayleigh/Bloch resolutions, independence from proxy placement, mode count, and comparison with an independent DtN/FEM or supercell reference.
- **Proved / unproved:** No general periodic-lead line-defect mode, TE mode, band-edge study, or independent eigenpair comparison is shown.
- **Current status:** **Not a contribution yet**; it is preliminary verification.
- **Risk:** **Critical for publication**.

## Consolidated verdict

| Draft component | Status | Recommended role |
|---|---:|---|
| Exact global-to-bounded guided-mode reduction | A | Background lemma citing Fliss 2013 |
| DtN graph identity / absorbing DtN | A--B | Background |
| Rayleigh expansions | A | Preliminaries |
| Theorem 2 augmented single-cell representation | C, proof not valid as written | Repair, sharply delimit, then decide whether to retain as theorem |
| Müller + lead-relation coupled operator | C | Best candidate for a focused formulation theorem |
| Ordinary Bloch-trace completeness | A in corrected generalized form | Replace conjecture with cited generalized-mode theorem and hypothesis map |
| MFS QP Green function / three-cell variant | B | Enabling numerical module |
| Scattering-to-Bloch pencil | A--B | Standard algorithmic component |
| Direct stable Cauchy-relation coupling | C | Candidate only with convergence/conditioning evidence |
| TE-only extension | B | Scope extension, not headline |
| Smallest singular-value scan | A | Diagnostic only; replace for final solver |
| Present numerical results | preliminary | Expand before any paper claim |

The strongest defensible current statement is not “the framework is new,” but:
**the particular high-order Müller BIE coupling to a generalized stable Bloch
Cauchy relation for exact line-defect eigenmodes was not found as a complete,
certified formulation in this search.** Even that must be phrased with the
qualification that absence from this search is not proof of priority.
