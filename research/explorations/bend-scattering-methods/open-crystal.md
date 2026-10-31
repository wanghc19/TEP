# 开放二维晶体弯角：原模型的针对性核验

2026-10-31，本轮后半段追加的模型核验；文献部分为 **Review only**。这不是新推荐方向。**结论仍为零项正式推荐**，但理由现在包含直接针对原几何的算法证据，而不只依赖有界硬壁条带的近邻。

## 1. 要回答的具体问题

M0为全平面质量型 $-\Delta u-\lambda\rho u=0$：同一二维周期背景中，两条与晶格相容的非平行线缺陷臂在局部连接，频率位于完整bulk gap。给定一条入射导模，求复反射/透射振幅。完整体隙不消除倏逝bulk场；弯角之外的外部区域仍然连通，两个有限截面端口一般不等于完整外部边界算子。

如果两条臂分别处在不同的远场bulk或多个扇区背景，须另定义参考介质；下述单一背景Green函数不自动覆盖它。当前讨论不是三维薄板、自由空间辐射光栅或物理硬壁条带，也没有假定拓扑或120度几何。

## 2. 直接适用的旧算法已经做了什么

下表均于2026-10-31核查。T表示读到原文算法与条件，不代表全文证明验收；“未核出误差证书”不等于算法失败。

| 原始文献与证据 | 对M0实际覆盖 | 有限表示的来源与保证边界 |
| --- | --- | --- |
| **Zhen Hu、Ya Yan Lu (2008), Efficient analysis of photonic crystal devices by Dirichlet-to-Neumann maps**, Optics Express16(22),17383–17399，DOI [10.1364/OE.16.017383](https://doi.org/10.1364/OE.16.017383)。[出版商提供的公开正文](https://www.researchgate.net/publication/23425710_Efficient_analysis_of_photonic_crystal_devices_by_Dirichlet-to-Neumann_maps)。主汇总及分工T：§§1–5，式6–18。 | 无限二维晶体、有限器件、若干半无限臂、60/90度弯折、分支；E偏振对应质量型。胞DtN合并与Bloch端口匹配都是直接先例。 | §3先将臂横向截成supercell并在两侧置零，远bulk边界也置零；之后对截断臂构造非局部端口。原文离散收敛例不能当作全部横向连续截断误差已认证。PDF链接404，已读公开正文但未下载。 |
| **Davy Pissoort、Eric Michielssen、Frank Olyslager、Daniël De Zutter (2005), Fast Analysis of 2-D Electromagnetic Crystal Devices Using a Periodic Green Function Approach**, JLT23(7),2294–2308，DOI [10.1109/JLT.2005.850029](https://doi.org/10.1109/JLT.2005.850029)。[作者全文](https://www.researchgate.net/publication/3243013_Fast_analysis_of_2-D_electromagnetic_crystal_devices_using_a_periodic_Green_function_approach)。主汇总抽核§III-C；分工及独立review T：§III、式30–33、§IV。 | 无限双周期背景、移除圆柱形成的缺陷网络，局部改变及弯角，直接计算器件S。未知量放在缺陷等效电流上，背景晶体用其Green函数消去。 | Green预计算使用有限背景；式31/33截断远耦合；端口假定单传播模，放在离结点足够远以忽略倏逝项的位置。其“exact”端口措辞不等于近截止全倏逝尾已认证。 |
| **Davy Pissoort、Eric Michielssen、Anthony Grbic (2007), An Electromagnetic Crystal Green Function Multiple Scattering Technique for Arbitrary Polarizations, Lattices, and Defects**, JLT25(2),571–583，DOI [10.1109/JLT.2006.889364](https://doi.org/10.1109/JLT.2006.889364)。[作者全文](https://www.researchgate.net/publication/3243893_An_Electromagnetic_Crystal_Green_Function_Multiple_Scattering_Technique_for_Arbitrary_Polarizations_Lattices_and_Defects)。主汇总核引言、式35–37；分工/review T：§§III–V。 | 两种偏振、方/三角晶格、非圆及材料改变的缺陷，弯角与网络；“复用bulk核＋局部散射块”已不局限于简单删圆柱。 | 截断角模和远相互作用得到近稀疏系统；bulk核及端口继承前文近似。本轮未核出所有截断误差同时传到连续S的可计算定理。机构PDF返回500，不重试；正常作者全文可读。 |
| **Sergei F. Mingaleev、Yuri S. Kivshar (2002), Effective equations for photonic-crystal waveguides and circuits**, Optics Letters27(4),231–233，DOI [10.1364/OL.27.000231](https://doi.org/10.1364/OL.27.000231)，[作者稿physics/0110068](https://arxiv.org/pdf/physics/0110068)。主汇总T：全3页、式2–8。 | 质量型二维晶体及弯角；背景Green函数转成缺陷长程耦合，两条半无限臂的传播/倏逝模式接有限弯区。 | 从精确积分表示到式3用了缺陷圆柱内场近似常数，式5再截断耦合范围；不能把有效离散方程当完整PDE。它进一步否决“缺陷网络有限表示本身是新意”。 |

其他直接方法及限制已由前轮独立review核于§18（Git提交 `d6278e8`；当前review已用于LaTeX报告审查）：Wojciech Śmigaj (2007), *Application of the multiple-scattering method to analysis of systems with semi-infinite photonic waveguides*，DOI [10.1364/JOSAA.24.003309](https://doi.org/10.1364/JOSAA.24.003309)，[作者稿](https://arxiv.org/pdf/physics/0703165v1)，已有有限臂反射去嵌入，但用单模及倏逝项可忽略假设；Esteban Moreno、Daniel Erni、Christian Hafner (2002), *Modeling of discontinuities in photonic crystal waveguides with the multiple multipole method*，DOI [10.1103/PhysRevE.66.036618](https://doi.org/10.1103/PhysRevE.66.036618)，[作者全文](https://www.researchgate.net/publication/11093070_Modeling_of_discontinuities_in_photonic_crystal_waveguides_with_the_multiple_multipole_method)，§IV-B已把横向晶体宽度和结点到端口距离分开诊断。主汇总没有重复全面核读这两篇，证据归属保留。

## 3. 连续外部归约的近邻：不能漏掉，也不能越界

- **Sonia Fliss (2013), A Dirichlet-to-Neumann Approach for the Exact Computation of Guided Modes in Photonic Crystal Waveguides**，SIAM JSC35(2),B438–B461，DOI [10.1137/12086697X](https://doi.org/10.1137/12086697X)，[作者稿v2](https://arxiv.org/pdf/1202.4928v2)。独立review T：Propositions3.1/3.3、Theorems4.1/4.5/4.12。原开放直线缺陷的纤维导模可精确归约到有限横向区域；半带Dirichlet谱例外必须保留。它不是弯角散射定理。
- **Julien Coatléven (2012), Helmholtz equation in periodic media with a line defect**，JCP231(4),1675–1704，DOI [10.1016/j.jcp.2011.10.022](https://doi.org/10.1016/j.jcp.2011.10.022)，[作者全文](https://www.researchgate.net/publication/220207190_Helmholtz_equation_in_periodic_media_with_a_line_defect)。主汇总核出版商模型说明；分工/review T：§2、Theorem3.1、§5.3 Theorems5.5–5.6。广义LS、轴向Floquet反演、横向DtN及求积率已有；但参考是同轴直缺陷，分析假设正吸收，不能推成无损两非平行臂的统一结论。
- **Christophe Besse、Julien Coatléven、Sonia Fliss、Ingrid Lacroix-Violet、Karim Ramdani (2013), Transparent boundary conditions for locally perturbed infinite hexagonal periodic media**，CMS11(4),907–938，DOI [10.4310/CMS.2013.v11.n4.a2](https://doi.org/10.4310/CMS.2013.v11.n4.a2)，[作者稿](https://arxiv.org/pdf/1205.5345v1)。分工/review T：A1–A3、DtN/DtD及Riccati构造。紧支缺陷、正耗散和旋转对称条件不包含任意入射导模及无限臂。
- **Pierre Amenoagbadji、Sonia Fliss、Patrick Joly (2025), Time-harmonic wave propagation in junctions of two periodic half-spaces**，PAA7(2),299–357，DOI [10.2140/paa.2025.7.299](https://doi.org/10.2140/paa.2025.7.299)。阈值分工T核式1-1/Remark1.1：$\operatorname{Im}\omega>0$，两周期半空间直界面，非本M0。独立review对此只有A/M，二者证据层级不混同。

2026的Goodwill–Epstein无界接口BIE和Lu–Shen–Zhang周期结构BIE见 [[research/explorations/bend-scattering-methods/landscape]] §4/7：分别是分层/可分解开放臂及横向同质夹层，不能仅因“open/periodic”就当作本M0的连续误差定理。

## 4. 具体外部表示诊断：哪里仍难，哪里没有新机制

已有算法允许以下清晰分层：先用背景晶体的Green函数消去bulk，再把缺陷未知量分成有限结点区和两条周期半无限臂。臂内部保留Bloch/模态关系，跨臂与结点相互作用由同一背景核提供。**这在结构上就是已有Green函数多重散射路线**，不是本轮发明的有限维外部表示。

一旦位于离bulk谱正距的窗内，局域核衰减可用于控制远相互作用；但“看见指数衰减”尚不给数值常数，更不能删除所有臂外场。沿臂的导波连续谱、近截止慢倏逝模和结点共振分别要求不同控制。横向零墙也可能引入表面谱，因此bulk gap本身不是任意截断边界安全的充分条件。直接近邻是 **Sonia Fliss、Dirk Klindworth、Kersten Schmidt (2015；online2014), Robin-to-Robin Transparent Boundary Conditions for the Computation of Guided Modes in Photonic Crystal Wave-Guides**，BIT55(1),81–115，DOI [10.1007/s10543-014-0521-1](https://doi.org/10.1007/s10543-014-0521-1)。阈值分工T核§2.3、§5.2的Dirichlet表面态和Theorem3.1的RtR构造；因此换RtR避开这些假极点本身也不是新机制。这里不是断言Hu2008特定算例出现了该故障。

为了检测剩余任务是否只是标准误差组合，可在**已合法定义出射空间且已得到有界可逆匹配算子** $A:X\to X$ 的条件下，记近似为 $\widehat A$、右端 $\widehat f$。若已知

$$\|A-\widehat A\|\le\varepsilon_A,\qquad
\|\widehat A^{-1}\|\le B,\qquad B\varepsilon_A<1,$$

则Neumann级数及残差恒等式给

$$\|u-\widehat u\|\le
\frac{B}{1-B\varepsilon_A}
\bigl(\|f-\widehat f\|+\varepsilon_A\|\widehat u\|\bigr).$$

这只是标准充分条件的应用诊断，**不是已经证明M0存在上述 $X,A,B$**，也不是把普通 $L^2$ 逆用于非衰减入射波。输出迹误差、核近似、远耦合、倏逝尾均须先在正确范数中进入 $\varepsilon_A$；若只完成此组合，应称为可靠性实现，不自动成为新方法。反过来，全逆失效不必使某个输出失败，危险模消去仍有已有基线。

实际未闭合的任务有三个：背景Green函数及其尾的连续可靠误差、半无限臂全部必要模态的可靠外部表示、中心匹配或指定输出的可计算稳定性。**目前没有找到一个具体条件，在该条件下上述成熟数值机制不足，而本轮又提出了新的可行操作。** 因而不能把这三项总打包为“连续误差闭合新理论”。

## 5. 判决、可复用资产与重新开启条件

原模型有直接可复用算法；原模型的完整可计算散射误差链仍未由本轮核实闭合。这两句话可同时成立。现有胞BIE、Floquet谱隔离、DtN/RtR经验能支持复现或可靠性建设；旧固定相位导模唯一性证书不能直接给散射稳定常数或整个二维bulk gap。

本轮不建议默认开发一套弯角求解器，也不建议仅为了产生题目去追求所有误差同时认证。有新证据才重新开启：先固定一个M0几何、可观察输出和信息预算，展示强旧基线的具体限制，再提出超出换边界条件、加模态、标准谱投影或逆扰动的新操作。对算法未给某个定理的事实，本身不足以满足该门槛。

此次检索非系统综述，未证明整个散射方法领域无空白。前轮证据、争议和访问限制见Git提交 `d6278e8` 中review §§16–21；当前 [[research/explorations/bend-scattering-methods/review]] 审查新报告；本文件的主结论仅用于本轮选题决策。
