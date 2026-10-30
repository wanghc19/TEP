# 端点惯性实验：本轮执行规格与记录

日期：2026-10-28。用户已将原交接任务改为本轮自行完成数值验证。本文件保留原指定文件名，现作为独立实验的执行规格与结果入口，**不再交接 Claude**。目标是判断一个较宽区间内的计数方法是否可行，不追求 $10^{-10}$ 定位精度，不预设计数为 $1$。执行结果在 §8 登记。

理论合同：[[research/explorations/spectral-counting/minimal_counting_theorem]] 的 SC1；连续提升合同：[[research/explorations/spectral-counting/continuous_vs_discrete_gap]] 的 C1。实现者先读仓库 `AGENTS.md` 与 `test/AGENTS.md`。这里只读复用旧程序的数学结构，不修改旧实现、旧实验数据或 draft。

## 1. 固定模型和暂定区间

沿用当前 I10 的真实解析材料：$\beta=0.5$，$L=d=1$，背景 $\rho=1$；中心五叶形材料 $\rho_c=4$；左右不同三叶形 lead 的材料均为 $17$，基础半径 $0.2$，形状参数分别为 $0.12,0.20$。左右不通过镜像替代。完整参数以 `test/i10/refine-v1/refine_i102_config.m` 为可追溯来源；新实验必须独立保存固定后的参数。

最新已记录的 P4 候选为

$$
k_{g12}=1.5584378957007303,\quad
k_{g24}=1.5584378942105757,\quad
k_{g48}=1.5584378941804409.
$$

出处：`research/projects/eig-apost/implementation/i10/review-10-2a.md`。旧配置的 `k0=1.558438079544167` 是初值，不能冒充最新结果。候选只用于选区间，不作为真谱或计数证据。

暂定

$$
I=(a,b)=(2.40,2.46)
$$

且输入明确为 $\mu=k^2$，不要把数值 $2.40,2.46$ 当波数。该区间仅为 **DESIGN_ONLY**；尚未证明它完全在共同 gap 或无 lead pole。无需本轮另选最窄区间。若预检查发现它不可用，保留原因并提出一个仍包含候选的替代区间，不能只因计数不是 $1$ 而移动端点。

## 2. 独立实验位置、预算与复用边界

本轮新建 `test/spectral-counting/endpoint-v1/`，按 `test/AGENTS.md` 登记一次固定科学尝试。主入口采用 standalone MATLAB function，helper 沿用 `LOCAL_` 前缀及清晰 provenance header。数学依据就是本主题 SC1/C1，而非旧墙面误差修正公式。

现有 `refine_i102.m` 的主入口会执行多阶 root 搜索、预测、场恢复及 Stein 质量计算，不宜为两端惯性直接启动整套流程。只提取或复用必要的几何、网格、准周期约束、真实质量组装、lead 单胞消元与 DtN helper；复制时记录旧函数及行段，禁止静默改变物理模型。新 MATLAB 参数放在源码或显式配置函数，不读取 Markdown、Git 状态或运行清单作为计算参数。

第一轮只做 g12、P2、两个端点和两套积分规则。若资源预估允许且需要检验符号稳定性，再作同几何 g12/P3 的一次对照；不默认运行 g24/g48 或三网格全套。所有网格／阶次对照仍只是数值证据。

当前默认预算是每次尝试 30 分钟 soft、40 分钟 hard、2 GiB hard memory。I10 旧任务的 `3e9` 内存设置不是本轮授权。历史完整任务峰值约为 g12 1.663 GB、g24 1.712 GB、g48 2.509 GB，但新完整中心 LDL 有不同填充，不能直接继承旧峰值估计。先预估稀疏填充和常驻矩阵，避免密集化中心矩阵；运行器应执行资源约束。权限、路径、环境故障继续同一 attempt，不能记作新的科学实验。

## 3. 每个端点的必做计算

### 3.1 保留完整中心空间

约束后的中心矩阵来自

$$
K_c=Q_{\rm qp}^*K_{\rm full}Q_{\rm qp},\qquad
M_c=Q_{\rm qp}^*(M_{h,\rm full}+\Delta M_{\rm full})Q_{\rm qp}.
$$

必须保留真实材料质量修正 $\Delta M$。两套积分规则分别组装／评估，差值用于敏感性诊断，不能称为严格误差上界。记录质量正定性、Hermitian 缺陷和准周期约束；几何真值仍是解析材料边界，而非仅固定多边形网格。

### 3.2 两端离散 DtN

分别计算 $D_{-,h}(e)$、$D_{+,h}(e)$，$e=a,b$。现有构造的稳定图为

$$
P=Z_1Z_0^{-1},\qquad D=S_{00}+S_{01}P.
$$

保存：稳定乘子个数、QZ 齐次特征值对的归一化单位圆分离指标、单胞内部块的条件估计及求解残差、`rcond(Z0)`、Riccati 残差、DtN Hermitian 缺陷、可用时两种 DtN 公式的一致性。这里分离指标精确定义为 $\min_j ||\alpha_j|-|\gamma_j||/(|\alpha_j|+|\gamma_j|)$，不是以 $\mu$ 为单位的连续谱距。若一致性检查因为相关块病态而未执行，状态写 `NOT_EVALUATED`，不能记为通过。

严格区分三个故障：单胞内部消元图失效；稳定空间不能写成当前 Dirichlet 图；bulk 传播乘子接近单位圆。它们不是同一个物理 pole，更不能由单个阈值统称“gap 已认证”。

### 3.3 完整矩阵惯性

构造

$$
\widehat T_h(e)=K_c-eM_c+
E_W^*\operatorname{diag}(D_{-,h}(e),D_{+,h}(e))E_W,
$$

其中 $E_W$ 抽取全部左右墙面自由度。实现上只在完整中心矩阵的墙面块加 DtN。矩阵包含内部及墙面所有自由度；禁止只数旧 `lambda_all`。

对完整矩阵作 sparse Hermitian LDL。计数必须处理 $1\times1$ 与 $2\times2$ 枢轴块；不能简单数 `diag(D_LDL)<0`。报告 $(n_-,n_0,n_+)$ 或未决符号区间、分解重构残差、置换／尺度、近零阈值。普通浮点阶段的“零”应解释为阈值内未决，不是假定精确核。

保留对称化前的 Hermitian 缺陷。若数值上使用 $(T+T^*)/2$，明确保存改变量并标成矩阵近似误差，不能用对称化消除真实模型不一致。尺度诊断可用正定 $G_h=K_c+M_c$；但其数值谱余量不是 C1 的 $b_c$ 归一化余量，除非另证两范数常数。可求少量靠近零的广义特征值辅助检查 LDL，不以这些少量值代替全部惯性。

若中心内部块 $A_{II}(e)$ 可逆，额外核对

$$
n_-(\widehat T_h(e))=n_-(A_{II}(e))+n_-(F_h(e)).
$$

这是低成本记账校验。若 $A_{II}$ 在端点奇异，完整中心矩阵仍可能正则，应保留完整 LDL 结果，不因旧 evaluator 的中心消元失败就宣告计数路线失败。区间内部的中心 Dirichlet pole 无需排除。

## 4. 结果解释，不预设答案

输出

$$
N_h=n_-(\widehat T_h(b))-n_-(\widehat T_h(a)).
$$

它首先只是 **ORDINARY_DISCRETE_INERTIA_DIFFERENCE**。

- $N_h=0$：记录零差；不强行解释为已有候选不存在，也不能因候选在区间而将结果改成一。先核对区间、模型、内部惯性和 pole。
- $N_h=1$：支持下一阶段认证；暂不写“唯一简单连续模态”。
- $N_h>1$：允许多个模态或重数；不必立即精确定位所有根才能验证端点方法。
- $N_h<0$：不能解释成负模态数；检查 lead poles、完整中心记账、响应分支和数值误差。
- 任一符号未决：输出整数区间或 `UNRESOLVED`；不通过调整容差强制得到目标整数。

同一离散模型、相同基底及无离散 lead pole 的条件下，$\widehat T_h(b)-\widehat T_h(a)$ 应体现质量负单调性；可做低成本方向检查。若发现违反，不自动归因于舍入，也可能是 pole 或 DtN 分支问题。不同空间的矩阵不能逐项相减验证单调性。

无需密集扫频。宽区间的数学计数只用两个端点；若要检验整个区间的 lead 条件，应采用有证明的参数覆盖或解析排除，而不是把密集扫描伪装为证书。

## 5. 最小 gap 与 lead 正则证据

### 5.1 对连续结论的最低要求

每个 lead 在固定 $\beta$ 下，对全部实横向 $\theta$ 证明某个索引 $N_\sigma$ 的 band 上界低于 $a$，下一 band 下界高于 $b$。使用有限参数覆盖及可靠扰动半径，无需高精度定位 band edge。Hoang–Plum–Wieners 型胞元包围须包括下一本征值索引起点，不能只把现有 Ritz band 加上未经证明的误差条。

初步数值阶段可输出低成本采样与 multiplier 诊断作为可行性资料，但字段明确为 `PROJECTED_GAP_UNCERTIFIED`。若项目已有严格证书，记录证书范围和假设后复用，不重复认证。

### 5.2 独立的 half-guide 条件

解析材料表达式的静态检查已经否定每侧关于实际切口的反射对称性：$r_\alpha(\theta)=q_\alpha(1+\alpha\cos3\theta)$ 在竖直反射下余弦项变号，$\alpha=0.12,0.20$ 均非零。严格内部／外部点反例见 `continuous_vs_discrete_gap.md` §6。因此当前模型不能由奇延拓直接排除 lead Dirichlet 态；无需再用数值图像验证这条失败的前提。

记录 `LEAD_DIRICHLET_POLE_FREE_UNVERIFIED`。端点 `rcond(Z0)` 不是整个区间的无 pole 证明。需要另行的半条带谱排除或经过验证的稳定图参数覆盖；不在第一轮自动展开新大实验。若明确存在 pole，可提出分段／换切口方案，再由理论决定如何计数，禁止套用未经修正的端点差。

## 6. 交付数据与连续认证的接受标准

第一轮最小导出：

| 内容 | 必需字段 |
| --- | --- |
| 身份 | 模型参数、真实材料、$\beta,L$、两个 $\mu$ 端点、网格／阶次、积分规则、代码来源 |
| 矩阵 | 约束后 $K_c,M_c$、墙面及内部索引、两端 DtN、完整端点矩阵的大小与稀疏度 |
| 惯性 | 两端 $(n_-,n_0,n_+)$ 或区间、$N_h$、阈值、LDL 枢轴块类型和重构残差 |
| 响应诊断 | 稳定维数、单位圆分离、单胞条件数、`rcond(Z0)`、Riccati／Hermitian 检查 |
| 可选核对 | 中心内部惯性＋墙面惯性恒等式；另一阶／积分规则的结果 |
| 资源与状态 | 耗时、峰值内存、未执行检查、gap／pole／连续提升分别处于什么状态 |

不要默认保存完整场恢复、Stein 矩阵或大量扫频数据。报告中的科学结论必须由实际输出支持，不能从候选差补填未测字段。

以后只有同时满足以下条件才可输出 **CERTIFIED_CONTINUOUS_COUNT = n**：

1. 连续共同 projected gap 证书覆盖 $[a,b]$；
2. 两端 half-guide Dirichlet 谱排除覆盖整个区间，或另有经过证明的 pole 修正公式；
3. 两个端点通过 C1 或等效严格谱包围，包括所有未解析方向、精确 DtN 近似及真实材料积分；
4. 有限矩阵符号计算可靠，端点连续可逆由证书确认。

若整数为 $1$，才进一步报告唯一且简单；若为 $0$ 或更大，则照实报告。第 1–4 项在本轮仅设计，没有已完成的算例认证。

## 7. 第一轮的实际验收

第一轮成功不要求连续认证已全部完成。它应回答：完整中心与墙面惯性是否记账一致；两端离零有多大余量；宽区间的普通整数差是多少；gap／lead 正则条件有哪些现成证据；在默认资源内是否值得进入 C1 常数认证。若这些得到可重复、明确分层的结果，第一轮即有有效交付。

## 8. 实际执行记录

**已实际完成 MATLAB R2023b 的 g12/P2 验证，不再交接 Claude。** 范围为固定两个端点、两套积分规则；没有扫频、求根、场恢复或 P3／P4／网格加密实验。独立目录为 `test/spectral-counting/endpoint-v1/`。

| 积分规则 | $\mu$ | 完整中心 $(n_-,n_{\mathrm{unresolved}},n_+)$ | 中心内部 $n_-$ | 墙面 $n_-$ | Schur 核对 |
| --- | ---: | --- | ---: | ---: | --- |
| primary | 2.40 | $(0,0,1464)$ | 0 | 0 | PASS |
| primary | 2.46 | $(1,0,1463)$ | 0 | 1 | PASS |
| check | 2.40 | $(0,0,1464)$ | 0 | 0 | PASS |
| check | 2.46 | $(1,0,1463)$ | 0 | 1 | PASS |

两规则均给出 **$N_h=1$**，没有阈值内未决方向。中心内部 1416 个自由度，两面合计 48 个墙面自由度。两规则下 $-[\widehat T_h(b)-\widehat T_h(a)]$ 的普通 Cholesky 检查均通过。完整负惯性、适用的 Schur 核对及积分规则一致性已进入机器可读验收字段，不能只凭一个总标签判断通过。

端点的 $G=K_c+M_c$ 归一化近零 `eigs` 诊断分别为 $2.325374\times10^{-2}$ 和 $2.558715\times10^{-2}$（绝对值）。这些只是有限矩阵的普通诊断，**不是 C1 的 $b_c$ 谱余量或严格上下界**。两规则的完整矩阵相对差约 $3.41\times10^{-15}$，质量矩阵相对差约 $7.78\times10^{-14}$；只用于敏感性检查。

八个 lead 响应均通过当前离散 gates：稳定维数每侧为 24；归一化单位圆分离指标约 $0.4392$–$0.4584$，`rcond(Z0)` 约 $0.0433$–$0.0462$，Riccati 残差约 $4.0$–$4.6\times10^{-16}$。两种 DtN 公式检查均实际执行。这支持端点数值响应的稳定性，不能证明全参数连续 projected gap 或整段无 half-guide pole。

### 实际命令、资源及验证

受控启动器使用 Conda `octave` 环境中的 Python，启动的 MATLAB 命令为：

```sh
/Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath('/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1'); endpoint_inertia('/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1',2);"
```

首轮成功后修补了验收状态的传播和复跑进度文件的处理，在**同一 attempt** 完成一次最小复核；没有增加科学范围。首轮启动器耗时 19.710 s，最终复核 16.211 s，共享预算时间 35.921 s；最终 MATLAB 内部含输出约 2.641 s。最终采样进程树峰值为 1,236,140,032 bytes，约 1.151 GiB，未触发预算，退出码为 0。资源每 0.2 s 采样，不能宣称捕获了采样间的瞬时峰值。首次启动器实际用了系统 Python 标准库，复核已按仓库要求切换 Conda；两轮 MATLAB 科学结果一致，日志均保留。

MATLAB 因复数 sparse Hermitian LDL 支持限制，实际使用等价实化后的 sparse LDL，再将重数除以二；偶数性及因子重构已检查。计数核心还包含独立小块自检，验证 $2\times2$ 枢轴计数和复 Hermitian 实化；这不替代连续认证。

主要文件：

- [数值入口](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/endpoint_inertia.m)、[固定配置](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/endpoint_config.m)、[受控启动器](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/run_endpoint.py)。
- [可读结果](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/report-p2.txt)、[惯性 CSV](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/inertia-p2.csv)、[lead CSV](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/lead-p2.csv)、[验收摘要](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/summary-p2.json)。
- [最终运行日志](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/run-02-p2.log)、[资源记录](/Users/whc/Documents/Work/epost/test/spectral-counting/endpoint-v1/run-02-p2-monitor.json)。完整矩阵与对象保存在同目录 `results.mat`；历史来源记录在 `provenance.csv`，执行不读取该记录。

### 实验结论

**端点惯性方案在当前二维异质模型上具有低成本数值可行性，普通离散惯性差稳定为一。** 目前状态仍是 `ORDINARY_DISCRETE_INERTIA_DIFFERENCE`，并明确保留 `PROJECTED_GAP_UNCERTIFIED`、`LEAD_DIRICHLET_POLE_FREE_UNVERIFIED`、`continuous_count_status=NOT_CERTIFIED`。因此不能将本表改写为 $\operatorname{rank}\mathbf1_I(A)=1$ 已获证明。

这次实验已满足 §7 的可行性验收。下一步有价值的工作是 SC1／C1 前提的有限认证，不是继续把求根精度推高或扩大普通扫频。
