# Phase 3 analysis

本目录把 Phase 2 的来源结论转化为可反驳的误差分解、estimator 定义和数值验证协议。
它不修改 MATLAB，不把候选公式称为定理，也不生成论文正文。

[[research/projects/eig-apost/phase2b-novelty/r-gate|Phase 2b novelty gate]] 已给出
`PASS WITH CONDITIONS`。本轮 Phase 3 design 的 adversarial verdict 为 `REVISE`；
本目录只能优先推进 C4--C5 的
最小离散证明义务、root qualification 和 independent-reference 设计；在 gate 的剩余
全文与证据条件闭合前，不冻结 novelty claim，也不进入 prototype。

- [[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]]：从
  single-cell BIE scattering map 到 finite-tail DtN 和 guided-mode operator 的数据链。
- [[research/projects/eig-apost/phase3-analysis/s-root|Root qualification]]：区分实轴奇异值
  极小点与实际 NEP root，并给出 analytic contour + bordered complex root protocol。
- [[research/projects/eig-apost/phase3-analysis/s-errors|Error budget]]：误差来源、冻结/变化
  参数和隔离测试。
- [[research/projects/eig-apost/phase3-analysis/s-estimator|Candidate estimator]]：
  coarse-tail correction、条件化区间、反例、diagnostics、effectivity 和接受标准。
- [[research/projects/eig-apost/phase3-analysis/p-benchmark|Benchmark plan]]：双椭圆
  benchmark、reference-truth ladder 和数值表设计。
- [[research/projects/eig-apost/phase3-analysis/p-implement|Implementation route]]：后续实现
  顺序、接口边界和停止条件；当前只作计划。
- [[research/projects/eig-apost/phase3-analysis/p-paper|Publication route]]：候选理论阶梯、
  发表门槛、退路和暂定论文结构。

Phase 3 的完成门槛是：每个误差指标都有明确计算对象和失败解释，每个实验只改变一类
误差源，并且 reference truth 的独立性层级不会被夸大。
