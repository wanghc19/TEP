# 周期波导 BIE / DtN 方法的问题与后续补救

BIE = boundary integral equation（边界积分方程）；DtN = Dirichlet-to-Neumann（Dirichlet 到 Neumann）；RtR = Robin-to-Robin（Robin 到 Robin）。

QP 指 quasi-periodic（准周期），NEP 指 nonlinear eigenvalue problem（非线性特征值问题），PML 指 perfectly matched layer（完全匹配层）。

## 结论

**可完整追踪的两条障碍是 Wood 阈值处的背景层势病态，以及人工竖直边界造成的 DtN Dirichlet 极点。后者已有相同模型、相同导模输出的 RtR 补救；前者已有多种散射层面的补救。** 本轮只保留一项有实际用途的核查：固定 $\beta$ 导模求根在背景 Wood 阈值附近的覆盖与精度。它目前是已知补救向完整导模算子的移植问题，还不足以认定为文献中的新开放问题。

另找到一个作者明确承认的理论缺口：修正窗口传输 BIE 的唯一性及无限窗口极限。本轮未找到同一方程的关闭结果，但它没有已报告的失效，而且不是当前仓库所用的代理周期化方程，不据此安排实现任务。**可直接据本轮证据立为新研究课题的项目数为零。**

## 范围、日期与检索

检索日期：2026-11-08。首轮限时 90 分钟。目标是二维、无损、标量传输波导，在固定切向 Bloch 参数下求导模频率与场。散射场、体能带和局域本征模分开记录；跨输出迁移逐条说明理由。

独立检索使用一般学术网页检索、arXiv、作者出版目录及 SIAM、Springer、Optica、Wiley、Global Science、Royal Society 的原始记录；实质判断来自下列原论文的方法、讨论及数值段落。主检索式包括 `periodic layer potentials Wood anomaly transmission`、`quasi-periodic Green function guided modes`、`photonic crystal waveguide DtN Dirichlet eigenvalues Robin-to-Robin`、`Fredholm determinant close eigenfrequencies`、`corrected windowed integral equation uniqueness`、`periodic half-strip radiation condition`，并分别加上 2024、2025、2026 和作者名。这里的“未找到”限于这些检索及下列引用链，不表示穷尽文献。

前向追查在后文正文及参考表中核对：BG2010/2011 → Cho–Barnett2015（Remarks1、3）；Fliss2013 → FKS2015（§1、参考文献5、13）；Cho2015 → Pérez-Arancibia等2019（引言对代理法和 shifted Green 的比较）；Strauszer-Caussade等2023 → Tan等2026（参考文献31）→ Matsushima–Isakari2026（参考文献25、26；也列 Cho2015 为16）；Zhao–Barnett2015 → Bruno等2026（参考文献34）。没有取得完整引文数据库的全部 citing 列表。

## 第一遍：作者报告的问题，先于仓库对照保存

以下初单先按原论文形成，尚未对照本仓库。后续补救不改写这份初单。

| 初单 | 原论文与准确位置 | 模型、输出、步骤和后果 | 陈述类别与迁移边界 |
|---|---|---|---|
| I1：背景 Green 函数的 Wood 发散 | Barnett–Greengard 2011，刊页 70–71 §1；84–85 §5；Fig. 6。另见 Barnett–Greengard 2010，作者稿 PDF pp.11–12 §3.3、Fig.3、Remark 6 | 二维无损介质圆柱阵列的受迫衍射：QP Green 函数有 −1/2 次幂奇性，接近 Wood 时舍入误差发散；单纯加密 Sommerfeld 节点仍有条件数约 $1/\lvert k_n\rvert$，精确 Wood 只能保留很少数字。2010 体能带例子在“空晶格”谱与目标能带交点显示无法超过约 $\sqrt{\epsilon_{mach}}$ 的分辨率 | **作者明确的失效及数值观察**。受迫场与体能带各自记录；可迁移的是相同背景 QP 核及阈值，不是“导模本身不存在”或“所有边界积分都失败” |
| I2：DtN 的局部与半带 Dirichlet 异常频率 | Fliss 2013，作者稿 PDF pp.10–11，Thm.4.1、Remark4.2；Fliss–Klindworth–Schmidt 2015，刊页82 §1、107–114 §5、Figs.3–4、8–11 | 二维标量光子晶体线缺陷，固定准动量求频率和导模。半带 Dirichlet 本征值处 DtN 不定义；局部单胞 Dirichlet 本征值使构造不稳定。2015 Fig.3 的 DtN 拟 Newton 距离函数模停在约 $10^{-4}$ 并振荡；包含半带异常值的插值也可不收敛 | **理论排除集加作者实际失败例**，不能只用 2013 的假设推断失败。这里的边界是人工竖直边界；坐标轴按论文可互换 |
| I3：辅助解析延拓产生非物理小奇异值 | Barnett–Greengard 2010，作者稿 PDF p.20，§5.1 末段 | 二维介质体能带，夹杂越过单胞边界，方法 B3 用 Bessel 展开延拓周期修正场。远端高振荡非物理密度使第二小奇异值由 $10^{-4}$ 降至 $10^{-6}$；会遮住追踪最小奇异值的目标极小。作者拟另研更不敏感的搜索方法 | **作者数值观察及明确后续方向**。只对同类跨边界延拓/冗余表示有迁移理由，不能泛化到所有导模求解 |
| I4：近重根使行列式找根失去精度 | Zhao–Barnett 2015，作者稿 PDF pp.15–17 §8，Eq.(44) | 有界二维 Dirichlet 腔本征频率；行列式扰动引起根误差反比于根间距，双根附近仅约保留 $\sqrt\epsilon$。故单纯提高根搜索迭代次数不补救 | **作者分析及算法限制**。根的局部代数因子可迁移到解析导模 NEP；腔的 CFIE 定理本身不可直接迁移到周期传输问题 |
| I5：外域伪共振/孔洞伪根 | Zhao–Barnett 2015，作者稿 PDF pp.13–16，Lemma7.1、Thm.7.2、Eq.(39)、Fig.5 | 有界 Dirichlet 腔的纯双层表示：孔洞 Neumann 频率产生错误零点；强凹形外共振可靠近实轴而被误认为腔本征频率 | **作者反例和理论机制**。涉及特定纯双层表示；尚无依据断言介质 Müller 传输表示具有同一伪根 |
| I6：低频/高纵横比条件数与参数自动选择 | Barnett–Greengard 2011，刊页87 §7 | 单向周期介质衍射；作者明确列出很低频与高纵横比的病态、参数 $H,\lambda,\delta,P,Z$ 的自动选择及 Conjecture2 的证明待研究 | **作者当时的开放问题**。是否落入固定 Bloch 参数导模的目标频段、是否已被分层/其他表示解决，须另查 |
| I7：修正窗口方程的唯一性与无限窗口极限尚无理论 | Strauszer-Caussade 等 2023，OA early-view PDF p.29，§8 末，方程(91)、(99)后的两段 | 二维正介质传输阵列的受迫准周期散射。作者证明有限窗口方程 Fredholm，但明确说唯一性难证，数值支持唯一性猜想；现用空间不含人工竖直边界上不衰减的迹，不能直接处理 $A\to\infty$ | **作者明确的理论缺口；不是观察到不唯一**。若将这种窗口算子用于导模求根，需要额外检验其核与物理场的对应及本征值收敛；这是本文推断，不是原文结论 |
| I8：全局展开构造 DtN 的加密精度地板 | Yuan–Lu–Antoine，作者稿《Modeling Photonic Crystals by Boundary Integral Equations and Dirichlet-to-Neumann Maps》PDF pp.17–18，Fig.5、Table1，式(32) | 二维非圆形介质夹杂的体能带：作者明确说边点数 $N$ 过大时全局展开病态会影响精度，表中非单调收敛，约 3–4 位有效数字 | **作者数值观察**。只有沿用该全局展开才会迁移；不据此断言所有 BIE–DtN 导模计算存在同一精度地板。版本首页写 2009-09-18，不能按文件名中的 2008 推定版本页码 |

## 第二遍：逐项尝试关闭

以下结论只针对列明的模型与输出；“已解决”不等于获得导模频率的可靠误差界。

| 初单 | 后续补救、位置及结果 | 关闭结论与剩余边界 |
|---|---|---|
| I1 | BG2011 刊页84–85 §5、式(5.2)：补入掠射波及辐射约束；Wood 介质例场值达到14位，预条件后条件数约 $3.4\times10^3$。Cho–Barnett2015 作者稿 p.7 Remark1、p.17 Remark3：有限层不施加多余的双向出射条件，稳定地消去代理系数；pp.21–22 Fig.4 的精确 Wood 例通量误差 $5\times10^{-10}$。Pérez-Arancibia 等2019 作者稿 pp.12–13 Thms.3.4–3.5：shifted-Green RtR 算子可逆，需避开离散的坏移位并把新增源放在层外；p.14 Remark3.6 讨论夹杂扩展。Strauszer-Caussade 等2023 pp.18–19 Fig.4、pp.29–30 Fig.7：朴素窗口失败，有限秩辐射修正后在同一 Wood 算例超代数收敛。Tan 等2026 预印本 pp.12–14 Thm3.2、Remark3.4、p.23 §6：解释朴素 PML 的辐射约束病态并作有限模修正 | **“散射核在 Wood 处无可用 BIE”已被否定。** 层状介质定理不能直接充当两侧周期半带导模求根定理；场收敛图也不等于导模谱收敛。完整导模 NEP 是否有无伪核、稳定的跨阈值表示，须按具体表示核对，不能以“Wood 未解决”立题 |
| I2 | FKS2015 刊页87 Thm3.1：实非零 Robin 参数下，半带 RtR 在本质谱外良定，无 Dirichlet 禁频；刊页83–84 Eq.(2.1)、Fig.1 已允许两侧不同晶体。刊页108 Figs.3–4、111 Fig.8 对照相同导模/表面模：DtN 距离函数模停在约 $10^{-4}$，RtR 收敛；图4(b)小区间的 RtR 频率误差低于 $10^{-10}$（图读值）。全局极点不能靠缩小 DtN 插值区间消除 | **相同模型、相同固定准动量导模输出已解决。** 局部单胞的 Robin 化只解决局部极点；完整 RtR 耦合避免重新取半带 DtN 逆引入全局极点。这是本轮保留的已解决实例 |
| I3 | BG2010 PDF p.20 明确报告问题；未找到对该 B3 跨界延拓表示的直接关闭定理 | **所查范围状态未定，迁移有条件。** 更换不需要远端延拓的表示可绕开；没有证据表明目标几何触发同一机制 |
| I4 | Zhao–Barnett2015 PDF pp.16–17 §8 已给近重根转用矩阵奇异值的算法。Bruno–Santana–Trefethen2026，arXiv v2 PDF p.7 §5、p.10 §6.3：自适应 AAA 标量预解式加割线，以及 block SS/Beyn 的块矩方法；明确指出采样不够会有假极点，需加密检验 | **算法补救已有；多重谱点的完整识别仍需块/秩信息。** 不能把任一标量行列式或标量 AAA 的收敛图当作不漏模保证；也未找到本模型中这些方法都无效的例子 |
| I5 | Zhao–Barnett2015 PDF pp.14–15 Thm7.2、Eq.(39)、Fig.5 的 combined-field 在其有界 Dirichlet 模型排除伪根 | **原模型已解决；对正介质 Müller 模型没有所需的失败证据。** 不迁移 |
| I6 | Cho–Barnett2015 pp.21–24 Tables1–2、Figs.4、6 已处理大量层及复杂形状；这不证明所有低频/高纵横比条件数问题均解决。本轮未找到 BG2011 所有自动参数问题的逐项关闭 | **所查范围状态未定，但未落实为目标导模任务的瓶颈。** 不把旧论文未来工作清单直接保留为当前问题 |
| I7 | Tan 等2026 的 Thm3.2 估计尾算子，并非修正窗口方程的唯一性定理。Matsushima–Isakari2026 预印本 PDF p.6 Thm2.6、p.8 Thm2.8 给出含 Wood 的唯一性、频率一致离散误差与条件数结果，但模型是 Dirichlet 周期曲面上方衍射，不是封闭介质杆的窗口传输系统 | **未找到同一传输窗口方程缺口的关闭，状态未定。** 原作者数值支持唯一性，不能写成已观察到假模或精度失效。局部散射唯一性与全局波导本征模的存在不可混淆 |
| I8 | 高阶 Nyström、代理周期化等后续表示避免必须使用该全局展开，例见 BG2011 §5、Cho–Barnett2015 §4。未找到把 Yuan 等式(32)本身改造后建立高精度稳定性的后续证明 | **该表示的限制有原文依据；不是通用 BIE/DtN 精度极限。** 不直接移植其3–4位地板到其他离散格式 |

**进一步反证检查。** Petropoulos–Turc2025 作者上传全文 pp.2–3 确实报告 Sommerfeld 轮廓变形与 Wood 奇性相互作用造成误差峰；其模型是自由空间声软离散阵列、连续横向 Fourier 积分和受迫场，不是固定切向 $\beta$ 的离散通道导模频率。它支持“某种 RtR 实现仍可能受 Wood 影响”，不支持“RtR 普遍失败”。本文尚未核对该文完整数值补救，不据此立题。

## 最后一遍：仓库相关性与取舍

初单和补救表保存后，才阅读 [求解器说明](../../../draft/bie-solver/README.md)、[加边实验的限制](../../../test/bie-bound/pole-free-v1/README.md)及 [Wood 搜索记录](../../../test/bie-bound/wood-fallback-v1/README.md)。没有用旧查新结论生成初单，也没有复核或重跑这些实验。

### 条件保留：Wood 附近的导模搜索覆盖与共享核误差

- **对用户的后果。** 当前闭合仍在上游用含 $1/\gamma_m$ 的胞元提取器，精确 Wood 不可用。排除带意味着该频段未搜索；单纯换平方根变量保留共享 Green 误差。仓库记录在 $t\simeq\pm1.2\times10^{-4}$ 时，细网格根与改变 Green 拟合后的参考相差约 $(6.27,6.47)\times10^{-11}$，两网格根差只有 $(3.82,3.99)\times10^{-12}$（Wood README 第17行）。这些是既有浮点记录，不是本轮获得的误差界。
- **迁移理由。** 固定 $\beta$ 后，背景层势中的同一个 $\gamma_m=\sqrt{\rho_e k^2-(\beta+2\pi m/d)^2}$ 出现于胞元核及提取器（BG2011 刊页70，式(1.6)–(1.7)，交换坐标）。背景阈值可以位于两侧周期介质的公共带隙内。因此核病态会传入导模匹配，即使周期半引线的衰减空间仍分离。原论文证明的是该核/胞元步骤的问题，不是全局导模的物理奇异性。
- **最近补救及增量。** BG2011 §5 的掠射补全、Cho2015 Remark1 的有限层最少辐射条件，以及2019 shifted-Green/RtR 是可用起点。已有成果主要返回受迫场或有限层算子；本任务还需要闭合两个周期半引线后，保证表示的非零核对应非零导模场，并能在阈值附近定位根。不能把散射唯一性要求套在本来就要求非零核的全局本征问题上。
- **最便宜的判别。** 只取一个公共带隙内跨 Wood 的已跟踪导模，先将一个胞元换成上述一种有限层/Robin 表示，并用阈值有限的 Cauchy 或 Robin 迹连接；比较阈值两侧及阈值点的胞元残差、条件数、重构场和根。根的参考必须独立改变 Green 表示，不能只加密共享同一核的两套边界网格。**停止条件：** 若这个局部替换已使场和根在目标精度下稳定，就按实现修补结束，不扩大成“Wood 问题未解决”；若胞元仍失败，先查未移除的出射约束或奇异换元。只有局部恢复而全局核对应/谱收敛仍有反例或明确缺口，才考虑新的研究问题。本轮不运行此检查，也不预设成功。

### 排除的其他方向

I2 已有完整 RtR 半带闭合，当前加边实现又已针对同类极点作恢复；不能把旧消元失败作为新的普遍障碍。I3、I8 针对特定远端延拓或全局展开，尚无与当前几何/表示相同的触发证据。I4 的近重根问题有矩阵/块方法补救，现有孤立根记录不足以提出新的普遍失效主张。I5 属于另一种边界条件与表示。I6 尚未落实到当前固定 $\beta$ 公共带隙任务。I7 保留为文献待核实问题，但当前代理方程没有采用该有限窗口算子；它不能直接解释本仓库的误差地板。

## 已读原始来源与版本

以下链接对应原论文或作者/机构全文。上表页码严格使用这里列明的版本；没有把作者稿页码冒充期刊页码。

| 简称 | 论文、版本与实读位置 |
|---|---|
| BG2010 | Barnett–Greengard, *A new integral representation for quasiperiodic fields and its application to two-dimensional band structure calculations*, JCP229,6898–6914；[DOI](https://doi.org/10.1016/j.jcp.2010.05.029)，实读 [arXiv:1001.5464v1](https://arxiv.org/pdf/1001.5464v1)，§§3.3、5.1、6，PDF pp.11–12、20–21 |
| BG2011 | Barnett–Greengard, *A new integral representation for quasi-periodic scattering problems in two dimensions*, BIT51,67–90；[DOI](https://doi.org/10.1007/s10543-010-0297-x)。实读本地出版 PDF 的刊页70–71、84–87，§§1、5–7 |
| Cho2015 | Cho–Barnett, *Robust fast direct integral equation solver for quasi-periodic scattering problems with a large number of layers*, Optics Express23,1775–1799；[DOI](https://doi.org/10.1364/OE.23.001775)，[作者全文](https://users.flatironinstitute.org/~ahb/dartmouth/papers/mlqp.pdf)。实读作者 PDF pp.6–7、15–17、21–24，§§1、3、4、5 |
| Fliss2013 | *A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides*, SISC35,B438–B461；[DOI](https://doi.org/10.1137/12086697X)，实读 [arXiv:1202.4928v2](https://arxiv.org/pdf/1202.4928v2)，PDF pp.10–11 Thm4.1、Remark4.2及p.23 §6 |
| FKS2015 | Fliss–Klindworth–Schmidt, *Robin-to-Robin transparent boundary conditions for the computation of guided modes in photonic crystal wave-guides*, BIT55,81–115；[DOI](https://doi.org/10.1007/s10543-014-0521-1)，[作者全文入口](https://perso.ensta.fr/~fliss/Recherche_files/BITN-S-13-00176.pdf)。实读本地出版 PDF：刊页82–90及107–115，§§1–3、5–6 |
| Huang2007 | Huang–Lu–Li, *Analyzing photonic crystal waveguides by Dirichlet-to-Neumann maps*, JOSAB24,2860–2869；[DOI](https://doi.org/10.1364/JOSAB.24.002860)，[作者全文](https://personal.cityu.edu.hk/mayylu/papers/yuexia4.pdf)，PDF pp.2、7–9。它实际固定频率求 Bloch 乘子，横向用截断超胞；不能当作已计算固定 $\beta$ 的半带闭合频率 |
| Yuan等 | Yuan–Lu–Antoine, *Modeling Photonic Crystals by Boundary Integral Equations and Dirichlet-to-Neumann Maps*；[DOI](https://doi.org/10.1016/j.jcp.2008.01.014)，[实读作者文件](https://personal.cityu.edu.hk/mayylu/papers/jianhua3.pdf)，PDF pp.1、17–18。文件首页标注2009-09-18；这里只按该文件定位，不混用出版版页码 |
| Pérez-Arancibia等2019 | Pérez-Arancibia–Shipman–Turc–Venakides, *Domain Decomposition for Quasi-Periodic Scattering by Layered Media via Robust Boundary-Integral Equations at All Frequencies*, CICP26,265–310；[DOI](https://doi.org/10.4208/cicp.OA-2018-0021)，[实读作者稿](https://www.math.lsu.edu/~shipman/articles/PerezArancibiaShipmanTurcVenakides2018.pdf)，PDF pp.2–3、6、12–14、21、25、29–30。闭合的是有限层；夹杂推广见Remark3.6，数值夹杂例是完全导体，不能冒充正介质杆导模验证 |
| Strauszer-Caussade等2023 | Strauszer-Caussade–Faria–Fernandez-Lado–Pérez-Arancibia, *Windowed Green function method for wave scattering by periodic arrays of 2D obstacles*, SAM150,277–315；[DOI](https://doi.org/10.1111/sapm.12540)，[实读 OA early-view 全文](https://ris.utwente.nl/ws/portalfiles/portal/287500311/Strauszercaussade_2022_Windowed_green_function_method_for_.pdf)，PDF pp.18–19、29–30、33，§§7–10。页码按39页 early-view，不按期刊277起换算 |
| Tan等2026 | Tan–Pérez-Arancibia–Yin, *A Uniformly High-Accuracy PML-BIE Method for Scattering by Periodic Arrays of Obstacles: The 2D Case*；[arXiv:2606.07971v1](https://arxiv.org/pdf/2606.07971v1)，预印本，实读 PDF pp.12–14、23，Thm3.2、Remark3.4、§6 |
| Matsushima2026 | Matsushima–Isakari, *A frequency-stable Nyström method for two-dimensional diffraction by periodic gratings at and near Wood anomalies*；[arXiv:2608.08172v1](https://arxiv.org/pdf/2608.08172v1)，预印本，实读 PDF pp.1–4、6、8，§§1–2、Thms.2.6、2.8 |
| Zhao2015 | Zhao–Barnett, *Robust and efficient solution of the drum problem via Nyström approximation of the Fredholm determinant*, SINUM53,1984–2007；[DOI](https://doi.org/10.1137/140973992)，实读 [arXiv:1406.5252v3](https://arxiv.org/pdf/1406.5252v3)，PDF pp.13–17 §§7–8，尤其p.17 Eq.(44)、Fig.6 |
| Bruno等2026 | Bruno–Santana–Trefethen, *Evaluation of Resonances: Adaptivity and AAA Rational Approximation of Randomly Scalarized Boundary Integral Resolvents*, SISC48,A1260–A1283；[DOI](https://doi.org/10.1137/24M1690680)，实读 [arXiv:2405.19582v2](https://arxiv.org/pdf/2405.19582v2)，PDF pp.2、7、10、15，§§5、6.3、7 |
| Petropoulos2025 | Petropoulos–Turc, *Domain decomposition multiple scattering solvers by semi-infinite and infinite arrays of discrete identical scatterers in two dimensions*, Phil. Trans. R. Soc. A383,20240355；[DOI](https://doi.org/10.1098/rsta.2024.0355)，[作者上传全文](https://www.researchgate.net/publication/393871031_Domain_decomposition_multiple_scattering_solvers_by_semi-infinite_and_infinite_arrays_of_discrete_identical_scatterers_in_two_dimensions)，仅实读pp.1–4引言和模型，不能支持其余数值节的判断 |

## 未查分支与访问限制

**访问限制。** FKS2015 的作者服务器本轮返回502，实读的是已有的同名出版 PDF。Petropoulos2025 出版社及下载按钮未返回 PDF，作者上传的公开网页全文可以阅读，故仅采用已读的引言和模型。Fliss–Joly–Lescarret, *A Dirichlet-to-Neumann approach to the mathematical and numerical analysis in waveguides with periodic outlets at infinity*, PAA3(2021),487–526，[DOI](https://doi.org/10.2140/paa.2021.3.487)：HAL入口被拦，出版社PDF链接返回HTML，本轮只核对元数据，未用于实质结论。一个搜索结果误连到同卷其他文章，身份检查后弃用。

**未查完的分支。** 未系统穷尽全部前向引用；未逐篇核对 Fliss2021 之后半带传播算子在零群速度/本质谱边缘的分析；未完成 BG2011 Conjecture2 的全参数后续证明追查；未对 I3 的跨界延拓表示逐版本寻求稳定化；未核对 block SS/Beyn 对同一传输导模模型的多重谱点实例与完备性结论；未核对2026年新出现的 BEM 横向边界条件论文全文。三维、电磁矢量、符号变化介质及逆问题均未扩展。以上没有变成“方法失败”或“开放问题”的证据。

**核查。** 初单保留了作者陈述、排除假设、实际观察与本文推断的区别；逐项追查补救并保留 I2 的同模型已解决实例；最后才对照仓库；每项实质文献判断附版本和位置。没有数值运行。后续数值判别仅为建议，尚未执行。
