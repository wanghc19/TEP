# 状态

更新日期：2026-11-04。

## 已完成

- 单一算例（$\beta=0.5$）的截断误差意义下可靠的包含区间、(H) 认证、舍入误差估计、加速探针，见 [[research/projects/fem-goerisch/README|README]] 的链接。

## 进行中

- 无。FEM 线暂停（见 [[research/projects/fem-goerisch/DECISIONS|DECISIONS]] 2026-11-04 条）。

## 第 2a 步：常规流程首版（2026-11-04，astra 完成，经理核查）

[[research/projects/fem-goerisch/implementation/pipeline-v1|pipeline-v1]]：`test/fem-goerisch/pipeline-v1/` 复现现有算例，原设置的 $E,M,S_+$ 与四角端点和 qj-cert-v2 逐位相同，$I_1=[2.4286785150,\,2.4287788272]$ 与论文一致；快设置端到端实测 393 秒、2.31 GiB，宽 $4.554\times10^{-9}$。支持范围只有芯区 $\rho$（要求 $\rho_{\rm center}>1$）；(H) 浮点检查（2b）和换参数试跑（2c）未做。

## 代码清单（2026-11-04，astra 完成，经理核查）

[[research/projects/fem-goerisch/implementation/code-inventory|code-inventory]]：只改芯区（引线、切口、$\beta$、窗口不变）时 (A)、(B)、(C) 可原样复用，只需重做试探场、$E,M,S$ 与 (D)，按已有记录约 12 分钟；整链重算约 67–85 分钟，其中约 55 分钟是 (H) 的认证 (A)–(C)；BIE 路线没有对应步骤（它的 670 秒只给无保证的估计）。可靠区间本身（试探场与 $E,M,S$）约 718 秒，快设置约 389 秒。最难的是几何：同一曲线的解析界在多处各写一份，必须合并成一个曲线对象。

## 下一步

- FEM 线暂停。若恢复：2b（(H) 浮点检查，OP-FG-4）、2c（一个 $\rho_{\rm center}$ 试跑）、严格验证提速（OP-FG-5）。
