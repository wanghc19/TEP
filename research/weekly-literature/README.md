# 每周文献检索与方法评估

本目录保存用户提供的五批定期检索记录的原文核验、全文归档信息和研究评估。工作位置为 `epost` 工作树的 `codex/epost` 分支；本轮整理日期 **2026-10-30**。这是限定于给定 13 篇的文献调研，不是覆盖所有数据库的系统综述，也未创建或修改定期任务。

## 时间索引

| 批次日期 | 篇数 | 主要问题 | 调研报告 |
| --- | ---: | --- | --- |
| 2026-10-01（周四） | 5 | 显式谱下界、残差对偶范数、无限端误差与 BIE 算法 | [[research/weekly-literature/2026-10-01]] |
| 2026-10-09（周五） | 1 | 带边有效模型与有限阵列截断误差 | [[research/weekly-literature/2026-10-09]] |
| 2026-10-16（周五） | 3 | 平衡通量、有限测试空间与完整残差范数、边界罚项 | [[research/weekly-literature/2026-10-16]] |
| 2026-10-23（周五） | 3 | 可计算投影常数、胞元 BIE 真/伪核、Maxwell 结构保持 | [[research/weekly-literature/2026-10-23]] |
| 2026-10-30（周五，本周） | 1 | Floquet 出射模态、高频 DtN 与 Fredholm 结构 | [[research/weekly-literature/2026-10-30]] |

第一批依用户明确给出的 **10 月 1 日** 归档。原记录内“starting tomorrow, October 2”是后续定期任务的首次计划日，不把这批移到 10 月 2 日，也不虚构第六批。批次日期、论文首发/修订/正式出版日期、此次核验日期分别记录。

跨批次的借鉴优先级、创新性影响、简报修正和待办只汇总在 [[research/weekly-literature/synthesis]]。各批报告保留各自原文定位，不以新的总结覆盖历史简报的语境。

## 全文与书目

全部资料经仓库入口 `ref/ref_data/` 访问，实际文件位于同级 `TEP_ref/`。采用首作者姓氏与出版年份命名；同名同年用 `a` 区分。论文数据不进入 Git，目录与 BibTeX 保存在 [文献索引](../../ref/README.md) 和 [reference.bib](../../ref/reference.bib)。本轮资料的版本、下载地址、公开来源依据、页数和 SHA-256 统一见 [sources.json](sources.json)。新增 **12 份**、复用 **1 份**，总计 **464 页**；PDF 页数/哈希、五批数量、书目键和本地链接检查结果见 [validation.json](validation.json)。

PDF 为公开 arXiv/机构稿或出版方公开全文；不绕过登录或付费限制。公开可获取不自动表示可随意再发布。已存在的 Lu2026.pdf 核验后复用，避免同一版本重复存储；新文件均检查 PDF 可解析性和题名/作者身份。临时提取文本、页面图和集成中间件放在 `research/tmp/weekly-literature/`，不是研究权威。

## 评估口径与当前方法基线

调研问题是：每篇能补充当前方法的哪一个具体环节，所需假设能否满足，它会削弱什么宽泛创新性表述，又留下什么尚须验证的研究空间？采用 `academic-research-suite` 的限定文献综述流程；定理引用和条件匹配采用 `rigorous-proof / Review only`，并用 PDF 提取及必要的公式页核对。没有修改原文证明，也没有重证全部参考文献的内部依赖。

当前方法以以下实际项目记录为依据，不能只从第一批旧简报推断：

- [[research/projects/eig-apost/STATUS]] 及 [[research/projects/eig-apost/implementation/i10/README]]：FEM＋DtN 的富化半径依赖饱和性、评价误差及共同连续目标假设，仍是条件结果。
- [[redteam/reports/error_certification]]：BIE 的谱距离数值估计尚未完成单侧输入包围；BIE/FEM 候选很接近不能证明连续模态身份或真误差。
- [[research/explorations/spectral-counting/STATUS]]、[[research/explorations/spectral-counting/continuous_vs_discrete_gap]]：已有普通离散端点惯性证据；projected gap、半端 Dirichlet pole 排除和连续补空间提升仍未认证。

统一区分四类内容：**原文证明的结论**、**原文的普通数值观察**、**本项目满足条件后才可迁移的推断**、**未证明的研究建议**。不得把存在性常数、渐近收敛或三层一致性改称可计算连续证书。本目录不建立或提升统一 `mainline/`。

本轮使用 AI 辅助检索、原文提取和撰写；所有创新性评价限于已检查的文献与项目记录，需研究者最终审定，不作全球首创判定。文献事实的核验范围、重要限制和后续状态见各批报告与综合报告。
