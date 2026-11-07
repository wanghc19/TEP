# 执行与文件边界核验

日期：2026-10-28。本任务有三个独立审计分工和root综合。所有写入路径均限定于
`/Users/whc/Documents/Work/epost/redteam/`；没有提交、推送、切换分支或修改生产配置。

## 源文件完整性

任务起始记录 main 与 codex/epost 的Git状态和HEAD，随后对两工作区所有Git跟踪
文件以及非忽略的未跟踪普通文件做内容指纹快照，排除redteam自身。
记录位于 `baseline/source-integrity-before.json`、`source-integrity-after.json` 和
`integrity-check.json`；指纹仅用于外层审计，不供数值程序读取。

前快照3047个文件，后快照3048个文件。**main的受检文件全部不变；两条实际
数值路线的受检代码、理论与原有ref改动也没有变化。** 外部工作区不是静止的：
两快照间检测到 `research/explorations/interface-threshold/` 以下7个路径变化，
本任务没有写入这些路径，按并发变化保留、不恢复或覆盖：

- `DECISIONS.md`
- `README.md`
- `STATUS.md`
- `next_steps.md`
- `research_priority_decision.md`
- `rigorous_2d_bridge.md`
- `spectral_certification_alternatives.md`

因此不声称“epost所有外部文件均未变化”。这些变化不在本任务的实际数值/证明
输入链；原始未提交ref文件和研究探索目录也均未由本任务处理。忽略文件和运行时
系统缓存不在上述全工作区指纹覆盖内；模态输入路径另在case及baseline明确记录。

## 数值与操作状态

- 精确机制C01–C04与QP核探针同一MATLAB进程成功：14.7036秒，进程树采样峰
  927825920字节，退出0。精确机制所有声明断言通过，不能推广为生产算法普遍正确。
- 物理模态比较实际使用MATLAB R2023b。提取、原比较、冻结点近层修正和端口补充
  的命令及耗时/内存均保存在 `results/mode-identity/attempt-1/*-run.json`。
  同一科学方法的调试保留在同一attempt，没有新建科学尝试掩盖失败。
- 第一次沙箱MATLAB/进程监控失败，以及比较器两次结构赋值错误，都保留了日志；
  它们是操作/实现故障，未进入数学反例账目。监控器补了启动前权限检查与异常清理。
- 原层势1536点评价在最近界面层不稳定；这是一项红队评价精度发现。保留原数据，
  在相同场/候选/物理点上增加该层评价节点，输出另存 `layer-refinement/`。
  不把修正前差值算成生产场错误，修正后也不声称已经取得全域严格范数界。
- 未运行Octave数值试验，未安装依赖，未执行生产搜索、FEM重新求解或全参数扫描。
  历史生产计时只读，不混入本轮诊断成本。

Python源码以项目Conda `octave`环境内存编译检查；MATLAB实际运行与静态检查记录
见 `results/validation/`。所有新增数值源由case文档说明依赖；独立实现仅指新写的
解析小模型与FE场评价器等明确部分，不指复用了保存场的整个求解链。

最终静态检查：4个MATLAB文件完成 `checkcode -id`；两个文件无消息，另两个各有
一条 `MSNU`（以前的警告抑制注释现已无必要），没有发现计算行为错误。保留这两条
无行为影响的注释，不为消除样式消息重跑科学计算。该检查进程14.105秒、采样峰
861880320字节、退出0。3个Python源内存编译成功，15个结果JSON解析成功。
`git diff --check` 无输出，但新redteam尚未跟踪，所以其文本另做空白/链接完整性检查。
24个新Markdown/MATLAB/Python文本检查未发现尾随空白或失效的本地链接，结果保存为
`results/validation/text-checks.json`。最终第二读者复核模态与决策报告未发现实质性
夸大；补正了映射有限元不必在物理坐标下为多项式、比较仅覆盖共同有限区域的措辞。
