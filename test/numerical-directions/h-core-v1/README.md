# h-core-v1：core count for the isolation hypothesis

`h-core` 指隔离假设 $(H)$ 的核心区域计数。

## 目的

最终空间 $(N_x,N_y)=(31,16)$、维数1122，得到 $n(L_{cert})=1$。第二特征值的安全下界为 0.365373688682，已扣除全部新增积分余项。结合上游输入及独立谱交集前提，Theorem S.2 给出窗口内恰有一个谱点，且为单重特征值。此结论排除舍入。

## 起点与输入

采用 [h-cert-proof.md](../../../research/explorations/numerical-directions/h-cert-proof.md) §5、§6、§7.1，计数形式及迹约定来自 [dtn-inertia-count.md §0](../../../research/explorations/numerical-directions/dtn-inertia-count.md)。独立一阶区间与谱相交的前提取自 [h-cert-problem.md §2](../../../research/explorations/numerical-directions/h-cert-problem.md)：该区间在窗口内部、宽度约 $10^{-4}$、中心约2.4287。本阶段直接使用该已给前提。

两侧矩阵为 h-dtn-v1 的 [left-certificate.json](../h-dtn-v1/left-certificate.json) 和 [right-certificate.json](../h-dtn-v1/right-certificate.json)，分别接在 $x=-1/2$、$x=+1/2$，对应左材料 $a=0.12$、右材料 $a=0.20$。输入系数次序是 $k=-16,\ldots,16$，$g(y)=\sum_k g_ke^{\mathrm i(0.5+2\pi k)y}$，$y\in[-1/2,1/2]$。`input-check.json` 核对了端口、材料、频率、窗口和全迹下界标记。上游 $K_+=279.899894626$ 已进入给定下界矩阵，本阶段直接使用这些下界。

核心真星形与 FEM `direct_native.m/LOCAL_curve` 的 cell_index=0 一致，`direct_native_config.m` 的 star_scale=1：
$$x=0.2(1.5+0.3\cos5\theta)\cos\theta,\qquad y=0.2(1+0.3\cos5\theta)\sin\theta.$$
保持原取向和原坐标。夹杂内 $\rho=4$，外部 $\rho=1$。$q=\lambda\rho+1$，$\lambda=5.6169$，$q_{max}=23.4676$。

## 复现命令

从仓库根目录执行。重跑使用新的 `run-NNN`，并在报告脚本中更新本次两个计数及附加验证的结果路径。无需 MAT 文件或旧的核心矩阵。

```sh
python3 test/numerical-directions/h-core-v1/core_constants.py test/numerical-directions/h-core-v1/constants.json
python3 test/numerical-directions/h-core-v1/launch_core.py --output test/numerical-directions/h-core-v1/output/run-001 --Nx 15 --Ny 8 --nodes 384 --left test/numerical-directions/h-dtn-v1/left-certificate.json --right test/numerical-directions/h-dtn-v1/right-certificate.json
python3 test/numerical-directions/h-core-v1/launch_core.py --output test/numerical-directions/h-core-v1/output/run-002 --Nx 31 --Ny 16 --nodes 512 --left test/numerical-directions/h-dtn-v1/left-certificate.json --right test/numerical-directions/h-dtn-v1/right-certificate.json
python3 test/numerical-directions/h-core-v1/launch_core.py --mode validate --output test/numerical-directions/h-core-v1/output/run-003 --Nx 31 --Ny 16 --nodes 512 --left test/numerical-directions/h-dtn-v1/left-certificate.json --right test/numerical-directions/h-dtn-v1/right-certificate.json
python3 test/numerical-directions/h-core-v1/report_core.py --experiment test/numerical-directions/h-core-v1 --fe test/numerical-directions/gap-ends-v1/output/run-005/analysis.json
```

MATLAB R2023b，11线程，`OMP_DYNAMIC=FALSE`。所有 MATLAB 启动通过 `diagnostics-v1/monitor.py`，软限30分钟、硬限40分钟、峰值3 GiB。数值入口只读明确给定的两侧矩阵；报告脚本另读归档 FE 数字作符号比较。

## 空间与投影常数

采用 cosine–Fourier 基加全部66个端口代表函数。基变换先减去代表函数在已保留 cosine 空间的能量投影，再按各频率的 $2\times2$ 余项 Gram 归一化；空间保持 (5.4)，解析能量 Gram 为 $H=I$。两截断都无依赖，最小余项 Gram 特征值如下。

| 截断 | 基维数 | 总维数 | $a_*$ | $C_h$ | $c_W$ | $\lambda_{min}(H)$ | 最小余项 Gram |
| --- | --- | --- | --- | --- | --- | --- | --- |
| (15,8) | 272 | 338 | 2527.86872668 | 0.0198894485181 | 0.990716448306 | 1 | 0.0098974707376 |
| (31,16) | 1056 | 1122 | 10107.7249067 | 0.0099465688511 | 0.997678251019 | 1 | 0.0049640097024 |

公式表复现如下；后两行只计算常数。最大相对差为 2.58839432499e-06，小于预设 $5\times10^{-6}$。

| 截断 | $C_h$ | $q_{max}C_h^2$ | $\delta=q_{max}C_h^2/c_W$ |
| --- | --- | --- | --- |
| (15,8) | 0.0198894485181 | 0.00928355169409 | 0.00937054362019 |
| (31,16) | 0.0099465688511 | 0.00232174898076 | 0.00232715204365 |
| (47,24) | 0.00663127370325 | 0.00103195933597 | 0.00103302537615 |
| (63,32) | 0.00497351507975 | 0.000580491086228 | 0.000580828251851 |

$(15,8)$ 已足够通过标量测试。最终采用 $(31,16)$，作为第二截断复核并减小质量膨胀。代码中 `P` 是原始基到能量正交基的系数变换；它与能量投影 $P_h$ 不同。`B_left/B_right` 是精确低 Fourier 迹，奇数编号代表函数在左端口取单位法向导数，偶数编号在右端口取单位法向导数。

## 星形区域上的积分

材料矩阵为 $M^q=6.6169M^1+16.8507M^{star}$。$M^1$、$H$ 和端口映射均用解析公式；$M^{star}$ 在真弧上按散度定理计算。cosine 产品按和频、差频合并；cosine–代表函数及代表函数–代表函数按指数乘积组装。利用核心区域的 $y$ 对称性合并正负横向频率，保持原物理取向。

复制曲线的基线面积为 $0.19415042599184923$，与解析面积相对差为0，见 run-001 的 `checks.area_relative_difference`。

周期梯形规则取解析带宽 $h=0.1$，每个指数矩用 (2.11) 的显式余项。常数矩使用精确面积 $0.04\pi(1.5+0.3^2/2)$；当散度公式的一个分母为零时改用另一分量，两个都为零时使用该面积。完整推导见文末。

| 截断 | 节点 $J$ | 指数矩数 | 原始基误差范数界 | 变换后星形质量误差界 | 加倍节点的实测变化 |
| --- | --- | --- | --- | --- | --- |
| (15,8) | 384 | 44351 | 2.11428011792e-12 | 5.48007004962e-10 | 1.26868061264e-14 |
| (31,16) | 512 | 89199 | 2.34470615165e-13 | 1.22086658301e-10 | 9.81720210589e-15 |

| 积分 | 边界梯形值 | 独立区域 Gauss 值 | 相对差 |
| --- | --- | --- | --- |
| 面积 | 0.194150425992 | 0.194150425992 | 7.14795640386e-16 |
| $\int x^2$ | 0.00488113962977 | 0.00488113962977 | 1.06617938077e-15 |
| $\int y^2$ | 0.00231288763546 | 0.00231288763546 | 7.50024968519e-16 |

独立区域规则使用 $c(\theta)$ 的径向缩放参数，径向80阶、角向384阶 Gauss 规则核对随机混合场质量二次型。第三个场只由余项代表函数组合，其质量很小。该场的附加相对检查未达到预设阈值，保留原结果：

| 量 | 值 |
| --- | --- |
| 区域积分 | 2.55420418989e-07 |
| 边界矩阵二次型 | 2.55420418943e-07 |
| 绝对差 | 4.61465137851e-17 |
| 相对差 | 1.80668851644e-10 |
| 预设相对容差 | 1e-10 |
| 已有星形质量算子余项 | 1.22086658301e-10 |

绝对差在已有算子余项内。相对阈值保持不变，该项记为未通过。核心下界继续使用完整算子余项，因而此项不改变安全方向及负指标。

## 计数

采用标量版本 (6.7)：$L_{center}=I-M^q_{center}/c_W+\sum B_\pm^*\hat\Lambda_\pm B_\pm$。材料积分误差在能量正交基中的安全矩阵为 $E=\epsilon I$，$L_{cert}=L_{center}-E$。两空间的 $\mu_2$ 均远大于 $\delta$。

| 截断 | $\mu_1$ | $\mu_2$ | $\delta$ |
| --- | --- | --- | --- |
| (15,8) | -0.80733290322 | 0.499218023156 | 0.00937054362019 |
| (31,16) | -0.807334101346 | 0.499135241999 | 0.00232715204365 |

| 截断 | $\lambda_1(L_{cert})$ | $\lambda_2(L_{cert})$ | $n(L_{cert})$ |
| --- | --- | --- | --- |
| (15,8) | -6.4732427247 | 0.36026393988 | 1 |
| (31,16) | -6.41713590436 | 0.365373688782 | 1 |

| 截断 | $\gamma_2$ | 核对后的中心下界 | $\epsilon$ | 安全第二下界 $\gamma_{safe}-\epsilon$ |
| --- | --- | --- | --- | --- |
| (15,8) | 0.360263949201 | 0.360263949101 | 9.32083206482e-09 | 0.36026393978 |
| (31,16) | 0.365373690844 | 0.365373690744 | 2.06203317645e-09 | 0.365373688682 |

所有特征值均在 $H=I$ 的能量基中。负指标由 $LDL^*$ 的1阶、2阶枢轴块直接计数。另对 $L_{center}-\gamma_{safe}I$ 作 $LDL^*$，负指标仍为1且枢轴非零，验证第二特征值确实大于所报告的中心下界。最终误差矩阵阶数1122，范数 2.06203317645e-09；最终 $L_{cert}$ 的最小绝对枢轴为 0.410450547031。

两个截断的 $\mu_2$ 变化为 -8.27811568997e-05；未膨胀 $T_{low}$ 的前两个能量特征值变化分别为 -3.41632756919e-05, -4.35786764595e-05。$L_{center}$ 的前两个值变化还包含标量膨胀随截断减小的影响，分别为 0.0561068130864, 0.00510974164279。这些变化均小于正方向的实际间隔。这里报告的是两截断稳定性，连续计数保证来自有限下界。

## 积分包围

最终核心矩阵中的星形材料积分均有显式余项；全核心无权质量、能量及迹为解析值。两侧 DtN 下界已包含 h-dtn-v1 的全部误差，直接代入；这些误差不重复加入本阶段的 $\epsilon$。用于计数的积分仍为浮点而未包围的部分：无。舍入按任务约定排除。

## 核查

1. 常数表：通过。最大相对差 2.58839432499e-06，容差 $5\times10^{-6}$。
2. 星形积分：通过。面积及两矩相对差最大 1.06617938077e-15；加倍节点的归一化变化 9.81720210589e-15，小于余项 1.22086658301e-10。附加混合场相对阈值未通过，数值和绝对余项比较见上表。
3. 端口代表：通过。cosine 模最大绝对误差 1.40998324127e-13，随机组合相对误差 1.84775583709e-14；含代表函数的独立 Gram 恒等式误差 3.56807527126e-13。预设容差分别 $10^{-11}$、$10^{-11}$、$10^{-10}$。
4. Hermitian 与 H：通过。$H=I$，构造核对差 5.04249419997e-14；$M^q$ 与边界矩阵相对 Hermitian 缺陷分别 1.88657404498e-14、0，均小于 $10^{-12}$。
5. FE 符号与稳定性：通过。归档 P3/g48 在 $k=2.37$ 的完整约化核心负指标为 1，与本实验一致；两截断变化见上文。小空间直接广义 eig 与低秩白化算法的四个铅笔特征值最大差 6.94333479601e-13，小于积分预算。
6. 两截断计数：通过。两者均为1，且第二方向严格为正。


归档 FE 数字来自 `gap-ends-v1/output/run-005/analysis.json` 中 $p=3,k=2.37$ 的行，仅作符号比较。本阶段没有重跑 FE。

## 成本

启动前估计：$(15,8)$ 为1–4分钟、0.8–1.8 GiB；$(31,16)$ 为2–8分钟、1.0–2.3 GiB；独立混合积分核查为1–3分钟、1.0–2.0 GiB。

| 运行 | 监控秒数 | 峰值 GiB |
| --- | --- | --- |
| run-001 | 18.595142917 | 0.82795715332 |
| run-002 | 14.137467833 | 0.919540405273 |
| run-003 | 16.380975 | 0.782760620117 |

run-003 的附加相对检验未通过，记录保留。主计数运行均正常结束。所有输出为小 JSON/CSV，不保存矩阵 MAT 文件。

## 结论

$n(L_{cert})=1\le1$，Theorem S.1 因而给出 $n(t_{\alpha_+})\le1$。A、P 和两侧全迹 DtN 下界已由上游提供；独立一阶区间与谱相交的前提已在问题说明中给出。Theorem S.2 的其余条件由本阶段的精确端口富化、$C_h$、$c_W>0$ 和有限计数满足。因此 $(1.7424,5.6169)$ 内恰有一个谱点，它是单重特征值，隔离假设 $(H)$ 在排除舍入的意义下成立。

`certificate.json` 保存最终截断、常数、特征值、误差及严格余量；`checks.json` 同时保留必需核查和附加失败项。

## 限制

排除舍入，只处理 $\lambda=\alpha_+$。结论使用已给的 A、P、独立谱交集和两侧 DtN 输入。矩阵运算及所有解析公式求值的舍入须在后续区间算术中处理。附加混合场的相对阈值仍未达到；其绝对差已在本阶段采用的算子余项内。

<details>
<summary>证明：基变换、解析矩与最终安全方向</summary>

本段是本实验新增计算界的从零推导。只使用已检查的 h-cert-proof.md Proposition D.1、Theorem S.1、S.2 和 (2.11)，不引入新的外部文献结论。

令 $s=x+1/2$，$\kappa_k=\sqrt{\beta_k^2+1}$。原始基由所有保留的 $\psi_{m,k}$ 与33对 $r_{-,k},r_{+,k}$ 组成。代表函数解 $(-\partial_x^2+\kappa_k^2)r=0$，左、右端口法向导数依次为 $(1,0)$、$(0,1)$，所以分部积分给出
$$e(w,r_{-,k})=(\tau_-w)_k,\qquad e(w,r_{+,k})=(\tau_+w)_k.$$
横向相位抵消边界项，$w$ 在两个端口可任意取迹。

在每个 $k$ 下，记 $D_k=\operatorname{diag}(a_{m,k})$，$V_k$ 的两列是 $c_m$ 和 $(-1)^mc_m$。代表函数能量 Gram 是
$$G_k=\frac1{\kappa_k}\begin{pmatrix}\coth\kappa_k&\operatorname{csch}\kappa_k\\\operatorname{csch}\kappa_k&\coth\kappa_k\end{pmatrix}.$$
减去能量投影后，其 Gram 为 $G_k-V_k^*D_k^{-1}V_k$。未保留该 $k$ 的 cosine 模时，后一项为空。有限检验给出这些2阶矩阵全部正定，故 Cholesky 变换产生独立的能量单位基。原始基到该基的系数矩阵是代码 `P`，解析 $P^*H_{raw}P=I$。空间没有改变，因而仍含 (5.4) 的全部代表函数；(5.5) 在补空间严格成立。

无权质量的 base–representative 块为 $D_k^{-1}V_k$。代表函数的同侧与异侧无权质量分别为
$$\frac{\coth\kappa}{2\kappa^3}+\frac{\operatorname{csch}^2\kappa}{2\kappa^2},\qquad
\frac{\coth\kappa\operatorname{csch}\kappa}{2\kappa^2}+\frac{\operatorname{csch}\kappa}{2\kappa^3}.$$
这些公式由一维 cosh 积分直接得到；不同横向频率正交。故 $M^1,H,B_\pm$ 全部解析。

星形边界是整函数。对 $|\Im\theta|\le h=0.1$，使用
$$c_x=0.3\cos\theta+0.03(\cos6\theta+\cos4\theta),\quad c_y=0.2\sin\theta+0.03(\sin6\theta-\sin4\theta).$$
令 $X_R,X_I$ 分别为 $|\Re c_x|,|\Im c_x|$ 的上界，$Y_R,Y_I$ 类似。代码取
$$X_R=0.3\cosh h+0.03(\cosh6h+\cosh4h),\quad X_I=0.3\sinh h+0.03(\sinh6h+\sinh4h),$$
$Y_R,Y_I$ 将0.3换为0.2。导数界 $X'_b,Y'_b$ 分别将括号内两项乘6与4，首项仍取 cosh。所有量是显式有限公式。

对 $I(a,b;o)=\int_{star}e^{ax+by+o}$，若 $a\ne0$，散度公式给出 $\oint e^{ac_x+bc_y+o}c_y'/a$；若 $b\ne0$，也可用 $-\oint e^{ac_x+bc_y+o}c_x'/b$。代码选择模较大的非零分母。对应解析被积函数模至多
$$M=\frac{Y'_b}{|a|}\exp\{ |\Re a|X_R+|\Im a|X_I+|\Re b|Y_R+|\Im b|Y_I+o\},$$
或将前因子换为 $X'_b/|b|$。所有偏移 $o$ 为实数。若 $a=b=0$，直接用 $e^o\,0.04\pi(1.5+0.3^2/2)$，无需除法。

(2.11) 的 Fourier 轮廓平移论证给出单个矩的误差 $4\pi M/(e^{hJ}-1)$。cosine 由两个指数及相位 $e^{\pm\mathrm im\pi/2}$ 组成。核心区域在 $y\mapsto-y$ 下不变，所以对纯虚 $b$ 有 $I(a,-b;o)=I(a,b;o)$、$I(\bar a,b;o)=\overline{I(a,b;o)}$。因此 cosine 矩可取旋转指数矩的实部，误差不增。和频、差频恒等式给出 cosine–cosine 块。

代表函数采用稳定的精确指数式
$$r_- =\frac{e^{-\kappa/2}e^{-\kappa x}+e^{-3\kappa/2}e^{\kappa x}}{\kappa(1-e^{-2\kappa})},\qquad
r_+ =\frac{e^{-3\kappa/2}e^{-\kappa x}+e^{-\kappa/2}e^{\kappa x}}{\kappa(1-e^{-2\kappa})}.$$
所有乘积只有有限指数项。代码把共同的 $e^{-\kappa/2}$ 或 $e^{-(\kappa_i+\kappa_j)/2}$ 放入 $o$，其余系数绝对值乘在矩余项上，再求和。这同时处理 cosine–cosh、cosh–cosh 和零分母情形。整个材料区使用真弧。

所得逐项误差界组成实对称非负矩阵 $E_{raw}^{abs}$，其最大行和控制 Hermitian 材料误差的算子范数。若该最大行和为 $e_{raw}$，则
$$\|P^*(M^{star}_{true}-M^{star}_{center})P\|_2\le\|P\|_2^2 e_{raw}\le\|P\|_1\|P\|_\infty e_{raw}=:\epsilon_{star}.$$
代码逐行累计误差，不需保存整张误差矩阵。对中心值取 Hermitian 部分不会增大该界。

由于 $M^q=6.6169M^1+16.8507M^{star}$，而 $c_W>0$，故
$$\epsilon=\frac{3\lambda}{c_W}\epsilon_{star},\qquad L_{center}-\epsilon I\preceq L_{scalar,true}.$$
两侧输入已经是全迹 DtN 下界，所以无需在这里再扣它们原有的误差。Proposition D.1 给出 $C_h$；代表函数使补空间的所有保留端口系数消失；Theorem S.1 及 (6.7) 因而适用，得到
$$n(t_{\alpha_+})\le n(L_{scalar,true})\le n(L_{cert})=1.$$
最小未保留模式给出的 $C_h$ 不因增加代表函数而失效。结合已给 A、P、独立谱交集及本次严格有限测试，Theorem S.2 的每个条件均已满足。

独立区域正权规则的参数化也可直接验证：记 $A=1.5+0.3\cos5\theta$、$B=1+0.3\cos5\theta$，则
$$\det(c,c')=0.04\{AB-0.75\sin5\theta\cos\theta\sin\theta\}\ge0.04(0.84-0.375)>0.$$
边界绕原点一次且角度严格增加，$r c(\theta)$ 因此一次覆盖内部。该正权规则仅作独立浮点核查，核心包围使用上面的曲线余项。

</details>
