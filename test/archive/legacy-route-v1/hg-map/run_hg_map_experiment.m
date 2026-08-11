function results = run_hg_map_experiment()
% Purpose:
%   Run the isolated half-guide map experiment and enforce its final GO gate.
%
% Output:
%   results is the struct returned by hg_map_experiment.

  results = hg_map_experiment();
  if ~results.all_pass
    error('run_hg_map_experiment:GateFailure', ...
      'At least one frozen half-guide map gate failed; inspect output/report.md.');
  end
end
