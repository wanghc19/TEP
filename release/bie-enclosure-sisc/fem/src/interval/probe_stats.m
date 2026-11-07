function r=probe_stats(action,why)
% Source: test/fem-goerisch/pipeline-v1/internal/probe_stats.m. Copied numerical algorithm.
  % PROBE_STATS Count adaptive split reasons; no mathematical decisions change.
  % stats means statistics of adaptive subdivisions.
  % Input: reset/get or a split kind and reason. Output: compact counters.
  persistent counts
  if isempty(counts)||strcmp(action,'reset'),counts=struct('smooth_tolerance',0,'smooth_contraction',0,'smooth_other',0,'sliver_split',0);end
  if strcmp(action,'smooth_split')
    if startsWith(why,'remainder'),counts.smooth_tolerance=counts.smooth_tolerance+1;
    elseif startsWith(why,'iface:Contraction'),counts.smooth_contraction=counts.smooth_contraction+1;
    else,counts.smooth_other=counts.smooth_other+1;end
  elseif strcmp(action,'sliver_split'),counts.sliver_split=counts.sliver_split+1;end
  r=counts;
end
