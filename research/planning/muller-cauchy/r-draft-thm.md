# Current-draft theorem correspondence

This table is an audit, not an endorsement of the present statements. Line numbers refer to the current `draft/draft.tex` and `draft/appendixA.tex` snapshot recorded in the pre-roadmap checkpoint.

| Current item | Draft location | Closest established result | Roadmap disposition | Reason |
|---|---:|---|---|---|
| Global guided mode iff bounded center problem with outgoing data | `draft.tex:448`, Theorem 1 | Fliss (2013), Theorem 4.5, journal p. B450 (local PDF p. 13) | Demote to Lemma P3 (restriction--gluing) | Exact global/bounded equivalence and multiplicity preservation are prior art; the relation language only removes a graph-coordinate restriction. |
| Half-guide Cauchy relation | `draft.tex:295--447` | Fliss (2013), Section 4; Fliss--Klindworth--Schmidt (2015), RtR construction | Keep as Definition P2 and Lemma P2 | Closedness and trace topology are missing in the draft. A relation is primary; DtN and RtR are coordinates when their projections are invertible. |
| Rayleigh radiation space | `draft.tex:509--698` | Barnett--Greengard (2010), Sections 2--3; periodic Green function theory | Retain, but retype in weighted sequence spaces | Dirichlet and Neumann traces have different Fourier weights. Plain unweighted coefficient spaces are insufficient. |
| Single-cell representation | `draft.tex:699`, Theorem 2 | Barnett--Greengard (2010), Theorem 4 and Appendix A, journal pp. 6904--6906, 6912--6914 | Replace by Lemmas B3--B5 and Theorem B1 | Field existence, density uniqueness, and the kernel of reconstruction must be separated. The safe result is a quotient-space isomorphism. |
| Appendix-A complementary representation | `appendixA.tex`, exterior pair near source line 243 | Barnett--Greengard (2010), Lemmas 9--10 and equations (A.4)--(A.12) | Correct before reuse | The exterior double layer must use the exterior wavenumber `k`; the draft currently mixes `D^{(nk)}` into the exterior representation. This roadmap records the correction but does not edit the draft. |
| Completeness of decaying Bloch eigenvectors | `draft.tex:830`, Conjecture 1 | Hohage--Soussi (2013), Theorem 2.2, journal pp. 117--118 and proof pp. 132--133 | Replace by Lemma F2 and Proposition F1 | Ordinary eigenvectors can be incomplete at defective multipliers. Generalized Floquet modes/Jordan chains and the trace Riesz basis are required. |
| Algebraic singularity means a guided mode/no spurious root | `draft.tex:871`, Conjecture 2 | Barnett--Greengard (2010), Theorem 4; Hiptmair--Moiola--Spence (2022), Theorems 1.10--1.12 | Replace by quotient-safe Main Theorem K1 plus a certification protocol | A second-kind BIE can still have representation-induced null vectors or large quasi-resonant inverse norms. Physical reconstruction must be tested separately. |
| Scattering/translation pencil | `draft.tex:1044--1465` | Joly--Li--Fliss (2006), Theorems 3.1 and 4.1; Hohage--Soussi (2013), Theorem 2.2; Zhang (2021/2023) | Interpret as a discretization of the stable Cauchy relation | A finite pencil is not itself a proof of continuous completeness or subspace convergence. |
| Empty line-defect numerical experiment | `draft.tex:1466` onward | Fliss (2013) and later RtR/modal-DtN computations | Leave untouched; create planning-only experiments | The present task forbids numerical execution and implementation. |

## The specific new target

The potentially new theorem is not restriction--gluing, QP Müller singularity, modal completeness, or DtN avoidance separately. It is their rigorously compatible coupling:

\[
  \ker \mathcal A_{\rm rel}(k,\beta)/\mathcal N_{\rm rep}(k,\beta)
  \simeq \mathcal G(k,\beta),
\]

with generalized stable trace coordinates, a completely characterized representation nullspace, and a physical-field certificate that distinguishes genuine guided modes from BIE artifacts. Removing the quotient is an optional strengthening, not a premise.

