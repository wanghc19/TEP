# I4：独立 reference 与可靠上界研究

## 当前状态

I4.1b quadratic fitted-P2 FEM 已按
[[research/projects/eig-apost/implementation/i4/design-4-1b|design-4-1b]] 完成；
[[research/projects/eig-apost/implementation/i4/review-4-1b#AE. Final post-run review of run-002/execution-002|review §AE]]
给出最终 `PASS WITH CONDITIONS`。Create-once
`run-002/execution-002` 已完成并消费，完成 $61/61$ 次 solve；field-based simple root-9
track为 `[8,32,55,78,101]`，并给出

$$
\lambda_{\mathrm{pre}}=3.3672400220423246,
\qquad
k_{\mathrm{pre}}=1.8350040931949783,
$$

$$
(\delta_h,\delta_g,\delta_N,\delta_\vartheta,\delta_{\mathrm{tol}})
=(7.2025200175129811\times10^{-5},
2.7115316763854924\times10^{-3},
3.1239311426567440\times10^{-7},0,0),
\qquad
\Delta_{\mathrm{ref}}^{\mathrm{obs}}=0.0027838692696748879.
$$

Whole-command wall为 $232.450046$ s，aggregate peak RSS为 $1055391744$ B。权威实现与artifact入口为
[[test/i4/femref-a2/README|femref-a2 attempt guide]]。该结果仅是geometry-dominated、
non-certified empirical P2 reference candidate；field identity、localization、empirical parity与17相位
bulk sampling不证明continuous guided-mode existence或certified bulk gap，
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$也不是误差上界。尚未进行或授权estimator effectivity comparison。

I4.1 literature/method research 已完成，独立
[[research/projects/eig-apost/implementation/i4/method-review|method review]] 的最终 verdict 为
`PASS WITH CONDITIONS`。随后 `femref-a1` attempt 按冻结的
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]] 实施；同一 Skeptic 在
[[research/projects/eig-apost/implementation/i4/review-4-1a|review-4-1a]] 完成 design、
spec-to-code 和 post-run gates。基础 empirical-candidate 终态为 review §BB 的
`PASS WITH CONDITIONS / SCIENTIFIC_READY / FEM_REFERENCE_CANDIDATE_READY`：create-once
`run-007/execution-001` 已自然完成并消费，完成 $119/119$ 次 solve、collection size $16$；48-root fine
spectra 已覆盖 $W_3$，未进入 conditional 60-root rung。Lexicographic winner 为 candidate $7$，
$\lambda_{\mathrm{ref}}^{\mathrm{FEM}}=3.3697211020626927$、
$k_{\mathrm{ref}}^{\mathrm{FEM}}=1.8356800108032698$，且

$$
(\delta_{\mathrm{FEM}}^{\mathrm{obs}},
\delta_{\mathrm{supercell}}^{\mathrm{obs}},
\delta_{\mathrm{twist}}^{\mathrm{obs}},
\delta_{\mathrm{alg}}^{\mathrm{obs}})
=(0.0019799758723477723,
3.3059115711608911\times10^{-5},
3.0119180025600656\times10^{-6},0),
$$

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}=0.0020160469060619413.
$$

Winner分类为 `cue-member / gap-edge-or-safe-buffer / weakly-localized / stable-parity-assignment /`
`empirical-resolution-complete / spectrum-covered-through-W3`，同时bulk仍为
`BULK_GAP_UNRESOLVED_DIAGNOSTIC`。Whole-command elapsed 为 $140.273679$ s，authoritative aggregate peak
RSS 为 $1353826304$ B，低于 $2700$ s/$2147483648$ B hard uppers。该artifact只是
`EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY`：$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 是non-certified
observed sensitivity sum，不是continuous error upper bound；结果不证明continuous eigenvalue/guided-mode
existence，也未进行或授权effectivity validation。`run-007`已消费且不得重试。先前`run-006`的§AW合法科学负结果
仍作为历史记录保留，不再是当前权威终态。

随后sample-out `run-008/execution-001`在单一fitted $(N,s,g)=(5,30,60)$ mesh上完成五个twist solves；
mesh 含 $11741$ nodes、$22760$ triangles和$11380$ reduced DOFs。Pure-FEM ranking的canonical winner仍为
candidate $3$，$(\lambda_{30},k_{30})=(0.61502508946098011,0.78423535336082628)$。后续独立field audit以
common-core mass-compatible overlap、continuation、localization和parity证据支持旧candidate $7$对应new candidate $9$，其
candidate-specific值为

$$
\lambda_{30}^{(7)}=3.366203342658638,
\qquad
k_{30}^{(7)}=1.834721598133798.
$$

这不改写canonical candidate $3$。四点candidate-specific profile报告

$$
(d_{12\to18},d_{18\to24},d_{24\to30})
=(-0.0052814302919568235,-0.001979901415371188,-0.0009584126670008075),
$$

$$
(\rho_1,\rho_2)=(0.37487977799998845,0.4840709035106812),
\qquad
r_{\mathrm{pred}}=4.794533798202494\times10^{-6}.
$$

七起点QR variable-projection fit的lexicographic winner为start $6$，

$$
p=1.8129679837413033,
\quad k_\infty=1.8327935034213265,
\quad C=0.9181205139250015,
\quad \mathrm{SSE}=4.302174060684754\times10^{-12}.
$$

Late positional comparison为
$|k_{30}^{(7)}-k_{\mathrm{BIE}}|=0.0019513090256411125<0.0029097217$，故冻结strict boolean为true；
它不参与mode selection。Review §BT给出`POST-RUN PASS WITH CONDITIONS`：全流程累计wall为
$110.055849$ s，peak RSS为$1073594368$ B。`run-008`、`identity-003`和`profile-001`均已消费，不得重跑。
Profile为`EMPIRICAL_NON_CERTIFIED`且`effectivity_performed=false`；该位置比较、drifts和fit均不是certified bound、
continuous eigenpair existence证明或effectivity validation。

I4.2 的 reliable enclosure、projected gap、存在性和可计算上界仍不在本次范围内。

## 文件权威顺序与阅读顺序

1. [[research/projects/eig-apost/phase4-report/method.tex|current continuous method]] 与
   [[research/projects/eig-apost/implementation/i3/README|I3 guide]]：固定 continuous problem、
   estimator claim boundary 和 I4 handoff；
2. [[research/projects/eig-apost/implementation/i4/search-plan|frozen search plan]]、
   [[research/projects/eig-apost/implementation/i4/search-log|search log]] 和
   [[research/projects/eig-apost/implementation/i4/sources|source verification matrix]]：固定检索、
   访问和原文核验链；[[research/projects/eig-apost/implementation/i4/r-validation|validation-practice
   literature audit]] 专门区分 solver validation、estimator effectivity 与 certification；
3. [[research/projects/eig-apost/implementation/i4/methods|candidate methods]]：保存候选、后备和
   排除路线的公平比较；
4. [[research/projects/eig-apost/implementation/i4/method-4-1|I4.1 method manuscript]]：本轮方法主稿；
5. [[research/projects/eig-apost/implementation/i4/method-review|independent method review]]：独立
   Skeptic verdict。若与方法稿冲突，以 review 对“是否通过方法门”的判断为准，但 Skeptic
   不替代 Researcher 改写方法稿；
6. [[research/projects/eig-apost/implementation/i4/design-4-1a|frozen I4.1a design]]：冻结本次
   continuous model、branch inventory、信息隔离、refinement、预算和失败状态；
7. [[research/projects/eig-apost/implementation/i4/review-4-1a|I4.1a review ledger]]：本次 design、
   theory-to-code、spec-to-code、retry、artifact 和 post-run verdict 的最终审查权威入口；
8. [[test/i4/femref-a1/README|femref-a1 attempt guide]]：实现与 append-only run artifact 入口。
9. [[research/projects/eig-apost/implementation/i4/design-4-1b|frozen I4.1b P2 design]]：冻结
   quadratic fitted-FEM、branch/refinement、信息隔离、预算和失败状态；
10. [[research/projects/eig-apost/implementation/i4/review-4-1b|I4.1b review ledger]]：I4.1b
    design、theory-to-code、spec-to-code、artifact、资源、数值结果和最终claim boundary的审查权威；
11. [[test/i4/femref-a2/README|femref-a2 attempt guide]]：P2实现、create-once artifacts和已验证结果入口。

项目级阶段和 unresolved concern 仍分别以
[[research/projects/eig-apost/STATUS|project STATUS]]、
[[research/projects/eig-apost/implementation/ROADMAP|ROADMAP]] 和
[[research/projects/eig-apost/implementation/open-problems|open-problem ledger]] 为准。本目录不
复制第二套状态或 open-problem ledger。

## Researcher--Skeptic gate

1. Researcher 先按冻结的 [[research/projects/eig-apost/implementation/i4/search-plan|search plan]]
   完成检索、原文核验、来源维护、候选综合和 `method-4-1.md` 初稿；
2. Skeptic 只写 `method-review.md`，独立检查 continuous-problem matching、方法独立性、mode
   identification、reference resolution、信息隔离、引用支持和范围边界；
3. `REVISE` 只把限定问题交回同一 Researcher；修订后由同一 Skeptic 复审；
4. 只有 unresolved `blocker` 可以阻止未来进入 `design-4-1.md`。`PASS` 或
   `PASS WITH CONDITIONS` 也不自动授权实验设计或运行。

I4.1a 的后续 Researcher--Engineer--Skeptic gate 及全部 bounded revision 已记录在
`review-4-1a.md`。§BB的`run-007` gate与§BF/§BQ/§BT的`run-008`、identity及profile gates均已关闭；
相应create-once identities已消费，不得重跑。任何新方法、attempt或effectivity comparison都需要新的明确授权和完整 gate。
I4.1b 的 P2 gate 已在 [[research/projects/eig-apost/implementation/i4/review-4-1b|review-4-1b §AE]]
关闭；`run-002/execution-002` 已消费且无重跑理由。

## Claim boundary

I4.1a 已产生field-bearing empirical FEM candidate及完整四轴observed sensitivity，且selection path未使用I3 estimator、
BIE density、QZ eigenvector或历史reference output。由于winner为`gap-edge-or-safe-buffer / weakly-localized`且bulk gap
仍 unresolved，该结果不能提升为continuous guided-mode/eigenvalue existence、唯一mode或certified reference；
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 不是误差上界。Sample-out candidate-7 profile与late-BIE strict positional boolean也只
增加empirical convergence/location evidence，不改变这一边界。当前estimator尚未与该reference比较，I4.1 effectivity
validation未完成也未获授权。I4.1b P2结果增加了独立的field-bearing empirical candidate及五轴
resolution evidence，但geometry component占主导且bulk证据仍是有限相位sample，因此同样不能提升为continuous existence、
certified gap或reference-error bound；I3证书、公式和历史结论均不改变。
