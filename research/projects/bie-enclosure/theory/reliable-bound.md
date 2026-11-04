# BIE 导模谱距离界的可靠化

> 来源：ChatGPT Pro 输出的报告（2026-11-04），原文照录，未改动。提问提示词附在文末"附录：提问提示词"。经理已核对的部分和未核对的部分见 [[research/projects/bie-enclosure/STATUS|STATUS]]；证明审查见 [[research/projects/bie-enclosure/theory/reliable-bound-review|reliable-bound-review]]（待完成）。本文中的"已证明"是报告作者的标注，不是本项目的结论。

## 结论与证明状态

日期：2026 年 11 月 4 日。核对对象为附件 `main.pdf`，尤其第 5 节（PDF 第 13–23 页），以及项目附件 `Fliss2013.pdf`。本文是证明与实施条件报告，不是已经运行完成的数值证书。

**现有谱距离定理可以继续作为主定理。需要改变的是它所作用的场、界面集合和输入量的认证方式。** 推荐固定实际 MFS 有限表示作为数学场，把上下准周期失配计入界面跳跃；用可靠的内外层求积、传播尾界和局部质量下界评价这个场。不同左右引线不会破坏预解式谱距离论证；它只影响“附近谱点属于离散导模”的带隙解释。

本报告给出以下结果：

| 任务 | 状态 | 主要结论 |
|---|---|---|
| T1 | 已证明 | 两条不同周期引线的本质谱为两全周期谱之并；公共间隙中只有孤立有限重谱；给出指数衰减证明和全 Bloch 参数带隙证书 |
| T2(a) | 已证明，在代理源位于闭胞元之外等列出条件下 | 连续光滑密度的层势、有限修正和逐胞元尾场满足逐片边界 $H^2$ 正则性 |
| T2(b) | 已证明 | 加入带相位的水平接缝，原谱距离公式保持；给出新的人工墙 Fourier 尾界及直接求积方案 |
| T3 | 各显式误差不等式已证明，数值使用以解析域及包络证书为条件 | 给出外层梯形混叠、Kress 乘积积分、墙和接缝 Taylor 面板、传播尾、特殊函数接口、背景圆盘质量下界 |
| T4 | 已证明；代入题中几何数字的结果仅为条件性估计 | 同半宽领子下可把 $C$ 从约 $9.58$ 降至约 $4.70$；墙和接缝单独用宽领子时约为 $1.04$ |
| T5 | 给出有证明支撑的评价加速方案；总时间未验证 | 共享参考胞元评价、流式多右端、Lyapunov 尾界、分组误差预算与少量圆盘点评价 |
| 实际全宽 $\le5\times10^{-9}$、时间 $\le40$ 分钟、内存 $\le3$ GiB | **未证明，也未完成数值验证** | 缺少曲线 Fourier 系数、密度、MFS 修正系数、传播矩阵、现有 FMM 算法细节和带隙证书；这些不能由题中几个汇总数反推出 |

“已证明”修饰本文的不等式和数学结论，不表示对应的实现常数已经算出。一般的解析性、网格加密后的接近程度、库的名义容差，均不能代替可靠上界。

### 目标的实际误差预算

按题目给定十进制 $\widehat k$ 取平方，有

$$\mu=2.42872867002270995345828629586281.$$

旧数据对应

$$Q_{\rm old}=9.578\,(2.05\times10^{-12})=1.96349\times10^{-11},$$

$$R_{\rm old}\approx7.72899\times10^{-10},\qquad 2R_{\rm old}\approx1.54580\times10^{-9}.$$

给定可靠质量下界 $U_->0$，要求全宽不超过 $5\times10^{-9}$ 的准确门槛是

$$\boxed{\overline Q\le
\frac{(2.5\times10^{-9})U_-}{2\mu+2.5\times10^{-9}}.}\tag{B0}$$

如果能可靠保住 $U_-=0.1234$，允许 $\overline Q\le6.35106\times10^{-11}$，约为旧估计的 $3.2346$ 倍；保留 $C=9.578$ 时相当于 $\overline\varepsilon\le6.63088\times10^{-12}$。但 $0.1234$ 目前只是估计。若一个背景圆盘只能证明 $U_-=0.06$，允许的 $Q$ 也必须按 $0.06/0.1234$ 缩减。不能只讨论 $C\varepsilon$ 的三倍余量而忽略质量下界损失。

T4 的较小迹常数可增加预算，但**接缝缺陷、内层求积、外层求积、FMM 截断与传播尾均须从同一份预算中支付**。

## 草稿必须先修改的地方

1. **不同引线。** 第 2 节把单一 $\rho_p,A_p$ 改为 $\rho_\pm,A_\pm$，本质谱改成两者谱的并。第 3.1 小节“左右介质柱是同一个柱的平移”、各胞元长度和 (5.4) 中的平移距离也应改为各侧自己的几何与 $L_\pm$。T1 给出全部证明。Fliss 的不同引线推广见 Remark 2.1(2)，并非未知猜想。
2. **(P2) 与 (5.23)。** 对实际 augmented MFS 场，删除“精确准周期”的断言，把水平接缝纳入 $\mathscr E$。原人工尾项 (5.23) 使用精确准周期 Green 函数的 Rayleigh 结构，对新定义场不能原样使用。T2.4 给出合法替代；优先直接积分墙段。
3. **领子覆盖重数。** 第 17 页“$\delta_{\rm col}$ 小于材料界面到胞元墙的距离即有 $N_{\rm ov}=1$”不足：两个领子各有半宽，必须检查距离大于半宽之和，并检查其他界面及周期副本。新接缝也会与竖墙领子相交。此处需修正几何证书，不推翻以真实覆盖重数为假设的命题 5.1。
4. **第 2 节式 (2.10) 的谱底端点。** 固定非零 $\beta$ 时，$b_\beta=\min_m|\beta+2\pi m/d|>0$，且 $A(\beta)\ge b_\beta^2/\rho_{\max}>0$。写成 $[0,\infty)\setminus\bigcup(a_n,b_n)$、$a_n\ge0$ 会错误地保留 $0$；本例下界为 $0.25/17=1/68$。直接使用能带并公式，或从实际谱底开始扣除内部开隙，即可修正。这不影响第 5 节的谱距离论证。
5. **第 5.1 小节关于离散点源的文字。** 二维单层点源的对数奇性仍局部平方可积，因为 $\int_0^a r|\log r|^2dr<\infty$；点偶极的 $1/r$ 奇性一般不平方可积。因此不宜笼统说所有离散层势都不属于 $L^2$。它们一般不满足直至源所在边界的 $H^2$，这是继续使用连续密度定义场的充分理由；不影响该定义和后续定理。

在原有精确准周期假设和正确的几何假设下，**没有发现命题 5.1、定理 5.2 的证明错误**。特别是全局 $H^2$、Hessian 的 Frobenius 范数恒等式、两类跳跃的不同号约定、紧支撑截断及 $\delta/2$ 的一维迹系数均成立。以下不重写这一已证部分，只证明所需扩展和更紧的常数。

## 全文记号与可靠性的约定

$\mathcal H=L^2(B,\rho)$，$A=A(\beta)=-\rho^{-1}\Delta$，$\mu=\widehat k^2$，$U=\|\widehat u\|_{\mathcal H}$。内积对第二变量取共轭。$J_D$ 或 $J_{\Gamma,0}$ 表示草稿 $\llbracket\widehat u\rrbracket_\Gamma$；$J_N$ 或 $J_{\Gamma,1}$ 表示 $\llbracket\partial_\nu\widehat u\rrbracket_\Gamma$。$\mathsf P_\pm$ 就是草稿的 $P_\pm$。所有曲线参数保持草稿 $t\in[0,1)$ 的周期约定；圆周角参数另写 $\theta\in[0,2\pi)$。

- **可靠上界/下界：** 由明确不等式和经验证的常数得到，具有所声称的数学保证。
- **条件性证明：** 定理已证明，但仍需核验列出的解析域、分离、矩阵范数等条件；未核验前不输出实际数值证书。
- **截断误差意义下可靠：** 对指定的精确算术算法，所有截断、求积和近似核/展开误差均已控制；浮点实现的舍入另列估计。这不等于包含舍入的严格区间。
- **估计：** 网格实验、未经证明的 FMM 容差、浮点几何极值及本文据题中汇总数作的性能或宽度推算。

允许舍入只作估计，**不等于允许遗漏 FMM 展开截断、特殊函数近似算法的截断或接缝残差**。若低成本地对少数 Taylor 中心、几何证书、传播小矩阵及质量点使用球算术，就可把其中大部分舍入也顺便包括进来。



## T1 不同左右引线的本质谱、公共谱隙与指数衰减

### 文献核验与草稿应改之处

已亲自核对附件 `Fliss2013.pdf`，其文件为 Sonia Fliss, *A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides*, arXiv:1202.4928v2（2013-01-30）；正式版为 *SIAM Journal on Scientific Computing* **35**(2), B438–B461 (2013), DOI [10.1137/12086697X](https://doi.org/10.1137/12086697X)。以下编号按已读的附件预印本。

- Remark 2.1(2)，PDF 第 4 页，明确允许左右使用不同的 $\rho_p^-$、$\rho_p^+$，并明确允许 $L_x^-\ne L_x^+$，只要求相同的 $y$ 周期。
- Proposition 3.1，PDF 第 7 页，**显示写出的命题及证明仍是同一个背景 $\rho_p$**，结论为 $\sigma_{\rm ess}(A)=\sigma(A_p)$；不能把这个显示公式原封不动地用于当前不同引线的算例。
- Proposition 3.3，PDF 第 8 页，给出间隙内孤立有限重特征值；Theorem 3.5，PDF 第 9 页，给出指数衰减。这些是在该文的同背景记号下写出的。

因此，准确的修订方式是“Fliss 的 Remark 2.1(2) 已指出此推广；以下命题给出本算例所用的两引线形式及证明”，而不是称为尚未证明的猜想，也不是声称 Proposition 3.1 的显示结论已直接等于两谱之并。以下证明不依赖未核对的文献定理。

### 定理 T1.1（两引线本质谱）

**状态：已证明。** 固定 $d>0$、$\beta\in\mathbb R$，令 $B=\mathbb R\times(-d/2,d/2)$。设 $\rho,\rho_\pm$ 为实值可测函数，存在共同常数

$$0<\rho_{\min}\le\rho,\rho_\pm\le\rho_{\max}<\infty.$$

假定它们关于 $y$ 均以 $d$ 为周期；$\rho_s$ 关于 $x$ 以 $L_s>0$ 为周期，$s\in\{-,+\}$；对一些有限的 $x_-<x_+$，有

$$\rho(x,y)=\rho_-(x,y)\quad(x<x_-),\qquad
  \rho(x,y)=\rho_+(x,y)\quad(x>x_+).$$

中心区内只需上述有界性，不要求光滑、分片常数或额外周期性。设 $\mathcal H=L^2(B,\rho)$，$\mathcal H_s=L^2(B,\rho_s)$。在这几个空间中分别由同一闭二次型

$$a[u,v]=\int_B\nabla u\cdot\overline{\nabla v},\qquad
D(a)=H^1_\beta(B)$$

定义 $A(\beta)$、$A_s(\beta)$，其中 $H^1_\beta(B)$ 的上下值迹满足相位 $e^{i\beta d}$。它们自伴非负，且

$$D(A)=D(A_s)=H^2_\beta(B),\qquad
A=-\rho^{-1}\Delta,\quad A_s=-\rho_s^{-1}\Delta,$$

这里 $H^2_\beta(B)$ 同时要求值与 $\partial_y$ 迹准周期。则

$$\boxed{\sigma_{\rm ess}(A(\beta))=
\sigma(A_-(\beta))\cup\sigma(A_+(\beta)).} \tag{T1.1}$$

**证明。** 型闭性和非负性来自 $\rho$ 的上下界及 $H^1$ 的完备性，表示定理给出自伴算子。弱算子方程意味着 $-\Delta u=\rho Au\in L^2$。在准周期圆柱上作 $x$ 的 Fourier 变换与 $y$ 的准周期 Fourier 级数，可得 $u\in H^2_\beta(B)$；反向包含由分部积分成立。这也给出图范数与 $H^2$ 范数的等价性。材料系数出现在零阶的质量项中，其跳跃不会破坏这个全局 $H^2$ 结论。

先证 $\sigma_{\rm ess}(A)\subset\sigma(A_-)\cup\sigma(A_+)$。取实数 $\lambda$ 不在右端并集内，记 $R_s=(A_s-\lambda)^{-1}$，$R_0=(A+1)^{-1}$。选取实光滑函数 $\chi_0,\chi_-,\chi_+$，仅依赖 $x$，满足

$$\chi_0^2+\chi_-^2+\chi_+^2=1,$$

$\chi_0$ 紧支撑，$\chi_-$ 及其非零导数全部位于 $x<x_-$，$\chi_+$ 及其非零导数全部位于 $x>x_+$，而 $\chi_s=1$ 于相应的充分远尾部。不同加权 $L^2$ 范数等价，故

$$Q=\chi_-R_-\chi_-+\chi_+R_+\chi_++\chi_0R_0\chi_0:
\mathcal H\longrightarrow D(A)$$

有界。直接计算得到

$$(A-\lambda)Q=I+K,$$

其中 $K$ 是以下算子的有限和：

$$[A,\chi_s]R_s\chi_s,
\qquad [A,\chi_0]R_0\chi_0,
\qquad -(\lambda+1)\chi_0R_0\chi_0.$$

交换子为

$$[A,\chi]v=-\rho^{-1}(2\chi'\partial_xv+\chi''v).$$

每项均经由一个有界 $x$ 窗口上的 $H^2\hookrightarrow H^1\hookrightarrow L^2$ 紧嵌入，故 $K$ 紧。右参数子意味着 $A-\lambda$ 的值域闭且余维有限；自伴性进一步给出核有限维，故 $A-\lambda$ 为 Fredholm 算子。于是 $\lambda\notin\sigma_{\rm ess}(A)$。此处没有把两个不同 Hilbert 空间中的算子直接作未经定义的酉比较。

再证反向包含。对一条全周期引线作 $x$ 方向 Floquet 变换，得到矩形胞元 $C_s=(0,L_s)\times(-d/2,d/2)$ 上的直积分。纤维 $A_s(\beta,\theta)$ 的值与法向导数在 $x$ 两端满足相位 $e^{i\theta L_s}$，$\theta\in[-\pi/L_s,\pi/L_s]$；$y$ 方向仍为 $\beta$ 准周期。纤维自伴并有紧预解式，记递增特征值为 $\lambda_{s,n}(\theta)$。通过周期规范变换，其型域固定，且下面式 (T1.6) 的最小最大论证给出 $\sqrt{\lambda_{s,n}}$ 的连续性。与矩形 Laplacian 比较还给出 $\inf_\theta\lambda_{s,n}(\theta)\to\infty$。因此能带并在有界能量范围内局部有限且闭，直积分谱为

$$\sigma(A_s)=\bigcup_{n\ge1}\bigcup_{\theta\in[-\pi/L_s,\pi/L_s]}
\{\lambda_{s,n}(\theta)\}. \tag{T1.2}$$

取 $\lambda=\lambda_{s,n}(\theta)$ 及对应的非零 Bloch 场 $w$。它的 $H^2$ 范数、$L^2(\rho_s)$ 范数在逐胞元平移后不变。在相应远尾部，令

$$u_N=c_N\,\eta\!\left(\frac{x-X_N}{NL_s}\right)w(x,y),$$

其中 $\eta\in C_c^\infty$ 非零，$X_N$ 使支撑逃向该尾部，$c_N$ 使 $\|u_N\|_{\mathcal H}=1$。周期性给出 $c_N=O(N^{-1/2})$，并有

$$\|(A-\lambda)u_N\|_{\mathcal H}=O(N^{-1}),\qquad
u_N\rightharpoonup0.$$

残量仅由 $\eta'$、$\eta''$ 的交换子产生；支撑上 $\rho=\rho_s$。Weyl 判据于是给出 $\lambda\in\sigma_{\rm ess}(A)$。两条引线分别处理即得结论。$\square$

### 推论 T1.2（间隙内的谱）

**状态：已证明。** 若开区间 $G=(a,b)$ 同时不交于 $\sigma(A_-)$ 与 $\sigma(A_+)$，则 $\sigma(A)\cap G$ 只由孤立、有限重的特征值组成；它们只能向 $a,b$ 聚集。每个紧区间 $I\Subset G$ 内只有有限多个特征值。整个开间隙内未必只有有限多个，也没有由此得到单模态结论。

**证明。** T1.1 排除了 $G$ 中的本质谱。自伴算子的非本质谱点按定义为孤立有限重特征值；若紧子区间内有无限多个，紧性给出区间内部的谱聚点，矛盾。$\square$

### 定理 T1.3（指数衰减及一个显式充分条件）

**状态：已证明。** 设 $Au=\lambda u$，$u\ne0$，$\lambda\in G$。对引线 $s$ 定义

$$g_s=\operatorname{dist}(\lambda,\sigma(A_s))>0.$$

任选长度 $\ell>0$。只要 $\alpha_s>0$ 满足

$$q_s(\alpha_s):=
\frac{2\alpha_s\sqrt{\lambda+g_s}}{\sqrt{\rho_{\min}}\,g_s}
+\frac{\alpha_s^2+\alpha_s/\ell}{\rho_{\min}g_s}<1, \tag{T1.3}$$

则在右尾部 $e^{\alpha_+x}u\in H^2$，在左尾部 $e^{-\alpha_-x}u\in H^2$。特别地，对 $\alpha=\min(\alpha_-,\alpha_+)$ 存在有限 $C_u$ 使

$$|u(x,y)|\le C_u e^{-\alpha|x|}$$

于充分远的两尾部成立。一个显式允许范围为

$$0<\alpha_s<\frac{\sqrt{B_s^2+4\rho_{\min}g_s}-B_s}{2},
\qquad B_s=2\sqrt{\rho_{\min}(\lambda+g_s)}+\ell^{-1}. \tag{T1.4}$$

**证明。** 仅证右侧。取截断函数 $\eta=1$ 于充分右处、$\eta=0$ 于 $x\le x_+$，使其过渡区也位于右引线。令 $w=\eta u$，则

$$(A_+-\lambda)w=f=-\rho_+^{-1}(2\eta'\partial_xu+\eta''u),$$

$f$ 的 $x$ 支撑紧。记 $R=(A_+-\lambda)^{-1}$。谱定理及 $\lambda\ge0$ 给出

$$\|R\|\le g_+^{-1},\qquad
\|A_+^{1/2}R\|^2
=\sup_{t\in\sigma(A_+)}\frac{t}{(t-\lambda)^2}
\le\frac{1}{g_+}+\frac{\lambda}{g_+^2}.$$

又由型恒等式

$$\|\rho_+^{-1}\partial_xRf\|_{\mathcal H_+}
\le\rho_{\min}^{-1/2}\|A_+^{1/2}Rf\|_{\mathcal H_+}.$$

在 $f$ 支撑的右边选一个起点 $b$。构造非负有界的 $W^{2,\infty}$ 截断权 $h_N$：它在 $x\le b$ 为零，斜率从 $0$ 在长度 $\ell$ 内上升至 $\alpha_+$，中间保持该斜率，再在足够远处下降至 $0$；要求

$$|h_N'|\le\alpha_+,\qquad |h_N''|\le\alpha_+/\ell.$$

把远端平台移至无穷可使 $h_N(x)$ 点态趋于一个在 $x\ge b+\ell$ 等于 $\alpha_+(x-b-\ell/2)$ 的权。乘法和链式法则在 $H^2$ 中合法，且

$$e^{h_N}(A_+-\lambda)e^{-h_N}=A_+-\lambda+B_N,$$

$$B_N=\rho_+^{-1}\bigl(2h_N'\partial_x+h_N''-(h_N')^2\bigr).$$

上述估计保证 $\|B_NR\|\le q_+(\alpha_+)<1$。因此

$$\|e^{h_N}w\|_{\mathcal H_+}
\le\frac{\|f\|_{\mathcal H_+}}{g_+(1-q_+)}.$$

同一恒等式及 $R:\mathcal H_+\to H^2_\beta(B)$ 的有界性给出 $e^{h_N}w$ 的统一 $H^2$ 界。弱紧性和 Fatou 引理得到指数加权的 $H^2$ 结论。在固定大小的平移窗口上用二维 $H^2\hookrightarrow C^0$ 嵌入即可得到点态界，常数与窗口位置无关。左侧把 $x$ 换为 $-x$。$\square$

这个衰减条件只需要与两条引线谱的距离，并不需要与其他缺陷特征值隔离。如果仅知可靠的特征值包络 $I=[\mu-R,\mu+R]\Subset G$，可用 $\lambda\le\sup I$ 和 $g_s\ge\operatorname{dist}(I,\sigma(A_s))$ 取得统一的保守常数。

### T1.4 实现中真正需要的带隙证书

对每条引线，可选择不同的带序号 $n_s$，提供两个**可靠**的数

$$\overline a_s\ge\sup_\theta\lambda_{s,n_s}(\theta),\qquad
\underline b_s\le\inf_\theta\lambda_{s,n_s+1}(\theta),\qquad
\overline a_s<\underline b_s.$$

这两个端点的正确方向很重要：下方能带需要上界，上方能带需要下界。令

$$a_*:=\max(\overline a_-,\overline a_+),\qquad
b_*:=\min(\underline b_-,\underline b_+).$$

若

$$\boxed{a_*<\mu-R\quad\hbox{且}\quad\mu+R<b_*}, \tag{T1.5}$$

则整个闭区间在本质谱之外。一个已证明的谱距离上界再保证区间内至少有一个离散特征值。严格不等号不可替换为允许碰到带边的非严格不等号。

只在有限个 $\theta$ 上画能带不足以形成这个证书。下面给出便宜但可能偏保守的网格补偿。

**引理（能带平方根的 Lipschitz 界，已证明）。** 若 $\rho_s\ge\rho_{\min,s}>0$，则相邻规范分支中

$$\left|\sqrt{\lambda_{s,n}(\theta)}-
\sqrt{\lambda_{s,n}(\theta')}\right|
\le\frac{|\theta-\theta'|}{\sqrt{\rho_{\min,s}}}. \tag{T1.6}$$

证明：规范变换后型为

$$a_\theta[v]=\|(\partial_x+i\theta)v\|_2^2+\|\partial_yv\|_2^2.$$

对每个 $v\ne0$，三角不等式给出

$$\left|\frac{\sqrt{a_\theta[v]}}{\|v\|_{\mathcal H_s}}-
\frac{\sqrt{a_{\theta'}[v]}}{\|v\|_{\mathcal H_s}}\right|
\le\frac{|\theta-\theta'|}{\sqrt{\rho_{\min,s}}}.$$

在同一固定型域上先取 $n$ 维子空间中的上确界，再取子空间下确界，得到结论。Brillouin 区端点用相等的规范分支识别。$\square$

设一组网格点覆盖 Brillouin 圆，覆盖半径为 $h_s$，并在每个网格点已有可靠纤维包络 $\ell_{n,i}\le\lambda_{s,n}(\theta_i)\le u_{n,i}$。于是可以取

$$\overline a_s=
\left(\max_i\sqrt{u_{n_s,i}}+\frac{h_s}{\sqrt{\rho_{\min,s}}}\right)^2,$$

$$\underline b_s=
\left(\max\left\{0,\min_i\sqrt{\ell_{n_s+1,i}}-
\frac{h_s}{\sqrt{\rho_{\min,s}}}\right\}\right)^2. \tag{T1.7}$$

该证书的可靠性仍以纤维特征值**下界和上界本身可靠**为前提；仅有 BIE 小奇异值或普通 FEM Ritz 上界不足以提供上方能带的下界。由于目标区间仅约 $10^{-9}$，但若它离带边有宏观余量，带隙证书完全不必也算到 $10^{-9}$。这部分是两条引线共享的离线费用，可以和候选场的 40 分钟评价预算分开报告；若要求从零开始的总时间，则必须一并计入。

### T1 数据与费用

| 量 | 用途和依据 | 费用属性 |
|---|---|---|
| $d,L_-,L_+,\beta,\rho_{\min,s},\rho_{\max,s}$ | 定义算子、T1.1 假设 | 已知输入；不要求 $L_-=L_+$ |
| 两侧纤维 $\lambda_{s,n_s},\lambda_{s,n_s+1}$ 的网格包络 | T1.7 构成全 $\theta$ 带隙证书 | 主要离线成本；无法由现有候选数据估算耗时 |
| 网格覆盖半径 $h_s$ | 漏采样补偿 | 标量计算 |
| $a_*,b_*$ 与 $[\mu-R,\mu+R]$ 的严格分离 | T1.5，排除本质谱 | 标量计算 |
| $g_s$ 的下界与 $\sup I$ | T1.3 指数衰减速率 | 可从带隙证书直接得到；不需要为谱距离定理另算特征函数 |



## T2 用实际 MFS 表示定义场并计入周期接缝

### T2.1 固定一个确切的数学场

**状态：在以下可检查条件下定义成立。** 保留草稿 (5.2) 的连续三角多项式密度。对每个参考胞元，在背景区域把场写成

$$
u_{\rm cell}(z)=u_{\rm near}(z)+\sum_{q=1}^{N_p}a_qG^{(\kappa_e)}(z,p_q)
+\sum_{q=1}^{N_w}b_q e^{i\zeta_q\cdot z}+u_b(z),\qquad \kappa_e=\widehat k\sqrt{\rho_e}. \tag{T2.1}
$$

这里 $u_{\rm near}$ 是有限个近邻周期像上的**连续**单层与双层势，包含本胞元的真实源曲线；$p_q$ 是代理点；$a_q,b_q$ 是冻结的有限复系数；$\zeta_q\cdot\zeta_q=\kappa_e^2$（复向量的双线性点积）；$u_b$ 是草稿中的有限 Rayleigh 场。柱内仍用波数 $\kappa_c$ 的连续层势。必须检查：

1. 本胞元以外的源曲线及全部代理点与所定义分片的闭包有正距离。不能在胞元内留下代理点奇性。
2. 所有背景波、代理源的波数与该区域的 $\mu\rho$ 一致。数学定义中的 $\gamma_m$ 使用精确的色散关系，不把一个不满足色散关系的浮点近似波数当成精确数。
3. 每个参考胞元的密度及有限修正系数线性依赖状态 $v\in\mathbb C^K$；左右使用各自的几何、$L_\pm$ 与 $\mathsf P_\pm$，按 (5.3)–(5.4) 延拓。
4. 数值保存的系数可视为精确的二进制有理数；求解器、QZ 分解和最小二乘拟合是否准确，不是本定理的前提。它们的效果由实际场的跳跃衡量。评价这些固定表达式的误差另行计入。

若现有代码只保存各源节点对应的 MFS 核系数，可把它们与密度、求积权的乘积先求和，直接冻结最终的 $a_q,b_q$；近邻像的奇异层势仍保留连续积分。这给出一个明确、易评价的场。它一般不同于“未知的连续源依赖 MFS 系数函数再精确积分”的场，因此需要按此定义重新评价残差，不能无说明地复用旧残差。也可固定一个源无关的最小二乘线性映射，由解析的右端定义连续源依赖系数；这时其积分误差须计入 T3。

有限修正项不必等于某个精确准周期 Green 函数的误差。它们只需是上述区域内的精确 Helmholtz 解。有限 Rayleigh 阶数 $M$、有限密度次数、离散传播矩阵的误差，均不是另一个必须与“真场”比较的截断误差；它们已通过所定义场的全界面跳跃进入证书。

### 定理 T2.2（逐片直到边界的 $H^2$ 正则性）

**状态：已证明，假设为 T2.1 的条件及下述光滑性。** 每条材料界面为正则、嵌入的解析闭曲线，与胞元边界有正距离；密度为有限三角多项式；近邻像和有限修正满足 T2.1。则 $\widehat u$ 在每个材料分片内直到边界局部属于 $H^2$，并在人工墙及上下接缝每侧有普通的单侧值迹和法向迹。曲线解析性可放宽为足够高的光滑性；此处采用题设的解析性以同时服务于 T3。

**证明。** 只需证明同一波数下

$$v=S^{(\kappa)}[\omega]+D^{(\kappa)}[\tau]$$

在一条材料曲线的两侧属于 $H^2$。取外法向 $\nu$，法坐标 $(s,t)$ 中 $t>0$ 是外侧。光滑参数上的有限 Fourier 密度作为弧长函数也是光滑的。二维 Helmholtz 单层核为对数奇性；双层核可由 $C/|z-z'|$ 局部控制。因此曲线积分至多给出 $C(1+|\log\operatorname{dist}(z,\Gamma)|)$ 型局部界，二者均属于 $L^2_{\rm loc}$。

设 $\delta_\Gamma$ 为曲线测度，分布 $\operatorname{div}(\tau\nu\delta_\Gamma)$ 对测试函数 $\phi$ 的作用为 $-\int_\Gamma\tau\partial_\nu\phi$。由 $(\Delta+\kappa^2)G^{(\kappa)}=-\delta$，直接对测试函数运算得到

$$
(\Delta+\kappa^2)v=-\omega\delta_\Gamma+
\operatorname{div}(\tau\nu\delta_\Gamma). \tag{T2.2}
$$

构造一个仅在局部领子内非零的分片光滑函数 $w$：内侧取零，外侧在 $t=0$ 附近取 $\tau(s)-t\omega(s)$，再乘以光滑截断函数。它的外减内值跳跃为 $\tau$，外减内法向跳跃为 $-\omega$。分片积分两次给出

$$
(\Delta+\kappa^2)w=F-\omega\delta_\Gamma+
\operatorname{div}(\tau\nu\delta_\Gamma),\qquad F\in L^2_{\rm loc}.
$$

因此 $(\Delta+\kappa^2)(v-w)=-F$ 且 $v-w\in L^2_{\rm loc}$。常系数椭圆方程的局部 $H^2$ 正则性可由截断 Fourier 估计得到，故 $v-w\in H^2_{\rm loc}$。$w$ 在每侧直到界面光滑，所需结论成立。这一论证同时给出通常的层势跳跃关系，不需要先假定 (P3)。远处的像、代理源和有限平面波在闭分片附近光滑；人工墙和胞元角点附近，单侧胞元公式还可向其外部延拓，所以不存在由人工矩形角点造成的边值正则性障碍。每个有界窗口只涉及有限个胞元，逐胞元平移保持局部正则性。$\square$

上述局部正则性可不用另引边界定理：设 $h=v-w$。先取一个紧支撑截断 $\chi_1$，由 $h\in L^2$ 与 $(\Delta+\kappa^2)h\in L^2$，可得 $(1-\Delta)(\chi_1h)\in H^{-1}$，因为交换子只含一阶弱导数。Fourier 乘子 $(1+|\xi|^2)^{-1}$ 把 $H^{-1}$ 映到 $H^1$，故 $h$ 在更小邻域属于 $H^1$。再取支撑于该邻域的 $\chi_2$，此时交换子属于 $L^2$，同一乘子把 $L^2$ 映到 $H^2$，得到 $h\in H^2_{\rm loc}$。

**全局平方可积性。** 令 $\mathcal U_s:\mathbb C^K\to L^2(\mathcal C^s,\rho_s)$ 是参考胞元的线性场映射。以上正则性和有限维性保证其有界。若可靠验证某个 $p_s\ge1$ 满足 $\|\mathsf P_s^{p_s}\|_2\le r_s<1$，则

$$\sum_{j\ge0}\|\mathcal U_s\mathsf P_s^jc_s\|^2<\infty.$$

这用下文 T3.8 的同一几何级数证明，从而 (P4) 成立。这里只需证明各参考场范数有限，不需要为了 (P4) 精确积分全部 $U$。

### 定理 T2.3（含非精确准周期接缝的谱距离界）

**状态：已证明。** 设 T1 的算子假设成立，$\mu>0$。设 $\widehat u\ne0$ 在各均匀分片内满足 $(\Delta+\mu\rho)\widehat u=0$，逐片局部 $H^2$ 直至边界，且 $\widehat u\in\mathcal H$。不要求 $\widehat u$ 的上下迹准周期。材料曲线与胞元边界分离，全部竖墙和材料曲线构成局部有限的分片；接缝按每个胞元的 $x$ 区间分段。

设 $q=e^{i\beta d}$，在接缝的上边界代表上定义

$$
J_{\Sigma,0}(x)=q\widehat u(x,-d/2)-\widehat u(x,d/2),\qquad
J_{\Sigma,1}(x)=\partial_y\widehat u(x,d/2)-q\partial_y\widehat u(x,-d/2). \tag{T2.3}
$$

这与草稿 (5.7) 中值跳跃、导数跳跃采用相反次序的约定一致。每段上、下边界只配成一条接缝，不能计两次。令

$$\mathscr E_{\rm new}=\mathscr E_{\rm mat}\mathbin{\dot\cup}\mathscr E_{\rm art}
\mathbin{\dot\cup}\mathscr E_\Sigma,$$

$$\varepsilon_{{\rm new},\ell_*}^2=
\varepsilon_{\partial,\ell_*}^2+
\int_{\mathbb R}\bigl(|J_{\Sigma,1}|^2+\ell_*^{-2}|J_{\Sigma,0}|^2\bigr)\,dx<\infty. \tag{T2.4}$$

若已验证

$$\sum_{\Gamma\in\mathscr E_{\rm new}}
\left(\|z\|_\Gamma^2+\ell_*^2\|\partial_{\nu_\Gamma}z\|_\Gamma^2\right)
\le C_{\rm new}^2\|(A+\mu)z\|_{\mathcal H}^2\quad(z\in D(A)),$$

则 $Q=C_{\rm new}\varepsilon_{{\rm new},\ell_*}<U=\|\widehat u\|_{\mathcal H}$ 时

$$\boxed{\operatorname{dist}(\mu,\sigma(A(\beta)))\le\frac{2\mu Q}{U-Q}.} \tag{T2.5}$$

更适合计算的版本是把界面分为有限种组 $g$，每组可包含无限多条平移曲线，且允许使用不同 $\ell_g$。若每组有迹界 $C_g$，取

$$\varepsilon_g^2=\sum_{\Gamma\in g}\left(\|J_{\Gamma,1}\|^2+
\ell_g^{-2}\|J_{\Gamma,0}\|^2\right),\qquad
\boxed{Q=\sum_g C_g\varepsilon_g.} \tag{T2.6}$$

同样得到 (T2.5)。适宜的组为中心材料、左右引线材料、人工竖墙、水平接缝；也可先保留原来的材料加竖墙组，再单独添加接缝。

**证明。** 若 $\mu\in\sigma(A)$，结论显然；以下设 $\mu\notin\sigma(A)$。草稿定理 5.2 的证明中取 $z=(A-\mu)^{-1}\widehat u$。该 $z$ 是精确准周期且全局 $H^2$ 的辅助场，无论 $\widehat u$ 的接缝误差多大都成立。上下 Green 边界项不再相消，而是恰好等于

$$\int_{\mathbb R}\left(J_{\Sigma,1}\overline{z(x,d/2)}+
J_{\Sigma,0}\overline{\partial_yz(x,d/2)}\right)dx. \tag{T2.7}$$

这是把 $z(x,d/2)=qz(x,-d/2)$ 及其导数关系代入两条边的外法向公式得到的。于是原来的恒等式 (5.20) 只需加上 (T2.7)。使用仅依赖 $x$ 的紧支撑截断时，接缝法向为 $e_y$，因此 $\partial_{\nu_\Sigma}\chi_R=0$；原有截断余项仍趋零。对全部界面或逐组作 Cauchy–Schwarz，得到

$$U^2\le Q\|(A+\mu)z\|_{\mathcal H}
\le Q(1+2\mu/\operatorname{dist}(\mu,\sigma(A)))U.$$

同草稿移项即得 (T2.5)。墙与接缝相交的点是曲线测度零集；此处没有沿边作切向分部积分，不产生额外的角点配对项。$\square$

### 接缝领子、覆盖重数与常数

在准周期圆柱上，把水平接缝 $\Sigma=\mathbb R\times\{d/2\}$ 的领子取为 $|y-d/2|<\delta_\Sigma$，其中 $0<\delta_\Sigma<d/2$，跨出条带的部分用辅助场 $z$ 的准周期延拓识别。其曲率为零、Jacobian 为一、该组内部的覆盖重数为一。按胞元拆成线段仅划分 $x$，不会增加覆盖重数。应用草稿的一维不等式即可取

$$C_{0,\Sigma}=\delta_\Sigma^{-1},\qquad C_{1,\Sigma}=\delta_\Sigma/2,$$

$$C_\Sigma^2=\frac{C_{0,\Sigma}}{\rho_{\min}\mu^2}
+\frac{C_{1,\Sigma}+\ell_\Sigma^2C_{0,\Sigma}}{4\mu}
+\ell_\Sigma^2 C_{1,\Sigma}\rho_{\max}. \tag{T2.8}$$

该领子可以穿过材料界面，因为它只作用于全局 $H^2$ 的 $z$，不作用于不连续的候选场。竖墙领子与水平接缝领子必然在墙端交叠。若统一成一组，必须重新验证全部领子的覆盖重数；原来为一且材料领子与接缝分离时，加入接缝通常可取二。不能把原 $N_{\rm ov}=1$ 原样留下。采用 (T2.6) 则不必让已有残差全部承受统一的 $\sqrt2$ 因子：各组分别由全局体范数控制，再把 $C_g\varepsilon_g$ 相加即可。T4 提供更小的 $C_g$。

### T2.4 人工墙模态尾项应怎样替换

**状态：以下替代公式已证明；草稿 (5.23) 在非精确准周期场上不能直接使用。** 对任意墙段 $\Gamma=\{x_\Gamma\}\times(-d/2,d/2)$，$\psi_m(y)=d^{-1/2}e^{i\beta_my}$ 仍构成 $L^2$ 的完备正交基，所以对**实际场的实际系数**，Parseval 等式 (5.22) 保持成立。但一般不能再由层势的值系数乘 $\pm i\gamma_m$ 得到法向系数；(4.9) 也不再是 MFS 场的全部模态提取公式。

一个最简单的反例机制是：解析函数 $f(y)$ 只要不满足端点准周期匹配，$h(y)=e^{-i\beta y}f(y)$ 的周期延拓就有端点跳跃，Fourier 系数通常只有 $1/|m|$ 的尾。因此实几何的正分离距离本身不能推出草稿的指数模态尾界。

**引理（可计算的非周期端点尾界）。** 设 $f\in W^{p,1}(-d/2,d/2)$，$p\ge1$，$h=e^{-i\beta y}f$，并令

$$D_j=\frac{|h^{(j)}(d/2)-h^{(j)}(-d/2)|}{\sqrt d}
\left(\frac d{2\pi}\right)^{j+1},\quad 0\le j<p,$$

$$E_p=\frac{\|h^{(p)}\|_{L^1}}{\sqrt d}\left(\frac d{2\pi}\right)^p.$$

对 $f_m=\int f\overline{\psi_m}$、$m\ne0$，有

$$|f_m|\le\sum_{j=0}^{p-1}\frac{D_j}{|m|^{j+1}}+\frac{E_p}{|m|^p}. \tag{T2.9}$$

因而任意 $M\ge1$ 满足

$$\boxed{\sum_{|m|>M}|f_m|^2\le
2(p+1)\left[\sum_{j=0}^{p-1}\frac{D_j^2}{(2j+1)M^{2j+1}}
+\frac{E_p^2}{(2p-1)M^{2p-1}}\right].} \tag{T2.10}$$

证明：对 $\int h(y)e^{-2\pi imy/d}dy$ 分部积分 $p$ 次；两端指数相同，留下上述端点差。再用 $(\sum_{1}^{p+1}a_j)^2\le(p+1)\sum a_j^2$ 及 $\sum_{m>M}m^{-q}\le M^{1-q}/(q-1)$。$\square$

分别对 $f=J_{\Gamma,1}$ 和 $J_{\Gamma,0}$ 应用此界，并按 $1,\ell_*^{-2}$ 加权，即是实际 MFS 场下可替代 (5.23) 的尾项。其常数需对**已经组合的跳跃及其导数**取界；先对两个大场分别取导数范数通常过于保守。也可以减去一个已知的端点 Hermite 插值多项式后，再控制剩余项；减去多项式本身的 Fourier 尾不可丢弃。

本算例优先使用 T3 的直接墙段 Taylor/多项式求积。这样不用恢复无穷模态，也不需要承受 $1/m$ 尾的保守性。保留 $M=48$ 作为场的定义参数完全可以；评价完整墙跳跃时不把 $|m|>48$ 的部分人为置零。

### 两条可靠化路线的比较

| 路线 | 必须控制的量 | 对现有实现的含义 |
|---|---|---|
| 本报告路线：MFS 场加接缝残差 | 全部材料、墙、接缝的实际跳跃及其求积误差；代理源分离；传播衰减 | 不需要证明 MFS 最小二乘近似了多少位精确 Green 函数；可直接复用有限表示和多数浮点评价 |
| 精确准周期场路线 | 以精确 $G_{\rm QP}$ 重新定义场，再证明 $G_{\rm MFS}-G_{\rm QP}$ 及所需源、目标导数的误差界 | 最小二乘边界失配本身不是内部核误差界；还需对应问题的稳定性常数，或独立可靠的 Ewald 评价 |

Arens、Sandfort、Schmitt、Lechleiter 的 *Analysing Ewald’s Method for the Evaluation of Green’s Functions for Periodic Media* 中，已核对的 KIT 原文 Theorems 4.2–4.4 给出二维 Ewald 截断界，Theorems 7.1–7.2 处理梯度；它们可用于后一条路线，但不能仅用“梯度定理”便声称已经控制 Müller 法向跳跃所需的混合二阶导数。该二阶导数还需逐项推导或另作可靠计算。

**成本判断属于方案评估：** 对已经有 MFS 场且只需此候选的谱证书，接缝路线的新增积分通常更便宜，因其省去了精确核误差和稳定性估计。然而若接缝缺陷本身过大、代理系数严重放大舍入误差，或直接墙求积的证书很保守，精确 Ewald 重定义场可能更合算。缺少实际系数和接缝数值，不能证明某一路线在本算例必定满足 40 分钟及全宽目标。

如果另一条路线已有核误差证书 $E_{ab}$，其中 $a,b\in\{0,1\}$ 分别表示目标、源方向导数阶数，则同一密度所产生的场差满足

$$|\delta u|\le E_{00}\|\omega\|_{L^1}+E_{01}\|\tau\|_{L^1},\qquad
|\delta\partial_\nu u|\le E_{10}\|\omega\|_{L^1}+E_{11}\|\tau\|_{L^1}.$$

这说明需要的是包含混合二阶导数的绝对误差证书。它可由“可靠 Ewald 值减去实际有限 MFS 值”的覆盖计算得到，不一定经过稳定性定理；但尚需对全部源目标参数覆盖，不能只比较几个实采样点。


## T3 可计算的求积与评价误差界

本节所称“已证明”指下面写出的不等式及其明确假设；具体算例仍需计算证书中的数值。曲线是解析的、密度是三角多项式，并不单独提供一个可用于认证的误差数。必须同时给出可用复邻域及该邻域上的上界。两个网格上的积分接近也不能替代这些数据：任意有限采样集合都存在非零解析函数在所有采样点取零。

固定输入浮点数可被理解为精确的二进制有理数；这样无需证明候选求解、最小二乘或密度插值逼近了另一个未知精确解。需要包住的是这个**已固定场**的连续积分和特殊函数评价误差。若舍入只作估计，下述所有区间操作可拆成“已证明截断界 + 单列舍入估计”；不得再称其为包含全部舍入的严格区间。

### T3.0 解析证书应包含哪些数据

曲线在实轴取 $\mathbb R^2$ 中的值，且正则、简单闭合；这些几何条件须核验。曲线写成
$$
 r(t)=\sum_{|m|\le P}r_m e^{2\pi i m t},\qquad
 \eta(t)=\sum_{m\in I_\eta}\eta_m e^{2\pi i m t},\quad t\in\mathbb R/\mathbb Z.
$$
若曲线不是有限 Fourier 和，以下各式还须增加已证明的系数尾界。令
$$
 B_j(a)=\sum_{|m|\le P}(2\pi|m|)^j\|r_m\|e^{2\pi a|m|},\qquad
 D_j(a)=\sum_{m\in I_\eta}(2\pi|m|)^j|\eta_m|e^{2\pi a|m|}.
$$
它们分别包住复条带中几何及密度的第 $j$ 阶导数。这里复向量平方必须使用双线性点积而非 Hermitian 内积：
$$
 v^2(t)=r'(t)\cdot r'(t),\qquad
 q(t,s)=(r(t)-r(s))\cdot(r(t)-r(s)),\qquad
 H(t,s)=\frac{q(t,s)}{4\sin^2\pi(t-s)}.
$$
$H$ 在对角线可去，$H(t,t)=v^2(t)/(4\pi^2)$。证书应验证：

1. 所用复域内 $v^2$ 无零，并选定与实轴正弧长因子相容的平方根；
2. 自相互作用所用复域内 $H$ 无零，并给出解析 $\log H$ 的分支；例如区间验证 $\operatorname{Re}H\ge h_0>0$ 是一个充分条件；
3. 不相交源—目标对的复平方距离避开零，并能一致选择 Hankel 函数分支；
4. 近邻周期像、代理源位置和**实际冻结的代理源/平面波系数**。仅给原密度系数不足以包住 MFS 修正场；
5. 所用参数区间、复邻域半径、Hankel/Bessel 包络及评价误差。

这些证书可以在参数矩形上用区间细分、Taylor 包络及 Fourier 系数界得到，无需在每个残差采样点重复构造。对相隔至少 $\delta$ 的实源—目标对，若复化后两者合计位移不超过 $\delta/4$，则
$$
 \operatorname{Re}q\ge 7\delta^2/16>0.
$$
证明是令实距离 $d_0\ge\delta$、复位移范数 $e\le\delta/4$，使用 $\operatorname{Re}q\ge d_0^2-2d_0e-e^2$。而复位移可由 $aB_1(a)$ 等显式上界控制。这是一个便宜但可能保守的离界面证书；自相互作用必须使用去掉 $\sin^2$ 因子的 $H$，不能使用实距离下界。

有限 MFS 修正最好直接定义为
$$
 u_{\rm corr}(x)=\sum_{q=1}^{N_p}c_q\Phi_q(x)+\sum_{r=1}^{N_w}a_rW_r(x),
$$
其中系数已冻结，$\Phi_q$ 的奇点在该胞元闭包之外，$W_r$ 是精确 Helmholtz 平面波。此时修正项只需有限求和，无须重新进行源曲线内层积分。若实现把修正保留为源位置依赖的核，则还必须提供该系数映射的解析定义及上界，不能把离散采样数组自动视为解析函数。

### T3.1 闭曲线外层求积

**定理 T3.1（在列出的解析证书条件下证明）。** 设 $J_D,J_N$ 为材料界面的值跳跃和法向跳跃。设其关于 $t$ 的解析延拓存在于 $|\operatorname{Im}t|<a$，并满足
$$
 |J_D(t)|\le M_D,\quad |J_N(t)|\le M_N,\quad
 |w(t)|\le W,
 \qquad w(t)=\sqrt{r'(t)\cdot r'(t)}.
$$
令 $f^\sharp(z)=\overline{f(\overline z)}$，并定义真正的全纯函数
$$
 F(z)=w(z)\bigl(J_N(z)J_N^\sharp(z)+\ell_*^{-2}J_D(z)J_D^\sharp(z)\bigr),
 \quad M_F=W(M_N^2+\ell_*^{-2}M_D^2).
$$
注意不能把 $|J(z)|^2$ 当作全纯函数。对 $t_q=q/N$，设计算值组成向量
$$
 \widetilde{\boldsymbol j}_q=(\widetilde J_N(t_q),\ell_*^{-1}\widetilde J_D(t_q)),
 \qquad
 \|\boldsymbol j(t_q)-\widetilde{\boldsymbol j}_q\|_2\le e_q.
$$
若 $\overline w_q\ge w(t_q)$，则
$$
 \boxed{
 \int_\Gamma(|J_N|^2+\ell_*^{-2}|J_D|^2)\,ds
 \le {1\over N}\sum_{q=0}^{N-1}\overline w_q
        (\|\widetilde{\boldsymbol j}_q\|_2+e_q)^2
      +{2M_F\over e^{2\pi aN}-1}. }
\tag{Q1}
$$
$e_q$ 必须包含内层求积、特殊函数和 FMM 的截断误差；若要求完全严格，再加入舍入误差。

**证明。** 移动 Fourier 系数积分路径得到 $|\widehat F_m|\le M_Fe^{-2\pi a|m|}$；离散正交性给出 $N^{-1}\sum F(t_q)=\sum_{r\in\mathbb Z}\widehat F_{rN}$。两者相减、对 $r\ne0$ 求和，得到 $2M_F/(e^{2\pi aN}-1)$。实节点处三角不等式给出第一项。证毕。

这是 Trefethen–Weideman, *The Exponentially Convergent Trapezoidal Rule* (2014), Theorem 3.2 的周期为 $1$ 的版本；原文已核对，原定理周期为 $2\pi$，常数是 $4\pi M/(e^{aN}-1)$。[TW14]

**成本与局限。** 已有 $N$ 点浮点评价可以完全复用；新开销是一个解析包络证书及节点误差界。若用巨大分量的三角不等式直接构造 $M_N$，这个界可能过于保守。尤其对 $\varepsilon\sim10^{-12}$，平方范数的绝对误差目标接近 $10^{-24}$；“指数收敛”并不自动保证 $N=768$ 足够。首先组合跳跃，再计算其解析包络或下述分片 Taylor 模型，通常更有希望。

### T3.2 内层 Kress 求积的显式界

本任务的 Müller 跳跃应先合并为算子差。主奇性相消后的核写成
$$
 K(t,s)=A(t,s)L(t-s)+B(t,s),\qquad
 L(\xi)=\log(4\sin^2\pi\xi).
$$
弧长因子包含在 $A,B$ 内。不能分别把两个超奇异算子当作普通可积核计算后相减。

**定理 T3.2（在列出的分裂条件下证明）。** 对固定实目标 $t$，记
$$
 h_t(s)=A(t,s)\eta(s),\qquad g_t(s)=B(t,s)\eta(s).
$$
假定它们是 $1$ 周期的、在 $|\operatorname{Im}s|<a$ 全纯，并有统一上界 $|h_t|\le H$、$|g_t|\le G$。取偶数 $N=2n$，令 $I_Nh_t$ 为通常的周期三角插值（Nyquist 频率作对称分配），定义
$$
 Q_N(t)=\int_0^1L(t-s)(I_Nh_t)(s)\,ds
             +{1\over N}\sum_{q=0}^{N-1}g_t(q/N).
$$
则
$$
 \boxed{
 |(K\eta)(t)-Q_N(t)|
 \le {4H e^{-2\pi an}\over1-e^{-2\pi a}}
          +{2G\over e^{2\pi aN}-1}. }
\tag{Q2}
$$
这是保守但完全显式的 Kress 乘积积分界。各密度和各核项分别建立 $H,G$ 后可以相加；先在解析层面组合相消的项可显著减小这些常数。

**证明。** $L$ 的 Fourier 系数为 $\lambda_0=0$、$\lambda_m=-1/|m|$ ($m\ne0$)，因此 $|\lambda_m|\le1$。$I_N$ 精确保持 $|m|<n$ 的模式；每一个其他模式混叠到一个模式或两个 Nyquist 模式，其系数绝对值之和不超过一。对单个输入模式，精确卷积与插值卷积的差绝对值因此不超过 $2$。又 $|\widehat h_{t,m}|\le He^{-2\pi a|m|}$，故卷积误差不超过
$$
 2\sum_{|m|\ge n}|\widehat h_{t,m}|
 \le4H\sum_{m=n}^{\infty}e^{-2\pi am}.
$$
光滑部分用 T3.1 的 Fourier 求和论证（不需要平方）。证毕。

若目标本身复化到 $|\operatorname{Im}t|\le b<a$，且 $H,G$ 对这一目标域同样成立，则一个可用版本是
$$
 |K\eta-Q_N|
 \le {4H e^{-2\pi(a-b)n}\over1-e^{-2\pi(a-b)}}
        +{2G\over e^{2\pi aN}-1}.
\tag{Q2c}
$$
证明在每个模式中增加 $|e^{2\pi imt}|\le e^{2\pi b|m|}$。该版本可用于下面 Taylor 模型的系数误差证书。若求积实现使用不同的 Nyquist 约定，须先核对它与这里的 $Q_N$ 一致，或单独界定 Nyquist 差项。

**复目标的定义。**

(Q2c) 中的复目标算子应明确定义为**实边界算子的 Fourier 解析延拓**。设 $h_t(s)$ 对复目标 $t$ 和源条带 $s$ 全纯，$|\operatorname{Im}t|\le b<a$，并令
$$
 \widehat h_m(t)=\int_0^1h_t(s)e^{-2\pi ims}\,ds.
$$
其对数卷积部分定义为
$$
 \mathcal Lh(t)=-\sum_{m\ne0}
          \frac{\widehat h_m(t)}{|m|}e^{2\pi imt}.
\tag{Q2d}
$$
由 $|\widehat h_m(t)|\le He^{-2\pi a|m|}$，该级数在 $|\operatorname{Im}t|\le b<a$ 绝对一致收敛，因而给出全纯函数；在实 $t$ 上它等于原来的 log-sine 卷积。精确算子的解析延拓再加光滑部分 $\int_0^1g_t(s)ds$；求积算子 $Q_N$ 则使用插值卷积的有限 Fourier 和，再加 $N^{-1}\sum_qg_t(q/N)$。两者的光滑部分仍由梯形误差项控制。

不能把 (Q2c) 理解为未经分支及路径处理的裸积分
$\int_0^1\log(4\sin^2\pi(t-s))h_t(s)ds$；这样的复对数写法可能不等于所需的解析延拓。用 (Q2d) 定义后，每个 $|m|\ge n$ 的混叠误差至多增加因子 $e^{2\pi b|m|}$，从而严格得到
$$
 |K\eta-Q_N|
 \le\frac{4He^{-2\pi(a-b)n}}{1-e^{-2\pi(a-b)}}
       +\frac{2G}{e^{2\pi aN}-1},
$$
这才是 (Q2c) 可用于 Cauchy/Taylor 系数认证的含义。


**可计算的 $A,B$，不是一个未说明的“解析常数”。** 令 $q=|x-y|^2$ 的双线性复化，并定义整函数
$$
 F_\kappa(q)=\sum_{j=0}^{\infty}{(-\kappa^2q/4)^j\over(j!)^2},
$$
$$
 E_\kappa(q)=
 \left({i\over4}-{\log(\kappa/2)+\gamma\over2\pi}\right)F_\kappa(q)
 +{1\over2\pi}\sum_{j=1}^{\infty}
       {(-1)^jH_j(\kappa^2q/4)^j\over(j!)^2},
$$
其中 $H_j=\sum_{r=1}^j1/r$，$\gamma$ 是 Euler 常数。对于正实 $\kappa$ 以及相容分支，
$$
 {i\over4}H_0^{(1)}(\kappa\sqrt q)
 =-{F_\kappa(q)\over4\pi}\log q+E_\kappa(q).
\tag{Q3}
$$
在曲线上利用 $q=4\sin^2\pi(t-s)H(t,s)$，可取单层核
$$
 A=-F_\kappa(q)/(4\pi),\qquad
 B=E_\kappa(q)-F_\kappa(q)\log H/(4\pi),
$$
再乘 $w(s)$。双层、伴随双层和两波数超奇异差，通过对这个表达式求源/目标法向导数得到。具体地，固定法向时
$$
 \partial_{\nu_x}\partial_{\nu_y}G(q)
 =G''(q)q_xq_y+G'(q)q_{xy},\quad
 q_x=2(x-y)\cdot\nu_x,\quad q_y=-2(x-y)\cdot\nu_y,
 \quad q_{xy}=-2\nu_x\cdot\nu_y.
$$
在两波数之差中 $F_{\kappa_e}-F_{\kappa_c}=O(q)$；应先把相关商写成解析除差，例如 $(F_{\kappa_e}-F_{\kappa_c})/q$，再求包络。$q_x,q_y=O((t-s)^2)$ 使其他表面法向导数商也有可去奇性。这样得到的 $A,B$ 确为解析函数，原先的超奇异主部已消掉。MFS 的非近邻修正及非零像只是解析的 $B$ 型贡献。

所有整函数级数都能以正项级数作显式余项控制。例如 $x=\kappa^2Q/4$，$|q|\le Q$，$\sum x^j/(j!)^2$ 截到 $j=p$ 后，只要 $x/(p+2)^2<1$，尾不超过
$$
 {x^{p+1}\over((p+1)!)^2}\,{1\over1-x/(p+2)^2}.
$$
含 $H_j$ 的级数使用相邻项比
$\frac{H_{j+1}}{H_j}\frac{x}{(j+1)^2}$；其上界可由 $H_{j+1}/H_j=1+1/((j+1)H_j)$ 得到。也可用粗界 $H_j\le j$ 与 $\sum x^j/(j!)^2\le e^x$。对 $\log H$、速度、法向及上述解析除差作区间包络即可产生数值 $H,G$。若 $A,B$ 已知包络为 $M_A,M_B$，则 $H\le M_AD_0(a)$、$G\le M_BD_0(a)$。

**成本。** 对三个参考胞元预计算几何包络后，每个目标误差常数可按面板共用。密度次数固定为 $N_\eta/2$ 时，$D_0(a)$ 含 $e^{\pi aN_\eta}$ 因子，所以原密度节点数恰好等于评价节点数时，粗包络未必小；零填充增加内层评价节点数仍保持场不变，且有明确收益。最简单实现为流式 $O(N_{\rm target}N_{\rm inner})$，无需保留全部核矩阵；重复状态可复用矩阵或低秩分解。

### T3.3 墙段和接缝的直接 Taylor 认证

不精确准周期的实际 MFS 场，在竖直墙上一般不具备解析周期延拓。必须对有限墙段积分，或显式加入端点缺陷项；本小节给出前者。水平接缝按每个胞元分段，遇到材料界面交点时继续分段。在不跨越源奇点的每个段内，实际有限修正场和连续层势都解析。

**定理 T3.3（已证明）。** 设一个参数面板是 $[c-h,c+h]$，其积分写成 $\int\|f(t)\|_2^2dt$；对曲线可取
$$
 f(t)=w(t)^{1/2}(J_N(t),\ell_*^{-1}J_D(t)),
$$
对以弧长为参数的墙段和接缝则 $w=1$。假定 $f$ 全纯于 $|z-c|<R$，$R>h$，且 $\|f(z)\|_2\le M$。设已算出的向量多项式
$$
 P(t)=\sum_{j=0}^pp_j(t-c)^j
$$
满足 Taylor 系数误差 $\|p_j-f^{(j)}(c)/j!\|_2\le\eta_j$。定义
$$
 e=\sum_{j=0}^p\eta_jh^j+
       {M(h/R)^{p+1}\over1-h/R},
 \quad
 V_P=\int_{-h}^h\left\|\sum_{j=0}^pp_js^j\right\|_2^2ds.
$$
则
$$
 \boxed{
 \bigl(\max\{0,\sqrt{V_P}-\sqrt{2h}\,e\}\bigr)^2
 \le\int_{c-h}^{c+h}\|f(t)\|_2^2dt
 \le(\sqrt{V_P}+\sqrt{2h}\,e)^2 . }
\tag{Q4}
$$
$V_P$ 是有限的精确代数表达式：
$$
 V_P=\sum_{j,k=0}^p\langle p_j,p_k\rangle
       {\bigl(1+(-1)^{j+k}\bigr)h^{j+k+1}\over j+k+1}.
$$
计算时转为正交 Legendre 基并求正平方和，可减少舍入相消。

**证明。** Cauchy 估计给出 Taylor 尾的逐点范数不超过 $M(h/R)^{p+1}/(1-h/R)$；加上系数误差可得 $\sup\|f-P\|\le e$。再在 $L^2$ 中使用正向和反向三角不等式。证毕。

另一完全实变量版本是已知 $\sup\|f^{(p+1)}\|\le D_{p+1}$ 时，将解析余项替换成 $D_{p+1}h^{p+1}/(p+1)!$。

**如何获得系数证书。** 先把两侧场、局部跳跃项、背景波、MFS 修正**相加成同一个 $J$ 的 Taylor 系数**，再对系数及余项取区间。对层势，可用源变量 Kress 求积的 Taylor/自动微分版本；如果已经在较大目标圆盘 $|t-c|\le R_0$ 上证明离散层势与连续层势之差不超过 $E_K$，Cauchy 公式给出第 $j$ 个 Taylor 系数误差不超过 $E_K/R_0^j$。其余有限修正项直接使用精确基函数的 Taylor 递推。普通浮点 $p_j$ 只有在另有系数误差界时才可用于认证。

这个策略采用 Dahne–Salvy, *Computation of Tight Enclosures for Laplacian Eigenvalues* (2020 预印本), §2.1 的核心做法：在严重相消的问题里，先合并函数的 Taylor 展开，再界定余项。原文 §2.2 也将场范数下界限制到内部子区域。这些段落已亲读；它们针对其特解法算例，不能直接当作本 BIE 核的显式常数定理。[DS20] 本处 (Q4) 的常数和证明独立给出。

**成本。** 每段通常只需一个中心处的 $p+1$ 阶 jet，加一份面板范围证书；若每段长度减半，余项按约 $2^{-p-1}$ 缩小。有限平面波 jet 有显式递推，Hankel jet 可由微分方程/区间幂级数获得；层势部分复用参考几何。实际 $p$、面板数与所需精度必须由已算出的余项自适应决定，不能预先保证某个固定数目。该方法无需假定墙上跳跃精确准周期，因此也适用于 T2 新加入的接缝。

### T3.4 FMM 误差不能遗漏

FMM 的 `tol` 参数只有在库保证它是所求值或梯度的绝对误差上界、并涵盖所有展开及平移截断时，才可直接放入 $e_q$。大多数浮点库的用户容差首先是算法参数，不能因为其名称是 `eps` 就视为可靠证书。这里 FMM 的截断误差属于本任务要求覆盖的误差，即使用户允许舍入仅作估计，也不能把 FMM 截断放到未证明的舍入项中。

可认证路线是：对实际使用的分离盒建立 Hankel/Bessel 展开尾界，对源强绝对值累加，再对值、法向导数分别给出绝对误差界；或者为少数主导残差面板采用直接核评价作为认证路径。近相互作用和自相互作用仍使用已证明的 Kress/局部求积界。

Epstein–Greengard–Klöckner, *On the Convergence of Local Expansions of Layer Potentials* (2013) 的 §2.3 处理二维 Helmholtz 局部展开，§4 区分展开截断与系数求积误差。但 §4 的 $C_q(N,\Gamma)$ 明确保留未展开的几何依赖；因此只引用该文的阶数估计不能得到本任务需要的显式数值证书。该原文已亲读。[EGK13] 本报告不声称已为用户未知的 FMM 实现给出可直接使用的完整截断证书。

### T3.4a 一个具有显式余项的源簇 Taylor 树评价器

**状态：下面的源簇展开及误差界已证明；尚未证明用户现有 FMM 库使用了这个展开、满足这些分离条件或逐步计入了全部截断误差。性能及最终区间宽度也未经算例验证。** 这个结果提供一条可独立实现的认证路径，并非对一个未审计 FMM 程序的事后背书。

#### 定理 T3.4a 源簇的值与梯度误差

设波数 $\kappa>0$。定义自由空间二维 Helmholtz 核
$$
 G_\kappa(x,y)=\mathcal G_\kappa(q),\qquad
 q=(x-y)\cdot(x-y),\qquad
 \mathcal G_\kappa(q)={i\over4}H_0^{(1)}(\kappa\sqrt q),
$$
其中复化时点积为双线性点积；在右半平面选择与正实平方根相容的分支。固定一个实源簇中心 $c\in\mathbb R^2$，源点为
$$
 y_j=c+v_j,\qquad v_j\in\mathbb R^2,\quad |v_j|\le a,
$$
其中 $a>0$；目标 $x\in\mathbb R^2$ 满足
$$
 R=|x-c|>3a,\qquad s={R\over3a}>1.
$$
设每个源的单层强度 $\omega_j\in\mathbb C$、双层强度 $\tau_j\in\mathbb C$ 和实单位方向 $\nu_j\in\mathbb R^2$ 已固定，考虑有限和
$$
 V(x)=\sum_j\bigl[\omega_jG_\kappa(x,y_j)
               +\tau_j\partial_{\nu_j,y}G_\kappa(x,y_j)\bigr].
\tag{F1}
$$
若它来自连续层势的某个求积和，求积权重应已吸收到 $\omega_j,\tau_j$ 中；连续积分到此有限和的误差仍由内层求积定理另行计入。

定义复 $q$ 盘
$$
 \mathcal D_R=\{q\in\mathbb C:|q-R^2|\le7R^2/9\}.
$$
给定可靠包络
$$
 A_r\ge\sup_{q\in\mathcal D_R}|\mathcal G_\kappa^{(r)}(q)|,
 \qquad r=0,1,2,
$$
并令
$$
 M_0=A_0,\qquad
 M_1={8R\over3}A_1,\qquad
 M_2={64R^2\over9}A_2+2A_1,
 \qquad
 \zeta_p={s^{-(p+1)}\over1-s^{-1}}.
\tag{F2}
$$
对每个源，将
$$
 t\longmapsto G_\kappa(x,c+tv_j),\qquad
 t\longmapsto\partial_{\nu_j,y}G_\kappa(x,c+tv_j)
$$
在 $t=0$ 的 Taylor 级数截到次数 $p\ge0$，再在 $t=1$ 取值；由此得到 $V_p(x)$。这里 $\partial_{\nu_j,y}$ 是核对其第二空间变量的方向导数，方向 $\nu_j$ 在 $t$ 变化时保持固定；它不是 $t$ 导数。则
$$
 \boxed{
 |V(x)-V_p(x)|
 \le\left(M_0\sum_j|\omega_j|+M_1\sum_j|\tau_j|\right)\zeta_p, }
\tag{F3}
$$
$$
 \boxed{
 \|\nabla_xV(x)-\nabla_xV_p(x)\|_2
 \le\left(M_1\sum_j|\omega_j|+M_2\sum_j|\tau_j|\right)\zeta_p. }
\tag{F4}
$$
因此 (F4) 同时包住任意实单位目标法向上的法向导数误差。若使用一般复偶极向量 $d_j\in\mathbb C^2$ 代替 $\tau_j\nu_j$，将 $\sum|\tau_j|$ 换成 $\sum\|d_j\|_2$，结论仍成立。

**证明。** 置 $w=x-c$、$r_j(t)=w-tv_j$ 和 $q_j(t)=r_j(t)\cdot r_j(t)$。在 $|t|\le s$ 上，$|tv_j|\le R/3$，从而
$$
 |q_j(t)-R^2|
 \le 2R|tv_j|+|tv_j|^2\le7R^2/9,
 \qquad \operatorname{Re}q_j(t)\ge2R^2/9>0.
\tag{F5}
$$
故所有复源位置对应的 $q_j(t)$ 均在 $\mathcal D_R$ 内；核的平方根及 Hankel 分支在该盘及其邻域全纯，相关 $t$ 函数在闭圆盘 $|t|\le s$ 的邻域全纯。

又有 $\|r_j(t)\|_2\le4R/3$。对任何固定实单位方向 $\nu$，
$$
 \partial_{\nu,y}q=-2r_j(t)\cdot\nu,
 \qquad \nabla_xq=2r_j(t),
$$
因此核值由 $M_0$ 包住，源方向导数与目标梯度分别由 $M_1$ 包住。进一步，
$$
 \nabla_x\partial_{\nu,y}\mathcal G_\kappa(q)
 =-4\mathcal G_\kappa''(q)(r_j(t)\cdot\nu)r_j(t)
       -2\mathcal G_\kappa'(q)\nu,
$$
其复 Euclidean 范数不超过 $M_2$。上述估计亦对复偶极向量使用向量范数成立。

若一个标量或有限维向量函数 $f$ 在 $|t|\le s$ 全纯且 $\|f(t)\|\le M$，Cauchy 系数估计给出 $\|[t^nf]\|\le Ms^{-n}$，故
$$
 \left\|f(1)-\sum_{n=0}^p[t^nf]\right\|
 \le M\sum_{n=p+1}^{\infty}s^{-n}=M\zeta_p.
$$
分别应用于核值、源方向导数、目标梯度和混合导数，再乘源强并相加，就得到 (F3)–(F4)。目标微分与有限 Taylor 截断可交换，所以 (F4) 中确实是 $\nabla_xV_p$。证毕。

若 $a=0$，所有源点都在中心，$p=0$ 已给出精确有限和；无须引入 $s$。

#### 如何可靠计算核包络

由于 $\operatorname{Re}q\ge2R^2/9$，包住 $\mathcal D_R$ 的复矩形仍位于右半平面。可以用支持复球/复区间输入的特殊函数库直接包络 $\mathcal G$ 及其导数；必要时对这个二维参数区域作细分。也可使用恒等式
$$
 \mathcal G_\kappa'(q)
 =-{i\kappa\over8\sqrt q}H_1^{(1)}(\kappa\sqrt q),
 \qquad
 \mathcal G_\kappa''(q)
 =-{\mathcal G_\kappa'(q)\over q}
        -{\kappa^2\mathcal G_\kappa(q)\over4q}.
\tag{F6}
$$
后一式由径向 Helmholtz 方程直接得到。因此若 $q_{\min}=2R^2/9$，已有 $A_0,A_1$ 时，可以取
$$
 A_2={A_1+\kappa^2A_0/4\over q_{\min}},
$$
或用直接包络取得更小的值。所有包络只需覆盖实际使用的波数与参数域；它们可由相同分离尺度的多个源簇/目标共用。

若需目标盒统一证书，可取 $R_{\min}\le|x-c|\le R_{\max}$ 且 $R_{\min}>3a$，使用统一 $s=R_{\min}/(3a)$。复域是
$$
 \bigcup_{R\in[R_{\min},R_{\max}]}\mathcal D_R,
$$
而 $M_1,M_2$ 中可保守地以 $R_{\max}$ 替代 $R$。这些选择对每个目标仍满足上述证明；复杂参数区域可用有限区间覆盖包络。

这个固定 $s$ 的选择未必高效：复 Hankel 函数包络可能随 $R$ 显著增大。也可任选
$$
 1<s<\frac{(\sqrt2-1)R}{a},\qquad b=sa,
$$
将盘半径改为 $2Rb+b^2<R^2$，取
$$
 M_1=2(R+b)A_1,\qquad M_2=4(R+b)^2A_2+2A_1.
$$
同一证明成立，可优化 $s$ 或细分源簇以减小 $M_r\zeta_p$。这只是可验证的优化变量，尚无本算例耗时收益结论。

#### 多个源共享的 Cartesian moments

沿 $t$ 展开的第 $n$ 阶系数等于空间 Taylor 展开中总次数为 $n$ 的项。设多指标 $\alpha=(\alpha_1,\alpha_2)$、$\alpha!=\alpha_1!\alpha_2!$，定义
$$
 m_\alpha=\sum_j\omega_j\frac{v_j^\alpha}{\alpha!},\qquad
 d_{\alpha,r}=\sum_j\tau_j(\nu_j)_r\frac{v_j^\alpha}{\alpha!},
 \quad r=1,2,\quad|\alpha|\le p.
$$
则
$$
 V_p(x)=\sum_{|\alpha|\le p}\left[
     m_\alpha\partial_y^\alpha G_\kappa(x,c)
   +\sum_{r=1}^2d_{\alpha,r}\partial_y^{\alpha+e_r}G_\kappa(x,c)
                               \right].
\tag{F7}
$$
共 $(p+1)(p+2)/2=O(p^2)$ 个单层 moments，以及两组同样数量的双层 moments；它们对所有目标共用。每个已接受源簇对一个目标的多项式收缩有 $O(p^2)$ 项；所需核 jets 的生成成本须另计，不能仅凭项数承诺完整 FMM 复杂度。

子簇 moments 向父簇平移也可用**有限代数恒等式**完成。若中心差为 $d=c_{\rm child}-c_{\rm parent}$，则
$$
 m^{\rm parent}_\alpha
 =\sum_{\rm child}\sum_{\beta\le\alpha}
     \frac{d^{\alpha-\beta}}{(\alpha-\beta)!}\,m^{\rm child}_\beta,
\tag{F8}
$$
偶极 moments 同理。由于只计算次数不超过 $p$ 的 moments，(F8) 不需要更高阶 moments，亦不引入截断误差；浮点求和误差另行处理。

一个直接可认证的树方法是：在每个目标处遍历源树；满足分离条件且 (F3)–(F4) 满足分配预算的源簇使用 (F7)，其余继续细分，叶子上的近作用直接评价。每个源对某个目标恰好归入一次；逐个已接受源簇的误差相加，得到这个目标的整体绝对误差。于是同一残差上的多胞元场、多个波数、近邻像和代理源的误差也能逐项相加，放入 (Q1) 的 $e_q$。本定理只证明实目标的值与一阶梯度误差；要用于 (Q4) 的高阶 Taylor 系数，还须另证目标复邻域中的统一加速误差（再用 Cauchy 估计），或逐阶证明导数误差。没有这个附加证书时，高阶系数应使用直接核/连续层势求积认证，不能由 (F4) 推出。若多个项本来具有解析相消，还可对合并后的核/源强建立同一类包络以减小常数。

该方法仅需要源 moments 和在实际目标处评价 moments，不必引入 multipole-to-local 或 local-to-local 展开。若现有库使用这些额外平移、近远场切换或其他展开，每一项都必须另有截断证明，才能使用其原输出；(F3)–(F4) 不会自动覆盖那些不同算法。也可以只对主导残差面板使用此方法或直接求和认证，其余保留已有浮点诊断。

**适用边界。** 本定理只包住给定有限源和的加速误差。自相互作用的奇异节点、Kress 权重、内层求积误差、系数及几何求值误差仍须分别认证。树的存储与浮点 FMM 可采用同量级的数据结构，但仅凭本定理不能保证 40 分钟或 3 GiB，更不能保证现有库的容差已满足 $10^{-12}$ 级残差所需的绝对精度。


### T3.5 特殊函数区间接口的最低要求

Arb 或等价库需要提供以下能力，选用哪个库本身不是数学证明：

- 对输入实/复球给出包含精确 $J_\nu,Y_\nu,H_\nu^{(1)}$ 的输出球，支持实际参数范围及所选分支；
- 包住平方根、指数、三角函数、$\log$ 和 $\pi,\gamma$ 等常数；
- 包住导数或 Taylor jets。可使用 $H_0'=-H_1$、$H_\nu'=(H_{\nu-1}-H_{\nu+1})/2$ 等精确关系，但递推中的舍入也应计入；
- 对自相互作用使用已经去掉奇性的 (Q3) 及解析除差，不能直接给包含 $q=0$ 的区间调用裸 Hankel 函数；
- 若输入球碰到分支切线、无法包住函数、返回不定球，则必须细分或提高精度，不能继续把该值当作有限上界。

不要求每个节点都用区间特殊函数。可以对共享的复参数区域计算函数/导数包络，浮点节点值的特殊函数误差另由已验证的近似算法界提供；如果现有双精度库没有这样的保证，该部分只能列为尚未认证的函数求值误差；要声称截断意义下可靠，仍需补上其算法近似误差界，或只对认证所需的少数 Taylor 中心和质量点切换到区间库。不能把未知的函数近似截断统称为舍入。

### T3.6 一个背景圆盘上的场范数下界

**定理 T3.6（已证明）。** 设闭圆盘 $\overline{D_R(c)}$ 包含在一个密度为常数 $\rho_b>0$ 的均匀分片内部，场在其邻域满足 $(\Delta+\kappa_b^2)\widehat u=0$，$\kappa_b=\sqrt{\mu\rho_b}>0$。若某次可靠点评价给出
$$
 |\widehat u(c)-\widetilde u(c)|\le e_c,\qquad
 a_c=\max\{0,|\widetilde u(c)|-e_c\},
$$
则
$$
 \boxed{ U^2\ge
 \rho_b\pi R^2\bigl[J_0(\kappa_bR)^2+J_1(\kappa_bR)^2\bigr]a_c^2 . }
\tag{Q5}
$$
右侧 Bessel 组合使用可靠下界；中心点模长下界也应可靠。

**证明。** 圆周均值 $m(r)=(2\pi)^{-1}\int_0^{2\pi}\widehat u(c+r e^{i\theta})d\theta$ 满足径向 Helmholtz 方程且 $m(0)=\widehat u(c)$，故 $m(r)=J_0(\kappa_b r)\widehat u(c)$。由 Cauchy–Schwarz，圆周上的平方积分至少是 $2\pi|m(r)|^2$。乘以 $r\rho_b$ 积分并使用
$$
 \int_0^R J_0(\kappa_b r)^2r\,dr
 ={R^2\over2}\bigl[J_0(\kappa_bR)^2+J_1(\kappa_bR)^2\bigr]
$$
即得结论。证毕。

这只需一个离界面点评价和两个 Bessel 值，无须二维体求积。可对若干互不相交的圆盘把 (Q5) 右侧相加。圆盘相交时不能直接相加；若覆盖重数至多 $m$，除以 $m$ 后才是通用可靠下界。可先用便宜浮点扫描选取场较大的点，再只认证选中的圆盘，这不影响证明。

若单点法过弱，可用正则 Fourier–Bessel 展开
$$
 \widehat u(c+r e^{i\theta})=\sum_{m\in\mathbb Z}a_mJ_{|m|}(\kappa_b r)e^{im\theta},
 \qquad W_m(R)=\int_0^R J_{|m|}(\kappa_b r)^2r\,dr.
$$
对任何有限指标集 $S$，
$$
 U^2\ge2\pi\rho_b\sum_{m\in S}\underline{|a_m|}^{\,2}\,\underline W_m(R).
\tag{Q6}
$$
若在半径 $r_0<R$ 的圆周取得可靠 Fourier 系数 $b_m=a_mJ_{|m|}(\kappa_b r_0)$，且分母被证明非零，可由区间除法认证 $a_m$。否则跳过该模式或换半径。圆周 Fourier 系数的有限采样误差仍须用 T3.1 型解析混叠界；不能把 DFT 系数当成精确 Fourier 系数。正项余和直接舍弃，因此这里无需估计无限高阶系数。

### T3.7 接合墙数值下降约 60% 的一种解释

这目前只能是假设，不能据两组数确定原因。若两侧法向场各为 $O(1)$ 或更小的常规量，而真实差仅 $10^{-12}$，旧评价网格的内层近奇异求积/FMM 截断偏差可能与真实跳跃同阶。目标与源的相对网格变化也会改变混叠的相位；若把非周期墙段强行作周期梯形/Fourier 评价，还会出现端点缺陷混叠。因此从 $768$ 到 $1536$ 点的墙跳跃平方下降约 60%，可以由**评价误差污染旧残差**解释，而不是物理场变好了。材料跳跃稳定、墙跳跃不稳定，与这个解释相容，但不足以证明它。

(Q1) 和 (Q4) 对同一个固定场给出包含内外层误差的单侧界。它们不会把两次评价的差当成误差证书：若第一次内层误差大，第一次上界会变宽；若增加节点后误差界下降，则新上界可以相应收紧。应把 $N_{\rm inner}$、$N_{\rm outer}$、FMM 精度和墙段端点处理分别改变，定位来源后再决定认证资源的投向。



## T3.8 引线传播尾与全局残差的组合

### 定理 T3.8（核对并扩展 boundary-propagation-tail）

**状态：已证明；草稿 (5.25) 在所列条件下正确。** 对 $s\in\{-,+\}$，把参考胞元的材料跳跃、它远离中心的一面竖墙跳跃、该胞元的水平接缝跳跃组成一个加权 Hilbert 空间 $Y_s$，定义线性映射

$$\mathsf L_s:\mathbb C^K\to Y_s,\qquad b_s(v)=\|\mathsf L_sv\|_{Y_s}^2.$$

墙跳跃比较 $u_s[v]$ 与下一胞元的平移场 $u_s[\mathsf P_sv]$；接缝跳跃按 T2.3 定义。若分组使用不同 $\ell_g$，可为各组分别建立相同的映射和尾界。令 $b_0$ 包含中心材料界面、两面接合墙和中心胞元水平接缝。则

$$\varepsilon_{\rm new}^2=b_0+\sum_{s=\pm}\sum_{j=0}^\infty b_s(\mathsf P_s^jc_s). \tag{PT1}$$

这里每面共享竖墙只归属于更靠近中心的那个胞元，每段上下边界只合成一次接缝。设

$$\Theta_s=\sum_{a=1}^K b_s(e_a),\qquad
\|\mathsf P_s^{p_s}\|_2\le r_s<1.$$

则 $b_s(v)\le\Theta_s\|v\|_2^2$，且对任意 $N\ge0$，

$$\boxed{\sum_{j=N}^\infty b_s(\mathsf P_s^jc_s)
\le \frac{\Theta_s}{1-r_s^2}
\left(\sum_{\ell=0}^{p_s-1}\|\mathsf P_s^\ell\|_2^2\right)
\|\mathsf P_s^Nc_s\|_2^2.}\tag{PT2}$$

**证明。** $\Theta_s=\|\mathsf L_s\|_{\rm HS}^2\ge\|\mathsf L_s\|^2$。写 $j=N+ip_s+\ell$，其中 $0\le\ell<p_s$，有

$$\|\mathsf P_s^jc_s\|_2\le
\|\mathsf P_s^\ell\|_2r_s^i\|\mathsf P_s^Nc_s\|_2.$$

平方后求几何级数即得。$\square$

数值使用时应将 $\Theta_s,r_s,\|\mathsf P_s^\ell\|_2$ 和尾状态范数都换成上界。矩阵谱半径小于一的浮点结果不是 $r_s$ 的证书；也不能忽略非正规暂态增长。允许先用浮点找到一个合适的 $p_s$，再认证该次矩阵幂的范数。由 Frobenius 范数或 $\sqrt{\|X\|_1\|X\|_\infty}$ 取得上界最简单；太保守时，认证近似最大奇异值或验证 $r_s^2I-X^*X\succeq0$。

这里的 $\mathsf P_s$ 是所定义场使用的矩阵，不必证明它恰好等于连续传播算子；后者的误差已经表现为相邻胞元的跳跃。但必须认证这个矩阵的衰减性。加入接缝后原来的 $\Theta_s$ 不再包含全部缺陷，须增加接缝项或为接缝另建 $\Theta_{\Sigma,s}$。

### 定理 T3.9（保留方向信息的 Lyapunov 尾界）

**状态：已证明；可选加速/收紧。** 省略引线下标。令 $G=\mathsf L^*\mathsf L$，且已证明 $G\preceq H$。若 Hermitian 矩阵 $S$ 满足

$$S\succeq0,\qquad S-\mathsf P^*S\mathsf P\succeq H,$$

则对 $w=\mathsf P^Nc$，

$$\boxed{\sum_{j=N}^\infty b(\mathsf P^jc)\le w^*Sw.}\tag{PT3}$$

**证明。** 对任意有限 $n$，把 Lyapunov 不等式左乘 $(\mathsf P^*)^j$、右乘 $\mathsf P^j$ 后求和，得

$$\sum_{j=0}^{n-1}w^*(\mathsf P^*)^jG\mathsf P^jw
\le w^*(S-(\mathsf P^*)^nS\mathsf P^n)w\le w^*Sw.$$

单调取极限即得。$\square$

可从浮点求出的 Hermitian $S_0$ 出发，认证

$$E=H-S_0+\mathsf P^*S_0\mathsf P\preceq eI,\qquad e\ge0.$$

若 $\|\mathsf P^p\|_2\le r<1$，则

$$D=\frac{\sum_{\ell=0}^{p-1}(\mathsf P^*)^\ell\mathsf P^\ell}{1-r^2},
\qquad S=S_0+eD \tag{PT4}$$

满足所需不等式，因为 $D-\mathsf P^*D\mathsf P\succeq I$。此外 $H\succeq G\succeq0$，迭代不等式并利用 $\mathsf P^n\to0$，自动得到 $S\succeq0$。$D$ 的浮点近似也须计入误差；不能把精确恒等式直接套到未经认证的近似矩阵上。

取 $H=\overline\Theta I$ 即可复用原来的标量证书，无需新增场评价。较紧的矩阵 $H$ 可由连续跳跃的多项式/傅里叶近似得到：若一个近似映射 $\widetilde{\mathsf L}$ 在同一个 Hilbert 空间满足 $\|\mathsf L-\widetilde{\mathsf L}\|\le\eta_L$，则任意 $t>0$ 给出

$$G\preceq(1+t)\widetilde{\mathsf L}^*\widetilde{\mathsf L}
+(1+t^{-1})\eta_L^2I. \tag{PT5}$$

证明是对每个向量使用三角不等式及加权平方不等式。构造 $\widetilde{\mathsf L}$ 时必须给出从离散系数到连续函数的明确重构与范数；不能把一个未经校正的采样 Gram 矩阵当作连续 $G$ 的上界。

### 定理 T3.10（最终可执行的证书组合）

**状态：在各输入证书成立时已证明。** 对界面组 $g$，由 T3.1/T3.3 得到显式胞元部分 $B_g$ 的上界，并由 (PT2) 或 (PT3) 得到两侧尾界 $T_{g,-},T_{g,+}$。令

$$\overline\varepsilon_g=
\sqrt{\overline B_g+\overline T_{g,-}+\overline T_{g,+}},\qquad
\overline Q=\sum_g\overline C_g\,\overline\varepsilon_g,$$

$$U_-^2=\sum_{D_j\ {
m 不交}}\underline{\mathcal M}_j,$$

其中 $\underline{\mathcal M}_j$ 是 (Q5) 或 (Q6) 的质量下界。若 $D:=U_--\overline Q>0$，则

$$\boxed{\overline R=\frac{2\mu\overline Q}{U_--\overline Q},\qquad
[\mu-\overline R,\mu+\overline R]\cap\sigma(A(\beta))\ne\varnothing.}\tag{PT6}$$

再验证 (T1.5)，即可把这个谱点解释为孤立有限重的导模特征值。全程不要求区间中仅有一个特征值。

如果 $\mu$ 的计算也用一个区间 $[\mu_-,\mu_+]$，应对迹常数等的整个参数范围取得上界，最终输出 $[\mu_--\overline R,\mu_++\overline R]$；其全宽还包括 $\mu_+-\mu_-$。更简单的是用已冻结的十进制或二进制 $\widehat k$ 精确定义 $\mu$，只对显示端点作向外舍入。

### 舍入估计如何单列

在完全严格模式，所有最终输入都包含舍入，(PT6) 就是严格谱包含。若采用题目允许的模式，应同时输出：

1. 对指定精确算术评价算法证明的 $\overline Q_{\rm tr},U_{-,\rm tr},R_{\rm tr}$；
2. 浮点执行的绝对误差**估计** $e_{Q,\rm fp},e_{U,\rm fp}$，以及把它们代入后产生的区间变化估计；
3. 对严重相消的材料跳跃、墙法向跳跃和 MFS 修正分别记录放大因子。

例如有限和 $s=\sum a_j$ 的标准舍入模型给出 $|\operatorname{fl}(s)-s|\le\gamma_n\sum|a_j|$，$\gamma_n=nu/(1-nu)$；复数乘加应按实际实运算数增加计数，特殊函数和矩阵乘法另计。这里只给出建模形式，不能从机器精度 $u$ 一项就认定误差是 $O(u)$：代理源大系数和大场相减会使 $\sum|a_j|/|s|$ 很大。若没有实际累加量和算法信息，该舍入项只能保持“尚未估计”，不能填入猜测数字。

把估计加到半径上也不会自动把它变成严格区间。最便宜的完整严格化通常是对少数 Taylor 系数、几何和解析包络、$97\times97$ 的矩阵证书及质量点使用球算术，其余共享浮点运算配有解析误差界。


## T4 收紧迹常数

### T4.1 一维迹不等式的最优能量常数

**状态：已证明。** 设 $a>0$、$\delta>0$，$g\in H^1(-\delta,\delta)$，则

$$
|g(0)|^2\le K(a,\delta)\int_{-\delta}^{\delta}(|g'|^2+a^2|g|^2)\,dt,
\qquad K(a,\delta)=\frac{\coth(a\delta)}{2a}.
\tag{T4.1}
$$

对固定的 $a,\delta$，常数 $K$ 最优。证明：在约束 $g(0)=1$ 下最小化右端能量。唯一极小函数为

$$h(t)=\frac{\cosh(a(\delta-|t|))}{\cosh(a\delta)},$$

它在两半区间满足 $-h''+a^2h=0$、$h'(\pm\delta)=0$，能量为 $2a\tanh(a\delta)$。对任意 $g=g(0)h+w$、$w(0)=0$，分部积分使能量交叉项为零，遂得结论。

沿草稿法线使用 (T4.1)，若领子单射、$|\kappa|\le\kappa_*$、$\vartheta=1-\delta\kappa_*>0$、重数至多 $N$，可替换为

$$D_0=\frac{N}{\vartheta}\frac{a\coth(a\delta)}2,
\qquad D_1=\frac{N}{\vartheta}\frac{\coth(a\delta)}{2a}.$$

然后直接以 $(D_0,D_1)$ 替换草稿 $(C_0,C_1)$。参数 $a$ 是任意的可计算优化变量；不需要证明数值优化器找到了真正最小值，任何已验证参数都产生一个有效上界。

### T4.2 保留 Jacobian 的更强迹界

**状态：已证明；这是建议首先实现的改动。** 仍假设每条曲线法向领子单射，半宽统一为 $\delta$，$|\kappa|\le\kappa_*$、$h_*:=\delta\kappa_*<1$，覆盖重数至多 $N$。定义

$$
\tau(\delta,\kappa_*):=
\frac\delta6+\frac{\delta h_*^2}{40(1-h_*^2)}.
\tag{T4.2}
$$

对任何 $\eta>0$，令

$$
D_0:=\frac{N(1+\eta)}{2\delta},\qquad
D_1:=N(1+\eta^{-1})\tau(\delta,\kappa_*).
\tag{T4.3}
$$

则对 $v\in H^2_\beta(B)$，

$$
\sum_\Gamma\|v\|_{L^2(\Gamma)}^2
\le D_0\|v\|_{L^2(B)}^2+D_1\|\nabla v\|_{L^2(B)}^2,
\tag{T4.4}
$$

$$
\sum_\Gamma\|\partial_{\nu_\Gamma}v\|_{L^2(\Gamma)}^2
\le D_0\|\nabla v\|_{L^2(B)}^2+D_1\|D^2v\|_{L^2(B)}^2.
\tag{T4.5}
$$

此处 $D_0$ 没有粗糙换元产生的 $\vartheta^{-1}$。

**证明。** 固定一条法线，记 $w(t)=1-\kappa t$，其积分恒为 $2\delta$。设

$$
F=\frac1{2\delta}\int_{-\delta}^{\delta}w(t)g(t)\,dt.
$$

从 $g(t)-g(0)=\int_0^tg'(s)\,ds$ 换序积分，得 $g(0)=F+\int K_\kappa(t)g'(t)\,dt$，其中 $K_\kappa$ 在正、负半区间的符号相反，其绝对值为

$$
|K_\kappa(t)|=\begin{cases}
\displaystyle\frac{\delta-t-\kappa(\delta^2-t^2)/2}{2\delta},&0<t<\delta,\\
\displaystyle\frac{\delta+t-\kappa(t^2-\delta^2)/2}{2\delta},&-\delta<t<0.
\end{cases}
$$

加权 Cauchy–Schwarz 给出

$$
|g(0)|\le\frac1{\sqrt{2\delta}}\left(\int w|g|^2\right)^{1/2}
+\sqrt{T_\kappa}\left(\int w|g'|^2\right)^{1/2},
\quad
T_\kappa=\int_{-\delta}^{\delta}\frac{|K_\kappa(t)|^2}{w(t)}\,dt.
$$

令 $h=\kappa\delta$，正负半区间相加后直接化简得

$$
T_\kappa=\frac\delta6+
\frac{\delta h^2}8\int_0^1\frac{(1-x)^4}{1-h^2x^2}\,dx
\le\frac\delta6+\frac{\delta h_*^2}{40(1-h_*^2)}=\tau.
$$

利用 $(a+b)^2\le(1+\eta)a^2+(1+\eta^{-1})b^2$，再对弧长积分。此时 $w(t)\,ds\,dt$ 正是面积元，完全不需要以 $\vartheta^{-1}$ 粗略控制。求和只需乘以覆盖重数 $N$。分别取 $g=v(\Phi(s,t))$ 与 $g=\nu(s)\cdot\nabla v(\Phi(s,t))$；后一情形 $g'=\nu(s)^TD^2v\nu(s)$，故 $|g'|\le|D^2v|_F$，得到 (T4.4)–(T4.5)。证毕。

若愿意做一次一维可靠积分，可用精确的 $T_{\kappa_*}$ 代替 $\tau$；上述积分表达式还证明 $T_\kappa$ 随 $|\kappa|$ 单调递增。但在当前参数下两者差别极小，没必要增加实现复杂度。

### T4.3 联合谱乘子，避免三个独立上确界相加

**状态：已证明。** 对任何满足 (T4.4)–(T4.5) 的 $D_0,D_1$，定义

$$
p(\lambda)=a+b\lambda+c\lambda^2,
\quad a=\frac{D_0}{\rho_{\min}},\quad
b=D_1+\ell_*^2D_0,\quad c=\ell_*^2D_1\rho_{\max}.
\tag{T4.6}
$$

则命题 5.1 的常数可以取

$$
C_{\rm joint}^2=
\sup_{\lambda\ge\lambda_0}\frac{p(\lambda)}{(\lambda+\mu)^2},
\quad
\lambda_0:=\frac{\operatorname{dist}(\beta,2\pi\mathbb Z/d)^2}{\rho_{\max}}.
\tag{T4.7}
$$

取 $\lambda_0=0$ 也有效。证明：将体范数界统一写为谱测度积分，得到

$$
T_{\ell_*}(v)^2\le
\frac{D_0}{\rho_{\min}}\|v\|_{\mathcal H}^2
+(D_1+\ell_*^2D_0)(Av,v)_{\mathcal H}
+\ell_*^2D_1\rho_{\max}\|Av\|_{\mathcal H}^2
=\int p(\lambda)\,d\|E_\lambda v\|_{\mathcal H}^2.
$$

$\lambda_0$ 来自 $y$ 方向 Fourier–Poincaré 不等式及 $\rho\le\rho_{\max}$。除以正移位谱乘子即得结论。

这个上确界无需扫描：检查 $\lambda=\lambda_0$、极限 $\lambda=\infty$（值为 $c$），以及当存在且 $\lambda_*\ge\lambda_0$ 时的唯一驻点

$$\lambda_*=\frac{2a-b\mu}{2c\mu-b}.$$

分母为零时导数没有独立驻点，直接检查端点即可；恒等于常数的情形也包括在端点检查内。用向外舍入计算这些有限个数即得到可靠 $\overline C$。

#### 当前参数的条件性数值

下表仅代入 $\kappa_*=64$、$N=1$、$\rho_{\min}=1$、$\rho_{\max}=17$、$\delta=.004$、$\ell_*=1$、$\mu=1.5584378941820909^2\approx2.428728670022710$。题目只给了近似曲率，没有 Fourier 几何数据和领子证书，故数值是**条件性估计，尚不是实际算例的可靠常数**。

| 方法 | 参数 | $C$ 估计 |
|---|---|---:|
| 草稿原式 (5.14) | $C_0=336.0215054,C_1=.0026881720$ | $9.570753$ |
| 保留原一维界，仅用联合谱乘子 | 驻点约 $.4290281$ | $7.668016$ |
| 最优一维能量界 + 原来三个分别取 supremum | $a\approx58.68$ | $6.889415$ |
| 最优一维能量界 + 联合谱乘子 | $a\approx27.43$ | $5.442787$ |
| 保留 Jacobian 的 (T4.2)–(T4.7) | 直接选可复现的 $\eta=.004$ | $4.694806$ |

最后一行的 $\tau\approx0.000673679885$、$D_0=125.5$、$D_1\approx0.1690936511$。它使用与原稿完全相同的领子半宽，不依赖扩大领子的额外几何假设。增加 $D_1$ 是允许的；关键是联合谱乘子避免让高频 Hessian 极值与低频值迹极值同时以最坏情形相加。

按题目 $\varepsilon=2.05\times10^{-12}$、$U=.1234$ 计算，最后一行给出的谱距离约 $3.79\times10^{-10}$、全宽约 $7.58\times10^{-10}$。这些仍只是条件性估计，尚未计入求积证书、MFS 接缝和 FMM 误差。它表明修紧迹常数本身可以腾出约两倍的误差预算；不是已经完成的可靠区间。

### T4.4 直接利用 $z=(A-\mu)^{-1}\widehat u$ 的进一步改进

**状态：已证明；可选，不必替换主稿的谱距离定理。** 设 $p$ 如 (T4.6)，并且该多项式迹界覆盖 Green 恒等式中的**全部界面**。令 $E\ge\varepsilon$、$0<U_-\le U$：原精确准周期场取 $\varepsilon=\varepsilon_{\partial,\ell_*}$；本报告 MFS 场必须取 $\varepsilon=\varepsilon_{{\rm new},\ell_*}$，把接缝包含在同一迹界和同一残差中。记 $P=p(\mu)$、$B=p'(\mu)=b+2c\mu$，并假设 $U_-^2>cE^2$。则

$$
\operatorname{dist}(\mu,\sigma(A))\le
R_{\rm pol}:=
\frac{E^2B+\sqrt{E^4B^2+4E^2P(U_-^2-cE^2)}}{2(U_-^2-cE^2)}.
\tag{T4.8}
$$

证明：若 $\delta=\operatorname{dist}(\mu,\sigma(A))>0$，由 Green 恒等式、(T4.6) 与谱定理，

$$
U^2\le\varepsilon T_{\ell_*}(z),\qquad
T_{\ell_*}(z)^2
\le\int\frac{p(\lambda)}{(\lambda-\mu)^2}\,d\|E_\lambda\widehat u\|^2
\le\left(\frac P{\delta^2}+\frac B\delta+c\right)U^2.
$$

最后一步使用 $p(\lambda)=P+B(\lambda-\mu)+c(\lambda-\mu)^2$ 与 $B\ge0$。整理为

$$(U_-^2-cE^2)\delta^2-E^2B\delta-E^2P\le0,$$

取正根得到结论。它仍然不需要谱隔离、计数或先验带隙。

对 (T4.3) 可直接为 $P$ 选取参数

$$
\eta=\sqrt{\frac{\tau(\mu+\ell_*^2\rho_{\max}\mu^2)}{(2\delta)^{-1}(\rho_{\min}^{-1}+\ell_*^2\mu)}}.
$$

该公式精确最小化 $P$（不声称精确最小化整个 $R_{\rm pol}$）。上述条件性参数下 $\eta\approx.01270590$、$\sqrt P\approx20.96548$，得到 $R_{\rm pol}\approx3.48\times10^{-10}$、全宽约 $6.97\times10^{-10}$。

### T4.5 分组、接缝和变量领子

**状态：在实际领子证书成立时已证明。** 可按中心材料曲线、左/右材料曲线、人工竖直墙、水平准周期接缝划分界面组 $\mathscr E_g$。每组自己选择 $\delta_g,\kappa_g,N_g,\ell_g$，计算 $C_g$ 及

$$
\varepsilon_g^2=\sum_{\Gamma\in\mathscr E_g}
\big(\|J_{\nu,\Gamma}\|^2+\ell_g^{-2}\|J_{0,\Gamma}\|^2\big).
$$

则原谱距离定理仍成立，只需取

$$Q_{\rm grp}=\sum_g C_g\varepsilon_g.$$

证明是分别对每组使用 Cauchy–Schwarz 后相加。**不同组之间即使领子重叠，也不需要在每个 $C_g$ 再加入跨组重数。** 因为各组本来就是分别用同一个全局体范数控制，然后在 $Q_{\rm grp}$ 中相加。

特别地，水平接缝在准周期圆柱上是一条无界直线；取 $0<\delta_\Sigma<d/2$，单独作为一组，有 $\kappa_\Sigma=0,N_\Sigma=1$。辅助场 $z$ 精确准周期、全局 $H^2$，所以其接缝领子可跨越材料界面；不需要把 $\delta_\Sigma$ 限制到星形曲线的曲率尺度。竖直墙与接缝相交不产生额外点源，交点是界面积分的零测集；若把所有组揉成单一联合领子，覆盖重数一般从 1 变 2，但上面的分组公式可避免这种全局损失。

人工竖直墙也可以单独取宽领子：相邻墙间隔为 $1$ 时，$\delta_{\rm art}=.2$ 的同组领子互不相交。以 $\kappa=0,\delta=.2$ 代入 (T4.2)–(T4.7)，直接取 $\eta=7/6$，得到 $D_0=65/12$、$D_1=13/210$，以及 $C_{\rm art}\approx1.03555281$；接缝组取同样半宽亦有相同估计。这比将所有墙都绑在 $\delta=.004$ 的最坏星形曲率上便宜得多。具体几何仍须验证墙的真实间隔。

曲线也可按弧长分段。每段设半宽 $\delta_g$ 和曲率上界，法向映射在相应变宽区域内单射并有可计算重数即可。证明不对 $s$ 求导，因此不需要对 $\delta(s)$ 求导，也没有分段端点的附加边界项。最省事的实现是有限分段，每段各计算 $C_g\varepsilon_g$，随后相加。仅知道最大曲率不足以验证全局单射，依然需要检查非局部法线碰撞和周期副本。

### T4.6 $\ell_*$ 的解析优化

用原稿的分离上界或任何固定 $D_0,D_1$，设

$$A_0=\frac{D_0}{\rho_{\min}\mu^2}+\frac{D_1}{4\mu},\qquad
B_0=\frac{D_0}{4\mu}+D_1\rho_{\max},$$

$$N=\sum\|J_\nu\|^2,\qquad V=\sum\|J_0\|^2.$$

则 $Q^2=(A_0+B_0\ell_*^2)(N+V/\ell_*^2)$，当 $N,V>0$ 时其最优值为

$$
\ell_*^{\rm opt}=\left(\frac{A_0V}{B_0N}\right)^{1/4},
\qquad Q_{\min}=\sqrt{A_0N}+\sqrt{B_0V}.
$$

零残差分量用相应极限处理。这里必须优化乘积 $C\varepsilon$，不能只优化 $C$；$\ell_*$ 变化同时改变跳跃范数。若用更紧的联合谱乘子，直接对 $t=\ell_*^2>0$ 做一维验证优化即可，固定 $D_0,D_1$ 时，$Q^2$ 关于 $\log t$ 是凸函数的上确界，因而为凸函数；选择任何验证参数已经足够，不要求全局最优证书。


### T4.7 一个由 Fourier 几何数据验证领子单射的充分程序

**状态：以下充分判据已证明。** 对单条曲线用原周期参数写

$$\Phi(t,n)=r(t)+n\nu(t),\qquad t\in\mathbb R/\mathbb Z,\quad |n|\le\delta.$$

选取 $h>0$ 及有限个展开参数区间 $I_j$，使周期距离小于 $h$ 的任意参数对都位于某个同一 $I_j$。例如可用相互重叠、长度大于 $2h$ 的有限区间覆盖，并明确检查这个覆盖性质。

对每个矩形 $I_j\times[-\delta,\delta]$，取一个已知可逆实矩阵 $B_j$，并验证

$$\sup_{(t,n)\in I_j\times[-\delta,\delta]}
\|I-B_j^{-1}D\Phi(t,n)\|_2\le q_j<1.\tag{G1}$$

同时对周期参数距离至少 $h$ 的所有 $(t,s)$ 验证

$$\|r(t)-r(s)\|>2\delta.\tag{G2}$$

则 $\Phi$ 在整个周期参数领子上单射。证明：近参数对落在同一凸矩形，对连接两参数点的直线积分导数，可得

$$\|B_j^{-1}(\Phi(z)-\Phi(z'))\|\ge(1-q_j)\|z-z'\|,$$

所以其像不相等；远参数对由三角不等式得到
$\|\Phi(t,n)-\Phi(s,m)\|\ge\|r(t)-r(s)\|-|n|-|m|>0$。证毕。

$D\Phi$ 由 $r',\nu,\nu'$ 明确给出，所有量可用 Fourier 导数包络和实区间细分计算；(G2) 是一个紧的二维参数集合上的距离下界验证。对于周期副本以及不同界面，还需验证对应的距离大于两个半宽之和。这个判据只是便于实现的充分条件：验证失败不说明领子一定自交，可缩小参数区间、调整 $h$，或直接细分验证法向像的分离。没有实际 Fourier 数据时，本报告不声称 (G1)–(G2) 已通过。

### 实现成本

这些改进只需可靠几何数据及标量算术。$\tau,D_0,D_1$ 和谱有理函数有限点最大值的代价可忽略；不会增加 FMM 调用次数。分组需要保存每类跳跃积分，而当前实现本来已经在统计误差来源，通常只增加常数级累加。变量领子的主要新增成本是几何证书，而不是场评价；应先实现同半宽的 (T4.2) 与 (T4.7)，再考虑扩大或分段领子。


## T5 可靠评价的加速和实施顺序

### 可以直接节约评价成本的改动

| 办法 | 省掉的工作 | 仍须证明或验证的事项 |
|---|---|---|
| 三个参考胞元的核与几何复用 | 避免对 40 个平移胞元反复构造相同相互作用 | 所用状态到场/跳跃的映射确实固定且线性；左右参考胞元分别处理 |
| 将 MFS 校正先组合成有限代理系数 | 避免每个目标重新积分源依赖 MFS 核或再解最小二乘 | 明确冻结后的场定义；连续近邻层势仍用 T3 求积界 |
| 候选状态与基向量分块多右端评价 | 共用核、面板、几何包络，一次处理多个传播状态或 $\Theta$ 的基向量 | 每个右端的误差按实际系数或已证算子范数传播，不能共用一个未经缩放的残差容差 |
| 先评价主导残差的组合 Taylor 系数 | 降低每个原始大场分别作区间积分造成的包络膨胀 | 组合后的系数和余项须有 T3.3 的证明；相消只能发生在计算出的系数中，不能凭直觉抵销误差半径 |
| 材料曲线用周期积分，墙和接缝用独立面板 | 避免非周期端点的缓慢 Fourier 尾 | 材料曲线的复条带证书；墙/接缝面板的解析圆盘与余项 |
| 可靠源簇 Taylor 树或经审计 FMM | 避免全部远相互作用逐点求和 | 本报告源簇定理或实际 FMM 的每类展开/平移尾界；不能只读取库的 `tol` |
| 采用 Lyapunov 尾界 | 避免将全部方向压到同一个最坏传播范数；可能减少显式胞元数 | (PT3)–(PT4) 的矩阵残余与严格稳定性，及 $G\preceq H$ |
| 背景圆盘质量下界 | 避免二维高精度体积分 | 圆盘完全位于均匀分片；中心点评价下界；多圆盘不重叠或已知覆盖重数 |
| 分组、较好的迹常数 | 在同一目标区间宽度下允许更宽松的跳跃评价误差 | 各组领子几何与覆盖重数；T4 的显式标量计算 |
| 按证书余项分配精度 | 避免对已远低于预算的部分继续加密 | 已有余项上界；停止条件使用 (B0)，不使用“出现平台” |

**关于 $\beta$ 扫描的复用。** 几何 Fourier 系数、曲线分离证书、源树结构和参考核分块可以跨参数复用。$\mathsf P_\pm,\Theta_\pm,r_\pm$ 通常同时依赖 $\beta$ 与 $k$，不能直接把一个参数点的可靠证书照搬到另一个点。只有在同一 $(\beta,k)$ 下改变中心缺陷或中心候选系数时，引线量才可原样复用；跨参数需要统一参数区间的矩阵/核包络，或者重新验证小矩阵和相应误差界。近似解可作热启动，但热启动不是证书。冻结一个旧传播矩阵也能定义新参数下的分片场，不过必须重新评价它的全部跳跃，不能复用旧 $\varepsilon$。

### 一个可执行的实施顺序

1. **锁定场和接口。** 导出 $\widehat k,\beta$、三个几何 Fourier 表、连续密度系数、背景波、代理位置及修正系数、$\mathsf P_\pm,c_\pm$，确保评价加密不会改变这些定义参数。先把完整接缝加入跳跃评价。
2. **先做低成本的几何和质量证书。** 验证领子及 T4 的 $C_g$；挑选并认证若干背景圆盘。立即用 (B0) 算出允许的总 $Q$。若质量下界很弱，先增加圆盘或有限 Bessel 模态，不急着把残差压到更低。
3. **检查接缝预算。** 先得接缝的浮点诊断及有证明的粗包络；如果接缝本身已用尽预算，应改善 MFS 场表示或改走精确核路线。不能靠加密外层求积消除场本身的接缝失配。
4. **认证中心材料和两面接合墙。** 这三处主导当前法向残差。采用 T3.1/T3.2 或组合 Taylor 面板；分别记录内层、外层、特殊函数、加速展开的误差份额。先把内层和外层节点数解耦，避免再次混淆墙上 60% 的变化来源。
5. **认证参考引线和传播尾。** 一次求出可靠的 $\Theta_\pm$ 或矩阵 $H_\pm$、$r_\pm$，随后批量处理状态。$N_{\rm cell}=40$ 是初始选择，停止条件应是 (PT2)/(PT3) 小于剩余预算。
6. **组合并停止。** 计算 $\overline Q,U_-,\overline R$，达到 (B0) 即停止无必要加密。检查两条引线的公共带隙证书，输出端点、输入证书摘要及单列舍入估计。

如果只有时间上限而证书在该时刻还未满足，合法输出是已得到的较宽可靠区间或“证书尚未闭合”，不能把未认证部分替换成加密差后宣称达到目标。

### 成本的可推算部分与尚不可推算的部分

令 $n_t$ 为目标节点/面板中心数，$n_s$ 为内层源节点数，$p_T$ 为 Taylor 阶数，$n_c$ 为显式胞元数，$K=97$。流式直接核评价是 $O(n_tn_s)$ 时间、$O(n_t+n_s)$ 临时存储；若缓存一个复双精度 $1536\times512$ 核矩阵，大小为 $12$ MiB，四个此类矩阵为 $48$ MiB。单个 $97\times97$ 复矩阵约 $0.144$ MiB。小矩阵的 $O(p_sK^3)$ 运算不是主要内存来源。

按参考几何缓存、以 8 或 16 个右端分块、逐面板生成区间/Taylor 数据，可避免同时保留所有胞元和所有高精度核，从数据结构上支持 3 GiB 以内的实现。**这不是对未知程序峰值内存的实测保证。** 大量高阶区间 jets 或未经分块的复几何二维包络仍可能消耗资源。

题中 54 秒、1.4 GiB 是已有浮点评价的一次实测，40 分钟相当于约 44 次这样的运行时间。这个比例说明存在优化空间，不能用于证明可靠版本的时间：解析包络细分、所需内层阶数、代理系数大小、最慢传播率、FMM 证书及带隙证书的首次构建成本均未知。特别是 $\Theta_\pm$ 若通过 $K$ 次完整独立评价求得，可能成为主要成本；应共享核或建立算子上界，避免机械地重复完整流程。

带隙证书可以对固定引线离线建立并复用；若“40 分钟”要求从零包含能带上下界，则必须把那部分费用也算入，不能默默移到预算外。本文提供了可靠化框架和停止准则，尚未证明当前候选能在给定资源内通过全部停止条件。

## 尚未闭合的数值事项

数学上，两引线、非精确准周期和逐片正则性均已有可用的证明；原谱距离定理不需要重做。实际认证仍要取得以下数据：真实几何与代理源的解析域证书、包含接缝的完整残差、所用评价路径的绝对误差界、传播收缩证书、足够大的质量下界，以及两侧全 Bloch 参数的共同带隙。

因此，当前可以成立的判断是：**存在一条不依赖谱隔离和模态计数、能复用大部分现有评价的可靠化路线；迹常数本身可以明显收紧。** 当前提供的数据还不能推出一条实际全宽 $\le5\times10^{-9}$ 的可靠区间，也不能证明 40 分钟内一定通过。报告中每个未闭合项都有对应的可计算量和停止条件，不以“继续加密直到平台”替代它们。

## 参考资料与核验范围

1. 用户附件 `main.pdf`，第 2 节、第 5.1–5.6 节，式 (2.10)、(5.12)–(5.30)。本报告核对其命题 5.1、定理 5.2 及两类尾项。
2. Sonia Fliss, *A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides*, SIAM Journal on Scientific Computing 35(2), B438–B461 (2013)。亲读项目附件 arXiv:1202.4928v2 的 Remark 2.1(2)、Propositions 3.1、3.3、Theorem 3.5。原文：[arXiv 1202.4928v2](https://arxiv.org/abs/1202.4928v2)；[DOI](https://doi.org/10.1137/12086697X)。
3. **[TW14]** Lloyd N. Trefethen and J. A. C. Weideman, *The Exponentially Convergent Trapezoidal Rule*, SIAM Review 56(3), 385–458 (2014)，Theorem 3.2。亲读原定理；(Q1) 同时给出本报告的独立 Fourier 证明。[作者 PDF](https://people.maths.ox.ac.uk/trefethen/publication/PDF/2014_149.pdf)。
4. **[DS20]** Joel Dahne and Bruno Salvy, *Computation of Tight Enclosures for Laplacian Eigenvalues*，2020 预印本，§2.1–2.2。亲读其先合并 Taylor 展开再作区间包络、以及局部范数下界的处理；不把其 Dirichlet 特解法定理直接套为本波导定理。[原文](https://arxiv.org/pdf/2003.08095)。
5. **[EGK13]** Charles L. Epstein, Leslie Greengard and Andreas Klöckner, *On the Convergence of Local Expansions of Layer Potentials*, SIAM Journal on Numerical Analysis 51(5), 2660–2679 (2013)，§2.3、§4。亲读二维 Helmholtz 和求积段落；原文保留的 $C_q(N,\Gamma)$ 不是本实现现成的显式证书。[原文](https://arxiv.org/pdf/1212.3868)。
6. Tilo Arens, Kai Sandfort, Susanne Schmitt and Armin Lechleiter, *Analysing Ewald’s Method for the Evaluation of Green’s Functions for Periodic Media*, IMA Journal of Applied Mathematics 78(3), 405–431 (2013)。亲读 KIT 版本的 Theorems 4.2–4.4、7.1–7.2 的适用范围；本报告仅将其作为精确准周期核路线的可选依据，不用其梯度界冒充混合二阶导数界。[KIT 原文](https://publikationen.bibliothek.kit.edu/1000019136/1396509)。
7. FLINT/Arb 官方复杂超几何函数接口。仅作为特殊函数实现接口参考，数学包络仍由实际返回球及所用算法保证。[官方文档](https://flintlib.org/doc/acb_hypgeom/index.html)。

Kress 乘积积分的 (Q2) 在本文直接从 log-sine Fourier 系数和混叠证明，未借用一个未核对定理号的渐近 $O(e^{-cN})$ 断言。其他新常数、接缝扩展、传播尾及圆盘下界也均给出了本报告的证明。

## 最终实现清单

下表中的“可靠”均要求所列常数真正经过证明或认证。符号 $\overline{\phantom{x}}$ 和 $\underline{\phantom{x}}$ 分别表示上、下界。

| 必须取得的量 | 怎样取得与用到的结论 | 大致成本/复用范围 |
|---|---|---|
| 精确定义的 $\widehat k,\mu,\beta,d,L_\pm,\rho$ | 固定输入及精确色散关系，T1、T2.1 | 常数成本；参数改变须重新核对 |
| 几何 Fourier 系数及可能的系数尾 | 精确有限和或带尾界的表示，T3.0 | 三个参考几何一次；不是从曲率估计反推 |
| 连续密度系数、背景波幅 | 草稿 (5.2)；评价时零填充不改变场 | $O(N_\eta\log N_\eta)$ 的转换；无需认证候选求解器精度 |
| 代理源位置、有限修正系数及状态映射 | T2.1、T3.0；检查所有源在闭分片外 | 一次导出与有限求和；缺失则无法认证实际 MFS 场 |
| 曲线速度的正下界、曲率上界 | Fourier 导数包络及区间细分 | 几何预处理；可跨候选复用 |
| 法向领子单射性、界面/周期副本分离、组内重数 | 草稿几何条件及本文修正；不能只检查曲率 | 几何细分为主；对已固定几何一次 |
| 各组 $\delta_g,\eta_g,\ell_g,D_{0,g},D_{1,g}$ | T4.2–T4.3；任意通过验证的参数即有效 | 标量计算；可优化但不要求证明优化器全局最优 |
| 各组 $\overline C_g$ | 谱有理函数的端点和唯一驻点，(T4.7) | 常数数量的算术；不增加 FMM 调用 |
| 复条带/面板半径 $a,R$ | 复速度平方、去奇性距离商和离界面距离证书，T3.0 | 可能是主要新增预处理；共享几何与面板 |
| $\log H$、平方根、Hankel 的分支证书 | 零点排除和相容分支，T3.0、(Q3) | 区间细分；可重复使用 |
| 分裂核包络 $H,G$ 及必要导数包络 | (Q3) 的整函数级数、解析除差、密度系数和 MFS 系数 | 每种几何/面板预计算，非每个胞元重复 |
| 内层 Kress 误差 $E_K$ | (Q2)，需要 Taylor 系数时用 (Q2c) 和 Cauchy 界 | 流式 $O(n_tn_s)$ 或共享核；阶数由余项决定 |
| 节点残差 $\widetilde J_D,\widetilde J_N$ 及绝对误差 $e_q$ | 内层、核函数、FMM 展开误差相加；浮点可复用 | 主要在线成本；不能只提供名义相对容差 |
| 外层 $M_F$、混叠余项 | (Q1)；用 $J(z)J^\sharp(z)$ 而非 $|J(z)|^2$ | $O(N)$ 加包络；无需另算真解 |
| 墙与接缝的 Taylor 系数、系数误差、余项和 $V_P$ | (Q4)，先组合跳跃；或 (T2.9)–(T2.10) | 每面板 $p_T+1$ 个系数；积分为有限代数 |
| 材料、墙、接缝有限部分 $\overline B_g$ | (Q1)/(Q4)，按组累加 | $O(n_c)$ 状态处理；只用三个参考几何 |
| 可靠的加速展开误差 | 源簇定理及各簇绝对强度，或实际 FMM 的已验证尾界 | 树/盒包络可共享；当前 FMM 是否满足尚未核验 |
| 特殊函数球/jet 或经验证的近似误差 | T3.5；自相互作用使用解析去奇性公式 | 少数共享中心与包络可用高精度；接口失败时细分 |
| $\overline\Theta_s$ 或 $G_s\preceq H_s$ | 对基向量用同样的连续残差证书，或 (PT5) | 最坏 $K$ 个右端；应批量/共享核 |
| $p_s,r_s<1$、$\overline{\|\mathsf P_s^\ell\|}$ | 可靠矩阵幂范数，T3.8 | $O(p_sK^3)$，小内存；不能只用谱半径估计 |
| 尾状态 $\mathsf P_s^{n_c}c_s$ 的范数/球 | 可靠矩阵向量递推，(PT2) | $O(n_cK^2)$ |
| 可选 $S_0,e,D,S$ | Lyapunov 近似与残余修正，(PT3)–(PT4) | $O(K^3+p_sK^3)$；避免 $K^2$ 维 Kronecker 系统 |
| 传播尾 $\overline T_{g,s}$ 与 $\overline\varepsilon_g$ | (PT2)/(PT3)、(PT6) | 标量/二次型；先认证稳定性和单胞跳跃映射 |
| 圆盘中心、半径及全盘处于均匀分片的证书 | 点到材料/人工界面的距离；T3.6 | 少量几何检查；不能跨越候选场的人工跳跃 |
| 圆盘中心值下界和 Bessel 正权重下界 | (Q5)；必要时有限模式 (Q6) | 每盘一个可靠场值和两个 Bessel 值；增强版另算圆周 Fourier 系数 |
| 圆盘不交或覆盖重数、$U_-$ | (Q5)/(Q6) 的正项相加 | 少量几何/标量运算 |
| 舍入与相消放大估计 | 逐类记录绝对累加强度及误差模型；与截断分开 | 通常常数倍开销；若仅估计，最终标签必须保留 |
| $\overline Q,D,\overline R$ 和向外取整端点 | (PT6)、预算 (B0) | 可忽略；$D\le0$ 时证书失败 |
| 两侧带边 $\overline a_s,\underline b_s$ | 可靠纤维上下界、(T1.6)–(T1.7) 全 $\theta$ 覆盖 | 离线主成本之一；同一引线同一 $\beta$ 可复用 |
| 最终区间与公共带隙的严格分离 | (T1.5) | 标量检查；仅用于把谱点认定为导模 |

## 附录：提问提示词

附件为当时的草稿 `draft/tmp/bie-theory-rewrite/main.pdf`。

附件：`main.pdf`（论文理论部分草稿，中文；第 5 节"基于预解式的谱距离估计"是本任务的起点）。

### 背景

二维 $y$ 方向周期（周期 $d$）的介电线缺陷波导，固定 Bloch 相位 $\beta$，算子 $A(\beta)=-\rho^{-1}\Delta$ 作用在条带 $B=\mathbb R\times(-d/2,d/2)$ 上的加权空间 $\mathcal H=L^2(B,\rho)$ 中（草稿第 2 节）。左右两侧是**不同的**周期半引线，中间是一个缺陷胞元。用边界积分方程（BIE）算出候选 $\widehat k$ 和分片场 $\widehat u$：每个均匀区域内精确满足 Helmholtz 方程，误差只在材料界面和人工竖直界面上的值跳跃与法向导数跳跃里。

草稿定理 5.x（谱距离定理）已经证明：
$$\operatorname{dist}(\mu,\sigma(A(\beta)))\le \frac{2\mu Q}{U-Q},\qquad Q=C\varepsilon_{\partial,\ell_*},\quad \mu=\widehat k^2 ,$$
其中 $\varepsilon_{\partial,\ell_*}$ 是全部界面跳跃的加权 $L^2$ 范数，$U=\lVert\widehat u\rVert_{\mathcal H}$，$C$ 是迹常数（命题"全界面正移位迹估计"）。这个界不需要谱隔离或模态计数。我们**不**要求证明区间内只有一个特征值。

现在的数值（全部是浮点估计，不是可靠界）：
- $\beta=0.5$，$d=1$，引线胞元宽 $L=1$；外部 $\rho=1$，中心介质柱 $\rho=4$，引线介质柱 $\rho=17$。
- 中心介质柱是一条五重扰动的星形解析曲线；左右引线介质柱是三瓣形 $r(t)=0.2\,(1+a\cos 3t)$，左 $a=0.12$，右 $a=0.20$。
- $\widehat k=1.5584378941820909$，$\mu=\widehat k^2$；$\ell_*=1$，领子半宽 $\delta_{\rm col}=0.004$（由 $C$ 反推最大曲率约 64，所以领子很窄）。
- $\varepsilon=2.05\times10^{-12}$（768 个评价点；1536 点时为 $1.64\times10^{-12}$），$C=9.578$，$U=0.1234$，谱距离 $R=7.7\times10^{-10}$，区间全宽 $W=2R\approx1.5\times10^{-9}$。
- 离散：Rayleigh 截断 $M=48$（$K=97$ 个模态），中心曲线 512 个密度节点，引线曲线各 256 个；显式累加 40 个引线胞元，其余用传播矩阵尾项。
- 评价：用 FMM，768 点约 54 s，峰值 1.4 GiB。$\varepsilon^2$ 中约 96% 来自中心材料界面的法向跳跃和左右接合墙（中心胞元与引线胞元之间的竖直界面）的法向跳跃。768→1536 点时，材料界面的跳跃基本不变，接合墙法向跳跃的平方却下降约 60%，原因不明。

目标：在 40 分钟、3 GiB 以内算出**可靠**的区间，全宽不超过 $5\times10^{-9}$（即 $\overline C\,\overline\varepsilon$ 的乘积最多比现值大约 3 倍）。舍入误差可以像我们的 FEM 论文那样只给估计（"截断误差意义下可靠，附舍入误差估计"），除非把它也包括进来代价很小。

### 草稿与实际实现的两处差别（请先处理）

1. 草稿第 2 节假定左右两侧是**同一个**周期背景 $\rho_{\rm p}$，本质谱命题引用 Fliss 2013 的命题 3.1。实际算例左右引线不同。
2. 草稿 (P2) 说场"精确满足 $\beta$ 准周期条件，因为准周期 Green 函数满足该条件"。实际代码中的准周期 Green 函数是增广基本解法（augmented MFS）的近似：自由空间 Hankel 函数的近邻周期像，加上胞元外的代理点源和上下的平面波，系数用最小二乘拟合。所以上下周期接缝上的准周期条件只近似成立。目前接缝的不匹配只作为诊断量算出，不计入 $\varepsilon$。

### 需要的定理（按优先级排列）

#### T1 两侧不同引线的本质谱与谱隙内的离散谱
设 $\rho=\rho_-$（$x<x_-$），$\rho=\rho_0$（$x_-<x<x_+$），$\rho=\rho_+$（$x>x_+$），其中 $\rho_\pm$ 在 $x$ 方向以 $L_\pm$ 为周期（允许 $L_-\ne L_+$），三者都在 $y$ 方向以 $d$ 为周期，分片常数并有正的上下界。证明：
$$\sigma_{\rm ess}(A(\beta))=\sigma(A_-(\beta))\cup\sigma(A_+(\beta)),$$
其中 $A_\pm(\beta)$ 是用 $\rho_\pm$ 填满整条带得到的周期算子；并证明在两者的公共谱隙内，$\sigma(A(\beta))$ 只含有限重的孤立特征值，特征函数指数衰减。可以给完整证明，也可以引用文献，但要写明作者、题名、定理号，逐条核对其假设（如果没有亲自读过原文，请注明）。最后说明：每条引线的带隙证书需要提供什么（例如固定 $\beta$ 时各能带在 $\theta$ 上的上下确界），才能推出 $[\mu-R,\mu+R]$ 落在本质谱之外。

#### T2 场的定义与正则性；不精确的准周期
(a) 对解析曲线和三角多项式密度，证明草稿中假定的 (P3)：场在每个分片内直到边界都局部属于 $H^2$。场包括层势、Rayleigh 波，以及引线中逐胞元平移得到的 Bloch 尾。

(b) 给出不依赖精确准周期 Green 函数的完整定理。建议的路线：用 MFS 近似核本身定义场（它在每个区域内仍精确满足 Helmholtz 方程），把上下接缝作为一类新界面加入 $\mathscr E$，其跳跃是值和 $\partial_y$ 相对于相位 $e^{i\beta d}$ 的不匹配；然后相应地修改迹估计（准周期圆柱上的接缝领子，接缝与竖直墙相交处的覆盖重数）以及谱距离定理的证明。另一条路线是给出 $G_{\rm MFS}-G_{\rm QP}$ 及其导数的可计算界。请比较两条路线，说明哪一条在完全可靠的前提下更便宜。人工界面的模态尾项界（草稿式 artificial-tail-bound）用到了精确准周期的 Rayleigh 结构，请按选定的定义重新推导。

#### T3 截断误差与求积误差的可计算上界（得到 $\overline\varepsilon$ 与 $\underline U$）
对下面每一项，给出带显式常数的定理。常数应当能由已知数据算出：曲线的 Fourier 系数、密度系数、$k$、$\rho$、几何距离。同时说明怎样计算这些常数，以及大致的计算量：
1. 外层求积：由有限个采样点得到 $\int_\Gamma|J|^2\,ds$ 的上界，其中 $J$ 是解析闭曲线上的跳跃函数；
2. 内层求积：三角多项式密度在曲线自身目标点上的 Kress 分裂求积误差；
3. 竖直墙上的跳跃：有限个模态加尾项，或者直接在墙段上求积；
4. 接缝跳跃（如果 T2 选这条路线）；
5. 引线的传播尾项：草稿已有式 boundary-propagation-tail，请核对；
6. Hankel/Bessel 函数求值：只需写明对区间算术库（如 Arb）的要求；
7. 场范数 $U$ 在一个背景圆盘上的下界。

我们倾向于能复用现有浮点评价的界，例如由解析延拓给出的混叠或 Fourier 尾项界，而不是在每个节点上做区间求值。可参考的工作：Dahne–Salvy 2020（先组合残差，再用 Taylor 模型和区间算术），Kress 的 Nyström 误差分析，Epstein–Greengard–Klöckner 2013 的层势局部展开误差，Arens 等 2013 的准周期 Ewald 误差界，Trefethen–Weideman 2014 的梯形公式误差。请对接合墙法向跳跃随节点数下降约 60% 的现象给出一个可能的解释（只需假设，不必证明），并说明你的界怎样处理它。

#### T4 收紧迹常数 $C$
区间宽度与 $C$ 成正比。现在 $C\approx9.58$，主要来自 $C_0/(\rho_{\min}\mu^2)$ 这一项，而 $C_0\propto1/\delta_{\rm col}$，$\delta_{\rm col}=0.004$ 被星形曲线的最大曲率限制。请寻找可以证明的更小常数，例如：最优的一维迹不等式常数；随弧长变化的领子宽度，配合加权的跳跃范数；优化 $\ell_*$；把曲线分段处理；或者其他利用 $z=(A-\mu)^{-1}\widehat u$ 结构的办法。给出公式；如果能估算，给出在上述参数下的数值。

#### T5 加速（次要，T1–T4 之后再做）
列出能降低**可靠评价**成本的办法（不是候选求解的成本）。每条说明能省掉什么，以及还需要证明什么。例如：$\beta$ 扫描时复用引线量（传播矩阵 $\mathsf P_\pm$、$\Theta_\pm$、$r_\pm$）；怎样让可靠的 $\overline\varepsilon$ 的计算量接近浮点 $\varepsilon$。

### 输出要求
- 中文，公式用 LaTeX，记号沿用草稿。
- 每个定理写清楚全部假设、函数空间和常数；给完整证明或准确引用；标明状态：已证明 / 在列出的条件下证明 / 未证明（写明缺口）。
- 严格区分"可靠上界"（有数学保证）和"估计"。
- 最后给一张表：为了得到可靠的 $\overline C$、$\overline\varepsilon$、$\underline U$，实现中要计算的每一个量、用到的定理，以及成本的大致估计。
- 发现草稿已证部分（定理 5.x、命题"全界面正移位迹估计"）有错误时请指出；没有错误就不必重写。
