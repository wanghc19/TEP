# I3.1 全边界胞元 BIE 弱残量设计

## 摘要与状态

- **Design ID:** `I3.1-FULL-BOUNDARY-CELL-BIE-V1`
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `DESIGN PASS`
- **Implementation:** `IMPLEMENTED / STATIC FROZEN / SPEC-TO-CODE REVIEW PENDING`
- **Run:** `NOT AUTHORIZED`
- **Frozen future attempt:** `fbie-a1`
本设计只研究 I2 算法实际保存的 candidate
$$ \widehat k_h=1.832770289108157, \qquad \mu_h=\widehat k_h^2=3.3590469326375971. $$
目标是用左右人工墙和材料圆组成的 full-boundary cell BIE 重建左右无限 lead 中的分片场，
再用显式 value lifts 把它修复成连续 form space 中的场，计算直接作用于连续弱方程的 residual
indicator candidate。finite determinant zero、score minimizer 和有限 Nyström density residual 都
不是本设计目标。
左右墙各使用一个准周期 single-layer density，材料圆使用 Müller densities。墙输入仍来自冻结的
$M=48$ total Dirichlet trace，但墙响应阶数、材料圆 density 阶数、circle action 阶数和 trace
weight 阶数全部独立冻结。墙密度按 Fourier mode 消元后，只需分解材料圆 Schur complement，
避免形成一个稠密的全边界大矩阵。
连续层面消去墙密度后得到的 Schur complement 与矩形 Dirichlet-wall Green 表示代数等价。
因此本路线是 [[research/projects/eig-apost/implementation/i3/design-3-1e|V4 pure-BIE design]]
的全边界重参数化和数值资格修复，不是独立连续方法，也不能作为 I3.2 independent reference。
它的新增价值仅是：把 $M=48$ 与完整墙响应解耦；在公共 1024 点表示上直接比较墙 Schur
response；把历史 individual-$T$ oracle 改成实际进入 Müller 方程的 $T_{\mathrm o}^{QP}-T_{\mathrm i}$
oracle。
若未来得到有限的 $q_h^{\mathrm{num}}<1$ 且所有内部资格通过，本 attempt 可交付
`INTERNALLY_QUALIFIED_FULL_BOUNDARY_BIE_ESTIMATOR_CANDIDATE / I3.2 READY`；否则只交付
`NUMERICALLY_UNQUALIFIED_FULL_BOUNDARY_BIE_INDICATOR`。两者的 nominal transform 都只是普通
双精度量，不证明连续特征值存在，不形成误差上界，也不识别唯一 mode。
### 原文依据和不能继承的结论
- [[ref/ref_data/books/McLean2000.pdf|McLean (2000) original]] Theorem 6.11（书页 203，
  本地 PDF p. 218）给出 single layer 的 $H^1$ 映射及 value/normal jump；Theorem 6.12 和
  Corollary 6.14 给出更高正则性。准周期 kernel 仍需使用“free singular part 加 smooth
  remainder”的映射，不从该书自动获得当前 finite evaluator 的误差界。
- [[ref/ref_data/Dominguez2016.pdf|Domínguez--Lyon--Turc (2016) original]] PDF pp. 5--6，
  (3.1)、(3.6)--(3.9) 用于核对 one-sided trace signs；Theorem 4.3（PDF p. 11）只支持
  hypersingular difference 相比 individual operators 弱化奇性并给出 compactness。其
  Theorems 4.5--4.6 不证明当前带人工墙 block
  的 full-boundary system 可逆。
- [[ref/ref_data/Barnett2010.pdf|Barnett--Greengard (2010) original]] PDF pp. 13--16，
  (34)--(42) 提供 full-wall layer representation 的数值先例；其完整性是 Conjecture 7，
  不是本项目可继承的定理。Remark 8（PDF p. 21）只是 full-system/Schur 操作的类似先例，
  不是本文 Dirichlet-wall Schur identity 的证明。
- [[ref/ref_data/Fliss2013.pdf|Fliss (2013) original]] Theorem 4.5、Remark 4.11、
  Theorems 4.12--4.13 只适用于满足相应 well-posedness 和 essential-gap 条件的连续
  half-guide propagation operator；finite QZ $P_\pm$ 只参数化本设计 trial，不能继承 exact
  propagation 或 DtN 定理。详见
  [[research/projects/eig-apost/phase3-analysis/s-lead-field|lead-field analysis]]。
- [[ref/ref_data/Hao2014.pdf|Hao et al. (2014) original]] 支持 smooth closed-curve Kress
  Nyström 的高阶数值表现，但不是 outward truncation enclosure，也不覆盖未经专门处理的
  close evaluation。
## 1. 连续目标、弱残量和谱距离变换

波导、材料、质量空间和 form space 固定为
$$ B=\mathbb R\times(-1/2,1/2), \qquad \rho=17\ \text{in every lead disk}, \qquad \rho=1\ \text{elsewhere}, $$
$$ H=L^2(B,\rho\,\mathrm dx\,\mathrm dy), \qquad V=H^1_\beta(B), \qquad \beta=0.5. $$
连续自伴算子是 $A=-\rho^{-1}\Delta$，其闭 form 为
$$ a(u,v)=\int_B\nabla u\cdot\nabla\overline v, \qquad m(u,v)=\int_B\rho u\overline v. $$
固定 shift $\gamma=\mu_h$ 和
$$ \|v\|_V^2=a(v,v)+\gamma m(v,v). $$
对后文构造的非零场 $u_h^{\mathrm c}\in V$，定义连续弱残量
$$ R_h(v)=a(u_h^{\mathrm c},v)-\mu_hm(u_h^{\mathrm c},v), \qquad v\in V. $$
本实验计算普通双精度 residual upper candidate $\mathcal M_h^{\mathrm{num}}$ 和 field-norm
lower candidate $N_h^{\mathrm{num}}$，其中理论方向必须分别是
$$ \|R_h\|_{V'}\leq \mathcal M_h, \qquad N_h\leq\|u_h^{\mathrm c}\|_V^2. $$
数值量定义为
$$ q_h^{\mathrm{num}} =\frac{\mathcal M_h^{\mathrm{num}}}{\sqrt{N_h^{\mathrm{num}}}}. $$
没有 outward quadrature、operator truncation 和 tail enclosure 时，上式只是 estimator
candidate，不是对真实 $q_h$ 的可靠上界。若 $q_h^{\mathrm{num}}<1$，仍保存代数变换
$$ I_{\lambda,h}^{\mathrm{num}} =\left[ \max\left\{0,\frac{\mu_h-q_h^{\mathrm{num}}\gamma} {1+q_h^{\mathrm{num}}}\right\}, \frac{\mu_h+q_h^{\mathrm{num}}\gamma} {1-q_h^{\mathrm{num}}} \right], $$
$$ I_{k,h}^{\mathrm{num}} =\left[\sqrt{\inf I_{\lambda,h}^{\mathrm{num}}}, \sqrt{\sup I_{\lambda,h}^{\mathrm{num}}}\right]. $$
该 nominal transform 只能标记 `UNQUALIFIED`。I3 第一层最终目标仍是
$$ \operatorname{dist}\!\left( \widehat k_h,\mathcal K_{\mathrm{disc}}(A;G_\lambda)\right), $$
不是 finite root 或 score minimizer。只有 I3.3 补齐 reliable one-sided numerics、continuous
projected gap 和预注册宽度门后，才允许把可靠区间解释为 gap 内至少存在一个连续离散谱点。
## 2. Frozen candidate、QZ state 和共享墙迹

固定 I2 fine object
$$ n_{\mathrm{tot}}=256, \qquad M=48, \qquad K=2M+1=97. $$
只在冻结 seed 和 $\widehat k_h$ 各调用一次 `eval_i21`；不重扫、不重选 candidate。若
$v_h$ 是物理加权矩阵 $D_rA_{\mathrm{def}}^DD_c$ 的最小右奇异向量，则中心 state 固定为
$$ q^{\mathrm{cen}} =\frac{D_cv_h}{\|D_cv_h\|_2} =\begin{bmatrix}q_L\\q_R\end{bmatrix}. $$
中心空列 $C_0=(-1/2,1/2)\times\mathbb T_d$ 内 $\rho=1$，其 exact Rayleigh field 固定为
$$ u_0(x,y)=\sum_{m=-M}^{M}\left[q_{L,m}e^{\mathrm i\gamma_m(x+1/2)} +q_{R,m}e^{-\mathrm i\gamma_m(x-1/2)}\right]\psi_m(y). $$
它严格满足 $(-\Delta-\mu_h)u_0=0$；左右 traces 分别为
$q_L+E_cq_R$、$E_cq_L+q_R$，global $+x$ derivatives 分别为
$\mathrm i\Gamma(q_L-E_cq_R)$、$\mathrm i\Gamma(E_cq_L-q_R)$。center outward flux 再按
左墙 $-e_x$、右墙 $+e_x$ 取号。该 field、两条 traces 和两个 outward-flux maps 必须保存。
冻结 QZ bases、whole-subspace propagation 和 wall trace maps 为
$$ Z_+=\begin{bmatrix}A_+\\B_+\end{bmatrix}, \qquad Z_-=\begin{bmatrix}A_-\\B_-\end{bmatrix}, \qquad D_\pm=A_\pm+B_\pm, $$
$$ D_-c_-=[I,E_c]q^{\mathrm{cen}}, \qquad D_+c_+=[E_c,I]q^{\mathrm{cen}}. $$
保留 full $K\times K$ matrices $P_\pm$；禁止逐 multiplier、删除 Jordan/nonnormal coupling、
使用 $P_\pm^{-1}$ 或在新 BIE 中重新拟合 propagation。右、左 lead 第 $n$ 个外向胞元的
左右 total Dirichlet coefficient pairs 分别为
$$ G_+P_+^nc_+ =\begin{bmatrix}D_+\\D_+P_+\end{bmatrix}P_+^nc_+, $$
$$ G_-P_-^nc_- =\begin{bmatrix}D_-P_-\\D_-\end{bmatrix}P_-^nc_-. $$
每一列 coefficient $d_m$ 表示物理 wall trace
$$ g(y)=\sum_{m=-M}^{M}d_m\psi_m(y), \qquad \psi_m(y)=d^{-1/2}e^{\mathrm i(\beta+2\pi m/d)y}, \qquad d=1. $$
$M=48$ **只定义该输入 $g$**。wall density、wall normal response、circle density、circle
action 和 circle trace weights 均不得截到 $|m|\leq48$。incoming/outgoing decomposition 只作
nonblocking diagnostic，不进入新 BIE right-hand side。
physical field 和 periodic gauge 的关系固定为
$$ u(x,y)=e^{\mathrm i\beta y}\widetilde u(x,y), \qquad u(x,y+d)=e^{\mathrm i\beta d}u(x,y), \qquad \widetilde u(x,y+d)=\widetilde u(x,y). $$
top/bottom physical outward normals 相反；数值 wall/Fourier maps 先在 physical basis 中形成，
再乘 $e^{-\mathrm i\beta y}$ 检查 periodic gauge。finite but poor branch margin、QZ rcond、solve
residual 和 scattering closure 只记 warning；branch 非有限或精确 Wood point 才使对象不可用。
## 3. 连续 full-boundary layer trial

### 3.1 Quotient cell、边界和方向
一个 lead cell 是准周期 quotient cylinder
$$ C=(-1/2,1/2)\times\mathbb T_d, \qquad d=1. $$
材料圆盘 $D$ 的半径为 $R=0.2$，圆周为 $\Gamma$，外部区域为
$\Omega_{\mathrm e}=C\setminus\overline D$，内部为 $\Omega_{\mathrm i}=D$。人工墙
$\Gamma_L$、$\Gamma_R$ 是 quotient cylinder 上互不相交的闭曲线；top/bottom 已由 Bloch
identification 配对，不是另外两条带 corner 的积分边界。因此本表示没有矩形 corner integral，
也没有 wall--circle junction。circle 到 wall 的最小距离冻结为
$$ \operatorname{dist}(\Gamma,\Gamma_L\cup\Gamma_R)=0.3. $$
wall cell-outward normals 为 $n_L=-e_x$、$n_R=+e_x$。circle normal $n_\Gamma$ 始终从
材料内指向背景区；circle interior/exterior derivatives 都按同一个 $+n_\Gamma$ 比较。
背景和材料 wavenumbers 为
$$ k_{\mathrm o}=\widehat k_h, \qquad k_{\mathrm i}=\sqrt{17}\,\widehat k_h. $$
### 3.2 连续 operators 和 density spaces
令 $\mathcal S^{QP}$、$\mathcal D^{QP}$、$\mathcal K^{QP}$、
$(\mathcal K^{QP})^*$ 和 $\mathcal T^{QP}$ 表示由**精确连续准周期 Green kernel** 定义的
layer/trace operators；内部 free-space operators 省略上标 `QP`。wall densities 和 circle
densities 属于
$$ \xi_L,\xi_R\in H^{-1/2}_\beta(\Gamma_{L/R}), \qquad \tau\in H^{1/2}(\Gamma), \qquad \zeta\in H^{-1/2}(\Gamma). $$
代码的第二 density coordinate 固定为
$$ \zeta=-\sigma. $$
连续 layer ansatz 为
$$ u_{\mathrm e}^{\mathrm{raw}} =\mathcal S_L^{QP}\xi_L+\mathcal S_R^{QP}\xi_R +\mathcal D_{\mathrm o}^{QP}\tau-\mathcal S_{\mathrm o}^{QP}\zeta, $$
$$ u_{\mathrm i}^{\mathrm{raw}} =\mathcal D_{\mathrm i}\tau-\mathcal S_{\mathrm i}\zeta. $$
同一 $n_\Gamma$ 下，circle transmission difference operator 是
$$ \mathcal A_{cc} =\begin{bmatrix} I+\mathcal K_{\mathrm o}^{QP}-\mathcal K_{\mathrm i} &\mathcal S_{\mathrm i}-\mathcal S_{\mathrm o}^{QP}\\ \mathcal T_{\mathrm o}^{QP}-\mathcal T_{\mathrm i} &I+\mathcal K_{\mathrm i}^*-(\mathcal K_{\mathrm o}^{QP})^* \end{bmatrix}. $$
第一行是 $u_{\mathrm e}-u_{\mathrm i}$，第二行是
$\partial_{n_\Gamma}u_{\mathrm e}-\partial_{n_\Gamma}u_{\mathrm i}$。wall-to-circle
operator $\mathcal A_{cw}$ 是两个 wall single layers 的 circle value/normal traces；
$\mathcal A_{wc}$ 是 circle layer field 在左右墙的 Dirichlet traces。
完整连续方程只用来定义需要近似的对象：
$$ \begin{bmatrix} \mathcal A_{cc}&\mathcal A_{cw}\\ \mathcal A_{wc}&\mathcal A_{ww} \end{bmatrix} \begin{bmatrix}\eta\\\xi\end{bmatrix} =\begin{bmatrix}0\\g\end{bmatrix}, \qquad \eta=\begin{bmatrix}\tau\\\zeta\end{bmatrix}, \qquad \xi=\begin{bmatrix}\xi_L\\\xi_R\end{bmatrix}. $$
本文不假设该连续 block operator 已证明可逆，也不把后文 finite solve 称为唯一 exact cell
solution。
### 3.3 Wall modal block、flux 和 Schur relation
对偶数 $N$，冻结 Fourier/Nyquist index set
$$ \mathcal I_N=\{-N/2,-N/2+1,\ldots,N/2-1\}. $$
对独立 wall-response order $m\in\mathcal I_{N_w}$，令
$$ \beta_m=\beta+2\pi m/d, \qquad \gamma_m^2=k_{\mathrm o}^2-\beta_m^2, $$
并固定 outgoing/decaying branch：propagating order 取 $\gamma_m>0$，evanescent order 取
$\operatorname{Im}\gamma_m>0$。令
$$ s_{0,m}=\frac{\mathrm i}{2\gamma_m}, \qquad E_m=e^{\mathrm i\gamma_mL}, \qquad L=1. $$
wall value block 和 cell-outward flux block 是
$$ A_{ww,m} =\begin{bmatrix}s_{0,m}&s_{0,m}E_m\\s_{0,m}E_m&s_{0,m}\end{bmatrix}, $$
$$ Q_{ww,m} =\frac12\begin{bmatrix}1&-E_m\\-E_m&1\end{bmatrix}. $$
若 $F_L,F_R$ 把 circle density 映到左右墙 outgoing Fourier coefficients，
$\Gamma_w=\operatorname{diag}(\gamma_m)$，则一个 cell 的左右 outward normal maps 为
$$ \begin{bmatrix}Q_L\\Q_R\end{bmatrix} =Q_{ww}\begin{bmatrix}\xi_L\\\xi_R\end{bmatrix} +\begin{bmatrix}\mathrm i\Gamma_wF_L\\\mathrm i\Gamma_wF_R\end{bmatrix}\eta. $$
$F_L,F_R$ 和 $\Gamma_w$ 使用完整独立 wall orders，不得复用 $M=48$。wall-to-circle
columns由同一 modal single layer 的 circle Cauchy data形成；source normal、target normal 和
wall outward orientation 必须分别保存。
有限实现只按 mode 反解 $A_{ww,m}$，不分解稠密 $2N_w\times2N_w$ wall block。消去 wall
density 后，circle Schur system 为
$$ S_c\eta =-A_{cw}A_{ww}^{-1}g, \qquad S_c=A_{cc}-A_{cw}A_{ww}^{-1}A_{wc}, $$
$$ \xi=A_{ww}^{-1}(g-A_{wc}\eta). $$
连续层面该消元与 Dirichlet-wall Green representation 代数等价，因而保留相同 continuous
Schur bias。并且
$$ \det A_{ww,m}=s_{0,m}^2(1-E_m^2). $$
所以 full-boundary parameterization 没有消除 Wood point 或 cell Dirichlet pole，只把它们
显式化。除 $|\gamma_m|$ 外，记录 scale-free pole clearance
$$ \delta_m^{\mathrm{pole}}=\frac{|1-E_m^2|}{1+|E_m|^2}. $$
$\gamma_m=0$、$\delta_m^{\mathrm{pole}}=0$ 或非有限值使相应 mode unavailable；有限但小于
$10^{-8}$ 只记 `WALL_MODAL_POLE_WARNING`。
## 4. Finite Nyström 对象和冻结分辨率

### 4.1 连续/有限对象严格分层
连续 operators 始终使用 calligraphic symbols。有限 circle Nyström/collocation matrices 写成
$A_{cc,N_c}$、$A_{cw,N_c,N_w}$、$A_{wc,N_w,N_c}$；wall modal matrix 写成
$A_{ww,N_w}$。finite solve 返回 trigonometric densities
$$ \eta_{N_c,N_w}, \qquad \xi_{N_c,N_w}. $$
数学 raw trial 是**精确连续 kernels 作用于这些有限三角 density**，不是
$A_N^{-1}$ 对应的 exact BVP。512 点 traces、Grams 和 FFT coefficients 只是该连续 trial 的
ordinary-double approximations。禁止把 $A_N^{-1}$ 写成 $\mathcal A^{-1}$，也禁止把 finite
collocation residual 当成连续弱残量。
`kbie` 返回 scaled matrix
$$ A_{cc,N_c}^{\mathrm{scaled}} =D_rA_{cc,N_c}^{\mathrm{phys}}D_c. $$
full-boundary assembly 必须先显式反缩放
$$ A_{cc,N_c}^{\mathrm{phys}} =D_r^{-1}A_{cc,N_c}^{\mathrm{scaled}}D_c^{-1}, $$
在 physical $[\tau;\zeta]$ coordinates 中加入 wall blocks，再只为 factor/solve 施加一次记录
清楚的 scaling。artifact 保存 scaled--physical roundtrip defect 和 $\zeta=-\sigma$ oracle。
### 4.2 冻结 levels 和公共表示
四类分辨率相互独立：
| 对象 | 冻结值 | 作用 |
|---|---:|---|
| circle density solve | $N_c=256$ | 每个 wall level 的 circle unknown |
| circle action/check | $N_c^{\mathrm{act}}=512$ | 同一 finite density 的 one-sided traces 和 residual factors |
| wall response coarse/official | $N_w=256/512$ | 分别重新形成 Schur system 并求解 |
| common wall grid | $N_w^{\mathrm{com}}=1024$ | 精确 Fourier evaluation 后比较 wall maps |
| circle coefficient set | $\mathcal L_{512}=\mathcal I_{512}$ | 全部 512 action modes，包括 Nyquist $-256$，都进入 residual |
| circle Riccati steps | $N_\gamma=256/512$ | 512-step value 为 official trace weight |
| wall/circle lift width | $\delta_w=\delta_c=0.04$ | value-only conforming repair |
| volume radial quadrature | 16/32 Gauss points | 32-point value 为 official volume factor |
两个 wall levels 都用相同 $N_c=256$ 重新求解；official estimator 使用 $N_w=512$ 解。
所有 1024 点 wall values 都由 Fourier series 直接求值，不用 nearest-node matching。
固定三种不同的 refinement diagnostics：
1. `fixed_density_action_change`：保持 coarse finite densities 不变，把 source/action 从 256
   细化到 512，再把两次结果用直接 Fourier evaluation 放到公共 1024 点表示；
2. `resolved_source_change`：分别重新求解 $N_w=256$ 和 $N_w=512$ full-boundary systems，
   再在同一 1024 点 physical/gauge 表示中比较；
3. `circle_action_change`：保持 official $\eta_{256,512}$ 不变，在 256 和 512 circle action
   grids 上计算 one-sided value/normal traces；先把 $\mathcal I_{256}$ coefficients 精确零填充
   到 $\mathcal L_{512}$，再与 512 action 比较全部共同及新增 modes；另把
   $\mathcal L_{512}\setminus\mathcal I_{256}$ 的 weighted energy 除以全部 512-mode energy，定义
   `circle_angular_tail_change`，它不同于无 pass threshold 的 outside-$M$ share。
每项都保存 raw numerator、两侧 norm、zero-component flag 和 scale-covariant ratio。若两侧都
精确为零，ratio 定义为零；否则 denominator 使用两侧实际 norm 和 `realmin`，不得用 `max(1,.)`
破坏尺度协变。三项 qualification threshold 预注册为 `0.20`；finite failure 只记 warning，
不停止 $q$。
### 4.3 Actual $\Delta T$ 和 one-sided kernel oracles
必须测试实际进入 $A_{cc}$ 第二行第一列的
$$ \Delta\mathcal T =\mathcal T_{\mathrm o}^{QP}-\mathcal T_{\mathrm i}, $$
而不是 individual $\mathcal T_{\mathrm o}$ 或 $\mathcal T_{\mathrm i}$。圆周使用
$L^2(\mathrm ds)$ orthonormal basis
$$ e_\ell(\theta)=\frac{e^{\mathrm i\ell\theta}}{\sqrt{2\pi R}}. $$
free-space hypersingular action 的解析 eigenvalue 为
$$ t_\ell(k) =\frac{\mathrm i\pi k^2R}{2} J_\ell'(kR)H_\ell^{(1)\prime}(kR). $$
对 $\ell=-8,\ldots,8$，独立 oracle 比较 assembled physical $A_{21,N_c}e_\ell$ 与完整向量
$$ \bigl[t_\ell(k_{\mathrm o})-t_\ell(k_{\mathrm i})\bigr]e_\ell +\mathcal T_{\mathrm{reg}}^{QP}e_\ell, $$
其中 smooth remainder 按
$$ (\mathcal T_{\mathrm{reg}}^{QP}\phi)(x) =\int_\Gamma n_x^T\nabla_x\nabla_yR^{QP}(x,y)n_y\phi(y)\,\mathrm ds_y, \qquad R^{QP}=G_{k_{\mathrm o}}^{QP}-G_{k_{\mathrm o}}^{\mathrm{free}}, $$
由真正 target--source mixed derivative 形成；若实现只使用 translation-invariant target Hessian，
等价式才是 $-\int n_x^T\nabla_x\nabla_xR^{QP}n_y\phi\,\mathrm ds_y$。production $A_{21}$
沿 Kress/proxy assembly 路径，reference 沿独立 direct/overresolved mixed-derivative contraction；
两者不得复用同一 assembled matrix。smooth remainder 一般破坏旋转对称性，所以比较完整输出
vector。official oracle 把 production $A_{21,256}e_\ell$ 与 direct reference 放在同一 256-target
grid 比较；独立 512-target reference 只按 nested restriction `1:2:512` 限制回这 256 点，用于
`reference_256_to_512_change`，不得在运行时另选 grid。256-grid norm 固定为
$\|v\|_{L^2(\mathrm ds),256}=\sqrt{2\pi R/256}\|v\|_2$；512 self-check 使用
$\sqrt{2\pi R/512}\|v\|_2$，故 $\|e_\ell\|=1$。每个 mode 保存 absolute defect、reference
change 和
$$ d_\ell^{\Delta T} =\frac{\|y_\ell^{\mathrm{num}}-y_\ell^{\mathrm{ref}}\|_{L^2(\mathrm ds),256}} {|t_\ell(k_{\mathrm o})|+|t_\ell(k_{\mathrm i})| +\|\mathcal T_{\mathrm{reg}}^{QP}e_\ell\|_{L^2(\mathrm ds),256}+\mathrm{realmin}}. $$
令 $\mathcal R_{512\to256}$ 是上述 nested restriction；reference change 固定为
$$ d_\ell^{\mathrm{ref}}=\frac{\|\mathcal R_{512\to256}y_{\ell,512}^{\mathrm{ref}}-y_{\ell,256}^{\mathrm{ref}}\|_{L^2(\mathrm ds),256}} {\max\{\|y_{\ell,512}^{\mathrm{ref}}\|_{L^2(\mathrm ds),512},\|y_{\ell,256}^{\mathrm{ref}}\|_{L^2(\mathrm ds),256},\mathrm{realmin}\}}. $$
该 denominator 在真实 difference 接近零时仍使用未相消 constituent scale，不除以近零真值，
也不 clip。qualification threshold 固定为 `0.20`。$O(1)$ finite failure 必须继续计算 $q$，但
设置 `actual_delta_t_qualified=false`，阻止把 estimator 冻结后移交 I3.2。
manufactured oracles 还必须覆盖 $\mathcal S$、$\mathcal D^\pm$、one-sided
$\partial_n\mathcal S$、$\zeta=-\sigma$ sign、$\pm1/2$ jumps、$R$ normalization、
row/column unscale、$A_{ww}$ value/flux signs。circle on-surface traces只用 jump formula/Kress
singular quadrature；不得用 near-target ordinary kernel。wall--circle cross action 的最小距离为
0.3，但仍做 256--512 source refinement。任何 nonfinite/dimension failure 使 action unavailable；
finite oracle failure 都是 nonblocking warning。
## 5. Explicit value lifts 和 global $H^1$ 条件

### 5.1 Wall 和 circle value defects
finite exact-kernel raw trial 一般不精确满足 collocation 之外的 wall trace。对每个物理 seam，
令相邻两胞元的 exact continuous raw traces 为 $u_-$、$u_+$，共享 total trace 为 $g$。在墙两侧
各取宽度 $\delta_w$ 的 strip，令
$$ \chi(t)=1-3t^2+2t^3, \qquad 0\leq t\leq1, $$
$$ w_\pm(s,y)=\bigl(g(y)-u_\pm(y)\bigr)\chi(s/\delta_w). $$
这里 $s$ 从 seam 向各胞元内部增加。于是修正后两侧 trace 都等于**同一个** $g$；
$\chi'(0)=0$ 保留 raw one-sided normal derivatives，$\chi(1)=\chi'(1)=0$ 不在 safe seam
产生新的 distributional residual。分别拟合两个近似相同的 trace 不能代替该数学 identity。
在材料圆上定义 exact continuous value jump
$$ \delta_D^{\mathrm{ex}} =\gamma_Du_{\mathrm e}^{\mathrm{raw}}- \gamma_Du_{\mathrm i}^{\mathrm{raw}}. $$
外、内 radial collars 分别加入
$$ w_{\mathrm e}(r,\theta) =-\frac12\delta_D^{\mathrm{ex}}(\theta) \chi\!\left(\frac{r-R}{\delta_c}\right), $$
$$ w_{\mathrm i}(r,\theta) =+\frac12\delta_D^{\mathrm{ex}}(\theta) \chi\!\left(\frac{R-r}{\delta_c}\right). $$
两侧修正后 value 相等；interface radial derivative correction 为零，raw circle normal jump 不变；
safe rims 的 value/derivative correction 都为零。zero-defect oracle 必须返回零 lift。
circle collar 外缘 $R+\delta_c=0.24$；wall strip 内缘到圆 collar 仍有 $0.22$ 间距。
不同圆心相距 1，故所有 wall strips、circle collars 和相邻圆 collars 互不相交。wall strips 位于
$\rho=1$ 区域；circle inner/outer collars 分别使用 $\rho=17/1$。
中心空列的 actual finite trace 是 $[I,E_c]q$ 和 $[E_c,I]q$，lead hierarchy 的共享 trace
固定为 $D_-c_-$ 和 $D_+c_+$。精确坐标关系下二者相等；ordinary finite solve 后仍须保存其
差，并在 center 一侧增加同型 value lift。center-side 与 first-lead-side 的四个 lift volume
sources 都是 singleton，必须单列进入 residual 和 artifact，不能并入 $J_\pm$ tail。
### 5.2 Bloch seam 和 global summability
数学 trial 使用精确准周期 kernel、准周期 wall basis 和 shared $g$，所以 top/bottom value 和
physical flux 按 Bloch phase 结构性匹配；在 periodic gauge 中它们严格 periodic。finite anchored
proxy、Kress 和 Fourier actions只是该对象的 ordinary approximations，必须在公共 grid 上独立
记录 value/flux Bloch defects。finite defect 只降低内部资格；因为数学对象按 exact QP kernel
定义，它不新增一个被遗漏的 physical seam residual。若未来实现实际改用不具 exact QP 定义的
kernel，则本设计失效，必须另加 Bloch lift 和其 volume residual，不能继续本 attempt。
逐胞 $H^1$ 和每个 seam value continuity 仍不足以得到全波导场。还必须用 mandatory
$W=I_K$ full-$P$ tail 建立 ordinary global summability candidate
$$ \sum_{n=0}^{\infty}\|P_\pm^nc_\pm\|_2^2<\infty. $$
对每个冻结 finite density/lift map，McLean mapping、正 wall--circle separation 和有限维性给出
$\|u_{\mathrm{cell}}(c)\|_{H^1(C)}\leq C_h\|c\|_2$；因此上述 state sum 才推出逐胞
$H^1$ norms 可和。没有这一 bounded cell map 或 finite state-tail candidate 时，global $H^1$
对象不可用。
没有该 finite tail candidate 时，$u_h^{\mathrm c}\in H^1_\beta(B)$ 的全局对象不可用，不能形成
$q_h^{\mathrm{num}}$。ordinary tail 不等于 outward-certified summability。
## 6. 完整弱残量、边界 upper candidates 和 field lower

### 6.1 Residual identity 和所有 seam
wall/circle lifts 之外的 exact-kernel raw pieces 分片满足各自 Helmholtz equation。定义所有
derivatives 的单一方向：wall 使用各 cell outward normal；circle 使用 $+n_\Gamma$。内部人工墙
的 corrected jump 是
$$ j_W=\partial_{n_R}u_{\mathrm{left}}^{\mathrm c} +\partial_{n_L}u_{\mathrm{right}}^{\mathrm c}. $$
circle 在分部积分中出现的 jump 是
$$ j_\Gamma =\partial_{n_\Gamma}u_{\mathrm i}^{\mathrm c} -\partial_{n_\Gamma}u_{\mathrm e}^{\mathrm c}. $$
由于 value lifts 在 physical interface 的 normal derivative 为零，这两个 jumps 等于相应 raw
normal jumps。令所有 lifts 的 volume source 为
$$ f_{\mathrm{lift}}=(-\Delta-\mu_h\rho)(w_W+w_{\mathrm e}+w_{\mathrm i}). $$
则完整 residual identity 是
$$ R_h(v) =\sum_{W}\langle j_W,\gamma_Wv\rangle +\sum_\Gamma\langle j_\Gamma,\gamma_\Gamma v\rangle +\int_B f_{\mathrm{lift}}\overline v. $$
center/first-cell 两个 walls 单列；lead 内部 walls、每个材料圆和每个 lift source 用 full-$P$
求和。top/bottom Bloch seam 对数学 exact-QP trial 为零。任何未来新增的非结构零 seam、corner 或
kernel defect 都必须显式增加 residual component，不能只记 diagnostic 后继续沿用本 identity。
### 6.2 Wall 和 circle $H^{-1/2}$ upper candidates
对所有 wall response orders，令
$$ \kappa_m=\sqrt{\beta_m^2+\gamma}, \qquad b_m^{\mathrm w}=2\kappa_m\tanh(\kappa_m/2)>0. $$
在 $L^2(\mathrm dy)$ orthonormal basis $\psi_m$ 下，长度各为 $1/2$ 的两侧 strip 的最小能量
lift 对数学 exact trial 给出 infinite-order quantity
$$ (B_{h,\infty}^{\mathrm w})^2 =\sum_{W}\sum_{m\in\mathbb Z}\frac{|j_{W,m}|^2}{b_m^{\mathrm w}}. $$
circle 使用 $L^2(\mathrm ds)$ orthonormal basis $e_\ell$。在内外 annuli 中令
$t=\log r$、$p=v_t/v$，并解
$$ p_t=\ell^2+\gamma\rho e^{2t}-p^2. $$
inner annulus 在 safe rim $r=R-\delta_c$ 取 $p=0$ 后积分到 $R$；outer annulus 在 safe rim
$r=R+\delta_c$ 取 $p=0$ 后反向积分到 $R$。interface $R$ 从不设 $p=0$。固定 RK4 256/512 steps；
official 512-step weight 是
$$ b_\ell^\Gamma =\frac{p_\ell^{\mathrm{in}}(R)-p_\ell^{\mathrm{out}}(R)}{R}>0. $$
$1/R$ 来自 $L^2(\mathrm ds)$ normalization，不能删除。数学 exact quantity 为
$$ (B_{h,\infty}^\Gamma)^2 =\sum_\Gamma\sum_{\ell\in\mathbb Z} \frac{|j_{\Gamma,\ell}|^2}{b_\ell^\Gamma}. $$
ordinary candidates $B_h^{\mathrm w,num}$、$B_h^{\Gamma,\mathrm{num}}$ 分别只在
$\mathcal I_{512}$ 和 $\mathcal L_{512}$ 上求和；所有已计算 modes 都进入。未计算 Fourier tails
没有 enclosure，故 `outward_wall_tail=false`、`outward_circle_tail=false`。描述性诊断固定用
$w_\ell=1/b_\ell^\Gamma$、$c_\ell=j_{\Gamma,\ell}$：
$$ r_{>|M|} =\frac{\sum_{\ell\in\mathcal L_{512},\,|\ell|>M}w_\ell|c_\ell|^2} {\sum_{\ell\in\mathcal L_{512}}w_\ell|c_\ell|^2} $$
只回答 wall input bandwidth 是否解释 circle content；它不删除 $|\ell|>M$ 的项，也没有 pass
threshold。zero denominator
时若 numerator 也为零，share 记零并标记 zero component；否则记 `Inf` warning。真正未计算的
$\ell\notin\mathcal L_{512}$ 没有 outward tail enclosure。
若 $b_\ell^\Gamma$ 非有限、非正或 stepper 无法返回，circle component 和 $q$ unavailable。
finite 256--512 weight change 即使超过 $10^{-8}$ 也只记 warning。低阶 modes 另与 scaled
modified-Bessel quotient 和离散 energy identity 比较。
数学 boundary trace/lifting inequality 的方向固定为
$$ \|R_h\|_{V'} \leq B_{h,\infty}^{\mathrm w}+B_{h,\infty}^\Gamma +B_{h,\infty}^{\mathrm{vol}}. $$
wall half-strips 只在 wall family 内分割波导，circle annuli 只在 circle family 内互不相交；
两类 trace lifts 可以互相重叠。各 family 的 restriction norm 不超过 global $V$ norm，因而各自
常数为 1；cross-family overlap 正是总量必须使用 triangle sum 的原因。
### 6.3 Lift volume source 和总 numerator
wall lift 的 $y$ derivatives 由完整 Fourier coefficients 求得，normal derivatives 用解析
$\chi',\chi''$；circle lift 用完整 circle Fourier coefficients，radial area quadrature 必须包含
$r/R$ 因子。固定 16/32 Gauss refinement，所有 wall strips 和 circle collars 的 source 放入同一个
正 factor，得到
$$ B_{h,\infty}^{\mathrm{vol}} =\gamma^{-1/2}\|\rho^{-1/2}f_{\mathrm{lift}}\|_{L^2(B)}. $$
finite Fourier sets 和 32-point quadrature 形成 $B_h^{\mathrm{vol,num}}$；未计算 wall/circle
Fourier tails 和 quadrature remainder 均未 enclosure。总 ordinary candidate 固定为
$$ \mathcal M_h^{\mathrm{num}} =B_h^{\mathrm w,num}+B_h^{\Gamma,\mathrm{num}}+B_h^{\mathrm{vol,num}}. $$
wall/circle value correction energy、strip/collar source 和各自 share 全部保存；有限 16--32
change 超过 `0.20` 只使 internal qualification 失败，不阻止 finite $q$。
### 6.4 Field-norm lower candidate
最终 conforming field 在每个人工墙的 trace 正是共享 $g$。数学 infinite trace quantity满足
$$ N_{h,\infty} =\sum_{\text{all physical walls counted once}} \sum_{m\in\mathbb Z} b_m^{\mathrm w}|g_m|^2 \leq\|u_h^{\mathrm c}\|_V^2. $$
每个 wall 两侧的 half-strips 在 $x$ 方向恰好分割全波导；$\rho\geq1$，所以使用 baseline
$\rho=1$ 仍给 lower direction。center-adjacent walls 使用 $D_\pm c_\pm$；farther walls 使用
$D_\pm P_\pm^nc_\pm$、$n\geq1$。每个物理 wall 只计一次，不能把一个 cell 的左右墙和邻 cell
再次重复。$N_h^{\mathrm{num}}$ 只取 $\mathcal I_{512}$ finite partial sum，因此仍保持 lower
方向；它必须 finite 且严格为正。field tail 的 $n\geq1$ 和必须以 $P_\pm c_\pm$ 为新 base state
输入 $n\geq0$ doubling，不能误用 $c_\pm$ 后再减一个可能受 roundoff 污染的首项。ordinary
Gram 不是 outward lower bound。
### 6.5 Positive-factor Grams
每个 wall、circle、volume、field 和 state quadratic object 先写成 weighted linear factor $F$，
再形成
$$ W=F^*F. $$
保存 factor dimensions、$\|W-W^*\|_2/\max\{\|W\|_2,\mathrm{realmin}\}$、最小 eigenvalue
和 physical scale。Hermitian/PSD tolerance 固定为 $10^{-12}$ 乘实际 $\|W\|_2$；$W=0$
单列为合法精确零对象。显著 indefinite Gram 使相应 component 和 $q$ unavailable，禁止 clipping。
coordinate-only repeat 使用 $10^8e^{\mathrm i\pi/7}$；归一化后 defect threshold 为 $10^{-10}$，
finite failure 只记 warning。
## 7. Full-$P$ sums、tail 和无重漏索引

对每侧 propagation matrix $P$、state $c$ 和 required Gram $W$，目标和有限和为
$$ \sum_{n=n_0}^{\infty}c^*(P^*)^nWP^nc, \qquad W_N=\sum_{n=0}^{N-1}(P^n)^*WP^n, \qquad S_N(c)=c^*W_Nc. $$
doubling 必须保留 full matrix：
$$ W_{2N}=W_N+(P^N)^*W_NP^N, \qquad P^{2N}=P^NP^N. $$
不得逐 multiplier、对角化或使用 $P^{-1}$。每个 $N=2^j$、$j=0,\ldots,12$ 用两种实际
parenthesization 重算 $P_N$ 和 $W_N$，保存
$$ e_N=\|P_N^{\mathrm L}-P_N^{\mathrm R}\|_2, $$
$$ a_N^{\mathrm{hi}} =\|P_N^{\mathrm L}\|_2+e_N +100K\epsilon_{\mathrm{mach}} \max\{1,\|P_N^{\mathrm L}\|_2,\|P_N^{\mathrm R}\|_2\}, $$
$$ \omega_N =\|W_N^{\mathrm L}-W_N^{\mathrm R}\|_2 +100K\epsilon_{\mathrm{mach}} \max\{\|W_N^{\mathrm L}\|_2,\|W_N^{\mathrm R}\|_2\}. $$
若 $a_N^{\mathrm{hi}}<1$，ordinary-double allowance 和 share 为
$$ t_N(c)=\frac{(a_N^{\mathrm{hi}})^2}{1-(a_N^{\mathrm{hi}})^2} \bigl(\|W_N^{\mathrm L}\|_2+\omega_N\bigr)\|c\|_2^2, $$
$$ s_N(c)=\frac{t_N(c)} {\max\{\operatorname{Re}S_N(c),\mathrm{realmin}\}}. $$
roundoff scale 必须随 $W$ 同次缩放；$W=0$ 时 $\omega_N=t_N=0$，禁止 `max(1,norm(W))`
人为注入物理量。`tail_share_max=1e-6` 只控制 internal qualification。优先选择第一个所有 required
shares 都通过的 level；若没有但有 finite $a_N^{\mathrm{hi}}<1$ level，则选择 maximum required
share 最小者，tie 取最小 $N$，保存 warning 后继续。精确 zero residual component 合法。
若 $\operatorname{Re}S_N$ 为负但其绝对值不超过
$100K\epsilon_{\mathrm{mach}}\|W_N\|_2\|c\|_2^2$，只在 scalar contraction 中记录为
roundoff-negative 并置零；更大的负值使该 level unavailable，禁止掩盖显著不定性。
residual squared sums 使用 $\operatorname{Re}S_N+t_N$；field lower 只使用有限部分
$\operatorname{Re}S_N$，不得把上侧 allowance 加进 denominator。mandatory $W=I_K$ state tail
只建立 ordinary global summability candidate。`certified_tail=false` 始终保持。
索引冻结如下：
令 $L_{L/R}^\pm$ 是一个 lead cell 左/右 wall value-lift volume factor，$C^\pm$ 是同一 cell
的 circle-collar factor。为避免 first-cell lift double count，lead volume factors 必须固定为
$$ F_{\mathrm{vol},+}=\begin{bmatrix}C^+\\L_R^+\\L_L^+P_+\end{bmatrix}, \qquad F_{\mathrm{vol},-}=\begin{bmatrix}C^-\\L_L^-\\L_R^-P_-\end{bmatrix}. $$
$F_{\mathrm{vol},\pm}P_\pm^nc_\pm$、$n\geq0$ 逐 interface 配对内部两侧 corrections；只有
center-adjacent 的 $L_L^+c_+$ 和 $L_R^-c_-$ 作为 singleton。这样每个 circle 和每个 wall-side
correction 恰好出现一次。
| 对象 | 单列部分 | full-$P$ 部分 |
|---|---|---|
| center/first wall jump | 左右各一个 | 无 |
| center/first wall value-lift source | 左右 center-side 与 lead-side 各一个 singleton | 无 |
| lead internal wall jump | 无 | $J_\pm P_\pm^nc_\pm$，$n\geq0$ |
| circle residual | 无 | $F_\pm^\Gamma P_\pm^nc_\pm$，$n\geq0$ |
| paired lead wall/circle lift volume | 无 | $F_{\mathrm{vol},\pm}P_\pm^nc_\pm$，$n\geq0$ |
| field lower | $D_\pm c_\pm$ | $D_\pm P_\pm^nc_\pm$，$n\geq1$ |
| state summability | 无 | $P_\pm^nc_\pm$，$n\geq0$ |
internal wall jump maps 是
$$ J_+=Q_R^+ +Q_L^+P_+, \qquad J_-=Q_L^- +Q_R^-P_-. $$
center/first jumps 使用中心显式 Rayleigh derivative 和第一个 full-boundary BIE cell outward
flux 单列，不能再进入 $J_\pm$ tail。artifact 还保存前四层显式 state/action，与 doubling contractions
逐层比较，防止 left/right orientation 和 off-by-one 错误。
## 8. Internal qualification、失败语义和阶段边界

### 8.1 预注册 internal checks
在把 estimator 冻结并交给 I3.2 独立经验验证前，下列 checks 必须全部通过：
1. actual $\Delta T$ normalized defect、$\pm1/2$ signs、$\zeta=-\sigma$ 和 scale roundtrip；
2. wall fixed-density action、re-solved source 和 common-grid/gauge changes 不超过 `0.20`；
3. circle action/angular-tail、Riccati/energy checks 和 lift quadrature 达到各自冻结阈值；
4. required Grams、full-$P$ tails、phase/scale repeat 和 explicit first-level indexing 可用；
5. shared wall value、circle value、Bloch phase 和 safe-rim value/derivative identities通过。
具体 metrics 和阈值冻结如下。map comparison 默认用
$d(X,Y)=\|X-Y\|_F/\max\{\|X\|_F,\|Y\|_F,\mathrm{realmin}\}$；两侧精确零时 $d=0$。
结构零 target 用表中 nonzero reference scale；该 scale 也为零时单列 zero component。
| Metric | Scale | Threshold |
|---|---|---:|
| actual $\Delta T$ / reference change | §4.3 constituent-weighted $L^2(\mathrm ds)$ scale | $0.20$ |
| wall action/re-solve、circle action/angular-tail、cross-action、lift 16--32 | 两侧实际 map/factor norm | $0.20$ |
| low-mode modified-Bessel quotient、Riccati energy identity | analytic/numerical energy norm | $0.20$ |
| shared-wall repaired value、repaired-circle value jump | shared/raw trace map norm | $10^{-10}$ |
| Bloch value/flux | top/bottom physical trace/flux map norm | $10^{-10}$ |
| safe-rim value/derivative | interface lift norm 与 $\delta^{-1}$-scaled derivative norm | $10^{-10}$ |
| $\pm1/2$ jumps、$\zeta=-\sigma$ sign | unit-density one-sided action norm | $10^{-10}$ |
| scaled--physical roundtrip | physical matrix norm | $10^{-10}$ |
| BIE solve/backward residual | RHS/solution scaled residual | $10^{-10}$ |
| finite factor rcond、pole clearance | exact dimensionless value | $10^{-8}$ |
| circle weight 256--512 | 两侧 positive weights | $10^{-8}$ |
| Gram Hermitian/PSD | actual $\|W\|_2$；$W=0$ 单列 | $10^{-12}$ relative |
| phase/scale | 两侧实际 quadratic quantity | $10^{-10}$ |
| full-$P$ tail share | finite partial sum；zero Gram allowance 为 0 | $10^{-6}$ |
除 nonfinite/对象不可定义外，表中 finite failure 都 fail-open 保存 $q$，但禁止 `I3.2 READY`。
finite rcond/pole 只有 exact zero 才 unavailable；circle weight 必须 finite positive；显著 indefinite
Gram 才使 $q$ unavailable。
outside-$M$ share 只有描述性记录，没有 threshold，也不是 I3.2 pass gate。
这些都是同一 QZ/BIE 链的内部资格，不是 I3.2 reference 或 effectivity validation。
`independent_reference=false` 固定。finite failure 必须保存 finite $q$ 和 nominal transform，只把状态
改为 `NUMERICALLY_UNQUALIFIED`；不得为了过门修改 grid、threshold、representation 或解释。
### 8.2 真正 execution blockers
只有以下情况停止后续 stage，并保存已经形成的数据：
1. frozen input/tag/output guard、MATLAB availability 或 dimension 失败；
2. branch 非有限、精确 Wood point、wall modal block 精确奇异或 overflow；
3. required operator/action、factor 或 solve throw，或无法返回 finite objects/densities；
4. hard wall time 或 active-object memory 超限。
finite small rcond、finite solve/backward residual、有限 pole clearance、wall/circle refinement、
$\Delta T$ oracle、near-action、outside-$M$、tail share、phase/scale 等都不是 execution blocker。
### 8.3 $q$ unavailable 和 finite outcomes
下列科学对象失败使 $q_h^{\mathrm{num}}$ unavailable，但不抹去前序 diagnostics：
- exact continuous value defects 无法定义，因而不能形成 wall/circle conforming lifts；
- required wall/circle trace weights 非有限或非正；
- required norm/state tail 在冻结 levels 内没有任何 finite $a_N^{\mathrm{hi}}<1$ level；
- $N_h^{\mathrm{num}}$ 非有限或不为正；
- residual component nonfinite 或 squared-norm Gram 显著 indefinite。
若 $q_h^{\mathrm{num}}\geq1$，状态为 `FULL_BOUNDARY_BIE_RESOLUTION_INSUFFICIENT`。若 finite
$q_h^{\mathrm{num}}<1$，无论 internal checks 是否通过都保存 nominal transform；checks 失败时
状态为 `COMPUTED_NUMERICALLY_UNQUALIFIED_FULL_BOUNDARY_BIE_INDICATOR`，全部通过时状态为
`INTERNALLY_QUALIFIED_FULL_BOUNDARY_BIE_ESTIMATOR_CANDIDATE / I3.2 READY`。两种状态的所有
I3.3 reliability/existence flags 都保持 false。
I3.2 的唯一前置是：estimator 公式和上述内部资格已经冻结，能够交给未参与构造的独立 reference
检验。outward residual upper、outward field lower、certified tail、continuous projected gap 和
预注册 interval width 都属于 I3.3 的 reliable interval/existence/upper-bound 研究，不前移为 I3.2
前置。即使 ordinary interval 很窄，也不得称连续谱存在或误差上界。
## 9. 未来实现、artifact 和资源合同

### 9.1 最小文件边界
Skeptic 给出 `DESIGN PASS` 后，未来实现首选：
- `test/i3/fb-resid/check_fb_resid.m`：唯一入口；负责 frozen input、QZ/full-$P$ state、
  runtime guard、status、schema、report 和资源；
- `test/i3/fb-resid/i31_full_bie.m`：full-boundary wall modal blocks、circle Müller actions、Schur
  solve、common-grid maps 和 one-sided oracles。
入口初稿超过约 1000 行，因此实现增加 `i31_bdry_est.m`，且它只承接 boundary weights、
value-lift factors、tail Grams 和 indicator contraction 这一科学边界。不得为 abstract interfaces
或一般 utilities 继续拆分。
不得修改任何历史 design、review、MATLAB code 或 output。
### 9.2 Frozen attempt、schema 和唯一未来命令
- Attempt: `fbie-a1`。
- Schema: `TEP_I3_1_FULL_BOUNDARY_CELL_BIE_RESIDUAL_V1`。
- Output: `test/i3/fb-resid/output/fbie-a1/`；正式运行前必须不存在，运行后 append-only。
- `retry_count=0`，`prior_failed_attempt_count=0`，`prior_attempt_history` 为空 typed struct。
- 唯一未来 MATLAB 命令：
```text
matlab -batch "addpath(fullfile(pwd,'test','i3','fb-resid'),fullfile(pwd,'test','i2','k-count')); check_fb_resid('fbie-a1');"
```
在独立 spec-to-code review 通过前，该命令不获授权。
`result.mat` 至少保存：
- config、saved candidate、weighted center state、branch/Wood、$P_\pm,c_\pm,D_\pm,G_\pm$；
- coarse/official wall order sets、circle order sets、$A_{ww,m}$ pole/rcond records、Schur factor和
  solve records；
- small unit maps $\eta$、$\xi_L$、$\xi_R$，actual-state maps，common 1024 wall traces/fluxes，
  circle value/normal maps；
- scaled/physical coordinate roundtrip、$\zeta=-\sigma$、$A_{ww}$、actual $\Delta T$、one-sided
  Kress、wall/circle refinement 和 Bloch/gauge records；
- center Rayleigh field/trace/flux maps、两个 center/first value defects 和 singleton lift-source maps；
- exact-defect mathematical-definition flags、ordinary numerical lift maps、wall/circle/volume/field/state
  factors、Gram records、full-$P$ tail rows、selected levels；
- $B_h^{\mathrm w}$、$B_h^\Gamma$、$B_h^{\mathrm{vol}}$、$N_h^{\mathrm{num}}$、$q_h^{\mathrm{num}}$、
  nominal interval、coverage/reliability flags；
- typed `nonblocking_warnings`、`first_nonblocking_failure`、`first_q_unavailable_condition`、
  `first_execution_blocker`、stage completion、elapsed time 和 peak active-object memory。
不保存 full pair-kernel matrices、全部 cell densities for every tail cell 或二维 field grids。
可靠性 fields 固定为 false：`outward_residual_upper`、`outward_field_lower`、`certified_tail`、
  `outward_wall_tail`、`outward_circle_tail`、`certified_projected_gap`、`independent_reference`、
`reliable_spectral_interval`、`continuous_eigenvalue_exists`。
### 9.3 Stage 顺序和资源
未来唯一 attempt 的 stages 固定为：
1. output guard、config、candidate/QZ/branch；
2. circle/wall unit blocks、actual $\Delta T$ 和 manufactured oracles；
3. $N_w=256$ coarse solve、$N_w=512$ official solve、1024 common-grid diagnostics；
4. exact-defect maps、wall/circle lifts、positive factors 和 Grams；
5. full-$P$ tails、phase/scale repeat、$q$ 和 nominal transform；
6. append-only `result.mat` 和 `report.md`。
跑前静态估计冻结 expected wall time 为 3--8 分钟，expected peak active-object memory 为
300--450 MiB。soft/hard wall time 为 900/1800 秒。由于当前上界接近 512 MiB，hard active-object
limit 预先冻结为 **640 MiB**，不得在看结果后改变。每个 stage 前检查 soft limit；超过后不启动
新 stage。任何正式失败都只保留该 attempt，不自动 retry，不复用 tag。
## 10. Skeptic 18 门逐项闭合表

1. **目标对象：** §1 固定 saved $\widehat k_h$、连续 $R_h$、$\mathcal M/N/q$ 和谱距离；排除
   finite zero、minimizer 和 density residual。
2. **$M=48$ 语义：** §2 只用它定义 wall $g$；§4.2、§6.2 独立冻结并完整计入 circle modes。
3. **连续/有限分层：** §3.2 使用 calligraphic operators；§4.1 使用 $A_N$ 和 finite density，
   exact-kernel mathematical trial 与 512 ordinary approximation 分离。
4. **全边界与适定性：** §3.1--§3.3 给出全部 boundaries、spaces、wavenumbers、normals、
   Müller signs、wall poles 和“未证明 continuous inverse”的边界。
5. **Bloch/corners/junction：** §2、§3.1、§5.2 给出 physical/gauge、opposite top/bottom normals、
   quotient-cylinder 无 corner integral、0.3 wall--circle separation 和 finite Bloch diagnostic。
6. **Global $H^1$：** §5.1 用同一个 $g$ 和 exact value lifts 消除 wall/circle value jumps；§5.2
   用 mandatory $W=I$ state tail闭合全局 summability。
7. **完整 residual：** §2、§5.1、§6.1 明列 center field、两个 center-lift singletons、wall、circle、
   lead lifts、Bloch 结构零项及禁止漏项规则。
8. **$V'$ upper 方向：** §6.2--§6.3 给出 wall/circle basis normalization、trace constants、
   $1/R$、volume factor 和 triangle sum。
9. **Field lower 方向：** §6.4 先证明 infinite trace lower，再取 finite partial $N_h^{\mathrm{num}}$；
   冻结 half-strip 分割、每墙一次和 $Pc$ 重基。
10. **Actual $\Delta T$：** §4.3 测实际 difference block，给 Bessel/Hankel eigenvalue、独立
    mixed-derivative remainder、weighted $L^2(\mathrm ds)$、global normal、unscale、$R$ 和 near-zero scale。
11. **Wall 256/512/common-grid：** §4.2 分开 fixed-density action、re-solved source、1024 direct
    Fourier representation、physical/gauge 和 zero-component 语义。
12. **Circle bandwidth 独立：** §4.2、§6.2 分开 density/action/order/weights，全部 512 modes 入
    residual，outside-$M$ 只诊断，未算 tail 不冒充可靠。
13. **Full-$P$ tails：** §7 保留 full nonnormal matrices、doubling/allowance、scale-covariant zero
    Gram、mandatory state tail 和完整 off-by-one 表。
14. **Near/one-sided action：** §4.3 冻结 jump/Kress、S/D/dS/$\Delta T$ oracles、0.3 cross-action
    separation 和 independent source refinement。
15. **非循环/shared bias：** 摘要、§3.3、§8.1 明确 Schur 等价、same-chain checks 和
    `independent_reference=false`。
16. **Failure precedence：** §8.2--§8.3 分开 execution blocker、$q$ unavailable、fail-open
    warnings、$q\geq1$ 和 finite $q<1$ nominal transform。
17. **I3.2/I3.3 边界：** §8.1、§8.3 只把内部资格作为 I3.2 freeze 门，把 outward/gap/width
    留给 I3.3。
18. **复现/预算/append-only：** §9 冻结新 tag、schema、output guard、唯一命令、history、
    audit maps、stage 顺序、3--8 分钟和 640 MiB hard limit；spec-to-code PASS 前不运行。
## 11. 跑前审查合同

Researcher 必须复核 wall single-layer modal signs、circle Müller row signs、Schur/shared-bias、
actual $\Delta T$ oracle、lift residual 和 full-$P$ indexing。Engineer 必须复核现有 evaluator/QZ、
Kress、incident/farfield maps 与上述 finite matrices的逐项接口和静态分配。Skeptic 必须逐项审查
§10 的 18 门并给出明确 `DESIGN PASS`，之后实现仍需独立 spec-to-code review。
Design 已获 Skeptic `DESIGN PASS`；实现冻结后仍须通过独立 spec-to-code review，才可授权
唯一正式命令。当前不得运行 MATLAB/Octave，也不得创建 `fbie-a1` output。
