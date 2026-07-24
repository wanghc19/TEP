# Proof obligations

Status vocabulary is literal: “covered” still requires a hypothesis-matching paragraph; “adaptation” requires a new proof in this geometry; “unproved” is not a promised result.

## PO-L1

- **编号/名称：** L1, Cauchy traces are well defined.
- **正式陈述/结论：** For every `u\in\mathcal U^\pm_{\rm out}` and center weak solution, `(\gamma_Du,\gamma_Nu)\in H^{1/2}_\beta(\Gamma^\pm)\times H^{-1/2}_\beta(\Gamma^\pm)`, continuously in the local graph norm.
- **函数空间：** piecewise `H^1_\beta`; `H^1_\Delta={v\in H^1:\Delta v\in L^2}` near the port; trace product `\mathcal H_\Gamma`.
- **假设：** A1--A5; port has a homogeneous Lipschitz neighborhood; weak PDE holds.
- **作用/依赖：** defines every port block; depends on D1--D2 only.
- **最近文献：** McLean (2000), Chapters 3--4; standard weak conormal trace. Fliss (2013), Section 4 uses the same `H^{\pm1/2}_\beta` pairing.
- **直接引用/适配/新增：** trace theorem is direct; quasiperiodic gauge and piecewise TM conormal orientation are adaptations; no novelty claimed.
- **方法/工具：** gauge `u=e^{i\beta x}v`, local Green identity, bounded lifting.
- **未解/反例/失败参数：** a port crossing an interface corner may lose the clean graph norm; an arbitrary `H^1` function has no Neumann trace.
- **最弱替代：** traces in `H^{1/2}\times H^{-1/2}` distributionally on a smaller smooth port.
- **完成状态：** 已由文献覆盖（需要写出适配）。

## PO-L2

- **编号/名称：** L2, closed outgoing Cauchy relation.
- **正式陈述/结论：** `\mathcal C^\pm_{\rm out}=\operatorname{Tr}\mathcal U^\pm_{\rm out}` is a closed linear subspace of `\mathcal H_{\Gamma^\pm}`.
- **函数空间：** half-guide solution graph space modulo zero trace; `\mathcal H_\Gamma=H^{1/2}_\beta\times H^{-1/2}_\beta`.
- **假设：** L1, A6--A12, a uniform estimate `\|u\|_{H^1(K)}\le C_K\|\operatorname{Tr}u\|_{\mathcal H}`.
- **作用/依赖：** makes relation coupling stable and allows projections/quotients; depends on L1 and half-guide uniqueness.
- **最近文献：** Fliss (2013), Proposition 4.3 and Lemma 4.4, pp. B448--B450; Hohage--Soussi (2013), Propositions 6.1--6.2, pp. 131--133.
- **直接引用/适配/新增：** closed graph/Riesz-range idea direct; transmission geometry and relation rather than DtN require adaptation.
- **方法/工具：** convergent trace sequence, uniform local estimates, weak compactness, uniqueness, or bounded-below Riesz synthesis.
- **未解/反例/失败参数：** threshold/unit-circle modes, trace nonuniqueness, half-guide embedded eigenstates.
- **最弱替代：** define `\mathcal C_{\rm out}` as the closure of the physical trace range and track possible extra limit traces.
- **完成状态：** 需要适配证明。

## PO-L3

- **编号/名称：** L3, restriction--gluing isomorphism.
- **正式陈述/结论：** restriction `R:\mathcal G\to\mathcal B` is bijective, with inverse given by weak gluing of the center field to the unique outgoing half-guide fields; dimensions agree.
- **函数空间：** global `H^1_\beta(\mathscr S)` and center `H^1_\beta(\mathcal C^0)` with port pairs in `\mathcal C^-_{\rm out}\times\mathcal C^+_{\rm out}`.
- **假设：** L1--L2, A1--A12, matched conormal orientations and unique continuation.
- **作用/依赖：** PDE-level bridge used by L12; depends on L1--L2.
- **最近文献：** Fliss (2013), Theorem 4.5, p. B450/local PDF p. 13, including multiplicity; current draft Theorem 1.
- **直接引用/适配/新增：** global/bounded equivalence is prior art; relation-valued weak gluing is adaptation only.
- **方法/工具：** sum Green identities; matching Neumann traces cancel the artificial boundary distribution; use uniqueness for inverse.
- **未解/反例/失败参数：** sign errors create a delta source; relation may be multivalued without half-guide uniqueness.
- **最弱替代：** a natural bijection after quotienting half-guide zero-Dirichlet solutions.
- **完成状态：** 已由文献覆盖/需要适配证明。

## PO-L4

- **编号/名称：** L4, strict-gap stable/unstable separation.
- **正式陈述/结论：** for the chosen trace translation `T^\pm`, `\sigma(T^\pm)\cap\mathbb S^1=\varnothing`, and disjoint contours enclose stable and unstable clusters with positive separation.
- **函数空间：** the Hohage--Soussi trace space or an explicitly equivalent Cauchy trace space.
- **假设：** A6--A9; no cell chart pole; translation is closed/bounded on the selected space.
- **作用/依赖：** defines outgoing spectral projection and exponential decay; depends on D3 and projected-gap identification.
- **最近文献：** Fliss (2013), Proposition 3.1, Proposition 3.3 and Theorem 3.5; Hohage--Soussi (2013), Sections 2--4; Joly--Li--Fliss (2006), Theorem 3.1 only in absorption.
- **直接引用/适配/新增：** no propagating multiplier in a projected gap is standard; equivalence for this precise trace operator must be shown.
- **方法/工具：** Bloch transform: `|\lambda|=1` implies real transverse quasi-momentum and hence membership in projected essential spectrum.
- **未解/反例/失败参数：** band edge, threshold, BIC/embedded mode, a chart pole masquerading as spectrum.
- **最弱替代：** assume an isolated stable Riesz contour directly, without claiming it follows from the gap.
- **完成状态：** 需要适配证明。

## PO-L5

- **编号/名称：** L5, generalized Bloch expansion.
- **正式陈述/结论：** stable outgoing solutions and their traces have unique Riesz-basis expansions over all generalized Floquet Jordan chains, converging in solution and trace norms.
- **函数空间：** `\mathcal U^\pm_{\rm out}` with local weighted/graph norm; coefficient `\ell^2`; trace `\mathcal H_\Gamma`.
- **假设：** Hohage--Soussi cell hypotheses, trace isomorphism, A1--A9.
- **作用/依赖：** replaces draft Conjecture 1; depends on L4.
- **最近文献：** Hohage--Soussi (2013), Theorem 2.2, pp. 117--118 and proof pp. 132--133; Proposition 3.5; Zhang (2021), Sections 3--5.
- **直接引用/适配/新增：** Jordan/Riesz theorem is direct under matched hypotheses; piecewise transmission and port trace require verification.
- **方法/工具：** analytic operator pencil, canonical Jordan chains, reference synthesis plus compact perturbation and injectivity.
- **未解/反例/失败参数：** ordinary eigenvectors fail at defective multipliers; trace map may have a kernel.
- **最弱替代：** a closed stable spectral subspace without a basis, coupled by a range condition.
- **完成状态：** 需要适配证明。

## PO-P1

- **编号/名称：** P1, outgoing relation equals stable generalized trace range.
- **正式陈述/结论：** `\mathcal C^\pm_{\rm out}=\operatorname{ran}Q^\pm`, and `Q^\pm:\ell^2\to\mathcal H_{\Gamma^\pm}` is bounded below on the chosen coordinate space.
- **函数空间：** stable Jordan coefficient `\ell^2` and Cauchy trace product.
- **假设：** L2, L4--L5, trace basis includes both Dirichlet and conormal components.
- **作用/依赖：** exact lead block used by L11--L13.
- **最近文献：** Hohage--Soussi (2013), Theorem 2.2 part 2 and Propositions 6.1--6.2, pp. 131--133; Zhang (2023), modal DtN construction.
- **直接引用/适配/新增：** Riesz trace range is near-direct; two-component Cauchy orientation and stable selection require adaptation.
- **方法/工具：** identify stable restriction of the Jordan synthesis; use Riesz inequalities for closedness and coordinate uniqueness.
- **未解/反例/失败参数：** overcomplete coordinates, missing associated vectors, unit-circle cluster.
- **最弱替代：** equality of closed ranges with coordinates factored by `\ker Q^\pm`.
- **完成状态：** 需要适配证明。

## PO-P2

- **编号/名称：** P2, DtN and RtR charts of the Cauchy relation.
- **正式陈述/结论：** if `\pi_D|_{\mathcal C}` is bijective, `\mathcal C=\operatorname{graph}\Lambda`; if an admissible Robin projection is bijective, the same relation is represented by an RtR map.
- **函数空间：** `H^{1/2}_\beta`, `H^{-1/2}_\beta`, and their Robin-compatible pivots.
- **假设：** L2; bounded inverse for the chosen projection.
- **作用/依赖：** clarifies relation/DtN/RtR; not used for coordinate-free K1.
- **最近文献：** Fliss (2013), Theorem 4.1 and Section 4; Fliss--Klindworth--Schmidt (2015), continuous RtR sections.
- **直接引用/适配/新增：** elementary closed-relation graph result plus cited constructions; no novelty.
- **方法/工具：** closed graph theorem and projection algebra.
- **未解/反例/失败参数：** Dirichlet half-guide pole or a bad Robin impedance.
- **最弱替代：** local chart on the complement of the projection kernel.
- **完成状态：** 已由文献覆盖。

## PO-L6

- **编号/名称：** L6, QP/free-space layer mapping properties.
- **正式陈述/结论：** `S:H^{-1/2}\to H^{1/2}`, `D:H^{1/2}\to H^{1/2}`, `D^*:H^{-1/2}\to H^{-1/2}`, `T:H^{1/2}\to H^{-1/2}` are bounded; QP minus free-space operators is smoothing on a smooth interface.
- **函数空间：** Sobolev spaces on `\partial\Omega_0` and quasiperiodic counterparts.
- **假设：** A1--A5, A8, A13; smooth interface and a defined non-Wood QP Green kernel.
- **作用/依赖：** foundation for Müller boundedness/compact structure; depends on D4.
- **最近文献：** McLean (2000), Chapters 6--8; Barnett--Greengard (2010), Section 2 and equation (13), journal pp. 6901--6903.
- **直接引用/适配/新增：** free-space maps direct; periodic smooth-remainder argument adapted.
- **方法/工具：** local kernel singularity decomposition and pseudodifferential/compact embedding estimates.
- **未解/反例/失败参数：** Wood anomaly or empty-lattice pole; nonsmooth corners alter spaces/compactness.
- **最弱替代：** boundedness only, with compactness assumed or proved blockwise.
- **完成状态：** 已由文献覆盖/需要适配证明。

## PO-L7

- **编号/名称：** L7, jump relations and Müller block.
- **正式陈述/结论：** the fixed layer ansatz satisfies transmission conditions iff `A_M\eta+B_h\xi=0`, with correct half-identity signs and TM conormal weights.
- **函数空间：** `H^{1/2}\times H^{-1/2}` to the corresponding transmission residual product.
- **假设：** L6; fixed normal points from inclusion to matrix; stated potential sign convention.
- **作用/依赖：** algebraic center equation; depends on L6.
- **最近文献：** Barnett--Greengard (2010), equations (17)--(20) and Appendix A; McLean, Chapters 6--7; Yuan--Lu--Antoine (2008), Sections 2--3.
- **直接引用/适配/新增：** jumps are direct; TM weights and homogeneous block are adapted.
- **方法/工具：** take both traces, form Müller combinations that cancel hypersingular principal parts, audit normals term by term.
- **未解/反例/失败参数：** convention mismatch changes signs; zero contrast degenerates a chosen block scaling.
- **最弱替代：** a multitrace Calderón equation retaining all traces instead of a reduced Müller block.
- **完成状态：** 需要适配证明。

## PO-L8

- **编号/名称：** L8, necessity and space of homogeneous Rayleigh augmentation.
- **正式陈述/结论：** the pure inclusion-layer range omits nonzero empty-cell homogeneous solutions; adding `\xi` from weighted Rayleigh space supplies the missing sector and yields correct port traces.
- **函数空间：** `h^{1/2}_\beta` Dirichlet sequences linked to `h^{-1/2}_\beta` Neumann sequences by modal factors.
- **假设：** A8--A9, no vanishing vertical modal factor on the selected regular set.
- **作用/依赖：** prevents false incompleteness of center representation; depends on L6.
- **最近文献：** Barnett--Greengard (2010), Definition 3 and Remarks 5--8 diagnose empty-cell/QP failures; standard Rayleigh Fourier trace characterization.
- **直接引用/适配/新增：** diagnosis is direct; exact augmentation and weighted-space proof are new/adapted.
- **方法/工具：** set densities to zero, exhibit homogeneous solutions, then identify Fourier trace isomorphism.
- **未解/反例/失败参数：** Wood mode gives zero/branch modal factor; double counting can create redundancy with layer ranges.
- **最弱替代：** finite nonresonant Rayleigh augmentation with an explicit quotient by overlap.
- **完成状态：** 尚未证明。

## PO-L9

- **编号/名称：** L9, corrected center representation theorem.
- **正式陈述/结论：** every center transmission solution is reconstructed by a homogeneous Rayleigh component plus QP exterior-wavenumber `k` layers and free-space interior-wavenumber `nk` layers; field representation is surjective.
- **函数空间：** center piecewise `H^1_\beta`; density/Rayleigh space D4.
- **假设：** L6--L8, A13--A16; auxiliary complementary problem unique; no empty-cell/Green pole.
- **作用/依赖：** completeness of center algebra; depends on L6--L8.
- **最近文献：** Barnett--Greengard (2010), Theorem 4, Appendix A, Lemmas 9--10 and (A.4)--(A.12), journal pp. 6912--6914; Colton--Kress Theorems 3.40--3.41 as cited there.
- **直接引用/适配/新增：** complementary proof architecture direct; center Rayleigh augmentation and exact spaces require adaptation. Correct exterior double layer is `D^{(k)}`, not the draft's mixed `D^{(nk)}`.
- **方法/工具：** representation identities, swapped-wavenumber complementary field, uniqueness, then an auxiliary inhomogeneous problem for surjectivity.
- **未解/反例/失败参数：** auxiliary transmission eigenvalue, empty resonance, Wood anomaly; density uniqueness is deliberately not concluded.
- **最弱替代：** surjectivity modulo a finite-dimensional missed homogeneous sector.
- **完成状态：** 需要适配证明。

## PO-L10

- **编号/名称：** L10, density-to-field kernel characterization.
- **正式陈述/结论：** `\ker\mathcal R_{\rm field}` within the center algebraic solution space is exactly an explicitly defined auxiliary Calderón/complementary nullspace `\mathcal N_{\rm center}`; it vanishes on a smaller regular set or is removed by quotient/side constraint.
- **函数空间：** D4 density/Rayleigh product and piecewise center `H^1`.
- **假设：** L6--L9, A14--A16.
- **作用/依赖：** core spurious-root separator and premise of T1/L13.
- **最近文献：** Barnett--Greengard (2010), Appendix A; Hiptmair--Moiola--Spence (2022), Lemmas 2.2--2.6 and Theorems 1.10--1.12.
- **直接引用/适配/新增：** Calderón range identities direct; precise periodic augmented nullspace is potentially new.
- **方法/工具：** assume zero field, apply jumps/extinction, construct complementary fields, identify projector ranges; add normalization if the nullspace is finite-dimensional.
- **未解/反例/失败参数：** nonzero densities can produce zero field at auxiliary eigenvalues; quasi-resonance gives near-kernel without exact kernel.
- **最弱替代：** define `\mathcal N_{\rm center}` abstractly as the kernel and prove only finite dimensionality plus a computable physical residual.
- **完成状态：** 尚未证明（最高风险之一）。

## PO-T1

- **编号/名称：** T1, center representation quotient isomorphism.
- **正式陈述/结论：** `\mathcal X_{\rm center}/\mathcal N_{\rm center}\cong\mathcal S_{\rm center}` by the induced field reconstruction.
- **函数空间：** closed algebraic solution subspace of D4 modulo L10 kernel; center physical `H^1` solution space.
- **假设：** L9 surjectivity and L10 exact kernel.
- **作用/依赖：** supplies center coordinates for L11 and ambiguity control for L13.
- **最近文献：** first-isomorphism theorem; Barnett--Greengard (2010), Theorem 4 is the closest unquotiented special case.
- **直接引用/适配/新增：** abstract quotient result direct; bounded inverse/closed range in this augmented system requires proof.
- **方法/工具：** first-isomorphism theorem, closed kernel, open mapping theorem.
- **未解/反例/失败参数：** range not closed or L9 not surjective.
- **最弱替代：** algebraic vector-space isomorphism without a norm-equivalence claim.
- **完成状态：** 需要适配证明。

## PO-L11

- **编号/名称：** L11, guided mode induces a kernel class.
- **正式陈述/结论：** every `u\in\mathcal G` determines at least one `x_u\in\ker\mathcal A_{\rm rel}` and a unique class modulo `\mathcal N_{\rm rep}`.
- **函数空间：** `\mathcal G`, coupled product `\mathcal X`, quotient kernel.
- **假设：** L3, P1, T1 and correct port orientations.
- **作用/依赖：** surjectivity/completeness direction of K1.
- **最近文献：** Fliss (2013), Theorem 4.5; Barnett--Greengard (2010), Theorem 4; Hohage--Soussi (2013), Theorem 2.2, combined but not previously as this block.
- **直接引用/适配/新增：** each component is cited; their compatible assembly is new/adapted.
- **方法/工具：** restrict, choose T1 representation, expand both lead traces through P1, substitute into three block rows.
- **未解/反例/失败参数：** missing modal associated vector or an unaccounted representation kernel changes uniqueness of class.
- **最弱替代：** existence of a kernel vector, without uniqueness of its class.
- **完成状态：** 需要适配证明。

## PO-L12

- **编号/名称：** L12, kernel vector reconstructs a guided field.
- **正式陈述/结论：** every coupled kernel vector reconstructs center and outgoing half-guide fields that glue to `u_x\in\mathcal G`.
- **函数空间：** coupled `\mathcal X`; local/global `H^1_\beta`.
- **假设：** L3, L7, P1; port residual contains both Cauchy components; L4 for decay.
- **作用/依赖：** soundness direction of K1.
- **最近文献：** Fliss (2013), Theorem 4.5; weak gluing standard; relation reconstruction from Hohage--Soussi Theorem 2.2.
- **直接引用/适配/新增：** gluing is standard; full BIE/relation reconstruction is adaptation.
- **方法/工具：** reconstruct fields, use zero block rows for PDE/transmission/trace matching, apply L3, then stable decay.
- **未解/反例/失败参数：** matching only Dirichlet data leaves an artificial source; a relation vector without a physical half-guide preimage invalidates soundness.
- **最弱替代：** local weak solution with `L^2` decay rather than pointwise exponential decay.
- **完成状态：** 需要适配证明。

## PO-L13

- **编号/名称：** L13, zero reconstructed field implies trivial algebraic class.
- **正式陈述/结论：** `u_x=0` implies `x\in\mathcal N_{\rm rep}`; on the injective regular set it implies `x=0`.
- **函数空间：** coupled kernel and representation quotient.
- **假设：** L10, T1, P1 bounded-below synthesis, unique continuation.
- **作用/依赖：** injectivity of K1 and exact no-spurious statement.
- **最近文献：** Barnett--Greengard (2010), Appendix A; Hohage--Soussi (2013), Propositions 6.1--6.2; Hiptmair--Moiola--Spence (2022), Section 2 Calderón projectors.
- **直接引用/适配/新增：** component injectivities are adjacent prior art; coupled periodic result is potentially new.
- **方法/工具：** zero lead field→zero Riesz coordinates; zero center field→L10 auxiliary nullspace; quotient or bounded projector side constraint.
- **未解/反例/失败参数：** auxiliary pole, overcomplete mode coordinates, density-field null vector.
- **最弱替代：** identify only `\ker\mathcal R_{\rm global}` abstractly and state K1 on its quotient.
- **完成状态：** 尚未证明；最关键瓶颈。

## PO-K1

- **编号/名称：** K1, continuous kernel--guided-space isomorphism.
- **正式陈述/结论：** `\ker\mathcal A_{\rm rel}/\mathcal N_{\rm rep}\cong\mathcal G`, naturally and with geometric dimension preserved; unquotiented only if `\mathcal N_{\rm rep}=0`.
- **函数空间：** coupled Hilbert quotient and global `H^1_\beta` eigenspace.
- **假设：** L11--L13 and A1--A16.
- **作用/依赖：** recommended main theorem and physical-root certificate.
- **最近文献：** Fliss (2013), Theorem 4.5; Barnett--Greengard (2010), Theorem 4; Hohage--Soussi (2013), Theorem 2.2; Zhang (2021/2023).
- **直接引用/适配/新增：** all ingredients overlap; the quotient-safe Müller--generalized-Bloch--relation coupling is the plausible new synthesis.
- **方法/工具：** induced reconstruction map; L11 surjectivity, L12 well-definedness, L13 injectivity.
- **未解/反例/失败参数：** all listed exceptional sets; theorem may collapse to a direct combination if multitrace literature already states the same coupling.
- **最弱替代：** a surjection from quotient kernel to guided fields plus a computable residual certificate at fixed truncation.
- **完成状态：** 尚未证明。

## PO-L14

- **编号/名称：** L14, boundedness of the coupled operator.
- **正式陈述/结论：** `\mathcal A_{\rm rel}:\mathcal X\to\mathcal Y` is bounded on the declared Sobolev/Riesz-coordinate product spaces.
- **函数空间：** D4 density/Rayleigh spaces, stable `\ell^2` coordinates, Müller and two trace residual spaces.
- **假设：** L6--L8, P1, ports separated from interfaces where smoothing is used.
- **作用/依赖：** prerequisite for Fredholm theory.
- **最近文献：** McLean layer mappings; Hohage--Soussi Riesz synthesis bounds; Barnett--Greengard second-kind block.
- **直接引用/适配/新增：** component bounds direct; full product bookkeeping adapted.
- **方法/工具：** estimate each block, including modal derivative weights and trace restriction.
- **未解/反例/失败参数：** wrong Rayleigh weights make `\Pi_h` unbounded; Wood factors diverge.
- **最弱替代：** boundedness on smoother spaces with a loss of derivatives.
- **完成状态：** 需要适配证明。

## PO-L15

- **编号/名称：** L15, invertible reference operator plus compact perturbation.
- **正式陈述/结论：** after a natural square quotient/multitrace realization, `\mathcal A_{\rm rel}=\mathcal A_0+\mathcal K`, with `\mathcal A_0` boundedly invertible and `\mathcal K` compact.
- **函数空间：** identical domain/codomain Hilbert product after Riesz normalization and representation quotient.
- **假设：** L14, smooth boundaries, separated ports, a square choice of constraints.
- **作用/依赖：** only planned route to T2.
- **最近文献：** Barnett--Greengard (2010), Theorem 4 second-kind structure; Hohage--Soussi (2013), Lemma 5.1 reference synthesis Fredholm index zero; Kato Chapter IV.
- **直接引用/适配/新增：** local principal blocks are cited; compactness and squareness of the coupled relation block are genuinely unresolved.
- **方法/工具：** Calderón principal symbol, diagonal Riesz synthesis identity, smoothing QP differences, compact off-interface trace maps.
- **未解/反例/失败参数：** relation row may be rectangular; port blocks may not be compact; overlap quotient may change index.
- **最弱替代：** closed range/finite kernel, semi-Fredholm, or finite-Rayleigh square theorem.
- **完成状态：** 陈述可能错误。

## PO-T2

- **编号/名称：** T2, Fredholm index zero.
- **正式陈述/结论：** the square quotient realization of `\mathcal A_{\rm rel}` is Fredholm with index zero.
- **函数空间：** those fixed in L15.
- **假设：** L15.
- **作用/依赖：** finite-dimensional kernels, analytic Fredholm route, but not by itself no-spuriousness.
- **最近文献：** Kato Chapter IV; Barnett--Greengard (2010), Theorem 4; Hohage--Soussi (2013), Lemma 5.1.
- **直接引用/适配/新增：** stability of index under compact perturbation is direct; construction of L15 is new.
- **方法/工具：** `\operatorname{ind}(A_0+K)=\operatorname{ind}A_0=0`.
- **未解/反例/失败参数：** no square reference operator; noncompact port coupling; representation pole.
- **最弱替代：** semi-Fredholm/finite kernel or index zero only after finite modal truncation.
- **完成状态：** 尚未证明；最可能失败的 theorem。

## PO-C1

- **编号/名称：** C1, isolated characteristic values and multiplicity.
- **正式陈述/结论：** on a complex regular component, an analytic Fredholm index-zero family invertible somewhere has discrete characteristic values of finite algebraic multiplicity; K1 identifies their geometric kernels with guided fields.
- **函数空间：** fixed complexified product spaces; analytic operator family.
- **假设：** T2, K1, analytic branch choices and one invertible point.
- **作用/依赖：** bridge to contour solvers and spectral approximation.
- **最近文献：** Kato Chapter VII; analytic Fredholm theorem; standard Gohberg--Sigal/Keldysh framework.
- **直接引用/适配/新增：** abstract theorem direct; analyticity through QP kernels and Riesz projections must be verified.
- **方法/工具：** analytic Fredholm theorem, root functions/Riesz projection; distinguish geometric, algebraic, nonlinear multiplicity.
- **未解/反例/失败参数：** Green poles, square-root/Wood branches, collision with band edge; representation pole is not a physical root.
- **最弱替代：** local meromorphic finite-dimensional Schur complement away from poles.
- **完成状态：** 需要适配证明。

## PO-FL1

- **编号/名称：** FL1, future Müller Nyström consistency.
- **正式陈述/结论：** lifted Nyström boundary blocks converge in operator norm or collectively compact sense on the chosen Sobolev scale.
- **函数空间：** continuous density product and trigonometric/grid approximation spaces.
- **假设：** smooth analytic boundary, corrected singular quadrature, fixed regular `k,\beta`.
- **作用/依赖：** boundary part of FL4/FT1; depends on L6--L7.
- **最近文献：** Kress high-order periodic Nyström theory; Barnett--Greengard (2010), Sections 3--4 numerical formulation.
- **直接引用/适配/新增：** quadrature theory may be cited; mixed QP/free-space block and nonlinear uniformity require adaptation.
- **方法/工具：** singularity subtraction, product integration, collectively compact convergence.
- **未解/反例/失败参数：** corners, near-touching interfaces, QP pole.
- **最弱替代：** pointwise consistency plus stability on a fixed frequency interval.
- **完成状态：** 尚未证明（未来）。

## PO-FL2

- **编号/名称：** FL2, future Rayleigh truncation consistency.
- **正式陈述/结论：** truncated homogeneous reconstruction and port traces converge in the correct weighted norms, uniformly on compact non-Wood parameter sets.
- **函数空间：** weighted `h^{1/2}_\beta/h^{-1/2}_\beta` and trace product.
- **假设：** L8, smooth/analytic port data, positive non-Wood distance.
- **作用/依赖：** modal part of FL4 and edge constants.
- **最近文献：** Fourier Sobolev characterization; Zhang (2023) exponential modal DtN truncation in a related setting.
- **直接引用/适配/新增：** weighted tail estimates standard; coupling-specific estimate adapted.
- **方法/工具：** Parseval, modal-factor asymptotics, analytic regularity for exponential rates.
- **未解/反例/失败参数：** grazing/Wood modes and nonsmooth data reduce rates or destroy uniformity.
- **最弱替代：** algebraic convergence for fixed regular parameters.
- **完成状态：** 尚未证明（未来）。

## PO-FL3

- **编号/名称：** FL3, future stable invariant-subspace convergence.
- **正式陈述/结论：** the discrete stable Cauchy subspace converges in gap to the continuous one, including whole defective clusters.
- **函数空间：** continuous/discrete trace spaces linked by lift/restriction operators.
- **假设：** L4--P1, norm-resolvent or collectively compact convergence of the cell pencil, uniform Riesz contour separation.
- **作用/依赖：** rigorous lead discretization; feeds FL4.
- **最近文献：** Kato Riesz projections; Hohage--Soussi (2013) Jordan structure; Zhang (2023) modal DtN error.
- **直接引用/适配/新增：** spectral projection perturbation direct; discretized scattering pencil convergence requires new proof.
- **方法/工具：** contour integral of resolvents, subspace gap/principal angles, cluster not vector-by-vector matching.
- **未解/反例/失败参数：** defective cluster splitting, spectral pollution, vanishing stable/unstable separation.
- **最弱替代：** convergence for semisimple separated multipliers only.
- **完成状态：** 尚未证明（未来）。

## PO-FL4

- **编号/名称：** FL4, future discrete reconstruction convergence.
- **正式陈述/结论：** convergent discrete algebraic classes reconstruct fields converging locally in `H^1` and in all physical residual norms.
- **函数空间：** lifted discrete quotient spaces and local piecewise `H^1`.
- **假设：** FL1--FL3 and uniform reconstruction stability modulo `\mathcal N_{\rm rep}`.
- **作用/依赖：** prevents purely algebraic false convergence; prerequisite FT1--FT2.
- **最近文献：** Coatléven (2012), Theorem 5.6 error architecture; standard potential estimates.
- **直接引用/适配/新增：** error decomposition pattern direct; quotient/residual coupling new.
- **方法/工具：** triangle inequality splitting boundary, Rayleigh, and stable-subspace errors; use local potential bounds.
- **未解/反例/失败参数：** near-null representation vectors give large algebraic coefficients with small fields.
- **最弱替代：** convergence of normalized physical fields for certified sequences.
- **完成状态：** 尚未证明（未来）。

## PO-FT1

- **编号/名称：** FT1, future discrete kernel/root convergence.
- **正式陈述/结论：** near an isolated regular characteristic value, discrete root clusters and reconstructed invariant spaces converge with total algebraic multiplicity.
- **函数空间：** analytic continuous/discrete operator families and their Riesz root subspaces.
- **假设：** C1, FL1--FL4, regular approximation uniform on a contour.
- **作用/依赖：** core future spectral-correctness result.
- **最近文献：** Babuška--Osborn (1991), pp. 641--787; Chatelin (1983); analytic operator-function approximation theory.
- **直接引用/适配/新增：** abstract spectral approximation direct; nonlinear quotient family and three-parameter limit adapted.
- **方法/工具：** operator-valued Rouché theorem/contour projections and reconstruction stability.
- **未解/反例/失败参数：** pole inside contour, nonuniform modal projection, exceptional representation parameter.
- **最弱替代：** convergence of a simple isolated root under a coupled refinement path.
- **完成状态：** 尚未证明（未来）。

## PO-FT2

- **编号/名称：** FT2, future no certified spectral pollution.
- **正式陈述/结论：** every bounded sequence of roots passing the matrix, field, interface, quasiperiodic, port-relation, and decay certificates has accumulation only at a K1 physical guided root.
- **函数空间：** compact regular parameter set and normalized reconstructed fields.
- **假设：** K1, FT1/FL4 compactness, certificate tolerances tend to zero.
- **作用/依赖：** operational meaning of “spurious-free.”
- **最近文献：** Hiptmair--Moiola--Spence (2022), Theorems 1.10--1.12 show why matrix singularity alone is insufficient; spectral approximation references above.
- **直接引用/适配/新增：** warning direct; positive multiphysics certificate theorem potentially new.
- **方法/工具：** contradiction, compactness of normalized fields, pass weak PDE/trace limits, apply K1.
- **未解/反例/失败参数：** fields converge weakly to zero; normalization concentrated in unresolved near-interface layers.
- **最弱替代：** an a posteriori filter with demonstrated reliability, not a theorem of absence.
- **完成状态：** 尚未证明（未来）。

## PO-FT3

- **编号/名称：** FT3, future near-band-edge parameter dependence.
- **正式陈述/结论：** constants are explicitly bounded in terms of projected-edge distance, `\min|\log|\lambda||`, stable/unstable separation, and non-Wood distance; blow-up is allowed as any tends to zero.
- **函数空间：** parameter-dependent trace, invariant-subspace, and reconstruction norms on regular compact subsets.
- **假设：** L4, FL2--FL3 and quantitative resolvent bounds.
- **作用/依赖：** states the honest validity envelope of all convergence results.
- **最近文献：** Fliss (2013), Theorem 3.5 and Section 6; Zhang (2023) modal truncation estimates; Kato projection perturbation.
- **直接引用/适配/新增：** qualitative deterioration is known; a unified quantitative budget for this solver is new/adapted.
- **方法/工具：** resolvent contour bound, Fourier tail bound, exponential-decay estimate, condition-number factorization.
- **未解/反例/失败参数：** exact edge/threshold, Jordan collision, Wood anomaly.
- **最弱替代：** empirical/upper-semicontinuous constants on fixed compact subintervals.
- **完成状态：** 尚未证明（未来）。

