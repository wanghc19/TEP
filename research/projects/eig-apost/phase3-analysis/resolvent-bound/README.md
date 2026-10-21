# Resolvent bound：预解式与界面缺陷估计

日期：2026-09-18。工作树 `/Users/whc/Documents/Work/epost`，分支 `codex/epost`。
本专题只研究理论及未来计算接口，未运行数值实验、未创建 `implementation/i6`，未提交 Git。

## 结论与范围

已得到一个经过实际 Researcher–Skeptic 协作审查的显式基线：对全条带物理算子
$A(\beta)=-\rho^{-1}\Delta$，在统一 $C^2$ collar 和有限覆盖重数条件下，
用户式 (4) 对全部 $\mu\in[\mu_-,\mu_+]$ 和 $v\in D(A(\beta))$ 成立。
原有“单连通 inclusion”条件本身不足；本专题明确增加几何正则性和统一性条件，
没有改变 PDE、物理 transmission、准周期条件或算子定义域。

令 $h$ 为双侧 collar 半宽、$\kappa_*$ 为曲率上界、
$\theta=1-h\kappa_*>0$、$N_{\mathrm{ov}}$ 为覆盖重数，并令

$$
c_0=\frac{N_{\mathrm{ov}}}{\theta h},\qquad
c_1=\frac{N_{\mathrm{ov}}h}{2\theta}.
$$

固定无量纲坐标下，原式可取

$$
\boxed{C_{\mathrm{tr}}^2
=\frac{c_0}{\rho_-\mu_-^2}
+\frac{c_0+c_1}{4\mu_-}+c_1\rho_+.}
$$

保留物理单位时，使用 `s-trace.md` 的 (T9)--(T10) 成对加权版本，固定长度
$\ell_*$（例如 $d$），同步改变导数迹权重及值跳跃的对偶权重。
常数只需有限几何、材料、频率参数；无未知谱距离、未知特征函数、全波导求解或胞元数因子。
局部几何证书还给出了不依赖未展开 reach 常数的单射性检验。

raw 场允许值和普通法向导数跳跃，不先构造 lift。通过逐片 Green 恒等式和严格
无穷远截断，在 $U=\|u_{h,M}\|_{\mathcal H}>Q
=C_{\mathrm{tr},\ell_*}\varepsilon_{\partial,\ell_*}$ 时得到

$$
\operatorname{dist}(\mu,\sigma(A(\beta)))
\le\frac{2\mu Q}{U-Q}.
$$

体内 PDE 缺陷和准周期缺陷的附加项均已写明。该结论先是全谱距离界；只有包含区间
落入另行确认的本质谱带隙时，才能解释为离散特征值存在性。分母不正表示当前估计
无信息，不表示 candidate 错误。

**状态：理论基线在明确假设下已证明；足以进入未来 I6 的数值设计。
具体实例的几何常数、全跳跃 $L^2$ 上界、raw 质量下界与分母正性尚未评价，
尚无本实例的可靠谱包含或 effectivity 结论。**

## 阅读顺序

1. [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework]]：全条带定义域、
   唯一界面清单、i5 跳跃符号映射、Green 极限与谱包含。
2. [[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace]]：主定理 T4、完整证明、
   显式常数、几何有限证书、尺度和反例。
3. [[research/projects/eig-apost/phase3-analysis/resolvent-bound/p-numerics]]：有限行 Gram、
   完整 $P_\pm$ 无限尾、raw 质量下界、i5 可复用及必须重评的输入。
4. [[research/projects/eig-apost/phase3-analysis/resolvent-bound/r-theory]]：独立审查、针对性修复、
   复核结论，以及本专题唯一的剩余事项表。

## 来源与记号决定

权威顺序按本轮用户指令：用户明确模型与限制 > main 的最新已初审 draft > epost 最新
i5 和 `residual-bound` 的明确局部定义。只读核对了 main 的 `s-modelproblem.tex`
(`eq:fixed-beta-operator`)、`s-error.tex`，并为胞元宽度和 DtN 名称补读 `s-dtn.tex`。
i5 的后期 (I5.1g-12)--(13) 配对跳跃定义优先于其早期单侧 shared-data 文字。

| 符号/冲突 | 本专题处理与理由 |
|---|---|
| $\Omega_0$ | 单个单连通 inclusion；不引入多分支下标。边界 $C^2$ 是另加假设，不由拓扑推出 |
| $\mathscr E,\Gamma\in\mathscr E$ | 全界面集合与单条界面；在所核对 draft/i5/residual 材料中未发现同名冲突 |
| $\Lambda_\pm$ | 保留给 DtN；旧 residual 模块以 $\Lambda$ 称材料曲线的局部用法在本专题改为 $\Gamma$，不修改旧文件 |
| $L$ | 沿用当前 draft 的背景胞元周期；旧 i5 中 Fourier cutoff 的 $L$ 不直接移植，新接口用 $M$ 并明确定义 |
| $\Sigma,\widetilde\Sigma$ | 沿用 draft 的上、下边；旧 i5 用 $\Sigma$ 泛指人工墙时，本专题写 $\Gamma\in\mathscr E_{\mathrm{art}}$ |
| $a_\Gamma,j_\Gamma$ | 一次物理配对跳跃；材料/人工侧向与旧 draft 的转换见 F3 表，不覆盖旧单侧 $a_{\Gamma,r}$ |
| $\delta_{\mathrm{spec}}$ | 仅谱距离；不覆盖 i5 裸 $\delta$ 的几何用途 |
| $\varepsilon_\partial,\varepsilon_{\partial,\ell_*}$ | 界面缺陷范数；不占用 density 的 $\eta$ |
| $h,\kappa_*,\theta,N_{\mathrm{ov}}$ | 分别为 collar 半宽、曲率上界、Jacobian 下界和重叠次数，均用于可评价常数；$h$ 在本专题不是网格尺寸 |
| $\ell_*,c_0,c_1$ | 对偶权重的参考长度及两个体范数几何系数；为尺度和常数展开所必需 |
| $P_\pm$ | 保留完整传播矩阵；不对角化为独立标量模态 |

其余字母只在其公式旁局部定义；材料波数 $\kappa_{e/i}$ 与曲率
$\kappa_\Gamma,\kappa_*$ 按明确下标区分，裸 $\kappa$ 不另作多义变量。
内积对第一变量线性；积分使用 $\mathrm d$，虚数单位使用 $\mathrm i$。

## 文献核验的边界

主证明自行展开，不调用 Barnett 的谱包含定理来替代当前无限 transmission 问题。

- Alex H. Barnett, Andrew Hassell, Melissa Tacy,
  *Comparable upper and lower bounds for boundary values of Neumann eigenfunctions and tight inclusion of eigenvalues*,
  Duke Mathematical Journal 167(16), 3059–3114 (2018),
  [DOI](https://doi.org/10.1215/00127094-2018-0031)。本地
  `/Users/whc/Documents/Work/TEP_ref/Barnett2018.pdf` 实际是
  [arXiv:1512.04165v2](https://arxiv.org/abs/1512.04165v2)，2016-05-05，40 页。
  核对了该版本 Theorem 1.8、(1.12)--(1.13)（印刷/PDF 页 7）及 (7.1) 与后续
  boundary-trace/resolvent 表达（页 30–32）。其假设依次为上下文中的光滑有界域、
  非零 Helmholtz 解及其特定 Neumann 边界权重；当前无界波导、有材料和人工双跳跃，
  不满足直接适用条件。它只提供思路参照，本文未继承其常数或离散特征基。
- Alex H. Barnett, Leslie Greengard,
  *A new integral representation for quasi-periodic fields and its application to two-dimensional band structure calculations*,
  Journal of Computational Physics 229(19), 6898–6914 (2010),
  [DOI](https://doi.org/10.1016/j.jcp.2010.05.029)。本地 `Barnett2010.pdf` 为
  [arXiv:1001.5464v1](https://arxiv.org/abs/1001.5464v1) 的 25 页稿，
  核对了 (2)--(4)（页 2–3）的普通导数 transmission 和第 2 节的光滑单连通 inclusion
  假设。它不是“2010 Dirichlet sharp inclusion”论文，未把二者混同。

在线仅核对上述原始出版/预印本身份；本轮没有下载文献、没有修改共享参考文献。

## 写入与将来同步

本轮新增/修改严格限于本目录五个 Markdown 文件，主 agent 统一落盘。
实际子代理 Researcher、Skeptic 均只读，不修改正文；协作和复核记录见 `r-theory.md`。
开始时 epost 已有 `ref/README.md`、`ref/reference.bib`、
`research/projects/eig-apost/phase2-sources/search-log.md` 三处未提交修改；保留原状。
main 已有未跟踪 `draft/examples/`，亦未触碰。

用户本轮写入授权优先于通用维护要求；因此没有更新上级 README、STATUS、DECISIONS、
问题台账、i5、residual-bound、draft 或 ref。将来获授权后可同步专题入口、记号冲突处理
和理论状态；本轮的剩余事项仅记录在 `r-theory.md`，不自动晋升为研究主线或论文结论。
