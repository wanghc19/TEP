# DtN inertia count and endpoint matrices: proof review

Scope: sections 0–4 of [[research/explorations/numerical-directions/dtn-inertia-count]]; mathematical files inspected: that note, [[research/explorations/numerical-directions/goerisch-width]] (the definition of (H) and Proposition 5), and [[ref/ref_data/books/Kato1995.pdf]] (VI.2.1 and VI.2.6). DtN means Dirichlet-to-Neumann.

**Result: 0 blockers, 1 important caveat, 2 minor caveats.**
**Task mode: Review only.**

D-1 and D-2 correct local proof expressions without changing the count or
matrix bounds. D-3 concerns the final assertion of (H) for the same
endpoints. The assumptions (P), (D+), (D−), and (C) are accepted as
assumptions. Line numbers below refer to the reviewed version.

| Item | Verdict | One line |
|---|---|---|
| Setting and (P) | correct | Lines 19–47 define the operators and forms consistently; (P) supplies a positive uniform distance to the half-lead spectra. |
| Standard facts (F1)–(F4) | correct | The Fourier, gluing, compactness, spectral, Fredholm, and resolvent facts are used in their standard forms. |
| Kato VI.2.1 / VI.2.6 correspondence | correct | Lines 73–79 match the inspected statements and their hypotheses. |
| Lemma 1(a) | correct | The lift and resolvent constructions give bounded extensions, and the homogeneous Dirichlet problem gives uniqueness. |
| Lemma 1(b) | correct | The resolvent correction has zero trace and exactly cancels the shifted weak residual. |
| Lemma 1(c) | correct | The explicit lift is a norm limit of finite-rank maps into $L^2$, and the bounded correction preserves compactness. |
| Lemma 1(d) | correct | Changing the second extension by a zero-trace function leaves the form unchanged. |
| Lemma 2: one-dimensional inequality | correct | The minimizing hyperbolic-cosine function and vanishing cross term give the stated sharp constant. |
| Lemma 2: Fourier summation | correct | Taking $\kappa=\langle k\rangle\ge1$ gives the common factor $\coth\ell$. |
| Lemma 3(a) | correct | The zero-trace differences and Hermitian symmetry give the mixed-extension identity with the stated sign. |
| Lemma 3(b) | correct | The direct-sum resolvent identity is exactly Lemma 1(b) on each lead. |
| Lemma 3(c) | correct | $p=t_{-1}$ is a positive inner product equivalent to the core $H^1$ norm. |
| Lemma 3(d) | D-1 | The compactness argument needs the supremum, rather than the minimum, of the reciprocal Fourier weights. |
| Lemma 3(e) | correct | The operator representation, compact self-adjoint structure, and Lipschitz estimate follow from the stated identities. |
| Lemma 3(f) | correct | Resolvent continuity gives the derivative, and the core mass gives strict decrease on each nonzero vector. |
| Lemma 4: test-function decomposition | correct | The remainder vanishes in the core and has zero lead traces, so the weak lead terms vanish. |
| Lemma 4: mapping into the kernel | correct | The decomposition and VI.2.1(iii) give an element of $D(A)$ satisfying the eigenvalue equation. |
| Lemma 4: injectivity | correct | Restriction of $U_\lambda u$ to the core recovers $u$. |
| Lemma 4: surjectivity | correct | Zero-extended lead tests and extension uniqueness recover each global eigenfunction. |
| Lemma 5: spectral decomposition and constants | D-2 | The definition of $c_-$ needs the case $H_-=\{0\}$. |
| Lemma 5: $n(\lambda)=\dim H_-$ | correct | The negative subspace and the complementary nonnegative subspace give both inequalities. |
| Lemma 5: $\nu(\lambda)=n(\lambda)+z(\lambda)$ | correct | Projection along the positive subspace bounds every nonpositive subspace's dimension. |
| Lemma 5: invertibility when $z=0$ | correct | The Fredholm alternative applies to $I-K$. |
| Lemma 6: step 1 | correct | The Dirichlet resolvents give zero-trace particular solutions whose zero extensions belong to $V$. |
| Lemma 6: step 2 | correct | The bounded antilinear functional is represented in $(\mathcal H,p)$ and solved using $(I-K)^{-1}$. |
| Lemma 6: step 3 | correct | The two classes of tests combine to give the full weak equation, and VI.2.1(iii) gives the operator equation. |
| Lemma 6: step 4 | correct | Bijectivity and closedness give a bounded everywhere-defined inverse. |
| Lemma 7: Riesz representers | correct | Their endpoint derivatives give the corresponding Fourier trace functionals, including the left-end sign. |
| Lemma 7: representer norms | correct | Evaluation at the represented endpoint gives $\coth(\kappa_k\ell)/\kappa_k$. |
| Lemma 7: formula for $\delta_{\pm,k}$ | correct | The conjugated right-hand side is $B_{\pm,k}^H$, and the projection norm has the stated matrix expression. |
| Lemma 7: best-approximation bound | correct | Orthogonal projection minimizes the $e$-norm error. |
| Theorem 1, part 1 | correct | The compact representation gives finite indices and Lemma 4 identifies the kernel multiplicity. |
| Theorem 1, part 2 | correct | The local index argument makes kernel points a finite set; Lemma 6 excludes all remaining spectral points in the window. |
| Theorem 1, part 3 | correct | A zero at the lower endpoint contributes to the jump; a zero at the upper endpoint does not. |
| Theorem 1 proof, step 1 | correct | This is the stated combination of Lemmas 3–5. |
| Theorem 1 proof, step 2: choice of $c_0$ | D-2 | Use the completed definition of $c_-$ before taking $c_0=\min(c_-,c_+)$. |
| Theorem 1 proof, step 2(i) | correct | The fixed negative subspace persists under the norm-small perturbation. |
| Theorem 1 proof, step 2(ii) | correct | Positivity on the fixed positive subspace bounds the nonpositive index. |
| Theorem 1 proof, step 2(iii) | correct | Strict decrease makes the former negative-plus-kernel subspace negative. |
| Theorem 1 proof, step 3 | correct | The two one-sided index identities exclude all nearby kernel points, including one-sided neighborhoods at the endpoints. |
| Theorem 1 proof, step 4 | correct | Kernel points are eigenvalues, and nonkernel points are in the resolvent set. |
| Theorem 1 proof, step 5 | correct | Telescoping the one-sided jumps gives the count on $[\alpha_-,\alpha_+)$. |
| Theorem 2, part 1 | correct | The two finite-matrix inertia bounds give the upper bound for the total multiplicity. |
| Theorem 2, part 2 | D-3 | The two spectral conclusions hold; the final assertion of (H) for the same endpoints needs $\alpha_-\ge0$. |
| Theorem 2 proof, step 1 | correct | (D+) gives an upper form on $V_h$, whose negative subspace is also negative for $t_{\alpha_-}$. |
| Theorem 2 proof, step 2 | correct | (D−) and the trace bound give the stated lower form $\ell$. |
| Theorem 2 proof, step 3(i) | correct | The $e$-orthogonal decomposition gives the energy identity. |
| Theorem 2 proof, step 3(ii) | correct | $q\ge0$ and $q\le q_{\max}$ justify weighted Cauchy–Schwarz and the displayed Young inequality. |
| Theorem 2 proof, step 3(iii) | correct | The representer errors control the trace coefficients, and the spectral-norm bounds handle both signs of $\hat\Lambda_\pm$. |
| Theorem 2 proof, step 4 | correct | The coefficients combine into exactly $L_h$ and $c_W$, with the indicated signs. |
| Theorem 2 proof, step 5 | correct | A nonzero vector in a negative subspace has a nonzero projected coefficient vector, whose image is negative for $L_h$. |
| Theorem 2 proof, step 6 | correct | The inertia inequalities and Theorem 1 give the claimed count bound. |
| Theorem 2 proof, step 7 | correct | Proposition 5 supplies a spectral point, Theorem 1 makes it an eigenvalue, and the count bound gives uniqueness and simplicity. |

## Objections

### D-1. The Fourier-tail coefficient uses the wrong extremum

**Form:** 1 — Failed step. **Class:** minor caveat.
**Location:** Lemma 3(d), proof step 4, line 159.

**Quoted text:**

> $\|u-P_Nu\|_{L^2(D)}^2\le(\min_{|k|>N}\langle k\rangle^{-2})\|u\|_1^2\to0$.

**Argument.** The positive numbers $\langle k\rangle^{-2}$ tend to zero
as $|k|\to\infty$, so the displayed minimum does not exist. Interpreting
it as an infimum gives zero and makes the inequality false: on
$D=(0,1)\times I$ with $\beta_0=0$, take
$u(x,y)=e^{2\pi\mathrm i(N+1)y}$. Then $P_Nu=0$ and the left side is 1,
whereas the proposed right side is zero. This is a local extremum error;
the compactness conclusion and its finite-mode argument remain valid.

**Repair.** Replace the coefficient by

$$
\sup_{|k|>N}\langle k\rangle^{-2}
=\left(\min_{|k|>N}\langle k\rangle^2\right)^{-1}.
$$

It tends to zero and bounds each omitted mode. With this replacement,
the stated norm-limit proof of compactness is complete.

### D-2. Define the negative-subspace constant when that subspace is zero

**Form:** 1 — Failed step. **Class:** minor caveat.
**Location:** Lemma 5, proof step 3, lines 209–210; Theorem 1 proof
step 2, line 234.

**Quoted text:**

> $c_-=\min\{\kappa_j-1:\kappa_j>1\}$
>
> 两者都是有限集上的最值，所以为正。

**Argument.** The set defining $c_-$ may be empty. For example, choose
$\mathcal W=[-2,-1]$, which satisfies (P) because $A_\pm\ge0$.
At $\lambda=-1$, Lemma 3 gives $K(-1)=0$, so $H_-=\{0\}$ and there is
no eigenvalue $\kappa_j>1$. Thus the displayed minimum and the subsequent
$c_0$ are undefined. The claimed inequality on $H_-$ is vacuous in this
case, so no extra spectral assumption is needed.

**Repair.** Set $c_-=1$ when $H_-=\{0\}$; otherwise use the displayed
minimum. Then $c_->0$, the vacuous inequality holds, and the local-index
proof uses a defined positive $c_0$ in every case.

### D-3. The final assertion of (H) needs its lower-endpoint condition

**Form:** 3 — Missing hypothesis. **Class:** important caveat.
**Location:** Theorem 2, final sentence of part 2, line 333; also the
summary at line 61.

**Quoted text:**

> 特别地，(H) 对 $(\alpha_-,\alpha_+)$ 和 $\lambda=\lambda_*$ 成立。

The cited definition in `goerisch-width.md`, line 19, is:

> $0\le\alpha_-<\alpha_+<\infty$，$\sigma(A)\cap(\alpha_-,\alpha_+)=\{\lambda\}$，$\lambda$ 是有限重特征值。

**Argument.** The present note allows arbitrary real $\alpha_-<\alpha_+$
in (P), and Theorem 2 adds only $\alpha_+\ge0$. Step 7 proves the
spectral intersection and multiplicity conclusions, but neither of
these implies $\alpha_-\ge0$. Nonnegativity of $A$ constrains spectral
points, not the endpoints of an interval containing them. In particular,
the negative part of a window introduces no obstruction to (P), since
both half-lead operators are nonnegative. Thus the two bullet conclusions
of part 2 are justified, while the final sentence omits one condition
of the specifically cited (H).

**Smallest repair.** Qualify the final sentence and its summary:
“If also $\alpha_-\ge0$, (H) holds for these endpoints.” Equivalently,
add $\alpha_-\ge0$ to the hypotheses of part 2 when claiming (H).
The count theorem and the matrix inequalities need no such restriction.

## Verification record

**Verified source:** Tosio Kato, *Perturbation Theory for Linear Operators*,
corrected printing of the second edition (1980), reprinted in *Classics
in Mathematics*, Springer, 1995,
[DOI: 10.1007/978-3-642-66282-9](https://doi.org/10.1007/978-3-642-66282-9).

| Result | Printed / PDF page | Hypothesis and conclusion match |
|---|---|---|
| VI.2.1(i),(iii) | 322 / 344 | The forms are densely defined, closed, and sectorial, in source order; (i) gives the weak identity for operator-domain vectors, and (iii) applies with the entire form domain as a core. |
| VI.2.6 | 323 / 345 | The forms are densely defined, symmetric, closed, and bounded below, in source order; the associated operators are self-adjoint with the same nonnegative lower bound. |

The applications in Lemmas 1, 4, and 6 stay within these conclusions.
Proposition 5 of `goerisch-width.md` was used as an accepted result for
the same global operator $A$ and the stated normalized trial and
admissible auxiliary field. Its spectral-intersection conclusion does
not require (H).

**Literature status:** Review literature verification completed.
All requested items were reviewed. No computations or experiments were
needed. Only `research/explorations/numerical-directions/dtn-inertia-count-review.md`
was written; the proof under review was preserved unchanged.
