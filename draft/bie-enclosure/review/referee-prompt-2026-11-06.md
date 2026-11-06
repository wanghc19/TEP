# 给 ChatGPT Pro 的审稿提示词（bie-enclosure 草稿，2026-11-06）

用法：
- 上传 `draft/bie-enclosure/main-clean.pdf`（对外版，43 页）。
- 最好再上传源文件压缩包，便于核对公式：`body.tex preamble.tex s-*.tex a-*.tex`。不要上传 `main.pdf`（工作版），里面的蓝字和灰字块是演变记录，会干扰审稿。
- 把下面分隔线以下的全文作为第一条消息发送。

---

You are an expert referee for a journal such as SIAM Journal on Numerical Analysis, SIAM Journal on Scientific Computing, or Mathematics of Computation. Review the attached manuscript to that standard. The manuscript is written in Chinese; the mathematics is standard. If LaTeX sources are attached, use them to check formulas exactly; the PDF is the version under review. All numbers below refer to the PDF.

## What the paper claims

Setting: a 2D strip $\mathbb R\times(-d/2,d/2)$ with piecewise-constant coefficient, quasi-periodic in $y$ with fixed Bloch phase $\beta$. Two semi-infinite periodic leads in $x$ (left and right may differ), each cell containing one simply connected dielectric inclusion, and a central defect cell (an inclusion or empty). The operator $A(\beta)$ is self-adjoint. A guided mode is an eigenvalue $\mu=k^2$ of $A(\beta)$ in a common gap of the two leads' essential spectra.

Claimed contributions (Section 1):
1. Center-cell reduction based on Cauchy data (Section 3, Prop. 3.2). A guided mode is equivalent to a nonzero center-cell solution whose Cauchy data on the two artificial interfaces lie in the decaying-solution subspaces of the half-leads. The reduction does not need unique solvability of the half-lead Dirichlet problem; DtN is a special case (Section 3.4).
2. BIE + port Rayleigh discretization (Section 4). Quasi-periodic layer potentials and transmission BIEs per cell, Thm. 4.2 (center-cell representation, proof in Appendix A, with Corollary A.1 near-image split), cell scattering matrices, decaying subspaces by ordered QZ, and a port-reduced matrix $\mathsf A(k)$ whose determinant is located by Chebyshev interpolation. This step only produces a candidate $\widehat k$; nothing about it is claimed to be rigorous.
3. Spectral-distance theorem (Section 5, Thm. 5.3, trace estimates in Prop. 5.2 and Appendix B). From the candidate, build an explicit piecewise field on the whole infinite strip. It solves Helmholtz exactly in each piece and has jumps only across material interfaces, artificial vertical interfaces and $y$-seams. Then $\operatorname{dist}(\widehat k^2,\sigma(A(\beta)))\le R$, with $R$ built from grouped weighted jump norms $\varepsilon_g$, trace constants $C_g$ and a field-norm lower bound $U$. The theorem is claimed for the whole spectrum, with no gap assumption.
4. Rounding-inclusive computation (Section 5.5–5.6, Appendix C). Panel-wise Chebyshev interpolation error bounds and ball arithmetic for the jump integrals; the infinite sum over lead cells is bounded by contraction of the propagation matrix; $U$ comes from disc masses; $C_g$ comes from piecewise checks of a collar geometry condition. Stored floating-point coefficients are treated as exact rationals. The final interval is claimed to be a reliable upper bound on the spectral distance (a guaranteed bound, rounding included).
5. Finite-dimensional criterion for a common spectral gap (Section 2.4, Lemma 2.4, Thm. 2.5, Prop. 2.6). Inertia tests on finitely many plane-wave matrices plus a Lipschitz bound of the band functions in the lead Floquet parameter $\theta$ prove that an interval avoids both leads' essential spectra at the fixed $\beta$. If the interval of item 3 lies in that gap, it contains at least one eigenvalue (Prop. 2.3).
6. Numerical example (Section 6). Star-shaped center inclusion, two different trefoil leads. One cold-start run of about 14 min gives a reliable wavenumber interval of full width $2.74\times10^{-11}$, about 1/163 of an FEM interval for the same problem.

Explicit non-claims: uniqueness of the eigenvalue in the interval, its index and its multiplicity; a priori convergence of the discretization. The FEM interval in Section 6 is used only for comparison, and its rounding is only estimated.

## What to check, in priority order

1. Correctness of the mathematics. Check each of the following line by line:
   - Prop. 3.2 (equivalence of the reduction, including the role of Lemma 3.1).
   - Thm. 4.2 and its proof in Appendix A: the Green identity with the quasi-periodic Green function on a cell with outgoing ports, the auxiliary exchanged transmission problem, and the uniqueness part.
   - Corollary A.1.
   - Prop. 5.1 (piecewise $H^2$).
   - Prop. 5.2 and Appendix B (grouped trace estimate: collars, Jacobians, overlap multiplicity, global $H^2$ Lemma B.1).
   - Thm. 5.3: is the constructed field in the right space on the infinite strip, are all interface types (material, artificial vertical, seams) accounted for, and are the constants correct?
   - Section 2.4: Lemma 2.4, Thm. 2.5, Prop. 2.6.
   - The final logic: interval meets $\sigma(A(\beta))$, interval inside common gap, therefore an eigenvalue.

   For each step, state whether you checked it in full, checked it partially, or only skimmed it.
2. Hypotheses. List every assumption each theorem uses. Say whether it is stated, whether the paper verifies it for the example, and how; flag any that is used but not stated. Examples:
   - no Wood anomaly ($\gamma_m\ne0$);
   - unique solvability of the exchanged transmission problem;
   - $C^2$ boundaries;
   - inclusions strictly inside cells;
   - collar / star-shape conditions;
   - contraction of the lead propagation matrices.
3. Reliability of the computed bound. Trace every input of the final interval: $\varepsilon_g$, $C_g$, $U$, the lead tail sum, the gap tests, the final assembly. Is each one a rigorous one-sided bound with rounding included? Flag every place where a floating-point quantity, a fitted coefficient, an interpolation, a truncated series or an "estimated" constant enters without an enclosure. Also check that the separation is clean: the uncertified search and fit may only influence the field, never the validity of the bound.
4. Novelty and positioning. Compare with:
   - Barnett–Hassell–Tacy (boundary-mismatch eigenvalue inclusion);
   - Fliss and Joly–Li–Fliss (DtN/half-guide reductions);
   - Barnett–Greengard and Cho–Barnett (quasi-periodic BIE);
   - classical eigenvalue inclusion and computer-assisted spectral bounds (Kato–Temple, Lehmann–Goerisch, Plum, Nakao and others).

   Is the contribution clear and sufficient for the venue? Is any closely related work missing? Do not invent references: give full bibliographic data for each suggestion and say when you are unsure that a paper exists or says what you attribute to it.
5. Numerical section. Does the example support the claims? Is the FEM comparison fair? What additional experiments would a referee require (e.g. a second geometry, a mode close to a band edge, the empty-center case, scaling with discretization)?
6. Presentation. Comment on the following:
   - structure and length, and which material could move to appendices or be cut;
   - notation consistency and conventions (e.g. $\theta$ versus $\beta$, scattering-matrix and amplitude conventions);
   - whether a reader can reproduce the computation from the text.

   Note language problems only where they obscure the mathematics.

## Output format

Write the report in Chinese. Structure:

1. 总体评价：两三句话概括论文做了什么、主要价值；建议（接收 / 小修 / 大修 / 拒稿）及理由。
2. 问题清单，按严重程度分三类，每类内按重要性排序：
   - `blocker`：使某个声称的结论不成立或无法验证；
   - `important caveat`：结论成立但需要额外条件、证明有缺口可以补上，或明显限制解释；
   - `minor caveat`：表述、记号、排版、可以推迟的问题。

   每条写明：位置（节号、定理号、式号、页码）；问题是什么；为什么重要；具体的修改建议（给出改正后的陈述、缺失的论证步骤或需要补的计算）。如果怀疑有错但不确定，写出你的推理和能判定的最小检查，不要把猜测写成结论。
3. 核对记录：逐条列出第 1 点中各结论你核对到什么程度（完整 / 部分 / 只浏览）。
4. 文献建议（如有），附完整书目信息与可信度说明。

Terminology: a numerically computed quantity is an "误差估计" or "谱距离估计"; a mathematically guaranteed bound is a "可靠上界". If a bound depends on an unverified condition, call it "在所列条件下成立的上界" and list the conditions. Do not use the terms "严格认证", "冻结" or "frozen".

Be direct. Do not soften real errors, and do not pad the report with generic praise or generic suggestions that do not apply to this manuscript.
