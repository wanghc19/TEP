# I4：独立 reference 与可靠上界研究

## 当前状态

I4.1 literature/method research 已完成，独立
[[research/projects/eig-apost/implementation/i4/method-review|method review]] 的最终 verdict 为
`PASS WITH CONDITIONS`。随后 `femref-a1` attempt 按冻结的
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]] 实施；同一 Skeptic 在
[[research/projects/eig-apost/implementation/i4/review-4-1a|review-4-1a]] 完成 design、
spec-to-code 和 post-run gates。当前权威终态为 review §BB 的
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

I4.2 的 reliable enclosure、projected gap、存在性和可计算上界仍不在本次范围内。

## 文件权威顺序与阅读顺序

1. [[research/projects/eig-apost/phase4-report/method.tex|current continuous method]] 与
   [[research/projects/eig-apost/implementation/i3/README|I3 guide]]：固定 continuous problem、
   estimator claim boundary 和 I4 handoff；
2. [[research/projects/eig-apost/implementation/i4/search-plan|frozen search plan]]、
   [[research/projects/eig-apost/implementation/i4/search-log|search log]] 和
   [[research/projects/eig-apost/implementation/i4/sources|source verification matrix]]：固定检索、
   访问和原文核验链；
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
`review-4-1a.md`。§BB post-run gate 已关闭；`run-007/execution-001` 已作为完整 empirical-candidate run
消费，不得重跑。任何新方法、attempt或effectivity comparison都需要新的明确授权和完整 gate。

## Claim boundary

I4.1a 已产生field-bearing empirical FEM candidate及完整四轴observed sensitivity，且selection path未使用I3 estimator、
BIE density、QZ eigenvector或历史reference output。由于winner为`gap-edge-or-safe-buffer / weakly-localized`且bulk gap
仍 unresolved，该结果不能提升为continuous guided-mode/eigenvalue existence、唯一mode或certified reference；
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ 不是误差上界。当前estimator尚未与该reference比较，I4.1 effectivity validation
未完成也未获授权；I3证书、公式和历史结论均不改变。
