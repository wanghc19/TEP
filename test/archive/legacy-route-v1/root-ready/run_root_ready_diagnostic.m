function results = run_root_ready_diagnostic()
% Purpose:
%   Run the root-readiness proxy provenance diagnostic from a stable entry
%   point.  This wrapper performs no root search.
%
% Output:
%   results - Complete diagnostic, provenance, and reproducibility bundle.

  here = fileparts(mfilename('fullpath'));
  addpath(here);
  results = root_ready_diagnostic();
end
