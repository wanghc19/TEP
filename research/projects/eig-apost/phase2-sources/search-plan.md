<!-- Reproducible Phase 2 search plan for periodic half-guide DtN and BIE coupling -->

# Phase 2 search plan

## Search Questions

1. 在 fixed-$\beta$ periodic half-guide 中，Dirichlet-to-Neumann operator 如何不依赖
   trace-subspace 而独立定义？其定义域、值域、法向约定和例外参数是什么？
2. Joly、Fliss、Coatléven 及后续工作如何从 cell problems、propagation operator 或
   Riccati equation 构造/离散 DtN？哪里使用 FEM，哪里只给连续理论？
3. BIE 文献所谓“直接计算 DtN”具体指 Calderón boundary operators、逐 Dirichlet datum
   的 boundary solve、Schur complement，还是 periodic half-guide 的其他构造？
4. 哪些来源把 BIE 与 artificial-boundary DtN coupling 用于 Helmholtz/waveguide/eigenvalue
   计算，并报告可用于 reference truth 的数值数据？
5. simple nonlinear eigenvalue 对 operator-function perturbation 的一阶位移公式、
   backward error/condition number 区分和可计算 two-level estimator 分别需要什么假设？

## Search Layers

1. 本地原文：`ref/ref_data/Joly2006.pdf`、`ref/ref_data/Fliss2013.pdf`、`ref/ref_data/Coatleven2012.pdf` 及其参考文献。
2. DOI/publisher/author pages：核验元数据、正式版本和定理/算法定位。
3. 学术搜索：补充 `periodic half-guide DtN`、`boundary integral DtN map`、
   `BIE DtN coupling Helmholtz` 和相关同义词。
4. 引用追踪：从纳入来源向前追踪 numerical DtN、BEM/BIE coupling 和 error analysis。

## Query Families

```text
(periodic waveguide OR periodic half-guide) AND
  (Dirichlet-to-Neumann OR DtN) AND
  (propagation operator OR Riccati)

(boundary integral OR boundary element OR Calderon) AND
  (Dirichlet-to-Neumann OR Poincare-Steklov) AND Helmholtz

(boundary integral) AND (DtN OR transparent boundary condition) AND
  (waveguide OR periodic medium)

(guided mode OR nonlinear eigenvalue) AND DtN AND
  (a posteriori error OR residual OR estimator OR convergence)
```

## Inclusion Criteria

- 同行评审论文、正式专著章节或作者/出版社正式版本；
- 给出 DtN 的数学定义、数值构造、BIE--DtN 接口、误差分析或可复查 benchmark；
- Helmholtz、photonic crystal、periodic waveguide 或足以迁移的 boundary-integral setting；
- 英文或中文全文可读；基础来源不限年份。

## Exclusion Criteria

- 只把 DtN 当作未定义黑箱，且没有构造、分析或数值接口；
- 只讨论 trace-subspace 而没有独立 DtN 定义；
- 仅有搜索摘要、二手博客或无法核验的引用；
- 与 elliptic/Helmholtz boundary maps 无可说明迁移关系的材料。

## Verification Rules

- 本地 PDF 只有在回到原文并定位定义/公式/算法后才标记 `verified against original`。
- DOI、题名、作者、期刊、年份必须与正式页面匹配；灰区标记 unverified，不补造信息。
- 文献声称“direct DtN”时必须记录它实际求解的 boundary equation 和离散对象。
- 证据卡只做逐来源描述；Phase 2 只允许为决定下一阶段对象而做有限综合，完整误差
  分解、实验协议和论文主张留给 Phase 3。

## Planned Outputs

- DtN definition/construction evidence cards；
- BIE--DtN interface evidence cards；
- annotated bibliography 与 source verification matrix；
- 可用于下一阶段的定义冲突、算法缺口和 reference-data 候选清单。
