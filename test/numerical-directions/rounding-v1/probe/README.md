# rounding probe：舍入工具探测

`rounding` 指浮点舍入认证，`probe` 指本阶段的工具检查；rounding-v1 保留给后续实现。本目录只保存探测脚本、微型 MAT 数据与日志。

Python 使用 `conda run -n octave python -I`，python-flint 0.9.0、numpy 2.5.4、scipy 1.18.1。

MATLAB 烟雾检查启动前估计20–60秒、峰值0.7–1.2 GiB，通过 diagnostics-v1/monitor.py，11线程、OMP_DYNAMIC=FALSE，30分钟软限、40分钟硬限、3 GiB。

检查结果见下文；复现命令和完整清单见 [rounding-inventory.md](../../../../research/explorations/numerical-directions/rounding-inventory.md)。

可选D试点已在99行清单完成后启动。export 运行预计30–120秒、峰值0.8–1.3 GiB；Python Arb 验证预计5–25分钟、含监控用MATLAB父进程峰值1.5–2.8 GiB。两阶段均经既有 monitor.py，Python作为受监控MATLAB的子进程。

试点仅冻结导出的 L_cert 双精度矩阵。复矩阵用精确实部与最大虚部绝对值包围，另导出近似负特征向量和秩1修正矩阵的实Cholesky因子。不会把此试点称为完整H的舍入认证。

<details>
<summary>E3试点的证明（从零推导）</summary>

目标是导出的固定 Hermitian double 矩阵 $L$。MATLAB 导出精确实部 $T$ 及最大虚部条目绝对值 $m$；有限浮点的实绝对值与max只做精确选择，故 $\|L-T\|_2\le\|\Im L\|_F\le n m=:d$。所有导出的double在Arb中是精确dyadic数。这个目标不同于把核心组装前面的误差全部包围。

令 $v$ 为任意导出的实向量，$\gamma=36537/100000$，$\tau=8$。设 $R$ 为任意上三角实矩阵、其对角非零，$A=T-\gamma I+\tau vv^T$、$E=A-R^TR$。用Arb复算E的Frobenius上界 $e\ge\|E\|_F$。

定义非负比较递推
$$a_i=\frac{1+\sum_{j>i}|R_{ij}|a_j}{|R_{ii}|},\qquad b_i=\frac{1+\sum_{j<i}|R_{ji}|b_j}{|R_{ii}|}.$$
逐步回代三角系统给出 $\|R^{-1}\|_\infty\le a:=\max a_i$、$\|R^{-1}\|_1\le b:=\max b_i$。因此 $\lambda_{min}(R^TR)\ge1/(ab)$。若严格验证 $eab<1$，则 $A\succeq(1/(ab)-e)I\succ0$。

对 $v^\perp$ 上所有非零向量，$T-\gamma I$ 与A的二次型相同且严格为正。因此 $\lambda_2(T)>\gamma$，继而 $\lambda_2(L)>\gamma-d$。再验证 $v^T T v+d\|v\|^2<0$，即可给出L至少一个负方向。合起来L恰有一个负特征值。全部判断用球的严格比较；无需假设R是真Cholesky因子，也无需假设v是精确特征向量或严格归一。

试点只验证固定导出矩阵。H、材料矩、DtN下界、几何、相位和模型参数的先前舍入误差仍须依清单重算。

</details>

## 检查结果

Python导入、实/复位模式往返、double精确转换均通过；smoke-results.json记录版本和逐项结果。MATLAB微型运行14.2205秒、0.639786 GiB。

E3试点成功：固定导出矩阵负指标1，严格第二特征值下界0.36536998；128位Arb验证2.07482秒，矩阵乘法0.65733秒。含MATLAB监控父进程17.54846秒、峰值1.244492 GiB。上游组装未被本试点认证。

复现命令及完整表见 research/explorations/numerical-directions/rounding-inventory.md。数值记录位于 run-002/science/pilot-export.json、run-003/science/pilot-certificate.json。MAT保存精确实部及虚部最大条目界；无需保存完整虚部矩阵，证明覆盖其整个Hermitian包围族。
