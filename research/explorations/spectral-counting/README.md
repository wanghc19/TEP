# 二维周期波导谱计数

本主题研究固定 Bloch 参数下一个区间中的连续模态数量。独立于 interface-threshold 探索及论文主线；不把候选差当真谱或唯一性证据。2026-10-28 用户追加授权本轮自行运行独立数值可行性实验。

阅读顺序：

1. [[research/explorations/spectral-counting/novelty_and_feasibility]]：推荐路线与科研定位。
2. [[research/explorations/spectral-counting/counting_methods_comparison]]：A／B／C 及全文文献核查。
3. [[research/explorations/spectral-counting/minimal_counting_theorem]]：连续计数定理 SC1。
4. [[research/explorations/spectral-counting/continuous_vs_discrete_gap]]：端点惯性认证 C1。
5. [[research/explorations/spectral-counting/claude_experiment_spec]]：保留原指定文件名；现为本轮实际实验规格与记录入口，不再交接 Claude。
6. [[research/explorations/spectral-counting/s-gap-fourier]]：真实二维周期端的连续共同谱隙证明；[[research/explorations/spectral-counting/r-gap-fourier|2026-10-30 结果]] 与 [[test/spectral-counting/gap-v1/README|可靠复现]]。
7. [[research/explorations/spectral-counting/s-half-gap]]：已验收的实际切口半条带排谱及统一谱距；[[test/spectral-counting/half-gap-v1/README|可靠复现]]。
8. [[research/explorations/spectral-counting/s-box-count]]：已验收的连续唯一简单导模计数；[[test/spectral-counting/box-count-v1/README|有限箱可靠复现]]。
9. [[research/explorations/spectral-counting/s-model-bridge]]：源码 binary64 字面量的解析模型及显式几何邻域；[[test/spectral-counting/bridge-v1/README|从数学常量完整重现]]。

当前可靠结果：精确解析模型、固定 $\beta=1/2$，在 $\mu=k^2\in(2.40,2.46)$ 中恰有一个简单条带 $L^2$ 导模本征值。两端周期谱隙、实际半条带无极点和完整中心惯性已由新 Fourier/有限箱证明链认证，独立验收通过；补充鲁棒证书覆盖源码 binary64 字面量的解析解释。旧逐位执行、网格、g12/P2 结果及高精度误差半径没有被自动升级。状态及唯一未决事项台账：[[research/explorations/spectral-counting/STATUS]]；方向决策：[[research/explorations/spectral-counting/DECISIONS]]。
