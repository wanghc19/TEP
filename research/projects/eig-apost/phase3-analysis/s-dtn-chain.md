# 从 I2 数据到连续弱残量

## 1. 连续物理对象先于矩阵

固定 Bloch 参数 $\beta$。连续正自伴算子 $A$ 的特征值参数是 $\lambda=k^2$。I2 的
$A_{\mathrm{def},h}^D(k)$、BIE density、QZ 子空间和离散 DtN 只用于产生 candidate 和重构
数据；它们不定义连续真值。

I3.1 在 I2 保存的 $\widehat k_h$ 处重构物理场。是否存在附近 finite determinant zero 对这
一步不是前提。

## 2. 主线 global residual 与可选 center residual

### 2.1 Global-field residual

在中心缺陷区域和有限个左右普通胞元中，由 I2 density、Rayleigh/Fourier coefficients 和
cell maps 重构分片场。然后：

1. 修复共享接口上的 Dirichlet trace，使场属于连续 form space；
2. 保持横向 Bloch 准周期条件；
3. 在更远胞元用预先固定的光滑 cutoff 衰减到零；
4. 把修复和 cutoff 自身产生的 defect 保留在 residual 中。

最终得到非零 $u_h^{\mathrm c}\in V$。该路线不需要把 numerical half-guide tail 证明成 exact
continuous tail；tail 与 cutoff 的代价直接进入 residual。

### 2.2 Exact-DtN center residual

另一选择是在中心域能量空间 $V_\beta(\Omega_0)$ 上使用连续 exact DtN：

$$
\langle\mathcal F(k)u,v\rangle
=a_0(k;u,v)
-\sum_{\varsigma\in\{-,+\}}
\langle\Lambda_\varsigma(k)\gamma_\varsigma u,
\gamma_\varsigma v\rangle.
$$

若实际只能计算 $\Lambda_{\varsigma,h}$，就必须把
$\Lambda_{\varsigma,h}-\Lambda_\varsigma$ 的影响单列为未知或另行估计。把 numerical DtN 同时
用于构造 candidate 和 residual，只能得到 partial/discrete residual，不能冒充 continuous
residual。即使 exact DtN 可得，还需要带已知常数和 tail allowance 的 outgoing
extension/lifting inequality，把 center residual norm 联系到 global form residual；否则不能
直接套用 global self-adjoint spectral proposition。

首个设计固定使用 global residual；其代价是 field repair 与 cutoff。exact-DtN residual 降为
OPTIONAL，其代价是 exact/numerical DtN 差异及 extension/lifting。若以后启用，不得把两条
路线各自缺失的部分互相省略后拼成“总 residual”。

### 2.3 已完成的中心空列特殊 baseline

当前 homogeneous empty center column 允许更短的 global construction：由 I2 的有限 Fourier
墙系数直接得到空列场 $u_0$，乘固定 $\chi(x)=\cos^2(\pi x)$ 后在单胞外延零。端点满足
$\chi=\chi'=0$，所以零延拓场属于强算子定义域，不需要跨材料界面或胞元接口修复。
`center-a1` 已计算该场的连续 strong residual，并得到 ratio $22.43882099031153$。

这一路线完整计入了固定 cutoff defect，但该 defect 恰好主导结果，使名义区间过宽。因此它
关闭了“能否构造一个真正 conforming 的非零连续场”这一最低问题，却没有交付有用分辨率的
estimator。下一设计必须改变 reconstruction 思路并重新冻结；不得在同一 attempt 中扩大 cutoff。

## 3. Residual decomposition

无论选择哪条路线，都要逐项说明是否包含：

- 每个材料子域内的体方程 defect；
- 材料界面的 field continuity 与 flux jump；
- 胞元接口和人工截面的 trace/flux mismatch；
- 横向准周期边界 mismatch；
- Rayleigh/Fourier truncation 与未保留 tail；
- field reconstruction、trace repair 和 cutoff defect；
- quadrature、field evaluation 和 linear solve error。

一个 sampled mismatch 表或原离散矩阵 residual 只能作为其中一项诊断，不能替代完整的
$V'$ residual functional。

## 4. Conforming 与 broken reconstruction

最清楚的首选对象是确定性的 conforming reconstruction $u_h^{\mathrm c}\in V$。若只得到
broken $H^1$ 场 $u_h^{\mathrm b}$，设计必须给出：

1. broken space 和所有 jump 的定义；
2. 从 $u_h^{\mathrm b}$ 到 $u_h^{\mathrm c}$ 的修复算子，或等价的 nonconforming residual
   分解；
3. 修复稳定性和其可计算误差；
4. 场范数非零门，防止归一化数值噪声。

完整 BIE density--kernel 双射不是使用 conforming field residual 的必要前提：只要实际重构场
非零并属于 $V$，谱残量命题即可应用。该双射仍决定能否把所有物理 mode 由 BIE 完整表示，
因此限制方法完备性，但不应挡住首个 residual indicator。

## 5. 当前真正义务

首个 `design-3-1.md` 已对中心空列特殊 baseline 关闭 continuous operator、field domain、
residual decomposition 与普通数值积分门。若继续 I3.1，当前需要：

1. 选择并冻结 cutoff defect 更小的 lead-aware conforming reconstruction，或 continuous weak
   residual；
2. 列出新 residual 的全部已含与未含 components；
3. 若使用 weak residual，给出 dual norm 的可计算近似和数值不确定度；
4. 先保证新的 field/residual 信号达到预注册分辨率，再考虑 reliable enclosure 与 gap
   certification。

不再要求 common finite-matrix transport、nearby finite zero、matrix $k$ derivative、Schur
zero equivalence 或 bordered conditioning。它们只属于可选 finite-matrix correction。
