# I3 provenance archive

## 阶段定位和状态

`RETIRED AS CURRENT GATE / HISTORICAL PROVENANCE EVIDENCE`。I3 保存 root-readiness proxy
诊断及 source-derived provenance closure。最终历史结论是 `PASS WITH CONDITIONS`，但其
后续 `GO` 已撤销，不能授权当前 complex-$k$、locator 或 root 工作。

## 文件

- [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness|root_readiness.md]]：
  保存受控 proxy/chart diagnostic 与 provenance-closure 的冻结设计。
- [[research/projects/eig-apost/implementation/archive/i3-provenance/root_result|root_result.md]]：
  保存第一轮诊断和 Section I provenance-closure 的结果及 claim boundary。
- [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness_review|root_readiness_review.md]]：
  保存纠错审查历史；Section L 是该历史 provenance closure 的最终 verdict。

## 实验产物入口

- 受控诊断：`test/root-ready/output/`
- provenance closure：`test/root-ready/provenance-closure/output/`
- 最终 repeat 报告：
  [[test/root-ready/provenance-closure/output/repeat/report|provenance repeat report]]

## 复用和替代关系

source manifest、shared-array fingerprint、instrumented copy 和事务化 artifact publication
机制可以复用。I3 不再是 current gate；它已由 M0 的 continuous DtN/BIE formulation gates
及其后续全新 theory-to-code contract 取代。
