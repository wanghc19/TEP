# Fallback theorem packages

## Package A — strongest programme

- **Claims:** continuous center representation with injective/controlled quotient; K1; square Fredholm index zero; no representation-induced continuous roots; analytic characteristic values; Nyström/Rayleigh/stable-subspace spectral convergence; no certified pollution.
- **Theoretical novelty:** high if all pieces genuinely couple beyond prior Fliss/Barnett/Hohage/Zhang results.
- **Difficulty:** very high; requires L10, L13, L15, nonlinear spectral approximation.
- **Prior-art risk:** medium-high because each ingredient has strong adjacent prior art; novelty rests on their exact periodic line-defect coupling and certification.
- **Minimum paper:** theorem framework, Calderón nullspace proof, stable generalized trace adaptation, Fredholm proof, convergence theorem, and numerical evidence.
- **Switch away when:** L15 has no natural square reference operator, or discrete no-pollution would delay a complete continuous paper excessively.

## Package B — recommended feasible main paper

- **Claims:** quotient-safe continuous/semi-continuous K1; P1 generalized stable trace relation; fixed-truncation spurious-free algebraic theorem after quotient/side constraint; six-part physical residual certificate; convergence numerics and nonuniform near-edge study. Fredholm index zero and global no-pollution are optional, not title claims.
- **Theoretical novelty:** moderate and defensible if L10/L13 characterize the ambiguity and the fixed-truncation certificate is rigorous.
- **Difficulty:** medium-high but decomposable.
- **Prior-art risk:** medium; must state that restriction--gluing, modal completeness, QP Müller and RtR are prior art.
- **Minimum paper:** scoped PDE setting; P1 adaptation or explicit assumption; quotient K1; fixed-truncation injectivity/certification; high-order interface-only implementation; benchmark and edge conditioning.
- **Switch to it when:** density uniqueness fails, the relation block is not naturally square, or only local/fixed-truncation spectral analysis closes.

## Package C — conservative computational result

- **Claims:** use established RtR/transparent boundary theory; use established BIE representation on its verified regular set; prove only finite-dimensional full-block reconstruction injectivity and residual soundness; contribute a high-order interface-only solver, robust physical certification and a careful near-band-edge convergence/conditioning study.
- **Theoretical novelty:** low-to-moderate; novelty primarily methodological and diagnostic.
- **Difficulty:** moderate.
- **Prior-art risk:** lowest if claims are tightly delimited, though “BIE instead of FEM” and cell DtN are already covered by Yuan--Lu--Antoine/Barnett.
- **Minimum paper:** algorithm, finite-dimensional algebra theorem, residual certificate, reproducible benchmark, convergence/conditioning data, clear failure cases.
- **Switch to it when:** P1 cannot be adapted, exact continuous nullspace characterization is unavailable, or an exact prior-art match to K1 is found.

## Recommendation

Start proofs with **Package B as the committed deliverable**, keep Package A as a stretch track, and preserve Package C as a clean exit. This prevents the project from depending on the most fragile Fredholm and no-pollution claims while retaining a genuinely useful spurious-root audit.

