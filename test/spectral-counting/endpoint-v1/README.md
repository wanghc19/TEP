# g12 端点惯性可行性实验

2026-10-28 完成。状态：**ORDINARY_DISCRETE_INERTIA_DIFFERENCE = 1**，普通数值验收通过。没有连续计数认证，没有运行 P3、扫频、求根、场恢复或 Stein 尾部质量计算。

## 固定对象与实现

本实验对应 `research/explorations/spectral-counting/minimal_counting_theorem.md` 的 SC1 理论问题。数值代码不读取该文件或任何 Markdown、Git、历史结果作为参数或运行前提。

当前真实解析材料、$\beta=0.5$、$L=d=1$；中心材料4、两端 inclusion 材料17、背景1；左右三叶形参数分别为0.12、0.20且不镜像。g12 几何网格为12个背景细分、80段解析材料界面，P2 场。中心保留1464个准周期约束后自由度，其中内部1416、左右墙面共48。

两端点明确为谱参数 $\mu=k^2$ 的 $a=2.40$、$b=2.46$。两套积分规则为：

| 规则 | 体积分每方向 Gauss 点 | 薄带细分 | 薄带每方向 Gauss 点 |
| --- | ---: | ---: | ---: |
| primary | 12 | 2 | 8 |
| check | 16 | 4 | 12 |

`endpoint_inertia.m` 从 `test/i10/refine-v1/refine_i102.m` 原样提取47个几何、空间、真实质量修正、单胞消元和 lead DtN helper，来源行记录在 `provenance.csv`。新逻辑构造完整中心矩阵

$$
T_h(\mu)=K_c-\mu M_c+E_W^*\operatorname{diag}(D_-(\mu),D_+(\mu))E_W,
\qquad M_c=M_{h,c}+\Delta M_c.
$$

没有将墙面 Schur 补误当完整中心矩阵。中心内部消元只提供附加记账核对。若该核对不适用，不会因中心 Dirichlet 极点而拒绝完整矩阵计数。

MATLAB R2023b 的稀疏复 Hermitian LDL 路径触发已实现的等价实表示 fallback：对 $B$ 使用 $\begin{bmatrix}\Re B&-\Im B\\\Im B&\Re B\end{bmatrix}$，确认各符号计数为偶数后除以2。矩阵保持稀疏；完整中心实表示维度2928。程序按 $1\times1$ 和 $2\times2$ 枢轴块特征值计数，并保存缩放、置换、阈值、分解及求解残差。实际四个完整矩阵未出现 $2\times2$ 枢轴；独立的解析小矩阵自检覆盖了该分支和复 Hermitian 情形。

## 实际结果

两套积分规则完全一致；下表中的中间列为阈值内未决数，不声称精确零特征值。

| $\mu$ | 完整中心 $(n_-,n_?,n_+)$ | 中心内部 | 墙面 Schur 补 |
| --- | --- | --- | --- |
| 2.40 | (0,0,1464) | (0,0,1416) | (0,0,48) |
| 2.46 | (1,0,1463) | (0,0,1416) | (1,0,47) |

四项 Schur 惯性恒等式全部 PASS；两规则各自的 $-[T_h(b)-T_h(a)]$ Cholesky 分解均成功。所有12项完整／内部／墙面惯性结果通过数值有效性检查，所有8次 lead 响应门检查通过。两种 DtN 公式的一致性检查均实际执行。

| 端点诊断 | $\mu=2.40$ | $\mu=2.46$ |
| --- | ---: | ---: |
| 完整 LDL 最小绝对枢轴块特征值 | $2.5703578\times10^{-2}$ | $4.0175330\times10^{-2}$ |
| 完整 LDL 未决阈值 | $10^{-10}$ | $10^{-10}$ |
| $G=K_c+M_c$ 下所求近零广义特征值的最小绝对值 | $2.325374\times10^{-2}$ | $2.558715\times10^{-2}$ |

上述枢轴数值依赖正对角缩放；$G$ 下数值也不是连续 C1 定理的边界范数余量。两者都不是连续谱距离上界。

全部惯性分解的最大相对重构残差为 $2.1821\times10^{-16}$，完整中心最大值为 $1.2564\times10^{-16}$；全部求解的最大后向残差为 $8.5297\times10^{-17}$。两规则中心质量矩阵的相对 Frobenius 差为 $7.7754\times10^{-14}$，完整端点矩阵差约 $3.4102\times10^{-15}$，仅作积分敏感性诊断。

以下区间合并 primary/check 两规则的结果。QZ 分离量是 $(||\alpha|-|\gamma||)/(|\alpha|+|\gamma|)$，不是连续 band 证书。

| $\mu$ | lead | 稳定维数 | QZ 单位圆分离量 | $\operatorname{rcond}(Z_0)$ | 单胞条件估计 |
| --- | --- | ---: | ---: | --- | ---: |
| 2.40 | left | 24 | 0.446415 | 0.043373–0.043990 | 19166.2 |
| 2.40 | right | 24 | 0.439201 | 0.043310–0.043413 | 18777.2 |
| 2.46 | left | 24 | 0.458382 | 0.043931–0.046155 | 17619.1 |
| 2.46 | right | 24 | 0.451261 | 0.044678–0.045623 | 17247.4 |

最大 lead 单胞求解后向残差 $3.3355\times10^{-17}$，最大 Riccati 残差 $4.5198\times10^{-16}$，最大 DtN Hermitian 缺陷 $4.5010\times10^{-16}$，最大双公式一致性差 $4.6503\times10^{-17}$。

## 命令与资源记录

执行前估计：包括 MATLAB 启动和保存1–3分钟、峰值1.2–1.8 GiB。运行器实际设置30分钟 soft、40分钟 hard、2 GiB hard；0.2秒采样进程树 RSS，达到限额立即终止。仅所有端点完成且处于保存阶段时允许一次有界延长。本轮未申请延长，也未触发限额。

最终验证命令，在本目录执行：

```sh
/Users/whc/opt/miniconda3/condabin/conda run --no-capture-output -n octave python run_endpoint.py \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --order 2 --tag run-02-p2 --prior-seconds 19.7100485
```

启动器实际执行：

```matlab
addpath('/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1');
endpoint_inertia('/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1',2);
```

| 运行 | 说明 | 受控耗时 | 采样峰值 RSS |
| --- | --- | ---: | ---: |
| run-01-p2 | 首次验证，使用系统 `python3` 标准库启动器 | 19.710049 s | 1,190,461,440 bytes |
| run-02-p2 | Conda octave Python；补充验收状态后复跑 | 16.210792 s | 1,236,140,032 bytes |

两轮共享科学运行计时35.920841秒，最终返回码0。最终 MATLAB 入口日志计时2.641秒（含保存）；结果内2.274351秒是进入保存前计时。RSS 是监控器与 MATLAB 子进程树的采样峰值，未观测采样间瞬时峰值。首次结果另存为 `run-01-p2-*`，未覆盖其日志证据。

首轮后的必要修正：将可执行的 Schur 核对及两规则一致性纳入验收字段；仅在 full/center/wall 惯性本身有效且无未决时执行 Schur 判定；新启动覆盖旧 progress 标记，避免历史 done 状态授权延长；删除 MATLAB 明确忽略的 eigs 选项。没有改变数学模型、矩阵公式或两个端点。

## 文件及资格边界

- `results.mat`：完整配置、几何／空间／积分检查、两规则的中心矩阵、两端 DtN、完整 $T_h$、惯性与近零诊断。
- `inertia-p2.csv`：12项惯性及残差；`lead-p2.csv`：8项 lead 响应诊断。
- `summary-p2.json`、`report-p2.txt`：当前结果及验收。
- `run-02-p2.log`、`run-02-p2-monitor.json`、`run-02-p2-resources.csv`：最终命令、退出码、时间及内存证据。
- `validation.json`：CSV／JSON／文本内部一致性及 MAT 的 HDF5 签名核验；没有声称独立重读 MAT 重构所有矩阵。

本实验只确立数值可行性。连续共同 projected gap 尚未认证；整个 $[2.40,2.46]$ 内两侧 half-guide Dirichlet 极点排除尚未证明；有限矩阵符号计算不是区间算术证书；FEM/DtN 到连续端点惯性的提升尚未完成。因此不能由当前普通整数差1宣布存在唯一简单的连续局域模态。两侧三叶形关于切口的全局竖直反射条件不成立，不能直接采用该反射捷径排除 lead 极点。

所有修改与产物均在此新实验目录；未修改旧实验、主线代码或论文，未 commit/push。
