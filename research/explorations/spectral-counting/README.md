# 二维周期波导谱计数

本主题研究固定 Bloch 参数下一个区间中的连续模态数量。独立于 interface-threshold 探索及论文主线；不把候选差当真谱或唯一性证据。2026-10-28 用户追加授权本轮自行运行独立数值可行性实验。

阅读顺序：

1. [[research/explorations/spectral-counting/novelty_and_feasibility]]：推荐路线与科研定位。
2. [[research/explorations/spectral-counting/counting_methods_comparison]]：A／B／C 及全文文献核查。
3. [[research/explorations/spectral-counting/minimal_counting_theorem]]：连续计数定理 SC1。
4. [[research/explorations/spectral-counting/continuous_vs_discrete_gap]]：端点惯性认证 C1。
5. [[research/explorations/spectral-counting/claude_experiment_spec]]：保留原指定文件名；现为本轮实际实验规格与记录入口，不再交接 Claude。
6. [[research/explorations/spectral-counting/s-gap-fourier]]：真实二维周期端的连续共同谱隙证明；[[research/explorations/spectral-counting/r-gap-fourier|2026-10-30 结果]] 与 [[test/spectral-counting/gap-v1/README|可靠复现]]。

当前可靠结果：精确解析模型的两侧周期端在 $\mu\in[2.40,2.46]$ 具有共同连续谱隙，全部 Floquet 参数由 25 维 Fourier 见证覆盖，独立算法复算通过。旧 g12/P2 两积分规则给完整中心负惯性 $0\to1$、四项 Schur 记账通过；它仍是普通离散惯性差。状态及唯一未决事项台账：[[research/explorations/spectral-counting/STATUS]]。方向决策：[[research/explorations/spectral-counting/DECISIONS]]。当前尚无该区间的严格连续导模计数证书。
