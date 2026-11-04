# 论文全文证明审查请求（发给 ChatGPT Pro）

说明（中文，给用户）：本文件 `---` 线以下的英文部分是发给 ChatGPT Pro 的提示词，可整段复制。随提示词上传两个文件：`draft/fem-goerisch/paper.tex` 和 `draft/fem-goerisch/lecture-notes.tex`；如愿意，可再附同目录的 `paper.pdf`、`lecture-notes.pdf` 便于阅读。`preamble.tex` 和 `paper.bbl` 不用发：讲义用到的宏和论文的参考文献表已写进提示词。返回的 Markdown 请存为 `research/explorations/numerical-directions/paper-review-pro.md`，经理逐条核对。

---

# Proof review of a paper draft and its lecture notes

You are reviewing the mathematics of a paper draft on guaranteed eigenvalue enclosures for a guided mode in a two-dimensional periodic waveguide with a line defect. Your job is to find steps that fail. Do not rewrite the paper.

## Files

- `paper.tex`: the paper draft (Chinese, 7 sections). This is the object of the review.
- `lecture-notes.tex`: lecture notes (Chinese, 13 sections) with the full proofs. The paper is a compressed version of the notes.
- PDFs of both, if attached, are only for reading. Locate every objection in the `.tex` source.

The notes load a preamble that is not attached. It defines:

```latex
\newcommand{\ii}{\mathrm{i}}      \newcommand{\ee}{\mathrm{e}}
\newcommand{\dd}{\mathrm{d}}      \newcommand{\RR}{\mathbb R}
\newcommand{\CC}{\mathbb C}       \newcommand{\nut}{\widetilde\nu}
\newcommand{\cell}{\mathcal C}    \newcommand{\Tr}{\mathcal T}
% theorem-like environments (shared counter, numbered within section):
% theorem=定理, proposition=命题, lemma=引理, corollary=推论,
% assumption=假设, definition=定义, remark=注; example=例 (own counter).
% keypoint: a framed "要点" paragraph, no mathematical content beyond the text.
% Packages: amsmath, amssymb, amsthm, mathtools, bm, natbib, tikz, pgfplots.
```

## Relation between the two files

A step that is missing or abbreviated in the paper but proved in the notes is not a gap. Report it only if the paper's text, as written, states something false or misleading; then it is a minor objection. A step that neither file proves is a gap.

## What is given (do not check)

- All reported numbers (eigenvalue candidates, matrix eigenvalues, integration remainders, constants such as $K_+$, $r$, $C_h$, $\delta$, $\varepsilon$, timings) come from code that was reviewed separately. Take them as given.
- Floating-point rounding is excluded by stipulation everywhere. Do not object to it.

## What to review, in priority order

1. Band-gap certificate: notes Section 8 (单胞问题; 平面波空间与补空间的配方; Bloch 相位的 Lipschitz 模与面板检验; 夹杂 Fourier 系数的积分误差), paper Section 5.2. Check the Fourier/complement inertia argument, the panel test that uses $N_\le\le n+z$, the Lipschitz modulus in the Bloch phase, and the quadrature remainder for the inclusion Fourier coefficients (with the trapezoid lemma attributed to Trefethen–Weideman).
2. Steps that were rewritten for these documents and have not been reviewed in this form:
   - the interval theorem proved directly from the spectral measure, with conditions $q<t_+$ and $t_-J<1$ (notes Section 4, 区间定理; paper Section 3.2);
   - the four-corner theorem, which needs only $D_{t_-}>0$, $D_{t_+}<0$ and $q_{\max}<t_+$ (no separate positivity test of $H$) (notes Section 6, 四角定理; paper Section 4.3);
   - the signed sweep identity for the true-material mass correction and the bound derived from it (notes Section 6, 真材料质量：带符号的同伦恒等式, Lemma 带符号的扫掠恒等式; paper Section 4.5), and its use in the interface residual (notes Section 6, 界面单元上的残差);
   - the surface-state argument with "positive definite at the lower endpoint plus monotonicity" as the main line, and the endpoint count as the general case (notes Section 9, 结构与单调性 and 端点计数; paper Section 5.3);
   - the geometric-series tail lemma for the transfer matrix (notes Section 10, Lemma 几何级数的尾项; paper Section 6.1).
3. The chain that proves the isolation hypothesis (H): the counting theorem and the reduction to the upper endpoint (notes Section 7; paper Section 5.1), the final core count (notes Section 11; paper Section 6.2), and the summary of the chain (notes Section 11, (H) 的完整证明链). For each theorem, check that its hypotheses are exactly supplied by earlier results: the window $(\alpha_-,\alpha_+)$, the Bloch phase $\beta$, which material sits on which side, the orientation of each half-lead, the trace conventions, and the first-order interval $I_1$ lying inside the window. Check that the four-corner interval uses the same (H) that is proved.
4. The DtN reduction (notes Section 3; paper Section 2.2): the spectral equivalence between the operator on the infinite strip and the reduced form on the core cell, the role of hypothesis (P), and that no guaranteed statement relies on the accuracy of the discrete DtN (it should only produce the candidate).
5. Everything else that carries a proof: notes Sections 2, 5, the rest of 6, 9 and 10, and the list of standard facts (notes Section 13, 用到的标准事实). For each standard fact, check that it is stated correctly and that its hypotheses hold where it is used.
6. Arithmetic consistency: for every inequality that the documents conclude from the given numbers (for example $K_+r$ below its budget, $\mu_2>\delta$, the second eigenvalue lower bound, the band-gap and surface-state margins, the four-corner sign conditions, the interval endpoints from the corner values), recompute it from the numbers as printed and say whether it holds. Also check that the same quantity has the same value wherever it appears in the two files.
7. Citations: for each statement attributed to a reference, check that the source has that setting, those hypotheses, and that conclusion. If you cannot access the source, mark it "not verified"; do not guess. Reference list of the paper:
   - [AljawiMarletta2023] S. Aljawi, M. Marletta. On the eigenvalues of spectral gaps of elliptic PDEs on waveguides. Integral Equations Operator Theory 95:7, 2023. doi:10.1007/s00020-023-02727-6
   - [BehnkeMertinsPlumWieners2000] H. Behnke, U. Mertins, M. Plum, C. Wieners. Eigenvalue inclusions via domain decomposition. Proc. R. Soc. Lond. A 456:2717–2730, 2000. doi:10.1098/rspa.2000.0635
   - [BoultonLevitin2007] L. Boulton, M. Levitin. On approximation of the eigenvalues of perturbed periodic Schrödinger operators. J. Phys. A 40(31):9319–9329, 2007. doi:10.1088/1751-8113/40/31/010
   - [BrownHoangPlumWood2009] B. M. Brown, V. Hoang, M. Plum, I. G. Wood. On spectral bounds for photonic crystal waveguides. In Inequalities and Applications, ISNM 157, pp. 23–30, Birkhäuser, 2009. doi:10.1007/978-3-7643-8773-0_3
   - [BrownHoangPlumWood2015] B. M. Brown, V. Hoang, M. Plum, I. Wood. On the spectrum of waveguides in planar photonic bandgap structures. Proc. R. Soc. A 471(2176):20140673, 2015. doi:10.1098/rspa.2014.0673
   - [CancesDussonMadayStammVohralik2020] E. Cancès, G. Dusson, Y. Maday, B. Stamm, M. Vohralík. Guaranteed a posteriori bounds for eigenvalues and eigenvectors: multiplicities and clusters. Math. Comp. 89(326):2563–2611, 2020. doi:10.1090/mcom/3549
   - [CarstensenGedicke2014] C. Carstensen, J. Gedicke. Guaranteed lower bounds for eigenvalues. Math. Comp. 83(290):2605–2629, 2014. doi:10.1090/S0025-5718-2014-02833-0
   - [Coatleven2012] J. Coatléven. Helmholtz equation in periodic media with a line defect. J. Comput. Phys. 231(4):1675–1704, 2012. doi:10.1016/j.jcp.2011.10.022
   - [Fliss2013] S. Fliss. A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides. SIAM J. Sci. Comput. 35(2):B438–B461, 2013. doi:10.1137/12086697X
   - [FlissJolyLescarret2021] S. Fliss, P. Joly, V. Lescarret. A Dirichlet-to-Neumann approach to the mathematical and numerical analysis in waveguides with periodic outlets at infinity. Pure Appl. Anal. 3(3):487–526, 2021. doi:10.2140/paa.2021.3.487
   - [HoangPlumWieners2009] V. Hoang, M. Plum, C. Wieners. A computer-assisted proof for photonic band gaps. Z. Angew. Math. Phys. 60(6):1035–1052, 2009. doi:10.1007/s00033-008-8021-2
   - [JolyLiFliss2006] P. Joly, J.-R. Li, S. Fliss. Exact boundary conditions for periodic waveguides containing a local perturbation. Commun. Comput. Phys. 1(6):945–973, 2006. doi:10.4208/cicp.2006.v1.p945
   - [KlindworthSchmidtFliss2014] D. Klindworth, K. Schmidt, S. Fliss. Numerical realization of Dirichlet-to-Neumann transparent boundary conditions for photonic crystal wave-guides. Comput. Math. Appl. 67(4):918–943, 2014. doi:10.1016/j.camwa.2013.03.005
   - [Liu2026Spectral] X. Liu. Guaranteed lower eigenvalue bounds for spectral Galerkin methods with application to Schrödinger operators, 2026 (no venue given in the draft).
   - [NakaoPlumWatanabe2019] M. T. Nakao, M. Plum, Y. Watanabe. Numerical Verification Methods and Computer-Assisted Proofs for Partial Differential Equations. Springer Ser. Comput. Math. 53, Springer, 2019. doi:10.1007/978-981-13-7669-6
   - [ReedSimon1978] M. Reed, B. Simon. Methods of Modern Mathematical Physics IV: Analysis of Operators. Academic Press, 1978.
   - [Temple1928] G. Temple. The theory of Rayleigh's principle as applied to continuous systems. Proc. R. Soc. Lond. A 119(782):276–293, 1928. doi:10.1098/rspa.1928.0098
   - [TrefethenWeideman2014] L. N. Trefethen, J. A. C. Weideman. The exponentially convergent trapezoidal rule. SIAM Rev. 56(3):385–458, 2014. doi:10.1137/130932132

## Out of scope

Floating-point rounding; the code and the numerical reproduction of any number; writing style, language, and layout; novelty and comparison with other methods; suggestions for stronger or different results when the given proof is correct.

## Form of objections

Every objection must be one of four forms:

1. **Failed step**: a specific inference that does not follow. Say why.
2. **Counterexample**: a concrete case that satisfies the stated hypotheses and violates the conclusion.
3. **Missing hypothesis**: a condition the proof uses but does not state or establish. Say where it is used.
4. **Wrong citation**: the cited source does not contain the claimed result in the claimed setting.

Severity:

- **blocker**: the guaranteed conclusion (the interval, existence, or (H)) does not follow as written;
- **important**: the conclusion survives, but a proof or statement must change;
- **minor**: a local error that does not affect any conclusion (wrong constant in a non-binding place, a sign typo, an inconsistent symbol, a misleading compressed statement).

Do not write general advice such as "the argument should be made more rigorous". If a step is correct, say "checked" and move on. Do not hedge.

## Reply format

One Markdown file, in English, math in `$...$`:

1. **Summary**: counts of blocker / important / minor objections, and one sentence on whether the guaranteed conclusions follow.
2. **Coverage table**: one row per item 1–7 above and per subsection reviewed: file, section, verdict (checked / objection numbers / not reviewed, with the reason).
3. **Objections**, numbered. For each: location (file, section title, theorem or equation label, and a quote of at most one line), form, severity, explanation, and the smallest repair.
4. **Arithmetic checks** (item 6): each inequality, the numbers used, the result.
5. **Citations** (item 7): each citation, where it is used, verdict (correct / wrong / not verified), and the location in the source when verified.
