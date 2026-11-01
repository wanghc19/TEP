# Goerisch enclosure and width: proof review

**Result: 0 blockers, 0 important caveats, 0 minor caveats.**

**Task mode:** Review only, following the research-worker proof-review workflow.
**Target:** [[research/explorations/numerical-directions/goerisch-width]],
sections 1–4: Lemma 0, Propositions 1–3, and Corollary 4, with their proofs
(lines 24–146). Definitions in section 0 are used as stated, and (H) is
accepted as an assumption.

| Item | Verdict | One line |
|---|---|---|
| Lemma 0, item 1 | correct | The Hilbert space and form meet the assumptions of (10.45). |
| Lemma 0, item 2 | correct | $U=(A+\gamma)^{1/2}:(V,a_\gamma)\to L^2_\rho(B)$ is unitary and conjugates $A_{\rm book}$ to $A+\gamma$, including their domains. |
| Lemma 0, item 3 | correct | Equations (10.52)–(10.54) give $w_1=z$ and $(A_0,A_1,A_2)=(G,1,q)$. |
| Proposition 1, step 1 | correct | The zero normal trace on the two internal cuts removes the distributional interface terms in the zero extension. |
| Proposition 1, step 2 | correct | The normal-trace Green formula and the conjugate quasi-periodic phases give (10.69). |
| Proposition 1, step 3 | correct | The isometry and admissibility satisfy Lemma 10.25 and yield $J\ge G$. |
| Proposition 1, step 4 | correct | (H) supplies the spectral hypotheses, and (C) excludes endpoint eigenelements in $\operatorname{span}\{v\}$. |
| Proposition 1, step 5 | correct | Theorem 10.29(a),(b) applies with $N=r=s=1$ and gives the stated two endpoints after subtracting $\gamma$. |
| Proposition 2, item 1 | correct | Cauchy–Schwarz and admissibility give $1/\nu<1/q\le G\le J<1/\mu$. |
| Proposition 2, item 2 | correct | On the stated interval, the upper endpoint increases with $J'$ and the lower endpoint decreases. |
| Proposition 2, item 3 | correct | $Tz$ is admissible, has squared $b_X$ norm $G$, and has the asserted flux representation. |
| Proposition 3, item 1 | correct | Spectral integration gives $G=(1-R)/\ell$ and $\ell(qG-1)=(\theta-\lambda)-qR$. |
| Proposition 3, item 2 | correct | Substitution into $W$ gives the stated formula, with both denominator factors strictly positive. |
| Proposition 3, item 3 | correct | The denominator bounds on the upper and lower spectral supports give all the stated inequalities. |
| Proposition 3, product form | correct | Factoring the expression in item 2 is valid when $\theta\ne\lambda$. |
| Corollary 4, upper bound | correct | For $\theta>\lambda$, $0\le\varepsilon<1$ and $\nu R\le\theta-\lambda$ justify each substitution; the zero-error case is handled separately. |
| Corollary 4, lower bound | correct | $q<\nu\le\tau+\gamma$ makes the substituted numerator positive, and both denominator substitutions have the stated direction. |

## Objections

No objections.

## Citation and hypothesis verification

The inspected source is Mitsuhiro T. Nakao, Michael Plum, and Yoshitaka
Watanabe, *Numerical Verification Methods and Computer-Assisted Proofs for
Partial Differential Equations*, Springer Series in Computational
Mathematics 53, Springer, 2019,
[DOI: 10.1007/978-981-13-7669-6](https://doi.org/10.1007/978-981-13-7669-6).
The local copy is [[ref/ref_data/books/Nakao2019.pdf]]. PDF page numbers
below are one-based.

| Inspected result | Printed pages | PDF pages | Application checked |
|---|---|---|---|
| (10.45) and its standing assumptions | 372 | 378 | Lemma 0, item 1. |
| (10.46)–(10.48) and the associated spectral definitions | 373–374 | 379–380 | Lemma 0, item 2. |
| (10.52)–(10.54) | 375 | 381 | Lemma 0, item 3. |
| Lemma 10.25, (10.68)–(10.70) | 380 | 386 | Proposition 1, steps 2–3; Proposition 2, item 1. |
| Theorem 10.29(a),(b), (10.81)–(10.87) | 386–387 | 392–393 | Proposition 1, steps 4–5. |

The hypotheses of Theorem 10.29 were matched in source order:

1. **Common hypotheses:** the single trial $v\in H=V$ is nonzero because
   $b(v,v)=1$. Lemma 0 supplies the Hilbert-space setting and $A_1,A_2$;
   Proposition 1, steps 1–3, supplies $X,b_X,T,\hat w$ as in Lemma 10.25
   and $\hat A_0=J$. Equation (10.81) becomes exactly the two scalars in
   the draft.
2. **Part (a):** $0<\mu<\nu<\infty$ follows from section 0. Lemma 0 and
   (H) exclude essential spectrum in $(\mu,\nu)$ and give a single
   finite-multiplicity spectral value there, so the accumulation condition
   holds. Step 4 excludes a $\mu$-eigenelement in the trial span. The
   scalar generalized eigenproblem and (C) give $r=1$. Equation (10.84)
   yields $\ell\le\mu+1/\hat\kappa(\mu)$.
3. **Part (b):** the same endpoints meet $0\le\mu<\nu<\infty$. The same
   spectral information satisfies the absence of essential spectrum and
   the accumulation condition at the lower endpoint. Step 4 excludes a
   $\nu$-eigenelement in the trial span. The scalar generalized
   eigenproblem and (C) give $s=1$. Equation (10.87) yields
   $\ell\ge\nu+1/\hat\kappa(\nu)$.

**Literature status:** Review literature verification completed.

**Output file:**
`research/explorations/numerical-directions/goerisch-width-review.md`.
The reviewed proof file was not modified. Only this review file was written.
