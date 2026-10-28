# I10：FEM＋DtN 特征值误差估计

更新：2026-10-28。当前唯一里程碑 **I10.1** 的D2正式 `attempt-1/run-02` 已完成。[[research/projects/eig-apost/implementation/i10/review-10-1a#6. R2：D2 run-02 完整结果审查|R2实际结果审查]]裁定 **PASS WITH CONDITIONS**：最终P4 $k=1.5584378941804409$，条件 $B_4=9.8028871425\times10^{-10}$（$\mu$尺度），完整墙钟127.844845秒、全进程树采样峰值2,508,603,392 bytes。D1失败及R1保留为历史；本次不是无条件连续上界或 $10^{-12}$ 真误差认证，不新建阶段。

## I10.1 当前交付

- [[research/projects/eig-apost/phase3-analysis/fem-bound/s-enrich|方法与证明]]：固定I9.5b二次网格，三模板共同 $P_2/P_3/P_4$ 扩充，真实材料质量、有向同伦带积分、Schur导数的完整无限质量和显式条件误差半径。
- [[research/projects/eig-apost/phase3-analysis/fem-bound/r-enrich|理论与设计独立审查]]：保留D1历史，新增本阶段同一skeptic对D2实际正文的独审；不作为修后实验PASS。
- [[research/projects/eig-apost/implementation/i10/design-10-1a|唯一实验设计D2]]：已执行，原文保留执行前合同；三模板共同P2/P3/P4、真实材料质量、预测与独立根、30–40分钟及3GB预算。
- [[research/projects/eig-apost/implementation/i10/review-10-1a#6. R2：D2 run-02 完整结果审查|实际结果审查R2]]：六链求根及定位修复通过本次检验，交付 $B_4,R_0,R_N$；保留S/E条件及分辨/成本口径。独立实际审查不以D2设计PASS替代。

原candidate $k_0=1.558438079544167$。给出的半径依赖明确的 $\mathrm S_{1/2}$ 饱和性和 $\mathrm E$ 数值评价假设；它们尚未证明，三层比和积分阶差不代替证明。BIE只作最后外部对照。真实材料在各层方程中重新装配，避免共同逼近近似材料后误解释层间差。

本阶段启动时新建Researcher和skeptic，本次复用这两位审实际源码与原始结果，不引入Engineer；模型与effort继承主agent。Codex只做理论/设计/审查，Claude负责授权范围内的实现/实验，不改研究文档。run-01及全部失败/规模探针保留，sizing-03零权矩阵和谱量未作为run-02科学输入。本次接收后停止，不自动追加P5、扫描或认证工程。

当前数值：原candidate条件半径 $R_0=5.7873603285\times10^{-7}$，预测条件半径 $R_N=1.6629701812\times10^{-9}$，均为 $\mu$尺度；最终 $B_4$对应最大 $k$半径 $3.14510\times10^{-10}$。P4与BIE的 $k$差约 $1.65\times10^{-12}$ 已在本轮规则/求根分辨尺度内，不能作真实误差。31.3秒只是P4账目子链，非完整估计或实测冷启动成本；主结果一律引用127.844845秒。

背景仅链接复用：[[research/projects/eig-apost/phase3-analysis/fem-bound/p-next#11. 研究路线复评：从维护估计器转向评价特征值|研究转向依据]]、[[research/projects/eig-apost/implementation/i9/review-9-5b|I9.5b求解器审查]]、[[research/projects/eig-apost/implementation/i9/review-9-6a#9. R2：D2 run-03 实际结果审查|I9.6阴性结果及资格边界]]、[[research/projects/eig-apost/implementation/ROADMAP|总路线图]]。

## I10.1 唯一问题账目

分类相对于本次条件方法与实验设计；尚未验证的条件不阻断首轮探索，但阻断升级为无条件连续上界。

| ID | 分类及影响范围 | 最小检查/落实 | 当前状态 |
|---|---|---|---|
| I101-1 连续模态与饱和性 | important caveat：同一连续目标及 $\mathrm S_{1/2}$ 未证明 | run-02同模相关及 $q_{\rm obs}=0.001211$ 支持当前解释，不证明条件；不调q、不用BIE校准 | CONDITIONAL；NUMERICALLY SUPPORTED |
| I101-2 真实质量评价 | important caveat：$\epsilon_p=10^{-10}$ 为未认证的总评价预算；B4仅为底项3.27倍 | 三模板真实质量已进入六链；两规则差小于 $10^{-11}$、根宽达标，仍不能证明E或BIE末位真精度 | IMPLEMENTED；E UNVERIFIED |
| I101-3 导数与预测 | important caveat：预测与验证根差低于评价尺度，不能解释为已解析Newton余项 | 完整质量/导数诊断及独立check根已完成；质量状态已从根资格分离，异常抛出隔离尚非全覆盖 | SUCCESS PATH VERIFIED；NO RERUN REQUIRED |
| I101-4 预算与成本 | important caveat：31.3秒不含B4必需P3和冷启动，不能把剩余工作全视为可省诊断 | 统一引用全墙127.844845秒、采样峰值2.508603392GB；不作同保证提速比 | FULL RUN WITHIN BUDGET；COST INTERPRETATION CORRECTED IN R2 |
| I101-5 阶段结论范围 | minor caveat：MATCH仅计数；常数缺陷为记录非自动门；预算占30.6%非主导；预测早于check根非所有P3根 | R2已按源码/实值纠正，实验原记录保留；不以报告措辞重跑实验 | R2 CLARIFIED |
| I101-6 薄带双解veto | 原blocker已关闭：D1错误门已撤，真实边检查保留，H/权重未改 | 两规则全部点定位成功、0错胞、0负重心owner；本实例无需后备定位认证 | CLOSED FOR RUN-02 |
| I101-7 数值零与括区 | minor caveat：特殊数值零/未分辨路径本次未行使 | 六链真实异号末端/宽度均达标，源码不再伪造零宽；保留未触发路径边界 | FORMAL ROOTS VERIFIED；FALLBACKS NOT EXERCISED |

本次研究助手审查没有运行MATLAB/数值实验、修改实验代码/main、安装依赖或stage/commit/push。没有操作goal，也没有替用户发送Claude消息。
