function results = run_i4_fliss_experiment(profile)
% RUN_I4_FLISS_EXPERIMENT Run one frozen I4 dual-track profile.
%
% Purpose:
%   Provide the user-facing entrypoint for the isolated Fliss 2013 control
%   experiment.  Scientific gate failures are reported in the output bundle;
%   only integrity failures raise an error after outputs have been written.
%
% Input:
%   profile - Optional 'pilot' or 'baseline'; default is 'pilot'.
%
% Output:
%   results - Full result struct returned by i4_fliss_experiment.

  if nargin < 1
    profile = 'pilot';
  end
  results = i4_fliss_experiment(profile);
  if ~results.integrity_pass
    error('run_i4_fliss_experiment:IntegrityFailure', ...
      'The dual-track integrity gate failed; inspect the generated report.');
  end
end
