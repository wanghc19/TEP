"""Write the Chinese rounding-error estimate from measured inputs.
Input: estimates and observation JSON. Output: the authorized report and README.
"""
from pathlib import Path
from collections import Counter
from flint import arb
import json,math,csv
here=Path(__file__).resolve().parent;repo=here.parents[2]
read=lambda p:json.loads(Path(p).read_text());x=read(here/'output/estimates.json');rows=x['rows'];ex=x['extras'];q=ex['qj'];ep=ex['endpoints'];obj=read(here/'output/object-sizes.json');obs=read(here/'output/run-006/observations.json')
f=lambda v:format(v,'.6g') if isinstance(v,(int,float)) else str(v)
def table(head,data):
  return '\n'.join(['| '+' | '.join(head)+' |','|'+'|'.join(['---']*len(head))+'|']+['| '+' | '.join(str(z).replace('|','&#124;').replace('\n',' ') for z in r)+' |' for r in data])
R={r['id']:r for r in rows};minimum=x['smallest_ratio'];B=ex['B'];C=ex['C'];D=ex['D'];cost=[]
for p in sorted((here/'output').glob('run-*/monitor.json')):
  z=read(p);cost.append([p.parent.name,z['reason'],f(z['wall_seconds']),f(z['peak_process_tree_rss_gib'])])
text=r'''# 舍入误差估计

## 目的

本次估计给出主区间左、右端点的数值位移约 **%s / %s**，分别占原宽度的 **%.4f%% / %.4f%%**。这两个工作数值包含积分/装配评价，以及下文对相位、几何和节点缓存的启发式解释。

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

共有%s行，阶段分布为%s。A的两行概括每端236个矩阵，**所有472个矩阵**的逐项余量、范数、装配项、求解器项和比值均在 [A-panel-estimates.csv](../../../test/numerical-directions/rounding-estimate-v1/output/A-panel-estimates.csv)。原参考中的236是每端矩阵数。

路径 `output/`、`qj/`、`core/`、`band/` 指本实验目录；`h-cert-v1/` 等指 `test/numerical-directions/` 下的原实验。每行完整输入还保存在 [estimates.json](../../../test/numerical-directions/rounding-estimate-v1/output/estimates.json) 的同名 `id.inputs`；[estimates.csv](../../../test/numerical-directions/rounding-estimate-v1/output/estimates.csv) 是同一张表。下列四类公式给出这些输入的含义。
'''%(f(ep['L']['estimated_shift']),f(ep['U']['estimated_shift']),100*ep['L']['relative_to_own_width'],100*ep['U']['relative_to_own_width'],len(rows),'、'.join(k+' '+str(v) for k,v in Counter(r['stage'] for r in rows).items()))
text+=r'''
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

'''
# Full table: compact numeric inputs with the complete JSON path attached.
input_keys=['n','nd','P','q','J','kappa','matrix_norm1','Cminus_norm1','value','p','qnorm1_scaled','rnorm1_scaled','positive_Q_scaled','large_terms_squared_scaled','basis_terms_squared_scaled','field_terms_squared_scaled','quadrature_path','eQ','eR','eZ','eLambda_scaled','dimension','center_norm1','total','Ch','qmax','detmin','h_estimate','absolute_E_poly_moments','absolute_C0_arcs','E','M','S','roundE','roundM','roundS','path_assumed','stored','power_norm','Pnorm2','coefficients','error_inputs','absolute_term_sum','relative_effect']
data=[]
for r in rows:
  inp=r['inputs'];pairs=[k+'='+f(inp[k]) for k in input_keys if k in inp]
  if not pairs:pairs=[k+'='+f(v) for k,v in inp.items() if isinstance(v,(int,float))][:8]
  pairs.append('全输入: '+r['id']+'.inputs')
  data.append([r['stage']+' / '+r['id'],r['quantity'],f(r['margin']),r['formula'],'; '.join(pairs),f(r['estimate']),'∞' if r['ratio'] is None else f(r['ratio']),r['source']])
text+=table(['阶段/ID','量','余量/准确度预算','估计公式','输入','估计舍入效应','比值','源码或JSON来源'],data)+'\n'
text+=r'''

100项旧清单的逐项去向见 [inventory-map.csv](../../../test/numerical-directions/rounding-estimate-v1/output/inventory-map.csv)。其中根、线性方程求解、通量极小化、插值系数、近似特征向量都是自由试探数据的选择，不需要把“解的误差”再次当作残差误差。整数RT3参考迹恒等式、整数拓扑计数是结构项。BIE/Hankel只用于独立参考，不进入这条链；没有为它编造舍入预算。B2的整数相等只在两端Schur符号稳定时保持。PSD的零特征值也不作为严格正余量：G/R是精确模型中的Gram，原浮点中心的极小负值用扰动尺度解释，不裁剪后冒充新的输入。

## 区间端点

'''
text+='名义积分与总估计如下。E/M行同时列出原截断半宽，便于看到算术估计是否超过已有准确度。\n\n'
text+=table(['量','名义值','原截断半宽或数值','纯评价舍入估计','对象备注加入量','采用总估计'],[
  ['E',f(q['E']),f(R['qj-E']['margin']),f(q['arithmetic_errors'][0]),f(q['object_E_effect']),f(q['roundE'])],
  ['M',f(q['M']),f(R['qj-M']['margin']),f(q['arithmetic_errors'][1]),f(q['object_M_effect']),f(q['roundM'])],
  ['S+',f(q['S']),f(q['S']),f(q['arithmetic_errors'][2]),f(q['object_S_effect']),f(q['roundS'])]])+'\n\n'
text+=r'''E/M的主要求和是非负项；同一积分内的多项式、质量修正和残差形成过程不同。172756个单元实例按“256个Gauss点—每模板最多6410元—13胞—3模板”的层级计，工作路径长度6682。曲边E的系数绝对矩总和为3.61480；公共残差的多项式绝对矩诊断为2.15995e-7，包含同一上下文中少量taper辅助调用，按偏大的尺度使用。质量带积分的正负项绝对和2.12142e-6、净和3.01746e-8，抵消约70.3倍；C0弧积分的绝对和为3.06288e-8。C0中 $c-\Pi_2c$ 的消减用坐标尺度0.4另估，贡献2.2354e-13，超过其最后求和项的估计。

RT3基评价的绝对平方尺度实测为2.88412e9；这正是不能把小S本身乘 $\gamma_n$ 的原因。公共S采用该尺度和 $\gamma_{1000}+100e_x$。界面部分抽样每模板4弧，共12弧；相减前尺度358.694按320/4=80外推，再乘10的工作放大量。这个10没有统计置信度含义，也没有保证覆盖未抽样弧。界面误差估计7.03e-15；公共S估计约2.92e-13，占主要部分。若不接受这项抽样外推，需对全部界面弧累计同样的尺度统计，而不是提高求和精度。

实际Gauss规则以512位Legendre根及权重公式对照，2至104阶最终比较器半径都小于1e-80。16阶节点最大差2.88618e-16、权重最大相对差1.73073e-14；实际C规则16至77阶的相应最大量见 `gauss-checks.json`。下游对同一规则取实测差的2倍作工作输入；这是校准选择，未使用较大的通用后向模型项当作已达到的实际误差。包含Duffy因子 $(1-x)$ 的相对变化。E/M额外规则估计分别为2.12215e-12、8.91156e-13。节点的导数放大按E的20倍绝对多项式尺度、M的16倍尺度，以及残差的100倍基项尺度估计。B的Gauss40误差小于已采用的共同 $\gamma_{8n+Pq+8J}$ 尺度。

设 $q=1+E/M$、$d=qS/M-(q-s)^2/s^2$、$D=q-t-td$，$F_t=q-1+qtd/D$。本次用256位评价导数：
$$F_q=1-t^2\delta(1+\delta)/D^2,\qquad F_\delta=qt(q-t)/D^2.$$
再用 $q_E=1/M$、$q_M=-E/M^2$，
$$\delta_E=q_ES/M-2(q-s)q_E/s^2,\quad \delta_M=q_MS/M-qS/M^2-2(q-s)q_M/s^2,\quad \delta_S=q/M.$$
于是端点估计为 $|F_E|e_E+|F_M|e_M+|F_S|e_S$，并加 $\gamma_{100}|F|$ 的末次评价项。固定s是自由试探参数，不要求它等于精确q。窗口端点对F的影响约 $F_t'=q^2d/D^2$ 乘端点的ulp误差，量级低于1e-23。

'''
data=[]
for key in ['L','U','I1L','I1U']:
  e=ep[key];data.append([key,format(e['value_float'],'.17g'),', '.join(format(float(arb(v).mid()),'.12g') for v in e['gradient']),f(e['estimated_shift']),f(100*e['relative_to_own_width'])+'%',str(e['active_corner'])])
text+=table(['端点','重新评价的名义中心','对E、M、S的导数','估计位移','占本区间宽度','名义活动角'],data)+'\n\n'
text+='主区间若把两端估计方向都按外移相加，宽度改变量约%s，即原宽度的%.4f%%。这只是工作估计，不把两个新数当作包含区间。\n\n'%(f(ep['L']['estimated_shift']+ep['U']['estimated_shift']),100*(ep['L']['estimated_shift']+ep['U']['estimated_shift'])/4.462331640314124e-9)
text+=r'''I1采用 $q(1+\delta/2\pm\sqrt{\delta+\delta^2/4})-1$，对S的导数约 $\pm85080$，故绝对位移较大，但仍只占其自身宽度约0.0254%。同一批E/M/S的四角重新评价与给定I1简写的末位相差约2.3e-13、3.3e-13；当前没有独立I1 JSON可追溯这几位的生成方式，不将该差认作纯舍入观测。它比本次位移估计小约八万倍，且I1离窗口边界至少0.686。

## 数据可容许性

这里只作O(u)扰动备注，不建立几何、空间或谱的扰动定理。目标场可由共享主节点和整数RT3基定义；它的单项式缓存、几何节点和相位是近似评价。以下量是实际测量或明确的启发式效果估计。

'''
text+=table(['项目','测量','采用的启发式效果或处理'],[
  ['Bloch相位',f(obj['phase_error'])+'；模平方偏差 '+f(obj['phase_modulus_squared_error']),'相位差除以sqrt(det_min)作局部梯度尺度；E影响 '+f(q['phase_E_effect'])],
  ['曲线节点公式',', '.join(f(v) for v in obj['curve_error_by_template']),'公式取值及物理胞平移的采样。'],
  ['实际二次图的节点像',', '.join(f(v["actual_geometry_node_error"]) for v in obj['field_conversion']),'每模板640个界面顶点/中点，匹配全部相邻单元像；局部应变按max差/sqrt(det_min)，E影响 '+f(q['geometry_E_effect'])],
  ['P3节点→单项式','V的∞条件数432；最大全节点重建差 '+f(max(z['exact_nodal_reconstruction_error'] for z in obj['field_conversion'])),'全部172756个单元实例，192位有理V重算；质心几何估计梯度变化平方 '+f(obj['gradient_change_squared'])+'，E影响 '+f(q['nodal_conversion_E_effect'])],
  ['RT3参考基','参考系数为整数；普通边共享主矩','整数性保留参考法向迹；精确Bloch相位和Piola公共几何仍是对象定义的一部分。缓存求值抵消进入S估计。'],
  ['C右侧实际墙迹','重复胞 '+f(read(here/'output/run-008/science/result.json')['trace_check']['bulk_wall_actual'])+'；首/重复胞 '+f(read(here/'output/run-008/science/result.json')['trace_check']['first_wall_actual']),'对应场Frobenius范数9.67767 / 204.504；均小于本文场评价项。这个检查不是重复计算同一乘积得到0的旧wall_match。'],
  ['精确端口修正','独立FE迹差约8.97e-16；保留Fourier差约7.44e-17','解析g与FE修正目标应使用同一表达式。误差纳入C的相减前尺度。'],
  ['D代表函数kappa','绝对差最大 '+f(obj['max_kappa_error'])+'；beta绝对差 '+f(obj['max_beta_error']),'Riesz代表恒等式发生O(u)偏离；用解析Gram绝对包络的7.69e-9项计入其工作尺度。'],
  ['D中的H=I','原浮点检查norm1(H-I)=5.04249e-14','直接作用尺度约7.74e-13，另加入解析H/M1/迹映射评价估计；没有将H-I当严格0。']])+'\n\n'
text+=r'''上述曲线测量只比较插值节点；二次弧相对真弧的截断缺陷仍由原截断项处理，不能用节点误差代替整弧误差。节点转换比较不是只比较两个double求值：本次导出全部主节点和系数，在192位下以精确有理插值点重建差，再用质心Jacobian和精确参考多项式矩计算局部变化尺度。它衡量缓存评价误差；曲边全积分和连续空间修补没有在此重做。共享拓扑、非曲线中点、曲线材料标签等原构造继续作为同一对象的定义；不能把“浮点检查为0”解释为精确相位或精确真曲线。

标量和JSON交接使用完整double，只有报告显示采用`.12g`等简写。MAT-v7和JSON的读取保持原double，主要效应来自交接前运算。本次D的epsilon在MAT/JSON间逐位一致，C的Q、Lambda条目和r在两层JSON间逐位一致。最后一次减/加epsilon仍产生微小的双向舍入：Q_minus最大对角差3.33e-15，R_plus约1.02e-22，Z_plus约2.77e-17；“full precision”不等于定向舍入。$K_+=279.899894626$ 相对精确有理公式值的名义上取余量约7.80e-11，对本次1e-11工作估计的比值约7.8；$K_-=0.70782$ 有更大的余量。若后续希望减少这项敏感性，可以使用279.9并一致重算C中的Z；单看 $K r$，增加约4.10e-12，远低于C的间隙。这里没有改旧输入。

主区间简写端点向内约8.60e-15、2.30e-14，远小于本次端点位移估计。无论使用何种误差路线，正式显示都应交代打印精度；完整JSON中的数值与简写显示不是同一组十进制端点。

## 观测与估计的对比

'''
dat=[]
for key,z in x['observations'].items():dat.append([key,f(z['observed']),f(z['estimate']),f(z['estimate']/z['observed']) if z['observed'] else '∞','通过' if z['pass'] else '未通过'])
text+=table(['比较','观测差','对应估计','估计/观测','核查'],dat)+'\n\n'
text+=r'''A比较的是第68面板、a=0.20下端的**固定导出矩阵**，double值为-0.00013972238243961722，高精度逆迭代值为-0.00013972238428734948，192位残差约2.36e-45。这个比较只检验特征值计算项，未把矩阵装配也改成高精度。

E/M/S比较使用同一批已积分项。正序、逆序显式循环、升/降序NumPy和、math.fsum及192位和均保留。Python的内置sum可能含补偿，本次“顺序循环”明确使用逐项加法。观测只能检查固定项的累加；上游被积函数、几何、整数基内部抵消另按前文估计。

D的8a试点给的是固定矩阵的0.36536998下端数字；它距double第二值约3.71e-6，这个差是所选shift的松量，不能当舍入误差。本次另以192位Rayleigh值0.36537368878193222644对照double的0.36537368878193166；向量残差约2.19e-15，使用邻近间隔0.353346估计其Rayleigh向量效应约1.36e-29。它与8a数字相容。本次固定矩阵实部与8a导出逐位相同，虚部条目未超过原最大值；这只解释固定矩阵对照。

要求的复现：原SciPy A程序给1.397223838884971e-4，与参考的相对差2.25e-10；D给0.3653736908439648，相对差0。两者达到1e-9要求。MATLAB仅值eig和带向量eig分别偏离A参考约1.06e-8和5.01e-9，没有达到那一相对门槛，均保留；其绝对差在同一矩阵的求解器舍入估计内。没有通过改求积或移动参数让它贴合参考。

按同样的输入改变量重算全部角点，输入敏感度线性项与有限改变量的相对差：主区间小于3e-11，I1约2.54e-4。末次公式求值项另外相加；记录在 `finite-sensitivity.json`。

## 结论

'''
text+='全表最小比值为 **%s**，对应D近贴边移位：第二方向约1.00e-10，估计效应约%s。这个移位不足以支持其最后几位。改用0.36时，间隔%s，比值%s；不必保留1.1e-10的LDL枢轴作为精度目标。\n\n'%(f(minimum['ratio']),f(minimum['estimate']),f(R['D-wide-shift']['margin']),f(R['D-wide-shift']['ratio']))
text+='A/B/C/D所用有限矩阵的原点符号在这些工作估计下均有余量。E的舍入估计约为其原截断半宽的%.2f倍，故E±的末位精度不能只用截断半宽描述；M的比值约%s。由端点敏感度得到的估计位移仍约为W的0.20%%/0.235%%。\n\n'%(R['qj-E']['estimate']/R['qj-E']['margin'],f(R['qj-M']['ratio']))
text+=r'''若目标只是评估舍入敏感性，本次估计支持采用较宽D移位并保留主区间的数值尺度。若要求原来的十位D下端数字或要求去掉“舍入排除”，这些估计不够；特别是可容许性备注和界面抽样因子没有被改写成包含结论。

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

'''
text+=table(['运行','结束状态','墙时/秒','峰值/GiB'],cost)+'\n\n'
text+='MATLAB全部运行合计%s秒，最高峰值%s GiB。节点转换的高精度全数据诊断%s秒；固定矩阵/求和对照%s秒；B矩尺度%s秒。\n\n'%(f(sum(float(r[2]) for r in cost)),f(max(float(r[3]) for r in cost)),f(obj['seconds']),f(obs['seconds']),f(read(here/'output/B-scales.json')['seconds']))
text+=r'''## 未决问题

- 500/1000/10000路径常数、1 ulp库模型及界面12弧外推是工作选择；只要把它们当作未经核验的可靠常数，就超出了本阶段结论。B的XDC缓存采用原粗尺度，估计可能明显偏大；若需要缩小，应导出逐系数绝对和。可按需重做全弧尺度统计或更细的逐核误差分析。
- 质心Jacobian用于节点转换后的能量变化估计；几何/相位的H1与H(div)修补只作局部尺度解释，未建立无限条带上的扰动定理。
- A的不同eig驱动不满足同一1e-9相对复现门槛；已有高精度固定矩阵对照说明差值属于求解器尺度。以后比较这类小余量，应同时给绝对误差和矩阵范数。
- I1未保留独立全精度生成记录，给定参考末位与本次统一四角计算有约3e-13差异。该差不影响窗口包含的数值估计，但生成方式仍需经理核对。
- 本阶段没有改变区间或(H)的数学状态，也没有把新的工作数值写回旧实验输入。
'''
(repo/'research/explorations/numerical-directions/rounding-estimate.md').write_text(text)
readme='''# rounding-estimate：舍入误差估计

本实验估计四角Goerisch区间及隔离假设(H)计算链的舍入效应。结果是估计，不给出可靠误差界。A/B/C/D分别指周期带隙、表面态、Dirichlet-to-Neumann矩阵、核心计数；qj指Goerisch量q和J。

## 入口

- `launch.py`：调用原monitor.py启动复制的MATLAB浮点代码；11线程，OMP_DYNAMIC=FALSE，软30分钟、硬40分钟、3 GiB。
- `high_precision_checks.py`：固定A/D矩阵和相同非负项的观测对照。
- `object_sizes.py`：主节点与缓存转换、相位/几何/代表函数的测量。
- `B_scales.py`：B曲线积分绝对项尺度，不重解响应。
- `estimate_analysis.py`、`write_report.py`：汇总估计、敏感度和报告。

## 结果与复现

完整公式、表、命令和运行成本见 [rounding-estimate.md](../../../research/explorations/numerical-directions/rounding-estimate.md)。主端点估计位移%s / %s，占原宽度%.4f%% / %.4f%%。D近贴边移位的比值%s；0.36移位的比值%s。观测对照均低于对应估计。

## 启动前预估

A：30–120秒、0.7–1.2 GiB。D：20–60秒、0.8–1.4 GiB。qj正项/模型：240–420秒、2.1–2.7 GiB。场数据导出：90–180秒、1.8–2.4 GiB。C首轮尺度：每侧3–8分钟、1.8–2.6 GiB；补充绝对基项：每侧6–12分钟、1.8–2.6 GiB。每侧累计预计低于30分钟。B的Python尺度诊断：10–60秒、0.2–0.5 GiB。Gauss导出：15–30秒、0.6–0.9 GiB；512位对照预计5–30秒、0.2 GiB。

复现入口（完整运行参数表见上述报告；运行目录须用新编号）：

```sh
python3 test/numerical-directions/rounding-estimate-v1/launch.py --help
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/estimate_analysis.py --experiment test/numerical-directions/rounding-estimate-v1
conda run -n octave python -I test/numerical-directions/rounding-estimate-v1/write_report.py
```

## 记录

`output/estimates.json`和CSV保存每行公式和输入；`A-panel-estimates.csv`保存472个面板符号。MAT为MATLAB-v7，仅作为可重生输入。run-011/012/013为Python汇总中的标量/维度/序列化错误记录，run-017记录Gauss比较器的区间包裹；MATLAB运行均完成。`setup_runs.py`是初始复制脚本，已保护为不能覆盖现有源；复现直接使用上述入口。
'''%(f(ep['L']['estimated_shift']),f(ep['U']['estimated_shift']),100*ep['L']['relative_to_own_width'],100*ep['U']['relative_to_own_width'],f(minimum['ratio']),f(R['D-wide-shift']['ratio']))
(here/'README.md').write_text(readme)
print('wrote',len(rows),'rows',len(text),'characters')
