# I9.5 eq-temple-v1：加权 RT2 通量、局部化界与预解式 Temple 估计

本实验实施 [[research/projects/eig-apost/phase3-analysis/fem-bound/s-eq-temple|s-eq-temple]] §8 的第0–1步，
冻结输入为 I9.3 `compare-v1/output/attempt-1/run-02/evidence.mat` 的原生曲边 $P_2$ 场。
不重解 FEM、不搜索候选、不读取 BIE 数据、不改网格或 $k_h$。

## 计算内容

1. **第0步**：重建 I9.4 的插值加一次边平均 RT2 通量。在 $\mu_h$、$s=\mu_h$ 处计算 B.1 式(9) 与定理 B。式(9) 的值应复现 I9.4 的 $\eta=0.670573$。
2. **Rayleigh 商**：$\mu_{\mathrm R}=\int|\nabla u|^2/\int\rho|u|^2$，使用真实 $\rho$、Q10 叶片积分。
3. **第1步**：
   - 对 $s\in\{\mu_h/2,\mu_h,2\mu_h\}$，在全局准周期 RT2 空间（约10.2万复未知数）上最小化 s-eq-temple 式(6) 的加权泛函，残差参数取 $\mu_{\mathrm R}$。
   - 另在 $s=\mu_h$ 处运行无权的 B.1 式(28) 对照。
4. **评价**：每个通量两遍直接积分，得到定理 B 的逐元 $\eta_K$（两分支取小）与 B.1 式(9)。由此给出：
   - 无条件线性界：$\mu_h$ 处的 B.1 式(15)，经推论 C3 转移；
   - 条件 Temple 半径 $x_T$：$\lambda_+\in\{2.1875^2,4,3\}$；
   - 下侧推论 C2 诊断：$\lambda_-=1.451^2$。
5. **积分诊断**：主通量（加权，$s=\mu_h$）的 Q8 与 Q10 之差。

所有输出是普通双精度估计（`UNCERTIFIED_ORDINARY_ARITHMETIC_ESTIMATE`）。条件结果依赖未认证的单侧谱隙假设 $\mathrm H^+$。

## 运行

从工作树根目录执行：

```sh
python3 test/i9/eq-temple-v1/run_eq.py --mode formal \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --input test/i9/compare-v1/output/attempt-1/run-02/evidence.mat \
  --output test/i9/eq-temple-v1/output/attempt-1/run-01
```

- 输出目录必须不存在。
- 启动器每秒采样进程树 RSS，硬限为 3,000,000,000 bytes 与 40 分钟；检测到其他 MATLAB 时拒绝启动。
- `--mode smoke` 只缩小积分阶与细分，用于调试，不作科学结果。
- 科学参数唯一来源为 `eq_temple_i95_config.m`。

第2步（有限 Floquet 尾）用 `--tail GLUE_CELL TAIL_CELLS` 运行，构造见 `eq_tail_build_i95.m`：
- 在 $x=\pm(c_g+1/2)$ 处粘接；
- 相邻 lead 胞元用原 FEM 的 $\rho_h$ 与 8 阶求积组装，内部消元后解 24 阶二次特征问题，取 24 个衰减乘子；
- 精确匹配墙迹，追加若干平移胞元，最外墙置零。

此时只评价 $s\in\{\mu_h/2,\mu_h\}$，不做 Q8 检查。

## 运行记录（attempt-1）

| run | 内容 | 墙钟/s | 峰值 RSS/bytes | 退出 |
|---|---|---:|---:|---|
| `smoke-01` | smoke，第0–1步调试 | 20.8 | 1,374,289,920 | 0 |
| `run-01` | formal，第0–1步 | 358.9 | 1,202,831,360 | 0 |
| `smoke-02` | smoke 回归：加入尾选项后 formal 路径不变（与 smoke-01 打印值逐位相同） | 19.1 | 1,299,300,352 | 0 |
| `smoke-tail-01` | smoke 尾，$c_g=3$、10 胞元 | 16.8 | 1,778,860,032 | 0 |
| `run-02` | formal 尾，$c_g=3$、10 胞元 | 428.1 | 1,591,689,216 | 0 |
| `run-03` | formal 尾，$c_g=1$、12 胞元 | 432.4 | 1,578,287,104 | 0 |
| `run-04` | formal 尾，$c_g=5$、8 胞元 | 416.8 | 1,618,427,904 | 0 |

另有一次操作性失败：shell 循环在 zsh 中未拆分参数，`--tail` 解析失败，MATLAB 未启动，无输出目录。修正命令后即为 run-02–04。
全部科学计算合计约 28.5 分钟，单次不超过 7.3 分钟，峰值 RSS 不超过 1.78 GB。

## 结果

汇总由 `summarize_eq.py` 从各 `result.json` 生成，见 `output/attempt-1/summary.json`。主要数值（普通双精度，未认证）：

| 情形 | $\eta_B$ | 其中端项 | 线性 $R(\mu_h)$ | $x_T$（$\lambda_+=2.1875^2$） |
|---|---:|---:|---:|---:|
| I9.4 平均通量（第0步）：B.1 式(9) | 0.67057 | 0.00733 | 1.7198 | — |
| I9.4 平均通量（第0步）：定理 B | 0.33114 | 0.00733 | 0.7867 | 0.314 |
| run-01 无权 LS，$s=\mu_h/2$ | 0.01240 | 0.00342 | 0.02376 | $3.92\times10^{-4}$ |
| run-01 无权 LS，$s=\mu_h$ | 0.01177 | 0.00307 | 0.02601 | $4.24\times10^{-4}$ |
| run-03 尾 $c_g=1$，无权 LS，$s=\mu_h/2$ | 0.00793 | $3.0\times10^{-6}$ | **0.01519** | **$1.60\times10^{-4}$** |

- 第0步式(9) 逐位复现 I9.4：$\eta=0.6705728416$，$U=1.0000007242$。
- 所有优化通量的内部与准周期物理法向连续性缺陷不超过 $4.2\times10^{-13}$；最小二乘相对残差不超过 $5.3\times10^{-11}$。
- run-01 主通量的 Q8/Q10 差：$\eta_B$ 变化不超过 $1.8\times10^{-6}$。
- 加权 LS（$\theta=1$）在定理 B 下一致略差于无权 LS：振荡权 $C_{P,K}^2$ 很小，最优点保留较大振荡，交叉项 $(\varepsilon+C_P\omega)^2$ 因而偏大。两者都是有效界，按设计取小。
- 尾部数据：
  - 两侧最大衰减乘子模为 $0.377$ 与 $0.384$；
  - 墙迹匹配残差不超过 $6\times10^{-16}$；
  - 闭合墙相对振幅：$c_g=1$ 时约 $10^{-5}$，$c_g=3$ 时约 $7\times10^{-5}$，$c_g=5$ 时约 $5\times10^{-4}$；
  - 合并节点值缺陷不超过 $1.3\times10^{-16}$；场的准周期与外墙零值均精确成立。
- 尾部试探场的 Rayleigh 商 $\mu_{\mathrm R}=2.428791044$，比 $\mu_h$ 低 $1.62\times10^{-5}$。条件结论为 $\sigma(A)\cap[\mu_{\mathrm R}-x_T,\mu_{\mathrm R}]\ne\varnothing$，于是 $\operatorname{dist}(\mu_h,\sigma(A))\le1.76\times10^{-4}$，对应 $k$ 半宽约 $5.6\times10^{-5}$。

**限制：**
- 全部为普通算术估计。
- 条件结果依赖未认证的 $\mathrm H^+(\mu_{\mathrm R},2.1875^2)$。
- 未决材料片（面积 $0.0156$）在定理 B 中只用逐点射线分类加 Q8/Q10 差作诊断，没有完整的材料包络。
