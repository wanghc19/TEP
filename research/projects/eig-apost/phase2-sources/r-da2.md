<!-- Phase 2 devil's-advocate checkpoint -->

# Phase 2 checkpoint

结论：`PASS WITH CONDITIONS`，允许建立 Phase 3 analysis 目录，但不允许实现 MATLAB
prototype 或宣称 estimator 已验证。

## 已关闭的门槛

- DtN 已从半波导边值问题独立定义；没有从 trace-subspace 反向命名。
- FEM/Riccati 文献与三类 BIE--DtN 构造已区分。
- 已找到与当前代码直接兼容的非模态路线：`A_QP -> cell scattering map -> finite-tail
  doubling -> half-guide map -> DtN`。
- simple-root operator perturbation 已给出首版 projected correction 的文献依据。
- 当前需要的可下载全文已按仓库规则保存到 `ref/ref_data/`。

## Phase 3 必须保留的 Major 条件

1. $j$ 只能表示 finite-tail doubling depth；不得同时暗含 port order、BIE quadrature
   或 algebraic solver tolerance。
2. $\delta_j$ 在没有 saturation/tail evidence 时只估计 $k_{j+1}-k_j$，不得写成
   $\lvert k_j-k_* \rvert$ estimator。
3. $I+R_j$ 的可逆性、Cayley transform 的条件数和左右端口法向符号必须单独检查。
4. `bloch.construct_S` 的 cell scattering accuracy 仍是固定但非零的误差；Phase 3
   必须安排在高精度 DtN 下改变 `ntot` 的 falsification test。
5. 由同一个 cell map 得到的 doubling 与 QZ/Riccati 极限，只能算 infinity-treatment
   的独立算法交叉检查，不能单独充当整个 $k_*$ 的双方法 reference truth。

## 当前无 Critical issue

在非 Wood、远离单位圆、孤立简单根的明确限制下，没有发现阻止进入分析设计阶段的
文献或实现结构矛盾。若实际 benchmark 无法产生稳定 projected gap 或 isolated root，
则回退到几何筛选，不修改 estimator 定义来迁就数据。
