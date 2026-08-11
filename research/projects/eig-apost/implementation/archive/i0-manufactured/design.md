# Manufactured NEP implementation design

## Material Passport

- Origin Skill: `academic-research-suite/experiment-agent`
- Origin Mode: `plan`
- Origin Date: 2026-08-02
- Verification Status: `UNVERIFIED`
- Version Label: `eig-apost-manufactured-v1.2`
- Repro Lock: `null`
- Theory base: Git commit `ab0d4da75e68` plus the current uncommitted files listed below

The governing theory files are:

- `research/projects/eig-apost/phase4-report/method.tex`;
- `research/projects/eig-apost/phase3-analysis/s-root.md`;
- `research/projects/eig-apost/phase3-analysis/s-estimator.md`;
- `research/projects/eig-apost/phase3-analysis/p-implement.md`.

These files are the theory-to-code authority for this experiment. The experiment must not
change their mathematical claims.

## Scope and claim boundary

The first implementation validates only the finite-dimensional root-search and projected-
correction pipeline. It does not implement the augmented BIE, a half-guide DtN map, a
Rayleigh branch chart, a pole ledger, or the kernel--field equivalence proposed in the
theory draft.

A successful run may support the following statements:

1. the implemented contour count and bordered Newton recover the selected simple root of
   a fixed-dimensional analytic nonlinear eigenvalue problem;
2. the implemented root, map, and total corrections agree with their defining formulas;
3. the map correction predicts the matched next-level shift increasingly well and its
   coarse-tail effectivity tends to one in the manufactured hierarchy;
4. the specified negative cases are rejected by the intended gates.

A successful run must not be described as validating the physical BIE/DtN formulation or
as producing a certified error interval. The reported estimator remains
`conditional/empirical`.

## Manufactured hierarchy

Let

$$
  s=k-k_\star,
  \qquad
  \varepsilon_j=\theta^{2^j},
$$

and define

$$
  F_j(k)=
  \begin{bmatrix}
    s+c s^2+\varepsilon_j & \alpha\\
    0 & 1+q s
  \end{bmatrix},
  \qquad
  F_\infty(k)=F_j(k)\big|_{\varepsilon_j=0}.
$$

The frozen default parameters are

$$
  k_\star=2.3,
  \qquad
  \alpha=4+3\mathrm{i},
  \qquad
  c=0.2,
  \qquad
  q=0.1,
  \qquad
  \theta=0.25.
$$

All parameters except $\varepsilon_j$ are identical at every level. This fixed
representation is part of the estimator definition, not an implementation convenience.

The target root uses the analytic square-root branch that equals one at
$\varepsilon=0$:

$$
  s_j=\frac{-1+\sqrt{1-4c\varepsilon_j}}{2c},
  \qquad
  k_j=k_\star+s_j.
$$

The implementation must not reselect a root by proximity independently at each level.
Root levels are $j=0,\ldots,4$, whereas estimator rows are $j=0,\ldots,3$ so that every
row has a matched next-level root.

The other quadratic root and the root $s=-1/q$ are retained as exclusion checks. A target
root is simple only when

$$
  1-4c\varepsilon_j\ne0,
  \qquad
  1+q s_j\ne0,
  \qquad
  1+2c s_j\ne0.
$$

At the target root, analytic right and left null directions are

$$
  x_j^{\mathrm{ref}}=
  \begin{bmatrix}1\\0\end{bmatrix},
  \qquad
  y_j^{\mathrm{ref}}=
  \frac{1}{\sqrt{|1+q s_j|^2+|\alpha|^2}}
  \begin{bmatrix}
    \overline{1+q s_j}\\
    -\overline{\alpha}
  \end{bmatrix}.
$$

The SVD directions are compared with these directions by phase-invariant principal-angle
errors, in addition to left and right residuals. This check is necessary because, for this
triangular model, the left-vector factor cancels from the projected correction. Therefore
the experiment checks the SVD orientation and residual implementation but does not by
itself validate general left-vector sensitivity in a nonnormal NEP.

## Search and root qualification

The real scan over $[1.8,2.5]$ with 401 points only supplies a candidate. It never declares
an eigenvalue.

For each root level, the argument-principle moments are

$$
  m_0=\frac{1}{2\pi\mathrm{i}}
  \int_{\mathcal C}\operatorname{tr}\bigl(F_j(k)^{-1}F_j'(k)\bigr)\,\mathrm{d}k,
$$

$$
  m_1=\frac{1}{2\pi\mathrm{i}}
  \int_{\mathcal C}k\operatorname{tr}\bigl(F_j(k)^{-1}F_j'(k)\bigr)\,\mathrm{d}k.
$$

The common contour is the counter-clockwise circle centered at $k_\star$ with radius
$0.4$. Counts are evaluated with 128 and 256 trapezoidal nodes, and repeated at radius
$0.32$. The moment seed is $m_1/m_0$ only after the count-one gate passes.

Bordered Newton fixes $v_{\mathrm{bdr}}$ and $w_{\mathrm{bdr}}$ from the smallest left and
right singular vectors at the scan candidate. Each iteration solves

$$
  \begin{bmatrix}F_j(k)&v_{\mathrm{bdr}}\\w_{\mathrm{bdr}}^*&0\end{bmatrix}
  \begin{bmatrix}x(k)\\f(k)\end{bmatrix}
  =
  \begin{bmatrix}0\\1\end{bmatrix},
$$

then solves the same bordered system with right-hand side
$[-F_j'(k)x(k);0]$ to obtain $f'(k)$ and applies $k\leftarrow k-f(k)/f'(k)$.
The scan candidate, contour-moment seed, and a perturbed complex seed must converge to the
same root. The perturbed seed is exactly `scan_candidate + 0.05i`. Newton converges only
when both

$$
  |\Delta k|\le 10^{-12}\max(1,|k|)
  \qquad\hbox{and}\qquad
  |f(k)|\le10^{-12}
$$

hold; reaching 20 iterations without both conditions is a failure.

The gate order is fixed:

1. scan candidate;
2. contour isolation;
3. bordered root solve;
4. SVD and simple-root qualification;
5. projected corrections;
6. matched-root and effectivity validation.

If an upstream gate fails, all downstream estimator fields are marked `unavailable`.

## Estimator

Let $x_j,y_j$ be unit right and left singular vectors at the computed root and define

$$
  d_j=y_j^*F_j'(k_j)x_j.
$$

At a computed root $\widetilde k_j$, the three corrections are

$$
  \delta_j^{\mathrm{root}}
  =-
  \frac{y_j^*F_j(\widetilde k_j)x_j}{d_j},
$$

$$
  \delta_j^{\mathrm{map}}
  =-
  \frac{y_j^*\bigl(F_{j+1}-F_j\bigr)(\widetilde k_j)x_j}{d_j},
$$

$$
  \delta_j^{\mathrm{tot}}
  =\delta_j^{\mathrm{root}}+\delta_j^{\mathrm{map}}.
$$

The empirical estimator is $\eta_j=|\delta_j^{\mathrm{map}}|$. Validation uses

$$
  a_j=k_{j+1}-k_j,
  \qquad
  c_j=\frac{|\delta_j^{\mathrm{map}}-a_j|}{|a_j|},
  \qquad
  \mathcal I_j^{\mathrm{tail}}
  =\frac{\eta_j}{|k_j-k_\star|}.
$$

For the exact target branch,

$$
  \delta_j^{\mathrm{map}}
  =\frac{\varepsilon_j-\varepsilon_{j+1}}
  {\sqrt{1-4c\varepsilon_j}}>0,
$$

and $\mathcal I_j^{\mathrm{tail}}\to1$. The quadratic term makes the correction differ from
the exact next-level increment at finite $j$, so the decrease of $c_j$ is a genuine
linearization test. In this manufactured problem, total and tail errors coincide because
$k_\star$ is the exact limit root; this experiment does not validate software separation
of common discretization error from tail error.

Three independent correction-oracle checks are required. The computed map correction is
compared as a complex number with the displayed analytic formula,
$\delta_j^{\mathrm{tot}}$ is compared with
$\delta_j^{\mathrm{root}}+\delta_j^{\mathrm{map}}$, and it is independently recomputed as

$$
  -\frac{y_j^*F_{j+1}(\widetilde k_j)x_j}{d_j}.
$$

Each comparison uses the mixed tolerance
`1e-10 * max(1,abs(reference))`.

## Data structures

The entry point returns one `results` structure with four layers:

- `results.config`: frozen parameters, representation tag, paths, and thresholds;
- `results.roots`: raw scan, contour, Newton, SVD, oracle, and qualification data for
  levels $0{:}4$;
- `results.estimators`: derived corrections and validation data for levels $0{:}3$;
- `results.negative_cases`: expected and observed failure labels;
- `results.all_pass`: conjunction of the pre-registered gates.

Complex roots, vectors, slopes, and corrections are stored before any absolute value is
formed. Oracle data, raw diagnostics, derived estimators, and gate decisions remain
separate.

The common-representation metadata include `level_scale`, a two-entry row-scaling
fingerprint, and a two-entry column-scaling fingerprint. All three are level-independent in
the positive hierarchy. The scaling negative case supplies `level_scale = 2^j`; the same
metadata gate used by the positive path must reject it before correction evaluation.

## Failure cases

Four negative cases are mandatory.

1. `REAL_AXIS_DIP_ONLY`: $f(k)=k-k_0+\mathrm{i}\tau$ has no real root but has the complex
   root $k_0-\mathrm{i}\tau$. A contour centered at $k_0$ with radius below $\tau$ counts
   zero; a radius above $\tau$ counts one.
2. `LEVEL_SCALING_REJECTED`: $\widetilde F_j=2^jF_j$ preserves roots but doubles the
   projected map correction relative to the common representation.
3. `CONTOUR_COUNT_NOT_ONE`: a contour that misses the selected root must stop before
   Newton and estimator evaluation.
4. `ROOT_ERROR_DOMINATES`: a deterministic offset
   $\widetilde k_j=k_j+10^{-4}$ must make the root correction too large relative to
   $\eta_j$ and therefore reject a map-only interpretation.

These cases are gate tests, not extra samples that may be dropped after inspection.
The positive and negative paths reuse the same contour-count, common-representation,
bordered-Newton, correction, and root-dominance helpers wherever the mathematical object is
the same. The scaling case also solves the scaled root numerically before checking that its
root is unchanged.

## Implementation boundary

All experiment source and generated artifacts belong under `test/eig-apost-nep/`. No
existing package, draft, theory file, or code outside that experiment directory may be
changed by the experiment. The only research files created for this task are the four
documents under `research/projects/eig-apost/implementation/` requested by the user.
