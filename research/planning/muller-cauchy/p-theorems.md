# Theorem roadmap

## 1. Audited target

The first publishable target is the quotient-safe theorem, not unconditional density uniqueness.

**Main Theorem K1 (continuous kernel--field equivalence).** Fix real `\beta` and real `k` satisfying A6--A16. Let `\mathcal A_{\rm rel}(k,\beta):\mathcal X\to\mathcal Y` be the relation-compatible Müller--Rayleigh center/lead operator of D5 below, and let

\[
  \mathcal N_{\rm rep}:=\ker\mathcal A_{\rm rel}\cap
  \ker\mathcal R_{\rm global}.
\]

Then global reconstruction induces a natural linear isomorphism

\[
  \overline{\mathcal R}_{\rm global}:
  \ker\mathcal A_{\rm rel}(k,\beta)/\mathcal N_{\rm rep}(k,\beta)
  \xrightarrow{\;\cong\;}\mathcal G(k,\beta),
\]

so geometric multiplicity is preserved. On the regular parameter subset where the representation and generalized trace synthesis are injective, `\mathcal N_{\rm rep}=\{0\}` and the quotient can be removed.

The novelty candidate is the compatible coupling and certificate. Fliss already supplies global/bounded equivalence; Barnett--Greengard supplies a nearby QP Müller equivalence; Hohage--Soussi and Zhang supply generalized modal structure. None of these alone proves K1 for this full relation-valued block.

## 2. Numbering and proof chain

### Part P: PDE, traces, and gluing

- **D1 Global space.** `\mathcal G(k,\beta)` is the kernel in ordinary global `H^1_\beta(\mathscr S)` of the weak piecewise Helmholtz form with TM flux continuity. `L^2` is part of `H^1`; exponential transverse decay is a consequence of the strict projected gap, not the definition. Pointwise decay is asserted only after local elliptic regularity/Sobolev embedding.
- **D2 Outgoing spaces and relations.** `\mathcal U^\pm_{\rm out}` are half-guide `H^1_{\rm loc,\beta}` weak solutions whose one-cell traces belong to the stable spectral subspace. `\mathcal C^\pm_{\rm out}=\operatorname{Tr}_{\Gamma^\pm}\mathcal U^\pm_{\rm out}`.
- **L1 (trace existence).** Dirichlet and weak Neumann traces lie in `H^{1/2}_\beta\times H^{-1/2}_\beta`.
- **L2 (closed outgoing relation).** Under a uniform half-guide estimate, `\mathcal C^\pm_{\rm out}` is a closed linear subspace.
- **L3 (restriction--gluing).** Restriction gives an isomorphism between global guided fields and center solutions whose port pairs lie in the two outgoing relations. Its proof is weak Green cancellation plus unique continuation. It is foundational prior art/adaptation, not the claimed innovation.

### Part F: translation and generalized Bloch structure

- **D3 Translation.** `T^\pm` maps the Cauchy trace on one cell interface to the next trace within `\mathcal U^\pm_{\rm out}`; it is conjugate to one-cell field translation through the trace isomorphism. A scattering pencil is only a discrete coordinate realization.
- **L4 (stable/unstable separation).** Strict projected gap plus A9 yields `\sigma(T^\pm)\cap\mathbb S^1=\varnothing` and separated Riesz contours. This must be proved for the chosen trace operator, not copied from a different propagation chart.
- **L5 (generalized Bloch expansion).** After verifying Hohage--Soussi's hypotheses, outgoing fields and traces have Riesz-basis expansions over stable Jordan chains, convergent respectively in the solution and trace norms.
- **P1 (stable trace characterization).** `\mathcal C^\pm_{\rm out}=\operatorname{ran}Q^\pm`, where `Q^\pm` synthesizes all stable generalized trace chains. The range is already closed by the Riesz-basis estimate; a bare algebraic span is inadequate.
- **P2 (DtN/RtR charts).** If the Dirichlet projection of the relation is bijective, it is `\operatorname{graph}\Lambda^\pm`. If a Robin projection is bijective, it yields an RtR chart. Poles are coordinate failures, not necessarily failures of the underlying relation.

### Part B: center Müller--Rayleigh representation

- **D4 Density and Rayleigh spaces.** `\eta=(\tau,\sigma)\in H^{1/2}(\partial\Omega_0)\times H^{-1/2}(\partial\Omega_0)`. Homogeneous Fourier/Rayleigh data use weighted spaces `h^{1/2}_\beta` for Dirichlet coefficients and `h^{-1/2}_\beta` for Neumann coefficients, tied by the exact modal multiplier away from Wood points.
- **L6 (layer mappings).** QP and free-space `S,D,D^*,T` have their standard Sobolev mappings; their singular parts coincide and their difference is smoothing at non-Wood, non-empty-pole parameters.
- **L7 (jump/Müller block).** With the fixed outward normal and TM conormal weight, jumps give the bounded block equation `A_M\eta+B_h\xi=0`; every half-identity sign is checked from the potential convention.
- **L8 (necessity of homogeneous augmentation).** Pure inclusion-supported QP layers miss empty-cell homogeneous solutions; adding `\xi` spans precisely that complementary finite/countable Rayleigh sector on the regular set.
- **L9 (corrected representation).** Every center transmission field has a Müller--Rayleigh representation. The exterior double layer is `D^{(k)}`, not `D^{(nk)}`. Existence of a field representation is separated from density uniqueness. Auxiliary transmission and empty-cell poles form an explicit exceptional set.
- **L10 (reconstruction-kernel characterization).** `\mathcal N_{\rm center}:=\ker\mathcal R_{\rm field}\cap\ker[A_M\;B_h]` equals the range of an auxiliary Calderón/complementary nullspace. Outside that exceptional set it is zero; otherwise one works modulo it or imposes a bounded side constraint.
- **T1 (center representation isomorphism).** The induced map `[\eta,\xi]\mapsto u` is an isomorphism from the algebraic solution space modulo `\mathcal N_{\rm center}` onto the center physical solution space.

### Part C: center--lead coupling

- **D5 Coupled operator.** With `x=(\eta,\xi,c^-,c^+)`, define

  \[
  \mathcal A_{\rm rel}x=
  \begin{bmatrix}
  A_M\eta+B_h\xi\\
  \Pi^-_\ell\eta+\Pi^-_h\xi-Q^-c^-\\
  \Pi^+_\ell\eta+\Pi^+_h\xi-Q^+c^+
  \end{bmatrix}.
  \]

  `\Pi^\pm_\ell` maps layer densities and `\Pi^\pm_h` homogeneous coefficients to outward-oriented port Cauchy pairs in `H^{1/2}_\beta\times H^{-1/2}_\beta`; `Q^\pm` is the stable generalized-trace synthesis. The codomain is the Müller transmission residual space times two Cauchy trace spaces. Analytic dependence is claimed only on a fixed regular component avoiding Green-function and spectral-projection poles.
- **L11 (completeness direction).** A global guided field restricts, is represented by L9/T1, and its lead restrictions have stable generalized coordinates by P1, giving a class in `\ker\mathcal A_{\rm rel}`.
- **L12 (soundness direction).** A kernel vector reconstructs center and lead fields; its two zero port residuals permit weak gluing; L4 supplies decay, hence a member of `\mathcal G`.
- **L13 (kernel injectivity modulo representation).** Zero global reconstruction forces stable coordinates to vanish by trace Riesz-basis uniqueness and forces the center unknown into `\mathcal N_{\rm center}` by L10. Thus the only algebraic ambiguity is `\mathcal N_{\rm rep}`. This is the highest-risk step.
- **K1 (main theorem).** L11--L13 give the quotient isomorphism and geometric multiplicity preservation.

### Part R: Fredholm and nonlinear spectrum

- **L14 (boundedness).** Every block of `\mathcal A_{\rm rel}` is bounded between the declared product spaces.
- **L15 (reference plus compact).** First choose a square quotient/multitrace realization. Candidate `\mathcal A_0` is the diagonal of the principal Müller Calderón block and two identity trace-synthesis charts after Riesz-coordinate normalization. Smooth QP/free-space differences, off-interface propagation, and finite homogeneous coupling form `\mathcal K`. This is a research task, not an established fact.
- **T2 (Fredholm index zero).** If L15 succeeds, `\mathcal A_{\rm rel}=\mathcal A_0+\mathcal K` is Fredholm of index zero on the quotient. If squareness fails, the acceptable result is closed range with finite-dimensional kernel, or a finite-Rayleigh index-zero theorem.
- **C1 (isolated roots and multiplicity).** On a regular complex neighborhood where the operator family is analytic and Fredholm index zero and is invertible at one point, analytic Fredholm theory makes characteristic values discrete with finite algebraic multiplicity. Geometric field multiplicity comes from K1; nonlinear algebraic multiplicity is defined by root functions/Riesz projection and is not automatically equal to it.

### Part D: future discretization (planning only)

- **D6 Discrete family.** `\mathcal A_{N,M,h}` uses `N` Nyström nodes, Rayleigh cutoff `M`, and stable-relation cell discretization parameter `h` (plus proxy parameters only if the robust Green representation needs them).
- **FL1 Müller Nyström consistency.** Prove collectively compact/operator-norm convergence after singular quadrature splitting.
- **FL2 Rayleigh truncation consistency.** Prove weighted trace convergence with constants depending on non-Wood separation.
- **FL3 Stable subspace convergence.** Prove `\operatorname{gap}(\mathcal C_{\rm out},\mathcal C_{{\rm out},M,h})\to0` via Riesz projections, including defective clusters.
- **FL4 Reconstruction convergence.** Convert algebraic convergence to local `H^1` field and physical residual convergence.
- **FT1 Discrete kernel convergence.** Near an isolated regular characteristic value, discrete root clusters and invariant spaces converge with total algebraic multiplicity.
- **FT2 No spectral pollution.** Any bounded sequence of certified discrete roots in a regular compact set has a subsequence converging to a K1 physical root; raw matrix singular values without the field certificate do not qualify.
- **FT3 Near-edge dependence.** Track constants in terms of edge distance, `\min|\log|\lambda||`, stable/unstable separation, and non-Wood distance; no uniform edge claim is made.

## 3. Recommended proof order and stop gates

1. Prove L1, L3, L6 and L7 using standard trace/layer theory.
2. Adapt L5/P1 and explicitly verify the trace isomorphism; stop if the chosen geometry violates Hohage--Soussi assumptions.
3. Prove only field-surjectivity in L9, then compute `\mathcal N_{\rm center}` in L10. Do not assume density uniqueness.
4. Prove L11 and L12; these should be achievable even with a quotient.
5. Attempt L13. If it yields only the quotient statement, freeze K1 in that form and move to Package B.
6. Attempt a square multitrace realization for L15/T2. If no natural `\mathcal A_0` appears, do not force the index theorem; retain finite-dimensional or semi-Fredholm results.
7. Only after K1 and a regular analytic family are settled, start the future discrete program.

## 4. Counts

The continuous chain contains **15 lemmas, 2 propositions, 3 theorems (T1, K1, T2), and 1 corollary**, plus 6 definitions. The future chain contains **4 planned lemmas and 3 planned theorems**. Total proof obligations: **28** when the three definitions that control operator construction (D3--D5) are included as audit obligations; otherwise 25 formal conclusions.

