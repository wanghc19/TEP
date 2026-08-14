# I3 结果写作：尚未开始

当前尚无可发表的 continuous eigenvalue-error estimator 结果。本页只保存非越界命名顺序：

1. I3.1 内部理论和检查通过后，称 **continuous-residual estimator candidate**；若只覆盖
   部分 residual components，则必须称 **partial residual indicator**；
2. I3.2 在冻结后 independent reference 上通过，才称 **empirical eigenvalue-error
   estimator**；
3. I3.3 的第一层只有 reliable interval 完全位于 current continuous projected gap，且通过
   预注册 absolute/gap-relative resolution，才称 **resolved continuous discrete-eigenvalue
   existence interval**；区间过宽时称 `EXISTS_BUT_RESOLUTION_INSUFFICIENT`；
4. 只有另有 continuous spectral isolation/count 时，才把区间命名为指定 $k_*$ 的
   **target-specific computable upper bound**；否则保留第一层，不强求唯一 mode；
5. 若可靠 enclosure 或 gap 条件失败，合法结论是 `UPPER_BOUND_UNAVAILABLE`，不撤销前两步在各自范围内的结果。

论文结构、样本、effectivity 图、阈值和主张均应在实际结果形成后决定，不在 I3.1 理论阶段
预先冻结。
