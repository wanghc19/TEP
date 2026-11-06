# Periodic waveguides and eigenvalue problems

Code, research notes and manuscripts on guided modes in two-dimensional
$y$-periodic dielectric waveguides with a line defect.

## 简介

本仓库研究二维 $y$ 周期介质波导及其线缺陷，内容包括 Bloch 模、传输特征值问题、
散射问题，以及固定 $\beta$ 下线缺陷导模的计算和误差界。数值方法有两条路线：

- 边界积分方程（BIE）：在均匀区域用 Rayleigh 展开，在周期半引线中用 Bloch 模展开，
  再通过迹匹配耦合起来；每个引线胞上的 BIE 是 Müller 方程组，准周期 Green 函数
  用基本解方法（MFS）近似；
- 有限元方法加 Dirichlet-to-Neumann 映射（FEM＋DtN）。

## 当前工作

| 专题 | 内容 | 入口 |
| --- | --- | --- |
| bie-enclosure | 用 BIE 候选和谱距离定理，给出导模特征值的可靠包含区间 | [研究](research/projects/bie-enclosure/README.md)、[状态](research/projects/bie-enclosure/STATUS.md)；[实验](test/bie-bound/README.md)；[英文稿件](draft/bie-siam/README.md)；[复现与校验包](release/bie-enclosure-sisc/README.md) |
| fem-goerisch | 用 FEM＋DtN 试探场和 Lehmann–Goerisch 型证书，给出包含区间 | [研究](research/projects/fem-goerisch/README.md)、[状态](research/projects/fem-goerisch/STATUS.md)；[实验](test/fem-goerisch/) |
| eig-apost | 固定 $\beta$ 线缺陷导模的计算与后验误差估计，BIE 与 FEM＋DtN 两条路线 | [研究](research/projects/eig-apost/README.md)、[状态](research/projects/eig-apost/STATUS.md)；实验 `test/i1/`–`test/i10/` |

其他专题和独立探索见 [research/README.md](research/README.md)。两条数值路线的对照检查在
[redteam/](redteam/README.md)，FEM＋DtN 讲义在 [draft/fem-dtn-epost/](draft/fem-dtn-epost/)。
进展和数值结果以各专题的 `STATUS.md` 和实验目录的 `README.md` 为准，首页不汇总。

## 目录结构

```
+bloch/ +kernel/ +op/ +geom/ +scan/ +quad/ +utils/ +viz/   公共 MATLAB 包
benchmark/   公共包的测试与基准（bloch/、qpgreen/）
test/        数值实验，每个实验一个目录
research/    理论与研究记录（中文，Obsidian 库）
draft/       论文稿件与讲义
release/     随论文发布的复现与校验包
redteam/     两条数值路线的对照检查
pre/         报告与幻灯片
ref/         参考文献目录（PDF 不纳入 Git）
vendor/      第三方依赖（除 README 外不纳入 Git）
```

公共包 `+bloch`、`+kernel`、`+geom`、`+scan`、`+viz` 各有 `README.md`，调用或修改前先读。

## 运行环境

- 不需要构建。MATLAB 代码在 MATLAB R2023b 中运行，Octave 不能代替。
- 子目录中的脚本需要把仓库根目录加入 MATLAB 路径（`addpath`）。
- 部分实验和可靠计算用 Python（如 python-flint）；版本见对应实验的 `README.md`，
  以及复现包的 `environment/README.md`。
- 第三方依赖 FMM2D 和 python-flint 的获取和编译方法见 [vendor/README.md](vendor/README.md)；
  SIAM 模板 `vendor/siamart_251216/` 的用法见 [draft/bie-siam/README.md](draft/bie-siam/README.md)。
- 每个实验的入口、参数和复现命令写在该实验目录的 `README.md` 中。

## 工作约定

写作术语、文件命名、代码文档、实验预算和运行规则见 [AGENTS.md](AGENTS.md) 及各子目录的
`AGENTS.md`；Claude Code 另读 [CLAUDE.md](CLAUDE.md)。

## 历史目录

以下目录只保存旧版理论、实现和验证程序，供历史追溯：

| 目录 | 内容 |
| --- | --- |
| [legacy/](legacy/) | 旧版理论笔记、文稿及相关材料 |
| [crystal_2d/](crystal_2d/README.md) | 旧二维周期晶体、空缺陷胞及线缺陷的计算与验证 |
| [waveguide_1d/](waveguide_1d/) | 旧一维周期波导与相关特征值计算 |

当前工作不以这些目录为理论依据、实现范例或结果基准；只有明确要求历史核查、复现或迁移时才使用。
根目录的公共 MATLAB 包仍在使用，不属于历史目录。
