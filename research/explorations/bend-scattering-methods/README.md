# 开放晶体弯角散射：两种外部表示

`bend-scattering-methods` 指弯折波导散射数值方法。**当前阅读入口为 [report.pdf](report.pdf)，源文件为 [report.tex](report.tex)。** `report` 是本专题调研报告；PDF（Portable Document Format）为其7页编译版，4幅TikZ图均内嵌在TeX源内。无需读取全部Markdown即可理解主要结论。

## 当前判断与阅读顺序

本轮复原Hu–Lu胞DtN/横向零墙和Pissoort背景Green/缺陷网络的计算机制。共同模型是无损、非磁性、正介电二维晶体中的两条同型单模臂与有限弯角；固定完整体隙内、远离截止且散射适定的工作窗。报告用公式区分局部离散与外部近似，明确半无限尾如何进入有限匹配系统。

**仍为零项正式新课题，不设备选。** 两种已有表示确实改变了外部近似方式；本轮未识别出新的数值机制，也未证明新的散射主定理。报告不把“未核到端到端误差界”解释为算法失效，不对整个散射方向作穷尽判断。

- [report.pdf](report.pdf) / [report.tex](report.tex)：当前面向学术听众的正文，模型、算子、4张图、两方法及选题判断。
- [[research/explorations/bend-scattering-methods/review]]：独立审查者本轮原位更新，主作者未修改。§9已通过当前7页稿的数学与全页视觉验收；§§6–8是过程记录。
- [[research/explorations/bend-scattering-methods/open-crystal]]：三篇直接算法的完整题名、公开全文链接和覆盖证据。
- [[research/explorations/bend-scattering-methods/landscape]]：前轮更广方法矩阵、2025–2026书目和访问限制。
- [[research/explorations/bend-scattering-methods/recommendation]] 及既有 `candidates/`：前轮选题、条件推演和淘汰依据；不作为本轮新增候选。

所有内容集中于原目录，没有新增研究子目录或候选文件。前轮完整稿保留于Git提交 `d6278e8`，本轮按用户要求原位复用入口与独立review，新增报告源及本地编译PDF。

## 本轮范围与复现

授权窗：2026-10-31 **08:05:41–09:35:41 UTC**。08:07核实真实路径 `/Users/whc/Documents/Work/dot-research`、分支 `codex/dot`、HEAD `d6278e8c861a00ad93259f27e35d035e8775fc25`，初始工作区干净。之后review改动来自指定独立审查者。没有清除旧轮用户改动，没有改数值代码、切换分支、push或访问私有GitHub。

本轮主要重新核读2005、2007、2008算法原文和2013横向DtN定理；不声称本轮新增覆盖2026文献。采用academic-research-suite原文核对、rigorous-proof的Review only、PDF逐页渲染检查及Library交付流程。报告中的统一记号、lifting和尾和公式为条件性重述/初等推演，非新主定理。

使用已有TeX Live 2024、XeLaTeX、latexmk、Fandol与TeX Gyre Pagella字体及Ghostscript 10.03.0；没有安装软件。以下命令从仓库根运行，所有输出及缓存留在仓库内：

```sh
mkdir -p tmp/bend-scattering-report/texmf-var tmp/bend-scattering-report/texmf-config tmp/bend-scattering-report/cache
TEXMFVAR="$PWD/tmp/bend-scattering-report/texmf-var" \
TEXMFCONFIG="$PWD/tmp/bend-scattering-report/texmf-config" \
XDG_CACHE_HOME="$PWD/tmp/bend-scattering-report/cache" \
latexmk -xelatex -interaction=nonstopmode -halt-on-error \
  -outdir="$PWD/tmp/bend-scattering-report" \
  research/explorations/bend-scattering-methods/report.tex
cp tmp/bend-scattering-report/report.pdf research/explorations/bend-scattering-methods/report.pdf
TMPDIR="$PWD/tmp/bend-scattering-report" \
gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r120 \
  -sOutputFile=tmp/bend-scattering-report/page-%d.png \
  research/explorations/bend-scattering-methods/report.pdf
```

逐页查看PNG，检查中文、图示、公式、引用与分页。当前Poppler缺少Adobe-GB1 CMap，直接渲染中文不完整，故改用已有Ghostscript，并用macOS CoreGraphics（Quartz）独立渲染全部7页。主作者已实际查看两套图像；最新Quartz图未见右侧裁切。PDF内Fandol的FontDescriptor均指向实际FontFile3嵌入流，故Poppler缺CMap不等于PDF缺中文字体。未安装字体/CMap或改变系统设置。首次编译的字体族查找问题已改为使用TeX内字体文件名。清理LaTeX中间文件只用：

```sh
latexmk -c -outdir="$PWD/tmp/bend-scattering-report" \
  research/explorations/bend-scattering-methods/report.tex
```

`report.pdf` 由仓库已有 `*.pdf` 规则忽略，按约定不强制加入Git；它保留在源文件同目录。Git保留可恢复的完整源和编译方法。引用复用内嵌的6条bibliography，没有新增图源或配置文件；本轮不修改共享ref索引。

**PDF与TeX均已保存为Library附件。** 当地预上传能力不可用，最初尝试在创建上传会话前退出。父线程确认当前技能规定的能力不可用回退路径后，两个新文件按顺序批量创建成功，并将返回的Library身份信息写入对应本地文件。附件与已编译、已查看的本地稿内容一致；真实附件标识随最终交付提供，不将本地路径冒充云端附件。

## 前轮已保存的公开文献


以下三份于2026-10-31前一轮合法公开下载；本轮未新增下载。此前已核对首页题名/作者/版本；只写当前仓库内真实目录 `ref/ref_data/`，不写历史外置 `TEP_ref/`，不提交PDF。三份共 **3,993,954字节**。来源、用途和版本同时记入ref两份目录。

PDF未提交是遵守 `ref/AGENTS.md` 的“Do not commit reference documents”约定；现有 `.gitignore` 第66行 `ref/**` 也忽略这些文件，已用 `git check-ignore -v` 核实，未修改忽略规则。三份文件仍实际保留在本地，并未丢失或删除；单独检出Git提交不会携带PDF，可按下表公开URL、版本和SHA-256重新取得并核验。

| 文件 | 作者、题名、版本及公开源 | 字节数 | SHA-256 |
| --- | --- | ---: | --- |
| `ref/ref_data/Halla2018.pdf` | Martin Halla、Lothar Nannen，*Two scale Hardy space infinite elements for scalar waveguide problems*，2018正式版（online2017），[出版商PDF](https://link.springer.com/content/pdf/10.1007/s10444-017-9549-5.pdf)；近截止强基线 | 2046782 | `2079475a94316cc03a5b954cb35b7e807e889884a76d7ba6ef812306ae8f3f24` |
| `ref/ref_data/Lawrence2026.pdf` | Scott Lawrence、Yukari Yamauchi，*Stable minimum principles for scattering states*，arXiv2605.17139v1（提交05-16，PDF题头05-19），[作者PDF](https://arxiv.org/pdf/2605.17139v1)；直接输出界先例 | 655144 | `cc65227b527bf114eb912265bd4a44143af02c5fbbe72921e6ed9e067ffabab7` |
| `ref/ref_data/Zhang2021.pdf` | Ruming Zhang，*Numerical methods for scattering problems in periodic waveguides*，2021正式版，[出版商PDF](https://link.springer.com/content/pdf/10.1007/s00211-021-01229-0.pdf)；周期条带完整算法基线 | 1292028 | `3f12832cbec1fc0e06167bc06be6501cc63bf772c1ed8639496e54e11c533762` |

Nazarov2017先前网页已读，本地下载HTTP403、无文件；Hu2008公开正文已读，PDF链接404、无下载。其它开放晶体关键原文采用正常公开作者/出版商全文在线核读，未批量下载。已知拒绝入口不重试、不绕过；其余具体访问限制见landscape/open-crystal及review。没有假称被拒资料已本地取得。

## 验证与资源边界

本轮只运行文稿编译、渲染、文件/链接检查及附件保存，没有数值实验、MATLAB或后台实验任务。最新7页PDF已由主作者和独立reviewer分别逐页检查，数学与视觉均通过，详见review §9。编译无overfull、未定义引用或缺字警告，仍有字体script元数据警告及一处参考文献underfull警告；实际中文和版面以渲染结果验收。已运行上述 `latexmk -c`，主PDF及源文件保持不变。

核对 `git diff --check`、明确暂存路径、分支与工作树；不提交AGENTS.override、临时文件或文献PDF。总存储包括隐藏/忽略文件，以不跟随外部链接的 `du -sk .` 监测，远低于1,000,000,000字节上限。未重试此前被拒的全系统进程检查，不声称审计过用户的所有进程。
