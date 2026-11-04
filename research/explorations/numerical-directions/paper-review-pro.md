# Proof review of the paper draft and lecture notes

Review date: 4 November 2026.

**Documents reviewed:** the uploaded paper.tex (952 lines) and lecture-notes.tex (2087 lines), under the instructions in paper-review-request.md. Locations below refer to these uploaded TeX sources. The paper and notes were read together; a proof supplied by the notes is not treated as missing from the paper.

**Scope convention:** reported numerical inputs and their separately audited computation are accepted. No numerical eigenproblem, quadrature implementation, or floating-point calculation is re-audited. Arithmetic below checks the deductions from the printed inputs, as expressly required by item 6. An approximate displayed scalar is distinguished from an interval asserted to contain a spectral point.

## 1. Summary

| Severity | Number |
|---|---:|
| blocker | **1** |
| important | **0** |
| minor | **10** |

**Verdict:** the spectral-measure and four-corner theorems, existence in the isolation window, and the A–D argument for (H) are supported by the supplied proofs and numerical inputs; the two literal decimal enclosures do not follow as printed because their displayed endpoints lie inward of the intervals obtained from those inputs (Objection 1).

The smallest endpoint repairs are

$$
\lambda_*\in[2.4287286691977,\;2.4287286736602]
$$

and, for the independent first-order existence certificate,

$$
I_1\subset[2.4286785150,\;2.4287788272].
$$

The latter outer interval remains strictly inside $(1.7424,5.6169)$. Thus this repair preserves existence, the proof of (H), and the claimed order of the narrow interval's width. The already printed frequency enclosure $[1.5584378939,1.5584378954]$ is outward and passes.

The remaining objections concern local false explanations, missing qualifications in compressed statements, or inconsistent symbols. In particular, the independent shifted $LDL^*$ calculation supplies the core count despite the wrongly named generalized pencil. The transfer-tail lemma and the positive-lower-endpoint surface-state argument are checked.

Three references have an access limitation: BrownHoangPlumWood2009 is not verified in full, NakaoPlumWatanabe2019 is not verified for the precise theorem attribution, and ReedSimon1978 is not verified. These are citation-verification limitations, not assertions that the cited results are false.

## 2. Coverage

### 2.1 Coverage of the seven requested priorities

| Item | Files and scope | Verdict |
|---|---|---|
| 1. Band-gap certificate | Notes §8; paper §5.2 | **Checked:** Fourier/complement square, nonpositive-subspace bound $N_{\le}\le n+z$, Bloch Lipschitz modulus, phase symmetry, analytic trapezoid remainder and matrix error transport. The compressed panel statement has **O2**. |
| 2. Rewritten arguments | Notes §§4, 6, 9, 10; paper §§3.2, 4.3, 4.5–4.6, 5.3, 6.1 | **Checked:** spectral-measure theorem with the stated weaker conditions; four-corner theorem without an additional positivity test; signed sweep and quantitative interface correction; positive-lower-endpoint surface exclusion; transfer-tail lemma. Local statements have **O3, O5, O8–O10**. |
| 3. Complete proof of (H) | Notes §§7, 11 and first-order interval; paper §§5.1, 6.2 | **Checked:** upper-endpoint reduction, complement lower bound, independent inertia proof, and matching geometry/phase/window/traces. **O1** corrects the displayed existence interval; **O4** corrects the diagnostic pencil label. The corrected existence interval still supplies the required hypothesis. |
| 4. DtN reduction | Notes §3; paper §2.2 | **Checked:** extension, kernel equivalence, resolvent construction and independent use of (P). Discrete DtN selects the candidate and is not used as a certified approximation. **O7** concerns explanatory text only. |
| 5. Other proofs and standard facts | Notes §§2, 5, remainder of §§6, 9, 10, and §13 | **Checked** with the local qualifications in **O6, O8–O10**. The standard-fact audit is in §2.4 below. |
| 6. Arithmetic and cross-file consistency | All reported deductions in both files | **Checked** in §4 below, except the literal interval displays in **O1** and the pencil identification in **O4**. Approximate scalar displays are recorded at their stated precision. |
| 7. Citation attributions | All 18 references and all citation occurrences in paper.tex | Audited in §5. **O11** concerns the universal separation claim. Inaccessible source portions are marked **not verified**. The notes have no additional independent citation occurrences. |

### 2.2 Lecture-notes subsection coverage

“Checked” includes reading the corresponding mathematical claims; introductory or scope-only subsections have no independent proof to verify.

| File | Subsection | Verdict |
|---|---|---|
| lecture-notes.tex | §1.1 问题 | Checked: model and intended spectral problem. |
| lecture-notes.tex | §1.2 结论 | **O1** for literal interval displays; other dependencies checked. |
| lecture-notes.tex | §1.3 方法一览 | Checked; width interpretation is qualified by **O8**. |
| lecture-notes.tex | §1.4 阅读路线 | Checked; no independent proof. |
| lecture-notes.tex | §2.1 几何与材料 | **O6**; remaining geometry, densities and side assignments checked. |
| lecture-notes.tex | §2.2 方程、Bloch 相位与弱形式 | Checked: positive density, closed form, self-adjoint realization, transmission and phase conditions. |
| lecture-notes.tex | §2.3 谱：能带、带隙与导模 | Checked: bands and common-gap setting; **O7** for the explanation of (H). |
| lecture-notes.tex | §3.1 记号 | Checked: form, trace and Fourier conventions. |
| lecture-notes.tex | §3.2 半导波的 Dirichlet 算子与假设 (P) | (P) checked; **O7** for the surface/global-spectrum explanation. |
| lecture-notes.tex | §3.3 延拓算子与 DtN 形式 | Checked: right inverse, uniqueness, resolvent identity, boundedness and compactness into weighted $L^2$. |
| lecture-notes.tex | §3.4 芯区上的约化形式 | Checked: extension/restriction, parameter identity and derivative sign. |
| lecture-notes.tex | §3.5 离散 DtN | Checked as a trial-field construction; no certified accuracy premise. |
| lecture-notes.tex | §4.1 设定：谱测度 | Checked: the form domain supplies the required first moment. |
| lecture-notes.tex | §4.2 互补能量：可计算的 $J\ge G$ | Checked: admissibility, Cauchy–Schwarz, minimizer and squared-distance identity. |
| lecture-notes.tex | §4.3 区间定理 | Checked: support signs, both denominator signs and monotone substitution $G\mapsto J$. |
| lecture-notes.tex | §4.4 区间有多宽 | Exact identities checked; **O8** for their unconditional interpretation. |
| lecture-notes.tex | §4.5 不用 (H) 的一阶区间 | Proposition checked; numerical specialization **O1**. |
| lecture-notes.tex | §5.1 试探场：截断的 FEM–DtN 解 | Admissibility and cutoff checked; **O8** for claimed monotonic deterioration. |
| lecture-notes.tex | §5.2 通量：$RT_3$ 最小化 | Checked: Piola conformity, end flux and quasi-periodic boundary cancellation. |
| lecture-notes.tex | §5.3 不需要归一化的公式 | Checked, including the negative $(q-s)^2/s^2$ term. |
| lecture-notes.tex | §6.1 四角定理 | Checked: affine numerators/denominators, fixed signs, vertex extrema; no extra positivity condition. |
| lecture-notes.tex | §6.2 积分的可靠界：多项式模型 | **O10** for the trigonometric clause; product, truncation, reciprocal and square-last estimates checked. |
| lecture-notes.tex | §6.3 按单元类型给界 | Checked: polynomial degrees and the conforming geometric deformation. |
| lecture-notes.tex | §6.4 真材料质量：带符号的同伦恒等式 | Checked: orientation, crossings/overlaps, signed identity and remainder factors. |
| lecture-notes.tex | §6.5 界面单元上的残差 | Quantitative estimate, inverse-map lemma and changed-assignment area bound checked; explanatory claim **O9**. |
| lecture-notes.tex | §6.6 结果 | Input bounds accepted; arithmetic checked; **O1**. |
| lecture-notes.tex | §7.1 惯性指数 | Checked: strict-negative convention, nullity and half-open count. |
| lecture-notes.tex | §7.2 计数定理的证明 | Checked: trace, compact structure, kernel correspondence, resolvent construction and local crossings. |
| lecture-notes.tex | §7.3 只需要检查上端点 | Checked: existence plus $n(\alpha_+)\le1$ forces uniqueness and simplicity. |
| lecture-notes.tex | §7.4 要做哪几件事 | Checked: A–D dependencies and reuse for a fixed configuration. |
| lecture-notes.tex | §8.1 单胞问题 | Checked: fixed transverse phase, compact fibers and Floquet union. |
| lecture-notes.tex | §8.2 平面波空间与补空间的配方 | Checked: $G=256(B-B^2)$, complement denominator and negative/nonpositive dimension arguments. |
| lecture-notes.tex | §8.3 Bloch 相位的 Lipschitz 模与面板检验 | Checked; the notes include the necessary $k_L>r_i$ condition missing from the paper. |
| lecture-notes.tex | §8.4 夹杂 Fourier 系数的积分误差 | Checked: divergence identity, analytic strip bound, trapezoid lemma and safe matrix corrections. |
| lecture-notes.tex | §8.5 结果 | Checked from given inputs: complete phase cover, strict margins and distances. |
| lecture-notes.tex | §9.1 设定 | Checked: translated pure periodic material, both orientations and weighted resolvent bounds. |
| lecture-notes.tex | §9.2 单层算子 | Checked: trace constant, kernel correspondence, compact perturbation, derivative and half-resolvent formula. |
| lecture-notes.tex | §9.3 端点计数 | Checked, including endpoint invertibility and the stronger positive-lower-endpoint corollary. |
| lecture-notes.tex | §9.4 怎样证明 $\mathsf B_\lambda$ 的惯性：低频块、尾项与 Schur 补 | Checked: hybrid reference, tail/cross bounds, Schur order and inertia. |
| lecture-notes.tex | §9.5 低频块：二次残差恒等式 | Checked: stationary residual identity, dual bound, Bloch source and analytic quadrature. |
| lecture-notes.tex | §9.6 结果 | Checked: corrected Schur minima are positive; no second subtraction of the already incorporated error is needed. |
| lecture-notes.tex | §10.1 半导波上的形式逆 | Checked: positive and negative spectral multipliers. |
| lecture-notes.tex | §10.2 有限迹空间上的二次残差界 | Checked: orthogonality, residual norm, both signs and noncompact admissible fields. |
| lecture-notes.tex | §10.3 高频迹的提升 | Checked: exact trace, homogeneous collar, energy identity and monotone bounds. |
| lecture-notes.tex | §10.4 对所有迹成立的下界矩阵 | Checked: boundary orthogonality, sign of $u+K_+r_2$, square completion and safe assembly. |
| lecture-notes.tex | §10.5 怎样构造低频场和通量 | Checked: feasible conforming fields and trial-field alternatives. |
| lecture-notes.tex | §10.6 实际采用的构造 | **O5** for the undefined transfer symbol; tail lemma, trace corrections, square integrability and quadrature checked. |
| lecture-notes.tex | §10.7 结果 | Checked: penalties, budget and consistency with the paper. |
| lecture-notes.tex | §11.1 思路 | Checked: three complement couplings. |
| lecture-notes.tex | §11.2 能量内积、端口代表元与投影常数 | Checked: form Parseval, tail minimum, port representatives and normal signs. |
| lecture-notes.tex | §11.3 配方下界 | Checked: general/scalar Gram bounds, completion of the square and projection of negative subspaces. |
| lecture-notes.tex | §11.4 参数与规模 | Checked: dimensions and mass amplification. |
| lecture-notes.tex | §11.5 结果 | **O4** for pencil identification; basis independence, matrix error transport and independent inertia checked. |
| lecture-notes.tex | §11.6 (H) 的完整证明链 | Checked: same model, phase, window, traces and existence input. |
| lecture-notes.tex | §12.1 结果总表 | **O1, O8**; other repeated numbers and arithmetic checked. |
| lecture-notes.tex | §12.2 计算成本 | Checked: per-run meanings, run multiplicities and time conversions. |
| lecture-notes.tex | §12.3 怎样看这些数字 | Checked proof dependencies and reuse; width explanation subject to **O8**. |
| lecture-notes.tex | §13.1 舍入误差 | Read; rounding is excluded from this review by instruction. |
| lecture-notes.tex | §13.2 尚未完成的部分 | Checked scope of the fixed phase and the stronger two-orientation surface test. |
| lecture-notes.tex | §13.3 用到的标准事实 | Checked as detailed in §2.4. |

### 2.3 Paper subsection coverage

For subsections containing numbered subsubsections, both the parent and the individual subsubsections are recorded.

| File | Subsection | Verdict |
|---|---|---|
| paper.tex | Abstract | **O1, O8**; remaining dependency statements checked. |
| paper.tex | §1 问题 | Checked; background citations audited in §5. |
| paper.tex | §1 相关工作 | **O11**; remaining citations audited in §5. |
| paper.tex | §1 本文的贡献 | Checked except the unqualified width interpretation, **O8**. |
| paper.tex | §2.1 几何、方程与谱 | **O6, O7**; form and spectral setting checked. |
| paper.tex | §2.2 DtN 约化 | Checked with the notes; local explanation **O7**. |
| paper.tex | §3.1 互补能量 | Checked with notes §4.2. |
| paper.tex | §3.2 区间定理 | Checked; the external $N=1$ attribution is not verified. |
| paper.tex | §3.3 宽度 | Exact formulas checked; **O8**. |
| paper.tex | §3.4 不用 (H) 的一阶区间 | Abstract proposition checked; **O1**. |
| paper.tex | §4.1 试探场与通量 | Construction checked; **O8**. |
| paper.tex | §4.2 不需要归一化的公式 | Checked. |
| paper.tex | §4.3 四角定理 | Checked. |
| paper.tex | §4.4 多项式模型 | **O10**; other rules checked with notes §6.2. |
| paper.tex | §4.5 真材料质量 | Checked with the signed sweep proof. |
| paper.tex | §4.6 界面单元上的残差 | Quantitative proof checked; **O9**. |
| paper.tex | §4.7 结果 | **O1**; input and sign checks pass. |
| paper.tex | §5.1 计数判据 | Checked with notes §7. |
| paper.tex | §5.2 周期引线的带隙 | Checked except **O2** in its panel statement. |
| paper.tex | §5.2.1 Fourier 补空间计数 | Checked, including $N_{\le}$ and nullity. |
| paper.tex | §5.2.2 覆盖全部 Bloch 相位 | Lipschitz and symmetry checked; **O2**. |
| paper.tex | §5.2.3 Fourier 系数的求积误差 | Checked; Trefethen–Weideman attribution verified. |
| paper.tex | §5.2.4 结果 | Checked from given finite tests and phase coverage. |
| paper.tex | §5.3 表面态 | Main proof checked; **O3** affects only the separate general-count sentence. |
| paper.tex | §5.3.1 单层算子 | Kernel/monotonicity corollary checked; **O3**. |
| paper.tex | §5.3.2 惯性的有限检验 | Checked with notes §§9.4–9.5. |
| paper.tex | §5.3.3 结果 | Checked. |
| paper.tex | §6.1 半导波 DtN 形式的下界 | Checked except local symbol **O5**. |
| paper.tex | §6.1.1 二次残差界 | Checked. |
| paper.tex | §6.1.2 全迹下界 | Checked. |
| paper.tex | §6.1.3 单胞场与传递矩阵 | **O5**; the notes supply convergence for the valid tail lemma. |
| paper.tex | §6.1.4 结果 | Checked. |
| paper.tex | §6.2 芯区计数 | Core theorem and independent count checked; **O4**. |
| paper.tex | §6.2.1 投影常数与端口代表元 | Checked. |
| paper.tex | §6.2.2 芯区下界 | Theorem checked; generalized-pencil sentence **O4**. |
| paper.tex | §6.2.3 结果 | **O4** for the repeated label; independent $LDL^*$ proof and final (H) theorem checked. |
| paper.tex | §7.1 主要结果 | **O1, O8**; cross-file arithmetic otherwise checked. |
| paper.tex | §7.2 成本 | Checked; the stated 12 minutes concerns the interval computation, with the additional (H) work separately listed. |
| paper.tex | §7.3 结论与局限 | **O1, O8**; uniqueness, simplicity, scope and reuse checked. |

### 2.4 Standard facts and the hypotheses actually supplied

| Standard fact in notes §13.3 | Application and hypotheses | Verdict |
|---|---|---|
| Self-adjoint spectral theorem | The strip, half-lead and periodic operators arise from closed nonnegative forms with $1\le\rho\le17$. The unbounded strip is not assumed to have compact resolvent. | Checked. |
| Min–max principle | Compact fibers on bounded cells; finite Hermitian matrices; identity-minus-compact reduced forms in the appropriate Hilbert norm. | Checked. |
| Form representation / Riesz representation | Closed semibounded forms define the PDE operators; bounded functionals are represented in coercive energy spaces. The weak eigenfunction identity supplies membership in the operator domain. | Checked. |
| Floquet–Bloch decomposition | Each separate lead is periodic longitudinally, with fixed transverse phase and positive bounded density; bounded-cell fibers have compact resolvent. | Checked. |
| Essential-spectrum invariance under gluing | The two ends are periodic, the core is bounded, and the cross-section is bounded. Decoupling at compact interfaces changes the resolvent compactly; the resulting essential spectrum is the union of the two periodic spectra. | Checked mathematically. Direct verification of the Reed–Simon attribution is unavailable. |
| Fredholm alternative | Applied to $I-K(\lambda)$ with compact $K$, and to $\mathsf B_\lambda=\tfrac12 I+\text{compact}$. | Checked. |
| Sobolev traces | Flat ports and the stated quasi-periodic Fourier trace space; explicit bounded liftings and trace constants are supplied. | Checked. |
| One-dimensional Rellich | Used on finite intervals after transverse Fourier truncation. The remaining Fourier tail tends to zero in operator norm. Compactness is not asserted for the unbounded-domain Sobolev embedding. | Checked. |
| Bernstein ellipses and Chebyshev coefficients | Polynomial trial coefficients and the analytic source factors admit the stated continuations. Real-axis conjugates are continued by conjugating coefficients. Source/Poisson denominators are pole-free in the specified strips. Elementwise analytic-map/Jacobian bounds are given inputs. | Checked, including the tensor $32\mathcal M2^{-2q}$ estimate. Interpolation selects a trial field; no unproved interpolation-accuracy bound is used. |
| Raviart–Thomas conformity | Contravariant Piola maps, matching normal moments, quasi-periodic top/bottom matching and the specified end conditions supply $H(\operatorname{div})$. | Checked; the first-cell transfer symbol needs the local identification in **O5**. |

### 2.5 Matching hypotheses along the A–D chain

| Quantity / condition | Value or convention used throughout | Verdict |
|---|---|---|
| Transverse phase | $\beta=0.5$, $\beta_k=0.5+2\pi k$ | Checked. |
| Left material | Three-lobed inclusion with $a=0.12$, density 17, background 1 | Checked. |
| Right material | Three-lobed inclusion with $a=0.20$, density 17, background 1 | Checked. |
| Core material | Printed five-lobed inclusion, density 4, background 1 | Checked; $q=\lambda\rho+1$ gives $M^q=(\lambda+1)M_1+3\lambda M^*$. |
| Half-lead orientation | Right $s=x-\tfrac12$; left $s=-\tfrac12-x$; material pulled back with its actual orientation | Checked. No identification of the two operators by reflection is used. |
| Trace / normal convention | Core values at $x=\pm\tfrac12$; half-lead outward normals point toward the core | Checked against the plus signs in the reduced form and the port representatives. |
| Window | $\mathcal W=[1.7424,5.6169]$ | Checked; same window in the interval theorem, all four tests and final count. |
| Shifts | $\gamma=1$ for spectral inclusion; $\sigma=1$ for core energy | Checked; equal numerical values with different roles. |
| (P) | Periodic band exclusion plus half-lead Dirichlet spectral exclusion throughout $\mathcal W$ | Supplied by A+B, independently of (H). |
| First-order existence | The exact first-order formula has a safe outer interval $[2.4286785150,2.4287788272]$ | Strictly inside the window; **O1** repairs its displayed numerical specialization. |
| Upper count | $n(t_{\alpha_+})\le n(L)\le1$ from the all-trace DtN lower bound and shifted inertia | Checked. Together with existence, this forces one simple eigenvalue in $[\alpha_-,\alpha_+)$. |
| Final use of (H) | The proved half-open isolation is stronger than the open-window isolation used in the four-corner theorem | Checked. No circular use of (H) to obtain the existence input. |

The key band argument has the required strength: on a nonpositive subspace of the full fiber form, projection onto the retained plane waves is injective, and its image is nonpositive for $T^-$. Therefore its dimension is bounded by $n(T^-)+z(T^-)$, including threshold eigenvalues. The upper-panel test consequently excludes an eigenvalue exactly at its threshold. This step is checked.

The surface argument also supplies the required strength: $\mathsf B_{\alpha_-}\succ0$ and monotonicity exclude half-lead spectrum all the way to $2.375^2$, which is still strictly inside the certified periodic gap. Thus the half-lead distance used in $K_+$ is established throughout the required side of the gap. Checking only two pole-free endpoints would not suffice, but that is not the argument used.

## 3. Objections

### O1. The two displayed decimal intervals are narrower than the intervals deduced from the printed inputs

**Form:** Failed step.  
**Severity:** blocker, limited to the literal displayed interval guarantees.

**Locations:**

- paper.tex, §4.7 “结果”, equation eq:main-interval, lines 450–453; lecture-notes.tex, §6.6 “结果”, the same label, lines 889–892.
- paper.tex, §3.4 “不用 (H) 的一阶区间”, numerical specialization of prop:first-order, lines 298–302; lecture-notes.tex, §4.5, lines 558–562.
- Repeated interval displays in the abstract, notes §1.2, and the results tables inherit the same issue.

**Quote:** “$\lambda_*\in[2.4287286691978,\ 2.4287286736601]$”.

With every printed input treated as an exact real number, the four-corner theorem yields

$$
L=2.428728669197791295335138745732\ldots,\qquad
U=2.428728673660123031064584074101\ldots.
$$

The displayed lower endpoint is greater than $L$ by $8.704664861254\ldots\times10^{-15}$, and the displayed upper endpoint is less than $U$ by $2.303106458407\ldots\times10^{-14}$. The proved inclusion $[L,U]$ therefore does not imply the narrower displayed inclusion. No stronger guaranteed bound is supplied to justify these inward replacements.

The first-order display has the same problem. At the single admissible corner $(E_+,M_-)$ its stated formula already gives

$$
[2.428678515083936305428410739\ldots,\;
  2.428778827106708243893081228\ldots],
$$

which extends beyond both ends of the printed $[2.4286785151,2.4287788271]$. Section 4.2 below supplies an outer bound valid throughout the input rectangle.

This is the arithmetic implication expressly requested in review item 6. It does not question floating-point evaluation, numerical input certification, or the independently audited code. It also does not assert that the true eigenvalue lies outside the printed interval; it identifies the missing implication needed to guarantee that smaller interval.

**Smallest repair:** use

$$
[2.4287286691977,\;2.4287286736602]
\quad\text{and}\quad
[2.4286785150,\;2.4287788272]
$$

at the existing decimal precision, and update repeated displays consistently. The latter remains inside the isolation window, so existence and the subsequent proof of (H) survive.

### O2. The paper's panel implication omits $r_i<k_L$

**Form:** Missing hypothesis.  
**Severity:** minor.

**Location:** paper.tex, §5.2.2 “覆盖全部 Bloch 相位”, line 558 and the displayed test immediately following lem:lipschitz. The complete counterpart is lecture-notes.tex, §8.3, equations eq:panel-low and eq:panel-up.

**Quote:** “对面板 $[\theta_i-r_i,\theta_i+r_i]$ 与阈值 $k_L<k_U$”.

The negative direction at $(k_L-r_i)^2$ gives

$$
\sqrt{\lambda_1(\theta_i)}<|k_L-r_i|.
$$

The Lipschitz bound then gives at most $|k_L-r_i|+r_i$ on the panel. The asserted upper bound $k_L$ follows when $k_L>r_i$, which the notes explicitly require. It does not follow from $k_L<k_U$ alone.

The actual panels satisfy the omitted condition: their maximum radius is $\pi/8<1.318=k_L$. Thus the numerical band certificate is unaffected.

**Smallest repair:** state $0\le r_i<k_L<k_U$ in the paper's panel sentence.

### O3. The compressed general surface-count formula omits endpoint invertibility

**Form:** Missing hypothesis.  
**Severity:** minor.

**Location:** paper.tex, §5.3.1 “单层算子”, line 628, following cor:surface. The complete statement is lecture-notes.tex, §9.3 “端点计数”, thm:surface-count, lines 1369–1375.

**Quote:** “$n(\mathsf B_a)-n(\mathsf B_b)$ 等于 $(a,b)$ 中两侧 Dirichlet 特征值的总重数”.

The general formula is stated in the notes under invertibility of $\mathsf B_a$ and $\mathsf B_b$. Without excluding a kernel at $b$, it need not hold: a zero there can change the difference of strictly negative indices without being counted in $(a,b)$. The increasing scalar block $B_\lambda=\lambda-b$ has index difference one between $a<b$ and $b$, but no zero in $(a,b)$.

The notes state and use the correct assumptions. The main numerical proof uses positivity at the lower endpoint and monotonicity, so every endpoint in question is invertible; that proof is checked.

**Smallest repair:** add “if $\mathsf B_a$ and $\mathsf B_b$ are invertible” to the paper sentence, retaining its same-connected-gap premise.

### O4. The generalized pencil subtracts the mass matrix twice, and the stated equivalence is too strict

**Form:** Failed step.  
**Severity:** minor: an inconsistent matrix label and threshold statement; the independent inertia verification supplies the required conclusion.

**Locations:** paper.tex, §6.2.2 “芯区下界”, line 839 after eq:L-scalar, and §6.2.3 “结果”, line 867; lecture-notes.tex, §11.5 “结果”, paragraph “计数”, lines 1969–1973.

**Quote:** “矩阵束 $(\bm T_{\rm low}-\bm M^q,\bm M^q)$”.

The preceding definitions give

$$
L=T_{\rm low}-\delta_h M^q,\qquad
\delta_h=\frac{q_{\max}C_h^2}{1-q_{\max}C_h^2}.
$$

Consequently, for the ordered eigenvalues $\nu_j$ of $(T_{\rm low},M^q)$,

$$
n(L)\le1\quad\Longleftrightarrow\quad \nu_2\ge\delta_h.
$$

The printed pencil instead has eigenvalues $\mu_j=\nu_j-1$, so its threshold would be $\delta_h-1$. Moreover, strict $>$ is sufficient for a positive second eigenvalue, but is not equivalent to counting at most one strictly negative eigenvalue: a zero second eigenvalue is allowed.

The supplied numerical labels expose the extra subtraction. If $-0.807334$ were the lowest eigenvalue of the printed pencil, the smallest eigenvalue of the mass-normalized $L$ would be

$$
-0.807334+1-0.00232715=0.19033885>0.
$$

That would make $L$ positive definite, contrary to the separately given negative eigenvalue of $\widetilde L$ and the tiny two-sided norm perturbation. This is a consistency check between supplied numbers, not a reproduction of either eigensolve.

**Smallest repair:** remove the extra $-M^q$ from the pencil in both files. Use $\mu_2\ge\delta_h$ for an equivalence, or describe $\mu_2>\delta_h$ as sufficient. Retain the independent shifted $LDL^*$ argument, which already proves the needed count.

### O5. The first flux-matching relation uses an undefined transfer $G$

**Form:** Failed step.  
**Severity:** minor.

**Locations:** lecture-notes.tex, §10.6 “实际采用的构造”, paragraph “通量”, line 1742, under sec:dtnbound; paper.tex, §6.1.3 “单胞场与传递矩阵”, line 756, under sec:dtn. The adjacent tail lemma is lem:transfer-tail in both files.

**Quote:** “$N_0=N_bG$，重复胞远墙映射 $F_b=N_bP$”.

The preceding construction specifies the cell sequence $UP^nw$. The first repeated cell therefore has input $Pw$, and its near-wall moments are $N_bPw$. The first cell has far-wall moments $N_0w$. Their equality requires $N_0=N_bP$. No distinct initial map $G$ is defined.

The later relation $F_b=N_bP$ supplies matching between repeated cells but cannot identify the undefined first transfer. This does not invalidate the transfer-tail lemma.

**Smallest repair:** replace $G$ by $P$, or explicitly define $G:=P$, using one common oriented normal for the moment maps. If a distinct initial map is intended, its coefficient sequence must instead be specified. Since the matching relation is an imposed construction constraint, this is a local symbol repair rather than a new numerical estimate.

### O6. The physical core does not have the asserted two-sided quarter-width homogeneous collar

**Form:** Counterexample.  
**Severity:** minor.

**Locations:** paper.tex, §2.1 “几何、方程与谱”, line 124 after the inclusion parametrizations; lecture-notes.tex, §2.1 “几何与材料”, line 126 after the ports are defined. The paragraph is unlabelled.

**Quote:** “每个夹杂离最近端口的距离大于 $\tfrac14$”.

The printed central curve has

$$
c_*(0)=(0.36,0).
$$

Its distance to the right port $x=0.5$ is $0.14<0.25$. The central inclusion therefore enters the alleged core-side collar, where the density is 4 rather than 1.

The needed collars nevertheless exist: the lead radius bounds are approximately $0.22319793$ and $0.23763541$, leaving wall clearances greater than $0.25$. Notes §9 uses two sides of a cut in a pure periodic continuation; notes §10 uses the physical exterior side of each port. Neither uses the false core-side collar.

**Smallest repair:** restrict the physical collar assertion to the half-lead sides, and state the two-sided collar separately for either pure periodic lead.

### O7. Global isolation (H) is conflated with half-lead pole exclusion (P)

**Form:** Failed step.  
**Severity:** minor.

**Locations:** paper.tex, §2.1 after ass:H, line 151, and §2.2 after ass:P, line 162; lecture-notes.tex, §2.3 after ass:H, line 205, and §3.2, line 248.

**Quote:** “(H) 同时排除……下文所说表面态引起的问题”.

(H) describes $\sigma(A)$ for the joined operator. Surface states are eigenvalues of the independently cut Dirichlet half-lead operators. Global isolation alone neither excludes those half-lead eigenvalues nor guarantees a pole-free DtN map.

The related assertion that a surface-state value “is not” in $\sigma(A)$ is also too strong: it belongs to a different spectral problem, but numerical coincidence with a global eigenvalue is not forbidden.

The proof correctly establishes (P) separately through A+B and uses it for the reduced form. There is no circular dependence on the explanatory claim.

**Smallest repair:** attribute surface-state exclusion to (P), remove it from the explanation of (H), and replace the categorical nonmembership statement by “need not be a spectral point of $A$.”

### O8. Rayleigh error is signed, and the unconditional width interpretation fails for an interior eigenvalue

**Form:** Counterexample.  
**Severity:** minor: the exact interval and width formulas remain valid.

**Locations:** paper.tex, §4.1 “试探场与通量”, line 314; lecture-notes.tex, §5.1, remark “为什么不需要 DtN 的精确性”, line 588. Also paper §3.3, line 281, §1 contribution 1, §7.1 line 908 and §7.3 line 937; notes §4.4, eq:width-asym and the following keypoint, lines 523–533, and §12.1 line 2025.

**Quote:** “离散 DtN 误差、求根误差和截断误差都只让 $\theta-\lambda_*$ 变大”.

Take $A=\operatorname{diag}(0,2,4)$, target $\lambda_*=2$, isolation window $(1,3)$ and $\gamma=1$. For

$$
v=\sqrt{1-\varepsilon^2}\,e_2+\varepsilon e_1,
$$

the trial field moves away from the target eigenspace but $\theta-\lambda_*=-2\varepsilon^2<0$. An interior eigenvalue has no general one-sided Rayleigh monotonicity.

For

$$
v=\sqrt{1-2\eta}\,e_2+\sqrt\eta\,e_1+\sqrt\eta\,e_3,
\qquad 0<\eta\ll1,
$$

one has

$$
q=3,\qquad \theta-\lambda_*=0,\qquad
G=\frac13+\frac8{15}\eta,\qquad qG-1=\frac85\eta>0.
$$

The interval hypotheses hold for sufficiently small $\eta$, but $W(G)>0$. Thus its width cannot unconditionally be a fixed multiple of the signed Rayleigh error.

The exact identity involving $R$ is correct. The paper's “far from the window” paraphrase is broader than the notes' “far above the window”; contamination below the window does not imply $qR\ll\theta-\lambda_*$. Moreover, no supplied bound on $R$ or on the nonguaranteed BIE reference makes the entire approximate $4.7\%$ discrepancy attributable to $J-G$.

**Smallest repair:** retain the exact width identity and the conditional asymptotic under the stated smallness condition on $R$. Remove the one-sided deterioration claim and the unconditional fixed-multiple claim. Treat the $4.7\%$ comparison as a diagnostic without exclusive causal attribution.

### O9. Matching value traces does not make the gradient residual difference proportional to seam width

**Form:** Counterexample.  
**Severity:** minor.

**Locations:** lecture-notes.tex, §6.5 “界面单元上的残差”, remark at line 867; paper.tex, §4.6, line 431. These are explanatory remarks following the quantitative branch correction, not separately labelled equations.

**Quote:** “两个分支在原边界上相等，差别与缝宽成比例”.

The residual contains $p-\nabla v/s$. A conforming $P_3$ field has matching value traces but may have a normal-gradient jump. At a flat interface $x=0$, take the local branches $v_K=0$ and $v_{K'}=x$. They agree on the interface, but

$$
\nabla v_{K'}-\nabla v_K=(1,0).
$$

With identical flux branches, the gradient component of the residual difference has magnitude $1/s$ throughout an arbitrarily narrow seam. It is not proportional to seam width.

The formal correction using directly bounded $d_i\ge|\Delta R_i|$ and $\sum_i(2b_id_i+d_i^2)$ is correct. The reported residual bounds remain accepted inputs.

**Smallest repair:** restrict the proportionality claim to the value branches; say that gradient residual differences are bounded directly by the existing polynomial difference models.

### O10. The trigonometric model rule requires a real-valued polynomial model

**Form:** Missing hypothesis.  
**Severity:** minor.

**Locations:** lecture-notes.tex, §6.2 “积分的可靠界：多项式模型”, lem:model-arith, line 741 and its proof at line 750; paper.tex, §4.4 “多项式模型”, lem:model-arith, lines 377–384.

**Quote:** “若实值 $f$ 满足 $\mathcal N(P-a)\le\Delta$”.

The model definition $f=P+e$, $|e|\le\varepsilon$ does not require $P$ or $e$ to be real-valued. Real-valued $f$ alone is insufficient, and complex models occur elsewhere in the residual arithmetic.

Take

$$
f=0,\quad P=i,\quad e=-i,\quad
\varepsilon=\Delta=1,\quad a=0,\quad L=3.
$$

The written hypotheses hold, but the sine model is $P-P^3/6=7i/6$, with error $7/6>1+1/24=25/24$. The proof uses derivative and Lipschitz bounds equal to one on the real axis, which do not apply on a complex segment.

**Smallest repair:** require $P$ to be real-valued in the sine/cosine clause and retain the real Taylor center. This matches the real geometry/cutoff applications; complex product and square-last models remain admissible.

### O11. The blanket spectral-separation attribution does not describe all the cited lower-bound methods

**Form:** Wrong citation.  
**Severity:** minor.

**Location:** paper.tex, §1 “相关工作”, line 59, immediately after the references CancesDussonMadayStammVohralik2020, CarstensenGedicke2014 and Liu2026Spectral. The paragraph has no theorem/equation label.

**Quote:** “这些方法都要求谱在所关心区间之外分离”.

The cluster estimates of Cancès et al. do assume separation of the target cluster; their Assumptions 2.1 and 4.2 state the relevant conditions. That does not justify a universal requirement for the other cited lower-bound constructions.

For example, [Carstensen–Gedicke, Theorem 3.2, p. 2609](https://www2.mathematik.hu-berlin.de/~ccafm/cc_homepage/download/2014-CC_JG-Guaranteed_lower_bounds_for_eigenvalues.pdf) gives

$$
\frac{\lambda_{\mathrm{CR},1}}
 {1+\kappa^2H^2\lambda_{\mathrm{CR},1}}\le\lambda_1
$$

without an a priori continuous neighboring-eigenvalue bound or an imposed isolation window. The algebraic eigensolve identification in their separate Theorem 3.1 is a different condition. [Liu's primary abstract](https://arxiv.org/abs/2607.04247) likewise explicitly distinguishes the projection framework from methods requiring neighboring-eigenvalue information.

**Smallest repair:** restrict the separation statement to the enclosure/cluster estimates that actually use it, and leave the projection/nonconforming lower-bound claims under their own stated hypotheses. No change to this paper's proof or method is required.



## 4. Arithmetic checks

The following calculations combine printed inputs only. Where a scalar is displayed to a few significant digits, its unshortened consequence is shown and the actual inequality is checked. Literal containment endpoints are treated separately in O1. Numerical matrices, residual certificates and integration remainders are not reproduced.

### 4.1 Four-corner inputs, signs and extrema

The following printed inputs are used unchanged:

$$E_-=11.470912271614043,\quad E_+=11.470912271618044,$$

$$M_-=4.7230110180143914,\quad M_+=4.7230110180281955,$$

$$S_+=2.9475799\times10^{-10},\quad s=3.4287286707248672,$$

$$t_-=2.7424,\quad t_+=6.6169.$$

At a corner, $q=1+e/m$, $J_+=S_+/m+2/s-q/s^2$, $\delta=qJ_+-1$. Write $f_+=N_{t_+}/D_{t_+}-1$ and $f_-=N_{t_-}/D_{t_-}-1$ for the lower and upper endpoint functions. All digits below are for displaying arithmetic results; the sign comparisons have large margins.

| Corner | $q$ | $\delta$ | $J_+$ |
|---|---:|---:|---:|
| $(E_-,M_-)$ | 3.42872867072762992106323 | $2.13983233870144964438\times10^{-10}$ | 0.291653290839653279674258 |
| $(E_-,M_+)$ | 3.42872867072053139571242 | $2.13983233869075587479\times10^{-10}$ | 0.291653290840257091896345 |
| $(E_+,M_-)$ | 3.42872867072847705014777 | $2.13983233870197373649\times10^{-10}$ | 0.291653290839581221483323 |
| $(E_+,M_+)$ | 3.42872867072137852479697 | $2.13983233869129019703\times10^{-10}$ | 0.291653290840185033705410 |

| Corner | $t_-J_+$ | $t_+J_+$ | $D_{t_-}$ | $D_{t_+}$ |
|---|---:|---:|---:|---:|
| $(E_-,M_-)$ | 0.79982998479866515418 | 1.92984066015690178628 | 0.945405187272012691878 | −4.39164768291882245420 |
| $(E_-,M_+)$ | 0.79982998480032104882 | 1.92984066016089715137 | 0.945405187266955050166 | −4.39164768295052822101 |
| $(E_+,M_-)$ | 0.79982998479846754180 | 1.92984066015642498443 | 0.945405187272946017340 | −4.39164768291657051384 |
| $(E_+,M_+)$ | 0.79982998480012343643 | 1.92984066016042034953 | 0.945405187267888375627 | −4.39164768294827628065 |

Thus all four lower denominators are positive, all four upper denominators are negative, and

$$q_{\max}=3.428728670728477050147774649\ldots<3.4287286707285<6.6169.$$

All three printed sign/admissibility checks hold. The normalized denominator factors are $1-t_-J_+\approx0.2001700152>0$ and $1-t_+J_+\approx-0.9298406602<0$ at every corner.

| Corner | $f_+$: lower endpoint | $f_-$: upper endpoint |
|---|---:|---:|
| $(E_-,M_-)$ | 2.428728669204889820671788136 | 2.428728673659275901982212374 |
| $(E_-,M_+)$ | **2.428728669197791295335138746** | 2.428728673652177376641011195 |
| $(E_+,M_-)$ | 2.428728669205736949755182218 | **2.428728673660123031064584074** |
| $(E_+,M_+)$ | 2.428728669198638424418523072 | 2.428728673653024505723394435 |

Consequently,

$$U-L=4.462331735729445328368253646\ldots\times10^{-9}.$$

The approximate printed width $4.462\times10^{-9}$ is consistent; the literal endpoint interval has Objection O1.

### 4.2 First-order existence enclosure

The exact first-order expression with the corner $q,\delta$ values gives:

| Corner | First-order lower endpoint | First-order upper endpoint |
|---|---:|---:|
| $(E_-,M_-)$ | 2.428678515083089194877783426 | 2.428778827105861096274251847 |
| $(E_-,M_+)$ | 2.428678515075990898689629133 | 2.428778827098762341755616161 |
| $(E_+,M_-)$ | 2.428678515083936305428410739 | 2.428778827106708243893081228 |
| $(E_+,M_+)$ | 2.428678515076838009120362472 | 2.428778827099609489494338071 |

No claim that this nonlinear expression obeys the four-corner theorem is needed. For a directly justified safe outer interval, use

$$q_{\min}=1+E_-/M_+,\quad q_{\max}=1+E_+/M_-,\quad \delta\le\delta_{\max}=q_{\max}S_+/M_-.$$

The lower root factor is positive and decreases with $\delta$, and the upper root factor increases with $\delta$. Using $q_{\min}$ with $\delta_{\max}$ on the lower side and $q_{\max}$ with $\delta_{\max}$ on the upper side yields

$$[2.42867851507599076709265786\ldots,\;2.42877882710670824402298798\ldots].$$

Therefore $[2.4286785150,2.4287788272]$ safely contains this interval. Its distances from $\alpha_-$ and $\alpha_+$ are respectively $0.6862785150$ and $3.1881211728$, both positive. The printed first-order width $1.003\times10^{-4}$ is a correct approximate width.


### 4.3 Band-gap certificate

| Deduction | Printed numbers / arithmetic | Result |
|---|---|---|
| Window endpoints | $1.32^2=1.7424$, $2.37^2=5.6169$ | Checked. |
| Certified gap endpoints | $1.318^2=1.737124$, $2.375^2=5.640625$ | Checked. |
| Lower distance | $1.7424-1.737124=0.005276$ | Positive; checked. |
| Upper distance | $5.640625-5.6169=0.023725$ | Positive; checked. |
| Plane-wave dimension | $(2\cdot6+1)^2=169$ | Checked. |
| Number of finite tests | $2\text{ materials}\times118\text{ panels}\times2=472$ | Checked. |
| Required panel radius condition | $r_{\max}=\pi/8=0.3926990817\ldots<1.318$ | Checked for the actual panels; repairs O2 in the general statement. |
| Maximum upper threshold | $(2.375+\pi/8)^2=7.6601582068\ldots<7.66016$ | Checked. |
| Analytic curve bounds | With the printed worst-case $R_a\le0.2$, $a\le0.2$, $s=0.1$, the formulas give $C_{\rm im}\le0.03227511657\ldots<0.033$ and $C_1\le0.32828929358\ldots<0.33$ | Checked. |
| Analytic integrand majorant | $\frac{0.33}{2\pi}\exp(48\pi\cdot0.033)=7.6121303408\ldots<8$ | Checked. |
| Fourier-coefficient remainder | $32\pi/(\exp(204.8)-1)=1.144959057965\ldots\times10^{-87}<1.15\times10^{-87}$ | Checked. |
| Matrix correction | With $e_B=169\epsilon_b$, $\lambda<7.66016$, $c>1572.32$, the upper correction is below $2.372\times10^{-83}$ and the lower correction below $2.927\times10^{-83}$ | Both are below $3\times10^{-83}$; checked. Using the coarser $\epsilon_b<1.15\times10^{-87}$ also gives a bound below $3\times10^{-83}$. |
| Finite-test signs | Given negative margin $>1.3972\times10^{-4}$, positive margin $>7.5205\times10^{-3}$ and $c>1572.32$ | Strict signs survive the stated analytic corrections; checked. |
| Normalized inclusion area | $\pi R_a^2(1+a^2/2)=0.04\pi$ | Checked for both materials. |

The finite phase coverage and the given strict matrix margins supply the band certificate. No band eigenvalue or adaptive panel computation was rerun.

### 4.4 Surface and DtN deductions

| Deduction | Printed numbers / arithmetic | Result |
|---|---|---|
| Lower-endpoint surface margins | $\lambda_{\min}(C_-)=0.0235558$ and $0.00428913$ | Both positive; checked. These are already corrected Schur matrices. |
| Upper-endpoint checks | $\lambda_{\min}(C_-)=0.5004$ for each material | Positive; checked. |
| Residual enclosure norms in the surface table | $0.00789,0.00238,0.0142,0.00884$ and the listed tail terms | Accepted inputs already incorporated in $C_-$. Subtracting them again would be incorrect. |
| Half-lead exclusion above $\alpha_-$ | Upper end $5.640625$ minus $\alpha_+=5.6169$ | $d_+=0.023725$; checked. |
| Lower-side distance at $\alpha_+$ | $5.6169-1.7424$ | $d_-=3.8745$; checked. |
| Positive inverse multiplier | $K_+=1+6.6169/0.023725$ | $279.899894625922\ldots$; the printed $279.899894626$ is conservative and $K_+\le279.9$. |
| Negative inverse multiplier | $K_-=\max(0,6.6169/3.8745-1)$ | $0.70780745902697\ldots\le0.70782$; checked. |
| High-frequency coercivity | $A_H=0.9997073-K_+(1.09938\times10^{-9})$ | $0.999706992283654\ldots>0$; checked. |
| High-frequency Schur factor | $(1.09938\times10^{-9})/A_H$ | $1.09970222124\ldots\times10^{-9}$; checked. |
| Fine-grid residual penalty | $K_+(3.8954\times10^{-8})$ | $1.09032204953\ldots\times10^{-5}$, consistent with $1.0903\times10^{-5}$. |
| Budget comparison | Previous penalty versus $4\times10^{-4}$ | Strictly below budget by a factor $36.6864\ldots$; “about 37” checked. |
| Main two-sided width term | $(K_++K_-)3.8954\times10^{-8}$ | $1.0930792427\ldots\times10^{-5}$, consistent with the reported width scale $1.0931\times10^{-5}$. Separate matrix norm maxima need not occur in one direction. |
| Coarse-grid residual penalty | $K_+(8.63\times10^{-6})$ | $0.00241553609\ldots$, consistent with $2.4\times10^{-3}$. |
| Refinement ratio | $8.63\times10^{-6}/(3.8954\times10^{-8})$ | $221.543\ldots$; checked. |
| Retained trace count | $2M+1=33$ for $M=16$; $11+22=33$ | Checked. |
| Trace-correction parameter | $\tau=12N$, $N=48$ | $\tau=576$; checked. |
| Transfer contractions | $\eta_L\le6\times10^{-24}$, $\eta_R\le6.5\times10^{-16}$ | Both strictly below one. |
| Transfer-tail factors | $\eta^2/(1-\eta^2)$ | At most $3.6\times10^{-47}/(1-3.6\times10^{-47})$ and $4.225\times10^{-31}/(1-4.225\times10^{-31})$; checked. |
| Positive matrix minima | Given $Q$ minima $0.411018879,0.337890502$ and $\widehat\Lambda$ minima $0.411018856,0.337890454$ | All positive; checked. Their construction and scaling conventions agree across files. |
| Safe residual allowance | $2\times10^{-14}-4.5\times10^{-22}$ | Positive; checked as an arithmetic allowance only. |
| Planning residual norm | Exact threshold $\sqrt{(4\times10^{-4})/K_+}=0.0011954423\ldots$ | Consistent with the explicitly approximate $1.2\times10^{-3}$. Plugging $0.0012$ exactly gives $4.03056\times10^{-4}$; it is not the actual certificate input. |
| Rough residual example | $K_+(10^{-3})^2$ | $2.79899894626\ldots\times10^{-4}$, consistent with “about $3\times10^{-4}$”. |

The given whole-half-lead Gram majorant for $Z$ is in the safe direction. The integration amplification factors 2.02 and 2.75, the high-tail penalties $7.3\times10^{-10}$ and $1.1\times10^{-9}$, and the residual matrix norms are accepted numerical inputs; their use in the inequalities is checked.

### 4.5 Core count

| Deduction | Printed numbers / arithmetic | Result |
|---|---|---|
| Core mass coefficient maximum | $4(5.6169)+1$ | $q_{\max}=23.4676$; checked. |
| Base dimensions | $(15+1)(2\cdot8+1)$, $32\cdot33$, $48\cdot49$, $64\cdot65$ | $272,1056,2352,4160$; checked. |
| Port enrichment | $2(2\cdot16+1)=66$ | Main dimension $1056+66=1122$; comparison dimensions $338$ and $2418$ checked. |
| Port-block independence | Given minimum residual Gram eigenvalue $0.00496$ | Positive; checked. |
| Omitted-mode minimum | $1+(32\pi)^2+0.25=10107.7249067155\ldots$; the other displayed candidate $(34\pi-0.5)^2=11302.6985374\ldots$ is larger | The selected minimum is correct; $C_h\approx0.00994656885$. |
| $(15,8)$ amplification | With $C_h=0.0198895$, $q_{\max}C_h^2=0.0092835997532629$ | $\delta_h=0.00937059258427\ldots$; table checked. |
| $(31,16)$ amplification | With $C_h=0.00994657$, $q_{\max}C_h^2=0.00232174951712076724$ | $c_W=0.997678250482879\ldots>0$, $\delta_h=0.00232715258251\ldots$; table checked. |
| $(47,24)$ amplification | With $C_h=0.00663127$, $q_{\max}C_h^2=0.00103195818336841204$ | $\delta_h=0.00103302422117\ldots$, about $0.1\%$; checked. |
| $(63,32)$ amplification | With $C_h=0.00497352$, $q_{\max}C_h^2=0.00058049223477583104$ | $\delta_h=0.00058082940173\ldots$; checked. |
| Second generalized value | $0.499135-0.00232715$ | $0.49680785>0$, ratio $>214$; comparison checked, subject to the pencil correction O4. |
| Wrong-pencil contradiction | $-0.807334+1-0.00232715$ | $0.19033885>0$; confirms O4. |
| Mass error transport | $3(5.6169)(1.22\times10^{-10})/0.99767825$ | $2.06056952730\ldots\times10^{-9}$; the displayed $2.06\times10^{-9}$ is shortened. |
| Second-eigenvalue margin | $0.3653736907-2.06\times10^{-9}$ | $0.36537368864\ge0.365373688>0$; checked. Using the unshortened previous expression gives $0.365373688639430\ldots$, with the same conclusion. |
| Negative first eigenvalue | Given $-6.41713590$ and perturbation about $2.061\times10^{-9}$ | Remains negative under the two-sided norm estimate; checked. |
| Shifted inertia | Given $n(\widetilde L-\varepsilon I)=1$ and $n(\widetilde L-0.3653736907I)=1$ | Implies $n(L)\le1$ and the positive second-eigenvalue bound; checked independently of the generalized pencil. |
| Smaller-space comparison | Given dimension 338, second eigenvalue $0.360264$ and generalized-value change $8.3\times10^{-5}$ | Positive comparison value and a change small relative to the approximately $0.497$ margin; checked. |

The transported moment bound $1.22\times10^{-10}$ is itself a supplied numerical bound. The row error $2.35\times10^{-13}$ cannot by itself determine that transported bound without the numerical basis-transformation norm; no such independent reconstruction is attempted.

### 4.6 Other integration, enclosure and cost arithmetic

| Deduction | Calculation | Result |
|---|---|---|
| Endpoint sensitivity discussion | The displayed formulas give derivatives approximately $13.70035367$ and $-7.11616547$ | Consistent with “about $14,-7$”; checked. |
| Relative $E,M$ halfwidths | $1.74397637\times10^{-13}$ and $1.46136648\times10^{-12}$ | Both below $2\times10^{-12}$; checked. The $1\%$ budget discussion is approximate. |
| Main exact corner width | $U-L=4.462331735729\ldots\times10^{-9}$ | Consistent with $4.462\times10^{-9}$; endpoint membership has O1. |
| Enlargement over raw-integral width | $(4.462331735729\ldots/4.454-1)100$ | $0.1870618709\ldots\%$, consistent with $0.19\%$. |
| Frequency conversion | $\sqrt L=1.55843789391742887488\ldots$, $\sqrt U=1.55843789534909700587\ldots$ | Inside the printed $[1.5584378939,1.5584378954]$; checked. |
| Relative frequency width | Unshortened root interval gives $9.18655877\ldots\times10^{-10}$ | Consistent with $9.2\times10^{-10}$ as a statistic of that interval. The outward short-decimal frequency display has relative width about $9.6250\times10^{-10}$. |
| $C_W$ diagnostic | Substituting $\lambda_{\rm BIE}=2.428728670022710$ gives $6.07120630787866\ldots$ | $6.0712$ checked as a diagnostic, not a guaranteed substitution for $\lambda_*$. |
| Predicted width | $6.0712(7.022\times10^{-10})$ | $4.26319664\times10^{-9}$; checked. |
| Percentage excess | $(4.462/4.263-1)100$ | $4.6680741262\ldots\%$, consistent with $4.7\%$; exclusive attribution fails as in O8. |
| BIE location | Reference minus printed lower end $=8.24910\times10^{-10}$; printed upper end minus reference $=3.637390\times10^{-9}$ | Both positive; checked. |
| Rayleigh/reference diagnostic | The printed $E/M$ bounds give $q_{\min}-1-\lambda_{\rm BIE}=6.9782139571242\ldots\times10^{-10}$ and $q_{\max}-1-\lambda_{\rm BIE}=7.0576705014777\ldots\times10^{-10}$ | The reported approximate $7.022\times10^{-10}$ is consistent with these bounds. The shortened Rayleigh value alone does not recover its extra digits. |
| Mass-correction budget | $6.80\times10^{-12}<10^{-11}$; ratio to $3.0175\times10^{-8}$ | $2.25352113\times10^{-4}$; checked. |
| Geometric admissibility | $0.0077<1$; $(1-0.0077)^2$ | $0.98465929>0$; checked. |
| Reciprocal model contraction | $0.0755<1$ | Checked. |
| Support/cell count | $1+13+13=27$ and $13.5-(-13.5)=27$ | Checked. |
| Component residual bounds | $2.5978065\times10^{-10}+3.4977344\times10^{-11}=2.94757994\times10^{-10}$ | This sum exceeds the separately given $S_+=2.9475799\times10^{-10}$ by $4\times10^{-18}$. No objection: the total bound is independently given and need not equal the sum of coarser component displays. |
| Main runtimes | $718/60=11.9667\ldots$ minutes; $670/60=11.1667\ldots$ minutes | Approximately 12 versus 11 minutes; checked. |
| Interface times | $161+119+181=461$ seconds | Consistent with “about 460”. |
| Additional (H) work | $4\cdot450=1800$ seconds; $2\cdot700=1400$ seconds | 30 minutes for four surface runs and 23 minutes 20 seconds for two DtN runs; checked. |
| Core time | Each run is 13–18 seconds; three such runs take 39–54 seconds | Per-run wording is consistent. No combined total is falsely identified as 12 minutes. |

### 4.7 Cross-file consistency

The duplicated geometry, material assignments, $\beta$, window, band endpoints, $s$, $E_\pm$, $M_\pm$, $S_+$, surface table, DtN table, $K_+$, $r$, core dimensions, $C_h$, $c_W$, $\delta_h$, inertia threshold, final positive margin and runtimes agree at the displayed precision. Short forms such as $-0.80733$ versus $-0.807334$, or $0.36537369$ versus $0.365373691$, are decimal presentation differences.

The substantive inconsistencies are the shared wrongly identified pencil (O4) and the arithmetic derivation of the literal enclosure endpoints (O1). The supplied first-order outer interval and the main four-corner calculation use the same window and shift as the proof of (H).



## 5. Citation audit

Verdicts concern the claim actually attributed in the draft. A background-method citation does not import every theorem from that source into the current proof. Exact source hypotheses are recorded to distinguish those uses. For sources available only in part, the inspected portion and the unverified portion are stated explicitly.

The notes contain self-contained proofs rather than additional citation commands. Thus the occurrence locations below are in paper.tex unless otherwise indicated.

| Citation | Where used | Verdict | Inspected primary-source location and scope |
|---|---|---|---|
| **AljawiMarletta2023** | §1, line 61: numerical approximation of gap eigenvalues | **correct** | [Accepted author manuscript](https://orca.cardiff.ac.uk/id/eprint/158306/1/SAljawifinal.pdf), abstract and §1. It treats self-adjoint elliptic waveguide problems, domain truncation with a dissipative perturbation, and DtN error estimates. This supports the stated background claim; the draft does not apply its theorem to the present certificate. |
| **BehnkeMertinsPlumWieners2000** | §1, line 61: acoustic-waveguide inclusion by domain decomposition and Dirichlet/Neumann comparison | **correct** | [Author-deposited full text](https://www.researchgate.net/publication/2484711_Eigenvalue_Inclusions_Via_Domain_Decomposition), §3.2 and §4.1 “Application to an acoustic waveguide”, Lemma 4.1 and Table 1, preprint pp. 8–10. The example is an infinite Neumann strip with a compact symmetric obstacle and symmetry reduction. The background claim does not identify that geometry with this paper's periodic leads. [Official bibliographic record](https://publikationen.bibliothek.kit.edu/1000043111). |
| **BoultonLevitin2007** | §1, line 61: numerical approximation of eigenvalues in gaps | **correct** | [Authors' institutional publication record and abstract](https://researchportal.hw.ac.uk/en/publications/on-approximation-of-the-eigenvalues-of-perturbed-periodic-schr%C3%B6di/). It states the periodic Schrödinger setting with a rapidly decaying perturbation and quadratic projection free from spectral pollution. The draft makes only this broad descriptive attribution. The full paper's individual theorems are not used or asserted verified here. |
| **BrownHoangPlumWood2009** | §1, line 61; §3.4, line 298: $H^{-1}$ residual and Weinstein-type enclosure for line-defect spectrum | **not verified** for the complete attribution | [Publisher preview](https://page-one.springer.com/pdf/preview/10.1007/978-3-7643-8773-0_3), printed pp. 23–24: abstract, end of introduction, §2 equations (1)–(4), start of §3. The preview verifies the $H^{-1}$ framework and enclosing intervals for a divergence-form photonic operator with a strip defect. It ends before the Weinstein theorem/application. The [chapter page](https://link.springer.com/chapter/10.1007/978-3-7643-8773-0_3) and [author repository](https://orca.cardiff.ac.uk/id/eprint/46308/) did not supply the full theorem text. No wrong-citation finding is inferred. |
| **BrownHoangPlumWood2015** | §1, line 61: existence of weak-defect guided modes | **correct** | [Accepted author manuscript](https://orca.cardiff.ac.uk/id/eprint/72386/1/BROWN-%20waveguidePRSLstyleRevised.pdf): Assumptions 2.1–2.2, pp. 3–4; Assumption 4.1, p. 8; Theorem 4.1 and (4.4), p. 10; Theorem 4.2, p. 13. The fixed-phase existence result uses a positive bounded periodic background and a nontrivial nonnegative strip defect satisfying the stated smallness condition. The draft cites existence as related work and does not apply that theorem to its unlike-lead configuration. |
| **CancesDussonMadayStammVohralik2020** | §1, line 59: equilibrated-flux estimates for multiplicities and clusters; separation requirement for this cluster method | **correct** | [Author preprint](https://arxiv.org/pdf/2008.04140), §2.1: bounded-below self-adjoint operator with compact resolvent; Assumption 2.1, §2.2: isolated target cluster; Assumption 4.2: continuous/discrete gap bounds; §5.1, Definition 5.1, Theorems 5.3 and 5.6: equilibrated flux and guaranteed cluster estimates. These conditions justify the statement for this reference, but not the universal extension to all adjacent references in O11. |
| **CarstensenGedicke2014** | §1, line 59: nonconforming guaranteed lower bounds | **correct** | [Author-hosted article](https://www2.mathematik.hu-berlin.de/~ccafm/cc_homepage/download/2014-CC_JG-Guaranteed_lower_bounds_for_eigenvalues.pdf), §2 and Theorem 3.2, p. 2609. The exact-solve lower bound uses a bounded polygonal Lipschitz domain, Crouzeix–Raviart discretization and the explicit interpolation constant. |
| **CarstensenGedicke2014** | Same paragraph's universal separation statement | **wrong**, O11 | Theorem 3.2 has no imposed continuous neighboring-eigenvalue separation. Theorem 3.1 separately identifies an inexact algebraic eigenpair; that is not the claimed general continuous-window requirement. |
| **Coatleven2012** | §1, line 61: DtN theory for a line defect | **correct** | Supplied primary PDF 04-Coatleven2012.pdf; [DOI](https://doi.org/10.1016/j.jcp.2011.10.022). Introduction p. 1677; §2, equation (1), Theorem 2.1; §4.2, pp. 1681–1684, Theorems 4.3–4.4 and equations (15)–(16). The source permits distinct periodic materials and transverse Floquet quasiperiodicity; its proved well-posedness estimates use positive absorption. Remark 5.5 qualifies the zero-absorption case. Correct as background; no absorbing theorem is imported as an unconditional lossless theorem. |
| **Fliss2013** | §1, lines 55 and 61: DtN guided modes; §2.1, line 137: essential spectrum, jointly with Reed–Simon | **correct**, with the stated scope | Supplied primary PDF 12-Fliss2013.pdf; [author preprint](https://arxiv.org/abs/1202.4928v2), [DOI](https://doi.org/10.1137/12086697X). Remark 2.1(2), p. 4, allows unlike periodic media with the same transverse period. Proposition 3.1, p. 7, states the essential-spectrum result for the common-background presentation; the two-background union follows by the standard two-end decoupling argument. Theorem 4.1, pp. 10–11, excludes half-Dirichlet exceptional frequencies; Theorem 4.5, p. 13, gives reduction under that solvability condition; Theorem 4.12 supplies the stable Riccati solution. |
| **FlissJolyLescarret2021** | §1, lines 55 and 61: DtN theory for periodic outlets | **correct** | [Full author manuscript uploaded by coauthor Vincent Lescarret](https://www.researchgate.net/publication/358564223_A_Dirichlet-to-Neumann_approach_to_the_mathematical_and_numerical_analysis_in_waveguides_with_periodic_outlets_at_infinity), January 19, 2021 version: §§2.1–2.2, equation (2), Remark 2.2; §3.2, Lemmas 3.6–3.7 and Theorem 3.8; §4. It treats different periodic outlets and uniformly elliptic coefficients. Theorem 3.8 uses Assumption A and excludes threshold/resonant frequencies. The generic method attribution is correct; it is not an all-frequency existence theorem. [Published DOI](https://doi.org/10.2140/paa.2021.3.487). |
| **HoangPlumWieners2009** | §1, line 61; §5.2, line 516: computer-assisted photonic gaps from finite parameter tests and perturbation coverage | **correct** | [Author preprint 08/05](https://publikationen.bibliothek.kit.edu/1000007941/246229), abstract; §§3–5, especially Theorem 7, printed p. 10; §6.2. It encloses fiber eigenvalues on a finite phase grid, then covers the Brillouin zone by perturbation bounds. Its weighted operator is $-\varepsilon^{-1}\Delta$ with positive bounded periodic permittivity. The attribution matches; the present complement construction is proved separately. |
| **JolyLiFliss2006** | §1, lines 55 and 61; §2.2, line 201: exact-boundary/DtN construction and discrete cell propagation | **correct** | Supplied primary PDF 05-Joly2006.pdf; [DOI](https://doi.org/10.4208/cicp.2006.v1.p945). §2, pp. 947–948; Theorem 3.1, p. 949; Theorem 4.1 and (4.5), p. 953; §5.1, p. 955; §7.1, p. 963. Positive absorption supplies well-posedness and stable propagation; distinct left/right periodic guides are allowed. Cell DtN operators satisfy a Riccati relation and are discretized by finite elements. Ordered QZ is the current draft's implementation choice. |
| **KlindworthSchmidtFliss2014** | §1, line 55; §2.2, line 201: FEM–DtN candidate computation | **correct** | [Publisher full-text extracts](https://doi.org/10.1016/j.camwa.2013.03.005), retrieved through its search-indexed article text: §3.1, Theorem 3.1 and the solvability assumption; §3.2, Remarks 3.8–3.9; §5, equations (39)–(42). The source excludes essential/half-Dirichlet exceptional frequencies, assumes cell-problem solvability, and constructs Schur/Riccati and stable-subspace systems. Its coordinate names differ from the draft's. It supports the construction; it does not specifically prescribe ordered QZ. |
| **Liu2026Spectral** | §1, line 59: guaranteed spectral-Galerkin lower bounds | **correct** for the descriptive claim | [Primary arXiv abstract, arXiv:2607.04247](https://arxiv.org/abs/2607.04247), also reproduced on the [author's institutional profile](https://cv01.ufinity.jp/twcu/cvclients/researchers/xfliu?achievement_type=published_papers&lang=en). It describes extension of projection bounds to spectral Galerkin spaces, bounded nonnegative potentials, explicit projection constants and Neumann truncation. The full text was inaccessible; no numbered theorem or detailed hypothesis beyond the primary abstract is marked verified. |
| **Liu2026Spectral** | Same paragraph's universal separation statement | **wrong**, O11 | The primary abstract expressly contrasts the projection framework with neighboring-eigenvalue-dependent Kato/Weinstein–Temple bounds. This suffices to check the broad attribution made in the draft; no unseen full-text theorem is inferred. |
| **NakaoPlumWatanabe2019** | §1, line 59; §3.2, line 260: Goerisch complementary quantity and the precise $N=1$ sign-condition equivalence | **not verified** | [Official chapter 10, “Eigenvalue Bounds for Self-Adjoint Eigenvalue Problems”](https://link.springer.com/chapter/10.1007/978-981-13-7669-6_10), pp. 349–411, was identified, but only its abstract and references were accessible. The algebraic implication of the displayed sign inequality is checked independently; its asserted equivalence to the book's particular theorem is not verified. |
| **ReedSimon1978** | §2.1, line 137: Floquet/essential-spectrum background, jointly with Fliss2013 | **not verified** | Methods of Modern Mathematical Physics IV: Analysis of Operators, Academic Press, 1978. The book was identified, but the actual cited theorem text was not accessible. No theorem location is invented. The applicability of the standard two-end compact-perturbation argument is checked independently in §2.4. |
| **Temple1928** | §1, line 59; §3.2, line 260: Temple-type bound and the $J=G$ case | **correct** as a Temple-type attribution | [Original article scan](https://scispace.com/pdf/the-theory-of-rayleigh-s-principle-as-applied-to-continuous-2l19ezrbla.pdf), §7, pp. 289–291, and §8, equation (8.1), p. 292; the equation was visually checked. It gives the first characteristic-number inverse-moment bound using the next threshold; with the appropriate moment identification it gives the lower endpoint's form. The current two-sided gap theorem is independently proved and is not claimed to appear verbatim in the 1928 setting. |
| **TrefethenWeideman2014** | §5.2.3, lem:trapezoid, line 569 | **correct** | [Author-hosted article](https://people.maths.ox.ac.uk/trefethen/publication/PDF/2014_149.pdf), Theorem 3.2 and equation (3.16), p. 396; Fourier/aliasing proof, p. 397. Its $2\pi$-periodic bounded analytic-strip hypothesis gives $4\pi\mathcal M/(\exp(sJ)-1)$. The draft assumes at least that much regularity and uses the same normalization and constant. |

For the historical or background citations above, “correct” means the inspected primary material supports the actual descriptive use. For Brown2009, Nakao2019 and Reed–Simon, the access limits prevent complete verification of the specific attributed material. Those limits do not replace or negate the independent proofs audited in the two supplied documents.

