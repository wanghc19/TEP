# DtN definition and BIE construction synthesis

状态：Phase 2 第一轮综合；不是定理证明，也不是实验实现说明。

## 1. 目标对象的独立定义

固定实 $\beta$ 和试探波数 $k$。以右半波导为例，给人工截面 $\Gamma_+$ 上的
Dirichlet trace $\phi$，先解完整右半波导问题：场在纵向满足 $\beta$-准周期条件，在
非周期方向属于由当前频率区间选定的衰减/物理解空间，并满足材料界面的传输条件。
若此问题唯一可解，则定义

$\Lambda_+(\beta,k) \phi = \partial_{n_+} u_+(\phi)\big|_{\Gamma_+}$，

其中 $n_+$ 必须固定为中心有界域或半波导的哪一个外法向；后续矩阵装配不能混用。
自然映射是 $H_\beta^{1/2}(\Gamma_+) \to H_\beta^{-1/2}(\Gamma_+)$。左端同理。

这一定义只依赖半波导边值问题，不依赖 trace-subspace、Bloch basis、Riccati 方程、
FEM 或 BIE。Fliss (2013) 第 11 页即按此顺序定义，并在 Theorem 4.5 中把它作为精确
人工边界条件。

## 2. Riccati 在哪里出现

Riccati 方程不是 DtN 的定义，而是利用周期性计算它的手段：

1. 在一个普通 bulk cell 内，以左右端 Dirichlet 数据解两个局部问题。
2. 由左右端法向导数形成四个 cell DtN blocks $T_{00},T_{01},T_{10},T_{11}$。
3. 求相邻 cell Dirichlet trace 的传播算子 $P$；在目标的严格 gap/简单设置中选取
   谱半径小于一的 Riccati 解。
4. 用 $\Lambda_+=T_{00}+T_{10} P$ 恢复半波导 DtN。

Joly、Fliss、Coatléven的数值实现都在第 1 步用有限元。因而“保留 BIE”的自然切入点
不是抛弃 Riccati，而是用 BIE 生成 cell boundary map，再保留第 3--4 步。

## 3. BIE 文献中“直接算 DtN”至少有三种含义

### 3.1 Calderón operator quotient

对边界闭合、介质齐次的有界域，Green 表示和 jump relations 给出 trace 方程。
在 Lu--Lu (2014) 的归一化下，可写成

$\Lambda=(K'-I)^{-1}T$。

这是从边界积分算子直接得到 DtN，但包含 hypersingular operator，并在内部谱点附近
有可逆性/条件数问题。它只解决一个有界子域的 Cauchy data 转换，不包含周期半波导
的稳定分支选择。

### 3.2 Special-solution trace quotient

Yuan--Lu--Antoine (2008) 不在单胞外边界上求任意 Dirichlet BVP，而是构造一组已满足
单胞内部 PDE/transmission 条件的特殊解。若其 Dirichlet trace matrix 为 $U$，Neumann
trace matrix 为 $Q$，则直接形成

$\Lambda_h=Q U^{-1}$。

特殊解由 inclusion-boundary transmission BIE 多右端求得。该方法与当前 `A_QP` 的
可复用组件最接近，但 $U$ 的病态会使加密后精度反而下降；原文已观察到这一点。

### 3.3 BIE unit-cell RtR plus half-array Riccati

Petropoulos--Turc (2025) 先用层势与 Fourier/Sommerfeld wall representation 直接计算
unit-cell Robin-to-Robin map，再以 operator Riccati equation 求半无限阵列 transmission
map。这是目前检索到与“BIE + 半无限周期端”最接近的完整数值架构。它也说明改用
RtR 可以避开纯 Dirichlet chart 的例外频率。

## 4. 不能混淆的两个“直接”

- 由稳定 Bloch traces 组成 $Q_- U_-^{-1}$ 也能形成 DtN 矩阵，但这是以 stable trace
  subspace 为计算坐标。它可作独立算法或交叉验证，不能反过来充当 DtN 的首要定义。
- 2026 年 Lu--Shen--Zhang 的 background-Green BIE 是透明边界条件的另一种实现；它
  不应仅因功能相似就改名为 Fliss half-guide DtN。

## 5. 对当前项目的初步判断

### 来源直接支持

- Fliss 的 PDE DtN 定义可以不经过 trace-subspace 独立陈述。
- BIE 可以直接构造有限单胞/齐次子域的 DtN 或 RtR map。
- BIE 生成的 unit-cell map 可以与 Riccati/doubling 结合处理半无限周期重复。
- 非 Wood、远离单位圆的假设正好避开已知最严重的数值退化区，但不自动保证所有
  离散矩阵良态。

### 由多来源推得的工作假设

- 对当前穿透椭圆 inclusion、固定 $\beta$ 的 cell，可尝试用现有 QP BIE 生成 cell
  RtR/DtN 数据，再用 Riccati 得到半波导 DtN。
- 这条路线比直接把现有 trace-subspace matrix 称为 DtN 更适合作为第一阶段理论对象；
  但它的可行性仍需写出与现有 `A_QP` 完全一致的 port problem 后才能确认。

### 尚未得到支持

- 没有来源证明现有 `A_QP` 可以原样、不加 port unknown 或 auxiliary wall
  representation 地输出 Fliss 的 cell DtN blocks。
- 没有来源给出目标 guided eigenvalue 的现成 a posteriori DtN error estimator。
- $\sigma_{\min}$ 的 `1e-3--1e-5` 平台不能从现有文献直接解释为同量级的 $k$ 误差。

## 6. Phase 3 的最小路线

1. 写清与现有 BIE 一致的 single-cell port problem，并决定首版用 DtN 还是 RtR
   坐标；理论上优先 RtR 以避开 cell Dirichlet poles，最终再转换到 center DtN。
2. 建立三层数值对象：`cell map -> half-guide map -> nonlinear guided-mode matrix`。
3. 对每一层分别定义可加密参数和差分量，不把一个总奇异值当成所有误差的代理。
4. 初始双椭圆 benchmark 固定 inclusion quadrature，只加密 port/Fourier dimension 或
   doubling/Riccati tolerance；随后固定高精度 DtN，再做 BIE 点数反证测试。
5. reference truth 优先用两条独立链：
   `BIE cell map + Riccati` 与 `large finite-cell recursive doubling/Schur limit`；若二者
   不足，再加入独立 FEM/supercell 或可靠 published data。
6. 文献已支持的 eigenvalue-sensitivity 骨架，是将 DtN perturbation 通过左右 null
   vectors 和 $k$ 导数投影，而不是直接使用 $\sigma_{\min}$：

   $\eta_{\mathrm{DtN}} \approx \lvert y^* \Delta F_{\mathrm{DtN}}(k_h) x \rvert / \lvert y^* F'(k_h) x \rvert$。

   该一阶结构已由 Güttel--Tisseur 的 matrix perturbation formula 和 Moskow 的
   operator correction formula 支持；但把 $\Delta F_{\mathrm{DtN}}$ 替换成两个数值 DtN 层级之差
   以后，它首先只预测相邻层级根位移。若要估计到精确 DtN 的剩余误差，还必须验证
   saturation/geometric-tail 假设。详见 `r-nep-error.md`。

## 7. 当前 estimator 目标的强度

首版不以宽泛 certified upper bound 为目标，也不满足于 indicator。建议以
**asymptotically quantitative estimator** 为论文最低目标：在独立 $k_{\mathrm{ref}}$ 上报告
effectivity $\eta/\lvert k_h-k_{\mathrm{ref}} \rvert$，要求跨代表性参数保持同量级，并随 DtN refinement
趋向稳定常数，理想情况下趋近 $1$。严格上下界是后续可选强化。

## 8. Phase 3 对首版 DtN hierarchy 的修订

首版把精确对象仍定义为半波导 DtN $\Lambda$，但用稳定的 scattering coordinate
计算它：

1. 固定 inclusion BIE quadrature、proxy/QP Green 参数和 Rayleigh channel dimension。
2. 用现有 `bloch.construct_S` 及 `A_QP` 生成一个 bulk cell 的 scattering blocks。
3. 以 Schur/Redheffer doubling 生成 $N=2^j$ 个 bulk cells 的 finite-segment
   scattering map。
4. 首版实根 sequence 在远端施加 homogeneous Dirichlet（另以冻结的 real Robin
   交叉检查），再由 terminated reflection 的 Cayley transform 得到同一个固定 port
   space 上的 $\Lambda_j$。zero-incoming sequence 只作 half-guide map 交叉验证。
5. 只改变 $j$，得到 $F_j(k)$、根 $k_j$ 和 projected correction $\delta_j$。

选择理由是：这一路径直接对应“非周期方向有限尾截断”，不调用 trace-subspace mode
selection；结构保持的远端闭合避免把可能离开实轴的泄漏 finite-level root 与实轴
singular-value minimum 混淆。Ehrhardt--Sun--Zheng 为 zero-incoming stop-band
boundary-map limit 提供直接先例，而 `bloch.construct_S` 已提供当前 BIE 到 single-cell
scattering map 的代码接口；Dirichlet/Robin eigenvalue hierarchy 的正确性仍是本项目
需要建立和验证的内容。

首阶段不把 Rayleigh order、BIE node count 或 Riccati solver tolerance 同时作为 $j$。
它们作为固定参数单独记录；完成 DtN effectivity 后，再固定足够大的 $j$ 对 `ntot` 做
用户要求的反证测试。
