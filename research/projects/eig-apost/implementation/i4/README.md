# I4：独立 reference 与可靠上界研究

## 当前状态

I4.1 本轮 literature/method research 已完成。独立
[[research/projects/eig-apost/implementation/i4/method-review|method review]] 的最终 verdict 为
`PASS WITH CONDITIONS`，没有 unresolved blocker；所选方法已通过方法门，但不授权实验设计、
实现或运行。未来必须满足的 empirical coverage/resolution conditions 以 method review 为准。

I4.2 的 reliable enclosure、projected gap、存在性和可计算上界不在本次范围内。本轮不得创建
`design-4-1.md`、`review-4-1.md`、`report.md`，也不得创建或运行 `test/i4/` 下的内容。

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
   不替代 Researcher 改写方法稿。

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

## Claim boundary

本轮只通过一条未来 independent-reference 方法及其 resolution/uncertainty 语义。它不计算
$k_{\mathrm{ref}}$，不评价 effectivity，不改变 I3 estimator、BIE density、QZ eigenvector、证书、
公式或历史结论。I4.1 的数值实验必须另行授权。
