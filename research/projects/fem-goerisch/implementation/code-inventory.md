# FEM–DtN–Goerisch 参数化代码清单

**结论：整链参数化是大工作；先支持同一单位胞、同类曲线、只改中心材料的参数族，则是中等工作。** 难点主要是几何及认证常数有多份硬编码，以及“三模板、一个中心胞、一个候选”的数据结构。最难的是把真实界面及其解析余项同时接入试探场、积分证书和核心计数，而不只是让网格随参数变化。只改两切口之间的 core、保持外侧半引线、切口终止方式、β 和隔离端点不变时，A/B/C 的数学结果可以复用；D 和新场的 E/M/S 必须重算。当前程序还需要显式连接证书，不能仅修改一个 config 后直接运行。

本次只读代码与既有小记录，未运行 MATLAB。主区间与项目范围以本项目 [[research/projects/fem-goerisch/README|README]] 为准。以下“可靠”沿用现有记录的排除舍入约定；舍入估计不作为通用参数的认证入口。

为缩短表格，下面的前缀均展开为完整仓库相对路径；`文件:行` 指本次读取的源文件位置：

| 前缀 | 目录 |
|---|---|
| P | `test/numerical-directions/fem-pipeline-v1/` |
| Q | `test/numerical-directions/qj-cert-v2/` |
| F | `test/numerical-directions/accel-probe-v1/` |
| G | `test/numerical-directions/gap-ends-v1/` |
| A | `test/numerical-directions/rounding-estimate-v1/band/` |
| B | `test/numerical-directions/h-cert-v1/` |
| C | `test/numerical-directions/h-dtn-v1/` |
| D | `test/numerical-directions/h-core-v1/` |

## 1. 各阶段的固定量

所给链条基本正确，有三点修正。P 与 Q 都已复制其所需的 FEM/DtN 实现，当前数值入口不再调用旧 I9/I10 控制器；P 的 `window_pipeline.m:17–30`、Q 的 `qj_run.m:12–16` 都在进程内重新搜索、生成场。Q 已包含场、RT3 和浮点核查，不能在成本中再加一遍 P。G 是普通浮点选窗和极点扫描，认证 A 的实际代码是 `h-cert-proof.md` 附录 A（`research/explorations/numerical-directions/h-cert-proof.md:1731–1853`）；其独立 Python 副本和 MATLAB 重放版分别是 `A/h-band-reproduce.py`、`A/band_estimate.m`。

表中“科学”是模型、窗口、函数空间或证明前提；“离散”是网格、截断、试探表示；“容差”包括求解、认证余项预算和运行检查。重复出现的科学量必须合并为同一来源。

| 阶段 | 固定量或现有参数入口 | 文件:行 | 种类 |
|---|---|---|---|
| P：P2 搜索 | β=0.5，d=L=1，star_scale=1；ρ 背景/中心/左右=1/4/17/17；左右 a=0.12/0.20，radius=0.2 | `P/fem_i9_config.m:8–10` | 科学 |
| P：几何与缺陷 | 仅 cell_index=0 是星形，其余按正负用左右三叶形；位置按 cell_index×L 平移；背景网格却用单位格、y=±0.5 | `P/fem_i9_run.m:99–115`、`:166`；P3 副本 `P/direct_native.m:101–112`、`:142–153` | 科学；L/d 目前只是部分可改 |
| P：P2 区域与网格 | half_cells=6，即总 13 胞；h=1/12，80 界面段，体积分阶8，ring_scale=0.15 | `P/fem_i9_config.m:12–14` | 离散 |
| P：搜索 | k-window 显式传入；平方窗口的三等分中点移位，每次12 Ritz 对，子空间40、seed193；shift_count 字段与公式里的 `1:3` 重复 | `P/fem_i9_config.m:11`、`:15–18`；`P/window_pipeline.m:17` | 科学窗口；离散搜索策略 |
| P：候选筛选 | eigs 容差1e-10、最多1000步；残差1e-8，中心质量≥0.15、中心三胞≥0.60、两端各2胞质量和≤0.02；去重 Δk≤1e-6、重叠≥0.90 | `P/fem_i9_config.m:15–21`；`P/fem_i9_run.m:265–297` | 容差/筛选策略 |
| P：P3 模型与网格 | 另一份同模型 config；生成入口固定 g48、阶3/4；g48 指每单位胞边48份、每曲线320段，几何仍是二次映射 | `P/direct_native_config.m:26–39`；`P/direct_native.m:14–23` | 科学副本；离散 |
| P：P3 积分及几何检查 | 体积12/16/20；界面带子段2/4/8，每子段8/12/16点；ring/clearance、最多3轮修复、30秒修复预算；位置残差1e-12、迹1e-10 | `P/direct_native_config.m:40–50`、`:66–89` | 离散/容差 |
| P：DtN 与根 | 两周期引线消元及 QZ 稳定子空间；局部 k-window=k_start±0.01；括区半宽序列[2e-6,2e-5,2e-4,1e-3,1e-2]，最多40频率，k宽2e-12、分支值1e-10、中心残差1e-9；单位圆分离1e-6、Z0 rcond≥1e-10 | `P/direct_native_config.m:33`、`:85–95`；`P/direct_native.m:1205–1273` | 科学分支/离散/容差 |
| P：场延拓 | 固定左右各13胞；恢复处另写 `exp(.5i)`，不是从模型读取；只生成 left/center/right 三模板 | `P/direct_native.m:58–66`；`P/direct_pipeline.m:44–50` | 科学约定/离散区域 |
| P/Q：Goerisch 场与通量 | γ=1，K=13，β=.5，区域[-13.5,13.5]×[-.5,.5]；两端宽2的 cosine taper，自 |x|=11.5 开始；RT3 稳定基、凝聚 | `P/direct_pipeline.m:24–30`、`:69–109`、`:566–575`；`Q/qj_run.m:16` | 科学移位/试探选择；离散 |
| P/Q：积分/检查 | 主/核查16/24阶，材料带10/16阶；准备函数中仍直接写16、10、degree=3；面积1e-12、迹1e-10、积分相对预算0.01 | `P/direct_pipeline.m:55–60`、`:173`；`P/window_pipeline.m:33–35`、`:68–75` | 离散/容差 |
| P/Q：端点与 s | P 默认旧 α=(1.3174²,2.1875²)；Q 入口改为(1.32²,2.37²)；μ=α−+1，ν=α++1；四角所用 s=P.q，q=1+E/M，γ的1也写进公式 | `P/direct_pipeline.m:26–30`、`:67`；`Q/qj_run.m:9`、`:45`；`Q/four_corners.m:7–13` | 科学；不能只改 cfg.gamma |
| Q：真实曲线 | 中心复指数频率[1,-1,6,-4]、系数[.25,.05,.03,.03]；引线频率[1,4,-2]、半径.2及a=.12/.20；曲线 Taylor18；中心三阶导界C3=8.7 | `Q/curve_model.m:7–15`；`Q/geometry_certificate.m:20–26`；`Q/interface_model.m:8`、`:48–50` | 科学及形状专用解析常数；离散次数 |
| Q：E/M/S 表示 | 固定3模板、P3 的4×4系数表、RT3的24系数；背景权重1，材料校正为ρ_in−1；渐消胞由 `abs(cell)>=12` 决定，证书中另写11.5 | `Q/qj_certificates.m:12–16`、`:28–45`、`:92–96`、`:159–164`；`Q/interface_fields.m:12–13` | 科学/离散结构 |
| Q：余项预算 | E rational总1e-12、公共S总1e-16，质量自愿半宽1e-13；smooth 每元素1e-13/(3×640)，细分最多3层；sliver初始4板、最多4层 | `Q/qj_certificates.m:9`、`:71–77`、`:132–135`；`Q/interface_certificate.m:15`、`:23–24`、`:62–65`、`:89–90` | 容差/离散 |
| Q/F：多项式模型 | 原PM总次数12、倒数/sin/cos阶16、逆猜测18次；F 提供选项，已测快设置tol×1000、12/16、sliver1板、逆猜测6次 | `Q/pm.m:24–36`、`:58–60`；`Q/interface_model.m:32`；`F/accel_iterations.m:40–44`、`:58–60` | 离散/容差；最终逆缺陷检查保留 |
| G：端点探索 | 入口写死旧搜索窗[1.451,2.249]、高端[2.1875,2.38]；高端9移位×24 Ritz；P3 g48的多组采样点，P2只核对4端点 | `G/gap_run.m:10–15` | 科学选窗与离散探索 |
| G：扫描检查 | 原模型、β及网格沿用复制版；完整矩阵核查仅在[1.32,2.1875,2.37,2.38]，eigs tol1e-10、500步；正惯性跳变才启动局部根 | `G/README.md:11–15`；`G/scan_extension.m:4–13`、`:40–45`、`:53–60` | 科学/容差/探索策略 |
| A：模型与目标 | 单位胞、β=.5、ρ=1/17、a=.12/.20、半径.2、面积.04π；认证 k 带隙[1.318,2.375]，只检查第一带与第二带之间 | `A/h-band-reproduce.py:14`、`:30–48`、`:59–64`、`:73–89` | 科学 |
| A：截断及面板 | 双指标|m|,|n|≤6，169维，曲线2048点；118个已接受面板覆盖[0,π]，端点为π/4096的整数倍；负θ由对称性补齐 | `A/h-band-reproduce.py:13–27`、`:96–99` | 离散；对称性是科学前提 |
| A：解析界/判据 | 复条带宽.1、被积函数模界8，矩阵常数16/256、尾分母ρ_max=17；每板尾分母和两个符号余量严格>0 | `A/h-band-reproduce.py:55–60`、`:75–89` | 形状专用解析界/认证判据 |
| B：模型与源 | a、λ显式传入，但radius=.2、胞中心(.5,0)、单位周期、ρ跳跃16、β=.5另写；参考源仅k=0特殊处理，其余κ=sqrt(β_k²−λ) | `B/h_bloch.m:41–58`、`:89–104`、`:118` | 科学 |
| B：窗口与边界空间 | λ取1.7424或5.6169；周期距离使用A边界1.318²/2.375²；源模|k|≤10，Schur核对M=8/10；无材料 collar宽1/4 | `B/README.md:28–42`；`B/h_bloch.m:92–104`；`B/h_endpoint.m:7–8`、`:33–39` | 科学/离散 |
| B：正式响应与积分 | N=26（53²平面波），64相位板、每板次数5，曲线2560点、相位40阶；小空间N18/128板用于复核；上下端分别form/poisson2 | `B/README.md:28–42`；`B/h_bloch.m:105–111`、`:170–174` | 离散 |
| B：解析界/检查 | 相位Bernstein椭圆2，曲线复条带.1；moment界中的100、10与固定曲线/模截断相关；Poisson分母.25−strip²；核对1e-9、Hermitian1e-12；专用K+要求下端负指标0 | `B/h_bloch.m:108–111`、`:127–138`；`B/h_analyze.m:30–44` | 科学解析前提/容差 |
| C：物理/接口 | α+=5.6169，β=.5，原取向两引线a=.12/.20，ρ=1/17；切口±.5；K+=279.899894626、K−=.70782直接嵌入 | `C/dtn_run.m:18–31`；`C/dtn_native.m:1905–1912`；`C/report_dtn.py:19–24` | 科学；B的结果尚未成为输入 |
| C：场/通量/迹 | g48/P4、RT3，节点迹每侧192个（48×4，实际由sp.n生成）；33 Fourier模|k|≤16，其中|k|≤5用数值响应；其余用解析提升；参考能量移位1 | `C/README.md:27–30`；`C/dtn_native.m:1905–1909`；`C/dtn_flux.m:5–15`；`C/dtn_run.m:29–31` | 离散；迹与移位须一致 |
| C：提升/求积/尾项 | collar=1/8，cubic提升，衰减12s并用8s核对；complex ellipse常数1.125/.625、级数40；按1e-13/1e-14及Z的1e-5分配，阶数24–104；传递倍增最多20轮、1e-15停 | `C/dtn_run.m:8–17`、`:57–64`；`C/dtn_bounds.m:5–29`；`C/dtn_integrate.m:7–24`、`:70` | 离散/容差及collar前提 |
| D：core和材料 | core=(-.5,.5)×(-.5,.5)，固定五叶星形；β=.5、ρ=1/4、α+=5.6169；Mq=(λ+1)M1+3λMstar，q_max=23.4676=4λ+1 | `D/core_curve.m:8–11`；`D/core_run.m:5–16`；`D/core_space.m:5–18` | 科学 |
| D：空间/迹 | Nx、Ny显式输入；正式(31,16)，cosine×Fourier基加两端66个精确代表，端口模式|k|≤16；能量移位1；不依赖P3场或RT网格 | `D/core_space.m:4–20`；`D/README.md:25–27` | 离散/空间选择 |
| D：积分/矩阵检查 | 曲线J=512并加倍；形状条带.1；eigs tol1e-11/2000步/子空间32；位移为λ₂估计−max(10残差,1e-10)；LDL计数及第二方向检查 | `D/core_curve.m:15–26`；`D/core_run.m:12–35`；`D/README.md:27` | 离散/容差 |

**关于C的节点迹数：** 这里192是g48/P4的构造数，也由正式左右记录的`wall_count`确认（`C/output/run-006/science/result.json:1`、`C/output/run-008/science/result.json:1`）；最终交付矩阵仍只有33×33。P3的节点迹为144，见 `C/README.md:125–128`。两种计数不能与B的21个源模或D的66个代表混用。

## 2. 阶段间输入与隐藏依赖

当前主计算几乎没有旧 MAT 依赖，问题主要是**跨阶段结果被抄成常数**，以及证书导出混在报告脚本里。以下列出科学数据依赖；日志与 monitor.json 的预算记账不算科学输入。

| 阶段 | 目前实际读取/传递 | 应替换的显式参数或交付件 |
|---|---|---|
| P | 仅窗口及out；P2候选→P3 native→prepared场均内存传递，无旧native.mat；`P/window_pipeline.m:17–30`、`P/direct_pipeline.m:39–50` | `search(example,disc,window)`返回完整候选；`trial(example,candidate,disc)`返回native对象。持久化如有需要必须传入指定文件，保存坐标、元素、阶数、场系数、相位、传递矩阵及根历史 |
| Q/F | 各入口重新执行P，随后内存P、flux、inventory、v1→interface；`Q/qj_run.m:12–16`、`:27–45`。F同样重生，见`F/accel_iterations.m:9–28` | 拆成`flux(trial,...)`、`integrals(trial,flux,...)`，同进程复用native，避免再跑P；标量`integrals.json`含E/M区间、S上界、固定s和全部判据 |
| Q汇总 | 显式run目录内读取interface-certificate、certificates、inventory-exact、baseline等JSON；`Q/analyze_v2.py:8`；还枚举同级monitor作历史成本，`:46` | 只消费本次显式交付对象；历史成本单独报告。四角函数本身已有E/M/S/s/cfg实参（`Q/four_corners.m:1–13`） |
| G | 不读旧场，每次重生；报告工具显式读取baseline/scan；`G/gap_run.m:8–17`、`G/README.md:15–25` | `explore_window(example,search_options)`→建议端点、原始扫描、候选列表；结果须标记“探索”，不自动冒充A/B证书 |
| A | 无旧输出；Python代码内保存已接受的118板。原生成记录称自适应发现有拒绝板，但现存附录/副本是最终覆盖重放（`h-cert-proof.md:384–386`、`:1731–1737`；`A/h-band-reproduce.py:19–27`） | `band_certificate(lead,beta,band_request,options)`→带隙、完整板链、符号余量、尾界。原板链可作为显式初始网格，新参数须逐板重验；未找到独立的自适应发现入口 |
| B | 四个主响应、四个小空间响应和tail-constants.json由显式manifest读取；`B/manifest.json:2–15`、`B/h_analyze.m:6–10`、`:36`。A给出的带边被硬写，未读A输出（`B/h_bloch.m:104`） | 数值入口直接接收`band_certificate`和两端λ；汇总直接接收数值记录数组/明确路径参数，不用运行清单授权或配置；输出`surface.json`含两端惯性、排极点结论、一般K及适用时单侧K+ |
| B→C | `B/report_h.py:88`导出monotonic-constant.json，但C没有读取它，K±仍是字面量（`C/dtn_run.m:22`、`C/dtn_integrate.m:7`） | `dtn_lower(lead,endpoint,surface_certificate,options)`；检查输入K的端点、方向、谱距离和适用前提，不允许无来源的标量替换 |
| C汇总/导出 | `C/analysis-input.json:2–12`指向constants.json、run009/007粗、006/008细及011的fe-dtn.json；`C/dtn_analyze.m:6–9`读取。`C/report_dtn.py:10–37`导出左右矩阵，并在`:38`读取README以拼报告 | 拆出纯数值`export_dtn(result,checks,out)`，从实际配置生成元数据；粗细和FE核查可显式附加。运行时不读README，也不把固定端点/a/β重新写进导出器 |
| D | `core_run(out,Nx,Ny,J,left_path,right_path)`读取左右certificate.json（`:7–10`）；输出目录本身无旧MAT依赖 | 现有显式参数保留，增加core模型、endpoint和与左右证书匹配的完整检查；小矩阵可JSON交付 |
| D汇总/H闭合 | `D/report_core.py:8–9`写死run001/002/003、constants.json，另外读G/run005的P3负指标；谱相交存在性只是文字前提（`:29–30`），不是实际读入/验证的数据 | `count(core,endpoint,left,right,options)`返回计数上界；另有`isolation(band,surface,count,intersection)`验证独立的一阶谱交集区间包含于隔离窗。G的浮点符号对照可选，不应为认证必需输入 |

此外，P的launcher会读取其旧run监控时间作累计预算（`P/launch_pipeline.py:9–16`）；新批次应显式传入预算会话，不要让多年历史运行逐渐耗尽一次新实验的额度。现有launcher通过自身目录找到代码与monitor，不是数值函数搜索仓库根；迁移时由launcher传入`code_dir`、`monitor_path`，数值函数仅使用MATLAB path（`P/launch_pipeline.py:8–15`；`test/AGENTS.md:38–47`）。

## 3. 本例专用假设、失效方式与能否检出

| 假设/结构 | 换参数后会发生什么 | 现有检查是否足够 |
|---|---|---|
| 一个局域候选 | P/Q入口直接`assert(numel(candidate_ids)==1)`；出现第二个候选即停。根初选为Schur矩阵最小绝对特征值，后续靠重叠跟踪，密集分支可能歧义 | 候选数和分支间隔会拦截部分问题；不保证P2已找到全部模式。须保留列表、逐候选跟踪，不能选最近旧根。`P/window_pipeline.m:18–19`；`P/direct_native.m:1378–1404`；`Q/qj_run.m:13` |
| 模式集中在中心三胞、13胞搜索足够 | 靠近带边的长尾及偏离中心的双缺陷模式可被质量筛选丢弃；固定两端渐消也可能主导残差 | P2输出NOT_LOCALIZED及质量可诊断，但不能把零候选解释为无谱；四角符号/宽度会反映差试探场，不一定自动给出原因。`P/fem_i9_run.m:265–279`；`Q/four_corners.m:8–13` |
| 一个中心胞、每模板一条界面、每界面仅内外两分支 | 两缺陷相隔若干胞须扩展core和模板序列；现有按cell正负分派会把第二缺陷当引线；interface_model只取元素第一条匹配弧 | 无通用拓扑检查。部分网格面积/单射断言可能失败，但若所有副本仍用旧模型，会一致地计算错误问题。`P/direct_pipeline.m:44–50`；`Q/interface_model.m:7–9`、`:43–50` |
| d=L=1 | 网格坐标、模式2πk、单位平移、端口、面积常数、能量Gram都依赖单位长度；改model.d/L不够 | 部分面积和配对检查会失败，余项公式仍可能错误。`P/fem_i9_run.m:114–115`；`D/core_space.m:5–18`；`A/h-band-reproduce.py:73–76` |
| β=.5且背景参考算子只有k=0需特殊处理 | 换β/高窗口时可有多个κ非实模；β趋0时B的Poisson逆分母也改变 | B仅用`k==0`替换κ，未先枚举全部例外模；这需要明确准入检查及一般源构造。`B/h_bloch.m:92–94`、`:135`；`B/h_endpoint.m:34–39` |
| 星形/三叶形的解析界 | C3=8.7、复条带模界8/100、曲线傅里叶频率、面积、ρ跳跃都专用于旧形状/材料；椭圆也未作为通用几何对象接入 | Q逆映射/单射断言确实存在，但不能证明错误的输入导数界。须由同一曲线对象生成全部界；仅点采样或面积一致不够。`Q/geometry_certificate.m:20–31`；`A/h-band-reproduce.py:55–60`；`B/h_bloch.m:110–138`；`C/dtn_bounds.m:5–22` |
| 横向反射对称 | A用y反射加共轭，从[0,π]推至负θ；D用绝对频差及取real复用材料矩。偏移/旋转形状可失去这两个简化 | 没有形状对称性准入断言；强制Hermitian之后再查Hermitian不能检出遗漏虚部。A应验对称或覆盖[-π,π]；D应算带符号频差的完整复矩。`A/h-band-reproduce.py:96–99`；`D/core_material.m:5–10`、`:16–20`、`:30–32` |
| 左右引线可不同，但不可随意镜像 | 现有a=.12/.20本来不同；A/B/C不要求两侧相同。B的左右半线及C的near/sigma保留原物理取向，不能用“同形”省掉终止方式 | C方向由side决定，交付JSON带inward_sigma；须纳入跨阶段匹配。`B/h_bloch.m:53–62`；`C/dtn_native.m:1910–1912`；`C/report_dtn.py:19–23` |
| B下端负指标为0 | 这是K+=279.899...的专用推论前提；若非0，可使用一般半线谱距离/Khalf，或者改变窗口，原数字失效 | B汇总条件分支会不填专用K，但C仍无条件使用旧数字，链间不会自动阻止。`B/h_analyze.m:30–34`；`B/h_endpoint.m:15–27`；`C/dtn_run.m:22` |
| 无材料collar及高频尾正性 | B用1/4、C用1/8；引线变大或切口变动可能破坏collar。C还需A_H>0，B需tail.t>0 | C的复杂几何/collar和传递收缩有assert；各tail分母应在入口集中检查。仅运行到输出不等于这些前提完整匹配。`B/h_endpoint.m:35–39`；`C/dtn_bounds.m:19–22`；`C/dtn_run.m:29–31`、`:63` |
| B无穷引线、C无穷引线与Q有限渐消区 | B是逆Bloch全线响应；C为传递矩阵无穷级数；Q是紧支撑试探函数。三者不是同一个“lead cells”参数 | C有尾界与收缩检查；Q增K须同时增native恢复并改证书taper常数。`B/README.md:77`；`C/dtn_run.m:57–64`；`Q/qj_certificates.m:28`、`:92–93` |
| A第一带之后的隙、手选面板 | A只检查第1/2特征值；换到更高谱隙需要带指标参数。旧面板覆盖仍完整但符号可能失败，靠近带边通常须加密/提高N | 每板符号/尾分母失败可检出；“复条带模界仍适用”和对称性需要独立检查。`A/h-band-reproduce.py:25–27`、`:78–89`；`h-cert-proof.md:384–386` |
| C只保留|k|≤16，D加入相同端口代表 | C的矩阵在33模外零嵌入，但其下界针对全迹，含高频/交叉罚项；D必须包含该矩阵全部代表。改变M需同步33、66及索引 | D检查两侧indices和左β、两port，却未在core_run中核对所有材料、endpoint、右β；静态旧input-check不能替代新运行检查。`C/README.md:154`；`D/core_run.m:8–11`；`D/core_space.m:5–15` |
| D的单胞cosine–Fourier补空间 | 长core、多个材料区要重算单位长度Gram、port代表、a_star、q_max与材料矩；同一矩形内改ρ/形状则仍可用此类空间 | 现有c_W由23.4676/ast算出；不能沿用旧正值。新参数须显式检查c_W>0；主程序还要求输入下DtN正定以做chol。`D/core_space.m:18–20`；`D/core_run.m:11`、`:16–27` |
| D负计数必须1 | 两模进入同窗会使当前“one_negative”判据失败；n(L_cert)>1只表示这个上界未能证明至多一个，不能据此宣称真实有两个 | 测试会记录失败；应返回计数/余量而非写固定H结论。独立两条不相交谱交集区间可另作多模证据。`D/core_run.m:35`；`D/report_core.py:29–30` |
| D的0.36移位 | 原D用自适应safe_gamma；0.36出现在后来的舍入估计副本，用较宽余量代替贴第二值的移位 | 新模型应从当前矩阵选择移位并复核LDL，不能照抄.36。`D/core_run.m:25–27`；`test/numerical-directions/rounding-estimate-v1/core/core_estimate.m:30`；`research/explorations/numerical-directions/rounding-estimate.md:264` |
| 旧参考值即通过条件 | P/Q/F会要求新根、q、E/M/S接近本例旧值；B tail表、D常数表也对旧打印值做回归 | 会把正确新例误拒绝。应将旧例回归与通用有效性分开，保留迹、正性、分支、积分等真正检查。`P/window_pipeline.m:20–27`、`:50–54`；`Q/qj_run.m:19–40`；`B/h_analyze.m:36–37`；`D/core_constants.py:5–10` |

附加检查有一项历史未通过：D独立混合场积分的相对阈值，但绝对差在采用的算子余项内。迁移时应保留该事实及绝对/相对两个判据，不能把历史报告的所有检查统称通过（`D/README.md:72–83`、`:115`、`:134–144`）。

## 4. core-only 改动的复用边界

**成立，但“引线相同”必须包含从切口开始的整个半引线及其物理取向。** 在原切口±0.5之间仅改中心ρ或形状，β、周期、A带隙和α±不变时：

1. **A原样复用。** 周期纤维及其材料矩只依赖两引线，代码没有中心材料输入（`A/h-band-reproduce.py:62–89`）。
2. **B原样复用。** 源、半线表面态计数、K±依赖引线、端口终止方式、β和端点；不依赖中心缺陷（`B/h_bloch.m:89–104`；`B/h_endpoint.m:33–39`）。
3. **C数学交付矩阵原样复用。** 固定λ=α+的半线DtN没有core变量；C只用所选侧模板消元/延拓（`C/dtn_native.m:1884–1912`）。不过它先用通用三模板网格器生成含中心的网格，且先要求整体geometry通过（`:1881–1884`）；这是实现耦合，应拆成独立lead mesh builder。C附带的旧候选baseline也依赖core，不能把它当作复用引线矩阵的必要步骤（`C/dtn_baseline.m:5–8`）。
4. **D必须重算。** 中心材料矩、q_max和补空间膨胀、第二正方向及负指标都会变；A/B/C固定时，port代表/无权Gram可缓存，但不能缓存完整核心矩阵或H结论（`D/core_run.m:12–35`；`D/core_space.m:16–20`）。新场、RT3通量、E/M/S及四角符号也必须重算（`Q/qj_run.m:12–16`、`:27–45`）。

两缺陷相隔数胞通常需要扩展core。若把切口移到整数个L之外，且新切口终止的周期介质与原来完全一致，A仍复用，B/C可经严格坐标平移复用；需要更新port坐标和方向元数据，并重新构造D在长矩形上的代表和投影常数。若切口穿过不同胞内相位、缺陷侵入外侧半线或新增界面进入collar，B/C不能原样复用（切口/方向约定见 `C/README.md:13–15`、`C/dtn_bounds.m:19–20`；D长度依赖见 `D/core_space.m:5–18`）。

只改搜索k-window不必重算A/B/C；改α±则是另一件事，B的端点计数和C在α+的矩阵需要重新匹配。A覆盖较大的已证带隙时，可供其中较小的新窗口复用（`A/h-band-reproduce.py:99`；`B/h_bloch.m:104`；`C/dtn_native.m:1905`）。若新例在原窗中有多模，复用A/B/C依然正确，变化的是D及单模四角结论是否可交付。

## 5. 建议的参数化布局与工作量

建议先建一个实验版本，不把每阶段做成独立历史实验，不新建根共享包。以下仅为布局建议，本次未创建目录：

```text
test/fem-goerisch/pipeline-v1/
  README.md
  examples/example_current.m       # 一个函数返回一个完整例子struct
  examples/example_defect_strength.m
  stages/search_candidates.m        # P2候选列表，窗口为显式参数
  stages/build_trial.m              # P3/DtN根及native场
  stages/build_flux.m               # 固定试探场的RT通量
  stages/certify_integrals.m        # E/M/S，保留原/快两套精度设置
  stages/explore_window.m           # 可选的普通浮点探索
  stages/certify_bands.m            # A
  stages/certify_half_leads.m       # B
  stages/certify_dtn.m              # C，两侧明确参数
  stages/count_core.m               # D
  stages/enclose_eigenvalue.m       # 独立谱交集、H拼接、四角结果
  internal/                        # 几何、FEM、RT、PM及矩阵导出助手
  run_pipeline.m                   # 配置/交付件/输出位置均为实参
  launch_pipeline.py                # 显式MATLAB path、monitor和共享预算
  output/run-NNN/                   # 小JSON/CSV及必要时的显式field MAT
```

一个example struct分开保存：`model`（β的波数约定、d/L、背景及区域ρ、曲线/位置、左右引线、core及ports）、`windows`（搜索k范围、隔离μ范围、周期带隙请求）、`discretization`（search/trial/flux/A/B/C/D各自设置）、`tolerances`、`resources`。γ=1和参考能量移位1先作为**明确固定的支持范围**，不要保留一个实际无效的可改字段。曲线对象至少提供实参数值/导数、面积、复条带/导数界或可生成这些界的有限Fourier表示；网格与认证必须调用同一对象。依据分别是上述Q/C的形状界与 `Q/four_corners.m:8–11` 的移位公式。

交付文件建议为 `candidates.json`、`trial-summary.json`、可选`trial.mat`、可选`flux.mat`、`integrals.json`、`band.json`、`surface-left/right.json`、`dtn-left/right.json`、`core-count.json`、`intersection.json`、`interval.json`。同进程优先传对象，不强制保存大MAT。每件含实际科学参数、单位、坐标/取向、模式排序、所用端点、有效性前提和数值余量；消费者按字段验证匹配，不能依赖文件名或固定run编号。H拼接器必须读取独立谱交集数值，不能沿用`D/report_core.py:30`的文字前提。独立一阶交集与四角区间分开生成，避免以依赖H的区间反过来证明H。

| 部分 | 复制来源及改法 | 工作量 |
|---|---|---|
| 统一例子与几何 | P的config、native曲线；Q的curve_model/geometry_certificate；C的dtn_bounds；D的core_curve合为一份模型及认证接口 | **大**：同一几何有实数、复条带、逆映射、Fourier矩等多种使用方式，漏改解析界会损害保证 |
| P候选/根 | 复制P的fem_i9_run/config、direct_native及实际调用的基/网格助手；入口用例子参数；去掉旧例数值assert，保留root、迹和求解检查 | **中**：同类单缺陷改ρ；**大**：多core胞、偏移缺陷和多分支，需改中心装配/索引/筛选，而非扩大一个数字 |
| RT与E/M/S | 以Q的direct_pipeline为基础（有exact_flux/inventory/certificates）；合入F的可调interface_certificate、pm和逆迭代选项；先固定P3/RT3 | **中到大**：只改ρ可沿用表示；任意次数、形状、多界面要改系数表/模板和界，必须保留自映射/分支检查 |
| G探索 | 复制gap_scan_native中的扫描逻辑；暴露ks、端点与候选策略，去掉old baseline前置 | **小到中**：已有数组输入；自动可靠选窗不在现有功能内 |
| A | 复制附录A的独立副本或band_estimate；显式模型、带指标、panel输入；添加失败面板细分及资源停止规则 | **中**：同类引线；换无反射几何须覆盖全相位，形状界另算。原自适应发现入口未找到 |
| B | 复制h_bloch、h_endpoint和tail公式；输入A交付；输出一般K与专用K的条件，不能直接输出未满足前提的旧K | **中**：同类曲线、β=.5；**大**：β跨背景阈值、换源或失去原collar时，源与解析界需扩展 |
| C | 复制dtn_native的endpoint路径、dtn_flux/integrate/bounds/geometry；删除生成中心的依赖；参数化M、低模数、λ、K、collar；独立导出矩阵 | **中到大**：方程已有，但科学量散在多处，33/24等数组与模索引同步工作较多 |
| D | 复制core_space/material/curve/run；所有ρ差、q_max、β/长度由参数生成；一般复材料矩；导出实际count而非固定H文字 | **中**：单矩形内改ρ；**大**：长core、非对称多缺陷材料矩与投影常数 |
| 交付/运行/验证 | 把report_h/report_dtn/report_core里的数值导出与README生成分开；通用结果检查与旧例回归分开；统一预算、缓存匹配和计时 | **中**：目前缺的是显式的A→B→C及存在性→H连接，而非新的外部依赖 |

最小可行首版应先重现现例，然后支持“core不变形、ρ_center变化、同窗单模”；同时让零/多候选和计数未闭合成为可报告状态。随后扩到同一有限Fourier曲线族，再做跨胞双缺陷。这样可先验证复用接口，避免一开始同时改动所有解析界。入口不得读取报告或清单来配置运行、不得自动发现仓库根，依照 `test/AGENTS.md:38–47`；旧报告脚本只供离线追溯，不应照搬为数值前置。

## 6. 当前设置的运行时间与峰值估计

下表为**相同设置下既有成功运行的成本**，用来估计新例，不是本次计时或一条已执行的总流程。主证书用原Q精度以保持4.462e-9主区间。选用各阶段最终正式运行，失败和探索调参不摊进单例重算；原有附加核查另列。单位为监控墙钟秒/GiB，除附录原Python实现外，所列重放采用11线程（各实验README复现说明；A的监控入口见 `test/numerical-directions/rounding-estimate-v1/README.md:7`）。

| 阶段 | 正式计算，秒 | 原附加核查，秒 | 该组最高峰值GiB | 来源与边界 |
|---|---:|---:|---:|---|
| P单独普通区间 | 119.398 | 已含同场核查 | 2.0384 | `P/README.md:64–79`；只作参照，下行Q已重做它，不再相加 |
| P+Q：从窗口到E/M/S及四角 | 717.806 | 已含进程内浮点/积分核查 | 2.0165 | `Q/README.md:183–185`，run004；含搜索、场、RT及证书 |
| A：既定覆盖重放 | 17.595 | 含该重放导出/诊断 | 0.6833 | rounding-estimate-v1 run003，`research/explorations/numerical-directions/rounding-estimate.md:302`；入口为该run的`command.json:5`；新面板发现时间缺失 |
| B：四端点 | 1845.260 | 490.354 | 1.7196 | 正式run009/010/007/011；附加002/012/003/013/014；`B/manifest.json:2–15`、`B/README.md:227–242` |
| C：两侧g48/P4 | 1414.214 | 543.008 | 2.0236 | 正式006/008；粗层009/007、FE比较011、汇总013；`C/analysis-input.json:3–12`、`C/README.md:141–148`；正式运行已含8s提升对照 |
| D：正式(31,16) | 14.137 | 34.976 | 0.9195 | 正式002；粗层001及附加003；`D/README.md:128–134`；附加相对检验历史未通过，不能省略这一说明 |
| G：旧候选窗/端点探索 | 635.697 | 已含旧基准与P2核对 | 2.0342 | run002+005，`G/README.md:120–125`；可选，内部重生P，不是通用未知带隙发现算法 |

由上表相加，给定可用窗口与同等证书余量时，P+Q+A+B+C+D正式记录为 **4009.012秒＝66.82分钟**；保留所列原附加核查为 **5077.350秒＝84.62分钟**。若照旧完整执行G，再增635.697秒，分别约 **77.41/95.22分钟**，其中G的旧基准与Q有重复；尚未测量统一参数化流程消除此重复后的总时。串行峰值取最大，不相加，当前这套正式链约 **2.024 GiB**，含G约2.034 GiB。新例远离现有余量时不能据此保证3 GiB内完成。

core-only且A/B/C可复用：原精度Q+D正式约 **731.944秒＝12.20分钟**，保留D粗层和独立核查约 **766.920秒＝12.78分钟**，已包含新P2搜索/P3根和通量；峰值参照Q约2.017 GiB。新场先给独立谱交集、D再闭合H，不需要重新进行G的引线探索；若新模式跑出旧窗或有多模，则重新选窗后复用条件需再判断。

F快设置的三模板实测总界面时间152.155秒，原为461.388秒；原Q内部698.135秒据此推算为388.90秒，尚无全流程实测。加入原Q约19.67秒启动/退出及D约14.14秒，core-only约 **423秒（7.05分钟）**，仅可作计划值。快设置同时使质量偏差界变宽，标量重组总区间4.554474e-9，较主记录增2.06%；不能把它报成“同一主区间只加快不变宽”（`F/README.md:66–84`；Q内/外时间见`F/README.md:80`及`Q/README.md:183`）。

预算上，整链重算的67–85分钟已经超过默认一项结果30/40分钟的共享限额，后续须先确定获准的整链预算或明确复用已有引线证书，不能靠分成多个进程重置额度（`test/AGENTS.md:10–19`）。本例主要时间在B与C；core-only后主要时间在Q界面和其前置积分。不同β、引线形状、带边距离或多core胞的额外成本没有记录；上述估计条件是截断、网格、面板及成功余量仍与当前相近。未找到原A面板自适应发现的独立运行成本，也未找到针对未知新引线的完整自动选窗成本。
