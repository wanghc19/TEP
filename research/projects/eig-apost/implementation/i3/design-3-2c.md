# I3.2 e-cap streamed-memory modularization design

## 0. Authority, status, and frozen identifiers

- **Authority:** this file is a prospective implementation contract for the next append-only
  I3.2 attempt. It does not revise the mathematical or numerical contract frozen in
  [[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]].
- **Historical evidence:**
  [[research/projects/eig-apost/implementation/i3/review-3-2b|review-3-2b]] records that
  `ecap-a2` completed the same-trial evaluation but stopped at the retained-memory gate before
  cap construction.
- **Researcher--Engineer contract:** `AGREED` on the compact-signature construction below.
- **Engineer state:** `FROZEN READY` after the static checks in section 14.
- **Skeptic design state:** `PENDING DESIGN REVIEW`; implementation and execution remain
  forbidden until `DESIGN PASS`.
- **New schema:** `TEP_I3_2_SAME_TRIAL_EVALUATION_CAP_REV_F`.
- **New and only future attempt tag:** `ecap-a3`.
- **New entry point:** `check_e_cap_stream.m`.
- **Frozen staged input:** the already staged `fbie-a1-certificate.mat`; it is read only through
  the explicit second function argument.
- **Claim class:** ordinary-double, same-certificate, empirically supported evaluation-cap
  candidate only. Every strict, reliable, gap, existence, independent-reference, and
  effectivity flag remains false.

This design changes only file ownership, transient-object lifetime, returned payloads, and
active-object accounting. It does not change the candidate, certificate, trial, densities,
wall data, Green kernel, branch, normal convention, levels, thresholds, action formulas,
lift formulas, majorant/cap formulas, full-$P$ powers, or fail-open scientific semantics.

## 1. Exact scope and append-only boundary

The consumed attempts `ecap-a1` and `ecap-a2` must never be rerun. Their design, amendments,
review, MATLAB sources, input, and output remain byte-for-byte historical objects. In
particular, the new entry point must not call the old monolithic files

```text
check_e_cap.m
i32_same_eval.m
i32_cap_tail.m
```

as a fallback or compatibility path. The refactor is implemented only in new function files.
The formal runtime may load the explicit staged MAT input, but it may not read, parse, hash, or
condition execution on historical output, Markdown, Git metadata, manifests, or repository
layout.

The scientific freeze is:

- circle levels $N_\theta=512,1024,2048$;
- symmetric image levels $J=32,48,64,96,128,192,256$;
- wall output levels $N_y=1024,2048,4096$ with the source density fixed at 512 orders;
- Riccati levels $512,1024,2048$;
- lift Gauss levels $32,64,128$;
- full-$P$ levels $8,16,32$;
- image contraction/remainder constants $0.80$ and $5$;
- all other spectral contraction/remainder constants $0.50$ and $2$;
- identity/Bloch threshold $10^{-10}$ and analytic-kernel threshold $10^{-8}$;
- width target $10^{-6}$;
- preflight memory gate 520 MiB, hard memory gate 640 MiB, soft time 1500 s, and hard time
  1800 s.

$M=48$ continues to mean only the artificial-wall trace order, giving $K=2M+1=97$ staged
wall-state coordinates. It is not an interior Rayleigh cutoff and is not a circle angular
cutoff.

## 2. Thin entry and file ownership

The only permitted call graph is

```text
check_e_cap_stream
  -> i32_certificate_input
  -> i32_lifting_quadrature
  -> i32_wall_module
  -> i32_circle_module
  -> i32_fullp_cap
  -> i32_result_output
```

The entry point owns only dispatch, stage ordering, resource gates, merge-on-return state,
failure precedence, and output publication. It contains no Green kernel, Bessel/Hankel,
Riccati, Gauss, wall/circle action, full-$P$, cap, or estimator formula.

| New function file | Sole responsibility | Explicitly forbidden responsibility |
|---|---|---|
| `check_e_cap_stream.m` | attempt/output guards, module dispatch, resource gates, status merge, final publication request | numerical kernels, boundary actions, weights, full-$P$, cap arithmetic |
| `i32_certificate_input.m` | explicit MAT load, integer-storage normalization, certificate identity, branch/Wood identity, raw-map dimensions, static preflight, post-identity pruning ledger | historical-output access, solves, scientific refinement |
| `i32_lifting_quadrature.m` | frozen Riccati, collar, wall-lift Gauss, wall-trace weights and their compact diagnostics | circle/wall action, candidate solve, cap combination |
| `i32_wall_module.m` | fixed-density circle-to-wall action, wall output ladder, wall conformity diagnostics, wall endpoint/pair signatures, finest wall factors | circle target action, full cap, any solve |
| `i32_circle_module.m` | fixed-density circle action, image/angular ladders, actual-$\Delta T$, finite-image Bloch, kernel oracles, circle endpoint/pair signatures, finest circle factors | wall output ladder, full cap, any solve |
| `i32_fullp_cap.m` | signature projector, canonical combined factors, full-$P$ partial/tail contractions, artifact association, axes, shells, interaction, arithmetic, field cap, $q_{\rm emp}$ and nominal transform | boundary re-solve, density re-fit, level/threshold selection |
| `i32_result_output.m` | compact result schema, coverage/qualification/reliability ledgers, report text, append-only save | scientific recomputation or claim upgrade |

Every new MATLAB source is a function file with English help text and grouped `LOCAL_`
subfunctions. No source discovers a repository root. Normal MATLAB function resolution is the
only source dependency mechanism.

## 3. Mechanical dimensions and typed module result

No implementation may hard-code a $97\times97$ compact matrix merely because the current
certificate has $K=97$. Define mechanically

$$
r_-:=\operatorname{size}(P_-,1),
\qquad
r_+:=\operatorname{size}(P_+,1).
$$

The certificate gate must verify separately that

$$
P_\pm\in\mathbb C^{r_\pm\times r_\pm},
\quad
c_\pm\in\mathbb C^{r_\pm},
\quad
G_\pm\in\mathbb C^{2K\times r_\pm},
$$

and that the staged certificate in this attempt has $r_-=r_+=K=97$. All signature schemas use
the mechanically obtained $r_-$ and $r_+$; equality to 97 is an identity check, not an array
constructor assumption.

Every science module returns one typed total result:

```text
available
first_unavailable
public_metrics
finest_factors
cap_signatures
audit_summary
warnings
call_counters
resource_record
```

`public_metrics`, `audit_summary`, warnings, counters, and resource records are compact and may
enter the final result. `finest_factors` and `cap_signatures` are private caller-owned
transients: their sole consumer is `i32_fullp_cap`, and they must be cleared in the entry
immediately after that consumer returns. Anticipated scientific threshold failures return
normally with `available` and qualification fields; they are never exceptions.

## 4. Compact augmented signatures

### 4.1 Canonical endpoint

Fix a component $X\in\{W,\Gamma,V\}$ and one numerical endpoint $e$. For each side
$s\in\{-,+\}$, let $H_{e,s}$ be exactly the weighted factor assembled by `design-3-2b`, with
the same row order, phase, lift normalization, and $P_s$ parenthesization. Let $N_{e,s}$ be the
selected direct-part length and $N_{\max}=32$. Let $c_e$ denote the component's center block.
The old augmented vector is

$$
F_e=
\begin{bmatrix}
c_e\\
H_{e,-}c_-\\
H_{e,-}P_-c_-\\
\vdots\\
H_{e,-}P_-^{N_{e,-}-1}c_-\\
0\\
\vdots\\
0\\
\sqrt{t_{e,-}}\\
H_{e,+}c_+\\
\vdots\\
H_{e,+}P_+^{N_{e,+}-1}c_+\\
0\\
\vdots\\
0\\
\sqrt{t_{e,+}}
\end{bmatrix},
$$

where each side has exactly $N_{\max}$ direct row slots and

$$
W_{e,s}=H_{e,s}^*H_{e,s},
\qquad
t_{e,s}=\operatorname{tail\_slot}(P_s,W_{e,s},c_s,N_{e,s}).
$$

The endpoint signature is

```text
endpoint_id, component, row_order, Nminus, Nplus
center_squared
minus.W, plus.W
minus.direct_squared_terms(1:32)
plus.direct_squared_terms(1:32)
minus.tail_input_audit, plus.tail_input_audit
finite
```

with

$$
a_{e,s,n}=\left\|H_{e,s}P_s^n c_s\right\|^2,
\qquad 0\le n<N_{\max}.
$$

Terms with $n\ge N_{e,s}$ remain stored as diagnostic action terms but occupy zero slots in
$F_e$. The module computes each term with the same ordered state update

```text
action = H * state
term = norm(action)^2
state = P * state
```

as the old `LOCAL_augmented`. Direct action blocks themselves are module-local finest
arithmetic transients; they never enter a module return or the final result.

### 4.2 Pair signature

For a preregistered ordered pair $(a,b)$ define, for $0\le n<N_{\max}$,

$$
\delta_{s,n}^{a,b}
=\left\|
\mathbf 1_{n<N_{b,s}}H_{b,s}P_s^n c_s
-\mathbf 1_{n<N_{a,s}}H_{a,s}P_s^n c_s
\right\|^2
$$

and

$$
\delta_c^{a,b}=\|c_b-c_a\|^2.
$$

The pair signature is

```text
left_endpoint_id, right_endpoint_id
center_difference_squared
minus.direct_difference_squared_terms(1:32)
plus.direct_difference_squared_terms(1:32)
left_norm_scale, right_norm_scale
finite
```

The difference action is formed while both endpoint factors are live; once the 32 scalar
terms and the required endpoint signatures exist, both coarse factors and all raw maps are
cleared. A raw Fourier norm, a difference of component norms, or a familywise tail is not an
admissible substitute.

### 4.3 Equivalence proposition

**Proposition (compact-signature reconstruction).** Assume the endpoint and pair signatures
above were formed from the same $H_{e,s}$, $P_s$, $c_s$, center blocks, selected indices, row
order, and `tail_slot` as the frozen augmented construction. Then the projector reconstructs
the same component norm and the same mathematical augmented-factor distance:

$$
B_e=\|F_e\|,
$$

and

$$
D(F_b,F_a)=\|F_b-F_a\|.
$$

**Proof.** The center, minus direct rows, minus tail slot, plus direct rows, and plus tail slot
are mutually disjoint coordinate blocks. Therefore

$$
B_e^2
=\|c_e\|^2
+\sum_{n=0}^{N_{e,-}-1}a_{e,-,n}
+t_{e,-}
+\sum_{n=0}^{N_{e,+}-1}a_{e,+,n}
+t_{e,+}.
$$

Every term on the right is present in the endpoint signature or is produced by the unchanged
`tail_slot`; taking the nonnegative square root gives $\|F_e\|$. Applying the same orthogonal
block decomposition to $F_b-F_a$ gives

$$
\begin{aligned}
\|F_b-F_a\|^2
={}&\delta_c^{a,b}
+\sum_{n=0}^{N_{\max}-1}\delta_{-,n}^{a,b}
+\left(\sqrt{t_{b,-}}-\sqrt{t_{a,-}}\right)^2\\
&+\sum_{n=0}^{N_{\max}-1}\delta_{+,n}^{a,b}
+\left(\sqrt{t_{b,+}}-\sqrt{t_{a,+}}\right)^2.
\end{aligned}
$$

These are exactly the pair-signature terms and the two endpoint tail slots. The nonnegative
square root is therefore $\|F_b-F_a\|$. No independence, normality, diagonalizability, or
modal decoupling of $P_s$ was used. Hence the complete nonnormal/Jordan coupling is retained.
$\square$

This proposition proves equality of the mathematical ordinary objects. It does **not** imply
bitwise equality of the ordinary reductions. Exactly two ordinary-double reduction-order
changes are authorized:

1. the old code applies one MATLAB `norm` to a long augmented vector, whereas REV_F reduces
   the already formed squared action terms and the two scalar tail slots; and
2. the old combined-volume route forms one stacked product
   $[H_{V,\Gamma,s};H_{V,w,s}]^*[H_{V,\Gamma,s};H_{V,w,s}]$, whereas REV_F adds the two
   already formed block Grams $W_{V,\Gamma,s}+W_{V,w,s}$.

Both changes preserve the mathematical object but may alter the last ordinary-double
reduction. Every $H P^n c$, `norm(action)^2`, state update, `tail_slot`, binary power, Gram
doubling, compensated sum, and roundoff-operation count otherwise keeps the old
parenthesization. The final direct, Gram, and compensated arithmetic paths remain three
separately recorded paths; the signature route may not replace all three by a Gram-only
computation.

### 4.4 Signature parity gate

The authorized reduction-order change is guarded by
`SIGNATURE_PARITY_UNRESOLVED`. Whenever a direct action block is live inside a module, the
module computes both

1. the direct-long-vector norm used by the old route; and
2. the norm reconstructed from the endpoint/pair signature.

For a parity comparison with results $p_{\rm long}$ and $p_{\rm sig}$, save

$$
\omega_{\rm parity}
=100n_{\rm op}\epsilon_{\rm mach}
\max\{\mathrm{realmin},|p_{\rm long}|,|p_{\rm sig}|\}.
$$

This is the already frozen arithmetic allowance rule, applied with the recorded operations of
the two norm paths. It is not a new scientific threshold and does not replace any axis,
oracle, or cap gate. The parity metric passes only if

$$
|p_{\rm long}-p_{\rm sig}|\le\omega_{\rm parity}.
$$

Actual producer-level parity covers every module-local endpoint/pair contribution while its
direct blocks are live. The blocks are then cleared and only the compact parity metric
returns. End-to-end parity in `i32_fullp_cap` additionally covers the actual final wall,
circle, and combined-volume objects; every actual circle and wall shell object; and the
full-$P$ $8,16,32$ choices. No claim is made that a producer-local family check is itself an
end-to-end combined-volume check.

The simultaneous joint object cannot retain both modules' coarse direct blocks without
violating the memory contract. Its coverage is therefore split, without hiding the
limitation:

- each actual circle and wall joint contribution passes producer-level long-vector parity;
- the cap verifies the exact Gram/direct-term addition and the single combined-volume tail;
- one preregistered end-to-end representative uses the actual finest circle and wall factors,
  the frozen states, a simultaneous two-family row stack, and the $N=16$ versus $N=32$
  zero-padding/tail pattern to compare the direct-long-vector and signature routes.

The representative changes no scientific endpoint and contributes no allowance; it is solely
an implementation parity oracle for the combined-volume/joint reduction pattern. The audit
must label which checks are actual endpoint checks and which is the representative structural
check. Direct action blocks, disk spools, and a second heavy circle evaluation are forbidden.

Any required parity failure is fail-open for later compact diagnostics but makes the
corresponding component and total numerator unavailable. In that case the first applicable
empirical reason is `SIGNATURE_PARITY_UNRESOLVED`, and neither $q_{\rm emp}$ nor a nominal
interval is formed.

The second authorized reduction has its own typed metric and operation ledger. Whenever both
actual family factors are simultaneously live, compare

$$
W_{\rm stack}
=\begin{bmatrix}H_{V,\Gamma,s}\\H_{V,w,s}\end{bmatrix}^*
\begin{bmatrix}H_{V,\Gamma,s}\\H_{V,w,s}\end{bmatrix}
$$

with

$$
W_{\rm sum}=H_{V,\Gamma,s}^*H_{V,\Gamma,s}+H_{V,w,s}^*H_{V,w,s}.
$$

The metric uses the same frozen arithmetic rule

$$
\omega_{\rm gram}
=100n_{\rm gram}\epsilon_{\rm mach}
\max\{\mathrm{realmin},\|W_{\rm stack}\|_2,\|W_{\rm sum}\|_2\},
$$

and passes only if

$$
\|W_{\rm stack}-W_{\rm sum}\|_2\le\omega_{\rm gram}.
$$

Save this independently as `combined_gram_parity`, including side, object class, actual versus
representative label, $n_{\rm gram}$, both norms, numerator, scale, allowance, ratio, and pass.
Actual final combined-volume endpoints are checked while their finest factors are live.
Actual coarse and joint family factors still receive producer-local Gram checks; because their
cross-module stacked factors are not retained, the same preregistered actual-finest
two-family/$N=16$ versus $N=32$ structural representative used above also covers stacked-Gram
versus block-sum assembly. This limitation is explicit and contributes no allowance.

Failure emits `COMBINED_GRAM_PARITY_UNRESOLVED`. It is fail-open for compact diagnostics but
makes the numerator and $q_{\rm emp}$ unavailable. Its allowance is an implementation parity
gate and is never added to $\epsilon_M^{\rm emp}$.

## 5. Table 1: old formula/field to new signature mapping

| Frozen object or old field | Old producer | Actual downstream consumer | REV_F replacement | Dense/raw object death point | Final-result projection |
|---|---|---|---|---|---|
| `density.orders/tau/zeta` | `LOCAL_density_coefficients` | circle and wall actions; density roundtrip | module-local fixed FFT coordinate plus norms/roundtrip summary | after each action module completes | shape, order band, roundtrip metric only |
| `density.xi_left/right` | same | wall-to-circle and wall actions | direct staged views local to the consuming module | after last cross action | source shape/normalization only |
| circle target samples `value_plus/minus`, `dr_plus/minus` | circle ladder | coefficient transform only | transformed immediately; never returned | immediately after endpoint coefficient/signature formation | norms and finite flags only |
| circle `delta_samples/jump_samples` | circle ladder | angular restriction and joint holdout | keep only the one live restriction source until all registered restrictions are signed | immediately after angular and joint signatures | restriction nodes and metric records only |
| image `delta_coeff/jump_coeff` at seven levels | circle ladder | image $F_\Gamma,F_V$ endpoints and pairs | endpoint/pair signatures | immediately after all pairs consuming that checkpoint are formed | compact image metrics only |
| image `actual_deltaT_coeff` at seven levels | circle ladder | actual-$\Delta T$ qualification | pending-pair queue; each metric formed at last use | at its last dyadic/staggered/cross comparison | qualification metrics only |
| angular `delta_coeff/jump_coeff/actual_deltaT_coeff` | circle ladder | angular axes, actual-$\Delta T$, final factors | pair signatures plus only finest projected factors | coarse after adjacent pair; finest after cap | metrics; no coefficients |
| `circle.theta`, `circle.orders` vectors | circle ladder | grid/audit labels, shell indexing | node count and arithmetic order-band descriptor; finest factor rows retain canonical order | vector after coefficient transform | scalar band endpoints and count |
| finite-Bloch level endpoint arrays | finite-Bloch oracle | value/flux metrics only | metrics formed at each checkpoint | immediately after metric formation | seven compact metric records |
| kernel-oracle raw matrices/harmonics | oracle helpers | oracle defects only | local oracle workspaces | after each oracle defect | availability, defect, threshold, message |
| wall `raw_left/right`, `g_left/right`, `circle_left/right` | wall ladder | defect, repair, and refinement metrics | defect/refinement formed immediately | same level after signature formation | norms/metrics only |
| wall `defect_left/right`, `flux_left/right` at three levels | wall ladder | wall axes, volume axes, final/shell factors | endpoint/pair signatures plus finest projected factors | coarse after pair signature; finest after cap | compact wall metrics only |
| Riccati and Gauss dense work arrays | weight helpers | one-dimensional weights | streamed integration/RK work | each step/level immediately | energy, Bessel, positivity, min/max metrics |
| three circle/collar/wall-lift weight vectors | weight module | axis and endpoint signatures | compact one-dimensional factor ladder, private only | after cap consumes all weight axes | public level summaries only |
| `oracle.density_modes` | old oracle return | no downstream consumer | deleted | before oracle return | absent |
| evaluator `public` duplicate coefficients/maps | `LOCAL_public_evaluation` | result serialization only | no duplicate public/internal tree | not created | compact public metrics built once |
| audit density coefficients, final theta/order vectors | evaluator audit | no scientific consumer | shapes, bands, norms, semantic labels | not returned | compact audit summary |
| `artifact.common_reconstruction` raw maps | artifact cap | audit serialization only | artifact association formed locally; shape/norm/phase summary | immediately after artifact comparison | compact association audit |
| endpoint `final/artifact` augmented vectors | cap | norms, association, arithmetic | endpoint/pair signatures; direct blocks only transient for finest arithmetic | after relevant metric/arithmetic path | norm, length, tails, arithmetic metrics |
| image/axis cell arrays of endpoint vectors | cap axes | pair differences | pair metric formed from signatures immediately; long/signature parity formed while direct blocks are live | after each preregistered pair | metric and parity records only |
| shell factors/vectors | cap shells | two shell norms | one shell endpoint at a time | after its shell norm | shell norms/metrics only |
| `raw_maps.QL*`, raw unit residual maps after identity | staged input | no post-identity scientific consumer | pruned from active staged working copy after compact identity audit | immediately after certificate identity | dimensions/identity metrics only |

No field may survive merely because it appeared in the old public/audit schema. Survival
requires a named scientific consumer in this table.

## 6. Table 2: module API, shape, registered consumer set, and death point

Here $N_c=2048$, $N_w=4096$, and $r_\pm$ are mechanically defined in section 3.
Every `certificate <field>` shorthand in this table denotes the canonical path
`finest_factors.staged.certificate.<field>` relative to the certificate-module return.
Likewise the retained raw-map subtree has canonical prefix
`finest_factors.staged.raw_maps`.

| Producer and returned field | Class and shape | Exact registered consumer set | Last use | Clear point | Saved? |
|---|---|---|---|---|---|
| staged `input_contract` | compact typed struct; no dense numerical payload | certificate gate and result provenance | initial result construction | compact copy retained | yes |
| certificate `Pminus/Pplus` | complex $r_-\times r_-$ / $r_+\times r_+$ | wall signatures, circle signatures, and full-$P$/field cap | full-$P$/field cap | immediately after cap return | shape/norm summary only |
| certificate `Gminus/Gplus` | complex $2K\times r_-$ / $2K\times r_+$ | wall projected factors, circle projected factors, and artifact/cap factors | artifact/cap factors | inside cap, then entry | shape/norm summary only |
| certificate `cminus/cplus` | complex $r_-\times1$ / $r_+\times1$ | wall/circle signatures and full-$P$/field contractions | full-$P$/field cap | immediately after cap return | norm summary only |
| certificate `eta_unit_256` | complex $512\times2K$ | exactly `{wall,circle}`: circle-to-wall action and circle self/image/oracle/density-roundtrip action | circle, under frozen wall-then-circle dispatch | immediately after circle return; no copied alias | shape/norm/roundtrip summary only |
| certificate `xi_left_unit_512` | complex $512\times2K$ | exactly `{wall,circle}`: wall defect action and circle wall-to-circle/finite-Bloch action | circle, under frozen wall-then-circle dispatch | immediately after circle return; no copied alias | shape/norm summary only |
| certificate `xi_right_unit_512` | complex $512\times2K$ | exactly `{wall,circle}`: wall defect action and circle wall-to-circle/finite-Bloch action | circle, under frozen wall-then-circle dispatch | immediately after circle return; no copied alias | shape/norm summary only |
| certificate `wall_input_unit_512` | numeric $1024\times2K$ | exactly `{wall}` for the fresh shared-wall defect action | wall | immediately after wall return | shape/norm summary only |
| certificate `q_center` | complex $2K\times1$ | exactly `{wall}` for fresh center-wall derivative signatures after identity | wall | immediately after wall return | norm/identity summary only |
| certificate `branch_port.gamma_m` | complex $K\times1$ | exactly `{wall}` for fresh center-wall derivative signatures after branch identity | wall | immediately after wall return | branch summary only |
| certificate `center_shared_left_trace/right_trace` | two complex $512\times1$ vectors | exactly `{circle,fullp_cap}` for structural Bloch and denominator field center | full-P/field cap | immediately after field metrics | compact norms/metrics only |
| certificate `center_actual_left_trace/right_trace` | two complex $512\times1$ vectors | exactly `{circle}` for the repaired-conformity metric | circle | immediately after circle return | compact repaired-conformity metrics only |
| certificate `center_left_value_mismatch/right_value_mismatch` | two complex $512\times1$ vectors | exactly `{circle,fullp_cap}` for repaired conformity and volume-center/artifact association | full-P/cap | immediately after volume/artifact metrics | compact norms/metrics only |
| certificate `center_wall_jumps.left_coefficients/right_coefficients` | two complex $512\times1$ vectors | exactly `{fullp_cap}` for artifact wall-center factors | artifact association | inside cap | compact norms only |
| certificate `Dminus/Dplus` | complex $K\times r_-$ / $K\times r_+$ | certificate $G$/center identity only | certificate identity | post-identity pruning | shape and identity defects only |
| certificate `wall_orders_512` | numeric $512\times1$ | certificate order identity only | certificate identity | post-identity pruning | count, band, and defect only |
| certificate branch identity arrays other than `gamma_m` | `beta_m`, `t_m`, `classification`, `outgoing_reference`, `outgoing_relative_defects`, `outgoing_sign_pass`, and `axis_pass`, each $K\times1$ | certificate branch/Wood identity only | certificate identity | post-identity pruning | compact defects, margin, classes, and sign metrics only |
| certificate duplicated `center_wall_jumps` trace arrays | `center_left/right_global_dx`, actual/shared left/right traces, and left/right value mismatches, each $512\times1$ | certificate stored-center identity only | certificate identity | post-identity pruning | compact stored-center metrics only |
| other certificate scalars, labels, and lift contract | compact scalar/text/Boolean fields | registered science consumers and result provenance | final compact projection | compact copy retained | yes, compact only |
| certificate `staged.raw_maps` retained whitelist | exactly `delta_plus/minus`, `circle_jump_plus/minus`, `Jplus/minus`, `wall_common_y_1024`, `wall_common_value_1024`, and `wall_input_unit_512`, with identity-checked shapes | cap artifact common-coordinate association only | artifact association | inside cap and then entry | no raw maps |
| staged `ordinary_anchor` scalar/tail/index fields | compact typed struct | anchor association, cap centers, selected full-$P$ indices | component/field cap | after cap | compact anchor summary only |
| staged `ordinary_anchor.lead_field_factor_minus/plus` | two complex matrices with mechanically checked second dimensions $r_-$ and $r_+$ | denominator same-finite-partial direct/Gram/compensated paths only | field cap | immediately after field metrics | no |
| other staged dense `ordinary_anchor.lead_*` and center-lift factors | complex matrices, shapes frozen by input identity | certificate/common-coordinate identity only; no REV_F science consumer | certificate identity | post-identity pruning | shape/norm audit only |
| staged `historical_diagnostics` | compact typed metrics; no scientific control | result/report background disclosure only | result construction | compact copy retained | yes |
| certificate `identity` | compact struct | entry qualification | final status | result publication | yes |
| lifting `private.circle_weights(1:3)` | three real $N_c\times1$ vectors | circle signatures and Riccati axis | Riccati metric | cap return | summaries only |
| lifting `private.collar_weights(1:3)` | three real $N_c\times1$ vectors | circle-volume signatures and Gauss axis | Gauss metric | cap return | summaries only |
| lifting `private.wall_lift_weights(1:3)` | three real $N_w\times1$ vectors | wall-volume signatures and Gauss axis | Gauss metric | cap return | summaries only |
| lifting `private.wall_trace` | real $N_w\times1$ | wall component endpoints/shells | wall shell | cap return | positivity/min/max only |
| circle `finest.jump_minus/plus` | complex $N_c\times r_\mp$ / $N_c\times r_+$ | Riccati, final, artifact, circle shells | last circle shell/anchor path | inside cap, then entry | no |
| circle `finest.delta_minus/plus` | complex $N_c\times r_\mp$ / $N_c\times r_+$ | Gauss, final, artifact, circle-volume shells | last circle shell/anchor path | inside cap, then entry | no |
| circle `signatures.image(1:7)` | endpoint signatures: two side Grams plus $32$-term vectors and compact parity records | image axes and interaction | image metrics and joint leg | inside cap | metrics/parity only |
| circle `signatures.angular(1:3)` | same compact schema | angular axes | angular metrics | inside cap | metrics only |
| circle `signatures.joint` | endpoint/pair signature at image 192 restricted to angular 1024 and penultimate weights, plus producer parity | simultaneous interaction | joint metric | inside cap | interaction/parity metric only |
| circle `public_metrics` | compact structs/scalars | final result | result merge immediately on module return | retained in result | yes |
| wall `finest.normal_minus/plus` | complex $N_w\times r_\mp$ / $N_w\times r_+$ | final wall, full-$P$, artifact, wall shells | last wall shell/anchor path | inside cap, then entry | no |
| wall `finest.defect_{L/R,minus/plus}` | four complex $N_w\times r_s$ factors | Gauss, final volume, artifact, wall-volume shells | last wall shell/anchor path | inside cap, then entry | no |
| wall `signatures.output(1:3)` | compact endpoint/pair signatures and producer parity records | wall axes and interaction | wall/joint metric | inside cap | metrics/parity only |
| wall `signatures.joint` | penultimate wall-output/weight endpoint and pair terms, plus producer parity | simultaneous interaction | joint metric | inside cap | interaction/parity metric only |
| wall `public_metrics` | compact structs/scalars | final result | result merge immediately on module return | retained in result | yes |
| full-P temporary finest direct action blocks | complex vectors, never matrices with state-coordinate columns | final direct arithmetic and parity paths only | component arithmetic/parity | same helper before return | no |
| cap endpoint/pair records | compact structs | axes, anchors, arithmetic | component cap assembly | before cap return | selected compact metrics only |
| cap `components/caps/estimator/tails/axis_metrics/arithmetic` | compact structs | result/report | publication | retained in result | yes |
| all module `warnings/counters/resource_record` | compact structs | entry merge | immediately after module return | merged copy retained | yes |

The entry must execute `clear lift_private wall_private circle_private cap_private` after the cap
has copied its compact return. A MATLAB `struct` or `cell` may not be used as a hidden owner of
raw target arrays. The implementation must recursively inventory each private return before
the resource gate and reject any field name or numeric shape outside the whitelist above.

The liveness rule is an exact registered consumer set plus one unique last consumer and death
point. A field may have more than one consumer only where this table lists the complete set.
In particular, the four dense source paths `eta_unit_256`, `xi_left_unit_512`,
`xi_right_unit_512`, and `wall_input_unit_512` have literal shapes and consumers above; they
are not a blanket certificate exception. The first three are shared by wall and circle, and
the frozen wall-then-circle order lets them die after circle. The certificate wall input has
only the wall consumer and dies after wall. It
is distinct from
`finest_factors.staged.raw_maps.wall_input_unit_512`, which remains solely for artifact
association inside the cap. The entry passes one reachable owner through the registered
consumers and does not make a private copied alias for either consumer.
The top-level actual, mismatch, and shared center traces remain live through the circle
module because repaired conformity is recomputed there as
`LOCAL_metric_record(actual_trace + mismatch, shared_trace, identity_tol)` with the frozen
Revision E formula and parenthesization. The certificate identity metric has a different
scale/allowance contract and may not replace this circle metric. The actual traces then die
after circle; mismatch and shared traces remain only for their registered full-P/cap uses.

MATLAB exposes value semantics and copy-on-write behavior but no supported portable reference
count. Therefore `whos` cannot prove that no physical alias exists. REV_F makes the narrower,
auditable claim that no forbidden owner is reachable through the returned struct/cell graph.
The checks are:

1. recursive returned-field whitelist;
2. prohibited raw-field-name assertion;
3. prohibited dense-shape assertion, except explicitly whitelisted finest factors;
4. local `whos` inventory after every last-use `clear`;
5. entry inventory after clearing every private module return.

The resulting byte counts are deterministic active-object proxies, not process RSS, allocator
high-water marks, or a proof about copy-on-write reference counts.

## 7. Table 3: combined volume, shells, joint interaction, and 292 contractions

### 7.1 Combined volume is formed before every tail

At every endpoint $e$, the volume factors retain the old row order

$$
H_{V,+}^{(e)}=
\begin{bmatrix}
H_{V,\Gamma,+}^{(e)}\\
H_{V,w,+}^{(e)}
\end{bmatrix},
\qquad
H_{V,-}^{(e)}=
\begin{bmatrix}
H_{V,\Gamma,-}^{(e)}\\
H_{V,w,-}^{(e)}
\end{bmatrix}.
$$

Consequently the projector must first form

$$
W_{V,s}^{(e)}
=W_{V,\Gamma,s}^{(e)}+W_{V,w,s}^{(e)},
$$

and only then call the unchanged `tail_slot` once per side. Pair direct-difference terms are
combined by adding the squared norms of the two orthogonal row blocks before the final square
root. The following are prohibited:

- separate circle and wall volume tails;
- addition or root-sum-square of familywise augmented norms;
- replacing the combined tail by a raw-map norm;
- using a per-eigenmode tail instead of full matrix powers.

For every actual final endpoint, the stacked $H^*H$ and block-Gram sum must satisfy the
`combined_gram_parity` gate in section 4.4 before the single volume tail is accepted. Shells
are checked when their masked finest factors are simultaneously live. Coarse and simultaneous
joint objects use the disclosed producer checks plus the actual-finest structural
representative; they may not be mislabeled as actual cross-module stacked checks.

### 7.2 Frozen object map

| Object | Signature construction | Full-$P$/tail rule | Output |
|---|---|---|---|
| final $F_W$ | finest wall-normal factor | one minus and one plus tail at $N=32$ | final norm/tail/arithmetic |
| final $F_\Gamma$ | finest circle-normal factor with final Riccati weight | one minus and one plus tail at $N=32$ | final norm/tail/arithmetic |
| final $F_V$ | circle-value and wall-value factors stacked before Gram | one combined tail per side at $N=32$ | final norm/tail/arithmetic |
| artifact factors | staged raw maps reconstructed on the frozen common coordinates | artifact selected $N_-$ and $N_+$; same side association | anchor comparison only |
| image axis | seven circle endpoints; all other coordinates final | each old build still projects all three components | five frozen pair metrics |
| angular/wall/Riccati/Gauss/full-$P$ axes | three endpoints, all other coordinates final | old $0.5/2$ rule | $d_1,d_2$ and remainder |
| circle shells | finest rows in $1024\setminus512$ and $2048\setminus1024$ bands | shell factor gets its own unchanged augmented tail | two shell norms per affected component |
| wall shells | finest rows in $2048\setminus1024$ and $4096\setminus2048$ bands | same | two shell norms per affected component |
| joint holdout | image 192 restricted to angular 1024, wall 2048, Riccati 1024, Gauss 64, full-$P$ 16 | simultaneous endpoint; volume Gram combined first | joint shift only, never an allowance |
| official joint legs | each one penultimate coordinate against all-final | same frozen endpoint projector | sum on right side of interaction gate |
| mandatory state tail | $W=I$ at $N=8,16,32$ | full $P_\pm$ matrices | state-tail diagnostic |
| field partial | staged field factors and selected artifact indices | direct/Gram/compensated plus growth at 8,16,32 | $\epsilon_N^{\rm emp}$ candidate |

### 7.3 Contraction ledger

One contraction sequence means one side-specific tail or finite-partial sequence. The REV_F
implementation must preserve the old semantic total even where compact signatures could
remove redundant work.

| Block | Count derivation | Frozen count |
|---|---:|---:|
| final components | $3$ components $\times2$ sides | 6 |
| mandatory state tail | $3$ levels $\times2$ sides | 6 |
| artifact components | $3$ components $\times2$ sides | 6 |
| image axis builds | $7$ choices $\times3$ components $\times2$ sides | 42 |
| nine three-level axes | $9\times3$ choices $\times3$ components $\times2$ sides | 162 |
| interaction joint plus six official legs | $7$ choices $\times3$ components $\times2$ sides | 42 |
| four shell families/components at two shells | $4\times2\times2$ sides | 16 |
| field direct/Gram/compensated and three growth levels | $6$ paths/levels $\times2$ sides | 12 |
| **total** | $6+6+6+42+162+42+16+12$ | **292** |

The counter audit must retain the category counts as well as the total. A total of 292 obtained
from a different category allocation is a spec failure.

The parity oracle does not increment the 292 ledger: it reuses an action block while that
block is already live and counts its own norm/subtraction operations only in
`n_op_signature_parity`. It may not add a tail/partial contraction sequence.

## 8. Component and gate preservation

The numerator availability Boolean is unchanged:

```text
wall cap available
AND circle cap available
AND volume cap available
AND interaction pass
AND mandatory state tail available
AND kernel oracle available and qualified
AND repaired conformity qualified
AND actual-Delta-T action qualified
AND finite-image Bloch action qualified
AND all required signature parity records qualified
AND all required combined-Gram parity records qualified
```

Actual-$\Delta T$, finite-image Bloch, and analytic-kernel threshold failures are fail-open in
the execution sense: later raw diagnostics continue whenever finite. They nevertheless make
the corresponding empirical numerator prerequisite false. Fail-open never means that
$q_{\rm emp}$ must be formed.

A signature parity failure has the same fail-open execution semantics: later compact
diagnostics continue, but the empirical numerator and $q_{\rm emp}$ remain unavailable. The
parity allowance is an arithmetic implementation check, not an empirical error-cap component
and is never added to $\epsilon_M^{\rm emp}$.

The independently recorded combined-Gram parity has the same semantics and no cap allowance.
`SIGNATURE_PARITY_UNRESOLVED` and `COMBINED_GRAM_PARITY_UNRESOLVED` must not be collapsed into
one untyped Boolean in the audit, even though either makes the numerator unavailable.

Every warning record retains typed availability, qualification, numerator, scale, ratio,
threshold, pass, and call counters. The post-run review may compare the new diagnostics with
the historical `ecap-a2` values as a parity check, but the formal MATLAB runtime must not read
the old output or encode those observed values as acceptance thresholds.

The cap formulas remain

$$
\epsilon_M^{\rm emp}
=\epsilon_W^{\rm emp}+\epsilon_\Gamma^{\rm emp}+\epsilon_V^{\rm emp},
$$

$$
q_{\rm emp}
=\frac{\widetilde{\mathcal M}_h+\epsilon_M^{\rm emp}}
{\sqrt{\widetilde N_h-\epsilon_N^{\rm emp}}},
$$

and, only if $q_{\rm emp}<1$, the frozen nominal algebraic interval. Nothing in REV_F creates
an outward residual upper bound, field lower enclosure, Fourier/image-tail enclosure,
certified gap, spectral existence result, or independent effectivity reference.

## 9. Table 4: resource proxy and failure publication

### 9.1 Per-module resource record

For each of `certificate`, `lifting`, `wall`, `circle`, `fullp_cap`, and
`result_output/publication`, the entry saves:

| Field | Definition |
|---|---|
| `retained_before_mib` | caller-owned active-object proxy immediately before the call |
| `input_alias_nominal_mib` | nominal size of module inputs visible in the callee |
| `local_workspace_peak_mib` | maximum `sum([whos.bytes])/2^20` observed at registered checkpoints |
| `module_exclusive_peak_mib` | $\max\{0,\text{local peak}-\text{input alias nominal}\}$ |
| `concurrent_peak_candidate_mib` | retained before plus $\max\{360\ \mathrm{MiB},\text{module-exclusive peak}\}$ |
| `return_payload_mib` | recursive nominal size of the typed module return |
| `retained_after_mib` | caller-owned proxy after merge and prescribed clears |
| `cumulative_peak_candidate_mib` | maximum of all normalization, concurrent, and retained-after candidates so far, with the 360 MiB floor in every module concurrent candidate |
| `proxy_semantics` | explicit statement that the ledger is not RSS/refcount/allocator accounting |

`i32_result_output` has no ordinary science payload return, but it is not exempt from the
ledger. Its publication record contains `retained_before_mib`, `input_alias_nominal_mib`,
`local_workspace_peak_mib`, `module_exclusive_peak_mib`, the same 360 MiB-floor concurrent
candidate, `retained_after_publication_proxy_mib`, and the cumulative candidate. The
after-publication value is the active-object proxy after report/result construction buffers
are cleared; it does not count file bytes as resident memory. The complete record is inserted
into the result before final serialization, and the function verifies the post-write proxy
against that recorded value before returning. A mismatch is a consumed-attempt publication
failure, not permission to rerun the tag.

Sequential module-local peaks are combined by maximum, never by addition. Caller-retained
inputs are neither omitted nor counted twice as exclusive transient. The same proxy is used
for preflight and the 640 MiB hard gate, so the refactor may not pass merely by changing the
accounting definition. In particular, deleting a dense return may reduce retained-after
memory, but it never removes the frozen `worst_transient_mib=360` floor from a concurrent
candidate. The formal formula is

$$
M_{\rm concurrent}^{(j)}
=M_{\rm retained,before}^{(j)}
+\max\{360\ \mathrm{MiB},M_{\rm exclusive,peak}^{(j)}\}.
$$

### 9.2 Static estimate

The `ecap-a2` evidence was approximately 47.2623 MiB retained before evaluation, 312.3857 MiB
evaluation-helper local peak, and 664.4707 MiB retained after the monolithic return. REV_F
removes the seven image and three angular dense coefficient ladders, the three dense wall
ladders, duplicate public maps, raw audit maps, and cap endpoint-vector cell arrays.

The largest returned science payloads are the whitelisted finest projected factors:

- four $N_c\times r_s$ circle factors;
- two $N_w\times r_s$ wall-normal factors;
- four $N_w\times r_s$ wall-defect factors;
- compact side Grams whose dimensions are $r_s\times r_s$;
- one-dimensional weight ladders and 32-term action summaries.

For the staged identity $N_c=2048$, $N_w=4096$, and $r_-=r_+=97$, the finest complex factors
are approximately 48.5 MiB in aggregate. Compact signatures and weights are expected to keep
retained science payload below about 70 MiB. With the frozen 360 MiB streaming-transient
allowance and staged certificate proxy, the conservative concurrent estimate is below about
480 MiB. These figures are a static planning estimate, not a promise and not a reason to
change any resource gate. If the exact preflight inventory exceeds 520 MiB, the formal
attempt stops without lowering levels or deleting an oracle.

### 9.3 Merge-before-gate and failure state

Each module must return a typed total result for anticipated branch/Wood, nonfinite action,
invalid weight, soft/hard time, and active-object resource conditions. The entry performs in
this order:

1. copy compact public metrics, completed-checkpoint audit, warnings, and counters into
   `result`;
2. update coverage and module resource record;
3. clear fields whose last use has passed;
4. execute the hard resource gate;
5. dispatch the next module only if permitted.

Thus a resource stop after circle or wall evaluation cannot reset counters, warnings,
coverage, or first-warning state to defaults. Unexpected MATLAB exceptions may still throw
to the entry catch, but unreturned work is never described as completed.

Failure precedence remains:

1. attempt already consumed;
2. explicit input unavailable or schema invalid;
3. certificate identity/NO_RESOLVE failure;
4. exact branch/Wood unavailable;
5. hard time/memory or soft stage-start stop;
6. required numerical object unavailable;
7. finite scientific qualification/cap unresolved;
8. finite nominal statuses.

`first_execution_blocker`, `first_empirical_unavailable`, and
`first_nonblocking_warning` are independent fields. A hard resource blocker does not erase a
scientific warning already returned; a scientific warning is not rewritten as the execution
blocker.

## 10. Returned-field and liveness hard assertions

The implementation must include a recursive return auditor with a literal schema table. It
rejects:

- target sample fields such as `value_plus`, `value_minus`, `dr_plus`, `dr_minus`,
  `delta_samples`, `jump_samples`, or `actual_deltaT_samples`;
- wall raw fields such as `raw_left`, `raw_right`, `g_left`, `g_right`, `circle_left`, or
  `circle_right`;
- duplicate `public` coefficient maps;
- artifact raw common maps in audit output;
- numeric two-dimensional arrays with both dimensions greater than one unless their exact
  full path and mechanical shape are one of:
  `finest_factors.staged.certificate.Pminus` $[r_-,r_-]$;
  `finest_factors.staged.certificate.Pplus` $[r_+,r_+]$;
  `finest_factors.staged.certificate.Gminus` $[2K,r_-]$;
  `finest_factors.staged.certificate.Gplus` $[2K,r_+]$;
  `finest_factors.staged.certificate.eta_unit_256` $[512,2K]$;
  `finest_factors.staged.certificate.xi_left_unit_512` $[512,2K]$;
  `finest_factors.staged.certificate.xi_right_unit_512` $[512,2K]$;
  `finest_factors.staged.certificate.wall_input_unit_512` $[1024,2K]$;
  an exact `finest_factors.staged.raw_maps.<field>` path from the nine-field artifact
  whitelist, including the distinct
  `finest_factors.staged.raw_maps.wall_input_unit_512`; a denominator lead field factor; a
  whitelisted finest factor; or a compact side Gram;
- any coefficient ladder whose level dimension is hidden in a struct/cell outside the compact
  signature schema.

Every module audit includes:

```text
returned_field_inventory
returned_numeric_shape_inventory
prohibited_field_count
prohibited_shape_count
last_use_clear_ledger
post_clear_local_owner_inventory
finest_factor_whitelist
compact_signature_whitelist
signature_parity_coverage
```

Both prohibited counts must be zero before the entry accepts the return. This verifies the
reachable owner graph defined by the schema; it does not claim access to MATLAB's internal
copy-on-write reference graph.

Every exception is path- and shape-specific. Neither
`finest_factors.staged.certificate` nor `finest_factors.staged.raw_maps` is a blanket
exception. Certificate $D_\pm$, `wall_orders_512`, and the listed branch and duplicated
`center_wall_jumps` identity arrays must be pruned after identity. The top-level actual
traces remain through circle exactly as Table 2 requires. The four dense source
paths and all vector paths must match their exact registered consumer set, unique last
consumer, and death point in Table 2. Only the nine named raw-map fields with a post-identity
consumer may survive. Dense ordinary-anchor factors other than the two lead field factors must
die after identity unless Table 2 names a consumer. An unknown field fails closed even if its
dimensions happen to match a permitted array.

## 11. NO_RESOLVE and same-trial contract

The eight forbidden counters remain exactly zero:

```text
candidate_solve_calls
qz_solve_calls
coordinate_solve_calls
propagation_solve_calls
wall_density_solve_calls
circle_density_solve_calls
schur_solve_calls
proxy_build_calls
```

The module split may not call back into candidate/QZ/BIE assembly, change a density, alter a
wall trace, or rebuild a propagation operator. Ordinary action/oracle counters remain typed
and are merged immediately after each module.

There are exactly two `eig` allowlist entries. First, inside `i32_fullp_cap`, the copied
`LOCAL_psd_root` availability gate may call

```text
eig((W+W')/2)
```

on the small Hermitian side Gram. It must retain the old Hermiticity defect, minimum-eigenvalue
tolerance, finite check, and `i32e:ComponentGram` failure semantics; it may not clip an
eigenvalue or use the eigendecomposition as a candidate/state solve. Record it in the typed
counter `small_hermitian_gram_diagnostic_eig_calls`, which is excluded by name from the eight
NO_RESOLVE counters but audited against the frozen projector call lattice. Its expected count
is $6+6+246+16=274$: final, artifact, axis/interaction, and shell side factors use the gate;
mandatory state tails and field partials do not call `LOCAL_psd_root`.

Second, only `i32_lifting_quadrature>LOCAL_gauss` may retain the frozen Golub--Welsch
quadrature-node construction

```matlab
j=(1:n-1).'; beta=j./sqrt(4*j.^2-1);
[V,D]=eig(diag(beta,1)+diag(beta,-1));
[x,order]=sort(diag(D)); V=V(:,order); w=2*(V(1,:).^2).';
```

The complete parenthesization, the `beta` formula, the symmetric tridiagonal `eig`, the sort,
the column reorder, and the weight formula are frozen. For each
$n\in\{32,64,128\}$, collar and wall lifting call `LOCAL_gauss` independently once. It is
forbidden to hard-code nodes, substitute a library or Newton generator, or cache one call for
both lifts. Record the typed counter `gauss_golub_welsch_eig_calls` with the exact category
map `{32:2, 64:2, 128:2}` and total $6$. It is distinct from
`small_hermitian_gram_diagnostic_eig_calls=274`, so the exact total allowlisted `eig` count is
$280$. These six calls construct only frozen quadrature nodes and are not candidate, state,
propagation, or BIE solves. Their count/path audit contributes no empirical allowance.

A wrong allowlisted expression, path, level-category count, small-Gram count, or total count
makes the input/spec identity unavailable and prevents component caps, the numerator, and
$q_{\rm emp}$ from being formed. It is not added to $\epsilon_M^{\rm emp}$ or
$\epsilon_N^{\rm emp}$. All other `eig`, every `eigs` or `qz`, backslash solve, `linsolve`,
`lsqminnorm`, `pinv`, BIE builder, proxy builder, and old monolithic fallback are forbidden in
formal functions. The static call inventory must mechanically distinguish the two exact
allowlisted expressions from all forbidden eigenvalue calls.

## 12. Output schema and formal command

The final `result.mat` and `report.md` remain compact. They contain:

- frozen certificate summary and level ledger;
- module completion/availability and resource ledger;
- compact circle, wall, lifting, oracle, actual-$\Delta T$, Bloch, and conformity metrics;
- actual/representative signature-parity coverage, operation counts, allowances, and pass
  records;
- actual/representative combined-Gram parity coverage with a separate operation ledger;
- component, anchor, axis, shell, interaction, arithmetic, full-$P$, and field ledgers;
- empirical caps, $q_{\rm emp}$, nominal endpoints/width when available;
- complete coverage, qualification, NO_RESOLVE, first-condition, and reliability-false
  ledgers.

They contain no private finest factors, signature Grams, raw target arrays, coefficient
ladders, direct action blocks, or staged raw maps.

The only future formal command is

```bash
matlab -batch "addpath(fullfile(pwd,'test','i3','e-cap')); check_e_cap_stream('ecap-a3',fullfile(pwd,'test','i3','e-cap','input','fbie-a1-certificate.mat'));"
```

The output guard is stronger than checking the two expected files: the entire directory

```text
test/i3/e-cap/output/ecap-a3
```

must be absent before the command starts. Creation of that directory consumes `ecap-a3`
immediately. If publication leaves only one file, a partial file, or an exception record, the
tag is still consumed and may not be rerun or backfilled.

On a complete publication the directory contains

```text
test/i3/e-cap/output/ecap-a3/result.mat
test/i3/e-cap/output/ecap-a3/report.md
```

The command may run exactly once after all authorization gates. There is no retry, adaptive
fallback, threshold change, level change, report backfill, or memory-limit increase.

## 13. Spec-to-code acceptance criteria

The implementation is eligible for Researcher mapping review and Skeptic spec-to-code review
only if static inspection establishes all of the following:

1. the entry point is thin and contains no scientific formula;
2. circle, wall, lifting/quadrature, and full-$P$/cap are independent function files;
3. historical MATLAB files and outputs are untouched and uncalled;
4. staged certificate/trial/levels/thresholds/formulas match `design-3-2b` exactly;
5. actual-$\Delta T$, finite-image Bloch, kernel-oracle, conformity, signature-parity, and
   combined-Gram-parity gates enter the same numerator Boolean;
6. compact endpoint/pair signatures implement the proposition and parity gate in section 4;
7. combined volume Grams precede every volume tail;
8. shell and joint objects match the frozen coordinate choices;
9. category and total full-$P$ counters equal the table in section 7.3;
10. no prohibited dense field is reachable from a module return or final result, and the
    certificate auditor uses exact full paths and mechanical shapes rather than a blanket
    certificate exception;
11. every private field matches its exact registered consumer set and has one unique last
    consumer and explicit death point; in particular the four dense source paths and all
    certificate vectors match Table 2 without a copied alias;
12. resource records use the proxy in section 9 without alias double-counting claims;
13. anticipated failure returns preserve completed counters/warnings/coverage;
14. `SIGNATURE_PARITY_UNRESOLVED` and `COMBINED_GRAM_PARITY_UNRESOLVED` are independently
    typed, fail-open for diagnostics, gate the numerator, and never enter an empirical
    allowance;
15. the only two allowlisted `eig` expressions match their exact function-path allowlists;
    `small_hermitian_gram_diagnostic_eig_calls=274`, the Gauss category map is exactly
    `{32:2, 64:2, 128:2}`, `gauss_golub_welsch_eig_calls=6`, and the audited total is 280;
16. publication has a module resource ledger and directory creation consumes the tag;
17. every reliable/certified/existence/independent/effectivity flag is false;
18. only the exact `ecap-a3` command and absent-output guard are accepted.

No formal MATLAB experiment, including a smoke run on the staged certificate, is allowed
before Skeptic `SPEC-TO-CODE PASS` and explicit one-command authorization. Read-only static
inspection and `checkcode` may occur only after implementation freeze and must not create an
attempt output.

## 14. Design-stage static checks and authorization chain

This design stage performed no MATLAB run, no staged-input mutation, and no output creation.
The design file itself must pass:

- Markdown display/inline math style required by `AGENTS.md`;
- no reference to an unconsumed historical tag as reusable;
- one unique schema, entry, attempt tag, command, and output path;
- complete producer--consumer--death mapping for every private payload class;
- a direct proof of augmented-signature equivalence;
- explicit disclosure that the memory ledger is an active-object proxy rather than RSS or a
  reference-count proof.

The remaining mandatory chain is

```text
Researcher--Engineer AGREED
-> Skeptic DESIGN PASS
-> new implementation only
-> implementation freeze
-> Researcher theory/interface mapping PASS
-> Skeptic SPEC-TO-CODE PASS
-> optional read-only checkcode
-> explicit authorization of the unique command
-> one ecap-a3 formal run
-> review-3-2c.md
```

At every stage, an honest finite failure or unresolved cap is an acceptable result. A smaller
interval is never a reason to alter this contract.
