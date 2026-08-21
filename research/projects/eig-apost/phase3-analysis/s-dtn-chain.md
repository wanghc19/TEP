# 从 I2 数据到全局连续残量

## 1. 连续物理对象先于矩阵

固定 Bloch 参数 $\beta$。连续正自伴算子 $A$ 的特征值参数是 $\lambda=k^2$。I2 的
$A_{\mathrm{def},h}^D(k)$、BIE density、QZ 子空间和离散 DtN 只用于产生 candidate 和重构
数据；它们不定义连续真值。

I3.1 在 I2 保存的 $\widehat k_h$ 处构造连续试验场。该场是否接近真物理场由 continuous
residual 判断；是否存在附近 finite determinant zero 对这一步不是前提。

## 2. 主线 global residual 与可选 center residual

### 2.1 Global-field residual

当前首选对象不是 raw BIE 分片场，也不再使用 finite-window cutoff。它由 frozen wall states
生成左右 matrix-power 序列，用 one-cell exterior/interior BIE samples 拟合不改变 wall Cauchy
data 的 bubbles，最终在每个胞元内定义一个单一 smooth Fourier--Hermite/bubble function。
相邻胞元共享 field 和全局 $x$ 导数，材料圆内外使用同一个函数，横向有限 Fourier basis
结构性满足 Bloch 准周期条件。若左右 $H^2$ Gram tails 可和，则所得非零场属于 $D(A)$，可以
直接计算 continuous strong residual。

完整构造、左右 orientation、Müller density signs、定义域证明和 infinite-tail bound 见
[[research/projects/eig-apost/phase3-analysis/s-lead-field|Global lead-aware conforming trial]]。
finite QZ action 在该路线中只参数化 trial；continuous PDE residual 决定 trial 质量。因此既不把
numerical half-guide tail 冒充 exact continuous tail，也不遗漏人工 cutoff defect。

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

当前路线固定使用 global strong residual；其代价是 BIE-informed fit、geometry-fitted volume
quadrature 和 infinite-tail Gram accounting。exact-DtN residual 降为 OPTIONAL，其代价是
exact/numerical DtN 差异及 extension/lifting。若以后启用，不得把两条
路线各自缺失的部分互相省略后拼成“总 residual”。

### 2.3 已完成的中心空列特殊 baseline

当前 homogeneous empty center column 允许更短的 global construction：由 I2 的有限 Fourier
墙系数直接得到空列场 $u_0$，乘固定 $\chi(x)=\cos^2(\pi x)$ 后在单胞外延零。端点满足
$\chi=\chi'=0$，所以零延拓场属于强算子定义域，不需要跨材料界面或胞元接口修复。
`center-a1` 已计算该场的连续 strong residual，并得到 ratio $22.43882099031153$。

这一路线完整计入了固定 cutoff defect，但该 defect 恰好主导结果，使名义区间过宽。因此它
关闭了“能否构造一个真正 conforming 的非零连续场”这一最低问题，却没有交付有用分辨率的
estimator。后续设计改用全局 lead-aware smooth trial；没有在同一历史 attempt 中扩大 cutoff。

### 2.4 Lead-aware 正式负结果

正式 `lead-a3` 的 finite input、density representation 和 frozen-$Z$ propagation 通过，但固定
BIE-informed fit 的 $J=4/8$ holdout error 约为 $4.522421/5.138028$，高于 $0.20$，故在
`CONFORMING_RECONSTRUCTION_UNRESOLVED` 首败处停止。由于 continuous trial 尚未通过重构门，
center correction、field/residual/$H^2$ Grams、tail 和 strong-residual ratio 均未形成。

training/holdout targets 到材料圆仅约为 source-panel arc scale 的 $0.86\%/1.08\%$；当前 direct
close layer-potential evaluation 未单独资格化。因此这个结果证明的是当前 pipeline 没有建立
BIE-informed shape quality，而不是已经证明 bubble basis 或 fit metric 单独失败。详见
[[research/projects/eig-apost/implementation/i3/review-3-1b|independent post-run review]]。

## 3. Residual decomposition

无论选择哪条路线，都要逐项说明是否包含：

- 每个材料子域内的体方程 defect；
- 材料界面的 field continuity 与 flux jump；
- 胞元接口和人工截面的 trace/flux mismatch；
- 横向准周期边界 mismatch；
- Rayleigh/Fourier truncation 与未保留 tail；
- field reconstruction、BIE-fit、center correction 和 infinite-tail allowance；
- quadrature、field evaluation 和 linear solve error。

一个 sampled mismatch 表或原离散矩阵 residual 只能作为其中一项诊断，不能替代完整的
$V'$ residual functional。

## 4. Conforming 与 broken reconstruction

当前首选对象是确定性的 $u_h^{\mathrm c}\in D(A)$。若其他路线只得到
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

`design-3-1.md` 已对中心空列特殊 baseline 关闭 continuous operator、field domain、residual
decomposition 与普通数值积分门；`design-3-1b.md` 又冻结了全波导对象，但 `lead-a3` 在形成该
对象之前止于 fit gate。若继续 I3.1，当前需要：

1. 先用独立、低成本检查区分 near-circle layer-potential evaluation 与 fixed
   Fourier--Hermite/bubble space/metric 的贡献；
2. 只有该区分能改变 reconstruction 设计时，才另行冻结修订或替代路线；不得自动调 basis、
   grid、threshold 或运行下一 attempt；
3. 新 reconstruction 先通过非零、field quality 和 continuous-residual 可计算门，再进入
   field/residual/$H^2$ Grams、infinite tail、reliable enclosure 与 gap certification；
4. 只有退回 weak residual 时，才重新引入 Riesz dual-norm solve。

不再要求 common finite-matrix transport、nearby finite zero、matrix $k$ derivative、Schur
zero equivalence 或 bordered conditioning。它们只属于可选 finite-matrix correction。
