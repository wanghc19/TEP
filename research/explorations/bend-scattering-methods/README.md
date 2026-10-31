# 弯折波导散射的数值方法选题

`bend-scattering-methods` 指弯折波导散射数值方法。本轮最终结论是：**零项正式推荐，不设备选；没有为凑题保留已被强先例削弱的路线。** 已核近截止表示、近共振输出和整频窗漏检，并回到原开放二维晶体弯角核查直接算法。没有证明散射方向已被穷尽，也没有证明新散射主定理。

## 阅读顺序与文件作用

1. [[research/explorations/bend-scattering-methods/recommendation]]：简短最终判断、计算用途与学术增量的区别、重新开启的证据门槛。
2. [[research/explorations/bend-scattering-methods/landscape]]：质量型模型、算法/保证覆盖矩阵，原始书目、2025–2026核读及访问限制。
3. [[research/explorations/bend-scattering-methods/open-crystal]]：原全平面晶体弯角的直接方法核验。Hu–Lu2008、Pissoort2005/2007等已有有限表示；未核出端到端连续误差证书不等于算法失效。
4. [[research/explorations/bend-scattering-methods/candidates/threshold-uncertainty]]：曾保留的截止不确定性问题及两通道解析诊断；最终仅为可靠性验收要求。
5. [[research/explorations/bend-scattering-methods/candidates/cell-to-port]]：胞导数问题、显式解析半径和双模态Cauchy迹的条件推演。局部连续部分经只读分工核查；不是全离散散射证书，也没有识别出新方法机制。
6. [[research/explorations/bend-scattering-methods/candidates/rejected-routes]]：其余路线的具体淘汰原因及有限精度反例边界。
7. [[research/explorations/bend-scattering-methods/review]]：指定独立reviewer的冻结原稿，主汇总没有编辑。§§14/16/21的修正已吸收；§§18–20是开放晶体直接先例。它记录审查时快照，部分“待修改”文字不代表终稿仍未修复。

本轮主体8份Markdown集中于此目录；另外仅改 `ref/README.md`、`ref/reference.bib` 两份来源目录。未搬动或改写上轮报告，未改数值代码。

## 范围、时间与证据

授权窗为2026-10-31 **03:08:10–04:38:10 UTC**。实际网页/原文检索在本窗内进行，主汇总主要检索于04:00前完成，之后为审查整合和提交。实际核到2026文献，包括Lawrence–Yamauchi、Goodwill–Epstein、Lu–Zhou和2026-10-26发表的Ackermann等有理逼近论文，详见landscape。不是2026年文献的穷尽检索，不能以未搜到证明开放性。

采用 academic-research-suite 文献筛选流程；文献审查为 rigorous-proof 的 Review only，未修改被审原文。`cell-to-port.md` 为明确授权的 Proof from scratch 条件推演，其余公式为选题诊断或标准扰动关系。没有数值实验、MATLAB运行、编译、依赖安装或后台实验任务。

## Git基线与保全

03:09 UTC核实真实路径 `/Users/whc/Documents/Work/dot-research`、分支 `codex/dot`、HEAD `9cb8d8a23f6eae8090da95aa92fa85c7b9df16ae`，初始工作区干净。当前worktree持有该分支；没有切换分支/工作树、push、访问私有GitHub或修改权限/网络。旧轮用户改动在本轮开始时已不表现为未提交变化，不能说是本轮清除了它们。

只提交本目录8份文稿及上述两份ref目录，明确列路径暂存；不提交PDF、AGENTS.override或其它用户文件。提交后的精确SHA由最终交付给出，避免为在文件中嵌入自身SHA再造提交。

## 公开文献保存清单

全部于2026-10-31合法公开下载，核对首页题名/作者/版本；只写当前仓库内真实目录 `ref/ref_data/`，不写历史外置 `TEP_ref/`，不提交PDF。三份共 **3,993,954字节**。来源、用途和版本同时记入ref两份目录。

| 文件 | 作者、题名、版本及公开源 | 字节数 | SHA-256 |
| --- | --- | ---: | --- |
| `ref/ref_data/Halla2018.pdf` | Martin Halla、Lothar Nannen，*Two scale Hardy space infinite elements for scalar waveguide problems*，2018正式版（online2017），[出版商PDF](https://link.springer.com/content/pdf/10.1007/s10444-017-9549-5.pdf)；近截止强基线 | 2046782 | `2079475a94316cc03a5b954cb35b7e807e889884a76d7ba6ef812306ae8f3f24` |
| `ref/ref_data/Lawrence2026.pdf` | Scott Lawrence、Yukari Yamauchi，*Stable minimum principles for scattering states*，arXiv2605.17139v1（提交05-16，PDF题头05-19），[作者PDF](https://arxiv.org/pdf/2605.17139v1)；直接输出界先例 | 655144 | `cc65227b527bf114eb912265bd4a44143af02c5fbbe72921e6ed9e067ffabab7` |
| `ref/ref_data/Zhang2021.pdf` | Ruming Zhang，*Numerical methods for scattering problems in periodic waveguides*，2021正式版，[出版商PDF](https://link.springer.com/content/pdf/10.1007/s00211-021-01229-0.pdf)；周期条带完整算法基线 | 1292028 | `3f12832cbec1fc0e06167bc06be6501cc63bf772c1ed8639496e54e11c533762` |

Nazarov2017先前网页已读，本地下载HTTP403、无文件；Hu2008公开正文已读，PDF链接404、无下载。其它M0关键原文采用正常公开作者/出版商全文在线核读，未批量下载。已知拒绝入口不重试、不绕过；其余具体访问限制见landscape/open-crystal及review。没有假称被拒资料已本地取得。

## 验证与资源

只做文稿/来源验证：检查本地链接、BibTeX key无重复、3份PDF首页及SHA、`git diff --check`、暂存路径清单、分支/worktree状态和总存储。可从入口按文献记录的页节独立重审结论；本轮没有需要复跑的数值实验或计算manifest。

```sh
git branch --show-current
git status --short
git show --stat --oneline HEAD
git diff --name-only 9cb8d8a23f6eae8090da95aa92fa85c7b9df16ae..HEAD
git diff --check 9cb8d8a23f6eae8090da95aa92fa85c7b9df16ae..HEAD
git check-ignore ref/ref_data/Halla2018.pdf ref/ref_data/Lawrence2026.pdf ref/ref_data/Zhang2021.pdf
LC_ALL=C shasum -a 256 ref/ref_data/Halla2018.pdf ref/ref_data/Lawrence2026.pdf ref/ref_data/Zhang2021.pdf
du -sk .
```

03:58 UTC工作树为97,816KiB（约100.2MB），含隐藏/忽略文件，不跟随外部链接；远低于1,000,000,000字节上限。本目录当时约140KB，低于250KB文字预算；3份PDF低于20MB下载预算。最终检查值在交付中报告。未启动MATLAB、数值实验或持久任务；先前`ps`拒绝未重试，因此不声称做了系统全进程普查。
