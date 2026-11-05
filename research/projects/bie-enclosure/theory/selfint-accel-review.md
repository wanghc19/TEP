# Review of the self-interaction acceleration bounds

**0 blockers, 0 important caveats, 0 minor caveats.** A1–A3, B1–B3, C and D1–D3 establish their bounds under the stated analytic-domain and error-enclosure hypotheses.

This Review only pass covers the requested statements in `selfint-accel.md`. Line numbers below refer to that file unless another file is named. The manager's listed numerical substitutions were accepted without repeating them. Timing predictions and the implementation of the proposed algorithms are outside this verdict.

| Step | Verdict | One-line check |
|---|---|---|
| Object and normalization, (SI1)–(SI2), lines 15–43 | correct | The vector contains the density, source Jacobian, target weight and compensating $2\pi$ factor, so the normalized convolution bounds the specified weighted self-interaction. |
| A2, source Fourier bounds, lines 86–87 | correct | Moving the source contour within the certified strip gives $\|\widehat A_m(t)\|_2\le H_Ae^{-a\lvert m\rvert}$ and the corresponding bound for $B$, uniformly over the selected target set. |
| A2, log-sine Fourier coefficients, line 103 | correct | Expanding $\log(1-re^{iv})+\log(1-re^{-iv})$ and taking the integrable boundary limit gives $\lambda_0=0$ and $\lambda_m=-1/\lvert m\rvert$. |
| A2, exact interpolation convolution | correct | Integrating the trigonometric interpolant against $L$ multiplies each retained mode by $\lambda_m$, so every source mode $\lvert m\rvert<n$ is exact. |
| A2, complex-target alias bound $w_N$ | correct | An aliased nonzero frequency of magnitude $k$ contributes at most $e^{bk}/k$, while an alias to the constant mode contributes zero. |
| A2, symmetric Nyquist split | correct | A mode congruent to $n$ is represented by half of each of the modes $\pm n$, whose convolution magnitudes sum to at most $e^{bn}/n$. |
| A2, positive and negative source tails, lines 103–107 | correct | For each $\lvert m\rvert\ge n$, the exact and aliased convolution contributions are bounded separately, and the two signs give the factor $2H_A$. |
| A2, first term of (SI5) | correct | Replacing $1/m$ by $1/n$ in the exact-mode tail gives $e^{-(a-b)n}/[n(1-e^{-(a-b)})]$. |
| A2, periodic alias sum in (SI5) | correct | Writing $m=n+j+qN$ and using the $N$-periodicity of $w_N$ gives the finite sum and the factor $e^{-an}/(1-e^{-aN})$. |
| A2, smooth trapezoid term | correct | Only nonzero multiples of $N$ alias into the source mean, giving $2H_B/(e^{aN}-1)$ without a target exponential multiplier. |
| A2, comparison with implemented weights | correct | `self_interaction.py:110–118` gives $w_j=-2\sum_{m=1}^{n-1}\cos(m(t-s_j))/m-\cos(n(t-s_j))/n$, exactly the symmetric-Nyquist interpolation-convolution weights. |
| A2, implementation normalization | correct | `self_interaction.py:101–104,127–129` includes source speed and density, then $2\pi/N$ and the target weight, matching the $A,B$ convention in (SI1). |
| A2, (SI6), near part of the frequency tail | correct | For $n\le m<\lceil3n/2\rceil$, the alias magnitude is at least $n/2$, so the two multiplier bounds sum to at most $3e^{bm}/n$. |
| A2, (SI6), remaining frequency tail | correct | Since $n\ge1$ and every nonzero alias has magnitude at least one, the remainder is bounded by $2e^{bm}$ per positive mode, giving the displayed second geometric tail. |
| A3, ellipse hypothesis, lines 125–135 | correct | The strict semimajor-axis inequality places the closed Bernstein ellipse inside the disk carrying the certified bound $M_{\rm self}$. |
| A3, Laurent-to-Chebyshev coefficients | correct | The Joukowski substitution gives an inversion-symmetric analytic function on the annulus, and Cauchy's formula yields $\|a_k\|_2\le2M\rho^{-k}$ for $k\ge1$. |
| A3, exact-node interpolation remainder | correct | Each $T_k$ aliases to zero or a signed retained Chebyshev polynomial, so summing twice the coefficient tail gives $4M\rho^{1-L}/(\rho-1)$. |
| A3, discrete-cosine Parseval identity | correct | Orthogonality at the $L$ Chebyshev roots gives $\|d_0\|_2^2+\frac12\sum_{j=1}^{L-1}\|d_j\|_2^2=L^{-1}\sum_l\|e_l\|_2^2$ for complex vector data. |
| A3, node-error factor in (SI7) | correct | Weighted Cauchy–Schwarz gives $E\sqrt{1+2\sum_{j=1}^{L-1}\lvert T_j(x)\rvert^2}\le E\sqrt{2L-1}$ on the real interval. |
| A3, exact binary node-value midpoints, line 157 | correct | Each selected midpoint is fixed data, and the node ball encloses its difference from the exact quadrature value at the exact Chebyshev node. |
| A3, conversion error $e_{\rm conv}$ | correct | The finite cosine and power-basis conversions enclose the interpolant of those fixed data, and the normalized coefficient radii bound the resulting function error on $I$. |
| A3, full error accounting, (SI8) | correct | Quadrature and node-evaluation errors receive the node-error factor once, the exact-function interpolation tail is separate, and conversion contributes $e_{\rm conv}$. |
| A3, separate source and interpolation domains, lines 165–169 | correct | The source envelopes need only hold at all real interpolation nodes, whereas $M_{\rm self}$ must bound the exact function on the containing ellipse. |
| A3, small-disk recomputation | correct | A target disk of radius $h$ contains all real nodes, so new source-strip envelopes there may be used with the original larger target-disk bound for interpolation. |
| A3, panelwise acceptance, lines 519,531–535 | correct | Each panel retains its own domain, node and conversion certificates, and pointwise control checks supplement the continuous bound (SI8). |
| D2, separate self-interaction polynomial, (SI22) | correct | The self-interaction function error adds to the other part's coefficient error and Cauchy tail, with no requirement that the two polynomials have equal degrees. |
| D2, use of (RE12) | correct | After signed polynomial addition, the uniform error gives an $L^2$ loss of at most $\sqrt{\lvert I\rvert}e_I$, precisely the hypothesis used in the proof of (RE12). |
| D2, replacing the target-tail envelope | correct | Only $F_{\rm other}$ retains the Taylor-tail charge, so its envelope is $M_{\rm local}+M_{\rm proxy}$ when the self-interaction error is already covered by (SI8). |
| D2, combination and coefficient radii, line 479 | correct | Taking fixed self-interaction coefficients after charging their conversion error permits subsequent signed assembly, with the remaining assembly radii charged separately. |
| D1, cached source geometry | correct | `material.py:42–70` depends on the source arguments and arithmetic context, so the same enclosing source transform is valid for every target using those inputs. |
| D1, cached moments | correct | `panel.py:45–65` separates the moment basis from the source-center phase and density coefficients, matching the stated cache dependencies. |
| D1, reuse and error payment | correct | Reusing an enclosing ball preserves inclusion in every expression, while the existing moment error remains payable in each CM application. |
| D1, cache invalidation, line 456 | correct | The specified keys retain geometry, wave number, partition, order, precision and input identity, and changed densities or lead states require the corresponding moment transformation. |
| D3, common refinement | correct | Restricting either uniform approximation to an intersection interval preserves its error bound. |
| D3, affine basis conversion and (RE12) | correct | Polynomial restriction is an exact finite affine substitution, and its certified conversion error adds to the two approximation errors before applying (RE12). |
| D3, coarse-panel domain requirement | correct | A polynomial on a larger panel needs its own analytic-domain and remainder certificate, as explicitly required in line 487. |
| A1, shifted circular DFT and aliasing | correct | Removing the node-offset phase gives aliases $(-1)^m a_{j+mL}r^{j+mL}$, whose Cauchy bounds sum to the second term of (SI3). |
| A1, vector Parseval and sample errors | correct | The normalized DFT preserves the averaged squared vector norm, so the first $p+1$ coefficient errors contribute at most $G_{2,p}(h/r)E$. |
| A1, (SI3) and the separate target tail | correct | The sample-error and exact-sample alias terms compare with the exact Taylor truncation, after which the stated Cauchy tail bounds the full function. |
| B1, divided chords and logarithmic split, (SI9) | correct | $D_0=D_{\sin}\operatorname{sinc}((t-s)/2)$ and the positive real sinc on the near window give the displayed real-integral identity and compatible analytic factors. |
| B1, sinc envelope and (SI10) | correct | The entire sinc series gives $\lvert\operatorname{sinc}z-1\rvert\le\eta$, and for $\eta<1$ the logarithm series gives $\lvert\log\operatorname{sinc}z\rvert\le\eta/(1-\eta)$. |
| B1, window endpoints and analytic domains | correct | The window contains the real target interval, while the individual near-part analytic radius is constrained by its endpoints as stated. |
| B2, rectangular Taylor truncation, (SI11) | correct | Two-variable Cauchy bounds and the union of the two omitted index tails give $T$, with harmless double counting of the corner. |
| B2, logarithmic integral and (SI12) | correct | For $W+h<1$, the absolute logarithm integral has the displayed endpoint formula and is maximized at $x=0$ by concavity. |
| B2, ordinary moments and $J_j(0)$ | correct | Parity and integration of $u^j\log(u^2)$ give the stated zero and even-index values. |
| B2, logarithmic-moment identity, (SI13) | correct | The explicit endpoint primitive gives $J_j'=2x^j\log((W+x)/(W-x))-2\sum_{k=0}^{j-1}m_{j-1-k}x^k$, whose integrated series is (SI13). |
| B2, endpoint singularities, line 281 | correct | The individual endpoint logarithms can create branch points, so overlapping near pieces need their cancellations retained before claiming analyticity across those endpoints. |
| B3, uniform moment bound, (SI14) | correct | The constant, finite-polynomial and infinite-series parts of (SI13) are bounded respectively by the three terms in $W^{j+1}C_J$. |
| B3, envelope $M_{\rm near,*}$ | correct | Summing the target powers finitely and the source powers geometrically gives the factor $WG_{p_t}(R_m/R_t)/[2\pi(1-W/R_s)]$. |
| B3, second target truncation, (SI15) | correct | The integrated polynomial kernel is holomorphic for $\lvert x\rvert<W$, so its bound at $R_m$ supplies the stated Cauchy remainder on $\lvert x\rvert\le h$. |
| B, far-domain separation, (SI16) | correct | Positive periodic distance after subtracting both radii separates the product disks from every logarithmic diagonal and permits a fixed periodic representative. |
| B, far logarithm envelope $L_s$ | correct | The selected sine has positive real part, modulus between $2\sin(\delta_s/2)$ and $2\cosh((R_t+R_s^{\rm far})/2)$, and argument of magnitude below $\pi/2$. |
| B, CM specialization, (SI17) | correct | The smooth vector kernel $AL+B$ with constant density one has source mass $2h_s$, giving exactly the displayed CM truncation bound including $1/(2\pi)$. |
| B, target propagation and (SI17a) | correct | Source errors are holomorphic on the target disk and receive $G_{p_f}(h/R_t)$, while the exact far integral receives its own Cauchy tail. |
| B, window-edge subdivision, lines 365–366 | correct | The positive margin $W-R_t-0.0025$ keeps the allowed far-source radius positive at the nearest endpoint, so halving eventually attains the stated radius ratio. |
| B, density separation and kernel branches, lines 370–374 | correct | A CM formulation with separate density requires a bare-kernel bound, and the decomposed logarithm supplies the certified branch without assuming $\operatorname{Re}q>0$. |
| C, common translation, (SI19) | correct | The real-variable substitution uses source periodicity and evenness of $L$, and the resulting fixed-real-$v$ integral defines the same analytic continuation. |
| C, holomorphy and available source strip | correct | $\lvert u\rvert\le R$ and $\lvert\operatorname{Im}v\rvert\le\alpha$ imply $\lvert\operatorname{Im}(c+u+v)\rvert\le R+\alpha\le a$, allowing uniform integration of the analytic factors against integrable $L(v)$. |
| C, translated Kress rule | correct | For every complex $u$, A2 applies in the variable $v$ at target zero with strip width $\alpha$, so the quadrature weights are independent of $u$. |
| C, coefficient error and (SI20) | correct | Cauchy's formula for the analytic quadrature error gives $E_N^{\rm sharp}/R^j$, while the exact function retains its separate tail from $M_{\rm self},R_t$. |
| C, common derivatives | correct | Differentiating $A(c+u,c+u+v)$ and $B(c+u,c+u+v)$ gives $(\partial_t+\partial_s)^j$, including every density, Jacobian and target-weight factor. |
| C, absolute sum of weights, line 423 | correct | The normalized weight sum is at most $2\sum_{m=1}^{n-1}1/m+1/n\le2H_n^{\rm harm}$. |
| C, finite-factor errors and (SI21) | correct | Uniform analytic-factor errors contribute $2H_n^{\rm harm}\Delta_A+\Delta_B$ on the target disk, then the Cauchy coefficient factor and finite coefficient error apply. |
| C, Q3 and diagonal requirements, line 431 | correct | Uniform remainder bounds are required on the whole translated product domain, and the diagonal uses the analytic divided-difference limit. |
| Citation table, T3.2 and (Q2c)–(Q3) | correct | The weighted Müller split, period rescaling, even node count, symmetric Nyquist convention and Fourier-defined complex continuation match the cited hypotheses. |
| Citation table, Proposition G and (RE12) | correct | G supplies the absence of material wrap changes, and the new fixed polynomial with a uniform real-panel error supplies the hypothesis actually needed by (RE12). |
| Citation table, (RE15) and CM | correct | B uses separated analytic source disks and C uses a common translated domain, while A3 handles real-node errors through interpolation instead of Cauchy coefficient bounds. |
| Citation table, (RE28) | correct | The recurrence is used only for separated kernel coefficients, with an independent remainder certificate and no application at the self-interaction diagonal. |

## Source record

Inspected `selfint-accel.md`, `reliable-bound.md` T3.2 and (Q2c)–(Q3), `reliable-eval-design.md` (RE12), (RE15), CM and (RE28), and the preceding `reliable-eval-design-review.md`. The implementation comparison used `test/bie-bound/matrel-v1/self_interaction.py`, `panel.py`, `material.py`, and `research/projects/bie-enclosure/implementation/matrel-v1.md`. The new formulas were checked algebraically. No numerical experiments were run, and the manager's listed arithmetic checks were not repeated.

Review literature verification completed. All requested steps are reviewed. The proof and implementation files were not modified.
