# 几何与二进制参数的可靠模型桥接

2026-10-30；模式 `Proof from scratch`。本文件接 [[research/explorations/spectral-counting/s-half-gap|HD1–HD2]] 和 [[research/explorations/spectral-counting/s-box-count|BC1–BC3]]，评价唯一账目 M1。目标是清楚区分精确解析模型、源代码二进制字面量的解析解释，以及实际求解器产生的离散场／网格。

## 1. 原目标与两种解析解释

已逐行核对 `test/i10/refine-v1/refine_i102_config.m` 的模型字段和 `refine_i102.m` 的 `LOCAL_curve`：$\beta=0.5$、$d=L=1$、中心不缩放、密度1/4/17、左右 $a=0.12,0.20$、基础半径0.2；中心使用 $0.2(1.5+0.3\cos5t)\cos t$ 与 $0.2(1+0.3\cos5t)\sin t$。没有改变研究模型的结构或参数意图。

- **有理解析模型**：有限十进制按精确有理数解释，是前面证书已认证的对象。
- **字面量二进制解析模型**：将源中每个浮点字面量替换为其确切 binary64 值，再在实数中解释上述解析公式，包括正规化根号。本轮用整数比记录这些值，直接包围它与有理解析模型的差异；不先把差异转为普通小数再当作界。
- **逐位求值／离散几何**：MATLAB 中间运算、三角函数求值、界面节点、曲边网格及旧恢复场。没有运行 MATLAB 就不声称逐位重放其整个轨迹；一组求值点或网格不是自动同一个解析算子。对它们的误差资格仍须单独检查。

$0.5$、1、1.5、整数密度与整数胞元平移可二进制精确表示；0.12、0.20、0.2、0.3、2.40、2.46 不能。后续证书还把两个端点各扩成半径 $10^{-12}$ 的实区间，以同时包含精确有理和源码二进制端点。

MATLAB 默认数值类型及 IEEE 754 双精度约定见 [MathWorks double 官方说明](https://www.mathworks.com/help/matlab/ref/double.html)，访问2026-10-30。本轮另外用相邻 binary64 数的精确有理中点核查所保存字面量，没有仅凭显示小数认定其值。

## 2. 从几何对称差到有限矩阵族

每个 inclusion 仍包含在其胞元内部，密度值固定，左右模板周期重复。允许新域 $\widetilde D_j$ 不具有 $y$ 反射对称性，但要求

$$
|\widetilde D_j\triangle D_j|\le\varepsilon_G. \tag{M1}
$$

对长度 $W$ 的有限箱基，$|\phi_i|\le c_i/\sqrt W$，其中余弦零阶 $c_i=1$、其余余弦或正弦基 $c_i=\sqrt2$。于是对 $s=1,2$，

$$
|\widetilde R_{s,ij}-R_{s,ij}|
\le\frac{c_ic_j}{W}\sum_j(\rho_j^s-1)\varepsilon_G,
\qquad R_s=P\rho^sP. \tag{M2}
$$

**Proof.** 积分之差支撑于各 inclusion 的对称差，且被积函数模不超过 $c_ic_j/W$；相乘的密度跃变量为 $\rho_j^s-1$。对各胞求和即得。无需边界光滑或几何对称性。证毕。

实现把 (M2) 同时加到每个条目的实、虚半径，因而允许真实矩为复 Hermitian；不能仅给 nominal 实矩阵加实误差后抹掉非对称扰动。由同一个真实密度定义的 $\widetilde R_2-\widetilde R_1^2=P\widetilde\rho Q\widetilde\rho P$ 仍半正定，故 B5 的协方差尾界原样成立。区间乘法包含它们的实际相关值；不假定区间矩阵的每个独立组合都对应一个材料。

单胞 Neumann 块用 $W=1$、单个密度跃变16。HD1 的 Dirichlet 试探函数满足 $|v|^2\le2$，故试探质量分母的额外误差不超过 $32\varepsilon_G$。尾动能和 $\rho_{\min}=1,\rho_{\max}=17$ 不变。如果扰动后的矩阵球仍通过相同严格符号，HD1、BC1–BC3 对整个材料族同时成立，而非仅对采样参数成立。

## 3. 字面量几何的可计算面积界

三类曲线都表示为 $x(t)=\sum a_k\cos kt$、$y(t)=\sum b_k\sin kt$。两套系数的差给出

$$
d_0=\sum_k(|\widetilde a_k-a_k|+|\widetilde b_k-b_k|),\quad
d_1=\sum_k k(|\widetilde a_k-a_k|+|\widetilde b_k-b_k|),\quad
V=\sum_k k(|a_k|+|b_k|),\quad R=\sum_k(|a_k|+|b_k|).
$$

沿曲线直线同伦 $\gamma_s=\gamma+s(\widetilde\gamma-\gamma)$，有 $|\partial_s\gamma_s|\le d_0$、$|\partial_t\gamma_s|\le V+d_1$。若参考曲线 $\det(\gamma,\gamma')\ge m>0$，且

$$
m-d_0V-Rd_1-d_0d_1>0, \tag{M3}
$$

则同伦中的每条曲线保持绕原点正向的简单星形边界。成员关系改变的点必须位于该同伦扫过的像中；对光滑二维参数映射应用含重数的面积公式，得到

$$
|\widetilde D\triangle D|\le
\int_0^1\!\int_0^{2\pi}|\det(\partial_s\gamma_s,\partial_t\gamma_s)|\,\mathrm dt\,\mathrm ds
\le 2\pi d_0(V+d_1). \tag{M4}
$$

曲线位于胞元内部另由 $\sum|\widetilde a_k|<1/2$、$\sum|\widetilde b_k|<1/2$ 验证。中心可用 B6 已证明的 $m=93/5000$；lead 可用 $m=[r_0(1-\alpha)]^2$。原点不在曲线上、绕数为1及行列式正性使角度严格单调，故这里没有假定未知的无自交性质。

二进制字面量由其确切整数比送入 Arb。center 系数为 $a_1=(3/2)r_b$、$b_1=r_b$、$a_4=a_6=b_6=-b_4=r_b c_b/2$，其中 $r_b=\operatorname{binary64}(0.2)$、$c_b=\operatorname{binary64}(0.3)$。lead 取 $u_b=r_b/\sqrt{1+\alpha_b^2/2}$，$a_1=b_1=u_b$、$a_2=a_4=b_4=-b_2=u_b\alpha_b/2$。所有差、(M3)与(M4)均可靠评价。

另评价每个展开系数在二进制字面量解析值周围独立变化 $10^{-13}$ 的明确邻域。它是一个已定义的鲁棒范围，不等于宣称已观测到旧 MATLAB 的全部中间值；某个实际冻结系数落入该邻域后才有直接覆盖资格。

## 4. 执行合同与证明报告

执行前合同选 $\varepsilon_G=10^{-10}$，端点半径 $10^{-12}$。从数学常量重新生成 G2 和有限箱所需材料矩，不读取旧实验 JSON，验证 (M1)–(M4)及全部严格惯性；若球半径过宽而失败则如实报告，不调整旧证书。理论依据是已验收 HD1/BC3 加本文件的显式几何与质量扰动界。

预算：`test/spectral-counting/bridge-v1/`、同一 `attempt-1`，串行、最多231维、192 bit；预计少于2分钟、0.5GB，输出5MB以内；30分钟／09:10 UTC较早者硬停，1GB进程峰值和900MB仓库预停。依赖已有本地环境，无MATLAB、无`.mat`。原证书文件与源码保持不变。

实际输出 `test/spectral-counting/bridge-v1/attempt-1/robust-01.json` 已通过全部判据。三种字面量解析曲线的对称差面积上界均小于 $2.072\times10^{-16}$；额外系数邻域的最大面积上界小于 $4.148\times10^{-12}$。两个单胞判据及8个有限箱矩阵全部通过，D/N 两端均为 $6\to7$，最小严格合同余量约0.00581657；因此完整证明链对 (M1) 材料族和两个端点带均成立。`rational-01.json` 另以标准库有理数核对字面量、系数公式、标量界及1870个严格定号枢轴。完整命令、结果范围和资源见 [[test/spectral-counting/bridge-v1/README]]。

**Completion report.** Mode: `Proof from scratch`。Target: 本文件 M1–M4 及矩阵族的自足推导；未修改旧证明。专门数学引用：无；面积公式是标准光滑变换的含重数面积界，应用所需参数、导数界、边界绕向与简单性均已列明。实例可靠执行、有理数审计及 [[research/planning/review-3h-20261030|独立审查§14]] 均通过；复核另以整数平方根和 $\pi<22/7$ 独立验证几何界。该结果闭合有理参数与源码字面量的解析模型衔接，不把旧离散场误差资格视为已解决。
