# 舍入误差估计

## 目的

本次估计给出主区间左、右端点的数值位移约 **9.05556e-12 / 1.0486e-11**，分别占原宽度的 **0.2029% / 0.2350%**。这两个工作数值包含积分/装配评价，以及下文对相位、几何和节点缓存的启发式解释。

全文给出**舍入误差估计**，不把它当作可靠误差界。原来的区间和 $(H)$ 仍保留“舍入排除”的解释。这里比较标准误差模型、实测抵消尺度、条件数和现有余量；没有逐操作验证库函数、运算路径或舍入方向。

原区间为 $[2.4287286691977914,2.4287286736601232]$，采用高精度差值得宽度 $W=4.462331640314124\times10^{-9}$。总表覆盖第8a清单的四类依赖；自由试探系数的生成、整数恒等式和纯诊断不需要假造正余量。

## 用到的标准事实

1. 标准模型取 $u=2^{-53}$、$\gamma_n=nu/(1-nu)$，和/内积/矩阵乘法采用 $\gamma_n$ 乘绝对项和；无溢出及可忽略下溢的前提未逐运算核验。定义和基本模型已核对 [Higham–Mary 的作者稿，(1.1)、(1.2)](https://eprints.maths.manchester.ac.uk/2673/1/paper.pdf)。Higham, *Accuracy and Stability of Numerical Algorithms*, 2nd ed., 2002，第3章的具体求和定理编号为 **citation to verify**，本文不写未核对的定理号。
2. Hermitian 特征值的绝对扰动按 $\|\Delta A\|_2$ 解释，矩阵估计中用1范数或Frobenius范数替代。采用 Weyl 的这一标准形式；定理编号为 citation to verify；参见 [LAPACK 对称特征值误差说明](https://www.netlib.org/lapack/lug/node90.html)。
3. 对稠密对称特征值计算，取工作项 $10nu\|A\|_1$。Netlib 只给随维数温和增长的 $p(n)$；**10n是本次选择的工作常数，不是LAPACK承诺的通用常数**；具体算法定理编号为 citation to verify。ARPACK 另加10倍已测残差。LDL的微小枢轴不直接等于谱间隔，本文用相应移位后的第二特征值间隔比较。
4. 对残差平方，采用 $2\sqrt S\,\eta+\eta^2$ 的扰动尺度，$\eta$ 来自相减前绝对项和。不能把 $S$ 本身乘一个 $\gamma_n$ 就结束；整数RT3基的内部抵消尤其重要。
5. sin/cos/exp/sqrt 的库误差按约1 ulp建模，并经输入导数传播。它们进入下面选定的500、1000、10000等运算路径常数；这些常数是源码循环与实测尺度给出的估计，不是逐操作计数所得的可靠常数。未采用随机独立舍入假设或 $\sqrt n\,u$ 经验律。

## 总表

表中“比值”是余量除以估计效应。符号余量、截断准确度预算、数值大小是不同用途：例如E行用原截断半宽作预算，端点行用W作预算，分项解析余量的末位行只估计该标量本身的计算误差。不能把解析余项当作吸收上游算术误差的备用余额。

共有125行，阶段分布为A 3、B 30、C 26、D 8、qj 34、handoffs 24。A的两行概括每端236个矩阵，**所有472个矩阵**的逐项余量、范数、装配项、求解器项和比值均在 [A-panel-estimates.csv](../../../test/numerical-directions/rounding-estimate-v1/output/A-panel-estimates.csv)。原参考中的236是每端矩阵数。

路径 `output/`、`qj/`、`core/`、`band/` 指本实验目录；`h-cert-v1/` 等指 `test/numerical-directions/` 下的原实验。每行完整输入还保存在 [estimates.json](../../../test/numerical-directions/rounding-estimate-v1/output/estimates.json) 的同名 `id.inputs`；[estimates.csv](../../../test/numerical-directions/rounding-estimate-v1/output/estimates.csv) 是同一张表。下列四类公式给出这些输入的含义。

**A：材料矩、覆盖和特征值。** 先测曲线梯形项的绝对和矩阵 $B_{abs}$，取 $e_B=\gamma_{8J+100}\|B_{abs}\|_1$、$e_M=16e_B$、$e_G=256[(1+2b)e_B+\gamma_{8n}b^2]$，其中 $b=(\|M\|_1+1)/16$。下/上端装配项分别为 $\ell e_M+e_K$、$h e_M+h^2e_G/d+e_K$，再加源码加法尺度和 $10nu\|A\|_1$。$e_K=100u\max(\|A_-\|_1+\ell\|M\|_1,\|A_+\|_1+h\|M\|_1)$；每个面板的 $\ell,h,d$ 都在CSV。

**B：同时估计曲线矩和二次残差抵消。** 仅用 $\gamma\kappa(\|C\|+\|E\|)$ 会漏掉材料矩乘响应系数、Poisson权重和二次残差的放大，所以最终取它与下面详细传播的较大值。$\kappa=149\sim349$ 来自原JSON。材料矩X的绝对行和约5.72/5.79，而曲线积分绝对项矩阵行和约55.44/58.08；后者与 $\gamma_{20680}$ 给出 $e_X\approx1.27/1.33\times10^{-10}$。源项IT/TT的同类绝对和另测，IT使用全相位的分母最小值和几何级数最大值，TT使用系数模的最大值。没有重解N=26的响应。

B式的全部标量在 `extras.B[*].details`，定义如下。$z$为原多项式响应范数，$T$为源的全线L2 Frobenius尺度，$g=\operatorname{tr}G_1$，$f=(17\lambda+1)T$，$N_A=\sqrt{17g}+16\lambda z+f$、$N_B=N_A+16\lambda z$。取 $e_X'=e_X+\gamma_{8n}\||X|\|_1$，$e_F=16\lambda e_{IT}+(\lambda+1)\gamma_{200}T$，
$$\eta_r=e_F+16\lambda e_X'z+\gamma_{20}\{f+(N_A+\lambda z)+\lambda(1+16\||X|\|_1)z\}.$$
C的正项尺度与矩误差为
$$c_{abs}=16\lambda T^2+2fz+z\{N_A+\lambda z+\lambda(1+16\||X|\|_1)z\},$$
$$e_C=16\lambda e_{TT}+2ze_F+16\lambda z^2e_X'+\gamma_{8n+Pq}c_{abs}.$$
G0误差估计同时加入 $(N_A^2+N_B^2)e_X'$、$2[(\lambda+1)N_A+(17\lambda+1)N_B]e_{IT}$、$[(\lambda+1)^2+(17\lambda+1)^2]e_{TT}$、解析源Tcoef/Tbg的 $\gamma_{200}$ 项，以及 $\gamma_{8n+Pq}\kappa17g$。还加入缓存 $X(D_cz_j)$ 的计算项：旧数据没有逐系数绝对和，使用原JSON的 `max_residual_bound` 作偏大的缓存尺度，令 $e_{XA}=\gamma_{8n}\||X|\|_1\,\texttt{max\_residual\_bound}$，缓存项取 $(N_A+N_B)e_{XA}+16\lambda N_B\gamma_{8n}\||X|\|_1z$。解析源两项明确取 $2N_A(\lambda+1)\gamma_{200}T+(\lambda+1)^2\gamma_{200}T^2$。记全部和为 $e_{G0}$。

令 $d_t=[2\pi(N+1)-\pi]^2+1/4$。下端以 $H_t=\operatorname{tr}E/K$、上端以 $H_t=\operatorname{tr}E$ 作工作尺度，
$$e_H=e_{G0}/d_t+2\sqrt{H_t}(2\eta_r)+(2\eta_r)^2+\gamma_{Pq}H_t.$$
下端 $e_E=K e_H$。上端令 $c=17\lambda(1+\lambda/d)$、$V_t=\operatorname{tr}E/c$，
$$e_V=e_{G0}/d_t^2+2\sqrt{V_t}(4\eta_r)+(4\eta_r)^2+\gamma_{Pq}V_t,\quad e_E=e_H+c e_V.$$
最后的Schur估计为 $e_C+e_E$ 加特征值计算项。这里使用名义残差与条件数作一阶工作尺度；它们本身仍来自舍入排除计算。

**C：低场、RT3基和无穷尾。** 正项与绝对基项分别测量；首胞和重复胞按 $s_q=\|T_{tr}^{-1/2}\|^2$、$g=\|G_{nod}\|^2$、原无穷和放大量w组合。对任一尺度 $B$ 使用 $s_q(B_{first}+gwB_{bulk})$。$P_Q$ 为能量与负质量项的绝对尺度，$B_R$ 为Lagrange/整数RT3基展开后相减前项的平方和，$B_u$为场/梯度的绝对基项。取
$$\eta_R=(\gamma_{1000}+100e_x)\sqrt{B_R},\quad e_R=2\sqrt{\|R_s\|_1}\eta_R+\eta_R^2+(\gamma_N+e_D)\|R_s\|_1,$$
$$\eta_u=(\gamma_{500}+100e_x)\sqrt{B_u},\quad e_Q=(\gamma_N+e_D)P_Q+2\sqrt{P_Q}\eta_u+\eta_u^2.$$
$N=8q_{max}^2+n_{parts}+20\cdot8\cdot192$。这里 $e_x,e_w$ 取实际Gauss对照的最大节点绝对差、权重相对差的2倍，$e_D=2e_w+e_x/(1-x_{max})$；100是对节点变化的工作导数放大量。gap仅指保留33迹上的差。对Z同样估计 $u+Kr_2$ 的变化，再取 $e_\Lambda=e_Q+K e_R+(b_H^2/A_H)e_Z$ 加标量计算项。上下差中的Q是同一缓存，打印gap的估计保留其最后一次相减误差。原矩阵坐标的误差尺度用 $q_{max}e_\Lambda$。表里的归一与原坐标数值分开列出。

**D、qj及标量。** D材料积分按实际曲线绝对项和、$\gamma_{8J+200}$、材料组装绝对行和及 $\||P|^T|M_*||P|\|_1$ 传播，边界乘积使用对应绝对包络。重新计算解析H/M1/端口映射的绝对包络，并加入H-I项。来自两侧C的误差估计乘 $\coth(1)$ 后相加。qj见下一节。标量正函数链采用表中明确的 $\gamma_{500}$ 或 $\gamma_{10000}$；二次几何缺陷的相减另按0.4的坐标尺度估计，不能直接用很小的缺陷值乘u。

| 阶段/ID | 量 | 余量/准确度预算 | 估计公式 | 输入 | 估计舍入效应 | 比值 | 源码或JSON来源 |
|---|---|---|---|---|---|---|---|
| A / A-lower | 236个lower端面板符号（最小比值） | 0.000139722 | lambda*dM+[lambda^2/den*dG]+dK+gamma_ops*abs_terms+10*n*u*norm1 | n=169; matrix_norm1=3150.16; 全输入: A-lower.inputs | 9.31211e-10 | 150044 | output/run-003/science/panels.csv；band/band_estimate.m:24 |
| A / A-upper | 236个upper端面板符号（最小比值） | 0.0075205 | lambda*dM+[lambda^2/den*dG]+dK+gamma_ops*abs_terms+10*n*u*norm1 | n=169; matrix_norm1=3200.67; 全输入: A-upper.inputs | 1.98954e-09 | 3.78003e+06 | output/run-003/science/panels.csv；band/band_estimate.m:24 |
| A / A-tail | 尾分母正性 | 1572.32 | gamma_100*(tail+17*lambda) | min_den=1572.32; max_scale=1890.86; 全输入: A-tail.inputs | 2.09928e-11 | 7.48982e+13 | output/run-003/science/panels.csv |
| B / B-run-009-M8 | a=0.12，lambda=1.7424，M=8 Schur符号 | 0.0235558 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=17; nd=2809; P=64; q=40; J=2560; kappa=155.973; Cminus_norm1=0.542424; 全输入: B-run-009-M8.inputs | 1.66261e-06 | 14168 | h-cert-v1/output/run-009/science/result.json |
| B / B-tail-run-009-M8 | a=0.12 lambda=1.7424 M=8 尾分母 | 0.5 | gamma_500*(0.5+h) | h=4.70955e-13; x=3.32061e-05; penalty=2.20529e-09; 全输入: B-tail-run-009-M8.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-009/science/result.json/tests/tail |
| B / B-run-009-M10 | a=0.12，lambda=1.7424，M=10 Schur符号 | 0.0235558 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=21; nd=2809; P=64; q=40; J=2560; kappa=155.973; Cminus_norm1=0.542424; 全输入: B-run-009-M10.inputs | 1.66261e-06 | 14168 | h-cert-v1/output/run-009/science/result.json |
| B / B-tail-run-009-M10 | a=0.12 lambda=1.7424 M=10 尾分母 | 0.5 | gamma_500*(0.5+h) | h=5.8581e-16; x=1.17113e-06; penalty=2.74311e-12; 全输入: B-tail-run-009-M10.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-009/science/result.json/tests/tail |
| B / B-run-010-M8 | a=0.12，lambda=5.6169，M=8 Schur符号 | 0.500643 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=17; nd=2809; P=64; q=40; J=2560; kappa=349.207; Cminus_norm1=1.42297; 全输入: B-run-010-M8.inputs | 4.20247e-06 | 119131 | h-cert-v1/output/run-010/science/result.json |
| B / B-tail-run-010-M8 | a=0.12 lambda=5.6169 M=8 尾分母 | 0.5 | gamma_500*(0.5+h) | h=1.11081e-12; x=7.07513e-05; penalty=1.00115e-08; 全输入: B-tail-run-010-M8.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-010/science/result.json/tests/tail |
| B / B-run-010-M10 | a=0.12，lambda=5.6169，M=10 Schur符号 | 0.500413 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=21; nd=2809; P=64; q=40; J=2560; kappa=349.207; Cminus_norm1=1.42297; 全输入: B-run-010-M10.inputs | 4.20247e-06 | 119076 | h-cert-v1/output/run-010/science/result.json |
| B / B-tail-run-010-M10 | a=0.12 lambda=5.6169 M=10 尾分母 | 0.5 | gamma_500*(0.5+h) | h=1.37649e-15; x=2.49058e-06; penalty=1.2406e-11; 全输入: B-tail-run-010-M10.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-010/science/result.json/tests/tail |
| B / B-run-007-M8 | a=0.2，lambda=1.7424，M=8 Schur符号 | 0.00428913 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=17; nd=2809; P=64; q=40; J=2560; kappa=148.809; Cminus_norm1=0.543601; 全输入: B-run-007-M8.inputs | 1.05385e-05 | 406.996 | h-cert-v1/output/run-007/science/result.json |
| B / B-tail-run-007-M8 | a=0.2 lambda=1.7424 M=8 尾分母 | 0.5 | gamma_500*(0.5+h) | h=4.70955e-13; x=3.32061e-05; penalty=2.20529e-09; 全输入: B-tail-run-007-M8.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-007/science/result.json/tests/tail |
| B / B-run-007-M10 | a=0.2，lambda=1.7424，M=10 Schur符号 | 0.00428913 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=21; nd=2809; P=64; q=40; J=2560; kappa=148.809; Cminus_norm1=0.543601; 全输入: B-run-007-M10.inputs | 1.05385e-05 | 406.996 | h-cert-v1/output/run-007/science/result.json |
| B / B-tail-run-007-M10 | a=0.2 lambda=1.7424 M=10 尾分母 | 0.5 | gamma_500*(0.5+h) | h=5.8581e-16; x=1.17113e-06; penalty=2.74311e-12; 全输入: B-tail-run-007-M10.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-007/science/result.json/tests/tail |
| B / B-run-011-M8 | a=0.2，lambda=5.6169，M=8 Schur符号 | 0.500643 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=17; nd=2809; P=64; q=40; J=2560; kappa=312.886; Cminus_norm1=2.18337; 全输入: B-run-011-M8.inputs | 2.11158e-05 | 23709.4 | h-cert-v1/output/run-011/science/result.json |
| B / B-tail-run-011-M8 | a=0.2 lambda=5.6169 M=8 尾分母 | 0.5 | gamma_500*(0.5+h) | h=1.11081e-12; x=7.07513e-05; penalty=1.00115e-08; 全输入: B-tail-run-011-M8.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-011/science/result.json/tests/tail |
| B / B-run-011-M10 | a=0.2，lambda=5.6169，M=10 Schur符号 | 0.500413 | max(gamma_(8*nd+P*q+8*J)*kappa*(Cnorm+Enorm),eC+eE)+10*p*u*Cminus_norm；详细传播见B式 | n=21; nd=2809; P=64; q=40; J=2560; kappa=312.886; Cminus_norm1=2.18337; 全输入: B-run-011-M10.inputs | 2.11158e-05 | 23698.5 | h-cert-v1/output/run-011/science/result.json |
| B / B-tail-run-011-M10 | a=0.2 lambda=5.6169 M=10 尾分母 | 0.5 | gamma_500*(0.5+h) | h=1.37649e-15; x=2.49058e-06; penalty=1.2406e-11; 全输入: B-tail-run-011-M10.inputs | 2.77556e-14 | 1.80144e+13 | h-cert-v1/output/run-011/science/result.json/tests/tail |
| C / C-left-Lambda | left下DtN最小特征值（trace归一） | 0.362118 | gamma_path*positive_Q+2*sqrt(positive_Q)*etaU+etaU^2+Kplus*eR+phi*eZ+gamma_100*(Qnorm+K*Rnorm+phi*Znorm) | qnorm1_scaled=0.999676; rnorm1_scaled=3.89541e-08; positive_Q_scaled=1556.12; large_terms_squared_scaled=6487.33; basis_terms_squared_scaled=5.41676e+13; field_terms_squared_scaled=8.58616e+06; quadrature_path=90972; eQ=5.07015e-08; eR=5.22541e-10; eZ=0.000865825; eLambda_scaled=1.96962e-07; 全输入: C-left-Lambda.inputs | 1.96962e-07 | 1.83852e+06 | h-dtn-v1/output/run-006/science/result.json + output/run-014/science/result.json |
| C / C-left-r | left残差范数r | 3.8954e-08 | 2*sqrt(norm1(Rscaled))*eta+eta^2+(gamma_path+duffy_error)*norm1(Rscaled)；eta=(gamma_1000+100*node_error)*sqrt(B_R) | qnorm1_scaled=0.999676; rnorm1_scaled=3.89541e-08; positive_Q_scaled=1556.12; large_terms_squared_scaled=6487.33; basis_terms_squared_scaled=5.41676e+13; field_terms_squared_scaled=8.58616e+06; quadrature_path=90972; eQ=5.07015e-08; eR=5.22541e-10; eZ=0.000865825; eLambda_scaled=1.96962e-07; 全输入: C-left-r.inputs | 5.22541e-10 | 74.5473 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-budget | left Kplus*r预算 | 0.000389097 | Kplus*eR+gamma_100*Kplus*r | qnorm1_scaled=0.999676; rnorm1_scaled=3.89541e-08; positive_Q_scaled=1556.12; large_terms_squared_scaled=6487.33; basis_terms_squared_scaled=5.41676e+13; field_terms_squared_scaled=8.58616e+06; quadrature_path=90972; eQ=5.07015e-08; eR=5.22541e-10; eZ=0.000865825; eLambda_scaled=1.96962e-07; 全输入: C-left-budget.inputs | 1.46259e-07 | 2660.32 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-gap | left上下DtN间隙数值 | 1.09308e-05 | (Kplus+Kminus)*eR+phi*eZ+gamma_30*(2*Qnorm+gap) | qnorm1_scaled=0.999676; rnorm1_scaled=3.89541e-08; positive_Q_scaled=1556.12; large_terms_squared_scaled=6487.33; basis_terms_squared_scaled=5.41676e+13; field_terms_squared_scaled=8.58616e+06; quadrature_path=90972; eQ=5.07015e-08; eR=5.22541e-10; eZ=0.000865825; eLambda_scaled=1.96962e-07; 全输入: C-left-gap.inputs | 1.4663e-07 | 74.5468 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-AH | left高频提升分母AH | 0.999707 | gamma_500*(aH+Kplus*bH2) | aH=0.999707; bH2=1.09938e-09; Kplus=279.9; 全输入: C-left-AH.inputs | 5.54949e-14 | 1.80144e+13 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-eps_Q | left eps_Q的末位 | 2.87586e-14 | gamma_10000*abs(value) | value=2.87586e-14; path_assumed=10000; 全输入: C-left-eps_Q.inputs | 3.19285e-26 | 9.0072e+11 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-eps_R | left eps_R的末位 | 1.58634e-14 | gamma_10000*abs(value) | value=1.58634e-14; path_assumed=10000; 全输入: C-left-eps_R.inputs | 1.76119e-26 | 9.0072e+11 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-eps_Z | left eps_Z的末位 | 1.58109e-12 | gamma_10000*abs(value) | value=1.58109e-12; path_assumed=10000; 全输入: C-left-eps_Z.inputs | 1.75536e-24 | 9.0072e+11 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-b_H_squared | left b_H_squared的末位 | 1.09938e-09 | gamma_10000*abs(value) | value=1.09938e-09; path_assumed=10000; 全输入: C-left-b_H_squared.inputs | 1.22056e-21 | 9.0072e+11 | h-dtn-v1/output/run-006/science/result.json |
| C / C-left-high_penalty | left high_penalty的末位 | 7.30756e-10 | gamma_10000*abs(value) | value=7.30756e-10; path_assumed=10000; 全输入: C-left-high_penalty.inputs | 8.11302e-22 | 9.0072e+11 | h-dtn-v1/output/run-006/science/result.json |
| C / C-right-Lambda | right下DtN最小特征值（trace归一） | 0.300576 | gamma_path*positive_Q+2*sqrt(positive_Q)*etaU+etaU^2+Kplus*eR+phi*eZ+gamma_100*(Qnorm+K*Rnorm+phi*Znorm) | qnorm1_scaled=0.999676; rnorm1_scaled=3.8954e-08; positive_Q_scaled=1569.64; large_terms_squared_scaled=6666.62; basis_terms_squared_scaled=5.41317e+13; field_terms_squared_scaled=1.22152e+07; quadrature_path=90936; eQ=5.65496e-08; eR=5.22367e-10; eZ=0.00100376; eLambda_scaled=2.02761e-07; 全输入: C-right-Lambda.inputs | 2.02761e-07 | 1.48242e+06 | h-dtn-v1/output/run-008/science/result.json + output/run-015/science/result.json |
| C / C-right-r | right残差范数r | 3.8954e-08 | 2*sqrt(norm1(Rscaled))*eta+eta^2+(gamma_path+duffy_error)*norm1(Rscaled)；eta=(gamma_1000+100*node_error)*sqrt(B_R) | qnorm1_scaled=0.999676; rnorm1_scaled=3.8954e-08; positive_Q_scaled=1569.64; large_terms_squared_scaled=6666.62; basis_terms_squared_scaled=5.41317e+13; field_terms_squared_scaled=1.22152e+07; quadrature_path=90936; eQ=5.65496e-08; eR=5.22367e-10; eZ=0.00100376; eLambda_scaled=2.02761e-07; 全输入: C-right-r.inputs | 5.22367e-10 | 74.5722 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-budget | right Kplus*r预算 | 0.000389097 | Kplus*eR+gamma_100*Kplus*r | qnorm1_scaled=0.999676; rnorm1_scaled=3.8954e-08; positive_Q_scaled=1569.64; large_terms_squared_scaled=6666.62; basis_terms_squared_scaled=5.41317e+13; field_terms_squared_scaled=1.22152e+07; quadrature_path=90936; eQ=5.65496e-08; eR=5.22367e-10; eZ=0.00100376; eLambda_scaled=2.02761e-07; 全输入: C-right-budget.inputs | 1.4621e-07 | 2661.21 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-gap | right上下DtN间隙数值 | 1.09308e-05 | (Kplus+Kminus)*eR+phi*eZ+gamma_30*(2*Qnorm+gap) | qnorm1_scaled=0.999676; rnorm1_scaled=3.8954e-08; positive_Q_scaled=1569.64; large_terms_squared_scaled=6666.62; basis_terms_squared_scaled=5.41317e+13; field_terms_squared_scaled=1.22152e+07; quadrature_path=90936; eQ=5.65496e-08; eR=5.22367e-10; eZ=0.00100376; eLambda_scaled=2.02761e-07; 全输入: C-right-gap.inputs | 1.46581e-07 | 74.5716 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-AH | right高频提升分母AH | 0.999707 | gamma_500*(aH+Kplus*bH2) | aH=0.999707; bH2=1.09938e-09; Kplus=279.9; 全输入: C-right-AH.inputs | 5.54949e-14 | 1.80144e+13 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-eps_Q | right eps_Q的末位 | 3.93014e-14 | gamma_10000*abs(value) | value=3.93014e-14; path_assumed=10000; 全输入: C-right-eps_Q.inputs | 4.36333e-26 | 9.0072e+11 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-eps_R | right eps_R的末位 | 2.1354e-14 | gamma_10000*abs(value) | value=2.1354e-14; path_assumed=10000; 全输入: C-right-eps_R.inputs | 2.37077e-26 | 9.0072e+11 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-eps_Z | right eps_Z的末位 | 2.20932e-12 | gamma_10000*abs(value) | value=2.20932e-12; path_assumed=10000; 全输入: C-right-eps_Z.inputs | 2.45283e-24 | 9.0072e+11 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-b_H_squared | right b_H_squared的末位 | 1.09938e-09 | gamma_10000*abs(value) | value=1.09938e-09; path_assumed=10000; 全输入: C-right-b_H_squared.inputs | 1.22056e-21 | 9.0072e+11 | h-dtn-v1/output/run-008/science/result.json |
| C / C-right-high_penalty | right high_penalty的末位 | 1.10831e-09 | gamma_10000*abs(value) | value=1.10831e-09; path_assumed=10000; 全输入: C-right-high_penalty.inputs | 1.23047e-21 | 9.0072e+11 | h-dtn-v1/output/run-008/science/result.json |
| D / D-count | 核心第二方向与负惯性1 | 0.365374 | 3*lambda/cW*(moment_error+gamma_(16*n)*abs_material)+gamma_(16*n)*abs_boundary+10*n*u*norm1+10*resL+coth(1)*(eLambda_left+right)+Hdef_effect+analytic_Gram_effect | dimension=1122; center_norm1=10.2102; total=7.64799e-07; 全输入: D-count.inputs | 7.64799e-07 | 477738 | output/run-007/science/result.json |
| D / D-near-shift | 近贴边shift后的第二方向 | 1e-10 | 同D-count；margin=lambda2-shift，LDL枢轴只作诊断 | dimension=1122; center_norm1=10.2102; total=7.64799e-07; 全输入: D-near-shift.inputs | 7.64799e-07 | 0.000130753 | output/run-007/science/result.json |
| D / D-wide-shift | 0.36移位后的第二方向 | 0.00537369 | 同D-count；margin=lambda2-0.36-epsilon | dimension=1122; center_norm1=10.2102; total=7.64799e-07; 全输入: D-wide-shift.inputs | 7.64799e-07 | 7026.28 | output/run-007/science/result.json |
| D / D-printed-gamma | 原打印第二下端0.365373688 | 7.81932e-10 | lambda2-epsilon-printed_gamma 对比同D-count估计 | dimension=1122; center_norm1=10.2102; total=7.64799e-07; 全输入: D-printed-gamma.inputs | 7.64799e-07 | 0.0010224 | output/run-007/science/result.json |
| D / D-first | 核心负方向 | 6.41714 | 同D-count | dimension=1122; center_norm1=10.2102; total=7.64799e-07; 全输入: D-first.inputs | 7.64799e-07 | 8.39062e+06 | output/run-007/science/result.json |
| D / D-cW | 补空间正分母cW | 0.997678 | gamma_500*(1+qmax*Ch^2) | Ch=0.00994657; qmax=23.4676; 全输入: D-cW.inputs | 5.564e-14 | 1.79309e+13 | output/run-007/science/result.json |
| D / D-Gram | 代表函数2阶余项Gram正性 | 0.00496401 | gamma_5000*max(1,norm1(P)*norminf(P)) | Pnorm1=25.1697; Pnorminf=20.6872; 全输入: D-Gram.inputs | 2.89041e-10 | 1.7174e+07 | output/run-007/science/result.json |
| D / D-epsilon | 解析积分epsilon的末位 | 2.06203e-09 | gamma_10000*epsilon | epsilon=2.06203e-09; 全输入: D-epsilon.inputs | 2.28932e-21 | 9.0072e+11 | output/run-007/science/result.json |
| qj / qj-E | E数值 | 2.00018e-12 | gamma_sum*E+2*gamma_500*sqrt(E*ZE)+gamma_10000*abs_E_poly+gauss_E_effect+object_E_effect | value=11.4709; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-E.inputs | 2.2742e-11 | 0.0879507 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-M | M数值 | 6.90203e-12 | gamma_sum*M+2*gamma_500*sqrt(M*ZM)+gamma_(10000+n_elements)*abs_C0+curve_defect_C0_effect+mass_bias_rounding+gauss_M_effect+object_M_effect | value=4.72301; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-M.inputs | 5.18729e-12 | 1.33057 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-Scommon | Scommon数值 | 2.59781e-10 | 2*sqrt(Scommon)*etaCommon+etaCommon^2+gamma_10000*abs_Spoly+gamma_sum*Scommon | value=2.59781e-10; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-Scommon.inputs | 2.9221e-13 | 889.02 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-Sinterface | Sinterface数值 | 3.49773e-11 | 2*sqrt(Sint)*etaInt+etaInt^2+gamma_10000*abs_pm*80*10 | value=3.49773e-11; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-Sinterface.inputs | 7.03499e-15 | 4971.91 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-Splus | Splus数值 | 2.94758e-10 | eScommon+eSinterface+object_S_effect | value=2.94758e-10; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-Splus.inputs | 2.99254e-13 | 984.977 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-C0 | C0数值 | 3.01753e-08 | gamma_(10000+n_elements)*sum(abs(C0_arc))+curve_defect_C0_effect | value=3.01753e-08; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-C0.inputs | 2.2354e-13 | 134988 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-mass-bias | mass-bias数值 | 2.59764e-12 | (gamma_10000+3*gamma_200*0.4/minD0)*bias | value=6.80236e-12; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-mass-bias.inputs | 2.81645e-18 | 922309 | qj-cert-v2/output/run-004/science/interface-certificate.json; output/run-009/science/estimate-data.json |
| qj / qj-q | q=1+E/M | 3.42873 | eE/M+E*eM/M^2 | q=3.42873; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-q.inputs | 7.48263e-12 | 4.58225e+11 | qj/four_corners.m:9 |
| qj / qj-J | J的重组数值 | 0.291653 | eS/M+S*eM/M^2+eq/s^2+gamma_30*sum(abs(terms)) | q=3.42873; absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-J.inputs | 7.0276e-13 | 4.15011e+11 | research/explorations/numerical-directions/qj-bounds-proof.md:118 |
| qj / qj-delta | 稳定delta严格正性 | 2.13983e-10 | abs(d_delta/dE)*eE+abs(d_delta/dM)*eM+(q/M)*eS+gamma_100*abs_terms | absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-delta.inputs | 2.17247e-13 | 984.977 | qj/four_corners.m:9 |
| qj / qj-Jacobian | Jacobian | 7.73167e-06 | gamma_path*(0.5/sqrt(detmin))*scale | detmin=7.73167e-06; h_estimate=0.00278059; 全输入: qj-Jacobian.inputs | 1.54354e-16 | 5.00906e+10 | qj-cert-v2/output/run-004/science/certificates.json/templates.geometry; interface-certificate.json/templates |
| qj / qj-native-injectivity | native-injectivity | 0.884879 | gamma_path*(0.5/sqrt(detmin))*scale | detmin=7.73167e-06; h_estimate=0.00278059; 全输入: qj-native-injectivity.inputs | 1.99638e-11 | 4.43241e+10 | qj-cert-v2/output/run-004/science/certificates.json/templates.geometry; interface-certificate.json/templates |
| qj / qj-fitted-injectivity | fitted-injectivity | 0.992338 | gamma_path*(0.5/sqrt(detmin))*scale | detmin=7.73167e-06; h_estimate=0.00278059; 全输入: qj-fitted-injectivity.inputs | 1.99638e-11 | 4.97068e+10 | qj-cert-v2/output/run-004/science/certificates.json/templates.geometry; interface-certificate.json/templates |
| qj / qj-inverse-selfmap | inverse-selfmap | 0.0315321 | gamma_path*(0.5/sqrt(detmin))*scale | detmin=7.73167e-06; h_estimate=0.00278059; 全输入: qj-inverse-selfmap.inputs | 1.99638e-10 | 1.57946e+08 | qj-cert-v2/output/run-004/science/certificates.json/templates.geometry; interface-certificate.json/templates |
| qj / qj-branch-coverage | branch-coverage | 0.0515773 | gamma_path*(0.5/sqrt(detmin))*scale | detmin=7.73167e-06; h_estimate=0.00278059; 全输入: qj-branch-coverage.inputs | 1.99638e-10 | 2.58354e+08 | qj-cert-v2/output/run-004/science/certificates.json/templates.geometry; interface-certificate.json/templates |
| qj / qj-reciprocal | 倒数模型已接受分支正性 | 0.977676 | gamma_10000*(0.5/hgeo) | min_d0=2.56548e-05; min_1_minus_k=0.977676; min_lo_over_d0=0.977676; accepted_calls=304; rejected_calls=0; hgeo=0.00278059; 全输入: qj-reciprocal.inputs | 1.99638e-10 | 4.89724e+09 | output/run-009/science/estimate-data.json/reciprocal_tests |
| qj / qj-sign-Dmu-00 | 角00 Dmu | 0.945405 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.2332730470793034260130305089301430332698809297909435860304554563069862805032 +/- 7.02e-78]', '[-0.3663869221770153758206312597071568179968761986687597108563275506055135554229 +/- 7.00e-77]', '-2.742399999999999948840923025272786617279052734375000000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=4.4063; 全输入: qj-sign-Dmu-00.inputs | 8.04101e-12 | 1.17573e+11 | qj/four_corners.m:8 |
| qj / qj-sign-minusDnu-00 | 角00 minusDnu | 4.39165 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.5628443790909578912955329811145004343245056245282610800963046326379330888082 +/- 3.49e-77]', '[-2.296836940400048686431349824525615469232478495130702441733081260521912754268 +/- 2.56e-76]', '-6.616900000000000225952589971711859107017517089843750000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=17.3043; 全输入: qj-sign-minusDnu-00.inputs | 2.67524e-11 | 1.64159e+11 | qj/four_corners.m:8 |
| qj / qj-sign-H-00 | 角00 H | 3.01411 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_50*sum(abs(term)) | coefficients=['[0.5435444252190428922942707327015471180464211716872472433119424032119201938771 +/- 2.54e-77]', '[-0.681945625353093174212685954744157092329866745583027940201371949382369463992 +/- 4.60e-76]', '[-18.14618656000000028113788630435009262343265990349020760756017234260895065745 +/- 1.05e-76]']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=9.45579; 全输入: qj-sign-H-00.inputs | 2.13816e-11 | 1.40968e+11 | qj/four_corners.m:8 |
| qj / qj-sign-Dmu-01 | 角01 Dmu | 0.945405 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.2332730470793034260130305089301430332698809297909435860304554563069862805032 +/- 7.02e-78]', '[-0.3663869221770153758206312597071568179968761986687597108563275506055135554229 +/- 7.00e-77]', '-2.742399999999999948840923025272786617279052734375000000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=4.4063; 全输入: qj-sign-Dmu-01.inputs | 8.04101e-12 | 1.17573e+11 | qj/four_corners.m:8 |
| qj / qj-sign-minusDnu-01 | 角01 minusDnu | 4.39165 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.5628443790909578912955329811145004343245056245282610800963046326379330888082 +/- 3.49e-77]', '[-2.296836940400048686431349824525615469232478495130702441733081260521912754268 +/- 2.56e-76]', '-6.616900000000000225952589971711859107017517089843750000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=17.3043; 全输入: qj-sign-minusDnu-01.inputs | 2.67524e-11 | 1.64159e+11 | qj/four_corners.m:8 |
| qj / qj-sign-H-01 | 角01 H | 3.01411 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_50*sum(abs(term)) | coefficients=['[0.5435444252190428922942707327015471180464211716872472433119424032119201938771 +/- 2.54e-77]', '[-0.681945625353093174212685954744157092329866745583027940201371949382369463992 +/- 4.60e-76]', '[-18.14618656000000028113788630435009262343265990349020760756017234260895065745 +/- 1.05e-76]']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=9.45579; 全输入: qj-sign-H-01.inputs | 2.13816e-11 | 1.40968e+11 | qj/four_corners.m:8 |
| qj / qj-sign-Dmu-10 | 角10 Dmu | 0.945405 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.2332730470793034260130305089301430332698809297909435860304554563069862805032 +/- 7.02e-78]', '[-0.3663869221770153758206312597071568179968761986687597108563275506055135554229 +/- 7.00e-77]', '-2.742399999999999948840923025272786617279052734375000000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=4.4063; 全输入: qj-sign-Dmu-10.inputs | 8.04101e-12 | 1.17573e+11 | qj/four_corners.m:8 |
| qj / qj-sign-minusDnu-10 | 角10 minusDnu | 4.39165 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.5628443790909578912955329811145004343245056245282610800963046326379330888082 +/- 3.49e-77]', '[-2.296836940400048686431349824525615469232478495130702441733081260521912754268 +/- 2.56e-76]', '-6.616900000000000225952589971711859107017517089843750000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=17.3043; 全输入: qj-sign-minusDnu-10.inputs | 2.67524e-11 | 1.64159e+11 | qj/four_corners.m:8 |
| qj / qj-sign-H-10 | 角10 H | 3.01411 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_50*sum(abs(term)) | coefficients=['[0.5435444252190428922942707327015471180464211716872472433119424032119201938771 +/- 2.54e-77]', '[-0.681945625353093174212685954744157092329866745583027940201371949382369463992 +/- 4.60e-76]', '[-18.14618656000000028113788630435009262343265990349020760756017234260895065745 +/- 1.05e-76]']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=9.45579; 全输入: qj-sign-H-10.inputs | 2.13816e-11 | 1.40968e+11 | qj/four_corners.m:8 |
| qj / qj-sign-Dmu-11 | 角11 Dmu | 0.945405 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.2332730470793034260130305089301430332698809297909435860304554563069862805032 +/- 7.02e-78]', '[-0.3663869221770153758206312597071568179968761986687597108563275506055135554229 +/- 7.00e-77]', '-2.742399999999999948840923025272786617279052734375000000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=4.4063; 全输入: qj-sign-Dmu-11.inputs | 8.04101e-12 | 1.17573e+11 | qj/four_corners.m:8 |
| qj / qj-sign-minusDnu-11 | 角11 minusDnu | 4.39165 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_30*sum(abs(term)) | coefficients=['[0.5628443790909578912955329811145004343245056245282610800963046326379330888082 +/- 3.49e-77]', '[-2.296836940400048686431349824525615469232478495130702441733081260521912754268 +/- 2.56e-76]', '-6.616900000000000225952589971711859107017517089843750000000000000000000000000']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=17.3043; 全输入: qj-sign-minusDnu-11.inputs | 2.67524e-11 | 1.64159e+11 | qj/four_corners.m:8 |
| qj / qj-sign-H-11 | 角11 H | 3.01411 | sum(abs(linear_coeff)*[eE,eM,eS])+gamma_50*sum(abs(term)) | coefficients=['[0.5435444252190428922942707327015471180464211716872472433119424032119201938771 +/- 2.54e-77]', '[-0.681945625353093174212685954744157092329866745583027940201371949382369463992 +/- 4.60e-76]', '[-18.14618656000000028113788630435009262343265990349020760756017234260895065745 +/- 1.05e-76]']; error_inputs=[2.274204155034239e-11, 5.187290364962186e-12, 2.9925374616035993e-13]; absolute_term_sum=9.45579; 全输入: qj-sign-H-11.inputs | 2.13816e-11 | 1.40968e+11 | qj/four_corners.m:8 |
| qj / qj-end-L | L端点 | 4.46233e-09 | abs(dF/dE)*eE+abs(dF/dM)*eM+abs(dF/dS)*eS | value=[2.42872866919779140172415406723453790175971561 +/- 4.96e-45]; 全输入: qj-end-L.inputs | 9.05556e-12 | 492.772 | qj/four_corners.m:10；本次高精度敏感度 |
| qj / qj-end-U | U端点 | 4.46233e-09 | abs(dF/dE)*eE+abs(dF/dM)*eM+abs(dF/dS)*eS | value=[2.42872867366012304203827813254734320553979148 +/- 3.60e-45]; 全输入: qj-end-U.inputs | 1.0486e-11 | 425.553 | qj/four_corners.m:10；本次高精度敏感度 |
| qj / qj-end-I1L | I1L端点 | 0.000100312 | abs(dF/dE)*eE+abs(dF/dM)*eM+abs(dF/dS)*eS | value=[2.42867851507567032250667976032953324217381994 +/- 2.29e-45]; 全输入: qj-end-I1L.inputs | 2.54676e-08 | 3938.8 | qj/four_corners.m:10；本次高精度敏感度 |
| qj / qj-end-I1U | I1U端点 | 0.000100312 | abs(dF/dE)*eE+abs(dF/dM)*eM+abs(dF/dS)*eS | value=[2.42877882710702892880032218794236941406376714 +/- 3.43e-45]; 全输入: qj-end-I1U.inputs | 2.54684e-08 | 3938.69 | qj/four_corners.m:10；本次高精度敏感度 |
| B / B3-run-010-B_inverse | 旧B3 a=0.12 B_inverse | 2.00002 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=2.00002; relative_effect=8.39801e-06; 全输入: B3-run-010-B_inverse.inputs | 1.67962e-05 | 119076 | h-cert-v1/output/run-010/science/result.json/tests[-1] |
| B / B3-run-010-T_squared | 旧B3 a=0.12 T_squared | 6.37665 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=6.37665; relative_effect=1.76449e-09; 全输入: B3-run-010-T_squared.inputs | 1.12515e-08 | 5.66737e+08 | h-cert-v1/output/run-010/science/result.json/tests[-1] |
| B / B3-run-010-d_half | 旧B3 a=0.12 d_half | 0.0182139 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=0.0182139; relative_effect=8.39977e-06; 全输入: B3-run-010-d_half.inputs | 1.52993e-07 | 119051 | h-cert-v1/output/run-010/science/result.json/tests[-1] |
| B / B3-run-010-K_half | 旧B3 a=0.12 K_half | 364.288 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=364.288; relative_effect=8.39977e-06; 全输入: B3-run-010-K_half.inputs | 0.00305994 | 119051 | h-cert-v1/output/run-010/science/result.json/tests[-1] |
| B / B3-run-010-K_coarse | 旧B3 a=0.12 K_coarse | 78344.7 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=78344.7; relative_effect=8.39801e-06; 全输入: B3-run-010-K_coarse.inputs | 0.65794 | 119076 | h-cert-v1/output/run-010/science/result.json/tests[-1] |
| B / B3-run-011-B_inverse | 旧B3 a=0.2 B_inverse | 2.00002 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=2.00002; relative_effect=4.21968e-05; 全输入: B3-run-011-B_inverse.inputs | 8.43944e-05 | 23698.5 | h-cert-v1/output/run-011/science/result.json/tests[-1] |
| B / B3-run-011-T_squared | 旧B3 a=0.2 T_squared | 22.388 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=22.388; relative_effect=1.58096e-09; 全输入: B3-run-011-T_squared.inputs | 3.53947e-08 | 6.32526e+08 | h-cert-v1/output/run-011/science/result.json/tests[-1] |
| B / B3-run-011-d_half | 旧B3 a=0.2 d_half | 0.011504 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=0.011504; relative_effect=4.21984e-05; 全输入: B3-run-011-d_half.inputs | 4.85451e-07 | 23697.6 | h-cert-v1/output/run-011/science/result.json/tests[-1] |
| B / B3-run-011-K_half | 旧B3 a=0.2 K_half | 576.182 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=576.182; relative_effect=4.21984e-05; 全输入: B3-run-011-K_half.inputs | 0.0243139 | 23697.6 | h-cert-v1/output/run-011/science/result.json/tests[-1] |
| B / B3-run-011-K_coarse | 旧B3 a=0.2 K_coarse | 78344.7 | abs(value)*(e_gamma/gamma+gamma_path*kappa)，T_squared仅用后项 | value=78344.7; relative_effect=4.21968e-05; 全输入: B3-run-011-K_coarse.inputs | 3.3059 | 23698.5 | h-cert-v1/output/run-011/science/result.json/tests[-1] |
| B / B-tail-penalty-lower-8 | lower M=8 x²/t数值 | 2.20529e-09 | gamma_1000*x^2/t | value=2.20529e-09; 全输入: B-tail-penalty-lower-8.inputs | 2.44836e-22 | 9.0072e+12 | h-cert-v1/output/run-009/science/result.json/tests/tail |
| B / B-tail-penalty-lower-10 | lower M=10 x²/t数值 | 2.74311e-12 | gamma_1000*x^2/t | value=2.74311e-12; 全输入: B-tail-penalty-lower-10.inputs | 3.04546e-25 | 9.0072e+12 | h-cert-v1/output/run-009/science/result.json/tests/tail |
| B / B-tail-penalty-upper-8 | upper M=8 x²/t数值 | 1.00115e-08 | gamma_1000*x^2/t | value=1.00115e-08; 全输入: B-tail-penalty-upper-8.inputs | 1.1115e-21 | 9.0072e+12 | h-cert-v1/output/run-010/science/result.json/tests/tail |
| B / B-tail-penalty-upper-10 | upper M=10 x²/t数值 | 1.2406e-11 | gamma_1000*x^2/t | value=1.2406e-11; 全输入: B-tail-penalty-upper-10.inputs | 1.37734e-24 | 9.0072e+12 | h-cert-v1/output/run-010/science/result.json/tests/tail |
| C / C-left-contraction | left P^128收缩 | 1 | gamma_(8*192*128)*192*max(1,norm2(P))^128 | dimension=192; power_norm=5.95163e-24; Pnorm2=0.762907; 全输入: C-left-contraction.inputs | 4.19095e-09 | 2.38609e+08 | h-dtn-v1/left-certificate.json/series |
| C / C-left-geometry | left 全域几何单射 | 0.889382 | gamma_1000*0.5/sqrt(detmin) | max_eta=0.110618; max_physical_eta=0.109704; min_det=7.93996e-06; curved_collar_clearance=0.124864; 全输入: C-left-geometry.inputs | 1.97002e-11 | 4.51458e+10 | h-dtn-v1/left-certificate.json/geometry |
| C / C-left-raw-Lambda | left原坐标最小特征值 | 0.411019 | qmax*eLambda_scaled | qmax=101.036; 全输入: C-left-raw-Lambda.inputs | 1.99002e-05 | 20654 | h-dtn-v1/output/run-006/science/result.json |
| C / C-right-contraction | right P^128收缩 | 1 | gamma_(8*192*128)*192*max(1,norm2(P))^128 | dimension=192; power_norm=6.48635e-16; Pnorm2=0.860228; 全输入: C-right-contraction.inputs | 4.19095e-09 | 2.38609e+08 | h-dtn-v1/right-certificate.json/series |
| C / C-right-geometry | right 全域几何单射 | 0.858752 | gamma_1000*0.5/sqrt(detmin) | max_eta=0.141248; max_physical_eta=0.134753; min_det=7.73167e-06; curved_collar_clearance=0.185511; 全输入: C-right-geometry.inputs | 1.99638e-11 | 4.30154e+10 | h-dtn-v1/right-certificate.json/geometry |
| C / C-right-raw-Lambda | right原坐标最小特征值 | 0.33789 | qmax*eLambda_scaled | qmax=101.036; 全输入: C-right-raw-Lambda.inputs | 2.04862e-05 | 16493.6 | h-dtn-v1/output/run-008/science/result.json |
| handoffs / handoff-Kplus-guard | Kplus相对公式值的上取余量 | 7.7968e-11 | 1e-11：包含lambda的ulp误差及除法；见标量分析 | stored=279.9; 全输入: handoff-Kplus-guard.inputs | 1e-11 | 7.7968 | h-dtn-v1/dtn_run.m:22 |
| handoffs / handoff-Kminus-guard | Kminus相对公式值的上取余量 | 1.2541e-05 | 1e-14：包含lambda和端点距离的ulp误差 | stored=0.70782; 全输入: handoff-Kminus-guard.inputs | 1e-14 | 1.2541e+09 | h-dtn-v1/dtn_run.m:22 |
| qj / qj-M-positive | M下端严格为正 | 4.72301 | 同M数值估计 | absolute_E_poly_moments=3.6148; absolute_C0_arcs=3.06288e-08; E=11.4709; M=4.72301; S=2.94758e-10; roundE=2.2742e-11; roundM=5.18729e-12; roundS=2.99254e-13; 全输入: qj-M-positive.inputs | 5.18729e-12 | 9.10497e+11 | qj-cert-v2/output/run-004/science/interface-certificate.json/M |
| qj / qj-I1-window | I1处于窗口内部 | 0.686279 | max(eI1L,eI1U) | 全输入: qj-I1-window.inputs | 2.54684e-08 | 2.69463e+07 | qj-cert-v2/output/run-004/analysis.json; draft/fem-goerisch/paper.tex:300 |
| handoffs / handoff-display-L | L简写十进制显示 | 4.46233e-09 | abs(displayed_endpoint-high_precision_endpoint) | display=2.42873; 全输入: handoff-display-L.inputs | 8.59828e-15 | 518980 | qj-cert-v2/output/run-004/analysis.json/scalar_decimal |
| handoffs / handoff-display-U | U简写十进制显示 | 4.46233e-09 | abs(displayed_endpoint-high_precision_endpoint) | display=2.42873; 全输入: handoff-display-U.inputs | 2.3042e-14 | 193660 | qj-cert-v2/output/run-004/analysis.json/scalar_decimal |
| handoffs / handoff-Kplus | Kplus full-precision交接 | 279.9 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=279.9; 全输入: handoff-Kplus.inputs | 1e-11 | 2.799e+13 | h-dtn-v1/dtn_run.m:22 |
| handoffs / handoff-Kminus | Kminus full-precision交接 | 0.70782 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=0.70782; 全输入: handoff-Kminus.inputs | 1e-15 | 7.0782e+14 | h-dtn-v1/dtn_run.m:22 |
| handoffs / handoff-a_minus | a_minus full-precision交接 | 1.7424 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=1.7424; 全输入: handoff-a_minus.inputs | 3e-16 | 5.808e+15 | qj/qj_run.m:9 |
| handoffs / handoff-a_plus | a_plus full-precision交接 | 5.6169 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=5.6169; 全输入: handoff-a_plus.inputs | 1e-15 | 5.6169e+15 | qj/qj_run.m:9 |
| handoffs / handoff-beta0 | beta0 full-precision交接 | 0.5 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=0.5; 全输入: handoff-beta0.inputs | 0 | ∞ | core/rounding_scalars.m:5 |
| handoffs / handoff-pi | pi full-precision交接 | 3.14159 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=3.14159; 全输入: handoff-pi.inputs | 2e-16 | 1.5708e+16 | core/rounding_scalars.m:5 |
| handoffs / handoff-C_h | C_h full-precision交接 | 0.00994657 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=0.00994657; 全输入: handoff-C_h.inputs | 1.10429e-16 | 9.0072e+13 | output/run-007/science/result.json/C_h |
| handoffs / handoff-epsilon_D | epsilon_D full-precision交接 | 2.06203e-09 | 显式标量误差估计；I/O保持原double，函数/常量误差另列 | value=2.06203e-09; 全输入: handoff-epsilon_D.inputs | 2.28932e-21 | 9.0072e+11 | output/run-007/science/result.json/epsilon |
| handoffs / handoff-left-Q_minus | left Q_minus最后加减 | 2.87586e-14 | u*(max(abs(diag(parent)))+epsilon) | parent_maxdiag=101.003; epsilon=2.87586e-14; observed=3.36895e-16; 全输入: handoff-left-Q_minus.inputs | 1.12136e-14 | 2.56462 | h-dtn-v1/left-certificate.json; output/handoff-checks.json |
| handoffs / handoff-left-R_plus | left R_plus最后加减 | 1.58634e-14 | u*(max(abs(diag(parent)))+epsilon) | parent_maxdiag=1.24386e-06; epsilon=1.58634e-14; observed=1.01654e-22; 全输入: handoff-left-R_plus.inputs | 1.38097e-22 | 1.14872e+08 | h-dtn-v1/left-certificate.json; output/handoff-checks.json |
| handoffs / handoff-left-Z_plus | left Z_plus最后加减 | 1.58109e-12 | u*(max(abs(diag(parent)))+epsilon) | parent_maxdiag=0.729868; epsilon=1.58109e-12; observed=2.26519e-17; 全输入: handoff-left-Z_plus.inputs | 8.10316e-17 | 19512 | h-dtn-v1/left-certificate.json; output/handoff-checks.json |
| handoffs / handoff-right-Q_minus | right Q_minus最后加减 | 3.93014e-14 | u*(max(abs(diag(parent)))+epsilon) | parent_maxdiag=101.003; epsilon=3.93014e-14; observed=3.3312e-15; 全输入: handoff-right-Q_minus.inputs | 1.12136e-14 | 3.50479 | h-dtn-v1/right-certificate.json; output/handoff-checks.json |
| handoffs / handoff-right-R_plus | right R_plus最后加减 | 2.1354e-14 | u*(max(abs(diag(parent)))+epsilon) | parent_maxdiag=1.24386e-06; epsilon=2.1354e-14; observed=6.93764e-24; 全输入: handoff-right-R_plus.inputs | 1.38097e-22 | 1.54631e+08 | h-dtn-v1/right-certificate.json; output/handoff-checks.json |
| handoffs / handoff-right-Z_plus | right Z_plus最后加减 | 2.20932e-12 | u*(max(abs(diag(parent)))+epsilon) | parent_maxdiag=1.11009; epsilon=2.20932e-12; observed=2.76944e-17; 全输入: handoff-right-Z_plus.inputs | 1.23245e-16 | 17926.2 | h-dtn-v1/right-certificate.json; output/handoff-checks.json |
| handoffs / Gauss-10 | Gauss10 节点/权重工作模型 | 1 | max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对 | order=10; max_root_residual=1.57925e-151; max_comparator_radius=1.1975e-151; max_node_absolute_error=1.54857e-16; max_weight_absolute_error=3.89782e-16; max_weight_relative_error=3.55825e-15; max_polynomial_moment_error_through_degree_16=1.88441e-16; minimum_one_minus_node=0.0130467; 全输入: Gauss-10.inputs | 1.11022e-12 | 9.0072e+11 | output/gauss-checks.json/order=10 |
| handoffs / Gauss-16 | Gauss16 节点/权重工作模型 | 1 | max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对 | order=16; max_root_residual=4.8281e-149; max_comparator_radius=2.39011e-149; max_node_absolute_error=2.88618e-16; max_weight_absolute_error=5.10933e-16; max_weight_relative_error=1.73073e-14; max_polynomial_moment_error_through_degree_16=1.60635e-15; minimum_one_minus_node=0.00529953; 全输入: Gauss-16.inputs | 2.84217e-12 | 3.51844e+11 | output/gauss-checks.json/order=16 |
| handoffs / Gauss-24 | Gauss24 节点/权重工作模型 | 1 | max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对 | order=24; max_root_residual=3.48941e-146; max_comparator_radius=1.28098e-146; max_node_absolute_error=2.64434e-16; max_weight_absolute_error=3.29877e-16; max_weight_relative_error=5.17788e-14; max_polynomial_moment_error_through_degree_16=3.66088e-16; minimum_one_minus_node=0.00240639; 全输入: Gauss-24.inputs | 6.39488e-12 | 1.56375e+11 | output/gauss-checks.json/order=24 |
| handoffs / Gauss-40 | Gauss40 节点/权重工作模型 | 1 | max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对 | order=40; max_root_residual=3.09525e-140; max_comparator_radius=1.04188e-140; max_node_absolute_error=1.58063e-16; max_weight_absolute_error=6.36187e-16; max_weight_relative_error=1.21198e-13; max_polynomial_moment_error_through_degree_16=6.34041e-16; minimum_one_minus_node=0.000881145; 全输入: Gauss-40.inputs | 1.77636e-11 | 5.6295e+10 | output/gauss-checks.json/order=40 |
| handoffs / Gauss-77 | Gauss77 节点/权重工作模型 | 1 | max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对 | order=77; max_root_residual=2.96446e-126; max_comparator_radius=4.49566e-127; max_node_absolute_error=1.64144e-16; max_weight_absolute_error=4.55876e-16; max_weight_relative_error=3.15431e-13; max_polynomial_moment_error_through_degree_16=4.28649e-16; minimum_one_minus_node=0.000240693; 全输入: Gauss-77.inputs | 6.58251e-11 | 1.51918e+10 | output/gauss-checks.json/order=77 |
| handoffs / Gauss-104 | Gauss104 节点/权重工作模型 | 1 | max(10*n*u,100*n^2*u)，前者节点绝对、后者权重相对 | order=104; max_root_residual=5.53465e-116; max_comparator_radius=6.74644e-117; max_node_absolute_error=1.37026e-16; max_weight_absolute_error=3.21249e-16; max_weight_relative_error=4.07748e-13; max_polynomial_moment_error_through_degree_16=7.11941e-16; minimum_one_minus_node=0.000132389; 全输入: Gauss-104.inputs | 1.20082e-10 | 8.32766e+09 | output/gauss-checks.json/order=104 |


100项旧清单的逐项去向见 [inventory-map.csv](../../../test/numerical-directions/rounding-estimate-v1/output/inventory-map.csv)。其中根、线性方程求解、通量极小化、插值系数、近似特征向量都是自由试探数据的选择，不需要把“解的误差”再次当作残差误差。整数RT3参考迹恒等式、整数拓扑计数是结构项。BIE/Hankel只用于独立参考，不进入这条链；没有为它编造舍入预算。B2的整数相等只在两端Schur符号稳定时保持。PSD的零特征值也不作为严格正余量：G/R是精确模型中的Gram，原浮点中心的极小负值用扰动尺度解释，不裁剪后冒充新的输入。

## 区间端点

名义积分与总估计如下。E/M行同时列出原截断半宽，便于看到算术估计是否超过已有准确度。

| 量 | 名义值 | 原截断半宽或数值 | 纯评价舍入估计 | 对象备注加入量 | 采用总估计 |
|---|---|---|---|---|---|
| E | 11.4709 | 2.00018e-12 | 1.75645e-11 | 5.17754e-12 | 2.2742e-11 |
| M | 4.72301 | 6.90203e-12 | 5.17843e-12 | 8.85806e-15 | 5.18729e-12 |
| S+ | 2.94758e-10 | 2.94758e-10 | 2.99245e-13 | 8.47068e-18 | 2.99254e-13 |

E/M的主要求和是非负项；同一积分内的多项式、质量修正和残差形成过程不同。172756个单元实例按“256个Gauss点—每模板最多6410元—13胞—3模板”的层级计，工作路径长度6682。曲边E的系数绝对矩总和为3.61480；公共残差的多项式绝对矩诊断为2.15995e-7，包含同一上下文中少量taper辅助调用，按偏大的尺度使用。质量带积分的正负项绝对和2.12142e-6、净和3.01746e-8，抵消约70.3倍；C0弧积分的绝对和为3.06288e-8。C0中 $c-\Pi_2c$ 的消减用坐标尺度0.4另估，贡献2.2354e-13，超过其最后求和项的估计。

RT3基评价的绝对平方尺度实测为2.88412e9；这正是不能把小S本身乘 $\gamma_n$ 的原因。公共S采用该尺度和 $\gamma_{1000}+100e_x$。界面部分抽样每模板4弧，共12弧；相减前尺度358.694按320/4=80外推，再乘10的工作放大量。这个10没有统计置信度含义，也没有保证覆盖未抽样弧。界面误差估计7.03e-15；公共S估计约2.92e-13，占主要部分。若不接受这项抽样外推，需对全部界面弧累计同样的尺度统计，而不是提高求和精度。

实际Gauss规则以512位Legendre根及权重公式对照，2至104阶最终比较器半径都小于1e-80。16阶节点最大差2.88618e-16、权重最大相对差1.73073e-14；实际C规则16至77阶的相应最大量见 `gauss-checks.json`。下游对同一规则取实测差的2倍作工作输入；这是校准选择，未使用较大的通用后向模型项当作已达到的实际误差。包含Duffy因子 $(1-x)$ 的相对变化。E/M额外规则估计分别为2.12215e-12、8.91156e-13。节点的导数放大按E的20倍绝对多项式尺度、M的16倍尺度，以及残差的100倍基项尺度估计。B的Gauss40误差小于已采用的共同 $\gamma_{8n+Pq+8J}$ 尺度。

设 $q=1+E/M$、$d=qS/M-(q-s)^2/s^2$、$D=q-t-td$，$F_t=q-1+qtd/D$。本次用256位评价导数：
$$F_q=1-t^2\delta(1+\delta)/D^2,\qquad F_\delta=qt(q-t)/D^2.$$
再用 $q_E=1/M$、$q_M=-E/M^2$，
$$\delta_E=q_ES/M-2(q-s)q_E/s^2,\quad \delta_M=q_MS/M-qS/M^2-2(q-s)q_M/s^2,\quad \delta_S=q/M.$$
于是端点估计为 $|F_E|e_E+|F_M|e_M+|F_S|e_S$，并加 $\gamma_{100}|F|$ 的末次评价项。固定s是自由试探参数，不要求它等于精确q。窗口端点对F的影响约 $F_t'=q^2d/D^2$ 乘端点的ulp误差，量级低于1e-23。

| 端点 | 重新评价的名义中心 | 对E、M、S的导数 | 估计位移 | 占本区间宽度 | 名义活动角 |
|---|---|---|---|---|---|
| L | 2.4287286691977914 | 0.211729338511, -0.514233114553, -5.16606894931 | 9.05556e-12 | 0.202933% | [0, 1] |
| U | 2.4287286736601232 | 0.211729338258, -0.514233114883, 9.94594237606 | 1.0486e-11 | 0.234988% | [1, 0] |
| I1L | 2.4286785150756702 | 0.211724674727, -0.514216478136, -85078.7409991 | 2.54676e-08 | 0.0253884% | [0, 1] |
| I1U | 2.428778827107029 | 0.211733969427, -0.514249671941, 85081.2301278 | 2.54684e-08 | 0.0253892% | [1, 0] |

主区间若把两端估计方向都按外移相加，宽度改变量约1.95415e-11，即原宽度的0.4379%。这只是工作估计，不把两个新数当作包含区间。

I1采用 $q(1+\delta/2\pm\sqrt{\delta+\delta^2/4})-1$，对S的导数约 $\pm85080$，故绝对位移较大，但仍只占其自身宽度约0.0254%。同一批E/M/S的四角重新评价与给定I1简写的末位相差约2.3e-13、3.3e-13；当前没有独立I1 JSON可追溯这几位的生成方式，不将该差认作纯舍入观测。它比本次位移估计小约八万倍，且I1离窗口边界至少0.686。

## 数据可容许性

这里只作O(u)扰动备注，不建立几何、空间或谱的扰动定理。目标场可由共享主节点和整数RT3基定义；它的单项式缓存、几何节点和相位是近似评价。以下量是实际测量或明确的启发式效果估计。

| 项目 | 测量 | 采用的启发式效果或处理 |
|---|---|---|
| Bloch相位 | 4.29277e-17；模平方偏差 7.97046e-17 | 相位差除以sqrt(det_min)作局部梯度尺度；E影响 2.27268e-13 |
| 曲线节点公式 | 2.62709e-16, 3.66285e-16, 3.24277e-16 | 公式取值及物理胞平移的采样。 |
| 实际二次图的节点像 | 3.57846e-16, 5.75192e-16, 3.6249e-16 | 每模板640个界面顶点/中点，匹配全部相邻单元像；局部应变按max差/sqrt(det_min)，E影响 4.74575e-12 |
| P3节点→单项式 | V的∞条件数432；最大全节点重建差 4.11235e-16 | 全部172756个单元实例，192位有理V重算；质心几何估计梯度变化平方 9.11651e-28，E影响 2.04524e-13 |
| RT3参考基 | 参考系数为整数；普通边共享主矩 | 整数性保留参考法向迹；精确Bloch相位和Piola公共几何仍是对象定义的一部分。缓存求值抵消进入S估计。 |
| C右侧实际墙迹 | 重复胞 1.43309e-18；首/重复胞 4.88992e-17 | 对应场Frobenius范数9.67767 / 204.504；均小于本文场评价项。这个检查不是重复计算同一乘积得到0的旧wall_match。 |
| 精确端口修正 | 独立FE迹差约8.97e-16；保留Fourier差约7.44e-17 | 解析g与FE修正目标应使用同一表达式。误差纳入C的相减前尺度。 |
| D代表函数kappa | 绝对差最大 1.57797e-14；beta绝对差 1.07794e-14 | Riesz代表恒等式发生O(u)偏离；用解析Gram绝对包络的7.69e-9项计入其工作尺度。 |
| D中的H=I | 原浮点检查norm1(H-I)=5.04249e-14 | 直接作用尺度约7.74e-13，另加入解析H/M1/迹映射评价估计；没有将H-I当严格0。 |

上述曲线测量只比较插值节点；二次弧相对真弧的截断缺陷仍由原截断项处理，不能用节点误差代替整弧误差。节点转换比较不是只比较两个double求值：本次导出全部主节点和系数，在192位下以精确有理插值点重建差，再用质心Jacobian和精确参考多项式矩计算局部变化尺度。它衡量缓存评价误差；曲边全积分和连续空间修补没有在此重做。共享拓扑、非曲线中点、曲线材料标签等原构造继续作为同一对象的定义；不能把“浮点检查为0”解释为精确相位或精确真曲线。

标量和JSON交接使用完整double，只有报告显示采用`.12g`等简写。MAT-v7和JSON的读取保持原double，主要效应来自交接前运算。本次D的epsilon在MAT/JSON间逐位一致，C的Q、Lambda条目和r在两层JSON间逐位一致。最后一次减/加epsilon仍产生微小的双向舍入：Q_minus最大对角差3.33e-15，R_plus约1.02e-22，Z_plus约2.77e-17；“full precision”不等于定向舍入。$K_+=279.899894626$ 相对精确有理公式值的名义上取余量约7.80e-11，对本次1e-11工作估计的比值约7.8；$K_-=0.70782$ 有更大的余量。若后续希望减少这项敏感性，可以使用279.9并一致重算C中的Z；单看 $K r$，增加约4.10e-12，远低于C的间隙。这里没有改旧输入。

主区间简写端点向内约8.60e-15、2.30e-14，远小于本次端点位移估计。无论使用何种误差路线，正式显示都应交代打印精度；完整JSON中的数值与简写显示不是同一组十进制端点。

## 观测与估计的对比

| 比较 | 观测差 | 对应估计 | 估计/观测 | 核查 |
|---|---|---|---|---|
| A_fixed_matrix | 1.84773e-12 | 5.91057e-10 | 319.882 | 通过 |
| D_fixed_matrix | 5.66108e-16 | 1.28021e-11 | 22614.3 | 通过 |
| energy_terms | 9.04277e-13 | 2.20009e-10 | 243.299 | 通过 |
| mass_terms | 3.60932e-13 | 9.05863e-11 | 250.979 | 通过 |
| residual_terms | 3.99879e-24 | 5.65257e-21 | 1413.57 | 通过 |
| mass_correction_terms | 5.21076e-22 | 4.06883e-17 | 78085.1 | 通过 |
| Gauss16_node | 2.88618e-16 | 1.77636e-14 | 61.5471 | 通过 |
| Gauss16_weight_relative | 1.73073e-14 | 2.84217e-12 | 164.218 | 通过 |
| Gauss77_node | 1.64144e-16 | 8.54872e-14 | 520.807 | 通过 |
| Gauss77_weight_relative | 3.15431e-13 | 6.58251e-11 | 208.683 | 通过 |

A比较的是第68面板、a=0.20下端的**固定导出矩阵**，double值为-0.00013972238243961722，高精度逆迭代值为-0.00013972238428734948，192位残差约2.36e-45。这个比较只检验特征值计算项，未把矩阵装配也改成高精度。

E/M/S比较使用同一批已积分项。正序、逆序显式循环、升/降序NumPy和、math.fsum及192位和均保留。Python的内置sum可能含补偿，本次“顺序循环”明确使用逐项加法。观测只能检查固定项的累加；上游被积函数、几何、整数基内部抵消另按前文估计。

D的8a试点给的是固定矩阵的0.36536998下端数字；它距double第二值约3.71e-6，这个差是所选shift的松量，不能当舍入误差。本次另以192位Rayleigh值0.36537368878193222644对照double的0.36537368878193166；向量残差约2.19e-15，使用邻近间隔0.353346估计其Rayleigh向量效应约1.36e-29。它与8a数字相容。本次固定矩阵实部与8a导出逐位相同，虚部条目未超过原最大值；这只解释固定矩阵对照。

要求的复现：原SciPy A程序给1.397223838884971e-4，与参考的相对差2.25e-10；D给0.3653736908439648，相对差0。两者达到1e-9要求。MATLAB仅值eig和带向量eig分别偏离A参考约1.06e-8和5.01e-9，没有达到那一相对门槛，均保留；其绝对差在同一矩阵的求解器舍入估计内。没有通过改求积或移动参数让它贴合参考。

按同样的输入改变量重算全部角点，输入敏感度线性项与有限改变量的相对差：主区间小于3e-11，I1约2.54e-4。末次公式求值项另外相加；记录在 `finite-sensitivity.json`。

## 结论

全表最小比值为 **0.000130753**，对应D近贴边移位：第二方向约1.00e-10，估计效应约7.64799e-07。这个移位不足以支持其最后几位。改用0.36时，间隔0.00537369，比值7026.28；不必保留1.1e-10的LDL枢轴作为精度目标。

A/B/C/D所用有限矩阵的原点符号在这些工作估计下均有余量。E的舍入估计约为其原截断半宽的11.37倍，故E±的末位精度不能只用截断半宽描述；M的比值约1.33057。由端点敏感度得到的估计位移仍约为W的0.20%/0.235%。

若目标只是评估舍入敏感性，本次估计支持采用较宽D移位并保留主区间的数值尺度。若要求原来的十位D下端数字或要求去掉“舍入排除”，这些估计不够；特别是可容许性备注和界面抽样因子没有被改写成包含结论。

## 复现

从仓库目录执行；MATLAB入口全部经既有monitor.py，11线程、OMP_DYNAMIC=FALSE。下列运行编号是本次记录；重跑应使用新编号。

```sh
python3 test/numerical-directions/rounding-estimate-v1/launch.py band --output test/numerical-directions/rounding-estimate-v1/output/run-003
python3 test/numerical-directions/rounding-estimate-v1/launch.py core --output test/numerical-directions/rounding-estimate-v1/output/run-007
python3 test/numerical-directions/rounding-estimate-v1/launch.py qj-cert --output test/numerical-directions/rounding-estimate-v1/output/run-009
python3 test/numerical-directions/rounding-estimate-v1/launch.py field --output test/numerical-directions/rounding-estimate-v1/output/run-010
python3 test/numerical-directions/rounding-estimate-v1/launch.py dtn-left --output test/numerical-directions/rounding-estimate-v1/output/run-014
python3 test/numerical-directions/rounding-estimate-v1/launch.py dtn-right --output test/numerical-directions/rounding-estimate-v1/output/run-015
python3 test/numerical-directions/rounding-estimate-v1/launch.py gauss --output test/numerical-directions/rounding-estimate-v1/output/run-016
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/band_python_reference.py
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/high_precision_checks.py --root test/numerical-directions/rounding-estimate-v1 --output test/numerical-directions/rounding-estimate-v1/output/run-006/observations.json
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/handoff_checks.py
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/gauss_checks.py --experiment test/numerical-directions/rounding-estimate-v1
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/object_sizes.py --experiment test/numerical-directions/rounding-estimate-v1
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/B_scales.py
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/estimate_analysis.py --experiment test/numerical-directions/rounding-estimate-v1
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/finite_sensitivity.py
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/inventory_map.py
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/write_report.py
```

Gauss初版192位区间迭代出现包裹，已保留run-017记录及初版JSON；最终改为512位中值Newton，并检查最终残差与半径。

高精度比较还读取run-004的固定正项和run-002的D矩阵，分别可由`launch.py qj`、`launch.py core`重生；最终run-007矩阵的第二值复现一致。core输入为原左右DtN JSON；qj入口在进程内重生P3场和RT3通量，不依赖旧MAT。Python使用python-flint 0.9.0、numpy 2.5.4、scipy 1.18.1，只作估计与观测对照。

| 运行 | 结束状态 | 墙时/秒 | 峰值/GiB |
|---|---|---|---|
| run-001 | completed | 22.274 | 0.680679 |
| run-002 | completed | 15.4662 | 0.883514 |
| run-003 | completed | 17.5951 | 0.683319 |
| run-004 | completed | 165.281 | 1.79672 |
| run-005 | completed | 402.516 | 1.82864 |
| run-007 | completed | 19.8742 | 0.912323 |
| run-008 | completed | 412.021 | 1.7791 |
| run-009 | completed | 202.245 | 2.38995 |
| run-010 | completed | 57.2776 | 1.72751 |
| run-014 | completed | 626.228 | 1.96344 |
| run-015 | completed | 530.634 | 1.90659 |
| run-016 | completed | 12.1383 | 0.773361 |

MATLAB全部运行合计2483.55秒，最高峰值2.38995 GiB。节点转换的高精度全数据诊断3.61197秒；固定矩阵/求和对照2.28702秒；B矩尺度1.2254秒。

## 未决问题

- 500/1000/10000路径常数、1 ulp库模型及界面12弧外推是工作选择；只要把它们当作未经核验的可靠常数，就超出了本阶段结论。B的XDC缓存采用原粗尺度，估计可能明显偏大；若需要缩小，应导出逐系数绝对和。可按需重做全弧尺度统计或更细的逐核误差分析。
- 质心Jacobian用于节点转换后的能量变化估计；几何/相位的H1与H(div)修补只作局部尺度解释，未建立无限条带上的扰动定理。
- A的不同eig驱动不满足同一1e-9相对复现门槛；已有高精度固定矩阵对照说明差值属于求解器尺度。以后比较这类小余量，应同时给绝对误差和矩阵范数。
- I1未保留独立全精度生成记录，给定参考末位与本次统一四角计算有约3e-13差异。该差不影响窗口包含的数值估计，但生成方式仍需经理核对。
- 本阶段没有改变区间或(H)的数学状态，也没有把新的工作数值写回旧实验输入。
