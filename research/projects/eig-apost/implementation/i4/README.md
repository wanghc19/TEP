# I4：独立 reference 与可靠上界研究

## 当前状态

I4.1 literature/method research 已完成，独立
[[research/projects/eig-apost/implementation/i4/method-review|method review]] 的最终 verdict 为
`PASS WITH CONDITIONS`。随后唯一 `femref-a1` attempt 按冻结的
[[research/projects/eig-apost/implementation/i4/design-4-1a|design-4-1a]] 实施；同一 Skeptic 在
[[research/projects/eig-apost/implementation/i4/review-4-1a|review-4-1a]] 完成 design、
spec-to-code 和 post-run gates。最终 artifact verdict 为 `PASS`，科学结果为
`MESH_QUALITY_UNRESOLVED / VALID SCIENTIFIC NEGATIVE / FROZEN M1 METHOD FAILED`：首个
`bulk-s12-g24` mesh 的 reflection stiffness defect 为
$2.410043158511017\times10^{-15}$，但 reflection mass defect 为
$0.014666412555809508>5\times10^{-11}$。运行在 `MESH_ORACLES` fail closed，完成
$0/119$ eigensolves；没有 eigenvalue、field、qualified reference collection 或 effectivity
evidence。该 attempt 已消费，不授权 `run-005` 或同方法重试；任何实质不同方法必须另行设计和
审查。

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

I4.1a 的后续 Researcher--Engineer--Skeptic gate 及全部 bounded revision/retry 已记录在
`review-4-1a.md`。post-run gate 已关闭；其 `FROZEN M1 METHOD FAILED` verdict 禁止在当前
attempt 内继续调网格、oracle 或阈值。

## Claim boundary

方法研究只通过一条 candidate independent-reference 路线及其 resolution/uncertainty 语义；
I4.1a 数值阶段随后在 reference solve 前以有效科学负结果结束。它没有计算
$k_{\mathrm{ref}}$，没有评价 effectivity，也不改变 I3 estimator、BIE density、QZ eigenvector、
证书、公式或历史结论。位置一致、reference resolution 或 estimator validation 均未建立。
