# Reference guide

Page references below use journal pagination where it is available; local-PDF page numbers are added when verified. An unverified theorem number is deliberately not supplied.

## Fliss (2013)

- **Document:** S. Fliss, *A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides*, SIAM J. Sci. Comput. 35, B438--B461.
- **Used for:** projected gaps, exponential localization, half-guide DtN, exact global/bounded equivalence, multiplicity.
- **Must read:** Sections 3--4; Theorem 3.5 (journal p. B446; local PDF p. 9), Proposition 4.3 and Lemma 4.4 (pp. B448--B449; local pp. 11--12), Theorem 4.5 (p. B450; local p. 13), Proposition 4.8 and Theorem 4.9 (pp. B451--B452; local p. 14), Theorems 4.12--4.13.
- **Directly citable:** gap modes decay exponentially; the bounded DtN eigenproblem is exactly equivalent to the global one and preserves multiplicity, away from the half-guide Dirichlet exceptional set.
- **Not directly reusable:** relation-valued ports at a DtN pole, interface-only Müller coupling, and representation-nullspace certification.
- **Notation map:** her axial `\beta` is this project's fixed `\beta`; her transverse exterior operators produce regular charts of `\mathcal C^\pm_{\rm out}`.

## Joly--Li--Fliss (2006)

- **Used for:** absorbed half-guide propagation, compact propagation operator, Riccati selection, and the warning that the lossless limit was not completed there.
- **Must read:** Sections 3--6; Theorem 3.1 (propagation operator); Theorem 4.1 and equations (4.5)--(4.6), journal pp. 953--954; Remark 5.1; Section 8.
- **Directly citable:** with absorption, the selected compact propagation operator has spectral radius below one and solves the stationary Riccati equation uniquely under the stated selection.
- **Adaptation needed:** replace absorption-selected decay by strict-gap stable spectral projection in a lossless problem.
- **Notation map:** `R^+` is a one-cell realization of the right-lead translation/propagation operator `T^+`.

## Coatléven (2012)

- **Used for:** line defects with possibly different leads, Floquet--Bloch transform, propagation/DtN and a complete approximation-error architecture.
- **Must read:** Theorem 2.1; Lemma 3.1 and Theorem 3.1; Theorems 4.1--4.4; Theorems 5.4 and 5.6; Remark 5.5; journal pp. 1675--1704.
- **Directly citable:** absorbed global well-posedness, FBT cell reduction, compact propagation/Riccati construction, and error decomposition.
- **Not directly reusable:** the real lossless guided eigenproblem and Müller representation.
- **Notation map:** left/right propagation operators correspond to stable charts of `\mathcal C^-_{\rm out}` and `\mathcal C^+_{\rm out}`.

## Fliss--Klindworth--Schmidt (2015)

- **Used for:** Robin-to-Robin transparent conditions and avoidance of the countable Dirichlet forbidden set.
- **Must read:** the continuous RtR construction, exact bounded reduction, and numerical comparison sections in BIT 55, 81--115. Exact theorem numbering was not verified from a local full text and is not invented here.
- **Directly citable:** RtR provides a regular coordinate chart where a DtN graph may fail.
- **Not directly reusable:** a Cauchy relation does not automatically offer an advantage over RtR; its advantage must be the coordinate-free coupling and nullspace analysis.
- **Notation map:** Robin projection `(\gamma_N+i\eta\gamma_D)u` is a chart of the same closed Cauchy subspace.

## Barnett--Greengard (2010)

- **Used for:** QP/free-space Müller representation, empty-cell resonance exclusion, BIE nullspace/Bloch-field equivalence, complementary swapped-wavenumber proof.
- **Must read:** Definition 3; Theorem 4 and Remarks 5--8 (journal pp. 6904--6906; local PDF pp. 6--8); Appendix A, Lemmas 9--10 and equations (A.4)--(A.12) (journal pp. 6912--6914; local pp. 22--24).
- **Directly citable:** away from empty-cell resonances, their QP Müller operator is Fredholm second kind and singular exactly at a Bloch eigenvalue.
- **Adaptation needed:** central cell with independent homogeneous Rayleigh components and port relation constraints; precise density-kernel characterization.
- **New opportunity:** combine the representation proof with a quotient/Calderón certificate rather than presuming density uniqueness.
- **Notation map:** their density vector `\eta=(\tau,\sigma)` maps to ours; their QP exterior plus free-space interior representation is the local `\mathcal R_{\rm field}` block.

## Hohage--Soussi (2013)

- **Used for:** generalized Floquet modes, Jordan chains, Riesz basis of solution and trace spaces, injective trace synthesis.
- **Must read:** Definition 2.1 and Theorem 2.2 (journal pp. 117--118; local PDF p. 5); Proposition 3.5 (journal around pp. 121--122; local pp. 9--10); Lemma 5.1 (journal p. 126; local p. 17); Propositions 6.1--6.2 and proof of Theorem 2.2 (journal pp. 131--133; local pp. 22--24); Appendix B uniqueness conditions.
- **Directly citable:** the full solution space has a Riesz basis of generalized Floquet modes; translation has Jordan form, with only finitely many nontrivial finite blocks; under trace well-posedness, traces form a Riesz basis with the same Jordan structure.
- **Adaptation needed:** verify their boundary/trace isomorphism hypotheses for the piecewise transmission cell and the artificial ports chosen here.
- **Notation map:** their translation `T` and trace synthesis `F=\tau T` become `T^\pm` and `Q^\pm`.

## Zhang (2021; 2023)

- **Used for:** spectral decomposition of translation operators, generalized-eigenfunction representation of LAP solutions, modal DtN truncation and exponential errors.
- **Must read:** Zhang (2021), Sections 3--5, SIAM J. Appl. Math. 81, 233--257; Zhang (2023), construction and convergence/error theorems, SIAM J. Numer. Anal. 61, 1195--1217. Exact theorem numbers are deferred until full-text verification.
- **Directly citable:** generalized modes, rather than ordinary eigenvectors alone, are the correct spectral coordinates; under separation assumptions, truncated modal DtN approximations converge exponentially.
- **Not directly reusable:** forced LAP scattering/FEM is not the present nonlinear guided-mode BIE.
- **Notation map:** Zhang's outgoing spectral sum supplies a constructive model for `Q^\pm c^\pm` and future gap estimates.

## Hiptmair--Moiola--Spence (2022)

- **Used for:** distinction between physical well-posedness, BIE inverse norms, spurious quasi-resonances, and augmented formulations.
- **Must read:** Definition 1.1; Lemmas 1.2 and 1.7; Theorems 1.10--1.12 and 1.15; Lemmas 2.2--2.6; Sections 3--5, SIAM J. Appl. Math. 82, 1446--1469.
- **Directly citable:** second-kind structure does not preclude nonphysical large inverse norms; Calderón ranges and projector identities isolate representation effects.
- **Adaptation needed:** their bounded-obstacle scattering setting has no periodic leads or guided eigenvalue.
- **Notation map:** their Calderón projector ranges guide the definition of `\mathcal N_{\rm rep}` and the side constraint `P_{\rm phys}x=x`.

## Yuan--Lu--Antoine (2008)

- **Used for:** interface BIE construction of unit-cell DtN maps, both scalar polarizations, and boundary-only reduction.
- **Must read:** Introduction and Sections 2--4, J. Comput. Phys. 227, 4617--4629.
- **Directly citable:** BIE-to-cell-DtN and reduced boundary eigenproblems are established computational ideas.
- **Not directly reusable:** bulk band structure is not a transverse line-defect guided-mode problem.
- **Notation map:** their unit-cell DtN is a finite representation of a chart of the port Cauchy relation.

## Standard books and approximation references

### McLean (2000)

- **Document:** W. McLean, *Strongly Elliptic Systems and Boundary Integral Equations*, Cambridge University Press.
- **Used for:** Sobolev traces, weak conormal derivatives, layer mappings, jumps, Fredholm BIE framework.
- **Read:** Chapters 3--4 for Sobolev/trace theory and Chapters 6--8 for potentials and boundary integral operators.
- **Limitation:** free-space elliptic theory must be periodized; the singular part transfers, but the QP smooth remainder must be checked separately.

### Colton--Kress (1983)

- **Document:** D. Colton and R. Kress, *Integral Equation Methods in Scattering Theory*, Wiley.
- **Used for:** representation/extinction, Cauchy uniqueness, complementary transmission problems. Barnett--Greengard explicitly invoke their Theorems 3.40--3.41 in Appendix A.
- **Read:** Chapter 3, especially those two theorems in the edition cited by Barnett--Greengard.
- **Limitation:** nonperiodic exterior radiation is not a periodic half-guide radiation relation.

### Kato (1995)

- **Document:** T. Kato, *Perturbation Theory for Linear Operators*, Springer Classics.
- **Used for:** closed operators, Fredholm index, Riesz projections, analytic families, algebraic spectral multiplicity.
- **Read:** Chapter IV (Fredholm theory) and Chapter VII (analytic perturbation).
- **Limitation:** supplies abstract tools, not compactness or analyticity of the concrete blocks.

### Babuška--Osborn (1991) and Chatelin (1983)

- **Used for:** spectral approximation, eigenspace gaps, pollution questions and collectively compact/operator convergence.
- **Read:** Babuška--Osborn, *Eigenvalue Problems*, Handbook of Numerical Analysis II, pp. 641--787; Chatelin, chapters on spectral projections and nonselfadjoint approximation.
- **Limitation:** an operator-valued nonlinear eigenproblem additionally needs analytic Fredholm/Keldysh or contour-operator machinery.

## Citation boundary

Results labelled “directly citable” still require hypothesis matching. Anything involving the central Müller--Rayleigh quotient, full center--lead coupled operator, or physical residual certificate is an adaptation or new proof obligation. No conclusion is promoted merely because a nearby paper uses the same vocabulary.

