# rounding-estimate：舍入误差估计

本实验估计四角Goerisch区间及隔离假设(H)计算链的舍入效应。结果是估计，不给出可靠误差界。A/B/C/D分别指周期带隙、表面态、Dirichlet-to-Neumann矩阵、核心计数；qj指Goerisch量q和J。

## 入口

- `launch.py`：调用原monitor.py启动复制的MATLAB浮点代码；11线程，OMP_DYNAMIC=FALSE，软30分钟、硬40分钟、3 GiB。
- `high_precision_checks.py`：固定A/D矩阵和相同非负项的观测对照。
- `object_sizes.py`：主节点与缓存转换、相位/几何/代表函数的测量。
- `B_scales.py`：B曲线积分绝对项尺度，不重解响应。
- `estimate_analysis.py`、`write_report.py`：汇总估计、敏感度和报告。

## 结果与复现

完整公式、表、命令和运行成本见 [rounding-estimate.md](../../../research/explorations/numerical-directions/rounding-estimate.md)。主端点估计位移9.05556e-12 / 1.0486e-11，占原宽度0.2029% / 0.2350%。D近贴边移位的比值0.000130753；0.36移位的比值7026.28。观测对照均低于对应估计。

## 启动前预估

A：30–120秒、0.7–1.2 GiB。D：20–60秒、0.8–1.4 GiB。qj正项/模型：240–420秒、2.1–2.7 GiB。场数据导出：90–180秒、1.8–2.4 GiB。C首轮尺度：每侧3–8分钟、1.8–2.6 GiB；补充绝对基项：每侧6–12分钟、1.8–2.6 GiB。每侧累计预计低于30分钟。B的Python尺度诊断：10–60秒、0.2–0.5 GiB。Gauss导出：15–30秒、0.6–0.9 GiB；512位对照预计5–30秒、0.2 GiB。

复现入口（完整运行参数表见上述报告；运行目录须用新编号）：

```sh
python3 test/numerical-directions/rounding-estimate-v1/launch.py --help
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/estimate_analysis.py --experiment test/numerical-directions/rounding-estimate-v1
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/write_report.py
```

## 记录

`output/estimates.json`和CSV保存每行公式和输入；`A-panel-estimates.csv`保存472个面板符号。MAT为MATLAB-v7，仅作为可重生输入。run-011/012/013为Python汇总中的标量/维度/序列化错误记录，run-017记录Gauss比较器的区间包裹；MATLAB运行均完成。`setup_runs.py`是初始复制脚本，已保护为不能覆盖现有源；复现直接使用上述入口。
