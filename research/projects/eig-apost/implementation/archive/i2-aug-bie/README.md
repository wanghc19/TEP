# I2 augmented BIE archive

## 阶段定位和状态

I2 是历史 augmented BIE 与 finite-tail center coupling 的离散代数阶段。原
`STAGE2_DISCRETE_ALGEBRA_GO` 和 `ROOT_READY=STOP` 保持不变；该矩阵不再定义当前主问题。

## 文件

- [[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie|aug-bie.md]]：
  冻结中心 BIE/port blocks、九组 unknown/row order、density scaling、elimination 和失败门。
- [[research/projects/eig-apost/implementation/archive/i2-aug-bie/aug-bie-review|aug-bie-review.md]]：
  保存 final Skeptic review、实现审计、适用范围及旧 verdict。

## 实验产物入口

- 实验目录：`test/aug-bie/`
- 入口函数：`test/aug-bie/run_aug_bie_experiment.m`
- 报告：[[test/aug-bie/output/report|augmented BIE report]]

## 复用和替代关系

中心 transmission BIE、wall trace blocks、density-coordinate 修正和 availability/failure
ledger 可能复用，但必须重新建立 theory-to-code map。旧的 finite-tail/remote-closure coupling
需要由 continuous center BIE 与 PDE-defined DtN 的 discrete graph/DtN coupling 替换。
