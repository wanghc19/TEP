# I1 discrete operator readiness

## 当前状态

状态为 `I1_2_M48_PASS_WITH_CONDITIONS / I1_2_EMPIRICAL_READY`。I1.1 已冻结当前 empty-center
missing-column 模型的离散 $A_{\mathrm{def}}$、unsafe-chart graph 后备，以及 one-cell pencil
到 half-guide Cauchy subspace 的链条。低阶 $M=5,8$ mechanism oracle 保持通过；新的
MATLAB static run 又在实际 trace 带宽 $M=48$、$K=97$ 上直接生成 coarse/fine one-cell
maps，并使 block/action、original/reversed QZ、stable/Cauchy projectors、代数 Dirichlet
chart、DtN action 和 $A_{\mathrm{def}}^{D/G}$ Schur 门全部通过。四个 QZ pass 均为
97 stable / 97 unstable、0 neutral / 0 indeterminate；最大 QZ residual 与 coarse/fine
projector change 分别为 $5.25\times10^{-15}$ 和 $7.06\times10^{-15}$。

本轮不形成或施加 Sylvester/Kronecker separation operator。缺少 production separation
只作为 `IMPORTANT CAVEAT`：当前 chart 只称为代数上条件良好，不称 perturbation-certified。
这不阻止经验型 I1.3 参数连续性、$A_{\mathrm{def}}'$ 开发和 candidate reconnaissance；
但 locator 结论、contour、root isolation、真实 eigenvalue 声明和 theorem-level conditioning
仍保持 `STOP`。

## 本目录

- [[research/projects/eig-apost/implementation/i1/design|design.md]]：当前离散
  $A_{\mathrm{def}}$ 的唯一设计权威，含空间、基、符号、维数、QZ、chart、组装、导数和
  实现契约。
- [[research/projects/eig-apost/implementation/i1/review|review.md]]：记录两项独立
  Skeptic 的多轮审查、已修复 blocker、剩余 caveat 和授权边界。本阶段没有数值结果，
  因此不创建 `result.md`。
- [[research/projects/eig-apost/implementation/ROADMAP|ROADMAP.md]]：只记录新路线 I1--I4
  项目级依赖和退出条件。

## I1 内部里程碑

| Milestone | 内容 | 当前状态 | 下一门 |
|---|---|---|---|
| I1.1 理论设计 | 连续 $\mathcal F$ 对应、empty-center $A_{\mathrm{def}}^{D/G}$、符号、尺寸和失败策略 | `PASS WITH CONDITIONS` | design-level blocker 为 0 |
| I1.2 half-guide 到 $A_{\mathrm{def}}$ 的联合验证 | 人工装配、真实 one-cell 双向 QZ、Cauchy graph/safe DtN 和两种 $A_{\mathrm{def}}$ 表示 | `PASS WITH CONDITIONS` | direct $M=48$ static empirical chain 通过；production separation 未计算但不阻止经验推进 |
| I1.3 参数扰动、连续性和 $A_{\mathrm{def}}'$ | 固定分支、subspace transport、导数、adjoint/Gram 与平衡一致性 | `AUTHORIZED -- EMPIRICAL` | 先做最小 real-$k$ stencil、projector/chart 连续性与 $A_{\mathrm{def}}'$ 数值检查；不得作 root 声明 |
| I1.4 locator readiness | anchored branch、小复圆盘、factor/pole ledger、必要负例与 anti-collapse | `NOT AUTHORIZED` | 需 I1.3 通过；通过后才可设计 locator |

## 权威和证据边界

连续真实谱对象仍由
[[research/projects/eig-apost/phase4-report/method.tex|continuous DtN/BIE method]] 定义。
I1 的当前设计只是它的有限维实现合同；OP-M0 的 kernel--field、continuous-to-cell、
analyticity 和 regular spectral approximation 证明缺口仍由
[[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 管理。

历史 numerical qualification 可作为部件证据，但不等于当前 $A_{\mathrm{def}}$ 已通过。
I1.2 当前实验入口与权威 MATLAB 报告分别为 `test/i1/hg-adef/README.md` 和
`test/i1/hg-adef/output/prod-full/report.md`。低阶报告
`test/i1/hg-adef/output/real/report.md` 保持为 mechanism evidence；旧
`output/prod-pilot/report.md` 已明确标为 non-authoritative matrix-free exploration。
统一历史实验入口见
[[test/archive/legacy-route-v1/README#I4-DLP-TRACE-V1|I4-DLP-TRACE-V1]]；旧 augmented-BIE 和
finite-tail 只从
[[research/projects/eig-apost/implementation/archive/legacy-route-v1/README|legacy route v1]] 追溯。

## 推荐阅读顺序

1. [[research/projects/eig-apost/implementation/i1/design|I1 design]]。
2. [[research/projects/eig-apost/implementation/i1/review|I1 review]]。
3. [[research/projects/eig-apost/implementation/open-problems#M0|M0 ledger]] 和
   [[research/projects/eig-apost/implementation/open-problems#Current I1|current I1 ledger]]。
4. [[research/projects/eig-apost/phase4-report/method.tex|continuous method]]。
