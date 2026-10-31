# 2026-10-31 选题调研的独立价值审查

`topic-survey` 表示研究专题筛选；本文件 `review` 是独立审查记录，不是主推荐报告。任务窗口为 2026-10-31 01:49:23–03:19:23 UTC。复核者只写本文件，由主研究者统一整理和提交。

状态：**Preliminary review; literature verification is incomplete.** 本轮尚未证明新定理，也没有数值实验。以下明确区分已读原文、摘要、已有结论、待核问题和价值判断。主报告尚未出现时先独立形成第1–4节，之后另记对主稿的审查，避免依其排序反推理由。

## 1. 价值判据：得到定理后，多知道了什么

不能以“困难”“周期端更一般”“现在能做”代替研究意义。我使用四个问题作筛选：

1. **区分能力**：结论能否区分两种此前同样可能的可观察行为，例如长器件传输与局域化、有限腔真束缚态与泄漏共振、同样慢光但不同扰动敏感性？
2. **不可替代性**：已有定理能否经模型改写或标准扰动得到？证明要增加的是否只是实现细节、现有算法误差常数或例行适配？
3. **失败的意义**：反例或不可能性定理是否也会改变设计认识？若只能成功叙事而不能陈述有价值的失败结论，题目通常尚不清晰。
4. **近期可判定性**：第一个月能否完成一个决定继续/停止的数学检查，而不是先搭建全套新工具再判断题目有没有内容？

上轮A“异质两端导带不完全水平”应退出第一推荐。无全空间点谱是有意义的谱分类，但排除严格水平段不量化可用带宽、群速度、传输长度、局域场强或杂散模态数；允许任意近平带时，它不能单独回答用户关心的传播能力。将其输运标准推论另包装为第二贡献也没有增加价值。更换两侧背景可能产生技术困难，却不自动产生值得优先解决的问题。见 [[research/planning/p-new-directions-20261030]] 及上轮独审 [[research/planning/review-new-directions-20261030]]。

## 2. 所有新方向先过的模型门：projected gap 不等于失去周期性后的隔离

本文件以 $x$ 为横向无界坐标，$y$ 为原周期方向，$A=-\rho^{-1}\Delta$ 为 $L^2(\mathbb R^2,\rho)$ 中由 $\int|\nabla u|^2$ 定义的质量型算子，$0<c\le\rho\le C$，$\mu=k^2$。原直波导沿 $y$ 周期；$A(\beta)$ 是固定准动量纤维。

**必须分开的两类问题。** 固定 $\beta$ 的共同 projected gap 只排除同一 $\beta$ 的体传播通道。截短波导、加入非周期局部缺陷、沿轴向随机化，均破坏该守恒量；其它 $\beta'$ 的体通道可能开放。因此：

- 研究有限线缺陷的 $L^2(\mathbb R^2)$ 腔模、或闭合的一维随机有效模型，需要另假设目标频率位于完整二维体谱隙，或独立处理体辐射。
- 仅有 projected gap 时，有限器件一般应问散射极点/共振与辐射，而不能直接把无限直导波的实纤维本征值当有限腔真本征值。
- 直波导单个固定 $\beta$ 的简单模态及其谱距证据不能提供上述完整体隙。当前 [[research/explorations/spectral-counting/STATUS]] 的证据范围应保留。

这不是文献新结论，而是选题边界检查。它能淘汰把同一条 $(\beta,k)$ 曲线直接解释成有限器件性能的假问题。

## 3. 独立宽筛：三个值得检验的价值对象，尚非三个已确认新题

### 3.1 弱无序下的可用传播长度，尤其慢光边缘的联合极限

**具体问题。** 在真正二维体隙内部，给定一条孤立导带的非退化边缘 $\mu_*+\alpha q^2+O(q^4)$，沿轴向施加有界、均值为零、短程相关的小随机材料扰动，能否从连续二维算子推出适用于长器件的有效随机传输过程，并在无序幅度和离带边距离同时趋零时给出局域化/传输长度的交叉规律？

**多知道什么。** 它回答“完美带图中的慢光能在多长的实际器件中维持”，并能区分同群速度但不同材料场重叠的设计；这比非平带直接。物理与数学随机介质研究者会关心其有效系数和失效区间，不只是计算者。

**不可认领的部分。** 无序导致局域化、$v_g^{-2}$ 型薄样品背散射、带边的非通常尺度，以及模式形状决定散射都不是新思想。Kirsch–Warzel已有连续随机表面势的谱/动力学局域化；Patterson等2009已明确指出多重散射及Beer–Lambert失效；Thompson等2026已在相同群折射率下降低背散射。把这些现象在本模型上画图或重新求Born系数不足立题。

**可能留下的贡献。** 只有连续波导到随机有效过程的受控长尺度约化、联合极限中的均匀性，或可控材料类中无法消除的耦合/可消除条件，才值得进一步调查。必须先核查随机波导与随机矩阵带边极限的既有覆盖，不能把经典一维指数当新定理。难度高，当前不宜承诺完整Anderson局域化理论。

**最小否证门。** 先定义随机模型、实际观测量和长度尺度；列出投影补空间的能量隔离。若只有projected gap，应改成包含辐射的开放通道问题，而不是擅用一维闭模型。若已有长尺度约化可直接应用，降为应用退出主推荐。

**进一步文献挑战。** Sadel–Schulz-Baldes2007 Theorem1已经严格给随机Jacobi矩阵的带内/带边/隙侧联合尺度及余项，包含能量偏移 $\sigma^{4/3}$ 与Lyapunov指数 $\sigma^{2/3}$。Garnier2007和Garnier–Sølna2008也已分析连续随机波导、长尺度扩散及倏逝模效应。因此“连续＋随机”“带边联合极限”“补入倏逝模”分别都不足成为贡献。剩余问题须精确指出周期开放横向几何与既有定理之间不能例行跨越的一步。

不要混淆三个量：几乎处处的Lyapunov衰减率、平均透射强度的衰减率、单个局域态的空间宽度。随机平均与对数不能交换。Faggiani等2016关于最小模态宽度的式(4)是物理预测与数值/实验支持，明确省略复杂多重散射，并非所有随机实现的严格下界；尤其无界Gaussian扰动不能直接放进全空间一致正、有界的材料类。不能只换符号就把其“阈值宽度”、经典局域化长度和我们拟证的量当成同一目标。

### 3.2 从无限导带到有限线缺陷腔：完整计数及端部修正

**具体问题。** 在完整二维体隙内，将周期线缺陷保留 $N$ 个胞元、两端以固定局部几何终止；无限直导波在某紧频段只有一对相反传播模态。有限腔的全部本征值是否由传播相位加两个端部反射相位的量子化条件给出，端部局域态如何补入，误差如何在慢光边缘退化？

**多知道什么。** 从无限带图预测可制造的有限腔：哪些频率会存在、数量怎样随长度变化、哪些模态完全由端部产生。若完整性成立，便能区分“带图给出的纵向模态”和“截断诱生的端态”，避免只对准若干数值频率。

**不可认领的部分。** Fabry–Perot相位条件、端部模式失配和Q值调节已有大量工作；不能把 $2N\beta+\phi_-+\phi_+=2\pi m$ 本身当新公式。长有限阵列由两个半无限端拼接也至少已有Thompson–Linton–Porter2008。若只给远离阈值的形式条件或 $O(N)$ 主计数，预期价值有限。

**可能留下的贡献。** 对连续二维波导给出“所有模态”的分解，包含端态及带边过渡，并明确完整体隙与仅projected gap下的本征值/共振分野。必须先查有限截断周期算子与多端散射量子化的成熟理论；本轮不宣称开放性。难度中高到高，离当前工具较近，但“离工具近”不是保留理由。

**最小否证门。** 构造端部半无限问题，检查是否有端态或阈值共振；若不能定义单通道反射相位或其它闭通道不一致小，先停止标量公式。若只有projected gap，则应明确改为散射极点问题，不能报真腔模定理。

### 3.3 有资源约束的慢光极限：追问能否任意窄，而非是否恰好平

**具体问题。** 对固定轴向周期、缺陷宽度、材料上下界、频率窗口及横向隔离量的明确材料类，能否让一条隔离导带在规定准动量区间上任意窄？若不能，最佳量级由哪些资源控制；若可以，必须展示不逃逸这些约束的序列。

**多知道什么。** 它给设计的可达边界，回答有限材料资源能否换取任意慢光；反例和下界均有意义。它直接加强了旧A过弱的定性结论。

**很容易变成伪创新。** Miller2007已有一维线性慢光器件可延迟比特数/延迟带宽限制，且注明可按模式重叠推广单模系统；不能把“有基本极限”当新思想。一维Hill算子最低带宽的 $L^\infty$ 约束优化至少已有Ashbaugh–Svirsky1992这一直接题名先例（正文未核；不据此断言覆盖）。若只在紧有限维参数盒中用连续性加非平带推出某个未知正数，则是紧性推论，不是有用性能极限。

另一应淘汰的“新定理”是把单调分支上的 $d\omega=v_g\,d\beta$ 积分。若 $0<v_g\le v_0$ 且准动量区间长不超过 $2\pi/a$，立刻有 $\Delta\omega\le 2\pi v_0/a$；这一带宽与群速度比较只是运动学恒等式的后果。必须提出超出它的材料、横向约束或可达性问题，不能因用户否定定性A就自动保留“定量A”。

**最低价值门。** 需要可解释的参数依赖或逼近极限的构造，并审查几何细化、共振腔增多、对比度/宽度增长、带簇换标及谱隔离丢失等逃逸方式。点态群速度下界通常不可能，因为带边和互易驻点存在；应研究规定区间振幅、可用频带或脉冲指标。难度很高，既有基本极限的覆盖尚未查全，暂作挑战问题而非优先保证。

## 4. 初轮原始来源及阅读深度

以下仅为限定范围检索，不是系统综述；2026新作的命中不说明全部近期文献已覆盖。没有检索结果不等于开放问题。只写本文件的限制高于技能默认下载流程；本轮在线读原文，未下载文献。

1. **Dominic Thompson, Antonia Neill, Nir Rotenberg, Stephen Hughes (2026).** *Reducing disorder-induced backscattering in photonic crystal waveguides through inverse design*. Physical Review A **113**, 023515. DOI [10.1103/pqdc-34mp](https://doi.org/10.1103/pqdc-34mp)；[arXiv:2507.05429v2](https://arxiv.org/html/2507.05429v2)，2026-02-11版。**原文已读§I、§II.2及式(9)–(11)附近**：三维无损、频率无色散介电板，单模、低于光线；孔壁随机扰动，薄样品Born型每胞元背散射指标。模式场分布可在相同群折射率下降低该指标。作者明确长样品多重散射不在所做优化中；不能把指标当任意长度传输定理。未独审数值优化。
2. **M. Patterson, S. Hughes, S. Schulz, D. M. Beggs, T. P. White, L. O'Faolain, T. F. Krauss (2009).** *Disorder-induced incoherent scattering losses in photonic crystal waveguides: Bloch mode reshaping, multiple scattering, and breakdown of the Beer-Lambert law*. Physical Review B **80**, 195305. DOI [10.1103/PhysRevB.80.195305](https://doi.org/10.1103/PhysRevB.80.195305)。**仅出版商摘要**；尚未读正文，未核具体方程或适用尺度。摘要明确模式形状、多重散射与群速度尺度失效；足以阻止认领概念首创，不足以判定连续联合极限定理已有覆盖。
3. **Werner Kirsch, Simone Warzel (2006).** *Anderson localization and Lifshits tails for random surface potentials*. Journal of Functional Analysis **230**, 222–250. DOI [10.1016/j.jfa.2005.05.009](https://doi.org/10.1016/j.jfa.2005.05.009)；[arXiv:math-ph/0412079v1](https://arxiv.org/html/math-ph/0412079v1)，2004稿。**原文已读§1.1、Theorems 1.4、1.6**：沿界面周期的背景允许两个晶体，另加非负随机bulk势和由非正独立同分布系数组成的非负单点轮廓surface势；相关可积/衰减、分布端点及Hölder条件；表面谱底低于bulk谱底。结论含Lifshits尾及低能谱/动力学局域化。不是光学质量型正能内部隙的直接应用，也不是弱无序长度的统一渐近；“异质界面＋随机局域化”宽泛组合却已有。
4. **David A. B. Miller (2007).** *Fundamental Limit to Linear One-Dimensional Slow Light Structures*. Physical Review Letters **99**, 203903. DOI [10.1103/PhysRevLett.99.203903](https://doi.org/10.1103/PhysRevLett.99.203903)；[arXiv:0710.3575](https://arxiv.org/pdf/0710.3575)。**读公开作者稿PDF pp.2–6，式(2)、(5)–(7)**。线性一维波动方程，带宽远小于中心频率、长度远大于背景波长；由可控制正交波数目给延迟比特数上限，资源为介电相对变化和长度。文中指出单模波导可按模式重叠重标度，延迟带宽式另用脉冲宽度/带宽近似。不能当任意二维多模/完整无限带宽的现成下界，也不能忽略其单模覆盖后宣称“首次基本极限”。
5. **Christophe Sauvan, Philippe Lalanne, Jean-Paul Hugonin (2005).** *Slow-wave effect and mode-profile matching in Photonic Crystal microcavities*. Physical Review B **71**, 165118. DOI [10.1103/PhysRevB.71.165118](https://doi.org/10.1103/PhysRevB.71.165118)；[arXiv:cond-mat/0502664](https://arxiv.org/pdf/cond-mat/0502664)。**读作者稿PDF pp.3–7，式(1)–(2)及其后误差讨论**。有限N缺孔三维板腔；以低于光线的无损基Bloch导模和两端反射系数给共振频率/Q的FP解释，端部向外辐射；承认忽略高阶倏逝Bloch模造成偏差。它直接覆盖“由导带和反射相位解释有限腔”这一想法，不提供本文候选所要求的全部谱完整性定理。
6. **I. Thompson, C. M. Linton, R. Porter (2008).** *A new approximation method for scattering by long finite arrays*. Quarterly Journal of Mechanics and Applied Mathematics **61**, 333–352. DOI [10.1093/qjmam/hbn006](https://doi.org/10.1093/qjmam/hbn006)；[作者机构书目](https://people.maths.bris.ac.uk/~marp/publications.html)。**出版商摘要与作者书目已核，正文未独立核**。二维Helmholtz刚性圆柱长阵列，将半无限端解组合；不是正密度二维晶体线缺陷的直接定理。本文只据此否定“拼两个端本身首次”的表述，不认领其误差定理。
7. **Frédéric Klopp (2016).** *Resonances for large one-dimensional “ergodic” systems*. Analysis & PDE **9**, 259–352. DOI [10.2140/apde.2016.9.259](https://doi.org/10.2140/apde.2016.9.259)；[arXiv:1210.1000v2](https://arxiv.org/html/1210.1000v2)，2013稿。**原文已读模型、Theorem 0.1，定位Proposition 1.4**。一维离散周期/随机势截在长区间、外部自由；周期情形在带内部紧区间且避开离散例外集，给共振实部密度和 $L\,\operatorname{Im}z$ 的解析极限曲线，更精细结果有逐根渐近。不是连续二维套用；但“无限带决定长有限共振分布”概念与一维精细理论已经存在。
8. **Mark S. Ashbaugh, Roman Svirsky (1992).** *Periodic Potentials with Minimal Energy Bands*. Proceedings of the American Mathematical Society **114**, 69–77. DOI [10.2307/2159784](https://doi.org/10.2307/2159784)；[JSTOR当期目录](https://www.jstor.org/stable/i337771)。**仅原出版目录元数据核验；原文不可由当前工具读取**。另见Kao–Osting2019原文参考文献[2]（其参考文献误列69–69，不照抄）。不将二手转写的具体极值结构当已核定理。
9. **Chiu-Yen Kao, Braxton Osting (2019).** *Extremal spectral gaps for periodic Schrödinger operators*. ESAIM: Control, Optimisation and Calculus of Variations **25**, article40. DOI [10.1051/cocv/2018029](https://doi.org/10.1051/cocv/2018029)；[arXiv:1805.04210v1](https://arxiv.org/html/1805.04210v1)。**读Theorem 1.1及证明**。固定晶格、固定第m隙、$0\le V\le V_+$，弱星紧性及带边连续性给最优gap-to-midgap比存在。此处目标不同，但说明“约束类紧性＋存在最优”已有常规路径，不应单独当强贡献。
10. **Owen D. Miller, Francesco Monticone (2026).** *Fundamental limits in photonics and electromagnetics: a tutorial*. [arXiv:2605.24738v1](https://arxiv.org/html/2605.24738v1)，2026-05-23。**读§5.9式(222)–(225)及其后未编号问题框，另读§6所列边界**。它明确指出一维延迟带宽界向二维/三维推广并不直接，提出从因果性及求和规则推导一般结构极限的问题；PDF题框标号尚未核，不在这里编造编号。这个原始作者提出的问题为“性能极限值得关心”提供具体依据，但不是本文更窄材料类已确认开放的证明，更不是现成可交定理。
11. **Christian Sadel, Hermann Schulz-Baldes (2007).** *Scaling diagram for the localization length at a band edge*. Annales Henri Poincaré **8**, 1595–1621. DOI [10.1007/s00023-007-0347-3](https://doi.org/10.1007/s00023-007-0347-3)；[arXiv:math-ph/0702051v2](https://arxiv.org/html/math-ph/0702051v2)，2008-02-20稿。**读§1设定、Theorem1、§2式(4)–(11)**。周期Jacobi背景、每L点一块的独立有界随机扰动、逐项中心化、正跳跃系数、非接触带边及随机迹一阶变化方差非零。定理给IDS和Lyapunov指数的椭圆/抛物/双曲区域与受控幂余项；带边层为 $E-E_b\sim\sigma^{4/3}$、$\gamma\sim\sigma^{2/3}$。它已经解决一个严格联合极限，不是待我们首次提出的尺度。
12. **Rémi Faggiani, Alexandre Baron, Xiaorun Zang, Loïc Lalouat, Sebastian A. Schulz, Bryan O'Regan, Kevin Vynck, Benoît Cluzel, Frédérique de Fornel, Thomas F. Krauss, Philippe Lalanne (2016).** *Lower bound for the spatial extent of localized modes in photonic-crystal waveguides with small random imperfections*. Scientific Reports **6**,27037. DOI [10.1038/srep27037](https://doi.org/10.1038/srep27037)；[出版商开放全文](https://www.nature.com/articles/srep27037)；[arXiv:1505.03472v2](https://arxiv.org/html/1505.03472v2)的2015稿题名为 *Lower bound for the spatial extent of localized modes in one-dimensional disordered periodic media*。**读刊本Results首小节式(1)–(4)及Methods宽度定义，并对照作者稿§II**。二次边、近似频移、FP相位/衰减阈值给宽度尺度，配2D波导计算及板实验。该尺度不是Lyapunov长度定理，也不是排除了罕见实现的概率硬界。
13. **Josselin Garnier (2007).** *The role of evanescent modes in randomly perturbed single-mode waveguides*. Discrete and Continuous Dynamical Systems–B **8**,455–472. DOI [10.3934/dcdsb.2007.8.455](https://doi.org/10.3934/dcdsb.2007.8.455)。**只核出版商摘要**；已定位有Proposition1等的全文检索片段，但尚未从原始公开PDF核完，不将片段升级原文定理检查。摘要已明确倏逝模耦合产生有效色散、小尺度随机涨落下可占主导。故“首次考虑倏逝模”应删；它对本周期导带边缘的覆盖尚未核。
14. **Josselin Garnier, Knut Sølna (2008).** *Effective Transport Equations and Enhanced Backscattering in Random Waveguides*. SIAM Journal on Applied Mathematics **68**,1574–1599. DOI [10.1137/070694909](https://doi.org/10.1137/070694909)。**仅出版商摘要**：弱随机幅度、相关长度同波长量级、长波导，允许显著背散射，以耦合模极限定理推导透反射矩。完整假设/定理未核，不据此声称覆盖本题；但长尺度随机传输从连续波导导出的方向早已存在。

## 5. 本轮规则和来源限制记录

已核对根AGENTS、AGENTS.override、research/AGENTS、根/研究README及研究状态；工作目录和分支正确。开始时工作区为空，HEAD相对origin领先一提交。总工作树约93MB量级，本文件预算不超过100KB。没有访问私有GitHub、运行MATLAB、安装依赖或更改网络/权限。

来源读取阻碍：打开PMC文章 `https://pmc.ncbi.nlm.nih.gov/articles/PMC4887989/` 返回浏览器/reCAPTCHA检查页，未点击、未重试或绕过；已完成题名和作者稿元数据检索，公开arXiv作者稿可正常读取，后续只使用该合法公开源。该受阻操作已停止，不影响独立筛选。arXiv部分旧稿无HTML返回404，正常PDF端点可读；未将技术404当访问授权。

本文件没有新增正式定理、proof环境、标签或编号；所有“可能贡献”都是筛选目标。主报告及现有证明/源码未修改。

## 6. 对后续主稿“纵向扰动后的泄漏/寿命”的先行审查门

02:00读到主目录README，尚未见主报告；其中列出的纵向扰动/寿命方向确实比旧A更贴近“是否传得出去”，但必须先选对谱对象。

**概念修复门。** 完美直波导的Bloch导波不是全空间 $L^2$ 本征态。一个沿轴向紧支撑的小缺陷，通常产生入射导波的散射，并不自动把这条广义本征态变成某个单一共振极点。若要研究极点寿命，须明确是哪种设置：有限腔模、原来的嵌入本征态，或者把轴向周期扩大为N胞元、折叠后使原导模成为超胞纤维的嵌入本征态。三者不能混称“导模受局部扰动后的寿命”。

**已有理论门。** 周期加倍/超胞折叠使原导模耦合辐射，$Q\sim\eta^{-2}$ 及对称保护，已有直接光子晶体先例：**Wenhao Wang, Yogesh Kumar Srivastava, Thomas CaiWei Tan, Zhiming Wang, Ranjan Singh (2023)**，*Brillouin zone folding driven bound states in the continuum*, Nature Communications **14**,2811，DOI [10.1038/s41467-023-38367-y](https://doi.org/10.1038/s41467-023-38367-y)，[原文开放全文](https://www.nature.com/articles/s41467-023-38367-y)。已读Introduction及Results式(1)–(2)和图1–3解释：硅板周期加倍，将原低于光线的导模折入辐射连续谱，数值/实验显示扰动幅度及准动量控制的Q尺度；不是一般连续周期端的谱定理。故“破坏原周期会泄漏”“首次由折叠得到高Q”“二阶辐射率”都不能直接认作新贡献。

**最低有价值的新增。** 可以保留的是某一明确的机制判定：例如原周期体介质的通道开启点附近，二阶辐射率何时不一致、如何分出真束缚态/虚态/泄漏极点，或者规定材料扰动族能否消除某个首阶辐射耦合。只把标准Fermi golden rule的均匀外部改为两种周期外部，除非暴露并解决了新的阈值机制，否则仍有“可做但价值不足”的风险。

**最低技术检查。** 明确物理/非物理解支、频率变量 $k$ 还是 $\mu=k^2$、未扰动态是否真本征态、开放通道数与阈值位置、出射通量归一化，以及辐射系数严格为正的材料条件。首阶耦合为零可能仅是对称性、傅里叶动量选择、材料场重叠零或路径抵消；“generic”必须带明确参数空间和拓扑，不能凭一次计算认定。

## 7. 对主稿“容量/单模频段”的先行审查门

**单模的量必须重定义。** 每个固定 $\beta$ 的一个简单纤维本征值，不等于固定频率只有一个传播通道。实验意义的右行通道数应在给定 $\omega$ 下数所有满足 $\omega_j(\beta)=\omega$ 且群速度为正的独立导波，简并点则用通量形式的正惯性；左行另数。一个非单调分支就可在同一频率多次相交。解析偶函数 $\omega_0+c\cos^2\beta$ 已说明“一条曲线”这一信息本身不能排除四个根；此例只是逻辑/运动学反例，不宣称已构造相应材料。

**容量的比较基准。** 固定频率通道数、全频带数、固定纤维gap内离散本征值数、净谱流、Landauer传输本征值的数目是不同对象。超胞折叠可增加图上分支条数，但不能凭表示方式增加物理通道。所谓“单模带宽”还须指定bulk辐射是否允许、是否只计某一极化以及通道开启端点怎样处理。

**价值门。** 一个材料约束下的可达通道上界、宽度/对比度和单模区间的限制，或两个设计在相同资源下的机制差异，都比“完成更多参数点的计数”有价值。若只把现有固定纤维端点惯性程序外加 $\beta$ 扫描，仍属于用户要求减少的算法扩展。若所得上界在物理可达数的量级上极差，也应说明其研究意义来自何种结构定理，而不是称作有实用设计预测。

**第一步**应是选定计数对象，给出对超胞改写不变的定义，并找一个已有宽波导/耦合导波极限核对资源量纲。若连这一点都未完成，不应以“容量”二字替代研究问题。

## 8. 2026高对比度新文献给出的实质反对与替代挑战

### 8.1 非周期连续到离散的约化本身已有强结果

**Habib Ammari, Borui Miao, Jiayu Qiu (2026).** *Resolvent Convergence and Patch Approximation for Subwavelength Guided Modes in Non-Periodic Systems of High-Contrast Resonators*. [arXiv:2605.30951v1](https://arxiv.org/html/2605.30951v1)，2026-05-29；[ETH机构记录入口](https://math.ethz.ch/sam/research/reports.leftnav.html?year=2026)。已读Assumption2.1及Theorem2.1所在设定、引言贡献、Theorem5.1定位；不是全篇证明审计。

它研究二维高对比度声学透射系统，有限多类型 $C^1$ 共振器、统一分离、有限胞几何覆盖及每胞非空共振器等条件；重标度后以电容算子近似内部问题，给算子范数意义的预解式收敛及patch算子范数误差。弯曲界面和非周期缺陷已在其范围。因此“首次不依赖Floquet处理弯曲/非周期缺陷”“首次连续到离散且可控误差”不能认领。当前固定对比度标量质量型并不直接满足其极限模型；但仅强调模型不同也不足建立独立价值。

### 8.2 一个更尖锐、但难度很高的随机问题

**Habib Ammari, Silvio Barandun, Jiayu Qiu, Alexander Uhlmann (2026).** *Long-range interactions and Anderson localisation for one-dimensional high-contrast resonator chain*. [arXiv:2607.04971v1](https://arxiv.org/html/2607.04971v1)，2026-07-06；[ETH报告2026-27](https://math.ethz.ch/sam/research/reports.leftnav.html?id=1182)。作者arXiv原文署名为Silvio，机构报告BibTeX缩为S.；不照抄搜索摘要中的Silvo。已读§1、§2模型、Theorem3.8定位及§5性质说明，未独审衰减证明。

三维自由外部中的一维共振器链，声学密度/模量透射且高对比极限；电容算子的远程相互作用为 $1/(r\log^2r)$ 量级。该衰减及有限链谱收敛是作者的定理，任意弱随机下局域化是其数值观察和待证问题，不能把§5标题当成已证明随机定理。这给一个比泛泛“无序导致局域化”更具体的挑战：**临界长程耦合是否在任意小的随机材料变化下仍有纯点谱，局域态究竟有何尾部、何种动力学局域化能成立？**

价值来自短程一维直觉是否在物理产生的临界长程核下失效；纯点/连续谱或代数/指数尾的不同都会改变关于真实局域化的认识。它不是本仓库材料模型的自然下一步，难度很高；没有随机算子专长或清晰的小目标，不宜因作者写“待证”就列近期第一推荐。完整局域化理论不能当90分钟调研后的保底承诺。

### 8.3 两条不能越过的推论边界

1. **预解式范数收敛不保留一般谱类型。** 它可控制孤立有限重特征值/谱投影及相应谱位置；不能仅据此把离散极限模型的纯点谱、Anderson局域化或动力学局域化直接搬到每个非零对比度的连续PDE。还需随机估计、相应加权控制或稳定性定理。
2. **有限矩阵全是本征值，不证明无限纯点谱。** 参与率、有限链尾形和随N变化的数据是数值证据。长程核的局域态尾还须单独分析；不能把有限区间半对数图近直线当指数局域化的结论。上述论文自身对“未有任意弱无序证明”的限定应保留，不能放大数值措辞。

本节只是最接近新文献带来的否证和高风险替代挑战，不把它加入主报告的三个推荐名额；最终排序仍须按主稿实际问题审查。

## 9. 尖角候选：值得问的是反射机制与坏频窗，而非再数传播模

02:07前读到主证据E1–E8；主报告仍未出现。本节针对已出现的弯角方向提出实质门槛，不预设它必须占一个推荐名额。

**近邻定理独核。** Habib Ammari, Jiayu Qiu (2026), *Robustness of Valley-Hall Interface Modes Against Sharp Bending*, [arXiv:2605.29485v2](https://arxiv.org/html/2605.29485v2)。已读Assumption2.7、Theorem2.8、式(2.16)、Remark2.10及§4。主证据关于“两个传播解不等于高透射”的判断正确：式(2.16)本身已经给散射矩阵，奇偶相位差决定反射。不能把重写相位差公式称为新定理。其全区间孤立带假设比单个频段无阈值强，去掉该假设是作者已指出的技术方向；只有表述“放宽它”仍不足说明价值。

**更接近的量化先例不能漏。** Gaëtan Lévêque, Yan Pennec, Pascal Szriftgiser, Alberto Amo, Alejandro Martínez (2023), *Scattering-matrix approach for a quantitative evaluation of the topological protection in valley photonic crystals*, Physical Review A **108**,043505, DOI [10.1103/PhysRevA.108.043505](https://doi.org/10.1103/PhysRevA.108.043505)，[作者全文v2](https://arxiv.org/html/2301.10565v2)。读§§1–3与摘要；二维TE光子晶体、FEM及角点/分束器的现象学散射参数。无几何缺陷的尖角也产生反射、透射谷和共振劈裂，均已量化；这些不是待首次揭示的现象。原刊正文需订阅，未登录或绕过，核读作者公开稿。

Tirth Shah, Florian Marquardt, Vittorio Peano (2021), *Tunneling in the Brillouin zone: Theory of backscattering in valley Hall edge channels*, Physical Review B **104**,235431, DOI [10.1103/PhysRevB.104.235431](https://doi.org/10.1103/PhysRevB.104.235431)。读出版商开放全文§§III、VI–VIII：平滑域壁、紧束缚/半经典WKB，给动量空间隧穿和随平滑度指数抑制的量化解释；不是尖锐连续介质的严格统一余项定理。故“定量分析反射”“平滑可降低背散射”也不能宽泛认领。

**可保留的精确问题。** 在小开隙参数 $\delta$ 的同一材料族内，固定两条渐近直臂及尖角拼接，取缩放后的体隙内部紧频窗，研究反射率 $R_\delta(\lambda)$ 是否在远离阈值及角点极点时一致趋零；若不能，一致强反射来自何种微观拼接或角点态？进一步可问给定 $0<\tau<1$，坏频集 $\{\lambda:R_\delta(\lambda)>\tau\}$ 占可用gap的相对测度是否趋零，以及它如何依赖拼接位置。**这仍是待筛假设问题，不是已确认开放问题。** 它把“通常看起来无反射”改成带宽尺度上的可否证判定；尖角器件使用者关心的是可用频窗，不是有限例外集的零测度描述。

**不能藏进假设的内容。** 只删去有限个异常频率并不给一致透射界：其邻域可能有窄但强的Fano反射；随 $\delta$ 变化，极点数与宽度也可能失控。“假定奇偶相位差接近 $\pi$”则已经假定想证明的高透射。若假定能量离角点谱有距离，须解释这个距离与gap宽度的比例，并核对是否排除了全部感兴趣频段。

**第一步及止损。** 明确固定的是原子尺度尖角、平滑半径还是随 $\delta^{-1}$ 放大的结构；推导含两个valley及微观顶点匹配的极限散射问题，检查单valley无反射是否只是把反射通道从模型中删掉。若完整PDE到双valley问题的误差只在有限传播时间上成立，它不够给定频散射或极点结论。若最终只剩一般Fredholm可解性、单位性或已有相位代数，退出主推荐；若出现真实的高反射反例或可用坏窗量级，则反结果同样有意义。

## 10. 阈值和计数方向的两项直接先例

### 10.1 “弱缺陷精确产生几个模”在多带、不光滑材料下已有

**B. M. Brown, V. Hoang, M. Plum, M. Radosz, I. Wood (2020).** *Gap localization of multiple TE-Modes by arbitrarily weak defects*. Journal of the London Mathematical Society **102**(2),773–795. DOI [10.1112/jlms.12337](https://doi.org/10.1112/jlms.12337)；2019作者稿题名 *Gap Localization of TE-Modes by arbitrarily weak defects - multiband case*, [arXiv:1901.05102v1](https://arxiv.org/html/1901.05102v1)。已核原文Assumptions1–3及Theorem3；原刊页码由作者机构Cardiff记录核。

模型是二维正有界 $\varepsilon$ 的散度型TE算子，沿轴周期、横向紧支撑的非负介电增加且在一球上严格增加；固定轴向准动量；参与上隙边的横向带均为非平、二次非退化极小。弱缺陷下，整个该纤维gap内的本征值数恰为触及边缘的 $(s,k)$ 对数。它允许多带和系数跳跃。因此一般“多带＋弱缺陷＋精确模数＋不光滑”不构成新题。本文不能直接覆盖当前质量型、符号变化、四次边或频率通道计数；但仅换算子/符号也不保证有值得研究的新机制。

容量方向还须区分这个“纤维gap本征值数”与§7固定频率的轴向传播通道数；不能在引用它时混换两个准动量。后者的资源界若能限制非单调带的多次穿越，才可能有独立内容；本轮尚未查全其现有覆盖，不能声称开放。

### 10.2 “阈值分叉成真态或共振”也不是尚无人处理的主题

**S. A. Nazarov (2020).** *Threshold resonances and virtual levels in the spectrum of cylindrical and periodic waveguides*. Izvestiya: Mathematics **84**(6),1105–1160. DOI [10.1070/IM8928](https://doi.org/10.1070/IM8928)，[Math-Net原刊记录](https://www.mathnet.ru/eng/im8928)。**目前仅原刊摘要/元数据**，不能据此评价具体定理覆盖。其范围已包括一般二阶自伴椭圆系统、周期端、退化阈值及多项式增长的几乎驻波；不能声称首次在周期端引入virtual level或退化阈值。

**D. I. Borisov, D. A. Zezyulin, M. Znojil (2021).** *Bifurcations of thresholds in essential spectra of elliptic operators under localized non-Hermitian perturbations*. Studies in Applied Mathematics **146**(4),834–880. DOI [10.1111/sapm.12367](https://doi.org/10.1111/sapm.12367)；[arXiv:2007.02258v2](https://arxiv.org/html/2007.02258v2)。**读§1及§2.1算子设定，尚未逐条核主定理证明**。模型为 $\mathcal H' -\partial_z^2$、有界或无界横域、Dirichlet/Robin，横算子有离散本征值；局部抽象扰动可非自伴，给阈值极点及真态/共振的区分和两项渐近。文中强调内部阈值两种延拓，忽略一张sheet会漏结果。它不是轴向周期开放二维bulk的直接应用，但“用加权空间/延拓把阈值态和共振分开”不是创新本身。

若推荐阈值方向，必须给出新现象而非方法名：例如原本横向导带吸入bulk时的**同一频窗散射可观测量、不同阈值通道相碰的非例行交叉、或可实现的材料选择规则改变分叉类型**。每项都要说清当前几何能否发生。一般分类、一阶系数或标准平方根/四次根律，未完成最近邻排查前应降级；当前数值难算并不增加其数学新意。

## 11. 主报告首稿审查：三个推荐均可条件保留，但第二、三项须收紧

02:10 UTC读到 `report.md` 首稿。它已明确三个目标：尖角反射、固定资源附加延迟、两横向极小合并的完整弱模截止；不再维护旧A的优先级。以下是可直接用于修订的意见，仍非完整新颖性审计。

### 11.1 推荐一：意义合格；“有余项的二维推广”仍须落在新的机制上

一句问法：**弱破缺尖角晶体的可用gap中，强反射窗口占多大、由哪些微观拼接和角点共振控制？** 可能新增的是对连续PDE可实现族的统一透射/坏窗定律，或同一假设下强反射反例，进而决定直带图是否能预测尖角器件。

最近邻必须至少包括Ammari–Qiu2026（题名链接见§9）、Dai等2025及Shah–Marquardt–Peano2021，而不只对照2026存在定理。Lévêque等2023已明确量化尖角反射造成的透射谷；建议主证据补入，避免“开始定量评价拓扑保护”的口吻。首稿没有这种明确首创误称，风险主要在后续立项时。

首稿“必须排除的共振窗口”是必要限定，但要补量：不能任意删掉坏区间后得到高透射。推荐以gap相对测度、极点数及宽度尺度，或事先规定的能量距离作可判定目标。若只能对固定 $\delta$ 删有限频率再证可解，价值退回原定理层级。

### 11.2 推荐二：价值最直接，创新门比首稿所列更高

一句问法：**在固定参考端口与材料/横向资源下，任意内部二维结构的高透射附加相位延迟能否超过与长度同阶的带宽乘积？** 可能新增的是对所有微观几何统一、可解释且有同阶构造的限制；数学物理和器件极限研究者都会关心它。风险是现有一般线性散射界或谱移理论已足以推出同阶结论。

**须新增的强先例。** David A. B. Miller (2007), *Fundamental limit for optical components*, Journal of the Optical Society of America B **24**(10),A1–A18, DOI [10.1364/JOSAB.24.0000A1](https://doi.org/10.1364/JOSAB.24.0000A1)，[作者机构记录](https://ee.stanford.edu/~dabm/331.html)。已读出版商开放正文§§2、3开头及§4。其中心结果已针对一般线性、多重散射、可含空间/时间/频率的Hilbert空间；一维只是具体例子。不能把2007先例概括为“仅有一维理论，所以二维限值尚无框架”。现有主稿说二维显式界仍须核新颖性是对的，但第一项文献门应包括这一一般定理；需指出**固定周期参考Green算子、无限横向内部自由度、以及线性L尺度**中究竟哪一步不已被覆盖。

**常数依赖须写清。** 主稿固定了 $I$，却称目标为延迟—带宽界。如果 $C_1,C_0$ 可任意依赖 $|I|^{-1}$，结论可能只表示每个预先固定窗口有界，不能支持缩窄带宽时的统一能力极限。可分“先固定窗口证明有限资源延迟界”与“对 $I\subset I_0$、远离固定端口阈值的统一乘积界”两个层级；后者常数不应暗含带宽倒数。

**一个具体检查。** 若只得到相位的 $L^1$ 谱移估计，不能直接声称乘积界：$\theta'=\tau\ge T$ 在宽度 $\Delta$ 的区间上给 $\inf_c\int|\theta-c|\ge T\Delta^2/4$，因此这类估计通常先给 $T\Delta^2$ 的控制；还差带宽一致性。此为单调函数的初等检查，不是本轮研究成果。

**连续边界截断确有非平凡陷阱。** Peter D. Hislop, Peter Müller (2010), *The spectral shift function for compactly supported perturbations of Schrödinger operators on large bounded domains*, Proceedings of the American Mathematical Society **138**,2141–2150，[arXiv:0907.3522v2](https://arxiv.org/html/0907.3522v2)。已读§1 Theorems1.1、1.3、1.4及Remarks1.5：正文重述Kirsch反例，固定紧扰动的有限盒SSF在 $d\ge2$ 仍可随外盒尺寸点态无界；其结果给平滑/子序列Cesàro控制。这不反驳固定周期单通道主问题，却足以禁止“加大外盒、两大计数相减必一致有界”的捷径。不是有限秩也不意味着本方向无价值；恰需查清这一步是否可由已有一般估计解决。

**延迟与DOS关系已有直接二维波动先例。** Romain Pierrat, Philipp Ambichl, Sylvain Gigan, Alexander Haber, Rémi Carminati, Stefan Rotter (2014), *Invariance property of wave scattering through disordered media*, PNAS **111**(50),17765–17770, DOI [10.1073/pnas.1417725111](https://doi.org/10.1073/pnas.1417725111)，[开放全文](https://pmc.ncbi.nlm.nih.gov/articles/PMC4273329/)。已读式(6)–(8)及图3后DOS/Weyl讨论：二维Helmholtz散射区接理想波导，TrWigner–Smith与DOS、面积/边界的平均延迟关系均已分析，Weyl使用为高频/频率平均近似。它不是当前固定低频窗的统一上界定理，但进一步压缩“首次把二维延迟和模数联系起来”的创新口径；仅重推标准Friedel/Smith关系不够。

### 11.3 推荐三：作为纤维模态分叉可留；“真实单模器件”目前超出目标

一句问法：**横向两极小合并时，弱线缺陷所生第二个纤维本征态的截止曲线怎样偏离未扰动合并点，能否在两个绑定尺度上完整计数？** 可能新增的是跨合并点的连续二维一致分叉定理；新意不在四次边或两个幂指数本身。

**必须修正/限定的措辞。** 这里固定轴向 $\beta$ 数横向束缚本征态；它并未计数同一频率下所有轴向 $\beta'$ 的通道，故首稿“真正的单模/双模工作区”不能直接理解成器件单通道频带。请明确称“固定准动量的单/双纤维模区域”，若要推实际单模频窗，另需轴向带的全根计数。第§7给出这一逻辑区别。

此外，极弱第二模可能因对称选择规则而不能被指定入射激发，且其材料区域能量重叠可趋零；“存在第二本征态”本身不等于已证明有显著串扰或坏传输。纯数学完整分叉仍有价值，但应以它自身解释价值，不把计算域漏模自动转成器件劣化结论。

最近邻是Sahand Mahmoodian、Christopher G. Poulton、Kokou B. Dossou、Ross C. McPhedran、Lindsay C. Botten、C. Martijn de Sterke (2009), *Modes of shallow photonic crystal waveguides: semi-analytic treatment*, Optics Express **17**(22),19629–19643，DOI [10.1364/OE.17.019629](https://doi.org/10.1364/OE.17.019629)。**本复核者目前仅核原刊目录和原作者摘要；原刊HTML只返回等待页，未读主研究者所核正文**。不据二手全文判定其是否已有联合截止公式。Brown等2020 Theorem3（§10.1）和Jonathan Arazy、Leonid Zelenko (2006), *Virtual Eigenvalues of the High Order Schrödinger Operator I/II*, IEOT **55**,189–231/305–345，DOI [I](https://doi.org/10.1007/s00020-005-1389-x)、[II](https://doi.org/10.1007/s00020-005-1390-4) 是强数学基线；后者本轮只核出版商摘要，完整正文阅读深度不能借用上轮审查冒充本轮已核。

首稿正确保留了真实材料实现、实际边缘移动及第二尺度余项门槛。建议首个止损输出是**截止曲线是否在已知有效模型中已有**及**材料耦合是否使第二模机制消失**，而非先投入高精度PDE计算。若仅剩换模型后的两项更准误差，按用户要求应退出。

**另一个不能误算为全新概念的近邻。** Sahand Mahmoodian, Andrey A. Sukhorukov, Sangwoo Ha, Andrei V. Lavrinenko, Christopher G. Poulton, Kokou B. Dossou, Lindsay C. Botten, Ross C. McPhedran, C. Martijn de Sterke (2010), *Paired modes of heterostructure cavities in photonic crystal waveguides with split band edges*, Optics Express **18**(25),25693–25701, DOI [10.1364/OE.18.025693](https://doi.org/10.1364/OE.18.025693)，[作者机构ANU记录](https://digitalcollections.anu.edu.au/items/3c52b421-dd49-4e17-a830-cae611250276)。目前仅作者机构摘要/元数据：有两轴向带边的双异质腔、两模耦合与调谐已有研究；它的轴向腔问题和本候选横向合并不同，不据摘要声称覆盖联合截止。UTS机构PDF读取返回429，已停止该操作，不重试或绕过。

## 12. 02:16 UTC主稿修订与最新近邻核验

主稿已把截止计数移到推荐二，把资源界移到推荐三；已明确固定 $\beta$ 的计数与频率通道不同，补入Miller一般定理及直接套用止损门，且尖角家族固定微观拼接、增加坏窗测度目标。§11的编号按所读首稿保留，不能拿其“第二、三项”误指新排序。

新近强来源独立核验：**Alexis Drouot (2026), *Reflectionless edge states in Dirac models of topological insulators*.** [arXiv:2609.16949v1](https://arxiv.org/html/2609.16949v1)，2026-09-15。已读§§1.1–1.4及Theorem1.1，不是全篇证明审计。原算子为 $D_1\sigma_1+D_2\sigma_2+\kappa(x)\sigma_3$，定义域 $H^1(\mathbb R^2,\mathbb C^2)$；实有界质量墙在紧区外为两条任意角度（非折回 $\pm\pi$）渐近直臂，其横向轮廓在两端分别恰为 $+1,-1$。完全透射在 $(-E,E)$ 的局部有限异常集外成立，$E$ 是两臂横向Dirac算子最小正谱点的较小者，**不应无条件改写为整个bulk gap的每个频率**。该窗口只留下一个单向edge通道；当前互易双谷晶体另有反向通道，不能直接继承反射率零。

§1.4确实明确提出其结论能否在Ammari–Qiu模型中成立，主稿引用属实。这是值得审查的明确前沿问题来源，强于“我们未搜到”；仍不证明更窄弱破缺版本没有其它先例。建议主稿简补上述窗口/异常集限定，避免量化定理范围扩大。作者也明确区别有限长时间波包逼近与定频全局散射，这支持主稿把联合吸收极限列为真正障碍。

延迟候选现已改为 $I\subset J$ 和近恒定延迟容差，但尚建议明说 $C_1,C_0$ 不依赖所选 $I$ 及其宽度；否则仍可把 $1/|I|$ 藏进常数。该处只需一句，不应另增推荐。

## 13. 02:21 UTC尖角方向深核：双谷并非尚无理论，真实缺口更窄

**推荐一可保留为高风险机制问题；不能以“首次双谷有效模型/首次拓扑散射理论”定位。** Drouot2026已经明确提出从其Dirac定理向连续晶体推广，这个研究来源须归于作者。我们的差异化目标只能是原文未给出的可用坏频窗、反向谷耦合或微观顶点分类，不能把作者的延拓建议作为本项目原创选题发现。

**Alexis Drouot, Michael I. Weinstein (2020).** *Edge states and the valley Hall effect*. Advances in Mathematics **368**,107142, DOI [10.1016/j.aim.2020.107142](https://doi.org/10.1016/j.aim.2020.107142)，[作者稿](https://arxiv.org/html/1910.03509v1)。本轮已读§3.4、Theorem5.1、armchair讨论及§6.3关键估计。它已经有包括两谷的 $4\times4$ 分块Dirac约化；armchair情形两谷投到同一纤维也已处理。模型域壁为 $\delta\kappa(\delta K_2\cdot x)W(x)$，过渡宽度为 $\delta^{-1}$，$\kappa$ 光滑且导数有界。Theorem5.1要求缩放谱参量与有效谱保持固定距离，是直臂纤维的预解式展开，不是尖角实轴散射的统一极限吸收结论。因而已有双谷谱约化不能直接闭合主目标；也不能只把它重推一次称创新。

**与Ammari–Qiu几何的距离。** 其Assumption2.4把周期破缺项 $b$ 在固定宽度走廊内置零，以保证全局系数光滑；不能误称其材料界面有跳跃。它仍是固定微观过渡宽度，区别于上文随 $\delta^{-1}$ 展宽的缓域壁。其Assumption2.3及Proposition2.5确给完整bulk gap所需的全布里渊区隔离条件，并非只在单纤维验证。因此主稿“完整bulk gap”是明确假设下的合法目标，不能说原单点证书已提供它。这里的难点是尺度及实轴控制，不宜泛称系数不光滑。

**Binglu Chen, Guillaume Bal (2025).** *Scattering theory of topologically protected edge transport*. Pure and Applied Analysis **7**,701–731, DOI [10.2140/paa.2025.7.701](https://doi.org/10.2140/paa.2025.7.701)，[作者稿v2](https://arxiv.org/html/2307.13540v2)。已读Hypotheses2.2、2.5、2.6及Theorems2.3、2.7、2.10。已有LAP、广义本征函数和散射矩阵；净透射差等于左右通道数差。互易双谷总指标为零时，这个恒等式不给单向透射的正下界。其已核Dirac应用是渐近线性无界质量、横向紧预解式；不能未经验证套到有bulk连续谱的有界质量晶体或尖角。这里不是缺一般散射语言，而是缺当前具体几何的可控匹配。

**Guillaume Bal, Jeremy Hoskins, Solomon Quinn, Manas Rachh (2026；预印本2023).** *Integral formulation of Dirac singular waveguides*. Pure and Applied Analysis **8**,331–365, DOI [10.2140/paa.2026.8.331](https://doi.org/10.2140/paa.2026.8.331)，[作者稿](https://arxiv.org/html/2312.16701v1)。作者名单据原文；期刊卷页由出版商作者索引核。已读§§1–2及§3.1主结果。两分量Dirac的分片常质量、光滑渐直曲线已有边界积分和一般参数下唯一可解性；并非字面尖角、双谷耦合或周期连续介质定理。不要把建立一个Dirac边界积分方程本身当本题新意。

**最有价值的首期交付应是可失败的机制判定。** 固定一族真实晶体和微观拼接，先判断折角后入/出射谷的对应关系，以及首个允许的反向耦合阶数；该阶数是否因对称或微观平移而消失？若只在单谷模型中删掉了反向通道，无反射当然不能解释互易晶体。若发现同一固定族的反射不趋零，这也可能是比勉强推广更有意义的否证。完整连续PDE统一余项非常难，距当前固定准动量质量型认证很远；不得把它写成现有框架的顺手延伸。

## 14. 02:21 UTC截止方向深核：已知失效的定量解释，而非新发现两尺度

**阅读深度更新。** §11.3保留的是02:10时的证据状态；此后已独立读Mahmoodian等2009原论文的公开出版商全文预览§§4–5（[全文入口](https://www.researchgate.net/publication/40483998_Modes_of_Shallow_Photonic_Crystal_Waveguides_Semi-Analytic_Treatment)），并读Arazy–Zelenko II的机构原稿Theorem3.4及条件(3.6)–(3.8)、式(3.50)–(3.53)（[ESI1706原稿](https://www.esi.ac.at/preprints/esi1706.pdf)）。未下载或绕过出版商限制。以下判断建立在这些正文，不再仅据摘要。

**物理先例比“有效质量失效”还具体。** Mahmoodian等§4已有两个横向Bloch谷的耦合包络；§5指出合并附近须考虑四阶色散，而且现有近似把截止钉在合并点，实际数值截止却随缺陷强度移动。这是作者已明确指出的建模缺陷，不能认领为本项目首先发现。候选真正可能新增的是对这个已知失效的连续PDE统一解释、真实边缘下的完整模数及截止主项。原图支持具体TE族的机制，不等于已严格验证 $b>0$、曲率横截或所有其它带隔离。物理场的奇偶性还含Bloch因子，不能直接把标量包络的奇偶标签照搬到原场。

**数学先例直接包含第二尺度和系数结构。** Arazy–Zelenko II Theorem3.4对一维 $D^{2l}+\gamma V$、连续非零 $V\ge0$、衰减且适当矩有限，给恰 $l$ 个阈值分支及高阶分支系数。$l=2$、$\gamma=-\varepsilon$ 时两个绑定尺度 $\varepsilon^{4/3}$、$\varepsilon^4$ 是旧结果；弱分支系数包含 $x\sqrt V$ 对 $\sqrt V$ 的正交距离，也就是加权方差结构。该定理本身没有曲率参数 $aD^2$ 的联合极限；因此尚不能据它认定主稿的联合截止已经覆盖，也不能只重证这两个指数。

**一个不宜包装成创新的便宜检查。** 为说明第二尺度的精度门，考虑独立玩具族

$$H_{a,\varepsilon}=bD^4+aD^2-\varepsilon V,\qquad b>0,\ a>0,$$

其中 $V\ge0$ 偶、连续、紧支撑且非零。零能自由核除一个无关常数为

$$G_a(r)=-\frac{|r|}{2a}-\frac{\sqrt b}{2a^{3/2}}e^{-\sqrt{a/b}|r|}.$$

在奇子空间，常数消失；固定支撑上展开给Birman–Schwinger算子

$$\sqrt V G_a\sqrt V\big|_{\rm odd}
=\frac{|x\sqrt V\rangle\langle x\sqrt V|}{2\sqrt{ab}}+O(1),\qquad a\downarrow0.$$

余项在算子范数中有界。因此令 $a=\varepsilon^2 A$，其第一阈值条件的形式主项为

$$A_c=\frac{\big(\int x^2V(x)\,dx\big)^2}{4b},\qquad a_c\sim\varepsilon^2 A_c.$$

这是核展开的独立一致性检查和低成本候选验证式，**不是完整PDE截止定理，也不是声称新的玩具定理**；严格全区域计数、$a\le0$ 时真实边缘平移和非偶/矩阵情形另需处理。它表明强模的曲率竞争尺度 $a\sim\varepsilon^{2/3}$ 与弱模的 $a\sim\varepsilon^2$ 不同。若PDE约化只给通常的粗范数误差，第二阈值信息很可能被埋掉；必须说明误差如何在相关低秩子空间或加权尺度上受控。

**本候选的止损应前移。** 第一轮先比较上述联合低能核与已有高阶弱耦合文献，核对从具体Bloch模得到的矩阵耦合和对称是否真的产生该弱分支，再谈二维定理。若只得到这个标量核的截止系数，是已知机制的小延伸，不能独占用户要求的主线。若真实二维约化改变其系数、消灭分支或产生不同截止类型，而且能给完整性与稳定余项，才有独立定理空间。当前主稿把两尺度、材料可实现性和全模计数写成门槛，方向准确；尚未证明这些门能通过。

## 15. 02:24 UTC硬域壁最近邻补核：微观位置依赖也已被研究

Tirth Shah, Florian Marquardt, Vittorio Peano (2023), *Tunneling-induced fractal transmission in valley Hall waveguides*, Physical Review B **107**,054304, DOI [10.1103/PhysRevB.107.054304](https://doi.org/10.1103/PhysRevB.107.054304)，[原作者稿v2](https://arxiv.org/html/2209.06188v2)。本轮独立读§II模型、§V、§VI及Appendix C；主证据E4已列此文，非漏引。

该文不只说平滑墙：最近邻蜂巢紧束缚、硬质量墙，数值取 $|m|/J=0.3$，直接保留两谷耦合；Appendix C已展示角点相对晶格位置改变反射、微观尖锐度改变谷隙宽度。因此“首次揭示角点平移影响反射”也应排除。本文没有给当前连续介质弱破缺联合极限的统一余项；不能因为它处理了微观位置就宣布覆盖主候选。原稿HTML自动生成日期不是投稿/发表年份，书目年份以2023原刊及2022版本记录核。

**应排除一个容易做出的伪反例。** §V主要反射尖峰与出射臂自身的edge minigap相连；若没有出射传播通道，反射并不是尖角在双方均可传播时破坏传输的新机制。主候选的缩放频窗须明确在**两臂均有规定入/出通道且远离各自阈值**的范围，再研究角点反射或角点极点。主稿已要求明确通道，但建议把这一排除写成一句，防止后来拿直臂禁带当角点反例。有限吸收drain紧束缚计算仍是证据，不能替代连续实轴散射的定理。

## 16. 02:25 UTC实质新颖性挑战：双极小合并后的移动截止已有精确相邻模型

**需主研究者吸收；不因模型不是光子晶体而略去。** Rytis Juršėnas, Julius Ruseckas (2013), *Bound states of the spin-orbit coupled ultracold atom in a one-dimensional short-range potential*, Journal of Mathematical Physics **54**(5), DOI [10.1063/1.4807419](https://doi.org/10.1063/1.4807419)，[原作者稿](https://arxiv.org/html/1305.2316v1)。已读§I模型、式(IV.4)、TheoremV.1、Figure4及RemarkV.3；未审全篇关于其它点相互作用实现的额外态。出版商DOI页面工具不可达，原稿公开可读，未尝试绕过。

模型为 $H_0=p^2I+\eta p\sigma_2+(\Omega/2)\sigma_3$ 加吸引点缺陷 $\gamma\delta(x)I$。下带两极小在 $\Omega=\eta^2$ 合并；连续本征函数分支的第二态在 $\Omega=\eta^2+\gamma^2/4$ 截止（RemarkV.3），已经是**超过未扰动合并点、按缺陷强度平方移动的截止**。该文不同实现还讨论不连续态；这里不据那些额外态作光子晶体类比，也不把点缺陷结果直接称一般有限宽缺陷定理。

一个独立标量积分可核其截止，不依赖复杂图示：当 $d=\Omega-\eta^2>0$，在真实边缘 $E=-\Omega/2$，自由预解式原点的有限对角元为

$$\int_{\mathbb R}\frac{dp}{2\pi}\frac{p^2}{p^2(p^2+d)}=\frac1{2\sqrt d}.$$

与吸引强度 $|\gamma|$ 的Birman–Schwinger阈值条件正好给 $d=\gamma^2/4$。下带的独立Taylor展开为

$$\lambda_-(p)=-\Omega/2+(1-\eta^2/\Omega)p^2+(\eta^4/\Omega^3)p^4+O(p^6).$$

故它确有当前讨论的四次合并正规形，绝非只有相似题名。原子自旋耦合的矢量Bloch结构也说明弱分支系数可来自内部态变化，而非仅标量势的空间二阶矩。

**对排序的影响。** 这没有覆盖二维TE晶体中有材料来源和统一余项的完整计数，但已排除“首次提出/解释双谷合并时缺陷使截止移动”或“发现平方移动律”作为广义创新。主推荐二只有在明确指出周期PDE的耦合/完整性带来什么超出该精确模型的认识时才值得继续；若目标只是把2013精确截止换成光子晶体上的一个系数，价值应进一步降级。应把这篇加到最近邻，而不能只对照纯 $D^4$ 的2006理论。

## 17. 02:29 UTC延迟候选的最小否证门：先试是否只是通道投影后的已有界

已进一步核Miller2007 JOSA B §2定理的具体条件：材料响应有界、内部Green算子在相关空间平方可积、源到接收算子紧，且迹取在**对接收空间可见的源子空间**上；不能拿整个 $L^2(D_L)$ 上乘法算子不可迹就宣告其失效。对二维质量型，局部Green对数奇性本身平方可积，因此“二维奇性”也不是自动的新障碍。主稿已把直接应用门列到首周，做法正确。

**以下是本复核者的可行性推断，不是已证明的周期端定理。** 在固定无阈值单通道背景，固定频率的远场接收投影只看见有限个传播Bloch剖面；内部Green的传播部分通常给长度为 $L$ 的积分算子范数 $O(L)$，非传播部分在固定gap距离下有望统一有界。若这两步在参考lead已经成立，代入Miller的可见子空间迹界就可能直接给线性长度尺度。真正还需查的是**所定义的近恒定相位延迟、高透射条件如何严格转成其可控制的正交输出数**及带宽一致性。不能因内部PDE是二维就预先认定这里有新能力界。

因此建议只给推荐三短预研，不当作三个方向中最确定可开工的一项。若上述投影/Schur估计与标准时域论证已经闭合，则写成旧定理在当前背景的应用并退出新选题；若不能，须留下明确不能闭合的数学步骤，不能泛称无限维或非有限秩。目标常数还应独立于 $L,T,I$ 及 $|I|$，只允许依赖固定背景、$J,W,m,M,\eta,\chi$。高Q的单个窄峰并不反驳乘积界；任意微观结构下线性量级是否只是已有框架推论，才是当前最大价值风险。

## 18. 02:29 UTC推荐等级与替代项的独立判断

**第三项目前不够资格与前两项同等推荐为主研究。** 相位斜率指标虽可形成数学问题，尚未证明它超出标准单通道可见源投影后的Miller界；改成低失真传输又更接近该作者的原指标。其“推荐”最多是**两天至一周的淘汰性预研**，成功通过以下两门才升级：明确证明旧定理不能直接给所求资源尺度；给出物理可解释、对微观几何统一的相位预算目标和同阶可达族。不能因为用户要求三个名额，就把方法尚未查清误称为三个同等成熟课题。

**相比之下，§8.2的临界长程随机链，独立科学价值比现版第三项更清楚，可行性却更差。** 它问一维的任意弱无序局域化直觉，在真实波动产生的 $1/(r\log^2r)$ 耦合下是否仍成立、以及局域化应以何种尾和动力学定义。若答案否定，将改变对长程共振器传输的预期；若肯定但只有代数尾，也推翻简单的指数局域图像。最接近来源是Ammari–Barandun–Qiu–Uhlmann2026，完整书目见§8.2；这是作者明确提出的未解决证明任务，不能认作我们首先发现的开放问题。

这也不是把经典Anderson定理搬过来：$t_r\asymp1/(r\log^2r)$ 虽在 $\ell^1$，却对每个 $0<s<1$ 都不在 $\ell^s$，故不能只用最简单的分数矩求和条件；还须保留原文乘性材料随机，而非擅自换成加性随机势。范数预解式收敛不能把离散谱类型自动转到连续模型。第一周只应核实际核的非零首项、原随机实现的自伴等价形式及最接近的长程随机算子定理，选择一个谱区或尾问题；不承诺一周证明任意弱无序全谱局域化。

**不建议现在为凑数立刻替换。** 该替代要跨到随机算子及高对比模型，当前只有具体价值与障碍核查，没有足够精细的最近邻排除或可证明第一引理。若主稿选择保留相位项，应把等级写成“第三个短预研推荐”；若要求三个都能立为长期主线，本轮证据只支持两个条件候选，加一个待成熟名额。这种不齐整比强行把未过门的课题说成熟更诚实。尖角项也应承认与当前程序距离远；截止项因§16的新近邻，创新风险已上升，不能通过把“连续PDE”加在题名前就免审。

## 19. 02:30 UTC新增相位文献与指标检查

**Ning Han, Rui Zhao, Shuxing Yang, Mingzhu Li, Hongsheng Chen, Yihao Yang (2026).** *Causality Sum Rules in Conventional Scattering Matrices*, [arXiv:2608.10427](https://arxiv.org/abs/2608.10427)，2026-08-11；[原稿PDF](https://arxiv.org/pdf/2608.10427)。本轮独立读原稿pp.13–14的lossless phase-delay部分及式(6)，未审Supplementary Note8的证明。它明确加无singular-inner因子和Blaschke相位的modal-count预算，且指出额外高Q相位会增加整数周转。这不能证明当前材料类已有统一上界；主稿最新表述为条件性近邻是准确的。第三方自动评论不能替代正文，此处未采用其真伪或常数评价。

**一个独立的指标一致性反检验。** 取抽象因果全通函数

$$t_N(\omega)=\left(\frac{\omega-i\gamma}{\omega+i\gamma}\right)^N,\quad \gamma>0,\qquad T_N=2N/\gamma.$$

它在上半平面解析且收缩，实轴模恒1；$S_N=\left(\begin{smallmatrix}0&t_N\\t_N&0\end{smallmatrix}\right)$ 是互易无损两端口。对固定 $q>0$、$|\omega|\le q\gamma$，群延迟为

$$\tau_N(\omega)=\frac{T_N}{1+(\omega/\gamma)^2}.$$

选 $q^2\le\chi/(1-\chi)$ 即满足主稿的相对延迟容差，而端点相对理想延迟的未取模相位误差为 $2N(\arctan q-q)$，随N无界。因此该条件不能保证传输乘子统一接近理想延迟；固定端口数、无损、互易、因果本身也不能给所需相位预算。**这是抽象传输函数检查，不是固定材料/体积PDE反例**，因而不能据此宣告主目标为假。它恰好指出资源到共振/相位预算的步骤不可省。

主稿现已改名为“透射相位”并明确优先级低、只做一周淘汰性预研，避免把弱指标误称低失真缓冲；这项修订应保留。待核的是它为何值得超越旧界应用，不是再改一个物理名词。主稿引用的 `first-gates.md` 在02:28读取时尚未存在，属写作中状态，本复核暂未验收该文件。

## 20. 02:33 UTC首步草稿数学复核

`first-gates.md` 已出现并于02:32后读取；§19的缺文件状态已解除。主稿仍是送审草案，以下不是最终提交验收。

**G2的jet独立性草图：条件下逻辑可成立，未发现反例。** 这里必须是固定材料的简单解析Bloch分支、完整场的 $H^1_{loc}$ 参数导数、正频率、$E'=0$ 和缺陷在开球内正。若 $\sqrt v\nabla(\partial_q\psi-c\psi)=0$，先在球上为常数，再用方程及正频率令该常数为零；局部UCP沿连通域传播，最后由含 $i\ell\psi$ 的微分平移律矛盾。实系数下可分实虚部应用UCP。已独立读 **Giovanni Alessandrini (2012), *Strong unique continuation for general elliptic equations in 2D***，JMAA386,669–676，DOI [10.1016/j.jmaa.2011.08.029](https://doi.org/10.1016/j.jmaa.2011.08.029)，[作者原文Theorem1.1及条件(1.3)–(1.4)](https://arxiv.org/html/1004.4527v1)。适用为局部有界域上的实有界一致椭圆系数及可积低阶项；常数 $-E_*$ 可局部延拓后应用，不要求其在全平面全局可积。该草图不应升级成已完成的二维截止定理。

**G2有一个后续必须固定的定义细节。** 曲率参数 $a$ 改变时，零能压缩投影应是去掉**当前**阈值向量的 $Q(a)$，而非固定临界值 $Q(0)$。否则 $Q(0)h_0(a)$ 即使很小，固定 $a>0$ 取能量趋阈值时仍可能乘上发散的主通道，所谓 $K_{\rm edge}(a)$ 压缩就未必存在。当前写法“令Q去掉h0”尚可按参数依赖理解，建议显式注明。

此外，由压缩核的一个大特征值推出第二态的阈值，需要对完整 $1-\varepsilon K$ 消去主通道并控制Schur项，不能只数 $QKQ$。草稿已经将完整计数、其它带及gap内非正部分列为未闭合，因而没有错误宣告完成。散度型 $B=\sqrt v\nabla$ 的高能部分一般是零阶有界项，不自动紧；不应在后续证明中默换成紧积分算子。用有限秩奇性加统一有界余项可能足够，仍须写出相应计数框架。

**G1/G3的价值止损写法准确。** G1不把固定参数Green存在当新结果，G3明确二次相位反例仅为指标检查；§19的因果全通族进一步说明即使加因果无损也不恢复脉冲保证。主稿已加入两臂传播条件、Drouot窗口限定、2009已知截止偏移、2013精确模型及Miller应用风险，实质吸收了本复核的主要批评。第二项能否升级为独立主线、第三项能否超越旧界，仍是未通过的价值门。

## 21. 02:34 UTC主要审查交付状态

主要独立价值审查已完成；供主研究者吸收后再做最终版本只读验收。当前主稿仍标送审，不对未提交版本作最终接受结论。最重要的新增证据为§16的2013精确移动截止先例；最重要的评级意见为§18的第三项仅属淘汰性预研。

本复核者只写本文件，约66KB；未修改主报告、代码、规则或旧用户文件，无MATLAB/数值实验，无提交/push/分支切换/私有远端访问。目录仍为规定worktree，分支 `codex/dot`，HEAD仍 `5c93665`；02:34 Git检查只见本轮新目录未跟踪，暂存区及既有跟踪文件diff均空。最新worktree约93MB，低于1GB上限。上述是当前本地状态，不是对后续lead提交的预先保证。公开来源读取的429/403、不可达及仅摘要证据已在相应段标明，均未绕过；最近邻覆盖仍不是穷尽检索。

## 22. 02:36 UTC临界随机链的10月后续：无AC已做，不能再当待证

收到父线程新来源后继续针对性核查。**Habib Ammari, Jiayu Qiu (2026), *Absence of Absolutely Continuous Spectrum for One-Dimensional Capacitance Operators with Critical Long-Range Interactions*.** SAM Research Report **2026-35**，2026-10；[机构条目](https://math.ethz.ch/sam/research/reports.leftnav.html?id=1190)，[arXiv:2610.09582v1，2026-10-07](https://arxiv.org/html/2610.09582v1)，DOI [10.48550/arXiv.2610.09582](https://doi.org/10.48550/arXiv.2610.09582)。已独立读§§1–2、Theorem2.4、Lemma3.3、§4.3及§5；不是全篇证明审计。

**精确范围。** 标量Laurent算子 $C$，核及前两阶有限差分分别受 $|n|^{-1-j}\log^{-\beta}|n|$ 控制、$\beta>1$；实偶符号在 $(0,\pi)$ 光滑且严格单调。随机模型是 $V_{\omega,\epsilon}CV_{\omega,\epsilon}$，$V_{nn}=1+\epsilon\omega_n$，i.i.d.有界密度、紧支撑且0在支撑内部。Theorem2.4给所有充分小非零 $\epsilon$ 下几乎处处无AC。实际1D-in-3D单胞单共振器：Corollary4.7仅给声学窗内部紧区间；额外轴向反射对称才由Corollary4.9得到全谱无AC。作者§5明确尚未区分纯点与奇异连续谱。

这**实质更新§8.2及§18的7月证据**：不能再以“临界尾下尚不能证明任何弱无序谱破坏”“先证明无AC”推荐新题；有限差分＋迹类切割这一步已有。尚可能值得的是排除奇异连续部分、证明几乎处处纯点，并研究允许的代数尾和相应动力学/传输尺度。它们不是无AC的自动推论，也不是把该文最后一段改写就产生本项目原创问题。

**独立价值判断。** 完整谱型问题仍比现版相位应用的科学分叉更鲜明：无AC还允许能量以奇异连续谱缓慢扩散；纯点则意味着每个态的时间演化轨道在Hilbert空间预紧，但这仍不等于所有空间矩一致有界或指数局域。若能区分这两种行为，会让长程共振器输运研究者知道有限链参与率看到的究竟是不是无限系统局域化，而不只是把已知“无正常传播”换一个名词。反过来，不能声称该文无AC已给指数长度、零透射或完整Anderson局域化。

**学习与模型成本很高，不能因2026新鲜而直接替换。** 几何从二维周期介质中的线缺陷变为三维自由外部中的一维高对比共振器链；目标先是静电电容极限算子。需要学习三维层势/容量、乘性随机算子的谱平均与局域化判据、长程核切割及概率多尺度方法。现有Floquet、Schur及加权自伴经验可复用；原二维固定纤维计数证书几乎不提供随机纯点控制。更不能把极限算子的谱型用预解式收敛直接搬给非零对比度、带自由空间辐射的原PDE。

建议若替换，明确标作**高价值、极高难度的长期挑战，先做两周方法可行性门**；第一步是给定一个反射对称单共振器族、固定非零内部谱窗，查现有Simon–Wolff/谱平均或多尺度路径在该乘性模型上缺的准确估计，或先选择可证的弱尾结论。单纯去掉反射对称而重做全谱无AC是作者已提出的延拓，且未必有足够独立价值；增加每胞共振器数也先不能把矩阵维数变化当创新。若两周只能复述“无AC不等于纯点”而无第一个可检验估计，不宜列长期主线。这里推荐等级不能高于已明确机制和第一门的尖角方向。

**访问状态。** 父线程给的Research Collection条目直接读取403、`reports.html?id=1190`及机构PDF工具不可达，均未重试绕过。检索取得公开机构索引及作者arXiv原稿，关键正文已读，故这些访问失败没有阻止本段结论；未下载本地文献。

## 23. 02:38 UTC随机候选的两项先例与动力学措辞门

**标题写Anderson localization不等于已证无限纯点谱。** Habib Ammari, Bryn Davies, Erik Orvehed Hiltunen (2024), *Anderson Localization in the Subwavelength Regime*, Communications in Mathematical Physics **405**,1，DOI [10.1007/s00220-023-04880-w](https://doi.org/10.1007/s00220-023-04880-w)。已读出版商开放正文引言、§§4–5及结论的相关段：有从PDE导出的电容近似、有限缺陷局域模与全随机有限阵列证据，正文明确完整随机离散谱论难以得到。故它压缩“首次高对比随机共振器局域化机制”的口径，但不能据题名说2026剩余纯点问题已解决。

**最新长程transfer框架也有实质不同假设。** Xianzhe Li, Zhenfu Wang, Jiangong You, Qi Zhou (2026), *Transfer Operators, Canonical Center Dynamics, and Spectral Applications for Long-Range Operators*, [arXiv:2606.29154](https://arxiv.org/abs/2606.29154)。本轮仅核作者原摘要与版本记录，未读主定理证明：其框架要求analytic hopping及小势，谱应用是解析准周期及Diophantine频率。不能把“long-range”标题当作已覆盖临界对数尾/i.i.d.乘性模型，也不能据摘要反向断言没有任何可复用引理。它已被10月论文引用，后续方法调研应逐条核真实假设。

**必须把动力学目标单独定义。** R. del Rio, S. Jitomirskaya, Y. Last, B. Simon (1995), *What is Localization?*, Physical Review Letters **75**,117–119，DOI [10.1103/PhysRevLett.75.117](https://doi.org/10.1103/PhysRevLett.75.117)，[作者机构摘要](https://authors.library.caltech.edu/records/ym90e-a4824)。目前只核原刊及机构摘要；它已有指数局域本征态但空间矩仍显著增长的反例。机构PDF重定向失败且不可重试，未绕过。故即便证明纯点，也不能直接称已得到实验传输长度或强动力学局域化；更不能从无AC推出零透射、零扩散或任意指定的输运速率。§22中奇异连续谱“缓慢扩散”只是可能行为的例子，并非一般速率结论。

可执行的首期门应先固定 $I\Subset(0,E_{\rm reg})$ 和一个反射对称单共振器模型，明确要证的是纯点、某个加权Green判据，还是指定的小阶空间矩/本征函数尾。针对 $t_n\asymp1/(n\log^2n)$，标准 $\ell^s$ 分数矩求和对任何 $s<1$ 失效，传统“指数长度”也不应预设；需核更适合该核的指标和概率估计。若只能证明非实谱参量下的代数预解式上界，不能将其误当实轴随机谱型结论；如果只重做10月的迹类切割，也不足以支持替换推荐。

## 24. 02:43 UTC新第二推荐的实际首步与价值再审

已读此时主稿新排序及 `first-gates.md` 的G4。替换理由成立：原双谷截止的核心认识已有强覆盖，而临界链尚有明确的谱型分叉；不过第二项是**高价值、极高难度的条件推荐**，并不是现有技术已有可行性保证。推荐三仍只够淘汰性预研，不应在最终简报中抹平等级。没有三个同等成熟方向这一事实，应保留。

**G4的无双侧指数尾推导，按当前明确条件可成立。** 核对7月Theorem3.2，符号确有非零逆对数主项，误差为逆对数平方。若 $D,D^{-1}$ 一致有界，指数衰减的 $u$ 使 $w=Du$ 及 $ED^{-2}w$ 都指数衰减；加权 $\ell^2$ 定义也可缩窄条带后用Cauchy–Schwarz转成解析Fourier级数。非零解析 $W$ 在0的有限阶零不能消除逆对数分支：$R/W$ 亚纯，沿实轴有界且趋零将使极点可去，故应至多为有限阶解析零，与 $c(\theta)\sim A/\log(1/|\theta|)$ 矛盾。只需符号在实轴的已知渐近，无需把其本身预先解析延拓。零能量用 $cW=0$ 和零点邻域中 $c\ne0$ 也排除。未发现边界/定义域反例。

这是一项有用的**目标校正**：若存在随机本征态，其尾不能按经典最近邻模型假定为双侧指数。它没有证明本征态存在，更没有给“必为某个精确幂次”或弱无序纯点谱。其逻辑只用了非解析周期符号，未用随机性；不宜让一个几行确定性推论承担整个第二推荐的新颖性。当前主稿已明说不足独占论文，是准确的。

**乘性随机是需保留的模型条件，但单独不是充分创新。** 对固定非零实能量，精确恒等式为

$$H-E=D\big(C-ED^{-2}\big)D.$$

若 $D_n=1+\varepsilon\omega_n\in[d_-,d_+]$，且原密度不超过 $B$，则对 $E\in J\Subset(0,\infty)$，对角量 $a_E(\omega_n)=-E(1+\varepsilon\omega_n)^{-2}$ 仍i.i.d.，密度有上界 $B d_+^3/(2\varepsilon\inf J)$。所以不能把“能量相关”描述成完全不能做谱平均的神秘障碍；固定内部窗的单变量变量替换本身很便宜。它也不是把整个自伴算子酉变成一个固定加性Anderson族：对复 $z$，精确预解式是 $D^{-1}(C-zD^{-2})^{-1}D^{-1}$，随机虚部及对能量的一致性仍需核；从逐能量概率1结论到谱测度结论也不能只对可数网格论证。真正主要的困难依然是**临界尾不满足常用分数矩可和条件，加上任意弱无序**。若最后贡献只有上述变量替换，而核估计已被旧理论覆盖，不足支撑主线。

**需要下一个可检验的概率门，而非仅列方法名。** 固定一个内部窗后，写出拟用的Simon–Wolff/广义谱平均判据、对应原 $DCD$ 模型的测度条件及所需的实轴Green列平方可和估计；逐条说明10月迹类切割为什么没有提供它。改善切割误差到另一Schatten类、或重证非实轴逆矩阵的尾，不会自动消除奇异连续部分。第二周若仍只有“可尝试多尺度/分数矩”的清单，宜暂停，不用有限链亮斑补充成可行性证据。

## 25. 02:43 UTC再排除两类“long-range”标题造成的过宽创新口径

**Yunfeng Shi, Li Wen, Dongfeng Yan (2025版本；初稿2024).** *Localization for random operators on $\mathbb Z^d$ with the long-range hopping*, [arXiv:2412.17262v2，2025-05-24](https://arxiv.org/html/2412.17262v2)。已读§1、Theorems3.4–3.5及分布假设，未审多尺度归纳证明。其跳跃上界为 $\exp[-\gamma\log^{\rho}(1+|n|)]$、$\rho>1$，小跳跃即强无序、Hölder连续分布；本征函数按该尺度衰减。此核比任意幂次都快，远快于 $1/(n\log^2n)$。因此它不是临界候选的覆盖定理；反过来也不能说此前多尺度法只会处理指数跳跃。题名中的long-range不替代实际衰减假设。

**X. Deng, V. E. Kravtsov, G. V. Shlyapnikov, L. Santos (2018).** *Duality in Power-Law Localization in Disordered One-Dimensional Systems*, Physical Review Letters **120**,110602，DOI [10.1103/PhysRevLett.120.110602](https://doi.org/10.1103/PhysRevLett.120.110602)，[原作者稿v4，2018-01-15](https://arxiv.org/html/1706.04088v4)。已读模型、localized/multifractal数值定义、duality声明及其证据范围；未审补充材料。主模型是随机位置产生的Euclidean非对角 $1/|r_n-r_m|^a$ 跳跃，亦比较带对角无序的等距模型；有大量有限尺寸对角化及部分极限的解析论证，不能把它整体称为当前固定等距乘性临界链的严谨纯点定理。它仍说明“长程系统也能局域、尾为代数而非指数”不是2026首次的新认识。网页生成日期不是发表年份。

此外，已独立核主稿E32原文Theorem1.6：**Peter D. Hislop, Rodrigo Matos, Constanza Rojas-Molina (2026), *Poisson eigenvalue statistics and dynamical delocalization for fractional and long-range Anderson models***，[arXiv:2609.33084v1](https://arxiv.org/html/2609.33084v1)。当前主稿保留其 $\beta>d/2$、强加性无序及高位置矩结论的限制，准确；不应取 $\beta\downarrow0$ 来覆盖临界对数尾。此处只独立核主定理范围，没有重审其证明。del Rio等1995及该新预印本共同要求我们把纯点、尾部和动力学指标分开，但不是把“它们不同”本身推荐为新发现。

## 26. 02:44 UTC主稿的一处应消歧表述与整体适用范围

推荐一“另要求整条直界面带隔离、非零群速度”容易被读成**整条周期带上群速度均非零**。Ammari–Qiu的Assumption2.7(ii)的确要求全准动量区间的隔离下界，但(i)只在穿越点给非零导数；Theorem2.8将非零导数要求用于所选频窗 $\mathcal I_0$。建议写成“另要求整条直界面带统一隔离，并在所选频窗内群速度非零”。实周期解析带不可能在整圈处处单调，不能误把这样的全局速度假设写进候选。这是范围消歧，不是推翻尖角选题。[该原文Assumption2.7与Theorem2.8](https://arxiv.org/html/2605.29485v2)已核。

新第二项接受电容算子作为已严格导出的研究对象，首周不必重新证明所有三维层势公式；因此其学习成本虽大，仍可从一个明确的标量随机算子入手。真正不应省的是它和原二维模型的距离，以及非零对比下自由空间辐射：极限纯点谱不能自动宣称真实开放声学系统永久困波。当前主稿明确不承诺连续PDE谱型，故未见这种误推广。若最终简报用“困波”作直观标题，正文必须保留这个对象限定。

## 27. 02:45 UTC尖角候选可用的最小标量目标：相位差，而非只验酉性

在**保留Ammari–Qiu原文反射/旋转拼接对称性及其通量规范**的家族内，式(2.16)已给一个无需新散射实现的直接判别。对只有左入射，记该文的两个酉相位为 $\beta^e=e^{i\phi_e}$、$\beta^o=e^{i\phi_o}$，则

$$R=\frac14|\beta^e+\beta^o|^2
=\cos^2\frac{\phi_e-\phi_o}{2},\qquad
\mathsf T=\frac14|\beta^e-\beta^o|^2=1-R.$$

因此一致低反射要求的是 $\beta^e/\beta^o\to-1$，即相位差趋于奇数倍 $\pi$，不是仅两个相位都模1。对固定 $\tau$，坏频集也可等价写成 $|\beta^e+\beta^o|>2\sqrt\tau$。这个代数观察来自原定理，**不是新结果**；它把后续渐近估计应该控制什么写清楚。若微观角点拼接破坏用于奇偶分解的对称性，则不能沿用这两个相位公式，须保留完整散射矩阵，不能一边宣称任意几何鲁棒一边继续使用对称化简。

直臂第一门还应说明所要的“统一”不是无条件 $O(1)$：原文的隔离常数 $d_*(\delta)$ 在gap闭合时不能被默认为固定正数，物理坐标中的衰减长度也发散。允许显式的 $\delta$ 幂次损失，关键是与主极点、通量归一化及缩放频率的量级比较后，余项是否足以控制上述相位差；单独把每个固定 $\delta$ 的Fredholm逆记作有限常数并没有推进候选。当前主稿已要求吸收极限次序和明确空间，这是应保留的实质门。

## 28. 02:48 UTC随机方向的年代与衰减门槛再核

**Vojkan Jakšić, Stanislav Molchanov (1999).** *Localization for One-Dimensional Long Range Random Hamiltonians*, Reviews in Mathematical Physics **11**(1),103–135，DOI [10.1142/S0129055X99000052](https://doi.org/10.1142/S0129055X99000052)，[作者公开原文](https://jaksic.xyz/papers_pdf/longrh.pdf)，[作者修订稿摘要记录](https://web.ma.utexas.edu/mp_arc-bin/mpa?yn=98-317)。已读引言及Theorem1.1–1.2、证明路线；旧PDF的部分公式字体提取不良，关键 $\gamma>8$ 的纯点门槛另由作者存档摘要交叉核。模型为平移不变自由核＋加性i.i.d.势，单调实偶符号等假设；文章区分无AC和无连续谱，并非只把一个结论换名字。7月文章引言关于 $r^{-4}$ 与局域化的简写，不能当作已核准确的纯点门槛。主稿E30已对这个引用层级保留警告，做法应保留。

**Wenwen Jian, Siqi Xu, Dongfeng Yan (2026).** *Spectral and dynamical localization at large disorder for the nonlocal random operators on $\mathbb Z^d$*, Journal of Mathematical Physics **67**,012705，2026-01-16，DOI [10.1063/5.0298463](https://doi.org/10.1063/5.0298463)，[出版商条目](https://pubs.aip.org/aip/jmp/article/67/1/012705/3377503/Spectral-and-dynamical-localization-at-large)。本轮只读出版商公开摘要、元数据和参考文献，正文需购买，未绕过。它与§25的2025多尺度稿分别用FMM/Simon–Wolff与MSA处理超多项式但次指数跳跃 $\exp[-\log^\rho(1+|n|)]$、$\rho>1$，强无序下已有相应谱/动力学局域化。故“把FMM从最近邻推广到非局部”本身也不新；它所公开的衰减及强度假设仍不覆盖当前临界弱无序候选。这里不据摘要声称已核其全部技术细节。

## 29. 02:48 UTC把随机候选的下一门写成可失败的具体量

**Barry Simon, Tom Wolff (1986).** *Singular continuous spectrum under rank one perturbations and localization for random hamiltonians*, Communications on Pure and Applied Mathematics **39**(1),75–90，DOI [10.1002/cpa.3160390105](https://doi.org/10.1002/cpa.3160390105)。本轮原刊公开摘要核书目与秩一适用框架，未读其全证明。便于实际入手的原作者后续是 **Michael Aizenman, Simone Warzel (2016)**，*Boosted Simon-Wolff Spectral Criterion and Resonant Delocalization*, CPAM **69**,2195–2218，DOI [10.1002/cpa.21625](https://doi.org/10.1002/cpa.21625)，[作者稿v1](https://arxiv.org/html/1412.3681v1)（初稿2014；本轮读§2.1–2.3及Proposition2.1/Theorem2.3，未审全证明；正式条目与v2记录由[arXiv元数据](https://arxiv.org/abs/1412.3681)核）。它给标准**加性**模型的具体谱判据，不是仅一个方法名称。

对自伴 $H$，用其真实预解式定义

$$\Gamma_0(E,\omega)=\lim_{\eta\downarrow0}\sum_n
\left|\langle\delta_n,(H-E-i\eta)^{-1}\delta_0\rangle\right|^2
=\lim_{\eta\downarrow0}\frac{\operatorname{Im}G_{00}(E+i\eta)}{\eta}.$$

该极限也等于谱测度对 $((t-E)^2+\eta^2)^{-1}$ 的积分极限，因而存在但可为无穷。标准加性秩一谱平均框架下，Lebesgue几乎处处能量、概率1的有限性可排除该谱窗内的连续谱。相反，证明虚部的边界值为0并不控制除以 $\eta$ 后的比值；无AC没有提供这个缺失速率。这是10月结果与纯点目标之间可写出的一个准确缺口，而非泛泛说还要更强估计。

**不能未经适配把上述标准定理套给 $DCD$。** 改变 $D_0$ 会同时改变整行/列，通常是秩至多二的变化。一个便宜的确切入口是把原算子按原点与其补空间分块，令 $c_{00}=\langle\delta_0,C\delta_0\rangle$、$b=QC\delta_0$、$\bar H=\bar D(QCQ)\bar D$。对 $\operatorname{Im}z>0$，Schur补严格给

$$G_{00}(z)=\frac{a}{F(z)-za},\qquad a=D_0^{-2},$$
$$F(z)=c_{00}-\langle b,\bar D(\bar H-z)^{-1}\bar D b\rangle,$$

其中 $F$ 不依赖原点的随机变量，$a$ 有§24所核的绝对连续条件分布。这展示一个可核的单变量Möbius结构，但**还不是已证明的乘性Simon–Wolff定理**；要检查边界极限、条件谱测度与参数平均，以及从单原点到可数平移的全空间结论。首周应先用旧理论把这一适配写准确，并判断有没有现实办法证明 $\Gamma_0<\infty$。若只得到每个 $\eta>0$ 的有限范数或一个任意发散的 $\eta^{-p}$ 上界，就尚未跨过纯点门。无指数尾的小引理已接近完成的条件性一致性检查，不宜把再花一周抄该短推导称为研究可行性进展。

这里提出的估计对象是对候选价值的具体化，不声称它是唯一证明路径，更不暗示该临界弱无序概率估计目前已有解。若今后改用别的判据，仍须同样清楚地写出已有10月论文未控制的量与可失败的第一门。

## 30. 02:49 UTC第二推荐的材料几何表述需再收紧一句

主稿“每周期一个光滑反射对称共振器”应明确成：每胞一个**有界连通**的 $C^{2,\eta}$ 共振器 $D\Subset(-a/2,a/2)\times\mathbb R^2$，并有沿链方向的反射 $\mathcal R(x_1,x_\perp)=(-x_1,x_\perp)$ 满足 $\mathcal RD=D$。不是任意一面镜像对称就可调用全谱结论；连通与单胞一体也是标量电容模型的对象限定。10月Corollaries4.7、4.9明确有这些条件。若只选内部声学窗，反射对称本非局部无AC的必要前提；这里保留它只是先选最清晰的物理基准族，不应宣传成证明局域化所必需的新对称性条件。推荐二仍可保留，需消除上述几何歧义。[已核原文§4.3](https://arxiv.org/html/2610.09582v1)。

## 31. 02:53 UTC针对性回合的可引用结论与未审边界

02:52已读主稿与首步附件的修订：§26的全带隔离/局部速度区分、§30的连通及沿链反射、§24的乘性变量替换、§29的真实Green列判据与单点Schur入口均已吸收。G1新增的相位目标也保留了拼接对称性限制。就此时版本，未发现需要撤下新第二项的实质数学错误；这不等于其弱无序纯点谱已证或已有现实解法。主报告仍为送审草案，**本段不是最终文件/提交验收**。

为核E36，现另读[ Aizenman–Warzel作者稿v2](https://arxiv.org/html/1412.3681v2)§§2.1–2.4：编号确与v1不同。v2 Proposition2.1为秩一固有态判别，Proposition2.2主要写 $\gamma=\infty$ 的连续谱方向，Theorem2.4为零一律；有限 $\gamma$ 的纯点支持结论还见§2.4式(2.25)。因此今后引用“有限Green平方和排除连续谱”应指完整谱平均判据/该段，而不是声称v2 Proposition2.2的字面声明就是有限性方向。当前主稿只引用总体框架，没有作这种错误精确归因。

**当前排序判断。** 尖角优先：目标是实轴连续晶体的双谷反射机制和有量级的坏频窗，不能认领作者已提出的连续延拓为原创问题。临界链次之：10月已无AC，剩余纯点/奇异连续分叉确有价值；它是作者明确留下的极难题，先做两周准确的谱平均适配和概率估计可行性门，不作近期论文承诺。相位项只属一周淘汰性调查：目前没有足够证据支持长期主线或超越Miller应用的新颖性。双谷截止撤为技术备选合理，因为2013精确相邻模型已覆盖其核心移动律。

本回合没有新增第四条推荐、没有数值实验/代码/下载、没有修改主文件或提交。仅追加本文件；最近Git检查仍 `codex/dot`、HEAD `5c93665`，跟踪文件与暂存区diff为空，只见本轮新目录未跟踪；worktree约93MB。最终commit及之后的文字不在此时验收范围。核心公开作者稿可读，受阻机构路径未绕过；全文证明审计与文献穷尽性均未完成，故本文件开头的preliminary review限定继续有效。
