# L1 proof review

L1 means research line 1. Review date: 2026-10-31. Task mode: **Review only**.

Source: [[research/explorations/numerical-directions/l1-sketch]], §4.0–4.3,
lines 39–137 of the reviewed version. The earlier
[[research/projects/eig-apost/phase3-analysis/fem-bound/s-dtn-bound]] is accepted
input; its proofs were not re-reviewed. Assumption A1 is accepted as an
assumption. This review concerns the stated mathematical bounds, including
the analytical rate sentence within Proposition 3; it does not assess
numerical estimates or other sections.

**Result: 0 blockers, 1 important caveat, 0 minor caveats.** The finite bounds
are correct. The additional asymptotic statement requires the hypothesis
specified in objection 1.

| Item | Verdict | One line |
|---|---|---|
| 4.0 I1 | correct | Residual bound for the exact reconstruction $w$; source (7)–(8), (10)–(11). |
| 4.0 I2 | correct | $L^2$ transfer bound for the same corrected finite reconstruction $w_d$; source (10), (16), (18). |
| 4.0 I3 | correct | Source projection, moment error, Fourier tail, and $b_M$ match source (12), (15)–(17) and §4.2. |
| Proposition 1(a) | correct | Lines 66, 72–76. |
| Proposition 1(b) | correct | Lines 68, 72–77. |
| Proposition 1(c) | correct | Lines 70, 72–78, under A1 for uniqueness and isolation. |
| Corollary 1′ | correct | Lines 80–84. |
| Lemma 1″ | correct | Lines 86–88. |
| Proposition 2 identity | correct | Lines 94, 106–110. |
| Proposition 2 inequality | correct | Lines 98–104, 112. |
| Proposition 3(i) | correct | Line 122. |
| Proposition 3(ii) | correct | Line 123. |
| Proposition 3(iii) | correct | Line 124. |
| Proposition 3(iv) | objection 1 (rate sentence only) | The inequality and its proof, lines 125–133, are correct; the appended rate at line 135 lacks a hypothesis. |
| Combined bound | correct | Line 137; independent of the rate sentence. |

## Objections

### 1. The rate of the supplied upper bound is not a consequence of a source jump

**Form:** 3 — Missing hypothesis.  
**Class:** important caveat.  
**Location:** §4.3, Proposition 3(iv), line 135.

**Quoted text:**

> 阶数：$E_R=O(h^{1/2})$，因为源在材料界面处间断。所以 $\|g_2\|_-^2=O(h^3)$，与 Fourier 尾的 $O(M^{-3})$ 同阶。

**Argument.** I3 and the cited source §4.2, lines 301–303, require only
$E_R\ge\|f-\widetilde f_R\|_0$. This is a lower constraint on the chosen
upper bound, not an upper constraint on its size as the mesh changes.
Neither a material jump nor best approximation forces the supplied bound
to decrease at any rate.

For a concrete instance within the accepted source setting, fix its actual
material $\rho$, choose a finite source box $D$ crossing a material interface,
and set

$$
f=\frac{\rho\mathbf1_D}{\|\rho\mathbf1_D\|_0},\qquad
\mu_0=s=1,\qquad u=\frac{f}{\rho+1}.
$$

Then $f=(\mu_0\rho+s)u$, $u\in L^2(B)\setminus\{0\}$, and $f$ has a
material-interface jump. On successively refined rectangular grids, choose
$\widetilde f_R=f_R=\Pi_Rf$ and the valid supplied bound $E_R=1$.
Orthogonal projection gives
$\|f-\widetilde f_R\|_0\le\|f\|_0=1$, so this satisfies the quoted input
condition at every resolution, with $\delta_c=0$. Nevertheless
$E_R/h^{1/2}=h^{-1/2}\to\infty$. Thus the first asserted rate does not
follow even for a jumping source with exact projection moments. This
example refutes the assertion about $E_R$; it does not assert that the
actual projection error for this particular source lacks a convergence rate.

The proof at lines 127–133 establishes only
$\|g_2\|_-^2\le(c_R')^2E_R^2$. To infer $O(h^3)$ from that inequality,
one must additionally assume or establish $E_R=O(h^{1/2})$ for the chosen
family of approximations and evaluations. Likewise, the stated Fourier
comparison follows from line 123 when $E_y^2=O(M^{-1})$ and
$b_M\asymp M^2$ along the family being compared.

**Smallest concrete repair.** Replace line 135 by the conditional statement:

> Let $h=\max\{h_x,h_y\}$. If the supplied bounds satisfy
> $E_R=O(h^{1/2})$, then $c_R'=O(h)$ and
> $\|g_2\|_-^2=O(h^3)$. If also $E_y^2=O(M^{-1})$ along the selected
> refinement family, then $\|g_1\|_-^2=O(M^{-3})$.

This repair leaves every finite inequality unchanged. No additional
asymptotic hypothesis is needed for the combined bound at line 137.

## Review record

- **Claim and dependency scope:** the nonnegative self-adjoint $A$ on
  $\mathcal H=L^2(B,\rho)$, its form domain $H^1_\beta(B)$, and the
  unweighted positive operator $L_s:H^2_\beta(B)\to L^2(B)$ are those of
  the accepted source. The nonzero reconstructions, residuals, and
  Rayleigh quotients are those in §4.0. I1–I3 provide the stated bounds;
  A1 is used only where invoked. The conclusions checked are precisely
  the table entries above.
- **Verified references:** `s-dtn-bound.md` §1–2 and Theorem 1 (7)–(8),
  lines 60–173; Theorem 2 (10)–(11), lines 190–220; Lemma 3 (13)–(14),
  lines 259–288, for the cited projection setting; §4.2 (15)–(18),
  lines 291–339. These checks match quantities and hypotheses, without
  reopening the accepted proofs.
- **Same-field check for I2:** the local `theta-v1/README.md` identifies
  the corrected I9.6 source. In
  `test/numerical-directions/theta-v1/reconstructed_theta.m`, lines 25–33
  check candidate, shift, resolution, cells, and modes; lines 47–60 add
  `dF_bNNN` to `F_bNNN` before reconstruction. This matches
  `test/i9/dtn-bound-v1/dtn_bound_i96.m`, lines 2128–2145. The closed-form
  reconstruction at lines 129–140 of the former matches lines 2020–2047
  of the latter. This is a structural field-identity check, not an inference
  from agreement of scalar norms. No saved data outside this worktree were
  accessed and no experiment was rerun.
- **Work completed:** direct checks of the spectral-measure argument,
  monotonicity substitutions, residual orthogonality, form expansion,
  energy duality, Fourier multiplier estimate, and rectangular projection
  estimate. No symbolic or numerical computation was required.
- **Output and authorized writes:** only
  `research/explorations/numerical-directions/l1-proof-review.md`.
  No source proof environments, labels, or numbers were added or changed;
  no insertion blocks were added to the reviewed source.
- **Integrity checks:** the reviewed sketch and accepted theory note were
  not modified. Final Git inspection shows only this new review file;
  there were no commits, branch changes, or writes outside the authorized
  output file.
- **Literature status:** **Review literature verification completed** for
  the local dependencies in scope. The Kato–Temple assertion was checked
  from the supplied proof. No external publication was relied upon,
  downloaded, or left missing; book page verification is not applicable.
- **Remaining proof gaps:** objection 1 only. No steps await external
  literature verification. This report does not certify numerical input
  values or establish A1.
