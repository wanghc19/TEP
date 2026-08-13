# Phase 3 analysis

本目录把 Phase 2 的来源结论转化为可反驳的误差分解、estimator 定义和数值验证协议。
它不修改 MATLAB，不把候选公式称为定理，也不生成论文正文。

2026-08-13 路线复审后，当前项目级权威改由
[[research/projects/eig-apost/implementation/ROADMAP|implementation ROADMAP]]、
[[research/projects/eig-apost/implementation/i2/README|I2 guide]] 和
[[research/projects/eig-apost/implementation/i3/README|I3 guide]]，并由
[[research/projects/eig-apost/phase4-report/method.tex|continuous method]] 共同维护。连续
self-adjoint real eigenvalue 决定实轴优先；有限维结构缺陷进入误差预算，而非搜索许可门。
本目录中以 finite-tail、complex-first、exact-finite-root 或 doubling 为默认的段落是历史或
条件方案，只有明确写入现行权威链的部分才构成当前计划。若某个 estimator 公式需要 simple
finite root，该条件只约束该公式，不构成整个 I2--I3 的预设目标。

[[research/projects/eig-apost/phase2b-novelty/r-gate|Phase 2b novelty gate]] 已给出
`PASS WITH CONDITIONS`。本轮 Phase 3 design 的 adversarial verdict 为 `REVISE`；
本目录只能优先推进 C4--C5 的
最小离散证明义务、root qualification 和 independent-reference 设计；在 gate 的剩余
全文与证据条件闭合前，不冻结 novelty claim，也不进入 prototype。

- [[research/projects/eig-apost/phase3-analysis/s-dtn-chain|DtN computation chain]]：从
  single-cell BIE scattering map 到 finite-tail DtN 和 guided-mode operator 的数据链。
- [[research/projects/eig-apost/phase3-analysis/s-root|Root qualification]]：区分 real-axis
  constrained candidate、finite NEP zero 与 continuous eigenvalue；complex protocol 只作
  异常触发的局部 fallback。
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
