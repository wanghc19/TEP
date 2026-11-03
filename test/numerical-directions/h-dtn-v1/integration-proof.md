<details>
<summary>解析几何与正权 Gauss 积分余项的推导</summary>

本段为本实验新增界的从零推导；它以 h-cert-proof.md 的 C.1、C.3 及 h-cert-v1 的半引线预解式界为输入。只排除舍入，不以两阶求积之差充当积分余项。

记单元顶点仿射映射为 $v_1+A\xi$。公共单元直接定义为该仿射映射。曲线单元使用
$$F=v_1+A\xi+4\ell_a\ell_b o+r^3\delta(t),\qquad r=\ell_a+\ell_b,\quad t=\ell_b/r,$$
其中 $o=c(t_{mid})-(v_a+v_b)/2$，$\delta$ 为真弧减去其二次插值。Duffy 坐标中的 $r,t$ 各在参数2、映到 $[0,1]$ 的 Bernstein 椭圆内。于是 $|r|,|t|,|1-t|\le1.125$，$|t-1/2|\le0.625$。三叶形的 Fourier 频率是 $1,2,4$，每个坐标的振幅上界依次为 $R,Ra/2,Ra/2$。

写 $T_j(z)=\sum_{k\ge j}z^k/k!$。对每个频率 $\nu$，令 $z=\nu\Delta\theta$，则
$$|\delta|_\infty\le\sum_\nu a_\nu\{T_3(0.625z)+2.8125T_3(0.5z)\},$$
$$|\delta'|_\infty\le\sum_\nu a_\nu\{zT_2(0.625z)+7T_3(0.5z)\}.$$
这是先减去中点 Taylor 二次式，再对剩余项作三点插值所得的界。代码把正项求到40阶；后续项比不超过 $z/42$，故用首个未计项除以 $1-z/42$ 包围。实际所有 $z$ 都满足该分母为正。

利用
$$J-A=4o(\ell_a\,d\ell_b+\ell_b\,d\ell_a)+r^2\{3\delta\,dr+\delta'(d\ell_b-t\,dr)\},$$
代码分别计算 $\eta=\|A^{-1}(J-A)\|_\infty$ 与 $\eta_{phys}=\|(J-A)A^{-1}\|_\infty$ 的上界。两者均小于1。因特征值模不超过矩阵无穷范数，整个复椭圆上有
$$|\det J|\ge\det A(1-\eta)^2,\quad |\det J|\le\det A(1+\eta)^2,\quad \|J^{-1}\|_\infty\le\|A^{-1}\|_\infty/(1-\eta).$$
实单胞上的分片位移连续，外胞壁位移为零，物理坐标导数范数小于1；延拓为零后仍是全局 Lipschitz 位移。对任意目标点，迭代 $x_{n+1}=y-d(x_n)$ 的差按几何级数下降，给出唯一原像。因此分片映射全局一一对应，材料标签与真弧一致。这一判断覆盖整个单元，不只覆盖求积点。

首胞端口修正按 $\xi=1/8$ 和实际端口多项式的各个横向分段裁剪仿射三角形。每个裁剪子三角形独立积分；不丢弃任何正面积片。曲线单元到修正带的距离由复位移上界核查为正。每个积分片上均只有一个解析表达式。公共重复胞上的 $Q,R,Z,E$ 密度是次数至多8的多项式；Duffy 后各变量次数至多9，16阶 Gauss 精确。

其余积分片上用系数 Frobenius 范数给出整块矩阵的算子范数界。设 $\Lambda=2$（裁剪后的仿射片取4），$n_b$ 为场基函数数目，$U_e$ 为场系数，$c_e$ 为整数 RT 基的单项式系数，则
$$|u|\le\sqrt{n_b}(p\Lambda+p)^p\|U_e\|_F,\quad |\partial_{ref}u|\le\sqrt{n_b}\,2p^2(p\Lambda+p)^{p-1}\|U_e\|_F,$$
$$|p_{ref}|_\infty\le\sqrt{24}\Lambda^4\|c_e\|_F,\quad |\operatorname{div}_{ref}p|\le5\sqrt{24}\Lambda^3\|c_e\|_F.$$
用上述 $J^{-1},J,\det J$ 界完成梯度和 Piola 变换。解析列的指数由 $\Re\xi$ 下界和 $|\Im y|$ 上界控制。Duffy 复重心坐标的负实部总量至多0.6875、虚部绝对值总量至多2.0625，所以
$$\Re\xi\ge\min_v\xi_v-0.6875\operatorname{span}_v\xi-d_{geom},\qquad |\Im y|\le1.03125\operatorname{span}_v y+d_{geom}.$$
对裁剪片，$\xi/b$ 的复值是顶点处 $[0,1]$ 数据的仿射插值；其模不超过 $\max_j(|\ell_j|,|1-\ell_j|)<3$。因此端口修正的三次截断函数及其物理导数分别用82和576控制；加上衰减指数后，导数界再加 $82\tau$。实际端口多项式系数也按其 Frobenius 范数包围。

设由此得到 $u,\nabla u,p,\operatorname{div}p$ 的上界分别为 $u_b,g_b,p_b,d_b$，每个梯度/通量分量分别受 $g_b,p_b$ 控制；$j_b$ 是含 Duffy 和子片面积因子的 Jacobian 上界。代码取
$$M_Q=j_b(2g_b^2+\lambda\rho u_b^2),\quad M_R=j_b\{2(g_b+p_b)^2+(d_b+\lambda\rho u_b)^2/\rho\},$$
$$M_Z=j_b\{u_b+K_+(d_b+\lambda\rho u_b)\}^2,\quad M_E=j_b(2g_b^2+\rho u_b^2).$$
这些是矩阵算子范数界，不是逐项界；无需再乘矩阵阶数。中心值始终先形成残差及 $z$ 再形成 Gram。复延拓中，共轭因子按 $\overline{f(\bar z)}$ 延拓，仍解析，并受同一对称椭圆界控制。

最后证明求积误差常数：参数2椭圆内有界解析函数的 Chebyshev 系数可由圆周 Fourier 积分得到，系数范数至多 $2M2^{-j}$。截断到次数 $2q-1$ 的尾范数不超过 $4M2^{-2q}$。映到 $[0,1]$ 后，积分及正权 Gauss 规则的范数均为1，单变量误差至多 $8M2^{-2q}$。对张量规则逐变量作差得到至多 $16M2^{-2q}$；代码采用更宽的
$$\varepsilon_{elem}=32M2^{-2q}.$$
按此界逐元选阶并累加，得到 JSON 中的积分误差；随后另加无穷级数误差和高频尾交叉界。该余项不包含浮点舍入。

</details>
