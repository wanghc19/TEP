# 舍入认证清单

## 目的

共100行，覆盖 qj、A、B、C、D 和标量/矩阵交接。默认71项 E1、7项 E3、9项 E4、10项 E0；另3项为诊断或可选快速分支。E2 不作为默认必需路径。现有四角区间与 (H) 均尚未去掉舍入排除，本清单没有把它们升级为计入舍入的结果。

依据为 [paper.tex 第3–6节](../../../draft/fem-goerisch/paper.tex)、[OP-ND-5](../../projects/eig-apost/implementation/open-problems.md:132)、[qj-bounds-proof.md 定理6.1](qj-bounds-proof.md) 和 [h-cert-proof.md §2–6](h-cert-proof.md)。本文只作清点、工具检查和可选的有限矩阵试点；数值实现写在后续阶段。

四类依赖：1为数据对象本身的可容许性，2为评价与组装，3为符号/惯性/几何决定，4为超越函数、常量及交接。E0 表示精确结构或任意试探数据的选择无需认证求解过程；E1 用 python-flint 重算；E3 用近似因子/向量加严格残差验证；E4 作有向交接。表中 other 的诊断不进入最终证书。

## 工具检查

两项均通过。`conda run -n octave python -I` 在沙箱中直接导入 python-flint 0.9.0、numpy 2.5.4、scipy 1.18.1。MATLAB 经提权的 monitor.py 启动，11线程、OMP_DYNAMIC=FALSE，14.2205秒、峰值0.639786 GiB。`save(...,'-v7')` 的实数与复数矩阵，分别将实部、虚部与 MATLAB 同次导出的 uint64 位模式比较，全部逐位一致；包含极大/极小正规数及最小次正规数。double 到 Arb 与其精确二进制有理数比较也通过。

记录在 [smoke-results.json](../../../test/numerical-directions/rounding-v1/probe/smoke-results.json) 及 [run-001/monitor.json](../../../test/numerical-directions/rounding-v1/probe/run-001/monitor.json)。这个检查证明导出层保持数据，不证明任意派生数组是可容许对象或已向外舍入。

本机 `arb_mat` 没有直接暴露 Cholesky/LDL 方法；有 `eig/inv/solve`，`acb_mat.eig` 可选 rigorously enclosed 的默认/Rump算法，也有明确不带误差的 `algorithm='approx'`。高重根需处理 cluster。可以用近似 Cholesky/LDL 或向量作为数据，再以球残差认证；不必逐个隔离全部1122个特征值。

复现工具检查：

```sh
python3 test/numerical-directions/rounding-v1/probe/smoke_launch.py --output test/numerical-directions/rounding-v1/probe/run-001
conda run -n octave python -I test/numerical-directions/rounding-v1/probe/python_smoke.py test/numerical-directions/rounding-v1/probe/run-001/science/smoke.mat test/numerical-directions/rounding-v1/probe/smoke-results.json
```

重跑 MATLAB 检查使用未占用的运行编号。

## 总表

以下是一张按阶段排序的完整表。成本为实施后的单阶段预计运行范围，尚未测量；共享步骤的成本不能逐行相加。工程工时另列。相对余量只在给定尺度内有意义；未保留范数/分母的地方明确记为未知。

余量代号及 JSON 来源：

- **QE/QM/QF/QI**：`test/numerical-directions/qj-cert-v2/output/run-004/science/interface-certificate.json` 的 `full_interval.E`、`M/mass_bias`、`full_interval.signs/L/U`、`templates.min_selfmap_margin/min_actual_branch_margin`。QE半宽2.00018e-12、相对1.7437e-13；QM半宽6.90203e-12、相对1.46136e-12；QF最小12符号0.945405；QI最小自映射0.0315321、实际分支0.0515773。
- **QS/QG/QTaper**：同次 `certificates.json` 的 `S_smooth`、`templates.geometry`，以及 `interface-certificate.json` 的 `templates.smooth_taper_remainder/taper_correction_bound`。QS公共S上界2.5978064967e-10；公共区间相对宽约9.47e-7。原逆延拓最小自映射0.0154489。G的相对Jacobian余量可从同目录 `*-geometry.csv` 的同元 det_min/det_max 读取。**QT**：同次 `exact-flux.json`，外墙主矩0、共享主边重建差0；这些零只覆盖当前构造中的浮点相位。
- **QFirst**：`draft/fem-goerisch/paper.tex:300` 的一阶交集区间；当前 qj JSON 未单列此对象，后续须重新导出证书。
- **AR**：A 没有既存运行 JSON，现数字来自 `h-cert-proof.md:1853` 及 MATLAB/原 Python 源码；下端1.3972238392e-4、上端7.5205045129e-3。表中没有伪造一个已测得的相对矩阵余量。后续必须逐面板记录矩阵norm和有向符号界。
- **BR/BB/BH/BG**：`h-cert-v1/output/run-009,010,007,011/science/result.json`，依次为0.12下/上端、0.20下/上端；字段 `gram_cancellation_ratio/eps_*/tests.gamma/tail/d_per/form_inverse`。最小BB为run-007、M10的0.00428912961539；以该JSON中 C/E 的绝对行和0.543877386455作参考尺度，相对值0.00788621。BG 的附加响应界没有被主链采用。
- **CT/CG/CR/CI/CP/CH/CL**：`h-dtn-v1/output/run-006,008/science/result.json` 的 `trace_check`、`first/bulk`、`r/K_r/gap`、`eps_Q/eps_R/eps_Z`、`series_weight_bound`、`A_H`、`min_lower_raw`；幂/几何补充值在 `h-dtn-v1/output/run-011/science/fe-dtn.json` 的 `series/geometry`。CR约3.8954e-8，K r约1.0903e-5；CI量级分别1e-14、1e-14、1e-12；CH=0.99970696205。
- **DR/DH/DC/DD/DP**：`h-core-v1/output/run-002/science/result.json` 的 `tail_Gram_min`、`H_defect`、`c_W/delta`、`gamma_2/epsilon/safe_margin`、`shifted_min_abs_pivot`。DD为0.365373690844减2.06203317645e-9；DP为1.10754385685e-10。DI为 `material.normalized_error=1.22086658301e-10`。**SM**为本次 smoke JSON。

派生余量、来源及几何同元比值另存 [inventory-margins.json](../../../test/numerical-directions/rounding-v1/probe/inventory-margins.json)，它是对已有记录的提取，不是新的舍入认证结果。

| 阶段 | file:line | 量 | 类 | 操作与规模 | 所进入的不等式 | 当前绝对/相对余量及来源 | 处理 | 预计成本 | main risk |
|---|---|---|---|---|---|---|---|---|---|
| qj | [qj_run.m:12](../../../test/numerical-directions/qj-cert-v2/qj_run.m#L12) | 浮点搜索、根和互补能量极小元 | 1 | P3 g48；27胞；RT3稀疏解 | 只选试探数据；无需把求解误差当证书 | 无独立余量；误差最终进入 QE/QS | E0：保留浮点解的独立主自由度；任意近似解均可，后验积分另证 | MATLAB重生约2分钟 | 导出派生缓存而非主数据 |
| qj | [direct_native.m:650](../../../test/numerical-directions/qj-cert-v2/direct_native.m#L650) | 精确 Bloch 相位 | 1 | 每模板上下节点识别；exp(i/2) | v 属 H1_beta | 存档 phase mismatch=0 只比较同一个浮点相位；不证明精确等式 | E1：导出 master/top/bottom 整数拓扑，Python以精确beta=1/2重建从属节点 | 秒级，随场导入 | 零浮点跳跃掩盖真实相位差 |
| qj | [direct_native.m:62](../../../test/numerical-directions/qj-cert-v2/direct_native.m#L62) | 芯区与27胞节点连续 | 1 | 每墙144节点；公共墙向量 | v 跨胞 H1 | 当前检查用1e-10容差；几何和共享关系见 QT | E1：导出每个全局节点唯一主值；墙面从同一对象复制，恢复精确相位后再建单元值 | 1–3分钟 | 独立恢复的两侧墙值产生微小跳跃 |
| qj | [direct_pipeline.m:564](../../../test/numerical-directions/qj-cert-v2/direct_pipeline.m#L564) | P3节点到局部单项式系数 | 1 | 每单元10系数；浮点 Vandermonde 右除 | v 单元边上的完全相等 | QT；已有 evaluator tolerance=1e-10 是诊断 | E1：由共享节点与精确有理 P3 Lagrange 转换重算；不冻结 field_coefficients | 1–5分钟 | 逐单元浮点系数独立冻结会失去连续性 |
| qj | [direct_native.m:277](../../../test/numerical-directions/qj-cert-v2/direct_native.m#L277) | 原网格界面节点与二次曲边 | 1 | 3模板，每界面320弧 | 原曲线必须是证明中 Pi2 c | QG：det>=7.7317e-6；相对尺度见数据表 | E1：导出角度整数索引；真曲线节点/中点用 Arb 重建；普通顶点可取精确 dyadic | 1–5分钟 | 把旧浮点曲线点误称为真曲线点 |
| qj | [direct_native.m:317](../../../test/numerical-directions/qj-cert-v2/direct_native.m#L317) | 整数网格拓扑与材料分区 | 1 | 3模板；边关联、边界环、曲边拥有者及rho标签 | 网格覆盖无重叠，积分使用实际材料分区 | 整数边关联可精确检查；位置/分区余量未逐项导出，QG只含局部几何界 | E1：冻结整数三角形表；精确查边关联/闭环，以球证有向面积及界面两侧归属；无须认证Delaunay算法本身 | 1–5分钟，随几何 | 只验证每元正Jacobian却未证明全局覆盖和rho标签 |
| qj | [goerisch_fitted_geometry.m:31](../../../test/numerical-directions/qj-cert-v2/goerisch_fitted_geometry.m#L31) | 拟合真界面与 Piola 几何 | 1 | r^3(c-Pi2c)；3模板 | 单元内rho常数及全域连续几何 | QG；界面几何模型 min margin 见 QI | E1：同一真弧端点对象共享；重算所有映射系数；r=0用连续延拓，r>0不设1e-14阈值 | 随几何认证 | 冻结原节点却重新计算c会使端点不重合 |
| qj | [exact_rt3_basis.m:7](../../../test/numerical-directions/qj-cert-v2/exact_rt3_basis.m#L7) | 整数 RT3 参考基 | 1 | 24x24整数；最大系数69552 | 参考法向迹为(2m+1)Legendre，内部迹零 | QT：72项整数恒等式；严格余量不适用 | E0：整数系数和边反向奇偶因子精确；保留现有整数检验 | 小于1秒 | 整数基只解决参考迹，不解决相位或几何 |
| qj | [direct_pipeline.m:686](../../../test/numerical-directions/qj-cert-v2/direct_pipeline.m#L686) | 全局边主系数和外墙零通量 | 1 | 共享边12矩及每单元12内部系数 | p 属 H(div)，外墙法向为零 | QT：外墙主矩0；当前相位是浮点exp | E1：只冻结全局边/内部主系数；精确相位、整数方向因子和同一 Piola 边图重建 | 1–5分钟 | 冻结 local(1:12) 会保存浮点约束缺陷 |
| qj | [taper_certificate.m:11](../../../test/numerical-directions/qj-cert-v2/taper_certificate.m#L11) | 截断函数、支撑与导数 | 1 | x=11.5,13.5；27胞；cos/sin | v 紧支撑且H1，零延拓可容许 | taper端点恒等式精确；QS预算 | E1：分段端点用精确有理数；端点值/导数直接设精确1/0；内部 trig 用Arb | 并入 taper，5–20分钟 | 舍入后的 cos(pi) 不能作为精确零约束 |
| qj | [geometry_certificate.m:34](../../../test/numerical-directions/qj-cert-v2/geometry_certificate.m#L34) | 二次 Jacobian 全域极值 | 3 | 每模板约6400个2次式；边/内驻点 | det_min>0 | QG：最小7.7317e-6；同元 lo/hi 需另导出 | E1：区间判别驻点是否在三角形；不确定分支全部保留或细分；证逆分母 | 1–5分钟 | 近零判别或漏掉边界驻点 |
| qj | [geometry_certificate.m:12](../../../test/numerical-directions/qj-cert-v2/geometry_certificate.m#L12) | 原/拟合映射全域单射 | 3 | 2x2范数与三顶点界 | eta_native<1，eta_fitted<1 | QG：1-eta >=0.884879/0.992338，均以1归一 | E1：固定浮点逆作精确 dyadic 预条件；Arb验证残差范数和逆界 | 1–5分钟 | 只验Gauss点不能替代全域界 |
| qj | [qj_certificates.m:149](../../../test/numerical-directions/qj-cert-v2/qj_certificates.m#L149) | 仿射分类与多项式精确性 | 3 | midside==edge midpoint；公共单元 | 阶16无截断误差 | 当前 literal affine，非容差；QE/QS | E1：按共享几何表达式证明等式；否则走曲边分支。积分用精确有理矩而非浮点Q16 | 秒至分钟 | 接近中点不等于仿射 |
| qj | [direct_pipeline.m:552](../../../test/numerical-directions/qj-cert-v2/direct_pipeline.m#L552) | Gauss/Duffy节点及权重 | 2 | Q16/Q24及辅助高阶规则 | 正权规则、精确性及余项 | 节点自身无现成误差界；QE/QS预算 | E1：用Legendre根的Arb隔离与正权公式；多项式类改用有理单项式矩 | 缓存每阶，秒级 | 把浮点节点当精确Gauss节点 |
| qj | [poly2.m:11](../../../test/numerical-directions/qj-cert-v2/poly2.m#L11) | 二维多项式模型系数 | 2 | 系数至13x13；conv2/加法/删项 | 系数球+统一余项包围真函数 | QI；未记录每次系数的舍入半径 | E1：arb/acb系数；整数二项式/阶乘；乘积删项取上界并单独保留截断余项 | 移植1–2天，运行20–120分钟 | 系数球宽与模型余项混为一项后重复或漏计 |
| qj | [poly2.m:17](../../../test/numerical-directions/qj-cert-v2/poly2.m#L17) | 倒数、sin/cos、Bernstein范围 | 2 | 倒数/三角16或18阶；范围转换 | d0>0，k<1，lower>0 | QG/QI；逐面板最小 reciprocal lower 未保存 | E1：所有中心、系数、norm和尾项以球计算；用严格上/下端比较，失败则精度提升或保留细分 | 并入模型 | midpoint比较或旧e=0被误当无舍入 |
| qj | [curve_model.m:9](../../../test/numerical-directions/qj-cert-v2/curve_model.m#L9) | 真弧 Taylor 系数与曲线缺陷 | 4 | 3x320弧；18阶；exp/factorial | c、c_u、d、d_u 一致包围 | QI；最小 taper 截断项可到1e-24，不是舍入预算 | E1：pi、角度、模型参数取精确语义；Arb exp；系数球半径与解析Taylor尾分开 | 1–5分钟模板缓存 | 用json中的浮点D0继续称上界 |
| qj | [poly2.m:42](../../../test/numerical-directions/qj-cert-v2/poly2.m#L42) | 曲边原能量有理积分 | 2 | 分母几何级数最高60阶；逐元累加 | E_- <= E <= E_+ | QE：半宽约2.00e-12，相对1.74e-13 | E1：分子先组装；Arb多项式矩、上取尾项及全局求和 | 5–30分钟 | 平坦双精度累加可能超过现有半宽 |
| qj | [qj_certificates.m:26](../../../test/numerical-directions/qj-cert-v2/qj_certificates.m#L26) | 原网格质量的精确多项式类 | 2 | 27胞；多项式 degree<=8 | M_nat 两侧界 | QM：最终半宽6.90e-12，相对1.46e-12 | E1：从主节点重建系数，以有理三角矩球积分；exactness只取消截断误差 | 1–10分钟 | 把浮点Q16值当精确值 |
| qj | [taper_certificate.m:14](../../../test/numerical-directions/qj-cert-v2/taper_certificate.m#L14) | taper E/M/公共 S | 2 | 4个外侧胞；解析chi与chi_prime | E/M/S 分项界 | QTaper：残差截断项约8.47e-24；非舍入余量 | E1：Arb复算三角模型与残差分子；小项仍有独立球半径 | 5–20分钟 | 极窄截断区间不会自动容纳双精度误差 |
| qj | [qj_certificates.m:64](../../../test/numerical-directions/qj-cert-v2/qj_certificates.m#L64) | 公共单元残差平方 | 2 | RT3/P3；先残差后平方 | S_common 上界 | QS：2.5978064967e-10；现有区间宽约2.46e-16 | E1：从同一场/通量系数复算小分子，禁止用大Gram相减替代 | 5–30分钟 | 大项相减后才包围会损失全部残差精度 |
| qj | [interface_model.m:23](../../../test/numerical-directions/qj-cert-v2/interface_model.m#L23) | 逆映射猜测与常逆预条件 | 1 | 每面板2变量12阶猜测；18步选择 | 猜测可任意；最终缺陷另证 | QI：最终自映射最小0.0315321 | E0：可以冻结猜测多项式和B为 dyadic 数据；无须认证产生猜测的 Newton 步 | 导出秒级 | 把猜测e=0理解为真逆已经精确 |
| qj | [interface_model.m:29](../../../test/numerical-directions/qj-cert-v2/interface_model.m#L29) | 压缩、自映射、共同单射域 | 3 | 960弧；两个native分支；固定cube | kappa<1、自映射、真逆在保留cube | QI：0.0315321、实际分支0.0515773；旧v1更小0.0154489 | E1：球复算J、I-BJ、最终缺陷和Bernstein范围；模糊布尔全部保留 | 10–45分钟 | 接近边界时只保留猜测所在分支 |
| qj | [interface_fields.m:1](../../../test/numerical-directions/qj-cert-v2/interface_fields.m#L1) | native分支场及taper组合 | 2 | 每弧/每胞；v、梯度和相位 | 界面延拓的同一原场 | QI/QS；无需guess本身精确 | E1：共享P3节点转换后作球多项式复合；真几何系数贯穿 | 并入界面20–120分钟 | 冻结局部多项式破坏场的统一定义 |
| qj | [interface_residual.m:9](../../../test/numerical-directions/qj-cert-v2/interface_residual.m#L9) | 拟合界面残差分子及积分 | 2 | 12阶模型；2残差分量+散度项 | S_int 上界 | QI：3.4977344097e-11；超额4.28e-14，相对0.001225 | E1：逐系数球算残差再平方、倒数、积分；维持分支差抵消 | 20–120分钟 | 区间依赖膨胀；首选192/256位 |
| qj | [interface_certificate.m:72](../../../test/numerical-directions/qj-cert-v2/interface_certificate.m#L72) | 薄层覆盖与全分支修正 | 3 | 960弧；2 native x2 fitted；u细分 | 真实分支均被覆盖，Jac绝对修正安全 | QI：实际分支余量>=0.0515773 | E1：按既有全部分支保留；区间比较含糊时继续保留，不用点归属猜测 | 5–30分钟 | 小于浮点位置容差的薄层被漏掉 |
| qj | [interface_certificate.m:76](../../../test/numerical-directions/qj-cert-v2/interface_certificate.m#L76) | 质量 C0、局部 V/L/D0/D1/Q1 与偏差 | 2 | 逐u子区间，复数模与带符号Jac | C0 ± B_e 包围真质量修正 | QM：bias=6.80236e-12，预算余量2.59764e-12(27.6%) | E1：先球构造Jac和分支差，再取上界；所有模、根、乘积向外 | 5–30分钟 | 质量半宽不能再用旧自愿1e-13代替舍入界 |
| qj | [qj_certificates.m:125](../../../test/numerical-directions/qj-cert-v2/qj_certificates.m#L125) | 模板/胞元总和与 E/M/S端点 | 2 | 约1.7e5三角形实例；多层分项 | E下/上、M下/上、S上 | QE/QM/QS | E1：Arb层次求和；保留每类半径。E2平坦sum不推荐 | 1–5分钟 | 未计累加误差或把估计误差下取 |
| qj | [four_corners.m:8](../../../test/numerical-directions/qj-cert-v2/four_corners.m#L8) | 12个严格符号 | 3 | 4角 x H/D_mu/-D_nu | 四角定理前提 | QF：最小0.945405；按项绝对和归一需重导出 | E1：arb逐角严格正；M_->0；保留所有分母球不跨零 | 小于1秒 | 以all(midpoint>0)替代球的严格正 |
| qj | [four_corners.m:10](../../../test/numerical-directions/qj-cert-v2/four_corners.m#L10) | q、delta及稳定端点 | 2 | 4角；公式(6.8) | L下取、U上取；避免qJ-1 | QF：W=4.46233e-9，相对mu约1.84e-9 | E1：复算delta=q S/M-(q-s)^2/s^2及稳定F；端点用球外端点 | 小于1秒 | Decimal只有高精度，没有自动定向包围 |
| qj | [paper.tex:283](../../../draft/fem-goerisch/paper.tex#L283) | 独立一阶谱交集 I1 | 2 | q、delta 的单调上界；sqrt | Theorem S.2 的独立存在性输入 | QFirst：I1宽1.003e-4，距窗口边至少0.686 | E1：用同一可容许数据和E/M/S球重算一阶谱交集；再验包含于A带隙及H窗口 | 小于1秒 | 只转抄旧I1会使最终H仍带舍入前提 |
| qj | [interface_certificate.m:48](../../../test/numerical-directions/qj-cert-v2/interface_certificate.m#L48) | BIE参考与Q16/Q24诊断 | 4 | mu_BIE、重复规则、根差 | 不进入证明，仅诊断 | BIE containment 非证明余量 | other：保持诊断标记；本链无Bessel/Hankel认证需求，参考值不用于校准界 | 0 | 把参考精度当谱证书 |
| A | [band_reproduce.m:5](../../../tmp/h-cert-check/band_reproduce.m#L5) | 精确平面波空间 | 1 | 169模，整数(m,n)，正交L2归一 | 带隙有限补空间分解 | 无H1拼接问题；A符号另证 | E0：导出整数模式和定义；exp(i(2pi m+theta)x+i beta_n y)按精确公式定义 | 0 | 冻结采样值会丢掉精确Bloch相位 |
| A | [band_reproduce.m:8](../../../tmp/h-cert-check/band_reproduce.m#L8) | 118相位面板完整覆盖 | 1 | 整数端点乘pi/4096 | 有限相位检验覆盖[0,pi] | 端点整数连续，覆盖恒等式精确 | E1：整数端点E0，pi及中心/半径球重建；不要冻结最后端点float(pi) | 秒级 | 最后一小段因pi下舍入而未覆盖 |
| A | [band_reproduce.m:51](../../../tmp/h-cert-check/band_reproduce.m#L51) | 真三叶形与曲线矩 | 2 | 2材料，25x25频率，2048节点 | 指标矩阵B的包围 | AR：原始JSON未留；截断约1e-86 | E1：Arb重建R_a、sin/cos/exp及曲线导数，零频用pi/25 | 1–5分钟 | 把曲线求值和积分中心的舍入漏在解析尾项外 |
| A | [band_reproduce.m:11](../../../tmp/h-cert-check/band_reproduce.m#L11) | 曲线梯形解析余项及传播 | 4 | EPS_B_ENTRY、169倍范数、M/G | B/M/G 安全误差方向 | AR：最终下余量1.3972e-4，上7.5205e-3 | E1：pi、expm1、乘积幂用球上端；中心积分的球半径另加 | 小于1秒 | 极小解析尾项不能覆盖浮点中心误差 |
| A | [band_reproduce.m:16](../../../tmp/h-cert-check/band_reproduce.m#L16) | M和G=B-B^2 | 2 | 2个169x169复矩阵 | 补空间下界和Gram | AR；G结构PSD，不要求浮点G严格正定 | E1：球乘法/结构Gram及统一范数余量；不截断负浮点特征值 | 1–5分钟 | B-B^2相减与PSD误判 |
| A | [band_reproduce.m:21](../../../tmp/h-cert-check/band_reproduce.m#L21) | 面板中心、波数平移与K | 4 | 118面板，low/high、pi、beta | 相位Lipschitz覆盖 | AR：KLOW-r>0；最小值未单列保存 | E1：KLOW=659/500、KHIGH=19/8精确语义；所有平方与min取安全端 | 秒级 | 先冻结low/high再继续用原覆盖证明 |
| A | [band_reproduce.m:25](../../../tmp/h-cert-check/band_reproduce.m#L25) | 遗漏谱尾与分母 | 3 | 169模，tail-17 high | c_I>0 | AR：最小1572.32；相对tail未保存 | E1：区间min的下界与high上界；所有除法前严格正 | 秒级 | min函数选错区间端或漏掉边界分支 |
| A | [band_reproduce.m:30](../../../tmp/h-cert-check/band_reproduce.m#L30) | 下端有一个负方向 | 3 | 236个169阶矩阵 | lambda_1(T_low)<0 | AR：1.3972238392e-4；矩阵范数未保存 | E3：浮点近似负特征向量只作数据；Arb Rayleigh严格负即可 | 1–5分钟 | 近似特征值本身不带误差 |
| A | [band_reproduce.m:30](../../../tmp/h-cert-check/band_reproduce.m#L30) | 上端第二特征值正及惯性 | 3 | 236个169阶 Hermitian | lambda_2(T_minus)>0 | AR：7.5205045129e-3；相对范数未保存 | E3：浮点LDL/特征基预条件，Arb残差和验证可逆；只需计数无需隔离所有高重根 | 3–15分钟 | cluster使直接全谱eig认证费时 |
| A | [band_reproduce.m:47](../../../tmp/h-cert-check/band_reproduce.m#L47) | Hermitian化与矩阵误差 | 2 | 169x169共472个 | 安全下矩阵 | AR；无舍入界 | E1：共轭转置与半和球化；反Hermitian残差并入范数，不只忽略imag | 秒至分钟 | 条目对称后仍需覆盖组装误差 |
| A | [h-band-reproduce.py:105](../../../tmp/h-cert-check/h-band-reproduce.py#L105) | 带边及d_per交接 | 4 | 下带1.318^2，上带2.375^2 | B/C使用的谱距离 | AR：d_minus=0.005276，d_plus=0.023725 | E4：输出精确有理端点及严格面板测试；d取下界，K取上界 | 小于1秒 | 四舍五入距离上取会把K下取 |
| B | [h_bloch.m:119](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L119) | 响应线性求解与多项式系数 | 1 | N26，2809x21，6系数x64面板 | 任意全线H2试探响应 | BR：求解误差只影响残差，不必认证求解本身 | E0：冻结 zc 为精确dyadic多项式系数；插值节点和求解可继续浮点 | MATLAB两必要下端约15分钟 | 误把派生XZ缓存也当任意可选数据 |
| B | [h_bloch.m:92](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L92) | Bloch基、规范因子、相位面板 | 1 | 64面板，全x Fourier，beta=1/2 | 响应严格H2及两相位 | 端点匹配无需相位多项式导数连续 | E1：从整数m/n、精确pi面板、theta变量重建规范；zc只作为系数 | 并入相位评价 | 冻结exp(i theta)会改变形式残差问题 |
| B | [h_bloch.m:43](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L43) | 曲线材料矩阵X | 2 | 105x105频率表；2809阶Toeplitz；2560点 | 真实rho质量乘子 | BR：曲线矩解析余项1.86e-99至7.44e-98 | E1：曲线/零频面积球化；缓存矩频率表，避免逐条目重复transcendental | 5–30分钟 | 巨大稠密acb矩阵占用和重复代价 |
| B | [h_bloch.m:64](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L64) | 非紧支撑源及双侧几何级数 | 2 | 21源，两个纵向分母，0模例外 | F=V_lambda T 与源Gram | BR：最小分母可由1-exp(-kappa)显式给；当前未单列 | E1：两个分母分开严格包围；保留零模非紧支撑项；exp负实参数球化 | 10–45分钟 | 反射替换或漏掉一侧/零模尾 |
| B | [h_bloch.m:104](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L104) | d_per、K、kappa与谱权重 | 4 | 两端点；sqrt/exp/min | 周期形式逆及残差放大 | BH：d=0.005276/0.023725；K约520.79/279.90 | E1：从精确带边和lambda重算；d下界、K上界，不能只转读double | 秒级 | 使用打印距离而非同一精确lambda |
| B | [h_bloch.m:124](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L124) | XC/XDC/XLC 缓存产品 | 2 | 每case384次2809^2 x21 | 物理乘子X作用到试探多项式 | BR：残差Gram抵消比149–349 | E1：球Toeplitz卷积或经严格误差包围的缓存；zc任意但Xzc不可任意 | 每case0.5–4小时，待标定 | 逐节点重做稠密球乘法会放大时间 |
| B | [h_bloch.m:196](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L196) | Gauss相位节点和正权 | 2 | 40阶及64面板；归一1/(2pi) | 相位积分及解析规则余项 | BR：相位余项 eps_H~1e-13–1e-12 | E1：球隔离Legendre节点、权重；精确面板仿射变换；缓存所有40阶节点 | 秒至分钟 | 冻结浮点节点后原Gauss精确性不成立 |
| B | [h_bloch.m:76](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L76) | 作用量与残差 G0/G1 | 2 | 每case2560次 nd x21、21阶Gram | quadratic residual identity(3.20) | BR：体残差范数0.47–8.45；抵消比149–349 | E1：保留多项式相关性，球复算已固定Z与真实源；不能把线性求解残差设0 | 每case0.5–3小时 | 大Gram抵消和系数依赖 |
| B | [h_bloch.m:152](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L152) | delta及Poisson对偶Gram H/H2 | 2 | 21阶；Dtail固定于面板 | 下端E=K H；上端二次Poisson E | BR：下端E_norm=0.00789/0.01419；上端0.00238/0.00884 | E1：先保留小投影残差，再计算G0-delta*delta项的球界；所有尾分母下取 | 每case10–60分钟 | 去掉有限残差或把Gram差当精确PSD |
| B | [h_bloch.m:131](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L131) | Dtail及复椭圆分母测试 | 3 | 64固定面板；inverseD=1/(.25-strip^2) | theta解析延拓无零点 | BH：.25-strip^2约0.24966；Dtail最小需重导出 | E1：球验证正分母与面板固定min；模糊比较取更宽安全分母 | 秒级 | 直接把绝对值min函数延拓进复平面 |
| B | [h_bloch.m:127](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L127) | 相位/曲线统一余项 | 2 | bounds zb/rb，A^8，阶40因子 | C±E 的Loewner包围 | BR：eps_C~1e-19，eps_H~1e-13；主余量BB | E1：Frobenius和所有norm取上界；曲线eps和相位eps外加球中心半径 | 分钟级 | 现有极小解析eps无法掩盖BLAS误差 |
| B | [h_bloch.m:168](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L168) | C_hat、E和Hermitian Gram组装 | 2 | 21x21；四case；另取M8/10 | C-E <= exact C <= C+E | BB：最小gamma=0.00428913，相对行范数约0.00789 | E1：形成Hermitian球中心+范数半径；误差矩阵保证PSD上界 | 秒至分钟 | 逐条目实部下舍入不是Loewner下界 |
| B | [h_endpoint.m:34](../../../test/numerical-directions/h-cert-v1/h_endpoint.m#L34) | h_M、x_M、t_M与尾罚项 | 4 | M8/10；sqrt/exp，有限max | 高块t>0，Schur罚项x^2/t | BH：t_M约0.5；M10罚项2.74e-12/1.24e-11 | E1：有限极值全算球；t下界、x上界、罚项上界 | 秒级 | t被打印成0.5并误认为精确等式 |
| B | [h_endpoint.m:8](../../../test/numerical-directions/h-cert-v1/h_endpoint.m#L8) | 四case的Schur惯性和gamma | 3 | 17/21阶矩阵 | B1/B2：两个Schur同负指标 | BB：最小0.00428912961539；rel约0.007886 | E3：主路线m=0用验证Cholesky/Arb严格谱下界；上端与M8为交叉检查 | 小于1分钟 | 把普通eig结果当严格正 |
| B | [h_endpoint.m:18](../../../test/numerical-directions/h-cert-v1/h_endpoint.m#L18) | 响应Gram及粗B3常数 | 3 | 21阶U/H/H2最大特征值 | 可选(3.25) K=364/576分支 | BG：当前实际主链采用单调K=279.9 | other：非必要分支保留浮点标签；若也要认证这些附加界，需E1+E3上谱界 | 省略可少做两个上端响应 | 错误地把未认证的附加数当主链输入 |
| B | [h_analyze.m:30](../../../test/numerical-directions/h-cert-v1/h_analyze.m#L30) | 零负指标单调延伸与K+ | 4 | 两材料下端m=0；距上带边 | P与d_half>=0.023725 | BH：K精确公式279.8998946259；采用279.9安全 | E4：严格验证下端Schur>0后用理论推论；距上下谱的min下取再K上取 | 秒级 | 只保留两端相同数字却没有可逆性证书 |
| C | [dtn_native.m:1899](../../../test/numerical-directions/h-dtn-v1/dtn_native.m#L1899) | P4解、QZ和自由内部场 | 1 | g48；192墙节点；2模板 | 仅选择半引线可容许试探场 | CP：P^128范数<6.49e-16；求解本身无需认证 | E0：冻结独立内部节点与P；不认证QZ谱，另验证有限幂收缩 | MATLAB两侧约20–40秒 | 把QZ稳定性当连续谱证明 |
| C | [dtn_native.m:1906](../../../test/numerical-directions/h-dtn-v1/dtn_native.m#L1906) | 首/重复胞精确墙迹 | 1 | Uwall=[I;P]，共享P | 无限胞H1拼接 | CT：浮点迹约9e-16；结构约束应精确 | E1：只导出内部行和P；墙行按同一I/P对象构造，再以精确相位展开 | 1–5分钟 | 独立冻结UbaseP和UbaseG会产生胞壁跳跃 |
| C | [dtn_flux.m:12](../../../test/numerical-directions/h-dtn-v1/dtn_flux.m#L12) | 通量墙面递推约束 | 1 | N0=Nb G，Fb=Nb P；192状态 | 无限胞H(div) | CT：wall_match当前0只因同一浮点公式 | E1：导出Nb主矩与内部系数；Fb、N0在Arb由同一P/G计算，禁止冻结缓存 | 1–5分钟 | 矩阵乘法缓存误差被当精确法向连续 |
| C | [dtn_flux.m:7](../../../test/numerical-directions/h-dtn-v1/dtn_flux.m#L7) | RT内部预条件和残差极小化 | 1 | 24局部基；全局边解 | 任意内部系数均可 | 整数RT参考迹；主链只需最终残差 | E0：将最终整数基中的内部系数作为dyadic；QR/Chol不需验证最优性 | 浮点导出秒级 | 再次导入预条件基会恢复法向缺陷 |
| C | [dtn_geometry.m:28](../../../test/numerical-directions/h-dtn-v1/dtn_geometry.m#L28) | 拟合几何及Bloch识别 | 1 | 6410/6392单元；真曲线 | rho常值与共享Piola边图 | CG：eta<=0.14125；delta_det见表 | E1：真弧节点符号重建；非界面三角形显式仿射；相位按beta=1/2 | 1–5分钟 | 冻结曲线端点又重算中点会不闭合 |
| C | [dtn_integrate.m:66](../../../test/numerical-directions/h-dtn-v1/dtn_integrate.m#L66) | 精确33迹与端口修正 | 1 | 11低迹实际FE差；22解析迹 | 每个u_i在端口精确等于g_i | CT：误差8.97e-16，retained约7.45e-17 | E1：从重建后的同一FE场定义g_h，再作g_exact-g_h；rational节点、kappa、指数均球化 | 5–20分钟 | 冻结trace_values却更换了内部场定义 |
| C | [dtn_integrate.m:87](../../../test/numerical-directions/h-dtn-v1/dtn_integrate.m#L87) | 首胞裁剪和积分片覆盖 | 3 | xi=1/8与横向端口分段 | 每片单一解析分支 | CG：曲线胞离修正带>=0.124864 | E1：拓扑裁剪平面精确；近零交点/面积用有理或球保守保留，不能舍弃小片 | 分钟级 | 浮点符号判断遗漏极薄积分片 |
| C | [dtn_bounds.m:12](../../../test/numerical-directions/h-dtn-v1/dtn_bounds.m#L12) | 复几何单射、det和逆界 | 3 | 2x2逆；产品Bernstein椭圆2 | eta_ref/eta_phys<1，det>0 | CG：最小det7.7317e-6；1-eta>=0.858752 | E1：球计算所有矩阵范数、Taylor尾及clearance；可以用固定浮点逆预条件 | 1–5分钟 | 旧sqrt/norm下取使分母不再安全 |
| C | [dtn_integrate.m:32](../../../test/numerical-directions/h-dtn-v1/dtn_integrate.m#L32) | 有限元/RT评价与小残差 | 2 | 首胞33列，重复胞192列 | Q、R、Z 的正确被积函数 | CR：r约3.8954e-8；K r约1.0903e-5 | E1：先在球中形成grad u-p及div p+lambda rho u和z，再Gram；分块coef复用 | 两侧合计1–6小时，待标定 | 逐点纯Python循环或大项独立包围 |
| C | [dtn_integrate.m:27](../../../test/numerical-directions/h-dtn-v1/dtn_integrate.m#L27) | Gauss节点/权重与多项式类 | 2 | 首胞51–77阶；重复胞16–54阶 | 正权及2q精确性 | CI：原eQ~3e-14，eR~2e-14，eZ~2e-12 | E1：复用统一球Gauss；仿射多项式改精确有理矩；其余每片节点球化 | 并入C积分 | 冻结节点后继续声称零多项式积分误差 |
| C | [dtn_integrate.m:53](../../../test/numerical-directions/h-dtn-v1/dtn_integrate.m#L53) | 复椭圆余项及自适应阶数 | 2 | 逐元 M_Q/R/Z/E 与32*2^-2q | Q±eQ I、R/Z安全上界 | CI；阶数上限104，实际<=77 | E1：阶数可由浮点选择，但以所选阶数复算Arb余项；不把目标tol当已达误差 | 1–10分钟 | ceil/log2选阶误差未用最终余项兜底 |
| C | [dtn_run.m:57](../../../test/numerical-directions/h-dtn-v1/dtn_run.m#L57) | Stein倍增及有限幂收缩 | 3 | 192x192，L=128 | 无穷尾与每胞误差放大 | CP：eta<=6.48635e-16，1-eta约1；放大2.02/2.75 | E1：P视为精确dyadic；球重算幂、W、Gram和上范数；严格eta<1后用尾式 | 1–10分钟 | 幂的下溢不能用不含下溢的gamma_n模型 |
| C | [dtn_run.m:22](../../../test/numerical-directions/h-dtn-v1/dtn_run.m#L22) | 高频解析列尾与交叉项 | 4 | 6<=abs(k)<=16；exp(-2kappa) | eQ/eR/eZ加上遗漏低高交叉 | CI/CR：保留K r的预算裕量约3.89e-4 | E1：所有指数、sqrt、范数及Cauchy平方根上取；极小值不可下溢到0 | 秒至分钟 | 将极小的正尾置零使上界变小 |
| C | [dtn_run.m:29](../../../test/numerical-directions/h-dtn-v1/dtn_run.m#L29) | 高模提升常数和AH | 4 | M16；a=L=1/8 | AH=aH-K bH^2>0 | CH：AH=0.99970696205，bH^2=1.09938e-9 | E1：Arb下aH/AH、上bH^2/K；先证正分母再取商上界 | 秒级 | AH由两个四舍五入标量相减 |
| C | [dtn_run.m:30](../../../test/numerical-directions/h-dtn-v1/dtn_run.m#L30) | Q-/R+/Z+与Lambda下矩阵 | 2 | 两侧33x33 | Theorem C.3 全迹下界 | CL：最小普通eig左0.411019/右0.337890 | E1：Hermitian中心加减经证明的谱范数半径；矩阵球计算最终式 | 秒级 | 逐条目下舍入不是Loewner下舍入 |
| C | [dtn_run.m:32](../../../test/numerical-directions/h-dtn-v1/dtn_run.m#L32) | 残差范数、PSD和间隙 | 3 | 33阶相似缩放；R中心极小特征值 | 范数预算；R/Z为精确Gram PSD | CR：右R浮点-4.49e-22；间隙1.09308e-5 | E3：Gram PSD可用构造证明；需数值谱界时验证R+或加norm半径；诊断负值不得截零 | 小于1分钟 | 对秩亏Gram要求严格Chol或误把容差当证书 |
| C | [report_dtn.py:15](../../../test/numerical-directions/h-dtn-v1/report_dtn.py#L15) | JSON矩阵交接 | 4 | 33x33复条目与eQ/eR/eZ | 下界方向传给D | CI；当前json是nearest浮点，没有方向 | E4：交付dyadic Hermitian中心+单独有向半径/精确端点，不把shifted数组重舍入后直接当下界 | 秒级 | 在Python列表中减epsilon再次向内舍入 |
| D | [core_space.m:4](../../../test/numerical-directions/h-core-v1/core_space.m#L4) | cosine/Fourier与端口代表 | 1 | (31,16)+66代表；1122维 | 包含全部r_pm,k使补空间迹精确为0 | DR：33个2阶余项Gram min0.00496401 | E1：模式整数E0；pi、sqrt和双曲函数定义为精确解析对象并球求值；不能冻结采样r | 1–5分钟 | 冻结近似kappa会破坏Riesz代表恒等式 |
| D | [core_space.m:13](../../../test/numerical-directions/h-core-v1/core_space.m#L13) | 浮点基变换P及H=I | 1 | 每k 2阶Chol；P稀疏1122阶 | H为能量Gram，空间不改变 | DH：浮点H-I的1范数5.04e-14；不等于严格0 | E1：推荐冻结P作dyadic预条件，复算H=P*HrawP并计H-I；或重新定义精确解析正交化P | 1–5分钟 | 把冻结P和理想H=I同时使用 |
| D | [core_space.m:12](../../../test/numerical-directions/h-core-v1/core_space.m#L12) | 线性独立与代表子块正性 | 3 | 33个2x2余项Gram | V_h独立，变换可逆 | DR：min0.00496401；各block相对条件未保留 | E3：2阶球Chol/行列式检验，或验证冻结三角P可逆；不以eig浮点最小值为证 | 秒级 | 减去投影的抵消使小Gram半径变大 |
| D | [core_space.m:16](../../../test/numerical-directions/h-core-v1/core_space.m#L16) | 解析M1与B_pm | 2 | 稀疏raw Gram和33x1122迹映射 | M^q和端口代表恒等式 | DH：独立M1检查误差6.37e-14 | E1：Arb公式、共享r对象；所有P乘积球化；移除H=I假设的遗漏 | 1–10分钟 | Q和B用不同版本的P或代表函数 |
| D | [core_space.m:18](../../../test/numerical-directions/h-core-v1/core_space.m#L18) | a_star、C_h、cW与delta | 4 | 有限min、pi、sqrt | cW>0，补空间质量膨胀 | DC：cW=0.9976782510；delta=0.0023271520 | E1：精确Nx/Ny/beta/sigma/lambda；a_star下取，C_h^2上取，cW下取 | 秒级 | 相同打印值不是同一精确模型常量 |
| D | [core_curve.m:15](../../../test/numerical-directions/h-core-v1/core_curve.m#L15) | 真星形指数矩与strip余项 | 2 | 89199矩，512节点；零分母面积 | Mstar 的包围 | DI：raw余项2.3447e-13，归一后1.22087e-10 | E1：Arb参数/curve/exp；零a,b以结构标签识别；保留offset缩放和ysym | 5–30分钟 | 以接近零的数值阈值替代精确零分母分支 |
| D | [core_material.m:31](../../../test/numerical-directions/h-core-v1/core_material.m#L31) | 频率组装和误差行和 | 2 | 1122阶实矩阵；P范数上界520.69 | &#124;&#124;Delta Mstar&#124;&#124; <= epsilon_star | DI：加倍变化9.82e-15；已有界1.22e-10 | E1：球条目与向上绝对行和；P范数仅用严格上界；对称化误差保留 | 1–10分钟 | 把浮点moment_count或err当实际球误差 |
| D | [core_run.m:11](../../../test/numerical-directions/h-core-v1/core_run.m#L11) | 端口边界项与Chol输入 | 2 | 两33阶Lambda，1122阶边界Gram | B* Lambda B 的下界 | CL：输入Lambda最小0.337890；DH | E1：直接复算B*Lambda_lower B；若保留chol构造，需验证其剩余误差，不能默认R*R等于Lambda | 1–10分钟 | 普通chol误差悄悄改变了已给下界 |
| D | [core_run.m:18](../../../test/numerical-directions/h-core-v1/core_run.m#L18) | eigs/SVD和mu_2诊断 | 1 | 1122维；低秩66白化 | 只选特征向量/shift | DD：mu2=0.499135，delta=0.002327；非必要证书 | E0：近似向量任意精度均可；eigs residual数字只能作初猜，真正符号走E3 | MATLAB约14秒 | 残差小不保证特征值序号 |
| D | [core_run.m:23](../../../test/numerical-directions/h-core-v1/core_run.m#L23) | H-Mq/cW+boundary 与误差矩阵 | 2 | 1122阶复Hermitian | L_cert <= 真有限下界 | DD：gamma2=0.365373691，epsilon=2.06203e-9 | E1：由全部上游球矩阵重建；若P冻结则加H-I；先球组装再选择Hermitian中心与范数罚项 | 5–20分钟 | 只认证导出的最终浮点矩阵，遗漏前面的组装误差 |
| D | [core_run.m:42](../../../test/numerical-directions/h-core-v1/core_run.m#L42) | LDL惯性计数 | 3 | 1122阶，1/2阶枢轴 | n(L_cert)<=1 | DD：负1；普通最小绝对枢轴0.410451 | E3：浮点LDL/Chol预条件，Arb验证因子残差及符号；不能只验D的浮点符号 | 试点Arb 2.07秒，含监控17.55秒 | 近零2阶块或不受控的逆因子范数 |
| D | [core_run.m:25](../../../test/numerical-directions/h-core-v1/core_run.m#L25) | 第二特征值的近贴边shift | 3 | gamma_safe约0.365373690744 | lambda2>=gamma_safe-epsilon | DP：shift后最小枢轴1.10754e-10；比例约3.0e-10 | E3：先用较宽shift如0.36验证核心结论；需要原数字时再收紧并验证，不复用普通LDL枢轴 | 较宽shift试点已验证，见下文 | 为保留十位数字无谓耗掉原本0.365的间隔 |
| handoffs | [qj_run.m:9](../../../test/numerical-directions/qj-cert-v2/qj_run.m#L9) | 统一模型常量和端点语义 | 4 | alpha-/+、a、rho、beta、尺度、周期 | 所有阶段必须是同一个模型 | alpha_minus literal与1.32^2相差ulp的风险 | E1：统一精确有理模型：alpha-=1089/625，alpha+=56169/10000，beta=1/2，a=3/25或1/5；pi用arb.pi | 一次schema，秒级 | 把模型常量和可自由冻结的试探系数混淆 |
| handoffs | [qj_run.m:17](../../../test/numerical-directions/qj-cert-v2/qj_run.m#L17) | 固定s与浮点根 | 4 | s=3.4287286707248672 | S(s)与四角使用同一个s | s>0且接近q；无需s等于真q | E0：s和任意试探系数可从-v7精确变为dyadic Arb；根仅用于选择场 | 0 | 复算q后顺手改变s，却沿用旧通量/残差 |
| handoffs | [interface_certificate.m:47](../../../test/numerical-directions/qj-cert-v2/interface_certificate.m#L47) | E-/E+、M-/M+、S+跨目录 | 4 | 6个标量及每类分项 | 四角单侧界 | QE/QM/QS；现JSON无有向标签 | E4：输出下端向下、上端向上；保存端点dyadic/球及方向，不能只输出midpoint | 秒级 | 直接解析旧nearest JSON为Arb不会生成遗失的误差 |
| handoffs | [h_bloch.m:104](../../../test/numerical-directions/h-cert-v1/h_bloch.m#L104) | A到B/C的带边与d_per | 4 | 1.318和2.375两带边；两个距离 | 逆常数分母 | BH：0.005276/0.023725 | E4：带边用有理常量和通过的谱证书；距谱量下取、除法和K上取 | 秒级 | 在跨阶段再平方时改变端点 |
| handoffs | [h_endpoint.m:17](../../../test/numerical-directions/h-cert-v1/h_endpoint.m#L17) | B到C的K+、K-及矩阵norm | 4 | K+=279.899894626；K-=0.70782 | C的两侧误差系数 | K+比精确公式多约7.5e-11；K-裕量约1.25e-5 | E4：在Arb中用确切d重新求上界；标量近似可只作为选择，不作为已证上界 | 秒级 | JSON显示位数不能代替上取证明 |
| handoffs | [report_dtn.py:29](../../../test/numerical-directions/h-dtn-v1/report_dtn.py#L29) | C到D的复下界矩阵 | 4 | 2个33阶Hermitian | 全迹Loewner下界 | CL/CI；当前numpy式shift只是nearest | E4：导出精确Hermitian中心+独立谱半径；D再用球表达center-radius I；存相位/索引schema | 秒级 | 实部逐条目向下不等于矩阵向下 |
| handoffs | [report_core.py:25](../../../test/numerical-directions/h-core-v1/report_core.py#L25) | D的epsilon、gamma与最终结论 | 4 | 1122阶误差norm、LDL结果 | gamma2>epsilon及n<=1 | DD/DP：安全第二下界0.365373688682 | E4：gamma用严格下界、epsilon用严格上界；数值报告按外端点格式化，附E3结果 | 秒级 | 把特征值显示值最后一位当已认证下界 |
| handoffs | [write_v2_report.py:14](../../../test/numerical-directions/qj-cert-v2/write_v2_report.py#L14) | 最终L/U和宽度打印 | 4 | L约2.4287286692，U约2.4287286737 | 输出的闭区间确实包含 | run-004/analysis.json scalar_decimal：简写L/U向内8.60e-15/2.30e-14，分别约宽的1.93e-6/5.16e-6 | E4：从Arb lower/upper定向十进制输出；若转double用nextafter并回验包含；宽度也球化 | 秒级 | nearest显示端点不能直接作为证书端点 |
| handoffs | [direct_native.m:792](../../../test/numerical-directions/qj-cert-v2/direct_native.m#L792) | 统一精确/球求积规则 | 2 | Legendre40/77/24等阶；多阶段复用 | Gauss正权、精确性和余项 | 现有规则无球半径；各阶段预算不同 | E1：一次验证节点和权重的根隔离/公式；并复用精确有理矩；不依赖scipy节点的正确舍入 | 一次0.5天，运行秒级 | 同阶不同目录各自冻结一套规则 |
| handoffs | [pm.m:45](../../../test/numerical-directions/qj-cert-v2/pm.m#L45) | 非负余项与全局聚合 | 2 | 模型尾、逐元/逐面板误差和 | 所有上界保持上取 | QE最严半宽约2e-12；flat gamma_(1.7e5)约2e-11不够 | E1：默认Arb sum；E2仅在明确平衡树、normal范围且外加运算界时可替换 | 秒至分钟 | MATLAB sum实现顺序或下溢未经约束 |
| handoffs | [qj_run.m:53](../../../test/numerical-directions/qj-cert-v2/qj_run.m#L53) | MAT-v7与JSON导出层 | 4 | 主双精度、整数拓扑、球端点/半径 | 导出不改变定义或安全方向 | SM：实/复各部分bit equality通过 | E0：double-v7-double已实测逐位保持；json只作描述，认证数据用精确binary/有向球表示 | I/O数秒至分钟 | 把无舍入导出误当上游已经有舍入保证 |
| handoffs | [dtn_run.m:61](../../../test/numerical-directions/h-dtn-v1/dtn_run.m#L61) | E2可选快速路径的适用域 | 2 | 复杂BLAS、FMA、sum及极小指数 | 标准gamma_n仅在无下溢时有效 | P幂/尾可有极小数；逐运算范围尚无记录 | other：本计划不以E2为必需默认；仅在范围验证后用gamma_(8n)等安全界，否则转Arb或另证绝对下溢项 | 微基准后决定 | 把正常双精度误差模型用于下溢/flush-to-zero |


逐阶段行数为 qj 32、A 11、B 16、C 17、D 12、handoffs 12。行记录在 [inventory-rows.json](../../../test/numerical-directions/rounding-v1/probe/inventory-rows.json)，可用于后续逐项销账。

## 数据本身的可容许性

**可以直接冻结的量。** 任意主节点/内部试探系数、响应多项式系数、预条件矩阵、近似特征向量和给定 $s>0$ 可以作为精确 dyadic 数据。浮点求根、场方程、通量最小化、QR、Vandermonde插值只负责选取这些数。后验残差负责其精度。试探场也无须精确归一化，未归一化E、M、S处理其实际尺度。无需把这些求解过程全部改成区间线性求解。

**qj 场必须重建共享关系。** 原始节点拓扑共享可以保留；上下从属值须由同一主节点乘精确 $e^{\mathrm i/2}$ 得到。27胞公共墙只定义一次。尤其不能将 `direct_pipeline.m:569` 的逐单元浮点单项式系数当作独立函数定义：即使原节点共享，独立浮点多项式转换也没有给出严格边连续性。用精确有理 Lagrange 转换从主节点生成局部多项式，再在球中评价。

**整数 RT3 基的边界。** 整数系数参考基使参考边法向迹恒等式和内部零迹精确；任意 dyadic 内部系数仍有零法向迹。它不使 rounded phase 等于精确相位，也不使 `B*local_coefficients` 的浮点缓存保留精确抵消。应导出整数基中的内部系数及唯一全局边主矩，再用整数方向、精确相位及同一Piola几何展开。外墙主矩保持精确0。这个修复同时用于qj与C。

**几何不能混用两种定义。** 冻结曲线节点给出的是 dyadic 曲边网格；重新计算真弧后，旧二次边不再自动等于该真弧的二次插值。当前薄层和拟合图公式恰依赖后一个等式。推荐导出角度的整数编号，所有真弧顶点/中点从规范有理模型及 Arb pi 重建；普通背景顶点可以固定为dyadic。非曲线边中点取同一端点表达式的精确平均。这样保留原证明结构，试探场只发生允许的微小变化，所有积分重算。原 `r>1e-14` 保护分支只可作为数值求值保护，不能成为真几何定义；认证图使用 $r>0$ 的公式及 $r=0$ 连续延拓。若坚持完全冻结旧网格，必须把其真实 dyadic 曲边作为同伦起点并重新证明闭合/覆盖，不能继续直接套当前 Pi2 c 余项。

**B 的固定响应是可用的。** 每面板的有限 Fourier 多项式系数任意，归一相位参数和精确 Bloch 基恢复后定义合法全线响应。面板间无须导数匹配。`Xzc/XDc/XDl` 不是自由试探数据，它们是物理乘子的派生缓存，须复算或附严格乘积误差。

**C 的无限链不能冻结所有派生块。** P可作为任意固定dyadic传递矩阵，但须验证某个有限幂收缩。U的边界行按同一I/P构造；低Fourier映射G用精确指数。只冻结内部场数据和一个通量主墙映射 $N_b$，由同一公式构造 $F_b=N_bP$、$N_0=N_bG$。若将这三个乘积独立浮点冻结，原本的全链H1/H(div)匹配不再严格。端口修正须针对重建后的实际FE迹重新定义；两项使用同一表达式才能逐点相消所有额外Fourier分量。

**D 的代表函数与能量基。** r必须是精确 $\kappa_k=\sqrt{\beta_k^2+1}$ 的解析函数；冻结一个近似kappa将破坏Riesz代表恒等式，补空间保留迹不再严格为0。浮点P可冻结为可逆dyadic基变换，空间仍含所有精确代表函数；但此时真实H通常不等于I。推荐在Arb中重算 $H=P^*H_{raw}P$，把H-I加入组装误差。另一个正确方案是以精确解析Cholesky定义P并球包围其系数。当前仅有 $\|H-I\|_1=5.04\times10^{-14}$ 的浮点检查，两种方案均需补上严格界。

**模型参数与自由数据分开。** $s$可选为原double；模型常量不是任意可选数据。统一 $\alpha_-=1089/625$、$\alpha_+=56169/10000$、$\beta_0=1/2$、$a=3/25,1/5$、星形系数 $1/5,3/10,3/2$、带边 $659/500,19/8$。`arb(float(pi))` 精确得到浮点pi，而非真pi；这里应使用 Arb 的 pi。两者的区别不能靠“double→Arb精确”消除。

**显示端点也需要有向舍入。** `qj-cert-v2/output/run-004/analysis.json` 的 `scalar_decimal` 给出未计舍入的高精度中心端点。常用简写 `[2.4287286691978, 2.4287286736601]` 相对这些值，左端向内约8.59828e-15，右端向内约2.30420e-14。它可以描述结果，但不能照抄成严格包含区间。后续只从球的外端点定向打印；这两个差值不是上游误差的界。

## 最小余量

以下是现有记录中五类最小的严格正检验量；不同单位不能横向当作同一条件数排序。逐面板 reciprocal lower、候选驻点归属及A矩阵norm没有完整记录，所以这不是对未导出内部量的穷尽最小值宣称。

| 项目 | 已存绝对量 | 相对尺度 | 舍入影响判断 |
|---|---:|---|---|
| D近贴边shift的最小LDL枢轴 | 1.10754e-10 | 相对gamma_safe约3.03e-10；依赖基与消元顺序 | 精确保留原十位下界时最敏感；只证H可用0.36等宽shift |
| qj/C全元Jacobian下界 | 7.73167e-6 | 最小值所在仿射元det_min/det_max约1；源见QG/CG | 绝对数小主要是单元面积；需要全元界，非危险谱间隔 |
| A最小下端负方向 | 1.39722e-4 | 原169阶矩阵norm未保存 | 最小关键谱符号余量；128位复算预计足够，尚未证明 |
| B右材料下端Schur间隔 | 0.00428912961539 | 对JSON中心C/E行范数参考约0.007886 | 允许约1e-6新增误差仍有明显间隔；大Gram抵消须量化 |
| D代表函数余项Gram最小值 | 0.00496400970240 | 每个2阶块的最大值未保存 | 需严格2阶正性或验证基变换可逆；不是线性依赖的证据 |

qj 的E半宽约2e-12、M剩余精度预算约2.6e-12，比这些符号量小得多，但属于准确度预算。未计入的双精度全量求和可能吃掉它们；E1系数和总和复算是必要的。C的交叉空间重叠最小值约9.16e-14、秩亏R的浮点最小值约-4.49e-22是诊断量，不是证明C.3所需的严格正门槛，不应为了保存这些数值而把全部精度推高。

可用于实施阶段的条件预算：若A每个矩阵新增谱误差不超过1e-6，下端余量仍约1.387e-4；B若新增误差不超过1e-6，最小Schur余量仍约0.004288。若C两侧新增trace归一误差各不超过1e-5，由迹界带来的核心损失不超过 $2\coth(1)\,10^{-5}\approx2.63\times10^{-5}$。再给D本地1e-6，第二方向仍大于0.3653。这些是预算条件，不是已测到的Arb误差。qj先给新增舍入 $\epsilon_E\le2\times10^{-13}$、$\epsilon_M\le5\times10^{-13}$、$\epsilon_S\le10^{-13}$，最终宽度用四角式重新决定，不预报未经计算的新端点。

## 试点

已做，成功。复制 h-core-v1 到 probe 内，进程内重生 $(31,16)$ 的最终浮点矩阵，第二特征值相对原记录差小于 $10^{-12}$。`-v7` 文件为14,710,348字节，保存固定 $L_{cert}$ 的实部、虚部最大条目界、近似负向量及实Cholesky见证。probe共用量保持在20MB以内。

采用128位、11线程Arb：对 $T=\Re L$ 验证 $T-\gamma I+8vv^T\succ0$，$\gamma=36537/100000$，再计入完整虚部的范数界。没有依赖浮点LDL枢轴符号。结果为
$$n(L_{\mathrm{frozen}})=1,\qquad \lambda_2(L_{\mathrm{frozen}})\ge\frac{36536998}{100000000}=0.36536998.$$

| 量 | 严格验证结果或监控实测 |
|---|---|
| 因子残差Frobenius上界 | $3.711\times10^{-15}$ 以下 |
| 三角比较逆无穷/1范数上界 | 2260.444 / 1481.537 以下 |
| 残差乘逆范数条件 | $1.243\times10^{-8}<1$ |
| 秩1修正矩阵的正下界 | 大于 $2.9860\times10^{-7}$ |
| 完整虚部算子界 | 小于 $1.5710\times10^{-8}$ |
| 负向量Rayleigh上界 | 小于 -6.4171358886 |
| Arb纯验证时间 / 其中矩阵乘法 | 2.07482秒 / 0.65733秒 |
| 含受监控MATLAB父进程的墙时 / 峰值 | 17.54846秒 / 1.24450 GiB以内 |

上表十进制上/下界均比球输出向外放宽。机器记录：[pilot-certificate.json](../../../test/numerical-directions/rounding-v1/probe/run-003/science/pilot-certificate.json)；[monitor.json](../../../test/numerical-directions/rounding-v1/probe/run-003/monitor.json)。递推与秩1推导在 [probe/README.md](../../../test/numerical-directions/rounding-v1/probe/README.md)。

这个结论只覆盖**固定导出double矩阵及其虚部包围**。该矩阵的上游H、材料积分、DtN输入和epsilon仍按原浮点方式产生，故这不是完整(D)或(H)的舍入认证。它表明E3的有限矩阵部分很便宜；B/C的源项与残差积分尚需单独标定。复现：

```sh
python3 test/numerical-directions/rounding-v1/probe/pilot_launch.py --mode export --output test/numerical-directions/rounding-v1/probe/run-002 --left test/numerical-directions/h-dtn-v1/left-certificate.json --right test/numerical-directions/h-dtn-v1/right-certificate.json
python3 test/numerical-directions/rounding-v1/probe/pilot_launch.py --mode proof --output test/numerical-directions/rounding-v1/probe/run-003 --mat test/numerical-directions/rounding-v1/probe/run-002/science/pilot.mat
```

重跑须用新编号。Python由受监控MATLAB的system子进程启动，整个树都受3 GiB和时间上限约束。

## 实现计划

推荐统一模型/schema、MAT导出及Arb公共库，使用一个串行分阶段驱动；不把全部大矩阵塞进一个常驻进程。阶段之间传有向球或dyadic中心加谱半径，几何/求积/指数矩缓存共享。当前目录各自重跑完整基准会重复生成场和通量；一次生成主数据再分阶段认证更便宜。

| 顺序 | 实施内容 | 工程工时预计 | 认证运行预计 | 峰值内存目标 | 需要重新导出的MATLAB数据 |
|---|---|---|---|---|---|
| 0 | 规范有理常量、位精确I/O、相位/共享拓扑、球交接schema | 0.5–1天 | 分钟级 | <1 GiB | qj主节点、主边/内部通量、整数拓扑；不导出独立局部缓存 |
| 1 | E3公共惯性/谱界引擎与D固定矩阵基准 | 0.5–1天 | 试点Arb 2.07秒；含监控17.55秒 | 实测1.24 GiB | D最终矩阵、近似向量/因子；仅用于校准 |
| 2 | A的材料矩、118面板覆盖、472个有限符号 | 0.5–1天 | 5–30分钟 | 0.5–1.5 GiB | 新入口导出逐面板近似向量/因子与norm；现A无结果JSON |
| 3 | qj精确可容许数据、二维模型、逆图、E/M/S及四角/I1 | 2–3天 | 1–6小时，按模板/面板分块 | 1–2.8 GiB | 重生P3与RT3一次；旧进程不保留场/通量，必须重跑 |
| 4 | B固定多项式响应、真实曲线源与Poisson Gram | 1.5–3天 | 必要两下端合计3–12小时；四端可到6–24小时 | 1–2.8 GiB | N26、21源、6系数、64面板；每面板约5.7MB复系数，逐块导出 |
| 5 | C精确墙约束、几何与残差Gram、无穷尾和下DtN | 1.5–2.5天 | 两侧1–6小时；是另一主要成本待测点 | 1–2.8 GiB | U的独立内部行、P、通量主墙与内部系数；按元素块约10MB导出 |
| 6 | D真解析M1/代表/B、星形矩、重新组装及验证惯性 | 0.5–1天 | 5–30分钟 | 1–2.5 GiB | 原代码重生约14秒；浮点P只作预条件，其余矩必须球复算 |
| 7 | 全链接线、回归、外端点打印和报告 | 0.5天 | 分钟级加一遍全链 | <2.8 GiB | 最小输入证书与方向明确的结果 |

工程合计约7.5–13天；首个完整球复算预计6–25小时，不含回退重试。除E3有限矩阵试点外，上述运行估计只以已有浮点成本与微型Arb调用作量级规划，尚未对B/C的主产品标定。首次实现先测一个qj界面面板、一个B相位面板、一个C元素块；外推若超过单run30分钟或3 GiB，必须按同一结果分块，并保留整个结果的累计成本，不能重置预算。

B的证明主路线还可省掉非必要上端计算：两材料在alpha_-的Schur严格正，结合A与已证单调性，已给出到上带边之前的半引线无谱及K+=279.9。原四端与B3响应Gram仍可保留为浮点诊断；若也要把这些附加数值标为已认证，另做表中相应E1/E3，不把它们混进最短主链。

性能安排：A/B/D的指数矩按频率合并缓存；B的X是二维Toeplitz，可用python-flint本包的acb_poly卷积或严格包围的分块乘法，避免每相位复制2809阶球矩阵。C先用精确有理多项式矩处理仿射类，再处理少量曲边/解析修正。qj逆多项式和预条件器可从浮点导出作为任意猜测，只在球中验证最终缺陷，省掉重做全部猜测迭代。Arb矩阵norm优先用Frobenius/1范数与无穷范数的严格上界，避免为非关键norm逐个求谱。

E2只作后备：标准gamma_n需要明确的舍入模式、运算路径与无下溢前提；复杂BLAS、FMA、并行sum和传递幂的极小数均未记录这些条件。即便用E2，也须在Arb中评价其误差上界，并将可能下溢的块交回E1或另证绝对下溢项。默认球算术路径更容易逐项核查。

## 未决问题

1. 旧MAT没有保存，必须新增导出入口；本阶段没有改动任何数值实现。可容许对象应由主数据与结构关系定义，不能把全部缓存直接保存后当作定义。
2. A无既存逐面板JSON/norm；qj未保存每个reciprocal lower及所有候选点分支余量，D未保存各2阶Gram的相对条件数。这些输出须在后续入口加入，当前无法保证上面五项是所有内部量的绝对最小值。
3. B/C的球产品主成本仍未测量，性能估计范围宽。128位用于A/D线性代数起步，qj/B/C从192位起步，必要时局部256位；精度选择须由球半径是否满足预算决定。
4. 一阶交集I1也需使用同一批球E/M/S重新包围。若只认证H计数而不补这个存在性输入，Theorem S.2仍不是完整的舍入结论。
5. BIE参考、旧FE根/计数、Q16/Q24包含检查、C的极小重叠特征值及D附加随机场相对检查都是诊断。它们保留当前状态；证明使用显式包围和严格有限测试。最终链无需Bessel/Hankel，故本计划不为参考BIE另造球算法。
6. 当前表没有给任何未经复算的最终球端点。12个四角符号、模型可容许性、A/P、下DtN和最终核心惯性必须在同一规范模型下全部通过，才可取消“舍入排除”。
