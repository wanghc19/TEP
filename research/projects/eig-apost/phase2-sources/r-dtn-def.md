<!-- Per-source evidence cards for periodic half-guide DtN definitions -->

# DtN definition evidence cards

状态：第一轮原文核验完成。以下各卡只记录单篇来源，不在本文件中进行跨来源综合。

## Fliss (2013)

- **文献：** S. Fliss, *A Dirichlet-to-Neumann Approach for the Exact Computation of
  Guided Modes in Photonic Crystal Waveguides*, SIAM J. Sci. Comput. 35(2),
  B438--B461, DOI `10.1137/12086697X`。
- **核验介质：** 本地 `ref/ref_data/Fliss2013.pdf`；PDF 第 11、13、18--20 页已逐页视觉核验。
- **问题与空间：** 固定轴向准周期参数 $\beta$，在左右周期半带 $B^+$、$B^-$ 上，
  给人工截面 $\Gamma_a^+$、$\Gamma_a^-$ 的 Dirichlet trace，解对应的半带问题。
- **独立定义：** 对给定 $\phi \in H_\beta^{1/2}(\Gamma_a^{\pm})$，令
  $u^{\pm}(\beta,\alpha;\phi)$ 为整个半带上的唯一解，再定义
  $\Lambda^{\pm}(\beta,\alpha) \phi = \mp \partial_x u^{\pm}\big|_{\Gamma_a^{\pm}}$。原文同时以
  $H_\beta^{-1/2}$--$H_\beta^{1/2}$ 对偶给出弱定义，见式 (4.1)。
- **定义域例外：** 除本质谱外，还可能有半带齐次 Dirichlet 特征值形成的可数例外集；
  Remark 4.2 指出 Robin-to-Robin 坐标可绕过这一 DtN 定义障碍。
- **有界化：** Theorem 4.5 把无界 guided-mode 问题精确等价为缺陷带上的非线性
  DtN 特征值问题，并保持重数。
- **构造而非定义：** 传播算子 $P$ 由相邻单胞截面 trace 的平移定义；四个局部
  DtN 块 $T_{pq}$ 来自两个单胞 Dirichlet 问题；$P$ 是
  $T_{10} P^2 + (T_{00}+T_{11})P + T_{01}=0$ 中谱半径小于一的解；随后
  $\Lambda^+=T_{00}+T_{10} P$，见 Theorem 4.12 和式 (4.16)。
- **数值离散：** 第 20 页算法明确用有限元或混合有限元求单胞问题及 $T_{pq}$，再用
  二次特征值分解或 modified Newton 求 Riccati 方程。
- **适用性限制：** 该文给出目标 PDE/DtN 框架，但没有 BIE 离散误差分析，也没有
  guided eigenvalue 的后验误差 estimator。

## Joly--Li--Fliss (2006)

- **文献：** P. Joly, J.-R. Li, S. Fliss, *Exact Boundary Conditions for Periodic
  Waveguides Containing a Local Perturbation*, Commun. Comput. Phys. 1(6),
  945--973, DOI `10.4208/cicp.2006.v1.p945`。
- **核验介质：** 本地 `ref/ref_data/Joly2006.pdf`；PDF 第 8--10、19 页已逐页视觉核验。
- **设置：** 吸收 Helmholtz 方程的周期半波导；物理解由正吸收选定。
- **局部构造：** 第 8 页由左右端 Dirichlet 数据定义两个单胞解及四个局部
  DtN-like 块 $T_{pq}$；传播算子 $R_\varepsilon$ 是谱半径小于一的 stationary Riccati
  解；式 (4.11) 给出 $\Lambda_\varepsilon^+=T_{00}^+ + T_{10}^+ R_\varepsilon^+$。
- **数值离散：** 第 19 页用截面上的分片常数空间；为 $2N$ 个单胞问题采用
  $H(\operatorname{div})\times L^2$ mixed formulation 与最低阶 Raviart--Thomas 有限元。故该实现不是
  BIE。
- **限制：** 无耗散极限通过 limiting absorption 讨论；本文当时没有证明传播算子
  普通特征函数完备性。该缺口不能被本文数值实验自动补足。

## Coatléven (2012)

- **文献：** J. Coatléven, *Helmholtz Equation in Periodic Media with a Line Defect*,
  J. Comput. Phys. 231(4), 1675--1704, DOI `10.1016/j.jcp.2011.10.022`。
- **核验介质：** 本地 `ref/ref_data/Coatleven2012.pdf`；PDF 第 8--10、19--20 页已逐页视觉
  核验。
- **独立定义：** 第 8 页先对人工截面的 Dirichlet 数据 $\phi$ 解吸收半条带问题
  $w^{\pm}(\phi)$，再以有符号 $\partial_x w^{\pm}$ 定义 $\Lambda^{\pm}$；这是精确人工边界条件。
- **构造：** 第 9--10 页以两个单胞问题定义局部 $T_{pq}$，以谱半径小于一的传播算子
  $R$ 解同一类 Riccati 方程，并由 Theorem 4.4 得 $\Lambda=T_{00}+T_{10} R$。
- **数值离散：** 第 19 页明确使用经典 Lagrange finite elements；离散单胞问题生成
  $T_h$，二次方程生成 $R_h$，再得到 $\Lambda_h$。故“Coatléven 全部采用有限元”
  对本文数值部分是正确的。
- **误差结果边界：** 论文中的主要误差估计服务于吸收强迫问题、Floquet--Bloch
  积分和空间截断。Remark 5.5 明确说明无吸收情形的完整辐射/唯一性框架仍缺失；
  这些结果不能直接作为实频 guided eigenvalue 的 DtN 后验估计。
