# h-cert-v1：isolation hypothesis certificate

`h-cert` 是 isolation hypothesis certificate，指隔离假设 $(H)$ 的证书。本目录计算表面态端点 B1、B2 和半引线预解式常数 B3。

## 目的

四个端点的有限 Schur 检验均通过，两种材料的负指标在窗口两端相同。排除舍入后，这给出截线两侧均无表面态，并给出下一步所用的 $K_+$。

## 起点与输入

采用 `research/explorations/numerical-directions/h-cert-proof.md` 的 §1.1、§1.2、§2.4、§3 和 §7.2，以及相邻复核文件。周期谱距离取已给定的 $d=\min(\lambda-1.318^2,2.375^2-\lambda)$。

`fem-pipeline-v1/direct_native.m` 的 `LOCAL_curve` 使用原取向三叶形；胞中心为整数，胞壁为半整数，物理端口为 $-1/2,1/2$。左端口平移 $+1/2$，右端口平移 $-1/2$ 后截线均为 0。周期延拓的计算胞是 $[0,1]\times[-1/2,1/2]$，夹杂中心 $(1/2,0)$。没有反射。夹杂密度 17、背景 1，横向相位 $0.5$。

边界为 $R_a(1+a\cos3t)(\cos t,\sin t)$，$R_a=0.2/\sqrt{1+a^2/2}$。两个材料的最大半径与截线最小间距如下；故 $a_{collar}=1/4$ 有效。

| 材料 | 最大半径 | 截线间距下界 |
|---|---|---|
| 0.12 | 0.223197928596 | 0.276802071404 |
| 0.2 | 0.237635410314 | 0.262364589686 |

## 复现命令

从仓库根目录执行下列命令；每次须用新的 `run-NNN`。入口参数完全给出数值配置，不读取旧输出配置响应场。保留旧记录时，把输出改为未用编号，并同步 `manifest.json` 的显式路径，再运行汇总。

```sh

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-009 --material 0.12 --lambda 1.7424 --order 26 --phases 64 --quadrature 2560 --certificate --degree 5 --phase-order 40

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-010 --material 0.12 --lambda 5.6169 --order 26 --phases 64 --quadrature 2560 --certificate --degree 5 --phase-order 40 --poisson2

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-007 --material 0.2 --lambda 1.7424 --order 26 --phases 64 --quadrature 2560 --certificate --degree 5 --phase-order 40

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-011 --material 0.2 --lambda 5.6169 --order 26 --phases 64 --quadrature 2560 --certificate --degree 5 --phase-order 40 --poisson2

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-002 --material 0.12 --lambda 1.7424 --order 18 --phases 128 --quadrature 30

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-012 --material 0.12 --lambda 5.6169 --order 18 --phases 128 --quadrature 2560 --analytic

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-003 --material 0.2 --lambda 1.7424 --order 18 --phases 128 --quadrature 30

python3 test/numerical-directions/h-cert-v1/launch_h.py --output test/numerical-directions/h-cert-v1/output/run-013 --material 0.2 --lambda 5.6169 --order 18 --phases 128 --quadrature 2560 --analytic

python3 test/numerical-directions/h-cert-v1/tail_constants.py test/numerical-directions/h-cert-v1/tail-constants.json

python3 test/numerical-directions/h-cert-v1/launch_analysis.py --output test/numerical-directions/h-cert-v1/output/run-014 --manifest test/numerical-directions/h-cert-v1/manifest.json

python3 test/numerical-directions/h-cert-v1/report_h.py test/numerical-directions/h-cert-v1/manifest.json test/numerical-directions/h-cert-v1/output/run-014/science/analysis.json
```

全部 MATLAB 运行由 `diagnostics-v1/monitor.py` 启动，11 线程，`OMP_DYNAMIC=FALSE`。正式端点运行预估 8–22 分钟、峰值 1.8–2.8 GiB；监控软限 30 分钟、硬限 40 分钟、峰值硬限 3 GiB。较小空间的复现参数在对应 `command.json` 与 `result.json` 中。

## 尾项常数

使用粗源界 (3.14)。全部 $n_k$、$D_0$ 对角元和常数在 `tail-constants.json`。$n_0=1/(2\sqrt{1.25})$；$a_M$ 的最大值在 $k=-(M+1)$。

| $\lambda$ | $M$ | $a_M$ | $b_{out}$ | $c_P$ | $h_M$ | $x_M$ | $t_M$ | $x_M^2/t_M$ |
|---|---|---|---|---|---|---|---|---|
| 1.7424 | 6 | 2.19867313334e-07 | 0.33816293163 | 3.51292897448 | 4.20240897726e-10 | 0.0009919210742 | 0.49999999958 | 1.96781483654e-06 |
| 1.7424 | 8 | 7.36039391115e-09 | 0.33816293163 | 3.51292897448 | 4.70954652014e-13 | 3.32060719904e-05 | 0.5 | 2.20528643406e-09 |
| 1.7424 | 10 | 2.59591139232e-10 | 0.33816293163 | 3.51292897448 | 5.85809897647e-16 | 1.17113325203e-06 | 0.5 | 2.74310618802e-12 |
| 1.7424 | 12 | 9.47592832047e-12 | 0.33816293163 | 3.51292897448 | 7.80585554826e-19 | 4.27502062775e-08 | 0.5 | 3.65516027354e-15 |
| 5.6169 | 6 | 2.22674969508e-07 | 0.33816293163 | 10.330028513 | 9.97391582188e-10 | 0.00212005638691 | 0.499999999003 | 8.98927818532e-06 |
| 5.6169 | 8 | 7.43118652653e-09 | 0.33816293163 | 10.330028513 | 1.11080856662e-12 | 7.07512590782e-05 | 0.499999999999 | 1.00114813223e-08 |
| 5.6169 | 10 | 2.61592176819e-10 | 0.33816293163 | 10.330028513 | 1.37648790336e-15 | 2.49058152543e-06 | 0.5 | 1.24059926696e-11 |
| 5.6169 | 12 | 9.53685116162e-12 | 0.33816293163 | 10.330028513 | 1.82950206952e-18 | 9.07989894907e-08 | 0.5 | 1.64889129851e-14 |

八个尾项按三个有效数字与证明 §3.5 相同。表格是显示近似；严格检验使用源码公式与 JSON 的完整数值。

| $\lambda$ | $D_0$ 最小对角元 | $D_0$ 最大对角元 | $n_0$ |
|---|---|---|---|
| 1.7424 | 0.5 | 0.521177347984 | 0.4472135955 |
| 5.6169 | 0.5 | 0.556276832425 | 0.4472135955 |

## 低频块与残差

每个 Bloch 胞用 $|m|,|n|\le N$ 的平面波。它们的值和一阶导数严格满足两个 Bloch 相位。逆 Bloch 表达的纵向频率为 $2\pi m+\theta$，支持有界；系数在相位上平方可积，故全线响应属于 $H^2$。相位面板间的系数不需要导数匹配。每个相位面板内系数是给定次数的多项式，节点上的有限求解只用于选择系数。源项由 (3.22) 的正、负半轴几何级数分别计算；两个分母均保留。零横向源的非紧支撑部分同样保留，全线的直接项 $(\lambda+1)n_0^2$ 精确求值。真实曲线的散度定理给出胞内积分。

$\widehat C$ 仍用 (3.19)–(3.21) 的二次恒等式。下端误差使用周期 Poisson 通量的形式残差界 $E=K\overline H+(\epsilon_C+K\epsilon_H)I$。上端用二次 Poisson 恒等式进一步收紧误差和响应界，公式见下面推导。原体残差大小同时保留在下表；它没有被丢弃。实现为 `h_bloch.m`，完整矩阵在每次运行的 `science/result.json`。

| 材料 | $\lambda$ | $N$ | 面板/次数 | $\sqrt{\|G_r\|}$ | $\sqrt{\|\overline H\|}$ | $\|E\|$ | 原 $\|G_r\|/d$ |
|---|---|---|---|---|---|---|---|
| 0.12 | 1.7424 | 26 | 64/5 | 0.474533174776 | 0.00389242318993 | 0.00789043303048 | 42.680389303 |
| 0.12 | 5.6169 | 26 | 64/5 | 4.37543174041 | 0.036177868126 | 0.00237795830891 | 806.929522233 |
| 0.2 | 1.7424 | 26 | 64/5 | 0.638787428107 | 0.00522063864501 | 0.0141941046564 | 77.3406706421 |
| 0.2 | 5.6169 | 26 | 64/5 | 8.44551350544 | 0.0697513891094 | 0.00884339297176 | 3006.39403037 |

<details>
<summary>Poisson 通量改进界的推导（本实验采用的替代公式）</summary>

在 Bloch 相位 $\theta$ 的胞上，令 $D_{mn}=(2\pi m+\theta)^2+(0.5+2\pi n)^2$，$r=F-L_\lambda Z$。所有 $D_{mn}>0$。取周期 Poisson 解 $\psi=(-\Delta)^{-1}r$ 和 $p=\nabla Z+\nabla\psi$。则 $p\in H(\operatorname{div})$，有两个 Bloch 相位，且
$$F+\lambda\rho Z+\operatorname{div}p=0,\qquad\nabla Z-p=-\nabla\psi.$$
对任意 $v$，残差泛函为 $\langle r,v\rangle=\langle\nabla\psi,\nabla v\rangle$。因为 $\|v\|_V^2=\|\nabla v\|^2+\|v\|_\rho^2\ge\|\nabla v\|^2$，其对偶范数平方不超过 $\|\nabla\psi\|^2$。由同一 Bloch Fourier 展开和正交性，后者等于 $\sum_{m,n}|r_{mn}|^2/D_{mn}$。

令 $P_N$ 保留 $|m|,|n|\le N$，$\delta=P_Nr$，$G_0=\int r_j\overline{r_i}$。所有遗漏模态满足 $D_{mn}\ge D_{\rm tail}>0$，因此相应的矩阵上界为
$$H=\delta^*D_N^{-1}\delta+\frac{G_0-\delta^*\delta}{D_{\rm tail}}.$$
代码用 $\delta=F_N-L_N Z$，不把有限求解的残差设为零。取
$$D_{\rm tail}=\min\{(2\pi(N+1)-|\theta|)^2+0.25,\ \theta^2+(2\pi(N+1)-0.5)^2\}.$$
正式证书在每个实相位面板 $I=[c-h,c+h]$ 固定使用更小的常数
$$D_{tail,I}=\min\{(2\pi(N+1)-\max_{\theta\in I}|\theta|)^2+0.25,\ (2\pi(N+1)-0.5)^2\}.$$
它是整个面板的遗漏模态下界。下面积分中的 $D_{tail}$ 都指这个固定常数，因此解析延拓中没有 $|\theta|$ 或逐点最小值。

设 $d=d_{\rm per}(\lambda)$、$K=1+(\lambda+1)/d$。证明 (3.1) 后的形式逆界给出 $|\langle r,L_\lambda^{-1}r\rangle|\le K c^*Hc$。故 (3.21) 的低频块不变，误差矩阵可改为 $E=K\int H(\theta)d\theta/(2\pi)$。这是原二次恒等式与形式逆界的组合。

同一谱乘子满足 $\sup_{t\in\sigma(A)}(t+1)/(t-\lambda)^2\le K/d$，所以 $\|L_\lambda^{-1}r\|_\rho\le\sqrt{K/d}\sqrt{c^*Hc}$。公式 (3.27) 改用
$$a_{\rm low}=\sqrt{\lambda_{\max}(G_U)}+\sqrt{K/d}\sqrt{\lambda_{\max}(\overline H)}.$$
这里 $G_U$ 和 $\overline H$ 都是归一化 Bloch 积分。上端点另用更紧的二次 Poisson 恒等式：令 $\psi=(-\Delta)^{-1}r$，则
$$R_\lambda r=\psi+\lambda R_\lambda(\rho\psi),$$
$$\langle r,R_\lambda r\rangle=\langle r,\psi\rangle+\lambda\|\psi\|_\rho^2+\lambda^2\langle\rho\psi,R_\lambda(\rho\psi)\rangle.$$
由 (3.1) 与 $\rho\le17$，可得
$$|\langle r,R_\lambda r\rangle|\le c^*Hc+17\lambda(1+\lambda/d)c^*H^{(2)}c,$$
$$\|R_\lambda r\|_\rho\le\sqrt{17}(1+\lambda/d)\sqrt{c^*H^{(2)}c},$$
其中
$$H^{(2)}=G_0/D_{tail}^2+\delta^*(D_N^{-2}-D_{tail}^{-2}I)\delta\succeq\int\psi_j\overline{\psi_i}.$$
因此上端用 $E=\overline H+17\lambda(1+\lambda/d)\overline H^{(2)}$，另加积分余项；响应误差改用后一个不等式。$H^{(2)}$ 的相位椭圆界是 $r_b^2[(0.25-s^2)^{-2}+2/D_{tail}^2]$，曲线传播界是原共同界再乘 $1+(0.25-s^2)^{-1}$。下端仍用形式逆界。全线 Bloch 分解、形式逆界和二次恒等式取自已读的证明 (3.19)–(3.23)；新推导只用 Fourier 正交性和 Cauchy–Schwarz。依赖的真实积分在积分包围节分别说明。

</details>

## 端点惯性 (B1, B2)

负指标 $m$ 来自 (3.16) 两个 Schur 矩阵。两者必须非奇异且负指标相同。下表使用积分包围后的误差矩阵。

| 材料 | $\lambda$ | $M$ | $m_- / m_+$ | $\gamma$ | $\|E\|$ | $x_M^2/t_M$ |
|---|---|---|---|---|---|---|
| 0.12 | 1.7424 | 8 | 0 / 0 | 0.023555789139 | 0.00789043303048 | 2.20528643406e-09 |
| 0.12 | 1.7424 | 10 | 0 / 0 | 0.0235557913416 | 0.00789043303048 | 2.74310618802e-12 |
| 0.12 | 5.6169 | 8 | 0 / 0 | 0.500642826488 | 0.00237795830891 | 1.00114813223e-08 |
| 0.12 | 5.6169 | 10 | 0 / 0 | 0.500412800137 | 0.00237795830891 | 1.24059926696e-11 |
| 0.2 | 1.7424 | 8 | 0 / 0 | 0.00428912741285 | 0.0141941046564 | 2.20528643406e-09 |
| 0.2 | 1.7424 | 10 | 0 / 0 | 0.00428912961539 | 0.0141941046564 | 2.74310618802e-12 |
| 0.2 | 5.6169 | 8 | 0 / 0 | 0.500642716157 | 0.00884339297176 | 1.00114813223e-08 |
| 0.2 | 5.6169 | 10 | 0 / 0 | 0.500412689806 | 0.00884339297176 | 1.24059926696e-11 |

| 材料 | $m(\alpha_-)$ | $m(\alpha_+)$ | B2 |
|---|---|---|---|
| 0.12 | 0 | 0 | 相等 |
| 0.2 | 0 | 0 | 相等 |

根据定理 B.3，相等的负指标排除该材料在截线两侧的整个闭窗口表面谱。

## 半导波预解式常数 (B3)

上端使用 $M=10$，由 (3.17)、(3.25)、改进后的 (3.27) 和 (3.28) 计算。粗界使用相同的边界逆范数与 (3.26)，未代入计划中的假设间隙 0.1。

| 材料 | $\|\mathscr B^{-1}\|$ 上界 | $\|\mathscr T\|^2$ Gram 上界 | (3.26) 粗界 | $d_{half}$ | $K_+$ | 粗 $K_+$ |
|---|---|---|---|---|---|---|
| 0.12 | 2.0000199247 | 6.37665378605 | 5898.8386644 | 0.0182139191162 | 364.288096196 | 78344.7287131 |
| 0.2 | 2.0000199247 | 22.3880461732 | 5898.8386644 | 0.0115040154704 | 576.181771708 | 78344.7287131 |

当下端 $m=0$ 时，还能直接得到更紧的距离界。B1 的可逆性与零负指标给出 $\mathscr B_{\alpha_-}\ge bI>0$。对 $\alpha_-\le\mu<2.375^2$，$\mathscr B_\mu-\mathscr B_{\alpha_-}=\int_{\alpha_-}^{\mu}\mathscr T_t^{*,\rho}\mathscr T_t\,dt\succeq0$。因此每个 $\mu\in[\alpha_-,2.375^2)$ 都有可逆的 $\mathscr B_\mu$；(3.24) 给出两个半引线在这些点的预解式。于是 $d_{half}(\alpha_+)\ge\min(\alpha_+-\alpha_-,2.375^2-\alpha_+)=0.023725$。这个推论只在零负指标时使用。它不改变上表按 (3.25) 请求计算的 Gram 与粗界。

| 材料 | 单调性距离界 | 单调性 $K_+$ |
|---|---|---|
| 0.12 | 0.023725 | 279.899894626 |
| 0.2 | 0.023725 | 279.899894626 |

下表的响应误差、$a_{low}$、$a_{high}$ 均为从边界系数 $\ell^2$ 到 $L^2_\rho$ 的算子范数。$G_U$ 是参考提升加试探响应的加权 Gram。

| 材料 | $\lambda_{max}(G_U)$ | $\|Rr\|_\rho$ 误差上界 | $a_{low}$ | $a_{high}$ |
|---|---|---|---|---|
| 0.12 | 5.34749347007 | 0.212728372873 | 2.52519317694 | 0.00729418703213 |
| 0.2 | 18.6731797656 | 0.410347704249 | 4.73159518218 | 0.00729418703213 |

## 积分包围

曲线梯形规则和相位 Gauss 规则都有显式余项。正式四个端点的 $\widehat C$、$G_r$、$\overline H$ 和响应 Gram 积分均计入截断余项；没有仍以裸浮点求积代替的积分。下面给出相位与空间余项合计。有限算术舍入仍被排除。较小空间对照的空间和相位积分只作浮点一致性比较，没有加积分包围，不是正式 B1/B3 界的输入。

| 材料 | $\lambda$ | $\epsilon_C$ | $\epsilon_H$ | $\epsilon_U$ | $\epsilon_G$ | $\epsilon_{H^{(2)}}$ | 曲线原始余项 | 曲线传播余项 |
|---|---|---|---|---|---|---|---|---|
| 0.12 | 1.7424 | 3.35823719152e-19 | 7.27311785079e-14 | 1.40093223349e-21 | 1.80838977805e-14 | — | 1.85794776395e-99 | 3.07033000524e-33 |
| 0.12 | 5.6169 | 1.88743651319e-18 | 4.13305682637e-13 | 2.2581214093e-21 | 1.0276439659e-13 | 1.66220489452e-12 | 1.85794776395e-99 | 3.1575269968e-33 |
| 0.2 | 1.7424 | 5.43774357887e-19 | 1.18383310784e-13 | 1.54721972934e-21 | 2.94348512516e-14 | — | 7.44379956188e-98 | 1.23042652778e-31 |
| 0.2 | 5.6169 | 7.38624389124e-18 | 1.62171944526e-12 | 4.485754646e-21 | 4.03224589743e-13 | 6.52212156061e-12 | 7.44379956188e-98 | 1.26628364595e-31 |

<details>
<summary>固定多项式响应的积分包围方法</summary>

每个相位面板取 $\theta=c+h t$，在六个 Chebyshev–Lobatto 点解有限胞系统，把响应系数插值为五次多项式 $Z(t)$。这是选定试探场的方法；实际使用其残差，不假定插值准确。有限 Fourier 和多项式系数都作为给定实数/复数使用。

对 Bernstein 椭圆参数 $\varrho=2$，有 $|t|\le1.25$、$|\operatorname{Im}\theta|\le s=0.75h$。若解析矩阵函数在椭圆上范数不超过 $B$，其 Chebyshev 系数范数至多 $2B\varrho^{-j}$。截断到 $2q-1$ 次，余项至多 $2B\varrho^{-2q}/(1-\varrho^{-1})$。正权 Gauss 规则对该多项式精确，积分与求积的余项各受此界控制。因此代码对归一化面板使用更宽的误差
$$\epsilon_q\le\frac{8B\varrho^{-2q}}{1-\varrho^{-1}}.$$
矩阵的解析延拓把实轴上的共轭系数换成系数共轭的多项式，故同一范数界适用于两因子。

设 $z_b=\sum_j\|Z_j\|_F1.25^j$。直接对 (3.22) 的两项及其分母取界，代码使用
$$t_b=e^s\left(\sum_i\left[\frac{\sqrt{q_i}(1+e^s)}{2\kappa_i(1-e^{-\kappa_i+s})}\right]^2\right)^{1/2},\quad f_b=(17\lambda+1)t_b.$$
令 $D_b=(2\pi N+|c|+1.25h)^2+(2\pi N+0.5)^2$，$\ell_b=D_b+17\lambda$，$r_b=f_b+\ell_bz_b$。因为 $|D_{mn}^{-1}|\le(0.25-s^2)^{-1}$，可以分别取
$$B_C=16\lambda t_b^2+2f_bz_b+\ell_bz_b^2,$$
$$B_H=r_b^2[(0.25-s^2)^{-1}+2/D_{tail}],\quad B_U=17(t_b+z_b)^2,\quad B_G=r_b^2.$$
面板权重是 $1/P$；把上述余项累加后，在误差矩阵中加入 $(\epsilon_C+K\epsilon_H)I$，在响应 Gram 中加入 $\epsilon_UI$。

空间积分用真实解析边界的散度定理，不用多边形。除常数项外，被积函数均为有限指数和；零频率面积精确为 $0.04\pi$。曲线参数的解析带宽取 $0.1$。其复数实部仍处于 $0<x<1$，所以两个纵向衰减因子的模不超过 1。由证明 (2.12) 的三角函数界，可取每个原始矩量的梯形余项
$$\epsilon_{curve}=\frac{4\pi\,100\exp[(8\pi N+40\pi+10)C_{im}(0.1)]}{e^{0.1J}-1}.$$
系数分母下界来自 $s<0.5<\kappa_0$。横向非零频率的最小间距为 $2\pi$；两个不同衰减率的最小间距大于 1。若 x 指数为零而 y 指数非零，改用 y 方向的散度公式；两个指数均为零时使用常数乘面积，不作除法。

传播时令 $A=(n+p+1)(1+\ell_b+f_b+z_b)$、$\epsilon=\epsilon_{curve}$。$X$、$IT$、$TT$ 的范数误差均至多 $A\epsilon$；源投影及 $L_N$ 的误差至多 $A^2\epsilon$。残差的两个 Fourier 分子 $-(D-\lambda)Z$、$-(D-17\lambda)Z$ 的范数至多 $A^2$。逐项展开 Gram 后，$G_0$ 的误差至多 $8A^5\epsilon$，响应 Gram 的误差至多 $4A^4\epsilon$，$\widehat C$ 的误差至多 $4A^4\epsilon$。保留模态残差 $\delta$ 的误差至多 $2A^3\epsilon$，其真值范数至多 $2A^2$。因此在 $A\epsilon<1$、$D_{tail}>1$ 时，$H$ 的误差至多 $20A^5(1+(0.25-s^2)^{-1})\epsilon$。所有面板均有 $A>3$，故统一的 $A^8(1+(0.25-s^2)^{-1})\epsilon$ 覆盖四类误差。代码把这个共同上界加到每个面板的四个积分余项中。这里采用很宽的界；实际余项仍由相位积分主导。

</details>

24 阶对照主规则与最终采用的 40 阶规则的差，以及曲线加倍点数的差列在 `analysis.json`。曲线比较包括全部 $X$ 矩元和 $\theta=-\pi,0,\pi$ 的源矩量；解析余项对全部相位有效。两种曲线规则的差大于极小的解析余项，有限浮点算术已到舍入尺度；没有把这些差值加作解析截断余项。

## 核查

1. 尾项表：通过；八个值均在三个有效数字上复现 §3.5。

2. 两个试探空间：通过；四个 $N=18$ 与 $N=26$ 空间满足 $\|\widehat C_1-\widehat C_2\|\le\|E_1\|+\|E_2\|$；最大比值 0.000668465427939。

3. 单调性：通过；$\widehat C_+-\widehat C_-+E_++E_-$ 的最小特征值 0.000241897407178。

4. M=8/10：通过；四端点两个边界截断的惯性相同；尾罚项均下降超过 100 倍。

5. 求积：通过；主/高阶规则与曲线加倍的最大比较量 1.26472943499e-13，预设容差 $10^{-9}$，小于最小间隙的 2.94868702478e-11。

6. Hermitian 与 Gram 正半定：通过；最大原始相对非 Hermitian 量 4.8601037124e-13，容差 $10^{-12}$；最小 Gram 特征值 -1.04228302845e-14，按 $-10^{-12}\|G_r\|$ 的舍入尺度核查；精确算术中的残差 Gram 按构造正半定。


| 材料 | $\lambda$ | 两块差范数 | 误差范数和 |
|---|---|---|---|
| 0.12 | 1.7424 | 8.27100831947e-06 | 0.0310126422581 |
| 0.12 | 5.6169 | 0.000708110786497 | 1.07364993874 |
| 0.2 | 1.7424 | 1.48365161005e-05 | 0.0558495275129 |
| 0.2 | 5.6169 | 0.00266286229445 | 3.98354527123 |

## 成本

14 次监控运行合计 3230.05739292 秒，最大峰值 1.71955871582 GiB。

| 运行 | 壁钟秒 | 峰值 GiB | 结束原因 |
|---|---|---|---|
| run-001 | 20.824489708 | 0.938995361328 | completed |
| run-002 | 128.981965625 | 1.48078918457 | completed |
| run-003 | 122.736818666 | 1.45831298828 | completed |
| run-004 | 22.836770916 | 0.905853271484 | completed |
| run-005 | 366.397892209 | 1.4422454834 | completed |
| run-006 | 25.571473958 | 0.980209350586 | completed |
| run-007 | 471.087339209 | 1.71955871582 | completed |
| run-008 | 458.812609125 | 1.55741882324 | completed |
| run-009 | 469.597183833 | 1.61695861816 | completed |
| run-010 | 440.854083458 | 1.50631713867 | completed |
| run-011 | 463.72106775 | 1.70118713379 | completed |
| run-012 | 113.28310575 | 1.00958251953 | completed |
| run-013 | 111.202168708 | 0.918807983398 | completed |
| run-014 | 14.150424 | 0.736343383789 | completed |

## 对下一步的意义

B1–B3 已给出可用于下一步的有限输入。若 DtN 低模修正预算取 $K_+r\le4\times10^{-4}$，则所需残差为：

| 材料 | Gram 界的 $\sqrt r$ 上限 | 单调性界的 $\sqrt r$ 上限 |
|---|---|---|
| 0.12 | 0.00104787023821 | 0.00119544232523 |
| 0.2 | 0.000833201874496 | 0.00119544232523 |

下一步计算物理半引线的 DtN 场、通量及修正矩阵，再做芯区最终计数。

## 限制

所有包围排除浮点舍入。有限矩阵的特征值和符号尚需后续区间算术包围。本方法同时检验截线两侧；左右物理半引线分别由对应材料的这一结论覆盖。关口 C、D 和最终计数尚未计算，$(H)$ 仍待这几步完成。
