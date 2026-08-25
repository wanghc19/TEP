# Run estimates

## Pilot attempt 1

- Status before run: `PREREGISTERED / NOT YET RUN`.
- Nodes: real anchor, one complex cardinal node, and one parent-path anchor
  comparison.
- Largest physical matrices: proxy collocation
  $720\times354$ / $960\times450$, BIE $320\times320$ / $512\times512$,
  one-cell QZ and $A_{\mathrm{def}}^D$ $194\times194$, and graph
  $388\times388$.
- Explicit auxiliary matrix larger than the physical graph: none.
- Estimated peak retained memory: below 512 MiB with one dense node streamed.
- Estimated wall time: 60 s; preregistered hard ceiling: 300 s.
- MATLAB command:
  `matlab -nodesktop -batch "addpath('test/i1/k-ready'); run_pilot"`.

The full disk is not authorized by this estimate.  Its estimate will be based
on the measured pilot time before any full run.
